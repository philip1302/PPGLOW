unit PPG.Tests.PopupMenuBasics;

{ Grundfunktionen von TPPGPopupMenu (Meldung aus einer MDI-Anwendung: "zeigt
  nichts an", beim Schliessen des Formulars Zugriffsfehler):
  - Oeffnen aus dem OnClick eines Buttons in einem MDI-Kind: sichtbares Fenster
    mit Eintraegen, Besitzer ist das Hauptformular (bleibt darueber, wenn es
    nach vorn kommt).
  - Schliessen per Esc, Klick daneben, Eintrag, Deaktivieren der Anwendung,
    Verstecken bzw. Freigeben des Formulars.
  - Die Anwendung setzt Application.OnMessage/OnDeactivate selbst: das Menue
    schliesst trotzdem (Ersatzweg in PPG.AppHooks).
  - Release des Formulars waehrend das Menue offen ist: erst nach Popup.
  - Abort in OnPopup, zweites Popup waehrend eines offenen, Popup aus einem
    modalen Dialog.
  Nach jedem Weg: keine Schleife mehr aktiv, Haken abgemeldet.

  Ablauf: Aktionen werden vor Popup in die Warteschlange gelegt (Probe) und
  laufen in der modalen Schleife. Bleibt das Menue nach einer Aktion offen,
  schliesst eine Sicherung es hart (der Test schlaegt dann fehl, haengt aber nicht). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Rtti, System.Generics.Collections, Vcl.Controls, Vcl.Forms, Vcl.Menus,
  PPG.AppHooks, PPG.Menus, PPG.Button, PPG.Grid, PPG.StyleManager, PPG.Tests.Controls;

type
  TProbeAction = reference to procedure;

  /// Fuehrt Aktionen ueber gepostete Nachrichten aus (auch in RunModal).
  /// Eine Aktion fuer ein offenes Menue wartet, bis es offen ist (die
  /// Reihenfolge geposteter Tasten-/Mausnachrichten zu anderen ist nicht fest).
  /// Danach wacht eine Sicherung (Timer): ist dasselbe Menue nach 2 s noch
  /// offen, schliesst sie es hart und zaehlt das.
  TMenuProbe = class
  private
    FWnd: HWND;
    FActions: TList<TProbeAction>;
    FNeedLoop: TList<Boolean>;
    FArmed: TPPGMenuLoop;
    FSafetyHits: Integer;
    procedure WndProc(var Message: TMessage);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Post(const Action: TProbeAction; NeedLoop: Boolean = True);
    property SafetyHits: Integer read FSafetyHits;
  end;
  TPopupMenuBasicsTests = class(TControlTestCase)
  private
    FLog: TStringList;
    FProbe: TMenuProbe;
    FMenu: TPPGPopupMenu;
    FButton: TPPGButton;
    FMain: TForm;
    FChild: TForm;
    FChildGone: Boolean;
    FHooks0: Integer;
    FSavedMessage: TMessageEvent;
    FSavedDeactivate: TNotifyEvent;
    procedure ItemClick(Sender: TObject);
    procedure ButtonPopup(Sender: TObject);
    procedure LogPopup(Sender: TObject);
    procedure LogClose(Sender: TObject);
    procedure ShowFirstPopup(Sender: TObject);
    procedure ExitClick(Sender: TObject);
    procedure AbortPopup(Sender: TObject);
    procedure ChildDestroy(Sender: TObject);
    procedure ChildClose(Sender: TObject; var Action: TCloseAction);
    procedure AppMessageOverride(var Msg: TMsg; var Handled: Boolean);
    procedure AppDeactivateOverride(Sender: TObject);
    function NewMenu(Owner: TComponent): TPPGPopupMenu;
    procedure MakeMdi;
    procedure PostKey(Wnd: HWND; VK: Word);
    procedure PostClick(Wnd: HWND);
    procedure Pump;
    procedure CheckClosed(const Context: string);
    procedure CheckNoSafety(const Context: string);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure ClickHandlerInMdiChildShowsMenuAboveMain;
    procedure ClosesByEscOutsideItemAndDeactivate;
    procedure ClosesWhenAppOverridesOnMessage;
    procedure ClosesWhenAppOverridesOnDeactivate;
    procedure ReleaseOfFormWhileOpenIsDeferred;
    procedure HidingOrFreeingFormClosesMenu;
    procedure AbortInOnPopup;
    procedure SecondPopupWhileOpen;
    procedure PopupFromModalDialog;
    procedure EmptyMenuDoesNotOpen;
  end;

implementation

const
  WM_PROBE = WM_APP + $5B1;

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

/// Liegt H in der Z-Reihenfolge ueber Other?
function IsAbove(H, Other: HWND): Boolean;
var
  Z: HWND;
begin
  Result := False;
  Z := GetWindow(H, GW_HWNDNEXT);
  while Z <> 0 do
  begin
    if Z = Other then
      Exit(True);
    Z := GetWindow(Z, GW_HWNDNEXT);
  end;
end;

/// Application.MainForm setzen (MDI-Kinder verlangen ein MDI-Hauptformular;
/// die Test-Exe hat keins). Nur fuer Tests.
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

{ TMenuProbe }

constructor TMenuProbe.Create;
begin
  inherited Create;
  FActions := TList<TProbeAction>.Create;
  FNeedLoop := TList<Boolean>.Create;
  FWnd := AllocateHWnd(WndProc);
end;

destructor TMenuProbe.Destroy;
begin
  if FWnd <> 0 then
  begin
    KillTimer(FWnd, 1);
    DeallocateHWnd(FWnd);
  end;
  FreeAndNil(FNeedLoop);
  FreeAndNil(FActions);
  inherited Destroy;
end;

procedure TMenuProbe.Post(const Action: TProbeAction; NeedLoop: Boolean);
begin
  FActions.Add(Action);
  FNeedLoop.Add(NeedLoop);
  PostMessage(FWnd, WM_PROBE, WPARAM(FActions.Count - 1), 0);
end;

procedure TMenuProbe.WndProc(var Message: TMessage);
var
  I: Integer;
begin
  case Message.Msg of
    WM_PROBE:
      begin
        I := Integer(Message.WParam);
        if FNeedLoop[I] and (PPGActiveMenuLoop = nil) then
        begin
          // Menue noch nicht offen (Klick noch in der Warteschlange): spaeter;
          // oeffnet es nie, entfaellt die Aktion (der Test prueft das Ergebnis)
          if Message.LParam < 200 then
            PostMessage(FWnd, WM_PROBE, Message.WParam, Message.LParam + 1);
          Exit;
        end;
        FActions[I]();
        FArmed := PPGActiveMenuLoop;
        if FArmed <> nil then
          SetTimer(FWnd, 1, 2000, nil);
      end;
    WM_TIMER:
      begin
        KillTimer(FWnd, 1);
        if (FArmed <> nil) and (PPGActiveMenuLoop = FArmed) then
        begin
          Inc(FSafetyHits);
          PPGActiveMenuLoop.CloseAll;
        end;
        FArmed := nil;
      end;
  else
    Message.Result := DefWindowProc(FWnd, Message.Msg, Message.WParam, Message.LParam);
  end;
end;
{ TPopupMenuBasicsTests }

procedure TPopupMenuBasicsTests.SetUp;
begin
  inherited SetUp;
  // Leak-Lauf wiederholt Tests auf derselben Instanz: Zustand zuruecksetzen
  FChildGone := False;
  FChild := nil;
  FMain := nil;
  FButton := nil;
  FMenu := nil;
  FLog := TStringList.Create;
  FProbe := TMenuProbe.Create;
  FHooks0 := PPGMessageHookCount;
  FSavedMessage := Application.OnMessage;
  FSavedDeactivate := Application.OnDeactivate;
end;

procedure TPopupMenuBasicsTests.TearDown;
begin
  if PPGActiveMenuLoop <> nil then
    PPGActiveMenuLoop.CloseAll;
  PPGFlushMenuExecute;
  Application.OnMessage := FSavedMessage;
  Application.OnDeactivate := FSavedDeactivate;
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
  FreeAndNil(FLog);
  inherited TearDown;
end;

procedure TPopupMenuBasicsTests.Pump;
var
  I: Integer;
begin
  for I := 1 to 8 do
    Application.ProcessMessages;
end;

procedure TPopupMenuBasicsTests.PostKey(Wnd: HWND; VK: Word);
begin
  PostMessage(Wnd, WM_KEYDOWN, VK, 1);
  PostMessage(Wnd, WM_KEYUP, VK, LPARAM($C0000001));
end;

procedure TPopupMenuBasicsTests.PostClick(Wnd: HWND);
begin
  PostMessage(Wnd, WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(5, 5));
  PostMessage(Wnd, WM_LBUTTONUP, 0, MouseLParam(5, 5));
end;

procedure TPopupMenuBasicsTests.ItemClick(Sender: TObject);
begin
  FLog.Add('click:' + StripHotkey(TMenuItem(Sender).Caption) + ':' +
    System.SysUtils.BoolToStr(PPGActiveMenuLoop = nil, True));
end;

procedure TPopupMenuBasicsTests.ButtonPopup(Sender: TObject);
var
  P: TPoint;
begin
  // Wie die Anwendung: ohne PopupComponent, Punkt unter dem Button
  P := FButton.ClientToScreen(Point(0, FButton.Height));
  FLog.Add('popup');
  FMenu.Popup(P.X, P.Y);
  FLog.Add('returned:' + System.SysUtils.BoolToStr(FChildGone, True));
end;

procedure TPopupMenuBasicsTests.AbortPopup(Sender: TObject);
begin
  FLog.Add('onpopup');
  Abort;
end;

procedure TPopupMenuBasicsTests.ChildDestroy(Sender: TObject);
begin
  FChildGone := True;
  FLog.Add('destroyed');
  if Sender = FChild then
    FChild := nil;
end;

procedure TPopupMenuBasicsTests.ChildClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TPopupMenuBasicsTests.AppMessageOverride(var Msg: TMsg; var Handled: Boolean);
begin
  // wie eine Anwendung, die nur das Mausrad umbaut
end;

procedure TPopupMenuBasicsTests.AppDeactivateOverride(Sender: TObject);
begin
end;

function TPopupMenuBasicsTests.NewMenu(Owner: TComponent): TPPGPopupMenu;
var
  I: Integer;
  It: TMenuItem;
begin
  Result := TPPGPopupMenu.Create(Owner);
  for I := 1 to 3 do
  begin
    It := TMenuItem.Create(Result);
    It.Caption := 'Eintrag' + IntToStr(I);
    It.OnClick := ItemClick;
    Result.Items.Add(It);
  end;
end;

procedure TPopupMenuBasicsTests.MakeMdi;
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
  FButton := TPPGButton.Create(FChild);
  FButton.Parent := FChild;
  FButton.SetBounds(10, 10, 100, 30);
  FButton.Animation.Enabled := False;
  FButton.OnClick := ButtonPopup;
  FMenu := NewMenu(FChild);
  Pump;
end;

procedure TPopupMenuBasicsTests.CheckClosed(const Context: string);
begin
  CheckNull(PPGActiveMenuLoop, Context + ': keine Schleife mehr aktiv');
  CheckEquals(FHooks0, PPGMessageHookCount, Context + ': Haken abgemeldet');
  CheckFalse(PPGFallbackHooksInstalled, Context + ': Thread-Haken entfernt');
end;

procedure TPopupMenuBasicsTests.CheckNoSafety(const Context: string);
begin
  CheckEquals(0, FProbe.SafetyHits, Context + ': Menue schloss nicht selbst');
end;

procedure TPopupMenuBasicsTests.ClickHandlerInMdiChildShowsMenuAboveMain;
var
  Visible, AboveAfter: Boolean;
  Items: Integer;
  OwnerWnd: HWND;
begin
  MakeMdi;
  Visible := False;
  AboveAfter := False;
  Items := 0;
  OwnerWnd := 0;
  FProbe.Post(
    procedure
    var
      W: TPPGMenuWindow;
    begin
      // Die Probe wartet auf das offene Menue (TMenuProbe.Post)
      W := PPGActiveMenuLoop.TopWindow;
      Visible := W.HandleAllocated and IsWindowVisible(W.Handle) and (W.Height > 20);
      Items := W.ItemCount;
      OwnerWnd := GetWindow(W.Handle, GW_OWNER);
      // Hauptformular kommt nach vorn (Aktivierung): das Menue bleibt darueber
      SetWindowPos(FMain.Handle, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
      AboveAfter := IsAbove(W.Handle, FMain.Handle);
      PostKey(FButton.Handle, VK_ESCAPE);
    end);
  // Klick wie mit der Maus: OnClick laeuft im WM_LBUTTONUP des Buttons
  PostClick(FButton.Handle);
  Pump;
  CheckEquals('popup,returned:False', FLog.CommaText);
  CheckTrue(Visible, 'Menuefenster sichtbar');
  CheckEquals(3, Items, 'Eintraege');
  CheckEquals(FMain.Handle, OwnerWnd, 'Besitzer = Hauptformular (MDI-Rahmen)');
  CheckTrue(AboveAfter, 'Menue liegt ueber dem Hauptformular, auch wenn es nach vorn kommt');
  CheckNoSafety('Esc');
  CheckClosed('Esc');
end;

procedure TPopupMenuBasicsTests.ClosesByEscOutsideItemAndDeactivate;
var
  Other: TPPGButton;
begin
  FForm.Show;
  FButton := NewButton('Ausloeser');
  Other := NewButton('Andere');
  Other.SetBounds(200, 200, 100, 30);
  Other.OnClick := ItemClick; // Klick daneben darf ihn nicht ausloesen
  FButton.SetFocus;
  FMenu := NewMenu(FForm);
  // Esc
  FProbe.Post(procedure begin PostKey(FButton.Handle, VK_ESCAPE); end);
  FMenu.Popup(50, 50);
  CheckNoSafety('Esc');
  CheckClosed('Esc');
  // Klick daneben: schliesst und wird verbraucht
  FProbe.Post(procedure begin PostClick(Other.Handle); end);
  FMenu.Popup(50, 50);
  Pump;
  CheckNoSafety('Klick daneben');
  CheckClosed('Klick daneben');
  CheckEquals(0, FLog.Count, 'Klick daneben verbraucht');
  // Eintrag waehlen (Tastatur): Klick nach dem Schliessen
  FProbe.Post(
    procedure
    begin
      PostKey(FButton.Handle, VK_DOWN);
      PostKey(FButton.Handle, VK_RETURN);
    end);
  FMenu.Popup(50, 50);
  Pump;
  CheckNoSafety('Eintrag');
  CheckClosed('Eintrag');
  CheckEquals('click:Eintrag1:True', FLog.CommaText, 'Eintrag nach dem Schliessen ausgeloest');
  // Eintrag per Maus (Fenster des Menues)
  FLog.Clear;
  FProbe.Post(
    procedure
    var
      W: TPPGMenuWindow;
      R: TRect;
    begin
      W := PPGActiveMenuLoop.TopWindow;
      R := W.ItemRect(1);
      PostMessage(W.Handle, WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(R.Left + 10, R.Top + 5));
      PostMessage(W.Handle, WM_LBUTTONUP, 0, MouseLParam(R.Left + 10, R.Top + 5));
    end);
  FMenu.Popup(50, 50);
  Pump;
  CheckNoSafety('Maus');
  CheckClosed('Maus');
  CheckEquals('click:Eintrag2:True', FLog.CommaText, 'Mausklick auf Eintrag');
  // Anwendung deaktiviert
  FProbe.Post(
    procedure
    begin
      if Application.Handle <> 0 then
        SendMessage(Application.Handle, WM_ACTIVATEAPP, 0, 0)
      else
        SendMessage(FForm.Handle, WM_ACTIVATEAPP, 0, 0);
      if (PPGActiveMenuLoop <> nil) and Assigned(Application.OnDeactivate) then
        Application.OnDeactivate(Application);
    end);
  FMenu.Popup(50, 50);
  CheckNoSafety('Deaktivieren');
  CheckClosed('Deaktivieren');
  SendMessage(FForm.Handle, WM_ACTIVATEAPP, 1, 0);
end;

procedure TPopupMenuBasicsTests.ClosesWhenAppOverridesOnMessage;
var
  Other: TPPGButton;
  Fallback: Boolean;
begin
  // Die Anwendung setzt Application.OnMessage selbst (trennt den Verteiler von
  // TApplicationEvents ab): Tasten und Klicks erreichen das Menue trotzdem
  FForm.Show;
  FButton := NewButton('Ausloeser');
  Other := NewButton('Andere');
  Other.SetBounds(200, 200, 100, 30);
  Other.OnClick := ItemClick;
  FButton.SetFocus;
  FMenu := NewMenu(FForm);
  Application.OnMessage := AppMessageOverride;
  Fallback := False;
  FProbe.Post(
    procedure
    begin
      Fallback := PPGFallbackHooksInstalled;
      PostKey(FButton.Handle, VK_ESCAPE);
    end);
  FMenu.Popup(50, 50);
  CheckTrue(Fallback, 'Thread-Haken liegt bereit');
  CheckNoSafety('Esc');
  CheckClosed('Esc');
  FProbe.Post(procedure begin PostClick(Other.Handle); end);
  FMenu.Popup(50, 50);
  Pump;
  CheckNoSafety('Klick daneben');
  CheckClosed('Klick daneben');
  CheckEquals(0, FLog.Count, 'Klick daneben verbraucht');
  // Eintrag per Tastatur
  FProbe.Post(
    procedure
    begin
      PostKey(FButton.Handle, VK_DOWN);
      PostKey(FButton.Handle, VK_RETURN);
    end);
  FMenu.Popup(50, 50);
  Pump;
  CheckNoSafety('Eintrag');
  CheckClosed('Eintrag');
  CheckEquals('click:Eintrag1:True', FLog.CommaText, 'Eintrag ausgeloest');
  Application.OnMessage := FSavedMessage;
end;

procedure TPopupMenuBasicsTests.ClosesWhenAppOverridesOnDeactivate;
begin
  FForm.Show;
  FButton := NewButton('Ausloeser');
  FMenu := NewMenu(FForm);
  Application.OnDeactivate := AppDeactivateOverride;
  FProbe.Post(
    procedure
    begin
      // WM_ACTIVATEAPP geht an jedes Fenster der Anwendung
      SendMessage(FForm.Handle, WM_ACTIVATEAPP, 0, 0);
    end);
  FMenu.Popup(50, 50);
  CheckNoSafety('Deaktivieren');
  CheckClosed('Deaktivieren');
  SendMessage(FForm.Handle, WM_ACTIVATEAPP, 1, 0);
  // Wieder aktiviert: das naechste Deaktivieren schliesst wieder
  FProbe.Post(procedure begin SendMessage(FForm.Handle, WM_ACTIVATEAPP, 0, 0); end);
  FMenu.Popup(50, 50);
  CheckNoSafety('zweites Deaktivieren');
  CheckClosed('zweites Deaktivieren');
  SendMessage(FForm.Handle, WM_ACTIVATEAPP, 1, 0);
end;

procedure TPopupMenuBasicsTests.ReleaseOfFormWhileOpenIsDeferred;
begin
  // Close mit caFree (Schliessen-Knopf, Strg+F4 ...) waehrend das Menue aus dem
  // OnClick offen ist: Release liefe sonst in RunModal, der Button liefe danach
  // in freigegebenem Speicher weiter
  MakeMdi;
  FProbe.Post(procedure begin FChild.Close; end);
  // Direkt statt per Klick: ohne Korrektur liefe sonst der Test selbst im
  // freigegebenen Button weiter
  ButtonPopup(nil);
  CheckEquals('popup,returned:False', FLog.CommaText, 'Formular lebt bis nach Popup');
  CheckNoSafety('Release');
  CheckClosed('Release');
  Pump;
  CheckTrue(FChildGone, 'danach freigegeben');
  CheckEquals('popup,returned:False,destroyed', FLog.CommaText);
end;

procedure TPopupMenuBasicsTests.HidingOrFreeingFormClosesMenu;
var
  Dlg: TForm;
  B: TPPGButton;
  M: TPPGPopupMenu;
begin
  // Verstecken
  FForm.Show;
  FButton := NewButton('Ausloeser');
  FMenu := NewMenu(FForm);
  FMenu.PopupComponent := FButton;
  FProbe.Post(procedure begin FForm.Hide; end);
  FMenu.Popup(50, 50);
  CheckNoSafety('Verstecken');
  CheckClosed('Verstecken');
  // Freigeben des Formulars (Menue gehoert ihm nicht)
  Dlg := TForm.CreateNew(nil);
  M := NewMenu(nil);
  try
    Dlg.SetBounds(50, 50, 300, 200);
    B := TPPGButton.Create(Dlg);
    B.Parent := Dlg;
    B.SetBounds(10, 10, 80, 30);
    Dlg.Show;
    M.PopupComponent := B;
    FProbe.Post(procedure begin FreeAndNil(Dlg); end);
    M.Popup(60, 60);
    CheckNull(Dlg, 'freigegeben');
    CheckNoSafety('Freigeben');
    CheckClosed('Freigeben');
  finally
    M.Free;
    Dlg.Free;
  end;
end;

procedure TPopupMenuBasicsTests.AbortInOnPopup;
var
  G: TPPGGrid;
  Raised: Boolean;
begin
  FForm.Show;
  FMenu := NewMenu(FForm);
  FMenu.OnPopup := AbortPopup;
  // Direkt: EAbort kommt beim Aufrufer an, nichts bleibt offen
  Raised := False;
  try
    FMenu.Popup(50, 50);
  except
    on EAbort do
      Raised := True;
  end;
  CheckTrue(Raised, 'EAbort');
  CheckClosed('Abort direkt');
  // Rechtsklick auf ein Grid mit diesem PopupMenu: still abgebrochen
  G := TPPGGrid.Create(FForm);
  G.Parent := FForm;
  G.SetBounds(10, 50, 300, 150);
  G.PopupMenu := FMenu;
  Pump;
  PostMessage(G.Handle, WM_RBUTTONDOWN, MK_RBUTTON, MouseLParam(80, 80));
  PostMessage(G.Handle, WM_RBUTTONUP, 0, MouseLParam(80, 80));
  Pump;
  CheckEquals('onpopup,onpopup', FLog.CommaText, 'OnPopup beim Rechtsklick');
  CheckEquals(0, FAppExceptions, 'EAbort wird nicht gemeldet');
  CheckClosed('Abort Rechtsklick');
  // Ohne Abort: Rechtsklick oeffnet, Esc schliesst
  FMenu.OnPopup := nil;
  FProbe.Post(procedure begin PostKey(G.Handle, VK_ESCAPE); end);
  PostMessage(G.Handle, WM_RBUTTONDOWN, MK_RBUTTON, MouseLParam(80, 80));
  PostMessage(G.Handle, WM_RBUTTONUP, 0, MouseLParam(80, 80));
  Pump;
  CheckNoSafety('Rechtsklick');
  CheckClosed('Rechtsklick');
end;

procedure TPopupMenuBasicsTests.SecondPopupWhileOpen;
var
  M2: TPPGPopupMenu;
begin
  FForm.Show;
  FButton := NewButton('Ausloeser');
  FButton.SetFocus;
  FMenu := NewMenu(FForm);
  M2 := NewMenu(FForm);
  M2.Items[0].Caption := 'Zweites';
  FProbe.Post(
    procedure
    begin
      FLog.Add('open2');
      // Zweites Menue waehrend das erste offen ist: das erste schliesst
      FProbe.Post(procedure begin PostKey(FButton.Handle, VK_ESCAPE); end);
      M2.Popup(80, 80);
      FLog.Add('back2:' + System.SysUtils.BoolToStr(PPGActiveMenuLoop = nil, True));
    end);
  FMenu.Popup(50, 50);
  FLog.Add('back1');
  Pump;
  CheckEquals('open2,back2:True,back1', FLog.CommaText, 'nur ein Menue, Reihenfolge');
  CheckClosed('zwei Menues');
end;

procedure TPopupMenuBasicsTests.PopupFromModalDialog;
var
  Dlg: TForm;
  B: TPPGButton;
  OwnerWnd: HWND;
  Res: Integer;
  DlgOpen: Boolean;
begin
  Dlg := TForm.CreateNew(nil);
  try
    Dlg.SetBounds(50, 50, 300, 200);
    B := TPPGButton.Create(Dlg);
    B.Parent := Dlg;
    B.SetBounds(10, 10, 80, 30);
    FMenu := NewMenu(Dlg);
    OwnerWnd := 0;
    DlgOpen := False;
    FProbe.Post(
      procedure
      begin
        // im modalen Dialog: Menue aus dem Dialog
        FProbe.Post(
          procedure
          begin
            if PPGActiveMenuLoop <> nil then
              OwnerWnd := GetWindow(PPGActiveMenuLoop.TopWindow.Handle, GW_OWNER);
            PostKey(B.Handle, VK_ESCAPE);
          end);
        FMenu.Popup(80, 80);
        // Esc schloss nur das Menue, nicht den Dialog
        DlgOpen := Dlg.Visible and (Dlg.ModalResult = mrNone);
        Dlg.ModalResult := mrOk;
      end, False);
    Res := Dlg.ShowModal;
    CheckEquals(mrOk, Res);
    CheckEquals(Dlg.Handle, OwnerWnd, 'Besitzer = Dialog');
    CheckTrue(DlgOpen, 'Esc schliesst nur das Menue');
    CheckNoSafety('Dialog');
    CheckClosed('Dialog');
  finally
    FMenu := nil;
    Dlg.Free;
  end;
end;

procedure TPopupMenuBasicsTests.LogPopup(Sender: TObject);
begin
  FLog.Add('onpopup');
end;

procedure TPopupMenuBasicsTests.LogClose(Sender: TObject);
begin
  FLog.Add('onclose');
end;

procedure TPopupMenuBasicsTests.ShowFirstPopup(Sender: TObject);
begin
  FLog.Add('onpopup');
  TPopupMenu(Sender).Items[0].Visible := True;
end;

procedure TPopupMenuBasicsTests.ExitClick(Sender: TObject);
begin
  FLog.Add('click:Exit:' + System.SysUtils.BoolToStr(PPGActiveMenuLoop = nil, True));
end;

procedure TPopupMenuBasicsTests.EmptyMenuDoesNotOpen;
var
  G: TPPGGrid;
  I: Integer;
begin
  FForm.Show;
  FMenu := NewMenu(FForm);
  for I := 0 to FMenu.Items.Count - 1 do
    FMenu.Items[I].Visible := False;
  FMenu.OnPopup := LogPopup;
  FMenu.OnClose := LogClose;
  // Direkt: kehrt sofort zurueck, keine Schleife, kein Fenster
  // Sicherung: oeffnet das leere Menue doch, schliesst die Probe es (Test schlaegt fehl statt zu haengen)
  FProbe.Post(procedure begin end);
  FMenu.Popup(50, 50);
  CheckEquals('onpopup,onclose', FLog.CommaText, 'Popup direkt');
  CheckClosed('leer direkt');
  // Rechtsklick (Kontextmenue nur mit unsichtbaren Eintraegen)
  FLog.Clear;
  G := TPPGGrid.Create(FForm);
  G.Parent := FForm;
  G.SetBounds(10, 50, 300, 150);
  G.PopupMenu := FMenu;
  Pump;
  FProbe.Post(procedure begin end);
  PostMessage(G.Handle, WM_RBUTTONDOWN, MK_RBUTTON, MouseLParam(80, 80));
  PostMessage(G.Handle, WM_RBUTTONUP, 0, MouseLParam(80, 80));
  Pump;
  CheckEquals('onpopup,onclose', FLog.CommaText, 'Rechtsklick');
  CheckClosed('leer Rechtsklick');
  // Ein Klick danach kommt normal an (wird nicht von einem leeren Menue verbraucht)
  FLog.Clear;
  FButton := TPPGButton.Create(FForm);
  FButton.Parent := FForm;
  FButton.SetBounds(10, 10, 80, 25);
  FButton.OnClick := ExitClick;
  FButton.Caption := 'Exit';
  Pump;
  FProbe.Post(procedure begin end);
  FMenu.Popup(50, 50);
  PostClick(FButton.Handle);
  Pump;
  CheckEquals('onpopup,onclose,click:Exit:True', FLog.CommaText, 'Klick nach leerem Menue');
  CheckNoSafety('leer');
  // Macht OnPopup einen Eintrag sichtbar, oeffnet das Menue (Esc schliesst)
  FLog.Clear;
  FMenu.OnPopup := ShowFirstPopup;
  FProbe.Post(procedure begin PostKey(G.Handle, VK_ESCAPE); end);
  FMenu.Popup(50, 50);
  CheckNoSafety('sichtbar gemacht');
  CheckClosed('sichtbar gemacht');
  CheckEquals('onpopup,onclose', FLog.CommaText, 'in OnPopup sichtbar gemacht');
end;

initialization
  RegisterTest('Menues', TPopupMenuBasicsTests.Suite);

end.
