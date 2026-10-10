unit DemoShowSpinEdit;

// Komponentenseite TPPGSpinEdit (Gruppe "Eingabe"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten des
// Zahlenfelds (Bereich 0..100 auf der Buehne, Value im Protokoll, eigene
// Kategorien) und die beiden Praxisbeispiele (ExSpinEditOrder,
// ExSpinEditAutoSave).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.SpinEdit, DemoKit, DemoShowcase, ExSpinEditOrder, ExSpinEditAutoSave;

type
  TDemoShowSpinEditPage = class(TDemoComponentPage)
  private
    FOrder: TOrderLine;
    FAutoSave: TAutoSaveSettings;
  protected
    function SubjectClass: TComponentClass; override;
    procedure BuildContent; override;
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

function TDemoShowSpinEditPage.SubjectClass: TComponentClass;
begin
  Result := TPPGSpinEdit;
end;

procedure TDemoShowSpinEditPage.BuildContent;
begin
  inherited BuildContent;
  // Das Geruest waehlt "Caption"; das Zahlenfeld hat keine. Value zeigt die
  // Erklaerung der wichtigsten Eigenschaft gleich beim Oeffnen.
  Inspector.SelectPath('Value');
end;

procedure TDemoShowSpinEditPage.SetupSubject(ASubject: TComponent);
var
  Spin: TPPGSpinEdit;
begin
  inherited SetupSubject(ASubject);
  // Ein Bereich, damit die Grenzen sofort spuerbar sind: Pfeile an den
  // Enden werden grau, Eingaben ausserhalb werden begrenzt
  Spin := TPPGSpinEdit(ASubject);
  Spin.Width := 160;
  Spin.Min := 0;
  Spin.Max := 100;
  Spin.Value := 25;
end;

procedure TDemoShowSpinEditPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if (AName = 'Value') or (AName = 'Min') or (AName = 'Max') or (AName = 'Increment') then
    ACategory := 'Inhalt'
  else if (AName = 'EditorEnabled') or (AName = 'AutoSelect') or (AName = 'MaxLength') or
    (AName = 'UseSystemContextMenu') then
    ACategory := 'Verhalten'
  else if (AName = 'ValidationState') or (AName = 'ValidationHint') then
    ACategory := 'Hinweise & Hilfe'
  else if AName = 'TextHintVisibleOnFocus' then
    ACategory := 'Beschriftung & Bild'
  else if AName = 'BorderStyle' then
    ACategory := 'Darstellung (VCL)';
end;

procedure TDemoShowSpinEditPage.EventOccurred(const AName, ADetail: string);
var
  Detail: string;
begin
  Detail := ADetail;
  // OnChange hat keine Parameter: den neuen Wert dazuschreiben
  if (AName = 'OnChange') and (Subject is TPPGSpinEdit) then
    Detail := Format('Value = %d', [TPPGSpinEdit(Subject).Value]);
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowSpinEditPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Bestellposition', 'ExSpinEditOrder',
    'Eine Bestellposition: Die <b>Menge</b> geht von 1 bis zum Lagerbestand (<b>Min</b>, '
    + '<b>Max</b>), der <b>Rabatt</b> springt in 5er-Schritten (<b>Increment</b>) und l{ae}sst '
    + 'sich nicht eintippen (<b>EditorEnabled</b> = False). <b>OnChange</b> rechnet die Summe neu. '
    + 'Probieren Sie: 80 als Menge eintippen und Tab dr{ue}cken, Pfeile gedr{ue}ckt halten, '
    + 'Bild auf/ab im Rabatt.');
  FOrder := TOrderLine.CreateLine(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Automatisch speichern', 'ExSpinEditAutoSave',
    'Eine Einstellungsseite: Das <b>Intervall</b> warnt unter 5 Minuten (<b>ValidationState</b>, '
    + 'Grund im Tooltip {-} <b>ValidationHint</b>), die Checkbox sperrt es (<b>Enabled</b>). '
    + 'Die <b>Versionen</b> legt der Administrator fest (<b>ReadOnly</b>: lesbar, nicht '
    + '{ae}nderbar). Probieren Sie: Intervall auf 3 stellen, dann die Checkbox ausschalten.');
  FAutoSave := TAutoSaveSettings.CreateSettings(Own, V.Live, DemoStyles);
end;

procedure TDemoShowSpinEditPage.SelfTest(Check: TDemoCheck);
var
  Spin: TPPGSpinEdit;
begin
  inherited SelfTest(Check);
  // Buehne: Schritt mit den Pfeilen erscheint mit Wert im Protokoll,
  // Werte ausserhalb werden still begrenzt
  ResetSubject;
  Spin := TPPGSpinEdit(Subject);
  Spin.Spin(1);
  Check('TPPGSpinEdit: Schritt auf der B' + #$00FC + 'hne erscheint mit Value im Protokoll',
    (Spin.Value = 26) and (EventList.Items.Count > 0) and
    (Pos('OnChange', EventList.Items[0]) > 0) and (Pos('Value = 26', EventList.Items[0]) > 0));
  Spin.Value := 500;
  Check('TPPGSpinEdit: Value 500 wird auf Max = 100 begrenzt', Spin.Value = 100);
  Inspector.SetValueText('Increment', '10');
  Spin.Spin(-2);
  Check('TPPGSpinEdit: Increment 10 aus dem Inspektor, zwei Schritte ab = 80', Spin.Value = 80);
  ResetSubject;

  // Praxisbeispiel 1: Bestellposition
  FOrder.Quantity.Value := 1;
  FOrder.Discount.Value := 0;
  FOrder.Quantity.Value := 3;
  Check('Beispiel Bestellposition: 3 St' + #$00FC + 'ck ergeben 14,70 EUR',
    FOrder.TotalCents = 1470);
  FOrder.Quantity.Value := 80;
  Check('Beispiel Bestellposition: Menge 80 wird auf den Lagerbestand 50 begrenzt',
    FOrder.Quantity.Value = 50);
  FOrder.Quantity.Value := 0;
  Check('Beispiel Bestellposition: Menge 0 wird auf Min = 1 angehoben',
    FOrder.Quantity.Value = 1);
  FOrder.Quantity.Value := 10;
  FOrder.Discount.Spin(1);
  Check('Beispiel Bestellposition: ein Schritt Rabatt = 5 %, Summe 46,55 EUR',
    (FOrder.Discount.Value = 5) and (FOrder.TotalCents = 4655));
  FOrder.Discount.Spin(10);
  Check('Beispiel Bestellposition: Rabatt endet bei Max = 30 %',
    FOrder.Discount.Value = 30);
  Check('Beispiel Bestellposition: Rabatt nicht eintippbar, Schrittweite 5',
    (not FOrder.Discount.EditorEnabled) and (FOrder.Discount.Increment = 5));
  FOrder.Discount.Value := 0;
  FOrder.Quantity.Value := 1;

  // Praxisbeispiel 2: Automatisch speichern
  FAutoSave.Interval.Value := 3;
  Check('Beispiel Automatisch speichern: Intervall 3 zeigt eine Warnung mit Grund',
    (FAutoSave.Interval.ValidationState = pvsWarning) and (FAutoSave.Interval.ValidationHint <> ''));
  FAutoSave.Interval.Value := 15;
  Check('Beispiel Automatisch speichern: Intervall 15 ohne Warnung, Status nennt 15 Minuten',
    (FAutoSave.Interval.ValidationState = pvsNone) and
    (Pos('alle 15 Minuten', FAutoSave.Status.Caption) > 0));
  FAutoSave.Active.Click;
  Check('Beispiel Automatisch speichern: Checkbox aus sperrt das Intervall',
    (not FAutoSave.Active.Checked) and (not FAutoSave.Interval.Enabled) and
    (Pos('aus', FAutoSave.Status.Caption) > 0));
  FAutoSave.Active.Click;
  Check('Beispiel Automatisch speichern: Checkbox an gibt das Intervall wieder frei',
    FAutoSave.Active.Checked and FAutoSave.Interval.Enabled);
  FAutoSave.Versions.Spin(1);
  Check('Beispiel Automatisch speichern: ReadOnly-Versionen bleiben bei 5',
    FAutoSave.Versions.ReadOnly and (FAutoSave.Versions.Value = 5));
  FAutoSave.Interval.Value := 10;
end;

initialization
  RegisterShowcasePage('TPPGSpinEdit', TDemoShowSpinEditPage);

end.
