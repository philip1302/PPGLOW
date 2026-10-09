unit PPG.Grid.View;

{ Ansicht des Grids als Kette (Phase 13a): Datenzeilen -> Filter ->
  Sortieren -> Gruppieren (13c) -> sichtbare Zeilen.

  - Jede Stufe ist ein Objekt hinter IPPGGridViewStage (Strategy, OCP): neue
    Stufen kommen hinzu, ohne die anderen zu aendern.
  - Die Stufen arbeiten auf einem Index-Array (Datenzeilen), nie auf den
    Daten. Was "passt" und wie verglichen wird, fragen sie beim Host
    (IPPGGridViewHost: Grid, DB-Grid, Tests).
  - Ohne aktive Stufe ist die Ansicht die Identitaet (kein Array, O(1)).
  - Begriffe: "Datenzeile" = Index in den Daten (Cells[], OnGetCellText),
    "Ansichtszeile" = Position in der Ansicht (0-basiert, ohne feste Zeilen).
  - Gruppieren (13c): die Gruppen-Stufe ordnet die Zeilen nach den Werten der
    Gruppenspalten (Hash statt Vergleich: O(n), die Reihenfolge innerhalb der
    Gruppe bleibt die der Sortierung) und legt einen Gruppenbaum an. Die
    Ansicht enthaelt dann auch Gruppenkopf- und Gruppenfuss-Eintraege
    (negative Werte, siehe PPGGridEntry*). Auf- und Zuklappen baut nur die
    flache Liste neu auf (O(n), kein Vergleich, kein Neugruppieren). }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections;

type
  IPPGGridViewHost = interface
    ['{91C4E2B7-0A63-4D58-8F2E-6B3D1C9A7E04}']
    /// Passt die Datenzeile zum Filter?
    function ViewRowPasses(ARow: Integer): Boolean;
    /// Vergleich zweier Datenzeilen in einer Spalte (<0, 0, >0).
    function ViewCompareRows(ACol, R1, R2: Integer): Integer;
    /// Gruppenschluessel einer Zelle (Standard: angezeigter Text).
    function ViewGroupKey(ACol, ARow: Integer): string;
  end;

  /// Vorberechneter Sortierschluessel einer Zelle (Audit 8c #1): Text und,
  /// falls der Text eine Zahl ist, ihr Wert.
  TPPGGridSortKey = record
    Text: string;
    Num: Double;
    IsNum: Boolean;
  end;

  /// Optional am Host: Schluessel einmal je Zeile statt Text je Vergleich.
  /// Der Vergleich ist PPGGridCompareSortKeys (gleich der Standardlogik des
  /// Grids). False = der Host vergleicht selbst (OnCompareCells u.ae.).
  IPPGGridViewSortKeys = interface
    ['{0B6E2F43-8C1D-4A57-9E3B-5D7A1C64F820}']
    function ViewSortKeys(ACol: Integer; const Rows: TArray<Integer>;
      out Keys: TArray<TPPGGridSortKey>): Boolean;
  end;

  /// Optional am Host: Schluessel fuer das Filterergebnis (Audit 8c #7).
  /// Gleicher Schluessel = gleiches Ergebnis (Filtertexte und Datenstand);
  /// '' = nicht zwischenspeichern (z.B. virtuelle Daten).
  IPPGGridViewFilterKey = interface
    ['{7F3C9A12-6B4E-4D81-A2C5-E81B0D3F6A97}']
    function ViewFilterKey: string;
  end;

  IPPGGridViewStage = interface
    ['{5D2F8A61-C3B7-4E09-A14D-7E6F0B2C9D38}']
    function StageActive: Boolean;
    /// Rows = Datenzeilen in Ansichtsreihenfolge; die Stufe filtert bzw.
    /// ordnet sie neu (Laenge darf sich aendern).
    procedure StageApply(var Rows: TArray<Integer>; const Host: IPPGGridViewHost);
  end;

  /// Filter (Audit 8c #7: das Ergebnis wird mit dem Schluessel des Hosts
  /// zwischengespeichert; reines Umsortieren filtert nicht erneut).
  TPPGGridFilterStage = class(TInterfacedObject, IPPGGridViewStage)
  private
    FActive: Boolean;
    FCacheKey: string;
    FCacheRows: TArray<Integer>;
  public
    function StageActive: Boolean;
    procedure StageApply(var Rows: TArray<Integer>; const Host: IPPGGridViewHost);
    /// Zwischengespeichertes Ergebnis verwerfen.
    procedure ClearCache;
    property Active: Boolean read FActive write FActive;
  end;

  /// Stabile Sortierung (Mergesort): gleiche Werte behalten ihre Reihenfolge.
  TPPGGridSortStage = class(TInterfacedObject, IPPGGridViewStage)
  private
    FColumn: Integer;
    FAscending: Boolean;
  public
    constructor Create;
    function StageActive: Boolean;
    procedure StageApply(var Rows: TArray<Integer>; const Host: IPPGGridViewHost);
    /// -1 = nicht sortiert.
    property Column: Integer read FColumn write FColumn;
    property Ascending: Boolean read FAscending write FAscending;
  end;

  TPPGGridGroup = record
    Level: Integer;
    Column: Integer;     // Datenspalte der Ebene
    Key: string;
    KeyRow: Integer;     // erste Datenzeile (Vertreter fuer Vergleich und Text)
    First: Integer;      // Bereich in Grouped (alle Datenzeilen darunter)
    Count: Integer;
    Parent: Integer;     // -1 = oberste Ebene
    FirstChild: Integer; // -1 = unterste Ebene (darunter Datenzeilen)
    Next: Integer;       // naechste Gruppe mit demselben Elternteil, -1 = keine
    Expanded: Boolean;
  end;

  TPPGGridGroupStage = class(TInterfacedObject, IPPGGridViewStage)
  private
    FColumns: TArray<Integer>;
    FSortColumn: Integer;
    FSortAscending: Boolean;
    FFooters: Boolean;
    FGroups: TArray<TPPGGridGroup>;
    FCount: Integer;
    FGrouped: TArray<Integer>;
    FHeaderAt: TArray<Integer>;
    FFooterAt: TArray<Integer>;
    FDefaultExpanded: Boolean;
    FToggled: TDictionary<string, Boolean>; // Pfade mit Abweichung von FDefaultExpanded
    procedure Build(const Host: IPPGGridViewHost; Level, AFirst, ACount, AParent: Integer;
      Dict: TDictionary<string, Integer>);
    function GetGroup(Index: Integer): TPPGGridGroup;
  public
    constructor Create;
    destructor Destroy; override;
    function StageActive: Boolean;
    procedure StageApply(var Rows: TArray<Integer>; const Host: IPPGGridViewHost);
    /// Flache Liste aus Gruppenbaum und Auf-/Zuklapp-Zustand.
    procedure Flatten(var Rows: TArray<Integer>);
    /// Pfad einer Gruppe (Schluessel der Ebenen) - bleibt ueber Neuaufbau gleich.
    function PathOf(Index: Integer): string;
    procedure SetExpanded(Index: Integer; Value: Boolean);
    procedure ExpandAll(Value: Boolean);
    /// Gruppenspalten (Datenspalten, Ebene 0 zuerst).
    property Columns: TArray<Integer> read FColumns write FColumns;
    /// Sortierung der Ansicht: gilt fuer die Gruppenreihenfolge, wenn die
    /// sortierte Spalte eine Gruppenspalte ist (sonst aufsteigend).
    property SortColumn: Integer read FSortColumn write FSortColumn;
    property SortAscending: Boolean read FSortAscending write FSortAscending;
    /// Gruppenfuss-Zeilen (Summen je Gruppe) erzeugen.
    property Footers: Boolean read FFooters write FFooters;
    property Count: Integer read FCount;
    property Groups[Index: Integer]: TPPGGridGroup read GetGroup;
    /// Alle Datenzeilen in Gruppenreihenfolge (auch zugeklappte).
    property Grouped: TArray<Integer> read FGrouped;
    /// Ansichtsindex des Gruppenkopfs (-1 = in zugeklappter Gruppe).
    property HeaderAt: TArray<Integer> read FHeaderAt;
    /// Ansichtsindex des Gruppenfusses (-1 = keiner sichtbar).
    property FooterAt: TArray<Integer> read FFooterAt;
  end;

  TPPGGridView = class
  private
    FStageRefs: array of IPPGGridViewStage;
    FFilter: TPPGGridFilterStage;
    FSort: TPPGGridSortStage;
    FGroup: TPPGGridGroupStage;
    FMapped: Boolean;
    FRows: TArray<Integer>;  // Ansichtszeile -> Datenzeile bzw. Gruppen-Eintrag
    FInv: TArray<Integer>;   // Datenzeile -> Ansichtszeile (-1 = nicht sichtbar)
    FFirst: Integer;
    FEnd: Integer;
    procedure BuildInverse;
  public
    constructor Create;
    destructor Destroy; override;
    /// Weitere Stufe hinten anhaengen.
    procedure AddStage(const Stage: IPPGGridViewStage);
    /// Neu aufbauen fuer die Datenzeilen First..EndRow-1.
    procedure Rebuild(const Host: IPPGGridViewHost; First, EndRow: Integer);
    /// Nach Auf-/Zuklappen: nur die flache Liste neu (ohne Neugruppieren).
    procedure Reflatten;
    /// Anzahl Ansichtszeilen (inkl. Gruppenzeilen).
    function Count: Integer;
    /// Datenzeile bzw. Gruppen-Eintrag (<= -2) einer Ansichtszeile; -1 = ausserhalb.
    function DataRowOf(ViewIndex: Integer): Integer;
    /// Ansichtszeile einer Datenzeile; -1 = herausgefiltert/zugeklappt/ausserhalb.
    function ViewIndexOf(ARow: Integer): Integer;
    /// Alle Datenzeilen der Ansicht (gefiltert, sortiert, gruppiert; auch
    /// zugeklappte) - Grundlage fuer Summen und Export.
    function AllRowCount: Integer;
    function AllRow(Index: Integer): Integer;
    function Grouped: Boolean;
    /// True, wenn eine Stufe aktiv ist (sonst Identitaet).
    property Mapped: Boolean read FMapped;
    property Filter: TPPGGridFilterStage read FFilter;
    property Sort: TPPGGridSortStage read FSort;
    property Group: TPPGGridGroupStage read FGroup;
  end;

/// Vergleich zweier Sortierschluessel: beide Zahlen numerisch, sonst
/// AnsiCompareText (wie TPPGCustomGrid.CompareDataRows; nicht transitiv bei
/// gemischten Spalten - bewusst unveraendert).
function PPGGridCompareSortKeys(const A, B: TPPGGridSortKey): Integer;

/// Gruppen-Eintraege in der Ansicht: Kopf = -(2*G+2), Fuss = -(2*G+3).
function PPGGridEntryIsGroup(Entry: Integer): Boolean; inline;
function PPGGridEntryGroup(Entry: Integer): Integer; inline;
function PPGGridEntryIsFooter(Entry: Integer): Boolean; inline;

implementation

function PPGGridCompareSortKeys(const A, B: TPPGGridSortKey): Integer;
begin
  if A.IsNum and B.IsNum then
  begin
    if A.Num < B.Num then
      Result := -1
    else if A.Num > B.Num then
      Result := 1
    else
      Result := 0;
  end
  else
    Result := AnsiCompareText(A.Text, B.Text);
end;

function PPGGridEntryIsGroup(Entry: Integer): Boolean;
begin
  Result := Entry <= -2;
end;

function PPGGridEntryGroup(Entry: Integer): Integer;
begin
  Result := (-Entry - 2) div 2;
end;

function PPGGridEntryIsFooter(Entry: Integer): Boolean;
begin
  Result := (Entry <= -2) and Odd(-Entry - 2);
end;

{ TPPGGridFilterStage }

function TPPGGridFilterStage.StageActive: Boolean;
begin
  Result := FActive;
end;

procedure TPPGGridFilterStage.StageApply(var Rows: TArray<Integer>; const Host: IPPGGridViewHost);
var
  I, N: Integer;
  FK: IPPGGridViewFilterKey;
  Key: string;
begin
  // Gleicher Schluessel (Filter, Datenstand) und gleiche Eingabe: Ergebnis
  // wiederverwenden
  Key := '';
  if Supports(Host, IPPGGridViewFilterKey, FK) then
    Key := FK.ViewFilterKey;
  if Key <> '' then
  begin
    Key := Key + '#' + IntToStr(Length(Rows));
    if Length(Rows) > 0 then
      Key := Key + '#' + IntToStr(Rows[0]) + '#' + IntToStr(Rows[High(Rows)]);
    if Key = FCacheKey then
    begin
      Rows := Copy(FCacheRows);
      Exit;
    end;
  end;
  N := 0;
  for I := 0 to High(Rows) do
    if Host.ViewRowPasses(Rows[I]) then
    begin
      Rows[N] := Rows[I];
      Inc(N);
    end;
  SetLength(Rows, N);
  FCacheKey := Key;
  if Key <> '' then
    FCacheRows := Copy(Rows)
  else
    FCacheRows := nil;
end;

procedure TPPGGridFilterStage.ClearCache;
begin
  FCacheKey := '';
  FCacheRows := nil;
end;

{ TPPGGridSortStage }

constructor TPPGGridSortStage.Create;
begin
  inherited Create;
  FColumn := -1;
  FAscending := True;
end;

function TPPGGridSortStage.StageActive: Boolean;
begin
  Result := FColumn >= 0;
end;

procedure TPPGGridSortStage.StageApply(var Rows: TArray<Integer>; const Host: IPPGGridViewHost);
var
  Tmp, A: TArray<Integer>;
  Keys: TArray<TPPGGridSortKey>;
  KH: IPPGGridViewSortKeys;
  Col, I: Integer;
  Asc, ByKey: Boolean;

  // A = Datenzeilen (Host vergleicht) bzw. Positionen in Keys (Schluessel).
  // Gleicher Mergesort in beiden Faellen: gleiche Reihenfolge, auch wenn der
  // Vergleich bei gemischten Spalten nicht transitiv ist.
  procedure MergeSort(L, R: Integer);
  var
    M, I1, I2, K, C: Integer;
  begin
    if R - L < 1 then
      Exit;
    M := (L + R) div 2;
    MergeSort(L, M);
    MergeSort(M + 1, R);
    I1 := L;
    I2 := M + 1;
    K := L;
    while (I1 <= M) and (I2 <= R) do
    begin
      if ByKey then
        C := PPGGridCompareSortKeys(Keys[A[I1]], Keys[A[I2]])
      else
        C := Host.ViewCompareRows(Col, A[I1], A[I2]);
      if not Asc then
        C := -C;
      // stabil: bei Gleichheit links zuerst
      if C <= 0 then
      begin
        Tmp[K] := A[I1];
        Inc(I1);
      end
      else
      begin
        Tmp[K] := A[I2];
        Inc(I2);
      end;
      Inc(K);
    end;
    while I1 <= M do
    begin
      Tmp[K] := A[I1];
      Inc(I1);
      Inc(K);
    end;
    while I2 <= R do
    begin
      Tmp[K] := A[I2];
      Inc(I2);
      Inc(K);
    end;
    Move(Tmp[L], A[L], (R - L + 1) * SizeOf(Integer));
  end;

begin
  if Length(Rows) < 2 then
    Exit;
  Col := FColumn;
  Asc := FAscending;
  SetLength(Tmp, Length(Rows));
  // Audit 8c #1: Schluessel einmal je Zeile (Text lesen, Zahl erkennen)
  // statt bei jedem Vergleich
  ByKey := Supports(Host, IPPGGridViewSortKeys, KH) and KH.ViewSortKeys(Col, Rows, Keys) and
    (Length(Keys) = Length(Rows));
  if ByKey then
  begin
    SetLength(A, Length(Rows));
    for I := 0 to High(A) do
      A[I] := I;
    MergeSort(0, High(A));
    Tmp := Copy(Rows);
    for I := 0 to High(A) do
      Rows[I] := Tmp[A[I]];
  end
  else
  begin
    A := Rows;
    MergeSort(0, High(A));
    Rows := A;
  end;
end;

{ TPPGGridGroupStage }

constructor TPPGGridGroupStage.Create;
begin
  inherited Create;
  FSortColumn := -1;
  FSortAscending := True;
  FDefaultExpanded := True;
  FToggled := TDictionary<string, Boolean>.Create;
end;

destructor TPPGGridGroupStage.Destroy;
begin
  FreeAndNil(FToggled);
  inherited Destroy;
end;

function TPPGGridGroupStage.StageActive: Boolean;
begin
  Result := Length(FColumns) > 0;
end;

function TPPGGridGroupStage.GetGroup(Index: Integer): TPPGGridGroup;
begin
  Result := FGroups[Index];
end;

function TPPGGridGroupStage.PathOf(Index: Integer): string;
begin
  // Schluessel von oben nach unten, getrennt durch #1 (kommt in Text kaum vor)
  Result := FGroups[Index].Key;
  Index := FGroups[Index].Parent;
  while Index >= 0 do
  begin
    Result := FGroups[Index].Key + #1 + Result;
    Index := FGroups[Index].Parent;
  end;
end;

procedure TPPGGridGroupStage.Build(const Host: IPPGGridViewHost;
  Level, AFirst, ACount, AParent: Integer; Dict: TDictionary<string, Integer>);
var
  Col, I, Id, NG, P, G, Prev, C: Integer;
  K: string;
  RowGroup, Rep, Sizes, Order, Rank, Start, Tmp, Buf: TArray<Integer>;
  Keys: TArray<string>;
  Asc: Boolean;

  procedure SortOrder(L, R: Integer);
  var
    M, I1, I2, J, Cmp: Integer;
  begin
    // Mergesort der Gruppen ueber ihre Vertreter (stabil: erste Fundstelle zuerst)
    if R - L < 1 then
      Exit;
    M := (L + R) div 2;
    SortOrder(L, M);
    SortOrder(M + 1, R);
    I1 := L;
    I2 := M + 1;
    J := L;
    while (I1 <= M) and (I2 <= R) do
    begin
      Cmp := Host.ViewCompareRows(Col, Rep[Order[I1]], Rep[Order[I2]]);
      if not Asc then
        Cmp := -Cmp;
      if Cmp <= 0 then
      begin
        Buf[J] := Order[I1];
        Inc(I1);
      end
      else
      begin
        Buf[J] := Order[I2];
        Inc(I2);
      end;
      Inc(J);
    end;
    while I1 <= M do
    begin
      Buf[J] := Order[I1];
      Inc(I1);
      Inc(J);
    end;
    while I2 <= R do
    begin
      Buf[J] := Order[I2];
      Inc(I2);
      Inc(J);
    end;
    for J := L to R do
      Order[J] := Buf[J];
  end;

begin
  if ACount = 0 then
    Exit;
  Col := FColumns[Level];
  Asc := (Col <> FSortColumn) or FSortAscending;
  // 1. Schluessel je Zeile -> Gruppen-Nummer (Hash, O(n))
  Dict.Clear;
  SetLength(RowGroup, ACount);
  NG := 0;
  for I := 0 to ACount - 1 do
  begin
    K := Host.ViewGroupKey(Col, FGrouped[AFirst + I]);
    if not Dict.TryGetValue(K, Id) then
    begin
      Id := NG;
      Dict.Add(K, Id);
      if NG >= Length(Rep) then
      begin
        SetLength(Rep, NG * 2 + 8);
        SetLength(Keys, NG * 2 + 8);
        SetLength(Sizes, NG * 2 + 8);
      end;
      Rep[NG] := FGrouped[AFirst + I];
      Keys[NG] := K;
      Sizes[NG] := 0;
      Inc(NG);
    end;
    RowGroup[I] := Id;
    Inc(Sizes[Id]);
  end;
  // 2. Gruppen ordnen (nur die Vertreter vergleichen)
  SetLength(Order, NG);
  SetLength(Buf, NG);
  for I := 0 to NG - 1 do
    Order[I] := I;
  SortOrder(0, NG - 1);
  SetLength(Rank, NG);
  SetLength(Start, NG);
  P := 0;
  for I := 0 to NG - 1 do
  begin
    Rank[Order[I]] := I;
    Start[I] := P;
    Inc(P, Sizes[Order[I]]);
  end;
  // 3. Zeilen stabil nach Gruppen verteilen (Counting Sort)
  SetLength(Tmp, ACount);
  for I := 0 to ACount - 1 do
  begin
    P := Rank[RowGroup[I]];
    Tmp[Start[P]] := FGrouped[AFirst + I];
    Inc(Start[P]);
  end;
  for I := 0 to ACount - 1 do
    FGrouped[AFirst + I] := Tmp[I];
  RowGroup := nil;
  Tmp := nil;
  // 4. Gruppen anlegen (Vorordnung: Gruppe, dann ihre Untergruppen)
  P := AFirst;
  Prev := -1;
  for I := 0 to NG - 1 do
  begin
    C := Order[I];
    if FCount >= Length(FGroups) then
      SetLength(FGroups, FCount * 2 + 16);
    G := FCount;
    Inc(FCount);
    FGroups[G].Level := Level;
    FGroups[G].Column := Col;
    FGroups[G].Key := Keys[C];
    FGroups[G].KeyRow := Rep[C];
    FGroups[G].First := P;
    FGroups[G].Count := Sizes[C];
    FGroups[G].Parent := AParent;
    FGroups[G].FirstChild := -1;
    FGroups[G].Next := -1;
    if FToggled.Count = 0 then
      FGroups[G].Expanded := FDefaultExpanded
    else
      FGroups[G].Expanded := FDefaultExpanded xor FToggled.ContainsKey(PathOf(G));
    if Prev >= 0 then
      FGroups[Prev].Next := G
    else if AParent >= 0 then
      FGroups[AParent].FirstChild := G;
    Prev := G;
    Inc(P, Sizes[C]);
    if Level < High(FColumns) then
      Build(Host, Level + 1, FGroups[G].First, FGroups[G].Count, G, Dict);
  end;
end;

procedure TPPGGridGroupStage.StageApply(var Rows: TArray<Integer>; const Host: IPPGGridViewHost);
var
  Dict: TDictionary<string, Integer>;
begin
  FGrouped := Copy(Rows);
  FCount := 0;
  FGroups := nil;
  Dict := TDictionary<string, Integer>.Create;
  try
    Build(Host, 0, 0, Length(FGrouped), -1, Dict);
  finally
    Dict.Free;
  end;
  SetLength(FGroups, FCount);
  Flatten(Rows);
end;

procedure TPPGGridGroupStage.Flatten(var Rows: TArray<Integer>);
var
  N, I, G: Integer;

  procedure Emit(AG: Integer);
  var
    C, J: Integer;
  begin
    Rows[N] := -(2 * AG + 2);
    FHeaderAt[AG] := N;
    Inc(N);
    if not FGroups[AG].Expanded then
      Exit;
    if FGroups[AG].FirstChild >= 0 then
    begin
      C := FGroups[AG].FirstChild;
      while C >= 0 do
      begin
        Emit(C);
        C := FGroups[C].Next;
      end;
    end
    else
      for J := FGroups[AG].First to FGroups[AG].First + FGroups[AG].Count - 1 do
      begin
        Rows[N] := FGrouped[J];
        Inc(N);
      end;
    if FFooters then
    begin
      Rows[N] := -(2 * AG + 3);
      FFooterAt[AG] := N;
      Inc(N);
    end;
  end;

begin
  SetLength(Rows, Length(FGrouped) + FCount * 2);
  SetLength(FHeaderAt, FCount);
  SetLength(FFooterAt, FCount);
  for I := 0 to FCount - 1 do
  begin
    FHeaderAt[I] := -1;
    FFooterAt[I] := -1;
  end;
  N := 0;
  // Oberste Ebene: Gruppe 0 und ihre Geschwister
  if FCount > 0 then
  begin
    G := 0;
    while G >= 0 do
    begin
      Emit(G);
      G := FGroups[G].Next;
    end;
  end;
  SetLength(Rows, N);
end;

procedure TPPGGridGroupStage.SetExpanded(Index: Integer; Value: Boolean);
var
  P: string;
begin
  if (Index < 0) or (Index >= FCount) or (FGroups[Index].Expanded = Value) then
    Exit;
  FGroups[Index].Expanded := Value;
  P := PathOf(Index);
  if Value = FDefaultExpanded then
    FToggled.Remove(P)
  else
    FToggled.AddOrSetValue(P, True);
end;

procedure TPPGGridGroupStage.ExpandAll(Value: Boolean);
var
  I: Integer;
begin
  FDefaultExpanded := Value;
  FToggled.Clear;
  for I := 0 to FCount - 1 do
    FGroups[I].Expanded := Value;
end;

{ TPPGGridView }

constructor TPPGGridView.Create;
begin
  inherited Create;
  FFilter := TPPGGridFilterStage.Create;
  FSort := TPPGGridSortStage.Create;
  FGroup := TPPGGridGroupStage.Create;
  AddStage(FFilter);
  AddStage(FSort);
  AddStage(FGroup);
end;

destructor TPPGGridView.Destroy;
begin
  // Die Stufen leben ueber ihre Interface-Referenzen
  FStageRefs := nil;
  inherited Destroy;
end;

procedure TPPGGridView.AddStage(const Stage: IPPGGridViewStage);
var
  N: Integer;
begin
  N := Length(FStageRefs);
  SetLength(FStageRefs, N + 1);
  FStageRefs[N] := Stage;
end;

procedure TPPGGridView.BuildInverse;
var
  I: Integer;
begin
  SetLength(FInv, FEnd);
  for I := 0 to FEnd - 1 do
    FInv[I] := -1;
  for I := 0 to High(FRows) do
    if (FRows[I] >= 0) and (FRows[I] < FEnd) then
      FInv[FRows[I]] := I;
end;

procedure TPPGGridView.Rebuild(const Host: IPPGGridViewHost; First, EndRow: Integer);
var
  I: Integer;
begin
  FFirst := First;
  FEnd := EndRow;
  FMapped := False;
  if not FFilter.Active then
    FFilter.ClearCache;
  for I := 0 to High(FStageRefs) do
    if FStageRefs[I].StageActive then
      FMapped := True;
  if not FMapped then
  begin
    FRows := nil;
    FInv := nil;
    Exit;
  end;
  SetLength(FRows, EndRow - First);
  for I := 0 to High(FRows) do
    FRows[I] := First + I;
  for I := 0 to High(FStageRefs) do
    if FStageRefs[I].StageActive then
      FStageRefs[I].StageApply(FRows, Host);
  BuildInverse;
end;

procedure TPPGGridView.Reflatten;
begin
  if not Grouped then
    Exit;
  FGroup.Flatten(FRows);
  BuildInverse;
end;

function TPPGGridView.Count: Integer;
begin
  if FMapped then
    Result := Length(FRows)
  else
    Result := FEnd - FFirst;
  if Result < 0 then
    Result := 0;
end;

function TPPGGridView.DataRowOf(ViewIndex: Integer): Integer;
begin
  if FMapped then
  begin
    if (ViewIndex >= 0) and (ViewIndex < Length(FRows)) then
      Result := FRows[ViewIndex]
    else
      Result := -1;
  end
  else if (ViewIndex >= 0) and (ViewIndex < FEnd - FFirst) then
    Result := FFirst + ViewIndex
  else
    Result := -1;
end;

function TPPGGridView.ViewIndexOf(ARow: Integer): Integer;
begin
  if (ARow < FFirst) or (ARow >= FEnd) then
    Result := -1
  else if FMapped then
  begin
    if ARow < Length(FInv) then
      Result := FInv[ARow]
    else
      Result := -1;
  end
  else
    Result := ARow - FFirst;
end;

function TPPGGridView.Grouped: Boolean;
begin
  Result := FMapped and FGroup.StageActive;
end;

function TPPGGridView.AllRowCount: Integer;
begin
  if Grouped then
    Result := Length(FGroup.Grouped)
  else
    Result := Count;
end;

function TPPGGridView.AllRow(Index: Integer): Integer;
begin
  if Grouped then
    Result := FGroup.Grouped[Index]
  else
    Result := DataRowOf(Index);
end;

end.
