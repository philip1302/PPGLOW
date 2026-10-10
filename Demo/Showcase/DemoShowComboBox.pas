unit DemoShowComboBox;

// Komponentenseite TPPGComboBox (Gruppe "Auswahl"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten der
// ComboBox (Eintraege auf der Buehne, Kategorien, OnCustomDrawItem im
// Protokoll) und die beiden Praxisbeispiele (ExComboBoxAddress,
// ExComboBoxArticle).

interface

uses
  System.SysUtils, System.Classes, System.Types, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  PPG.ComboBox, PPG.CustomDraw, DemoKit, DemoShowcase, ExComboBoxAddress, ExComboBoxArticle;

type
  TDemoShowComboBoxPage = class(TDemoComponentPage)
  private
    FAddress: TAddressForm;
    FArticles: TArticlePicker;
    FDrawLogged: Boolean;
    procedure SubjectDrawItem(Sender: TObject; Canvas: TCanvas; Index: Integer;
      const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
      var DefaultDraw: Boolean);
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

type
  // Zugriff auf die Auswahl wie durch den Anwender (OnClick, OnSelect) im Selbsttest
  TComboAccess = class(TPPGComboBox);

function TDemoShowComboBoxPage.SubjectClass: TComponentClass;
begin
  Result := TPPGComboBox;
end;

procedure TDemoShowComboBoxPage.SetupSubject(ASubject: TComponent);
var
  C: TPPGComboBox;
begin
  inherited SetupSubject(ASubject);
  // Einige Eintraege, damit Aufklappen, Tippen und Auswahl sofort etwas zeigen
  C := TPPGComboBox(ASubject);
  C.Width := 260;
  C.Items.Text := L('Berlin' + sLineBreak + 'Hamburg' + sLineBreak + 'M{ue}nchen' + sLineBreak +
    'K{oe}ln' + sLineBreak + 'Frankfurt am Main' + sLineBreak + 'Stuttgart' + sLineBreak +
    'D{ue}sseldorf' + sLineBreak + 'Leipzig' + sLineBreak + 'Dresden');
  C.TextHint := L('Stadt w{ae}hlen oder eingeben');
  // Eigene Signatur: wird nicht automatisch protokolliert
  C.OnCustomDrawItem := SubjectDrawItem;
  FDrawLogged := False;
end;

procedure TDemoShowComboBoxPage.SubjectDrawItem(Sender: TObject; Canvas: TCanvas;
  Index: Integer; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
  var DefaultDraw: Boolean);
begin
  // Einmal je Aufklappen melden (sonst eine Zeile je gezeichnetem Eintrag)
  if FDrawLogged then
    Exit;
  FDrawLogged := True;
  LogEvent('OnCustomDrawItem', Format(L('Index %d {-} wird f{ue}r jeden Eintrag beim Zeichnen gerufen'),
    [Index]));
end;

procedure TDemoShowComboBoxPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'ItemIndex') or SameText(AName, 'Sorted') then
    ACategory := 'Inhalt'
  else if SameText(AName, 'AutoCloseUp') or SameText(AName, 'AutoComplete') or
    SameText(AName, 'AutoDropDown') or SameText(AName, 'FilterMode') or
    SameText(AName, 'CharCase') or SameText(AName, 'MaxLength') or
    SameText(AName, 'ShowClearButton') or SameText(AName, 'UseSystemContextMenu') or
    SameText(AName, 'ValidationState') then
    ACategory := 'Verhalten'
  else if SameText(AName, 'DropDownCount') or SameText(AName, 'DropDownWidth') or
    SameText(AName, 'AutoDropDownWidth') or SameText(AName, 'ItemHeight') then
    ACategory := 'Layout'
  else if SameText(AName, 'TextHintVisibleOnFocus') then
    ACategory := 'Beschriftung & Bild'
  else if SameText(AName, 'ValidationHint') then
    ACategory := 'Hinweise & Hilfe'
  else if SameText(AName, 'BorderStyle') then
    ACategory := 'Darstellung (VCL)';
end;

procedure TDemoShowComboBoxPage.EventOccurred(const AName, ADetail: string);
var
  C: TPPGComboBox;
  Detail: string;
begin
  Detail := ADetail;
  if Subject is TPPGComboBox then
  begin
    C := TPPGComboBox(Subject);
    if (AName = 'OnClick') or (AName = 'OnSelect') or (AName = 'OnChange') then
      Detail := Format('ItemIndex = %d, Text = "%s"', [C.ItemIndex, C.Text])
    else if AName = 'OnDropDown' then
    begin
      FDrawLogged := False;
      Detail := Format(L('%d Eintr{ae}ge'), [C.Items.Count]);
    end;
  end;
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowComboBoxPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Kundenadresse', 'ExComboBoxAddress',
    'Ein Adressformular: <b>Anrede</b> und <b>Land</b> nur aus der Liste (Style = csDropDownList), '
    + 'das Land alphabetisch (<b>Sorted</b>). <b>OnSelect</b> stellt das PLZ-Feld auf das Land ein. '
    + 'Die <b>Branche</b> ist frei (csDropDown) mit Vorschl{ae}gen: Tippen Sie "Hand" (AutoComplete) '
    + 'oder einen eigenen Text. Speichern ohne Land zeigt den <b>ValidationState</b>.');
  FAddress := TAddressForm.CreateForm(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Artikel w{ae}hlen', 'ExComboBoxArticle',
    'Eine Auftragsposition: Der <b>Artikel</b> hat reiche Eintr{ae}ge (<b>ItemsEx</b> mit Detailzeile, '
    + 'Plakette, gesperrtem Eintrag) und filtert beim Tippen (<b>FilterMode</b> = fmContains): Tippen Sie '
    + '"kabellos". Das <b>Lager</b> l{ae}dt erst beim Aufklappen (<b>OnDropDown</b>) die Lager mit Bestand; '
    + 'knappe Best{ae}nde sind kursiv (<b>OnCustomDrawItem</b>). Ein unbekannter Artikel wird beim '
    + 'Verlassen markiert (OnExit).');
  FArticles := TArticlePicker.CreatePicker(Own, V.Live, DemoStyles);
end;

procedure TDemoShowComboBoxPage.SelfTest(Check: TDemoCheck);
var
  C: TPPGComboBox;
  Style: TPPGDrawStyle;
  DefDraw: Boolean;
  N: Integer;
begin
  inherited SelfTest(Check);
  // Buehne: Auswahl wie durch den Anwender meldet OnClick und OnSelect;
  // ItemIndex aus dem Code meldet nichts
  ResetSubject;
  C := TPPGComboBox(Subject);
  Check('TPPGComboBox: B' + #$00FC + 'hne hat Eintr' + #$00E4 + 'ge', C.Items.Count = 9);
  N := EventList.Items.Count;
  C.ItemIndex := 2;
  Check('TPPGComboBox: ItemIndex aus dem Code l' + #$00F6 + 'st kein Ereignis aus',
    EventList.Items.Count = N);
  TComboAccess(C).SelectIndex(1);
  Check('TPPGComboBox: Auswahl meldet OnClick und danach OnSelect mit Text',
    (EventList.Items.Count >= 2) and (Pos('OnSelect', EventList.Items[0]) > 0) and
    (Pos('Hamburg', EventList.Items[0]) > 0) and (Pos('OnClick', EventList.Items[1]) > 0));
  ResetSubject;

  // Praxisbeispiel 1: Kundenadresse
  Check('Beispiel Adresse: Land sortiert (Belgien zuerst), Anrede nur aus der Liste',
    (FAddress.Country.Items[0] = 'Belgien') and (FAddress.Salutation.Text = 'Firma') and
    (FAddress.Salutation.Style = csDropDownList));
  FAddress.SaveButton.Click;
  Check('Beispiel Adresse: Speichern ohne Land markiert das Feld (pvsError)',
    (FAddress.Country.ValidationState = pvsError) and (Pos('fehlt', FAddress.Status.Caption) > 0));
  TComboAccess(FAddress.Country).SelectIndex(FAddress.Country.Items.IndexOf('Schweiz'));
  Check('Beispiel Adresse: OnSelect Schweiz stellt PLZ auf 4 Stellen, Vorwahl +41, Fehler weg',
    FAddress.Zip.Enabled and (FAddress.Zip.MaxLength = 4) and
    (Pos('+41', FAddress.CountryInfo.Caption) > 0) and
    (FAddress.Country.ValidationState = pvsNone));
  FAddress.Industry.Text := 'Messebau';
  FAddress.SaveButton.Click;
  Check('Beispiel Adresse: Branche als eigener Text ohne Listeneintrag gespeichert',
    (FAddress.Industry.ItemIndex = -1) and (Pos('Messebau', FAddress.Status.Caption) > 0) and
    (Pos('Schweiz', FAddress.Status.Caption) > 0));
  FAddress.Industry.Text := '';

  // Praxisbeispiel 2: Artikel und Lager
  Check('Beispiel Artikel: 7 reiche Eintr' + #$00E4 + 'ge, Items enth' + #$00E4 + 'lt ihre Texte, ausverkauft gesperrt',
    (FArticles.Article.ItemsEx.Count = 7) and (FArticles.Article.Items.Count = 7) and
    (FArticles.Article.Items[1] = 'Dockingstation USB-C') and
    not FArticles.Article.ItemsEx[6].Enabled);
  Check('Beispiel Artikel: Lager gesperrt, solange kein Artikel gew' + #$00E4 + 'hlt ist',
    not FArticles.Warehouse.Enabled);
  TComboAccess(FArticles.Article).SelectIndex(1);
  Check('Beispiel Artikel: OnSelect zeigt den Preis und gibt das Lager frei',
    (Pos('189', FArticles.Price.Caption) > 0) and FArticles.Warehouse.Enabled);
  FArticles.Warehouse.OnDropDown(FArticles.Warehouse);
  Check('Beispiel Artikel: OnDropDown l' + #$00E4 + 'dt nur Lager mit Bestand (Berlin 4, Hamburg 8)',
    (FArticles.Warehouse.Items.Count = 2) and (Pos('Berlin', FArticles.Warehouse.Items[0]) = 1) and
    (Pos('Hamburg', FArticles.Warehouse.Items[1]) = 1));
  Style.Reset;
  DefDraw := True;
  FArticles.Warehouse.OnCustomDrawItem(FArticles.Warehouse, nil, 0, Rect(0, 0, 10, 10), [],
    Style, DefDraw);
  Check('Beispiel Artikel: OnCustomDrawItem setzt knappen Bestand kursiv',
    (Style.FontStyle = [fsItalic]) and DefDraw);
  Style.Reset;
  FArticles.Warehouse.OnCustomDrawItem(FArticles.Warehouse, nil, 1, Rect(0, 0, 10, 10), [],
    Style, DefDraw);
  Check('Beispiel Artikel: OnCustomDrawItem l' + #$00E4 + 'sst ausreichenden Bestand normal',
    Style.FontStyle = []);
  FArticles.Article.Text := 'Beamer';
  FArticles.Article.OnChange(FArticles.Article);
  FArticles.Article.OnExit(FArticles.Article);
  Check('Beispiel Artikel: unbekannter Text sperrt das Lager und warnt beim Verlassen',
    (not FArticles.Warehouse.Enabled) and (FArticles.Article.ValidationState = pvsWarning));
  FArticles.Article.Text := '';
  FArticles.Article.OnExit(FArticles.Article);
end;

initialization
  RegisterShowcasePage('TPPGComboBox', TDemoShowComboBoxPage);

end.
