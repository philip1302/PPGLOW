unit PPG.Exceptions;

{ Exception-Hierarchie der Suite.

  Regeln:
  - Alle Exceptions der Suite erben von EPPGError, damit Anwendungen gezielt
    "on E: EPPGError" abfangen koennen.
  - Meldungen kommen immer aus resourcestrings (PPG.Consts).
  - Ein Objekt bleibt nach einer EPPGPropertyError unveraendert
    (erst validieren, dann zuweisen). }

{$I ..\PPG.inc}

interface

uses
  System.SysUtils, System.Classes;

type
  EPPGError = class(Exception);

  EPPGPropertyError = class(EPPGError)
  private
    FPropertyName: string;
    FOwnerName: string;
  public
    constructor CreateInvalid(Sender: TPersistent; const APropertyName, AValue: string);
    constructor CreateRange(Sender: TPersistent; const APropertyName: string;
      AValue, AMin, AMax: Integer);
    property PropertyName: string read FPropertyName;
    property OwnerName: string read FOwnerName;
  end;

  EPPGRenderError = class(EPPGError);
  EPPGConfigError = class(EPPGError);
  EPPGStreamError = class(EPPGError);

/// Liefert einen sprechenden Namen fuer Meldungen ("Form1.Button1" bzw. Klassenname).
function PPGDisplayName(Sender: TPersistent): string;

/// Wie RaiseLastOSError, aber mit Name des API-Aufrufs in der Meldung
/// (im Feld sofort zuordenbar) und als EPPGRenderError.
procedure PPGRaiseLastOSError(const ApiCall: string);

implementation

uses
  PPG.Lang,
  Winapi.Windows, PPG.Consts;

procedure PPGRaiseLastOSError(const ApiCall: string);
var
  Code: Cardinal;
begin
  Code := GetLastError; // sofort sichern, bevor andere Aufrufe es ueberschreiben
  raise EPPGRenderError.CreateFmt(PPGStr(@SPPGOSCallFailed),
    [ApiCall, Code, SysErrorMessage(Code)]);
end;

function PPGDisplayName(Sender: TPersistent): string;
begin
  if Sender = nil then
    Result := '(nil)'
  else if (Sender is TComponent) and (TComponent(Sender).Name <> '') then
    Result := TComponent(Sender).Name
  else
    Result := Sender.GetNamePath;
  if Result = '' then
    Result := Sender.ClassName;
end;

{ EPPGPropertyError }

constructor EPPGPropertyError.CreateInvalid(Sender: TPersistent;
  const APropertyName, AValue: string);
begin
  FOwnerName := PPGDisplayName(Sender);
  FPropertyName := APropertyName;
  CreateFmt(PPGStr(@SPPGInvalidPropertyValue), [AValue, FOwnerName, APropertyName]);
end;

constructor EPPGPropertyError.CreateRange(Sender: TPersistent;
  const APropertyName: string; AValue, AMin, AMax: Integer);
begin
  FOwnerName := PPGDisplayName(Sender);
  FPropertyName := APropertyName;
  CreateFmt(PPGStr(@SPPGValueOutOfRange), [AValue, FOwnerName, APropertyName, AMin, AMax]);
end;

end.
