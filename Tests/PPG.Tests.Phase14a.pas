unit PPG.Tests.Phase14a;

{ Tests fuer Phase 14a (Kern des Planers): Zeitzonen und Sommerzeit,
  Wiederholungen (Beispiele aus RFC 5545), Anordnung, Modell, iCalendar. }

interface

uses
  TestFramework, Winapi.Windows, System.Classes, System.SysUtils, System.DateUtils,
  PPG.TimeZones, PPG.Planner.Recurrence, PPG.Planner.Layout, PPG.Planner.Model,
  PPG.Planner.ICal, PPG.Markup.Parser;

type
  TTimeZoneTests = class(TTestCase)
  private
    function Berlin: IPPGTimeZone;
  published
    procedure BerlinSummerAndWinter;
    procedure SpringGapMovesForward;
    procedure AutumnHourTakesFirst;
    procedure DayLengths;
    procedure NewYorkRules;
    procedure UtcIanaAndUnknown;
  end;

  TRecurrenceTests = class(TTestCase)
  private
    function Dates(const Rule: string; Start: TDateTime; Count: Integer = 100): string;
  published
    procedure DailyCount;
    procedure EveryOtherDayForever;
    procedure EveryTenDays;
    procedure WeeklyCount;
    procedure WeeklyTuThUntil;
    procedure BiweeklyMoWeFr;
    procedure MonthlyFirstFriday;
    procedure FirstAndLastSunday;
    procedure ThirdToLastDay;
    procedure YearlyJuneJuly;
    procedure LastWorkdayBySetPos;
    procedure MonthEndSkipOrLastDay;
    procedure LeapDayYearly;
    procedure YearlyTwentiethMonday;
    procedure ExDatesAndRange;
    procedure ParseAndFormat;
  end;

  TLayoutTests = class(TTestCase)
  published
    procedure ColumnsOverlap;
    procedure ColumnsReuseAndGroups;
    procedure ColSpanUsesFreeColumns;
    procedure ZeroDurationAndRows;
  end;

  TModelTests = class(TTestCase)
  private
    FItems: TPPGAppointments;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure StoresUtcShowsLocal;
    procedure LocalModeAndAllDay;
    procedure WeeklyKeepsWallClockOverDst;
    procedure ExceptionsAndDetach;
    procedure RangeQuery;
    procedure ICalRoundTrip;
    procedure ICalImportZonesAndDuration;
    procedure ICalFolding;
    procedure ICalImportIsPlainTextAndComplete;
  end;

implementation

uses
  PPG.Exceptions;

function DT(Y, M, D: Word; H: Word = 0; N: Word = 0): TDateTime;
begin
  Result := EncodeDateTime(Y, M, D, H, N, 0, 0);
end;

{ TTimeZoneTests }

function TTimeZoneTests.Berlin: IPPGTimeZone;
begin
  Result := PPGFindTimeZone('Europe/Berlin');
  CheckNotNull(Result, 'W. Europe Standard Time in der Registry');
end;

procedure TTimeZoneTests.BerlinSummerAndWinter;
var
  Z: IPPGTimeZone;
begin
  Z := Berlin;
  CheckEquals(DT(2026, 7, 1, 8), Z.ToUtc(DT(2026, 7, 1, 10)), 1E-9, 'Sommer +2');
  CheckEquals(DT(2026, 1, 15, 9), Z.ToUtc(DT(2026, 1, 15, 10)), 1E-9, 'Winter +1');
  CheckEquals(DT(2026, 7, 1, 10), Z.ToLocal(DT(2026, 7, 1, 8)), 1E-9);
  CheckEquals(120, Z.OffsetMinutes(DT(2026, 7, 1, 8)));
  CheckEquals(60, Z.OffsetMinutes(DT(2026, 1, 1)));
end;

procedure TTimeZoneTests.SpringGapMovesForward;
var
  Z: IPPGTimeZone;
begin
  // 29.03.2026: 02:00 -> 03:00; 02:30 gibt es nicht
  Z := Berlin;
  CheckEquals(DT(2026, 3, 29, 0, 30), Z.ToUtc(DT(2026, 3, 29, 1, 30)), 1E-9);
  CheckEquals(DT(2026, 3, 29, 1, 30), Z.ToUtc(DT(2026, 3, 29, 2, 30)), 1E-9,
    'Luecke: Winter-Abstand');
  CheckEquals(DT(2026, 3, 29, 3, 30), Z.ToLocal(Z.ToUtc(DT(2026, 3, 29, 2, 30))), 1E-9,
    '02:30 wird 03:30');
  CheckEquals(DT(2026, 3, 29, 1), Z.ToUtc(DT(2026, 3, 29, 3)), 1E-9, '03:00 MESZ = 01:00 UTC');
  CheckEquals(DT(2026, 3, 29, 3), Z.ToLocal(DT(2026, 3, 29, 1)), 1E-9);
  CheckEquals(DT(2026, 3, 29, 1, 59), Z.ToLocal(DT(2026, 3, 29, 0, 59)), 1E-9);
end;

procedure TTimeZoneTests.AutumnHourTakesFirst;
var
  Z: IPPGTimeZone;
begin
  // 25.10.2026: 03:00 -> 02:00; 02:30 gibt es zweimal
  Z := Berlin;
  CheckEquals(DT(2026, 10, 25, 0, 30), Z.ToUtc(DT(2026, 10, 25, 2, 30)), 1E-9, 'erste (MESZ)');
  CheckEquals(DT(2026, 10, 25, 2, 30), Z.ToLocal(DT(2026, 10, 25, 0, 30)), 1E-9);
  CheckEquals(DT(2026, 10, 25, 2, 30), Z.ToLocal(DT(2026, 10, 25, 1, 30)), 1E-9, 'zweite (MEZ)');
  CheckEquals(DT(2026, 10, 25, 2), Z.ToUtc(DT(2026, 10, 25, 3)), 1E-9);
end;

procedure TTimeZoneTests.DayLengths;
var
  Z: IPPGTimeZone;
begin
  Z := Berlin;
  CheckEquals(23, Round((Z.ToUtc(DT(2026, 3, 30)) - Z.ToUtc(DT(2026, 3, 29))) * 24), '23 Stunden');
  CheckEquals(25, Round((Z.ToUtc(DT(2026, 10, 26)) - Z.ToUtc(DT(2026, 10, 25))) * 24), '25 Stunden');
  CheckEquals(24, Round((Z.ToUtc(DT(2026, 6, 2)) - Z.ToUtc(DT(2026, 6, 1))) * 24));
end;

procedure TTimeZoneTests.NewYorkRules;
var
  Z: IPPGTimeZone;
begin
  Z := PPGFindTimeZone('America/New_York');
  CheckNotNull(Z);
  CheckEquals('Eastern Standard Time', Z.Id);
  // 08.03.2026 02:00 -> 03:00, 01.11.2026 02:00 -> 01:00
  CheckEquals(DT(2026, 3, 8, 6, 30), Z.ToUtc(DT(2026, 3, 8, 1, 30)), 1E-9, 'vorher -5');
  CheckEquals(DT(2026, 3, 8, 7, 30), Z.ToUtc(DT(2026, 3, 8, 3, 30)), 1E-9, 'nachher -4');
  CheckEquals(DT(2026, 11, 1, 5, 30), Z.ToUtc(DT(2026, 11, 1, 1, 30)), 1E-9, 'doppelt: erste');
  CheckEquals(DT(2026, 11, 1, 1, 30), Z.ToLocal(DT(2026, 11, 1, 6, 30)), 1E-9, 'zweite');
  CheckEquals(-240, Z.OffsetMinutes(DT(2026, 7, 1)));
end;

procedure TTimeZoneTests.UtcIanaAndUnknown;
var
  Info: TTimeZoneInformation;
  Z: IPPGTimeZone;
begin
  CheckEquals(DT(2026, 7, 1, 10), PPGUtcTimeZone.ToUtc(DT(2026, 7, 1, 10)), 1E-9);
  CheckEquals('UTC', PPGFindTimeZone('Etc/UTC').Id);
  CheckNull(PPGFindTimeZone('Mars/Olympus'));
  CheckEquals('Europe/Berlin', PPGIanaOfWindowsZone('W. Europe Standard Time'));
  // Zone ohne Sommerzeit aus festen Regeln
  FillChar(Info, SizeOf(Info), 0);
  Info.Bias := -540; // UTC+9
  Z := PPGTimeZoneFromInfo('Tokio', Info);
  CheckEquals(DT(2026, 7, 1, 1), Z.ToUtc(DT(2026, 7, 1, 10)), 1E-9);
  CheckEquals(540, Z.OffsetMinutes(DT(2026, 1, 1)));
end;

{ TRecurrenceTests }

function TRecurrenceTests.Dates(const Rule: string; Start: TDateTime; Count: Integer): string;
var
  R: TPPGRecurrence;
  A: TArray<TDateTime>;
  I: Integer;
begin
  R := TPPGRecurrence.Parse(Rule);
  A := R.Expand(Start, Start, Start + 3660, [], Count);
  Result := '';
  for I := 0 to High(A) do
  begin
    if I > 0 then
      Result := Result + ' ';
    Result := Result + FormatDateTime('yyyymmdd', A[I]);
  end;
end;

procedure TRecurrenceTests.DailyCount;
begin
  CheckEquals('19970902 19970903 19970904 19970905 19970906 19970907 19970908 19970909 ' +
    '19970910 19970911', Dates('FREQ=DAILY;COUNT=10', DT(1997, 9, 2, 9)));
end;

procedure TRecurrenceTests.EveryOtherDayForever;
begin
  CheckEquals('19970902 19970904 19970906 19970908', Dates('FREQ=DAILY;INTERVAL=2',
    DT(1997, 9, 2, 9), 4));
end;

procedure TRecurrenceTests.EveryTenDays;
begin
  CheckEquals('19970902 19970912 19970922 19971002 19971012',
    Dates('FREQ=DAILY;INTERVAL=10;COUNT=5', DT(1997, 9, 2, 9)));
end;

procedure TRecurrenceTests.WeeklyCount;
begin
  CheckEquals('19970902 19970909 19970916 19970923 19970930 19971007 19971014 19971021 ' +
    '19971028 19971104', Dates('FREQ=WEEKLY;COUNT=10', DT(1997, 9, 2, 9)));
end;

procedure TRecurrenceTests.WeeklyTuThUntil;
begin
  CheckEquals('19970902 19970904 19970909 19970911 19970916 19970918 19970923 19970925 ' +
    '19970930 19971002', Dates('FREQ=WEEKLY;UNTIL=19971007T000000Z;WKST=SU;BYDAY=TU,TH',
    DT(1997, 9, 2, 9)));
end;

procedure TRecurrenceTests.BiweeklyMoWeFr;
var
  S: string;
begin
  S := Dates('FREQ=WEEKLY;INTERVAL=2;UNTIL=19971224T000000Z;WKST=SU;BYDAY=MO,WE,FR',
    DT(1997, 9, 1, 9));
  CheckEquals(25, Length(S.Split([' '])), S);
  CheckEquals('19970901 19970903 19970905 19970915 19970917', Copy(S, 1, 44));
  CheckEquals('19971222', Copy(S, Length(S) - 7, 8), 'letzter');
end;

procedure TRecurrenceTests.MonthlyFirstFriday;
begin
  CheckEquals('19970905 19971003 19971107 19971205 19980102 19980206 19980306 19980403 ' +
    '19980501 19980605', Dates('FREQ=MONTHLY;COUNT=10;BYDAY=1FR', DT(1997, 9, 5, 9)));
end;

procedure TRecurrenceTests.FirstAndLastSunday;
begin
  CheckEquals('19970907 19970928 19971102 19971130 19980104 19980125 19980301 19980329 ' +
    '19980503 19980531', Dates('FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU',
    DT(1997, 9, 7, 9)));
end;

procedure TRecurrenceTests.ThirdToLastDay;
begin
  CheckEquals('19970928 19971029 19971128 19971229 19980129 19980226',
    Dates('FREQ=MONTHLY;BYMONTHDAY=-3', DT(1997, 9, 28, 9), 6));
end;

procedure TRecurrenceTests.YearlyJuneJuly;
begin
  CheckEquals('19970610 19970710 19980610 19980710 19990610 19990710 20000610 20000710 ' +
    '20010610 20010710', Dates('FREQ=YEARLY;COUNT=10;BYMONTH=6,7', DT(1997, 6, 10, 9)));
end;

procedure TRecurrenceTests.LastWorkdayBySetPos;
begin
  CheckEquals('19970930 19971031 19971128 19971231 19980130 19980227 19980331',
    Dates('FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1', DT(1997, 9, 30, 9), 7));
end;

procedure TRecurrenceTests.MonthEndSkipOrLastDay;
var
  R: TPPGRecurrence;
  A: TArray<TDateTime>;
begin
  CheckEquals('20260131 20260331 20260531 20260731 20260831',
    Dates('FREQ=MONTHLY;COUNT=5', DT(2026, 1, 31, 9)), 'RFC: 31. entfaellt');
  R := TPPGRecurrence.Parse('FREQ=MONTHLY;COUNT=5');
  R.MonthEnd := mebLastDay;
  A := R.Expand(DT(2026, 1, 31, 9), DT(2026, 1, 1), DT(2027, 1, 1), []);
  CheckEquals(5, Length(A));
  CheckEquals(DT(2026, 2, 28, 9), A[1], 1E-9, 'Monatsletzter');
  CheckEquals(DT(2026, 4, 30, 9), A[3], 1E-9);
end;

procedure TRecurrenceTests.LeapDayYearly;
begin
  CheckEquals('20240229 20280229 20320229', Dates('FREQ=YEARLY;COUNT=3', DT(2024, 2, 29, 9)),
    '29.02. nur in Schaltjahren');
end;

procedure TRecurrenceTests.YearlyTwentiethMonday;
begin
  CheckEquals('19970519 19980518 19990517', Dates('FREQ=YEARLY;BYDAY=20MO;COUNT=3',
    DT(1997, 5, 19, 9)));
end;

procedure TRecurrenceTests.ExDatesAndRange;
var
  R: TPPGRecurrence;
  A: TArray<TDateTime>;
begin
  R := TPPGRecurrence.Parse('FREQ=DAILY');
  A := R.Expand(DT(2026, 1, 1, 9), DT(2026, 6, 1), DT(2026, 6, 4), [DT(2026, 6, 2, 9)]);
  CheckEquals(2, Length(A), 'nur der Bereich, ohne Ausnahme');
  CheckEquals(DT(2026, 6, 1, 9), A[0], 1E-9);
  CheckEquals(DT(2026, 6, 3, 9), A[1], 1E-9);
  R := TPPGRecurrence.Parse('FREQ=DAILY;COUNT=3');
  A := R.Expand(DT(2026, 1, 1, 9), DT(2026, 6, 1), DT(2026, 7, 1), []);
  CheckEquals(0, Length(A), 'COUNT zaehlt ab DTSTART');
  R.Clear;
  A := R.Expand(DT(2026, 1, 1, 9), DT(2026, 1, 1), DT(2026, 1, 2), []);
  CheckEquals(1, Length(A), 'ohne Regel: nur DTSTART');
end;

procedure TRecurrenceTests.ParseAndFormat;
var
  R: TPPGRecurrence;
begin
  R := TPPGRecurrence.Parse('RRULE:FREQ=MONTHLY;INTERVAL=2;BYDAY=1SU,-1SU;COUNT=10;WKST=SU');
  CheckEquals('FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU;WKST=SU', R.ToString);
  CheckEquals(2, R.Interval);
  CheckEquals(-1, R.ByDay[1].Ordinal);
  CheckEquals(7, R.ByDay[1].Weekday);
  R := TPPGRecurrence.Parse('FREQ=WEEKLY;UNTIL=20261231');
  CheckEquals(DT(2026, 12, 31, 23, 59) + 59 / SecsPerDay, R.UntilDate, 1E-6, 'Datum: ganzer Tag');
  CheckFalse(R.UntilUtc);
  CheckFalse(TPPGRecurrence.TryParse('FREQ=HOURLY', R), 'nicht unterstuetzt');
  CheckFalse(TPPGRecurrence.TryParse('FREQ=DAILY;INTERVAL=0', R));
  CheckFalse(TPPGRecurrence.TryParse('FREQ=WEEKLY;BYDAY=XX', R));
  CheckFalse(TPPGRecurrence.TryParse('INTERVAL=2', R), 'FREQ fehlt');
  CheckTrue(TPPGRecurrence.TryParse('', R));
  CheckFalse(R.IsRecurring);
  CheckTrue(TPPGRecurrence.TryParse('FREQ=DAILY;BYHOUR=9', R), 'unbekannte Teile ignoriert');
  try
    TPPGRecurrence.Parse('FREQ=NIE');
    Fail('Fehler erwartet');
  except
    on E: EPPGError do
      CheckTrue(Pos('FREQ=NIE', E.Message) > 0);
  end;
end;

{ TLayoutTests }

procedure TLayoutTests.ColumnsOverlap;
var
  S: TArray<TPPGSpanSlot>;
begin
  S := PPGLayoutColumns([PPGSpan(DT(2026, 1, 1, 9), DT(2026, 1, 1, 12)),
    PPGSpan(DT(2026, 1, 1, 10), DT(2026, 1, 1, 11)),
    PPGSpan(DT(2026, 1, 1, 10, 30), DT(2026, 1, 1, 13))]);
  CheckEquals(0, S[0].Column);
  CheckEquals(1, S[1].Column);
  CheckEquals(2, S[2].Column);
  CheckEquals(3, S[0].ColumnCount);
  CheckEquals(3, S[2].ColumnCount);
end;

procedure TLayoutTests.ColumnsReuseAndGroups;
var
  S: TArray<TPPGSpanSlot>;
begin
  S := PPGLayoutColumns([PPGSpan(DT(2026, 1, 1, 9), DT(2026, 1, 1, 11)),
    PPGSpan(DT(2026, 1, 1, 10), DT(2026, 1, 1, 12)),
    PPGSpan(DT(2026, 1, 1, 11), DT(2026, 1, 1, 13)),
    PPGSpan(DT(2026, 1, 1, 14), DT(2026, 1, 1, 15))]);
  CheckEquals(0, S[2].Column, 'Spalte 0 ist ab 11 Uhr frei');
  CheckEquals(2, S[0].ColumnCount);
  CheckEquals(2, S[2].ColumnCount, 'gleiche Gruppe');
  CheckEquals(1, S[3].ColumnCount, 'eigene Gruppe');
  CheckEquals(0, S[3].Column);
end;

procedure TLayoutTests.ColSpanUsesFreeColumns;
var
  S: TArray<TPPGSpanSlot>;
begin
  // G lang, H und I nacheinander in Spalte 1, J kurz in Spalte 2
  S := PPGLayoutColumns([PPGSpan(DT(2026, 1, 1, 9), DT(2026, 1, 1, 12)),
    PPGSpan(DT(2026, 1, 1, 9), DT(2026, 1, 1, 10)),
    PPGSpan(DT(2026, 1, 1, 10), DT(2026, 1, 1, 11)),
    PPGSpan(DT(2026, 1, 1, 9), DT(2026, 1, 1, 9, 30))]);
  CheckEquals(3, S[0].ColumnCount);
  CheckEquals(1, S[2].Column);
  CheckEquals(2, S[2].ColSpan, 'I darf in die freie Spalte 2');
  CheckEquals(1, S[1].ColSpan, 'H nicht: J liegt daneben');
  CheckEquals(1, S[0].ColSpan);
end;

procedure TLayoutTests.ZeroDurationAndRows;
var
  S: TArray<TPPGSpanSlot>;
  R: TArray<Integer>;
  N: Integer;
begin
  S := PPGLayoutColumns([PPGSpan(DT(2026, 1, 1, 9), DT(2026, 1, 1, 9)),
    PPGSpan(DT(2026, 1, 1, 9), DT(2026, 1, 1, 9))]);
  CheckEquals(2, S[0].ColumnCount, 'Dauer 0 zaehlt mit Mindestdauer');
  R := PPGLayoutRows([PPGSpan(DT(2026, 1, 1), DT(2026, 1, 4)),
    PPGSpan(DT(2026, 1, 2), DT(2026, 1, 3)),
    PPGSpan(DT(2026, 1, 4), DT(2026, 1, 5)),
    PPGSpan(DT(2026, 1, 3), DT(2026, 1, 6))], N);
  CheckEquals(2, N);
  CheckEquals(0, R[0]);
  CheckEquals(1, R[1]);
  CheckEquals(0, R[2], 'Zeile 0 ab dem 4. frei');
  CheckEquals(1, R[3]);
  R := PPGLayoutRows([], N);
  CheckEquals(0, N);
end;

{ TModelTests }

procedure TModelTests.SetUp;
begin
  inherited SetUp;
  FItems := TPPGAppointments.Create(nil);
  FItems.SetDisplayZone(PPGFindTimeZone('Europe/Berlin'));
end;

procedure TModelTests.TearDown;
begin
  FreeAndNil(FItems);
  inherited TearDown;
end;

procedure TModelTests.StoresUtcShowsLocal;
var
  A: TPPGAppointment;
begin
  A := FItems.AddAppointment(DT(2026, 7, 1, 10), DT(2026, 7, 1, 11), 'Besprechung');
  CheckEquals(DT(2026, 7, 1, 8), A.StartTime, 1E-9, 'gespeichert in UTC');
  CheckEquals(DT(2026, 7, 1, 10), A.Start, 1E-9, 'angezeigt lokal');
  CheckEquals(1, A.Id);
  CheckEquals(2, FItems.Add.Id, 'fortlaufend');
  CheckSame(A, FItems.FindById(1));
  FItems.SetDisplayZone(PPGFindTimeZone('America/New_York'));
  CheckEquals(DT(2026, 7, 1, 4), A.Start, 1E-9, 'andere Anzeige-Zone, gleicher Zeitpunkt');
end;

procedure TModelTests.LocalModeAndAllDay;
var
  A: TPPGAppointment;
begin
  A := FItems.Add;
  A.AllDay := True;
  A.Start := DT(2026, 7, 1);
  A.Finish := DT(2026, 7, 3);
  CheckEquals(DT(2026, 7, 1), A.StartTime, 1E-9, 'ganztaegig: Datum ohne Zone');
  FItems.TimeZoneMode := tzmLocal;
  A := FItems.AddAppointment(DT(2026, 7, 1, 10), DT(2026, 7, 1, 11), 'lokal');
  CheckEquals(DT(2026, 7, 1, 10), A.StartTime, 1E-9, 'tzmLocal: keine Umrechnung');
end;

procedure TModelTests.WeeklyKeepsWallClockOverDst;
var
  A: TPPGAppointment;
  O: TArray<TPPGOccurrence>;
begin
  // Montag 23.03.2026 09:00 MEZ, woechentlich; ab 30.03. Sommerzeit
  A := FItems.AddAppointment(DT(2026, 3, 23, 9), DT(2026, 3, 23, 10), 'Jour fixe');
  A.Recurrence := 'FREQ=WEEKLY;COUNT=3';
  O := FItems.GetOccurrences(DT(2026, 3, 1), DT(2026, 5, 1));
  CheckEquals(3, Length(O));
  CheckEquals(DT(2026, 3, 30, 9), O[1].Start, 1E-9, 'weiter 09:00 Ortszeit');
  CheckEquals(DT(2026, 3, 30, 10), O[1].Finish, 1E-9);
  CheckTrue(O[1].Recurring);
end;

procedure TModelTests.ExceptionsAndDetach;
var
  A, X: TPPGAppointment;
  O: TArray<TPPGOccurrence>;
begin
  A := FItems.AddAppointment(DT(2026, 6, 1, 9), DT(2026, 6, 1, 10), 'Standup');
  A.Recurrence := 'FREQ=DAILY;COUNT=5';
  A.AddException(DT(2026, 6, 2, 9));
  O := FItems.GetOccurrences(DT(2026, 6, 1), DT(2026, 6, 10));
  CheckEquals(4, Length(O), 'Ausnahme fehlt');
  CheckTrue(Pos('20260602T070000Z', A.ExDates) > 0, 'EXDATE in UTC: ' + A.ExDates);
  // Ein Vorkommen herausloesen und verschieben
  X := FItems.DetachOccurrence(O[1]); // 03.06.
  CheckEquals(A.Id, X.RecurrenceParent);
  CheckEquals('', X.Recurrence);
  X.Start := DT(2026, 6, 3, 14);
  X.Finish := DT(2026, 6, 3, 15);
  O := FItems.GetOccurrences(DT(2026, 6, 1), DT(2026, 6, 10));
  CheckEquals(4, Length(O), 'Serie 3 + Einzeltermin 1');
  CheckSame(X, O[1].Appointment, 'Einzeltermin nach Beginn einsortiert');
  CheckEquals(DT(2026, 6, 3, 14), O[1].Start, 1E-9);
end;

procedure TModelTests.RangeQuery;
var
  I: Integer;
  O: TArray<TPPGOccurrence>;
  A: TPPGAppointment;
begin
  // 50 000 Termine ueber ein Jahr; Abfrage einer Woche
  // Audit 11a #7: Laufzeit im Benchmark (Bench11, vorher 1000 ms im Test)
  FItems.BeginUpdate;
  try
    for I := 0 to 49999 do
    begin
      A := FItems.Add;
      A.StartTime := DT(2026, 1, 1) + (I mod 365) + (I mod 9) / 24;
      A.FinishTime := A.StartTime + 1 / 24;
    end;
  finally
    FItems.EndUpdate;
  end;
  O := FItems.GetOccurrences(DT(2026, 3, 2), DT(2026, 3, 9));
  CheckTrue((Length(O) > 900) and (Length(O) < 1100), IntToStr(Length(O)));
  // Mehrtaegiger Termin beruehrt den Bereich
  A := FItems.AddAppointment(DT(2025, 12, 1), DT(2026, 12, 31), 'Projekt');
  O := FItems.GetOccurrences(DT(2026, 3, 2), DT(2026, 3, 3));
  CheckTrue(O[0].Appointment = A, 'lang laufender Termin zuerst');
end;

procedure TModelTests.ICalRoundTrip;
var
  A, X: TPPGAppointment;
  S: string;
  Other: TPPGAppointments;
  O: TArray<TPPGOccurrence>;
begin
  A := FItems.AddAppointment(DT(2026, 6, 1, 9), DT(2026, 6, 1, 10), 'Sitzung; Raum, 3');
  A.Location := 'B'#$FC'ro';
  A.Body := '<b>Agenda</b>'#13#10'Punkt 2';
  A.Recurrence := 'FREQ=WEEKLY;COUNT=4';
  A.Category := 2;
  A.ResourceId := 7;
  O := FItems.GetOccurrences(DT(2026, 6, 1), DT(2026, 7, 1));
  X := FItems.DetachOccurrence(O[2]);
  X.Start := DT(2026, 6, 15, 11);
  X.Finish := DT(2026, 6, 15, 12);
  A := FItems.Add;
  A.AllDay := True;
  A.Subject := 'Urlaub';
  A.StartTime := DT(2026, 8, 1);
  A.FinishTime := DT(2026, 8, 15);
  S := PPGICalText(FItems, 'Team');
  CheckTrue(Pos('SUMMARY:Sitzung\; Raum\, 3', S) > 0);
  CheckTrue(Pos('DTSTART:20260601T070000Z', S) > 0, 'UTC mit Z');
  CheckTrue(Pos('DTSTART;VALUE=DATE:20260801', S) > 0);
  CheckTrue(Pos('RECURRENCE-ID:20260615T070000Z', S) > 0);
  CheckTrue(Pos('DESCRIPTION:Agenda\nPunkt 2', S) > 0, 'ohne Markup, Zeilenumbruch maskiert');
  Other := TPPGAppointments.Create(nil);
  try
    Other.SetDisplayZone(FItems.DisplayZone);
    CheckEquals(3, PPGLoadICalText(Other, S));
    CheckEquals('Sitzung; Raum, 3', Other[0].Subject);
    CheckEquals('B'#$FC'ro', Other[0].Location);
    CheckEquals(DT(2026, 6, 1, 7), Other[0].StartTime, 1E-9);
    CheckEquals(2, Other[0].Category);
    CheckEquals(7, Other[0].ResourceId);
    CheckEquals(Other[0].Id, Other[1].RecurrenceParent, 'Einzeltermin wieder der Serie zugeordnet');
    CheckTrue(Other[2].AllDay);
    CheckEquals(DT(2026, 8, 15), Other[2].FinishTime, 1E-9);
    O := Other.GetOccurrences(DT(2026, 6, 1), DT(2026, 7, 1));
    CheckEquals(4, Length(O), '3 Serie + 1 verschoben');
  finally
    Other.Free;
  end;
end;

procedure TModelTests.ICalImportZonesAndDuration;
const
  Ics =
    'BEGIN:VCALENDAR'#13#10'VERSION:2.0'#13#10 +
    'BEGIN:VEVENT'#13#10'UID:a'#13#10'DTSTART;TZID=America/New_York:20260701T090000'#13#10 +
    'DURATION:PT1H30M'#13#10'SUMMARY:NY'#13#10 +
    'BEGIN:VALARM'#13#10'TRIGGER:-PT15M'#13#10'SUMMARY:Erinnerung'#13#10'END:VALARM'#13#10 +
    'END:VEVENT'#13#10 +
    'BEGIN:VEVENT'#13#10'UID:b'#13#10'DTSTART:20260701T090000'#13#10 +
    'DTEND:20260701T100000'#13#10'SUMMARY:schwebend'#13#10'END:VEVENT'#13#10 +
    'BEGIN:VEVENT'#13#10'UID:c'#13#10'SUMMARY:ohne Beginn'#13#10'END:VEVENT'#13#10 +
    'END:VCALENDAR'#13#10;
begin
  CheckEquals(2, PPGLoadICalText(FItems, Ics), 'ohne DTSTART verworfen');
  CheckEquals(DT(2026, 7, 1, 13), FItems[0].StartTime, 1E-9, 'New York 09:00 = 13:00 UTC');
  CheckEquals(DT(2026, 7, 1, 14, 30), FItems[0].FinishTime, 1E-9, 'DURATION');
  CheckEquals('NY', FItems[0].Subject, 'VALARM ueberschreibt nicht');
  CheckEquals(DT(2026, 7, 1, 9), FItems[1].Start, 1E-9, 'ohne Zone = Anzeige-Zone');
  try
    PPGLoadICalText(FItems, 'kein Kalender');
    Fail('Fehler erwartet');
  except
    on E: EPPGError do
      CheckTrue(E.Message <> '');
  end;
end;

procedure TModelTests.ICalImportIsPlainTextAndComplete;
const
  Ics =
    'BEGIN:VCALENDAR'#13#10'VERSION:2.0'#13#10 +
    'BEGIN:VEVENT'#13#10'UID:a'#13#10'DTSTART:20260701T090000'#13#10 +
    'DTEND:20260701T100000'#13#10'SUMMARY:A'#13#10 +
    'DESCRIPTION:a<b>c</b> & d'#13#10'END:VEVENT'#13#10 +
    // abgeschnittene Datei: kein END:VEVENT
    'BEGIN:VEVENT'#13#10'UID:b'#13#10'SUMMARY:halb'#13#10;
begin
  // Audit 08.10.2026: DESCRIPTION landete unmaskiert im Markup-Body; ein
  // Termin ohne END:VEVENT blieb als leerer Termin am 30.12.1899 stehen.
  CheckEquals(1, PPGLoadICalText(FItems, Ics));
  CheckEquals(1, FItems.Count, 'abgeschnittener Termin verworfen');
  CheckEquals('a<b>c</b> & d', PPGStripMarkup(FItems[0].Body), 'Text bleibt Text');
  CheckTrue(Pos('<b>', FItems[0].Body) = 0, 'kein Fett-Tag im Markup');
end;

procedure TModelTests.ICalFolding;
var
  S: string;
  L: TStringList;
  I: Integer;
begin
  FItems.AddAppointment(DT(2026, 6, 1, 9), DT(2026, 6, 1, 10),
    StringOfChar('x', 60) + StringOfChar(Char($E4), 60));
  S := PPGICalText(FItems);
  L := TStringList.Create;
  try
    L.Text := S;
    for I := 0 to L.Count - 1 do
      CheckTrue(Length(TEncoding.UTF8.GetBytes(L[I])) <= 75, 'Zeile ' + IntToStr(I));
  finally
    L.Free;
  end;
  FItems.Clear;
  PPGLoadICalText(FItems, S);
  CheckEquals(StringOfChar('x', 60) + StringOfChar(Char($E4), 60), FItems[0].Subject, 'entfaltet');
end;

initialization
  RegisterTest('Phase14a', TTimeZoneTests.Suite);
  RegisterTest('Phase14a', TRecurrenceTests.Suite);
  RegisterTest('Phase14a', TLayoutTests.Suite);
  RegisterTest('Phase14a', TModelTests.Suite);

end.
