unit PPG.Tests.Audit7B;

{ Audit-Paket 7B (Docs\Audit-Paket7-Plan.md): Regressionstests fuer 7c #1-#5
  (Tastatur), 7a #7 (Tippsuche) und 7f #1-#4, #6 (Tooltips, Hot-Zustand,
  Ziehschwelle, RTL). Audit 09.10.2026, Paket 7. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Rtti, System.TypInfo, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids, Vcl.Clipbrd,
  Data.DB, Datasnap.DBClient,
  PPG.Types, PPG.Items, PPG.Controls.ItemList, PPG.ListBox, PPG.CheckListBox, PPG.TreeView,
  PPG.Grid, PPG.Grid.Columns, PPG.RadioButton, PPG.TabControl, PPG.PageControl,
  PPG.TileView, PPG.TagEdit, PPG.ColumnComboBox, PPG.DB.Grid, PPG.Tests.Controls;

type
  TAudit7BTests = class(TControlTestCase)
  private
    FKeyCount: Integer;
    FSuppress: Boolean;
    FClosing: Integer;
    FSetCount: Integer;
    procedure SetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
    procedure KeyEv(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TabClosing(Sender: TObject; Index: Integer; var CanClose: Boolean);
    procedure PageClosing(Sender: TObject; Page: TPPGTabSheet; var CanClose: Boolean);
    function NewList(const S: string): TPPGListBox;
    function NewGrid: TPPGGrid;
    function NewRadios(out R1, R2, R3: TPPGRadioButton): Boolean;
    function HintAt(C: TControl; const P: TPoint; const Preset: string = ''): string;
    procedure CheckKeyOnce(C: TWinControl; Key: Word; const What: string);
  protected
    procedure SetUp; override;
  published
    { 7c #1 }
    procedure ListBoxKeyDownFiresOnce;
    procedure CheckListBoxKeyDownFiresOnce;
    procedure TreeViewKeyDownFiresOnce;
    procedure GridKeyDownFiresOnce;
    procedure RadioButtonKeyDownFiresOnce;
    { 7c #2 }
    procedure RadioTabStopOnlyChecked;
    { 7c #3 }
    procedure CtrlF4ClosesTab;
    procedure CtrlF4ClosesPage;
    { 7c #4 }
    procedure ListSkipsHeadersBothWays;
    procedure ListEndWithoutFocus;
    { 7c #5 }
    procedure GridDeleteClearsEditableCells;
    procedure GridCutAndClipboardKeys;
    procedure DBGridReadOnlyDeleteKeepsData;
    { 7a #7 }
    procedure TileViewTypeAheadCycles;
    procedure ColumnComboTypeAheadCycles;
    { 7f #1 }
    procedure ListToolTipForTruncatedText;
    procedure GridToolTipForTruncatedCell;
    { 7f #2 }
    procedure TileHintOnlyWhenTruncated;
    { 7f #3 }
    procedure TagEditMouseLeaveResetsHot;
    { 7f #6 }
    procedure RadioArrowsMirroredInRtl;
    { neue API }
    procedure TypeAheadRecord;
    procedure DragExceededHalfRect;
    procedure GridClearAndCutMethods;
    procedure ToolTipsPublishedAndSwitchable;
  end;

implementation

type
  TItemListAccess7 = class(TPPGCustomItemList);
  TGridAccess7 = class(TPPGCustomGrid);
  TDBGridAccess7 = class(TPPGCustomDBGrid);
  TRadioAccess7 = class(TPPGCustomRadioButton);
  TTabsAccess7 = class(TPPGCustomTabs);
  TWinAccess7 = class(TWinControl);

function PrivInt(Obj: TObject; const Field: string): Integer;
var
  Ctx: TRttiContext;
  F: TRttiField;
begin
  F := Ctx.GetType(Obj.ClassType).GetField(Field);
  if F = nil then
    raise Exception.Create('Feld fehlt: ' + Field);
  Result := F.GetValue(Obj).AsInteger;
end;

{ Hilfen }

procedure TAudit7BTests.SetUp;
begin
  inherited SetUp;
  // /leaks laesst die Tests zweimal laufen (dieselben Objekte)
  FKeyCount := 0;
  FSuppress := False;
  FClosing := 0;
  FSetCount := 0;
end;

procedure TAudit7BTests.KeyEv(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  Inc(FKeyCount);
  if FSuppress then
    Key := 0;
end;

procedure TAudit7BTests.SetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
begin
  Inc(FSetCount);
end;

procedure TAudit7BTests.TabClosing(Sender: TObject; Index: Integer; var CanClose: Boolean);
begin
  Inc(FClosing);
end;

procedure TAudit7BTests.PageClosing(Sender: TObject; Page: TPPGTabSheet; var CanClose: Boolean);
begin
  Inc(FClosing);
end;

function TAudit7BTests.NewList(const S: string): TPPGListBox;
begin
  Result := TPPGListBox.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 200, 200);
  Result.Items.CommaText := S;
  Result.HandleNeeded;
end;

function TAudit7BTests.NewGrid: TPPGGrid;
var
  C, R: Integer;
begin
  Result := TPPGGrid.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 400, 300);
  Result.ColCount := 4;
  Result.RowCount := 5;
  Result.Options := Result.Options + [goEditing];
  for C := 1 to 3 do
    for R := 1 to 4 do
      Result.Cells[C, R] := Format('%d/%d', [C, R]);
  Result.HandleNeeded;
end;

function TAudit7BTests.NewRadios(out R1, R2, R3: TPPGRadioButton): Boolean;

  function Make(Y: Integer): TPPGRadioButton;
  begin
    Result := TPPGRadioButton.Create(FForm);
    Result.Parent := FForm;
    Result.SetBounds(10, Y, 150, 24);
    Result.Caption := 'R' + IntToStr(Y);
  end;

begin
  R1 := Make(10);
  R2 := Make(40);
  R3 := Make(70);
  FForm.Show;
  Result := True;
end;

function TAudit7BTests.HintAt(C: TControl; const P: TPoint; const Preset: string): string;
var
  HI: Vcl.Controls.THintInfo;
  M: TCMHintShow;
begin
  FillChar(HI, SizeOf(HI), 0);
  HI.CursorPos := P;
  HI.HintControl := C;
  HI.HintStr := Preset;
  M.Msg := CM_HINTSHOW;
  M.HintInfo := @HI;
  M.Result := 0;
  C.Dispatch(M);
  Result := HI.HintStr;
end;

procedure TAudit7BTests.CheckKeyOnce(C: TWinControl; Key: Word; const What: string);
var
  K: Word;
begin
  FKeyCount := 0;
  K := Key;
  TWinAccess7(C).KeyDown(K, []);
  CheckEquals(1, FKeyCount, C.ClassName + ': OnKeyDown genau einmal bei ' + What);
end;

{ 7c #1: OnKeyDown kommt zuerst und genau einmal; Key := 0 unterdrueckt }

procedure TAudit7BTests.ListBoxKeyDownFiresOnce;
var
  L: TPPGListBox;
  K: Word;
begin
  L := NewList('Anton,Berta,Caesar,Dora');
  L.MultiSelect := True;
  L.OnKeyDown := KeyEv;
  CheckKeyOnce(L, VK_DOWN, 'Pfeil');
  CheckKeyOnce(L, VK_SPACE, 'Leertaste');
  CheckKeyOnce(L, Ord('C'), 'Buchstabe');
  CheckKeyOnce(L, VK_END, 'Ende');
  L.ItemIndex := 0;
  FSuppress := True;
  K := VK_DOWN;
  TItemListAccess7(L).KeyDown(K, []);
  CheckEquals(0, L.ItemIndex, 'Key := 0 unterdrueckt die Navigation');
  K := Ord('A');
  TItemListAccess7(L).KeyDown(K, [ssCtrl]);
  CheckEquals(1, L.SelCount, 'Key := 0 unterdrueckt Strg+A');
end;

procedure TAudit7BTests.CheckListBoxKeyDownFiresOnce;
var
  L: TPPGCheckListBox;
  K: Word;
begin
  L := TPPGCheckListBox.Create(FForm);
  L.Parent := FForm;
  L.SetBounds(0, 0, 200, 200);
  L.Items.CommaText := 'Anton,Berta,Caesar';
  L.HandleNeeded;
  L.OnKeyDown := KeyEv;
  L.ItemIndex := 0;
  CheckKeyOnce(L, VK_DOWN, 'Pfeil');
  CheckKeyOnce(L, VK_SPACE, 'Leertaste');
  CheckKeyOnce(L, Ord('X'), 'Buchstabe');
  L.ItemIndex := 0;
  L.Checked[0] := False;
  FSuppress := True;
  K := VK_SPACE;
  TItemListAccess7(L).KeyDown(K, []);
  CheckFalse(L.Checked[0], 'Key := 0: Leertaste hakt nicht an');
end;

procedure TAudit7BTests.TreeViewKeyDownFiresOnce;
var
  T: TPPGTreeView;
  N: TPPGTreeNode;
  K: Word;
begin
  T := TPPGTreeView.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(0, 0, 200, 200);
  N := T.Items.Add(nil, 'Wurzel');
  T.Items.AddChild(N, 'Kind');
  T.Items.Add(nil, 'Zweite');
  T.HandleNeeded;
  T.Selected := N;
  T.OnKeyDown := KeyEv;
  CheckKeyOnce(T, VK_DOWN, 'Pfeil');
  T.Selected := N;
  CheckKeyOnce(T, VK_ADD, 'Plus');
  CheckKeyOnce(T, VK_SUBTRACT, 'Minus');
  CheckKeyOnce(T, VK_SPACE, 'Leertaste');
  CheckKeyOnce(T, Ord('Q'), 'Buchstabe');
  T.Selected := N;
  N.Expanded := False;
  FSuppress := True;
  K := VK_ADD;
  TItemListAccess7(T).KeyDown(K, []);
  CheckFalse(N.Expanded, 'Key := 0: Plus klappt nicht auf');
  K := VK_DOWN;
  TItemListAccess7(T).KeyDown(K, []);
  CheckTrue(T.Selected = N, 'Key := 0: Pfeil bewegt nicht');
end;

procedure TAudit7BTests.GridKeyDownFiresOnce;
var
  G: TPPGGrid;
  K: Word;
begin
  G := NewGrid;
  G.OnKeyDown := KeyEv;
  G.Col := 1;
  G.Row := 1;
  CheckKeyOnce(G, VK_DOWN, 'Pfeil');
  CheckKeyOnce(G, VK_SPACE, 'Leertaste');
  CheckKeyOnce(G, Ord('C'), 'C ohne Strg');
  CheckKeyOnce(G, Ord('V'), 'V ohne Strg');
  CheckKeyOnce(G, Ord('A'), 'A ohne Strg');
  CheckKeyOnce(G, VK_TAB, 'Tab');
  G.Col := 1;
  G.Row := 1;
  FSuppress := True;
  K := VK_DOWN;
  TGridAccess7(G).KeyDown(K, []);
  CheckEquals(1, G.Row, 'Key := 0 unterdrueckt die Navigation');
end;

procedure TAudit7BTests.RadioButtonKeyDownFiresOnce;
var
  R1, R2, R3: TPPGRadioButton;
  K: Word;
begin
  NewRadios(R1, R2, R3);
  R1.Checked := True;
  R1.OnKeyDown := KeyEv;
  CheckKeyOnce(R1, VK_DOWN, 'Pfeil');
  R1.Checked := True;
  CheckKeyOnce(R1, VK_SPACE, 'Leertaste');
  R1.Checked := True;
  FSuppress := True;
  K := VK_DOWN;
  TRadioAccess7(R1).KeyDown(K, []);
  CheckTrue(R1.Checked and not R2.Checked, 'Key := 0: Pfeil wechselt nicht');
end;

{ 7c #2 }

procedure TAudit7BTests.RadioTabStopOnlyChecked;
var
  R1, R2, R3: TPPGRadioButton;
begin
  NewRadios(R1, R2, R3);
  CheckTrue(R1.TabStop, 'ohne Markierung: erste ist Tabstopp');
  CheckFalse(R2.TabStop, 'ohne Markierung: zweite nicht');
  CheckFalse(R3.TabStop, 'ohne Markierung: dritte nicht');
  R2.Checked := True;
  CheckFalse(R1.TabStop, 'markiert ist R2');
  CheckTrue(R2.TabStop, 'nur die markierte');
  CheckFalse(R3.TabStop);
  R3.Checked := True;
  CheckFalse(R2.TabStop, 'Markierung gewechselt');
  CheckTrue(R3.TabStop);
  R3.Checked := False;
  CheckTrue(R1.TabStop, 'wieder ohne Markierung: erste');
  CheckFalse(R3.TabStop);
end;

{ 7c #3 }

procedure TAudit7BTests.CtrlF4ClosesTab;
var
  T: TPPGTabControl;
  K: Word;
begin
  T := TPPGTabControl.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(0, 0, 300, 200);
  T.Tabs.CommaText := 'Eins,Zwei,Drei';
  T.TabIndex := 1;
  T.OnClosing := TabClosing;
  K := VK_F4;
  TTabsAccess7(T).KeyDown(K, [ssCtrl]);
  CheckEquals(3, T.Tabs.Count, 'ohne ShowCloseButton kein Schliessen');
  CheckEquals(0, FClosing);
  T.ShowCloseButton := True;
  K := VK_F4;
  TTabsAccess7(T).KeyDown(K, [ssCtrl]);
  CheckEquals(1, FClosing, 'OnClosing kommt');
  CheckEquals(2, T.Tabs.Count, 'Strg+F4 schliesst den aktiven Reiter');
  CheckEquals(0, K, 'Taste verbraucht');
  CheckEquals('Eins,Drei', T.Tabs.CommaText);
end;

procedure TAudit7BTests.CtrlF4ClosesPage;
var
  PC: TPPGPageControl;
  S1, S2: TPPGTabSheet;
  K: Word;
begin
  PC := TPPGPageControl.Create(FForm);
  PC.Parent := FForm;
  PC.SetBounds(0, 0, 300, 200);
  S1 := TPPGTabSheet.Create(FForm);
  S1.PageControl := PC;
  S2 := TPPGTabSheet.Create(FForm);
  S2.PageControl := PC;
  PC.ActivePage := S2;
  PC.ShowCloseButton := True;
  PC.OnClosing := PageClosing;
  K := VK_F4;
  TTabsAccess7(PC).KeyDown(K, [ssCtrl]);
  CheckEquals(1, FClosing, 'OnClosing kommt');
  CheckFalse(S2.TabVisible, 'aktive Seite geschlossen');
  CheckTrue(PC.ActivePage = S1);
end;

{ 7c #4 }

procedure TAudit7BTests.ListSkipsHeadersBothWays;
var
  L: TPPGCheckListBox;
  K: Word;
begin
  L := TPPGCheckListBox.Create(FForm);
  L.Parent := FForm;
  L.SetBounds(0, 0, 200, 400);
  L.Items.CommaText := 'Anton,Berta,Caesar,Ende';
  L.Header[3] := True;
  L.HandleNeeded;
  L.ItemIndex := 0;
  K := VK_NEXT;
  TItemListAccess7(L).KeyDown(K, []);
  CheckEquals(2, L.ItemIndex, 'Bild runter am Rand: letzter waehlbarer Eintrag');
  L.Header[3] := False;
  L.Header[0] := True;
  L.ItemIndex := 3;
  K := VK_PRIOR;
  TItemListAccess7(L).KeyDown(K, []);
  CheckEquals(1, L.ItemIndex, 'Bild hoch am Rand: erster waehlbarer Eintrag');
end;

procedure TAudit7BTests.ListEndWithoutFocus;
var
  L: TPPGListBox;
  K: Word;
begin
  L := NewList('Anton,Berta,Caesar,Dora');
  CheckEquals(-1, L.ItemIndex);
  K := VK_END;
  TItemListAccess7(L).KeyDown(K, []);
  CheckEquals(3, L.ItemIndex, 'Ende ohne Fokus springt ans Ende');
end;

{ 7c #5 }

procedure TAudit7BTests.GridDeleteClearsEditableCells;
var
  G: TPPGGrid;
  C, R: Integer;
  K: Word;
  Sel: TGridRect;
begin
  G := NewGrid;
  // Spalten bestimmen die Spaltenzahl: erst alle vier, dann die Texte
  for C := 0 to 3 do
    G.Columns.Add;
  G.Columns[2].ReadOnly := True;
  for C := 1 to 3 do
    for R := 1 to 4 do
      G.Cells[C, R] := Format('%d/%d', [C, R]);
  Sel.Left := 1;
  Sel.Top := 1;
  Sel.Right := 2;
  Sel.Bottom := 2;
  G.Selection := Sel;
  K := VK_DELETE;
  TGridAccess7(G).KeyDown(K, []);
  CheckEquals(0, K, 'Entf verbraucht');
  CheckEquals('', G.Cells[1, 1], 'Entf leert die Auswahl');
  CheckEquals('', G.Cells[1, 2]);
  CheckEquals('2/1', G.Cells[2, 1], 'schreibgeschuetzte Spalte bleibt');
  CheckEquals('1/3', G.Cells[1, 3], 'ausserhalb der Auswahl bleibt');
  G.Options := G.Options - [goEditing];
  G.Cells[1, 1] := 'x';
  K := VK_DELETE;
  TGridAccess7(G).KeyDown(K, []);
  CheckEquals('x', G.Cells[1, 1], 'ohne goEditing nichts loeschen');
end;

/// Zwischenablage kurz belegt (anderes Programm, Zwischenablage-Verlauf):
/// einige Male versuchen, wie in PPG.Tests.Phase12a.
function GetClip7: string;
var
  I: Integer;
begin
  for I := 1 to 20 do
    try
      Exit(Clipboard.AsText);
    except
      on EClipboardException do
        Sleep(50);
    end;
  Result := Clipboard.AsText;
end;

procedure SetClip7(const S: string);
var
  I: Integer;
begin
  for I := 1 to 20 do
    try
      Clipboard.AsText := S;
      Exit;
    except
      on EClipboardException do
        Sleep(50);
    end;
  Clipboard.AsText := S;
end;

/// Taste ans Grid; scheitert der Zugriff auf die Zwischenablage, hat das Grid
/// nichts geaendert (erst kopieren, dann leeren) und es wird wiederholt.
procedure GridKey7(G: TPPGCustomGrid; Key: Word; Shift: TShiftState);
var
  I: Integer;
  K: Word;
begin
  for I := 1 to 20 do
    try
      K := Key;
      TGridAccess7(G).KeyDown(K, Shift);
      Exit;
    except
      on EClipboardException do
        Sleep(50);
    end;
  K := Key;
  TGridAccess7(G).KeyDown(K, Shift);
end;

procedure GridCut7(G: TPPGCustomGrid);
var
  I: Integer;
begin
  for I := 1 to 20 do
    try
      G.CutToClipboard;
      Exit;
    except
      on EClipboardException do
        Sleep(50);
    end;
  G.CutToClipboard;
end;

procedure TAudit7BTests.GridCutAndClipboardKeys;
var
  G: TPPGGrid;
  Sel: TGridRect;
begin
  G := NewGrid;
  Sel.Left := 1;
  Sel.Top := 1;
  Sel.Right := 1;
  Sel.Bottom := 1;
  G.Selection := Sel;
  // Strg+Einfg kopiert
  SetClip7('');
  GridKey7(G, VK_INSERT, [ssCtrl]);
  CheckEquals('1/1'#13#10, GetClip7, 'Strg+Einfg kopiert');
  // Strg+X schneidet aus
  GridKey7(G, Ord('X'), [ssCtrl]);
  CheckEquals('1/1'#13#10, GetClip7, 'Strg+X kopiert');
  CheckEquals('', G.Cells[1, 1], 'Strg+X leert');
  // Umschalt+Einfg fuegt ein
  GridKey7(G, VK_INSERT, [ssShift]);
  CheckEquals('1/1', G.Cells[1, 1], 'Umschalt+Einfg fuegt ein');
  // Umschalt+Entf schneidet aus
  G.Cells[1, 1] := 'neu';
  GridKey7(G, VK_DELETE, [ssShift]);
  CheckEquals('neu'#13#10, GetClip7, 'Umschalt+Entf kopiert');
  CheckEquals('', G.Cells[1, 1], 'Umschalt+Entf leert');
end;

procedure TAudit7BTests.DBGridReadOnlyDeleteKeepsData;
var
  DS: TClientDataSet;
  Src: TDataSource;
  G: TPPGDBGrid;
  K: Word;
begin
  DS := TClientDataSet.Create(FForm);
  DS.FieldDefs.Add('Name', ftString, 20);
  DS.CreateDataSet;
  DS.AppendRecord(['Anton']);
  DS.AppendRecord(['Berta']);
  DS.First;
  Src := TDataSource.Create(FForm);
  Src.DataSet := DS;
  G := TPPGDBGrid.Create(FForm);
  G.Parent := FForm;
  G.SetBounds(0, 0, 300, 200);
  G.DataSource := Src;
  G.ReadOnly := True;
  G.HandleNeeded;
  G.Col := TDBGridAccess7(G).FixedCols;
  K := VK_DELETE;
  TDBGridAccess7(G).KeyDown(K, []);
  CheckEquals('Anton', DS.FieldByName('Name').AsString, 'ReadOnly: Entf loescht nichts');
  CheckTrue(DS.State = dsBrowse, 'kein Bearbeiten');
  G.ReadOnly := False;
  K := VK_DELETE;
  TDBGridAccess7(G).KeyDown(K, []);
  CheckEquals('', DS.FieldByName('Name').AsString, 'editierbar: Entf leert das Feld');
  DS.Cancel;
  CheckEquals('Anton', DS.FieldByName('Name').AsString, 'Esc/Cancel stellt wieder her');
end;

{ 7a #7 }

procedure TAudit7BTests.TileViewTypeAheadCycles;
var
  V: TPPGTileView;
begin
  V := TPPGTileView.Create(FForm);
  V.Parent := FForm;
  V.SetBounds(0, 0, 600, 400);
  V.Items.Add('Apfel');
  V.Items.Add('Birne');
  V.Items.Add('Banane');
  V.Perform(WM_CHAR, Ord('b'), 0);
  CheckEquals(1, V.ItemIndex);
  V.Perform(WM_CHAR, Ord('b'), 0);
  CheckEquals(2, V.ItemIndex, 'b nochmal blaettert weiter');
  V.Perform(WM_CHAR, Ord('b'), 0);
  CheckEquals(1, V.ItemIndex, 'und wieder von vorn');
end;

procedure TAudit7BTests.ColumnComboTypeAheadCycles;
var
  C: TPPGColumnComboBox;
  Ch: Char;
begin
  C := TPPGColumnComboBox.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(10, 10, 260, 32);
  C.Animation.Enabled := False;
  C.Columns.Add.Title := 'Nr';
  C.Columns.Add.Title := 'Name';
  C.Items.Add('1|Mueller');
  C.Items.Add('2|Albers');
  C.Items.Add('3|Zander');
  C.Items.Add('4|Mayer');
  C.DisplayColumn := 1;
  C.ItemIndex := 1;
  Ch := 'm';
  C.Perform(WM_CHAR, Ord(Ch), 0);
  CheckEquals(3, C.ItemIndex, 'zu: m -> naechster Treffer');
  C.Perform(WM_CHAR, Ord(Ch), 0);
  CheckEquals(0, C.ItemIndex, 'zu: m nochmal -> blaettert');
  Sleep(1100);
  C.ItemIndex := 1;
  FForm.Show;
  try
    C.DropDown;
    CheckTrue(C.DroppedDown);
    C.Perform(WM_CHAR, Ord(Ch), 0);
    CheckEquals(3, TPPGColumnPopup(C.Popup).FocusRow, 'offen: m -> naechster Treffer');
    C.Perform(WM_CHAR, Ord(Ch), 0);
    CheckEquals(0, TPPGColumnPopup(C.Popup).FocusRow, 'offen: m nochmal -> blaettert');
    C.CloseUp(False);
  finally
    FForm.Hide;
  end;
end;

{ 7f #1 }

procedure TAudit7BTests.ListToolTipForTruncatedText;
var
  L: TPPGListBox;
  R: TRect;
begin
  L := NewList('');
  L.Width := 80;
  L.Items.Add('Ein sehr langer Eintrag, der nicht passt');
  L.Items.Add('kurz');
  R := L.ItemRect(0);
  CheckEquals('Ein sehr langer Eintrag, der nicht passt',
    HintAt(L, Point(R.Left + 10, (R.Top + R.Bottom) div 2)), 'abgeschnitten: Tooltip');
  R := L.ItemRect(1);
  CheckEquals('', HintAt(L, Point(R.Left + 10, (R.Top + R.Bottom) div 2)), 'passt: kein Tooltip');
  L.Hint := 'Eigener';
  R := L.ItemRect(0);
  CheckEquals('Eigener', HintAt(L, Point(R.Left + 10, (R.Top + R.Bottom) div 2), 'Eigener'),
    'eigener Hint hat Vorrang');
end;

procedure TAudit7BTests.GridToolTipForTruncatedCell;
var
  G: TPPGGrid;
  I: Integer;
  R: TRect;
  HI: Vcl.Controls.THintInfo;
  M: TCMHintShow;
begin
  G := NewGrid;
  G.Cells[1, 0] := 'Eine sehr lange Ueberschrift';
  G.Cells[1, 1] := 'Ein sehr langer Zelltext, der nicht passt';
  G.Cells[2, 1] := 'k';
  R := G.CellRect(1, 1);
  CheckEquals('Ein sehr langer Zelltext, der nicht passt',
    HintAt(G, Point(R.Left + 5, R.Top + 5)), 'abgeschnittene Zelle');
  FillChar(HI, SizeOf(HI), 0);
  HI.CursorPos := Point(R.Left + 5, R.Top + 5);
  M.Msg := CM_HINTSHOW;
  M.HintInfo := @HI;
  G.Dispatch(M);
  CheckTrue(EqualRect(R, HI.CursorRect), 'Tooltip gilt fuer die Zelle');
  R := G.CellRect(2, 1);
  CheckEquals('', HintAt(G, Point(R.Left + 5, R.Top + 5)), 'passt: kein Tooltip');
  R := G.CellRect(1, 0);
  CheckEquals('Eine sehr lange Ueberschrift', HintAt(G, Point(R.Left + 5, R.Top + 5)),
    'Kopfzeile');
  // Zellart (Haken) zeichnet selbst: kein Text-Tooltip
  for I := 0 to 3 do
    G.Columns.Add;
  G.Columns[2].CellKind := ckCheck;
  G.Cells[2, 1] := 'Ein sehr langer Zelltext, der nicht passt';
  G.Cells[1, 1] := 'Ein sehr langer Zelltext, der nicht passt';
  R := G.CellRect(1, 1);
  CheckEquals(G.Cells[1, 1], HintAt(G, Point(R.Left + 5, R.Top + 5)), 'mit Spalten');
  R := G.CellRect(2, 1);
  CheckEquals('', HintAt(G, Point(R.Left + 5, R.Top + 5)), 'Hakenzelle');
end;

{ 7f #2 }

procedure TAudit7BTests.TileHintOnlyWhenTruncated;
var
  V: TPPGTileView;
  R: TRect;
begin
  V := TPPGTileView.Create(FForm);
  V.Parent := FForm;
  V.SetBounds(0, 0, 600, 400);
  V.Items.Add('Kurz');
  V.Items.Add('Eine ausgesprochen lange Beschriftung, die in keine Kachel passt, '
    + 'auch nicht in eine breite');
  R := V.ItemRect(0);
  CheckEquals('', HintAt(V, Point(R.Left + 5, R.Top + 5)), 'passt: kein Hint');
  R := V.ItemRect(1);
  CheckEquals(V.Items[1].Text, HintAt(V, Point(R.Left + 5, R.Top + 5)), 'abgeschnitten: Hint');
  V.Hint := 'Eigener';
  CheckEquals('Eigener', HintAt(V, Point(R.Left + 5, R.Top + 5), 'Eigener'),
    'eigener Hint hat Vorrang');
end;

{ 7f #3 }

procedure TAudit7BTests.TagEditMouseLeaveResetsHot;
var
  T: TPPGTagEdit;
  X, Y: Integer;
  B: TBitmap;
begin
  T := TPPGTagEdit.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(0, 0, 300, 32);
  T.Tags.Add('Eins');
  T.Tags.Add('Zwei');
  B := RenderToBitmap(T);
  B.Free;
  Y := T.Height div 2;
  X := 2;
  while (X < T.Width) and (PrivInt(T, 'FHotTag') < 0) do
  begin
    T.Perform(WM_MOUSEMOVE, 0, MakeLParam(X, Y));
    Inc(X, 2);
  end;
  CheckTrue(PrivInt(T, 'FHotTag') >= 0, 'Maus ueber einem Tag');
  T.Perform(CM_MOUSELEAVE, 0, 0);
  CheckEquals(-1, PrivInt(T, 'FHotTag'), 'Maus verlaesst das Feld: kein Hot-Tag');
  T.Perform(WM_MOUSEMOVE, 0, MakeLParam(X - 2, Y));
  CheckTrue(PrivInt(T, 'FHotTag') >= 0);
  // Wechsel ins innere Edit: das meldet sein CM_MOUSEENTER an den Parent
  T.Perform(CM_MOUSEENTER, 0, LPARAM(T.Controls[0]));
  CheckEquals(-1, PrivInt(T, 'FHotTag'), 'Wechsel ins Edit: kein Hot-Tag');
end;

{ 7f #6 }

procedure TAudit7BTests.RadioArrowsMirroredInRtl;
var
  R1, R2, R3: TPPGRadioButton;
  K: Word;
begin
  NewRadios(R1, R2, R3);
  R2.Checked := True;
  R2.BiDiMode := bdRightToLeft;
  K := VK_RIGHT;
  TRadioAccess7(R2).KeyDown(K, []);
  CheckTrue(R1.Checked, 'RTL: Pfeil rechts geht zurueck');
  R2.Checked := True;
  K := VK_LEFT;
  TRadioAccess7(R2).KeyDown(K, []);
  CheckTrue(R3.Checked, 'RTL: Pfeil links geht vor');
  R2.Checked := True;
  K := VK_DOWN;
  TRadioAccess7(R2).KeyDown(K, []);
  CheckTrue(R3.Checked, 'Pfeil runter bleibt vorwaerts');
end;

{ neue API }

procedure TAudit7BTests.TypeAheadRecord;
var
  T: TPPGTypeAhead;
begin
  T.Reset;
  CheckEquals('a', T.Add('a'), 'erster Buchstabe');
  CheckEquals('a', T.Add('a'), 'derselbe Buchstabe: blaettern');
  CheckEquals('a', T.Add('A'), 'auch in anderer Schreibung');
  CheckEquals('aaAb', T.Add('b'), 'anderer Buchstabe: Text waechst');
  T.Tick := GetTickCount - PPGTypeAheadMs - 100;
  CheckEquals('x', T.Add('x'), 'nach der Pause neu');
  CheckEquals('xy', T.Add('y'));
  T.Reset;
  CheckEquals('', T.Text);
end;

procedure TAudit7BTests.DragExceededHalfRect;
var
  HX, HY: Integer;
begin
  HX := GetSystemMetrics(SM_CXDRAG) div 2;
  if HX < 1 then
    HX := 1;
  HY := GetSystemMetrics(SM_CYDRAG) div 2;
  if HY < 1 then
    HY := 1;
  CheckFalse(PPGDragExceeded(Point(100, 100), Point(100 + HX, 100)), 'auf dem Rand: noch kein Ziehen');
  CheckFalse(PPGDragExceeded(Point(100, 100), Point(100 - HX, 100 + HY)));
  CheckTrue(PPGDragExceeded(Point(100, 100), Point(100 + HX + 1, 100)), 'waagerecht');
  CheckTrue(PPGDragExceeded(Point(100, 100), Point(100, 100 - HY - 1)), 'senkrecht');
end;

procedure TAudit7BTests.GridClearAndCutMethods;
var
  G: TPPGGrid;
  Sel: TGridRect;
begin
  G := NewGrid;
  G.OnSetEditText := SetEditText;
  G.Cells[2, 2] := '';
  Sel.Left := 1;
  Sel.Top := 1;
  Sel.Right := 2;
  Sel.Bottom := 2;
  G.Selection := Sel;
  G.ClearSelection;
  CheckEquals(3, FSetCount, 'ein Ereignis je geleerter Zelle (leere ausgelassen)');
  CheckEquals('', G.Cells[2, 1]);
  G.Cells[1, 1] := 'a';
  Sel.Right := 1;
  Sel.Bottom := 1;
  G.Selection := Sel;
  GridCut7(G);
  CheckEquals('a'#13#10, GetClip7, 'ausgeschnitten');
  CheckEquals('', G.Cells[1, 1]);
end;

procedure TAudit7BTests.ToolTipsPublishedAndSwitchable;
const
  Classes: array[0..4] of TClass = (TPPGListBox, TPPGCheckListBox, TPPGTreeView, TPPGGrid,
    TPPGDBGrid);
var
  I: Integer;
  P: PPropInfo;
  L: TPPGListBox;
  G: TPPGGrid;
  R: TRect;
begin
  for I := 0 to High(Classes) do
  begin
    P := GetPropInfo(Classes[I], 'ToolTips');
    CheckTrue(P <> nil, Classes[I].ClassName + ': ToolTips veroeffentlicht');
    CheckEquals(Ord(True), P^.Default, Classes[I].ClassName + ': Vorgabe True');
  end;
  L := NewList('');
  L.Width := 80;
  L.Items.Add('Ein sehr langer Eintrag, der nicht passt');
  L.ToolTips := False;
  R := L.ItemRect(0);
  CheckEquals('', HintAt(L, Point(R.Left + 10, (R.Top + R.Bottom) div 2)), 'ListBox: aus');
  G := NewGrid;
  G.Cells[1, 1] := 'Ein sehr langer Zelltext, der nicht passt';
  G.ToolTips := False;
  R := G.CellRect(1, 1);
  CheckEquals('', HintAt(G, Point(R.Left + 5, R.Top + 5)), 'Grid: aus');
end;

initialization
  RegisterTest('Audit7B', TAudit7BTests.Suite);

end.
