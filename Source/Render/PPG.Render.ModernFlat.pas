unit PPG.Render.ModernFlat;

{ Preset "ModernFlat": flache Flaechen, abgerundete Ecken, weicher
  aeusserer Leuchtrand in Akzentfarbe (Fluent-/Neon-Stil). }

{$I ..\PPG.inc}

interface

uses
  System.Types, Vcl.Graphics, PPG.Types, PPG.Appearance, PPG.Tokens, PPG.Render.Intf,
  PPG.Render.Registry;

type
  TPPGModernFlatRenderer = class(TPPGRendererBase)
  public
    function Name: string; override;
    procedure ApplyDefaults(Appearance: TPPGAppearance); override;
    function Tokens(Dark: Boolean): TPPGTokens; override;
    function BodyInset(const Style: TPPGSurfaceStyle): Integer; override;
    procedure DrawSurface(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle); override;
  end;

implementation

uses
  PPG.Consts;

const
  Accent = $00D77800; // RGB(0,120,215)

function TPPGModernFlatRenderer.Name: string;
begin
  Result := PPGPresetModernFlat;
end;

function TPPGModernFlatRenderer.Tokens(Dark: Boolean): TPPGTokens;
begin
  Result := PPGDefaultTokens(Dark);
  if not Dark then
  begin
    // Hell: exakt die bisherigen ModernFlat-Farben (bestehende DFMs/Optik)
    Result.Accent := Accent;
    Result.AccentHover := $00E58A1A;
    Result.AccentPressed := $00A35A00;
    Result.OnAccent := $00FFFFFF;
    Result.Background := $00F3F3F3;
    Result.Layer := $00FBFBFB;
    Result.Surface := $00FBFBFB;
    Result.SurfaceHover := $00FFF7EF;
    Result.SurfacePressed := $00F5E3CC;
    Result.SurfaceDisabled := $00F3F3F3;
    Result.Stroke := $00CFCFCF;
    Result.StrokeStrong := $00A0A0A0;
    Result.StrokeDisabled := $00E0E0E0;
    Result.TextPrimary := $00202020;
    Result.TextSecondary := $005D5D5D;
    Result.TextDisabled := $00A0A0A0;
    Result.Danger := PPGColorError;
    Result.Warning := PPGColorWarning;
    Result.Success := PPGColorSuccess;
    Result.Paused := $0000B9FF;
  end
  else
  begin
    // Dunkel: Windows-11-Dunkel mit hellerem Akzent (#4CC2FF) fuer Kontrast
    Result.Accent := $00FFC24C;
    Result.AccentHover := $00FFCF6E;
    Result.AccentPressed := $00D9A040;
    Result.OnAccent := $00000000;
    Result.Background := $00202020;
    Result.Layer := $002B2B2B;
    Result.Surface := $002D2D2D;
    Result.SurfaceHover := $00383838;
    Result.SurfacePressed := $0047331D;
    Result.SurfaceDisabled := $00292929;
    // Kraeftiger als die Windows-Vorgabe: leere Kaestchen/Kreise brauchen
    // auf dunklem Grund einen sichtbaren Rand
    Result.Stroke := $005C5C5C;
    Result.StrokeStrong := $00707070;
    Result.StrokeDisabled := $00383838;
    Result.TextPrimary := $00F0F0F0;
    Result.TextSecondary := $00C5C5C5;
    Result.TextDisabled := $007A7A7A;
  end;
  Result.RadiusSmall := 4;
  Result.RadiusMedium := 6;
  Result.RadiusLarge := 8;
  Result.StrokeWidth := 1;
  Result.DurationNormal := 150;
end;

procedure TPPGModernFlatRenderer.ApplyDefaults(Appearance: TPPGAppearance);
begin
  Appearance.BeginUpdate;
  try
    ApplyThemeColors(Appearance, False);
    // Form des Presets: Glow-Staerken, Rundung, Rahmen
    Appearance.Normal.GlowAlpha := 0;
    Appearance.Hot.GlowAlpha := 150;
    Appearance.Down.GlowAlpha := 210;
    Appearance.Disabled.GlowAlpha := 0;
    Appearance.Checked.GlowAlpha := 0;
    Appearance.Rounding := 6;
    Appearance.BorderWidth := 1;
    Appearance.GlowSize := 5;
  finally
    Appearance.EndUpdate;
  end;
end;

function TPPGModernFlatRenderer.BodyInset(const Style: TPPGSurfaceStyle): Integer;
begin
  // Platz fuer den aeusseren Glow, damit der Koerper beim Hover nicht springt
  Result := Style.GlowSize;
end;

procedure TPPGModernFlatRenderer.DrawSurface(const Canvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle);
begin
  if IsRectEmpty(Body) then
    Exit;
  if Style.GlowAlpha > 0 then
    Canvas.DrawOuterGlow(Body, Style.Rounding, Style.GlowSize, Style.GlowColor, Style.GlowAlpha);
  if Style.Color = Style.ColorTo then
    Canvas.FillRoundRect(Body, Style.Rounding, Style.Color, 255)
  else
  begin
    Canvas.PushClipRoundRect(Body, Style.Rounding);
    try
      Canvas.FillGradientRect(Body, Style.Color, Style.ColorTo, Style.Direction, 255);
    finally
      Canvas.PopClip;
    end;
  end;
  Canvas.FrameRoundRect(Body, Style.Rounding, Style.BorderWidth, Style.BorderColor, 255);
end;

initialization
  TPPGRendererRegistry.RegisterRenderer(PPGPresetModernFlat, TPPGModernFlatRenderer);

finalization
  TPPGRendererRegistry.UnregisterRenderer(PPGPresetModernFlat);

end.
