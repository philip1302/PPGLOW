unit PPG.Tests.Phase11a;

{ Tests fuer Phase 11a-c: Platzierung, Nachrichten-Verteiler, Menues
  (TPPGMenuLoop, TPPGPopupMenu) und Menueleiste (TPPGMenuBar). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Menus, Vcl.StdCtrls, Vcl.ActnList,
  {$IF CompilerVersion >= 24.0}System.Actions,{$IFEND}
  PPG.Types, PPG.Render.Registry, PPG.Controls.Base, PPG.Popup.Placement, PPG.AppHooks,
  PPG.Accessibility, PPG.Menus, PPG.MenuBar, PPG.Button, PPG.Edit, PPG.Consts, PPG.Lang,
  PPG.Tests.Controls;


type
  TPlacementTests = class(TTestCase)
  published
    procedure BelowAndFlipAbove;
    procedure PointAnchorOpensLeftAtRightEdge;
    procedure SubmenuRightAndFlipLeft;
    procedure ClampHeightMarksClipped;
  end;

  TMenuTestCase = class(TControlTestCase)
  protected
    FLog: TStringList;
    FMenu: TPopupMenu;
    FFocus: TPPGButton;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure ItemClick(Sender: TObject);
    procedure OwnerDraw(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
      State: TOwnerDrawState);
    procedure ActionUpdate(Sender: TObject);
    procedure ActionExecute(Sender: TObject);
    /// Datei (Neu, Oeffnen, -, Zuletzt > (A, B), -, Beenden Strg+Q)
    procedure BuildMenu(M: TMenu);
    function NewItem(Owner: TComponent; const Caption: string): TMenuItem;
    procedure PostKey(VK: Word; Sys: Boolean = False);
    procedure Pump;
  end;

  TMenuLoopTests = class(TMenuTestCase)
  private
    FLoopToClose: TPPGMenuLoop;
    procedure CloseLoopOnClick(Sender: TObject);
    procedure PopupClosed(Sender: TObject);
  published
    procedure SubmenuDefaultActionIsPosted;
    procedure SubmenuClickThatClosesLoopOpensNothing;
    procedure PopupMenuFreedWhileOpen;
    procedure HookChainOrderAndRemoval;
    procedure OpenLoadsVisibleItemsAndReducesLines;
    procedure KeyboardNavigationAndSubmenu;
    procedure MnemonicUniqueAndAmbiguous;
    procedure ExecuteClosesFirstThenClicks;
    procedure DisabledItemNotExecuted;
    procedure ActionsAreUpdatedBeforeShow;
    procedure KeysViaApplicationHook;
    procedure ClickOutsideClosesAndIsEaten;
    procedure PopupMenuIsModalLikeVcl;
    procedure AccessibilityOfMenuWindow;
    procedure OwnerDrawEventIsCalled;
    procedure PaintsInAllPresets;
    procedure MenuGallery;
  end;

  TMenuBarTests = class(TMenuTestCase)
  private
    FMain: TMainMenu;
    function NewBar: TPPGMenuBar;
    procedure HideOnClick(Sender: TObject);
  published
    procedure ClickHandlerRebuildingMenuOpensNothing;
    procedure DefaultActionIsPostedAndChecked;
    procedure HidesAndRestoresFormMenu;
    procedure KeyboardModeAndArrows;
    procedure AltKeyEntersKeyboardMode;
    procedure AltMnemonicOpensItem;
    procedure ShortcutsStillWork;
    procedure SwitchingKeepsKeyboardMode;
    procedure MouseOpensAndSecondClickCloses;
  end;

  TFieldMenuTests = class(TMenuTestCase)
  private
    function NewEdit: TPPGEdit;
    function ItemEnabled(M: TPopupMenu; Tag: Integer): Boolean;
  published
    procedure StatesFollowSelectionAndReadOnly;
    procedure CommandsWorkOnTheEdit;
    procedure ContextMenuMessageShowsSuiteMenu;
  end;

implementation

uses
  Winapi.oleacc, System.StrUtils, Vcl.Imaging.pngimage, PPG.Theme;

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

{ TPlacementTests }

procedure TPlacementTests.BelowAndFlipAbove;
var
  P: TPPGPlacement;
  WA: TRect;
begin
  WA := Rect(0, 0, 1000, 800);
  P := PPGPlacePopup(Rect(100, 100, 300, 130), 200, 300, ppsBelow, WA, False, True);
  CheckTrue(P.Side = ppsBelow);
  CheckEquals(130, P.Bounds.Top);
  CheckEquals(100, P.Bounds.Left);
  CheckFalse(P.Clipped);
  // Unten zu wenig Platz, oben mehr: kippen
  P := PPGPlacePopup(Rect(100, 700, 300, 730), 200, 300, ppsBelow, WA, False, True);
  CheckTrue(P.Side = ppsAbove);
  CheckEquals(700, P.Bounds.Bottom);
  // AlignEnd: rechtsbuendig am Anker
  P := PPGPlacePopup(Rect(100, 100, 300, 130), 150, 100, ppsBelow, WA, True, True);
  CheckEquals(300, P.Bounds.Right);
end;

procedure TPlacementTests.PointAnchorOpensLeftAtRightEdge;
var
  P: TPPGPlacement;
begin
  // Kontextmenue am Punkt nahe dem rechten Rand: klappt nach links auf
  P := PPGPlacePopup(Rect(950, 100, 950, 100), 200, 100, ppsBelow, Rect(0, 0, 1000, 800),
    False, True);
  CheckEquals(750, P.Bounds.Left);
  CheckEquals(950, P.Bounds.Right);
  // Feld als Anker: nur in die Arbeitsflaeche geschoben
  P := PPGPlacePopup(Rect(900, 100, 980, 130), 200, 100, ppsBelow, Rect(0, 0, 1000, 800),
    False, True);
  CheckEquals(1000, P.Bounds.Right);
end;

procedure TPlacementTests.SubmenuRightAndFlipLeft;
var
  P: TPPGPlacement;
begin
  P := PPGPlacePopup(Rect(100, 100, 300, 130), 200, 150, ppsRight, Rect(0, 0, 1000, 800),
    False, False);
  CheckTrue(P.Side = ppsRight);
  CheckEquals(300, P.Bounds.Left);
  CheckEquals(100, P.Bounds.Top, 'oben buendig');
  P := PPGPlacePopup(Rect(700, 100, 900, 130), 200, 150, ppsRight, Rect(0, 0, 1000, 800),
    False, False);
  CheckTrue(P.Side = ppsLeft, 'rechts kein Platz');
  CheckEquals(700, P.Bounds.Right);
  // Unten zu wenig Platz: nach oben geschoben
  P := PPGPlacePopup(Rect(100, 750, 300, 780), 200, 150, ppsRight, Rect(0, 0, 1000, 800),
    False, False);
  CheckEquals(800, P.Bounds.Bottom);
end;

procedure TPlacementTests.ClampHeightMarksClipped;
var
  P: TPPGPlacement;
begin
  P := PPGPlacePopup(Rect(100, 100, 300, 130), 200, 2000, ppsBelow, Rect(0, 0, 1000, 800),
    False, True);
  CheckTrue(P.Clipped);
  CheckTrue(P.Bounds.Bottom <= 800);
end;

{ TMenuTestCase }

procedure TMenuTestCase.SetUp;
begin
  inherited SetUp;
  FLog := TStringList.Create;
  FMenu := TPopupMenu.Create(FForm);
  BuildMenu(FMenu);
  FFocus := NewButton('Fokus');
end;

procedure TMenuTestCase.TearDown;
begin
  if PPGActiveMenuLoop <> nil then
    PPGActiveMenuLoop.CloseAll;
  PPGFlushMenuExecute;
  FreeAndNil(FLog);
  inherited TearDown;
end;

function TMenuTestCase.NewItem(Owner: TComponent; const Caption: string): TMenuItem;
begin
  Result := TMenuItem.Create(Owner);
  Result.Caption := Caption;
  Result.OnClick := ItemClick;
end;

procedure TMenuTestCase.BuildMenu(M: TMenu);
var
  Recent, It: TMenuItem;
begin
  M.Items.Add(NewItem(M, '&Neu'));
  M.Items.Add(NewItem(M, '&Oeffnen'));
  M.Items.Add(NewItem(M, '-'));
  M.Items.Add(NewItem(M, '-')); // doppelter Trenner -> einer
  Recent := NewItem(M, '&Zuletzt');
  Recent.OnClick := nil;
  M.Items.Add(Recent);
  Recent.Add(NewItem(M, 'A'));
  Recent.Add(NewItem(M, 'B'));
  It := NewItem(M, 'Unsichtbar');
  It.Visible := False;
  M.Items.Add(It);
  M.Items.Add(NewItem(M, '-'));
  It := NewItem(M, '&Beenden');
  It.ShortCut := ShortCut(Ord('Q'), [ssCtrl]);
  M.Items.Add(It);
  M.Items.Add(NewItem(M, 'Ordner'));     // Mehrdeutig mit "Oeffnen" (erster Buchstabe O)
  M.Items.Add(NewItem(M, '-'));          // Trenner am Ende -> weg
end;

procedure TMenuTestCase.ItemClick(Sender: TObject);
begin
  FLog.Add('click:' + StripHotkey(TMenuItem(Sender).Caption) + ':' +
    System.SysUtils.BoolToStr(PPGActiveMenuLoop = nil, True));
end;

procedure TMenuTestCase.OwnerDraw(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
  State: TOwnerDrawState);
begin
  FLog.Add('draw:' + TMenuItem(Sender).Caption);
  ACanvas.Brush.Color := clRed;
  ACanvas.FillRect(ARect);
end;

procedure TMenuTestCase.ActionUpdate(Sender: TObject);
begin
  FLog.Add('update');
  TAction(Sender).Enabled := False;
end;

procedure TMenuTestCase.ActionExecute(Sender: TObject);
begin
  FLog.Add('execute');
end;

procedure TMenuTestCase.PostKey(VK: Word; Sys: Boolean);
begin
  if Sys then
  begin
    PostMessage(FFocus.Handle, WM_SYSKEYDOWN, VK, $20000001);
    PostMessage(FFocus.Handle, WM_SYSKEYUP, VK, LPARAM($E0000001));
  end
  else
  begin
    PostMessage(FFocus.Handle, WM_KEYDOWN, VK, 1);
    PostMessage(FFocus.Handle, WM_KEYUP, VK, LPARAM($C0000001));
  end;
end;

procedure TMenuTestCase.Pump;
var
  I: Integer;
begin
  for I := 1 to 5 do
    Application.ProcessMessages;
end;

{ TMenuLoopTests }

type
  THookProbe = class
  public
    Log: TStringList;
    Name: string;
    Eat: Boolean;
    procedure Hook(var Msg: TMsg; var Handled: Boolean);
  end;

procedure THookProbe.Hook(var Msg: TMsg; var Handled: Boolean);
begin
  if Msg.message = WM_USER + 77 then
  begin
    Log.Add(Name);
    Handled := Eat;
  end;
end;

procedure TMenuLoopTests.HookChainOrderAndRemoval;
var
  A, B: THookProbe;
  N0: Integer;
begin
  N0 := PPGMessageHookCount;
  A := THookProbe.Create;
  B := THookProbe.Create;
  try
    A.Log := FLog;
    B.Log := FLog;
    A.Name := 'A';
    B.Name := 'B';
    PPGAddMessageHook(A.Hook);
    PPGAddMessageHook(B.Hook);
    PPGAddMessageHook(B.Hook); // doppelt -> einmal
    CheckEquals(N0 + 2, PPGMessageHookCount);
    FForm.Show;
    PostMessage(FFocus.Handle, WM_USER + 77, 0, 0);
    Pump;
    CheckEquals('B,A', FLog.CommaText, 'zuletzt angemeldet zuerst');
    FLog.Clear;
    B.Eat := True;
    PostMessage(FFocus.Handle, WM_USER + 77, 0, 0);
    Pump;
    CheckEquals('B', FLog.CommaText, 'Handled stoppt die Kette');
    PPGRemoveMessageHook(B.Hook);
    PPGRemoveMessageHook(A.Hook);
    CheckEquals(N0, PPGMessageHookCount);
  finally
    PPGRemoveMessageHook(B.Hook);
    PPGRemoveMessageHook(A.Hook);
    A.Free;
    B.Free;
    FForm.Hide;
  end;
end;

procedure TMenuLoopTests.OpenLoadsVisibleItemsAndReducesLines;
var
  L: TPPGMenuLoop;
  W: TPPGMenuWindow;
  I: Integer;
  S: string;
begin
  FForm.Show;
  L := TPPGMenuLoop.Create;
  try
    L.StyleSource := FFocus;
    L.OpenPopup(FMenu.Items, Rect(100, 100, 100, 100), ppsBelow, False);
    CheckTrue(L.Active);
    CheckEquals(1, L.OpenCount);
    W := L.TopWindow;
    CheckTrue(W.IsOpen);
    S := '';
    for I := 0 to W.ItemCount - 1 do
      S := S + StripHotkey(W.Item(I).Caption) + '|';
    CheckEquals('Neu|Oeffnen|-|Zuletzt|-|Beenden|Ordner|', S, 'unsichtbar und doppelte/aeussere Trenner weg');
    CheckEquals(-1, W.Hot, 'Maus: keine Hervorhebung');
    CheckTrue(W.Width > 100);
    L.CloseAll;
    CheckFalse(L.Active);
    CheckFalse(W.IsOpen);
    CheckNull(PPGActiveMenuLoop);
  finally
    L.Free;
    FForm.Hide;
  end;
end;

procedure TMenuLoopTests.KeyboardNavigationAndSubmenu;
var
  L: TPPGMenuLoop;
  W: TPPGMenuWindow;
begin
  FForm.Show;
  L := TPPGMenuLoop.Create;
  try
    L.ShowAccelerators := True;
    L.OpenPopup(FMenu.Items, Rect(100, 100, 100, 100), ppsBelow, False);
    W := L.TopWindow;
    CheckEquals(0, W.Hot, 'Tastatur: erster Eintrag');
    L.HandleKey(VK_DOWN, []);
    CheckEquals(1, W.Hot);
    L.HandleKey(VK_DOWN, []);
    CheckEquals(3, W.Hot, 'Trenner uebersprungen');
    L.HandleKey(VK_UP, []);
    L.HandleKey(VK_UP, []);
    L.HandleKey(VK_UP, []);
    CheckEquals(6, W.Hot, 'Umlauf nach oben');
    L.HandleKey(VK_HOME, []);
    CheckEquals(0, W.Hot);
    L.HandleKey(VK_DOWN, []);
    L.HandleKey(VK_DOWN, []);
    CheckEquals('Zuletzt', StripHotkey(W.Item(W.Hot).Caption));
    L.HandleKey(VK_RIGHT, []);
    CheckEquals(2, L.OpenCount, 'Untermenue offen');
    CheckEquals(0, L.TopWindow.Hot, 'erster Eintrag im Untermenue');
    CheckTrue(L.TopWindow.Left >= W.Left + W.Width - 10, 'rechts daneben');
    L.HandleKey(VK_LEFT, []);
    CheckEquals(1, L.OpenCount, 'Pfeil links schliesst nur die Ebene');
    L.HandleKey(VK_RETURN, []);
    CheckEquals(2, L.OpenCount, 'Enter oeffnet');
    L.HandleKey(VK_ESCAPE, []);
    CheckEquals(1, L.OpenCount, 'Esc schliesst nur die Ebene');
    L.HandleKey(VK_ESCAPE, []);
    CheckFalse(L.Active, 'Esc auf Ebene 0 schliesst alles');
    CheckEquals(0, FLog.Count, 'nichts ausgeloest');
  finally
    L.Free;
    FForm.Hide;
  end;
end;

procedure TMenuLoopTests.MnemonicUniqueAndAmbiguous;
var
  L: TPPGMenuLoop;
  W: TPPGMenuWindow;
begin
  FForm.Show;
  L := TPPGMenuLoop.Create;
  try
    L.OpenPopup(FMenu.Items, Rect(100, 100, 100, 100), ppsBelow, False);
    W := L.TopWindow;
    // O: "&Oeffnen" (Mnemonic) und "Ordner" (erster Buchstabe) -> reihum
    L.HandleChar('o');
    CheckEquals(1, W.Hot);
    CheckTrue(L.Active, 'mehrdeutig: nur hervorheben');
    L.HandleChar('o');
    CheckEquals(6, W.Hot, 'naechster Treffer');
    // Z: eindeutig mit Untermenue -> oeffnet
    L.HandleChar('z');
    CheckEquals(2, L.OpenCount);
    // A im Untermenue: eindeutig -> ausloesen
    L.HandleChar('a');
    CheckFalse(L.Active, 'ausgeloest und geschlossen');
    PPGFlushMenuExecute;
    CheckEquals('click:A:True', FLog.CommaText);
  finally
    L.Free;
    FForm.Hide;
  end;
end;

procedure TMenuLoopTests.ExecuteClosesFirstThenClicks;
var
  L: TPPGMenuLoop;
begin
  FForm.Show;
  L := TPPGMenuLoop.Create;
  try
    L.OpenPopup(FMenu.Items, Rect(100, 100, 100, 100), ppsBelow, False);
    L.Execute(FMenu.Items[0]);
    CheckFalse(L.Active);
    CheckEquals(0, FLog.Count, 'Klick kommt erst ueber die Nachrichtenschleife');
    CheckTrue(L.Selected = FMenu.Items[0]);
    Pump;
    CheckEquals('click:Neu:True', FLog.CommaText, 'nach dem Schliessen, ohne offenes Menue');
  finally
    L.Free;
    FForm.Hide;
  end;
end;

procedure TMenuLoopTests.DisabledItemNotExecuted;
var
  L: TPPGMenuLoop;
begin
  FForm.Show;
  FMenu.Items[0].Enabled := False;
  L := TPPGMenuLoop.Create;
  try
    L.ShowAccelerators := True;
    L.OpenPopup(FMenu.Items, Rect(100, 100, 100, 100), ppsBelow, False);
    CheckEquals(0, L.TopWindow.Hot, 'deaktiviert, aber erreichbar (wie Windows)');
    L.HandleKey(VK_RETURN, []);
    CheckTrue(L.Active, 'Enter auf deaktiviertem Eintrag tut nichts');
    L.Execute(FMenu.Items[0]);
    Pump;
    CheckEquals(0, FLog.Count);
  finally
    L.Free;
    FForm.Hide;
  end;
end;

procedure TMenuLoopTests.ActionsAreUpdatedBeforeShow;
var
  AL: TActionList;
  A: TAction;
  L: TPPGMenuLoop;
begin
  AL := TActionList.Create(FForm);
  A := TAction.Create(AL);
  A.ActionList := AL;
  A.Caption := 'Aktion';
  A.OnUpdate := ActionUpdate;
  A.OnExecute := ActionExecute;
  FMenu.Items[0].Action := A;
  FForm.Show;
  L := TPPGMenuLoop.Create;
  try
    L.OpenPopup(FMenu.Items, Rect(100, 100, 100, 100), ppsBelow, False);
    CheckTrue(FLog.IndexOf('update') >= 0, 'OnUpdate vor dem Zeigen');
    CheckFalse(FMenu.Items[0].Enabled, 'Action hat deaktiviert');
    CheckEquals('Aktion', L.TopWindow.Item(0).Caption);
  finally
    L.Free;
    FForm.Hide;
  end;
end;

procedure TMenuLoopTests.KeysViaApplicationHook;
var
  L: TPPGMenuLoop;
begin
  FForm.Show;
  FFocus.SetFocus;
  L := TPPGMenuLoop.Create;
  try
    L.ShowAccelerators := True;
    L.OpenPopup(FMenu.Items, Rect(100, 100, 100, 100), ppsBelow, False);
    // Tasten gehen an den fokussierten Button, der Haken leitet sie ans Menue
    PostKey(VK_DOWN);
    Pump;
    CheckEquals(1, L.TopWindow.Hot);
    PostMessage(FFocus.Handle, WM_CHAR, Ord('n'), 1);
    Pump;
    CheckFalse(L.Active, 'Mnemonic per WM_CHAR');
    Pump;
    CheckEquals('click:Neu:True', FLog.CommaText);
    // Alt schliesst ein offenes Menue
    L.OpenPopup(FMenu.Items, Rect(100, 100, 100, 100), ppsBelow, False);
    PostKey(VK_MENU, True);
    Pump;
    CheckFalse(L.Active, 'Alt schliesst');
  finally
    L.Free;
    FForm.Hide;
  end;
end;

procedure TMenuLoopTests.ClickOutsideClosesAndIsEaten;
var
  L: TPPGMenuLoop;
  B: TPPGButton;
begin
  FForm.Show;
  B := NewButton('Andere');
  B.SetBounds(200, 200, 100, 30);
  B.OnClick := ItemClick;
  L := TPPGMenuLoop.Create;
  try
    L.OpenPopup(FMenu.Items, Rect(10, 10, 10, 10), ppsBelow, False);
    PostMessage(B.Handle, WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(10, 10));
    PostMessage(B.Handle, WM_LBUTTONUP, 0, MouseLParam(10, 10));
    Pump;
    CheckFalse(L.Active, 'Klick daneben schliesst');
    CheckEquals(0, FLog.Count, 'der Klick wird verbraucht (kein Button-Klick)');
    // Anwendung verliert die Aktivierung (Alt+Tab): schliesst
    L.OpenPopup(FMenu.Items, Rect(10, 10, 10, 10), ppsBelow, False);
    CheckTrue(L.Active);
    // Windows schickt WM_ACTIVATEAPP an das Anwendungsfenster, die VCL meldet
    // daraufhin Application.OnDeactivate (Verteiler von TApplicationEvents).
    // Die Test-Exe ist ein Konsolenprogramm ohne Anwendungsfenster (Handle 0):
    // dann wird das VCL-Ereignis direkt ausgeloest
    if Application.Handle <> 0 then
      SendMessage(Application.Handle, WM_ACTIVATEAPP, 0, 0)
    else
    begin
      CheckTrue(Assigned(Application.OnDeactivate), 'Verteiler von TApplicationEvents');
      Application.OnDeactivate(Application);
    end;
    Pump;
    CheckFalse(L.Active, 'Deaktivieren der Anwendung schliesst');
    if Application.Handle <> 0 then
      SendMessage(Application.Handle, WM_ACTIVATEAPP, 1, 0);
    Pump;
  finally
    L.Free;
    FForm.Hide;
  end;
end;

procedure TMenuLoopTests.PopupMenuIsModalLikeVcl;
var
  M: TPPGPopupMenu;
begin
  FForm.Show;
  FFocus.SetFocus;
  M := TPPGPopupMenu.Create(FForm);
  BuildMenu(M);
  M.PopupComponent := FFocus;
  // Tasten vorab in die Warteschlange: die modale Schleife verarbeitet sie
  PostKey(VK_DOWN);
  PostKey(VK_RETURN);
  M.Popup(100, 100);
  CheckNull(M.Loop, 'Popup kehrt nach dem Schliessen zurueck');
  CheckNull(PPGActiveMenuLoop);
  Pump;
  CheckEquals('click:Neu:True', FLog.CommaText, 'Klick nach dem Schliessen');
  // Esc: kein Klick
  FLog.Clear;
  PostKey(VK_ESCAPE);
  M.Popup(100, 100);
  Pump;
  CheckEquals(0, FLog.Count);
  FForm.Hide;
end;

type
  /// Gibt Target frei, sobald WM_USER + 79 durch die Nachrichtenschleife laeuft.
  TMenuFreer = class
  public
    Target: TComponent;
    procedure Hook(var Msg: TMsg; var Handled: Boolean);
  end;

procedure TMenuFreer.Hook(var Msg: TMsg; var Handled: Boolean);
begin
  if Msg.message = WM_USER + 79 then
  begin
    FreeAndNil(Target);
    Handled := True;
  end;
end;

procedure TMenuLoopTests.CloseLoopOnClick(Sender: TObject);
begin
  FLog.Add('closeloop');
  FLoopToClose.CloseAll;
end;

procedure TMenuLoopTests.PopupClosed(Sender: TObject);
begin
  FLog.Add('closed');
end;

procedure TMenuLoopTests.SubmenuDefaultActionIsPosted;
var
  L: TPPGMenuLoop;
  A: IPPGAccessibleChildren;
begin
  // Audit 08.10.2026: Die Standardaktion eines Untermenue-Eintrags rief
  // OpenSubmenu (und damit OnClick) synchron im COM-Aufruf auf.
  FForm.Show;
  L := TPPGMenuLoop.Create;
  try
    L.OpenPopup(FMenu.Items, Rect(100, 100, 100, 100), ppsBelow, False);
    CheckTrue(Supports(L.TopWindow, IPPGAccessibleChildren, A));
    A.AccChildDoDefault(4); // Zuletzt
    CheckEquals(1, L.OpenCount, 'nicht im COM-Aufruf');
    Pump;
    CheckEquals(2, L.OpenCount, 'gepostet geoeffnet');
    // Inzwischen geschlossen: die gepostete Aktion verfaellt
    L.CloseFrom(1);
    A.AccChildDoDefault(4);
    L.CloseAll;
    Pump;
    CheckEquals(0, L.OpenCount);
    CheckFalse(L.Active);
    A := nil;
  finally
    L.Free;
    FForm.Hide;
  end;
end;

procedure TMenuLoopTests.SubmenuClickThatClosesLoopOpensNothing;
var
  L: TPPGMenuLoop;
begin
  // Audit 08.10.2026: Beendete OnClick des Untermenue-Eintrags die Schleife,
  // oeffnete OpenSubmenu trotzdem ein Fenster ohne Hooks.
  FForm.Show;
  L := TPPGMenuLoop.Create;
  try
    L.OpenPopup(FMenu.Items, Rect(100, 100, 100, 100), ppsBelow, False);
    FLoopToClose := L;
    FMenu.Items[4].OnClick := CloseLoopOnClick; // Zuletzt
    L.OpenSubmenu(L.TopWindow, 3, False);
    CheckEquals('closeloop', FLog.CommaText);
    CheckFalse(L.Active);
    CheckEquals(0, L.OpenCount, 'kein Untermenue geoeffnet');
  finally
    FMenu.Items[4].OnClick := nil;
    FLoopToClose := nil;
    L.Free;
    FForm.Hide;
  end;
end;

procedure TMenuLoopTests.PopupMenuFreedWhileOpen;
var
  M: TPPGPopupMenu;
  Freer: TMenuFreer;
begin
  // Audit 08.10.2026: Wurde das Menue waehrend der modalen Schleife
  // freigegeben, schrieb PopupAtRect danach in Self und rief DoClose.
  FForm.Show;
  FFocus.SetFocus;
  M := TPPGPopupMenu.Create(FForm);
  BuildMenu(M);
  M.PopupComponent := FFocus;
  M.OnClose := PopupClosed;
  Freer := TMenuFreer.Create;
  try
    Freer.Target := M;
    PPGAddMessageHook(Freer.Hook);
    PostMessage(FFocus.Handle, WM_USER + 79, 0, 0);
    M.Popup(100, 100);
    CheckNull(Freer.Target, 'Menue in der Schleife freigegeben');
    CheckEquals(-1, FLog.IndexOf('closed'), 'kein OnClose nach der Freigabe');
    CheckNull(PPGActiveMenuLoop);
  finally
    PPGRemoveMessageHook(Freer.Hook);
    Freer.Target.Free;
    Freer.Free;
    FForm.Hide;
  end;
end;

procedure TMenuLoopTests.AccessibilityOfMenuWindow;
var
  L: TPPGMenuLoop;
  W: TPPGMenuWindow;
  A: IPPGAccessibleChildren;
  I: Integer;
begin
  FForm.Show;
  FMenu.Items[1].Checked := True;
  L := TPPGMenuLoop.Create;
  try
    L.OpenPopup(FMenu.Items, Rect(100, 100, 100, 100), ppsBelow, False);
    W := L.TopWindow;
    CheckTrue(Supports(W, IPPGAccessibleChildren, A));
    CheckEquals(W.ItemCount, A.AccChildCount);
    CheckEquals('Neu', A.AccChildName(1));
    CheckEquals(ROLE_SYSTEM_MENUITEM, A.AccChildRole(1));
    CheckEquals(ROLE_SYSTEM_SEPARATOR, A.AccChildRole(3));
    CheckTrue(A.AccChildState(2) and STATE_SYSTEM_CHECKED <> 0, 'Haken');
    I := 4; // Zuletzt
    CheckTrue(A.AccChildState(I) and STATE_SYSTEM_HASPOPUP <> 0, 'Untermenue');
    W.SetHot(0);
    CheckEquals(1, A.AccFocusedChild);
    CheckTrue(A.AccChildState(1) and STATE_SYSTEM_FOCUSED <> 0);
  finally
    L.Free;
    FForm.Hide;
  end;
end;

procedure TMenuLoopTests.OwnerDrawEventIsCalled;
var
  L: TPPGMenuLoop;
begin
  FForm.Show;
  FMenu.Items[0].OnAdvancedDrawItem := OwnerDraw;
  L := TPPGMenuLoop.Create;
  try
    // Wie die VCL: ohne OwnerDraw (und ohne Images) kein Ereignis
    L.OpenPopup(FMenu.Items, Rect(100, 100, 100, 100), ppsBelow, False);
    RenderToBitmap(L.TopWindow).Free;
    CheckEquals(-1, FLog.IndexOf('draw:&Neu'), 'ohne OwnerDraw nicht aufgerufen');
    L.CloseAll;
    FMenu.OwnerDraw := True;
    L.OpenPopup(FMenu.Items, Rect(100, 100, 100, 100), ppsBelow, False);
    RenderToBitmap(L.TopWindow).Free;
    CheckTrue(FLog.IndexOf('draw:&Neu') >= 0, 'mit OwnerDraw aufgerufen');
  finally
    L.Free;
    FForm.Hide;
  end;
end;

procedure TMenuLoopTests.PaintsInAllPresets;
var
  Names: TStringList;
  P: Integer;
  Dark, Gdi: Boolean;
  L: TPPGMenuLoop;
  B: TBitmap;
begin
  Names := TStringList.Create;
  FForm.Show;
  L := TPPGMenuLoop.Create;
  try
    FMenu.Items[1].Checked := True;
    FMenu.Items[0].Default := True;
    TPPGRendererRegistry.GetNames(Names);
    for P := 0 to Names.Count - 1 do
      for Dark := False to True do
        for Gdi := False to True do
        begin
          if Dark then
            TPPGTheme.Mode := tmDark
          else
            TPPGTheme.Mode := tmLight;
          TPPGRendererRegistry.ForceGdiFallback := Gdi;
          L.Preset := Names[P];
          L.ShowAccelerators := True;
          L.OpenPopup(FMenu.Items, Rect(100, 100, 100, 100), ppsBelow, False);
          L.HandleKey(VK_DOWN, []);
          L.HandleKey(VK_DOWN, []);
          L.HandleKey(VK_RIGHT, []);
          B := RenderToBitmap(L.Window(0));
          B.Free;
          RenderToBitmap(L.TopWindow).Free;
          L.CloseAll;
        end;
  finally
    TPPGTheme.Mode := tmLight;
    TPPGRendererRegistry.ForceGdiFallback := False;
    L.Free;
    Names.Free;
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TMenuLoopTests.MenuGallery;
var
  Names: TStringList;
  P, Row, X: Integer;
  Dark: Boolean;
  L: TPPGMenuLoop;
  B, Sub, Sheet: TBitmap;
  Png: TPngImage;
  Dir: string;
begin
  Names := TStringList.Create;
  Sheet := TBitmap.Create;
  FForm.Show;
  L := TPPGMenuLoop.Create;
  try
    FMenu.Items[1].Checked := True;
    FMenu.Items[0].Default := True;
    FMenu.Items[7].Enabled := False; // "Beenden" deaktiviert
    L.Animate := False;
    TPPGRendererRegistry.GetNames(Names);
    Sheet.PixelFormat := pf24bit;
    Sheet.SetSize(600, Names.Count * 2 * 260);
    Sheet.Canvas.Brush.Color := clWhite;
    Sheet.Canvas.FillRect(Rect(0, 0, Sheet.Width, Sheet.Height));
    Row := 0;
    for P := 0 to Names.Count - 1 do
      for Dark := False to True do
      begin
        if Dark then
          TPPGTheme.Mode := tmDark
        else
          TPPGTheme.Mode := tmLight;
        L.Preset := Names[P];
        L.ShowAccelerators := True;
        L.OpenPopup(FMenu.Items, Rect(100, 100, 100, 100), ppsBelow, False);
        L.HandleKey(VK_DOWN, []);
        L.HandleKey(VK_DOWN, []);
        L.HandleKey(VK_RIGHT, []);
        B := RenderToBitmap(L.Window(0));
        Sub := RenderToBitmap(L.TopWindow);
        try
          Sheet.Canvas.TextOut(4, Row * 260 + 4, Names[P] + IfThen(Dark, ' dunkel', ' hell'));
          Sheet.Canvas.Draw(10, Row * 260 + 24, B);
          X := 10 + B.Width - 4;
          Sheet.Canvas.Draw(X, Row * 260 + 24 + 60, Sub);
        finally
          B.Free;
          Sub.Free;
        end;
        L.CloseAll;
        Inc(Row);
      end;
    Dir := ExtractFilePath(ParamStr(0)) + 'Visual\Gallery\';
    ForceDirectories(Dir);
    Png := TPngImage.Create;
    try
      Png.Assign(Sheet);
      Png.SaveToFile(Dir + 'Menu.png');
    finally
      Png.Free;
    end;
  finally
    TPPGTheme.Mode := tmLight;
    L.Free;
    Sheet.Free;
    Names.Free;
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;


{ TMenuBarTests }

function TMenuBarTests.NewBar: TPPGMenuBar;
var
  Datei, Bearb, It: TMenuItem;
begin
  // Datei (Neu, Zuletzt > A, Aktualisieren F5) | Bearbeiten (Kopieren) | Hilfe
  FMain := TMainMenu.Create(FForm);
  Datei := NewItem(FMain, '&Datei');
  Datei.OnClick := nil;
  FMain.Items.Add(Datei);
  Datei.Add(NewItem(FMain, '&Neu'));
  It := NewItem(FMain, '&Zuletzt');
  It.OnClick := nil;
  Datei.Add(It);
  It.Add(NewItem(FMain, 'A'));
  It := NewItem(FMain, '&Aktualisieren');
  It.ShortCut := ShortCut(VK_F5, []);
  Datei.Add(It);
  Bearb := NewItem(FMain, '&Bearbeiten');
  Bearb.OnClick := nil;
  FMain.Items.Add(Bearb);
  Bearb.Add(NewItem(FMain, '&Kopieren'));
  FMain.Items.Add(NewItem(FMain, '&Hilfe'));
  FForm.Menu := FMain;
  Result := TPPGMenuBar.Create(FForm);
  Result.Parent := FForm;
  Result.Animation.Enabled := False;
  Result.Menu := FMain;
  Result.HandleNeeded;
end;

procedure TMenuBarTests.HideOnClick(Sender: TObject);
begin
  FLog.Add('hide');
  TMenuItem(Sender).Visible := False;
end;

procedure TMenuBarTests.ClickHandlerRebuildingMenuOpensNothing;
var
  Bar: TPPGMenuBar;
begin
  // Audit 08.10.2026: OnClick beim Oeffnen darf das Menue umbauen; danach
  // wurden Index und Eintrag ungeprueft weiterbenutzt.
  FForm.Show;
  Bar := NewBar;
  FMain.Items[0].OnClick := HideOnClick; // Datei blendet sich aus
  Bar.OpenItem(0, False);
  CheckEquals('hide', FLog.CommaText);
  CheckFalse(Bar.Loop.Active, 'umgebaut: nichts oeffnen');
  CheckEquals(-1, Bar.OpenIndex);
  CheckEquals(2, Bar.ItemCount);
  FForm.Hide;
end;

procedure TMenuBarTests.DefaultActionIsPostedAndChecked;
var
  Bar: TPPGMenuBar;
  A: IPPGAccessibleChildren;
begin
  // Audit 08.10.2026: Die Standardaktion oeffnete das Menue (mit OnClick)
  // synchron im COM-Aufruf.
  FForm.Show;
  Bar := NewBar;
  CheckTrue(Supports(Bar, IPPGAccessibleChildren, A));
  A.AccChildDoDefault(1);
  CheckFalse(Bar.Loop.Active, 'nicht im COM-Aufruf');
  Pump;
  CheckTrue(Bar.Loop.Active, 'gepostet geoeffnet');
  CheckEquals(0, Bar.OpenIndex);
  Bar.CloseMenus;
  // Leiste inzwischen umgebaut: die gepostete Aktion verfaellt
  A.AccChildDoDefault(1);
  FMain.Items[0].Visible := False;
  Pump;
  CheckFalse(Bar.Loop.Active, 'anderer Eintrag an der Stelle');
  A := nil;
  FForm.Hide;
end;

procedure TMenuBarTests.HidesAndRestoresFormMenu;
var
  Bar: TPPGMenuBar;
begin
  Bar := NewBar;
  CheckNull(FForm.Menu, 'Formular-Menue zur Laufzeit geleert');
  CheckEquals(3, Bar.ItemCount);
  CheckTrue(Bar.Height > 10, 'AutoSize');
  CheckTrue(Bar.Align = alTop);
  Bar.Free;
  CheckTrue(FForm.Menu = FMain, 'beim Freigeben wiederhergestellt');
end;

procedure TMenuBarTests.KeyboardModeAndArrows;
var
  Bar: TPPGMenuBar;
begin
  FForm.Show;
  Bar := NewBar;
  Bar.EnterKeyboardMode;
  CheckTrue(Bar.KeyboardMode);
  CheckEquals(0, Bar.Hot);
  Bar.HandleBarKey(VK_RIGHT);
  CheckEquals(1, Bar.Hot);
  Bar.HandleBarKey(VK_LEFT);
  Bar.HandleBarKey(VK_LEFT);
  CheckEquals(2, Bar.Hot, 'Umlauf');
  Bar.HandleBarKey(VK_LEFT);
  Bar.HandleBarKey(VK_DOWN);
  CheckEquals(1, Bar.OpenIndex, 'Pfeil runter oeffnet');
  CheckTrue(Bar.Loop.Active);
  CheckEquals(0, Bar.Loop.TopWindow.Hot, 'erster Eintrag markiert');
  Bar.Loop.HandleKey(VK_ESCAPE, []);
  CheckFalse(Bar.Loop.Active);
  CheckTrue(Bar.KeyboardMode, 'Esc: Leiste bleibt markiert');
  CheckEquals(1, Bar.Hot);
  Bar.HandleBarKey(VK_ESCAPE);
  CheckFalse(Bar.KeyboardMode);
  CheckEquals(-1, Bar.Hot);
  FForm.Hide;
end;

procedure TMenuBarTests.AltKeyEntersKeyboardMode;
var
  Bar: TPPGMenuBar;
begin
  FForm.Show;
  Bar := NewBar;
  FFocus.SetFocus;
  PostKey(VK_MENU, True);
  Pump;
  CheckTrue(Bar.KeyboardMode, 'Alt allein');
  PostKey(VK_MENU, True);
  Pump;
  CheckFalse(Bar.KeyboardMode, 'Alt noch einmal verlaesst');
  PostKey(VK_F10, True);
  Pump;
  CheckTrue(Bar.KeyboardMode, 'F10');
  Bar.LeaveKeyboardMode;
  FForm.Hide;
end;

procedure TMenuBarTests.AltMnemonicOpensItem;
var
  Bar: TPPGMenuBar;
begin
  FForm.Show;
  Bar := NewBar;
  FFocus.SetFocus;
  PostMessage(FFocus.Handle, WM_SYSCHAR, Ord('b'), $20000001);
  Pump;
  CheckEquals(1, Bar.OpenIndex, 'Alt+B oeffnet "Bearbeiten"');
  CheckTrue(Bar.Loop.Active);
  Bar.CloseMenus;
  Bar.LeaveKeyboardMode;
  FForm.Hide;
end;

procedure TMenuBarTests.ShortcutsStillWork;
var
  Bar: TPPGMenuBar;
begin
  FForm.Show;
  Bar := NewBar;
  FFocus.SetFocus;
  CheckNull(FForm.Menu);
  PostKey(VK_F5);
  Pump;
  CheckEquals(1, FLog.Count, 'F5 loest "Aktualisieren" aus, obwohl Form.Menu leer ist');
  CheckEquals('click:Aktualisieren:True', FLog[0]);
  CheckNotNull(Bar);
  FForm.Hide;
end;

procedure TMenuBarTests.SwitchingKeepsKeyboardMode;
var
  Bar: TPPGMenuBar;
begin
  FForm.Show;
  Bar := NewBar;
  Bar.EnterKeyboardMode;
  Bar.HandleBarKey(VK_DOWN);
  CheckEquals(0, Bar.OpenIndex);
  // "Neu" hat kein Untermenue: Pfeil rechts geht zum Nachbarn der Leiste
  Bar.Loop.HandleKey(VK_RIGHT, []);
  CheckEquals(1, Bar.OpenIndex, 'Nachbar offen');
  CheckTrue(Bar.Loop.Active);
  Bar.Loop.HandleKey(VK_LEFT, []);
  CheckEquals(0, Bar.OpenIndex, 'zurueck');
  Bar.Loop.HandleKey(VK_ESCAPE, []);
  CheckTrue(Bar.KeyboardMode);
  CheckEquals(0, Bar.Hot);
  Bar.LeaveKeyboardMode;
  FForm.Hide;
end;

procedure TMenuBarTests.MouseOpensAndSecondClickCloses;
var
  Bar: TPPGMenuBar;
  R: TRect;
begin
  FForm.Show;
  Bar := NewBar;
  R := Bar.ItemRect(0);
  Bar.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam((R.Left + R.Right) div 2,
    (R.Top + R.Bottom) div 2));
  Bar.Perform(WM_LBUTTONUP, 0, MouseLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
  CheckEquals(0, Bar.OpenIndex);
  CheckTrue(Bar.Loop.Active);
  CheckEquals(-1, Bar.Loop.TopWindow.Hot, 'Maus: nichts markiert');
  // Ueberfahren des Nachbarn wechselt
  R := Bar.ItemRect(1);
  Bar.Perform(WM_MOUSEMOVE, 0, MouseLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
  CheckEquals(1, Bar.OpenIndex, 'Hot-Tracking');
  Bar.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam((R.Left + R.Right) div 2,
    (R.Top + R.Bottom) div 2));
  CheckFalse(Bar.Loop.Active, 'zweiter Klick schliesst');
  // Eintrag ohne Untermenue ("Hilfe") loest direkt aus
  R := Bar.ItemRect(2);
  Bar.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam((R.Left + R.Right) div 2,
    (R.Top + R.Bottom) div 2));
  CheckEquals('click:Hilfe:True', FLog.CommaText);
  FForm.Hide;
end;

{ TFieldMenuTests }

function TFieldMenuTests.NewEdit: TPPGEdit;
begin
  Result := TPPGEdit.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 60, 200, 28);
  Result.Animation.Enabled := False;
  Result.HandleNeeded;
end;

function TFieldMenuTests.ItemEnabled(M: TPopupMenu; Tag: Integer): Boolean;
var
  I: Integer;
begin
  for I := 0 to M.Items.Count - 1 do
    if M.Items[I].Tag = Tag then
      Exit(M.Items[I].Enabled);
  Fail('Eintrag fehlt: ' + IntToStr(Tag));
  Result := False;
end;

procedure TFieldMenuTests.StatesFollowSelectionAndReadOnly;
var
  E: TPPGEdit;
  M: TPopupMenu;
begin
  E := NewEdit;
  E.Text := 'Hallo Welt';
  E.SelStart := 0;
  E.SelLength := 0;
  M := E.BuildEditMenu;
  CheckTrue(M is TPPGPopupMenu, 'Menue im Stil der Suite');
  CheckEquals(8, M.Items.Count, '6 Befehle + 2 Trenner');
  CheckEquals(PPGStr(@SPPGEditCopy), M.Items[3].Caption, 'uebersetzter Text');
  CheckFalse(ItemEnabled(M, 2), 'Ausschneiden ohne Auswahl');
  CheckFalse(ItemEnabled(M, 3), 'Kopieren ohne Auswahl');
  CheckFalse(ItemEnabled(M, 5), 'Loeschen ohne Auswahl');
  CheckTrue(ItemEnabled(M, 6), 'Alles markieren');
  E.SelStart := 0;
  E.SelLength := 5;
  M := E.BuildEditMenu;
  CheckTrue(ItemEnabled(M, 2));
  CheckTrue(ItemEnabled(M, 3));
  CheckTrue(ItemEnabled(M, 5));
  E.ReadOnly := True;
  M := E.BuildEditMenu;
  CheckFalse(ItemEnabled(M, 2), 'ReadOnly: nicht ausschneiden');
  CheckTrue(ItemEnabled(M, 3), 'ReadOnly: kopieren geht');
  CheckFalse(ItemEnabled(M, 4), 'ReadOnly: nicht einfuegen');
  CheckFalse(ItemEnabled(M, 5), 'ReadOnly: nicht loeschen');
  E.ReadOnly := False;
  E.PasswordChar := '*';
  E.SelectAll;
  M := E.BuildEditMenu;
  CheckFalse(ItemEnabled(M, 2), 'Passwort: nicht ausschneiden');
  CheckFalse(ItemEnabled(M, 3), 'Passwort: nicht kopieren');
  CheckFalse(ItemEnabled(M, 6), 'alles schon markiert');
  E.PasswordChar := #0;
  E.Text := '';
  M := E.BuildEditMenu;
  CheckFalse(ItemEnabled(M, 6), 'leer: nichts zu markieren');
end;

procedure TFieldMenuTests.CommandsWorkOnTheEdit;
var
  E: TPPGEdit;
  M: TPopupMenu;
  I: Integer;
begin
  E := NewEdit;
  E.Text := 'abc def';
  M := E.BuildEditMenu;
  for I := 0 to M.Items.Count - 1 do
    if M.Items[I].Tag = 6 then
      M.Items[I].Click;
  CheckEquals(7, E.SelLength, 'Alles markieren');
  M := E.BuildEditMenu;
  for I := 0 to M.Items.Count - 1 do
    if M.Items[I].Tag = 5 then
      M.Items[I].Click;
  CheckEquals('', E.Text, 'Loeschen');
end;

procedure TFieldMenuTests.ContextMenuMessageShowsSuiteMenu;
var
  E: TPPGEdit;
  Inner: TWinControl;
begin
  FForm.Show;
  E := NewEdit;
  E.Text := 'Text';
  E.SetFocus;
  Inner := TWinControl(E.Controls[0]);
  // Esc vorab in die Warteschlange: die modale Menue-Schleife schliesst damit
  PostMessage(Inner.Handle, WM_KEYDOWN, VK_ESCAPE, 1);
  SendMessage(Inner.Handle, WM_CONTEXTMENU, Inner.Handle, LPARAM($FFFFFFFF));
  CheckNull(PPGActiveMenuLoop, 'Menue wieder geschlossen');
  CheckTrue(E.BuildEditMenu is TPPGPopupMenu);
  CheckFalse(E.UseSystemContextMenu, 'Vorgabe: Suite-Menue');
  FForm.Hide;
end;

initialization
  RegisterTest('Phase11a', TPlacementTests.Suite);
  RegisterTest('Phase11a', TMenuLoopTests.Suite);
  RegisterTest('Phase11a', TMenuBarTests.Suite);
  RegisterTest('Phase11a', TFieldMenuTests.Suite);

end.
