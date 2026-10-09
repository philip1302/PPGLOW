unit PPG.Render.Classic;

{ Preset "Classic": glaenzende Office-Optik (oberer/unterer Verlauf,
  innerer Lichtschein, weisse Innenkante). }

{$I ..\PPG.inc}

interface

uses
  System.Types, Vcl.Graphics, PPG.Types, PPG.Appearance, PPG.Tokens, PPG.Render.Intf,
  PPG.Render.Registry;

type
  TPPGClassicRenderer = class(TPPGRendererBase)
  public
    function Name: string; override;
    procedure ApplyDefaults(Appearance: TPPGAppearance); override;
    function BaseTokens(Dark: Boolean): TPPGTokens; override;
    procedure ApplyThemeColors(Appearance: TPPGAppearance; Dark: Boolean); override;
    procedure DrawSurface(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle); override;
    /// Office-Feld: Fokus faerbt den ganzen Rahmen, mit weichem Innenschein.
    procedure DrawField(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle; FocusProgress: Single; PPI: Integer); override;
    /// Office-Liste: Hervorhebung als Glanz-Verlauf ueber die ganze Breite.
    procedure DrawListItem(const Canvas: IPPGCanvas; const R: TRect;
      const ListStyle, HighlightStyle: TPPGSurfaceStyle; Selected: Boolean;
      Highlight: Single; PPI: Integer); override;
    /// Office-Reiter: Glanz-Verlauf mit Rahmen, nicht gewaehlte etwas niedriger.
    procedure DrawTab(const Canvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; Selected: Boolean; HotProgress: Single;
      Bottom: Boolean; PPI: Integer); override;
    /// Kein Unterstrich: der gewaehlte Reiter haengt mit der Seite zusammen.
    procedure DrawTabIndicator(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      Bottom: Boolean; PPI: Integer); override;
    /// Office-Eintrag: gewaehlt = Glanz-Verlauf, Hover = halbtransparenter Glanz.
    procedure DrawItemBackground(const Canvas: IPPGCanvas; const R: TRect;
      const ListStyle, HighlightStyle: TPPGSurfaceStyle; Selected, Focused: Boolean;
      Hot: Single; RightToLeft: Boolean; PPI: Integer); override;
    /// Office-Saeule: Glanz-Verlauf quer zur Wachstumsrichtung, feiner Rand.
    procedure DrawChartBar(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      Hot: Single; Vertical, Negative: Boolean; PPI: Integer); override;
  end;

implementation

uses
  PPG.Consts;

function TPPGClassicRenderer.Name: string;
begin
  Result := PPGPresetClassic;
end;

function TPPGClassicRenderer.BaseTokens(Dark: Boolean): TPPGTokens;
begin
  Result := PPGBaseTokens(Dark);
  if not Dark then
  begin
    Result.Accent := $00D77800;
    Result.AccentHover := $00E58A1A;
    Result.AccentPressed := $00A35A00;
    Result.OnAccent := $00FFFFFF;
    Result.Background := $00F0F0F0;
    Result.Layer := $00FAFAFA;
    Result.Surface := $00FAFAFA;
    Result.SurfaceHover := $0097E7FF;   // Office-Gold
    Result.SurfacePressed := $0053A6FB; // Office-Orange
    Result.SurfaceDisabled := $00F0F0F0;
    Result.Stroke := $00A8A8A8;
    Result.StrokeStrong := $00808080;
    Result.StrokeDisabled := $00D0D0D0;
    Result.TextPrimary := $00202020;
    Result.TextSecondary := $00606060;
    Result.TextDisabled := $00A0A0A0;
    Result.Danger := PPGColorError;
    Result.Warning := PPGColorWarning;
    Result.Success := PPGColorSuccess;
    Result.Paused := $0000B9FF;
  end
  else
  begin
    Result.Accent := $00F0A040;
    Result.AccentHover := $00F5B565;
    Result.AccentPressed := $00C88530;
    Result.OnAccent := $00000000;
    Result.Background := $00262626;
    Result.Layer := $00303030;
    Result.Surface := $00444444;
    // Semantische Hover-/Druckflaeche fuer hellen Text; die Glanz-Buttons
    // bleiben gold/orange (eigene Abbildung in ApplyThemeColors)
    Result.SurfaceHover := $00505050;
    Result.SurfacePressed := $003A3A3A;
    Result.SurfaceDisabled := $00363636;
    Result.Stroke := $00686868;
    Result.StrokeStrong := $00808080;
    Result.StrokeDisabled := $004A4A4A;
    Result.TextPrimary := $00F0F0F0;
    Result.TextSecondary := $00C0C0C0;
    Result.TextDisabled := $007A7A7A;
  end;
  Result.RadiusSmall := 2;
  Result.RadiusMedium := 3;
  Result.RadiusLarge := 4;
  Result.StrokeWidth := 1;
  Result.DurationNormal := 150;
  Result.Link := PPGLinkColor(Result.Accent, Result.Background);
end;

procedure TPPGClassicRenderer.ApplyThemeColors(Appearance: TPPGAppearance; Dark: Boolean);
var
  T: TPPGTokens;
begin
  // Glanz-Optik: vier Verlaufsfarben pro Zustand; Gold/Orange fuer Hover und
  // Druck bleiben in beiden Modi (Office-Markenzeichen, mit dunklem Text)
  T := Tokens(Dark);
  Appearance.BeginUpdate;
  try
    if not Dark then
    begin
      Appearance.Normal.SetAll($00FAFAFA, $00EEEEEE, $00E2E2E2, $00F1F1F1,
        $00A8A8A8, $00FFE6C0, $00202020, Appearance.Normal.GlowAlpha);
      Appearance.Disabled.SetAll($00F4F4F4, $00F0F0F0, $00EBEBEB, $00F0F0F0,
        $00D0D0D0, $00F0F0F0, $00A0A0A0, Appearance.Disabled.GlowAlpha);
    end
    else
    begin
      Appearance.Normal.SetAll($00505050, $00444444, $00383838, $003E3E3E,
        $00686868, $00806040, $00F0F0F0, Appearance.Normal.GlowAlpha);
      Appearance.Disabled.SetAll($003A3A3A, $00363636, $00323232, $00343434,
        $004A4A4A, $003A3A3A, $007A7A7A, Appearance.Disabled.GlowAlpha);
    end;
    Appearance.Hot.SetAll($00DDFDFF, $0097E7FF, $004DD7FF, $0096E7FF,
      $0080C0D8, $00FFFFFF, $00101010, Appearance.Hot.GlowAlpha);
    Appearance.Down.SetAll($008ACAFD, $0053A6FB, $00217EF9, $0063B4FD,
      $004B83C2, $00A0E0FF, $00101010, Appearance.Down.GlowAlpha);
    // "An"-Zustand: goldener Office-Verlauf, dunkler Haken
    Appearance.Checked.SetAll($00C8F4FF, $0080DCFF, $0040C8FF, $0090E0FF,
      $00309ACF, $00FFFFFF, $00202020, Appearance.Checked.GlowAlpha);
    Appearance.FocusColor := T.Accent;
  finally
    Appearance.EndUpdate;
  end;
end;

procedure TPPGClassicRenderer.ApplyDefaults(Appearance: TPPGAppearance);
begin
  Appearance.BeginUpdate;
  try
    ApplyThemeColors(Appearance, False);
    Appearance.Normal.GlowAlpha := 0;
    Appearance.Hot.GlowAlpha := 170;
    Appearance.Down.GlowAlpha := 140;
    Appearance.Disabled.GlowAlpha := 0;
    Appearance.Checked.GlowAlpha := 0;
    Appearance.Rounding := 3;
    Appearance.BorderWidth := 1;
    Appearance.GlowSize := 0;
  finally
    Appearance.EndUpdate;
  end;
end;

procedure TPPGClassicRenderer.DrawSurface(const Canvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle);
var
  First, Second, Glow, Inner: TRect;
  W, H: Integer;
begin
  if IsRectEmpty(Body) then
    Exit;
  W := Body.Right - Body.Left;
  H := Body.Bottom - Body.Top;
  First := Body;
  Second := Body;
  if Style.Direction = gdHorizontal then
  begin
    First.Right := Body.Left + W div 2;
    Second.Left := First.Right;
  end
  else
  begin
    First.Bottom := Body.Top + H * 2 div 5; // Glanzkante bei 40 %
    Second.Top := First.Bottom;
  end;

  Canvas.PushClipRoundRect(Body, Style.Rounding);
  try
    Canvas.FillGradientRect(First, Style.Color, Style.ColorTo, Style.Direction, 255);
    Canvas.FillGradientRect(Second, Style.ColorMirror, Style.ColorMirrorTo, Style.Direction, 255);
    if Style.GlowAlpha > 0 then
    begin
      // Lichtschein von unten (typischer "Glow"-Effekt)
      Glow := Rect(Body.Left - W div 6, Body.Top + H div 3,
        Body.Right + W div 6, Body.Bottom + H * 2 div 3);
      Canvas.FillRadialGlow(Glow, Style.GlowColor, Style.GlowAlpha);
    end;
    Inner := Body;
    InflateRect(Inner, -Style.BorderWidth, -Style.BorderWidth);
    Canvas.FrameRoundRect(Inner, Style.Rounding - Style.BorderWidth, 1, clWhite, 120);
  finally
    Canvas.PopClip;
  end;
  Canvas.FrameRoundRect(Body, Style.Rounding, Style.BorderWidth, Style.BorderColor, 255);
end;

procedure TPPGClassicRenderer.DrawField(const Canvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle; FocusProgress: Single; PPI: Integer);
var
  R, BW: Integer;
  P: Single;
  Inner: TRect;
begin
  if IsRectEmpty(Body) then
    Exit;
  P := PPGClampSingle(FocusProgress, 0, 1);
  R := PPGCapRounding(Body, Style.Rounding);
  BW := Style.BorderWidth;
  Canvas.FillRoundRect(Body, R, Style.Color, 255);
  if (P > 0) and (BW > 0) then
  begin
    // Innenschein in Fokusfarbe, innerhalb des Rahmens
    Inner := Body;
    InflateRect(Inner, -BW, -BW);
    if not IsRectEmpty(Inner) then
      Canvas.FrameRoundRect(Inner, PPGCapRounding(Inner, R - BW), PPGScale(2, PPI),
        Style.GlowColor, Round(70 * P));
  end;
  if BW > 0 then
    Canvas.FrameRoundRect(Body, R, BW,
      PPGBlendColor(Style.BorderColor, Style.GlowColor, P), 255);
end;

procedure TPPGClassicRenderer.DrawListItem(const Canvas: IPPGCanvas; const R: TRect;
  const ListStyle, HighlightStyle: TPPGSurfaceStyle; Selected: Boolean;
  Highlight: Single; PPI: Integer);
var
  Body, First, Second: TRect;
  Rad: Integer;
  H: Single;
  Alpha: Byte;
begin
  if IsRectEmpty(R) then
    Exit;
  Body := R;
  InflateRect(Body, -PPGScale(2, PPI), -PPGScale(1, PPI));
  if IsRectEmpty(Body) then
    Body := R;
  Rad := PPGCapRounding(Body, PPGScale(2, PPI));
  H := PPGClampSingle(Highlight, 0, 1);
  if H > 0 then
  begin
    Alpha := Round(255 * H);
    First := Body;
    First.Bottom := Body.Top + (Body.Bottom - Body.Top) * 2 div 5;
    Second := Body;
    Second.Top := First.Bottom;
    Canvas.PushClipRoundRect(Body, Rad);
    try
      Canvas.FillGradientRect(First, HighlightStyle.Color, HighlightStyle.ColorTo,
        gdVertical, Alpha);
      Canvas.FillGradientRect(Second, HighlightStyle.ColorMirror,
        HighlightStyle.ColorMirrorTo, gdVertical, Alpha);
    finally
      Canvas.PopClip;
    end;
    Canvas.FrameRoundRect(Body, Rad, 1, HighlightStyle.BorderColor, Alpha);
  end
  else if Selected then
    // Aktueller Wert ohne Hervorhebung: duenner Rahmen in Glanzfarbe
    Canvas.FrameRoundRect(Body, Rad, 1, HighlightStyle.BorderColor, 160);
end;

procedure TPPGClassicRenderer.DrawItemBackground(const Canvas: IPPGCanvas; const R: TRect;
  const ListStyle, HighlightStyle: TPPGSurfaceStyle; Selected, Focused: Boolean;
  Hot: Single; RightToLeft: Boolean; PPI: Integer);
var
  Body: TRect;
  Rad: Integer;
  H: Single;
begin
  if IsRectEmpty(R) then
    Exit;
  // Gleicher Glanz wie die Combo-Liste: voll fuer gewaehlt, anteilig fuer Hover
  H := PPGClampSingle(Hot, 0, 1);
  if Selected then
    H := 1;
  DrawListItem(Canvas, R, ListStyle, HighlightStyle, False, H, PPI);
  if Focused then
  begin
    Body := R;
    InflateRect(Body, -PPGScale(2, PPI), -PPGScale(1, PPI));
    Rad := PPGCapRounding(Body, PPGScale(2, PPI));
    Canvas.FrameRoundRect(Body, Rad, 1, ListStyle.TextColor, 170);
  end;
end;

procedure TPPGClassicRenderer.DrawTab(const Canvas: IPPGCanvas; const R: TRect;
  const Style: TPPGSurfaceStyle; Selected: Boolean; HotProgress: Single;
  Bottom: Boolean; PPI: Integer);
var
  Body, Clip, First, Second: TRect;
  Rad, Lift: Integer;
begin
  if IsRectEmpty(R) then
    Exit;
  if Selected then
  begin
    inherited DrawTab(Canvas, R, Style, True, HotProgress, Bottom, PPI);
    Exit;
  end;
  // Nicht gewaehlt: etwas niedriger, Glanz-Verlauf, Rahmen zur Seite offen
  Lift := PPGScale(2, PPI);
  Clip := R;
  if Bottom then
    Dec(Clip.Bottom, Lift)
  else
    Inc(Clip.Top, Lift);
  Inc(Clip.Left, 1);
  Dec(Clip.Right, 1);
  if IsRectEmpty(Clip) then
    Exit;
  Rad := PPGCapRounding(Clip, Style.Rounding);
  Body := Clip;
  if Bottom then
    Dec(Body.Top, Rad + 1)
  else
    Inc(Body.Bottom, Rad + 1);
  First := Clip;
  Second := Clip;
  if Bottom then
  begin
    First.Top := Clip.Bottom - (Clip.Bottom - Clip.Top) * 2 div 5;
    Second.Bottom := First.Top;
  end
  else
  begin
    First.Bottom := Clip.Top + (Clip.Bottom - Clip.Top) * 2 div 5;
    Second.Top := First.Bottom;
  end;
  Canvas.PushClipRoundRect(Clip, 0);
  try
    Canvas.PushClipRoundRect(Body, Rad);
    try
      Canvas.FillGradientRect(First, Style.Color, Style.ColorTo, gdVertical, 255);
      Canvas.FillGradientRect(Second, Style.ColorMirror, Style.ColorMirrorTo, gdVertical, 255);
    finally
      Canvas.PopClip;
    end;
    if Style.BorderWidth > 0 then
      Canvas.FrameRoundRect(Body, Rad, Style.BorderWidth, Style.BorderColor, 255);
  finally
    Canvas.PopClip;
  end;
end;

procedure TPPGClassicRenderer.DrawTabIndicator(const Canvas: IPPGCanvas; const R: TRect;
  Color: TColor; Bottom: Boolean; PPI: Integer);
begin
  // Absichtlich leer (siehe Deklaration)
end;

procedure TPPGClassicRenderer.DrawChartBar(const Canvas: IPPGCanvas; const R: TRect;
  Color: TColor; Hot: Single; Vertical, Negative: Boolean; PPI: Integer);
var
  C: TColor;
  First, Second: TRect;
  Dir: TPPGGradientDirection;
begin
  if IsRectEmpty(R) then
    Exit;
  C := Color;
  if Hot > 0 then
    C := PPGBlendColor(Color, clWhite, 0.25 * Hot);
  // Glanz quer zur Wachstumsrichtung: helle Haelfte, dann satte Farbe
  First := R;
  Second := R;
  if Vertical then
  begin
    Dir := gdHorizontal;
    First.Right := (R.Left + R.Right) div 2;
    Second.Left := First.Right;
  end
  else
  begin
    Dir := gdVertical;
    First.Bottom := (R.Top + R.Bottom) div 2;
    Second.Top := First.Bottom;
  end;
  Canvas.FillGradientRect(First, PPGBlendColor(C, clWhite, 0.35), C, Dir, 255);
  Canvas.FillGradientRect(Second, C, PPGDarken(C, 0.15), Dir, 255);
  if (R.Right - R.Left > 4) and (R.Bottom - R.Top > 4) then
    Canvas.FrameRoundRect(R, 0, 1, PPGDarken(C, 0.3), 255);
end;


initialization
  TPPGRendererRegistry.RegisterRenderer(PPGPresetClassic, TPPGClassicRenderer);

finalization
  TPPGRendererRegistry.UnregisterRenderer(PPGPresetClassic);

end.
