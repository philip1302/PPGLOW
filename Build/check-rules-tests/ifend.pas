// expect: IFEND
unit IfEnd;

interface

{$IF CompilerVersion >= 24.0}
const A = 1;
{$ENDIF}

{$IFDEF DEBUG}
const B = 1;
{$IFEND}

implementation

end.
