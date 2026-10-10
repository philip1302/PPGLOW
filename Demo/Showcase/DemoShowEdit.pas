unit DemoShowEdit;

// Komponentenseite TPPGEdit (Gruppe "Eingabe"): Buehne und Inspektor kommen
// aus TDemoComponentPage; hier stehen nur die Besonderheiten des Felds
// (Platzhalter auf der Buehne, Kategorien, Text im Protokoll) und die beiden
// Praxisbeispiele (ExEditSearch, ExEditCustomer).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.Controls.Field, PPG.Edit, DemoKit, DemoShowcase, ExEditSearch, ExEditCustomer;

type
  TDemoShowEditPage = class(TDemoComponentPage)
  private
    FSearch: TCustomerSearch;
    FCustomer: TCustomerForm;
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
  Winapi.Windows;

type
  // Zugriff auf ButtonClick (Klick auf einen Knopf im Feld ohne Maus)
  TEditAccess = class(TPPGEdit);

function TDemoShowEditPage.SubjectClass: TComponentClass;
begin
  Result := TPPGEdit;
end;

procedure TDemoShowEditPage.SetupSubject(ASubject: TComponent);
begin
  inherited SetupSubject(ASubject);
  // Breit genug fuer einen Suchbegriff; der Platzhalter zeigt gleich, wozu
  // das Feld dient
  TPPGEdit(ASubject).Width := 280;
  TPPGEdit(ASubject).TextHint := 'Kunde suchen ...';
end;

procedure TDemoShowEditPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'Text') or SameText(AName, 'TextHint') or
    SameText(AName, 'TextHintVisibleOnFocus') or SameText(AName, 'MaxLength') or
    SameText(AName, 'CharCase') or SameText(AName, 'NumbersOnly') or
    SameText(AName, 'PasswordChar') then
    ACategory := 'Inhalt'
  else if SameText(AName, 'ShowClearButton') or SameText(AName, 'AutoSelect') or
    SameText(AName, 'HideSelection') or SameText(AName, 'UseSystemContextMenu') or
    SameText(AName, 'ValidationState') or SameText(AName, 'ValidationHint') then
    ACategory := 'Verhalten'
  else if SameText(AName, 'LeftButton') or SameText(AName, 'RightButton') then
    ACategory := 'Beschriftung & Bild'
  else if SameText(AName, 'BorderStyle') then
    ACategory := 'Darstellung (VCL)';
end;

procedure TDemoShowEditPage.EventOccurred(const AName, ADetail: string);
var
  Detail: string;
begin
  Detail := ADetail;
  if (AName = 'OnChange') and (Subject is TPPGEdit) then
    Detail := Format('Text = "%s"', [TPPGEdit(Subject).Text]);
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowEditPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Kundensuche', 'ExEditSearch',
    'Ein Suchfeld {ue}ber einer Kundenliste: <b>TextHint</b> sagt, wonach gesucht wird, '
    + '<b>OnChange</b> filtert beim Tippen, <b>ShowClearButton</b> leert das Feld. Der Knopf '
    + 'links (<b>LeftButton</b> mit Bild und <b>DropDownMenu</b>) w{ae}hlt, ob im Namen oder im '
    + 'Ort gesucht wird. Probieren Sie: "han" tippen, Enter (<b>OnKeyDown</b> {ue}bernimmt den '
    + 'ersten Treffer), dann "xyz" {-} das Feld zeigt eine Warnung (<b>ValidationState</b>).');
  FSearch := TCustomerSearch.CreateSearch(Own, V.Live, Host.Images, DemoStyles);

  V := AddExample('Praxis: Kundendaten', 'ExEditCustomer',
    'Ein Stammdaten-Formular: Die Kundennummer ist <b>ReadOnly</b> (eigene Optik {ue}ber '
    + '<b>ReadOnlyStyle</b>), der Name hat <b>MaxLength</b>, die PLZ nimmt nur Ziffern '
    + '(<b>NumbersOnly</b>). Die E-Mail wird beim Tippen gepr{ue}ft (<b>ValidationState</b> und '
    + '<b>ValidationHint</b>); der Brief-Knopf (<b>RightButton</b>) geht nur bei g{ue}ltiger '
    + 'Adresse. Probieren Sie: Namen eingeben, "info@" tippen, dann vervollst{ae}ndigen.');
  FCustomer := TCustomerForm.CreateForm(Own, V.Live, Host.Images, DemoStyles);
end;

procedure TDemoShowEditPage.SelfTest(Check: TDemoCheck);
const
  Prefix = 'TPPGEdit: ';
var
  Ed: TPPGEdit;
  Key: Word;
begin
  inherited SelfTest(Check);

  // Buehne: Text aendern erscheint mit Inhalt im Protokoll; Loeschknopf leert
  ResetSubject;
  Ed := TPPGEdit(Subject);
  Inspector.SetValueText('Text', 'Hansen');
  Check(Prefix + 'Text im Inspektor l' + #$00F6 + 'st OnChange mit dem Text im Protokoll aus',
    (EventList.Items.Count > 0) and (Pos('OnChange', EventList.Items[0]) > 0) and
    (Pos('Hansen', EventList.Items[0]) > 0));
  Inspector.SetValueText('ShowClearButton', 'True');
  TEditAccess(Ed).ButtonClick(PPGFieldButtonClear);
  Check(Prefix + 'L' + #$00F6 + 'schknopf (ShowClearButton) leert das Feld', Ed.Text = '');
  ResetSubject;

  // Praxisbeispiel 1: Kundensuche
  FSearch.SearchEdit.Text := 'han';
  Check('Beispiel Kundensuche: "han" im Namen findet 2 Kunden',
    FSearch.ResultList.Items.Count = 2);
  Key := VK_RETURN;
  FSearch.SearchEdit.OnKeyDown(FSearch.SearchEdit, Key, []);
  Check('Beispiel Kundensuche: Enter ' + #$00FC + 'bernimmt den ersten Treffer',
    (Pos('Hansen Logistik', FSearch.Selected) = 1) and (Key = 0));
  FSearch.SearchEdit.Text := 'xyz';
  Check('Beispiel Kundensuche: ohne Treffer warnt das Feld (pvsWarning mit Hinweis)',
    (FSearch.ResultList.Items.Count = 0) and
    (FSearch.SearchEdit.ValidationState = pvsWarning) and
    (FSearch.SearchEdit.ValidationHint <> ''));
  FSearch.SearchMenu.Items[1].Click;
  FSearch.SearchEdit.Text := 'hamburg';
  Check('Beispiel Kundensuche: Men' + #$00FC + ' am LeftButton sucht im Ort (2 in Hamburg)',
    (FSearch.SearchIn = siCity) and (FSearch.ResultList.Items.Count = 2) and
    (FSearch.SearchEdit.ValidationState = pvsNone) and
    (Pos('Ort', FSearch.SearchEdit.TextHint) > 0));
  FSearch.SearchEdit.ShowClearButton := True;
  TEditAccess(FSearch.SearchEdit).ButtonClick(PPGFieldButtonClear);
  Check('Beispiel Kundensuche: L' + #$00F6 + 'schknopf zeigt wieder alle 8 Kunden',
    (FSearch.SearchEdit.Text = '') and (FSearch.ResultList.Items.Count = 8));
  FSearch.SearchMenu.Items[0].Click;

  // Praxisbeispiel 2: Kundendaten
  Check('Beispiel Kundendaten: Kundennummer ReadOnly, Speichern ohne Namen gesperrt',
    FCustomer.NumberEdit.ReadOnly and not FCustomer.SaveButton.Enabled);
  Check('Beispiel Kundendaten: PLZ nur Ziffern, h' + #$00F6 + 'chstens 5',
    FCustomer.ZipEdit.NumbersOnly and (FCustomer.ZipEdit.MaxLength = 5));
  FCustomer.NameEdit.Text := 'Krause Bau';
  Check('Beispiel Kundendaten: mit Namen ist Speichern frei', FCustomer.SaveButton.Enabled);
  FCustomer.MailEdit.Text := 'info@';
  Check('Beispiel Kundendaten: "info@" ist rot (pvsError), Brief-Knopf und Speichern gesperrt',
    (FCustomer.MailEdit.ValidationState = pvsError) and
    (FCustomer.MailEdit.ValidationHint <> '') and
    not FCustomer.MailEdit.RightButton.Enabled and not FCustomer.SaveButton.Enabled);
  FCustomer.MailEdit.Text := 'info@krause-bau.de';
  Check('Beispiel Kundendaten: g' + #$00FC + 'ltige Adresse ist gr' + #$00FC +
    'n, Brief-Knopf und Speichern frei',
    (FCustomer.MailEdit.ValidationState = pvsValid) and FCustomer.MailEdit.RightButton.Enabled and
    FCustomer.SaveButton.Enabled);
  TEditAccess(FCustomer.MailEdit).ButtonClick(PPGEditButtonRight);
  Check('Beispiel Kundendaten: Brief-Knopf l' + #$00F6 + 'st OnRightButtonClick aus',
    Pos('info@krause-bau.de', FCustomer.Status.Caption) > 0);
  FCustomer.ZipEdit.Text := '010';
  Check('Beispiel Kundendaten: PLZ mit 3 Ziffern warnt und sperrt Speichern',
    (FCustomer.ZipEdit.ValidationState = pvsWarning) and not FCustomer.SaveButton.Enabled);
  FCustomer.ZipEdit.Text := '01067';
  FCustomer.SaveButton.Click;
  Check('Beispiel Kundendaten: vollst' + #$00E4 + 'ndige PLZ, Speichern merkt den Namen',
    (FCustomer.ZipEdit.ValidationState = pvsNone) and (FCustomer.LastSaved = 'Krause Bau'));
  FCustomer.NameEdit.Text := '';
  FCustomer.ZipEdit.Text := '';
  FCustomer.MailEdit.Text := '';
end;

initialization
  RegisterShowcasePage('TPPGEdit', TDemoShowEditPage);

end.
