unit PPG.Grid.Export;

{ Export und Import fuer Tabellen (Phase 13f).

  - Alle Formate lesen dieselbe Quelle (IPPGTableSource): Grid, DB-Grid
    oder eigene Quellen. Ausgegeben wird, was der Anwender sieht: angezeigte
    Spalten in Anzeige-Reihenfolge, gefilterte und sortierte Zeilen.
  - xlsx: PPG.Xlsx. HTML: mit IPPGTableLook wie im Grid (Baender, Gruppen,
    Summen-tfoot, Spalten- und Zebra-Stile, bedingte Formate, Kaestchen und
    Sterne als Zeichen, Fortschritt und Datenbalken als CSS-Verlauf, Links nur
    http/https/mailto), sonst einfache Tabelle. CSV/TSV nach RFC 4180.
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
  PPG.Types, PPG.Tokens, PPG.Markup, PPG.Grid.CellKinds, PPG.Grid.Look,
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
  // Wie fuer xlsx: maskiert Sonderzeichen und entfernt ungueltige Steuerzeichen
  Result := PPGXmlEscape(S);
end;

function CssColor(C: TColor): string;
var
  RGB: Integer;
begin
  RGB := ColorToRGB(C);
  Result := Format('#%.2x%.2x%.2x', [RGB and $FF, (RGB shr 8) and $FF, (RGB shr 16) and $FF]);
end;

function CssFontStyle(Style: TFontStyles): string;
begin
  Result := '';
  if fsBold in Style then
    Result := Result + ';font-weight:bold';
  if fsItalic in Style then
    Result := Result + ';font-style:italic';
  if (fsUnderline in Style) and (fsStrikeOut in Style) then
    Result := Result + ';text-decoration:underline line-through'
  else if fsUnderline in Style then
    Result := Result + ';text-decoration:underline'
  else if fsStrikeOut in Style then
    Result := Result + ';text-decoration:line-through';
end;

/// Einfache Tabelle (Quellen ohne IPPGTableLook): wie vor Phase 17.
function PlainHtmlText(const Source: IPPGTableSource; const Title: string): string;
const
  AlignCss: array[TAlignment] of string = ('left', 'right', 'center');
var
  SB: TStringBuilder;
  PS: IPPGGridPrintSource;
  C, R: Integer;
  Info: array of TPPGTableColumnInfo;
  S, Style: string;
  St: TPPGGridCellStyle;
  Plain: TPPGTableLook;
begin
  Supports(Source, IPPGGridPrintSource, PS);
  Plain := PPGPlainTableLook;
  SB := TStringBuilder.Create;
  try
    SB.Append('<!DOCTYPE html>'#13#10'<html><head><meta charset="utf-8">');
    if Title <> '' then
      SB.Append('<title>' + HtmlEscape(Title) + '</title>');
    SB.Append('<style>table{border-collapse:collapse;font-family:Segoe UI,sans-serif;font-size:10pt}' +
      'th,td{border:1px solid ' + LowerCase(CssColor(Plain.Line)) +
      ';padding:3px 6px}th{background:' + LowerCase(CssColor(Plain.HeaderFill)) + '}</style>');
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
          if St.Bold or (fsBold in St.FontStyle) then
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

/// Link nur fuer sichere Schemata (kein javascript: aus Zelldaten).
function IsSafeLink(const S: string): Boolean;
var
  L: string;
begin
  L := LowerCase(Trim(S));
  Result := (Pos('http://', L) = 1) or (Pos('https://', L) = 1) or (Pos('mailto:', L) = 1);
end;

function PPGExportHtmlText(const Source: IPPGTableSource; const Title: string): string;
const
  AlignCss: array[TAlignment] of string = ('left', 'right', 'center');
var
  LookSrc: IPPGTableLook;
  Ex: IPPGTableExport;
  Look: TPPGTableLook;
  CL: array of TPPGTableColumnLook;
  Info: array of TPPGTableColumnInfo;
  Bands: TArray<TPPGTableBand>;
  Merges: TArray<TRect>;
  Lines: TPPGTableLines;
  SB: TStringBuilder;
  Cols, C, L, Li, R, B, First, M, Span, N: Integer;
  S, Style, Cell, Line, Css: string;
  Cs: TPPGGridCellStyle;
  Clr: TColor;
  F: Double;

  function MergeAt(ACol, ARow: Integer): Integer;
  var
    J: Integer;
  begin
    for J := 0 to High(Merges) do
      if (ACol >= Merges[J].Left) and (ACol <= Merges[J].Right) and (ARow >= Merges[J].Top) and
        (ARow <= Merges[J].Bottom) then
        Exit(J);
    Result := -1;
  end;

  /// Datenbalken als Verlauf: Anteil T in Farbe, Rest frei.
  function BarCss(T: Double; AColor, Back: TColor): string;
  var
    P: string;
  begin
    P := IntToStr(Round(T * 100)) + '%';
    if Back = clNone then
      Back := clWhite;
    Result := ';background:linear-gradient(to right,' + CssColor(AColor) + ' 0,' +
      CssColor(AColor) + ' ' + P + ',' + CssColor(Back) + ' ' + P + ')';
  end;

  function SymbolSpan(const T: string; AColor: TColor): string;
  begin
    Result := '';
    if T <> '' then
      Result := '<span class="sym" style="color:' + CssColor(AColor) + '">' + T + '</span>';
  end;

begin
  if not Supports(Source, IPPGTableLook, LookSrc) then
    Exit(PlainHtmlText(Source, Title));
  Look := LookSrc.ExportLook;
  if (Look.Fill <> clNone) and (ColorToRGB(Look.Fill) = $FFFFFF) then
    Look.Fill := clNone;
  Cols := Source.TableColCount;
  SetLength(CL, Cols);
  SetLength(Info, Cols);
  for C := 0 to Cols - 1 do
  begin
    Info[C] := Source.TableColumn(C);
    CL[C] := LookSrc.ExportColumnLook(C);
  end;
  Bands := LookSrc.ExportBands;
  Lines := TPPGTableLines.Create(Source, True, False);
  SB := TStringBuilder.Create;
  try
    SetLength(Merges, 0);
    if not Lines.Grouped and Supports(Source, IPPGTableExport, Ex) then
      Merges := Ex.ExportMerges;
    // Vorgaben als CSS, Abweichungen je Zelle inline
    Css := 'body{font-family:''' + Look.FontName + ''',Segoe UI,sans-serif}' +
      'table{border-collapse:collapse;font-size:' + IntToStr(Look.FontSize) + 'pt';
    if Look.Text <> clNone then
      Css := Css + ';color:' + CssColor(Look.Text);
    if Look.Fill <> clNone then
      Css := Css + ';background:' + CssColor(Look.Fill);
    Css := Css + '}th,td{padding:3px 6px;white-space:nowrap';
    if Look.RowHeight > 0 then
      Css := Css + ';height:' + IntToStr(Look.RowHeight - 7) + 'px';
    Css := Css + '}td{border:';
    if Look.Line <> clNone then
      Css := Css + '1px solid ' + CssColor(Look.Line)
    else
      Css := Css + 'none';
    Css := Css + '}th,tfoot td{border:';
    if Look.HeaderLine <> clNone then
      Css := Css + '1px solid ' + CssColor(Look.HeaderLine)
    else
      Css := Css + 'none';
    Css := Css + '}th{font-weight:normal';
    if Look.HeaderFill <> clNone then
      Css := Css + ';background:' + CssColor(Look.HeaderFill);
    if Look.HeaderText <> clNone then
      Css := Css + ';color:' + CssColor(Look.HeaderText);
    Css := Css + CssFontStyle(Look.HeaderFontStyle) + '}tr.g td{';
    if Look.GroupFill <> clNone then
      Css := Css + 'background:' + CssColor(Look.GroupFill) + ';';
    if Look.GroupText <> clNone then
      Css := Css + 'color:' + CssColor(Look.GroupText);
    Css := Css + CssFontStyle(Look.GroupFontStyle) + '}tfoot td{';
    if Look.FooterFill <> clNone then
      Css := Css + 'background:' + CssColor(Look.FooterFill) + ';';
    if Look.FooterText <> clNone then
      Css := Css + 'color:' + CssColor(Look.FooterText);
    Css := Css + CssFontStyle(Look.FooterFontStyle) + '}.sym{font-family:''' + PPGSymbolFont +
      '''}a{color:' + CssColor(Look.Accent) + '}';
    SB.Append('<!DOCTYPE html>'#13#10'<html><head><meta charset="utf-8">');
    if Title <> '' then
      SB.Append('<title>' + HtmlEscape(Title) + '</title>');
    SB.Append('<style>' + Css + '</style></head><body>'#13#10);
    if Title <> '' then
      SB.Append('<h1>' + HtmlEscape(Title) + '</h1>'#13#10);
    // Spaltenbreiten wie im Grid
    SB.Append('<table>'#13#10'<colgroup>');
    for C := 0 to Cols - 1 do
      SB.Append('<col style="width:' + IntToStr(Max(Info[C].Width, 20)) + 'px">');
    SB.Append('</colgroup>'#13#10'<thead>');
    // Baender: Laeufe gleicher Baender je Ebene
    for L := 0 to PPGTableBandLevels(Bands) - 1 do
    begin
      SB.Append('<tr>');
      C := 0;
      while C < Cols do
      begin
        B := PPGTableBandAt(Bands, L, C);
        First := C;
        Inc(C);
        while (C < Cols) and (PPGTableBandAt(Bands, L, C) = B) do
          Inc(C);
        Span := C - First;
        S := '<th';
        if Span > 1 then
          S := S + ' colspan="' + IntToStr(Span) + '"';
        if B >= 0 then
          SB.Append(S + ' style="text-align:' + AlignCss[Bands[B].Alignment] + '">' +
            HtmlEscape(Bands[B].Caption) + '</th>')
        else
          SB.Append(S + '></th>');
      end;
      SB.Append('</tr>'#13#10);
    end;
    SB.Append('<tr>');
    for C := 0 to Cols - 1 do
    begin
      Style := 'text-align:' + AlignCss[CL[C].HeaderAlignment];
      if CL[C].Header.Fill <> clNone then
        Style := Style + ';background:' + CssColor(CL[C].Header.Fill);
      if CL[C].Header.TextColor <> clNone then
        Style := Style + ';color:' + CssColor(CL[C].Header.TextColor);
      Style := Style + CssFontStyle(CL[C].Header.FontStyle);
      SB.Append('<th style="' + Style + '">' + HtmlEscape(Info[C].Title) + '</th>');
    end;
    SB.Append('</tr></thead>'#13#10'<tbody>'#13#10);
    for Li := 0 to Lines.Count - 1 do
    begin
      if Lines.Kind(Li) = tlGroup then
      begin
        SB.Append('<tr class="g"><td colspan="' + IntToStr(Max(Cols, 1)) +
          '" style="padding-left:' + IntToStr(6 + Lines.Level(Li) * 16) + 'px">' +
          HtmlEscape(Lines.Text(Li)) + '</td></tr>'#13#10);
        Continue;
      end;
      R := Lines.Row(Li);
      Line := '<tr>';
      for C := 0 to Cols - 1 do
      begin
        M := -1;
        if Length(Merges) > 0 then
          M := MergeAt(C, R);
        Span := 0;
        if M >= 0 then
        begin
          if (C <> Merges[M].Left) or (R <> Merges[M].Top) then
            Continue; // von der Ursprungszelle ueberdeckt
          Span := 1;
        end;
        S := Source.TableCellText(C, R);
        Cs := LookSrc.ExportCellStyle(C, R, S, Lines.Alternate(Li));
        Style := 'text-align:' + AlignCss[Info[C].Alignment];
        Cell := HtmlEscape(S);
        case CL[C].Kind of
          ckCheck:
            begin
              Style := 'text-align:center';
              Cell := SymbolSpan(PPGCheckGlyph(PPGValueChecked(S)), Look.Accent);
            end;
          ckRating:
            begin
              N := PPGRatingStars(CL[C].MaxValue);
              B := Max(0, Min(StrToIntDef(S, 0), N));
              Cell := SymbolSpan(StringOfChar(#$2605, B), Look.Warning) +
                SymbolSpan(StringOfChar(#$2606, N - B), Look.Hint);
            end;
          ckProgress:
            if S <> '' then
            begin
              F := PPGProgressFraction(S, CL[C].MinValue, CL[C].MaxValue);
              Style := Style + BarCss(F, PPGBlendColor(clWhite, Look.Accent, 0.45),
                Cs.Fill);
              Cell := HtmlEscape(Format(PPGStr(@SPPGPercentFormat), [Round(F * 100)]));
              Cs.Fill := clNone;
            end;
          ckColor:
            if (S <> '') and PPGCellColor(S, Clr) then
            begin
              Cs.Fill := PPGColorToRGB(Clr);
              Cs.TextColor := PPGContrastTextColor(Cs.Fill);
            end;
          ckLink:
            if IsSafeLink(S) then
              Cell := '<a href="' + HtmlEscape(Trim(S)) + '">' + HtmlEscape(S) + '</a>'
            else if S <> '' then
            begin
              if Cs.TextColor = clNone then
                Cs.TextColor := Look.Accent;
              Include(Cs.FontStyle, fsUnderline);
            end;
          ckMarkup:
            Cell := HtmlEscape(PPGStripMarkup(S));
        end;
        // Datenbalken der bedingten Formate (Anteil aus dem Zellstil)
        if CL[C].DataBar and (Cs.Bar >= 0) then
        begin
          Style := Style + BarCss(Cs.Bar, PPGBlendColor(clWhite, Cs.BarColor, 0.45), Cs.Fill);
          Cs.Fill := clNone;
        end;
        if Cs.Fill <> clNone then
          Style := Style + ';background:' + CssColor(Cs.Fill);
        if Cs.TextColor <> clNone then
          Style := Style + ';color:' + CssColor(Cs.TextColor);
        if Cs.Bold then
          Include(Cs.FontStyle, fsBold);
        Style := Style + CssFontStyle(Cs.FontStyle);
        if Cs.FontName <> '' then
          Style := Style + ';font-family:''' + Cs.FontName + '''';
        if Cs.FontSize > 0 then
          Style := Style + ';font-size:' + IntToStr(Cs.FontSize) + 'pt';
        S := '<td';
        if Span > 0 then
        begin
          if Merges[M].Right > Merges[M].Left then
            S := S + ' colspan="' + IntToStr(Merges[M].Right - Merges[M].Left + 1) + '"';
          if Merges[M].Bottom > Merges[M].Top then
            S := S + ' rowspan="' + IntToStr(Merges[M].Bottom - Merges[M].Top + 1) + '"';
        end;
        Line := Line + S + ' style="' + Style + '">' + Cell + '</td>';
      end;
      SB.Append(Line + '</tr>'#13#10);
    end;
    SB.Append('</tbody>');
    if PPGTableHasFooter(LookSrc, Cols) then
    begin
      SB.Append(#13#10'<tfoot><tr class="f">');
      for C := 0 to Cols - 1 do
        SB.Append('<td style="text-align:' + AlignCss[Info[C].Alignment] + '">' +
          HtmlEscape(LookSrc.ExportFooterText(C)) + '</td>');
      SB.Append('</tr></tfoot>');
    end;
    SB.Append('</table>'#13#10'</body></html>'#13#10);
    Result := SB.ToString;
  finally
    SB.Free;
    Lines.Free;
  end;
end;

procedure SaveText(const S, FileName: string; WithBom: Boolean);
var
  FS: TFileStream;
  B: TBytes;
begin
  // Unveraendert schreiben (TStringList.Text wuerde Zeilenumbrueche in
  // Feldern angleichen). Excel erkennt UTF-8 in CSV nur am BOM.
  FS := TFileStream.Create(FileName, fmCreate);
  try
    if WithBom then
    begin
      B := TEncoding.UTF8.GetPreamble;
      if Length(B) > 0 then
        FS.WriteBuffer(B[0], Length(B));
    end;
    B := TEncoding.UTF8.GetBytes(S);
    if Length(B) > 0 then
      FS.WriteBuffer(B[0], Length(B));
  finally
    FS.Free;
  end;
end;

procedure PPGExportHtml(const Source: IPPGTableSource; const FileName: string;
  const Title: string);
begin
  SaveText(PPGExportHtmlText(Source, Title), FileName, False);
end;

function PPGExportCsvText(const Source: IPPGTableSource; Separator: Char): string;
var
  SB: TStringBuilder;
  C, R: Integer;

  procedure Field(const AText: string);
  var
    F: string;
    D: Double;
  begin
    F := AText;
    // Formel-Einschleusung: Excel fuehrt Felder mit = + - @ (bzw. Tab/CR
    // am Anfang) als Formel aus. Zahlen wie -5 bleiben unveraendert.
    if (F <> '') and CharInSet(F[1], ['=', '+', '-', '@', #9, #13]) and not TryStrToFloat(F, D) then
      F := '''' + F;
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
  SaveText(PPGExportCsvText(Source, Separator), FileName, True);
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
