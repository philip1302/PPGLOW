unit PPG.Grid.Data;

{ Daten des Grids (Phase 13a).

  - IPPGTableSource: die Tabelle, wie Druck und Export (13e/13f) sie sehen -
    Spalten, Zeilen der Ansicht (gefiltert/sortiert), Text und Wert je
    Zelle. Umgesetzt vom Grid, vom DB-Grid und von eigenen Quellen
    (TPPGStringTableSource). Drucker und Export kennen nur dieses Interface,
    nie ein Control (DIP).
  - TPPGCellStore: der Text-Speicher des Grids (Cells[]). Zeilen werden erst
    beim ersten Schreiben angelegt; ein rein virtuelles Grid (OnGetCellText)
    belegt keinen Speicher.
  - TPPGAggregateAcc (Phase 13c): sammelt Werte einer Spalte (Anzahl, Summe,
    Min, Max) und laesst sich zusammenfuehren - Gruppen-Summen entstehen aus
    den Untergruppen, ohne die Zeilen erneut zu lesen. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.SysUtils, System.Variants, System.Types, Vcl.Graphics, PPG.Grid.Columns,
  PPG.Grid.Styles, PPG.Grid.CellKinds;

type
  TPPGTableColumnInfo = record
    Title: string;
    /// Logische Breite in Pixeln bei 96 dpi.
    Width: Integer;
    Alignment: TAlignment;
    /// Zahlen-/Datumsformat (Excel-Syntax) fuer den Export; '' = Standard.
    Format: string;
  end;

  /// Zeile einer Gliederung (gruppierte Ansicht) fuer den Export.
  TPPGOutlineRow = record
    Row: Integer;    // Tabellenzeile; -1 = Gruppenkopf
    Level: Integer;  // 0 = oberste Ebene
    Text: string;    // Text des Gruppenkopfs (ohne Markup)
  end;

  /// Zusatz fuer den Export (xlsx): Summen, verbundene Zellen, Gliederung.
  IPPGTableExport = interface
    ['{8D3A6E15-2B97-4C40-A5F1-6E0C93B27D18}']
    function ExportAggregate(ACol: Integer): TPPGGridAggregate;
    /// Verbundene Zellen in Tabellen-Koordinaten (Zeilen = Datenzeilen,
    /// Right/Bottom inklusive).
    function ExportMerges: TArray<TRect>;
    /// Gliederung (Gruppenkoepfe und Datenzeilen); leer = ungegliedert.
    function ExportOutline: TArray<TPPGOutlineRow>;
  end;

  IPPGTableSource = interface
    ['{C84D2E15-7B39-4A6F-9E02-1F5A8B3C6D71}']
    function TableColCount: Integer;
    /// Zeilen der Ansicht (ohne Kopfzeilen).
    function TableRowCount: Integer;
    function TableColumn(ACol: Integer): TPPGTableColumnInfo;
    /// Angezeigter Text (so wie im Grid).
    function TableCellText(ACol, ARow: Integer): string;
    /// Wert fuer Export (Zahl, Datum, Boolean oder Text); Null = leer.
    function TableCellValue(ACol, ARow: Integer): Variant;
  end;

  /// Zusatz fuer Druck und Export (13e/13f): Darstellung wie im Grid, aber
  /// in Tabellen-Koordinaten (angezeigte Spalten, Datenzeilen der Ansicht).
  IPPGGridPrintSource = interface
    ['{B5E2A917-3C64-4D08-9F71-2A8C6E0D5B43}']
    /// Bedingte Formate + OnGetCellStyle (Fuellfarben fuer weisses Papier).
    function PrintCellStyle(ACol, ARow: Integer; const Text: string): TPPGGridCellStyle;
    /// Zellart einer Tabellenspalte (nil = Text); Ctx mit dem Bereich der Spalte.
    function PrintCellKind(ACol: Integer; out Ctx: TPPGCellKindContext): IPPGCellKind;
    function PrintFont: TFont;
    /// Zeilenhoehe in logischen Pixeln (96 dpi).
    function PrintRowHeight: Integer;
  end;

  TPPGAggregateAcc = record
    Count: Integer;     // nicht leere Werte
    NumCount: Integer;  // davon Zahlen
    Sum, Min, Max: Double;
    procedure Reset;
    procedure Add(const S: string);
    procedure Merge(const Other: TPPGAggregateAcc);
    /// Ergebnis; False = kein Wert (z.B. Summe ohne Zahlen).
    function Value(Kind: TPPGGridAggregate; out V: Double): Boolean;
    /// Formatierter Text ('' = kein Wert). Fmt = FormatFloat-Muster.
    function Text(Kind: TPPGGridAggregate; const Fmt: string): string;
  end;

  TPPGCellStore = class
  private
    FRows: array of array of string;
    FColCount: Integer;
    procedure EnsureRow(ARow: Integer);
  public
    function Get(ACol, ARow: Integer): string; inline;
    /// True, wenn sich der Wert geaendert hat.
    function Put(ACol, ARow: Integer; const Value: string): Boolean;
    /// Spaltenzahl aendern (kuerzt bestehende Zeilen).
    procedure SetColCount(Value: Integer);
    /// Zeilen ab Value verwerfen.
    procedure TruncateRows(Value: Integer);
    procedure Clear;
  end;

  /// Einfache Tabelle im Speicher (Tests, eigener Export ohne Grid).
  TPPGStringTableSource = class(TInterfacedObject, IPPGTableSource)
  private
    FColumns: array of TPPGTableColumnInfo;
    FStore: TPPGCellStore;
    FRowCount: Integer;
  public
    constructor Create(const Titles: array of string);
    destructor Destroy; override;
    /// Zeile anhaengen; liefert ihren Index.
    function AddRow(const Values: array of string): Integer;
    procedure SetColumn(ACol: Integer; Width: Integer; Alignment: TAlignment);
    function TableColCount: Integer;
    function TableRowCount: Integer;
    function TableColumn(ACol: Integer): TPPGTableColumnInfo;
    function TableCellText(ACol, ARow: Integer): string;
    function TableCellValue(ACol, ARow: Integer): Variant;
  end;

/// Wert aus Text: Zahl (aktuelles Format), sonst Text; '' = Null.
function PPGTableValueOf(const S: string): Variant;

implementation

uses
  PPG.NumberFormat;

function PPGTableValueOf(const S: string): Variant;
var
  D: Double;
begin
  if S = '' then
    Result := Null
  else if TryStrToFloat(S, D) then
    Result := D
  else
    Result := S;
end;

{ TPPGAggregateAcc }

procedure TPPGAggregateAcc.Reset;
begin
  Count := 0;
  NumCount := 0;
  Sum := 0;
  Min := 0;
  Max := 0;
end;

procedure TPPGAggregateAcc.Add(const S: string);
var
  D: Double;
begin
  if S = '' then
    Exit;
  Inc(Count);
  // Schneller Weg zuerst; Tausendertrenner u.ae. ueber PPGParseNumber
  if not TryStrToFloat(S, D) and not PPGParseNumber(S, FormatSettings, D) then
    Exit;
  if NumCount = 0 then
  begin
    Min := D;
    Max := D;
  end
  else
  begin
    if D < Min then
      Min := D;
    if D > Max then
      Max := D;
  end;
  Inc(NumCount);
  Sum := Sum + D;
end;

procedure TPPGAggregateAcc.Merge(const Other: TPPGAggregateAcc);
begin
  if Other.NumCount > 0 then
  begin
    if NumCount = 0 then
    begin
      Min := Other.Min;
      Max := Other.Max;
    end
    else
    begin
      if Other.Min < Min then
        Min := Other.Min;
      if Other.Max > Max then
        Max := Other.Max;
    end;
  end;
  Inc(Count, Other.Count);
  Inc(NumCount, Other.NumCount);
  Sum := Sum + Other.Sum;
end;

function TPPGAggregateAcc.Value(Kind: TPPGGridAggregate; out V: Double): Boolean;
begin
  Result := True;
  case Kind of
    agSum: V := Sum;
    agCount: V := Count;
    agAvg:
      if NumCount > 0 then
        V := Sum / NumCount
      else
        Result := False;
    agMin:
      if NumCount > 0 then
        V := Min
      else
        Result := False;
    agMax:
      if NumCount > 0 then
        V := Max
      else
        Result := False;
  else
    Result := False;
  end;
  if (Kind = agSum) and (NumCount = 0) then
    Result := False;
end;

function TPPGAggregateAcc.Text(Kind: TPPGGridAggregate; const Fmt: string): string;
var
  V: Double;
begin
  if not Value(Kind, V) then
    Result := ''
  else if Kind = agCount then
    Result := IntToStr(Count)
  else if Fmt <> '' then
    Result := FormatFloat(Fmt, V)
  else
    Result := FormatFloat('#,##0.##', V);
end;

{ TPPGCellStore }

procedure TPPGCellStore.EnsureRow(ARow: Integer);
begin
  if Length(FRows) <= ARow then
    SetLength(FRows, ARow + 1);
  if Length(FRows[ARow]) < FColCount then
    SetLength(FRows[ARow], FColCount);
end;

function TPPGCellStore.Get(ACol, ARow: Integer): string;
begin
  if (ARow >= 0) and (ARow < Length(FRows)) and (ACol >= 0) and
    (ACol < Length(FRows[ARow])) then
    Result := FRows[ARow][ACol]
  else
    Result := '';
end;

function TPPGCellStore.Put(ACol, ARow: Integer; const Value: string): Boolean;
begin
  if (ACol >= FColCount) then
    SetColCount(ACol + 1);
  EnsureRow(ARow);
  Result := FRows[ARow][ACol] <> Value;
  if Result then
    FRows[ARow][ACol] := Value;
end;

procedure TPPGCellStore.SetColCount(Value: Integer);
var
  I: Integer;
begin
  FColCount := Value;
  for I := 0 to High(FRows) do
    if Length(FRows[I]) > Value then
      SetLength(FRows[I], Value);
end;

procedure TPPGCellStore.TruncateRows(Value: Integer);
begin
  if Length(FRows) > Value then
    SetLength(FRows, Value);
end;

procedure TPPGCellStore.Clear;
begin
  FRows := nil;
end;

{ TPPGStringTableSource }

constructor TPPGStringTableSource.Create(const Titles: array of string);
var
  I: Integer;
begin
  inherited Create;
  FStore := TPPGCellStore.Create;
  SetLength(FColumns, Length(Titles));
  for I := 0 to High(Titles) do
  begin
    FColumns[I].Title := Titles[I];
    FColumns[I].Width := 64;
    FColumns[I].Alignment := taLeftJustify;
    FColumns[I].Format := '';
  end;
  FStore.SetColCount(Length(Titles));
end;

destructor TPPGStringTableSource.Destroy;
begin
  FreeAndNil(FStore);
  inherited Destroy;
end;

function TPPGStringTableSource.AddRow(const Values: array of string): Integer;
var
  I: Integer;
begin
  Result := FRowCount;
  Inc(FRowCount);
  for I := 0 to High(Values) do
    if I < Length(FColumns) then
      FStore.Put(I, Result, Values[I]);
end;

procedure TPPGStringTableSource.SetColumn(ACol: Integer; Width: Integer; Alignment: TAlignment);
begin
  FColumns[ACol].Width := Width;
  FColumns[ACol].Alignment := Alignment;
end;

function TPPGStringTableSource.TableColCount: Integer;
begin
  Result := Length(FColumns);
end;

function TPPGStringTableSource.TableRowCount: Integer;
begin
  Result := FRowCount;
end;

function TPPGStringTableSource.TableColumn(ACol: Integer): TPPGTableColumnInfo;
begin
  Result := FColumns[ACol];
end;

function TPPGStringTableSource.TableCellText(ACol, ARow: Integer): string;
begin
  Result := FStore.Get(ACol, ARow);
end;

function TPPGStringTableSource.TableCellValue(ACol, ARow: Integer): Variant;
begin
  Result := PPGTableValueOf(FStore.Get(ACol, ARow));
end;

end.
