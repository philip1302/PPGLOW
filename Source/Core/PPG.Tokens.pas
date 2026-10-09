unit PPG.Tokens;

{ Design-Tokens: die semantischen Farben, Masse und Bewegungsdauern eines
  Presets - je einmal fuer Hell und Dunkel.

  Jedes Preset (Renderer) liefert seine Tokens ueber IPPGThemeRenderer und
  leitet daraus die Farben seiner Appearance ab (ApplyThemeColors). Controls
  lesen Farben, die nicht in der Appearance stehen (Signalfarben, spaeter
  Flaechen von Feldern/Listen/Seiten im Dark Mode), aus den Tokens statt aus
  Systemfarben wie clWindow - die bleiben im Dark Mode hell.

  Die Werte sind TColor ($00BBGGRR); Masse in logischen 96-DPI-Pixeln. }

{$I ..\PPG.inc}

interface

uses
  Vcl.Graphics;

type
  TPPGTokens = record
    { Akzent }
    Accent: TColor;          // Hauptakzent (Fokus, gewaehlt, Fortschritt)
    AccentHover: TColor;
    AccentPressed: TColor;
    OnAccent: TColor;        // Text/Symbole auf Akzentflaeche
    { Flaechen }
    Background: TColor;      // Fensterhintergrund
    Layer: TColor;           // Container, Seiten, Listen
    Surface: TColor;         // Bedienelement in Ruhe
    SurfaceHover: TColor;
    SurfacePressed: TColor;
    SurfaceDisabled: TColor;
    { Raender }
    Stroke: TColor;          // normaler Rand
    StrokeStrong: TColor;    // Unterkante/Elevation, Trennlinien
    StrokeDisabled: TColor;
    { Text }
    TextPrimary: TColor;
    TextSecondary: TColor;   // Detailzeilen, Hinweise
    TextDisabled: TColor;
    Link: TColor;            // Links im Text (4,5:1 zum Hintergrund)
    { Signale }
    Danger: TColor;
    Warning: TColor;
    Success: TColor;
    Paused: TColor;          // Fortschritt angehalten
    { Masse (logische px) }
    RadiusSmall: Integer;    // Kaestchen, kleine Buttons
    RadiusMedium: Integer;   // Buttons, Felder
    RadiusLarge: Integer;    // Popups, Karten
    StrokeWidth: Integer;
    { Bewegung (ms) }
    DurationFast: Integer;
    DurationNormal: Integer;
    DurationSlow: Integer;
  end;

  /// Farb-Tokens als Aufzaehlung (fuer Ueberschreibungen und Theme-Dateien).
  TPPGTokenColor = (tkAccent, tkAccentHover, tkAccentPressed, tkOnAccent,
    tkBackground, tkLayer, tkSurface, tkSurfaceHover, tkSurfacePressed,
    tkSurfaceDisabled, tkStroke, tkStrokeStrong, tkStrokeDisabled,
    tkTextPrimary, tkTextSecondary, tkTextDisabled, tkDanger, tkWarning,
    tkSuccess, tkPaused, tkLink);

  /// Akzentfarben fuer beide Modi.
  TPPGAccentPair = record
    Light: TColor; // heller Modus: Text darauf weiss
    Dark: TColor;  // dunkler Modus: Text darauf schwarz
  end;

  /// Anwendungsweite Ueberschreibungen der Tokens aller Presets (Marke,
  /// Firmen-Design). clDefault = Wert des Presets. Gesetzt werden sie
  /// ueblicherweise ueber TPPGStyleManager (AccentColor, ThemeColors,
  /// ChartPalette); danach TPPGTheme.Changed, damit alle Controls neu zeichnen.
  TPPGTokenOverrides = class
  private
    class var FAccentBase: TColor;
    class var FColors: array[Boolean, TPPGTokenColor] of TColor;
    class var FChartPalette: TArray<TColor>;
    class var FVersion: Integer;
    class procedure SetAccentBase(const Value: TColor); static;
    class function GetColor(Dark: Boolean; Kind: TPPGTokenColor): TColor; static;
    class procedure SetColor(Dark: Boolean; Kind: TPPGTokenColor; const Value: TColor); static;
    class function GetChartPalette: TArray<TColor>; static;
    class procedure SetChartPalette(const Value: TArray<TColor>); static;
  public
    /// Alle Ueberschreibungen entfernen (Presets gelten wieder unveraendert).
    class procedure Clear; static;
    /// True, wenn mindestens eine Ueberschreibung gesetzt ist.
    class function Active: Boolean; static;
    /// Grundfarbe des Akzents; Hell/Dunkel-Varianten und Hover/Druck werden
    /// mit Kontrastpruefung abgeleitet (wie der Windows-Akzent).
    class property AccentBase: TColor read FAccentBase write SetAccentBase;
    /// Einzelnes Token je Modus (Dark = True fuer den dunklen Modus).
    class property Colors[Dark: Boolean; Kind: TPPGTokenColor]: TColor read GetColor write SetColor;
    /// Eigene Reihenfolge der Diagramm-/Kategorienfarben (leer = Preset).
    class property ChartPalette: TArray<TColor> read GetChartPalette write SetChartPalette;
    /// Zaehlt jede Aenderung (fuer Zwischenspeicher).
    class property Version: Integer read FVersion;
  end;

/// Tokens des Standard-Presets OHNE anwendungsweite Ueberschreibungen
/// (Grundlage fuer Renderer).
function PPGBaseTokens(Dark: Boolean): TPPGTokens;
/// Wendet AccentBase und die einzelnen Token-Ueberschreibungen an.
/// Renderer rufen das am Ende von Tokens auf.
procedure PPGApplyTokenOverrides(var T: TPPGTokens; Dark: Boolean);
function PPGGetTokenColor(const T: TPPGTokens; Kind: TPPGTokenColor): TColor;
procedure PPGSetTokenColor(var T: TPPGTokens; Kind: TPPGTokenColor; Value: TColor);
/// Akzente fuer Hell/Dunkel aus einer Grundfarbe ableiten (mit Kontrastpruefung).
function PPGAccentFromBase(Base: TColor): TPPGAccentPair;
/// Hell: weisser Text 4,5:1; Dunkel: schwarzer Text 7:1 und 3:1 zum Hintergrund.
function PPGFixAccentPair(const Pair: TPPGAccentPair): TPPGAccentPair;

/// Neutrale Windows-11-Palette (Grundlage fuer Presets ohne eigene Tokens),
/// einschliesslich der anwendungsweiten Ueberschreibungen.
function PPGDefaultTokens(Dark: Boolean): TPPGTokens;

/// Relative Leuchtdichte nach WCAG 2.x (0 = schwarz, 1 = weiss).
function PPGRelativeLuminance(C: TColor): Double;
/// Kontrastverhaeltnis nach WCAG 2.x (1..21). Text braucht mindestens 4,5:1,
/// Bedienelemente und grosse Schrift 3:1.
function PPGContrastRatio(A, B: TColor): Double;

/// Textfarbe auf einer Flaeche: die hellere (Light) oder dunklere (Dark)
/// Farbe, je nachdem welche den hoeheren Kontrast hat. Erreicht Light schon
/// 4,5:1 (auf eine Stelle gerundet), bleibt Light (weisser Text auf mittleren
/// Akzenten wie #0078D7).
function PPGContrastTextColor(Fill: TColor; Light: TColor = clWhite;
  Dark: TColor = clBlack): TColor;
/// Text bleibt, wenn er 4,5:1 zur Flaeche erreicht; sonst PPGContrastTextColor.
function PPGReadableTextColor(Text, Fill: TColor): TColor;
/// Link-Farbe aus dem Akzent: so weit abgedunkelt (heller Hintergrund) bzw.
/// aufgehellt (dunkler Hintergrund), dass sie 4,5:1 zum Hintergrund erreicht.
function PPGLinkColor(Accent, Background: TColor): TColor;
/// Farbe im deaktivierten Zustand: entsaettigt und zur Flaeche hin abgeblendet.
function PPGDisabledColor(C, Background: TColor): TColor;
/// Tokens fuer ein deaktiviertes Control: Akzent- und Signalfarben
/// abgeblendet (PPGDisabledColor), Text TextDisabled, Raender StrokeDisabled,
/// Flaechen SurfaceDisabled. Hintergrund und Layer bleiben.
function PPGDisabledTokens(const T: TPPGTokens): TPPGTokens;

implementation

uses
  System.Math, PPG.Types;

function PPGDefaultTokens(Dark: Boolean): TPPGTokens;
begin
  Result := PPGBaseTokens(Dark);
  PPGApplyTokenOverrides(Result, Dark);
end;

function PPGBaseTokens(Dark: Boolean): TPPGTokens;
begin
  // Ruhe/Hover/Druck-Stufen und Signalfarben nach den Windows-11-Vorgaben
  // (WinUI "Fluent" Farbpalette), als TColor ($00BBGGRR)
  if not Dark then
  begin
    Result.Accent := $00B85F00;          // #005FB8
    Result.AccentHover := $00C26E19;     // #196EC2
    Result.AccentPressed := $00C77D31;   // #317DC7
    Result.OnAccent := $00FFFFFF;
    Result.Background := $00F3F3F3;
    Result.Layer := $00F9F9F9;
    Result.Surface := $00FBFBFB;
    Result.SurfaceHover := $00F6F6F6;
    Result.SurfacePressed := $00F0F0F0;
    Result.SurfaceDisabled := $00F5F5F5;
    Result.Stroke := $00E5E5E5;
    Result.StrokeStrong := $00C4C4C4;
    Result.StrokeDisabled := $00E5E5E5;
    Result.TextPrimary := $001B1B1B;
    Result.TextSecondary := $005D5D5D;
    Result.TextDisabled := $00A0A0A0;
    Result.Danger := $001C2BC4;          // #C42B1C
    Result.Warning := $00005D9D;         // #9D5D00
    Result.Success := $00107C0F;         // #0F7B0F
    Result.Paused := $0000B9FF;
  end
  else
  begin
    Result.Accent := $00FFCD60;          // #60CDFF
    Result.AccentHover := $00E8BA5A;
    Result.AccentPressed := $00CCA454;
    Result.OnAccent := $00000000;
    Result.Background := $00202020;
    Result.Layer := $002B2B2B;
    Result.Surface := $002D2D2D;
    Result.SurfaceHover := $00323232;
    Result.SurfacePressed := $00272727;
    Result.SurfaceDisabled := $002A2A2A;
    Result.Stroke := $00383838;
    Result.StrokeStrong := $00636363;
    Result.StrokeDisabled := $00333333;
    Result.TextPrimary := $00FFFFFF;
    Result.TextSecondary := $00C5C5C5;
    Result.TextDisabled := $00787878;
    Result.Danger := $00A499FF;          // #FF99A4
    Result.Warning := $0000E1FC;         // #FCE100
    Result.Success := $005FCB6C;         // #6CCB5F
    Result.Paused := $0000E1FC;
  end;
  Result.RadiusSmall := 4;
  Result.RadiusMedium := 4;
  Result.RadiusLarge := 8;
  Result.StrokeWidth := 1;
  Result.DurationFast := 83;
  Result.DurationNormal := 167;
  Result.DurationSlow := 250;
  Result.Link := PPGLinkColor(Result.Accent, Result.Background);
end;

function Channel(V: Integer): Double;
var
  S: Double;
begin
  S := V / 255;
  if S <= 0.03928 then
    Result := S / 12.92
  else
    Result := Power((S + 0.055) / 1.055, 2.4);
end;

function PPGRelativeLuminance(C: TColor): Double;
var
  RGB: Cardinal;
begin
  RGB := Cardinal(PPGColorToRGB(C));
  Result := 0.2126 * Channel(RGB and $FF) + 0.7152 * Channel((RGB shr 8) and $FF) +
    0.0722 * Channel((RGB shr 16) and $FF);
end;

function PPGContrastRatio(A, B: TColor): Double;
var
  LA, LB: Double;
begin
  LA := PPGRelativeLuminance(A);
  LB := PPGRelativeLuminance(B);
  if LA < LB then
    Result := (LB + 0.05) / (LA + 0.05)
  else
    Result := (LA + 0.05) / (LB + 0.05);
end;

{ ---- Textkontrast ---- }

/// 4,5:1 (WCAG AA fuer Text), wie Pruefwerkzeuge auf eine Nachkommastelle
/// gerundet: Weiss auf #0078D7 (4,499:1) gilt wie bei Windows als lesbar.
function MeetsTextContrast(Ratio: Double): Boolean;
begin
  Result := Round(Ratio * 10) >= 45;
end;

function PPGContrastTextColor(Fill, Light, Dark: TColor): TColor;
var
  CL: Double;
begin
  Fill := PPGColorToRGB(Fill);
  Light := PPGColorToRGB(Light);
  Dark := PPGColorToRGB(Dark);
  CL := PPGContrastRatio(Fill, Light);
  if MeetsTextContrast(CL) or (CL >= PPGContrastRatio(Fill, Dark)) then
    Result := Light
  else
    Result := Dark;
end;

function PPGReadableTextColor(Text, Fill: TColor): TColor;
begin
  if MeetsTextContrast(PPGContrastRatio(Text, Fill)) then
    Result := PPGColorToRGB(Text)
  else
    Result := PPGContrastTextColor(Fill);
end;

function PPGDisabledColor(C, Background: TColor): TColor;
var
  RGB: Cardinal;
  G: Integer;
begin
  // Grauwert gleicher Helligkeit, dann zur Haelfte in die Flaeche
  RGB := Cardinal(PPGColorToRGB(C));
  G := Round(0.299 * (RGB and $FF) + 0.587 * ((RGB shr 8) and $FF) +
    0.114 * ((RGB shr 16) and $FF));
  if G > 255 then
    G := 255;
  Result := PPGBlendColor(TColor(G or (G shl 8) or (G shl 16)), Background, 0.5);
end;

function PPGDisabledTokens(const T: TPPGTokens): TPPGTokens;
var
  B: TColor;
begin
  Result := T;
  B := T.Background;
  Result.Accent := PPGDisabledColor(T.Accent, B);
  Result.AccentHover := Result.Accent;
  Result.AccentPressed := Result.Accent;
  Result.OnAccent := PPGBlendColor(PPGContrastTextColor(Result.Accent), Result.Accent, 0.3);
  Result.Link := PPGDisabledColor(T.Link, B);
  Result.Surface := T.SurfaceDisabled;
  Result.SurfaceHover := T.SurfaceDisabled;
  Result.SurfacePressed := T.SurfaceDisabled;
  Result.Stroke := T.StrokeDisabled;
  Result.StrokeStrong := T.StrokeDisabled;
  Result.TextPrimary := T.TextDisabled;
  Result.TextSecondary := T.TextDisabled;
  Result.Danger := PPGDisabledColor(T.Danger, B);
  Result.Warning := PPGDisabledColor(T.Warning, B);
  Result.Success := PPGDisabledColor(T.Success, B);
  Result.Paused := PPGDisabledColor(T.Paused, B);
end;

{ ---- Akzent aus Grundfarbe ---- }

function EnsureContrast(C, Against: TColor; Min: Double; TowardWhite: Boolean): TColor;
var
  I: Integer;
begin
  Result := C;
  for I := 1 to 30 do
  begin
    if PPGContrastRatio(Result, Against) >= Min then
      Exit;
    if TowardWhite then
      Result := PPGLighten(Result, 0.1)
    else
      Result := PPGDarken(Result, 0.1);
  end;
end;

function PPGFixAccentPair(const Pair: TPPGAccentPair): TPPGAccentPair;
var
  Dark: TPPGTokens;
begin
  // Hell: weisser Text auf dem Akzent (WCAG AA). Dunkel: schwarzer Text mit
  // deutlichem Abstand (7:1), so bleibt die Helligkeit klar von den hellen
  // Akzenten getrennt, und der Akzent hebt sich vom dunklen Hintergrund ab.
  Dark := PPGBaseTokens(True);
  Result.Light := EnsureContrast(PPGColorToRGB(Pair.Light), clWhite, 4.5, False);
  Result.Dark := EnsureContrast(PPGColorToRGB(Pair.Dark), clBlack, 7.0, True);
  Result.Dark := EnsureContrast(Result.Dark, Dark.Background, 3.0, True);
end;

function PPGLinkColor(Accent, Background: TColor): TColor;
begin
  // Heller Hintergrund: Akzent bei Bedarf abdunkeln; dunkler: aufhellen
  Result := EnsureContrast(PPGColorToRGB(Accent), PPGColorToRGB(Background), 4.5,
    PPGRelativeLuminance(Background) < 0.4);
end;

function PPGAccentFromBase(Base: TColor): TPPGAccentPair;
var
  B: TColor;
begin
  // Windows nutzt im Hellen eine dunklere, im Dunkeln eine deutlich hellere
  // Variante der Grundfarbe (AccentDark1 / AccentLight2)
  B := PPGColorToRGB(Base);
  Result.Light := PPGDarken(B, 0.15);
  Result.Dark := PPGLighten(B, 0.45);
  Result := PPGFixAccentPair(Result);
end;

{ ---- Einzelne Tokens ---- }

function PPGGetTokenColor(const T: TPPGTokens; Kind: TPPGTokenColor): TColor;
begin
  case Kind of
    tkAccent: Result := T.Accent;
    tkAccentHover: Result := T.AccentHover;
    tkAccentPressed: Result := T.AccentPressed;
    tkOnAccent: Result := T.OnAccent;
    tkBackground: Result := T.Background;
    tkLayer: Result := T.Layer;
    tkSurface: Result := T.Surface;
    tkSurfaceHover: Result := T.SurfaceHover;
    tkSurfacePressed: Result := T.SurfacePressed;
    tkSurfaceDisabled: Result := T.SurfaceDisabled;
    tkStroke: Result := T.Stroke;
    tkStrokeStrong: Result := T.StrokeStrong;
    tkStrokeDisabled: Result := T.StrokeDisabled;
    tkTextPrimary: Result := T.TextPrimary;
    tkTextSecondary: Result := T.TextSecondary;
    tkTextDisabled: Result := T.TextDisabled;
    tkDanger: Result := T.Danger;
    tkWarning: Result := T.Warning;
    tkSuccess: Result := T.Success;
    tkPaused: Result := T.Paused;
  else
    Result := T.Link;
  end;
end;

procedure PPGSetTokenColor(var T: TPPGTokens; Kind: TPPGTokenColor; Value: TColor);
begin
  case Kind of
    tkAccent: T.Accent := Value;
    tkAccentHover: T.AccentHover := Value;
    tkAccentPressed: T.AccentPressed := Value;
    tkOnAccent: T.OnAccent := Value;
    tkBackground: T.Background := Value;
    tkLayer: T.Layer := Value;
    tkSurface: T.Surface := Value;
    tkSurfaceHover: T.SurfaceHover := Value;
    tkSurfacePressed: T.SurfacePressed := Value;
    tkSurfaceDisabled: T.SurfaceDisabled := Value;
    tkStroke: T.Stroke := Value;
    tkStrokeStrong: T.StrokeStrong := Value;
    tkStrokeDisabled: T.StrokeDisabled := Value;
    tkTextPrimary: T.TextPrimary := Value;
    tkTextSecondary: T.TextSecondary := Value;
    tkTextDisabled: T.TextDisabled := Value;
    tkDanger: T.Danger := Value;
    tkWarning: T.Warning := Value;
    tkSuccess: T.Success := Value;
    tkPaused: T.Paused := Value;
  else
    T.Link := Value;
  end;
end;

procedure PPGApplyTokenOverrides(var T: TPPGTokens; Dark: Boolean);
var
  P: TPPGAccentPair;
  A, Under: TColor;
  K: TPPGTokenColor;
  C: TColor;
begin
  if TPPGTokenOverrides.FAccentBase <> clDefault then
  begin
    // Wie der Fluent-Systemakzent: Hover/Druck = Akzent mit 90/80 % Deckung
    P := PPGAccentFromBase(TPPGTokenOverrides.FAccentBase);
    if Dark then
    begin
      A := P.Dark;
      Under := T.Background;
      T.OnAccent := clBlack;
    end
    else
    begin
      A := P.Light;
      Under := T.Surface;
      T.OnAccent := clWhite;
    end;
    T.Accent := A;
    T.AccentHover := PPGBlendColor(A, Under, 0.10);
    T.AccentPressed := PPGBlendColor(A, Under, 0.20);
  end;
  for K := Low(TPPGTokenColor) to High(TPPGTokenColor) do
  begin
    C := TPPGTokenOverrides.FColors[Dark, K];
    if C <> clDefault then
      PPGSetTokenColor(T, K, PPGColorToRGB(C));
  end;
  // Link folgt einem geaenderten Akzent bzw. Hintergrund (ausser bei eigener Link-Farbe)
  if (TPPGTokenOverrides.FColors[Dark, tkLink] = clDefault) and
    ((TPPGTokenOverrides.FAccentBase <> clDefault) or
    (TPPGTokenOverrides.FColors[Dark, tkAccent] <> clDefault) or
    (TPPGTokenOverrides.FColors[Dark, tkBackground] <> clDefault)) then
    T.Link := PPGLinkColor(T.Accent, T.Background);
end;

{ TPPGTokenOverrides }

class procedure TPPGTokenOverrides.Clear;
var
  K: TPPGTokenColor;
begin
  FAccentBase := clDefault;
  for K := Low(TPPGTokenColor) to High(TPPGTokenColor) do
  begin
    FColors[False, K] := clDefault;
    FColors[True, K] := clDefault;
  end;
  SetLength(FChartPalette, 0);
  Inc(FVersion);
end;

class function TPPGTokenOverrides.Active: Boolean;
var
  K: TPPGTokenColor;
begin
  Result := (FAccentBase <> clDefault) or (Length(FChartPalette) > 0);
  if not Result then
    for K := Low(TPPGTokenColor) to High(TPPGTokenColor) do
      if (FColors[False, K] <> clDefault) or (FColors[True, K] <> clDefault) then
        Exit(True);
end;

class procedure TPPGTokenOverrides.SetAccentBase(const Value: TColor);
begin
  if FAccentBase <> Value then
  begin
    FAccentBase := Value;
    Inc(FVersion);
  end;
end;

class function TPPGTokenOverrides.GetColor(Dark: Boolean; Kind: TPPGTokenColor): TColor;
begin
  Result := FColors[Dark, Kind];
end;

class procedure TPPGTokenOverrides.SetColor(Dark: Boolean; Kind: TPPGTokenColor;
  const Value: TColor);
begin
  if FColors[Dark, Kind] <> Value then
  begin
    FColors[Dark, Kind] := Value;
    Inc(FVersion);
  end;
end;

class function TPPGTokenOverrides.GetChartPalette: TArray<TColor>;
begin
  Result := Copy(FChartPalette);
end;

class procedure TPPGTokenOverrides.SetChartPalette(const Value: TArray<TColor>);
begin
  FChartPalette := Copy(Value);
  Inc(FVersion);
end;

initialization
  TPPGTokenOverrides.Clear;

end.
