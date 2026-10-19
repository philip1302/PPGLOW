unit PPG.Tests.DBGridGrouping;

{ Tests fuer das Gruppieren im DB-Grid (Gruppe 5, Schritt 6b): Gruppen ueber
  die ganze Datenmenge (Column.GroupIndex, GroupBy, mehrere Ebenen), Zuklappen
  und Erhalt beim Neulesen, Navigation (Tasten, Navigator, Locate,
  LocateRecord), Filterzeile und Suche mit Gruppen, Bearbeiten, Einfuegen und
  Loeschen, Mehrfachauswahl in der Reihenfolge der Ansicht, Gruppen-Summen,
  Export und RowValue, unveraendertes Verhalten ohne Gruppierung, Streaming
  und ungueltige Werte.

  Daten: TClientDataSet im Speicher (synthetische Werte, OrtID = I mod 3 + 1).
  Formate fest deutsch (PPGTestGermanFormat). }

interface

uses
  TestFramework, Winapi.Windows, System.Classes, System.SysUtils, System.Types,
  System.Variants, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Menus, Vcl.DBGrids, Data.DB,
  Datasnap.DBClient, MidasLib,
  PPG.Types, PPG.Exceptions, PPG.Controls.Base, PPG.Controls.Scroll, PPG.Grid.Data,
  PPG.Grid.Styles, PPG.Grid, PPG.Grid.Columns, PPG.DB.Grid,
  PPG.Tests.Controls, PPG.Tests.Phase9c;

type
  TDBGridGroupingTests = class(TDBTestCase)
  private
    FStyleNotes: TStringList;
    function NewGrid(N: Integer; const Cols: array of string): TPPGDBGrid;
    function ColOf(G: TPPGDBGrid; const FieldName: string): Integer;
    function Column(G: TPPGDBGrid; const FieldName: string): TPPGDBGridColumn;
    function GroupOfKey(G: TPPGDBGrid; const Key: string): Integer;
    function FocusedID(G: TPPGDBGrid): Integer;
    function CurID: Integer;
    procedure Key(G: TPPGDBGrid; VK: Word; Shift: TShiftState = []);
    procedure Press(G: TPPGDBGrid; const S: string);
    procedure GroupTextHook(Sender: TObject; Group: Integer; var Text: string);
    procedure StyleNote(Sender: TObject; ACol, ARow: Integer; var Style: TPPGGridCellStyle);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure DefaultsRangeAndStreaming;
    procedure GroupsWholeDataSetAndUngroup;
    procedure CollapseKeepsStateOnReload;
    procedure NavigationKeysAndDataSetMoves;
    procedure FilterRowAndSearchWithGroups;
    procedure EditInsertDeleteUpdateView;
    procedure MultiSelectInViewOrder;
    procedure FootersExportAndRowValue;
    procedure WithoutGroupingBufferUnchanged;
  end;

implementation

type
  TDBGridAccess = class(TPPGDBGrid);

procedure ForcePPI96(C: TControl);
begin
{$IF CompilerVersion >= 33.0}
  if C.CurrentPPI <> 96 then
    C.ScaleForPPI(96);
{$IFEND}
end;

{ TDBGridGroupingTests }

procedure TDBGridGroupingTests.SetUp;
begin
  inherited SetUp;
  FormatSettings := PPGTestGermanFormat;
  FStyleNotes := TStringList.Create;
end;

procedure TDBGridGroupingTests.TearDown;
begin
  FreeAndNil(FStyleNotes);
  inherited TearDown;
end;

function TDBGridGroupingTests.NewGrid(N: Integer; const Cols: array of string): TPPGDBGrid;
var
  I: Integer;
begin
  FillData(N);
  Result := TPPGDBGrid.Create(FForm);
  Result.Parent := FForm;
  ForcePPI96(Result);
  Result.BorderStyle := bsNone;
  Result.ScrollBarMode := sbmNever;
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.SetBounds(0, 0, 640, 400);
  Result.HandleNeeded;
  for I := 0 to High(Cols) do
    TPPGDBGridColumn(Result.Columns.Add).FieldName := Cols[I];
  Result.DataSource := FSource;
end;

function TDBGridGroupingTests.ColOf(G: TPPGDBGrid; const FieldName: string): Integer;
var
  I: Integer;
begin
  for I := 0 to G.FieldCount - 1 do
    if SameText(G.Fields[I].FieldName, FieldName) then
      Exit(TDBGridAccess(G).FixedCols + I);
  Result := -1;
end;

function TDBGridGroupingTests.Column(G: TPPGDBGrid; const FieldName: string): TPPGDBGridColumn;
var
  I: Integer;
begin
  for I := 0 to G.Columns.Count - 1 do
    if SameText(TPPGDBGridColumn(G.Columns[I]).FieldName, FieldName) then
      Exit(TPPGDBGridColumn(G.Columns[I]));
  Result := nil;
end;

function TDBGridGroupingTests.GroupOfKey(G: TPPGDBGrid; const Key: string): Integer;
var
  I: Integer;
begin
  for I := 0 to G.GroupCount - 1 do
    if (G.GroupInfo(I).Level = 0) and (G.GroupInfo(I).Key = Key) then
      Exit(I);
  Result := -1;
end;

function TDBGridGroupingTests.FocusedID(G: TPPGDBGrid): Integer;
var
  R: Integer;
begin
  R := G.Row;
  if R < TDBGridAccess(G).FixedRows then
    Exit(-1);
  Result := StrToIntDef(TDBGridAccess(G).GetCellText(ColOf(G, 'ID'), R), -1);
end;

function TDBGridGroupingTests.CurID: Integer;
begin
  if FData.State = dsInsert then
    Result := -1
  else
    Result := FData.FieldByName('ID').AsInteger;
end;

procedure TDBGridGroupingTests.Key(G: TPPGDBGrid; VK: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := VK;
  TDBGridAccess(G).NavigateKey(K, Shift);
end;

procedure TDBGridGroupingTests.Press(G: TPPGDBGrid; const S: string);
var
  I: Integer;
  Ch: Char;
begin
  for I := 1 to Length(S) do
  begin
    Ch := S[I];
    TDBGridAccess(G).KeyPress(Ch);
  end;
end;

procedure TDBGridGroupingTests.GroupTextHook(Sender: TObject; Group: Integer; var Text: string);
begin
  Text := 'Ort ' + TPPGDBGrid(Sender).GroupInfo(Group).Key;
end;

procedure TDBGridGroupingTests.StyleNote(Sender: TObject; ACol, ARow: Integer;
  var Style: TPPGGridCellStyle);
begin
  FStyleNotes.Add(IntToStr(ARow) + '=' + VarToStr(TPPGDBGrid(Sender).RowValue('Notiz')));
end;

procedure TDBGridGroupingTests.DefaultsRangeAndStreaming;
var
  G, G2: TPPGDBGrid;
  C: TPPGDBGridColumn;
  M: TMemoryStream;
  T: TStringStream;
begin
  G := TPPGDBGrid.Create(nil);
  G2 := TPPGDBGrid.Create(nil);
  M := TMemoryStream.Create;
  T := TStringStream.Create('');
  try
    CheckFalse(G.ShowGroupPanel);
    CheckFalse(G.GroupFooter);
    CheckFalse(G.GroupedView, 'ohne Datenmenge nicht gruppiert');
    CheckEquals(-1, G.ActiveDataRow);
    CheckEquals(0, Length(G.ActiveGroupValues));
    CheckFalse(G.LocateRecord('ID', 1, []), 'ohne Datenmenge');
    G.RefreshGroups; // ohne Gruppierung: nichts
    C := TPPGDBGridColumn(G.Columns.Add);
    C.FieldName := 'OrtID';
    CheckEquals(-1, C.GroupIndex);
    try
      C.GroupIndex := -2;
      Fail('GroupIndex -2');
    except
      on E: EPPGPropertyError do
        ;
    end;
    try
      C.GroupIndex := 101;
      Fail('GroupIndex 101');
    except
      on E: EPPGPropertyError do
        ;
    end;
    CheckEquals(-1, C.GroupIndex, 'unveraendert');
    M.WriteComponent(G);
    M.Position := 0;
    ObjectBinaryToText(M, T);
    CheckEquals(0, Pos('ShowGroupPanel', T.DataString), 'Vorgabe nicht gespeichert');
    CheckEquals(0, Pos('GroupFooter', T.DataString));
    CheckEquals(0, Pos('GroupIndex', T.DataString));
    G.ShowGroupPanel := True;
    G.GroupFooter := True;
    C.GroupIndex := 0;
    G.OnGetGroupText := GroupTextHook;
    M.Clear;
    M.WriteComponent(G);
    M.Position := 0;
    M.ReadComponent(G2);
    CheckTrue(G2.ShowGroupPanel);
    CheckTrue(G2.GroupFooter);
    CheckEquals(0, TPPGDBGridColumn(G2.Columns[0]).GroupIndex);
  finally
    T.Free;
    M.Free;
    G2.Free;
    G.Free;
  end;
end;

procedure TDBGridGroupingTests.GroupsWholeDataSetAndUngroup;
var
  G: TPPGDBGrid;
  R0, I: Integer;
  V: TArray<string>;
  B: TBitmap;
begin
  G := NewGrid(30, ['ID', 'Name', 'OrtID', 'Aktiv', 'Preis']);
  R0 := TDBGridAccess(G).RowCount;
  CheckTrue(R0 < 31, 'ohne Gruppierung: nur der Puffer');
  CheckFalse(G.GroupedView);
  CheckEquals(0, G.GroupReadCount);
  Column(G, 'OrtID').GroupIndex := 0;
  CheckTrue(G.GroupedView);
  CheckEquals(1, G.GroupReadCount, 'einmal gelesen');
  CheckEquals(TDBGridAccess(G).FixedRows + 30, TDBGridAccess(G).RowCount, 'alle Saetze');
  CheckEquals(3, G.GroupCount);
  for I := 0 to 2 do
  begin
    CheckEquals(IntToStr(I + 1), G.GroupInfo(I).Key, 'nach Wert geordnet');
    CheckEquals(10, G.GroupInfo(I).Count);
    CheckTrue(G.GroupInfo(I).Expanded, 'anfangs aufgeklappt');
  end;
  CheckEquals(1, CurID, 'Datenmenge bleibt');
  CheckEquals(1, FocusedID(G), 'Fokus auf dem aktiven Satz');
  CheckEquals(G.ActiveDataRow, G.Row);
  CheckTrue(G.IsDataRow(G.FocusRow));
  V := G.ActiveGroupValues;
  CheckEquals(1, Length(V));
  CheckEquals('2', V[0]);
  CheckTrue(Pos('(10)', G.GroupText(0)) > 0, 'Feld: Wert (Anzahl)');
  G.OnGetGroupText := GroupTextHook;
  CheckEquals('Ort 1', G.GroupText(0), 'OnGetGroupText');
  G.OnGetGroupText := nil;
  B := RenderToBitmap(G);
  B.Free;
  // Zwei Ebenen ohne Neulesen
  G.GroupBy([ColOf(G, 'OrtID'), ColOf(G, 'Aktiv')]);
  CheckEquals(1, G.GroupReadCount, 'umgruppiert ohne Lesen');
  CheckEquals(9, G.GroupCount, '3 Orte + je 2 Aktiv');
  V := G.ActiveGroupValues;
  CheckEquals(2, Length(V));
  CheckEquals('2', V[0]);
  CheckEquals('True', V[1], 'Kaestchen nach Wert');
  CheckEquals(1, FocusedID(G));
  // Aufheben: wieder der Puffer
  G.Ungroup;
  CheckFalse(G.GroupedView);
  CheckEquals(R0, TDBGridAccess(G).RowCount);
  CheckEquals(0, G.GroupCount);
  CheckEquals(1, CurID);
  // Gruppenleiste und Kopfmenue im ungruppierten Grid
  G.ShowGroupPanel := True;
  G.GroupBy([ColOf(G, 'Name')]);
  CheckEquals(30, G.GroupCount, 'nach Name: je Satz eine Gruppe');
  G.Ungroup;
end;

procedure TDBGridGroupingTests.CollapseKeepsStateOnReload;
var
  G: TPPGDBGrid;
  Reads: Integer;
begin
  G := NewGrid(30, ['ID', 'Name', 'OrtID']);
  Column(G, 'OrtID').GroupIndex := 0;
  G.ExpandGroup(GroupOfKey(G, '3'), False);
  CheckFalse(G.GroupInfo(GroupOfKey(G, '3')).Expanded);
  Reads := G.GroupReadCount;
  // Aenderung von aussen (wie Refresh): DataSetChanged
  FData.DisableControls;
  FData.EnableControls;
  CheckEquals(Reads + 1, G.GroupReadCount, 'DataSetChanged liest neu');
  CheckFalse(G.GroupInfo(GroupOfKey(G, '3')).Expanded, 'zugeklappt nach Gruppenwert');
  CheckTrue(G.GroupInfo(GroupOfKey(G, '2')).Expanded);
  CheckEquals(1, FocusedID(G), 'Fokus bleibt');
  G.FullCollapse;
  CheckEquals(TDBGridAccess(G).FixedRows + 3, G.ViewRowCount, 'nur Gruppenzeilen');
  CheckEquals(1, CurID, 'Zuklappen bewegt die Datenmenge nicht');
  G.FullExpand;
  CheckEquals(TDBGridAccess(G).FixedRows + 33, G.ViewRowCount);
  // Schliessen und Oeffnen: Zustand bleibt, die Gruppe des Satzes klappt auf
  G.ExpandGroup(GroupOfKey(G, '3'), False);
  G.ExpandGroup(GroupOfKey(G, '2'), False);
  FData.Close;
  CheckFalse(G.GroupedView);
  FData.Open;
  CheckTrue(G.GroupedView);
  CheckFalse(G.GroupInfo(GroupOfKey(G, '3')).Expanded, 'bleibt zu');
  CheckTrue(G.GroupInfo(GroupOfKey(G, '2')).Expanded, 'Gruppe des aktiven Satzes');
  CheckEquals(CurID, FocusedID(G));
end;

procedure TDBGridGroupingTests.NavigationKeysAndDataSetMoves;
var
  G: TPPGDBGrid;
  Reads, G0: Integer;
begin
  G := NewGrid(30, ['ID', 'Name', 'OrtID']);
  Column(G, 'OrtID').GroupIndex := 0;
  Reads := G.GroupReadCount;
  // Gruppe '2': 1, 4, 7 ...
  Key(G, VK_DOWN);
  CheckEquals(4, FocusedID(G), 'naechste Zeile der Gruppe');
  CheckEquals(4, CurID, 'Datenmenge folgt');
  Key(G, VK_UP);
  CheckEquals(1, CurID);
  Key(G, VK_UP);
  CheckEquals(-1, G.Row, 'Gruppenkopf');
  CheckEquals(1, CurID, 'Gruppenzeile bewegt die Datenmenge nicht');
  G0 := G.GroupOfRow(G.FocusRow);
  Key(G, VK_LEFT);
  CheckFalse(G.GroupInfo(G0).Expanded, 'Pfeil links klappt zu');
  Key(G, VK_RIGHT);
  CheckTrue(G.GroupInfo(G0).Expanded, 'Pfeil rechts klappt auf');
  Key(G, VK_SPACE);
  CheckFalse(G.GroupInfo(G0).Expanded, 'Leertaste schaltet um');
  Key(G, VK_ADD);
  CheckTrue(G.GroupInfo(G0).Expanded, '+ klappt auf');
  Key(G, VK_SUBTRACT);
  CheckFalse(G.GroupInfo(G0).Expanded, '- klappt zu');
  Key(G, VK_RETURN);
  CheckTrue(G.GroupInfo(G0).Expanded, 'Enter schaltet um');
  // Navigator: Satzwechsel in der Reihenfolge der Datenmenge
  FData.Next;
  CheckEquals(2, FocusedID(G), 'Fokus folgt der Datenmenge');
  FData.Prior;
  CheckEquals(1, FocusedID(G));
  CheckEquals(Reads, G.GroupReadCount, 'Next/Prior lesen nicht neu');
  // Strg+Pos1: erste Zeile der Ansicht (Gruppenkopf), dann die erste Datenzeile
  Key(G, VK_HOME, [ssCtrl]);
  CheckEquals(-1, G.Row);
  Key(G, VK_DOWN);
  CheckEquals(3, CurID, 'erster Satz der Gruppe 1');
  Key(G, VK_END, [ssCtrl]);
  CheckEquals(29, CurID, 'letzter Satz der Ansicht');
  Key(G, VK_DOWN);
  CheckEquals(29, CurID, 'am Ende wird nichts angehaengt');
  CheckTrue(FData.State = dsBrowse);
  // LocateRecord in eine zugeklappte Gruppe: ohne Neulesen, Gruppe auf
  G.ExpandGroup(GroupOfKey(G, '1'), False);
  CheckTrue(G.LocateRecord('ID', 9, []));
  CheckEquals(9, CurID);
  CheckEquals(9, FocusedID(G));
  CheckTrue(G.GroupInfo(GroupOfKey(G, '1')).Expanded, 'aufgeklappt');
  CheckEquals(Reads, G.GroupReadCount, 'LocateRecord liest nicht neu');
  CheckFalse(G.LocateRecord('ID', 999, []));
  CheckEquals(9, CurID);
  // Locate der Anwendung meldet DataSetChanged: liest neu, Fokus folgt
  FData.Locate('ID', 10, []);
  CheckEquals(Reads + 1, G.GroupReadCount);
  CheckEquals(10, FocusedID(G));
  // Zeile per Code (Row) bewegt die Datenmenge
  G.Row := G.ActiveDataRow + 1;
  CheckEquals(11, CurID, 'Zeile = Satz in der Datenmenge');
end;

procedure TDBGridGroupingTests.FilterRowAndSearchWithGroups;
var
  G: TPPGDBGrid;
  Reads, I, Sum: Integer;
begin
  G := NewGrid(30, ['ID', 'Name', 'OrtID', 'Preis']);
  Column(G, 'OrtID').GroupIndex := 0;
  G.ShowFilterRow := True;
  G.Filters[ColOf(G, 'ID')] := '>15';
  CheckEquals(15, FData.RecordCount);
  CheckTrue(G.GroupedView);
  CheckEquals(TDBGridAccess(G).FixedRows + 15, TDBGridAccess(G).RowCount, 'nur gefilterte Saetze');
  Sum := 0;
  for I := 0 to G.GroupCount - 1 do
    Inc(Sum, G.GroupInfo(I).Count);
  CheckEquals(15, Sum);
  CheckEquals(CurID, FocusedID(G), 'Fokus auf dem ersten gefilterten Satz');
  G.ClearFilters;
  CheckEquals(TDBGridAccess(G).FixedRows + 30, TDBGridAccess(G).RowCount);
  // Suchfeld: Reihenfolge der Ansicht, zugeklappte Gruppen klappen auf
  G.FindPanel := fpmAlways;
  Reads := G.GroupReadCount;
  G.ExpandGroup(GroupOfKey(G, '3'), False);
  G.FindText := 'name29';
  CheckTrue(G.FindNext);
  CheckEquals(29, CurID);
  CheckEquals(29, FocusedID(G));
  CheckTrue(G.GroupInfo(GroupOfKey(G, '3')).Expanded);
  CheckEquals(ColOf(G, 'Name'), G.DataCol(G.FocusCol), 'Fokus auf der Fundstelle');
  CheckTrue(G.LocateRecord('ID', 1, []));
  G.Col := ColOf(G, 'ID');
  G.FindText := 'name2';
  CheckTrue(G.FindNext);
  CheckEquals(22, CurID, 'naechster Treffer in der Gruppe (1, 4 ... 22)');
  CheckTrue(G.FindNext);
  CheckEquals(25, CurID);
  CheckTrue(G.FindPrevious);
  CheckEquals(22, CurID);
  G.FindText := 'zzz';
  CheckFalse(G.FindNext);
  CheckEquals(22, CurID, 'kein Treffer: Satz bleibt');
  CheckEquals(Reads, G.GroupReadCount, 'Suche liest nicht neu');
  // Tippsuche in der Fokusspalte
  G.FindPanel := fpmNone;
  G.IncrementalSearch := True;
  G.Options := G.Options - [dgEditing];
  PPGSetTypeAheadClock(PPGTestClock);
  G.Col := ColOf(G, 'Name');
  Press(G, 'name13');
  CheckEquals(13, CurID);
  CheckEquals(13, FocusedID(G));
end;

procedure TDBGridGroupingTests.EditInsertDeleteUpdateView;
var
  G: TPPGDBGrid;
  Reads, NameCol, R: Integer;
begin
  G := NewGrid(30, ['ID', 'Name', 'OrtID']);
  Column(G, 'OrtID').GroupIndex := 0;
  NameCol := ColOf(G, 'Name');
  Reads := G.GroupReadCount;
  // Bearbeiten in der Zelle: Post liest nur den Satz
  CheckTrue(TDBGridAccess(G).CanEditCell(NameCol, G.FocusRow), 'Datenzeile bearbeitbar');
  TDBGridAccess(G).SetCellByUser(NameCol, G.Row, 'Neu');
  CheckTrue(FData.State = dsEdit);
  FData.Post;
  CheckEquals('Neu', TDBGridAccess(G).GetCellText(NameCol, G.Row));
  CheckEquals(Reads, G.GroupReadCount, 'Post liest nur den Satz');
  // Gruppenwert aendern: neu gruppiert, Fokus folgt dem Satz
  FData.Edit;
  FData.FieldByName('OrtID').AsInteger := 3;
  FData.Post;
  CheckEquals(Reads, G.GroupReadCount);
  CheckEquals(11, G.GroupInfo(GroupOfKey(G, '3')).Count);
  CheckEquals(9, G.GroupInfo(GroupOfKey(G, '2')).Count);
  CheckEquals(1, FocusedID(G));
  CheckEquals('3', G.ActiveGroupValues[0]);
  // Cancel liest den Satz zurueck
  FData.Edit;
  FData.FieldByName('Name').AsString := 'Weg';
  CheckEquals('Weg', TDBGridAccess(G).GetCellText(NameCol, G.Row), 'Feldaenderung sofort');
  FData.Cancel;
  CheckEquals('Neu', TDBGridAccess(G).GetCellText(NameCol, G.Row));
  // Wechsel der Zeile bucht die Bearbeitung
  R := G.Row;
  FData.Edit;
  FData.FieldByName('Name').AsString := 'Gebucht';
  Key(G, VK_DOWN);
  CheckTrue(FData.State = dsBrowse, 'gebucht');
  CheckEquals('Gebucht', TDBGridAccess(G).GetCellText(NameCol, R));
  CheckEquals(Reads, G.GroupReadCount);
  // Einfuegen: eigene Zeile, nach Post in ihrer Gruppe
  FData.Insert;
  CheckEquals(TDBGridAccess(G).FixedRows + 31, TDBGridAccess(G).RowCount, 'Zeile fuer den neuen Satz');
  CheckEquals(G.ActiveDataRow, G.Row, 'Fokus auf dem neuen Satz');
  FData.FieldByName('ID').AsInteger := 31;
  FData.FieldByName('Name').AsString := 'Name31';
  FData.FieldByName('OrtID').AsInteger := 1;
  CheckEquals('Name31', TDBGridAccess(G).GetCellText(NameCol, G.Row), 'Eingabe sichtbar');
  FData.Post;
  CheckEquals(31, FocusedID(G));
  CheckEquals(11, G.GroupInfo(GroupOfKey(G, '1')).Count);
  CheckEquals('1', G.ActiveGroupValues[0]);
  // Einfg und Pfeil hoch: unveraenderter neuer Satz verschwindet
  Key(G, VK_INSERT);
  CheckTrue(FData.State = dsInsert);
  CheckEquals(TDBGridAccess(G).FixedRows + 32, TDBGridAccess(G).RowCount);
  Key(G, VK_UP);
  CheckTrue(FData.State = dsBrowse);
  CheckEquals(TDBGridAccess(G).FixedRows + 31, TDBGridAccess(G).RowCount);
  // Loeschen
  Reads := G.GroupReadCount;
  CheckTrue(G.LocateRecord('ID', 5, []));
  FData.Delete;
  CheckEquals(Reads + 1, G.GroupReadCount, 'Loeschen liest neu');
  CheckEquals(TDBGridAccess(G).FixedRows + 30, TDBGridAccess(G).RowCount);
  CheckEquals(CurID, FocusedID(G));
end;

procedure TDBGridGroupingTests.MultiSelectInViewOrder;
var
  G: TPPGDBGrid;
  Vals: TArray<Variant>;
  Reads: Integer;
begin
  G := NewGrid(30, ['ID', 'Name', 'OrtID']);
  G.Options := G.Options + [dgMultiSelect];
  Column(G, 'OrtID').GroupIndex := 0;
  Reads := G.GroupReadCount;
  CheckTrue(G.LocateRecord('ID', 3, []));
  Key(G, VK_DOWN, [ssShift]);
  Key(G, VK_DOWN, [ssShift]);
  CheckEquals(9, CurID, 'Gruppe 1: 3, 6, 9');
  CheckEquals(3, G.SelectedCount);
  Vals := G.SelectedValues('ID');
  CheckEquals(3, Length(Vals));
  CheckEquals(3, Integer(Vals[0]));
  CheckEquals(6, Integer(Vals[1]));
  CheckEquals(9, Integer(Vals[2]));
  CheckTrue(TDBGridAccess(G).RowMarked(G.Row), 'Markierung je Satz');
  // Bereich mit Umschalt+Strg+Ende: bis zum Ende der Ansicht
  Key(G, VK_END, [ssCtrl, ssShift]);
  CheckEquals(29, CurID);
  CheckEquals(30, G.SelectedCount, 'von 3 bis zum Ende der Ansicht = alle');
  Key(G, VK_DOWN, []);
  CheckEquals(0, G.SelectedCount, 'Bewegen ohne Umschalt hebt auf');
  Key(G, Ord('A'), [ssCtrl]);
  CheckEquals(30, G.SelectedCount);
  CheckEquals(Reads, G.GroupReadCount, 'Auswahl liest nicht neu');
  G.SelectedRows.Clear;
  CheckTrue(G.LocateRecord('ID', 4, []));
  Key(G, VK_DOWN, [ssShift]);
  CheckEquals(2, G.SelectedCount);
  G.SelectedRows.Delete;
  CheckEquals(28, FData.RecordCount);
  CheckEquals(TDBGridAccess(G).FixedRows + 28, TDBGridAccess(G).RowCount, 'neu gelesen');
end;

procedure TDBGridGroupingTests.FootersExportAndRowValue;
var
  G: TPPGDBGrid;
  PC, R, I: Integer;
  D: Double;
  O: TArray<TPPGOutlineRow>;
  St: TPPGGridCellStyle;
begin
  G := NewGrid(30, ['ID', 'Name', 'OrtID', 'Preis']);
  PC := ColOf(G, 'Preis');
  Column(G, 'Preis').Aggregate := agSum;
  G.ShowFooter := True;
  G.GroupFooter := True;
  CheckEquals('', G.FooterText(PC), 'ohne Gruppierung: Sache der Datenmenge');
  G.OnGetCellStyle := StyleNote;
  Column(G, 'OrtID').GroupIndex := 0;
  CheckTrue(TryStrToFloat(G.FooterText(PC), D), G.FooterText(PC));
  CheckEquals(697.5, D, 0.001, 'Summe ueber alle Saetze');
  CheckTrue(TryStrToFloat(G.GroupFooterText(GroupOfKey(G, '1'), PC), D));
  CheckEquals(247.5, D, 0.001, 'Gruppe 1: 3+6+...+30 je 1,5');
  CheckEquals(TDBGridAccess(G).FixedRows + 36, G.ViewRowCount, 'mit Gruppenfuessen');
  // Export: Saetze in der Reihenfolge der Gruppen, Gruppenzeilen als Gliederung
  CheckEquals(30, TDBGridAccess(G).TableRowCount);
  CheckEquals('3', TDBGridAccess(G).TableCellText(0, 0), 'erste Zeile: Gruppe 1');
  CheckEquals(3.0, Double(TDBGridAccess(G).TableCellValue(0, 0)), 0.001);
  O := TDBGridAccess(G).ExportOutline;
  CheckEquals(33, Length(O), '3 Gruppen + 30 Saetze');
  CheckTrue(TDBGridAccess(G).ExportAggregate(3) = agSum);
  // RowValue fuer einen anderen als den aktiven Satz (Bildschirm)
  R := -1;
  for I := 0 to 29 do
    if TDBGridAccess(G).GetCellText(ColOf(G, 'ID'), TDBGridAccess(G).FixedRows + I) = '7' then
      R := TDBGridAccess(G).FixedRows + I;
  CheckTrue(R >= 0);
  FStyleNotes.Clear;
  St := TDBGridAccess(G).CellStyle(ColOf(G, 'Name'), R, 'x');
  CheckTrue(FStyleNotes.IndexOf(IntToStr(R) + '=Notiz 7') >= 0, FStyleNotes.Text);
  // Ohne Gruppierung wieder wie vorher
  G.OnGetCellStyle := nil;
  G.Ungroup;
  CheckEquals('', G.FooterText(PC));
  CheckEquals(30, TDBGridAccess(G).TableRowCount);
  CheckEquals('1', TDBGridAccess(G).TableCellText(0, 0), 'Reihenfolge der Datenmenge');
end;

procedure TDBGridGroupingTests.WithoutGroupingBufferUnchanged;
var
  G: TPPGDBGrid;
  M1, M2: TPopupMenu;
  R0: Integer;
begin
  G := NewGrid(200, ['ID', 'Name', 'OrtID']);
  R0 := TDBGridAccess(G).RowCount;
  CheckTrue(R0 < 50, 'Puffer');
  M1 := G.CreateHeaderMenu(ColOf(G, 'Name'));
  try
    G.ShowGroupPanel := True;
    CheckFalse(G.GroupedView, 'Leiste allein gruppiert nicht');
    CheckEquals(0, G.GroupReadCount, 'nichts gelesen');
    M2 := G.CreateHeaderMenu(ColOf(G, 'Name'));
    try
      CheckTrue(M2.Items.Count > M1.Items.Count, 'mit Leiste: Gruppieren im Kopfmenue');
    finally
      M2.Free;
    end;
  finally
    M1.Free;
  end;
  FData.Last;
  CheckEquals(200, CurID);
  CheckEquals(0, G.GroupReadCount);
  CheckTrue(TDBGridAccess(G).RowCount < 50);
  // Kartenansicht gruppiert nicht
  Column(G, 'OrtID').GroupIndex := 0;
  CheckTrue(G.GroupedView);
  CheckEquals(200, FocusedID(G), 'aktiver Satz fokussiert');
  G.ViewStyle := dgvCards;
  CheckFalse(G.GroupedView);
  G.ViewStyle := dgvTable;
  CheckTrue(G.GroupedView);
  Column(G, 'OrtID').GroupIndex := -1;
  CheckFalse(G.GroupedView);
  CheckTrue(TDBGridAccess(G).RowCount < 50, 'wieder der Puffer');
end;

initialization
  RegisterTest('DBGridGrouping', TDBGridGroupingTests.Suite);

end.
