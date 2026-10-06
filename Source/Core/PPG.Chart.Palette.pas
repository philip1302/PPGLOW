unit PPG.Chart.Palette;

{ Serienfarben fuer Diagramme (Phase 10).

  Farbe 0 ist immer der Akzent des Presets (Tokens.Accent), danach folgen
  sieben feste Farben je Hell/Dunkel. Jede Farbe hat mindestens 3:1 Kontrast
  zu den Flaechen des Presets (WCAG fuer grafische Elemente; geprueft im Test
  ChartPaletteContrast). Im Hochkontrast gelten Systemfarben. }

{$I ..\PPG.inc}

interface

uses
  Vcl.Graphics, PPG.Tokens;

const
  PPGChartPaletteSize = 8;

/// Farbe der Serie Index (laeuft nach PPGChartPaletteSize wieder von vorn).
function PPGChartColor(const Tokens: TPPGTokens; Dark: Boolean; Index: Integer): TColor;
/// Serienfarbe im Hochkontrast (Systemfarben, bereits als RGB).
function PPGChartHighContrastColor(Index: Integer): TColor;

implementation

uses
  PPG.Types;

const
  // TColor = $00BBGGRR
  LightColors: array[1..PPGChartPaletteSize - 1] of TColor = (
    $001050CA,  // #CA5010 Orange
    $00878303,  // #038387 Petrol
    $00B86487,  // #8764B8 Violett
    $00B339C2,  // #C239B3 Magenta
    $00058249,  // #498205 Gruen
    $000B6F98,  // #986F0B Gold
    $002C26A4); // #A4262C Rot
  DarkColors: array[1..PPGChartPaletteSize - 1] of TColor = (
    $0062A0FF,  // #FFA062
    $00D6D64C,  // #4CD6D6
    $00FFA0B4,  // #B4A0FF
    $00E68FF4,  // #F48FE6
    $005ED39B,  // #9BD35E
    $005BC5E3,  // #E3C55B
    $008A8AFF); // #FF8A8A

function PPGChartColor(const Tokens: TPPGTokens; Dark: Boolean; Index: Integer): TColor;
begin
  if Index < 0 then
    Index := 0;
  Index := Index mod PPGChartPaletteSize;
  if Index = 0 then
    Result := Tokens.Accent
  else if Dark then
    Result := DarkColors[Index]
  else
    Result := LightColors[Index];
end;

function PPGChartHighContrastColor(Index: Integer): TColor;
begin
  if Index < 0 then
    Index := 0;
  case Index mod 4 of
    0: Result := PPGColorToRGB(clHighlight);
    1: Result := PPGColorToRGB(clHotLight);
    2: Result := PPGColorToRGB(clWindowText);
  else
    Result := PPGColorToRGB(clGrayText);
  end;
end;

end.
