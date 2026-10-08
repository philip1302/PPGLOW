unit PPG.Tests.Phase17;

{ Tests fuer Phase 17: Druck, PDF und HTML mit der Optik des Grids
  (IPPGTableLook, PPG.Grid.Look). Gedruckt wird nicht: Seiten werden auf
  Bitmaps mit 96 dpi gezeichnet und Pixel geprueft. }

interface

uses
  TestFramework, Winapi.Windows, System.Classes, System.SysUtils, System.Types,
  System.Variants, Vcl.Graphics, Vcl.Forms, Vcl.Grids,
  PPG.Grid, PPG.Grid.Columns, PPG.Grid.Data, PPG.Grid.Styles, PPG.Grid.Print,
  PPG.Grid.Look, PPG.Grid.Export, PPG.Tests.Controls;

type
  TGridLookPrintTests = class(TControlTestCase)
  private
    FPrn: TPPGGridPrinter;
    FDev: TPPGPrintDevice;
    function SampleGrid(Rows: Integer = 6): TPPGGrid;
    function Render(PageIndex: Integer): TBitmap;
    /// Mitte einer Zeile (0 = erste Zeile unter dem Seitenkopf) in Spalte ACol,
    /// DX Punkte vor deren rechter Kante (dort steht kein Text).
    function CellPoint(ACol, ALine, DX: Integer): TPoint;
    function Look(G: TPPGGrid): TPPGTableLook;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure HeaderUsesGridColors;
    procedure PlainLookWithoutOption;
    procedure BandsAddHeadRow;
    procedure GroupsAndFooterAreLines;
    procedure GroupHeaderNeverAloneAtPageEnd;
    procedure FooterOnlyOnLastPage;
    procedure ZebraAndConditionalFill;
    procedure MergedCellsHaveNoInnerLine;
    procedure OptionAndStreaming;
    procedure SharedHelpers;
  end;

  THtmlLookTests = class(TControlTestCase)
  private
    function SampleGrid: TPPGGrid;
  published
    procedure HeaderBandsGroupsFooter;
    procedure CellKindsAsSymbolsAndBars;
    procedure LinksOnlySafeSchemes;
    procedure MergedCellsSpan;
    procedure PlainSourceStaysSimple;
  end;

implementation

uses
  System.StrUtils, PPG.Exceptions;

const
  Cats: array[0..2] of string = ('Obst', 'Brot', 'Milch');

function Src(G: TPPGGrid): IPPGTableSource;
begin
  Supports(G, IPPGTableSource, Result);
end;

function FillGrid(G: TPPGGrid; Rows: Integer): TPPGGrid;
var
  R: Integer;
begin
  G.Columns.Add.Title := 'Name';
  G.Columns.Add.Title := 'Kategorie';
  G.Columns.Add.Title := 'Preis';
  G.Columns.Add.Title := 'Menge';
  G.FixedCols := 0;
  G.Columns[0].Width := 160;
  G.Columns[1].Width := 120;
  G.Columns[2].Width := 100;
  G.Columns[3].Width := 100;
  G.RowCount := Rows + 1;
  for R := 1 to Rows do
  begin
    G.Cells[0, R] := 'Artikel ' + IntToStr(R);
    G.Cells[1, R] := Cats[R mod 3];
    G.Cells[2, R] := IntToStr(R * 2);
    G.Cells[3, R] := IntToStr(R);
  end;
  Result := G;
end;

{ TGridLookPrintTests }

procedure TGridLookPrintTests.SetUp;
begin
  inherited SetUp;
  FPrn := TPPGGridPrinter.Create(nil);
  FDev := TPPGPrintDevice.A4(96, False);
end;

procedure TGridLookPrintTests.TearDown;
begin
  FreeAndNil(FPrn);
  inherited TearDown;
end;

function TGridLookPrintTests.SampleGrid(Rows: Integer): TPPGGrid;
begin
  Result := TPPGGrid.Create(FForm);
  Result.Parent := FForm;
  FillGrid(Result, Rows);
  FPrn.Grid := Result;
end;

function TGridLookPrintTests.Render(PageIndex: Integer): TBitmap;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(FDev.PageWidth, FDev.PageHeight);
  Result.Canvas.Brush.Color := clWhite;
  Result.Canvas.FillRect(Rect(0, 0, FDev.PageWidth, FDev.PageHeight));
  FPrn.RenderPage(PageIndex, Result.Canvas.Handle, FDev);
end;

function TGridLookPrintTests.CellPoint(ACol, ALine, DX: Integer): TPoint;
var
  I, X: Integer;
begin
  FPrn.PageCount(FDev);
  X := FPrn.ContentRect.Left;
  for I := 0 to ACol do
    Inc(X, FPrn.LayoutColWidth(I));
  Result.X := X - DX;
  Result.Y := FPrn.ContentRect.Top + ALine * FPrn.LayoutRowHeight + FPrn.LayoutRowHeight div 2;
end;

function TGridLookPrintTests.Look(G: TPPGGrid): TPPGTableLook;
var
  L: IPPGTableLook;
begin
  CheckTrue(Supports(G, IPPGTableLook, L));
  Result := L.ExportLook;
end;

procedure TGridLookPrintTests.HeaderUsesGridColors;
var
  G: TPPGGrid;
  B: TBitmap;
  P: TPoint;
begin
  G := SampleGrid;
  G.Styles.Header.Color := $00336699;
  G.Columns[3].TitleStyle.Color := $00445566;
  B := Render(0);
  try
    P := CellPoint(0, 0, 6);
    CheckEquals($00336699, B.Canvas.Pixels[P.X, P.Y], 'Kopf wie Styles.Header');
    P := CellPoint(3, 0, 6);
    CheckEquals($00445566, B.Canvas.Pixels[P.X, P.Y], 'TitleStyle der Spalte');
  finally
    B.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TGridLookPrintTests.PlainLookWithoutOption;
var
  G: TPPGGrid;
  B: TBitmap;
  P: TPoint;
begin
  // Gegenprobe: UseGridLook = False druckt wie vor Phase 17
  G := SampleGrid;
  G.Styles.Header.Color := $00336699;
  FPrn.UseGridLook := False;
  B := Render(0);
  try
    P := CellPoint(0, 0, 6);
    CheckEquals($00F0F0F0, B.Canvas.Pixels[P.X, P.Y], 'grauer Kopf');
  finally
    B.Free;
  end;
  // Ohne Farben: Kopf weiss
  FPrn.UseGridLook := True;
  FPrn.PrintColors := False;
  FPrn.Invalidate;
  B := Render(0);
  try
    P := CellPoint(0, 0, 6);
    CheckEquals(clWhite, B.Canvas.Pixels[P.X, P.Y], 'PrintColors = False');
  finally
    B.Free;
  end;
end;

procedure TGridLookPrintTests.BandsAddHeadRow;
var
  G: TPPGGrid;
  B: TBitmap;
  P: TPoint;
  Without: Integer;
begin
  G := SampleGrid(200);
  FPrn.PageCount(FDev);
  CheckEquals(1, FPrn.LayoutHeadRows);
  Without := FPrn.Page(0).RowCount;
  G.Styles.Header.Color := $00336699;
  G.Bands.Add.Caption := 'Ware';
  G.Columns[0].Band := 0;
  G.Columns[1].Band := 0;
  FPrn.Invalidate;
  FPrn.PageCount(FDev);
  CheckEquals(2, FPrn.LayoutHeadRows, 'Bandzeile + Spaltenkoepfe');
  CheckEquals(Without - 1, FPrn.Page(0).RowCount, 'eine Datenzeile weniger je Seite');
  CheckEquals(2, FPrn.LayoutHeadRows);
  B := Render(1);
  try
    // Bandzeile auf jeder Seite (RepeatHeader), auch ueber Spalten ohne Band
    P := CellPoint(3, 0, 6);
    CheckEquals($00336699, B.Canvas.Pixels[P.X, P.Y], 'Bandzeile in Kopffarbe');
  finally
    B.Free;
  end;
end;

procedure TGridLookPrintTests.GroupsAndFooterAreLines;
var
  G: TPPGGrid;
  B: TBitmap;
  P: TPoint;
  L: TPPGTableLook;
begin
  G := SampleGrid; // 6 Zeilen, 3 Kategorien
  G.Columns[2].Aggregate := agSum;
  G.ShowFooter := True;
  G.GroupBy([1]);
  G.Styles.GroupRow.Color := $00225588;
  G.Styles.Footer.Color := $00113377;
  CheckEquals(1, FPrn.PageCount(FDev));
  CheckEquals(3 + 6 + 1, FPrn.Page(0).RowCount, 'Gruppenkoepfe, Datenzeilen, Summe');
  CheckTrue(FPrn.LayoutLineKind(0) = tlGroup);
  CheckTrue(FPrn.LayoutLineKind(1) = tlData);
  CheckTrue(FPrn.LayoutLineKind(9) = tlFooter);
  L := Look(G);
  B := Render(0);
  try
    P := CellPoint(3, 1, 6); // Zeile 1 = erste Druckzeile (Gruppenkopf)
    CheckEquals(L.GroupFill, B.Canvas.Pixels[P.X, P.Y], 'Gruppenzeile ueber alle Spalten');
    P := CellPoint(3, 1 + 9, 6);
    CheckEquals(L.FooterFill, B.Canvas.Pixels[P.X, P.Y], 'Summenzeile');
  finally
    B.Free;
  end;
  // Ohne sichtbare Summenzeile im Grid auch keine im Druck
  G.ShowFooter := False;
  FPrn.Invalidate;
  FPrn.PageCount(FDev);
  CheckEquals(3 + 6, FPrn.Page(0).RowCount);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TGridLookPrintTests.GroupHeaderNeverAloneAtPageEnd;
var
  G: TPPGGrid;
  I, N, Sum, LastLine: Integer;
begin
  G := SampleGrid(300);
  G.GroupBy([1, 0]); // viele Gruppen in zwei Ebenen
  N := FPrn.PageCount(FDev);
  CheckTrue(N > 3, 'mehrere Seiten');
  Sum := 0;
  for I := 0 to N - 1 do
  begin
    CheckEquals(Sum, FPrn.Page(I).RowFirst, 'lueckenlos');
    Inc(Sum, FPrn.Page(I).RowCount);
    LastLine := FPrn.Page(I).RowFirst + FPrn.Page(I).RowCount - 1;
    if I < N - 1 then
      CheckTrue(FPrn.LayoutLineKind(LastLine) <> tlGroup,
        'Seite ' + IntToStr(I + 1) + ' endet mit einem Gruppenkopf');
  end;
  CheckEquals(300 + 3 + 300, Sum, 'alle Druckzeilen (3 Kategorien, je Artikel eine Gruppe)');
end;

procedure TGridLookPrintTests.FooterOnlyOnLastPage;
var
  G: TPPGGrid;
  I, J, N: Integer;
begin
  G := SampleGrid(200);
  G.Columns[2].Aggregate := agSum;
  G.ShowFooter := True;
  N := FPrn.PageCount(FDev);
  CheckTrue(N > 1);
  for I := 0 to N - 1 do
    for J := FPrn.Page(I).RowFirst to FPrn.Page(I).RowFirst + FPrn.Page(I).RowCount - 1 do
      CheckEquals(Ord(I = N - 1) * Ord(J = 200), Ord(FPrn.LayoutLineKind(J) = tlFooter),
        'Summe nur als letzte Zeile');
end;

procedure TGridLookPrintTests.ZebraAndConditionalFill;
var
  G: TPPGGrid;
  CF: TPPGGridConditionalFormat;
  B: TBitmap;
  P: TPoint;
begin
  G := SampleGrid;
  G.Styles.AlternateRow.Color := $00EEDDCC;
  G.Columns[1].Style.Color := $00112233;
  CF := G.ConditionalFormats.Add;
  CF.Column := 3;
  CF.Rule := crRange;
  CF.Value2 := '1';
  CF.Color := ccCustom;
  CF.CustomColor := $000000C0;
  B := Render(0);
  try
    P := CellPoint(0, 1, 6);
    CheckEquals(clWhite, B.Canvas.Pixels[P.X, P.Y], 'erste Datenzeile ohne Zebra');
    P := CellPoint(0, 2, 6);
    CheckEquals($00EEDDCC, B.Canvas.Pixels[P.X, P.Y], 'zweite Datenzeile Zebra');
    P := CellPoint(1, 2, 6);
    CheckEquals($00112233, B.Canvas.Pixels[P.X, P.Y], 'Spaltenstil vor Zebra');
    P := CellPoint(3, 1, 40);
    CheckTrue(B.Canvas.Pixels[P.X, P.Y] <> clWhite, 'bedingte Flaeche (Menge 1)');
    P := CellPoint(3, 3, 40);
    CheckEquals(clWhite, B.Canvas.Pixels[P.X, P.Y], 'Menge 3 ohne Regel');
  finally
    B.Free;
  end;
end;

procedure TGridLookPrintTests.MergedCellsHaveNoInnerLine;
var
  G: TPPGGrid;
  B: TBitmap;
  P: TPoint;
  L: TPPGTableLook;
begin
  G := SampleGrid;
  G.Styles.GridLine.Color := $00102030;
  G.MergeCells(0, 1, 2, 1); // erste Datenzeile: Name + Kategorie
  L := Look(G);
  B := Render(0);
  try
    P := CellPoint(0, 2, 0); // Kante zwischen Spalte 0 und 1, zweite Datenzeile
    CheckEquals(L.Line, B.Canvas.Pixels[P.X, P.Y], 'Linie zwischen normalen Zellen');
    P := CellPoint(0, 1, 0);
    CheckTrue(B.Canvas.Pixels[P.X, P.Y] <> L.Line, 'keine Linie in der verbundenen Zelle');
  finally
    B.Free;
  end;
end;

procedure TGridLookPrintTests.OptionAndStreaming;
var
  M: TMemoryStream;
  P2: TPPGGridPrinter;
begin
  CheckEquals(5, FPrn.OptionCount);
  CheckTrue(FPrn.GetOption(4), 'Vorgabe: Optik des Grids');
  FPrn.SetOption(4, False);
  CheckFalse(FPrn.UseGridLook);
  CheckTrue(FPrn.OptionCaption(4) <> '');
  M := TMemoryStream.Create;
  P2 := TPPGGridPrinter.Create(nil);
  try
    M.WriteComponent(FPrn);
    M.Position := 0;
    M.ReadComponent(P2);
    CheckFalse(P2.UseGridLook, 'DFM');
  finally
    P2.Free;
    M.Free;
  end;
end;

procedure TGridLookPrintTests.SharedHelpers;
var
  S: TPPGStringTableSource;
  T: IPPGTableSource;
  Lines: TPPGTableLines;
begin
  CheckEquals(#$2605#$2605#$2606, PPGStarsText(2, 3));
  CheckEquals(#$2605#$2605#$2605, PPGStarsText(9, 3), 'geklemmt');
  CheckEquals(5, PPGRatingStars(0));
  CheckEquals(20, PPGRatingStars(99));
  CheckTrue(PPGValueChecked(True));
  CheckTrue(PPGValueChecked('Ja'));
  CheckTrue(PPGValueChecked(1));
  CheckFalse(PPGValueChecked('0'));
  CheckEquals(0.5, PPGProgressFraction('50', 0, 0), 0.0001, 'Vorgabe 0..100');
  CheckEquals(0.25, PPGProgressFraction(100, 0, 400), 0.0001);
  CheckEquals(0, PPGProgressFraction('x9999', 0, 10), 0.0001, 'kein Wert = Minimum');
  // Ohne Gliederung: Zeile I = Tabellenzeile I
  S := TPPGStringTableSource.Create(['A']);
  T := S;
  S.AddRow(['1']);
  S.AddRow(['2']);
  Lines := TPPGTableLines.Create(T, True, True);
  try
    CheckEquals(3, Lines.Count);
    CheckEquals(1, Lines.Row(1));
    CheckTrue(Lines.Kind(2) = tlFooter);
    CheckEquals(-1, Lines.Row(2));
    CheckFalse(Lines.Grouped);
  finally
    Lines.Free;
  end;
end;

{ THtmlLookTests }

function THtmlLookTests.SampleGrid: TPPGGrid;
begin
  Result := TPPGGrid.Create(FForm);
  Result.Parent := FForm;
  FillGrid(Result, 6);
end;

procedure THtmlLookTests.HeaderBandsGroupsFooter;
var
  G: TPPGGrid;
  H: string;
begin
  G := SampleGrid;
  G.Styles.Header.Color := $00336699;
  G.Bands.Add.Caption := 'Ware';
  G.Columns[0].Band := 0;
  G.Columns[1].Band := 0;
  G.Columns[2].Aggregate := agSum;
  G.ShowFooter := True;
  H := PPGExportHtmlText(Src(G));
  CheckTrue(Pos('<th colspan="2" style="text-align:center">Ware</th>', H) > 0, 'Band');
  CheckTrue(Pos('<th colspan="2"></th>', H) > 0, 'leere Bandzelle ueber Preis und Menge');
  CheckTrue(Pos('background:#996633', H) > 0, 'Kopffarbe im CSS');
  CheckTrue(Pos('<tfoot><tr class="f">', H) > 0, 'Summenzeile');
  CheckTrue(Pos('>' + G.FooterText(2) + '</td>', H) > 0, 'Summentext wie im Grid');
  G.GroupBy([1]);
  H := PPGExportHtmlText(Src(G));
  CheckEquals(3, (Length(H) - Length(StringReplace(H, '<tr class="g">', '', [rfReplaceAll]))) div
    Length('<tr class="g">'), 'drei Gruppenzeilen');
  CheckTrue(Pos('<td colspan="4" style="padding-left:6px">Kategorie: ', H) > 0);
end;

procedure THtmlLookTests.CellKindsAsSymbolsAndBars;
var
  G: TPPGGrid;
  CF: TPPGGridConditionalFormat;
  H: string;
begin
  G := SampleGrid;
  G.Columns[0].EditorKind := gekCheck;
  G.Columns[1].CellKind := ckRating;
  G.Columns[2].CellKind := ckProgress;
  G.Columns[2].MaxValue := 20;
  G.Cells[0, 1] := '1';
  G.Cells[1, 1] := '2';
  CF := G.ConditionalFormats.Add;
  CF.Column := 3;
  CF.Rule := crDataBar;
  H := PPGExportHtmlText(Src(G));
  CheckTrue(Pos('<span class="sym" style="color:', H) > 0, 'Symbolschrift');
  CheckTrue(Pos(#$2611 + '</span>', H) > 0, 'Kaestchen angehakt');
  CheckTrue(Pos(#$2610 + '</span>', H) > 0, 'Kaestchen leer');
  CheckTrue(Pos('>' + #$2605#$2605 + '</span><span class="sym" style="color:', H) > 0,
    'zwei gefuellte Sterne, dann leere');
  CheckTrue(Pos('linear-gradient(to right,', H) > 0, 'Fortschritt/Datenbalken als Verlauf');
  CheckTrue(Pos(' 10%,', H) > 0, 'Preis 2 von 20 = 10 %');
  CheckTrue(Pos('>10 %</td>', H) > 0, 'Prozenttext wie im Grid');
end;

procedure THtmlLookTests.LinksOnlySafeSchemes;
var
  G: TPPGGrid;
  H: string;
begin
  G := SampleGrid;
  G.Columns[0].CellKind := ckLink;
  G.Cells[0, 1] := 'https://example.com/?a=1&b=2';
  G.Cells[0, 2] := 'javascript:alert(1)';
  H := PPGExportHtmlText(Src(G));
  CheckTrue(Pos('<a href="https://example.com/?a=1&amp;b=2">', H) > 0, 'Link');
  CheckEquals(0, Pos('href="javascript', H), 'kein Skript-Link');
  CheckTrue(Pos('text-decoration:underline">javascript:alert(1)<', H) > 0, 'nur eingefaerbt');
end;

procedure THtmlLookTests.MergedCellsSpan;
var
  G: TPPGGrid;
  H: string;
begin
  G := SampleGrid;
  G.MergeCells(0, 1, 2, 2);
  H := PPGExportHtmlText(Src(G));
  CheckTrue(Pos('<td colspan="2" rowspan="2"', H) > 0, 'verbundene Zelle');
  CheckEquals(0, Pos('Artikel 2', H), 'ueberdeckte Zelle entfaellt');
end;

procedure THtmlLookTests.PlainSourceStaysSimple;
var
  S: TPPGStringTableSource;
  T: IPPGTableSource;
  H: string;
begin
  S := TPPGStringTableSource.Create(['A']);
  T := S;
  S.AddRow(['x']);
  H := PPGExportHtmlText(T);
  CheckTrue(Pos('th{background:#f0f0f0}', H) > 0, 'einfache Tabelle wie bisher');
  CheckEquals(0, Pos('.sym', H));
end;

initialization
  RegisterTest('Phase17', TGridLookPrintTests.Suite);
  RegisterTest('Phase17', THtmlLookTests.Suite);

end.
