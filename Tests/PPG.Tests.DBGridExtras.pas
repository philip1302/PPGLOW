unit PPG.Tests.DBGridExtras;

{ Tests fuer Erweiterungen von Grid und DB-Grid: Lesezeichen in Masse
  (SelectedRows.AddBookmarks, BeginUpdate/EndUpdate), Lage der Ansicht
  (TopRow, ActiveRowInView), Zeilenhoehe nach Inhalt (WordWrap,
  AutoRowHeights, MaxRowLines), eigener Spaltenkopf (OnDrawColumnTitle),
  HitTest und eingefrorene Datenspalten (FrozenCols).

  Daten: Cells bzw. OnGetCellText im Grid, TClientDataSet im Speicher im
  DB-Grid (synthetische Werte). }

interface

uses
  TestFramework, Winapi.Windows, System.Classes, System.SysUtils, System.Types,
  System.Math, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids, Vcl.DBGrids,
  Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Controls.Scroll, PPG.Grid.Columns, PPG.Grid, PPG.DB.Grid,
  PPG.Tests.Controls, PPG.Tests.Phase9c;

type
  TGridExtrasTests = class(TControlTestCase)
  private
    FTitleCalls: Integer;
    FTitleCol: Integer;
    FTitleColumn: TPPGGridColumn;
    FTitleRect: TRect;
    FTitleState: TGridDrawState;
    FTitleDefault: Boolean;
    FMinRow, FMaxRow: Integer;
    function NewGrid(Cols, Rows: Integer): TPPGGrid;
    procedure TitleHook(Sender: TObject; ACanvas: TCanvas; const Rect: TRect;
      ACol: Integer; Column: TPPGGridColumn; State: TGridDrawState;
      var DefaultDraw: Boolean);
    procedure VirtualText(Sender: TObject; ACol, ARow: Integer; var Text: string);
    function DiffPixels(A, B: TBitmap; const R: TRect): Integer;
    procedure Paint(G: TPPGGrid);
  published
    procedure DefaultsLeaveLayoutUnchanged;
    procedure TopRowReadsAndScrolls;
    procedure HitTestReportsAreas;
    procedure DrawColumnTitleEvent;
    procedure DrawColumnTitleKeepsSortArrow;
    procedure AutoRowHeightsWrapText;
    procedure AutoRowHeightsMeasureOnlyVisibleRows;
    procedure FrozenColsStayOnHorizontalScroll;
  end;

  TDBGridExtrasTests = class(TDBTestCase)
  private
    FChanges: Integer;
    FVeto: Integer;
    FTitleCols: TStringList;
    function NewGrid(Multi: Boolean = True): TPPGDBGrid;
    procedure CountChange(Sender: TObject);
    procedure VetoSelect(Sender: TObject; var Allow: Boolean);
    procedure TitleHook(Sender: TObject; ACanvas: TCanvas; const Rect: TRect;
      ACol: Integer; Column: TPPGGridColumn; State: TGridDrawState;
      var DefaultDraw: Boolean);
    function BookmarkOf(RecNo: Integer): TBookmark;
    function CurID: Integer;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure AddBookmarksInOneStep;
    procedure AddBookmarksRespectsVetoAndOption;
    procedure PublicBeginUpdateCollectsChanges;
    procedure ActiveRowInViewRestoresView;
    procedure ActiveRowInViewGrouped;
    procedure AutoRowHeightsFitBuffer;
    procedure HitTestAndTitleUseColumnIndex;
    procedure FrozenColsAfterIndicator;
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

function Center(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

const
  LongText = 'aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll';

{ TGridExtrasTests }

function TGridExtrasTests.NewGrid(Cols, Rows: Integer): TPPGGrid;
var
  I: Integer;
begin
  Result := TPPGGrid.Create(FForm);
  Result.Parent := FForm;
  ForcePPI96(Result);
  Result.BorderStyle := bsNone;
  Result.ScrollBarMode := sbmNever;
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.SetBounds(0, 0, 360, 24 * 9);
  Result.HandleNeeded;
  Result.FixedCols := 0;
  Result.ColCount := Cols;
  for I := 0 to Cols - 1 do
    Result.Columns.Add.Title := 'Titel' + IntToStr(I);
  Result.RowCount := Rows;
  for I := 1 to Rows - 1 do
    if I < 200 then
    begin
      Result.Cells[0, I] := 'Z' + IntToStr(I);
      if Cols > 1 then
        Result.Cells[1, I] := 'kurz';
    end;
end;

procedure TGridExtrasTests.TitleHook(Sender: TObject; ACanvas: TCanvas; const Rect: TRect;
  ACol: Integer; Column: TPPGGridColumn; State: TGridDrawState; var DefaultDraw: Boolean);
begin
  Inc(FTitleCalls);
  if ACol = 0 then
  begin
    FTitleCol := ACol;
    FTitleColumn := Column;
    FTitleRect := Rect;
    FTitleState := State;
  end;
  CheckNotNull(ACanvas, 'Canvas');
  DefaultDraw := FTitleDefault;
end;

procedure TGridExtrasTests.VirtualText(Sender: TObject; ACol, ARow: Integer; var Text: string);
begin
  if ARow = 0 then
    Exit;
  if ACol = 1 then
  begin
    FMinRow := Min(FMinRow, ARow);
    FMaxRow := Max(FMaxRow, ARow);
    if Odd(ARow) then
      Text := LongText
    else
      Text := 'kurz';
  end
  else
    Text := IntToStr(ARow);
end;

function TGridExtrasTests.DiffPixels(A, B: TBitmap; const R: TRect): Integer;
var
  X, Y: Integer;
begin
  Result := 0;
  for Y := R.Top to R.Bottom - 1 do
    for X := R.Left to R.Right - 1 do
      if A.Canvas.Pixels[X, Y] <> B.Canvas.Pixels[X, Y] then
        Inc(Result);
end;

procedure TGridExtrasTests.Paint(G: TPPGGrid);
begin
  // Gemessen wird beim Zeichnen (das Formular ist unsichtbar)
  RenderToBitmap(G).Free;
end;

procedure TGridExtrasTests.DefaultsLeaveLayoutUnchanged;
var
  G: TPPGGrid;
  R1, R2: TRect;
begin
  G := NewGrid(2, 20);
  CheckEquals(0, G.FrozenCols, 'FrozenCols');
  CheckFalse(G.AutoRowHeights, 'AutoRowHeights');
  CheckEquals(0, G.MaxRowLines, 'MaxRowLines');
  CheckFalse(G.Columns[1].WordWrap, 'WordWrap');
  CheckFalse(Assigned(G.OnDrawColumnTitle));
  G.Cells[1, 1] := LongText;
  G.ColWidths[1] := 60;
  R1 := G.CellRect(1, 1);
  // WordWrap allein aendert die Hoehe nicht (erst mit AutoRowHeights)
  G.Columns[1].WordWrap := True;
  Paint(G);
  R2 := G.CellRect(1, 1);
  CheckEquals(R1.Height, R2.Height, 'ohne AutoRowHeights gleiche Hoehe');
  CheckEquals(24, R2.Height, 'Standardhoehe');
  CheckEquals(1, G.TopRow, 'oberste Zeile = erste Datenzeile');
end;

procedure TGridExtrasTests.TopRowReadsAndScrolls;
var
  G: TPPGGrid;
  HeadBottom: Integer;
begin
  G := NewGrid(2, 101);
  HeadBottom := G.CellRect(0, 0).Bottom;
  CheckEquals(1, G.TopRow);
  G.TopRow := 30;
  CheckEquals(30, G.TopRow, 'gesetzt');
  CheckEquals(HeadBottom, G.CellRect(0, 30).Top, 'Zeile 30 steht oben');
  G.TopRow := 0;
  CheckEquals(1, G.TopRow, 'Kopfzeile ist keine scrollende Zeile');
  G.TopRow := 100000;
  CheckTrue(G.TopRow < 100, 'am Ende begrenzt');
  CheckTrue(G.TopRow > 80, 'ganz unten');
  CheckTrue(G.CellRect(0, 100).Bottom <= G.ClientHeight, 'letzte Zeile ganz sichtbar');
  G.TopRow := 5;
  CheckEquals(5, G.TopRow, 'zurueck');
end;

procedure TGridExtrasTests.HitTestReportsAreas;
var
  G: TPPGGrid;
  H: TPPGGridHitInfo;
  P: TPoint;
  R: TRect;
begin
  G := NewGrid(3, 20);
  // Kopf der zweiten Spalte
  H := G.HitTest(Center(G.CellRect(1, 0)).X, Center(G.CellRect(1, 0)).Y);
  CheckTrue(H.Area = ghaHeader, 'Kopf');
  CheckEquals(1, H.ColumnIndex, 'Kopf: Spalte');
  CheckEquals(0, H.DataRow, 'Kopf: Zeile');
  CheckTrue(H.Column = G.Columns[1], 'Kopf: Column');
  // Datenzelle
  P := Center(G.CellRect(2, 4));
  H := G.HitTest(P.X, P.Y);
  CheckTrue(H.Area = ghaData, 'Daten');
  CheckEquals(2, H.VisCol);
  CheckEquals(2, H.DataCol);
  CheckEquals(2, H.ColumnIndex);
  CheckEquals(4, H.VisRow);
  CheckEquals(4, H.DataRow);
  CheckEquals(3, H.DataIndex, 'ohne Kopfzeile');
  // Nach Spaltentausch: Anzeige- und Datenspalte verschieden
  G.Columns[2].Index := 0;
  P := Center(G.CellRect(0, 4));
  H := G.HitTest(P.X, P.Y);
  CheckEquals(0, H.VisCol, 'Anzeige-Spalte');
  CheckTrue(H.Column = G.Columns[0], 'verschobene Spalte');
  // Unterhalb der letzten Zeile: nichts
  G.RowCount := 3;
  H := G.HitTest(10, G.ClientHeight - 3);
  CheckTrue(H.Area = ghaNone, 'leerer Bereich');
  CheckEquals(-1, H.DataRow);
  // Summenzeile: Spalte unter X
  G.ShowFooter := True;
  R := G.CellRect(1, 1);
  H := G.HitTest(Center(R).X, G.ClientHeight - 3);
  CheckTrue(H.Area = ghaFooter, 'Summenzeile');
  CheckEquals(1, H.VisCol, 'Summenzeile: Spalte');
  // Feste Spalte links
  G.ShowFooter := False;
  G.FixedCols := 1;
  P := Center(G.CellRect(0, 2));
  H := G.HitTest(P.X, P.Y);
  CheckTrue(H.Area = ghaFixedCol, 'feste Spalte');
  CheckEquals(2, H.DataRow);
end;

procedure TGridExtrasTests.DrawColumnTitleEvent;
var
  G: TPPGGrid;
  WithText, Without: TBitmap;
  R: TRect;
begin
  G := NewGrid(3, 10);
  G.OnDrawColumnTitle := TitleHook;
  FTitleDefault := True;
  WithText := RenderToBitmap(G);
  try
    CheckTrue(FTitleCalls >= 3, 'je Kopfzelle');
    CheckEquals(0, FTitleCol);
    CheckTrue(FTitleColumn = G.Columns[0], 'Column');
    R := G.CellRect(0, 0);
    CheckEquals(R.Left, FTitleRect.Left, 'Rect links');
    CheckEquals(R.Top, FTitleRect.Top, 'Rect oben');
    CheckEquals(R.Bottom, FTitleRect.Bottom, 'Rect unten');
    CheckTrue(gdFixed in FTitleState, 'gdFixed');
    FTitleDefault := False;
    Without := RenderToBitmap(G);
    try
      CheckTrue(DiffPixels(WithText, Without, R) > 10, 'Titeltext weggelassen');
      // Datenzellen bleiben gleich
      CheckEquals(0, DiffPixels(WithText, Without, G.CellRect(0, 2)), 'Daten unveraendert');
    finally
      Without.Free;
    end;
  finally
    WithText.Free;
  end;
end;

procedure TGridExtrasTests.DrawColumnTitleKeepsSortArrow;
var
  G: TPPGGrid;
  Plain, Sorted: TBitmap;
begin
  G := NewGrid(3, 10);
  G.OnDrawColumnTitle := TitleHook;
  FTitleDefault := False;
  Plain := RenderToBitmap(G);
  try
    G.SortBy(0, True);
    Sorted := RenderToBitmap(G);
    try
      CheckTrue(DiffPixels(Plain, Sorted, G.CellRect(0, 0)) > 0,
        'Sortierpfeil trotz DefaultDraw = False');
    finally
      Sorted.Free;
    end;
  finally
    Plain.Free;
  end;
end;

procedure TGridExtrasTests.AutoRowHeightsWrapText;
var
  G: TPPGGrid;
  Def, Full, Two: Integer;
begin
  G := NewGrid(2, 20);
  G.ColWidths[1] := 70;
  G.Cells[1, 2] := LongText;
  G.Columns[1].WordWrap := True;
  Def := G.CellRect(1, 1).Height;
  G.AutoRowHeights := True;
  Paint(G);
  Full := G.CellRect(1, 2).Height;
  CheckTrue(Full > 3 * Def div 2, Format('umgebrochen hoeher (%d)', [Full]));
  CheckEquals(Def, G.CellRect(1, 1).Height, 'kurzer Text: Standardhoehe');
  CheckEquals(Def, G.CellRect(1, 3).Height, 'Nachbarzeile');
  // Hoechstens zwei Textzeilen
  G.MaxRowLines := 2;
  Paint(G);
  Two := G.CellRect(1, 2).Height;
  CheckTrue(Two < Full, 'MaxRowLines begrenzt');
  CheckTrue(Two > Def, 'zwei Zeilen hoeher als eine');
  // Text geaendert: Zeile neu gemessen
  G.MaxRowLines := 0;
  G.Cells[1, 2] := 'kurz';
  Paint(G);
  CheckEquals(Def, G.CellRect(1, 2).Height, 'nach Textaenderung neu gemessen');
  G.Cells[1, 2] := LongText;
  Paint(G);
  CheckEquals(Full, G.CellRect(1, 2).Height, 'wieder hoch');
  // Aus: wieder Standardhoehe
  G.AutoRowHeights := False;
  Paint(G);
  CheckEquals(Def, G.CellRect(1, 2).Height, 'aus');
  G.AutoRowHeights := True;
  G.Columns[1].WordWrap := False;
  Paint(G);
  CheckEquals(Def, G.CellRect(1, 2).Height, 'ohne WordWrap nicht gemessen');
end;

procedure TGridExtrasTests.AutoRowHeightsMeasureOnlyVisibleRows;
var
  G: TPPGGrid;
  B: TBitmap;
  Def: Integer;
begin
  G := NewGrid(2, 2);
  G.ColWidths[1] := 70;
  G.Columns[1].WordWrap := True;
  G.OnGetCellText := VirtualText;
  G.RowCount := 100001;
  Def := G.CellRect(0, 2).Height;
  FMinRow := MaxInt;
  FMaxRow := -1;
  G.AutoRowHeights := True;
  B := RenderToBitmap(G);
  B.Free;
  CheckTrue(FMaxRow >= 1, 'gemessen');
  CheckTrue(FMaxRow < 100, Format('nur sichtbare Zeilen (%d)', [FMaxRow]));
  CheckTrue(G.CellRect(1, 1).Height > Def, 'ungerade Zeile hoch');
  CheckEquals(Def, G.CellRect(1, 2).Height, 'gerade Zeile Standard');
  FMinRow := MaxInt;
  FMaxRow := -1;
  G.TopRow := 50001;
  CheckEquals(50001, G.TopRow, 'oberste Zeile bleibt nach dem Messen');
  CheckTrue(G.CellRect(1, 50001).Height > Def, 'dort gemessen');
  CheckTrue(FMinRow > 49000, Format('ab der Ansicht (%d)', [FMinRow]));
  CheckTrue(FMaxRow < 50200, Format('bis zur Ansicht (%d)', [FMaxRow]));
end;

procedure TGridExtrasTests.FrozenColsStayOnHorizontalScroll;
var
  G: TPPGGrid;
  I, C, R: Integer;
  R0, R1: TRect;
  H: TPPGGridHitInfo;
begin
  G := NewGrid(8, 20);
  for I := 0 to 7 do
    G.ColWidths[I] := 100;
  // Ohne FrozenCols scrollt die erste Spalte weg
  R0 := G.CellRect(0, 1);
  G.MakeCellVisible(7, 1);
  CheckTrue(G.CellRect(0, 1).Left < R0.Left, 'ohne FrozenCols weg');
  G.MakeCellVisible(0, 1);
  CheckEquals(R0.Left, G.CellRect(0, 1).Left, 'zurueck');
  G.FrozenCols := 1;
  CheckEquals(1, G.FrozenCols);
  R1 := G.CellRect(1, 1);
  G.MakeCellVisible(7, 1);
  CheckEquals(R0.Left, G.CellRect(0, 1).Left, 'eingefroren: links');
  CheckEquals(R0.Right, G.CellRect(0, 1).Right, 'eingefroren: rechts');
  CheckTrue(G.CellRect(1, 1).Left < R1.Left, 'zweite Spalte scrollt');
  CheckTrue(G.CellRect(7, 1).Right <= G.ClientWidth, 'letzte Spalte sichtbar');
  CheckTrue(G.CellRect(7, 1).Left >= R0.Right, 'nicht unter der eingefrorenen');
  // Maus auf der eingefrorenen Spalte trifft sie, nicht die darunter
  CheckTrue(G.MouseCoord(Center(R0).X, Center(R0).Y, C, R), 'MouseCoord');
  CheckEquals(0, C, 'MouseCoord Spalte');
  CheckEquals(1, R, 'MouseCoord Zeile');
  H := G.HitTest(Center(R0).X, Center(R0).Y);
  CheckTrue(H.Area = ghaData, 'eingefroren bleibt Datenzelle');
  CheckEquals(0, H.ColumnIndex);
  CheckEquals(-1, G.HitTest(Center(R0).X, Center(R0).Y).Group);
  // Begrenzung: mindestens eine Spalte scrollt
  G.FrozenCols := 100;
  CheckEquals(100, G.FrozenCols, 'Wert bleibt');
  CheckTrue(G.CellRect(0, 1).Left = R0.Left, 'erste weiter links');
  G.FrozenCols := 0;
  G.MakeCellVisible(0, 1);
  CheckEquals(R0.Left, G.CellRect(0, 1).Left, 'aus');
end;

{ TDBGridExtrasTests }

procedure TDBGridExtrasTests.SetUp;
begin
  inherited SetUp;
  FChanges := 0;
  FVeto := 0;
  FTitleCols := TStringList.Create;
end;

procedure TDBGridExtrasTests.TearDown;
begin
  FreeAndNil(FTitleCols);
  inherited TearDown;
end;

function TDBGridExtrasTests.NewGrid(Multi: Boolean): TPPGDBGrid;
const
  Cols: array[0..5] of string = ('ID', 'Name', 'Aktiv', 'Geboren', 'Preis', 'OrtID');
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
  Result.SetBounds(0, 0, 420, 24 * 9); // Titel + 8 Datenzeilen
  Result.HandleNeeded;
  for I := 0 to High(Cols) do
    TPPGDBGridColumn(Result.Columns.Add).FieldName := Cols[I];
  if Multi then
    Result.Options := Result.Options + [dgMultiSelect];
  Result.DataSource := FSource;
end;

procedure TDBGridExtrasTests.CountChange(Sender: TObject);
begin
  Inc(FChanges);
end;

procedure TDBGridExtrasTests.VetoSelect(Sender: TObject; var Allow: Boolean);
begin
  Inc(FVeto);
  Allow := FData.FieldByName('ID').AsInteger <> 4;
end;

procedure TDBGridExtrasTests.TitleHook(Sender: TObject; ACanvas: TCanvas; const Rect: TRect;
  ACol: Integer; Column: TPPGGridColumn; State: TGridDrawState; var DefaultDraw: Boolean);
begin
  if Column <> nil then
    FTitleCols.Values[IntToStr(ACol)] := TPPGDBGridColumn(Column).FieldName
  else
    FTitleCols.Values[IntToStr(ACol)] := '-';
end;

function TDBGridExtrasTests.BookmarkOf(RecNo: Integer): TBookmark;
var
  Old: TBookmark;
begin
  Old := FData.Bookmark;
  FData.DisableControls;
  try
    FData.RecNo := RecNo;
    Result := FData.Bookmark;
    FData.Bookmark := Old;
  finally
    FData.EnableControls;
  end;
end;

function TDBGridExtrasTests.CurID: Integer;
begin
  Result := FData.FieldByName('ID').AsInteger;
end;

procedure TDBGridExtrasTests.AddBookmarksInOneStep;
var
  G: TPPGDBGrid;
  Arr: array of TBookmark;
  Before: Integer;
begin
  FillData(30);
  G := NewGrid;
  G.OnSelectionChanged := CountChange;
  FData.RecNo := 5;
  Before := TDBGridAccess(G).DataLink.ActiveRecord;
  SetLength(Arr, 6);
  Arr[0] := BookmarkOf(20);
  Arr[1] := BookmarkOf(2);
  Arr[2] := BookmarkOf(12);
  Arr[3] := BookmarkOf(2); // doppelt
  Arr[4] := nil;           // leer
  Arr[5] := BookmarkOf(25);
  CheckEquals(4, G.SelectedRows.AddBookmarks(Arr), 'neu aufgenommen');
  CheckEquals(4, G.SelectedRows.Count);
  CheckEquals(1, FChanges, 'OnSelectionChanged einmal');
  CheckEquals(5, CurID, 'Datenmenge nicht bewegt');
  CheckEquals(Before, TDBGridAccess(G).DataLink.ActiveRecord, 'Ansicht nicht verschoben');
  // Sortiert wie die Datenmenge (Find/IndexOf funktionieren)
  CheckTrue(G.SelectedRows.IndexOf(BookmarkOf(12)) >= 0, 'IndexOf');
  CheckTrue(G.SelectedRows.IndexOf(BookmarkOf(13)) < 0, 'nicht gewaehlt');
  FData.RecNo := 25;
  CheckTrue(G.SelectedRows.CurrentRowSelected, 'CurrentRowSelected');
  FData.RecNo := 5;
  // Nochmal: nichts neu, kein Ereignis
  CheckEquals(0, G.SelectedRows.AddBookmarks(Arr), 'schon gewaehlt');
  CheckEquals(1, FChanges, 'kein weiteres Ereignis');
  // Leeres Feld
  CheckEquals(0, G.SelectedRows.AddBookmarks([]), 'leer');
  CheckEquals(1, FChanges);
  // Mischung mit vorhandener Auswahl
  CheckEquals(1, G.SelectedRows.AddBookmarks([BookmarkOf(1), BookmarkOf(2)]), 'eins neu');
  CheckEquals(5, G.SelectedRows.Count);
  CheckEquals(2, FChanges);
end;

procedure TDBGridExtrasTests.AddBookmarksRespectsVetoAndOption;
var
  G: TPPGDBGrid;
begin
  FillData(10);
  G := NewGrid(False);
  G.OnSelectionChanged := CountChange;
  CheckEquals(0, G.SelectedRows.AddBookmarks([BookmarkOf(2), BookmarkOf(3)]),
    'ohne dgMultiSelect nichts');
  CheckEquals(0, G.SelectedRows.Count);
  CheckEquals(0, FChanges);
  G.Options := G.Options + [dgMultiSelect];
  G.OnCanSelectRecord := VetoSelect;
  FData.RecNo := 7;
  CheckEquals(2, G.SelectedRows.AddBookmarks([BookmarkOf(3), BookmarkOf(4), BookmarkOf(5)]),
    'Satz 4 abgelehnt');
  CheckEquals(3, FVeto, 'je Satz gefragt');
  CheckEquals(2, G.SelectedRows.Count);
  CheckTrue(G.SelectedRows.IndexOf(BookmarkOf(4)) < 0, 'abgelehnt nicht gewaehlt');
  CheckEquals(7, CurID, 'Datenmenge zurueck');
  CheckEquals(1, FChanges);
end;

procedure TDBGridExtrasTests.PublicBeginUpdateCollectsChanges;
var
  G: TPPGDBGrid;
begin
  FillData(10);
  G := NewGrid;
  G.OnSelectionChanged := CountChange;
  G.SelectedRows.BeginUpdate;
  try
    CheckTrue(G.SelectedRows.AddBookmark(BookmarkOf(2)));
    CheckTrue(G.SelectedRows.AddBookmark(BookmarkOf(6)));
    CheckFalse(G.SelectedRows.AddBookmark(BookmarkOf(6)), 'doppelt');
    CheckEquals(1, G.SelectedRows.AddBookmarks([BookmarkOf(8)]));
    CheckTrue(G.SelectedRows.RemoveBookmark(BookmarkOf(2)));
    CheckEquals(0, FChanges, 'waehrend BeginUpdate kein Ereignis');
  finally
    G.SelectedRows.EndUpdate;
  end;
  CheckEquals(1, FChanges, 'einmal am Ende');
  CheckEquals(2, G.SelectedRows.Count);
  // Ohne Aenderung kein Ereignis
  G.SelectedRows.BeginUpdate;
  G.SelectedRows.EndUpdate;
  CheckEquals(1, FChanges);
end;

procedure TDBGridExtrasTests.ActiveRowInViewRestoresView;
var
  G: TPPGDBGrid;
  B: TBookmark;
  P, Sum: Integer;
begin
  FillData(60);
  G := NewGrid(False);
  CheckEquals(0, G.ActiveRowInView, 'erster Satz oben');
  CheckEquals(TDBGridAccess(G).FixedRows, G.TopRow, 'ungruppiert: TopRow = erste Datenzeile');
  FData.RecNo := 30;
  G.ActiveRowInView := 3;
  CheckEquals(3, G.ActiveRowInView, 'gesetzt');
  CheckEquals(30, CurID, 'Satz bleibt');
  P := G.ActiveRowInView;
  // Eigener Durchlauf verschiebt den Puffer
  B := FData.Bookmark;
  Sum := 0;
  FData.DisableControls;
  try
    FData.First;
    while not FData.Eof do
    begin
      Inc(Sum, FData.FieldByName('ID').AsInteger);
      FData.Next;
    end;
    FData.Bookmark := B;
  finally
    FData.EnableControls;
  end;
  CheckEquals(60 * 61 div 2, Sum);
  G.ActiveRowInView := P;
  CheckEquals(3, G.ActiveRowInView, 'Ansicht wiederhergestellt');
  CheckEquals(30, CurID);
  // Oberste Zeile zeigt Satz 27
  CheckEquals('27', TDBGridAccess(G).GetCellText(TDBGridAccess(G).FixedCols,
    TDBGridAccess(G).FixedRows), 'oberste Zeile');
  // Grenzen: am Anfang so nah wie moeglich
  FData.RecNo := 2;
  G.ActiveRowInView := 5;
  CheckEquals(1, G.ActiveRowInView, 'am Anfang begrenzt');
  FData.RecNo := 40;
  G.ActiveRowInView := 0;
  CheckEquals(0, G.ActiveRowInView, 'ganz oben');
  FData.RecNo := 59;
  G.ActiveRowInView := 0;
  CheckEquals(6, G.ActiveRowInView, 'am Ende begrenzt (60 Saetze)');
  CheckEquals(59, CurID);
  G.ActiveRowInView := 100;
  CheckEquals(7, G.ActiveRowInView, 'unten begrenzt');
  // Waehrend der Bearbeitung unveraendert
  FData.Edit;
  G.ActiveRowInView := 2;
  CheckEquals(7, G.ActiveRowInView, 'nicht in dsEdit');
  FData.Cancel;
end;

procedure TDBGridExtrasTests.ActiveRowInViewGrouped;
var
  G: TPPGDBGrid;
  I: Integer;
begin
  FillData(60);
  G := NewGrid(False);
  for I := 0 to G.Columns.Count - 1 do
    if SameText(TPPGDBGridColumn(G.Columns[I]).FieldName, 'OrtID') then
      G.Columns[I].GroupIndex := 0;
  FData.RecNo := 40;
  CheckEquals(40, CurID);
  G.ActiveRowInView := 2;
  CheckEquals(2, G.ActiveRowInView, 'gruppiert gesetzt');
  CheckEquals(40, CurID, 'Satz bleibt');
  I := G.TopRow;
  G.TopRow := I + 1;
  CheckEquals(1, G.ActiveRowInView, 'folgt TopRow');
end;

procedure TDBGridExtrasTests.AutoRowHeightsFitBuffer;
var
  G: TPPGDBGrid;
  C: TPPGDBGridColumn;
  N, I, Def, VR: Integer;
  GA: TDBGridAccess;
begin
  FillData(40);
  FData.RecNo := 2;
  FData.Edit;
  FData.FieldByName('Name').AsString := 'aaa bbb ccc ddd eee';
  FData.Post;
  FData.First;
  G := NewGrid(False);
  GA := TDBGridAccess(G);
  G.Columns.Clear;
  TPPGDBGridColumn(G.Columns.Add).FieldName := 'ID';
  C := TPPGDBGridColumn(G.Columns.Add);
  C.FieldName := 'Name';
  C.Width := 60;
  C.WordWrap := True;
  CheckEquals(8, GA.RowCount - GA.FixedRows, 'acht Saetze im Puffer');
  Def := G.CellRect(GA.FixedCols, GA.VisualRow(GA.FixedRows)).Height;
  G.AutoRowHeights := True;
  N := GA.RowCount - GA.FixedRows;
  CheckTrue(N < 8, Format('weniger Saetze (%d)', [N]));
  CheckTrue(N >= 5, Format('nur eine Zeile hoch (%d)', [N]));
  CheckTrue(G.CellRect(GA.FixedCols, GA.VisualRow(GA.FixedRows + 1)).Height > 3 * Def div 2,
    'Satz 2 hoch');
  CheckEquals(Def, G.CellRect(GA.FixedCols, GA.VisualRow(GA.FixedRows)).Height, 'Satz 1');
  for I := 0 to N - 1 do
  begin
    VR := GA.VisualRow(GA.FixedRows + I);
    CheckTrue(G.CellRect(GA.FixedCols, VR).Bottom <= G.ClientHeight,
      Format('Zeile %d ganz sichtbar', [I]));
  end;
  // Ans Ende: kurze Saetze, Puffer waechst wieder
  FData.Last;
  N := GA.RowCount - GA.FixedRows;
  CheckEquals(8, N, 'am Ende wieder acht');
  CheckEquals(N - 1, G.ActiveRowInView, 'letzter Satz unten');
  FData.RecNo := 2;
  N := GA.RowCount - GA.FixedRows;
  CheckTrue(N < 8, 'wieder weniger');
  VR := GA.VisualRow(GA.FixedRows + G.ActiveRowInView);
  CheckTrue(G.CellRect(GA.FixedCols, VR).Bottom <= G.ClientHeight, 'aktiver Satz ganz sichtbar');
  CheckEquals(2, CurID);
  // Hoechstens eine Zeile: Standardhoehe, acht Saetze
  G.MaxRowLines := 1;
  CheckEquals(8, GA.RowCount - GA.FixedRows, 'MaxRowLines = 1');
  G.MaxRowLines := 0;
  G.AutoRowHeights := False;
  CheckEquals(8, GA.RowCount - GA.FixedRows, 'aus: acht');
  CheckEquals(Def, G.CellRect(GA.FixedCols, GA.VisualRow(GA.FixedRows + 1)).Height, 'aus: Standard');
end;

procedure TDBGridExtrasTests.HitTestAndTitleUseColumnIndex;
var
  G: TPPGDBGrid;
  GA: TDBGridAccess;
  H: TPPGGridHitInfo;
  P: TPoint;
  B: TBitmap;
begin
  FillData(5);
  G := NewGrid(False);
  GA := TDBGridAccess(G);
  CheckEquals(1, GA.FixedCols, 'Indikator');
  // Indikator
  P := Center(G.CellRect(0, GA.VisualRow(GA.FixedRows + 2)));
  H := G.HitTest(P.X, P.Y);
  CheckTrue(H.Area = ghaFixedCol, 'Indikator');
  CheckEquals(-1, H.ColumnIndex, 'Indikator ohne Spalte');
  CheckEquals(2, H.DataIndex, 'Pufferzeile');
  // Zweite Datenspalte
  P := Center(G.CellRect(GA.FixedCols + 1, GA.VisualRow(GA.FixedRows + 3)));
  H := G.HitTest(P.X, P.Y);
  CheckTrue(H.Area = ghaData, 'Daten');
  CheckEquals(1, H.ColumnIndex, 'Index in Columns');
  CheckEquals(3, H.DataIndex, 'Pufferzeile');
  CheckTrue(H.Column = G.Columns[1], 'Column');
  CheckEquals('Name', TPPGDBGridColumn(H.Column).FieldName);
  // Kopf
  P := Center(G.CellRect(GA.FixedCols, 0));
  H := G.HitTest(P.X, P.Y);
  CheckTrue(H.Area = ghaHeader, 'Kopf');
  CheckEquals(0, H.ColumnIndex);
  // Leere Zeilen unter den Saetzen: kein Satz
  H := G.HitTest(P.X, G.ClientHeight - 3);
  CheckTrue(H.Area = ghaNone, 'leere Zeile');
  // OnDrawColumnTitle: ACol = Index in Columns
  G.OnDrawColumnTitle := TitleHook;
  B := RenderToBitmap(G);
  B.Free;
  CheckEquals('ID', FTitleCols.Values['0'], 'Spalte 0');
  CheckEquals('Name', FTitleCols.Values['1'], 'Spalte 1');
  CheckEquals('', FTitleCols.Values['-1'], 'Indikator ohne Ereignis');
end;

procedure TDBGridExtrasTests.FrozenColsAfterIndicator;
var
  G: TPPGDBGrid;
  GA: TDBGridAccess;
  I, VR: Integer;
  R0, RInd: TRect;
begin
  FillData(10);
  G := NewGrid(False);
  GA := TDBGridAccess(G);
  for I := 0 to G.Columns.Count - 1 do
    G.Columns[I].Width := 120;
  G.FrozenCols := 1;
  VR := GA.VisualRow(GA.FixedRows);
  RInd := G.CellRect(0, VR);
  R0 := G.CellRect(GA.FixedCols, VR);
  G.MakeCellVisible(GA.FixedCols + G.Columns.Count - 1, VR);
  CheckEquals(RInd.Left, G.CellRect(0, VR).Left, 'Indikator bleibt');
  CheckEquals(R0.Left, G.CellRect(GA.FixedCols, VR).Left, 'erste Datenspalte bleibt');
  CheckTrue(G.CellRect(GA.FixedCols + 1, VR).Left < R0.Right, 'zweite scrollt');
  CheckEquals(0, G.HitTest(Center(R0).X, Center(R0).Y).ColumnIndex, 'HitTest');
end;

initialization
  RegisterTest('DBGridExtras', TGridExtrasTests.Suite);
  RegisterTest('DBGridExtras', TDBGridExtrasTests.Suite);
end.
