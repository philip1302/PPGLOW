unit DemoShowNumberEdit;

// Komponentenseite TPPGNumberEdit (Gruppe "Eingabe"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten des
// Zahlenfelds (Startwert auf der Buehne, Kategorien, Wert im Protokoll) und
// die beiden Praxisbeispiele (ExNumberEditInvoice, ExNumberEditStock).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.NumberEdit, DemoKit, DemoShowcase, ExNumberEditInvoice, ExNumberEditStock;

type
  TDemoShowNumberEditPage = class(TDemoComponentPage)
  private
    FInvoice: TInvoiceLine;
    FStock: TStockData;
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

uses
  PPG.Controls.Field;

function TDemoShowNumberEditPage.SubjectClass: TComponentClass;
begin
  Result := TPPGNumberEdit;
end;

procedure TDemoShowNumberEditPage.SetupSubject(ASubject: TComponent);
begin
  inherited SetupSubject(ASubject);
  // Ein Wert mit Tausender und Nachkommastellen zeigt das Anzeigeformat sofort
  TPPGNumberEdit(ASubject).Width := 180;
  TPPGNumberEdit(ASubject).Value := 1234.5;
end;

procedure TDemoShowNumberEditPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'Kind') or SameText(AName, 'Value') or SameText(AName, 'Min') or
    SameText(AName, 'Max') or SameText(AName, 'Decimals') or SameText(AName, 'AllowNull') then
    ACategory := 'Inhalt'
  else if SameText(AName, 'Increment') or SameText(AName, 'LargeIncrement') or
    SameText(AName, 'ShowSpinButtons') or SameText(AName, 'AllowExpressions') or
    SameText(AName, 'ShowClearButton') or SameText(AName, 'UseSystemContextMenu') then
    ACategory := 'Verhalten'
  else if SameText(AName, 'ShowThousandSeparator') or SameText(AName, 'CurrencyString') or
    SameText(AName, 'TextHintVisibleOnFocus') then
    ACategory := 'Beschriftung & Bild'
  else if SameText(AName, 'ValidationState') or SameText(AName, 'ValidationHint') then
    ACategory := 'Hinweise & Hilfe'
  else if SameText(AName, 'BorderStyle') then
    ACategory := 'Darstellung (VCL)';
end;

procedure TDemoShowNumberEditPage.EventOccurred(const AName, ADetail: string);
var
  Ed: TPPGNumberEdit;
  Detail: string;
begin
  Detail := ADetail;
  if (AName = 'OnChange') and (Subject is TPPGNumberEdit) then
  begin
    // Neuer Wert und wie er ohne Fokus aussieht
    Ed := TPPGNumberEdit(Subject);
    if Ed.IsNull then
      Detail := 'Value = (kein Wert, IsNull)'
    else
      Detail := Format('Value = %s  (Anzeige "%s")', [FloatToStr(Ed.Value), Ed.DisplayText]);
  end;
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowNumberEditPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Rechnungsposition', 'ExNumberEditInvoice',
    'Eine Rechnungsposition: <b>Menge</b> (nkInteger, Spin-Buttons, Min 1), <b>Einzelpreis</b> '
    + '(nkCurrency, <b>AllowExpressions</b>), <b>Rabatt</b> (nkPercent, 0 bis 100) und der '
    + 'berechnete <b>Gesamtbetrag</b> (ReadOnly). <b>OnChange</b> rechnet neu. Probieren Sie: '
    + 'im Preis 3*19,99 und Enter, Menge mit Pfeil auf/ab oder Bild auf, Rabatt 150 eingeben.');
  FInvoice := TInvoiceLine.CreateLine(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Lagerdaten', 'ExNumberEditStock',
    'Lagerdaten eines Artikels: Liegt der <b>Bestand</b> unter dem <b>Meldebestand</b>, warnt das '
    + 'Feld (<b>ValidationState</b>). Der Meldebestand ist optional (<b>AllowNull</b>, '
    + '<b>TextHint</b>), das Gewicht hat drei Nachkommastellen, der Einkauf ist in CHF '
    + '(<b>CurrencyString</b>) und erlaubt kein Rechnen. Probieren Sie: Bestand auf 5, dann '
    + 'Meldebestand leeren; im Einkauf 2*10 und Enter.');
  FStock := TStockData.CreateStock(Own, V.Live, DemoStyles);
end;

procedure TDemoShowNumberEditPage.SelfTest(Check: TDemoCheck);
var
  Ed: TPPGNumberEdit;
  DS: Char;
begin
  inherited SelfTest(Check);
  DS := FormatSettings.DecimalSeparator;

  // Buehne: Anzeigeformat, OnChange mit Wert im Protokoll, Wert aus Code still
  ResetSubject;
  Ed := TPPGNumberEdit(Subject);
  Check('TPPGNumberEdit: B' + #$00FC + 'hne zeigt 1234,5 formatiert mit Tausendertrenner',
    (Ed.Value = 1234.5) and (Ed.Text = Ed.DisplayText) and
    (Pos(FormatSettings.ThousandSeparator, Ed.Text) > 0));
  Ed.Value := 10;
  Check('TPPGNumberEdit: Value aus Code l' + #$00F6 + 'st kein OnChange aus',
    EventList.Items.Count = 0);
  Ed.Spin(1);
  Check('TPPGNumberEdit: Spin erscheint als OnChange mit Wert im Protokoll',
    (EventList.Items.Count > 0) and (Pos('OnChange', EventList.Items[0]) > 0) and
    (Pos('Value = 11', EventList.Items[0]) > 0));
  ResetSubject;

  // Praxisbeispiel 1: Rechnungsposition
  FInvoice.Quantity.Value := 1;
  FInvoice.Discount.Value := 0;
  FInvoice.Price.Text := '2*19' + DS + '99';
  Check('Beispiel Rechnung: Ausdruck 2*19,99 im Preis wird ausgerechnet',
    FInvoice.Price.Commit and (FInvoice.Price.AsCurrency = 39.98));
  Check('Beispiel Rechnung: OnChange rechnet den Gesamtbetrag (39,98)',
    FInvoice.Total.AsCurrency = 39.98);
  FInvoice.Quantity.Spin(2);
  Check('Beispiel Rechnung: Menge +2 per Spin ergibt 3 x 39,98 = 119,94',
    (FInvoice.Quantity.AsInteger = 3) and (FInvoice.Total.AsCurrency = 119.94));
  FInvoice.Discount.Text := '150';
  FInvoice.Discount.Commit;
  Check('Beispiel Rechnung: Rabatt 150 wird auf Max 100 begrenzt, Gesamt 0',
    (FInvoice.Discount.Value = 100) and (FInvoice.Total.AsCurrency = 0));
  FInvoice.Discount.Text := '10';
  FInvoice.Discount.Commit;
  Check('Beispiel Rechnung: 10 % Rabatt, kaufm' + #$00E4 + 'nnisch gerundet 107,95',
    FInvoice.Total.AsCurrency = 107.95);
  FInvoice.Quantity.Text := '0';
  FInvoice.Quantity.Commit;
  Check('Beispiel Rechnung: Menge 0 wird auf Min 1 begrenzt',
    FInvoice.Quantity.AsInteger = 1);
  Check('Beispiel Rechnung: Gesamt ist schreibgesch' + #$00FC + 'tzt und ohne TabStop',
    FInvoice.Total.ReadOnly and not FInvoice.Total.TabStop);
  FInvoice.Price.Value := 0;
  FInvoice.Discount.Value := 0;
  FInvoice.Recalculate;

  // Praxisbeispiel 2: Lagerdaten
  Check('Beispiel Lager: Bestand 25 bei Meldebestand 10 ohne Warnung',
    (not FStock.NeedsReorder) and (FStock.Stock.ValidationState = pvsNone));
  FStock.Stock.Spin(-20);
  Check('Beispiel Lager: Bestand 5 unter Meldebestand 10 warnt (pvsWarning)',
    (FStock.Stock.AsInteger = 5) and (FStock.Stock.ValidationState = pvsWarning) and
    (Pos('5 Stk.', FStock.Status.Caption) > 0));
  FStock.Reorder.Text := '';
  Check('Beispiel Lager: leerer Meldebestand = kein Wert (AllowNull), Warnung weg',
    FStock.Reorder.Commit and FStock.Reorder.IsNull and
    (FStock.Stock.ValidationState = pvsNone));
  FStock.Stock.Text := '-5';
  FStock.Stock.Commit;
  Check('Beispiel Lager: negativer Bestand wird auf Min 0 begrenzt', FStock.Stock.AsInteger = 0);
  Check('Beispiel Lager: Einkauf zeigt CHF und drei Gewichts-Nachkommastellen',
    (Pos('CHF', FStock.Purchase.Text) > 0) and (Pos(DS + '250', FStock.Weight.Text) > 0));
  FStock.Purchase.Text := '2*10';
  Check('Beispiel Lager: ohne AllowExpressions ist 2*10 ung' + #$00FC + 'ltig (pvsError)',
    (not FStock.Purchase.Commit) and (FStock.Purchase.ValidationState = pvsError) and
    (FStock.Purchase.AsCurrency = 1234.5));
  // Ausgangszustand
  FStock.Purchase.AsCurrency := 1234.5;
  FStock.Reorder.Value := 10;
  FStock.Stock.Value := 25;
  FStock.CheckStock;
end;

initialization
  RegisterShowcasePage('TPPGNumberEdit', TDemoShowNumberEditPage);

end.
