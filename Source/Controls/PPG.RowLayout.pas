unit PPG.RowLayout;

{ TPPGRowLayout - Lage von Zeilen fuer virtuelle Listen (ListBox, Baum, Grid).

  - Feste Zeilenhoehe: RowTop/RowAt in O(1), kein Speicher pro Zeile.
  - Variable Hoehe (Audit 8c #5: duenn besetzt): gespeichert werden nur die
    Zeilen mit eigener Hoehe, sortiert nach Index, dazu die Praefixsummen
    ihrer Hoehen. RowTop und RowHeight per binaerer Suche ueber diese k
    Eintraege (O(log k)), RowAt ebenso. Eine eigene Hoehe in einer Liste mit
    1 000 000 Zeilen kostet damit keinen Speicher und keinen O(n)-Lauf mehr.
    Aufsteigend gesetzte Hoehen (der uebliche Aufbau) werden angehaengt.
  - Positionen sind Int64: 1 000 000 Zeilen x 30 px passen nicht sicher in
    Integer-Pixel ueberall (Scroll-Controls rechnen mit Integer, deshalb gibt
    TotalHeight hoechstens High(Integer) zurueck).
  - DefaultHeight darf sich jederzeit aendern (Schrift, DPI): die
    Praefixsummen enthalten nur die eigenen Hoehen. }

{$I ..\PPG.inc}

interface

type
  TPPGRowLayout = class
  private
    FCount: Integer;
    FDefaultHeight: Integer;
    FIdx: array of Integer;   // Zeilen mit eigener Hoehe, aufsteigend
    FHgt: array of Integer;   // ihre Hoehen (> 0)
    FCum: array of Int64;     // FCum[J] = Summe FHgt[0..J-1] (FN + 1 Eintraege)
    FN: Integer;              // belegte Eintraege
    FCumFrom: Integer;        // FCum ab hier ungueltig (FN = alles gueltig)
    procedure SetCount(const Value: Integer);
    procedure SetDefaultHeight(const Value: Integer);
    procedure EnsureCum;
    function GetVariable: Boolean;
    /// Anzahl Eintraege mit Index < AIndex (Position fuer AIndex).
    function LowerBound(AIndex: Integer): Integer;
    procedure Invalidate(J: Integer);
    procedure RemoveEntries(J0, J1: Integer);
  public
    constructor Create;
    /// Hoehe einer Zeile setzen (0 = Standardhoehe). Schaltet in den variablen Modus.
    procedure SetRowHeight(Index, Height: Integer);
    function RowHeight(Index: Integer): Integer;
    /// Eigene Hoehe einer Zeile (0 = keine, also Standardhoehe).
    function OwnHeight(Index: Integer): Integer;
    /// Alle Einzelhoehen verwerfen (wieder feste Hoehe).
    procedure ClearHeights;
    /// Oberkante der Zeile (0 = erste); Index = Count liefert die Gesamthoehe.
    function RowTop(Index: Integer): Int64;
    /// Zeile an der Inhaltskoordinate Y, -1 = keine (Y < 0 oder hinter dem Ende).
    function RowAt(Y: Int64): Integer;
    /// Gesamthoehe, begrenzt auf High(Integer) (Pixel-Koordinaten der Controls).
    function TotalHeight: Integer;
    function TotalHeight64: Int64;
    /// Nach Einfuegen/Loeschen von Zeilen: Einzelhoehen mitverschieben.
    procedure RowsInserted(Index, ACount: Integer);
    procedure RowsDeleted(Index, ACount: Integer);
    /// Zeilen mit eigener Hoehe (aufsteigend): Anzahl, Zeile und Hoehe.
    function OwnHeightCount: Integer;
    function OwnHeightRow(J: Integer): Integer;
    function OwnHeightValue(J: Integer): Integer;
    property Count: Integer read FCount write SetCount;
    property DefaultHeight: Integer read FDefaultHeight write SetDefaultHeight;
    property Variable: Boolean read GetVariable;
  end;

implementation

uses
  PPG.Lang,
  System.SysUtils, PPG.Consts, PPG.Exceptions;

{ TPPGRowLayout }

constructor TPPGRowLayout.Create;
begin
  inherited Create;
  FDefaultHeight := 20;
end;

function TPPGRowLayout.GetVariable: Boolean;
begin
  Result := FN > 0;
end;

function TPPGRowLayout.LowerBound(AIndex: Integer): Integer;
var
  Lo, Hi, Mid: Integer;
begin
  // Schneller Weg: hinter dem letzten Eintrag (Aufbau in aufsteigender Folge)
  if (FN = 0) or (FIdx[FN - 1] < AIndex) then
    Exit(FN);
  Lo := 0;
  Hi := FN;
  while Lo < Hi do
  begin
    Mid := (Lo + Hi) div 2;
    if FIdx[Mid] < AIndex then
      Lo := Mid + 1
    else
      Hi := Mid;
  end;
  Result := Lo;
end;

procedure TPPGRowLayout.Invalidate(J: Integer);
begin
  if J < FCumFrom then
    FCumFrom := J;
end;

procedure TPPGRowLayout.EnsureCum;
var
  J: Integer;
begin
  if FCumFrom >= FN then
    Exit;
  if Length(FCum) < FN + 1 then
    SetLength(FCum, Length(FIdx) + 1);
  if FCumFrom <= 0 then
  begin
    FCum[0] := 0;
    FCumFrom := 0;
  end;
  for J := FCumFrom to FN - 1 do
    FCum[J + 1] := FCum[J] + FHgt[J];
  FCumFrom := FN;
end;

procedure TPPGRowLayout.RemoveEntries(J0, J1: Integer);
var
  K: Integer;
begin
  // Eintraege J0..J1-1 entfernen
  if J1 <= J0 then
    Exit;
  K := FN - J1;
  if K > 0 then
  begin
    Move(FIdx[J1], FIdx[J0], K * SizeOf(Integer));
    Move(FHgt[J1], FHgt[J0], K * SizeOf(Integer));
  end;
  Dec(FN, J1 - J0);
  Invalidate(J0);
end;

procedure TPPGRowLayout.SetCount(const Value: Integer);
begin
  if Value < 0 then
    raise EPPGPropertyError.CreateFmt(PPGStr(@SPPGInvalidArgument), [Value, 'Count']);
  if Value = FCount then
    Exit;
  // Hoehen hinter dem neuen Ende verfallen
  if Value < FCount then
    RemoveEntries(LowerBound(Value), FN);
  FCount := Value;
end;

procedure TPPGRowLayout.SetDefaultHeight(const Value: Integer);
begin
  if Value < 1 then
    raise EPPGPropertyError.CreateFmt(PPGStr(@SPPGInvalidArgument), [Value, 'DefaultHeight']);
  FDefaultHeight := Value;
end;

procedure TPPGRowLayout.SetRowHeight(Index, Height: Integer);
var
  J, N: Integer;
begin
  if (Index < 0) or (Index >= FCount) then
    raise EPPGPropertyError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, FCount - 1]);
  if Height < 0 then
    Height := 0;
  J := LowerBound(Index);
  if (J < FN) and (FIdx[J] = Index) then
  begin
    if Height = 0 then
      RemoveEntries(J, J + 1)
    else if FHgt[J] <> Height then
    begin
      FHgt[J] := Height;
      Invalidate(J);
    end;
    Exit;
  end;
  if Height = 0 then
    Exit; // Standardhoehe: nichts zu speichern
  if FN >= Length(FIdx) then
  begin
    N := Length(FIdx) * 2;
    if N < 16 then
      N := 16;
    SetLength(FIdx, N);
    SetLength(FHgt, N);
  end;
  if J < FN then
  begin
    Move(FIdx[J], FIdx[J + 1], (FN - J) * SizeOf(Integer));
    Move(FHgt[J], FHgt[J + 1], (FN - J) * SizeOf(Integer));
  end;
  FIdx[J] := Index;
  FHgt[J] := Height;
  Inc(FN);
  Invalidate(J);
end;

function TPPGRowLayout.OwnHeight(Index: Integer): Integer;
var
  J: Integer;
begin
  Result := 0;
  if FN = 0 then
    Exit;
  J := LowerBound(Index);
  if (J < FN) and (FIdx[J] = Index) then
    Result := FHgt[J];
end;

function TPPGRowLayout.RowHeight(Index: Integer): Integer;
begin
  Result := 0;
  if (FN > 0) and (Index >= 0) and (Index < FCount) then
    Result := OwnHeight(Index);
  if Result <= 0 then
    Result := FDefaultHeight;
end;

procedure TPPGRowLayout.ClearHeights;
begin
  FN := 0;
  FCumFrom := 0;
  SetLength(FIdx, 0);
  SetLength(FHgt, 0);
  SetLength(FCum, 0);
end;

function TPPGRowLayout.RowTop(Index: Integer): Int64;
var
  J: Integer;
begin
  if Index < 0 then
    Index := 0;
  if Index > FCount then
    Index := FCount;
  if FN = 0 then
    Exit(Int64(Index) * FDefaultHeight);
  EnsureCum;
  // J Zeilen davor haben eine eigene Hoehe, die uebrigen die Standardhoehe
  J := LowerBound(Index);
  Result := Int64(Index - J) * FDefaultHeight + FCum[J];
end;

function TPPGRowLayout.TotalHeight64: Int64;
begin
  Result := RowTop(FCount);
end;

function TPPGRowLayout.TotalHeight: Integer;
var
  H: Int64;
begin
  H := TotalHeight64;
  if H > High(Integer) then
    Result := High(Integer)
  else
    Result := Integer(H);
end;

function TPPGRowLayout.RowAt(Y: Int64): Integer;
var
  Lo, Hi, Mid: Integer;
  Top, E: Int64;
  R: Int64;
begin
  if (Y < 0) or (FCount = 0) then
    Exit(-1);
  if FN = 0 then
  begin
    if Y div FDefaultHeight >= FCount then
      Exit(-1);
    Exit(Integer(Y div FDefaultHeight));
  end;
  EnsureCum;
  if Y >= Int64(FCount - FN) * FDefaultHeight + FCum[FN] then
    Exit(-1);
  // Letzter Eintrag mit Oberkante <= Y
  Lo := -1;
  Hi := FN - 1;
  while Lo < Hi do
  begin
    Mid := (Lo + Hi + 1) div 2;
    Top := Int64(FIdx[Mid] - Mid) * FDefaultHeight + FCum[Mid];
    if Top <= Y then
      Lo := Mid
    else
      Hi := Mid - 1;
  end;
  if Lo < 0 then
    // vor der ersten eigenen Hoehe: nur Standardzeilen
    R := Y div FDefaultHeight
  else
  begin
    Top := Int64(FIdx[Lo] - Lo) * FDefaultHeight + FCum[Lo];
    E := Top + FHgt[Lo];
    if Y < E then
      R := FIdx[Lo]
    else
      R := FIdx[Lo] + 1 + (Y - E) div FDefaultHeight;
  end;
  if R >= FCount then
    R := FCount - 1;
  Result := Integer(R);
end;

procedure TPPGRowLayout.RowsInserted(Index, ACount: Integer);
var
  J: Integer;
begin
  if ACount <= 0 then
    Exit;
  if (Index < 0) or (Index > FCount) then
    Index := FCount;
  // Eigene Hoehen ab Index wandern mit (Summen bleiben gleich)
  for J := LowerBound(Index) to FN - 1 do
    Inc(FIdx[J], ACount);
  Inc(FCount, ACount);
end;

procedure TPPGRowLayout.RowsDeleted(Index, ACount: Integer);
var
  J, J0, J1: Integer;
begin
  if (ACount <= 0) or (Index < 0) or (Index >= FCount) then
    Exit;
  if Index + ACount > FCount then
    ACount := FCount - Index;
  J0 := LowerBound(Index);
  J1 := LowerBound(Index + ACount);
  RemoveEntries(J0, J1);
  for J := J0 to FN - 1 do
    Dec(FIdx[J], ACount);
  Dec(FCount, ACount);
end;

function TPPGRowLayout.OwnHeightCount: Integer;
begin
  Result := FN;
end;

function TPPGRowLayout.OwnHeightRow(J: Integer): Integer;
begin
  Result := FIdx[J];
end;

function TPPGRowLayout.OwnHeightValue(J: Integer): Integer;
begin
  Result := FHgt[J];
end;

end.
