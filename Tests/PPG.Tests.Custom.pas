unit PPG.Tests.Custom;

{ Tests fuer die Anpassbarkeit (Docs\Anforderungen-Anpassbarkeit.md),
  Baustein "Theme-Tokens": Markenfarbe, Token-Ueberschreibungen,
  Diagrammpalette, Theme-Datei und Farbtexte. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, Vcl.Graphics, Vcl.Forms, Vcl.Controls,
  PPG.Tokens, PPG.Consts, PPG.Exceptions, PPG.Render.Intf, PPG.Render.Registry,
  PPG.Presets, PPG.Render.Fluent11, PPG.StyleManager, PPG.ThemeFile,
  PPG.Chart.Palette, PPG.Button, PPG.Types, PPG.Appearance, PPG.Theme,
  PPG.Tests.Controls, PPG.CheckBox, System.UITypes, System.Types, Vcl.Grids, PPG.Grid,
  PPG.Grid.Columns, PPG.Grid.Styles, PPG.ElementStyle, PPG.DB.Grid, PPG.ListBox,
  PPG.TreeView, PPG.ComboBox, PPG.Popup, PPG.ItemPainter, PPG.CustomDraw, PPG.Items,
  Vcl.ComCtrls, Vcl.Menus, PPG.PageControl, PPG.TabControl, PPG.TabStrip, PPG.NavigationView,
  PPG.StatusBar, PPG.ToolBar, PPG.Menus, PPG.Popup.Placement, PPG.Calendar, PPG.DatePicker,
  PPG.Planner, PPG.Planner.Model, PPG.Kanban, PPG.Kanban.Items, PPG.Chart, PPG.Chart.Series,
  PPG.Expander, PPG.GroupBox, PPG.Gauge, PPG.Feedback, System.DateUtils, Vcl.ImgList,
  PPG.Render.Gdi, PPG.Render.GdiPlus, PPG.Ribbon, PPG.Ribbon.Items, PPG.Ribbon.Layout,
  PPG.Print, PPG.Kanban.Print, PPG.Edit, PPG.Panel, System.TypInfo, Vcl.Imaging.pngimage,
  PPG.CheckListBox, PPG.ProgressBar, PPG.ColorPicker, PPG.Controls.Field;

type
  TCustomThemeTests = class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure AccentOverrideAppliesToAllPresets;
    procedure AccentOverrideKeepsContrast;
    procedure TokenOverrideWinsPerMode;
    procedure ClearRestoresPresetTokens;
    procedure StyleManagerAccentReachesControls;
    procedure StyleManagerAccentDerivesAppearance;
    procedure StyleManagerFreeClearsBranding;
    procedure ThemeColorsStreamOnlyWhenSet;
    procedure ThemeColorsLoadedFromDfmApply;
    procedure ChartPaletteOverridesSeriesColors;
    procedure ChartPaletteSkipsInvalidLines;
    procedure ThemeFileRoundTrip;
    procedure ThemeFileInvalidValueKeepsManager;
    procedure ColorTextRoundTrip;
  end;

  // Baustein Appearance: Fokus-Zustand, Dunkel-Farben, Schriftstil je Zustand
  TCustomAppearanceTests = class(TControlTestCase)
  private
    FOldMode: TPPGThemeMode;
    function DarkPixels(B: TBitmap): Integer;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure FocusedColorsApplyOnlyWhenFocused;
    procedure FocusedKeepsUnsetColors;
    procedure DarkColorsApplyInDarkMode;
    procedure DarkModeIgnoresLightFocusedColors;
    procedure FontStyleBlendsAtHalfway;
    procedure NewPropertiesStreamOnlyWhenSet;
    procedure AssignAndEqualsCoverNewParts;
    procedure BoldStatePaintsBolderCaption;
    procedure CheckedFontStyleOnCheckBoxCaption;
  end;

  // Baustein Element-Stile: Grid und DB-Grid
  TCustomGridTests = class(TControlTestCase)
  private
    FOldMode: TPPGThemeMode;
    function NewGrid: TPPGGrid;
    function PixelAt(G: TPPGGrid; ACol, VRow, DX, DY: Integer): TColor;
    function DarkCount(G: TPPGGrid; ACol, VRow: Integer): Integer;
    procedure BoldStyle(Sender: TObject; ACol, ARow: Integer; var Style: TPPGGridCellStyle);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure HeaderColorFillsFixedArea;
    procedure FixedColorMapsToHeaderStyle;
    procedure ZebraFillsEverySecondRow;
    procedure SelectionColorIsOpaque;
    procedure GridLineColorAndWidth;
    procedure GridLineWidthZeroHidesLines;
    procedure ColumnStyleFillsCells;
    procedure ColumnTitleStyleAndAlignment;
    procedure HeaderFontStyleMakesBolderText;
    procedure CellStyleFontStyleFromEvent;
    procedure DarkModeUsesDarkColors;
    procedure GradientHeaderDrawingStyle;
    procedure HotRowFollowsMouse;
    procedure StylesStreamOnlyWhenSet;
    procedure DBGridTitleFontMapsToHeader;
    procedure EmptyStylesKeepDefaultLook;
  end;

  // Baustein Element-Stile: Listen, Baum, Combo-Liste; eigenes Zeichnen
  TCustomListTests = class(TControlTestCase)
  private
    FDrawCalls: Integer;
    FSawCanvas: Boolean;
    FLastNode: TPPGTreeNode;
    function NewList: TPPGListBox;
    function PixelIn(C: TWinControl; const R: TRect; DX: Integer): TColor;
    function DarkIn(C: TWinControl; const R: TRect): Integer;
    procedure DrawItem(Sender: TObject; Canvas: TCanvas; Index: Integer; const ARect: TRect;
      State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean);
    procedure DrawNode(Sender: TObject; Canvas: TCanvas; Node: TPPGTreeNode; const ARect: TRect;
      State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean);
  published
    procedure ZebraAndItemColor;
    procedure SelectionInactiveColorOpaque;
    procedure ItemFontStyleBolder;
    procedure GroupHeaderAndDetailStyles;
    procedure CustomDrawStyleAndSkip;
    procedure TreeNodeColorAndCustomDrawNode;
    procedure TreeHotTrackUnderlines;
    procedure TreeToolTipForTruncatedText;
    procedure ComboPassesListStylesToPopup;
    procedure ListStylesStreamOnlyWhenSet;
  end;

  // Baustein Element-Stile: Reiter, Navigation, Leisten, Menues
  TCustomBarTests = class(TControlTestCase)
  private
    FTabDraws: Integer;
    FMenuDraws: Integer;
    function NewPages(Count: Integer): TPPGPageControl;
    function Px(C: TWinControl; X, Y: Integer): TColor;
    procedure DrawTab(Control: TObject; TabIndex: Integer; const Rect: TRect; Active: Boolean);
    procedure DrawNav(Sender: TObject; Canvas: TCanvas; Item: TPPGNavItem; const ARect: TRect;
      State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean);
    procedure DrawMenu(Sender: TObject; Canvas: TCanvas; Item: TMenuItem; const ARect: TRect;
      State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean);
  published
    procedure TabColorAndActiveTabStyle;
    procedure MultiLineWrapsTabsIntoRows;
    procedure MultiLineSelectedRowNextToPage;
    procedure ButtonStyleDrawsWithoutOverlap;
    procedure OwnerDrawCallsOnDrawTab;
    procedure TabControlDfmPropertiesStream;
    procedure NavItemColorAndCustomDraw;
    procedure NavPaneStyle;
    procedure StatusPanelColorAndBarStyle;
    procedure ToolItemColorFillsAtRest;
    procedure MenuStylesAndCustomDraw;
  end;

  // Baustein Element-Stile: Kalender, Planer, Kanban, Diagramm, Kopf-Schriften
  TCustomViewTests = class(TControlTestCase)
  private
    FHoliday: TDate;
    function Count(C: TWinControl; Color: TColor): Integer;
    procedure DrawDay(Sender: TObject; Canvas: TCanvas; ADate: TDate; const ARect: TRect;
      State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean);
    procedure DrawAppt(Sender: TObject; Canvas: TCanvas; Appointment: TPPGAppointment;
      const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
      var DefaultDraw: Boolean);
    procedure DrawCard(Sender: TObject; Canvas: TCanvas; const Card: TPPGKanbanCardData;
      const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
      var DefaultDraw: Boolean);
  published
    procedure CalendarWeekendSelectedAndCustomDay;
    procedure DatePickerStreamsCalendarStyles;
    procedure PlannerCategoryColorAndStyles;
    procedure PlannerCustomDrawAppointment;
    procedure KanbanStylesAndCustomDrawCard;
    procedure ChartTitleGridAndLegendStyles;
    procedure ExpanderGroupBoxHeaderStyles;
    procedure KpiGaugeInfoBarStyles;
  end;

  // Baustein Button und Bilder: Ausrichtung, Margin, Bild je Zustand, Einfaerben
  TCustomButtonTests = class(TControlTestCase)
  private
    FImages: TImageList;
    function MakeImages: TImageList;
    function TextSpan(B: TBitmap; out L, R: Integer): Boolean;
  protected
    procedure TearDown; override;
  published
    procedure AlignmentLeftAndRight;
    procedure MarginMovesContent;
    procedure PressedImageIndexWhenDown;
    procedure ImageTintUsesTextColor;
    procedure TintedDrawKeepsShape;
    procedure NewButtonPropertiesStream;
  end;

  // Restpunkte: Layout speichern, Schnellzugriff, Kanban-Druck, ReadOnly-Optik,
  // Touch, Rundung je Ecke, Schatten
  TCustomRestTests = class(TControlTestCase)
  private
    function CornerPixels(const Canvas: IPPGCanvas; B: TBitmap; Frame: Boolean): string;
  published
    procedure KanbanLayoutRoundTrip;
    procedure PlannerLayoutRoundTrip;
    procedure RibbonQuickAccessRoundTrip;
    procedure KanbanPrinterPagesAndContent;
    procedure ReadOnlyStyleColorsField;
    procedure TouchAndGesturePublished;
    procedure SquareCornersOnBothCanvases;
    procedure ButtonRoundedCorners;
    procedure ShadowShrinksBodyAndDarkens;
    procedure PanelShadowKeepsChildrenInside;
    procedure CornersAndShadowStream;
  end;

  // Properties, die bisher nur fuer die DFM-Kompatibilitaet gespeichert wurden
  TCustomVclPropTests = class(TControlTestCase)
  private
    FTomorrowAsked: Boolean;
    procedure UserInput(Sender: TObject; const UserString: string; var DateAndTime: TDateTime;
      var AllowChange: Boolean);
    function NewList(N: Integer): TPPGListBox;
    procedure Shot(C: TWinControl; const Name: string);
  published
    procedure ListBoxColumnsArrangeAndNavigate;
    procedure ListBoxScrollWidthWidensRows;
    procedure ListBoxIntegralHeightSnaps;
    procedure ListBoxTabWidthExpandsTabs;
    procedure CheckListBoxHeaderColorsAndFlat;
    procedure TreeViewRowSelectFalseHighlightsText;
    procedure ProgressBarSmoothFalseDrawsBlocks;
    procedure TabsLeftAndRight;
    procedure TabsScrollOpposite;
    procedure ColorPickerNoneColorColor;
    procedure DatePickerTimeKind;
    procedure DatePickerUpDownMode;
    procedure DatePickerParseInput;
  end;

implementation

function ThemeTokens(const Preset: string; Dark: Boolean): TPPGTokens;
var
  TR: IPPGThemeRenderer;
begin
  if not Supports(TPPGRendererRegistry.Get(Preset), IPPGThemeRenderer, TR) then
    raise Exception.Create('kein Theme-Renderer: ' + Preset);
  Result := TR.Tokens(Dark);
end;

function ComponentToText(C: TComponent): string;
var
  Bin, Txt: TMemoryStream;
  S: TStringStream;
begin
  Bin := TMemoryStream.Create;
  Txt := TMemoryStream.Create;
  try
    Bin.WriteComponent(C);
    Bin.Position := 0;
    ObjectBinaryToText(Bin, Txt);
    S := TStringStream.Create('');
    try
      Txt.Position := 0;
      S.CopyFrom(Txt, Txt.Size);
      Result := S.DataString;
    finally
      S.Free;
    end;
  finally
    Txt.Free;
    Bin.Free;
  end;
end;

procedure TextToComponent(const Text: string; C: TComponent);
var
  Bin: TMemoryStream;
  S: TStringStream;
begin
  S := TStringStream.Create(Text);
  Bin := TMemoryStream.Create;
  try
    ObjectTextToBinary(S, Bin);
    Bin.Position := 0;
    Bin.ReadComponent(C);
  finally
    Bin.Free;
    S.Free;
  end;
end;

{ TCustomThemeTests }

procedure TCustomThemeTests.SetUp;
begin
  TPPGTokenOverrides.Clear;
end;

procedure TCustomThemeTests.TearDown;
begin
  TPPGTokenOverrides.Clear;
end;

procedure TCustomThemeTests.AccentOverrideAppliesToAllPresets;
const
  Presets: array[0..2] of string = (PPGPresetClassic, PPGPresetModernFlat, PPGPresetFluent11);
var
  I: Integer;
  P: TPPGAccentPair;
begin
  TPPGTokenOverrides.AccentBase := $00206020; // Gruen
  P := PPGAccentFromBase($00206020);
  for I := 0 to High(Presets) do
  begin
    CheckEquals(Integer(P.Light), Integer(ThemeTokens(Presets[I], False).Accent), Presets[I] + ' hell');
    CheckEquals(Integer(P.Dark), Integer(ThemeTokens(Presets[I], True).Accent), Presets[I] + ' dunkel');
    CheckEquals(Integer(clWhite), Integer(ThemeTokens(Presets[I], False).OnAccent), 'Text auf Akzent hell');
  end;
  // auch die neutrale Palette (Dialoge, Formulare)
  CheckEquals(Integer(P.Light), Integer(PPGDefaultTokens(False).Accent));
  // Basis ohne Ueberschreibung bleibt unberuehrt
  CheckFalse(PPGBaseTokens(False).Accent = P.Light, 'BaseTokens ohne Marke');
end;

procedure TCustomThemeTests.AccentOverrideKeepsContrast;
const
  Bases: array[0..3] of TColor = (clYellow, clWhite, clBlack, $0000A5FF);
var
  I: Integer;
  T: TPPGTokens;
begin
  for I := 0 to High(Bases) do
  begin
    TPPGTokenOverrides.AccentBase := Bases[I];
    T := ThemeTokens(PPGPresetModernFlat, False);
    CheckTrue(PPGContrastRatio(T.Accent, clWhite) >= 4.5, 'hell: weisser Text ' + IntToStr(I));
    T := ThemeTokens(PPGPresetModernFlat, True);
    CheckTrue(PPGContrastRatio(T.Accent, clBlack) >= 7.0, 'dunkel: schwarzer Text ' + IntToStr(I));
  end;
end;

procedure TCustomThemeTests.TokenOverrideWinsPerMode;
var
  BaseDark: TColor;
begin
  BaseDark := ThemeTokens(PPGPresetFluent11, True).Danger;
  TPPGTokenOverrides.Colors[False, tkDanger] := $00123456;
  TPPGTokenOverrides.AccentBase := clRed;
  TPPGTokenOverrides.Colors[False, tkAccent] := $00010203; // Einzeltoken nach Akzent
  CheckEquals($00123456, Integer(ThemeTokens(PPGPresetFluent11, False).Danger));
  CheckEquals(Integer(BaseDark), Integer(ThemeTokens(PPGPresetFluent11, True).Danger), 'Dunkel unveraendert');
  CheckEquals($00010203, Integer(ThemeTokens(PPGPresetClassic, False).Accent), 'Token schlaegt AccentBase');
  // Systemfarben werden aufgeloest
  TPPGTokenOverrides.Colors[True, tkBackground] := clWindow;
  CheckEquals(Integer(ColorToRGB(clWindow)), Integer(ThemeTokens(PPGPresetModernFlat, True).Background));
end;

procedure TCustomThemeTests.ClearRestoresPresetTokens;
var
  Before: TPPGTokens;
  V: Integer;
begin
  Before := ThemeTokens(PPGPresetModernFlat, False);
  V := TPPGTokenOverrides.Version;
  TPPGTokenOverrides.AccentBase := clRed;
  TPPGTokenOverrides.Colors[False, tkSurface] := clYellow;
  CheckTrue(TPPGTokenOverrides.Active);
  CheckTrue(TPPGTokenOverrides.Version > V, 'Version zaehlt');
  TPPGTokenOverrides.Clear;
  CheckFalse(TPPGTokenOverrides.Active);
  CheckEquals(Integer(Before.Accent), Integer(ThemeTokens(PPGPresetModernFlat, False).Accent));
  CheckEquals(Integer(Before.Surface), Integer(ThemeTokens(PPGPresetModernFlat, False).Surface));
end;

procedure TCustomThemeTests.StyleManagerAccentReachesControls;
var
  M: TPPGStyleManager;
  B: TPPGButton;
begin
  M := TPPGStyleManager.Create(nil);
  B := TPPGButton.Create(nil);
  try
    B.StyleManager := M;
    M.AccentColor := $00800000; // Navy
    CheckEquals(Integer(PPGAccentFromBase($00800000).Light), Integer(B.Tokens.Accent),
      'Button ohne Fenster sieht den Akzent');
    CheckEquals(Integer($00800000), Integer(TPPGTokenOverrides.AccentBase));
    M.AccentColor := clDefault;
    CheckFalse(TPPGTokenOverrides.Active, 'zurueckgesetzt');
  finally
    B.Free;
    M.Free;
  end;
end;

procedure TCustomThemeTests.StyleManagerAccentDerivesAppearance;
var
  M: TPPGStyleManager;
  B: TPPGButton;
  Rounding: Integer;
begin
  M := TPPGStyleManager.Create(nil);
  B := TPPGButton.Create(nil);
  try
    M.Preset := PPGPresetFluent11;
    M.Appearance.Rounding := 11;
    B.StyleManager := M;
    M.AccentColor := $00008000;
    Rounding := M.Appearance.Rounding;
    CheckEquals(11, Rounding, 'Formen bleiben');
    CheckEquals(Integer(PPGAccentFromBase($00008000).Light), Integer(M.Appearance.FocusColor),
      'FocusColor aus dem neuen Akzent');
    CheckEquals(Integer(M.Appearance.Checked.Color), Integer(B.Appearance.Checked.Color),
      'Client hat die neue Appearance');
    // Einzelnes Token im hellen Modus leitet ebenfalls neu ab
    M.ThemeColors.Light.Surface := $00EEDDCC;
    CheckEquals($00EEDDCC, Integer(M.Appearance.Normal.Color));
  finally
    B.Free;
    M.Free;
  end;
end;

procedure TCustomThemeTests.StyleManagerFreeClearsBranding;
var
  M: TPPGStyleManager;
begin
  M := TPPGStyleManager.Create(nil);
  try
    M.ThemeColors.Dark.Danger := clFuchsia;
    CheckTrue(TPPGTokenOverrides.Active);
  finally
    M.Free;
  end;
  CheckFalse(TPPGTokenOverrides.Active, 'Marke endet mit dem Manager');
end;

procedure TCustomThemeTests.ThemeColorsStreamOnlyWhenSet;
var
  M: TPPGStyleManager;
  S: string;
begin
  M := TPPGStyleManager.Create(nil);
  try
    S := ComponentToText(M);
    CheckEquals(0, Pos('ThemeColors', S), 'Standard wird nicht gespeichert');
    CheckEquals(0, Pos('AccentColor', S));
    CheckEquals(0, Pos('ChartPalette', S));
    M.ThemeColors.Dark.TextSecondary := clSilver;
    M.AccentColor := clTeal;
    S := ComponentToText(M);
    CheckTrue(Pos('ThemeColors.Dark.TextSecondary = clSilver', S) > 0, S);
    CheckTrue(Pos('AccentColor = clTeal', S) > 0, S);
    CheckEquals(0, Pos('ThemeColors.Light', S), 'nur gesetzte Werte');
  finally
    M.Free;
  end;
end;

procedure TCustomThemeTests.ThemeColorsLoadedFromDfmApply;
var
  M: TPPGStyleManager;
begin
  M := TPPGStyleManager.Create(nil);
  try
    TextToComponent('object M: TPPGStyleManager' + sLineBreak +
      '  AccentColor = clPurple' + sLineBreak +
      '  ThemeColors.Light.Warning = clOlive' + sLineBreak +
      '  ChartPalette.Strings = (' + sLineBreak + '    ''#FF0000''' + sLineBreak +
      '    ''clBlue'')' + sLineBreak + 'end', M);
    CheckEquals(Integer(clPurple), Integer(TPPGTokenOverrides.AccentBase));
    CheckEquals(Integer(clOlive), Integer(TPPGTokenOverrides.Colors[False, tkWarning]));
    CheckEquals(2, Length(TPPGTokenOverrides.ChartPalette));
    CheckEquals(Integer(clRed), Integer(TPPGTokenOverrides.ChartPalette[0]));
  finally
    M.Free;
  end;
end;

procedure TCustomThemeTests.ChartPaletteOverridesSeriesColors;
var
  T: TPPGTokens;
  M: TPPGStyleManager;
  C: TColor;
begin
  M := TPPGStyleManager.Create(nil);
  try
    M.ChartPalette.Text := '#102030' + sLineBreak + 'clRed' + sLineBreak + '$0000FF00';
    T := PPGDefaultTokens(False);
    CheckEquals($00302010, Integer(PPGChartColor(T, False, 0)));
    CheckEquals(Integer(clRed), Integer(PPGChartColor(T, False, 1)));
    CheckEquals($0000FF00, Integer(PPGChartColor(T, False, 2)));
    CheckEquals($00302010, Integer(PPGChartColor(T, False, 3)), 'laeuft um');
    // Dunkel: zu dunkle Farbe wird bis 3:1 aufgehellt
    T := PPGDefaultTokens(True);
    C := PPGChartColor(T, True, 0);
    CheckTrue(PPGContrastRatio(C, T.Background) >= 3.0, 'Kontrast im Dunkeln');
    M.ChartPalette.Clear;
    CheckEquals(0, Length(TPPGTokenOverrides.ChartPalette), 'leer = Preset');
  finally
    M.Free;
  end;
end;

procedure TCustomThemeTests.ChartPaletteSkipsInvalidLines;
var
  M: TPPGStyleManager;
begin
  M := TPPGStyleManager.Create(nil);
  try
    M.ChartPalette.Text := 'keineFarbe' + sLineBreak + '#00FF00' + sLineBreak + '';
    CheckEquals(1, Length(TPPGTokenOverrides.ChartPalette));
    CheckEquals(Integer(clLime), Integer(TPPGTokenOverrides.ChartPalette[0]));
  finally
    M.Free;
  end;
end;

procedure TCustomThemeTests.ThemeFileRoundTrip;
var
  A, B: TPPGStyleManager;
  S: TMemoryStream;
  Txt: TStringList;
begin
  A := TPPGStyleManager.Create(nil);
  B := TPPGStyleManager.Create(nil);
  S := TMemoryStream.Create;
  Txt := TStringList.Create;
  try
    A.Preset := PPGPresetFluent11;
    A.Appearance.Rounding := 9;
    A.Appearance.Hot.TextColor := clMaroon;
    A.Animation.Duration := 333;
    A.ThemeColors.Dark.Danger := $00102030;
    A.ChartPalette.Text := '#112233' + sLineBreak + 'clGreen';
    A.AccentColor := $00664422;
    A.Appearance.Hot.TextColor := clMaroon; // nach dem Ableiten wieder setzen
    A.SaveToStream(S);
    S.Position := 0;
    Txt.LoadFromStream(S);
    CheckTrue(Txt.IndexOf('[PPGlowTheme]') >= 0, Txt.Text);
    CheckTrue(Pos('AccentColor=#224466', Txt.Text) > 0, Txt.Text);
    CheckTrue(Pos('Appearance.Hot.TextColor=#800000', Txt.Text) > 0, 'Farben als #RRGGBB');
    TPPGTokenOverrides.Clear;
    S.Position := 0;
    B.LoadFromStream(S);
    CheckEquals(PPGPresetFluent11, B.Preset);
    CheckEquals(9, B.Appearance.Rounding);
    CheckEquals(Integer(clMaroon), Integer(B.Appearance.Hot.TextColor), 'geladene Farbe bleibt');
    CheckEquals(333, B.Animation.Duration);
    CheckEquals($00664422, Integer(B.AccentColor));
    CheckEquals($00102030, Integer(B.ThemeColors.Dark.Danger));
    CheckEquals(2, B.ChartPalette.Count);
    CheckEquals($00664422, Integer(TPPGTokenOverrides.AccentBase), 'Marke ist aktiv');
  finally
    Txt.Free;
    S.Free;
    B.Free;
    A.Free;
  end;
end;

procedure TCustomThemeTests.ThemeFileInvalidValueKeepsManager;
var
  M: TPPGStyleManager;
  S: TStringStream;
  Raised: Boolean;
begin
  M := TPPGStyleManager.Create(nil);
  S := TStringStream.Create('[PPGlowTheme]' + sLineBreak + 'Format=1' + sLineBreak +
    'Appearance.Rounding=7' + sLineBreak + 'AccentColor=keineFarbe' + sLineBreak);
  try
    M.Appearance.Rounding := 5;
    Raised := False;
    try
      M.LoadFromStream(S);
    except
      on E: EPPGStreamError do
        Raised := True;
    end;
    CheckTrue(Raised, 'EPPGStreamError erwartet');
    CheckEquals(5, M.Appearance.Rounding, 'Manager unveraendert');
    CheckEquals(Integer(clDefault), Integer(M.AccentColor));
  finally
    S.Free;
    M.Free;
  end;
end;

procedure TCustomThemeTests.ColorTextRoundTrip;
var
  C: TColor;
begin
  CheckEquals('#1E90FF', PPGColorToText($00FF901E));
  CheckEquals('clBtnFace', PPGColorToText(clBtnFace));
  CheckEquals('clDefault', PPGColorToText(clDefault));
  CheckTrue(PPGTryTextToColor('#1E90FF', C));
  CheckEquals($00FF901E, Integer(C));
  CheckTrue(PPGTryTextToColor('#F00', C));
  CheckEquals(Integer(clRed), Integer(C));
  CheckTrue(PPGTryTextToColor('Navy', C), 'Kurzform ohne cl');
  CheckEquals(Integer(clNavy), Integer(C));
  CheckTrue(PPGTryTextToColor('$0000FF00', C));
  CheckEquals(Integer(clLime), Integer(C));
  CheckFalse(PPGTryTextToColor('#12345', C));
  CheckFalse(PPGTryTextToColor('', C));
  try
    PPGTextToColor('xyz');
    Fail('EPPGPropertyError erwartet');
  except
    on E: EPPGPropertyError do
      CheckTrue(Pos('xyz', E.Message) > 0);
  end;
end;

{ TCustomAppearanceTests }

procedure TCustomAppearanceTests.SetUp;
begin
  inherited SetUp;
  FOldMode := TPPGTheme.Mode;
end;

procedure TCustomAppearanceTests.TearDown;
begin
  TPPGTheme.Mode := FOldMode;
  inherited TearDown;
end;

function TCustomAppearanceTests.DarkPixels(B: TBitmap): Integer;
var
  X, Y: Integer;
  C: TColor;
begin
  Result := 0;
  for Y := 0 to B.Height - 1 do
    for X := 0 to B.Width - 1 do
    begin
      C := B.Canvas.Pixels[X, Y];
      if PPGRelativeLuminance(C) < 0.25 then
        Inc(Result);
    end;
end;

procedure TCustomAppearanceTests.FocusedColorsApplyOnlyWhenFocused;
var
  A: TPPGAppearance;
  S: TPPGSurfaceStyle;
begin
  A := TPPGAppearance.Create(nil);
  try
    A.Normal.Color := clWhite;
    A.Focused.Color := clYellow;
    A.Focused.TextColor := clNavy;
    A.Focused.FontStyle := [fsUnderline];
    S := A.Resolve(vsNormal, 96, False);
    CheckEquals(Integer(clWhite), Integer(S.Color), 'ohne Fokus');
    S := A.Resolve(vsNormal, 96, True);
    CheckEquals(Integer(clYellow), Integer(S.Color));
    CheckEquals(Integer(clYellow), Integer(S.ColorTo), 'einfarbig');
    CheckEquals(Integer(clNavy), Integer(S.TextColor));
    CheckTrue(fsUnderline in S.FontStyle);
  finally
    A.Free;
  end;
end;

procedure TCustomAppearanceTests.FocusedKeepsUnsetColors;
var
  A: TPPGAppearance;
  S: TPPGSurfaceStyle;
begin
  A := TPPGAppearance.Create(nil);
  try
    A.Normal.Color := clWhite;
    A.Normal.TextColor := clBlack;
    A.FocusColor := clRed;
    A.Focused.ColorTo := clSilver;
    S := A.Resolve(vsNormal, 96, True);
    CheckEquals(Integer(clWhite), Integer(S.Color));
    CheckEquals(Integer(clSilver), Integer(S.ColorTo));
    CheckEquals(Integer(clBlack), Integer(S.TextColor));
    CheckEquals(Integer(clRed), Integer(S.BorderColor), 'Fokusfarbe bleibt');
  finally
    A.Free;
  end;
end;

procedure TCustomAppearanceTests.DarkColorsApplyInDarkMode;
var
  B: TPPGButton;
  LightHot: TColor;
begin
  B := NewButton('Dark');
  B.Appearance.Dark.Normal.Color := $00332211;
  B.Appearance.Dark.Checked.TextColor := clLime;
  B.Appearance.Dark.FocusColor := clFuchsia;
  LightHot := B.Appearance.Hot.Color;
  TPPGTheme.Mode := tmLight;
  CheckFalse(B.EffectiveAppearance.Normal.Color = $00332211, 'hell: keine Dunkel-Farbe');
  TPPGTheme.Mode := tmDark;
  CheckEquals($00332211, Integer(B.EffectiveAppearance.Normal.Color));
  CheckEquals($00332211, Integer(B.EffectiveAppearance.Normal.ColorMirrorTo), 'einfarbig');
  CheckEquals(Integer(clLime), Integer(B.EffectiveAppearance.Checked.TextColor));
  CheckEquals(Integer(clFuchsia), Integer(B.EffectiveAppearance.FocusColor));
  CheckFalse(B.EffectiveAppearance.Hot.Color = LightHot, 'Hot bleibt Preset-dunkel');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomAppearanceTests.DarkModeIgnoresLightFocusedColors;
var
  B: TPPGButton;
begin
  B := NewButton('F');
  B.Appearance.Focused.TextColor := clRed;
  B.Appearance.Dark.Focused.BorderColor := clAqua;
  TPPGTheme.Mode := tmDark;
  CheckEquals(Integer(clDefault), Integer(B.EffectiveAppearance.Focused.TextColor));
  CheckEquals(Integer(clAqua), Integer(B.EffectiveAppearance.Focused.BorderColor));
  TPPGTheme.Mode := tmLight;
  CheckEquals(Integer(clRed), Integer(B.EffectiveAppearance.Focused.TextColor));
end;

procedure TCustomAppearanceTests.FontStyleBlendsAtHalfway;
var
  N, H: TPPGSurfaceStyle;
begin
  FillChar(N, SizeOf(N), 0);
  H := N;
  H.FontStyle := [fsBold];
  CheckTrue(PPGBlendSurface(N, H, 0.3).FontStyle = []);
  CheckTrue(PPGBlendSurface(N, H, 0.7).FontStyle = [fsBold]);
end;

procedure TCustomAppearanceTests.NewPropertiesStreamOnlyWhenSet;
var
  B: TPPGButton;
  S: string;
begin
  B := TPPGButton.Create(nil);
  try
    S := ComponentToText(B);
    CheckEquals(0, Pos('FontStyle', S), 'Standard nicht gespeichert');
    CheckEquals(0, Pos('Appearance.Focused', S));
    CheckEquals(0, Pos('Appearance.Dark', S));
    B.Appearance.Hot.FontStyle := [fsBold];
    B.Appearance.Focused.Color := clYellow;
    B.Appearance.Dark.Down.TextColor := clWhite;
    S := ComponentToText(B);
    CheckTrue(Pos('Appearance.Hot.FontStyle = [fsBold]', S) > 0, S);
    CheckTrue(Pos('Appearance.Focused.Color = clYellow', S) > 0, S);
    CheckTrue(Pos('Appearance.Dark.Down.TextColor = clWhite', S) > 0, S);
    B.Appearance.Hot.FontStyle := [];
    TextToComponent(S, B);
    CheckTrue(B.Appearance.Hot.FontStyle = [fsBold], 'geladen');
    CheckEquals(Integer(clWhite), Integer(B.Appearance.Dark.Down.TextColor));
  finally
    B.Free;
  end;
end;

procedure TCustomAppearanceTests.AssignAndEqualsCoverNewParts;
var
  A, C: TPPGAppearance;
begin
  A := TPPGAppearance.Create(nil);
  C := TPPGAppearance.Create(nil);
  try
    A.Focused.BorderColor := clRed;
    A.Dark.Hot.FontStyle := [fsItalic];
    A.Dark.FocusColor := clLime;
    A.Normal.FontStyle := [fsBold];
    CheckFalse(A.Equals(C));
    C.Assign(A);
    CheckTrue(A.Equals(C));
    CheckEquals(Integer(clRed), Integer(C.Focused.BorderColor));
    CheckTrue(C.Dark.Hot.FontStyle = [fsItalic]);
    CheckEquals(Integer(clLime), Integer(C.Dark.FocusColor));
    C.Dark.Hot.FontStyle := [];
    CheckFalse(A.Equals(C), 'Dark zaehlt bei Equals');
  finally
    C.Free;
    A.Free;
  end;
end;

procedure TCustomAppearanceTests.BoldStatePaintsBolderCaption;
var
  B: TPPGButton;
  Bmp: TBitmap;
  Normal, Bold: Integer;
begin
  B := NewButton('WWWWWW');
  B.SetBounds(0, 0, 160, 40);
  B.Font.Color := clBlack;
  B.Appearance.Normal.TextColor := clBlack;
  Bmp := RenderToBitmap(B);
  try
    Normal := DarkPixels(Bmp);
  finally
    Bmp.Free;
  end;
  B.Appearance.Normal.FontStyle := [fsBold];
  Bmp := RenderToBitmap(B);
  try
    Bold := DarkPixels(Bmp);
  finally
    Bmp.Free;
  end;
  CheckTrue(Bold > Normal + 20, Format('fett %d > normal %d', [Bold, Normal]));
  CheckFalse(fsBold in B.Font.Style, 'Font des Controls unveraendert');
end;

procedure TCustomAppearanceTests.CheckedFontStyleOnCheckBoxCaption;
var
  C: TPPGCheckBox;
  Bmp: TBitmap;
  Off, OnPixels: Integer;
begin
  C := TPPGCheckBox.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(0, 0, 200, 30);
  C.Caption := 'WWWWWW';
  C.Font.Color := clBlack;
  C.Appearance.Normal.TextColor := clBlack;
  C.Appearance.Checked.FontStyle := [fsBold];
  Bmp := RenderToBitmap(C);
  try
    Off := DarkPixels(Bmp);
  finally
    Bmp.Free;
  end;
  C.Checked := True;
  Bmp := RenderToBitmap(C);
  try
    OnPixels := DarkPixels(Bmp);
  finally
    Bmp.Free;
  end;
  CheckTrue(OnPixels > Off + 20, Format('an %d > aus %d', [OnPixels, Off]));
end;

{ TCustomGridTests }

procedure TCustomGridTests.SetUp;
begin
  inherited SetUp;
  FOldMode := TPPGTheme.Mode;
  TPPGTheme.Mode := tmLight;
end;

procedure TCustomGridTests.TearDown;
begin
  TPPGTheme.Mode := FOldMode;
  inherited TearDown;
end;

function TCustomGridTests.NewGrid: TPPGGrid;
var
  R, C: Integer;
begin
  Result := TPPGGrid.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 360, 200);
  Result.ColCount := 4;
  Result.RowCount := 6;
  for R := 1 to 5 do
    for C := 1 to 3 do
      Result.Cells[C, R] := '';
  Result.HandleNeeded;
end;

function TCustomGridTests.PixelAt(G: TPPGGrid; ACol, VRow, DX, DY: Integer): TColor;
var
  B: TBitmap;
  R: TRect;
begin
  B := RenderToBitmap(G);
  try
    R := G.CellRect(ACol, VRow);
    Result := B.Canvas.Pixels[R.Left + DX, R.Top + DY];
  finally
    B.Free;
  end;
end;

function TCustomGridTests.DarkCount(G: TPPGGrid; ACol, VRow: Integer): Integer;
var
  B: TBitmap;
  R: TRect;
  X, Y: Integer;
begin
  Result := 0;
  B := RenderToBitmap(G);
  try
    R := G.CellRect(ACol, VRow);
    for Y := R.Top + 2 to R.Bottom - 3 do
      for X := R.Left + 2 to R.Right - 3 do
        if PPGRelativeLuminance(B.Canvas.Pixels[X, Y]) < 0.3 then
          Inc(Result);
  finally
    B.Free;
  end;
end;

procedure TCustomGridTests.BoldStyle(Sender: TObject; ACol, ARow: Integer;
  var Style: TPPGGridCellStyle);
begin
  if (ACol = 1) and (ARow = 1) then
    Style.FontStyle := [fsBold];
end;

procedure TCustomGridTests.HeaderColorFillsFixedArea;
var
  G: TPPGGrid;
begin
  G := NewGrid;
  G.Styles.Header.Color := clYellow;
  CheckEquals(Integer(clYellow), Integer(PixelAt(G, 2, 0, 3, 3)), 'Kopfzeile');
  CheckEquals(Integer(clYellow), Integer(PixelAt(G, 0, 2, 3, 3)), 'Kopfspalte');
  CheckFalse(PixelAt(G, 2, 2, 3, 3) = clYellow, 'Daten unveraendert');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomGridTests.FixedColorMapsToHeaderStyle;
var
  G: TPPGGrid;
begin
  G := NewGrid;
  CheckEquals(Integer(clBtnFace), Integer(G.FixedColor), 'Vorgabe wie TStringGrid');
  G.FixedColor := clLime;
  CheckEquals(Integer(clLime), Integer(G.Styles.Header.Color));
  G.FixedColor := clBtnFace;
  CheckEquals(Integer(clDefault), Integer(G.Styles.Header.Color), 'clBtnFace = Preset');
end;

procedure TCustomGridTests.ZebraFillsEverySecondRow;
var
  G: TPPGGrid;
begin
  G := NewGrid;
  G.Styles.AlternateRow.Color := clAqua;
  CheckFalse(PixelAt(G, 2, 1, 3, 3) = clAqua, 'erste Datenzeile ohne');
  CheckEquals(Integer(clAqua), Integer(PixelAt(G, 2, 2, 3, 3)), 'zweite Datenzeile');
  CheckFalse(PixelAt(G, 2, 3, 3, 3) = clAqua);
  CheckEquals(Integer(clAqua), Integer(PixelAt(G, 2, 4, 3, 3)));
end;

procedure TCustomGridTests.SelectionColorIsOpaque;
var
  G: TPPGGrid;
  Sel: TGridRect;
begin
  G := NewGrid;
  G.Styles.Selection.Color := clRed;
  G.Styles.SelectionInactive.Color := clRed;
  Sel.Left := 2;
  Sel.Right := 2;
  Sel.Top := 3;
  Sel.Bottom := 3;
  G.Selection := Sel;
  CheckEquals(Integer(clRed), Integer(PixelAt(G, 2, 3, 6, 6)));
  CheckFalse(PixelAt(G, 3, 3, 6, 6) = clRed, 'Nachbar nicht');
end;

procedure TCustomGridTests.GridLineColorAndWidth;
var
  G: TPPGGrid;
  B: TBitmap;
  R: TRect;
begin
  G := NewGrid;
  G.Styles.GridLine.Color := clRed;
  G.GridLineWidth := 3;
  B := RenderToBitmap(G);
  try
    R := G.CellRect(2, 2);
    CheckEquals(Integer(clRed), Integer(B.Canvas.Pixels[R.Right - 1, R.Top + 8]), 'rechts 1');
    CheckEquals(Integer(clRed), Integer(B.Canvas.Pixels[R.Right - 3, R.Top + 8]), 'rechts 3');
    CheckFalse(B.Canvas.Pixels[R.Right - 5, R.Top + 8] = clRed, 'nur 3 px');
    CheckEquals(Integer(clRed), Integer(B.Canvas.Pixels[R.Left + 8, R.Bottom - 3]), 'unten 3');
  finally
    B.Free;
  end;
end;

procedure TCustomGridTests.GridLineWidthZeroHidesLines;
var
  G: TPPGGrid;
  B: TBitmap;
  R: TRect;
begin
  G := NewGrid;
  G.Styles.GridLine.Color := clRed;
  G.GridLineWidth := 0;
  B := RenderToBitmap(G);
  try
    R := G.CellRect(2, 2);
    CheckFalse(B.Canvas.Pixels[R.Right - 1, R.Top + 8] = clRed);
  finally
    B.Free;
  end;
  try
    G.GridLineWidth := 11;
    Fail('EPPGPropertyError erwartet');
  except
    on E: EPPGPropertyError do
      CheckEquals(0, G.GridLineWidth, 'unveraendert');
  end;
end;

procedure TCustomGridTests.ColumnStyleFillsCells;
var
  G: TPPGGrid;
  I: Integer;
begin
  G := NewGrid;
  for I := 0 to 3 do
    G.Columns.Add;
  G.Columns[2].Style.Color := clFuchsia;
  G.Styles.AlternateRow.Color := clAqua;
  CheckEquals(Integer(clFuchsia), Integer(PixelAt(G, 2, 1, 3, 3)));
  CheckEquals(Integer(clFuchsia), Integer(PixelAt(G, 2, 2, 3, 3)), 'Spalte vor Zebra');
  CheckEquals(Integer(clAqua), Integer(PixelAt(G, 3, 2, 3, 3)), 'Nachbarspalte Zebra');
  CheckFalse(PixelAt(G, 2, 0, 3, 3) = clFuchsia, 'Kopf nicht');
end;

procedure TCustomGridTests.ColumnTitleStyleAndAlignment;
var
  G: TPPGGrid;
  I: Integer;
begin
  G := NewGrid;
  for I := 0 to 3 do
    G.Columns.Add;
  G.Columns[1].Alignment := taRightJustify;
  CheckTrue(G.Columns[1].EffectiveTitleAlignment = taRightJustify, 'wie Spalte');
  G.Columns[1].TitleAlignment := gtaCenter;
  CheckTrue(G.Columns[1].EffectiveTitleAlignment = taCenter);
  G.Columns[1].TitleStyle.Color := clOlive;
  CheckEquals(Integer(clOlive), Integer(PixelAt(G, 1, 0, 3, 3)));
  CheckFalse(PixelAt(G, 2, 0, 3, 3) = clOlive);
end;

procedure TCustomGridTests.HeaderFontStyleMakesBolderText;
var
  G: TPPGGrid;
  N, B: Integer;
begin
  G := NewGrid;
  G.Font.Color := clBlack;
  G.Cells[2, 0] := 'WWWWW';
  N := DarkCount(G, 2, 0);
  G.Styles.Header.FontStyle := [fsBold];
  B := DarkCount(G, 2, 0);
  CheckTrue(B > N + 10, Format('fett %d > normal %d', [B, N]));
end;

procedure TCustomGridTests.CellStyleFontStyleFromEvent;
var
  G: TPPGGrid;
  N, B: Integer;
begin
  G := NewGrid;
  G.Font.Color := clBlack;
  G.Cells[1, 1] := 'WWWWW';
  N := DarkCount(G, 1, 1);
  G.OnGetCellStyle := BoldStyle;
  B := DarkCount(G, 1, 1);
  CheckTrue(B > N + 10, Format('fett %d > normal %d', [B, N]));
end;

procedure TCustomGridTests.DarkModeUsesDarkColors;
var
  G: TPPGGrid;
begin
  G := NewGrid;
  G.Styles.AlternateRow.Color := clAqua;
  G.Styles.AlternateRow.DarkColor := $00404000;
  TPPGTheme.Mode := tmDark;
  CheckEquals($00404000, Integer(PixelAt(G, 2, 2, 3, 3)));
  G.Styles.AlternateRow.DarkColor := clDefault;
  CheckFalse(PixelAt(G, 2, 2, 3, 3) = clAqua, 'helle Farbe gilt im Dunkeln nicht');
end;

procedure TCustomGridTests.GradientHeaderDrawingStyle;
var
  G: TPPGGrid;
  B: TBitmap;
  R: TRect;
begin
  G := NewGrid;
  G.DrawingStyle := gdsGradient;
  G.GradientStartColor := clWhite;
  G.GradientEndColor := clBlack;
  B := RenderToBitmap(G);
  try
    R := G.CellRect(2, 0);
    CheckTrue(PPGRelativeLuminance(B.Canvas.Pixels[R.Left + 3, R.Top + 2]) >
      PPGRelativeLuminance(B.Canvas.Pixels[R.Left + 3, R.Bottom - 4]) + 0.2, 'Verlauf hell -> dunkel');
  finally
    B.Free;
  end;
end;

procedure TCustomGridTests.HotRowFollowsMouse;
var
  G: TPPGGrid;
  R: TRect;
begin
  G := NewGrid;
  G.Styles.HotRow.Color := clLime;
  R := G.CellRect(2, 3);
  G.Perform(WM_MOUSEMOVE, 0, MakeLParam(R.Left + 5, R.Top + 5));
  CheckEquals(Integer(clLime), Integer(PixelAt(G, 2, 3, 3, 3)));
  CheckFalse(PixelAt(G, 2, 2, 3, 3) = clLime);
  G.Perform(CM_MOUSELEAVE, 0, 0);
  CheckFalse(PixelAt(G, 2, 3, 3, 3) = clLime, 'nach Verlassen');
end;

procedure TCustomGridTests.StylesStreamOnlyWhenSet;
var
  G: TPPGGrid;
  S: string;
begin
  G := TPPGGrid.Create(nil);
  try
    S := ComponentToText(G);
    CheckEquals(0, Pos('Styles.', S));
    CheckEquals(0, Pos('FixedColor', S));
    CheckEquals(0, Pos('GradientStartColor', S));
    CheckEquals(0, Pos('GridLineWidth', S));
    G.Styles.AlternateRow.Color := clAqua;
    G.Styles.Header.Font.Size := 12;
    G.FixedColor := clYellow;
    S := ComponentToText(G);
    CheckTrue(Pos('Styles.AlternateRow.Color = clAqua', S) > 0, S);
    CheckTrue(Pos('Styles.Header.Color = clYellow', S) > 0, S);
    CheckTrue(Pos('Styles.Header.ParentFont = False', S) > 0, S);
    CheckEquals(0, Pos('FixedColor', S), 'Alias nicht gespeichert');
    G.Styles.AlternateRow.Color := clDefault;
    TextToComponent(S, G);
    CheckEquals(Integer(clAqua), Integer(G.Styles.AlternateRow.Color));
    CheckEquals(12, G.Styles.Header.Font.Size);
  finally
    G.Free;
  end;
end;

procedure TCustomGridTests.DBGridTitleFontMapsToHeader;
var
  G: TPPGDBGrid;
begin
  G := TPPGDBGrid.Create(nil);
  try
    CheckTrue(G.Styles.Header.ParentFont);
    G.TitleFont.Size := 14;
    CheckFalse(G.Styles.Header.ParentFont, 'TitleFont setzt eigene Schrift');
    CheckEquals(14, G.Styles.Header.Font.Size);
    G.FixedColor := clGray;
    CheckEquals(Integer(clGray), Integer(G.Styles.Header.Color));
  finally
    G.Free;
  end;
end;

procedure TCustomGridTests.EmptyStylesKeepDefaultLook;
var
  A, B: TPPGGrid;
  BA, BB: TBitmap;
  X, Y, Diff: Integer;
begin
  A := NewGrid;
  B := NewGrid;
  B.Top := 210;
  B.Styles.AlternateRow.Color := clAqua;
  B.Styles.AlternateRow.Color := clDefault; // wieder leer
  B.GridLineWidth := 1;
  BA := RenderToBitmap(A);
  BB := RenderToBitmap(B);
  try
    Diff := 0;
    for Y := 0 to BA.Height - 1 do
      for X := 0 to BA.Width - 1 do
        if BA.Canvas.Pixels[X, Y] <> BB.Canvas.Pixels[X, Y] then
          Inc(Diff);
    CheckEquals(0, Diff, 'ohne Stile pixelgleich');
  finally
    BB.Free;
    BA.Free;
  end;
end;

{ TCustomListTests }

function TCustomListTests.NewList: TPPGListBox;
var
  I: Integer;
begin
  Result := TPPGListBox.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 220, 200);
  for I := 0 to 4 do
    Result.ItemsEx.Add('Eintrag ' + IntToStr(I));
  Result.HandleNeeded;
end;

function TCustomListTests.PixelIn(C: TWinControl; const R: TRect; DX: Integer): TColor;
var
  B: TBitmap;
begin
  B := RenderToBitmap(C);
  try
    Result := B.Canvas.Pixels[R.Right - DX, (R.Top + R.Bottom) div 2];
  finally
    B.Free;
  end;
end;

function TCustomListTests.DarkIn(C: TWinControl; const R: TRect): Integer;
var
  B: TBitmap;
  X, Y: Integer;
begin
  Result := 0;
  B := RenderToBitmap(C);
  try
    for Y := R.Top + 1 to R.Bottom - 2 do
      for X := R.Left + 1 to R.Right - 2 do
        if PPGRelativeLuminance(B.Canvas.Pixels[X, Y]) < 0.3 then
          Inc(Result);
  finally
    B.Free;
  end;
end;

procedure TCustomListTests.DrawItem(Sender: TObject; Canvas: TCanvas; Index: Integer;
  const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
  var DefaultDraw: Boolean);
begin
  Inc(FDrawCalls);
  FSawCanvas := FSawCanvas or (Canvas <> nil) and (Canvas.Handle <> 0);
  if Index = 0 then
    Style.Fill := clLime
  else if Index = 1 then
    DefaultDraw := False;
end;

procedure TCustomListTests.DrawNode(Sender: TObject; Canvas: TCanvas; Node: TPPGTreeNode;
  const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
  var DefaultDraw: Boolean);
begin
  if Node.Text = 'B' then
  begin
    FLastNode := Node;
    Style.Fill := clFuchsia;
  end;
end;

procedure TCustomListTests.ZebraAndItemColor;
var
  L: TPPGListBox;
begin
  L := NewList;
  L.Styles.AlternateRow.Color := clAqua;
  L.ItemsEx[2].Color := clYellow;
  CheckFalse(PixelIn(L, L.ItemRect(0), 8) = clAqua, 'Zeile 0 ohne Zebra');
  CheckEquals(Integer(clAqua), Integer(PixelIn(L, L.ItemRect(1), 8)), 'Zeile 1 Zebra');
  CheckEquals(Integer(clYellow), Integer(PixelIn(L, L.ItemRect(2), 8)), 'Farbe des Eintrags');
  CheckEquals(Integer(clAqua), Integer(PixelIn(L, L.ItemRect(3), 8)));
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomListTests.SelectionInactiveColorOpaque;
var
  L: TPPGListBox;
begin
  L := NewList;
  L.Styles.SelectionInactive.Color := clRed;
  L.ItemIndex := 2;
  CheckEquals(Integer(clRed), Integer(PixelIn(L, L.ItemRect(2), 12)), 'eigene Auswahl ohne Fokus');
  CheckFalse(PixelIn(L, L.ItemRect(1), 12) = clRed);
end;

procedure TCustomListTests.ItemFontStyleBolder;
var
  L: TPPGListBox;
  N, B: Integer;
begin
  L := NewList;
  L.Font.Color := clBlack;
  L.ItemsEx[0].Text := 'WWWWWWW';
  L.ItemsEx[1].Text := 'WWWWWWW';
  L.ItemsEx[1].FontStyle := [fsBold];
  N := DarkIn(L, L.ItemRect(0));
  B := DarkIn(L, L.ItemRect(1));
  CheckTrue(B > N + 10, Format('fett %d > normal %d', [B, N]));
end;

procedure TCustomListTests.GroupHeaderAndDetailStyles;
var
  L: TPPGListBox;
  B: TBitmap;
  R: TRect;
begin
  L := NewList;
  L.ItemsEx[0].Group := 'Gruppe';
  L.ItemsEx[1].Group := 'Gruppe';
  L.Styles.GroupHeader.Color := clOlive;
  B := RenderToBitmap(L);
  try
    R := L.ItemRect(0);
    // Ueberschrift liegt ueber der ersten Zeile
    CheckEquals(Integer(clOlive), Integer(B.Canvas.Pixels[R.Right - 8, R.Top - 4]));
  finally
    B.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomListTests.CustomDrawStyleAndSkip;
var
  L: TPPGListBox;
begin
  L := NewList;
  L.Font.Color := clBlack;
  L.ItemsEx[1].Text := 'WWWWWWW';
  L.OnCustomDrawItem := DrawItem;
  CheckEquals(Integer(clLime), Integer(PixelIn(L, L.ItemRect(0), 8)), 'Style.Fill');
  CheckEquals(0, DarkIn(L, L.ItemRect(1)), 'DefaultDraw = False: nichts gezeichnet');
  CheckTrue(FDrawCalls >= 5, 'Ereignis je Eintrag');
  CheckTrue(FSawCanvas, 'Canvas mit Handle');
end;

procedure TCustomListTests.TreeNodeColorAndCustomDrawNode;
var
  T: TPPGTreeView;
  A, B: TPPGTreeNode;
begin
  T := TPPGTreeView.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(0, 0, 220, 200);
  A := T.Items.Add(nil, 'A');
  B := T.Items.Add(nil, 'B');
  A.Color := clYellow;
  T.HandleNeeded;
  CheckEquals(Integer(clYellow), Integer(PixelIn(T, T.ItemRect(0), 8)), 'Knotenfarbe');
  T.OnCustomDrawNode := DrawNode;
  CheckEquals(Integer(clFuchsia), Integer(PixelIn(T, T.ItemRect(1), 8)), 'OnCustomDrawNode');
  CheckTrue(FLastNode = B, 'Knoten kommt an');
end;

procedure TCustomListTests.TreeHotTrackUnderlines;
var
  T: TPPGTreeView;
  R: TRect;
  N, U: Integer;
begin
  T := TPPGTreeView.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(0, 0, 220, 200);
  T.Font.Color := clBlack;
  T.Items.Add(nil, 'WWWWWW');
  T.HandleNeeded;
  R := T.ItemRect(0);
  T.Perform(WM_MOUSEMOVE, 0, MakeLParam(R.Left + 40, (R.Top + R.Bottom) div 2));
  N := DarkIn(T, R);
  T.HotTrack := True;
  U := DarkIn(T, R);
  CheckTrue(U > N + 5, Format('unterstrichen %d > %d', [U, N]));
end;

procedure TCustomListTests.TreeToolTipForTruncatedText;
var
  T: TPPGTreeView;
  R: TRect;
  HI: THintInfo;
  M: TCMHintShow;
begin
  T := TPPGTreeView.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(0, 0, 80, 100);
  T.Items.Add(nil, 'Ein sehr langer Knotentext, der nicht passt');
  T.Items.Add(nil, 'kurz');
  T.HandleNeeded;
  FillChar(HI, SizeOf(HI), 0);
  R := T.ItemRect(0);
  HI.CursorPos := Point(R.Left + 30, (R.Top + R.Bottom) div 2);
  HI.HintControl := T;
  M.Msg := CM_HINTSHOW;
  M.HintInfo := @HI;
  M.Result := 0;
  T.Dispatch(M);
  CheckEquals('Ein sehr langer Knotentext, der nicht passt', HI.HintStr);
  R := T.ItemRect(1);
  HI.HintStr := '';
  HI.CursorPos := Point(R.Left + 30, (R.Top + R.Bottom) div 2);
  T.Dispatch(M);
  CheckEquals('', HI.HintStr, 'passt: kein Hinweis');
  T.ToolTips := False;
  HI.CursorPos := Point(R.Left + 30, (T.ItemRect(0).Top + T.ItemRect(0).Bottom) div 2);
  T.Dispatch(M);
  CheckEquals('', HI.HintStr, 'ToolTips aus');
end;

function CountColor(B: TBitmap; C: TColor): Integer;
var
  X, Y: Integer;
begin
  Result := 0;
  for Y := 0 to B.Height - 1 do
    for X := 0 to B.Width - 1 do
      if B.Canvas.Pixels[X, Y] = C then
        Inc(Result);
end;

procedure TCustomListTests.ComboPassesListStylesToPopup;
var
  C: TPPGComboBox;
  LS: IPPGListStylesSource;
  B: TBitmap;
  R: TRect;
begin
  C := TPPGComboBox.Create(FForm);
  C.Parent := FForm;
  C.ItemsEx.Add('Eins');
  C.ItemsEx.Add('Zwei');
  C.ItemsEx.Add('Drei');
  C.ItemsEx.Add('Vier');
  C.ItemsEx.Add('Fuenf');
  C.ListStyles.AlternateRow.Color := clAqua;
  C.Animation.Enabled := False; // Liste sofort in voller Groesse
  C.OnCustomDrawItem := DrawItem;
  CheckTrue(Supports(C, IPPGListStylesSource, LS));
  CheckTrue(LS.GetListStyles = C.ListStyles);
  FForm.Show;
  try
    C.DroppedDown := True;
    B := RenderToBitmap(C.PopupList);
    try
      // Zebra in Zeile 1 und 3 (eine davon kann unter der Maus liegen)
      CheckTrue(CountColor(B, clAqua) > 50, 'Zebra in der Aufklappliste');
      R := C.PopupList.ItemRect(0);
      CheckEquals(Integer(clLime), Integer(B.Canvas.Pixels[R.Right - 20, (R.Top + R.Bottom) div 2]));
    finally
      B.Free;
    end;
    C.DroppedDown := False;
  finally
    FForm.Hide;
  end;
end;

procedure TCustomListTests.ListStylesStreamOnlyWhenSet;
var
  L: TPPGListBox;
  S: string;
begin
  L := TPPGListBox.Create(nil);
  try
    S := ComponentToText(L);
    CheckEquals(0, Pos('Styles.', S));
    L.Styles.HotItem.TextColor := clMaroon;
    L.ItemsEx.Add('x').FontStyle := [fsItalic];
    S := ComponentToText(L);
    CheckTrue(Pos('Styles.HotItem.TextColor = clMaroon', S) > 0, S);
    CheckTrue(Pos('FontStyle = [fsItalic]', S) > 0, S);
  finally
    L.Free;
  end;
end;

{ TCustomBarTests }

function TCustomBarTests.NewPages(Count: Integer): TPPGPageControl;
var
  I: Integer;
  P: TPPGTabSheet;
begin
  Result := TPPGPageControl.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 300, 160);
  for I := 0 to Count - 1 do
  begin
    P := TPPGTabSheet.Create(FForm);
    P.PageControl := Result;
    P.Caption := 'Seite ' + IntToStr(I);
  end;
  Result.ActivePageIndex := 0;
  Result.HandleNeeded;
end;

function TCustomBarTests.Px(C: TWinControl; X, Y: Integer): TColor;
var
  B: TBitmap;
begin
  B := RenderToBitmap(C);
  try
    Result := B.Canvas.Pixels[X, Y];
  finally
    B.Free;
  end;
end;

procedure TCustomBarTests.DrawTab(Control: TObject; TabIndex: Integer; const Rect: TRect;
  Active: Boolean);
begin
  Inc(FTabDraws);
  // Inhalt selbst: Flaeche im Reiter (Canvas des Controls)
  TPPGCustomTabs(Control).Canvas.Brush.Color := clRed;
  TPPGCustomTabs(Control).Canvas.FillRect(System.Types.Rect(Rect.Left + 4, Rect.Top + 4,
    Rect.Left + 10, Rect.Top + 10));
end;

procedure TCustomBarTests.DrawNav(Sender: TObject; Canvas: TCanvas; Item: TPPGNavItem;
  const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
  var DefaultDraw: Boolean);
begin
  if Item.Caption = 'Zwei' then
    Style.Fill := clFuchsia;
end;

procedure TCustomBarTests.DrawMenu(Sender: TObject; Canvas: TCanvas; Item: TMenuItem;
  const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
  var DefaultDraw: Boolean);
begin
  Inc(FMenuDraws);
  if Item.Caption = 'B' then
    Style.Fill := clLime;
end;

procedure TCustomBarTests.TabColorAndActiveTabStyle;
var
  PC: TPPGPageControl;
  R: TRect;
begin
  PC := NewPages(3);
  PC.Pages[1].TabColor := clYellow;
  PC.TabStyles.ActiveTab.Color := clAqua;
  R := PC.TabRect(1);
  CheckEquals(Integer(clYellow), Integer(Px(PC, R.Left + 4, (R.Top + R.Bottom) div 2)), 'TabColor');
  R := PC.TabRect(0);
  CheckEquals(Integer(clAqua), Integer(Px(PC, R.Left + 4, (R.Top + R.Bottom) div 2)), 'ActiveTab');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomBarTests.MultiLineWrapsTabsIntoRows;
var
  PC: TPPGPageControl;
  Single: Integer;
  RowRight, W0, I: Integer;
begin
  PC := NewPages(8);
  Single := PC.DisplayRect.Top;
  CheckTrue(PC.Strip.Overflow, 'ohne MultiLine: Blaetterpfeile');
  PC.MultiLine := True;
  CheckFalse(PC.Strip.Overflow, 'MultiLine: keine Pfeile');
  CheckTrue(PC.Strip.RowCount >= 2, 'mehrere Reihen');
  CheckTrue(PC.DisplayRect.Top > Single, 'Seite rueckt nach unten');
  CheckFalse(IsRectEmpty(PC.TabRect(7)), 'letzter Reiter sichtbar');
  // ohne RaggedRight fuellen die Reihen die Breite
  RowRight := 0;
  for I := 0 to 7 do
    if (PC.TabRect(I).Top = PC.TabRect(0).Top) and (PC.TabRect(I).Right > RowRight) then
      RowRight := PC.TabRect(I).Right;
  CheckTrue(RowRight > PC.Width - 20, 'Reihe gefuellt');
  W0 := PC.TabRect(0).Right - PC.TabRect(0).Left;
  PC.RaggedRight := True;
  CheckTrue(PC.TabRect(0).Right - PC.TabRect(0).Left < W0, 'RaggedRight: nicht gestreckt');
end;

procedure TCustomBarTests.MultiLineSelectedRowNextToPage;
var
  PC: TPPGPageControl;
begin
  PC := NewPages(8);
  PC.MultiLine := True;
  PC.ActivePageIndex := 0;
  CheckEquals(PC.DisplayRect.Top > 0, True);
  CheckTrue(PC.TabRect(0).Bottom >= PC.TabRect(7).Bottom, 'Reihe des gewaehlten unten');
  PC.ActivePageIndex := 7;
  CheckTrue(PC.TabRect(7).Bottom >= PC.TabRect(0).Bottom, 'nach Wechsel unten');
end;

procedure TCustomBarTests.ButtonStyleDrawsWithoutOverlap;
var
  PC: TPPGPageControl;
begin
  PC := NewPages(3);
  PC.Style := tsButtons;
  RenderToBitmap(PC).Free;
  PC.Style := tsFlatButtons;
  RenderToBitmap(PC).Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomBarTests.OwnerDrawCallsOnDrawTab;
var
  PC: TPPGPageControl;
  R: TRect;
begin
  FTabDraws := 0; // DUnit verwendet das Testobjekt im Leak-Lauf wieder
  PC := NewPages(3);
  PC.OnDrawTab := DrawTab;
  RenderToBitmap(PC).Free;
  CheckEquals(0, FTabDraws, 'ohne OwnerDraw kein Aufruf');
  PC.OwnerDraw := True;
  R := PC.TabRect(1);
  CheckEquals(Integer(clRed), Integer(Px(PC, R.Left + 6, R.Top + 6)), 'OnDrawTab zeichnet');
  CheckTrue(FTabDraws >= 3);
end;

procedure TCustomBarTests.TabControlDfmPropertiesStream;
var
  T: TPPGTabControl;
  S: string;
begin
  T := TPPGTabControl.Create(nil);
  try
    T.MultiLine := True;
    T.RaggedRight := True;
    T.ScrollOpposite := True;
    T.Style := tsFlatButtons;
    T.OwnerDraw := True;
    T.TabStyles.HotTab.TextColor := clRed;
    S := ComponentToText(T);
    CheckTrue(Pos('MultiLine = True', S) > 0, S);
    CheckTrue(Pos('Style = tsFlatButtons', S) > 0, S);
    CheckTrue(Pos('TabStyles.HotTab.TextColor = clRed', S) > 0, S);
    T.MultiLine := False;
    TextToComponent(S, T);
    CheckTrue(T.MultiLine);
    CheckTrue(T.ScrollOpposite);
  finally
    T.Free;
  end;
end;

procedure TCustomBarTests.NavItemColorAndCustomDraw;
var
  N: TPPGNavigationView;
  B: TBitmap;
  Y1, Y2, X, I, Found1, Found2: Integer;
begin
  N := TPPGNavigationView.Create(FForm);
  N.Parent := FForm;
  N.SetBounds(0, 0, 250, 280);
  N.Items.AddItem('Eins').Color := clYellow;
  N.Items.AddItem('Zwei');
  N.OnCustomDrawItem := DrawNav;
  N.HandleNeeded;
  B := RenderToBitmap(N);
  try
    Found1 := 0;
    Found2 := 0;
    for Y1 := 0 to B.Height - 1 do
      for X := 100 to 110 do
      begin
        if B.Canvas.Pixels[X, Y1] = clYellow then
          Inc(Found1);
        if B.Canvas.Pixels[X, Y1] = clFuchsia then
          Inc(Found2);
      end;
    CheckTrue(Found1 > 50, 'Item.Color');
    CheckTrue(Found2 > 50, 'OnCustomDrawItem');
  finally
    B.Free;
  end;
  Y2 := 0;
  I := Y2;
  CheckEquals(0, I + FErrors.Count, FErrors.Text);
end;

procedure TCustomBarTests.NavPaneStyle;
var
  N: TPPGNavigationView;
begin
  N := TPPGNavigationView.Create(FForm);
  N.Parent := FForm;
  N.SetBounds(0, 0, 250, 280);
  N.NavStyles.Pane.Color := clOlive;
  CheckEquals(Integer(clOlive), Integer(Px(N, 120, N.Height - 6)));
end;

procedure TCustomBarTests.StatusPanelColorAndBarStyle;
var
  S: TPPGStatusBar;
  P: TPPGStatusPanel;
begin
  S := TPPGStatusBar.Create(FForm);
  S.Parent := FForm;
  S.Align := alNone;
  S.SetBounds(0, 0, 300, 28);
  S.SizeGrip := False;
  S.BarStyle.Color := clSilver;
  P := S.Panels.Add;
  P.Width := 100;
  P.Color := clYellow;
  S.Panels.Add.Width := 100;
  CheckEquals(Integer(clYellow), Integer(Px(S, 20, 14)), 'Feld');
  CheckEquals(Integer(clSilver), Integer(Px(S, 250, 14)), 'Leiste');
end;

procedure TCustomBarTests.ToolItemColorFillsAtRest;
var
  T: TPPGToolBar;
  It: TPPGToolItem;
  B: TBitmap;
  X, Y, N: Integer;
begin
  T := TPPGToolBar.Create(FForm);
  T.Parent := FForm;
  T.Align := alNone;
  T.SetBounds(0, 0, 300, 40);
  It := T.Items.Add;
  It.Caption := 'Speichern';
  It.Color := clLime;
  It.FontStyle := [fsBold];
  B := RenderToBitmap(T);
  try
    N := 0;
    for Y := 0 to B.Height - 1 do
      for X := 0 to B.Width - 1 do
        if B.Canvas.Pixels[X, Y] = clLime then
          Inc(N);
    CheckTrue(N > 200, 'Flaeche in Ruhe');
  finally
    B.Free;
  end;
end;

procedure TCustomBarTests.MenuStylesAndCustomDraw;
var
  M: TPPGPopupMenu;
  L: TPPGMenuLoop;
  W: TPPGMenuWindow;
  It: TMenuItem;
  B: TBitmap;
  R: TRect;
begin
  M := TPPGPopupMenu.Create(FForm);
  It := TMenuItem.Create(M);
  It.Caption := 'A';
  M.Items.Add(It);
  It := TMenuItem.Create(M);
  It.Caption := 'B';
  M.Items.Add(It);
  M.MenuStyles.Menu.Color := clYellow;
  FForm.Show;
  L := TPPGMenuLoop.Create;
  try
    L.Animate := False;
    L.MenuStyles := M.MenuStyles;
    L.OnCustomDrawItem := DrawMenu;
    L.DrawSender := M;
    L.OpenPopup(M.Items, Rect(100, 100, 100, 100), ppsBelow, False);
    W := L.TopWindow;
    B := RenderToBitmap(W);
    try
      R := W.ItemRect(0);
      CheckEquals(Integer(clYellow), Integer(B.Canvas.Pixels[R.Right - 12, (R.Top + R.Bottom) div 2]), 'Menue-Flaeche');
      R := W.ItemRect(1);
      CheckEquals(Integer(clLime), Integer(B.Canvas.Pixels[R.Right - 12, (R.Top + R.Bottom) div 2]), 'eigenes Zeichnen');
    finally
      B.Free;
    end;
    CheckTrue(FMenuDraws >= 2);
    L.CloseAll;
  finally
    L.Free;
    FForm.Hide;
  end;
end;

{ TCustomViewTests }

function CountGreenish(C: TWinControl): Integer;
var
  B: TBitmap;
  X, Y: Integer;
  P: Cardinal;
begin
  // Kantengeglaettete Linien: kraeftig gruen statt exakt clLime
  Result := 0;
  B := TBitmap.Create;
  try
    B.PixelFormat := pf24bit;
    B.SetSize(C.Width, C.Height);
    B.Canvas.Lock;
    try
      C.PaintTo(B.Canvas.Handle, 0, 0);
    finally
      B.Canvas.Unlock;
    end;
    for Y := 0 to B.Height - 1 do
      for X := 0 to B.Width - 1 do
      begin
        P := Cardinal(ColorToRGB(B.Canvas.Pixels[X, Y]));
        if (Integer((P shr 8) and $FF) - Integer(P and $FF) > 60) and
          (Integer((P shr 8) and $FF) - Integer((P shr 16) and $FF) > 60) then
          Inc(Result);
      end;
  finally
    B.Free;
  end;
end;

function TCustomViewTests.Count(C: TWinControl; Color: TColor): Integer;
var
  B: TBitmap;
begin
  B := RenderToBitmap(C);
  try
    Result := CountColor(B, Color);
  finally
    B.Free;
  end;
end;

procedure TCustomViewTests.DrawDay(Sender: TObject; Canvas: TCanvas; ADate: TDate;
  const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
  var DefaultDraw: Boolean);
begin
  if Trunc(ADate) = Trunc(FHoliday) then
    Style.Fill := clFuchsia;
end;

procedure TCustomViewTests.DrawAppt(Sender: TObject; Canvas: TCanvas;
  Appointment: TPPGAppointment; const ARect: TRect; State: TPPGItemDrawState;
  var Style: TPPGDrawStyle; var DefaultDraw: Boolean);
begin
  Style.Fill := $00800080; // Lila: Farbstreifen
end;

procedure TCustomViewTests.DrawCard(Sender: TObject; Canvas: TCanvas;
  const Card: TPPGKanbanCardData; const ARect: TRect; State: TPPGItemDrawState;
  var Style: TPPGDrawStyle; var DefaultDraw: Boolean);
begin
  if Card.Title = 'B' then
    Style.Fill := clFuchsia;
end;

procedure TCustomViewTests.CalendarWeekendSelectedAndCustomDay;
var
  C: TPPGCalendar;
  N: Integer;
begin
  C := TPPGCalendar.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(0, 0, 300, 300);
  C.Date := EncodeDate(2026, 10, 14);
  N := Count(C, clYellow);
  C.CalendarStyles.Weekend.Color := clYellow;
  CheckTrue(Count(C, clYellow) > N + 200, 'Wochenende');
  C.CalendarStyles.Selected.Color := clLime;
  CheckTrue(Count(C, clLime) > 100, 'Auswahl');
  FHoliday := EncodeDate(2026, 10, 15);
  C.OnCustomDrawDay := DrawDay;
  CheckTrue(Count(C, clFuchsia) > 100, 'Feiertag');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomViewTests.DatePickerStreamsCalendarStyles;
var
  D: TPPGDatePicker;
  S: string;
begin
  D := TPPGDatePicker.Create(nil);
  try
    D.CalendarStyles.Today.BorderColor := clRed;
    S := ComponentToText(D);
    CheckTrue(Pos('CalendarStyles.Today.BorderColor = clRed', S) > 0, S);
  finally
    D.Free;
  end;
end;

procedure TCustomViewTests.PlannerCategoryColorAndStyles;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
begin
  P := TPPGPlanner.Create(FForm);
  P.Parent := FForm;
  P.SetBounds(0, 0, 380, 280);
  P.View := pvDay;
  P.Date := EncodeDate(2026, 10, 14);
  P.DayStartHour := 8;
  P.DayEndHour := 12;
  P.Categories.AddCategory('Kunde', $00008000);
  A := P.Appointments.Add;
  A.StartTime := EncodeDateTime(2026, 10, 14, 9, 0, 0, 0);
  A.FinishTime := EncodeDateTime(2026, 10, 14, 10, 0, 0, 0);
  A.Subject := 'Termin';
  A.Category := 0;
  CheckTrue(Count(P, $00008000) > 20, 'Kategoriefarbe als Streifen');
  P.PlannerStyles.NonWorkHours.Color := clYellow;
  P.WorkStart := 9 * 60;
  CheckTrue(Count(P, clYellow) > 200, 'Ausserhalb der Arbeitszeit');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomViewTests.PlannerCustomDrawAppointment;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
begin
  P := TPPGPlanner.Create(FForm);
  P.Parent := FForm;
  P.SetBounds(0, 0, 380, 280);
  P.View := pvDay;
  P.Date := EncodeDate(2026, 10, 14);
  P.DayStartHour := 8;
  P.DayEndHour := 12;
  A := P.Appointments.Add;
  A.StartTime := EncodeDateTime(2026, 10, 14, 9, 0, 0, 0);
  A.FinishTime := EncodeDateTime(2026, 10, 14, 10, 0, 0, 0);
  A.Subject := 'Termin';
  P.OnCustomDrawAppointment := DrawAppt;
  CheckTrue(Count(P, $00800080) > 20, 'Fill aus OnCustomDrawAppointment');
end;

procedure TCustomViewTests.KanbanStylesAndCustomDrawCard;
var
  K: TPPGKanban;
  Col: TPPGKanbanColumn;
  Card: TPPGKanbanCard;
begin
  K := TPPGKanban.Create(FForm);
  K.Parent := FForm;
  K.SetBounds(0, 0, 400, 300);
  Col := K.Columns.Add;
  Col.Title := 'Offen';
  Card := K.Cards.Add;
  Card.Title := 'A';
  Card.ColumnId := Col.Id;
  Card := K.Cards.Add;
  Card.Title := 'B';
  Card.ColumnId := Col.Id;
  K.KanbanStyles.Column.Color := clYellow;
  K.KanbanStyles.Card.Color := clAqua;
  CheckTrue(Count(K, clYellow) > 500, 'Spaltenflaeche');
  CheckTrue(Count(K, clAqua) > 500, 'Kartenflaeche');
  K.OnCustomDrawCard := DrawCard;
  CheckTrue(Count(K, clFuchsia) > 300, 'OnCustomDrawCard');
end;

procedure TCustomViewTests.ChartTitleGridAndLegendStyles;
var
  C: TPPGChart;
  S: TPPGChartSeries;
begin
  C := TPPGChart.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(0, 0, 400, 260);
  C.Animation.Enabled := False;
  C.Title := 'Umsatz';
  S := C.Series.Add;
  S.Title := 'Serie';
  S.ValuesText := '1;5;3;8';
  C.ChartStyles.Title.TextColor := clRed;
  C.ChartStyles.Title.Font.Size := 20;
  C.ChartStyles.Grid.Color := clLime;
  C.ChartStyles.Legend.TextColor := clBlue;
  CheckTrue(Count(C, clRed) > 50, 'Titelfarbe');
  CheckTrue(CountGreenish(C) > 50, 'Gitterlinien (geglaettet)');
  CheckTrue(Count(C, clBlue) > 5, 'Legende');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomViewTests.ExpanderGroupBoxHeaderStyles;
var
  E: TPPGExpander;
  G: TPPGGroupBox;
  H0: Integer;
begin
  E := TPPGExpander.Create(FForm);
  E.Parent := FForm;
  E.SetBounds(0, 0, 250, 120);
  E.Caption := 'Kopf';
  E.HeaderStyle.Color := clYellow;
  CheckTrue(Count(E, clYellow) > 500, 'Kopf-Flaeche');
  H0 := E.HeaderHeight;
  E.HeaderStyle.Font.Size := 20;
  CheckTrue(E.HeaderHeight > H0, 'Kopf waechst mit der Schrift');
  G := TPPGGroupBox.Create(FForm);
  G.Parent := FForm;
  G.SetBounds(0, 130, 250, 120);
  G.Caption := 'Gruppe';
  G.CaptionStyle.Color := clAqua;
  CheckTrue(Count(G, clAqua) > 100, 'Plakette');
end;

procedure TCustomViewTests.KpiGaugeInfoBarStyles;
var
  K: TPPGKpiTile;
  I: TPPGInfoBar;
  G: TPPGGauge;
begin
  K := TPPGKpiTile.Create(FForm);
  K.Parent := FForm;
  K.SetBounds(0, 0, 220, 120);
  K.Title := 'Umsatz';
  K.ValueText := '1234';
  K.ValueStyle.TextColor := clRed;
  CheckTrue(Count(K, clRed) > 50, 'KPI-Wert');
  G := TPPGGauge.Create(FForm);
  G.Parent := FForm;
  G.SetBounds(0, 130, 160, 160);
  G.Value := 50;
  G.ValueStyle.TextColor := clRed;
  CheckTrue(Count(G, clRed) > 30, 'Gauge-Wert');
  I := TPPGInfoBar.Create(FForm);
  I.Parent := FForm;
  I.SetBounds(0, 0, 300, 60);
  I.Message := 'Hinweis';
  I.BarStyle.Color := clYellow;
  CheckTrue(Count(I, clYellow) > 1000, 'InfoBar-Flaeche');
end;

{ TCustomButtonTests }

type
  TButtonCrack = class(TPPGButton);

procedure TCustomButtonTests.TearDown;
begin
  FreeAndNil(FImages);
  inherited TearDown;
end;

function TCustomButtonTests.MakeImages: TImageList;
var
  B, M: TBitmap;
  I: Integer;
begin
  // Zwei 16x16-Bilder mit Maske: schwarzer Kreis auf transparentem Grund
  Result := TImageList.Create(nil);
  Result.Width := 16;
  Result.Height := 16;
  for I := 0 to 1 do
  begin
    B := TBitmap.Create;
    M := TBitmap.Create;
    try
      B.SetSize(16, 16);
      B.Canvas.Brush.Color := clWhite;
      B.Canvas.FillRect(Rect(0, 0, 16, 16));
      B.Canvas.Brush.Color := clBlack;
      B.Canvas.Ellipse(1, 1, 15, 15);
      M.Monochrome := True;
      M.SetSize(16, 16);
      M.Canvas.Brush.Color := clWhite;
      M.Canvas.FillRect(Rect(0, 0, 16, 16));
      M.Canvas.Brush.Color := clBlack;
      M.Canvas.Ellipse(1, 1, 15, 15);
      Result.Add(B, M);
    finally
      M.Free;
      B.Free;
    end;
  end;
end;

function TCustomButtonTests.TextSpan(B: TBitmap; out L, R: Integer): Boolean;
var
  X, Y: Integer;
begin
  // Waagerechte Ausdehnung dunkler Pixel (Text) in der Mitte
  L := MaxInt;
  R := -1;
  for Y := 0 to B.Height - 1 do
    for X := 0 to B.Width - 1 do
      if PPGRelativeLuminance(B.Canvas.Pixels[X, Y]) < 0.2 then
      begin
        if X < L then
          L := X;
        if X > R then
          R := X;
      end;
  Result := R >= 0;
end;

procedure TCustomButtonTests.AlignmentLeftAndRight;
var
  B: TPPGButton;
  Bmp: TBitmap;
  L, R: Integer;
begin
  B := NewButton('WWW');
  B.SetBounds(0, 0, 240, 32);
  B.Font.Color := clBlack;
  B.Appearance.Normal.TextColor := clBlack;
  B.Alignment := taLeftJustify;
  Bmp := RenderToBitmap(B);
  try
    CheckTrue(TextSpan(Bmp, L, R));
    CheckTrue(R < 120, Format('links: Text endet bei %d', [R]));
  finally
    Bmp.Free;
  end;
  B.Alignment := taRightJustify;
  Bmp := RenderToBitmap(B);
  try
    CheckTrue(TextSpan(Bmp, L, R));
    CheckTrue(L > 120, Format('rechts: Text beginnt bei %d', [L]));
  finally
    Bmp.Free;
  end;
end;

procedure TCustomButtonTests.MarginMovesContent;
var
  B: TPPGButton;
  Bmp: TBitmap;
  L, R, L0: Integer;
begin
  B := NewButton('WWW');
  B.SetBounds(0, 0, 240, 32);
  B.Font.Color := clBlack;
  B.Appearance.Normal.TextColor := clBlack;
  B.Margin := 0;
  Bmp := RenderToBitmap(B);
  try
    CheckTrue(TextSpan(Bmp, L0, R));
  finally
    Bmp.Free;
  end;
  B.Margin := 60;
  Bmp := RenderToBitmap(B);
  try
    CheckTrue(TextSpan(Bmp, L, R));
    CheckTrue(L >= L0 + 50, Format('Margin 60: %d, Margin 0: %d', [L, L0]));
  finally
    Bmp.Free;
  end;
  try
    B.Margin := -2;
    Fail('EPPGPropertyError erwartet');
  except
    on E: EPPGPropertyError do
      CheckEquals(60, B.Margin);
  end;
end;

procedure TCustomButtonTests.PressedImageIndexWhenDown;
var
  B: TPPGButton;
begin
  FImages := MakeImages;
  B := NewButton('Bild');
  B.Images := FImages;
  B.ImageIndex := 0;
  B.PressedImageIndex := 1;
  CheckEquals(0, TButtonCrack(B).GetCurrentImageIndex, 'in Ruhe');
  B.GroupIndex := 1;
  B.AllowAllUp := True;
  B.Down := True;
  CheckEquals(1, TButtonCrack(B).GetCurrentImageIndex, 'eingerastet');
end;

procedure TCustomButtonTests.ImageTintUsesTextColor;
var
  B: TPPGButton;
  Bmp: TBitmap;
  N0, N1: Integer;
begin
  FImages := MakeImages;
  B := NewButton('');
  B.SetBounds(0, 0, 60, 40);
  B.Images := FImages;
  B.ImageIndex := 0;
  B.Appearance.Normal.TextColor := clRed;
  Bmp := RenderToBitmap(B);
  try
    N0 := CountColor(Bmp, clRed);
  finally
    Bmp.Free;
  end;
  B.ImageTint := itTextColor;
  Bmp := RenderToBitmap(B);
  try
    N1 := CountColor(Bmp, clRed);
  finally
    Bmp.Free;
  end;
  CheckEquals(0, N0, 'ohne Einfaerben kein Rot');
  CheckTrue(N1 > 80, Format('eingefaerbt: %d rote Pixel', [N1]));
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomButtonTests.TintedDrawKeepsShape;
var
  Bmp: TBitmap;
begin
  FImages := MakeImages;
  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf24bit;
    Bmp.SetSize(20, 20);
    Bmp.Canvas.Brush.Color := clWhite;
    Bmp.Canvas.FillRect(Rect(0, 0, 20, 20));
    PPGGdiDrawImageTinted(Bmp.Canvas.Handle, FImages, 0, 2, 2, clBlue);
    CheckEquals(Integer(clBlue), Integer(Bmp.Canvas.Pixels[10, 10]), 'Mitte eingefaerbt');
    CheckEquals(Integer(clWhite), Integer(Bmp.Canvas.Pixels[2, 2]), 'Ecke bleibt durchsichtig');
  finally
    Bmp.Free;
  end;
end;

procedure TCustomButtonTests.NewButtonPropertiesStream;
var
  B: TPPGButton;
  S: string;
begin
  B := TPPGButton.Create(nil);
  try
    S := ComponentToText(B);
    CheckEquals(0, Pos('Margin', S));
    CheckEquals(0, Pos('Alignment', S));
    CheckEquals(0, Pos('ImageTint', S));
    CheckEquals(0, Pos('PressedImageIndex', S));
    B.Alignment := taLeftJustify;
    B.Margin := 8;
    B.ImageTint := itTextColor;
    B.PressedImageIndex := 3;
    S := ComponentToText(B);
    CheckTrue(Pos('Alignment = taLeftJustify', S) > 0, S);
    CheckTrue(Pos('Margin = 8', S) > 0, S);
    CheckTrue(Pos('ImageTint = itTextColor', S) > 0, S);
    CheckTrue(Pos('PressedImageIndex = 3', S) > 0, S);
  finally
    B.Free;
  end;
end;

{ TCustomRestTests }

procedure TCustomRestTests.KanbanLayoutRoundTrip;
var
  K: TPPGKanban;
  C1, C2: TPPGKanbanColumn;
  L: TPPGKanbanLane;
  S: string;
begin
  K := TPPGKanban.Create(FForm);
  K.Parent := FForm;
  K.SetBounds(0, 0, 900, 400);
  C1 := K.Columns.AddColumn('Offen');
  C2 := K.Columns.AddColumn('Fertig');
  L := K.Lanes.AddLane('Team');
  C1.Width := 300;
  C2.Collapsed := True;
  L.Collapsed := True;
  S := K.SaveLayout;
  CheckTrue(Pos('[PPGKanbanLayout]', S) = 1, S);
  C1.Width := 0;
  C2.Collapsed := False;
  L.Collapsed := False;
  K.LoadLayout(S);
  CheckEquals(300, C1.Width, 'Breite');
  CheckTrue(C2.Collapsed, 'Spalte eingeklappt');
  CheckTrue(L.Collapsed, 'Swimlane eingeklappt');
  // Fremder Text: nichts aendern
  K.LoadLayout('[PPGGridLayout]'#13#10'Column.1=500,0');
  CheckEquals(300, C1.Width, 'fremdes Layout');
  // Unbekannte Ids, kaputte und ungueltige Werte werden uebergangen
  K.LoadLayout('[PPGKanbanLayout]'#13#10'Column.999=200,1'#13#10'Column.x=1'#13#10 +
    'Column.' + IntToStr(C1.Id) + '=5,0'#13#10'Lane.' + IntToStr(L.Id) + '=0');
  CheckEquals(300, C1.Width, 'Breite 5 ungueltig');
  CheckFalse(L.Collapsed, 'Swimlane aufgeklappt');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomRestTests.PlannerLayoutRoundTrip;
var
  P: TPPGPlanner;
  S: string;
begin
  P := TPPGPlanner.Create(FForm);
  P.Parent := FForm;
  P.View := pvDay;
  P.DayCount := 3;
  P.SlotMinutes := 15;
  P.SlotHeight := 30;
  P.GroupByResource := False;
  P.AgendaDays := 21;
  S := P.SaveLayout;
  P.View := pvMonth;
  P.DayCount := 1;
  P.SlotMinutes := 30;
  P.SlotHeight := 22;
  P.GroupByResource := True;
  P.AgendaDays := 14;
  P.LoadLayout(S);
  CheckTrue(P.View = pvDay, 'Ansicht');
  CheckEquals(3, P.DayCount);
  CheckEquals(15, P.SlotMinutes);
  CheckEquals(30, P.SlotHeight);
  CheckFalse(P.GroupByResource);
  CheckEquals(21, P.AgendaDays);
  // Ungueltige Werte einzeln uebergehen, gueltige trotzdem uebernehmen
  P.LoadLayout('[PPGPlannerLayout]'#13#10'DayCount=99'#13#10'View=pvQuatsch'#13#10 +
    'SlotMinutes=7'#13#10'SlotHeight=40');
  CheckEquals(3, P.DayCount, 'DayCount 99');
  CheckTrue(P.View = pvDay, 'unbekannte Ansicht');
  CheckEquals(15, P.SlotMinutes, 'SlotMinutes 7');
  CheckEquals(40, P.SlotHeight, 'gueltiger Wert danach');
  P.LoadLayout('irgendwas');
  CheckEquals(40, P.SlotHeight, 'fremder Text');
end;

procedure TCustomRestTests.RibbonQuickAccessRoundTrip;
var
  R: TPPGRibbon;
  G: TPPGRibbonGroup;
  A, B, C: TPPGRibbonItem;
  S: string;
  N0: Integer;
begin
  R := TPPGRibbon.Create(FForm);
  R.Parent := FForm;
  G := R.Tabs.AddTab('Start').Groups.AddGroup('Ablage');
  A := G.Items.AddButton('Eins', $E77F, rsLarge);
  B := G.Items.AddButton('Zwei', $E8C6, rsMedium);
  C := G.Items.AddButton('Drei', $E8C8, rsMedium);
  N0 := R.QuickAccess.Count;
  R.AddToQuickAccess(C);
  R.AddToQuickAccess(A);
  S := R.SaveQuickAccess;
  while R.QuickAccess.Count > 0 do
    R.RemoveFromQuickAccess(0);
  R.AddToQuickAccess(B);
  // Band umgebaut: "Eins" steht jetzt an anderer Stelle
  A.Index := 2;
  R.LoadQuickAccess(S);
  CheckEquals(N0 + 2, R.QuickAccess.Count, S);
  CheckEquals('Drei', R.QuickAccess[N0].Caption);
  CheckEquals('Eins', R.QuickAccess[N0 + 1].Caption);
  CheckTrue(R.QuickSource(R.QuickAccess[N0 + 1]) = A, 'wirkt auf das Item im Band');
  // Fremder Text aendert nichts, Unbekanntes faellt weg
  R.LoadQuickAccess('abc');
  CheckEquals(N0 + 2, R.QuickAccess.Count, 'fremder Text');
  R.LoadQuickAccess('[PPGRibbonQuickAccess]'#13#10'Item=9,9,9,Gibt es nicht'#13#10'Action=Nix');
  CheckEquals(0, R.QuickAccess.Count, 'nur Unbekanntes');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomRestTests.KanbanPrinterPagesAndContent;
var
  Png: TPngImage;
  K: TPPGKanban;
  Prn: TPPGKanbanPrinter;
  D: TPPGPrintDevice;
  B: TBitmap;
  I, X, Y, Dark, N1, N2: Integer;
begin
  K := TPPGKanban.Create(FForm);
  K.Parent := FForm;
  K.SetBounds(0, 0, 800, 400);
  for I := 1 to 8 do
    K.Columns.AddColumn('Spalte ' + IntToStr(I));
  for I := 1 to 30 do
    K.Cards.AddCard(K.Columns[0].Id, 'Karte ' + IntToStr(I));
  Prn := TPPGKanbanPrinter.Create(FForm);
  Prn.Kanban := K;
  D := TPPGPrintDevice.A4(96, False);
  CheckTrue(Prn.FitToPageWidth, 'Vorgabe');
  N1 := Prn.PageCount(D);
  Prn.FitToPageWidth := False;
  N2 := Prn.PageCount(D);
  CheckTrue(N1 >= 1, 'Seiten: ' + IntToStr(N1));
  CheckTrue(N2 > N1, Format('nebeneinander mehr Seiten: %d / %d', [N1, N2]));
  Prn.FitToPageWidth := True;
  B := TBitmap.Create;
  try
    B.PixelFormat := pf24bit;
    B.SetSize(D.PageWidth, D.PageHeight);
    B.Canvas.Brush.Color := clWhite;
    B.Canvas.FillRect(Rect(0, 0, B.Width, B.Height));
    Prn.RenderPage(0, B.Canvas.Handle, D);
    CheckEquals(0, FErrors.Count, FErrors.Text);
    Dark := 0;
    for Y := 0 to B.Height div 8 - 1 do
      for X := 0 to B.Width div 8 - 1 do
        if GetRValue(B.Canvas.Pixels[X * 8, Y * 8]) < 250 then
          Inc(Dark);
    if GetEnvironmentVariable('PPG_SHOTS') <> '' then
    begin
      Png := TPngImage.Create;
      try
        Png.Assign(B);
        Png.SaveToFile(IncludeTrailingPathDelimiter(GetEnvironmentVariable('PPG_SHOTS')) +
          'kanban-print.png');
      finally
        Png.Free;
      end;
    end;
    CheckEquals(1, N1, 'auf Seitenbreite: eine Seite');
    CheckTrue(Dark > 500, 'Inhalt gezeichnet: ' + IntToStr(Dark));
  finally
    B.Free;
  end;
  K.Free;
  CheckNull(Prn.Kanban, 'Freigabe gemeldet');
  CheckEquals(0, Prn.PageCount(D));
end;

procedure TCustomRestTests.ReadOnlyStyleColorsField;
var
  E: TPPGEdit;
  Bmp: TBitmap;
  N0, N1: Integer;
  S: string;
begin
  E := TPPGEdit.Create(FForm);
  E.Parent := FForm;
  E.SetBounds(0, 0, 160, 32);
  E.ReadOnlyStyle.Color := clYellow;
  Bmp := RenderToBitmap(E);
  try
    N0 := CountColor(Bmp, clYellow);
  finally
    Bmp.Free;
  end;
  E.ReadOnly := True;
  Bmp := RenderToBitmap(E);
  try
    N1 := CountColor(Bmp, clYellow);
  finally
    Bmp.Free;
  end;
  CheckEquals(0, N0, 'bearbeitbar: normale Farbe');
  CheckTrue(N1 > 500, 'ReadOnly: gelb ' + IntToStr(N1));
  S := ComponentToText(E);
  CheckTrue(Pos('ReadOnlyStyle.Color = clYellow', S) > 0, S);
  E.ReadOnlyStyle.Clear;
  CheckEquals(0, Pos('ReadOnlyStyle', ComponentToText(E)), 'leer: nicht gespeichert');
end;

procedure TCustomRestTests.TouchAndGesturePublished;
const
  Classes: array[0..5] of TClass = (TPPGButton, TPPGEdit, TPPGGrid, TPPGListBox, TPPGKanban, TPPGPanel);
var
  I: Integer;
begin
  for I := 0 to High(Classes) do
  begin
    CheckTrue(GetPropInfo(Classes[I], 'Touch') <> nil, Classes[I].ClassName + '.Touch');
    CheckTrue(GetPropInfo(Classes[I], 'OnGesture') <> nil, Classes[I].ClassName + '.OnGesture');
  end;
end;

function TCustomRestTests.CornerPixels(const Canvas: IPPGCanvas; B: TBitmap; Frame: Boolean): string;
var
  Old: TPPGCorners;

  function P(X, Y: Integer): Char;
  begin
    if B.Canvas.Pixels[X, Y] = clRed then
      Result := 'R'
    else
      Result := '.';
  end;

begin
  B.Canvas.Brush.Color := clWhite;
  B.Canvas.FillRect(Rect(0, 0, 40, 40));
  Old := PPGSetSquareCorners(Canvas, [pcTopLeft, pcBottomRight]);
  try
    if Frame then
      Canvas.FrameRoundRect(Rect(0, 0, 40, 40), 12, 2, clRed, 255)
    else
      Canvas.FillRoundRect(Rect(0, 0, 40, 40), 12, clRed, 255);
  finally
    PPGSetSquareCorners(Canvas, Old);
  end;
  // Ecken: oben links, oben rechts, unten rechts, unten links
  Result := P(0, 0) + P(39, 0) + P(39, 39) + P(0, 39);
  CheckTrue(PPGSetSquareCorners(Canvas, []) = [], 'zurueckgesetzt');
end;

procedure TCustomRestTests.SquareCornersOnBothCanvases;
var
  B: TBitmap;
  C: IPPGCanvas;
begin
  B := TBitmap.Create;
  try
    B.PixelFormat := pf24bit;
    B.SetSize(40, 40);
    C := TPPGGdiCanvas.Create(B.Canvas.Handle);
    CheckEquals('R.R.', CornerPixels(C, B, False), 'GDI fuellen');
    CheckEquals('R.R.', CornerPixels(C, B, True), 'GDI Rahmen');
    CheckTrue(B.Canvas.Pixels[1, 20] = clRed, 'GDI Rahmen links');
    CheckTrue(B.Canvas.Pixels[20, 20] = clWhite, 'GDI Rahmen innen leer');
    C := nil;
    C := TPPGGdiPlusCanvas.Create(B.Canvas.Handle);
    CheckEquals('R.R.', CornerPixels(C, B, False), 'GDI+ fuellen');
    C := nil;
  finally
    B.Free;
  end;
end;

procedure TCustomRestTests.ButtonRoundedCorners;
var
  Btn: TPPGButton;
  Bmp: TBitmap;
  Body: TRect;
  Rounded, Square: TColor;
begin
  Btn := NewButton('');
  Btn.SetBounds(0, 0, 120, 48);
  Btn.Appearance.Rounding := 14;
  Btn.Appearance.Normal.Color := clRed;
  Btn.Appearance.Normal.ColorTo := clRed;
  Btn.Appearance.Normal.ColorMirror := clRed;
  Btn.Appearance.Normal.ColorMirrorTo := clRed;
  Btn.Appearance.Normal.BorderColor := clRed;
  Body := TButtonCrack(Btn).LayoutBodyRect;
  Bmp := RenderToBitmap(Btn);
  try
    Rounded := Bmp.Canvas.Pixels[Body.Left + 1, Body.Top + 1];
  finally
    Bmp.Free;
  end;
  Btn.RoundedCorners := [pcTopRight, pcBottomRight];
  Bmp := RenderToBitmap(Btn);
  try
    Square := Bmp.Canvas.Pixels[Body.Left + 1, Body.Top + 1];
    CheckTrue(Bmp.Canvas.Pixels[Body.Right - 2, Body.Top + 1] <> clRed, 'rechts oben bleibt rund');
  finally
    Bmp.Free;
  end;
  CheckTrue(Rounded <> clRed, 'rund: Ecke frei');
  CheckEquals(Integer(clRed), Integer(Square), 'eckig: Ecke gefuellt');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomRestTests.ShadowShrinksBodyAndDarkens;
var
  Btn: TPPGButton;
  Bmp: TBitmap;
  B0, B1: TRect;
  L0, L1: Single;
begin
  Btn := NewButton('');
  Btn.SetBounds(0, 0, 120, 50);
  B0 := TButtonCrack(Btn).LayoutBodyRect;
  Btn.Shadow.Size := 6;
  Btn.Shadow.OffsetY := 2;
  Btn.Shadow.Opacity := 200;
  B1 := TButtonCrack(Btn).LayoutBodyRect;
  CheckTrue(B1.Bottom <= Btn.Height - 8, Format('unten Platz: %d', [B1.Bottom]));
  CheckTrue(B1.Left >= 6, Format('links Platz: %d', [B1.Left]));
  CheckTrue(B1.Bottom < B0.Bottom, 'Flaeche kleiner');
  Bmp := RenderToBitmap(Btn);
  try
    L0 := PPGRelativeLuminance(Bmp.Canvas.Pixels[0, 0]);
    L1 := PPGRelativeLuminance(Bmp.Canvas.Pixels[60, B1.Bottom + 1]);
  finally
    Bmp.Free;
  end;
  CheckTrue(L1 < L0 - 0.1, Format('Schatten dunkler: %.2f / %.2f', [L1, L0]));
  try
    Btn.Shadow.Size := 65;
    Fail('EPPGPropertyError erwartet');
  except
    on E: EPPGPropertyError do
      CheckEquals(6, Btn.Shadow.Size);
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomRestTests.PanelShadowKeepsChildrenInside;
var
  P: TPPGPanel;
  C: TPPGButton;
  L0: Integer;
begin
  P := TPPGPanel.Create(FForm);
  P.Parent := FForm;
  P.SetBounds(0, 0, 200, 120);
  P.HandleNeeded;
  C := TPPGButton.Create(FForm);
  C.Parent := P;
  C.Align := alClient;
  L0 := C.Left;
  P.Shadow.Size := 8;
  CheckEquals(L0 + 8, C.Left, 'links eingerueckt');
  CheckTrue(C.Top + C.Height <= P.Height - 10, 'unten eingerueckt');
  P.Shadow.Size := 0;
  CheckEquals(L0, C.Left, 'ohne Schatten wie vorher');
end;

procedure TCustomRestTests.CornersAndShadowStream;
var
  B, B2: TPPGButton;
  S: string;
begin
  B := TPPGButton.Create(nil);
  try
    S := ComponentToText(B);
    CheckEquals(0, Pos('RoundedCorners', S));
    CheckEquals(0, Pos('Shadow', S));
    B.RoundedCorners := [pcTopLeft, pcBottomLeft];
    B.Shadow.Size := 4;
    B.Shadow.Color := clNavy;
    S := ComponentToText(B);
    CheckTrue(Pos('RoundedCorners = [pcTopLeft, pcBottomLeft]', S) > 0, S);
    CheckTrue(Pos('Shadow.Size = 4', S) > 0, S);
    B2 := TPPGButton.Create(nil);
    TextToComponent(S, B2);
    try
      CheckTrue(B2.RoundedCorners = [pcTopLeft, pcBottomLeft]);
      CheckEquals(4, B2.Shadow.Size);
      CheckEquals(Integer(clNavy), Integer(B2.Shadow.Color));
      CheckEquals(2, B2.Shadow.OffsetY, 'Vorgabe');
    finally
      B2.Free;
    end;
  finally
    B.Free;
  end;
end;

{ TCustomVclPropTests }

type
  TListAccess = class(TPPGListBox);
  TDateAccess = class(TPPGDatePicker);

procedure TCustomVclPropTests.Shot(C: TWinControl; const Name: string);
var
  B: TBitmap;
  Png: TPngImage;
begin
  // Bild fuer die Sichtpruefung (nur mit PPG_SHOTS)
  if GetEnvironmentVariable('PPG_SHOTS') = '' then
    Exit;
  B := RenderToBitmap(C);
  Png := TPngImage.Create;
  try
    Png.Assign(B);
    Png.SaveToFile(IncludeTrailingPathDelimiter(GetEnvironmentVariable('PPG_SHOTS')) + Name + '.png');
  finally
    Png.Free;
    B.Free;
  end;
end;

function TCustomVclPropTests.NewList(N: Integer): TPPGListBox;
var
  I: Integer;
begin
  Result := TPPGListBox.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 300, 120);
  for I := 0 to N - 1 do
    Result.Items.Add('Eintrag ' + IntToStr(I));
  Result.HandleNeeded;
end;

procedure TCustomVclPropTests.ListBoxColumnsArrangeAndNavigate;
var
  L: TPPGListBox;
  R0, R: TRect;
  J: Integer;
  Key: Word;
begin
  L := NewList(30);
  L.Columns := 3;
  Shot(L, 'vcl-list-columns');
  R0 := L.ItemRect(0);
  J := 1;
  while (J < 30) and (L.ItemRect(J).Left = R0.Left) do
    Inc(J);
  CheckTrue((J > 1) and (J < 30), 'zweite Spalte ab Eintrag ' + IntToStr(J));
  R := L.ItemRect(J);
  CheckEquals(R0.Top, R.Top, 'neue Spalte beginnt oben');
  CheckTrue(R.Left - R0.Left >= (R0.Right - R0.Left) - 2, 'Spalten nebeneinander');
  CheckEquals(J, L.ItemAtPos((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
  L.ItemIndex := 0;
  Key := VK_RIGHT;
  TListAccess(L).KeyDown(Key, []);
  CheckEquals(J, L.ItemIndex, 'Pfeil rechts = eine Spalte weiter');
  Key := VK_LEFT;
  TListAccess(L).KeyDown(Key, []);
  CheckEquals(0, L.ItemIndex, 'Pfeil links zurueck');
  try
    L.Columns := -1;
    Fail('EPPGPropertyError erwartet');
  except
    on E: EPPGPropertyError do
      CheckEquals(3, L.Columns);
  end;
  L.Columns := 0;
  CheckEquals(L.ItemRect(0).Top + (L.ItemRect(0).Bottom - L.ItemRect(0).Top), L.ItemRect(1).Top,
    'wieder einspaltig');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomVclPropTests.ListBoxScrollWidthWidensRows;
var
  L: TPPGListBox;
  W0: Integer;
begin
  L := NewList(5);
  L.Width := 150;
  W0 := L.ItemRect(0).Right - L.ItemRect(0).Left;
  L.ScrollWidth := 500;
  CheckTrue(L.ItemRect(0).Right - L.ItemRect(0).Left >= 500,
    Format('Zeile so breit wie ScrollWidth: %d (vorher %d)', [L.ItemRect(0).Right - L.ItemRect(0).Left, W0]));
  CheckTrue(L.ContentWidth >= 500, 'waagerechter Bildlauf');
  L.ScrollWidth := 0;
  CheckEquals(W0, L.ItemRect(0).Right - L.ItemRect(0).Left, 'ohne ScrollWidth');
end;

procedure TCustomVclPropTests.ListBoxIntegralHeightSnaps;
var
  L: TPPGListBox;
  RowH, Frame: Integer;
begin
  L := NewList(20);
  RowH := TListAccess(L).DefaultItemHeight;
  Frame := 2 * TListAccess(L).FrameInset;
  L.IntegralHeight := True;
  L.Height := 5 * RowH + Frame + RowH div 2;
  CheckEquals(5 * RowH + Frame, L.Height, 'auf ganze Zeilen gerundet');
  L.Height := 10;
  CheckEquals(RowH + Frame, L.Height, 'mindestens eine Zeile');
  L.IntegralHeight := False;
  L.Height := 5 * RowH + Frame + RowH div 2;
  CheckEquals(5 * RowH + Frame + RowH div 2, L.Height, 'ohne IntegralHeight frei');
end;

procedure TCustomVclPropTests.ListBoxTabWidthExpandsTabs;
var
  L: TPPGListBox;
  B0, B1: TBitmap;

  function RightmostDark(B: TBitmap): Integer;
  var
    X, Y: Integer;
  begin
    Result := -1;
    for Y := 0 to 30 do
      for X := 0 to B.Width - 1 do
        if PPGRelativeLuminance(B.Canvas.Pixels[X, Y]) < 0.3 then
          if X > Result then
            Result := X;
  end;

begin
  L := NewList(0);
  L.Items.Add('A'#9'B');
  B0 := RenderToBitmap(L);
  L.TabWidth := 120;
  B1 := RenderToBitmap(L);
  try
    CheckTrue(RightmostDark(B1) > RightmostDark(B0) + 20,
      Format('B rueckt an den Tabstopp: %d / %d', [RightmostDark(B1), RightmostDark(B0)]));
  finally
    B0.Free;
    B1.Free;
  end;
  CheckTrue(TPPGItemPainter.TabUnitsToPixels(L.Font, 32) > 0);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomVclPropTests.CheckListBoxHeaderColorsAndFlat;
var
  C: TPPGCheckListBox;
  B: TBitmap;
  N0, N1: Integer;
  S: string;
begin
  C := TPPGCheckListBox.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(0, 0, 220, 120);
  C.Items.Add('Gruppe');
  C.Items.Add('Eins');
  C.Header[0] := True;
  C.HandleNeeded;
  B := RenderToBitmap(C);
  try
    N0 := CountColor(B, clYellow);
  finally
    B.Free;
  end;
  C.HeaderBackgroundColor := clYellow;
  B := RenderToBitmap(C);
  try
    N1 := CountColor(B, clYellow);
  finally
    B.Free;
  end;
  CheckEquals(0, N0, 'Vorgabe: Preset-Optik');
  CheckTrue(N1 > 300, 'Ueberschrift gelb: ' + IntToStr(N1));
  // GroupHeader hat Vorrang
  C.Styles.GroupHeader.Color := clAqua;
  B := RenderToBitmap(C);
  try
    CheckEquals(0, CountColor(B, clYellow), 'Styles.GroupHeader gewinnt');
  finally
    B.Free;
  end;
  C.Flat := False;
  Shot(C, 'vcl-checklist-native');
  B := RenderToBitmap(C);
  B.Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
  S := ComponentToText(C);
  CheckTrue(Pos('Flat = False', S) > 0, S);
  CheckTrue(Pos('HeaderBackgroundColor = clYellow', S) > 0, S);
end;

procedure TCustomVclPropTests.TreeViewRowSelectFalseHighlightsText;
var
  T: TPPGTreeView;
  R: TRect;
  B: TBitmap;
  Full, TextOnly: Integer;

  function LimeAt(X, Y: Integer): Boolean;
  begin
    Result := B.Canvas.Pixels[X, Y] = clLime;
  end;

begin
  T := TPPGTreeView.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(0, 0, 300, 120);
  T.Items.Add(nil, 'Knoten');
  T.HandleNeeded;
  T.Styles.Selection.Color := clLime;
  T.Styles.SelectionInactive.Color := clLime;
  T.Selected := T.Items[0];
  R := T.ItemRect(0);
  B := RenderToBitmap(T);
  try
    Full := Ord(LimeAt(R.Right - 12, (R.Top + R.Bottom) div 2));
  finally
    B.Free;
  end;
  T.RowSelect := False;
  B := RenderToBitmap(T);
  try
    TextOnly := Ord(LimeAt(R.Right - 12, (R.Top + R.Bottom) div 2));
    if GetEnvironmentVariable('PPG_SHOTS') <> '' then
      B.SaveToFile(IncludeTrailingPathDelimiter(GetEnvironmentVariable('PPG_SHOTS')) + 'tree-rowselect.bmp');
    CheckTrue(CountColor(B, clLime) > 100, 'Text weiter hervorgehoben: ' + IntToStr(CountColor(B, clLime)));
  finally
    B.Free;
  end;
  CheckEquals(1, Full, 'RowSelect: ganze Zeile');
  CheckEquals(0, TextOnly, 'ohne RowSelect: rechts frei');
end;

procedure TCustomVclPropTests.ProgressBarSmoothFalseDrawsBlocks;
var
  P: TPPGProgressBar;
  B: TBitmap;
  Y, Changes0, Changes1: Integer;

  function CountChanges(Bmp: TBitmap): Integer;
  var
    C, Last: TColor;
    X: Integer;
  begin
    Result := 0;
    Last := Bmp.Canvas.Pixels[0, Y];
    for X := 1 to Bmp.Width - 1 do
    begin
      C := Bmp.Canvas.Pixels[X, Y];
      if C <> Last then
        Inc(Result);
      Last := C;
    end;
  end;

begin
  P := TPPGProgressBar.Create(FForm);
  P.Parent := FForm;
  P.SetBounds(0, 0, 300, 20);
  P.Animation.Enabled := False;
  P.Position := 80;
  CheckTrue(P.Smooth, 'Vorgabe glatt');
  CheckEquals(0, Pos('Smooth', ComponentToText(P)));
  Y := 10;
  B := RenderToBitmap(P);
  try
    Changes0 := CountChanges(B);
  finally
    B.Free;
  end;
  P.Smooth := False;
  Shot(P, 'vcl-progress-blocks');
  B := RenderToBitmap(P);
  try
    Changes1 := CountChanges(B);
  finally
    B.Free;
  end;
  CheckTrue(Changes1 > Changes0 + 10, Format('Bloecke: %d / %d Farbwechsel', [Changes1, Changes0]));
  CheckTrue(Pos('Smooth = False', ComponentToText(P)) > 0);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomVclPropTests.TabsLeftAndRight;
var
  PC: TPPGPageControl;
  I: Integer;
  R0, R1: TRect;
  P: TPPGTabSheet;
begin
  PC := TPPGPageControl.Create(FForm);
  PC.Parent := FForm;
  PC.SetBounds(0, 0, 400, 240);
  for I := 0 to 2 do
  begin
    P := TPPGTabSheet.Create(FForm);
    P.PageControl := PC;
    P.Caption := 'Seite ' + IntToStr(I);
  end;
  PC.ActivePageIndex := 0;
  PC.HandleNeeded;
  PC.TabPosition := tpLeft;
  R0 := PC.TabRect(0);
  R1 := PC.TabRect(1);
  Shot(PC, 'vcl-tabs-left');
  CheckTrue(R0.Left < 20, 'links');
  CheckEquals(R0.Left, R1.Left, 'untereinander');
  CheckTrue(R1.Top >= R0.Bottom, 'zweiter Reiter darunter');
  CheckTrue(PC.ActivePage.Left >= R0.Right, 'Seite rechts der Leiste');
  CheckTrue(PC.ActivePage.Height > 150, 'Seite ueber die ganze Hoehe');
  PC.TabPosition := tpRight;
  R0 := PC.TabRect(0);
  Shot(PC, 'vcl-tabs-right');
  CheckTrue(R0.Left > 200, 'rechts');
  CheckTrue(PC.ActivePage.Left + PC.ActivePage.Width <= R0.Left, 'Seite links der Leiste');
  RenderToBitmap(PC).Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomVclPropTests.TabsScrollOpposite;
var
  T: TPPGTabControl;
  I, Bottom0, Bottom1: Integer;

  function LowestTab: Integer;
  var
    J: Integer;
  begin
    Result := 0;
    for J := 0 to T.Tabs.Count - 1 do
      if T.TabRect(J).Bottom > Result then
        Result := T.TabRect(J).Bottom;
  end;

begin
  T := TPPGTabControl.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(0, 0, 260, 260);
  for I := 0 to 11 do
    T.Tabs.Add('Reiter ' + IntToStr(I));
  T.MultiLine := True;
  T.HandleNeeded;
  T.TabIndex := 0;
  Bottom0 := LowestTab;
  CheckTrue(Bottom0 < 130, 'ohne ScrollOpposite: alle Reihen oben');
  T.ScrollOpposite := True;
  Shot(T, 'vcl-tabs-opposite');
  Bottom1 := LowestTab;
  CheckTrue(Bottom1 > 200, Format('Reihen hinter dem gewaehlten unten: %d', [Bottom1]));
  // letzte Reihe waehlen: nichts mehr auf der Gegenseite
  T.TabIndex := 11;
  CheckTrue(LowestTab < 130, 'gewaehlte Reihe an der Seite');
  RenderToBitmap(T).Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomVclPropTests.ColorPickerNoneColorColor;
var
  C: TPPGColorPicker;
  B: TBitmap;
  N0, N1: Integer;
begin
  C := TPPGColorPicker.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(0, 0, 200, 32);
  C.Selected := clNone;
  B := RenderToBitmap(C);
  try
    N0 := CountColor(B, clLime);
  finally
    B.Free;
  end;
  C.NoneColorColor := clLime;
  B := RenderToBitmap(C);
  try
    N1 := CountColor(B, clLime);
  finally
    B.Free;
  end;
  CheckEquals(0, N0);
  CheckTrue(N1 > 50, 'Feld "Keine" gefuellt: ' + IntToStr(N1));
end;

procedure TCustomVclPropTests.DatePickerTimeKind;
var
  D: TPPGDatePicker;
  Key: Word;
begin
  D := TPPGDatePicker.Create(FForm);
  D.Parent := FForm;
  D.HandleNeeded;
  D.DateTime := EncodeDateTime(2026, 10, 8, 14, 30, 0, 0);
  D.Kind := dtkTime;
  Shot(D, 'vcl-datepicker-time');
  CheckEquals(FormatDateTime(FormatSettings.LongTimeFormat, D.DateTime), D.Text, 'Uhrzeit');
  Key := VK_UP;
  TDateAccess(D).FieldKeyDown(Key, []);
  CheckEquals(EncodeDateTime(2026, 10, 8, 14, 31, 0, 0), D.DateTime, 'Minute +1');
  Key := VK_DOWN;
  TDateAccess(D).FieldKeyDown(Key, [ssCtrl]);
  CheckEquals(EncodeDateTime(2026, 10, 8, 13, 31, 0, 0), D.DateTime, 'Stunde -1');
  D.Text := '09:15:00';
  TDateAccess(D).CommitText(True);
  CheckEquals(EncodeDateTime(2026, 10, 8, 9, 15, 0, 0), D.DateTime, 'Eingabe der Uhrzeit');
  D.DropDown;
  CheckFalse(D.DroppedDown, 'kein Kalender');
  CheckTrue(Pos('Kind = dtkTime', ComponentToText(D)) > 0);
end;

procedure TCustomVclPropTests.DatePickerUpDownMode;
var
  D: TPPGDatePicker;
begin
  D := TPPGDatePicker.Create(FForm);
  D.Parent := FForm;
  D.HandleNeeded;
  D.Date := EncodeDate(2026, 10, 8);
  D.DateMode := dmUpDown;
  Shot(D, 'vcl-datepicker-updown');
  CheckTrue(IsRectEmpty(TDateAccess(D).ButtonRect(40)), 'kein Kalender-Knopf');
  CheckFalse(IsRectEmpty(TDateAccess(D).ButtonRect(42)), 'Auf-Knopf');
  TDateAccess(D).ButtonClick(42);
  CheckEquals(EncodeDate(2026, 10, 9), D.Date, 'Auf = naechster Tag');
  TDateAccess(D).ButtonClick(43);
  TDateAccess(D).ButtonClick(43);
  CheckEquals(EncodeDate(2026, 10, 7), D.Date, 'Ab = Vortag');
  D.DropDown;
  CheckFalse(D.DroppedDown, 'kein Kalender');
  RenderToBitmap(D).Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TCustomVclPropTests.UserInput(Sender: TObject; const UserString: string;
  var DateAndTime: TDateTime; var AllowChange: Boolean);
begin
  FTomorrowAsked := True;
  if SameText(UserString, 'morgen') then
    DateAndTime := Date + 1
  else
    AllowChange := False;
end;

procedure TCustomVclPropTests.DatePickerParseInput;
var
  D: TPPGDatePicker;
begin
  FTomorrowAsked := False;
  D := TPPGDatePicker.Create(FForm);
  D.Parent := FForm;
  D.HandleNeeded;
  D.Date := EncodeDate(2026, 1, 1);
  D.OnUserInput := UserInput;
  D.Text := 'morgen';
  TDateAccess(D).CommitText(True);
  CheckFalse(FTomorrowAsked, 'ohne ParseInput nicht gefragt');
  CheckEquals(EncodeDate(2026, 1, 1), D.Date);
  D.ParseInput := True;
  D.Text := 'morgen';
  CheckTrue(TDateAccess(D).CommitText(True));
  CheckTrue(FTomorrowAsked);
  CheckEquals(Date + 1, D.Date, 'eigene Auswertung');
  D.Text := 'quatsch';
  CheckFalse(TDateAccess(D).CommitText(True), 'abgelehnt');
  CheckTrue(D.ValidationState = pvsError);
end;

initialization
  RegisterTest('Anpassbarkeit', TCustomThemeTests.Suite);
  RegisterTest('Anpassbarkeit', TCustomAppearanceTests.Suite);
  RegisterTest('Anpassbarkeit', TCustomGridTests.Suite);
  RegisterTest('Anpassbarkeit', TCustomListTests.Suite);
  RegisterTest('Anpassbarkeit', TCustomBarTests.Suite);
  RegisterTest('Anpassbarkeit', TCustomViewTests.Suite);
  RegisterTest('Anpassbarkeit', TCustomButtonTests.Suite);
  RegisterTest('Anpassbarkeit', TCustomRestTests.Suite);
  RegisterTest('Anpassbarkeit', TCustomVclPropTests.Suite);

end.
