unit PPG.BusyOverlay;

{ Warte-Overlay ueber einem Control oder Formular (Phase 19c).

  TPPGBusyOverlay (nicht sichtbar):
  - Show/Hide (zaehlend, verschachtelbar): legt eine abgedunkelte Flaeche
    (TPPGDimWindow aus PPG.Overlay) ueber das Ziel und darauf eine Karte mit
    Ring, Text, Beschreibung, Fortschritt und optional Abbrechen.
  - Eingaben ins Ziel sind ab Show gesperrt, ohne dass es grau wird: die Maus
    faengt die Flaeche ab (zuerst fast durchsichtig), die Tastatur fuer
    Fenster im Ziel verwirft ein Nachrichtenhaken (PPG.AppHooks); Esc loest
    bei ShowCancel Abbrechen aus. Das Formular laesst sich waehrenddessen
    nicht schliessen (OnCloseQuery verkettet).
  - Delay: erst nach dieser Zeit wird abgedunkelt und die Karte gezeigt
    (kurze Arbeiten blitzen nicht). MinDisplayTime: einmal gezeigt, bleibt
    das Overlay mindestens so lange stehen. ShowNow zeigt sofort und zeichnet
    synchron - fuer Code, der danach den Hauptthread blockiert (dann steht
    das Overlay, animiert aber nicht).
  - Run(Work) fuehrt Work in einem Hintergrund-Thread aus und wartet mit
    laufender Nachrichtenschleife; der Ring dreht sich, Report/SetText aus dem
    Thread kommen ueber den Kontext an (thread-sicher, der Hauptthread holt
    sie ab). Eine Exception im Thread wird im Hauptthread erneut ausgeloest.
    RunAsync kehrt sofort zurueck und ruft OnDone im Hauptthread.
  - Die Lage folgt dem Ziel (Formular und Ziel werden beobachtet, dazu ein
    Abgleich je Animationsschritt); ist das Ziel nicht sichtbar, wird nichts
    gezeigt. Ohne Platz fuer die Karte nur der Ring.
  - Screenreader: Die Karte meldet sich beim Erscheinen (EVENT_SYSTEM_ALERT),
    Rolle Fortschritt, Name = Text, Wert = Prozent, Standardaktion = Abbrechen.

  Grenzen: Die Arbeit in Run darf keine VCL-Controls anfassen (Thread). Wer
  waehrend Run das Overlay selbst freigibt (z.B. aus einem Timer), bekommt
  einen Fehler. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.SyncObjs, System.Generics.Collections, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  PPG.Types, PPG.Render.Intf, PPG.Animation, PPG.Controls.Base, PPG.StyleManager,
  PPG.Overlay;

type
  /// Verbindung der Arbeit in Run zum Overlay (thread-sicher).
  IPPGBusyContext = interface
    ['{6E3B1F2A-8C4D-4E59-9A7B-2D1C5F0E8B34}']
    /// Fortschritt 0..100 (-1 = unbestimmt).
    procedure Report(Progress: Integer); overload;
    procedure Report(Progress: Integer; const Text: string); overload;
    procedure SetText(const Text: string);
    procedure SetDescription(const Text: string);
    /// True, sobald der Benutzer (oder Code) abgebrochen hat.
    function Cancelled: Boolean;
  end;

  TPPGBusyWork = reference to procedure(const Context: IPPGBusyContext);
  /// Nach RunAsync im Hauptthread; Error = nil bei Erfolg (danach freigegeben).
  TPPGBusyDone = reference to procedure(const Error: Exception);

  TPPGBusyOverlay = class;

  /// Karte des Overlays (eigenes Fenster ueber der Abdunklung).
  TPPGBusyCard = class(TPPGCustomControl)
  private
    FOverlay: TPPGBusyOverlay;
    FPPI: Integer;
    FHotCancel: Boolean;
    FDownCancel: Boolean;
    FCompact: Boolean;
    procedure GetLayout(out RingR, TitleR, DescR, CancelR: TRect);
    procedure ApplyRegion;
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure Resize; override;
    procedure WndProc(var Message: TMessage); override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function AccRole: Integer; override;
    function AccName: string; override;
    function AccDescription: string; override;
    function AccValue: string; override;
    function AccDefaultAction: string; override;
    procedure AccDoDefaultAction; override;
  public
    constructor CreateCard(AOverlay: TPPGBusyOverlay);
    function ScalePPI: Integer; override;
    /// Groesse fuer hoechstens MaxWidth x MaxHeight (sonst nur der Ring).
    function MeasureSize(MaxWidth, MaxHeight: Integer): TSize;
    /// Lage des Abbrechen-Knopfs (leer = keiner).
    function CancelRect: TRect;
    property Compact: Boolean read FCompact;
  end;

  TPPGBusyOverlay = class(TComponent)
  private
    FTarget: TWinControl;
    FText: string;
    FDescription: string;
    FCancelCaption: string;
    FProgress: Integer;
    FShowCancel: Boolean;
    FDelay: Integer;
    FMinDisplayTime: Integer;
    FDimOpacity: Byte;
    FPreset: string;
    FStyleManager: TPPGStyleManager;
    FOnCancel: TNotifyEvent;
    FOnShow: TNotifyEvent;
    FOnHide: TNotifyEvent;
    FCount: Integer;
    FCancelled: Boolean;
    FDim: TPPGDimWindow;
    FCard: TPPGBusyCard;
    FBlocking: Boolean;
    FCardShown: Boolean;
    FHidePending: Boolean;
    FShownAt: Cardinal;
    FDelayAnim: TPPGAnimation;
    FHideAnim: TPPGAnimation;
    FSpin: TPPGAnimation;
    FHooked: Boolean;
    FForm: TCustomForm;
    FFormHooked: Boolean;
    FOldCloseQuery: TCloseQueryEvent;
    FWatchedForm: TCustomForm;
    FWatchedTarget: TWinControl;
    FRuns: TObjectList<TObject>;
    FLastRect: TRect;
    procedure SetTarget(const Value: TWinControl);
    procedure SetText(const Value: string);
    procedure SetDescription(const Value: string);
    procedure SetCancelCaption(const Value: string);
    procedure SetProgress(const Value: Integer);
    procedure SetShowCancel(const Value: Boolean);
    procedure SetDelay(const Value: Integer);
    procedure SetMinDisplayTime(const Value: Integer);
    procedure SetDimOpacity(const Value: Byte);
    procedure SetStyleManager(const Value: TPPGStyleManager);
    function GetActive: Boolean;
    function GetVisible: Boolean;
    function TargetForm: TCustomForm;
    function EffectiveTarget: TWinControl;
    procedure EnsureWindows;
    procedure BeginBlocking;
    procedure ShowCard;
    procedure HideWindows;
    procedure Reposition;
    procedure CardChanged;
    procedure DelayStep(Sender: TObject);
    procedure HideStep(Sender: TObject);
    procedure SpinStep(Sender: TObject);
    procedure InputHook(var Msg: TMsg; var Handled: Boolean);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure WatchMessage(Control: TControl; var Message: TMessage);
    procedure Watch;
    procedure Unwatch;
    procedure HookForm;
    procedure UnhookForm;
    procedure PollRuns;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoShow; virtual;
    procedure DoHide; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Sperrt das Ziel; Karte nach Delay. Zaehlend: jedes Show braucht ein Hide.
    procedure Show;
    /// Wie Show, aber sofort sichtbar und synchron gezeichnet.
    procedure ShowNow;
    procedure Hide;
    /// Abbrechen ausloesen (wie der Knopf): Cancelled, Kontext, OnCancel.
    procedure Cancel;
    /// Work im Thread, wartet mit Nachrichtenschleife; Exception kommt hier an.
    procedure Run(const Work: TPPGBusyWork);
    /// Work im Thread, kehrt sofort zurueck; OnDone im Hauptthread.
    procedure RunAsync(const Work: TPPGBusyWork; const OnDone: TPPGBusyDone);
    /// Show-Zaehler > 0 (Eingaben gesperrt).
    property Active: Boolean read GetActive;
    /// Karte wird gezeigt.
    property Visible: Boolean read GetVisible;
    property Cancelled: Boolean read FCancelled;
    property Card: TPPGBusyCard read FCard;
    property DimWindow: TPPGDimWindow read FDim;
  published
    /// Ueberdecktes Control; leer = das Formular (Client-Bereich).
    property Target: TWinControl read FTarget write SetTarget;
    property Text: string read FText write SetText;
    property Description: string read FDescription write SetDescription;
    /// -1 = unbestimmt (drehender Ring), 0..100 = Prozent.
    property Progress: Integer read FProgress write SetProgress default -1;
    property ShowCancel: Boolean read FShowCancel write SetShowCancel default False;
    /// Beschriftung des Knopfs ('' = "Abbrechen").
    property CancelCaption: string read FCancelCaption write SetCancelCaption;
    /// ms bis zur Anzeige (0..60000).
    property Delay: Integer read FDelay write SetDelay default 300;
    /// ms, die das Overlay mindestens steht, wenn es einmal gezeigt wurde.
    property MinDisplayTime: Integer read FMinDisplayTime write SetMinDisplayTime default 500;
    /// Deckkraft der Abdunklung (0 = keine, Eingaben bleiben gesperrt).
    property DimOpacity: Byte read FDimOpacity write SetDimOpacity default 96;
    property Preset: string read FPreset write FPreset;
    property StyleManager: TPPGStyleManager read FStyleManager write SetStyleManager;
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
    /// Karte erscheint bzw. verschwindet.
    property OnShow: TNotifyEvent read FOnShow write FOnShow;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
  end;

implementation

uses
  System.Math, System.UITypes, Winapi.oleacc, PPG.Exceptions, PPG.ErrorHandler, PPG.Lang, PPG.Consts,
  PPG.Appearance, PPG.Tokens, PPG.DpiUtils, PPG.AppHooks, PPG.Feedback;

const
  CardPad = 20;
  RingSize = 40;
  RingWidth = 4;
  CardGap = 12;
  ButtonHeight = 32;
  CardMaxWidth = 360;
  CardMinWidth = 200;
  Margin = 16;
  CompactPad = 12;

var
  GMsgBusyCancel: Cardinal = 0;

type
  TFormAccess = class(TCustomForm);

  TBusyContext = class(TInterfacedObject, IPPGBusyContext)
  private
    FLock: TCriticalSection;
    FCancelled: Integer;
    FProgress: Integer;
    FText: string;
    FDescription: string;
    FHasProgress: Boolean;
    FHasText: Boolean;
    FHasDescription: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Report(Progress: Integer); overload;
    procedure Report(Progress: Integer; const Text: string); overload;
    procedure SetText(const Text: string);
    procedure SetDescription(const Text: string);
    function Cancelled: Boolean;
    procedure DoCancel;
    /// Hauptthread: neue Werte uebernehmen.
    procedure ApplyTo(Overlay: TPPGBusyOverlay);
  end;

  TBusyThread = class(TThread)
  private
    FWork: TPPGBusyWork;
    FContext: IPPGBusyContext;
    FError: TObject;
  protected
    procedure Execute; override;
  public
    constructor Create(const AWork: TPPGBusyWork; const AContext: IPPGBusyContext);
    destructor Destroy; override;
  end;

  TBusyRun = class
  public
    Context: TBusyContext;
    ContextRef: IPPGBusyContext;
    Thread: TBusyThread;
    Async: Boolean;
    OnDone: TPPGBusyDone;
    destructor Destroy; override;
  end;

{ TBusyContext }

constructor TBusyContext.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
end;

destructor TBusyContext.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

procedure TBusyContext.Report(Progress: Integer);
begin
  if Progress < -1 then
    Progress := -1
  else if Progress > 100 then
    Progress := 100;
  FLock.Enter;
  try
    FProgress := Progress;
    FHasProgress := True;
  finally
    FLock.Leave;
  end;
end;

procedure TBusyContext.Report(Progress: Integer; const Text: string);
begin
  Report(Progress);
  SetText(Text);
end;

procedure TBusyContext.SetText(const Text: string);
begin
  FLock.Enter;
  try
    // Eigene Kopie: der Thread darf seinen String danach weiter aendern
    FText := Copy(Text, 1, MaxInt);
    FHasText := True;
  finally
    FLock.Leave;
  end;
end;

procedure TBusyContext.SetDescription(const Text: string);
begin
  FLock.Enter;
  try
    FDescription := Copy(Text, 1, MaxInt);
    FHasDescription := True;
  finally
    FLock.Leave;
  end;
end;

function TBusyContext.Cancelled: Boolean;
begin
  Result := InterlockedCompareExchange(FCancelled, 0, 0) <> 0;
end;

procedure TBusyContext.DoCancel;
begin
  InterlockedExchange(FCancelled, 1);
end;

procedure TBusyContext.ApplyTo(Overlay: TPPGBusyOverlay);
var
  P: Integer;
  T, D: string;
  HasP, HasT, HasD: Boolean;
begin
  FLock.Enter;
  try
    HasP := FHasProgress;
    HasT := FHasText;
    HasD := FHasDescription;
    P := FProgress;
    T := FText;
    D := FDescription;
    FHasProgress := False;
    FHasText := False;
    FHasDescription := False;
  finally
    FLock.Leave;
  end;
  if HasP then
    Overlay.Progress := P;
  if HasT then
    Overlay.Text := T;
  if HasD then
    Overlay.Description := D;
end;

{ TBusyThread }

constructor TBusyThread.Create(const AWork: TPPGBusyWork; const AContext: IPPGBusyContext);
begin
  FWork := AWork;
  FContext := AContext;
  inherited Create(False);
end;

destructor TBusyThread.Destroy;
begin
  // Nicht abgeholte Exception (z.B. Overlay freigegeben) nicht verlieren
  FreeAndNil(FError);
  inherited Destroy;
end;

procedure TBusyThread.Execute;
begin
  try
    FWork(FContext);
  except
    // Grenze: die Exception gehoert dem Hauptthread (Run loest sie dort aus)
    FError := AcquireExceptionObject;
  end;
end;

{ TBusyRun }

destructor TBusyRun.Destroy;
begin
  if Thread <> nil then
  begin
    if Context <> nil then
      Context.DoCancel;
    Thread.WaitFor;
    Thread.Free;
  end;
  ContextRef := nil;
  inherited Destroy;
end;

{ TPPGBusyCard }

constructor TPPGBusyCard.CreateCard(AOverlay: TPPGBusyOverlay);
begin
  inherited Create(nil);
  FOverlay := AOverlay;
  Visible := False;
  TabStop := False;
end;

function TPPGBusyCard.ScalePPI: Integer;
begin
  if FPPI > 0 then
    Result := FPPI
  else
    Result := inherited ScalePPI;
end;

procedure TPPGBusyCard.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP;
  Params.ExStyle := WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE;
  Params.WindowClass.style := Params.WindowClass.style or CS_DROPSHADOW;
  // Ueber der Abdunklung: gehoert ihrem Fenster
  if (FOverlay <> nil) and (FOverlay.FDim <> nil) and FOverlay.FDim.HandleAllocated then
    Params.WndParent := FOverlay.FDim.Handle
  else
    Params.WndParent := Application.Handle;
end;

procedure TPPGBusyCard.CreateWnd;
begin
  inherited CreateWnd;
  if GMsgBusyCancel = 0 then
    GMsgBusyCancel := RegisterWindowMessage('PPGlow.BusyCancel');
  ApplyRegion;
end;

procedure TPPGBusyCard.Resize;
begin
  inherited Resize;
  ApplyRegion;
end;

procedure TPPGBusyCard.ApplyRegion;
var
  D: Integer;
  Rgn: HRGN;
begin
  if not HandleAllocated then
    Exit;
  D := 2 * PPGScale(Tokens.RadiusLarge, ScalePPI);
  if FCompact then
    D := Min(Width, Height);
  Rgn := CreateRoundRectRgn(0, 0, Width + 1, Height + 1, D, D);
  if SetWindowRgn(Handle, Rgn, True) = 0 then
    DeleteObject(Rgn);
end;

procedure TPPGBusyCard.WndProc(var Message: TMessage);
begin
  if (GMsgBusyCancel <> 0) and (Message.Msg = GMsgBusyCancel) then
  begin
    if FOverlay <> nil then
      FOverlay.Cancel;
    Exit;
  end;
  inherited WndProc(Message);
end;

procedure TPPGBusyCard.WMMouseActivate(var Message: TWMMouseActivate);
begin
  Message.Result := MA_NOACTIVATE;
end;

procedure TPPGBusyCard.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHotCancel then
  begin
    FHotCancel := False;
    Invalidate;
  end;
end;

/// Hoehe eines umbrochenen Texts (GDI, wie DrawText beim Zeichnen).
function TextHeight(AFont: TFont; const S: string; AWidth: Integer): Integer;
var
  B: TBitmap;
  R: TRect;
begin
  Result := 0;
  if S = '' then
    Exit;
  B := TBitmap.Create;
  try
    B.Canvas.Font := AFont;
    R := Rect(0, 0, Max(AWidth, 1), 0);
    DrawText(B.Canvas.Handle, PChar(S), Length(S), R,
      DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX or DT_CENTER);
    Result := R.Bottom - R.Top;
  finally
    B.Free;
  end;
end;

function TextWidth(AFont: TFont; const S: string): Integer;
var
  B: TBitmap;
begin
  B := TBitmap.Create;
  try
    B.Canvas.Font := AFont;
    Result := B.Canvas.TextWidth(S);
  finally
    B.Free;
  end;
end;

function CancelText(O: TPPGBusyOverlay): string;
begin
  if O.FCancelled then
    Result := PPGStr(@SPPGBusyCancelling)
  else if O.FCancelCaption <> '' then
    Result := O.FCancelCaption
  else
    Result := PPGStr(@SPPGBusyCancel);
end;

function TitleText(O: TPPGBusyOverlay): string;
begin
  if O.FText <> '' then
    Result := O.FText
  else
    Result := PPGStr(@SPPGBusyWait);
end;

function TPPGBusyCard.MeasureSize(MaxWidth, MaxHeight: Integer): TSize;
var
  PPI, W, H, Inner: Integer;
  Bold: TFont;
begin
  PPI := ScalePPI;
  W := Min(PPGScale(CardMaxWidth, PPI), MaxWidth);
  W := Max(W, PPGScale(CardMinWidth, PPI));
  Inner := W - 2 * PPGScale(CardPad, PPI);
  Bold := TFont.Create;
  try
    Bold.Assign(Font);
    Bold.Style := Bold.Style + [fsBold];
    H := 2 * PPGScale(CardPad, PPI) + PPGScale(RingSize, PPI) + PPGScale(CardGap, PPI) +
      TextHeight(Bold, TitleText(FOverlay), Inner);
  finally
    Bold.Free;
  end;
  if FOverlay.FDescription <> '' then
    Inc(H, PPGScale(CardGap, PPI) div 2 + TextHeight(Font, FOverlay.FDescription, Inner));
  if FOverlay.FShowCancel then
    Inc(H, PPGScale(CardGap, PPI) + PPGScale(ButtonHeight, PPI));
  FCompact := (W > MaxWidth) or (H > MaxHeight);
  if FCompact then
  begin
    W := PPGScale(RingSize + 2 * CompactPad, PPI);
    H := W;
  end;
  Result.cx := W;
  Result.cy := H;
end;

procedure TPPGBusyCard.GetLayout(out RingR, TitleR, DescR, CancelR: TRect);
var
  PPI, Pad, Ring, Y, Inner, BW, H: Integer;
  Bold: TFont;
begin
  PPI := ScalePPI;
  Ring := PPGScale(RingSize, PPI);
  TitleR := Rect(0, 0, 0, 0);
  DescR := TitleR;
  CancelR := TitleR;
  if FCompact then
  begin
    RingR := Rect((Width - Ring) div 2, (Height - Ring) div 2, 0, 0);
    RingR.Right := RingR.Left + Ring;
    RingR.Bottom := RingR.Top + Ring;
    Exit;
  end;
  Pad := PPGScale(CardPad, PPI);
  Inner := Width - 2 * Pad;
  Y := Pad;
  RingR := Rect((Width - Ring) div 2, Y, (Width - Ring) div 2 + Ring, Y + Ring);
  Inc(Y, Ring + PPGScale(CardGap, PPI));
  Bold := TFont.Create;
  try
    Bold.Assign(Font);
    Bold.Style := Bold.Style + [fsBold];
    H := TextHeight(Bold, TitleText(FOverlay), Inner);
  finally
    Bold.Free;
  end;
  TitleR := Rect(Pad, Y, Pad + Inner, Y + H);
  Inc(Y, H);
  if FOverlay.FDescription <> '' then
  begin
    Inc(Y, PPGScale(CardGap, PPI) div 2);
    H := TextHeight(Font, FOverlay.FDescription, Inner);
    DescR := Rect(Pad, Y, Pad + Inner, Y + H);
    Inc(Y, H);
  end;
  if FOverlay.FShowCancel then
  begin
    Inc(Y, PPGScale(CardGap, PPI));
    BW := Max(PPGScale(120, PPI), TextWidth(Font, CancelText(FOverlay)) + PPGScale(32, PPI));
    BW := Min(BW, Inner);
    CancelR := Rect((Width - BW) div 2, Y, (Width - BW) div 2 + BW, Y + PPGScale(ButtonHeight, PPI));
  end;
end;

function TPPGBusyCard.CancelRect: TRect;
var
  R1, R2, R3: TRect;
begin
  GetLayout(R1, R2, R3, Result);
end;

procedure TPPGBusyCard.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  T: TPPGTokens;
  A: TPPGAppearance;
  PPI, Rad, W, RingRad: Integer;
  Fill, Border, TextCol, SecCol, Accent, Track: TColor;
  RingR, TitleR, DescR, CancelR, R: TRect;
  C: TPoint;
  Pts: TArray<TPoint>;
  P, Start, Sweep: Single;
  S: TPPGSurfaceStyle;
  Bold: TFont;
begin
  PPI := ScalePPI;
  T := Tokens;
  A := EffectiveAppearance;
  // Hochkontrast: Tokens und Appearance liefern die Systemfarben
  Fill := T.Layer;
  Border := T.Stroke;
  TextCol := T.TextPrimary;
  SecCol := T.TextSecondary;
  Accent := PPGColorToRGB(A.FocusColor);
  if UseHighContrast then
    Track := T.StrokeDisabled // Sonderfall: Spur deutlich sichtbar
  else
    Track := PPGBlendColor(Fill, TextCol, 0.15);
  Rad := PPGScale(T.RadiusLarge, PPI);
  ACanvas.FillRoundRect(ClientR, 0, Fill, 255);
  if not FCompact then
    ACanvas.FrameRoundRect(ClientR, Rad, 1, Border, 255);
  GetLayout(RingR, TitleR, DescR, CancelR);
  // Ring wie TPPGProgressRing
  W := PPGScale(RingWidth, PPI);
  C := Point((RingR.Left + RingR.Right) div 2, (RingR.Top + RingR.Bottom) div 2);
  RingRad := (RingR.Right - RingR.Left - W) div 2;
  if FOverlay.FProgress >= 0 then
  begin
    R := Rect(C.X - RingRad - W div 2, C.Y - RingRad - W div 2, C.X + RingRad + (W + 1) div 2,
      C.Y + RingRad + (W + 1) div 2);
    ACanvas.FrameEllipse(R, W, Track, 255);
    Start := 0;
    Sweep := 3.6 * FOverlay.FProgress;
  end
  else
  begin
    P := FOverlay.FSpin.Value;
    Start := P * 720;
    Sweep := 30 + 240 * (0.5 - 0.5 * Cos(P * 2 * Pi));
    Start := Start + (270 - Sweep) / 2;
  end;
  if Sweep > 0.5 then
  begin
    PPGArcPoints(C, RingRad, Start, Sweep, Pts);
    ACanvas.DrawPolyline(Pts, W, Accent, 255);
  end;
  if FCompact then
    Exit;
  if FOverlay.FProgress >= 0 then
    ACanvas.DrawText(RingR, IntToStr(FOverlay.FProgress), Font, TextCol,
      DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
  Bold := TFont.Create;
  try
    Bold.Assign(Font);
    Bold.Style := Bold.Style + [fsBold];
    ACanvas.DrawText(TitleR, TitleText(FOverlay), Bold, TextCol,
      DT_WORDBREAK or DT_CENTER or DT_NOPREFIX);
  finally
    Bold.Free;
  end;
  if not IsRectEmpty(DescR) then
    ACanvas.DrawText(DescR, FOverlay.FDescription, Font, SecCol,
      DT_WORDBREAK or DT_CENTER or DT_NOPREFIX);
  if not IsRectEmpty(CancelR) then
  begin
    if FOverlay.FCancelled then
      S := A.Resolve(vsDisabled, PPI, False)
    else if FDownCancel and FHotCancel then
      S := A.Resolve(vsDown, PPI, False)
    else if FHotCancel then
      S := A.Resolve(vsHot, PPI, False)
    else
      S := A.Resolve(vsNormal, PPI, False);
    S.GlowAlpha := 0;
    S.Rounding := Min(S.Rounding, PPGScale(4, PPI));
    Renderer.DrawSurface(ACanvas, CancelR, S);
    ACanvas.DrawText(CancelR, CancelText(FOverlay), Font, S.TextColor,
      DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
  end;
end;

procedure TPPGBusyCard.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and PtInRect(CancelRect, Point(X, Y)) and not FOverlay.FCancelled then
  begin
    FDownCancel := True;
    Invalidate;
  end;
end;

procedure TPPGBusyCard.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Hot: Boolean;
begin
  inherited MouseMove(Shift, X, Y);
  Hot := PtInRect(CancelRect, Point(X, Y)) and not FOverlay.FCancelled;
  if Hot <> FHotCancel then
  begin
    FHotCancel := Hot;
    Invalidate;
  end;
end;

procedure TPPGBusyCard.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  WasDown: Boolean;
begin
  inherited MouseUp(Button, Shift, X, Y);
  WasDown := FDownCancel;
  FDownCancel := False;
  Invalidate;
  if WasDown and (Button = mbLeft) and PtInRect(CancelRect, Point(X, Y)) then
    FOverlay.Cancel;
end;

function TPPGBusyCard.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_PROGRESSBAR;
end;

function TPPGBusyCard.AccName: string;
begin
  Result := TitleText(FOverlay);
end;

function TPPGBusyCard.AccDescription: string;
begin
  Result := FOverlay.FDescription;
end;

function TPPGBusyCard.AccValue: string;
begin
  if FOverlay.FProgress >= 0 then
    Result := IntToStr(FOverlay.FProgress) + ' %'
  else
    Result := '';
end;

function TPPGBusyCard.AccDefaultAction: string;
begin
  if FOverlay.FShowCancel and not FOverlay.FCancelled then
    Result := CancelText(FOverlay)
  else
    Result := '';
end;

procedure TPPGBusyCard.AccDoDefaultAction;
begin
  // Aufruf kommt per COM von aussen: nur posten
  if HandleAllocated and FOverlay.FShowCancel and (GMsgBusyCancel <> 0) then
    PostMessage(Handle, GMsgBusyCancel, 0, 0);
end;

{ TPPGBusyOverlay }

constructor TPPGBusyOverlay.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProgress := -1;
  FDelay := 300;
  FMinDisplayTime := 500;
  FDimOpacity := 96;
  FRuns := TObjectList<TObject>.Create(True);
  FDelayAnim := TPPGAnimation.Create(Self);
  FDelayAnim.OnStep := DelayStep;
  FHideAnim := TPPGAnimation.Create(Self);
  FHideAnim.OnStep := HideStep;
  FSpin := TPPGAnimation.Create(Self);
  FSpin.OnStep := SpinStep;
end;

destructor TPPGBusyOverlay.Destroy;
begin
  FCount := 0;
  if FRuns <> nil then
    FRuns.Clear; // bricht ab und wartet auf die Threads
  if FDelayAnim <> nil then
    FDelayAnim.OnStep := nil;
  if FHideAnim <> nil then
    FHideAnim.OnStep := nil;
  if FSpin <> nil then
    FSpin.OnStep := nil;
  HideWindows;
  FreeAndNil(FDelayAnim);
  FreeAndNil(FHideAnim);
  FreeAndNil(FSpin);
  FreeAndNil(FCard);
  FreeAndNil(FDim);
  FreeAndNil(FRuns);
  inherited Destroy;
end;

procedure TPPGBusyOverlay.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation <> opRemove then
    Exit;
  if AComponent = FTarget then
  begin
    Unwatch;
    FTarget := nil;
    if FCount > 0 then
    begin
      Watch;
      Reposition;
    end;
  end;
  if AComponent = FStyleManager then
  begin
    FStyleManager := nil;
    if FCard <> nil then
      FCard.StyleManager := nil;
  end;
  if AComponent = FWatchedForm then
    FWatchedForm := nil;
  if AComponent = FWatchedTarget then
    FWatchedTarget := nil;
  if AComponent = FForm then
  begin
    FFormHooked := False;
    FForm := nil;
  end;
end;

function TPPGBusyOverlay.TargetForm: TCustomForm;
begin
  if FTarget <> nil then
    Result := GetParentForm(FTarget)
  else if Owner is TCustomForm then
    Result := TCustomForm(Owner)
  else
    Result := nil;
end;

function TPPGBusyOverlay.EffectiveTarget: TWinControl;
begin
  if FTarget <> nil then
    Result := FTarget
  else
    Result := TargetForm;
end;

function TPPGBusyOverlay.GetActive: Boolean;
begin
  Result := FCount > 0;
end;

function TPPGBusyOverlay.GetVisible: Boolean;
begin
  Result := FCardShown and (FCard <> nil) and FCard.HandleAllocated and
    IsWindowVisible(FCard.Handle);
end;

procedure TPPGBusyOverlay.SetTarget(const Value: TWinControl);
begin
  if FTarget = Value then
    Exit;
  if FCount > 0 then
    Unwatch;
  FTarget := Value;
  if Value <> nil then
    Value.FreeNotification(Self);
  if FCount > 0 then
  begin
    Watch;
    Reposition;
  end;
end;

procedure TPPGBusyOverlay.SetText(const Value: string);
begin
  if FText = Value then
    Exit;
  FText := Value;
  CardChanged;
  if Visible then
    FCard.NotifyAccessibility(EVENT_OBJECT_NAMECHANGE);
end;

procedure TPPGBusyOverlay.SetDescription(const Value: string);
begin
  if FDescription = Value then
    Exit;
  FDescription := Value;
  CardChanged;
end;

procedure TPPGBusyOverlay.SetCancelCaption(const Value: string);
begin
  if FCancelCaption = Value then
    Exit;
  FCancelCaption := Value;
  CardChanged;
end;

procedure TPPGBusyOverlay.SetProgress(const Value: Integer);
begin
  if (Value < -1) or (Value > 100) then
    raise EPPGPropertyError.CreateRange(Self, 'Progress', Value, -1, 100);
  if FProgress = Value then
    Exit;
  FProgress := Value;
  if FCard <> nil then
    FCard.Invalidate;
  if Visible then
    FCard.NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
end;

procedure TPPGBusyOverlay.SetShowCancel(const Value: Boolean);
begin
  if FShowCancel = Value then
    Exit;
  FShowCancel := Value;
  CardChanged;
end;

procedure TPPGBusyOverlay.SetDelay(const Value: Integer);
begin
  FDelay := PPGCheckRange(Self, 'Delay', Value, 0, 60000);
end;

procedure TPPGBusyOverlay.SetMinDisplayTime(const Value: Integer);
begin
  FMinDisplayTime := PPGCheckRange(Self, 'MinDisplayTime', Value, 0, 60000);
end;

procedure TPPGBusyOverlay.SetDimOpacity(const Value: Byte);
begin
  FDimOpacity := Value;
  if (FDim <> nil) and FCardShown then
    FDim.Opacity := Value;
end;

procedure TPPGBusyOverlay.SetStyleManager(const Value: TPPGStyleManager);
begin
  if FStyleManager = Value then
    Exit;
  FStyleManager := Value;
  if Value <> nil then
    Value.FreeNotification(Self);
  if FCard <> nil then
    FCard.StyleManager := Value;
end;

procedure TPPGBusyOverlay.CardChanged;
begin
  // Groesse haengt am Text: neu messen und mittig setzen
  if FCardShown then
  begin
    FLastRect := Rect(0, 0, 0, 0);
    Reposition;
  end;
  if FCard <> nil then
    FCard.Invalidate;
end;

procedure TPPGBusyOverlay.EnsureWindows;
var
  F: TCustomForm;
begin
  F := TargetForm;
  if FDim = nil then
    FDim := TPPGDimWindow.Create(nil);
  FDim.SetOwnerForm(F);
  FDim.EnsureOwner;
  if FCard = nil then
    FCard := TPPGBusyCard.CreateCard(Self);
  if FPreset <> '' then
    FCard.Preset := FPreset;
  if FStyleManager <> nil then
    FCard.StyleManager := FStyleManager;
  if F <> nil then
  begin
    FCard.Font := F.Font;
    FCard.FPPI := PPGControlPPI(F);
  end;
end;

procedure TPPGBusyOverlay.Watch;
var
  F: TCustomForm;
begin
  F := TargetForm;
  if (F <> nil) and (FWatchedForm = nil) then
  begin
    FWatchedForm := F;
    F.FreeNotification(Self);
    PPGWatchControl(F, WatchMessage);
  end;
  if (FTarget <> nil) and (FTarget <> F) and (FWatchedTarget = nil) then
  begin
    FWatchedTarget := FTarget;
    PPGWatchControl(FTarget, WatchMessage);
  end;
end;

procedure TPPGBusyOverlay.Unwatch;
begin
  if (FWatchedForm <> nil) and not (csDestroying in FWatchedForm.ComponentState) then
    PPGUnwatchControl(FWatchedForm, WatchMessage);
  FWatchedForm := nil;
  if (FWatchedTarget <> nil) and not (csDestroying in FWatchedTarget.ComponentState) then
    PPGUnwatchControl(FWatchedTarget, WatchMessage);
  FWatchedTarget := nil;
end;

procedure TPPGBusyOverlay.WatchMessage(Control: TControl; var Message: TMessage);
begin
  case Message.Msg of
    WM_WINDOWPOSCHANGED, WM_SIZE, WM_MOVE, CM_SHOWINGCHANGED, WM_SHOWWINDOW:
      if FCount > 0 then
        Reposition;
  end;
end;

procedure TPPGBusyOverlay.HookForm;
var
  Q: TCloseQueryEvent;
begin
  if FFormHooked then
    Exit;
  FForm := TargetForm;
  if FForm = nil then
    Exit;
  FForm.FreeNotification(Self);
  FOldCloseQuery := TFormAccess(FForm).OnCloseQuery;
  Q := FormCloseQuery;
  TFormAccess(FForm).OnCloseQuery := Q;
  FFormHooked := True;
end;

procedure TPPGBusyOverlay.UnhookForm;
var
  Q: TCloseQueryEvent;
begin
  if not FFormHooked then
    Exit;
  FFormHooked := False;
  Q := FormCloseQuery;
  if (FForm <> nil) and (TMethod(TFormAccess(FForm).OnCloseQuery).Code = TMethod(Q).Code) and
    (TMethod(TFormAccess(FForm).OnCloseQuery).Data = TMethod(Q).Data) then
    TFormAccess(FForm).OnCloseQuery := FOldCloseQuery;
  FOldCloseQuery := nil;
  FForm := nil;
end;

procedure TPPGBusyOverlay.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Assigned(FOldCloseQuery) then
    FOldCloseQuery(Sender, CanClose);
  // Waehrend der Arbeit bleibt das Formular offen
  if (FCount > 0) or (FRuns.Count > 0) then
    CanClose := False;
end;

procedure TPPGBusyOverlay.InputHook(var Msg: TMsg; var Handled: Boolean);
var
  T: TWinControl;
begin
  if FCount = 0 then
    Exit;
  T := EffectiveTarget;
  if (Msg.message >= WM_KEYFIRST) and (Msg.message <= WM_KEYLAST) then
  begin
    if PPGWindowInTarget(T, Msg.hwnd) then
    begin
      if (Msg.message = WM_KEYDOWN) and (Msg.wParam = VK_ESCAPE) and FShowCancel then
        Cancel;
      Handled := True;
    end;
  end
  else if (Msg.message >= WM_MOUSEFIRST) and (Msg.message <= WM_MOUSELAST) then
  begin
    // z.B. Mausrad an das fokussierte Control oder eine noch gehaltene Maus
    if PPGWindowInTarget(T, Msg.hwnd) then
      Handled := True;
  end;
end;

procedure TPPGBusyOverlay.BeginBlocking;
begin
  if FBlocking then
    Exit;
  FBlocking := True;
  EnsureWindows;
  FDim.Opacity := 1;
  if not FHooked then
  begin
    PPGAddMessageHook(InputHook);
    FHooked := True;
  end;
  HookForm;
  Watch;
  FLastRect := Rect(0, 0, 0, 0);
  Reposition;
  // Ring und Lageabgleich laufen ueber den gemeinsamen Animator
  FSpin.StartLoop(2000);
end;

procedure TPPGBusyOverlay.Show;
begin
  Inc(FCount);
  if FCount > 1 then
    Exit;
  FCancelled := False;
  if FHidePending then
  begin
    // Noch sichtbar (MinDisplayTime): einfach stehen lassen
    FHidePending := False;
    FHideAnim.Stop;
    Exit;
  end;
  BeginBlocking;
  if FDelay = 0 then
    ShowCard
  else
  begin
    FDelayAnim.Jump(0);
    FDelayAnim.AnimateTo(1, FDelay, ekLinear);
  end;
end;

procedure TPPGBusyOverlay.ShowNow;
begin
  Show;
  FDelayAnim.Stop;
  if not FCardShown then
    ShowCard;
  // Synchron zeichnen: der Aufrufer blockiert danach womoeglich den Hauptthread
  if (FDim <> nil) and FDim.HandleAllocated then
    UpdateWindow(FDim.Handle);
  if (FCard <> nil) and FCard.HandleAllocated then
    UpdateWindow(FCard.Handle);
end;

procedure TPPGBusyOverlay.ShowCard;
begin
  if FCount = 0 then
    Exit;
  EnsureWindows;
  FCardShown := True;
  FShownAt := GetTickCount;
  FDim.Opacity := FDimOpacity;
  FLastRect := Rect(0, 0, 0, 0);
  Reposition;
  if Visible then
    FCard.NotifyAccessibility(EVENT_SYSTEM_ALERT);
  DoShow;
end;

procedure TPPGBusyOverlay.Hide;
var
  Elapsed: Cardinal;
begin
  if FCount = 0 then
    Exit;
  Dec(FCount);
  if FCount > 0 then
    Exit;
  FDelayAnim.Stop;
  if FCardShown and (FMinDisplayTime > 0) then
  begin
    Elapsed := GetTickCount - FShownAt;
    if Elapsed < Cardinal(FMinDisplayTime) then
    begin
      FHidePending := True;
      FHideAnim.Jump(0);
      FHideAnim.AnimateTo(1, Cardinal(FMinDisplayTime) - Elapsed, ekLinear);
      Exit;
    end;
  end;
  HideWindows;
end;

procedure TPPGBusyOverlay.HideWindows;
var
  WasShown: Boolean;
begin
  WasShown := FCardShown;
  FCardShown := False;
  FHidePending := False;
  FBlocking := False;
  if FSpin <> nil then
    FSpin.Stop;
  if FHideAnim <> nil then
    FHideAnim.Stop;
  if (FCard <> nil) and FCard.HandleAllocated then
    ShowWindow(FCard.Handle, SW_HIDE);
  if FDim <> nil then
    FDim.HideWindow;
  if FHooked then
  begin
    PPGRemoveMessageHook(InputHook);
    FHooked := False;
  end;
  UnhookForm;
  Unwatch;
  if WasShown and not (csDestroying in ComponentState) then
    DoHide;
end;

procedure TPPGBusyOverlay.Reposition;
var
  R: TRect;
  Sz: TSize;
  X, Y: Integer;
begin
  if not FBlocking or (FDim = nil) then
    Exit;
  R := PPGOverlayRect(EffectiveTarget);
  if IsRectEmpty(R) then
  begin
    // Ziel gerade nicht zu sehen (anderer Reiter, minimiert): nichts zeigen
    if (FCard <> nil) and FCard.HandleAllocated then
      ShowWindow(FCard.Handle, SW_HIDE);
    FDim.HideWindow;
    FLastRect := R;
    Exit;
  end;
  if EqualRect(R, FLastRect) and FDim.IsShown and
    (not FCardShown or ((FCard <> nil) and FCard.HandleAllocated and IsWindowVisible(FCard.Handle))) then
    Exit;
  FLastRect := R;
  FDim.EnsureOwner;
  FDim.ShowAt(R);
  if not FCardShown or (FCard = nil) then
    Exit;
  // Karte gehoert dem Fenster der Abdunklung (neu anlegen, wenn es neu ist)
  if FCard.HandleAllocated and (GetWindowLongPtr(FCard.Handle, GWLP_HWNDPARENT) <> LONG_PTR(FDim.Handle)) then
    FCard.DestroyHandle;
  Sz := FCard.MeasureSize(R.Right - R.Left - 2 * PPGScale(Margin, FCard.ScalePPI),
    R.Bottom - R.Top - 2 * PPGScale(Margin, FCard.ScalePPI));
  X := (R.Left + R.Right - Sz.cx) div 2;
  Y := (R.Top + R.Bottom - Sz.cy) div 2;
  FCard.HandleNeeded;
  FCard.SetBounds(X, Y, Sz.cx, Sz.cy);
  FCard.ApplyRegion;
  SetWindowPos(FCard.Handle, HWND_TOP, X, Y, Sz.cx, Sz.cy, SWP_NOACTIVATE or SWP_SHOWWINDOW);
  FCard.Invalidate;
end;

procedure TPPGBusyOverlay.DelayStep(Sender: TObject);
begin
  if not FDelayAnim.Running and (FDelayAnim.Value >= 1) and (FCount > 0) and not FCardShown then
    ShowCard;
end;

procedure TPPGBusyOverlay.HideStep(Sender: TObject);
begin
  if not FHideAnim.Running and FHidePending then
  begin
    FHidePending := False;
    if FCount = 0 then
      HideWindows;
  end;
end;

procedure TPPGBusyOverlay.SpinStep(Sender: TObject);
begin
  PollRuns;
  if not FBlocking then
    Exit;
  Reposition;
  if FCardShown and (FProgress < 0) and (FCard <> nil) then
    FCard.Invalidate;
end;

procedure TPPGBusyOverlay.Cancel;
var
  I: Integer;
begin
  if FCancelled then
    Exit;
  FCancelled := True;
  for I := 0 to FRuns.Count - 1 do
    TBusyRun(FRuns[I]).Context.DoCancel;
  if FCard <> nil then
  begin
    FCard.FHotCancel := False;
    FCard.FDownCancel := False;
    FCard.Invalidate;
  end;
  if Assigned(FOnCancel) then
    FOnCancel(Self);
end;

procedure TPPGBusyOverlay.DoShow;
begin
  if Assigned(FOnShow) then
    FOnShow(Self);
end;

procedure TPPGBusyOverlay.DoHide;
begin
  if Assigned(FOnHide) then
    FOnHide(Self);
end;

procedure TPPGBusyOverlay.Run(const Work: TPPGBusyWork);
var
  Run: TBusyRun;
  Err: TObject;
  H: THandle;
begin
  if not Assigned(Work) then
    Exit;
  Run := TBusyRun.Create;
  Run.Context := TBusyContext.Create;
  Run.ContextRef := Run.Context;
  FRuns.Add(Run);
  Show;
  try
    Run.Thread := TBusyThread.Create(Work, Run.ContextRef);
    if FCancelled then
      Run.Context.DoCancel;
    while not Run.Thread.Finished do
    begin
      H := Run.Thread.Handle;
      MsgWaitForMultipleObjects(1, H, False, 50, QS_ALLINPUT);
      Application.ProcessMessages;
      Run.Context.ApplyTo(Self);
      if Application.Terminated then
        Run.Context.DoCancel;
    end;
    Run.Thread.WaitFor;
    Run.Context.ApplyTo(Self);
    Err := Run.Thread.FError;
    Run.Thread.FError := nil;
  finally
    FRuns.Remove(Run);
    Hide;
  end;
  if Err <> nil then
    raise Err;
end;

procedure TPPGBusyOverlay.RunAsync(const Work: TPPGBusyWork; const OnDone: TPPGBusyDone);
var
  Run: TBusyRun;
begin
  if not Assigned(Work) then
    Exit;
  Run := TBusyRun.Create;
  Run.Context := TBusyContext.Create;
  Run.ContextRef := Run.Context;
  Run.Async := True;
  Run.OnDone := OnDone;
  FRuns.Add(Run);
  Show;
  Run.Thread := TBusyThread.Create(Work, Run.ContextRef);
  if FCancelled then
    Run.Context.DoCancel;
end;

procedure TPPGBusyOverlay.PollRuns;
var
  I: Integer;
  Run: TBusyRun;
  Err: TObject;
  Done: TPPGBusyDone;
begin
  for I := FRuns.Count - 1 downto 0 do
  begin
    if I >= FRuns.Count then
      Continue;
    Run := TBusyRun(FRuns[I]);
    Run.Context.ApplyTo(Self);
    if not Run.Async or (Run.Thread = nil) or not Run.Thread.Finished then
      Continue;
    Run.Thread.WaitFor;
    Run.Context.ApplyTo(Self);
    Err := Run.Thread.FError;
    Run.Thread.FError := nil;
    Done := Run.OnDone;
    FRuns.Remove(Run);
    Hide;
    try
      if Assigned(Done) then
      begin
        if Err is Exception then
          Done(Exception(Err))
        else
          Done(nil);
      end;
    finally
      Err.Free;
    end;
  end;
end;

end.
