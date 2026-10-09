// expect: none
// path: Source\Design\PPG.TextDesignTest.pas
unit TextDesignTest;

{ Design-Units sind ausgenommen (die IDE bleibt englisch). }

{$I ..\PPG.inc}

interface

uses
  Vcl.StdCtrls;

procedure Foo(L: TLabel);

implementation

procedure Foo(L: TLabel);
begin
  L.Caption := 'Edit items...';
end;

end.
