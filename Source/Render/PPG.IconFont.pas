unit PPG.IconFont;

{ Fluent-Icons aus der Symbolschrift von Windows (Phase 8.6).

  - Windows 11: "Segoe Fluent Icons", Windows 10: "Segoe MDL2 Assets" (beide
    mit denselben Codepunkten fuer die hier genutzten Symbole).
  - Fehlt beides (Windows 7/8, Server Core, Wine), liefert PPGDrawIcon False;
    der Renderer zeichnet dann seine bisherigen Linien.
  - Die Schrift wird einmal gesucht und zwischengespeichert. Tests erzwingen
    den Rueckfall mit PPGSetIconFontOverride('-').

  Gezeichnet wird ueber IPPGCanvas.DrawText (GDI, ClearType wie der Text der
  Controls); eine Drehung ist damit nicht moeglich. }

{$I ..\PPG.inc}

interface

uses
  System.Types, Vcl.Graphics, PPG.Render.Intf;

type
  TPPGIconGlyph = (igChevronDown, igChevronUp, igChevronLeft, igChevronRight,
    igClose, igCheckMark, igInfo, igWarning, igError, igSuccess, igSearch, igStar,
    igStarFilled, igCalendar, igClock, igMenu, igMore, igSettings);

const
  PPGFontFluentIcons = 'Segoe Fluent Icons';
  PPGFontMdl2Assets = 'Segoe MDL2 Assets';

/// Name der verfuegbaren Symbolschrift, '' = keine.
function PPGIconFontName: string;
/// '' = automatisch suchen; '-' = keine Symbolschrift (Rueckfall erzwingen);
/// sonst dieser Schriftname. Verwirft den Zwischenspeicher.
procedure PPGSetIconFontOverride(const Name: string);
/// Zeichen des Symbols (Private-Use-Bereich der Symbolschriften).
function PPGIconChar(Glyph: TPPGIconGlyph): Char;
/// Zeichnet das Symbol mittig in R mit der Schriftgroesse SizePx (Pixel,
/// Em-Hoehe). False = keine Symbolschrift; dann hat der Aufrufer zu zeichnen.
function PPGDrawIcon(const Canvas: IPPGCanvas; const R: TRect; Glyph: TPPGIconGlyph;
  Color: TColor; SizePx: Integer): Boolean;
/// Wie PPGDrawIcon, aber mit einem beliebigen Zeichen der Symbolschrift
/// (Code-Punkt, z.B. $E80F fuer "Home").
function PPGDrawIconChar(const Canvas: IPPGCanvas; const R: TRect; CodePoint: Word;
  Color: TColor; SizePx: Integer): Boolean;

implementation

uses
  Winapi.Windows, System.SysUtils;

const
  GlyphChars: array[TPPGIconGlyph] of Word = (
    $E70D,  // ChevronDown
    $E70E,  // ChevronUp
    $E76B,  // ChevronLeft
    $E76C,  // ChevronRight
    $E711,  // Cancel
    $E73E,  // CheckMark
    $E946,  // Info
    $E7BA,  // Warning
    $EA39,  // ErrorBadge
    $E930,  // Completed
    $E721,  // Search
    $E734,  // FavoriteStar
    $E735,  // FavoriteStarFill
    $E787,  // Calendar
    $E823,  // Clock
    $E700,  // GlobalNavigationButton (Hamburger)
    $E712,  // More
    $E713); // Setting

var
  GOverride: string = '';
  GResolved: Boolean = False;
  GFontName: string = '';

function EnumProc(const LogFont: TLogFont; const TextMetric: TTextMetric;
  FontType: DWORD; Data: LPARAM): Integer; stdcall;
begin
  PBoolean(Data)^ := True;
  Result := 0; // erster Treffer genuegt
end;

function FontInstalled(const Name: string): Boolean;
var
  DC: HDC;
  LF: TLogFont;
  Found: Boolean;
begin
  Result := False;
  DC := GetDC(0);
  if DC = 0 then
    Exit;
  try
    FillChar(LF, SizeOf(LF), 0);
    LF.lfCharSet := DEFAULT_CHARSET;
    StrPLCopy(LF.lfFaceName, Name, Length(LF.lfFaceName) - 1);
    Found := False;
    EnumFontFamiliesEx(DC, LF, @EnumProc, LPARAM(@Found), 0);
    Result := Found;
  finally
    ReleaseDC(0, DC);
  end;
end;

function PPGIconFontName: string;
begin
  if not GResolved then
  begin
    if GOverride = '-' then
      GFontName := ''
    else if GOverride <> '' then
      GFontName := GOverride
    else if FontInstalled(PPGFontFluentIcons) then
      GFontName := PPGFontFluentIcons
    else if FontInstalled(PPGFontMdl2Assets) then
      GFontName := PPGFontMdl2Assets
    else
      GFontName := '';
    GResolved := True;
  end;
  Result := GFontName;
end;

procedure PPGSetIconFontOverride(const Name: string);
begin
  GOverride := Name;
  GResolved := False;
end;

function PPGIconChar(Glyph: TPPGIconGlyph): Char;
begin
  Result := Char(GlyphChars[Glyph]);
end;

function PPGDrawIcon(const Canvas: IPPGCanvas; const R: TRect; Glyph: TPPGIconGlyph;
  Color: TColor; SizePx: Integer): Boolean;
begin
  Result := PPGDrawIconChar(Canvas, R, GlyphChars[Glyph], Color, SizePx);
end;

function PPGDrawIconChar(const Canvas: IPPGCanvas; const R: TRect; CodePoint: Word;
  Color: TColor; SizePx: Integer): Boolean;
var
  Name: string;
  F: TFont;
begin
  Name := PPGIconFontName;
  Result := (Name <> '') and (CodePoint <> 0);
  if not Result or IsRectEmpty(R) or (SizePx < 4) then
    Exit;
  F := TFont.Create;
  try
    F.Name := Name;
    F.Charset := DEFAULT_CHARSET;
    F.Height := -SizePx;
    Canvas.DrawText(R, Char(CodePoint), F, Color,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_NOCLIP);
  finally
    F.Free;
  end;
end;

end.
