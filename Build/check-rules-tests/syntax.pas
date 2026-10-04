// expect: SYNTAX
unit SyntaxTest;

interface

type
  TFoo = class
    [weak] FRef: TObject;
  end;

implementation

procedure Foo;
var
  S: string;
  I: Integer;
begin
  S := NameOf(I);
  I := if S = '' then 1 else 2;
  S := '''
    mehrzeilig
    ''';
end;

end.
