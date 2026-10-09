unit PPG.Tests.Phase4a;

{ Tests fuer Phase 4a: Feld-Basis, TPPGEdit, TPPGMemo, TPPGSpinEdit. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, Winapi.ActiveX, Winapi.oleacc,
  System.Classes, System.SysUtils, System.Types, System.Variants,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Vcl.Menus,
  PPG.Types, PPG.Consts, PPG.Exceptions, PPG.Render.Intf, PPG.Render.Registry,
  PPG.Button, PPG.Controls.Field, PPG.Edit, PPG.Memo, PPG.SpinEdit,
  PPG.Tests.Controls, PPG.Tests.Gaps;

type
  TPhase4TestCase = class(TGapTestCase)
  protected
    FChanges, FEnters, FExits, FKeyDowns, FKeyPresses, FButtonClicks: Integer;
    FLastSender: TObject;
    FLastX, FLastY: Integer;
    FComInit: Boolean;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure CountChange(Sender: TObject);
    procedure CountEnter(Sender: TObject);
    procedure CountExit(Sender: TObject);
    procedure CountButton(Sender: TObject);
    procedure RecordKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure RecordKeyPress(Sender: TObject; var Key: Char);
    procedure RecordMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    function NewEdit(W: Integer = 200): TPPGEdit;
    function NewMemo: TPPGMemo;
    function NewSpin: TPPGSpinEdit;
    procedure ClickAt(C: TWinControl; X, Y: Integer);
    /// Verarbeitet nur WM_TIMER (Animator), ohne Application.Idle/DoMouseIdle.
    procedure PumpTimers(Ms: Cardinal);
  end;

  TFieldTests = class(TPhase4TestCase)
  published
    procedure DefaultsMatchTEdit;
    procedure FocusGoesToInnerAndEnterExitFire;
    procedure TabReachesInnerEdit;
    procedure ActiveControlForwardsFocus;
    procedure OnChangeOncePerRealChange;
    procedure KeyEventsArriveAtField;
    procedure MouseCoordinatesAreTranslated;
    procedure AutoSizeFollowsFontAndCentersText;
    procedure TextHintOnlyWhenEmptyAndUnfocused;
    procedure ClearButtonClearsAndFiresChange;
    procedure ReadOnlyHidesClearButton;
    procedure SideButtonsLayoutClickAndRtl;
    procedure DropDownMenuFreedClearsReference;
    procedure FocusLineInAccentColorBothPresets;
    procedure ValidationStateColorsBorder;
    procedure DisabledPropagatesToInner;
    procedure CornersShowParentColor;
    procedure PasswordIsNotExposed;
    procedure InnerEditGetsAccessibleName;
    procedure LoadsTEditDfmAndRoundTrips;
  end;

  TMemoFieldTests = class(TPhase4TestCase)
  published
    procedure LinesAndMemoProperties;
    procedure NoAutoSizeAndInnerFillsField;
    procedure LoadsTMemoDfm;
  end;

  TSpinEditTests = class(TPhase4TestCase)
  published
    procedure ClampsLikeTSpinEdit;
    procedure IncrementIsValidated;
    procedure KeysAndWheelSpin;
    procedure ButtonsClickAndRepeatWhileHeld;
    procedure ButtonsDisabledAtBounds;
    procedure InvalidInputIsNormalized;
    procedure EditorDisabledStillSpins;
    procedure LoadsTSpinEditDfm;
    procedure AccessibilityRoleAndValue;
  end;

  TPhase4aPaintTests = class(TPhase4TestCase)
  published
    procedure AllFieldsAllVariantsPaintWithoutErrors;
    procedure ExtremeSizesPaintWithoutErrors;
    procedure NoHandleOrMemoryLeaks;
  end;

implementation

{$WARN SYMBOL_PLATFORM OFF}

type
  TFieldAccess = class(TPPGEdit);
  TBaseFieldAccess = class(TPPGCustomField);
  TMemoFieldAccess = class(TPPGMemo);
  TSpinAccess = class(TPPGSpinEdit);
  TInnerAccess = class(TCustomEdit);

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

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Cardinal(Word(SmallInt(X))) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

function AllocatedBytes: NativeUInt;
var
  S: TMemoryManagerState;
  I: Integer;
begin
  GetMemoryManagerState(S);
  Result := S.TotalAllocatedMediumBlockSize + S.TotalAllocatedLargeBlockSize;
  for I := Low(S.SmallBlockTypeStates) to High(S.SmallBlockTypeStates) do
    Inc(Result, S.SmallBlockTypeStates[I].AllocatedBlockCount *
      S.SmallBlockTypeStates[I].UseableBlockSize);
end;

procedure LoadDfm(const Text: string; Instance: TComponent);
var
  Src: TStringStream;
  Bin: TMemoryStream;
begin
  Src := TStringStream.Create(Text);
  Bin := TMemoryStream.Create;
  try
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    Bin.ReadComponent(Instance);
  finally
    Bin.Free;
    Src.Free;
  end;
end;

function ComponentToText(C: TComponent): string;
var
  Bin: TMemoryStream;
  Txt: TStringStream;
begin
  Bin := TMemoryStream.Create;
  Txt := TStringStream.Create('');
  try
    Bin.WriteComponent(C);
    Bin.Position := 0;
    ObjectBinaryToText(Bin, Txt);
    Result := Txt.DataString;
  finally
    Txt.Free;
    Bin.Free;
  end;
end;

function CountDiff(A, B: TBitmap; const R: TRect): Integer;
var
  X, Y: Integer;
begin
  Result := 0;
  for Y := R.Top to R.Bottom - 1 do
    for X := R.Left to R.Right - 1 do
      if A.Canvas.Pixels[X, Y] <> B.Canvas.Pixels[X, Y] then
        Inc(Result);
end;

{ TPhase4TestCase }

procedure TPhase4TestCase.SetUp;
begin
  inherited;
  FChanges := 0;
  FEnters := 0;
  FExits := 0;
  FKeyDowns := 0;
  FKeyPresses := 0;
  FButtonClicks := 0;
  FLastSender := nil;
  // Wie in praktisch jeder VCL-Anwendung (ComObj): COM fuer IAccPropServices
  FComInit := Succeeded(CoInitialize(nil));
end;

procedure TPhase4TestCase.TearDown;
begin
  inherited;
  if FComInit then
    CoUninitialize;
end;

procedure TPhase4TestCase.CountChange(Sender: TObject);
begin
  Inc(FChanges);
  FLastSender := Sender;
end;

procedure TPhase4TestCase.CountEnter(Sender: TObject);
begin
  Inc(FEnters);
end;

procedure TPhase4TestCase.CountExit(Sender: TObject);
begin
  Inc(FExits);
end;

procedure TPhase4TestCase.CountButton(Sender: TObject);
begin
  Inc(FButtonClicks);
end;

procedure TPhase4TestCase.RecordKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  Inc(FKeyDowns);
  FLastSender := Sender;
end;

procedure TPhase4TestCase.RecordKeyPress(Sender: TObject; var Key: Char);
begin
  Inc(FKeyPresses);
  FLastSender := Sender;
end;

procedure TPhase4TestCase.RecordMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FLastSender := Sender;
  FLastX := X;
  FLastY := Y;
end;

function TPhase4TestCase.NewEdit(W: Integer): TPPGEdit;
begin
  Result := TPPGEdit.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, W, 25);
  Result.Preset := PPGPresetModernFlat;
  Result.Animation.Enabled := False;
  Result.OnChange := CountChange;
  Result.HandleNeeded;
end;

function TPhase4TestCase.NewMemo: TPPGMemo;
begin
  Result := TPPGMemo.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 50, 200, 100);
  Result.Preset := PPGPresetModernFlat;
  Result.Animation.Enabled := False;
  Result.OnChange := CountChange;
  Result.HandleNeeded;
end;

function TPhase4TestCase.NewSpin: TPPGSpinEdit;
begin
  Result := TPPGSpinEdit.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 160, 140, 25);
  Result.Preset := PPGPresetModernFlat;
  Result.Animation.Enabled := False;
  Result.OnChange := CountChange;
  Result.HandleNeeded;
end;

procedure TPhase4TestCase.ClickAt(C: TWinControl; X, Y: Integer);
begin
  C.Perform(WM_MOUSEMOVE, 0, MouseLParam(X, Y));
  C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(X, Y));
  C.Perform(WM_LBUTTONUP, 0, MouseLParam(X, Y));
end;

procedure TPhase4TestCase.PumpTimers(Ms: Cardinal);
var
  Start: Cardinal;
  Msg: TMsg;
begin
  Start := GetTickCount;
  while GetTickCount - Start < Ms do
    if PeekMessage(Msg, 0, WM_TIMER, WM_TIMER, PM_REMOVE) then
      DispatchMessage(Msg)
    else
      Sleep(2);
end;

function CenterOf(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

{ TFieldTests }

procedure TFieldTests.DefaultsMatchTEdit;
var
  E: TPPGEdit;
begin
  E := NewEdit;
  CheckEquals(200, E.Width);
  CheckTrue(E.AutoSize);
  CheckEquals(clWindow, E.Color);
  CheckFalse(E.ParentColor);
  CheckTrue(E.TabStop, 'TabStop des Edits');
  CheckFalse(TWinControl(E).TabStop, 'das Feld selbst ist kein Tabstopp');
  CheckEquals('', E.Text);
  CheckEquals('', TBaseFieldAccess(E).Caption, 'kein Komponentenname als Caption');
  CheckEquals(0, E.MaxLength);
  CheckTrue(E.Alignment = taLeftJustify);
  CheckTrue(E.BorderStyle = bsSingle);
  CheckTrue(E.AutoSelect);
  CheckTrue(E.HideSelection);
  CheckFalse(E.ShowClearButton);
  CheckTrue(E.ValidationState = pvsNone);
  E := TPPGEdit.Create(nil);
  try
    CheckEquals(121, E.Width, 'Standardbreite wie TEdit');
  finally
    E.Free;
  end;
end;

procedure TFieldTests.FocusGoesToInnerAndEnterExitFire;
var
  E: TPPGEdit;
  B: TPPGButton;
begin
  FForm.Show;
  try
    E := NewEdit;
    E.OnEnter := CountEnter;
    E.OnExit := CountExit;
    B := NewButton('B');
    B.Top := 200;
    E.SetFocus;
    CheckTrue(TFieldAccess(E).Inner.Focused, 'Fokus liegt im inneren Edit');
    CheckTrue(E.Focused, 'Focused des Felds');
    CheckTrue(TFieldAccess(E).FieldFocused);
    CheckEquals(1, FEnters, 'OnEnter');
    CheckEquals(1.0, TFieldAccess(E).FocusProgress, 0.001, 'Fokuslinie ohne Animation sofort');
    B.SetFocus;
    CheckEquals(1, FExits, 'OnExit');
    CheckFalse(E.Focused);
    CheckEquals(0.0, TFieldAccess(E).FocusProgress, 0.001);
  finally
    FForm.Hide;
  end;
end;

procedure TFieldTests.TabReachesInnerEdit;
var
  B1, B2: TPPGButton;
  E: TPPGEdit;
begin
  FForm.Show;
  try
    B1 := NewButton('1');
    E := NewEdit;
    E.Top := 60;
    B2 := NewButton('2');
    B2.Top := 120;
    B1.TabOrder := 0;
    E.TabOrder := 1;
    B2.TabOrder := 2;
    B1.SetFocus;
    FForm.Perform(WM_NEXTDLGCTL, 0, 0);
    CheckTrue(TFieldAccess(E).Inner.Focused, 'Tab landet im Edit, nicht im Rahmen');
    FForm.Perform(WM_NEXTDLGCTL, 0, 0);
    CheckTrue(B2.Focused, 'naechster Tab verlaesst das Feld (genau ein Tabstopp)');
    E.TabStop := False;
    B1.SetFocus;
    FForm.Perform(WM_NEXTDLGCTL, 0, 0);
    CheckTrue(B2.Focused, 'TabStop = False ueberspringt das Feld');
  finally
    FForm.Hide;
  end;
end;

procedure TFieldTests.ActiveControlForwardsFocus;
var
  E: TPPGEdit;
begin
  E := NewEdit;
  FForm.ActiveControl := E;
  FForm.Show;
  try
    Application.ProcessMessages;
    CheckTrue(TFieldAccess(E).Inner.Focused, 'ActiveControl = Feld -> Fokus im Edit');
  finally
    FForm.Hide;
  end;
end;

procedure TFieldTests.OnChangeOncePerRealChange;
var
  E: TPPGEdit;
begin
  E := NewEdit;
  E.Text := 'abc';
  CheckEquals(1, FChanges);
  CheckSame(E, FLastSender, 'Sender ist das Feld');
  E.Text := 'abc';
  CheckEquals(1, FChanges, 'gleicher Text');
  // Eingabe wie beim Tippen (EM_REPLACESEL an der Einfuegemarke)
  E.SelStart := 3;
  SendMessage(TFieldAccess(E).Inner.Handle, EM_REPLACESEL, 1, LPARAM(PChar('x')));
  CheckEquals(2, FChanges, 'Tippen');
  CheckEquals('abcx', E.Text);
  CheckTrue(E.Modified);
end;

procedure TFieldTests.KeyEventsArriveAtField;
var
  E: TPPGEdit;
begin
  E := NewEdit;
  E.OnKeyDown := RecordKeyDown;
  E.OnKeyPress := RecordKeyPress;
  TFieldAccess(E).Inner.Perform(WM_KEYDOWN, VK_LEFT, 0);
  CheckEquals(1, FKeyDowns);
  CheckSame(E, FLastSender);
  TFieldAccess(E).Inner.Perform(WM_CHAR, Ord('a'), 0);
  CheckEquals(1, FKeyPresses);
  CheckSame(E, FLastSender);
end;

procedure TFieldTests.MouseCoordinatesAreTranslated;
var
  E: TPPGEdit;
  I: TCustomEdit;
begin
  E := NewEdit;
  E.OnMouseDown := RecordMouseDown;
  I := TFieldAccess(E).Inner;
  I.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(3, 4));
  I.Perform(WM_LBUTTONUP, 0, MouseLParam(3, 4));
  CheckSame(E, FLastSender);
  CheckEquals(I.Left + 3, FLastX, 'X in Feld-Koordinaten');
  CheckEquals(I.Top + 4, FLastY, 'Y in Feld-Koordinaten');
end;

procedure TFieldTests.AutoSizeFollowsFontAndCentersText;
var
  E: TPPGEdit;
  I: TCustomEdit;
  H0, Mid: Integer;
begin
  E := NewEdit;
  H0 := E.Height;
  CheckTrue((H0 >= 20) and (H0 <= 30), Format('Hoehe wie TEdit (%d)', [H0]));
  E.Font.Size := 20;
  CheckTrue(E.Height > H0 + 10, 'groessere Schrift -> hoeher');
  I := TFieldAccess(E).Inner;
  Mid := I.Top * 2 + I.Height;
  CheckTrue(Abs(Mid - E.ClientHeight) <= 2,
    Format('Text vertikal mittig (%d/%d)', [Mid, E.ClientHeight]));
  E.AutoSize := False;
  E.Height := 60;
  E.Font.Size := 8;
  CheckEquals(60, E.Height, 'ohne AutoSize bleibt die Hoehe');
  Mid := I.Top * 2 + I.Height;
  CheckTrue(Abs(Mid - E.ClientHeight) <= 2, 'auch im hohen Feld mittig');
end;

procedure TFieldTests.TextHintOnlyWhenEmptyAndUnfocused;
var
  E: TPPGEdit;
  B0, B1: TBitmap;
  I: TCustomEdit;
  R: TRect;
begin
  E := NewEdit;
  I := TFieldAccess(E).Inner;
  R := I.BoundsRect;
  B0 := RenderToBitmap(E);
  try
    E.TextHint := 'WWWWWW';
    CheckTrue(TFieldAccess(E).TextHintShowing);
    B1 := RenderToBitmap(E);
    try
      CheckTrue(CountDiff(B0, B1, R) > 20, 'Hint wird im Edit gezeichnet');
    finally
      B1.Free;
    end;
  finally
    B0.Free;
  end;
  E.Text := 'x';
  CheckFalse(TFieldAccess(E).TextHintShowing, 'mit Text kein Hint');
  E.Text := '';
  CheckTrue(TFieldAccess(E).TextHintShowing);
  FForm.Show;
  try
    E.SetFocus;
    CheckFalse(TFieldAccess(E).TextHintShowing, 'mit Fokus (Standard) kein Hint');
    E.TextHintVisibleOnFocus := True;
    CheckTrue(TFieldAccess(E).TextHintShowing);
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TFieldTests.ClearButtonClearsAndFiresChange;
var
  E: TPPGEdit;
  P: TPoint;
  W0: Integer;
begin
  E := NewEdit;
  W0 := TFieldAccess(E).Inner.Width;
  E.ShowClearButton := True;
  CheckTrue(TFieldAccess(E).Inner.Width < W0, 'Platz fuer den Button reserviert');
  E.Text := 'abc';
  FChanges := 0;
  P := CenterOf(TFieldAccess(E).ButtonRect(PPGFieldButtonClear));
  CheckEquals(-1, TFieldAccess(E).ButtonAt(P.X, P.Y), 'ohne Hover/Fokus unsichtbar');
  FForm.Show;
  try
    E.SetFocus;
    CheckTrue(TFieldAccess(E).ButtonAt(P.X, P.Y) >= 0, 'mit Fokus sichtbar');
    ClickAt(E, P.X, P.Y);
    CheckEquals('', E.Text);
    CheckEquals(1, FChanges, 'genau ein OnChange');
    CheckTrue(TFieldAccess(E).Inner.Focused, 'Fokus bleibt im Edit');
    CheckEquals(-1, TFieldAccess(E).ButtonAt(P.X, P.Y), 'ohne Text unsichtbar');
  finally
    FForm.Hide;
  end;
end;

procedure TFieldTests.ReadOnlyHidesClearButton;
var
  E: TPPGEdit;
  P: TPoint;
  Acc: IAccessible;
begin
  FForm.Show;
  try
    E := NewEdit;
    E.ShowClearButton := True;
    E.Text := 'abc';
    E.ReadOnly := True;
    E.SetFocus;
    P := CenterOf(TFieldAccess(E).ButtonRect(PPGFieldButtonClear));
    CheckEquals(-1, TFieldAccess(E).ButtonAt(P.X, P.Y), 'ReadOnly: kein Loeschen');
    Acc := AccOf(E);
    CheckTrue(AccState(Acc) and STATE_SYSTEM_READONLY <> 0);
  finally
    FForm.Hide;
  end;
end;

procedure TFieldTests.SideButtonsLayoutClickAndRtl;
var
  E: TPPGEdit;
  RL, RR: TRect;
  P: TPoint;
begin
  E := NewEdit;
  E.LeftButton.Visible := True;
  E.RightButton.Visible := True;
  E.OnRightButtonClick := CountButton;
  RL := TFieldAccess(E).ButtonRect(PPGEditButtonLeft);
  RR := TFieldAccess(E).ButtonRect(PPGEditButtonRight);
  CheckFalse(IsRectEmpty(RL));
  CheckFalse(IsRectEmpty(RR));
  CheckTrue(TFieldAccess(E).Inner.Left >= RL.Right, 'Text rechts vom linken Button');
  CheckTrue(TFieldAccess(E).Inner.BoundsRect.Right <= RR.Left, 'Text links vom rechten Button');
  P := CenterOf(RR);
  ClickAt(E, P.X, P.Y);
  CheckEquals(1, FButtonClicks);
  E.RightButton.Enabled := False;
  ClickAt(E, P.X, P.Y);
  CheckEquals(1, FButtonClicks, 'deaktivierter Button');
  E.BiDiMode := bdRightToLeft;
  RL := TFieldAccess(E).ButtonRect(PPGEditButtonLeft);
  CheckTrue(RL.Left > E.Width div 2, 'RTL: linker Button steht rechts');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TFieldTests.DropDownMenuFreedClearsReference;
var
  E: TPPGEdit;
  M: TPopupMenu;
begin
  E := NewEdit;
  M := TPopupMenu.Create(FForm);
  E.RightButton.DropDownMenu := M;
  E.LeftButton.DropDownMenu := M;
  E.RightButton.Visible := True;
  M.Free;
  CheckNull(E.RightButton.DropDownMenu);
  CheckNull(E.LeftButton.DropDownMenu);
  RenderToBitmap(E).Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TFieldTests.FocusLineInAccentColorBothPresets;
const
  Presets: array[0..1] of string = (PPGPresetModernFlat, PPGPresetClassic);
var
  E: TPPGEdit;
  B: TPPGButton;
  Bmp: TBitmap;
  I: Integer;
  Gdi: Boolean;
begin
  FForm.Show;
  try
    E := NewEdit;
    B := NewButton('B');
    B.Top := 200;
    for Gdi := False to True do
      for I := 0 to High(Presets) do
      begin
        TPPGRendererRegistry.ForceGdiFallback := Gdi;
        E.Preset := Presets[I];
        E.SetFocus;
        Bmp := RenderToBitmap(E);
        try
          CheckTrue(ColorDist(Bmp.Canvas.Pixels[E.Width div 2, E.Height - 1],
            E.Appearance.FocusColor) < 60, Presets[I] + ': Fokus unten in Akzentfarbe');
        finally
          Bmp.Free;
        end;
        B.SetFocus;
        Bmp := RenderToBitmap(E);
        try
          CheckTrue(ColorDist(Bmp.Canvas.Pixels[E.Width div 2, E.Height - 1],
            E.Appearance.FocusColor) > 100, Presets[I] + ': ohne Fokus keine Akzentlinie');
        finally
          Bmp.Free;
        end;
      end;
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TFieldTests.ValidationStateColorsBorder;
var
  E: TPPGEdit;
  Bmp: TBitmap;
begin
  E := NewEdit;
  E.ValidationState := pvsError;
  E.ValidationHint := 'Pflichtfeld';
  Bmp := RenderToBitmap(E);
  try
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[0, E.Height div 2], PPGColorError) < 90,
      'Rahmen in Fehlerfarbe');
  finally
    Bmp.Free;
  end;
  CheckEquals('Pflichtfeld', TFieldAccess(E).Inner.Hint, 'Tooltip ueber dem Edit');
  CheckEquals('Pflichtfeld', TFieldAccess(E).AccDescription);
  E.ValidationState := pvsNone;
  CheckEquals('', TFieldAccess(E).Inner.Hint);
  Bmp := RenderToBitmap(E);
  try
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[0, E.Height div 2], PPGColorError) > 120);
  finally
    Bmp.Free;
  end;
end;

procedure TFieldTests.DisabledPropagatesToInner;
var
  E: TPPGEdit;
begin
  E := NewEdit;
  E.Enabled := False;
  CheckFalse(TFieldAccess(E).Inner.Enabled);
  CheckEquals(ColorToRGB(E.Appearance.Disabled.Color),
    ColorToRGB(TInnerAccess(TFieldAccess(E).Inner).Color), 'Edit in Feldfarbe');
  E.Enabled := True;
  CheckTrue(TFieldAccess(E).Inner.Enabled);
  CheckEquals(ColorToRGB(clWindow), ColorToRGB(TInnerAccess(TFieldAccess(E).Inner).Color));
  E.Color := clYellow;
  CheckEquals(ColorToRGB(clYellow), ColorToRGB(TInnerAccess(TFieldAccess(E).Inner).Color));
end;

procedure TFieldTests.CornersShowParentColor;
var
  E: TPPGEdit;
  Bmp: TBitmap;
begin
  // Regression: Ecken ausserhalb der Rundung zeigten Color (weiss) statt Parent
  FForm.Color := clRed;
  E := NewEdit;
  E.Appearance.Rounding := 8;
  Bmp := RenderToBitmap(E);
  try
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[0, 0], clRed) < 60, 'Ecke in Formularfarbe');
  finally
    Bmp.Free;
  end;
end;

procedure TFieldTests.PasswordIsNotExposed;
var
  E: TPPGEdit;
  W: WideString;
begin
  E := NewEdit;
  E.Text := 'geheim';
  CheckEquals(S_OK, AccOf(E).Get_accValue(CHILDID_SELF, W));
  CheckEquals('geheim', string(W));
  E.PasswordChar := '*';
  AccOf(E).Get_accValue(CHILDID_SELF, W);
  CheckEquals('', string(W), 'Kennwort nie an andere Prozesse');
end;

procedure TFieldTests.InnerEditGetsAccessibleName;
var
  E: TPPGEdit;
  L: TLabel;
  Acc: IAccessible;
  W: WideString;
  V: OleVariant;
begin
  FForm.Show;
  try
    E := NewEdit;
    E.TextHint := 'Suchbegriff';
    E.SetFocus;
    Acc := AccOf(TFieldAccess(E).Inner);
    CheckEquals(S_OK, Acc.Get_accName(CHILDID_SELF, W));
    CheckEquals('Suchbegriff', string(W), 'ohne Label: TextHint');
    CheckEquals(S_OK, Acc.Get_accRole(CHILDID_SELF, V));
    CheckEquals(ROLE_SYSTEM_TEXT, Integer(V), 'natives Edit bleibt TEXT');

    L := TLabel.Create(FForm);
    L.Parent := FForm;
    L.Caption := '&Nachname';
    L.FocusControl := E;
    NewButton('B').SetFocus;
    E.SetFocus;
    Acc := AccOf(TFieldAccess(E).Inner);
    Acc.Get_accName(CHILDID_SELF, W);
    CheckEquals('Nachname', string(W), 'Label mit FocusControl hat Vorrang');
  finally
    FForm.Hide;
  end;
end;

procedure TFieldTests.LoadsTEditDfmAndRoundTrips;
const
  Dfm =
    'object PPGEdit1: TPPGEdit'#13#10 +
    '  Left = 8'#13#10 +
    '  Top = 8'#13#10 +
    '  Width = 200'#13#10 +
    '  Height = 23'#13#10 +
    '  Alignment = taRightJustify'#13#10 +
    '  CharCase = ecUpperCase'#13#10 +
    '  MaxLength = 10'#13#10 +
    '  ReadOnly = True'#13#10 +
    '  TabOrder = 0'#13#10 +
    '  TabStop = False'#13#10 +
    '  Text = ''HALLO'''#13#10 +
    '  TextHint = ''Hinweis'''#13#10 +
    'end'#13#10;
var
  A, B: TPPGEdit;
  S: string;
  M: TMemoryStream;
begin
  A := TPPGEdit.Create(nil);
  B := nil;
  try
    A.OnChange := CountChange;
    LoadDfm(Dfm, A);
    CheckTrue(A.Alignment = taRightJustify);
    CheckTrue(A.CharCase = ecUpperCase);
    CheckEquals(10, A.MaxLength);
    CheckTrue(A.ReadOnly);
    CheckFalse(A.TabStop);
    CheckEquals('HALLO', A.Text);
    CheckEquals('Hinweis', A.TextHint);
    CheckEquals(0, FChanges, 'kein OnChange beim Laden');
    CheckTrue(TFieldAccess(A).HasText);

    S := ComponentToText(A);
    CheckEquals(0, Pos('TPPGFieldEdit', S), 'inneres Edit wird nicht gespeichert');
    M := TMemoryStream.Create;
    try
      M.WriteComponent(A);
      M.Position := 0;
      B := TPPGEdit.Create(nil);
      M.ReadComponent(B);
    finally
      M.Free;
    end;
    CheckEquals('HALLO', B.Text);
    CheckEquals(10, B.MaxLength);
    CheckFalse(B.TabStop);
    CheckTrue(A.Appearance.Equals(B.Appearance));
  finally
    B.Free;
    A.Free;
  end;
end;

{ TMemoFieldTests }

procedure TMemoFieldTests.LinesAndMemoProperties;
var
  M: TPPGMemo;
begin
  M := NewMemo;
  M.Lines.Add('eins');
  M.Lines.Add('zwei');
  CheckEquals(2, M.Lines.Count);
  CheckTrue(Pos('zwei', M.Text) > 0);
  CheckTrue(FChanges >= 1, 'OnChange');
  M.ScrollBars := ssVertical;
  M.WordWrap := False;
  M.WantTabs := True;
  CheckTrue(M.ScrollBars = ssVertical);
  CheckFalse(M.WordWrap);
  CheckTrue(M.WantTabs);
  CheckTrue(M.WantReturns);
  CheckTrue(TMemoFieldAccess(M).Inner is TCustomMemo);
end;

procedure TMemoFieldTests.NoAutoSizeAndInnerFillsField;
var
  M: TPPGMemo;
  I: TCustomEdit;
begin
  M := NewMemo;
  CheckFalse(TBaseFieldAccess(M).AutoSize);
  M.Font.Size := 24;
  CheckEquals(100, M.Height, 'Memo-Hoehe bleibt');
  I := TMemoFieldAccess(M).Inner;
  CheckTrue(I.Height > M.Height - 20, 'Memo fuellt das Feld');
  CheckTrue(I.Width > M.Width - 30);
  M.TextHint := 'Kommentar';
  RenderToBitmap(M).Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TMemoFieldTests.LoadsTMemoDfm;
const
  Dfm =
    'object Memo1: TPPGMemo'#13#10 +
    '  Lines.Strings = ('#13#10 +
    '    ''Zeile 1'''#13#10 +
    '    ''Zeile 2'')'#13#10 +
    '  ScrollBars = ssBoth'#13#10 +
    '  WantTabs = True'#13#10 +
    '  WordWrap = False'#13#10 +
    'end'#13#10;
var
  M: TPPGMemo;
begin
  // Wie beim Laden eines Formulars mit Parent (Lines braucht das Fenster)
  M := TPPGMemo.Create(nil);
  try
    M.Parent := FForm;
    LoadDfm(Dfm, M);
    CheckEquals(2, M.Lines.Count);
    CheckEquals('Zeile 2', M.Lines[1]);
    CheckTrue(M.ScrollBars = ssBoth);
    CheckTrue(M.WantTabs);
    CheckFalse(M.WordWrap);
  finally
    M.Free;
  end;
end;

{ TSpinEditTests }

procedure TSpinEditTests.ClampsLikeTSpinEdit;
var
  S: TPPGSpinEdit;
begin
  S := NewSpin;
  CheckEquals(0, S.Value);
  CheckEquals('0', S.Text);
  S.Value := 1000000;
  CheckEquals(1000000, S.Value, 'MinValue = MaxValue = 0: keine Grenze');
  S.Min := 10; // Max noch 0 -> vorlaeufig "verkehrt", wie bei TSpinEdit kein Fehler
  S.Max := 20;
  CheckEquals(20, S.Value, 'auf Max begrenzt');
  S.Value := 5;
  CheckEquals(10, S.Value);
  CheckEquals('10', S.Text);
  S.Value := 25;
  CheckEquals(20, S.Value);
  S.Min := 15;
  S.Max := 15;
  S.Value := 99;
  CheckEquals(99, S.Value, 'Min = Max: keine Grenze');
end;

procedure TSpinEditTests.IncrementIsValidated;
var
  S: TPPGSpinEdit;
begin
  S := NewSpin;
  S.Increment := 5;
  try
    S.Increment := 0;
    Fail('EPPGPropertyError erwartet');
  except
    on E: EPPGPropertyError do
      CheckEquals('Increment', E.PropertyName);
  end;
  CheckEquals(5, S.Increment);
end;

procedure TSpinEditTests.KeysAndWheelSpin;
var
  S: TPPGSpinEdit;
  I: TCustomEdit;
begin
  S := NewSpin;
  S.Increment := 2;
  I := TSpinAccess(S).Inner;
  I.Perform(WM_KEYDOWN, VK_UP, 0);
  CheckEquals(2, S.Value);
  I.Perform(WM_KEYDOWN, VK_PRIOR, 0);
  CheckEquals(22, S.Value, 'Bild auf = 10 Schritte');
  I.Perform(WM_KEYDOWN, VK_DOWN, 0);
  CheckEquals(20, S.Value);
  TInnerAccess(I).DoMouseWheel([], 120, Point(0, 0));
  CheckEquals(22, S.Value, 'Mausrad ueber das innere Edit');
  TInnerAccess(I).DoMouseWheel([], -120, Point(0, 0));
  CheckEquals(20, S.Value);
  S.ReadOnly := True;
  I.Perform(WM_KEYDOWN, VK_UP, 0);
  CheckEquals(20, S.Value, 'ReadOnly');
end;

procedure TSpinEditTests.ButtonsClickAndRepeatWhileHeld;
var
  S: TPPGSpinEdit;
  P: TPoint;
begin
  FForm.Show;
  try
    S := NewSpin;
    P := CenterOf(TSpinAccess(S).ButtonRect(PPGSpinButtonUp));
    ClickAt(S, P.X, P.Y);
    CheckEquals(1, S.Value, 'Klick');
    P := CenterOf(TSpinAccess(S).ButtonRect(PPGSpinButtonDown));
    ClickAt(S, P.X, P.Y);
    CheckEquals(0, S.Value);

    P := CenterOf(TSpinAccess(S).ButtonRect(PPGSpinButtonUp));
    S.Perform(WM_MOUSEMOVE, 0, MouseLParam(P.X, P.Y));
    S.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
    CheckEquals(1, S.Value, 'sofort ein Schritt');
    PumpTimers(250);
    CheckEquals(1, S.Value, 'vor der Verzoegerung keine Wiederholung');
    PumpTimers(500);
    S.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y));
    CheckTrue(S.Value >= 4, Format('Wiederholung beim Halten (%d)', [S.Value]));
    CheckFalse(TSpinAccess(S).Repeating, 'nach dem Loslassen gestoppt');
    P.X := S.Value;
    PumpTimers(150);
    CheckEquals(P.X, S.Value, 'keine weiteren Schritte');
  finally
    FForm.Hide;
  end;
end;

procedure TSpinEditTests.ButtonsDisabledAtBounds;
var
  S: TPPGSpinEdit;
  P: TPoint;
begin
  S := NewSpin;
  S.Max := 3;
  S.Min := 0;
  S.Value := 3;
  P := CenterOf(TSpinAccess(S).ButtonRect(PPGSpinButtonUp));
  CheckEquals(-1, TSpinAccess(S).ButtonAt(P.X, P.Y), 'Auf an Max inaktiv');
  P := CenterOf(TSpinAccess(S).ButtonRect(PPGSpinButtonDown));
  CheckTrue(TSpinAccess(S).ButtonAt(P.X, P.Y) >= 0);
  S.Value := 0;
  CheckEquals(-1, TSpinAccess(S).ButtonAt(P.X, P.Y), 'Ab an Min inaktiv');
  RenderToBitmap(S).Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TSpinEditTests.InvalidInputIsNormalized;
var
  S: TPPGSpinEdit;
  I: TCustomEdit;
  B: TPPGButton;
begin
  FForm.Show;
  try
    S := NewSpin;
    S.Min := 1;
    S.Max := 50;
    I := TSpinAccess(S).Inner;
    I.Perform(WM_CHAR, Ord('x'), 0);
    CheckEquals('1', S.Text, 'Buchstaben werden abgewiesen');
    S.Text := '99';
    CheckEquals(50, S.Value, 'Value liest begrenzt');
    I.Perform(WM_CHAR, 13, 0);
    CheckEquals('50', S.Text, 'Enter setzt den Text auf den Wert');
    S.SetFocus;
    S.Text := '';
    B := NewButton('B');
    B.Top := 200;
    B.SetFocus;
    CheckEquals('1', S.Text, 'Verlassen setzt den Text auf den Wert');
  finally
    FForm.Hide;
  end;
end;

procedure TSpinEditTests.EditorDisabledStillSpins;
var
  S: TPPGSpinEdit;
begin
  S := NewSpin;
  S.EditorEnabled := False;
  CheckTrue(TSpinAccess(S).Inner.ReadOnly, 'Tippen gesperrt');
  CheckFalse(S.ReadOnly);
  S.Spin(3);
  CheckEquals(3, S.Value, 'Buttons/Tasten weiter aktiv');
  S.EditorEnabled := True;
  CheckFalse(TSpinAccess(S).Inner.ReadOnly);
end;

procedure TSpinEditTests.LoadsTSpinEditDfm;
const
  Dfm =
    'object SpinEdit1: TPPGSpinEdit'#13#10 +
    '  Increment = 5'#13#10 +
    // Audit 5c: MinValue/MaxValue von TSpinEdit heissen Min/Max (migrate.ps1 stellt um)
    '  Max = 50'#13#10 +
    '  Min = 10'#13#10 +
    '  TabOrder = 0'#13#10 +
    '  Value = 99'#13#10 +
    'end'#13#10;
var
  S: TPPGSpinEdit;
begin
  S := TPPGSpinEdit.Create(nil);
  try
    LoadDfm(Dfm, S);
    CheckEquals(5, S.Increment);
    CheckEquals(50, S.Max);
    CheckEquals(10, S.Min);
    CheckEquals(50, S.Value, 'nach dem Laden begrenzt');
    CheckEquals('50', S.Text);
  finally
    S.Free;
  end;
end;

procedure TSpinEditTests.AccessibilityRoleAndValue;
var
  S: TPPGSpinEdit;
  Acc: IAccessible;
  W: WideString;
begin
  S := NewSpin;
  S.Value := 42;
  Acc := AccOf(S);
  CheckEquals(ROLE_SYSTEM_SPINBUTTON, AccRole(Acc));
  CheckEquals(S_OK, Acc.Get_accValue(CHILDID_SELF, W));
  CheckEquals('42', string(W));
end;

{ TPhase4aPaintTests }

procedure TPhase4aPaintTests.AllFieldsAllVariantsPaintWithoutErrors;
const
  Presets: array[0..1] of string = (PPGPresetModernFlat, PPGPresetClassic);
var
  E: TPPGEdit;
  M: TPPGMemo;
  S: TPPGSpinEdit;
  Gdi: Boolean;
  P, V: Integer;
  Fields: array[0..2] of TPPGCustomField;
  F: Integer;
begin
  E := NewEdit;
  E.ShowClearButton := True;
  E.LeftButton.Visible := True;
  E.Text := 'Text';
  E.TextHint := 'Hint';
  M := NewMemo;
  M.Lines.Text := 'a'#13#10'b';
  M.ScrollBars := ssBoth;
  S := NewSpin;
  Fields[0] := E;
  Fields[1] := M;
  Fields[2] := S;
  for Gdi := False to True do
    for P := 0 to High(Presets) do
      for F := 0 to High(Fields) do
        for V := 0 to 5 do
        begin
          TPPGRendererRegistry.ForceGdiFallback := Gdi;
          TBaseFieldAccess(Fields[F]).Preset := Presets[P];
          TBaseFieldAccess(Fields[F]).Enabled := V <> 1;
          TBaseFieldAccess(Fields[F]).ValidationState := TPPGValidationState(V mod 4);
          if V = 4 then
            TBaseFieldAccess(Fields[F]).BiDiMode := bdRightToLeft
          else
            TBaseFieldAccess(Fields[F]).BiDiMode := bdLeftToRight;
          if V = 5 then
            TBaseFieldAccess(Fields[F]).BorderStyle := bsNone
          else
            TBaseFieldAccess(Fields[F]).BorderStyle := bsSingle;
          RenderToBitmap(Fields[F]).Free;
        end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPhase4aPaintTests.ExtremeSizesPaintWithoutErrors;
const
  Sizes: array[0..4] of TPoint = ((X: 0; Y: 0), (X: 1; Y: 1), (X: 6; Y: 6),
    (X: 2000; Y: 30), (X: 30; Y: 400));
var
  E: TPPGEdit;
  S: TPPGSpinEdit;
  M: TPPGMemo;
  I: Integer;
begin
  E := NewEdit;
  E.AutoSize := False;
  E.ShowClearButton := True;
  E.Text := 'x';
  S := NewSpin;
  S.AutoSize := False;
  M := NewMemo;
  for I := 0 to High(Sizes) do
  begin
    E.SetBounds(0, 0, Sizes[I].X, Sizes[I].Y);
    S.SetBounds(0, 0, Sizes[I].X, Sizes[I].Y);
    M.SetBounds(0, 0, Sizes[I].X, Sizes[I].Y);
    if (Sizes[I].X > 0) and (Sizes[I].Y > 0) then
    begin
      RenderToBitmap(E).Free;
      RenderToBitmap(S).Free;
      RenderToBitmap(M).Free;
    end;
    CheckTrue(TFieldAccess(E).Inner.Width >= 0);
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPhase4aPaintTests.NoHandleOrMemoryLeaks;

  procedure Cycle;
  var
    I: Integer;
    E: TPPGEdit;
    M: TPPGMemo;
    S: TPPGSpinEdit;
  begin
    for I := 1 to 25 do
    begin
      E := NewEdit;
      E.ShowClearButton := True;
      E.TextHint := 'Hint';
      E.Text := IntToStr(I);
      E.SetFocus;
      RenderToBitmap(E).Free;
      AccOf(E);
      AccOf(TFieldAccess(E).Inner);
      E.Free;
      M := NewMemo;
      M.Lines.Add('x');
      RenderToBitmap(M).Free;
      M.Free;
      S := NewSpin;
      S.Spin(I);
      RenderToBitmap(S).Free;
      S.Free;
    end;
  end;

var
  Gdi0, User0: Cardinal;
  M0, M1: NativeUInt;
begin
  FForm.Show;
  try
    Cycle;
    Gdi0 := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
    User0 := GetGuiResources(GetCurrentProcess, GR_USEROBJECTS);
    M0 := AllocatedBytes;
    Cycle;
    Cycle;
    M1 := AllocatedBytes;
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS) <= Gdi0 + 2, 'GDI-Handles wachsen');
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_USEROBJECTS) <= User0 + 2, 'USER-Handles wachsen');
    CheckTrue(M1 <= M0 + 1024, Format('Speicher waechst: %d -> %d', [M0, M1]));
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterTest('Phase4a', TFieldTests.Suite);
  RegisterTest('Phase4a', TMemoFieldTests.Suite);
  RegisterTest('Phase4a', TSpinEditTests.Suite);
  RegisterTest('Phase4a', TPhase4aPaintTests.Suite);

end.
