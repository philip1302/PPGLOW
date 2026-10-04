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
    FOnStep: TNotifyEvent;
    FOwner: TObject;
    procedure Tick(Now: Cardinal);
  public
    constructor Create(AOwner: TObject);
    destructor Destroy; override;
    /// Startet eine Animation vom aktuellen Wert zum Zielwert.
    /// Duration = 0 setzt den Wert sofort (ohne Timer).
    procedure AnimateTo(ATarget: Single; ADurationMs: Cardinal;
      AEasing: TPPGEasing = ekSmooth);
    /// Endlosschleife: Value laeuft linear von 0 bis 1 und beginnt dann von
    /// vorn (z.B. Marquee). Laeuft bis Stop, Jump oder AnimateTo.
    procedure StartLoop(APeriodMs: Cardinal);
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
    property OnStep: TNotifyEvent read FOnStep write FOnStep;
  end;

/// Wendet eine Kurve auf T (0..1) an; Ergebnis 0..1, Anfang 0, Ende 1.
function PPGEase(Easing: TPPGEasing; T: Single): Single;
/// Systempruefungen (auch fuer Tests/Diagnose oeffentlich).
function PPGSystemAnimationsEnabled: Boolean;
function PPGIsRemoteSession: Boolean;
/// Anzahl gerade laufender Animationen (Diagnose/Tests).
function PPGRunningAnimationCount: Integer;

implementation

uses
  System.SysUtils, System.Generics.Collections, Winapi.Windows, Vcl.ExtCtrls,
  PPG.Types, PPG.ErrorHandler;

const
  AnimatorInterval = 15; // ms, ~60 fps

type
  TPPGAnimator = class
  private
    FTimer: TTimer;
    FItems: TList<TPPGAnimation>;
    FTicking: Boolean;
    procedure TimerTick(Sender: TObject);
    procedure UpdateTimer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(A: TPPGAnimation);
    procedure Remove(A: TPPGAnimation);
    function Count: Integer;
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

function PPGSystemAnimationsEnabled: Boolean;
var
  Enabled: BOOL;
begin
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
    Result := PPGSystemAnimationsEnabled and not PPGIsRemoteSession;
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
  FRunning := True;
  if not FRegistered then
  begin
    A.Add(Self);
    FRegistered := True;
  end;
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
  FRunning := True;
  if not FRegistered then
  begin
    A.Add(Self);
    FRegistered := True;
  end;
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
  FRunning := False;
  FLooping := False;
  if FRegistered then
  begin
    FRegistered := False;
    if GAnimator <> nil then
      GAnimator.Remove(Self);
  end;
end;

procedure TPPGAnimation.Tick(Now: Cardinal);
var
  Elapsed: Cardinal;
  T: Single;
begin
  if not FRunning then
    Exit;
  Elapsed := Now - FStartTick; // Cardinal-Arithmetik: korrekt auch bei Tick-Ueberlauf
  if FLooping then
    FValue := (Elapsed mod FDuration) / FDuration // linear, ohne Easing
  else if Elapsed >= FDuration then
  begin
    FValue := FTargetValue;
    Stop;
  end
  else
  begin
    T := Elapsed / FDuration;
    T := PPGEase(FEasing, T);
    FValue := FStartValue + (FTargetValue - FStartValue) * T;
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
  if FItems.IndexOf(A) < 0 then
    FItems.Add(A);
  UpdateTimer;
end;

procedure TPPGAnimator.Remove(A: TPPGAnimation);
begin
  FItems.Remove(A);
  if not FTicking then
    UpdateTimer;
end;

function TPPGAnimator.Count: Integer;
begin
  Result := FItems.Count;
end;

procedure TPPGAnimator.UpdateTimer;
begin
  FTimer.Enabled := FItems.Count > 0;
end;

procedure TPPGAnimator.TimerTick(Sender: TObject);
var
  Snapshot: TArray<TPPGAnimation>;
  A: TPPGAnimation;
  AOwner: TObject;
  I: Integer;
  Now: Cardinal;
begin
  if FTicking then
    Exit; // Reentranz (z.B. ProcessMessages in einem OnStep-Handler)
  FTicking := True;
  try
    // Kopie: OnStep darf Animationen stoppen, starten oder freigeben
    Snapshot := FItems.ToArray;
    Now := GetTickCount;
    for I := 0 to High(Snapshot) do
    begin
      A := Snapshot[I];
      if FItems.IndexOf(A) < 0 then
        Continue; // inzwischen abgemeldet/freigegeben
      AOwner := A.Owner; // vorher merken: OnStep kann A freigeben
      try
        A.Tick(Now);
      except
        on E: Exception do
        begin
          // Fehlerhafte Animation sofort stoppen, sonst kommt alle 15 ms
          // derselbe Fehlerdialog.
          if FItems.IndexOf(A) >= 0 then
            A.Stop;
          TPPGErrorHandler.HandleCallbackError(AOwner, E, 'Animation.Tick');
        end;
      end;
    end;
  finally
    FTicking := False;
    UpdateTimer;
  end;
end;

initialization

finalization
  GFinalized := True;
  FreeAndNil(GAnimator);

end.
