// expect: RAISE EXCEPT source-unit
unit RaiseTest;

{$I ..\PPG.inc}

interface

implementation

uses
  System.SysUtils;

procedure Foo;
begin
  try
    raise Exception.Create('nein');
  except
  end;
  RaiseLastOSError;
end;

end.
