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

  AutoSize (veroeffentlicht von Panel, ScrollBox und GroupBox): Der Container
  wird so gross, dass seine sichtbaren Kinder samt Rahmen, Rundung und Padding
  hineinpassen (CalcAutoSize). Regeln je Kind:
  - frei platziert (alNone): rechte bzw. untere Kante zaehlt; mit Anker nur
    rechts/unten zaehlen Groesse und Randabstand, gedehnte Kinder (Anker
    links und rechts) nur Randabstaende und Constraints.MinWidth/MinHeight -
    sonst wuerde der Container ihnen hinterherwachsen bzw. -schrumpfen,
  - alTop/alLeft: Unterkante bzw. rechte Kante des Stapels,
  - alBottom/alRight: ihre Hoehen bzw. Breiten werden addiert,
  - alClient: fuellt nur aus und bestimmt nichts.
  Bestimmt kein Kind eine Richtung (z.B. leeres Panel), bleibt sie, wie sie
  ist. Constraints begrenzen das Ergebnis wie bei jedem Control. Wie in der
  VCL wirkt AutoSize erst mit Fensterhandle vollstaendig (Kind-Bewegungen
  meldet die VCL sonst nicht); beim Anlegen des Fensters wird nachgezogen. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Base;

type
  TPPGCustomContainer = class(TPPGCustomControl)
  private
    FAutoSizing: Boolean;
    /// Groesse an die Kinder anpassen (nur mit AutoSize, nicht verschachtelt).
    procedure FitToChildren;
    procedure CMControlChange(var Message: TCMControlChange); message CM_CONTROLCHANGE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
  protected
    procedure UpdateVisualState(Animate: Boolean = True); override;
    procedure AppearanceUpdated; override;
    procedure CreateWnd; override;
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;
    procedure AdjustSize; override;
    /// AutoSize: Groesse aus den Kindern (siehe Kopfkommentar).
    function CalcAutoSize(out AWidth, AHeight: Integer): Boolean; override;
    /// Bereich, in dem die Kinder liegen (Client-Koordinaten, ohne Verschiebung
    /// durch Scrollen): Grundlage fuer AutoSize.
    function AutoSizeView: TRect; virtual;
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
  System.SysUtils, System.Math, Winapi.oleacc, PPG.Appearance, PPG.DpiUtils, PPG.VclStyles,
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

{ ---- AutoSize ---- }

type
  // Constraints ist in TControl nicht in jeder Version oeffentlich
  TContainerChildAccess = class(TControl);

procedure TPPGCustomContainer.CreateWnd;
begin
  inherited CreateWnd;
  // Ohne Fensterhandle meldet die VCL Kind-Bewegungen nicht: jetzt nachziehen
  FitToChildren;
end;

procedure TPPGCustomContainer.AlignControls(AControl: TControl; var Rect: TRect);
begin
  inherited AlignControls(AControl, Rect);
  // Kinder wurden ausgerichtet, verschoben oder in der Groesse geaendert
  FitToChildren;
end;

procedure TPPGCustomContainer.AdjustSize;
begin
  if FAutoSizing then
    Exit;
  FAutoSizing := True;
  try
    inherited AdjustSize;
  finally
    FAutoSizing := False;
  end;
  FitToChildren;
end;

procedure TPPGCustomContainer.CMControlChange(var Message: TCMControlChange);
begin
  inherited;
  // Kind eingefuegt oder entfernt
  FitToChildren;
end;

procedure TPPGCustomContainer.FitToChildren;
var
  Pass, W, H: Integer;
begin
  if FAutoSizing or not AutoSize or (csLoading in ComponentState) or
    (csDestroying in ComponentState) then
    Exit;
  FAutoSizing := True;
  try
    // Die eigene Groessenaenderung richtet die Kinder neu aus (Anker,
    // Scrollleisten): hoechstens drei Durchgaenge, bis die Groesse steht
    for Pass := 1 to 3 do
    begin
      W := Width;
      H := Height;
      RequestAutoSize;
      if (W = Width) and (H = Height) then
        Break;
    end;
  finally
    FAutoSizing := False;
  end;
end;

function TPPGCustomContainer.AutoSizeView: TRect;
begin
  // Wie TPPGCustomPanel.SafeClientRect: ClientRect legte sonst ein Handle an
  if HandleAllocated then
    Result := ClientRect
  else
  begin
    Result := Rect(0, 0, Width, Height);
    InflateRect(Result, -BorderWidth, -BorderWidth);
  end;
  // Rahmen, Rundung, Beschriftung und Padding (VCL) abziehen
  AdjustClientRect(Result);
end;

function TPPGCustomContainer.CalcAutoSize(out AWidth, AHeight: Integer): Boolean;
var
  View: TRect;
  I, ML, MT, MR, MB, ExtW, ExtH, SumR, SumB, Need: Integer;
  C: TControl;
  HasW, HasH: Boolean;
begin
  AWidth := Width;
  AHeight := Height;
  View := AutoSizeView;
  ExtW := 0;
  ExtH := 0;
  SumR := 0;
  SumB := 0;
  HasW := False;
  HasH := False;
  for I := 0 to ControlCount - 1 do
  begin
    C := Controls[I];
    if not C.Visible and not (csDesigning in ComponentState) then
      Continue;
    // Margins wirken in der VCL nur mit AlignWithMargins
    if C.AlignWithMargins then
    begin
      ML := C.Margins.Left;
      MT := C.Margins.Top;
      MR := C.Margins.Right;
      MB := C.Margins.Bottom;
    end
    else
    begin
      ML := 0;
      MT := 0;
      MR := 0;
      MB := 0;
    end;
    case C.Align of
      alClient:
        Continue; // fuellt aus, bestimmt nichts
      alTop:
        begin
          ExtH := Max(ExtH, C.Top + C.Height + MB - View.Top);
          HasH := True;
        end;
      alBottom:
        begin
          Inc(SumB, MT + C.Height + MB);
          HasH := True;
        end;
      alLeft:
        begin
          ExtW := Max(ExtW, C.Left + C.Width + MR - View.Left);
          HasW := True;
        end;
      alRight:
        begin
          Inc(SumR, ML + C.Width + MR);
          HasW := True;
        end;
    else
      begin
        // Frei platziert (auch alCustom): Anker entscheiden, was zaehlt
        if not (akRight in C.Anchors) then
          Need := C.Left + C.Width - View.Left
        else if akLeft in C.Anchors then
          Need := C.Left - View.Left + TContainerChildAccess(C).Constraints.MinWidth +
            (View.Right - C.Left - C.Width)
        else
          Need := C.Width + (View.Right - C.Left - C.Width);
        ExtW := Max(ExtW, Need);
        if not (akBottom in C.Anchors) then
          Need := C.Top + C.Height - View.Top
        else if akTop in C.Anchors then
          Need := C.Top - View.Top + TContainerChildAccess(C).Constraints.MinHeight +
            (View.Bottom - C.Top - C.Height)
        else
          Need := C.Height + (View.Bottom - C.Top - C.Height);
        ExtH := Max(ExtH, Need);
        HasW := True;
        HasH := True;
      end;
    end;
  end;
  if HasW then
    AWidth := Width - (View.Right - View.Left) + Max(0, ExtW + SumR);
  if HasH then
    AHeight := Height - (View.Bottom - View.Top) + Max(0, ExtH + SumB);
  Result := HasW or HasH;
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
  if UseHighContrast then
  begin
    // Hochkontrast: Systemfarben aus der Appearance; Rahmen immer sichtbar
    if Result.BorderWidth < 1 then
      Result.BorderWidth := 1;
  end
  else if UseVclStyle then
  begin
    PPGVclStyleContainerColors(GroupBox, Enabled, Fill, Border, Text);
    Result.Color := Fill;
    Result.ColorTo := Fill;
    Result.ColorMirror := Fill;
    Result.ColorMirrorTo := Fill;
    Result.BorderColor := Border;
    Result.TextColor := Text;
  end;
end;

function TPPGCustomContainer.ContainerRenderer: IPPGContainerRenderer;
begin
  if not Supports(Renderer, IPPGContainerRenderer, Result) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
      IPPGContainerRenderer, Result);
end;

function TPPGCustomContainer.ChildSurface(out Body: TRect; out Style: TPPGSurfaceStyle): Boolean;
var
  SI: TRect;
begin
  Body := Rect(0, 0, Width, Height);
  // ohne den Platz fuer den Schatten (Panel)
  SI := ShadowInsets;
  Inc(Body.Left, SI.Left);
  Inc(Body.Top, SI.Top);
  Dec(Body.Right, SI.Right);
  Dec(Body.Bottom, SI.Bottom);
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
