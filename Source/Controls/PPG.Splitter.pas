unit PPG.Splitter;

{ TPPGSplitter - Ziehgriff zwischen ausgerichteten Controls (Phase 7a).

  Verhalten wie TSplitter (DFM-kompatibel: Align, MinSize, AutoSnap,
  ResizeStyle, OnCanResize, OnMoved): veraendert die Groesse des Controls,
  das auf derselben Seite direkt angrenzt. Zusaetzlich:
  - Optik im Preset-Stil: Linie und Griffpunkte erscheinen beim Hover, beim
    Ziehen in der Fokusfarbe; Dark Mode/Hochkontrast ueber die Tokens.
  - Fenster-Control: mit TabStop per Tastatur erreichbar; Pfeile verschieben
    (Strg = 1 px, sonst 10 logische px), Pos1/Ende = Minimum/Maximum.
  - ResizeStyle rsUpdate (Standard) zieht live; rsLine/rsPattern zeigen eine
    invertierte Linie auf dem Parent, rsNone aendert erst beim Loslassen.
  - Esc bricht das Ziehen ab (alte Groesse). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.ExtCtrls,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Base;

type
  TPPGCustomSplitter = class(TPPGCustomControl)
  private
    FMinSize: Integer;
    FAutoSnap: Boolean;
    FResizeStyle: TResizeStyle;
    FControl: TControl;
    FDragging: Boolean;
    FDownPos: TPoint;      // Bildschirm
    FStartSize: Integer;
    FNewSize: Integer;
    FMaxSize: Integer;
    FLineVisible: Boolean;
    FLineDC: HDC;
    // Fenster, von dem FLineDC stammt: beim Zerstoeren ist Parent schon nil
    FLineWnd: HWND;
    FLinePos: Integer;     // Parent-Koordinate der invertierten Linie
    FBrush: HBRUSH;
    FOnCanResize: TCanResizeEvent;
    FOnMoved: TNotifyEvent;
    FBeveled: Boolean;
    FOnPaint: TNotifyEvent;
    FPaintCanvas: TCanvas;
    FInUserPaint: Boolean;
    procedure SetBeveled(const Value: Boolean);
    function GetCanvas: TCanvas;
    procedure DoUserPaint(const ACanvas: IPPGCanvas);
    procedure SetMinSize(const Value: Integer);
    function Horizontal: Boolean;
    procedure CalcMaxSize;
    function ClampSize(Value: Integer): Integer;
    function DoCanResize(var NewSize: Integer): Boolean;
    procedure ApplySize(NewSize: Integer);
    procedure DrawLine;
    procedure ShowLine(NewSize: Integer);
    procedure HideLine;
    procedure EndDrag(Accept: Boolean);
    procedure UpdateCursor;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMCancelMode(var Message: TMessage); message WM_CANCELMODE;
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
  protected
    procedure RequestAlign; override;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function AccRole: Integer; override;
    function AccValue: string; override;
    property MinSize: Integer read FMinSize write SetMinSize default 30;
    property AutoSnap: Boolean read FAutoSnap write FAutoSnap default True;
    property ResizeStyle: TResizeStyle read FResizeStyle write FResizeStyle default rsUpdate;
    property OnCanResize: TCanResizeEvent read FOnCanResize write FOnCanResize;
    property OnMoved: TNotifyEvent read FOnMoved write FOnMoved;
    /// Wie TSplitter: Linie auch in Ruhe sichtbar.
    property Beveled: Boolean read FBeveled write SetBeveled default False;
    /// Wie TSplitter: nach dem eigenen Zeichnen, mit Canvas.
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Das Control, dessen Groesse der Splitter aendert (nil = keines).
    function FindResizeControl: TControl;
    /// Groesse des angrenzenden Controls setzen (wie beim Ziehen, mit OnCanResize/OnMoved).
    function MoveBy(Delta: Integer): Boolean;
    property IsDragging: Boolean read FDragging;
    /// Nur waehrend OnPaint gueltig.
    property Canvas: TCanvas read GetCanvas;
  end;

  TPPGSplitter = class(TPPGCustomSplitter)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property HighContrastSupport;
    property MinSize;
    property AutoSnap;
    property Beveled;
    property ResizeStyle;
    property Align default alLeft;
    property Color;
    property Constraints;
    property Enabled;
    property ParentColor;
    property ParentShowHint;
    property ShowHint;
    property TabOrder;
    property TabStop default False;
    property Visible;
    property Touch;
    property OnGesture;
    property Width default 6;
    property OnCanResize;
    property OnMoved;
    property OnPaint;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseActivate;
    property OnContextPopup;
    property PopupMenu;
    property StyleElements;
    property DragMode;
    property DragCursor;
    property OnDragDrop;
    property OnDragOver;
    property OnStartDrag;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
  end;

implementation

uses
  System.SysUtils, System.Math, Winapi.oleacc,
  PPG.Appearance, PPG.DpiUtils, PPG.Tokens;

{ TPPGCustomSplitter }

constructor TPPGCustomSplitter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption, csDoubleClicks]; // Audit 5d: OnClick wie TControl
  FMinSize := 30;
  FAutoSnap := True;
  FResizeStyle := rsUpdate;
  Align := alLeft;
  Width := 6;
  TabStop := False;
  UpdateCursor;
end;

destructor TPPGCustomSplitter.Destroy;
begin
  FreeAndNil(FPaintCanvas);
  HideLine;
  if FBrush <> 0 then
    DeleteObject(FBrush);
  inherited Destroy;
end;

procedure TPPGCustomSplitter.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FControl) then
  begin
    // Waehrend des Ziehens freigegeben: Linie und gesperrten DC freigeben
    if FDragging then
    begin
      HideLine;
      MouseCapture := False;
    end;
    FControl := nil;
    FDragging := False;
  end;
end;

function TPPGCustomSplitter.Horizontal: Boolean;
begin
  // "Horizontal" = verschiebt waagrecht (Splitter steht senkrecht)
  Result := Align in [alLeft, alRight, alNone, alCustom, alClient];
end;

procedure TPPGCustomSplitter.UpdateCursor;
begin
  // Selbst gesetzten Cursor behalten
  if (Cursor <> crDefault) and (Cursor <> crHSplit) and (Cursor <> crVSplit) then
    Exit;
  if Align in [alTop, alBottom] then
    Cursor := crVSplit
  else
    Cursor := crHSplit;
end;

procedure TPPGCustomSplitter.RequestAlign;
begin
  inherited RequestAlign;
  UpdateCursor; // Align geaendert: Cursor anpassen
end;

procedure TPPGCustomSplitter.SetMinSize(const Value: Integer);
begin
  FMinSize := PPGCheckRange(Self, 'MinSize', Value, 0, 100000);
end;

function TPPGCustomSplitter.IsHot: Boolean;
begin
  Result := MouseInside or FDragging;
end;

function TPPGCustomSplitter.IsDown: Boolean;
begin
  Result := FDragging;
end;

function TPPGCustomSplitter.FindResizeControl: TControl;
var
  I: Integer;
  C: TControl;
  P: TPoint;
begin
  Result := nil;
  if Parent = nil then
    Exit;
  // Wie TSplitter: das Control, das auf derselben Seite direkt anschliesst
  case Align of
    alLeft: P := Point(Left - 1, Top + Height div 2);
    alRight: P := Point(Left + Width, Top + Height div 2);
    alTop: P := Point(Left + Width div 2, Top - 1);
    alBottom: P := Point(Left + Width div 2, Top + Height);
  else
    Exit;
  end;
  for I := 0 to Parent.ControlCount - 1 do
  begin
    C := Parent.Controls[I];
    if (C <> Self) and C.Visible and (C.Align = Align) and PtInRect(C.BoundsRect, P) then
      Exit(C);
  end;
  // Zugeklapptes Control (Groesse 0) liegt genau am Splitter an
  for I := 0 to Parent.ControlCount - 1 do
  begin
    C := Parent.Controls[I];
    if (C = Self) or not C.Visible or (C.Align <> Align) then
      Continue;
    case Align of
      alLeft: if C.Left + C.Width = Left then Exit(C);
      alRight: if C.Left = Left + Width then Exit(C);
      alTop: if C.Top + C.Height = Top then Exit(C);
      alBottom: if C.Top = Top + Height then Exit(C);
    end;
  end;
end;

procedure TPPGCustomSplitter.CalcMaxSize;
var
  I: Integer;
  C: TControl;
begin
  // Wie TSplitter: Platz des Parents minus aller Controls derselben Achse
  if Align in [alLeft, alRight] then
  begin
    FMaxSize := Parent.ClientWidth - FMinSize;
    for I := 0 to Parent.ControlCount - 1 do
    begin
      C := Parent.Controls[I];
      if C.Visible and (C.Align in [alLeft, alRight]) then
        Dec(FMaxSize, C.Width);
    end;
    Inc(FMaxSize, FControl.Width);
  end
  else
  begin
    FMaxSize := Parent.ClientHeight - FMinSize;
    for I := 0 to Parent.ControlCount - 1 do
    begin
      C := Parent.Controls[I];
      if C.Visible and (C.Align in [alTop, alBottom]) then
        Dec(FMaxSize, C.Height);
    end;
    Inc(FMaxSize, FControl.Height);
  end;
  if FMaxSize < 0 then
    FMaxSize := 0;
end;

function TPPGCustomSplitter.ClampSize(Value: Integer): Integer;
begin
  Result := Value;
  if Result > FMaxSize then
    Result := FMaxSize;
  if Result < FMinSize then
  begin
    // AutoSnap: unter MinSize klappt das Control ganz zu
    if FAutoSnap and (Result < FMinSize div 2) then
      Result := 0
    else
      Result := Min(FMinSize, FMaxSize);
  end;
  if Result < 0 then
    Result := 0;
end;

function TPPGCustomSplitter.DoCanResize(var NewSize: Integer): Boolean;
begin
  Result := True;
  if Assigned(FOnCanResize) then
    FOnCanResize(Self, NewSize, Result);
  if Result and (NewSize <= FMinSize) and FAutoSnap and (NewSize < FMinSize div 2) then
    NewSize := 0;
end;

procedure TPPGCustomSplitter.ApplySize(NewSize: Integer);
begin
  if FControl = nil then
    Exit;
  case Align of
    alLeft: FControl.Width := NewSize;
    alTop: FControl.Height := NewSize;
    alRight:
      begin
        Parent.DisableAlign;
        try
          FControl.Left := FControl.Left + (FControl.Width - NewSize);
          FControl.Width := NewSize;
        finally
          Parent.EnableAlign;
        end;
      end;
    alBottom:
      begin
        Parent.DisableAlign;
        try
          FControl.Top := FControl.Top + (FControl.Height - NewSize);
          FControl.Height := NewSize;
        finally
          Parent.EnableAlign;
        end;
      end;
  end;
  Parent.Update;
  NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
end;

procedure TPPGCustomSplitter.DrawLine;
var
  Old: HBRUSH;
begin
  // XOR-Linie: zweimal zeichnen = loeschen
  if FLineDC = 0 then
    Exit;
  Old := SelectObject(FLineDC, FBrush);
  if Horizontal then
    PatBlt(FLineDC, FLinePos, Top, Width, Height, PATINVERT)
  else
    PatBlt(FLineDC, Left, FLinePos, Width, Height, PATINVERT);
  SelectObject(FLineDC, Old);
end;

procedure TPPGCustomSplitter.ShowLine(NewSize: Integer);
var
  Bmp: TBitmap;
  I: Integer;
begin
  if FBrush = 0 then
  begin
    if FResizeStyle = rsPattern then
    begin
      // Schachbrettmuster wie TSplitter
      Bmp := TBitmap.Create;
      try
        Bmp.Width := 8;
        Bmp.Height := 8;
        for I := 0 to 63 do
          if Odd(I mod 8 + I div 8) then
            Bmp.Canvas.Pixels[I mod 8, I div 8] := clWhite
          else
            Bmp.Canvas.Pixels[I mod 8, I div 8] := clBlack;
        FBrush := CreatePatternBrush(Bmp.Handle);
      finally
        Bmp.Free;
      end;
    end
    else
      FBrush := CreateSolidBrush(ColorToRGB(clWhite));
  end;
  if FLineDC = 0 then
  begin
    FLineWnd := Parent.Handle;
    FLineDC := GetDCEx(FLineWnd, 0, DCX_CACHE or DCX_CLIPSIBLINGS or DCX_LOCKWINDOWUPDATE);
  end;
  if FLineVisible then
    DrawLine;
  case Align of
    alLeft: FLinePos := FControl.Left + NewSize;
    alRight: FLinePos := FControl.Left + FControl.Width - NewSize - Width;
    alTop: FLinePos := FControl.Top + NewSize;
    alBottom: FLinePos := FControl.Top + FControl.Height - NewSize - Height;
  end;
  DrawLine;
  FLineVisible := True;
end;

procedure TPPGCustomSplitter.HideLine;
begin
  if FLineDC <> 0 then
  begin
    // Linie nur zuruecknehmen, solange das Fenster noch besteht
    if FLineVisible and IsWindow(FLineWnd) then
      DrawLine;
    ReleaseDC(FLineWnd, FLineDC);
    FLineDC := 0;
    FLineWnd := 0;
  end;
  FLineVisible := False;
end;

procedure TPPGCustomSplitter.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button <> mbLeft) or not Enabled then
    Exit;
  FControl := FindResizeControl;
  if FControl = nil then
    Exit;
  FControl.FreeNotification(Self);
  CalcMaxSize;
  if Horizontal then
    FStartSize := FControl.Width
  else
    FStartSize := FControl.Height;
  FNewSize := FStartSize;
  FDownPos := ClientToScreen(Point(X, Y));
  FDragging := True;
  if FResizeStyle in [rsLine, rsPattern] then
    ShowLine(FStartSize);
  UpdateVisualState(False);
end;

procedure TPPGCustomSplitter.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
  Delta, S: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  if not FDragging or (FControl = nil) then
    Exit;
  P := ClientToScreen(Point(X, Y));
  if Horizontal then
    Delta := P.X - FDownPos.X
  else
    Delta := P.Y - FDownPos.Y;
  if Align in [alRight, alBottom] then
    Delta := -Delta;
  S := ClampSize(FStartSize + Delta);
  if S = FNewSize then
    Exit;
  if not DoCanResize(S) then
    Exit;
  FNewSize := S;
  case FResizeStyle of
    rsUpdate: ApplySize(S);
    rsLine, rsPattern: ShowLine(S);
  end;
end;

procedure TPPGCustomSplitter.EndDrag(Accept: Boolean);
begin
  if not FDragging then
    Exit;
  FDragging := False;
  HideLine;
  if FControl <> nil then
  begin
    if not Accept then
    begin
      if FResizeStyle = rsUpdate then
        ApplySize(FStartSize);
    end
    else
    begin
      if FResizeStyle <> rsUpdate then
        ApplySize(FNewSize);
      if (FNewSize <> FStartSize) and Assigned(FOnMoved) then
        FOnMoved(Self);
    end;
  end;
  UpdateVisualState(False);
end;

procedure TPPGCustomSplitter.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    EndDrag(True);
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TPPGCustomSplitter.WMCancelMode(var Message: TMessage);
begin
  EndDrag(False);
  inherited;
end;

procedure TPPGCustomSplitter.WMCaptureChanged(var Message: TMessage);
begin
  // Capture verloren (Alt+Tab, Dialog): Ziehen abbrechen
  if FDragging and (HWND(Message.LParam) <> Handle) and (GetKeyState(VK_LBUTTON) >= 0) then
    EndDrag(True)
  else if FDragging and (HWND(Message.LParam) <> Handle) then
    EndDrag(False);
  inherited;
end;

function TPPGCustomSplitter.MoveBy(Delta: Integer): Boolean;
var
  S: Integer;
begin
  Result := False;
  if FDragging or (Parent = nil) then
    Exit;
  FControl := FindResizeControl;
  if FControl = nil then
    Exit;
  FControl.FreeNotification(Self);
  CalcMaxSize;
  if Horizontal then
    FStartSize := FControl.Width
  else
    FStartSize := FControl.Height;
  S := FStartSize + Delta;
  if S > FMaxSize then
    S := FMaxSize;
  if S < 0 then
    S := 0;
  // Tastatur rastet nicht ein: Minimum statt Zuklappen, ausser es geht auf 0
  if (S > 0) and (S < FMinSize) then
  begin
    if Delta < 0 then
    begin
      if FAutoSnap then
        S := 0
      else
        S := Min(FMinSize, FMaxSize);
    end
    else
      S := Min(FMinSize, FMaxSize);
  end;
  if S = FStartSize then
    Exit;
  if not DoCanResize(S) then
    Exit;
  FNewSize := S;
  ApplySize(S);
  Result := True;
  if Assigned(FOnMoved) then
    FOnMoved(Self);
end;

procedure TPPGCustomSplitter.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TPPGCustomSplitter.KeyDown(var Key: Word; Shift: TShiftState);
var
  Step, Dir: Integer;
begin
  inherited KeyDown(Key, Shift);
  if FDragging then
  begin
    if Key = VK_ESCAPE then
    begin
      EndDrag(False);
      if GetCapture = Handle then
        ReleaseCapture;
      Key := 0;
    end;
    Exit;
  end;
  if ssCtrl in Shift then
    Step := 1
  else
    Step := PPGScale(10, ScalePPI);
  Dir := 0;
  case Key of
    VK_LEFT: if Horizontal then Dir := -1;
    VK_RIGHT: if Horizontal then Dir := 1;
    VK_UP: if not Horizontal then Dir := -1;
    VK_DOWN: if not Horizontal then Dir := 1;
    VK_HOME:
      begin
        MoveBy(-MaxInt div 2);
        Key := 0;
      end;
    VK_END:
      begin
        MoveBy(MaxInt div 2);
        Key := 0;
      end;
  end;
  if Dir <> 0 then
  begin
    // Pfeil in Richtung des Controls verkleinert es
    if Align in [alRight, alBottom] then
      Dir := -Dir;
    if Horizontal and UseRightToLeftAlignment and (Align = alNone) then
      Dir := -Dir;
    MoveBy(Dir * Step);
    Key := 0;
  end;
end;

procedure TPPGCustomSplitter.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TPPGCustomSplitter.DoExit;
begin
  inherited DoExit;
  EndDrag(False);
  Invalidate;
end;

procedure TPPGCustomSplitter.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  PPI, CX, CY, D, I, LineW: Integer;
  LineCol, DotCol: TColor;
  R: TRect;
  HC, Active, Show: Boolean;
begin
  PPI := ScalePPI;
  HC := HighContrastSupport and PPGIsHighContrast;
  Active := FDragging or (Focused and FocusVisible);
  Show := Active or (MouseInside and Enabled) or (csDesigning in ComponentState);
  if not Show then
  begin
    // Ruhend unsichtbar wie in WinUI; mit Beveled eine dezente Linie
    if FBeveled then
    begin
      if HC then
        LineCol := PPGColorToRGB(clWindowText)
      else
        LineCol := PPGBlendColor(PPGColorToRGB(GetBackgroundColor), Tokens.TextPrimary, 0.18);
      CX := (ClientR.Left + ClientR.Right) div 2;
      CY := (ClientR.Top + ClientR.Bottom) div 2;
      if Horizontal then
        R := Rect(CX, ClientR.Top, CX + 1, ClientR.Bottom)
      else
        R := Rect(ClientR.Left, CY, ClientR.Right, CY + 1);
      ACanvas.FillRoundRect(R, 0, LineCol, 255);
    end;
    DoUserPaint(ACanvas);
    Exit;
  end;
  if HC then
  begin
    if Active then
      LineCol := PPGColorToRGB(clHighlight)
    else
      LineCol := PPGColorToRGB(clWindowText);
    DotCol := LineCol;
  end
  else if Active then
  begin
    LineCol := PPGColorToRGB(EffectiveAppearance.FocusColor);
    DotCol := LineCol;
  end
  else
  begin
    LineCol := PPGBlendColor(PPGColorToRGB(GetBackgroundColor), Tokens.TextPrimary, 0.25);
    DotCol := Tokens.TextSecondary;
  end;
  CX := (ClientR.Left + ClientR.Right) div 2;
  CY := (ClientR.Top + ClientR.Bottom) div 2;
  LineW := Max(1, PPGScale(1, PPI));
  if Active then
    LineW := Max(2, PPGScale(2, PPI));
  // Linie ueber die ganze Laenge
  if Horizontal then
    R := Rect(CX - LineW div 2, ClientR.Top, CX - LineW div 2 + LineW, ClientR.Bottom)
  else
    R := Rect(ClientR.Left, CY - LineW div 2, ClientR.Right, CY - LineW div 2 + LineW);
  ACanvas.FillRoundRect(R, 0, LineCol, 255);
  // Griff: drei Punkte in der Mitte
  D := Max(3, PPGScale(3, PPI));
  for I := -1 to 1 do
  begin
    if Horizontal then
      R := Rect(CX - D div 2 - 1, CY + I * 2 * D - D div 2, CX - D div 2 - 1 + D + 2,
        CY + I * 2 * D - D div 2 + D)
    else
      R := Rect(CX + I * 2 * D - D div 2, CY - D div 2 - 1, CX + I * 2 * D - D div 2 + D,
        CY - D div 2 - 1 + D + 2);
    ACanvas.FillEllipse(R, DotCol, 255);
  end;
  DoUserPaint(ACanvas);
end;

procedure TPPGCustomSplitter.SetBeveled(const Value: Boolean);
begin
  if FBeveled <> Value then
  begin
    FBeveled := Value;
    Invalidate;
  end;
end;

function TPPGCustomSplitter.GetCanvas: TCanvas;
begin
  if FInUserPaint then
    Result := FPaintCanvas
  else
    Result := nil;
end;

procedure TPPGCustomSplitter.DoUserPaint(const ACanvas: IPPGCanvas);
var
  DC: HDC;
begin
  if not Assigned(FOnPaint) then
    Exit;
  if FPaintCanvas = nil then
    FPaintCanvas := TCanvas.Create;
  DC := ACanvas.BeginGdi;
  try
    FPaintCanvas.Handle := DC;
    try
      FInUserPaint := True;
      try
        FOnPaint(Self);
      finally
        FInUserPaint := False;
      end;
    finally
      FPaintCanvas.Handle := 0;
    end;
  finally
    ACanvas.EndGdi(DC);
  end;
end;

function TPPGCustomSplitter.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_SEPARATOR;
end;

function TPPGCustomSplitter.AccValue: string;
var
  C: TControl;
begin
  C := FindResizeControl;
  if C = nil then
    Result := ''
  else if Horizontal then
    Result := IntToStr(C.Width)
  else
    Result := IntToStr(C.Height);
end;

end.
