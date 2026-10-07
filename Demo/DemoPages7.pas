unit DemoPages7;

{ Demo-Seite "Planer" (Phase 14a): Team-Woche mit Ressourcen, verbundener
  Kalender, Ansichten, Ziehen/Anlegen mit Ereignissen, Druckvorschau und
  iCalendar-Export. Die Termine liegen rund um die aktuelle Woche. }

interface

uses
  System.SysUtils, System.Classes, System.Types, System.DateUtils, Vcl.Controls, Vcl.StdCtrls,
  PPG.Types, PPG.Panel, PPG.Labels, PPG.Button, PPG.ComboBox, PPG.Calendar,
  PPG.Planner.Model, PPG.Planner, PPG.Planner.Print, PPG.Planner.ICal,
  DemoKit;

type
  TDemoPlannerPage = class(TDemoPage)
  private
    FPlanner: TPPGPlanner;
    FCalendar: TPPGCalendar;
    FView: TPPGComboBox;
    FGroup: TPPGComboBox;
    FPrinter: TPPGPlannerPrinter;
    FResult: TPPGLabel;
    FRange: TPPGLabel;
    procedure FillAppointments;
    procedure UpdateRange;
    procedure ViewChange(Sender: TObject);
    procedure GroupChange(Sender: TObject);
    procedure PrevClick(Sender: TObject);
    procedure TodayClick(Sender: TObject);
    procedure NextClick(Sender: TObject);
    procedure PrintClick(Sender: TObject);
    procedure ICalClick(Sender: TObject);
    procedure RangeChange(Sender: TObject);
    procedure Changing(Sender: TObject; Appointment: TPPGAppointment;
      Kind: TPPGAppointmentChangeKind; var NewStart, NewFinish: TDateTime;
      var NewResourceId: Integer; var Allow: Boolean);
    procedure Changed(Sender: TObject; Appointment: TPPGAppointment);
    procedure Created(Sender: TObject; Appointment: TPPGAppointment);
    procedure Deleting(Sender: TObject; Appointment: TPPGAppointment; var Allow: Boolean);
    procedure Opened(Sender: TObject; Appointment: TPPGAppointment);
  protected
    procedure Build; override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

uses
  PPG.Controls.Base;

const
  FullW = 2 * 484 + CardGap;
  CalW = 280;
  PlanH = 640;

function Fmt(T: TDateTime): string;
begin
  Result := FormatDateTime('ddd dd.mm. hh:nn', T);
end;

procedure TDemoPlannerPage.Build;
var
  Card: TPPGPanel;
  X, Y: Integer;
begin
  NewPageHeader(Own, Sheet, 'Planer', L('TPPGPlanner: Tag, Arbeitswoche, Woche, Monat, Zeitleiste und ') +
    L('Agenda. Termine ziehen (Strg kopiert), an der Kante die Dauer {ae}ndern, auf freier Fl{ae}che ') +
    L('ziehen und tippen oder doppelklicken legt einen Termin an. Gespeichert wird in UTC.'));
  Y := PageContentTop;
  Card := NewCard(Own, Sheet, PageX, Y, FullW, PlanH, 'Team-Woche',
    L('Personen als Spalten ("Nach Personen") oder Zeilen (Zeitleiste), Wiederholungen nach ') +
    L('RFC 5545, Kalender links verbunden ') +
    L('(Tage mit Terminen fett). Tastatur: Pfeile, Tab, Strg+Pfeile, Enter, F2, Entf.'));
  // Werkzeugzeile
  X := CardPad;
  NewButton(Own, Card, X, Card.Tag, 40, '<', PrevClick);
  Inc(X, 46);
  NewButton(Own, Card, X, Card.Tag, 80, 'Heute', TodayClick);
  Inc(X, 86);
  NewButton(Own, Card, X, Card.Tag, 40, '>', NextClick);
  Inc(X, 52);
  FView := TPPGComboBox.Create(Own);
  FView.Parent := Card;
  FView.Style := csDropDownList;
  FView.SetBounds(X, Card.Tag, 150, CtlH);
  FView.Items.Add('Tag');
  FView.Items.Add('Arbeitswoche');
  FView.Items.Add('Woche');
  FView.Items.Add('Monat');
  FView.Items.Add('Zeitleiste');
  FView.Items.Add('Agenda');
  FView.ItemIndex := Ord(pvWorkWeek);
  FView.OnChange := ViewChange;
  Inc(X, 158);
  FGroup := TPPGComboBox.Create(Own);
  FGroup.Parent := Card;
  FGroup.Style := csDropDownList;
  FGroup.SetBounds(X, Card.Tag, 170, CtlH);
  FGroup.Items.Add('Nach Personen');
  FGroup.Items.Add('Alle zusammen');
  FGroup.ItemIndex := 1;
  FGroup.OnChange := GroupChange;
  Inc(X, 178);
  NewButton(Own, Card, X, Card.Tag, 120, 'Druckvorschau', PrintClick);
  Inc(X, 126);
  NewButton(Own, Card, X, Card.Tag, 120, 'iCal-Export', ICalClick);
  FRange := NewLabel(Own, Card, CardPad, Card.Tag + CtlH + 8, FullW - 2 * CardPad, '', tkStrong);
  // Kalender und Planer
  FCalendar := TPPGCalendar.Create(Own);
  FCalendar.Parent := Card;
  FCalendar.SetBounds(CardPad, Card.Tag + CtlH + 40, CalW, 320);
  FCalendar.FirstDayOfWeek := fdMonday;
  FCalendar.ShowWeekNumbers := True;
  FPlanner := TPPGPlanner.Create(Own);
  FPlanner.Parent := Card;
  FPlanner.SetBounds(CardPad + CalW + CardGap, Card.Tag + CtlH + 40,
    FullW - 2 * CardPad - CalW - CardGap, PlanH - (Card.Tag + CtlH + 40) - 52);
  FPlanner.Anchors := [akLeft, akTop, akRight, akBottom];
  FPlanner.FirstDayOfWeek := fdMonday;
  FPlanner.View := pvWorkWeek;
  FPlanner.DayStartHour := 7;
  FPlanner.DayEndHour := 20;
  FPlanner.GroupByResource := False;
  FPlanner.Resources.AddResource(1, 'Anna');
  FPlanner.Resources.AddResource(2, 'Ben');
  FPlanner.Resources.AddResource(3, 'Raum Elbe').Color := $0050A0E0;
  FPlanner.OnAppointmentChanging := Changing;
  FPlanner.OnAppointmentChanged := Changed;
  FPlanner.OnAppointmentCreated := Created;
  FPlanner.OnDeleting := Deleting;
  FPlanner.OnAppointmentOpen := Opened;
  FPlanner.OnRangeChange := RangeChange;
  FillAppointments;
  FPlanner.Calendar := FCalendar;
  FResult := NewResult(Own, Card, 'Letzte Aktion');
  FPrinter := TPPGPlannerPrinter.Create(Own);
  FPrinter.Planner := FPlanner;
  FPrinter.Title := 'Team-Woche';
  FPrinter.HeaderText := '[Titel]';
  Host.RegisterSpecial('planner', FPlanner);
  UpdateRange;
end;

procedure TDemoPlannerPage.FillAppointments;
var
  W: TDate;
  A: TPPGAppointment;

  function Add(Day, H, M, DurMin, Res, Cat: Integer; const Subj, Loc: string): TPPGAppointment;
  begin
    Result := FPlanner.Appointments.AddAppointment(W + Day + EncodeTime(H, M, 0, 0),
      W + Day + EncodeTime(H, M, 0, 0) + DurMin / MinsPerDay, Subj);
    Result.ResourceId := Res;
    Result.Category := Cat;
    Result.Location := Loc;
  end;

begin
  // Montag der aktuellen Woche
  W := Trunc(Date) - (DayOfTheWeek(Date) - 1);
  FPlanner.Appointments.BeginUpdate;
  try
    A := Add(0, 9, 0, 15, 1, -1, 'Standup', 'Teams');
    A.Recurrence := 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
    A := Add(0, 9, 0, 15, 2, -1, 'Standup', 'Teams');
    A.Recurrence := 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
    Add(0, 10, 0, 90, 1, 1, 'Kundentermin Meyer', 'Raum Elbe');
    Add(0, 10, 0, 90, 3, 1, 'Kundentermin Meyer', '');
    Add(1, 13, 0, 120, 2, 2, 'Code-Review Planer', '');
    Add(1, 14, 0, 60, 2, 3, 'Telefonat Lieferant', '');
    Add(2, 11, 30, 60, 1, 4, 'Mittagessen mit Team', 'Kantine');
    Add(2, 15, 0, 120, 3, 5, 'Workshop UX', 'Raum Elbe');
    Add(2, 15, 0, 120, 1, 5, 'Workshop UX', 'Raum Elbe');
    Add(3, 8, 0, 240, 2, 6, 'Release vorbereiten', '');
    Add(3, 16, 0, 30, 1, -1, 'Feedback Bewerbung', '');
    Add(4, 12, 0, 60, 2, 2, 'Retro', 'Raum Elbe');
    Add(4, 12, 0, 60, 3, 2, 'Retro', '');
    A := FPlanner.Appointments.Add;
    A.AllDay := True;
    A.Subject := 'Messe Hamburg';
    A.Start := W + 2;
    A.Finish := W + 5;
    A.ResourceId := 1;
    A.Category := 0;
    A := FPlanner.Appointments.Add;
    A.AllDay := True;
    A.Subject := 'Urlaub';
    A.Start := W + 7;
    A.Finish := W + 12;
    A.ResourceId := 2;
    A.Category := 4;
    Add(-3, 18, 0, 240, 3, 3, 'Server-Wartung', 'Rechenzentrum');
  finally
    FPlanner.Appointments.EndUpdate;
  end;
end;

procedure TDemoPlannerPage.UpdateRange;
begin
  FRange.Caption := L(FormatDateTime('dddd, d. mmmm yyyy', FPlanner.RangeStart) + ' {-} ' +
    FormatDateTime('dddd, d. mmmm yyyy', FPlanner.RangeEnd - 1) +
    Format(' (%d Termine sichtbar)', [FPlanner.ItemCount]));
end;

procedure TDemoPlannerPage.ViewChange(Sender: TObject);
begin
  // Zeitleiste (Zeilen = Personen) im Stundenraster, sonst halbe Stunden
  if FView.ItemIndex = Ord(pvTimeline) then
    FPlanner.SlotMinutes := 60
  else
    FPlanner.SlotMinutes := 30;
  if FView.ItemIndex >= 0 then
    FPlanner.View := TPPGPlannerView(FView.ItemIndex);
  Host.Log('Planer', 'Ansicht: ' + FView.Text);
  UpdateRange;
end;

procedure TDemoPlannerPage.GroupChange(Sender: TObject);
begin
  FPlanner.GroupByResource := FGroup.ItemIndex = 0;
end;

procedure TDemoPlannerPage.PrevClick(Sender: TObject);
begin
  FPlanner.PrevPage;
end;

procedure TDemoPlannerPage.TodayClick(Sender: TObject);
begin
  FPlanner.GoToToday;
end;

procedure TDemoPlannerPage.NextClick(Sender: TObject);
begin
  FPlanner.NextPage;
end;

procedure TDemoPlannerPage.PrintClick(Sender: TObject);
begin
  FPrinter.TakeFromPlanner;
  FPrinter.Preview;
end;

procedure TDemoPlannerPage.ICalClick(Sender: TObject);
var
  FileName: string;
begin
  FileName := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) + 'PPGlow-Team.ics';
  PPGSaveICal(FPlanner.Appointments, FileName, 'Team');
  SetResult(FResult, Format('%d Termine nach %s exportiert', [FPlanner.Appointments.Count, FileName]));
  Host.Log('Planer', 'iCal-Export: ' + FileName);
end;

procedure TDemoPlannerPage.RangeChange(Sender: TObject);
begin
  if (FPlanner <> nil) and (FRange <> nil) then
    UpdateRange;
end;

procedure TDemoPlannerPage.Changing(Sender: TObject; Appointment: TPPGAppointment;
  Kind: TPPGAppointmentChangeKind; var NewStart, NewFinish: TDateTime;
  var NewResourceId: Integer; var Allow: Boolean);
begin
  // Beispiel einer Regel: nichts am Wochenende
  if (Kind <> ackSubject) and (DayOfTheWeek(NewStart) >= 6) then
  begin
    Allow := False;
    SetResult(FResult, L('Abgelehnt: am Wochenende wird nicht gearbeitet'));
  end;
end;

procedure TDemoPlannerPage.Changed(Sender: TObject; Appointment: TPPGAppointment);
begin
  SetResult(FResult, Format('%s: %s {-} %s', [Appointment.Subject, Fmt(Appointment.Start),
    FormatDateTime('hh:nn', Appointment.Finish)]));
  Host.Log('Planer', L('Ge{ae}ndert: ') + Appointment.Subject);
  UpdateRange;
end;

procedure TDemoPlannerPage.Created(Sender: TObject; Appointment: TPPGAppointment);
begin
  SetResult(FResult, 'Neuer Termin ' + Fmt(Appointment.Start));
  Host.Log('Planer', 'Angelegt: ' + Fmt(Appointment.Start));
  UpdateRange;
end;

procedure TDemoPlannerPage.Deleting(Sender: TObject; Appointment: TPPGAppointment; var Allow: Boolean);
begin
  SetResult(FResult, L('Gel{oe}scht: ') + Appointment.Subject);
  Host.Log('Planer', L('Gel{oe}scht: ') + Appointment.Subject);
end;

procedure TDemoPlannerPage.Opened(Sender: TObject; Appointment: TPPGAppointment);
begin
  SetResult(FResult, L('Ge{oe}ffnet: ') + Appointment.Subject + ' (' + Appointment.Location + ')');
  FPlanner.BeginEditSubject;
end;

procedure TDemoPlannerPage.SelfTest(Check: TDemoCheck);
var
  N, I: Integer;
  A: TPPGAppointment;
  Occ: TPPGOccurrence;
  S: string;
  Other: TPPGAppointments;
begin
  FPlanner.GoToToday;
  FPlanner.View := pvWorkWeek;
  Check('Planer: Termine in der Woche', FPlanner.ItemCount >= 15);
  Check('Planer: Kalender verbunden', FCalendar.Link = FPlanner);
  Check('Planer: Standup in jeder Spalte', FPlanner.PieceCount >= FPlanner.ItemCount);
  // Verschieben ueber die Ereignisse (Mittwoch -> Donnerstag)
  Occ.Appointment := nil;
  for I := 0 to FPlanner.ItemCount - 1 do
    if FPlanner.Item(I).Appointment.Subject = 'Mittagessen mit Team' then
      Occ := FPlanner.Item(I);
  Check('Planer: Termin gefunden', Occ.Appointment <> nil);
  if Occ.Appointment <> nil then
  begin
    Check('Planer: verschoben', FPlanner.ChangeAppointment(Occ, ackMove, Occ.Start + 1,
      Occ.Finish + 1, Occ.Appointment.ResourceId));
    Check('Planer: Wochenende abgelehnt', not FPlanner.ChangeAppointment(FPlanner.Item(0), ackMove,
      Trunc(FPlanner.RangeStart) + 5 + 10 / 24, Trunc(FPlanner.RangeStart) + 5 + 11 / 24, 1));
  end;
  // Alle Ansichten
  for I := Ord(Low(TPPGPlannerView)) to Ord(High(TPPGPlannerView)) do
  begin
    FView.ItemIndex := I;
    ViewChange(nil);
    FPlanner.Repaint;
  end;
  Check('Planer: Agenda listet Termine', FPlanner.PieceCount > 0);
  FView.ItemIndex := Ord(pvWorkWeek);
  ViewChange(nil);
  // Anlegen und loeschen
  N := FPlanner.Appointments.Count;
  A := FPlanner.CreateAppointment(Trunc(FPlanner.RangeStart) + 17 / 24,
    Trunc(FPlanner.RangeStart) + 18 / 24, 1);
  FPlanner.EndEditSubject(True);
  Check('Planer: angelegt', (A <> nil) and (FPlanner.Appointments.Count = N + 1));
  FPlanner.SelectAppointment(A);
  Check(L('Planer: gel{oe}scht'), FPlanner.DeleteSelected and (FPlanner.Appointments.Count = N));
  // Drucken und iCalendar
  FPrinter.TakeFromPlanner;
  Check('Planer: Druckseite', FPrinter.PageCount(FPrinter.PrinterDevice) = 1);
  S := PPGICalText(FPlanner.Appointments, 'Team');
  Other := TPPGAppointments.Create(nil);
  try
    Check('Planer: iCal-Rundreise', PPGLoadICalText(Other, S) = FPlanner.Appointments.Count);
  finally
    Other.Free;
  end;
  UpdateRange;
end;

end.
