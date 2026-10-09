// expect: EXCEPT
// path: Source\Controls\PPG.CatchAllTest.pas
// count: 2
unit CatchAllTest;

{ except ohne Klassenfilter (auch "on E: Exception") und ohne raise nur an
  einer markierten Grenze. }

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
    Log('verschluckt');
  end;
  try
    Log('b');
  except
    on E: Exception do
      Log(E.Message);
  end;
end;

end.
