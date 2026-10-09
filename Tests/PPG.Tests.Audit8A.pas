unit PPG.Tests.Audit8A;

{ Audit-Paket 8A (Docs\Audit-Paket8-Plan.md): Regressionstests. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  Vcl.Controls, Vcl.Forms, PPG.AppHooks, PPG.Tests.Controls;

type
  TAudit8ATests = class(TControlTestCase)
  published
    procedure Placeholder;
  end;

  /// 8.0 #1: Control wird waehrend einer beobachteten Nachricht freigegeben.
  TAppHooksLifetimeTests = class(TTestCase)
  private
    FWatched: TForm;
    FCallsAfterFree: Integer;
    FFreed: Boolean;
    procedure CountingEvent(Control: TControl; var Message: TMessage);
    procedure FreeingEvent(Control: TControl; var Message: TMessage);
  protected
    procedure SetUp; override;
  published
    procedure ObserverFreesControlStopsChain;
    procedure ReleaseOfWatchedFormIsSafe;
  end;

implementation

const
  WM_AUDIT8_FREE = WM_USER + 801;

procedure TAudit8ATests.Placeholder;
begin
  CheckTrue(True);
end;

{ TAppHooksLifetimeTests }

procedure TAppHooksLifetimeTests.SetUp;
begin
  inherited;
  FWatched := nil;
  FCallsAfterFree := 0;
  FFreed := False;
end;

procedure TAppHooksLifetimeTests.CountingEvent(Control: TControl; var Message: TMessage);
begin
  if FFreed then
    Inc(FCallsAfterFree);
end;

procedure TAppHooksLifetimeTests.FreeingEvent(Control: TControl; var Message: TMessage);
begin
  if (Message.Msg = WM_AUDIT8_FREE) and not FFreed then
  begin
    FFreed := True;
    FreeAndNil(FWatched);
  end;
end;

procedure TAppHooksLifetimeTests.ObserverFreesControlStopsChain;
begin
  FWatched := TForm.CreateNew(nil);
  // Zuletzt angemeldet = zuerst gerufen: FreeingEvent laeuft vor CountingEvent
  PPGWatchControl(FWatched, CountingEvent);
  PPGWatchControl(FWatched, FreeingEvent);
  FWatched.Perform(WM_AUDIT8_FREE, 0, 0);
  CheckTrue(FFreed, 'Control freigegeben');
  CheckEquals(0, FCallsAfterFree,
    'nach dem Freigeben darf kein weiterer Beobachter gerufen werden');
end;

procedure TAppHooksLifetimeTests.ReleaseOfWatchedFormIsSafe;
var
  F: TForm;
begin
  F := TForm.CreateNew(nil);
  PPGWatchControl(F, CountingEvent);
  F.Release;
  // CM_RELEASE gibt das Formular in seiner eigenen (beobachteten) WndProc
  // frei; danach darf WatchProc den Beobachter nicht mehr anfassen.
  Application.ProcessMessages;
  CheckTrue(True, 'ohne Zugriffsverletzung');
end;

initialization
  RegisterTest('Audit8A', TAudit8ATests.Suite);
  RegisterTest('Audit8A', TAppHooksLifetimeTests.Suite);

end.
