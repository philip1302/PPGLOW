unit PPG.Tests.CalendarPopup;

{ PPGShowCalendarPopup - Kalender-Popup unter einem beliebigen PPGlow-Feld
  (ohne TPPGDatePicker), modal wie TPPGPopupMenu.Popup:
  - Klick auf einen Tag bzw. Enter uebernimmt (Uhrzeit von ADate bleibt),
    Pfeile/Bild/Pos1/Ende navigieren, Tippen landet nicht im Feld.
  - Esc, Tab, Klick daneben (verbraucht), Fokuswechsel und Deaktivieren
    brechen ab; ADate bleibt.
  - Startdatum (0 = heute, Grenzen), Kalenderwochen schaltbar.
  - MDI-Kind: Besitzer ist das Hauptformular.
  - Formular wird waehrend des Popups freigegeben bzw. gibt sich frei
    (Release erst nach der Rueckkehr).
  - Die Anwendung setzt Application.OnMessage selbst (Ersatzweg PPG.AppHooks).
  - TPPGDatePicker nutzt dasselbe Popup unveraendert (Stile, Direktwahl).
  Nach jedem Weg: kein Popup mehr offen, Haken abgemeldet.

  Ablauf wie PPG.Tests.PopupMenuBasics: Aktionen werden vor dem Aufruf in die
  Warteschlange gelegt (Probe) und laufen in der modalen Schleife. Bleibt das
  Popup offen, schliesst eine Sicherung es (Test schlaegt fehl, haengt nicht). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Rtti, System.Generics.Collections, Vcl.Controls, Vcl.Forms,
  Vcl.Graphics, PPG.Types, PPG.CustomDraw, PPG.AppHooks, PPG.Edit, PPG.Button,
  PPG.Calendar, PPG.DatePicker, PPG.Tests.Controls;

type
  TCalProbeAction = reference to procedure;

  /// Fuehrt Aktionen ueber gepostete Nachrichten aus (auch in der Schleife des
  /// Popups). NeedOpen: wartet, bis ein Popup offen ist. Danach wacht eine
  /// Sicherung: ist dasselbe Popup nach 2 s noch offen, schliesst sie es.
  TCalendarProbe = class
  private
    FWnd: HWND;
    FActions: TList<TCalProbeAction>;
    FNeedOpen: TList<Boolean>;
    FArmed: TPPGCalendarPopup;
    FSafetyHits: Integer;
    procedure WndProc(var Message: TMessage);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Post(const Action: TCalProbeAction; NeedOpen: Boolean = True);
    property SafetyHits: Integer read FSafetyHits;
  end;

  TCalendarPopupTests = class(TControlTestCase)
  private
    FProbe: TCalendarProbe;
    FEdit: TPPGEdit;
    FMain: TForm;
    FChild: TForm;
    FChildGone: Boolean;
    FHooks0: Integer;
    FClicks: Integer;
    FDrawCalls: Integer;
    FSavedMessage: TMessageEvent;
    procedure OtherClick(Sender: TObject);
    procedure ChildDestroy(Sender: TObject);
    procedure ChildClose(Sender: TObject; var Action: TCloseAction);
    procedure AppMessageOverride(var Msg: TMsg; var Handled: Boolean);
    procedure DrawDay(Sender: TObject; Canvas: TCanvas; ADate: TDate;
      const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
      var DefaultDraw: Boolean);
    function NewEdit(AParent: TWinControl): TPPGEdit;
    procedure ShowForm;
    procedure MakeMdi;
    procedure Pump;
    procedure PostKey(VK: Word);
    procedure ClickDay(D: TDate);
    procedure CheckClosed(const Context: string);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure ClickOnDayAccepts;
    procedure KeyboardNavigationAndEnter;
    procedure EscTabAndOutsideClickCancel;
    procedure FocusLossAndDeactivateCancel;
    procedure StartDateTodayAndRange;
    procedure WeekNumbersSwitchable;
    procedure MdiChildOwnerIsMainForm;
    procedure FormFreedWhileOpen;
    procedure ReleaseOfFormWhileOpenIsDeferred;
    procedure AppOverridesOnMessage;
    procedure HiddenAnchorDoesNotOpen;
    procedure SecondCallCancelsFirst;
    procedure DatePickerUnchanged;
  end;

implementation

const
  WM_CALPROBE = WM_APP + $5B3;

type
  TDateAccess = class(TPPGDatePicker);

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

/// Application.MainForm setzen (MDI-Kinder verlangen ein MDI-Hauptformular).
procedure SetMainForm(F: TForm);
var
  Ctx: TRttiContext;
  Fld: TRttiField;
begin
  Fld := Ctx.GetType(TApplication).GetField('FMainForm');
  if Fld = nil then
    raise Exception.Create('TApplication.FMainForm nicht gefunden');
  Fld.SetValue(Application, F);
end;

{ TCalendarProbe }

constructor TCalendarProbe.Create;
begin
  inherited Create;
  FActions := TList<TCalProbeAction>.Create;
  FNeedOpen := TList<Boolean>.Create;
  FWnd := AllocateHWnd(WndProc);
end;

destructor TCalendarProbe.Destroy;
begin
  if FWnd <> 0 then
  begin
    KillTimer(FWnd, 1);
    DeallocateHWnd(FWnd);
  end;
  FreeAndNil(FNeedOpen);
  FreeAndNil(FActions);
  inherited Destroy;
end;

procedure TCalendarProbe.Post(const Action: TCalProbeAction; NeedOpen: Boolean);
begin
  FActions.Add(Action);
  FNeedOpen.Add(NeedOpen);
  PostMessage(FWnd, WM_CALPROBE, WPARAM(FActions.Count - 1), 0);
end;

procedure TCalendarProbe.WndProc(var Message: TMessage);
var
  I: Integer;
begin
  case Message.Msg of
    WM_CALPROBE:
      begin
        I := Integer(Message.WParam);
        if FNeedOpen[I] and (PPGActiveCalendarPopup = nil) then
        begin
          if Message.LParam < 200 then
            PostMessage(FWnd, WM_CALPROBE, Message.WParam, Message.LParam + 1);
          Exit;
        end;
        FActions[I]();
        FArmed := PPGActiveCalendarPopup;
        if FArmed <> nil then
          SetTimer(FWnd, 1, 2000, nil);
      end;
    WM_TIMER:
      begin
        KillTimer(FWnd, 1);
        if (FArmed <> nil) and (PPGActiveCalendarPopup = FArmed) then
        begin
          Inc(FSafetyHits);
          PPGCloseCalendarPopup;
        end;
        FArmed := nil;
      end;
  else
    Message.Result := DefWindowProc(FWnd, Message.Msg, Message.WParam, Message.LParam);
  end;
end;

{ TCalendarPopupTests }

procedure TCalendarPopupTests.SetUp;
begin
  inherited SetUp;
  FormatSettings := PPGTestGermanFormat;
  FChildGone := False;
  FChild := nil;
  FMain := nil;
  FEdit := nil;
  FClicks := 0;
  FDrawCalls := 0;
  FProbe := TCalendarProbe.Create;
  FHooks0 := PPGMessageHookCount;
  FSavedMessage := Application.OnMessage;
end;

procedure TCalendarPopupTests.TearDown;
begin
  PPGCloseCalendarPopup;
  Application.OnMessage := FSavedMessage;
  Pump;
  if FChild <> nil then
  begin
    FChild.OnDestroy := nil;
    FreeAndNil(FChild);
  end;
  if FMain <> nil then
  begin
    SetMainForm(nil);
    FreeAndNil(FMain);
  end;
  FreeAndNil(FProbe);
  inherited TearDown;
end;

procedure TCalendarPopupTests.Pump;
var
  I: Integer;
begin
  for I := 1 to 8 do
    Application.ProcessMessages;
end;

procedure TCalendarPopupTests.PostKey(VK: Word);
var
  W: HWND;
begin
  // An das Fenster mit Fokus (wie die Tastatur); der Haken sieht jedes Fenster
  W := GetFocus;
  if W = 0 then
    W := FForm.Handle;
  PostMessage(W, WM_KEYDOWN, VK, 1);
  PostMessage(W, WM_KEYUP, VK, LPARAM($C0000001));
end;

procedure TCalendarPopupTests.ClickDay(D: TDate);
var
  Cal: TPPGCalendar;
  I: Integer;
  R: TRect;
  X, Y: Integer;
begin
  Cal := PPGActiveCalendarPopup.Calendar;
  for I := 0 to 41 do
    if Trunc(Cal.CellDate(I)) = Trunc(D) then
    begin
      R := Cal.CellRect(I);
      X := (R.Left + R.Right) div 2;
      Y := (R.Top + R.Bottom) div 2;
      // Wie die Maus: an das Fenster unter dem Zeiger (den Kalender)
      PostMessage(Cal.Handle, WM_MOUSEMOVE, 0, MouseLParam(X, Y));
      PostMessage(Cal.Handle, WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(X, Y));
      PostMessage(Cal.Handle, WM_LBUTTONUP, 0, MouseLParam(X, Y));
      Exit;
    end;
  Fail('Tag nicht sichtbar: ' + DateToStr(D));
end;

procedure TCalendarPopupTests.CheckClosed(const Context: string);
begin
  CheckNull(PPGActiveCalendarPopup, Context + ': kein Popup mehr offen');
  CheckEquals(FHooks0, PPGMessageHookCount, Context + ': Haken abgemeldet');
  CheckFalse(PPGFallbackHooksInstalled, Context + ': Thread-Haken entfernt');
  CheckEquals(0, FProbe.SafetyHits, Context + ': Popup schloss selbst');
end;

procedure TCalendarPopupTests.OtherClick(Sender: TObject);
begin
  Inc(FClicks);
end;

procedure TCalendarPopupTests.ChildDestroy(Sender: TObject);
begin
  FChildGone := True;
  if Sender = FChild then
    FChild := nil;
end;

procedure TCalendarPopupTests.ChildClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TCalendarPopupTests.AppMessageOverride(var Msg: TMsg; var Handled: Boolean);
begin
  // wie eine Anwendung, die Application.OnMessage selbst setzt
end;

procedure TCalendarPopupTests.DrawDay(Sender: TObject; Canvas: TCanvas; ADate: TDate;
  const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
  var DefaultDraw: Boolean);
begin
  Inc(FDrawCalls);
end;

function TCalendarPopupTests.NewEdit(AParent: TWinControl): TPPGEdit;
begin
  Result := TPPGEdit.Create(AParent);
  Result.Parent := AParent;
  Result.SetBounds(10, 10, 150, 26);
  Result.Animation.Enabled := False;
end;

procedure TCalendarPopupTests.ShowForm;
begin
  FForm.Show;
  FEdit := NewEdit(FForm);
  Pump;
  FEdit.SetFocus;
  Pump;
end;

procedure TCalendarPopupTests.MakeMdi;
begin
  FMain := TForm.CreateNew(nil);
  FMain.FormStyle := fsMDIForm;
  FMain.SetBounds(0, 0, 800, 600);
  SetMainForm(FMain);
  FMain.Show;
  FChild := TForm.CreateNew(nil);
  FChild.FormStyle := fsMDIChild;
  FChild.SetBounds(10, 10, 500, 400);
  FChild.OnDestroy := ChildDestroy;
  FChild.OnClose := ChildClose;
  FChild.Show;
  FEdit := NewEdit(FChild);
  Pump;
  FEdit.SetFocus;
  Pump;
end;

procedure TCalendarPopupTests.ClickOnDayAccepts;
var
  D: TDateTime;
  Ok, Visible, Below, FocusKept: Boolean;
  StartSel, StartFocus: TDate;
  OwnerWnd, Focus0: HWND;
begin
  ShowForm;
  D := EncodeDate(2026, 10, 15) + EncodeTime(10, 30, 0, 0);
  Visible := False;
  Below := False;
  FocusKept := False;
  StartSel := 0;
  StartFocus := 0;
  OwnerWnd := 0;
  Focus0 := GetFocus;
  FProbe.Post(
    procedure
    var
      P: TPPGCalendarPopup;
      R: TRect;
      A: TPoint;
    begin
      P := PPGActiveCalendarPopup;
      Visible := P.HandleAllocated and IsWindowVisible(P.Handle) and
        IsWindowVisible(P.Calendar.Handle) and (P.Height > 200);
      GetWindowRect(P.Handle, R);
      A := FEdit.ClientToScreen(Point(0, FEdit.Height));
      Below := (R.Top >= A.Y - 1) and (Abs(R.Left - A.X) <= 2);
      OwnerWnd := GetWindow(P.Handle, GW_OWNER);
      StartSel := P.Calendar.Date;
      StartFocus := P.Calendar.FocusDate;
      FocusKept := GetFocus = Focus0;
      ClickDay(EncodeDate(2026, 10, 20));
    end);
  Ok := PPGShowCalendarPopup(FEdit, D);
  CheckTrue(Ok, 'Tag gewaehlt');
  CheckEquals(EncodeDate(2026, 10, 20) + EncodeTime(10, 30, 0, 0), D, 1 / 86400,
    'gewaehlter Tag, Uhrzeit bleibt');
  CheckTrue(Visible, 'Popup sichtbar');
  CheckTrue(Below, 'unter dem Feld, linksbuendig');
  CheckEquals(FForm.Handle, OwnerWnd, 'Besitzer = Formular des Felds');
  CheckEquals(EncodeDate(2026, 10, 15), StartSel, 0, 'Startdatum gewaehlt');
  CheckEquals(EncodeDate(2026, 10, 15), StartFocus, 0, 'Startdatum fokussiert');
  CheckTrue(FocusKept, 'Fokus bleibt beim Feld');
  CheckClosed('Klick');
  // Klick auf den schon gewaehlten Tag uebernimmt ebenfalls
  D := EncodeDate(2026, 10, 15);
  FProbe.Post(procedure begin ClickDay(EncodeDate(2026, 10, 15)); end);
  CheckTrue(PPGShowCalendarPopup(FEdit, D), 'gewaehlter Tag erneut');
  CheckEquals(EncodeDate(2026, 10, 15), D, 0);
  CheckClosed('gleicher Tag');
end;

procedure TCalendarPopupTests.KeyboardNavigationAndEnter;
var
  D: TDateTime;
begin
  ShowForm;
  FEdit.Text := 'abc';
  // Rechts, Unten, Enter; ein Zeichen kommt nicht im Feld an
  D := EncodeDate(2026, 10, 15);
  FProbe.Post(
    procedure
    begin
      PostKey(VK_RIGHT);
      PostKey(VK_DOWN);
      PostMessage(GetFocus, WM_CHAR, Ord('x'), 1);
      PostKey(VK_RETURN);
    end);
  CheckTrue(PPGShowCalendarPopup(FEdit, D), 'Enter');
  CheckEquals(EncodeDate(2026, 10, 23), D, 0, 'Rechts + Unten');
  CheckClosed('Enter');
  Pump;
  CheckEquals('abc', FEdit.Text, 'Tippen geht nicht ins Feld');
  // Bild ab, Pos1, Ende
  D := EncodeDate(2026, 10, 15);
  FProbe.Post(
    procedure
    begin
      PostKey(VK_NEXT);
      PostKey(VK_HOME);
      FProbe.Post(
        procedure
        begin
          CheckEquals(EncodeDate(2026, 11, 1), PPGActiveCalendarPopup.Calendar.FocusDate, 0,
            'Bild ab + Pos1');
          PostKey(VK_END);
          PostKey(VK_RETURN);
        end);
    end);
  CheckTrue(PPGShowCalendarPopup(FEdit, D), 'Enter nach Bild/Pos1/Ende');
  CheckEquals(EncodeDate(2026, 11, 30), D, 0, 'Ende = Monatsende');
  CheckClosed('Bild/Pos1/Ende');
  // F4 uebernimmt einen bewegten Fokus-Tag, ohne Bewegung bricht es ab
  D := EncodeDate(2026, 10, 15);
  FProbe.Post(procedure begin PostKey(VK_LEFT); PostKey(VK_F4); end);
  CheckTrue(PPGShowCalendarPopup(FEdit, D), 'F4 mit bewegtem Fokus');
  CheckEquals(EncodeDate(2026, 10, 14), D, 0);
  FProbe.Post(procedure begin PostKey(VK_F4); end);
  CheckFalse(PPGShowCalendarPopup(FEdit, D), 'F4 ohne Bewegung');
  CheckEquals(EncodeDate(2026, 10, 14), D, 0);
  CheckClosed('F4');
end;

procedure TCalendarPopupTests.EscTabAndOutsideClickCancel;
var
  D: TDateTime;
  Other: TPPGButton;
begin
  ShowForm;
  Other := TPPGButton.Create(FForm);
  Other.Parent := FForm;
  Other.SetBounds(330, 10, 60, 26); // neben dem Popup
  Other.OnClick := OtherClick;
  Pump;
  D := EncodeDate(2026, 10, 15);
  FProbe.Post(procedure begin PostKey(VK_RIGHT); PostKey(VK_ESCAPE); end);
  CheckFalse(PPGShowCalendarPopup(FEdit, D), 'Esc');
  CheckEquals(EncodeDate(2026, 10, 15), D, 0, 'Esc: Datum bleibt');
  CheckClosed('Esc');
  FProbe.Post(procedure begin PostKey(VK_TAB); end);
  CheckFalse(PPGShowCalendarPopup(FEdit, D), 'Tab');
  CheckClosed('Tab');
  FProbe.Post(
    procedure
    begin
      PostMessage(Other.Handle, WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(5, 5));
      PostMessage(Other.Handle, WM_LBUTTONUP, 0, MouseLParam(5, 5));
    end);
  CheckFalse(PPGShowCalendarPopup(FEdit, D), 'Klick daneben');
  Pump;
  CheckEquals(EncodeDate(2026, 10, 15), D, 0, 'Klick daneben: Datum bleibt');
  CheckEquals(0, FClicks, 'Klick daneben verbraucht');
  CheckClosed('Klick daneben');
end;

procedure TCalendarPopupTests.FocusLossAndDeactivateCancel;
var
  D: TDateTime;
  Other: TPPGEdit;
begin
  ShowForm;
  Other := NewEdit(FForm);
  Other.SetBounds(10, 250, 150, 26);
  Pump;
  D := EncodeDate(2026, 10, 15);
  FProbe.Post(procedure begin Other.SetFocus; end);
  CheckFalse(PPGShowCalendarPopup(FEdit, D), 'Fokuswechsel');
  CheckClosed('Fokuswechsel');
  FEdit.SetFocus;
  Pump;
  FProbe.Post(
    procedure
    begin
      // wie Windows: WM_ACTIVATEAPP an das Anwendungsfenster (OnDeactivate)
      if Application.Handle <> 0 then
        SendMessage(Application.Handle, WM_ACTIVATEAPP, 0, 0)
      else
        SendMessage(FForm.Handle, WM_ACTIVATEAPP, 0, 0);
      if (PPGActiveCalendarPopup <> nil) and Assigned(Application.OnDeactivate) then
        Application.OnDeactivate(Application);
    end);
  CheckFalse(PPGShowCalendarPopup(FEdit, D), 'Deaktivieren');
  CheckEquals(EncodeDate(2026, 10, 15), D, 0);
  CheckClosed('Deaktivieren');
  if Application.Handle <> 0 then
    SendMessage(Application.Handle, WM_ACTIVATEAPP, 1, 0);
  SendMessage(FForm.Handle, WM_ACTIVATEAPP, 1, 0);
  // Verstecken des Formulars
  FProbe.Post(procedure begin FForm.Hide; end);
  CheckFalse(PPGShowCalendarPopup(FEdit, D), 'Verstecken');
  CheckClosed('Verstecken');
end;

procedure TCalendarPopupTests.StartDateTodayAndRange;
var
  D: TDateTime;
  Seen: TDate;
  Opt: TPPGCalendarPopupOptions;
begin
  ShowForm;
  // 0 = heute
  D := 0;
  Seen := 0;
  FProbe.Post(
    procedure
    begin
      Seen := PPGActiveCalendarPopup.Calendar.Date;
      PostKey(VK_ESCAPE);
    end);
  CheckFalse(PPGShowCalendarPopup(FEdit, D));
  CheckEquals(System.SysUtils.Date, Seen, 0, 'ohne Datum: heute');
  CheckEquals(0, D, 0, 'abgebrochen: 0 bleibt');
  // Grenzen: Start davor wird auf MinDate geholt, Enter uebernimmt ihn
  Opt := PPGCalendarPopupOptions(False, EncodeDate(2026, 3, 10), EncodeDate(2026, 3, 20));
  D := EncodeDate(2026, 1, 1);
  FProbe.Post(
    procedure
    begin
      Seen := PPGActiveCalendarPopup.Calendar.Date;
      CheckEquals(EncodeDate(2026, 3, 10), PPGActiveCalendarPopup.Calendar.MinDate, 0, 'MinDate');
      CheckEquals(EncodeDate(2026, 3, 20), PPGActiveCalendarPopup.Calendar.MaxDate, 0, 'MaxDate');
      PostKey(VK_LEFT); // gesperrt: bleibt auf MinDate
      PostKey(VK_RETURN);
    end);
  CheckTrue(PPGShowCalendarPopup(FEdit, D, Opt), 'Enter auf MinDate');
  CheckEquals(EncodeDate(2026, 3, 10), Seen, 0, 'Start auf MinDate geholt');
  CheckEquals(EncodeDate(2026, 3, 10), D, 0, 'nicht vor MinDate');
  // Start danach -> MaxDate
  D := EncodeDate(2027, 1, 1);
  FProbe.Post(
    procedure
    begin
      Seen := PPGActiveCalendarPopup.Calendar.Date;
      PostKey(VK_ESCAPE);
    end);
  CheckFalse(PPGShowCalendarPopup(FEdit, D, Opt));
  CheckEquals(EncodeDate(2026, 3, 20), Seen, 0, 'Start auf MaxDate geholt');
  CheckClosed('Grenzen');
end;

procedure TCalendarPopupTests.WeekNumbersSwitchable;
var
  D: TDateTime;
  WOff, WOn: Integer;
  ShownOff, ShownOn: Boolean;
begin
  ShowForm;
  D := EncodeDate(2026, 10, 15);
  WOff := 0;
  WOn := 0;
  ShownOff := True;
  ShownOn := False;
  FProbe.Post(
    procedure
    begin
      ShownOff := PPGActiveCalendarPopup.Calendar.ShowWeekNumbers;
      WOff := PPGActiveCalendarPopup.Width;
      PostKey(VK_ESCAPE);
    end);
  PPGShowCalendarPopup(FEdit, D);
  FProbe.Post(
    procedure
    begin
      ShownOn := PPGActiveCalendarPopup.Calendar.ShowWeekNumbers;
      WOn := PPGActiveCalendarPopup.Width;
      PostKey(VK_ESCAPE);
    end);
  PPGShowCalendarPopup(FEdit, D, True);
  CheckFalse(ShownOff, 'Vorgabe ohne Kalenderwochen');
  CheckTrue(ShownOn, 'Kalenderwochen eingeschaltet');
  CheckTrue(WOn > WOff, 'breiter fuer die Wochenspalte');
  CheckClosed('Kalenderwochen');
end;

procedure TCalendarPopupTests.MdiChildOwnerIsMainForm;
var
  D: TDateTime;
  OwnerWnd: HWND;
begin
  MakeMdi;
  D := EncodeDate(2026, 10, 15);
  OwnerWnd := 0;
  FProbe.Post(
    procedure
    begin
      OwnerWnd := GetWindow(PPGActiveCalendarPopup.Handle, GW_OWNER);
      ClickDay(EncodeDate(2026, 10, 16));
    end);
  CheckTrue(PPGShowCalendarPopup(FEdit, D), 'Klick im MDI-Kind');
  CheckEquals(EncodeDate(2026, 10, 16), D, 0);
  CheckEquals(FMain.Handle, OwnerWnd, 'Besitzer = Hauptformular (MDI-Rahmen)');
  CheckClosed('MDI');
end;

procedure TCalendarPopupTests.FormFreedWhileOpen;
var
  Dlg: TForm;
  E: TPPGEdit;
  D: TDateTime;
begin
  Dlg := TForm.CreateNew(nil);
  try
    Dlg.SetBounds(50, 50, 300, 200);
    E := NewEdit(Dlg);
    Dlg.Show;
    Pump;
    E.SetFocus;
    D := EncodeDate(2026, 10, 15);
    FProbe.Post(procedure begin FreeAndNil(Dlg); end);
    CheckFalse(PPGShowCalendarPopup(E, D), 'Formular freigegeben');
    CheckNull(Dlg, 'freigegeben');
    CheckEquals(EncodeDate(2026, 10, 15), D, 0);
    CheckClosed('Freigeben');
  finally
    Dlg.Free;
  end;
end;

procedure TCalendarPopupTests.ReleaseOfFormWhileOpenIsDeferred;
var
  D: TDateTime;
  GoneAtReturn: Boolean;
begin
  // Close mit caFree waehrend das Popup offen ist: Release liefe sonst in der
  // Schleife, der Aufrufer (Klick-Ereignis) danach in freigegebenem Speicher
  MakeMdi;
  D := EncodeDate(2026, 10, 15);
  FProbe.Post(procedure begin FChild.Close; end);
  CheckFalse(PPGShowCalendarPopup(FEdit, D), 'abgebrochen');
  GoneAtReturn := FChildGone;
  CheckClosed('Release');
  Pump;
  CheckFalse(GoneAtReturn, 'Formular lebt bis nach der Rueckkehr');
  CheckTrue(FChildGone, 'danach freigegeben');
end;

procedure TCalendarPopupTests.AppOverridesOnMessage;
var
  D: TDateTime;
  Fallback: Boolean;
  Other: TPPGButton;
begin
  ShowForm;
  Other := TPPGButton.Create(FForm);
  Other.Parent := FForm;
  Other.SetBounds(330, 10, 60, 26);
  Other.OnClick := OtherClick;
  Pump;
  Application.OnMessage := AppMessageOverride;
  Fallback := False;
  D := EncodeDate(2026, 10, 15);
  FProbe.Post(
    procedure
    begin
      Fallback := PPGFallbackHooksInstalled;
      PostKey(VK_RIGHT);
      PostKey(VK_RETURN);
    end);
  CheckTrue(PPGShowCalendarPopup(FEdit, D), 'Enter');
  CheckTrue(Fallback, 'Thread-Haken liegt bereit');
  CheckEquals(EncodeDate(2026, 10, 16), D, 0);
  CheckClosed('Enter');
  FProbe.Post(procedure begin ClickDay(EncodeDate(2026, 10, 20)); end);
  CheckTrue(PPGShowCalendarPopup(FEdit, D), 'Klick');
  CheckEquals(EncodeDate(2026, 10, 20), D, 0);
  CheckClosed('Klick');
  FProbe.Post(
    procedure
    begin
      PostMessage(Other.Handle, WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(5, 5));
      PostMessage(Other.Handle, WM_LBUTTONUP, 0, MouseLParam(5, 5));
    end);
  CheckFalse(PPGShowCalendarPopup(FEdit, D), 'Klick daneben');
  Pump;
  CheckEquals(0, FClicks, 'Klick daneben verbraucht');
  CheckClosed('Klick daneben');
  FProbe.Post(procedure begin PostKey(VK_ESCAPE); end);
  CheckFalse(PPGShowCalendarPopup(FEdit, D), 'Esc');
  CheckClosed('Esc');
  Application.OnMessage := FSavedMessage;
end;

procedure TCalendarPopupTests.HiddenAnchorDoesNotOpen;
var
  E: TPPGEdit;
  D: TDateTime;
begin
  // Formular nicht sichtbar: sofort zurueck, keine Schleife
  E := NewEdit(FForm);
  D := EncodeDate(2026, 10, 15);
  FProbe.Post(procedure begin end, False);
  CheckFalse(PPGShowCalendarPopup(E, D), 'unsichtbar');
  CheckFalse(PPGShowCalendarPopup(nil, D), 'ohne Anker');
  CheckEquals(EncodeDate(2026, 10, 15), D, 0);
  Pump;
  CheckClosed('unsichtbar');
end;

procedure TCalendarPopupTests.SecondCallCancelsFirst;
var
  D1, D2: TDateTime;
  R1, R2: Boolean;
  Log: string;
begin
  ShowForm;
  D1 := EncodeDate(2026, 10, 15);
  D2 := EncodeDate(2026, 12, 1);
  R2 := False;
  Log := '';
  FProbe.Post(
    procedure
    begin
      Log := Log + 'open2,';
      FProbe.Post(procedure begin PostKey(VK_RETURN); end);
      R2 := PPGShowCalendarPopup(FEdit, D2);
      Log := Log + 'back2,';
    end);
  R1 := PPGShowCalendarPopup(FEdit, D1);
  Log := Log + 'back1';
  CheckEquals('open2,back2,back1', Log, 'nur ein Popup, Reihenfolge');
  CheckFalse(R1, 'erstes abgebrochen');
  CheckTrue(R2, 'zweites uebernommen');
  CheckEquals(EncodeDate(2026, 10, 15), D1, 0);
  CheckEquals(EncodeDate(2026, 12, 1), D2, 0);
  CheckClosed('zwei Popups');
end;

procedure TCalendarPopupTests.DatePickerUnchanged;
var
  DP: TPPGDatePicker;
  K: Word;
begin
  FForm.Show;
  DP := TPPGDatePicker.Create(FForm);
  DP.Parent := FForm;
  DP.SetBounds(10, 10, 150, 26);
  DP.Animation.Enabled := False;
  DP.Date := EncodeDate(2026, 10, 15);
  DP.Styles.Today.Color := clRed;
  DP.OnCustomDrawDay := DrawDay;
  Pump;
  DP.SetFocus;
  DP.DropDown;
  CheckTrue(DP.DroppedDown, 'aufgeklappt');
  CheckTrue(DP.Popup is TPPGCalendarPopup);
  CheckSame(DP, DP.Popup.Owner, 'Popup gehoert dem DatePicker');
  CheckNull(PPGActiveCalendarPopup, 'keine modale Schleife');
  CheckEquals(clRed, DP.Popup.Calendar.Styles.Today.Color, 'Stile vom DatePicker');
  CheckTrue(Assigned(DP.Popup.Calendar.OnCustomDrawDay), 'eigenes Zeichnen vom DatePicker');
  CheckFalse(DP.Popup.Calendar.ShowWeekNumbers, 'ohne Kalenderwochen');
  CheckEquals(EncodeDate(2026, 10, 15), DP.Popup.Calendar.Date, 0);
  // Direkt am Kalender gewaehlt (nicht ueber das Feld): uebernimmt und schliesst
  DP.Popup.Calendar.Perform(WM_KEYDOWN, VK_RIGHT, 0);
  DP.Popup.Calendar.Perform(WM_KEYDOWN, VK_RETURN, 0);
  CheckFalse(DP.DroppedDown, 'Direktwahl schliesst');
  CheckEquals(EncodeDate(2026, 10, 16), DP.Date, 0, 'Direktwahl uebernommen');
  // Ueber das Feld: Esc bricht ab, Enter uebernimmt
  DP.DropDown;
  K := VK_RIGHT;
  TDateAccess(DP).FieldKeyDown(K, []);
  K := VK_ESCAPE;
  TDateAccess(DP).FieldKeyDown(K, []);
  CheckFalse(DP.DroppedDown, 'Esc');
  CheckEquals(EncodeDate(2026, 10, 16), DP.Date, 0, 'Esc: Datum bleibt');
  CheckEquals(FHooks0, PPGMessageHookCount, 'keine Haken');
end;

initialization
  RegisterTest('Kalender-Popup', TCalendarPopupTests.Suite);

end.
