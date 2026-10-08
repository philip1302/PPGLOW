unit PPG.Panel;

{ TPPGPanel - Container-Flaeche in der Optik des Presets (abgerundet,
  Rahmen, im Classic-Preset mit dezentem Verlauf).

  Migration von TPanel: Caption, Alignment, VerticalAlignment, ShowCaption,
  Padding und die Bevel-Properties bleiben gueltig (Bevels zeichnet nur die
  VCL selbst bei BevelKind <> bkNone). Color bestimmt nur den Hintergrund
  hinter den abgerundeten Ecken (ParentBackground = False); die Flaeche kommt
  aus Appearance.Normal. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.Types, Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Container;

type
  TPPGCustomPanel = class(TPPGCustomContainer)
  private
    FAlignment: TAlignment;
    FVerticalAlignment: TVerticalAlignment;
    FShowCaption: Boolean;
    procedure SetAlignment(const Value: TAlignment);
    procedure SetVerticalAlignment(const Value: TVerticalAlignment);
    procedure SetShowCaption(const Value: Boolean);
  protected
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function ChildOverlapsDecoration(const R: TRect): Boolean; override;
    property Alignment: TAlignment read FAlignment write SetAlignment default taCenter;
    property VerticalAlignment: TVerticalAlignment read FVerticalAlignment
      write SetVerticalAlignment default taVerticalCenter;
    property ShowCaption: Boolean read FShowCaption write SetShowCaption default True;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TPPGPanel = class(TPPGCustomPanel)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Alignment;
    property VerticalAlignment;
    property ShowCaption;
    property WordWrap;
    property RoundedCorners;
    property Shadow;
    property HighContrastSupport;
    { VCL-Standard }
    property Align;
    property Anchors;
    property BevelEdges;
    property BevelInner;
    property BevelKind;
    property BevelOuter;
    property BevelWidth;
    property BiDiMode;
    property BorderWidth;
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
    property UseDockManager default True;
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
  PPG.Appearance, PPG.Render.Gdi, PPG.Accessibility;

const
  CaptionPadding = 6; // logische px zwischen Rahmen und Beschriftung

{ TPPGCustomPanel }

constructor TPPGCustomPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 185;
  Height := 41;
  FAlignment := taCenter;
  FVerticalAlignment := taVerticalCenter;
  FShowCaption := True;
  UseDockManager := True;
end;

procedure TPPGCustomPanel.SetAlignment(const Value: TAlignment);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomPanel.SetVerticalAlignment(const Value: TVerticalAlignment);
begin
  if FVerticalAlignment <> Value then
  begin
    FVerticalAlignment := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomPanel.SetShowCaption(const Value: Boolean);
begin
  if FShowCaption <> Value then
  begin
    FShowCaption := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomPanel.AdjustClientRect(var Rect: TRect);
var
  D: Integer;
  SI: TRect;
begin
  inherited AdjustClientRect(Rect);
  D := ContentInset;
  InflateRect(Rect, -D, -D);
  SI := ShadowInsets;
  Inc(Rect.Left, SI.Left);
  Inc(Rect.Top, SI.Top);
  Dec(Rect.Right, SI.Right);
  Dec(Rect.Bottom, SI.Bottom);
end;

function TPPGCustomPanel.ChildOverlapsDecoration(const R: TRect): Boolean;
var
  TextR, CapR, Tmp: TRect;
  D, X, Y: Integer;
  Sz: TSize;
begin
  // Liegt ein Kind ueber der Beschriftung, muss es sie als Hintergrund sehen:
  // dann der exakte (langsame) Weg ueber DrawParentBackground
  Result := False;
  if not FShowCaption or (Caption = '') then
    Exit;
  if WordWrap then
    Exit(True); // mehrzeilig: nicht nachrechnen, sicher ist sicher
  TextR := Rect(0, 0, Width, Height);
  D := GetContainerStyle(False).BorderWidth + PPGScale(CaptionPadding, ScalePPI);
  InflateRect(TextR, -D, -D);
  Sz := PPGMeasureTextNoCanvas(PPGAccStripHotkey(Caption), Font, 0, False);
  case FAlignment of
    taLeftJustify: X := TextR.Left;
    taRightJustify: X := TextR.Right - Sz.cx;
  else
    X := (TextR.Left + TextR.Right - Sz.cx) div 2;
  end;
  case FVerticalAlignment of
    taAlignTop: Y := TextR.Top;
    taAlignBottom: Y := TextR.Bottom - Sz.cy;
  else
    Y := (TextR.Top + TextR.Bottom - Sz.cy) div 2;
  end;
  CapR := Rect(X, Y, X + Sz.cx, Y + Sz.cy);
  Result := IntersectRect(Tmp, CapR, R);
end;

procedure TPPGCustomPanel.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  Style: TPPGSurfaceStyle;
  TextR, Body, SI: TRect;
  Old: TPPGCorners;
  Flags: Cardinal;
  D: Integer;
  TextSize: TSize;
begin
  Style := GetContainerStyle(False);
  // Flaeche ohne den Platz fuer den Schatten; eckige Ecken nur fuer die Flaeche
  Body := ClientR;
  SI := ShadowInsets;
  Inc(Body.Left, SI.Left);
  Inc(Body.Top, SI.Top);
  Dec(Body.Right, SI.Right);
  Dec(Body.Bottom, SI.Bottom);
  Old := PPGSetSquareCorners(ACanvas, SquareCorners);
  try
    PaintShadow(ACanvas, Body, Style.Rounding);
    ContainerRenderer.DrawContainer(ACanvas, Body, Style);
  finally
    PPGSetSquareCorners(ACanvas, Old);
  end;
  if not FShowCaption or (Caption = '') then
    Exit;

  TextR := Body;
  D := Style.BorderWidth + PPGScale(CaptionPadding, ScalePPI);
  InflateRect(TextR, -D, -D);
  if IsRectEmpty(TextR) then
    Exit;
  case FAlignment of
    taLeftJustify: Flags := DT_LEFT;
    taRightJustify: Flags := DT_RIGHT;
  else
    Flags := DT_CENTER;
  end;
  Flags := Flags or DT_NOCLIP or DT_END_ELLIPSIS;
  if not AcceleratorCuesVisible then
    Flags := Flags or DT_HIDEPREFIX;
  if WordWrap then
  begin
    // DT_VCENTER/DT_BOTTOM wirken nur einzeilig -> selbst positionieren
    Flags := Flags or DT_WORDBREAK;
    TextSize := ACanvas.MeasureText(Caption, Font, TextR.Right - TextR.Left, True);
    case FVerticalAlignment of
      taVerticalCenter: TextR.Top := TextR.Top + (TextR.Bottom - TextR.Top - TextSize.cy) div 2;
      taAlignBottom: TextR.Top := TextR.Bottom - TextSize.cy;
    end;
  end
  else
  begin
    Flags := Flags or DT_SINGLELINE;
    case FVerticalAlignment of
      taVerticalCenter: Flags := Flags or DT_VCENTER;
      taAlignBottom: Flags := Flags or DT_BOTTOM;
    end;
  end;
  ACanvas.DrawText(TextR, Caption, Font, Style.TextColor, DrawTextBiDiModeFlags(Flags));
end;

end.
