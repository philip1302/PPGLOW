// expect: none source-unit
unit Ok;

{ Gueltige Unit: alles erlaubt, was die Regeln zulassen. }

{$I ..\PPG.inc}

interface

type
  TEv = procedure(Sender: TObject;
    var Value: string; var Accept: Boolean) of object;

procedure Foo(A: Integer;
  var B: Integer);

implementation

uses
  System.SysUtils, PPG.Exceptions;

procedure Foo(A: Integer;
  var B: Integer);
var
  S: string;
begin
  S := 'if x then y else z; var Q: Integer; {';
  // raise Exception.Create('nur Kommentar'); for var I := 0
  {$IF CompilerVersion >= 24.0}
  B := A;
  {$IFEND}
  {$IFDEF DEBUG}
  B := B + 1;
  {$ENDIF}
  try
    B := StrToInt(S);
  except
    on E: EConvertError do
      raise EPPGError.Create('x');
  end;
  S := 'it''';
end;

end.
