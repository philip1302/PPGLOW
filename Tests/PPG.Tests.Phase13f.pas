unit PPG.Tests.Phase13f;

{ Tests fuer Phase 13f: xlsx schreiben/lesen, HTML, CSV, PDF. }

interface

uses
  TestFramework, Winapi.Windows, System.Classes, System.SysUtils, System.Variants,
  System.Zip, System.IOUtils, System.DateUtils, Vcl.Graphics, Vcl.Forms,
  PPG.Grid, PPG.Grid.Columns, PPG.Grid.Data, PPG.Grid.Styles, PPG.Grid.Print,
  PPG.Xlsx, PPG.Grid.Export, PPG.Tests.Controls;

type
  TExportTests = class(TControlTestCase)
  private
    FDir: string;
    FOldFS: TFormatSettings;
    function TempFile(const Ext: string): string;
    function ZipPart(const FileName, Part: string): string;
    function SampleGrid: TPPGGrid;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure ExcelSerialDates;
    procedure ColumnNames;
    procedure XmlEscaping;
    procedure RoundTripSimpleSource;
    procedure PackageHasRequiredParts;
    procedure GridValuesFormatsAndViewOrder;
    procedure GroupsBecomeOutline;
    procedure MergesAndFooter;
    procedure ReaderRichAndInlineStrings;
    procedure LoadIntoGrid;
    procedure HtmlExport;
    procedure CsvExport;
    procedure PdfExport;
    procedure ManyRows;
  end;

implementation

uses
  PPG.Exceptions;

function Src(G: TPPGGrid): IPPGTableSource;
begin
  Supports(G, IPPGTableSource, Result);
end;

procedure TExportTests.SetUp;
begin
  inherited SetUp;
  FOldFS := FormatSettings;
  FormatSettings := TFormatSettings.Create('de-DE');
  FDir := TPath.Combine(TPath.GetTempPath, 'PPGlowExport' + IntToStr(GetCurrentProcessId));
  ForceDirectories(FDir);
end;

procedure TExportTests.TearDown;
begin
  FormatSettings := FOldFS;
  if DirectoryExists(FDir) then
    TDirectory.Delete(FDir, True);
  inherited TearDown;
end;

function TExportTests.TempFile(const Ext: string): string;
begin
  Result := TPath.Combine(FDir, 'test' + IntToStr(Random(1000000)) + Ext);
end;

function TExportTests.ZipPart(const FileName, Part: string): string;
var
  Z: TZipFile;
  B: TBytes;
begin
  Z := TZipFile.Create;
  try
    Z.Open(FileName, zmRead);
    Z.Read(Part, B);
    Result := TEncoding.UTF8.GetString(B);
  finally
    Z.Free;
  end;
end;

function TExportTests.SampleGrid: TPPGGrid;
const
  Cats: array[1..6] of string = ('Obst', 'Brot', 'Obst', 'Brot', 'Obst', 'Milch');
var
  R: Integer;
begin
  Result := TPPGGrid.Create(FForm);
  Result.Parent := FForm;
  Result.Columns.Add.Title := 'Name';
  Result.Columns.Add.Title := 'Kategorie';
  Result.Columns.Add.Title := 'Preis';
  Result.Columns.Add.Title := 'Datum';
  Result.FixedCols := 0;
  Result.Columns[2].Format := '#,##0.00';
  Result.Columns[2].Aggregate := agSum;
  Result.Columns[3].Format := 'dd.mm.yyyy';
  Result.RowCount := 7;
  for R := 1 to 6 do
  begin
    Result.Cells[0, R] := 'Artikel ' + IntToStr(R);
    Result.Cells[1, R] := Cats[R];
    Result.Cells[2, R] := FloatToStr(R * 1.5);
    Result.Cells[3, R] := DateToStr(EncodeDate(2026, 1, R));
  end;
end;

procedure TExportTests.ExcelSerialDates;
begin
  CheckEquals(61, PPGExcelSerial(EncodeDate(1900, 3, 1)), 0, '01.03.1900 = 61');
  CheckEquals(1, PPGExcelSerial(EncodeDate(1900, 1, 1)), 0, '01.01.1900 = 1');
  CheckEquals(59, PPGExcelSerial(EncodeDate(1900, 2, 28)), 0);
  CheckEquals(46023, PPGExcelSerial(EncodeDate(2026, 1, 1)), 0);
  CheckEquals(EncodeDate(1900, 1, 1), PPGFromExcelSerial(1), 0);
  CheckEquals(EncodeDate(2026, 1, 1), PPGFromExcelSerial(46023), 0);
end;

procedure TExportTests.ColumnNames;
begin
  CheckEquals('A', PPGXlsxColName(0));
  CheckEquals('Z', PPGXlsxColName(25));
  CheckEquals('AA', PPGXlsxColName(26));
  CheckEquals('ZZ', PPGXlsxColName(701));
  CheckEquals('AAA', PPGXlsxColName(702));
  CheckTrue(PPGIsDateFormat('dd.mm.yyyy'));
  CheckTrue(PPGIsDateFormat('hh:mm'));
  CheckFalse(PPGIsDateFormat('#,##0.00'));
  CheckFalse(PPGIsDateFormat(''));
end;

procedure TExportTests.XmlEscaping;
begin
  CheckEquals('a&amp;b&lt;c&gt;&quot;', PPGXmlEscape('a&b<c>"'));
  CheckEquals('ab'#9'c', PPGXmlEscape('a'#1'b'#9'c'#11), 'Steuerzeichen entfernt');
end;

procedure TExportTests.RoundTripSimpleSource;
var
  S: TPPGStringTableSource;
  T: IPPGTableSource;
  F: string;
  Rd: TPPGXlsxReader;
begin
  S := TPPGStringTableSource.Create(['Text', 'Zahl']);
  T := S;
  S.AddRow(['A & <B>', '1,5']);
  S.AddRow([' mit Leerzeichen ', '-2']);
  S.AddRow(['', '']);
  S.AddRow(['Ende', 'kein Wert']);
  F := TempFile('.xlsx');
  PPGExportXlsx(T, F, 'Daten');
  Rd := TPPGXlsxReader.Create;
  try
    Rd.LoadFromFile(F);
    CheckEquals(5, Rd.RowCount, 'Kopf + 4 Zeilen');
    CheckEquals(2, Rd.ColCount);
    CheckEquals('Text', Rd.Cells[0, 0]);
    CheckEquals('A & <B>', Rd.Cells[0, 1]);
    CheckEquals(' mit Leerzeichen ', Rd.Cells[0, 2]);
    CheckEquals(1.5, Double(Rd.Values[1, 1]), 0.0001, 'Zahl als Zahl');
    CheckEquals(-2, Double(Rd.Values[1, 2]), 0);
    CheckTrue(VarIsNull(Rd.Values[0, 3]), 'leer');
    CheckEquals('kein Wert', Rd.Cells[1, 4]);
  finally
    Rd.Free;
  end;
  CheckTrue(Pos('name="Daten"', ZipPart(F, 'xl/workbook.xml')) > 0);
end;

procedure TExportTests.PackageHasRequiredParts;
var
  F, Sheet: string;
  Z: TZipFile;
  S: TPPGStringTableSource;
  T: IPPGTableSource;
begin
  S := TPPGStringTableSource.Create(['A']);
  T := S;
  S.AddRow(['x']);
  F := TempFile('.xlsx');
  PPGExportXlsx(T, F);
  Z := TZipFile.Create;
  try
    Z.Open(F, zmRead);
    CheckTrue(Z.IndexOf('[Content_Types].xml') >= 0);
    CheckTrue(Z.IndexOf('_rels/.rels') >= 0);
    CheckTrue(Z.IndexOf('xl/workbook.xml') >= 0);
    CheckTrue(Z.IndexOf('xl/_rels/workbook.xml.rels') >= 0);
    CheckTrue(Z.IndexOf('xl/styles.xml') >= 0);
    CheckTrue(Z.IndexOf('xl/sharedStrings.xml') >= 0);
    CheckTrue(Z.IndexOf('xl/worksheets/sheet1.xml') >= 0);
  finally
    Z.Free;
  end;
  Sheet := ZipPart(F, 'xl/worksheets/sheet1.xml');
  CheckTrue(Pos('state="frozen"', Sheet) > 0, 'Kopf fixiert');
  CheckTrue(Pos('<autoFilter ref="A1:A2"/>', Sheet) > 0, 'Autofilter');
  // Reihenfolge laut Schema: sheetData vor autoFilter
  CheckTrue(Pos('</sheetData>', Sheet) < Pos('<autoFilter', Sheet));
  CheckTrue(Pos('_xlnm._FilterDatabase', ZipPart(F, 'xl/workbook.xml')) > 0);
end;

procedure TExportTests.GridValuesFormatsAndViewOrder;
var
  G: TPPGGrid;
  F, Styles: string;
  Rd: TPPGXlsxReader;
begin
  G := SampleGrid;
  G.SortBy(2, False); // Preis absteigend
  G.Columns[1].Visible := False;
  F := TempFile('.xlsx');
  PPGExportXlsx(Src(G), F);
  Rd := TPPGXlsxReader.Create;
  try
    Rd.LoadFromFile(F);
    CheckEquals(3, Rd.ColCount, 'ausgeblendete Spalte fehlt');
    CheckEquals('Preis', Rd.Cells[1, 0]);
    CheckEquals('Artikel 6', Rd.Cells[0, 1], 'sortiert wie im Grid');
    CheckEquals(9, Double(Rd.Values[1, 1]), 0.001);
    CheckEquals(PPGExcelSerial(EncodeDate(2026, 1, 6)), Double(Rd.Values[2, 1]), 0,
      'Datum als Excel-Zahl');
  finally
    Rd.Free;
  end;
  Styles := ZipPart(F, 'xl/styles.xml');
  CheckTrue(Pos('formatCode="#,##0.00"', Styles) > 0);
  CheckTrue(Pos('formatCode="dd.mm.yyyy"', Styles) > 0);
end;

procedure TExportTests.GroupsBecomeOutline;
var
  G: TPPGGrid;
  F, Sheet: string;
  Rd: TPPGXlsxReader;
begin
  G := SampleGrid;
  G.GroupBy([1]);
  F := TempFile('.xlsx');
  PPGExportXlsx(Src(G), F);
  Sheet := ZipPart(F, 'xl/worksheets/sheet1.xml');
  CheckTrue(Pos('outlineLevel="1"', Sheet) > 0, 'Gliederung');
  CheckTrue(Pos('outlineLevelRow="1"', Sheet) > 0);
  CheckTrue(Pos('summaryBelow="0"', Sheet) > 0, 'Gruppenkopf oben');
  Rd := TPPGXlsxReader.Create;
  try
    Rd.LoadFromFile(F);
    CheckEquals(1 + 3 + 6, Rd.RowCount, 'Kopf, 3 Gruppen, 6 Zeilen (Summe nur als Formel)');
    CheckEquals('Kategorie: Brot (2)', Rd.Cells[0, 1], 'Gruppenkopf');
    CheckEquals('Artikel 2', Rd.Cells[0, 2]);
  finally
    Rd.Free;
  end;
end;

procedure TExportTests.MergesAndFooter;
var
  G: TPPGGrid;
  F, Sheet: string;
begin
  G := SampleGrid;
  G.MergeCells(0, 1, 2, 1);
  F := TempFile('.xlsx');
  PPGExportXlsx(Src(G), F);
  Sheet := ZipPart(F, 'xl/worksheets/sheet1.xml');
  CheckTrue(Pos('<mergeCell ref="A2:B2"/>', Sheet) > 0, 'verbundene Zellen');
  CheckTrue(Pos('<f>SUBTOTAL(109,C2:C7)</f>', Sheet) > 0, 'Summe als Formel');
  CheckTrue(Pos('<autoFilter ref="A1:D7"/>', Sheet) > 0, 'Filter ohne Summenzeile');
end;

procedure TExportTests.ReaderRichAndInlineStrings;
var
  F: string;
  Z: TZipFile;
  Rd: TPPGXlsxReader;

  procedure AddText(const Name, Text: string);
  begin
    Z.Add(TEncoding.UTF8.GetBytes(Text), Name);
  end;

begin
  F := TempFile('.xlsx');
  Z := TZipFile.Create;
  try
    Z.Open(F, zmWrite);
    AddText('xl/workbook.xml', '<workbook xmlns:r="x"><sheets><sheet name="S" sheetId="1" r:id="rId7"/></sheets></workbook>');
    AddText('xl/_rels/workbook.xml.rels', '<Relationships><Relationship Id="rId7" Target="worksheets/blatt.xml"/></Relationships>');
    AddText('xl/sharedStrings.xml', '<sst><si><t>eins</t></si><si><r><rPr><b/></rPr><t>zw</t></r><r><t>ei</t></r></si>' +
      '<si><t>a&amp;b&#x263A;</t><rPh><t>x</t></rPh></si></sst>');
    AddText('xl/worksheets/blatt.xml', '<worksheet><sheetData>' +
      '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c><c r="D1" t="s"><v>2</v></c></row>' +
      '<row r="3"><c r="A3" t="inlineStr"><is><t>inline</t></is></c><c r="B3" t="b"><v>1</v></c>' +
      '<c r="C3"><f>1+1</f><v>2</v></c><c r="AA3"><v>3.25</v></c></row></sheetData></worksheet>');
    Z.Close;
  finally
    Z.Free;
  end;
  Rd := TPPGXlsxReader.Create;
  try
    Rd.LoadFromFile(F);
    CheckEquals('eins', Rd.Cells[0, 0]);
    CheckEquals('zwei', Rd.Cells[1, 0], 'Formatierungslaeufe');
    CheckEquals('a&b'#$263A, Rd.Cells[3, 0], 'Entitaeten, ohne Phonetik');
    CheckEquals('', Rd.Cells[0, 1], 'Zeile 2 fehlt in der Datei');
    CheckEquals('inline', Rd.Cells[0, 2]);
    CheckEquals('1', Rd.Cells[1, 2], 'Wahrheitswert');
    CheckEquals(2, Double(Rd.Values[2, 2]), 0, 'Formel: nur der Wert');
    CheckEquals(3.25, Double(Rd.Values[26, 2]), 0, 'Spalte AA');
    CheckEquals(27, Rd.ColCount);
    CheckEquals(3, Rd.RowCount);
  finally
    Rd.Free;
  end;
end;

procedure TExportTests.LoadIntoGrid;
var
  G, G2: TPPGGrid;
  F: string;
begin
  G := SampleGrid;
  F := TempFile('.xlsx');
  PPGExportXlsx(Src(G), F);
  G2 := TPPGGrid.Create(FForm);
  G2.Parent := FForm;
  G2.SortBy(1);
  PPGLoadXlsx(G2, F);
  CheckEquals(4, G2.ColCount);
  CheckEquals(7, G2.RowCount, 'Kopf + 6 (Summenzeile hat nur eine Formel, keinen Wert)');
  CheckEquals('Preis', G2.Cells[2, 0]);
  CheckEquals('Artikel 3', G2.Cells[0, 3]);
  CheckEquals('4,5', G2.Cells[2, 3], 'Zahl im aktuellen Format');
  CheckEquals(-1, G2.SortColumn, 'Ansicht zurueckgesetzt');
  PPGLoadXlsx(G2, F, False);
  CheckEquals('A', G2.Cells[0, 0], 'ohne Kopfzeile: Spaltennamen');
  CheckEquals('Name', G2.Cells[0, 1]);
end;

procedure TExportTests.HtmlExport;
var
  G: TPPGGrid;
  H: string;
  Fm: TPPGGridConditionalFormat;
begin
  G := SampleGrid;
  G.Cells[0, 1] := 'A <b> & "c"';
  Fm := G.ConditionalFormats.Add;
  Fm.Column := 1;
  Fm.Rule := crEqual;
  Fm.Value1 := 'Milch';
  Fm.Color := ccCustom;
  Fm.CustomColor := clRed;
  Fm.Target := ctText;
  Fm.Bold := True;
  H := PPGExportHtmlText(Src(G), 'Liste <1>');
  CheckTrue(Pos('<title>Liste &lt;1&gt;</title>', H) > 0);
  CheckTrue(Pos('<th style="text-align:left">Preis</th>', H) > 0);
  CheckTrue(Pos('A &lt;b&gt; &amp; &quot;c&quot;', H) > 0, 'maskiert');
  CheckTrue(Pos('color:#ff0000;font-weight:bold">milch', LowerCase(H)) > 0, 'bedingtes Format');
  CheckEquals(6 * Length('<tr><td'), Length(H) - Length(StringReplace(H, '<tr><td', '', [rfReplaceAll])),
    'sechs Datenzeilen');
end;

procedure TExportTests.CsvExport;
var
  S: TPPGStringTableSource;
  T: IPPGTableSource;
  C: string;
begin
  S := TPPGStringTableSource.Create(['A', 'B']);
  T := S;
  S.AddRow(['x;y', 'sagt "hallo"']);
  S.AddRow(['1'#13#10'2', '']);
  C := PPGExportCsvText(T);
  CheckEquals('A;B'#13#10'"x;y";"sagt ""hallo"""'#13#10'"1'#13#10'2";'#13#10, C);
  CheckEquals('A'#9'B', Copy(PPGExportCsvText(T, #9), 1, 3));
end;

procedure TExportTests.PdfExport;
var
  P: TPPGGridPrinter;
  S: TPPGStringTableSource;
  F: string;
  I: Integer;
  B: TBytes;
begin
  S := TPPGStringTableSource.Create(['A', 'B']);
  for I := 1 to 80 do
    S.AddRow([IntToStr(I), 'Zeile ' + IntToStr(I)]);
  P := TPPGGridPrinter.Create(nil);
  try
    P.SetSource(S);
    F := TempFile('.pdf');
    if PPGFindPdfPrinter = '' then
    begin
      try
        PPGExportPdf(P, F);
        Fail('ohne PDF-Drucker: Fehler erwartet');
      except
        on E: EPPGError do
          CheckTrue(Pos('PDF', E.Message) > 0);
      end;
      Exit;
    end;
    PPGExportPdf(P, F);
    // Der Spooler schreibt die Datei nach EndDoc
    for I := 1 to 100 do
    begin
      if FileExists(F) and (TFile.GetSize(F) > 100) then
        Break;
      Sleep(100);
    end;
    CheckTrue(FileExists(F), 'PDF geschrieben');
    B := TFile.ReadAllBytes(F);
    CheckEquals('%PDF', TEncoding.ASCII.GetString(B, 0, 4));
  finally
    P.Free;
  end;
end;

procedure TExportTests.ManyRows;
var
  S: TPPGStringTableSource;
  T: IPPGTableSource;
  F: string;
  I: Integer;
  T0: Cardinal;
  Rd: TPPGXlsxReader;
begin
  S := TPPGStringTableSource.Create(['Nr', 'Text', 'Wert']);
  T := S;
  for I := 1 to 20000 do
    S.AddRow([IntToStr(I), 'Text ' + IntToStr(I mod 100), FloatToStr(I / 4)]);
  F := TempFile('.xlsx');
  T0 := GetTickCount;
  PPGExportXlsx(T, F);
  CheckTrue(GetTickCount - T0 < 10000);
  Rd := TPPGXlsxReader.Create;
  try
    Rd.LoadFromFile(F);
    CheckEquals(20001, Rd.RowCount);
    CheckEquals('Text 99', Rd.Cells[1, 99]);
    CheckEquals(5000, Double(Rd.Values[2, 20000]), 0);
  finally
    Rd.Free;
  end;
end;

initialization
  RegisterTest('Phase13f', TExportTests.Suite);

end.
