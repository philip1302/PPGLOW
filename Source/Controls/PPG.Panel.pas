unit PPG.Panel;

{ TPPGPanel - Container-Flaeche in der Optik des Presets (abgerundet,
  Rahmen, im Classic-Preset mit dezentem Verlauf).

  Migration von TPanel: Caption, Alignment, VerticalAlignment, ShowCaption,
  Padding und die Bevel-Properties bleiben gueltig (Bevels zeichnet nur die
  VCL selbst bei BevelKind <> bkNone). Color bestimmt nur den Hintergrund
  hinter den abgerundeten Ecken (ParentBackground = False); die Flaeche kommt
  aus Appearance.Normal.

  Scrollen (Phase 18d): AutoScroll, HorzScrollBar und VertScrollBar wie
  TScrollingWinControl. Gescrollt werden echte Kind-Fenster (Lage wird
  verschoben, Neuzeichnen per WM_SETREDRAW gebuendelt), Rahmen und
  Beschriftung des Panels bleiben stehen. Die Leisten liegen in einem
  schmalen Streifen am Rand (Kind-Fenster lassen sich nicht ueberlagern) und
  kommen vom Scroll-Renderer des Presets wie bei Liste und Grid. Mausrad (auch
  ueber Kind-Controls, die es nicht nutzen: Windows reicht es weiter),
  weiches Scrollen, Tab zu einem verdeckten Kind holt es ins Bild
  (ScrollInView). TPPGScrollBox ist ein Panel mit AutoScroll = True und
  BorderStyle wie TScrollBox. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, Vcl.Controls, Vcl.Graphics,
  Vcl.Forms, PPG.Types, PPG.Render.Intf, PPG.Animation, PPG.Controls.Container;

type
  TPPGCustomPanel = class;

  /// Einstellungen einer Leiste (DFM-kompatibel zu TControlScrollBar).
  TPPGPanelScrollBar = class(TPersistent)
  private
    FOwner: TPPGCustomPanel;
    FKind: TScrollBarKind;
    FVisible: Boolean;
    FRange: Integer;
    FIncrement: Integer;
    FTracking: Boolean;
    FSmooth: Boolean;
    function GetPosition: Integer;
    procedure SetPosition(const Value: Integer);
    procedure SetVisible(const Value: Boolean);
    procedure SetRange(const Value: Integer);
    procedure SetIncrement(const Value: Integer);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TPPGCustomPanel; AKind: TScrollBarKind);
    procedure Assign(Source: TPersistent); override;
    /// Wird die Leiste gebraucht und gezeigt?
    function IsScrollBarVisible: Boolean;
    property Kind: TScrollBarKind read FKind;
  published
    property Visible: Boolean read FVisible write SetVisible default True;
    /// Inhaltsgroesse in Pixeln; mit AutoScroll aus den Kind-Controls berechnet.
    property Range: Integer read FRange write SetRange default 0;
    property Increment: Integer read FIncrement write SetIncrement default 8;
    property Position: Integer read GetPosition write SetPosition default 0;
    /// Inhalt folgt dem Daumen beim Ziehen (sonst erst beim Loslassen).
    property Tracking: Boolean read FTracking write FTracking default False;
    /// Weiches Scrollen (Mausrad, Klick in die Spur).
    property Smooth: Boolean read FSmooth write FSmooth default True;
  end;

  TPPGCustomPanel = class(TPPGCustomContainer)
  private
    FAlignment: TAlignment;
    FVerticalAlignment: TVerticalAlignment;
    FShowCaption: Boolean;
    FNoFrame: Boolean;
    FAutoScroll: Boolean;
    FHorzBar, FVertBar: TPPGPanelScrollBar;
    FScroll: TPoint;
    FRange: TSize;          // Inhaltsgroesse (Pixel)
    FNeedH, FNeedV: Boolean;
    FUpdatingRange: Boolean;
    FDragBar: Integer;      // -1 = keine, 0 = waagerecht, 1 = senkrecht
    FDragOffset: Integer;
    FHotBar: Integer;
    FAnim: TPPGAnimation;
    FAnimFrom, FAnimTo: TPoint;
    procedure SetAlignment(const Value: TAlignment);
    procedure SetVerticalAlignment(const Value: TVerticalAlignment);
    procedure SetShowCaption(const Value: Boolean);
    procedure SetAutoScroll(const Value: Boolean);
    procedure SetHorzBar(const Value: TPPGPanelScrollBar);
    procedure SetVertBar(const Value: TPPGPanelScrollBar);
    procedure SetNoFrame(const Value: Boolean);
    procedure AnimStep(Sender: TObject);
    procedure MoveContent(DX, DY: Integer);
    procedure CMFocusChanged(var Message: TCMFocusChanged); message CM_FOCUSCHANGED;
    procedure CMControlChange(var Message: TCMControlChange); message CM_CONTROLCHANGE;
    function GetContentSize: TSize;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    /// Ohne Fensterhandle meldet die VCL Kind-Bewegungen nicht (kein AlignControls):
    /// dann vor jeder Abfrage neu messen.
    procedure EnsureRange;
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure CreateWnd; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function ChildOverlapsDecoration(const R: TRect): Boolean; override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    /// ClientRect ohne Fensterhandle (Width/Height minus BorderWidth), damit das
    /// Rechnen auch vor dem Anzeigen und ohne Parent geht.
    function SafeClientRect: TRect;
    /// Innenbereich ohne Leisten und ohne Verschiebung (Client-Koordinaten).
    function ViewArea: TRect;
    /// Scrollen aktiv (AutoScroll oder feste Range)?
    function Scrollable: Boolean;
    /// Inhaltsgroesse neu bestimmen (Kind-Controls bzw. Range).
    procedure UpdateScrollRange;
    function BarThickness: Integer;
    function BarTrack(Vertical: Boolean): TRect;
    function BarThumb(Vertical: Boolean): TRect;
    procedure PaintScrollBars(const ACanvas: IPPGCanvas);
    /// Ohne Rahmen und Flaeche (TScrollBox.BorderStyle = bsNone).
    property NoFrame: Boolean read FNoFrame write SetNoFrame default False;
    property Alignment: TAlignment read FAlignment write SetAlignment default taCenter;
    property VerticalAlignment: TVerticalAlignment read FVerticalAlignment
      write SetVerticalAlignment default taVerticalCenter;
    property ShowCaption: Boolean read FShowCaption write SetShowCaption default True;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Lage des Inhalts setzen (begrenzt). Animate: weich.
    procedure ScrollTo(X, Y: Integer; Animate: Boolean = False);
    /// Kind-Control (auch verschachtelt) vollstaendig ins Bild holen.
    procedure ScrollInView(AControl: TControl);
    /// Inhaltsgroesse (mit AutoScroll aus den Kind-Controls).
    property ContentSize: TSize read GetContentSize;
    property ScrollPos: TPoint read FScroll;
    property AutoScroll: Boolean read FAutoScroll write SetAutoScroll default False;
    property HorzScrollBar: TPPGPanelScrollBar read FHorzBar write SetHorzBar;
    property VertScrollBar: TPPGPanelScrollBar read FVertBar write SetVertBar;
  end;

  TPPGPanel = class(TPPGCustomPanel)
  private
    FBorderStyle: TBorderStyle;
    procedure SetBorderStyle(const Value: TBorderStyle);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  published
    /// bsSingle: Rahmen des Fensters wie TPanel (mit Ctl3D vertieft).
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsNone;
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
    property AutoScroll;
    property HorzScrollBar;
    property VertScrollBar;
    property Animation;
    { VCL-Standard }
    property Align;
    property Anchors;
    property BevelEdges;
    property BevelInner default bvNone;
    property BevelKind;
    property BevelOuter default bvRaised;
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
    property OnMouseWheel;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseActivate;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
    property Action;
    // Audit 5d Stufe 3: wie VCL
    property OnCanResize;
  end;

  /// Wie TScrollBox: AutoScroll = True, ohne Beschriftung; BorderStyle bsNone
  /// zeichnet weder Rahmen noch Flaeche (Hintergrund des Parents).
  TPPGScrollBox = class(TPPGCustomPanel)
  private
    function GetBorderStyle: TBorderStyle;
    procedure SetBorderStyle(const Value: TBorderStyle);
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property RoundedCorners;
    property HighContrastSupport;
    property AutoScroll default True;
    property HorzScrollBar;
    property VertScrollBar;
    property Animation;
    property BorderStyle: TBorderStyle read GetBorderStyle write SetBorderStyle default bsSingle;
    { VCL-Standard }
    property Align;
    property Anchors;
    property BevelEdges;
    property BevelInner default bvNone;
    property BevelKind;
    property BevelOuter default bvRaised;
    property BevelWidth;
    property BiDiMode;
    property BorderWidth;
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
    property OnMouseWheel;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseActivate;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

implementation

uses
  System.SysUtils, System.Math, PPG.Appearance, PPG.Render.Gdi, PPG.Render.Registry, PPG.DpiUtils,
  PPG.Accessibility, PPG.Exceptions, PPG.Lang, PPG.Consts, PPG.Controls.Base;

const
  CaptionPadding = 6; // logische px zwischen Rahmen und Beschriftung
  BarSize = 10;       // logische px: Streifen der Leiste
  MinThumb = 24;
  WheelLine = 16;     // logische px je Zeile (Zeilen je Raste: Systemeinstellung)
  ScrollMs = 150;

{ TPPGPanelScrollBar }

constructor TPPGPanelScrollBar.Create(AOwner: TPPGCustomPanel; AKind: TScrollBarKind);
begin
  inherited Create;
  FOwner := AOwner;
  FKind := AKind;
  FVisible := True;
  FIncrement := 8;
  FSmooth := True;
end;

function TPPGPanelScrollBar.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TPPGPanelScrollBar.Assign(Source: TPersistent);
var
  S: TPPGPanelScrollBar;
begin
  if Source is TPPGPanelScrollBar then
  begin
    S := TPPGPanelScrollBar(Source);
    FVisible := S.FVisible;
    FRange := S.FRange;
    FIncrement := S.FIncrement;
    FTracking := S.FTracking;
    FSmooth := S.FSmooth;
    FOwner.UpdateScrollRange;
  end
  else
    inherited Assign(Source);
end;

function TPPGPanelScrollBar.IsScrollBarVisible: Boolean;
begin
  FOwner.EnsureRange;
  if FKind = sbHorizontal then
    Result := FOwner.FNeedH
  else
    Result := FOwner.FNeedV;
end;

function TPPGPanelScrollBar.GetPosition: Integer;
begin
  if FKind = sbHorizontal then
    Result := FOwner.FScroll.X
  else
    Result := FOwner.FScroll.Y;
end;

procedure TPPGPanelScrollBar.SetPosition(const Value: Integer);
begin
  if FKind = sbHorizontal then
    FOwner.ScrollTo(Value, FOwner.FScroll.Y)
  else
    FOwner.ScrollTo(FOwner.FScroll.X, Value);
end;

procedure TPPGPanelScrollBar.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    FOwner.UpdateScrollRange;
  end;
end;

procedure TPPGPanelScrollBar.SetRange(const Value: Integer);
begin
  if FRange <> Value then
  begin
    FRange := PPGCheckRange(FOwner, 'Range', Value, 0, MaxInt div 2);
    FOwner.UpdateScrollRange;
  end;
end;

procedure TPPGPanelScrollBar.SetIncrement(const Value: Integer);
begin
  FIncrement := PPGCheckRange(FOwner, 'Increment', Value, 1, 32767);
end;

{ TPPGCustomPanel }

constructor TPPGCustomPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Wie TPanel (die VCL zeichnet sie nur mit BevelKind <> bkNone)
  BevelInner := bvNone;
  BevelOuter := bvRaised;
  Width := 185;
  Height := 41;
  FAlignment := taCenter;
  FVerticalAlignment := taVerticalCenter;
  FShowCaption := True;
  UseDockManager := True;
  FHorzBar := TPPGPanelScrollBar.Create(Self, sbHorizontal);
  FVertBar := TPPGPanelScrollBar.Create(Self, sbVertical);
  FDragBar := -1;
  FHotBar := -1;
  FAnim := TPPGAnimation.Create(Self);
  FAnim.OnStep := AnimStep;
end;

destructor TPPGCustomPanel.Destroy;
begin
  FreeAndNil(FAnim);
  inherited Destroy;
  FreeAndNil(FVertBar);
  FreeAndNil(FHorzBar);
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

procedure TPPGCustomPanel.SetNoFrame(const Value: Boolean);
begin
  if FNoFrame <> Value then
  begin
    FNoFrame := Value;
    LayoutChanged;
  end;
end;

procedure TPPGCustomPanel.SetAutoScroll(const Value: Boolean);
begin
  if FAutoScroll <> Value then
  begin
    FAutoScroll := Value;
    if not Value and (FHorzBar.Range = 0) and (FVertBar.Range = 0) then
      ScrollTo(0, 0);
    UpdateScrollRange;
  end;
end;

procedure TPPGCustomPanel.SetHorzBar(const Value: TPPGPanelScrollBar);
begin
  FHorzBar.Assign(Value);
end;

procedure TPPGCustomPanel.SetVertBar(const Value: TPPGPanelScrollBar);
begin
  FVertBar.Assign(Value);
end;

function TPPGCustomPanel.Scrollable: Boolean;
begin
  Result := FAutoScroll or (FHorzBar.Range > 0) or (FVertBar.Range > 0);
end;

function TPPGCustomPanel.BarThickness: Integer;
begin
  Result := PPGScale(BarSize, ScalePPI);
end;

procedure TPPGCustomPanel.AdjustClientRect(var Rect: TRect);
var
  D: Integer;
  SI: TRect;
begin
  inherited AdjustClientRect(Rect);
  if not FNoFrame then
  begin
    D := ContentInset;
    InflateRect(Rect, -D, -D);
  end;
  SI := ShadowInsets;
  Inc(Rect.Left, SI.Left);
  Inc(Rect.Top, SI.Top);
  Dec(Rect.Right, SI.Right);
  Dec(Rect.Bottom, SI.Bottom);
  if not Scrollable then
    Exit;
  // Platz fuer die Leisten; ausgerichtete Kinder liegen im verschobenen Bereich
  // ueber die ganze Inhaltsgroesse (wie TScrollingWinControl)
  if FNeedV then
    if UseRightToLeftAlignment then
      Inc(Rect.Left, BarThickness)
    else
      Dec(Rect.Right, BarThickness);
  if FNeedH then
    Dec(Rect.Bottom, BarThickness);
  Rect := Bounds(Rect.Left - FScroll.X, Rect.Top - FScroll.Y,
    Max(Rect.Right - Rect.Left, FRange.cx), Max(Rect.Bottom - Rect.Top, FRange.cy));
end;

procedure TPPGCustomPanel.EnsureRange;
begin
  if Scrollable and not HandleAllocated and not FUpdatingRange then
    UpdateScrollRange;
end;

function TPPGCustomPanel.GetContentSize: TSize;
begin
  EnsureRange;
  Result := FRange;
end;

procedure TPPGCustomPanel.CMControlChange(var Message: TCMControlChange);
begin
  inherited;
  if Scrollable then
    UpdateScrollRange;
end;

function TPPGCustomPanel.SafeClientRect: TRect;
begin
  if HandleAllocated then
    Result := ClientRect
  else
  begin
    Result := Rect(0, 0, Width, Height);
    InflateRect(Result, -BorderWidth, -BorderWidth);
  end;
end;

function TPPGCustomPanel.ViewArea: TRect;
var
  SaveScroll: TPoint;
  SaveRange: TSize;
begin
  // AdjustClientRect ohne Verschiebung und ohne Aufweitung auf den Inhalt
  SaveScroll := FScroll;
  SaveRange := FRange;
  FScroll := Point(0, 0);
  FRange.cx := 0;
  FRange.cy := 0;
  try
    Result := SafeClientRect;
    AdjustClientRect(Result);
  finally
    FScroll := SaveScroll;
    FRange := SaveRange;
  end;
end;

procedure TPPGCustomPanel.AlignControls(AControl: TControl; var Rect: TRect);
begin
  inherited AlignControls(AControl, Rect);
  // Kinder haben sich bewegt: Inhaltsgroesse nachziehen
  if Scrollable and not FUpdatingRange then
    UpdateScrollRange;
end;

procedure TPPGCustomPanel.UpdateScrollRange;
var
  I, W, H: Integer;
  C: TControl;
  View: TRect;
  OldH, OldV: Boolean;
  Pass: Integer;
begin
  if FUpdatingRange or (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  if not Scrollable then
  begin
    // Kein Scrollen: nichts messen (und kein Fensterhandle anlegen)
    if FNeedH or FNeedV then
    begin
      FNeedH := False;
      FNeedV := False;
      Realign;
    end;
    FRange.cx := 0;
    FRange.cy := 0;
    Exit;
  end;
  FUpdatingRange := True;
  try
    // Zwei Durchgaenge: eine Leiste nimmt Platz und kann die andere noetig machen
    for Pass := 0 to 1 do
    begin
      // Inhaltskoordinate = Lage im Client + Scrollposition - Oberkante der Sicht
      View := ViewArea;
      W := 0;
      H := 0;
      if FAutoScroll then
        for I := 0 to ControlCount - 1 do
        begin
          C := Controls[I];
          if not C.Visible and not (csDesigning in ComponentState) then
            Continue;
          // Ausgerichtete Kinder fuellen den Bereich und bestimmen ihn nicht
          if C.Align in [alClient, alRight, alBottom] then
            Continue;
          if C.Align <> alTop then
            W := Max(W, C.Left + C.Width + C.Margins.Right * Ord(C.AlignWithMargins) +
              FScroll.X - View.Left);
          if C.Align <> alLeft then
            H := Max(H, C.Top + C.Height + C.Margins.Bottom * Ord(C.AlignWithMargins) +
              FScroll.Y - View.Top);
        end;
      if FHorzBar.Range > 0 then
        W := FHorzBar.Range;
      if FVertBar.Range > 0 then
        H := FVertBar.Range;
      OldH := FNeedH;
      OldV := FNeedV;
      FRange.cx := W;
      FRange.cy := H;
      FNeedH := Scrollable and FHorzBar.Visible and (W > View.Right - View.Left);
      FNeedV := Scrollable and FVertBar.Visible and (H > View.Bottom - View.Top);
      if (OldH = FNeedH) and (OldV = FNeedV) then
        Break;
    end;
    // Lage begrenzen (Inhalt kleiner geworden)
    View := ViewArea;
    ScrollTo(Min(FScroll.X, Max(0, FRange.cx - (View.Right - View.Left))),
      Min(FScroll.Y, Max(0, FRange.cy - (View.Bottom - View.Top))));
  finally
    FUpdatingRange := False;
  end;
  Invalidate;
end;

procedure TPPGCustomPanel.Loaded;
begin
  inherited Loaded;
  UpdateScrollRange;
end;

procedure TPPGCustomPanel.CreateWnd;
begin
  inherited CreateWnd;
  if Scrollable then
    UpdateScrollRange;
end;

procedure TPPGCustomPanel.Resize;
begin
  inherited Resize;
  if Scrollable then
    UpdateScrollRange;
end;

procedure TPPGCustomPanel.MoveContent(DX, DY: Integer);
var
  I: Integer;
  C: TControl;
  Redraw, WasUpdating: Boolean;
begin
  if (DX = 0) and (DY = 0) then
    Exit;
  // Alle Kinder verschieben; Neuzeichnen einmal am Ende (kein Flackern)
  Redraw := HandleAllocated and IsWindowVisible(Handle);
  if Redraw then
    SendMessage(Handle, WM_SETREDRAW, 0, 0);
  DisableAlign;
  WasUpdating := FUpdatingRange;
  FUpdatingRange := True;
  try
    for I := 0 to ControlCount - 1 do
    begin
      C := Controls[I];
      if C.Align in [alNone, alCustom] then
        C.SetBounds(C.Left + DX, C.Top + DY, C.Width, C.Height);
    end;
  finally
    FUpdatingRange := WasUpdating;
    EnableAlign; // ausgerichtete Kinder folgen ueber AdjustClientRect
    if Redraw then
    begin
      SendMessage(Handle, WM_SETREDRAW, 1, 0);
      RedrawWindow(Handle, nil, 0, RDW_INVALIDATE or RDW_ALLCHILDREN or RDW_ERASE or RDW_FRAME);
    end;
  end;
end;

procedure TPPGCustomPanel.ScrollTo(X, Y: Integer; Animate: Boolean);
var
  View: TRect;
  Old: TPoint;
begin
  if not FUpdatingRange then
    EnsureRange;
  if csLoading in ComponentState then
  begin
    // Beim Laden (Position aus der DFM): merken, Begrenzung folgt mit dem Bereich
    FScroll := Point(Max(0, X), Max(0, Y));
    Exit;
  end;
  View := ViewArea;
  X := Max(0, Min(X, FRange.cx - (View.Right - View.Left)));
  Y := Max(0, Min(Y, FRange.cy - (View.Bottom - View.Top)));
  if not FNeedH then
    X := 0;
  if not FNeedV then
    Y := 0;
  if Animate and Animation.EffectiveEnabled and HandleAllocated then
  begin
    FAnimFrom := FScroll;
    FAnimTo := Point(X, Y);
    FAnim.Jump(0);
    FAnim.AnimateTo(1, ScrollMs, ekDecelerate);
    Exit;
  end;
  FAnim.Stop;
  Old := FScroll;
  if (Old.X = X) and (Old.Y = Y) then
    Exit;
  FScroll := Point(X, Y);
  MoveContent(Old.X - X, Old.Y - Y);
  Invalidate;
end;

procedure TPPGCustomPanel.AnimStep(Sender: TObject);
var
  P: Single;
  Old: TPoint;
  X, Y: Integer;
begin
  P := FAnim.Value;
  X := Round(FAnimFrom.X + (FAnimTo.X - FAnimFrom.X) * P);
  Y := Round(FAnimFrom.Y + (FAnimTo.Y - FAnimFrom.Y) * P);
  Old := FScroll;
  FScroll := Point(X, Y);
  MoveContent(Old.X - X, Old.Y - Y);
  Invalidate;
end;

procedure TPPGCustomPanel.ScrollInView(AControl: TControl);
var
  R, View: TRect;
  P: TPoint;
  X, Y: Integer;
  C: TControl;
begin
  EnsureRange;
  if (AControl = nil) or not Scrollable or not ContainsControl(AControl) then
    Exit;
  // Zusammengesetzte Controls (Feld mit innerem Edit): das ganze Control zeigen.
  // Hoch bis zum naechsten Vorfahren, der Kinder aufnimmt (Container) - der
  // Container selbst kann groesser als die Sicht sein.
  while (AControl.Parent <> nil) and (AControl.Parent <> Self) and
    not (csAcceptsControls in AControl.Parent.ControlStyle) do
    AControl := AControl.Parent;
  // Lage des Controls relativ zum Panel ueber die Parent-Kette (auch tief
  // verschachtelt, ohne Fensterhandle)
  P := Point(0, 0);
  C := AControl;
  while (C <> nil) and (C <> Self) do
  begin
    Inc(P.X, C.Left);
    Inc(P.Y, C.Top);
    C := C.Parent;
  end;
  R := Bounds(P.X, P.Y, AControl.Width, AControl.Height);
  View := ViewArea;
  X := FScroll.X;
  Y := FScroll.Y;
  if R.Right > View.Right then
    Inc(X, R.Right - View.Right);
  if R.Left - (FScroll.X - X) < View.Left then
    X := X - (View.Left - (R.Left - (FScroll.X - X)));
  if R.Bottom > View.Bottom then
    Inc(Y, R.Bottom - View.Bottom);
  if R.Top - (Y - FScroll.Y) < View.Top then
    Y := Y - (View.Top - (R.Top - (Y - FScroll.Y)));
  ScrollTo(X, Y);
end;

procedure TPPGCustomPanel.CMFocusChanged(var Message: TCMFocusChanged);
begin
  inherited;
  // Wie TScrollingWinControl.AutoScrollInView: Tab zu einem verdeckten Kind
  if FAutoScroll and (Message.Sender <> nil) and (Message.Sender <> Self) and
    ContainsControl(Message.Sender) then
    ScrollInView(Message.Sender);
end;

function TPPGCustomPanel.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
var
  Step, Lines: Integer;
  Horz, Smooth: Boolean;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if Result or not Scrollable then
    Exit;
  Horz := (ssShift in Shift) or not FNeedV;
  if Horz and not FNeedH then
    Exit;
  // Audit 7b: Zeilen aus der Systemeinstellung, Teil-Deltas gesammelt
  Lines := PPGWheelScrollLines;
  if Lines < 0 then
  begin
    // seitenweise
    if Horz then
      Step := ClientWidth
    else
      Step := ClientHeight;
  end
  else
    Step := Lines * PPGScale(WheelLine, ScalePPI);
  Step := WheelSteps(WheelDelta, Step);
  if Horz then
  begin
    Smooth := FHorzBar.Smooth;
    ScrollTo(FScroll.X - Step, FScroll.Y, Smooth and (Abs(WheelDelta) >= WHEEL_DELTA));
  end
  else
  begin
    Smooth := FVertBar.Smooth;
    ScrollTo(FScroll.X, FScroll.Y - Step, Smooth and (Abs(WheelDelta) >= WHEEL_DELTA));
  end;
  Result := True;
end;

{ Leisten }

function TPPGCustomPanel.BarTrack(Vertical: Boolean): TRect;
var
  View: TRect;
  B: Integer;
begin
  Result := Rect(0, 0, 0, 0);
  View := ViewArea;
  B := BarThickness;
  if Vertical and FNeedV then
  begin
    if UseRightToLeftAlignment then
      Result := Rect(View.Left - B, View.Top, View.Left, View.Bottom)
    else
      Result := Rect(View.Right, View.Top, View.Right + B, View.Bottom);
  end
  else if not Vertical and FNeedH then
    Result := Rect(View.Left, View.Bottom, View.Right, View.Bottom + B);
end;

function TPPGCustomPanel.BarThumb(Vertical: Boolean): TRect;
var
  T, View: TRect;
  Len, ViewLen, Content, ThumbLen, MaxS, Off: Integer;
begin
  EnsureRange;
  T := BarTrack(Vertical);
  if IsRectEmpty(T) then
    Exit(T);
  View := ViewArea;
  if Vertical then
  begin
    Len := T.Bottom - T.Top;
    ViewLen := View.Bottom - View.Top;
    Content := FRange.cy;
    Off := FScroll.Y;
  end
  else
  begin
    Len := T.Right - T.Left;
    ViewLen := View.Right - View.Left;
    Content := FRange.cx;
    Off := FScroll.X;
  end;
  ThumbLen := Max(PPGScale(MinThumb, ScalePPI), MulDiv(Len, ViewLen, Max(Content, 1)));
  ThumbLen := Min(ThumbLen, Len);
  MaxS := Max(Content - ViewLen, 1);
  Off := MulDiv(Len - ThumbLen, Off, MaxS);
  if Vertical then
    Result := Rect(T.Left, T.Top + Off, T.Right, T.Top + Off + ThumbLen)
  else
    Result := Rect(T.Left + Off, T.Top, T.Left + Off + ThumbLen, T.Bottom);
end;

procedure TPPGCustomPanel.PaintScrollBars(const ACanvas: IPPGCanvas);
var
  SR: IPPGScrollRenderer;
  St: TPPGSurfaceStyle;
  V: Boolean;
  A: TPPGAppearance;
begin
  if not FNeedH and not FNeedV then
    Exit;
  if not Supports(Renderer, IPPGScrollRenderer, SR) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName), IPPGScrollRenderer, SR);
  if SR = nil then
    Exit;
  A := EffectiveAppearance;
  St := GetContainerStyle(False);
  St.TextColor := PPGColorToRGB(A.Normal.TextColor);
  if HighContrastSupport and PPGIsHighContrast then
    St.TextColor := PPGColorToRGB(clWindowText);
  for V := False to True do
    if not IsRectEmpty(BarTrack(V)) then
      SR.DrawScrollBar(ACanvas, BarTrack(V), BarThumb(V), St, V, 1, FHotBar = Ord(V),
        FDragBar = Ord(V), ScalePPI);
end;

procedure TPPGCustomPanel.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  V: Boolean;
  T, Th: TRect;
  View: TRect;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button <> mbLeft) or not Scrollable then
    Exit;
  View := ViewArea;
  for V := False to True do
  begin
    T := BarTrack(V);
    if not PtInRect(T, Point(X, Y)) then
      Continue;
    Th := BarThumb(V);
    if PtInRect(Th, Point(X, Y)) then
    begin
      FDragBar := Ord(V);
      if V then
        FDragOffset := Y - Th.Top
      else
        FDragOffset := X - Th.Left;
    end
    // Klick in die Spur: eine Seite weiter
    else if V then
    begin
      if Y < Th.Top then
        ScrollTo(FScroll.X, FScroll.Y - (View.Bottom - View.Top), FVertBar.Smooth)
      else
        ScrollTo(FScroll.X, FScroll.Y + (View.Bottom - View.Top), FVertBar.Smooth);
    end
    else if X < Th.Left then
      ScrollTo(FScroll.X - (View.Right - View.Left), FScroll.Y, FHorzBar.Smooth)
    else
      ScrollTo(FScroll.X + (View.Right - View.Left), FScroll.Y, FHorzBar.Smooth);
    Invalidate;
    Exit;
  end;
end;

procedure TPPGCustomPanel.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  T, Th, View: TRect;
  Hot, Len, ThumbLen, Content, ViewLen, P: Integer;
  V: Boolean;
begin
  inherited MouseMove(Shift, X, Y);
  if not Scrollable then
    Exit;
  if FDragBar >= 0 then
  begin
    V := FDragBar = 1;
    T := BarTrack(V);
    Th := BarThumb(V);
    View := ViewArea;
    if V then
    begin
      Len := T.Bottom - T.Top;
      ThumbLen := Th.Bottom - Th.Top;
      Content := FRange.cy;
      ViewLen := View.Bottom - View.Top;
      P := Y - FDragOffset - T.Top;
    end
    else
    begin
      Len := T.Right - T.Left;
      ThumbLen := Th.Right - Th.Left;
      Content := FRange.cx;
      ViewLen := View.Right - View.Left;
      P := X - FDragOffset - T.Left;
    end;
    if Len - ThumbLen <= 0 then
      Exit;
    P := MulDiv(P, Content - ViewLen, Len - ThumbLen);
    // Tracking: Inhalt folgt sofort (sonst ebenfalls - nur ohne Animation)
    if V then
      ScrollTo(FScroll.X, P)
    else
      ScrollTo(P, FScroll.Y);
    Exit;
  end;
  Hot := -1;
  if PtInRect(BarTrack(True), Point(X, Y)) then
    Hot := 1
  else if PtInRect(BarTrack(False), Point(X, Y)) then
    Hot := 0;
  if Hot <> FHotBar then
  begin
    FHotBar := Hot;
    Invalidate;
  end;
end;

procedure TPPGCustomPanel.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if FDragBar >= 0 then
  begin
    FDragBar := -1;
    Invalidate;
  end;
end;

procedure TPPGCustomPanel.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHotBar <> -1 then
  begin
    FHotBar := -1;
    Invalidate;
  end;
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
  if not FNoFrame then
  begin
    Old := PPGSetSquareCorners(ACanvas, SquareCorners);
    try
      PaintShadow(ACanvas, Body, Style.Rounding);
      ContainerRenderer.DrawContainer(ACanvas, Body, Style);
    finally
      PPGSetSquareCorners(ACanvas, Old);
    end;
  end;
  PaintScrollBars(ACanvas);
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

{ TPPGScrollBox }

constructor TPPGScrollBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 185;
  Height := 105;
  ShowCaption := False;
  AutoScroll := True;
end;

{ TPPGPanel }

procedure TPPGPanel.SetBorderStyle(const Value: TBorderStyle);
begin
  if FBorderStyle <> Value then
  begin
    FBorderStyle := Value;
    RecreateWnd;
  end;
end;

procedure TPPGPanel.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Wie TCustomPanel.CreateParams
  if FBorderStyle = bsSingle then
    if NewStyleControls and Ctl3D then
      Params.ExStyle := Params.ExStyle or WS_EX_CLIENTEDGE
    else
      Params.Style := Params.Style or WS_BORDER;
end;

function TPPGScrollBox.GetBorderStyle: TBorderStyle;
begin
  if NoFrame then
    Result := bsNone
  else
    Result := bsSingle;
end;

procedure TPPGScrollBox.SetBorderStyle(const Value: TBorderStyle);
begin
  NoFrame := Value = bsNone;
end;

end.
