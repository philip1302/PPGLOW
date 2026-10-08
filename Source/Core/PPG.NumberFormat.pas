unit PPG.NumberFormat;

{ Zahlen lesen, rechnen und formatieren (Phase 12b) - ohne VCL, testbar.

  - PPGNormalizeNumber liest tolerant: Waehrungszeichen, Prozent, Leerzeichen
    (auch geschuetzte), Tausendertrenner des Gebietsschemas und Apostroph
    (Schweiz). Eingefuegtes "1,234.50" wird auch unter deutschen
    Einstellungen erkannt: Kommen Punkt und Komma vor, ist das letzte der
    Dezimaltrenner. Kommt nur der Tausendertrenner vor und folgen ihm immer
    genau drei Ziffern, ist er ein Tausendertrenner, sonst ein Dezimaltrenner.
    Ergebnis ist ein invarianter Text ("-1234.5"), den StrToFloat/StrToCurr
    mit PPGInvariantFormat exakt lesen (Currency ohne Umweg ueber Double).
  - PPGEvalNumber rechnet + - * / und Klammern (Punkt vor Strich, unaeres
    Minus), wie das Rechnerfeld von TMS. Zahlen darin wie oben.
  - PPGFormatNumber: Anzeige mit Tausendertrennern, Waehrung nach
    FormatSettings (CurrencyFormat/NegCurrFormat ueber ffCurrency), Prozent.
  - PPGMapCaretByDigits: Einfuegemarke nach dem Formatwechsel an dieselbe
    Ziffer setzen. }

{$I ..\PPG.inc}

interface

uses
  System.SysUtils;

type
  TPPGNumberKind = (nkInteger, nkFloat, nkCurrency, nkPercent);

/// Invariantes Format (Punkt als Dezimaltrenner, keine Tausendertrenner).
function PPGInvariantFormat: TFormatSettings;

/// Tolerantes Lesen; Invariant = "-1234.5". False = keine Zahl.
function PPGNormalizeNumber(const S: string; const FS: TFormatSettings;
  out Invariant: string): Boolean;
function PPGParseNumber(const S: string; const FS: TFormatSettings; out Value: Double): Boolean;
function PPGParseCurrency(const S: string; const FS: TFormatSettings; out Value: Currency): Boolean;

/// Rechnet einen Ausdruck aus (+ - * / Klammern). False = ungueltig oder
/// Division durch Null.
function PPGEvalNumber(const S: string; const FS: TFormatSettings; out Value: Double): Boolean;
/// True, wenn S Rechenzeichen enthaelt (nicht nur ein Vorzeichen).
function PPGIsExpression(const S: string): Boolean;

/// Anzeigeformat. CurrencyString '' = aus FS.
function PPGFormatNumber(Value: Double; Kind: TPPGNumberKind; Decimals: Integer;
  ThousandSeparator: Boolean; const CurrencyString: string; const FS: TFormatSettings): string;
/// Bearbeitungsformat: ohne Tausendertrenner und Zeichen, Nachkommastellen
/// nur soweit noetig ("1234,5").
function PPGFormatEditNumber(Value: Double; Decimals: Integer; const FS: TFormatSettings): string;

/// Position nach der gleichen Anzahl Ziffern (und Dezimaltrenner) im neuen Text.
function PPGMapCaretByDigits(const OldText: string; OldPos: Integer; const NewText: string;
  const FS: TFormatSettings): Integer;

implementation

uses
  System.Math;

var
  GInvariant: TFormatSettings;

function PPGInvariantFormat: TFormatSettings;
begin
  Result := GInvariant;
end;

function IsDigit(C: Char): Boolean; inline;
begin
  Result := (C >= '0') and (C <= '9');
end;

function PPGNormalizeNumber(const S: string; const FS: TFormatSettings;
  out Invariant: string): Boolean;
var
  T, Digits: string;
  I, P, LastDot, LastComma, Count: Integer;
  C, Dec, Prev: Char;
  Neg, AllGroups3, SeenDigit, LetterAfter, SignAfter: Boolean;
begin
  Result := False;
  Invariant := '';
  SeenDigit := False;
  LetterAfter := False;
  SignAfter := False;
  Prev := #0;
  T := Trim(S);
  Neg := False;
  // Klammern wie in Buchhaltungsformaten: (12,50) = -12,50
  if (Length(T) > 2) and (T[1] = '(') and (T[Length(T)] = ')') then
  begin
    Neg := True;
    T := Copy(T, 2, Length(T) - 2);
  end;
  // Waehrung, Prozent, Leerzeichen und Apostroph entfernen
  if FS.CurrencyString <> '' then
    T := StringReplace(T, FS.CurrencyString, '', [rfReplaceAll, rfIgnoreCase]);
  Digits := '';
  // Buchstaben (Waehrungskuerzel) nur vor oder hinter der Zahl, ein Minus nur
  // davor oder ganz am Ende ("100-"). Sonst waeren "A-100" = -100,
  // "1e3" = 13 oder "3x4" = 34 und verfaelschten Summen und Statistiken.
  for I := 1 to Length(T) do
  begin
    C := T[I];
    if IsDigit(C) or (C = '.') or (C = ',') then
    begin
      if IsDigit(C) then
      begin
        if LetterAfter or SignAfter then
          Exit;
        SeenDigit := True;
      end;
      Digits := Digits + C;
    end
    else if (C = '-') or (C = #$2212) then
    begin
      if Neg then
        Exit; // zwei Vorzeichen
      if (Prev >= 'A') and (Prev <= 'Z') or (Prev >= 'a') and (Prev <= 'z') then
        Exit; // "A-100" ist ein Kuerzel, keine negative Zahl
      if SeenDigit then
        SignAfter := True;
      Neg := True;
    end
    else if C = '+' then
    begin
      // Vorzeichen ohne Wirkung, aber nur vor der Zahl ("1+2" ist ein Ausdruck)
      if SeenDigit then
        Exit;
    end
    else if (C = ' ') or (C = #$A0) or (C = #$202F) or (C = '''') or (C = #$2019) or
      (C = '%') or (C = #$20AC) or (C = '$') or (C = #$00A3) or (C = #$00A5) then
      // Leerzeichen, Apostroph (CH), Prozent und gaengige Waehrungszeichen
    else if (C = FS.ThousandSeparator) and (C <> #0) then
      Digits := Digits + '.'  // wird unten wie ein Punkt bewertet
    else if (C >= 'A') and (C <= 'Z') or (C >= 'a') and (C <= 'z') then
    begin
      // Waehrungskuerzel (EUR, CHF, USD)
      if SeenDigit then
        LetterAfter := True;
    end
    else
      Exit;
    Prev := C;
  end;
  if Digits = '' then
    Exit;
  LastDot := LastDelimiter('.', Digits);
  LastComma := LastDelimiter(',', Digits);
  if (LastDot > 0) and (LastComma > 0) then
  begin
    // Beide vorhanden: das letzte ist der Dezimaltrenner
    if LastDot > LastComma then
      Dec := '.'
    else
      Dec := ',';
  end
  else if (LastDot > 0) or (LastComma > 0) then
  begin
    if LastDot > 0 then
      C := '.'
    else
      C := ',';
    // Nur eine Sorte: Tausendertrenner, wenn mehrfach oder wenn es nicht der
    // Dezimaltrenner ist und jede Gruppe genau drei Ziffern hat
    Count := 0;
    AllGroups3 := True;
    P := 0;
    for I := 1 to Length(Digits) do
      if Digits[I] = C then
      begin
        Inc(Count);
        if (P > 0) and (I - P - 1 <> 3) then
          AllGroups3 := False;
        P := I;
      end;
    if Length(Digits) - P <> 3 then
      AllGroups3 := False;
    if (Count > 1) and AllGroups3 then
      Dec := #0
    else if Count > 1 then
      Exit // "1.2.3"
    else if (C <> FS.DecimalSeparator) and AllGroups3 and (P > 1) and (Digits[1] <> '0') then
      Dec := #0
    else
      Dec := C;
  end
  else
    Dec := #0;
  // Zusammensetzen: Dezimaltrenner -> '.', andere Trenner weg
  Invariant := '';
  for I := 1 to Length(Digits) do
  begin
    C := Digits[I];
    if IsDigit(C) then
      Invariant := Invariant + C
    else if (Dec <> #0) and (C = Dec) and (I = LastDelimiter(Dec, Digits)) then
      Invariant := Invariant + '.';
  end;
  if (Invariant = '') or (Invariant = '.') then
    Exit;
  if Invariant[1] = '.' then
    Invariant := '0' + Invariant;
  if Invariant[Length(Invariant)] = '.' then
    Delete(Invariant, Length(Invariant), 1);
  if Neg then
    Invariant := '-' + Invariant;
  Result := True;
end;

function PPGParseNumber(const S: string; const FS: TFormatSettings; out Value: Double): Boolean;
var
  Inv: string;
begin
  Value := 0;
  Result := PPGNormalizeNumber(S, FS, Inv) and TryStrToFloat(Inv, Value, GInvariant);
end;

function PPGParseCurrency(const S: string; const FS: TFormatSettings; out Value: Currency): Boolean;
var
  Inv: string;
begin
  Value := 0;
  Result := PPGNormalizeNumber(S, FS, Inv) and TryStrToCurr(Inv, Value, GInvariant);
end;

{ Ausdruecke }

type
  TExprParser = record
    S: string;
    P: Integer;
    FS: TFormatSettings;
    Ok: Boolean;
    procedure SkipSpaces;
    function Peek: Char;
    function Expr: Double;
    function Term: Double;
    function Factor: Double;
  end;

procedure TExprParser.SkipSpaces;
begin
  while (P <= Length(S)) and ((S[P] = ' ') or (S[P] = #$A0)) do
    Inc(P);
end;

function TExprParser.Peek: Char;
begin
  SkipSpaces;
  if P <= Length(S) then
    Result := S[P]
  else
    Result := #0;
end;

function TExprParser.Expr: Double;
var
  C: Char;
begin
  Result := Term;
  while Ok do
  begin
    C := Peek;
    if C = '+' then
    begin
      Inc(P);
      Result := Result + Term;
    end
    else if (C = '-') or (C = #$2212) then
    begin
      Inc(P);
      Result := Result - Term;
    end
    else
      Break;
  end;
end;

function TExprParser.Term: Double;
var
  C: Char;
  D: Double;
begin
  Result := Factor;
  while Ok do
  begin
    C := Peek;
    if (C = '*') or (C = #$00D7) then
    begin
      Inc(P);
      Result := Result * Factor;
    end
    else if (C = '/') or (C = ':') or (C = #$00F7) then
    begin
      Inc(P);
      D := Factor;
      if D = 0 then
      begin
        Ok := False;
        Exit;
      end;
      Result := Result / D;
    end
    else
      Break;
  end;
end;

function TExprParser.Factor: Double;
var
  C: Char;
  Start: Integer;
begin
  Result := 0;
  C := Peek;
  if (C = '-') or (C = #$2212) then
  begin
    Inc(P);
    Result := -Factor;
    Exit;
  end;
  if C = '+' then
  begin
    Inc(P);
    Result := Factor;
    Exit;
  end;
  if C = '(' then
  begin
    Inc(P);
    Result := Expr;
    if Peek <> ')' then
      Ok := False
    else
      Inc(P);
    Exit;
  end;
  // Zahl: Ziffern, Trenner, Apostroph, Waehrung/Prozent dahinter
  Start := P;
  while (P <= Length(S)) and (IsDigit(S[P]) or (S[P] = '.') or (S[P] = ',') or
    (S[P] = '''') or (S[P] = #$2019) or (S[P] = FS.ThousandSeparator) and (S[P] <> ' ')) do
    Inc(P);
  if P = Start then
  begin
    Ok := False;
    Exit;
  end;
  if not PPGParseNumber(Copy(S, Start, P - Start), FS, Result) then
    Ok := False;
  // Waehrung oder Prozent hinter der Zahl ueberspringen
  SkipSpaces;
  while (P <= Length(S)) and ((S[P] = '%') or (S[P] = #$20AC) or (S[P] = '$')) do
    Inc(P);
end;

function PPGIsExpression(const S: string): Boolean;
var
  I: Integer;
  T: string;
begin
  T := Trim(S);
  Result := False;
  // "(12,50)" ist eine negative Zahl im Buchhaltungsformat, keine Rechnung
  if (Length(T) > 2) and (T[1] = '(') and (T[Length(T)] = ')') and
    (Pos('(', Copy(T, 2, Length(T) - 2)) = 0) and (Pos(')', Copy(T, 2, Length(T) - 2)) = 0) then
    T := Copy(T, 2, Length(T) - 2);
  for I := 2 to Length(T) do
    if CharInSet(T[I], ['+', '-', '*', '/', ':', '(', ')']) or (T[I] = #$00D7) or
      (T[I] = #$00F7) or (T[I] = #$2212) then
      Exit(True);
  if (T <> '') and (T[1] = '(') then
    Result := True;
end;

function PPGEvalNumber(const S: string; const FS: TFormatSettings; out Value: Double): Boolean;
var
  E: TExprParser;
begin
  Value := 0;
  // Reine Zahl (auch mit Tausendertrennern, Waehrung): direkt lesen
  if not PPGIsExpression(S) then
    Exit(PPGParseNumber(S, FS, Value));
  E.S := S;
  E.P := 1;
  E.FS := FS;
  E.Ok := True;
  try
    Value := E.Expr;
  except
    on EMathError do
      E.Ok := False;
  end;
  Result := E.Ok and (E.Peek = #0) and not IsNan(Value) and not IsInfinite(Value);
end;

{ Formatieren }

function PPGFormatNumber(Value: Double; Kind: TPPGNumberKind; Decimals: Integer;
  ThousandSeparator: Boolean; const CurrencyString: string; const FS: TFormatSettings): string;
var
  F: TFormatSettings;
begin
  F := FS;
  if Kind = nkInteger then
    Decimals := 0;
  if Decimals < 0 then
    Decimals := 0;
  case Kind of
    nkCurrency:
      begin
        if CurrencyString <> '' then
          F.CurrencyString := CurrencyString;
        F.CurrencyDecimals := Decimals;
        Result := FloatToStrF(Value, ffCurrency, 18, Decimals, F);
      end;
  else
    if ThousandSeparator then
      Result := FloatToStrF(Value, ffNumber, 18, Decimals, F)
    else
      Result := FloatToStrF(Value, ffFixed, 18, Decimals, F);
  end;
  if (Kind = nkCurrency) and not ThousandSeparator and (F.ThousandSeparator <> #0) then
    Result := StringReplace(Result, F.ThousandSeparator, '', [rfReplaceAll]);
  if Kind = nkPercent then
  begin
    // Deutsch "12,5 %", Englisch "12.5%"
    if F.DecimalSeparator = ',' then
      Result := Result + #$A0'%'
    else
      Result := Result + '%';
  end;
end;

function PPGFormatEditNumber(Value: Double; Decimals: Integer; const FS: TFormatSettings): string;
begin
  if Decimals <= 0 then
    Result := FormatFloat('0', Value, FS)
  else
    Result := FormatFloat('0.' + StringOfChar('#', Decimals), Value, FS);
  if Result = '-0' then
    Result := '0';
end;

function PPGMapCaretByDigits(const OldText: string; OldPos: Integer; const NewText: string;
  const FS: TFormatSettings): Integer;
var
  I, N, Seen: Integer;
  AfterDec: Boolean;
  DecIdx: Integer;
begin
  // Ziffern vor der Marke zaehlen; hinter dem Dezimaltrenner zaehlt der Teil
  // nach dem Trenner fuer sich (sonst springt die Marke bei "1.234,5")
  N := 0;
  AfterDec := False;
  DecIdx := Pos(FS.DecimalSeparator, OldText);
  for I := 1 to Min(OldPos, Length(OldText)) do
    if IsDigit(OldText[I]) then
      Inc(N);
  if (DecIdx > 0) and (OldPos >= DecIdx) then
  begin
    AfterDec := True;
    N := 0;
    for I := DecIdx + 1 to Min(OldPos, Length(OldText)) do
      if IsDigit(OldText[I]) then
        Inc(N);
  end;
  if AfterDec then
  begin
    DecIdx := Pos(FS.DecimalSeparator, NewText);
    if DecIdx = 0 then
      Exit(Length(NewText));
    Result := DecIdx;
    Seen := 0;
    for I := DecIdx + 1 to Length(NewText) do
    begin
      if Seen >= N then
        Break;
      if IsDigit(NewText[I]) then
        Inc(Seen);
      Result := I;
    end;
    Exit;
  end;
  Result := 0;
  Seen := 0;
  for I := 1 to Length(NewText) do
  begin
    if Seen >= N then
      Break;
    if IsDigit(NewText[I]) then
      Inc(Seen);
    Result := I;
  end;
end;

initialization
  GInvariant := TFormatSettings.Create('en-US');
  GInvariant.DecimalSeparator := '.';
  GInvariant.ThousandSeparator := ',';

end.
