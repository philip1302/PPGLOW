unit PPG.GroupBox;

{ TPPGGroupBox - Gruppierung mit Rahmen und Beschriftung.

  Die Beschriftung sitzt als "Plakette" (Pille in der Flaechenfarbe) auf der
  oberen Rahmenlinie. Dadurch braucht der Rahmen keine ausgesparte Luecke,
  und die Optik passt zu den Glow-Presets. Liegt der Fokus auf einem Kind,
  leuchtet die Plakette in der Fokusfarbe (HighlightFocus).

  Migration von TGroupBox: Caption, Padding und die Standard-Properties
  bleiben gueltig. Accelerator (&) fokussiert wie bei TGroupBox das erste Kind. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Container, PPG.ElementStyle;

type
  TPPGCustomGroupBox = class(TPPGCustomContainer)
  private
    FCaptionStyle: TPPGElementStyle;
    FHighlightFocus: Boolean;
    FFocusInside: Boolean;
    procedure SetCaptionStyle(const Value: TPPGElementStyle);
    procedure CaptionStyleChanged(Sender: TObject);
    procedure SetHighlightFocus(const Value: Boolean);
    procedure CMFocusChanged(var Message: TCMFocusChanged); message CM_FOCUSCHANGED;
  protected
    procedure AdjustClientRect(var Rect: TRect); override;
    /// Plakette (leer, wenn keine Caption) und Oberkante des Rahmens.
    procedure GetHeader(out Plate: TRect; out BodyTop: Integer);
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function ChildSurface(out Body: TRect; out Style: TPPGSurfaceStyle): Boolean; override;
    function AccRole: Integer; override;
    property HighlightFocus: Boolean read FHighlightFocus write SetHighlightFocus default True;
    /// Plakette der Beschriftung: Flaeche, Rand, Text und Schrift.
    property CaptionStyle: TPPGElementStyle read FCaptionStyle write SetCaptionStyle;
  public
    destructor Destroy; override;
    constructor Create(AOwner: TComponent); override;
    /// True, wenn ein Kind (auch tiefer verschachtelt) den Fokus hat.
    property FocusInside: Boolean read FFocusInside;
  end;

  TPPGGroupBox = class(TPPGCustomGroupBox)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property HighlightFocus;
    property CaptionStyle;
    property HighContrastSupport;
    { VCL-Standard }
    property Align;
    property Anchors;
    property BiDiMode;
    property Caption;
    property Color;
    property Constraints;
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property Padding;
    property ParentBackground default True;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop default False;
    property Visible;
    property Touch;
    property OnGesture;
    property OnAlignInsertBefore;
    property OnAlignPosition;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDockDrop;
    property OnDockOver;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
  end;

implementation

uses
  System.SysUtils, Winapi.oleacc, PPG.Appearance, PPG.DpiUtils, PPG.Render.Gdi;

const
  PlateIndent = 10;   // logische px vom linken Rand (zusaetzlich zur Rundung)
  PlatePadH = 8;      // Innenabstand der Plakette waagrecht
  PlatePadV = 2;      // und senkrecht
  ContentPad = 4;     // Abstand der Kinder zum Rahmen

{ TPPGCustomGroupBox }

procedure TPPGCustomGroupBox.SetCaptionStyle(const Value: TPPGElementStyle);
begin
  FCaptionStyle.Assign(Value);
end;

procedure TPPGCustomGroupBox.CaptionStyleChanged(Sender: TObject);
begin
  RequestAutoSize;
  Realign;
  Invalidate;
end;

constructor TPPGCustomGroupBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCaptionStyle := TPPGElementStyle.Create(Self);
  FCaptionStyle.OnChange := CaptionStyleChanged;
  FHighlightFocus := True;
end;

destructor TPPGCustomGroupBox.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FCaptionStyle);
end;

procedure TPPGCustomGroupBox.SetHighlightFocus(const Value: Boolean);
begin
  if FHighlightFocus <> Value then
  begin
    FHighlightFocus := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomGroupBox.CMFocusChanged(var Message: TCMFocusChanged);
var
  Inside: Boolean;
begin
  // Wird vom Formular an alle Controls verteilt. Ergebnis zwischenspeichern:
  // Paint darf den Fokus nicht selbst ermitteln (keine Nachrichten im Paint).
  Inside := (Message.Sender <> nil) and (Message.Sender <> Self) and
    ContainsControl(Message.Sender);
  if Inside <> FFocusInside then
  begin
    FFocusInside := Inside;
    if FHighlightFocus then
      Invalidate;
  end;
  inherited;
end;

procedure TPPGCustomGroupBox.GetHeader(out Plate: TRect; out BodyTop: Integer);
var
  PPI, PlateH: Integer;
  TS: TSize;
  S: TPPGSurfaceStyle;
  Temp: TFont;
begin
  Plate := Rect(0, 0, 0, 0);
  BodyTop := 0;
  if Caption = '' then
    Exit;
  PPI := ScalePPI;
  // Ohne Canvas messen: dieselbe Funktion fuer AdjustClientRect und Paint
  Temp := nil;
  try
    TS := PPGMeasureTextNoCanvas(Caption, PPGElementFont(FCaptionStyle, Font, [], Temp), 0, False);
  finally
    Temp.Free;
  end;
  PlateH := TS.cy + 2 * PPGScale(PlatePadV, PPI);
  S := EffectiveAppearance.Resolve(vsNormal, PPI, False);
  Plate.Top := 0;
  Plate.Bottom := PlateH;
  if UseRightToLeftAlignment then
  begin
    Plate.Right := Width - PPGScale(PlateIndent, PPI) - S.Rounding;
    Plate.Left := Plate.Right - TS.cx - 2 * PPGScale(PlatePadH, PPI);
    if Plate.Left < 0 then
      Plate.Left := 0;
  end
  else
  begin
    Plate.Left := PPGScale(PlateIndent, PPI) + S.Rounding;
    Plate.Right := Plate.Left + TS.cx + 2 * PPGScale(PlatePadH, PPI);
    if Plate.Right > Width then
      Plate.Right := Width;
  end;
  BodyTop := PlateH div 2;
end;

procedure TPPGCustomGroupBox.AdjustClientRect(var Rect: TRect);
var
  Plate: TRect;
  BodyTop, Inset, Pad, Top: Integer;
begin
  inherited AdjustClientRect(Rect);
  GetHeader(Plate, BodyTop);
  Inset := ContentInset;
  Pad := PPGScale(ContentPad, ScalePPI);
  Top := BodyTop + Inset;
  if Plate.Bottom > Top then
    Top := Plate.Bottom;
  Inc(Rect.Top, Top + Pad);
  Inc(Rect.Left, Inset + Pad);
  Dec(Rect.Right, Inset + Pad);
  Dec(Rect.Bottom, Inset + Pad);
end;

procedure TPPGCustomGroupBox.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  Temp: TFont;
  Style, PlateStyle: TPPGSurfaceStyle;
  Plate, Body: TRect;
  BodyTop: Integer;
  Flags: Cardinal;
  Highlight: Boolean;
begin
  Style := GetContainerStyle(True);
  GetHeader(Plate, BodyTop);
  Body := ClientR;
  Body.Top := BodyTop;
  ContainerRenderer.DrawContainer(ACanvas, Body, Style);
  if IsRectEmpty(Plate) then
    Exit;

  PlateStyle := Style;
  PlateStyle.Rounding := (Plate.Bottom - Plate.Top) div 2;
  // CaptionStyle: eigene Flaeche, Rand und Textfarbe der Plakette
  if not (HighContrastSupport and PPGIsHighContrast) and not UseVclStyle then
  begin
    if FCaptionStyle.HasFill(UseDarkMode) then
    begin
      PlateStyle.Color := FCaptionStyle.FillFor(UseDarkMode, PlateStyle.Color);
      PlateStyle.ColorTo := PlateStyle.Color;
      PlateStyle.ColorMirror := PlateStyle.Color;
      PlateStyle.ColorMirrorTo := PlateStyle.Color;
    end;
    PlateStyle.BorderColor := FCaptionStyle.BorderFor(UseDarkMode, PlateStyle.BorderColor);
    if Enabled then
      PlateStyle.TextColor := FCaptionStyle.TextFor(UseDarkMode, PlateStyle.TextColor);
  end;
  Highlight := FHighlightFocus and FFocusInside and Enabled and
    not (HighContrastSupport and PPGIsHighContrast);
  if Highlight then
  begin
    // Fokus in der Gruppe: Plakette leuchtet in der Fokusfarbe
    PlateStyle.BorderColor := PPGColorToRGB(EffectiveAppearance.FocusColor);
    ACanvas.DrawOuterGlow(Plate, PlateStyle.Rounding, PPGScale(3, ScalePPI),
      PlateStyle.BorderColor, 110);
  end;
  ContainerRenderer.DrawContainer(ACanvas, Plate, PlateStyle);

  Flags := DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOCLIP or DT_END_ELLIPSIS;
  if not AcceleratorCuesVisible then
    Flags := Flags or DT_HIDEPREFIX;
  Temp := nil;
  try
    ACanvas.DrawText(Plate, Caption, PPGElementFont(FCaptionStyle, Font, [], Temp),
      PlateStyle.TextColor, DrawTextBiDiModeFlags(Flags));
  finally
    Temp.Free;
  end;
end;

function TPPGCustomGroupBox.ChildSurface(out Body: TRect;
  out Style: TPPGSurfaceStyle): Boolean;
var
  Plate: TRect;
  BodyTop: Integer;
begin
  GetHeader(Plate, BodyTop);
  Body := Rect(0, BodyTop, Width, Height);
  Style := GetContainerStyle(True);
  Result := True;
end;

function TPPGCustomGroupBox.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_GROUPING;
end;

end.
