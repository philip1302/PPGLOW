unit PPG.Planner.Layout;

{ Anordnung von Terminen (Phase 14a), ohne VCL - reine Funktionen.

  - PPGLayoutColumns (Tages-/Wochenansicht): sich ueberschneidende Termine
    bilden Gruppen; in jeder Gruppe bekommt ein Termin gierig die erste freie
    Spalte. Alle Termine einer Gruppe teilen sich die Breite (ColumnCount);
    ColSpan nutzt freie Spalten rechts daneben (wie Outlook).
  - PPGLayoutRows (ganztaegige Termine, Monatsansicht, Zeitleiste): Zeile je
    Termin, gierig von oben.
  - Termine ohne Dauer zaehlen mit MinDuration (sonst "ueberlappen" sie nie). }

{$I ..\PPG.inc}

interface

type
  TPPGSpan = record
    Start, Finish: TDateTime;
  end;

  TPPGSpanSlot = record
    Column: Integer;       // 0-basiert
    ColumnCount: Integer;  // Spalten der Gruppe
    ColSpan: Integer;      // belegte Spalten (>= 1)
  end;

function PPGSpan(AStart, AFinish: TDateTime): TPPGSpan;
/// Spalten fuer ueberlappende Termine (Ergebnis in der Reihenfolge von Spans).
function PPGLayoutColumns(const Spans: array of TPPGSpan;
  MinDuration: TDateTime = 1 / 24 / 60 * 15): TArray<TPPGSpanSlot>;
/// Zeilen (0-basiert) fuer Baender; RowCount = Anzahl Zeilen.
function PPGLayoutRows(const Spans: array of TPPGSpan; out RowCount: Integer;
  MinDuration: TDateTime = 1 / 24 / 60): TArray<Integer>;

implementation

uses
  System.Generics.Collections, System.Generics.Defaults;

function PPGSpan(AStart, AFinish: TDateTime): TPPGSpan;
begin
  Result.Start := AStart;
  Result.Finish := AFinish;
end;

function SortedOrder(const Spans: array of TPPGSpan; MinDuration: TDateTime;
  out Fin: TArray<TDateTime>): TArray<Integer>;
var
  I: Integer;
  Ends: TArray<TDateTime>;
  Starts: TArray<TDateTime>;
begin
  SetLength(Result, Length(Spans));
  SetLength(Fin, Length(Spans));
  SetLength(Starts, Length(Spans));
  for I := 0 to High(Spans) do
  begin
    Result[I] := I;
    Starts[I] := Spans[I].Start;
    Fin[I] := Spans[I].Finish;
    if Fin[I] < Spans[I].Start + MinDuration then
      Fin[I] := Spans[I].Start + MinDuration;
  end;
  Ends := Fin;
  // Beginn aufsteigend, bei Gleichstand die laengeren zuerst, dann Eingabe
  TArray.Sort<Integer>(Result, TComparer<Integer>.Construct(
    function(const A, B: Integer): Integer
    begin
      if Starts[A] < Starts[B] then
        Result := -1
      else if Starts[A] > Starts[B] then
        Result := 1
      else if Ends[A] > Ends[B] then
        Result := -1
      else if Ends[A] < Ends[B] then
        Result := 1
      else
        Result := A - B;
    end));
end;

function PPGLayoutColumns(const Spans: array of TPPGSpan;
  MinDuration: TDateTime): TArray<TPPGSpanSlot>;
var
  Order: TArray<Integer>;
  Fin: TArray<TDateTime>;
  ColEnds: TList<TDateTime>;
  Group: TList<Integer>;
  I, J, C, Idx, Cols: Integer;
  GroupEnd: TDateTime;

  procedure CloseGroup;
  var
    G, H, X, Col2: Integer;
  begin
    // Spaltenzahl der Gruppe eintragen, dann nach rechts ausdehnen
    for G := 0 to Group.Count - 1 do
      Result[Group[G]].ColumnCount := Cols;
    for G := 0 to Group.Count - 1 do
    begin
      X := Group[G];
      Col2 := Result[X].Column + 1;
      while Col2 < Cols do
      begin
        for H := 0 to Group.Count - 1 do
          if (Result[Group[H]].Column = Col2) and
            (Spans[Group[H]].Start < Fin[X]) and (Fin[Group[H]] > Spans[X].Start) then
          begin
            Col2 := Cols + 1; // belegt: nicht weiter
            Break;
          end;
        if Col2 > Cols then
          Break;
        Inc(Result[X].ColSpan);
        Inc(Col2);
      end;
    end;
    Group.Clear;
    ColEnds.Clear;
    Cols := 0;
  end;

begin
  SetLength(Result, Length(Spans));
  if Length(Spans) = 0 then
    Exit;
  Order := SortedOrder(Spans, MinDuration, Fin);
  ColEnds := TList<TDateTime>.Create;
  Group := TList<Integer>.Create;
  try
    Cols := 0;
    GroupEnd := 0;
    for I := 0 to High(Order) do
    begin
      Idx := Order[I];
      // Neue Gruppe, wenn der Termin nach allen bisherigen beginnt
      if (Group.Count > 0) and (Spans[Idx].Start >= GroupEnd) then
        CloseGroup;
      C := -1;
      for J := 0 to ColEnds.Count - 1 do
        if ColEnds[J] <= Spans[Idx].Start then
        begin
          C := J;
          Break;
        end;
      if C < 0 then
      begin
        C := ColEnds.Count;
        ColEnds.Add(Fin[Idx]);
        Inc(Cols);
      end
      else
        ColEnds[C] := Fin[Idx];
      Result[Idx].Column := C;
      Result[Idx].ColSpan := 1;
      Group.Add(Idx);
      if (Group.Count = 1) or (Fin[Idx] > GroupEnd) then
        GroupEnd := Fin[Idx];
    end;
    CloseGroup;
  finally
    Group.Free;
    ColEnds.Free;
  end;
end;

function PPGLayoutRows(const Spans: array of TPPGSpan; out RowCount: Integer;
  MinDuration: TDateTime): TArray<Integer>;
var
  Order: TArray<Integer>;
  Fin: TArray<TDateTime>;
  RowEnds: TList<TDateTime>;
  I, J, R, Idx: Integer;
begin
  SetLength(Result, Length(Spans));
  RowCount := 0;
  if Length(Spans) = 0 then
    Exit;
  Order := SortedOrder(Spans, MinDuration, Fin);
  RowEnds := TList<TDateTime>.Create;
  try
    for I := 0 to High(Order) do
    begin
      Idx := Order[I];
      R := -1;
      for J := 0 to RowEnds.Count - 1 do
        if RowEnds[J] <= Spans[Idx].Start then
        begin
          R := J;
          Break;
        end;
      if R < 0 then
      begin
        R := RowEnds.Count;
        RowEnds.Add(Fin[Idx]);
      end
      else
        RowEnds[R] := Fin[Idx];
      Result[Idx] := R;
    end;
    RowCount := RowEnds.Count;
  finally
    RowEnds.Free;
  end;
end;

end.
