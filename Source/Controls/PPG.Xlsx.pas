unit PPG.Xlsx;

{ xlsx ohne Excel (Phase 13f): OpenXML ueber System.Zip (ab XE2).

  - TPPGXlsxWriter schreibt eine IPPGTableSource: Kopfzeile fett, Zahlen und
    Datumswerte als echte Werte (nicht als Text), Zahlenformate aus
    Column.Format, Spaltenbreiten, fixierte Kopfzeile, Autofilter, verbundene
    Zellen, Gruppen als Gliederung (outlineLevel) und die Summenzeile als
    Formel (SUBTOTAL). Ueber IPPGTableExport kommen Summen, Verbindungen und
    Gliederung; jede andere Quelle wird als einfache Tabelle geschrieben.
  - Optik (Styled, IPPGTableLook): wie im Grid in heller Darstellung - Schrift,
    Kopf- und Summenfarben, Baender, Gitterlinien, Ausrichtung, Zeilenhoehe,
    Spaltenstile, Zebra, bedingte Formate (Flaeche, Text, fett), Kaestchen als
    1/0 mit Symbol-Format, Bewertung als Sterne, Farb- und Linkzellen.
    Datenbalken, Fortschritt und Symbolsaetze werden native Excel-Regeln, die
    sich beim Bearbeiten in Excel mitrechnen. Jede Kombination landet nur
    einmal in styles.xml (hoechstens MaxXfs, danach das Spaltenformat).
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
    FStyled: Boolean;
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
    /// Optik der Quelle uebernehmen (IPPGTableLook, z.B. Grid); False = nur
    /// Werte mit grauem Kopf.
    property Styled: Boolean read FStyled write FStyled;
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
  Winapi.Windows, System.Zip, System.IOUtils, System.Math, Vcl.Graphics, PPG.Types, PPG.Tokens,
  PPG.Markup, PPG.Grid.Styles, PPG.Grid.Paint, PPG.Grid.CellKinds, PPG.Exceptions, PPG.Lang,
  PPG.Consts;

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

  TXlsxAlign = (xaGeneral, xaLeft, xaRight, xaCenter);

  /// Stile der Arbeitsmappe (styles.xml): jede Schrift, Flaeche, jeder Rahmen
  /// und jede Kombination (cellXfs) nur einmal.
  TXlsxStyles = class
  private
    FFonts, FFills, FBorders, FXfs, FNumFmts: TStringList;
    FIndex: TDictionary<string, Integer>;
    function Intern(List: TStringList; const Prefix, Xml: string): Integer;
  public
    constructor Create(const FontName: string; FontSize: Integer);
    destructor Destroy; override;
    /// Zahlenformat-Id (0 = Standard, 164.. = eigene).
    function NumFmt(const Code: string): Integer;
    function Font(const Name: string; Size: Integer; Color: TColor; Style: TFontStyles): Integer;
    /// Flaeche (clNone = keine).
    function Fill(Color: TColor): Integer;
    /// Duenner Rahmen rundum (clNone = keiner).
    function Border(Color: TColor): Integer;
    /// Zellformat; -1, wenn Excels Grenze erreicht ist.
    function Xf(NumFmtId, FontId, FillId, BorderId: Integer; Align: TXlsxAlign;
      Indent: Integer = 0): Integer;
    function Xml: string;
  end;

const
  /// Excel erlaubt rund 64 000 Zellformate (Farbskalen erzeugen viele).
  MaxXfs = 60000;

function ArgbOf(C: TColor): string;
var
  RGB: Integer;
begin
  RGB := ColorToRGB(C);
  Result := Format('FF%.2x%.2x%.2x', [RGB and $FF, (RGB shr 8) and $FF, (RGB shr 16) and $FF]);
end;

function AlignOf(A: TAlignment): TXlsxAlign;
begin
  case A of
    taRightJustify: Result := xaRight;
    taCenter: Result := xaCenter;
  else
    Result := xaLeft;
  end;
end;

/// Breite der Ziffer 0 in Pixeln bei 96 dpi (Excels Einheit fuer Spaltenbreiten).
function DigitWidth(const FontName: string; FontSize: Integer): Integer;
var
  DC: HDC;
  F, Old: HFONT;
  Sz: TSize;
begin
  Result := 7;
  DC := CreateCompatibleDC(0);
  if DC = 0 then
    Exit;
  try
    F := CreateFont(-MulDiv(FontSize, 96, 72), 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET,
      OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH, PChar(FontName));
    if F = 0 then
      Exit;
    try
      Old := SelectObject(DC, F);
      if GetTextExtentPoint32(DC, '0', 1, Sz) and (Sz.cx > 0) then
        Result := Sz.cx;
      SelectObject(DC, Old);
    finally
      DeleteObject(F);
    end;
  finally
    DeleteDC(DC);
  end;
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

{ TXlsxStyles }

constructor TXlsxStyles.Create(const FontName: string; FontSize: Integer);
begin
  inherited Create;
  FFonts := TStringList.Create;
  FFills := TStringList.Create;
  FBorders := TStringList.Create;
  FXfs := TStringList.Create;
  FNumFmts := TStringList.Create;
  FIndex := TDictionary<string, Integer>.Create;
  // Pflichteintraege: Schrift 0 = Standard der Mappe, Flaechen 0/1, Rahmen 0, Format 0
  Font(FontName, FontSize, clNone, []);
  Intern(FFills, 'L', '<fill><patternFill patternType="none"/></fill>');
  Intern(FFills, 'L', '<fill><patternFill patternType="gray125"/></fill>');
  Intern(FBorders, 'B', '<border><left/><right/><top/><bottom/><diagonal/></border>');
  Xf(0, 0, 0, 0, xaGeneral);
end;

destructor TXlsxStyles.Destroy;
begin
  FIndex.Free;
  FNumFmts.Free;
  FXfs.Free;
  FBorders.Free;
  FFills.Free;
  FFonts.Free;
  inherited Destroy;
end;

function TXlsxStyles.Intern(List: TStringList; const Prefix, Xml: string): Integer;
begin
  if not FIndex.TryGetValue(Prefix + Xml, Result) then
  begin
    Result := List.Add(Xml);
    FIndex.Add(Prefix + Xml, Result);
  end;
end;

function TXlsxStyles.NumFmt(const Code: string): Integer;
begin
  if Code = '' then
    Exit(0);
  Result := 164 + Intern(FNumFmts, 'N', Code);
end;

function TXlsxStyles.Font(const Name: string; Size: Integer; Color: TColor;
  Style: TFontStyles): Integer;
var
  S: string;
begin
  // Reihenfolge laut Schema: b, i, strike, u, sz, color, name
  S := '<font>';
  if fsBold in Style then
    S := S + '<b/>';
  if fsItalic in Style then
    S := S + '<i/>';
  if fsStrikeOut in Style then
    S := S + '<strike/>';
  if fsUnderline in Style then
    S := S + '<u/>';
  S := S + '<sz val="' + IntToStr(Size) + '"/>';
  if Color <> clNone then
    S := S + '<color rgb="' + ArgbOf(Color) + '"/>';
  Result := Intern(FFonts, 'F', S + '<name val="' + PPGXmlEscape(Name) + '"/></font>');
end;

function TXlsxStyles.Fill(Color: TColor): Integer;
begin
  if Color = clNone then
    Exit(0);
  Result := Intern(FFills, 'L', '<fill><patternFill patternType="solid"><fgColor rgb="' +
    ArgbOf(Color) + '"/><bgColor indexed="64"/></patternFill></fill>');
end;

function TXlsxStyles.Border(Color: TColor): Integer;
var
  C: string;
begin
  if Color = clNone then
    Exit(0);
  C := ' style="thin"><color rgb="' + ArgbOf(Color) + '"/>';
  Result := Intern(FBorders, 'B', '<border><left' + C + '</left><right' + C + '</right><top' + C +
    '</top><bottom' + C + '</bottom><diagonal/></border>');
end;

function TXlsxStyles.Xf(NumFmtId, FontId, FillId, BorderId: Integer; Align: TXlsxAlign;
  Indent: Integer): Integer;
const
  AlignName: array[TXlsxAlign] of string = ('', 'left', 'right', 'center');
var
  S, Key: string;
begin
  S := '<xf numFmtId="' + IntToStr(NumFmtId) + '" fontId="' + IntToStr(FontId) + '" fillId="' +
    IntToStr(FillId) + '" borderId="' + IntToStr(BorderId) + '" xfId="0"';
  if NumFmtId > 0 then
    S := S + ' applyNumberFormat="1"';
  if FontId > 0 then
    S := S + ' applyFont="1"';
  if FillId > 0 then
    S := S + ' applyFill="1"';
  if BorderId > 0 then
    S := S + ' applyBorder="1"';
  if (Align = xaGeneral) and (Indent = 0) and (FXfs.Count = 0) then
    S := S + '/>'
  else
  begin
    S := S + ' applyAlignment="1"><alignment';
    if Align <> xaGeneral then
      S := S + ' horizontal="' + AlignName[Align] + '"';
    S := S + ' vertical="center"';
    if Indent > 0 then
      S := S + ' indent="' + IntToStr(Indent) + '"';
    S := S + '/></xf>';
  end;
  Key := 'X' + S;
  if FIndex.TryGetValue(Key, Result) then
    Exit;
  if FXfs.Count >= MaxXfs then
    Exit(-1);
  Result := FXfs.Add(S);
  FIndex.Add(Key, Result);
end;

function TXlsxStyles.Xml: string;
var
  SB: TStringBuilder;
  I: Integer;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append(XmlHead + '<styleSheet xmlns="' + NsMain + '">');
    if FNumFmts.Count > 0 then
    begin
      SB.Append('<numFmts count="' + IntToStr(FNumFmts.Count) + '">');
      for I := 0 to FNumFmts.Count - 1 do
        SB.Append('<numFmt numFmtId="' + IntToStr(164 + I) + '" formatCode="' +
          PPGXmlEscape(FNumFmts[I]) + '"/>');
      SB.Append('</numFmts>');
    end;
    SB.Append('<fonts count="' + IntToStr(FFonts.Count) + '">');
    for I := 0 to FFonts.Count - 1 do
      SB.Append(FFonts[I]);
    SB.Append('</fonts><fills count="' + IntToStr(FFills.Count) + '">');
    for I := 0 to FFills.Count - 1 do
      SB.Append(FFills[I]);
    SB.Append('</fills><borders count="' + IntToStr(FBorders.Count) + '">');
    for I := 0 to FBorders.Count - 1 do
      SB.Append(FBorders[I]);
    SB.Append('</borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" ' +
      'borderId="0"/></cellStyleXfs><cellXfs count="' + IntToStr(FXfs.Count) + '">');
    for I := 0 to FXfs.Count - 1 do
      SB.Append(FXfs[I]);
    SB.Append('</cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/>' +
      '</cellStyles></styleSheet>');
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

constructor TPPGXlsxWriter.Create;
begin
  inherited Create;
  FFreezeHeader := True;
  FAutoFilter := True;
  FWriteFooter := True;
  FOutline := True;
  FStyled := True;
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
const
  // SUBTOTAL 1..9 statt 101..109: auch OpenOffice rechnet sie; gefilterte Zeilen
  // fallen trotzdem heraus, zugeklappte Gruppen zaehlen mit
  AggCode: array[TPPGGridAggregate] of Integer = (0, 9, 1, 5, 4, 3, 0);
  SymbolFont = 'Segoe UI Symbol';
var
  Ex: IPPGTableExport;
  LookSrc: IPPGTableLook;
  Look: TPPGTableLook;
  Strings: TDictionary<string, Integer>;
  StrList: TStringList;
  St: TXlsxStyles;
  Cols, Rows, R, C, I, Level, MaxLevel, RowNo, LastRow, HeadRows, DataStart, Prio, K: Integer;
  Info: array of TPPGTableColumnInfo;
  CL: array of TPPGTableColumnLook;
  NumFmts: array of Integer;  // Zahlenformat je Spalte
  BaseXf: array of Integer;   // Zellformat je Spalte ohne Zellstil
  DateXf: array of Integer;   // Datum ohne eigenes Format (eingebautes Format 14)
  CheckXf: array of Integer;  // Kaestchen
  IsDate: array of Boolean;
  Agg: array of TPPGGridAggregate;
  Outline: TArray<TPPGOutlineRow>;
  Merges: TArray<TRect>;
  Bands: TArray<TPPGTableBand>;
  TmpName, Name, S, Ref, Dim: string;
  Tmp: TFileStream;
  X: TXmlOut;
  Zip: TZipFile;
  V: Variant;
  D: TDateTime;
  Num: Double;
  HasFooter, Alt: Boolean;
  DataBorder, HeadBorder, MDW: Integer;

  function StrEntry(const Key, Inner: string): Integer;
  begin
    if not Strings.TryGetValue(Key, Result) then
    begin
      Result := StrList.Count;
      StrList.Add(Inner);
      Strings.Add(Key, Result);
    end;
  end;

  function StrIndex(const T: string): Integer;
  begin
    if (T <> '') and ((T[1] = ' ') or (T[Length(T)] = ' ')) then
      Result := StrEntry('T' + T, '<t xml:space="preserve">' + PPGXmlEscape(T) + '</t>')
    else
      Result := StrEntry('T' + T, '<t>' + PPGXmlEscape(T) + '</t>');
  end;

  /// Sterne wie im Grid (gefuellte, dann leere). Als einfacher Text in einer
  /// Zellschrift: Rich-Text-Laeufe zeigt nicht jede Tabellenkalkulation richtig.
  function Stars(Value, Count: Integer): string;
  begin
    Value := Max(0, Min(Value, Count));
    Result := StringOfChar(#$2605, Value) + StringOfChar(#$2606, Count - Value);
  end;

  function CellRef(ACol: Integer): string;
  begin
    Result := PPGXlsxColName(ACol) + IntToStr(RowNo);
  end;

  procedure TextCell(ACol: Integer; const T: string; Xf: Integer);
  begin
    X.Add('<c r="' + CellRef(ACol) + '" t="s"');
    if Xf > 0 then
      X.Add(' s="' + IntToStr(Xf) + '"');
    X.Add('><v>' + IntToStr(StrIndex(T)) + '</v></c>');
  end;

  procedure NumCell(ACol: Integer; AValue: Double; Xf: Integer);
  begin
    X.Add('<c r="' + CellRef(ACol) + '"');
    if Xf > 0 then
      X.Add(' s="' + IntToStr(Xf) + '"');
    X.Add('><v>' + FloatToStr(AValue, GInv) + '</v></c>');
  end;

  procedure EmptyCell(ACol, Xf: Integer);
  begin
    if Xf > 0 then
      X.Add('<c r="' + CellRef(ACol) + '" s="' + IntToStr(Xf) + '"/>');
  end;

  function Pick(A, B: TColor): TColor;
  begin
    if A <> clNone then
      Result := A
    else
      Result := B;
  end;

  /// Zellformat einer Spalte mit Zellstil (Fallback: Spaltenformat).
  function StyledXf(ACol, ANumFmt: Integer; const Cs: TPPGGridCellStyle; TextColor: TColor;
    Extra: TFontStyles; Fallback: Integer): Integer;
  var
    FontStyle: TFontStyles;
    FName: string;
    FSize: Integer;
  begin
    FontStyle := Cs.FontStyle + Extra;
    if Cs.Bold then
      Include(FontStyle, fsBold);
    FName := Look.FontName;
    if Cs.FontName <> '' then
      FName := Cs.FontName;
    FSize := Look.FontSize;
    if Cs.FontSize > 0 then
      FSize := Cs.FontSize;
    Result := St.Xf(ANumFmt, St.Font(FName, FSize, Pick(Cs.TextColor, TextColor), FontStyle),
      St.Fill(Pick(Cs.Fill, Look.Fill)), DataBorder, AlignOf(Info[ACol].Alignment));
    if Result < 0 then
      Result := Fallback;
  end;

  procedure DataRow(ARow, ALevel: Integer);
  var
    J, N, Xf, Base: Integer;
    T: string;
    Cs: TPPGGridCellStyle;
    Clr: TColor;
    Checked: Boolean;
  begin
    X.Add('<row r="' + IntToStr(RowNo) + '"');
    if ALevel > 0 then
      X.Add(' outlineLevel="' + IntToStr(Min(ALevel, 7)) + '"');
    X.Add('>');
    for J := 0 to Cols - 1 do
    begin
      V := Source.TableCellValue(J, ARow);
      Cs.Reset;
      T := '';
      if LookSrc <> nil then
      begin
        T := Source.TableCellText(J, ARow);
        Cs := LookSrc.ExportCellStyle(J, ARow, T, Alt);
      end;
      Base := BaseXf[J];
      case CL[J].Kind of
        ckCheck:
          begin
            // 1/0 mit Zahlenformat "Kaestchen": bleibt in Excel filter- und zaehlbar
            if VarType(V) = varBoolean then
              Checked := Boolean(V)
            else
              Checked := TPPGCellPainter.IsCheckedText(VarToStr(V));
            Xf := CheckXf[J];
            if (Cs.Fill <> clNone) and (Cs.Fill <> Look.Fill) then
            begin
              Xf := St.Xf(St.NumFmt('"' + #$2611 + '";"' + #$2611 + '";"' + #$2610 + '"'),
                St.Font(SymbolFont, Look.FontSize + 2, Look.Accent, []), St.Fill(Cs.Fill),
                DataBorder, xaCenter);
              if Xf < 0 then
                Xf := CheckXf[J];
            end;
            NumCell(J, Ord(Checked), Xf);
            Continue;
          end;
        ckRating:
          begin
            N := CL[J].MaxValue;
            if N <= 0 then
              N := 5;
            if N > 20 then
              N := 20;
            Xf := St.Xf(0, St.Font(SymbolFont, Look.FontSize, Look.Warning, []),
              St.Fill(Pick(Cs.Fill, Look.Fill)), DataBorder, AlignOf(Info[J].Alignment));
            if Xf < 0 then
              Xf := Base;
            TextCell(J, Stars(StrToIntDef(VarToStr(V), 0), N), Xf);
            Continue;
          end;
        ckColor:
          begin
            S := VarToStr(V);
            if (S <> '') and PPGCellColor(S, Clr) then
            begin
              // Flaeche in der Farbe, Text mit Kontrast
              Cs.Fill := PPGColorToRGB(Clr);
              if PPGRelativeLuminance(Cs.Fill) > 0.45 then
                Cs.TextColor := clBlack
              else
                Cs.TextColor := clWhite;
              TextCell(J, S, StyledXf(J, 0, Cs, Look.Text, [], Base));
              Continue;
            end;
          end;
        ckLink:
          begin
            S := VarToStr(V);
            if S <> '' then
            begin
              if Cs.TextColor = clNone then
                Cs.TextColor := Look.Accent;
              TextCell(J, S, StyledXf(J, 0, Cs, Look.Text, [fsUnderline], Base));
            end
            else
              EmptyCell(J, Base);
            Continue;
          end;
        ckMarkup:
          if VarType(V) = varUString then
            V := PPGStripMarkup(VarToStr(V));
      end;
      Xf := Base;
      if (LookSrc <> nil) and ((Cs.Fill <> clNone) or (Cs.TextColor <> clNone) or Cs.Bold or
        (Cs.FontStyle <> []) or (Cs.FontName <> '') or (Cs.FontSize > 0)) then
        Xf := StyledXf(J, NumFmts[J], Cs, Look.Text, [], Base);
      case VarType(V) of
        varEmpty, varNull:
          EmptyCell(J, Xf);
        varBoolean:
          begin
            X.Add('<c r="' + CellRef(J) + '" t="b"');
            if Xf > 0 then
              X.Add(' s="' + IntToStr(Xf) + '"');
            X.Add('><v>' + IntToStr(Ord(Boolean(V))) + '</v></c>');
          end;
        varDate:
          begin
            if (NumFmts[J] = 0) and (Xf = Base) then
              Xf := DateXf[J];
            NumCell(J, PPGExcelSerial(VarToDateTime(V)), Xf);
          end;
      else
        if VarIsNumeric(V) then
          NumCell(J, Double(V), Xf)
        else
        begin
          S := VarToStr(V);
          if S = '' then
            EmptyCell(J, Xf)
          // Datumsspalte: Text als Datum, wenn er sich lesen laesst
          else if IsDate[J] and TryStrToDateTime(S, D) then
            NumCell(J, PPGExcelSerial(D), Xf)
          else if (NumFmts[J] > 0) and not IsDate[J] and TryStrToFloat(S, Num) then
            NumCell(J, Num, Xf)
          else
            TextCell(J, S, Xf);
        end;
      end;
    end;
    X.Add('</row>');
    Inc(RowNo);
    Alt := not Alt;
  end;

  procedure HeaderRows;
  var
    L, J, B, K2, Xf, HeadFont, HeadFill: Integer;
  begin
    // Baender (je Ebene eine Zeile), danach die Spaltenkoepfe. Excel verlangt
    // die Zellen einer Zeile in Spaltenreihenfolge.
    HeadFont := St.Font(Look.FontName, Look.FontSize, Look.HeaderText, Look.HeaderFontStyle);
    HeadFill := St.Fill(Look.HeaderFill);
    for L := 0 to HeadRows - 2 do
    begin
      X.Add('<row r="' + IntToStr(RowNo) + '">');
      for J := 0 to Cols - 1 do
      begin
        B := -1;
        for K2 := 0 to High(Bands) do
          if (Bands[K2].Level = L) and (J >= Bands[K2].ColFirst) and (J <= Bands[K2].ColLast) then
          begin
            B := K2;
            Break;
          end;
        if B < 0 then
          EmptyCell(J, St.Xf(0, HeadFont, HeadFill, HeadBorder, xaCenter))
        else
        begin
          Xf := St.Xf(0, HeadFont, HeadFill, HeadBorder, AlignOf(Bands[B].Alignment));
          if J = Bands[B].ColFirst then
            TextCell(J, Bands[B].Caption, Xf)
          else
            EmptyCell(J, Xf);
        end;
      end;
      X.Add('</row>');
      Inc(RowNo);
    end;
    X.Add('<row r="' + IntToStr(RowNo) + '">');
    for J := 0 to Cols - 1 do
    begin
      Xf := St.Xf(0, St.Font(Look.FontName, Look.FontSize, Pick(CL[J].Header.TextColor,
        Look.HeaderText), Look.HeaderFontStyle + CL[J].Header.FontStyle),
        St.Fill(Pick(CL[J].Header.Fill, Look.HeaderFill)), HeadBorder,
        AlignOf(CL[J].HeaderAlignment));
      TextCell(J, Info[J].Title, Xf);
    end;
    X.Add('</row>');
    Inc(RowNo);
  end;

  procedure GroupRow(const AText: string; ALevel: Integer);
  var
    J, Xf, Xf0: Integer;
  begin
    X.Add('<row r="' + IntToStr(RowNo) + '"');
    if ALevel > 0 then
      X.Add(' outlineLevel="' + IntToStr(Min(ALevel, 7)) + '"');
    X.Add('>');
    Xf0 := St.Xf(0, St.Font(Look.FontName, Look.FontSize, Look.GroupText, Look.GroupFontStyle),
      St.Fill(Look.GroupFill), DataBorder, xaLeft, Min(ALevel, 15));
    Xf := St.Xf(0, 0, St.Fill(Look.GroupFill), DataBorder, xaGeneral);
    TextCell(0, AText, Xf0);
    for J := 1 to Cols - 1 do
      EmptyCell(J, Xf);
    X.Add('</row>');
    Inc(RowNo);
    Alt := not Alt; // Gruppenzeilen zaehlen beim Zebra mit (wie im Grid)
  end;

  procedure FooterRow;
  var
    J, Xf, Fmt: Integer;
    FontId, FillId: Integer;
  begin
    // Summenzeile als Formel (SUBTOTAL ueberspringt verschachtelte Teilergebnisse)
    X.Add('<row r="' + IntToStr(RowNo) + '">');
    FontId := St.Font(Look.FontName, Look.FontSize, Look.FooterText, Look.FooterFontStyle);
    FillId := St.Fill(Look.FooterFill);
    for J := 0 to Cols - 1 do
    begin
      if CL[J].FooterFormat <> '' then
        Fmt := St.NumFmt(CL[J].FooterFormat)
      else
        Fmt := NumFmts[J];
      Xf := St.Xf(Fmt, FontId, FillId, HeadBorder, AlignOf(Info[J].Alignment));
      if AggCode[Agg[J]] > 0 then
      begin
        Ref := PPGXlsxColName(J);
        X.Add('<c r="' + CellRef(J) + '"');
        if Xf > 0 then
          X.Add(' s="' + IntToStr(Xf) + '"');
        X.Add(Format('><f>SUBTOTAL(%d,%s%d:%s%d)</f></c>',
          [AggCode[Agg[J]], Ref, DataStart, Ref, RowNo - 1]));
      end
      else
        EmptyCell(J, Xf);
    end;
    X.Add('</row>');
  end;

  procedure ConditionalRules;
  var
    J: Integer;
    Lo, Hi: Integer;
    Range: string;
  begin
    // Datenbalken und Symbolsaetze rechnet Excel selbst (Min..Max der Spalte)
    Prio := 1;
    for J := 0 to Cols - 1 do
    begin
      Range := PPGXlsxColName(J) + IntToStr(DataStart) + ':' + PPGXlsxColName(J) +
        IntToStr(LastRow);
      if CL[J].Kind = ckProgress then
      begin
        Lo := CL[J].MinValue;
        Hi := CL[J].MaxValue;
        if Hi <= Lo then
        begin
          Lo := 0;
          Hi := 100;
        end;
        X.Add('<conditionalFormatting sqref="' + Range + '"><cfRule type="dataBar" priority="' +
          IntToStr(Prio) + '"><dataBar><cfvo type="num" val="' + IntToStr(Lo) +
          '"/><cfvo type="num" val="' + IntToStr(Hi) + '"/><color rgb="' + ArgbOf(Look.Accent) +
          '"/></dataBar></cfRule></conditionalFormatting>');
        Inc(Prio);
      end
      else if CL[J].DataBar then
      begin
        X.Add('<conditionalFormatting sqref="' + Range + '"><cfRule type="dataBar" priority="' +
          IntToStr(Prio) + '"><dataBar><cfvo type="min"/><cfvo type="max"/><color rgb="' +
          ArgbOf(Pick(CL[J].DataBarColor, Look.Accent)) + '"/></dataBar></cfRule>' +
          '</conditionalFormatting>');
        Inc(Prio);
      end;
      if CL[J].IconSet then
      begin
        X.Add('<conditionalFormatting sqref="' + Range + '"><cfRule type="iconSet" priority="' +
          IntToStr(Prio) + '"><iconSet iconSet="3Arrows"><cfvo type="percent" val="0"/>' +
          '<cfvo type="percent" val="33"/><cfvo type="percent" val="67"/></iconSet></cfRule>' +
          '</conditionalFormatting>');
        Inc(Prio);
      end;
    end;
  end;

begin
  if Source = nil then
    raise EPPGError.CreateFmt(PPGStr(@SPPGInvalidArgument), [0, 'Source']);
  Supports(Source, IPPGTableExport, Ex);
  LookSrc := nil;
  if FStyled then
    Supports(Source, IPPGTableLook, LookSrc);
  Look.Reset;
  if LookSrc <> nil then
    Look := LookSrc.ExportLook;
  // Weiss ist Excels Flaeche: keine Fuellung (sonst verschwinden die Excel-Gitterlinien)
  if (Look.Fill <> clNone) and (ColorToRGB(Look.Fill) = $FFFFFF) then
    Look.Fill := clNone;
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
  SetLength(CL, Cols);
  SetLength(NumFmts, Cols);
  SetLength(BaseXf, Cols);
  SetLength(DateXf, Cols);
  SetLength(CheckXf, Cols);
  SetLength(IsDate, Cols);
  SetLength(Agg, Cols);
  St := TXlsxStyles.Create(Look.FontName, Look.FontSize);
  Strings := TDictionary<string, Integer>.Create;
  StrList := TStringList.Create;
  try
    DataBorder := St.Border(Look.Line);
    HeadBorder := St.Border(Look.HeaderLine);
    for C := 0 to Cols - 1 do
    begin
      Info[C] := Source.TableColumn(C);
      if LookSrc <> nil then
        CL[C] := LookSrc.ExportColumnLook(C)
      else
      begin
        CL[C].Reset;
        CL[C].HeaderAlignment := Info[C].Alignment;
      end;
      IsDate[C] := PPGIsDateFormat(Info[C].Format);
      NumFmts[C] := St.NumFmt(Info[C].Format);
      // Ohne Optik der Quelle: Excel richtet aus (Zahlen rechts), sonst wie im Grid
      if (LookSrc = nil) and (Info[C].Alignment = taLeftJustify) then
      begin
        BaseXf[C] := St.Xf(NumFmts[C], 0, St.Fill(Look.Fill), DataBorder, xaGeneral);
        DateXf[C] := St.Xf(14, 0, St.Fill(Look.Fill), DataBorder, xaGeneral);
      end
      else
      begin
        BaseXf[C] := St.Xf(NumFmts[C], St.Font(Look.FontName, Look.FontSize, Look.Text, []),
          St.Fill(Look.Fill), DataBorder, AlignOf(Info[C].Alignment));
        DateXf[C] := St.Xf(14, St.Font(Look.FontName, Look.FontSize, Look.Text, []),
          St.Fill(Look.Fill), DataBorder, AlignOf(Info[C].Alignment));
      end;
      CheckXf[C] := St.Xf(St.NumFmt('"' + #$2611 + '";"' + #$2611 + '";"' + #$2610 + '"'),
        St.Font(SymbolFont, Look.FontSize + 2, Look.Accent, []), St.Fill(Look.Fill), DataBorder,
        xaCenter);
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
    SetLength(Bands, 0);
    if LookSrc <> nil then
      Bands := LookSrc.ExportBands;
    HeadRows := 1;
    for I := 0 to High(Bands) do
      HeadRows := Max(HeadRows, Bands[I].Level + 2);
    DataStart := HeadRows + 1;
    MaxLevel := 0;
    for I := 0 to High(Outline) do
      MaxLevel := Max(MaxLevel, Min(Outline[I].Level, 7));
    if Length(Outline) > 0 then
      LastRow := HeadRows + Length(Outline)
    else
      LastRow := HeadRows + Rows;
    MDW := DigitWidth(Look.FontName, Look.FontSize);
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
            X.Add('<pane ySplit="' + IntToStr(HeadRows) + '" topLeftCell="A' +
              IntToStr(DataStart) + '" activePane="bottomLeft" state="frozen"/>');
          X.Add('</sheetView></sheetViews>');
          // Zeilenhoehe wie im Grid (Punkt = Pixel * 72 / 96)
          if Look.RowHeight > 0 then
            X.Add('<sheetFormatPr defaultRowHeight="' + FloatToStr(Look.RowHeight * 0.75, GInv) +
              '" customHeight="1"')
          else
            X.Add('<sheetFormatPr defaultRowHeight="15"');
          if MaxLevel > 0 then
            X.Add(' outlineLevelRow="' + IntToStr(MaxLevel) + '"');
          X.Add('/>');
          if Cols > 0 then
          begin
            // Excel-Breite in Zeichen der Ziffer 0: (Pixel - 5 px Rand) / Ziffernbreite
            X.Add('<cols>');
            for C := 0 to Cols - 1 do
              X.Add(Format('<col min="%d" max="%d" width="%s" customWidth="1"/>',
                [C + 1, C + 1, FloatToStr(RoundTo(Max(Max(Info[C].Width, 20) - 5, 1) / MDW, -2), GInv)]));
            X.Add('</cols>');
          end;
          X.Add('<sheetData>');
          RowNo := 1;
          HeaderRows;
          // Daten (gegliedert oder flach)
          Alt := False;
          if Length(Outline) > 0 then
            for I := 0 to High(Outline) do
            begin
              Level := Outline[I].Level;
              if Outline[I].Row < 0 then
                GroupRow(Outline[I].Text, Level)
              else
                DataRow(Outline[I].Row, Level);
            end
          else
            for R := 0 to Rows - 1 do
              DataRow(R, 0);
          if HasFooter then
            FooterRow;
          X.Add('</sheetData>');
          if FAutoFilter and (Cols > 0) then
            X.Add('<autoFilter ref="A' + IntToStr(HeadRows) + ':' + PPGXlsxColName(Cols - 1) +
              IntToStr(LastRow) + '"/>');
          if (Length(Merges) > 0) or (Length(Bands) > 0) then
          begin
            S := '';
            K := 0;
            for I := 0 to High(Bands) do
              if (Bands[I].ColLast > Bands[I].ColFirst) and (Bands[I].ColFirst >= 0) and
                (Bands[I].ColLast < Cols) then
              begin
                S := S + '<mergeCell ref="' + PPGXlsxColName(Bands[I].ColFirst) +
                  IntToStr(Bands[I].Level + 1) + ':' + PPGXlsxColName(Bands[I].ColLast) +
                  IntToStr(Bands[I].Level + 1) + '"/>';
                Inc(K);
              end;
            for I := 0 to High(Merges) do
            begin
              S := S + '<mergeCell ref="' + PPGXlsxColName(Merges[I].Left) +
                IntToStr(Merges[I].Top + DataStart) + ':' + PPGXlsxColName(Merges[I].Right) +
                IntToStr(Merges[I].Bottom + DataStart) + '"/>';
              Inc(K);
            end;
            if K > 0 then
              X.Add('<mergeCells count="' + IntToStr(K) + '">' + S + '</mergeCells>');
          end;
          if (Rows > 0) and (LastRow >= DataStart) then
            ConditionalRules;
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
            PPGXmlEscape(StringReplace(Name, '''', '''''', [rfReplaceAll])) + '''!$A$' +
            IntToStr(HeadRows) + ':$' + PPGXlsxColName(Cols - 1) + '$' + IntToStr(LastRow) +
            '</definedName></definedNames>';
        Zip.Add(Utf8(S + '</workbook>'), 'xl/workbook.xml');
        Zip.Add(Utf8(XmlHead + '<Relationships xmlns="' + NsPkgRel + '">' +
          '<Relationship Id="rId1" Type="' + NsRel + '/worksheet" Target="worksheets/sheet1.xml"/>' +
          '<Relationship Id="rId2" Type="' + NsRel + '/styles" Target="styles.xml"/>' +
          '<Relationship Id="rId3" Type="' + NsRel + '/sharedStrings" Target="sharedStrings.xml"/>' +
          '</Relationships>'), 'xl/_rels/workbook.xml.rels');
        // Stile (erst jetzt sind alle Kombinationen bekannt)
        Zip.Add(Utf8(St.Xml), 'xl/styles.xml');
        Zip.Add(TmpName, 'xl/worksheets/sheet1.xml');
        // Shared Strings (zuletzt: erst jetzt sind alle Texte bekannt)
        Tmp := TFileStream.Create(TmpName, fmCreate);
        try
          X := TXmlOut.Create(Tmp);
          try
            X.Add(XmlHead + '<sst xmlns="' + NsMain + '" count="' + IntToStr(StrList.Count) +
              '" uniqueCount="' + IntToStr(StrList.Count) + '">');
            for I := 0 to StrList.Count - 1 do
              X.Add('<si>' + StrList[I] + '</si>');
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
    St.Free;
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
