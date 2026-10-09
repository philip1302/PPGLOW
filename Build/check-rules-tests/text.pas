// expect: TEXT
// path: Source\Controls\PPG.TextTest.pas
// count: 1
unit TextTest;

{ Sichtbare Texte nur ueber PPGStr (resourcestring in PPG.Consts).
  Ein einzelnes Zeichen (Symbol) ist erlaubt. }

{$I ..\PPG.inc}

interface

uses
  Vcl.StdCtrls;

procedure Foo(L: TLabel);

implementation

procedure Foo(L: TLabel);
begin
  L.Caption := 'x';
  L.Hint := '';
  L.Caption := 'Speichern';
end;

end.
