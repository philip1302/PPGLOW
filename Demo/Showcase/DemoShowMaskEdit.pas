unit DemoShowMaskEdit;

// Komponentenseite TPPGMaskEdit (Gruppe "Eingabe"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten des
// Maskenfelds (Datumsmaske auf der Buehne, Zusatzinfo im Protokoll, eigene
// Kategorien) und die beiden Praxisbeispiele (ExMaskEditCustomer,
// ExMaskEditTimeEntry).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.Controls.Field, PPG.MaskEdit, DemoKit, DemoShowcase, ExMaskEditCustomer, ExMaskEditTimeEntry;

type
  TDemoShowMaskEditPage = class(TDemoComponentPage)
  private
    FCustomer: TCustomerForm;
    FTime: TTimeEntry;
    procedure CheckCustomer(Check: TDemoCheck);
    procedure CheckTimeEntry(Check: TDemoCheck);
  protected
    function SubjectClass: TComponentClass; override;
    procedure SetupSubject(ASubject: TComponent); override;
    procedure BuildExamples; override;
    procedure CategoryFor(Sender: TObject; const AName: string; var ACategory: string); override;
    procedure EventOccurred(const AName, ADetail: string); override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

function TDemoShowMaskEditPage.SubjectClass: TComponentClass;
begin
  Result := TPPGMaskEdit;
end;

procedure TDemoShowMaskEditPage.SetupSubject(ASubject: TComponent);
begin
  inherited SetupSubject(ASubject);
  // Sofort sichtbar: eine Datumsmaske mit Platzhaltern
  TPPGMaskEdit(ASubject).Width := 160;
  TPPGMaskEdit(ASubject).EditMask := '00.00.0000;1;_';
end;

procedure TDemoShowMaskEditPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if (AName = 'EditMask') or (AName = 'Text') or (AName = 'MaxLength') or
    (AName = 'CharCase') or (AName = 'PasswordChar') then
    ACategory := 'Inhalt'
  else if (AName = 'ValidationState') or (AName = 'ValidationHint') or
    (AName = 'ShowClearButton') or (AName = 'UseSystemContextMenu') then
    ACategory := 'Verhalten'
  else if (AName = 'TextHintVisibleOnFocus') then
    ACategory := 'Beschriftung & Bild'
  else if (AName = 'AutoSelect') or (AName = 'HideSelection') then
    ACategory := 'Tastatur & Fokus'
  else if AName = 'BorderStyle' then
    ACategory := 'Darstellung (VCL)';
end;

procedure TDemoShowMaskEditPage.EventOccurred(const AName, ADetail: string);
var
  Detail: string;
  M: TPPGMaskEdit;
begin
  Detail := ADetail;
  if Subject is TPPGMaskEdit then
  begin
    M := TPPGMaskEdit(Subject);
    if AName = 'OnChange' then
      Detail := Format('Text = "%s", EditText = "%s"', [M.Text, M.EditText])
    else if AName = 'OnValidationError' then
      Detail := Format('InvalidPos = %d, ValidationState = pvsError', [M.InvalidPos]);
  end;
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowMaskEditPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Kundendaten', 'ExMaskEditCustomer',
    'Kundennummer, PLZ und IBAN mit je einer <b>EditMask</b>: "KD-" steht fest im Feld und wird '
    + 'mit gespeichert (;1;), die PLZ nimmt nur Ziffern, die IBAN wird per ">" gro{ss} geschrieben. '
    + '<b>Speichern</b> pr{ue}ft mit <b>IsEmpty</b> (Pflichtfelder) und <b>ValidateInput</b>; Fehler '
    + 'zeigt <b>ValidationState</b> rot mit <b>ValidationHint</b>, <b>OnValidationError</b> meldet die '
    + 'Stelle. Probieren Sie: leer speichern, dann nur "123" als PLZ, zuletzt alles vollst{ae}ndig.');
  FCustomer := TCustomerForm.CreateForm(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Arbeitszeit buchen', 'ExMaskEditTimeEntry',
    'Datum, Beginn und Ende mit Masken, die Punkt und Doppelpunkt mitliefern ("08:30"). '
    + '<b>OnChange</b> rechnet die Dauer, sobald beide Uhrzeiten vollst{ae}ndig sind. Was die Maske '
    + 'nicht pr{ue}ft, pr{ue}ft das Beispiel selbst: "25:00" wird rot (<b>pvsError</b>), ein Ende vor '
    + 'dem Beginn gelb (<b>pvsWarning</b>), jeweils mit <b>ValidationHint</b> als Tooltip.');
  FTime := TTimeEntry.CreateEntry(Own, V.Live, DemoStyles);
end;

procedure TDemoShowMaskEditPage.CheckCustomer(Check: TDemoCheck);
var
  C: TCustomerForm;
begin
  C := FCustomer;
  C.SaveButton.Click;
  Check(L('Beispiel Kundendaten: leer speichern markiert die Pflichtfelder rot, IBAN bleibt neutral'),
    (not C.Saved) and (C.CustomerNo.ValidationState = pvsError) and
    (C.CustomerNo.ValidationHint = 'Pflichtfeld') and (C.Zip.ValidationState = pvsError) and
    (C.Iban.ValidationState = pvsNone));

  C.CustomerNo.EditText := 'KD-123456';
  Check(L('Beispiel Kundendaten: neue Eingabe (OnChange) nimmt die Markierung zur{ue}ck'),
    C.CustomerNo.ValidationState = pvsNone);
  C.Zip.EditText := '123__';
  C.SaveButton.Click;
  Check(L('Beispiel Kundendaten: PLZ "123" ist unvollst{ae}ndig (ValidateInput, OnValidationError, InvalidPos = 3)'),
    (not C.Saved) and (C.Zip.ValidationState = pvsError) and (C.LastInvalid = C.Zip) and
    (C.Zip.InvalidPos = 3) and (C.CustomerNo.ValidationState = pvsNone));

  C.Zip.EditText := '12345';
  C.Iban.EditText := 'DE89 3704 0044 0532 0130 00';
  C.SaveButton.Click;
  Check(L('Beispiel Kundendaten: vollst{ae}ndig gespeichert, Kundennummer mit festem "KD-"'),
    C.Saved and (C.Zip.ValidationState = pvsNone) and (C.CustomerNo.Text = 'KD-123456') and
    (C.Zip.Text = '12345') and (Pos('PLZ 12345', C.Status.Caption) > 0) and
    (Pos('DE89 3704', C.Status.Caption) > 0));
end;

procedure TDemoShowMaskEditPage.CheckTimeEntry(Check: TDemoCheck);
var
  T: TTimeEntry;
begin
  T := FTime;
  Check(L('Beispiel Arbeitszeit: Datum ist mit heute vorbelegt'),
    T.DateEdit.Text = FormatDateTime('dd"."mm"."yyyy', Date));
  T.StartEdit.Text := '08:00';
  T.EndEdit.Text := '16:30';
  Check(L('Beispiel Arbeitszeit: 08:00 bis 16:30 ergibt 8:30 Std. (OnChange)'),
    (T.Minutes = 510) and (Pos('8:30', T.Duration.Caption) > 0) and
    (T.EndEdit.ValidationState = pvsNone));
  T.EndEdit.Text := '07:15';
  Check(L('Beispiel Arbeitszeit: Ende vor Beginn wird gelb (pvsWarning) mit Hinweis'),
    (T.Minutes = -1) and (T.EndEdit.ValidationState = pvsWarning) and (T.EndEdit.ValidationHint <> ''));
  T.StartEdit.Text := '25:00';
  Check(L('Beispiel Arbeitszeit: 25:00 ist keine Uhrzeit (pvsError)'),
    (T.Minutes = -1) and (T.StartEdit.ValidationState = pvsError));
  T.StartEdit.Text := '08:00';
  T.EndEdit.EditText := '16:__';
  Check(L('Beispiel Arbeitszeit: unvollst{ae}ndiges Ende rechnet nicht und markiert nichts'),
    (T.Minutes = -1) and (T.EndEdit.ValidationState = pvsNone) and
    (T.StartEdit.ValidationState = pvsNone));
end;

procedure TDemoShowMaskEditPage.SelfTest(Check: TDemoCheck);
var
  M: TPPGMaskEdit;
begin
  inherited SelfTest(Check);
  // Buehne: Eingabe erscheint mit Text und EditText im Protokoll
  ResetSubject;
  M := TPPGMaskEdit(Subject);
  M.EditText := '09.10.2026';
  Check(L('TPPGMaskEdit: Eingabe auf der B{ue}hne erscheint mit Text im Ereignis-Protokoll'),
    (EventList.Items.Count > 0) and (Pos('OnChange', EventList.Items[0]) > 0) and
    (Pos('09.10.2026', EventList.Items[0]) > 0));
  M.EditText := '09.1_.2026';
  M.ValidateInput;
  Check(L('TPPGMaskEdit: ValidateInput meldet OnValidationError mit InvalidPos im Protokoll'),
    (M.ValidationState = pvsError) and (Pos('OnValidationError', EventList.Items[0]) > 0) and
    (Pos('InvalidPos = 4', EventList.Items[0]) > 0));

  CheckCustomer(Check);
  CheckTimeEntry(Check);
end;

initialization
  RegisterShowcasePage('TPPGMaskEdit', TDemoShowMaskEditPage);

end.
