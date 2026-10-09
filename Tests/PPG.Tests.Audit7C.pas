unit PPG.Tests.Audit7C;

{ Audit-Paket 7C (Docs\Audit-Paket7-Plan.md): Regressionstests fuer
  7e #1-#6 (Farben), 7g (Appearance bei Badge, ProgressRing, Rating,
  Splitter), 7f #5 (Hints von rechts nach links) und 7e #7 (Hochkontrast
  als Token-Satz, simuliert ueber PPGSetHighContrastReader). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.TypInfo, Vcl.Controls, Vcl.Forms, Vcl.Graphics,
  PPG.Types, PPG.Tokens, PPG.Appearance, PPG.Theme, PPG.Render.Intf, PPG.Render.Registry,
  PPG.StyleManager, PPG.Controls.Base, PPG.Feedback, PPG.Rating, PPG.Splitter, PPG.Labels,
  PPG.Hints, PPG.Kanban, PPG.Kanban.Items, PPG.Planner, PPG.Planner.Model, PPG.Grid,
  PPG.Grid.Columns, PPG.Grid.Data, PPG.Grid.Export, PPG.DpiUtils, PPG.Dialogs, PPG.Button,
  PPG.Tests.Controls;

type
  TAudit7CTests = class(TControlTestCase)
  private
    FOldMode: TPPGThemeMode;
    function Shot(C: TWinControl): TBitmap;
    function NewBadge: TPPGBadge;
    function NewRing: TPPGProgressRing;
    function NewRating: TPPGRating;
    function NewSplitter: TPPGSplitter;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    { 7e #1/#2 }
    procedure ContrastTextColorHigherContrastWins;
    procedure ExportColorCellUsesSharedContrastRule;
    { 7e #3/#4 }
    procedure LinkTokenReadableInAllPresets;
    procedure LinkTokenFollowsAccentOverride;
    procedure LinkLabelAndLabelUseLinkToken;
    procedure LabelDisabledUsesTextDisabled;
    { 7e #5 }
    procedure DisabledTokensDropStrongColors;
    procedure KanbanDisabledDropsStrongColors;
    procedure PlannerDisabledDimsAppointments;
    { 7e #6 }
    procedure PlainTableLookIsSharedByHtmlAndPrint;
    { 7g }
    procedure CheckedCarriesAccentInFlatPresets;
    procedure BadgeReadsAppearance;
    procedure ProgressRingReadsAppearance;
    procedure RatingReadsAppearance;
    procedure SplitterReadsAppearance;
    procedure AppearanceChangeRepaints;
    { 7f #5 }
    procedure HintContentRightToLeft;
  end;

  /// Audit 7e #7: Hochkontrast als Token-Satz (simuliert, Systemfarben des
  /// Testrechners).
  THighContrastTokenTests = class(TControlTestCase)
  private
    FOldMode: TPPGThemeMode;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure HighContrastTokensAreSystemColors;
    procedure ControlTokensAndAppearanceFollowHighContrast;
    procedure HighContrastSupportOffKeepsPresetColors;
    procedure SwitchingHighContrastRebuildsAppearance;
    procedure LabelHonorsHighContrastSupport;
    procedure HintsHonorHighContrastSupport;
    procedure DialogPassesHighContrastSupportOn;
    procedure InfoBarLinksUseLinkToken;
    procedure PaletteControlsPaintAndAreReadable;
  end;

implementation

uses
  PPG.Tests.Audit5d;

type
  TCCV = class(TPPGCustomControl);
  TLinkAccess = class(TPPGCustomLinkLabel);

const
  Presets: array[0..2] of string = ('ModernFlat', 'Fluent11', 'Classic');

function Near(A, B: TColor; Tol: Integer = 40): Boolean;
var
  CA, CB: Cardinal;
begin
  CA := Cardinal(ColorToRGB(A));
  CB := Cardinal(ColorToRGB(B));
  Result := Abs(Integer(CA and $FF) - Integer(CB and $FF)) +
    Abs(Integer((CA shr 8) and $FF) - Integer((CB shr 8) and $FF)) +
    Abs(Integer((CA shr 16) and $FF) - Integer((CB shr 16) and $FF)) <= Tol;
end;

function Hex(C: TColor): string;
begin
  Result := '$' + IntToHex(ColorToRGB(C), 6);
end;

/// Pixel mit deutlicher Saettigung (max - min der Kanaele > 40).
function SaturatedPixels(B: TBitmap): Integer;
var
  X, Y, Mx, Mn: Integer;
  P: PByteArray;
begin
  Result := 0;
  B.PixelFormat := pf24bit;
  for Y := 0 to B.Height - 1 do
  begin
    P := B.ScanLine[Y];
    for X := 0 to B.Width - 1 do
    begin
      Mx := P[X * 3];
      Mn := P[X * 3];
      if P[X * 3 + 1] > Mx then Mx := P[X * 3 + 1];
      if P[X * 3 + 2] > Mx then Mx := P[X * 3 + 2];
      if P[X * 3 + 1] < Mn then Mn := P[X * 3 + 1];
      if P[X * 3 + 2] < Mn then Mn := P[X * 3 + 2];
      if Mx - Mn > 40 then
        Inc(Result);
    end;
  end;
end;

function DiffPixels(A, B: TBitmap): Integer;
var
  X, Y: Integer;
begin
  Result := 0;
  for Y := 0 to A.Height - 1 do
    for X := 0 to A.Width - 1 do
      if not Near(A.Canvas.Pixels[X, Y], B.Canvas.Pixels[X, Y], 30) then
        Inc(Result);
end;

{ TAudit7CTests }

procedure TAudit7CTests.SetUp;
begin
  inherited;
  FOldMode := TPPGTheme.Mode;
  TPPGTheme.Mode := tmLight;
  TPPGTokenOverrides.Clear;
end;

procedure TAudit7CTests.TearDown;
begin
  TPPGTokenOverrides.Clear;
  TPPGTheme.Mode := FOldMode;
  inherited;
end;

function TAudit7CTests.Shot(C: TWinControl): TBitmap;
begin
  Result := RenderToBitmap(C);
end;

function TAudit7CTests.NewBadge: TPPGBadge;
begin
  Result := TPPGBadge.Create(FForm);
  Result.Parent := FForm;
  Result.Value := 7;
  Result.Font.Name := 'Segoe UI';
  Result.Font.Height := -12;
  Result.HandleNeeded;
end;

function TAudit7CTests.NewRing: TPPGProgressRing;
begin
  Result := TPPGProgressRing.Create(FForm);
  Result.Parent := FForm;
  Result.Indeterminate := False;
  Result.Value := 65;
  Result.SetBounds(0, 0, 48, 48);
  Result.HandleNeeded;
end;

function TAudit7CTests.NewRating: TPPGRating;
begin
  Result := TPPGRating.Create(FForm);
  Result.Parent := FForm;
  Result.Value := 3;
  TCCV(Result).Animation.Enabled := False;
  Result.SetBounds(0, 0, 160, 32);
  Result.HandleNeeded;
end;

function TAudit7CTests.NewSplitter: TPPGSplitter;
begin
  Result := TPPGSplitter.Create(FForm);
  Result.Parent := FForm;
  Result.Align := alNone;
  Result.Beveled := True;
  TCCV(Result).Animation.Enabled := False;
  Result.SetBounds(20, 0, 8, 120);
  Result.HandleNeeded;
end;

{ ---- 7e #1/#2 ---- }

procedure TAudit7CTests.ContrastTextColorHigherContrastWins;
begin
  // Audit 09.10.2026, Paket 7e #1: eine Regel statt 6 Kopien und 8 Schwellen
  CheckEquals(clWhite, PPGContrastTextColor($00D77800), 'weiss auf #0078D7 (wie Windows)');
  CheckEquals(clWhite, PPGContrastTextColor($00B85F00), 'weiss auf #005FB8');
  CheckEquals(clBlack, PPGContrastTextColor($00FFC24C), 'schwarz auf hellem Dunkel-Akzent');
  // Rot: Schwarz hat 5,3:1, Weiss nur 4,0:1 (bisher Export/Xlsx: Weiss)
  CheckEquals(clBlack, PPGContrastTextColor($000000FF), 'schwarz auf Rot');
  CheckEquals(clBlack, PPGContrastTextColor($0000FFFF), 'schwarz auf Gelb');
  CheckEquals(clWhite, PPGContrastTextColor($00400000), 'weiss auf Dunkelblau');
  CheckEquals($00202020, PPGContrastTextColor($0000B9FF, clWhite, $00202020),
    'eigene Dunkel-Farbe');
  // Text bleibt, wenn er lesbar ist; sonst Kontrastfarbe
  CheckEquals(clWhite, PPGReadableTextColor(clWhite, $00D77800));
  CheckEquals(clWhite, PPGReadableTextColor($00202020, $00D77800),
    'dunkler Text auf Akzent (3,6:1) wird weiss');
end;

procedure TAudit7CTests.ExportColorCellUsesSharedContrastRule;
var
  G: TPPGGrid;
  Src: IPPGTableSource;
  H: string;
begin
  // Audit 7e #1: Export (bisher Leuchtdichte > 0,45) folgt der gemeinsamen Regel
  G := TPPGGrid.Create(FForm);
  G.Parent := FForm;
  G.Columns.Add.Title := 'Farbe';
  G.FixedCols := 0;
  G.RowCount := 2;
  G.Columns[0].CellKind := ckColor;
  G.Cells[0, 1] := '#FF0000';
  Supports(G, IPPGTableSource, Src);
  H := PPGExportHtmlText(Src);
  CheckTrue(Pos('color:#000000', H) > 0, 'schwarzer Text auf Rot: ' + H);
  CheckEquals(0, Pos('color:#FFFFFF', UpperCase(H)), 'kein weisser Text auf Rot');
end;

{ ---- 7e #3/#4 ---- }

procedure TAudit7CTests.LinkTokenReadableInAllPresets;
var
  I: Integer;
  Dark: Boolean;
  T: TPPGTokens;
begin
  // Audit 7e #3: Link-Token mit mindestens 4,5:1 zum Hintergrund
  for I := Low(Presets) to High(Presets) do
    for Dark := False to True do
    begin
      T := PPGPresetTokens(Presets[I], Dark);
      CheckTrue(PPGContrastRatio(T.Link, T.Background) >= 4.5,
        Format('%s dunkel=%s: Link %s auf %s nur %.2f:1', [Presets[I], System.SysUtils.BoolToStr(Dark, True),
        Hex(T.Link), Hex(T.Background), PPGContrastRatio(T.Link, T.Background)]));
      CheckEquals(T.Link, PPGGetTokenColor(T, tkLink), 'Aufzaehlung');
    end;
  // Hell bleibt der Link nahe am Akzent (nur so weit abgedunkelt wie noetig)
  T := PPGPresetTokens('Fluent11', False);
  CheckTrue(Near(T.Link, T.Accent, 60), 'Fluent11 hell: Link = Akzent');
  // StyleManager/Theme-Datei: Link ist ein ueberschreibbares Token
  CheckTrue(GetPropInfo(TPPGTokenColorSet, 'Link') <> nil, 'TPPGTokenColorSet.Link');
end;

procedure TAudit7CTests.LinkTokenFollowsAccentOverride;
var
  Dark: Boolean;
  T: TPPGTokens;
begin
  // Ein heller Markenakzent: Link wird im Hellen abgedunkelt, im Dunkeln aufgehellt
  TPPGTokenOverrides.AccentBase := $0000D7FF; // Gold
  for Dark := False to True do
  begin
    T := PPGPresetTokens('ModernFlat', Dark);
    CheckTrue(PPGContrastRatio(T.Link, T.Background) >= 4.5,
      Format('AccentBase dunkel=%s: %.2f:1', [System.SysUtils.BoolToStr(Dark, True),
      PPGContrastRatio(T.Link, T.Background)]));
  end;
  // Eigene Link-Farbe gewinnt
  TPPGTokenOverrides.Colors[False, tkLink] := $00112233;
  CheckEquals($00112233, PPGPresetTokens('ModernFlat', False).Link);
end;

procedure TAudit7CTests.LinkLabelAndLabelUseLinkToken;
var
  L: TPPGLinkLabel;
  Lb: TPPGLabel;
  T: TPPGTokens;
begin
  // Audit 7e #3: keine feste clHotLight bzw. FocusColor mehr fuer Links
  L := TPPGLinkLabel.Create(FForm);
  L.Parent := FForm;
  L.Caption := 'Siehe <a href="x">Hilfe</a>';
  L.HandleNeeded;
  T := TCCV(L).Tokens;
  CheckEquals(Hex(T.Link), Hex(TLinkAccess(L).LinkColor), 'LinkLabel: Link-Token');
  CheckTrue(PPGContrastRatio(TLinkAccess(L).LinkColor, T.Background) >= 4.5, 'lesbar');
  // Eigene Fokusfarbe bleibt die Link-Farbe (bisheriges Verhalten)
  L.Appearance.FocusColor := $00008000;
  CheckEquals(Hex($00008000), Hex(TLinkAccess(L).LinkColor), 'eigene FocusColor');
  Lb := TPPGLabel.Create(FForm);
  Lb.Parent := FForm;
  CheckEquals(Hex(PPGPresetTokens('', False).Link), Hex(Lb.LinkColor), 'Label: Link-Token');
  CheckTrue(ColorToRGB(Lb.LinkColor) <> ColorToRGB(clHotLight), 'nicht clHotLight');
end;

procedure TAudit7CTests.LabelDisabledUsesTextDisabled;
var
  Lb: TPPGLabel;
begin
  // Audit 7e #4: Tokens des Standard-Presets, deaktiviert TextDisabled statt clGrayText
  Lb := TPPGLabel.Create(FForm);
  Lb.Parent := FForm;
  Lb.Enabled := False;
  CheckEquals(Hex(PPGPresetTokens('', False).TextDisabled), Hex(Lb.TextColor), 'hell');
  TPPGTheme.Mode := tmDark;
  CheckEquals(Hex(PPGPresetTokens('', True).TextDisabled), Hex(Lb.TextColor), 'dunkel');
  Lb.Enabled := True;
  Lb.Secondary := True;
  CheckEquals(Hex(PPGPresetTokens('', True).TextSecondary), Hex(Lb.TextColor), 'Secondary');
end;

{ ---- 7e #5 ---- }

procedure TAudit7CTests.DisabledTokensDropStrongColors;
var
  T, D: TPPGTokens;
  C: TColor;
begin
  T := PPGPresetTokens('ModernFlat', False);
  D := PPGDisabledTokens(T);
  CheckEquals(Hex(T.TextDisabled), Hex(D.TextPrimary));
  CheckEquals(Hex(T.StrokeDisabled), Hex(D.Stroke));
  C := ColorToRGB(D.Accent);
  CheckEquals(C and $FF, (C shr 8) and $FF, 'Akzent grau');
  CheckEquals(C and $FF, (C shr 16) and $FF, 'Akzent grau');
  C := ColorToRGB(PPGDisabledColor($000000FF, clWhite));
  CheckEquals(C and $FF, (C shr 16) and $FF, 'Rot wird grau');
end;

procedure TAudit7CTests.KanbanDisabledDropsStrongColors;
var
  K: TPPGKanban;
  B1, B2: TBitmap;
  S1, S2: Integer;
begin
  // Audit 7e #5: Kanban blendet bei Enabled = False Karten, Akzente und Text ab
  // (Restliche gesaettigte Pixel: ClearType-Raender der Schrift)
  K := TPPGKanban.Create(FForm);
  K.Parent := FForm;
  K.SetBounds(0, 0, 640, 360);
  K.Animation.Enabled := False;
  K.Columns.AddColumn('Backlog').Color := $0000A5FF;
  K.Columns.AddColumn('Erledigt');
  K.Cards.AddCard(1, 'A1').Labels := 'Bug, UI';
  K.Cards.AddCard(1, 'A2').Assignee := 'Anna Berg';
  K.Cards.AddCard(2, 'B1').Progress := 60;
  K.Cards.AddCard(2, 'B2').Color := $00008000;
  K.HandleNeeded;
  B1 := Shot(K);
  try
    K.Enabled := False;
    B2 := Shot(K);
    try
      S1 := SaturatedPixels(B1);
      S2 := SaturatedPixels(B2);
      CheckTrue(S1 > 100, 'aktiv farbig: ' + IntToStr(S1));
      CheckTrue(S2 * 4 < S1, Format('deaktiviert ohne kraeftige Farben (%d statt %d)', [S2, S1]));
    finally
      B2.Free;
    end;
  finally
    B1.Free;
  end;
end;

procedure TAudit7CTests.PlannerDisabledDimsAppointments;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  B1, B2: TBitmap;
  S1, S2: Integer;
begin
  // Audit 7e #5: Planner blendet auch die Termin-Fuellungen ab (bisher nur Text)
  P := TPPGPlanner.Create(FForm);
  P.Parent := FForm;
  P.SetBounds(0, 0, 640, 480);
  P.Animation.Enabled := False;
  P.SmoothScrolling := False;
  P.Date := Date;
  A := P.Appointments.AddAppointment(Date + EncodeTime(9, 0, 0, 0),
    Date + EncodeTime(12, 0, 0, 0), 'Termin');
  P.HandleNeeded;
  P.SelectAppointment(A);
  B1 := Shot(P);
  try
    P.Enabled := False;
    B2 := Shot(P);
    try
      S1 := SaturatedPixels(B1);
      S2 := SaturatedPixels(B2);
      CheckTrue(S1 > 100, 'aktiv farbig: ' + IntToStr(S1));
      CheckTrue(S2 * 4 < S1, Format('deaktiviert ohne kraeftige Farben (%d statt %d)', [S2, S1]));
    finally
      B2.Free;
    end;
  finally
    B1.Free;
  end;
end;

{ ---- 7e #6 ---- }

procedure TAudit7CTests.PlainTableLookIsSharedByHtmlAndPrint;
var
  S: TPPGStringTableSource;
  Src: IPPGTableSource;
  L: TPPGTableLook;
  H: string;
begin
  // Audit 7e #6: ein schlichter Satz, eine Linienfarbe fuer Druck und HTML
  L := PPGPlainTableLook;
  CheckEquals(Hex($00F0F0F0), Hex(L.HeaderFill), 'grauer Kopf');
  CheckTrue(fsBold in L.HeaderFontStyle, 'fetter Kopf');
  CheckEquals(Hex(clBlack), Hex(L.Text));
  CheckEquals(Hex(L.Line), Hex(L.HeaderLine), 'eine Linienfarbe');
  S := TPPGStringTableSource.Create(['A']);
  Src := S;
  S.AddRow(['x']);
  H := PPGExportHtmlText(Src);
  CheckTrue(Pos(LowerCase('border:1px solid #' + IntToHex(L.Line and $FF, 2) +
    IntToHex((L.Line shr 8) and $FF, 2) + IntToHex((L.Line shr 16) and $FF, 2)), H) > 0,
    'HTML nutzt die Linienfarbe: ' + H);
  CheckTrue(Pos('th{background:#f0f0f0}', LowerCase(H)) > 0, 'Kopf wie bisher');
end;

{ ---- 7g ---- }

procedure TAudit7CTests.CheckedCarriesAccentInFlatPresets;
var
  I: Integer;
  Dark: Boolean;
  B: TPPGBadge;
  A: TPPGAppearance;
begin
  // Vorpruefung zu 7g (Entscheidung 4): in den flachen Presets ist Checked.Color
  // der Akzent (= FocusColor); Classic hat dort den goldenen An-Zustand und
  // behaelt deshalb FocusColor
  for I := Low(Presets) to High(Presets) do
    for Dark := False to True do
    begin
      if Dark then
        TPPGTheme.Mode := tmDark
      else
        TPPGTheme.Mode := tmLight;
      B := NewBadge;
      try
        B.Preset := Presets[I];
        A := TCCV(B).EffectiveAppearance;
        CheckEquals(Hex(A.FocusColor), Hex(PPGAccentColor(A)),
          Presets[I] + ' dunkel=' + System.SysUtils.BoolToStr(Dark, True) + ': Akzent = FocusColor');
        CheckEquals(I <> 2, PPGCheckedIsAccent(A), Presets[I] + ': Checked traegt den Akzent');
        if I <> 2 then
          CheckEquals(Hex(A.FocusColor), Hex(A.Checked.Color), Presets[I] + ': Checked.Color');
      finally
        B.Free;
      end;
    end;
  // Fluent11 mit Marken-/Systemakzent: Checked folgt dem Akzent
  TPPGTheme.Mode := tmLight;
  TPPGTokenOverrides.AccentBase := $00336699;
  B := NewBadge;
  try
    B.Preset := 'Fluent11';
    A := TCCV(B).EffectiveAppearance;
    CheckEquals(Hex(A.FocusColor), Hex(A.Checked.Color), 'Fluent11 mit AccentBase');
    CheckEquals(Hex(TCCV(B).Tokens.Accent), Hex(PPGAccentColor(A)));
  finally
    B.Free;
  end;
end;

procedure TAudit7CTests.BadgeReadsAppearance;
var
  B: TPPGBadge;
  Bmp: TBitmap;
  Y: Integer;
begin
  B := NewBadge;
  Y := B.Height div 2;
  Bmp := Shot(B);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[3, Y], B.Appearance.Checked.Color),
      'Standard: Akzentflaeche ' + Hex(Bmp.Canvas.Pixels[3, Y]));
    CheckFalse(Near(Bmp.Canvas.Pixels[0, 0], B.Appearance.Checked.Color), 'Pille: Ecke frei');
  finally
    Bmp.Free;
  end;
  // Flaeche aus Checked.Color
  B.Appearance.Checked.Color := clRed;
  B.Appearance.Checked.ColorTo := clRed;
  Bmp := Shot(B);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[3, Y], clRed), 'Checked.Color ' + Hex(Bmp.Canvas.Pixels[3, Y]));
  finally
    Bmp.Free;
  end;
  // Rundung 0: eckig
  B.Appearance.Rounding := 0;
  Bmp := Shot(B);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[1, 1], clRed), 'Rounding 0: Ecke gefuellt ' + Hex(Bmp.Canvas.Pixels[1, 1]));
  finally
    Bmp.Free;
  end;
  // Rahmen aus Checked.BorderColor und BorderWidth
  B.Appearance.Checked.BorderColor := clLime;
  B.Appearance.BorderWidth := 2;
  Bmp := Shot(B);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[B.Width div 2, 0], clLime), 'Rahmen oben');
    CheckTrue(Near(Bmp.Canvas.Pixels[B.Width div 2, 1], clLime), 'Rahmen 2 px');
  finally
    Bmp.Free;
  end;
  // Signalfarben bleiben Tokens
  B.Severity := bsvError;
  CheckEquals(Hex(TCCV(B).Tokens.Danger), Hex(B.FillColor), 'Fehler = Danger');
end;

procedure TAudit7CTests.ProgressRingReadsAppearance;
var
  R: TPPGProgressRing;
  Bmp: TBitmap;
begin
  R := NewRing;
  Bmp := Shot(R);
  try
    // Bogen beginnt oben (Mitte der Strichstaerke 4 px bei y = 4)
    CheckTrue(Near(Bmp.Canvas.Pixels[24, 3], R.Appearance.Checked.Color), 'Bogen = Akzent');
    CheckTrue(Near(Bmp.Canvas.Pixels[3, 24], R.Appearance.Normal.BorderColor),
      'Spur = Normal.BorderColor ' + Hex(Bmp.Canvas.Pixels[3, 24]));
  finally
    Bmp.Free;
  end;
  R.Appearance.Checked.Color := clRed;
  R.Appearance.Normal.BorderColor := clLime;
  Bmp := Shot(R);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[24, 3], clRed), 'Checked.Color');
    CheckTrue(Near(Bmp.Canvas.Pixels[3, 24], clLime), 'Normal.BorderColor');
    CheckFalse(Near(Bmp.Canvas.Pixels[24, 9], clRed), 'duenner Ring');
  finally
    Bmp.Free;
  end;
  // BorderWidth als Mindeststaerke (Thickness = 0)
  R.Appearance.BorderWidth := 10;
  Bmp := Shot(R);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[24, 8], clRed), 'BorderWidth 10: dicker Bogen');
  finally
    Bmp.Free;
  end;
end;

procedure TAudit7CTests.RatingReadsAppearance;
var
  R: TPPGRating;
  Bmp: TBitmap;
  P: TPoint;
  Fill: TColor;
begin
  R := NewRating;
  P := CenterPoint(R.StarRect(0));
  Bmp := Shot(R);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[P.X, P.Y], R.Appearance.Checked.Color),
      'Stern = Akzent ' + Hex(Bmp.Canvas.Pixels[P.X, P.Y]));
  finally
    Bmp.Free;
  end;
  R.Appearance.Checked.Color := clRed;
  Bmp := Shot(R);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[P.X, P.Y], clRed), 'Checked.Color');
  finally
    Bmp.Free;
  end;
  // StarColor geht vor
  R.StarColor := clBlue;
  Bmp := Shot(R);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[P.X, P.Y], clBlue), 'StarColor');
  finally
    Bmp.Free;
  end;
  R.StarColor := clDefault;
  // Hover-Vorschau zur Hot-Flaeche hin; IsHot wird gesetzt
  R.Appearance.Hot.Color := clBlack;
  R.Perform(WM_MOUSEMOVE, 0, MakeLParam(CenterPoint(R.StarRect(3)).X, P.Y));
  CheckTrue(TCCV(R).IsHot, 'IsHot bei Vorschau');
  Fill := PPGBlendColor(clRed, clBlack, 0.3);
  Bmp := Shot(R);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[P.X, P.Y], Fill), 'Vorschau ' + Hex(Bmp.Canvas.Pixels[P.X, P.Y]));
  finally
    Bmp.Free;
  end;
  R.Perform(CM_MOUSELEAVE, 0, 0);
  CheckFalse(TCCV(R).IsHot, 'ohne Vorschau nicht hot');
end;

procedure TAudit7CTests.SplitterReadsAppearance;
var
  S: TPPGSplitter;
  Bmp: TBitmap;
begin
  S := NewSplitter;
  // Ruhend mit Beveled: Rand in Ruhe
  S.Appearance.Normal.BorderColor := clRed;
  Bmp := Shot(S);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[4, 5], clRed), 'ruhend Normal.BorderColor ' +
      Hex(Bmp.Canvas.Pixels[4, 5]));
  finally
    Bmp.Free;
  end;
  // Hover: Hot.BorderColor, Griffpunkte Hot.TextColor; Linienbreite aus BorderWidth
  S.Appearance.Hot.BorderColor := clLime;
  S.Appearance.Hot.TextColor := clBlue;
  S.Appearance.BorderWidth := 3;
  S.Perform(CM_MOUSEENTER, 0, 0);
  Bmp := Shot(S);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[4, 5], clLime), 'Hover Hot.BorderColor ' +
      Hex(Bmp.Canvas.Pixels[4, 5]));
    CheckTrue(Near(Bmp.Canvas.Pixels[3, 5], clLime), 'Linie 3 px breit (links)');
    CheckTrue(Near(Bmp.Canvas.Pixels[5, 5], clLime), 'Linie 3 px breit (rechts)');
    CheckTrue(Near(Bmp.Canvas.Pixels[3, 60], clBlue), 'Griffpunkt Hot.TextColor ' +
      Hex(Bmp.Canvas.Pixels[3, 60]));
  finally
    Bmp.Free;
  end;
  S.Perform(CM_MOUSELEAVE, 0, 0);
end;

procedure TAudit7CTests.AppearanceChangeRepaints;
var
  Ctls: array[0..3] of TPPGCustomControl;
  I: Integer;
  R: TRect;
begin
  Ctls[0] := NewBadge;
  Ctls[1] := NewRing;
  Ctls[2] := NewRating;
  Ctls[3] := NewSplitter;
  FForm.Show;
  try
    for I := 0 to High(Ctls) do
    begin
      Ctls[I].Update;
      ValidateRect(Ctls[I].Handle, nil);
      CheckFalse(GetUpdateRect(Ctls[I].Handle, R, False), Ctls[I].ClassName + ': gezeichnet');
      TCCV(Ctls[I]).Appearance.Checked.Color := clRed;
      CheckTrue(GetUpdateRect(Ctls[I].Handle, R, False), Ctls[I].ClassName + ': neu zeichnen');
    end;
  finally
    FForm.Hide;
  end;
end;

{ ---- 7f #5 ---- }

procedure TAudit7CTests.HintContentRightToLeft;
var
  C: TPPGHintContent;
  Bmp: TBitmap;
  Sz: TSize;
  MinX, MaxX: Integer;

  procedure Ink(out AMin, AMax: Integer);
  var
    X, Y: Integer;
    Fill, Border, Txt: TColor;
  begin
    PPGHintColors('', Fill, Border, Txt);
    AMin := MaxInt;
    AMax := -1;
    for Y := 4 to Bmp.Height - 5 do
      for X := 4 to Bmp.Width - 5 do
        if Near(Bmp.Canvas.Pixels[X, Y], Txt, 120) then
        begin
          if X < AMin then
            AMin := X;
          if X > AMax then
            AMax := X;
        end;
  end;

begin
  // Audit 7f #5: bei RTL Titel und Text rechtsbuendig
  C := TPPGHintContent.Create;
  Bmp := TBitmap.Create;
  try
    C.Prepare(96, 'Titel', 'Kurzer Text', False);
    Sz := C.Measure(400);
    Bmp.PixelFormat := pf24bit;
    Bmp.SetSize(400, Sz.cy);
    C.Paint(Bmp.Canvas, Rect(0, 0, Bmp.Width, Bmp.Height), '');
    Ink(MinX, MaxX);
    CheckTrue((MinX < 20) and (MaxX < 200), Format('LTR links: %d..%d', [MinX, MaxX]));
    C.RightToLeft := True;
    C.Paint(Bmp.Canvas, Rect(0, 0, Bmp.Width, Bmp.Height), '');
    Ink(MinX, MaxX);
    CheckTrue((MinX > 200) and (MaxX > 380), Format('RTL rechts: %d..%d', [MinX, MaxX]));
  finally
    Bmp.Free;
    C.Free;
  end;
end;

{ ---- 7e #7: Hochkontrast als Token-Satz ---- }

function SimulatedHighContrast: Boolean;
begin
  Result := True;
end;

function NoHighContrast: Boolean;
begin
  Result := False;
end;

function RGBOf(C: TColor): TColor;
begin
  Result := TColor(ColorToRGB(C));
end;

procedure THighContrastTokenTests.SetUp;
begin
  inherited;
  FOldMode := TPPGTheme.Mode;
  TPPGTheme.Mode := tmLight;
  TPPGTokenOverrides.Clear;
  PPGSetHighContrastReader(SimulatedHighContrast);
end;

procedure THighContrastTokenTests.TearDown;
begin
  PPGSetHighContrastReader(nil);
  TPPGTokenOverrides.Clear;
  TPPGTheme.Mode := FOldMode;
  inherited;
end;

procedure THighContrastTokenTests.HighContrastTokensAreSystemColors;
var
  T, B: TPPGTokens;
begin
  T := PPGHighContrastTokens;
  B := PPGBaseTokens(False);
  CheckEquals(RGBOf(clHighlight), T.Accent, 'Accent');
  CheckEquals(RGBOf(clHighlight), T.AccentHover, 'AccentHover');
  CheckEquals(RGBOf(clHighlightText), T.OnAccent, 'OnAccent');
  CheckEquals(RGBOf(clWindow), T.Background, 'Background');
  CheckEquals(RGBOf(clWindow), T.Layer, 'Layer');
  CheckEquals(RGBOf(clWindow), T.Surface, 'Surface');
  CheckEquals(RGBOf(clWindow), T.SurfaceDisabled, 'SurfaceDisabled');
  CheckEquals(RGBOf(clWindowText), T.Stroke, 'Stroke');
  CheckEquals(RGBOf(clWindowText), T.TextPrimary, 'TextPrimary');
  CheckEquals(RGBOf(clWindowText), T.TextSecondary, 'TextSecondary');
  CheckEquals(RGBOf(clGrayText), T.TextDisabled, 'TextDisabled');
  CheckEquals(RGBOf(clGrayText), T.StrokeDisabled, 'StrokeDisabled');
  CheckEquals(RGBOf(clHotLight), T.Link, 'Link');
  CheckEquals(RGBOf(clHighlight), T.Danger, 'Danger');
  CheckEquals(RGBOf(clHighlight), T.Warning, 'Warning');
  CheckEquals(RGBOf(clHighlight), T.Success, 'Success');
  CheckEquals(B.RadiusMedium, T.RadiusMedium, 'Masse bleiben');
  CheckEquals(B.DurationNormal, T.DurationNormal, 'Dauern bleiben');
  // Ueberschreibungen des StyleManagers gelten im Hochkontrast nicht
  TPPGTokenOverrides.AccentBase := clRed;
  CheckEquals(RGBOf(clHighlight), PPGHighContrastTokens.Accent, 'ohne Ueberschreibungen');
end;

procedure THighContrastTokenTests.ControlTokensAndAppearanceFollowHighContrast;
var
  B: TPPGButton;
  T: TPPGTokens;
  A: TPPGAppearance;
begin
  B := NewButton('Los');
  B.Preset := 'Fluent11';
  CheckTrue(B.UseHighContrast);
  CheckFalse(B.UseOwnColors, 'eigene Farben gelten nicht');
  T := B.Tokens;
  CheckEquals(RGBOf(clHighlight), T.Accent, 'Accent');
  CheckEquals(RGBOf(clWindow), T.Surface, 'Surface');
  CheckEquals(RGBOf(clWindowText), T.TextPrimary, 'TextPrimary');
  CheckEquals(RGBOf(clHotLight), T.Link, 'Link');
  CheckEquals(PPGPresetTokens('Fluent11', False).RadiusLarge, T.RadiusLarge, 'Masse des Presets');
  A := B.EffectiveAppearance;
  CheckTrue(A <> B.Appearance, 'Kopie, die gespeicherte Appearance bleibt');
  CheckEquals(RGBOf(clBtnFace), RGBOf(A.Normal.Color), 'Normal.Color');
  CheckEquals(RGBOf(clBtnText), RGBOf(A.Normal.TextColor), 'Normal.TextColor');
  CheckEquals(RGBOf(clHighlight), RGBOf(A.Down.Color), 'Down.Color');
  CheckEquals(RGBOf(clHighlightText), RGBOf(A.Checked.TextColor), 'Checked.TextColor');
  CheckEquals(RGBOf(clHighlight), RGBOf(A.FocusColor), 'FocusColor');
  CheckEquals(B.Appearance.Rounding, A.Rounding, 'Formen bleiben');
  CheckEquals(RGBOf(clHighlight), RGBOf(B.EffectiveAppearance.FocusColor), 'zwischengespeichert');
  // Dark Mode gilt im Hochkontrast nicht
  TPPGTheme.Mode := tmDark;
  CheckFalse(B.UseDarkMode, 'kein Dark Mode im Hochkontrast');
  CheckEquals(RGBOf(clWindow), B.Tokens.Surface, 'Hochkontrast vor Dark Mode');
end;

procedure THighContrastTokenTests.HighContrastSupportOffKeepsPresetColors;
var
  B: TPPGButton;
begin
  B := NewButton('Los');
  B.HighContrastSupport := False;
  CheckFalse(B.UseHighContrast);
  CheckTrue(B.EffectiveAppearance = B.Appearance, 'Appearance unveraendert');
  CheckEquals(PPGPresetTokens(B.Preset, False).Accent, B.Tokens.Accent, 'Tokens des Presets');
  // Ohne Hochkontrast (Normalbetrieb) ebenso
  B.HighContrastSupport := True;
  PPGSetHighContrastReader(NoHighContrast);
  CheckTrue(B.EffectiveAppearance = B.Appearance, 'Normalbetrieb: Appearance selbst');
  CheckEquals(PPGPresetTokens(B.Preset, False).Accent, B.Tokens.Accent, 'Normalbetrieb: Preset');
  CheckTrue(B.UseOwnColors);
end;

procedure THighContrastTokenTests.SwitchingHighContrastRebuildsAppearance;
var
  B: TPPGButton;
begin
  B := NewButton('Los');
  CheckEquals(RGBOf(clHighlight), RGBOf(B.EffectiveAppearance.FocusColor), 'an');
  PPGSetHighContrastReader(NoHighContrast);
  CheckTrue(B.EffectiveAppearance = B.Appearance, 'aus: wieder die eigene Appearance');
  PPGSetHighContrastReader(SimulatedHighContrast);
  CheckEquals(RGBOf(clBtnFace), RGBOf(B.EffectiveAppearance.Normal.Color), 'wieder an');
  // Systemfarben geaendert (CM_SYSCOLORCHANGE): Kopie wird neu aufgebaut
  B.Perform(CM_SYSCOLORCHANGE, 0, 0);
  CheckEquals(RGBOf(clBtnFace), RGBOf(B.EffectiveAppearance.Normal.Color), 'nach Systemfarben');
end;

procedure THighContrastTokenTests.LabelHonorsHighContrastSupport;
var
  L: TPPGLabel;
  LL: TPPGLinkLabel;
begin
  L := TPPGLabel.Create(FForm);
  L.Parent := FForm;
  L.Font.Color := clRed;
  CheckTrue(L.HighContrastSupport, 'Vorgabe True');
  CheckEquals(RGBOf(clWindowText), RGBOf(L.TextColor), 'Text clWindowText');
  CheckEquals(RGBOf(clHotLight), RGBOf(L.LinkColor), 'Link clHotLight');
  L.Enabled := False;
  CheckEquals(RGBOf(clGrayText), RGBOf(L.TextColor), 'deaktiviert clGrayText');
  L.Enabled := True;
  L.HighContrastSupport := False;
  CheckEquals(RGBOf(clRed), RGBOf(L.TextColor), 'ohne HighContrastSupport: eigene Farbe');
  CheckEquals(PPGPresetTokens('', False).Link, RGBOf(L.LinkColor), 'ohne: Link-Token');
  LL := TPPGLinkLabel.Create(FForm);
  LL.Parent := FForm;
  CheckEquals(RGBOf(clHotLight), RGBOf(TLinkAccess(LL).LinkColor), 'LinkLabel: clHotLight');
  CheckEquals(RGBOf(clWindowText), RGBOf(TLinkAccess(LL).TextColor), 'LinkLabel: Text');
end;

procedure THighContrastTokenTests.HintsHonorHighContrastSupport;
var
  Fill, Border, Txt: TColor;
  M: TPPGHintManager;
  H: TPPGCustomHint;
begin
  PPGHintColors('', Fill, Border, Txt);
  CheckEquals(RGBOf(clInfoBk), RGBOf(Fill), 'Hint: clInfoBk');
  CheckEquals(RGBOf(clInfoText), RGBOf(Txt), 'Hint: clInfoText');
  PPGHintColors('', Fill, Border, Txt, False);
  CheckEquals(PPGPresetTokens('', False).Layer, RGBOf(Fill), 'ohne HighContrastSupport: Preset');
  M := TPPGHintManager.Create(nil);
  H := TPPGCustomHint.Create(nil);
  try
    CheckTrue(M.HighContrastSupport, 'Manager: Vorgabe True');
    CheckTrue(H.HighContrastSupport, 'CustomHint: Vorgabe True');
    CheckEquals(RGBOf(clHighlight), M.Tokens.Accent, 'Manager-Tokens im Hochkontrast');
    M.HighContrastSupport := False;
    CheckEquals(PPGPresetTokens('', False).Accent, M.Tokens.Accent, 'Manager ohne');
  finally
    H.Free;
    M.Free;
  end;
end;

procedure THighContrastTokenTests.DialogPassesHighContrastSupportOn;
var
  D: TPPGTaskDialog;
  F: TPPGDialogForm;
  I: Integer;
begin
  D := TPPGTaskDialog.Create(nil);
  try
    D.Title := 'Titel';
    D.Text := 'Inhalt';
    CheckTrue(D.HighContrastSupport, 'Vorgabe True');
    F := TPPGDialogForm.CreateFor(D, 0);
    try
      CheckTrue(F.UseHighContrast);
      CheckEquals(RGBOf(clWindowText), RGBOf(F.TitleLabel.TextColor), 'Titel in clWindowText');
    finally
      F.Free;
    end;
    D.HighContrastSupport := False;
    F := TPPGDialogForm.CreateFor(D, 0);
    try
      CheckFalse(F.UseHighContrast);
      CheckFalse(F.TitleLabel.HighContrastSupport, 'an den Titel weitergegeben');
      CheckTrue(F.ButtonCount > 0);
      for I := 0 to F.ButtonCount - 1 do
        if F.ButtonAt(I) is TPPGButton then
          CheckFalse(TPPGButton(F.ButtonAt(I)).HighContrastSupport, 'an die Buttons weitergegeben');
    finally
      F.Free;
    end;
  finally
    D.Free;
  end;
end;

procedure THighContrastTokenTests.InfoBarLinksUseLinkToken;
var
  IB: TPPGInfoBar;
begin
  IB := TPPGInfoBar.Create(FForm);
  IB.Parent := FForm;
  IB.Message := 'Mehr <a href="x">Details</a>';
  CheckEquals(RGBOf(clHotLight), IB.TextLinkColor, 'Hochkontrast: clHotLight');
  PPGSetHighContrastReader(NoHighContrast);
  CheckEquals(IB.Tokens.Link, IB.TextLinkColor, 'sonst das Link-Token');
  TPPGTheme.Mode := tmDark;
  CheckEquals(IB.Tokens.Link, IB.TextLinkColor, 'dunkel: Link-Token');
  CheckTrue(PPGContrastRatio(IB.TextLinkColor, IB.Tokens.Background) >= 4.5, 'dunkel lesbar');
end;

procedure THighContrastTokenTests.PaletteControlsPaintAndAreReadable;
var
  CC: TControlClass;
  C: TControl;
  T: TPPGTokens;
  A: TPPGAppearance;
  Bmp: TBitmap;
  Bad: string;

  procedure Pair(const What: string; Fore, Back: TColor; MinRatio: Double);
  var
    R: Double;
  begin
    R := PPGContrastRatio(RGBOf(Fore), RGBOf(Back));
    // wie MeetsTextContrast: auf eine Stelle gerundet (#0078D7/Weiss = 4,5)
    if Round(R * 10) < Round(MinRatio * 10) then
      Bad := Bad + #13#10 + CC.ClassName + ': ' + What + ' ' + FormatFloat('0.00', R);
  end;

begin
  FForm.SetBounds(0, 0, 900, 700);
  FForm.Show;
  Bad := '';
  try
    for CC in VisualClasses do
    begin
      C := CC.Create(FForm);
      try
        C.Parent := FForm;
        C.SetBounds(10, 10, 300, 200);
        if C is TWinControl then
        begin
          TWinControl(C).HandleNeeded;
          Bmp := RenderToBitmap(TWinControl(C));
          Bmp.Free;
        end
        else
          FForm.Repaint;
        if C is TPPGCustomControl then
        begin
          CheckTrue(TCCV(C).UseHighContrast, CC.ClassName + ': Hochkontrast');
          T := TCCV(C).Tokens;
          CheckEquals(RGBOf(clWindowText), T.TextPrimary, CC.ClassName + ': TextPrimary');
          CheckEquals(RGBOf(clHighlight), T.Accent, CC.ClassName + ': Accent');
          Pair('TextPrimary/Surface', T.TextPrimary, T.Surface, 4.5);
          Pair('TextPrimary/Background', T.TextPrimary, T.Background, 4.5);
          Pair('TextDisabled/Surface', T.TextDisabled, T.Surface, 3.0);
          Pair('OnAccent/Accent', T.OnAccent, T.Accent, 4.5);
          Pair('Link/Background', T.Link, T.Background, 4.5);
          A := TCCV(C).EffectiveAppearance;
          Pair('Normal', A.Normal.TextColor, A.Normal.Color, 4.5);
          Pair('Hot', A.Hot.TextColor, A.Hot.Color, 4.5);
          Pair('Down', A.Down.TextColor, A.Down.Color, 4.5);
          Pair('Checked', A.Checked.TextColor, A.Checked.Color, 4.5);
          Pair('Disabled', A.Disabled.TextColor, A.Disabled.Color, 3.0);
        end;
      finally
        C.Free;
      end;
      Application.ProcessMessages;
    end;
  finally
    FForm.Hide;
  end;
  CheckEquals('', Bad, 'Kontrast im Hochkontrast');
  CheckEquals(0, FErrors.Count, FErrors.Text);
  CheckEquals(0, FAppExceptions, 'keine Exceptions');
end;

initialization
  RegisterTest('Audit7C', TAudit7CTests.Suite);
  RegisterTest('Audit7C', THighContrastTokenTests.Suite);

end.
