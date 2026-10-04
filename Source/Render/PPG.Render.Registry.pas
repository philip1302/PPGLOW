unit PPG.Render.Registry;

{ Registry fuer Renderer (Open/Closed-Prinzip): Neue Optiken werden per
  RegisterRenderer hinzugefuegt, ohne ein Control zu aendern.

  Ausserdem Canvas-Fabrik: liefert GDI+ oder - falls nicht verfuegbar bzw.
  erzwungen - den GDI-Fallback. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.Types, Vcl.Graphics, Vcl.StdCtrls,
  PPG.Types, PPG.Appearance, PPG.Tokens, PPG.Render.Intf;

type
  /// Basisklasse fuer Renderer: zustandslos, wird von allen Controls geteilt.
  TPPGRendererBase = class(TInterfacedObject, IPPGRenderer, IPPGIndicatorRenderer,
    IPPGRangeRenderer, IPPGContainerRenderer, IPPGFieldRenderer, IPPGListRenderer, IPPGTabRenderer, IPPGScrollRenderer,
    IPPGThemeRenderer, IPPGItemRenderer)
  public
    constructor Create; virtual;
    function Name: string; virtual; abstract;
    procedure ApplyDefaults(Appearance: TPPGAppearance); virtual; abstract;
    { IPPGThemeRenderer - Standard: neutrale Windows-11-Palette und die
      Abbildung Ruhe/Hover/Druck/Deaktiviert/An auf die Appearance }
    function Tokens(Dark: Boolean): TPPGTokens; virtual;
    procedure ApplyThemeColors(Appearance: TPPGAppearance; Dark: Boolean); virtual;
    function BodyInset(const Style: TPPGSurfaceStyle): Integer; virtual;
    procedure DrawSurface(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle); virtual; abstract;
    procedure DrawFocus(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle); virtual;
    procedure DrawCheckMark(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      PPI: Integer); virtual;
    { IPPGIndicatorRenderer - Standard-Darstellung auf Basis von DrawSurface }
    procedure DrawCheckIndicator(const Canvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; State: TPPGCheckState; PPI: Integer); virtual;
    procedure DrawRadioIndicator(const Canvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; Checked: Boolean; PPI: Integer); virtual;
    procedure DrawSwitch(const Canvas: IPPGCanvas; const Track: TRect;
      const Style: TPPGSurfaceStyle; Position: Single; RightToLeft: Boolean;
      PPI: Integer); virtual;
    { IPPGRangeRenderer }
    procedure DrawProgress(const Canvas: IPPGCanvas; const Track, Fill: TRect;
      const TrackStyle, FillStyle: TPPGSurfaceStyle; PPI: Integer); virtual;
    procedure DrawSliderTrack(const Canvas: IPPGCanvas; const Track, Fill: TRect;
      const TrackStyle, FillStyle: TPPGSurfaceStyle; PPI: Integer); virtual;
    procedure DrawSliderThumb(const Canvas: IPPGCanvas; const Thumb: TRect;
      const Style: TPPGSurfaceStyle; Accent: TColor; HotProgress: Single;
      PPI: Integer); virtual;
    { IPPGContainerRenderer }
    procedure DrawContainer(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle); virtual;
    { IPPGFieldRenderer - Standard: Fluent-Feld mit Akzentlinie unten }
    procedure DrawField(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle; FocusProgress: Single; PPI: Integer); virtual;
    procedure DrawFieldButton(const Canvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; Glyph: TPPGFieldGlyph; Hot, Pressed: Boolean;
      PPI: Integer); virtual;
    /// Zeichnet nur das Symbol eines Feld-Buttons (fuer eigene Hintergruende).
    procedure DrawFieldGlyph(const Canvas: IPPGCanvas; const R: TRect;
      Glyph: TPPGFieldGlyph; Color: TColor; PPI: Integer); virtual;
    { IPPGListRenderer - Standard: Fluent-Liste (Hover-Pille, Akzentbalken) }
    procedure DrawPopupFrame(const Canvas: IPPGCanvas; const R: TRect;
      const ListStyle: TPPGSurfaceStyle; PPI: Integer); virtual;
    procedure DrawListItem(const Canvas: IPPGCanvas; const R: TRect;
      const ListStyle, HighlightStyle: TPPGSurfaceStyle; Selected: Boolean;
      Highlight: Single; PPI: Integer); virtual;
    procedure DrawScrollThumb(const Canvas: IPPGCanvas; const Track, Thumb: TRect;
      const ListStyle: TPPGSurfaceStyle; Hot: Boolean; PPI: Integer); virtual;
    procedure DrawDropArrow(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      Rotation: Single; PPI: Integer); virtual;
    { IPPGTabRenderer - Standard: flache Reiter, gleitender Akzent-Unterstrich }
    procedure DrawTabStrip(const Canvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; Bottom: Boolean; PPI: Integer); virtual;
    procedure DrawTab(const Canvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; Selected: Boolean; HotProgress: Single;
      Bottom: Boolean; PPI: Integer); virtual;
    procedure DrawTabIndicator(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      Bottom: Boolean; PPI: Integer); virtual;
    procedure DrawTabClose(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      Hot: Boolean; PPI: Integer); virtual;
    procedure DrawTabScrollArrow(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      Forward, Hot, Enabled: Boolean; PPI: Integer); virtual;
    { IPPGScrollRenderer - Standard: Fluent-Overlay }
    procedure DrawScrollBar(const Canvas: IPPGCanvas; const Track, Thumb: TRect;
      const Style: TPPGSurfaceStyle; Vertical: Boolean; Expand: Single;
      Hot, Pressed: Boolean; PPI: Integer); virtual;
    { IPPGItemRenderer - Standard: Fluent-Eintraege (Pille, Akzentbalken) }
    procedure DrawItemBackground(const Canvas: IPPGCanvas; const R: TRect;
      const ListStyle, HighlightStyle: TPPGSurfaceStyle; Selected, Focused: Boolean;
      Hot: Single; RightToLeft: Boolean; PPI: Integer); virtual;
    procedure DrawGroupHeader(const Canvas: IPPGCanvas; const R: TRect; const Text: string;
      Font: TFont; const ListStyle: TPPGSurfaceStyle; RightToLeft: Boolean; PPI: Integer); virtual;
    function BadgeSize(const Canvas: IPPGCanvas; const Text: string; Font: TFont;
      PPI: Integer): TSize; virtual;
    procedure DrawBadge(const Canvas: IPPGCanvas; const R: TRect; const Text: string;
      Font: TFont; Fill, TextColor: TColor; PPI: Integer); virtual;
    procedure DrawExpander(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      Expanded: Single; RightToLeft: Boolean; PPI: Integer); virtual;
    procedure DrawTreeLine(const Canvas: IPPGCanvas; const Points: array of TPoint;
      Color: TColor; PPI: Integer); virtual;
    procedure DrawDropIndicator(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      PPI: Integer); virtual;
  end;

  TPPGRendererClass = class of TPPGRendererBase;

  TPPGRendererRegistry = class
  private
    class var FForceGdiFallback: Boolean;
  public
    class procedure RegisterRenderer(const AName: string; AClass: TPPGRendererClass); static;
    class procedure UnregisterRenderer(const AName: string); static;
    /// nil, wenn unbekannt
    class function Find(const AName: string): IPPGRenderer; static;
    /// EPPGConfigError, wenn unbekannt
    class function Get(const AName: string): IPPGRenderer; static;
    class function IsRegistered(const AName: string): Boolean; static;
    class procedure GetNames(List: TStrings); static;
    class function DefaultName: string; static;

    /// Erzeugt einen Zeichen-Canvas fuer den DC (GDI+ oder GDI-Fallback).
    class function CreateCanvas(DC: HDC): IPPGCanvas; static;
    /// Erzwingt den GDI-Fallback (Tests, Terminalserver-Policies, Diagnose).
    class property ForceGdiFallback: Boolean read FForceGdiFallback write FForceGdiFallback;
  end;

/// Begrenzt die Rundung auf die halbe kurze Seite (Pillenform als Maximum).
function PPGCapRounding(const R: TRect; Rounding: Integer): Integer;

implementation

uses
  PPG.Lang,
  System.SysUtils, PPG.Consts, PPG.Exceptions, PPG.ErrorHandler,
  PPG.Render.Gdi, PPG.Render.GdiPlus;

type
  TRendererEntry = class
  public
    RendererClass: TPPGRendererClass;
    Instance: IPPGRenderer;
  end;

var
  GEntries: TStringList = nil;
  GCanvasFallbackLogged: Boolean = False;

function Entries: TStringList;
begin
  if GEntries = nil then
  begin
    GEntries := TStringList.Create;
    GEntries.CaseSensitive := False;
    GEntries.Sorted := True;
    GEntries.Duplicates := dupError;
    GEntries.OwnsObjects := True;
  end;
  Result := GEntries;
end;

{ TPPGRendererBase }

constructor TPPGRendererBase.Create;
begin
  inherited Create;
end;

function TPPGRendererBase.Tokens(Dark: Boolean): TPPGTokens;
begin
  Result := PPGDefaultTokens(Dark);
end;

procedure TPPGRendererBase.ApplyThemeColors(Appearance: TPPGAppearance; Dark: Boolean);
var
  T: TPPGTokens;
begin
  T := Tokens(Dark);
  Appearance.BeginUpdate;
  try
    // Nur Farben; die Glow-Staerken gehoeren zur Form des Presets und bleiben
    Appearance.Normal.SetAll(T.Surface, T.Surface, T.Surface, T.Surface,
      T.Stroke, T.Accent, T.TextPrimary, Appearance.Normal.GlowAlpha);
    Appearance.Hot.SetAll(T.SurfaceHover, T.SurfaceHover, T.SurfaceHover, T.SurfaceHover,
      T.Accent, T.Accent, T.TextPrimary, Appearance.Hot.GlowAlpha);
    Appearance.Down.SetAll(T.SurfacePressed, T.SurfacePressed, T.SurfacePressed,
      T.SurfacePressed, T.AccentPressed, T.Accent, T.TextPrimary, Appearance.Down.GlowAlpha);
    Appearance.Disabled.SetAll(T.SurfaceDisabled, T.SurfaceDisabled, T.SurfaceDisabled,
      T.SurfaceDisabled, T.StrokeDisabled, T.StrokeDisabled, T.TextDisabled,
      Appearance.Disabled.GlowAlpha);
    Appearance.Checked.SetAll(T.Accent, T.Accent, T.Accent, T.Accent,
      T.Accent, T.Accent, T.OnAccent, Appearance.Checked.GlowAlpha);
    Appearance.FocusColor := T.Accent;
  finally
    Appearance.EndUpdate;
  end;
end;

function TPPGRendererBase.BodyInset(const Style: TPPGSurfaceStyle): Integer;
begin
  Result := 0;
end;

procedure TPPGRendererBase.DrawFocus(const Canvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle);
var
  W: Integer;
begin
  // Fokus = durchgehend verstaerkter Rand in Fokusfarbe (Style.BorderColor ist
  // bei Fokus bereits die FocusColor). Bewusst EIN Strich ueber den
  // vorhandenen Rand nach innen: ein separater innerer Ring wuerde eine
  // Luecke (blau-weiss-blau) bzw. Antialiasing-Naehte in den Rundungen erzeugen.
  W := Style.BorderWidth;
  if W < 1 then
    W := 1;
  Canvas.FrameRoundRect(Body, Style.Rounding, W * 2, Style.BorderColor, 255);
end;

procedure TPPGRendererBase.DrawCheckMark(const Canvas: IPPGCanvas; const R: TRect;
  Color: TColor; PPI: Integer);
var
  W, H: Integer;
  Pts: array[0..2] of TPoint;
begin
  W := R.Right - R.Left;
  H := R.Bottom - R.Top;
  if (W <= 2) or (H <= 2) then
    Exit;
  Pts[0] := Point(R.Left + Round(W * 0.22), R.Top + Round(H * 0.52));
  Pts[1] := Point(R.Left + Round(W * 0.42), R.Top + Round(H * 0.72));
  Pts[2] := Point(R.Left + Round(W * 0.78), R.Top + Round(H * 0.30));
  Canvas.DrawPolyline(Pts, PPGScale(2, PPI), Color, 255);
end;

/// Rand eines leeren Kaestchens/Kreises. Auf dunklen Flaechen ist der normale
/// Rand (Stroke) zu zart: dort mindestens 3:1 zur Flaeche (WCAG 1.4.11),
/// indem er Richtung Textfarbe gemischt wird. Helle Flaechen bleiben unveraendert.
function IndicatorBorder(const S: TPPGSurfaceStyle): TColor;
var
  I: Integer;
begin
  Result := S.BorderColor;
  if S.Focused or (PPGRelativeLuminance(S.Color) >= 0.2) then
    Exit;
  for I := 1 to 10 do
  begin
    if PPGContrastRatio(Result, S.Color) >= 3.0 then
      Exit;
    Result := PPGBlendColor(Result, S.TextColor, 0.15);
  end;
end;

/// Fokus eines GEFUELLTEN Indikators (angehakt/an): Die Fuellung hat oft schon die
/// Akzent- = Fokusfarbe, ein verstaerkter Rand waere unsichtbar. Deshalb ein Ring
/// mit 1 px Abstand aussen (Platz: IndicatorMargin des Controls).
procedure DrawOuterFocusRing(const Canvas: IPPGCanvas; const R: TRect; Rounding: Integer;
  Color: TColor; PPI: Integer);
var
  Ring: TRect;
  G, W: Integer;
begin
  G := PPGScale(1, PPI);
  W := PPGScale(2, PPI);
  if W < 2 then
    W := 2;
  Ring := R;
  InflateRect(Ring, G + W, G + W);
  Canvas.FrameRoundRect(Ring, Rounding + G + W, W, Color, 255);
end;

procedure TPPGRendererBase.DrawCheckIndicator(const Canvas: IPPGCanvas; const R: TRect;
  const Style: TPPGSurfaceStyle; State: TPPGCheckState; PPI: Integer);
var
  S: TPPGSurfaceStyle;
  Inner: TRect;
  D: Integer;
begin
  if IsRectEmpty(R) then
    Exit;
  S := Style;
  // Kaestchen nur leicht abgerundet, unabhaengig vom Button-Rounding
  if S.Rounding > PPGScale(4, PPI) then
    S.Rounding := PPGScale(4, PPI);
  if State <> cbChecked then
    S.BorderColor := IndicatorBorder(S);
  DrawSurface(Canvas, R, S);
  case State of
    cbChecked:
      DrawCheckMark(Canvas, R, S.TextColor, PPI);
    cbGrayed:
      begin
        Inner := R;
        D := (R.Right - R.Left) div 4;
        InflateRect(Inner, -D, -D);
        Canvas.FillRoundRect(Inner, PPGScale(1, PPI), S.TextColor, 255);
      end;
  end;
  if S.Focused and (State <> cbUnchecked) then
    DrawOuterFocusRing(Canvas, R, S.Rounding, S.BorderColor, PPI)
  else if S.Focused then
    DrawFocus(Canvas, R, S);
end;

procedure TPPGRendererBase.DrawRadioIndicator(const Canvas: IPPGCanvas; const R: TRect;
  const Style: TPPGSurfaceStyle; Checked: Boolean; PPI: Integer);
var
  S: TPPGSurfaceStyle;
  Dot: TRect;
  D: Integer;
begin
  if IsRectEmpty(R) then
    Exit;
  S := Style;
  S.Rounding := (R.Right - R.Left) div 2; // Kreis
  if not Checked then
    S.BorderColor := IndicatorBorder(S);
  DrawSurface(Canvas, R, S);
  if Checked then
  begin
    Dot := R;
    D := Round((R.Right - R.Left) * 0.3);
    InflateRect(Dot, -D, -D);
    if not IsRectEmpty(Dot) then
      Canvas.FillEllipse(Dot, S.TextColor, 255);
  end;
  if S.Focused and Checked then
    DrawOuterFocusRing(Canvas, R, S.Rounding, S.BorderColor, PPI)
  else if S.Focused then
    DrawFocus(Canvas, R, S);
end;

procedure TPPGRendererBase.DrawSwitch(const Canvas: IPPGCanvas; const Track: TRect;
  const Style: TPPGSurfaceStyle; Position: Single; RightToLeft: Boolean; PPI: Integer);
var
  S: TPPGSurfaceStyle;
  Inset, D, Travel, X: Integer;
  Thumb: TRect;
begin
  if IsRectEmpty(Track) then
    Exit;
  S := Style;
  S.Rounding := (Track.Bottom - Track.Top) div 2; // Pillenform
  DrawSurface(Canvas, Track, S);
  Inset := PPGScale(4, PPI);
  D := (Track.Bottom - Track.Top) - 2 * Inset;
  if D <= 0 then
    Exit;
  Travel := (Track.Right - Track.Left) - 2 * Inset - D;
  if Travel < 0 then
    Travel := 0;
  if RightToLeft then
    Position := 1 - Position;
  X := Track.Left + Inset + Round(Travel * PPGClampSingle(Position, 0, 1));
  Thumb := Rect(X, Track.Top + Inset, X + D, Track.Top + Inset + D);
  Canvas.FillEllipse(Thumb, S.TextColor, 255);
  // Die Spur ist (an wie aus) eine Flaeche: Fokus als Ring aussen
  if S.Focused then
    DrawOuterFocusRing(Canvas, Track, S.Rounding, S.BorderColor, PPI);
end;

function PPGCapRounding(const R: TRect; Rounding: Integer): Integer;
var
  M: Integer;
begin
  M := R.Right - R.Left;
  if R.Bottom - R.Top < M then
    M := R.Bottom - R.Top;
  M := M div 2;
  if M < 0 then
    M := 0;
  Result := Rounding;
  if Result > M then
    Result := M;
  if Result < 0 then
    Result := 0;
end;

procedure TPPGRendererBase.DrawProgress(const Canvas: IPPGCanvas; const Track, Fill: TRect;
  const TrackStyle, FillStyle: TPPGSurfaceStyle; PPI: Integer);
var
  T, F: TPPGSurfaceStyle;
  Inner: TRect;
  R: Integer;
begin
  if IsRectEmpty(Track) then
    Exit;
  T := TrackStyle;
  T.Rounding := PPGCapRounding(Track, T.Rounding);
  T.GlowAlpha := 0; // die Spur leuchtet nicht
  DrawSurface(Canvas, Track, T);
  if IsRectEmpty(Fill) then
    Exit;
  Inner := Track;
  InflateRect(Inner, -T.BorderWidth, -T.BorderWidth);
  if IsRectEmpty(Inner) then
    Exit;
  R := T.Rounding - T.BorderWidth;
  if R < 0 then
    R := 0;
  F := FillStyle;
  F.Rounding := PPGCapRounding(Fill, R);
  // Fuellung immer in der Form der Spur (Marquee ragt ueber die Enden hinaus)
  Canvas.PushClipRoundRect(Inner, R);
  try
    DrawSurface(Canvas, Fill, F);
  finally
    Canvas.PopClip;
  end;
end;

procedure TPPGRendererBase.DrawSliderTrack(const Canvas: IPPGCanvas; const Track, Fill: TRect;
  const TrackStyle, FillStyle: TPPGSurfaceStyle; PPI: Integer);
var
  R: Integer;
begin
  if IsRectEmpty(Track) then
    Exit;
  // Schmale Schiene: die kraeftigere Rahmenfarbe ist die sichtbare Farbe
  // (eine Verlaufs-/Glanzflaeche waere bei wenigen Pixeln nicht erkennbar).
  R := PPGCapRounding(Track, MaxInt);
  Canvas.FillRoundRect(Track, R, TrackStyle.BorderColor, 255);
  if not IsRectEmpty(Fill) then
    Canvas.FillRoundRect(Fill, PPGCapRounding(Fill, R), FillStyle.BorderColor, 255);
end;

procedure TPPGRendererBase.DrawSliderThumb(const Canvas: IPPGCanvas; const Thumb: TRect;
  const Style: TPPGSurfaceStyle; Accent: TColor; HotProgress: Single; PPI: Integer);
var
  S: TPPGSurfaceStyle;
  Dot: TRect;
  D: Integer;
begin
  if IsRectEmpty(Thumb) then
    Exit;
  S := Style;
  S.Rounding := PPGCapRounding(Thumb, MaxInt); // Kreis
  DrawSurface(Canvas, Thumb, S);
  // Innerer Punkt in Akzentfarbe, waechst beim Hover (Fluent-Schieberegler)
  Dot := Thumb;
  D := Round((Thumb.Right - Thumb.Left) * (0.30 - 0.06 * PPGClampSingle(HotProgress, 0, 1)));
  InflateRect(Dot, -D, -D);
  if not IsRectEmpty(Dot) then
    Canvas.FillEllipse(Dot, Accent, 255);
  if S.Focused then
    DrawFocus(Canvas, Thumb, S);
end;

procedure TPPGRendererBase.DrawContainer(const Canvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle);
begin
  if IsRectEmpty(Body) then
    Exit;
  // Grosse Flaeche: hoechstens ein dezenter Verlauf von oben nach unten,
  // keine Glanzkante (sonst wirkt ein Panel wie ein riesiger Button)
  if Style.Color = Style.ColorMirrorTo then
    Canvas.FillRoundRect(Body, Style.Rounding, Style.Color, 255)
  else
  begin
    Canvas.PushClipRoundRect(Body, Style.Rounding);
    try
      Canvas.FillGradientRect(Body, Style.Color, Style.ColorMirrorTo, gdVertical, 255);
    finally
      Canvas.PopClip;
    end;
  end;
  Canvas.FrameRoundRect(Body, Style.Rounding, Style.BorderWidth, Style.BorderColor, 255);
end;

procedure TPPGRendererBase.DrawField(const Canvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle; FocusProgress: Single; PPI: Integer);
var
  R, H: Integer;
  P: Single;
  Line: TRect;
begin
  if IsRectEmpty(Body) then
    Exit;
  R := PPGCapRounding(Body, Style.Rounding);
  Canvas.FillRoundRect(Body, R, Style.Color, 255);
  if Style.BorderWidth > 0 then
    Canvas.FrameRoundRect(Body, R, Style.BorderWidth, Style.BorderColor, 255);
  // Fluent-Feld: untere Kante etwas kraeftiger, bei Fokus eine Akzentlinie.
  // Beides in der Form des Felds (Rundung), deshalb mit Clip.
  P := PPGClampSingle(FocusProgress, 0, 1);
  Canvas.PushClipRoundRect(Body, R);
  try
    if Style.BorderWidth > 0 then
    begin
      Line := Rect(Body.Left, Body.Bottom - Style.BorderWidth, Body.Right, Body.Bottom);
      Canvas.FillRoundRect(Line, 0, PPGDarken(Style.BorderColor, 0.25), 255);
    end;
    if P > 0 then
    begin
      H := PPGScale(2, PPI);
      if H < Style.BorderWidth then
        H := Style.BorderWidth;
      Line := Rect(Body.Left, Body.Bottom - H, Body.Right, Body.Bottom);
      Canvas.FillRoundRect(Line, 0, Style.GlowColor, Round(255 * P));
    end;
  finally
    Canvas.PopClip;
  end;
end;

procedure TPPGRendererBase.DrawFieldButton(const Canvas: IPPGCanvas; const R: TRect;
  const Style: TPPGSurfaceStyle; Glyph: TPPGFieldGlyph; Hot, Pressed: Boolean;
  PPI: Integer);
var
  Alpha: Byte;
begin
  if IsRectEmpty(R) then
    Exit;
  // Dezente Flaeche in Symbolfarbe: passt zu hellen und dunklen Feldern
  if Pressed then
    Alpha := 56
  else if Hot then
    Alpha := 28
  else
    Alpha := 0;
  if Alpha > 0 then
    Canvas.FillRoundRect(R, PPGCapRounding(R, PPGScale(4, PPI)), Style.TextColor, Alpha);
  DrawFieldGlyph(Canvas, R, Glyph, Style.TextColor, PPI);
end;

procedure TPPGRendererBase.DrawFieldGlyph(const Canvas: IPPGCanvas; const R: TRect;
  Glyph: TPPGFieldGlyph; Color: TColor; PPI: Integer);
var
  CX, CY, S, Half, Quarter, W: Integer;
  Pts: array[0..2] of TPoint;
  Line: array[0..1] of TPoint;
begin
  if (Glyph = fgNone) or IsRectEmpty(R) then
    Exit;
  S := R.Right - R.Left;
  if R.Bottom - R.Top < S then
    S := R.Bottom - R.Top;
  S := Round(S * 0.42);
  if S > PPGScale(10, PPI) then
    S := PPGScale(10, PPI);
  if S < 4 then
    Exit;
  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;
  Half := S div 2;
  Quarter := S div 4;
  W := Round(1.5 * PPI / 96);
  if W < 1 then
    W := 1;
  case Glyph of
    fgClear:
      begin
        Line[0] := Point(CX - Half, CY - Half);
        Line[1] := Point(CX + Half, CY + Half);
        Canvas.DrawPolyline(Line, W, Color, 255);
        Line[0] := Point(CX + Half, CY - Half);
        Line[1] := Point(CX - Half, CY + Half);
        Canvas.DrawPolyline(Line, W, Color, 255);
      end;
    fgSpinUp:
      begin
        Pts[0] := Point(CX - Half, CY + Quarter);
        Pts[1] := Point(CX, CY - Quarter);
        Pts[2] := Point(CX + Half, CY + Quarter);
        Canvas.DrawPolyline(Pts, W, Color, 255);
      end;
    fgSpinDown, fgDropDown:
      begin
        Pts[0] := Point(CX - Half, CY - Quarter);
        Pts[1] := Point(CX, CY + Quarter);
        Pts[2] := Point(CX + Half, CY - Quarter);
        Canvas.DrawPolyline(Pts, W, Color, 255);
      end;
  end;
end;

{ IPPGListRenderer }

procedure TPPGRendererBase.DrawPopupFrame(const Canvas: IPPGCanvas; const R: TRect;
  const ListStyle: TPPGSurfaceStyle; PPI: Integer);
var
  Rad, W: Integer;
begin
  if IsRectEmpty(R) then
    Exit;
  Rad := PPGCapRounding(R, ListStyle.Rounding);
  W := ListStyle.BorderWidth;
  if W < 1 then
    W := 1;
  Canvas.FillRoundRect(R, Rad, ListStyle.Color, 255);
  Canvas.FrameRoundRect(R, Rad, W, ListStyle.BorderColor, 255);
end;

procedure TPPGRendererBase.DrawListItem(const Canvas: IPPGCanvas; const R: TRect;
  const ListStyle, HighlightStyle: TPPGSurfaceStyle; Selected: Boolean;
  Highlight: Single; PPI: Integer);
var
  Body, Bar: TRect;
  Rad, BarW, BarH: Integer;
  H: Single;
begin
  if IsRectEmpty(R) then
    Exit;
  // Fluent: abgesetzte, gerundete Pille statt Balken ueber die ganze Breite
  Body := R;
  InflateRect(Body, -PPGScale(4, PPI), -PPGScale(1, PPI));
  if IsRectEmpty(Body) then
    Body := R;
  Rad := PPGCapRounding(Body, PPGScale(4, PPI));
  H := PPGClampSingle(Highlight, 0, 1);
  if H > 0 then
    Canvas.FillRoundRect(Body, Rad, HighlightStyle.Color, Round(255 * H))
  else if Selected then
    Canvas.FillRoundRect(Body, Rad, ListStyle.TextColor, 14);
  if Selected then
  begin
    // Akzentbalken links (wie WinUI-Listen)
    BarW := PPGScale(3, PPI);
    BarH := (Body.Bottom - Body.Top) div 2;
    if BarH < PPGScale(6, PPI) then
      BarH := Body.Bottom - Body.Top;
    Bar.Left := Body.Left;
    Bar.Right := Body.Left + BarW;
    Bar.Top := (Body.Top + Body.Bottom - BarH) div 2;
    Bar.Bottom := Bar.Top + BarH;
    Canvas.FillRoundRect(Bar, BarW div 2, ListStyle.GlowColor, 255);
  end;
end;

procedure TPPGRendererBase.DrawScrollThumb(const Canvas: IPPGCanvas; const Track, Thumb: TRect;
  const ListStyle: TPPGSurfaceStyle; Hot: Boolean; PPI: Integer);
var
  T: TRect;
  W: Integer;
  Alpha: Byte;
begin
  if IsRectEmpty(Thumb) then
    Exit;
  T := Thumb;
  // Ruhend schmal, beim Ueberfahren volle Breite (Fluent-Scrollleiste)
  if not Hot then
  begin
    W := (T.Right - T.Left) div 2;
    if W < 2 then
      W := 2;
    T.Left := T.Right - W;
    Alpha := 90;
  end
  else
  begin
    Canvas.FillRoundRect(Track, PPGCapRounding(Track, Track.Right - Track.Left),
      ListStyle.TextColor, 16);
    Alpha := 150;
  end;
  Canvas.FillRoundRect(T, PPGCapRounding(T, T.Right - T.Left), ListStyle.TextColor, Alpha);
end;

procedure TPPGRendererBase.DrawDropArrow(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
  Rotation: Single; PPI: Integer);
var
  CX, CY, S, Half, Quarter, W, I: Integer;
  Src: array[0..2] of TPoint;
  Pts: array[0..2] of TPoint;
  A, C, Sn: Double;
begin
  if IsRectEmpty(R) then
    Exit;
  // Gleiche Groesse wie die Chevrons der Feld-Buttons (DrawFieldGlyph)
  S := R.Right - R.Left;
  if R.Bottom - R.Top < S then
    S := R.Bottom - R.Top;
  S := Round(S * 0.42);
  if S > PPGScale(10, PPI) then
    S := PPGScale(10, PPI);
  if S < 4 then
    Exit;
  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;
  Half := S div 2;
  Quarter := S div 4;
  W := Round(1.5 * PPI / 96);
  if W < 1 then
    W := 1;
  Src[0] := Point(-Half, -Quarter);
  Src[1] := Point(0, Quarter);
  Src[2] := Point(Half, -Quarter);
  A := PPGClampSingle(Rotation, 0, 1) * Pi;
  C := Cos(A);
  Sn := Sin(A);
  for I := 0 to 2 do
    Pts[I] := Point(CX + Round(Src[I].X * C - Src[I].Y * Sn),
      CY + Round(Src[I].X * Sn + Src[I].Y * C));
  Canvas.DrawPolyline(Pts, W, Color, 255);
end;

{ IPPGTabRenderer }

procedure TPPGRendererBase.DrawTabStrip(const Canvas: IPPGCanvas; const R: TRect;
  const Style: TPPGSurfaceStyle; Bottom: Boolean; PPI: Integer);
begin
  if IsRectEmpty(R) or (Style.Color = clNone) then
    Exit;
  Canvas.FillRoundRect(R, 0, Style.Color, 255);
end;

procedure TPPGRendererBase.DrawTab(const Canvas: IPPGCanvas; const R: TRect;
  const Style: TPPGSurfaceStyle; Selected: Boolean; HotProgress: Single;
  Bottom: Boolean; PPI: Integer);
var
  Body: TRect;
  Rad: Integer;
  H: Single;
begin
  if IsRectEmpty(R) then
    Exit;
  Rad := PPGCapRounding(R, PPGScale(6, PPI));
  if Selected then
  begin
    // Oben gerundet, zur Seite hin offen: Koerper ueber den Rand hinaus
    // verlaengern und auf R begrenzen (der Rahmen fehlt dann zur Seite hin)
    Body := R;
    if Bottom then
      Dec(Body.Top, Rad + 1)
    else
      Inc(Body.Bottom, Rad + 1);
    Canvas.PushClipRoundRect(R, 0);
    try
      Canvas.FillRoundRect(Body, Rad, Style.Color, 255);
      if Style.BorderWidth > 0 then
        Canvas.FrameRoundRect(Body, Rad, Style.BorderWidth, Style.BorderColor, 255);
    finally
      Canvas.PopClip;
    end;
    Exit;
  end;
  // Nicht gewaehlt: nur beim Hover eine dezente Flaeche (Fluent)
  H := PPGClampSingle(HotProgress, 0, 1);
  if H <= 0 then
    Exit;
  Body := R;
  InflateRect(Body, -PPGScale(2, PPI), -PPGScale(3, PPI));
  Canvas.FillRoundRect(Body, PPGCapRounding(Body, PPGScale(4, PPI)), Style.TextColor,
    Round(18 * H));
end;

procedure TPPGRendererBase.DrawTabIndicator(const Canvas: IPPGCanvas; const R: TRect;
  Color: TColor; Bottom: Boolean; PPI: Integer);
var
  M: Integer;
begin
  if IsRectEmpty(R) then
    Exit;
  M := R.Bottom - R.Top;
  if R.Right - R.Left < M then
    M := R.Right - R.Left;
  Canvas.FillRoundRect(R, M div 2, Color, 255);
end;

procedure TPPGRendererBase.DrawTabClose(const Canvas: IPPGCanvas; const R: TRect;
  Color: TColor; Hot: Boolean; PPI: Integer);
begin
  if IsRectEmpty(R) then
    Exit;
  if Hot then
    Canvas.FillRoundRect(R, PPGCapRounding(R, PPGScale(3, PPI)), Color, 36);
  DrawFieldGlyph(Canvas, R, fgClear, Color, PPI);
end;

procedure TPPGRendererBase.DrawTabScrollArrow(const Canvas: IPPGCanvas; const R: TRect;
  Color: TColor; Forward, Hot, Enabled: Boolean; PPI: Integer);
var
  CX, CY, S, Half, Quarter, W: Integer;
  Pts: array[0..2] of TPoint;
  Alpha: Byte;
begin
  if IsRectEmpty(R) then
    Exit;
  if Hot and Enabled then
    Canvas.FillRoundRect(R, PPGCapRounding(R, PPGScale(4, PPI)), Color, 28);
  S := R.Right - R.Left;
  if R.Bottom - R.Top < S then
    S := R.Bottom - R.Top;
  S := Round(S * 0.42);
  if S > PPGScale(10, PPI) then
    S := PPGScale(10, PPI);
  if S < 4 then
    Exit;
  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;
  Half := S div 2;
  Quarter := S div 4;
  W := Round(1.5 * PPI / 96);
  if W < 1 then
    W := 1;
  if Forward then
  begin
    Pts[0] := Point(CX - Quarter, CY - Half);
    Pts[1] := Point(CX + Quarter, CY);
    Pts[2] := Point(CX - Quarter, CY + Half);
  end
  else
  begin
    Pts[0] := Point(CX + Quarter, CY - Half);
    Pts[1] := Point(CX - Quarter, CY);
    Pts[2] := Point(CX + Quarter, CY + Half);
  end;
  if Enabled then
    Alpha := 255
  else
    Alpha := 90;
  Canvas.DrawPolyline(Pts, W, Color, Alpha);
end;

{ IPPGScrollRenderer }

procedure TPPGRendererBase.DrawScrollBar(const Canvas: IPPGCanvas; const Track, Thumb: TRect;
  const Style: TPPGSurfaceStyle; Vertical: Boolean; Expand: Single;
  Hot, Pressed: Boolean; PPI: Integer);
var
  E: Single;
  Cross, Thin, Full, W, Inset, C: Integer;
  T: TRect;
  Alpha: Byte;
begin
  if IsRectEmpty(Track) or IsRectEmpty(Thumb) then
    Exit;
  E := PPGClampSingle(Expand, 0, 1);
  if Vertical then
    Cross := Track.Right - Track.Left
  else
    Cross := Track.Bottom - Track.Top;
  // Breit: Spur dezent hinterlegt, Daumen fast so breit wie die Leiste
  if E > 0 then
    Canvas.FillRoundRect(Track, PPGCapRounding(Track, Cross div 2), Style.TextColor,
      Round(16 * E));
  Inset := PPGScale(2, PPI);
  Thin := PPGScale(2, PPI);
  Full := Cross - 2 * Inset;
  if Full < Thin then
    Full := Thin;
  W := Thin + Round((Full - Thin) * E);
  T := Thumb;
  if Vertical then
  begin
    C := (Track.Left + Track.Right) div 2;
    T.Left := C - W div 2;
    T.Right := T.Left + W;
  end
  else
  begin
    C := (Track.Top + Track.Bottom) div 2;
    T.Top := C - W div 2;
    T.Bottom := T.Top + W;
  end;
  if Pressed then
    Alpha := 200
  else if Hot then
    Alpha := 160
  else
    Alpha := 110 + Round(30 * E);
  Canvas.FillRoundRect(T, PPGCapRounding(T, W div 2), Style.TextColor, Alpha);
end;

{ IPPGItemRenderer }

procedure TPPGRendererBase.DrawItemBackground(const Canvas: IPPGCanvas; const R: TRect;
  const ListStyle, HighlightStyle: TPPGSurfaceStyle; Selected, Focused: Boolean;
  Hot: Single; RightToLeft: Boolean; PPI: Integer);
var
  Body, Bar: TRect;
  Rad, BarW, BarH, FW: Integer;
  H: Single;
begin
  if IsRectEmpty(R) then
    Exit;
  // Fluent: abgesetzte, gerundete Pille statt Balken ueber die ganze Breite
  Body := R;
  InflateRect(Body, -PPGScale(4, PPI), -PPGScale(1, PPI));
  if IsRectEmpty(Body) then
    Body := R;
  Rad := PPGCapRounding(Body, PPGScale(4, PPI));
  H := PPGClampSingle(Hot, 0, 1);
  if Selected then
    // Gewaehlt: dezente Flaeche in Textfarbe (passt zu hell und dunkel),
    // beim Hover etwas kraeftiger
    Canvas.FillRoundRect(Body, Rad, ListStyle.TextColor, 18 + Round(10 * H))
  else if H > 0 then
    Canvas.FillRoundRect(Body, Rad, HighlightStyle.Color, Round(255 * H));
  if Selected then
  begin
    // Akzentbalken am Anfang der Zeile (wie WinUI-Listen)
    BarW := PPGScale(3, PPI);
    BarH := (Body.Bottom - Body.Top) div 2;
    if BarH < PPGScale(6, PPI) then
      BarH := Body.Bottom - Body.Top;
    if RightToLeft then
    begin
      Bar.Right := Body.Right;
      Bar.Left := Body.Right - BarW;
    end
    else
    begin
      Bar.Left := Body.Left;
      Bar.Right := Body.Left + BarW;
    end;
    Bar.Top := (Body.Top + Body.Bottom - BarH) div 2;
    Bar.Bottom := Bar.Top + BarH;
    Canvas.FillRoundRect(Bar, BarW div 2, ListStyle.GlowColor, 255);
  end;
  if Focused then
  begin
    FW := PPGScale(1, PPI);
    if FW < 1 then
      FW := 1;
    Canvas.FrameRoundRect(Body, Rad, FW, ListStyle.TextColor, 200);
  end;
end;

procedure TPPGRendererBase.DrawGroupHeader(const Canvas: IPPGCanvas; const R: TRect;
  const Text: string; Font: TFont; const ListStyle: TPPGSurfaceStyle; RightToLeft: Boolean;
  PPI: Integer);
var
  T, Line: TRect;
  Flags: Cardinal;
  Pad: Integer;
begin
  if IsRectEmpty(R) then
    Exit;
  Pad := PPGScale(10, PPI);
  T := R;
  InflateRect(T, -Pad, 0);
  Flags := DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS;
  if RightToLeft then
    Flags := Flags or DT_RIGHT or DT_RTLREADING;
  Canvas.DrawText(T, Text, Font, PPGBlendColor(ListStyle.TextColor, ListStyle.Color, 0.25),
    Flags);
  // Feine Trennlinie unter der Ueberschrift
  Line := Rect(R.Left + Pad, R.Bottom - PPGScale(1, PPI) - 1, R.Right - Pad, R.Bottom - 1);
  if Line.Bottom <= Line.Top then
    Line.Bottom := Line.Top + 1;
  Canvas.FillRoundRect(Line, 0, ListStyle.TextColor, 40);
end;

function TPPGRendererBase.BadgeSize(const Canvas: IPPGCanvas; const Text: string; Font: TFont;
  PPI: Integer): TSize;
var
  T: TSize;
begin
  if Text = '' then
  begin
    Result.cx := 0;
    Result.cy := 0;
    Exit;
  end;
  T := Canvas.MeasureText(Text, Font, 0, False);
  Result.cy := T.cy + 2 * PPGScale(1, PPI);
  Result.cx := T.cx + 2 * PPGScale(7, PPI);
  if Result.cx < Result.cy then
    Result.cx := Result.cy;
end;

procedure TPPGRendererBase.DrawBadge(const Canvas: IPPGCanvas; const R: TRect;
  const Text: string; Font: TFont; Fill, TextColor: TColor; PPI: Integer);
begin
  if IsRectEmpty(R) or (Text = '') then
    Exit;
  Canvas.FillRoundRect(R, PPGCapRounding(R, MaxInt), Fill, 255);
  Canvas.DrawText(R, Text, Font, TextColor, DT_SINGLELINE or DT_CENTER or DT_VCENTER or
    DT_NOPREFIX);
end;

procedure TPPGRendererBase.DrawExpander(const Canvas: IPPGCanvas; const R: TRect;
  Color: TColor; Expanded: Single; RightToLeft: Boolean; PPI: Integer);
var
  CX, CY, S, Half, Quarter, W, I: Integer;
  Src: array[0..2] of TPoint;
  Pts: array[0..2] of TPoint;
  A, C, Sn: Double;
begin
  if IsRectEmpty(R) then
    Exit;
  S := R.Right - R.Left;
  if R.Bottom - R.Top < S then
    S := R.Bottom - R.Top;
  S := Round(S * 0.42);
  if S > PPGScale(10, PPI) then
    S := PPGScale(10, PPI);
  if S < 4 then
    Exit;
  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;
  Half := S div 2;
  Quarter := S div 4;
  W := Round(1.5 * PPI / 96);
  if W < 1 then
    W := 1;
  // Chevron nach rechts; zugeklappt 0 Grad, aufgeklappt 90 Grad (nach unten).
  // RTL: nach links, Drehung gegen den Uhrzeigersinn.
  Src[0] := Point(-Quarter, -Half);
  Src[1] := Point(Quarter, 0);
  Src[2] := Point(-Quarter, Half);
  A := PPGClampSingle(Expanded, 0, 1) * Pi / 2;
  C := Cos(A);
  Sn := Sin(A);
  for I := 0 to 2 do
  begin
    if RightToLeft then
      Pts[I] := Point(CX - Round(Src[I].X * C - Src[I].Y * Sn),
        CY + Round(Src[I].X * Sn + Src[I].Y * C))
    else
      Pts[I] := Point(CX + Round(Src[I].X * C - Src[I].Y * Sn),
        CY + Round(Src[I].X * Sn + Src[I].Y * C));
  end;
  Canvas.DrawPolyline(Pts, W, Color, 255);
end;

procedure TPPGRendererBase.DrawTreeLine(const Canvas: IPPGCanvas; const Points: array of TPoint;
  Color: TColor; PPI: Integer);
begin
  if Length(Points) < 2 then
    Exit;
  Canvas.DrawPolyline(Points, 1, Color, 90);
end;

procedure TPPGRendererBase.DrawDropIndicator(const Canvas: IPPGCanvas; const R: TRect;
  Color: TColor; PPI: Integer);
var
  Dot: TRect;
  D: Integer;
begin
  if IsRectEmpty(R) then
    Exit;
  Canvas.FillRoundRect(R, PPGCapRounding(R, MaxInt), Color, 255);
  // Kleiner Kreis am Anfang (wie im Explorer beim Einfuegen)
  D := (R.Bottom - R.Top) * 3;
  Dot := Rect(R.Left, (R.Top + R.Bottom - D) div 2, R.Left + D, (R.Top + R.Bottom + D) div 2);
  Canvas.FrameEllipse(Dot, R.Bottom - R.Top, Color, 255);
end;

{ TPPGRendererRegistry }

class procedure TPPGRendererRegistry.RegisterRenderer(const AName: string;
  AClass: TPPGRendererClass);
var
  E: TRendererEntry;
begin
  if AClass = nil then
    raise EPPGConfigError.Create(PPGStr(@SPPGRendererClassNil));
  if Entries.IndexOf(AName) >= 0 then
    raise EPPGConfigError.CreateFmt(PPGStr(@SPPGRendererAlreadyRegistered), [AName]);
  E := TRendererEntry.Create;
  try
    E.RendererClass := AClass;
    Entries.AddObject(AName, E);
  except
    E.Free;
    raise;
  end;
end;

class procedure TPPGRendererRegistry.UnregisterRenderer(const AName: string);
var
  I: Integer;
begin
  if GEntries = nil then
    Exit;
  I := GEntries.IndexOf(AName);
  if I >= 0 then
    GEntries.Delete(I); // OwnsObjects -> Entry wird freigegeben
end;

class function TPPGRendererRegistry.Find(const AName: string): IPPGRenderer;
var
  I: Integer;
  E: TRendererEntry;
begin
  Result := nil;
  if GEntries = nil then
    Exit;
  I := GEntries.IndexOf(AName);
  if I < 0 then
    Exit;
  E := TRendererEntry(GEntries.Objects[I]);
  if E.Instance = nil then
    E.Instance := E.RendererClass.Create;
  Result := E.Instance;
end;

class function TPPGRendererRegistry.Get(const AName: string): IPPGRenderer;
begin
  Result := Find(AName);
  if Result = nil then
    raise EPPGConfigError.CreateFmt(PPGStr(@SPPGUnknownPreset), [AName]);
end;

class function TPPGRendererRegistry.IsRegistered(const AName: string): Boolean;
begin
  Result := (GEntries <> nil) and (GEntries.IndexOf(AName) >= 0);
end;

class procedure TPPGRendererRegistry.GetNames(List: TStrings);
var
  I: Integer;
begin
  List.BeginUpdate;
  try
    List.Clear;
    if GEntries <> nil then
      for I := 0 to GEntries.Count - 1 do
        List.Add(GEntries[I]);
  finally
    List.EndUpdate;
  end;
end;

class function TPPGRendererRegistry.DefaultName: string;
begin
  Result := PPGDefaultPreset;
end;

class function TPPGRendererRegistry.CreateCanvas(DC: HDC): IPPGCanvas;
begin
  Result := nil;
  if not FForceGdiFallback and PPGGdiPlusAvailable then
  try
    Result := TPPGGdiPlusCanvas.Create(DC);
  except
    on E: EPPGRenderError do
    begin
      // Einmalig protokollieren, dann weiter mit GDI (z.B. Treiberproblem)
      if not GCanvasFallbackLogged then
      begin
        GCanvasFallbackLogged := True;
        TPPGErrorHandler.LogWarning(nil, E.Message);
      end;
      Result := nil;
    end;
  end;
  if Result = nil then
    Result := TPPGGdiCanvas.Create(DC);
end;

initialization

finalization
  FreeAndNil(GEntries);

end.
