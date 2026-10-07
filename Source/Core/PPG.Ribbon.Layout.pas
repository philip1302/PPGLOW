unit PPG.Ribbon.Layout;

{ Layout des Ribbons als reine Funktionen (Phase 14b), ohne VCL und ohne
  Fenster testbar.

  - PPGRibbonLayoutGroup legt die Zellen (Items) einer Gruppe in einem
    Zustand aus: grosse Items und Galerien als eigene Spalte ueber die volle
    Hoehe, kleine Items und eingebettete Controls in Stapeln zu Rows Zeilen.
  - PPGRibbonReduce schrumpft die Gruppen einer Registerkarte, bis sie in die
    verfuegbare Breite passen. Feste Reihenfolge: erst alle Gruppen auf
    "klein mit Text", dann "nur Symbol", dann "als Dropdown" - jeweils in der
    Reihenfolge von PPGRibbonReduceOrder (ReduceOrder aufsteigend, bei
    Gleichstand von rechts nach links). Ein Schritt, der die Gruppe nicht
    schmaler macht, wird uebersprungen.

  Alle Masse sind Pixel; die Breiten der Zellen misst das Control. }

{$I ..\PPG.inc}

interface

uses
  System.Types;

type
  /// Darstellung eines Items: gross (Symbol ueber Text), mittel (kleines
  /// Symbol mit Text), klein (nur Symbol).
  TPPGRibbonSize = (rsLarge, rsMedium, rsSmall);
  /// Zustand einer Gruppe beim Schrumpfen.
  TPPGRibbonGroupState = (rgsLarge, rgsMedium, rgsSmall, rgsCollapsed);

  TPPGRibbonCellKind = (rckButton, rckControl, rckGallery, rckSeparator);

  TPPGRibbonSizeWidths = array[TPPGRibbonSize] of Integer;

  /// Eine Zelle (sichtbares Item) fuer das Layout.
  TPPGRibbonCell = record
    Kind: TPPGRibbonCellKind;
    /// Gewuenschte Groesse im Zustand rgsLarge.
    MaxSize: TPPGRibbonSize;
    /// Kleinste erlaubte Groesse (rsLarge = schrumpft nie).
    MinSize: TPPGRibbonSize;
    /// Breite je Groesse. Galerie: rsLarge/rsMedium = Galerie in der Leiste
    /// (volle/verringerte Spaltenzahl), rsSmall = grosser Dropdown-Button.
    /// Control und Trenner: alle drei gleich.
    Width: TPPGRibbonSizeWidths;
    /// Beginnt einen neuen Stapel, auch wenn der vorige noch Platz hat.
    BeginColumn: Boolean;
    /// Steht rechts neben der vorigen Zelle in derselben Zeile (z.B. Fett,
    /// Kursiv, Unterstrichen nebeneinander).
    SameRow: Boolean;
  end;

  TPPGRibbonMetrics = record
    /// Oberkante der Item-Flaeche (relativ zur Gruppe).
    ContentTop: Integer;
    /// Hoehe einer Zeile eines Stapels.
    RowHeight: Integer;
    /// Zeilen je Stapel (Office: 3); die Item-Flaeche ist Rows * RowHeight hoch.
    Rows: Integer;
    /// Abstand zwischen Spalten.
    ColumnGap: Integer;
    /// Innenabstand links und rechts.
    Padding: Integer;
  end;

  TPPGRibbonPlace = record
    Size: TPPGRibbonSize;
    /// Relativ zur linken Kante der Gruppe; leer = nicht sichtbar.
    Bounds: TRect;
  end;
  TPPGRibbonPlaces = array of TPPGRibbonPlace;

  TPPGRibbonGroupWidths = array[TPPGRibbonGroupState] of Integer;
  TPPGRibbonGroupStates = array of TPPGRibbonGroupState;

/// Groesse einer Zelle im Zustand State (rgsCollapsed wie rgsSmall).
function PPGRibbonCellSize(const Cell: TPPGRibbonCell; State: TPPGRibbonGroupState): TPPGRibbonSize;
/// True, wenn die Zelle eine eigene Spalte ueber die volle Hoehe belegt.
function PPGRibbonCellIsColumn(const Cell: TPPGRibbonCell; Size: TPPGRibbonSize): Boolean;
/// Legt die Zellen aus und liefert die Breite der Gruppe (mindestens
/// MinWidth, z.B. die Beschriftung). Ist der Inhalt schmaler als MinWidth,
/// wird er mittig gesetzt. State = rgsCollapsed liefert leere Plaetze und
/// MinWidth.
function PPGRibbonLayoutGroup(const Cells: array of TPPGRibbonCell; State: TPPGRibbonGroupState;
  const M: TPPGRibbonMetrics; MinWidth: Integer; var Places: TPPGRibbonPlaces): Integer;
/// Reihenfolge des Schrumpfens: Indizes nach ReduceOrder aufsteigend, bei
/// Gleichstand der hoehere Index (weiter rechts) zuerst.
function PPGRibbonReduceOrder(const ReduceOrders: array of Integer): TArray<Integer>;
/// Gesamtbreite der Gruppen in den Zustaenden States, Gap zwischen je zwei.
function PPGRibbonTotalWidth(const Widths: array of TPPGRibbonGroupWidths;
  const States: TPPGRibbonGroupStates; Gap: Integer): Integer;
/// Zustaende der Gruppen, damit sie in Available passen (oder so schmal wie
/// moeglich sind). Order = Ergebnis von PPGRibbonReduceOrder.
function PPGRibbonReduce(const Widths: array of TPPGRibbonGroupWidths; const Order: array of Integer;
  Available, Gap: Integer): TPPGRibbonGroupStates;

implementation

function PPGRibbonCellSize(const Cell: TPPGRibbonCell; State: TPPGRibbonGroupState): TPPGRibbonSize;
var
  S: Integer;
begin
  if State = rgsCollapsed then
    State := rgsSmall;
  case Cell.Kind of
    rckControl, rckSeparator:
      Exit(Cell.MaxSize);
    rckGallery:
      S := Ord(State); // Galerie: Zustand direkt (gross/verringert/Dropdown)
  else
    // groesser als gewuenscht nie, kleiner als erlaubt nie
    if Ord(Cell.MaxSize) > Ord(State) then
      S := Ord(Cell.MaxSize)
    else
      S := Ord(State);
  end;
  if S > Ord(Cell.MinSize) then
    S := Ord(Cell.MinSize);
  Result := TPPGRibbonSize(S);
end;

function PPGRibbonCellIsColumn(const Cell: TPPGRibbonCell; Size: TPPGRibbonSize): Boolean;
begin
  case Cell.Kind of
    rckSeparator, rckGallery: Result := True;
    rckControl: Result := False;
  else
    Result := Size = rsLarge;
  end;
end;

function PPGRibbonLayoutGroup(const Cells: array of TPPGRibbonCell; State: TPPGRibbonGroupState;
  const M: TPPGRibbonMetrics; MinWidth: Integer; var Places: TPPGRibbonPlaces): Integer;
var
  I, X, ColW, Row, Rows, FullH, Shift, Total, RowRight: Integer;
  Size: TPPGRibbonSize;
  InStack, Any: Boolean;

  procedure CloseStack;
  begin
    if InStack then
    begin
      Inc(X, ColW + M.ColumnGap);
      InStack := False;
      ColW := 0;
      Row := 0;
    end;
  end;

begin
  SetLength(Places, Length(Cells));
  for I := 0 to High(Places) do
  begin
    Places[I].Size := rsSmall;
    Places[I].Bounds := Rect(0, 0, 0, 0);
  end;
  if State = rgsCollapsed then
    Exit(MinWidth);
  Rows := M.Rows;
  if Rows < 1 then
    Rows := 1;
  FullH := Rows * M.RowHeight;
  X := M.Padding;
  ColW := 0;
  Row := 0;
  RowRight := 0;
  InStack := False;
  Any := False;
  for I := 0 to High(Cells) do
  begin
    Size := PPGRibbonCellSize(Cells[I], State);
    Places[I].Size := Size;
    Any := True;
    if PPGRibbonCellIsColumn(Cells[I], Size) then
    begin
      CloseStack;
      Places[I].Bounds := Rect(X, M.ContentTop, X + Cells[I].Width[Size], M.ContentTop + FullH);
      Inc(X, Cells[I].Width[Size] + M.ColumnGap);
      Continue;
    end;
    // In derselben Zeile rechts neben der vorigen Zelle
    if InStack and Cells[I].SameRow and not Cells[I].BeginColumn and (Row > 0) then
    begin
      Places[I].Bounds := Rect(RowRight + M.ColumnGap, M.ContentTop + (Row - 1) * M.RowHeight,
        RowRight + M.ColumnGap + Cells[I].Width[Size], M.ContentTop + Row * M.RowHeight);
      RowRight := Places[I].Bounds.Right;
      if RowRight - X > ColW then
        ColW := RowRight - X;
      Continue;
    end;
    // Stapel: neue Spalte bei voller Spalte oder auf Wunsch
    if InStack and ((Row >= Rows) or Cells[I].BeginColumn) then
      CloseStack;
    InStack := True;
    Places[I].Bounds := Rect(X, M.ContentTop + Row * M.RowHeight, X + Cells[I].Width[Size],
      M.ContentTop + (Row + 1) * M.RowHeight);
    RowRight := Places[I].Bounds.Right;
    if Cells[I].Width[Size] > ColW then
      ColW := Cells[I].Width[Size];
    Inc(Row);
  end;
  CloseStack;
  if Any then
    Total := X - M.ColumnGap + M.Padding
  else
    Total := 0;
  if Total >= MinWidth then
    Exit(Total);
  // Schmaler als die Beschriftung: Inhalt mittig
  Shift := (MinWidth - Total) div 2;
  if Shift > 0 then
    for I := 0 to High(Places) do
      if not IsRectEmpty(Places[I].Bounds) then
        OffsetRect(Places[I].Bounds, Shift, 0);
  Result := MinWidth;
end;

function PPGRibbonReduceOrder(const ReduceOrders: array of Integer): TArray<Integer>;
var
  I, J, T: Integer;

  function Before(A, B: Integer): Boolean;
  begin
    if ReduceOrders[A] <> ReduceOrders[B] then
      Result := ReduceOrders[A] < ReduceOrders[B]
    else
      Result := A > B;
  end;

begin
  SetLength(Result, Length(ReduceOrders));
  for I := 0 to High(Result) do
    Result[I] := I;
  // Einfuegesortieren: wenige Gruppen, stabil
  for I := 1 to High(Result) do
  begin
    T := Result[I];
    J := I - 1;
    while (J >= 0) and Before(T, Result[J]) do
    begin
      Result[J + 1] := Result[J];
      Dec(J);
    end;
    Result[J + 1] := T;
  end;
end;

function PPGRibbonTotalWidth(const Widths: array of TPPGRibbonGroupWidths;
  const States: TPPGRibbonGroupStates; Gap: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(Widths) do
  begin
    Inc(Result, Widths[I][States[I]]);
    if I > 0 then
      Inc(Result, Gap);
  end;
end;

function PPGRibbonReduce(const Widths: array of TPPGRibbonGroupWidths; const Order: array of Integer;
  Available, Gap: Integer): TPPGRibbonGroupStates;
var
  I, G: Integer;
  Total: Integer;
  S: TPPGRibbonGroupState;
begin
  SetLength(Result, Length(Widths));
  for I := 0 to High(Result) do
    Result[I] := rgsLarge;
  Total := PPGRibbonTotalWidth(Widths, Result, Gap);
  for S := rgsMedium to rgsCollapsed do
    for I := 0 to High(Order) do
    begin
      if Total <= Available then
        Exit;
      G := Order[I];
      if (G < 0) or (G > High(Widths)) or (Ord(Result[G]) >= Ord(S)) then
        Continue;
      // Nur schrumpfen, wenn es Platz bringt
      if Widths[G][S] < Widths[G][Result[G]] then
      begin
        Dec(Total, Widths[G][Result[G]] - Widths[G][S]);
        Result[G] := S;
      end;
    end;
end;

end.
