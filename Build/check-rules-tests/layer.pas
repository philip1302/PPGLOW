// expect: LAYER
// path: Source\Core\PPG.LayerTest.pas
// count: 2
unit LayerTest;

{ Core darf nur Core verwenden: PPG.Types (Core) ist erlaubt,
  PPG.Markup (Render) und PPG.Controls.Base (Controls) nicht. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, PPG.Types;

implementation

uses
  PPG.Markup, PPG.Controls.Base;

end.
