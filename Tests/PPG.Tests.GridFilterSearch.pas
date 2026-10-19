unit PPG.Tests.GridFilterSearch;

{ Tests fuer Filter, Suche und Ereignisse von Grid und DB-Grid (Gruppe 5,
  Schritt 6a): Filtertext mit Operatoren (TPPGFilterCondition), Filterzeile
  im Grid und ueber die Datenmenge (OnFilterRecord, Filter der Anwendung
  bleiben erhalten), sofortiges Filtern, Filterleiste, Suchfeld (FindPanel,
  Weiter/Zurueck, Markierung), Tippsuche in der Fokusspalte, RowValue in
  OnGetCellStyle (Bildschirm und Druck), Mehrfachauswahl-Helfer und Veto,
  OnFocusedRecordChanged und OnSelectCell, Bearbeitungsformular mit Memo,
  Datum und Abschnitten, mehrspaltige Nachschlage-Auswahl, Layout des
  DB-Grids und Streaming der neuen Properties.

  Daten: Zeichenketten im Grid bzw. ein TClientDataSet im Speicher
  (synthetische Werte). Formate fest deutsch (PPGTestGermanFormat). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Variants, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids,
  Vcl.DBGrids, Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Types, PPG.Exceptions, PPG.Controls.Base, PPG.Controls.Scroll, PPG.Button,
  PPG.Memo, PPG.DatePicker, PPG.ColumnComboBox, PPG.Lang, PPG.Consts,
  PPG.Grid.Styles, PPG.Grid, PPG.Grid.View, PPG.Grid.Edit, PPG.DB.Grid,
  PPG.Tests.Controls, PPG.Tests.Phase9c;

type
  TGridFilterParseTests = class(TControlTestCase)
  published
    procedure ParsesOperatorsAndMatches;
    procedure FilterTextRoundTrip;
  end;

  TGridFilterSearchTests = class(TControlTestCase)
  private
    FFilterChanged: Integer;
    function SampleGrid: TPPGGrid;
    function Visible(G: TPPGGrid): string;
    procedure Key(G: TPPGGrid; VK: Word; Shift: TShiftState = []);
    procedure Press(G: TPPGGrid; const S: string);
    procedure Click(G: TPPGGrid; const P: TPoint);
    procedure CountFilter(Sender: TObject);
  published
    procedure DefaultsAndStreaming;
    procedure OperatorsInFilterRow;
    procedure EventDescriptionAndFilterBar;
    procedure ImmediateFilterKeepsEditor;
    procedure FindPanelNextPreviousAndHide;
    procedure IncrementalSearchInFocusColumn;
  end;

  TDBGridFilterSearchTests = class(TDBTestCase)
  private
    FFocusChanged: Integer;
    FSorted: Integer;
    FStyleIds: TStringList;
    FOrte: TClientDataSet;
    FOrteSource: TDataSource;
    function NewGrid(N: Integer; const Cols: array of string): TPPGDBGrid;
    function ColOf(G: TPPGDBGrid; const FieldName: string): Integer;
    function Editor(G: TPPGDBGrid; const FieldName: string): TPPGCustomControl;
    function ItemOf(G: TPPGDBGrid; const FieldName: string): Integer;
    function Column(G: TPPGDBGrid; const FieldName: string): TPPGDBGridColumn;
    procedure Press(G: TPPGDBGrid; const S: string);
    procedure EvenOnly(DataSet: TDataSet; var Accept: Boolean);
    procedure EvenSelect(Sender: TObject; var Allow: Boolean);
    procedure CountFocus(Sender: TObject);
    procedure CountSorted(Sender: TObject);
    procedure RefuseId3(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure StyleByAktiv(Sender: TObject; ACol, ARow: Integer; var Style: TPPGGridCellStyle);
    procedure MakeOrte;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure DefaultsRangeChecksAndStreaming;
    procedure FilterRowFiltersDataSet;
    procedure FilterKeepsApplicationFilter;
    procedure FilterRowEditorImmediate;
    procedure FindPanelWalksDataSet;
    procedure IncrementalSearchLocates;
    procedure RowValueInCellStyleScreenAndPrint;
    procedure MultiSelectHelpersAndVeto;
    procedure FocusedRecordAndSelectCellVeto;
    procedure EditFormMemoDateAndGroups;
    procedure LookupWithSeveralListFields;
    procedure LayoutSaveLoadAndSortIndicator;
  end;

implementation

type
  TGridAccess = class(TPPGGrid);
  TDBGridAccess = class(TPPGDBGrid);
  TButtonAccess = class(TPPGButton);

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

{ TGridFilterParseTests }

procedure TGridFilterParseTests.ParsesOperatorsAndMatches;
var
  C: TPPGFilterCondition;
begin
  FormatSettings := PPGTestGermanFormat;
  C := PPGFilterParse('');
  CheckFalse(C.Active, 'leer: keine Bedingung');
  C := PPGFilterParse('abc');
  CheckTrue(C.Op = pfoContains, 'Text: enthaelt');
  CheckTrue(C.MatchText('xABCx'), 'ohne Gross/klein');
  CheckFalse(C.MatchText('ab'));
  C := PPGFilterParse('5', fvkNumber);
  CheckTrue(C.Op = pfoEqual, 'Zahl ohne Operator: gleich');
  CheckTrue(C.MatchText('5'));
  CheckFalse(C.MatchText('15'));
  C := PPGFilterParse('>=10');
  CheckTrue(C.Op = pfoGreaterEqual);
  CheckTrue(C.NumOk);
  CheckTrue(C.MatchText('10'));
  CheckTrue(C.MatchText('100'), 'als Zahl verglichen');
  CheckFalse(C.MatchText('9'), 'als Zahl verglichen (Text waere groesser)');
  C := PPGFilterParse('<> 3');
  CheckTrue(C.Op = pfoNotEqual);
  CheckEquals('3', C.Value);
  C := PPGFilterParse('<2,5');
  CheckTrue(C.Op = pfoLess);
  CheckTrue(C.MatchText('2'));
  CheckFalse(C.MatchText('2,5'));
  C := PPGFilterParse('1..3');
  CheckTrue(C.Op = pfoBetween);
  CheckTrue(C.MatchText('2'));
  CheckTrue(C.MatchText('3'), 'einschliesslich');
  CheckFalse(C.MatchText('4'));
  C := PPGFilterParse('ab*');
  CheckTrue(C.Op = pfoBeginsWith);
  CheckTrue(C.MatchText('ABC'));
  CheckFalse(C.MatchText('cab'));
  C := PPGFilterParse('*ab');
  CheckTrue(C.Op = pfoEndsWith);
  CheckTrue(C.MatchText('cab'));
  CheckFalse(C.MatchText('abc'));
  C := PPGFilterParse('*5*', fvkNumber);
  CheckTrue(C.Op = pfoContains, 'Sterne: enthaelt auch bei Zahlen');
  CheckTrue(C.MatchText('150'));
  C := PPGFilterParse('=');
  CheckTrue(C.Op = pfoEmpty);
  CheckTrue(C.MatchText(''));
  CheckFalse(C.MatchText('x'));
  CheckTrue(C.MatchNull);
  C := PPGFilterParse('<>');
  CheckTrue(C.Op = pfoNotEmpty);
  CheckFalse(C.MatchText(''));
  CheckFalse(C.MatchNull);
  C := PPGFilterParse('<05.01.2000', fvkDate);
  CheckTrue(C.DateOk);
  CheckTrue(C.MatchText('04.01.2000'));
  CheckFalse(C.MatchText('05.01.2000'));
  C := PPGFilterParse('05.01.2000', fvkDate);
  CheckTrue(C.Op = pfoEqual, 'Datum ohne Operator: gleich');
  CheckTrue(C.MatchDate(EncodeDate(2000, 1, 5) + 0.75), 'nur der Tag zaehlt');
  CheckFalse(C.MatchDate(EncodeDate(2000, 1, 6)));
  C := PPGFilterParse('>m');
  CheckTrue(C.MatchText('n'), 'Text-Vergleich');
  CheckFalse(C.MatchText('a'));
end;

procedure TGridFilterParseTests.FilterTextRoundTrip;
var
  Op: TPPGFilterOperator;
  C: TPPGFilterCondition;
begin
  FormatSettings := PPGTestGermanFormat;
  for Op := Low(TPPGFilterOperator) to High(TPPGFilterOperator) do
  begin
    C := PPGFilterParse(PPGFilterText(Op, '7', '9'), fvkNumber);
    CheckTrue(C.Op = Op, PPGFilterText(Op, '7', '9'));
    if not (Op in [pfoEmpty, pfoNotEmpty]) then
      CheckEquals('7', C.Value);
  end;
  CheckEquals('*a*', PPGFilterText(pfoContains, 'a'));
  CheckEquals('', PPGFilterText(pfoContains, ''), 'leer: kein Filter');
  CheckEquals('1..2', PPGFilterText(pfoBetween, '1', '2'));
end;

{ TGridFilterSearchTests }

function TGridFilterSearchTests.SampleGrid: TPPGGrid;
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
  Result.OnFilterChanged := CountFilter;
  FFilterChanged := 0;
end;

function TGridFilterSearchTests.Visible(G: TPPGGrid): string;
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

procedure TGridFilterSearchTests.Key(G: TPPGGrid; VK: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := VK;
  TGridAccess(G).KeyDown(K, Shift);
end;

procedure TGridFilterSearchTests.Press(G: TPPGGrid; const S: string);
var
  I: Integer;
  Ch: Char;
begin
  for I := 1 to Length(S) do
  begin
    Ch := S[I];
    TGridAccess(G).KeyPress(Ch);
  end;
end;

procedure TGridFilterSearchTests.Click(G: TPPGGrid; const P: TPoint);
begin
  G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P));
  G.Perform(WM_LBUTTONUP, 0, MouseLParam(P));
end;

procedure TGridFilterSearchTests.CountFilter(Sender: TObject);
begin
  Inc(FFilterChanged);
end;

procedure TGridFilterSearchTests.DefaultsAndStreaming;
var
  G, G2: TPPGGrid;
  M: TMemoryStream;
  T: TStringStream;
begin
  G := TPPGGrid.Create(nil);
  M := TMemoryStream.Create;
  T := TStringStream.Create('');
  try
    CheckFalse(G.FilterImmediate);
    CheckFalse(G.ShowFilterBar);
    CheckTrue(G.FindPanel = fpmNone);
    CheckFalse(G.IncrementalSearch);
    CheckFalse(G.FindPanelVisible);
    CheckNull(G.FindPanelControl, 'Suchfeld erst beim Einblenden');
    M.WriteComponent(G);
    M.Position := 0;
    ObjectBinaryToText(M, T);
    CheckEquals(0, Pos('FilterImmediate', T.DataString), 'Vorgabe nicht gespeichert');
    CheckEquals(0, Pos('ShowFilterBar', T.DataString));
    CheckEquals(0, Pos('FindPanel', T.DataString));
    CheckEquals(0, Pos('IncrementalSearch', T.DataString));
    G.FilterImmediate := True;
    G.ShowFilterBar := True;
    G.FindPanel := fpmAlways;
    G.IncrementalSearch := True;
    M.Clear;
    M.WriteComponent(G);
    M.Position := 0;
    G2 := TPPGGrid(M.ReadComponent(nil));
    try
      CheckTrue(G2.FilterImmediate, 'FilterImmediate');
      CheckTrue(G2.ShowFilterBar, 'ShowFilterBar');
      CheckTrue(G2.FindPanel = fpmAlways, 'FindPanel');
      CheckTrue(G2.IncrementalSearch, 'IncrementalSearch');
    finally
      G2.Free;
    end;
  finally
    T.Free;
    M.Free;
    G.Free;
  end;
end;

procedure TGridFilterSearchTests.OperatorsInFilterRow;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.ShowFilterRow := True;
  G.Filters[1] := '>5';
  CheckEquals('Mutter,Duebel,Winkel,Kabel', Visible(G), '> als Zahl');
  G.Filters[1] := '=2';
  CheckEquals('Schraube,Mutter klein', Visible(G));
  G.Filters[1] := '2..10';
  CheckEquals('Mutter,Schraube,Mutter klein,Kabel', Visible(G));
  G.SetFilterCondition(1, pfoLess, '10');
  CheckEquals('<10', G.Filters[1]);
  CheckEquals('Schraube,Mutter klein,Kabel', Visible(G));
  G.Filters[1] := '';
  G.Filters[0] := 'mutter*';
  CheckEquals('Mutter,Mutter klein', Visible(G), 'beginnt mit');
  G.Filters[0] := '*klein';
  CheckEquals('Mutter klein', Visible(G), 'endet mit');
  G.SetFilterCondition(0, pfoContains, 'au');
  CheckEquals('Schraube', Visible(G), 'enthaelt');
  G.Filters[0] := '=';
  CheckEquals('', Visible(G), 'leer: keine');
  G.Filters[0] := '<>';
  CheckEquals('Mutter,Schraube,Duebel,Mutter klein,Winkel,Kabel', Visible(G), 'nicht leer');
  G.SetFilterCondition(0, pfoEqual, 'kabel');
  CheckEquals('Kabel', Visible(G), 'gleich ohne Gross/klein');
  G.ClearFilters;
  CheckEquals('Mutter,Schraube,Duebel,Mutter klein,Winkel,Kabel', Visible(G));
end;

procedure TGridFilterSearchTests.EventDescriptionAndFilterBar;
var
  G: TPPGGrid;
  GV0: TRect;
  H, N: Integer;
  B: TBitmap;
  Expected: string;
begin
  G := SampleGrid;
  G.Filters[0] := 'mut';
  CheckEquals(1, FFilterChanged, 'OnFilterChanged');
  CheckTrue(G.FiltersActive);
  G.Filters[0] := 'mut';
  CheckEquals(1, FFilterChanged, 'gleicher Text: kein Ereignis');
  G.Filters[1] := '>5';
  Expected := Format(PPGStr(@SPPGFilterDescJoin),
    [Format(PPGStr(@SPPGFilterDescContains), ['Name', 'mut']),
     Format(PPGStr(@SPPGFilterDescCompare), ['Zahl', '>', '5'])]);
  CheckEquals(Expected, G.FilterDescription);
  // Filterleiste nur mit ShowFilterBar und aktivem Filter
  CheckEquals(0, TGridAccess(G).FilterBarHeight, 'ohne ShowFilterBar');
  GV0 := TGridAccess(G).GridViewRect;
  G.ShowFilterBar := True;
  H := TGridAccess(G).FilterBarHeight;
  CheckTrue(H > 0, 'Filterleiste sichtbar');
  CheckEquals(GV0.Bottom - H, TGridAccess(G).GridViewRect.Bottom, 'Zellen enden ueber der Leiste');
  B := RenderToBitmap(G);
  B.Free;
  // "Filter loeschen" anklicken
  N := FFilterChanged;
  Click(G, CenterOf(TGridAccess(G).FilterBarClearRect));
  CheckFalse(G.FiltersActive, 'Klick loescht die Filter');
  CheckEquals(N + 1, FFilterChanged);
  CheckEquals(0, TGridAccess(G).FilterBarHeight, 'Leiste wieder weg');
  CheckEquals(GV0.Bottom, TGridAccess(G).GridViewRect.Bottom);
  CheckEquals('', G.FilterDescription);
end;

procedure TGridFilterSearchTests.ImmediateFilterKeepsEditor;
var
  G: TPPGGrid;
  Ed: TPPGGridEdit;
begin
  FForm.Show; // der Editor braucht den Fokus
  try
    G := SampleGrid;
    G.ShowFilterRow := True;
    G.FilterImmediate := True;
    Click(G, CenterOf(G.CellRect(0, 1)));
    CheckTrue(G.EditorMode, 'Klick in die Filterzeile oeffnet den Editor');
    Ed := G.InplaceEditor as TPPGGridEdit;
    Ed.Text := 'mut';
    CheckEquals('mut', G.Filters[0], 'sofort gefiltert');
    CheckEquals('Mutter,Mutter klein', Visible(G));
    CheckTrue(G.EditorMode, 'Editor bleibt offen');
    Ed.Text := 'mutter k';
    CheckEquals('Mutter klein', Visible(G));
    CheckTrue(G.EditorMode);
    G.EditorMode := False;
    CheckEquals('mutter k', G.Filters[0]);
    // Ohne FilterImmediate: erst beim Uebernehmen
    G.FilterImmediate := False;
    Click(G, CenterOf(G.CellRect(0, 1)));
    Ed := G.InplaceEditor as TPPGGridEdit;
    Ed.Text := 'sch';
    CheckEquals('mutter k', G.Filters[0], 'noch nicht uebernommen');
    G.EditorMode := False;
    CheckEquals('Schraube', Visible(G), 'beim Uebernehmen');
  finally
    FForm.Hide;
  end;
end;

procedure TGridFilterSearchTests.FindPanelNextPreviousAndHide;
var
  G: TPPGGrid;
  GV0: TRect;
  P: TPPGGridFindPanel;
  B: TBitmap;
begin
  G := SampleGrid;
  G.ShowFind;
  CheckFalse(G.FindPanelVisible, 'FindPanel = fpmNone: kein Suchfeld');
  G.FindPanel := fpmManual;
  CheckFalse(G.FindPanelVisible, 'manuell: erst auf Anforderung');
  GV0 := TGridAccess(G).GridViewRect;
  Key(G, Ord('F'), [ssCtrl]);
  CheckTrue(G.FindPanelVisible, 'Strg+F');
  P := G.FindPanelControl;
  CheckNotNull(P);
  CheckTrue(P.Visible);
  CheckTrue(P.CloseButton.Visible, 'manuell: Schliessen');
  CheckEquals(GV0.Top + TGridAccess(G).FindPanelHeight, TGridAccess(G).GridViewRect.Top,
    'Zellen unter dem Suchfeld');
  CheckEquals(TGridAccess(G).FindPanelHeight, P.Height);
  G.Col := 0;
  G.Row := 1;
  G.FindText := 'mutter';
  CheckTrue(G.FindNext);
  CheckEquals('Mutter klein', G.Cells[0, G.Row], 'naechster Treffer');
  CheckTrue(G.FindNext);
  CheckEquals('Mutter', G.Cells[0, G.Row], 'im Kreis');
  CheckTrue(G.FindPrevious);
  CheckEquals('Mutter klein', G.Cells[0, G.Row], 'voriger Treffer');
  G.FindText := 't5';
  CheckTrue(G.FindNext);
  CheckEquals(2, G.Col, 'Treffer in der dritten Spalte');
  CheckEquals('Winkel', G.Cells[0, G.Row]);
  G.FindText := 'zzz';
  CheckFalse(G.FindNext, 'kein Treffer');
  CheckEquals('Winkel', G.Cells[0, G.Row], 'Fokus bleibt');
  // Treffer markiert zeichnen
  G.FindText := 'au';
  B := RenderToBitmap(G);
  B.Free;
  // Schaltflaeche Weiter mit dem Text des Felds
  P.Edit.Text := 'kabel';
  TButtonAccess(P.NextButton).Click;
  CheckEquals('kabel', G.FindText);
  CheckEquals('Kabel', G.Cells[0, G.Row]);
  // F3 im Grid
  G.FindText := 'mutter';
  Key(G, VK_F3);
  CheckEquals('Mutter', G.Cells[0, G.Row], 'F3');
  Key(G, VK_F3, [ssShift]);
  CheckEquals('Mutter klein', G.Cells[0, G.Row], 'Umschalt+F3');
  // Schliessen leert den Suchtext
  TButtonAccess(P.CloseButton).Click;
  CheckFalse(G.FindPanelVisible);
  CheckEquals('', G.FindText);
  CheckEquals(GV0.Top, TGridAccess(G).GridViewRect.Top);
  // Immer sichtbar: ohne Schliessen
  G.FindPanel := fpmAlways;
  CheckTrue(G.FindPanelVisible);
  CheckFalse(G.FindPanelControl.CloseButton.Visible);
  G.HideFind;
  CheckTrue(G.FindPanelVisible, 'fpmAlways bleibt');
  G.FindPanel := fpmNone;
  CheckFalse(G.FindPanelVisible);
end;

procedure TGridFilterSearchTests.IncrementalSearchInFocusColumn;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  PPGSetTypeAheadClock(PPGTestClock);
  G.Col := 0;
  G.Row := 1;
  Press(G, 'w');
  CheckEquals('Mutter', G.Cells[0, G.Row], 'ohne IncrementalSearch: nichts');
  G.IncrementalSearch := True;
  Press(G, 'w');
  CheckEquals('Winkel', G.Cells[0, G.Row]);
  CheckEquals('w', G.IncrementalSearchText);
  Press(G, 'i');
  CheckEquals('Winkel', G.Cells[0, G.Row], 'wi: bleibt');
  PPGTestAdvanceClock(PPGTypeAheadMs + 100);
  Press(G, 'm');
  CheckEquals('Mutter', G.Cells[0, G.Row], 'neu: m im Kreis');
  Press(G, 'utter k');
  CheckEquals('Mutter klein', G.Cells[0, G.Row], 'Praefix ohne Gross/klein');
  CheckEquals('mutter k', G.IncrementalSearchText);
  Key(G, VK_ESCAPE);
  CheckEquals('', G.IncrementalSearchText, 'Esc beginnt neu');
end;

{ TDBGridFilterSearchTests }

procedure TDBGridFilterSearchTests.SetUp;
begin
  inherited SetUp;
  FormatSettings := PPGTestGermanFormat;
  FFocusChanged := 0;
  FSorted := 0;
  FStyleIds := TStringList.Create;
  FOrte := nil;
  FOrteSource := nil;
end;

procedure TDBGridFilterSearchTests.TearDown;
begin
  FreeAndNil(FStyleIds);
  inherited TearDown;
end;

function TDBGridFilterSearchTests.NewGrid(N: Integer; const Cols: array of string): TPPGDBGrid;
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

function TDBGridFilterSearchTests.ColOf(G: TPPGDBGrid; const FieldName: string): Integer;
var
  I: Integer;
begin
  for I := 0 to G.FieldCount - 1 do
    if SameText(G.Fields[I].FieldName, FieldName) then
      Exit(TDBGridAccess(G).FixedCols + I);
  Result := -1;
end;

function TDBGridFilterSearchTests.Editor(G: TPPGDBGrid; const FieldName: string): TPPGCustomControl;
begin
  Result := G.EditFormEditor(ColOf(G, FieldName));
  CheckNotNull(Result, 'Editor fuer ' + FieldName);
end;

function TDBGridFilterSearchTests.ItemOf(G: TPPGDBGrid; const FieldName: string): Integer;
var
  I: Integer;
begin
  for I := 0 to G.EditFormControl.ItemCount - 1 do
    if G.EditFormControl.ItemDataCol(I) = ColOf(G, FieldName) then
      Exit(I);
  Result := -1;
end;

function TDBGridFilterSearchTests.Column(G: TPPGDBGrid; const FieldName: string): TPPGDBGridColumn;
var
  I: Integer;
begin
  for I := 0 to G.Columns.Count - 1 do
    if SameText(TPPGDBGridColumn(G.Columns[I]).FieldName, FieldName) then
      Exit(TPPGDBGridColumn(G.Columns[I]));
  Result := nil;
end;

procedure TDBGridFilterSearchTests.Press(G: TPPGDBGrid; const S: string);
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

procedure TDBGridFilterSearchTests.EvenOnly(DataSet: TDataSet; var Accept: Boolean);
begin
  Accept := not Odd(DataSet.FieldByName('ID').AsInteger);
end;

procedure TDBGridFilterSearchTests.EvenSelect(Sender: TObject; var Allow: Boolean);
begin
  Allow := not Odd(FData.FieldByName('ID').AsInteger);
end;

procedure TDBGridFilterSearchTests.CountFocus(Sender: TObject);
begin
  Inc(FFocusChanged);
end;

procedure TDBGridFilterSearchTests.CountSorted(Sender: TObject);
begin
  Inc(FSorted);
end;

procedure TDBGridFilterSearchTests.RefuseId3(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
begin
  CanSelect := VarToStr((Sender as TPPGDBGrid).RowValue('ID')) <> '3';
end;

procedure TDBGridFilterSearchTests.StyleByAktiv(Sender: TObject; ACol, ARow: Integer;
  var Style: TPPGGridCellStyle);
var
  G: TPPGDBGrid;
begin
  G := Sender as TPPGDBGrid;
  FStyleIds.Add(VarToStr(G.RowValue('ID')));
  if G.RowValue('Aktiv') = True then
    Style.Fill := clRed;
end;

procedure TDBGridFilterSearchTests.MakeOrte;
var
  I: Integer;
begin
  FOrte := TClientDataSet.Create(FForm);
  FOrte.FieldDefs.Add('OrtID', ftInteger);
  FOrte.FieldDefs.Add('Ort', ftString, 20);
  FOrte.FieldDefs.Add('PLZ', ftString, 5);
  FOrte.CreateDataSet;
  for I := 1 to 3 do
    FOrte.AppendRecord([I, 'Ort' + IntToStr(I), '1000' + IntToStr(I)]);
  FOrteSource := TDataSource.Create(FForm);
  FOrteSource.DataSet := FOrte;
end;

procedure TDBGridFilterSearchTests.DefaultsRangeChecksAndStreaming;
const
  Props: array[0..9] of string = ('ShowFilterRow', 'FilterImmediate', 'ShowFilterBar',
    'FindPanel', 'IncrementalSearch', 'SortOnHeaderClick', 'ListFieldIndex', 'EditFormEditor',
    'EditFormRows', 'EditFormGroup');
var
  G, G2: TPPGDBGrid;
  C, C2: TPPGDBGridColumn;
  M: TMemoryStream;
  T: TStringStream;
  I: Integer;
begin
  G := TPPGDBGrid.Create(nil);
  M := TMemoryStream.Create;
  T := TStringStream.Create('');
  try
    CheckFalse(G.ShowFilterRow);
    CheckFalse(G.SortOnHeaderClick, 'DB-Grid: Sortieren ist Sache der Datenmenge');
    CheckEquals(0, G.SelectedCount);
    C := TPPGDBGridColumn(G.Columns.Add);
    C.FieldName := 'Name';
    CheckEquals(0, C.ListFieldIndex);
    CheckTrue(C.EditFormEditor = efeAuto);
    CheckEquals(3, C.EditFormRows);
    CheckEquals('', C.EditFormGroup);
    try
      C.EditFormRows := 0;
      Fail('EditFormRows 0');
    except
      on E: EPPGPropertyError do
        ;
    end;
    try
      C.EditFormRows := 21;
      Fail('EditFormRows 21');
    except
      on E: EPPGPropertyError do
        ;
    end;
    CheckEquals(3, C.EditFormRows, 'unveraendert');
    try
      C.ListFieldIndex := -1;
      Fail('ListFieldIndex -1');
    except
      on E: EPPGPropertyError do
        ;
    end;
    try
      C.ListFieldIndex := 32;
      Fail('ListFieldIndex 32');
    except
      on E: EPPGPropertyError do
        ;
    end;
    CheckEquals(0, C.ListFieldIndex, 'unveraendert');
    M.WriteComponent(G);
    M.Position := 0;
    ObjectBinaryToText(M, T);
    for I := 0 to High(Props) do
      CheckEquals(0, Pos(Props[I], T.DataString), 'Vorgabe nicht gespeichert: ' + Props[I]);
    G.ShowFilterRow := True;
    G.FilterImmediate := True;
    G.ShowFilterBar := True;
    G.FindPanel := fpmManual;
    G.IncrementalSearch := True;
    G.SortOnHeaderClick := True;
    C.ListFieldIndex := 2;
    C.EditFormEditor := efeMemo;
    C.EditFormRows := 5;
    C.EditFormGroup := 'Adresse';
    M.Clear;
    M.WriteComponent(G);
    M.Position := 0;
    G2 := TPPGDBGrid(M.ReadComponent(nil));
    try
      CheckTrue(G2.ShowFilterRow, 'ShowFilterRow');
      CheckTrue(G2.FilterImmediate, 'FilterImmediate');
      CheckTrue(G2.ShowFilterBar, 'ShowFilterBar');
      CheckTrue(G2.FindPanel = fpmManual, 'FindPanel');
      CheckTrue(G2.IncrementalSearch, 'IncrementalSearch');
      CheckTrue(G2.SortOnHeaderClick, 'SortOnHeaderClick');
      C2 := TPPGDBGridColumn(G2.Columns[0]);
      CheckEquals(2, C2.ListFieldIndex, 'ListFieldIndex');
      CheckTrue(C2.EditFormEditor = efeMemo, 'EditFormEditor');
      CheckEquals(5, C2.EditFormRows, 'EditFormRows');
      CheckEquals('Adresse', C2.EditFormGroup, 'EditFormGroup');
    finally
      G2.Free;
    end;
    // Assign uebernimmt die neuen Spalten-Properties
    C2 := TPPGDBGridColumn(G.Columns.Add);
    C2.Assign(C);
    CheckEquals(2, C2.ListFieldIndex);
    CheckEquals('Adresse', C2.EditFormGroup);
  finally
    T.Free;
    M.Free;
    G.Free;
  end;
end;

procedure TDBGridFilterSearchTests.FilterRowFiltersDataSet;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(20, []);
  G.ShowFilterRow := True;
  G.Filters[ColOf(G, 'ID')] := '>15';
  CheckEquals(5, FData.RecordCount, 'ID > 15');
  CheckTrue(FData.Filtered);
  G.Filters[ColOf(G, 'Name')] := 'name1';
  CheckEquals(4, FData.RecordCount, 'und Name enthaelt name1');
  G.ClearFilters;
  CheckEquals(20, FData.RecordCount);
  CheckFalse(FData.Filtered, 'ohne Filter: wie vorher');
  G.Filters[ColOf(G, 'Preis')] := '3..6';
  CheckEquals(3, FData.RecordCount, 'Preis zwischen 3 und 6 (Zahl)');
  G.Filters[ColOf(G, 'Preis')] := '';
  G.Filters[ColOf(G, 'Geboren')] := '<=' + DateToStr(EncodeDate(2000, 1, 4));
  CheckEquals(3, FData.RecordCount, 'Datum bis');
  G.Filters[ColOf(G, 'Geboren')] := DateToStr(EncodeDate(2000, 1, 6));
  CheckEquals(1, FData.RecordCount, 'Datum gleich');
  CheckEquals(5, FData.FieldByName('ID').AsInteger);
  G.Filters[ColOf(G, 'Geboren')] := '';
  G.Filters[ColOf(G, 'Aktiv')] := '=1';
  CheckEquals(10, FData.RecordCount, 'Kaestchen: 1 = an');
  G.Filters[ColOf(G, 'Aktiv')] := '';
  G.Filters[ColOf(G, 'ID')] := '*1*';
  CheckEquals(11, FData.RecordCount, 'Zahl mit Sternen: enthaelt');
  G.ClearFilters;
  FData.First;
  FData.Edit;
  FData.FieldByName('Notiz').Clear;
  FData.Post;
  G.Filters[ColOf(G, 'Notiz')] := '=';
  CheckEquals(1, FData.RecordCount, 'leer');
  G.Filters[ColOf(G, 'Notiz')] := '<>';
  CheckEquals(19, FData.RecordCount, 'nicht leer');
  G.ClearFilters;
  CheckEquals(20, FData.RecordCount);
end;

procedure TDBGridFilterSearchTests.FilterKeepsApplicationFilter;
var
  G: TPPGDBGrid;
  M: TFilterRecordEvent;
begin
  G := NewGrid(20, []);
  FData.OnFilterRecord := EvenOnly;
  FData.Filtered := True;
  CheckEquals(10, FData.RecordCount, 'Filter der Anwendung');
  G.Filters[ColOf(G, 'ID')] := '<=10';
  CheckEquals(5, FData.RecordCount, 'beide Filter');
  G.ClearFilters;
  CheckEquals(10, FData.RecordCount, 'wieder nur der der Anwendung');
  CheckTrue(FData.Filtered);
  M := FData.OnFilterRecord;
  CheckTrue(TMethod(M).Data = Pointer(Self), 'OnFilterRecord zurueck');
  // Filter-Text der Anwendung, nicht aktiv: bleibt aus und bleibt erhalten
  FData.Filtered := False;
  FData.OnFilterRecord := nil;
  FData.Filter := 'ID > 15';
  CheckEquals(20, FData.RecordCount);
  G.Filters[ColOf(G, 'ID')] := '<=10';
  CheckEquals(10, FData.RecordCount, 'nur der Grid-Filter');
  G.ClearFilters;
  CheckEquals('ID > 15', FData.Filter, 'Filter-Text zurueck');
  CheckFalse(FData.Filtered);
  CheckEquals(20, FData.RecordCount);
  // Freigabe des Grids bzw. DataSource = nil setzt die Datenmenge zurueck
  G.Filters[ColOf(G, 'ID')] := '>18';
  CheckEquals(2, FData.RecordCount);
  G.DataSource := nil;
  CheckFalse(FData.Filtered, 'DataSource = nil');
  CheckFalse(Assigned(FData.OnFilterRecord));
  CheckEquals(20, FData.RecordCount);
  G.DataSource := FSource;
  G.Filters[ColOf(G, 'ID')] := '>18';
  CheckEquals(2, FData.RecordCount);
  G.Free;
  CheckFalse(FData.Filtered, 'Grid freigegeben');
  CheckFalse(Assigned(FData.OnFilterRecord));
  CheckEquals('ID > 15', FData.Filter);
  CheckEquals(20, FData.RecordCount);
end;

procedure TDBGridFilterSearchTests.FilterRowEditorImmediate;
var
  G: TPPGDBGrid;
  P: TPoint;
  Ed: TPPGGridEdit;
begin
  FForm.Show; // der Editor braucht den Fokus
  try
    G := NewGrid(20, []);
    G.ShowFilterRow := True;
    G.FilterImmediate := True;
    G.ShowFilterBar := True;
    P := CenterOf(G.CellRect(G.VisualCol(ColOf(G, 'Name')), TDBGridAccess(G).VFixedRows - 1));
    G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P));
    G.Perform(WM_LBUTTONUP, 0, MouseLParam(P));
    CheckTrue(G.EditorMode, 'Editor in der Filterzeile');
    Ed := G.InplaceEditor as TPPGGridEdit;
    Ed.Text := 'name1';
    CheckEquals(11, FData.RecordCount, 'sofort gefiltert');
    CheckTrue(G.EditorMode, 'Editor bleibt offen');
    CheckTrue(TDBGridAccess(G).FilterBarHeight > 0, 'Filterleiste');
    Ed.Text := 'name2';
    CheckEquals(2, FData.RecordCount);
    G.EditorMode := False;
    CheckEquals('name2', G.Filters[ColOf(G, 'Name')]);
    CheckEquals(2, FData.RecordCount);
    CheckTrue(FData.State = dsBrowse, 'Datenmenge nicht bearbeitet');
    G.ClearFilters;
    CheckEquals(0, TDBGridAccess(G).FilterBarHeight);
  finally
    FForm.Hide;
  end;
end;

procedure TDBGridFilterSearchTests.FindPanelWalksDataSet;
var
  G: TPPGDBGrid;
  B: TBitmap;
begin
  G := NewGrid(30, []);
  G.FindPanel := fpmAlways;
  CheckTrue(G.FindPanelVisible);
  FData.First;
  G.FindText := 'name25';
  CheckTrue(G.FindNext);
  CheckEquals(25, FData.FieldByName('ID').AsInteger);
  CheckEquals(ColOf(G, 'Name'), G.DataCol(G.FocusCol), 'Fokus auf der Fundstelle');
  G.FindText := 'name2';
  FData.First;
  CheckTrue(G.FindNext);
  CheckEquals(2, FData.FieldByName('ID').AsInteger);
  CheckTrue(G.FindNext);
  CheckEquals(20, FData.FieldByName('ID').AsInteger);
  CheckTrue(G.FindPrevious);
  CheckEquals(2, FData.FieldByName('ID').AsInteger);
  CheckTrue(G.FindPrevious);
  CheckEquals(29, FData.FieldByName('ID').AsInteger, 'rueckwaerts im Kreis');
  B := RenderToBitmap(G);
  B.Free;
  G.FindText := '22,5';
  FData.First;
  CheckTrue(G.FindNext);
  CheckEquals(15, FData.FieldByName('ID').AsInteger, 'Preis 22,5');
  CheckEquals(ColOf(G, 'Preis'), G.DataCol(G.FocusCol));
  G.FindText := 'zzz';
  FData.RecNo := 7;
  CheckFalse(G.FindNext);
  CheckEquals(7, FData.FieldByName('ID').AsInteger, 'kein Treffer: Satz bleibt');
end;

procedure TDBGridFilterSearchTests.IncrementalSearchLocates;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(30, []);
  G.IncrementalSearch := True;
  G.Options := G.Options - [dgEditing];
  PPGSetTypeAheadClock(PPGTestClock);
  FData.First;
  G.Col := ColOf(G, 'Name');
  Press(G, 'name15');
  CheckEquals(15, FData.FieldByName('ID').AsInteger);
  CheckEquals('name15', G.IncrementalSearchText);
  PPGTestAdvanceClock(PPGTypeAheadMs + 100);
  Press(G, 'nAME7');
  CheckEquals(7, FData.FieldByName('ID').AsInteger, 'im Kreis, ohne Gross/klein');
  PPGTestAdvanceClock(PPGTypeAheadMs + 100);
  Press(G, 'x');
  CheckEquals(7, FData.FieldByName('ID').AsInteger, 'kein Treffer: Satz bleibt');
end;

procedure TDBGridFilterSearchTests.RowValueInCellStyleScreenAndPrint;
var
  G: TPPGDBGrid;
  St: TPPGGridCellStyle;
begin
  G := NewGrid(10, ['ID', 'Name', 'Aktiv']);
  G.OnGetCellStyle := StyleByAktiv;
  FData.First;
  CheckEquals(1, G.RowValue('ID'), 'ausserhalb: aktiver Satz');
  // Bildschirm: Pufferzeile 2 = Satz 3 (Aktiv), ohne Satzwechsel
  St := TDBGridAccess(G).CellStyle(ColOf(G, 'Name'), TDBGridAccess(G).FixedRows + 2, '');
  CheckEquals('3', FStyleIds[FStyleIds.Count - 1]);
  CheckEquals(clRed, St.Fill, 'Satz 3 ist aktiv');
  St := TDBGridAccess(G).CellStyle(ColOf(G, 'Name'), TDBGridAccess(G).FixedRows + 3, '');
  CheckEquals('4', FStyleIds[FStyleIds.Count - 1]);
  CheckTrue(St.Fill <> clRed);
  CheckEquals(1, FData.FieldByName('ID').AsInteger, 'Satz unveraendert');
  // Druck: Satz im Schnappschuss
  CheckEquals(10, TDBGridAccess(G).TableRowCount);
  St := TDBGridAccess(G).PrintCellStyle(0, 4, '');
  CheckEquals('5', FStyleIds[FStyleIds.Count - 1], 'Druck: Satz 5');
  CheckEquals(clRed, St.Fill);
  St := TDBGridAccess(G).PrintCellStyle(1, 7, '');
  CheckEquals('8', FStyleIds[FStyleIds.Count - 1]);
  CheckTrue(St.Fill <> clRed);
  try
    G.RowValue('GibtEsNicht');
    Fail('unbekanntes Feld');
  except
    on E: EPPGError do
      ;
  end;
end;

procedure TDBGridFilterSearchTests.MultiSelectHelpersAndVeto;
var
  G: TPPGDBGrid;
  Sum, N: Integer;
  V: TArray<Variant>;
begin
  G := NewGrid(10, []);
  Sum := 0;
  N := G.ForEachSelected(
    procedure(DataSet: TDataSet)
    begin
      Inc(Sum);
    end);
  CheckEquals(0, N, 'ohne dgMultiSelect');
  G.Options := G.Options + [dgMultiSelect];
  G.SelectedRows.SelectAll;
  CheckEquals(10, G.SelectedCount);
  FData.RecNo := 4;
  N := G.ForEachSelected(
    procedure(DataSet: TDataSet)
    begin
      Inc(Sum, DataSet.FieldByName('ID').AsInteger);
    end);
  CheckEquals(10, N);
  CheckEquals(55, Sum);
  CheckEquals(4, FData.RecNo, 'Satz danach wie vorher');
  V := G.SelectedValues('ID');
  CheckEquals(10, Length(V));
  CheckEquals(1, V[0]);
  CheckEquals(10, V[9]);
  try
    G.SelectedValues('GibtEsNicht');
    Fail('unbekanntes Feld');
  except
    on E: EPPGError do
      ;
  end;
  // Veto: nur gerade IDs
  G.SelectedRows.Clear;
  G.OnCanSelectRecord := EvenSelect;
  G.SelectedRows.SelectAll;
  CheckEquals(5, G.SelectedCount, 'SelectAll mit Veto');
  G.SelectedRows.Clear;
  FData.RecNo := 3;
  G.SelectedRows.CurrentRowSelected := True;
  CheckEquals(0, G.SelectedCount, 'Satz 3 abgelehnt');
  FData.RecNo := 4;
  G.SelectedRows.CurrentRowSelected := True;
  CheckEquals(1, G.SelectedCount);
  V := G.SelectedValues('Name');
  CheckEquals('Name4', VarToStr(V[0]));
end;

procedure TDBGridFilterSearchTests.FocusedRecordAndSelectCellVeto;
var
  G: TPPGDBGrid;
  K: Word;
begin
  G := NewGrid(10, ['ID', 'Name']);
  FData.First;
  G.OnFocusedRecordChanged := CountFocus;
  FFocusChanged := 0;
  FData.Next;
  CheckEquals(1, FFocusChanged, 'Next');
  FData.Next;
  CheckEquals(2, FFocusChanged);
  FData.Edit;
  FData.FieldByName('Name').AsString := 'Neu';
  FData.Post;
  CheckEquals(2, FFocusChanged, 'gleicher Satz: kein Ereignis');
  FData.Append;
  CheckEquals(3, FFocusChanged, 'neuer Satz');
  FData.Cancel;
  CheckEquals(4, FFocusChanged, 'zurueck');
  K := VK_UP;
  TDBGridAccess(G).KeyDown(K, []);
  CheckEquals(5, FFocusChanged, 'Taste');
  // OnSelectCell: Veto vor dem Satzwechsel, RowValue liest die Zielzeile
  G.OnSelectCell := RefuseId3;
  FData.First;
  CheckFalse(TDBGridAccess(G).SelectCell(ColOf(G, 'Name'), TDBGridAccess(G).FixedRows + 2),
    'Satz 3 abgelehnt');
  CheckEquals(1, FData.FieldByName('ID').AsInteger);
  CheckTrue(TDBGridAccess(G).SelectCell(ColOf(G, 'Name'), TDBGridAccess(G).FixedRows + 1));
  CheckEquals(2, FData.FieldByName('ID').AsInteger, 'Satz 2 erlaubt');
end;

procedure TDBGridFilterSearchTests.EditFormMemoDateAndGroups;
var
  G: TPPGDBGrid;
  P: TPPGDBGridEditForm;
  Memo: TPPGMemo;
  DP: TPPGDatePicker;
  ACell, ARow, ASpan: Integer;
begin
  G := NewGrid(10, ['ID', 'Name', 'Geboren', 'Notiz', 'Preis']);
  Column(G, 'Geboren').EditFormGroup := 'Daten';
  Column(G, 'Notiz').EditFormGroup := 'Daten';
  Column(G, 'Notiz').EditFormRows := 4;
  G.EditMode := dgeForm;
  FData.RecNo := 2;
  G.ShowEditForm;
  CheckTrue(G.EditFormActive);
  P := G.EditFormControl;
  CheckTrue(Editor(G, 'Notiz') is TPPGMemo, 'Memo-Feld: mehrzeilig');
  CheckTrue(Editor(G, 'Geboren') is TPPGDatePicker, 'Datumsfeld: Kalender');
  CheckTrue(Editor(G, 'Name') is TPPGGridEdit);
  Memo := TPPGMemo(Editor(G, 'Notiz'));
  DP := TPPGDatePicker(Editor(G, 'Geboren'));
  CheckEquals('Notiz 2', Memo.Text);
  CheckEquals(DateToStr(EncodeDate(2000, 1, 3)), DateToStr(DP.Date));
  // Raster: ID, Name | Ueberschrift "Daten" | Geboren, Notiz (4 Zeilen) | Preis
  CheckEquals(1, P.GroupCount);
  CheckEquals('Daten', P.GroupCaption(0));
  CheckEquals(1, P.GroupRow(0));
  P.ItemCell(ItemOf(G, 'Geboren'), ACell, ARow, ASpan);
  CheckEquals(0, ACell);
  CheckEquals(2, ARow);
  P.ItemCell(ItemOf(G, 'Notiz'), ACell, ARow, ASpan);
  CheckEquals(1, ACell);
  CheckEquals(2, ARow);
  CheckEquals(4, P.ItemRowSpan(ItemOf(G, 'Notiz')));
  P.ItemCell(ItemOf(G, 'Preis'), ACell, ARow, ASpan);
  CheckEquals(0, ACell, 'neuer Abschnitt (ohne Ueberschrift)');
  CheckEquals(6, ARow, 'unter dem mehrzeiligen Feld');
  // Masse bei 96 PPI: Editor 28, Zeilenabstand 6, Rand 10
  CheckEquals(4 * 28 + 3 * 6, Memo.Height, 'Memo ueber 4 Rasterzeilen');
  CheckEquals(10 + 1 * (28 + 6), P.GroupRect(0).Top, 'Ueberschrift in Zeile 1');
  // Enter im Memo ist ein Zeilenumbruch (das Formular faengt ihn nicht ab)
  CheckEquals(0, P.Perform(CM_CHILDKEY, VK_RETURN, LPARAM(Memo)), 'Enter im Memo');
  // Schreiben: Memo-Text und Datum
  Memo.Text := 'Zeile1'#13#10'Zeile2';
  DP.Date := EncodeDate(2020, 5, 6);
  CheckTrue(G.HideEditForm(True));
  CheckEquals('Zeile1'#13#10'Zeile2', FData.FieldByName('Notiz').AsString);
  CheckEquals(EncodeDate(2020, 5, 6), FData.FieldByName('Geboren').AsDateTime);
  // Kaestchen aus: Datum leer
  G.ShowEditForm;
  DP := TPPGDatePicker(Editor(G, 'Geboren'));
  CheckTrue(DP.ShowCheckbox, 'kein Pflichtfeld: leer erlaubt');
  DP.Checked := False;
  CheckTrue(G.HideEditForm(True));
  CheckTrue(FData.FieldByName('Geboren').IsNull, 'Datum geleert');
  // Editor per Spalte festlegen; Datum nur fuer Datumsfelder
  Column(G, 'Notiz').EditFormEditor := efeText;
  Column(G, 'Name').EditFormEditor := efeDate;
  G.ShowEditForm;
  CheckTrue(Editor(G, 'Notiz') is TPPGGridEdit, 'efeText');
  CheckTrue(Editor(G, 'Name') is TPPGGridEdit, 'efeDate an Textfeld: Text');
  Column(G, 'Name').EditFormEditor := efeMemo;
  CheckTrue(Editor(G, 'Name') is TPPGMemo, 'efeMemo an Textfeld');
  CheckTrue(G.HideEditForm(False));
end;

procedure TDBGridFilterSearchTests.LookupWithSeveralListFields;
var
  G: TPPGDBGrid;
  C: TPPGDBGridColumn;
  Combo: TPPGColumnComboBox;
  Names: TArray<string>;
begin
  FForm.Show; // der Editor braucht den Fokus
  try
    G := NewGrid(10, ['ID', 'Name']);
    MakeOrte;
    C := TPPGDBGridColumn(G.Columns.Add);
    C.FieldName := 'OrtID';
    C.ListSource := FOrteSource;
    C.KeyField := 'OrtID';
    C.ListField := 'Ort; PLZ';
    C.ListFieldIndex := 1;
    Names := C.ListFieldNames;
    CheckEquals(2, Length(Names));
    CheckEquals('PLZ', Names[1], 'ohne Leerzeichen');
    CheckEquals('PLZ', C.ListResultField, 'nach ListFieldIndex');
    CheckEquals('10003', C.LookupText(3));
    C.ListFieldIndex := 0;
    CheckEquals('Ort3', C.LookupText(3), 'Index geaendert: neu gelesen');
    C.ListFieldIndex := 5;
    CheckEquals('Ort', C.ListResultField, 'ausserhalb der Liste: erstes Feld');
    C.ListFieldIndex := 1;
    // Zell-Editor: mehrspaltige Auswahl, geschrieben wird der Schluessel
    FData.RecNo := 2; // OrtID = 3
    G.Col := ColOf(G, 'OrtID');
    G.EditorMode := True;
    CheckTrue(G.InplaceEditor is TPPGGridColumnCombo, 'mehrspaltige Auswahl');
    Combo := TPPGColumnComboBox(G.InplaceEditor);
    CheckEquals(3, Combo.Columns.Count, 'Schluessel + Ort + PLZ');
    CheckFalse(Combo.Columns[0].Visible, 'Schluessel ausgeblendet');
    CheckEquals(3, Combo.RowCount);
    CheckEquals('3', Combo.KeyValue);
    CheckEquals('10003', Combo.DisplayText);
    Combo.ItemIndex := 0;
    G.EditorMode := False;
    CheckEquals(1, FData.FieldByName('OrtID').AsInteger, 'Schluessel geschrieben');
    FData.Post;
    // Bearbeitungsformular: dieselbe Auswahl
    G.EditMode := dgeForm;
    G.ShowEditForm;
    CheckTrue(Editor(G, 'OrtID') is TPPGGridColumnCombo);
    Combo := TPPGColumnComboBox(Editor(G, 'OrtID'));
    CheckEquals('1', Combo.KeyValue);
    Combo.ItemIndex := 1;
    CheckTrue(G.HideEditForm(True));
    CheckEquals(2, FData.FieldByName('OrtID').AsInteger, 'Formular schreibt den Schluessel');
    // Ein Listenfeld: einfache Auswahlliste wie bisher
    C.ListField := 'Ort';
    G.ShowEditForm;
    CheckFalse(Editor(G, 'OrtID') is TPPGColumnComboBox, 'ein Feld: Auswahlliste');
    CheckTrue(G.HideEditForm(False));
  finally
    FForm.Hide;
  end;
end;

procedure TDBGridFilterSearchTests.LayoutSaveLoadAndSortIndicator;
var
  G, G2: TPPGDBGrid;
  S: string;
begin
  G := NewGrid(10, ['ID', 'Name', 'Preis', 'Aktiv']);
  G.OnSorted := CountSorted;
  G.ColWidths[ColOf(G, 'Name')] := 150;
  G.MoveColumn(G.VisualCol(ColOf(G, 'Preis')), G.VisualCol(ColOf(G, 'ID')));
  Column(G, 'Aktiv').Visible := False;
  // Kopfklick: Pfeil nur mit SortOnHeaderClick (die Datenmenge sortiert die Anwendung)
  TDBGridAccess(G).HeaderClicked(ColOf(G, 'Name'), 0);
  CheckEquals(-1, G.SortColumn, 'ohne SortOnHeaderClick kein Pfeil');
  G.SortOnHeaderClick := True;
  TDBGridAccess(G).HeaderClicked(ColOf(G, 'Name'), 0);
  CheckEquals(ColOf(G, 'Name'), G.SortColumn);
  CheckTrue(G.SortAscending);
  CheckEquals(1, FSorted, 'OnSorted');
  TDBGridAccess(G).HeaderClicked(ColOf(G, 'Name'), 0);
  CheckFalse(G.SortAscending, 'zweiter Klick: absteigend');
  FData.First;
  CheckEquals('1', TDBGridAccess(G).GetCellText(ColOf(G, 'ID'), TDBGridAccess(G).FixedRows),
    'Puffer nicht umsortiert');
  S := G.SaveLayout;
  CheckTrue(Pos('Name', S) > 0, 'Schluessel = Feldname');
  // Andere Spalten-Reihenfolge im zweiten Grid: Layout ueber die Feldnamen
  G2 := TPPGDBGrid.Create(FForm);
  G2.Parent := FForm;
  ForcePPI96(G2);
  G2.SetBounds(0, 0, 640, 400);
  TPPGDBGridColumn(G2.Columns.Add).FieldName := 'Aktiv';
  TPPGDBGridColumn(G2.Columns.Add).FieldName := 'Name';
  TPPGDBGridColumn(G2.Columns.Add).FieldName := 'ID';
  TPPGDBGridColumn(G2.Columns.Add).FieldName := 'Preis';
  G2.DataSource := FSource;
  G2.LoadLayout(S);
  CheckEquals(150, G2.ColWidths[ColOf(G2, 'Name')], 'Breite');
  CheckEquals(ColOf(G2, 'Preis'), G2.DataCol(TDBGridAccess(G2).FixedCols), 'Preis vorn');
  CheckFalse(Column(G2, 'Aktiv').Visible, 'ausgeblendet');
  CheckEquals(ColOf(G2, 'Name'), G2.SortColumn, 'Sortierpfeil');
  CheckFalse(G2.SortAscending);
end;

initialization
  RegisterTest('GridFilterSearch', TGridFilterParseTests.Suite);
  RegisterTest('GridFilterSearch', TGridFilterSearchTests.Suite);
  RegisterTest('GridFilterSearch', TDBGridFilterSearchTests.Suite);

end.
