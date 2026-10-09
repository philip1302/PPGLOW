// expect: DB
// path: Source\Controls\PPG.DbTest.pas
// count: 2
unit DbTest;

{ Data.DB gehoert nur nach Source\DB (das Grundpaket linkt kein Data.DB). }

{$I ..\PPG.inc}

interface

uses
  System.Classes, Data.DB, Vcl.DBCtrls;

implementation

end.
