// expect: TESTS
// path: Tests\PPG.Tests.SelfTest.pas
// count: 9
unit PPG.Tests.SelfTest;

{ Regel TESTS: Pruefungen, die nichts pruefen, verschluckte Fehlschlaege
  (DUnits ETestFailure erbt von EAbort) und stilles Ueberspringen. }

interface

uses
  TestFramework, System.SysUtils;

type
  TSelfTests = class(TTestCase)
  private
    procedure Helper;
  published
    procedure AlwaysTrue;
    procedure SwallowsWithEAbort;
    procedure SwallowsWithException;
    procedure SwallowsBare;
    procedure SwallowsWithElse;
    procedure ExitWithStatus;
    procedure ExitBeforeFirstCheck;
  end;

implementation

procedure TSelfTests.Helper;
begin
end;

procedure TSelfTests.AlwaysTrue;
begin
  CheckTrue(True, 'immer');
  Check(True);
  CheckFalse(False);
end;

procedure TSelfTests.SwallowsWithEAbort;
begin
  try
    Helper;
    Fail('erwartet');
  except
    on E: EAbort do
      ;
  end;
end;

procedure TSelfTests.SwallowsWithException;
begin
  try
    CheckEquals(1, 2);
  except
    on Exception do
      ;
  end;
end;

procedure TSelfTests.SwallowsBare;
begin
  try
    Helper;
    Fail('erwartet');
  except
    Helper;
  end;
end;

procedure TSelfTests.SwallowsWithElse;
begin
  try
    Helper;
    Fail('erwartet');
  except
    on EConvertError do
      ;
  else
    Helper;
  end;
end;

procedure TSelfTests.ExitWithStatus;
begin
  if Now = 0 then
  begin
    Status('Umgebung fehlt');
    Exit;
  end;
  CheckTrue(Now > 0);
end;

procedure TSelfTests.ExitBeforeFirstCheck;
begin
  if Now = 0 then
    Exit;
  CheckTrue(Now > 0);
end;

end.
