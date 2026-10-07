unit PPG.Controls.Container;

{ TPPGCustomContainer - gemeinsame Basis fuer Panel und GroupBox.

  - Nimmt Controls auf (csAcceptsControls -> WS_CLIPCHILDREN, WS_EX_CONTROLPARENT)
  - Kein Hover-/Druckzustand: ein Container reagiert nicht auf die Maus
  - Farben: Appearance.Normal (bzw. Panel-Farben des VCL-Styles), ohne Glow
  - AdjustClientRect haelt Kinder (auch Align = alClient) innerhalb von
    Rahmen und Rundung. Aendern sich Schrift, Caption oder Appearance,
    werden die Kinder neu ausgerichtet.

  Kinder mit ParentBackground (auch PPGlow-Controls) holen sich ihren
  Hintergrund per WM_PRINTCLIENT vom Container; dessen Paint zeichnet dann
  in den DC des Kindes. Paint sendet deshalb keine Nachrichten (siehe Basis).

  AutoSize wird bewusst nicht angeboten (Groesse aus den Kindern waere ein
  eigenes, von TWinControl abweichendes Regelwerk). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Base;

type
  TPPGCustomContainer = class(TPPGCustomControl)
  private
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
  protected
    procedure UpdateVisualState(Animate: Boolean = True); override;
    procedure AppearanceUpdated; override;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    procedure DoAccelerator; override;
    /// Kinder neu ausrichten, wenn sich der Innenbereich geaendert haben kann.
    procedure LayoutChanged;
    /// Abstand der Kinder zum Rand (Rahmen + Rundung), ohne Padding.
    function ContentInset: Integer;
    /// Flaechenstil des Containers (Hochkontrast > VCL-Style > Appearance).
    function GetContainerStyle(GroupBox: Boolean): TPPGSurfaceStyle;
    function ContainerRenderer: IPPGContainerRenderer;
    /// Flaeche, auf der die Kinder liegen (Rechteck und Stil wie beim Zeichnen).
    /// False = keine einfache Flaeche: Kinder holen den Hintergrund exakt.
    function ChildSurface(out Body: TRect; out Style: TPPGSurfaceStyle): Boolean; virtual;
    /// True, wenn R (Client) ueber Beschriftung o.ae. liegt, die der schnelle
    /// Hintergrund nicht kennt (z.B. Panel-Caption).
    function ChildOverlapsDecoration(const R: TRect): Boolean; virtual;
    function GetChildBackground(Child: TControl; out ColorTop, ColorBottom: TColor): Boolean; override;
    function AccRole: Integer; override;
    function AccDefaultAction: string; override;
    procedure AccDoDefaultAction; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  System.SysUtils, Winapi.oleacc, PPG.Appearance, PPG.DpiUtils, PPG.VclStyles,
  PPG.Render.Registry;

{ TPPGCustomContainer }

constructor TPPGCustomContainer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csAcceptsControls, csCaptureMouse, csClickEvents, csSetCaption,
    csDoubleClicks, csReplicatable, csParentBackground];
  TabStop := False;
  Width := 185;
  Height := 105;
end;

procedure TPPGCustomContainer.UpdateVisualState(Animate: Boolean);
begin
  // Kein Zustandswechsel bei Maus/Tastatur -> auch kein Neuzeichnen
end;

procedure TPPGCustomContainer.AppearanceUpdated;
begin
  inherited AppearanceUpdated;
  LayoutChanged; // Rahmen/Rundung bestimmen den Innenbereich
end;

function TPPGCustomContainer.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGCustomContainer.IsDown: Boolean;
begin
  Result := False;
end;

procedure TPPGCustomContainer.DoAccelerator;
begin
  // Wie TGroupBox: Accelerator fokussiert das erste Kind
  SelectFirst;
end;

procedure TPPGCustomContainer.LayoutChanged;
begin
  if not (csLoading in ComponentState) and not (csDestroying in ComponentState) then
    Realign;
  Invalidate;
end;

procedure TPPGCustomContainer.CMFontChanged(var Message: TMessage);
begin
  inherited;
  LayoutChanged;
end;

procedure TPPGCustomContainer.CMTextChanged(var Message: TMessage);
begin
  inherited;
  LayoutChanged;
end;

procedure TPPGCustomContainer.CMStyleChanged(var Message: TMessage);
begin
  inherited;
  LayoutChanged;
end;

function TPPGCustomContainer.ContentInset: Integer;
var
  S: TPPGSurfaceStyle;
begin
  S := EffectiveAppearance.Resolve(vsNormal, ScalePPI, False);
  // Ein Rechteck-Kind beruehrt die Rundung nicht, wenn es um
  // r * (1 - 1/Wurzel 2), also gut 0,3 r, nach innen versetzt ist.
  Result := S.BorderWidth + (S.Rounding * 3 + 9) div 10;
end;

function TPPGCustomContainer.GetContainerStyle(GroupBox: Boolean): TPPGSurfaceStyle;
var
  A: TPPGAppearance;
  Fill, Border, Text: TColor;
begin
  A := EffectiveAppearance;
  Result := A.Resolve(vsNormal, ScalePPI, False);
  Result.GlowAlpha := 0;
  if not Enabled then
    Result.TextColor := PPGColorToRGB(A.Disabled.TextColor);
  if UseVclStyle then
  begin
    PPGVclStyleContainerColors(GroupBox, Enabled, Fill, Border, Text);
    Result.Color := Fill;
    Result.ColorTo := Fill;
    Result.ColorMirror := Fill;
    Result.ColorMirrorTo := Fill;
    Result.BorderColor := Border;
    Result.TextColor := Text;
  end;
  if HighContrastSupport and PPGIsHighContrast then
  begin
    Result.Color := PPGColorToRGB(clBtnFace);
    Result.ColorTo := Result.Color;
    Result.ColorMirror := Result.Color;
    Result.ColorMirrorTo := Result.Color;
    Result.BorderColor := PPGColorToRGB(clWindowText);
    if Enabled then
      Result.TextColor := PPGColorToRGB(clBtnText)
    else
      Result.TextColor := PPGColorToRGB(clGrayText);
    if Result.BorderWidth < 1 then
      Result.BorderWidth := 1;
  end;
end;

function TPPGCustomContainer.ContainerRenderer: IPPGContainerRenderer;
begin
  if not Supports(Renderer, IPPGContainerRenderer, Result) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
      IPPGContainerRenderer, Result);
end;

function TPPGCustomContainer.ChildSurface(out Body: TRect; out Style: TPPGSurfaceStyle): Boolean;
begin
  Body := Rect(0, 0, Width, Height);
  Style := GetContainerStyle(False);
  Result := True;
end;

function TPPGCustomContainer.ChildOverlapsDecoration(const R: TRect): Boolean;
begin
  Result := False;
end;

function TPPGCustomContainer.GetChildBackground(Child: TControl; out ColorTop,
  ColorBottom: TColor): Boolean;
var
  Body, Inner, R: TRect;
  Style: TPPGSurfaceStyle;
  H, D: Integer;
begin
  ColorTop := clNone;
  ColorBottom := clNone;
  Result := False;
  if (Child = nil) or not ChildSurface(Body, Style) then
    Exit;
  // Nur, wenn das Kind ganz im Inneren liegt (nicht ueber Rahmen/Rundung)
  Inner := Body;
  D := ContentInset;
  InflateRect(Inner, -D, -D);
  R := Child.BoundsRect;
  if (R.Left < Inner.Left) or (R.Top < Inner.Top) or (R.Right > Inner.Right) or
    (R.Bottom > Inner.Bottom) or ChildOverlapsDecoration(R) then
    Exit;
  if Style.Color = Style.ColorMirrorTo then
  begin
    ColorTop := Style.Color;
    ColorBottom := Style.Color;
  end
  else
  begin
    // Senkrechter Verlauf wie in DrawContainer (Color -> ColorMirrorTo)
    H := Body.Bottom - Body.Top;
    if H <= 0 then
      Exit;
    ColorTop := PPGBlendColor(Style.Color, Style.ColorMirrorTo, (R.Top - Body.Top) / H);
    ColorBottom := PPGBlendColor(Style.Color, Style.ColorMirrorTo, (R.Bottom - Body.Top) / H);
  end;
  Result := True;
end;

function TPPGCustomContainer.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_PANE;
end;

function TPPGCustomContainer.AccDefaultAction: string;
begin
  Result := '';
end;

procedure TPPGCustomContainer.AccDoDefaultAction;
begin
  // Container haben keine Standardaktion
end;

end.
