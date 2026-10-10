unit DemoShowToggleSwitch;

// Komponentenseite TPPGToggleSwitch (Gruppe "Auswahl"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten des
// Schalters (Beschriftung auf der Buehne, Zustand im Protokoll) und die beiden
// Praxisbeispiele (ExToggleSwitchSettings, ExToggleSwitchFilter).

interface

uses
  System.SysUtils, System.Classes,
  PPG.ToggleSwitch, DemoKit, DemoShowcase, ExToggleSwitchSettings, ExToggleSwitchFilter;

type
  TDemoShowToggleSwitchPage = class(TDemoComponentPage)
  private
    FSettings: TNotifySettings;
    FFilter: TOrderFilter;
  protected
    function SubjectClass: TComponentClass; override;
    procedure SetupSubject(ASubject: TComponent); override;
    procedure BuildExamples; override;
    procedure EventOccurred(const AName, ADetail: string); override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

function TDemoShowToggleSwitchPage.SubjectClass: TComponentClass;
begin
  Result := TPPGToggleSwitch;
end;

procedure TDemoShowToggleSwitchPage.SetupSubject(ASubject: TComponent);
begin
  inherited SetupSubject(ASubject);
  // Eine typische Einstellung statt des Komponentennamens; breit genug,
  // damit Alignment und Spacing sichtbar wirken
  TPPGToggleSwitch(ASubject).Caption := L('Automatisch &speichern');
  TPPGToggleSwitch(ASubject).Width := 240;
end;

procedure TDemoShowToggleSwitchPage.EventOccurred(const AName, ADetail: string);
var
  Detail: string;
begin
  Detail := ADetail;
  if Subject is TPPGToggleSwitch then
  begin
    if AName = 'OnChange' then
      Detail := Format('Checked = %s', [BoolToStr(TPPGToggleSwitch(Subject).Checked, True)])
    else if AName = 'OnClick' then
      Detail := L('vom Anwender umgeschaltet (Checked = ') +
        BoolToStr(TPPGToggleSwitch(Subject).Checked, True) + ')';
  end;
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowToggleSwitchPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Einstellungen', 'ExToggleSwitchSettings',
    'Eine Einstellungsseite wie in Windows: Text links, Schalter rechts (<b>Alignment = '
    + 'taLeftJustify</b>). Der Hauptschalter <b>Benachrichtigungen</b> sperrt in <b>OnChange</b> '
    + 'die drei abh{ae}ngigen Schalter (<b>Enabled</b>), ihre Werte bleiben erhalten. Probieren Sie: '
    + 'Hauptschalter aus und wieder ein, dann einzelne Benachrichtigungen per Maus oder mit Tab '
    + 'und Leertaste umschalten.');
  FSettings := TNotifySettings.CreateSettings(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Listenfilter', 'ExToggleSwitchFilter',
    'Zwei Filter-Schalter {ue}ber einer Auftragsliste. <b>OnChange</b> filtert bei jeder '
    + '{Ae}nderung, <b>OnClick</b> meldet nur die Bedienung durch den Anwender. Probieren Sie: '
    + '"Nur offene" und "Nur meine" einschalten (die Zeile unten z{ae}hlt mit), dann '
    + '"Filter zur{ue}cksetzen" {-} die Liste ist wieder vollst{ae}ndig, der Z{ae}hler bleibt, '
    + 'weil <b>Checked := False</b> im Code kein OnClick ausl{oe}st.');
  FFilter := TOrderFilter.CreateFilter(Own, V.Live, DemoStyles);
end;

procedure TDemoShowToggleSwitchPage.SelfTest(Check: TDemoCheck);
var
  Sw: TPPGToggleSwitch;
begin
  inherited SelfTest(Check);
  // Buehne: Klick schaltet um und meldet OnChange und OnClick; Setzen im
  // Code meldet nur OnChange
  ResetSubject;
  Sw := TPPGToggleSwitch(Subject);
  Sw.Click;
  Check('TPPGToggleSwitch: Klick schaltet ein und meldet OnClick nach OnChange',
    Sw.Checked and (EventList.Items.Count >= 2) and (Pos('OnClick', EventList.Items[0]) > 0) and
    (Pos('OnChange', EventList.Items[1]) > 0));
  Sw.Checked := False;
  Check('TPPGToggleSwitch: Checked := False im Code meldet nur OnChange',
    (not Sw.Checked) and (Pos('OnChange', EventList.Items[0]) > 0) and
    (Pos('Checked = False', EventList.Items[0]) > 0));
  ResetSubject;

  // Praxisbeispiel 1: Hauptschalter sperrt die abhaengigen Schalter
  Check('Beispiel Einstellungen: Ausgangszustand 2 von 3 aktiv, alle frei',
    (FSettings.ActiveCount = 2) and FSettings.Sound.Enabled and
    (Pos('2 von 3', FSettings.Status.Caption) > 0));
  FSettings.Notify.Click;
  Check('Beispiel Einstellungen: Hauptschalter aus sperrt die drei Schalter',
    (not FSettings.Notify.Checked) and (not FSettings.NewOrders.Enabled) and
    (not FSettings.DailySummary.Enabled) and (not FSettings.Sound.Enabled) and
    (FSettings.ActiveCount = 0) and (Pos('ausgeschaltet', FSettings.Status.Caption) > 0));
  FSettings.Notify.Click;
  Check('Beispiel Einstellungen: Hauptschalter an gibt frei, Werte bleiben erhalten',
    FSettings.NewOrders.Enabled and FSettings.NewOrders.Checked and FSettings.Sound.Checked and
    (not FSettings.DailySummary.Checked) and (FSettings.ActiveCount = 2));
  FSettings.DailySummary.Click;
  Check('Beispiel Einstellungen: Zusammenfassung an ergibt 3 von 3',
    (FSettings.ActiveCount = 3) and (Pos('3 von 3', FSettings.Status.Caption) > 0));
  FSettings.DailySummary.Click;

  // Praxisbeispiel 2: Filter per OnChange, Zaehler nur per OnClick
  Check('Beispiel Listenfilter: ohne Filter alle 6 Auftr' + #$00E4 + 'ge',
    FFilter.List.Items.Count = 6);
  FFilter.OnlyOpen.Click;
  Check('Beispiel Listenfilter: "Nur offene" zeigt 4, Anwender-Z' + #$00E4 + 'hler 1',
    (FFilter.List.Items.Count = 4) and (FFilter.UserChanges = 1));
  FFilter.OnlyMine.Click;
  Check('Beispiel Listenfilter: dazu "Nur meine" zeigt 2, Anwender-Z' + #$00E4 + 'hler 2',
    (FFilter.List.Items.Count = 2) and (FFilter.UserChanges = 2));
  FFilter.ResetButton.Click;
  Check('Beispiel Listenfilter: Zur' + #$00FC + 'cksetzen im Code filtert neu (OnChange), ' +
    'z' + #$00E4 + 'hlt aber nicht (kein OnClick)',
    (not FFilter.OnlyOpen.Checked) and (not FFilter.OnlyMine.Checked) and
    (FFilter.List.Items.Count = 6) and (FFilter.UserChanges = 2));
end;

initialization
  RegisterShowcasePage('TPPGToggleSwitch', TDemoShowToggleSwitchPage);

end.
