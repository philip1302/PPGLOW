unit PPG.RowLayout;

{ TPPGRowLayout - Lage von Zeilen fuer virtuelle Listen (ListBox, Baum, Grid).

  - Feste Zeilenhoehe: RowTop/RowAt in O(1), kein Speicher pro Zeile.
  - Variable Hoehe: Hoehen pro Zeile (0 = Standardhoehe), dazu ein
    Praefixsummen-Cache, der erst bei Bedarf neu aufgebaut wird (O(n) einmal
    nach Aenderungen), danach RowTop O(1) und RowAt per binaerer Suche.
  - Positionen sind Int64: 1 000 000 Zeilen x 30 px passen nicht sicher in
    Integer-Pixel ueberall (Scroll-Controls rechnen mit Integer, deshalb gibt
    TotalHeight hoechstens High(Integer) zurueck).
  - Wird DefaultHeight geaendert (Schrift, DPI), ist der Cache ungueltig. }

{$I ..\PPG.inc}

interface

type
  TPPGRowLayout = class
  private
    FCount: Integer;
    FDefaultHeight: Integer;
    FHeights: array of Integer; // leer = alle Zeilen in Standardhoehe
    FTops: array of Int64;      // Praefixsummen (Count + 1 Eintraege)
    FDirty: Boolean;
    procedure SetCount(const Value: Integer);
    procedure SetDefaultHeight(const Value: Integer);
    procedure EnsureTops;
    function GetVariable: Boolean;
  public
    constructor Create;
    /// Hoehe einer Zeile setzen (0 = Standardhoehe). Schaltet in den variablen Modus.
    procedure SetRowHeight(Index, Height: Integer);
    function RowHeight(Index: Integer): Integer;
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
  Result := Length(FHeights) > 0;
end;

procedure TPPGRowLayout.SetCount(const Value: Integer);
var
  Old, I: Integer;
begin
  if Value < 0 then
    raise EPPGPropertyError.CreateFmt(PPGStr(@SPPGInvalidArgument), [Value, 'Count']);
  if Value = FCount then
    Exit;
  Old := FCount;
  FCount := Value;
  if Variable then
  begin
    SetLength(FHeights, Value);
    for I := Old to Value - 1 do
      FHeights[I] := 0;
  end;
  FDirty := True;
end;

procedure TPPGRowLayout.SetDefaultHeight(const Value: Integer);
begin
  if Value < 1 then
    raise EPPGPropertyError.CreateFmt(PPGStr(@SPPGInvalidArgument), [Value, 'DefaultHeight']);
  if Value <> FDefaultHeight then
  begin
    FDefaultHeight := Value;
    FDirty := True;
  end;
end;

procedure TPPGRowLayout.SetRowHeight(Index, Height: Integer);
var
  I: Integer;
begin
  if (Index < 0) or (Index >= FCount) then
    raise EPPGPropertyError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, FCount - 1]);
  if Height < 0 then
    Height := 0;
  if not Variable then
  begin
    if Height = 0 then
      Exit; // Standardhoehe im festen Modus: nichts zu tun
    SetLength(FHeights, FCount);
    for I := 0 to FCount - 1 do
      FHeights[I] := 0;
  end;
  if FHeights[Index] <> Height then
  begin
    FHeights[Index] := Height;
    FDirty := True;
  end;
end;

function TPPGRowLayout.RowHeight(Index: Integer): Integer;
begin
  if Variable and (Index >= 0) and (Index < FCount) and (FHeights[Index] > 0) then
    Result := FHeights[Index]
  else
    Result := FDefaultHeight;
end;

procedure TPPGRowLayout.ClearHeights;
begin
  SetLength(FHeights, 0);
  SetLength(FTops, 0);
  FDirty := True;
end;

procedure TPPGRowLayout.EnsureTops;
var
  I: Integer;
  Y: Int64;
begin
  if not FDirty and (Length(FTops) = FCount + 1) then
    Exit;
  SetLength(FTops, FCount + 1);
  Y := 0;
  for I := 0 to FCount - 1 do
  begin
    FTops[I] := Y;
    if FHeights[I] > 0 then
      Inc(Y, FHeights[I])
    else
      Inc(Y, FDefaultHeight);
  end;
  FTops[FCount] := Y;
  FDirty := False;
end;

function TPPGRowLayout.RowTop(Index: Integer): Int64;
begin
  if Index < 0 then
    Index := 0;
  if Index > FCount then
    Index := FCount;
  if not Variable then
    Exit(Int64(Index) * FDefaultHeight);
  EnsureTops;
  Result := FTops[Index];
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
begin
  if (Y < 0) or (FCount = 0) then
    Exit(-1);
  if not Variable then
  begin
    if Y div FDefaultHeight >= FCount then
      Exit(-1);
    Exit(Integer(Y div FDefaultHeight));
  end;
  EnsureTops;
  if Y >= FTops[FCount] then
    Exit(-1);
  // Groesste Zeile mit Top <= Y
  Lo := 0;
  Hi := FCount - 1;
  while Lo < Hi do
  begin
    Mid := (Lo + Hi + 1) div 2;
    if FTops[Mid] <= Y then
      Lo := Mid
    else
      Hi := Mid - 1;
  end;
  Result := Lo;
end;

procedure TPPGRowLayout.RowsInserted(Index, ACount: Integer);
var
  I: Integer;
begin
  if ACount <= 0 then
    Exit;
  if (Index < 0) or (Index > FCount) then
    Index := FCount;
  if Variable then
  begin
    SetLength(FHeights, FCount + ACount);
    for I := FCount - 1 downto Index do
      FHeights[I + ACount] := FHeights[I];
    for I := Index to Index + ACount - 1 do
      FHeights[I] := 0;
  end;
  Inc(FCount, ACount);
  FDirty := True;
end;

procedure TPPGRowLayout.RowsDeleted(Index, ACount: Integer);
var
  I: Integer;
begin
  if (ACount <= 0) or (Index < 0) or (Index >= FCount) then
    Exit;
  if Index + ACount > FCount then
    ACount := FCount - Index;
  if Variable then
  begin
    for I := Index to FCount - ACount - 1 do
      FHeights[I] := FHeights[I + ACount];
    SetLength(FHeights, FCount - ACount);
  end;
  Dec(FCount, ACount);
  FDirty := True;
end;

end.
