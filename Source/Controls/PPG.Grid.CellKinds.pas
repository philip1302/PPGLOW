unit PPG.Grid.CellKinds;

{ Zellarten des Grids (Phase 13d).

  - Jede Zellart ist eine Klasse hinter IPPGCellKind: Zeichnen, Mausklick,
    Taste, Mauszeiger und Text fuer Screenreader. Das Grid kennt nur das
    Interface (OCP); neue Arten werden registriert (PPGRegisterCellKind bzw.
    PPGRegisterCellKindName fuer Column.CellKind = ckCustom).
  - Der Wert einer Zelle bleibt Text (Cells[]/OnGetCellText): '1'/'0' fuer
    Kaestchen, Zahl fuer Fortschritt und Bewertung, '3;5;2' fuer Sparklines,
    Bildindex, Farbe ('clRed', '#FF8800', '$0000FF').
  - Hintergrund, Linien, Auswahl und Fokus zeichnet das Grid; die Zellart
    zeichnet nur den Inhalt. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.Types, System.SysUtils, Vcl.Controls,
  Vcl.Graphics, Vcl.ImgList,
  PPG.Types, PPG.Tokens, PPG.Render.Intf, PPG.Grid.Columns, PPG.Grid.Paint;

type
  TPPGCellAction = (caNone, caSetValue, caLink, caButton);

  /// Alles, was eine Zellart zum Zeichnen und Bedienen braucht (einmal je
  /// Zeichenvorgang vom Grid gefuellt).
  TPPGCellKindContext = record
    Canvas: IPPGCanvas;
    Painter: TPPGCellPainter;
    PPI: Integer;
    Font: TFont;
    Images: TCustomImageList;
    Tokens: TPPGTokens;
    TextColor, FillColor, LineColor, AccentColor, HintColor: TColor;
    CheckedStyle, UncheckedStyle: TPPGSurfaceStyle;
    /// Bereich der Spalte (MinValue/MaxValue; 0/0 = Vorgabe der Zellart).
    MinValue, MaxValue: Integer;
    Enabled, RightToLeft: Boolean;
  end;

  IPPGCellKind = interface
    ['{2E8B5C71-94D3-4A6F-B1E8-3C07D5A9F264}']
    procedure PaintCell(const Ctx: TPPGCellKindContext; const R: TRect; const Text: string);
    /// Klick an P (Client-Koordinaten) in der Zelle R.
    function CellClick(const Ctx: TPPGCellKindContext; const R: TRect; const P: TPoint;
      const Text: string; out NewText: string): TPPGCellAction;
    /// Taste auf der Fokuszelle (Leertaste, Enter, Ziffern).
    function CellKey(const Ctx: TPPGCellKindContext; Key: Word; const Text: string;
      out NewText: string): TPPGCellAction;
    function CellCursor(const Ctx: TPPGCellKindContext; const R: TRect; const P: TPoint;
      const Text: string): TCursor;
    /// Wert fuer Screenreader (z.B. "75 %", "3/5").
    function CellAccText(const Ctx: TPPGCellKindContext; const Text: string): string;
  end;

  /// Basis mit neutralen Vorgaben (eigene Zellarten erben davon).
  TPPGCellKindBase = class(TInterfacedObject, IPPGCellKind)
  public
    procedure PaintCell(const Ctx: TPPGCellKindContext; const R: TRect; const Text: string); virtual;
    function CellClick(const Ctx: TPPGCellKindContext; const R: TRect; const P: TPoint;
      const Text: string; out NewText: string): TPPGCellAction; virtual;
    function CellKey(const Ctx: TPPGCellKindContext; Key: Word; const Text: string;
      out NewText: string): TPPGCellAction; virtual;
    function CellCursor(const Ctx: TPPGCellKindContext; const R: TRect; const P: TPoint;
      const Text: string): TCursor; virtual;
    function CellAccText(const Ctx: TPPGCellKindContext; const Text: string): string; virtual;
  end;

procedure PPGRegisterCellKind(Kind: TPPGGridCellKind; const Impl: IPPGCellKind);
procedure PPGRegisterCellKindName(const Name: string; const Impl: IPPGCellKind);
/// Zellart (nil = Text). Name nur fuer ckCustom.
function PPGCellKind(Kind: TPPGGridCellKind; const Name: string = ''): IPPGCellKind;
/// Eingebaute Zellart? Ihre Texte darf das Grid sammeln und in einem
/// GDI-Block ausgeben (sie zeichnet nach dem Text nichts mehr darueber).
function PPGCellKindIsBuiltIn(const Kind: IPPGCellKind): Boolean;
/// Farbe aus Text: Name (clRed), #RRGGBB, $BBGGRR oder Zahl.
function PPGCellColor(const S: string; out C: TColor): Boolean;
/// Text zeichnen (GDI, einzeilig) - fuer Zellarten.
procedure PPGCellDrawText(const Ctx: TPPGCellKindContext; const S: string; R: TRect;
  Color: TColor; Flags: Cardinal; AFont: TFont = nil);

implementation

uses
  System.Math, System.UITypes, System.Generics.Collections, PPG.Lang, PPG.Consts, PPG.Appearance,
  PPG.Markup, PPG.Markup.Parser, PPG.Sparkline, PPG.Render.Shapes;

var
  GKinds: array[TPPGGridCellKind] of IPPGCellKind;
  GNamed: TDictionary<string, IPPGCellKind>;

procedure ClearKinds;
var
  K: TPPGGridCellKind;
begin
  for K := Low(K) to High(K) do
    GKinds[K] := nil;
end;

procedure PPGRegisterCellKind(Kind: TPPGGridCellKind; const Impl: IPPGCellKind);
begin
  GKinds[Kind] := Impl;
end;

procedure PPGRegisterCellKindName(const Name: string; const Impl: IPPGCellKind);
begin
  if Impl = nil then
    GNamed.Remove(UpperCase(Name))
  else
    GNamed.AddOrSetValue(UpperCase(Name), Impl);
end;

function PPGCellKind(Kind: TPPGGridCellKind; const Name: string): IPPGCellKind;
begin
  if Kind = ckCustom then
  begin
    if not GNamed.TryGetValue(UpperCase(Name), Result) then
      Result := nil;
  end
  else
    Result := GKinds[Kind];
end;

function PPGCellColor(const S: string; out C: TColor): Boolean;
var
  T: string;
  V: Integer;
  L: Longint;
begin
  T := Trim(S);
  Result := False;
  if T = '' then
    Exit;
  if T[1] = '#' then
  begin
    // #RRGGBB -> TColor ($BBGGRR)
    Result := (Length(T) = 7) and TryStrToInt('$' + Copy(T, 2, 6), V);
    if Result then
      C := TColor(((V and $FF) shl 16) or (V and $FF00) or ((V shr 16) and $FF));
  end
  else if IdentToColor(T, L) then
  begin
    C := TColor(L);
    Result := True;
  end
  else if TryStrToInt(T, V) then
  begin
    C := TColor(V);
    Result := True;
  end;
end;

procedure PPGCellDrawText(const Ctx: TPPGCellKindContext; const S: string; R: TRect;
  Color: TColor; Flags: Cardinal; AFont: TFont);
var
  DC: HDC;
begin
  if (S = '') or IsRectEmpty(R) then
    Exit;
  if AFont = nil then
    AFont := Ctx.Font;
  // Audit 8c #9: im Grid gesammelt und in EINEM GDI-Block ausgegeben (nur
  // mit der Schrift des Grids - fremde Schriften koennten vorher freigegeben
  // werden)
  if (Ctx.Painter <> nil) and Ctx.Painter.CollectTexts and (AFont = Ctx.Font) then
  begin
    if Ctx.RightToLeft then
      Flags := Flags or DT_RTLREADING;
    Ctx.Painter.AddTextFont(R, S, Color, Flags, 0);
    Exit;
  end;
  DC := Ctx.Canvas.BeginGdi;
  try
    SelectObject(DC, AFont.Handle);
    SetBkMode(DC, TRANSPARENT);
    SetTextColor(DC, ColorToRGB(Color));
    if Ctx.RightToLeft then
      Flags := Flags or DT_RTLREADING;
    Winapi.Windows.DrawText(DC, PChar(S), Length(S), R, Flags);
  finally
    Ctx.Canvas.EndGdi(DC);
  end;
end;

function TextWidth(const Ctx: TPPGCellKindContext; const S: string; AFont: TFont = nil): Integer;
var
  DC: HDC;
  Old: HGDIOBJ;
  Sz: TSize;
begin
  Result := 0;
  if S = '' then
    Exit;
  if AFont = nil then
    AFont := Ctx.Font;
  // Audit 8c #9: Messcache des Zeichenvorgangs (z.B. '100 %' je Zelle)
  if Ctx.Painter <> nil then
    Exit(Ctx.Painter.TextWidth(AFont, S));
  DC := GetDC(0);
  try
    Old := SelectObject(DC, AFont.Handle);
    if GetTextExtentPoint32(DC, PChar(S), Length(S), Sz) then
      Result := Sz.cx;
    SelectObject(DC, Old);
  finally
    ReleaseDC(0, DC);
  end;
end;

const
  TextFlagsLeft = DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS;

function CellPad(const Ctx: TPPGCellKindContext): Integer;
begin
  Result := PPGScale(6, Ctx.PPI);
end;

{ TPPGCellKindBase }

procedure TPPGCellKindBase.PaintCell(const Ctx: TPPGCellKindContext; const R: TRect;
  const Text: string);
var
  TR: TRect;
begin
  TR := R;
  InflateRect(TR, -CellPad(Ctx), 0);
  PPGCellDrawText(Ctx, Text, TR, Ctx.TextColor, TextFlagsLeft);
end;

function TPPGCellKindBase.CellClick(const Ctx: TPPGCellKindContext; const R: TRect;
  const P: TPoint; const Text: string; out NewText: string): TPPGCellAction;
begin
  NewText := Text;
  Result := caNone;
end;

function TPPGCellKindBase.CellKey(const Ctx: TPPGCellKindContext; Key: Word;
  const Text: string; out NewText: string): TPPGCellAction;
begin
  NewText := Text;
  Result := caNone;
end;

function TPPGCellKindBase.CellCursor(const Ctx: TPPGCellKindContext; const R: TRect;
  const P: TPoint; const Text: string): TCursor;
begin
  Result := crDefault;
end;

function TPPGCellKindBase.CellAccText(const Ctx: TPPGCellKindContext; const Text: string): string;
begin
  Result := Text;
end;

type
  { Kaestchen: '1'/'True'/'Ja' = an }
  TPPGCheckCellKind = class(TPPGCellKindBase)
  public
    procedure PaintCell(const Ctx: TPPGCellKindContext; const R: TRect; const Text: string); override;
    function CellClick(const Ctx: TPPGCellKindContext; const R: TRect; const P: TPoint;
      const Text: string; out NewText: string): TPPGCellAction; override;
    function CellKey(const Ctx: TPPGCellKindContext; Key: Word; const Text: string;
      out NewText: string): TPPGCellAction; override;
  end;

  { Fortschritt: Zahl zwischen MinValue und MaxValue (Vorgabe 0..100) }
  TPPGProgressCellKind = class(TPPGCellKindBase)
  private
    function Fraction(const Ctx: TPPGCellKindContext; const Text: string; out V: Double): Double;
  public
    procedure PaintCell(const Ctx: TPPGCellKindContext; const R: TRect; const Text: string); override;
    function CellAccText(const Ctx: TPPGCellKindContext; const Text: string): string; override;
  end;

  { Sparkline: Werte "3;5;2.5" }
  TPPGSparklineCellKind = class(TPPGCellKindBase)
  public
    procedure PaintCell(const Ctx: TPPGCellKindContext; const R: TRect; const Text: string); override;
    function CellAccText(const Ctx: TPPGCellKindContext; const Text: string): string; override;
  end;

  { Bewertung: 0..MaxValue Sterne (Vorgabe 5) }
  TPPGRatingCellKind = class(TPPGCellKindBase)
  private
    function StarCount(const Ctx: TPPGCellKindContext): Integer;
    function StarRect(const Ctx: TPPGCellKindContext; const R: TRect; Index: Integer): TRect;
  public
    procedure PaintCell(const Ctx: TPPGCellKindContext; const R: TRect; const Text: string); override;
    function CellClick(const Ctx: TPPGCellKindContext; const R: TRect; const P: TPoint;
      const Text: string; out NewText: string): TPPGCellAction; override;
    function CellKey(const Ctx: TPPGCellKindContext; Key: Word; const Text: string;
      out NewText: string): TPPGCellAction; override;
    function CellCursor(const Ctx: TPPGCellKindContext; const R: TRect; const P: TPoint;
      const Text: string): TCursor; override;
    function CellAccText(const Ctx: TPPGCellKindContext; const Text: string): string; override;
  end;

  { Bild: Index in Grid.Images }
  TPPGImageCellKind = class(TPPGCellKindBase)
  public
    procedure PaintCell(const Ctx: TPPGCellKindContext; const R: TRect; const Text: string); override;
  end;

  { Link: Text als Link, Klick/Enter -> OnLinkClick }
  TPPGLinkCellKind = class(TPPGCellKindBase)
  private
    FFont: TFont;
    FBaseHandle: HFONT; // Schrift, aus der FFont zuletzt abgeleitet wurde
    function LinkFont(const Ctx: TPPGCellKindContext): TFont;
    function TextRect(const Ctx: TPPGCellKindContext; const R: TRect; const Text: string): TRect;
  public
    destructor Destroy; override;
    procedure PaintCell(const Ctx: TPPGCellKindContext; const R: TRect; const Text: string); override;
    function CellClick(const Ctx: TPPGCellKindContext; const R: TRect; const P: TPoint;
      const Text: string; out NewText: string): TPPGCellAction; override;
    function CellKey(const Ctx: TPPGCellKindContext; Key: Word; const Text: string;
      out NewText: string): TPPGCellAction; override;
    function CellCursor(const Ctx: TPPGCellKindContext; const R: TRect; const P: TPoint;
      const Text: string): TCursor; override;
  end;

  { Button: Beschriftung = Text, Klick/Leertaste -> OnCellButtonClick }
  TPPGButtonCellKind = class(TPPGCellKindBase)
  private
    function ButtonRect(const Ctx: TPPGCellKindContext; const R: TRect): TRect;
  public
    procedure PaintCell(const Ctx: TPPGCellKindContext; const R: TRect; const Text: string); override;
    function CellClick(const Ctx: TPPGCellKindContext; const R: TRect; const P: TPoint;
      const Text: string; out NewText: string): TPPGCellAction; override;
    function CellKey(const Ctx: TPPGCellKindContext; Key: Word; const Text: string;
      out NewText: string): TPPGCellAction; override;
    function CellCursor(const Ctx: TPPGCellKindContext; const R: TRect; const P: TPoint;
      const Text: string): TCursor; override;
  end;

  { Farbfeld: Farbe + Text }
  TPPGColorCellKind = class(TPPGCellKindBase)
  public
    procedure PaintCell(const Ctx: TPPGCellKindContext; const R: TRect; const Text: string); override;
  end;

  { Markup: <b>, <i>, <font color>, <a href> ... }
  TPPGMarkupCellKind = class(TPPGCellKindBase)
  private
    FLayout: TPPGMarkupLayout;
    function Origin(const Ctx: TPPGCellKindContext; const R: TRect): TPoint;
  public
    constructor Create;
    destructor Destroy; override;
    procedure PaintCell(const Ctx: TPPGCellKindContext; const R: TRect; const Text: string); override;
    function CellClick(const Ctx: TPPGCellKindContext; const R: TRect; const P: TPoint;
      const Text: string; out NewText: string): TPPGCellAction; override;
    function CellCursor(const Ctx: TPPGCellKindContext; const R: TRect; const P: TPoint;
      const Text: string): TCursor; override;
    function CellAccText(const Ctx: TPPGCellKindContext; const Text: string): string; override;
  end;

function PPGCellKindIsBuiltIn(const Kind: IPPGCellKind): Boolean;
var
  O: TObject;
begin
  Result := False;
  if Kind = nil then
    Exit;
  O := Kind as TObject;
  Result := (O.ClassType = TPPGCheckCellKind) or (O.ClassType = TPPGProgressCellKind) or
    (O.ClassType = TPPGSparklineCellKind) or (O.ClassType = TPPGRatingCellKind) or
    (O.ClassType = TPPGImageCellKind) or (O.ClassType = TPPGLinkCellKind) or
    (O.ClassType = TPPGButtonCellKind) or (O.ClassType = TPPGColorCellKind) or
    (O.ClassType = TPPGMarkupCellKind);
end;

{ TPPGCheckCellKind }

procedure TPPGCheckCellKind.PaintCell(const Ctx: TPPGCellKindContext; const R: TRect;
  const Text: string);
begin
  if TPPGCellPainter.IsCheckedText(Text) then
    Ctx.Painter.DrawCheck(Ctx.Canvas, R, True, Ctx.CheckedStyle, Ctx.PPI)
  else
    Ctx.Painter.DrawCheck(Ctx.Canvas, R, False, Ctx.UncheckedStyle, Ctx.PPI);
end;

function TPPGCheckCellKind.CellClick(const Ctx: TPPGCellKindContext; const R: TRect;
  const P: TPoint; const Text: string; out NewText: string): TPPGCellAction;
var
  B: TRect;
begin
  // Nur das Kaestchen (mit etwas Rand) schaltet um
  B := Rect((R.Left + R.Right) div 2 - PPGScale(10, Ctx.PPI), R.Top,
    (R.Left + R.Right) div 2 + PPGScale(10, Ctx.PPI), R.Bottom);
  NewText := Text;
  Result := caNone;
  if PtInRect(B, P) then
    Result := CellKey(Ctx, VK_SPACE, Text, NewText);
end;

function TPPGCheckCellKind.CellKey(const Ctx: TPPGCellKindContext; Key: Word;
  const Text: string; out NewText: string): TPPGCellAction;
begin
  NewText := Text;
  Result := caNone;
  if Key <> VK_SPACE then
    Exit;
  if TPPGCellPainter.IsCheckedText(Text) then
    NewText := '0'
  else
    NewText := '1';
  Result := caSetValue;
end;

{ TPPGProgressCellKind }

function TPPGProgressCellKind.Fraction(const Ctx: TPPGCellKindContext; const Text: string;
  out V: Double): Double;
var
  Lo, Hi: Double;
begin
  Lo := Ctx.MinValue;
  Hi := Ctx.MaxValue;
  if Hi <= Lo then
  begin
    Lo := 0;
    Hi := 100;
  end;
  if not TryStrToFloat(Text, V) then
    V := Lo;
  Result := (V - Lo) / (Hi - Lo);
  if Result < 0 then
    Result := 0;
  if Result > 1 then
    Result := 1;
end;

procedure TPPGProgressCellKind.PaintCell(const Ctx: TPPGCellKindContext; const R: TRect;
  const Text: string);
var
  F, V: Double;
  Bar, Track, TR: TRect;
  H, TW, Pad: Integer;
  S: string;
begin
  if Text = '' then
    Exit;
  F := Fraction(Ctx, Text, V);
  Pad := CellPad(Ctx);
  S := Format(PPGStr(@SPPGPercentFormat), [Round(F * 100)]);
  TW := TextWidth(Ctx, '100 %') + Pad;
  H := PPGScale(6, Ctx.PPI);
  Track := Rect(R.Left + Pad, (R.Top + R.Bottom - H) div 2, R.Right - TW - Pad,
    (R.Top + R.Bottom - H) div 2 + H);
  if Ctx.RightToLeft then
    Track := Rect(R.Left + TW + Pad, Track.Top, R.Right - Pad, Track.Bottom);
  if Track.Right - Track.Left < PPGScale(12, Ctx.PPI) then
  begin
    // Zu schmal fuer einen Balken: nur die Zahl
    TR := R;
    InflateRect(TR, -Pad, 0);
    PPGCellDrawText(Ctx, S, TR, Ctx.TextColor, TextFlagsLeft or DT_RIGHT);
    Exit;
  end;
  Ctx.Canvas.FillRoundRect(Track, H div 2, Ctx.LineColor, 255);
  Bar := Track;
  if Ctx.RightToLeft then
    Bar.Left := Bar.Right - Round((Track.Right - Track.Left) * F)
  else
    Bar.Right := Bar.Left + Round((Track.Right - Track.Left) * F);
  if Bar.Right > Bar.Left then
    Ctx.Canvas.FillRoundRect(Bar, H div 2, Ctx.AccentColor, 255);
  if Ctx.RightToLeft then
    TR := Rect(R.Left + Pad, R.Top, Track.Left - Pad div 2, R.Bottom)
  else
    TR := Rect(Track.Right + Pad div 2, R.Top, R.Right - Pad, R.Bottom);
  PPGCellDrawText(Ctx, S, TR, Ctx.TextColor, TextFlagsLeft or DT_RIGHT);
end;

function TPPGProgressCellKind.CellAccText(const Ctx: TPPGCellKindContext;
  const Text: string): string;
var
  V: Double;
begin
  if Text = '' then
    Result := ''
  else
    Result := Format(PPGStr(@SPPGPercentFormat), [Round(Fraction(Ctx, Text, V) * 100)]);
end;

{ TPPGSparklineCellKind }

procedure TPPGSparklineCellKind.PaintCell(const Ctx: TPPGCellKindContext; const R: TRect;
  const Text: string);
var
  Values: TArray<Double>;
  Opt: TPPGSparklineOptions;
  SR: TRect;
begin
  if not PPGParseValueList(Text, Values) or (Length(Values) = 0) then
    Exit;
  Opt := PPGDefaultSparklineOptions(Ctx.Tokens, Ctx.FillColor, Ctx.PPI);
  SR := R;
  InflateRect(SR, -PPGScale(4, Ctx.PPI), -PPGScale(3, Ctx.PPI));
  PPGDrawSparkline(Ctx.Canvas, SR, Values, Opt);
end;

function TPPGSparklineCellKind.CellAccText(const Ctx: TPPGCellKindContext;
  const Text: string): string;
var
  Values: TArray<Double>;
begin
  Result := Text;
  if PPGParseValueList(Text, Values) and (Length(Values) > 0) then
    Result := Format(PPGStr(@SPPGSparklineSummary), [FloatToStr(MinValue(Values)),
      FloatToStr(MaxValue(Values)), FloatToStr(Values[High(Values)])]);
end;

{ TPPGRatingCellKind }

function TPPGRatingCellKind.StarCount(const Ctx: TPPGCellKindContext): Integer;
begin
  Result := Ctx.MaxValue;
  if Result <= 0 then
    Result := 5;
  if Result > 20 then
    Result := 20;
end;

function TPPGRatingCellKind.StarRect(const Ctx: TPPGCellKindContext; const R: TRect;
  Index: Integer): TRect;
var
  N, Sz, Gap, X: Integer;
begin
  N := StarCount(Ctx);
  Gap := PPGScale(2, Ctx.PPI);
  Sz := Min((R.Bottom - R.Top) - PPGScale(6, Ctx.PPI),
    ((R.Right - R.Left) - CellPad(Ctx) * 2 - Gap * (N - 1)) div N);
  if Sz < 4 then
    Sz := 4;
  X := R.Left + CellPad(Ctx) + Index * (Sz + Gap);
  if Ctx.RightToLeft then
    X := R.Right - CellPad(Ctx) - (Index + 1) * Sz - Index * Gap;
  Result := Rect(X, (R.Top + R.Bottom - Sz) div 2, X + Sz, (R.Top + R.Bottom - Sz) div 2 + Sz);
end;

procedure StarPoints(const R: TRect; out Pts: array of TPoint);
var
  I, CX, CY, RO, RI: Integer;
  A: Double;
begin
  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2 + (R.Bottom - R.Top) div 20;
  RO := (R.Right - R.Left) div 2;
  RI := Round(RO * 0.45);
  for I := 0 to 9 do
  begin
    A := (I * 36 - 90) * Pi / 180;
    if Odd(I) then
      Pts[I] := Point(CX + Round(RI * Cos(A)), CY + Round(RI * Sin(A)))
    else
      Pts[I] := Point(CX + Round(RO * Cos(A)), CY + Round(RO * Sin(A)));
  end;
  Pts[10] := Pts[0];
end;

procedure TPPGRatingCellKind.PaintCell(const Ctx: TPPGCellKindContext; const R: TRect;
  const Text: string);
var
  I, V: Integer;
  Pts: array[0..10] of TPoint;
begin
  V := StrToIntDef(Text, 0);
  for I := 0 to StarCount(Ctx) - 1 do
  begin
    StarPoints(StarRect(Ctx, R, I), Pts);
    if I < V then
      PPGFillPolygon(Ctx.Canvas, Pts, Ctx.Tokens.Warning, 255)
    else
      Ctx.Canvas.DrawPolyline(Pts, Max(1, PPGScale(1, Ctx.PPI)), Ctx.HintColor, 255);
  end;
end;

function TPPGRatingCellKind.CellClick(const Ctx: TPPGCellKindContext; const R: TRect;
  const P: TPoint; const Text: string; out NewText: string): TPPGCellAction;
var
  I: Integer;
begin
  NewText := Text;
  Result := caNone;
  for I := 0 to StarCount(Ctx) - 1 do
    if PtInRect(StarRect(Ctx, R, I), P) then
    begin
      // Klick auf den aktuellen Wert setzt auf 0 zurueck
      if StrToIntDef(Text, 0) = I + 1 then
        NewText := '0'
      else
        NewText := IntToStr(I + 1);
      Exit(caSetValue);
    end;
end;

function TPPGRatingCellKind.CellKey(const Ctx: TPPGCellKindContext; Key: Word;
  const Text: string; out NewText: string): TPPGCellAction;
begin
  NewText := Text;
  Result := caNone;
  if (Key >= Ord('0')) and (Key <= Ord('9')) and (Integer(Key - Ord('0')) <= StarCount(Ctx)) then
  begin
    NewText := IntToStr(Key - Ord('0'));
    Result := caSetValue;
  end;
end;

function TPPGRatingCellKind.CellCursor(const Ctx: TPPGCellKindContext; const R: TRect;
  const P: TPoint; const Text: string): TCursor;
var
  I: Integer;
begin
  Result := crDefault;
  for I := 0 to StarCount(Ctx) - 1 do
    if PtInRect(StarRect(Ctx, R, I), P) then
      Exit(crHandPoint);
end;

function TPPGRatingCellKind.CellAccText(const Ctx: TPPGCellKindContext;
  const Text: string): string;
begin
  Result := IntToStr(StrToIntDef(Text, 0)) + '/' + IntToStr(StarCount(Ctx));
end;

{ TPPGImageCellKind }

procedure TPPGImageCellKind.PaintCell(const Ctx: TPPGCellKindContext; const R: TRect;
  const Text: string);
var
  I: Integer;
begin
  I := StrToIntDef(Text, -1);
  if (Ctx.Images = nil) or (I < 0) or (I >= Ctx.Images.Count) then
    Exit;
  Ctx.Canvas.DrawImage(Ctx.Images, I, (R.Left + R.Right - Ctx.Images.Width) div 2,
    (R.Top + R.Bottom - Ctx.Images.Height) div 2, Ctx.Enabled);
end;

{ TPPGLinkCellKind }

destructor TPPGLinkCellKind.Destroy;
begin
  FreeAndNil(FFont);
  inherited Destroy;
end;

function TPPGLinkCellKind.LinkFont(const Ctx: TPPGCellKindContext): TFont;
begin
  if FFont = nil then
    FFont := TFont.Create;
  // Nur bei anderer Schrift neu ableiten (Audit 8c #9): sonst bekam jede
  // Zelle ein neues Schrift-Handle
  if (FBaseHandle = 0) or (FBaseHandle <> Ctx.Font.Handle) or (FFont.Name <> Ctx.Font.Name) or
    (FFont.Height <> Ctx.Font.Height) or (FFont.Style <> Ctx.Font.Style + [fsUnderline]) or
    (FFont.Charset <> Ctx.Font.Charset) or (FFont.PixelsPerInch <> Ctx.Font.PixelsPerInch) or
    (FFont.Quality <> Ctx.Font.Quality) or (FFont.Pitch <> Ctx.Font.Pitch) or
    (FFont.Orientation <> Ctx.Font.Orientation) then
  begin
    FFont.Assign(Ctx.Font);
    FFont.Style := FFont.Style + [fsUnderline];
    FBaseHandle := Ctx.Font.Handle;
  end;
  Result := FFont;
end;

function TPPGLinkCellKind.TextRect(const Ctx: TPPGCellKindContext; const R: TRect;
  const Text: string): TRect;
var
  W: Integer;
begin
  W := Min(TextWidth(Ctx, Text, LinkFont(Ctx)), (R.Right - R.Left) - 2 * CellPad(Ctx));
  if Ctx.RightToLeft then
    Result := Rect(R.Right - CellPad(Ctx) - W, R.Top, R.Right - CellPad(Ctx), R.Bottom)
  else
    Result := Rect(R.Left + CellPad(Ctx), R.Top, R.Left + CellPad(Ctx) + W, R.Bottom);
end;

procedure TPPGLinkCellKind.PaintCell(const Ctx: TPPGCellKindContext; const R: TRect;
  const Text: string);
var
  TR: TRect;
begin
  TR := R;
  InflateRect(TR, -CellPad(Ctx), 0);
  // Gesammelt mit der Link-Schrift (gehoert der Zellart, lebt ueber den Block)
  if (Ctx.Painter <> nil) and Ctx.Painter.CollectTexts and (Text <> '') and
    not IsRectEmpty(TR) then
  begin
    if Ctx.RightToLeft then
      Ctx.Painter.AddTextFont(TR, Text, Ctx.AccentColor, TextFlagsLeft or DT_RTLREADING,
        LinkFont(Ctx).Handle)
    else
      Ctx.Painter.AddTextFont(TR, Text, Ctx.AccentColor, TextFlagsLeft, LinkFont(Ctx).Handle);
    Exit;
  end;
  PPGCellDrawText(Ctx, Text, TR, Ctx.AccentColor, TextFlagsLeft, LinkFont(Ctx));
end;

function TPPGLinkCellKind.CellClick(const Ctx: TPPGCellKindContext; const R: TRect;
  const P: TPoint; const Text: string; out NewText: string): TPPGCellAction;
begin
  NewText := Text;
  if (Text <> '') and PtInRect(TextRect(Ctx, R, Text), P) then
    Result := caLink
  else
    Result := caNone;
end;

function TPPGLinkCellKind.CellKey(const Ctx: TPPGCellKindContext; Key: Word;
  const Text: string; out NewText: string): TPPGCellAction;
begin
  NewText := Text;
  if (Text <> '') and ((Key = VK_RETURN) or (Key = VK_SPACE)) then
    Result := caLink
  else
    Result := caNone;
end;

function TPPGLinkCellKind.CellCursor(const Ctx: TPPGCellKindContext; const R: TRect;
  const P: TPoint; const Text: string): TCursor;
begin
  if (Text <> '') and PtInRect(TextRect(Ctx, R, Text), P) then
    Result := crHandPoint
  else
    Result := crDefault;
end;

{ TPPGButtonCellKind }

function TPPGButtonCellKind.ButtonRect(const Ctx: TPPGCellKindContext; const R: TRect): TRect;
begin
  Result := R;
  InflateRect(Result, -PPGScale(4, Ctx.PPI), -PPGScale(3, Ctx.PPI));
end;

procedure TPPGButtonCellKind.PaintCell(const Ctx: TPPGCellKindContext; const R: TRect;
  const Text: string);
var
  B: TRect;
  S: string;
begin
  B := ButtonRect(Ctx, R);
  if IsRectEmpty(B) then
    Exit;
  Ctx.Canvas.FillRoundRect(B, PPGScale(4, Ctx.PPI), PPGBlendColor(Ctx.FillColor, Ctx.LineColor, 0.45), 255);
  Ctx.Canvas.FrameRoundRect(B, PPGScale(4, Ctx.PPI), PPGScale(4, Ctx.PPI), Ctx.LineColor, 255);
  S := Text;
  if S = '' then
    S := '...';
  PPGCellDrawText(Ctx, S, B, Ctx.TextColor,
    DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
end;

function TPPGButtonCellKind.CellClick(const Ctx: TPPGCellKindContext; const R: TRect;
  const P: TPoint; const Text: string; out NewText: string): TPPGCellAction;
begin
  NewText := Text;
  if PtInRect(ButtonRect(Ctx, R), P) then
    Result := caButton
  else
    Result := caNone;
end;

function TPPGButtonCellKind.CellKey(const Ctx: TPPGCellKindContext; Key: Word;
  const Text: string; out NewText: string): TPPGCellAction;
begin
  NewText := Text;
  if (Key = VK_SPACE) or (Key = VK_RETURN) then
    Result := caButton
  else
    Result := caNone;
end;

function TPPGButtonCellKind.CellCursor(const Ctx: TPPGCellKindContext; const R: TRect;
  const P: TPoint; const Text: string): TCursor;
begin
  if PtInRect(ButtonRect(Ctx, R), P) then
    Result := crHandPoint
  else
    Result := crDefault;
end;

{ TPPGColorCellKind }

procedure TPPGColorCellKind.PaintCell(const Ctx: TPPGCellKindContext; const R: TRect;
  const Text: string);
var
  C: TColor;
  Sw, TR: TRect;
  Sz, Pad: Integer;
begin
  if not PPGCellColor(Text, C) then
  begin
    inherited PaintCell(Ctx, R, Text);
    Exit;
  end;
  Pad := CellPad(Ctx);
  Sz := (R.Bottom - R.Top) - PPGScale(10, Ctx.PPI);
  if Sz < 6 then
    Sz := 6;
  if Ctx.RightToLeft then
    Sw := Rect(R.Right - Pad - Sz, (R.Top + R.Bottom - Sz) div 2, R.Right - Pad,
      (R.Top + R.Bottom - Sz) div 2 + Sz)
  else
    Sw := Rect(R.Left + Pad, (R.Top + R.Bottom - Sz) div 2, R.Left + Pad + Sz,
      (R.Top + R.Bottom - Sz) div 2 + Sz);
  Ctx.Canvas.FillRoundRect(Sw, PPGScale(2, Ctx.PPI), C, 255);
  Ctx.Canvas.FrameRoundRect(Sw, PPGScale(2, Ctx.PPI), PPGScale(2, Ctx.PPI), Ctx.LineColor, 255);
  TR := R;
  InflateRect(TR, -Pad, 0);
  if Ctx.RightToLeft then
    TR.Right := Sw.Left - Pad
  else
    TR.Left := Sw.Right + Pad;
  PPGCellDrawText(Ctx, Text, TR, Ctx.TextColor, TextFlagsLeft);
end;

{ TPPGMarkupCellKind }

constructor TPPGMarkupCellKind.Create;
begin
  inherited Create;
  FLayout := TPPGMarkupLayout.Create;
end;

destructor TPPGMarkupCellKind.Destroy;
begin
  FreeAndNil(FLayout);
  inherited Destroy;
end;

function TPPGMarkupCellKind.Origin(const Ctx: TPPGCellKindContext; const R: TRect): TPoint;
begin
  Result.Y := R.Top + ((R.Bottom - R.Top) - FLayout.Size.cy) div 2;
  if Ctx.RightToLeft then
    Result.X := R.Right - CellPad(Ctx) - FLayout.Size.cx
  else
    Result.X := R.Left + CellPad(Ctx);
end;

procedure TPPGMarkupCellKind.PaintCell(const Ctx: TPPGCellKindContext; const R: TRect;
  const Text: string);
var
  P: TPoint;
begin
  if Text = '' then
    Exit;
  FLayout.Layout(Text, Ctx.Font, Ctx.Images, 0, False);
  P := Origin(Ctx, R);
  Ctx.Canvas.PushClipRoundRect(R, 0);
  try
    FLayout.Draw(Ctx.Canvas, P.X, P.Y, Ctx.TextColor, Ctx.AccentColor, Ctx.Enabled);
  finally
    Ctx.Canvas.PopClip;
  end;
end;

function TPPGMarkupCellKind.CellClick(const Ctx: TPPGCellKindContext; const R: TRect;
  const P: TPoint; const Text: string; out NewText: string): TPPGCellAction;
var
  O: TPoint;
begin
  NewText := Text;
  Result := caNone;
  if Text = '' then
    Exit;
  FLayout.Layout(Text, Ctx.Font, Ctx.Images, 0, False);
  O := Origin(Ctx, R);
  NewText := FLayout.LinkAt(P.X - O.X, P.Y - O.Y);
  if NewText <> '' then
    Result := caLink
  else
    NewText := Text;
end;

function TPPGMarkupCellKind.CellCursor(const Ctx: TPPGCellKindContext; const R: TRect;
  const P: TPoint; const Text: string): TCursor;
var
  O: TPoint;
begin
  Result := crDefault;
  if Text = '' then
    Exit;
  FLayout.Layout(Text, Ctx.Font, Ctx.Images, 0, False);
  O := Origin(Ctx, R);
  if FLayout.LinkAt(P.X - O.X, P.Y - O.Y) <> '' then
    Result := crHandPoint;
end;

function TPPGMarkupCellKind.CellAccText(const Ctx: TPPGCellKindContext;
  const Text: string): string;
begin
  Result := PPGStripMarkup(Text);
end;

initialization
  GNamed := TDictionary<string, IPPGCellKind>.Create;
  PPGRegisterCellKind(ckCheck, TPPGCheckCellKind.Create);
  PPGRegisterCellKind(ckProgress, TPPGProgressCellKind.Create);
  PPGRegisterCellKind(ckSparkline, TPPGSparklineCellKind.Create);
  PPGRegisterCellKind(ckRating, TPPGRatingCellKind.Create);
  PPGRegisterCellKind(ckImage, TPPGImageCellKind.Create);
  PPGRegisterCellKind(ckLink, TPPGLinkCellKind.Create);
  PPGRegisterCellKind(ckButton, TPPGButtonCellKind.Create);
  PPGRegisterCellKind(ckColor, TPPGColorCellKind.Create);
  PPGRegisterCellKind(ckMarkup, TPPGMarkupCellKind.Create);

finalization
  ClearKinds;
  FreeAndNil(GNamed);

end.
