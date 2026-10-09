unit PPG.Planner.Dialog;

{ Termin-Dialog des Planers (Phase 20a).

  PPGEditAppointmentDialog(Planner, A, AllowSeries) zeigt einen modalen
  Dialog aus Controls der Suite und schreibt bei OK in A:
  - Betreff (Pflicht), Ort, Beginn/Ende als Datum und Uhrzeit, ganztaegig,
    Kategorie (Planner.Categories), Ressource (Planner.Resources), Notiz.
  - Wiederholung (nur mit AllowSeries): keine, taeglich, woechentlich mit
    Wochentagen, monatlich, jaehrlich, jeweils "alle N"; Ende nie, nach N
    Terminen oder am Datum. Geschrieben wird eine RRULE (TPPGRecurrence).
    Regeln, die der Dialog nicht abbilden kann (BYSETPOS, Ordnungszahlen,
    mehrere Monatstage ...), erscheinen als "Benutzerdefiniert" und bleiben
    unveraendert, solange man die Wiederholung nicht aendert.
  - Geprueft mit TPPGValidator: Betreff, Ende nicht vor Beginn; OK schliesst
    erst, wenn alles stimmt (CheckOnClose).
  PPGAppointmentDialogHook ersetzt den Dialog (eigene Dialoge, Tests).
  TPPGAppointmentEditor ist das Formular selbst: LoadFrom/SaveTo lassen sich
  ohne ShowModal pruefen. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, Vcl.Controls, Vcl.Forms,
  PPG.Planner.Model, PPG.Planner.Recurrence, PPG.Edit, PPG.Memo, PPG.DatePicker,
  PPG.TimePicker, PPG.CheckBox, PPG.ComboBox, PPG.SpinEdit, PPG.RadioGroup, PPG.GroupBox,
  PPG.Button, PPG.Labels, PPG.Validator;

type
  TPPGAppointmentDialogHook = function(Planner: TComponent; A: TPPGAppointment;
    AllowSeries: Boolean): Boolean;

  TPPGAppointmentEditor = class(TForm)
  private
    FPlanner: TComponent;
    FAllowSeries: Boolean;
    FCustomRule: string;
    FResourceIds: TArray<Integer>;
    FLoading: Boolean;
    procedure Build;
    procedure AllDayClick(Sender: TObject);
    procedure FreqChange(Sender: TObject);
    procedure EndsChange(Sender: TObject);
    procedure CheckTimes(Sender: TObject; Rule: TPPGValidationRule; const Value: Variant;
      var Valid: Boolean; var Message: string);
    function StartValue: TDateTime;
    function FinishValue: TDateTime;
    procedure UpdateSeriesControls;
    function BuildRule: string;
  public
    Subject: TPPGEdit;
    Location: TPPGEdit;
    StartDate: TPPGDatePicker;
    StartTime: TPPGTimePicker;
    FinishDate: TPPGDatePicker;
    FinishTime: TPPGTimePicker;
    AllDay: TPPGCheckBox;
    Category: TPPGComboBox;
    Resource: TPPGComboBox;
    Notes: TPPGMemo;
    SeriesBox: TPPGGroupBox;
    Freq: TPPGComboBox;
    Interval: TPPGSpinEdit;
    IntervalUnit: TPPGLabel;
    WeekDays: TPPGCheckGroup;
    Ends: TPPGComboBox;
    EndCount: TPPGSpinEdit;
    EndDate: TPPGDatePicker;
    OkButton: TPPGButton;
    CancelButton: TPPGButton;
    Validator: TPPGValidator;
    constructor CreateEditor(APlanner: TComponent; AllowSeries: Boolean); reintroduce;
    /// Felder aus A fuellen.
    procedure LoadFrom(A: TPPGAppointment; IsNew: Boolean = False);
    /// Felder nach A schreiben (ohne Pruefung).
    procedure SaveTo(A: TPPGAppointment);
    /// Index in Freq: 0 = keine, 1 = taeglich, 2 = woechentlich, 3 = monatlich,
    /// 4 = jaehrlich, 5 = benutzerdefiniert (nur wenn die Regel es verlangt).
    property CustomRule: string read FCustomRule;
  end;

var
  /// Ersetzt den eingebauten Dialog (nil = eingebaut).
  PPGAppointmentDialogHook: TPPGAppointmentDialogHook = nil;

/// Termin-Dialog; True = OK und in A geschrieben.
function PPGEditAppointmentDialog(Planner: TComponent; A: TPPGAppointment;
  AllowSeries: Boolean): Boolean;

implementation

uses
  System.Math, System.DateUtils, System.Variants, Vcl.StdCtrls, Vcl.Graphics, PPG.Lang,
  PPG.Consts, PPG.DpiUtils, PPG.Planner;

type
  TPlannerAccess = class(TPPGCustomPlanner);

const
  LX = 16;
  FieldW = 470;
  HalfW = 225;
  RowH = 58;
  CtlH = 32;

{ TPPGAppointmentEditor }

constructor TPPGAppointmentEditor.CreateEditor(APlanner: TComponent; AllowSeries: Boolean);
var
  F: TCustomForm;
begin
  inherited CreateNew(nil);
  FPlanner := APlanner;
  FAllowSeries := AllowSeries;
  BorderStyle := bsDialog;
  Position := poOwnerFormCenter;
  if APlanner is TControl then
  begin
    F := GetParentForm(TControl(APlanner));
    if F <> nil then
      Font := F.Font;
  end;
  Build;
end;

function NewLabel(AOwner: TComponent; AParent: TWinControl; X, Y: Integer;
  const ACaption: string; AFor: TWinControl): TPPGLabel;
begin
  Result := TPPGLabel.Create(AOwner);
  Result.Parent := AParent;
  Result.Left := X;
  Result.Top := Y;
  Result.Caption := ACaption;
  Result.FocusControl := AFor;
end;

procedure TPPGAppointmentEditor.Build;
var
  Y, I: Integer;
  P: TPlannerAccess;
  R: TPPGValidationRule;
begin
  FLoading := True;
  try
    ClientWidth := LX * 2 + FieldW;
    Y := 12;
    Subject := TPPGEdit.Create(Self);
    Subject.Parent := Self;
    Subject.SetBounds(LX, Y + 22, FieldW, CtlH);
    NewLabel(Self, Self, LX, Y, PPGStr(@SPPGApptSubject), Subject);
    Inc(Y, RowH);
    Location := TPPGEdit.Create(Self);
    Location.Parent := Self;
    Location.SetBounds(LX, Y + 22, FieldW, CtlH);
    NewLabel(Self, Self, LX, Y, PPGStr(@SPPGApptLocation), Location);
    Inc(Y, RowH);

    StartDate := TPPGDatePicker.Create(Self);
    StartDate.Parent := Self;
    StartDate.SetBounds(LX, Y + 22, 130, CtlH);
    NewLabel(Self, Self, LX, Y, PPGStr(@SPPGApptStart), StartDate);
    StartTime := TPPGTimePicker.Create(Self);
    StartTime.Parent := Self;
    StartTime.SetBounds(LX + 136, Y + 22, 88, CtlH);
    FinishDate := TPPGDatePicker.Create(Self);
    FinishDate.Parent := Self;
    FinishDate.SetBounds(LX + HalfW + 20, Y + 22, 130, CtlH);
    NewLabel(Self, Self, LX + HalfW + 20, Y, PPGStr(@SPPGApptEnd), FinishDate);
    FinishTime := TPPGTimePicker.Create(Self);
    FinishTime.Parent := Self;
    FinishTime.SetBounds(LX + HalfW + 156, Y + 22, 88, CtlH);
    Inc(Y, RowH);
    AllDay := TPPGCheckBox.Create(Self);
    AllDay.Parent := Self;
    AllDay.SetBounds(LX, Y, 200, 26);
    AllDay.Caption := PPGStr(@SPPGApptAllDay);
    AllDay.OnClick := AllDayClick;
    Inc(Y, 36);

    Category := TPPGComboBox.Create(Self);
    Category.Parent := Self;
    Category.Style := csDropDownList;
    Category.SetBounds(LX, Y + 22, HalfW, CtlH);
    NewLabel(Self, Self, LX, Y, PPGStr(@SPPGApptCategory), Category);
    Category.Items.Add(PPGStr(@SPPGApptNoCategory));
    Resource := TPPGComboBox.Create(Self);
    Resource.Parent := Self;
    Resource.Style := csDropDownList;
    Resource.SetBounds(LX + HalfW + 20, Y + 22, HalfW, CtlH);
    NewLabel(Self, Self, LX + HalfW + 20, Y, PPGStr(@SPPGApptResource), Resource);
    if FPlanner is TPPGCustomPlanner then
    begin
      P := TPlannerAccess(FPlanner);
      for I := 0 to P.Categories.Count - 1 do
        Category.Items.Add(P.Categories[I].Caption);
      SetLength(FResourceIds, P.Resources.Count);
      for I := 0 to P.Resources.Count - 1 do
      begin
        Resource.Items.Add(P.Resources[I].Caption);
        FResourceIds[I] := P.Resources[I].Id;
      end;
    end;
    Resource.Enabled := Resource.Items.Count > 0;
    Inc(Y, RowH);
    Notes := TPPGMemo.Create(Self);
    Notes.Parent := Self;
    Notes.SetBounds(LX, Y + 22, FieldW, 60);
    NewLabel(Self, Self, LX, Y, PPGStr(@SPPGApptNotes), Notes);
    Inc(Y, 22 + 60 + 14);

    SeriesBox := TPPGGroupBox.Create(Self);
    SeriesBox.Parent := Self;
    SeriesBox.SetBounds(LX, Y, FieldW, 168);
    SeriesBox.Caption := PPGStr(@SPPGApptRepeat);
    SeriesBox.Visible := FAllowSeries;
    Freq := TPPGComboBox.Create(Self);
    Freq.Parent := SeriesBox;
    Freq.Style := csDropDownList;
    Freq.SetBounds(16, 30, 190, CtlH);
    Freq.Items.Add(PPGStr(@SPPGApptFreqNone));
    Freq.Items.Add(PPGStr(@SPPGApptFreqDaily));
    Freq.Items.Add(PPGStr(@SPPGApptFreqWeekly));
    Freq.Items.Add(PPGStr(@SPPGApptFreqMonthly));
    Freq.Items.Add(PPGStr(@SPPGApptFreqYearly));
    Freq.ItemIndex := 0;
    Freq.OnChange := FreqChange;
    NewLabel(Self, SeriesBox, 222, 36, PPGStr(@SPPGApptEvery), nil);
    Interval := TPPGSpinEdit.Create(Self);
    Interval.Parent := SeriesBox;
    Interval.SetBounds(270, 30, 70, CtlH);
    Interval.Min := 1;
    Interval.Max := 99;
    Interval.Value := 1;
    IntervalUnit := NewLabel(Self, SeriesBox, 348, 36, '', nil);
    WeekDays := TPPGCheckGroup.Create(Self);
    WeekDays.Parent := SeriesBox;
    WeekDays.SetBounds(12, 70, FieldW - 24, 40);
    WeekDays.ShowFrame := False;
    WeekDays.ChoiceStyle := csSegmented;
    WeekDays.Columns := 7;
    // Montag zuerst (ISO), Namen aus dem Gebietsschema
    for I := 0 to 6 do
      WeekDays.Items.Add(FormatSettings.ShortDayNames[(I + 1) mod 7 + 1]);
    Ends := TPPGComboBox.Create(Self);
    Ends.Parent := SeriesBox;
    Ends.Style := csDropDownList;
    Ends.SetBounds(16, 120, 150, CtlH);
    Ends.Items.Add(PPGStr(@SPPGApptEndsNever));
    Ends.Items.Add(PPGStr(@SPPGApptEndsAfter));
    Ends.Items.Add(PPGStr(@SPPGApptEndsOn));
    Ends.ItemIndex := 0;
    Ends.OnChange := EndsChange;
    EndCount := TPPGSpinEdit.Create(Self);
    EndCount.Parent := SeriesBox;
    EndCount.SetBounds(176, 120, 80, CtlH);
    EndCount.Min := 1;
    EndCount.Max := 999;
    EndCount.Value := 10;
    EndDate := TPPGDatePicker.Create(Self);
    EndDate.Parent := SeriesBox;
    EndDate.SetBounds(176, 120, 140, CtlH);
    if FAllowSeries then
      Inc(Y, 168 + 14);

    OkButton := TPPGButton.Create(Self);
    OkButton.Parent := Self;
    OkButton.Caption := PPGStr(@SPPGDlgOK);
    OkButton.SetBounds(LX + FieldW - 2 * 110 - 10, Y, 110, CtlH);
    OkButton.Default := True;
    OkButton.ModalResult := mrOk;
    CancelButton := TPPGButton.Create(Self);
    CancelButton.Parent := Self;
    CancelButton.Caption := PPGStr(@SPPGDlgCancel);
    CancelButton.SetBounds(LX + FieldW - 110, Y, 110, CtlH);
    CancelButton.Cancel := True;
    CancelButton.ModalResult := mrCancel;
    ClientHeight := Y + CtlH + 16;

    Validator := TPPGValidator.Create(Self);
    Validator.AutoFieldRules := False;
    Validator.Rules.AddRule(Subject, vrRequired);
    R := Validator.Rules.AddRule(FinishDate, vrCustom);
    R.Message := PPGStr(@SPPGApptEndBeforeStart);
    Validator.OnValidate := CheckTimes;
    UpdateSeriesControls;
  finally
    FLoading := False;
  end;
end;

function TPPGAppointmentEditor.StartValue: TDateTime;
begin
  Result := Int(StartDate.Date);
  if not AllDay.Checked then
    Result := Result + Frac(StartTime.Time);
end;

function TPPGAppointmentEditor.FinishValue: TDateTime;
begin
  Result := Int(FinishDate.Date);
  if AllDay.Checked then
    Result := Result + 1 // ganztaegig: Ende exklusiv
  else
    Result := Result + Frac(FinishTime.Time);
end;

procedure TPPGAppointmentEditor.CheckTimes(Sender: TObject; Rule: TPPGValidationRule;
  const Value: Variant; var Valid: Boolean; var Message: string);
begin
  if Rule.Control = FinishDate then
    Valid := FinishValue >= StartValue;
end;

procedure TPPGAppointmentEditor.AllDayClick(Sender: TObject);
begin
  StartTime.Enabled := not AllDay.Checked;
  FinishTime.Enabled := not AllDay.Checked;
end;

procedure TPPGAppointmentEditor.FreqChange(Sender: TObject);
begin
  // Wer die Wiederholung aendert, gibt die nicht abbildbare Regel auf
  if not FLoading and (Freq.ItemIndex <> 5) then
    FCustomRule := '';
  UpdateSeriesControls;
end;

procedure TPPGAppointmentEditor.EndsChange(Sender: TObject);
begin
  UpdateSeriesControls;
end;

procedure TPPGAppointmentEditor.UpdateSeriesControls;
var
  On_: Boolean;
begin
  On_ := (Freq.ItemIndex >= 1) and (Freq.ItemIndex <= 4);
  Interval.Enabled := On_;
  WeekDays.Visible := Freq.ItemIndex = 2;
  Ends.Enabled := On_;
  EndCount.Visible := On_ and (Ends.ItemIndex = 1);
  EndDate.Visible := On_ and (Ends.ItemIndex = 2);
  case Freq.ItemIndex of
    1: IntervalUnit.Caption := PPGStr(@SPPGApptUnitDays);
    2: IntervalUnit.Caption := PPGStr(@SPPGApptUnitWeeks);
    3: IntervalUnit.Caption := PPGStr(@SPPGApptUnitMonths);
    4: IntervalUnit.Caption := PPGStr(@SPPGApptUnitYears);
  else
    IntervalUnit.Caption := '';
  end;
end;

/// Kann der Dialog die Regel abbilden? Taeglich mit Wochentagen wird woechentlich.
function Representable(const R: TPPGRecurrence; Start: TDateTime): Boolean;
var
  I: Integer;
begin
  Result := False;
  if (Length(R.BySetPos) > 0) or (Length(R.ByMonth) > 0) then
    Exit;
  for I := 0 to High(R.ByDay) do
    if R.ByDay[I].Ordinal <> 0 then
      Exit;
  if Length(R.ByMonthDay) > 1 then
    Exit;
  if (Length(R.ByMonthDay) = 1) and (R.ByMonthDay[0] <> DayOf(Start)) then
    Exit;
  case R.Freq of
    rfDaily: Result := (Length(R.ByDay) = 0) or (R.Interval <= 1);
    rfWeekly: Result := True;
    rfMonthly, rfYearly: Result := Length(R.ByDay) = 0;
  end;
end;

procedure TPPGAppointmentEditor.LoadFrom(A: TPPGAppointment; IsNew: Boolean);
var
  R: TPPGRecurrence;
  I, J: Integer;
begin
  FLoading := True;
  try
    if IsNew then
      Caption := PPGStr(@SPPGApptNew)
    else
      Caption := PPGStr(@SPPGApptTitle);
    Subject.Text := A.Subject;
    Location.Text := A.Location;
    AllDay.Checked := A.AllDay;
    StartDate.Date := Int(A.Start);
    StartTime.Time := Frac(A.Start);
    if A.AllDay then
    begin
      // Ende exklusiv: letzter Tag ist einer davor
      FinishDate.Date := Max(Int(A.Start), Int(A.Finish) - 1);
      FinishTime.Time := Frac(A.Finish);
    end
    else
    begin
      FinishDate.Date := Int(A.Finish);
      FinishTime.Time := Frac(A.Finish);
    end;
    AllDayClick(nil);
    if (A.Category >= 0) and (A.Category + 1 < Category.Items.Count) then
      Category.ItemIndex := A.Category + 1
    else
      Category.ItemIndex := 0;
    Resource.ItemIndex := -1;
    for I := 0 to High(FResourceIds) do
      if FResourceIds[I] = A.ResourceId then
        Resource.ItemIndex := I;
    Notes.Lines.Text := A.Body;
    FCustomRule := '';
    Freq.ItemIndex := 0;
    Interval.Value := 1;
    Ends.ItemIndex := 0;
    EndDate.Date := Int(A.Start) + 30;
    for I := 0 to WeekDays.Count - 1 do
      WeekDays.Checked[I] := False;
    if A.IsRecurring then
    begin
      R := A.Rule;
      if not Representable(R, A.Start) then
      begin
        FCustomRule := A.Recurrence;
        Freq.Items.Add(PPGStr(@SPPGApptFreqCustom));
        Freq.ItemIndex := 5;
      end
      else
      begin
        if (R.Freq = rfDaily) and (Length(R.ByDay) > 0) then
          Freq.ItemIndex := 2
        else
          Freq.ItemIndex := Ord(R.Freq);
        Interval.Value := Max(1, R.Interval);
        for J := 0 to High(R.ByDay) do
          WeekDays.Checked[R.ByDay[J].Weekday - 1] := True;
        if R.Count > 0 then
        begin
          Ends.ItemIndex := 1;
          EndCount.Value := R.Count;
        end
        else if R.UntilDate > 0 then
        begin
          Ends.ItemIndex := 2;
          EndDate.Date := Int(R.UntilDate);
        end;
      end;
    end;
    UpdateSeriesControls;
  finally
    FLoading := False;
  end;
end;

function TPPGAppointmentEditor.BuildRule: string;
var
  R: TPPGRecurrence;
  I, N: Integer;
begin
  if Freq.ItemIndex = 5 then
    Exit(FCustomRule);
  Result := '';
  if (Freq.ItemIndex < 1) or (Freq.ItemIndex > 4) then
    Exit;
  R.Clear;
  R.Freq := TPPGRecurFreq(Freq.ItemIndex);
  R.Interval := Interval.Value;
  if R.Freq = rfWeekly then
  begin
    N := 0;
    SetLength(R.ByDay, 7);
    for I := 0 to 6 do
      if WeekDays.Checked[I] then
      begin
        R.ByDay[N].Ordinal := 0;
        R.ByDay[N].Weekday := I + 1;
        Inc(N);
      end;
    // Kein Tag gewaehlt: der Wochentag des Beginns (wie RRULE ohne BYDAY)
    SetLength(R.ByDay, N);
  end;
  case Ends.ItemIndex of
    1: R.Count := EndCount.Value;
    2: R.UntilDate := Int(EndDate.Date) + EncodeTime(23, 59, 59, 0);
  end;
  Result := R.ToString;
end;

procedure TPPGAppointmentEditor.SaveTo(A: TPPGAppointment);
begin
  if A.Collection <> nil then
    A.Collection.BeginUpdate;
  try
    A.Subject := Subject.Text;
    A.Location := Location.Text;
    A.AllDay := AllDay.Checked;
    A.Start := StartValue;
    A.Finish := FinishValue;
    if Category.ItemIndex > 0 then
      A.Category := Category.ItemIndex - 1
    else
      A.Category := -1;
    if (Resource.ItemIndex >= 0) and (Resource.ItemIndex <= High(FResourceIds)) then
      A.ResourceId := FResourceIds[Resource.ItemIndex];
    A.Body := Notes.Lines.Text;
    // Notiz ohne abschliessenden Zeilenumbruch speichern
    if (Length(A.Body) >= 2) and (Copy(A.Body, Length(A.Body) - 1, 2) = #13#10) then
      A.Body := Copy(A.Body, 1, Length(A.Body) - 2);
    if FAllowSeries then
      A.Recurrence := BuildRule;
  finally
    if A.Collection <> nil then
      A.Collection.EndUpdate;
  end;
end;

function PPGEditAppointmentDialog(Planner: TComponent; A: TPPGAppointment;
  AllowSeries: Boolean): Boolean;
var
  E: TPPGAppointmentEditor;
  PPI: Integer;
begin
  if Assigned(PPGAppointmentDialogHook) then
    Exit(PPGAppointmentDialogHook(Planner, A, AllowSeries));
  E := TPPGAppointmentEditor.CreateEditor(Planner, AllowSeries);
  try
    E.LoadFrom(A);
    if Planner is TControl then
    begin
      PPI := PPGControlPPI(TControl(Planner));
      if PPI <> 96 then
        E.ScaleBy(PPI, 96);
    end;
    Result := E.ShowModal = mrOk;
    if Result then
      E.SaveTo(A);
  finally
    E.Free;
  end;
end;

end.
