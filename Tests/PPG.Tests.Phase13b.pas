unit PPG.Tests.Phase13b;

{ Tests fuer Phase 13b: Spalten des Grids - verschieben, ausblenden, Breite
  automatisch, rechts fixieren, Baender, Kopfmenue, Layout speichern/laden. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids, Vcl.Menus,
  PPG.Types, PPG.UIA, PPG.Grid, PPG.Grid.Columns, PPG.Grid.Data, PPG.Tests.Controls;

type
  TGridColumnTests = class(TControlTestCase)
  private
    FMoves: Integer;
    FMoveFrom, FMoveTo: Integer;
    FMenuCol: Integer;
    procedure ColumnMoved(Sender: TObject; FromIndex, ToIndex: Longint);
    procedure HeaderMenu(Sender: TObject; ACol: Integer; Menu: TPopupMenu);
    function NewGrid: TPPGGrid;
    /// 1 feste + 4 Spalten "A".."D", 5 Datenzeilen.
    function SampleGrid: TPPGGrid;
    function Row1(G: TPPGGrid): string;
    function MenuItem(M: TPopupMenu; const Caption: string): TMenuItem;
  protected
    procedure SetUp; override;
  published
    procedure DefaultsAreIdentity;
    procedure MoveColumnChangesDisplayOnly;
    procedure MoveKeepsFocusOnDataColumn;
    procedure MoveNotAllowedForFixedOrWithoutColumns;
    procedure HideColumn;
    procedure LastVisibleColumnStays;
    procedure DragHeaderMovesColumn;
    procedure DragWithoutOptionSorts;
    procedure AutoSizeFitsText;
    procedure AutoSizeSamplesManyRows;
    procedure DoubleClickEdgeAutoSizes;
    procedure FixedColsRightStayAtEdge;
    procedure BandsShiftCells;
    procedure BandLevels;
    procedure HeaderMenuItems;
    procedure HeaderMenuHidesAndShows;
    procedure LayoutRoundTrip;
    procedure LayoutIgnoresUnknown;
    procedure DfmKeepsColumnState;
    procedure ExportFollowsDisplay;
    procedure UiaUsesDataColumn;
  end;

implementation

uses
  PPG.Menus;

type
  TGridAccess = class(TPPGGrid);

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := MakeLParam(Word(SmallInt(X)), Word(SmallInt(Y)));
end;

function CenterOf(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

{ TGridColumnTests }

procedure TGridColumnTests.SetUp;
begin
  inherited SetUp;
  // Zaehler je Test (der Leak-Lauf startet die Tests zweimal)
  FMoves := 0;
  FMenuCol := -1;
end;

procedure TGridColumnTests.ColumnMoved(Sender: TObject; FromIndex, ToIndex: Longint);
begin
  Inc(FMoves);
  FMoveFrom := FromIndex;
  FMoveTo := ToIndex;
end;

procedure TGridColumnTests.HeaderMenu(Sender: TObject; ACol: Integer; Menu: TPopupMenu);
var
  It: TMenuItem;
begin
  FMenuCol := ACol;
  It := TMenuItem.Create(Menu);
  It.Caption := 'Eigener Eintrag';
  Menu.Items.Add(It);
end;

function TGridColumnTests.NewGrid: TPPGGrid;
begin
  Result := TPPGGrid.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 400, 240);
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.HandleNeeded;
end;

function TGridColumnTests.SampleGrid: TPPGGrid;
var
  C, R: Integer;
begin
  Result := NewGrid;
  Result.Columns.Add.Title := '#';
  for C := 1 to 4 do
    Result.Columns.Add.Title := Chr(Ord('A') + C - 1);
  Result.FixedCols := 1; // Columns.Add setzt ColCount kurz auf 1 (FixedCols -> 0)
  Result.RowCount := 6;
  for R := 1 to 5 do
  begin
    Result.Cells[0, R] := IntToStr(R);
    for C := 1 to 4 do
      Result.Cells[C, R] := Chr(Ord('A') + C - 1) + IntToStr(R);
  end;
  Result.OnColumnMoved := ColumnMoved;
end;

function TGridColumnTests.Row1(G: TPPGGrid): string;
var
  T: IPPGTableSource;
  C: Integer;
begin
  // Erste Datenzeile in Anzeige-Reihenfolge (ueber die Export-Schnittstelle)
  Result := '';
  Supports(G, IPPGTableSource, T);
  for C := 0 to T.TableColCount - 1 do
  begin
    if C > 0 then
      Result := Result + ',';
    Result := Result + T.TableCellText(C, 0);
  end;
end;

function ByTag(M: TPopupMenu; ATag: Integer): TMenuItem;
var
  I: Integer;
begin
  for I := 0 to M.Items.Count - 1 do
    if M.Items[I].Tag = ATag then
      Exit(M.Items[I]);
  raise Exception.CreateFmt('Eintrag %d fehlt', [ATag]);
end;

/// Spaltenauswahl = einziger Eintrag mit Untermenue.
function Chooser(M: TPopupMenu): TMenuItem;
var
  I: Integer;
begin
  for I := 0 to M.Items.Count - 1 do
    if M.Items[I].Count > 0 then
      Exit(M.Items[I]);
  raise Exception.Create('Spaltenauswahl fehlt');
end;

function TGridColumnTests.MenuItem(M: TPopupMenu; const Caption: string): TMenuItem;
var
  I: Integer;
begin
  for I := 0 to M.Items.Count - 1 do
    if M.Items[I].Caption = Caption then
      Exit(M.Items[I]);
  Result := nil;
end;

procedure TGridColumnTests.DefaultsAreIdentity;
var
  G: TPPGGrid;
  I: Integer;
begin
  G := SampleGrid;
  CheckEquals(5, G.VisibleColCount);
  for I := 0 to 4 do
  begin
    CheckEquals(I, G.DataCol(I));
    CheckEquals(I, G.VisualCol(I));
  end;
  CheckEquals(-1, G.DataCol(5));
  CheckEquals(-1, G.VisualCol(-1));
  CheckEquals('1,A1,B1,C1,D1', Row1(G));
  CheckEquals(0, G.FixedColsRight);
  CheckTrue(G.HeaderMenu);
  CheckEquals(-1, G.Columns[1].DisplayIndex);
  CheckTrue(G.Columns[1].Visible);
end;

procedure TGridColumnTests.MoveColumnChangesDisplayOnly;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.MoveColumn(1, 3); // A hinter C
  CheckEquals('1,B1,C1,A1,D1', Row1(G));
  CheckEquals(1, FMoves, 'OnColumnMoved');
  CheckEquals(1, FMoveFrom);
  CheckEquals(3, FMoveTo);
  CheckEquals('A1', G.Cells[1, 1], 'Cells bleiben Datenspalten');
  CheckEquals(3, G.VisualCol(1));
  CheckEquals(2, G.DataCol(1));
  CheckEquals(2, G.Columns[1].DisplayIndex, 'DisplayIndex neu geschrieben');
  CheckEquals(0, G.Columns[2].DisplayIndex);
  G.MoveColumn(4, 1); // D nach vorn
  CheckEquals('1,D1,B1,C1,A1', Row1(G));
  G.Columns[4].DisplayIndex := 3; // per Property zurueck nach hinten
  CheckEquals('1,B1,C1,A1,D1', Row1(G), 'DisplayIndex-Gleichstand (A und D = 3): Datenindex entscheidet');
end;

procedure TGridColumnTests.MoveKeepsFocusOnDataColumn;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.Col := 2;
  CheckEquals(2, G.FocusCol);
  G.MoveColumn(2, 4);
  CheckEquals(2, G.Col, 'Col bleibt die Datenspalte');
  CheckEquals(4, G.FocusCol, 'Anzeige-Spalte folgt');
  G.Col := 1;
  CheckEquals(1, G.FocusCol);
end;

procedure TGridColumnTests.MoveNotAllowedForFixedOrWithoutColumns;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.MoveColumn(0, 2);
  CheckEquals('1,A1,B1,C1,D1', Row1(G), 'feste Spalte bleibt');
  G.MoveColumn(2, 0);
  CheckEquals('1,A1,B1,C1,D1', Row1(G), 'nicht vor die feste Spalte');
  CheckEquals(0, FMoves);
  G := NewGrid; // ohne Columns
  G.Cells[1, 1] := 'x';
  G.MoveColumn(1, 2);
  CheckEquals(1, G.DataCol(1), 'ohne Spalten-Objekte keine Verschiebung');
end;

procedure TGridColumnTests.HideColumn;
var
  G: TPPGGrid;
  R: TRect;
begin
  G := SampleGrid;
  G.Col := 2;
  G.Columns[2].Visible := False;
  CheckEquals(4, G.VisibleColCount);
  CheckEquals('1,A1,C1,D1', Row1(G));
  CheckEquals(-1, G.VisualCol(2));
  CheckEquals(3, G.DataCol(2));
  CheckEquals(2, G.FocusCol, 'Fokus auf die naechste angezeigte Spalte');
  R := G.CellRect(G.VisualCol(3), 1);
  CheckEquals(G.CellRect(1, 1).Right, R.Left, 'C rueckt an A heran');
  CheckEquals('B1', G.Cells[2, 1], 'Daten bleiben');
  G.Columns[2].Visible := True;
  CheckEquals('1,A1,B1,C1,D1', Row1(G));
end;

procedure TGridColumnTests.LastVisibleColumnStays;
var
  G: TPPGGrid;
  I: Integer;
begin
  G := SampleGrid;
  for I := 1 to 4 do
    G.Columns[I].Visible := False;
  CheckEquals(2, G.VisibleColCount, 'feste + eine Spalte bleiben');
  CheckEquals(1, G.DataCol(1));
end;

procedure TGridColumnTests.DragHeaderMovesColumn;
var
  G: TPPGGrid;
  P, Q: TPoint;
begin
  FForm.Show;
  try
    G := SampleGrid;
    G.Options := G.Options + [goColMoving];
    P := CenterOf(G.CellRect(1, 0));
    Q := CenterOf(G.CellRect(3, 0));
    Q.X := G.CellRect(3, 0).Right - 3; // rechte Haelfte von C -> hinter C
    G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
    G.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P.X + 20, P.Y));
    G.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(Q.X, Q.Y));
    G.Perform(WM_LBUTTONUP, 0, MouseLParam(Q.X, Q.Y));
    CheckEquals('1,B1,C1,A1,D1', Row1(G));
    CheckEquals(-1, G.SortColumn, 'Ziehen sortiert nicht');
    CheckEquals(1, FMoves);
  finally
    FForm.Hide;
  end;
end;

procedure TGridColumnTests.DragWithoutOptionSorts;
var
  G: TPPGGrid;
  P: TPoint;
begin
  FForm.Show;
  try
    G := SampleGrid;
    P := CenterOf(G.CellRect(1, 0));
    G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
    G.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P.X + 2, P.Y));
    G.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X + 2, P.Y));
    CheckEquals('1,A1,B1,C1,D1', Row1(G));
    CheckEquals(1, G.SortColumn, 'Klick sortiert wie bisher');
  finally
    FForm.Hide;
  end;
end;

procedure TGridColumnTests.AutoSizeFitsText;
var
  G: TPPGGrid;
  W0: Integer;
begin
  G := SampleGrid;
  W0 := G.ColWidths[2];
  G.Cells[2, 3] := 'Ein sehr langer Text, der nicht in die Spalte passt';
  G.AutoSizeColumn(2);
  CheckTrue(G.ColWidths[2] > W0 * 3, 'breiter');
  G.Cells[2, 3] := 'x';
  G.AutoSizeColumn(2);
  CheckTrue(G.ColWidths[2] < 64, 'schmaler, Kopf "B" bestimmt');
  CheckTrue(G.ColWidths[2] >= 8);
  G.SortBy(1, True);
  G.Filters[1] := 'A1';
  G.Cells[3, 2] := 'Ganz langer Text in herausgefilterter Zeile';
  G.AutoSizeColumn(3);
  CheckTrue(G.ColWidths[3] < 100, 'nur Zeilen der Ansicht');
end;

procedure TGridColumnTests.AutoSizeSamplesManyRows;
var
  G: TPPGGrid;
  T: Cardinal;
begin
  G := SampleGrid;
  G.RowCount := 1000001;
  T := GetTickCount;
  G.AutoSizeColumn(1);
  CheckTrue(GetTickCount - T < 2000, 'Stichprobe statt 1 000 000 Zeilen');
end;

procedure TGridColumnTests.DoubleClickEdgeAutoSizes;
var
  G: TPPGGrid;
  R: TRect;
begin
  FForm.Show;
  try
    G := SampleGrid;
    G.Options := G.Options + [goColSizing];
    G.Cells[1, 2] := 'Breiter Inhalt fuer die automatische Breite';
    R := G.CellRect(1, 0);
    G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(R.Right - 1, (R.Top + R.Bottom) div 2));
    G.Perform(WM_LBUTTONUP, 0, MouseLParam(R.Right - 1, (R.Top + R.Bottom) div 2));
    G.Perform(WM_LBUTTONDBLCLK, MK_LBUTTON, MouseLParam(R.Right - 1, (R.Top + R.Bottom) div 2));
    G.Perform(WM_LBUTTONUP, 0, MouseLParam(R.Right - 1, (R.Top + R.Bottom) div 2));
    CheckTrue(G.ColWidths[1] > 150, 'Doppelklick auf die Kante');
    CheckFalse(G.EditorMode);
  finally
    FForm.Hide;
  end;
end;

procedure TGridColumnTests.FixedColsRightStayAtEdge;
var
  G: TPPGGrid;
  R, R0: TRect;
  C, V: Integer;
  I: Integer;
begin
  G := SampleGrid;
  for I := 0 to 4 do
    G.ColWidths[I] := 150; // breiter als das Grid
  G.FixedColsRight := 1;
  R0 := G.CellRect(4, 1);
  CheckTrue(R0.Right <= G.ClientWidth, 'rechts fixierte Spalte ganz sichtbar');
  CheckTrue(R0.Right >= G.ClientWidth - 10, 'am rechten Rand');
  TGridAccess(G).ScrollTo(100, 0);
  R := G.CellRect(4, 1);
  CheckEquals(R0.Left, R.Left, 'scrollt nicht mit');
  CheckTrue(G.MouseCoord(CenterOf(R).X, CenterOf(R).Y, C, V));
  CheckEquals(4, C, 'Treffer auf der fixierten Spalte');
  // Spalte 3 liegt unter der fixierten: dort trifft man Spalte 4
  G.FixedColsRight := 10;
  CheckEquals(2, TGridAccess(G).FirstRightCol, 'mindestens eine scrollbare Spalte (feste + 1)');
  G.FixedColsRight := 0;
  R := G.CellRect(4, 1);
  CheckTrue(R.Left <> R0.Left);
end;

procedure TGridColumnTests.BandsShiftCells;
var
  G: TPPGGrid;
  Top0: Integer;
  Bmp: TBitmap;
  C, V: Integer;
  B: TPPGGridBand;
begin
  G := SampleGrid;
  Top0 := G.CellRect(1, 0).Top;
  B := G.Bands.Add;
  B.Caption := 'Gruppe';
  G.Columns[1].Band := 0;
  G.Columns[2].Band := 0;
  CheckEquals(G.CellRect(1, 0).Bottom - G.CellRect(1, 0).Top + Top0, G.CellRect(1, 0).Top,
    'Kopf rueckt um eine Bandzeile nach unten');
  CheckFalse(G.MouseCoord(CenterOf(G.CellRect(1, 0)).X, Top0 + 2, C, V),
    'Bandzeile ist keine Zelle');
  Bmp := RenderToBitmap(G);
  Bmp.Free;
  G.Bands.Clear;
  CheckEquals(Top0, G.CellRect(1, 0).Top);
end;

procedure TGridColumnTests.BandLevels;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.Bands.Add.Caption := 'Oben';
  G.Bands.Add.Caption := 'Mitte';
  G.Bands[1].ParentBand := 0;
  G.Bands.Add.Caption := 'Allein';
  CheckEquals(2, G.Bands.LevelCount);
  CheckEquals(0, G.Bands.LevelOf(0));
  CheckEquals(1, G.Bands.LevelOf(1));
  CheckEquals(0, G.Bands.BandAtLevel(1, 0));
  CheckEquals(1, G.Bands.BandAtLevel(1, 1));
  CheckEquals(-1, G.Bands.BandAtLevel(2, 1), 'keine Unterebene');
  // Zyklus bricht ab
  G.Bands[0].ParentBand := 1;
  CheckTrue(G.Bands.LevelCount <= 3);
end;

procedure TGridColumnTests.HeaderMenuItems;
var
  G: TPPGGrid;
  M: TPopupMenu;
  It: TMenuItem;
begin
  G := SampleGrid;
  G.OnHeaderMenu := HeaderMenu;
  G.SortBy(2, False);
  M := G.CreateHeaderMenu(2);
  try
    CheckTrue(M is TPPGPopupMenu, 'Menue der Suite');
    CheckEquals(2, FMenuCol, 'OnHeaderMenu mit Datenspalte');
    CheckNotNull(MenuItem(M, 'Eigener Eintrag'), 'OnHeaderMenu ergaenzt');
    It := M.Items[1];
    CheckTrue(It.Checked, 'absteigend markiert');
    It.Click;
    CheckEquals(2, G.SortColumn);
    It := M.Items[0];
    It.Click;
    CheckTrue(G.SortAscending, 'aufsteigend');
    M.Items[2].Click;
    CheckEquals(-1, G.SortColumn, 'Sortierung entfernen');
  finally
    M.Free;
  end;
  G.Columns[3].Sortable := False;
  M := G.CreateHeaderMenu(3);
  try
    CheckFalse(M.Items[0].Enabled, 'nicht sortierbar');
  finally
    M.Free;
  end;
end;

procedure TGridColumnTests.HeaderMenuHidesAndShows;
var
  G: TPPGGrid;
  M: TPopupMenu;
  Sub: TMenuItem;
  I: Integer;
begin
  G := SampleGrid;
  M := G.CreateHeaderMenu(3);
  try
    ByTag(M, 4).Click; // Spalte ausblenden
    CheckFalse(G.Columns[3].Visible);
  finally
    M.Free;
  end;
  M := G.CreateHeaderMenu(1);
  try
    Sub := Chooser(M); // Spaltenauswahl
    CheckEquals(4 + 2, Sub.Count, '4 Spalten, Trenner, alle einblenden');
    CheckFalse(Sub[2].Checked, 'C ausgeblendet');
    CheckTrue(Sub[0].Checked);
    Sub[2].Click;
    CheckTrue(G.Columns[3].Visible, 'wieder eingeblendet');
    Sub[0].Click;
    CheckFalse(G.Columns[1].Visible);
  finally
    M.Free;
  end;
  M := G.CreateHeaderMenu(2);
  try
    Chooser(M)[Chooser(M).Count - 1].Click; // alle einblenden
  finally
    M.Free;
  end;
  for I := 1 to 4 do
    CheckTrue(G.Columns[I].Visible);
  G.ColWidths[4] := 20;
  M := G.CreateHeaderMenu(4);
  try
    ByTag(M, 5).Click; // optimale Breite
  finally
    M.Free;
  end;
  CheckTrue(G.ColWidths[4] > 20);
end;

procedure TGridColumnTests.LayoutRoundTrip;
var
  G, G2: TPPGGrid;
  S: string;
begin
  G := SampleGrid;
  G.MoveColumn(1, 4);
  G.Columns[2].Visible := False;
  G.ColWidths[3] := 123;
  G.SortBy(4, False);
  S := G.SaveLayout;
  CheckTrue(Pos('[PPGGridLayout]', S) = 1);
  G2 := SampleGrid;
  G2.LoadLayout(S);
  CheckEquals(Row1(G), Row1(G2), 'Reihenfolge und Sichtbarkeit');
  CheckFalse(G2.Columns[2].Visible);
  CheckEquals(123, G2.ColWidths[3]);
  CheckEquals(4, G2.SortColumn);
  CheckFalse(G2.SortAscending);
  CheckEquals(S, G2.SaveLayout, 'stabil');
end;

procedure TGridColumnTests.LayoutIgnoresUnknown;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.LoadLayout('irgendwas');
  CheckEquals('1,A1,B1,C1,D1', Row1(G), 'fremder Text aendert nichts');
  // Spalte 9 gibt es nicht; fehlende Spalten haengen hinten an
  G.LoadLayout('[PPGGridLayout]'#13#10'Version=1'#13#10'Col=1,80,3'#13#10 +
    'Col=1,80,9'#13#10'Col=0,0,1'#13#10'Kaputt'#13#10'Sort=A,77');
  CheckEquals('1,C1,B1,D1', Row1(G));
  CheckFalse(G.Columns[1].Visible);
  CheckEquals(-1, G.SortColumn);
end;

procedure TGridColumnTests.DfmKeepsColumnState;
var
  G, G2: TPPGGrid;
  M: TMemoryStream;
begin
  G := SampleGrid;
  G.Bands.Add.Caption := 'Band';
  G.Columns[2].Band := 0;
  G.MoveColumn(1, 2);
  G.Columns[3].Visible := False;
  G.FixedColsRight := 1;
  G.HeaderMenu := False;
  M := TMemoryStream.Create;
  try
    M.WriteComponent(G);
    M.Position := 0;
    G2 := TPPGGrid.Create(FForm);
    G2.Parent := FForm;
    M.ReadComponent(G2);
    CheckEquals(1, G2.Bands.Count);
    CheckEquals('Band', G2.Bands[0].Caption);
    CheckEquals(0, G2.Columns[2].Band);
    CheckFalse(G2.Columns[3].Visible);
    CheckEquals(1, G2.FixedColsRight);
    CheckFalse(G2.HeaderMenu);
    CheckEquals(2, G2.VisualCol(1), 'Reihenfolge aus DisplayIndex');
    CheckEquals(1, G2.VisualCol(2));
  finally
    M.Free;
  end;
end;

procedure TGridColumnTests.ExportFollowsDisplay;
var
  G: TPPGGrid;
  S: string;
begin
  G := SampleGrid;
  G.MoveColumn(4, 1);
  G.Columns[2].Visible := False;
  S := G.ToCSV;
  CheckEquals('1;D1;A1;C1', Copy(S, Pos('1;', S), Length('1;D1;A1;C1')));
  G.Options := G.Options + [goRangeSelect];
  G.Selection := TGridRect(Rect(1, 1, 2, 1));
  CheckEquals('D1'#9'A1'#13#10, G.SelectionAsText);
end;

procedure TGridColumnTests.UiaUsesDataColumn;
var
  G: TPPGGrid;
  Id: TPPGUiaId;
  R, C: Integer;
begin
  G := SampleGrid;
  G.MoveColumn(1, 3);
  Id := TGridAccess(G).UiaGridItem(0, 0); // erste Datenzelle der Anzeige = B
  CheckEquals(2, Id.B, 'Element traegt die Datenspalte');
  CheckEquals('B1', TGridAccess(G).UiaValue(Id));
  TGridAccess(G).UiaGridPos(Id, R, C);
  CheckEquals(0, C);
  CheckEquals(1, TGridAccess(G).UiaIndexInParent(Id), 'Position in der Zeile (Anzeige)');
  G.Columns[2].Visible := False;
  CheckFalse(TGridAccess(G).UiaValid(Id), 'ausgeblendet = nicht gueltig');
end;

initialization
  RegisterTest('Phase13b', TGridColumnTests.Suite);

end.
