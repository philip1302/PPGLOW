unit PPG.Tests.Gaps;

{ Tests fuer die geschlossenen Luecken:
  1. Barrierefreiheit (IAccessible / Screenreader)
  2. VCL-Styles
  3. Button-Funktionen: AutoSize, Split-Button, ImageName }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, Winapi.ActiveX, Winapi.oleacc,
  System.Classes, System.SysUtils, System.Types, System.Variants,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Vcl.ImgList, Vcl.Menus,
  PPG.Types, PPG.Consts, PPG.Render.Registry, PPG.Controls.Base, PPG.Button,
  PPG.CheckBox, PPG.RadioButton, PPG.ToggleSwitch, PPG.Tests.Controls;

type
  TGapTestCase = class(TControlTestCase)
  protected
    FClicks, FDropDowns: Integer;
    procedure CountClick(Sender: TObject);
    procedure CountDropDown(Sender: TObject);
    procedure RaisingDropDown(Sender: TObject);
    function AccOf(C: TWinControl): IAccessible;
    function AccName(const Acc: IAccessible): string;
    function AccRole(const Acc: IAccessible): Integer;
    function AccState(const Acc: IAccessible): Integer;
    procedure SetUp; override;
  end;

  TAccessibilityTests = class(TGapTestCase)
  published
    procedure ButtonExposesNameRoleShortcut;
    procedure DisabledIsUnavailable;
    procedure CheckBoxStatesAreReported;
    procedure RadioAndSwitchRoles;
    procedure SplitButtonRole;
    procedure DefaultActionClicksAsynchronously;
    procedure LocationComesFromWindow;
    procedure DisconnectedAfterFreeDoesNotCrash;
    procedure RecreatedWindowGetsNewObject;
  end;

  TVclStyleTests = class(TGapTestCase)
  private
    FStyleName: string;
    function ActivateDarkStyle: Boolean;
    procedure RestoreSystemStyle;
  published
    procedure VclStyleIntegration;
  end;

  TButtonFeatureTests = class(TGapTestCase)
  published
    procedure AutoSizeFollowsCaption;
    procedure AutoSizeIncludesImageAndArrow;
    procedure AutoSizeRespectsAlign;
    procedure AutoSizeCheckControls;
    procedure SplitBodyClickFiresOnlyOnClick;
    procedure SplitArrowFiresOnlyDropDown;
    procedure SplitKeyboardOpensDropDown;
    procedure ExceptionInDropDownLeavesNoPressedState;
    procedure ImageNameResolvesAndSurvivesReordering;
    procedure ImageNameIsStoredInsteadOfIndex;
  end;

implementation

uses
  Vcl.Themes, Vcl.Styles, Vcl.Imaging.pngimage
  {$IF CompilerVersion >= 34.0}, Vcl.ImageCollection, Vcl.VirtualImageList{$IFEND};

type
  TButtonAccess = class(TPPGButton);

const
  CO_E_OBJNOTCONNECTED = HResult($800401FD);

function ColorDist(A, B: TColor): Integer;
var
  CA, CB: Cardinal;
begin
  CA := ColorToRGB(A);
  CB := ColorToRGB(B);
  Result := Abs(GetRValue(CA) - GetRValue(CB)) + Abs(GetGValue(CA) - GetGValue(CB)) +
    Abs(GetBValue(CA) - GetBValue(CB));
end;

{ TGapTestCase }

procedure TGapTestCase.SetUp;
begin
  inherited;
  FClicks := 0;
  FDropDowns := 0;
end;

procedure TGapTestCase.CountClick(Sender: TObject);
begin
  Inc(FClicks);
end;

procedure TGapTestCase.CountDropDown(Sender: TObject);
begin
  Inc(FDropDowns);
end;

procedure TGapTestCase.RaisingDropDown(Sender: TObject);
begin
  raise EAbort.Create('OnDropDownClick failed');
end;

function TGapTestCase.AccOf(C: TWinControl): IAccessible;
begin
  // Genau der Weg, den ein Screenreader geht (WM_GETOBJECT -> OBJID_CLIENT)
  Result := nil;
  CheckEquals(S_OK, AccessibleObjectFromWindow(C.Handle, OBJID_CLIENT, IID_IAccessible, Result),
    'AccessibleObjectFromWindow');
  CheckTrue(Result <> nil);
end;

function TGapTestCase.AccName(const Acc: IAccessible): string;
var
  W: WideString;
begin
  CheckEquals(S_OK, Acc.Get_accName(CHILDID_SELF, W), 'accName');
  Result := W;
end;

function TGapTestCase.AccRole(const Acc: IAccessible): Integer;
var
  V: OleVariant;
begin
  CheckEquals(S_OK, Acc.Get_accRole(CHILDID_SELF, V), 'accRole');
  Result := V;
end;

function TGapTestCase.AccState(const Acc: IAccessible): Integer;
var
  V: OleVariant;
begin
  CheckEquals(S_OK, Acc.Get_accState(CHILDID_SELF, V), 'accState');
  Result := V;
end;

{ TAccessibilityTests }

procedure TAccessibilityTests.ButtonExposesNameRoleShortcut;
var
  B: TPPGButton;
  Acc: IAccessible;
  W: WideString;
begin
  B := NewButton('&Speichern');
  B.Hint := 'Dokument speichern|Speichert das aktuelle Dokument';
  Acc := AccOf(B);
  CheckEquals('Speichern', AccName(Acc), 'Name ohne &');
  CheckEquals(ROLE_SYSTEM_PUSHBUTTON, AccRole(Acc));
  CheckEquals(S_OK, Acc.Get_accKeyboardShortcut(CHILDID_SELF, W));
  CheckEquals('Alt+S', string(W));
  CheckEquals(S_OK, Acc.Get_accDescription(CHILDID_SELF, W));
  CheckEquals('Dokument speichern', string(W), 'kurzer Hint als Beschreibung');
  CheckEquals(S_OK, Acc.Get_accDefaultAction(CHILDID_SELF, W));
  CheckEquals(SPPGAccPress, string(W));
end;

procedure TAccessibilityTests.DisabledIsUnavailable;
var
  B: TPPGButton;
  Acc: IAccessible;
begin
  B := NewButton('Aus');
  Acc := AccOf(B);
  CheckTrue((AccState(Acc) and STATE_SYSTEM_FOCUSABLE) <> 0);
  B.Enabled := False;
  CheckTrue((AccState(Acc) and STATE_SYSTEM_UNAVAILABLE) <> 0);
  CheckTrue((AccState(Acc) and STATE_SYSTEM_FOCUSABLE) = 0);
end;

procedure TAccessibilityTests.CheckBoxStatesAreReported;
var
  C: TPPGCheckBox;
  Acc: IAccessible;
  W: WideString;
begin
  C := TPPGCheckBox.Create(FForm);
  C.Parent := FForm;
  C.Caption := 'Merken';
  C.AllowGrayed := True;
  Acc := AccOf(C);
  CheckEquals(ROLE_SYSTEM_CHECKBUTTON, AccRole(Acc));
  CheckTrue((AccState(Acc) and STATE_SYSTEM_CHECKED) = 0);
  CheckEquals(S_OK, Acc.Get_accDefaultAction(CHILDID_SELF, W));
  CheckEquals(SPPGAccCheck, string(W));
  C.Checked := True;
  CheckTrue((AccState(Acc) and STATE_SYSTEM_CHECKED) <> 0, 'CHECKED');
  CheckEquals(S_OK, Acc.Get_accDefaultAction(CHILDID_SELF, W));
  CheckEquals(SPPGAccUncheck, string(W));
  C.State := cbGrayed;
  CheckTrue((AccState(Acc) and STATE_SYSTEM_MIXED) <> 0, 'MIXED');
end;

procedure TAccessibilityTests.RadioAndSwitchRoles;
var
  R: TPPGRadioButton;
  S: TPPGToggleSwitch;
  W: WideString;
begin
  R := TPPGRadioButton.Create(FForm);
  R.Parent := FForm;
  R.Caption := 'Option';
  CheckEquals(ROLE_SYSTEM_RADIOBUTTON, AccRole(AccOf(R)));
  S := TPPGToggleSwitch.Create(FForm);
  S.Parent := FForm;
  S.Caption := 'WLAN';
  S.Top := 40;
  CheckEquals(ROLE_SYSTEM_CHECKBUTTON, AccRole(AccOf(S)));
  CheckEquals(S_OK, AccOf(S).Get_accValue(CHILDID_SELF, W));
  CheckEquals(SPPGAccOff, string(W), 'Schalter meldet Ein/Aus als Wert');
  S.Checked := True;
  CheckEquals(S_OK, AccOf(S).Get_accValue(CHILDID_SELF, W));
  CheckEquals(SPPGAccOn, string(W));
end;

procedure TAccessibilityTests.SplitButtonRole;
var
  B: TPPGButton;
begin
  B := NewButton('Mehr');
  B.Style := pbsSplitButton;
  CheckEquals(ROLE_SYSTEM_SPLITBUTTON, AccRole(AccOf(B)));
  CheckTrue((AccState(AccOf(B)) and STATE_SYSTEM_HASPOPUP) <> 0);
end;

procedure TAccessibilityTests.DefaultActionClicksAsynchronously;
var
  B: TPPGButton;
  C: TPPGCheckBox;
  Acc: IAccessible;
begin
  B := NewButton('Los');
  B.OnClick := CountClick;
  Acc := AccOf(B);
  CheckEquals(S_OK, Acc.accDoDefaultAction(CHILDID_SELF));
  CheckEquals(0, FClicks, 'nicht innerhalb des COM-Aufrufs ausfuehren');
  Application.ProcessMessages;
  CheckEquals(1, FClicks, 'nach der Nachrichtenschleife ausgefuehrt');

  C := TPPGCheckBox.Create(FForm);
  C.Parent := FForm;
  C.Top := 60;
  CheckEquals(S_OK, AccOf(C).accDoDefaultAction(CHILDID_SELF));
  Application.ProcessMessages;
  CheckTrue(C.Checked, 'Standardaktion schaltet die CheckBox um');
end;

procedure TAccessibilityTests.LocationComesFromWindow;
var
  B: TPPGButton;
  L, T, W, H: Integer;
  P: TPoint;
begin
  B := NewButton('Ort');
  CheckEquals(S_OK, AccOf(B).accLocation(L, T, W, H, CHILDID_SELF));
  CheckEquals(B.Width, W);
  CheckEquals(B.Height, H);
  P := B.ClientToScreen(Point(0, 0));
  CheckEquals(P.X, L);
  CheckEquals(P.Y, T);
end;

procedure TAccessibilityTests.DisconnectedAfterFreeDoesNotCrash;
var
  B: TPPGButton;
  Acc: IAccessible;
  W: WideString;
  V: OleVariant;
begin
  B := NewButton('Weg');
  Acc := AccOf(B);
  B.Free; // Screenreader haelt das Objekt noch
  CheckEquals(CO_E_OBJNOTCONNECTED, Acc.Get_accName(CHILDID_SELF, W));
  CheckEquals(CO_E_OBJNOTCONNECTED, Acc.Get_accState(CHILDID_SELF, V));
  CheckEquals(CO_E_OBJNOTCONNECTED, Acc.accDoDefaultAction(CHILDID_SELF));
  Acc := nil; // letzte Referenz -> Objekt wird freigegeben (Leak-Pruefung)
end;

procedure TAccessibilityTests.RecreatedWindowGetsNewObject;
var
  B: TPPGButton;
  Old, New: IAccessible;
  W: WideString;
begin
  B := NewButton('Neu');
  Old := AccOf(B);
  B.BiDiMode := bdRightToLeft; // erzwingt RecreateWnd
  B.HandleNeeded;
  CheckEquals(CO_E_OBJNOTCONNECTED, Old.Get_accName(CHILDID_SELF, W),
    'altes Objekt gehoert zum alten Fenster');
  New := AccOf(B);
  CheckEquals('Neu', AccName(New));
end;

{ TVclStyleTests }

function TVclStyleTests.ActivateDarkStyle: Boolean;
var
  FileName: string;
  Info: TStyleInfo;
begin
  Result := False;
  FileName := 'C:\Users\Public\Documents\Embarcadero\Studio\37.0\Styles\Windows10Dark.vsf';
  if not FileExists(FileName) then
    Exit;
  // Datei vorhanden, aber nicht ladbar = echter Fehler (nicht still ueberspringen)
  CheckTrue(TStyleManager.IsValidStyle(FileName, Info),
    'Style-Datei vorhanden, aber ungueltig (Vcl.Styles eingebunden?)');
  FStyleName := Info.Name;
  if not TStyleManager.TrySetStyle(FStyleName, False) then
  begin
    TStyleManager.LoadFromFile(FileName);
    TStyleManager.SetStyle(FStyleName);
  end;
  Application.ProcessMessages;
  CheckTrue(TStyleManager.IsCustomStyleActive, 'Style liess sich nicht aktivieren');
  Result := True;
end;

procedure TVclStyleTests.RestoreSystemStyle;
begin
  TStyleManager.SetStyle(TStyleManager.SystemStyle);
  Application.ProcessMessages;
end;

procedure TVclStyleTests.VclStyleIntegration;
{ Bewusst EIN Test mit genau einem Style-Wechsel hin und zurueck.
  Beobachtung in dieser Konsolen-Testumgebung (ohne Hauptformular/Run-Schleife):
  Nach "Style -> System -> Style" schlaegt das naechste CreateWindow fehl -
  auch fuer Standard-VCL-TButton. Das ist kein PPGlow-Verhalten; mehrere
  Wechsel pro Testlauf werden daher vermieden. }
var
  B, Own: TPPGButton;
  C: TPPGCheckBox;
  S: TPPGToggleSwitch;
  Bmp: TBitmap;
  Before: TColor;
begin
  B := NewButton('');
  B.Preset := PPGPresetModernFlat;
  Before := B.Appearance.Normal.Color;
  if not ActivateDarkStyle then
  begin
    Status('Style-Datei nicht vorhanden - Test uebersprungen');
    Exit;
  end;
  try
    // 1. Button folgt dem Style
    CheckTrue(B.UseVclStyle);
    CheckTrue(B.EffectiveAppearance <> B.Appearance, 'gestylte Kopie erwartet');
    Bmp := RenderToBitmap(B);
    try
      CheckTrue(ColorDist(Bmp.Canvas.Pixels[20, B.Height div 2],
        StyleServices.GetStyleColor(scButtonNormal)) < 20,
        'Koerper muss die Buttonfarbe des Styles haben');
    finally
      Bmp.Free;
    end;
    // 2. Gespeicherte Appearance bleibt unveraendert (sonst landen Style-Farben in der DFM)
    CheckEquals(Integer(Before), Integer(B.Appearance.Normal.Color));
    // 3. StyleElements ohne seClient -> eigene Farben
    Own := NewButton('');
    Own.Preset := PPGPresetModernFlat;
    Own.StyleElements := [seFont, seBorder];
    CheckFalse(Own.UseVclStyle);
    Bmp := RenderToBitmap(Own);
    try
      CheckTrue(ColorDist(Bmp.Canvas.Pixels[20, Own.Height div 2],
        Own.Appearance.Normal.Color) < 20, 'eigene Farben ohne seClient');
    finally
      Bmp.Free;
    end;
    // 4. Auswahl-Controls zeichnen fehlerfrei unter dem Style
    C := TPPGCheckBox.Create(FForm);
    C.Parent := FForm;
    C.Caption := 'Dunkel';
    C.Checked := True;
    RenderToBitmap(C).Free;
    S := TPPGToggleSwitch.Create(FForm);
    S.Parent := FForm;
    S.Caption := 'Dunkel';
    S.Checked := True;
    RenderToBitmap(S).Free;
  finally
    RestoreSystemStyle;
  end;
  // 5. Zurueck zum System-Style -> wieder eigene Appearance
  CheckFalse(B.UseVclStyle);
  CheckTrue(B.EffectiveAppearance = B.Appearance);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

{ TButtonFeatureTests }

procedure TButtonFeatureTests.AutoSizeFollowsCaption;
var
  B: TPPGButton;
  W1: Integer;
begin
  B := NewButton('A');
  B.AutoSize := True;
  W1 := B.Width;
  B.Caption := 'Ein deutlich laengerer Text';
  CheckTrue(B.Width > W1 + 50, Format('Breite waechst nicht: %d -> %d', [W1, B.Width]));
  CheckTrue(B.Height >= 24, 'Mindesthoehe');
  B.Caption := 'A';
  CheckEquals(W1, B.Width, 'schrumpft wieder');
end;

procedure TButtonFeatureTests.AutoSizeIncludesImageAndArrow;
var
  B: TPPGButton;
  IL: TImageList;
  Bmp: TBitmap;
  P: TPopupMenu;
  W0, W1, W2: Integer;
begin
  B := NewButton('Text');
  B.AutoSize := True;
  W0 := B.Width;
  IL := TImageList.Create(FForm);
  IL.SetSize(24, 24);
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(24, 24);
    IL.Add(Bmp, nil);
  finally
    Bmp.Free;
  end;
  B.Images := IL;
  B.ImageIndex := 0;
  W1 := B.Width;
  CheckTrue(W1 >= W0 + 24, 'Bild + Abstand muessen Platz bekommen');
  P := TPopupMenu.Create(FForm);
  B.DropDownMenu := P;
  W2 := B.Width;
  CheckTrue(W2 >= W1 + 18, 'Pfeilbereich muss Platz bekommen');
  P.Free; // Menue weg -> Pfeil weg -> Breite zurueck
  CheckEquals(W1, B.Width);
end;

procedure TButtonFeatureTests.AutoSizeRespectsAlign;
var
  B: TPPGButton;
begin
  B := NewButton('Oben');
  B.Align := alTop;
  B.AutoSize := True;
  CheckEquals(FForm.ClientWidth, B.Width, 'Breite gehoert bei alTop dem Parent');
end;

procedure TButtonFeatureTests.AutoSizeCheckControls;
var
  C: TPPGCheckBox;
  S: TPPGToggleSwitch;
  W1: Integer;
begin
  C := TPPGCheckBox.Create(FForm);
  C.Parent := FForm;
  C.Caption := 'X';
  C.AutoSize := True;
  W1 := C.Width;
  C.Caption := 'Eine laengere Beschriftung';
  CheckTrue(C.Width > W1 + 50);
  S := TPPGToggleSwitch.Create(FForm);
  S.Parent := FForm;
  S.Caption := '';
  S.AutoSize := True;
  CheckTrue(S.Width >= 40, 'Schalter ohne Text: mindestens die Spurbreite');
  CheckTrue(S.Width < 70);
end;

procedure TButtonFeatureTests.SplitBodyClickFiresOnlyOnClick;
var
  B: TPPGButton;
begin
  B := NewButton('Split');
  B.Style := pbsSplitButton;
  B.OnClick := CountClick;
  B.OnDropDownClick := CountDropDown;
  B.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(15, 15));
  B.Perform(WM_LBUTTONUP, 0, MakeLParam(15, 15));
  CheckEquals(1, FClicks);
  CheckEquals(0, FDropDowns);
end;

procedure TButtonFeatureTests.SplitArrowFiresOnlyDropDown;
var
  B: TPPGButton;
  X: Integer;
begin
  B := NewButton('Split');
  B.Style := pbsSplitButton;
  B.OnClick := CountClick;
  B.OnDropDownClick := CountDropDown;
  X := B.Width - 12; // im Pfeilbereich
  B.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(X, 15));
  CheckEquals(1, FDropDowns, 'Pfeil oeffnet beim Druecken');
  B.Perform(WM_LBUTTONUP, 0, MakeLParam(X, 15));
  CheckEquals(0, FClicks, 'kein OnClick nach dem Pfeil');
  CheckFalse(TButtonAccess(B).MousePressed);
end;

procedure TButtonFeatureTests.SplitKeyboardOpensDropDown;
var
  B: TPPGButton;
begin
  B := NewButton('Split');
  B.Style := pbsSplitButton;
  B.OnClick := CountClick;
  B.OnDropDownClick := CountDropDown;
  B.Perform(WM_KEYDOWN, VK_F4, 0);
  CheckEquals(1, FDropDowns, 'F4');
  B.Perform(WM_SYSKEYDOWN, VK_DOWN, $20000000); // Bit 29 = Alt gedrueckt
  CheckEquals(2, FDropDowns, 'Alt+Pfeil runter');
  CheckEquals(0, FClicks);
end;

procedure TButtonFeatureTests.ExceptionInDropDownLeavesNoPressedState;
var
  B: TPPGButton;
begin
  B := NewButton('Split');
  B.Style := pbsSplitButton;
  B.OnDropDownClick := RaisingDropDown;
  try
    B.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(B.Width - 12, 15));
    Fail('Exception muss propagieren');
  except
    on E: EAbort do
      ;
  end;
  CheckFalse(TButtonAccess(B).MousePressed);
  CheckTrue(B.VisualState <> vsDown);
  RenderToBitmap(B).Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

{$IF CompilerVersion >= 34.0}
function MakeCollection(Owner: TComponent): TImageCollection;
const
  Names: array[0..2] of string = ('save', 'open', 'print');
var
  I: Integer;
  Bmp: TBitmap;
  Png: TPngImage;
  S: TMemoryStream;
begin
  Result := TImageCollection.Create(Owner);
  for I := 0 to High(Names) do
  begin
    Bmp := TBitmap.Create;
    Png := TPngImage.Create;
    S := TMemoryStream.Create;
    try
      Bmp.SetSize(16, 16);
      Bmp.Canvas.Brush.Color := RGB(I * 80, 100, 200);
      Bmp.Canvas.FillRect(Rect(0, 0, 16, 16));
      Png.Assign(Bmp);
      Png.SaveToStream(S);
      S.Position := 0;
      Result.Add(Names[I], S);
    finally
      S.Free;
      Png.Free;
      Bmp.Free;
    end;
  end;
end;
{$IFEND}

procedure TButtonFeatureTests.ImageNameResolvesAndSurvivesReordering;
{$IF CompilerVersion >= 34.0}
var
  B: TPPGButton;
  IC: TImageCollection;
  VIL: TVirtualImageList;
begin
  IC := MakeCollection(FForm);
  VIL := TVirtualImageList.Create(FForm);
  VIL.ImageCollection := IC;
  VIL.Add('save', 'save');
  VIL.Add('open', 'open');
  VIL.Add('print', 'print');
  B := NewButton('Bild');
  B.Images := VIL;
  B.ImageName := 'open';
  CheckEquals(1, B.ImageIndex);
  B.ImageIndex := 2;
  CheckEquals('print', B.ImageName, 'Index -> Name');
  VIL.Delete(0); // Umsortiert: "print" ist jetzt Index 1
  CheckEquals(1, B.ImageIndex, 'Index muss ueber den Namen nachgefuehrt werden');
  B.ImageName := 'gibtsnicht';
  CheckEquals(-1, B.ImageIndex, 'unbekannter Name = kein Bild, keine Exception');
  RenderToBitmap(B).Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;
{$ELSE}
begin
  Status('ImageName erst ab Delphi 10.4');
end;
{$IFEND}

procedure TButtonFeatureTests.ImageNameIsStoredInsteadOfIndex;
{$IF CompilerVersion >= 34.0}
var
  B: TPPGButton;
  VIL: TVirtualImageList;
  Bin, Txt: TMemoryStream;
  Dfm: string;
  DfmA: AnsiString;
begin
  VIL := TVirtualImageList.Create(FForm);
  VIL.ImageCollection := MakeCollection(FForm);
  VIL.Add('save', 'save');
  VIL.Add('open', 'open');
  B := NewButton('Bild');
  B.Images := VIL;
  B.ImageName := 'open';
  Bin := TMemoryStream.Create;
  Txt := TMemoryStream.Create;
  try
    Bin.WriteComponent(B);
    Bin.Position := 0;
    ObjectBinaryToText(Bin, Txt);
    SetString(DfmA, PAnsiChar(Txt.Memory), Txt.Size);
    Dfm := string(DfmA);
    CheckTrue(Pos('ImageName = ''open''', Dfm) > 0, 'ImageName muss gespeichert werden');
    CheckTrue(Pos('ImageIndex', Dfm) = 0, 'ImageIndex darf dann NICHT gespeichert werden');
  finally
    Txt.Free;
    Bin.Free;
  end;
end;
{$ELSE}
begin
  Status('ImageName erst ab Delphi 10.4');
end;
{$IFEND}

initialization
  RegisterTest('Luecken', TAccessibilityTests.Suite);
  RegisterTest('Luecken', TVclStyleTests.Suite);
  RegisterTest('Luecken', TButtonFeatureTests.Suite);

end.
