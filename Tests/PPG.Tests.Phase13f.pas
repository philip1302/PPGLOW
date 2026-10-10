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
    procedure LookHeaderFontAndLines;
    procedure LookConditionalFormats;
    procedure LookCellKinds;
    procedure LookBandsShiftRows;
    procedure LookZebraAndColumnStyle;
    procedure LookOffAndPlainSource;
    procedure LookStylesAreShared;
    procedure ThousandSeparatorsStayNumbers;
    procedure AuditTimesReaderAndCsvSafety;
  end;

implementation

uses
  System.StrUtils, Vcl.Grids, PPG.Exceptions;

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
  CheckTrue(Pos('<f>SUBTOTAL(9,C2:C7)</f>', Sheet) > 0, 'Summe als Formel');
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

procedure TExportTests.AuditTimesReaderAndCsvSafety;
var
  F: string;
  Z: TZipFile;
  Rd: TPPGXlsxReader;
  S: TPPGStringTableSource;
  T: IPPGTableSource;
  B: TBytes;

  procedure AddText(const Name, Text: string);
  begin
    Z.Add(TEncoding.UTF8.GetBytes(Text), Name);
  end;

begin
  // Audit 08.10.2026: reine Uhrzeiten wurden negativ (Excel zeigte #####)
  CheckEquals(0.5, PPGExcelSerial(0.5), 0, '12:00 ohne Datum');
  CheckEquals(0.5, PPGFromExcelSerial(0.5), 0, 'zurueck');
  CheckEquals(1, PPGExcelSerial(EncodeDate(1900, 1, 1)), 0, 'Datum unveraendert');
  // Reader: r-Attribute sind optional; Inline-Text aus mehreren Laeufen
  F := TempFile('.xlsx');
  Z := TZipFile.Create;
  try
    Z.Open(F, zmWrite);
    AddText('xl/workbook.xml', '<workbook><sheets><sheet name="S" sheetId="1"/></sheets></workbook>');
    AddText('xl/sharedStrings.xml', '<sst></sst>');
    AddText('xl/worksheets/sheet1.xml', '<worksheet><sheetData>' +
      '<row><c t="inlineStr"><is><r><t>in</t></r><r><t>line</t></r></is></c><c><v>7</v></c></row>' +
      '<row><c><v>8</v></c></row></sheetData></worksheet>');
    Z.Close;
  finally
    Z.Free;
  end;
  Rd := TPPGXlsxReader.Create;
  try
    Rd.LoadFromFile(F);
    CheckEquals('inline', Rd.Cells[0, 0], 'alle Laeufe');
    CheckEquals(7, Double(Rd.Values[1, 0]), 0, 'Spalte ohne r');
    CheckEquals(8, Double(Rd.Values[0, 1]), 0, 'Zeile ohne r');
    CheckEquals(2, Rd.RowCount);
  finally
    Rd.Free;
  end;
  // CSV: Formel-Einschleusung abwehren, Zahlen bleiben Zahlen
  S := TPPGStringTableSource.Create(['A', 'B']);
  T := S;
  S.AddRow(['=1+1', '-5']);
  S.AddRow(['@x', '+49 30']);
  CheckEquals('A;B'#13#10'''=1+1;-5'#13#10'''@x;''+49 30'#13#10, PPGExportCsvText(T));
  // CSV-Datei mit BOM, damit Excel UTF-8 erkennt
  F := TempFile('.csv');
  PPGExportCsv(T, F);
  B := TFile.ReadAllBytes(F);
  CheckTrue((Length(B) > 3) and (B[0] = $EF) and (B[1] = $BB) and (B[2] = $BF), 'BOM');
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
  Rd: TPPGXlsxReader;
begin
  // Audit 11a #7: Laufzeit im Benchmark (Bench11, vorher 10000 ms im Test)
  S := TPPGStringTableSource.Create(['Nr', 'Text', 'Wert']);
  T := S;
  for I := 1 to 20000 do
    S.AddRow([IntToStr(I), 'Text ' + IntToStr(I mod 100), FloatToStr(I / 4)]);
  F := TempFile('.xlsx');
  PPGExportXlsx(T, F);
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

{ ---- Optik wie im Grid (IPPGTableLook) ---- }

/// Zellformat-Index einer Zelle ('B2'); 0 = ohne s, -1 = Zelle fehlt.
function CellXf(const Sheet, Ref: string): Integer;
var
  P, Q: Integer;
  Tag: string;
begin
  P := Pos('<c r="' + Ref + '"', Sheet);
  if P = 0 then
    Exit(-1);
  Q := PosEx('>', Sheet, P);
  Tag := Copy(Sheet, P, Q - P);
  P := Pos(' s="', Tag);
  if P = 0 then
    Exit(0);
  Result := StrToInt(Copy(Tag, P + 4, PosEx('"', Tag, P + 4) - P - 4));
end;

/// Index-tes Element ItemTag innerhalb von ListTag (z.B. 'fills', 'fill').
function NthItem(const Xml, ListTag, ItemTag: string; Index: Integer): string;
var
  P, E, T, I: Integer;
begin
  Result := '';
  P := Pos('<' + ListTag, Xml);
  if P = 0 then
    Exit;
  E := PosEx('</' + ListTag + '>', Xml, P);
  I := -1;
  P := PosEx('<' + ItemTag, Xml, P + Length(ListTag) + 1);
  while (P > 0) and (P < E) do
  begin
    if CharInSet(Xml[P + Length(ItemTag) + 1], [' ', '>', '/']) then
    begin
      Inc(I);
      T := PosEx('>', Xml, P);
      if I = Index then
      begin
        if Xml[T - 1] = '/' then
          Result := Copy(Xml, P, T - P + 1)
        else
          Result := Copy(Xml, P, PosEx('</' + ItemTag + '>', Xml, P) + Length(ItemTag) + 3 - P);
        Exit;
      end;
    end;
    P := PosEx('<' + ItemTag, Xml, P + 1);
  end;
end;

function AttrOf(const Tag, Name: string): string;
var
  P: Integer;
begin
  Result := '';
  P := Pos(' ' + Name + '="', Tag);
  if P > 0 then
  begin
    Inc(P, Length(Name) + 3);
    Result := Copy(Tag, P, PosEx('"', Tag, P) - P);
  end;
end;

/// Teil (font/fill/border) des Zellformats einer Zelle.
function CellPart(const Sheet, Styles, Ref, Part: string): string;
var
  Xf: string;
begin
  Xf := NthItem(Styles, 'cellXfs', 'xf', CellXf(Sheet, Ref));
  Result := NthItem(Styles, Part + 's', Part, StrToIntDef(AttrOf(Xf, Part + 'Id'), 0));
end;

function CellXfTag(const Sheet, Styles, Ref: string): string;
begin
  Result := NthItem(Styles, 'cellXfs', 'xf', CellXf(Sheet, Ref));
end;

procedure TExportTests.LookHeaderFontAndLines;
var
  G: TPPGGrid;
  F, Sheet, Styles: string;
begin
  G := SampleGrid;
  G.Font.Name := 'Segoe UI';
  G.Font.Size := 10;
  G.Styles.Header.Color := $00336699;      // RGB 99 66 33
  G.Styles.Header.TextColor := clWhite;
  G.Styles.GridLine.Color := $00102030;    // RGB 30 20 10
  G.Columns[2].Alignment := taRightJustify;
  F := TempFile('.xlsx');
  PPGExportXlsx(Src(G), F);
  Sheet := ZipPart(F, 'xl/worksheets/sheet1.xml');
  Styles := ZipPart(F, 'xl/styles.xml');
  CheckTrue(Pos('FF996633', CellPart(Sheet, Styles, 'A1', 'fill')) > 0, 'Kopf-Flaeche');
  CheckTrue(Pos('FFFFFFFF', CellPart(Sheet, Styles, 'A1', 'font')) > 0, 'Kopf-Text');
  CheckTrue(Pos('<b/>', CellPart(Sheet, Styles, 'A1', 'font')) = 0, 'Kopf nicht fett (wie im Grid)');
  CheckTrue(Pos('Segoe UI', NthItem(Styles, 'fonts', 'font', 0)) > 0, 'Schrift der Mappe');
  CheckTrue(Pos('<sz val="10"/>', NthItem(Styles, 'fonts', 'font', 0)) > 0, 'Groesse');
  CheckTrue(Pos('style="thin"><color rgb="FF302010"', CellPart(Sheet, Styles, 'B3', 'border')) > 0,
    'Gitterlinien als Rahmen');
  CheckTrue(Pos('horizontal="right"', CellXfTag(Sheet, Styles, 'C3')) > 0, 'Ausrichtung');
  CheckTrue(Pos('vertical="center"', CellXfTag(Sheet, Styles, 'C3')) > 0);
  CheckTrue(Pos('customHeight="1"', Sheet) > 0, 'Zeilenhoehe wie im Grid');
  CheckEquals(0, StrToIntDef(AttrOf(CellXfTag(Sheet, Styles, 'B3'), 'fillId'), -1),
    'weisse Flaeche = keine Fuellung');
  // Ohne Gitterlinien im Grid auch keine Rahmen
  G.Options := G.Options - [goVertLine, goHorzLine];
  PPGExportXlsx(Src(G), F);
  Sheet := ZipPart(F, 'xl/worksheets/sheet1.xml');
  Styles := ZipPart(F, 'xl/styles.xml');
  CheckEquals('0', AttrOf(CellXfTag(Sheet, Styles, 'B3'), 'borderId'));
end;

procedure TExportTests.LookConditionalFormats;
var
  G: TPPGGrid;
  CF: TPPGGridConditionalFormat;
  F, Sheet, Styles: string;
begin
  G := SampleGrid; // Preise 1,5 3 4,5 6 7,5 9 in Spalte C
  CF := G.ConditionalFormats.Add;
  CF.Column := 2;
  CF.Rule := crRange;
  CF.Value2 := '3';
  CF.Color := ccDanger;
  CF := G.ConditionalFormats.Add;
  CF.Column := 0;
  CF.Rule := crContains;
  CF.Value1 := 'Artikel 6';
  CF.Color := ccSuccess;
  CF.Target := ctText;
  CF.Bold := True;
  CF := G.ConditionalFormats.Add;
  CF.Column := 2;
  CF.Rule := crDataBar;
  CF := G.ConditionalFormats.Add;
  CF.Column := 1;
  CF.Rule := crIconSet;
  F := TempFile('.xlsx');
  PPGExportXlsx(Src(G), F);
  Sheet := ZipPart(F, 'xl/worksheets/sheet1.xml');
  Styles := ZipPart(F, 'xl/styles.xml');
  CheckTrue(Pos('patternType="solid"', CellPart(Sheet, Styles, 'C2', 'fill')) > 0, '1,5 <= 3 rot');
  CheckTrue(Pos('patternType="solid"', CellPart(Sheet, Styles, 'C3', 'fill')) > 0, '3 <= 3 rot');
  CheckTrue(Pos('patternType="solid"', CellPart(Sheet, Styles, 'C4', 'fill')) = 0, '4,5 nicht');
  CheckTrue(Pos('<b/>', CellPart(Sheet, Styles, 'A7', 'font')) > 0, 'Artikel 6 fett');
  CheckTrue(Pos('<color rgb=', CellPart(Sheet, Styles, 'A7', 'font')) > 0, 'Artikel 6 farbig');
  CheckTrue(Pos('<b/>', CellPart(Sheet, Styles, 'A6', 'font')) = 0, 'Artikel 5 nicht');
  CheckTrue(Pos('<conditionalFormatting sqref="C2:C7"><cfRule type="dataBar"', Sheet) > 0,
    'Datenbalken als Excel-Regel');
  CheckTrue(Pos('<conditionalFormatting sqref="B2:B7"><cfRule type="iconSet"', Sheet) > 0,
    'Symbolsatz als Excel-Regel');
  // Reihenfolge laut Schema: mergeCells/autoFilter vor conditionalFormatting
  CheckTrue(Pos('<autoFilter', Sheet) < Pos('<conditionalFormatting', Sheet));
end;

procedure TExportTests.LookCellKinds;
var
  G: TPPGGrid;
  F, Sheet, Styles, Fmt: string;
  Rd: TPPGXlsxReader;
begin
  G := TPPGGrid.Create(FForm);
  G.Parent := FForm;
  G.FixedCols := 0;
  G.Columns.Add.Title := 'Aktiv';
  G.Columns[0].EditorKind := gekCheck;
  G.Columns.Add.Title := 'Bewertung';
  G.Columns[1].CellKind := ckRating;
  G.Columns.Add.Title := 'Lager';
  G.Columns[2].CellKind := ckProgress;
  G.Columns[2].MaxValue := 400;
  G.Columns.Add.Title := 'Farbe';
  G.Columns[3].CellKind := ckColor;
  G.Columns.Add.Title := 'Link';
  G.Columns[4].CellKind := ckLink;
  G.RowCount := 3;
  G.Cells[0, 1] := '1';
  G.Cells[1, 1] := '3';
  G.Cells[2, 1] := '200';
  G.Cells[3, 1] := '#FF0000';
  G.Cells[4, 1] := 'https://example.com';
  G.Cells[0, 2] := '0';
  G.Cells[1, 2] := '5';
  G.Cells[2, 2] := '400';
  F := TempFile('.xlsx');
  PPGExportXlsx(Src(G), F);
  Sheet := ZipPart(F, 'xl/worksheets/sheet1.xml');
  Styles := ZipPart(F, 'xl/styles.xml');
  Rd := TPPGXlsxReader.Create;
  try
    Rd.LoadFromFile(F);
    CheckEquals(1, Double(Rd.Values[0, 1]), 0, 'Kaestchen als Zahl 1');
    CheckEquals(0, Double(Rd.Values[0, 2]), 0, 'Kaestchen als Zahl 0');
    CheckEquals(200, Double(Rd.Values[2, 1]), 0, 'Fortschritt bleibt Zahl');
    CheckEquals(#$2605#$2605#$2605#$2606#$2606, Rd.Cells[1, 1], '3 von 5 Sternen');
    CheckEquals(#$2605#$2605#$2605#$2605#$2605, Rd.Cells[1, 2]);
  finally
    Rd.Free;
  end;
  Fmt := NthItem(Styles, 'numFmts', 'numFmt', 0);
  CheckTrue(Pos(#$2611, Fmt) > 0, 'Zahlenformat mit Kaestchen');
  CheckTrue(Pos('horizontal="center"', CellXfTag(Sheet, Styles, 'A2')) > 0, 'Kaestchen mittig');
  CheckTrue(Pos('Segoe UI Symbol', CellPart(Sheet, Styles, 'B2', 'font')) > 0, 'Sterne als Symbolschrift');
  CheckTrue(Pos('<cfvo type="num" val="0"/><cfvo type="num" val="400"/>', Sheet) > 0,
    'Fortschritt als Datenbalken 0..MaxValue');
  CheckTrue(Pos('FFFF0000', CellPart(Sheet, Styles, 'D2', 'fill')) > 0, 'Farbzelle gefuellt');
  CheckTrue(Pos('<u/>', CellPart(Sheet, Styles, 'E2', 'font')) > 0, 'Link unterstrichen');
end;

procedure TExportTests.LookBandsShiftRows;
var
  G: TPPGGrid;
  F, Sheet: string;
  Rd: TPPGXlsxReader;
begin
  G := SampleGrid;
  G.Bands.Add.Caption := 'Ware';
  G.Bands.Add.Caption := 'Werte';
  G.Columns[0].Band := 0;
  G.Columns[1].Band := 0;
  G.Columns[2].Band := 1;
  G.Columns[3].Band := 1;
  F := TempFile('.xlsx');
  PPGExportXlsx(Src(G), F);
  Sheet := ZipPart(F, 'xl/worksheets/sheet1.xml');
  Rd := TPPGXlsxReader.Create;
  try
    Rd.LoadFromFile(F);
    CheckEquals('Ware', Rd.Cells[0, 0], 'Bandzeile');
    CheckEquals('Werte', Rd.Cells[2, 0]);
    CheckEquals('Name', Rd.Cells[0, 1], 'Spaltenkoepfe darunter');
    CheckEquals('Artikel 1', Rd.Cells[0, 2], 'Daten ab Zeile 3');
  finally
    Rd.Free;
  end;
  CheckTrue(Pos('<mergeCell ref="A1:B1"/>', Sheet) > 0, 'Band verbunden');
  CheckTrue(Pos('<mergeCell ref="C1:D1"/>', Sheet) > 0);
  CheckTrue(Pos('ySplit="2" topLeftCell="A3"', Sheet) > 0, 'beide Kopfzeilen fixiert');
  CheckTrue(Pos('<autoFilter ref="A2:D8"/>', Sheet) > 0, 'Filter auf den Spaltenkoepfen');
  CheckTrue(Pos('<f>SUBTOTAL(9,C3:C8)</f>', Sheet) > 0, 'Summe ab der ersten Datenzeile');
end;

procedure TExportTests.LookZebraAndColumnStyle;
var
  G: TPPGGrid;
  F, Sheet, Styles: string;
begin
  G := SampleGrid;
  G.Styles.AlternateRow.Color := $00EEDDCC;  // RGB CC DD EE
  G.Columns[1].Style.Color := $00112233;     // RGB 33 22 11
  G.Columns[1].Style.FontStyle := [fsItalic];
  G.Columns[0].TitleStyle.Color := $00445566; // RGB 66 55 44
  F := TempFile('.xlsx');
  PPGExportXlsx(Src(G), F);
  Sheet := ZipPart(F, 'xl/worksheets/sheet1.xml');
  Styles := ZipPart(F, 'xl/styles.xml');
  CheckTrue(Pos('FFCCDDEE', CellPart(Sheet, Styles, 'A2', 'fill')) = 0, 'erste Zeile ohne Zebra');
  CheckTrue(Pos('FFCCDDEE', CellPart(Sheet, Styles, 'A3', 'fill')) > 0, 'zweite Zeile Zebra');
  CheckTrue(Pos('FF332211', CellPart(Sheet, Styles, 'B3', 'fill')) > 0, 'Spaltenstil vor Zebra');
  CheckTrue(Pos('<i/>', CellPart(Sheet, Styles, 'B2', 'font')) > 0, 'Spaltenschrift kursiv');
  CheckTrue(Pos('FF665544', CellPart(Sheet, Styles, 'A1', 'fill')) > 0, 'TitleStyle im Kopf');
  CheckTrue(Pos('FF665544', CellPart(Sheet, Styles, 'B1', 'fill')) = 0);
end;

procedure TExportTests.LookOffAndPlainSource;
var
  G: TPPGGrid;
  W: TPPGXlsxWriter;
  S: TPPGStringTableSource;
  T: IPPGTableSource;
  F, Sheet, Styles: string;
begin
  G := SampleGrid;
  G.Styles.Header.Color := $00336699;
  F := TempFile('.xlsx');
  W := TPPGXlsxWriter.Create;
  try
    W.Styled := False;
    W.SaveToFile(Src(G), F);
  finally
    W.Free;
  end;
  Styles := ZipPart(F, 'xl/styles.xml');
  CheckTrue(Pos('FF996633', Styles) = 0, 'ohne Optik keine Grid-Farben');
  CheckTrue(Pos('Calibri', NthItem(Styles, 'fonts', 'font', 0)) > 0, 'Excel-Standardschrift');
  // Einfache Quelle: grauer, fetter Kopf, Zahlen richtet Excel aus
  S := TPPGStringTableSource.Create(['Text', 'Zahl']);
  T := S;
  S.AddRow(['a', '1']);
  PPGExportXlsx(T, F);
  Sheet := ZipPart(F, 'xl/worksheets/sheet1.xml');
  Styles := ZipPart(F, 'xl/styles.xml');
  CheckTrue(Pos('<b/>', CellPart(Sheet, Styles, 'A1', 'font')) > 0, 'Kopf fett');
  CheckTrue(Pos('FFF0F0F0', CellPart(Sheet, Styles, 'A1', 'fill')) > 0, 'Kopf grau');
  CheckTrue(Pos('horizontal=', CellXfTag(Sheet, Styles, 'B2')) = 0, 'Zahl ohne feste Ausrichtung');
end;

procedure TExportTests.LookStylesAreShared;
var
  G: TPPGGrid;
  CF: TPPGGridConditionalFormat;
  F, Styles: string;
  R: Integer;
begin
  G := SampleGrid;
  G.RowCount := 2001;
  for R := 1 to 2000 do
  begin
    G.Cells[0, R] := 'A' + IntToStr(R);
    G.Cells[2, R] := IntToStr(R mod 7);
  end;
  CF := G.ConditionalFormats.Add;
  CF.Column := 2;
  CF.Rule := crRange;
  CF.Value1 := '3';
  F := TempFile('.xlsx');
  PPGExportXlsx(Src(G), F);
  Styles := ZipPart(F, 'xl/styles.xml');
  CheckTrue(StrToInt(AttrOf(Copy(Styles, Pos('<cellXfs', Styles), 40), 'count')) < 30,
    'gleiche Formate nur einmal');
end;

procedure TExportTests.ThousandSeparatorsStayNumbers;
var
  G: TPPGGrid;
  F: string;
  Rd: TPPGXlsxReader;
begin
  // Regression: "30.082,00" (Wert-Spalte der Demo) landete als Text in Excel
  CheckEquals(1234, Double(PPGTableValueOf('1.234')), 0);
  CheckEquals(-1234567.5, Double(PPGTableValueOf('-1.234.567,5')), 0.0001);
  CheckEquals(30082, Double(PPGTableValueOf('30.082,00')), 0);
  CheckEquals('12.34', VarToStr(PPGTableValueOf('12.34')), 'Gruppe ohne 3 Ziffern bleibt Text');
  CheckEquals('1234.567', VarToStr(PPGTableValueOf('1234.567')));
  CheckEquals('1.234,', VarToStr(PPGTableValueOf('1.234,')));
  CheckEquals('1.2.3', VarToStr(PPGTableValueOf('1.2.3')));
  CheckEquals('M 1.234', VarToStr(PPGTableValueOf('M 1.234')));
  CheckEquals(varUString, VarType(PPGTableValueOf('Schraube M4')));
  G := SampleGrid;
  G.Cells[2, 1] := '30.082,00';
  F := TempFile('.xlsx');
  PPGExportXlsx(Src(G), F);
  Rd := TPPGXlsxReader.Create;
  try
    Rd.LoadFromFile(F);
    CheckTrue(VarIsNumeric(Rd.Values[2, 1]), 'als Zahl');
    CheckEquals(30082, Double(Rd.Values[2, 1]), 0);
  finally
    Rd.Free;
  end;
end;

initialization
  RegisterTest('Phase13f', TExportTests.Suite);

end.
