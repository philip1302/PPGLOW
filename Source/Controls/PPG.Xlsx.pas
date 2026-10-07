unit PPG.Xlsx;

{ xlsx ohne Excel (Phase 13f): OpenXML ueber System.Zip (ab XE2).

  - TPPGXlsxWriter schreibt eine IPPGTableSource: Kopfzeile fett, Zahlen und
    Datumswerte als echte Werte (nicht als Text), Zahlenformate aus
    Column.Format, Spaltenbreiten, fixierte Kopfzeile, Autofilter, verbundene
    Zellen, Gruppen als Gliederung (outlineLevel) und die Summenzeile als
    Formel (SUBTOTAL). Ueber IPPGTableExport kommen Summen, Verbindungen und
    Gliederung; jede andere Quelle wird als einfache Tabelle geschrieben.
  - Speicher: das Tabellenblatt wird Zeile fuer Zeile in eine temporaere Datei
    geschrieben und erst dann gepackt; im Speicher bleiben nur die
    verschiedenen Texte (Shared Strings).
  - Datum: Excel zaehlt ab 1.1.1900 = 1 und kennt den 29.02.1900 (Fehler aus
    Lotus 1-2-3). Ab dem 1.3.1900 ist die Excel-Zahl gleich TDateTime,
    davor eins kleiner (PPGExcelSerial/PPGFromExcelSerial).
  - TPPGXlsxReader liest die erste Tabelle: Werte und Text, ohne Formeln und
    Formate (eigener kleiner XML-Leser, kein MSXML). }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.SysUtils, System.Variants, System.Types, System.Generics.Collections,
  PPG.Grid.Columns, PPG.Grid.Data;

type
  TPPGXlsxWriter = class
  private
    FSheetName: string;
    FFreezeHeader: Boolean;
    FAutoFilter: Boolean;
    FWriteFooter: Boolean;
    FOutline: Boolean;
  public
    constructor Create;
    procedure SaveToFile(const Source: IPPGTableSource; const FileName: string);
    procedure SaveToStream(const Source: IPPGTableSource; Stream: TStream);
    /// Name der Tabelle ('' = "Sheet1").
    property SheetName: string read FSheetName write FSheetName;
    property FreezeHeader: Boolean read FFreezeHeader write FFreezeHeader;
    property AutoFilter: Boolean read FAutoFilter write FAutoFilter;
    /// Summenzeile als SUBTOTAL-Formel (Spalten mit Aggregate).
    property WriteFooter: Boolean read FWriteFooter write FWriteFooter;
    /// Gruppen als Gliederung.
    property Outline: Boolean read FOutline write FOutline;
  end;

  TPPGXlsxReader = class
  private
    FCells: array of array of Variant; // [Zeile][Spalte]
    FColCount: Integer;
    function GetCell(ACol, ARow: Integer): string;
    function GetValue(ACol, ARow: Integer): Variant;
    procedure Parse(Zip: TObject);
  public
    procedure LoadFromFile(const FileName: string);
    procedure LoadFromStream(Stream: TStream);
    function RowCount: Integer;
    property ColCount: Integer read FColCount;
    /// Text (Zahlen im aktuellen Format); '' = leer.
    property Cells[ACol, ARow: Integer]: string read GetCell;
    /// Double, Boolean oder string; Null = leer.
    property Values[ACol, ARow: Integer]: Variant read GetValue;
  end;

function PPGExcelSerial(D: TDateTime): Double;
function PPGFromExcelSerial(V: Double): TDateTime;
/// Spaltenname: 0 -> A, 25 -> Z, 26 -> AA.
function PPGXlsxColName(ACol: Integer): string;
/// Text fuer XML (Sonderzeichen maskiert, ungueltige Steuerzeichen entfernt).
function PPGXmlEscape(const S: string): string;
/// Sieht das Format nach Datum aus (d, m, y ohne Ziffernplatzhalter)?
function PPGIsDateFormat(const Fmt: string): Boolean;

implementation

uses
  System.Zip, System.IOUtils, System.Math, PPG.Exceptions, PPG.Lang, PPG.Consts;

const
  NsMain = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  NsRel = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  NsPkgRel = 'http://schemas.openxmlformats.org/package/2006/relationships';
  XmlHead = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'#13#10;

var
  GInv: TFormatSettings;

function PPGExcelSerial(D: TDateTime): Double;
begin
  // TDateTime 61 = 01.03.1900 = Excel 61; davor fehlt Excels 29.02.1900
  if D < 61 then
    Result := D - 1
  else
    Result := D;
end;

function PPGFromExcelSerial(V: Double): TDateTime;
begin
  if V < 61 then
    Result := V + 1
  else
    Result := V;
end;

function PPGXlsxColName(ACol: Integer): string;
begin
  Result := '';
  Inc(ACol);
  while ACol > 0 do
  begin
    Result := Char(Ord('A') + (ACol - 1) mod 26) + Result;
    ACol := (ACol - 1) div 26;
  end;
end;

function PPGXmlEscape(const S: string): string;
var
  SB: TStringBuilder;
  I: Integer;
  C: Char;
begin
  SB := TStringBuilder.Create(Length(S) + 8);
  try
    for I := 1 to Length(S) do
    begin
      C := S[I];
      case C of
        '&': SB.Append('&amp;');
        '<': SB.Append('&lt;');
        '>': SB.Append('&gt;');
        '"': SB.Append('&quot;');
        #9, #10, #13: SB.Append(C);
        #0..#8, #11, #12, #14..#31, #$FFFE, #$FFFF: ; // in XML nicht erlaubt
      else
        SB.Append(C);
      end;
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function PPGIsDateFormat(const Fmt: string): Boolean;
var
  L: string;
begin
  L := LowerCase(Fmt);
  Result := (Fmt <> '') and ((Pos('d', L) > 0) or (Pos('y', L) > 0) or (Pos('h', L) > 0)) and
    (Pos('0', L) = 0) and (Pos('#', L) = 0);
end;

{ ---- Schreiben ---- }

type
  /// Gepufferte UTF-8-Ausgabe in einen Stream.
  TXmlOut = class
  private
    FStream: TStream;
    FSB: TStringBuilder;
  public
    constructor Create(AStream: TStream);
    destructor Destroy; override;
    procedure Add(const S: string);
    procedure Flush;
  end;

constructor TXmlOut.Create(AStream: TStream);
begin
  inherited Create;
  FStream := AStream;
  FSB := TStringBuilder.Create(65536);
end;

destructor TXmlOut.Destroy;
begin
  Flush;
  FreeAndNil(FSB);
  inherited Destroy;
end;

procedure TXmlOut.Add(const S: string);
begin
  FSB.Append(S);
  if FSB.Length > 60000 then
    Flush;
end;

procedure TXmlOut.Flush;
var
  B: TBytes;
begin
  if FSB.Length = 0 then
    Exit;
  B := TEncoding.UTF8.GetBytes(FSB.ToString);
  FStream.WriteBuffer(B[0], Length(B));
  FSB.Clear;
end;

constructor TPPGXlsxWriter.Create;
begin
  inherited Create;
  FFreezeHeader := True;
  FAutoFilter := True;
  FWriteFooter := True;
  FOutline := True;
end;

procedure TPPGXlsxWriter.SaveToFile(const Source: IPPGTableSource; const FileName: string);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Source, FS);
  finally
    FS.Free;
  end;
end;

function Utf8(const S: string): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(S);
end;

procedure TPPGXlsxWriter.SaveToStream(const Source: IPPGTableSource; Stream: TStream);
var
  Ex: IPPGTableExport;
  Strings: TDictionary<string, Integer>;
  StrList: TStringList;
  Cols, Rows, R, C, I, Level, MaxLevel, RowNo, LastRow, K: Integer;
  Info: array of TPPGTableColumnInfo;
  Styles: array of Integer;   // Stil je Spalte
  IsDate: array of Boolean;
  Agg: array of TPPGGridAggregate;
  Formats: TStringList;
  Outline: TArray<TPPGOutlineRow>;
  Merges: TArray<TRect>;
  TmpName, Name, S, Ref, Dim: string;
  Tmp: TFileStream;
  X: TXmlOut;
  Zip: TZipFile;
  V: Variant;
  D: TDateTime;
  Num: Double;
  HasFooter: Boolean;

  function StrIndex(const T: string): Integer;
  begin
    if not Strings.TryGetValue(T, Result) then
    begin
      Result := StrList.Count;
      StrList.Add(T);
      Strings.Add(T, Result);
    end;
  end;

  procedure TextCell(ACol: Integer; const T: string; Style: Integer);
  begin
    X.Add('<c r="' + PPGXlsxColName(ACol) + IntToStr(RowNo) + '" t="s"');
    if Style > 0 then
      X.Add(' s="' + IntToStr(Style) + '"');
    X.Add('><v>' + IntToStr(StrIndex(T)) + '</v></c>');
  end;

  procedure NumCell(ACol: Integer; AValue: Double; Style: Integer);
  begin
    X.Add('<c r="' + PPGXlsxColName(ACol) + IntToStr(RowNo) + '"');
    if Style > 0 then
      X.Add(' s="' + IntToStr(Style) + '"');
    X.Add('><v>' + FloatToStr(AValue, GInv) + '</v></c>');
  end;

  procedure DataRow(ARow, ALevel: Integer);
  var
    J: Integer;
  begin
    X.Add('<row r="' + IntToStr(RowNo) + '"');
    if ALevel > 0 then
      X.Add(' outlineLevel="' + IntToStr(Min(ALevel, 7)) + '"');
    X.Add('>');
    for J := 0 to Cols - 1 do
    begin
      V := Source.TableCellValue(J, ARow);
      case VarType(V) of
        varEmpty, varNull:
          Continue;
        varBoolean:
          X.Add('<c r="' + PPGXlsxColName(J) + IntToStr(RowNo) + '" t="b"><v>' +
            IntToStr(Ord(Boolean(V))) + '</v></c>');
        varDate:
          NumCell(J, PPGExcelSerial(VarToDateTime(V)), IfThen(Styles[J] > 0, Styles[J], 2));
      else
        if VarIsNumeric(V) then
          NumCell(J, Double(V), Styles[J])
        else
        begin
          S := VarToStr(V);
          if S = '' then
            Continue;
          // Datumsspalte: Text als Datum, wenn er sich lesen laesst
          if IsDate[J] and TryStrToDateTime(S, D) then
            NumCell(J, PPGExcelSerial(D), Styles[J])
          else if (Styles[J] > 2) and TryStrToFloat(S, Num) then
            NumCell(J, Num, Styles[J])
          else
            TextCell(J, S, 0);
        end;
      end;
    end;
    X.Add('</row>');
    Inc(RowNo);
  end;

const
  AggCode: array[TPPGGridAggregate] of Integer = (0, 109, 101, 105, 104, 103, 0);
begin
  if Source = nil then
    raise EPPGError.CreateFmt(PPGStr(@SPPGInvalidArgument), [0, 'Source']);
  Supports(Source, IPPGTableExport, Ex);
  Cols := Source.TableColCount;
  Rows := Source.TableRowCount;
  Name := FSheetName;
  if Name = '' then
    Name := 'Sheet1';
  // Excel: hoechstens 31 Zeichen, keine []:*?/\
  for I := 1 to Length(Name) do
    if CharInSet(Name[I], ['[', ']', ':', '*', '?', '/', '\']) then
      Name[I] := '_';
  Name := Copy(Name, 1, 31);
  SetLength(Info, Cols);
  SetLength(Styles, Cols);
  SetLength(IsDate, Cols);
  SetLength(Agg, Cols);
  Formats := TStringList.Create;
  Strings := TDictionary<string, Integer>.Create;
  StrList := TStringList.Create;
  try
    // Stile: 0 normal, 1 fett, 2 Datum (eingebaut 14), 3.. eigene Formate
    for C := 0 to Cols - 1 do
    begin
      Info[C] := Source.TableColumn(C);
      IsDate[C] := PPGIsDateFormat(Info[C].Format);
      Styles[C] := 0;
      if Info[C].Format <> '' then
      begin
        K := Formats.IndexOf(Info[C].Format);
        if K < 0 then
          K := Formats.Add(Info[C].Format);
        Styles[C] := 3 + K;
      end;
      Agg[C] := agNone;
      if (Ex <> nil) and FWriteFooter then
        Agg[C] := Ex.ExportAggregate(C);
    end;
    HasFooter := False;
    for C := 0 to Cols - 1 do
      if AggCode[Agg[C]] > 0 then
        HasFooter := True;
    SetLength(Outline, 0);
    if (Ex <> nil) and FOutline then
      Outline := Ex.ExportOutline;
    SetLength(Merges, 0);
    if Ex <> nil then
      Merges := Ex.ExportMerges;
    MaxLevel := 0;
    for I := 0 to High(Outline) do
      MaxLevel := Max(MaxLevel, Min(Outline[I].Level, 7));
    if Length(Outline) > 0 then
      LastRow := 1 + Length(Outline)
    else
      LastRow := 1 + Rows;
    // 1. Tabellenblatt in eine temporaere Datei (Zeile fuer Zeile)
    TmpName := TPath.GetTempFileName;
    try
      Tmp := TFileStream.Create(TmpName, fmCreate);
      try
        X := TXmlOut.Create(Tmp);
        try
          X.Add(XmlHead + '<worksheet xmlns="' + NsMain + '" xmlns:r="' + NsRel + '">');
          if MaxLevel > 0 then
            X.Add('<sheetPr><outlinePr summaryBelow="0"/></sheetPr>');
          Dim := 'A1:' + PPGXlsxColName(Max(Cols, 1) - 1) + IntToStr(LastRow + Ord(HasFooter));
          X.Add('<dimension ref="' + Dim + '"/>');
          X.Add('<sheetViews><sheetView workbookViewId="0">');
          if FFreezeHeader then
            X.Add('<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>');
          X.Add('</sheetView></sheetViews>');
          X.Add('<sheetFormatPr defaultRowHeight="15"');
          if MaxLevel > 0 then
            X.Add(' outlineLevelRow="' + IntToStr(MaxLevel) + '"');
          X.Add('/>');
          if Cols > 0 then
          begin
            X.Add('<cols>');
            for C := 0 to Cols - 1 do
              X.Add(Format('<col min="%d" max="%d" width="%s" customWidth="1"/>',
                [C + 1, C + 1, FloatToStr(RoundTo(Max(Info[C].Width, 20) / 7 + 0.7, -2), GInv)]));
            X.Add('</cols>');
          end;
          X.Add('<sheetData>');
          // Kopfzeile
          RowNo := 1;
          X.Add('<row r="1">');
          for C := 0 to Cols - 1 do
            TextCell(C, Info[C].Title, 1);
          X.Add('</row>');
          RowNo := 2;
          // Daten (gegliedert oder flach)
          if Length(Outline) > 0 then
            for I := 0 to High(Outline) do
            begin
              Level := Outline[I].Level;
              if Outline[I].Row < 0 then
              begin
                X.Add('<row r="' + IntToStr(RowNo) + '"');
                if Level > 0 then
                  X.Add(' outlineLevel="' + IntToStr(Min(Level, 7)) + '"');
                X.Add('>');
                TextCell(0, Outline[I].Text, 1);
                X.Add('</row>');
                Inc(RowNo);
              end
              else
                DataRow(Outline[I].Row, Level);
            end
          else
            for R := 0 to Rows - 1 do
              DataRow(R, 0);
          // Summenzeile als Formel (SUBTOTAL ueberspringt verschachtelte Teilergebnisse)
          if HasFooter then
          begin
            X.Add('<row r="' + IntToStr(RowNo) + '">');
            for C := 0 to Cols - 1 do
              if AggCode[Agg[C]] > 0 then
              begin
                Ref := PPGXlsxColName(C);
                X.Add('<c r="' + Ref + IntToStr(RowNo) + '"');
                if Styles[C] > 0 then
                  X.Add(' s="' + IntToStr(Styles[C]) + '"');
                X.Add(Format('><f>SUBTOTAL(%d,%s2:%s%d)</f></c>',
                  [AggCode[Agg[C]], Ref, Ref, RowNo - 1]));
              end;
            X.Add('</row>');
          end;
          X.Add('</sheetData>');
          if FAutoFilter and (Cols > 0) then
            X.Add('<autoFilter ref="A1:' + PPGXlsxColName(Cols - 1) + IntToStr(LastRow) + '"/>');
          if Length(Merges) > 0 then
          begin
            X.Add('<mergeCells count="' + IntToStr(Length(Merges)) + '">');
            for I := 0 to High(Merges) do
              X.Add('<mergeCell ref="' + PPGXlsxColName(Merges[I].Left) +
                IntToStr(Merges[I].Top + 2) + ':' + PPGXlsxColName(Merges[I].Right) +
                IntToStr(Merges[I].Bottom + 2) + '"/>');
            X.Add('</mergeCells>');
          end;
          X.Add('</worksheet>');
        finally
          X.Free;
        end;
      finally
        Tmp.Free;
      end;
      // 2. Paket packen
      Zip := TZipFile.Create;
      try
        Zip.Open(Stream, zmWrite);
        Zip.Add(Utf8(XmlHead +
          '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
          '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
          '<Default Extension="xml" ContentType="application/xml"/>' +
          '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' +
          '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' +
          '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' +
          '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>' +
          '</Types>'), '[Content_Types].xml');
        Zip.Add(Utf8(XmlHead + '<Relationships xmlns="' + NsPkgRel + '">' +
          '<Relationship Id="rId1" Type="' + NsRel + '/officeDocument" Target="xl/workbook.xml"/>' +
          '</Relationships>'), '_rels/.rels');
        S := XmlHead + '<workbook xmlns="' + NsMain + '" xmlns:r="' + NsRel + '"><sheets>' +
          '<sheet name="' + PPGXmlEscape(Name) + '" sheetId="1" r:id="rId1"/></sheets>';
        if FAutoFilter and (Cols > 0) then
          S := S + '<definedNames><definedName name="_xlnm._FilterDatabase" localSheetId="0" hidden="1">''' +
            PPGXmlEscape(StringReplace(Name, '''', '''''', [rfReplaceAll])) + '''!$A$1:$' +
            PPGXlsxColName(Cols - 1) + '$' + IntToStr(LastRow) + '</definedName></definedNames>';
        Zip.Add(Utf8(S + '</workbook>'), 'xl/workbook.xml');
        Zip.Add(Utf8(XmlHead + '<Relationships xmlns="' + NsPkgRel + '">' +
          '<Relationship Id="rId1" Type="' + NsRel + '/worksheet" Target="worksheets/sheet1.xml"/>' +
          '<Relationship Id="rId2" Type="' + NsRel + '/styles" Target="styles.xml"/>' +
          '<Relationship Id="rId3" Type="' + NsRel + '/sharedStrings" Target="sharedStrings.xml"/>' +
          '</Relationships>'), 'xl/_rels/workbook.xml.rels');
        // Stile
        S := XmlHead + '<styleSheet xmlns="' + NsMain + '">';
        if Formats.Count > 0 then
        begin
          S := S + '<numFmts count="' + IntToStr(Formats.Count) + '">';
          for I := 0 to Formats.Count - 1 do
            S := S + '<numFmt numFmtId="' + IntToStr(164 + I) + '" formatCode="' +
              PPGXmlEscape(Formats[I]) + '"/>';
          S := S + '</numFmts>';
        end;
        S := S + '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>' +
          '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>' +
          '<fills count="2"><fill><patternFill patternType="none"/></fill>' +
          '<fill><patternFill patternType="gray125"/></fill></fills>' +
          '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>' +
          '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>' +
          '<cellXfs count="' + IntToStr(3 + Formats.Count) + '">' +
          '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>' +
          '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>' +
          '<xf numFmtId="14" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>';
        for I := 0 to Formats.Count - 1 do
          S := S + '<xf numFmtId="' + IntToStr(164 + I) +
            '" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>';
        S := S + '</cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/>' +
          '</cellStyles></styleSheet>';
        Zip.Add(Utf8(S), 'xl/styles.xml');
        Zip.Add(TmpName, 'xl/worksheets/sheet1.xml');
        // Shared Strings (zuletzt: erst jetzt sind alle Texte bekannt)
        Tmp := TFileStream.Create(TmpName, fmCreate);
        try
          X := TXmlOut.Create(Tmp);
          try
            X.Add(XmlHead + '<sst xmlns="' + NsMain + '" count="' + IntToStr(StrList.Count) +
              '" uniqueCount="' + IntToStr(StrList.Count) + '">');
            for I := 0 to StrList.Count - 1 do
            begin
              S := StrList[I];
              if (S <> '') and ((S[1] = ' ') or (S[Length(S)] = ' ')) then
                X.Add('<si><t xml:space="preserve">' + PPGXmlEscape(S) + '</t></si>')
              else
                X.Add('<si><t>' + PPGXmlEscape(S) + '</t></si>');
            end;
            X.Add('</sst>');
          finally
            X.Free;
          end;
        finally
          Tmp.Free;
        end;
        Zip.Add(TmpName, 'xl/sharedStrings.xml');
        Zip.Close;
      finally
        Zip.Free;
      end;
    finally
      if FileExists(TmpName) then
        System.SysUtils.DeleteFile(TmpName);
    end;
  finally
    StrList.Free;
    Strings.Free;
    Formats.Free;
  end;
end;

{ ---- Lesen ---- }

function XmlUnescape(const S: string): string;
var
  I, J, N: Integer;
  E: string;
  SB: TStringBuilder;
begin
  if Pos('&', S) = 0 then
    Exit(S);
  SB := TStringBuilder.Create(Length(S));
  try
    I := 1;
    while I <= Length(S) do
    begin
      if S[I] = '&' then
      begin
        J := I + 1;
        while (J <= Length(S)) and (S[J] <> ';') and (J - I < 12) do
          Inc(J);
        E := Copy(S, I + 1, J - I - 1);
        if E = 'amp' then
          SB.Append('&')
        else if E = 'lt' then
          SB.Append('<')
        else if E = 'gt' then
          SB.Append('>')
        else if E = 'quot' then
          SB.Append('"')
        else if E = 'apos' then
          SB.Append('''')
        else if (E <> '') and (E[1] = '#') then
        begin
          if (Length(E) > 1) and ((E[2] = 'x') or (E[2] = 'X')) then
            N := StrToIntDef('$' + Copy(E, 3, MaxInt), 63)
          else
            N := StrToIntDef(Copy(E, 2, MaxInt), 63);
          if N > $FFFF then
          begin
            Dec(N, $10000);
            SB.Append(Char($D800 + (N shr 10)));
            SB.Append(Char($DC00 + (N and $3FF)));
          end
          else
            SB.Append(Char(N));
        end
        else
          SB.Append(Copy(S, I, J - I + 1));
        I := J + 1;
      end
      else
      begin
        SB.Append(S[I]);
        Inc(I);
      end;
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

/// Wert eines Attributs im Tag-Text (z.B. 'r="A1" t="s"').
function Attr(const Tag, Name: string): string;
var
  P, Q: Integer;
begin
  Result := '';
  P := Pos(' ' + Name + '="', Tag);
  if P = 0 then
    Exit;
  Inc(P, Length(Name) + 3);
  Q := P;
  while (Q <= Length(Tag)) and (Tag[Q] <> '"') do
    Inc(Q);
  Result := XmlUnescape(Copy(Tag, P, Q - P));
end;

/// Naechstes Tag ab From: liefert Name, Attribut-Text und Position danach.
function NextTag(const S: string; var From: Integer; out Name, Attrs: string;
  out SelfClosing: Boolean): Boolean;
var
  P, Q, E: Integer;
begin
  Result := False;
  P := From;
  while (P <= Length(S)) and (S[P] <> '<') do
    Inc(P);
  if P > Length(S) then
    Exit;
  Q := P + 1;
  E := Q;
  while (E <= Length(S)) and (S[E] <> '>') do
    Inc(E);
  // Name bis Leerzeichen, '/' oder '>' (schliessendes Tag: '/' gehoert zum Namen)
  if (Q < E) and (S[Q] = '/') then
    Inc(Q);
  while (Q < E) and not CharInSet(S[Q], [' ', '/', '>', #9, #10, #13]) do
    Inc(Q);
  Name := Copy(S, P + 1, Q - P - 1);
  Attrs := ' ' + Copy(S, Q, E - Q);
  SelfClosing := (E > P) and (S[E - 1] = '/');
  From := E + 1;
  Result := True;
end;

/// Text bis zum naechsten '<' ab From.
function TextUntilTag(const S: string; var From: Integer): string;
var
  P: Integer;
begin
  P := From;
  while (P <= Length(S)) and (S[P] <> '<') do
    Inc(P);
  Result := XmlUnescape(Copy(S, From, P - From));
  From := P;
end;

function ZipText(Zip: TZipFile; const Name: string): string;
var
  B: TBytes;
  I: Integer;
begin
  Result := '';
  I := Zip.IndexOf(Name);
  if I < 0 then
    Exit;
  Zip.Read(I, B);
  Result := TEncoding.UTF8.GetString(B);
end;

/// "B12" -> Spalte 1, Zeile 11 (0-basiert).
procedure SplitRef(const Ref: string; out ACol, ARow: Integer);
var
  I: Integer;
begin
  ACol := 0;
  I := 1;
  while (I <= Length(Ref)) and CharInSet(Ref[I], ['A'..'Z']) do
  begin
    ACol := ACol * 26 + Ord(Ref[I]) - Ord('A') + 1;
    Inc(I);
  end;
  Dec(ACol);
  ARow := StrToIntDef(Copy(Ref, I, MaxInt), 1) - 1;
end;

procedure TPPGXlsxReader.LoadFromFile(const FileName: string);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(FS);
  finally
    FS.Free;
  end;
end;

procedure TPPGXlsxReader.LoadFromStream(Stream: TStream);
var
  Zip: TZipFile;
begin
  Zip := TZipFile.Create;
  try
    Zip.Open(Stream, zmRead);
    Parse(Zip);
  finally
    Zip.Free;
  end;
end;

procedure TPPGXlsxReader.Parse(Zip: TObject);
var
  Z: TZipFile;
  S, Name, Attrs, SheetPath, RId, T, CellType, Ref: string;
  P, I, Col, Row, Depth: Integer;
  SC, InSi, InCell: Boolean;
  Shared: TStringList;
  SiText: TStringBuilder;
  V: Variant;
  D: Double;
begin
  Z := TZipFile(Zip);
  FCells := nil;
  FColCount := 0;
  // Erste Tabelle: workbook.xml -> r:id -> Ziel in den Beziehungen
  SheetPath := 'xl/worksheets/sheet1.xml';
  S := ZipText(Z, 'xl/workbook.xml');
  P := 1;
  RId := '';
  while NextTag(S, P, Name, Attrs, SC) do
    if Name = 'sheet' then
    begin
      RId := Attr(Attrs, 'r:id');
      Break;
    end;
  if RId <> '' then
  begin
    S := ZipText(Z, 'xl/_rels/workbook.xml.rels');
    P := 1;
    while NextTag(S, P, Name, Attrs, SC) do
      if (Name = 'Relationship') and (Attr(Attrs, 'Id') = RId) then
      begin
        T := Attr(Attrs, 'Target');
        if (T <> '') and (T[1] = '/') then
          SheetPath := Copy(T, 2, MaxInt)
        else if T <> '' then
          SheetPath := 'xl/' + T;
        Break;
      end;
  end;
  if Z.IndexOf(SheetPath) < 0 then
    raise EPPGError.CreateFmt(PPGStr(@SPPGXlsxInvalid), [SheetPath]);
  // Shared Strings (auch mit Formatierungslaeufen <r><t>..</t></r>)
  Shared := TStringList.Create;
  SiText := TStringBuilder.Create;
  try
    S := ZipText(Z, 'xl/sharedStrings.xml');
    P := 1;
    InSi := False;
    while NextTag(S, P, Name, Attrs, SC) do
      if Name = 'si' then
      begin
        InSi := True;
        SiText.Clear;
      end
      else if Name = '/si' then
      begin
        Shared.Add(SiText.ToString);
        InSi := False;
      end
      else if (Name = 't') and InSi and not SC then
        SiText.Append(TextUntilTag(S, P))
      else if (Name = 'rPh') and not SC then
      begin
        // Phonetik-Hilfe nicht mitlesen
        Depth := 1;
        while (Depth > 0) and NextTag(S, P, Name, Attrs, SC) do
          if Name = '/rPh' then
            Dec(Depth);
      end;
    // Zellen
    S := ZipText(Z, SheetPath);
    P := 1;
    InCell := False;
    Col := 0;
    Row := 0;
    CellType := '';
    while NextTag(S, P, Name, Attrs, SC) do
    begin
      if Name = 'c' then
      begin
        Ref := Attr(Attrs, 'r');
        CellType := Attr(Attrs, 't');
        SplitRef(Ref, Col, Row);
        InCell := not SC;
      end
      else if Name = '/c' then
        InCell := False
      else if InCell and ((Name = 'v') or (Name = 't')) and not SC then
      begin
        T := TextUntilTag(S, P);
        if CellType = 's' then
        begin
          I := StrToIntDef(T, -1);
          if (I >= 0) and (I < Shared.Count) then
            V := Shared[I]
          else
            V := '';
        end
        else if CellType = 'b' then
          V := T = '1'
        else if (CellType = 'str') or (CellType = 'inlineStr') or (CellType = 'e') then
          V := T
        else if TryStrToFloat(T, D, GInv) then
          V := D
        else
          V := T;
        if (Row >= 0) and (Col >= 0) and (Row < 1048576) and (Col < 16384) then
        begin
          if Row >= Length(FCells) then
            SetLength(FCells, Row + 1);
          if Col >= Length(FCells[Row]) then
            SetLength(FCells[Row], Col + 1);
          FCells[Row][Col] := V;
          if Col + 1 > FColCount then
            FColCount := Col + 1;
        end;
      end;
    end;
  finally
    SiText.Free;
    Shared.Free;
  end;
end;

function TPPGXlsxReader.RowCount: Integer;
begin
  Result := Length(FCells);
end;

function TPPGXlsxReader.GetValue(ACol, ARow: Integer): Variant;
begin
  Result := Null;
  if (ARow >= 0) and (ARow < Length(FCells)) and (ACol >= 0) and (ACol < Length(FCells[ARow])) and
    not VarIsEmpty(FCells[ARow][ACol]) then
    Result := FCells[ARow][ACol];
end;

function TPPGXlsxReader.GetCell(ACol, ARow: Integer): string;
var
  V: Variant;
begin
  V := GetValue(ACol, ARow);
  if VarIsNull(V) then
    Result := ''
  else if VarType(V) = varBoolean then
  begin
    if Boolean(V) then
      Result := '1'
    else
      Result := '0';
  end
  else if VarIsNumeric(V) then
    Result := FloatToStr(Double(V))
  else
    Result := VarToStr(V);
end;

initialization
  GInv := TFormatSettings.Create('en-US');
  GInv.DecimalSeparator := '.';
  GInv.ThousandSeparator := ',';

end.
