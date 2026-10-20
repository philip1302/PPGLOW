unit PPG.Tests.DBGridKeySync;

{ Tests fuer das DB-Grid im Gruppenmodus mit Schluesselfeldern (KeyFieldNames)
  und das gesammelte Nachziehen der Datenmenge bei schneller Navigation
  (GroupSyncDelay):
  - Positionieren per Locate statt Lesezeichen (auch mehrteiliger Schluessel,
    nach Neulesen, geloeschter Satz), Mehrfachauswahl mit Schluesseln;
  - keine Lesezeichen-Zugriffe (abgeleitete Datenmenge zaehlt GetBookmark,
    GotoBookmark, BookmarkValid und CompareBookmarks);
  - Tastenwiederholung (Bit 30 in WM_KEYDOWN) bewegt nur den Fokus, die
    Datenmenge folgt einmal (Loslassen, Wartezeit, Zugriff); Einzelschritt
    sofort; Mausrad scrollt nur die Ansicht; Bearbeiten nach schneller
    Navigation trifft den fokussierten Satz.

  Daten: TClientDataSet im Speicher (synthetische Werte, OrtID = I mod 3 + 1).
  Formate fest deutsch (PPGTestGermanFormat). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Variants, Vcl.Controls, Vcl.Forms, Vcl.DBGrids, Data.DB,
  Datasnap.DBClient, MidasLib,
  PPG.Types, PPG.Exceptions, PPG.Controls.Base, PPG.Controls.Scroll, PPG.Grid,
  PPG.Grid.Columns, PPG.DB.Grid,
  PPG.Tests.Controls, PPG.Tests.Phase9c;

type
  /// Datenmenge, die die Zugriffe ueber Lesezeichen und die Satzwechsel zaehlt.
  TBookmarkCountingDataSet = class(TClientDataSet)
  public
    Gets, Gotos, Valids, Compares, Locates, Scrolls: Integer;
    /// Locate findet diesen Wert von ID nicht (Satz anderswo geloescht).
    LostID: Integer;
    procedure ResetCounts;
    /// Lesezeichen-Zugriffe insgesamt.
    function BookmarkCalls: Integer;
    function GetBookmark: TBookmark; override;
    function BookmarkValid(Bookmark: TBookmark): Boolean; override;
    function CompareBookmarks(Bookmark1, Bookmark2: TBookmark): Integer; override;
    function Locate(const KeyFields: string; const KeyValues: Variant;
      Options: TLocateOptions): Boolean; override;
  protected
    procedure InternalGotoBookmark(Bookmark: TBookmark); overload; override;
    procedure DoAfterScroll; override;
  end;

  TDBGridKeySyncTests = class(TDBTestCase)
  private
    FCnt: TBookmarkCountingDataSet;
    FCntSource: TDataSource;
    FFocusEvents: Integer;
    procedure FillCounted(N: Integer);
    procedure FillTwoPartKey;
    function NewGrid(const Cols: array of string; const Keys: string): TPPGDBGrid;
    function Column(G: TPPGDBGrid; const FieldName: string): TPPGDBGridColumn;
    function ColOf(G: TPPGDBGrid; const FieldName: string): Integer;
    function FocusedText(G: TPPGDBGrid; const FieldName: string): string;
    function FocusedID(G: TPPGDBGrid): Integer;
    function CurID: Integer;
    procedure Key(G: TPPGDBGrid; VK: Word; Shift: TShiftState = []);
    /// WM_KEYDOWN mit gesetztem Wiederholungsbit (Taste gehalten), Count mal.
    procedure RepeatKey(G: TPPGDBGrid; VK: Word; Count: Integer);
    procedure KeyUpMsg(G: TPPGDBGrid; VK: Word);
    procedure FocusChanged(Sender: TObject);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure DefaultsRangeAndStreaming;
    procedure KeyedGroupingUsesNoBookmarks;
    procedure TwoPartKeyLocatesAndKeepsAfterReload;
    procedure DeletedRecordIsNotReachable;
    procedure KeyedMultiSelectInViewOrder;
    procedure SingleStepMovesAtOnce;
    procedure RepeatedKeysMoveDataSetOnce;
    procedure RepeatedKeysFollowAfterDelay;
    procedure WheelSeriesDoesNotMoveDataSet;
    procedure AccessAfterFastNavigationHitsFocusedRecord;
    procedure OutsideMoveWinsAndDelayZero;
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

{ TBookmarkCountingDataSet }

procedure TBookmarkCountingDataSet.ResetCounts;
begin
  Gets := 0;
  Gotos := 0;
  Valids := 0;
  Compares := 0;
  Locates := 0;
  Scrolls := 0;
end;

function TBookmarkCountingDataSet.BookmarkCalls: Integer;
begin
  Result := Gets + Gotos + Valids + Compares;
end;

function TBookmarkCountingDataSet.GetBookmark: TBookmark;
begin
  Inc(Gets);
  Result := inherited GetBookmark;
end;

function TBookmarkCountingDataSet.BookmarkValid(Bookmark: TBookmark): Boolean;
begin
  Inc(Valids);
  Result := inherited BookmarkValid(Bookmark);
end;

function TBookmarkCountingDataSet.CompareBookmarks(Bookmark1, Bookmark2: TBookmark): Integer;
begin
  Inc(Compares);
  Result := inherited CompareBookmarks(Bookmark1, Bookmark2);
end;

function TBookmarkCountingDataSet.Locate(const KeyFields: string; const KeyValues: Variant;
  Options: TLocateOptions): Boolean;
begin
  Inc(Locates);
  if (LostID <> 0) and SameText(KeyFields, 'ID') and not VarIsArray(KeyValues) and
    (KeyValues = LostID) then
    Exit(False);
  Result := inherited Locate(KeyFields, KeyValues, Options);
end;

procedure TBookmarkCountingDataSet.InternalGotoBookmark(Bookmark: TBookmark);
begin
  Inc(Gotos);
  inherited InternalGotoBookmark(Bookmark);
end;

procedure TBookmarkCountingDataSet.DoAfterScroll;
begin
  Inc(Scrolls);
  inherited DoAfterScroll;
end;

{ TDBGridKeySyncTests }

procedure TDBGridKeySyncTests.SetUp;
begin
  inherited SetUp;
  FormatSettings := PPGTestGermanFormat;
  FCnt := TBookmarkCountingDataSet.Create(FForm);
  FCntSource := TDataSource.Create(FForm);
  FCntSource.DataSet := FCnt;
  FFocusEvents := 0;
end;

procedure TDBGridKeySyncTests.TearDown;
begin
  FCntSource := nil;
  FCnt := nil;
  inherited TearDown;
end;

procedure TDBGridKeySyncTests.FillCounted(N: Integer);
var
  I: Integer;
begin
  FCnt.Close;
  FCnt.FieldDefs.Clear;
  FCnt.FieldDefs.Add('ID', ftInteger);
  FCnt.FieldDefs.Add('Name', ftString, 20);
  FCnt.FieldDefs.Add('OrtID', ftInteger);
  FCnt.CreateDataSet;
  for I := 1 to N do
    FCnt.AppendRecord([I, 'Name' + IntToStr(I), (I mod 3) + 1]);
  FCnt.First;
end;

procedure TDBGridKeySyncTests.FillTwoPartKey;
var
  K, I: Integer;
begin
  // Schluessel (Kunde, Nr): einzeln nicht eindeutig, zusammen schon
  FCnt.Close;
  FCnt.FieldDefs.Clear;
  FCnt.FieldDefs.Add('Kunde', ftInteger);
  FCnt.FieldDefs.Add('Nr', ftString, 10);
  FCnt.FieldDefs.Add('Gruppe', ftString, 10);
  FCnt.FieldDefs.Add('Text', ftString, 20);
  FCnt.CreateDataSet;
  for K := 1 to 3 do
    for I := 0 to 4 do
      FCnt.AppendRecord([K, Char(Ord('A') + I), 'G' + IntToStr((K + I) mod 2),
        Format('K%d-%s', [K, Char(Ord('A') + I)])]);
  FCnt.First;
end;

function TDBGridKeySyncTests.NewGrid(const Cols: array of string; const Keys: string): TPPGDBGrid;
var
  I: Integer;
begin
  Result := TPPGDBGrid.Create(FForm);
  Result.Parent := FForm;
  ForcePPI96(Result);
  Result.BorderStyle := bsNone;
  Result.ScrollBarMode := sbmNever;
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.SetBounds(0, 0, 640, 400);
  Result.HandleNeeded;
  Result.KeyFieldNames := Keys;
  for I := 0 to High(Cols) do
    TPPGDBGridColumn(Result.Columns.Add).FieldName := Cols[I];
  Result.DataSource := FCntSource;
  Result.OnFocusedRecordChanged := FocusChanged;
end;

function TDBGridKeySyncTests.Column(G: TPPGDBGrid; const FieldName: string): TPPGDBGridColumn;
var
  I: Integer;
begin
  for I := 0 to G.Columns.Count - 1 do
    if SameText(TPPGDBGridColumn(G.Columns[I]).FieldName, FieldName) then
      Exit(TPPGDBGridColumn(G.Columns[I]));
  Result := nil;
end;

function TDBGridKeySyncTests.ColOf(G: TPPGDBGrid; const FieldName: string): Integer;
var
  I: Integer;
begin
  for I := 0 to G.FieldCount - 1 do
    if SameText(G.Fields[I].FieldName, FieldName) then
      Exit(TDBGridAccess(G).FixedCols + I);
  Result := -1;
end;

function TDBGridKeySyncTests.FocusedText(G: TPPGDBGrid; const FieldName: string): string;
begin
  if G.Row < TDBGridAccess(G).FixedRows then
    Exit('');
  Result := TDBGridAccess(G).GetCellText(ColOf(G, FieldName), G.Row);
end;

function TDBGridKeySyncTests.FocusedID(G: TPPGDBGrid): Integer;
begin
  Result := StrToIntDef(FocusedText(G, 'ID'), -1);
end;

function TDBGridKeySyncTests.CurID: Integer;
begin
  Result := FCnt.FieldByName('ID').AsInteger;
end;

procedure TDBGridKeySyncTests.Key(G: TPPGDBGrid; VK: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := VK;
  TDBGridAccess(G).NavigateKey(K, Shift);
end;

procedure TDBGridKeySyncTests.RepeatKey(G: TPPGDBGrid; VK: Word; Count: Integer);
var
  I: Integer;
begin
  // Bit 30: Taste war schon gedrueckt (automatische Wiederholung), Zaehler 1
  for I := 1 to Count do
    G.Perform(WM_KEYDOWN, VK, LPARAM($40000001));
end;

procedure TDBGridKeySyncTests.KeyUpMsg(G: TPPGDBGrid; VK: Word);
begin
  G.Perform(WM_KEYUP, VK, LPARAM($C0000001));
end;

procedure TDBGridKeySyncTests.FocusChanged(Sender: TObject);
begin
  Inc(FFocusEvents);
end;

procedure TDBGridKeySyncTests.DefaultsRangeAndStreaming;
var
  G, G2: TPPGDBGrid;
  M: TMemoryStream;
  T: TStringStream;
begin
  G := TPPGDBGrid.Create(nil);
  G2 := TPPGDBGrid.Create(nil);
  M := TMemoryStream.Create;
  T := TStringStream.Create('');
  try
    CheckEquals('', G.KeyFieldNames);
    CheckEquals(120, G.GroupSyncDelay);
    CheckFalse(G.RecordSyncPending);
    CheckFalse(G.SyncActiveRecord, 'ohne Datenmenge: nichts nachzuziehen');
    try
      G.GroupSyncDelay := -1;
      Fail('GroupSyncDelay -1');
    except
      on E: EPPGPropertyError do
        ;
    end;
    try
      G.GroupSyncDelay := 5001;
      Fail('GroupSyncDelay 5001');
    except
      on E: EPPGPropertyError do
        ;
    end;
    CheckEquals(120, G.GroupSyncDelay, 'unveraendert');
    M.WriteComponent(G);
    M.Position := 0;
    ObjectBinaryToText(M, T);
    CheckEquals(0, Pos('KeyFieldNames', T.DataString), 'Vorgabe nicht gespeichert');
    CheckEquals(0, Pos('GroupSyncDelay', T.DataString));
    G.KeyFieldNames := 'Kunde;Nr';
    G.GroupSyncDelay := 0;
    M.Clear;
    M.WriteComponent(G);
    M.Position := 0;
    M.ReadComponent(G2);
    CheckEquals('Kunde;Nr', G2.KeyFieldNames);
    CheckEquals(0, G2.GroupSyncDelay);
  finally
    T.Free;
    M.Free;
    G2.Free;
    G.Free;
  end;
end;

procedure TDBGridKeySyncTests.KeyedGroupingUsesNoBookmarks;
var
  G: TPPGDBGrid;
  Plain: Integer;
begin
  // Gegenprobe ohne KeyFieldNames: Lesen und Navigation nutzen Lesezeichen
  FillCounted(30);
  G := NewGrid(['ID', 'Name', 'OrtID'], '');
  FCnt.ResetCounts;
  Column(G, 'OrtID').GroupIndex := 0;
  Key(G, VK_DOWN);
  Key(G, VK_DOWN);
  Plain := FCnt.BookmarkCalls;
  CheckTrue(Plain >= 30, 'ohne Schluessel: Lesezeichen je Satz (Zaehler arbeitet)');
  G.Free;
  // Mit KeyFieldNames: weder beim Lesen noch beim Navigieren, Bearbeiten,
  // Neulesen und Suchen ein Lesezeichen
  FillCounted(30);
  G := NewGrid(['ID', 'Name', 'OrtID'], 'ID');
  FCnt.ResetCounts;
  Column(G, 'OrtID').GroupIndex := 0;
  CheckTrue(G.GroupedView);
  CheckEquals(TDBGridAccess(G).FixedRows + 30, TDBGridAccess(G).RowCount, 'alle Saetze');
  CheckEquals(1, CurID, 'Position nach dem Lesen wie vorher');
  CheckEquals(1, FocusedID(G));
  // Gruppe '2': 1, 4, 7 ...
  Key(G, VK_DOWN);
  CheckEquals(4, FocusedID(G));
  CheckEquals(4, CurID, 'Datenmenge folgt per Locate');
  Key(G, VK_DOWN);
  CheckEquals(7, CurID);
  Key(G, VK_UP);
  CheckEquals(4, CurID);
  Key(G, VK_END, [ssCtrl]);
  CheckEquals(29, CurID, 'letzter Satz der Ansicht');
  Key(G, VK_HOME, [ssCtrl]);
  Key(G, VK_DOWN);
  CheckEquals(3, CurID, 'erster Satz der Gruppe 1');
  G.Row := G.ActiveDataRow + 1;
  CheckEquals(4, CurID, 'Zeile per Code (Datenzeile = Satz der Datenmenge)');
  CheckTrue(G.LocateRecord('ID', 20, []));
  CheckEquals(20, FocusedID(G));
  // Bearbeiten: Post liest nur den Satz (Vergleich ueber den Schluessel)
  FCnt.Edit;
  FCnt.FieldByName('Name').AsString := 'Neu';
  FCnt.Post;
  CheckEquals('Neu', FocusedText(G, 'Name'));
  // Gruppenwert aendern: neu gruppiert, Fokus folgt
  FCnt.Edit;
  FCnt.FieldByName('OrtID').AsInteger := 1;
  FCnt.Post;
  CheckEquals(20, FocusedID(G));
  CheckEquals('1', G.ActiveGroupValues[0]);
  G.RefreshGroups;
  CheckEquals(20, CurID, 'Neulesen haelt den Satz');
  CheckEquals(20, FocusedID(G));
  CheckTrue(FFocusEvents > 0, 'OnFocusedRecordChanged ohne Lesezeichen');
  CheckEquals(0, FCnt.Gets, 'GetBookmark');
  CheckEquals(0, FCnt.Gotos, 'GotoBookmark');
  CheckEquals(0, FCnt.Valids, 'BookmarkValid');
  CheckEquals(0, FCnt.Compares, 'CompareBookmarks');
  CheckTrue(FCnt.Locates > 0, 'positioniert per Locate');
end;

procedure TDBGridKeySyncTests.TwoPartKeyLocatesAndKeepsAfterReload;
var
  G: TPPGDBGrid;
  Reads: Integer;
begin
  FillTwoPartKey;
  G := NewGrid(['Kunde', 'Nr', 'Gruppe', 'Text'], 'Kunde;Nr');
  FCnt.ResetCounts;
  Column(G, 'Gruppe').GroupIndex := 0;
  Reads := G.GroupReadCount;
  // Erster Satz (1, A) liegt in G1; dort folgen (1, C), (1, E), (2, B) ...
  CheckEquals('K1-A', FocusedText(G, 'Text'));
  Key(G, VK_DOWN);
  CheckEquals('K1-C', FocusedText(G, 'Text'));
  CheckEquals('K1-C', FCnt.FieldByName('Text').AsString, 'Locate mit beiden Feldern');
  Key(G, VK_DOWN);
  Key(G, VK_DOWN);
  CheckEquals('K2-B', FocusedText(G, 'Text'));
  CheckEquals(2, FCnt.FieldByName('Kunde').AsInteger);
  CheckEquals('B', FCnt.FieldByName('Nr').AsString, 'derselbe Kunde, anderes Nr waere falsch');
  // Neulesen (Aenderung von aussen ueber EnableControls): Satz bleibt
  FCnt.DisableControls;
  FCnt.EnableControls;
  CheckEquals(Reads + 1, G.GroupReadCount, 'neu gelesen');
  CheckEquals('K2-B', FCnt.FieldByName('Text').AsString);
  CheckEquals('K2-B', FocusedText(G, 'Text'));
  G.RefreshGroups;
  CheckEquals('K2-B', FocusedText(G, 'Text'));
  // Gruppe wechseln: Fokus folgt dem Satz
  FCnt.Edit;
  FCnt.FieldByName('Gruppe').AsString := 'G0';
  FCnt.Post;
  CheckEquals('G0', G.ActiveGroupValues[0]);
  CheckEquals('K2-B', FocusedText(G, 'Text'));
  Key(G, VK_DOWN);
  CheckEquals(FocusedText(G, 'Text'), FCnt.FieldByName('Text').AsString);
  CheckEquals(0, FCnt.BookmarkCalls, 'mehrteiliger Schluessel ohne Lesezeichen');
  // Schliessen und neu anlegen: Felder neu aufgeloest
  FillTwoPartKey;
  FCnt.ResetCounts;
  CheckTrue(G.GroupedView);
  CheckTrue(G.LocateRecord('Kunde;Nr', VarArrayOf([3, 'D']), []));
  CheckEquals('K3-D', FocusedText(G, 'Text'));
  Key(G, VK_UP);
  CheckEquals(FocusedText(G, 'Text'), FCnt.FieldByName('Text').AsString);
  CheckEquals(0, FCnt.BookmarkCalls, 'nach dem Neuanlegen ohne Lesezeichen');
end;

procedure TDBGridKeySyncTests.DeletedRecordIsNotReachable;
var
  G: TPPGDBGrid;
  Clone: TClientDataSet;
  Rows: Integer;
begin
  FillCounted(30);
  G := NewGrid(['ID', 'Name', 'OrtID'], 'ID');
  Column(G, 'OrtID').GroupIndex := 0;
  Rows := TDBGridAccess(G).RowCount;
  // Satz 4 ist in der Datenbank geloescht (z.B. von einem anderen Anwender):
  // Locate findet ihn nicht mehr, das Grid hat ihn noch im Speicher
  FCnt.LostID := 4;
  FCnt.ResetCounts;
  CheckEquals(1, CurID);
  Key(G, VK_DOWN);
  CheckEquals(1, CurID, 'geloeschter Satz: Datenmenge bleibt');
  CheckEquals(1, FocusedID(G), 'Fokus bleibt beim aktiven Satz');
  // Sammelphase, die auf dem geloeschten Satz endet: Fokus zurueck
  RepeatKey(G, VK_DOWN, 1);
  CheckEquals(4, FocusedID(G));
  KeyUpMsg(G, VK_DOWN);
  CheckEquals(1, CurID);
  CheckEquals(1, FocusedID(G), 'nach dem Nachziehen auf dem aktiven Satz');
  CheckFalse(G.RecordSyncPending);
  // Ueber den Satz hinweg geht es weiter
  RepeatKey(G, VK_DOWN, 2);
  KeyUpMsg(G, VK_DOWN);
  CheckEquals(7, CurID);
  CheckEquals(7, FocusedID(G));
  CheckEquals(0, FCnt.BookmarkCalls);
  // Loeschen ueber die Datenmenge: neu gelesen, Fokus auf dem Nachbarn
  FCnt.LostID := 0;
  CheckTrue(G.LocateRecord('ID', 4, []));
  FCnt.Delete;
  CheckEquals(Rows - 1, TDBGridAccess(G).RowCount, 'Zeile entfernt');
  CheckEquals(CurID, FocusedID(G));
  Key(G, VK_DOWN);
  CheckEquals(FocusedID(G), CurID);
  // Loeschen ueber einen zweiten Zeiger auf dieselben Daten: das Grid bleibt
  // mit der Datenmenge im Einklang
  Clone := TClientDataSet.Create(FForm);
  Clone.CloneCursor(FCnt, False);
  CheckTrue(Clone.Locate('ID', 13, []));
  Clone.Delete;
  Clone.Free;
  CheckTrue(G.LocateRecord('ID', 10, []));
  Key(G, VK_DOWN);
  CheckEquals(FocusedID(G), CurID);
  Key(G, VK_DOWN);
  CheckEquals(FocusedID(G), CurID);
  G.RefreshGroups;
  CheckEquals(Rows - 2, TDBGridAccess(G).RowCount, 'nach Neulesen ohne den Satz');
  CheckEquals(FocusedID(G), CurID);
end;

procedure TDBGridKeySyncTests.KeyedMultiSelectInViewOrder;
var
  G: TPPGDBGrid;
  Vals: TArray<Variant>;
  Reads: Integer;
begin
  FillCounted(30);
  G := NewGrid(['ID', 'Name', 'OrtID'], 'ID');
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
  CheckEquals(9, Integer(Vals[2]));
  CheckTrue(TDBGridAccess(G).RowMarked(G.Row), 'Markierung ueber den Schluessel');
  CheckFalse(TDBGridAccess(G).RowMarked(G.Row + 1), '12 nicht gewaehlt');
  // Bereich bis zum Ende der Ansicht: Lesezeichen in einem Durchlauf
  Key(G, VK_END, [ssCtrl, ssShift]);
  CheckEquals(29, CurID);
  CheckEquals(30, G.SelectedCount, 'von 3 bis zum Ende der Ansicht = alle');
  CheckTrue(TDBGridAccess(G).RowMarked(TDBGridAccess(G).FixedRows), 'erste Zeile markiert');
  Key(G, VK_DOWN, []);
  CheckEquals(0, G.SelectedCount, 'Bewegen ohne Umschalt hebt auf');
  Key(G, Ord('A'), [ssCtrl]);
  CheckEquals(30, G.SelectedCount);
  // Neulesen: Markierung bleibt (Schluessel der Lesezeichen gemerkt)
  G.RefreshGroups;
  CheckTrue(TDBGridAccess(G).RowMarked(G.Row), 'nach Neulesen markiert');
  G.SelectedRows.Clear;
  // Satzwechsel der Anwendung, dann waehlen: Schluessel wird gemerkt
  FCnt.Locate('ID', 10, []);
  G.SelectedRows.CurrentRowSelected := True;
  CheckEquals(1, G.SelectedCount);
  CheckTrue(TDBGridAccess(G).RowMarked(G.Row), 'Satz der Anwendung markiert');
  G.SelectedRows.Clear;
  CheckTrue(G.LocateRecord('ID', 4, []));
  Key(G, VK_DOWN, [ssShift]);
  CheckEquals(2, G.SelectedCount);
  G.SelectedRows.Delete;
  CheckEquals(28, FCnt.RecordCount);
  CheckEquals(TDBGridAccess(G).FixedRows + 28, TDBGridAccess(G).RowCount, 'neu gelesen');
  CheckTrue(G.GroupReadCount > Reads);
end;

procedure TDBGridKeySyncTests.SingleStepMovesAtOnce;
var
  G: TPPGDBGrid;
begin
  FillCounted(90);
  G := NewGrid(['ID', 'Name', 'OrtID'], 'ID');
  Column(G, 'OrtID').GroupIndex := 0;
  FCnt.ResetCounts;
  FFocusEvents := 0;
  // Ein Tastendruck (ohne Wiederholungsbit): sofort, wie bisher
  G.Perform(WM_KEYDOWN, VK_DOWN, 1);
  CheckEquals(4, FocusedID(G));
  CheckEquals(4, CurID, 'Einzelschritt bewegt sofort');
  CheckEquals(1, FCnt.Scrolls);
  CheckEquals(1, FFocusEvents, 'OnFocusedRecordChanged sofort');
  CheckFalse(G.RecordSyncPending);
  KeyUpMsg(G, VK_DOWN);
  CheckEquals(1, FCnt.Scrolls, 'Loslassen ohne Sammelphase: nichts');
  G.Perform(WM_KEYDOWN, VK_NEXT, 1);
  CheckEquals(FocusedID(G), CurID, 'Bild ab sofort');
  CheckEquals(2, FCnt.Scrolls);
end;

procedure TDBGridKeySyncTests.RepeatedKeysMoveDataSetOnce;
var
  G: TPPGDBGrid;
  Target: Integer;
begin
  FillCounted(90);
  G := NewGrid(['ID', 'Name', 'OrtID'], 'ID');
  Column(G, 'OrtID').GroupIndex := 0;
  G.Perform(WM_KEYDOWN, VK_DOWN, 1);
  CheckEquals(4, CurID);
  FCnt.ResetCounts;
  FFocusEvents := 0;
  // Taste gehalten: 20 Wiederholungen bewegen nur den Fokus
  RepeatKey(G, VK_DOWN, 20);
  Target := 4 + 20 * 3;
  CheckEquals(Target, FocusedID(G), 'Fokus wandert mit');
  CheckEquals(0, FCnt.Scrolls, 'Datenmenge noch nicht bewegt');
  CheckEquals(4, CurID);
  CheckTrue(G.RecordSyncPending);
  CheckEquals(0, FFocusEvents, 'noch kein Satzwechsel');
  // Loslassen: einmal nachziehen
  KeyUpMsg(G, VK_DOWN);
  CheckFalse(G.RecordSyncPending);
  CheckEquals(1, FCnt.Scrolls, 'genau ein Satzwechsel');
  CheckEquals(Target, CurID, 'auf dem fokussierten Satz');
  CheckEquals(1, FFocusEvents, 'ein OnFocusedRecordChanged');
  CheckEquals(0, FCnt.BookmarkCalls, 'mit Schluesseln ohne Lesezeichen');
  // Bild auf gehalten (auch ohne Schluesselfelder: per Lesezeichen)
  G.KeyFieldNames := '';
  FCnt.ResetCounts;
  RepeatKey(G, VK_PRIOR, 3);
  CheckEquals(0, FCnt.Scrolls);
  CheckTrue(FocusedID(G) < Target);
  // Eine andere Taste zieht vorher nach (OnKeyDown sieht den Satz)
  G.Perform(WM_KEYDOWN, VK_RIGHT, 1);
  CheckFalse(G.RecordSyncPending);
  CheckEquals(1, FCnt.Scrolls);
  CheckEquals(FocusedID(G), CurID);
end;

procedure TDBGridKeySyncTests.RepeatedKeysFollowAfterDelay;
var
  G: TPPGDBGrid;
  T0: Cardinal;
begin
  FillCounted(90);
  G := NewGrid(['ID', 'Name', 'OrtID'], 'ID');
  Column(G, 'OrtID').GroupIndex := 0;
  G.GroupSyncDelay := 50;
  FCnt.ResetCounts;
  RepeatKey(G, VK_DOWN, 5);
  CheckTrue(G.RecordSyncPending);
  CheckEquals(0, FCnt.Scrolls);
  // Ohne Loslassen (WM_KEYUP fehlt): die Wartezeit zieht nach
  T0 := GetTickCount;
  while G.RecordSyncPending and (GetTickCount - T0 < 3000) do
  begin
    Application.ProcessMessages;
    Sleep(5);
  end;
  CheckFalse(G.RecordSyncPending, 'nach der Wartezeit nachgezogen');
  CheckEquals(1, FCnt.Scrolls);
  CheckEquals(1 + 5 * 3, CurID);
  CheckEquals(CurID, FocusedID(G));
end;

procedure TDBGridKeySyncTests.WheelSeriesDoesNotMoveDataSet;
var
  G: TPPGDBGrid;
  I, Y0: Integer;
begin
  FillCounted(90);
  G := NewGrid(['ID', 'Name', 'OrtID'], 'ID');
  Column(G, 'OrtID').GroupIndex := 0;
  FCnt.ResetCounts;
  Y0 := TDBGridAccess(G).ScrollY;
  // Gruppiert scrollt das Rad nur die Ansicht (Zeilen aus dem Speicher)
  for I := 1 to 10 do
    TDBGridAccess(G).DoMouseWheel([], -WHEEL_DELTA, Point(10, 10));
  CheckTrue(TDBGridAccess(G).ScrollY > Y0, 'Ansicht gescrollt');
  CheckEquals(0, FCnt.Scrolls, 'Datenmenge nicht bewegt');
  CheckEquals(1, CurID);
  CheckEquals(1, FocusedID(G));
  CheckEquals(0, FCnt.BookmarkCalls + FCnt.Locates);
end;

procedure TDBGridKeySyncTests.AccessAfterFastNavigationHitsFocusedRecord;
var
  G: TPPGDBGrid;
  Vals: TArray<Variant>;
  Want: Integer;
begin
  FillCounted(90);
  G := NewGrid(['ID', 'Name', 'OrtID'], 'ID');
  Column(G, 'OrtID').GroupIndex := 0;
  // Zellwert schreiben (Kaestchen, Tippen) trifft den fokussierten Satz
  RepeatKey(G, VK_DOWN, 6);
  Want := FocusedID(G);
  CheckEquals(1 + 6 * 3, Want);
  TDBGridAccess(G).SetCellByUser(ColOf(G, 'Name'), G.Row, 'Geaendert');
  CheckTrue(FCnt.State = dsEdit);
  CheckEquals(Want, CurID, 'bearbeitet wird der fokussierte Satz');
  FCnt.Post;
  CheckEquals('Geaendert', FocusedText(G, 'Name'));
  CheckTrue(FCnt.Locate('ID', Want, []));
  CheckEquals('Geaendert', FCnt.FieldByName('Name').AsString);
  CheckTrue(G.LocateRecord('ID', Want, []));
  // Editor oeffnen (ohne sichtbares Formular: der Schritt vor dem Editor)
  RepeatKey(G, VK_DOWN, 2);
  CheckTrue(G.RecordSyncPending);
  TDBGridAccess(G).EditorPrepare(ColOf(G, 'Name'), G.Row);
  CheckFalse(G.RecordSyncPending);
  CheckEquals(FocusedID(G), CurID, 'Editor auf dem fokussierten Satz');
  // RowValue fuer den aktiven Satz
  RepeatKey(G, VK_DOWN, 2);
  CheckEquals(FocusedID(G), Integer(G.RowValue('ID')));
  // Fokusverlust
  RepeatKey(G, VK_UP, 3);
  G.Perform(CM_EXIT, 0, 0);
  CheckFalse(G.RecordSyncPending);
  CheckEquals(FocusedID(G), CurID, 'Fokusverlust');
  // Mehrfachauswahl: SelectedRows nimmt den fokussierten Satz
  G.Options := G.Options + [dgMultiSelect];
  RepeatKey(G, VK_DOWN, 4);
  G.SelectedRows.CurrentRowSelected := True;
  Vals := G.SelectedValues('ID');
  CheckEquals(1, Length(Vals));
  CheckEquals(FocusedID(G), Integer(Vals[0]));
  // Freigabe: die Datenmenge bleibt auf dem zuletzt fokussierten Satz
  RepeatKey(G, VK_DOWN, 3);
  Want := FocusedID(G);
  CheckTrue(G.RecordSyncPending);
  G.Free;
  CheckEquals(Want, CurID, 'beim Freigeben nachgezogen');
end;

procedure TDBGridKeySyncTests.OutsideMoveWinsAndDelayZero;
var
  G: TPPGDBGrid;
begin
  FillCounted(90);
  G := NewGrid(['ID', 'Name', 'OrtID'], 'ID');
  Column(G, 'OrtID').GroupIndex := 0;
  // Satzwechsel von aussen waehrend der Sammelphase: Fokus folgt ihm
  RepeatKey(G, VK_DOWN, 5);
  CheckTrue(G.RecordSyncPending);
  FCnt.Next;
  CheckFalse(G.RecordSyncPending, 'verworfen');
  CheckEquals(2, CurID);
  CheckEquals(2, FocusedID(G), 'Fokus auf dem Satz der Datenmenge');
  // LocateRecord ersetzt das Nachziehen
  RepeatKey(G, VK_DOWN, 3);
  CheckTrue(G.LocateRecord('ID', 30, []));
  CheckFalse(G.RecordSyncPending);
  CheckEquals(30, FocusedID(G));
  // SyncActiveRecord von Hand
  RepeatKey(G, VK_DOWN, 2);
  CheckTrue(G.SyncActiveRecord);
  CheckEquals(FocusedID(G), CurID);
  CheckFalse(G.SyncActiveRecord, 'nichts mehr offen');
  // GroupSyncDelay = 0: jede Wiederholung sofort
  G.GroupSyncDelay := 0;
  FCnt.ResetCounts;
  RepeatKey(G, VK_DOWN, 4);
  CheckFalse(G.RecordSyncPending);
  CheckEquals(4, FCnt.Scrolls, 'jeder Schritt sofort');
  CheckEquals(FocusedID(G), CurID);
end;

initialization
  RegisterTest('DBGridKeySync', TDBGridKeySyncTests.Suite);

end.
