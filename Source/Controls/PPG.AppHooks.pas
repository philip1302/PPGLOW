unit PPG.AppHooks;

{ Verteiler fuer Nachrichten der Anwendung (Phase 11a).

  Menues, Menueleiste, KeyTips und TeachingTips muessen Tasten und Mausklicks
  sehen, die an andere Fenster gehen (Fokus bleibt beim Formular, Popups
  werden nie aktiviert). Niemand ueberschreibt dafuer Application.OnMessage:
  ein internes TApplicationEvents (verteilt selbst an mehrere Empfaenger,
  ab XE2) ruft die hier angemeldeten Haken auf - der zuletzt angemeldete
  zuerst (oberstes Menue vor der Menueleiste). Setzt ein Haken Handled, ist
  die Nachricht verbraucht.

  Ein Haken darf sich in seinem Aufruf selbst abmelden: Die Listen werden
  nie veraendert, An- und Abmelden legen eine neue an (copy-on-write); eine
  laufende Verteilung behaelt ihren Stand ohne Kopie je Nachricht.

  Beobachter fuer Controls (PPGWatchControl): TeachingTip und Tour folgen
  ihrem Ziel. Haengt sich einmal je Control in WindowProc ein (Hilfsobjekt,
  das dem Control gehoert und mit ihm stirbt) und meldet jede Nachricht nach
  der Verarbeitung an alle Empfaenger. Hat sich danach jemand anderes
  eingehaengt, bleibt das Hilfsobjekt als Durchreiche stehen (sonst wuerde
  dessen Kette brechen).
  Abmelden waehrend einer gemeldeten Nachricht (z.B. Popup schliesst beim
  Ausblenden des Formulars) gibt das Hilfsobjekt erst nach deren Ende frei. }

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
  // Nach der Finalisierung nicht neu anlegen (Formulare werden spaeter
  // abgebaut und melden sich dabei ab bzw. an): sonst Leck
  GFinalized: Boolean = False;

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
  List: TArray<TMethod>;
  I: Integer;
begin
  if Length(FMessageHooks) = 0 then
    Exit;
  // Audit 8D: nur eine Referenz (copy-on-write), keine Kopie je Nachricht
  List := FMessageHooks;
  for I := High(List) downto 0 do
  begin
    try
      TPPGMessageHook(List[I])(Msg, Handled);
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
  List: TArray<TMethod>;
  I: Integer;
begin
  List := FDeactivateHooks;
  for I := High(List) downto 0 do
    TNotifyEvent(List[I])(Sender);
end;

function Host: THookHost;
begin
  if (GHost = nil) and not GFinalized then
    GHost := THookHost.Create(nil);
  Result := GHost;
end;

procedure AddMethod(var List: TArray<TMethod>; const M: TMethod);
var
  I, N: Integer;
  NewList: TArray<TMethod>;
begin
  // Copy-on-write: immer eine neue Liste, die alte bleibt fuer eine
  // laufende Verteilung unveraendert
  for I := 0 to High(List) do
    if SameMethod(List[I], M) then
      Exit;
  N := Length(List);
  SetLength(NewList, N + 1);
  for I := 0 to N - 1 do
    NewList[I] := List[I];
  NewList[N] := M;
  List := NewList;
end;

procedure RemoveMethod(var List: TArray<TMethod>; const M: TMethod);
var
  I, J, K: Integer;
  NewList: TArray<TMethod>;
begin
  for I := High(List) downto 0 do
    if SameMethod(List[I], M) then
    begin
      // Copy-on-write (siehe AddMethod)
      SetLength(NewList, Length(List) - 1);
      K := 0;
      for J := 0 to High(List) do
        if J <> I then
        begin
          NewList[K] := List[J];
          Inc(K);
        end;
      List := NewList;
      Exit;
    end;
end;

procedure PPGAddMessageHook(const Hook: TPPGMessageHook);
var
  L: TArray<TMethod>;
begin
  if Host = nil then
    Exit;
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
  if Host = nil then
    Exit;
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
  /// Merker je laufendem WatchProc-Aufruf (liegt auf dem Stack): Der
  /// Destruktor setzt Gone, wenn das Control samt Beobachter waehrend der
  /// Nachricht freigegeben wird - danach darf WatchProc Self nicht mehr anfassen.
  PWatchFrame = ^TWatchFrame;
  TWatchFrame = record
    Gone: Boolean;
    Prev: PWatchFrame;
  end;

  TControlWatcher = class(TComponent)
  private
    FControl: TControl;
    FOldProc: TWndMethod;
    FEvents: TArray<TMethod>;
    FDepth: Integer;        // laufende WatchProc-Aufrufe
    FFrame: PWatchFrame;    // innerster laufender Aufruf (verkettet)
    FFreePending: Boolean;  // abgemeldet waehrend WatchProc: danach freigeben
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
var
  F: PWatchFrame;
begin
  // Laufende WatchProc-Aufrufe duerfen danach nicht mehr auf Self zugreifen
  F := FFrame;
  while F <> nil do
  begin
    F^.Gone := True;
    F := F^.Prev;
  end;
  FFrame := nil;
  if (FControl <> nil) and IsTopOfChain then
    FControl.WindowProc := FOldProc;
  FEvents := nil;
  inherited Destroy;
end;

procedure TControlWatcher.WatchProc(var Message: TMessage);
var
  List: TArray<TMethod>;
  I: Integer;
  Frame: TWatchFrame;
  Ctl: TControl;
begin
  Frame.Gone := False;
  Frame.Prev := FFrame;
  FFrame := @Frame;
  Inc(FDepth);
  try
    FOldProc(Message);
    // Control (und damit dieser Beobachter) in der Nachricht freigegeben
    if Frame.Gone then
      Exit;
    // Audit 8D: Referenz statt Kopie je Nachricht (Listen sind copy-on-write;
    // die lokale Referenz haelt sie auch, wenn der Beobachter stirbt)
    List := FEvents;
    Ctl := FControl;
    for I := High(List) downto 0 do
    begin
      try
        TPPGControlWatchEvent(List[I])(Ctl, Message);
      except
        // Grenze: fremder Beobachter in der Fensterprozedur - seine Exception
        // darf die Nachricht und die uebrigen Beobachter nicht abbrechen
        on E: Exception do
          if Frame.Gone then
            TPPGErrorHandler.HandleCallbackError(nil, E, 'PPG.AppHooks.PPGWatchControl')
          else
            TPPGErrorHandler.HandleCallbackError(Ctl, E, 'PPG.AppHooks.PPGWatchControl');
      end;
      if Frame.Gone then
        Exit;
    end;
  finally
    if not Frame.Gone then
    begin
      Dec(FDepth);
      FFrame := Frame.Prev;
    end;
  end;
  // Waehrend der Nachricht abgemeldet: jetzt aushaengen und freigeben
  if FFreePending and (FDepth = 0) then
    Free;
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
  W.FFreePending := False;
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
  begin
    if W.FDepth > 0 then
      W.FFreePending := True // laeuft noch (WatchProc gibt frei)
    else
      W.Free;
  end;
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
  GFinalized := True;
  FreeAndNil(GHost);

end.
