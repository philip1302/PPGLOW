// expect: none
// path: Source\Controls\PPG.Xe2OkTest.pas
unit Xe2OkTest;

{ Erlaubte Formen: qualifiziert, eigene Funktionen, ohne Generics. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.Generics.Collections;

type
  TItems = class(TCollection)
  protected
    procedure Notify(Item: TCollectionItem; Action: System.Classes.TCollectionNotification); override;
  end;

implementation

function FloatMod(const N, D: Double): Double;
begin
  Result := N - Trunc(N / D) * D;
end;

function PPGDocumentProperties(hWnd: HWND; hPrinter: THandle; pDeviceName: PChar;
  pDevModeOutput, pDevModeInput: PDeviceMode; fMode: DWORD): Longint; stdcall;
  external 'winspool.drv' name 'DocumentPropertiesW';

procedure TItems.Notify(Item: TCollectionItem; Action: System.Classes.TCollectionNotification);
begin
  if Action = System.Classes.cnDeleting then
    Exit;
  if FloatMod(1, 2) > PPGDocumentProperties(0, 0, nil, nil, nil, 0) then
    Exit;
end;

end.
