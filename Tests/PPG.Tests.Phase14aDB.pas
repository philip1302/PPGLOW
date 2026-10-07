unit PPG.Tests.Phase14aDB;

{ Tests fuer Phase 14a: TPPGDBPlanner (PPG.DB.Planner) auf einem
  TClientDataSet im Speicher. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.DateUtils, System.Variants, Vcl.Controls, Vcl.Forms,
  Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Calendar, PPG.Planner.Model, PPG.Planner, PPG.DB.Planner, PPG.Tests.Controls;

type
  TDBPlannerTests = class(TControlTestCase)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    FRanges: TStringList;
    procedure AddRow(AId: Integer; AStart, AFinish: TDateTime; const ASubject: string;
      ARes: Integer = 0; const ARule: string = '');
    function NewPlanner: TPPGDBPlanner;
    procedure GetRange(Sender: TObject; AFrom, ATo: TDateTime);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure LoadsRecordsAsAppointments;
    procedure UtcFieldsShowLocal;
    procedure MoveWritesBack;
    procedure CreateAndDeleteWriteRecords;
    procedure DetachWritesSeriesAndOccurrence;
    procedure ExternalChangeReloadsInPlace;
    procedure GetRangeOnPaging;
    procedure SelectionMovesRecord;
    procedure WithoutKeyIsReadOnly;
    procedure ClosedDataSetClears;
  end;

implementation

const
  Mon = 46174; // 01.06.2026

function DT(D: TDateTime; H: Word; N: Word = 0): TDateTime;
begin
  Result := Trunc(D) + EncodeTime(H, N, 0, 0);
end;

function Center(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

{ TDBPlannerTests }

procedure TDBPlannerTests.SetUp;
begin
  inherited SetUp;
  FForm.SetBounds(0, 0, 900, 700);
  FRanges := TStringList.Create;
  FData := TClientDataSet.Create(FForm);
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Beginn', ftDateTime);
  FData.FieldDefs.Add('Ende', ftDateTime);
  FData.FieldDefs.Add('Betreff', ftString, 80);
  FData.FieldDefs.Add('Ort', ftString, 40);
  FData.FieldDefs.Add('Ressource', ftInteger);
  FData.FieldDefs.Add('Regel', ftString, 120);
  FData.FieldDefs.Add('Ausnahmen', ftString, 400);
  FData.FieldDefs.Add('Serie', ftInteger);
  FData.FieldDefs.Add('Ganztags', ftBoolean);
  FData.FieldDefs.Add('Kategorie', ftInteger);
  FData.CreateDataSet;
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
end;

procedure TDBPlannerTests.TearDown;
begin
  FreeAndNil(FRanges);
  inherited TearDown;
end;

procedure TDBPlannerTests.AddRow(AId: Integer; AStart, AFinish: TDateTime; const ASubject: string;
  ARes: Integer; const ARule: string);
begin
  FData.Append;
  FData.FieldByName('ID').AsInteger := AId;
  FData.FieldByName('Beginn').AsDateTime := AStart;
  FData.FieldByName('Ende').AsDateTime := AFinish;
  FData.FieldByName('Betreff').AsString := ASubject;
  FData.FieldByName('Ressource').AsInteger := ARes;
  if ARule <> '' then
    FData.FieldByName('Regel').AsString := ARule;
  FData.Post;
end;

function TDBPlannerTests.NewPlanner: TPPGDBPlanner;
begin
  Result := TPPGDBPlanner.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 860, 640);
  Result.Animation.Enabled := False;
  Result.FirstDayOfWeek := fdMonday;
  Result.TimeZoneMode := tzmLocal;
  Result.Date := Mon + 2;
  Result.NowOverride := DT(Mon + 2, 10);
  Result.ReloadDelay := 0;
  Result.KeyField := 'ID';
  Result.StartField := 'Beginn';
  Result.FinishField := 'Ende';
  Result.SubjectField := 'Betreff';
  Result.LocationField := 'Ort';
  Result.ResourceField := 'Ressource';
  Result.RecurrenceField := 'Regel';
  Result.ExDatesField := 'Ausnahmen';
  Result.ParentField := 'Serie';
  Result.AllDayField := 'Ganztags';
  Result.CategoryField := 'Kategorie';
  Result.DataSource := FSource;
  Result.HandleNeeded;
end;

procedure TDBPlannerTests.GetRange(Sender: TObject; AFrom, ATo: TDateTime);
begin
  FRanges.Add(FormatDateTime('yyyy-mm-dd', AFrom) + '/' + FormatDateTime('yyyy-mm-dd', ATo));
end;

procedure TDBPlannerTests.LoadsRecordsAsAppointments;
var
  P: TPPGDBPlanner;
begin
  AddRow(10, DT(Mon + 1, 9), DT(Mon + 1, 10), 'A', 2);
  AddRow(11, DT(Mon + 2, 9), DT(Mon + 2, 10), 'B');
  FData.First;
  FData.Next;
  P := NewPlanner;
  CheckEquals(2, P.LoadedCount);
  CheckEquals(2, P.Appointments.Count);
  CheckEquals(10, P.Appointments[0].Id);
  CheckEquals('A', P.Appointments[0].Subject);
  CheckEquals(2, P.Appointments[0].ResourceId);
  CheckEquals(-1, P.Appointments[0].Category, 'NULL = keine Kategorie');
  CheckEquals(DT(Mon + 1, 9), P.Appointments[0].Start, 1E-9);
  CheckEquals(2, P.ItemCount);
  CheckEquals(11, FData.FieldByName('ID').AsInteger, 'Position bleibt');
end;

procedure TDBPlannerTests.UtcFieldsShowLocal;
var
  P: TPPGDBPlanner;
begin
  AddRow(1, DT(Mon + 1, 7), DT(Mon + 1, 8), 'UTC');
  P := NewPlanner;
  P.TimeZone := 'Europe/Berlin';
  P.TimeZoneMode := tzmUtc;
  P.Reload;
  CheckEquals(DT(Mon + 1, 9), P.Appointments[0].Start, 1E-9, '07:00 UTC = 09:00 MESZ');
end;

procedure TDBPlannerTests.MoveWritesBack;
var
  P: TPPGDBPlanner;
begin
  AddRow(1, DT(Mon + 1, 9), DT(Mon + 1, 10), 'A');
  P := NewPlanner;
  P.SelectAppointment(P.Appointments[0]);
  CheckTrue(P.MoveSelected(60, 1));
  CheckTrue(FData.Locate('ID', 1, []));
  CheckEquals(DT(Mon + 2, 10), FData.FieldByName('Beginn').AsDateTime, 1E-6);
  CheckEquals(DT(Mon + 2, 11), FData.FieldByName('Ende').AsDateTime, 1E-6);
  CheckEquals(1, FData.RecordCount);
  CheckTrue(FData.State = dsBrowse);
  CheckFalse(P.ReloadPending, 'eigenes Schreiben laedt nicht neu');
end;

procedure TDBPlannerTests.CreateAndDeleteWriteRecords;
var
  P: TPPGDBPlanner;
  A: TPPGAppointment;
begin
  AddRow(5, DT(Mon + 1, 9), DT(Mon + 1, 10), 'A');
  P := NewPlanner;
  A := P.CreateAppointment(DT(Mon + 3, 14), DT(Mon + 3, 15));
  CheckNotNull(A);
  CheckEquals(6, A.Id, 'naechste freie Nummer');
  CheckEquals(2, FData.RecordCount);
  CheckTrue(FData.Locate('ID', 6, []));
  CheckEquals(DT(Mon + 3, 14), FData.FieldByName('Beginn').AsDateTime, 1E-6);
  P.EndEditSubject(True);
  P.SelectAppointment(A);
  CheckTrue(P.DeleteSelected);
  CheckEquals(1, FData.RecordCount);
  CheckFalse(FData.Locate('ID', 6, []));
  CheckEquals(1, P.Appointments.Count);
end;

procedure TDBPlannerTests.DetachWritesSeriesAndOccurrence;
var
  P: TPPGDBPlanner;
begin
  AddRow(1, DT(Mon, 9), DT(Mon, 10), 'Standup', 0, 'FREQ=DAILY;COUNT=5');
  P := NewPlanner;
  CheckEquals(5, P.ItemCount);
  CheckEquals(Mon + 2, Trunc(P.Item(2).Start), 'Mittwoch');
  CheckTrue(P.ChangeAppointment(P.Item(2), ackMove, DT(Mon + 2, 11), DT(Mon + 2, 12), 0));
  CheckEquals(2, FData.RecordCount, 'Einzeltermin eingefuegt');
  CheckTrue(FData.Locate('ID', 1, []));
  CheckTrue(Pos('20260603T090000', FData.FieldByName('Ausnahmen').AsString) > 0,
    'Ausnahme der Serie: ' + FData.FieldByName('Ausnahmen').AsString);
  CheckTrue(FData.Locate('Serie', 1, []));
  CheckEquals(DT(Mon + 2, 11), FData.FieldByName('Beginn').AsDateTime, 1E-6);
  CheckTrue(FData.FieldByName('Regel').AsString = '');
end;

procedure TDBPlannerTests.ExternalChangeReloadsInPlace;
var
  P: TPPGDBPlanner;
  A: TPPGAppointment;
begin
  AddRow(1, DT(Mon + 1, 9), DT(Mon + 1, 10), 'A');
  AddRow(2, DT(Mon + 1, 11), DT(Mon + 1, 12), 'B');
  P := NewPlanner;
  A := P.Appointments[0];
  P.SelectAppointment(A);
  FData.Locate('ID', 1, []);
  FData.Edit;
  FData.FieldByName('Betreff').AsString := 'A2';
  FData.Post;
  CheckSame(A, P.Appointments[0], 'gleiches Objekt');
  CheckEquals('A2', A.Subject);
  CheckSame(A, P.SelectedAppointment, 'Auswahl bleibt');
  FData.Locate('ID', 2, []);
  FData.Delete;
  CheckEquals(1, P.Appointments.Count, 'geloeschter Datensatz verschwindet');
  // Verzoegert: erst nach FlushReload
  P.ReloadDelay := 500;
  AddRow(3, DT(Mon + 3, 9), DT(Mon + 3, 10), 'C');
  CheckTrue(P.ReloadPending);
  CheckEquals(1, P.Appointments.Count);
  P.FlushReload;
  CheckEquals(2, P.Appointments.Count);
end;

procedure TDBPlannerTests.GetRangeOnPaging;
var
  P: TPPGDBPlanner;
begin
  AddRow(1, DT(Mon + 1, 9), DT(Mon + 1, 10), 'A');
  P := NewPlanner;
  P.OnGetRange := GetRange;
  P.NextPage;
  CheckEquals(1, FRanges.Count);
  CheckEquals('2026-06-08/2026-06-15', FRanges[0]);
  P.View := pvMonth;
  CheckEquals('2026-06-01/2026-07-13', FRanges[FRanges.Count - 1], 'Monatsraster Juni');
end;

procedure TDBPlannerTests.SelectionMovesRecord;
var
  P: TPPGDBPlanner;
begin
  AddRow(1, DT(Mon + 1, 9), DT(Mon + 1, 10), 'A');
  AddRow(2, DT(Mon + 2, 9), DT(Mon + 2, 10), 'B');
  FData.First;
  P := NewPlanner;
  // Auswahl durch den Anwender (Tab) stellt den Datensatz ein
  P.Perform(WM_KEYDOWN, VK_TAB, 0);
  P.Perform(WM_KEYDOWN, VK_TAB, 0);
  CheckEquals('B', P.SelectedAppointment.Subject);
  CheckEquals(2, FData.FieldByName('ID').AsInteger, 'Datensatz folgt der Auswahl');
end;

procedure TDBPlannerTests.WithoutKeyIsReadOnly;
var
  P: TPPGDBPlanner;
begin
  AddRow(1, DT(Mon + 1, 9), DT(Mon + 1, 10), 'A');
  P := NewPlanner;
  P.KeyField := '';
  CheckTrue(P.Appointments[0].ReadOnly);
  P.SelectAppointment(P.Appointments[0]);
  CheckFalse(P.MoveSelected(30, 0), 'ohne Schluessel nicht aenderbar');
end;

procedure TDBPlannerTests.ClosedDataSetClears;
var
  P: TPPGDBPlanner;
begin
  AddRow(1, DT(Mon + 1, 9), DT(Mon + 1, 10), 'A');
  P := NewPlanner;
  CheckEquals(1, P.Appointments.Count);
  FData.Close;
  CheckEquals(0, P.Appointments.Count);
  FData.Open;
  CheckEquals(1, P.Appointments.Count);
  FSource.Free;
  CheckNull(P.DataSource);
  CheckEquals(0, P.Appointments.Count);
end;

initialization
  RegisterTest('Phase14a', TDBPlannerTests.Suite);

end.
