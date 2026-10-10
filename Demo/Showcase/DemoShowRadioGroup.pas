unit DemoShowRadioGroup;

// Komponentenseite TPPGRadioGroup (Gruppe "Auswahl"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten der
// Optionsgruppe (Eintraege auf der Buehne, Kategorien, Auswahl im Protokoll)
// und die beiden Praxisbeispiele (ExRadioGroupShipping, ExRadioGroupSubscription).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.Controls.Field, PPG.RadioGroup, DemoKit, DemoInspector, DemoShowcase,
  ExRadioGroupShipping, ExRadioGroupSubscription;

type
  TDemoShowRadioGroupPage = class(TDemoComponentPage)
  private
    FShipping: TShippingChoice;
    FSettings: TSubscriptionSettings;
  protected
    function SubjectClass: TComponentClass; override;
    procedure SetupSubject(ASubject: TComponent); override;
    procedure BuildExamples; override;
    procedure CategoryFor(Sender: TObject; const AName: string; var ACategory: string); override;
    function SkipInRoundTrip(Node: TDemoPropNode; var AReason: string): Boolean; override;
    procedure EventOccurred(const AName, ADetail: string); override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

type
  // Zugriff auf ActivateItem (geschuetzt): waehlt einen Eintrag wie ein
  // Klick des Anwenders (mit OnClick und OnChange)
  TChoiceGroupAccess = class(TPPGRadioGroup);

procedure UserPick(AGroup: TPPGRadioGroup; AIndex: Integer);
begin
  TChoiceGroupAccess(AGroup).ActivateItem(AIndex);
end;

function TDemoShowRadioGroupPage.SubjectClass: TComponentClass;
begin
  Result := TPPGRadioGroup;
end;

procedure TDemoShowRadioGroupPage.SetupSubject(ASubject: TComponent);
var
  Grp: TPPGRadioGroup;
begin
  inherited SetupSubject(ASubject);
  // Mit Eintraegen, damit man sofort waehlen kann
  Grp := TPPGRadioGroup(ASubject);
  Grp.SetBounds(Grp.Left, Grp.Top, 280, 130);
  Grp.Items.Add('Rechnung');
  Grp.Items.Add('Lastschrift');
  Grp.Items.Add('Kreditkarte');
end;

procedure TDemoShowRadioGroupPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'ItemIndex') then
    ACategory := 'Inhalt'
  else if SameText(AName, 'ChoiceStyle') or SameText(AName, 'ShowFrame') or
    SameText(AName, 'ItemStyle') or SameText(AName, 'SelectedStyle') or
    SameText(AName, 'CaptionStyle') or SameText(AName, 'HighlightFocus') then
    ACategory := 'PPGlow'
  else if SameText(AName, 'Columns') then
    ACategory := 'Layout'
  else if SameText(AName, 'ValidationState') then
    ACategory := 'Verhalten'
  else if SameText(AName, 'ValidationHint') then
    ACategory := 'Hinweise & Hilfe'
  else if SameText(AName, 'Images') then
    ACategory := 'Beschriftung & Bild';
end;

function TDemoShowRadioGroupPage.SkipInRoundTrip(Node: TDemoPropNode;
  var AReason: string): Boolean;
begin
  // Items und ItemsEx sind dieselben Eintraege. Zuruecksetzen auf eine neue
  // Komponente (ohne Eintraege) leerte die Buehne, und die folgenden Zeilen
  // ItemIndex und ItemsEx[n] haetten nichts mehr zum Pruefen.
  Result := (Node.Parent = nil) and SameText(Node.Name, 'Items');
  if Result then
    AReason := 'Zur' + #$00FC + 'cksetzen leert die Eintr' + #$00E4 +
      'ge, an denen ItemIndex und ItemsEx[n] h' + #$00E4 + 'ngen';
end;

procedure TDemoShowRadioGroupPage.EventOccurred(const AName, ADetail: string);
var
  Grp: TPPGRadioGroup;
  Detail: string;
begin
  Detail := ADetail;
  if ((AName = 'OnClick') or (AName = 'OnChange')) and (Subject is TPPGRadioGroup) then
  begin
    Grp := TPPGRadioGroup(Subject);
    if Grp.ItemIndex >= 0 then
      Detail := Format('ItemIndex = %d (%s)', [Grp.ItemIndex, Grp.Items[Grp.ItemIndex]])
    else
      Detail := 'ItemIndex = -1';
  end;
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowRadioGroupPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Versandart', 'ExRadioGroupShipping',
    'Versandart im Bestellformular als <b>Auswahlkacheln</b> (ChoiceStyle = csCards, Columns = 1): je Kachel '
    + 'Symbol, Titel, Beschreibung und ein <b>Value</b> (Versandkosten in Cent) aus <b>ItemsEx</b>; '
    + '"Abholung" ist gesperrt. Probieren Sie: zuerst "Bestellen" ohne Auswahl (die Gruppe wird rot, '
    + 'ValidationHint als Tooltip), dann eine Kachel w{ae}hlen {-} <b>OnChange</b> rechnet die Summe neu.');
  FShipping := TShippingChoice.CreateChoice(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Abo-Einstellungen', 'ExRadioGroupSubscription',
    'Oben ein <b>Segment-Umschalter</b> ohne Rahmen (csSegmented, ShowFrame = False) f{ue}r den '
    + 'Abrechnungszeitraum, darunter eine klassische Optionsgruppe mit <b>Items</b> und <b>Columns</b> = 3. '
    + 'Probieren Sie: "Lastschrift" w{ae}hlen {-} <b>OnClick</b> gibt das IBAN-Feld frei; mit den '
    + 'Pfeiltasten durch die Segmente wechseln.');
  FSettings := TSubscriptionSettings.CreateSettings(Own, V.Live, DemoStyles);
end;

procedure TDemoShowRadioGroupPage.SelfTest(Check: TDemoCheck);
var
  Grp: TPPGRadioGroup;
  N: Integer;
begin
  inherited SelfTest(Check);

  // Buehne: Wahl des Anwenders meldet OnClick und OnChange, Code nicht
  ResetSubject;
  Grp := TPPGRadioGroup(Subject);
  UserPick(Grp, 1);
  Check('TPPGRadioGroup: Wahl auf der B' + #$00FC + 'hne meldet OnClick und OnChange mit ItemIndex',
    (EventList.Items.Count >= 2) and (Pos('OnChange', EventList.Items[0]) > 0) and
    (Pos('ItemIndex = 1', EventList.Items[0]) > 0) and (Pos('OnClick', EventList.Items[1]) > 0));
  N := EventList.Items.Count;
  Inspector.SetValueText('ItemIndex', '2');
  Check('TPPGRadioGroup: ItemIndex im Inspektor (Code) setzt ohne Ereignis',
    (Grp.ItemIndex = 2) and (EventList.Items.Count = N));
  ResetSubject;

  // Praxisbeispiel 1: Pflichtauswahl, gesperrte Kachel, Value und Summe
  FShipping.Shipping.ItemIndex := -1;
  FShipping.Shipping.ValidationState := pvsNone;
  FShipping.OrderButton.Click;
  Check('Beispiel Versandart: Bestellen ohne Auswahl markiert die Gruppe rot (ValidationState, Hint)',
    (FShipping.Shipping.ValidationState = pvsError) and (FShipping.Shipping.ValidationHint <> '') and
    (Pos('fehlt', FShipping.Status.Caption) > 0));
  UserPick(FShipping.Shipping, 2);
  Check('Beispiel Versandart: gesperrte Kachel "Abholung" l' + #$00E4 + 'sst sich nicht w' + #$00E4 +
    'hlen', FShipping.Shipping.ItemIndex = -1);
  UserPick(FShipping.Shipping, 1);
  Check('Beispiel Versandart: Wahl "Express" l' + #$00F6 + 'scht die Fehlermarke, Value = 990',
    (FShipping.Shipping.ValidationState = pvsNone) and (FShipping.Shipping.Value = '990') and
    (FShipping.ShippingCents = 990));
  Check('Beispiel Versandart: OnChange rechnet die Summe (129,90)',
    (Pos('129', FShipping.Total.Caption) > 0) and (Pos('9,90', FShipping.Total.Caption) +
    Pos('9.90', FShipping.Total.Caption) > 0));
  FShipping.OrderButton.Click;
  Check('Beispiel Versandart: Bestellen mit Auswahl nennt die Versandart',
    Pos('Express', FShipping.Status.Caption) > 0);

  // Praxisbeispiel 2: LoadSettings ohne Ereignis, OnClick schaltet die IBAN,
  // OnChange der Segmente aendert den Preis
  FSettings.LoadSettings(2, 1);
  Check('Beispiel Abo: LoadSettings zeigt Jahr und Lastschrift, IBAN frei',
    (FSettings.Interval.ItemIndex = 2) and (FSettings.Payment.ItemIndex = 1) and
    FSettings.Iban.Enabled and (Pos('Jahr', FSettings.Price.Caption) > 0));
  UserPick(FSettings.Payment, 0);
  Check('Beispiel Abo: Wahl "Rechnung" (OnClick) sperrt die IBAN', not FSettings.Iban.Enabled);
  UserPick(FSettings.Payment, 1);
  Check('Beispiel Abo: Wahl "Lastschrift" (OnClick) gibt die IBAN frei', FSettings.Iban.Enabled);
  UserPick(FSettings.Interval, 1);
  Check('Beispiel Abo: Segment "Quartal" (OnChange) zeigt den Quartalspreis',
    Pos('Quartal', FSettings.Price.Caption) > 0);
  FSettings.Interval.ItemIndex := 0;
  Check('Beispiel Abo: ItemIndex im Code l' + #$00F6 + 'st kein OnChange aus (Preis bleibt)',
    Pos('Quartal', FSettings.Price.Caption) > 0);
  FSettings.LoadSettings(0, 0);
end;

initialization
  RegisterShowcasePage('TPPGRadioGroup', TDemoShowRadioGroupPage);

end.
