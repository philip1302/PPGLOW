unit PPG.TimeZones;

{ Zeitzonen fuer den Terminplaner (Phase 14a), ohne VCL.

  - IPPGTimeZone rechnet zwischen UTC und Ortszeit einer Zone. Die Regeln
    (Abstand zu UTC, Beginn/Ende der Sommerzeit) kommen aus der Registry
    (HKLM\...\Time Zones\<Id>\TZI) bzw. fuer die eigene Zone aus
    GetTimeZoneInformation.
  - Umstellungstage sind definiert:
    - Luecke (Fruehjahr, z. B. 02:30 in Berlin gibt es nicht): die Ortszeit
      wird mit dem Winter-Abstand gerechnet und landet damit in der Sommerzeit
      (02:30 -> 01:30 UTC = 03:30 MESZ) - wie RFC 5545 es fuer DTSTART verlangt.
    - Doppelte Stunde (Herbst, 02:30 gibt es zweimal): es gilt die erste
      (Sommerzeit).
  - Zonen ohne Sommerzeit (StandardDate.wMonth = 0) haben nur den Abstand.
  - IANA-Namen (Europe/Berlin, America/New_York ...) werden fuer die ueblichen
    Zonen auf Windows-Namen abgebildet (iCalendar). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.SysUtils;

type
  IPPGTimeZone = interface
    ['{4E1A7C93-2D58-4B06-9F3E-A61C0D8B7E25}']
    function ToUtc(Local: TDateTime): TDateTime;
    function ToLocal(Utc: TDateTime): TDateTime;
    /// Abstand zu UTC in Minuten zu einem UTC-Zeitpunkt (Berlin Sommer: +120).
    function OffsetMinutes(Utc: TDateTime): Integer;
    /// Windows-Name ('W. Europe Standard Time', 'UTC', 'Local').
    function Id: string;
  end;

/// Zone des Rechners.
function PPGLocalTimeZone: IPPGTimeZone;
function PPGUtcTimeZone: IPPGTimeZone;
/// Zone nach Windows- oder IANA-Name; nil = unbekannt.
function PPGFindTimeZone(const IdOrIana: string): IPPGTimeZone;
/// Zone aus festen Regeln (Tests, eigene Zonen).
function PPGTimeZoneFromInfo(const AId: string; const Info: TTimeZoneInformation): IPPGTimeZone;
/// IANA-Name zu einem Windows-Namen (iCalendar-Export); '' = keiner bekannt.
function PPGIanaOfWindowsZone(const WindowsId: string): string;

implementation

uses
  System.DateUtils, System.Win.Registry;

type
  TRuleZone = class(TInterfacedObject, IPPGTimeZone)
  private
    FId: string;
    FInfo: TTimeZoneInformation;
    function HasDst: Boolean;
    /// Umstellungen eines Jahres in Ortszeit: DstStart in Winterzeit, DstEnd in Sommerzeit.
    procedure Transitions(Year: Word; out DstStart, DstEnd: TDateTime);
    function StdOffset: Integer;
    function DstOffset: Integer;
  public
    constructor Create(const AId: string; const AInfo: TTimeZoneInformation);
    function ToUtc(Local: TDateTime): TDateTime;
    function ToLocal(Utc: TDateTime): TDateTime;
    function OffsetMinutes(Utc: TDateTime): Integer;
    function Id: string;
  end;

  TUtcZone = class(TInterfacedObject, IPPGTimeZone)
  public
    function ToUtc(Local: TDateTime): TDateTime;
    function ToLocal(Utc: TDateTime): TDateTime;
    function OffsetMinutes(Utc: TDateTime): Integer;
    function Id: string;
  end;

const
  OneMinute = 1 / MinsPerDay;
  // Toleranz fuer Grenzvergleiche (TDateTime ist nicht exakt)
  Eps = 0.5 / MSecsPerDay;

{ TUtcZone }

function TUtcZone.ToUtc(Local: TDateTime): TDateTime;
begin
  Result := Local;
end;

function TUtcZone.ToLocal(Utc: TDateTime): TDateTime;
begin
  Result := Utc;
end;

function TUtcZone.OffsetMinutes(Utc: TDateTime): Integer;
begin
  Result := 0;
end;

function TUtcZone.Id: string;
begin
  Result := 'UTC';
end;

{ TRuleZone }

constructor TRuleZone.Create(const AId: string; const AInfo: TTimeZoneInformation);
begin
  inherited Create;
  FId := AId;
  FInfo := AInfo;
end;

function TRuleZone.Id: string;
begin
  Result := FId;
end;

function TRuleZone.HasDst: Boolean;
begin
  Result := (FInfo.StandardDate.wMonth <> 0) and (FInfo.DaylightDate.wMonth <> 0);
end;

function TRuleZone.StdOffset: Integer;
begin
  // Bias: UTC = Ortszeit + Bias (Minuten)
  Result := -(FInfo.Bias + FInfo.StandardBias);
end;

function TRuleZone.DstOffset: Integer;
begin
  Result := -(FInfo.Bias + FInfo.DaylightBias);
end;

/// Datum einer Umstellungsregel: wDay = n-ter Wochentag (5 = letzter) im Monat.
function RuleDate(const R: TSystemTime; Year: Word): TDateTime;
var
  D: TDateTime;
  DOW, N: Integer;
begin
  if R.wYear <> 0 then
  begin
    // feste Angabe (selten)
    Result := EncodeDate(R.wYear, R.wMonth, R.wDay) +
      EncodeTime(R.wHour, R.wMinute, R.wSecond, 0);
    Exit;
  end;
  D := EncodeDate(Year, R.wMonth, 1);
  // DayOfWeek: 1 = Sonntag; wDayOfWeek: 0 = Sonntag
  DOW := DayOfWeek(D) - 1;
  D := D + (7 + R.wDayOfWeek - DOW) mod 7;
  N := R.wDay;
  if N < 1 then
    N := 1;
  D := D + 7 * (N - 1);
  while MonthOf(D) <> R.wMonth do
    D := D - 7; // "5." = letzter
  Result := D + EncodeTime(R.wHour, R.wMinute, R.wSecond, 0);
end;

procedure TRuleZone.Transitions(Year: Word; out DstStart, DstEnd: TDateTime);
begin
  DstStart := RuleDate(FInfo.DaylightDate, Year);
  DstEnd := RuleDate(FInfo.StandardDate, Year);
end;

function TRuleZone.ToUtc(Local: TDateTime): TDateTime;
var
  S, E: TDateTime;
  Delta: Double;
  InDst: Boolean;
begin
  if not HasDst then
    Exit(Local - StdOffset * OneMinute);
  Transitions(YearOf(Local), S, E);
  Delta := (DstOffset - StdOffset) * OneMinute;
  // S in Winterzeit (Luecke [S, S+Delta)), E in Sommerzeit (doppelt [E-Delta, E))
  if S < E then
    InDst := (Local >= S + Delta - Eps) and (Local < E - Eps)
  else
    InDst := (Local >= S + Delta - Eps) or (Local < E - Eps); // Suedhalbkugel
  // Luecke: Winter-Abstand (landet in der Sommerzeit); doppelte Stunde: Sommerzeit
  if InDst then
    Result := Local - DstOffset * OneMinute
  else
    Result := Local - StdOffset * OneMinute;
end;

function TRuleZone.OffsetMinutes(Utc: TDateTime): Integer;
var
  S, E, SU, EU: TDateTime;
  InDst: Boolean;
begin
  if not HasDst then
    Exit(StdOffset);
  Transitions(YearOf(Utc + StdOffset * OneMinute), S, E);
  SU := S - StdOffset * OneMinute; // Beginn in UTC
  EU := E - DstOffset * OneMinute; // Ende in UTC
  if SU < EU then
    InDst := (Utc >= SU - Eps) and (Utc < EU - Eps)
  else
    InDst := (Utc >= SU - Eps) or (Utc < EU - Eps);
  if InDst then
    Result := DstOffset
  else
    Result := StdOffset;
end;

function TRuleZone.ToLocal(Utc: TDateTime): TDateTime;
begin
  Result := Utc + OffsetMinutes(Utc) * OneMinute;
end;

{ Fabriken }

var
  GUtc: IPPGTimeZone;

function PPGUtcTimeZone: IPPGTimeZone;
begin
  if GUtc = nil then
    GUtc := TUtcZone.Create;
  Result := GUtc;
end;

function PPGTimeZoneFromInfo(const AId: string; const Info: TTimeZoneInformation): IPPGTimeZone;
begin
  Result := TRuleZone.Create(AId, Info);
end;

function PPGLocalTimeZone: IPPGTimeZone;
var
  Info: TTimeZoneInformation;
begin
  FillChar(Info, SizeOf(Info), 0);
  GetTimeZoneInformation(Info);
  Result := TRuleZone.Create('Local', Info);
end;

const
  IanaMap: array[0..23, 0..1] of string = (
    ('Europe/Berlin', 'W. Europe Standard Time'),
    ('Europe/Vienna', 'W. Europe Standard Time'),
    ('Europe/Zurich', 'W. Europe Standard Time'),
    ('Europe/Amsterdam', 'W. Europe Standard Time'),
    ('Europe/Rome', 'W. Europe Standard Time'),
    ('Europe/Paris', 'Romance Standard Time'),
    ('Europe/Brussels', 'Romance Standard Time'),
    ('Europe/Madrid', 'Romance Standard Time'),
    ('Europe/London', 'GMT Standard Time'),
    ('Europe/Dublin', 'GMT Standard Time'),
    ('Europe/Warsaw', 'Central European Standard Time'),
    ('Europe/Prague', 'Central Europe Standard Time'),
    ('Europe/Helsinki', 'FLE Standard Time'),
    ('Europe/Moscow', 'Russian Standard Time'),
    ('America/New_York', 'Eastern Standard Time'),
    ('America/Chicago', 'Central Standard Time'),
    ('America/Denver', 'Mountain Standard Time'),
    ('America/Los_Angeles', 'Pacific Standard Time'),
    ('Asia/Tokyo', 'Tokyo Standard Time'),
    ('Asia/Shanghai', 'China Standard Time'),
    ('Asia/Kolkata', 'India Standard Time'),
    ('Australia/Sydney', 'AUS Eastern Standard Time'),
    ('UTC', 'UTC'),
    ('Etc/UTC', 'UTC'));

function PPGIanaOfWindowsZone(const WindowsId: string): string;
var
  I: Integer;
begin
  for I := 0 to High(IanaMap) do
    if SameText(IanaMap[I, 1], WindowsId) then
      Exit(IanaMap[I, 0]);
  Result := '';
end;

type
  // Aufbau des Registry-Werts TZI
  TRegTzi = packed record
    Bias, StandardBias, DaylightBias: Longint;
    StandardDate, DaylightDate: TSystemTime;
  end;

function PPGFindTimeZone(const IdOrIana: string): IPPGTimeZone;
var
  Name: string;
  I: Integer;
  R: TRegistry;
  Tzi: TRegTzi;
  Info: TTimeZoneInformation;
begin
  Result := nil;
  Name := IdOrIana;
  if SameText(Name, 'UTC') or SameText(Name, 'Etc/UTC') or SameText(Name, 'GMT') then
    Exit(PPGUtcTimeZone);
  if SameText(Name, 'Local') then
    Exit(PPGLocalTimeZone);
  for I := 0 to High(IanaMap) do
    if SameText(IanaMap[I, 0], Name) then
    begin
      Name := IanaMap[I, 1];
      Break;
    end;
  R := TRegistry.Create(KEY_READ);
  try
    R.RootKey := HKEY_LOCAL_MACHINE;
    if not R.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\' + Name) then
      Exit;
    if R.GetDataSize('TZI') <> SizeOf(Tzi) then
      Exit;
    R.ReadBinaryData('TZI', Tzi, SizeOf(Tzi));
  finally
    R.Free;
  end;
  FillChar(Info, SizeOf(Info), 0);
  Info.Bias := Tzi.Bias;
  Info.StandardBias := Tzi.StandardBias;
  Info.DaylightBias := Tzi.DaylightBias;
  Info.StandardDate := Tzi.StandardDate;
  Info.DaylightDate := Tzi.DaylightDate;
  Result := TRuleZone.Create(Name, Info);
end;

end.
