unit PPG.Tests.Phase14aPlanner;

{$WARN SYMBOL_PLATFORM OFF}

{ Tests fuer Phase 14a: das Control TPPGPlanner (Ansichten, Anordnung,
  Treffer, Ziehen, Tastatur, Ereignisse, Screenreader, Kalender, Streaming,
  Zeichnen). Datum fest: Woche ab Montag, 01.06.2026. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.DateUtils, Vcl.Controls, Vcl.Forms, Vcl.Graphics,
  Vcl.Imaging.pngimage, PPG.Types, PPG.Accessibility, PPG.Render.Registry, PPG.Theme,
  PPG.Controls.Base, PPG.Calendar, PPG.Planner.Model, PPG.Planner, PPG.Print,
  PPG.Planner.Print, PPG.Tests.Controls;

type
  TPlannerTests = class(TControlTestCase)
  private
    FLog: TStringList;
    FVeto: Boolean;
    FFreeInDeleting: Boolean;
    function NewPlanner: TPPGPlanner;
    procedure Click(P: TPPGPlanner; const Pt: TPoint; Keys: Integer = 0);
    procedure Drag(P: TPPGPlanner; const A, B: TPoint; Keys: Integer = 0);
    procedure Key(P: TPPGPlanner; AKey: Word; Shift: TShiftState = []);
    procedure Changing(Sender: TObject; Appointment: TPPGAppointment;
      Kind: TPPGAppointmentChangeKind; var NewStart, NewFinish: TDateTime;
      var NewResourceId: Integer; var Allow: Boolean);
    procedure Changed(Sender: TObject; Appointment: TPPGAppointment);
    procedure Created(Sender: TObject; Appointment: TPPGAppointment);
    procedure Deleting(Sender: TObject; Appointment: TPPGAppointment; var Allow: Boolean);
    procedure Creating(Sender: TObject; AStart, AFinish: TDateTime; AResourceId: Integer;
      AAllDay: Boolean; var Allow: Boolean);
    procedure RangeChange(Sender: TObject);
    procedure Shot(P: TPPGPlanner; const Name: string);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure RangesPerView;
    procedure PagingAndRangeEvent;
    procedure OverlapsShareColumn;
    procedure AllDayAndMultiDayInBand;
    procedure MidnightSplitsWithMarks;
    procedure HitTestSlotsEdgesAndRtl;
    procedure DragMovesWithSnap;
    procedure DragVetoAndCopy;
    procedure ResizeEndByDrag;
    procedure DragDetachesOccurrence;
    procedure SelectSlotsByDragAndCreate;
    procedure TypingCreatesAndEditsSubject;
    procedure EscapeDropsNewAppointment;
    procedure KeyboardMovesAndDeletes;
    procedure ReleasesRemovedAppointments;
    procedure TabWalksAppointments;
    procedure ResourcesAsColumns;
    procedure TimelineRowsAndResourceDrag;
    procedure MonthShowsMore;
    procedure AgendaListsDays;
    procedure AccessibleChildren;
    procedure CalendarLink;
    procedure StreamingRoundTrip;
    procedure ResourcesGetUniqueIds;
    procedure RangeSettersStayConsistent;
    procedure PaintsAllViews;
    procedure ManyAppointmentsStayFast;
    procedure PrintsPagesWithSameDrawing;
    procedure PrintPreviewAndSetup;
  end;

implementation

uses
  Winapi.oleacc, PPG.Exceptions;

type
  TWinControlAccess = class(TWinControl);
  TPPGCustomControlAccess = class(TPPGCustomControl);

const
  Mon = 46174; // 01.06.2026, Montag

function DT(D: TDateTime; H: Word; N: Word = 0): TDateTime;
begin
  Result := Trunc(D) + EncodeTime(H, N, 0, 0);
end;

function Center(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

function SameTime(A, B: TDateTime): Boolean;
begin
  Result := Abs(A - B) < 1 / SecsPerDay;
end;

{ TPlannerTests }

procedure TPlannerTests.SetUp;
begin
  inherited SetUp;
  FLog := TStringList.Create;
  FVeto := False;
  FFreeInDeleting := False;
  FForm.SetBounds(0, 0, 900, 700);
end;

procedure TPlannerTests.TearDown;
begin
  FreeAndNil(FLog);
  inherited TearDown;
end;

function TPlannerTests.NewPlanner: TPPGPlanner;
begin
  CheckEquals(EncodeDate(2026, 6, 1), Mon, 'Konstante');
  Result := TPPGPlanner.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 860, 640);
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.FirstDayOfWeek := fdMonday;
  Result.TimeZone := 'Europe/Berlin';
  Result.Font.Name := 'Segoe UI';
  Result.Font.Size := 9;
  Result.Date := Mon + 2;
  Result.NowOverride := DT(Mon + 2, 10, 15);
  Result.OnAppointmentChanging := Changing;
  Result.OnAppointmentChanged := Changed;
  Result.OnAppointmentCreated := Created;
  Result.OnDeleting := Deleting;
  Result.OnCreateAppointment := Creating;
  Result.OnRangeChange := RangeChange;
  Result.HandleNeeded;
  FLog.Clear;
end;

procedure TPlannerTests.Click(P: TPPGPlanner; const Pt: TPoint; Keys: Integer);
begin
  P.Perform(WM_LBUTTONDOWN, MK_LBUTTON or Keys, MakeLParam(Pt.X, Pt.Y));
  P.Perform(WM_LBUTTONUP, Keys, MakeLParam(Pt.X, Pt.Y));
end;

procedure TPlannerTests.Drag(P: TPPGPlanner; const A, B: TPoint; Keys: Integer);
begin
  P.Perform(WM_LBUTTONDOWN, MK_LBUTTON or Keys, MakeLParam(A.X, A.Y));
  P.Perform(WM_MOUSEMOVE, MK_LBUTTON or Keys, MakeLParam((A.X + B.X) div 2, (A.Y + B.Y) div 2));
  P.Perform(WM_MOUSEMOVE, MK_LBUTTON or Keys, MakeLParam(B.X, B.Y));
  P.Perform(WM_LBUTTONUP, Keys, MakeLParam(B.X, B.Y));
end;

procedure TPlannerTests.Key(P: TPPGPlanner; AKey: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := AKey;
  TWinControlAccess(P).KeyDown(K, Shift);
end;

procedure TPlannerTests.Changing(Sender: TObject; Appointment: TPPGAppointment;
  Kind: TPPGAppointmentChangeKind; var NewStart, NewFinish: TDateTime;
  var NewResourceId: Integer; var Allow: Boolean);
begin
  FLog.Add(Format('changing:%d:%s', [Ord(Kind), FormatDateTime('dd hh:nn', NewStart)]));
  if FVeto then
    Allow := False;
end;

procedure TPlannerTests.Changed(Sender: TObject; Appointment: TPPGAppointment);
begin
  FLog.Add('changed:' + Appointment.Subject);
end;

procedure TPlannerTests.Created(Sender: TObject; Appointment: TPPGAppointment);
begin
  FLog.Add('created');
end;

procedure TPlannerTests.Deleting(Sender: TObject; Appointment: TPPGAppointment; var Allow: Boolean);
begin
  FLog.Add('deleting:' + Appointment.Subject);
  if FVeto then
    Allow := False;
  if FFreeInDeleting then
    Appointment.Free;
end;

procedure TPlannerTests.Creating(Sender: TObject; AStart, AFinish: TDateTime; AResourceId: Integer;
  AAllDay: Boolean; var Allow: Boolean);
begin
  FLog.Add(Format('creating:%s-%s:%d', [FormatDateTime('dd hh:nn', AStart),
    FormatDateTime('dd hh:nn', AFinish), AResourceId]));
  if FVeto then
    Allow := False;
end;

procedure TPlannerTests.RangeChange(Sender: TObject);
begin
  FLog.Add('range');
end;

procedure TPlannerTests.Shot(P: TPPGPlanner; const Name: string);
var
  B: TBitmap;
  Png: TPngImage;
  Dir: string;
begin
  B := RenderToBitmap(P);
  try
    CheckEquals(0, FErrors.Count, 'Fehler beim Zeichnen: ' + FErrors.Text);
    // Bilder fuer die Sichtpruefung nur auf Wunsch
    Dir := GetEnvironmentVariable('PPG_SHOTS');
    if Dir <> '' then
    begin
      Png := TPngImage.Create;
      try
        Png.Assign(B);
        Png.SaveToFile(IncludeTrailingPathDelimiter(Dir) + 'planner-' + Name + '.png');
      finally
        Png.Free;
      end;
    end;
  finally
    B.Free;
  end;
end;

procedure TPlannerTests.RangesPerView;
var
  P: TPPGPlanner;
begin
  P := NewPlanner;
  CheckEquals(Mon, P.RangeStart, 'Woche ab Montag');
  CheckEquals(Mon + 7, P.RangeEnd);
  P.View := pvWorkWeek;
  CheckEquals(5, P.DayCountVisible);
  CheckEquals(Mon + 5, P.RangeEnd);
  P.WorkDays := [wdMonday, wdWednesday];
  CheckEquals(2, P.DayCountVisible);
  CheckEquals(Mon + 2, P.VisibleDay(1));
  P.View := pvDay;
  P.DayCount := 3;
  CheckEquals(Mon + 2, P.RangeStart);
  CheckEquals(Mon + 5, P.RangeEnd);
  P.View := pvMonth;
  CheckEquals(42, P.DayCountVisible);
  CheckEquals(Mon, P.RangeStart, 'Juni 2026 beginnt am Montag');
  P.FirstDayOfWeek := fdSunday;
  CheckEquals(Mon - 1, P.RangeStart, 'Woche ab Sonntag');
  P.View := pvTimeline;
  CheckEquals(7, P.DayCountVisible);
  CheckEquals(Mon + 2, P.RangeStart);
  P.View := pvAgenda;
  CheckEquals(14, P.DayCountVisible);
  try
    P.SlotMinutes := 7;
    Fail('7 Minuten sind kein Raster');
  except
    on E: EPPGPropertyError do
      CheckEquals(30, P.SlotMinutes);
  end;
end;

procedure TPlannerTests.PagingAndRangeEvent;
var
  P: TPPGPlanner;
begin
  P := NewPlanner;
  P.NextPage;
  CheckEquals(Mon + 7, P.RangeStart);
  CheckEquals('range', Trim(FLog.Text));
  P.PrevPage;
  CheckEquals(Mon, P.RangeStart);
  FLog.Clear;
  P.Date := Mon + 4;
  CheckEquals(0, FLog.Count, 'gleiche Woche: kein Ereignis');
  P.View := pvMonth;
  P.NextPage;
  CheckEquals(EncodeDate(2026, 7, 5), P.Date, 'Juli');
  CheckEquals(EncodeDate(2026, 6, 29), P.RangeStart);
  Key(P, VK_HOME);
  CheckEquals(Mon + 2, P.Date, 'Pos1 = heute');
end;

procedure TPlannerTests.OverlapsShareColumn;
var
  P: TPPGPlanner;
  A, B: TPPGAppointment;
  RA, RB, RS: TRect;
begin
  P := NewPlanner;
  A := P.Appointments.AddAppointment(DT(Mon + 1, 9), DT(Mon + 1, 11), 'A');
  B := P.Appointments.AddAppointment(DT(Mon + 1, 10), DT(Mon + 1, 12), 'B');
  CheckEquals(2, P.ItemCount);
  CheckEquals(2, P.PieceCount);
  RA := P.ItemRect(0);
  RB := P.ItemRect(1);
  CheckSame(A, P.Item(0).Appointment);
  CheckTrue(RA.Right <= RB.Left, 'nebeneinander');
  CheckTrue(Abs((RA.Right - RA.Left) - (RB.Right - RB.Left)) <= 2, 'gleich breit');
  RS := P.SlotRect(DT(Mon + 1, 9));
  CheckEquals(RS.Top + 1, RA.Top, '09:00 oben');
  CheckEquals(P.SlotRect(DT(Mon + 1, 11)).Top - 1, RA.Bottom, '11:00 unten');
  CheckTrue(RA.Left >= RS.Left, 'in der Dienstagsspalte');
  CheckTrue(RB.Right <= RS.Right);
  CheckEquals(P.SlotRect(DT(Mon + 1, 10)).Top + 1, RB.Top);
  CheckSame(B, P.Item(1).Appointment);
end;

procedure TPlannerTests.AllDayAndMultiDayInBand;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  Pc: TPPGPlannerPiece;
  R, R2: TRect;
begin
  P := NewPlanner;
  A := P.Appointments.Add;
  A.AllDay := True;
  A.Subject := 'Urlaub';
  A.Start := Mon + 2;
  A.Finish := Mon + 4;
  P.Appointments.AddAppointment(DT(Mon + 3, 10), DT(Mon + 5, 12), 'Messe');
  CheckEquals(2, P.PieceCount, 'je ein Band-Stueck');
  Pc := P.Piece(0);
  CheckTrue(Pc.Band);
  CheckTrue(Pc.Area = paFixed);
  R := P.PieceRect(0);
  CheckTrue(R.Bottom <= P.HeaderHeight, 'im Kopf');
  CheckTrue(R.Left < P.SlotRect(DT(Mon + 2, 9)).Left + 5, 'ab Mittwoch');
  CheckTrue(R.Right > P.SlotRect(DT(Mon + 3, 9)).Right - 5, 'bis Donnerstag');
  CheckTrue(R.Right < P.SlotRect(DT(Mon + 4, 9)).Left + 5, 'nicht Freitag (Ende exklusiv)');
  R2 := P.PieceRect(1);
  CheckTrue(R2.Top >= R.Bottom - 1, 'Ueberschneidung: zweite Zeile');
  CheckTrue(R2.Right > P.SlotRect(DT(Mon + 5, 9)).Right - 5, 'Messe bis Samstag');
end;

procedure TPlannerTests.MidnightSplitsWithMarks;
var
  P: TPPGPlanner;
  A, B: TPPGPlannerPiece;
begin
  P := NewPlanner;
  P.Appointments.AddAppointment(DT(Mon, 22), DT(Mon + 1, 2), 'Nacht');
  CheckEquals(1, P.ItemCount);
  CheckEquals(2, P.PieceCount, 'auf zwei Tage geteilt');
  A := P.Piece(0);
  B := P.Piece(1);
  CheckFalse(A.Band);
  CheckTrue(A.ContAfter and not A.ContBefore, 'Montag: geht weiter');
  CheckTrue(B.ContBefore and not B.ContAfter, 'Dienstag: Fortsetzung');
  CheckEquals(P.SlotRect(DT(Mon + 1, 0)).Top + 1, P.PieceRect(1).Top);
end;

procedure TPlannerTests.HitTestSlotsEdgesAndRtl;
var
  P: TPPGPlanner;
  H: TPPGPlannerHit;
  R, RMon: TRect;
begin
  P := NewPlanner;
  P.Appointments.AddAppointment(DT(Mon + 1, 9), DT(Mon + 1, 11), 'A');
  P.SelectSlots(DT(Mon + 1, 9), DT(Mon + 1, 10)); // in die Ansicht holen
  H := P.HitTest(Center(P.SlotRect(DT(Mon + 3, 14, 30))).X, Center(P.SlotRect(DT(Mon + 3, 14, 30))).Y);
  CheckTrue(H.Kind = phSlot);
  CheckTrue(SameTime(DT(Mon + 3, 14, 30), H.Time), DateTimeToStr(H.Time));
  R := P.ItemRect(0);
  H := P.HitTest(Center(R).X, Center(R).Y);
  CheckTrue(H.Kind = phAppointment);
  CheckEquals(0, H.Item);
  H := P.HitTest(Center(R).X, R.Top + 1);
  CheckTrue(H.Kind = phResizeStart, 'obere Kante');
  H := P.HitTest(Center(R).X, R.Bottom - 2);
  CheckTrue(H.Kind = phResizeEnd, 'untere Kante');
  H := P.HitTest(Center(P.SlotRect(Mon)).X, 5);
  CheckTrue(H.Kind = phHeader);
  RMon := P.SlotRect(DT(Mon, 9));
  P.BiDiMode := bdRightToLeft;
  P.InvalidateLayout;
  R := P.SlotRect(DT(Mon, 9));
  CheckTrue(R.Left > RMon.Left, 'RTL: Montag rechts');
  H := P.HitTest(Center(R).X, Center(R).Y);
  CheckTrue(SameTime(DT(Mon, 9), H.Time), 'RTL-Treffer');
end;

procedure TPlannerTests.DragMovesWithSnap;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  R: TRect;
  Dx, Dy: Integer;
begin
  P := NewPlanner;
  A := P.Appointments.AddAppointment(DT(Mon + 1, 9), DT(Mon + 1, 10), 'A');
  P.SelectAppointment(A);
  R := P.ItemRect(0);
  // eine Spalte nach rechts, zwei Felder (60 min) nach unten, etwas daneben
  Dx := P.SlotRect(DT(Mon + 2, 9)).Left - P.SlotRect(DT(Mon + 1, 9)).Left;
  Dy := P.SlotRect(DT(Mon + 1, 10)).Top - P.SlotRect(DT(Mon + 1, 9)).Top + 3;
  Drag(P, Center(R), Point(Center(R).X + Dx, Center(R).Y + Dy));
  CheckTrue(SameTime(DT(Mon + 2, 10), A.Start), 'Mittwoch 10:00: ' + DateTimeToStr(A.Start));
  CheckTrue(SameTime(DT(Mon + 2, 11), A.Finish), 'Dauer bleibt');
  CheckEquals('changing:0:03 10:00', FLog[0]);
  CheckEquals('changed:A', FLog[1]);
  CheckSame(A, P.SelectedAppointment);
  CheckTrue(P.DragState = pdNone);
  // Klick ohne Bewegung aendert nichts
  FLog.Clear;
  Click(P, Center(P.ItemRect(0)));
  CheckEquals(0, FLog.Count);
end;

procedure TPlannerTests.DragVetoAndCopy;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  R: TRect;
  Dy: Integer;
begin
  P := NewPlanner;
  A := P.Appointments.AddAppointment(DT(Mon + 1, 9), DT(Mon + 1, 10), 'A');
  A.Location := 'Raum 1';
  R := P.ItemRect(0);
  Dy := P.SlotRect(DT(Mon + 1, 11)).Top - P.SlotRect(DT(Mon + 1, 9)).Top;
  FVeto := True;
  Drag(P, Center(R), Point(Center(R).X, Center(R).Y + Dy));
  CheckTrue(SameTime(DT(Mon + 1, 9), A.Start), 'abgelehnt');
  CheckEquals(1, FLog.Count);
  FVeto := False;
  FLog.Clear;
  // Strg: Kopie
  Drag(P, Center(R), Point(Center(R).X, Center(R).Y + Dy), MK_CONTROL);
  CheckEquals(2, P.Appointments.Count);
  CheckTrue(SameTime(DT(Mon + 1, 9), A.Start), 'Original bleibt');
  CheckTrue(SameTime(DT(Mon + 1, 11), P.Appointments[1].Start), 'Kopie 11:00');
  CheckEquals('Raum 1', P.Appointments[1].Location);
  CheckEquals('changing:2:02 11:00', FLog[0]);
  CheckEquals('created', FLog[1]);
end;

procedure TPlannerTests.ResizeEndByDrag;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  R: TRect;
  Dy: Integer;
begin
  P := NewPlanner;
  A := P.Appointments.AddAppointment(DT(Mon + 1, 9), DT(Mon + 1, 10), 'A');
  R := P.ItemRect(0);
  Dy := P.SlotRect(DT(Mon + 1, 11)).Top - P.SlotRect(DT(Mon + 1, 10)).Top;
  Drag(P, Point(Center(R).X, R.Bottom - 2), Point(Center(R).X, R.Bottom - 2 + Dy));
  CheckTrue(SameTime(DT(Mon + 1, 9), A.Start));
  CheckTrue(SameTime(DT(Mon + 1, 11), A.Finish), 'Ende 11:00: ' + DateTimeToStr(A.Finish));
  CheckEquals('changing:1:02 09:00', FLog[0]);
  // Nicht kuerzer als ein Feld
  R := P.ItemRect(0);
  Drag(P, Point(Center(R).X, R.Bottom - 2), Point(Center(R).X, R.Top - 40));
  CheckTrue(SameTime(DT(Mon + 1, 9, 30), A.Finish), 'mindestens 30 min: ' + DateTimeToStr(A.Finish));
end;

procedure TPlannerTests.DragDetachesOccurrence;
var
  P: TPPGPlanner;
  A, X: TPPGAppointment;
  R: TRect;
  Dy, I: Integer;
begin
  P := NewPlanner;
  A := P.Appointments.AddAppointment(DT(Mon, 9), DT(Mon, 10), 'Standup');
  A.Recurrence := 'FREQ=DAILY;COUNT=5';
  CheckEquals(5, P.ItemCount);
  R := P.ItemRect(2); // Mittwoch
  Dy := P.SlotRect(DT(Mon, 11)).Top - P.SlotRect(DT(Mon, 9)).Top;
  Drag(P, Center(R), Point(Center(R).X, Center(R).Y + Dy));
  CheckEquals(2, P.Appointments.Count, 'herausgeloest');
  X := P.Appointments[1];
  CheckEquals(A.Id, X.RecurrenceParent);
  CheckTrue(SameTime(DT(Mon + 2, 11), X.Start));
  CheckEquals(5, P.ItemCount, '4 Serie + 1 verschoben');
  for I := 0 to P.ItemCount - 1 do
    if P.Item(I).Appointment = A then
      CheckFalse(SameTime(DT(Mon + 2, 9), P.Item(I).Start), 'Mittwoch 09:00 fehlt');
  CheckSame(X, P.SelectedAppointment);
end;

procedure TPlannerTests.SelectSlotsByDragAndCreate;
var
  P: TPPGPlanner;
  A, B: TPoint;
begin
  P := NewPlanner;
  P.SelectSlots(DT(Mon + 3, 13), DT(Mon + 3, 14));
  A := Center(P.SlotRect(DT(Mon + 3, 13)));
  B := Center(P.SlotRect(DT(Mon + 3, 14, 30)));
  Drag(P, A, B);
  CheckTrue(SameTime(DT(Mon + 3, 13), P.SelStart), DateTimeToStr(P.SelStart));
  CheckTrue(SameTime(DT(Mon + 3, 15), P.SelFinish), DateTimeToStr(P.SelFinish));
  CheckNull(P.SelectedAppointment);
  // Doppelklick in der Auswahl legt den Termin dafuer an
  P.Perform(WM_LBUTTONDBLCLK, MK_LBUTTON, MakeLParam(A.X, A.Y));
  P.Perform(WM_LBUTTONUP, 0, MakeLParam(A.X, A.Y));
  CheckEquals(1, P.Appointments.Count);
  CheckEquals('creating:04 13:00-04 15:00:0', FLog[0]);
  CheckTrue(P.Editing, 'Betreff wird bearbeitet');
  P.Editor.Text := 'Workshop';
  P.EndEditSubject(True);
  CheckEquals('Workshop', P.Appointments[0].Subject);
  CheckTrue(SameTime(DT(Mon + 3, 15), P.Appointments[0].Finish));
end;

procedure TPlannerTests.TypingCreatesAndEditsSubject;
var
  P: TPPGPlanner;
  C: Char;
  K: Word;
begin
  P := NewPlanner;
  FForm.Show;
  P.SetFocus;
  P.SelectSlots(DT(Mon + 4, 8), DT(Mon + 4, 9));
  C := 'R';
  TWinControlAccess(P).KeyPress(C);
  CheckEquals(#0, C);
  CheckEquals(1, P.Appointments.Count);
  CheckTrue(P.Editing);
  CheckEquals('R', P.Editor.Text, 'getipptes Zeichen');
  P.Editor.Text := 'Review';
  K := VK_RETURN;
  P.Editor.OnKeyDown(P.Editor, K, []);
  CheckFalse(P.Editing);
  CheckEquals('Review', P.Appointments[0].Subject);
  CheckTrue(FLog.IndexOf('changed:Review') >= 0, FLog.Text);
  // Veto beim Anlegen
  FVeto := True;
  P.SelectSlots(DT(Mon + 4, 12), DT(Mon + 4, 13));
  C := 'X';
  TWinControlAccess(P).KeyPress(C);
  CheckEquals(1, P.Appointments.Count, 'abgelehnt');
  FForm.Hide;
end;

procedure TPlannerTests.EscapeDropsNewAppointment;
var
  P: TPPGPlanner;
  K: Word;
begin
  P := NewPlanner;
  FForm.Show;
  P.SelectSlots(DT(Mon + 4, 8), DT(Mon + 4, 9));
  Key(P, VK_RETURN);
  CheckEquals(1, P.Appointments.Count, 'Enter legt an');
  CheckTrue(P.Editing);
  K := VK_ESCAPE;
  P.Editor.OnKeyDown(P.Editor, K, []);
  CheckEquals(0, P.Appointments.Count, 'Esc: neuer leerer Termin wieder weg');
  FForm.Hide;
end;

procedure TPlannerTests.KeyboardMovesAndDeletes;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
begin
  P := NewPlanner;
  A := P.Appointments.AddAppointment(DT(Mon + 1, 9), DT(Mon + 1, 10), 'A');
  P.SelectAppointment(A);
  Key(P, VK_DOWN, [ssCtrl]);
  CheckTrue(SameTime(DT(Mon + 1, 9, 30), A.Start), 'Strg+Unten: 30 min');
  Key(P, VK_RIGHT, [ssCtrl]);
  CheckTrue(SameTime(DT(Mon + 2, 9, 30), A.Start), 'Strg+Rechts: ein Tag');
  Key(P, VK_DOWN, [ssCtrl, ssShift]);
  CheckTrue(SameTime(DT(Mon + 2, 11), A.Finish), 'Strg+Umschalt: Dauer');
  CheckTrue(SameTime(DT(Mon + 2, 9, 30), A.Start));
  FLog.Clear;
  FVeto := True;
  Key(P, VK_DELETE);
  CheckEquals(1, P.Appointments.Count, 'OnDeleting lehnt ab');
  CheckEquals('deleting:A', FLog[0]);
  FVeto := False;
  Key(P, VK_DELETE);
  CheckEquals(0, P.Appointments.Count);
  CheckNull(P.SelectedAppointment);
  // Pfeile wandern durch die Felder
  P.SelectSlots(DT(Mon + 1, 9), DT(Mon + 1, 9, 30));
  Key(P, VK_DOWN);
  CheckTrue(SameTime(DT(Mon + 1, 9, 30), P.SelStart));
  Key(P, VK_DOWN, [ssShift]);
  CheckTrue(SameTime(DT(Mon + 1, 10, 30), P.SelFinish), 'Umschalt erweitert');
  CheckTrue(SameTime(DT(Mon + 1, 9, 30), P.SelStart));
  Key(P, VK_LEFT);
  CheckTrue(SameTime(DT(Mon, 10), P.SelStart), DateTimeToStr(P.SelStart));
  Key(P, VK_LEFT);
  CheckEquals(Mon - 7, P.RangeStart, 'ueber den Rand: blaettern');
end;

procedure TPlannerTests.ReleasesRemovedAppointments;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
begin
  // Audit 08.10.2026: DeleteSelected las den Termin nach der Freigabe,
  // Editor und Auswahl zeigten nach Clear/Reload auf freigegebene Termine.
  P := NewPlanner;
  FForm.Show;
  P.View := pvDay;
  P.Resources.AddResource(1, 'Anna');
  P.Resources.AddResource(2, 'Ben');
  A := P.Appointments.AddAppointment(DT(Mon + 2, 9), DT(Mon + 2, 10), 'A');
  A.ResourceId := 2;
  P.SelectAppointment(A);
  Key(P, VK_DELETE);
  CheckEquals(0, P.Appointments.Count);
  CheckEquals(2, P.SelResourceId, 'Ressource des geloeschten Termins');
  // Inline-Editor offen, dann Clear (wie DB-Reload)
  A := P.Appointments.AddAppointment(DT(Mon + 2, 11), DT(Mon + 2, 12), 'B');
  A.ResourceId := 1;
  P.SelectAppointment(A);
  P.BeginEditSubject;
  CheckTrue(P.Editing, 'Editor offen');
  P.Appointments.Clear;
  CheckFalse(P.Editing, 'Editor nach Clear zu');
  CheckNull(P.SelectedAppointment, 'Auswahl nach Clear leer');
  P.EndEditSubject(True);
  CheckEquals(0, P.Appointments.Count);
  // OnDeleting gibt den Termin selbst frei
  A := P.Appointments.AddAppointment(DT(Mon + 2, 13), DT(Mon + 2, 14), 'C');
  A.ResourceId := 1;
  P.SelectAppointment(A);
  FFreeInDeleting := True;
  CheckFalse(P.DeleteSelected, 'Termin schon weg');
  FFreeInDeleting := False;
  CheckEquals(0, P.Appointments.Count);
  CheckNull(P.SelectedAppointment);
  FForm.Hide;
end;

procedure TPlannerTests.RangeSettersStayConsistent;
var
  P: TPPGPlanner;
  Prn: TPPGPlannerPrinter;
begin
  // Audit 08.10.2026: WorkStart > WorkEnd und PrintFrom > PrintTo wurden
  // angenommen; DayCount/TimelineDays/AgendaDays loesten auch bei gleichem
  // Wert RangeChanged aus (der DB-Planer las dabei alles neu).
  P := NewPlanner;
  P.WorkStart := 600;
  P.WorkEnd := 900;
  P.WorkStart := 1000;
  CheckEquals(1000, P.WorkEnd, 'WorkEnd folgt WorkStart');
  P.WorkEnd := 300;
  CheckEquals(300, P.WorkStart, 'WorkStart folgt WorkEnd');
  P.View := pvDay;
  P.DayCount := 3;
  FLog.Clear;
  P.DayCount := 3;
  P.TimelineDays := P.TimelineDays;
  P.AgendaDays := P.AgendaDays;
  CheckEquals(0, FLog.Count, 'gleicher Wert: kein RangeChanged');
  P.DayCount := 4;
  CheckTrue(FLog.IndexOf('range') >= 0, 'neuer Wert: RangeChanged');
  Prn := TPPGPlannerPrinter.Create(FForm);
  Prn.PrintFrom := Mon + 7;
  Prn.PrintTo := Mon;
  CheckEquals(Mon, Prn.PrintFrom, 0, 'PrintFrom folgt PrintTo');
  Prn.PrintFrom := Mon + 3;
  CheckEquals(Mon + 3, Prn.PrintTo, 0, 'PrintTo folgt PrintFrom');
  Prn.PrintFrom := 0;
  CheckEquals(Mon + 3, Prn.PrintTo, 0, '0 = nicht gesetzt, keine Kopplung');
end;

procedure TPlannerTests.TabWalksAppointments;
var
  P: TPPGPlanner;
begin
  P := NewPlanner;
  P.Appointments.AddAppointment(DT(Mon + 1, 9), DT(Mon + 1, 10), 'A');
  P.Appointments.AddAppointment(DT(Mon + 2, 9), DT(Mon + 2, 10), 'B');
  Key(P, VK_TAB);
  CheckEquals('A', P.SelectedAppointment.Subject);
  Key(P, VK_TAB);
  CheckEquals('B', P.SelectedAppointment.Subject);
  CheckEquals(0, P.Perform(WM_GETDLGCODE, VK_TAB, 0) and DLGC_WANTTAB, 'am Ende gibt Tab ab');
  Key(P, VK_TAB, [ssShift]);
  CheckEquals('A', P.SelectedAppointment.Subject);
end;

procedure TPlannerTests.ResourcesAsColumns;
var
  P: TPPGPlanner;
  R1, R2: TRect;
  H: TPPGPlannerHit;
begin
  P := NewPlanner;
  P.View := pvDay;
  P.Resources.AddResource(1, 'Anna');
  P.Resources.AddResource(2, 'Ben');
  P.Appointments.AddAppointment(DT(Mon + 2, 9), DT(Mon + 2, 10), 'A').ResourceId := 1;
  P.Appointments.AddAppointment(DT(Mon + 2, 9), DT(Mon + 2, 10), 'B').ResourceId := 2;
  CheckEquals(2, P.PieceCount);
  R1 := P.SlotRect(DT(Mon + 2, 9), 1);
  R2 := P.SlotRect(DT(Mon + 2, 9), 2);
  CheckTrue(R2.Left >= R1.Right - 1, 'Ben rechts von Anna');
  CheckTrue(P.ItemRect(0).Right <= R1.Right, 'A bei Anna, volle Breite');
  H := P.HitTest(Center(R2).X, Center(R2).Y);
  CheckEquals(2, H.ResourceId);
  // Ziehen zu Anna
  Drag(P, Center(P.ItemRect(1)), Point(Center(P.ItemRect(1)).X - (R2.Left - R1.Left), Center(P.ItemRect(1)).Y));
  CheckEquals(1, P.Appointments[1].ResourceId, 'Ressource gewechselt');
  P.GroupByResource := False;
  CheckTrue(P.SlotRect(DT(Mon + 2, 9)).Right > R2.Right - 5, 'ohne Gruppen: eine Spalte');
end;

procedure TPlannerTests.TimelineRowsAndResourceDrag;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  R, S1, S2: TRect;
  H: TPPGPlannerHit;
begin
  P := NewPlanner;
  P.View := pvTimeline;
  P.Resources.AddResource(1, 'Raum 1');
  P.Resources.AddResource(2, 'Raum 2');
  A := P.Appointments.AddAppointment(DT(Mon + 2, 9), DT(Mon + 2, 11), 'A');
  A.ResourceId := 1;
  P.ScrollTo(0, 0);
  S1 := P.SlotRect(DT(Mon + 2, 9), 1);
  S2 := P.SlotRect(DT(Mon + 2, 9), 2);
  CheckTrue(S2.Top >= S1.Bottom - 1, 'Zeilen untereinander');
  R := P.ItemRect(0);
  CheckEquals(S1.Left + 1, R.Left, 'Beginn 09:00');
  CheckEquals(P.SlotRect(DT(Mon + 2, 11), 1).Left - 1, R.Right, 'Ende 11:00');
  H := P.HitTest(Center(S2).X, Center(S2).Y);
  CheckTrue(H.Kind = phSlot);
  CheckEquals(2, H.ResourceId);
  CheckTrue(SameTime(DT(Mon + 2, 9), H.Time));
  Drag(P, Center(R), Point(Center(R).X + (S2.Right - S2.Left), Center(R).Y + (S2.Top - S1.Top)));
  CheckEquals(2, A.ResourceId);
  CheckTrue(SameTime(DT(Mon + 2, 9, 30), A.Start), DateTimeToStr(A.Start));
  // Kante rechts: Dauer
  R := P.ItemRect(0);
  Drag(P, Point(R.Right - 2, Center(R).Y), Point(R.Right - 2 + (S2.Right - S2.Left), Center(R).Y));
  CheckTrue(SameTime(DT(Mon + 2, 12), A.Finish), DateTimeToStr(A.Finish));
end;

procedure TPlannerTests.MonthShowsMore;
var
  P: TPPGPlanner;
  I: Integer;
  R: TRect;
  H: TPPGPlannerHit;
begin
  P := NewPlanner;
  P.View := pvMonth;
  for I := 0 to 9 do
    P.Appointments.AddAppointment(DT(Mon + 9, 8 + I), DT(Mon + 9, 9 + I), 'T' + IntToStr(I));
  CheckTrue(P.PieceCount < 10, 'nicht alle passen');
  R := P.SlotRect(Mon + 9);
  H := P.HitTest(Center(R).X, R.Bottom - 6);
  CheckTrue(H.Kind = phMore, '"+N weitere"');
  Click(P, Point(Center(R).X, R.Bottom - 6));
  CheckTrue(P.View = pvDay, 'Klick zeigt den Tag');
  CheckEquals(Mon + 9, P.Date);
  CheckEquals(10, P.PieceCount);
end;

procedure TPlannerTests.AgendaListsDays;
var
  P: TPPGPlanner;
begin
  P := NewPlanner;
  P.View := pvAgenda;
  Shot(P, 'agenda-empty');
  P.Appointments.AddAppointment(DT(Mon + 2, 9), DT(Mon + 2, 10), 'A');
  P.Appointments.AddAppointment(DT(Mon + 4, 9), DT(Mon + 5, 10), 'Zwei Tage');
  CheckEquals(3, P.PieceCount, 'mehrtaegig an beiden Tagen');
  CheckTrue(P.PieceRect(1).Top > P.PieceRect(0).Bottom + 10, 'Tageskopf dazwischen');
  Key(P, VK_DOWN);
  CheckEquals('A', P.SelectedAppointment.Subject);
end;

procedure TPlannerTests.AccessibleChildren;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  Acc: IPPGAccessibleChildren;
begin
  P := NewPlanner;
  A := P.Appointments.AddAppointment(DT(Mon + 1, 9), DT(Mon + 1, 11), 'Planung');
  A.Location := 'Raum 2';
  CheckTrue(Supports(P, IPPGAccessibleChildren, Acc));
  CheckEquals(1, Acc.AccChildCount);
  CheckTrue(Pos('Planung, ', Acc.AccChildName(1)) = 1, Acc.AccChildName(1));
  CheckTrue(Pos(', Raum 2', Acc.AccChildName(1)) > 0);
  CheckTrue(Pos(FormatDateTime(FormatSettings.ShortTimeFormat, DT(Mon, 11)), Acc.AccChildName(1)) > 0);
  CheckEquals(ROLE_SYSTEM_TABLE, TPPGCustomControlAccess(P).AccRole);
  P.SelectAppointment(A);
  CheckEquals(1, Acc.AccSelectedChild);
  CheckEquals(1, Acc.AccChildAt(Center(P.ItemRect(0)).X, Center(P.ItemRect(0)).Y));
  CheckTrue(Acc.AccChildState(1) and STATE_SYSTEM_SELECTED <> 0);
end;

procedure TPlannerTests.CalendarLink;
var
  P: TPPGPlanner;
  C: TPPGCalendar;
  L: IPPGCalendarLink;
begin
  P := NewPlanner;
  C := TPPGCalendar.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(0, 0, 300, 300);
  P.Appointments.AddAppointment(DT(Mon + 10, 9), DT(Mon + 10, 10), 'A');
  P.Calendar := C;
  CheckSame(P, C.Link);
  CheckEquals(Mon + 2, C.Date, 'Kalender zeigt den Tag');
  CheckTrue(Supports(P, IPPGCalendarLink, L));
  CheckTrue(L.CalendarDateMarked(Mon + 10), 'Tag mit Termin');
  CheckFalse(L.CalendarDateMarked(Mon + 11));
  // Auswahl im Kalender stellt den Planer ein
  C.FocusDate := Mon + 20;
  C.Perform(WM_KEYDOWN, VK_RETURN, 0);
  CheckEquals(Mon + 20, P.Date);
  CheckTrue(FLog.IndexOf('range') >= 0);
  C.Free;
  CheckNull(P.Calendar, 'Kalender freigegeben');
  C := TPPGCalendar.Create(FForm);
  C.Parent := FForm;
  P.Calendar := C;
  P.Free;
  CheckNull(C.Link, 'Planer freigegeben');
end;

procedure TPlannerTests.ResourcesGetUniqueIds;
var
  P, Q: TPPGPlanner;
  R1, R2: TPPGPlannerResource;
  M: TMemoryStream;
begin
  // Audit 08.10.2026: Neue Ressourcen (Collection-Editor, Add) hatten alle
  // Id 0; IndexOfId und GroupByResource funktionierten dann nicht.
  P := NewPlanner;
  R1 := P.Resources.Add;
  R2 := P.Resources.Add;
  CheckTrue(R1.Id > 0, 'erste Ressource hat eine Id');
  CheckTrue(R2.Id <> R1.Id, 'eindeutig');
  CheckEquals(1, P.Resources.IndexOfId(R2.Id));
  P.Resources.AddResource(0, 'Null');
  CheckEquals(0, P.Resources[2].Id, 'ausdrueckliche 0 bleibt');
  CheckEquals(R2.Id + 1, P.Resources.Add.Id, 'naechste freie Nummer');
  // Streaming: gespeicherte Ids (auch 0) bleiben, nichts wird neu vergeben
  M := TMemoryStream.Create;
  try
    M.WriteComponent(P);
    M.Position := 0;
    Q := TPPGPlanner(M.ReadComponent(nil));
    try
      CheckEquals(4, Q.Resources.Count);
      CheckEquals(R1.Id, Q.Resources[0].Id);
      CheckEquals(R2.Id, Q.Resources[1].Id);
      CheckEquals(0, Q.Resources[2].Id, '0 gespeichert und geladen');
      CheckEquals(P.Resources[3].Id, Q.Resources[3].Id);
    finally
      Q.Free;
    end;
  finally
    M.Free;
  end;
end;

procedure TPlannerTests.StreamingRoundTrip;
var
  P, Q: TPPGPlanner;
  M: TMemoryStream;
  A: TPPGAppointment;
begin
  P := NewPlanner;
  P.View := pvTimeline;
  P.SlotMinutes := 15;
  P.WorkStart := 420;
  P.WorkDays := [wdMonday, wdTuesday];
  P.Resources.AddResource(5, 'Anna').Color := clRed;
  A := P.Appointments.AddAppointment(DT(Mon + 1, 9), DT(Mon + 1, 10), 'A');
  A.Recurrence := 'FREQ=WEEKLY';
  A.Category := 3;
  A.ResourceId := 5;
  M := TMemoryStream.Create;
  try
    M.WriteComponent(P);
    M.Position := 0;
    Q := TPPGPlanner(M.ReadComponent(nil));
    try
      CheckTrue(Q.View = pvTimeline);
      CheckEquals(15, Q.SlotMinutes);
      CheckEquals(420, Q.WorkStart);
      CheckTrue(Q.WorkDays = [wdMonday, wdTuesday]);
      CheckEquals('Europe/Berlin', Q.TimeZone);
      CheckEquals(1, Q.Resources.Count);
      CheckEquals(clRed, Q.Resources[0].Color);
      CheckEquals(1, Q.Appointments.Count);
      CheckEquals(A.Id, Q.Appointments[0].Id);
      CheckEquals(A.StartTime, Q.Appointments[0].StartTime, 1E-9);
      CheckEquals('FREQ=WEEKLY', Q.Appointments[0].Recurrence);
      CheckEquals(3, Q.Appointments[0].Category);
      CheckEquals(A.Id + 1, Q.Appointments.Add.Id, 'Ids laufen weiter');
    finally
      Q.Free;
    end;
  finally
    M.Free;
  end;
end;

procedure TPlannerTests.PaintsAllViews;
const
  Names: array[TPPGPlannerView] of string = ('day', 'workweek', 'week', 'month', 'timeline', 'agenda');
var
  P: TPPGPlanner;
  V: TPPGPlannerView;
  A: TPPGAppointment;
  I: Integer;
begin
  P := NewPlanner;
  P.Resources.AddResource(1, 'Anna');
  P.Resources.AddResource(2, 'Ben');
  P.GroupByResource := False;
  for I := 0 to 4 do
  begin
    A := P.Appointments.AddAppointment(DT(Mon + I, 9 + I mod 3), DT(Mon + I, 10 + I mod 3, 30),
      'Besprechung ' + IntToStr(I));
    A.Location := 'Raum ' + IntToStr(I + 1);
    A.Category := I;
    A.ResourceId := 1 + I mod 2;
  end;
  P.Appointments.AddAppointment(DT(Mon + 1, 10), DT(Mon + 1, 12), 'Ueberschneidung').ResourceId := 2;
  P.Appointments.AddAppointment(DT(Mon + 3, 22), DT(Mon + 4, 1), 'Nachtschicht').ResourceId := 1;
  A := P.Appointments.Add;
  A.AllDay := True;
  A.Subject := 'Konferenz';
  A.Start := Mon + 1;
  A.Finish := Mon + 4;
  A.ResourceId := 2;
  A := P.Appointments.AddAppointment(DT(Mon, 8), DT(Mon, 8, 30), 'Standup');
  A.Recurrence := 'FREQ=DAILY;BYDAY=MO,TU,WE,TH,FR';
  A.ResourceId := 1;
  P.SelectAppointment(P.Appointments[2]);
  FForm.Show;
  for V := Low(TPPGPlannerView) to High(TPPGPlannerView) do
  begin
    P.View := V;
    P.Update;
    Shot(P, Names[V]);
  end;
  P.View := pvWeek;
  P.GroupByResource := True;
  P.View := pvWorkWeek;
  Shot(P, 'resources');
  TPPGTheme.Mode := tmDark;
  try
    P.View := pvWeek;
    Shot(P, 'week-dark');
  finally
    TPPGTheme.Mode := tmLight;
  end;
  TPPGRendererRegistry.ForceGdiFallback := True;
  P.View := pvMonth;
  Shot(P, 'month-gdi');
  FForm.Hide;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPlannerTests.ManyAppointmentsStayFast;
var
  P: TPPGPlanner;
  I: Integer;
  A: TPPGAppointment;
  T0: Cardinal;
  B: TBitmap;
begin
  P := NewPlanner;
  P.Appointments.BeginUpdate;
  try
    for I := 0 to 49999 do
    begin
      A := P.Appointments.Add;
      A.StartTime := EncodeDate(2026, 1, 1) + (I mod 365) + (8 + I mod 10) / 24;
      A.FinishTime := A.StartTime + 1 / 24;
      A.Subject := 'T' + IntToStr(I);
    end;
  finally
    P.Appointments.EndUpdate;
  end;
  T0 := GetTickCount;
  P.InvalidateLayout;
  P.EnsureLayout;
  CheckTrue(P.ItemCount > 900, IntToStr(P.ItemCount));
  B := RenderToBitmap(P);
  B.Free;
  CheckTrue(GetTickCount - T0 < 1500, 'Woche mit 50 000 Terminen: ' + IntToStr(GetTickCount - T0) + ' ms');
end;

procedure TPlannerTests.PrintsPagesWithSameDrawing;
var
  P: TPPGPlanner;
  Prn: TPPGPlannerPrinter;
  D: TPPGPrintDevice;
  B: TBitmap;
  Png: TPngImage;
  X, Y, Dark: Integer;
  Dir: string;
begin
  P := NewPlanner;
  P.Appointments.AddAppointment(DT(Mon + 1, 9), DT(Mon + 1, 11), 'Planung').Location := 'Raum 2';
  P.Appointments.AddAppointment(DT(Mon + 3, 13), DT(Mon + 3, 14), 'Review');
  Prn := TPPGPlannerPrinter.Create(FForm);
  Prn.Planner := P;
  D := TPPGPrintDevice.A4(96, True);
  CheckEquals(1, Prn.PageCount(D), 'ohne Zeitraum: eine Seite');
  CheckEquals(Mon, Prn.PageStart(0), 'Woche des Planers');
  Prn.PrintFrom := Mon;
  Prn.PrintTo := Mon + 20;
  CheckEquals(3, Prn.PageCount(D), 'drei Wochen');
  CheckEquals(Mon + 14, Prn.PageStart(2));
  Prn.View := pvMonth;
  CheckEquals(1, Prn.PageCount(D), 'Juni');
  CheckTrue(Pos(FormatSettings.LongMonthNames[6], Prn.PageTitle(0)) = 1);
  Prn.View := pvWeek;
  Prn.HeaderText := '[Titel]';
  Prn.Title := 'Team';
  B := TBitmap.Create;
  try
    B.PixelFormat := pf24bit;
    B.SetSize(D.PageWidth, D.PageHeight);
    B.Canvas.Brush.Color := clWhite;
    B.Canvas.FillRect(Rect(0, 0, B.Width, B.Height));
    Prn.RenderPage(0, B.Canvas.Handle, D);
    CheckEquals(0, FErrors.Count, FErrors.Text);
    // Etwas Dunkles (Text, Linien) in der Seite
    Dark := 0;
    for Y := 0 to B.Height div 8 - 1 do
      for X := 0 to B.Width div 8 - 1 do
        if GetRValue(B.Canvas.Pixels[X * 8, Y * 8]) < 128 then
          Inc(Dark);
    CheckTrue(Dark > 20, 'Inhalt gezeichnet: ' + IntToStr(Dark));
    Dir := GetEnvironmentVariable('PPG_SHOTS');
    if Dir <> '' then
    begin
      Png := TPngImage.Create;
      try
        Png.Assign(B);
        Png.SaveToFile(IncludeTrailingPathDelimiter(Dir) + 'planner-print.png');
      finally
        Png.Free;
      end;
    end;
  finally
    B.Free;
  end;
  // Druck-Planer ist weg, der Planer unveraendert
  CheckTrue(P.View = pvWeek);
  CheckEquals(Mon + 2, P.Date);
  P.Free;
  CheckNull(Prn.Planner);
  CheckEquals(0, Prn.PageCount(D));
end;

procedure TPlannerTests.PrintPreviewAndSetup;
var
  P: TPPGPlanner;
  Prn: TPPGPlannerPrinter;
  F: TPPGPrintPreviewForm;
  S: TPPGPageSetupForm;
begin
  P := NewPlanner;
  P.Appointments.AddAppointment(DT(Mon + 1, 9), DT(Mon + 1, 11), 'Planung');
  Prn := TPPGPlannerPrinter.Create(FForm);
  Prn.Planner := P;
  Prn.PrintFrom := Mon;
  Prn.PrintTo := Mon + 13;
  F := TPPGPrintPreviewForm.CreateFor(Prn);
  try
    F.Show;
    Application.ProcessMessages;
    CheckEquals(2, F.PageList.Items.Count);
    F.GoToPage(1);
    F.View.Repaint;
    F.Hide;
  finally
    F.Free;
  end;
  S := TPPGPageSetupForm.CreateFor(Prn);
  try
    S.Apply;
    CheckTrue(Prn.WorkHoursOnly, 'Option unveraendert');
  finally
    S.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterClass(TPPGPlanner);
  RegisterTest('Phase14a', TPlannerTests.Suite);

end.
