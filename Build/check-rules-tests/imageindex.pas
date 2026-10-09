// expect: IMAGEINDEX
// path: Source\Controls\PPG.ImageIndexTest.pas
// count: 1
unit ImageIndexTest;

{ TImageIndex nur in PPG.Types, sonst TPPGImageIndex. }

{$I ..\PPG.inc}

interface

uses
  System.UITypes, PPG.Types;

type
  TFoo = class
  private
    FGood: TPPGImageIndex;
    FBad: TImageIndex;
  end;

implementation

end.
