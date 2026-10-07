unit PPG.Tests.Phase7d;

{$WARN SYMBOL_PLATFORM OFF}

{ Tests fuer Phase 7d: TPPGNotificationCenter / TPPGToast. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics,
  PPG.Types, PPG.Consts, PPG.Render.Registry, PPG.Controls.Base, PPG.Feedback,
  PPG.Notifications, PPG.Tests.Controls;

type
  TQuietCenter = class(TPPGNotificationCenter)
  protected
    function QuietTime: Boolean; override;
  public
    Quiet: Boolean;
  end;

  TNotificationTests = class(TControlTestCase)
  private
    FEvents: TStringList;
    procedure LogClose(Sender: TObject; Toast: TPPGToast; Reason: TPPGToastCloseReason);
    procedure LogAction(Sender: TObject; Toast: TPPGToast; ActionIndex: Integer);
    procedure LogClick(Sender: TObject; Toast: TPPGToast);
    function NewCenter: TPPGNotificationCenter;
    procedure Pump(Ms: Cardinal);
    procedure WaitFor(Center: TPPGNotificationCenter; Visible: Integer; TimeoutMs: Cardinal);
    procedure ClickPart(T: TPPGToast; Part: Integer);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure ShowPlacesToastInCorner;
    procedure StackNewestAtCorner;
    procedure MaxVisibleQueuesTheRest;
    procedure CloseButtonAndActions;
    procedure ClickOnToast;
    procedure AutoHideAfterDuration;
    procedure HoverPausesTimer;
    procedure QuietTimeHoldsToasts;
    procedure CloseAllAndFreeCenter;
    procedure PaintAllPresetsAndAccessibility;
    procedure NoHandleOrMemoryLeaks;
  end;

implementation

uses
  Winapi.oleacc, PPG.Theme;

type
  TToastAccess = class(TPPGToast);

const
  ReasonNames: array[TPPGToastCloseReason] of string = ('timeout', 'user', 'action', 'click', 'code');

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

function AllocatedBytes: NativeUInt;
var
  S: TMemoryManagerState;
  I: Integer;
begin
  GetMemoryManagerState(S);
  Result := S.TotalAllocatedMediumBlockSize + S.TotalAllocatedLargeBlockSize;
  for I := Low(S.SmallBlockTypeStates) to High(S.SmallBlockTypeStates) do
    Inc(Result, S.SmallBlockTypeStates[I].AllocatedBlockCount *
      S.SmallBlockTypeStates[I].UseableBlockSize);
end;

{ TQuietCenter }

function TQuietCenter.QuietTime: Boolean;
begin
  Result := Quiet;
end;

{ TNotificationTests }

procedure TNotificationTests.SetUp;
begin
  inherited SetUp;
  FEvents := TStringList.Create;
  FForm.Show;
end;

procedure TNotificationTests.TearDown;
begin
  FForm.Hide;
  FreeAndNil(FEvents);
  inherited TearDown;
end;

procedure TNotificationTests.LogClose(Sender: TObject; Toast: TPPGToast; Reason: TPPGToastCloseReason);
begin
  FEvents.Add('close:' + Toast.Title + ':' + ReasonNames[Reason]);
end;

procedure TNotificationTests.LogAction(Sender: TObject; Toast: TPPGToast; ActionIndex: Integer);
begin
  FEvents.Add('action:' + IntToStr(ActionIndex));
end;

procedure TNotificationTests.LogClick(Sender: TObject; Toast: TPPGToast);
begin
  FEvents.Add('click:' + Toast.Title);
end;

function TNotificationTests.NewCenter: TPPGNotificationCenter;
begin
  Result := TPPGNotificationCenter.Create(FForm);
  Result.Animations := False;
  Result.RespectQuietHours := False;
  Result.OnClose := LogClose;
  Result.OnAction := LogAction;
  Result.OnToastClick := LogClick;
end;

procedure TNotificationTests.Pump(Ms: Cardinal);
var
  T0: Cardinal;
begin
  T0 := GetTickCount;
  repeat
    Application.ProcessMessages;
    Sleep(5);
  until GetTickCount - T0 >= Ms;
end;

procedure TNotificationTests.WaitFor(Center: TPPGNotificationCenter; Visible: Integer;
  TimeoutMs: Cardinal);
var
  T0: Cardinal;
begin
  T0 := GetTickCount;
  while (Center.VisibleCount <> Visible) and (GetTickCount - T0 < TimeoutMs) do
  begin
    Application.ProcessMessages;
    Sleep(5);
  end;
  Application.ProcessMessages; // Freigabe der geschlossenen Toasts
end;

procedure TNotificationTests.ClickPart(T: TPPGToast; Part: Integer);
var
  R: TRect;
  X, Y: Integer;
begin
  if Part = -3 then
    R := Rect(T.Width div 2 - 2, T.Height div 2 - 2, T.Width div 2 + 2, T.Height div 2 + 2)
  else
    R := T.PartRect(Part);
  X := (R.Left + R.Right) div 2;
  Y := (R.Top + R.Bottom) div 2;
  T.Perform(WM_MOUSEMOVE, 0, MouseLParam(X, Y));
  T.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(X, Y));
  T.Perform(WM_LBUTTONUP, 0, MouseLParam(X, Y));
end;

procedure TNotificationTests.ShowPlacesToastInCorner;
var
  C: TPPGNotificationCenter;
  T: TPPGToast;
  WA, R: TRect;
begin
  C := NewCenter;
  T := C.Show('Gespeichert', 'Die Datei wurde gespeichert.', psSuccess, 0);
  CheckEquals(1, C.VisibleCount);
  CheckTrue(T.Shown);
  CheckTrue(IsWindowVisible(T.Handle), 'Fenster sichtbar');
  CheckTrue(GetWindowLong(T.Handle, GWL_EXSTYLE) and WS_EX_NOACTIVATE <> 0, 'ohne Aktivierung');
  CheckTrue(GetActiveWindow <> T.Handle);
  WA := Screen.MonitorFromWindow(FForm.Handle).WorkareaRect;
  GetWindowRect(T.Handle, R);
  CheckTrue(R.Right <= WA.Right, 'rechts im Arbeitsbereich');
  CheckTrue(R.Right >= WA.Right - 40, 'an der rechten Kante');
  CheckTrue(R.Bottom <= WA.Bottom);
  CheckTrue(R.Bottom >= WA.Bottom - 40, 'unten');
  CheckEquals(360, T.Width, 'ToastWidth (96 DPI)');
  C.Position := npTopLeft;
  T := C.Show('Zwei', 'Oben links', psInformational, 0);
  GetWindowRect(T.Handle, R);
  CheckTrue(R.Left <= WA.Left + 40);
  C.Free;
end;

procedure TNotificationTests.StackNewestAtCorner;
var
  C: TPPGNotificationCenter;
  T1, T2: TPPGToast;
  R1, R2: TRect;
begin
  C := NewCenter;
  T1 := C.Show('Eins', 'Erster', psInformational, 0);
  T2 := C.Show('Zwei', 'Zweiter', psWarning, 0);
  GetWindowRect(T1.Handle, R1);
  GetWindowRect(T2.Handle, R2);
  CheckTrue(R2.Top > R1.Top, 'neuester unten an der Ecke');
  CheckTrue(R1.Bottom <= R2.Top, 'keine Ueberlappung');
  T2.Close(tcrCode);
  WaitFor(C, 1, 500);
  GetWindowRect(T1.Handle, R1);
  CheckTrue(R1.Bottom >= R2.Bottom - 2, 'aelterer rueckt nach');
  C.Free;
end;

procedure TNotificationTests.MaxVisibleQueuesTheRest;
var
  C: TPPGNotificationCenter;
  T1: TPPGToast;
begin
  C := NewCenter;
  C.MaxVisible := 2;
  T1 := C.Show('A', '1', psInformational, 0);
  C.Show('B', '2', psInformational, 0);
  C.Show('C', '3', psInformational, 0);
  CheckEquals(2, C.VisibleCount);
  CheckEquals(1, C.PendingCount);
  T1.Close(tcrUser);
  WaitFor(C, 2, 500);
  CheckEquals(2, C.VisibleCount, 'wartender rueckt nach');
  CheckEquals(0, C.PendingCount);
  CheckEquals('close:A:user', FEvents.CommaText);
  C.Free;
end;

procedure TNotificationTests.CloseButtonAndActions;
var
  C: TPPGNotificationCenter;
  T: TPPGToast;
begin
  C := NewCenter;
  T := C.Show('Update', 'Neue Version', psInformational, 0, ['Installieren', 'Spaeter']);
  CheckEquals(2, Length(T.Actions));
  CheckFalse(IsRectEmpty(T.PartRect(1)));
  ClickPart(T, 1);
  WaitFor(C, 0, 500);
  CheckEquals('action:1,close:Update:action', FEvents.CommaText);
  FEvents.Clear;
  T := C.Show('Zweiter', 'Text', psError, 0);
  ClickPart(T, -2);
  WaitFor(C, 0, 500);
  CheckEquals('close:Zweiter:user', FEvents.CommaText);
  C.Free;
end;

procedure TNotificationTests.ClickOnToast;
var
  C: TPPGNotificationCenter;
  T: TPPGToast;
begin
  C := NewCenter;
  T := C.Show('Mail', 'Neue Nachricht', psInformational, 0);
  ClickPart(T, -3);
  WaitFor(C, 0, 500);
  CheckEquals('click:Mail,close:Mail:click', FEvents.CommaText);
  C.Free;
end;

procedure TNotificationTests.AutoHideAfterDuration;
var
  C: TPPGNotificationCenter;
begin
  C := NewCenter;
  C.Show('Kurz', 'Verschwindet', psInformational, 120);
  CheckEquals(1, C.VisibleCount);
  WaitFor(C, 0, 2000);
  CheckEquals(0, C.VisibleCount, 'nach Duration geschlossen');
  CheckEquals('close:Kurz:timeout', FEvents.CommaText);
  C.Free;
end;

procedure TNotificationTests.HoverPausesTimer;
var
  C: TPPGNotificationCenter;
  T: TPPGToast;
begin
  C := NewCenter;
  T := C.Show('Halt', 'Maus darueber', psInformational, 150);
  T.PauseTimer;
  Pump(400);
  CheckEquals(1, C.VisibleCount, 'angehalten');
  T.ResumeTimer;
  WaitFor(C, 0, 2000);
  CheckEquals(0, C.VisibleCount, 'laeuft weiter');
  C.Free;
end;

procedure TNotificationTests.QuietTimeHoldsToasts;
var
  C: TQuietCenter;
begin
  C := TQuietCenter.Create(FForm);
  C.Animations := False;
  C.Quiet := True;
  C.Show('Spaeter', 'Vollbild', psInformational, 0);
  CheckEquals(0, C.VisibleCount, 'wartet');
  CheckEquals(1, C.PendingCount);
  C.Quiet := False;
  WaitFor(C, 1, 3000);
  CheckEquals(1, C.VisibleCount, 'nach der Ruhezeit gezeigt');
  C.Free;
end;

procedure TNotificationTests.CloseAllAndFreeCenter;
var
  C: TPPGNotificationCenter;
begin
  C := NewCenter;
  C.MaxVisible := 1;
  C.Show('A', '1', psInformational, 0);
  C.Show('B', '2', psInformational, 0);
  C.CloseAll;
  WaitFor(C, 0, 500);
  CheckEquals(0, C.VisibleCount);
  CheckEquals(0, C.PendingCount);
  CheckEquals(2, FEvents.Count);
  // Freigeben mit offenen Toasts: ohne Ereignisse, ohne Fehler
  C.Show('C', '3', psInformational, 0);
  C.OnClose := nil;
  C.Free;
  Pump(50);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TNotificationTests.PaintAllPresetsAndAccessibility;
var
  Names: TStringList;
  P: Integer;
  Dark: Boolean;
  C: TPPGNotificationCenter;
  T: TPPGToast;
begin
  Names := TStringList.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    try
      for P := 0 to Names.Count - 1 do
        for Dark := False to True do
        begin
          if Dark then
            TPPGTheme.Mode := tmDark
          else
            TPPGTheme.Mode := tmLight;
          C := NewCenter;
          C.Preset := Names[P];
          T := C.Show('Titel', 'Text mit <b>Markup</b>', psWarning, 0, ['OK']);
          RenderToBitmap(T).Free;
          CheckEquals(ROLE_SYSTEM_ALERT, TToastAccess(T).AccRole);
          CheckEquals('Titel Text mit Markup', TToastAccess(T).AccName);
          C.Free;
        end;
    finally
      TPPGTheme.Mode := tmLight;
    end;
  finally
    Names.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TNotificationTests.NoHandleOrMemoryLeaks;

  procedure Cycle;
  var
    I: Integer;
    C: TPPGNotificationCenter;
  begin
    for I := 1 to 3 do
    begin
      C := NewCenter;
      C.Show('A', 'x', psInformational, 0);
      C.Show('B', 'y', psError, 0, ['OK']).Close(tcrCode);
      WaitFor(C, 1, 300);
      C.Free;
    end;
    Application.ProcessMessages;
  end;

var
  Gdi0, User0: Cardinal;
  M0, M1: NativeUInt;
begin
  Cycle;
  Gdi0 := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
  User0 := GetGuiResources(GetCurrentProcess, GR_USEROBJECTS);
  M0 := AllocatedBytes;
  Cycle;
  Cycle;
  M1 := AllocatedBytes;
  CheckTrue(GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS) <= Gdi0 + 2, 'GDI-Handles wachsen');
  CheckTrue(GetGuiResources(GetCurrentProcess, GR_USEROBJECTS) <= User0 + 2, 'USER-Handles wachsen');
  CheckTrue(M1 <= M0 + 4096, Format('Speicher waechst: %d -> %d', [M0, M1]));
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterTest('Phase7d', TNotificationTests.Suite);

end.
