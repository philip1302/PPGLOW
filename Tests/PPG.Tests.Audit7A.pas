unit PPG.Tests.Audit7A;

{ Audit-Paket 7A (Docs\Audit-Paket7-Plan.md): Regressionstests fuer
  7a Aufklappfelder, 7b Mausrad und 7c #6 (Segmente im DatePicker).

  TDatePickerPinTests halten das Verhalten des DatePickers vor dem Umbau auf
  die Aufklapp-Basis fest (7a #3): sie liefen gegen den alten Code gruen. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.DateUtils, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls,
  Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Types, PPG.Controls.Base, PPG.Controls.Field, PPG.Controls.DropDown, PPG.Popup,
  PPG.Calendar, PPG.DatePicker, PPG.TimePicker, PPG.NumberEdit, PPG.SpinEdit,
  PPG.ComboBox, PPG.TrackBar, PPG.Kanban, PPG.Planner, PPG.TileView, PPG.Panel,
  PPG.Edit, PPG.DB.Controls, PPG.Tests.Controls;

type
  TAudit7ATestCase = class(TControlTestCase)
  protected
    FSavedFS: TFormatSettings;
    FChanges: Integer;
    FClicks: Integer;
    FDropDowns: Integer;
    FCloseUps: Integer;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure Changed(Sender: TObject);
    procedure Clicked(Sender: TObject);
    procedure DroppedDown(Sender: TObject);
    procedure ClosedUp(Sender: TObject);
    function NewPicker: TPPGDatePicker;
    /// Klick an einem Bildschirmpunkt wie Windows ihn zustellt: an das Fenster
    /// mit der Maus (Capture), sonst an Fallback.
    procedure ClickAt(const ScreenPt: TPoint; Fallback: TWinControl);
    procedure ClickDay(D: TPPGDatePicker; Day: TDate);
    procedure Key(D: TPPGCustomField; VK: Word; Shift: TShiftState = []);
    /// Enter wie die VCL ihn verteilt: erst CN_KEYDOWN (Dialogtaste), dann WM_KEYDOWN/WM_CHAR.
    procedure PressEnter(F: TPPGCustomField);
  end;

  /// 7a #3: Verhalten vor dem Umbau (gegen den alten Code gruen).
  TDatePickerPinTests = class(TAudit7ATestCase)
  published
    procedure KeysOpenAndEscCloses;
    procedure ButtonTogglesAndEventsFire;
    procedure ClickOnDayPicks;
    procedure EnterPicksFocusedDay;
    procedure EscDiscards;
    procedure FocusLossCloses;
    procedure CheckboxPickChecks;
    procedure SpinModeAndReadOnlyDoNotOpen;
    procedure DBNullAndPick;
  end;

  /// 7a: Aufklappfelder.
  TDropDownFieldTests = class(TAudit7ATestCase)
  published
    procedure F4AndAltArrowCloseAccepting;
    procedure EnterGoesToDefaultButton;
    procedure DatePickerUsesDropDownBase;
    procedure ClickOutsideCloses;
    procedure PopupFollowsForm;
    procedure HidingFormCloses;
    procedure RegionNotPerFrame;
    procedure ItemHeightFollowsFont;
  end;

  /// 7b: Mausrad.
  TWheelTests = class(TAudit7ATestCase)
  published
    procedure SpinEditNeedsFocusAndCollects;
    procedure NumberEditCollectsPartialDeltas;
    procedure TimePickerCollectsPartialDeltas;
    procedure CalendarNeedsFocus;
    procedure TrackBarNeedsFocus;
    procedure PopupListUsesSystemLines;
    procedure KanbanCollectsFineDeltas;
    procedure PlannerMonthOnePagePerNotch;
    procedure TileViewZoomOnePerNotch;
    procedure PanelCollectsFineDeltas;
  end;

  /// 7c #6: Segmente im DatePicker.
  TDateSegmentTests = class(TAudit7ATestCase)
  published
    procedure TimeKindStepsSegmentAtCaret;
    procedure DateTimeKindStepsDateOrTime;
    procedure WheelStepsSegment;
  end;

implementation

type
  TDateAccess = class(TPPGDatePicker);
  TFieldAccess = class(TPPGCustomField);
  TTimeAccess = class(TPPGTimePicker);
  TNumberAccess = class(TPPGNumberEdit);
  TSpinAccess = class(TPPGSpinEdit);
  TComboAccess = class(TPPGComboBox);
  TCalAccess = class(TPPGCalendar);
  TTrackAccess = class(TPPGTrackBar);
  TKanbanAccess = class(TPPGKanban);
  TPlannerAccess = class(TPPGPlanner);
  TTileAccess = class(TPPGTileView);
  TPanelAccess = class(TPPGPanel);

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

function SystemWheelLines: Integer;
var
  L: UINT;
begin
  L := 3;
  SystemParametersInfo(SPI_GETWHEELSCROLLLINES, 0, @L, 0);
  Result := Integer(L);
end;

function RgnBox(Wnd: HWND; out Box: TRect): Boolean;
var
  Rgn: HRGN;
begin
  Box := Rect(0, 0, 0, 0);
  Rgn := CreateRectRgn(0, 0, 0, 0);
  try
    Result := GetWindowRgn(Wnd, Rgn) <> ERROR;
    if Result then
      GetRgnBox(Rgn, Box);
  finally
    DeleteObject(Rgn);
  end;
end;

{ TAudit7ATestCase }

procedure TAudit7ATestCase.SetUp;
begin
  inherited SetUp;
  FSavedFS := FormatSettings;
  FormatSettings.DateSeparator := '.';
  FormatSettings.ShortDateFormat := 'dd.mm.yyyy';
  FormatSettings.LongDateFormat := 'dddd, d. mmmm yyyy';
  FormatSettings.TimeSeparator := ':';
  FormatSettings.ShortTimeFormat := 'hh:nn';
  FormatSettings.LongTimeFormat := 'hh:nn:ss';
  FormatSettings.TimeAMString := 'AM';
  FormatSettings.TimePMString := 'PM';
  FChanges := 0;
  FClicks := 0;
  FDropDowns := 0;
  FCloseUps := 0;
end;

procedure TAudit7ATestCase.TearDown;
begin
  if GetCapture <> 0 then
    ReleaseCapture;
  if FForm <> nil then
    FForm.Hide;
  inherited TearDown;
  FormatSettings := FSavedFS;
end;

procedure TAudit7ATestCase.Changed(Sender: TObject);
begin
  Inc(FChanges);
end;

procedure TAudit7ATestCase.Clicked(Sender: TObject);
begin
  Inc(FClicks);
end;

procedure TAudit7ATestCase.DroppedDown(Sender: TObject);
begin
  Inc(FDropDowns);
end;

procedure TAudit7ATestCase.ClosedUp(Sender: TObject);
begin
  Inc(FCloseUps);
end;

function TAudit7ATestCase.NewPicker: TPPGDatePicker;
begin
  Result := TPPGDatePicker.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 160, 24);
  Result.Animation.Enabled := False;
  Result.Date := EncodeDate(2026, 10, 4);
  Result.OnChange := Changed;
  Result.OnDropDown := DroppedDown;
  Result.OnCloseUp := ClosedUp;
  Result.HandleNeeded;
end;

procedure TAudit7ATestCase.ClickAt(const ScreenPt: TPoint; Fallback: TWinControl);

  procedure Send(Msg: Cardinal; Keys: WPARAM);
  var
    W: HWND;
    P: TPoint;
  begin
    W := GetCapture;
    if W = 0 then
      W := Fallback.Handle;
    P := ScreenPt;
    Winapi.Windows.ScreenToClient(W, P);
    SendMessage(W, Msg, Keys, MouseLParam(P.X, P.Y));
  end;

begin
  Send(WM_MOUSEMOVE, 0);
  Send(WM_LBUTTONDOWN, MK_LBUTTON);
  Send(WM_LBUTTONUP, 0);
end;

procedure TAudit7ATestCase.ClickDay(D: TPPGDatePicker; Day: TDate);
var
  C: TPPGCalendar;
  R: TRect;
  I: Integer;
begin
  C := D.Popup.Calendar;
  I := Trunc(Day) - Trunc(C.CellDate(0));
  R := C.CellRect(I);
  ClickAt(C.ClientToScreen(Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2)), C);
end;

procedure TAudit7ATestCase.Key(D: TPPGCustomField; VK: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := VK;
  TFieldAccess(D).FieldKeyDown(K, Shift);
end;

procedure TAudit7ATestCase.PressEnter(F: TPPGCustomField);
var
  W: TWinControl;
begin
  W := TFieldAccess(F).Inner;
  if W.Perform(CN_KEYDOWN, VK_RETURN, 0) <> 0 then
    Exit; // Dialogtaste: Default-Button hat sie bekommen
  W.Perform(WM_KEYDOWN, VK_RETURN, 0);
  W.Perform(WM_CHAR, 13, 0);
end;

{ TDatePickerPinTests }

procedure TDatePickerPinTests.KeysOpenAndEscCloses;
var
  D: TPPGDatePicker;
begin
  FForm.Show;
  D := NewPicker;
  Key(D, VK_F4);
  CheckTrue(D.DroppedDown, 'F4 klappt auf');
  Key(D, VK_ESCAPE);
  CheckFalse(D.DroppedDown, 'Esc schliesst');
  Key(D, VK_DOWN, [ssAlt]);
  CheckTrue(D.DroppedDown, 'Alt+Pfeil runter klappt auf');
  Key(D, VK_ESCAPE);
  CheckFalse(D.DroppedDown);
  CheckEquals(EncodeDate(2026, 10, 4), D.Date, 0);
  CheckEquals(0, FChanges);
end;

procedure TDatePickerPinTests.ButtonTogglesAndEventsFire;
var
  D: TPPGDatePicker;
begin
  FForm.Show;
  D := NewPicker;
  TDateAccess(D).ButtonDown(PPGDateButtonCalendar);
  CheckTrue(D.DroppedDown, 'Knopf klappt auf');
  CheckEquals(1, FDropDowns);
  CheckTrue(D.Popup <> nil);
  CheckTrue(IsWindowVisible(D.Popup.Handle));
  CheckTrue(D.Popup.Calendar.HandleAllocated and IsWindowVisible(D.Popup.Calendar.Handle));
  CheckEquals(EncodeDate(2026, 10, 4), D.Popup.Calendar.Date, 0, 'Kalender zeigt das Datum');
  TDateAccess(D).ButtonDown(PPGDateButtonCalendar);
  CheckFalse(D.DroppedDown, 'Knopf klappt zu');
  CheckEquals(1, FCloseUps);
  CheckFalse(IsWindowVisible(D.Popup.Handle));
  CheckEquals(0, FChanges);
  D.DroppedDown := True;
  CheckTrue(D.DroppedDown, 'DroppedDown setzbar');
  D.DroppedDown := False;
  CheckFalse(D.DroppedDown);
end;

procedure TDatePickerPinTests.ClickOnDayPicks;
var
  D: TPPGDatePicker;
begin
  FForm.Show;
  D := NewPicker;
  D.SetFocus;
  D.DropDown;
  ClickDay(D, EncodeDate(2026, 10, 20));
  CheckFalse(D.DroppedDown, 'Klick auf einen Tag schliesst');
  CheckEquals(EncodeDate(2026, 10, 20), D.Date, 0);
  CheckEquals(1, FChanges);
  CheckEquals(1, FCloseUps);
  CheckTrue(TDateAccess(D).FieldFocused, 'Fokus bleibt beim Feld');
end;

procedure TDatePickerPinTests.EnterPicksFocusedDay;
var
  D: TPPGDatePicker;
begin
  FForm.Show;
  D := NewPicker;
  D.DropDown;
  Key(D, VK_RIGHT);
  Key(D, VK_DOWN);
  CheckEquals(EncodeDate(2026, 10, 12), D.Popup.Calendar.FocusDate, 0, 'Pfeile an den Kalender');
  CheckEquals(0, FChanges);
  Key(D, VK_RETURN);
  CheckFalse(D.DroppedDown);
  CheckEquals(EncodeDate(2026, 10, 12), D.Date, 0);
  CheckEquals(1, FChanges);
end;

procedure TDatePickerPinTests.EscDiscards;
var
  D: TPPGDatePicker;
begin
  FForm.Show;
  D := NewPicker;
  D.DropDown;
  Key(D, VK_NEXT);
  Key(D, VK_ESCAPE);
  CheckFalse(D.DroppedDown);
  CheckEquals(EncodeDate(2026, 10, 4), D.Date, 0, 'Esc verwirft');
  CheckEquals(0, FChanges);
end;

procedure TDatePickerPinTests.FocusLossCloses;
var
  D: TPPGDatePicker;
  E: TPPGEdit;
begin
  FForm.Show;
  E := TPPGEdit.Create(FForm);
  E.Parent := FForm;
  E.SetBounds(10, 200, 100, 24);
  D := NewPicker;
  D.SetFocus;
  D.DropDown;
  Key(D, VK_RIGHT);
  E.SetFocus;
  CheckFalse(D.DroppedDown, 'Fokusverlust schliesst');
  CheckEquals(EncodeDate(2026, 10, 4), D.Date, 0, 'ohne Uebernahme');
  CheckEquals(0, FChanges);
end;

procedure TDatePickerPinTests.CheckboxPickChecks;
var
  D: TPPGDatePicker;
begin
  FForm.Show;
  D := NewPicker;
  D.ShowCheckbox := True;
  D.Checked := False;
  CheckFalse(D.HasDate);
  D.DropDown;
  CheckEquals(0, D.Popup.Calendar.Date, 0, 'ohne Haken keine Auswahl im Kalender');
  ClickDay(D, EncodeDate(2026, 10, 6));
  CheckFalse(D.DroppedDown);
  CheckTrue(D.Checked, 'Auswahl setzt den Haken');
  CheckTrue(D.HasDate);
  CheckEquals(EncodeDate(2026, 10, 6), D.Date, 0);
  CheckEquals(1, FChanges);
end;

procedure TDatePickerPinTests.SpinModeAndReadOnlyDoNotOpen;
var
  D: TPPGDatePicker;
begin
  FForm.Show;
  D := NewPicker;
  D.DateMode := dmUpDown;
  D.DropDown;
  CheckFalse(D.DroppedDown, 'Auf/Ab: kein Kalender');
  D.DateMode := dmComboBox;
  TDateAccess(D).ReadOnly := True;
  D.DropDown;
  CheckFalse(D.DroppedDown, 'ReadOnly');
  TDateAccess(D).ReadOnly := False;
  D.DropDown;
  CheckTrue(D.DroppedDown);
  D.Kind := dtkTime;
  CheckFalse(D.DroppedDown, 'Wechsel auf Uhrzeit schliesst');
  D.Kind := dtkDate;
  D.DropDown;
  D.Enabled := False;
  CheckFalse(D.DroppedDown, 'Abschalten schliesst');
  CheckEquals(0, FChanges);
end;

procedure TDatePickerPinTests.DBNullAndPick;
var
  DS: TClientDataSet;
  Src: TDataSource;
  D: TPPGDBDatePicker;
begin
  DS := TClientDataSet.Create(nil);
  Src := TDataSource.Create(nil);
  try
    DS.FieldDefs.Add('Termin', ftDate);
    DS.CreateDataSet;
    DS.Append;
    DS.Post;
    Src.DataSet := DS;
    FForm.Show;
    D := TPPGDBDatePicker.Create(FForm);
    D.Parent := FForm;
    D.SetBounds(10, 10, 160, 24);
    D.Animation.Enabled := False;
    D.ShowCheckbox := True;
    D.DataSource := Src;
    D.DataField := 'Termin';
    CheckFalse(D.Checked, 'Null: ohne Haken');
    D.SetFocus;
    D.DropDown;
    CheckTrue(D.DroppedDown);
    ClickDay(D, Trunc(D.Popup.Calendar.CellDate(10)));
    CheckFalse(D.DroppedDown);
    CheckTrue(D.Checked);
    CheckTrue(DS.State = dsEdit, 'Auswahl setzt den Datensatz in Bearbeitung');
    D.Perform(CM_EXIT, 0, 0);
    DS.Post;
    CheckFalse(DS.FieldByName('Termin').IsNull);
    CheckEquals(D.Date, DS.FieldByName('Termin').AsDateTime, 0);
    D.Free;
  finally
    Src.Free;
    DS.Free;
  end;
end;

{ TDropDownFieldTests }

procedure TDropDownFieldTests.F4AndAltArrowCloseAccepting;
var
  D: TPPGDatePicker;
begin
  // Audit 09.10.2026, Paket 7a #1: F4 und Alt+Pfeil schlossen ohne Uebernahme
  // (CloseUp(False)); Alt+Pfeil hoch klappte nicht wieder zu.
  FForm.Show;
  D := NewPicker;
  D.DropDown;
  Key(D, VK_RIGHT);
  Key(D, VK_F4);
  CheckFalse(D.DroppedDown);
  CheckEquals(EncodeDate(2026, 10, 5), D.Date, 0, 'F4 uebernimmt den Fokus-Tag');
  CheckEquals(1, FChanges);
  Key(D, VK_DOWN, [ssAlt]);
  Key(D, VK_RIGHT);
  Key(D, VK_UP, [ssAlt]);
  CheckFalse(D.DroppedDown);
  CheckEquals(EncodeDate(2026, 10, 6), D.Date, 0, 'Alt+Pfeil hoch uebernimmt');
  CheckEquals(2, FChanges);
  Key(D, VK_DOWN, [ssAlt]);
  Key(D, VK_DOWN, [ssAlt]);
  CheckFalse(D.DroppedDown, 'Alt+Pfeil runter klappt auch zu');
  CheckEquals(EncodeDate(2026, 10, 6), D.Date, 0, 'unveraendert');
  CheckEquals(2, FChanges, 'ohne Aenderung kein OnChange');
end;

procedure TDropDownFieldTests.EnterGoesToDefaultButton;
var
  B: TButton;
  D: TPPGDatePicker;
  T: TPPGTimePicker;
  N: TPPGNumberEdit;
begin
  // Audit 09.10.2026, Paket 7a #2: DatePicker, TimePicker und NumberEdit
  // beanspruchten Enter immer - der Default-Button reagierte nie.
  FForm.Show;
  B := TButton.Create(FForm);
  B.Parent := FForm;
  B.SetBounds(200, 200, 80, 25);
  B.Default := True;
  B.OnClick := Clicked;
  D := NewPicker;
  T := TPPGTimePicker.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(10, 50, 120, 24);
  T.ClockFormat := pcf24Hour;
  T.Time := EncodeTime(9, 5, 0, 0);
  N := TPPGNumberEdit.Create(FForm);
  N.Parent := FForm;
  N.SetBounds(10, 90, 120, 24);
  N.Value := 5;

  D.SetFocus;
  PressEnter(D);
  CheckEquals(1, FClicks, 'DatePicker unveraendert: Default-Button');
  D.Text := '05.10.2026';
  PressEnter(D);
  CheckEquals(1, FClicks, 'getippt: Enter uebernimmt');
  CheckEquals(EncodeDate(2026, 10, 5), D.Date, 0);
  PressEnter(D);
  CheckEquals(2, FClicks, 'danach wieder der Default-Button');
  D.DropDown;
  PressEnter(D);
  CheckEquals(2, FClicks, 'offen: Enter waehlt im Kalender');
  CheckFalse(D.DroppedDown);

  T.SetFocus;
  PressEnter(T);
  CheckEquals(3, FClicks, 'TimePicker unveraendert: Default-Button');
  T.Text := '10:30';
  PressEnter(T);
  CheckEquals(3, FClicks);
  CheckEquals(EncodeTime(10, 30, 0, 0), T.Time, 0.000001);

  N.SetFocus;
  PressEnter(N);
  CheckEquals(4, FClicks, 'NumberEdit unveraendert: Default-Button');
  N.Text := '7';
  PressEnter(N);
  CheckEquals(4, FClicks);
  CheckEquals(7, N.Value, 1E-9);
end;

procedure TDropDownFieldTests.DatePickerUsesDropDownBase;
var
  D: TPPGDatePicker;
begin
  // Audit 09.10.2026, Paket 7a #3: eigener Maus-Hook statt Aufklapp-Basis
  D := NewPicker;
  CheckTrue(TObject(D) is TPPGCustomDropDownField, 'DatePicker auf TPPGCustomDropDownField');
  FForm.Show;
  D.DropDown;
  CheckTrue(TObject(D.Popup) is TPPGDropPopup, 'Kalender-Popup ist ein TPPGDropPopup');
  CheckEquals(D.Handle, GetCapture, 'Feld haelt die Maus wie die anderen Aufklappfelder');
  D.CloseUp(False);
end;

procedure TDropDownFieldTests.ClickOutsideCloses;
var
  D: TPPGDatePicker;
  P: TPoint;
begin
  FForm.Show;
  D := NewPicker;
  D.SetFocus;
  D.DropDown;
  Key(D, VK_RIGHT);
  P := FForm.ClientToScreen(Point(380, 280));
  ClickAt(P, FForm);
  CheckFalse(D.DroppedDown, 'Klick ausserhalb schliesst');
  CheckEquals(EncodeDate(2026, 10, 4), D.Date, 0, 'ohne Uebernahme');
  CheckEquals(0, FChanges);
end;

procedure TDropDownFieldTests.PopupFollowsForm;
var
  D: TPPGDatePicker;
  C: TPPGComboBox;
  R0, R1: TRect;
  I: Integer;
begin
  // Audit 09.10.2026, Paket 7a #4: Popups blieben stehen, wenn das Formular
  // verschoben wurde (z.B. per Tastatur oder Code).
  FForm.Show;
  D := NewPicker;
  D.DropDown;
  GetWindowRect(D.Popup.Handle, R0);
  FForm.Left := FForm.Left + 40;
  FForm.Top := FForm.Top + 30;
  Application.ProcessMessages;
  CheckTrue(D.DroppedDown);
  GetWindowRect(D.Popup.Handle, R1);
  CheckEquals(R0.Left + 40, R1.Left, 'DatePicker-Popup folgt waagerecht');
  CheckEquals(R0.Top + 30, R1.Top, 'DatePicker-Popup folgt senkrecht');
  D.CloseUp(False);

  C := TPPGComboBox.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(10, 60, 160, 24);
  C.Animation.Enabled := False;
  for I := 1 to 20 do
    C.Items.Add('Eintrag ' + IntToStr(I));
  C.DropDown;
  GetWindowRect(C.PopupList.Handle, R0);
  FForm.Left := FForm.Left - 25;
  Application.ProcessMessages;
  GetWindowRect(C.PopupList.Handle, R1);
  CheckEquals(R0.Left - 25, R1.Left, 'Listen-Popup folgt');
  CheckEquals(R0.Top, R1.Top);
  C.CloseUp(False);
end;

procedure TDropDownFieldTests.HidingFormCloses;
var
  D: TPPGDatePicker;
begin
  FForm.Show;
  D := NewPicker;
  D.DropDown;
  CheckTrue(D.DroppedDown);
  FForm.Hide;
  CheckFalse(D.DroppedDown, 'Formular versteckt: Popup schliesst');
  CheckFalse(IsWindowVisible(D.Popup.Handle));
  CheckEquals(0, FChanges);
end;

procedure TDropDownFieldTests.RegionNotPerFrame;
var
  D: TPPGDatePicker;
  Final, Box: TRect;
  FinalH: Integer;
begin
  // Audit 09.10.2026, Paket 7a #5: die Aufklapp-Animation setzte je Bild eine
  // neue Fensterregion (SetWindowRgn). Die Region hat jetzt von Anfang an die
  // Endgroesse.
  FForm.Show;
  D := NewPicker;
  D.DropDown;
  FinalH := D.Popup.Height;
  CheckTrue(RgnBox(D.Popup.Handle, Final), 'abgerundetes Popup hat eine Region');
  D.CloseUp(False);
  D.Animation.Enabled := True;
  if not D.Animation.EffectiveEnabled then
    Exit; // Animationen im System aus: nichts zu pruefen
  D.DropDown;
  CheckTrue(D.Popup.Height < FinalH, 'Animation laeuft');
  CheckTrue(RgnBox(D.Popup.Handle, Box));
  CheckEquals(Final.Bottom - Final.Top, Box.Bottom - Box.Top, 'Region schon in Endgroesse');
  D.CloseUp(False);
end;

procedure TDropDownFieldTests.ItemHeightFollowsFont;
var
  C: TPPGComboBox;
  H0, H1: Integer;
begin
  // 7a #6: ItemHeight wird zwischengespeichert - Schrift, PPI, Bilder und
  // Zweizeiligkeit verwerfen den Wert.
  FForm.Show;
  C := TPPGComboBox.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(10, 60, 160, 24);
  C.Animation.Enabled := False;
  C.Items.Add('A');
  C.DropDown;
  H0 := C.PopupList.ItemHeight;
  CheckEquals(H0, C.PopupList.ItemHeight);
  C.CloseUp(False);
  C.Font.Size := C.Font.Size * 2;
  C.DropDown;
  H1 := C.PopupList.ItemHeight;
  CheckTrue(H1 > H0, 'groessere Schrift: hoehere Zeilen');
  C.PopupList.TwoLineItems := True;
  CheckTrue(C.PopupList.ItemHeight > H1, 'zweizeilig');
  C.PopupList.TwoLineItems := False;
  CheckEquals(H1, C.PopupList.ItemHeight);
  C.PopupList.MinItemHeight := 200;
  CheckTrue(C.PopupList.ItemHeight >= 200, 'MinItemHeight');
  C.CloseUp(False);
end;

{ TWheelTests }

procedure TWheelTests.SpinEditNeedsFocusAndCollects;
var
  S: TPPGSpinEdit;
  E: TPPGEdit;
begin
  // Audit 09.10.2026, Paket 7b: das Rad aenderte den Wert ohne Fokus, und
  // jede Nachricht eines hochaufloesenden Rads zaehlte als ganzer Schritt.
  FForm.Show;
  E := TPPGEdit.Create(FForm);
  E.Parent := FForm;
  E.SetBounds(10, 200, 100, 24);
  S := TPPGSpinEdit.Create(FForm);
  S.Parent := FForm;
  S.SetBounds(10, 10, 120, 24);
  S.Value := 10;
  E.SetFocus;
  CheckFalse(TSpinAccess(S).DoMouseWheel([], WHEEL_DELTA, Point(0, 0)),
    'ohne Fokus: Rad geht an den Elternteil');
  CheckEquals(10, S.Value, 'ohne Fokus keine Aenderung');
  S.SetFocus;
  CheckTrue(TSpinAccess(S).DoMouseWheel([], 40, Point(0, 0)));
  TSpinAccess(S).DoMouseWheel([], 40, Point(0, 0));
  CheckEquals(10, S.Value, 'Teil-Deltas gesammelt');
  TSpinAccess(S).DoMouseWheel([], 40, Point(0, 0));
  CheckEquals(11, S.Value, '3 x 40 = ein Schritt');
  TSpinAccess(S).DoMouseWheel([], -WHEEL_DELTA, Point(0, 0));
  CheckEquals(10, S.Value);
end;

procedure TWheelTests.NumberEditCollectsPartialDeltas;
var
  N: TPPGNumberEdit;
begin
  FForm.Show;
  N := TPPGNumberEdit.Create(FForm);
  N.Parent := FForm;
  N.SetBounds(10, 10, 120, 24);
  N.Value := 5;
  N.SetFocus;
  TNumberAccess(N).DoMouseWheel([], 40, Point(0, 0));
  TNumberAccess(N).DoMouseWheel([], 40, Point(0, 0));
  CheckEquals(5, N.Value, 1E-9, 'Teil-Deltas');
  TNumberAccess(N).DoMouseWheel([], 40, Point(0, 0));
  CheckEquals(6, N.Value, 1E-9, '3 x 40 = ein Schritt');
end;

procedure TWheelTests.TimePickerCollectsPartialDeltas;
var
  T: TPPGTimePicker;
begin
  FForm.Show;
  T := TPPGTimePicker.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(10, 10, 120, 24);
  T.Animation.Enabled := False;
  T.ClockFormat := pcf24Hour;
  T.Time := EncodeTime(9, 5, 0, 0);
  T.SetFocus;
  T.SelStart := 4; // Minute
  TTimeAccess(T).DoMouseWheel([], 40, Point(0, 0));
  TTimeAccess(T).DoMouseWheel([], 40, Point(0, 0));
  CheckEquals(EncodeTime(9, 5, 0, 0), T.Time, 0.000001, 'Teil-Deltas');
  TTimeAccess(T).DoMouseWheel([], 40, Point(0, 0));
  CheckEquals(EncodeTime(9, 6, 0, 0), T.Time, 0.000001, '3 x 40 = eine Minute');
end;

procedure TWheelTests.CalendarNeedsFocus;
var
  C: TPPGCalendar;
  E: TPPGEdit;
begin
  FForm.Show;
  E := TPPGEdit.Create(FForm);
  E.Parent := FForm;
  E.SetBounds(10, 260, 100, 24);
  C := TPPGCalendar.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(10, 10, 280, 240);
  C.Animation.Enabled := False;
  C.Date := EncodeDate(2026, 10, 4);
  E.SetFocus;
  CheckFalse(TCalAccess(C).DoMouseWheel([], -WHEEL_DELTA, Point(0, 0)), 'ohne Fokus: an den Elternteil');
  CheckEquals(10, C.DisplayMonth, 'ohne Fokus kein Blaettern');
  C.SetFocus;
  TCalAccess(C).DoMouseWheel([], -40, Point(0, 0));
  TCalAccess(C).DoMouseWheel([], -40, Point(0, 0));
  CheckEquals(10, C.DisplayMonth, 'Teil-Deltas');
  TCalAccess(C).DoMouseWheel([], -40, Point(0, 0));
  CheckEquals(11, C.DisplayMonth, '3 x 40 = eine Seite');
end;

procedure TWheelTests.TrackBarNeedsFocus;
var
  T: TPPGTrackBar;
  E: TPPGEdit;
begin
  FForm.Show;
  E := TPPGEdit.Create(FForm);
  E.Parent := FForm;
  E.SetBounds(10, 260, 100, 24);
  T := TPPGTrackBar.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(10, 10, 200, 32);
  T.Position := 5;
  E.SetFocus;
  CheckFalse(TTrackAccess(T).DoMouseWheel([], -WHEEL_DELTA, Point(0, 0)), 'ohne Fokus: an den Elternteil');
  CheckEquals(5, T.Position, 'ohne Fokus keine Aenderung');
  T.SetFocus;
  CheckTrue(TTrackAccess(T).DoMouseWheel([], -WHEEL_DELTA, Point(0, 0)));
  CheckEquals(6, T.Position);
end;

procedure TWheelTests.PopupListUsesSystemLines;
var
  C: TPPGComboBox;
  I, Lines: Integer;
begin
  Lines := SystemWheelLines;
  if (Lines <= 0) or (Lines > 20) then
    Exit; // seitenweise bzw. aus: hier nicht pruefbar
  FForm.Show;
  C := TPPGComboBox.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(10, 10, 160, 24);
  C.Animation.Enabled := False;
  for I := 1 to 100 do
    C.Items.Add('Eintrag ' + IntToStr(I));
  C.SetFocus;
  C.DropDown;
  CheckEquals(0, C.PopupList.TopIndex);
  TComboAccess(C).DoMouseWheel([], -40, Point(0, 0));
  TComboAccess(C).DoMouseWheel([], -40, Point(0, 0));
  TComboAccess(C).DoMouseWheel([], -40, Point(0, 0));
  CheckEquals(Lines, C.PopupList.TopIndex, '3 x 40 = eine Raste = Zeilen aus der Systemeinstellung');
  C.CloseUp(False);
end;

procedure TWheelTests.KanbanCollectsFineDeltas;

  function NewBoard: TPPGKanban;
  var
    I: Integer;
  begin
    Result := TPPGKanban.Create(FForm);
    Result.Parent := FForm;
    Result.SetBounds(0, 0, 380, 280);
    Result.Animation.Enabled := False;
    Result.SmoothScrolling := False;
    Result.Columns.AddColumn('A');
    for I := 1 to 40 do
      Result.Cards.AddCard(1, 'Karte ' + IntToStr(I));
    Result.HandleNeeded;
  end;

var
  K1, K2: TPPGKanban;
  P: TPoint;
  I: Integer;
begin
  FForm.Show;
  K1 := NewBoard;
  P := K1.ClientToScreen(Point(40, 120));
  TKanbanAccess(K1).DoMouseWheel([], -WHEEL_DELTA, P);
  CheckTrue(K1.ColumnScroll(0) > 0, 'eine Raste scrollt');
  K2 := NewBoard;
  for I := 1 to WHEEL_DELTA do
    TKanbanAccess(K2).DoMouseWheel([], -1, P);
  CheckEquals(K1.ColumnScroll(0), K2.ColumnScroll(0), '120 x 1 = eine Raste (kein Rundungsverlust)');
end;

procedure TWheelTests.PlannerMonthOnePagePerNotch;
var
  P: TPPGPlanner;
  D0: TDate;
begin
  FForm.Show;
  P := TPPGPlanner.Create(FForm);
  P.Parent := FForm;
  P.SetBounds(0, 0, 380, 280);
  P.Animation.Enabled := False;
  P.View := pvMonth;
  P.Date := EncodeDate(2026, 6, 15);
  D0 := P.Date;
  TPlannerAccess(P).DoMouseWheel([], 40, Point(0, 0));
  TPlannerAccess(P).DoMouseWheel([], 40, Point(0, 0));
  CheckEquals(D0, P.Date, 0, 'Teil-Deltas');
  TPlannerAccess(P).DoMouseWheel([], 40, Point(0, 0));
  CheckEquals(6 - 1, MonthOf(P.Date), '3 x 40 = ein Monat zurueck');
end;

procedure TWheelTests.TileViewZoomOnePerNotch;
var
  V: TPPGTileView;
begin
  V := TPPGTileView.Create(FForm);
  V.Parent := FForm;
  V.SetBounds(0, 0, 300, 200);
  V.Items.Add('A');
  V.HandleNeeded;
  CheckEquals(100, V.Zoom);
  TTileAccess(V).DoMouseWheel([ssCtrl], 40, Point(0, 0));
  TTileAccess(V).DoMouseWheel([ssCtrl], 40, Point(0, 0));
  CheckEquals(100, V.Zoom, 'Teil-Deltas');
  TTileAccess(V).DoMouseWheel([ssCtrl], 40, Point(0, 0));
  CheckEquals(110, V.Zoom, '3 x 40 = eine Zoomstufe');
end;

procedure TWheelTests.PanelCollectsFineDeltas;

  function NewPanel: TPPGPanel;
  var
    E: TPPGEdit;
  begin
    Result := TPPGPanel.Create(FForm);
    Result.Parent := FForm;
    Result.SetBounds(0, 0, 200, 150);
    Result.AutoScroll := True;
    Result.VertScrollBar.Smooth := False;
    E := TPPGEdit.Create(FForm);
    E.Parent := Result;
    E.SetBounds(10, 600, 100, 24);
    Result.HandleNeeded;
  end;

var
  P1, P2: TPPGPanel;
  I: Integer;
begin
  FForm.Show;
  P1 := NewPanel;
  TPanelAccess(P1).DoMouseWheel([], -WHEEL_DELTA, Point(0, 0));
  CheckTrue(P1.ScrollPos.Y > 0);
  P2 := NewPanel;
  for I := 1 to WHEEL_DELTA do
    TPanelAccess(P2).DoMouseWheel([], -1, Point(0, 0));
  CheckEquals(P1.ScrollPos.Y, P2.ScrollPos.Y, '120 x 1 = eine Raste');
end;

{ TDateSegmentTests }

procedure TDateSegmentTests.TimeKindStepsSegmentAtCaret;
var
  D: TPPGDatePicker;
begin
  // Audit 09.10.2026, Paket 7c #6: im Uhrzeit-Modus aenderten die Pfeile immer
  // die Minute (Strg: Stunde), egal wo die Einfuegemarke stand.
  FForm.Show;
  D := NewPicker;
  D.DateTime := EncodeDateTime(2026, 10, 8, 14, 30, 0, 0);
  D.Kind := dtkTime;
  D.SetFocus;
  CheckEquals('14:30:00', D.Text);
  D.SelStart := 1;
  Key(D, VK_UP);
  CheckEquals(EncodeDateTime(2026, 10, 8, 15, 30, 0, 0), D.DateTime, 1E-8, 'Stunde unter der Marke');
  CheckEquals(1, D.SelStart, 'Marke bleibt im Teil');
  D.SelStart := 4;
  Key(D, VK_DOWN);
  CheckEquals(EncodeDateTime(2026, 10, 8, 15, 29, 0, 0), D.DateTime, 1E-8, 'Minute');
  D.SelStart := 7;
  Key(D, VK_UP);
  CheckEquals(EncodeDateTime(2026, 10, 8, 15, 29, 1, 0), D.DateTime, 1E-8, 'Sekunde');
  CheckEquals(3, FChanges);
end;

procedure TDateSegmentTests.DateTimeKindStepsDateOrTime;
var
  D: TPPGDatePicker;
begin
  FForm.Show;
  D := NewPicker;
  D.Kind := dtkDateTime;
  D.DateTime := EncodeDateTime(2026, 10, 8, 14, 30, 0, 0);
  D.SetFocus;
  CheckEquals('08.10.2026 14:30', D.Text);
  D.SelStart := 2;
  Key(D, VK_UP);
  CheckEquals(EncodeDateTime(2026, 10, 9, 14, 30, 0, 0), D.DateTime, 1E-8, 'Datumsteil: Tag');
  D.SelStart := 12;
  Key(D, VK_UP);
  CheckEquals(EncodeDateTime(2026, 10, 9, 15, 30, 0, 0), D.DateTime, 1E-8, 'Stunde');
  CheckEquals(12, D.SelStart, 'Marke bleibt');
  D.SelStart := 15;
  Key(D, VK_DOWN);
  CheckEquals(EncodeDateTime(2026, 10, 9, 15, 29, 0, 0), D.DateTime, 1E-8, 'Minute');
end;

procedure TDateSegmentTests.WheelStepsSegment;
var
  D: TPPGDatePicker;
  E: TPPGEdit;
begin
  FForm.Show;
  E := TPPGEdit.Create(FForm);
  E.Parent := FForm;
  E.SetBounds(10, 200, 100, 24);
  D := NewPicker;
  D.DateTime := EncodeDateTime(2026, 10, 8, 14, 30, 0, 0);
  D.Kind := dtkTime;
  E.SetFocus;
  CheckFalse(TDateAccess(D).DoMouseWheel([], WHEEL_DELTA, Point(0, 0)), 'ohne Fokus an den Elternteil');
  D.SetFocus;
  D.SelStart := 4;
  TDateAccess(D).DoMouseWheel([], 40, Point(0, 0));
  TDateAccess(D).DoMouseWheel([], 40, Point(0, 0));
  CheckEquals(EncodeDateTime(2026, 10, 8, 14, 30, 0, 0), D.DateTime, 1E-8, 'Teil-Deltas');
  CheckTrue(TDateAccess(D).DoMouseWheel([], 40, Point(0, 0)));
  CheckEquals(EncodeDateTime(2026, 10, 8, 14, 31, 0, 0), D.DateTime, 1E-8, 'Rad auf der Minute');
  D.Kind := dtkDate;
  D.SetFocus;
  TDateAccess(D).DoMouseWheel([], -WHEEL_DELTA, Point(0, 0));
  CheckEquals(EncodeDate(2026, 10, 7), D.Date, 0, 'Datum: Rad = Tag');
end;

initialization
  RegisterTest('Audit7A', TDatePickerPinTests.Suite);
  RegisterTest('Audit7A', TDropDownFieldTests.Suite);
  RegisterTest('Audit7A', TWheelTests.Suite);
  RegisterTest('Audit7A', TDateSegmentTests.Suite);

end.
