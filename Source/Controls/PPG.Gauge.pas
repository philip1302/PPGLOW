unit PPG.Gauge;

{ Dashboard-Bausteine (Phase 10c): TPPGGauge und TPPGKpiTile.

  TPPGGauge - Bogenanzeige fuer einen Wert:
  - Min/Max/Value (Double), Bogen ueber StartAngle/SweepAngle (0 Grad = oben,
    im Uhrzeigersinn; Vorgabe 270 Grad, halbrund = -90/180).
  - Ranges: farbige Abschnitte der Spur (Signalfarben aus den Tokens). Mit
    ValueColorFromRange nimmt der Wertbogen die Farbe seines Abschnitts an.
  - Zielmarke (ShowTarget/TargetValue), Werttext mit ValueFormat und Units,
    Beschriftung (Caption) darunter.
  - Wertwechsel gleitet ueber den gemeinsamen Animator (ekDecelerate), der
    Text zaehlt dabei mit. Code setzt Werte ohne OnChange.
  - ReadOnly (Vorgabe): reine Anzeige ohne Fokus. Sonst Schieberegler:
    Ziehen auf dem Bogen, Pfeile/Bild/Pos1/Ende; OnChange nur bei Anwender-
    Aenderungen.
  - Screenreader: Rolle Fortschritt (ReadOnly) bzw. Schieberegler.

  TPPGKpiTile - Kennzahl-Kachel:
  - Title, Wert (Value/ValueFormat oder freier ValueText) mit Units,
    Veraenderung (Change/ChangeFormat) mit Trendpfeil: gruen = gut,
    rot = schlecht (InvertTrend: weniger ist besser).
  - Eingebettete Sparkline (SparklineText/SetSparkline) ueber PPGDrawSparkline.
  - Flaeche wie ein Container (IPPGContainerRenderer), Hover; Klick, Enter und
    Leertaste loesen OnClick aus. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Tokens, PPG.Animation, PPG.Render.Intf, PPG.Controls.Base,
  PPG.Sparkline, PPG.ElementStyle;

type
  TPPGGaugeRangeKind = (grkSuccess, grkWarning, grkError, grkAccent, grkNeutral, grkCustom);

  TPPGGaugeRange = class(TCollectionItem)
  private
    FStartValue: Double;
    FEndValue: Double;
    FRangeColor: TPPGGaugeRangeKind;
    FCustomColor: TColor;
    procedure SetStartValue(const Value: Double);
    procedure SetEndValue(const Value: Double);
    procedure SetRangeColor(const Value: TPPGGaugeRangeKind);
    procedure SetCustomColor(const Value: TColor);
    function IsStartStored: Boolean;
    function IsEndStored: Boolean;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    function Contains(V: Double): Boolean;
  published
    property StartValue: Double read FStartValue write SetStartValue stored IsStartStored;
    property EndValue: Double read FEndValue write SetEndValue stored IsEndStored;
    property Kind: TPPGGaugeRangeKind read FRangeColor write SetRangeColor default grkSuccess;
    property Color: TColor read FCustomColor write SetCustomColor default clDefault;
  end;

  TPPGGaugeRanges = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGGaugeRange;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TPPGGaugeRange;
    /// Abschnitt mit V (der letzte gewinnt bei Ueberlappung), sonst nil.
    function RangeAt(V: Double): TPPGGaugeRange;
    property Items[Index: Integer]: TPPGGaugeRange read GetItem; default;
  end;

  TPPGCustomGauge = class(TPPGCustomControl)
  private
    FValueStyle: TPPGElementStyle;
    FMin: Double;
    FMax: Double;
    FValue: Double;
    FFromValue: Double;      // Startwert der laufenden Animation
    FValueAnim: TPPGAnimation;
    FStartAngle: Integer;
    FSweepAngle: Integer;
    FThickness: Integer;
    FRanges: TPPGGaugeRanges;
    FValueColorFromRange: Boolean;
    FShowTarget: Boolean;
    FTargetValue: Double;
    FShowValue: Boolean;
    FValueFormat: string;
    FUnits: string;
    FValueColor: TColor;
    FReadOnly: Boolean;
    FIncrement: Double;
    FDragging: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetValueStyle(const Value: TPPGElementStyle);
    procedure ValueStyleChanged(Sender: TObject);
    procedure SetMin(const Value: Double);
    procedure SetMax(const Value: Double);
    procedure SetValue(const Value: Double);
    procedure SetStartAngle(const Value: Integer);
    procedure SetSweepAngle(const Value: Integer);
    procedure SetThickness(const Value: Integer);
    procedure SetRanges(const Value: TPPGGaugeRanges);
    procedure SetValueColorFromRange(const Value: Boolean);
    procedure SetShowTarget(const Value: Boolean);
    procedure SetTargetValue(const Value: Double);
    procedure SetShowValue(const Value: Boolean);
    procedure SetValueFormat(const Value: string);
    procedure SetUnits(const Value: string);
    procedure SetValueColor(const Value: TColor);
    procedure SetReadOnly(const Value: Boolean);
    procedure SetIncrement(const Value: Double);
    function IsMinStored: Boolean;
    function IsMaxStored: Boolean;
    function IsValueStored: Boolean;
    function IsTargetStored: Boolean;
    function IsIncrementStored: Boolean;
    function IsValueFormatStored: Boolean;
    function ClampValue(V: Double): Double;
    procedure AnimStep(Sender: TObject);
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  protected
    procedure Loaded; override;
    procedure UpdateVisualState(Animate: Boolean = True); override;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    /// Wert durch den Anwender (OnChange, Screenreader).
    procedure UserSetValue(V: Double);
    function AccRole: Integer; override;
    function AccState: Integer; override;
    function AccValue: string; override;
    property Min: Double read FMin write SetMin stored IsMinStored;
    property Max: Double read FMax write SetMax stored IsMaxStored;
    property Value: Double read FValue write SetValue stored IsValueStored;
    /// Winkel in Grad, 0 = oben, im Uhrzeigersinn.
    property StartAngle: Integer read FStartAngle write SetStartAngle default -135;
    property SweepAngle: Integer read FSweepAngle write SetSweepAngle default 270;
    /// Strichstaerke in logischen px (0 = aus der Groesse).
    property Thickness: Integer read FThickness write SetThickness default 0;
    property Ranges: TPPGGaugeRanges read FRanges write SetRanges;
    property ValueColorFromRange: Boolean read FValueColorFromRange
      write SetValueColorFromRange default True;
    property ShowTarget: Boolean read FShowTarget write SetShowTarget default False;
    property TargetValue: Double read FTargetValue write SetTargetValue stored IsTargetStored;
    property ShowValue: Boolean read FShowValue write SetShowValue default True;
    /// FormatFloat-Maske des Werttexts.
    property ValueFormat: string read FValueFormat write SetValueFormat stored IsValueFormatStored;
    property Units: string read FUnits write SetUnits;
    /// Farbe des Wertbogens (clDefault = Akzent bzw. Farbe des Abschnitts).
    property ValueColor: TColor read FValueColor write SetValueColor default clDefault;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default True;
    /// Schritt fuer Pfeiltasten (Bild = zehnfach).
    property Increment: Double read FIncrement write SetIncrement stored IsIncrementStored;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    /// Werttext: TextColor und Schrift (ohne eigene Schrift: fett, Groesse nach dem Bogen).
    property ValueStyle: TPPGElementStyle read FValueStyle write SetValueStyle;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Gerade angezeigter Wert (waehrend der Animation zwischen alt und neu).
    function DisplayValue: Double;
    function ValueText(V: Double): string;
    /// Mittelpunkt, Radius (Mitte des Strichs) und Strichstaerke.
    procedure GetGeometry(out Center: TPoint; out Radius, Thick: Integer);
    /// Wert zum Punkt (Ziehen); ausserhalb des Bogens das naehere Ende.
    function ValueAtPoint(X, Y: Integer): Double;
    function AngleOfValue(V: Double): Single;
    function ArcColor(V: Double): TColor;
  end;

  TPPGGauge = class(TPPGCustomGauge)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighContrastSupport;
    property Min;
    property Max;
    property Value;
    property StartAngle;
    property SweepAngle;
    property Thickness;
    property Ranges;
    property ValueColorFromRange;
    property ShowTarget;
    property TargetValue;
    property ShowValue;
    property ValueFormat;
    property Units;
    property ValueColor;
    property ValueStyle;
    property ReadOnly;
    property Increment;
    property Caption;
    property Align;
    property Anchors;
    property BiDiMode;
    property Constraints;
    property Enabled;
    property Font;
    property Hint;
    property ParentBiDiMode;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default False;
    property Visible;
    property Touch;
    property OnGesture;
    property OnChange;
    property OnClick;
    property OnEnter;
    property OnExit;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseActivate;
    property OnContextPopup;
    property StyleElements;
    property DragMode;
    property DragCursor;
    property OnDragDrop;
    property OnDragOver;
    property OnStartDrag;
    property OnEndDrag;
    property Color;
    property ParentColor;
  end;

  TPPGTrend = (trNone, trUp, trDown);

  TPPGCustomKpiTile = class(TPPGCustomControl)
  private
    FTitleStyle: TPPGElementStyle;
    FValueStyle: TPPGElementStyle;
    FTitle: string;
    FValue: Double;
    FValueText: string;
    FValueFormat: string;
    FUnits: string;
    FChange: Double;
    FChangeFormat: string;
    FShowChange: Boolean;
    FInvertTrend: Boolean;
    FSparkline: TArray<Double>;
    FSparklineKind: TPPGSparklineKind;
    FShowSparkline: Boolean;
    procedure SetTitleStyle(const Value: TPPGElementStyle);
    procedure TitleStyleChanged(Sender: TObject);
    procedure SetValueStyle(const Value: TPPGElementStyle);
    procedure ValueStyleChanged(Sender: TObject);
    procedure SetTitle(const Value: string);
    procedure SetValue(const Value: Double);
    procedure SetValueText(const Value: string);
    procedure SetValueFormat(const Value: string);
    procedure SetUnits(const Value: string);
    procedure SetChange(const Value: Double);
    procedure SetChangeFormat(const Value: string);
    procedure SetShowChange(const Value: Boolean);
    procedure SetInvertTrend(const Value: Boolean);
    procedure SetSparklineKind(const Value: TPPGSparklineKind);
    procedure SetShowSparkline(const Value: Boolean);
    function GetSparklineText: string;
    procedure SetSparklineText(const Value: string);
    function IsValueStored: Boolean;
    function IsChangeStored: Boolean;
    function IsValueFormatStored: Boolean;
    function IsChangeFormatStored: Boolean;
    procedure Changed;
  protected
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure KeyPress(var Key: Char); override;
    function AccName: string; override;
    function AccRole: Integer; override;
    function AccValue: string; override;
    property Title: string read FTitle write SetTitle;
    property Value: Double read FValue write SetValue stored IsValueStored;
    /// Freier Text statt Value (z.B. "n/a" oder "3:45 h").
    property ValueText: string read FValueText write SetValueText;
    property ValueFormat: string read FValueFormat write SetValueFormat stored IsValueFormatStored;
    property Units: string read FUnits write SetUnits;
    property Change: Double read FChange write SetChange stored IsChangeStored;
    /// FormatFloat-Maske der Veraenderung (Abschnitte fuer +/-/0).
    property ChangeFormat: string read FChangeFormat write SetChangeFormat stored IsChangeFormatStored;
    property ShowChange: Boolean read FShowChange write SetShowChange default True;
    /// True = sinkende Werte sind gut (z.B. Fehlerquote).
    property InvertTrend: Boolean read FInvertTrend write SetInvertTrend default False;
    property Kind: TPPGSparklineKind read FSparklineKind write SetSparklineKind default skArea;
    property ShowSparkline: Boolean read FShowSparkline write SetShowSparkline default True;
    property SparklineText: string read GetSparklineText write SetSparklineText stored True;
    /// Wert: TextColor und Schrift (ohne eigene Schrift: fett, Groesse nach der Kachel).
    property ValueStyle: TPPGElementStyle read FValueStyle write SetValueStyle;
    /// Titel: TextColor und Schrift.
    property TitleStyle: TPPGElementStyle read FTitleStyle write SetTitleStyle;
  public
    destructor Destroy; override;
    constructor Create(AOwner: TComponent); override;
    procedure SetSparkline(const AValues: array of Double);
    function Trend: TPPGTrend;
    /// Farbe der Veraenderung (gut = Erfolg, schlecht = Fehler, 0 = neutral).
    function ChangeColor: TColor;
    function DisplayValueText: string;
    function DisplayChangeText: string;
    /// Bereiche fuer Titel, Wert, Veraenderung und Sparkline (Tests).
    procedure GetLayout(out TitleR, ValueR, ChangeR, SparkR: TRect);
  end;

  TPPGKpiTile = class(TPPGCustomKpiTile)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighContrastSupport;
    property Title;
    property TitleStyle;
    property Value;
    property ValueText;
    property ValueStyle;
    property ValueFormat;
    property Units;
    property Change;
    property ChangeFormat;
    property ShowChange;
    property InvertTrend;
    property Kind;
    property ShowSparkline;
    property SparklineText;
    property Align;
    property Anchors;
    property BiDiMode;
    property Constraints;
    property Enabled;
    property Font;
    property Hint;
    property ParentBiDiMode;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Touch;
    property OnGesture;
    property OnClick;
    property OnEnter;
    property OnExit;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseActivate;
    property OnContextPopup;
    property StyleElements;
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
  end;

implementation

uses
  PPG.Lang,
  System.Math, System.UITypes, Winapi.oleacc,
  PPG.Consts, PPG.Exceptions, PPG.ErrorHandler, PPG.Appearance, PPG.DpiUtils,
  PPG.Render.Registry, PPG.Render.Gdi, PPG.Render.Shapes;

const
  DefaultValueFormat = '0';
  DefaultChangeFormat = '+0.0%;-0.0%;0.0%';
  DefaultKpiFormat = '#,##0';

function RangeColorOf(const T: TPPGTokens; Kind: TPPGGaugeRangeKind; Custom: TColor): TColor;
begin
  case Kind of
    grkSuccess: Result := T.Success;
    grkWarning: Result := T.Warning;
    grkError: Result := T.Danger;
    grkAccent: Result := T.Accent;
    grkNeutral: Result := T.TextSecondary;
  else
    // Nicht gesetzt = clDefault (vorher clNone; beides gilt als leer)
    if (Custom = clDefault) or (Custom = clNone) then
      Result := T.TextSecondary
    else
      Result := PPGColorToRGB(Custom);
  end;
end;

{ TPPGGaugeRange }

function TPPGGaugeRange.GetDisplayName: string;
begin
  Result := Format('%g - %g', [FStartValue, FEndValue]);
end;

constructor TPPGGaugeRange.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FCustomColor := clDefault;
end;

procedure TPPGGaugeRange.Assign(Source: TPersistent);
begin
  if Source is TPPGGaugeRange then
  begin
    FStartValue := TPPGGaugeRange(Source).FStartValue;
    FEndValue := TPPGGaugeRange(Source).FEndValue;
    FRangeColor := TPPGGaugeRange(Source).FRangeColor;
    FCustomColor := TPPGGaugeRange(Source).FCustomColor;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGGaugeRange.Contains(V: Double): Boolean;
begin
  Result := (V >= System.Math.Min(FStartValue, FEndValue)) and
    (V <= System.Math.Max(FStartValue, FEndValue));
end;

function TPPGGaugeRange.IsStartStored: Boolean;
begin
  Result := FStartValue <> 0;
end;

function TPPGGaugeRange.IsEndStored: Boolean;
begin
  Result := FEndValue <> 0;
end;

procedure TPPGGaugeRange.SetStartValue(const Value: Double);
begin
  PPGCheckFinite(Self, 'StartValue', Value);
  if FStartValue <> Value then
  begin
    FStartValue := Value;
    Changed(False);
  end;
end;

procedure TPPGGaugeRange.SetEndValue(const Value: Double);
begin
  PPGCheckFinite(Self, 'EndValue', Value);
  if FEndValue <> Value then
  begin
    FEndValue := Value;
    Changed(False);
  end;
end;

procedure TPPGGaugeRange.SetRangeColor(const Value: TPPGGaugeRangeKind);
begin
  if FRangeColor <> Value then
  begin
    FRangeColor := Value;
    Changed(False);
  end;
end;

procedure TPPGGaugeRange.SetCustomColor(const Value: TColor);
begin
  if FCustomColor <> Value then
  begin
    FCustomColor := Value;
    Changed(False);
  end;
end;

{ TPPGGaugeRanges }

constructor TPPGGaugeRanges.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TPPGGaugeRange);
end;

function TPPGGaugeRanges.Add: TPPGGaugeRange;
begin
  Result := TPPGGaugeRange(inherited Add);
end;

function TPPGGaugeRanges.GetItem(Index: Integer): TPPGGaugeRange;
begin
  Result := TPPGGaugeRange(inherited Items[Index]);
end;

function TPPGGaugeRanges.RangeAt(V: Double): TPPGGaugeRange;
var
  I: Integer;
begin
  Result := nil;
  for I := Count - 1 downto 0 do
    if Items[I].Contains(V) then
      Exit(Items[I]);
end;

procedure TPPGGaugeRanges.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if GetOwner is TControl then
    TControl(GetOwner).Invalidate;
end;

{ TPPGCustomGauge }

procedure TPPGCustomGauge.SetValueStyle(const Value: TPPGElementStyle);
begin
  FValueStyle.Assign(Value);
end;

procedure TPPGCustomGauge.ValueStyleChanged(Sender: TObject);
begin
  RequestAutoSize;
  Realign;
  Invalidate;
end;

constructor TPPGCustomGauge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FValueStyle := TPPGElementStyle.Create(Self);
  FValueStyle.OnChange := ValueStyleChanged;
  ControlStyle := ControlStyle - [csSetCaption, csDoubleClicks];
  FMax := 100;
  FStartAngle := -135;
  FSweepAngle := 270;
  FValueColorFromRange := True;
  FShowValue := True;
  FValueFormat := DefaultValueFormat;
  FValueColor := clDefault;
  FReadOnly := True;
  FIncrement := 1;
  FRanges := TPPGGaugeRanges.Create(Self);
  FValueAnim := TPPGAnimation.Create(Self);
  FValueAnim.Jump(1);
  FValueAnim.OnStep := AnimStep;
  TabStop := False;
  Width := 160;
  Height := 160;
end;

destructor TPPGCustomGauge.Destroy;
begin
  if FValueAnim <> nil then
    FValueAnim.OnStep := nil;
  FreeAndNil(FValueAnim); // meldet sich selbst beim Animator ab
  FreeAndNil(FRanges);
  inherited Destroy;
  FreeAndNil(FValueStyle);
end;

procedure TPPGCustomGauge.Loaded;
begin
  inherited Loaded;
  if FMax <= FMin then
  begin
    TPPGErrorHandler.LogWarning(Self, Format(PPGStr(@SPPGGaugeRangeInvalid),
      [FloatToStr(FMin), FloatToStr(FMax)]));
    FMax := FMin + 1;
  end;
  FValue := ClampValue(FValue);
  FValueAnim.Jump(1);
end;

procedure TPPGCustomGauge.UpdateVisualState(Animate: Boolean);
begin
  inherited UpdateVisualState(Animate);
  // Animation abgeschaltet: laufenden Wertwechsel sofort beenden
  if (FValueAnim <> nil) and not Animation.EffectiveEnabled and FValueAnim.Running then
  begin
    FValueAnim.Jump(1);
    Invalidate;
  end;
end;

function TPPGCustomGauge.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGCustomGauge.IsDown: Boolean;
begin
  Result := False;
end;

function TPPGCustomGauge.ClampValue(V: Double): Double;
begin
  Result := V;
  if Result < FMin then
    Result := FMin;
  if Result > FMax then
    Result := FMax;
end;

function TPPGCustomGauge.DisplayValue: Double;
begin
  if (FValueAnim <> nil) and FValueAnim.Running then
    Result := FFromValue + (FValue - FFromValue) * FValueAnim.Value
  else
    Result := FValue;
end;

procedure TPPGCustomGauge.AnimStep(Sender: TObject);
begin
  Invalidate;
end;

procedure TPPGCustomGauge.SetMin(const Value: Double);
begin
  // Audit 08.10.2026: NaN uebersteht alle Vergleiche und liess Paint werfen
  PPGCheckFinite(Self, 'Min', Value);
  if FMin = Value then
    Exit;
  if not PPGIsLoading(Self) and (Value >= FMax) then
    raise EPPGPropertyError.CreateFmt(PPGStr(@SPPGGaugeRangeInvalid),
      [FloatToStr(Value), FloatToStr(FMax)]);
  FMin := Value;
  if not PPGIsLoading(Self) then
    FValue := ClampValue(FValue);
  Invalidate;
end;

procedure TPPGCustomGauge.SetMax(const Value: Double);
begin
  PPGCheckFinite(Self, 'Max', Value);
  if FMax = Value then
    Exit;
  if not PPGIsLoading(Self) and (Value <= FMin) then
    raise EPPGPropertyError.CreateFmt(PPGStr(@SPPGGaugeRangeInvalid),
      [FloatToStr(FMin), FloatToStr(Value)]);
  FMax := Value;
  if not PPGIsLoading(Self) then
    FValue := ClampValue(FValue);
  Invalidate;
end;

procedure TPPGCustomGauge.SetValue(const Value: Double);
var
  V: Double;
begin
  PPGCheckFinite(Self, 'Value', Value);
  if csLoading in ComponentState then
  begin
    FValue := Value; // geklemmt wird in Loaded (Min/Max evtl. noch nicht gelesen)
    Exit;
  end;
  V := ClampValue(Value);
  if V = FValue then
    Exit;
  if HandleAllocated and Showing and Animation.EffectiveEnabled and
    not (csDesigning in ComponentState) and not FDragging then
  begin
    FFromValue := DisplayValue;
    FValue := V;
    FValueAnim.Jump(0);
    FValueAnim.AnimateTo(1, Animation.Duration * 4, ekDecelerate);
  end
  else
  begin
    FValue := V;
    FValueAnim.Jump(1);
  end;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
end;

procedure TPPGCustomGauge.UserSetValue(V: Double);
var
  Old: Double;
begin
  Old := FValue;
  V := ClampValue(V);
  if V = Old then
    Exit;
  FValue := V;
  FValueAnim.Jump(1);
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGCustomGauge.SetStartAngle(const Value: Integer);
begin
  if FStartAngle = Value then
    Exit;
  FStartAngle := PPGCheckRange(Self, 'StartAngle', Value, -360, 360);
  Invalidate;
end;

procedure TPPGCustomGauge.SetSweepAngle(const Value: Integer);
begin
  if FSweepAngle = Value then
    Exit;
  FSweepAngle := PPGCheckRange(Self, 'SweepAngle', Value, 10, 360);
  Invalidate;
end;

procedure TPPGCustomGauge.SetThickness(const Value: Integer);
begin
  if FThickness = Value then
    Exit;
  FThickness := PPGCheckRange(Self, 'Thickness', Value, 0, 200);
  Invalidate;
end;

procedure TPPGCustomGauge.SetRanges(const Value: TPPGGaugeRanges);
begin
  FRanges.Assign(Value);
end;

procedure TPPGCustomGauge.SetValueColorFromRange(const Value: Boolean);
begin
  if FValueColorFromRange <> Value then
  begin
    FValueColorFromRange := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomGauge.SetShowTarget(const Value: Boolean);
begin
  if FShowTarget <> Value then
  begin
    FShowTarget := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomGauge.SetTargetValue(const Value: Double);
begin
  PPGCheckFinite(Self, 'TargetValue', Value);
  if FTargetValue <> Value then
  begin
    FTargetValue := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomGauge.SetShowValue(const Value: Boolean);
begin
  if FShowValue <> Value then
  begin
    FShowValue := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomGauge.SetValueFormat(const Value: string);
begin
  if FValueFormat <> Value then
  begin
    FValueFormat := Value;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
  end;
end;

procedure TPPGCustomGauge.SetUnits(const Value: string);
begin
  if FUnits <> Value then
  begin
    FUnits := Value;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
  end;
end;

procedure TPPGCustomGauge.SetValueColor(const Value: TColor);
begin
  if FValueColor <> Value then
  begin
    FValueColor := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomGauge.SetReadOnly(const Value: Boolean);
begin
  if FReadOnly <> Value then
  begin
    FReadOnly := Value;
    // Schieberegler sind per Tab erreichbar, Anzeigen nicht
    if not (csLoading in ComponentState) then
      TabStop := not FReadOnly;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
  end;
end;

procedure TPPGCustomGauge.SetIncrement(const Value: Double);
begin
  // Zur Laufzeit Exception, beim DFM-Laden protokollieren und Wert behalten
  FIncrement := PPGCheckFloat(Self, 'Increment', Value, Value > 0, FIncrement);
end;

function TPPGCustomGauge.IsMinStored: Boolean;
begin
  Result := FMin <> 0;
end;

function TPPGCustomGauge.IsMaxStored: Boolean;
begin
  Result := FMax <> 100;
end;

function TPPGCustomGauge.IsValueStored: Boolean;
begin
  Result := FValue <> 0;
end;

function TPPGCustomGauge.IsTargetStored: Boolean;
begin
  Result := FTargetValue <> 0;
end;

function TPPGCustomGauge.IsIncrementStored: Boolean;
begin
  Result := FIncrement <> 1;
end;

function TPPGCustomGauge.IsValueFormatStored: Boolean;
begin
  Result := FValueFormat <> DefaultValueFormat;
end;

procedure TPPGCustomGauge.CMTextChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_NAMECHANGE);
end;

function TPPGCustomGauge.ValueText(V: Double): string;
begin
  if FValueFormat = '' then
    Result := FloatToStr(V)
  else
    Result := FormatFloat(FValueFormat, V);
  Result := Result + FUnits;
end;

function TPPGCustomGauge.AngleOfValue(V: Double): Single;
begin
  if FMax <= FMin then
    Result := FStartAngle
  else
    Result := FStartAngle + FSweepAngle * (ClampValue(V) - FMin) / (FMax - FMin);
end;

procedure TPPGCustomGauge.GetGeometry(out Center: TPoint; out Radius, Thick: Integer);
var
  MinX, MaxX, MinY, MaxY, A, S, C, T, Scale: Double;
  I, Steps, W, H: Integer;
begin
  // Ausdehnung des Bogens auf dem Einheitskreis -> groesster passender Radius
  MinX := 0;
  MaxX := 0;
  MinY := 0;
  MaxY := 0;
  Steps := FSweepAngle;
  for I := 0 to Steps do
  begin
    A := (FStartAngle + FSweepAngle * I / Steps - 90) * Pi / 180;
    C := Cos(A);
    S := Sin(A);
    if I = 0 then
    begin
      MinX := C;
      MaxX := C;
      MinY := S;
      MaxY := S;
    end
    else
    begin
      MinX := System.Math.Min(MinX, C);
      MaxX := System.Math.Max(MaxX, C);
      MinY := System.Math.Min(MinY, S);
      MaxY := System.Math.Max(MaxY, S);
    end;
  end;
  // Mittelpunkt gehoert immer dazu (Platz fuer den Werttext)
  MinX := System.Math.Min(MinX, 0);
  MaxX := System.Math.Max(MaxX, 0);
  MinY := System.Math.Min(MinY, 0);
  MaxY := System.Math.Max(MaxY, 0);
  // Strichstaerke relativ zum Radius (Auto: 12 %), halb nach aussen
  T := 0.12;
  W := ClientWidth;
  H := ClientHeight;
  Scale := System.Math.Min(W / (MaxX - MinX + T), H / (MaxY - MinY + T));
  if FThickness > 0 then
  begin
    Thick := PPGScale(FThickness, ScalePPI);
    Scale := System.Math.Min((W - Thick) / (MaxX - MinX), (H - Thick) / (MaxY - MinY));
  end
  else
    Thick := Round(Scale * T);
  if Thick < 2 then
    Thick := 2;
  if Scale < 1 then
    Scale := 1;
  Radius := Round(Scale);
  Center.X := Round((W - (MaxX - MinX) * Scale) / 2 - MinX * Scale);
  Center.Y := Round((H - (MaxY - MinY) * Scale) / 2 - MinY * Scale);
end;

function TPPGCustomGauge.ValueAtPoint(X, Y: Integer): Double;
var
  C: TPoint;
  R, T: Integer;
  A, Rel: Double;
begin
  GetGeometry(C, R, T);
  A := ArcTan2(Y - C.Y, X - C.X) * 180 / Pi + 90; // 0 = oben, im Uhrzeigersinn
  Rel := A - FStartAngle;
  while Rel < 0 do
    Rel := Rel + 360;
  while Rel >= 360 do
    Rel := Rel - 360;
  if Rel > FSweepAngle then
  begin
    // Ausserhalb des Bogens: naeheres Ende
    if Rel - FSweepAngle < 360 - Rel then
      Rel := FSweepAngle
    else
      Rel := 0;
  end;
  Result := FMin + (FMax - FMin) * Rel / FSweepAngle;
end;

function TPPGCustomGauge.ArcColor(V: Double): TColor;
var
  Rg: TPPGGaugeRange;
begin
  if HighContrastSupport and PPGIsHighContrast then
    Exit(PPGColorToRGB(clHighlight));
  if not Enabled then
    Exit(Tokens.TextDisabled);
  if FValueColor <> clDefault then
    Exit(PPGColorToRGB(FValueColor));
  if FValueColorFromRange then
  begin
    Rg := FRanges.RangeAt(V);
    if Rg <> nil then
      Exit(RangeColorOf(Tokens, Rg.Kind, Rg.Color));
  end;
  Result := PPGColorToRGB(EffectiveAppearance.FocusColor);
end;

procedure TPPGCustomGauge.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  C: TPoint;
  Rad, Th, I, PPI, TextTop: Integer;
  Pts: TArray<TPoint>;
  Track, Bg, TextCol, SecCol, RC: TColor;
  T: TPPGTokens;
  HC: Boolean;
  DV, A0, A1, Ang: Single;
  Rg: TPPGGaugeRange;
  VF: TFont;
  S: TSize;
  TR: TRect;
  Txt: string;
  P1, P2: TPoint;
begin
  T := Tokens;
  PPI := ScalePPI;
  HC := HighContrastSupport and PPGIsHighContrast;
  GetGeometry(C, Rad, Th);
  if Rad < 4 then
    Exit;
  Bg := PPGColorToRGB(GetBackgroundColor);
  if HC then
  begin
    Track := PPGColorToRGB(clGrayText);
    TextCol := PPGColorToRGB(clWindowText);
    SecCol := TextCol;
  end
  else
  begin
    Track := PPGBlendColor(Bg, T.TextPrimary, 0.12);
    if Enabled then
      TextCol := T.TextPrimary
    else
      TextCol := T.TextDisabled;
    SecCol := T.TextSecondary;
    if not Enabled then
      SecCol := T.TextDisabled;
  end;
  // Spur
  PPGShapeArcPoints(C, Rad, FStartAngle, FSweepAngle, Pts);
  ACanvas.DrawPolyline(Pts, Th, Track, 255);
  // Abschnitte als getoente Spur
  if not HC then
    for I := 0 to FRanges.Count - 1 do
    begin
      Rg := FRanges[I];
      A0 := AngleOfValue(System.Math.Min(Rg.StartValue, Rg.EndValue));
      A1 := AngleOfValue(System.Math.Max(Rg.StartValue, Rg.EndValue));
      if A1 - A0 < 0.5 then
        Continue;
      RC := RangeColorOf(T, Rg.Kind, Rg.Color);
      if not Enabled then
        RC := T.TextDisabled;
      PPGShapeArcPoints(C, Rad, A0, A1 - A0, Pts);
      ACanvas.DrawPolyline(Pts, Th, PPGBlendColor(Bg, RC, 0.35), 255);
    end;
  // Wertbogen
  DV := DisplayValue;
  Ang := AngleOfValue(DV) - FStartAngle;
  if Ang > 0.5 then
  begin
    PPGShapeArcPoints(C, Rad, FStartAngle, Ang, Pts);
    ACanvas.DrawPolyline(Pts, Th, ArcColor(DV), 255);
  end;
  // Zielmarke: Strich quer ueber die Spur
  if FShowTarget then
  begin
    Ang := (AngleOfValue(FTargetValue) - 90) * Pi / 180;
    P1 := Point(C.X + Round((Rad - Th) * Cos(Ang)), C.Y + Round((Rad - Th) * Sin(Ang)));
    P2 := Point(C.X + Round((Rad + Th) * Cos(Ang)), C.Y + Round((Rad + Th) * Sin(Ang)));
    ACanvas.DrawPolyline([P1, P2], System.Math.Max(PPGScale(2, PPI), 2), TextCol, 255);
  end;
  // Fokus: Ring um die Spur (nur als Schieberegler)
  if not FReadOnly and FocusVisible then
  begin
    PPGShapeArcPoints(C, Rad + Th div 2 + PPGScale(3, PPI), FStartAngle, FSweepAngle, Pts);
    ACanvas.DrawPolyline(Pts, System.Math.Max(PPGScale(1, PPI), 1),
      PPGColorToRGB(EffectiveAppearance.FocusColor), 255);
  end;
  // Werttext und Beschriftung
  if FShowValue or (Caption <> '') then
  begin
    VF := TFont.Create;
    try
      if FValueStyle.HasOwnFont then
      begin
        VF.Assign(FValueStyle.Font);
        VF.PixelsPerInch := Font.PixelsPerInch;
        VF.Size := FValueStyle.Font.Size;
        VF.Style := FValueStyle.Font.Style + FValueStyle.FontStyle;
      end
      else
      begin
        VF.Assign(Font);
        VF.Style := [fsBold] + FValueStyle.FontStyle;
        VF.Height := -System.Math.Max(Round(Rad * 0.42), 8);
      end;
      if not (HighContrastSupport and PPGIsHighContrast) and not UseVclStyle and Enabled then
        TextCol := FValueStyle.TextFor(UseDarkMode, TextCol);
      TextTop := C.Y;
      if FShowValue then
      begin
        Txt := ValueText(DV);
        S := ACanvas.MeasureText(Txt, VF, 0, False);
        // Halbrund (nichts unter dem Mittelpunkt): Text ueber dem Mittelpunkt
        if C.Y + Th >= ClientR.Bottom - S.cy div 2 then
          TextTop := C.Y - S.cy
        else
          TextTop := C.Y - S.cy div 2;
        TR := Rect(C.X - Rad, TextTop, C.X + Rad, TextTop + S.cy);
        ACanvas.DrawText(TR, Txt, VF, TextCol, DT_CENTER or DT_SINGLELINE or DT_NOPREFIX);
        TextTop := TR.Bottom;
      end;
      if Caption <> '' then
      begin
        S := ACanvas.MeasureText(Caption, Font, 0, False);
        TR := Rect(C.X - Rad, TextTop, C.X + Rad, TextTop + S.cy);
        if TR.Bottom > ClientR.Bottom then
          OffsetRect(TR, 0, ClientR.Bottom - TR.Bottom);
        ACanvas.DrawText(TR, Caption, Font, SecCol, DT_CENTER or DT_SINGLELINE or
          DT_END_ELLIPSIS or DT_NOPREFIX);
      end;
    finally
      VF.Free;
    end;
  end;
end;

procedure TPPGCustomGauge.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if FReadOnly or (Button <> mbLeft) or not Enabled then
    Exit;
  if CanFocus then
    SetFocus;
  FDragging := True;
  UserSetValue(ValueAtPoint(X, Y));
end;

procedure TPPGCustomGauge.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if FDragging and (ssLeft in Shift) then
    UserSetValue(ValueAtPoint(X, Y));
end;

procedure TPPGCustomGauge.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FDragging := False;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TPPGCustomGauge.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if not FReadOnly and Enabled then
    case Key of
      VK_LEFT, VK_DOWN:
        begin
          UserSetValue(FValue - FIncrement);
          Key := 0;
        end;
      VK_RIGHT, VK_UP:
        begin
          UserSetValue(FValue + FIncrement);
          Key := 0;
        end;
      VK_NEXT:
        begin
          UserSetValue(FValue - 10 * FIncrement);
          Key := 0;
        end;
      VK_PRIOR:
        begin
          UserSetValue(FValue + 10 * FIncrement);
          Key := 0;
        end;
      VK_HOME:
        begin
          UserSetValue(FMin);
          Key := 0;
        end;
      VK_END:
        begin
          UserSetValue(FMax);
          Key := 0;
        end;
    end;
  inherited KeyDown(Key, Shift);
end;

procedure TPPGCustomGauge.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  if not FReadOnly then
    Message.Result := Message.Result or DLGC_WANTARROWS;
end;

function TPPGCustomGauge.AccRole: Integer;
begin
  if FReadOnly then
    Result := ROLE_SYSTEM_PROGRESSBAR
  else
    Result := ROLE_SYSTEM_SLIDER;
end;

function TPPGCustomGauge.AccState: Integer;
begin
  Result := inherited AccState;
  if FReadOnly then
    Result := Result or STATE_SYSTEM_READONLY;
end;

function TPPGCustomGauge.AccValue: string;
begin
  Result := ValueText(FValue);
end;

{ TPPGCustomKpiTile }

const
  TilePad = 12;    // logische px Innenabstand
  TileGap = 4;

procedure TPPGCustomKpiTile.SetValueStyle(const Value: TPPGElementStyle);
begin
  FValueStyle.Assign(Value);
end;

procedure TPPGCustomKpiTile.ValueStyleChanged(Sender: TObject);
begin
  RequestAutoSize;
  Realign;
  Invalidate;
end;

procedure TPPGCustomKpiTile.SetTitleStyle(const Value: TPPGElementStyle);
begin
  FTitleStyle.Assign(Value);
end;

procedure TPPGCustomKpiTile.TitleStyleChanged(Sender: TObject);
begin
  RequestAutoSize;
  Realign;
  Invalidate;
end;

constructor TPPGCustomKpiTile.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTitleStyle := TPPGElementStyle.Create(Self);
  FTitleStyle.OnChange := TitleStyleChanged;
  FValueStyle := TPPGElementStyle.Create(Self);
  FValueStyle.OnChange := ValueStyleChanged;
  ControlStyle := ControlStyle - [csSetCaption, csDoubleClicks];
  FValueFormat := DefaultKpiFormat;
  FChangeFormat := DefaultChangeFormat;
  FShowChange := True;
  FSparklineKind := skArea;
  FShowSparkline := True;
  TabStop := True;
  Width := 200;
  Height := 120;
end;

destructor TPPGCustomKpiTile.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FTitleStyle);
  FreeAndNil(FValueStyle);
end;

procedure TPPGCustomKpiTile.Changed;
begin
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
end;

procedure TPPGCustomKpiTile.SetTitle(const Value: string);
begin
  if FTitle <> Value then
  begin
    FTitle := Value;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_NAMECHANGE);
  end;
end;

procedure TPPGCustomKpiTile.SetValue(const Value: Double);
begin
  if FValue <> Value then
  begin
    FValue := Value;
    Changed;
  end;
end;

procedure TPPGCustomKpiTile.SetValueText(const Value: string);
begin
  if FValueText <> Value then
  begin
    FValueText := Value;
    Changed;
  end;
end;

procedure TPPGCustomKpiTile.SetValueFormat(const Value: string);
begin
  if FValueFormat <> Value then
  begin
    FValueFormat := Value;
    Changed;
  end;
end;

procedure TPPGCustomKpiTile.SetUnits(const Value: string);
begin
  if FUnits <> Value then
  begin
    FUnits := Value;
    Changed;
  end;
end;

procedure TPPGCustomKpiTile.SetChange(const Value: Double);
begin
  if FChange <> Value then
  begin
    FChange := Value;
    Changed;
  end;
end;

procedure TPPGCustomKpiTile.SetChangeFormat(const Value: string);
begin
  if FChangeFormat <> Value then
  begin
    FChangeFormat := Value;
    Changed;
  end;
end;

procedure TPPGCustomKpiTile.SetShowChange(const Value: Boolean);
begin
  if FShowChange <> Value then
  begin
    FShowChange := Value;
    Changed;
  end;
end;

procedure TPPGCustomKpiTile.SetInvertTrend(const Value: Boolean);
begin
  if FInvertTrend <> Value then
  begin
    FInvertTrend := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomKpiTile.SetSparklineKind(const Value: TPPGSparklineKind);
begin
  if FSparklineKind <> Value then
  begin
    FSparklineKind := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomKpiTile.SetShowSparkline(const Value: Boolean);
begin
  if FShowSparkline <> Value then
  begin
    FShowSparkline := Value;
    Invalidate;
  end;
end;

function TPPGCustomKpiTile.GetSparklineText: string;
begin
  Result := PPGFormatValueList(FSparkline);
end;

procedure TPPGCustomKpiTile.SetSparklineText(const Value: string);
var
  V: TArray<Double>;
begin
  if not PPGParseValueList(Value, V) then
  begin
    if not PPGIsLoading(Self) then
      raise EPPGPropertyError.CreateInvalid(Self, 'SparklineText', Value);
    TPPGErrorHandler.LogWarning(Self, Format(PPGStr(@SPPGInvalidValueList), [Value]));
    Exit;
  end;
  SetSparkline(V);
end;

procedure TPPGCustomKpiTile.SetSparkline(const AValues: array of Double);
var
  I: Integer;
begin
  SetLength(FSparkline, Length(AValues));
  for I := 0 to High(AValues) do
    FSparkline[I] := AValues[I];
  Invalidate;
end;

function TPPGCustomKpiTile.IsValueStored: Boolean;
begin
  Result := FValue <> 0;
end;

function TPPGCustomKpiTile.IsChangeStored: Boolean;
begin
  Result := FChange <> 0;
end;

function TPPGCustomKpiTile.IsValueFormatStored: Boolean;
begin
  Result := FValueFormat <> DefaultKpiFormat;
end;

function TPPGCustomKpiTile.IsChangeFormatStored: Boolean;
begin
  Result := FChangeFormat <> DefaultChangeFormat;
end;

function TPPGCustomKpiTile.Trend: TPPGTrend;
begin
  if FChange > 0 then
    Result := trUp
  else if FChange < 0 then
    Result := trDown
  else
    Result := trNone;
end;

function TPPGCustomKpiTile.ChangeColor: TColor;
var
  T: TPPGTokens;
  Good: Boolean;
begin
  T := Tokens;
  if HighContrastSupport and PPGIsHighContrast then
    Exit(PPGColorToRGB(clWindowText));
  if not Enabled then
    Exit(T.TextDisabled);
  if Trend = trNone then
    Exit(T.TextSecondary);
  Good := (Trend = trUp) <> FInvertTrend;
  if Good then
    Result := T.Success
  else
    Result := T.Danger;
end;

function TPPGCustomKpiTile.DisplayValueText: string;
begin
  if FValueText <> '' then
    Result := FValueText
  else if FValueFormat = '' then
    Result := FloatToStr(FValue)
  else
    Result := FormatFloat(FValueFormat, FValue);
  if FUnits <> '' then
    Result := Result + ' ' + FUnits;
end;

function TPPGCustomKpiTile.DisplayChangeText: string;
begin
  if FChangeFormat = '' then
    Result := FloatToStr(FChange)
  else
    Result := FormatFloat(FChangeFormat, FChange);
end;

procedure TPPGCustomKpiTile.GetLayout(out TitleR, ValueR, ChangeR, SparkR: TRect);
var
  PPI, Pad, Gap, TH, VH, CH: Integer;
  Inner: TRect;
  Temp: TFont;
begin
  PPI := ScalePPI;
  Pad := PPGScale(TilePad, PPI);
  Gap := PPGScale(TileGap, PPI);
  Inner := Rect(Pad, Pad, ClientWidth - Pad, ClientHeight - Pad);
  Temp := nil;
  try
    TH := PPGMeasureTextNoCanvas('Wg', PPGElementFont(FTitleStyle, Font, [], Temp), 0, False).cy;
  finally
    Temp.Free;
  end;
  VH := Round(TH * 1.9);
  if FShowChange then
    CH := TH
  else
    CH := 0;
  TitleR := Rect(Inner.Left, Inner.Top, Inner.Right, Inner.Top + TH);
  ValueR := Rect(Inner.Left, TitleR.Bottom + Gap, Inner.Right, TitleR.Bottom + Gap + VH);
  ChangeR := Rect(Inner.Left, ValueR.Bottom, Inner.Right, ValueR.Bottom + CH);
  SparkR := Rect(Inner.Left, ChangeR.Bottom + Gap, Inner.Right, Inner.Bottom);
  if not FShowSparkline or (Length(FSparkline) = 0) or
    (SparkR.Bottom - SparkR.Top < PPGScale(12, PPI)) then
    SparkR := Rect(0, 0, 0, 0);
end;

procedure TPPGCustomKpiTile.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  Style: TPPGSurfaceStyle;
  CR: IPPGContainerRenderer;
  TitleR, ValueR, ChangeR, SparkR, AR: TRect;
  T: TPPGTokens;
  TextCol, SecCol, ChCol: TColor;
  VF: TFont;
  PPI, A, CX, CY, Flags: Integer;
  Opt: TPPGSparklineOptions;
  HC: Boolean;
  Arrow: array[0..2] of TPoint;
  UseColors: Boolean;
begin
  PPI := ScalePPI;
  T := Tokens;
  HC := HighContrastSupport and PPGIsHighContrast;
  Style := GetCurrentStyle;
  Style.GlowAlpha := 0;
  if not Supports(Renderer, IPPGContainerRenderer, CR) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
      IPPGContainerRenderer, CR);
  CR.DrawContainer(ACanvas, ClientR, Style);
  if Style.Focused then
    Renderer.DrawFocus(ACanvas, ClientR, Style);

  TextCol := Style.TextColor;
  if HC then
    SecCol := TextCol
  else if Enabled then
    SecCol := PPGBlendColor(TextCol, Style.Color, 0.35)
  else
    SecCol := TextCol;
  GetLayout(TitleR, ValueR, ChangeR, SparkR);
  Flags := DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX or DT_VCENTER;
  if UseRightToLeftAlignment then
    Flags := Flags or DT_RIGHT or DT_RTLREADING;
  UseColors := not HC and not UseVclStyle and Enabled;
  VF := nil;
  try
    if UseColors then
      ACanvas.DrawText(TitleR, FTitle, PPGElementFont(FTitleStyle, Font, [], VF),
        FTitleStyle.TextFor(UseDarkMode, SecCol), Flags)
    else
      ACanvas.DrawText(TitleR, FTitle, PPGElementFont(FTitleStyle, Font, [], VF), SecCol, Flags);
  finally
    FreeAndNil(VF);
  end;

  VF := TFont.Create;
  try
    if FValueStyle.HasOwnFont then
    begin
      VF.Assign(FValueStyle.Font);
      VF.PixelsPerInch := Font.PixelsPerInch;
      VF.Size := FValueStyle.Font.Size;
      VF.Style := FValueStyle.Font.Style + FValueStyle.FontStyle;
    end
    else
    begin
      VF.Assign(Font);
      VF.Style := [fsBold] + FValueStyle.FontStyle;
      VF.Height := -Round((ValueR.Bottom - ValueR.Top) * 0.8);
    end;
    if UseColors then
      ACanvas.DrawText(ValueR, DisplayValueText, VF, FValueStyle.TextFor(UseDarkMode, TextCol), Flags)
    else
      ACanvas.DrawText(ValueR, DisplayValueText, VF, TextCol, Flags);
  finally
    VF.Free;
  end;

  if FShowChange and (ChangeR.Bottom > ChangeR.Top) then
  begin
    ChCol := ChangeColor;
    A := (ChangeR.Bottom - ChangeR.Top) div 3;
    if UseRightToLeftAlignment then
      CX := ChangeR.Right - A
    else
      CX := ChangeR.Left + A;
    CY := (ChangeR.Top + ChangeR.Bottom) div 2;
    case Trend of
      trUp:
        begin
          Arrow[0] := Point(CX - A, CY + A div 2 + 1);
          Arrow[1] := Point(CX + A, CY + A div 2 + 1);
          Arrow[2] := Point(CX, CY - A);
          PPGFillPolygon(ACanvas, Arrow, ChCol, 255);
        end;
      trDown:
        begin
          Arrow[0] := Point(CX - A, CY - A div 2 - 1);
          Arrow[1] := Point(CX + A, CY - A div 2 - 1);
          Arrow[2] := Point(CX, CY + A);
          PPGFillPolygon(ACanvas, Arrow, ChCol, 255);
        end;
    end;
    AR := ChangeR;
    if UseRightToLeftAlignment then
      AR.Right := AR.Right - 2 * A - PPGScale(TileGap, PPI)
    else
      AR.Left := AR.Left + 2 * A + PPGScale(TileGap, PPI);
    ACanvas.DrawText(AR, DisplayChangeText, Font, ChCol, Flags);
  end;

  if not IsRectEmpty(SparkR) then
  begin
    Opt := PPGDefaultSparklineOptions(T, Style.Color, PPI);
    Opt.Kind := FSparklineKind;
    if HC then
      Opt.Color := PPGColorToRGB(clHighlight)
    else if Enabled then
      Opt.Color := PPGColorToRGB(EffectiveAppearance.FocusColor)
    else
      Opt.Color := T.TextDisabled;
    if not Enabled then
      Opt.NegativeColor := T.TextDisabled;
    Opt.LineWidth := System.Math.Max(PPGScale(2, PPI), 1);
    PPGDrawSparkline(ACanvas, SparkR, FSparkline, Opt);
  end;
end;

procedure TPPGCustomKpiTile.KeyPress(var Key: Char);
begin
  inherited KeyPress(Key);
  if (Key = #13) and Enabled then
  begin
    Key := #0;
    Click;
  end;
end;

function TPPGCustomKpiTile.AccName: string;
begin
  Result := FTitle;
end;

function TPPGCustomKpiTile.AccRole: Integer;
begin
  if Assigned(OnClick) then
    Result := ROLE_SYSTEM_PUSHBUTTON
  else
    Result := ROLE_SYSTEM_STATICTEXT;
end;

function TPPGCustomKpiTile.AccValue: string;
begin
  Result := DisplayValueText;
  if FShowChange then
    Result := Result + ', ' + Format(PPGStr(@SPPGKpiChange), [DisplayChangeText]);
end;

end.
