unit PPG.Controls.Range;

{ TPPGCustomRangeControl - gemeinsame Basis fuer ProgressBar und TrackBar:
  Min/Max/Position, Validierung, Streaming, OnChange, Bruchteil-Berechnung.

  Validierung (bewusst wie die VCL, siehe Docs\Architektur.md):
  - Min > Max zur Laufzeit -> EPPGPropertyError, Objekt bleibt unveraendert.
    SetRange setzt beide Grenzen in einem Schritt.
  - Position ausserhalb von Min..Max wird STILL geklemmt (wie TProgressBar/
    TTrackBar). Code wie "Position := Position + 10" ist ueblich und darf
    am Ende des Bereichs nicht werfen.
  - Beim DFM-Laden werden Min, Max und Position roh uebernommen und erst in
    Loaded geprueft: die Reihenfolge in der DFM ist nicht garantiert
    (z.B. Min = 200 vor Max = 300 bei Vorgabe Max = 100).

  Ereignisse: OnChange bei jeder Aenderung von Position (Benutzer oder Code),
  nicht beim Laden. Der Zustand ist vor dem Aufruf bereits gesetzt.

  Arithmetik ueber Int64/Double: Max - Min kann den Integer-Bereich sprengen. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.Types, Vcl.Controls,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Base;

type
  TPPGCustomRangeControl = class(TPPGCustomControl)
  private
    FMin: Integer;
    FMax: Integer;
    FPosition: Integer;
    FOnChange: TNotifyEvent;
    procedure SetMin(const Value: Integer);
    procedure SetMax(const Value: Integer);
    procedure SetPosition(const Value: Integer);
  protected
    procedure Loaded; override;
    /// Position auf Min..Max begrenzen.
    function ClampPosition(Value: Int64): Integer;
    /// Zentrale Positionsaenderung (klemmt, Hook, Screenreader, OnChange).
    procedure SetPositionInternal(Value: Int64);
    /// Hook nach jeder Positionsaenderung (Animation, Neuzeichnen).
    procedure PositionChanged(OldPosition: Integer); virtual;
    /// Hook nach einer Aenderung von Min/Max.
    procedure RangeChanged; virtual;
    procedure DoChange; virtual;
    /// Anteil (0..1) eines Wertes am Bereich; Min = Max -> 0.
    function FractionOf(Value: Double): Double;
    /// Wert zu einem Anteil (0..1), gerundet und geklemmt.
    function ValueAt(Fraction: Double): Integer;
    function RangeRenderer: IPPGRangeRenderer;
    function AccValue: string; override;

    property Min: Integer read FMin write SetMin;
    property Max: Integer read FMax write SetMax;
    property Position: Integer read FPosition write SetPosition;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  public
    constructor Create(AOwner: TComponent); override;
    /// Setzt Min und Max gemeinsam (vermeidet die Reihenfolge-Falle).
    procedure SetRange(AMin, AMax: Integer);
  end;

implementation

uses
  PPG.Lang,
  System.SysUtils, Winapi.oleacc, PPG.Consts, PPG.Exceptions, PPG.ErrorHandler,
  PPG.Render.Registry;

{ TPPGCustomRangeControl }

constructor TPPGCustomRangeControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Kein csSetCaption: der Komponentenname soll nicht als Text erscheinen
  ControlStyle := ControlStyle - [csSetCaption, csDoubleClicks];
  FMin := 0;
  FMax := 100;
  FPosition := 0;
end;

procedure TPPGCustomRangeControl.Loaded;
begin
  inherited Loaded;
  // Erst jetzt sind Min, Max und Position vollstaendig gelesen
  if FMin > FMax then
  begin
    TPPGErrorHandler.LogWarning(Self, Format(PPGStr(@SPPGValueClamped),
      [FMax, PPGDisplayName(Self), 'Max', FMin]));
    FMax := FMin;
  end;
  FPosition := ClampPosition(FPosition);
  RangeChanged;
end;

function TPPGCustomRangeControl.ClampPosition(Value: Int64): Integer;
begin
  if Value < FMin then
    Result := FMin
  else if Value > FMax then
    Result := FMax
  else
    Result := Integer(Value);
end;

procedure TPPGCustomRangeControl.SetMin(const Value: Integer);
var
  V: Integer;
begin
  if PPGIsLoading(Self) then
  begin
    FMin := Value; // Pruefung in Loaded
    Exit;
  end;
  V := PPGCheckRange(Self, 'Min', Value, Low(Integer), FMax);
  if V = FMin then
    Exit;
  FMin := V;
  RangeChanged;
  SetPositionInternal(FPosition);
end;

procedure TPPGCustomRangeControl.SetMax(const Value: Integer);
var
  V: Integer;
begin
  if PPGIsLoading(Self) then
  begin
    FMax := Value;
    Exit;
  end;
  V := PPGCheckRange(Self, 'Max', Value, FMin, High(Integer));
  if V = FMax then
    Exit;
  FMax := V;
  RangeChanged;
  SetPositionInternal(FPosition);
end;

procedure TPPGCustomRangeControl.SetRange(AMin, AMax: Integer);
begin
  if AMin > AMax then
    raise EPPGPropertyError.CreateRange(Self, 'Min', AMin, Low(Integer), AMax);
  if (AMin = FMin) and (AMax = FMax) then
    Exit;
  FMin := AMin;
  FMax := AMax;
  RangeChanged;
  SetPositionInternal(FPosition);
end;

procedure TPPGCustomRangeControl.SetPosition(const Value: Integer);
begin
  if PPGIsLoading(Self) then
  begin
    FPosition := Value; // geklemmt wird in Loaded
    Exit;
  end;
  SetPositionInternal(Value);
end;

procedure TPPGCustomRangeControl.SetPositionInternal(Value: Int64);
var
  Old: Integer;
begin
  Old := FPosition;
  FPosition := ClampPosition(Value);
  if FPosition = Old then
    Exit;
  PositionChanged(Old);
  NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
  if not (csLoading in ComponentState) then
    DoChange;
end;

procedure TPPGCustomRangeControl.PositionChanged(OldPosition: Integer);
begin
  Invalidate;
end;

procedure TPPGCustomRangeControl.RangeChanged;
begin
  Invalidate;
end;

procedure TPPGCustomRangeControl.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TPPGCustomRangeControl.FractionOf(Value: Double): Double;
var
  Span: Int64;
begin
  Span := Int64(FMax) - FMin;
  if Span <= 0 then
    Exit(0);
  Result := (Value - FMin) / Span;
  if Result < 0 then
    Result := 0
  else if Result > 1 then
    Result := 1;
end;

function TPPGCustomRangeControl.ValueAt(Fraction: Double): Integer;
begin
  if Fraction < 0 then
    Fraction := 0
  else if Fraction > 1 then
    Fraction := 1;
  Result := ClampPosition(FMin + Round(Fraction * (Int64(FMax) - FMin)));
end;

function TPPGCustomRangeControl.RangeRenderer: IPPGRangeRenderer;
begin
  // Presets ohne eigene Darstellung -> Standard-Preset verwenden
  if not Supports(Renderer, IPPGRangeRenderer, Result) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
      IPPGRangeRenderer, Result);
end;

function TPPGCustomRangeControl.AccValue: string;
begin
  Result := IntToStr(FPosition);
end;

end.
