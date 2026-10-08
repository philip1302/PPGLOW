unit PPG.DB.Planner;

{ TPPGDBPlanner - Terminplaner auf einer Datenmenge (Phase 14a, Paket PPGlowDBR).

  - Feldzuordnung: KeyField (Pflicht zum Schreiben, ganze Zahl), StartField,
    FinishField, SubjectField sowie optional LocationField, BodyField,
    AllDayField, CategoryField, ResourceField, RecurrenceField (RRULE-Text),
    ExDatesField und ParentField (geaenderter Einzeltermin einer Serie).
  - Zeiten in der Datenmenge wie TimeZoneMode: UTC (Vorgabe) oder Ortszeit.
  - Laden: alle Datensaetze (hoechstens MaxRecords) werden in Appointments
    gespiegelt. Bestehende Termine werden per Schluessel aktualisiert statt
    neu angelegt (Auswahl und Zeiger bleiben gueltig).
  - Grosse Kalender: OnGetRange meldet den sichtbaren Zeitraum, bevor
    gelesen wird; die Anwendung setzt dort Filter bzw. Parameter der Abfrage
    (Serien mit Wiederholung muessen dabei immer dabei sein).
  - Schreiben: jede Aenderung durch den Anwender (Ziehen, Groesse, Betreff,
    Anlegen, Loeschen, Kopieren, Herausloesen eines Vorkommens) wird sofort
    in die Datenmenge geschrieben (Locate per KeyField, sonst Append).
    Selbst vergebene Schluessel (AutoInc) werden nach Post uebernommen.
  - Datenaenderungen von aussen laden verzoegert neu (ReloadDelay ueber den
    Animator); eigenes Lesen und Schreiben loest kein Neuladen aus.
  - SyncRecord: der gewaehlte Termin wird zum aktuellen Datensatz.
  - Waehrend Edit/Insert durch andere Controls wird nicht gelesen. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, Data.DB,
  PPG.Animation, PPG.Planner.Model, PPG.Planner;

type
  TPPGCustomDBPlanner = class;

  TPPGPlannerDataLink = class(TDataLink)
  private
    FPlanner: TPPGCustomDBPlanner;
  protected
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure RecordChanged(Field: TField); override;
  public
    constructor Create(APlanner: TPPGCustomDBPlanner);
  end;

  TPPGPlannerRangeEvent = procedure(Sender: TObject; AFrom, ATo: TDateTime) of object;

  TPPGCustomDBPlanner = class(TPPGCustomPlanner)
  private
    FDataLink: TPPGPlannerDataLink;
    FKeyField: string;
    FStartField: string;
    FFinishField: string;
    FSubjectField: string;
    FLocationField: string;
    FBodyField: string;
    FAllDayField: string;
    FCategoryField: string;
    FResourceField: string;
    FRecurrenceField: string;
    FExDatesField: string;
    FParentField: string;
    FMaxRecords: Integer;
    FReloadDelay: Integer;
    FSyncRecord: Boolean;
    FReloadAnim: TPPGAnimation;
    FReloadPending: Boolean;
    FBusy: Integer;
    FLoadedCount: Integer;
    // Schluessel der Saetze, die als Termin geladen oder vom Planer
    // geschrieben wurden. Nur diese werden per Edit geaendert bzw. geloescht.
    FDbKeys: TDictionary<Integer, Boolean>;
    FOnGetRange: TPPGPlannerRangeEvent;
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    procedure SetField(Index: Integer; const Value: string);
    function GetField(Index: Integer): string;
    procedure SetMaxRecords(const Value: Integer);
    procedure SetReloadDelay(const Value: Integer);
    procedure ReloadStep(Sender: TObject);
    function Fld(const AName: string): TField;
    function CanWrite: Boolean;
    function LocateKey(AId: Integer): Boolean;
    procedure WriteFields(A: TPPGAppointment);
    procedure CheckNoForeignEdit;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure RangeChanged; override;
    procedure SelectionChanged; override;
    procedure AppointmentWritten(A: TPPGAppointment); override;
    procedure DoDeleteAppointment(A: TPPGAppointment); override;
    procedure ScheduleReload;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property KeyField: string index 0 read GetField write SetField;
    property StartField: string index 1 read GetField write SetField;
    property FinishField: string index 2 read GetField write SetField;
    property SubjectField: string index 3 read GetField write SetField;
    property LocationField: string index 4 read GetField write SetField;
    property BodyField: string index 5 read GetField write SetField;
    property AllDayField: string index 6 read GetField write SetField;
    property CategoryField: string index 7 read GetField write SetField;
    property ResourceField: string index 8 read GetField write SetField;
    property RecurrenceField: string index 9 read GetField write SetField;
    property ExDatesField: string index 10 read GetField write SetField;
    property ParentField: string index 11 read GetField write SetField;
    property MaxRecords: Integer read FMaxRecords write SetMaxRecords default 10000;
    property ReloadDelay: Integer read FReloadDelay write SetReloadDelay default 100;
    property SyncRecord: Boolean read FSyncRecord write FSyncRecord default True;
    property OnGetRange: TPPGPlannerRangeEvent read FOnGetRange write FOnGetRange;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Sofort aus der Datenmenge lesen (vorher OnGetRange).
    procedure Reload;
    procedure FlushReload;
    function ReloadPending: Boolean;
    property LoadedCount: Integer read FLoadedCount;
    property DataLink: TPPGPlannerDataLink read FDataLink;
  end;

  TPPGDBPlanner = class(TPPGCustomDBPlanner)
  published
    property DataSource;
    property KeyField;
    property StartField;
    property FinishField;
    property SubjectField;
    property LocationField;
    property BodyField;
    property AllDayField;
    property CategoryField;
    property ResourceField;
    property RecurrenceField;
    property ExDatesField;
    property ParentField;
    property MaxRecords;
    property ReloadDelay;
    property SyncRecord;
    property OnGetRange;
    property Resources;
    property Categories;
    property PlannerStyles;
    property View;
    property Date;
    property DayCount;
    property FirstDayOfWeek;
    property WorkDays;
    property WorkStart;
    property WorkEnd;
    property DayStartHour;
    property DayEndHour;
    property SlotMinutes;
    property SlotHeight;
    property SlotWidth;
    property TimelineDays;
    property AgendaDays;
    property GroupByResource;
    property ShowNowLine;
    property ReadOnly;
    property TimeZone;
    property TimeZoneMode;
    property Calendar;
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighContrastSupport;
    property ScrollBarMode;
    property SmoothScrolling;
    property Align;
    property Anchors;
    property BiDiMode;
    property Constraints;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Touch;
    property OnGesture;
    property OnAppointmentChanging;
    property OnAppointmentChanged;
    property OnAppointmentCreated;
    property OnAppointmentOpen;
    property OnDeleting;
    property OnCreateAppointment;
    property OnGetAppointmentColor;
    property OnCustomDrawAppointment;
    property OnSelectionChange;
    property OnRangeChange;
    property OnScroll;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnMouseDown;
    property OnMouseUp;
  end;

implementation

uses
  System.Variants, PPG.Types, PPG.DB.Controls, PPG.Consts, PPG.Lang, PPG.Exceptions;

{ TPPGPlannerDataLink }

constructor TPPGPlannerDataLink.Create(APlanner: TPPGCustomDBPlanner);
begin
  inherited Create;
  FPlanner := APlanner;
end;

procedure TPPGPlannerDataLink.ActiveChanged;
begin
  if FPlanner <> nil then
    FPlanner.Reload;
end;

procedure TPPGPlannerDataLink.DataSetChanged;
begin
  if (FPlanner <> nil) and not PPGDBReading then
    FPlanner.ScheduleReload;
end;

procedure TPPGPlannerDataLink.RecordChanged(Field: TField);
begin
  if FPlanner <> nil then
    FPlanner.ScheduleReload;
end;

{ TPPGCustomDBPlanner }

constructor TPPGCustomDBPlanner.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMaxRecords := 10000;
  FReloadDelay := 100;
  FSyncRecord := True;
  FReloadAnim := TPPGAnimation.Create(Self);
  FReloadAnim.OnStep := ReloadStep;
  FDbKeys := TDictionary<Integer, Boolean>.Create;
  FDataLink := TPPGPlannerDataLink.Create(Self);
end;

destructor TPPGCustomDBPlanner.Destroy;
begin
  if FDataLink <> nil then
    FDataLink.FPlanner := nil;
  FreeAndNil(FDataLink);
  if FReloadAnim <> nil then
    FReloadAnim.OnStep := nil;
  FreeAndNil(FReloadAnim);
  inherited Destroy;
  FreeAndNil(FDbKeys);
end;

procedure TPPGCustomDBPlanner.Loaded;
begin
  inherited Loaded;
  Reload;
end;

procedure TPPGCustomDBPlanner.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FDataLink <> nil) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TPPGCustomDBPlanner.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TPPGCustomDBPlanner.SetDataSource(Value: TDataSource);
begin
  PPGDBSetDataSource(Self, FDataLink, Value);
end;

function TPPGCustomDBPlanner.GetField(Index: Integer): string;
begin
  case Index of
    0: Result := FKeyField;
    1: Result := FStartField;
    2: Result := FFinishField;
    3: Result := FSubjectField;
    4: Result := FLocationField;
    5: Result := FBodyField;
    6: Result := FAllDayField;
    7: Result := FCategoryField;
    8: Result := FResourceField;
    9: Result := FRecurrenceField;
    10: Result := FExDatesField;
  else
    Result := FParentField;
  end;
end;

procedure TPPGCustomDBPlanner.SetField(Index: Integer; const Value: string);
begin
  if GetField(Index) = Value then
    Exit;
  case Index of
    0: FKeyField := Value;
    1: FStartField := Value;
    2: FFinishField := Value;
    3: FSubjectField := Value;
    4: FLocationField := Value;
    5: FBodyField := Value;
    6: FAllDayField := Value;
    7: FCategoryField := Value;
    8: FResourceField := Value;
    9: FRecurrenceField := Value;
    10: FExDatesField := Value;
  else
    FParentField := Value;
  end;
  ScheduleReload;
end;

procedure TPPGCustomDBPlanner.SetMaxRecords(const Value: Integer);
begin
  FMaxRecords := PPGCheckRange(Self, 'MaxRecords', Value, 1, MaxInt);
  ScheduleReload;
end;

procedure TPPGCustomDBPlanner.SetReloadDelay(const Value: Integer);
begin
  FReloadDelay := PPGCheckRange(Self, 'ReloadDelay', Value, 0, 10000);
end;

function TPPGCustomDBPlanner.Fld(const AName: string): TField;
begin
  if (AName = '') or (FDataLink.DataSet = nil) then
    Result := nil
  else
    Result := FDataLink.DataSet.FindField(AName);
end;

procedure TPPGCustomDBPlanner.ScheduleReload;
begin
  if (FBusy > 0) or (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  if (FReloadDelay = 0) or (csDesigning in ComponentState) then
  begin
    Reload;
    Exit;
  end;
  FReloadPending := True;
  FReloadAnim.Jump(0);
  FReloadAnim.AnimateTo(1, Cardinal(FReloadDelay), ekLinear);
end;

procedure TPPGCustomDBPlanner.ReloadStep(Sender: TObject);
begin
  if FReloadPending and not FReloadAnim.Running then
    Reload;
end;

function TPPGCustomDBPlanner.ReloadPending: Boolean;
begin
  Result := FReloadPending;
end;

procedure TPPGCustomDBPlanner.FlushReload;
begin
  if FReloadPending then
    Reload;
end;

procedure TPPGCustomDBPlanner.RangeChanged;
begin
  inherited RangeChanged;
  // Neuer Zeitraum: die Anwendung darf filtern, dann lesen
  if Assigned(FOnGetRange) and FDataLink.Active then
    Reload;
end;

procedure TPPGCustomDBPlanner.Reload;
var
  DS: TDataSet;
  FKey, FStart, FFinish, FSubj, FLoc, FBody, FAll, FCat, FRes, FRec, FEx, FPar: TField;
  Seen: TDictionary<Integer, Boolean>;
  ById: TDictionary<Integer, TPPGAppointment>;
  A: TPPGAppointment;
  Bm: TBookmark;
  I, N, Key: Integer;
begin
  FReloadPending := False;
  if FReloadAnim.Running then
    FReloadAnim.Stop;
  if (csLoading in ComponentState) or (csDestroying in ComponentState) or (FBusy > 0) then
    Exit;
  if not FDataLink.Active or (FDataLink.DataSet = nil) or FDataLink.DataSet.IsUniDirectional then
  begin
    Appointments.Clear;
    FDbKeys.Clear;
    FLoadedCount := 0;
    Exit;
  end;
  DS := FDataLink.DataSet;
  if DS.State in dsEditModes then
  begin
    FReloadPending := True;
    Exit;
  end;
  if Assigned(FOnGetRange) then
  begin
    Inc(FBusy);
    try
      FOnGetRange(Self, RangeStart, RangeEnd);
    finally
      Dec(FBusy);
    end;
    if not FDataLink.Active then
      Exit;
  end;
  FKey := Fld(FKeyField);
  FStart := Fld(FStartField);
  FFinish := Fld(FFinishField);
  FSubj := Fld(FSubjectField);
  FLoc := Fld(FLocationField);
  FBody := Fld(FBodyField);
  FAll := Fld(FAllDayField);
  FCat := Fld(FCategoryField);
  FRes := Fld(FResourceField);
  FRec := Fld(FRecurrenceField);
  FEx := Fld(FExDatesField);
  FPar := Fld(FParentField);
  Seen := TDictionary<Integer, Boolean>.Create;
  ById := TDictionary<Integer, TPPGAppointment>.Create;
  Appointments.BeginUpdate;
  Inc(FBusy);
  try
    for I := 0 to Appointments.Count - 1 do
      ById.AddOrSetValue(Appointments[I].Id, Appointments[I]);
    Bm := DS.Bookmark;
    PPGDBBeginRead;
    DS.DisableControls;
    try
      FDbKeys.Clear;
      DS.First;
      N := 0;
      while not DS.Eof and (N < FMaxRecords) do
      begin
        if FKey <> nil then
        begin
          // Saetze ohne Schluessel lassen sich nicht zurueckschreiben und
          // wuerden mit Schluessel 0 zusammenfallen
          if FKey.IsNull then
          begin
            DS.Next;
            Continue;
          end;
        end;
        if (FStart <> nil) and not FStart.IsNull then
        begin
          if FKey <> nil then
            Key := FKey.AsInteger
          else
            Key := N + 1;
          if not ById.TryGetValue(Key, A) then
          begin
            A := Appointments.Add;
            A.Id := Key;
            ById.Add(Key, A);
          end;
          Seen.AddOrSetValue(Key, True);
          if FKey <> nil then
            FDbKeys.AddOrSetValue(Key, True);
          if FAll <> nil then
            A.AllDay := FAll.AsBoolean
          else
            A.AllDay := False;
          A.StartTime := FStart.AsDateTime;
          if (FFinish <> nil) and not FFinish.IsNull then
            A.FinishTime := FFinish.AsDateTime
          else
            A.FinishTime := A.StartTime;
          if FSubj <> nil then
            A.Subject := FSubj.AsString;
          if FLoc <> nil then
            A.Location := FLoc.AsString;
          if FBody <> nil then
            A.Body := FBody.AsString;
          if (FCat <> nil) and not FCat.IsNull then
            A.Category := FCat.AsInteger
          else
            A.Category := -1;
          if FRes <> nil then
            A.ResourceId := FRes.AsInteger;
          if FRec <> nil then
            A.Recurrence := FRec.AsString;
          if FEx <> nil then
            A.ExDates := FEx.AsString;
          if FPar <> nil then
            A.RecurrenceParent := FPar.AsInteger;
          A.ReadOnly := FKey = nil; // ohne Schluessel nicht zurueckschreibbar
          Inc(N);
        end;
        DS.Next;
      end;
      FLoadedCount := N;
    finally
      if (Length(Bm) > 0) and DS.BookmarkValid(Bm) then
        DS.Bookmark := Bm;
      DS.EnableControls;
      PPGDBEndRead;
    end;
    // Nicht mehr vorhandene Termine entfernen
    for I := Appointments.Count - 1 downto 0 do
      if not Seen.ContainsKey(Appointments[I].Id) then
        Appointments[I].Free;
  finally
    Dec(FBusy);
    Appointments.EndUpdate;
    ById.Free;
    Seen.Free;
  end;
end;

function TPPGCustomDBPlanner.CanWrite: Boolean;
begin
  Result := FDataLink.Active and (FDataLink.DataSet <> nil) and FDataLink.DataSet.CanModify and
    (Fld(FKeyField) <> nil) and (Fld(FStartField) <> nil);
end;

function TPPGCustomDBPlanner.LocateKey(AId: Integer): Boolean;
begin
  Result := FDataLink.DataSet.Locate(FKeyField, AId, []);
end;

procedure TPPGCustomDBPlanner.WriteFields(A: TPPGAppointment);

  procedure Put(const AName: string; const V: Variant);
  var
    F: TField;
  begin
    F := Fld(AName);
    if (F <> nil) and not F.ReadOnly then
      F.Value := V;
  end;

begin
  Put(FStartField, A.StartTime);
  Put(FFinishField, A.FinishTime);
  Put(FSubjectField, A.Subject);
  Put(FLocationField, A.Location);
  Put(FBodyField, A.Body);
  Put(FAllDayField, A.AllDay);
  if A.Category < 0 then
    Put(FCategoryField, Null)
  else
    Put(FCategoryField, A.Category);
  Put(FResourceField, A.ResourceId);
  Put(FRecurrenceField, A.Recurrence);
  Put(FExDatesField, A.ExDates);
  if A.RecurrenceParent = 0 then
    Put(FParentField, Null)
  else
    Put(FParentField, A.RecurrenceParent);
end;

procedure TPPGCustomDBPlanner.AppointmentWritten(A: TPPGAppointment);
var
  DS: TDataSet;
  KeyF: TField;
  NewKey: Integer;
  KeyWritable, Done: Boolean;
begin
  inherited AppointmentWritten(A);
  if not CanWrite then
    Exit;
  DS := FDataLink.DataSet;
  KeyF := Fld(FKeyField);
  CheckNoForeignEdit;
  Done := False;
  Inc(FBusy);
  try
    // Nur Saetze bearbeiten, die tatsaechlich gelesen wurden. Ein neuer
    // Termin hat eine Id aus der Sammlung, die zufaellig einem nicht
    // geladenen Satz (ohne Beginn, ueber MaxRecords, gefiltert) gehoeren kann.
    if FDbKeys.ContainsKey(A.Id) and LocateKey(A.Id) then
      DS.Edit
    else
    begin
      NewKey := A.Id;
      KeyWritable := not KeyF.ReadOnly and (KeyF.DataType <> ftAutoInc);
      if KeyWritable then
        while LocateKey(NewKey) do
          Inc(NewKey);
      DS.Append;
      if KeyWritable then
        KeyF.AsInteger := NewKey;
    end;
    try
      WriteFields(A);
      DS.Post;
    except
      DS.Cancel;
      raise;
    end;
    // Von der Datenbank (oder oben) vergebener Schluessel
    if not KeyF.IsNull and (KeyF.AsInteger <> A.Id) then
      A.Id := KeyF.AsInteger;
    FDbKeys.AddOrSetValue(A.Id, True);
    Done := True;
  finally
    Dec(FBusy);
    // Fehlgeschlagen: Anzeige wieder an die Datenmenge angleichen
    if not Done then
      ScheduleReload;
  end;
end;

procedure TPPGCustomDBPlanner.CheckNoForeignEdit;
begin
  // Eine offene Bearbeitung gehoert einem anderen Control (oder dem
  // Anwendungscode). Sie still zu speichern oder durch Locate speichern zu
  // lassen, waere Datenverlust bzw. ungewollte Buchung.
  if FDataLink.DataSet.State in dsEditModes then
  begin
    ScheduleReload;
    raise EPPGError.Create(PPGStr(@SPPGDBEditPending));
  end;
end;

procedure TPPGCustomDBPlanner.DoDeleteAppointment(A: TPPGAppointment);
begin
  if CanWrite and FDbKeys.ContainsKey(A.Id) then
  begin
    CheckNoForeignEdit;
    Inc(FBusy);
    try
      if LocateKey(A.Id) then
        FDataLink.DataSet.Delete;
      FDbKeys.Remove(A.Id);
    finally
      Dec(FBusy);
    end;
  end;
  inherited DoDeleteAppointment(A);
end;

procedure TPPGCustomDBPlanner.SelectionChanged;
var
  A: TPPGAppointment;
begin
  inherited SelectionChanged;
  A := SelectedAppointment;
  if FSyncRecord and (A <> nil) and FDataLink.Active and (Fld(FKeyField) <> nil) and
    not (FDataLink.DataSet.State in dsEditModes) then
  begin
    Inc(FBusy);
    try
      LocateKey(A.Id);
    finally
      Dec(FBusy);
    end;
  end;
end;

end.
