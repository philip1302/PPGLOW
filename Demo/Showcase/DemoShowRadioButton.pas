unit DemoShowRadioButton;

// Komponentenseite TPPGRadioButton (Gruppe "Auswahl"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten des
// RadioButtons (Checked im Protokoll) und die beiden Praxisbeispiele
// (ExRadioButtonShipping, ExRadioButtonExport).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.RadioButton, DemoKit, DemoShowcase, ExRadioButtonShipping, ExRadioButtonExport;

type
  TDemoShowRadioButtonPage = class(TDemoComponentPage)
  private
    FShipping: TShippingChoice;
    FExport: TExportOptions;
  protected
    function SubjectClass: TComponentClass; override;
    procedure BuildExamples; override;
    procedure EventOccurred(const AName, ADetail: string); override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

function TDemoShowRadioButtonPage.SubjectClass: TComponentClass;
begin
  Result := TPPGRadioButton;
end;

procedure TDemoShowRadioButtonPage.EventOccurred(const AName, ADetail: string);
var
  Detail: string;
begin
  Detail := ADetail;
  if ((AName = 'OnClick') or (AName = 'OnChange')) and (Subject is TPPGRadioButton) then
    Detail := Format('Checked = %s', [BoolToStr(TPPGRadioButton(Subject).Checked, True)]);
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowRadioButtonPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Versandart', 'ExRadioButtonShipping',
    'Versandart in einer Bestellung: Drei Optionen in einer <b>GroupBox</b> bilden eine Gruppe '
    + '(gleicher Parent), genau eine ist gew{ae}hlt. Ein gemeinsames <b>OnClick</b> liest den Preis '
    + 'aus <b>Tag</b>. Probieren Sie: Express w{ae}hlen, dann Sperrgut anhaken (Express wird '
    + 'gesperrt, die Auswahl springt auf Standard), Abholung w{ae}hlen (Adressfeld gesperrt). '
    + 'Mit Tab in die Gruppe und mit den Pfeiltasten wechseln.');
  FShipping := TShippingChoice.CreateChoice(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Export-Optionen', 'ExRadioButtonExport',
    'Zwei Gruppen im selben Container, getrennt {ue}ber <b>GroupIndex</b> (Format = 1, Umfang = 2): '
    + 'Eine Wahl im Format l{ae}sst den Umfang unber{ue}hrt. <b>OnChange</b> h{ae}lt die '
    + 'Zusammenfassung aktuell, auch wenn der Code <b>Checked</b> setzt. Probieren Sie: Excel und '
    + '"Nur Auswahl" w{ae}hlen, dann "Standard wiederherstellen".');
  FExport := TExportOptions.CreateOptions(Own, V.Live, DemoStyles, 12);
end;

procedure TDemoShowRadioButtonPage.SelfTest(Check: TDemoCheck);
var
  Rb: TPPGRadioButton;
begin
  inherited SelfTest(Check);
  // Buehne: Klick schaltet ein und erscheint im Protokoll; ein zweiter Klick
  // schaltet nicht aus (RadioButtons schaltet man nur ein)
  ResetSubject;
  Rb := TPPGRadioButton(Subject);
  Rb.Click;
  Check('TPPGRadioButton: Klick auf der B' + #$00FC + 'hne schaltet ein und erscheint im Protokoll',
    Rb.Checked and (EventList.Items.Count > 0) and (Pos('OnClick', EventList.Items[0]) > 0) and
    (Pos('Checked = True', EventList.Items[0]) > 0));
  Rb.Click;
  Check('TPPGRadioButton: zweiter Klick schaltet nicht aus', Rb.Checked);
  Inspector.SetValueText('Checked', 'False');
  Check('TPPGRadioButton: Checked im Inspektor l' + #$00F6 + 'st nur OnChange aus',
    (not Rb.Checked) and (Pos('OnChange', EventList.Items[0]) > 0));
  ResetSubject;

  // Praxisbeispiel 1: Versandart
  Check('Beispiel Versandart: Standard vorgew' + #$00E4 + 'hlt, 4,90 EUR',
    FShipping.Standard.Checked and (FShipping.CostCents = 490) and
    (Pos('4,90', FShipping.CostLabel.Caption) > 0));
  FShipping.Express.Click;
  Check('Beispiel Versandart: Express schaltet Standard aus, 9,90 EUR',
    FShipping.Express.Checked and not FShipping.Standard.Checked and
    (FShipping.CostCents = 990) and (Pos('9,90', FShipping.CostLabel.Caption) > 0));
  FShipping.Bulky.Click;
  Check('Beispiel Versandart: Sperrgut sperrt Express und w' + #$00E4 + 'hlt Standard',
    (not FShipping.Express.Enabled) and FShipping.Standard.Checked and
    not FShipping.Express.Checked and (FShipping.CostCents = 490));
  FShipping.Pickup.Click;
  Check('Beispiel Versandart: Abholung kostenlos, Adressfeld gesperrt',
    FShipping.Pickup.Checked and (FShipping.CostCents = 0) and not FShipping.Address.Enabled);
  FShipping.Standard.Click;
  Check('Beispiel Versandart: zur' + #$00FC + 'ck zu Standard gibt das Adressfeld frei',
    FShipping.Address.Enabled and not FShipping.Pickup.Checked);
  FShipping.Bulky.Click;
  Check('Beispiel Versandart: ohne Sperrgut ist Express wieder w' + #$00E4 + 'hlbar',
    FShipping.Express.Enabled);

  // Praxisbeispiel 2: zwei Gruppen ueber GroupIndex
  Check('Beispiel Export: Vorgabe PDF und alle Zeilen',
    FExport.Pdf.Checked and FExport.AllRows.Checked and
    (FExport.Summary.Caption = 'Export: alle Zeilen als PDF'));
  FExport.Excel.Click;
  Check('Beispiel Export: Excel schaltet PDF aus, der Umfang bleibt',
    FExport.Excel.Checked and not FExport.Pdf.Checked and FExport.AllRows.Checked and
    (FExport.FormatName = 'Excel'));
  FExport.SelectedRows.Click;
  Check('Beispiel Export: Nur Auswahl schaltet Alle aus, das Format bleibt',
    FExport.SelectedRows.Checked and not FExport.AllRows.Checked and FExport.Excel.Checked and
    (FExport.Summary.Caption = 'Export: 12 markierte Zeilen als Excel'));
  FExport.ResetButton.Click;
  Check('Beispiel Export: Standard wiederherstellen setzt Checked im Code, OnChange aktualisiert',
    FExport.Pdf.Checked and not FExport.Excel.Checked and FExport.AllRows.Checked and
    not FExport.SelectedRows.Checked and (FExport.Summary.Caption = 'Export: alle Zeilen als PDF'));
  Check('Beispiel Export: nur die gew' + #$00E4 + 'hlte Option jeder Gruppe ist Tabstopp',
    FExport.Pdf.TabStop and not FExport.Excel.TabStop and not FExport.Csv.TabStop and
    FExport.AllRows.TabStop and not FExport.SelectedRows.TabStop);
end;

initialization
  RegisterShowcasePage('TPPGRadioButton', TDemoShowRadioButtonPage);

end.
