unit PPG.Planner.Recurrence;

{ Wiederholungen nach RFC 5545 (iCalendar RRULE), Phase 14a, ohne VCL.

  - Unterstuetzt: FREQ (DAILY/WEEKLY/MONTHLY/YEARLY), INTERVAL, COUNT, UNTIL,
    BYDAY (auch mit Ordnungszahl, z. B. 2TU, -1FR), BYMONTHDAY (auch negativ),
    BYMONTH, BYSETPOS, WKST. Andere Teile werden beim Lesen ignoriert.
  - Gerechnet wird in Ortszeit (Wanduhr): ein woechentlicher Termin um 09:00
    bleibt ueber die Sommerzeit hinweg um 09:00. Die Umrechnung nach UTC macht
    das Modell (PPG.Planner.Model).
  - Aufgeloest wird nur bis zum Ende des angefragten Bereichs; COUNT zaehlt ab
    DTSTART (DTSTART ist immer das erste Vorkommen).
  - Tage, die es im Monat nicht gibt (31., 29. Februar), entfallen wie in
    RFC 5545 vorgeschrieben; MonthEnd = mebLastDay verschiebt sie stattdessen
    auf den Monatsletzten. }

{$I ..\PPG.inc}

interface

uses
  System.SysUtils, System.DateUtils;

type
  TPPGRecurFreq = (rfNone, rfDaily, rfWeekly, rfMonthly, rfYearly);
  TPPGMonthEndBehavior = (mebSkip, mebLastDay);

  TPPGByDay = record
    Ordinal: Integer;   // 0 = jeder; 2 = zweiter; -1 = letzter
    Weekday: Integer;   // ISO: 1 = Montag .. 7 = Sonntag
  end;

  TPPGRecurrence = record
    Freq: TPPGRecurFreq;
    Interval: Integer;
    Count: Integer;            // 0 = unbegrenzt
    UntilDate: TDateTime;      // 0 = unbegrenzt (inklusive)
    UntilUtc: Boolean;         // UNTIL mit "Z": UntilDate ist UTC
    ByDay: TArray<TPPGByDay>;
    ByMonthDay: TArray<Integer>;
    ByMonth: TArray<Integer>;
    BySetPos: TArray<Integer>;
    WeekStart: Integer;        // ISO 1..7, Vorgabe Montag
    MonthEnd: TPPGMonthEndBehavior;
    procedure Clear;
    function IsRecurring: Boolean;
    /// RRULE-Text ohne "RRULE:" ('' = keine Wiederholung).
    function ToString: string;
    class function Parse(const S: string): TPPGRecurrence; static;
    class function TryParse(const S: string; out R: TPPGRecurrence): Boolean; static;
    /// Beginn aller Vorkommen (Ortszeit) in [AFrom, ATo). Start = DTSTART.
    /// UntilDate muss in derselben Zeit wie Start sein (siehe UntilUtc).
    function Expand(Start, AFrom, ATo: TDateTime; const ExDates: array of TDateTime;
      MaxCount: Integer = 100000): TArray<TDateTime>;
  end;

/// Datum/Zeit im iCalendar-Format: 20261231, 20261231T235959, ...Z.
function PPGParseICalDateTime(const S: string; out D: TDateTime; out IsUtc, IsDate: Boolean): Boolean;
function PPGFormatICalDateTime(D: TDateTime; IsUtc, IsDate: Boolean): string;

implementation

uses
  System.Generics.Collections, System.Generics.Defaults, PPG.Types, PPG.Exceptions, PPG.Lang,
  PPG.Consts;

const
  DayCodes: array[1..7] of string = ('MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU');
  FreqCodes: array[TPPGRecurFreq] of string = ('', 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY');

function IsoDow(D: TDateTime): Integer;
begin
  Result := DayOfTheWeek(D); // 1 = Montag
end;

function PPGParseICalDateTime(const S: string; out D: TDateTime; out IsUtc, IsDate: Boolean): Boolean;
var
  T: string;
  Y, M, Dd, H, Mi, Se: Integer;
begin
  Result := False;
  T := UpperCase(Trim(S));
  IsUtc := (T <> '') and (T[Length(T)] = 'Z');
  if IsUtc then
    Delete(T, Length(T), 1);
  IsDate := Length(T) = 8;
  if not (IsDate or ((Length(T) = 15) and (T[9] = 'T'))) then
    Exit;
  if not TryStrToInt(Copy(T, 1, 4), Y) or not TryStrToInt(Copy(T, 5, 2), M) or
    not TryStrToInt(Copy(T, 7, 2), Dd) then
    Exit;
  H := 0;
  Mi := 0;
  Se := 0;
  if not IsDate and (not TryStrToInt(Copy(T, 10, 2), H) or not TryStrToInt(Copy(T, 12, 2), Mi) or
    not TryStrToInt(Copy(T, 14, 2), Se)) then
    Exit;
  if Se = 60 then
    Se := 59; // Schaltsekunde
  Result := TryEncodeDateTime(Y, M, Dd, H, Mi, Se, 0, D);
end;

function PPGFormatICalDateTime(D: TDateTime; IsUtc, IsDate: Boolean): string;
begin
  if IsDate then
    Result := FormatDateTime('yyyymmdd', D)
  else
  begin
    Result := FormatDateTime('yyyymmdd"T"hhnnss', D);
    if IsUtc then
      Result := Result + 'Z';
  end;
end;

{ TPPGRecurrence }

procedure TPPGRecurrence.Clear;
begin
  Freq := rfNone;
  Interval := 1;
  Count := 0;
  UntilDate := 0;
  UntilUtc := False;
  ByDay := nil;
  ByMonthDay := nil;
  ByMonth := nil;
  BySetPos := nil;
  WeekStart := 1;
  MonthEnd := mebSkip;
end;

function TPPGRecurrence.IsRecurring: Boolean;
begin
  Result := Freq <> rfNone;
end;

function JoinInts(const A: TArray<Integer>): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(A) do
  begin
    if I > 0 then
      Result := Result + ',';
    Result := Result + IntToStr(A[I]);
  end;
end;

function TPPGRecurrence.ToString: string;
var
  I: Integer;
  S: string;
begin
  Result := '';
  if Freq = rfNone then
    Exit;
  Result := 'FREQ=' + FreqCodes[Freq];
  if Interval > 1 then
    Result := Result + ';INTERVAL=' + IntToStr(Interval);
  if Count > 0 then
    Result := Result + ';COUNT=' + IntToStr(Count);
  if UntilDate > 0 then
    Result := Result + ';UNTIL=' + PPGFormatICalDateTime(UntilDate, UntilUtc, False);
  if Length(ByDay) > 0 then
  begin
    S := '';
    for I := 0 to High(ByDay) do
    begin
      if I > 0 then
        S := S + ',';
      if ByDay[I].Ordinal <> 0 then
        S := S + IntToStr(ByDay[I].Ordinal);
      S := S + DayCodes[ByDay[I].Weekday];
    end;
    Result := Result + ';BYDAY=' + S;
  end;
  if Length(ByMonthDay) > 0 then
    Result := Result + ';BYMONTHDAY=' + JoinInts(ByMonthDay);
  if Length(ByMonth) > 0 then
    Result := Result + ';BYMONTH=' + JoinInts(ByMonth);
  if Length(BySetPos) > 0 then
    Result := Result + ';BYSETPOS=' + JoinInts(BySetPos);
  if WeekStart <> 1 then
    Result := Result + ';WKST=' + DayCodes[WeekStart];
end;

function ParseIntList(const S: string; Lo, Hi: Integer; out A: TArray<Integer>): Boolean;
var
  Parts: TArray<string>;
  I, V: Integer;
begin
  Parts := PPGSplitString(S, ',', False);
  SetLength(A, Length(Parts));
  for I := 0 to High(Parts) do
  begin
    if not TryStrToInt(Trim(Parts[I]), V) or (V = 0) or (Abs(V) < Lo) or (Abs(V) > Hi) then
      Exit(False);
    A[I] := V;
  end;
  Result := Length(A) > 0;
end;

function DayCodeIndex(const C: string): Integer;
var
  I: Integer;
begin
  for I := 1 to 7 do
    if SameText(DayCodes[I], C) then
      Exit(I);
  Result := 0;
end;

class function TPPGRecurrence.TryParse(const S: string; out R: TPPGRecurrence): Boolean;
var
  T, Name, Value, Code: string;
  Parts, Days: TArray<string>;
  I, P, V, D: Integer;
  F: TPPGRecurFreq;
  IsUtc, IsDate: Boolean;
begin
  R.Clear;
  Result := False;
  T := Trim(S);
  if SameText(Copy(T, 1, 6), 'RRULE:') then
    Delete(T, 1, 6);
  if T = '' then
    Exit(True); // keine Wiederholung
  Parts := PPGSplitString(T, ';', True);
  for I := 0 to High(Parts) do
  begin
    P := Pos('=', Parts[I]);
    if P = 0 then
      Continue;
    Name := UpperCase(Trim(Copy(Parts[I], 1, P - 1)));
    Value := UpperCase(Trim(Copy(Parts[I], P + 1, MaxInt)));
    if Name = 'FREQ' then
    begin
      R.Freq := rfNone;
      for F := rfDaily to rfYearly do
        if FreqCodes[F] = Value then
          R.Freq := F;
      if R.Freq = rfNone then
        Exit; // HOURLY u. ae. nicht unterstuetzt
    end
    else if Name = 'INTERVAL' then
    begin
      if not TryStrToInt(Value, V) or (V < 1) then
        Exit;
      R.Interval := V;
    end
    else if Name = 'COUNT' then
    begin
      if not TryStrToInt(Value, V) or (V < 1) then
        Exit;
      R.Count := V;
    end
    else if Name = 'UNTIL' then
    begin
      if not PPGParseICalDateTime(Value, R.UntilDate, IsUtc, IsDate) then
        Exit;
      R.UntilUtc := IsUtc;
      if IsDate then
        R.UntilDate := R.UntilDate + EncodeTime(23, 59, 59, 0); // ganzer Tag inklusive
    end
    else if Name = 'BYDAY' then
    begin
      Days := PPGSplitString(Value, ',', False);
      SetLength(R.ByDay, Length(Days));
      for D := 0 to High(Days) do
      begin
        Code := Trim(Days[D]);
        if Length(Code) < 2 then
          Exit;
        R.ByDay[D].Weekday := DayCodeIndex(Copy(Code, Length(Code) - 1, 2));
        if R.ByDay[D].Weekday = 0 then
          Exit;
        R.ByDay[D].Ordinal := 0;
        if Length(Code) > 2 then
        begin
          if not TryStrToInt(Copy(Code, 1, Length(Code) - 2), V) or (V = 0) or (Abs(V) > 53) then
            Exit;
          R.ByDay[D].Ordinal := V;
        end;
      end;
    end
    else if Name = 'BYMONTHDAY' then
    begin
      if not ParseIntList(Value, 1, 31, R.ByMonthDay) then
        Exit;
    end
    else if Name = 'BYMONTH' then
    begin
      if not ParseIntList(Value, 1, 12, R.ByMonth) then
        Exit;
      for V in R.ByMonth do
        if V < 0 then
          Exit;
    end
    else if Name = 'BYSETPOS' then
    begin
      if not ParseIntList(Value, 1, 366, R.BySetPos) then
        Exit;
    end
    else if Name = 'WKST' then
    begin
      R.WeekStart := DayCodeIndex(Value);
      if R.WeekStart = 0 then
        Exit;
    end;
    // andere Teile (BYHOUR, BYWEEKNO ...) werden ignoriert
  end;
  Result := R.Freq <> rfNone;
end;

class function TPPGRecurrence.Parse(const S: string): TPPGRecurrence;
begin
  if not TryParse(S, Result) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGRRuleInvalid), [S]);
end;

function TPPGRecurrence.Expand(Start, AFrom, ATo: TDateTime; const ExDates: array of TDateTime;
  MaxCount: Integer): TArray<TDateTime>;
var
  Res: TList<TDateTime>;
  Cand: TList<TDateTime>;
  TimeOfDay: TDateTime;
  D0, PStart: TDateTime;
  Y0, M0, Dd0: Word;
  N, P, Guard, I: Integer;
  Stop: Boolean;

  function InList(const A: TArray<Integer>; V: Integer): Boolean;
  var
    X: Integer;
  begin
    Result := Length(A) = 0;
    for X in A do
      if X = V then
        Exit(True);
  end;

  function DayMatches(D: TDateTime): Boolean;
  var
    X: Integer;
    Dim, Md: Integer;
  begin
    // Als Einschraenkung (DAILY, WEEKLY): Monat, Monatstag, Wochentag
    Result := InList(ByMonth, MonthOf(D));
    if not Result then
      Exit;
    if Length(ByMonthDay) > 0 then
    begin
      Result := False;
      Dim := DaysInMonth(D);
      for X in ByMonthDay do
      begin
        if X > 0 then
          Md := X
        else
          Md := Dim + X + 1;
        if Md = DayOf(D) then
          Result := True;
      end;
      if not Result then
        Exit;
    end;
    if Length(ByDay) > 0 then
    begin
      Result := False;
      for X := 0 to High(ByDay) do
        if ByDay[X].Weekday = IsoDow(D) then
          Result := True;
    end;
  end;

  procedure AddDay(D: TDateTime);
  begin
    if Cand.IndexOf(D) < 0 then
      Cand.Add(D);
  end;

  procedure MonthDays(Y, M: Integer);
  var
    Dim, X, Md, K, Cnt: Integer;
    First, D: TDateTime;
    Days: TList<TDateTime>;
    OrdinalOk: Boolean;
  begin
    Dim := DaysInAMonth(Y, M);
    First := EncodeDate(Y, M, 1);
    if Length(ByMonthDay) > 0 then
    begin
      for X in ByMonthDay do
      begin
        if X > 0 then
          Md := X
        else
          Md := Dim + X + 1;
        if (Md > Dim) and (MonthEnd = mebLastDay) then
          Md := Dim;
        if (Md < 1) or (Md > Dim) then
          Continue; // RFC 5545: Tag gibt es nicht -> entfaellt
        D := First + Md - 1;
        if Length(ByDay) > 0 then
        begin
          OrdinalOk := False;
          for K := 0 to High(ByDay) do
            if ByDay[K].Weekday = IsoDow(D) then
              OrdinalOk := True;
          if not OrdinalOk then
            Continue;
        end;
        AddDay(D);
      end;
    end
    else if Length(ByDay) > 0 then
    begin
      Days := TList<TDateTime>.Create;
      try
        for K := 0 to High(ByDay) do
        begin
          Days.Clear;
          for X := 0 to Dim - 1 do
            if IsoDow(First + X) = ByDay[K].Weekday then
              Days.Add(First + X);
          Cnt := Days.Count;
          if ByDay[K].Ordinal = 0 then
            for X := 0 to Cnt - 1 do
              AddDay(Days[X])
          else if (ByDay[K].Ordinal > 0) and (ByDay[K].Ordinal <= Cnt) then
            AddDay(Days[ByDay[K].Ordinal - 1])
          else if (ByDay[K].Ordinal < 0) and (-ByDay[K].Ordinal <= Cnt) then
            AddDay(Days[Cnt + ByDay[K].Ordinal]);
        end;
      finally
        Days.Free;
      end;
    end
    else
    begin
      Md := Dd0;
      if (Md > Dim) and (MonthEnd = mebLastDay) then
        Md := Dim;
      if Md <= Dim then
        AddDay(First + Md - 1);
    end;
  end;

  procedure YearDaysByWeekday(Y: Integer);
  var
    K, X, Cnt: Integer;
    D, First: TDateTime;
    Days: TList<TDateTime>;
  begin
    // YEARLY mit BYDAY ohne BYMONTH: Ordnungszahl bezogen auf das Jahr
    First := EncodeDate(Y, 1, 1);
    Days := TList<TDateTime>.Create;
    try
      for K := 0 to High(ByDay) do
      begin
        Days.Clear;
        D := First;
        while YearOf(D) = Y do
        begin
          if IsoDow(D) = ByDay[K].Weekday then
            Days.Add(D);
          D := D + 1;
        end;
        Cnt := Days.Count;
        if ByDay[K].Ordinal = 0 then
          for X := 0 to Cnt - 1 do
            AddDay(Days[X])
        else if (ByDay[K].Ordinal > 0) and (ByDay[K].Ordinal <= Cnt) then
          AddDay(Days[ByDay[K].Ordinal - 1])
        else if (ByDay[K].Ordinal < 0) and (-ByDay[K].Ordinal <= Cnt) then
          AddDay(Days[Cnt + ByDay[K].Ordinal]);
      end;
    finally
      Days.Free;
    end;
  end;

  procedure ApplySetPos;
  var
    Sel: TList<TDateTime>;
    X, Idx: Integer;
  begin
    if Length(BySetPos) = 0 then
      Exit;
    Sel := TList<TDateTime>.Create;
    try
      for X in BySetPos do
      begin
        if X > 0 then
          Idx := X - 1
        else
          Idx := Cand.Count + X;
        if (Idx >= 0) and (Idx < Cand.Count) and (Sel.IndexOf(Cand[Idx]) < 0) then
          Sel.Add(Cand[Idx]);
      end;
      Cand.Clear;
      Cand.AddRange(Sel);
      Cand.Sort;
    finally
      Sel.Free;
    end;
  end;

  function IsExcluded(DT: TDateTime): Boolean;
  var
    X: Integer;
  begin
    for X := 0 to High(ExDates) do
      if Abs(ExDates[X] - DT) < 1 / SecsPerDay then
        Exit(True);
    Result := False;
  end;

  procedure Emit(DT: TDateTime);
  begin
    // Bereich und Grenzen; Stop = alle weiteren Vorkommen liegen dahinter
    if (UntilDate > 0) and (DT > UntilDate + 1 / SecsPerDay / 2) then
    begin
      Stop := True;
      Exit;
    end;
    Inc(N);
    if (Count > 0) and (N > Count) then
    begin
      Stop := True;
      Exit;
    end;
    if DT >= ATo then
    begin
      Stop := True;
      Exit;
    end;
    if (DT >= AFrom) and not IsExcluded(DT) and (Res.Count < MaxCount) then
      Res.Add(DT);
  end;

  var
    K, Mo, Yr, MonthIdx, W: Integer;
    Week0: TDateTime;
begin
  SetLength(Result, 0);
  Res := TList<TDateTime>.Create;
  Cand := TList<TDateTime>.Create;
  try
    Stop := False;
    N := 0;
    // DTSTART ist immer das erste Vorkommen
    Emit(Start);
    if (Freq = rfNone) or Stop then
    begin
      Result := Res.ToArray;
      Exit;
    end;
    TimeOfDay := Frac(Start);
    D0 := Trunc(Start);
    DecodeDate(D0, Y0, M0, Dd0);
    W := (7 + IsoDow(D0) - WeekStart) mod 7;
    Week0 := D0 - W;
    P := 0;
    // Ohne COUNT haengt kein Vorkommen von den frueheren ab: direkt bis kurz
    // vor AFrom springen, statt bei jedem Aufruf ab DTSTART zu zaehlen. Die
    // uebersprungenen Zeitraeume enden alle vor AFrom.
    if (Count = 0) and (Interval > 0) and (AFrom > D0 + 1) then
    begin
      case Freq of
        rfDaily: P := Trunc((AFrom - D0) / Interval) - 1;
        rfWeekly: P := Trunc((AFrom - Week0) / (7 * Interval)) - 1;
        rfMonthly: P := ((YearOf(AFrom) * 12 + MonthOf(AFrom) - 1) - (Y0 * 12 + M0 - 1)) div
          Interval - 1;
        rfYearly: P := (YearOf(AFrom) - Y0) div Interval - 1;
      end;
      if P < 0 then
        P := 0;
    end;
    Guard := 0;
    PStart := D0;
    while not Stop and (Guard < 200000) do
    begin
      Inc(Guard);
      Cand.Clear;
      case Freq of
        rfDaily:
          begin
            PStart := D0 + P * Interval;
            if DayMatches(PStart) then
              AddDay(PStart);
          end;
        rfWeekly:
          begin
            PStart := Week0 + 7 * P * Interval;
            if Length(ByDay) > 0 then
            begin
              for K := 0 to 6 do
                if DayMatches(PStart + K) then
                  AddDay(PStart + K);
            end
            else if InList(ByMonth, MonthOf(PStart + W)) then
              AddDay(PStart + W);
          end;
        rfMonthly:
          begin
            MonthIdx := (Y0 * 12 + M0 - 1) + P * Interval;
            Yr := MonthIdx div 12;
            Mo := MonthIdx mod 12 + 1;
            PStart := EncodeDate(Yr, Mo, 1);
            if InList(ByMonth, Mo) then
              MonthDays(Yr, Mo);
          end;
        rfYearly:
          begin
            Yr := Y0 + P * Interval;
            if Yr > 9998 then
              Break;
            PStart := EncodeDate(Yr, 1, 1);
            if Length(ByMonth) > 0 then
            begin
              for Mo in ByMonth do
                MonthDays(Yr, Mo);
            end
            else if (Length(ByDay) > 0) and (Length(ByMonthDay) = 0) then
              YearDaysByWeekday(Yr)
            else if Length(ByMonthDay) > 0 then
            begin
              // RFC 5545: BYMONTHDAY ohne BYMONTH gilt in jedem Monat
              for Mo := 1 to 12 do
                MonthDays(Yr, Mo);
            end
            else
              MonthDays(Yr, M0);
          end;
      end;
      Cand.Sort;
      ApplySetPos;
      for I := 0 to Cand.Count - 1 do
      begin
        if Cand[I] + TimeOfDay <= Start then
          Continue; // vor bzw. gleich DTSTART (schon gezaehlt)
        Emit(Cand[I] + TimeOfDay);
        if Stop then
          Break;
      end;
      // Zeitraum liegt ganz hinter dem Bereich: fertig
      if PStart > ATo + 1 then
        Break;
      Inc(P);
    end;
    Result := Res.ToArray;
  finally
    Cand.Free;
    Res.Free;
  end;
end;

end.
