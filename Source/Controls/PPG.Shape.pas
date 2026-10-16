unit PPG.Shape;

{ TPPGShape - Formen (Rechteck, Quadrat, abgerundet, Ellipse, Kreis).

  Grafisches Control wie TShape (kein Fensterhandle) und DFM-kompatibel:
  Shape, Brush und Pen heissen und streamen wie in der VCL, damit ein Tausch
  im Formular ohne Nacharbeit geht (Build\migrate.ps1).

  Mehrwert gegenueber TShape:
  - Antialiasing: Fuellung und Rand laufen ueber den Renderer der Suite
    (GDI+, sonst GDI-Fallback). Ohne GDI+ sieht die Form wie bei TShape aus.
  - Theme: Die Vorgabefarben (Brush weiss bzw. Fensterfarbe, Pen schwarz)
    folgen im Dark Mode und im Hochkontrast den Farben der Suite
    (TPPGTheme, wie TPPGLabel). Eigene Farben bleiben unveraendert.
    ThemeColors = False schaltet das ab.
  - Im Hellen sieht eine Form mit Vorgabefarben genau wie TShape aus.

  Stifte und Pinsel, die der Renderer nicht kann (gestrichelte Stifte,
  Schraffuren, Bitmap-Pinsel), zeichnet die VCL wie bei TShape. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.UITypes,
  Vcl.Controls, Vcl.Graphics, Vcl.ExtCtrls;

type
  TPPGShape = class(TGraphicControl)
  private
    FPen: TPen;
    FBrush: TBrush;
    FShape: TShapeType;
    FThemeColors: Boolean;
    procedure SetBrush(Value: TBrush);
    procedure SetPen(Value: TPen);
    procedure SetShape(Value: TShapeType);
    procedure SetThemeColors(const Value: Boolean);
    procedure StyleChanged(Sender: TObject);
    function CanUseRenderer: Boolean;
    function ThemeTokensActive(out Dark, HC: Boolean): Boolean;
    procedure PaintClassic;
    procedure PaintRendered;
  protected
    procedure Paint; override;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Tatsaechliche Fuellfarbe (Dark Mode, Hochkontrast).
    function EffectiveBrushColor: TColor;
    /// Tatsaechliche Randfarbe (Dark Mode, Hochkontrast).
    function EffectivePenColor: TColor;
    /// Das Rechteck, das die Form ausfuellt (Quadrat und Kreis zentriert).
    function ShapeRect: TRect;
  published
    property Brush: TBrush read FBrush write SetBrush;
    property Pen: TPen read FPen write SetPen;
    property Shape: TShapeType read FShape write SetShape default stRectangle;
    /// Vorgabefarben von Brush und Pen folgen Dark Mode und Hochkontrast.
    property ThemeColors: Boolean read FThemeColors write SetThemeColors default True;
    { wie TShape }
    property Align;
    property Anchors;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property Touch;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnGesture;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

uses
  System.SysUtils,
  PPG.Render.Intf, PPG.Render.Registry, PPG.Tokens, PPG.DpiUtils, PPG.VclStyles, PPG.Theme;

{ TPPGShape }

constructor TPPGShape.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csReplicatable];
  Width := 65;
  Height := 65;
  FThemeColors := True;
  FPen := TPen.Create;
  FPen.OnChange := StyleChanged;
  FBrush := TBrush.Create;
  FBrush.OnChange := StyleChanged;
  TPPGTheme.AddClient(Self);
end;

destructor TPPGShape.Destroy;
begin
  TPPGTheme.RemoveClient(Self);
  FreeAndNil(FBrush);
  FreeAndNil(FPen);
  inherited Destroy;
end;

procedure TPPGShape.WndProc(var Message: TMessage);
begin
  if (PPGThemeChangedMessage <> 0) and (Message.Msg = PPGThemeChangedMessage) then
  begin
    Invalidate; // Hell/Dunkel gewechselt
    Exit;
  end;
  inherited WndProc(Message);
end;

procedure TPPGShape.StyleChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TPPGShape.SetBrush(Value: TBrush);
begin
  FBrush.Assign(Value);
end;

procedure TPPGShape.SetPen(Value: TPen);
begin
  FPen.Assign(Value);
end;

procedure TPPGShape.SetShape(Value: TShapeType);
begin
  if FShape <> Value then
  begin
    FShape := Value;
    Invalidate;
  end;
end;

procedure TPPGShape.SetThemeColors(const Value: Boolean);
begin
  if FThemeColors <> Value then
  begin
    FThemeColors := Value;
    Invalidate;
  end;
end;

function TPPGShape.ThemeTokensActive(out Dark, HC: Boolean): Boolean;
begin
  HC := PPGUseHighContrast(True);
  Dark := TPPGTheme.IsDark and not PPGVclStyleActive and not HC;
  Result := FThemeColors and (Dark or HC);
end;

function TPPGShape.EffectiveBrushColor: TColor;
var
  Dark, HC: Boolean;
  T: TPPGTokens;
begin
  Result := FBrush.Color;
  if ThemeTokensActive(Dark, HC) then
  begin
    T := PPGPresetTokens('', Dark, HC);
    if (Result = clWhite) or (Result = clWindow) then
      Result := T.Surface
    else if Result = clBtnFace then
      Result := T.Layer;
  end;
end;

function TPPGShape.EffectivePenColor: TColor;
var
  Dark, HC: Boolean;
  T: TPPGTokens;
begin
  Result := FPen.Color;
  if ThemeTokensActive(Dark, HC) then
  begin
    T := PPGPresetTokens('', Dark, HC);
    if (Result = clBlack) or (Result = clWindowText) or (Result = clBtnText) then
      Result := T.Stroke;
  end;
end;

function TPPGShape.ShapeRect: TRect;
var
  S: Integer;
begin
  Result := Rect(0, 0, Width, Height);
  if FShape in [stSquare, stRoundSquare, stCircle] then
  begin
    S := Width;
    if Height < S then
      S := Height;
    Result.Left := (Width - S) div 2;
    Result.Top := (Height - S) div 2;
    Result.Right := Result.Left + S;
    Result.Bottom := Result.Top + S;
  end;
end;

function TPPGShape.CanUseRenderer: Boolean;
begin
  Result := (FPen.Style in [psSolid, psInsideFrame, psClear]) and
    (FBrush.Style in [bsSolid, bsClear]) and (FBrush.Bitmap = nil);
end;

procedure TPPGShape.Paint;
begin
  if CanUseRenderer then
    PaintRendered
  else
    PaintClassic;
end;

procedure TPPGShape.PaintClassic;
var
  X, Y, W, H, S: Integer;
begin
  // Wie TShape.Paint der VCL
  Canvas.Pen.Assign(FPen);
  Canvas.Pen.Color := EffectivePenColor;
  Canvas.Brush.Assign(FBrush);
  Canvas.Brush.Color := EffectiveBrushColor;
  X := FPen.Width div 2;
  Y := X;
  W := Width - FPen.Width + 1;
  H := Height - FPen.Width + 1;
  if FPen.Width = 0 then
  begin
    Dec(W);
    Dec(H);
  end;
  if W < H then
    S := W
  else
    S := H;
  if FShape in [stSquare, stRoundSquare, stCircle] then
  begin
    Inc(X, (W - S) div 2);
    Inc(Y, (H - S) div 2);
    W := S;
    H := S;
  end;
  case FShape of
    stRectangle, stSquare:
      Canvas.Rectangle(X, Y, X + W, Y + H);
    stRoundRect, stRoundSquare:
      Canvas.RoundRect(X, Y, X + W, Y + H, S div 4, S div 4);
    stCircle, stEllipse:
      Canvas.Ellipse(X, Y, X + W, Y + H);
  end;
end;

procedure TPPGShape.PaintRendered;
var
  Cv: IPPGCanvas;
  Q, F: TRect;
  PW, Inset, Radius, S: Integer;
  PenC, BrushC: TColor;
begin
  Q := ShapeRect;
  if IsRectEmpty(Q) then
    Exit;
  PenC := ColorToRGB(EffectivePenColor);
  BrushC := ColorToRGB(EffectiveBrushColor);
  if FPen.Style = psClear then
    PW := 0
  else if FPen.Width < 1 then
    PW := 1
  else
    PW := FPen.Width;
  Inset := PW div 2;
  F := Q;
  InflateRect(F, -Inset, -Inset);
  S := Q.Right - Q.Left;
  if Q.Bottom - Q.Top < S then
    S := Q.Bottom - Q.Top;
  // Wie TShape: Eckendurchmesser = S div 4
  Radius := 0;
  if FShape in [stRoundRect, stRoundSquare] then
    Radius := S div 8;
  Cv := TPPGRendererRegistry.CreateCanvas(Canvas.Handle);
  try
    case FShape of
      stRectangle, stSquare, stRoundRect, stRoundSquare:
        begin
          if FBrush.Style = bsSolid then
            Cv.FillRoundRect(F, Radius - Inset, BrushC, 255);
          if PW > 0 then
            Cv.FrameRoundRect(Q, Radius, PW, PenC, 255);
        end;
      stEllipse, stCircle:
        begin
          if FBrush.Style = bsSolid then
            Cv.FillEllipse(F, BrushC, 255);
          if PW > 0 then
            Cv.FrameEllipse(Q, PW, PenC, 255);
        end;
    end;
  finally
    Cv := nil;
  end;
end;

end.
