unit PPG.Animation;

{ Animationen fuer Zustandsuebergaenge (Hover-Glow, Farbwechsel).

  - TPPGAnimationSettings : published Einstellungen (Enabled, Duration)
  - TPPGAnimation         : ein Wert 0..1, der ueber die Zeit laeuft (gehoert dem Control)
  - Animator (intern)     : EIN gemeinsamer Timer fuer alle Animationen der
                            Anwendung, laeuft nur, solange etwas animiert wird.
                            Spart USER-Handles und CPU.

  Stolperfalle Finalisierung: Diese Unit wird VOR Vcl.Controls finalisiert,
  Formulare (und damit Controls) werden aber erst danach zerstoert. Deshalb
  meldet der Animator beim Finalisieren alle Animationen ab, und
  TPPGAnimation prueft vor jeder Abmeldung, ob der Animator noch existiert. }

{$I ..\PPG.inc}

interface

uses
  System.Classes;

const
  PPGDefaultAnimationDuration = 150;
  PPGMaxAnimationDuration = 5000;

type
  /// Bewegungskurven (Phase 8.5):
  /// - ekSmooth     : weich anfahren und abbremsen (Smoothstep) - Zustandswechsel
  /// - ekDecelerate : schnell starten, weich enden (Fluent "Decelerate") -
  ///                  Bewegung auf ein Ziel zu: Aufklappen, Unterstrich, Scrollen
  /// - ekLinear     : gleichmaessig (Schleifen, Fortschritt)
  TPPGEasing = (ekSmooth, ekDecelerate, ekLinear);

  TPPGAnimationSettings = class(TPersistent)
  private
    FOwner: TPersistent;
    FEnabled: Boolean;
    FDuration: Integer;
    FRespectSystemSettings: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetDuration(const Value: Integer);
    procedure SetEnabled(const Value: Boolean);
    procedure SetRespectSystemSettings(const Value: Boolean);
  protected
    procedure Changed;
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TPersistent);
    procedure Assign(Source: TPersistent); override;
    /// True, wenn tatsaechlich animiert werden soll (beruecksichtigt
    /// Systemeinstellung "Animationen anzeigen" und Remote-Desktop).
    function EffectiveEnabled: Boolean;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Duration: Integer read FDuration write SetDuration default PPGDefaultAnimationDuration;
    property RespectSystemSettings: Boolean read FRespectSystemSettings
      write SetRespectSystemSettings default True;
  end;

  TPPGAnimation = class
  private
    FStartValue: Single;
    FTargetValue: Single;
    FValue: Single;
    FStartTick: Cardinal;
    FDuration: Cardinal;
    FRunning: Boolean;
    FLooping: Boolean;
    FRegistered: Boolean;
    FEasing: TPPGEasing;
    FStepInterval: Cardinal;
    FLastStep: Cardinal;
    FOnStep: TNotifyEvent;
    FOwner: TObject;
    procedure Tick(Now: Cardinal);
    procedure UpdateValue(Now: Cardinal);
    function IsDue(Now: Cardinal): Boolean;
    function DueIn(Now: Cardinal): Cardinal;
  public
    constructor Create(AOwner: TObject);
    destructor Destroy; override;
    /// Startet eine Animation vom aktuellen Wert zum Zielwert.
    /// Duration = 0 setzt den Wert sofort (ohne Timer).
    procedure AnimateTo(ATarget: Single; ADurationMs: Cardinal;
      AEasing: TPPGEasing = ekSmooth);
    /// Endlosschleife: Value laeuft linear von 0 bis 1 und beginnt dann von
    /// vorn (z.B. Marquee). Laeuft bis Stop, Jump oder AnimateTo.
    procedure StartLoop(APeriodMs: Cardinal); overload;
    /// Wie StartLoop, mit Faelligkeitsmodus (StepInterval = AStepMs).
    procedure StartLoop(APeriodMs, AStepMs: Cardinal); overload;
    procedure Stop;
    /// Setzt den Wert sofort und stoppt eine laufende Animation.
    procedure Jump(AValue: Single);
    property Value: Single read FValue;
    property TargetValue: Single read FTargetValue;
    property Running: Boolean read FRunning;
    property Looping: Boolean read FLooping;
    /// Kurve der laufenden bzw. letzten Animation.
    property Easing: TPPGEasing read FEasing;
    property Owner: TObject read FOwner;
    /// Faelligkeitsmodus (Audit 8a #3): 0 = jeder Frame (~15 ms); sonst
    /// ruft der Animator OnStep nur alle StepInterval ms bzw. am Ende der
    /// Animation. Laeuft keine Frame-Animation, schlaeft der gemeinsame
    /// Timer bis zur naechsten Faelligkeit (lange Schleifen wie die
    /// Jetzt-Linie oder eine Lebensdauer wecken so nicht 67-mal je Sekunde).
    /// Value ist dazwischen der Stand des letzten Schritts; Stop rechnet ihn
    /// auf den aktuellen Zeitpunkt nach.
    property StepInterval: Cardinal read FStepInterval write FStepInterval;
    property OnStep: TNotifyEvent read FOnStep write FOnStep;
  end;

/// Wendet eine Kurve auf T (0..1) an; Ergebnis 0..1, Anfang 0, Ende 1.
function PPGEase(Easing: TPPGEasing; T: Single): Single;
type
  /// Ersatz fuer die Systemabfrage "Animationen erlaubt" (Tests).
  TPPGSystemAnimationsReader = function: Boolean;

/// Systempruefungen (auch fuer Tests/Diagnose oeffentlich).
function PPGSystemAnimationsEnabled: Boolean;
function PPGIsRemoteSession: Boolean;
/// Testhaken: ersetzt die Systemabfrage (Client-Animationen und
/// Remote-Sitzung) fuer PPGSystemAnimationsEnabled und
/// TPPGAnimationSettings.EffectiveEnabled (nil = System).
procedure PPGSetSystemAnimationsReader(Reader: TPPGSystemAnimationsReader);
/// Anzahl gerade laufender Animationen (Diagnose/Tests).
function PPGRunningAnimationCount: Integer;
/// Diagnose/Tests: aktuelles Intervall des gemeinsamen Timers in ms
/// (0 = Timer aus) und Anzahl seiner bisherigen Ticks.
function PPGAnimatorInterval: Cardinal;
function PPGAnimatorTicks: Cardinal;

implementation

uses
  System.SysUtils, System.Generics.Collections, Winapi.Windows, Vcl.ExtCtrls,
  PPG.Types, PPG.ErrorHandler;

const
  AnimatorInterval = 15; // ms, ~60 fps
  // Faelligkeitsmodus: Timer und GetTickCount haben ~16 ms Aufloesung; ein
  // Schritt gilt so viel frueher als faellig (sonst ein zweiter Wakeup je
  // Periode, nur um die letzten Millisekunden abzuwarten)
  DueSlack = 16;

type
  TPPGAnimator = class
  private
    FTimer: TTimer;
    FItems: TList<TPPGAnimation>;
    FTicking: Boolean;
    /// Kopie der Liste waehrend TimerTick; abgemeldete Eintraege werden
    /// darin auf nil gesetzt (statt IndexOf je Eintrag und Tick).
    FSnapshot: TArray<TPPGAnimation>;
    FTickIndex: Integer;
    FTicks: Cardinal;
    procedure TimerTick(Sender: TObject);
    procedure UpdateTimer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(A: TPPGAnimation);
    procedure Remove(A: TPPGAnimation);
    function Count: Integer;
    function Interval: Cardinal;
  end;

var
  GAnimator: TPPGAnimator = nil;
  GFinalized: Boolean = False;

function Animator: TPPGAnimator;
begin
  if (GAnimator = nil) and not GFinalized then
    GAnimator := TPPGAnimator.Create;
  Result := GAnimator;
end;

var
  GSystemAnimationsReader: TPPGSystemAnimationsReader = nil;

procedure PPGSetSystemAnimationsReader(Reader: TPPGSystemAnimationsReader);
begin
  GSystemAnimationsReader := Reader;
end;

function PPGSystemAnimationsEnabled: Boolean;
var
  Enabled: BOOL;
begin
  if Assigned(GSystemAnimationsReader) then
    Exit(GSystemAnimationsReader());
  // SPI_GETCLIENTAREAANIMATION = $1042 (ab Vista). Schlaegt der Aufruf fehl,
  // gehen wir von "an" aus.
  Enabled := True;
  if SystemParametersInfo($1042, 0, @Enabled, 0) then
    Result := Enabled
  else
    Result := True;
end;

function PPGIsRemoteSession: Boolean;
begin
  Result := GetSystemMetrics(SM_REMOTESESSION) <> 0;
end;

function PPGEase(Easing: TPPGEasing; T: Single): Single;
var
  U: Single;
begin
  T := PPGClampSingle(T, 0, 1);
  case Easing of
    ekDecelerate:
      begin
        // Ease-out (Quart): Annaeherung an Fluent cubic-bezier(0, 0, 0, 1)
        U := 1 - T;
        Result := 1 - U * U * U * U;
      end;
    ekLinear:
      Result := T;
  else
    Result := T * T * (3 - 2 * T); // Smoothstep
  end;
end;

function PPGRunningAnimationCount: Integer;
begin
  if GAnimator = nil then
    Result := 0
  else
    Result := GAnimator.Count;
end;

function PPGAnimatorInterval: Cardinal;
begin
  if GAnimator = nil then
    Result := 0
  else
    Result := GAnimator.Interval;
end;

function PPGAnimatorTicks: Cardinal;
begin
  if GAnimator = nil then
    Result := 0
  else
    Result := GAnimator.FTicks;
end;

{ TPPGAnimationSettings }

constructor TPPGAnimationSettings.Create(AOwner: TPersistent);
begin
  inherited Create;
  FOwner := AOwner;
  FEnabled := True;
  FDuration := PPGDefaultAnimationDuration;
  FRespectSystemSettings := True;
end;

function TPPGAnimationSettings.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TPPGAnimationSettings.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGAnimationSettings.Assign(Source: TPersistent);
begin
  if Source is TPPGAnimationSettings then
  begin
    FEnabled := TPPGAnimationSettings(Source).FEnabled;
    FDuration := TPPGAnimationSettings(Source).FDuration;
    FRespectSystemSettings := TPPGAnimationSettings(Source).FRespectSystemSettings;
    Changed;
  end
  else
    inherited Assign(Source);
end;

function TPPGAnimationSettings.EffectiveEnabled: Boolean;
begin
  Result := FEnabled and (FDuration > 0);
  if Result and FRespectSystemSettings then
  begin
    if Assigned(GSystemAnimationsReader) then
      Result := GSystemAnimationsReader()
    else
      Result := PPGSystemAnimationsEnabled and not PPGIsRemoteSession;
  end;
end;

procedure TPPGAnimationSettings.SetDuration(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'Duration', Value, 0, PPGMaxAnimationDuration);
  if FDuration <> V then
  begin
    FDuration := V;
    Changed;
  end;
end;

procedure TPPGAnimationSettings.SetEnabled(const Value: Boolean);
begin
  if FEnabled <> Value then
  begin
    FEnabled := Value;
    Changed;
  end;
end;

procedure TPPGAnimationSettings.SetRespectSystemSettings(const Value: Boolean);
begin
  if FRespectSystemSettings <> Value then
  begin
    FRespectSystemSettings := Value;
    Changed;
  end;
end;

{ TPPGAnimation }

constructor TPPGAnimation.Create(AOwner: TObject);
begin
  inherited Create;
  FOwner := AOwner;
end;

destructor TPPGAnimation.Destroy;
begin
  FOnStep := nil;
  Stop;
  inherited Destroy;
end;

procedure TPPGAnimation.AnimateTo(ATarget: Single; ADurationMs: Cardinal;
  AEasing: TPPGEasing);
var
  A: TPPGAnimator;
begin
  FEasing := AEasing;
  ATarget := PPGClampSingle(ATarget, 0, 1);
  if (ADurationMs = 0) or (Abs(ATarget - FValue) < 0.001) then
  begin
    Jump(ATarget);
    Exit;
  end;
  A := Animator;
  if A = nil then // Anwendung wird beendet -> ohne Animation
  begin
    Jump(ATarget);
    Exit;
  end;
  FLooping := False;
  FStartValue := FValue;
  FTargetValue := ATarget;
  // Restdauer proportional zum verbleibenden Weg (sanftes Umkehren bei
  // schnellem Hover-Wechsel)
  FDuration := Round(ADurationMs * Abs(ATarget - FValue));
  if FDuration < AnimatorInterval then
    FDuration := AnimatorInterval;
  FStartTick := GetTickCount;
  FLastStep := FStartTick;
  FRunning := True;
  if not FRegistered then
  begin
    FRegistered := True;
    A.Add(Self);
  end
  else
    A.UpdateTimer; // neues Ende bzw. Frame-Animation: Timer anpassen
end;

procedure TPPGAnimation.StartLoop(APeriodMs, AStepMs: Cardinal);
begin
  FStepInterval := AStepMs;
  StartLoop(APeriodMs);
end;

procedure TPPGAnimation.StartLoop(APeriodMs: Cardinal);
var
  A: TPPGAnimator;
begin
  if APeriodMs < AnimatorInterval then
    APeriodMs := AnimatorInterval;
  // Laufende Schleife mit gleicher Periode nicht neu starten (kein Ruckeln)
  if FLooping and FRunning and (FDuration = APeriodMs) then
    Exit;
  A := Animator;
  if A = nil then // Anwendung wird beendet
    Exit;
  FLooping := True;
  FDuration := APeriodMs;
  FStartTick := GetTickCount;
  FLastStep := FStartTick;
  FRunning := True;
  if not FRegistered then
  begin
    FRegistered := True;
    A.Add(Self);
  end
  else
    A.UpdateTimer;
end;

procedure TPPGAnimation.Jump(AValue: Single);
var
  Changed: Boolean;
begin
  Stop;
  AValue := PPGClampSingle(AValue, 0, 1);
  Changed := Abs(AValue - FValue) > 0.0001;
  FValue := AValue;
  FTargetValue := AValue;
  if Changed and Assigned(FOnStep) then
    FOnStep(Self);
end;

procedure TPPGAnimation.Stop;
begin
  // Faelligkeitsmodus: Value auf den Zeitpunkt des Anhaltens nachziehen
  // (z.B. Restdauer einer pausierten Lebensdauer)
  if FRunning and (FStepInterval > 0) then
    UpdateValue(GetTickCount);
  FRunning := False;
  FLooping := False;
  if FRegistered then
  begin
    FRegistered := False;
    if GAnimator <> nil then
      GAnimator.Remove(Self);
  end;
end;

procedure TPPGAnimation.UpdateValue(Now: Cardinal);
var
  Elapsed: Cardinal;
  T: Single;
begin
  Elapsed := Now - FStartTick; // Cardinal-Arithmetik: korrekt auch bei Tick-Ueberlauf
  if FLooping then
    FValue := (Elapsed mod FDuration) / FDuration // linear, ohne Easing
  else if Elapsed >= FDuration then
    FValue := FTargetValue
  else
  begin
    T := Elapsed / FDuration;
    T := PPGEase(FEasing, T);
    FValue := FStartValue + (FTargetValue - FStartValue) * T;
  end;
end;

function TPPGAnimation.IsDue(Now: Cardinal): Boolean;
begin
  Result := (FStepInterval = 0) or (Now - FLastStep + DueSlack >= FStepInterval) or
    (not FLooping and (Now - FStartTick + DueSlack >= FDuration));
end;

function TPPGAnimation.DueIn(Now: Cardinal): Cardinal;
var
  E, Rest: Cardinal;
begin
  if not FRunning then
    Exit(High(Cardinal));
  if FStepInterval = 0 then
    Exit(0);
  E := Now - FLastStep;
  if E >= FStepInterval then
    Exit(0);
  Result := FStepInterval - E;
  if not FLooping then
  begin
    E := Now - FStartTick;
    if E >= FDuration then
      Exit(0);
    Rest := FDuration - E;
    if Rest < Result then
      Result := Rest;
  end;
end;

procedure TPPGAnimation.Tick(Now: Cardinal);
begin
  if not FRunning then
    Exit;
  FLastStep := Now;
  // Faelligkeitsmodus: innerhalb der Toleranz vor dem Ende = Ende
  if (FStepInterval > 0) and not FLooping and (Now - FStartTick + DueSlack >= FDuration) then
    Now := FStartTick + FDuration;
  UpdateValue(Now);
  if not FLooping and (Now - FStartTick >= FDuration) then
  begin
    FRunning := False; // Stop rechnet den Wert dann nicht nach
    Stop;
  end;
  if Assigned(FOnStep) then
    FOnStep(Self);
end;

{ TPPGAnimator }

constructor TPPGAnimator.Create;
begin
  inherited Create;
  FItems := TList<TPPGAnimation>.Create;
  FTimer := TTimer.Create(nil);
  FTimer.Enabled := False;
  FTimer.Interval := AnimatorInterval;
  FTimer.OnTimer := TimerTick;
end;

destructor TPPGAnimator.Destroy;
var
  I: Integer;
begin
  if FTimer <> nil then
    FTimer.Enabled := False;
  if FItems <> nil then
    for I := 0 to FItems.Count - 1 do
    begin
      FItems[I].FRegistered := False;
      FItems[I].FRunning := False;
    end;
  FTimer.Free;
  FItems.Free;
  inherited Destroy;
end;

procedure TPPGAnimator.Add(A: TPPGAnimation);
begin
  // Nur aus AnimateTo/StartLoop, wenn A noch nicht angemeldet ist
  // (FRegistered): kein IndexOf noetig
  FItems.Add(A);
  UpdateTimer;
end;

procedure TPPGAnimator.Remove(A: TPPGAnimation);
var
  I: Integer;
begin
  FItems.Remove(A);
  if FTicking then
  begin
    // In der Kopie des laufenden Ticks austragen (A kann gleich danach
    // freigegeben werden); meist ist es der gerade bearbeitete Eintrag
    if (FTickIndex >= 0) and (FTickIndex <= High(FSnapshot)) and (FSnapshot[FTickIndex] = A) then
      FSnapshot[FTickIndex] := nil
    else
      for I := 0 to High(FSnapshot) do
        if FSnapshot[I] = A then
        begin
          FSnapshot[I] := nil;
          Break;
        end;
  end
  else
    UpdateTimer;
end;

function TPPGAnimator.Count: Integer;
begin
  Result := FItems.Count;
end;

function TPPGAnimator.Interval: Cardinal;
begin
  if FTimer.Enabled then
    Result := FTimer.Interval
  else
    Result := 0;
end;

procedure TPPGAnimator.UpdateTimer;
var
  I: Integer;
  Now, D, Wait: Cardinal;
begin
  if FTicking then
    Exit; // TimerTick stellt den Timer am Ende ein
  if FItems.Count = 0 then
  begin
    FTimer.Enabled := False;
    Exit;
  end;
  // Frame-Takt, solange eine Animation jeden Frame braucht; sonst bis zur
  // fruehesten Faelligkeit schlafen (Audit 8a #3)
  Now := GetTickCount;
  Wait := High(Cardinal);
  for I := 0 to FItems.Count - 1 do
  begin
    D := FItems[I].DueIn(Now);
    if D < Wait then
      Wait := D;
    if Wait <= AnimatorInterval then
      Break;
  end;
  if Wait < AnimatorInterval then
    Wait := AnimatorInterval;
  if Wait > Cardinal(MaxInt) then
    Wait := Cardinal(MaxInt);
  if FTimer.Interval <> Wait then
    FTimer.Interval := Wait; // startet einen laufenden Timer neu
  FTimer.Enabled := True;
end;

procedure TPPGAnimator.TimerTick(Sender: TObject);
var
  A: TPPGAnimation;
  AOwner: TObject;
  I: Integer;
  Now: Cardinal;
begin
  if FTicking then
    Exit; // Reentranz (z.B. ProcessMessages in einem OnStep-Handler)
  FTicking := True;
  try
    Inc(FTicks);
    // Kopie: OnStep darf Animationen stoppen, starten oder freigeben;
    // abgemeldete Eintraege setzt Remove hier auf nil
    FSnapshot := FItems.ToArray;
    Now := GetTickCount;
    for I := 0 to High(FSnapshot) do
    begin
      A := FSnapshot[I];
      if (A = nil) or not A.IsDue(Now) then
        Continue; // inzwischen abgemeldet/freigegeben bzw. noch nicht faellig
      FTickIndex := I;
      AOwner := A.Owner; // vorher merken: OnStep kann A freigeben
      try
        A.Tick(Now);
      except
        on E: Exception do
        begin
          // Fehlerhafte Animation sofort stoppen, sonst kommt alle 15 ms
          // derselbe Fehlerdialog.
          if FSnapshot[I] <> nil then
            A.Stop;
          TPPGErrorHandler.HandleCallbackError(AOwner, E, 'Animation.Tick');
        end;
      end;
    end;
  finally
    FSnapshot := nil;
    FTickIndex := -1;
    FTicking := False;
    UpdateTimer;
  end;
end;

initialization

finalization
  GFinalized := True;
  FreeAndNil(GAnimator);

end.
