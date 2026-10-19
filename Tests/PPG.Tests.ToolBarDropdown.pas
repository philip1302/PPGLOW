unit PPG.Tests.ToolBarDropdown;

{ Tests fuer TPPGToolBar mit Aufklappmenue je Eintrag (DropdownMenu,
  DropdownStyle, OnDropdown): Pfeil und Breite, Klick bei tdsMenu und
  tdsSplit, Tausch des Menues, Freigabe des Menues, Streaming, Ueberlauf als
  Untermenue, Tastatur, Actions, RTL und Barrierefreiheit.

  Das Aufklappen laeuft ueber PopupMenuAt (Erweiterungspunkt); die Testleiste
  merkt sich den Aufruf, statt ein modales Menue zu zeigen. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, {$IF CompilerVersion >= 24.0}System.Actions,{$IFEND} Vcl.ActnList,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Menus, Winapi.oleacc,
  PPG.Types, PPG.Consts, PPG.Lang, PPG.Controls.Base, PPG.Accessibility, PPG.Menus, PPG.ToolBar,
  PPG.Tests.Controls;

type
  /// Leiste, die das Aufklappen nur protokolliert.
  TDropToolBar = class(TPPGToolBar)
  public
    PopCount: Integer;
    LastMenu: TPopupMenu;
    LastRect: TRect;
    PartDuringPopup: Integer;
  protected
    procedure PopupMenuAt(Menu: TPopupMenu; const ScreenRect: TRect); override;
  end;

  TToolBarDropdownTests = class(TControlTestCase)
  private
    FLog: TStringList;
    FSwap: TPopupMenu;
    FSwapMode: Integer; // 0 = unveraendert, 1 = tauschen, 2 = nil
    function NewBar: TDropToolBar;
    function NewMenu(const Captions: array of string): TPPGPopupMenu;
    procedure ItemClick(Sender: TObject);
    procedure MenuClick(Sender: TObject);
    procedure Dropdown(Sender: TObject; Item: TPPGToolItem; var Menu: TPopupMenu);
    procedure ClickAt(C: TWinControl; X, Y: Integer);
    procedure Key(C: TWinControl; VK: Word; Shift: TShiftState = []);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure DefaultsAndArrowWidth;
    procedure MenuStyleClickOpensMenuOnly;
    procedure SplitStyleArrowAndBody;
    procedure OnDropdownSwapsOrCancels;
    procedure DisabledSeparatorAndInvalid;
    procedure FreeingMenuClearsReference;
    procedure StreamingRoundTrip;
    procedure OverflowBuildsSubmenu;
    procedure KeyboardOpensMenu;
    procedure ActionStillWorks;
    procedure RightToLeftArrowLeft;
    procedure AccessibilityRoles;
    procedure PaintsWithArrow;
  end;

implementation

type
  TDropRoot = class(TForm);

{ TDropToolBar }

procedure TDropToolBar.PopupMenuAt(Menu: TPopupMenu; const ScreenRect: TRect);
begin
  Inc(PopCount);
  LastMenu := Menu;
  LastRect := ScreenRect;
  PartDuringPopup := DropdownPart;
end;

{ TToolBarDropdownTests }

procedure TToolBarDropdownTests.SetUp;
begin
  inherited SetUp;
  FLog := TStringList.Create;
  FSwapMode := 0;
  FSwap := nil;
end;

procedure TToolBarDropdownTests.TearDown;
begin
  FreeAndNil(FLog);
  inherited TearDown;
end;

function TToolBarDropdownTests.NewBar: TDropToolBar;
begin
  Result := TDropToolBar.Create(FForm);
  Result.Parent := FForm;
  Result.Width := 600;
  Result.PartDuringPopup := -5;
  Result.HandleNeeded;
end;

function TToolBarDropdownTests.NewMenu(const Captions: array of string): TPPGPopupMenu;
var
  I: Integer;
  M: TMenuItem;
begin
  Result := TPPGPopupMenu.Create(FForm);
  for I := 0 to High(Captions) do
  begin
    M := TMenuItem.Create(Result);
    M.Caption := Captions[I];
    M.OnClick := MenuClick;
    Result.Items.Add(M);
  end;
end;

procedure TToolBarDropdownTests.ItemClick(Sender: TObject);
begin
  FLog.Add('click:' + TPPGToolItem(Sender).Caption);
end;

procedure TToolBarDropdownTests.MenuClick(Sender: TObject);
begin
  FLog.Add('menu:' + StripHotkey(TMenuItem(Sender).Caption));
end;

procedure TToolBarDropdownTests.Dropdown(Sender: TObject; Item: TPPGToolItem;
  var Menu: TPopupMenu);
begin
  FLog.Add('dropdown:' + Item.Caption);
  case FSwapMode of
    1: Menu := FSwap;
    2: Menu := nil;
  end;
end;

procedure TToolBarDropdownTests.ClickAt(C: TWinControl; X, Y: Integer);
begin
  C.Perform(WM_MOUSEMOVE, 0, MakeLParam(Word(X), Word(Y)));
  C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Word(X), Word(Y)));
  C.Perform(WM_LBUTTONUP, 0, MakeLParam(Word(X), Word(Y)));
end;

type
  TWinAccessTB = class(TWinControl);

procedure TToolBarDropdownTests.Key(C: TWinControl; VK: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := VK;
  TWinAccessTB(C).KeyDown(K, Shift);
end;

procedure TToolBarDropdownTests.DefaultsAndArrowWidth;
var
  T: TDropToolBar;
  It: TPPGToolItem;
  W0, W1, W2: Integer;
  AR, R: TRect;
begin
  T := NewBar;
  It := T.Items.AddButton('Ansicht', $E890);
  CheckTrue(It.DropdownStyle = tdsMenu, 'Vorgabe tdsMenu');
  CheckNull(It.DropdownMenu);
  CheckFalse(It.HasDropdown);
  CheckTrue(IsRectEmpty(T.ItemArrowRect(0)), 'ohne Menue kein Pfeil');
  CheckEquals(-1, T.DropdownPart);
  W0 := T.ItemRect(0).Right - T.ItemRect(0).Left;
  It.DropdownMenu := NewMenu(['Liste']);
  CheckTrue(It.HasDropdown);
  W1 := T.ItemRect(0).Right - T.ItemRect(0).Left;
  CheckEquals(W0 + 14, W1, 'Pfeil tdsMenu: 14 px breiter');
  It.DropdownStyle := tdsSplit;
  W2 := T.ItemRect(0).Right - T.ItemRect(0).Left;
  CheckEquals(W0 + 18, W2, 'Pfeilteil tdsSplit: 18 px');
  AR := T.ItemArrowRect(0);
  R := T.ItemRect(0);
  CheckEquals(R.Right, AR.Right, 'Pfeil rechts');
  CheckEquals(18, AR.Right - AR.Left);
  CheckEquals(R.Top, AR.Top);
  CheckEquals(R.Bottom, AR.Bottom);
end;

procedure TToolBarDropdownTests.MenuStyleClickOpensMenuOnly;
var
  T: TDropToolBar;
  It: TPPGToolItem;
  M: TPPGPopupMenu;
  R: TRect;
  P: TPoint;
begin
  FForm.Show;
  try
    T := NewBar;
    T.Items.AddButton('Neu', $E710, ItemClick);
    It := T.Items.AddButton('Ansicht', $E890, ItemClick);
    M := NewMenu(['Liste', 'Kacheln']);
    It.DropdownMenu := M;
    T.OnItemClick := nil;
    R := T.ItemRect(1);
    // Klick auf den Text (nicht den Pfeil) klappt auf, OnClick laeuft nicht
    ClickAt(T, R.Left + 4, (R.Top + R.Bottom) div 2);
    CheckEquals(1, T.PopCount, 'aufgeklappt');
    CheckTrue(T.LastMenu = M);
    CheckEquals(0, FLog.Count, 'kein OnClick bei tdsMenu: ' + FLog.CommaText);
    CheckEquals(1, T.PartDuringPopup, 'Eintrag gedrueckt waehrend des Menues');
    CheckEquals(-1, T.DropdownPart, 'danach nicht mehr');
    CheckTrue(M.PopupComponent = T, 'PopupComponent');
    // Menue unter dem Eintrag (Bildschirm)
    P := T.ClientToScreen(Point(R.Left, R.Bottom));
    CheckEquals(P.X, T.LastRect.Left);
    CheckEquals(P.Y, T.LastRect.Bottom);
    // Normaler Eintrag unveraendert
    ClickAt(T, T.ItemRect(0).Left + 4, (R.Top + R.Bottom) div 2);
    CheckEquals('click:Neu', FLog.CommaText);
    CheckEquals(1, T.PopCount);
    // DropdownItem aus Code
    CheckTrue(T.DropdownItem(It));
    CheckEquals(2, T.PopCount);
    CheckFalse(T.DropdownItem(T.Items[0]), 'Eintrag ohne Menue');
    CheckFalse(T.DropdownItem(nil));
  finally
    FForm.Hide;
  end;
end;

procedure TToolBarDropdownTests.SplitStyleArrowAndBody;
var
  T: TDropToolBar;
  It: TPPGToolItem;
  AR, R: TRect;
begin
  FForm.Show;
  try
    T := NewBar;
    It := T.Items.AddButton('Drucken', $E749, ItemClick);
    It.DropdownMenu := NewMenu(['Vorschau']);
    It.DropdownStyle := tdsSplit;
    R := T.ItemRect(0);
    AR := T.ItemArrowRect(0);
    ClickAt(T, R.Left + 4, (R.Top + R.Bottom) div 2);
    CheckEquals('click:Drucken', FLog.CommaText, 'Koerper loest OnClick aus');
    CheckEquals(0, T.PopCount, 'Koerper klappt nicht auf');
    FLog.Clear;
    ClickAt(T, (AR.Left + AR.Right) div 2, (AR.Top + AR.Bottom) div 2);
    CheckEquals(1, T.PopCount, 'Pfeil klappt auf');
    CheckEquals(0, FLog.Count, 'Pfeil ohne OnClick');
  finally
    FForm.Hide;
  end;
end;

procedure TToolBarDropdownTests.OnDropdownSwapsOrCancels;
var
  T: TDropToolBar;
  It: TPPGToolItem;
  M: TPPGPopupMenu;
begin
  T := NewBar;
  It := T.Items.AddButton('Filter', 0);
  M := NewMenu(['A']);
  It.DropdownMenu := M;
  FSwap := NewMenu(['B']);
  T.OnDropdown := Dropdown;
  FSwapMode := 1;
  CheckTrue(T.DropdownItem(It));
  CheckTrue(T.LastMenu = FSwap, 'getauschtes Menue');
  CheckEquals('dropdown:Filter', FLog.CommaText);
  FSwapMode := 2;
  CheckFalse(T.DropdownItem(It), 'nil: nichts');
  CheckEquals(1, T.PopCount);
  CheckEquals(-1, T.DropdownPart);
  FSwapMode := 0;
  CheckTrue(T.DropdownItem(It));
  CheckTrue(T.LastMenu = M, 'unveraendert');
end;

procedure TToolBarDropdownTests.DisabledSeparatorAndInvalid;
var
  T: TDropToolBar;
  It, Sep: TPPGToolItem;
begin
  T := NewBar;
  It := T.Items.AddButton('X', 0);
  It.DropdownMenu := NewMenu(['A']);
  It.Enabled := False;
  CheckFalse(T.DropdownItem(It), 'deaktiviert');
  It.Enabled := True;
  T.Enabled := False;
  CheckFalse(T.DropdownItem(It), 'Leiste deaktiviert');
  T.Enabled := True;
  It.Visible := False;
  CheckFalse(T.DropdownItem(It), 'unsichtbar');
  It.Visible := True;
  // Trenner ignoriert ein Menue (kein Pfeil, keine Breite)
  Sep := T.Items.AddSeparator;
  Sep.DropdownMenu := It.DropdownMenu;
  CheckFalse(Sep.HasDropdown);
  CheckTrue(IsRectEmpty(T.ItemArrowRect(Sep.Index)));
  CheckFalse(T.DropdownItem(Sep));
  // Ausserhalb der Liste
  CheckTrue(IsRectEmpty(T.ItemArrowRect(-1)));
  CheckTrue(IsRectEmpty(T.ItemArrowRect(99)));
  // Eintrag einer anderen Leiste
  CheckFalse(NewBar.DropdownItem(It), 'fremder Eintrag');
  CheckEquals(0, T.PopCount);
end;

procedure TToolBarDropdownTests.FreeingMenuClearsReference;
var
  T: TDropToolBar;
  It: TPPGToolItem;
  M: TPPGPopupMenu;
  W: Integer;
begin
  T := NewBar;
  It := T.Items.AddButton('Ansicht', $E890);
  W := T.ItemRect(0).Right - T.ItemRect(0).Left;
  M := NewMenu(['A']);
  It.DropdownMenu := M;
  T.Items.AddButton('Zweit', 0).DropdownMenu := M;
  M.Free;
  CheckNull(It.DropdownMenu, 'Verweis geloescht');
  CheckNull(T.Items[1].DropdownMenu, 'auch im zweiten Eintrag');
  CheckEquals(W, T.ItemRect(0).Right - T.ItemRect(0).Left, 'Breite wieder ohne Pfeil');
  CheckFalse(T.DropdownItem(It));
end;

procedure TToolBarDropdownTests.StreamingRoundTrip;
var
  R1, R2: TDropRoot;
  T: TPPGToolBar;
  M: TPPGPopupMenu;
  S: TMemoryStream;
  Txt: TStringStream;
  Dfm: string;
begin
  RegisterClasses([TPPGToolBar, TPPGPopupMenu, TMenuItem]);
  R1 := TDropRoot.CreateNew(nil);
  R2 := nil;
  S := TMemoryStream.Create;
  Txt := TStringStream.Create('');
  try
    M := TPPGPopupMenu.Create(R1);
    M.Name := 'MenuAnsicht';
    T := TPPGToolBar.Create(R1);
    T.Name := 'Bar';
    T.Parent := R1;
    T.Items.AddButton('Ansicht', 0).DropdownMenu := M;
    T.Items.AddButton('Drucken', 0).DropdownStyle := tdsSplit;
    T.Items.AddButton('Neu', 0);
    S.WriteComponent(R1);
    S.Position := 0;
    ObjectBinaryToText(S, Txt);
    Dfm := Txt.DataString;
    CheckTrue(Pos('DropdownMenu = MenuAnsicht', Dfm) > 0, 'Verweis gespeichert');
    CheckTrue(Pos('DropdownStyle = tdsSplit', Dfm) > 0, 'Split gespeichert');
    CheckEquals(1, Length(Dfm) - Length(StringReplace(Dfm, 'DropdownStyle', 'DropdownStyl', [rfReplaceAll])),
      'Vorgabe tdsMenu nicht gespeichert');
    CheckEquals(1, Length(Dfm) - Length(StringReplace(Dfm, 'DropdownMenu', 'DropdownMen', [rfReplaceAll])),
      'leerer Verweis nicht gespeichert');
    S.Position := 0;
    R2 := TDropRoot.CreateNew(nil);
    S.ReadComponent(R2);
    T := R2.FindComponent('Bar') as TPPGToolBar;
    CheckNotNull(T);
    CheckTrue(T.Items[0].DropdownMenu = R2.FindComponent('MenuAnsicht'), 'Verweis gelesen');
    CheckTrue(T.Items[0].DropdownStyle = tdsMenu);
    CheckTrue(T.Items[1].DropdownStyle = tdsSplit);
    CheckNull(T.Items[1].DropdownMenu);
    // Verweis nach dem Laden ueberwacht: Freigeben loescht ihn
    R2.FindComponent('MenuAnsicht').Free;
    CheckNull(T.Items[0].DropdownMenu, 'FreeNotification nach dem Laden');
    // Assign kopiert beide Properties
    T.Items[2].Assign(T.Items[1]);
    CheckTrue(T.Items[2].DropdownStyle = tdsSplit, 'Assign');
  finally
    Txt.Free;
    S.Free;
    R2.Free;
    R1.Free;
  end;
end;

procedure TToolBarDropdownTests.OverflowBuildsSubmenu;
var
  T: TDropToolBar;
  It, Sp: TPPGToolItem;
  M: TPPGPopupMenu;
  O, Sub: TMenuItem;
  I: Integer;
begin
  T := NewBar;
  for I := 1 to 6 do
    T.Items.AddButton('Befehl Nummer ' + IntToStr(I), $E710, ItemClick);
  It := T.Items.AddButton('Ansicht', 0, ItemClick);
  M := NewMenu(['Liste', 'Kacheln']);
  It.DropdownMenu := M;
  Sp := T.Items.AddButton('Drucken', 0, ItemClick);
  Sp.DropdownMenu := NewMenu(['Vorschau']);
  Sp.DropdownStyle := tdsSplit;
  T.Width := 250;
  CheckTrue(T.HasOverflow);
  CheckTrue(T.IsInOverflow(It.Index), 'Ansicht im Ueberlauf');
  CheckFalse(T.DropdownItem(It), 'im Ueberlauf nicht direkt');
  T.OnDropdown := Dropdown;
  T.ShowOverflowMenu;
  CheckEquals(1, T.PopCount);
  CheckTrue(T.LastMenu = T.OverflowMenu);
  O := nil;
  Sub := nil;
  for I := 0 to T.OverflowMenu.Items.Count - 1 do
  begin
    if T.OverflowMenu.Items[I].Caption = 'Ansicht' then
      O := T.OverflowMenu.Items[I];
    if T.OverflowMenu.Items[I].Caption = 'Drucken' then
      Sub := T.OverflowMenu.Items[I];
  end;
  CheckNotNull(O, 'Eintrag im Ueberlauf');
  CheckEquals(2, O.Count, 'Untermenue mit den Menuepunkten');
  CheckEquals('Kacheln', O.Items[1].Caption);
  CheckTrue(Pos('dropdown:Ansicht', FLog.CommaText) > 0, 'OnDropdown auch im Ueberlauf');
  FLog.Clear;
  O.Items[1].Click;
  CheckEquals('menu:Kacheln', FLog.CommaText, 'Kopie loest das Original aus');
  // Geteilter Eintrag: eigener Befehl, Trenner, Menuepunkte
  CheckNotNull(Sub);
  CheckEquals(3, Sub.Count);
  CheckEquals('Drucken', Sub.Items[0].Caption);
  CheckTrue(Sub.Items[1].IsLine);
  FLog.Clear;
  Sub.Items[0].Click;
  CheckEquals('click:Drucken', FLog.CommaText, 'eigener Befehl');
  FLog.Clear;
  Sub.Items[2].Click;
  CheckEquals('menu:Vorschau', FLog.CommaText);
  // Menue freigeben leert die Kopien (keine Verweise ins Leere)
  M.Free;
  CheckEquals(0, T.OverflowMenu.Items.Count, 'Kopien verworfen');
  T.ShowOverflowMenu;
  for I := 0 to T.OverflowMenu.Items.Count - 1 do
    if T.OverflowMenu.Items[I].Caption = 'Ansicht' then
      CheckEquals(0, T.OverflowMenu.Items[I].Count, 'ohne Menue normaler Eintrag');
end;

procedure TToolBarDropdownTests.KeyboardOpensMenu;
var
  T: TDropToolBar;
  It: TPPGToolItem;
begin
  T := NewBar;
  T.Items.AddButton('Neu', 0, ItemClick);
  It := T.Items.AddButton('Ansicht', 0, ItemClick);
  It.DropdownMenu := NewMenu(['A']);
  Key(T, VK_HOME);
  Key(T, VK_DOWN);
  CheckEquals(0, T.PopCount, 'Pfeil runter ohne Menue: nichts');
  Key(T, VK_RIGHT);
  CheckEquals(1, T.FocusPart);
  Key(T, VK_DOWN);
  CheckEquals(1, T.PopCount, 'Pfeil runter klappt auf');
  Key(T, VK_DOWN, [ssAlt]);
  CheckEquals(2, T.PopCount, 'Alt+Pfeil runter');
  Key(T, VK_RETURN);
  CheckEquals(3, T.PopCount, 'Enter bei tdsMenu klappt auf');
  CheckEquals(0, FLog.Count);
  It.DropdownStyle := tdsSplit;
  Key(T, VK_SPACE);
  CheckEquals('click:Ansicht', FLog.CommaText, 'Leertaste bei tdsSplit loest aus');
  CheckEquals(3, T.PopCount);
  Key(T, VK_DOWN);
  CheckEquals(4, T.PopCount, 'Split: Pfeil runter klappt auf');
end;

procedure TToolBarDropdownTests.ActionStillWorks;
var
  T: TDropToolBar;
  AL: TActionList;
  A: TAction;
  It: TPPGToolItem;
begin
  AL := TActionList.Create(FForm);
  A := TAction.Create(FForm);
  A.ActionList := AL;
  A.Caption := 'Speichern';
  A.OnExecute := ItemClick;
  T := NewBar;
  It := T.Items.Add;
  It.Action := A;
  It.DropdownMenu := NewMenu(['Unter']);
  It.DropdownStyle := tdsSplit;
  FForm.Show;
  try
    ClickAt(T, T.ItemRect(0).Left + 4, (T.ItemRect(0).Top + T.ItemRect(0).Bottom) div 2);
  finally
    FForm.Hide;
  end;
  CheckEquals(1, FLog.Count, 'Action ausgefuehrt (Split-Koerper)');
  FLog.Clear;
  It.DropdownStyle := tdsMenu;
  T.Perform(WM_NULL, 0, 0);
  CheckTrue(T.DropdownItem(It));
  CheckEquals(0, FLog.Count, 'tdsMenu fuehrt die Action nicht aus');
  T.ClickItem(It);
  CheckEquals(1, FLog.Count, 'ClickItem aus Code fuehrt sie weiter aus');
end;

procedure TToolBarDropdownTests.RightToLeftArrowLeft;
var
  T: TDropToolBar;
  It: TPPGToolItem;
  R, AR: TRect;
begin
  FForm.Show;
  try
    T := NewBar;
    T.BiDiMode := bdRightToLeft;
    It := T.Items.AddButton('Ansicht', 0, ItemClick);
    It.DropdownMenu := NewMenu(['A']);
    It.DropdownStyle := tdsSplit;
    R := T.ItemRect(0);
    AR := T.ItemArrowRect(0);
    CheckEquals(R.Left, AR.Left, 'RTL: Pfeil links');
    CheckEquals(18, AR.Right - AR.Left);
    ClickAt(T, (AR.Left + AR.Right) div 2, (AR.Top + AR.Bottom) div 2);
    CheckEquals(1, T.PopCount, 'Pfeilteil links klappt auf');
    ClickAt(T, R.Right - 4, (R.Top + R.Bottom) div 2);
    CheckEquals('click:Ansicht', FLog.CommaText);
  finally
    FForm.Hide;
  end;
end;

procedure TToolBarDropdownTests.AccessibilityRoles;
var
  T: TDropToolBar;
  A: IPPGAccessibleChildren;
begin
  T := NewBar;
  T.Items.AddButton('Neu', 0);
  T.Items.AddButton('Ansicht', 0).DropdownMenu := NewMenu(['A']);
  T.Items.AddButton('Drucken', 0).DropdownMenu := NewMenu(['B']);
  T.Items[2].DropdownStyle := tdsSplit;
  CheckTrue(Supports(T, IPPGAccessibleChildren, A));
  CheckEquals(ROLE_SYSTEM_PUSHBUTTON, A.AccChildRole(1));
  CheckEquals(ROLE_SYSTEM_BUTTONMENU, A.AccChildRole(2));
  CheckEquals(ROLE_SYSTEM_SPLITBUTTON, A.AccChildRole(3));
  CheckEquals('Ansicht', A.AccChildName(2), 'Name unveraendert');
  CheckTrue(A.AccChildState(2) and STATE_SYSTEM_HASPOPUP <> 0);
  CheckTrue(A.AccChildState(1) and STATE_SYSTEM_HASPOPUP = 0);
  CheckEquals(PPGStr(@SPPGAccOpen), A.AccChildDefaultAction(2));
  CheckEquals(PPGStr(@SPPGAccPress), A.AccChildDefaultAction(3));
  // Standardaktion (gepostet) klappt bei tdsMenu auf
  A.AccChildDoDefault(2);
  Application.ProcessMessages;
  CheckEquals(1, T.PopCount, 'Standardaktion klappt auf');
  A := nil;
end;

procedure TToolBarDropdownTests.PaintsWithArrow;
var
  T: TDropToolBar;
  B: TBitmap;
  Clean: TBitmap;
  It: TPPGToolItem;
  X, Y, Diff: Integer;
  AR: TRect;
begin
  FForm.Show;
  try
    T := NewBar;
    It := T.Items.AddButton('Ansicht', 0);
    Clean := RenderToBitmap(T);
    try
      It.DropdownMenu := NewMenu(['A']);
      It.DropdownStyle := tdsSplit;
      B := RenderToBitmap(T);
      try
        AR := T.ItemArrowRect(0);
        Diff := 0;
        for Y := AR.Top to AR.Bottom - 1 do
          for X := AR.Left to AR.Right - 1 do
            if B.Canvas.Pixels[X, Y] <> Clean.Canvas.Pixels[X, Y] then
              Inc(Diff);
        CheckTrue(Diff > 4, 'Pfeil gezeichnet (' + IntToStr(Diff) + ')');
      finally
        B.Free;
      end;
    finally
      Clean.Free;
    end;
  finally
    FForm.Hide;
  end;
end;

initialization
  RegisterTest('ToolBarDropdown', TToolBarDropdownTests.Suite);

end.
