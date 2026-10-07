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

/// Neutrale Windows-11-Palette (Grundlage fuer Presets ohne eigene Tokens).
function PPGDefaultTokens(Dark: Boolean): TPPGTokens;

/// Relative Leuchtdichte nach WCAG 2.x (0 = schwarz, 1 = weiss).
function PPGRelativeLuminance(C: TColor): Double;
/// Kontrastverhaeltnis nach WCAG 2.x (1..21). Text braucht mindestens 4,5:1,
/// Bedienelemente und grosse Schrift 3:1.
function PPGContrastRatio(A, B: TColor): Double;

implementation

uses
  System.Math, PPG.Types;

function PPGDefaultTokens(Dark: Boolean): TPPGTokens;
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

end.
