unit PPG.Tests.Phase8;

{ Tests fuer Phase 8 (modernes Design). 8.1: Design-Tokens. }

interface

uses
  TestFramework, Winapi.Windows, System.Classes, System.SysUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.ComCtrls,
  PPG.Types, PPG.Consts, PPG.Tokens, PPG.Appearance, PPG.Render.Intf,
  PPG.Render.Registry, PPG.Controls.Base, PPG.Controls.Field, PPG.Edit,
  PPG.ProgressBar, PPG.Tests.Controls;

type
  TTokenTests = class(TControlTestCase)
  private
    function ThemeRenderer(const Name: string): IPPGThemeRenderer;
    procedure CheckContrast(const What: string; A, B: TColor; Min: Double);
  published
    procedure ContrastFormula;
    procedure EveryPresetHasLightAndDarkTokens;
    procedure TextContrastMeetsWcag;
    procedure ApplyDefaultsEqualsLightThemeColors;
    procedure DarkColorsKeepShapes;
    procedure LegacyPresetColorsUnchanged;
    procedure ControlsTakeSignalColorsFromTokens;
    procedure RendererWithoutOwnTokensGetsDefaults;
  end;

  TFluent11Tests = class(TControlTestCase)
  private
    procedure CheckRingPixels(Gdi: Boolean);
  protected
    procedure TearDown; override;
  published
    procedure Registered;
    procedure ShapeDefaults;
    procedure AccentFromPalette;
    procedure AccentFromBaseMeetsContrast;
    procedure AccentOverrideReachesAppearance;
    procedure SystemAccentIsUsed;
    procedure DoubleFocusRing;
    procedure UncheckedBoxHasStrongStroke;
    procedure AllControlsPaint;
  end;

  TThemeTests = class(TControlTestCase)
  private
    FChanges: Integer;
    procedure CountChange(Sender: TObject);
  protected
    procedure TearDown; override;
  published
    procedure DefaultIsLight;
    procedure DarkKeepsAppearanceAndDfm;
    procedure SwitchReachesAllControls;
    procedure OpenPopupFollowsTheme;
    procedure SystemModeFollowsSetting;
    procedure StyleFormsColorsAndRestores;
    procedure NewFormGetsStyled;
    procedure SeClientOffKeepsOwnColors;
    procedure TokensFollowMode;
    procedure StyleManagerSetsMode;
    procedure ClientsRegisterAndUnregister;
    procedure AllPresetsPaintDark;
    procedure DarkIndicatorBorderVisible;
  end;

  TEasingTests = class(TTestCase)
  published
    procedure EndpointsAreZeroAndOne;
    procedure CurvesAreMonotonic;
    procedure DecelerateIsAboveSmooth;
    procedure AnimateToRemembersEasing;
  end;

  TIconFontTests = class(TTestCase)
  private
    function InkPixels(Glyph: TPPGFieldGlyph): Integer;
  protected
    procedure TearDown; override;
  published
    procedure FontIsDetected;
    procedure FallbackWithoutIconFont;
    procedure GlyphsDrawInk;
  end;

implementation

uses
  PPG.Tests.Visual,
  Winapi.Messages, Vcl.StdCtrls, PPG.Render.Fluent11, PPG.Button, PPG.CheckBox, PPG.RadioButton, PPG.ToggleSwitch,
  PPG.TrackBar, PPG.Panel, PPG.GroupBox, PPG.Memo, PPG.SpinEdit, PPG.ComboBox,
  PPG.TabControl, PPG.PageControl, PPG.Theme, PPG.StyleManager, PPG.Animation,
  PPG.IconFont;

type
  TEditAccess = class(TPPGEdit);
  TFieldAccess = class(TPPGCustomField);
  TCustomControlAccess = class(TPPGCustomControl);

  /// Fremdes Preset ohne eigene Tokens (Grundlage: neutrale Palette).
  TPlainRenderer = class(TPPGRendererBase)
  public
    function Name: string; override;
    procedure ApplyDefaults(Appearance: TPPGAppearance); override;
    procedure DrawSurface(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle); override;
  end;

function TPlainRenderer.Name: string;
begin
  Result := 'PlainTest';
end;

procedure TPlainRenderer.ApplyDefaults(Appearance: TPPGAppearance);
begin
  ApplyThemeColors(Appearance, False);
end;

procedure TPlainRenderer.DrawSurface(const Canvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle);
begin
  Canvas.FillRoundRect(Body, Style.Rounding, Style.Color, 255);
end;

function ColorDist(A, B: TColor): Integer;
var
  CA, CB: Cardinal;
begin
  CA := ColorToRGB(A);
  CB := ColorToRGB(B);
  Result := Abs(GetRValue(CA) - GetRValue(CB)) + Abs(GetGValue(CA) - GetGValue(CB)) +
    Abs(GetBValue(CA) - GetBValue(CB));
end;

{ TTokenTests }

function TTokenTests.ThemeRenderer(const Name: string): IPPGThemeRenderer;
begin
  CheckTrue(Supports(TPPGRendererRegistry.Get(Name), IPPGThemeRenderer, Result),
    Name + ': IPPGThemeRenderer');
end;

procedure TTokenTests.CheckContrast(const What: string; A, B: TColor; Min: Double);
var
  R: Double;
begin
  R := PPGContrastRatio(A, B);
  CheckTrue(R >= Min, Format('%s: Kontrast %.2f < %.1f', [What, R, Min]));
end;

procedure TTokenTests.ContrastFormula;
begin
  CheckEquals(21.0, PPGContrastRatio(clBlack, clWhite), 0.01);
  CheckEquals(21.0, PPGContrastRatio(clWhite, clBlack), 0.01, 'symmetrisch');
  CheckEquals(1.0, PPGContrastRatio($00808080, $00808080), 0.001);
  // #767676 auf Weiss ist die bekannte Grenze fuer 4,5:1
  CheckEquals(4.54, PPGContrastRatio($00767676, clWhite), 0.02);
  CheckEquals(0.0, PPGRelativeLuminance(clBlack), 0.0001);
  CheckEquals(1.0, PPGRelativeLuminance(clWhite), 0.0001);
end;

procedure TTokenTests.EveryPresetHasLightAndDarkTokens;
var
  Names: TStringList;
  I: Integer;
  L, D: TPPGTokens;
begin
  Names := TStringList.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    CheckTrue(Names.Count >= 2);
    for I := 0 to Names.Count - 1 do
    begin
      L := ThemeRenderer(Names[I]).Tokens(False);
      D := ThemeRenderer(Names[I]).Tokens(True);
      CheckTrue(PPGRelativeLuminance(L.Surface) > 0.7, Names[I] + ': hell ist hell');
      CheckTrue(PPGRelativeLuminance(D.Surface) < 0.1, Names[I] + ': dunkel ist dunkel');
      CheckTrue(PPGRelativeLuminance(D.TextPrimary) > 0.7, Names[I] + ': Text im Dunkeln hell');
      CheckTrue(L.RadiusMedium >= 0);
      CheckTrue(L.DurationFast < L.DurationSlow, Names[I] + ': Dauern geordnet');
    end;
  finally
    Names.Free;
  end;
end;

procedure TTokenTests.TextContrastMeetsWcag;
var
  Names: TStringList;
  I: Integer;
  Dark: Boolean;
  T: TPPGTokens;
  P: string;
begin
  Names := TStringList.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    for I := 0 to Names.Count - 1 do
      for Dark := False to True do
      begin
        T := ThemeRenderer(Names[I]).Tokens(Dark);
        P := Names[I] + System.SysUtils.BoolToStr(Dark, True);
        // Text 4,5:1 (WCAG AA), Bedienelemente/Akzent 3:1
        CheckContrast(P + ' Text/Surface', T.TextPrimary, T.Surface, 4.5);
        CheckContrast(P + ' Text/Layer', T.TextPrimary, T.Layer, 4.5);
        CheckContrast(P + ' Text/Background', T.TextPrimary, T.Background, 4.5);
        CheckContrast(P + ' Text/Hover', T.TextPrimary, T.SurfaceHover, 4.5);
        CheckContrast(P + ' Sekundaertext/Layer', T.TextSecondary, T.Layer, 4.5);
        CheckContrast(P + ' OnAccent/Accent', T.OnAccent, T.Accent, 3.0);
        CheckContrast(P + ' Accent/Background', T.Accent, T.Background, 3.0);
        CheckContrast(P + ' Danger/Background', T.Danger, T.Background, 3.0);
      end;
  finally
    Names.Free;
  end;
end;

procedure TTokenTests.ApplyDefaultsEqualsLightThemeColors;
var
  Names: TStringList;
  I: Integer;
  A1, A2: TPPGAppearance;
begin
  Names := TStringList.Create;
  A1 := TPPGAppearance.Create(nil);
  A2 := TPPGAppearance.Create(nil);
  try
    TPPGRendererRegistry.GetNames(Names);
    for I := 0 to Names.Count - 1 do
    begin
      TPPGRendererRegistry.Get(Names[I]).ApplyDefaults(A1);
      A2.Assign(A1);
      A2.Normal.Color := clFuchsia; // verfaelschen: ApplyThemeColors muss es reparieren
      ThemeRenderer(Names[I]).ApplyThemeColors(A2, False);
      CheckTrue(A2.Equals(A1), Names[I] + ': Hell-Farben = Preset-Vorgabe');
    end;
  finally
    A2.Free;
    A1.Free;
    Names.Free;
  end;
end;

procedure TTokenTests.DarkColorsKeepShapes;
var
  A, D: TPPGAppearance;
  R: IPPGRenderer;
begin
  A := TPPGAppearance.Create(nil);
  D := TPPGAppearance.Create(nil);
  try
    R := TPPGRendererRegistry.Get(PPGPresetModernFlat);
    R.ApplyDefaults(A);
    A.Rounding := 11; // eigene Form des Anwenders
    D.Assign(A);
    ThemeRenderer(PPGPresetModernFlat).ApplyThemeColors(D, True);
    CheckEquals(11, D.Rounding, 'Formen bleiben');
    CheckEquals(A.BorderWidth, D.BorderWidth);
    CheckEquals(A.GlowSize, D.GlowSize);
    CheckEquals(A.Hot.GlowAlpha, D.Hot.GlowAlpha, 'Glow-Staerke ist Form');
    CheckTrue(PPGRelativeLuminance(D.Normal.Color) < 0.1, 'Flaeche dunkel');
    CheckTrue(PPGRelativeLuminance(D.Normal.TextColor) > 0.7, 'Text hell');
    CheckTrue(D.FocusColor <> A.FocusColor, 'hellerer Akzent im Dunkeln');
  finally
    D.Free;
    A.Free;
  end;
end;

procedure TTokenTests.LegacyPresetColorsUnchanged;
var
  A: TPPGAppearance;
begin
  // Bestehende DFMs/Screenshots: die Hell-Farben der Presets duerfen sich durch
  // die Tokens nicht veraendern
  A := TPPGAppearance.Create(nil);
  try
    TPPGRendererRegistry.Get(PPGPresetModernFlat).ApplyDefaults(A);
    CheckEquals($00FBFBFB, Integer(A.Normal.Color));
    CheckEquals($00CFCFCF, Integer(A.Normal.BorderColor));
    CheckEquals($00FFF7EF, Integer(A.Hot.Color));
    CheckEquals($00D77800, Integer(A.Hot.BorderColor));
    CheckEquals($00A35A00, Integer(A.Down.BorderColor));
    CheckEquals($00E0E0E0, Integer(A.Disabled.BorderColor));
    CheckEquals($00FFFFFF, Integer(A.Checked.TextColor));
    CheckEquals(150, A.Hot.GlowAlpha);
    CheckEquals(6, A.Rounding);
    TPPGRendererRegistry.Get(PPGPresetClassic).ApplyDefaults(A);
    CheckEquals($00EEEEEE, Integer(A.Normal.ColorTo));
    CheckEquals($004DD7FF, Integer(A.Hot.ColorMirror));
    CheckEquals($00D77800, Integer(A.FocusColor));
    CheckEquals(170, A.Hot.GlowAlpha);
    CheckEquals(3, A.Rounding);
  finally
    A.Free;
  end;
end;

procedure TTokenTests.ControlsTakeSignalColorsFromTokens;
var
  E: TPPGEdit;
  P: TPPGProgressBar;
  Bmp: TBitmap;
begin
  E := TPPGEdit.Create(FForm);
  E.Parent := FForm;
  E.Preset := PPGPresetClassic;
  CheckEquals(Integer(PPGColorError), Integer(TEditAccess(E).Tokens.Danger));
  E.ValidationState := pvsWarning;
  CheckEquals(Integer(TEditAccess(E).Tokens.Warning),
    Integer(TEditAccess(E).GetFieldStyle.BorderColor), 'Warnfarbe aus den Tokens');
  P := TPPGProgressBar.Create(FForm);
  P.Parent := FForm;
  P.SetBounds(10, 100, 200, 16);
  P.Position := 100;
  P.State := pbsError;
  Bmp := RenderToBitmap(P);
  try
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[100, 8], P.Tokens.Danger) < 90,
      'Fehlerzustand in der Danger-Farbe');
  finally
    Bmp.Free;
  end;
end;

procedure TTokenTests.RendererWithoutOwnTokensGetsDefaults;
var
  R: IPPGThemeRenderer;
  A: TPPGAppearance;
  D: TPPGTokens;
begin
  R := TPlainRenderer.Create;
  A := TPPGAppearance.Create(nil);
  try
    D := PPGDefaultTokens(False);
    CheckEquals(Integer(D.Accent), Integer(R.Tokens(False).Accent));
    R.ApplyThemeColors(A, False);
    CheckEquals(Integer(D.Surface), Integer(A.Normal.Color), 'Standard-Abbildung');
    CheckEquals(Integer(D.OnAccent), Integer(A.Checked.TextColor));
    CheckEquals(Integer(D.Accent), Integer(A.FocusColor));
  finally
    A.Free;
  end;
end;

{ TFluent11Tests }

procedure TFluent11Tests.TearDown;
begin
  TPPGFluent11Renderer.AccentOverride := clNone;
  inherited;
end;

procedure TFluent11Tests.Registered;
var
  R: IPPGRenderer;
  Names: TStringList;
begin
  CheckTrue(TPPGRendererRegistry.IsRegistered(PPGPresetFluent11));
  R := TPPGRendererRegistry.Get(PPGPresetFluent11);
  CheckEquals(PPGPresetFluent11, R.Name);
  CheckTrue(Supports(R, IPPGThemeRenderer));
  CheckTrue(Supports(R, IPPGIndicatorRenderer));
  Names := TStringList.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    CheckTrue(Names.IndexOf(PPGPresetFluent11) >= 0, 'in der Preset-Liste');
  finally
    Names.Free;
  end;
  CheckEquals(PPGPresetModernFlat, TPPGRendererRegistry.DefaultName,
    'Standard-Preset bleibt (DFM-Kompatibilitaet)');
end;

procedure TFluent11Tests.ShapeDefaults;
var
  A: TPPGAppearance;
begin
  A := TPPGAppearance.Create(nil);
  try
    TPPGRendererRegistry.Get(PPGPresetFluent11).ApplyDefaults(A);
    CheckEquals(0, A.Normal.GlowAlpha, 'kein Glow');
    CheckEquals(0, A.Hot.GlowAlpha);
    CheckEquals(0, A.Down.GlowAlpha);
    CheckEquals(0, A.Checked.GlowAlpha);
    CheckEquals(4, A.Rounding);
    CheckEquals(1, A.BorderWidth);
    CheckEquals(3, A.GlowSize, 'Abstand des Fokusrings');
    CheckEquals(Integer(A.Normal.BorderColor), Integer(A.Hot.BorderColor),
      'Hover: Rand bleibt neutral');
    CheckTrue(PPGRelativeLuminance(A.Down.BorderColor) <
      PPGRelativeLuminance(A.Normal.BorderColor), 'Druck/eingerastet: kraeftigerer Rand');
    CheckEquals(Integer(A.Normal.TextColor), Integer(A.Down.TextColor),
      'eingerasteter Toggle bleibt gut lesbar');
    CheckTrue(A.Hot.Color <> A.Normal.Color, 'Hover = Flaechenwechsel');
    CheckTrue(A.Down.Color <> A.Hot.Color, 'Druck = Flaechenwechsel');
    CheckEquals(Integer(A.FocusColor), Integer(A.Checked.Color), 'Akzent');
  finally
    A.Free;
  end;
end;

procedure TFluent11Tests.AccentFromPalette;
var
  Pal: array[0..31] of Byte;
  P: TPPGAccentPair;
  Short: array[0..9] of Byte;
begin
  // Windows-Standardpalette (Blau): Light2 = #4CC2FF, Dark1 = #005FB8
  FillChar(Pal, SizeOf(Pal), 0);
  Pal[4] := $4C; Pal[5] := $C2; Pal[6] := $FF;
  Pal[12] := $00; Pal[13] := $78; Pal[14] := $D4;
  Pal[16] := $00; Pal[17] := $5F; Pal[18] := $B8;
  CheckTrue(PPGAccentFromPalette(Pal, P));
  CheckEquals(Integer($00B85F00), Integer(P.Light), 'Hell = AccentDark1');
  CheckEquals(Integer($00FFC24C), Integer(P.Dark), 'Dunkel = AccentLight2');
  FillChar(Short, SizeOf(Short), 1);
  CheckFalse(PPGAccentFromPalette(Short, P), 'zu kurz');
  FillChar(Pal, SizeOf(Pal), 0);
  CheckFalse(PPGAccentFromPalette(Pal, P), 'leer');
end;

procedure TFluent11Tests.AccentFromBaseMeetsContrast;
const
  Bases: array[0..4] of TColor = ($0000FFFF, $00D47800, $00000000, $00FFFFFF, $00008000);
var
  I: Integer;
  P: TPPGAccentPair;
begin
  // Auch ungeeignete Systemfarben (Gelb, Schwarz, Weiss) ergeben lesbare Akzente
  for I := 0 to High(Bases) do
  begin
    P := PPGAccentFromBase(Bases[I]);
    CheckTrue(PPGContrastRatio(P.Light, clWhite) >= 4.5,
      Format('%.6x hell: Weiss auf Akzent', [Integer(Bases[I])]));
    CheckTrue(PPGContrastRatio(P.Dark, clBlack) >= 7.0,
      Format('%.6x dunkel: Schwarz auf Akzent', [Integer(Bases[I])]));
    CheckTrue(PPGContrastRatio(P.Dark, PPGDefaultTokens(True).Background) >= 3.0,
      Format('%.6x dunkel: Akzent auf Hintergrund', [Integer(Bases[I])]));
  end;
end;

procedure TFluent11Tests.AccentOverrideReachesAppearance;
var
  T: IPPGThemeRenderer;
  Tok: TPPGTokens;
  V: Cardinal;
  B: TPPGButton;
begin
  TPPGFluent11Renderer.AccentOverride := $00008000; // Gruen
  CheckTrue(Supports(TPPGRendererRegistry.Get(PPGPresetFluent11), IPPGThemeRenderer, T));
  Tok := T.Tokens(False);
  V := Cardinal(Tok.Accent);
  CheckTrue(((V shr 8) and $FF) > (V and $FF), 'gruener Akzent');
  CheckTrue(((V shr 8) and $FF) > ((V shr 16) and $FF), 'gruener Akzent');
  CheckTrue(Tok.AccentHover <> Tok.Accent);
  B := NewButton('x');
  B.Preset := PPGPresetFluent11;
  CheckEquals(Integer(Tok.Accent), Integer(B.Appearance.FocusColor));
  CheckEquals(Integer(Tok.Accent), Integer(B.Appearance.Checked.Color));
  CheckEquals(Integer(PPGAccentFromBase($00008000).Dark), Integer(T.Tokens(True).Accent),
    'dunkel: helle Variante');
end;

procedure TFluent11Tests.SystemAccentIsUsed;
var
  P: TPPGAccentPair;
  T: IPPGThemeRenderer;
begin
  PPGRefreshSystemAccent;
  CheckTrue(Supports(TPPGRendererRegistry.Get(PPGPresetFluent11), IPPGThemeRenderer, T));
  if PPGSystemAccent(P) then
  begin
    CheckEquals(Integer(P.Light), Integer(T.Tokens(False).Accent), 'hell: Systemakzent');
    CheckEquals(Integer(P.Dark), Integer(T.Tokens(True).Accent), 'dunkel: Systemakzent');
    CheckTrue(PPGContrastRatio(P.Light, clWhite) >= 4.5);
  end
  else
    CheckEquals(Integer(PPGDefaultTokens(False).Accent), Integer(T.Tokens(False).Accent),
      'ohne Systemakzent: Windows-Blau');
end;

procedure TFluent11Tests.CheckRingPixels(Gdi: Boolean);
var
  B: TPPGButton;
  Bmp: TBitmap;
  Y: Integer;
  Tag: string;
begin
  Tag := System.SysUtils.BoolToStr(Gdi, True);
  TPPGRendererRegistry.ForceGdiFallback := Gdi;
  B := NewButton('');
  try
    B.Preset := PPGPresetFluent11;
    Y := B.Height div 2;
    // Ohne Fokus: der Ringbereich zeigt den Hintergrund
    Bmp := RenderToBitmap(B);
    try
      CheckTrue(ColorDist(Bmp.Canvas.Pixels[0, Y], $001B1B1B) > 150,
        Tag + ': ohne Fokus kein Ring');
    finally
      Bmp.Free;
    end;
    B.SetFocus;
    FForm.Perform(WM_UPDATEUISTATE, MakeWParam(UIS_CLEAR, UISF_HIDEFOCUS), 0);
    B.Perform(WM_UPDATEUISTATE, MakeWParam(UIS_CLEAR, UISF_HIDEFOCUS), 0);
    Bmp := RenderToBitmap(B);
    try
      // Koerper beginnt bei 3 px: aussen 2 px dunkel, dann 1 px hell, dann der Rand
      CheckTrue(ColorDist(Bmp.Canvas.Pixels[0, Y], $001B1B1B) < 60, Tag + ': aussen dunkel (x=0)');
      CheckTrue(ColorDist(Bmp.Canvas.Pixels[1, Y], $001B1B1B) < 60, Tag + ': aussen dunkel (x=1)');
      CheckTrue(ColorDist(Bmp.Canvas.Pixels[2, Y], clWhite) < 60, Tag + ': innen hell (x=2)');
      CheckTrue(ColorDist(Bmp.Canvas.Pixels[3, Y], B.Appearance.FocusColor) > 100,
        Tag + ': Rand bleibt neutral (kein Akzent)');
    finally
      Bmp.Free;
    end;
  finally
    B.Free;
  end;
end;

procedure TFluent11Tests.DoubleFocusRing;
begin
  FForm.Show;
  try
    CheckRingPixels(False);
    CheckRingPixels(True);
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TFluent11Tests.UncheckedBoxHasStrongStroke;
var
  C: TPPGCheckBox;
  Bmp: TBitmap;
  X, Y, First: Integer;
  Bg: TColor;
begin
  C := TPPGCheckBox.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(10, 10, 120, 24);
  C.Caption := '';
  C.Preset := PPGPresetFluent11;
  Bmp := RenderToBitmap(C);
  try
    Y := C.Height div 2;
    Bg := Bmp.Canvas.Pixels[0, Y];
    First := -1;
    for X := 0 to 20 do
      if ColorDist(Bmp.Canvas.Pixels[X, Y], Bg) > 30 then
      begin
        First := X;
        Break;
      end;
    CheckTrue(First >= 0, 'Kaestchen gefunden');
    // Windows 11: kraeftiger Rand (etwa #8A8A8A), nicht der zarte Button-Rand
    CheckTrue(PPGRelativeLuminance(Bmp.Canvas.Pixels[First, Y]) < 0.5,
      Format('Rand zu hell: %.6x', [Integer(Bmp.Canvas.Pixels[First, Y])]));
  finally
    Bmp.Free;
  end;
end;

/// Je ein Control jeder Art auf Form (Liste L), alle im Preset APreset.
procedure CreateAllControls(Form: TForm; const APreset: string; L: TList);
var
  Page: TPPGTabSheet;
  PC: TPPGPageControl;
  TC: TPPGTabControl;
  Combo: TPPGComboBox;
  Chk: TPPGCheckBox;

  procedure Add(Ctl: TPPGCustomControl; X, Y, W, H: Integer);
  begin
    Ctl.Parent := Form;
    Ctl.SetBounds(X, Y, W, H);
    TCustomControlAccess(Ctl).Preset := APreset;
    L.Add(Ctl);
  end;

begin
  Add(TPPGButton.Create(Form), 0, 0, 100, 32);
  Chk := TPPGCheckBox.Create(Form);
  Add(Chk, 0, 40, 100, 24);
  Chk.State := cbGrayed;
  Add(TPPGRadioButton.Create(Form), 0, 70, 100, 24);
  Add(TPPGToggleSwitch.Create(Form), 0, 100, 100, 24);
  Add(TPPGProgressBar.Create(Form), 0, 130, 100, 16);
  Add(TPPGTrackBar.Create(Form), 0, 150, 120, 32);
  Add(TPPGPanel.Create(Form), 130, 0, 100, 60);
  Add(TPPGGroupBox.Create(Form), 130, 70, 100, 60);
  Add(TPPGEdit.Create(Form), 130, 140, 100, 28);
  Add(TPPGMemo.Create(Form), 240, 0, 100, 60);
  Add(TPPGSpinEdit.Create(Form), 240, 70, 100, 28);
  Combo := TPPGComboBox.Create(Form);
  Add(Combo, 240, 110, 100, 28);
  Combo.Items.Add('Eins');
  Combo.ItemIndex := 0;
  TC := TPPGTabControl.Create(Form);
  Add(TC, 0, 190, 180, 80);
  TC.Tabs.Add('A');
  TC.Tabs.Add('B');
  PC := TPPGPageControl.Create(Form);
  Add(PC, 190, 190, 180, 80);
  Page := TPPGTabSheet.Create(Form);
  Page.PageControl := PC;
  Page.Caption := 'Seite';
end;

procedure TFluent11Tests.AllControlsPaint;
var
  Focused: TBitmap;
  L: TList;
  Gdi: Boolean;
  I: Integer;
  C: TPPGCustomControl;
  Bmp: TBitmap;
begin
  L := TList.Create;
  try
    CreateAllControls(FForm, PPGPresetFluent11, L);
    FForm.Show;
    try
      for Gdi := False to True do
      begin
        TPPGRendererRegistry.ForceGdiFallback := Gdi;
        for I := 0 to L.Count - 1 do
        begin
          C := TPPGCustomControl(L[I]);
          // Panel und GroupBox ohne Beschriftung sind fast leere Flaechen: fuer "nicht leer" beschriften
          if C is TPPGPanel then
            TPPGPanel(C).Caption := 'Panel';
          if C is TPPGGroupBox then
            TPPGGroupBox(C).Caption := 'Gruppe';
          // Audit 11b: nicht leer; Controls in der Tab-Folge zeigen den Fokus
          FForm.ActiveControl := nil;
          Bmp := RenderToBitmap(C);
          try
            PPGCheckPainted(Self, Bmp, C.ClassName);
            C.SetFocus;
            C.Perform(WM_UPDATEUISTATE, MakeWParam(UIS_CLEAR, UISF_HIDEFOCUS or UISF_HIDEACCEL), 0);
            Focused := RenderToBitmap(C);
            try
              PPGCheckPainted(Self, Focused, C.ClassName + ' Fokus');
              if C.TabStop then
                PPGCheckDiffers(Self, Bmp, Focused, C.ClassName + ' Fokus');
            finally
              Focused.Free;
            end;
          finally
            Bmp.Free;
          end;
        end;
      end;
    finally
      FForm.Hide;
    end;
  finally
    L.Free;
  end;
  TPPGRendererRegistry.ForceGdiFallback := False;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

{ TThemeTests }

var
  GFakeSystemDark: Boolean = False;

function FakeSystemDark: Boolean;
begin
  Result := GFakeSystemDark;
end;

function ComponentText(C: TComponent): string;
var
  S: TMemoryStream;
  B: TBytes;
begin
  S := TMemoryStream.Create;
  try
    S.WriteComponent(C);
    SetLength(B, S.Size);
    if S.Size > 0 then
      Move(S.Memory^, B[0], S.Size);
    Result := TEncoding.ANSI.GetString(B);
  finally
    S.Free;
  end;
end;

procedure TThemeTests.CountChange(Sender: TObject);
begin
  Inc(FChanges);
end;

procedure TThemeTests.TearDown;
begin
  TPPGTheme.OnChange := nil;
  TPPGTheme.StyleForms := False;
  TPPGTheme.Mode := tmLight;
  TPPGTheme.SystemDarkReader := nil;
  inherited;
end;

procedure TThemeTests.DefaultIsLight;
var
  B: TPPGButton;
begin
  CheckTrue(TPPGTheme.Mode = tmLight, 'Standard: hell (bestehende Anwendungen unveraendert)');
  CheckFalse(TPPGTheme.IsDark);
  B := NewButton('x');
  CheckFalse(B.UseDarkMode);
  CheckTrue(B.EffectiveAppearance = B.Appearance, 'hell: keine Kopie');
end;

procedure TThemeTests.DarkKeepsAppearanceAndDfm;
var
  B: TPPGButton;
  Before: string;
  OldColor: TColor;
begin
  B := NewButton('x');
  B.Appearance.Rounding := 11; // eigene Form
  OldColor := B.Appearance.Normal.Color;
  Before := ComponentText(B);
  TPPGTheme.Mode := tmDark;
  CheckTrue(B.UseDarkMode);
  CheckTrue(B.EffectiveAppearance <> B.Appearance, 'Kopie im Dunkeln');
  CheckTrue(PPGRelativeLuminance(B.EffectiveAppearance.Normal.Color) < 0.1, 'Flaeche dunkel');
  CheckTrue(PPGRelativeLuminance(B.EffectiveAppearance.Normal.TextColor) > 0.7, 'Text hell');
  CheckEquals(11, B.EffectiveAppearance.Rounding, 'Formen bleiben');
  CheckEquals(Integer(OldColor), Integer(B.Appearance.Normal.Color), 'Appearance unveraendert');
  CheckEquals(Before, ComponentText(B), 'DFM unveraendert');
  TPPGTheme.Mode := tmLight;
  CheckTrue(B.EffectiveAppearance = B.Appearance, 'zurueck auf hell');
end;

procedure TThemeTests.SwitchReachesAllControls;
var
  L: TList;
  B: TPPGButton;
  E, M: TPPGCustomField;
  I: Integer;
  Bmp: TBitmap;
begin
  L := TList.Create;
  try
    CreateAllControls(FForm, PPGPresetModernFlat, L);
    FForm.Show;
    try
      B := TPPGButton(L[0]);
      E := TPPGCustomField(L[8]);
      M := TPPGCustomField(L[9]);
      TPPGTheme.Mode := tmDark;
      for I := 0 to L.Count - 1 do
        CheckTrue(TPPGCustomControl(L[I]).UseDarkMode, TPPGCustomControl(L[I]).ClassName);
      Bmp := RenderToBitmap(B);
      try
        CheckTrue(PPGRelativeLuminance(Bmp.Canvas.Pixels[B.Width div 2, B.Height div 2]) < 0.1,
          'Button dunkel gezeichnet');
      finally
        Bmp.Free;
      end;
      // Innere Edits: Flaeche und Textfarbe dunkel/hell, Schrift unveraendert
      CheckTrue(PPGRelativeLuminance(TEditAccess(TFieldAccess(E).Inner).Color) < 0.1,
        'inneres Edit dunkel');
      CheckTrue(PPGRelativeLuminance(TPPGFieldEdit(TFieldAccess(E).Inner).TextColor) > 0.7,
        'Text im Edit hell');
      CheckEquals(Integer(clWindowText), Integer(TFieldAccess(E).Font.Color), 'Font unveraendert');
      CheckTrue(TPPGFieldMemo(TFieldAccess(M).Inner).DarkScrollBars, 'Memo: dunkle Scrollleisten');
      TPPGTheme.Mode := tmLight;
      CheckTrue(PPGRelativeLuminance(TEditAccess(TFieldAccess(E).Inner).Color) > 0.9,
        'zurueck: inneres Edit hell');
      CheckFalse(TPPGFieldMemo(TFieldAccess(M).Inner).DarkScrollBars);
    finally
      FForm.Hide;
    end;
  finally
    L.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TThemeTests.OpenPopupFollowsTheme;
var
  C: TPPGComboBox;
begin
  C := TPPGComboBox.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(10, 10, 150, 26);
  C.Items.Add('Eins');
  C.Items.Add('Zwei');
  FForm.Show;
  try
    C.DropDown;
    CheckTrue(C.DroppedDown);
    CheckTrue(PPGRelativeLuminance(C.PopupList.ListColor) > 0.9, 'hell');
    TPPGTheme.Mode := tmDark;
    CheckTrue(PPGRelativeLuminance(C.PopupList.ListColor) < 0.1, 'offene Liste wird dunkel');
    CheckTrue(C.PopupList.UseDarkMode);
    C.CloseUp(False);
  finally
    FForm.Hide;
  end;
end;

procedure TThemeTests.SystemModeFollowsSetting;
var
  B: TPPGButton;
  Wnd: HWND;
begin
  B := NewButton('x');
  GFakeSystemDark := False;
  TPPGTheme.SystemDarkReader := FakeSystemDark;
  TPPGTheme.OnChange := CountChange;
  TPPGTheme.Mode := tmSystem;
  CheckFalse(TPPGTheme.IsDark, 'System hell');
  Wnd := TPPGTheme.WindowHandle;
  CheckTrue(Wnd <> 0, 'Hilfsfenster fuer WM_SETTINGCHANGE');
  FChanges := 0;
  // Andere Einstellung: kein Wechsel des Modus
  GFakeSystemDark := True;
  SendMessage(Wnd, WM_SETTINGCHANGE, 0, LPARAM(PChar('Policy')));
  CheckEquals(0, FChanges, 'fremde Einstellung ignoriert');
  // Windows meldet den Wechsel auf dunkel
  SendMessage(Wnd, WM_SETTINGCHANGE, 0, LPARAM(PChar('ImmersiveColorSet')));
  CheckTrue(TPPGTheme.IsDark, 'System dunkel');
  CheckTrue(FChanges >= 1, 'OnChange');
  CheckTrue(PPGRelativeLuminance(B.EffectiveAppearance.Normal.Color) < 0.1, 'Control folgt');
  GFakeSystemDark := False;
  SendMessage(Wnd, WM_SETTINGCHANGE, 0, LPARAM(PChar('ImmersiveColorSet')));
  CheckFalse(TPPGTheme.IsDark, 'wieder hell');
  CheckTrue(B.EffectiveAppearance = B.Appearance);
  TPPGTheme.Mode := tmLight;
  CheckEquals(0, Integer(TPPGTheme.WindowHandle), 'Hilfsfenster nur im System-Modus');
  CheckEquals(0, FAppExceptions);
end;

procedure TThemeTests.StyleFormsColorsAndRestores;
var
  B: TPPGButton;
begin
  FForm.Color := clRed;
  FForm.Font.Color := clBlue;
  B := NewButton('x');
  FForm.Show;
  try
    TPPGTheme.StyleForms := True;
    TPPGTheme.Mode := tmDark;
    CheckEquals(Integer(PPGDefaultTokens(True).Background), Integer(FForm.Color), 'Formular dunkel');
    CheckEquals(Integer(PPGDefaultTokens(True).TextPrimary), Integer(FForm.Font.Color));
    TPPGTheme.Mode := tmLight;
    CheckEquals(Integer(PPGDefaultTokens(False).Background), Integer(FForm.Color),
      'StyleForms hell: helle Fensterfarbe');
    TPPGTheme.StyleForms := False;
    CheckEquals(Integer(clRed), Integer(FForm.Color), 'Originalfarbe zurueck');
    CheckEquals(Integer(clBlue), Integer(FForm.Font.Color));
    // Titelleiste direkt: darf auf keinem Windows werfen
    TPPGTheme.SetDarkTitleBar(FForm.Handle, True);
    TPPGTheme.SetDarkTitleBar(FForm.Handle, False);
    TPPGTheme.SetDarkTitleBar(0, True);
  finally
    FForm.Hide;
  end;
  CheckTrue(B <> nil);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TThemeTests.NewFormGetsStyled;
var
  F: TForm;
  B: TPPGButton;
begin
  TPPGTheme.StyleForms := True;
  TPPGTheme.Mode := tmDark;
  F := TForm.CreateNew(nil);
  try
    F.Color := clRed;
    B := TPPGButton.Create(F);
    B.Parent := F;
    B.HandleNeeded; // Fenster erzeugen -> Formular wird gefaerbt
    CheckEquals(Integer(PPGDefaultTokens(True).Background), Integer(F.Color),
      'Formular mit PPGlow-Control wird beim Erzeugen gefaerbt');
  finally
    F.Free;
  end;
  // Freigegebenes Formular darf beim naechsten Wechsel nicht stoeren
  TPPGTheme.Mode := tmLight;
  TPPGTheme.StyleForms := False;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TThemeTests.SeClientOffKeepsOwnColors;
var
  B: TPPGButton;
begin
  B := NewButton('x');
  B.StyleElements := [seFont, seBorder];
  TPPGTheme.Mode := tmDark;
  CheckFalse(B.UseDarkMode, 'ohne seClient kein Dark Mode');
  CheckTrue(B.EffectiveAppearance = B.Appearance);
end;

procedure TThemeTests.TokensFollowMode;
var
  E: TPPGEdit;
  T: IPPGThemeRenderer;
begin
  E := TPPGEdit.Create(FForm);
  E.Parent := FForm;
  CheckTrue(Supports(E.Renderer, IPPGThemeRenderer, T));
  CheckEquals(Integer(T.Tokens(False).Danger), Integer(E.Tokens.Danger));
  TPPGTheme.Mode := tmDark;
  CheckEquals(Integer(T.Tokens(True).Danger), Integer(E.Tokens.Danger), 'dunkle Signalfarbe');
  E.ValidationState := pvsError;
  CheckEquals(Integer(T.Tokens(True).Danger),
    Integer(TEditAccess(E).GetFieldStyle.BorderColor), 'Feld nutzt sie');
end;

procedure TThemeTests.StyleManagerSetsMode;
var
  SM: TPPGStyleManager;
  S: string;
begin
  SM := TPPGStyleManager.Create(FForm);
  CheckTrue(SM.ThemeMode = tmLight);
  S := ComponentText(SM);
  CheckEquals(0, Pos('ThemeMode', S), 'Standard wird nicht gespeichert');
  SM.ThemeMode := tmDark;
  CheckTrue(TPPGTheme.Mode = tmDark, 'setzt den globalen Modus');
  CheckTrue(Pos('ThemeMode', ComponentText(SM)) > 0, 'gespeichert');
  SM.StyleForms := True;
  CheckTrue(TPPGTheme.StyleForms);
  SM.StyleForms := False;
  SM.ThemeMode := tmLight;
  CheckTrue(TPPGTheme.Mode = tmLight);
end;

procedure TThemeTests.ClientsRegisterAndUnregister;
var
  N: Integer;
  B: TPPGButton;
begin
  N := TPPGTheme.ClientCount;
  B := NewButton('x');
  CheckEquals(N + 1, TPPGTheme.ClientCount);
  B.Free;
  CheckEquals(N, TPPGTheme.ClientCount, 'Abmeldung im Destruktor');
end;

procedure TThemeTests.AllPresetsPaintDark;
var
  Names: TStringList;
  L: TList;
  P, I: Integer;
  Gdi: Boolean;
  C: TPPGCustomControl;
  Bmp: TBitmap;
  B: TPPGButton;
begin
  Names := TStringList.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    TPPGTheme.Mode := tmDark;
    FForm.Show;
    try
      for P := 0 to Names.Count - 1 do
      begin
        L := TList.Create;
        try
          CreateAllControls(FForm, Names[P], L);
          for Gdi := False to True do
          begin
            TPPGRendererRegistry.ForceGdiFallback := Gdi;
            for I := 0 to L.Count - 1 do
            begin
              C := TPPGCustomControl(L[I]);
              Bmp := RenderToBitmap(C);
              Bmp.Free;
              C.SetFocus;
              Bmp := RenderToBitmap(C);
              Bmp.Free;
            end;
            B := TPPGButton(L[0]);
            Bmp := RenderToBitmap(B);
            try
              CheckTrue(PPGRelativeLuminance(Bmp.Canvas.Pixels[B.Width div 2,
                B.Height div 2]) < 0.2, Names[P] + ': Button dunkel');
            finally
              Bmp.Free;
            end;
          end;
          for I := L.Count - 1 downto 0 do
            TObject(L[I]).Free;
        finally
          L.Free;
        end;
      end;
    finally
      FForm.Hide;
    end;
  finally
    Names.Free;
  end;
  TPPGRendererRegistry.ForceGdiFallback := False;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TThemeTests.DarkIndicatorBorderVisible;
var
  C: TPPGCheckBox;
  Bmp: TBitmap;
  X, Y, Best: Integer;
  Bg: TColor;
  R, MaxR: Double;
begin
  // Leeres Kaestchen auf dunkler Flaeche: Rand mindestens etwa 3:1 (WCAG 1.4.11)
  TPPGTheme.Mode := tmDark;
  C := TPPGCheckBox.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(10, 10, 120, 24);
  C.Caption := '';
  C.Preset := PPGPresetModernFlat;
  Bmp := RenderToBitmap(C);
  try
    Y := C.Height div 2;
    Bg := Bmp.Canvas.Pixels[C.Width - 2, Y];
    MaxR := 0;
    Best := -1;
    for X := 0 to 24 do
    begin
      R := PPGContrastRatio(Bmp.Canvas.Pixels[X, Y], C.EffectiveAppearance.Normal.Color);
      if R > MaxR then
      begin
        MaxR := R;
        Best := X;
      end;
    end;
    CheckTrue(Best >= 0);
    CheckTrue(MaxR >= 2.8, Format('Rand zu schwach: %.2f', [MaxR]));
    CheckTrue(Bg <> clNone);
  finally
    Bmp.Free;
  end;
end;

{ TEasingTests }

procedure TEasingTests.EndpointsAreZeroAndOne;
var
  E: TPPGEasing;
begin
  for E := Low(TPPGEasing) to High(TPPGEasing) do
  begin
    CheckEquals(0, PPGEase(E, 0), 0.0001, 'Anfang');
    CheckEquals(1, PPGEase(E, 1), 0.0001, 'Ende');
    CheckEquals(0, PPGEase(E, -0.5), 0.0001, 'geklemmt unten');
    CheckEquals(1, PPGEase(E, 1.5), 0.0001, 'geklemmt oben');
  end;
  CheckEquals(0.5, PPGEase(ekLinear, 0.5), 0.0001);
  CheckEquals(0.5, PPGEase(ekSmooth, 0.5), 0.0001, 'Smoothstep symmetrisch');
end;

procedure TEasingTests.CurvesAreMonotonic;
var
  E: TPPGEasing;
  I: Integer;
  Prev, V: Single;
begin
  for E := Low(TPPGEasing) to High(TPPGEasing) do
  begin
    Prev := 0;
    for I := 1 to 100 do
    begin
      V := PPGEase(E, I / 100);
      CheckTrue(V >= Prev, Format('Kurve %d faellt bei %d', [Ord(E), I]));
      Prev := V;
    end;
  end;
end;

procedure TEasingTests.DecelerateIsAboveSmooth;
var
  I: Integer;
  T: Single;
begin
  // Fluent: schnell starten, weich enden - liegt ueberall ueber Smoothstep
  for I := 1 to 19 do
  begin
    T := I / 20;
    CheckTrue(PPGEase(ekDecelerate, T) > PPGEase(ekSmooth, T), Format('t=%.2f', [T]));
  end;
  CheckTrue(PPGEase(ekDecelerate, 0.25) > 0.6, 'schneller Start');
end;

procedure TEasingTests.AnimateToRemembersEasing;
var
  A: TPPGAnimation;
begin
  A := TPPGAnimation.Create(nil);
  try
    A.AnimateTo(1, 1000, ekDecelerate);
    CheckTrue(A.Easing = ekDecelerate);
    CheckTrue(A.Running);
    A.AnimateTo(0, 1000);
    CheckTrue(A.Easing = ekSmooth, 'Standard bleibt Smoothstep');
    A.Stop;
  finally
    A.Free;
  end;
end;

{ TIconFontTests }

procedure TIconFontTests.TearDown;
begin
  PPGSetIconFontOverride('');
  TPPGRendererRegistry.ForceGdiFallback := False;
  inherited;
end;

function TIconFontTests.InkPixels(Glyph: TPPGFieldGlyph): Integer;
var
  Bmp: TBitmap;
  C: IPPGCanvas;
  FR: IPPGFieldRenderer;
  X, Y: Integer;
  S: TPPGSurfaceStyle;
begin
  // Symbol schwarz auf Weiss zeichnen und dunkle Pixel zaehlen
  Result := 0;
  FillChar(S, SizeOf(S), 0);
  S.TextColor := clBlack;
  CheckTrue(Supports(TPPGRendererRegistry.Get(PPGPresetFluent11), IPPGFieldRenderer, FR));
  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf24bit;
    Bmp.SetSize(24, 24);
    Bmp.Canvas.Brush.Color := clWhite;
    Bmp.Canvas.FillRect(Rect(0, 0, 24, 24));
    Bmp.Canvas.Lock;
    try
      C := TPPGRendererRegistry.CreateCanvas(Bmp.Canvas.Handle);
      FR.DrawFieldButton(C, Rect(0, 0, 24, 24), S, Glyph, False, False, 96);
      C := nil;
    finally
      Bmp.Canvas.Unlock;
    end;
    for Y := 0 to 23 do
      for X := 0 to 23 do
        if PPGRelativeLuminance(Bmp.Canvas.Pixels[X, Y]) < 0.5 then
          Inc(Result);
  finally
    Bmp.Free;
  end;
end;

procedure TIconFontTests.FontIsDetected;
var
  N: string;
begin
  N := PPGIconFontName;
  CheckTrue((N = '') or (N = PPGFontFluentIcons) or (N = PPGFontMdl2Assets), N);
  if CheckWin32Version(10) then
    CheckTrue(N <> '', 'Windows 10/11 bringt eine Symbolschrift mit');
  CheckEquals($E70D, Ord(PPGIconChar(igChevronDown)), 'Codepunkt ChevronDown');
end;

procedure TIconFontTests.FallbackWithoutIconFont;
var
  Bmp: TBitmap;
  C: IPPGCanvas;
begin
  PPGSetIconFontOverride('-');
  CheckEquals('', PPGIconFontName);
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(16, 16);
    C := TPPGRendererRegistry.CreateCanvas(Bmp.Canvas.Handle);
    CheckFalse(PPGDrawIcon(C, Rect(0, 0, 16, 16), igClose, clBlack, 12),
      'ohne Schrift: Aufrufer zeichnet');
    C := nil;
  finally
    Bmp.Free;
  end;
  CheckTrue(InkPixels(fgDropDown) > 4, 'Rueckfall auf Linien zeichnet');
  CheckTrue(InkPixels(fgClear) > 4);
  PPGSetIconFontOverride('');
  CheckTrue(PPGIconFontName <> '-');
end;

procedure TIconFontTests.GlyphsDrawInk;
var
  G: TPPGFieldGlyph;
  Gdi: Boolean;
begin
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    for G := fgClear to fgDropDown do
      CheckTrue(InkPixels(G) > 4, Format('Symbol %d sichtbar', [Ord(G)]));
    CheckEquals(0, InkPixels(fgNone), 'fgNone zeichnet nichts');
  end;
end;

initialization
  RegisterTest('Phase8', TTokenTests.Suite);
  RegisterTest('Phase8', TFluent11Tests.Suite);
  RegisterTest('Phase8', TThemeTests.Suite);
  RegisterTest('Phase8', TEasingTests.Suite);
  RegisterTest('Phase8', TIconFontTests.Suite);

end.
