unit PPG.Render.Fluent11;

{ Preset "Fluent11": Windows-11-Optik (WinUI / Fluent 2).
  - Flaechen ohne Glow; Hover und Druck sind feine Flaechenwechsel, der
    Rand bleibt dabei neutral (kein Akzent-Rand beim Hover).
  - 1-px-Rand mit dunklerer Unterkante (Elevation); dunkle neutrale
    Flaechen bekommen stattdessen eine hellere Oberkante.
  - Fokus als Doppelring AUSSERHALB des Koerpers: aussen dunkel, innen hell
    (im Dunkeln umgekehrt). Der Abstand ist GlowSize (Standard 3 px),
    BodyInset haelt dafuer Platz frei.
  - Akzent aus dem System: AccentPalette (die Varianten, die Windows selbst
    fuer Hell/Dunkel nutzt), sonst DWM-AccentColor, sonst Windows-Blau.
    Die Akzente werden so angepasst, dass Text darauf 4,5:1 erreicht. }

{$I ..\PPG.inc}

interface

uses
  System.Types, Vcl.Graphics, PPG.Types, PPG.Appearance, PPG.Tokens, PPG.Render.Intf,
  PPG.Render.Registry;

type
  /// Akzentfarben fuer beide Modi.
  TPPGAccentPair = record
    Light: TColor; // heller Modus: Text darauf weiss
    Dark: TColor;  // dunkler Modus: Text darauf schwarz
  end;

  TPPGFluent11Renderer = class(TPPGRendererBase)
  private
    class var FAccentOverride: TColor;
    class function CurrentAccent(out Pair: TPPGAccentPair): Boolean; static;
    /// Koerper mit ausdruecklicher Randfarbe; Elevation = dunklere Unterkante.
    procedure DrawBody(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle; Border: TColor; Elevation: Boolean);
  public
    function Name: string; override;
    procedure ApplyDefaults(Appearance: TPPGAppearance); override;
    function Tokens(Dark: Boolean): TPPGTokens; override;
    procedure ApplyThemeColors(Appearance: TPPGAppearance; Dark: Boolean); override;
    /// Platz fuer den Fokusring (GlowSize), damit er nicht abgeschnitten wird.
    function BodyInset(const Style: TPPGSurfaceStyle): Integer; override;
    procedure DrawSurface(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle); override;
    /// Windows-11-Doppelring ausserhalb von Body.
    procedure DrawFocus(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle); override;
    procedure DrawCheckIndicator(const Canvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; State: TPPGCheckState; PPI: Integer); override;
    procedure DrawRadioIndicator(const Canvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; Checked: Boolean; PPI: Integer); override;
    procedure DrawSwitch(const Canvas: IPPGCanvas; const Track: TRect;
      const Style: TPPGSurfaceStyle; Position: Single; RightToLeft: Boolean;
      PPI: Integer); override;
    { Symbole aus der Fluent-Symbolschrift (PPG.IconFont); ohne Schrift die
      Linien der Basis }
    procedure DrawCheckMark(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      PPI: Integer); override;
    procedure DrawFieldGlyph(const Canvas: IPPGCanvas; const R: TRect;
      Glyph: TPPGFieldGlyph; Color: TColor; PPI: Integer); override;
    /// Mit Symbolschrift ohne Drehung: ab halber Animation zeigt der Pfeil nach oben.
    procedure DrawDropArrow(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      Rotation: Single; PPI: Integer); override;
    procedure DrawTabClose(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      Hot: Boolean; PPI: Integer); override;
    procedure DrawTabScrollArrow(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      Forward, Hot, Enabled: Boolean; PPI: Integer); override;
    /// Feste Akzentfarbe (z.B. Markenfarbe) statt der Systemfarbe;
    /// clNone = Systemfarbe. Wirkt, sobald das Preset angewendet wird
    /// (ApplyDefaults, also Preset-Zuweisung oder "Reset to preset defaults").
    class property AccentOverride: TColor read FAccentOverride write FAccentOverride;
  end;

/// Akzente fuer Hell/Dunkel aus einer Grundfarbe ableiten (mit Kontrastpruefung).
function PPGAccentFromBase(Base: TColor): TPPGAccentPair;
/// Akzente aus dem Registry-Wert AccentPalette (8 Farben zu je R,G,B,A):
/// Hell = AccentDark1 (Index 4), Dunkel = AccentLight2 (Index 1).
function PPGAccentFromPalette(const Palette: array of Byte;
  out Pair: TPPGAccentPair): Boolean;
/// Systemakzent (zwischengespeichert). False = keiner gesetzt/lesbar.
function PPGSystemAccent(out Pair: TPPGAccentPair): Boolean;
/// Verwirft den Zwischenspeicher (z.B. nach WM_SETTINGCHANGE).
procedure PPGRefreshSystemAccent;

implementation

uses
  Winapi.Windows, System.Math, Vcl.StdCtrls, PPG.Consts, PPG.IconFont;

const
  AccentKey = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Accent';
  DwmKey = 'Software\Microsoft\Windows\DWM';
  FocusOuterLight = $001B1B1B;
  FocusInnerLight = $00FFFFFF;
  FocusOuterDark = $00FFFFFF;
  FocusInnerDark = $00101010;

var
  GAccentState: Integer = 0; // 0 = ungelesen, 1 = vorhanden, 2 = keiner
  GAccent: TPPGAccentPair;

{ ---- Systemakzent ---- }

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

function FixPair(const Pair: TPPGAccentPair): TPPGAccentPair;
var
  Dark: TPPGTokens;
begin
  // Hell: weisser Text auf dem Akzent (WCAG AA). Dunkel: schwarzer Text mit
  // deutlichem Abstand (7:1), so bleibt die Helligkeit klar von den hellen
  // Akzenten getrennt (DrawFocus erkennt daran den Modus), und der Akzent
  // hebt sich vom dunklen Hintergrund ab.
  Dark := PPGDefaultTokens(True);
  Result.Light := EnsureContrast(PPGColorToRGB(Pair.Light), clWhite, 4.5, False);
  Result.Dark := EnsureContrast(PPGColorToRGB(Pair.Dark), clBlack, 7.0, True);
  Result.Dark := EnsureContrast(Result.Dark, Dark.Background, 3.0, True);
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
  Result := FixPair(Result);
end;

function PPGAccentFromPalette(const Palette: array of Byte;
  out Pair: TPPGAccentPair): Boolean;
var
  I: Integer;
  Any: Boolean;
begin
  Result := False;
  Pair.Light := clNone;
  Pair.Dark := clNone;
  if Length(Palette) < 28 then
    Exit;
  Any := False;
  for I := 0 to 27 do
    if Palette[I] <> 0 then
      Any := True;
  if not Any then
    Exit;
  Pair.Light := TColor(RGB(Palette[16], Palette[17], Palette[18]));
  Pair.Dark := TColor(RGB(Palette[4], Palette[5], Palette[6]));
  Pair := FixPair(Pair);
  Result := True;
end;

function ReadValue(const Key, Value: string; ExpectedType: DWORD; var Buf;
  Size: DWORD): DWORD;
var
  H: HKEY;
  T, L: DWORD;
begin
  // Liefert die Anzahl gelesener Bytes, 0 bei Fehler/falschem Typ. Fehlende
  // Werte sind normal (aeltere Windows-Versionen) und kein Fehlerfall.
  Result := 0;
  if RegOpenKeyEx(HKEY_CURRENT_USER, PChar(Key), 0, KEY_READ, H) <> ERROR_SUCCESS then
    Exit;
  try
    L := Size;
    T := 0;
    if (RegQueryValueEx(H, PChar(Value), nil, @T, @Buf, @L) = ERROR_SUCCESS) and
      (T = ExpectedType) then
      Result := L;
  finally
    RegCloseKey(H);
  end;
end;

function ReadSystemAccent(out Pair: TPPGAccentPair): Boolean;
var
  Palette: array[0..31] of Byte;
  Color: DWORD;
begin
  FillChar(Palette, SizeOf(Palette), 0);
  if (ReadValue(AccentKey, 'AccentPalette', REG_BINARY, Palette, SizeOf(Palette)) >= 28) and
    PPGAccentFromPalette(Palette, Pair) then
    Exit(True);
  // DWM speichert $AABBGGRR - die unteren drei Bytes sind schon ein TColor
  Color := 0;
  if ReadValue(DwmKey, 'AccentColor', REG_DWORD, Color, SizeOf(Color)) = SizeOf(Color) then
  begin
    Pair := PPGAccentFromBase(TColor(Color and $00FFFFFF));
    Exit(True);
  end;
  Result := False;
end;

function PPGSystemAccent(out Pair: TPPGAccentPair): Boolean;
begin
  if GAccentState = 0 then
  begin
    if ReadSystemAccent(GAccent) then
      GAccentState := 1
    else
      GAccentState := 2;
  end;
  Pair := GAccent;
  Result := GAccentState = 1;
end;

procedure PPGRefreshSystemAccent;
begin
  GAccentState := 0;
end;

{ ---- Hilfen ---- }

function IsLight(C: TColor): Boolean;
begin
  Result := PPGRelativeLuminance(C) > 0.4;
end;

function IsSaturated(C: TColor): Boolean;
var
  V: Cardinal;
  R, G, B, Mx, Mn: Integer;
begin
  V := Cardinal(PPGColorToRGB(C));
  R := V and $FF;
  G := (V shr 8) and $FF;
  B := (V shr 16) and $FF;
  Mx := R;
  if G > Mx then Mx := G;
  if B > Mx then Mx := B;
  Mn := R;
  if G < Mn then Mn := G;
  if B < Mn then Mn := B;
  Result := Mx - Mn > 40;
end;

/// Kraeftiger Rand fuer Kaestchen, Kreis und Schalter (Windows: "strong
/// stroke", etwa halb zwischen Flaeche und Text).
function StrongStroke(const S: TPPGSurfaceStyle): TColor;
begin
  Result := PPGBlendColor(S.Color, S.TextColor, 0.55);
end;

/// Rand eines GEFUELLTEN Indikators (angehakt/an): normal unsichtbar (Akzentflaeche),
/// aber wenn die Fuellung kaum vom Symbol abweicht (deaktiviert: grau auf hellgrau)
/// ein kraeftiger Rand - sonst bliebe vom Kaestchen nur der Haken uebrig.
function FilledBorder(const S: TPPGSurfaceStyle): TColor;
var
  C: TColor;
  R, G, B: Integer;
begin
  // Akzentflaeche (farbig) ohne Rand; graue Flaeche (deaktiviert) mit Rand
  C := ColorToRGB(S.Color);
  R := GetRValue(C);
  G := GetGValue(C);
  B := GetBValue(C);
  if (MaxIntValue([R, G, B]) - MinIntValue([R, G, B]) >= 40) and
    (PPGContrastRatio(S.Color, S.TextColor) >= 2.5) then
    Result := S.Color
  else
    Result := PPGBlendColor(S.Color, S.TextColor, 0.85); // auch auf dunkler Flaeche sichtbar
end;

{ TPPGFluent11Renderer }

function TPPGFluent11Renderer.Name: string;
begin
  Result := PPGPresetFluent11;
end;

class function TPPGFluent11Renderer.CurrentAccent(out Pair: TPPGAccentPair): Boolean;
begin
  if FAccentOverride <> clNone then
  begin
    Pair := PPGAccentFromBase(FAccentOverride);
    Result := True;
  end
  else
    Result := PPGSystemAccent(Pair);
end;

function TPPGFluent11Renderer.Tokens(Dark: Boolean): TPPGTokens;
var
  P: TPPGAccentPair;
  A, Under: TColor;
begin
  // Grundlage ist die neutrale Windows-11-Palette; nur der Akzent kommt aus
  // dem System. Hover/Druck = Akzent mit 90 %/80 % Deckung (wie WinUI).
  Result := PPGDefaultTokens(Dark);
  if CurrentAccent(P) then
  begin
    if Dark then
    begin
      A := P.Dark;
      Under := Result.Background;
    end
    else
    begin
      A := P.Light;
      Under := Result.Surface;
    end;
    Result.Accent := A;
    Result.AccentHover := PPGBlendColor(A, Under, 0.10);
    Result.AccentPressed := PPGBlendColor(A, Under, 0.20);
  end;
end;

procedure TPPGFluent11Renderer.ApplyThemeColors(Appearance: TPPGAppearance; Dark: Boolean);
var
  T: TPPGTokens;
begin
  T := Tokens(Dark);
  Appearance.BeginUpdate;
  try
    // Windows 11: kein Akzent-Rand bei Hover. Gedrueckt wird der Rand etwas
    // kraeftiger statt (wie in WinUI) der Text blasser: Der Druck-Zustand ist
    // auch der eingerastete Toggle-Button, und der muss gut lesbar und klar
    // erkennbar bleiben. Nur Farben - die Glow-Staerken gehoeren zur Form.
    Appearance.Normal.SetAll(T.Surface, T.Surface, T.Surface, T.Surface,
      T.Stroke, T.Accent, T.TextPrimary, Appearance.Normal.GlowAlpha);
    Appearance.Hot.SetAll(T.SurfaceHover, T.SurfaceHover, T.SurfaceHover, T.SurfaceHover,
      T.Stroke, T.Accent, T.TextPrimary, Appearance.Hot.GlowAlpha);
    Appearance.Down.SetAll(T.SurfacePressed, T.SurfacePressed, T.SurfacePressed,
      T.SurfacePressed, T.StrokeStrong, T.Accent, T.TextPrimary, Appearance.Down.GlowAlpha);
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

procedure TPPGFluent11Renderer.ApplyDefaults(Appearance: TPPGAppearance);
begin
  Appearance.BeginUpdate;
  try
    ApplyThemeColors(Appearance, False);
    // Kein Glow; GlowSize ist hier der Abstand des Fokusrings
    Appearance.Normal.GlowAlpha := 0;
    Appearance.Hot.GlowAlpha := 0;
    Appearance.Down.GlowAlpha := 0;
    Appearance.Disabled.GlowAlpha := 0;
    Appearance.Checked.GlowAlpha := 0;
    Appearance.Rounding := 4;
    Appearance.BorderWidth := 1;
    Appearance.GlowSize := 3;
  finally
    Appearance.EndUpdate;
  end;
end;

function TPPGFluent11Renderer.BodyInset(const Style: TPPGSurfaceStyle): Integer;
begin
  Result := Style.GlowSize;
end;

procedure TPPGFluent11Renderer.DrawBody(const Canvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle; Border: TColor; Elevation: Boolean);
var
  R, BW, H: Integer;
  Edge: TRect;
  EdgeColor: TColor;
begin
  if IsRectEmpty(Body) then
    Exit;
  R := PPGCapRounding(Body, Style.Rounding);
  if Style.Color = Style.ColorTo then
    Canvas.FillRoundRect(Body, R, Style.Color, 255)
  else
  begin
    Canvas.PushClipRoundRect(Body, R);
    try
      Canvas.FillGradientRect(Body, Style.Color, Style.ColorTo, Style.Direction, 255);
    finally
      Canvas.PopClip;
    end;
  end;
  BW := Style.BorderWidth;
  if BW <= 0 then
    Exit;
  Canvas.FrameRoundRect(Body, R, BW, Border, 255);
  if not Elevation then
    Exit;
  // Elevation: derselbe Rahmen noch einmal, auf ein Band an der Unter- bzw.
  // Oberkante begrenzt - so folgt die Kante sauber der Rundung
  H := R div 2 + BW;
  Edge := Body;
  if IsLight(Style.Color) or IsSaturated(Style.Color) then
  begin
    Edge.Top := Body.Bottom - H;
    if IsLight(Style.Color) then
      EdgeColor := PPGDarken(Border, 0.14)
    else
      EdgeColor := PPGDarken(Border, 0.30);
  end
  else
  begin
    Edge.Bottom := Body.Top + H;
    EdgeColor := PPGLighten(Border, 0.07);
  end;
  Canvas.PushClipRoundRect(Edge, 0);
  try
    Canvas.FrameRoundRect(Body, R, BW, EdgeColor, 255);
  finally
    Canvas.PopClip;
  end;
end;

procedure TPPGFluent11Renderer.DrawSurface(const Canvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle);
var
  Border: TColor;
begin
  // Bei Fokus ist Style.BorderColor die Fokusfarbe. Windows 11 laesst den Rand
  // neutral und zeigt den Fokus nur als Ring (DrawFocus) - deshalb ein
  // neutraler Rand aus Flaeche und Text.
  Border := Style.BorderColor;
  if Style.Focused then
    Border := PPGBlendColor(Style.Color, Style.TextColor, 0.15);
  DrawBody(Canvas, Body, Style, Border, True);
end;

procedure TPPGFluent11Renderer.DrawFocus(const Canvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle);
var
  M, InnerW, OuterW, U, R: Integer;
  Outer, Mid, Inner: TRect;
  OuterColor, InnerColor: TColor;
begin
  if IsRectEmpty(Body) then
    Exit;
  // Modus aus der Fokusfarbe (= Akzent): im Hellen dunkel (Text weiss darauf),
  // im Dunkeln hell (siehe FixPair). Dunkler Akzent -> heller Modus.
  if PPGRelativeLuminance(Style.BorderColor) < 0.24 then
  begin
    OuterColor := FocusOuterLight;
    InnerColor := FocusInnerLight;
  end
  else
  begin
    OuterColor := FocusOuterDark;
    InnerColor := FocusInnerDark;
  end;
  M := Style.GlowSize;
  if M >= 2 then
  begin
    // Ring ausserhalb: aussen 2/3 dunkel, innen 1/3 hell (bei 96 DPI 2 + 1 px)
    InnerW := Round(M / 3);
    if InnerW < 1 then
      InnerW := 1;
    OuterW := M - InnerW;
    Outer := Body;
    InflateRect(Outer, M, M);
    R := Style.Rounding;
    if R > 0 then
      Inc(R, M);
    Canvas.FrameRoundRect(Outer, PPGCapRounding(Outer, R), OuterW, OuterColor, 255);
    Mid := Body;
    InflateRect(Mid, InnerW, InnerW);
    R := Style.Rounding;
    if R > 0 then
      Inc(R, InnerW);
    Canvas.FrameRoundRect(Mid, PPGCapRounding(Mid, R), InnerW, InnerColor, 255);
  end
  else
  begin
    // Kein Platz ausserhalb (GlowSize 0/1): Ring innen auf dem Rand
    U := Style.BorderWidth;
    if U < 1 then
      U := 1;
    R := PPGCapRounding(Body, Style.Rounding);
    Canvas.FrameRoundRect(Body, R, 2 * U, OuterColor, 255);
    Inner := Body;
    InflateRect(Inner, -2 * U, -2 * U);
    if not IsRectEmpty(Inner) then
    begin
      R := R - 2 * U;
      if R < 0 then
        R := 0;
      Canvas.FrameRoundRect(Inner, R, U, InnerColor, 255);
    end;
  end;
end;

procedure TPPGFluent11Renderer.DrawCheckIndicator(const Canvas: IPPGCanvas; const R: TRect;
  const Style: TPPGSurfaceStyle; State: TPPGCheckState; PPI: Integer);
var
  S: TPPGSurfaceStyle;
  Inner: TRect;
  D, H: Integer;
  Border: TColor;
begin
  if IsRectEmpty(R) then
    Exit;
  S := Style;
  if S.Rounding > PPGScale(4, PPI) then
    S.Rounding := PPGScale(4, PPI);
  // Aus/gemischt: kraeftiger Rand; an: Akzentflaeche ohne sichtbaren Rand
  if State = cbChecked then
    Border := FilledBorder(S)
  else
    Border := StrongStroke(S);
  DrawBody(Canvas, R, S, Border, False);
  case State of
    cbChecked:
      DrawCheckMark(Canvas, R, S.TextColor, PPI);
    cbGrayed:
      begin
        // Windows 11: waagerechter Strich statt Quadrat
        Inner := R;
        D := (R.Right - R.Left) * 3 div 10;
        H := PPGScale(2, PPI);
        Inner.Left := R.Left + D;
        Inner.Right := R.Right - D;
        Inner.Top := (R.Top + R.Bottom - H) div 2;
        Inner.Bottom := Inner.Top + H;
        if not IsRectEmpty(Inner) then
          Canvas.FillRoundRect(Inner, H div 2, S.TextColor, 255);
      end;
  end;
  if S.Focused then
    DrawFocus(Canvas, R, S);
end;

procedure TPPGFluent11Renderer.DrawRadioIndicator(const Canvas: IPPGCanvas; const R: TRect;
  const Style: TPPGSurfaceStyle; Checked: Boolean; PPI: Integer);
var
  S: TPPGSurfaceStyle;
  Dot: TRect;
  D: Integer;
  Border: TColor;
begin
  if IsRectEmpty(R) then
    Exit;
  S := Style;
  S.Rounding := (R.Right - R.Left) div 2; // Kreis
  if Checked then
    Border := FilledBorder(S)
  else
    Border := StrongStroke(S);
  DrawBody(Canvas, R, S, Border, False);
  if Checked then
  begin
    // Heller Punkt auf dem Akzent (etwa 40 % des Durchmessers)
    Dot := R;
    D := Round((R.Right - R.Left) * 0.3);
    InflateRect(Dot, -D, -D);
    if not IsRectEmpty(Dot) then
      Canvas.FillEllipse(Dot, S.TextColor, 255);
  end;
  if S.Focused then
    DrawFocus(Canvas, R, S);
end;

procedure TPPGFluent11Renderer.DrawSwitch(const Canvas: IPPGCanvas; const Track: TRect;
  const Style: TPPGSurfaceStyle; Position: Single; RightToLeft: Boolean; PPI: Integer);
var
  S: TPPGSurfaceStyle;
  P: Single;
  Strong, Knob: TColor;
  Inset, D, Travel, X: Integer;
  Thumb: TRect;
begin
  if IsRectEmpty(Track) then
    Exit;
  S := Style;
  S.Rounding := (Track.Bottom - Track.Top) div 2; // Pillenform
  P := PPGClampSingle(Position, 0, 1);
  // Aus: kraeftiger Rand und Knopf in derselben Farbe; an: Akzent mit hellem
  // Knopf. Waehrend der Animation gleitend.
  Strong := StrongStroke(S);
  DrawBody(Canvas, Track, S, PPGBlendColor(Strong, FilledBorder(S), P), False);
  Knob := PPGBlendColor(Strong, S.TextColor, P);
  Inset := PPGScale(5, PPI);
  D := (Track.Bottom - Track.Top) - 2 * Inset;
  if D > 0 then
  begin
    Travel := (Track.Right - Track.Left) - 2 * Inset - D;
    if Travel < 0 then
      Travel := 0;
    if RightToLeft then
      P := 1 - P;
    X := Track.Left + Inset + Round(Travel * P);
    Thumb := Rect(X, Track.Top + Inset, X + D, Track.Top + Inset + D);
    Canvas.FillEllipse(Thumb, Knob, 255);
  end;
  if S.Focused then
    DrawFocus(Canvas, Track, S);
end;

{ ---- Symbole ---- }

/// Em-Groesse eines kleinen Symbols in R (passend zu den Chevrons der Basis).
function IconSize(const R: TRect; PPI: Integer): Integer;
var
  S: Integer;
begin
  S := R.Right - R.Left;
  if R.Bottom - R.Top < S then
    S := R.Bottom - R.Top;
  Result := Round(S * 0.5);
  if Result > PPGScale(12, PPI) then
    Result := PPGScale(12, PPI);
end;

procedure TPPGFluent11Renderer.DrawCheckMark(const Canvas: IPPGCanvas; const R: TRect;
  Color: TColor; PPI: Integer);
var
  S: Integer;
begin
  S := R.Right - R.Left;
  if R.Bottom - R.Top < S then
    S := R.Bottom - R.Top;
  if not PPGDrawIcon(Canvas, R, igCheckMark, Color, Round(S * 0.75)) then
    inherited DrawCheckMark(Canvas, R, Color, PPI);
end;

procedure TPPGFluent11Renderer.DrawFieldGlyph(const Canvas: IPPGCanvas; const R: TRect;
  Glyph: TPPGFieldGlyph; Color: TColor; PPI: Integer);
var
  G: TPPGIconGlyph;
  Size: Integer;
begin
  case Glyph of
    fgClear: G := igClose;
    fgSpinUp: G := igChevronUp;
    fgSpinDown, fgDropDown: G := igChevronDown;
  else
    Exit; // fgNone
  end;
  Size := IconSize(R, PPI);
  if not PPGDrawIcon(Canvas, R, G, Color, Size) then
    inherited DrawFieldGlyph(Canvas, R, Glyph, Color, PPI);
end;

procedure TPPGFluent11Renderer.DrawDropArrow(const Canvas: IPPGCanvas; const R: TRect;
  Color: TColor; Rotation: Single; PPI: Integer);
var
  G: TPPGIconGlyph;
begin
  if Rotation < 0.5 then
    G := igChevronDown
  else
    G := igChevronUp;
  if not PPGDrawIcon(Canvas, R, G, Color, IconSize(R, PPI)) then
    inherited DrawDropArrow(Canvas, R, Color, Rotation, PPI);
end;

procedure TPPGFluent11Renderer.DrawTabClose(const Canvas: IPPGCanvas; const R: TRect;
  Color: TColor; Hot: Boolean; PPI: Integer);
var
  S: Integer;
begin
  if PPGIconFontName = '' then
  begin
    inherited DrawTabClose(Canvas, R, Color, Hot, PPI);
    Exit;
  end;
  if IsRectEmpty(R) then
    Exit;
  if Hot then
    Canvas.FillRoundRect(R, PPGCapRounding(R, PPGScale(4, PPI)), Color, 28);
  // Kleiner Knopf: das X fuellt ihn staerker aus als ein Chevron ein Feld
  S := R.Right - R.Left;
  if R.Bottom - R.Top < S then
    S := R.Bottom - R.Top;
  S := Round(S * 0.7);
  if S > PPGScale(12, PPI) then
    S := PPGScale(12, PPI);
  PPGDrawIcon(Canvas, R, igClose, Color, S);
end;

procedure TPPGFluent11Renderer.DrawTabScrollArrow(const Canvas: IPPGCanvas; const R: TRect;
  Color: TColor; Forward, Hot, Enabled: Boolean; PPI: Integer);
var
  G: TPPGIconGlyph;
begin
  // Deaktiviert braucht Transparenz - das kann nur die Linie der Basis
  if not Enabled or (PPGIconFontName = '') then
  begin
    inherited DrawTabScrollArrow(Canvas, R, Color, Forward, Hot, Enabled, PPI);
    Exit;
  end;
  if IsRectEmpty(R) then
    Exit;
  if Hot then
    Canvas.FillRoundRect(R, PPGCapRounding(R, PPGScale(4, PPI)), Color, 28);
  if Forward then
    G := igChevronRight
  else
    G := igChevronLeft;
  PPGDrawIcon(Canvas, R, G, Color, IconSize(R, PPI));
end;

initialization
  TPPGFluent11Renderer.FAccentOverride := clNone;
  TPPGRendererRegistry.RegisterRenderer(PPGPresetFluent11, TPPGFluent11Renderer);

finalization
  TPPGRendererRegistry.UnregisterRenderer(PPGPresetFluent11);

end.
