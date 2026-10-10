// expect: none
// path: Tests\PPG.Tests.SelfTestOk.pas
unit PPG.Tests.SelfTestOk;

{ Erlaubt: konkrete Klasse, raise im Handler, Klassenpruefung, Skip vor
  Exit, Exit nach der ersten Pruefung und ausserhalb von Testmethoden. }

interface

uses
  TestFramework, System.SysUtils;

type
  TSelfOkTests = class(TTestCase)
  private
    procedure Helper;
    procedure Skip(const Reason: string);
  published
    procedure ConcreteClass;
    procedure ReRaise;
    procedure ClassCheck;
    procedure SkipThenExit;
    procedure ExitAfterCheck;
    procedure LocalRoutineExits;
  end;

implementation

procedure TSelfOkTests.Helper;
begin
  if Now = 0 then
    Exit;
end;

procedure TSelfOkTests.Skip(const Reason: string);
begin
  Status(Reason);
end;

procedure TSelfOkTests.ConcreteClass;
begin
  try
    Helper;
    Fail('erwartet');
  except
    on EConvertError do
      ;
  end;
end;

procedure TSelfOkTests.ReRaise;
begin
  try
    CheckEquals(1, 1);
  except
    on E: Exception do
    begin
      Helper;
      raise;
    end;
  end;
end;

procedure TSelfOkTests.ClassCheck;
begin
  try
    Helper;
    Fail('erwartet');
  except
    on E: Exception do
      CheckTrue(E is EConvertError, E.ClassName);
  end;
end;

procedure TSelfOkTests.SkipThenExit;
begin
  if Now = 0 then
  begin
    Skip('Umgebung fehlt');
    Exit;
  end;
  CheckTrue(Now > 0);
end;

procedure TSelfOkTests.ExitAfterCheck;
begin
  CheckTrue(Now > 0);
  if Now > 1 then
    Exit;
  CheckTrue(Now > 0);
end;

procedure TSelfOkTests.LocalRoutineExits;

  function Value: Integer;
  begin
    Result := 1;
    if Now = 0 then
      Exit;
  end;

begin
  try
    CheckEquals(1, Value);
  finally
    Helper;
  end;
end;

end.
