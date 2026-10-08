unit PPG.Grid.Look;

{ Gemeinsame Bausteine fuer Ausgaben mit der Optik des Grids (Phase 17):
  xlsx, Druck/PDF und HTML lesen dieselbe Quelle (IPPGTableSource mit
  IPPGTableExport und IPPGTableLook) und brauchen dieselbe Zeilenfolge,
  dieselben Baender und dieselben Ersatztexte fuer Zellarten.

  - TPPGTableLines: Zeilen der Ausgabe in Reihenfolge - Gruppenkoepfe und
    Datenzeilen aus der Gliederung, am Ende optional die Summenzeile. Ohne
    Gliederung ist Zeile I = Tabellenzeile I (nichts wird vorab gelesen,
    virtuelle Quellen bleiben seitenweise).
  - Zebra wie im Grid: jede zweite angezeigte Zeile, Gruppenkoepfe zaehlen mit.
  - Kaestchen und Sterne als Zeichen (Segoe UI Symbol), wenn eine Ausgabe
    sie nicht zeichnen kann (HTML) bzw. als Text braucht (xlsx). }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.SysUtils, System.Variants, Vcl.Graphics, PPG.Grid.Columns,
  PPG.Grid.Data, PPG.Grid.Styles;

const
  /// Schrift fuer Kaestchen und Sterne.
  PPGSymbolFont = 'Segoe UI Symbol';

type
  TPPGTableLineKind = (tlData, tlGroup, tlFooter);

  TPPGTableLines = class
  private
    FOutline: TArray<TPPGOutlineRow>;
    FRows: Integer;
    FFooter: Boolean;
  public
    /// Outline = Gruppenkoepfe und Datenzeilen; Footer = Summenzeile anhaengen.
    constructor Create(const Source: IPPGTableSource; UseOutline, Footer: Boolean);
    function Count: Integer;
    function Kind(Index: Integer): TPPGTableLineKind;
    /// Tabellenzeile einer Datenzeile (sonst -1).
    function Row(Index: Integer): Integer;
    /// Gliederungsebene (0 = oben).
    function Level(Index: Integer): Integer;
    /// Text eines Gruppenkopfs.
    function Text(Index: Integer): string;
    /// Zebra: jede zweite angezeigte Zeile (wie im Grid).
    function Alternate(Index: Integer): Boolean;
    function Grouped: Boolean;
  end;

/// Gibt es fuer eine Spalte einen Summentext?
function PPGTableHasFooter(const Look: IPPGTableLook; ColCount: Integer): Boolean;
/// Anzahl Bandreihen (0 = keine Baender).
function PPGTableBandLevels(const Bands: TArray<TPPGTableBand>): Integer;
/// Band, das Spalte ACol in Ebene Level ueberdeckt (-1 = keins).
function PPGTableBandAt(const Bands: TArray<TPPGTableBand>; Level, ACol: Integer): Integer;
/// Kaestchen-Zustand aus einem Wert (Boolean, 1/0, 'True', 'Ja').
function PPGValueChecked(const V: Variant): Boolean;
function PPGCheckGlyph(Checked: Boolean): string;
/// Anzahl Sterne einer Bewertungsspalte (MaxValue, Vorgabe 5, hoechstens 20).
function PPGRatingStars(MaxValue: Integer): Integer;
/// Gefuellte und leere Sterne ('3' bei 5 -> 3 + 2).
function PPGStarsText(Value, Count: Integer): string;
/// Zellstil mit Vorgaben der Tabelle (Flaeche, Text) aufgefuellt.
function PPGResolveCellLook(const Look: TPPGTableLook;
  const Cs: TPPGGridCellStyle): TPPGGridCellStyle;
/// Anteil 0..1 eines Fortschritts (MinValue/MaxValue; 0/0 = 0..100).
function PPGProgressFraction(const V: Variant; MinValue, MaxValue: Integer): Double;

implementation

uses
  System.Math, PPG.Grid.Paint;

{ TPPGTableLines }

constructor TPPGTableLines.Create(const Source: IPPGTableSource; UseOutline, Footer: Boolean);
var
  Ex: IPPGTableExport;
begin
  inherited Create;
  FRows := 0;
  if Source <> nil then
    FRows := Source.TableRowCount;
  SetLength(FOutline, 0);
  if UseOutline and Supports(Source, IPPGTableExport, Ex) then
    FOutline := Ex.ExportOutline;
  FFooter := Footer;
end;

function TPPGTableLines.Grouped: Boolean;
begin
  Result := Length(FOutline) > 0;
end;

function TPPGTableLines.Count: Integer;
begin
  if Grouped then
    Result := Length(FOutline)
  else
    Result := FRows;
  Inc(Result, Ord(FFooter));
end;

function TPPGTableLines.Kind(Index: Integer): TPPGTableLineKind;
begin
  if FFooter and (Index = Count - 1) then
    Result := tlFooter
  else if Grouped and (FOutline[Index].Row < 0) then
    Result := tlGroup
  else
    Result := tlData;
end;

function TPPGTableLines.Row(Index: Integer): Integer;
begin
  if Kind(Index) <> tlData then
    Result := -1
  else if Grouped then
    Result := FOutline[Index].Row
  else
    Result := Index;
end;

function TPPGTableLines.Level(Index: Integer): Integer;
begin
  if Grouped and (Index < Length(FOutline)) then
    Result := FOutline[Index].Level
  else
    Result := 0;
end;

function TPPGTableLines.Text(Index: Integer): string;
begin
  if Grouped and (Index < Length(FOutline)) then
    Result := FOutline[Index].Text
  else
    Result := '';
end;

function TPPGTableLines.Alternate(Index: Integer): Boolean;
begin
  Result := Odd(Index);
end;

{ Funktionen }

function PPGTableHasFooter(const Look: IPPGTableLook; ColCount: Integer): Boolean;
var
  C: Integer;
begin
  Result := False;
  if Look <> nil then
    for C := 0 to ColCount - 1 do
      if Look.ExportFooterText(C) <> '' then
        Exit(True);
end;

function PPGTableBandLevels(const Bands: TArray<TPPGTableBand>): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(Bands) do
    Result := Max(Result, Bands[I].Level + 1);
end;

function PPGTableBandAt(const Bands: TArray<TPPGTableBand>; Level, ACol: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to High(Bands) do
    if (Bands[I].Level = Level) and (ACol >= Bands[I].ColFirst) and (ACol <= Bands[I].ColLast) then
      Exit(I);
  Result := -1;
end;

function PPGValueChecked(const V: Variant): Boolean;
begin
  if VarType(V) = varBoolean then
    Result := Boolean(V)
  else if VarIsNumeric(V) then
    Result := Double(V) <> 0
  else
    Result := TPPGCellPainter.IsCheckedText(VarToStr(V));
end;

function PPGCheckGlyph(Checked: Boolean): string;
begin
  if Checked then
    Result := #$2611
  else
    Result := #$2610;
end;

function PPGRatingStars(MaxValue: Integer): Integer;
begin
  Result := MaxValue;
  if Result <= 0 then
    Result := 5;
  if Result > 20 then
    Result := 20;
end;

function PPGStarsText(Value, Count: Integer): string;
begin
  Value := Max(0, Min(Value, Count));
  Result := StringOfChar(#$2605, Value) + StringOfChar(#$2606, Count - Value);
end;

function PPGResolveCellLook(const Look: TPPGTableLook;
  const Cs: TPPGGridCellStyle): TPPGGridCellStyle;
begin
  Result := Cs;
  if Result.Fill = clNone then
    Result.Fill := Look.Fill;
  if Result.TextColor = clNone then
    Result.TextColor := Look.Text;
  if Result.Bold then
    Include(Result.FontStyle, fsBold);
  if Result.FontName = '' then
    Result.FontName := Look.FontName;
  if Result.FontSize <= 0 then
    Result.FontSize := Look.FontSize;
end;

function PPGProgressFraction(const V: Variant; MinValue, MaxValue: Integer): Double;
var
  Lo, Hi, D: Double;
begin
  Lo := MinValue;
  Hi := MaxValue;
  if Hi <= Lo then
  begin
    Lo := 0;
    Hi := 100;
  end;
  if VarIsNumeric(V) then
    D := Double(V)
  else if not TryStrToFloat(VarToStr(V), D) then
    D := Lo;
  Result := (D - Lo) / (Hi - Lo);
  if Result < 0 then
    Result := 0;
  if Result > 1 then
    Result := 1;
end;

end.
