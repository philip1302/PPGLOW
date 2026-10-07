unit PPG.Kanban.Layout;

{ Kanban-Board (Phase 14c): reine Funktionen ohne VCL, ohne Fenster testbar.

  - Stapel: Karten einer Zelle (Spalte x Swimlane) untereinander mit Abstand.
  - Einfuegeposition beim Ziehen: Lage der Maus gegen die Kartenmitten; die
    gezogene Karte selbst zaehlt nicht mit (Skip), damit sich beim Ziehen
    innerhalb der Spalte nichts verschiebt, solange die Maus ueber ihr steht.
  - Zielindex nach dem Herausnehmen (Verschieben in derselben Zelle).
  - Hilfen fuer die Karte: Initialen, Labels, WIP-Zustand. }

{$I ..\PPG.inc}

interface

type
  TPPGKanbanWipState = (kwsNone, kwsOk, kwsFull, kwsOver);

/// Legt Karten der Hoehen Heights ab Top mit Gap untereinander; Tops erhaelt
/// die Oberkanten. Ergebnis: Unterkante der letzten Karte (Top ohne Karten).
function PPGKanbanStack(const Heights: array of Integer; Top, Gap: Integer;
  var Tops: TArray<Integer>): Integer;
/// Erste Karte, deren Unterkante unter Y liegt (binaere Suche), Count = keine.
function PPGKanbanFirstBelow(const Tops, Heights: array of Integer; Y: Integer): Integer;
/// Einfuegeposition fuer die Maus bei Y: Anzahl der Karten (ohne Skip), deren
/// Mitte ueber Y liegt. Skip = Index der gezogenen Karte in diesem Stapel, -1 = keine.
function PPGKanbanDropIndex(const Tops, Heights: array of Integer; Y, Skip: Integer): Integer;
/// Index nach dem Verschieben von OldIndex an die Einfuegeposition DropIndex
/// (gezaehlt ohne die verschobene Karte) - in derselben Zelle gleich DropIndex.
function PPGKanbanMoveIndex(OldIndex, DropIndex, Count: Integer): Integer;
/// Initialen eines Namens: "Anna Berg" -> "AB", "Anna" -> "AN", '' -> ''.
function PPGKanbanInitials(const Name: string): string;
/// Labels aus "Bug, UI; Wichtig" (Komma oder Semikolon), ohne leere.
function PPGKanbanSplitLabels(const S: string): TArray<string>;
/// Zustand gegen das WIP-Limit (Limit <= 0: kwsNone).
function PPGKanbanWipState(Count, Limit: Integer): TPPGKanbanWipState;
/// Stabile Farbnummer 0..Count-1 fuer einen Text (Labels, Avatare).
function PPGKanbanHashIndex(const S: string; Count: Integer): Integer;

implementation

uses
  System.SysUtils, PPG.Types;

function PPGKanbanStack(const Heights: array of Integer; Top, Gap: Integer;
  var Tops: TArray<Integer>): Integer;
var
  I, Y: Integer;
begin
  SetLength(Tops, Length(Heights));
  Y := Top;
  for I := 0 to High(Heights) do
  begin
    Tops[I] := Y;
    Inc(Y, Heights[I]);
    if I < High(Heights) then
      Inc(Y, Gap);
  end;
  Result := Y;
end;

function PPGKanbanFirstBelow(const Tops, Heights: array of Integer; Y: Integer): Integer;
var
  Lo, Hi, Mid: Integer;
begin
  Lo := 0;
  Hi := High(Tops);
  Result := Length(Tops);
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) div 2;
    if Tops[Mid] + Heights[Mid] > Y then
    begin
      Result := Mid;
      Hi := Mid - 1;
    end
    else
      Lo := Mid + 1;
  end;
end;

function PPGKanbanDropIndex(const Tops, Heights: array of Integer; Y, Skip: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(Tops) do
  begin
    if I = Skip then
      Continue;
    if Tops[I] + Heights[I] div 2 < Y then
      Inc(Result)
    else
      Break;
  end;
end;

function PPGKanbanMoveIndex(OldIndex, DropIndex, Count: Integer): Integer;
begin
  // DropIndex zaehlt schon ohne die Karte; Count = Karten der Zelle mit ihr
  Result := DropIndex;
  if Result < 0 then
    Result := 0;
  if (OldIndex >= 0) and (Result > Count - 1) then
    Result := Count - 1
  else if (OldIndex < 0) and (Result > Count) then
    Result := Count;
end;

function PPGKanbanInitials(const Name: string): string;
var
  Parts: TArray<string>;
  S: string;
  I, N: Integer;
begin
  Result := '';
  S := Trim(Name);
  if S = '' then
    Exit;
  S := StringReplace(StringReplace(StringReplace(S, '.', ' ', [rfReplaceAll]), '-', ' ',
    [rfReplaceAll]), '_', ' ', [rfReplaceAll]);
  Parts := PPGSplitString(S, ' ', True);
  N := Length(Parts);
  if N >= 2 then
    Result := Copy(Parts[0], 1, 1) + Copy(Parts[N - 1], 1, 1)
  else if N = 1 then
    Result := Copy(Parts[0], 1, 2);
  Result := AnsiUpperCase(Result);
  for I := Length(Result) downto 1 do
    if Result[I] = ' ' then
      Delete(Result, I, 1);
end;

function PPGKanbanSplitLabels(const S: string): TArray<string>;
var
  Parts: TArray<string>;
  I, N: Integer;
begin
  Parts := PPGSplitString(StringReplace(S, ';', ',', [rfReplaceAll]), ',', False);
  SetLength(Result, Length(Parts));
  N := 0;
  for I := 0 to High(Parts) do
    if Trim(Parts[I]) <> '' then
    begin
      Result[N] := Trim(Parts[I]);
      Inc(N);
    end;
  SetLength(Result, N);
end;

function PPGKanbanWipState(Count, Limit: Integer): TPPGKanbanWipState;
begin
  if Limit <= 0 then
    Result := kwsNone
  else if Count > Limit then
    Result := kwsOver
  else if Count = Limit then
    Result := kwsFull
  else
    Result := kwsOk;
end;

function PPGKanbanHashIndex(const S: string; Count: Integer): Integer;
var
  I: Integer;
  H: Cardinal;
begin
  if Count <= 0 then
    Exit(0);
  H := 2166136261;
  for I := 1 to Length(S) do
  begin
    H := H xor Ord(UpCase(S[I]));
    H := Cardinal((UInt64(H) * 16777619) and $FFFFFFFF);
  end;
  Result := Integer(H mod Cardinal(Count));
end;

end.
