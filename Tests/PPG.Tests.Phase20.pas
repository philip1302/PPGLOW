unit PPG.Tests.Phase20;

{ Tests fuer Phase 20: Fertigstellen bestehender Controls.
  20a: Planer - Serienabfrage (nur Vorkommen / ganze Serie), Ort direkt
  bearbeiten, Termin-Dialog (Laden, Speichern, Pruefen, Haken).
  20b: Kanban - Filter (Text, Labels, Person, Ereignis), Spalten ziehen.
  20c: Ribbon - Tastatur in Gruppen- und Band-Popups, Galerie-Kategorien.
  20d: TrackBar - SelStart/SelEnd, Bereichsregler mit zwei Griffen.
  20e: ComboBox auf der Aufklapp-Basis - festhaltende Tests. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.DateUtils, Vcl.Forms, Vcl.Controls,
  PPG.Calendar, PPG.Planner.Model, PPG.Planner.Recurrence, PPG.Planner, PPG.Planner.Dialog,
  Vcl.Graphics, PPG.Kanban.Items, PPG.Kanban.Layout, PPG.Kanban, PPG.Items, PPG.Ribbon.Items, PPG.Ribbon.Layout, PPG.Ribbon,
  Vcl.ComCtrls, PPG.Controls.Range, PPG.TrackBar, Vcl.StdCtrls, PPG.ComboBox, PPG.Tests.Controls;

type
  TPlannerSeriesTests = class(TControlTestCase)
  private
    FAnswer: TPPGSeriesChoice;
    FActions: string;
    FChanged: Integer;
    function NewPlanner: TPPGPlanner;
    function FindOcc(P: TPPGPlanner; AStart: TDateTime): Integer;
    procedure SeriesEdit(Sender: TObject; const Occurrence: TPPGOccurrence;
      Action: TPPGSeriesAction; var Choice: TPPGSeriesChoice);
    procedure Changed(Sender: TObject; Appointment: TPPGAppointment);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure OccurrenceModeDetaches;
    procedure SeriesModeShiftsAllAndKeepsExceptions;
    procedure SeriesShiftMovesWeekdays;
    procedure SeriesResizeChangesDuration;
    procedure EventDecidesAndCancels;
    procedure DeleteOccurrenceOrSeries;
    procedure SubjectOnOccurrenceDetaches;
    procedure LocationEditInPlace;
    procedure HiddenPlannerDoesNotAsk;
    procedure EditorLoadsAndSavesRule;
    procedure EditorKeepsCustomRule;
    procedure EditorAllDayAndCategories;
    procedure EditorValidates;
    procedure EditAppointmentUsesHook;
    procedure EditOccurrenceDetachesAfterOk;
    procedure OpenUsesEditorOrInline;
    procedure StreamsNewProperties;
  end;

  TKanbanFilterTests = class(TControlTestCase)
  private
    FLog: string;
    FVeto: Boolean;
    function NewBoard: TPPGKanban;
    function Order(K: TPPGKanban): string;
    procedure Key(K: TPPGKanban; AKey: Word; Shift: TShiftState = []);
    procedure ColMoving(Sender: TObject; Column: TPPGKanbanColumn; NewIndex: Integer;
      var Allow: Boolean);
    procedure ColMoved(Sender: TObject; Column: TPPGKanbanColumn);
    procedure OnlyAnna(Sender: TObject; Card: TPPGKanbanCard; var Accept: Boolean);
  protected
    procedure SetUp; override;
  published
    procedure FilterTextHidesAndCounts;
    procedure FilterListsAndEvent;
    procedure WipLimitCountsHiddenCards;
    procedure MoveInsideFilterKeepsHiddenCards;
    procedure MoveColumnByCode;
    procedure ColumnDragByMouse;
    procedure KeyboardMovesColumn;
    procedure LayoutKeepsOrderAndFilter;
    procedure PaintsFilteredAndDragging;
    procedure StreamsFilterProperties;
  end;


  TRibbonPopupKeyTests = class(TControlTestCase)
  private
    FLog: string;
    FGallery: TPPGRibbonItem;
    function NewRibbon: TPPGRibbon;
    procedure NavTo(R: TPPGRibbon; Part: TPPGRibbonPart);
    function CollapsedGroup(R: TPPGRibbon): Integer;
    procedure ItemClick(Sender: TObject; Item: TPPGRibbonItem);
    procedure GalleryClick(Sender: TObject; Item: TPPGRibbonItem; Index: Integer);
    procedure GroupFromEvent(Sender: TObject; Item: TPPGRibbonItem; Index: Integer;
      var Data: TPPGItemData; var AColor: TColor);
  protected
    procedure SetUp; override;
  published
    procedure EnterOpensCollapsedGroupAndNavigates;
    procedure EscapeReturnsToGroup;
    procedure ArrowsAfterMouseOpen;
    procedure MinimizedTabPopupByKeyboard;
    procedure GalleryCategoriesRowsAndKeys;
    procedure GalleryCategoriesFromEvent;
    procedure PaintsPopupsWithFocusAndCategories;
  end;


  TTrackRangeTests = class(TControlTestCase)
  private
    FChanges: Integer;
    function NewTrack: TPPGTrackBar;
    procedure Key(T: TPPGTrackBar; AKey: Word; Shift: TShiftState = []);
    procedure Changed(Sender: TObject);
  protected
    procedure SetUp; override;
  published
    procedure SelRangeLoadsLikeTTrackBar;
    procedure RangeModeKeepsOrder;
    procedure MouseMovesNearerThumb;
    procedure KeyboardTabSwitchesThumb;
    procedure AccessibleThumbs;
    procedure PaintsSelectionAndRange;
    procedure StreamsRangeProperties;
  end;


  TComboDropBaseTests = class(TControlTestCase)
  private
    FLog: string;
    function NewCombo(AStyle: TComboBoxStyle): TPPGComboBox;
    procedure LogDrop(Sender: TObject);
    procedure LogClose(Sender: TObject);
    procedure LogSelect(Sender: TObject);
  protected
    procedure SetUp; override;
  published
    procedure CharsGoToEditWhileOpen;
    procedure HomeEndWhileOpen;
    procedure ClosedKeysAndEnterPassThrough;
    procedure ArrowAndEventsOnOpenClose;
    procedure MouseLeaveKeepsHighlight;
  end;


implementation

uses
  PPG.Tests.Visual,
  PPG.Validator, PPG.Lang, PPG.Consts, PPG.Render.Registry;

type
  TWinControlAccess = class(TWinControl);

const
  Mon = 46174; // 01.06.2026, Montag

var
  GHookCalls: Integer;
  GHookSeries: Boolean;
  GHookCancel: Boolean;

function DT(D: TDateTime; H: Word; N: Word = 0): TDateTime;
begin
  Result := Trunc(D) + EncodeTime(H, N, 0, 0);
end;

function SameTime(A, B: TDateTime): Boolean;
begin
  Result := Abs(A - B) < 1 / SecsPerDay;
end;

function TestHook(Planner: TComponent; A: TPPGAppointment; AllowSeries: Boolean): Boolean;
begin
  Inc(GHookCalls);
  GHookSeries := AllowSeries;
  Result := not GHookCancel;
  if Result then
    A.Subject := A.Subject + ' (bearbeitet)';
end;

{ TPlannerSeriesTests }

procedure TPlannerSeriesTests.SetUp;
begin
  inherited SetUp;
  FAnswer := scOccurrence;
  FActions := '';
  FChanged := 0;
  GHookCalls := 0;
  GHookCancel := False;
  PPGAppointmentDialogHook := TestHook;
end;

procedure TPlannerSeriesTests.TearDown;
begin
  PPGAppointmentDialogHook := nil;
  inherited TearDown;
end;

function TPlannerSeriesTests.NewPlanner: TPPGPlanner;
begin
  Result := TPPGPlanner.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 860, 640);
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.FirstDayOfWeek := fdMonday;
  Result.TimeZone := 'Europe/Berlin';
  Result.Date := Mon + 2;
  Result.NowOverride := DT(Mon + 2, 10, 15);
  Result.OnAppointmentChange := Changed;
end;

function TPlannerSeriesTests.FindOcc(P: TPPGPlanner; AStart: TDateTime): Integer;
var
  I: Integer;
begin
  P.EnsureLayout;
  for I := 0 to P.ItemCount - 1 do
    if SameTime(P.Item(I).Start, AStart) then
      Exit(I);
  Result := -1;
end;

procedure TPlannerSeriesTests.SeriesEdit(Sender: TObject; const Occurrence: TPPGOccurrence;
  Action: TPPGSeriesAction; var Choice: TPPGSeriesChoice);
const
  Names: array[TPPGSeriesAction] of string = ('M', 'R', 'S', 'L', 'D', 'E');
begin
  FActions := FActions + Names[Action];
  Choice := FAnswer;
end;

procedure TPlannerSeriesTests.Changed(Sender: TObject; Appointment: TPPGAppointment);
begin
  Inc(FChanged);
end;

procedure TPlannerSeriesTests.OccurrenceModeDetaches;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  I: Integer;
begin
  P := NewPlanner;
  P.SeriesEditMode := semOccurrence;
  A := P.Appointments.AddAppointment(DT(Mon, 9), DT(Mon, 10), 'Standup');
  A.Recurrence := 'FREQ=DAILY;COUNT=5';
  I := FindOcc(P, DT(Mon + 2, 9));
  CheckTrue(P.ChangeAppointment(P.Item(I), ackMove, DT(Mon + 2, 11), DT(Mon + 2, 12), 0));
  CheckEquals(2, P.Appointments.Count, 'herausgeloest');
  CheckEquals(A.Id, P.Appointments[1].RecurrenceParent);
  CheckEquals(1, Length(A.ExceptionDates), 'Serie hat eine Ausnahme');
end;

procedure TPlannerSeriesTests.SeriesModeShiftsAllAndKeepsExceptions;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  I: Integer;
begin
  P := NewPlanner;
  P.SeriesEditMode := semSeries;
  A := P.Appointments.AddAppointment(DT(Mon, 9), DT(Mon, 10), 'Standup');
  A.Recurrence := 'FREQ=DAILY;COUNT=5';
  A.AddException(DT(Mon + 4, 9));
  CheckEquals(4, P.ItemCount);
  I := FindOcc(P, DT(Mon + 2, 9));
  CheckTrue(P.ChangeAppointment(P.Item(I), ackMove, DT(Mon + 2, 11), DT(Mon + 2, 12), 0));
  CheckEquals(1, P.Appointments.Count, 'nichts herausgeloest');
  CheckTrue(SameTime(DT(Mon, 11), A.Start), 'Serie beginnt um 11');
  P.EnsureLayout;
  CheckEquals(4, P.ItemCount, 'Ausnahme wandert mit');
  for I := 0 to P.ItemCount - 1 do
    CheckEquals(11, HourOf(P.Item(I).Start), 'alle um 11');
  CheckEquals(-1, FindOcc(P, DT(Mon + 4, 11)), 'Freitag bleibt ausgenommen');
  CheckTrue(SameTime(DT(Mon + 2, 11), P.SelectedAppointment.Start) or (P.SelectedAppointment = A));
end;

procedure TPlannerSeriesTests.SeriesShiftMovesWeekdays;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  I: Integer;
  R: TPPGRecurrence;
begin
  P := NewPlanner;
  P.SeriesEditMode := semSeries;
  A := P.Appointments.AddAppointment(DT(Mon, 9), DT(Mon, 10), 'Jour fixe');
  A.Recurrence := 'FREQ=WEEKLY;BYDAY=MO,WE';
  I := FindOcc(P, DT(Mon, 9));
  CheckTrue(P.ChangeAppointment(P.Item(I), ackMove, DT(Mon + 1, 9), DT(Mon + 1, 10), 0));
  R := A.Rule;
  CheckEquals(2, Length(R.ByDay));
  CheckEquals(2, R.ByDay[0].Weekday, 'Montag -> Dienstag');
  CheckEquals(4, R.ByDay[1].Weekday, 'Mittwoch -> Donnerstag');
  CheckTrue(FindOcc(P, DT(Mon + 3, 9)) >= 0, 'Donnerstag da');
  CheckEquals(-1, FindOcc(P, DT(Mon + 2, 9)), 'Mittwoch weg');
end;

procedure TPlannerSeriesTests.SeriesResizeChangesDuration;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  I: Integer;
begin
  P := NewPlanner;
  P.SeriesEditMode := semSeries;
  A := P.Appointments.AddAppointment(DT(Mon, 9), DT(Mon, 10), 'Standup');
  A.Recurrence := 'FREQ=DAILY;COUNT=3';
  I := FindOcc(P, DT(Mon + 1, 9));
  CheckTrue(P.ChangeAppointment(P.Item(I), ackResize, DT(Mon + 1, 9), DT(Mon + 1, 9, 30), 0));
  CheckTrue(SameTime(DT(Mon, 9), A.Start), 'Beginn bleibt');
  CheckTrue(SameTime(DT(Mon, 9, 30), A.Finish), 'alle eine halbe Stunde');
end;

procedure TPlannerSeriesTests.EventDecidesAndCancels;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  I: Integer;
begin
  P := NewPlanner;
  P.OnSeriesEdit := SeriesEdit;
  A := P.Appointments.AddAppointment(DT(Mon, 9), DT(Mon, 10), 'Standup');
  A.Recurrence := 'FREQ=DAILY;COUNT=5';
  FAnswer := scCancel;
  I := FindOcc(P, DT(Mon + 1, 9));
  CheckFalse(P.ChangeAppointment(P.Item(I), ackMove, DT(Mon + 1, 11), DT(Mon + 1, 12), 0), 'abgebrochen');
  CheckFalse(P.ChangeAppointment(P.Item(I), ackResize, DT(Mon + 1, 9), DT(Mon + 1, 11), 0));
  CheckEquals('MR', FActions, 'Aktionen gemeldet');
  CheckEquals(1, P.Appointments.Count);
  CheckTrue(SameTime(DT(Mon, 9), A.Start), 'nichts geaendert');
  P.SelectAppointment(A);
  CheckFalse(P.DeleteSelected, 'Loeschen abgebrochen');
  CheckEquals('MRD', FActions);
  // Kopieren fragt nicht
  CheckTrue(P.ChangeAppointment(P.Item(I), ackCopy, DT(Mon + 1, 14), DT(Mon + 1, 15), 0));
  CheckEquals('MRD', FActions, 'Kopie ohne Abfrage');
  // Termin ohne Serie fragt nie
  FActions := '';
  I := FindOcc(P, DT(Mon + 1, 14));
  P.ChangeAppointment(P.Item(I), ackMove, DT(Mon + 1, 16), DT(Mon + 1, 17), 0);
  CheckEquals('', FActions);
end;

procedure TPlannerSeriesTests.DeleteOccurrenceOrSeries;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  I: Integer;
begin
  P := NewPlanner;
  P.OnSeriesEdit := SeriesEdit;
  A := P.Appointments.AddAppointment(DT(Mon, 9), DT(Mon, 10), 'Standup');
  A.Recurrence := 'FREQ=DAILY;COUNT=5';
  // ein herausgeloestes Vorkommen dazu
  FAnswer := scOccurrence;
  I := FindOcc(P, DT(Mon + 3, 9));
  P.ChangeAppointment(P.Item(I), ackMove, DT(Mon + 3, 13), DT(Mon + 3, 14), 0);
  CheckEquals(2, P.Appointments.Count);
  // Nur dieses Vorkommen loeschen (SelectAppointment waehlt das erste: Montag)
  P.SelectAppointment(A);
  CheckTrue(SameTime(DT(Mon, 9), P.Item(P.SelectedItem).Start));
  CheckTrue(P.DeleteSelected);
  CheckEquals(2, P.Appointments.Count, 'Serie bleibt');
  CheckEquals(-1, FindOcc(P, DT(Mon, 9)), 'Montag ausgenommen');
  // Ganze Serie samt herausgeloestem Termin
  FAnswer := scSeries;
  P.SelectAppointment(A);
  CheckTrue(P.DeleteSelected);
  CheckEquals(0, P.Appointments.Count, 'Serie und Einzeltermin weg');
  CheckEquals('MDD', FActions);
end;

procedure TPlannerSeriesTests.SubjectOnOccurrenceDetaches;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
begin
  P := NewPlanner;
  P.OnSeriesEdit := SeriesEdit;
  A := P.Appointments.AddAppointment(DT(Mon, 9), DT(Mon, 10), 'Standup');
  A.Recurrence := 'FREQ=DAILY;COUNT=5';
  FForm.Show;
  P.SelectAppointment(A);
  P.BeginEditSubject;
  CheckTrue(P.Editing);
  P.Editor.Text := 'Planung';
  FAnswer := scOccurrence;
  P.EndEditSubject(True);
  CheckEquals('S', FActions);
  CheckEquals(2, P.Appointments.Count, 'Vorkommen herausgeloest');
  CheckEquals('Standup', A.Subject, 'Serie unveraendert');
  CheckEquals('Planung', P.Appointments[1].Subject);
  // Ganze Serie
  P.SelectAppointment(A);
  P.BeginEditSubject;
  P.Editor.Text := 'Daily';
  FAnswer := scSeries;
  P.EndEditSubject(True);
  CheckEquals('Daily', A.Subject);
  CheckEquals(2, P.Appointments.Count);
  FForm.Hide;
end;

procedure TPlannerSeriesTests.LocationEditInPlace;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  K: Word;
begin
  P := NewPlanner;
  A := P.Appointments.AddAppointment(DT(Mon + 1, 9), DT(Mon + 1, 10), 'Review');
  A.Location := 'Raum 1';
  FForm.Show;
  P.SelectAppointment(A);
  K := VK_F2;
  TWinControlAccess(P).KeyDown(K, [ssShift]);
  CheckTrue(P.Editing, 'Umschalt+F2');
  CheckEquals('Raum 1', P.Editor.Text, 'zeigt den Ort');
  P.Editor.Text := 'Raum 2';
  P.EndEditSubject(True);
  CheckEquals('Raum 2', A.Location);
  CheckEquals('Review', A.Subject, 'Betreff bleibt');
  CheckEquals(1, FChanged);
  P.BeginEditLocation;
  P.Editor.Text := 'egal';
  P.EndEditSubject(False);
  CheckEquals('Raum 2', A.Location, 'Esc verwirft');
  FForm.Hide;
end;

procedure TPlannerSeriesTests.HiddenPlannerDoesNotAsk;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  I: Integer;
begin
  P := NewPlanner;
  CheckTrue(P.SeriesEditMode = semAsk, 'Vorgabe');
  A := P.Appointments.AddAppointment(DT(Mon, 9), DT(Mon, 10), 'Standup');
  A.Recurrence := 'FREQ=DAILY;COUNT=5';
  I := FindOcc(P, DT(Mon + 1, 9));
  // Formular nicht sichtbar: keine Abfrage, nur das Vorkommen wie bisher
  CheckTrue(P.SeriesChoice(P.Item(I), saMove) = scOccurrence);
  P.SeriesEditMode := semSeries;
  CheckTrue(P.SeriesChoice(P.Item(I), saMove) = scSeries);
end;

procedure TPlannerSeriesTests.EditorLoadsAndSavesRule;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  E: TPPGAppointmentEditor;
  R: TPPGRecurrence;
begin
  P := NewPlanner;
  A := P.Appointments.AddAppointment(DT(Mon, 9), DT(Mon, 10, 30), 'Jour fixe');
  A.Location := 'Raum 3';
  A.Recurrence := 'FREQ=WEEKLY;BYDAY=MO,WE;COUNT=10';
  E := TPPGAppointmentEditor.CreateEditor(P, True);
  try
    E.LoadFrom(A);
    CheckEquals('Jour fixe', E.Subject.Text);
    CheckEquals('Raum 3', E.Location.Text);
    CheckEquals(2, E.Freq.ItemIndex, 'woechentlich');
    CheckTrue(E.WeekDays.Checked[0] and E.WeekDays.Checked[2] and not E.WeekDays.Checked[1]);
    CheckEquals(1, E.Ends.ItemIndex, 'nach N');
    CheckEquals(10, E.EndCount.Value);
    CheckTrue(SameTime(DT(Mon, 10, 30), Int(E.FinishDate.Date) + Frac(E.FinishTime.Time)));
    // Aendern: alle 2 Tage bis zum 30.06.
    E.Freq.ItemIndex := 1;
    E.Interval.Value := 2;
    E.Ends.ItemIndex := 2;
    E.EndDate.Date := EncodeDate(2026, 6, 30);
    E.Subject.Text := 'Abstimmung';
    E.SaveTo(A);
  finally
    E.Free;
  end;
  CheckEquals('Abstimmung', A.Subject);
  R := A.Rule;
  CheckTrue(R.Freq = rfDaily);
  CheckEquals(2, R.Interval);
  CheckEquals(0, R.Count);
  CheckEquals(EncodeDate(2026, 6, 30), Int(R.UntilDate), 'bis einschliesslich');
  // Wiederholung "keine"
  E := TPPGAppointmentEditor.CreateEditor(P, True);
  try
    E.LoadFrom(A);
    CheckEquals(1, E.Freq.ItemIndex);
    E.Freq.ItemIndex := 0;
    E.SaveTo(A);
  finally
    E.Free;
  end;
  CheckFalse(A.IsRecurring, 'Serie aufgehoben');
end;

procedure TPlannerSeriesTests.EditorKeepsCustomRule;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  E: TPPGAppointmentEditor;
begin
  P := NewPlanner;
  A := P.Appointments.AddAppointment(DT(Mon + 8, 9), DT(Mon + 8, 10), 'Monatsrunde');
  A.Recurrence := 'FREQ=MONTHLY;BYDAY=2TU';
  E := TPPGAppointmentEditor.CreateEditor(P, True);
  try
    E.LoadFrom(A);
    CheckEquals(5, E.Freq.ItemIndex, 'benutzerdefiniert');
    CheckEquals('FREQ=MONTHLY;BYDAY=2TU', E.CustomRule);
    E.Location.Text := 'Kantine';
    E.SaveTo(A);
  finally
    E.Free;
  end;
  CheckEquals('FREQ=MONTHLY;BYDAY=2TU', A.Recurrence, 'unveraendert');
  CheckEquals('Kantine', A.Location);
  // Taeglich an Werktagen wird als woechentlich gezeigt
  A.Recurrence := 'FREQ=DAILY;BYDAY=MO,TU,WE,TH,FR';
  E := TPPGAppointmentEditor.CreateEditor(P, True);
  try
    E.LoadFrom(A);
    CheckEquals(2, E.Freq.ItemIndex);
    CheckTrue(E.WeekDays.Checked[4] and not E.WeekDays.Checked[5]);
  finally
    E.Free;
  end;
end;

procedure TPlannerSeriesTests.EditorAllDayAndCategories;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  E: TPPGAppointmentEditor;
begin
  P := NewPlanner;
  P.Categories.Add;
  P.Categories[0].Caption := 'Kunde';
  P.Categories.Add;
  P.Categories[1].Caption := 'Intern';
  P.Resources.AddResource(7, 'Anna');
  P.Resources.AddResource(9, 'Ben');
  A := P.Appointments.Add;
  A.AllDay := True;
  A.Subject := 'Messe';
  A.Start := Mon + 1;
  A.Finish := Mon + 4; // Dienstag bis Donnerstag (Ende exklusiv)
  A.Category := 1;
  A.ResourceId := 9;
  E := TPPGAppointmentEditor.CreateEditor(P, False);
  try
    E.LoadFrom(A);
    CheckFalse(E.SeriesBox.Visible, 'ohne Serie');
    CheckTrue(E.AllDay.Checked);
    CheckEquals(Mon + 3, Int(E.FinishDate.Date), 'letzter Tag Donnerstag');
    CheckEquals(2, E.Category.ItemIndex, 'Intern (nach "Keine")');
    CheckEquals(1, E.Resource.ItemIndex, 'Ben');
    E.FinishDate.Date := Mon + 4;
    E.Category.ItemIndex := 0;
    E.Resource.ItemIndex := 0;
    E.SaveTo(A);
  finally
    E.Free;
  end;
  CheckTrue(SameTime(Mon + 5, A.Finish), 'bis einschliesslich Freitag');
  CheckEquals(-1, A.Category);
  CheckEquals(7, A.ResourceId);
end;

procedure TPlannerSeriesTests.EditorValidates;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  E: TPPGAppointmentEditor;
begin
  P := NewPlanner;
  A := P.Appointments.AddAppointment(DT(Mon, 9), DT(Mon, 10), 'X');
  E := TPPGAppointmentEditor.CreateEditor(P, True);
  try
    E.LoadFrom(A);
    CheckTrue(E.Validator.Validate);
    E.Subject.Text := '';
    CheckFalse(E.Validator.Validate, 'Betreff Pflicht');
    E.Subject.Text := 'X';
    E.FinishTime.Time := EncodeTime(8, 0, 0, 0);
    CheckFalse(E.Validator.Validate, 'Ende vor Beginn');
    E.FinishTime.Time := EncodeTime(11, 0, 0, 0);
    CheckTrue(E.Validator.Validate);
  finally
    E.Free;
  end;
end;

procedure TPlannerSeriesTests.EditAppointmentUsesHook;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
begin
  P := NewPlanner;
  A := P.Appointments.AddAppointment(DT(Mon + 1, 9), DT(Mon + 1, 10), 'Review');
  P.SelectAppointment(A);
  CheckTrue(P.EditAppointment);
  CheckEquals(1, GHookCalls);
  CheckTrue(GHookSeries, 'Einzeltermin: Serie darf angelegt werden');
  CheckEquals('Review (bearbeitet)', A.Subject);
  CheckEquals(1, FChanged);
  GHookCancel := True;
  CheckFalse(P.EditAppointment, 'Abbrechen');
  CheckEquals(1, FChanged);
  P.ReadOnly := True;
  CheckFalse(P.EditAppointment, 'schreibgeschuetzt');
  CheckEquals(2, GHookCalls);
end;

procedure TPlannerSeriesTests.EditOccurrenceDetachesAfterOk;
var
  P: TPPGPlanner;
  A, X: TPPGAppointment;
  I: Integer;
begin
  P := NewPlanner;
  P.OnSeriesEdit := SeriesEdit;
  A := P.Appointments.AddAppointment(DT(Mon, 9), DT(Mon, 10), 'Standup');
  A.Recurrence := 'FREQ=DAILY;COUNT=5';
  FAnswer := scOccurrence;
  I := FindOcc(P, DT(Mon + 2, 9));
  GHookCancel := True;
  CheckFalse(P.EditAppointment(I));
  CheckEquals(1, P.Appointments.Count, 'Abbrechen loest nichts heraus');
  GHookCancel := False;
  I := FindOcc(P, DT(Mon + 2, 9));
  CheckTrue(P.EditAppointment(I));
  CheckFalse(GHookSeries, 'Vorkommen: keine Serie im Dialog');
  CheckEquals(2, P.Appointments.Count);
  X := P.Appointments[1];
  CheckEquals('Standup (bearbeitet)', X.Subject);
  CheckEquals('Standup', A.Subject, 'Serie unveraendert');
  CheckEquals(A.Id, X.RecurrenceParent);
  CheckTrue(SameTime(DT(Mon + 2, 9), X.Start));
  // Ganze Serie: der Dialog bearbeitet die Serie selbst
  FAnswer := scSeries;
  I := FindOcc(P, DT(Mon + 3, 9));
  CheckTrue(P.EditAppointment(I));
  CheckEquals('Standup (bearbeitet)', A.Subject);
  CheckTrue(GHookSeries);
  CheckEquals('EEE', FActions);
end;

procedure TPlannerSeriesTests.OpenUsesEditorOrInline;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  K: Word;
begin
  P := NewPlanner;
  A := P.Appointments.AddAppointment(DT(Mon + 1, 9), DT(Mon + 1, 10), 'Review');
  FForm.Show;
  P.SelectAppointment(A);
  K := VK_RETURN;
  TWinControlAccess(P).KeyDown(K, []);
  CheckEquals(1, GHookCalls, 'Enter oeffnet den Dialog');
  P.DefaultEditor := False;
  K := VK_RETURN;
  TWinControlAccess(P).KeyDown(K, []);
  CheckEquals(1, GHookCalls);
  CheckTrue(P.Editing, 'ohne Dialog: Betreff direkt');
  P.EndEditSubject(False);
  FForm.Hide;
end;

procedure TPlannerSeriesTests.StreamsNewProperties;
var
  M: TMemoryStream;
  P, P2: TPPGPlanner;
begin
  P := NewPlanner;
  P.SeriesEditMode := semSeries;
  P.DefaultEditor := False;
  M := TMemoryStream.Create;
  try
    M.WriteComponent(P);
    M.Position := 0;
    P2 := TPPGPlanner.Create(FForm);
    M.ReadComponent(P2);
    CheckTrue(P2.SeriesEditMode = semSeries);
    CheckFalse(P2.DefaultEditor);
  finally
    M.Free;
  end;
end;

{ TKanbanFilterTests }

type
  TKanbanAccess = class(TPPGCustomKanban);

procedure TKanbanFilterTests.SetUp;
begin
  inherited SetUp;
  FLog := '';
  FVeto := False;
end;

function TKanbanFilterTests.NewBoard: TPPGKanban;
var
  A, B, C: TPPGKanbanColumn;
begin
  Result := TPPGKanban.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 1080, 640);
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.OnColumnMoving := ColMoving;
  Result.OnColumnMoved := ColMoved;
  A := Result.Columns.AddColumn('Offen');
  B := Result.Columns.AddColumn('Arbeit', 2);
  C := Result.Columns.AddColumn('Fertig');
  with Result.Cards.AddCard(A.Id, 'Login-Fehler') do
  begin
    Labels := 'Bug, UI';
    Assignee := 'Anna';
  end;
  with Result.Cards.AddCard(A.Id, 'Neue Startseite') do
  begin
    Labels := 'UI';
    Assignee := 'Ben';
  end;
  with Result.Cards.AddCard(A.Id, 'Export', 'Excel mit <b>Bug</b>-Liste') do
    Assignee := 'Anna';
  with Result.Cards.AddCard(B.Id, 'Datenbank') do
    Assignee := 'Ben';
  with Result.Cards.AddCard(B.Id, 'Bug im Druck') do
    Labels := 'Bug';
  Result.Cards.AddCard(C.Id, 'Release 1.0');
end;

procedure TKanbanFilterTests.ColMoving(Sender: TObject; Column: TPPGKanbanColumn;
  NewIndex: Integer; var Allow: Boolean);
begin
  FLog := FLog + Format('moving:%s>%d;', [Column.Title, NewIndex]);
  if FVeto then
    Allow := False;
end;

procedure TKanbanFilterTests.ColMoved(Sender: TObject; Column: TPPGKanbanColumn);
begin
  FLog := FLog + 'moved:' + Column.Title + ';';
end;

procedure TKanbanFilterTests.OnlyAnna(Sender: TObject; Card: TPPGKanbanCard; var Accept: Boolean);
begin
  Accept := Accept and (Card.Assignee = 'Anna');
end;

function TKanbanFilterTests.Order(K: TPPGKanban): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to K.ColumnCount - 1 do
    Result := Result + K.LayoutColumn(I).Title + ' ';
  Result := Trim(Result);
end;

procedure TKanbanFilterTests.FilterTextHidesAndCounts;
var
  K: TPPGKanban;
begin
  K := NewBoard;
  CheckFalse(K.IsFiltered);
  K.FilterText := 'bug';
  CheckTrue(K.IsFiltered);
  CheckEquals(2, K.ColumnCardCount(0), 'Titel, Label und Text (ohne Markup)');
  CheckEquals(1, K.ColumnHiddenCount(0));
  CheckEquals(3, K.ColumnTotalCount(0));
  CheckEquals(1, K.ColumnCardCount(1), 'Bug im Druck');
  CheckEquals(0, K.ColumnCardCount(2));
  CheckEquals('Login-Fehler', K.CardAt(0, 0, 0).Title);
  CheckEquals('Export', K.CardAt(0, 0, 1).Title, 'Treffer im Text');
  K.FilterText := 'ANNA';
  CheckEquals(2, K.ColumnCardCount(0), 'Person, ohne Gross-/Kleinschreibung');
  K.FilterText := '';
  CheckEquals(3, K.ColumnCardCount(0));
  CheckEquals(0, K.ColumnHiddenCount(0));
end;

procedure TKanbanFilterTests.FilterListsAndEvent;
var
  K: TPPGKanban;
begin
  K := NewBoard;
  K.FilterLabels := 'ui, Doku';
  CheckEquals(2, K.ColumnCardCount(0), 'irgendein Label der Liste');
  CheckEquals(0, K.ColumnCardCount(1));
  K.FilterLabels := '';
  K.FilterAssignee := 'Ben,Carla';
  CheckEquals(1, K.ColumnCardCount(0));
  CheckEquals(1, K.ColumnCardCount(1));
  K.FilterAssignee := '';
  K.OnFilterCard := OnlyAnna;
  CheckTrue(K.IsFiltered);
  CheckEquals(2, K.ColumnCardCount(0));
  K.FilterText := 'export';
  CheckEquals(1, K.ColumnCardCount(0), 'alle Bedingungen zusammen');
  K.OnFilterCard := nil;
end;

procedure TKanbanFilterTests.WipLimitCountsHiddenCards;
var
  K: TPPGKanban;
begin
  K := NewBoard;
  K.WipMode := kwmBlock;
  K.FilterText := 'druck';
  CheckEquals(1, K.ColumnCardCount(1));
  CheckTrue(K.WipState(1) = kwsFull, 'Limit 2 mit einer ausgeblendeten Karte voll');
  K.FilterText := '';
  CheckFalse(K.MoveCard(0, 0, 0, 1, 0, 0), 'gesperrt: volle Spalte');
end;

procedure TKanbanFilterTests.MoveInsideFilterKeepsHiddenCards;
var
  K: TPPGKanban;
  I: Integer;
  S: string;
begin
  K := NewBoard;
  K.FilterAssignee := 'Anna';
  // sichtbar in "Offen": Login-Fehler, Export; ausgeblendet: Neue Startseite
  CheckEquals(2, K.ColumnCardCount(0));
  CheckTrue(K.MoveCard(0, 0, 1, 0, 0, 0), 'Export nach vorn');
  CheckEquals('Export', K.CardAt(0, 0, 0).Title);
  K.FilterAssignee := '';
  S := '';
  for I := 0 to K.CardCount(0, 0) - 1 do
    S := S + K.CardAt(0, 0, I).Title + ';';
  CheckEquals('Export;Login-Fehler;Neue Startseite;', S, 'ausgeblendete Karte bleibt hinter ihrem Nachbarn');
end;

procedure TKanbanFilterTests.MoveColumnByCode;
var
  K: TPPGKanban;
begin
  K := NewBoard;
  CheckTrue(K.MoveColumn(0, 3));
  CheckEquals('Arbeit Fertig Offen', Order(K));
  CheckEquals('moving:Offen>2;moved:Offen;', FLog);
  CheckTrue(K.Announcement <> '', 'Ansage fuer den Screenreader');
  CheckFalse(K.MoveColumn(1, 1), 'vor sich selbst');
  CheckFalse(K.MoveColumn(1, 2), 'hinter sich selbst');
  FVeto := True;
  CheckFalse(K.MoveColumn(2, 0), 'abgelehnt');
  CheckEquals('Arbeit Fertig Offen', Order(K));
  FVeto := False;
  // Ausgeblendete Spalte behaelt ihren Platz in der Collection
  K.Columns[1].Visible := False; // "Fertig" (Collection: Arbeit, Fertig, Offen)
  CheckEquals('Arbeit Offen', Order(K));
  CheckTrue(K.MoveColumn(1, 0));
  CheckEquals('Offen Arbeit', Order(K));
  K.Columns.FindById(3).Visible := True;
  K.ReadOnly := True;
  CheckFalse(K.MoveColumn(0, 2), 'schreibgeschuetzt');
end;

procedure TKanbanFilterTests.ColumnDragByMouse;
var
  K: TPPGKanban;
  A, B: TPoint;
  R: TRect;
begin
  K := NewBoard;
  R := K.HeaderRect(0);
  A := Point(R.Left + 30, (R.Top + R.Bottom) div 2);
  B := Point(K.HeaderRect(2).Right - 10, A.Y);
  K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(A.X, A.Y));
  K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(A.X + 20, A.Y));
  CheckTrue(K.ColumnDragging, 'Ziehen beginnt');
  K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(B.X, B.Y));
  CheckEquals(3, K.ColumnDropIndex, 'hinter die letzte');
  K.Perform(WM_LBUTTONUP, 0, MakeLParam(B.X, B.Y));
  CheckFalse(K.ColumnDragging);
  CheckEquals('Arbeit Fertig Offen', Order(K));
  // Esc bricht ab
  R := K.HeaderRect(0);
  A := Point(R.Left + 30, (R.Top + R.Bottom) div 2);
  K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(A.X, A.Y));
  K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(B.X, B.Y));
  CheckTrue(K.ColumnDragging);
  Key(K, VK_ESCAPE);
  CheckFalse(K.ColumnDragging);
  K.Perform(WM_LBUTTONUP, 0, MakeLParam(B.X, B.Y));
  CheckEquals('Arbeit Fertig Offen', Order(K), 'unveraendert');
  K.AllowColumnDrag := False;
  K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(A.X, A.Y));
  K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(B.X, B.Y));
  CheckFalse(K.ColumnDragging, 'abgeschaltet');
  K.Perform(WM_LBUTTONUP, 0, MakeLParam(B.X, B.Y));
end;

procedure TKanbanFilterTests.KeyboardMovesColumn;
var
  K: TPPGKanban;
begin
  K := NewBoard;
  K.Select(0, 0, 0);
  Key(K, VK_RIGHT, [ssCtrl, ssShift]);
  CheckEquals('Arbeit Offen Fertig', Order(K));
  CheckEquals(1, K.Focus.Col, 'Fokus wandert mit');
  Key(K, VK_LEFT, [ssCtrl, ssShift]);
  CheckEquals('Offen Arbeit Fertig', Order(K));
end;

procedure TKanbanFilterTests.LayoutKeepsOrderAndFilter;
var
  K: TPPGKanban;
  S: string;
begin
  K := NewBoard;
  K.MoveColumn(2, 0);
  K.FilterText := 'bug';
  K.FilterAssignee := 'Anna';
  S := K.SaveLayout;
  K.MoveColumn(0, 3);
  K.FilterText := '';
  K.FilterAssignee := '';
  K.LoadLayout(S);
  CheckEquals('Fertig Offen Arbeit', Order(K));
  CheckEquals('bug', K.FilterText);
  CheckEquals('Anna', K.FilterAssignee);
  CheckEquals(2, K.ColumnCardCount(1), 'Filter wirkt nach dem Laden');
end;

procedure TKanbanFilterTests.PaintsFilteredAndDragging;
var
  S: TBitmap;
  K: TPPGKanban;
  B: TBitmap;
  Gdi: Boolean;
  R: TRect;
begin
  K := NewBoard;
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    try
      K.FilterText := 'bug';
      PPGPaintCheck(Self, K, 'K');
      R := K.HeaderRect(0);
      K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(R.Left + 30, R.Top + 10));
      K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(K.HeaderRect(1).Right - 5, R.Top + 10));
      PPGPaintCheck(Self, K, 'K');
      Key(K, VK_ESCAPE);
      K.Perform(WM_LBUTTONUP, 0, MakeLParam(R.Left + 30, R.Top + 10));
      K.BiDiMode := bdRightToLeft;
      PPGPaintCheck(Self, K, 'K');
      K.BiDiMode := bdLeftToRight;
      K.FilterText := '';
    finally
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
  // Audit 11b: Filter und Spalten-Ziehen sind sichtbar (GDI+ und GDI)
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    try
      K.FilterText := '';
      B := RenderToBitmap(K);
      try
        K.FilterText := 'bug';
        S := RenderToBitmap(K);
        try
          PPGCheckDiffers(Self, B, S, 'Kanban Filter');
        finally
          S.Free;
        end;
        K.FilterText := '';
        R := K.HeaderRect(0);
        K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(R.Left + 30, R.Top + 10));
        K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(K.HeaderRect(1).Right - 5, R.Top + 10));
        S := RenderToBitmap(K);
        try
          PPGCheckDiffers(Self, B, S, 'Kanban Spalte ziehen');
        finally
          S.Free;
          Key(K, VK_ESCAPE);
          K.Perform(WM_LBUTTONUP, 0, MakeLParam(R.Left + 30, R.Top + 10));
        end;
      finally
        B.Free;
      end;
    finally
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TKanbanFilterTests.StreamsFilterProperties;
var
  M: TMemoryStream;
  K, K2: TPPGKanban;
begin
  K := NewBoard;
  K.FilterText := 'x';
  K.FilterLabels := 'Bug';
  K.FilterAssignee := 'Anna';
  K.AllowColumnDrag := False;
  M := TMemoryStream.Create;
  try
    M.WriteComponent(K);
    M.Position := 0;
    K2 := TPPGKanban.Create(FForm);
    M.ReadComponent(K2);
    CheckEquals('x', K2.FilterText);
    CheckEquals('Bug', K2.FilterLabels);
    CheckEquals('Anna', K2.FilterAssignee);
    CheckFalse(K2.AllowColumnDrag);
  finally
    M.Free;
  end;
end;

procedure TKanbanFilterTests.Key(K: TPPGKanban; AKey: Word; Shift: TShiftState);
var
  W: Word;
begin
  W := AKey;
  TKanbanAccess(K).KeyDown(W, Shift);
end;


{ TRibbonPopupKeyTests }

procedure TRibbonPopupKeyTests.SetUp;
begin
  inherited SetUp;
  FLog := '';
end;

procedure TRibbonPopupKeyTests.ItemClick(Sender: TObject; Item: TPPGRibbonItem);
begin
  FLog := FLog + 'click:' + Item.Caption + ';';
end;

procedure TRibbonPopupKeyTests.GalleryClick(Sender: TObject; Item: TPPGRibbonItem; Index: Integer);
begin
  FLog := FLog + 'gallery:' + IntToStr(Index) + ';';
end;

procedure TRibbonPopupKeyTests.GroupFromEvent(Sender: TObject; Item: TPPGRibbonItem; Index: Integer;
  var Data: TPPGItemData; var AColor: TColor);
begin
  if Index < 2 then
    Data.Group := 'Oben'
  else
    Data.Group := 'Unten';
end;

function TRibbonPopupKeyTests.NewRibbon: TPPGRibbon;
var
  T: TPPGRibbonTab;
  G: TPPGRibbonGroup;
begin
  Result := TPPGRibbon.Create(FForm);
  Result.Parent := FForm;
  Result.Animation.Enabled := False;
  Result.Align := alNone;
  Result.SetBounds(0, 0, 900, 140);
  Result.OnItemClick := ItemClick;
  Result.OnGalleryClick := GalleryClick;
  T := Result.Tabs.AddTab('Start');
  // kurzer Titel, viele Befehle: als Dropdown schmaler als klein
  G := T.Groups.AddGroup('Ab');
  G.Items.AddButton('Einfuegen', $E77F, rsLarge);
  G.Items.AddButton('Ausschneiden', $E8C6, rsMedium);
  G.Items.AddButton('Kopieren', $E8C8, rsMedium);
  G.Items.AddButton('Format', $E8DC, rsMedium);
  G.Items.AddButton('Loeschen', $E74D, rsMedium);
  G.Items.AddButton('Alles', $E8B3, rsMedium);
  G.Items.AddButton('Leeren', $E894, rsMedium);
  G := T.Groups.AddGroup('Bearbeiten');
  G.Items.AddButton('Suchen', $E721, rsMedium);
  G.Items.AddButton('Ersetzen', $E8AB, rsMedium);
  G := T.Groups.AddGroup('Vorlagen');
  FGallery := G.Items.Add;
  FGallery.Kind := rikGallery;
  FGallery.Caption := 'Vorlagen';
  FGallery.GalleryColumns := 2;
  FGallery.GalleryPopupColumns := 3;
  FGallery.GalleryItems.Add('Titel|Ueberschrift 1');
  FGallery.GalleryItems.Add('Titel|Ueberschrift 2');
  FGallery.GalleryItems.Add('Text|Standard');
  FGallery.GalleryItems.Add('Text|Zitat');
  FGallery.GalleryItems.Add('Text|Code');
  Result.Tabs.AddTab('Einfuegen').Groups.AddGroup('Tabellen').Items.AddButton('Tabelle', $E80A, rsLarge);
  FForm.ClientWidth := 900;
  FForm.Show;
  Result.UpdateLayout;
end;

function TRibbonPopupKeyTests.CollapsedGroup(R: TPPGRibbon): Integer;
var
  I: Integer;
begin
  for I := 0 to R.GroupCount - 1 do
    if R.GroupState(I) = rgsCollapsed then
      Exit(I);
  Result := -1;
end;

procedure TRibbonPopupKeyTests.NavTo(R: TPPGRibbon; Part: TPPGRibbonPart);
var
  I: Integer;
begin
  for I := 0 to R.ElementCount do
  begin
    if R.NavHit.Part = Part then
      Exit;
    R.HandleNavKey(VK_TAB, []);
  end;
  Fail('Element nicht gefunden');
end;

procedure TRibbonPopupKeyTests.EnterOpensCollapsedGroupAndNavigates;
var
  R: TPPGRibbon;
  H: TPPGRibbonHit;
begin
  R := NewRibbon;
  R.Width := 90;
  R.UpdateLayout;
  CheckTrue(CollapsedGroup(R) >= 0, 'eine Gruppe als Dropdown: ' + IntToStr(R.GroupCount) + ' Breite ' + IntToStr(R.Width) + ' Zustand ' + IntToStr(Ord(R.GroupState(0))) + IntToStr(Ord(R.GroupState(R.GroupCount - 1))));
  R.EnterKeyboardNavigation;
  NavTo(R, rpGroup);
  R.HandleNavKey(VK_RETURN, []);
  CheckTrue((R.GroupPopup <> nil) and R.GroupPopup.IsOpen, 'Popup offen');
  CheckTrue(R.KeyboardNavigation, 'Tastatur bleibt aktiv');
  H := R.NavHit;
  CheckTrue(H.View = R.GroupPopup.View, 'Fokus im Popup');
  CheckTrue(H.Part = rpItem);
  CheckEquals(7, R.ElementCount, 'nur die Befehle des Popups');
  R.HandleNavKey(VK_TAB, []);
  R.HandleNavKey(VK_TAB, []);
  CheckTrue(R.NavHit.View = R.GroupPopup.View, 'Tab bleibt im Popup');
  R.HandleNavKey(VK_RETURN, []);
  CheckEquals('click:Kopieren;', FLog, 'Enter loest aus');
  CheckFalse(R.GroupPopup.IsOpen, 'Popup zu');
  CheckFalse(R.KeyboardNavigation);
end;

procedure TRibbonPopupKeyTests.EscapeReturnsToGroup;
var
  R: TPPGRibbon;
begin
  R := NewRibbon;
  R.Width := 90;
  R.UpdateLayout;
  R.EnterKeyboardNavigation;
  NavTo(R, rpGroup);
  R.HandleNavKey(VK_RETURN, []);
  CheckTrue(R.GroupPopup.IsOpen);
  R.HandleNavKey(VK_ESCAPE, []);
  CheckFalse(R.GroupPopup.IsOpen, 'Esc schliesst das Popup');
  CheckTrue(R.KeyboardNavigation, 'eine Ebene zurueck');
  CheckTrue(R.NavHit.Part = rpGroup, 'Fokus wieder auf der Gruppe');
  R.HandleNavKey(VK_ESCAPE, []);
  CheckFalse(R.KeyboardNavigation, 'zweites Esc verlaesst die Tastatur');
end;

procedure TRibbonPopupKeyTests.ArrowsAfterMouseOpen;
var
  R: TPPGRibbon;
  P: TPoint;
begin
  R := NewRibbon;
  R.Width := 90;
  R.UpdateLayout;
  P := Point((R.GroupRect(CollapsedGroup(R)).Left + R.GroupRect(CollapsedGroup(R)).Right) div 2,
    (R.GroupRect(CollapsedGroup(R)).Top + R.GroupRect(CollapsedGroup(R)).Bottom) div 2);
  R.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(P.X, P.Y));
  R.Perform(WM_LBUTTONUP, 0, MakeLParam(P.X, P.Y));
  CheckTrue(R.GroupPopup.IsOpen, 'mit der Maus geoeffnet');
  CheckFalse(R.KeyboardNavigation);
  PostMessage(FForm.Handle, WM_KEYDOWN, VK_DOWN, 0);
  Application.ProcessMessages;
  CheckTrue(R.KeyboardNavigation, 'Pfeil fuehrt ins Popup');
  CheckTrue(R.NavHit.View = R.GroupPopup.View);
  R.HandleNavKey(VK_ESCAPE, []);
  CheckFalse(R.GroupPopup.IsOpen);
end;

procedure TRibbonPopupKeyTests.MinimizedTabPopupByKeyboard;
var
  R: TPPGRibbon;
begin
  R := NewRibbon;
  R.Minimized := True;
  R.UpdateLayout;
  R.EnterKeyboardNavigation;
  CheckTrue(R.NavHit.Part = rpTab, 'Start auf der Registerkarte');
  R.HandleNavKey(VK_RETURN, []);
  CheckTrue((R.PanelPopup <> nil) and R.PanelPopup.IsOpen, 'Karte als Popup');
  CheckTrue(R.KeyboardNavigation);
  CheckTrue(R.NavHit.View = R.PanelPopup.View, 'Fokus im Popup der Karte');
  R.HandleNavKey(VK_ESCAPE, []);
  CheckFalse(R.PanelPopup.IsOpen);
  CheckTrue(R.NavHit.Part = rpTab, 'zurueck zur Registerkarte');
  R.LeaveKeyboardNavigation;
end;

procedure TRibbonPopupKeyTests.GalleryCategoriesRowsAndKeys;
var
  R: TPPGRibbon;
  G: TPPGRibbonGalleryPopup;
begin
  R := NewRibbon;
  R.OpenGallery(FGallery);
  G := R.GalleryPopup;
  CheckTrue((G <> nil) and G.IsOpen);
  CheckTrue(G.Grouped, 'Kategorien aus "Kategorie|Text"');
  CheckEquals(4, G.RowCount, 'Titel, 2 Kacheln, Text, 3 Kacheln');
  CheckTrue(G.TileRect(2).Top > G.TileRect(1).Bottom, 'neue Kategorie in neuer Zeile');
  CheckEquals(G.TileRect(0).Left, G.TileRect(2).Left, 'beginnt links');
  CheckEquals(G.TileRect(2).Top, G.TileRect(4).Top, 'Text: eine Zeile mit drei Kacheln');
  // Tastatur: Spalte halten, Ueberschriften ueberspringen
  G.HandleKey(VK_HOME);
  CheckEquals(0, G.FocusIndex);
  G.HandleKey(VK_DOWN);
  CheckEquals(2, G.FocusIndex, 'erste Kachel der naechsten Kategorie');
  G.HandleKey(VK_RIGHT);
  G.HandleKey(VK_RIGHT);
  CheckEquals(4, G.FocusIndex);
  G.HandleKey(VK_UP);
  CheckEquals(1, G.FocusIndex, 'Spalte begrenzt auf die kuerzere Zeile');
  G.HandleKey(VK_DOWN);
  G.HandleKey(VK_RETURN);
  CheckEquals('gallery:3;', FLog);
  CheckFalse(G.IsOpen);
end;

procedure TRibbonPopupKeyTests.GalleryCategoriesFromEvent;
var
  R: TPPGRibbon;
  G: TPPGRibbonGalleryPopup;
  I: Integer;
begin
  R := NewRibbon;
  for I := 0 to FGallery.GalleryItems.Count - 1 do
    FGallery.GalleryItems[I] := 'Eintrag ' + IntToStr(I);
  R.OpenGallery(FGallery);
  CheckFalse(R.GalleryPopup.Grouped, 'ohne Kategorie: einfaches Raster');
  CheckEquals(2, R.GalleryPopup.RowCount);
  R.ClosePopups;
  R.OnGetGalleryItem := GroupFromEvent;
  R.OpenGallery(FGallery);
  G := R.GalleryPopup;
  CheckTrue(G.Grouped, 'Data.Group aus OnGetGalleryItem');
  CheckEquals(4, G.RowCount);
end;

procedure TRibbonPopupKeyTests.PaintsPopupsWithFocusAndCategories;
var
  S: TBitmap;
  R: TPPGRibbon;
  B: TBitmap;
  Gdi: Boolean;
begin
  R := NewRibbon;
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    try
      R.Width := 90;
      R.UpdateLayout;
      R.EnterKeyboardNavigation;
      NavTo(R, rpGroup);
      R.HandleNavKey(VK_RETURN, []);
      PPGPaintCheck(Self, R.GroupPopup, 'R.GroupPopup');
      R.HandleNavKey(VK_ESCAPE, []);
      R.LeaveKeyboardNavigation;
      R.Width := 900;
      R.UpdateLayout;
      R.OpenGallery(FGallery);
      R.GalleryPopup.HandleKey(VK_DOWN);
      PPGPaintCheck(Self, R.GalleryPopup, 'R.GalleryPopup');
      R.ClosePopups;
    finally
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
  // Audit 11b: die Tastatur-Markierung im Galerie-Popup ist sichtbar (GDI+ und GDI)
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    try
      R.Width := 900;
      R.UpdateLayout;
      R.OpenGallery(FGallery);
      B := RenderToBitmap(R.GalleryPopup);
      try
        PPGCheckPainted(Self, B, 'Galerie');
        R.GalleryPopup.HandleKey(VK_DOWN);
        S := RenderToBitmap(R.GalleryPopup);
        try
          PPGCheckDiffers(Self, B, S, 'Galerie: Markierung nach Pfeil');
        finally
          S.Free;
        end;
      finally
        B.Free;
        R.ClosePopups;
      end;
    finally
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;


{ TTrackRangeTests }

type
  TTrackAccess = class(TPPGCustomTrackBar);

procedure TTrackRangeTests.SetUp;
begin
  inherited SetUp;
  FChanges := 0;
end;

procedure TTrackRangeTests.Changed(Sender: TObject);
begin
  Inc(FChanges);
end;

function TTrackRangeTests.NewTrack: TPPGTrackBar;
begin
  Result := TPPGTrackBar.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 320, 44);
  Result.Animation.Enabled := False;
  Result.SetRange(0, 100);
  Result.OnChange := Changed;
end;

procedure TTrackRangeTests.Key(T: TPPGTrackBar; AKey: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := AKey;
  TTrackAccess(T).KeyDown(K, Shift);
end;

procedure TTrackRangeTests.SelRangeLoadsLikeTTrackBar;
const
  Dfm =
    'object Track: TPPGTrackBar'#13#10 +
    '  Left = 0'#13#10 +
    '  Top = 0'#13#10 +
    '  Width = 200'#13#10 +
    '  Height = 40'#13#10 +
    '  Max = 20'#13#10 +
    '  Position = 5'#13#10 +
    '  SelEnd = 12'#13#10 +
    '  SelStart = 4'#13#10 +
    '  ShowSelRange = False'#13#10 +
    'end';
var
  Src: TStringStream;
  Bin: TMemoryStream;
  T: TPPGTrackBar;
begin
  Src := TStringStream.Create(Dfm);
  Bin := TMemoryStream.Create;
  try
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    T := TPPGTrackBar.Create(FForm);
    Bin.ReadComponent(T);
    T.Parent := FForm;
    CheckEquals(4, T.SelStart);
    CheckEquals(12, T.SelEnd);
    CheckFalse(T.ShowSelRange);
    CheckEquals(5, T.Position, 'Position unberuehrt');
  finally
    Bin.Free;
    Src.Free;
  end;
end;

procedure TTrackRangeTests.RangeModeKeepsOrder;
var
  T: TPPGTrackBar;
begin
  T := NewTrack;
  T.Position := 20;
  T.RangeMode := True;
  CheckEquals(100, T.PositionEnd, 'Ende vor dem Anfang: ans Maximum');
  T.PositionEnd := 60;
  CheckEquals(60, T.PositionEnd);
  T.PositionEnd := 10;
  CheckEquals(20, T.PositionEnd, 'Ende ueberholt den Anfang nicht');
  T.PositionEnd := 500;
  CheckEquals(100, T.PositionEnd, 'begrenzt auf Max');
  T.Position := 80;
  T.PositionEnd := 90;
  T.Position := 95;
  CheckEquals(95, T.PositionEnd, 'Code schiebt das Ende mit');
  CheckTrue(FChanges >= 5, 'OnChange fuer beide Werte');
end;

procedure TTrackRangeTests.MouseMovesNearerThumb;
var
  T: TPPGTrackBar;
  R: TRect;
  Y: Integer;
begin
  T := NewTrack;
  T.RangeMode := True;
  T.Position := 20;
  T.PositionEnd := 60;
  R := T.ClientRect;
  Y := (R.Top + R.Bottom) div 2;
  // Klick weit rechts: das Ende (naeher)
  T.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(R.Right - 20, Y));
  T.Perform(WM_LBUTTONUP, 0, MakeLParam(R.Right - 20, Y));
  CheckEquals(1, T.ActiveThumb);
  CheckTrue(T.PositionEnd > 80, 'Ende springt hin');
  CheckEquals(20, T.Position, 'Anfang bleibt');
  // Klick links: der Anfang
  T.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(R.Left + 20, Y));
  CheckEquals(0, T.ActiveThumb);
  // Ziehen ueber das Ende hinaus: bleibt am Ende stehen
  T.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(R.Right - 2, Y));
  T.Perform(WM_LBUTTONUP, 0, MakeLParam(R.Right - 2, Y));
  CheckEquals(T.PositionEnd, T.Position, 'Anfang ueberholt das Ende nicht');
end;

procedure TTrackRangeTests.KeyboardTabSwitchesThumb;
var
  T: TPPGTrackBar;
begin
  T := NewTrack;
  T.RangeMode := True;
  T.Position := 30;
  T.PositionEnd := 40;
  Key(T, VK_RIGHT);
  CheckEquals(31, T.Position, 'Pfeil bewegt den Anfang');
  Key(T, VK_TAB);
  CheckEquals(1, T.ActiveThumb, 'Tab: zum Ende');
  Key(T, VK_RIGHT);
  CheckEquals(41, T.PositionEnd);
  Key(T, VK_END);
  CheckEquals(100, T.PositionEnd);
  Key(T, VK_TAB, [ssShift]);
  CheckEquals(0, T.ActiveThumb, 'Umschalt+Tab zurueck');
  Key(T, VK_HOME);
  CheckEquals(0, T.Position);
  // ohne RangeMode bleibt Tab beim Formular
  T.RangeMode := False;
  Key(T, VK_TAB);
  CheckEquals(0, T.ActiveThumb);
end;

procedure TTrackRangeTests.AccessibleThumbs;
var
  T: TPPGTrackBar;
  A: TTrackAccess;
begin
  T := NewTrack;
  A := TTrackAccess(T);
  CheckEquals(0, A.AccChildCount, 'ohne Bereich keine Kinder');
  T.RangeMode := True;
  T.Position := 10;
  T.PositionEnd := 70;
  CheckEquals(2, A.AccChildCount);
  CheckEquals(Format(PPGStr(@SPPGTrackRangeFrom), [10]), A.AccChildName(1));
  CheckEquals(Format(PPGStr(@SPPGTrackRangeTo), [70]), A.AccChildName(2));
  CheckEquals(Format(PPGStr(@SPPGTrackRangeValue), [10, 70]), A.AccValue);
  CheckFalse(IsRectEmpty(A.AccChildRect(2)));
  CheckEquals(2, A.AccChildAt((A.AccChildRect(2).Left + A.AccChildRect(2).Right) div 2,
    (A.AccChildRect(2).Top + A.AccChildRect(2).Bottom) div 2));
end;

procedure TTrackRangeTests.PaintsSelectionAndRange;
var
  S: TBitmap;
  T: TPPGTrackBar;
  B: TBitmap;
  Gdi: Boolean;
begin
  T := NewTrack;
  T.SelStart := 20;
  T.SelEnd := 70;
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    try
      PPGPaintCheck(Self, T, 'T');
      T.RangeMode := True;
      T.Position := 30;
      T.PositionEnd := 60;
      PPGPaintCheck(Self, T, 'T');
      T.Orientation := trVertical;
      PPGPaintCheck(Self, T, 'T');
      T.Orientation := trHorizontal;
      T.BiDiMode := bdRightToLeft;
      PPGPaintCheck(Self, T, 'T');
      T.BiDiMode := bdLeftToRight;
      T.Enabled := False;
      PPGPaintCheck(Self, T, 'T');
      T.Enabled := True;
      T.RangeMode := False;
    finally
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
  // Audit 11b: Auswahlbereich, Bereichsmodus und Deaktiviert sind sichtbar
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    try
      T.SelStart := 0;
      T.SelEnd := 0;
      B := RenderToBitmap(T);
      try
        T.SelStart := 20;
        T.SelEnd := 70;
        S := RenderToBitmap(T);
        try
          PPGCheckDiffers(Self, B, S, 'Auswahlbereich');
        finally
          S.Free;
        end;
        T.RangeMode := True;
        T.Position := 30;
        T.PositionEnd := 60;
        S := RenderToBitmap(T);
        try
          PPGCheckDiffers(Self, B, S, 'Bereichsmodus');
        finally
          S.Free;
          T.RangeMode := False;
        end;
      finally
        B.Free;
      end;
    finally
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
  PPGCheckStates(Self, T, 'TrackBar', False, False, True, Point(0, 0));
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TTrackRangeTests.StreamsRangeProperties;
var
  M: TMemoryStream;
  T, T2: TPPGTrackBar;
begin
  T := NewTrack;
  T.RangeMode := True;
  T.Position := 15;
  T.PositionEnd := 45;
  T.SelStart := 5;
  T.SelEnd := 9;
  M := TMemoryStream.Create;
  try
    M.WriteComponent(T);
    M.Position := 0;
    T2 := TPPGTrackBar.Create(FForm);
    M.ReadComponent(T2);
    CheckTrue(T2.RangeMode);
    CheckEquals(15, T2.Position);
    CheckEquals(45, T2.PositionEnd);
    CheckEquals(5, T2.SelStart);
    CheckEquals(9, T2.SelEnd);
  finally
    M.Free;
  end;
end;


{ TComboDropBaseTests }

type
  TComboAccess20 = class(TPPGCustomComboBox);

function LP20(X, Y: Integer): LPARAM;
begin
  Result := MakeLParam(Word(X and $FFFF), Word(Y and $FFFF));
end;

procedure TComboDropBaseTests.SetUp;
begin
  inherited SetUp;
  FLog := '';
end;

procedure TComboDropBaseTests.LogDrop(Sender: TObject);
begin
  FLog := FLog + 'drop;';
end;

procedure TComboDropBaseTests.LogClose(Sender: TObject);
begin
  FLog := FLog + 'close:' + IntToStr(TPPGComboBox(Sender).ItemIndex) + ';';
end;

procedure TComboDropBaseTests.LogSelect(Sender: TObject);
begin
  FLog := FLog + 'select:' + IntToStr(TPPGComboBox(Sender).ItemIndex) + ';';
end;

function TComboDropBaseTests.NewCombo(AStyle: TComboBoxStyle): TPPGComboBox;
begin
  Result := TPPGComboBox.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 160, 25);
  Result.Animation.Enabled := False;
  Result.Style := AStyle;
  Result.Items.CommaText := 'Apfel,Banane,Birne,Cola,Dattel';
  Result.OnDropDown := LogDrop;
  Result.OnCloseUp := LogClose;
  Result.OnSelect := LogSelect;
  FForm.Show;
  Result.SetFocus;
end;

procedure TComboDropBaseTests.CharsGoToEditWhileOpen;
var
  C: TPPGComboBox;
  Ch: Char;
begin
  C := NewCombo(csDropDown);
  C.DropDown;
  CheckTrue(C.DroppedDown);
  Ch := 'B';
  TComboAccess20(C).FieldKeyPress(Ch);
  CheckEquals('B', string(Ch), 'Zeichen bleibt fuer das Edit');
  CheckTrue(C.DroppedDown, 'Liste bleibt offen');
  Ch := #13;
  TComboAccess20(C).FieldKeyPress(Ch);
  CheckEquals(#0, string(Ch), 'Enter ohne Signalton');
  C.CloseUp(False);
  // Liste: Zeichen sind Tippsuche und werden verbraucht
  C.Style := csDropDownList;
  C.DropDown;
  Ch := 'c';
  TComboAccess20(C).FieldKeyPress(Ch);
  CheckEquals(#0, string(Ch));
  CheckEquals(3, C.PopupList.Highlight, 'Tippsuche in der offenen Liste');
  CheckTrue(C.DroppedDown);
  C.CloseUp(False);
end;

procedure TComboDropBaseTests.HomeEndWhileOpen;
var
  C: TPPGComboBox;
  K: Word;
begin
  C := NewCombo(csDropDown);
  C.ItemIndex := 2;
  C.DropDown;
  K := VK_HOME;
  TComboAccess20(C).FieldKeyDown(K, []);
  CheckEquals(VK_HOME, K, 'Pos1 bewegt den Cursor im Edit');
  CheckEquals(2, C.PopupList.Highlight, 'Hervorhebung bleibt');
  K := VK_LEFT;
  TComboAccess20(C).FieldKeyDown(K, []);
  CheckEquals(VK_LEFT, K, 'Pfeil links gehoert dem Edit');
  CheckTrue(C.DroppedDown);
  C.CloseUp(False);
  C.Style := csDropDownList;
  C.DropDown;
  K := VK_END;
  TComboAccess20(C).FieldKeyDown(K, []);
  CheckEquals(0, K);
  CheckEquals(4, C.PopupList.Highlight, 'Ende: letzter Eintrag');
  K := VK_HOME;
  TComboAccess20(C).FieldKeyDown(K, []);
  CheckEquals(0, C.PopupList.Highlight);
  K := VK_NEXT;
  TComboAccess20(C).FieldKeyDown(K, []);
  CheckTrue(C.PopupList.Highlight > 0, 'Bild ab');
  K := VK_RETURN;
  TComboAccess20(C).FieldKeyDown(K, []);
  CheckFalse(C.DroppedDown);
  CheckEquals(C.ItemIndex, C.PopupList.Highlight, 'Enter uebernimmt');
end;

procedure TComboDropBaseTests.ClosedKeysAndEnterPassThrough;
var
  C: TPPGComboBox;
  K: Word;
begin
  C := NewCombo(csDropDownList);
  K := VK_DOWN;
  TComboAccess20(C).FieldKeyDown(K, []);
  CheckEquals(0, C.ItemIndex, 'Pfeil waehlt geschlossen direkt');
  K := VK_NEXT;
  TComboAccess20(C).FieldKeyDown(K, []);
  CheckEquals(4, C.ItemIndex, 'Bild ab: DropDownCount - 1 weiter');
  K := VK_RETURN;
  TComboAccess20(C).FieldKeyDown(K, []);
  CheckEquals(VK_RETURN, K, 'Enter geschlossen: fuer den Default-Button');
  CheckFalse(TComboAccess20(C).WantSpecialKey(VK_RETURN));
  CheckFalse(TComboAccess20(C).WantSpecialKey(VK_ESCAPE));
  K := VK_F4;
  TComboAccess20(C).FieldKeyDown(K, []);
  CheckTrue(C.DroppedDown);
  CheckTrue(TComboAccess20(C).WantSpecialKey(VK_ESCAPE));
  K := VK_ESCAPE;
  TComboAccess20(C).FieldKeyDown(K, []);
  CheckFalse(C.DroppedDown);
  CheckEquals('select:0;select:4;drop;close:4;', FLog);
end;

procedure TComboDropBaseTests.ArrowAndEventsOnOpenClose;
var
  C: TPPGComboBox;
begin
  C := NewCombo(csDropDownList);
  CheckEquals(0.0, C.ArrowProgress, 0.001);
  C.DroppedDown := True;
  CheckEquals(1.0, C.ArrowProgress, 0.001, 'Pfeil gedreht');
  CheckEquals(0, C.PopupList.TopIndex);
  CheckEquals(-1, C.PopupList.Highlight, 'ohne Auswahl keine Hervorhebung');
  C.PopupList.SetHighlight(1);
  C.CloseUp(True);
  CheckEquals(0.0, C.ArrowProgress, 0.001);
  CheckEquals('drop;select:1;close:1;', FLog, 'Auswahl vor OnCloseUp');
  C.Enabled := False;
  C.DroppedDown := True;
  CheckFalse(C.DroppedDown, 'abgeschaltet: kein Aufklappen');
end;

procedure TComboDropBaseTests.MouseLeaveKeepsHighlight;
var
  C: TPPGComboBox;
  P: TPoint;
begin
  C := NewCombo(csDropDownList);
  C.DropDown;
  P := C.ScreenToClient(C.PopupList.ClientToScreen(Point(10,
    (C.PopupList.ItemRect(2).Top + C.PopupList.ItemRect(2).Bottom) div 2)));
  C.Perform(WM_MOUSEMOVE, 0, LP20(P.X, P.Y));
  CheckEquals(2, C.PopupList.Highlight, 'Maus hebt hervor');
  C.Perform(WM_MOUSEMOVE, 0, LP20(-5, -5));
  CheckEquals(2, C.PopupList.Highlight, 'ausserhalb bleibt die Hervorhebung');
  CheckTrue(C.DroppedDown);
  // Loslassen ausserhalb uebernimmt nichts
  C.Perform(WM_LBUTTONUP, 0, LP20(-5, -5));
  CheckTrue(C.DroppedDown);
  CheckEquals(-1, C.ItemIndex);
  C.CloseUp(False);
end;

initialization
  RegisterTest('Phase20', TPlannerSeriesTests.Suite);
  RegisterTest('Phase20', TKanbanFilterTests.Suite);
  RegisterTest('Phase20', TRibbonPopupKeyTests.Suite);
  RegisterTest('Phase20', TTrackRangeTests.Suite);
  RegisterTest('Phase20', TComboDropBaseTests.Suite);

end.
