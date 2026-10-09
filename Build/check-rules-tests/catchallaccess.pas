// expect: none
// path: Source\Access\PPG.CatchAllAccessTest.pas
unit CatchAllAccessTest;

{ Source\Access: COM-Methoden fuer fremde Prozesse fangen alles (E_FAIL). }

{$I ..\PPG.inc}

interface

function Foo: HResult;

implementation

uses
  Winapi.Windows;

function Foo: HResult;
begin
  try
    Result := S_OK;
  except
    Result := E_FAIL;
  end;
end;

end.
