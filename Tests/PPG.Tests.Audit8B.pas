unit PPG.Tests.Audit8B;

{ Audit-Paket 8B (Docs\Audit-Paket8-Plan.md, 8c Grid): festhaltende Tests.
  Sie liefen zuerst gegen den unveraenderten Code und halten fest, dass die
  Optimierungen nichts am Ergebnis aendern: Sortierreihenfolge (gleicher
  Mergesort, gleiche Vergleichslogik), Filter, Summen (auch nach
  Einzelaenderungen), bedingte Formate, Zeilenhoehen (auch DFM) und das
  gezeichnete Bild (Referenzbilder unter Tests\Visual\Audit8B, beim ersten
  Lauf angelegt). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids,
  Vcl.Imaging.pngimage,
  PPG.Types, PPG.Tokens, PPG.RowLayout, PPG.Render.Registry, PPG.Grid,
  PPG.Grid.Columns, PPG.Grid.Styles, PPG.Grid.CellKinds, PPG.Tests.Controls;

type
  TAudit8BTests = class(TControlTestCase)
  private
    FOldFS: TFormatSettings;
    FCompareCalls: Integer;
    FVirt: array of string;
    FCustomCalls: Integer;
    FVirtCalls: Integer;
    procedure CompareByLength(Sender: TObject; ACol, ARow1, ARow2: Integer;
      var Compare: Integer);
    procedure VirtText(Sender: TObject; ACol, ARow: Integer; var Text: string);
    procedure CustomAgg(Sender: TObject; ACol, Group: Integer; var Value: string);
    function NewGrid(W: Integer = 420; H: Integer = 300): TPPGGrid;
    /// Spalten: # | Kategorie | Name | Menge (Summe) | Art | Preis (Min) |
    /// Gewicht (Max) | Wert (Mittel), 8 Datenzeilen.
    function AggGrid: TPPGGrid;
    /// Alle Summentexte (Summenzeile und Gruppenfuesse) als Text.
    function AggTexts(G: TPPGGrid): string;
    procedure CheckAggConsistent(G: TPPGGrid; const What: string);
    function RenderConfig(Index: Integer): TBitmap;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    { #1 Sortieren }
    procedure SortMatchesMergeSort;
    procedure SortRandomMixedMatchesMergeSort;
    procedure SortHeaderClickCycle;
    procedure SortCompareEventKeepsOldWay;
    procedure SortVirtualGrid;
    procedure SortReadsEachRowOnce;
    procedure SortWithGroups;
    { #3, #7 Filtern }
    procedure FilterCaseInsensitive;
    procedure FilterThenResortFollowsData;
    procedure FilterResortReusesResult;
    procedure FilterVirtualResortFollowsData;
    { #6 Summen }
    procedure AggregatesAfterSingleChanges;
    procedure AggregatesWithFilterAndCustom;
    procedure AggregatesIncrementalCount;
    procedure AggregatesManyAddsAreExact;
    { #4 bedingte Formate }
    procedure CondFormatsTopBottomScale;
    { #2 Spaltenbreite }
    procedure ColumnWidthKeepsFooterAndStyles;
    procedure ColumnWidthDoesNotRecalc;
    { #5 Zeilenhoehen }
    procedure RowHeightsFollowDataRows;
    procedure RowHeightsMillionRows;
    procedure RowHeightsStreaming;
    procedure RowHeightsRowCountAndDefault;
    procedure RowLayoutMatchesModel;
    { #11 Zellspeicher }
    procedure CellStoreGrowsAndTruncates;
    { #8-#10, #12 Zeichnen }
    procedure PaintUnchanged;
  end;

implementation

uses
  System.Math, System.Generics.Collections, PPG.Grid.Data, PPG.Tests.Visual;

type
  TGridAccess = class(TPPGGrid);
  TRowCompare = reference to function(R1, R2: Integer): Integer;

const
  Cats: array[1..8] of string = ('Obst', 'Gemuese', 'Obst', 'Brot', 'Gemuese', 'Obst', 'Brot', 'Obst');
  Names: array[1..8] of string = ('Apfel', 'Kohl', 'Birne', 'Laib', 'Lauch', 'Kiwi', 'Semmel', 'Pflaume');
  Qty: array[1..8] of string = ('10', '4', '6', '2', '8', '1', '30', '5');
  Kinds: array[1..8] of string = ('rot', 'gruen', 'gruen', 'hell', 'gruen', 'braun', 'hell', 'rot');
  Prices: array[1..8] of string = ('2,5', '1', '3', '0,75', '4', '9', '1,25', '2');
  Weights: array[1..8] of string = ('100', '250', '80', '500', '120', '60', '45', '70');
  Values: array[1..8] of string = ('1', '2', '3', '4', '5', '6', '7', '8');

{ Referenz: derselbe Mergesort wie TPPGGridSortStage (Mitte (L+R) div 2,
  bei Gleichheit links zuerst). }
function RefSort(const Rows: TArray<Integer>; const Cmp: TRowCompare; Asc: Boolean): TArray<Integer>;
var
  Tmp: TArray<Integer>;

  procedure MergeSort(L, R: Integer);
  var
    M, I1, I2, K, C: Integer;
  begin
    if R - L < 1 then
      Exit;
    M := (L + R) div 2;
    MergeSort(L, M);
    MergeSort(M + 1, R);
    I1 := L;
    I2 := M + 1;
    K := L;
    while (I1 <= M) and (I2 <= R) do
    begin
      C := Cmp(Result[I1], Result[I2]);
      if not Asc then
        C := -C;
      if C <= 0 then
      begin
        Tmp[K] := Result[I1];
        Inc(I1);
      end
      else
      begin
        Tmp[K] := Result[I2];
        Inc(I2);
      end;
      Inc(K);
    end;
    while I1 <= M do
    begin
      Tmp[K] := Result[I1];
      Inc(I1);
      Inc(K);
    end;
    while I2 <= R do
    begin
      Tmp[K] := Result[I2];
      Inc(I2);
      Inc(K);
    end;
    for K := L to R do
      Result[K] := Tmp[K];
  end;

begin
  Result := Copy(Rows);
  SetLength(Tmp, Length(Result));
  MergeSort(0, High(Result));
end;

/// Vergleich wie TPPGCustomGrid.CompareDataRows (ohne OnCompareCells).
function RefCompareText(const S1, S2: string): Integer;
var
  F1, F2: Double;
begin
  if TryStrToFloat(S1, F1) and TryStrToFloat(S2, F2) then
  begin
    if F1 < F2 then
      Result := -1
    else if F1 > F2 then
      Result := 1
    else
      Result := 0;
  end
  else
    Result := AnsiCompareText(S1, S2);
end;

function RowRange(First, Last: Integer): TArray<Integer>;
var
  I: Integer;
begin
  SetLength(Result, Last - First + 1);
  for I := 0 to High(Result) do
    Result[I] := First + I;
end;

/// Datenzeilen der Ansicht (ohne feste Zeilen).
function ViewRows(G: TPPGGrid): TArray<Integer>;
var
  V, N: Integer;
begin
  N := TGridAccess(G).VRowCount - TGridAccess(G).VFixedRows;
  SetLength(Result, N);
  for V := 0 to N - 1 do
    Result[V] := G.DataRow(V + TGridAccess(G).VFixedRows);
end;

function RowsStr(const Rows: TArray<Integer>): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(Rows) do
  begin
    if I > 0 then
      Result := Result + ',';
    Result := Result + IntToStr(Rows[I]);
  end;
end;

function GridCompare(G: TPPGGrid; Col: Integer): TRowCompare;
begin
  Result :=
    function(R1, R2: Integer): Integer
    begin
      Result := RefCompareText(TGridAccess(G).GetCellText(Col, R1),
        TGridAccess(G).GetCellText(Col, R2));
    end;
end;

{ TAudit8BTests }

procedure TAudit8BTests.SetUp;
begin
  inherited SetUp;
  FOldFS := FormatSettings;
  FormatSettings := TFormatSettings.Create('de-DE');
end;

procedure TAudit8BTests.TearDown;
begin
  FormatSettings := FOldFS;
  inherited TearDown;
end;

procedure TAudit8BTests.CompareByLength(Sender: TObject; ACol, ARow1, ARow2: Integer;
  var Compare: Integer);
begin
  Inc(FCompareCalls);
  Compare := Length(TPPGGrid(Sender).Cells[ACol, ARow1]) -
    Length(TPPGGrid(Sender).Cells[ACol, ARow2]);
end;

procedure TAudit8BTests.VirtText(Sender: TObject; ACol, ARow: Integer; var Text: string);
begin
  Inc(FVirtCalls);
  if (ARow >= 0) and (ARow < Length(FVirt)) and (ACol = 1) then
    Text := FVirt[ARow]
  else if ACol = 2 then
    Text := IntToStr(ARow mod 3);
end;

procedure TAudit8BTests.CustomAgg(Sender: TObject; ACol, Group: Integer; var Value: string);
var
  Rows: TArray<Integer>;
  I: Integer;
  S: Double;
  D: Double;
begin
  Inc(FCustomCalls);
  Rows := TPPGGrid(Sender).GroupDataRows(Group);
  S := 0;
  for I := 0 to High(Rows) do
    if TryStrToFloat(TPPGGrid(Sender).Cells[3, Rows[I]], D) then
      S := S + D;
  Value := 'n=' + IntToStr(Length(Rows)) + ' s=' + FloatToStr(S);
end;

function TAudit8BTests.NewGrid(W, H: Integer): TPPGGrid;
begin
  Result := TPPGGrid.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, W, H);
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.HandleNeeded;
end;

function TAudit8BTests.AggGrid: TPPGGrid;
var
  R: Integer;
begin
  Result := NewGrid;
  Result.Columns.Add.Title := '#';
  Result.Columns.Add.Title := 'Kategorie';
  Result.Columns.Add.Title := 'Name';
  Result.Columns.Add.Title := 'Menge';
  Result.Columns.Add.Title := 'Art';
  Result.Columns.Add.Title := 'Preis';
  Result.Columns.Add.Title := 'Gewicht';
  Result.Columns.Add.Title := 'Wert';
  Result.FixedCols := 1;
  Result.RowCount := 9;
  for R := 1 to 8 do
  begin
    Result.Cells[0, R] := IntToStr(R);
    Result.Cells[1, R] := Cats[R];
    Result.Cells[2, R] := Names[R];
    Result.Cells[3, R] := Qty[R];
    Result.Cells[4, R] := Kinds[R];
    Result.Cells[5, R] := Prices[R];
    Result.Cells[6, R] := Weights[R];
    Result.Cells[7, R] := Values[R];
  end;
  Result.Columns[2].Aggregate := agCount;
  Result.Columns[3].Aggregate := agSum;
  Result.Columns[5].Aggregate := agMin;
  Result.Columns[6].Aggregate := agMax;
  Result.Columns[7].Aggregate := agAvg;
  Result.ShowFooter := True;
  Application.ProcessMessages;
end;

function TAudit8BTests.AggTexts(G: TPPGGrid): string;
var
  C, Grp: Integer;
begin
  Result := '';
  for C := 0 to G.ColCount - 1 do
  begin
    Result := Result + '[' + TGridAccess(G).CachedFooterText(C) + ']';
    for Grp := 0 to G.GroupCount - 1 do
      Result := Result + TGridAccess(G).CachedGroupFooterText(Grp, C) + ';';
  end;
end;

procedure TAudit8BTests.CheckAggConsistent(G: TPPGGrid; const What: string);
var
  Before: string;
begin
  // Was nach der Nachricht im Zwischenspeicher steht, muss einer vollen
  // Neuberechnung entsprechen
  Application.ProcessMessages;
  Before := AggTexts(G);
  G.RecalcAggregates;
  CheckEquals(AggTexts(G), Before, What);
end;

{ ---- #1 Sortieren ---- }

procedure TAudit8BTests.SortMatchesMergeSort;
const
  Vals: array[0..19] of string = ('10', '9', 'abc', 'ABC', '', '2,5', '-1', 'b', '10',
    'Zebra', '1e3', ' 5', 'Apfel', '9', 'apfel', '0', '-0', 'x10', '1.000', '3');
var
  G: TPPGGrid;
  R, C: Integer;
  Asc: Boolean;
  Expected: TArray<Integer>;
begin
  G := NewGrid;
  G.ColCount := 3;
  G.RowCount := 21;
  for R := 1 to 20 do
  begin
    G.Cells[0, R] := IntToStr(R);
    G.Cells[1, R] := Vals[R - 1];
    G.Cells[2, R] := Vals[(R * 7) mod 20];
  end;
  for C := 1 to 2 do
    for Asc := False to True do
    begin
      G.SortBy(C, Asc);
      Expected := RefSort(RowRange(1, 20), GridCompare(G, C), Asc);
      CheckEquals(RowsStr(Expected), RowsStr(ViewRows(G)),
        Format('Spalte %d, aufsteigend %s', [C, System.SysUtils.BoolToStr(Asc, True)]));
    end;
  G.SortBy(-1);
  CheckEquals(RowsStr(RowRange(1, 20)), RowsStr(ViewRows(G)), 'unsortiert');
end;

procedure TAudit8BTests.SortRandomMixedMatchesMergeSort;
var
  G: TPPGGrid;
  R, C: Integer;
  Asc: Boolean;
  Expected: TArray<Integer>;
  S: string;
begin
  RandSeed := 8080;
  G := NewGrid;
  G.ColCount := 4;
  G.RowCount := 3001;
  for R := 1 to 3000 do
  begin
    // Zahlen, Text, leere Zellen und Gleichstaende gemischt
    case Random(6) of
      0: S := IntToStr(Random(50));
      1: S := FloatToStr(Random(1000) / 8);
      2: S := 'Text ' + IntToStr(Random(40));
      3: S := '';
      4: S := Chr(Ord('a') + Random(26)) + Chr(Ord('A') + Random(26));
    else
      S := IntToStr(Random(5) - 2);
    end;
    G.Cells[1, R] := S;
    G.Cells[2, R] := IntToStr(Random(100000));
    G.Cells[3, R] := 'Name ' + IntToStr(Random(300));
  end;
  for C := 1 to 3 do
    for Asc := False to True do
    begin
      G.SortBy(C, Asc);
      Expected := RefSort(RowRange(1, 3000), GridCompare(G, C), Asc);
      CheckEquals(RowsStr(Expected), RowsStr(ViewRows(G)),
        Format('Spalte %d, aufsteigend %s', [C, System.SysUtils.BoolToStr(Asc, True)]));
    end;
end;

procedure TAudit8BTests.SortHeaderClickCycle;
var
  G: TPPGGrid;
  R: Integer;
begin
  G := NewGrid;
  G.ColCount := 2;
  G.RowCount := 7;
  for R := 1 to 6 do
    G.Cells[1, R] := IntToStr((R * 5) mod 7);
  TGridAccess(G).HeaderClicked(1, 0);
  CheckEquals(RowsStr(RefSort(RowRange(1, 6), GridCompare(G, 1), True)), RowsStr(ViewRows(G)),
    'erster Klick aufsteigend');
  TGridAccess(G).HeaderClicked(1, 0);
  CheckEquals(RowsStr(RefSort(RowRange(1, 6), GridCompare(G, 1), False)), RowsStr(ViewRows(G)),
    'zweiter Klick absteigend');
  TGridAccess(G).HeaderClicked(1, 0);
  CheckEquals(RowsStr(RowRange(1, 6)), RowsStr(ViewRows(G)), 'dritter Klick unsortiert');
  CheckEquals(-1, G.SortColumn);
end;

procedure TAudit8BTests.SortCompareEventKeepsOldWay;
var
  G: TPPGGrid;
  R: Integer;
  Expected: TArray<Integer>;
begin
  G := NewGrid;
  G.ColCount := 2;
  G.RowCount := 41;
  for R := 1 to 40 do
    G.Cells[1, R] := StringOfChar('x', (R * 13) mod 9) + IntToStr(R);
  G.OnCompareCells := CompareByLength;
  FCompareCalls := 0;
  G.SortBy(1, False);
  CheckTrue(FCompareCalls > 0, 'OnCompareCells wird gerufen');
  Expected := RefSort(RowRange(1, 40),
    function(R1, R2: Integer): Integer
    begin
      Result := Length(G.Cells[1, R1]) - Length(G.Cells[1, R2]);
    end, False);
  CheckEquals(RowsStr(Expected), RowsStr(ViewRows(G)));
end;

procedure TAudit8BTests.SortVirtualGrid;
var
  G: TPPGGrid;
  R: Integer;
  Expected: TArray<Integer>;
begin
  SetLength(FVirt, 501);
  for R := 1 to 500 do
    FVirt[R] := IntToStr((R * 37) mod 101);
  G := NewGrid;
  G.ColCount := 3;
  G.OnGetCellText := VirtText;
  G.RowCount := 501;
  G.SortBy(1, True);
  Expected := RefSort(RowRange(1, 500), GridCompare(G, 1), True);
  CheckEquals(RowsStr(Expected), RowsStr(ViewRows(G)), 'virtuell');
  // Daten aendern sich ausserhalb des Grids: neues Sortieren liest neu
  for R := 1 to 500 do
    FVirt[R] := IntToStr((R * 53) mod 97);
  G.SortBy(1, False);
  Expected := RefSort(RowRange(1, 500), GridCompare(G, 1), False);
  CheckEquals(RowsStr(Expected), RowsStr(ViewRows(G)), 'virtuell nach Datenaenderung');
end;

procedure TAudit8BTests.SortReadsEachRowOnce;
var
  G: TPPGGrid;
  R: Integer;
begin
  SetLength(FVirt, 2001);
  for R := 1 to 2000 do
    FVirt[R] := IntToStr((R * 7919) mod 2003);
  G := NewGrid;
  G.ColCount := 3;
  G.OnGetCellText := VirtText;
  G.RowCount := 2001;
  FVirtCalls := 0;
  G.SortBy(1, True);
  // Schluessel einmal je Zeile (vorher zwei Texte je Vergleich, ~ 2 n log n)
  CheckTrue(FVirtCalls <= 2000 + 200, Format('%d Abfragen', [FVirtCalls]));
  CheckEquals(RowsStr(RefSort(RowRange(1, 2000), GridCompare(G, 1), True)), RowsStr(ViewRows(G)));
  // Mit OnCompareCells der alte Weg
  G.OnCompareCells := CompareByLength;
  FCompareCalls := 0;
  G.SortBy(1, False);
  CheckTrue(FCompareCalls > 2000, 'OnCompareCells je Vergleich');
end;

procedure TAudit8BTests.SortWithGroups;
var
  G: TPPGGrid;
  Sorted, Firsts, Order, Expected: TArray<Integer>;
  I, J, N: Integer;
  Seen: Boolean;
  Got: TArray<Integer>;
  Asc: Boolean;
begin
  G := AggGrid;
  G.GroupBy([1]);
  for Asc := False to True do
  begin
    G.SortBy(3, Asc);
    // Zeilen sortiert, Gruppen in Reihenfolge ihres Schluessels (aufsteigend),
    // Vertreter = erste Zeile der Gruppe in der sortierten Folge
    Sorted := RefSort(RowRange(1, 8), GridCompare(G, 3), Asc);
    SetLength(Firsts, 0);
    for I := 0 to High(Sorted) do
    begin
      Seen := False;
      for J := 0 to High(Firsts) do
        if G.Cells[1, Firsts[J]] = G.Cells[1, Sorted[I]] then
          Seen := True;
      if not Seen then
      begin
        SetLength(Firsts, Length(Firsts) + 1);
        Firsts[High(Firsts)] := Sorted[I];
      end;
    end;
    Order := RefSort(Firsts, GridCompare(G, 1), True);
    N := 0;
    SetLength(Expected, 8 + Length(Order));
    for I := 0 to High(Order) do
    begin
      Expected[N] := -3; // Gruppenkopf
      Inc(N);
      for J := 0 to High(Sorted) do
        if G.Cells[1, Sorted[J]] = G.Cells[1, Order[I]] then
        begin
          Expected[N] := Sorted[J];
          Inc(N);
        end;
    end;
    SetLength(Expected, N);
    Got := ViewRows(G);
    CheckEquals(RowsStr(Expected), RowsStr(Got), 'gruppiert, aufsteigend ' + System.SysUtils.BoolToStr(Asc, True));
  end;
end;

{ ---- Filtern ---- }

procedure TAudit8BTests.FilterCaseInsensitive;
const
  AUml = #$00C4; // A-Umlaut
  aUmlS = #$00E4;
var
  G: TPPGGrid;
  Words: array[1..8] of string;
  R: Integer;
  Expected: TArray<Integer>;
  F: string;

  function Pass(ARow: Integer): Boolean;
  begin
    Result := Pos(AnsiUpperCase(F), AnsiUpperCase(G.Cells[1, ARow])) > 0;
  end;

begin
  Words[1] := AUml + 'pfel';
  Words[2] := aUmlS + 'pfel';
  Words[3] := 'Apfel';
  Words[4] := 'BIRNE';
  Words[5] := 'birne';
  Words[6] := 'K' + aUmlS + 'se';
  Words[7] := '';
  Words[8] := 'Zwetschge ' + aUmlS + 'P';
  G := NewGrid;
  G.ColCount := 3;
  G.RowCount := 9;
  for R := 1 to 8 do
  begin
    G.Cells[1, R] := Words[R];
    G.Cells[2, R] := IntToStr(R mod 3);
  end;
  F := aUmlS + 'p';
  G.Filters[1] := F;
  SetLength(Expected, 0);
  for R := 1 to 8 do
    if Pass(R) then
    begin
      SetLength(Expected, Length(Expected) + 1);
      Expected[High(Expected)] := R;
    end;
  CheckEquals(RowsStr(Expected), RowsStr(ViewRows(G)), 'Umlaut, Gross/Klein');
  CheckEquals('1,2,8', RowsStr(ViewRows(G)));
  F := 'IR';
  G.Filters[1] := 'ir';
  CheckEquals('4,5', RowsStr(ViewRows(G)));
  // Zwei Filter: beide muessen passen
  G.Filters[2] := '2';
  CheckEquals('5', RowsStr(ViewRows(G)));
  G.ClearFilters;
  CheckEquals(RowsStr(RowRange(1, 8)), RowsStr(ViewRows(G)));
end;

procedure TAudit8BTests.FilterThenResortFollowsData;
var
  G: TPPGGrid;
  R: Integer;
  Base, Expected: TArray<Integer>;

  function Passing: TArray<Integer>;
  var
    K: Integer;
  begin
    SetLength(Result, 0);
    for K := 1 to 60 do
      if Pos('1', G.Cells[2, K]) > 0 then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := K;
      end;
  end;

begin
  G := NewGrid;
  G.ColCount := 3;
  G.RowCount := 61;
  for R := 1 to 60 do
  begin
    G.Cells[1, R] := IntToStr((R * 17) mod 23);
    G.Cells[2, R] := IntToStr(R);
  end;
  G.Filters[2] := '1';
  Base := Passing;
  CheckEquals(RowsStr(Base), RowsStr(ViewRows(G)), 'gefiltert');
  G.SortBy(1, True);
  CheckEquals(RowsStr(RefSort(Base, GridCompare(G, 1), True)), RowsStr(ViewRows(G)), 'sortiert');
  G.SortBy(1, False);
  CheckEquals(RowsStr(RefSort(Base, GridCompare(G, 1), False)), RowsStr(ViewRows(G)),
    'umsortiert mit Filter');
  // Datenaenderung: Zeile 2 passt danach, Zeile 10 nicht mehr
  G.Cells[2, 2] := 'x1';
  G.Cells[2, 10] := 'zehn';
  G.SortBy(1, True);
  Expected := RefSort(Passing, GridCompare(G, 1), True);
  CheckEquals(RowsStr(Expected), RowsStr(ViewRows(G)), 'nach Datenaenderung neu gefiltert');
  CheckTrue(G.VisualRow(2) >= 0, 'Zeile 2 sichtbar');
  CheckEquals(-1, G.VisualRow(10), 'Zeile 10 herausgefiltert');
  // Zeilenzahl geaendert: neue Zeilen werden gefiltert
  G.RowCount := 71;
  G.Cells[2, 70] := '100';
  G.SortBy(1, False);
  CheckTrue(G.VisualRow(70) >= 0, 'neue Zeile sichtbar');
  CheckEquals(-1, G.VisualRow(65), 'leere neue Zeile gefiltert');
end;

procedure TAudit8BTests.FilterResortReusesResult;
var
  G: TPPGGrid;
  N, A: Integer;
  Sum: string;
begin
  G := AggGrid;
  G.RowCount := 401;
  G.Cells[3, 300] := '7';
  G.Cells[2, 300] := 'Kiwi';
  G.Filters[2] := 'i';
  Sum := G.FooterText(3);
  N := TGridAccess(G).FilterEvalCount;
  A := TGridAccess(G).AggRecalcCount;
  G.SortBy(3, True);
  G.SortBy(3, False);
  G.SortBy(2, True);
  G.SortBy(-1);
  CheckEquals(N, TGridAccess(G).FilterEvalCount, 'Umsortieren filtert nicht neu');
  CheckEquals(A, TGridAccess(G).AggRecalcCount, 'Summen bleiben beim Umsortieren');
  CheckEquals(Sum, G.FooterText(3));
  // Datenaenderung: neu filtern und neu summieren
  G.Cells[2, 2] := 'Kiwi';
  G.SortBy(3, True);
  CheckTrue(TGridAccess(G).FilterEvalCount > N, 'nach Datenaenderung neu gefiltert');
  CheckTrue(G.VisualRow(2) >= 0);
  CheckAggConsistent(G, 'nach Datenaenderung');
  // Ohne Filter: Umsortieren ohne neue Summen
  G.ClearFilters;
  A := TGridAccess(G).AggRecalcCount;
  G.SortBy(5, True);
  G.SortBy(5, False);
  CheckEquals(A, TGridAccess(G).AggRecalcCount, 'ohne Filter');
  // Gruppiert: immer neu (Gruppen haengen an der Reihenfolge)
  G.GroupBy([1]);
  A := TGridAccess(G).AggRecalcCount;
  G.SortBy(3, True);
  CheckEquals(A + 1, TGridAccess(G).AggRecalcCount, 'gruppiert');
  CheckAggConsistent(G, 'gruppiert');
end;

procedure TAudit8BTests.FilterVirtualResortFollowsData;
var
  G: TPPGGrid;
  R: Integer;
begin
  SetLength(FVirt, 41);
  for R := 1 to 40 do
    FVirt[R] := 'a' + IntToStr(R);
  G := NewGrid;
  G.ColCount := 3;
  G.OnGetCellText := VirtText;
  G.RowCount := 41;
  G.Filters[1] := '3';
  CheckEquals('3,13,23,30,31,32,33,34,35,36,37,38,39', RowsStr(ViewRows(G)));
  // Virtuelle Daten aendern sich ohne Cells[]: Umsortieren filtert neu
  FVirt[5] := 'b3';
  FVirt[3] := 'x';
  G.SortBy(2, True);
  CheckTrue(G.VisualRow(5) >= 0, 'Zeile 5 passt jetzt');
  CheckEquals(-1, G.VisualRow(3), 'Zeile 3 passt nicht mehr');
end;

{ ---- Summen ---- }

procedure TAudit8BTests.AggregatesAfterSingleChanges;
var
  G: TPPGGrid;
begin
  G := AggGrid;
  G.GroupFooter := True;
  G.GroupBy([1]);
  CheckEquals('66', G.FooterText(3));
  CheckEquals('0,75', G.FooterText(5));
  CheckEquals('500', G.FooterText(6));
  CheckEquals('4,5', G.FooterText(7));
  CheckEquals('8', G.FooterText(2));
  CheckAggConsistent(G, 'Ausgangslage');
  G.Cells[3, 2] := '7';
  Application.ProcessMessages;
  CheckEquals('69', TGridAccess(G).CachedFooterText(3), 'Summe nach Einzelaenderung');
  CheckAggConsistent(G, 'Summe');
  G.Cells[5, 1] := '0,5';
  CheckAggConsistent(G, 'neues Minimum');
  CheckEquals('0,5', TGridAccess(G).CachedFooterText(5));
  G.Cells[5, 1] := '9';
  CheckAggConsistent(G, 'Minimum entfernt');
  CheckEquals('0,75', TGridAccess(G).CachedFooterText(5));
  G.Cells[6, 4] := '';
  CheckAggConsistent(G, 'Maximum geleert');
  CheckEquals('250', TGridAccess(G).CachedFooterText(6));
  G.Cells[7, 3] := 'abc';
  CheckAggConsistent(G, 'Text im Mittelwert');
  G.Cells[3, 5] := '1.234,5';
  CheckAggConsistent(G, 'Tausendertrenner');
  G.Cells[2, 6] := '';
  CheckAggConsistent(G, 'Anzahl');
  CheckEquals('7', TGridAccess(G).CachedFooterText(2));
  G.Cells[3, 1] := '1';
  G.Cells[3, 1] := '2';
  G.Cells[3, 8] := '-3';
  CheckAggConsistent(G, 'mehrere vor der Nachricht');
  TGridAccess(G).SetCellByUser(3, 7, '11');
  CheckAggConsistent(G, 'SetCellByUser');
  G.Cells[1, 2] := 'Obst';
  CheckAggConsistent(G, 'Gruppenspalte');
  G.Cells[3, 2] := '100';
  CheckAggConsistent(G, 'nach Wechsel der Gruppenspalte');
  G.Cells[0, 3] := '99';
  CheckAggConsistent(G, 'Spalte ohne Summe');
  CheckEquals('', TGridAccess(G).CachedFooterText(0));
end;

procedure TAudit8BTests.AggregatesWithFilterAndCustom;
var
  G: TPPGGrid;
  S: string;
begin
  G := AggGrid;
  G.Filters[1] := 'Obst';
  CheckEquals('22', G.FooterText(3), 'nur gefilterte Zeilen');
  G.Cells[3, 2] := '1000';
  CheckAggConsistent(G, 'herausgefilterte Zeile');
  CheckEquals('22', TGridAccess(G).CachedFooterText(3));
  G.Cells[3, 1] := '20';
  CheckAggConsistent(G, 'sichtbare Zeile');
  CheckEquals('32', TGridAccess(G).CachedFooterText(3));
  G.ClearFilters;
  CheckEquals('1.072', G.FooterText(3));
  // agCustom: jedes Mal neu
  G.OnCustomAggregate := CustomAgg;
  G.Columns[4].Aggregate := agCustom;
  G.GroupBy([1]);
  S := G.FooterText(4);
  CheckEquals('n=8 s=1072', S);
  G.Cells[3, 4] := '12';
  Application.ProcessMessages;
  CheckEquals('n=8 s=1082', TGridAccess(G).CachedFooterText(4), 'Custom neu gerechnet');
  CheckAggConsistent(G, 'Custom');
  // Sortieren aendert keine Summen
  G.SortBy(3, False);
  CheckEquals('n=8 s=1082', TGridAccess(G).CachedFooterText(4));
  CheckAggConsistent(G, 'nach Sortieren');
end;

procedure TAudit8BTests.AggregatesIncrementalCount;
var
  G: TPPGGrid;
  N, I: Integer;
begin
  G := AggGrid;
  G.GroupFooter := True;
  G.GroupBy([1, 4]);
  Application.ProcessMessages;
  N := TGridAccess(G).AggRecalcCount;
  for I := 1 to 20 do
  begin
    G.Cells[3, 1 + I mod 8] := IntToStr(I * 3);
    G.Cells[7, 1 + (I * 3) mod 8] := IntToStr(I);
    G.Cells[2, 1 + I mod 5] := 'Name' + IntToStr(I);
    Application.ProcessMessages;
  end;
  CheckEquals(N, TGridAccess(G).AggRecalcCount, 'Einzelaenderungen ohne volle Rechnung');
  CheckAggConsistent(G, 'nach 60 Einzelaenderungen');
  // Minimum entfernt: einmal voll
  N := TGridAccess(G).AggRecalcCount;
  G.Cells[5, 4] := '100';
  Application.ProcessMessages;
  CheckEquals(N + 1, TGridAccess(G).AggRecalcCount, 'Minimum entfernt: voll');
  CheckAggConsistent(G, 'Minimum');
  // Neues Maximum: inkrementell
  N := TGridAccess(G).AggRecalcCount;
  G.Cells[6, 2] := '9999';
  Application.ProcessMessages;
  CheckEquals(N, TGridAccess(G).AggRecalcCount, 'neues Maximum: inkrementell');
  CheckEquals('9.999', TGridAccess(G).CachedFooterText(6));
  // Gruppenspalte: voll
  G.Cells[4, 3] := 'rot';
  Application.ProcessMessages;
  CheckEquals(N + 1, TGridAccess(G).AggRecalcCount, 'Gruppenspalte: voll');
  CheckAggConsistent(G, 'Gruppenspalte');
end;

procedure TAudit8BTests.AggregatesManyAddsAreExact;
var
  G: TPPGGrid;
  R: Integer;
begin
  G := NewGrid;
  G.Columns.Add.Title := '#';
  G.Columns.Add.Title := 'Wert';
  G.Columns[1].Aggregate := agSum;
  G.Columns[1].FooterFormat := '0.000000';
  G.ShowFooter := True;
  G.RowCount := 1001;
  for R := 1 to 1000 do
    G.Cells[1, R] := '0,1';
  CheckEquals('100,000000', G.FooterText(1));
  for R := 1 to 500 do
  begin
    G.Cells[1, R] := '0,3';
    if R mod 50 = 0 then
      Application.ProcessMessages;
  end;
  Application.ProcessMessages;
  CheckEquals('200,000000', TGridAccess(G).CachedFooterText(1));
  CheckAggConsistent(G, 'viele Aenderungen');
end;

{ ---- bedingte Formate ---- }

procedure TAudit8BTests.CondFormatsTopBottomScale;
var
  G: TPPGGrid;
  R, N, K: Integer;
  Vals, Sorted: TArray<Double>;
  Tok: TPPGTokens;
  St: TPPGGridCellStyle;
  TopRule, BotRule, Scale: TPPGGridConditionalFormat;
  ThrTop, ThrBot, VMin, VMax, T: Double;
  C: TColor;
  V: Double;
begin
  RandSeed := 4711;
  G := NewGrid;
  G.ColCount := 4;
  G.RowCount := 201;
  for R := 1 to 200 do
  begin
    G.Cells[1, R] := IntToStr(Random(1000));
    G.Cells[2, R] := FloatToStr(Random(5000) / 10);
    G.Cells[3, R] := IntToStr(Random(30) - 10);
  end;
  G.Cells[1, 7] := 'kein Wert';
  TopRule := G.ConditionalFormats.Add;
  TopRule.Column := 1;
  TopRule.Rule := crTop;
  TopRule.Value1 := '10%';
  BotRule := G.ConditionalFormats.Add;
  BotRule.Column := 2;
  BotRule.Rule := crBottom;
  BotRule.Value1 := '7';
  Scale := G.ConditionalFormats.Add;
  Scale.Column := 3;
  Scale.Rule := crColorScale;
  Scale.Color := ccAccent;
  G.RecalcAggregates;
  Tok := PPGDefaultTokens(False);
  // Referenz-Schwellen
  SetLength(Vals, 0);
  for R := 1 to 200 do
    if TryStrToFloat(G.Cells[1, R], V) then
    begin
      SetLength(Vals, Length(Vals) + 1);
      Vals[High(Vals)] := V;
    end;
  Sorted := Copy(Vals);
  TArray.Sort<Double>(Sorted);
  N := Length(Sorted);
  K := Round(N * 10 / 100);
  ThrTop := Sorted[N - K];
  SetLength(Vals, 0);
  for R := 1 to 200 do
    if TryStrToFloat(G.Cells[2, R], V) then
    begin
      SetLength(Vals, Length(Vals) + 1);
      Vals[High(Vals)] := V;
    end;
  Sorted := Copy(Vals);
  TArray.Sort<Double>(Sorted);
  ThrBot := Sorted[6];
  VMin := MaxDouble;
  VMax := -MaxDouble;
  for R := 1 to 200 do
  begin
    V := StrToFloat(G.Cells[3, R]);
    VMin := Min(VMin, V);
    VMax := Max(VMax, V);
  end;
  for R := 1 to 200 do
  begin
    St.Reset;
    G.ConditionalFormats.Apply(1, G.Cells[1, R], Tok, clWhite, St);
    CheckEquals(TryStrToFloat(G.Cells[1, R], V) and (V >= ThrTop), St.Fill <> clNone,
      'Oben-10 % Zeile ' + IntToStr(R));
    St.Reset;
    G.ConditionalFormats.Apply(2, G.Cells[2, R], Tok, clWhite, St);
    // Double wie im Grid (StrToFloat liefert Extended)
    V := StrToFloat(G.Cells[2, R]);
    CheckEquals(V <= ThrBot, St.Fill <> clNone, 'Unten-7 Zeile ' + IntToStr(R));
    St.Reset;
    G.ConditionalFormats.Apply(3, G.Cells[3, R], Tok, clWhite, St);
    V := StrToFloat(G.Cells[3, R]);
    T := (V - VMin) / (VMax - VMin);
    C := PPGBlendColor(clWhite, Scale.RuleColor(Tok), T);
    CheckEquals(Integer(PPGBlendColor(clWhite, C, 0.45)), Integer(St.Fill),
      'Farbskala Zeile ' + IntToStr(R));
  end;
end;

{ ---- Spaltenbreite ---- }

procedure TAudit8BTests.ColumnWidthKeepsFooterAndStyles;
var
  G: TPPGGrid;
  Before, StyleBefore, StyleAfter: string;
  I, R: Integer;
  Rule: TPPGGridConditionalFormat;
  St: TPPGGridCellStyle;
  Tok: TPPGTokens;
begin
  G := AggGrid;
  G.RowHeights[0] := 30;
  Rule := G.ConditionalFormats.Add;
  Rule.Column := 3;
  Rule.Rule := crColorScale;
  Application.ProcessMessages;
  Before := AggTexts(G);
  Tok := PPGDefaultTokens(False);
  StyleBefore := '';
  for R := 1 to 8 do
  begin
    St.Reset;
    G.ConditionalFormats.Apply(3, G.Cells[3, R], Tok, clWhite, St);
    StyleBefore := StyleBefore + IntToStr(St.Fill) + ';';
  end;
  for I := 0 to 19 do
  begin
    G.ColWidths[3] := 50 + I;
    G.Columns[2].Width := 70 + I;
    Application.ProcessMessages;
  end;
  CheckEquals(Before, AggTexts(G), 'Summen unveraendert');
  StyleAfter := '';
  for R := 1 to 8 do
  begin
    St.Reset;
    G.ConditionalFormats.Apply(3, G.Cells[3, R], Tok, clWhite, St);
    StyleAfter := StyleAfter + IntToStr(St.Fill) + ';';
  end;
  CheckEquals(StyleBefore, StyleAfter, 'Farbskala unveraendert');
  CheckEquals(69, G.ColWidths[3]);
  CheckEquals(89, G.ColWidths[2]);
  CheckEquals(30, G.RowHeights[0]);
  CheckEquals(30, TGridAccess(G).RawCellRect(1, 0).Bottom - TGridAccess(G).RawCellRect(1, 0).Top);
  // Aggregat geaendert: Summen neu
  G.Columns[3].Aggregate := agMax;
  CheckEquals('30', G.FooterText(3));
end;

procedure TAudit8BTests.ColumnWidthDoesNotRecalc;
var
  G: TPPGGrid;
  Rule: TPPGGridConditionalFormat;
  N, RG, I: Integer;
begin
  G := AggGrid;
  G.RowHeights[0] := 30;
  Rule := G.ConditionalFormats.Add;
  Rule.Column := 3;
  Rule.Rule := crColorScale;
  Application.ProcessMessages;
  N := TGridAccess(G).AggRecalcCount;
  RG := TGridAccess(G).RowGeomCount;
  for I := 0 to 9 do
  begin
    G.ColWidths[3] := 50 + I;
    G.Columns[2].Width := 80 + I;
    G.Columns[1].Title := 'Titel ' + IntToStr(I);
    G.Columns[4].Visible := Odd(I);
    Application.ProcessMessages;
  end;
  CheckEquals(N, TGridAccess(G).AggRecalcCount, 'Spaltenbreite rechnet keine Summen');
  CheckEquals(RG, TGridAccess(G).RowGeomCount, 'Spaltenbreite baut die Zeilen nicht neu auf');
  G.Columns[3].Aggregate := agAvg;
  Application.ProcessMessages;
  CheckEquals(N + 1, TGridAccess(G).AggRecalcCount, 'Aggregat geaendert: einmal neu');
  CheckEquals('8,25', TGridAccess(G).CachedFooterText(3));
  // Ohne Spalten (ColWidths direkt)
  G := NewGrid;
  G.ColCount := 4;
  G.RowCount := 10;
  N := TGridAccess(G).AggRecalcCount;
  RG := TGridAccess(G).RowGeomCount;
  for I := 0 to 9 do
    G.ColWidths[2] := 40 + I;
  Application.ProcessMessages;
  CheckEquals(N, TGridAccess(G).AggRecalcCount);
  CheckEquals(RG, TGridAccess(G).RowGeomCount);
  CheckEquals(49, G.ColWidths[2]);
  CheckEquals(49, TGridAccess(G).RawCellRect(2, 1).Right - TGridAccess(G).RawCellRect(2, 1).Left);
end;

{ ---- Zeilenhoehen ---- }

procedure TAudit8BTests.RowHeightsFollowDataRows;
var
  G: TPPGGrid;
  R: Integer;

  procedure CheckHeights(const What: string);
  var
    V, D: Integer;
    RR: TRect;
    Sum: Integer;
  begin
    Sum := 0;
    for V := 0 to TGridAccess(G).VRowCount - 1 do
    begin
      D := G.DataRow(V);
      RR := TGridAccess(G).RawCellRect(1, V);
      if D >= 0 then
        CheckEquals(G.RowHeights[D], RR.Bottom - RR.Top, What + ' Zeile ' + IntToStr(D));
      Inc(Sum, RR.Bottom - RR.Top);
    end;
    RR := TGridAccess(G).RawCellRect(1, TGridAccess(G).VRowCount - 1);
    CheckEquals(Sum, RR.Bottom - TGridAccess(G).RawCellRect(1, 0).Top, What + ' Gesamthoehe');
  end;

begin
  G := NewGrid(420, 600);
  G.ColCount := 3;
  G.RowCount := 12;
  for R := 1 to 11 do
  begin
    G.Cells[1, R] := IntToStr(12 - R);
    G.Cells[2, R] := IntToStr(R mod 2);
  end;
  G.RowHeights[0] := 30;
  G.RowHeights[3] := 40;
  G.RowHeights[7] := 10;
  G.RowHeights[11] := 33;
  CheckHeights('unsortiert');
  CheckEquals(40, G.RowHeights[3]);
  CheckEquals(24, G.RowHeights[4]);
  G.SortBy(1, True);
  CheckHeights('sortiert');
  G.Filters[2] := '1';
  CheckHeights('gefiltert');
  G.ClearFilters;
  G.ShowFilterRow := True;
  CheckHeights('Filterzeile');
  G.ShowFilterRow := False;
  G.RowHeights[3] := 0;
  CheckEquals(24, G.RowHeights[3], '0 = Standard');
  CheckHeights('zurueckgesetzt');
end;

procedure TAudit8BTests.RowHeightsMillionRows;
var
  G: TPPGGrid;
  R: TRect;
  V: Integer;
  T0: Cardinal;
begin
  SetLength(FVirt, 0);
  G := NewGrid;
  G.ColCount := 3;
  G.OnGetCellText := VirtText;
  G.RowCount := 1000001;
  T0 := GetTickCount;
  G.RowHeights[0] := 30;
  G.RowHeights[3] := 10;
  G.RowHeights[999999] := 40;
  for V := 0 to 49 do
    G.ColWidths[1] := 60 + V;
  CheckTrue(GetTickCount - T0 < 2000, Format('%d ms', [GetTickCount - T0]));
  R := TGridAccess(G).RawCellRect(1, 0);
  CheckEquals(30, R.Bottom - R.Top);
  R := TGridAccess(G).RawCellRect(1, 3);
  CheckEquals(10, R.Bottom - R.Top);
  CheckEquals(30 + 24 + 24, R.Top - TGridAccess(G).RawCellRect(1, 0).Top);
  V := G.VisualRow(999999);
  R := TGridAccess(G).RawCellRect(1, V);
  CheckEquals(40, R.Bottom - R.Top);
  // Gesamthoehe: 1 000 001 Zeilen, drei davon mit eigener Hoehe
  R := TGridAccess(G).RawCellRect(1, 1000000);
  CheckEquals(Int64(30) + 10 + 40 + Int64(999998) * 24,
    Int64(R.Bottom) - TGridAccess(G).RawCellRect(1, 0).Top);
end;

procedure TAudit8BTests.RowHeightsStreaming;
var
  G, G2: TPPGGrid;
  M: TMemoryStream;
  R: Integer;
  S: TStringStream;
begin
  G := NewGrid;
  G.ColCount := 3;
  G.RowCount := 10;
  M := TMemoryStream.Create;
  S := TStringStream.Create('');
  try
    // Ohne eigene Hoehen: nichts gespeichert
    M.WriteComponent(G);
    M.Position := 0;
    ObjectBinaryToText(M, S);
    CheckEquals(0, Pos('RowHeights', S.DataString), 'keine Hoehen');
    G.RowHeights[2] := 50;
    G.RowHeights[5] := 24; // gleich dem Standard
    G.RowHeights[9] := 12;
    M.Clear;
    S.Size := 0;
    M.WriteComponent(G);
    M.Position := 0;
    ObjectBinaryToText(M, S);
    CheckTrue(Pos('RowHeights', S.DataString) > 0, 'Hoehen gespeichert');
    M.Position := 0;
    G2 := TPPGGrid.Create(FForm);
    G2.Parent := FForm;
    M.ReadComponent(G2);
    for R := 0 to 9 do
      CheckEquals(G.RowHeights[R], G2.RowHeights[R], 'Zeile ' + IntToStr(R));
    // Gelesener Standardwert gilt als Standard (folgt DefaultRowHeight)
    G2.DefaultRowHeight := 30;
    CheckEquals(30, G2.RowHeights[5]);
    CheckEquals(50, G2.RowHeights[2]);
    CheckEquals(30, G2.RowHeights[0]);
  finally
    S.Free;
    M.Free;
  end;
end;

procedure TAudit8BTests.RowHeightsRowCountAndDefault;
var
  G: TPPGGrid;
begin
  G := NewGrid;
  G.ColCount := 2;
  G.RowCount := 11;
  G.RowHeights[9] := 40;
  G.RowHeights[4] := 24;
  G.RowCount := 5;
  G.RowCount := 11;
  CheckEquals(24, G.RowHeights[9], 'gekuerzte Zeile vergessen');
  G.DefaultRowHeight := 30;
  CheckEquals(24, G.RowHeights[4], 'explizit gesetzte Hoehe bleibt');
  CheckEquals(30, G.RowHeights[3]);
  try
    G.RowHeights[11] := 5;
    Fail('Index ausserhalb');
  except
    on E: Exception do
      CheckTrue(E.ClassName <> 'ETestFailure', E.ClassName);
  end;
end;

procedure TAudit8BTests.RowLayoutMatchesModel;
var
  L: TPPGRowLayout;
  Model: array of Integer;
  I, Step, Idx, H, N, Def: Integer;
  Y: Int64;

  function ModelHeight(AI: Integer): Integer;
  begin
    if Model[AI] > 0 then
      Result := Model[AI]
    else
      Result := Def;
  end;

  procedure CheckModel(const What: string);
  var
    K, Probe: Integer;
    Top: Int64;
  begin
    CheckEquals(Length(Model), L.Count, What + ' Count');
    Top := 0;
    for K := 0 to High(Model) do
    begin
      CheckEquals(Top, L.RowTop(K), What + ' RowTop ' + IntToStr(K));
      CheckEquals(ModelHeight(K), L.RowHeight(K), What + ' RowHeight ' + IntToStr(K));
      for Probe := 0 to 2 do
        CheckEquals(K, L.RowAt(Top + (ModelHeight(K) - 1) * Probe div 2),
          What + ' RowAt ' + IntToStr(K));
      Inc(Top, ModelHeight(K));
    end;
    CheckEquals(Top, L.TotalHeight64, What + ' Gesamt');
    CheckEquals(-1, L.RowAt(Top), What + ' hinter dem Ende');
  end;

begin
  RandSeed := 1234;
  L := TPPGRowLayout.Create;
  try
    Def := 20;
    L.DefaultHeight := Def;
    L.Count := 300;
    SetLength(Model, 300);
    CheckModel('leer');
    for Step := 0 to 199 do
    begin
      N := Length(Model);
      case Random(5) of
        0, 1:
          if N > 0 then
          begin
            Idx := Random(N);
            if Random(4) = 0 then
              H := 0
            else
              H := 1 + Random(60);
            L.SetRowHeight(Idx, H);
            Model[Idx] := H;
          end;
        2:
          begin
            Idx := Random(N + 1);
            H := 1 + Random(4);
            L.RowsInserted(Idx, H);
            SetLength(Model, N + H);
            for I := N + H - 1 downto Idx + H do
              Model[I] := Model[I - H];
            for I := Idx to Idx + H - 1 do
              Model[I] := 0;
          end;
        3:
          if N > 0 then
          begin
            Idx := Random(N);
            H := 1 + Random(5);
            if Idx + H > N then
              H := N - Idx;
            L.RowsDeleted(Idx, H);
            for I := Idx to N - H - 1 do
              Model[I] := Model[I + H];
            SetLength(Model, N - H);
          end;
      else
        begin
          if Random(2) = 0 then
            Def := 10 + Random(20);
          L.DefaultHeight := Def;
        end;
      end;
      if Step mod 20 = 0 then
        CheckModel('Schritt ' + IntToStr(Step));
    end;
    CheckModel('Ende');
    // Count verkleinern und wieder vergroessern: Hoehen dahinter verfallen
    N := Length(Model) div 2;
    L.Count := N;
    SetLength(Model, N);
    L.Count := N + 10;
    SetLength(Model, N + 10);
    for I := N to N + 9 do
      Model[I] := 0;
    CheckModel('Count');
    L.ClearHeights;
    for I := 0 to High(Model) do
      Model[I] := 0;
    CheckModel('ClearHeights');
    CheckFalse(L.Variable);
    Y := L.TotalHeight64;
    CheckEquals(Int64(Length(Model)) * Def, Y);
  finally
    L.Free;
  end;
end;

{ ---- Zellspeicher ---- }

procedure TAudit8BTests.CellStoreGrowsAndTruncates;
var
  G: TPPGGrid;
  R: Integer;
begin
  G := NewGrid;
  G.ColCount := 3;
  G.RowCount := 20001;
  for R := 1 to 20000 do
    G.Cells[R mod 3, R] := IntToStr(R);
  for R := 1 to 20000 do
    CheckEquals(IntToStr(R), G.Cells[R mod 3, R]);
  CheckEquals('', G.Cells[(1 + 1) mod 3, 1]);
  G.RowCount := 100;
  G.RowCount := 20001;
  CheckEquals('', G.Cells[19999 mod 3, 19999], 'gekuerzt');
  CheckEquals('99', G.Cells[0, 99]);
  G.ColCount := 2;
  G.ColCount := 3;
  CheckEquals('', G.Cells[2, 98], 'Spalte gekuerzt');
end;

{ ---- Zeichnen ---- }

function TAudit8BTests.RenderConfig(Index: Integer): TBitmap;
var
  G: TPPGGrid;
  R, C: Integer;
  Rule: TPPGGridConditionalFormat;
  Sel: TGridRect;
begin
  G := NewGrid(520, 320);
  try
    G.Columns.Add.Title := '#';
    for C := 1 to 6 do
      G.Columns.Add.Title := 'Spalte ' + IntToStr(C);
    G.FixedCols := 1;
    G.RowCount := 40;
    for R := 1 to 39 do
    begin
      G.Cells[0, R] := IntToStr(R);
      G.Cells[1, R] := 'Name ' + IntToStr((R * 7) mod 13);
      G.Cells[2, R] := IntToStr((R * 37) mod 100);
      G.Cells[3, R] := IntToStr(R mod 6);
      G.Cells[4, R] := 'https://x.de/' + IntToStr(R);
      G.Cells[5, R] := IntToStr(R mod 2);
      G.Cells[6, R] := FloatToStr(R / 4);
    end;
    case Index of
      0:
        begin
          G.Styles.AlternateRow.Color := $00F4ECE0;
          G.Styles.HotRow.Color := $00C0FFFF;
          G.Columns[3].Style.Color := $00E0FFE0;
          G.Columns[2].TitleStyle.Color := $00FFE0E0;
          G.Columns[6].Style.TextColor := clRed;
          Sel.Left := 2;
          Sel.Top := 3;
          Sel.Right := 4;
          Sel.Bottom := 6;
          G.Selection := Sel;
        end;
      1, 6:
        begin
          Rule := G.ConditionalFormats.Add;
          Rule.Column := 2;
          Rule.Rule := crTop;
          Rule.Value1 := '20%';
          Rule := G.ConditionalFormats.Add;
          Rule.Column := 6;
          Rule.Rule := crColorScale;
          Rule.Color := ccSuccess;
          Rule := G.ConditionalFormats.Add;
          Rule.Column := 3;
          Rule.Rule := crDataBar;
          Rule := G.ConditionalFormats.Add;
          Rule.Column := 1;
          Rule.Rule := crContains;
          Rule.Value1 := '1';
          Rule.Target := ctText;
          Rule.Bold := True;
          Rule := G.ConditionalFormats.Add;
          Rule.Column := 5;
          Rule.Rule := crIconSet;
          G.Styles.AlternateRow.Color := $00F4ECE0;
          if Index = 6 then
            TPPGRendererRegistry.ForceGdiFallback := True;
        end;
      2, 5:
        begin
          G.Columns[2].CellKind := ckProgress;
          G.Columns[3].CellKind := ckRating;
          G.Columns[4].CellKind := ckLink;
          G.Columns[5].CellKind := ckCheck;
          G.Columns[6].CellKind := ckButton;
          G.Columns[1].CellKind := ckColor;
          for R := 1 to 39 do
            if Odd(R) then
              G.Cells[1, R] := 'clRed'
            else
              G.Cells[1, R] := '#00A0FF';
          if Index = 5 then
            G.BiDiMode := bdRightToLeft;
        end;
      3:
        begin
          G.Columns[2].Aggregate := agSum;
          G.Columns[6].Aggregate := agAvg;
          G.ShowFooter := True;
          G.GroupFooter := True;
          G.ShowFilterRow := True;
          G.ShowGroupPanel := True;
          G.GroupBy([3]);
          G.SortBy(2, False);
          G.ExpandGroup(1, False);
        end;
      4:
        begin
          G.Bands.Add.Caption := 'Band A';
          G.Bands.Add.Caption := 'Band B';
          G.Columns[1].Band := 0;
          G.Columns[2].Band := 0;
          G.Columns[3].Band := 1;
          G.FixedColsRight := 1;
          G.MergeCells(1, 2, 2, 2);
          G.MergeCells(3, 5, 1, 3);
          G.RowHeights[4] := 40;
          G.RowHeights[6] := 14;
          G.Options := G.Options + [goRowSelect];
          G.Row := 9;
        end;
    end;
    Application.ProcessMessages;
    // Hover-Zeile erst direkt vor dem Zeichnen (keine Nachricht dazwischen)
    if Index = 0 then
      G.Perform(WM_MOUSEMOVE, 0, MakeLParam(200, 24 * 8 + 10));
    Result := RenderToBitmap(G);
  finally
    TPPGRendererRegistry.ForceGdiFallback := False;
    G.Free;
  end;
end;

procedure TAudit8BTests.PaintUnchanged;
var
  I, D: Integer;
  B, Ref: TBitmap;
  Png: TPngImage;
  Dir, F: string;
  Errors, Created: TStringList;
begin
  Dir := ExtractFilePath(ParamStr(0)) + 'Visual\Audit8B\';
  ForceDirectories(Dir);
  Errors := TStringList.Create;
  Created := TStringList.Create;
  try
    for I := 0 to 6 do
    begin
      B := RenderConfig(I);
      try
        F := Dir + 'Grid8B_' + IntToStr(I) + '.png';
        if not FileExists(F) then
        begin
          Png := TPngImage.Create;
          try
            Png.Assign(B);
            Png.SaveToFile(F);
          finally
            Png.Free;
          end;
          Created.Add(ExtractFileName(F));
          Continue;
        end;
        Png := TPngImage.Create;
        Ref := TBitmap.Create;
        try
          Png.LoadFromFile(F);
          Ref.Assign(Png);
          Ref.PixelFormat := pf24bit;
          D := PPGPixelDiff(B, Ref, 0);
          if D <> 0 then
            Errors.Add(Format('Bild %d: %d Pixel abweichend', [I, D]));
        finally
          Ref.Free;
          Png.Free;
        end;
      finally
        B.Free;
      end;
    end;
    if Created.Count > 0 then
      Status('Referenzbilder angelegt: ' + Created.CommaText);
    CheckEquals('', Errors.Text, 'Grid zeichnet anders: ' + Errors.Text);
  finally
    Created.Free;
    Errors.Free;
  end;
end;

initialization
  RegisterTest('Audit8B', TAudit8BTests.Suite);

end.
