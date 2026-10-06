unit PPG.AppHooks;

{ Verteiler fuer Nachrichten der Anwendung (Phase 11a).

  Menues, Menueleiste, KeyTips und TeachingTips muessen Tasten und Mausklicks
  sehen, die an andere Fenster gehen (Fokus bleibt beim Formular, Popups
  werden nie aktiviert). Niemand ueberschreibt dafuer Application.OnMessage:
  ein internes TApplicationEvents (verteilt selbst an mehrere Empfaenger,
  ab XE2) ruft die hier angemeldeten Haken auf - der zuletzt angemeldete
  zuerst (oberstes Menue vor der Menueleiste). Setzt ein Haken Handled, ist
  die Nachricht verbraucht.

  Ein Haken darf sich in seinem Aufruf selbst abmelden (Liste wird kopiert).

  Beobachter fuer Controls (PPGWatchControl): TeachingTip und Tour folgen
  ihrem Ziel. Haengt sich einmal je Control in WindowProc ein (Hilfsobjekt,
  das dem Control gehoert und mit ihm stirbt) und meldet jede Nachricht nach
  der Verarbeitung an alle Empfaenger. Hat sich danach jemand anderes
  eingehaengt, bleibt das Hilfsobjekt als Durchreiche stehen (sonst wuerde
  dessen Kette brechen). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, Vcl.Controls;

type
  TPPGMessageHook = procedure(var Msg: TMsg; var Handled: Boolean) of object;
  /// Nach der Verarbeitung einer Nachricht des beobachteten Controls.
  TPPGControlWatchEvent = procedure(Control: TControl; var Message: TMessage) of object;

procedure PPGAddMessageHook(const Hook: TPPGMessageHook);
procedure PPGRemoveMessageHook(const Hook: TPPGMessageHook);
/// Anwendung verliert die Aktivierung (Alt+Tab, Klick in fremde Anwendung).
procedure PPGAddDeactivateHook(const Hook: TNotifyEvent);
procedure PPGRemoveDeactivateHook(const Hook: TNotifyEvent);
/// Anzahl angemeldeter Haken (Tests, Diagnose).
function PPGMessageHookCount: Integer;

/// Meldet alle Nachrichten an Control (nach dessen Verarbeitung) an Event.
procedure PPGWatchControl(Control: TControl; const Event: TPPGControlWatchEvent);
procedure PPGUnwatchControl(Control: TControl; const Event: TPPGControlWatchEvent);
/// Anzahl Empfaenger fuer Control (Tests).
function PPGControlWatchCount(Control: TControl): Integer;

implementation

uses
  System.SysUtils, Vcl.AppEvnts, PPG.ErrorHandler;

type
  THookHost = class(TComponent)
  private
    FEvents: TApplicationEvents;
    FMessageHooks: TArray<TMethod>;
    FDeactivateHooks: TArray<TMethod>;
    procedure AppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure AppDeactivate(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  GHost: THookHost = nil;

function SameMethod(const A, B: TMethod): Boolean;
begin
  Result := (A.Code = B.Code) and (A.Data = B.Data);
end;

constructor THookHost.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEvents := TApplicationEvents.Create(Self);
  FEvents.OnMessage := AppMessage;
  FEvents.OnDeactivate := AppDeactivate;
end;

procedure THookHost.AppMessage(var Msg: TMsg; var Handled: Boolean);
var
  Copy: TArray<TMethod>;
  I: Integer;
begin
  if Length(FMessageHooks) = 0 then
    Exit;
  Copy := System.Copy(FMessageHooks);
  for I := High(Copy) downto 0 do
  begin
    try
      TPPGMessageHook(Copy[I])(Msg, Handled);
    except
      // Grenze: eine Exception im Haken darf die Nachrichtenschleife nicht
      // stoeren; gemeldet wird sie trotzdem
      on E: Exception do
        TPPGErrorHandler.HandleCallbackError(Self, E, 'PPG.AppHooks');
    end;
    if Handled then
      Exit;
  end;
end;

procedure THookHost.AppDeactivate(Sender: TObject);
var
  Copy: TArray<TMethod>;
  I: Integer;
begin
  Copy := System.Copy(FDeactivateHooks);
  for I := High(Copy) downto 0 do
    TNotifyEvent(Copy[I])(Sender);
end;

function Host: THookHost;
begin
  if GHost = nil then
    GHost := THookHost.Create(nil);
  Result := GHost;
end;

procedure AddMethod(var List: TArray<TMethod>; const M: TMethod);
var
  I, N: Integer;
begin
  for I := 0 to High(List) do
    if SameMethod(List[I], M) then
      Exit;
  N := Length(List);
  SetLength(List, N + 1);
  List[N] := M;
end;

procedure RemoveMethod(var List: TArray<TMethod>; const M: TMethod);
var
  I, J: Integer;
begin
  for I := High(List) downto 0 do
    if SameMethod(List[I], M) then
    begin
      for J := I to High(List) - 1 do
        List[J] := List[J + 1];
      SetLength(List, Length(List) - 1);
      Exit;
    end;
end;

procedure PPGAddMessageHook(const Hook: TPPGMessageHook);
var
  L: TArray<TMethod>;
begin
  L := Host.FMessageHooks;
  AddMethod(L, TMethod(Hook));
  Host.FMessageHooks := L;
end;

procedure PPGRemoveMessageHook(const Hook: TPPGMessageHook);
var
  L: TArray<TMethod>;
begin
  if GHost = nil then
    Exit;
  L := GHost.FMessageHooks;
  RemoveMethod(L, TMethod(Hook));
  GHost.FMessageHooks := L;
end;

procedure PPGAddDeactivateHook(const Hook: TNotifyEvent);
var
  L: TArray<TMethod>;
begin
  L := Host.FDeactivateHooks;
  AddMethod(L, TMethod(Hook));
  Host.FDeactivateHooks := L;
end;

procedure PPGRemoveDeactivateHook(const Hook: TNotifyEvent);
var
  L: TArray<TMethod>;
begin
  if GHost = nil then
    Exit;
  L := GHost.FDeactivateHooks;
  RemoveMethod(L, TMethod(Hook));
  GHost.FDeactivateHooks := L;
end;

function PPGMessageHookCount: Integer;
begin
  if GHost = nil then
    Result := 0
  else
    Result := Length(GHost.FMessageHooks);
end;

{ Beobachter }

type
  TControlWatcher = class(TComponent)
  private
    FControl: TControl;
    FOldProc: TWndMethod;
    FEvents: TArray<TMethod>;
    procedure WatchProc(var Message: TMessage);
    function IsTopOfChain: Boolean;
  public
    constructor Create(AControl: TControl); reintroduce;
    destructor Destroy; override;
  end;

constructor TControlWatcher.Create(AControl: TControl);
begin
  // Gehoert dem Control: wird mit ihm freigegeben
  inherited Create(AControl);
  FControl := AControl;
  FOldProc := AControl.WindowProc;
  AControl.WindowProc := WatchProc;
end;

function TControlWatcher.IsTopOfChain: Boolean;
var
  M: TWndMethod;
begin
  M := WatchProc;
  Result := (TMethod(FControl.WindowProc).Code = TMethod(M).Code) and
    (TMethod(FControl.WindowProc).Data = Self);
end;

destructor TControlWatcher.Destroy;
begin
  if (FControl <> nil) and IsTopOfChain then
    FControl.WindowProc := FOldProc;
  FEvents := nil;
  inherited Destroy;
end;

procedure TControlWatcher.WatchProc(var Message: TMessage);
var
  Copy: TArray<TMethod>;
  I: Integer;
begin
  FOldProc(Message);
  if Length(FEvents) = 0 then
    Exit;
  Copy := System.Copy(FEvents);
  for I := High(Copy) downto 0 do
    try
      TPPGControlWatchEvent(Copy[I])(FControl, Message);
    except
      on E: Exception do
        TPPGErrorHandler.HandleCallbackError(Self, E, 'PPG.AppHooks.PPGWatchControl');
    end;
end;

function FindWatcher(Control: TControl): TControlWatcher;
var
  I: Integer;
begin
  Result := nil;
  if Control = nil then
    Exit;
  for I := 0 to Control.ComponentCount - 1 do
    if Control.Components[I] is TControlWatcher then
      Exit(TControlWatcher(Control.Components[I]));
end;

procedure PPGWatchControl(Control: TControl; const Event: TPPGControlWatchEvent);
var
  W: TControlWatcher;
  L: TArray<TMethod>;
begin
  if Control = nil then
    Exit;
  W := FindWatcher(Control);
  if W = nil then
    W := TControlWatcher.Create(Control);
  L := W.FEvents;
  AddMethod(L, TMethod(Event));
  W.FEvents := L;
end;

procedure PPGUnwatchControl(Control: TControl; const Event: TPPGControlWatchEvent);
var
  W: TControlWatcher;
  L: TArray<TMethod>;
begin
  W := FindWatcher(Control);
  if W = nil then
    Exit;
  L := W.FEvents;
  RemoveMethod(L, TMethod(Event));
  W.FEvents := L;
  // Nur aushaengen, wenn niemand nach uns eingehaengt hat
  if (Length(L) = 0) and W.IsTopOfChain and
    not (csDestroying in Control.ComponentState) then
    W.Free;
end;

function PPGControlWatchCount(Control: TControl): Integer;
var
  W: TControlWatcher;
begin
  W := FindWatcher(Control);
  if W = nil then
    Result := 0
  else
    Result := Length(W.FEvents);
end;

initialization

finalization
  FreeAndNil(GHost);

end.
