unit PPG.Chart.Scale;

{ Achsen fuer Diagramme (Phase 10) - ohne VCL, deshalb ohne Fenster testbar.

  - Zahlenachse: "Nice Numbers" (Heckbert): Schrittweite 1, 2 oder 5 mal
    10^n, Grenzen als Vielfache der Schrittweite.
  - Datumsachse: Schritte in sinnvollen Einheiten (Sekunde bis Jahr),
    Striche auf Einheitsgrenzen (Wochen beginnen am Montag, ISO 8601).
  - Beschriftung ueber TFormatSettings (Dezimaltrenner, Datumsformat). }

{$I ..\PPG.inc}

interface

uses
  System.SysUtils;

type
  TPPGAxisScale = record
    Min: Double;
    Max: Double;
    Step: Double;
    /// Nachkommastellen fuer die Beschriftung (aus der Schrittweite).
    Decimals: Integer;
  end;

  TPPGDateUnit = (duSecond, duMinute, duHour, duDay, duWeek, duMonth, duYear);

  TPPGDateScale = record
    Min: TDateTime;
    Max: TDateTime;
    DateUnit: TPPGDateUnit;
    /// Vielfaches der Einheit je Schritt (z.B. 15 Minuten, 3 Monate).
    Count: Integer;
  end;

/// Runde Zahl in der Groessenordnung von Value (Rounded = naechste statt
/// naechsthoehere: 1, 2, 5, 10).
function PPGNiceNumber(Value: Double; Rounded: Boolean): Double;
/// Automatische Achse fuer den Datenbereich. IncludeZero = 0 liegt immer
/// auf der Achse (Saeulen, Flaechen). MaxTicks >= 2.
function PPGNiceScale(DataMin, DataMax: Double; MaxTicks: Integer;
  IncludeZero: Boolean): TPPGAxisScale;
/// Feste Grenzen, nur die Schrittweite wird gerundet.
function PPGFixedScale(AMin, AMax: Double; MaxTicks: Integer): TPPGAxisScale;
function PPGScaleTickCount(const S: TPPGAxisScale): Integer;
/// Wert des Strichs Index (0 = Min). Beseitigt Rundungsreste (0.30000004).
function PPGScaleTick(const S: TPPGAxisScale; Index: Integer): Double;
/// Leeres Fmt = Dezimalstellen aus der Achse; sonst FormatFloat(Fmt).
function PPGFormatAxisValue(Value: Double; Decimals: Integer; const Fmt: string;
  const FS: TFormatSettings): string;

function PPGNiceDateScale(AMin, AMax: TDateTime; MaxTicks: Integer): TPPGDateScale;
/// Alle Striche von Min bis Max (beide eingeschlossen).
function PPGDateTicks(const S: TPPGDateScale): TArray<TDateTime>;
/// Naechster Strich nach Value (ein Schritt der Achse).
function PPGNextDateTick(const S: TPPGDateScale; Value: TDateTime): TDateTime;
function PPGFormatDateTick(Value: TDateTime; const S: TPPGDateScale;
  const FS: TFormatSettings): string;
/// Kurzes Datumsformat ohne Jahr ("dd.MM.yyyy" -> "dd.MM").
function PPGStripYearFormat(const ShortDateFormat: string): string;

implementation

uses
  System.Math, System.DateUtils;

const
  // Double-Basis: Power(10, n) waehlt unter Win64 die Single-Ueberladung
  TenD: Double = 10;
  Eps = 1E-9;

// Floor/Ceil aus System.Math liefern Integer und laufen ab 2^31 ueber
// (z.B. Werte um 1e10 mit Schrittweite 2). Hier ohne Ganzzahl-Umweg.
function FloorF(X: Double): Double;
begin
  Result := Int(X);
  if Result > X then
    Result := Result - 1;
end;

function CeilF(X: Double): Double;
begin
  Result := Int(X);
  if Result < X then
    Result := Result + 1;
end;

function IsUsable(V: Double): Boolean;
begin
  Result := not IsNan(V) and not IsInfinite(V);
end;

function PPGNiceNumber(Value: Double; Rounded: Boolean): Double;
var
  Expo: Integer;
  F, Nice: Double;
begin
  if Value <= 0 then
    Exit(1);
  Expo := Floor(Log10(Value));
  F := Value / IntPower(TenD, Expo);
  if Rounded then
  begin
    if F < 1.5 then
      Nice := 1
    else if F < 3 then
      Nice := 2
    else if F < 7 then
      Nice := 5
    else
      Nice := 10;
  end
  else
  begin
    if F <= 1 + Eps then
      Nice := 1
    else if F <= 2 + Eps then
      Nice := 2
    else if F <= 5 + Eps then
      Nice := 5
    else
      Nice := 10;
  end;
  Result := Nice * IntPower(TenD, Expo);
end;

function DecimalsFor(Step: Double): Integer;
begin
  if Step <= 0 then
    Exit(0);
  Result := -Floor(Log10(Step) + Eps);
  if Result < 0 then
    Result := 0;
  if Result > 15 then
    Result := 15;
end;

function PPGNiceScale(DataMin, DataMax: Double; MaxTicks: Integer;
  IncludeZero: Boolean): TPPGAxisScale;
var
  Lo, Hi, Span, Range: Double;
begin
  if MaxTicks < 2 then
    MaxTicks := 2;
  if not IsUsable(DataMin) or not IsUsable(DataMax) then
  begin
    DataMin := 0;
    DataMax := 0;
  end;
  Lo := System.Math.Min(DataMin, DataMax);
  Hi := System.Math.Max(DataMin, DataMax);
  if IncludeZero then
  begin
    if Lo > 0 then
      Lo := 0;
    if Hi < 0 then
      Hi := 0;
  end;
  if Hi - Lo <= Abs(Hi) * Eps then
  begin
    // Alle Werte gleich: Bereich um den Wert (bei 0 einfach 0..1)
    if Hi = 0 then
    begin
      Lo := 0;
      Hi := 1;
    end
    else
    begin
      Span := Abs(Hi) * 0.1;
      if IncludeZero and (Hi > 0) then
        Lo := 0
      else
        Lo := Lo - Span;
      if IncludeZero and (Hi < 0) then
        Hi := 0
      else
        Hi := Hi + Span;
    end;
  end;
  // Nur die Schrittweite runden (den Bereich vorher zu runden macht die
  // Achse oft doppelt so hoch wie die Daten, z.B. 0..40 fuer 23)
  Range := Hi - Lo;
  Result.Step := PPGNiceNumber(Range / (MaxTicks - 1), True);
  Result.Min := FloorF(Lo / Result.Step + Eps) * Result.Step;
  Result.Max := CeilF(Hi / Result.Step - Eps) * Result.Step;
  if Result.Max <= Result.Min then
    Result.Max := Result.Min + Result.Step;
  Result.Decimals := DecimalsFor(Result.Step);
end;

function PPGFixedScale(AMin, AMax: Double; MaxTicks: Integer): TPPGAxisScale;
begin
  if MaxTicks < 2 then
    MaxTicks := 2;
  if not IsUsable(AMin) or not IsUsable(AMax) or (AMax <= AMin) then
    Exit(PPGNiceScale(AMin, AMax, MaxTicks, False));
  Result.Min := AMin;
  Result.Max := AMax;
  Result.Step := PPGNiceNumber((AMax - AMin) / (MaxTicks - 1), True);
  Result.Decimals := DecimalsFor(Result.Step);
end;

function PPGScaleTickCount(const S: TPPGAxisScale): Integer;
var
  First: Double;
begin
  if S.Step <= 0 then
    Exit(0);
  // Striche liegen auf Vielfachen der Schrittweite innerhalb [Min, Max]
  First := CeilF(S.Min / S.Step - Eps) * S.Step;
  Result := Floor((S.Max - First) / S.Step + Eps) + 1;
  if Result < 0 then
    Result := 0;
end;

function PPGScaleTick(const S: TPPGAxisScale; Index: Integer): Double;
begin
  Result := (CeilF(S.Min / S.Step - Eps) + Index) * S.Step;
  // Rundungsreste weg (0.1 * 3 = 0.30000000000000004)
  Result := RoundTo(Result, -System.Math.Min(S.Decimals + 2, 15));
  if Abs(Result) < S.Step * Eps then
    Result := 0;
end;

function PPGFormatAxisValue(Value: Double; Decimals: Integer; const Fmt: string;
  const FS: TFormatSettings): string;
begin
  if Fmt <> '' then
    Result := FormatFloat(Fmt, Value, FS)
  else
    Result := FloatToStrF(Value, ffNumber, 15, Decimals, FS);
end;

{ ---- Datumsachse ---- }

type
  TDateStep = record
    U: TPPGDateUnit;
    N: Integer;
    Days: Double; // ungefaehre Laenge
  end;

const
  DateSteps: array[0..20] of TDateStep = (
    (U: duSecond; N: 1; Days: 1 / 86400),
    (U: duSecond; N: 5; Days: 5 / 86400),
    (U: duSecond; N: 15; Days: 15 / 86400),
    (U: duSecond; N: 30; Days: 30 / 86400),
    (U: duMinute; N: 1; Days: 1 / 1440),
    (U: duMinute; N: 5; Days: 5 / 1440),
    (U: duMinute; N: 15; Days: 15 / 1440),
    (U: duMinute; N: 30; Days: 30 / 1440),
    (U: duHour; N: 1; Days: 1 / 24),
    (U: duHour; N: 3; Days: 3 / 24),
    (U: duHour; N: 6; Days: 6 / 24),
    (U: duHour; N: 12; Days: 12 / 24),
    (U: duDay; N: 1; Days: 1),
    (U: duDay; N: 2; Days: 2),
    (U: duWeek; N: 1; Days: 7),
    (U: duMonth; N: 1; Days: 30.44),
    (U: duMonth; N: 3; Days: 91.31),
    (U: duMonth; N: 6; Days: 182.62),
    (U: duYear; N: 1; Days: 365.25),
    (U: duYear; N: 2; Days: 730.5),
    (U: duYear; N: 5; Days: 1826.25));

function FloorToUnit(Value: TDateTime; U: TPPGDateUnit; N: Integer): TDateTime;
var
  Y, M, D, H, Mi, S, Ms: Word;
begin
  DecodeDateTime(Value, Y, M, D, H, Mi, S, Ms);
  case U of
    duSecond: Result := EncodeDateTime(Y, M, D, H, Mi, (S div N) * N, 0);
    duMinute: Result := EncodeDateTime(Y, M, D, H, (Mi div N) * N, 0, 0);
    duHour: Result := EncodeDateTime(Y, M, D, (H div N) * N, 0, 0, 0);
    duDay: Result := EncodeDate(Y, M, D);
    duWeek: Result := EncodeDate(Y, M, D) - (DayOfTheWeek(Value) - 1);
    duMonth: Result := EncodeDate(Y, ((M - 1) div N) * N + 1, 1);
  else
    Result := EncodeDate(System.Math.Max(1, (Y div N) * N), 1, 1);
  end;
end;

/// Ungefaehre Schrittweite in Tagen (obere Schranke).
function StepDays(const S: TPPGDateScale): Double;
var
  N: Integer;
begin
  N := System.Math.Max(S.Count, 1);
  case S.DateUnit of
    duSecond: Result := N / 86400;
    duMinute: Result := N / 1440;
    duHour: Result := N / 24;
    duDay: Result := N;
    duWeek: Result := 7 * N;
    duMonth: Result := 31 * N;
  else
    Result := 366 * N;
  end;
end;

/// Liegt V im Bereich, den TDateTime-Routinen kodieren koennen (Jahr 1..9999)?
function InDateRange(V: Double): Boolean;
begin
  Result := IsUsable(V) and (V >= MinDateTime) and (V <= MaxDateTime);
end;

function PPGNextDateTick(const S: TPPGDateScale; Value: TDateTime): TDateTime;
begin
  // Audit 08.10.2026: Ausserhalb von Jahr 1..9999 (z. B. Unix-Zeitstempel als
  // Datum) warfen IncYear/IncMonth EConvertError in Layout und Paint. Dort
  // nur noch rechnen, nicht kodieren; die Schleifen enden trotzdem.
  if not InDateRange(Value) or not InDateRange(Value + StepDays(S)) then
  begin
    if IsUsable(Value) then
      Result := Value + StepDays(S)
    else
      Result := MaxDateTime + 1;
    Exit;
  end;
  case S.DateUnit of
    duSecond: Result := IncSecond(Value, S.Count);
    duMinute: Result := IncMinute(Value, S.Count);
    duHour: Result := IncHour(Value, S.Count);
    duDay: Result := IncDay(Value, S.Count);
    duWeek: Result := IncWeek(Value, S.Count);
    duMonth: Result := IncMonth(Value, S.Count);
  else
    Result := IncYear(Value, S.Count);
  end;
end;

function PPGNiceDateScale(AMin, AMax: TDateTime; MaxTicks: Integer): TPPGDateScale;
var
  Span, T: Double;
  I, Guard: Integer;
begin
  if MaxTicks < 2 then
    MaxTicks := 2;
  // Auf den kodierbaren Bereich begrenzen (FloorToUnit kodiert)
  if not IsUsable(AMin) then
    AMin := 0;
  if not IsUsable(AMax) then
    AMax := AMin;
  AMin := System.Math.Min(System.Math.Max(AMin, MinDateTime), MaxDateTime);
  AMax := System.Math.Min(System.Math.Max(AMax, MinDateTime), MaxDateTime);
  if AMax < AMin then
  begin
    T := AMin;
    AMin := AMax;
    AMax := T;
  end;
  if AMax - AMin < 1 / 86400 then
    AMax := AMin + 1 / 86400;
  Span := AMax - AMin;
  Result.DateUnit := duYear;
  Result.Count := 0;
  for I := Low(DateSteps) to High(DateSteps) do
    if DateSteps[I].Days * (MaxTicks - 1) >= Span then
    begin
      Result.DateUnit := DateSteps[I].U;
      Result.Count := DateSteps[I].N;
      Break;
    end;
  if Result.Count = 0 then
  begin
    // Jahrhunderte: Jahresschritt als runde Zahl
    Result.DateUnit := duYear;
    Result.Count := Round(PPGNiceNumber(Span / 365.25 / (MaxTicks - 1), False));
    if Result.Count < 1 then
      Result.Count := 1;
  end;
  Result.Min := FloorToUnit(AMin, Result.DateUnit, Result.Count);
  Result.Max := Result.Min;
  Guard := 0;
  while (Result.Max < AMax - 1E-7) and (Guard < 10000) do
  begin
    Result.Max := PPGNextDateTick(Result, Result.Max);
    Inc(Guard);
  end;
end;

function PPGDateTicks(const S: TPPGDateScale): TArray<TDateTime>;
var
  T: TDateTime;
  N, Guard: Integer;
begin
  SetLength(Result, 0);
  N := 0;
  T := S.Min;
  if not IsUsable(T) or not IsUsable(S.Max) then
    Exit;
  if T < MinDateTime then
    T := MinDateTime;
  Guard := 0;
  while (T <= S.Max + 1E-7) and (N < 10000) and (Guard < 100000) do
  begin
    Inc(Guard);
    // Nur beschriftbare Zeitpunkte liefern (FormatDateTime kodiert)
    if InDateRange(T) then
    begin
      SetLength(Result, N + 1);
      Result[N] := T;
      Inc(N);
    end
    else if T > MaxDateTime then
      Break;
    T := PPGNextDateTick(S, T);
  end;
end;

function PPGStripYearFormat(const ShortDateFormat: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(ShortDateFormat) do
  begin
    C := ShortDateFormat[I];
    if (C = 'y') or (C = 'Y') then
      Continue;
    Result := Result + C;
  end;
  // Trenner, die am Rand uebrig bleiben ("dd.MM." / "-MM-dd")
  while (Result <> '') and not CharInSet(Result[Length(Result)], ['d', 'D', 'm', 'M']) do
    Delete(Result, Length(Result), 1);
  while (Result <> '') and not CharInSet(Result[1], ['d', 'D', 'm', 'M']) do
    Delete(Result, 1, 1);
  if Result = '' then
    Result := 'dd/mm';
end;

function PPGFormatDateTick(Value: TDateTime; const S: TPPGDateScale;
  const FS: TFormatSettings): string;
begin
  if not InDateRange(Value) then
    Exit('');
  case S.DateUnit of
    duSecond: Result := FormatDateTime(FS.LongTimeFormat, Value, FS);
    duMinute, duHour: Result := FormatDateTime(FS.ShortTimeFormat, Value, FS);
    duDay, duWeek:
      if InDateRange(S.Min) and InDateRange(S.Max) and (YearOf(S.Min) = YearOf(S.Max)) then
        Result := FormatDateTime(PPGStripYearFormat(FS.ShortDateFormat), Value, FS)
      else
        Result := FormatDateTime(FS.ShortDateFormat, Value, FS);
    duMonth: Result := FormatDateTime('mmm yyyy', Value, FS);
  else
    Result := FormatDateTime('yyyy', Value, FS);
  end;
end;

end.
