unit PPG.TrackBar;

{ TPPGTrackBar - Schieberegler mit Glow-Griff.

  Bedienung:
  - Maus: Klick auf die Schiene setzt den Wert direkt dorthin und startet
    das Ziehen (wie Fluent/Windows 11); Klick auf den Griff zieht ohne Sprung.
  - Tastatur wie TTrackBar: Pfeile = LineSize, Bild auf/ab = PageSize,
    Pos1/Ende = Min/Max. Bei RTL sind Links/Rechts gespiegelt.
  - Mausrad: eine Raste = LineSize (nach unten = groesser, wie TTrackBar).
  - Vertikal steht Min oben (wie TTrackBar).

  Geometrie (alles in einer Funktion, damit Zeichnen und Hit-Test nie
  auseinanderlaufen): siehe GetGeometry.

  Auswahlbereich (Phase 20d): SelStart/SelEnd/ShowSelRange wie TTrackBar -
  ein hervorgehobener Bereich auf der Schiene mit Marken an den Enden.

  Bereichsregler (RangeMode): zwei Griffe, Position = Anfang, PositionEnd =
  Ende; sie ueberholen sich nicht. Klick auf die Schiene bewegt den naeheren
  Griff, Tab wechselt den Griff (danach verlaesst Tab das Control).
  Screenreader: zwei Kinder "Von"/"Bis" mit ihrem Wert.

  Migration: Typen und Property-Namen von TTrackBar (Vcl.ComCtrls).
  Nicht unterstuetzt: PositionToolTip, manuelle Ticks per SetTick
  (tsManual zeigt nur Anfang und Ende). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.ComCtrls,
  PPG.Types, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Range;

type
  /// Ergebnis der Layout-Berechnung (Pixel, bereits DPI-skaliert).
  TPPGSliderGeometry = record
    Vertical: Boolean;
    Reverse: Boolean;       // Min am rechten/unteren Ende
    ThumbSize: Integer;
    TravelStart: Integer;   // Griffmitte bei Min (bzw. Max bei Reverse), Hauptachse
    TravelEnd: Integer;
    Center: Integer;        // Mitte von Schiene und Griff, Querachse
    TickLen: Integer;
    TickGap: Integer;
  end;

  TPPGCustomTrackBar = class(TPPGCustomRangeControl, IPPGAccessibleChildren)
  private
    FSelStart: Integer;
    FSelEnd: Integer;
    FShowSelRange: Boolean;
    FRangeMode: Boolean;
    FPositionEnd: Integer;
    FActiveThumb: Integer;      // 0 = Position, 1 = PositionEnd (RangeMode)
    FOrientation: TTrackBarOrientation;
    FTickMarks: TTickMark;
    FTickStyle: TTickStyle;
    FFrequency: Integer;
    FLineSize: Integer;
    FPageSize: Integer;
    FThumbLength: Integer;
    FSliderVisible: Boolean;
    FDragging: Boolean;
    FDragOffset: Integer;
    FOnTracking: TNotifyEvent;
    procedure SetSelStart(const Value: Integer);
    procedure SetSelEnd(const Value: Integer);
    procedure SetShowSelRange(const Value: Boolean);
    procedure SetRangeMode(const Value: Boolean);
    procedure SetPositionEnd(const Value: Integer);
    procedure SetPositionEndInternal(Value: Int64);
    procedure SetThumbValue(Thumb: Integer; Value: Int64);
    function ThumbValue(Thumb: Integer): Integer;
    procedure SetOrientation(const Value: TTrackBarOrientation);
    procedure SetTickMarks(const Value: TTickMark);
    procedure SetTickStyle(const Value: TTickStyle);
    procedure SetFrequency(const Value: Integer);
    procedure SetLineSize(const Value: Integer);
    procedure SetPageSize(const Value: Integer);
    procedure SetThumbLength(const Value: Integer);
    procedure SetSliderVisible(const Value: Boolean);
    function PixelOf(const G: TPPGSliderGeometry; Value: Double): Integer;
    function ValueAtPixel(const G: TPPGSliderGeometry; Pixel: Integer): Integer;
    function MainCoord(X, Y: Integer): Integer;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean; override;
    function DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean; override;
    procedure DoAccelerator; override;
    function IsDown: Boolean; override;
    function CalcAutoSize(out AWidth, AHeight: Integer): Boolean; override;

    function GetGeometry: TPPGSliderGeometry;
    function ThumbRect: TRect; overload;
    /// Griff Thumb (0 = Position, 1 = PositionEnd im RangeMode).
    function ThumbRect(Thumb: Integer): TRect; overload;
    procedure Loaded; override;
    function AccValue: string; override;
    procedure PositionChanged(OldPosition: Integer); override;
    { IPPGAccessibleChildren: im RangeMode die beiden Griffe }
    function AccChildCount: Integer;
    function AccChildName(Id: Integer): string;
    function AccChildRole(Id: Integer): Integer;
    function AccChildState(Id: Integer): Integer;
    function AccChildRect(Id: Integer): TRect;
    function AccChildAt(X, Y: Integer): Integer;
    function AccChildDefaultAction(Id: Integer): string;
    procedure AccChildDoDefault(Id: Integer);
    function AccFocusedChild: Integer;
    function AccSelectedChild: Integer;
    function GetThumbStyle: TPPGSurfaceStyle;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure PaintTicks(const ACanvas: IPPGCanvas; const G: TPPGSliderGeometry;
      Color: TColor);
    function AccRole: Integer; override;
    function AccState: Integer; override;
    function AccDefaultAction: string; override;
    procedure AccDoDefaultAction; override;

    property Orientation: TTrackBarOrientation read FOrientation write SetOrientation default trHorizontal;
    property TickMarks: TTickMark read FTickMarks write SetTickMarks default tmBottomRight;
    property TickStyle: TTickStyle read FTickStyle write SetTickStyle default tsAuto;
    property Frequency: Integer read FFrequency write SetFrequency default 1;
    property LineSize: Integer read FLineSize write SetLineSize default 1;
    property PageSize: Integer read FPageSize write SetPageSize default 2;
    /// Durchmesser des Griffs in logischen 96-DPI-Pixeln (wie TTrackBar).
    property ThumbLength: Integer read FThumbLength write SetThumbLength default 20;
    property ShowSlider: Boolean read FSliderVisible write SetSliderVisible default True;
    /// Hervorgehobener Bereich auf der Schiene (wie TTrackBar); gleich = keiner.
    property SelStart: Integer read FSelStart write SetSelStart default 0;
    property SelEnd: Integer read FSelEnd write SetSelEnd default 0;
    property ShowSelRange: Boolean read FShowSelRange write SetShowSelRange default True;
    /// Zwei Griffe: Position = Anfang, PositionEnd = Ende des Bereichs.
    property RangeMode: Boolean read FRangeMode write SetRangeMode default False;
    property PositionEnd: Integer read FPositionEnd write SetPositionEnd default 0;
    /// Waehrend der Anwender den Griff zieht, bei jeder Wertaenderung (wie TTrackBar).
    property OnTracking: TNotifyEvent read FOnTracking write FOnTracking;
  public
    constructor Create(AOwner: TComponent); override;
    /// True waehrend der Benutzer den Griff zieht.
    function Dragging: Boolean;
    /// Griff, der gezogen wird bzw. die Tastatur hat (RangeMode).
    property ActiveThumb: Integer read FActiveThumb;
  end;

  TPPGTrackBar = class(TPPGCustomTrackBar)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Min default 0;
    property Max default 10;
    property Position default 0;
    property Orientation;
    property Frequency;
    property LineSize;
    property PageSize;
    property TickMarks;
    property TickStyle;
    property ThumbLength;
    property ShowSlider;
    property SelStart;
    property SelEnd;
    property ShowSelRange;
    property RangeMode;
    property PositionEnd;
    property ShowFocusRect;
    property HighContrastSupport;
    property OnChange;
    { VCL-Standard }
    property Align;
    property Anchors;
    property AutoSize;
    property BiDiMode;
    property Color;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Hint;
    property ParentBackground default True;
    property ParentBiDiMode;
    property ParentColor;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Touch;
    property OnGesture;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnClick;
    property OnMouseWheel;
    property OnMouseActivate;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
    // Audit 5d Stufe 3: wie VCL
    property OnTracking;
  end;

implementation

uses
  System.SysUtils, Winapi.oleacc, PPG.Appearance, PPG.DpiUtils, PPG.Lang, PPG.Consts;

const
  GrooveThickness = 4;   // logische px
  TickLength = 4;
  TickGapSize = 3;
  MinTickSpacing = 3;    // px; dichtere Ticks werden ausgelassen (nur Enden)
  PPGMinThumbLength = 8;
  PPGMaxThumbLength = 100;

{ TPPGCustomTrackBar }

constructor TPPGCustomTrackBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  TabStop := True;
  Width := 150;
  Height := 40;
  SetRange(0, 10);
  FTickMarks := tmBottomRight;
  FTickStyle := tsAuto;
  FFrequency := 1;
  FLineSize := 1;
  FPageSize := 2;
  FThumbLength := 20;
  FSliderVisible := True;
  FShowSelRange := True;
end;

procedure TPPGCustomTrackBar.Loaded;
begin
  inherited Loaded;
  // Erst jetzt stehen Min, Max und Position fest
  FPositionEnd := ClampPosition(FPositionEnd);
  if FRangeMode and (FPositionEnd < Position) then
    FPositionEnd := Position;
end;

procedure TPPGCustomTrackBar.PositionChanged(OldPosition: Integer);
begin
  inherited PositionChanged(OldPosition);
  // Code setzt den Anfang hinter das Ende: das Ende wandert mit
  if FRangeMode and not (csLoading in ComponentState) and (Position > FPositionEnd) then
    FPositionEnd := Position;
end;

{ ---- Auswahlbereich und Bereichsregler (Phase 20d) ---- }

procedure TPPGCustomTrackBar.SetSelStart(const Value: Integer);
begin
  if FSelStart <> Value then
  begin
    FSelStart := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomTrackBar.SetSelEnd(const Value: Integer);
begin
  if FSelEnd <> Value then
  begin
    FSelEnd := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomTrackBar.SetShowSelRange(const Value: Boolean);
begin
  if FShowSelRange <> Value then
  begin
    FShowSelRange := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomTrackBar.SetRangeMode(const Value: Boolean);
begin
  if FRangeMode = Value then
    Exit;
  FRangeMode := Value;
  FActiveThumb := 0;
  if Value and not (csLoading in ComponentState) and (FPositionEnd < Position) then
    FPositionEnd := Max;
  Invalidate;
end;

procedure TPPGCustomTrackBar.SetPositionEnd(const Value: Integer);
begin
  if csLoading in ComponentState then
  begin
    FPositionEnd := Value; // Pruefung in Loaded
    Exit;
  end;
  SetPositionEndInternal(Value);
end;

procedure TPPGCustomTrackBar.SetPositionEndInternal(Value: Int64);
var
  V: Integer;
begin
  V := ClampPosition(Value);
  // Das Ende ueberholt den Anfang nicht
  if FRangeMode and (V < Position) then
    V := Position;
  if V = FPositionEnd then
    Exit;
  FPositionEnd := V;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
  DoChange;
end;

function TPPGCustomTrackBar.ThumbValue(Thumb: Integer): Integer;
begin
  if Thumb = 1 then
    Result := FPositionEnd
  else
    Result := Position;
end;

procedure TPPGCustomTrackBar.SetThumbValue(Thumb: Integer; Value: Int64);
begin
  if FRangeMode and (Thumb = 1) then
    SetPositionEndInternal(Value)
  else
  begin
    // Der Anfang ueberholt das Ende nicht
    if FRangeMode and (Value > FPositionEnd) then
      Value := FPositionEnd;
    SetPositionInternal(Value);
  end;
end;

procedure TPPGCustomTrackBar.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Schnelle Klicks sind Einzelklicks (sonst "verschluckt" Windows jeden zweiten)
  Params.WindowClass.style := Params.WindowClass.style and not CS_DBLCLKS;
end;

{ ---- Properties ---- }

procedure TPPGCustomTrackBar.SetOrientation(const Value: TTrackBarOrientation);
begin
  if FOrientation = Value then
    Exit;
  FOrientation := Value;
  // Wie TTrackBar: Breite und Hoehe tauschen (nicht beim Laden)
  if not (csLoading in ComponentState) then
    SetBounds(Left, Top, Height, Width);
  RequestAutoSize;
  Invalidate;
end;

procedure TPPGCustomTrackBar.SetTickMarks(const Value: TTickMark);
begin
  if FTickMarks <> Value then
  begin
    FTickMarks := Value;
    RequestAutoSize;
    Invalidate;
  end;
end;

procedure TPPGCustomTrackBar.SetTickStyle(const Value: TTickStyle);
begin
  if FTickStyle <> Value then
  begin
    FTickStyle := Value;
    RequestAutoSize;
    Invalidate;
  end;
end;

procedure TPPGCustomTrackBar.SetFrequency(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'Frequency', Value, 1, High(Integer));
  if FFrequency <> V then
  begin
    FFrequency := V;
    Invalidate;
  end;
end;

procedure TPPGCustomTrackBar.SetLineSize(const Value: Integer);
begin
  FLineSize := PPGCheckRange(Self, 'LineSize', Value, 1, High(Integer));
end;

procedure TPPGCustomTrackBar.SetPageSize(const Value: Integer);
begin
  FPageSize := PPGCheckRange(Self, 'PageSize', Value, 1, High(Integer));
end;

procedure TPPGCustomTrackBar.SetThumbLength(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'ThumbLength', Value, PPGMinThumbLength, PPGMaxThumbLength);
  if FThumbLength <> V then
  begin
    FThumbLength := V;
    RequestAutoSize;
    Invalidate;
  end;
end;

procedure TPPGCustomTrackBar.SetSliderVisible(const Value: Boolean);
begin
  if FSliderVisible <> Value then
  begin
    FSliderVisible := Value;
    Invalidate;
  end;
end;

{ ---- Geometrie ---- }

function TPPGCustomTrackBar.GetGeometry: TPPGSliderGeometry;
var
  PPI, Pad, MainLen, CrossLen, Block, BlockStart: Integer;
  Before, After: Boolean;
  Hot: TPPGSurfaceStyle;
begin
  PPI := ScalePPI;
  Result.Vertical := FOrientation = trVertical;
  Result.Reverse := not Result.Vertical and UseRightToLeftAlignment;
  Result.ThumbSize := PPGScale(FThumbLength, PPI);
  Result.TickLen := PPGScale(TickLength, PPI);
  Result.TickGap := PPGScale(TickGapSize, PPI);
  // Platz fuer Glow und Fokusring um den Griff
  Hot := EffectiveAppearance.Resolve(vsHot, PPI, False);
  Pad := 0;
  if Renderer <> nil then
    Pad := Renderer.BodyInset(Hot);
  if Pad < PPGScale(2, PPI) then
    Pad := PPGScale(2, PPI);

  if Result.Vertical then
  begin
    MainLen := Height;
    CrossLen := Width;
  end
  else
  begin
    MainLen := Width;
    CrossLen := Height;
  end;
  Result.TravelStart := Pad + Result.ThumbSize div 2;
  Result.TravelEnd := MainLen - Pad - (Result.ThumbSize - Result.ThumbSize div 2);
  if Result.TravelEnd < Result.TravelStart then
    Result.TravelEnd := Result.TravelStart;

  // Querachse: [Ticks oben/links] Griff [Ticks unten/rechts], als Block zentriert
  Before := (FTickStyle <> tsNone) and (FTickMarks in [tmTopLeft, tmBoth]);
  After := (FTickStyle <> tsNone) and (FTickMarks in [tmBottomRight, tmBoth]);
  Block := Result.ThumbSize;
  if Before then
    Inc(Block, Result.TickGap + Result.TickLen);
  if After then
    Inc(Block, Result.TickGap + Result.TickLen);
  BlockStart := (CrossLen - Block) div 2;
  if Before then
    Result.Center := BlockStart + Result.TickGap + Result.TickLen + Result.ThumbSize div 2
  else
    Result.Center := BlockStart + Result.ThumbSize div 2;
end;

function TPPGCustomTrackBar.PixelOf(const G: TPPGSliderGeometry; Value: Double): Integer;
var
  Offset: Integer;
begin
  Offset := Round(FractionOf(Value) * (G.TravelEnd - G.TravelStart));
  if G.Reverse then
    Result := G.TravelEnd - Offset
  else
    Result := G.TravelStart + Offset;
end;

function TPPGCustomTrackBar.ValueAtPixel(const G: TPPGSliderGeometry; Pixel: Integer): Integer;
var
  F: Double;
begin
  if G.TravelEnd <= G.TravelStart then
    Exit(Min);
  F := (Pixel - G.TravelStart) / (G.TravelEnd - G.TravelStart);
  if G.Reverse then
    F := 1 - F;
  Result := ValueAt(F);
end;

function TPPGCustomTrackBar.MainCoord(X, Y: Integer): Integer;
begin
  if FOrientation = trVertical then
    Result := Y
  else
    Result := X;
end;

function TPPGCustomTrackBar.ThumbRect: TRect;
begin
  Result := ThumbRect(FActiveThumb);
end;

function TPPGCustomTrackBar.ThumbRect(Thumb: Integer): TRect;
var
  G: TPPGSliderGeometry;
  P, H: Integer;
begin
  G := GetGeometry;
  if FRangeMode then
    P := PixelOf(G, ThumbValue(Thumb))
  else
    P := PixelOf(G, Position);
  H := G.ThumbSize div 2;
  if G.Vertical then
    Result := Rect(G.Center - H, P - H, G.Center - H + G.ThumbSize, P - H + G.ThumbSize)
  else
    Result := Rect(P - H, G.Center - H, P - H + G.ThumbSize, G.Center - H + G.ThumbSize);
end;

function TPPGCustomTrackBar.CalcAutoSize(out AWidth, AHeight: Integer): Boolean;
var
  PPI, Pad, Cross: Integer;
begin
  // Nur die Dicke passt sich an; die Laenge bestimmt der Anwender
  PPI := ScalePPI;
  Pad := 0;
  if Renderer <> nil then
    Pad := Renderer.BodyInset(EffectiveAppearance.Resolve(vsHot, PPI, False));
  if Pad < PPGScale(2, PPI) then
    Pad := PPGScale(2, PPI);
  Cross := PPGScale(FThumbLength, PPI) + 2 * Pad;
  if FTickStyle <> tsNone then
  begin
    if FTickMarks in [tmTopLeft, tmBoth] then
      Inc(Cross, PPGScale(TickGapSize + TickLength, PPI));
    if FTickMarks in [tmBottomRight, tmBoth] then
      Inc(Cross, PPGScale(TickGapSize + TickLength, PPI));
  end;
  if FOrientation = trVertical then
  begin
    AWidth := Cross;
    AHeight := Height;
  end
  else
  begin
    AWidth := Width;
    AHeight := Cross;
  end;
  Result := True;
end;

{ ---- Bedienung ---- }

function TPPGCustomTrackBar.Dragging: Boolean;
begin
  Result := FDragging and MousePressed; // Capture-Verlust beendet das Ziehen
end;

function TPPGCustomTrackBar.IsDown: Boolean;
begin
  // Gedrueckt = Griff wird gezogen (auch ausserhalb des Controls).
  // Die Leertaste hat beim Schieberegler keine Bedeutung.
  Result := FDragging and MousePressed;
end;

procedure TPPGCustomTrackBar.WMGetDlgCode(var Message: TWMGetDlgCode);
var
  Shift: Boolean;
  M: PMsg;
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
  // Tab bleibt im Control, solange er den Griff wechselt (LParam = Tastennachricht)
  M := PMsg(TMessage(Message).LParam);
  if FRangeMode and (M <> nil) and (M^.message = WM_KEYDOWN) and (M^.wParam = VK_TAB) then
  begin
    Shift := GetKeyState(VK_SHIFT) < 0;
    if ((FActiveThumb = 0) and not Shift) or ((FActiveThumb = 1) and Shift) then
      Message.Result := Message.Result or DLGC_WANTTAB;
  end;
end;

procedure TPPGCustomTrackBar.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  G: TPPGSliderGeometry;
  TR: TRect;
  P, V: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y); // Fokus, Zustand, OnMouseDown
  if (Button <> mbLeft) or not Enabled or not MousePressed then
    Exit;
  G := GetGeometry;
  P := MainCoord(X, Y);
  if FRangeMode then
  begin
    // Griff unter der Maus, sonst der naehere (bei gleichem Abstand: in Zugrichtung)
    if PtInRect(ThumbRect(1), Point(X, Y)) and not PtInRect(ThumbRect(0), Point(X, Y)) then
      FActiveThumb := 1
    else if PtInRect(ThumbRect(0), Point(X, Y)) and not PtInRect(ThumbRect(1), Point(X, Y)) then
      FActiveThumb := 0
    else
    begin
      V := ValueAtPixel(G, P);
      if Abs(V - FPositionEnd) < Abs(V - Position) then
        FActiveThumb := 1
      else if Abs(V - FPositionEnd) > Abs(V - Position) then
        FActiveThumb := 0
      else if V > Position then
        FActiveThumb := 1
      else
        FActiveThumb := 0;
    end;
  end;
  TR := ThumbRect(FActiveThumb);
  if FSliderVisible and PtInRect(TR, Point(X, Y)) then
  begin
    // Griff gepackt: relativ zur Griffmitte ziehen (kein Sprung)
    FDragOffset := P - PixelOf(G, ThumbValue(FActiveThumb));
  end
  else
  begin
    FDragOffset := 0;
    SetThumbValue(FActiveThumb, ValueAtPixel(G, P));
  end;
  FDragging := True;
  UpdateVisualState(False);
  Invalidate;
end;

procedure TPPGCustomTrackBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Old: Integer;
begin
  if FDragging and MousePressed then
  begin
    Old := ThumbValue(FActiveThumb);
    SetThumbValue(FActiveThumb, ValueAtPixel(GetGeometry, MainCoord(X, Y) - FDragOffset));
    if (ThumbValue(FActiveThumb) <> Old) and Assigned(FOnTracking) then
      FOnTracking(Self);
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TPPGCustomTrackBar.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FDragging := False;
    UpdateVisualState(False);
  end;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TPPGCustomTrackBar.KeyDown(var Key: Word; Shift: TShiftState);
var
  Delta: Int64;
  Handled: Boolean;
  Forward: Word;
  Backward: Word;
begin
  if Enabled and (Shift * [ssAlt, ssCtrl] = []) then
  begin
    // Rechts erhoeht (bei RTL: links), vertikal erhoeht "runter" (Min oben)
    if UseRightToLeftAlignment and (FOrientation = trHorizontal) then
    begin
      Forward := VK_LEFT;
      Backward := VK_RIGHT;
    end
    else
    begin
      Forward := VK_RIGHT;
      Backward := VK_LEFT;
    end;
    Handled := True;
    Delta := 0;
    if (Key = Forward) or (Key = VK_DOWN) then
      Delta := FLineSize
    else if (Key = Backward) or (Key = VK_UP) then
      Delta := -FLineSize
    else if Key = VK_NEXT then
      Delta := FPageSize
    else if Key = VK_PRIOR then
      Delta := -FPageSize
    else if Key = VK_HOME then
      Delta := Int64(Min) - ThumbValue(FActiveThumb)
    else if Key = VK_END then
      Delta := Int64(Max) - ThumbValue(FActiveThumb)
    else
      Handled := False;
    if Handled then
    begin
      SetThumbValue(FActiveThumb, Int64(ThumbValue(FActiveThumb)) + Delta);
      Key := 0;
    end;
  end;
  // Bereich: Tab vom Anfang zum Ende, Umschalt+Tab zurueck
  if FRangeMode and (Key = VK_TAB) and (Shift * [ssAlt, ssCtrl] = []) then
    if (FActiveThumb = 0) and not (ssShift in Shift) then
    begin
      FActiveThumb := 1;
      Invalidate;
      NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, 2);
      Key := 0;
    end
    else if (FActiveThumb = 1) and (ssShift in Shift) then
    begin
      FActiveThumb := 0;
      Invalidate;
      NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, 1);
      Key := 0;
    end;
  inherited KeyDown(Key, Shift);
end;

function TPPGCustomTrackBar.DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheelDown(Shift, MousePos);
  // Audit 7b: nur mit Fokus (sonst scrollt die Seite); Rasten sammelt TControl
  if not Result and Enabled and not WheelNeedsFocus then
  begin
    SetThumbValue(FActiveThumb, Int64(ThumbValue(FActiveThumb)) + FLineSize);
    Result := True;
  end;
end;

function TPPGCustomTrackBar.DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheelUp(Shift, MousePos);
  if not Result and Enabled and not WheelNeedsFocus then
  begin
    SetThumbValue(FActiveThumb, Int64(ThumbValue(FActiveThumb)) - FLineSize);
    Result := True;
  end;
end;

procedure TPPGCustomTrackBar.DoAccelerator;
begin
  // Kein Caption-Accelerator: ein Schieberegler hat keine Beschriftung
end;

{ ---- Zeichnen ---- }

function TPPGCustomTrackBar.GetThumbStyle: TPPGSurfaceStyle;
var
  A: TPPGAppearance;
  PPI: Integer;
  Focus: Boolean;
begin
  // Wie der Button: Normal -> Hot -> Down, animiert
  Result := GetCurrentStyle;
  A := EffectiveAppearance;
  PPI := ScalePPI;
  Focus := FocusVisible;
  if Focus then
  begin
    Result.Focused := True;
    Result.BorderColor := PPGColorToRGB(A.FocusColor);
  end;
  if not Enabled then
    Result := A.Resolve(vsDisabled, PPI, False);
end;

procedure TPPGCustomTrackBar.PaintTicks(const ACanvas: IPPGCanvas;
  const G: TPPGSliderGeometry; Color: TColor);

  procedure Tick(Value: Int64);
  var
    P, H, A1, A2: Integer;
  begin
    P := PixelOf(G, Value);
    H := G.ThumbSize div 2;
    if FTickMarks in [tmTopLeft, tmBoth] then
    begin
      A2 := G.Center - H - G.TickGap;
      A1 := A2 - G.TickLen;
      if G.Vertical then
        ACanvas.DrawPolyline([Point(A1, P), Point(A2, P)], 1, Color, 255)
      else
        ACanvas.DrawPolyline([Point(P, A1), Point(P, A2)], 1, Color, 255);
    end;
    if FTickMarks in [tmBottomRight, tmBoth] then
    begin
      A1 := G.Center - H + G.ThumbSize + G.TickGap;
      A2 := A1 + G.TickLen;
      if G.Vertical then
        ACanvas.DrawPolyline([Point(A1, P), Point(A2, P)], 1, Color, 255)
      else
        ACanvas.DrawPolyline([Point(P, A1), Point(P, A2)], 1, Color, 255);
    end;
  end;

var
  Count, Span: Int64;
  V: Int64;
begin
  if FTickStyle = tsNone then
    Exit;
  Tick(Min);
  Tick(Max);
  if FTickStyle <> tsAuto then
    Exit;
  Span := Int64(Max) - Min;
  if Span <= 0 then
    Exit;
  Count := Span div FFrequency;
  // Zu dicht (z.B. 0..100000 mit Frequency 1): nur die Enden zeichnen
  if (Count = 0) or ((G.TravelEnd - G.TravelStart) div Count < PPGScale(MinTickSpacing, ScalePPI)) then
    Exit;
  V := Int64(Min) + FFrequency;
  while V < Max do
  begin
    Tick(V);
    Inc(V, FFrequency);
  end;
end;

procedure TPPGCustomTrackBar.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  G: TPPGSliderGeometry;
  A: TPPGAppearance;
  PPI, HalfG, P, PMin, S1, S2, Swap: Integer;
  Track, Fill, SelR: TRect;
  TrackStyle, FillStyle, ThumbStyle, Other: TPPGSurfaceStyle;
  TickColor: TColor;
  RR: IPPGRangeRenderer;
  HC: Boolean;
begin
  G := GetGeometry;
  A := EffectiveAppearance;
  PPI := ScalePPI;
  HC := UseHighContrast;
  RR := RangeRenderer;

  if Enabled then
  begin
    TrackStyle := A.Resolve(vsNormal, PPI, False);
    FillStyle := A.ResolveStyle(A.Checked, PPI, False);
  end
  else
  begin
    TrackStyle := A.Resolve(vsDisabled, PPI, False);
    FillStyle := TrackStyle;
    FillStyle.BorderColor := PPGColorToRGB(A.Disabled.TextColor);
  end;
  TickColor := TrackStyle.BorderColor;
  if HC then
  begin
    // Sonderfall: Schiene und Striche in Textfarbe, Fuellung Accent (Tokens)
    TrackStyle.BorderColor := Tokens.Stroke;
    if Enabled then
      FillStyle.BorderColor := Tokens.Accent
    else
      FillStyle.BorderColor := Tokens.TextDisabled;
    TickColor := Tokens.Stroke;
  end;

  // Schiene ueber den gesamten Weg, Enden halbrund
  HalfG := PPGScale(GrooveThickness, PPI) div 2;
  if HalfG < 1 then
    HalfG := 1;
  P := PixelOf(G, Position);
  PMin := PixelOf(G, Min);
  if G.Vertical then
  begin
    Track := Rect(G.Center - HalfG, G.TravelStart - HalfG, G.Center + HalfG, G.TravelEnd + HalfG);
    if P >= PMin then
      Fill := Rect(Track.Left, PMin - HalfG, Track.Right, P + HalfG)
    else
      Fill := Rect(Track.Left, P - HalfG, Track.Right, PMin + HalfG);
  end
  else
  begin
    Track := Rect(G.TravelStart - HalfG, G.Center - HalfG, G.TravelEnd + HalfG, G.Center + HalfG);
    if P >= PMin then
      Fill := Rect(PMin - HalfG, Track.Top, P + HalfG, Track.Bottom)
    else
      Fill := Rect(P - HalfG, Track.Top, PMin + HalfG, Track.Bottom);
  end;
  if Position = Min then
    Fill := Rect(0, 0, 0, 0);
  if FRangeMode then
  begin
    // Fuellung zwischen den beiden Griffen
    PMin := PixelOf(G, Position);
    P := PixelOf(G, FPositionEnd);
    if PMin > P then
    begin
      Swap := PMin;
      PMin := P;
      P := Swap;
    end;
    if G.Vertical then
      Fill := Rect(Track.Left, PMin - HalfG, Track.Right, P + HalfG)
    else
      Fill := Rect(PMin - HalfG, Track.Top, P + HalfG, Track.Bottom);
    if Position = FPositionEnd then
      Fill := Rect(0, 0, 0, 0);
  end;

  PaintTicks(ACanvas, G, TickColor);
  RR.DrawSliderTrack(ACanvas, Track, Fill, TrackStyle, FillStyle, PPI);
  // Auswahlbereich wie TTrackBar: Band ueber der Schiene, Marken an den Enden
  if FShowSelRange and (FSelEnd > FSelStart) then
  begin
    S1 := PixelOf(G, ClampPosition(FSelStart));
    S2 := PixelOf(G, ClampPosition(FSelEnd));
    if S1 > S2 then
    begin
      Swap := S1;
      S1 := S2;
      S2 := Swap;
    end;
    if G.Vertical then
    begin
      SelR := Rect(G.Center - HalfG - PPGScale(2, PPI), S1, G.Center + HalfG + PPGScale(2, PPI), S2);
      ACanvas.FillRoundRect(SelR, HalfG, FillStyle.BorderColor, 90);
      ACanvas.DrawPolyline([Point(SelR.Left - PPGScale(3, PPI), S1), Point(SelR.Right + PPGScale(3, PPI), S1)],
        1, FillStyle.BorderColor, 255);
      ACanvas.DrawPolyline([Point(SelR.Left - PPGScale(3, PPI), S2), Point(SelR.Right + PPGScale(3, PPI), S2)],
        1, FillStyle.BorderColor, 255);
    end
    else
    begin
      SelR := Rect(S1, G.Center - HalfG - PPGScale(2, PPI), S2, G.Center + HalfG + PPGScale(2, PPI));
      ACanvas.FillRoundRect(SelR, HalfG, FillStyle.BorderColor, 90);
      ACanvas.DrawPolyline([Point(S1, SelR.Top - PPGScale(3, PPI)), Point(S1, SelR.Bottom + PPGScale(3, PPI))],
        1, FillStyle.BorderColor, 255);
      ACanvas.DrawPolyline([Point(S2, SelR.Top - PPGScale(3, PPI)), Point(S2, SelR.Bottom + PPGScale(3, PPI))],
        1, FillStyle.BorderColor, 255);
    end;
  end;

  ThumbStyle := GetThumbStyle;
  if FSliderVisible then
  begin
    if HC then
    begin
      // Sonderfall: Griff auch beim Ziehen flach, nur der Rand hebt hervor
      // (Systemfarben aus der Hochkontrast-Appearance)
      ThumbStyle.Color := PPGColorToRGB(A.Normal.Color);
      ThumbStyle.ColorTo := ThumbStyle.Color;
      ThumbStyle.ColorMirror := ThumbStyle.Color;
      ThumbStyle.ColorMirrorTo := ThumbStyle.Color;
      ThumbStyle.GlowAlpha := 0;
      if Enabled and (IsHot or ThumbStyle.Focused) then
        ThumbStyle.BorderColor := PPGColorToRGB(A.FocusColor)
      else if Enabled then
        ThumbStyle.BorderColor := PPGColorToRGB(A.Normal.BorderColor)
      else
        ThumbStyle.BorderColor := PPGColorToRGB(A.Disabled.BorderColor);
    end;
    if FRangeMode then
    begin
      // Der Griff ohne Tastatur zuerst, ohne Fokusrahmen
      Other := ThumbStyle;
      Other.Focused := False;
      Other.BorderColor := GetCurrentStyle.BorderColor;
      if not Enabled then
        Other := ThumbStyle;
      RR.DrawSliderThumb(ACanvas, ThumbRect(1 - FActiveThumb), Other, FillStyle.BorderColor, 0, PPI);
    end;
    RR.DrawSliderThumb(ACanvas, ThumbRect(FActiveThumb), ThumbStyle, FillStyle.BorderColor,
      HotProgress, PPI);
  end
  else if FocusVisible then
    Renderer.DrawFocus(ACanvas, Track, ThumbStyle);
end;

{ ---- Barrierefreiheit ---- }

function TPPGCustomTrackBar.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_SLIDER;
end;

function TPPGCustomTrackBar.AccState: Integer;
begin
  // "gedrueckt" ergibt beim Schieberegler keinen Sinn
  Result := inherited AccState and not STATE_SYSTEM_PRESSED;
end;

function TPPGCustomTrackBar.AccDefaultAction: string;
begin
  Result := '';
end;

procedure TPPGCustomTrackBar.AccDoDefaultAction;
begin
  // Keine Standardaktion; der Wert wird per Tastatur geaendert
end;

function TPPGCustomTrackBar.AccValue: string;
begin
  if FRangeMode then
    Result := Format(PPGStr(@SPPGTrackRangeValue), [Position, FPositionEnd])
  else
    Result := inherited AccValue;
end;

function TPPGCustomTrackBar.AccChildCount: Integer;
begin
  if FRangeMode then
    Result := 2
  else
    Result := 0;
end;

function TPPGCustomTrackBar.AccChildName(Id: Integer): string;
begin
  if Id = 2 then
    Result := Format(PPGStr(@SPPGTrackRangeTo), [FPositionEnd])
  else
    Result := Format(PPGStr(@SPPGTrackRangeFrom), [Position]);
end;

function TPPGCustomTrackBar.AccChildRole(Id: Integer): Integer;
begin
  Result := ROLE_SYSTEM_INDICATOR;
end;

function TPPGCustomTrackBar.AccChildState(Id: Integer): Integer;
begin
  Result := STATE_SYSTEM_FOCUSABLE;
  if Focused and (Id - 1 = FActiveThumb) then
    Result := Result or STATE_SYSTEM_FOCUSED;
  if not Enabled then
    Result := Result or STATE_SYSTEM_UNAVAILABLE;
end;

function TPPGCustomTrackBar.AccChildRect(Id: Integer): TRect;
begin
  if (Id < 1) or (Id > AccChildCount) then
    Result := Rect(0, 0, 0, 0)
  else
    Result := ThumbRect(Id - 1);
end;

function TPPGCustomTrackBar.AccChildAt(X, Y: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to AccChildCount do
    if PtInRect(ThumbRect(I - 1), Point(X, Y)) then
      Exit(I);
end;

function TPPGCustomTrackBar.AccChildDefaultAction(Id: Integer): string;
begin
  Result := '';
end;

procedure TPPGCustomTrackBar.AccChildDoDefault(Id: Integer);
begin
end;

function TPPGCustomTrackBar.AccFocusedChild: Integer;
begin
  if FRangeMode and Focused then
    Result := FActiveThumb + 1
  else
    Result := 0;
end;

function TPPGCustomTrackBar.AccSelectedChild: Integer;
begin
  Result := 0;
end;

end.
