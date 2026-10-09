// expect: UNITS
// path: Tests\PPG.Tests.UnitsTest.pas
// count: 3
unit UnitsTest;

{ Unit-Namen immer voll qualifiziert (Winapi.Windows statt Windows). }

interface

uses
  Windows, System.SysUtils, Classes;

implementation

uses
  Generics.Collections;

end.
