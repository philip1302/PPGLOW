unit PPG.ErrorHandler;

{ Zentrale Fehler- und Log-Behandlung.

  Die Suite faengt Exceptions nur an genau definierten Grenzen ab:
  - Paint            -> ReportPaintError  (nie weiterwerfen, sonst WM_PAINT-Schleife)
  - Timer/Callbacks  -> HandleCallbackError (Application.HandleException wie die VCL)
  Ueberall sonst propagieren Exceptions normal.

  Anwendungen koennen ein eigenes Logging anschliessen:
    TPPGErrorHandler.Logger := TMyLogger.Create;      // IPPGLogger
    TPPGErrorHandler.OnError := MyForm.HandlePPGError; // Ereignis

  Zugriff nur aus dem Main-Thread (wie die gesamte VCL). }

{$I ..\PPG.inc}

interface

uses
  System.SysUtils, System.Classes;

type
  TPPGLogLevel = (llDebug, llInfo, llWarning, llError);

  IPPGLogger = interface
    ['{5B0E8C2A-3C1F-4D8E-9A61-2F7B4C9D1E10}']
    procedure Log(Level: TPPGLogLevel; const Msg: string);
  end;

  /// Standard-Logger: schreibt per OutputDebugString (sichtbar im IDE-Ereignisprotokoll / DebugView).
  TPPGDebugLogger = class(TInterfacedObject, IPPGLogger)
  public
    procedure Log(Level: TPPGLogLevel; const Msg: string);
  end;

  TPPGErrorEvent = procedure(Sender: TObject; E: Exception; const Context: string) of object;

  TPPGErrorHandler = class
  private
    class var FLogger: IPPGLogger;
    class var FOnError: TPPGErrorEvent;
    class var FInHandler: Boolean;
    class function GetLogger: IPPGLogger; static;
    class procedure SetLogger(const Value: IPPGLogger); static;
    class procedure NotifyError(Sender: TObject; E: Exception; const Context: string); static;
  public
    /// Fehler beim Zeichnen: protokollieren, nie weiterwerfen.
    class procedure ReportPaintError(Sender: TObject; E: Exception); static;
    /// Fehler in Timer-/Message-Callbacks: protokollieren und wie die VCL
    /// ueber Application.HandleException melden. Muss aus einem except-Block
    /// heraus aufgerufen werden.
    class procedure HandleCallbackError(Sender: TObject; E: Exception; const Context: string); static;
    class procedure LogWarning(Sender: TObject; const Msg: string); static;
    class procedure LogInfo(Sender: TObject; const Msg: string); static;

    class property Logger: IPPGLogger read GetLogger write SetLogger;
    class property OnError: TPPGErrorEvent read FOnError write FOnError;
  end;

implementation

uses
  Winapi.Windows, Vcl.Forms, PPG.Consts, PPG.Exceptions;

const
  LevelNames: array[TPPGLogLevel] of string = ('DEBUG', 'INFO', 'WARN', 'ERROR');

function SenderText(Sender: TObject): string;
begin
  if Sender is TPersistent then
    Result := PPGDisplayName(TPersistent(Sender))
  else if Sender <> nil then
    Result := Sender.ClassName
  else
    Result := '(nil)';
end;

{ TPPGDebugLogger }

procedure TPPGDebugLogger.Log(Level: TPPGLogLevel; const Msg: string);
begin
  OutputDebugString(PChar('[PPGlow ' + LevelNames[Level] + '] ' + Msg));
end;

{ TPPGErrorHandler }

class function TPPGErrorHandler.GetLogger: IPPGLogger;
begin
  if FLogger = nil then
    FLogger := TPPGDebugLogger.Create;
  Result := FLogger;
end;

class procedure TPPGErrorHandler.SetLogger(const Value: IPPGLogger);
begin
  FLogger := Value;
end;

class procedure TPPGErrorHandler.NotifyError(Sender: TObject; E: Exception;
  const Context: string);
begin
  // Ein fehlerhafter Fehler-Handler darf keine Rekursion und keinen
  // Folgefehler im aufrufenden Paint/Timer ausloesen. Das ist die einzige
  // Stelle, an der eine Exception bewusst verworfen wird - sie wird aber
  // noch per OutputDebugString sichtbar gemacht.
  if FInHandler then
    Exit;
  FInHandler := True;
  try
    try
      GetLogger.Log(llError, Format('%s: %s (%s: %s)',
        [SenderText(Sender), Context, E.ClassName, E.Message]));
      if Assigned(FOnError) then
        FOnError(Sender, E, Context);
    except
      on Inner: Exception do
        OutputDebugString(PChar('[PPGlow ERROR] Error handler failed: ' + Inner.Message));
    end;
  finally
    FInHandler := False;
  end;
end;

class procedure TPPGErrorHandler.ReportPaintError(Sender: TObject; E: Exception);
begin
  NotifyError(Sender, E, Format(SPPGPaintFailed, [SenderText(Sender), E.Message]));
end;

class procedure TPPGErrorHandler.HandleCallbackError(Sender: TObject;
  E: Exception; const Context: string);
begin
  NotifyError(Sender, E, Format(SPPGCallbackFailed, [Context, E.Message]));
  // Wie die VCL selbst: Anwendung zeigt bzw. protokolliert die Exception
  // (madExcept/EurekaLog haengen sich hier ein), Programm laeuft weiter.
  if (Application <> nil) and not Application.Terminated then
    Application.HandleException(Sender);
end;

class procedure TPPGErrorHandler.LogWarning(Sender: TObject; const Msg: string);
begin
  GetLogger.Log(llWarning, SenderText(Sender) + ': ' + Msg);
end;

class procedure TPPGErrorHandler.LogInfo(Sender: TObject; const Msg: string);
begin
  GetLogger.Log(llInfo, SenderText(Sender) + ': ' + Msg);
end;

initialization

finalization
  // Interface-Referenz vor dem Entladen der Unit freigeben (sonst Leak-Meldung)
  TPPGErrorHandler.FLogger := nil;
  TPPGErrorHandler.FOnError := nil;

end.
