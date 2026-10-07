unit PPG.Tests.Check;

{ Tests fuer Phase 2: CheckBox, RadioButton, ToggleSwitch. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Vcl.ActnList,
  PPG.Types, PPG.Consts, PPG.Render.Registry, PPG.Controls.Check,
  PPG.CheckBox, PPG.RadioButton, PPG.ToggleSwitch, PPG.Tests.Controls;

type
  TCheckTestCase = class(TControlTestCase)
  protected
    FClicks, FChanges: Integer;
    procedure CountClick(Sender: TObject);
    procedure CountChange(Sender: TObject);
    procedure RaisingChange(Sender: TObject);
    function NewCheck(const ACaption: string = 'Check'): TPPGCheckBox;
    function NewRadio(const ACaption: string; AGroup: Integer = 0): TPPGRadioButton;
    function NewSwitch(const ACaption: string = 'Switch'): TPPGToggleSwitch;
    procedure SetUp; override;
  end;

  TCheckBoxTests = class(TCheckTestCase)
  published
    procedure ClickTogglesAndFiresBothEvents;
    procedure ProgrammaticChangeFiresOnlyOnChange;
    procedure SettingSameValueFiresNothing;
    procedure AllowGrayedCyclesLikeVcl;
    procedure SpaceKeyToggles;
    procedure AcceleratorTogglesAndFocuses;
    procedure ExceptionInOnChangeKeepsConsistentState;
    procedure DisabledIgnoresInput;
    procedure ActionSyncsChecked;
    procedure LoadsVclStyleDfmWithoutEvents;
    procedure AnimatesOnlyWhenVisible;
  end;

  TRadioButtonTests = class(TCheckTestCase)
  published
    procedure CheckingOneUnchecksSiblings;
    procedure GroupsAreIndependent;
    procedure ClickOnCheckedStaysChecked;
    procedure ArrowKeysMoveSelectionWithWrap;
    procedure WantsArrowKeys;
    procedure SiblingOnChangeFires;
  end;

  TToggleSwitchTests = class(TCheckTestCase)
  published
    procedure ClickToggles;
    procedure ThumbPositionFollowsState;
    procedure RightToLeftMirrorsThumb;
  end;

  TCheckPaintTests = class(TCheckTestCase)
  published
    procedure AllControlsAllStatesBothPresetsPaintWithoutErrors;
    procedure CheckedIndicatorUsesCheckedColor;
    procedure NoHandleOrMemoryLeaks;
  end;

implementation

{$WARN SYMBOL_PLATFORM OFF}

type
  TCheckAccess = class(TPPGCustomCheckControl);

const
  GR_GDIOBJECTS = 0;
  GR_USEROBJECTS = 1;

function ColorDist(A, B: TColor): Integer;
var
  CA, CB: Cardinal;
begin
  CA := ColorToRGB(A);
  CB := ColorToRGB(B);
  Result := Abs(GetRValue(CA) - GetRValue(CB)) + Abs(GetGValue(CA) - GetGValue(CB)) +
    Abs(GetBValue(CA) - GetBValue(CB));
end;

{ TCheckTestCase }

procedure TCheckTestCase.SetUp;
begin
  inherited;
  FClicks := 0;
  FChanges := 0;
end;

procedure TCheckTestCase.CountClick(Sender: TObject);
begin
  Inc(FClicks);
end;

procedure TCheckTestCase.CountChange(Sender: TObject);
begin
  Inc(FChanges);
end;

procedure TCheckTestCase.RaisingChange(Sender: TObject);
begin
  raise EAbort.Create('OnChange failed');
end;

function TCheckTestCase.NewCheck(const ACaption: string): TPPGCheckBox;
begin
  Result := TPPGCheckBox.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 140, 24);
  Result.Caption := ACaption;
  Result.Animation.Enabled := False;
  Result.OnClick := CountClick;
  Result.OnChange := CountChange;
  Result.HandleNeeded;
end;

function TCheckTestCase.NewRadio(const ACaption: string; AGroup: Integer): TPPGRadioButton;
begin
  Result := TPPGRadioButton.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 40 + FForm.ControlCount * 26, 140, 24);
  Result.Caption := ACaption;
  Result.GroupIndex := AGroup;
  Result.Animation.Enabled := False;
  Result.OnClick := CountClick;
  Result.OnChange := CountChange;
  Result.HandleNeeded;
end;

function TCheckTestCase.NewSwitch(const ACaption: string): TPPGToggleSwitch;
begin
  Result := TPPGToggleSwitch.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 160, 28);
  Result.Caption := ACaption;
  Result.Animation.Enabled := False;
  Result.OnClick := CountClick;
  Result.OnChange := CountChange;
  Result.HandleNeeded;
end;

{ TCheckBoxTests }

procedure TCheckBoxTests.ClickTogglesAndFiresBothEvents;
var
  C: TPPGCheckBox;
begin
  C := NewCheck;
  C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(5, 5));
  C.Perform(WM_LBUTTONUP, 0, MakeLParam(5, 5));
  CheckTrue(C.Checked);
  CheckEquals(1, FClicks, 'OnClick');
  CheckEquals(1, FChanges, 'OnChange');
  C.Click;
  CheckFalse(C.Checked);
  CheckEquals(2, FClicks);
  CheckEquals(2, FChanges);
end;

procedure TCheckBoxTests.ProgrammaticChangeFiresOnlyOnChange;
var
  C: TPPGCheckBox;
begin
  C := NewCheck;
  C.Checked := True;
  CheckEquals(0, FClicks, 'Code darf KEIN OnClick ausloesen (anders als VCL)');
  CheckEquals(1, FChanges);
  C.State := cbGrayed;
  CheckEquals(2, FChanges);
end;

procedure TCheckBoxTests.SettingSameValueFiresNothing;
var
  C: TPPGCheckBox;
begin
  C := NewCheck;
  C.Checked := False;
  C.State := cbUnchecked;
  CheckEquals(0, FChanges);
end;

procedure TCheckBoxTests.AllowGrayedCyclesLikeVcl;
var
  C: TPPGCheckBox;
begin
  C := NewCheck;
  C.AllowGrayed := True;
  C.Click;
  CheckTrue(C.State = cbGrayed, 'unchecked -> grayed');
  C.Click;
  CheckTrue(C.State = cbChecked, 'grayed -> checked');
  C.Click;
  CheckTrue(C.State = cbUnchecked, 'checked -> unchecked');
end;

procedure TCheckBoxTests.SpaceKeyToggles;
var
  C: TPPGCheckBox;
begin
  C := NewCheck;
  C.Perform(WM_KEYDOWN, VK_SPACE, 0);
  CheckFalse(C.Checked, 'erst beim Loslassen');
  C.Perform(WM_KEYUP, VK_SPACE, 0);
  CheckTrue(C.Checked);
  CheckEquals(1, FClicks);
end;

procedure TCheckBoxTests.AcceleratorTogglesAndFocuses;
var
  C, Other: TPPGCheckBox;
begin
  FForm.Show;
  try
    Other := NewCheck('Andere');
    Other.SetFocus;
    C := NewCheck('&Drucken');
    C.Top := 60;
    CheckEquals(1, C.Perform(CM_DIALOGCHAR, Ord('d'), 0));
    CheckTrue(C.Checked);
    CheckTrue(C.Focused, 'Accelerator muss fokussieren');
  finally
    FForm.Hide;
  end;
end;

procedure TCheckBoxTests.ExceptionInOnChangeKeepsConsistentState;
var
  C: TPPGCheckBox;
begin
  C := NewCheck;
  C.OnChange := RaisingChange;
  C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(5, 5));
  try
    C.Perform(WM_LBUTTONUP, 0, MakeLParam(5, 5));
    Fail('Exception aus OnChange muss propagieren');
  except
    on E: EAbort do
      ;
  end;
  CheckTrue(C.Checked, 'Zustand wurde vor dem Ereignis gesetzt');
  CheckFalse(TCheckAccess(C).MousePressed, 'Control haengt im gedrueckten Zustand');
  CheckEquals(0, FClicks, 'OnClick nach fehlgeschlagenem OnChange nicht mehr ausgeloest');
end;

procedure TCheckBoxTests.DisabledIgnoresInput;
var
  C: TPPGCheckBox;
begin
  C := NewCheck('&Aus');
  C.Enabled := False;
  C.Perform(WM_KEYDOWN, VK_SPACE, 0);
  C.Perform(WM_KEYUP, VK_SPACE, 0);
  CheckEquals(0, C.Perform(CM_DIALOGCHAR, Ord('a'), 0));
  CheckFalse(C.Checked);
  CheckEquals(0, FChanges);
end;

procedure TCheckBoxTests.ActionSyncsChecked;
var
  C: TPPGCheckBox;
  A: TAction;
begin
  A := TAction.Create(FForm);
  A.Caption := 'Mit Action';
  A.Checked := True;
  C := NewCheck('');
  C.Action := A;
  CheckTrue(C.Checked, 'Action.Checked -> Control');
  CheckEquals('Mit Action', C.Caption);
  A.Checked := False;
  CheckFalse(C.Checked, 'Action-Aenderung muss ankommen');
end;

procedure TCheckBoxTests.LoadsVclStyleDfmWithoutEvents;
var
  Src: TStringStream;
  Bin: TMemoryStream;
  C: TPPGCheckBox;
begin
  // Exakt die Syntax einer VCL-TCheckBox-DFM -> Migration per Suchen/Ersetzen
  Src := TStringStream.Create(
    'object CB1: TPPGCheckBox'#13#10 +
    '  AllowGrayed = True'#13#10 +
    '  State = cbGrayed'#13#10 +
    '  Caption = ''Migriert'''#13#10 +
    'end');
  Bin := TMemoryStream.Create;
  try
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    C := TPPGCheckBox.Create(FForm);
    C.OnChange := CountChange;
    Bin.ReadComponent(C);
    CheckTrue(C.State = cbGrayed);
    CheckTrue(C.AllowGrayed);
    CheckEquals(0, FChanges, 'Beim Laden kein OnChange');
  finally
    Bin.Free;
    Src.Free;
  end;
end;

procedure TCheckBoxTests.AnimatesOnlyWhenVisible;
var
  C: TPPGCheckBox;
begin
  C := NewCheck;
  C.Animation.Enabled := True;
  C.Animation.RespectSystemSettings := False;
  C.Animation.Duration := 2000;
  C.Checked := True; // Formular unsichtbar
  CheckEquals(1.0, TCheckAccess(C).CheckProgress, 0.001, 'unsichtbar: sofort springen');
  FForm.Show;
  try
    C.Checked := False;
    CheckTrue(TCheckAccess(C).CheckProgress > 0.5, 'sichtbar: Animation laeuft');
  finally
    FForm.Hide;
  end;
  C.Free; // laufende Animation muss sauber abgemeldet werden
end;

{ TRadioButtonTests }

procedure TRadioButtonTests.CheckingOneUnchecksSiblings;
var
  R1, R2, R3: TPPGRadioButton;
begin
  R1 := NewRadio('A');
  R2 := NewRadio('B');
  R3 := NewRadio('C');
  R1.Checked := True;
  R2.Click;
  CheckFalse(R1.Checked);
  CheckTrue(R2.Checked);
  CheckFalse(R3.Checked);
  R3.Checked := True;
  CheckFalse(R2.Checked);
end;

procedure TRadioButtonTests.GroupsAreIndependent;
var
  A1, A2, B1: TPPGRadioButton;
begin
  A1 := NewRadio('A1', 1);
  A2 := NewRadio('A2', 1);
  B1 := NewRadio('B1', 2);
  A1.Checked := True;
  B1.Checked := True;
  CheckTrue(A1.Checked, 'andere Gruppe darf nicht abschalten');
  A2.Checked := True;
  CheckFalse(A1.Checked);
  CheckTrue(B1.Checked);
end;

procedure TRadioButtonTests.ClickOnCheckedStaysChecked;
var
  R: TPPGRadioButton;
begin
  R := NewRadio('A');
  R.Click;
  R.Click;
  CheckTrue(R.Checked);
  CheckEquals(2, FClicks);
  CheckEquals(1, FChanges, 'zweiter Klick aendert nichts');
end;

procedure TRadioButtonTests.ArrowKeysMoveSelectionWithWrap;
var
  R1, R2, R3: TPPGRadioButton;
begin
  FForm.Show;
  try
    R1 := NewRadio('A');
    R2 := NewRadio('B');
    R3 := NewRadio('C');
    R1.Checked := True;
    R1.SetFocus;
    R1.Perform(WM_KEYDOWN, VK_DOWN, 0);
    CheckTrue(R2.Checked and R2.Focused, 'Pfeil runter -> naechster');
    R2.Perform(WM_KEYDOWN, VK_DOWN, 0);
    R3.Perform(WM_KEYDOWN, VK_DOWN, 0);
    CheckTrue(R1.Checked and R1.Focused, 'Umlauf am Ende');
    R1.Perform(WM_KEYDOWN, VK_UP, 0);
    CheckTrue(R3.Checked, 'Pfeil hoch mit Umlauf');
  finally
    FForm.Hide;
  end;
end;

procedure TRadioButtonTests.WantsArrowKeys;
var
  R: TPPGRadioButton;
begin
  R := NewRadio('A');
  CheckTrue((R.Perform(WM_GETDLGCODE, 0, 0) and DLGC_WANTARROWS) <> 0);
end;

procedure TRadioButtonTests.SiblingOnChangeFires;
var
  R1, R2: TPPGRadioButton;
begin
  R1 := NewRadio('A');
  R2 := NewRadio('B');
  R1.Checked := True;
  FChanges := 0;
  R2.Checked := True;
  CheckEquals(2, FChanges, 'Ein- UND Ausschalten melden');
end;

{ TToggleSwitchTests }

procedure TToggleSwitchTests.ClickToggles;
var
  S: TPPGToggleSwitch;
begin
  S := NewSwitch;
  S.Click;
  CheckTrue(S.Checked);
  S.Click;
  CheckFalse(S.Checked);
  CheckEquals(2, FChanges);
end;

procedure TToggleSwitchTests.ThumbPositionFollowsState;
var
  S: TPPGToggleSwitch;
  Bmp: TBitmap;
  ThumbColor: TColor;
begin
  S := NewSwitch('');
  S.Preset := PPGPresetModernFlat;
  ThumbColor := S.Appearance.Normal.TextColor;
  // Indikator: x = 4..44, y = 4..24; Knopf-Mitte links bei ~x=14, rechts bei ~x=34
  Bmp := RenderToBitmap(S);
  try
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[14, 14], ThumbColor) < 60, 'Knopf links bei aus');
  finally
    Bmp.Free;
  end;
  S.Checked := True;
  Bmp := RenderToBitmap(S);
  try
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[34, 14], S.Appearance.Checked.TextColor) < 60,
      'Knopf rechts bei an');
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[14, 14], S.Appearance.Checked.Color) < 60,
      'Spur in An-Farbe');
  finally
    Bmp.Free;
  end;
end;

procedure TToggleSwitchTests.RightToLeftMirrorsThumb;
var
  S: TPPGToggleSwitch;
  Bmp: TBitmap;
begin
  S := NewSwitch('');
  S.Preset := PPGPresetModernFlat;
  S.BiDiMode := bdRightToLeft;
  S.Checked := True;
  Bmp := RenderToBitmap(S);
  try
    // Bei RTL steht der Indikator rechts, der "an"-Knopf links in der Spur
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[S.Width - 34, 14], S.Appearance.Checked.TextColor) < 60,
      'RTL: Knopf muss links in der Spur stehen');
  finally
    Bmp.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

{ TCheckPaintTests }

procedure TCheckPaintTests.AllControlsAllStatesBothPresetsPaintWithoutErrors;
const
  Presets: array[0..1] of string = (PPGPresetClassic, PPGPresetModernFlat);
var
  P, K, St, E, G: Integer;
  C: TPPGCustomCheckControl;
begin
  FForm.Show;
  try
    for G := 0 to 1 do
    begin
      TPPGRendererRegistry.ForceGdiFallback := G = 1;
      for P := 0 to High(Presets) do
        for K := 0 to 2 do
          for St := 0 to 2 do
            for E := 0 to 1 do
            begin
              case K of
                0: C := NewCheck('Text');
                1: C := NewRadio('Text');
              else
                C := NewSwitch('Text');
              end;
              try
                TCheckAccess(C).Preset := Presets[P];
                if (K = 0) then
                begin
                  TPPGCheckBox(C).AllowGrayed := True;
                  TPPGCheckBox(C).State := TCheckBoxState(St);
                end
                else
                  TCheckAccess(C).Checked := St = 1;
                C.Enabled := E = 0;
                if C.Enabled then
                  C.SetFocus;
                TCheckAccess(C).Alignment := TLeftRight(St mod 2);
                RenderToBitmap(C).Free;
              finally
                C.Free;
              end;
            end;
    end;
  finally
    TPPGRendererRegistry.ForceGdiFallback := False;
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCheckPaintTests.CheckedIndicatorUsesCheckedColor;
var
  C: TPPGCheckBox;
  Bmp: TBitmap;
begin
  C := NewCheck('');
  C.Preset := PPGPresetModernFlat;
  // Indikator 16x16 ab x=4, vertikal zentriert; Punkt in der Fuellung oberhalb des Hakens
  Bmp := RenderToBitmap(C);
  try
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[12, 6], C.Appearance.Normal.Color) < 30, 'aus: Normal-Farbe');
  finally
    Bmp.Free;
  end;
  C.Checked := True;
  Bmp := RenderToBitmap(C);
  try
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[12, 6], C.Appearance.Checked.Color) < 30, 'an: Checked-Farbe');
  finally
    Bmp.Free;
  end;
end;

procedure TCheckPaintTests.NoHandleOrMemoryLeaks;

  procedure Cycle;
  var
    I: Integer;
    C: TPPGCheckBox;
    R: TPPGRadioButton;
    S: TPPGToggleSwitch;
  begin
    for I := 1 to 40 do
    begin
      C := NewCheck('Leak');
      C.Checked := True;
      RenderToBitmap(C).Free;
      C.Free;
      R := NewRadio('Leak');
      R.Click;
      RenderToBitmap(R).Free;
      R.Free;
      S := NewSwitch('Leak');
      S.Perform(CM_MOUSEENTER, 0, 0);
      RenderToBitmap(S).Free;
      S.Free;
    end;
  end;

var
  Gdi0, User0: Cardinal;
  S0, S1: TMemoryManagerState;
  Used0, Used1: NativeUInt;
  I: Integer;
begin
  Cycle;
  Gdi0 := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
  User0 := GetGuiResources(GetCurrentProcess, GR_USEROBJECTS);
  GetMemoryManagerState(S0);
  Cycle;
  Cycle;
  GetMemoryManagerState(S1);
  Used0 := S0.TotalAllocatedMediumBlockSize + S0.TotalAllocatedLargeBlockSize;
  Used1 := S1.TotalAllocatedMediumBlockSize + S1.TotalAllocatedLargeBlockSize;
  for I := Low(S0.SmallBlockTypeStates) to High(S0.SmallBlockTypeStates) do
  begin
    Inc(Used0, S0.SmallBlockTypeStates[I].AllocatedBlockCount * S0.SmallBlockTypeStates[I].UseableBlockSize);
    Inc(Used1, S1.SmallBlockTypeStates[I].AllocatedBlockCount * S1.SmallBlockTypeStates[I].UseableBlockSize);
  end;
  CheckTrue(GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS) <= Gdi0 + 2, 'GDI-Handles wachsen');
  CheckTrue(GetGuiResources(GetCurrentProcess, GR_USEROBJECTS) <= User0 + 2, 'USER-Handles wachsen');
  CheckTrue(Used1 <= Used0 + 1024, Format('Speicher waechst: %d -> %d', [Used0, Used1]));
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterTest('Phase2', TCheckBoxTests.Suite);
  RegisterTest('Phase2', TRadioButtonTests.Suite);
  RegisterTest('Phase2', TToggleSwitchTests.Suite);
  RegisterTest('Phase2', TCheckPaintTests.Suite);

end.
