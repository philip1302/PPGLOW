unit DemoShowCheckBox;

// Komponentenseite TPPGCheckBox (Gruppe "Auswahl"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten der
// CheckBox (Zustand im Protokoll, Kategorien) und die beiden
// Praxisbeispiele (ExCheckBoxOrder, ExCheckBoxRights).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls,
  PPG.CheckBox, DemoKit, DemoShowcase, ExCheckBoxOrder, ExCheckBoxRights;

type
  TDemoShowCheckBoxPage = class(TDemoComponentPage)
  private
    FOrder: TOrderCheckout;
    FRights: TRoleRights;
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

function StateName(AState: TCheckBoxState): string;
begin
  case AState of
    cbChecked: Result := 'cbChecked';
    cbGrayed: Result := 'cbGrayed';
  else
    Result := 'cbUnchecked';
  end;
end;

function TDemoShowCheckBoxPage.SubjectClass: TComponentClass;
begin
  Result := TPPGCheckBox;
end;

procedure TDemoShowCheckBoxPage.SetupSubject(ASubject: TComponent);
begin
  inherited SetupSubject(ASubject);
  // Etwas breiter als die Vorgabe (140), damit auch laengere Texte aus dem
  // Inspektor ohne AutoSize lesbar bleiben
  if ASubject is TPPGCheckBox then
    TPPGCheckBox(ASubject).Width := 220;
end;

procedure TDemoShowCheckBoxPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'State') then
    ACategory := 'Inhalt'
  else if SameText(AName, 'AllowGrayed') then
    ACategory := 'Verhalten';
end;

procedure TDemoShowCheckBoxPage.EventOccurred(const AName, ADetail: string);
var
  Detail: string;
begin
  Detail := ADetail;
  // Neuer Zustand im Protokoll: OnChange kommt bei jeder Aenderung (auch aus
  // dem Inspektor), OnClick nur bei Bedienung
  if ((AName = 'OnChange') or (AName = 'OnClick')) and (Subject is TPPGCheckBox) then
    Detail := 'State = ' + StateName(TPPGCheckBox(Subject).State);
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowCheckBoxPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Bestellabschluss', 'ExCheckBoxOrder',
    'Der Abschluss einer Bestellung: <b>Checked</b> ist vorbelegt (Lieferadresse wie '
    + 'Rechnungsadresse), <b>OnChange</b> gibt das Adressfeld frei bzw. schaltet den Button frei, '
    + 'der lange AGB-Text bricht mit <b>WordWrap</b> um. Probieren Sie: Lieferadresse abhaken, '
    + 'dann versuchen abzusenden, zuletzt die AGB anhaken (auch per Alt+A oder Leertaste).');
  FOrder := TOrderCheckout.CreateCheckout(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Benutzerrechte', 'ExCheckBoxRights',
    'Freigaben einer Rolle: {Ue}ber den Modulen steht <b>Alle Module</b>. Es zeigt <b>State</b> '
    + '= cbGrayed, wenn nur ein Teil freigegeben ist. Sein <b>OnClick</b> (nur Bedienung) schaltet '
    + 'alle Module, deren <b>OnChange</b> (jede {Ae}nderung) rechnet den Zustand neu. Probieren '
    + 'Sie: einzelne Module an- und abhaken, dann zweimal auf Alle Module klicken.');
  FRights := TRoleRights.CreateRights(Own, V.Live, DemoStyles);
end;

procedure TDemoShowCheckBoxPage.SelfTest(Check: TDemoCheck);
var
  Box: TPPGCheckBox;
  I: Integer;
  AllOn: Boolean;
begin
  inherited SelfTest(Check);
  // Buehne: Klick meldet OnChange und OnClick, Setzen im Inspektor nur OnChange
  ResetSubject;
  Box := TPPGCheckBox(Subject);
  Box.Click;
  Check('TPPGCheckBox: Klick auf der B' + #$00FC + 'hne hakt an und meldet OnChange und OnClick',
    Box.Checked and (EventList.Items.Count >= 2) and (Pos('OnClick', EventList.Items[0]) > 0) and
    (Pos('OnChange', EventList.Items[1]) > 0) and (Pos('cbChecked', EventList.Items[0]) > 0));
  EventList.Items.Clear;
  Inspector.SetValueText('State', 'cbGrayed');
  Check('TPPGCheckBox: State im Inspektor meldet nur OnChange (kein OnClick)',
    (Box.State = cbGrayed) and (EventList.Items.Count = 1) and
    (Pos('OnChange', EventList.Items[0]) > 0) and (Pos('cbGrayed', EventList.Items[0]) > 0));
  Box.Click;
  Check('TPPGCheckBox: Klick aus cbGrayed f' + #$00FC + 'hrt zu cbChecked', Box.State = cbChecked);
  ResetSubject;
  Box := TPPGCheckBox(Subject);
  Inspector.SetValueText('AllowGrayed', 'True');
  Box.Click;
  Check('TPPGCheckBox: mit AllowGrayed f' + #$00FC + 'hrt der Klick aus cbUnchecked zu cbGrayed',
    Box.State = cbGrayed);
  ResetSubject;

  // Praxisbeispiel 1: Bestellabschluss
  Check('Beispiel Bestellung: Lieferadresse vorbelegt, Adressfeld und Absenden gesperrt',
    FOrder.SameAddress.Checked and not FOrder.DeliveryEdit.Enabled and
    not FOrder.SubmitButton.Enabled);
  FOrder.SameAddress.Click;
  Check('Beispiel Bestellung: Lieferadresse abgehakt gibt das Adressfeld frei',
    (not FOrder.SameAddress.Checked) and FOrder.DeliveryEdit.Enabled);
  FOrder.DeliveryEdit.Text := 'Lager Nord';
  FOrder.Terms.Click;
  Check('Beispiel Bestellung: AGB angehakt gibt Absenden frei', FOrder.SubmitButton.Enabled);
  FOrder.Newsletter.Checked := True;
  FOrder.SubmitButton.Click;
  Check('Beispiel Bestellung: Absenden meldet abweichende Adresse und Newsletter',
    (Pos('Lager Nord', FOrder.Status.Caption) > 0) and
    (Pos('mit Newsletter', FOrder.Status.Caption) > 0));
  FOrder.Terms.Checked := False;
  Check('Beispiel Bestellung: AGB im Code abgehakt sperrt Absenden wieder (OnChange)',
    not FOrder.SubmitButton.Enabled);
  // Ausgangszustand wiederherstellen
  FOrder.Newsletter.Checked := False;
  FOrder.DeliveryEdit.Text := '';
  FOrder.SameAddress.Checked := True;
  FOrder.Status.Caption := 'Noch nicht abgeschickt.';

  // Praxisbeispiel 2: Benutzerrechte
  Check('Beispiel Rechte: ein Modul vorbelegt, Alle Module = cbGrayed',
    FRights.Modules[0].Checked and (FRights.All.State = cbGrayed) and
    (Pos('1 von 4', FRights.Summary.Caption) > 0));
  FRights.All.Click;
  AllOn := True;
  for I := 0 to ModuleCount - 1 do
    AllOn := AllOn and FRights.Modules[I].Checked;
  Check('Beispiel Rechte: Klick auf Alle Module (teilweise) schaltet alle an',
    AllOn and (FRights.All.State = cbChecked) and (Pos('4 von 4', FRights.Summary.Caption) > 0));
  FRights.All.Click;
  AllOn := False;
  for I := 0 to ModuleCount - 1 do
    AllOn := AllOn or FRights.Modules[I].Checked;
  Check('Beispiel Rechte: zweiter Klick schaltet alle aus',
    (not AllOn) and (FRights.All.State = cbUnchecked));
  FRights.Modules[2].Click;
  Check('Beispiel Rechte: ein Modul angehakt macht Alle Module teilweise (cbGrayed)',
    FRights.All.State = cbGrayed);
  for I := 0 to ModuleCount - 1 do
    FRights.Modules[I].Checked := True;
  Check('Beispiel Rechte: alle Module einzeln angehakt ergibt cbChecked',
    FRights.All.State = cbChecked);
  // Ausgangszustand wiederherstellen
  for I := 0 to ModuleCount - 1 do
    FRights.Modules[I].Checked := I = 0;
end;

initialization
  RegisterShowcasePage('TPPGCheckBox', TDemoShowCheckBoxPage);

end.
