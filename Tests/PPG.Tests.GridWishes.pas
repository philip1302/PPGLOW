unit PPG.Tests.GridWishes;

{ Tests fuer die Grid-Erweiterungen (Grid-Wuensche): Enter zur naechsten
  Zelle, Sortier-Anforderung und Sortierpfeil, Doppelklick auf eine Zelle,
  Zelltext und Kopfzeilen, Spalten ohne Spaltenauswahl, Gruppieren nach
  Datum, Filter nach Werteliste (auch im Kopfmenue), erweiterte Suche,
  Blaettern ueber die Ansicht (IPPGViewPosition), im DB-Grid ausserdem
  AllowEdit/AllowInsert/AllowDelete, Sortierpfeil aus IndexFieldNames,
  aktiver Satz, Kartenbreite und -flaeche sowie die Reihenfolge im
  Bearbeitungsformular. Mit Streaming und ungueltigen Werten.

  Daten: Zeichenketten im Grid bzw. ein TClientDataSet im Speicher
  (synthetische Werte). Formate fest deutsch (PPGTestGermanFormat). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.DateUtils, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids,
  Vcl.Menus, Vcl.DBGrids, Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Types, PPG.Exceptions, PPG.Controls.Base, PPG.Controls.Scroll, PPG.Lang, PPG.Consts,
  PPG.Grid, PPG.Grid.Columns, PPG.Grid.View, PPG.Grid.Edit, PPG.DB.Grid,
  PPG.Tests.Controls, PPG.Tests.Phase9c;

type
  /// Beobachter fuer IPPGViewPosition (zaehlt CM_PPGVIEWPOSITION).
  TViewObserver = class(TComponent)
  public
    Count: Integer;
    procedure CMViewPosition(var Message: TMessage); message CM_PPGVIEWPOSITION;
  end;

  TGridQueryTests = class(TControlTestCase)
  published
    procedure FindQuerySyntax;
    procedure FilterValueList;
    procedure DateGroupKeys;
  end;

  TGridWishesTests = class(TControlTestCase)
  private
    FRequests: TStringList;
    FSorted: Integer;
    FDbl: string;
    FMapDesc: Boolean;
    FRefuse: Boolean;
    function SampleGrid(WithColumns: Boolean = False): TPPGGrid;
    function Visible(G: TPPGGrid): string;
    procedure Key(G: TPPGGrid; VK: Word; Shift: TShiftState = []);
    procedure SortRequest(Sender: TObject; ACol: Integer; var Direction: TPPGGridSortDirection;
      var Accept: Boolean);
    procedure CountSorted(Sender: TObject);
    procedure CellDbl(Sender: TObject; ACol, ARow: Integer);
    procedure AddValue(Sender: TObject; ACol: Integer; Values: TStrings);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure DefaultsAndStreaming;
    procedure EnterMovesToNextCell;
    procedure SortRequestAndIndicator;
    procedure CellDblClickCellTextHeaderRows;
    procedure CustomizationHiddenColumns;
    procedure GroupsByDate;
    procedure FilterValuesAndHeaderMenu;
    procedure ExtendedFindInGrid;
    procedure ViewPositionAndObservers;
  end;

  TDBGridWishesTests = class(TDBTestCase)
  private
    FRequests: TStringList;
    FSorted: Integer;
    FDbl: string;
    FMapDesc: Boolean;
    function NewGrid(N: Integer; const Cols: array of string): TPPGDBGrid;
    function ColOf(G: TPPGDBGrid; const FieldName: string): Integer;
    function Column(G: TPPGDBGrid; const FieldName: string): TPPGDBGridColumn;
    function CurID: Integer;
    procedure Key(G: TPPGDBGrid; VK: Word; Shift: TShiftState = []);
    function RecordTotal: Integer;
    procedure SortRequest(Sender: TObject; ACol: Integer; var Direction: TPPGGridSortDirection;
      var Accept: Boolean);
    procedure CountSorted(Sender: TObject);
    procedure CellDbl(Sender: TObject; ACol, ARow: Integer);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure DefaultsRangeAndStreaming;
    procedure AllowEditInsertDelete;
    procedure EnterMovesToNextRecord;
    procedure SortRequestIndexAndActiveRow;
    procedure GroupsByDateField;
    procedure FilterValuesOverDataSet;
    procedure ExtendedFindOverDataSet;
    procedure ViewPositionOverDataSet;
    procedure CardsWidthAreaAndDblClick;
    procedure EditFormOrderAndNewRow;
  end;

implementation

type
  TGridAccess = class(TPPGGrid);
  TDBGridAccess = class(TPPGDBGrid);

procedure ForcePPI96(C: TControl);
begin
{$IF CompilerVersion >= 33.0}
  if C.CurrentPPI <> 96 then
    C.ScaleForPPI(96);
{$IFEND}
end;

function CenterOf(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

function MouseLParam(const P: TPoint): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(P.X)) or (Cardinal(Word(SmallInt(P.Y))) shl 16));
end;

function SubMenu(M: TPopupMenu; const Caption: string): TMenuItem;
var
  I: Integer;
begin
  for I := 0 to M.Items.Count - 1 do
    if M.Items[I].Caption = Caption then
      Exit(M.Items[I]);
  Result := nil;
end;

function Join(const A: TArray<string>): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(A) do
  begin
    if I > 0 then
      Result := Result + ',';
    Result := Result + A[I];
  end;
end;

{ TViewObserver }

procedure TViewObserver.CMViewPosition(var Message: TMessage);
begin
  Inc(Count);
end;

{ TGridQueryTests }

procedure TGridQueryTests.FindQuerySyntax;
var
  Q: TPPGFindQuery;
  P, L: Integer;
begin
  // Einfach: der ganze Text ist ein Begriff (auch mit Leerzeichen)
  Q.Parse('mutter klein', False);
  CheckEquals(1, Length(Q.Terms));
  CheckTrue(Q.RowMatches(['SCHRAUBE', 'MUTTER KLEIN']));
  CheckFalse(Q.RowMatches(['MUTTER', 'KLEIN']), 'nicht als zwei Begriffe');
  // Erweitert: Leerzeichen = oder, + muss, - darf nicht
  Q.Parse('mutter winkel', True);
  CheckEquals(2, Length(Q.Terms));
  CheckTrue(Q.RowMatches(['WINKEL']));
  CheckTrue(Q.RowMatches(['MUTTER']));
  CheckFalse(Q.RowMatches(['KABEL']));
  Q.Parse('mutter -klein', True);
  CheckTrue(Q.RowMatches(['MUTTER', '10']));
  CheckFalse(Q.RowMatches(['MUTTER KLEIN', '2']), 'Ausschluss gilt fuer die Zeile');
  CheckFalse(Q.RowMatches(['MUTTER', 'KLEIN']), 'auch in einer anderen Zelle');
  Q.Parse('+mutter +2', True);
  CheckTrue(Q.RowMatches(['MUTTER KLEIN', '2']));
  CheckFalse(Q.RowMatches(['MUTTER', '10']));
  CheckTrue(Q.CellHit('MUTTER KLEIN'));
  CheckFalse(Q.CellHit('T4'));
  // Nur Ausschluss: jede Zeile ohne den Begriff passt, jede Zelle zaehlt
  Q.Parse('-klein', True);
  CheckTrue(Q.RowMatches(['MUTTER']));
  CheckFalse(Q.RowMatches(['KLEIN']));
  CheckTrue(Q.CellHit('IRGENDWAS'));
  // Anfuehrungszeichen und Platzhalter
  Q.Parse('"mutter klein" kabel', True);
  CheckEquals(2, Length(Q.Terms));
  CheckEquals('MUTTER KLEIN', Q.Terms[0].Text);
  CheckFalse(Q.RowMatches(['MUTTER']));
  Q.Parse('sch%be', True);
  CheckTrue(Q.Terms[0].Wild);
  CheckTrue(Q.RowMatches(['SCHRAUBE']));
  CheckFalse(Q.RowMatches(['SCHALE']));
  Q.Parse('k_bel', True);
  CheckTrue(Q.RowMatches(['KABEL']));
  CheckFalse(Q.RowMatches(['KBEL']), '_ = genau ein Zeichen');
  CheckTrue(PPGWildContains('ABC', ''));
  CheckTrue(PPGWildContains('ABC', '%'));
  CheckTrue(PPGWildContains('ABC', 'B%'));
  CheckFalse(PPGWildContains('ABC', 'D%'));
  CheckFalse(PPGWildContains('', '_'));
  // Leer, nur Leerzeichen, offene Anfuehrungszeichen, nur Zeichen + / -
  Q.Parse('', True);
  CheckTrue(Q.Empty);
  CheckFalse(Q.RowMatches(['A']));
  Q.Parse('   ', True);
  CheckTrue(Q.Empty);
  Q.Parse('+ -', True);
  CheckTrue(Q.Empty, 'Zeichen ohne Begriff');
  Q.Parse('"offen', True);
  CheckEquals(1, Length(Q.Terms));
  CheckEquals('OFFEN', Q.Terms[0].Text);
  CheckFalse(Q.RowMatches([]), 'Zeile ohne Zellen');
  // Markierung: erster Begriff ohne - und ohne Platzhalter
  Q.Parse('klein mutter -t', True);
  CheckTrue(Q.MarkAt('MUTTER KLEIN', P, L));
  CheckEquals(1, P);
  CheckEquals(6, L);
  Q.Parse('sch%be', True);
  CheckFalse(Q.MarkAt('SCHRAUBE', P, L), 'Platzhalter: keine Markierung');
end;

procedure TGridQueryTests.FilterValueList;
var
  C: TPPGFilterCondition;
begin
  CheckEquals('', PPGFilterListText([]), 'leere Liste = kein Filter');
  CheckEquals('=a|b|', PPGFilterListText(['a', ' b ']));
  CheckEquals('=a|b|', PPGFilterText(pfoInList, 'a|b'));
  C := PPGFilterParse('=Mutter|Kabel|');
  CheckTrue(C.Op = pfoInList);
  CheckTrue(C.Active);
  CheckEquals('Mutter|Kabel', C.Value);
  CheckTrue(C.MatchText('mutter'), 'ohne Gross-/Kleinschreibung');
  CheckTrue(C.MatchText(' Kabel '));
  CheckFalse(C.MatchText('Mutter klein'), 'ganzer Wert, kein Teiltext');
  CheckFalse(C.MatchNull);
  C := PPGFilterParse('=|x|');
  CheckTrue(C.Op = pfoInList);
  CheckTrue(C.MatchNull, 'leerer Eintrag = leer');
  CheckTrue(C.MatchText(''));
  CheckTrue(C.MatchText('X'));
  // Ohne "|" bleibt "=" der Vergleich
  C := PPGFilterParse('=5');
  CheckTrue(C.Op = pfoEqual);
  C := PPGFilterParse('=|');
  CheckTrue(C.Op = pfoInList, 'nur der leere Wert');
  CheckTrue(C.MatchNull);
  CheckFalse(C.MatchText('a'));
end;

procedure TGridQueryTests.DateGroupKeys;
var
  T: TDateTime;
begin
  FormatSettings := PPGTestGermanFormat;
  // Mittwoch, 14.10.2026 (Montag der Woche: 12.10.)
  T := EncodeDate(2026, 10, 14);
  CheckEquals(PPGStr(@SPPGGridDateToday), PPGGridDateGroupKey(T + 0.5, gdmRelative, T));
  CheckEquals(PPGStr(@SPPGGridDateYesterday), PPGGridDateGroupKey(T - 1, gdmRelative, T));
  CheckEquals(PPGStr(@SPPGGridDateTomorrow), PPGGridDateGroupKey(T + 1, gdmRelative, T));
  CheckEquals(PPGStr(@SPPGGridDateEarlierThisWeek), PPGGridDateGroupKey(T - 2, gdmRelative, T));
  CheckEquals(PPGStr(@SPPGGridDateLaterThisWeek), PPGGridDateGroupKey(T + 2, gdmRelative, T));
  CheckEquals(PPGStr(@SPPGGridDateLaterThisWeek), PPGGridDateGroupKey(T + 4, gdmRelative, T),
    'Sonntag');
  CheckEquals(PPGStr(@SPPGGridDateNextWeek), PPGGridDateGroupKey(T + 5, gdmRelative, T));
  CheckEquals(PPGStr(@SPPGGridDateNextWeek), PPGGridDateGroupKey(T + 11, gdmRelative, T));
  CheckEquals(PPGStr(@SPPGGridDateLater), PPGGridDateGroupKey(T + 12, gdmRelative, T));
  CheckEquals(PPGStr(@SPPGGridDateLastWeek), PPGGridDateGroupKey(T - 3, gdmRelative, T));
  CheckEquals(PPGStr(@SPPGGridDateLastWeek), PPGGridDateGroupKey(T - 9, gdmRelative, T));
  CheckEquals(PPGStr(@SPPGGridDateOlder), PPGGridDateGroupKey(T - 10, gdmRelative, T));
  // Montag: gestern liegt in der Vorwoche und heisst trotzdem "Gestern"
  T := EncodeDate(2026, 10, 12);
  CheckEquals(PPGStr(@SPPGGridDateYesterday), PPGGridDateGroupKey(T - 1, gdmRelative, T));
  CheckEquals(PPGStr(@SPPGGridDateLastWeek), PPGGridDateGroupKey(T - 2, gdmRelative, T));
  // Kalenderwoche nach ISO (31.12.2024 gehoert zur KW 1 2025)
  CheckEquals(Format(PPGStr(@SPPGGridDateWeek), [1, 2025]),
    PPGGridDateGroupKey(EncodeDate(2024, 12, 31), gdmWeek, T));
  CheckEquals(Format(PPGStr(@SPPGGridDateWeek), [42, 2026]),
    PPGGridDateGroupKey(EncodeDate(2026, 10, 14), gdmWeek, T));
  CheckEquals(Format(PPGStr(@SPPGGridDateQuarter), [2, 2026]),
    PPGGridDateGroupKey(EncodeDate(2026, 5, 15), gdmQuarter, T));
  CheckEquals(Format(PPGStr(@SPPGGridDateQuarter), [4, 2026]),
    PPGGridDateGroupKey(EncodeDate(2026, 12, 31), gdmQuarter, T));
  CheckEquals('2026', PPGGridDateGroupKey(EncodeDate(2026, 5, 15), gdmYear, T));
  CheckEquals(FormatDateTime('mmmm yyyy', EncodeDate(2026, 5, 1)),
    PPGGridDateGroupKey(EncodeDate(2026, 5, 15), gdmMonth, T));
  CheckEquals('15.05.2026', PPGGridDateGroupKey(EncodeDateTime(2026, 5, 15, 13, 0, 0, 0),
    gdmDay, T), 'Tag ohne Uhrzeit');
end;

{ TGridWishesTests }

procedure TGridWishesTests.SetUp;
begin
  inherited SetUp;
  FRequests := TStringList.Create;
  FSorted := 0;
  FDbl := '';
  FMapDesc := False;
  FRefuse := False;
end;

procedure TGridWishesTests.TearDown;
begin
  FreeAndNil(FRequests);
  inherited TearDown;
end;

function TGridWishesTests.SampleGrid(WithColumns: Boolean): TPPGGrid;
const
  Names: array[1..6] of string = ('Mutter', 'Schraube', 'Duebel', 'Mutter klein', 'Winkel', 'Kabel');
  Nums: array[1..6] of string = ('10', '2', '33', '2', '100', '7');
var
  I: Integer;
begin
  FormatSettings := PPGTestGermanFormat;
  Result := TPPGGrid.Create(FForm);
  Result.Parent := FForm;
  ForcePPI96(Result);
  Result.SetBounds(10, 10, 360, 240);
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.HandleNeeded;
  Result.FixedCols := 0;
  Result.ColCount := 3;
  // Spalten-Objekte (Gruppieren, Spaltenauswahl) vor den Zellen
  if WithColumns then
  begin
    Result.Columns.Add.Title := 'Name';
    Result.Columns.Add.Title := 'Zahl';
    Result.Columns.Add.Title := 'Text';
  end;
  Result.RowCount := 7;
  Result.Cells[0, 0] := 'Name';
  Result.Cells[1, 0] := 'Zahl';
  Result.Cells[2, 0] := 'Text';
  for I := 1 to 6 do
  begin
    Result.Cells[0, I] := Names[I];
    Result.Cells[1, I] := Nums[I];
    Result.Cells[2, I] := 'T' + IntToStr(I);
  end;
end;

function TGridWishesTests.Visible(G: TPPGGrid): string;
var
  V, D: Integer;
begin
  Result := '';
  for V := TGridAccess(G).VFixedRows to TGridAccess(G).VRowCount - 1 do
  begin
    D := G.DataRow(V);
    if D < 1 then
      Continue;
    if Result <> '' then
      Result := Result + ',';
    Result := Result + G.Cells[0, D];
  end;
end;

procedure TGridWishesTests.Key(G: TPPGGrid; VK: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := VK;
  TGridAccess(G).KeyDown(K, Shift);
end;

procedure TGridWishesTests.SortRequest(Sender: TObject; ACol: Integer;
  var Direction: TPPGGridSortDirection; var Accept: Boolean);
begin
  FRequests.Add(IntToStr(ACol) + ':' + IntToStr(Ord(Direction)));
  if FMapDesc and (Direction = gsdDescending) then
    Direction := gsdNone;
  if FRefuse then
    Accept := False;
end;

procedure TGridWishesTests.CountSorted(Sender: TObject);
begin
  Inc(FSorted);
end;

procedure TGridWishesTests.CellDbl(Sender: TObject; ACol, ARow: Integer);
begin
  FDbl := IntToStr(ACol) + ',' + IntToStr(ARow);
end;

procedure TGridWishesTests.AddValue(Sender: TObject; ACol: Integer; Values: TStrings);
begin
  Values.Add('Extra');
end;

procedure TGridWishesTests.DefaultsAndStreaming;
var
  G, G2: TPPGGrid;
  C, C2: TPPGGridColumn;
  M: TMemoryStream;
  T: TStringStream;
begin
  G := TPPGGrid.Create(nil);
  G2 := TPPGGrid.Create(nil);
  M := TMemoryStream.Create;
  T := TStringStream.Create('');
  try
    CheckFalse(G.EnterMovesNext);
    CheckFalse(G.FindExtendedSyntax);
    CheckFalse(G.FilterValueMenu);
    CheckFalse(Assigned(G.OnCellDblClick));
    CheckEquals(1, G.HeaderRowCount);
    CheckEquals('', G.CellText(-1, 0), 'ausserhalb');
    CheckEquals('', G.CellText(0, 99));
    CheckEquals(0, Length(G.FilterValues(-1)));
    CheckEquals(0, Length(G.FilterValues(99)));
    CheckEquals(0, Length(G.ColumnFilterValues(-1)));
    CheckEquals(0, Length(G.ColumnFilterValues(0, 0)), 'MaxCount 0');
    C := G.Columns.Add;
    CheckTrue(C.VisibleForCustomization);
    CheckTrue(C.GroupDateMode = gdmValue);
    M.WriteComponent(G);
    M.Position := 0;
    ObjectBinaryToText(M, T);
    CheckEquals(0, Pos('EnterMovesNext', T.DataString), 'Vorgabe nicht gespeichert');
    CheckEquals(0, Pos('FindExtendedSyntax', T.DataString));
    CheckEquals(0, Pos('FilterValueMenu', T.DataString));
    CheckEquals(0, Pos('VisibleForCustomization', T.DataString));
    CheckEquals(0, Pos('GroupDateMode', T.DataString));
    G.EnterMovesNext := True;
    G.FindExtendedSyntax := True;
    G.FilterValueMenu := True;
    C.VisibleForCustomization := False;
    C.GroupDateMode := gdmQuarter;
    M.Clear;
    M.WriteComponent(G);
    M.Position := 0;
    M.ReadComponent(G2);
    CheckTrue(G2.EnterMovesNext);
    CheckTrue(G2.FindExtendedSyntax);
    CheckTrue(G2.FilterValueMenu);
    CheckFalse(G2.Columns[0].VisibleForCustomization);
    CheckTrue(G2.Columns[0].GroupDateMode = gdmQuarter);
    // Assign uebernimmt die neuen Spalten-Properties
    C2 := G2.Columns.Add;
    C2.Assign(C);
    CheckFalse(C2.VisibleForCustomization);
    CheckTrue(C2.GroupDateMode = gdmQuarter);
  finally
    T.Free;
    M.Free;
    G2.Free;
    G.Free;
  end;
end;

procedure TGridWishesTests.EnterMovesToNextCell;
var
  G: TPPGGrid;
begin
  FForm.Show;
  try
    G := SampleGrid(True);
    G.Options := G.Options + [goEditing];
    G.SetFocus;
    G.Row := 1;
    G.Col := 0;
    // Ohne EnterMovesNext oeffnet Enter den Editor
    Key(G, VK_RETURN);
    CheckTrue(G.EditorMode);
    G.HideEditor(False);
    G.EnterMovesNext := True;
    Key(G, VK_RETURN);
    CheckFalse(G.EditorMode, 'Enter oeffnet keinen Editor mehr');
    CheckEquals(1, G.Col, 'naechste Spalte');
    CheckEquals(1, G.Row);
    G.Col := 2;
    Key(G, VK_RETURN);
    CheckEquals(0, G.Col, 'Zeilenende: erste Spalte');
    CheckEquals(2, G.Row, 'naechste Zeile');
    // Im Editor: uebernehmen, dann weiter
    Key(G, VK_F2);
    CheckTrue(G.EditorMode, 'F2 bearbeitet weiter');
    TPPGGridEdit(G.InplaceEditor).Text := 'Bolzen';
    G.InplaceEditor.Perform(WM_KEYDOWN, VK_RETURN, 0);
    CheckFalse(G.EditorMode);
    CheckEquals('Bolzen', G.Cells[0, 2]);
    CheckEquals(1, G.Col);
    // Letzte Zelle: der Fokus bleibt
    G.Row := 6;
    G.Col := 2;
    Key(G, VK_RETURN);
    CheckEquals(6, G.Row);
    CheckEquals(2, G.Col);
    // Gruppiert: Gruppenzeilen werden uebersprungen
    G.GroupBy([1]);
    G.FullExpand;
    G.Row := 2; // Zahl 2, erste Gruppe
    G.Col := 2;
    Key(G, VK_RETURN);
    CheckTrue(G.IsDataRow(G.FocusRow), 'auf einer Datenzeile');
    CheckEquals(0, G.Col);
  finally
    FForm.Hide;
  end;
end;

procedure TGridWishesTests.SortRequestAndIndicator;
var
  G: TPPGGrid;
  M: TPopupMenu;
begin
  G := SampleGrid;
  G.OnSorted := CountSorted;
  G.OnSortRequest := SortRequest;
  TGridAccess(G).HeaderClicked(1, 0);
  CheckEquals('1:1', FRequests[0], 'aufsteigend angefragt');
  CheckEquals(1, G.SortColumn);
  CheckTrue(G.SortAscending);
  CheckEquals(1, FSorted);
  FMapDesc := True;
  TGridAccess(G).HeaderClicked(1, 0);
  CheckEquals('1:2', FRequests[1], 'absteigend angefragt');
  CheckEquals(-1, G.SortColumn, 'absteigend -> keine Sortierung');
  FMapDesc := False;
  FRefuse := True;
  TGridAccess(G).HeaderClicked(0, 0);
  CheckEquals(-1, G.SortColumn, 'abgelehnt');
  CheckEquals(2, FSorted);
  FRefuse := False;
  // Kopfmenue geht denselben Weg
  M := G.CreateHeaderMenu(0);
  try
    CheckTrue(M.Items[1].Enabled, 'sortierbar');
    M.Items[1].Click;
  finally
    M.Free;
  end;
  CheckEquals('0:2', FRequests[FRequests.Count - 1]);
  CheckEquals(0, G.SortColumn);
  CheckFalse(G.SortAscending);
  CheckEquals('Winkel', G.Cells[0, G.DataRow(TGridAccess(G).VFixedRows)]);
  M := G.CreateHeaderMenu(0);
  try
    M.Items[2].Click; // Sortierung entfernen
  finally
    M.Free;
  end;
  CheckEquals('0:0', FRequests[FRequests.Count - 1], 'bisherige Spalte, keine Richtung');
  CheckEquals(-1, G.SortColumn);
  // Sortierpfeil per Code: ohne OnSorted, die Ansicht folgt
  FSorted := 0;
  G.SetSortIndicator(1, False);
  CheckEquals(0, FSorted, 'kein OnSorted');
  CheckEquals(1, G.SortColumn);
  CheckFalse(G.SortAscending);
  CheckEquals('100', G.Cells[1, G.DataRow(TGridAccess(G).VFixedRows)]);
  G.SetSortIndicator(99);
  CheckEquals(-1, G.SortColumn, 'ungueltige Spalte = keine');
  G.SetSortIndicator(-5);
  CheckEquals(-1, G.SortColumn);
end;

procedure TGridWishesTests.CellDblClickCellTextHeaderRows;
var
  G: TPPGGrid;
  P: TPoint;
begin
  G := SampleGrid;
  G.OnCellDblClick := CellDbl;
  P := CenterOf(G.CellRect(1, 3));
  G.Perform(WM_LBUTTONDBLCLK, MK_LBUTTON, MouseLParam(P));
  G.Perform(WM_LBUTTONUP, 0, MouseLParam(P));
  CheckEquals('1,3', FDbl, 'Datenspalte, Datenzeile');
  FDbl := '';
  P := CenterOf(G.CellRect(1, 0));
  G.Perform(WM_LBUTTONDBLCLK, MK_LBUTTON, MouseLParam(P));
  G.Perform(WM_LBUTTONUP, 0, MouseLParam(P));
  CheckEquals('', FDbl, 'Kopf: kein Ereignis');
  // Sortiert: Datenzeile, nicht die sichtbare Zeile
  G.SortBy(0, True); // Duebel zuerst
  P := CenterOf(G.CellRect(0, 1));
  G.Perform(WM_LBUTTONDBLCLK, MK_LBUTTON, MouseLParam(P));
  G.Perform(WM_LBUTTONUP, 0, MouseLParam(P));
  CheckEquals('0,3', FDbl);
  // Zelltext und Kopfzeilen
  CheckEquals('Schraube', G.CellText(0, 2));
  CheckEquals('Name', G.CellText(0, 0));
  CheckEquals(1, G.HeaderRowCount);
  G.FixedRows := 2;
  CheckEquals(2, G.HeaderRowCount);
end;

procedure TGridWishesTests.CustomizationHiddenColumns;
var
  G: TPPGGrid;
  M: TPopupMenu;
  Sub: TMenuItem;
  I: Integer;
begin
  G := SampleGrid(True);
  G.Columns[2].VisibleForCustomization := False;
  M := G.CreateHeaderMenu(1);
  try
    Sub := SubMenu(M, PPGStr(@SPPGGridColumnChooser));
    CheckNotNull(Sub);
    CheckEquals(2 + 2, Sub.Count, 'nur zwei Spalten in der Auswahl');
    for I := 0 to Sub.Count - 1 do
      CheckNotEquals('Text', Sub[I].Caption);
  finally
    M.Free;
  end;
  M := G.CreateHeaderMenu(2);
  try
    for I := 0 to M.Items.Count - 1 do
      if M.Items[I].Caption = PPGStr(@SPPGGridHideColumn) then
      begin
        CheckFalse(M.Items[I].Enabled, 'nicht ausblendbar');
        M.Items[I].Click;
      end;
  finally
    M.Free;
  end;
  CheckTrue(G.Columns[2].Visible, 'bleibt sichtbar');
  // Ausgeblendet per Code: "Alle einblenden" laesst sie aus
  G.Columns[2].Visible := False;
  G.Columns[1].Visible := False;
  M := G.CreateHeaderMenu(0);
  try
    Sub := SubMenu(M, PPGStr(@SPPGGridColumnChooser));
    Sub[Sub.Count - 1].Click;
  finally
    M.Free;
  end;
  CheckTrue(G.Columns[1].Visible);
  CheckFalse(G.Columns[2].Visible, 'nicht zur Anpassung');
end;

procedure TGridWishesTests.GroupsByDate;
const
  Dates: array[1..6] of string = ('03.02.2026', '15.01.2026', '20.12.2025', '28.02.2026',
    '02.01.2026', 'kein Datum');
var
  G: TPPGGrid;
  I: Integer;
begin
  G := SampleGrid(True);
  for I := 1 to 6 do
    G.Cells[2, I] := Dates[I];
  G.Columns[2].GroupDateMode := gdmMonth;
  G.GroupBy([2]);
  // Dezember 2025, Januar, Februar, Text: nach dem Datum, nicht alphabetisch
  CheckEquals(4, G.GroupCount);
  CheckEquals(FormatDateTime('mmmm yyyy', EncodeDate(2025, 12, 1)), G.GroupInfo(0).Key);
  CheckEquals(FormatDateTime('mmmm yyyy', EncodeDate(2026, 1, 1)), G.GroupInfo(1).Key);
  CheckEquals(2, G.GroupInfo(1).Count);
  CheckEquals(FormatDateTime('mmmm yyyy', EncodeDate(2026, 2, 1)), G.GroupInfo(2).Key);
  CheckEquals(2, G.GroupInfo(2).Count);
  CheckEquals('kein Datum', G.GroupInfo(3).Key, 'kein Datum: nach dem Text');
  G.Columns[2].GroupDateMode := gdmYear;
  CheckEquals(3, G.GroupCount);
  CheckEquals('2025', G.GroupInfo(0).Key);
  CheckEquals('2026', G.GroupInfo(1).Key);
  CheckEquals(4, G.GroupInfo(1).Count);
  G.Columns[2].GroupDateMode := gdmValue;
  CheckEquals(6, G.GroupCount, 'nach dem Wert');
  // Relativ: heute und gestern
  G.Cells[2, 1] := DateToStr(Date);
  G.Cells[2, 2] := DateToStr(Date - 1);
  G.Columns[2].GroupDateMode := gdmRelative;
  CheckTrue(G.GroupCount >= 3);
  CheckEquals(PPGStr(@SPPGGridDateOlder), G.GroupInfo(0).Key, 'alt zuerst');
end;

procedure TGridWishesTests.FilterValuesAndHeaderMenu;
var
  G: TPPGGrid;
  M: TPopupMenu;
  Sub: TMenuItem;
  V: TArray<string>;
begin
  G := SampleGrid;
  G.SetFilterValues(0, ['Mutter', 'Kabel']);
  CheckEquals('=Mutter|Kabel|', G.Filters[0]);
  CheckEquals('Mutter,Kabel', Visible(G));
  V := G.FilterValues(0);
  CheckEquals('Mutter,Kabel', Join(V));
  CheckTrue(Pos('Mutter, Kabel', G.FilterDescription) > 0, G.FilterDescription);
  CheckEquals(0, Length(G.FilterValues(1)), 'kein Listenfilter');
  G.SetFilterValues(0, []);
  CheckEquals('', G.Filters[0], 'leer = aus');
  CheckEquals(6, Length(Visible(G).Split([','])));
  // Werte einer Spalte: verschieden, Zahlen nach Wert
  CheckEquals('2,7,10,33,100', Join(G.ColumnFilterValues(1)));
  CheckEquals('2,10', Join(G.ColumnFilterValues(1, 2)), 'hoechstens 2 (erste Fundstellen)');
  // Kopfmenue: Werte abhaken
  M := G.CreateHeaderMenu(0);
  try
    CheckNull(SubMenu(M, PPGStr(@SPPGGridFilterValues)), 'ohne FilterValueMenu');
  finally
    M.Free;
  end;
  G.FilterValueMenu := True;
  G.OnGetFilterValues := AddValue;
  M := G.CreateHeaderMenu(0);
  try
    Sub := SubMenu(M, PPGStr(@SPPGGridFilterValues));
    CheckNotNull(Sub);
    CheckEquals(1 + 6 + 1, Sub.Count, '(Alle), 6 Werte, Extra');
    CheckTrue(Sub[0].Checked, '(Alle) ohne Filter');
    CheckEquals('Duebel', Sub[1].Caption);
    CheckEquals('Extra', Sub[7].Caption);
    Sub[1].Click;
  finally
    M.Free;
  end;
  CheckEquals('Duebel', Visible(G));
  M := G.CreateHeaderMenu(0);
  try
    Sub := SubMenu(M, PPGStr(@SPPGGridFilterValues));
    CheckFalse(Sub[0].Checked);
    CheckTrue(Sub[1].Checked);
    Sub[6].Click; // Winkel dazu
  finally
    M.Free;
  end;
  CheckEquals('Duebel,Winkel', Visible(G));
  M := G.CreateHeaderMenu(0);
  try
    SubMenu(M, PPGStr(@SPPGGridFilterValues))[1].Click; // Duebel wieder weg
  finally
    M.Free;
  end;
  CheckEquals('Winkel', Visible(G));
  M := G.CreateHeaderMenu(0);
  try
    SubMenu(M, PPGStr(@SPPGGridFilterValues))[0].Click; // (Alle)
  finally
    M.Free;
  end;
  CheckEquals('', G.Filters[0]);
  // Leerer Wert erscheint als "(Leer)"
  G.Cells[2, 3] := '';
  M := G.CreateHeaderMenu(2);
  try
    Sub := SubMenu(M, PPGStr(@SPPGGridFilterValues));
    CheckEquals(PPGStr(@SPPGGridFilterEmptyValue), Sub[1].Caption);
    Sub[1].Click;
  finally
    M.Free;
  end;
  CheckEquals('Duebel', Visible(G), 'nur die leere Zelle');
end;

procedure TGridWishesTests.ExtendedFindInGrid;
var
  G: TPPGGrid;
  B: TBitmap;
begin
  G := SampleGrid;
  G.FindPanel := fpmAlways;
  G.FindText := 'mutter -klein';
  G.Row := 1;
  G.Col := 0;
  // Einfach: der ganze Text kommt nicht vor
  CheckFalse(G.FindNext);
  G.FindExtendedSyntax := True;
  CheckTrue(G.FindNext);
  CheckEquals(1, G.Row, 'nur "Mutter" (im Kreis)');
  G.FindText := 'winkel kabel';
  CheckTrue(G.FindNext);
  CheckEquals(5, G.Row);
  CheckTrue(G.FindNext);
  CheckEquals(6, G.Row);
  G.FindText := '+mutter +2';
  G.Row := 1;
  CheckTrue(G.FindNext);
  CheckEquals(4, G.Row, 'Mutter klein, Zahl 2');
  G.FindText := 'sch%be';
  G.Row := 1;
  CheckTrue(G.FindNext);
  CheckEquals(2, G.Row);
  B := RenderToBitmap(G);
  B.Free;
  G.FindText := '-mutter';
  G.Row := 1;
  CheckTrue(G.FindNext);
  CheckEquals(2, G.Row, 'erste Zeile ohne Mutter');
  G.FindText := '+zzz';
  CheckFalse(G.FindNext);
  // Umschalten liest den Text neu
  G.FindText := 'winkel kabel';
  G.FindExtendedSyntax := False;
  CheckFalse(G.FindNext);
end;

procedure TGridWishesTests.ViewPositionAndObservers;
var
  G: TPPGGrid;
  VP: IPPGViewPosition;
  O, O2: TViewObserver;
  N: Integer;
begin
  G := SampleGrid(True);
  CheckTrue(Supports(G, IPPGViewPosition, VP));
  CheckEquals(6, VP.ViewRecordCount);
  G.Row := 1;
  CheckEquals(1, VP.ViewRecordNo);
  CheckFalse(VP.ViewCanMove(pvmPrior));
  CheckFalse(VP.ViewCanMove(pvmFirst));
  CheckTrue(VP.ViewCanMove(pvmNext));
  O := TViewObserver.Create(nil);
  O2 := TViewObserver.Create(nil);
  try
    VP.ViewPositionObserver(O, True);
    VP.ViewPositionObserver(O, True); // doppelt: einmal
    VP.ViewPositionObserver(nil, True); // nil: nichts
    CheckTrue(VP.ViewMove(pvmNext));
    CheckEquals(2, VP.ViewRecordNo);
    CheckEquals(1, O.Count, 'einmal benachrichtigt');
    CheckTrue(VP.ViewMove(pvmLast));
    CheckEquals(6, VP.ViewRecordNo);
    CheckFalse(VP.ViewMove(pvmNext), 'am Ende');
    CheckTrue(VP.ViewMove(pvmFirst));
    CheckEquals(1, G.Row);
    // Filter aendert die Anzahl
    N := O.Count;
    G.Filters[0] := 'mutter';
    CheckEquals(2, VP.ViewRecordCount);
    CheckTrue(O.Count > N, 'Filter benachrichtigt');
    G.Filters[0] := '';
    // Gruppiert: zugeklappte Gruppen zaehlen nicht
    G.GroupBy([1]);
    CheckEquals(6, VP.ViewRecordCount);
    G.ExpandGroup(0, False); // Zahl 2: zwei Zeilen
    CheckEquals(4, VP.ViewRecordCount);
    VP.ViewMove(pvmFirst);
    CheckTrue(G.IsDataRow(G.FocusRow));
    CheckEquals(1, VP.ViewRecordNo);
    G.FullCollapse;
    CheckEquals(0, VP.ViewRecordCount);
    CheckEquals(0, VP.ViewRecordNo, 'Gruppenzeile');
    CheckFalse(VP.ViewMove(pvmNext));
    G.FullExpand;
    // Abmelden; ein freigegebener Beobachter wird entfernt
    VP.ViewPositionObserver(O, False);
    VP.ViewPositionObserver(O, False);
    N := O.Count;
    VP.ViewMove(pvmLast);
    CheckEquals(N, O.Count, 'abgemeldet');
    VP.ViewPositionObserver(O2, True);
    FreeAndNil(O2);
    VP.ViewMove(pvmFirst); // kein Zugriff auf den freigegebenen
  finally
    O2.Free;
    O.Free;
  end;
  VP := nil;
end;

{ TDBGridWishesTests }

procedure TDBGridWishesTests.SetUp;
begin
  inherited SetUp;
  FormatSettings := PPGTestGermanFormat;
  FRequests := TStringList.Create;
  FSorted := 0;
  FDbl := '';
  FMapDesc := False;
end;

procedure TDBGridWishesTests.TearDown;
begin
  FreeAndNil(FRequests);
  inherited TearDown;
end;

function TDBGridWishesTests.NewGrid(N: Integer; const Cols: array of string): TPPGDBGrid;
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

function TDBGridWishesTests.ColOf(G: TPPGDBGrid; const FieldName: string): Integer;
var
  I: Integer;
begin
  for I := 0 to G.FieldCount - 1 do
    if SameText(G.Fields[I].FieldName, FieldName) then
      Exit(TDBGridAccess(G).FixedCols + I);
  Result := -1;
end;

function TDBGridWishesTests.Column(G: TPPGDBGrid; const FieldName: string): TPPGDBGridColumn;
var
  I: Integer;
begin
  for I := 0 to G.Columns.Count - 1 do
    if SameText(TPPGDBGridColumn(G.Columns[I]).FieldName, FieldName) then
      Exit(TPPGDBGridColumn(G.Columns[I]));
  Result := nil;
end;

function TDBGridWishesTests.CurID: Integer;
begin
  if FData.State = dsInsert then
    Result := -1
  else
    Result := FData.FieldByName('ID').AsInteger;
end;

procedure TDBGridWishesTests.Key(G: TPPGDBGrid; VK: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := VK;
  TDBGridAccess(G).NavigateKey(K, Shift);
end;

function TDBGridWishesTests.RecordTotal: Integer;
var
  B: TBookmark;
begin
  Result := 0;
  B := FData.Bookmark;
  FData.DisableControls;
  try
    FData.First;
    while not FData.Eof do
    begin
      Inc(Result);
      FData.Next;
    end;
    FData.Bookmark := B;
  finally
    FData.EnableControls;
  end;
end;

procedure TDBGridWishesTests.SortRequest(Sender: TObject; ACol: Integer;
  var Direction: TPPGGridSortDirection; var Accept: Boolean);
begin
  FRequests.Add(IntToStr(ACol) + ':' + IntToStr(Ord(Direction)));
  if FMapDesc and (Direction = gsdDescending) then
    Direction := gsdNone;
end;

procedure TDBGridWishesTests.CountSorted(Sender: TObject);
begin
  Inc(FSorted);
end;

procedure TDBGridWishesTests.CellDbl(Sender: TObject; ACol, ARow: Integer);
begin
  FDbl := IntToStr(ACol) + ',' + IntToStr(ARow);
end;

procedure TDBGridWishesTests.DefaultsRangeAndStreaming;
var
  G, G2: TPPGDBGrid;
  C, C2: TPPGDBGridColumn;
  M: TMemoryStream;
  T: TStringStream;
begin
  G := TPPGDBGrid.Create(nil);
  G2 := TPPGDBGrid.Create(nil);
  M := TMemoryStream.Create;
  T := TStringStream.Create('');
  try
    CheckTrue(G.AllowEdit);
    CheckTrue(G.AllowInsert);
    CheckTrue(G.AllowDelete);
    CheckFalse(G.SortIndicatorFromIndex);
    CheckFalse(G.CardAutoWidth);
    CheckEquals(clDefault, G.CardAreaColor);
    CheckFalse(G.IsActiveRecordRow(1), 'ohne Datenmenge');
    CheckFalse(G.SyncSortIndicator);
    CheckEquals(0, Length(G.ColumnFilterValues(1)));
    C := TPPGDBGridColumn(G.Columns.Add);
    C.FieldName := 'Name';
    CheckEquals(-1, C.EditFormIndex);
    CheckFalse(C.EditFormNewRow);
    try
      C.EditFormIndex := -2;
      Fail('EditFormIndex -2');
    except
      on E: EPPGPropertyError do
        ;
    end;
    try
      C.EditFormIndex := 10000;
      Fail('EditFormIndex 10000');
    except
      on E: EPPGPropertyError do
        ;
    end;
    CheckEquals(-1, C.EditFormIndex, 'unveraendert');
    M.WriteComponent(G);
    M.Position := 0;
    ObjectBinaryToText(M, T);
    CheckEquals(0, Pos('AllowEdit', T.DataString), 'Vorgabe nicht gespeichert');
    CheckEquals(0, Pos('AllowInsert', T.DataString));
    CheckEquals(0, Pos('AllowDelete', T.DataString));
    CheckEquals(0, Pos('SortIndicatorFromIndex', T.DataString));
    CheckEquals(0, Pos('CardAutoWidth', T.DataString));
    CheckEquals(0, Pos('CardAreaColor', T.DataString));
    CheckEquals(0, Pos('EditFormIndex', T.DataString));
    CheckEquals(0, Pos('EditFormNewRow', T.DataString));
    G.AllowEdit := False;
    G.AllowInsert := False;
    G.AllowDelete := False;
    G.SortIndicatorFromIndex := True;
    G.CardAutoWidth := True;
    G.CardAreaColor := clYellow;
    G.EnterMovesNext := True;
    G.FindExtendedSyntax := True;
    G.FilterValueMenu := True;
    C.EditFormIndex := 3;
    C.EditFormNewRow := True;
    C.GroupDateMode := gdmWeek;
    M.Clear;
    M.WriteComponent(G);
    M.Position := 0;
    M.ReadComponent(G2);
    CheckFalse(G2.AllowEdit);
    CheckFalse(G2.AllowInsert);
    CheckFalse(G2.AllowDelete);
    CheckTrue(G2.SortIndicatorFromIndex);
    CheckTrue(G2.CardAutoWidth);
    CheckEquals(clYellow, G2.CardAreaColor);
    CheckTrue(G2.EnterMovesNext);
    CheckTrue(G2.FindExtendedSyntax);
    CheckTrue(G2.FilterValueMenu);
    C2 := TPPGDBGridColumn(G2.Columns[0]);
    CheckEquals(3, C2.EditFormIndex);
    CheckTrue(C2.EditFormNewRow);
    CheckTrue(C2.GroupDateMode = gdmWeek);
    C2 := TPPGDBGridColumn(G2.Columns.Add);
    C2.Assign(C);
    CheckEquals(3, C2.EditFormIndex, 'Assign');
    CheckTrue(C2.EditFormNewRow);
  finally
    T.Free;
    M.Free;
    G2.Free;
    G.Free;
  end;
end;

procedure TDBGridWishesTests.AllowEditInsertDelete;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(5, ['ID', 'Name']);
  G.Options := G.Options - [dgConfirmDelete];
  G.AllowInsert := False;
  Key(G, VK_INSERT);
  CheckTrue(FData.State = dsBrowse, 'Einfg gesperrt');
  FData.Last;
  Key(G, VK_DOWN);
  CheckTrue(FData.State = dsBrowse, 'kein Anhaengen');
  CheckEquals(5, RecordTotal);
  G.AllowDelete := False;
  Key(G, VK_DELETE, [ssCtrl]);
  CheckEquals(5, RecordTotal, 'Loeschen gesperrt');
  G.AllowDelete := True;
  Key(G, VK_DELETE, [ssCtrl]);
  CheckEquals(4, RecordTotal);
  // Bearbeiten: bestehende Saetze nur lesen, neue bearbeitbar
  FData.First;
  CheckTrue(TDBGridAccess(G).CanEditCell(ColOf(G, 'Name'), G.FocusRow));
  G.AllowEdit := False;
  CheckFalse(TDBGridAccess(G).CanEditCell(ColOf(G, 'Name'), G.FocusRow));
  G.AllowInsert := True;
  Key(G, VK_INSERT);
  CheckTrue(FData.State = dsInsert);
  CheckTrue(G.IsActiveRecordRow(G.FocusRow));
  CheckTrue(TDBGridAccess(G).CanEditCell(ColOf(G, 'Name'), G.FocusRow), 'neuer Satz');
  G.AllowInsert := False;
  CheckFalse(TDBGridAccess(G).CanEditCell(ColOf(G, 'Name'), G.FocusRow));
  FData.Cancel;
  // Formular: ohne AllowEdit nicht fuer bestehende Saetze
  G.EditMode := dgeForm;
  G.ShowEditForm;
  CheckFalse(G.EditFormActive);
  G.AllowEdit := True;
  G.ShowEditForm;
  CheckTrue(G.EditFormActive);
  G.HideEditForm(False);
  // Mehrfachauswahl: Strg+Entf folgt AllowDelete
  G.EditMode := dgeCells;
  G.Options := G.Options + [dgMultiSelect];
  G.SelectedRows.CurrentRowSelected := True;
  G.AllowDelete := False;
  Key(G, VK_DELETE, [ssCtrl]);
  CheckEquals(4, RecordTotal, 'Auswahl nicht geloescht');
  G.AllowDelete := True;
  Key(G, VK_DELETE, [ssCtrl]);
  CheckEquals(3, RecordTotal);
end;

procedure TDBGridWishesTests.EnterMovesToNextRecord;
var
  G: TPPGDBGrid;
begin
  FForm.Show;
  try
    G := NewGrid(5, ['ID', 'Name']);
    G.EnterMovesNext := True;
    G.SetFocus;
    G.Col := ColOf(G, 'ID');
    Key(G, VK_RETURN);
    CheckEquals(ColOf(G, 'Name'), G.Col, 'naechste Spalte');
    CheckEquals(1, CurID);
    Key(G, VK_RETURN);
    CheckEquals(2, CurID, 'naechster Satz');
    CheckEquals(ColOf(G, 'ID'), G.Col);
    // Im Editor: Wert schreiben, buchen und weiter
    G.Col := ColOf(G, 'Name');
    Key(G, VK_F2);
    CheckTrue(G.EditorMode);
    TPPGGridEdit(G.InplaceEditor).Text := 'Neu2';
    G.InplaceEditor.Perform(WM_KEYDOWN, VK_RETURN, 0);
    CheckFalse(G.EditorMode);
    CheckEquals(3, CurID);
    CheckTrue(FData.State = dsBrowse, 'gebucht');
    CheckTrue(FData.Locate('ID', 2, []));
    CheckEquals('Neu2', FData.FieldByName('Name').AsString);
    // Letzter Satz: nichts anhaengen
    FData.Last;
    G.Col := ColOf(G, 'Name');
    Key(G, VK_RETURN);
    CheckEquals(5, CurID);
    CheckTrue(FData.State = dsBrowse);
    CheckEquals(5, RecordTotal);
  finally
    FForm.Hide;
  end;
end;

procedure TDBGridWishesTests.SortRequestIndexAndActiveRow;
var
  G: TPPGDBGrid;
  M: TPopupMenu;
begin
  G := NewGrid(10, ['ID', 'Name', 'Preis']);
  G.OnSorted := CountSorted;
  // Ohne Sortierpfeil kein Sortieren im Kopfmenue (wie bisher)
  M := G.CreateHeaderMenu(ColOf(G, 'Name'));
  try
    CheckFalse(M.Items[0].Enabled);
  finally
    M.Free;
  end;
  G.SortOnHeaderClick := True;
  G.OnSortRequest := SortRequest;
  M := G.CreateHeaderMenu(ColOf(G, 'Name'));
  try
    CheckTrue(M.Items[0].Enabled, 'mit Sortierpfeil');
    M.Items[0].Click;
  finally
    M.Free;
  end;
  CheckEquals(IntToStr(ColOf(G, 'Name')) + ':1', FRequests[0]);
  CheckEquals(ColOf(G, 'Name'), G.SortColumn);
  CheckEquals(1, FSorted, 'OnSorted fuer die Datenmenge');
  FMapDesc := True;
  TDBGridAccess(G).HeaderClicked(ColOf(G, 'Name'), 0);
  CheckEquals(IntToStr(ColOf(G, 'Name')) + ':2', FRequests[1]);
  CheckEquals(-1, G.SortColumn, 'absteigend nicht moeglich');
  // Pfeil aus IndexFieldNames
  FSorted := 0;
  G.SortIndicatorFromIndex := True;
  FData.IndexFieldNames := 'Name';
  CheckEquals(ColOf(G, 'Name'), G.SortColumn);
  CheckTrue(G.SortAscending);
  CheckEquals(0, FSorted, 'kein OnSorted');
  CheckFalse(G.SyncSortIndicator, 'unveraendert');
  FData.IndexFieldNames := 'Preis;Name';
  CheckEquals(ColOf(G, 'Preis'), G.SortColumn, 'erstes Feld');
  FData.IndexFieldNames := 'OrtID';
  CheckEquals(-1, G.SortColumn, 'Feld ohne Spalte');
  FData.IndexFieldNames := '';
  CheckEquals(-1, G.SortColumn);
  // Aktiver Satz
  FData.First;
  FData.MoveBy(2);
  CheckTrue(G.IsActiveRecordRow(G.FocusRow));
  CheckFalse(G.IsActiveRecordRow(G.FocusRow - 1));
  CheckFalse(G.IsActiveRecordRow(0), 'Kopf');
  CheckFalse(G.IsActiveRecordRow(-1));
  CheckFalse(G.IsActiveRecordRow(9999));
  // Zelltext je Pufferzeile
  CheckEquals('Name3', G.CellText(ColOf(G, 'Name'), G.HeaderRowCount + 2));
  CheckEquals(1, G.HeaderRowCount);
end;

procedure TDBGridWishesTests.GroupsByDateField;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(40, ['ID', 'Name', 'Geboren']);
  // Geboren = 1.1.2000 + ID: 2.1. bis 10.2.2000
  Column(G, 'Geboren').GroupDateMode := gdmMonth;
  Column(G, 'Geboren').GroupIndex := 0;
  CheckTrue(G.GroupedView);
  CheckEquals(2, G.GroupCount);
  CheckEquals(FormatDateTime('mmmm yyyy', EncodeDate(2000, 1, 1)), G.GroupInfo(0).Key);
  CheckEquals(30, G.GroupInfo(0).Count);
  CheckEquals(FormatDateTime('mmmm yyyy', EncodeDate(2000, 2, 1)), G.GroupInfo(1).Key);
  CheckEquals(10, G.GroupInfo(1).Count);
  Column(G, 'Geboren').GroupDateMode := gdmWeek;
  CheckEquals(7, G.GroupCount, 'KW 1 bis 6 (2000) und KW 52 (1999)');
  CheckEquals(Format(PPGStr(@SPPGGridDateWeek), [52, 1999]), G.GroupInfo(0).Key,
    '2.1.2000 gehoert zur KW 52 1999');
  // Null-Datum: eigene (leere) Gruppe zuerst
  FData.First;
  FData.Edit;
  FData.FieldByName('Geboren').Clear;
  FData.Post;
  G.RefreshGroups;
  CheckEquals('', G.GroupInfo(0).Key);
  CheckEquals(1, G.GroupInfo(0).Count);
end;

procedure TDBGridWishesTests.FilterValuesOverDataSet;
var
  G: TPPGDBGrid;
  M: TPopupMenu;
  Sub: TMenuItem;
begin
  G := NewGrid(30, ['ID', 'Name', 'Preis', 'OrtID']);
  FData.RecNo := 5;
  CheckEquals('1,2,3', Join(G.ColumnFilterValues(ColOf(G, 'OrtID'))));
  CheckEquals(5, CurID, 'Satz bleibt');
  CheckEquals('1,5,3,4,5,6,7,5', Join(G.ColumnFilterValues(ColOf(G, 'Preis'), 5)),
    'nach Wert, hoechstens 5');
  G.SetFilterValues(ColOf(G, 'OrtID'), ['1', '3']);
  CheckEquals(20, RecordTotal);
  CheckTrue(G.FiltersActive);
  // Kopfmenue
  G.FilterValueMenu := True;
  M := G.CreateHeaderMenu(ColOf(G, 'OrtID'));
  try
    Sub := SubMenu(M, PPGStr(@SPPGGridFilterValues));
    CheckNotNull(Sub);
    CheckEquals(1 + 2, Sub.Count, 'Werte der gefilterten Datenmenge');
    CheckTrue(Sub[1].Checked);
    Sub[1].Click; // 1 weg
  finally
    M.Free;
  end;
  CheckEquals(10, RecordTotal);
  G.ClearFilters;
  CheckEquals(30, RecordTotal);
  // Offene Bearbeitung: nur der Puffer, nichts gebucht
  FData.First;
  FData.Edit;
  FData.FieldByName('Name').AsString := 'Offen';
  CheckTrue(Length(G.ColumnFilterValues(ColOf(G, 'OrtID'))) > 0);
  CheckTrue(FData.State = dsEdit, 'nicht gebucht');
  FData.Cancel;
  // Gruppiert: aus dem Speicher
  Column(G, 'OrtID').GroupIndex := 0;
  CheckEquals('1,2,3', Join(G.ColumnFilterValues(ColOf(G, 'OrtID'))));
end;

procedure TDBGridWishesTests.ExtendedFindOverDataSet;
var
  G: TPPGDBGrid;
  Ids: TStringList;
  I: Integer;
begin
  G := NewGrid(30, ['ID', 'Name', 'OrtID']);
  G.FindPanel := fpmAlways;
  G.FindExtendedSyntax := True;
  G.FindText := 'name2 -name20';
  FData.First;
  CheckTrue(G.FindNext);
  CheckEquals(2, CurID);
  CheckTrue(G.FindNext);
  CheckEquals(21, CurID, 'Name20 ausgeschlossen');
  G.FindText := '+"name1" +4';
  FData.First;
  CheckTrue(G.FindNext);
  CheckEquals(14, CurID, 'Name14 (ID 14 enthaelt 4)');
  G.FindText := 'nam_7';
  FData.First;
  CheckTrue(G.FindNext);
  CheckEquals(7, CurID);
  G.FindText := '+name -name';
  CheckFalse(G.FindNext);
  // Gruppiert: in der Reihenfolge der Ansicht
  Column(G, 'OrtID').GroupIndex := 0;
  G.FindText := 'name2 -name20';
  Ids := TStringList.Create;
  try
    Ids.Sorted := True;
    Ids.Duplicates := dupIgnore;
    for I := 1 to 12 do
    begin
      CheckTrue(G.FindNext);
      Ids.Add(IntToStr(CurID));
    end;
    CheckEquals(10, Ids.Count, '2 und 21..29');
    CheckEquals(-1, Ids.IndexOf('20'));
  finally
    Ids.Free;
  end;
end;

procedure TDBGridWishesTests.ViewPositionOverDataSet;
var
  G: TPPGDBGrid;
  VP: IPPGViewPosition;
  O: TViewObserver;
  N: Integer;
begin
  G := NewGrid(10, ['ID', 'Name', 'OrtID']);
  CheckTrue(Supports(G, IPPGViewPosition, VP));
  CheckEquals(10, VP.ViewRecordCount);
  CheckEquals(1, VP.ViewRecordNo);
  O := TViewObserver.Create(nil);
  try
    VP.ViewPositionObserver(O, True);
    FData.Next;
    CheckTrue(O.Count > 0, 'Satzwechsel benachrichtigt');
    CheckEquals(2, VP.ViewRecordNo);
    CheckTrue(VP.ViewMove(pvmLast));
    CheckEquals(10, CurID);
    CheckEquals(10, VP.ViewRecordNo);
    CheckTrue(VP.ViewMove(pvmFirst));
    CheckEquals(1, CurID);
    CheckFalse(VP.ViewCanMove(pvmPrior), 'Bof');
    CheckTrue(VP.ViewMove(pvmNext));
    CheckEquals(2, CurID);
    // Neuer Satz: keine Nummer
    FData.Append;
    CheckEquals(0, VP.ViewRecordNo);
    FData.Cancel;
    // Gruppiert: die Ansicht (zugeklappte Gruppen ohne Zeilen)
    Column(G, 'OrtID').GroupIndex := 0;
    CheckEquals(10, VP.ViewRecordCount);
    G.FullCollapse;
    CheckEquals(0, VP.ViewRecordCount);
    G.FullExpand;
    N := O.Count;
    CheckTrue(VP.ViewMove(pvmLast));
    CheckTrue(O.Count > N);
    CheckEquals(10, VP.ViewRecordNo);
    VP.ViewPositionObserver(O, False);
    // Geschlossen
    FData.Close;
    CheckEquals(0, VP.ViewRecordCount);
    CheckEquals(0, VP.ViewRecordNo);
    CheckFalse(VP.ViewCanMove(pvmNext));
    CheckFalse(VP.ViewMove(pvmNext));
  finally
    O.Free;
  end;
  VP := nil;
end;

procedure TDBGridWishesTests.CardsWidthAreaAndDblClick;
var
  G: TPPGDBGrid;
  M: TPPGDBGridCardMetrics;
  B: TBitmap;
  R: TRect;
  P: TPoint;
  C, V, Y: Integer;
  Found: Boolean;
begin
  FForm.Show;
  try
    G := NewGrid(6, ['ID', 'Name']);
    G.ViewStyle := dgvCards;
    G.CardWidth := 250;
    M := G.CardMetrics;
    CheckEquals(250, M.CardW);
    CheckEquals(2, M.PerRow);
    G.CardAutoWidth := True;
    M := G.CardMetrics;
    CheckEquals(2, M.PerRow);
    CheckEquals(((M.View.Right - M.View.Left) - M.Gap) div 2 - M.Gap, M.CardW, 'Zeile gefuellt');
    // Flaeche zwischen den Karten
    G.CardAreaColor := clRed;
    B := RenderToBitmap(G);
    try
      CheckEquals(ColorToRGB(clRed), B.Canvas.Pixels[2, 2] and $FFFFFF);
  finally
    B.Free;
  end;
  G.CardAreaColor := clDefault;
  B := RenderToBitmap(G);
  try
    CheckNotEquals(ColorToRGB(clRed), B.Canvas.Pixels[2, 2] and $FFFFFF, 'Theme');
  finally
    B.Free;
  end;
  // Doppelklick auf ein Feld der zweiten Karte
  G.OnCellDblClick := CellDbl;
  R := G.CardRect(1);
  CheckFalse(R.IsEmpty);
  Found := False;
  P := Point(0, 0);
  for Y := R.Top to R.Bottom do
    if G.MouseCoord(CenterOf(R).X, Y, C, V) and G.IsDataRow(V) then
    begin
      P := Point(CenterOf(R).X, Y);
      Found := True;
      Break;
    end;
  CheckTrue(Found, 'Feld in der Karte');
  G.Perform(WM_LBUTTONDBLCLK, MK_LBUTTON, MouseLParam(P));
  G.Perform(WM_LBUTTONUP, 0, MouseLParam(P));
  CheckEquals(IntToStr(G.DataCol(C)) + ',' + IntToStr(TDBGridAccess(G).FixedRows + 1), FDbl);
  // Zwischen den Karten: kein Ereignis
  FDbl := '';
  G.Perform(WM_LBUTTONDBLCLK, MK_LBUTTON, MouseLParam(Point(2, 2)));
  G.Perform(WM_LBUTTONUP, 0, MouseLParam(Point(2, 2)));
  CheckEquals('', FDbl);
  finally
    FForm.Hide;
  end;
end;

procedure TDBGridWishesTests.EditFormOrderAndNewRow;
var
  G: TPPGDBGrid;
  P: TPPGDBGridEditForm;
  ACell, ARow, ASpan: Integer;
begin
  G := NewGrid(5, ['ID', 'Name', 'Preis', 'OrtID']);
  G.EditForm.ColumnCount := 4;
  Column(G, 'OrtID').EditFormIndex := 0;
  Column(G, 'Preis').EditFormIndex := 0; // gleich: Anzeige-Reihenfolge
  Column(G, 'Name').EditFormNewRow := True;
  G.EditMode := dgeForm;
  G.ShowEditForm;
  CheckTrue(G.EditFormActive);
  P := G.EditFormControl;
  CheckEquals(4, P.ItemCount);
  CheckEquals(ColOf(G, 'Preis'), P.ItemDataCol(0), 'Index 0, in der Anzeige vor OrtID');
  CheckEquals(ColOf(G, 'OrtID'), P.ItemDataCol(1));
  CheckEquals(ColOf(G, 'ID'), P.ItemDataCol(2), 'ohne Index danach');
  CheckEquals(ColOf(G, 'Name'), P.ItemDataCol(3));
  P.ItemCell(2, ACell, ARow, ASpan);
  CheckEquals(2, ACell);
  CheckEquals(0, ARow);
  P.ItemCell(3, ACell, ARow, ASpan);
  CheckEquals(0, ACell, 'neue Zeile');
  CheckEquals(1, ARow);
  G.HideEditForm(False);
  // Neue Zeile am Zeilenanfang: keine leere Zeile
  Column(G, 'Name').EditFormIndex := 1;
  Column(G, 'Name').EditFormNewRow := False;
  Column(G, 'ID').EditFormNewRow := True;
  G.EditForm.ColumnCount := 3;
  G.ShowEditForm;
  P := G.EditFormControl;
  CheckEquals(ColOf(G, 'Name'), P.ItemDataCol(2));
  CheckEquals(ColOf(G, 'ID'), P.ItemDataCol(3));
  P.ItemCell(3, ACell, ARow, ASpan);
  CheckEquals(0, ACell);
  CheckEquals(1, ARow, 'Zeile 0 voll, ID beginnt Zeile 1');
  G.HideEditForm(False);
end;

initialization
  RegisterTest('GridWishes', TGridQueryTests.Suite);
  RegisterTest('GridWishes', TGridWishesTests.Suite);
  RegisterTest('GridWishes', TDBGridWishesTests.Suite);

end.
