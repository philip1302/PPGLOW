unit DemoShowCheckComboBox;

// Komponentenseite TPPGCheckComboBox (Gruppe "Auswahl"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten der
// CheckComboBox (Eintraege auf der Buehne, OnItemCheck mit eigener Signatur
// im Protokoll) und die beiden Praxisbeispiele (ExCheckComboBoxFilter,
// ExCheckComboBoxSettings).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.CheckComboBox, DemoKit, DemoShowcase, ExCheckComboBoxFilter, ExCheckComboBoxSettings;

type
  TDemoShowCheckComboBoxPage = class(TDemoComponentPage)
  private
    FFilter: TCustomerFilter;
    FSettings: TReportSettings;
    procedure SubjectItemCheck(Sender: TObject; Index: Integer);
  protected
    function SubjectClass: TComponentClass; override;
    procedure SetupSubject(ASubject: TComponent); override;
    procedure CategoryFor(Sender: TObject; const AName: string; var ACategory: string); override;
    procedure BuildExamples; override;
    procedure EventOccurred(const AName, ADetail: string); override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

uses
  PPG.Controls.Field;

function TDemoShowCheckComboBoxPage.SubjectClass: TComponentClass;
begin
  Result := TPPGCheckComboBox;
end;

procedure TDemoShowCheckComboBoxPage.SetupSubject(ASubject: TComponent);
var
  Combo: TPPGCheckComboBox;
begin
  inherited SetupSubject(ASubject);
  // Mit Eintraegen und zwei Haken sieht man sofort Anzeige und Liste
  Combo := ASubject as TPPGCheckComboBox;
  Combo.Width := 280;
  Combo.Items.CommaText := 'Vertrieb,Einkauf,Lager,Buchhaltung,Personal,IT,Marketing';
  Combo.CheckedText := 'Vertrieb;Lager';
  Combo.TextHint := L('Abteilungen w{ae}hlen');
  // Eigene Signatur (Sender, Index): wird nicht automatisch protokolliert
  Combo.OnItemCheck := SubjectItemCheck;
end;

procedure TDemoShowCheckComboBoxPage.SubjectItemCheck(Sender: TObject; Index: Integer);
var
  Combo: TPPGCheckComboBox;
begin
  Combo := Sender as TPPGCheckComboBox;
  if (Index >= 0) and (Index < Combo.Items.Count) then
    LogEvent('OnItemCheck', Format('Index = %d (%s), Checked = %s',
      [Index, Combo.Items[Index], BoolToStr(Combo.Checked[Index], True)]))
  else
    LogEvent('OnItemCheck', Format('Index = %d', [Index]));
end;

procedure TDemoShowCheckComboBoxPage.EventOccurred(const AName, ADetail: string);
var
  Detail: string;
begin
  Detail := ADetail;
  if ((AName = 'OnChange') or (AName = 'OnClick')) and (Subject is TPPGCheckComboBox) then
    Detail := 'CheckedText = ''' + TPPGCheckComboBox(Subject).CheckedText + '''';
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowCheckComboBoxPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'CheckedText') then
    ACategory := 'Inhalt'
  else if SameText(AName, 'Delimiter') then
    ACategory := 'Daten'
  else if SameText(AName, 'DisplayMode') or SameText(AName, 'DisplayDelimiter') or
    SameText(AName, 'MaxDisplayItems') then
    ACategory := 'Beschriftung & Bild'
  else if SameText(AName, 'ShowSelectAll') or SameText(AName, 'FilterThreshold') or
    SameText(AName, 'DropDownCount') then
    ACategory := 'Verhalten'
  else if SameText(AName, 'ValidationState') or SameText(AName, 'ValidationHint') then
    ACategory := 'Hinweise & Hilfe';
end;

procedure TDemoShowCheckComboBoxPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Kundenliste filtern', 'ExCheckComboBoxFilter',
    'Zwei Mehrfachfilter {ue}ber einer Kundenliste. <b>Status</b> hat "Alle ausw{ae}hlen" '
    + '(<b>ShowSelectAll</b>), <b>Region</b> hat viele Eintr{ae}ge und deshalb eine Filterzeile '
    + '(<b>FilterThreshold</b>) und zeigt nur die Anzahl (<b>DisplayMode</b> = cdmCount). '
    + 'Jeder Haken filtert sofort (<b>OnChange</b>), ohne Haken gilt ein Filter als "alle" '
    + '(<b>TextHint</b>). Probieren Sie: Status aufklappen und "Aktiv" anhaken, dann in Region '
    + '"ba" tippen und Bayern anhaken, zuletzt "Alle anzeigen".');
  FFilter := TCustomerFilter.CreateFilter(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Einstellung Berichtstage', 'ExCheckComboBoxSettings',
    'Eine Einstellung "Wochenbericht senden am": Die Auswahl wird als <b>CheckedText</b> mit '
    + '<b>Delimiter</b> = "," gespeichert und geladen. <b>OnItemCheck</b> pr{ue}ft die Eingabe: '
    + 'Ohne Tag zeigt <b>ValidationState</b> einen Fehler und Speichern ist gesperrt. '
    + '<b>MaxDisplayItems</b> = 3 k{ue}rzt die Anzeige. Probieren Sie: alle Tage abhaken, '
    + 'Dienstag anhaken und speichern, dann etwas {ae}ndern und "Verwerfen".');
  FSettings := TReportSettings.CreateSettings(Own, V.Live, DemoStyles);
end;

procedure TDemoShowCheckComboBoxPage.SelfTest(Check: TDemoCheck);
const
  P = 'TPPGCheckComboBox: ';
var
  Combo: TPPGCheckComboBox;
  Before: Integer;
begin
  inherited SelfTest(Check);

  // Buehne: Anwender-Haken melden OnItemCheck und OnChange, Code nicht
  ResetSubject;
  Combo := TPPGCheckComboBox(Subject);
  Check(P + 'B' + #$00FC + 'hne mit Eintr' + #$00E4 + 'gen und zwei Haken',
    (Combo.Items.Count = 7) and (Combo.CheckedText = 'Vertrieb;Lager'));
  Combo.ToggleItem(1);
  Check(P + 'Haken durch den Anwender: OnItemCheck und OnChange im Protokoll',
    (EventList.Items.Count >= 2) and (Pos('OnChange', EventList.Items[0]) > 0) and
    (Pos('OnItemCheck', EventList.Items.Text) > 0) and (Pos('Einkauf', EventList.Items.Text) > 0));
  Before := EventList.Items.Count;
  Combo.Checked[3] := True;
  Combo.CheckedText := 'IT';
  Check(P + 'Checked[] und CheckedText aus Code l' + #$00F6 + 'sen keine Ereignisse aus',
    (EventList.Items.Count = Before) and (Combo.CheckedCount = 1));
  Inspector.SetValueText('DisplayMode', 'cdmCount');
  Check(P + 'DisplayMode = cdmCount zeigt die Anzahl', Pos('1', Combo.DisplayText) > 0);
  ResetSubject;

  // Praxisbeispiel 1: Filter
  FFilter.ResetButton.Click;
  Check('Beispiel Filter: ohne Haken alle 10 Kunden, "Alle anzeigen" gesperrt',
    (FFilter.CustomerList.Items.Count = 10) and not FFilter.ResetButton.Enabled);
  FFilter.StatusFilter.ToggleItem(FFilter.StatusFilter.Items.IndexOf('Aktiv'));
  Check('Beispiel Filter: Status Aktiv zeigt 4 Kunden',
    (FFilter.CustomerList.Items.Count = 4) and FFilter.ResetButton.Enabled);
  FFilter.RegionFilter.ToggleItem(FFilter.RegionFilter.Items.IndexOf('Bayern'));
  Check('Beispiel Filter: Aktiv und Bayern zeigt nur Albers GmbH',
    (FFilter.CustomerList.Items.Count = 1) and
    (Pos('Albers', FFilter.CustomerList.Items[0]) = 1));
  FFilter.StatusFilter.UserCheckAll(True);
  Check('Beispiel Filter: "Alle ausw' + #$00E4 + 'hlen" bei Status zeigt alle 3 Kunden in Bayern',
    FFilter.StatusFilter.AllChecked and (FFilter.CustomerList.Items.Count = 3));
  Check('Beispiel Filter: Region mit Filterzeile (Eintr' + #$00E4 + 'ge >= FilterThreshold), Anzeige als Anzahl',
    (FFilter.RegionFilter.Items.Count >= FFilter.RegionFilter.FilterThreshold) and
    (FFilter.RegionFilter.DisplayMode = cdmCount));
  FFilter.ResetButton.Click;
  Check('Beispiel Filter: "Alle anzeigen" l' + #$00F6 + 'scht beide Filter',
    (FFilter.StatusFilter.CheckedCount = 0) and (FFilter.RegionFilter.CheckedCount = 0) and
    (FFilter.CustomerList.Items.Count = 10));

  // Praxisbeispiel 2: Einstellung speichern, pruefen, verwerfen
  FSettings.Settings.Values['Berichtstage'] := 'Montag,Mittwoch,Freitag';
  FSettings.LoadSettings;
  Check('Beispiel Einstellung: geladen aus "Montag,Mittwoch,Freitag"',
    (FSettings.Days.CheckedCount = 3) and (FSettings.Days.CheckedText = 'Montag,Mittwoch,Freitag') and
    (FSettings.Days.DisplayText = 'Montag, Mittwoch, Freitag') and FSettings.SaveButton.Enabled);
  FSettings.Days.ToggleItem(0);
  FSettings.Days.ToggleItem(2);
  FSettings.Days.ToggleItem(4);
  Check('Beispiel Einstellung: ohne Tag Fehler (ValidationState) und Speichern gesperrt',
    (FSettings.Days.ValidationState = pvsError) and not FSettings.SaveButton.Enabled);
  FSettings.Days.ToggleItem(1);
  Check('Beispiel Einstellung: mit Dienstag wieder g' + #$00FC + 'ltig',
    (FSettings.Days.ValidationState = pvsNone) and FSettings.SaveButton.Enabled);
  FSettings.SaveButton.Click;
  Check('Beispiel Einstellung: Speichern schreibt CheckedText in die Einstellungen',
    FSettings.Settings.Values['Berichtstage'] = 'Dienstag');
  FSettings.Days.ToggleItem(3);
  FSettings.Days.ToggleItem(5);
  FSettings.Days.ToggleItem(6);
  FSettings.Days.ToggleItem(0);
  Check('Beispiel Einstellung: MaxDisplayItems = 3 k' + #$00FC + 'rzt auf "+2"',
    FSettings.Days.DisplayText = 'Montag, Dienstag, Donnerstag, +2');
  FSettings.DiscardButton.Click;
  Check('Beispiel Einstellung: Verwerfen l' + #$00E4 + 'dt den gespeicherten Stand',
    FSettings.Days.CheckedText = 'Dienstag');
  FSettings.Settings.Values['Berichtstage'] := 'Montag,Mittwoch,Freitag';
  FSettings.LoadSettings;
end;

initialization
  RegisterShowcasePage('TPPGCheckComboBox', TDemoShowCheckComboBoxPage);

end.
