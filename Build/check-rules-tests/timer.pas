// expect: TIMER
// path: Source\Controls\PPG.TimerTest.pas
// count: 3
unit TimerTest;

{ Timer laufen nur ueber den gemeinsamen Animator (PPG.Animation). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Vcl.ExtCtrls;

type
  TFoo = class
  private
    FTimer: TTimer;
    procedure Start(Wnd: HWND);
  end;

implementation

procedure TFoo.Start(Wnd: HWND);
begin
  SetTimer(Wnd, 1, 100, nil);
  KillTimer(Wnd, 1);
end;

end.
