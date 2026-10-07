// expect: INLINEVAR
unit InlineVar;

interface

implementation

procedure Foo;
begin
  var I: Integer := 1;
  for var J := 0 to 2 do
    I := I + J;
end;

end.
