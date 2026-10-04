unit PPG.Tests.Phase7b;

{$WARN SYMBOL_PLATFORM OFF}

{ Tests fuer Phase 7b: TPPGCalendar, TPPGDatePicker, TPPGTimePicker.
  Datum/Zeit mit fester Locale (FormatSettings im SetUp gesetzt). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.DateUtils, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.ComCtrls,
  PPG.Types, PPG.Consts, PPG.Render.Intf, PPG.Render.Registry, PPG.Controls.Base,
  PPG.Controls.Field, PPG.Calendar, PPG.DatePicker, PPG.TimePicker, PPG.Accessibility,
  PPG.Exceptions,
  PPG.Tests.Controls, PPG.Tests.Phase4b;

type
  TPhase7bTestCase = class(TComboTestCase)
  protected
    FSavedFS: TFormatSettings;
    FChanges7: Integer;
    FViews: Integer;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure Count7(Sender: TObject);
    procedure CountView(Sender: TObject);
    procedure DisableWeekend(Sender: TObject; ADate: TDate; var Disabled: Boolean);
    function NewCalendar: TPPGCalendar;
    procedure ClickDate(C: TPPGCalendar; D: TDate);
    procedure Key7b(C: TWinControl; VK: Word; Shift: TShiftState = []);
  end;

  TCalendarTests = class(TPhase7bTestCase)
  published
    procedure FirstDayOfWeekShiftsGrid;
    procedure IsoWeekNumbersAtYearBoundary;
    procedure LeapYearAndMonthEnds;
    procedure ClickSelectsSingle;
    procedure RangeSelection;
    procedure MultipleSelection;
    procedure DisabledDates;
    procedure KeyboardNavigation;
    procedure ZoomViews;
    procedure CodeSetsWithoutEvents;
    procedure RightToLeftMirrors;
    procedure Accessibility;
  end;

  TDatePickerTests = class(TPhase7bTestCase)
  published
    procedure DefaultsAndTDateTimePickerDfm;
    procedure CommitTypedText;
    procedure InvalidTextShowsError;
    procedure ArrowKeysStepDays;
    procedure PopupPicksDate;
    procedure PopupShowsCalendar;
    procedure CheckboxMeansNoDate;
  end;

  TTimePickerTests = class(TPhase7bTestCase)
  published
    procedure ParsesManyFormats;
    procedure FormatsByClock;
    procedure ItemsFollowIncrement;
    procedure ArrowsStepSegmentWithWrap;
    procedure CommitFiresOnceAndCodeIsQuiet;
    procedure ListSelectsTime;
  end;

  TPhase7bPaintTests = class(TPhase7bTestCase)
  published
    procedure PaintAllPresetsAndModes;
    procedure NoHandleOrMemoryLeaks;
  end;

implementation

uses
  Winapi.oleacc, PPG.Theme, PPG.Popup;

type
  TWinAccess7b = class(TWinControl);
  TCalAccess = class(TPPGCalendar);
  TDateAccess = class(TPPGDatePicker);
  TTimeAccess = class(TPPGTimePicker);
  TCC7b = class(TPPGCustomControl);

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

function AllocatedBytes: NativeUInt;
var
  S: TMemoryManagerState;
  I: Integer;
begin
  GetMemoryManagerState(S);
  Result := S.TotalAllocatedMediumBlockSize + S.TotalAllocatedLargeBlockSize;
  for I := Low(S.SmallBlockTypeStates) to High(S.SmallBlockTypeStates) do
    Inc(Result, S.SmallBlockTypeStates[I].AllocatedBlockCount *
      S.SmallBlockTypeStates[I].UseableBlockSize);
end;

function LoadDfm7b(const Text: string): TComponent;
var
  Src, Bin: TMemoryStream;
  B: TBytes;
begin
  Src := TMemoryStream.Create;
  Bin := TMemoryStream.Create;
  try
    B := TEncoding.UTF8.GetBytes(Text);
    if Length(B) > 0 then
      Src.WriteBuffer(B[0], Length(B));
    Src.Position := 0;
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    Result := Bin.ReadComponent(nil);
  finally
    Bin.Free;
    Src.Free;
  end;
end;

{ TPhase7bTestCase }

procedure TPhase7bTestCase.SetUp;
begin
  inherited SetUp;
  FSavedFS := FormatSettings;
  // Feste deutsche Formate (unabhaengig vom Rechner)
  FormatSettings.DateSeparator := '.';
  FormatSettings.ShortDateFormat := 'dd.mm.yyyy';
  FormatSettings.LongDateFormat := 'dddd, d. mmmm yyyy';
  FormatSettings.TimeSeparator := ':';
  FormatSettings.TimeAMString := 'AM';
  FormatSettings.TimePMString := 'PM';
  FormatSettings.LongDayNames[1] := 'Sonntag';
  FormatSettings.LongDayNames[2] := 'Montag';
  FormatSettings.LongDayNames[3] := 'Dienstag';
  FormatSettings.LongDayNames[4] := 'Mittwoch';
  FormatSettings.LongDayNames[5] := 'Donnerstag';
  FormatSettings.LongDayNames[6] := 'Freitag';
  FormatSettings.LongDayNames[7] := 'Samstag';
  FormatSettings.LongMonthNames[9] := 'September';
  FormatSettings.LongMonthNames[10] := 'Oktober';
  FChanges7 := 0;
  FViews := 0;
end;

procedure TPhase7bTestCase.TearDown;
begin
  FormatSettings := FSavedFS;
  inherited TearDown;
end;

procedure TPhase7bTestCase.Count7(Sender: TObject);
begin
  Inc(FChanges7);
end;

procedure TPhase7bTestCase.CountView(Sender: TObject);
begin
  Inc(FViews);
end;

procedure TPhase7bTestCase.DisableWeekend(Sender: TObject; ADate: TDate; var Disabled: Boolean);
begin
  Disabled := DayOfTheWeek(ADate) >= 6;
end;

function TPhase7bTestCase.NewCalendar: TPPGCalendar;
begin
  Result := TPPGCalendar.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 300, 330);
  Result.Animation.Enabled := False;
  Result.FirstDayOfWeek := fdMonday;
  Result.TodayOverride := EncodeDate(2026, 10, 4);
  Result.ShowMonth(2026, 10);
  Result.OnChange := Count7;
  Result.OnViewChange := CountView;
  Result.HandleNeeded;
end;

procedure TPhase7bTestCase.ClickDate(C: TPPGCalendar; D: TDate);
var
  I: Integer;
  R: TRect;
begin
  I := Trunc(D) - Trunc(C.CellDate(0));
  R := C.CellRect(I);
  C.Perform(WM_MOUSEMOVE, 0, MouseLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
  C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
  C.Perform(WM_LBUTTONUP, 0, MouseLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
end;

procedure TPhase7bTestCase.Key7b(C: TWinControl; VK: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := VK;
  TWinAccess7b(C).KeyDown(K, Shift);
end;

{ TCalendarTests }

procedure TCalendarTests.FirstDayOfWeekShiftsGrid;
var
  C: TPPGCalendar;
begin
  C := NewCalendar;
  // 1.10.2026 ist ein Donnerstag
  CheckEquals(EncodeDate(2026, 9, 28), C.CellDate(0), 0, 'Montag davor');
  CheckEquals(EncodeDate(2026, 10, 1), C.CellDate(3), 0);
  C.FirstDayOfWeek := fdSunday;
  CheckEquals(EncodeDate(2026, 9, 27), C.CellDate(0), 0, 'Sonntag davor');
  C.FirstDayOfWeek := fdThursday;
  CheckEquals(EncodeDate(2026, 10, 1), C.CellDate(0), 0, 'Monat beginnt am ersten Wochentag');
  CheckEquals(7, PPGIsoDayOfWeek(EncodeDate(2026, 10, 4)), 'Sonntag = 7');
  CheckTrue((PPGLocaleFirstDayOfWeek >= 1) and (PPGLocaleFirstDayOfWeek <= 7));
end;

procedure TCalendarTests.IsoWeekNumbersAtYearBoundary;
var
  C: TPPGCalendar;
begin
  C := NewCalendar;
  // Januar 2021: 1.1. ist Freitag und gehoert zu KW 53 von 2020
  C.ShowMonth(2021, 1);
  CheckEquals(EncodeDate(2020, 12, 28), C.CellDate(0), 0);
  CheckEquals(53, C.WeekNumberOfRow(0), 'KW 53');
  CheckEquals(1, C.WeekNumberOfRow(1));
  // Dezember 2024: 30./31.12. gehoeren zu KW 1 von 2025
  C.ShowMonth(2024, 12);
  CheckEquals(EncodeDate(2024, 12, 30), C.CellDate(35), 0);
  CheckEquals(1, C.WeekNumberOfRow(5), 'KW 1 des Folgejahrs');
  C.ShowWeekNumbers := True;
  CheckTrue(C.CellRect(0).Left > 20, 'Platz fuer die Wochennummern');
end;

procedure TCalendarTests.LeapYearAndMonthEnds;
var
  C: TPPGCalendar;
  I: Integer;
  Found: Boolean;
begin
  C := NewCalendar;
  C.ShowMonth(2024, 2);
  Found := False;
  for I := 0 to 41 do
    if Trunc(C.CellDate(I)) = Trunc(EncodeDate(2024, 2, 29)) then
      Found := True;
  CheckTrue(Found, '29.2.2024 im Raster');
  C.FocusDate := EncodeDate(2024, 1, 31);
  Key7b(C, VK_NEXT);
  CheckEquals(EncodeDate(2024, 2, 29), C.FocusDate, 0, 'Monatsende im Schaltjahr');
  Key7b(C, VK_NEXT, [ssCtrl]);
  CheckEquals(EncodeDate(2025, 2, 28), C.FocusDate, 0, 'Folgejahr ohne 29.');
  CheckEquals(2, C.DisplayMonth);
  CheckEquals(2025, C.DisplayYear);
end;

procedure TCalendarTests.ClickSelectsSingle;
var
  C: TPPGCalendar;
begin
  FForm.Show;
  try
    C := NewCalendar;
    ClickDate(C, EncodeDate(2026, 10, 15));
    CheckEquals(EncodeDate(2026, 10, 15), C.Date, 0);
    CheckEquals(1, FChanges7);
    ClickDate(C, EncodeDate(2026, 10, 15));
    CheckEquals(1, FChanges7, 'gleicher Tag: kein Ereignis');
    // Tag im Folgemonat blaettert dorthin
    ClickDate(C, C.CellDate(41));
    CheckEquals(11, C.DisplayMonth);
    CheckEquals(2, FChanges7);
    CheckTrue(C.IsSelected(C.Date));
    CheckEquals(1, C.SelectedCount);
  finally
    FForm.Hide;
  end;
end;

procedure TCalendarTests.RangeSelection;
var
  C: TPPGCalendar;
begin
  FForm.Show;
  try
    C := NewCalendar;
    C.SelectionMode := dsmRange;
    ClickDate(C, EncodeDate(2026, 10, 10));
    CheckEquals(1, C.SelectedCount, 'Anfang');
    ClickDate(C, EncodeDate(2026, 10, 5));
    CheckEquals(EncodeDate(2026, 10, 5), C.RangeStart, 0, 'rueckwaerts gezogen');
    CheckEquals(EncodeDate(2026, 10, 10), C.RangeEnd, 0);
    CheckEquals(6, C.SelectedCount);
    CheckEquals(EncodeDate(2026, 10, 7), C.SelectedDate(2), 0);
    CheckTrue(C.IsSelected(EncodeDate(2026, 10, 8)));
    CheckFalse(C.IsSelected(EncodeDate(2026, 10, 11)));
    ClickDate(C, EncodeDate(2026, 10, 20));
    CheckEquals(1, C.SelectedCount, 'dritter Klick beginnt neu');
    CheckEquals(3, FChanges7);
  finally
    FForm.Hide;
  end;
end;

procedure TCalendarTests.MultipleSelection;
var
  C: TPPGCalendar;
begin
  FForm.Show;
  try
    C := NewCalendar;
    C.SelectionMode := dsmMultiple;
    ClickDate(C, EncodeDate(2026, 10, 20));
    ClickDate(C, EncodeDate(2026, 10, 2));
    ClickDate(C, EncodeDate(2026, 10, 9));
    CheckEquals(3, C.SelectedCount);
    CheckEquals(EncodeDate(2026, 10, 2), C.SelectedDate(0), 0, 'sortiert');
    ClickDate(C, EncodeDate(2026, 10, 9));
    CheckEquals(2, C.SelectedCount, 'Klick schaltet um');
    CheckFalse(C.IsSelected(EncodeDate(2026, 10, 9)));
    C.ClearSelection;
    CheckEquals(0, C.SelectedCount);
  finally
    FForm.Hide;
  end;
end;

procedure TCalendarTests.DisabledDates;
var
  C: TPPGCalendar;
begin
  FForm.Show;
  try
    C := NewCalendar;
    C.MinDate := EncodeDate(2026, 10, 10);
    C.MaxDate := EncodeDate(2026, 10, 25);
    ClickDate(C, EncodeDate(2026, 10, 5));
    CheckEquals(0, FChanges7, 'vor MinDate');
    CheckTrue(C.IsDateDisabled(EncodeDate(2026, 10, 26)));
    C.OnIsDateDisabled := DisableWeekend;
    CheckTrue(C.IsDateDisabled(EncodeDate(2026, 10, 17)), 'Samstag');
    ClickDate(C, EncodeDate(2026, 10, 17));
    CheckEquals(0, FChanges7);
    ClickDate(C, EncodeDate(2026, 10, 15));
    CheckEquals(1, FChanges7);
    // Fokus bleibt in den Grenzen
    C.FocusDate := EncodeDate(2026, 10, 24);
    Key7b(C, VK_DOWN);
    CheckEquals(EncodeDate(2026, 10, 25), C.FocusDate, 0, 'an MaxDate begrenzt');
  finally
    FForm.Hide;
  end;
end;

procedure TCalendarTests.KeyboardNavigation;
var
  C: TPPGCalendar;
begin
  C := NewCalendar;
  C.FocusDate := EncodeDate(2026, 10, 31);
  Key7b(C, VK_RIGHT);
  CheckEquals(EncodeDate(2026, 11, 1), C.FocusDate, 0);
  CheckEquals(11, C.DisplayMonth, 'Ansicht folgt dem Fokus');
  Key7b(C, VK_UP);
  CheckEquals(EncodeDate(2026, 10, 25), C.FocusDate, 0, 'Woche zurueck');
  Key7b(C, VK_PRIOR);
  CheckEquals(EncodeDate(2026, 9, 25), C.FocusDate, 0);
  Key7b(C, VK_PRIOR, [ssCtrl]);
  CheckEquals(EncodeDate(2025, 9, 25), C.FocusDate, 0, 'Jahr zurueck');
  Key7b(C, VK_END);
  CheckEquals(EncodeDate(2025, 9, 30), C.FocusDate, 0);
  Key7b(C, VK_HOME);
  CheckEquals(EncodeDate(2025, 9, 1), C.FocusDate, 0);
  CheckEquals(0, FChanges7, 'Bewegen waehlt nicht');
  Key7b(C, VK_RETURN);
  CheckEquals(EncodeDate(2025, 9, 1), C.Date, 0);
  CheckEquals(1, FChanges7);
end;

procedure TCalendarTests.ZoomViews;
var
  C: TPPGCalendar;
  R: TRect;
begin
  FForm.Show;
  try
    C := NewCalendar;
    R := C.PartRect(cpTitle);
    C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(R.Left + 10, (R.Top + R.Bottom) div 2));
    C.Perform(WM_LBUTTONUP, 0, MouseLParam(R.Left + 10, (R.Top + R.Bottom) div 2));
    CheckTrue(C.View = cvYear, 'Titel zoomt heraus');
    CheckEquals(12, TCalAccess(C).AccChildCount);
    R := C.CellRect(2);
    C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
    C.Perform(WM_LBUTTONUP, 0, MouseLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
    CheckTrue(C.View = cvMonth, 'Monat hinein');
    CheckEquals(3, C.DisplayMonth);
    Key7b(C, VK_UP, [ssCtrl]);
    Key7b(C, VK_UP, [ssCtrl]);
    CheckTrue(C.View = cvDecade);
    CheckEquals(2026, YearOf(C.CellDate(7)), 'Dekade 2020-2029 mit Rand');
    Key7b(C, VK_DOWN, [ssCtrl]);
    CheckTrue(C.View = cvYear);
    CheckEquals(5, FViews, 'Titel, Monat, 2x heraus, 1x hinein');
    CheckEquals(0, FChanges7);
  finally
    FForm.Hide;
  end;
end;

procedure TCalendarTests.CodeSetsWithoutEvents;
var
  C: TPPGCalendar;
begin
  C := NewCalendar;
  C.Date := EncodeDate(2027, 3, 14);
  CheckEquals(3, C.DisplayMonth, 'Anzeige folgt Date');
  CheckEquals(2027, C.DisplayYear);
  C.View := cvYear;
  C.NextPage;
  C.SelectRange(EncodeDate(2027, 1, 5), EncodeDate(2027, 1, 1));
  C.ShowMonth(2030, 1);
  CheckEquals(0, FChanges7);
  CheckEquals(0, FViews);
  try
    C.ShowMonth(2030, 13);
    Fail('Monat 13');
  except
    on E: Exception do
      CheckTrue(E is EPPGError, E.ClassName);
  end;
end;

procedure TCalendarTests.RightToLeftMirrors;
var
  C: TPPGCalendar;
  K: Word;
begin
  C := NewCalendar;
  C.BiDiMode := bdRightToLeft;
  CheckTrue(C.CellRect(0).Left > C.CellRect(6).Left, 'erste Spalte rechts');
  CheckTrue(C.PartRect(cpNext).Left < C.PartRect(cpTitle).Left);
  C.FocusDate := EncodeDate(2026, 10, 14);
  K := VK_LEFT;
  TWinAccess7b(C).KeyDown(K, []);
  CheckEquals(EncodeDate(2026, 10, 15), C.FocusDate, 0, 'Links = vorwaerts bei RTL');
end;

procedure TCalendarTests.Accessibility;
var
  C: TPPGCalendar;
  A: IPPGAccessibleChildren;
begin
  C := NewCalendar;
  CheckTrue(Supports(C, IPPGAccessibleChildren, A));
  CheckEquals(42, A.AccChildCount);
  CheckEquals('Montag, 28. September 2026', A.AccChildName(1));
  CheckEquals(ROLE_SYSTEM_CELL, A.AccChildRole(1));
  C.Date := EncodeDate(2026, 10, 15);
  CheckTrue(A.AccChildState(Trunc(EncodeDate(2026, 10, 15)) - Trunc(C.CellDate(0)) + 1) and
    STATE_SYSTEM_SELECTED <> 0);
  CheckEquals(Trunc(EncodeDate(2026, 10, 15)) - Trunc(C.CellDate(0)) + 1, A.AccSelectedChild);
  C.MinDate := EncodeDate(2026, 10, 2);
  CheckTrue(A.AccChildState(1) and STATE_SYSTEM_UNAVAILABLE <> 0);
  CheckEquals(ROLE_SYSTEM_TABLE, TCalAccess(C).AccRole);
  CheckEquals('Donnerstag, 15. Oktober 2026', TCalAccess(C).AccValue);
end;

{ TDatePickerTests }

function NewPicker(F: TForm; T: TPhase7bTestCase): TPPGDatePicker;
begin
  Result := TPPGDatePicker.Create(F);
  Result.Parent := F;
  Result.SetBounds(10, 10, 160, 24);
  Result.Animation.Enabled := False;
  Result.Date := EncodeDate(2026, 10, 4);
  Result.OnChange := T.Count7;
  Result.HandleNeeded;
end;

procedure TDatePickerTests.DefaultsAndTDateTimePickerDfm;
var
  D: TPPGDatePicker;
begin
  D := TPPGDatePicker.Create(nil);
  try
    CheckEquals(Trunc(System.SysUtils.Date), D.Date, 0, 'heute wie TDateTimePicker');
    CheckTrue(D.Kind = dtkDate);
    CheckTrue(D.Checked);
    CheckFalse(D.ShowCheckbox);
  finally
    D.Free;
  end;
  D := LoadDfm7b(
    'object DateTimePicker1: TPPGDatePicker'#13#10 +
    '  Left = 8'#13#10 +
    '  Top = 8'#13#10 +
    '  Width = 186'#13#10 +
    '  Height = 23'#13#10 +
    '  Date = 46299.000000000000000000'#13#10 +
    '  Time = 0.500000000000000000'#13#10 +
    '  ShowCheckbox = True'#13#10 +
    '  Checked = False'#13#10 +
    '  DateFormat = dfLong'#13#10 +
    '  CalAlignment = dtaRight'#13#10 +
    '  Kind = dtkDate'#13#10 +
    '  DateMode = dmComboBox'#13#10 +
    '  TabOrder = 0'#13#10 +
    'end') as TPPGDatePicker;
  try
    CheckEquals(46299, D.Date, 0);
    CheckEquals(0.5, D.Time, 0.00001, 'Zeitanteil bleibt');
    CheckTrue(D.ShowCheckbox);
    CheckFalse(D.Checked);
    CheckFalse(D.HasDate, 'ohne Haken kein Datum');
    CheckTrue(D.DateFormat = dfLong);
    CheckEquals(FormatDateTime(FormatSettings.LongDateFormat, 46299), D.Text);
  finally
    D.Free;
  end;
end;

procedure TDatePickerTests.CommitTypedText;
var
  D: TPPGDatePicker;
begin
  D := NewPicker(FForm, Self);
  CheckEquals('04.10.2026', D.Text);
  D.Text := '24.12.2026';
  CheckEquals(0, FChanges7, 'Text im Code');
  CheckTrue(TDateAccess(D).CommitText(True));
  CheckEquals(EncodeDate(2026, 12, 24), D.Date, 0);
  CheckEquals(1, FChanges7);
  CheckTrue(TDateAccess(D).CommitText(True));
  CheckEquals(1, FChanges7, 'unveraendert: kein Ereignis');
  D.Text := '1.2.2027';
  TDateAccess(D).CommitText(True);
  CheckEquals(EncodeDate(2027, 2, 1), D.Date, 0, 'kurze Eingabe');
  CheckEquals('01.02.2027', D.Text, 'neu formatiert');
end;

procedure TDatePickerTests.InvalidTextShowsError;
var
  D: TPPGDatePicker;
begin
  D := NewPicker(FForm, Self);
  D.Text := '31.02.2026';
  CheckFalse(TDateAccess(D).CommitText(True));
  CheckTrue(D.ValidationState = pvsError);
  CheckEquals('31.02.2026', D.Text, 'Text bleibt zum Korrigieren');
  CheckEquals(EncodeDate(2026, 10, 4), D.Date, 0);
  D.MaxDate := EncodeDate(2026, 12, 31);
  D.Text := '01.01.2027';
  CheckFalse(TDateAccess(D).CommitText(True), 'nach MaxDate');
  D.Date := EncodeDate(2026, 11, 11);
  CheckTrue(D.ValidationState = pvsNone, 'Datum im Code loescht den Fehler');
  CheckEquals(0, FChanges7);
end;

procedure TDatePickerTests.ArrowKeysStepDays;
var
  D: TPPGDatePicker;
  K: Word;
begin
  D := NewPicker(FForm, Self);
  K := VK_UP;
  TDateAccess(D).FieldKeyDown(K, []);
  CheckEquals(EncodeDate(2026, 10, 5), D.Date, 0);
  K := VK_DOWN;
  TDateAccess(D).FieldKeyDown(K, [ssCtrl]);
  CheckEquals(EncodeDate(2026, 9, 5), D.Date, 0, 'Strg = Monat');
  CheckEquals(2, FChanges7);
  D.MinDate := EncodeDate(2026, 9, 5);
  K := VK_DOWN;
  TDateAccess(D).FieldKeyDown(K, []);
  CheckEquals(EncodeDate(2026, 9, 5), D.Date, 0, 'MinDate');
end;

procedure TDatePickerTests.PopupPicksDate;
var
  D: TPPGDatePicker;
  K: Word;
begin
  FForm.Show;
  try
    D := NewPicker(FForm, Self);
    D.DropDown;
    CheckTrue(D.DroppedDown);
    CheckTrue(D.Popup <> nil);
    CheckEquals(EncodeDate(2026, 10, 4), D.Popup.Calendar.Date, 0);
    K := VK_RIGHT;
    TDateAccess(D).FieldKeyDown(K, []);
    CheckEquals(EncodeDate(2026, 10, 5), D.Popup.Calendar.FocusDate, 0, 'Pfeil an den Kalender');
    CheckEquals(0, FChanges7);
    K := VK_RETURN;
    TDateAccess(D).FieldKeyDown(K, []);
    CheckFalse(D.DroppedDown, 'Enter waehlt und schliesst');
    CheckEquals(EncodeDate(2026, 10, 5), D.Date, 0);
    CheckEquals(1, FChanges7);
    D.DropDown;
    K := VK_DOWN;
    TDateAccess(D).FieldKeyDown(K, []);
    K := VK_ESCAPE;
    TDateAccess(D).FieldKeyDown(K, []);
    CheckFalse(D.DroppedDown);
    CheckEquals(EncodeDate(2026, 10, 5), D.Date, 0, 'Esc verwirft');
    CheckEquals(1, FChanges7);
  finally
    FForm.Hide;
  end;
end;

procedure TDatePickerTests.PopupShowsCalendar;
var
  D: TPPGDatePicker;
  K: Word;
  T0: Cardinal;
begin
  // Regression: das Popup war leer (Kalenderfenster nie gezeigt)
  FForm.Show;
  try
    D := NewPicker(FForm, Self);
    D.Animation.Enabled := True;
    D.SetFocus;
    D.DropDown;
    T0 := GetTickCount;
    while GetTickCount - T0 < 400 do
    begin
      Application.ProcessMessages;
      Sleep(5);
    end;
    CheckTrue(IsWindowVisible(D.Popup.Handle), 'Popup');
    CheckTrue(D.Popup.Calendar.HandleAllocated and IsWindowVisible(D.Popup.Calendar.Handle),
      'Kalenderfenster sichtbar');
    CheckEquals(D.Popup.Width, D.Popup.Calendar.Width);
    CheckTrue(D.Popup.Calendar.Height >= 300, 'volle Hoehe');
    CheckTrue(D.Popup.Calendar.ShowFocusAlways, 'Fokus-Tag sichtbar ohne eigenen Fokus');
    CheckTrue(D.Focused, 'Fokus bleibt beim Feld');
    // Klick auf einen Tag im Kalenderfenster uebernimmt
    ClickDate(D.Popup.Calendar, EncodeDate(2026, 10, 20));
    CheckFalse(D.DroppedDown);
    CheckEquals(EncodeDate(2026, 10, 20), D.Date, 0);
    CheckFalse(IsWindowVisible(D.Popup.Calendar.Handle), 'versteckt nach dem Schliessen');
    D.DropDown;
    CheckTrue(IsWindowVisible(D.Popup.Calendar.Handle), 'wieder sichtbar');
    K := VK_ESCAPE;
    TDateAccess(D).FieldKeyDown(K, []);
  finally
    FForm.Hide;
  end;
end;

procedure TDatePickerTests.CheckboxMeansNoDate;
var
  D: TPPGDatePicker;
begin
  D := NewPicker(FForm, Self);
  D.ShowCheckbox := True;
  CheckTrue(D.HasDate);
  CheckFalse(IsRectEmpty(TDateAccess(D).ButtonRect(PPGDateButtonCheck)));
  TDateAccess(D).ButtonClick(PPGDateButtonCheck);
  CheckFalse(D.Checked);
  CheckFalse(D.HasDate);
  CheckEquals(1, FChanges7);
  CheckEquals('', TDateAccess(D).AccValue);
  D.Text := '';
  TDateAccess(D).CommitText(True);
  CheckEquals(0, D.DateTime, 0, 'leer = kein Datum (nur mit Kontrollkaestchen)');
end;

{ TTimePickerTests }

function NewTime(F: TForm; T: TPhase7bTestCase): TPPGTimePicker;
begin
  Result := TPPGTimePicker.Create(F);
  Result.Parent := F;
  Result.SetBounds(10, 10, 120, 24);
  Result.Animation.Enabled := False;
  Result.ClockFormat := pcf24Hour;
  Result.Time := EncodeTime(9, 5, 0, 0);
  Result.OnChange := T.Count7;
  Result.HandleNeeded;
end;

procedure TTimePickerTests.ParsesManyFormats;
var
  P: TPPGTimePicker;
  T: TTime;
begin
  P := NewTime(FForm, Self);
  CheckTrue(P.ParseTime('14:30', T));
  CheckEquals(EncodeTime(14, 30, 0, 0), T, 0.000001);
  CheckTrue(P.ParseTime('1430', T));
  CheckEquals(EncodeTime(14, 30, 0, 0), T, 0.000001);
  CheckTrue(P.ParseTime('930', T));
  CheckEquals(EncodeTime(9, 30, 0, 0), T, 0.000001);
  CheckTrue(P.ParseTime('2:30 PM', T));
  CheckEquals(EncodeTime(14, 30, 0, 0), T, 0.000001);
  CheckTrue(P.ParseTime('12:00 AM', T));
  CheckEquals(0, T, 0.000001, 'Mitternacht');
  CheckTrue(P.ParseTime('7.15', T), 'Punkt als Trenner');
  CheckEquals(EncodeTime(7, 15, 0, 0), T, 0.000001);
  CheckTrue(P.ParseTime('10:20:30', T));
  CheckEquals(EncodeTime(10, 20, 30, 0), T, 0.000001);
  CheckFalse(P.ParseTime('25:00', T));
  CheckFalse(P.ParseTime('13:00 PM', T));
  CheckFalse(P.ParseTime('abc', T));
  CheckFalse(P.ParseTime('', T));
end;

procedure TTimePickerTests.FormatsByClock;
var
  P: TPPGTimePicker;
begin
  P := NewTime(FForm, Self);
  CheckEquals('09:05', P.Text);
  P.ShowSeconds := True;
  CheckEquals('09:05:00', P.Text);
  P.ShowSeconds := False;
  P.ClockFormat := pcf12Hour;
  CheckEquals('9:05 AM', P.Text);
  P.Time := EncodeTime(21, 40, 0, 0);
  CheckEquals('9:40 PM', P.Text);
  CheckEquals(0, FChanges7);
  CheckEquals('9:40 PM', TTimeAccess(P).AccValue);
end;

procedure TTimePickerTests.ItemsFollowIncrement;
var
  P: TPPGTimePicker;
begin
  P := NewTime(FForm, Self);
  CheckEquals(96, TTimeAccess(P).Items.Count, '15 Minuten');
  P.MinuteIncrement := 30;
  CheckEquals(48, TTimeAccess(P).Items.Count);
  CheckEquals('00:30', TTimeAccess(P).Items[1]);
  CheckEquals('09:05', P.Text, 'Zeit bleibt');
  try
    P.MinuteIncrement := 0;
    Fail('0 Minuten');
  except
    on E: Exception do
      CheckTrue(E is EPPGError, E.ClassName);
  end;
end;

procedure TTimePickerTests.ArrowsStepSegmentWithWrap;
var
  P: TPPGTimePicker;
  K: Word;
begin
  P := NewTime(FForm, Self);
  P.SelStart := 4; // Minute
  K := VK_UP;
  TTimeAccess(P).FieldKeyDown(K, []);
  CheckEquals('09:06', P.Text);
  P.SelStart := 0; // Stunde
  K := VK_UP;
  TTimeAccess(P).FieldKeyDown(K, []);
  CheckEquals('10:06', P.Text);
  P.Time := EncodeTime(23, 59, 0, 0);
  P.SelStart := 4;
  K := VK_UP;
  TTimeAccess(P).FieldKeyDown(K, []);
  CheckEquals('00:00', P.Text, 'Uebertrag ueber Mitternacht');
  P.SelStart := 1;
  K := VK_DOWN;
  TTimeAccess(P).FieldKeyDown(K, []);
  CheckEquals('23:00', P.Text, 'rueckwaerts');
  CheckEquals(4, FChanges7);
end;

procedure TTimePickerTests.CommitFiresOnceAndCodeIsQuiet;
var
  P: TPPGTimePicker;
begin
  P := NewTime(FForm, Self);
  P.Time := EncodeTime(8, 0, 0, 0);
  CheckEquals(0, FChanges7);
  P.Text := '7:45';
  CheckEquals(0, FChanges7, 'Text im Code');
  CheckTrue(TTimeAccess(P).CommitText(True));
  CheckEquals(EncodeTime(7, 45, 0, 0), P.Time, 0.000001);
  CheckEquals('07:45', P.Text);
  CheckEquals(1, FChanges7);
  P.Text := 'Mittag';
  CheckFalse(TTimeAccess(P).CommitText(True));
  CheckTrue(P.ValidationState = pvsError);
  CheckEquals(1, FChanges7);
end;

procedure TTimePickerTests.ListSelectsTime;
var
  P: TPPGTimePicker;
begin
  FForm.Show;
  try
    P := NewTime(FForm, Self);
    P.DropDown;
    CheckTrue(P.DroppedDown);
    PumpPosted(P.Handle);
    CheckEquals(36, P.PopupList.Highlight, '09:05 -> naechste 09:00');
    P.PopupList.SetHighlight(40);
    P.CloseUp(True);
    CheckEquals(EncodeTime(10, 0, 0, 0), P.Time, 0.000001);
    CheckEquals(1, FChanges7);
  finally
    FForm.Hide;
  end;
end;

{ TPhase7bPaintTests }

procedure TPhase7bPaintTests.PaintAllPresetsAndModes;
var
  Names: TStringList;
  P, I: Integer;
  Dark, Gdi: Boolean;
  L: array of TWinControl;
  C: TPPGCalendar;
begin
  Names := TStringList.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    FForm.Show;
    try
      for P := 0 to Names.Count - 1 do
        for Dark := False to True do
          for Gdi := False to True do
          begin
            if Dark then
              TPPGTheme.Mode := tmDark
            else
              TPPGTheme.Mode := tmLight;
            TPPGRendererRegistry.ForceGdiFallback := Gdi;
            SetLength(L, 5);
            C := NewCalendar;
            C.Date := EncodeDate(2026, 10, 8);
            C.ShowWeekNumbers := True;
            L[0] := C;
            C := NewCalendar;
            C.SelectionMode := dsmRange;
            C.SelectRange(EncodeDate(2026, 10, 5), EncodeDate(2026, 10, 9));
            C.View := cvYear;
            L[1] := C;
            L[2] := NewPicker(FForm, Self);
            TPPGDatePicker(L[2]).ShowCheckbox := True;
            L[3] := NewTime(FForm, Self);
            C := NewCalendar;
            C.View := cvDecade;
            L[4] := C;
            for I := 0 to High(L) do
            begin
              TCC7b(L[I]).Preset := Names[P];
              RenderToBitmap(L[I]).Free;
            end;
            for I := 0 to High(L) do
              L[I].Free;
          end;
    finally
      FForm.Hide;
      TPPGTheme.Mode := tmLight;
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  finally
    Names.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPhase7bPaintTests.NoHandleOrMemoryLeaks;

  procedure Cycle;
  var
    I: Integer;
    C: TPPGCalendar;
    D: TPPGDatePicker;
    T: TPPGTimePicker;
  begin
    for I := 1 to 5 do
    begin
      C := NewCalendar;
      C.SelectionMode := dsmMultiple;
      C.Select(EncodeDate(2026, 10, 2));
      RenderToBitmap(C).Free;
      C.Free;
      D := NewPicker(FForm, Self);
      D.DropDown;
      D.CloseUp(False);
      RenderToBitmap(D).Free;
      D.Free;
      T := NewTime(FForm, Self);
      T.DropDown;
      T.CloseUp(False);
      RenderToBitmap(T).Free;
      T.Free;
    end;
  end;

var
  Gdi0, User0: Cardinal;
  M0, M1: NativeUInt;
begin
  FForm.Show;
  try
    Cycle;
    PumpPosted(0);
    Gdi0 := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
    User0 := GetGuiResources(GetCurrentProcess, GR_USEROBJECTS);
    M0 := AllocatedBytes;
    Cycle;
    Cycle;
    PumpPosted(0);
    M1 := AllocatedBytes;
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS) <= Gdi0 + 2, 'GDI-Handles wachsen');
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_USEROBJECTS) <= User0 + 2, 'USER-Handles wachsen');
    CheckTrue(M1 <= M0 + 4096, Format('Speicher waechst: %d -> %d', [M0, M1]));
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterClasses([TPPGCalendar, TPPGDatePicker, TPPGTimePicker]);
  RegisterTest('Phase7b', TCalendarTests.Suite);
  RegisterTest('Phase7b', TDatePickerTests.Suite);
  RegisterTest('Phase7b', TTimePickerTests.Suite);
  RegisterTest('Phase7b', TPhase7bPaintTests.Suite);

end.
