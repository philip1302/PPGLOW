unit PPG.Overlay;

{ Gemeinsame Bausteine fuer Overlays ueber Controls (Phase 19c; spaeter auch
  das Spotlight der Tour, Phase 16).

  TPPGDimWindow: randloses Fenster ueber einem Bildschirmrechteck.
  - WS_EX_LAYERED mit gleichmaessiger Deckkraft (SetLayeredWindowAttributes):
    geht auch ohne DWM und im Remote-Desktop. Deckkraft 1 statt 0, damit das
    Fenster die Maus auch dann abfaengt, wenn es noch nicht sichtbar sein soll
    (BusyOverlay: Eingaben sind ab Show gesperrt, gezeigt wird erst nach Delay).
  - Gehoert dem Formular (WndParent), damit es ueber ihm liegt, mit ihm
    minimiert wird und nie die Aktivierung nimmt (WS_EX_NOACTIVATE,
    MA_NOACTIVATE). Ueber dem Fenster zeigt die Maus den Warte-Cursor.
  - Ein neues Formular-Handle (RecreateWnd) erkennt EnsureOwner und legt das
    Fenster neu an.

  PPGOverlayRect: Bildschirmrechteck eines Ziels; beim Formular der
  Client-Bereich (Titelleiste bleibt frei, das Fenster laesst sich ziehen). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms;

type
  TPPGDimWindow = class(TWinControl)
  private
    FOwnerForm: TCustomForm;
    FOwnerWnd: HWND;
    FColor: TColor;
    FOpacity: Byte;
    FCursorWait: Boolean;
    procedure SetOpacity(const Value: Byte);
    procedure SetDimColor(const Value: TColor);
    procedure ApplyAlpha;
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    /// Formular, ueber dem das Fenster liegt (Besitzer).
    procedure SetOwnerForm(AForm: TCustomForm);
    /// Neues Formular-Handle seit dem Anlegen? Dann neu anlegen.
    procedure EnsureOwner;
    /// Lage auf dem Bildschirm setzen und zeigen (ohne Aktivierung).
    procedure ShowAt(const ScreenRect: TRect);
    procedure HideWindow;
    function IsShown: Boolean;
    property OwnerForm: TCustomForm read FOwnerForm;
    property DimColor: TColor read FColor write SetDimColor;
    /// 0..255; 0 wird als 1 gesetzt (Fenster faengt die Maus weiter ab).
    property Opacity: Byte read FOpacity write SetOpacity;
    /// Warte-Cursor ueber dem Fenster (Vorgabe True).
    property CursorWait: Boolean read FCursorWait write FCursorWait;
  end;

/// Bildschirmrechteck eines Overlay-Ziels: Formular = Client-Bereich,
/// sonst die Lage des Controls. Leer, wenn es nicht angezeigt wird.
function PPGOverlayRect(Target: TWinControl): TRect;
/// True, wenn Wnd das Fenster von Target oder eines seiner Kinder ist.
function PPGWindowInTarget(Target: TWinControl; Wnd: HWND): Boolean;

implementation

function PPGOverlayRect(Target: TWinControl): TRect;
var
  P: TPoint;
begin
  Result := Rect(0, 0, 0, 0);
  if (Target = nil) or not Target.HandleAllocated or not Target.Showing then
    Exit;
  if Target is TCustomForm then
  begin
    if IsIconic(Target.Handle) then
      Exit;
    Winapi.Windows.GetClientRect(Target.Handle, Result);
    P := Target.ClientToScreen(Point(0, 0));
    OffsetRect(Result, P.X, P.Y);
  end
  else
    GetWindowRect(Target.Handle, Result);
end;

function PPGWindowInTarget(Target: TWinControl; Wnd: HWND): Boolean;
begin
  Result := (Target <> nil) and Target.HandleAllocated and (Wnd <> 0) and
    ((Wnd = Target.Handle) or IsChild(Target.Handle, Wnd));
end;

{ TPPGDimWindow }

constructor TPPGDimWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColor := clBlack;
  FOpacity := 96;
  FCursorWait := True;
  ControlStyle := ControlStyle + [csOpaque];
  Visible := False;
end;

procedure TPPGDimWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP;
  Params.ExStyle := WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE or WS_EX_LAYERED;
  if (FOwnerForm <> nil) and FOwnerForm.HandleAllocated then
    Params.WndParent := FOwnerForm.Handle
  else
    Params.WndParent := Application.Handle;
  FOwnerWnd := Params.WndParent;
end;

procedure TPPGDimWindow.CreateWnd;
begin
  inherited CreateWnd;
  ApplyAlpha;
end;

procedure TPPGDimWindow.SetOwnerForm(AForm: TCustomForm);
begin
  if FOwnerForm = AForm then
    Exit;
  FOwnerForm := AForm;
  if HandleAllocated then
    RecreateWnd;
end;

procedure TPPGDimWindow.EnsureOwner;
begin
  if HandleAllocated and (FOwnerForm <> nil) and FOwnerForm.HandleAllocated and
    (FOwnerWnd <> FOwnerForm.Handle) then
  begin
    DestroyHandle;
    HandleNeeded;
  end;
end;

procedure TPPGDimWindow.ApplyAlpha;
var
  A: Byte;
begin
  if not HandleAllocated then
    Exit;
  A := FOpacity;
  if A = 0 then
    A := 1;
  SetLayeredWindowAttributes(Handle, 0, A, LWA_ALPHA);
end;

procedure TPPGDimWindow.SetOpacity(const Value: Byte);
begin
  if FOpacity = Value then
    Exit;
  FOpacity := Value;
  ApplyAlpha;
end;

procedure TPPGDimWindow.SetDimColor(const Value: TColor);
begin
  if FColor = Value then
    Exit;
  FColor := Value;
  if HandleAllocated then
    InvalidateRect(Handle, nil, True);
end;

procedure TPPGDimWindow.ShowAt(const ScreenRect: TRect);
begin
  HandleNeeded;
  // Ueber dem Besitzer, ohne ihn zu aktivieren
  SetWindowPos(Handle, HWND_TOP, ScreenRect.Left, ScreenRect.Top,
    ScreenRect.Right - ScreenRect.Left, ScreenRect.Bottom - ScreenRect.Top,
    SWP_NOACTIVATE or SWP_SHOWWINDOW);
end;

procedure TPPGDimWindow.HideWindow;
begin
  if HandleAllocated then
    ShowWindow(Handle, SW_HIDE);
end;

function TPPGDimWindow.IsShown: Boolean;
begin
  Result := HandleAllocated and IsWindowVisible(Handle);
end;

procedure TPPGDimWindow.WMMouseActivate(var Message: TWMMouseActivate);
begin
  Message.Result := MA_NOACTIVATE;
end;

procedure TPPGDimWindow.WMNCHitTest(var Message: TWMNCHitTest);
begin
  // Ganze Flaeche ist Client: kein Ziehen, keine Groessenaenderung
  Message.Result := HTCLIENT;
end;

procedure TPPGDimWindow.WMEraseBkgnd(var Message: TWMEraseBkgnd);
var
  R: TRect;
  B: HBRUSH;
begin
  Winapi.Windows.GetClientRect(Handle, R);
  B := CreateSolidBrush(ColorToRGB(FColor));
  try
    FillRect(Message.DC, R, B);
  finally
    DeleteObject(B);
  end;
  Message.Result := 1;
end;

procedure TPPGDimWindow.WMPaint(var Message: TWMPaint);
var
  PS: TPaintStruct;
begin
  // Nur die Flaeche (WM_ERASEBKGND); nichts zu zeichnen
  BeginPaint(Handle, PS);
  EndPaint(Handle, PS);
  Message.Result := 0;
end;

procedure TPPGDimWindow.WMSetCursor(var Message: TWMSetCursor);
begin
  if FCursorWait and (Message.HitTest = HTCLIENT) then
  begin
    Winapi.Windows.SetCursor(Screen.Cursors[crHourGlass]);
    Message.Result := 1;
  end
  else
    inherited;
end;

end.
