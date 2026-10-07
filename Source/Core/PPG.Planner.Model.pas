unit PPG.Planner.Model;

{ Termine des Planers (Phase 14a), ohne Zeichencode.

  - TPPGAppointment: Beginn/Ende, ganztaegig, Betreff, Ort, Text (Markup),
    Kategorie, Ressource, Wiederholung (RRULE), Ausnahmen (EXDATE) und
    geaenderte Einzeltermine (RecurrenceParent/RecurrenceStart).
  - Zeiten: bei TimeZoneMode = tzmUtc (Vorgabe) stehen StartTime/FinishTime in
    UTC; Start/Finish rechnen in die Anzeige-Zone (DisplayZone). Ganztaegige
    Termine sind Daten ohne Zone (Ende exklusiv, wie DTEND in iCalendar).
  - GetOccurrences liefert die Vorkommen eines Zeitraums (Anzeige-Zeit),
    Wiederholungen nur fuer diesen Zeitraum aufgeloest. Grosse Kalender
    liefern stattdessen eine eigene IPPGAppointmentSource (z. B. DB-Planer,
    nur der sichtbare Zeitraum). }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.SysUtils, PPG.TimeZones, PPG.Planner.Recurrence;

type
  TPPGTimeZoneMode = (tzmUtc, tzmLocal);

  TPPGAppointments = class;

  TPPGAppointment = class(TCollectionItem)
  private
    FId: Integer;
    FStartTime: TDateTime;
    FFinishTime: TDateTime;
    FAllDay: Boolean;
    FSubject: string;
    FLocation: string;
    FBody: string;
    FCategory: Integer;
    FResourceId: Integer;
    FRecurrence: string;
    FExDates: string;
    FRecurrenceParent: Integer;
    FRecurrenceStart: TDateTime;
    FReadOnly: Boolean;
    FTag: NativeInt;
    function Owner: TPPGAppointments;
    function ToDisplay(T: TDateTime): TDateTime;
    function FromDisplay(T: TDateTime): TDateTime;
    function GetStart: TDateTime;
    function GetFinish: TDateTime;
    procedure SetStart(const Value: TDateTime);
    procedure SetFinish(const Value: TDateTime);
    procedure SetStartTime(const Value: TDateTime);
    procedure SetFinishTime(const Value: TDateTime);
    procedure SetAllDay(const Value: Boolean);
    procedure SetSubject(const Value: string);
    procedure SetLocation(const Value: string);
    procedure SetBody(const Value: string);
    procedure SetCategory(const Value: Integer);
    procedure SetResourceId(const Value: Integer);
    procedure SetRecurrence(const Value: string);
    procedure SetExDates(const Value: string);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    /// Beginn/Ende in der Anzeige-Zone (ganztaegig: Datum, Ende exklusiv).
    property Start: TDateTime read GetStart write SetStart;
    property Finish: TDateTime read GetFinish write SetFinish;
    function Duration: TDateTime;
    function IsRecurring: Boolean;
    function Rule: TPPGRecurrence;
    /// Vorkommen einer Serie ausnehmen (Beginn in Anzeige-Zeit).
    procedure AddException(OccurrenceStart: TDateTime);
    /// Ausnahmen (EXDATE) in Anzeige-Zeit.
    function ExceptionDates: TArray<TDateTime>;
  published
    /// Eindeutige Nummer (vergibt die Collection).
    property Id: Integer read FId write FId default 0;
    /// Gespeicherter Beginn/Ende: UTC bei TimeZoneMode = tzmUtc.
    property StartTime: TDateTime read FStartTime write SetStartTime;
    property FinishTime: TDateTime read FFinishTime write SetFinishTime;
    property AllDay: Boolean read FAllDay write SetAllDay default False;
    property Subject: string read FSubject write SetSubject;
    property Location: string read FLocation write SetLocation;
    /// Text mit Markup.
    property Body: string read FBody write SetBody;
    /// Kategorie (Farbe aus der Palette); -1 = keine.
    property Category: Integer read FCategory write SetCategory default -1;
    property ResourceId: Integer read FResourceId write SetResourceId default 0;
    /// RRULE (z. B. 'FREQ=WEEKLY;BYDAY=MO,WE').
    property Recurrence: string read FRecurrence write SetRecurrence;
    /// Ausnahmen: iCalendar-Zeiten, durch Komma getrennt (gespeicherte Zeit).
    property ExDates: string read FExDates write SetExDates;
    /// Geaenderter Einzeltermin: Id der Serie (0 = keiner) und urspruenglicher Beginn.
    property RecurrenceParent: Integer read FRecurrenceParent write FRecurrenceParent default 0;
    property RecurrenceStart: TDateTime read FRecurrenceStart write FRecurrenceStart;
    property ReadOnly: Boolean read FReadOnly write FReadOnly default False;
    property Tag: NativeInt read FTag write FTag default 0;
  end;

  /// Ein Vorkommen im Zeitraum (Serien: je Wiederholung eins).
  TPPGOccurrence = record
    Appointment: TPPGAppointment;
    Start, Finish: TDateTime;  // Anzeige-Zeit
    Recurring: Boolean;
  end;

  IPPGAppointmentSource = interface
    ['{3C8F5D21-7A94-4B6E-A02D-91E6C4B7F350}']
    /// Vorkommen, die [AFrom, ATo) beruehren (Anzeige-Zeit), nach Beginn sortiert.
    function GetOccurrences(AFrom, ATo: TDateTime): TArray<TPPGOccurrence>;
  end;

  IPPGAppointmentsHost = interface
    ['{9B0E2C47-5D18-4F3A-B6C9-2E7A41D8F063}']
    procedure AppointmentsChanged;
  end;

  TPPGAppointments = class(TOwnedCollection)
  private
    FTimeZoneMode: TPPGTimeZoneMode;
    FDisplayZone: IPPGTimeZone;
    FNextId: Integer;
    function GetItem(Index: Integer): TPPGAppointment;
    procedure SetTimeZoneMode(const Value: TPPGTimeZoneMode);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TPPGAppointment;
    /// Neuer Termin in Anzeige-Zeit.
    function AddAppointment(AStart, AFinish: TDateTime; const ASubject: string): TPPGAppointment;
    function FindById(AId: Integer): TPPGAppointment;
    /// Vorkommen in [AFrom, ATo) (Anzeige-Zeit), nach Beginn sortiert.
    function GetOccurrences(AFrom, ATo: TDateTime): TArray<TPPGOccurrence>;
    /// Einzelnes Vorkommen einer Serie herausloesen (eigener Termin mit
    /// RecurrenceParent; die Serie bekommt eine Ausnahme).
    function DetachOccurrence(const Occ: TPPGOccurrence): TPPGAppointment;
    /// Zone der Anzeige (Vorgabe: Zone des Rechners).
    function DisplayZone: IPPGTimeZone;
    procedure SetDisplayZone(const Value: IPPGTimeZone);
    property TimeZoneMode: TPPGTimeZoneMode read FTimeZoneMode write SetTimeZoneMode;
    property Items[Index: Integer]: TPPGAppointment read GetItem; default;
  end;

/// Ueberschneidet [S1, F1) den Bereich [S2, F2)? (Dauer 0 zaehlt als Punkt.)
function PPGOverlaps(S1, F1, S2, F2: TDateTime): Boolean;
/// Vorkommen nach Beginn sortieren (bei Gleichstand laengere zuerst).
procedure PPGSortOccurrences(var A: TArray<TPPGOccurrence>);

implementation

uses
  System.Generics.Collections, System.Generics.Defaults, PPG.Types;

function PPGOverlaps(S1, F1, S2, F2: TDateTime): Boolean;
begin
  if F1 <= S1 then
    Result := (S1 >= S2) and (S1 < F2)
  else
    Result := (S1 < F2) and (F1 > S2);
end;

procedure PPGSortOccurrences(var A: TArray<TPPGOccurrence>);
begin
  TArray.Sort<TPPGOccurrence>(A, TComparer<TPPGOccurrence>.Construct(
    function(const X, Y: TPPGOccurrence): Integer
    begin
      if X.Start < Y.Start then
        Result := -1
      else if X.Start > Y.Start then
        Result := 1
      else if X.Finish > Y.Finish then
        Result := -1
      else if X.Finish < Y.Finish then
        Result := 1
      else
        Result := X.Appointment.Index - Y.Appointment.Index;
    end));
end;

{ TPPGAppointment }

constructor TPPGAppointment.Create(Collection: TCollection);
begin
  FCategory := -1;
  inherited Create(Collection);
  // Neue Nummer (beim Laden aus dem DFM kommt sie aus dem Stream)
  if (Collection is TPPGAppointments) and not ((TPPGAppointments(Collection).Owner is TComponent)
    and (csLoading in TComponent(TPPGAppointments(Collection).Owner).ComponentState)) then
  begin
    Inc(TPPGAppointments(Collection).FNextId);
    FId := TPPGAppointments(Collection).FNextId;
  end;
end;

procedure TPPGAppointment.Assign(Source: TPersistent);
var
  S: TPPGAppointment;
begin
  if Source is TPPGAppointment then
  begin
    S := TPPGAppointment(Source);
    FStartTime := S.FStartTime;
    FFinishTime := S.FFinishTime;
    FAllDay := S.FAllDay;
    FSubject := S.FSubject;
    FLocation := S.FLocation;
    FBody := S.FBody;
    FCategory := S.FCategory;
    FResourceId := S.FResourceId;
    FRecurrence := S.FRecurrence;
    FExDates := S.FExDates;
    FRecurrenceParent := S.FRecurrenceParent;
    FRecurrenceStart := S.FRecurrenceStart;
    FReadOnly := S.FReadOnly;
    FTag := S.FTag;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGAppointment.GetDisplayName: string;
begin
  if FSubject <> '' then
    Result := FSubject
  else
    Result := inherited GetDisplayName;
end;

function TPPGAppointment.Owner: TPPGAppointments;
begin
  if Collection is TPPGAppointments then
    Result := TPPGAppointments(Collection)
  else
    Result := nil;
end;

function TPPGAppointment.ToDisplay(T: TDateTime): TDateTime;
begin
  if FAllDay or (Owner = nil) or (Owner.TimeZoneMode = tzmLocal) or (T = 0) then
    Result := T
  else
    Result := Owner.DisplayZone.ToLocal(T);
end;

function TPPGAppointment.FromDisplay(T: TDateTime): TDateTime;
begin
  if FAllDay or (Owner = nil) or (Owner.TimeZoneMode = tzmLocal) then
    Result := T
  else
    Result := Owner.DisplayZone.ToUtc(T);
end;

function TPPGAppointment.GetStart: TDateTime;
begin
  Result := ToDisplay(FStartTime);
end;

function TPPGAppointment.GetFinish: TDateTime;
begin
  Result := ToDisplay(FFinishTime);
end;

procedure TPPGAppointment.SetStart(const Value: TDateTime);
begin
  SetStartTime(FromDisplay(Value));
end;

procedure TPPGAppointment.SetFinish(const Value: TDateTime);
begin
  SetFinishTime(FromDisplay(Value));
end;

procedure TPPGAppointment.SetStartTime(const Value: TDateTime);
begin
  if FStartTime <> Value then
  begin
    FStartTime := Value;
    Changed(False);
  end;
end;

procedure TPPGAppointment.SetFinishTime(const Value: TDateTime);
begin
  if FFinishTime <> Value then
  begin
    FFinishTime := Value;
    Changed(False);
  end;
end;

procedure TPPGAppointment.SetAllDay(const Value: Boolean);
begin
  if FAllDay <> Value then
  begin
    FAllDay := Value;
    Changed(False);
  end;
end;

procedure TPPGAppointment.SetSubject(const Value: string);
begin
  if FSubject <> Value then
  begin
    FSubject := Value;
    Changed(False);
  end;
end;

procedure TPPGAppointment.SetLocation(const Value: string);
begin
  if FLocation <> Value then
  begin
    FLocation := Value;
    Changed(False);
  end;
end;

procedure TPPGAppointment.SetBody(const Value: string);
begin
  if FBody <> Value then
  begin
    FBody := Value;
    Changed(False);
  end;
end;

procedure TPPGAppointment.SetCategory(const Value: Integer);
begin
  if FCategory <> Value then
  begin
    FCategory := Value;
    Changed(False);
  end;
end;

procedure TPPGAppointment.SetResourceId(const Value: Integer);
begin
  if FResourceId <> Value then
  begin
    FResourceId := Value;
    Changed(False);
  end;
end;

procedure TPPGAppointment.SetRecurrence(const Value: string);
begin
  if FRecurrence <> Value then
  begin
    FRecurrence := Value;
    Changed(False);
  end;
end;

procedure TPPGAppointment.SetExDates(const Value: string);
begin
  if FExDates <> Value then
  begin
    FExDates := Value;
    Changed(False);
  end;
end;

function TPPGAppointment.Duration: TDateTime;
begin
  Result := FFinishTime - FStartTime;
  if Result < 0 then
    Result := 0;
end;

function TPPGAppointment.Rule: TPPGRecurrence;
begin
  if not TPPGRecurrence.TryParse(FRecurrence, Result) then
    Result.Clear;
end;

function TPPGAppointment.IsRecurring: Boolean;
begin
  Result := Rule.IsRecurring;
end;

function TPPGAppointment.ExceptionDates: TArray<TDateTime>;
var
  Parts: TArray<string>;
  I, N: Integer;
  D: TDateTime;
  IsUtc, IsDate: Boolean;
begin
  Parts := PPGSplitString(FExDates, ',', True);
  SetLength(Result, Length(Parts));
  N := 0;
  for I := 0 to High(Parts) do
    if PPGParseICalDateTime(Trim(Parts[I]), D, IsUtc, IsDate) then
    begin
      if IsDate then
        D := D + Frac(Start); // nur Datum: Uhrzeit der Serie
      if IsUtc and not FAllDay and (Owner <> nil) and (Owner.TimeZoneMode = tzmUtc) then
        D := Owner.DisplayZone.ToLocal(D);
      Result[N] := D;
      Inc(N);
    end;
  SetLength(Result, N);
end;

procedure TPPGAppointment.AddException(OccurrenceStart: TDateTime);
var
  S: string;
  Utc: Boolean;
begin
  Utc := not FAllDay and (Owner <> nil) and (Owner.TimeZoneMode = tzmUtc);
  if Utc then
    S := PPGFormatICalDateTime(Owner.DisplayZone.ToUtc(OccurrenceStart), True, False)
  else
    S := PPGFormatICalDateTime(OccurrenceStart, False, False);
  if Pos(S, FExDates) > 0 then
    Exit;
  if FExDates = '' then
    SetExDates(S)
  else
    SetExDates(FExDates + ',' + S);
end;

{ TPPGAppointments }

constructor TPPGAppointments.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TPPGAppointment);
end;

function TPPGAppointments.Add: TPPGAppointment;
begin
  Result := TPPGAppointment(inherited Add);
end;

function TPPGAppointments.AddAppointment(AStart, AFinish: TDateTime;
  const ASubject: string): TPPGAppointment;
begin
  BeginUpdate;
  try
    Result := Add;
    Result.Subject := ASubject;
    Result.Start := AStart;
    Result.Finish := AFinish;
  finally
    EndUpdate;
  end;
end;

function TPPGAppointments.GetItem(Index: Integer): TPPGAppointment;
begin
  Result := TPPGAppointment(inherited Items[Index]);
end;

procedure TPPGAppointments.SetTimeZoneMode(const Value: TPPGTimeZoneMode);
begin
  if FTimeZoneMode <> Value then
  begin
    FTimeZoneMode := Value;
    Changed;
  end;
end;

function TPPGAppointments.DisplayZone: IPPGTimeZone;
begin
  if FDisplayZone = nil then
    FDisplayZone := PPGLocalTimeZone;
  Result := FDisplayZone;
end;

procedure TPPGAppointments.SetDisplayZone(const Value: IPPGTimeZone);
begin
  FDisplayZone := Value;
  Changed;
end;

procedure TPPGAppointments.Update(Item: TCollectionItem);
var
  H: IPPGAppointmentsHost;
  I: Integer;
begin
  inherited Update(Item);
  // Ids nach dem Laden: hoechste merken
  for I := 0 to Count - 1 do
    if Items[I].FId > FNextId then
      FNextId := Items[I].FId;
  if (GetOwner is TComponent) and (csLoading in TComponent(GetOwner).ComponentState) then
    Exit;
  if Supports(GetOwner, IPPGAppointmentsHost, H) then
    H.AppointmentsChanged;
end;

function TPPGAppointments.FindById(AId: Integer): TPPGAppointment;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Items[I].FId = AId then
      Exit(Items[I]);
  Result := nil;
end;

function TPPGAppointments.GetOccurrences(AFrom, ATo: TDateTime): TArray<TPPGOccurrence>;
var
  L: TList<TPPGOccurrence>;
  I, K: Integer;
  A: TPPGAppointment;
  O: TPPGOccurrence;
  R: TPPGRecurrence;
  S, Dur: TDateTime;
  Starts: TArray<TDateTime>;
begin
  L := TList<TPPGOccurrence>.Create;
  try
    for I := 0 to Count - 1 do
    begin
      A := Items[I];
      O.Appointment := A;
      S := A.Start;
      Dur := A.Finish - S;
      if Dur < 0 then
        Dur := 0;
      R := A.Rule;
      if not R.IsRecurring then
      begin
        if PPGOverlaps(S, S + Dur, AFrom, ATo) then
        begin
          O.Start := S;
          O.Finish := S + Dur;
          O.Recurring := False;
          L.Add(O);
        end;
        Continue;
      end;
      // UNTIL mit Z: in die Anzeige-Zone (die Serie laeuft auf der Wanduhr)
      if R.UntilUtc and (TimeZoneMode = tzmUtc) and not A.AllDay then
        R.UntilDate := DisplayZone.ToLocal(R.UntilDate);
      Starts := R.Expand(S, AFrom - Dur, ATo, A.ExceptionDates);
      for K := 0 to High(Starts) do
        if PPGOverlaps(Starts[K], Starts[K] + Dur, AFrom, ATo) then
        begin
          O.Start := Starts[K];
          O.Finish := Starts[K] + Dur;
          O.Recurring := True;
          L.Add(O);
        end;
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
  PPGSortOccurrences(Result);
end;

function TPPGAppointments.DetachOccurrence(const Occ: TPPGOccurrence): TPPGAppointment;
var
  Series: TPPGAppointment;
begin
  Series := Occ.Appointment;
  BeginUpdate;
  try
    Result := Add;
    Result.Assign(Series);
    Result.FRecurrence := '';
    Result.FExDates := '';
    Result.FRecurrenceParent := Series.Id;
    Result.Start := Occ.Start;
    Result.Finish := Occ.Finish;
    Result.FRecurrenceStart := Result.FStartTime;
    Series.AddException(Occ.Start);
  finally
    EndUpdate;
  end;
end;

end.
