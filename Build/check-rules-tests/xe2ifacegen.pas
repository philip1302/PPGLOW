// expect: none
// path: Source\Core\PPG.Xe2IfaceTest.pas
unit Xe2IfaceTest;

{ System.Generics.Collections erst in implementation: im interface ist
  TCollectionNotification eindeutig (System.Classes). }

{$I ..\PPG.inc}

interface

uses
  System.Classes;

type
  TItems = class(TCollection)
  protected
    procedure Notify(Item: TCollectionItem; Action: TCollectionNotification); override;
  end;

implementation

uses
  System.Generics.Collections;

procedure TItems.Notify(Item: TCollectionItem; Action: System.Classes.TCollectionNotification);
begin
end;

end.
