// expect: XE2
// path: Source\Controls\PPG.Xe2Test.pas
// count: 5
unit Xe2Test;

{ XE2-Verbotsliste: FMod, unqualifiziertes TCollectionNotification bzw. cn*
  neben System.Generics.Collections, DocumentProperties mit nil. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.Generics.Collections;

type
  TItems = class(TCollection)
  protected
    procedure Notify(Item: TCollectionItem; Action: TCollectionNotification); override;
  end;

function Rest(X: Double): Double;
function Size(H: THandle; const Name: string): Integer;

implementation

uses
  System.Math, Winapi.WinSpool;

procedure TItems.Notify(Item: TCollectionItem; Action: TCollectionNotification);
begin
  if Action = cnDeleting then
    Exit;
end;

function Rest(X: Double): Double;
begin
  Result := FMod(X, 360);
end;

function Size(H: THandle; const Name: string): Integer;
begin
  Result := DocumentProperties(0, H, PChar(Name),
    nil, nil, 0);
end;

end.
