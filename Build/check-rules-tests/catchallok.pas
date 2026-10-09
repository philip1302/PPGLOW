// expect: none
// path: Source\Controls\PPG.CatchAllOkTest.pas
unit CatchAllOkTest;

{ Erlaubt: Klassenfilter, raise/Abort im Handler, markierte Grenze. }

{$I ..\PPG.inc}

interface

procedure Foo;

implementation

uses
  System.SysUtils;

procedure Log(const S: string);
begin
end;

procedure Foo;
begin
  try
    Log('a');
  except
    on E: EConvertError do
      Log(E.Message);
  end;
  try
    Log('b');
  except
    Log('aufraeumen');
    raise;
  end;
  try
    Log('c');
  except
    on E: Exception do
    begin
      Log(E.Message);
      Abort;
    end;
  end;
  try
    Log('d');
  except
    // Grenze: Fensternachricht von Windows - die Anwendung meldet den Fehler
    on E: Exception do
      Log(E.Message);
  end;
end;

end.
