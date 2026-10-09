unit PPG.Notifications;

{ TPPGNotificationCenter - Benachrichtigungen ("Toasts") der Anwendung (Phase 7d).

  - Komponente aufs Formular; Show(Titel, Text, Art, Dauer, Aktionen) zeigt
    einen Toast: eigenes Fenster ohne Aktivierung (WS_EX_NOACTIVATE, der
    Fokus bleibt in der Anwendung), gestapelt in einer Ecke des Monitors des
    Formulars (Position), hoechstens MaxVisible zugleich, weitere warten.
  - Ein-/Ausblenden (Deckkraft und Gleiten) und das Nachruecken des Stapels
    sind animiert; Auto-Ausblenden nach Duration ms, solange die Maus ueber
    dem Toast steht, ist die Zeit angehalten.
  - Schliessen-Knopf, bis zu drei Aktions-Buttons (OnAction), Klick auf den
    Toast (OnToastClick); OnClose mit Grund.
  - Laeuft eine Vollbild-Anwendung bzw. Praesentation
    (SHQueryUserNotificationState), warten neue Toasts, bis das vorbei ist.
  - Kein eigener Timer: alles laeuft ueber den gemeinsamen Animator.
  - Screenreader: Rolle Alarm, Meldung EVENT_SYSTEM_ALERT beim Zeigen. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.Generics.Collections, Vcl.Controls, Vcl.Graphics, Vcl.Forms,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Markup, PPG.StyleManager,
  PPG.Controls.Base, PPG.Feedback;

type
  TPPGNotificationCenter = class;

  TPPGToastPosition = (npBottomRight, npTopRight, npBottomLeft, npTopLeft);
  TPPGToastCloseReason = (tcrTimeout, tcrUser, tcrAction, tcrClick, tcrCode);

  /// Ein Toast (Fenster). Lebensdauer verwaltet das NotificationCenter.
  TPPGToast = class(TPPGCustomControl)
  private
    FCenter: TPPGNotificationCenter;
    FTitle: string;
    FMessage: string;
    FSeverity: TPPGSeverity;
    FActions: TArray<string>;
    FDuration: Integer;
    FMarkup: TPPGMarkupLayout;
    FLife: TPPGAnimation;     // 0..1 ueber Duration
    FAppear: TPPGAnimation;   // 0 = unsichtbar, 1 = da
    FMove: TPPGAnimation;     // 0..1 von FFromY nach FToY
    FFromY, FToY, FX: Integer;
    FHotPart: Integer;        // -1 = nichts, -2 = Schliessen, >= 0 Aktion, -3 = Flaeche
    FDownPart: Integer;
    FClosing: Boolean;
    FCloseReason: TPPGToastCloseReason;
    FShown: Boolean;
    FPPI: Integer;
    FData: Pointer;
    FTag: NativeInt;
    procedure LifeStep(Sender: TObject);
    procedure AppearStep(Sender: TObject);
    procedure MoveStep(Sender: TObject);
    procedure ApplyWindow;
    function CurrentY: Integer;
    function PartAt(X, Y: Integer): Integer;
    procedure GetLayout(out IconR, TextR, CloseR: TRect; out ActionRects: TArray<TRect>);
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure Resize; override;
    procedure ApplyRegion;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function AccRole: Integer; override;
    function AccName: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ScalePPI: Integer; override;
    /// Benoetigte Hoehe bei der Breite des Centers.
    function MeasureHeight(AWidth: Integer): Integer;
    /// Schliessen (Ausblenden, dann OnClose und Freigabe).
    procedure Close(Reason: TPPGToastCloseReason = tcrCode);
    /// Auto-Ausblenden anhalten bzw. fortsetzen.
    procedure PauseTimer;
    procedure ResumeTimer;
    function PartRect(Part: Integer): TRect;
    property Title: string read FTitle;
    property Message: string read FMessage;
    property Severity: TPPGSeverity read FSeverity;
    property Actions: TArray<string> read FActions;
    property Duration: Integer read FDuration;
    property Shown: Boolean read FShown;
    property Closing: Boolean read FClosing;
    property Data: Pointer read FData write FData;
    property Tag: NativeInt read FTag write FTag;
  end;

  TPPGToastEvent = procedure(Sender: TObject; Toast: TPPGToast) of object;
  TPPGToastActionEvent = procedure(Sender: TObject; Toast: TPPGToast; ActionIndex: Integer) of object;
  TPPGToastCloseEvent = procedure(Sender: TObject; Toast: TPPGToast; Reason: TPPGToastCloseReason) of object;

  TPPGNotificationCenter = class(TComponent)
  private
    FToasts: TList<TPPGToast>;   // sichtbar (inkl. ausblendende)
    FQueue: TList<TPPGToast>;    // wartend
    FPosition: TPPGToastPosition;
    FDuration: Integer;
    FMaxVisible: Integer;
    FToastWidth: Integer;
    FPreset: string;
    FStyleManager: TPPGStyleManager;
    FAnimation: TPPGAnimationSettings;
    FRespectQuietHours: Boolean;
    FPoll: TPPGAnimation;
    FWnd: HWND;
    // Beendete Toasts, deren Freigabe gepostet ist. Der Destruktor gibt sie
    // selbst frei: DeallocateHWnd verwirft die ausstehenden Nachrichten.
    FReleasing: TList<TPPGToast>;
    FOnAction: TPPGToastActionEvent;
    FOnToastClick: TPPGToastEvent;
    FOnClose: TPPGToastCloseEvent;
    FOnShow: TPPGToastEvent;
    procedure SetAnimation(const Value: TPPGAnimationSettings);
    procedure SetPosition(const Value: TPPGToastPosition);
    procedure SetPreset(const Value: string);
    procedure SetMaxVisible(const Value: Integer);
    procedure ReleaseLater(Toast: TPPGToast);
    procedure SetToastWidth(const Value: Integer);
    procedure SetDuration(const Value: Integer);
    procedure SetStyleManager(const Value: TPPGStyleManager);
    procedure WndMethod(var Msg: TMessage);
    procedure PollStep(Sender: TObject);
    function OwnerForm: TCustomForm;
    function WorkArea: TRect;
    function FormPPI: Integer;
    procedure ShowPending;
    procedure ToastClosed(Toast: TPPGToast);
    procedure ToastFinished(Toast: TPPGToast);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    /// Stapel neu anordnen (Animate: Nachruecken animiert).
    procedure Arrange(Animate: Boolean); virtual;
    /// True, wenn gerade nicht gestoert werden soll (Vollbild, Praesentation).
    function QuietTime: Boolean; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Zeigt einen Toast. ADuration < 0 = Duration des Centers, 0 = bis zum Schliessen.
    function Show(const ATitle, AMessage: string; ASeverity: TPPGSeverity;
      ADuration: Integer; const AActions: array of string): TPPGToast; overload;
    function Show(const ATitle, AMessage: string; ASeverity: TPPGSeverity = psInformational;
      ADuration: Integer = -1): TPPGToast; overload;
    /// Schliesst alle Toasts (auch wartende).
    procedure CloseAll;
    function VisibleCount: Integer;
    function PendingCount: Integer;
    function Toast(Index: Integer): TPPGToast;
  published
    property Position: TPPGToastPosition read FPosition write SetPosition default npBottomRight;
    /// Anzeigedauer in ms (0 = bis zum Schliessen).
    property Duration: Integer read FDuration write SetDuration default 5000;
    property MaxVisible: Integer read FMaxVisible write SetMaxVisible default 3;
    /// Breite in logischen px.
    property ToastWidth: Integer read FToastWidth write SetToastWidth default 360;
    property Preset: string read FPreset write SetPreset;
    property StyleManager: TPPGStyleManager read FStyleManager write SetStyleManager;
    /// Ein-/Ausblenden und Verschieben (wie Animation der Controls).
    property Animation: TPPGAnimationSettings read FAnimation write SetAnimation;
    /// Bei Vollbild/Praesentation warten (SHQueryUserNotificationState).
    property RespectQuietHours: Boolean read FRespectQuietHours write FRespectQuietHours default True;
    property OnAction: TPPGToastActionEvent read FOnAction write FOnAction;
    property OnClose: TPPGToastCloseEvent read FOnClose write FOnClose;
    property OnShow: TPPGToastEvent read FOnShow write FOnShow;
    property OnToastClick: TPPGToastEvent read FOnToastClick write FOnToastClick;
  end;

implementation

uses
  PPG.Render.Registry,
  PPG.Lang,
  System.Math, Winapi.oleacc,
  PPG.Consts, PPG.Exceptions, PPG.Appearance, PPG.DpiUtils, PPG.Tokens, PPG.IconFont,
  PPG.Render.Gdi;

const
  ToastPad = 16;
  ToastGap = 12;
  ToastMargin = 16;
  IconSz = 16;
  ActionH = 32;
  SlideDist = 40;

  MsgReleaseToast = WM_USER + 1;

  // SHQueryUserNotificationState (shell32, ab Vista)
  QUNS_BUSY = 2;
  QUNS_RUNNING_D3D_FULL_SCREEN = 3;
  QUNS_PRESENTATION_MODE = 4;

type
  TSHQueryUserNotificationState = function(out State: Integer): HRESULT; stdcall;

var
  GQueryState: TSHQueryUserNotificationState = nil;
  GQueryResolved: Boolean = False;

function ContrastOn(Fill: TColor): TColor;
begin
  if PPGRelativeLuminance(Fill) < 0.4 then
    Result := clWhite
  else
    Result := clBlack;
end;

{ TPPGToast }

constructor TPPGToast.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csOpaque, csNoDesignVisible, csCaptureMouse];
  ParentBackground := False;
  Visible := False;
  FMarkup := TPPGMarkupLayout.Create;
  FHotPart := -1;
  FDownPart := -1;
  FLife := TPPGAnimation.Create(Self);
  FLife.OnStep := LifeStep;
  FAppear := TPPGAnimation.Create(Self);
  FAppear.OnStep := AppearStep;
  FMove := TPPGAnimation.Create(Self);
  FMove.Jump(1);
  FMove.OnStep := MoveStep;
end;

destructor TPPGToast.Destroy;
begin
  if FLife <> nil then
    FLife.OnStep := nil;
  if FAppear <> nil then
    FAppear.OnStep := nil;
  if FMove <> nil then
    FMove.OnStep := nil;
  FreeAndNil(FLife);
  FreeAndNil(FAppear);
  FreeAndNil(FMove);
  FreeAndNil(FMarkup);
  inherited Destroy;
end;

procedure TPPGToast.CreateParams(var Params: TCreateParams);
var
  F: TCustomForm;
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP;
  Params.ExStyle := WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE or WS_EX_TOPMOST or WS_EX_LAYERED;
  Params.WindowClass.style := Params.WindowClass.style or CS_DROPSHADOW;
  F := nil;
  if FCenter <> nil then
    F := FCenter.OwnerForm;
  if (F <> nil) and F.HandleAllocated then
    Params.WndParent := F.Handle
  else
    Params.WndParent := Application.Handle;
end;

procedure TPPGToast.CreateWnd;
begin
  inherited CreateWnd;
  SetLayeredWindowAttributes(Handle, 0, 0, LWA_ALPHA);
  ApplyRegion;
end;

procedure TPPGToast.Resize;
begin
  inherited Resize;
  ApplyRegion;
end;

procedure TPPGToast.ApplyRegion;
var
  D: Integer;
  Rgn: HRGN;
begin
  if not HandleAllocated then
    Exit;
  // Abgerundete Ecken wie die Karte (Region gehoert danach dem Fenster)
  D := 2 * PPGScale(Tokens.RadiusLarge, ScalePPI);
  Rgn := CreateRoundRectRgn(0, 0, Width + 1, Height + 1, D, D);
  if SetWindowRgn(Handle, Rgn, True) = 0 then
    DeleteObject(Rgn);
end;

function TPPGToast.ScalePPI: Integer;
begin
  if FPPI > 0 then
    Result := FPPI
  else
    Result := inherited ScalePPI;
end;

function TPPGToast.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGToast.IsDown: Boolean;
begin
  Result := False;
end;

procedure TPPGToast.WMMouseActivate(var Message: TWMMouseActivate);
begin
  Message.Result := MA_NOACTIVATE;
end;

procedure TPPGToast.GetLayout(out IconR, TextR, CloseR: TRect; out ActionRects: TArray<TRect>);
var
  PPI, Pad, W, I, X, BW, N: Integer;
begin
  PPI := ScalePPI;
  Pad := PPGScale(ToastPad, PPI);
  W := Width;
  IconR := Rect(Pad, Pad + PPGScale(2, PPI), Pad + PPGScale(IconSz, PPI), Pad + PPGScale(2 + IconSz, PPI));
  CloseR := Rect(W - PPGScale(8 + 28, PPI), PPGScale(8, PPI), W - PPGScale(8, PPI), PPGScale(8 + 28, PPI));
  TextR := Rect(IconR.Right + PPGScale(12, PPI), Pad, CloseR.Left - PPGScale(4, PPI), Height - Pad);
  N := Length(FActions);
  SetLength(ActionRects, N);
  if N > 0 then
  begin
    TextR.Bottom := Height - Pad - PPGScale(ActionH + 12, PPI);
    BW := (W - 2 * Pad - (N - 1) * PPGScale(8, PPI)) div N;
    X := Pad;
    for I := 0 to N - 1 do
    begin
      ActionRects[I] := Rect(X, Height - Pad - PPGScale(ActionH, PPI), X + BW, Height - Pad);
      Inc(X, BW + PPGScale(8, PPI));
    end;
  end;
  if UseRightToLeftAlignment then
  begin
    IconR := Rect(W - IconR.Right, IconR.Top, W - IconR.Left, IconR.Bottom);
    CloseR := Rect(W - CloseR.Right, CloseR.Top, W - CloseR.Left, CloseR.Bottom);
    TextR := Rect(W - TextR.Right, TextR.Top, W - TextR.Left, TextR.Bottom);
    for I := 0 to N - 1 do
      ActionRects[I] := Rect(W - ActionRects[I].Right, ActionRects[I].Top, W - ActionRects[I].Left,
        ActionRects[I].Bottom);
  end;
end;

function TPPGToast.MeasureHeight(AWidth: Integer): Integer;
var
  PPI, Pad, TextW: Integer;
  S: string;
begin
  PPI := ScalePPI;
  Pad := PPGScale(ToastPad, PPI);
  TextW := AWidth - 2 * Pad - PPGScale(IconSz + 12, PPI) - PPGScale(8 + 28 + 4, PPI) + Pad;
  if FTitle <> '' then
    S := '<b>' + StringReplace(StringReplace(FTitle, '&', '&amp;', [rfReplaceAll]), '<', '&lt;',
      [rfReplaceAll]) + '</b><br>' + FMessage
  else
    S := FMessage;
  FMarkup.Layout(S, Font, nil, Max(TextW, 20), True);
  Result := Max(FMarkup.Size.cy, PPGScale(20, PPI)) + 2 * Pad;
  if Length(FActions) > 0 then
    Inc(Result, PPGScale(ActionH + 12, PPI));
end;

function TPPGToast.PartRect(Part: Integer): TRect;
var
  IR, TR, CR: TRect;
  AR: TArray<TRect>;
begin
  GetLayout(IR, TR, CR, AR);
  if Part = -2 then
    Result := CR
  else if (Part >= 0) and (Part < Length(AR)) then
    Result := AR[Part]
  else
    Result := Rect(0, 0, 0, 0);
end;

function TPPGToast.PartAt(X, Y: Integer): Integer;
var
  IR, TR, CR: TRect;
  AR: TArray<TRect>;
  I: Integer;
begin
  GetLayout(IR, TR, CR, AR);
  if PtInRect(CR, Point(X, Y)) then
    Exit(-2);
  for I := 0 to High(AR) do
    if PtInRect(AR[I], Point(X, Y)) then
      Exit(I);
  if PtInRect(ClientRect, Point(X, Y)) then
    Result := -3
  else
    Result := -1;
end;

procedure TPPGToast.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  T: TPPGTokens;
  A: TPPGAppearance;
  PPI, I, Rad: Integer;
  HC: Boolean;
  Fill, Border, TextCol, Sev: TColor;
  IR, TR, CR, R: TRect;
  AR: TArray<TRect>;
  S: TPPGSurfaceStyle;
  G: TPPGIconGlyph;
  Txt: string;
  Pts: array[0..1] of TPoint;
begin
  PPI := ScalePPI;
  T := Tokens;
  A := EffectiveAppearance;
  HC := HighContrastSupport and PPGIsHighContrast;
  Sev := PPGSeverityColor(T, FSeverity);
  if HC then
  begin
    Fill := PPGColorToRGB(clWindow);
    Border := PPGColorToRGB(clWindowText);
    TextCol := PPGColorToRGB(clWindowText);
    Sev := PPGColorToRGB(clHighlight);
  end
  else
  begin
    Fill := T.Layer;
    Border := T.Stroke;
    TextCol := T.TextPrimary;
  end;
  // Kein Fenster-Hintergrund dahinter: Region schneidet die Ecken ab
  Rad := PPGScale(T.RadiusLarge, PPI);
  ACanvas.FillRoundRect(ClientR, 0, Fill, 255);
  ACanvas.FrameRoundRect(ClientR, Rad, 1, Border, 255);
  // Farbstreifen der Schwere links
  ACanvas.FillRoundRect(Rect(ClientR.Left + 1, ClientR.Top + Rad, ClientR.Left + PPGScale(4, PPI),
    ClientR.Bottom - Rad), PPGScale(2, PPI), Sev, 255);
  GetLayout(IR, TR, CR, AR);
  case FSeverity of
    psSuccess: G := igSuccess;
    psWarning: G := igWarning;
    psError: G := igError;
  else
    G := igInfo;
  end;
  if not PPGDrawIcon(ACanvas, IR, G, Sev, PPGScale(IconSz, PPI)) then
    ACanvas.FillEllipse(IR, Sev, 255);
  if FTitle <> '' then
    Txt := '<b>' + StringReplace(StringReplace(FTitle, '&', '&amp;', [rfReplaceAll]), '<', '&lt;',
      [rfReplaceAll]) + '</b><br>' + FMessage
  else
    Txt := FMessage;
  FMarkup.Layout(Txt, Font, nil, Max(TR.Right - TR.Left, 20), True);
  ACanvas.PushClipRoundRect(TR, 0);
  try
    FMarkup.Draw(ACanvas, TR.Left, TR.Top, TextCol, PPGColorToRGB(A.FocusColor), True);
  finally
    ACanvas.PopClip;
  end;
  // Schliessen
  R := CR;
  if FHotPart = -2 then
    ACanvas.FillRoundRect(R, PPGScale(4, PPI), TextCol, IfThen(FDownPart = -2, 28, 16));
  if not PPGDrawIcon(ACanvas, R, igClose, TextCol, PPGScale(10, PPI)) then
  begin
    InflateRect(R, -PPGScale(9, PPI), -PPGScale(9, PPI));
    Pts[0] := R.TopLeft;
    Pts[1] := R.BottomRight;
    ACanvas.DrawPolyline(Pts, PPGScale(1, PPI) + 1, TextCol, 255);
    Pts[0] := Point(R.Right, R.Top);
    Pts[1] := Point(R.Left, R.Bottom);
    ACanvas.DrawPolyline(Pts, PPGScale(1, PPI) + 1, TextCol, 255);
  end;
  // Aktions-Buttons im Stil des Presets
  for I := 0 to High(AR) do
  begin
    if (FDownPart = I) and (FHotPart = I) then
      S := A.Resolve(vsDown, PPI, False)
    else if FHotPart = I then
      S := A.Resolve(vsHot, PPI, False)
    else
      S := A.Resolve(vsNormal, PPI, False);
    S.GlowAlpha := 0;
    S.Rounding := Min(S.Rounding, PPGScale(4, PPI));
    Renderer.DrawSurface(ACanvas, AR[I], S);
    ACanvas.DrawText(AR[I], FActions[I], Font, S.TextColor,
      DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
  end;
end;

procedure TPPGToast.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = mbLeft then
  begin
    FDownPart := PartAt(X, Y);
    Invalidate;
  end;
end;

procedure TPPGToast.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  P := PartAt(X, Y);
  if P <> FHotPart then
  begin
    FHotPart := P;
    Invalidate;
  end;
end;

procedure TPPGToast.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P, D: Integer;
  C: TPPGNotificationCenter;
begin
  D := FDownPart;
  FDownPart := -1;
  Invalidate;
  inherited MouseUp(Button, Shift, X, Y);
  if (Button <> mbLeft) or FClosing then
    Exit;
  P := PartAt(X, Y);
  if P <> D then
    Exit;
  C := FCenter;
  if P = -2 then
    Close(tcrUser)
  else if P >= 0 then
  begin
    if (C <> nil) and Assigned(C.FOnAction) then
      C.FOnAction(C, Self, P);
    Close(tcrAction);
  end
  else if P = -3 then
  begin
    if (C <> nil) and Assigned(C.FOnToastClick) then
      C.FOnToastClick(C, Self);
    Close(tcrClick);
  end;
end;

procedure TPPGToast.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  PauseTimer;
end;

procedure TPPGToast.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHotPart <> -1 then
  begin
    FHotPart := -1;
    Invalidate;
  end;
  ResumeTimer;
end;

procedure TPPGToast.PauseTimer;
begin
  if FLife.Running then
    FLife.Stop; // Value bleibt stehen
end;

procedure TPPGToast.ResumeTimer;
var
  Rest: Integer;
begin
  if FClosing or not FShown or (FDuration <= 0) or FLife.Running then
    Exit;
  Rest := Round(FDuration * (1 - FLife.Value));
  if Rest < 1 then
    Close(tcrTimeout)
  else
    FLife.AnimateTo(1, Cardinal(Rest), ekLinear);
end;

procedure TPPGToast.LifeStep(Sender: TObject);
begin
  if not FLife.Running and (FLife.Value >= 1) then
    Close(tcrTimeout);
end;

function TPPGToast.CurrentY: Integer;
begin
  Result := FFromY + Round((FToY - FFromY) * FMove.Value);
end;

procedure TPPGToast.ApplyWindow;
var
  Alpha: Byte;
  Slide, X: Integer;
  P: Single;
begin
  if not HandleAllocated then
    Exit;
  P := FAppear.Value;
  Alpha := Round(255 * PPGClampSingle(P, 0, 1));
  SetLayeredWindowAttributes(Handle, 0, Alpha, LWA_ALPHA);
  // Gleitet von der Seite der Ecke herein
  Slide := Round((1 - P) * PPGScale(SlideDist, ScalePPI));
  if (FCenter <> nil) and (FCenter.Position in [npBottomLeft, npTopLeft]) then
    X := FX - Slide
  else
    X := FX + Slide;
  SetWindowPos(Handle, HWND_TOPMOST, X, CurrentY, Width, Height,
    SWP_NOACTIVATE or SWP_SHOWWINDOW or SWP_NOSIZE);
end;

procedure TPPGToast.AppearStep(Sender: TObject);
begin
  ApplyWindow;
  if FClosing and not FAppear.Running and (FAppear.Value <= 0) and (FCenter <> nil) then
    FCenter.ToastFinished(Self);
end;

procedure TPPGToast.MoveStep(Sender: TObject);
begin
  ApplyWindow;
end;

procedure TPPGToast.Close(Reason: TPPGToastCloseReason);
begin
  if FClosing then
    Exit;
  FClosing := True;
  FCloseReason := Reason;
  if FLife.Running then
    FLife.Stop;
  if FCenter <> nil then
    FCenter.ToastClosed(Self);
  if FShown and HandleAllocated and (FCenter <> nil) and FCenter.FAnimation.EffectiveEnabled and
    PPGSystemAnimationsEnabled then
    FAppear.AnimateTo(0, 200, ekSmooth)
  else
  begin
    FAppear.Jump(0);
    if FCenter <> nil then
      FCenter.ToastFinished(Self);
  end;
end;

function TPPGToast.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_ALERT;
end;

function TPPGToast.AccName: string;
begin
  Result := Trim(FTitle + ' ' + PPGStripMarkup(FMessage));
end;

{ TPPGNotificationCenter }

procedure TPPGNotificationCenter.SetPreset(const Value: string);
begin
  // Audit 5a: wie TPPGCustomControl.SetPreset pruefen
  FPreset := PPGCheckPreset(Self, Value);
end;

constructor TPPGNotificationCenter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FToasts := TList<TPPGToast>.Create;
  FQueue := TList<TPPGToast>.Create;
  FReleasing := TList<TPPGToast>.Create;
  FDuration := 5000;
  FMaxVisible := 3;
  FToastWidth := 360;
  FAnimation := TPPGAnimationSettings.Create(Self);
  FRespectQuietHours := True;
  FPoll := TPPGAnimation.Create(Self);
  FPoll.OnStep := PollStep;
end;

procedure TPPGNotificationCenter.SetAnimation(const Value: TPPGAnimationSettings);
begin
  FAnimation.Assign(Value);
end;

destructor TPPGNotificationCenter.Destroy;
var
  T: TPPGToast;
begin
  if FPoll <> nil then
    FPoll.OnStep := nil;
  FreeAndNil(FPoll);
  FreeAndNil(FAnimation);
  // Toasts ohne Ereignisse freigeben
  if FToasts <> nil then
    for T in FToasts do
    begin
      T.FCenter := nil;
      T.Free;
    end;
  if FQueue <> nil then
    for T in FQueue do
    begin
      T.FCenter := nil;
      T.Free;
    end;
  if FReleasing <> nil then
    for T in FReleasing do
      T.Free;
  FreeAndNil(FReleasing);
  FreeAndNil(FToasts);
  FreeAndNil(FQueue);
  if FWnd <> 0 then
    DeallocateHWnd(FWnd);
  inherited Destroy;
end;

procedure TPPGNotificationCenter.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FStyleManager) then
    FStyleManager := nil;
end;

procedure TPPGNotificationCenter.SetStyleManager(const Value: TPPGStyleManager);
begin
  if FStyleManager <> Value then
  begin
    if FStyleManager <> nil then
      FStyleManager.RemoveFreeNotification(Self);
    FStyleManager := Value;
    if FStyleManager <> nil then
      FStyleManager.FreeNotification(Self);
  end;
end;

procedure TPPGNotificationCenter.SetMaxVisible(const Value: Integer);
begin
  FMaxVisible := PPGCheckRange(Self, 'MaxVisible', Value, 1, 20);
end;

procedure TPPGNotificationCenter.SetToastWidth(const Value: Integer);
begin
  FToastWidth := PPGCheckRange(Self, 'ToastWidth', Value, 160, 1000);
end;

procedure TPPGNotificationCenter.SetDuration(const Value: Integer);
begin
  FDuration := PPGCheckRange(Self, 'Duration', Value, 0, 600000);
end;

function TPPGNotificationCenter.OwnerForm: TCustomForm;
begin
  if Owner is TCustomForm then
    Result := TCustomForm(Owner)
  else if (Owner is TControl) then
    Result := GetParentForm(TControl(Owner))
  else
    Result := Application.MainForm;
end;

function TPPGNotificationCenter.WorkArea: TRect;
var
  F: TCustomForm;
  M: TMonitor;
begin
  F := OwnerForm;
  M := nil;
  if (F <> nil) and F.HandleAllocated then
    M := Screen.MonitorFromWindow(F.Handle, mdNearest);
  if M = nil then
    M := Screen.PrimaryMonitor;
  if M <> nil then
    Result := M.WorkareaRect
  else
    Result := Screen.WorkAreaRect;
end;

function TPPGNotificationCenter.FormPPI: Integer;
var
  F: TCustomForm;
begin
  F := OwnerForm;
  if F <> nil then
    Result := PPGControlPPI(F)
  else
    Result := Screen.PixelsPerInch;
end;

function TPPGNotificationCenter.QuietTime: Boolean;
var
  State: Integer;
  H: HMODULE;
begin
  Result := False;
  if not FRespectQuietHours then
    Exit;
  if not GQueryResolved then
  begin
    GQueryResolved := True;
    H := GetModuleHandle('shell32.dll');
    if H <> 0 then
      @GQueryState := GetProcAddress(H, 'SHQueryUserNotificationState');
  end;
  if Assigned(GQueryState) and Succeeded(GQueryState(State)) then
    Result := State in [QUNS_BUSY, QUNS_RUNNING_D3D_FULL_SCREEN, QUNS_PRESENTATION_MODE];
end;

function TPPGNotificationCenter.Show(const ATitle, AMessage: string; ASeverity: TPPGSeverity;
  ADuration: Integer): TPPGToast;
begin
  Result := Show(ATitle, AMessage, ASeverity, ADuration, []);
end;

function TPPGNotificationCenter.Show(const ATitle, AMessage: string; ASeverity: TPPGSeverity;
  ADuration: Integer; const AActions: array of string): TPPGToast;
var
  T: TPPGToast;
  I, N: Integer;
begin
  T := TPPGToast.Create(nil);
  T.FCenter := Self;
  T.FTitle := ATitle;
  T.FMessage := AMessage;
  T.FSeverity := ASeverity;
  if ADuration < 0 then
    T.FDuration := FDuration
  else
    T.FDuration := ADuration;
  N := Min(Length(AActions), 3);
  SetLength(T.FActions, N);
  for I := 0 to N - 1 do
    T.FActions[I] := AActions[I];
  if FPreset <> '' then
    T.Preset := FPreset;
  if FStyleManager <> nil then
    T.StyleManager := FStyleManager;
  if OwnerForm <> nil then
  begin
    T.Font := OwnerForm.Font;
    T.BiDiMode := OwnerForm.BiDiMode;
  end;
  FQueue.Add(T);
  Result := T;
  ShowPending;
end;

procedure TPPGNotificationCenter.ShowPending;
var
  T: TPPGToast;
  Active: Integer;
  I: Integer;
begin
  if csDestroying in ComponentState then
    Exit;
  if FQueue.Count = 0 then
    Exit;
  if QuietTime then
  begin
    // Spaeter erneut pruefen (ueber den Animator, kein Timer)
    if not FPoll.Running then
    begin
      FPoll.Jump(0);
      FPoll.AnimateTo(1, 2000, ekLinear);
    end;
    Exit;
  end;
  Active := 0;
  for I := 0 to FToasts.Count - 1 do
    if not FToasts[I].FClosing then
      Inc(Active);
  while (FQueue.Count > 0) and (Active < FMaxVisible) do
  begin
    T := FQueue[0];
    FQueue.Delete(0);
    FToasts.Add(T);
    Inc(Active);
    T.FPPI := FormPPI;
    T.Width := PPGScale(FToastWidth, T.FPPI);
    T.Height := T.MeasureHeight(T.Width);
    T.HandleNeeded;
    T.FShown := True;
    Arrange(False);
    if FAnimation.EffectiveEnabled then
    begin
      T.FAppear.Jump(0);
      T.ApplyWindow;
      T.FAppear.AnimateTo(1, 250, ekDecelerate);
    end
    else
    begin
      T.FAppear.Jump(1);
      T.ApplyWindow;
    end;
    if T.FDuration > 0 then
      T.FLife.AnimateTo(1, Cardinal(T.FDuration), ekLinear);
    T.NotifyAccessibility(EVENT_SYSTEM_ALERT);
    if Assigned(FOnShow) then
      FOnShow(Self, T);
  end;
end;

procedure TPPGNotificationCenter.PollStep(Sender: TObject);
begin
  if not FPoll.Running and (FPoll.Value >= 1) then
    ShowPending;
end;

procedure TPPGNotificationCenter.SetPosition(const Value: TPPGToastPosition);
begin
  if FPosition = Value then
    Exit;
  FPosition := Value;
  // Sichtbare Meldungen sofort an die neue Ecke\n  Arrange(False);
end;

procedure TPPGNotificationCenter.Arrange(Animate: Boolean);
var
  WA: TRect;
  I, Y, Gap, Margin, X: Integer;
  T: TPPGToast;
  Bottom: Boolean;
begin
  WA := WorkArea;
  Bottom := FPosition in [npBottomRight, npBottomLeft];
  if Bottom then
    Y := WA.Bottom
  else
    Y := WA.Top;
  // Neuester Toast an der Ecke, aeltere ruecken weg
  for I := FToasts.Count - 1 downto 0 do
  begin
    T := FToasts[I];
    if T.FClosing then
      Continue;
    Gap := PPGScale(ToastGap, T.ScalePPI);
    Margin := PPGScale(ToastMargin, T.ScalePPI);
    if FPosition in [npBottomLeft, npTopLeft] then
      X := WA.Left + Margin
    else
      X := WA.Right - Margin - T.Width;
    T.FX := X;
    if Bottom then
    begin
      if Y = WA.Bottom then
        Dec(Y, Margin)
      else
        Dec(Y, Gap);
      Dec(Y, T.Height);
      if Animate and (T.FToY <> Y) and FAnimation.EffectiveEnabled then
      begin
        T.FFromY := T.CurrentY;
        T.FToY := Y;
        T.FMove.Jump(0);
        T.FMove.AnimateTo(1, 250, ekDecelerate);
      end
      else
      begin
        T.FFromY := Y;
        T.FToY := Y;
        T.FMove.Jump(1);
        T.ApplyWindow;
      end;
    end
    else
    begin
      if Y = WA.Top then
        Inc(Y, Margin)
      else
        Inc(Y, Gap);
      if Animate and (T.FToY <> Y) and FAnimation.EffectiveEnabled then
      begin
        T.FFromY := T.CurrentY;
        T.FToY := Y;
        T.FMove.Jump(0);
        T.FMove.AnimateTo(1, 250, ekDecelerate);
      end
      else
      begin
        T.FFromY := Y;
        T.FToY := Y;
        T.FMove.Jump(1);
        T.ApplyWindow;
      end;
      Inc(Y, T.Height);
    end;
  end;
end;

procedure TPPGNotificationCenter.ToastClosed(Toast: TPPGToast);
var
  I: Integer;
begin
  // Wartender Toast geschlossen: sofort entfernen
  I := FQueue.IndexOf(Toast);
  if I >= 0 then
  begin
    FQueue.Delete(I);
    // Zustand vor dem Anwender-Ereignis: die Freigabe steht auch dann fest,
    // wenn OnClose wirft
    ReleaseLater(Toast);
    if Assigned(FOnClose) then
      FOnClose(Self, Toast, Toast.FCloseReason);
    Exit;
  end;
  // Die anderen ruecken nach; wartende kommen dazu
  Arrange(True);
  ShowPending;
end;

procedure TPPGNotificationCenter.ToastFinished(Toast: TPPGToast);
var
  I: Integer;
begin
  I := FToasts.IndexOf(Toast);
  if I < 0 then
    Exit;
  FToasts.Delete(I);
  if Toast.HandleAllocated then
    ShowWindow(Toast.Handle, SW_HIDE);
  // Freigabe ausserhalb des Animator-Takts bzw. des Mausereignisses; vor
  // dem Anwender-Ereignis festgelegt (wirft OnClose, bleibt kein Leck)
  ReleaseLater(Toast);
  if Assigned(FOnClose) then
    FOnClose(Self, Toast, Toast.FCloseReason);
end;

procedure TPPGNotificationCenter.ReleaseLater(Toast: TPPGToast);
begin
  Toast.FCenter := nil;
  FReleasing.Add(Toast);
  if FWnd = 0 then
    FWnd := AllocateHWnd(WndMethod);
  PostMessage(FWnd, MsgReleaseToast, 0, LPARAM(Toast));
end;

procedure TPPGNotificationCenter.WndMethod(var Msg: TMessage);
var
  T: TPPGToast;
begin
  if Msg.Msg = MsgReleaseToast then
  begin
    T := TPPGToast(Msg.LParam);
    // Nur freigeben, was noch aussteht (sonst doppelt)
    if FReleasing.Remove(T) >= 0 then
      T.Free;
  end
  else
    Msg.Result := DefWindowProc(FWnd, Msg.Msg, Msg.WParam, Msg.LParam);
end;

procedure TPPGNotificationCenter.CloseAll;
begin
  while FQueue.Count > 0 do
    FQueue[FQueue.Count - 1].Close(tcrCode);
  while VisibleCount > 0 do
    Toast(0).Close(tcrCode);
end;

function TPPGNotificationCenter.VisibleCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FToasts.Count - 1 do
    if not FToasts[I].FClosing then
      Inc(Result);
end;

function TPPGNotificationCenter.PendingCount: Integer;
begin
  Result := FQueue.Count;
end;

function TPPGNotificationCenter.Toast(Index: Integer): TPPGToast;
var
  I, N: Integer;
begin
  N := 0;
  for I := 0 to FToasts.Count - 1 do
    if not FToasts[I].FClosing then
    begin
      if N = Index then
        Exit(FToasts[I]);
      Inc(N);
    end;
  raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, VisibleCount - 1]);
end;

end.
