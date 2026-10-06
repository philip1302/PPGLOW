unit PPG.Grid.Export;

{ Export und Import fuer Tabellen (Phase 13f).

  - Alle Formate lesen dieselbe Quelle (IPPGTableSource): Grid, DB-Grid
    oder eigene Quellen. Ausgegeben wird, was der Anwender sieht: angezeigte
    Spalten in Anzeige-Reihenfolge, gefilterte und sortierte Zeilen.
  - xlsx: PPG.Xlsx. HTML: Tabelle mit Inline-Stilen (bedingte Formate ueber
    IPPGGridPrintSource). CSV/TSV nach RFC 4180.
  - PDF: ueber den Drucker "Microsoft Print to PDF" (ab Windows 10) mit
    DOCINFO.lpszOutput = Zieldatei, also ohne Dialog - derselbe Weg wie beim
    Drucken. Gefunden wird der Drucker ueber Treiber- bzw. Portnamen (der
    Anzeigename ist lokalisiert). Fehlt er, gibt es eine klare Meldung.
  - Import: erste Tabelle einer xlsx-Datei in ein Grid. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.SysUtils, PPG.Grid.Data, PPG.Grid, PPG.Grid.Print, PPG.Xlsx;

procedure PPGExportXlsx(const Source: IPPGTableSource; const FileName: string;
  const SheetName: string = '');
/// HTML-Dokument (Title = Ueberschrift und Fenstertitel; '' = ohne).
function PPGExportHtmlText(const Source: IPPGTableSource; const Title: string = ''): string;
procedure PPGExportHtml(const Source: IPPGTableSource; const FileName: string;
  const Title: string = '');
function PPGExportCsvText(const Source: IPPGTableSource; Separator: Char = ';'): string;
procedure PPGExportCsv(const Source: IPPGTableSource; const FileName: string;
  Separator: Char = ';');
/// Name des PDF-Druckers ('' = keiner installiert).
function PPGFindPdfPrinter: string;
/// PDF ueber "Microsoft Print to PDF"; Fehler, wenn der Drucker fehlt.
procedure PPGExportPdf(Printer: TPPGGridPrinter; const FileName: string);
/// Erste Tabelle einer xlsx-Datei ins Grid; HeaderRow = erste Zeile wird zur
/// Kopfzeile (Spaltentitel).
procedure PPGLoadXlsx(Grid: TPPGCustomGrid; const FileName: string; HeaderRow: Boolean = True);

implementation

uses
  Winapi.Windows, Winapi.WinSpool, System.Variants, System.Math, Vcl.Graphics,
  PPG.Grid.Styles, PPG.Grid.Columns, PPG.Exceptions, PPG.Lang, PPG.Consts;

type
  TGridAccess = class(TPPGCustomGrid);

procedure PPGExportXlsx(const Source: IPPGTableSource; const FileName: string;
  const SheetName: string);
var
  W: TPPGXlsxWriter;
begin
  W := TPPGXlsxWriter.Create;
  try
    W.SheetName := SheetName;
    W.SaveToFile(Source, FileName);
  finally
    W.Free;
  end;
end;

function HtmlEscape(const S: string): string;
begin
  Result := StringReplace(S, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
end;

function CssColor(C: TColor): string;
var
  RGB: Integer;
begin
  RGB := ColorToRGB(C);
  Result := Format('#%.2x%.2x%.2x', [RGB and $FF, (RGB shr 8) and $FF, (RGB shr 16) and $FF]);
end;

function PPGExportHtmlText(const Source: IPPGTableSource; const Title: string): string;
const
  AlignCss: array[TAlignment] of string = ('left', 'right', 'center');
var
  SB: TStringBuilder;
  PS: IPPGGridPrintSource;
  C, R: Integer;
  Info: array of TPPGTableColumnInfo;
  S, Style: string;
  St: TPPGGridCellStyle;
begin
  Supports(Source, IPPGGridPrintSource, PS);
  SB := TStringBuilder.Create;
  try
    SB.Append('<!DOCTYPE html>'#13#10'<html><head><meta charset="utf-8">');
    if Title <> '' then
      SB.Append('<title>' + HtmlEscape(Title) + '</title>');
    SB.Append('<style>table{border-collapse:collapse;font-family:Segoe UI,sans-serif;font-size:10pt}' +
      'th,td{border:1px solid #c8c8c8;padding:3px 6px}th{background:#f0f0f0}</style>');
    SB.Append('</head><body>'#13#10);
    if Title <> '' then
      SB.Append('<h1>' + HtmlEscape(Title) + '</h1>'#13#10);
    SB.Append('<table>'#13#10'<thead><tr>');
    SetLength(Info, Source.TableColCount);
    for C := 0 to High(Info) do
    begin
      Info[C] := Source.TableColumn(C);
      SB.Append('<th style="text-align:' + AlignCss[Info[C].Alignment] + '">' +
        HtmlEscape(Info[C].Title) + '</th>');
    end;
    SB.Append('</tr></thead>'#13#10'<tbody>'#13#10);
    for R := 0 to Source.TableRowCount - 1 do
    begin
      SB.Append('<tr>');
      for C := 0 to High(Info) do
      begin
        S := Source.TableCellText(C, R);
        Style := 'text-align:' + AlignCss[Info[C].Alignment];
        if PS <> nil then
        begin
          St := PS.PrintCellStyle(C, R, S);
          if St.Fill <> clNone then
            Style := Style + ';background:' + CssColor(St.Fill);
          if St.TextColor <> clNone then
            Style := Style + ';color:' + CssColor(St.TextColor);
          if St.Bold then
            Style := Style + ';font-weight:bold';
        end;
        SB.Append('<td style="' + Style + '">' + HtmlEscape(S) + '</td>');
      end;
      SB.Append('</tr>'#13#10);
    end;
    SB.Append('</tbody></table>'#13#10'</body></html>'#13#10);
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure SaveText(const S, FileName: string);
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Text := S;
    L.WriteBOM := False;
    L.SaveToFile(FileName, TEncoding.UTF8);
  finally
    L.Free;
  end;
end;

procedure PPGExportHtml(const Source: IPPGTableSource; const FileName: string;
  const Title: string);
begin
  SaveText(PPGExportHtmlText(Source, Title), FileName);
end;

function PPGExportCsvText(const Source: IPPGTableSource; Separator: Char): string;
var
  SB: TStringBuilder;
  C, R: Integer;

  procedure Field(const F: string);
  begin
    // RFC 4180: Felder mit Trenner, Anfuehrungszeichen oder Zeilenumbruch
    if (Pos(Separator, F) > 0) or (Pos('"', F) > 0) or (Pos(#13, F) > 0) or (Pos(#10, F) > 0) then
      SB.Append('"' + StringReplace(F, '"', '""', [rfReplaceAll]) + '"')
    else
      SB.Append(F);
  end;

begin
  SB := TStringBuilder.Create;
  try
    for C := 0 to Source.TableColCount - 1 do
    begin
      if C > 0 then
        SB.Append(Separator);
      Field(Source.TableColumn(C).Title);
    end;
    SB.Append(#13#10);
    for R := 0 to Source.TableRowCount - 1 do
    begin
      for C := 0 to Source.TableColCount - 1 do
      begin
        if C > 0 then
          SB.Append(Separator);
        Field(Source.TableCellText(C, R));
      end;
      SB.Append(#13#10);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure PPGExportCsv(const Source: IPPGTableSource; const FileName: string; Separator: Char);
begin
  SaveText(PPGExportCsvText(Source, Separator), FileName);
end;

function PPGFindPdfPrinter: string;
var
  Needed, Count: DWORD;
  Buf: TBytes;
  Info: PPrinterInfo2;
  I: Integer;
begin
  Result := '';
  Needed := 0;
  Count := 0;
  EnumPrinters(PRINTER_ENUM_LOCAL or PRINTER_ENUM_CONNECTIONS, nil, 2, nil, 0, Needed, Count);
  if Needed = 0 then
    Exit;
  SetLength(Buf, Needed);
  if not EnumPrinters(PRINTER_ENUM_LOCAL or PRINTER_ENUM_CONNECTIONS, nil, 2, @Buf[0], Needed,
    Needed, Count) then
    Exit;
  Info := PPrinterInfo2(@Buf[0]);
  for I := 0 to Integer(Count) - 1 do
  begin
    // Treiber "Microsoft Print To PDF" bzw. Port "PORTPROMPT:" - nicht der
    // (lokalisierte) Anzeigename
    if SameText(string(Info^.pDriverName), 'Microsoft Print To PDF') or
      (SameText(string(Info^.pPortName), 'PORTPROMPT:') and
      (Pos('PDF', UpperCase(string(Info^.pDriverName))) > 0)) then
      Exit(string(Info^.pPrinterName));
    Inc(Info);
  end;
end;

procedure PPGExportPdf(Printer: TPPGGridPrinter; const FileName: string);
var
  P: string;
begin
  P := PPGFindPdfPrinter;
  if P = '' then
    raise EPPGError.Create(PPGStr(@SPPGPdfPrinterMissing));
  Printer.PrintToFile(P, ExpandFileName(FileName));
end;

procedure PPGLoadXlsx(Grid: TPPGCustomGrid; const FileName: string; HeaderRow: Boolean);
var
  Rd: TPPGXlsxReader;
  C, R, First, Cols: Integer;
  G: TGridAccess;
begin
  G := TGridAccess(Grid);
  Rd := TPPGXlsxReader.Create;
  try
    Rd.LoadFromFile(FileName);
    Cols := Rd.ColCount;
    if Cols < 1 then
      Cols := 1;
    G.Ungroup;
    G.ClearFilters;
    G.SortBy(-1);
    G.ClearMerges;
    G.Columns.Clear;
    G.FixedCols := 0;
    G.ColCount := Cols;
    First := Ord(HeaderRow);
    G.FixedRows := 0;
    G.RowCount := Max(2, Rd.RowCount - First + 1);
    G.FixedRows := 1;
    // Kopfzeile: erste Zeile der Datei oder A, B, C ...
    for C := 0 to Cols - 1 do
      if HeaderRow then
        G.Cells[C, 0] := Rd.Cells[C, 0]
      else
        G.Cells[C, 0] := PPGXlsxColName(C);
    for R := First to Rd.RowCount - 1 do
      for C := 0 to Cols - 1 do
        G.Cells[C, R - First + 1] := Rd.Cells[C, R];
  finally
    Rd.Free;
  end;
end;

end.
