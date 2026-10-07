unit PPG.KeyTips;

{ KeyTips (Buchstaben-Plaketten fuer die Tastatur, Phase 14b) als reine
  Funktionen ohne VCL.

  Vergabe (PPGAssignKeyTips) fuer eine Ebene:
  1. Eigene KeyTips (Explicit) gelten unveraendert (in Grossbuchstaben).
  2. Sonst ein Buchstabe: der Buchstabe hinter "&" in der Beschriftung, dann
     die Wortanfaenge, dann die uebrigen Buchstaben und Ziffern der
     Beschriftung - der erste, der noch frei ist.
  3. Wer leer ausgeht, bekommt zwei Zeichen: ein Praefix, das kein
     Einzelzeichen ist (erster Buchstabe der Beschriftung, sonst Z, Y, X ...)
     und ein zweites Zeichen, das unter diesem Praefix frei ist.
  Ein Einzelzeichen ist nie Anfang eines Zweierzeichens (sonst loeste das
  erste Zeichen sofort aus).

  Abgleich (PPGMatchKeyTips): wie viele Plaketten mit dem Getippten
  beginnen und welche genau passt. }

{$I ..\PPG.inc}

interface

/// KeyTips fuer eine Ebene. Captions und Explicit haben gleiche Laenge;
/// Reserved = Zeichen, die nicht vergeben werden (z.B. schon belegt).
function PPGAssignKeyTips(const Captions, Explicit: array of string;
  const Reserved: string = ''): TArray<string>;
/// Anzahl der Tips, die mit Typed beginnen (ohne Gross-/Kleinschreibung);
/// Exact = Index des Tips, der genau Typed ist, sonst -1.
function PPGMatchKeyTips(const Tips: array of string; const Typed: string;
  out Exact: Integer): Integer;
/// Ein Zeichen als KeyTip-Zeichen (Grossbuchstabe), '' = nicht geeignet.
function PPGKeyTipChar(C: Char): string;

implementation

uses
  System.SysUtils;

function PPGKeyTipChar(C: Char): string;
begin
  Result := '';
  if CharInSet(C, ['0'..'9', 'A'..'Z']) then
    Result := C
  else if CharInSet(C, ['a'..'z']) then
    Result := UpCase(C)
  else if Ord(C) > 127 then
  begin
    // Buchstaben ausserhalb von ASCII (Umlaute): haben Gross- und Kleinform
    Result := AnsiUpperCase(C);
    if Result = AnsiLowerCase(C) then
      Result := '';
  end;
end;

/// Kandidaten in der Reihenfolge: &-Buchstabe, Wortanfaenge, Rest.
function Candidates(const Caption: string): string;
var
  I: Integer;
  S, Hot, Starts, Rest: string;
  WordStart: Boolean;
begin
  Hot := '';
  Starts := '';
  Rest := '';
  WordStart := True;
  I := 1;
  while I <= Length(Caption) do
  begin
    if (Caption[I] = '&') and (I < Length(Caption)) then
    begin
      if Caption[I + 1] = '&' then
      begin
        Inc(I, 2);
        WordStart := False;
        Continue;
      end;
      if Hot = '' then
        Hot := PPGKeyTipChar(Caption[I + 1]);
      Inc(I);
      Continue;
    end;
    S := PPGKeyTipChar(Caption[I]);
    if S = '' then
      WordStart := True
    else
    begin
      if WordStart then
        Starts := Starts + S
      else
        Rest := Rest + S;
      WordStart := False;
    end;
    Inc(I);
  end;
  Result := Hot + Starts + Rest;
end;

function PPGAssignKeyTips(const Captions, Explicit: array of string;
  const Reserved: string): TArray<string>;
const
  Prefixes = 'ZYXWVQJK';
  Seconds = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789';
var
  I, J, N: Integer;
  Used: string;        // vergebene Einzelzeichen und Praefixe
  Cand, P, S, Pref: string;
  Done: Boolean;
  Tips: TArray<string>;

  function Taken(const T: string): Boolean;
  var
    K: Integer;
  begin
    for K := 0 to N - 1 do
      if Tips[K] = T then
        Exit(True);
    Result := False;
  end;

  function UsedAsPrefix(const Ch: string): Boolean;
  var
    K: Integer;
  begin
    for K := 0 to N - 1 do
      if (Length(Tips[K]) > 1) and (Copy(Tips[K], 1, 1) = Ch) then
        Exit(True);
    Result := False;
  end;

begin
  N := Length(Captions);
  SetLength(Tips, N);
  Used := AnsiUpperCase(Reserved);
  // 1. Eigene KeyTips
  for I := 0 to N - 1 do
  begin
    if I <= High(Explicit) then
      Tips[I] := AnsiUpperCase(Trim(Explicit[I]))
    else
      Tips[I] := '';
    if Length(Tips[I]) = 1 then
      Used := Used + Tips[I];
  end;
  // 2. Ein Buchstabe aus der Beschriftung
  for I := 0 to N - 1 do
  begin
    if Tips[I] <> '' then
      Continue;
    Cand := Candidates(Captions[I]);
    for J := 1 to Length(Cand) do
    begin
      S := Cand[J];
      if (Pos(S, Used) = 0) and not UsedAsPrefix(S) then
      begin
        Tips[I] := S;
        Used := Used + S;
        Break;
      end;
    end;
  end;
  // 3. Zwei Zeichen fuer den Rest
  for I := 0 to N - 1 do
  begin
    if Tips[I] <> '' then
      Continue;
    Cand := Candidates(Captions[I]);
    Pref := '';
    // Praefix: erster Buchstabe der Beschriftung, wenn er kein Einzelzeichen ist
    if (Cand <> '') and (Pos(Cand[1], Used) = 0) then
      Pref := Cand[1]
    else
      for J := 1 to Length(Prefixes) do
        if Pos(Prefixes[J], Used) = 0 then
        begin
          Pref := Prefixes[J];
          Break;
        end;
    if Pref = '' then
      Pref := 'Z';
    Done := False;
    // zweites Zeichen: zuerst aus der Beschriftung, dann der Reihe nach
    P := Cand + Seconds;
    for J := 1 to Length(P) do
    begin
      S := Pref + P[J];
      if not Taken(S) then
      begin
        Tips[I] := S;
        Done := True;
        Break;
      end;
    end;
    if not Done then
      Tips[I] := Pref + IntToStr(I);
  end;
  Result := Tips;
end;

function PPGMatchKeyTips(const Tips: array of string; const Typed: string;
  out Exact: Integer): Integer;
var
  I: Integer;
  T: string;
begin
  Result := 0;
  Exact := -1;
  T := AnsiUpperCase(Typed);
  if T = '' then
    Exit;
  for I := 0 to High(Tips) do
    if (Tips[I] <> '') and (Copy(Tips[I], 1, Length(T)) = T) then
    begin
      Inc(Result);
      if (Exact < 0) and (Tips[I] = T) then
        Exact := I;
    end;
end;

end.
