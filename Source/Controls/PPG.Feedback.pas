unit PPG.Feedback;

{ Rueckmelde-Controls (Phase 7a): TPPGBadge, TPPGProgressRing, TPPGInfoBar.

  - TPPGBadge: Punkt, Zahl (99+) oder kurzer Text auf Akzent- bzw.
    Signalfarbe (Tokens; Dark Mode automatisch). Die Akzent-Plakette liest
    Appearance.Checked (Flaeche/Verlauf, Rahmen, Text, Schriftstil),
    BorderWidth und Rounding (Pille als Obergrenze).
  - TPPGProgressRing: bestimmt (Bogen 0-100 %) oder unbestimmt (rotierender
    Bogen mit wechselnder Laenge). Die Endlosschleife laeuft ueber den
    gemeinsamen Animator und nur, solange das Control sichtbar ist; ohne
    Animationen steht ein Viertelbogen.
  - TPPGInfoBar: Hinweisleiste Info/Erfolg/Warnung/Fehler mit Symbol, Titel,
    Text (Markup), optionalem Aktions-Button und Schliessen-Knopf. Button und
    Knopf sind gezeichnet (keine Kind-Fenster); Tastatur: Pfeile wechseln,
    Enter/Leertaste loest aus, Esc schliesst. Screenreader: Rolle Alarm,
    Meldung beim Oeffnen. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Animation, PPG.Tokens, PPG.Render.Intf, PPG.Markup, PPG.Controls.Base, PPG.ElementStyle;

type
  TPPGSeverity = (psInformational, psSuccess, psWarning, psError);
  TPPGBadgeKind = (bkNumber, bkDot, bkText);
  TPPGBadgeSeverity = (bsvAccent, bsvSuccess, bsvWarning, bsvError, bsvNeutral);

  TPPGCustomBadge = class(TPPGCustomControl)
  private
    FKind: TPPGBadgeKind;
    FValue: Integer;
    FMaxValue: Integer;
    FBadgeColor: TPPGBadgeSeverity;
    procedure SetKind(const Value: TPPGBadgeKind);
    procedure SetValue(const Value: Integer);
    procedure SetMaxValue(const Value: Integer);
    procedure SetBadgeColor(const Value: TPPGBadgeSeverity);
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  protected
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    function CalcAutoSize(out AWidth, AHeight: Integer): Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function AccRole: Integer; override;
    function AccName: string; override;
    function AccDefaultAction: string; override;
    property Kind: TPPGBadgeKind read FKind write SetKind default bkNumber;
    property Value: Integer read FValue write SetValue default 0;
    /// Groessere Zahlen erscheinen als "99+" (0 = ohne Grenze).
    property MaxValue: Integer read FMaxValue write SetMaxValue default 99;
    property Severity: TPPGBadgeSeverity read FBadgeColor write SetBadgeColor default bsvAccent;
  public
    constructor Create(AOwner: TComponent); override;
    /// Angezeigter Text ("" beim Punkt).
    function DisplayText: string;
    function FillColor: TColor;
    /// True, wenn Flaeche, Rahmen, Text und Schriftstil aus Appearance.Checked kommen.
    function UsesChecked: Boolean;
  end;

  TPPGBadge = class(TPPGCustomBadge)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property HighContrastSupport;
    property Kind;
    property Value;
    property MaxValue;
    property Severity;
    property Caption;
    property Align;
    property Anchors;
    property AutoSize default True;
    property Enabled;
    property Font;
    property ParentFont;
    property ParentShowHint;
    property ShowHint;
    property Visible;
    property Touch;
    property OnGesture;
    property OnClick;
    property OnMouseDown;
    property OnMouseUp;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnDblClick;
    property OnMouseMove;
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
    property Color;
    property ParentColor;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
    property Action;
  end;

  TPPGCustomProgressRing = class(TPPGCustomControl)
  private
    FIndeterminate: Boolean;
    FMin: Integer;
    FMax: Integer;
    FValue: Integer;
    FThickness: Integer;
    FShowTrack: Boolean;
    FLoop: TPPGAnimation;
    procedure SetIndeterminate(const Value: Boolean);
    procedure SetMin(const Value: Integer);
    procedure SetMax(const Value: Integer);
    procedure SetValue(const Value: Integer);
    procedure SetThickness(const Value: Integer);
    procedure SetShowTrack(const Value: Boolean);
    procedure LoopStep(Sender: TObject);
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
  protected
    procedure Loaded; override;
    procedure CreateWnd; override;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    procedure DestroyWnd; override;
    procedure UpdateVisualState(Animate: Boolean = True); override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function AccRole: Integer; override;
    function AccState: Integer; override;
    function AccValue: string; override;
    property Indeterminate: Boolean read FIndeterminate write SetIndeterminate default True;
    /// Wertebereich (Audit 5c, wie ProgressBar); Value liegt in Min..Max.
    property Min: Integer read FMin write SetMin default 0;
    property Max: Integer read FMax write SetMax default 100;
    property Value: Integer read FValue write SetValue default 0;
    /// Strichstaerke in logischen px (0 = aus der Groesse).
    property Thickness: Integer read FThickness write SetThickness default 0;
    property ShowTrack: Boolean read FShowTrack write SetShowTrack default True;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure UpdateLoop;
    function Spinning: Boolean;
  end;

  TPPGProgressRing = class(TPPGCustomProgressRing)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighContrastSupport;
    property Indeterminate;
    property Min;
    property Max;
    property Value;
    property Thickness;
    property ShowTrack;
    property Align;
    property Anchors;
    property Enabled;
    property ParentShowHint;
    property ShowHint;
    property Visible;
    property Touch;
    property OnGesture;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnClick;
    property OnDblClick;
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
    property Color;
    property ParentColor;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

  TPPGInfoBarPart = (ipNone, ipAction, ipClose);
  TPPGInfoBarClosingEvent = procedure(Sender: TObject; var AllowClose: Boolean) of object;

  TPPGCustomInfoBar = class(TPPGCustomControl)
  private
    FBarStyle: TPPGElementStyle;
    FSeverity: TPPGSeverity;
    FTitle: string;
    FMessage: string;
    FIsOpen: Boolean;
    FIsClosable: Boolean;
    FActionCaption: string;
    FMarkup: TPPGMarkupLayout;
    FOpenAnim: TPPGAnimation;   // 1 = offen, 0 = zu (Hoehe animiert)
    FFullH: Integer;             // volle Hoehe waehrend der Animation
    // Audit 8D: volle Hoehe je (Breite, Text, PPI); Schrift und Stil leeren sie
    FHeightValid: Boolean;
    FHeightW: Integer;
    FHeightPPI: Integer;
    FHeightText: string;
    FHeightFull: Integer;
    FHotPart: TPPGInfoBarPart;
    FDownPart: TPPGInfoBarPart;
    FFocusPart: TPPGInfoBarPart;
    FOnActionClick: TNotifyEvent;
    FOnClosing: TPPGInfoBarClosingEvent;
    FOnClose: TNotifyEvent;
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
    procedure SetBarStyle(const Value: TPPGElementStyle);
    procedure BarStyleChanged(Sender: TObject);
    procedure SetSeverity(const Value: TPPGSeverity);
    procedure SetTitle(const Value: string);
    procedure SetMessage(const Value: string);
    procedure SetIsOpen(const Value: Boolean);
    procedure SetIsClosable(const Value: Boolean);
    procedure SetActionCaption(const Value: string);
    function MarkupText: string;
    procedure GetLayout(out IconR, TextR, ActionR, CloseR: TRect);
    function PartAt(X, Y: Integer): TPPGInfoBarPart;
    procedure TextChanged;
    procedure OpenStep(Sender: TObject);
    function CanAnimateOpen: Boolean;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    procedure WndProc(var Message: TMessage); override;
    procedure Resize; override;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    function CalcAutoSize(out AWidth, AHeight: Integer): Boolean; override;
    function AutoSizeWidth: Boolean; override;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    /// Hoehe fuer eine Breite der Textspalte.
    function HeightForTextWidth(TextWidth: Integer): Integer;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoEnter; override;
    procedure ActivatePart(Part: TPPGInfoBarPart); virtual;
    function AccRole: Integer; override;
    function AccName: string; override;
    function AccDefaultAction: string; override;
    procedure AccDoDefaultAction; override;
    property Severity: TPPGSeverity read FSeverity write SetSeverity default psInformational;
    property Title: string read FTitle write SetTitle;
    property Message: string read FMessage write SetMessage;
    property Open: Boolean read FIsOpen write SetIsOpen default True;
    property ShowCloseButton: Boolean read FIsClosable write SetIsClosable default True;
    property ActionCaption: string read FActionCaption write SetActionCaption;
    property OnActionClick: TNotifyEvent read FOnActionClick write FOnActionClick;
    property OnClosing: TPPGInfoBarClosingEvent read FOnClosing write FOnClosing;
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
    /// Leiste: Flaeche, Rand, Text und Schrift (sonst aus der Signalfarbe getoent).
    property Style: TPPGElementStyle read FBarStyle write SetBarStyle;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Schliessen wie per Knopf (OnClosing, dann OnClose).
    function CloseByUser: Boolean;
    function SeverityColor: TColor;
    function PartRect(Part: TPPGInfoBarPart): TRect;
    property HotPart: TPPGInfoBarPart read FHotPart;
    property FocusPart: TPPGInfoBarPart read FFocusPart;
  end;

  TPPGInfoBar = class(TPPGCustomInfoBar)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighContrastSupport;
    property Severity;
    property Title;
    property Message;
    property Open;
    property ShowCloseButton;
    property Style;
    property ActionCaption;
    property Align;
    property Anchors;
    property AutoSize default True;
    property BiDiMode;
    property Constraints;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentFont;
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
    property OnActionClick;
    property OnClose;
    property OnClosing;
    property OnEnter;
    property OnExit;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseActivate;
    property OnContextPopup;
    property DragMode;
    property DragCursor;
    property OnDragDrop;
    property OnDragOver;
    property OnStartDrag;
    property OnEndDrag;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property Color;
    property ParentColor;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

/// Signalfarbe einer Schwere aus den Tokens.
function PPGSeverityColor(const T: TPPGTokens; Severity: TPPGSeverity): TColor;
/// Punkte eines Kreisbogens (Winkel in Grad, 0 = oben, im Uhrzeigersinn).
procedure PPGArcPoints(const Center: TPoint; Radius: Integer; StartDeg, SweepDeg: Single;
  var Points: TArray<TPoint>);

implementation

uses
  PPG.Lang,
  System.SysUtils, System.Math, Winapi.oleacc,
  PPG.Consts, PPG.Exceptions, PPG.Appearance, PPG.DpiUtils, PPG.IconFont, PPG.ItemPainter,
  PPG.Render.Registry, PPG.Render.Gdi, PPG.Render.Shapes;

var
  GMsgInfoAction: Cardinal = 0;

function PPGSeverityColor(const T: TPPGTokens; Severity: TPPGSeverity): TColor;
begin
  case Severity of
    psSuccess: Result := T.Success;
    psWarning: Result := T.Warning;
    psError: Result := T.Danger;
  else
    Result := T.Accent;
  end;
end;

procedure PPGArcPoints(const Center: TPoint; Radius: Integer; StartDeg, SweepDeg: Single;
  var Points: TArray<TPoint>);
begin
  PPGShapeArcPoints(Center, Radius, StartDeg, SweepDeg, Points);
end;

{ TPPGCustomBadge }

constructor TPPGCustomBadge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption];
  FMaxValue := 99;
  Width := 24;
  Height := 18;
  AutoSize := True;
end;

function TPPGCustomBadge.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGCustomBadge.IsDown: Boolean;
begin
  Result := False;
end;

function TPPGCustomBadge.DisplayText: string;
begin
  case FKind of
    bkDot: Result := '';
    bkText: Result := Caption;
  else
    if (FMaxValue > 0) and (FValue > FMaxValue) then
      Result := IntToStr(FMaxValue) + '+'
    else
      Result := IntToStr(FValue);
  end;
end;

function TPPGCustomBadge.UsesChecked: Boolean;
begin
  // Akzent-Plakette in einem flachen Preset: Flaeche, Rahmen, Text und
  // Schriftstil aus Appearance.Checked (wie die ProgressBar)
  Result := (FBadgeColor = bsvAccent) and Enabled and
    not UseHighContrast and
    PPGCheckedIsAccent(EffectiveAppearance);
end;

function TPPGCustomBadge.FillColor: TColor;
var
  T: TPPGTokens;
begin
  T := Tokens;
  if UseHighContrast then
    Exit(T.Accent); // eine Systemfarbe (clHighlight) fuer alle Arten
  case FBadgeColor of
    bsvSuccess: Result := T.Success;
    bsvWarning: Result := T.Warning;
    bsvError: Result := T.Danger;
    bsvNeutral: Result := T.TextSecondary;
  else
    Result := PPGAccentColor(EffectiveAppearance);
  end;
  // Deaktiviert: entsaettigt und abgeblendet (gemeinsamer Helfer, Audit 7e)
  if not Enabled then
    Result := PPGDisabledColor(Result, PPGColorToRGB(GetBackgroundColor));
end;

function TPPGCustomBadge.CalcAutoSize(out AWidth, AHeight: Integer): Boolean;
var
  S: TSize;
  F, Temp: TFont;
begin
  if FKind = bkDot then
  begin
    AWidth := PPGScale(8, ScalePPI);
    AHeight := AWidth;
  end
  else
  begin
    Temp := nil;
    try
      if UsesChecked then
        F := PPGStyledFont(Font, EffectiveAppearance.Checked.FontStyle, Temp)
      else
        F := Font;
      S := PPGMeasureTextNoCanvas(DisplayText, F, 0, False);
    finally
      Temp.Free;
    end;
    AHeight := S.cy + 2 * PPGScale(1, ScalePPI);
    AWidth := S.cx + 2 * PPGScale(6, ScalePPI);
    if AWidth < AHeight then
      AWidth := AHeight;
  end;
  Result := True;
end;

procedure TPPGCustomBadge.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  A: TPPGAppearance;
  R: TRect;
  D, Rad, BW: Integer;
  F, F2, Border, Txt: TColor;
  Styled: Boolean;
  Fnt, Temp: TFont;
begin
  A := EffectiveAppearance;
  Styled := UsesChecked;
  F := FillColor;
  F2 := F;
  Border := F;
  Txt := PPGContrastTextColor(F);
  if Styled then
  begin
    F2 := PPGColorToRGB(A.Checked.ColorTo);
    Border := PPGColorToRGB(A.Checked.BorderColor);
    Txt := PPGReadableTextColor(PPGColorToRGB(A.Checked.TextColor), F);
  end
  else if not Enabled then
    Txt := PPGBlendColor(Txt, F, 0.3);
  R := ClientR;
  if FKind = bkDot then
  begin
    D := ClientR.Right - ClientR.Left;
    if ClientR.Bottom - ClientR.Top < D then
      D := ClientR.Bottom - ClientR.Top;
    R := Rect((ClientR.Left + ClientR.Right - D) div 2, (ClientR.Top + ClientR.Bottom - D) div 2,
      (ClientR.Left + ClientR.Right + D) div 2, (ClientR.Top + ClientR.Bottom + D) div 2);
  end;
  if IsRectEmpty(R) then
    Exit;
  // Rundung: Appearance.Rounding dreifach (Plaketten sind etwa halb so hoch
  // wie Buttons), gedeckelt auf die Pillenform; so bleiben die Presets
  // (Rounding 3..6) Pillen, 0 ergibt eckige Plaketten
  Rad := PPGCapRounding(R, PPGScale(A.Rounding, ScalePPI) * 3);
  if F2 = F then
    ACanvas.FillRoundRect(R, Rad, F, 255)
  else
  begin
    ACanvas.PushClipRoundRect(R, Rad);
    try
      ACanvas.FillGradientRect(R, F, F2, A.Checked.GradientDirection, 255);
    finally
      ACanvas.PopClip;
    end;
  end;
  BW := PPGScale(A.BorderWidth, ScalePPI);
  if (BW > 0) and (Border <> F) then
    ACanvas.FrameRoundRect(R, Rad, BW, Border, 255);
  if FKind = bkDot then
    Exit;
  Temp := nil;
  try
    if Styled then
      Fnt := PPGStyledFont(Font, A.Checked.FontStyle, Temp)
    else
      Fnt := Font;
    ACanvas.DrawText(R, DisplayText, Fnt, Txt, DT_SINGLELINE or DT_CENTER or DT_VCENTER or
      DT_NOPREFIX);
  finally
    Temp.Free;
  end;
end;

procedure TPPGCustomBadge.SetKind(const Value: TPPGBadgeKind);
begin
  if FKind <> Value then
  begin
    FKind := Value;
    RequestAutoSize;
    Invalidate;
  end;
end;

procedure TPPGCustomBadge.SetValue(const Value: Integer);
begin
  if FValue <> Value then
  begin
    FValue := Value;
    RequestAutoSize;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_NAMECHANGE);
  end;
end;

procedure TPPGCustomBadge.SetMaxValue(const Value: Integer);
begin
  if FMaxValue = Value then
    Exit;
  FMaxValue := PPGCheckRange(Self, 'MaxValue', Value, 0, MaxInt);
  RequestAutoSize;
  Invalidate;
end;

procedure TPPGCustomBadge.SetBadgeColor(const Value: TPPGBadgeSeverity);
begin
  if FBadgeColor <> Value then
  begin
    FBadgeColor := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomBadge.CMTextChanged(var Message: TMessage);
begin
  inherited;
  if FKind = bkText then
  begin
    RequestAutoSize;
    Invalidate;
  end;
end;

function TPPGCustomBadge.AccRole: Integer;
begin
  // Audit 7d: mit OnClick (auch ueber eine Action) ein Button, sonst Text
  if Assigned(OnClick) then
    Result := ROLE_SYSTEM_PUSHBUTTON
  else
    Result := ROLE_SYSTEM_STATICTEXT;
end;

function TPPGCustomBadge.AccDefaultAction: string;
begin
  if Assigned(OnClick) then
    Result := PPGStr(@SPPGAccPress)
  else
    Result := '';
end;

function TPPGCustomBadge.AccName: string;
begin
  Result := DisplayText;
end;

{ TPPGCustomProgressRing }

constructor TPPGCustomProgressRing.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption];
  FIndeterminate := True;
  FMax := 100;
  FShowTrack := True;
  Width := 32;
  Height := 32;
  TabStop := False;
  FLoop := TPPGAnimation.Create(Self);
  FLoop.OnStep := LoopStep;
end;

destructor TPPGCustomProgressRing.Destroy;
begin
  if FLoop <> nil then
    FLoop.OnStep := nil;
  FreeAndNil(FLoop); // meldet sich selbst beim Animator ab
  inherited Destroy;
end;

procedure TPPGCustomProgressRing.Loaded;
begin
  inherited Loaded;
  // Aus der DFM: Min > Max korrigieren, Value in den Bereich holen
  if FMin >= FMax then
    FMax := FMin + 1;
  if FValue < FMin then
    FValue := FMin
  else if FValue > FMax then
    FValue := FMax;
  UpdateLoop;
end;

procedure TPPGCustomProgressRing.CreateWnd;
begin
  inherited CreateWnd;
  UpdateLoop;
end;

procedure TPPGCustomProgressRing.DestroyWnd;
begin
  if FLoop <> nil then
    FLoop.Stop; // ohne Fenster nichts zu zeigen
  inherited DestroyWnd;
end;

procedure TPPGCustomProgressRing.UpdateVisualState(Animate: Boolean);
begin
  // Kein Hover-/Druckzustand; Aenderungen der Animation-Einstellungen
  // kommen hier an und schalten die Schleife um.
  UpdateLoop;
  Invalidate;
end;

function TPPGCustomProgressRing.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGCustomProgressRing.IsDown: Boolean;
begin
  Result := False;
end;

procedure TPPGCustomProgressRing.UpdateLoop;
var
  Run: Boolean;
begin
  if (FLoop = nil) or (csDestroying in ComponentState) then
    Exit;
  // Nur drehen, wenn man es sieht (spart CPU und Animator-Takte)
  Run := FIndeterminate and HandleAllocated and Showing and
    not (csLoading in ComponentState) and not (csDesigning in ComponentState) and
    Animation.EffectiveEnabled;
  if Run then
    FLoop.StartLoop(2000)
  else if FLoop.Running then
    FLoop.Stop;
end;

function TPPGCustomProgressRing.Spinning: Boolean;
begin
  Result := (FLoop <> nil) and FLoop.Running;
end;

procedure TPPGCustomProgressRing.LoopStep(Sender: TObject);
begin
  Invalidate;
end;

procedure TPPGCustomProgressRing.CMShowingChanged(var Message: TMessage);
begin
  inherited;
  UpdateLoop;
end;

procedure TPPGCustomProgressRing.SetIndeterminate(const Value: Boolean);
begin
  if FIndeterminate <> Value then
  begin
    FIndeterminate := Value;
    UpdateLoop;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
  end;
end;

procedure TPPGCustomProgressRing.SetMin(const Value: Integer);
begin
  if FMin = Value then
    Exit;
  if not (csLoading in ComponentState) and (Value >= FMax) then
    raise EPPGPropertyError.CreateInvalid(Self, 'Min', IntToStr(Value));
  FMin := Value;
  if not (csLoading in ComponentState) and (FValue < FMin) then
    FValue := FMin;
  Invalidate;
end;

procedure TPPGCustomProgressRing.SetMax(const Value: Integer);
begin
  if FMax = Value then
    Exit;
  if not (csLoading in ComponentState) and (Value <= FMin) then
    raise EPPGPropertyError.CreateInvalid(Self, 'Max', IntToStr(Value));
  FMax := Value;
  if not (csLoading in ComponentState) and (FValue > FMax) then
    FValue := FMax;
  Invalidate;
end;


procedure TPPGCustomProgressRing.SetValue(const Value: Integer);
var
  V: Integer;
begin
  if csLoading in ComponentState then
  begin
    FValue := Value; // Min/Max ggf. noch nicht gelesen: Loaded prueft
    Exit;
  end;
  V := PPGCheckRange(Self, 'Value', Value, FMin, FMax);
  if FValue <> V then
  begin
    FValue := V;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
  end;
end;

procedure TPPGCustomProgressRing.SetThickness(const Value: Integer);
begin
  if FThickness = Value then
    Exit;
  FThickness := PPGCheckRange(Self, 'Thickness', Value, 0, 100);
  Invalidate;
end;

procedure TPPGCustomProgressRing.SetShowTrack(const Value: Boolean);
begin
  if FShowTrack <> Value then
  begin
    FShowTrack := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomProgressRing.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  D, W, Rad: Integer;
  A: TPPGAppearance;
  C: TPoint;
  Accent, Track: TColor;
  Pts: TArray<TPoint>;
  P, Start, Sweep: Single;
  Ring: TRect;
begin
  D := ClientR.Right - ClientR.Left;
  if ClientR.Bottom - ClientR.Top < D then
    D := ClientR.Bottom - ClientR.Top;
  if D < 4 then
    Exit;
  A := EffectiveAppearance;
  if FThickness > 0 then
    W := PPGScale(FThickness, ScalePPI)
  else
    // Automatisch: ein Zehntel, Appearance.BorderWidth als Mindeststaerke
    W := System.Math.Max(D div 10, PPGScale(A.BorderWidth, ScalePPI));
  if W < 2 then
    W := 2;
  C := Point((ClientR.Left + ClientR.Right) div 2, (ClientR.Top + ClientR.Bottom) div 2);
  Rad := (D - W) div 2;
  // Hochkontrast: die Appearance liefert die Systemfarben
  if not Enabled then
  begin
    // Deaktiviert: grauer Bogen auf der Spur des Disabled-Zustands
    Accent := PPGColorToRGB(A.Disabled.TextColor);
    Track := PPGColorToRGB(A.Disabled.BorderColor);
  end
  else
  begin
    // Bogen = Akzentrolle (Checked bzw. FocusColor), Spur = Rand in Ruhe
    Accent := PPGAccentColor(A);
    Track := PPGColorToRGB(A.Normal.BorderColor);
  end;
  if FShowTrack and not FIndeterminate then
  begin
    Ring := Rect(C.X - Rad - W div 2, C.Y - Rad - W div 2, C.X + Rad + (W + 1) div 2,
      C.Y + Rad + (W + 1) div 2);
    ACanvas.FrameEllipse(Ring, W, Track, 255);
  end;
  if FIndeterminate then
  begin
    if Spinning then
    begin
      // Zwei Umdrehungen je Periode; die Bogenlaenge atmet zwischen 30 und 270 Grad
      P := FLoop.Value;
      Start := P * 720;
      Sweep := 30 + 240 * (0.5 - 0.5 * Cos(P * 2 * Pi));
      Start := Start + (270 - Sweep) / 2;
    end
    else
    begin
      Start := 0;
      Sweep := 90; // ohne Animation: ruhender Viertelbogen
    end;
  end
  else
  begin
    Start := 0;
    Sweep := 360 * (FValue - FMin) / (FMax - FMin);
  end;
  if Sweep <= 0.5 then
    Exit;
  PPGArcPoints(C, Rad, Start, Sweep, Pts);
  ACanvas.DrawPolyline(Pts, W, Accent, 255);
end;

function TPPGCustomProgressRing.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_PROGRESSBAR;
end;

function TPPGCustomProgressRing.AccState: Integer;
begin
  Result := (inherited AccState) or STATE_SYSTEM_READONLY;
  if FIndeterminate then
    Result := Result or STATE_SYSTEM_BUSY;
end;

function TPPGCustomProgressRing.AccValue: string;
begin
  if FIndeterminate then
    Result := ''
  else
    Result := IntToStr(Round((FValue - FMin) * 100 / (FMax - FMin))) + ' %';
end;

{ TPPGCustomInfoBar }

const
  BarPad = 12;       // logische px Innenabstand
  IconSize = 16;
  CloseSize = 32;

procedure TPPGCustomInfoBar.SetBarStyle(const Value: TPPGElementStyle);
begin
  FBarStyle.Assign(Value);
end;

procedure TPPGCustomInfoBar.BarStyleChanged(Sender: TObject);
begin
  FHeightValid := False;
  RequestAutoSize;
  Realign;
  Invalidate;
end;

constructor TPPGCustomInfoBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBarStyle := TPPGElementStyle.Create(Self);
  FBarStyle.OnChange := BarStyleChanged;
  ControlStyle := ControlStyle - [csSetCaption]; // Audit 5d: OnClick wie TControl
  FIsOpen := True;
  FIsClosable := True;
  FMarkup := TPPGMarkupLayout.Create;
  FOpenAnim := TPPGAnimation.Create(Self);
  FOpenAnim.Jump(1);
  FOpenAnim.OnStep := OpenStep;
  Width := 400;
  Height := 48;
  TabStop := True;
  AutoSize := True;
  if GMsgInfoAction = 0 then
    GMsgInfoAction := RegisterWindowMessage('PPGlow.InfoBarAction');
end;

destructor TPPGCustomInfoBar.Destroy;
begin
  if FOpenAnim <> nil then
    FOpenAnim.OnStep := nil;
  FreeAndNil(FOpenAnim);
  FreeAndNil(FMarkup);
  inherited Destroy;
  FreeAndNil(FBarStyle);
end;

function TPPGCustomInfoBar.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGCustomInfoBar.IsDown: Boolean;
begin
  Result := False;
end;

function TPPGCustomInfoBar.MarkupText: string;
begin
  // Titel fett, dann der Text (der Text darf selbst Markup enthalten)
  if FTitle <> '' then
    Result := '<b>' + StringReplace(StringReplace(FTitle, '&', '&amp;', [rfReplaceAll]),
      '<', '&lt;', [rfReplaceAll]) + '</b>   ' + FMessage
  else
    Result := FMessage;
end;

function TPPGCustomInfoBar.SeverityColor: TColor;
begin
  // Hochkontrast: alle Signal-Tokens sind clHighlight
  Result := PPGSeverityColor(Tokens, FSeverity);
end;

procedure TPPGCustomInfoBar.GetLayout(out IconR, TextR, ActionR, CloseR: TRect);
var
  PPI, Pad, X, R, W, H, Top, Bottom: Integer;
  S: TSize;
begin
  PPI := ScalePPI;
  Pad := PPGScale(BarPad, PPI);
  H := Height;
  // Waehrend des Auf-/Zuklappens nach der vollen Hoehe ausrichten (nichts wandert)
  if (FOpenAnim <> nil) and (FOpenAnim.Value < 1) and (FFullH > 0) then
    H := FFullH;
  Top := 0;
  Bottom := H;
  IconR := Rect(Pad, 0, Pad + PPGScale(IconSize, PPI), 0);
  IconR.Top := Pad + (PPGScale(20, PPI) - PPGScale(IconSize, PPI)) div 2;
  IconR.Bottom := IconR.Top + PPGScale(IconSize, PPI);
  R := Width - PPGScale(4, PPI);
  CloseR := Rect(0, 0, 0, 0);
  if FIsClosable then
  begin
    CloseR := Rect(R - PPGScale(CloseSize, PPI), (H - PPGScale(CloseSize, PPI)) div 2, R,
      (H + PPGScale(CloseSize, PPI)) div 2);
    R := CloseR.Left - PPGScale(4, PPI);
  end
  else
    R := Width - Pad;
  ActionR := Rect(0, 0, 0, 0);
  if FActionCaption <> '' then
  begin
    S := PPGMeasureTextNoCanvas(FActionCaption, Font, 0, False);
    W := S.cx + 2 * PPGScale(12, PPI);
    ActionR := Rect(R - W, (H - PPGScale(30, PPI)) div 2, R, (H + PPGScale(30, PPI)) div 2);
    R := ActionR.Left - PPGScale(8, PPI);
  end;
  X := IconR.Right + PPGScale(10, PPI);
  TextR := Rect(X, Top + Pad, R, Bottom - Pad);
  if UseRightToLeftAlignment then
  begin
    IconR := Rect(Width - IconR.Right, IconR.Top, Width - IconR.Left, IconR.Bottom);
    TextR := Rect(Width - TextR.Right, TextR.Top, Width - TextR.Left, TextR.Bottom);
    if not IsRectEmpty(ActionR) then
      ActionR := Rect(Width - ActionR.Right, ActionR.Top, Width - ActionR.Left, ActionR.Bottom);
    if not IsRectEmpty(CloseR) then
      CloseR := Rect(Width - CloseR.Right, CloseR.Top, Width - CloseR.Left, CloseR.Bottom);
  end;
end;

function TPPGCustomInfoBar.PartRect(Part: TPPGInfoBarPart): TRect;
var
  IR, TR, AR, CR: TRect;
begin
  GetLayout(IR, TR, AR, CR);
  case Part of
    ipAction: Result := AR;
    ipClose: Result := CR;
  else
    Result := Rect(0, 0, 0, 0);
  end;
end;

function TPPGCustomInfoBar.PartAt(X, Y: Integer): TPPGInfoBarPart;
var
  IR, TR, AR, CR: TRect;
begin
  GetLayout(IR, TR, AR, CR);
  if PtInRect(AR, Point(X, Y)) then
    Result := ipAction
  else if PtInRect(CR, Point(X, Y)) then
    Result := ipClose
  else
    Result := ipNone;
end;

function TPPGCustomInfoBar.HeightForTextWidth(TextWidth: Integer): Integer;
var
  PPI: Integer;
  Temp: TFont;
  Txt: string;
begin
  PPI := ScalePPI;
  Txt := MarkupText;
  // Audit 8D: Die Oeffnen-Animation fragt je Bild die volle Hoehe ab - der
  // Umbruch wird nur bei neuer Breite, neuem Text oder neuer PPI gerechnet
  if FHeightValid and (FHeightW = TextWidth) and (FHeightPPI = PPI) and (FHeightText = Txt) then
    Result := FHeightFull
  else
  begin
    Temp := nil;
    try
      FMarkup.Layout(Txt, PPGElementFont(FBarStyle, Font, [], Temp), nil, Max(TextWidth, 1), True);
    finally
      Temp.Free;
    end;
    Result := FMarkup.Size.cy + 2 * PPGScale(BarPad, PPI);
    if Result < PPGScale(48, PPI) then
      Result := PPGScale(48, PPI);
    FHeightValid := True;
    FHeightW := TextWidth;
    FHeightPPI := PPI;
    FHeightText := Txt;
    FHeightFull := Result;
  end;
  // Auf-/Zuklappen: Anteil der vollen Hoehe
  FFullH := Result;
  if (FOpenAnim <> nil) and (FOpenAnim.Value < 1) then
    Result := Max(1, Round(Result * FOpenAnim.Value));
end;

function TPPGCustomInfoBar.CalcAutoSize(out AWidth, AHeight: Integer): Boolean;
var
  IR, TR, AR, CR: TRect;
begin
  GetLayout(IR, TR, AR, CR);
  AWidth := Width; // nur die Hoehe folgt dem Text
  AHeight := HeightForTextWidth(TR.Right - TR.Left);
  Result := True;
end;

function TPPGCustomInfoBar.AutoSizeWidth: Boolean;
begin
  Result := False;
end;

function TPPGCustomInfoBar.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
var
  IR, TR, AR, CR: TRect;
begin
  // Der Umbruch haengt von der NEUEN Breite ab (Width ist hier noch die alte)
  Result := True;
  if (csLoading in ComponentState) or (Align in [alLeft, alRight, alClient]) then
    Exit;
  GetLayout(IR, TR, AR, CR);
  NewHeight := HeightForTextWidth(NewWidth - (Width - (TR.Right - TR.Left)));
end;

procedure TPPGCustomInfoBar.Resize;
begin
  inherited Resize;
  RequestAutoSize; // Umbruch haengt von der Breite ab
end;

procedure TPPGCustomInfoBar.TextChanged;
begin
  RequestAutoSize;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_NAMECHANGE);
end;

procedure TPPGCustomInfoBar.CMFontChanged(var Message: TMessage);
begin
  inherited;
  FHeightValid := False;
  RequestAutoSize;
end;

procedure TPPGCustomInfoBar.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  Temp: TFont;
  IR, TR, AR, CR, Body, R: TRect;
  PPI, Rad: Integer;
  Sev, Fill, Border, Text: TColor;
  T: TPPGTokens;
  A: TPPGAppearance;
  S: TPPGSurfaceStyle;
  G: TPPGIconGlyph;
  HC: Boolean;
  Pts: array[0..2] of TPoint;
begin
  PPI := ScalePPI;
  T := Tokens;
  A := EffectiveAppearance;
  HC := UseHighContrast;
  Sev := SeverityColor;
  if not Enabled and not HC then
    Sev := PPGBlendColor(Sev, Tokens.Surface, 0.6); // deaktiviert: Signalfarbe zuruecknehmen
  if HC then
  begin
    // Sonderfall: keine getoente Flaeche
    Fill := T.Surface;
    Border := T.Stroke;
    if Enabled then
      Text := T.TextPrimary
    else
      Text := T.TextDisabled;
  end
  else
  begin
    // Flaeche leicht in der Signalfarbe getoent (wie WinUI InfoBar)
    Fill := PPGBlendColor(T.Surface, Sev, 0.12);
    Border := PPGBlendColor(T.Surface, Sev, 0.35);
    Text := T.TextPrimary;
    if UseVclStyle then
      Text := PPGColorToRGB(A.Normal.TextColor);
    if not UseVclStyle then
    begin
      Fill := FBarStyle.FillFor(UseDarkMode, Fill);
      Border := FBarStyle.BorderFor(UseDarkMode, Border);
      Text := FBarStyle.TextFor(UseDarkMode, Text);
    end;
    if not Enabled then
      Text := T.TextDisabled;
  end;
  Body := ClientR;
  Rad := Min(PPGScale(A.Rounding, PPI), (Body.Bottom - Body.Top) div 2);
  ACanvas.FillRoundRect(Body, Rad, Fill, 255);
  ACanvas.FrameRoundRect(Body, Rad, 1, Border, 255);
  GetLayout(IR, TR, AR, CR);
  // Symbol (Icon-Schrift, sonst Kreis mit Zeichen)
  case FSeverity of
    psSuccess: G := igSuccess;
    psWarning: G := igWarning;
    psError: G := igError;
  else
    G := igInfo;
  end;
  if not PPGDrawIcon(ACanvas, IR, G, Sev, PPGScale(IconSize, PPI)) then
  begin
    ACanvas.FillEllipse(IR, Sev, 255);
    if FSeverity = psSuccess then
    begin
      Pts[0] := Point(IR.Left + (IR.Right - IR.Left) * 3 div 10, (IR.Top + IR.Bottom) div 2);
      Pts[1] := Point(IR.Left + (IR.Right - IR.Left) * 45 div 100, IR.Top + (IR.Bottom - IR.Top) * 68 div 100);
      Pts[2] := Point(IR.Left + (IR.Right - IR.Left) * 72 div 100, IR.Top + (IR.Bottom - IR.Top) * 32 div 100);
      ACanvas.DrawPolyline(Pts, PPGScale(2, PPI), PPGContrastTextColor(Sev), 255);
    end
    else if FSeverity = psError then
      ACanvas.DrawText(IR, 'x', Font, PPGContrastTextColor(Sev), DT_CENTER or DT_VCENTER or DT_SINGLELINE)
    else if FSeverity = psWarning then
      ACanvas.DrawText(IR, '!', Font, PPGContrastTextColor(Sev), DT_CENTER or DT_VCENTER or DT_SINGLELINE)
    else
      ACanvas.DrawText(IR, 'i', Font, PPGContrastTextColor(Sev), DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end;
  // Titel und Text
  Temp := nil;
  try
    FMarkup.Layout(MarkupText, PPGElementFont(FBarStyle, Font, [], Temp), nil, TR.Right - TR.Left, True);
  finally
    Temp.Free;
  end;
  ACanvas.PushClipRoundRect(TR, 0);
  try
    if UseRightToLeftAlignment then
      FMarkup.Draw(ACanvas, TR.Right - FMarkup.Size.cx, TR.Top, Text, TextLinkColor, Enabled)
    else
      FMarkup.Draw(ACanvas, TR.Left, TR.Top, Text, TextLinkColor, Enabled);
  finally
    ACanvas.PopClip;
  end;
  // Aktions-Button im Stil des Presets
  if not IsRectEmpty(AR) then
  begin
    if not Enabled then
      S := A.Resolve(vsDisabled, PPI, False)
    else if (FDownPart = ipAction) and (FHotPart = ipAction) then
      S := A.Resolve(vsDown, PPI, False)
    else if FHotPart = ipAction then
      S := A.Resolve(vsHot, PPI, False)
    else
      S := A.Resolve(vsNormal, PPI, False);
    S.GlowAlpha := 0;
    if S.Rounding > PPGScale(4, PPI) then
      S.Rounding := PPGScale(4, PPI);
    Renderer.DrawSurface(ACanvas, AR, S);
    ACanvas.DrawText(AR, FActionCaption, Font, S.TextColor,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
    if FocusVisible and (FFocusPart = ipAction) then
    begin
      S.Focused := True;
      S.BorderColor := PPGColorToRGB(A.FocusColor);
      Renderer.DrawFocus(ACanvas, AR, S);
    end;
  end;
  // Schliessen-Knopf
  if not IsRectEmpty(CR) then
  begin
    R := CR;
    InflateRect(R, -PPGScale(4, PPI), -PPGScale(4, PPI));
    if (FHotPart = ipClose) and Enabled then
      ACanvas.FillRoundRect(R, PPGScale(4, PPI), Text, 24);
    if not PPGDrawIcon(ACanvas, R, igClose, Text, PPGScale(10, PPI)) then
    begin
      Pts[0] := Point(R.Left + (R.Right - R.Left) div 3, R.Top + (R.Bottom - R.Top) div 3);
      Pts[1] := Point(R.Right - (R.Right - R.Left) div 3, R.Bottom - (R.Bottom - R.Top) div 3);
      ACanvas.DrawPolyline(Slice(Pts, 2), PPGScale(1, PPI) + 1, Text, 255);
      Pts[0] := Point(R.Right - (R.Right - R.Left) div 3, R.Top + (R.Bottom - R.Top) div 3);
      Pts[1] := Point(R.Left + (R.Right - R.Left) div 3, R.Bottom - (R.Bottom - R.Top) div 3);
      ACanvas.DrawPolyline(Slice(Pts, 2), PPGScale(1, PPI) + 1, Text, 255);
    end;
    if FocusVisible and (FFocusPart = ipClose) then
      ACanvas.FrameRoundRect(R, PPGScale(4, PPI), PPGScale(2, PPI), A.FocusColor, 255);
  end;
end;

procedure TPPGCustomInfoBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = mbLeft then
  begin
    FDownPart := PartAt(X, Y);
    Invalidate;
  end;
end;

procedure TPPGCustomInfoBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P: TPPGInfoBarPart;
begin
  inherited MouseMove(Shift, X, Y);
  P := PartAt(X, Y);
  if P <> FHotPart then
  begin
    FHotPart := P;
    Invalidate;
  end;
end;

procedure TPPGCustomInfoBar.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P: TPPGInfoBarPart;
begin
  P := FDownPart;
  FDownPart := ipNone; // Zustand vor dem Ereignis zuruecksetzen
  Invalidate;
  inherited MouseUp(Button, Shift, X, Y);
  if (Button = mbLeft) and (P <> ipNone) and (PartAt(X, Y) = P) then
    ActivatePart(P);
end;

procedure TPPGCustomInfoBar.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHotPart <> ipNone then
  begin
    FHotPart := ipNone;
    Invalidate;
  end;
end;

procedure TPPGCustomInfoBar.ActivatePart(Part: TPPGInfoBarPart);
begin
  case Part of
    ipAction:
      if Assigned(FOnActionClick) then
        FOnActionClick(Self);
    ipClose:
      CloseByUser;
  end;
end;

function TPPGCustomInfoBar.CloseByUser: Boolean;
var
  Allow: Boolean;
begin
  Result := False;
  if not FIsClosable then
    Exit;
  Allow := True;
  if Assigned(FOnClosing) then
    FOnClosing(Self, Allow);
  if not Allow then
    Exit;
  SetIsOpen(False);
  Result := True;
  if Assigned(FOnClose) then
    FOnClose(Self);
end;

procedure TPPGCustomInfoBar.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TPPGCustomInfoBar.DoEnter;
begin
  inherited DoEnter;
  if FFocusPart = ipNone then
  begin
    if FActionCaption <> '' then
      FFocusPart := ipAction
    else if FIsClosable then
      FFocusPart := ipClose;
    Invalidate;
  end;
end;

procedure TPPGCustomInfoBar.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  case Key of
    VK_LEFT, VK_RIGHT:
      begin
        if (FFocusPart = ipAction) and FIsClosable then
          FFocusPart := ipClose
        else if (FFocusPart = ipClose) and (FActionCaption <> '') then
          FFocusPart := ipAction;
        Invalidate;
        Key := 0;
      end;
    VK_RETURN, VK_SPACE:
      if FFocusPart <> ipNone then
      begin
        ActivatePart(FFocusPart);
        Key := 0;
      end;
    VK_ESCAPE:
      if FIsClosable then
      begin
        CloseByUser;
        Key := 0;
      end;
  end;
end;

procedure TPPGCustomInfoBar.SetSeverity(const Value: TPPGSeverity);
begin
  if FSeverity <> Value then
  begin
    FSeverity := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomInfoBar.SetTitle(const Value: string);
begin
  if FTitle <> Value then
  begin
    FTitle := Value;
    TextChanged;
  end;
end;

procedure TPPGCustomInfoBar.SetMessage(const Value: string);
begin
  if FMessage <> Value then
  begin
    FMessage := Value;
    TextChanged;
  end;
end;

function TPPGCustomInfoBar.CanAnimateOpen: Boolean;
begin
  // Animiert wird ueber AutoSize (Hoehe); sichtbar muss der Parent sein
  Result := AutoSize and not (Align in [alLeft, alRight, alClient]) and
    (Parent <> nil) and Parent.Showing and Parent.HandleAllocated and
    not (csLoading in ComponentState) and Animation.EffectiveEnabled;
end;

procedure TPPGCustomInfoBar.SetIsOpen(const Value: Boolean);
begin
  if FIsOpen = Value then
    Exit;
  FIsOpen := Value;
  if csDesigning in ComponentState then
    Exit; // im Designer sichtbar bleiben
  if CanAnimateOpen then
  begin
    if Value then
    begin
      if not Visible then
        FOpenAnim.Jump(0);
      Visible := True;
      RequestAutoSize;
      FOpenAnim.AnimateTo(1, Cardinal(Animation.Duration), ekDecelerate);
    end
    else
      FOpenAnim.AnimateTo(0, Cardinal(Animation.Duration), ekDecelerate);
  end
  else
  begin
    if Value then
      FOpenAnim.Jump(1)
    else
      FOpenAnim.Jump(0);
    Visible := Value;
    RequestAutoSize;
  end;
  // Screenreader liest die Meldung beim Oeffnen vor
  if Value and HandleAllocated then
    NotifyAccessibility(EVENT_SYSTEM_ALERT);
end;

procedure TPPGCustomInfoBar.CMVisibleChanged(var Message: TMessage);
begin
  inherited;
  // Audit 5b: Visible von aussen (Code, Designer) ist auch der Offen-Zustand.
  // Waehrend des Zuklappens bleibt Visible bis zum Ende True.
  if (csDesigning in ComponentState) or (csLoading in ComponentState) then
    Exit;
  if Visible and not FIsOpen then
  begin
    FIsOpen := True;
    FOpenAnim.Jump(1);
    RequestAutoSize;
  end
  else if not Visible and FIsOpen then
  begin
    FIsOpen := False;
    FOpenAnim.Jump(0);
  end;
end;

procedure TPPGCustomInfoBar.OpenStep(Sender: TObject);
begin
  RequestAutoSize;
  Invalidate;
  // Zugeklappt: erst jetzt unsichtbar
  if not FOpenAnim.Running and (FOpenAnim.Value <= 0) and not FIsOpen then
    Visible := False;
end;

procedure TPPGCustomInfoBar.SetIsClosable(const Value: Boolean);
begin
  if FIsClosable <> Value then
  begin
    FIsClosable := Value;
    if (FFocusPart = ipClose) and not Value then
      FFocusPart := ipNone;
    TextChanged;
  end;
end;

procedure TPPGCustomInfoBar.SetActionCaption(const Value: string);
begin
  if FActionCaption <> Value then
  begin
    FActionCaption := Value;
    if (FFocusPart = ipAction) and (Value = '') then
      FFocusPart := ipNone;
    TextChanged;
  end;
end;

procedure TPPGCustomInfoBar.WndProc(var Message: TMessage);
begin
  if (GMsgInfoAction <> 0) and (Message.Msg = GMsgInfoAction) then
  begin
    // Aus AccDoDefaultAction gepostet (ausserhalb des COM-Aufrufs)
    if FActionCaption <> '' then
      ActivatePart(ipAction)
    else
      ActivatePart(ipClose);
    Exit;
  end;
  inherited WndProc(Message);
end;

function TPPGCustomInfoBar.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_ALERT;
end;

function TPPGCustomInfoBar.AccName: string;
begin
  Result := Trim(FTitle + ' ' + PPGStripMarkup(FMessage));
end;

function TPPGCustomInfoBar.AccDefaultAction: string;
begin
  if FActionCaption <> '' then
    Result := FActionCaption
  else if FIsClosable then
    Result := PPGStr(@SPPGAccClose)
  else
    Result := '';
end;

procedure TPPGCustomInfoBar.AccDoDefaultAction;
begin
  if HandleAllocated then
    PostMessage(Handle, GMsgInfoAction, 0, 0);
end;

end.
