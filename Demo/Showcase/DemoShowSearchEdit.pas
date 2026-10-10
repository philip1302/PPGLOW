unit DemoShowSearchEdit;

// Komponentenseite TPPGSearchEdit (Gruppe "Eingabe"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen die Besonderheiten des
// Suchfelds (Vorschlaege auf der Buehne, OnSearch/OnSubmit mit eigener
// Signatur im Protokoll, Kategorien) und die beiden Praxisbeispiele
// (ExSearchEditCustomer, ExSearchEditFilter).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.Controls.Field, PPG.ComboBox, PPG.SearchEdit, DemoKit, DemoShowcase, ExSearchEditCustomer,
  ExSearchEditFilter;

type
  TDemoShowSearchEditPage = class(TDemoComponentPage)
  private
    FCustomer: TCustomerSearch;
    FFilter: TArticleFilter;
    procedure SubjectSearch(Sender: TObject; const SearchText: string);
    procedure SubjectSubmit(Sender: TObject; const SearchText: string);
  protected
    function SubjectClass: TComponentClass; override;
    procedure SetupSubject(ASubject: TComponent); override;
    procedure BuildExamples; override;
    procedure CategoryFor(Sender: TObject; const AName: string; var ACategory: string); override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

type
  // Zugriff auf die geschuetzten Ausloeser (nur fuer den Selbsttest)
  TSearchEditAccess = class(TPPGSearchEdit);

function TDemoShowSearchEditPage.SubjectClass: TComponentClass;
begin
  Result := TPPGSearchEdit;
end;

procedure TDemoShowSearchEditPage.SetupSubject(ASubject: TComponent);
var
  S: TPPGSearchEdit;
begin
  inherited SetupSubject(ASubject);
  S := ASubject as TPPGSearchEdit;
  S.Width := 280;
  S.TextHint := L('Ort suchen {...}');
  // Ein paar Vorschlaege, damit beim Tippen sofort eine Liste erscheint
  S.Items.Text := 'Berlin' + sLineBreak + 'Bremen' + sLineBreak + 'Dortmund' + sLineBreak +
    'Dresden' + sLineBreak + 'Hamburg' + sLineBreak + 'Hannover' + sLineBreak + L('K{oe}ln') +
    sLineBreak + L('M{ue}nchen') + sLineBreak + 'Stuttgart';
  // Eigene Signatur (Sender, SearchText): nicht im automatischen Protokoll
  S.OnSearch := SubjectSearch;
  S.OnSubmit := SubjectSubmit;
end;

procedure TDemoShowSearchEditPage.SubjectSearch(Sender: TObject; const SearchText: string);
begin
  LogEvent('OnSearch', Format('SearchText = ''%s''', [SearchText]));
end;

procedure TDemoShowSearchEditPage.SubjectSubmit(Sender: TObject; const SearchText: string);
begin
  LogEvent('OnSubmit', Format('SearchText = ''%s''', [SearchText]));
end;

procedure TDemoShowSearchEditPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if (AName = 'SearchDelay') or (AName = 'FilterMode') or (AName = 'AutoComplete') or
    (AName = 'Sorted') or (AName = 'DropDownCount') or (AName = 'DropDownWidth') or
    (AName = 'ItemHeight') then
    ACategory := 'Inhalt'
  else if (AName = 'ShowClearButton') or (AName = 'AutoSelect') or (AName = 'CharCase') or
    (AName = 'MaxLength') or (AName = 'UseSystemContextMenu') then
    ACategory := 'Verhalten'
  else if AName = 'TextHintVisibleOnFocus' then
    ACategory := 'Beschriftung & Bild'
  else if (AName = 'ValidationState') or (AName = 'ValidationHint') then
    ACategory := 'Hinweise & Hilfe'
  else if AName = 'BorderStyle' then
    ACategory := 'Darstellung (VCL)';
end;

procedure TDemoShowSearchEditPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Kundensuche', 'ExSearchEditCustomer',
    'Die Kundensuche einer Auftragsmaske: <b>OnSearch</b> f{ue}llt nach <b>SearchDelay</b> '
    + '(250 ms) die Vorschl{ae}ge in <b>ItemsEx</b> mit Ort und Kundennummer als Detailzeile. '
    + '<b>OnSubmit</b> {ue}bernimmt den Kunden und meldet unbekannte Namen {ue}ber '
    + '<b>ValidationState</b>. Probieren Sie: "bau" tippen, einen Vorschlag w{ae}hlen; dann '
    + '"xyz" und Enter; Esc leert das Feld.');
  FCustomer := TCustomerSearch.CreateIn(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Artikelliste filtern', 'ExSearchEditFilter',
    'Ein Suchfeld {ue}ber einer Artikelliste: <b>OnSearch</b> filtert die Liste selbst (ohne '
    + 'Vorschlagsliste), die Zahl der Treffer steht daneben. Ohne Treffer zeigt '
    + '<b>ValidationState</b> einen gelben Rand mit Hinweis. Enter (<b>OnSubmit</b>) w{ae}hlt den '
    + 'ersten Treffer. Probieren Sie: "kabel", dann "monitor" und Enter, zuletzt "xyz".');
  FFilter := TArticleFilter.CreateIn(Own, V.Live, DemoStyles);
end;

procedure TDemoShowSearchEditPage.SelfTest(Check: TDemoCheck);
var
  S: TSearchEditAccess;
  Found: Boolean;
  I: Integer;
begin
  inherited SelfTest(Check);

  // Buehne: Suche und Absenden (eigene Signatur) erscheinen im Protokoll
  ResetSubject;
  S := TSearchEditAccess(Subject);
  Check('TPPGSearchEdit: B' + #$00FC + 'hne hat Vorschl' + #$00E4 + 'ge und Platzhalter',
    (S.Items.Count = 9) and (S.TextHint <> ''));
  S.Text := 'Ham';
  Check('TPPGSearchEdit: Text im Code l' + #$00F6 + 'st keine Suche aus',
    (EventList.Items.Count = 0) or (Pos('OnSearch', EventList.Items[0]) = 0));
  S.DoSearch;
  Check('TPPGSearchEdit: OnSearch erscheint mit dem Suchtext im Protokoll',
    (EventList.Items.Count > 0) and (Pos('OnSearch', EventList.Items[0]) > 0) and
    (Pos('Ham', EventList.Items[0]) > 0));
  EventList.Items.Clear;
  S.ButtonClick(PPGSearchButtonQuery);
  // Die Lupe setzt danach den Fokus ins Feld; OnEnter kann also obenauf liegen
  Found := False;
  for I := 0 to EventList.Items.Count - 1 do
    if (Pos('OnSubmit', EventList.Items[I]) > 0) and (Pos('Ham', EventList.Items[I]) > 0) then
      Found := True;
  Check('TPPGSearchEdit: Klick auf die Lupe meldet OnSubmit mit dem Suchtext', Found);
  Check('TPPGSearchEdit: Abschicken beendet eine wartende Suche', not S.SearchPending);
  ResetSubject;

  // Praxisbeispiel 1: Kundensuche
  Check('Beispiel Kundensuche: SearchDelay 250 ms, FilterMode fmNone',
    (FCustomer.Search.SearchDelay = 250) and (FCustomer.Search.FilterMode = fmNone));
  FCustomer.Search.OnSearch(FCustomer.Search, 'b');
  Check('Beispiel Kundensuche: ein Zeichen liefert noch keine Vorschl' + #$00E4 + 'ge',
    FCustomer.Search.ItemsEx.Count = 0);
  FCustomer.Search.OnSearch(FCustomer.Search, 'bau');
  Found := FCustomer.Search.ItemsEx.Count = 3;
  for I := 0 to FCustomer.Search.ItemsEx.Count - 1 do
    if Pos('K-', FCustomer.Search.ItemsEx[I].Detail) = 0 then
      Found := False;
  Check('Beispiel Kundensuche: "bau" liefert 3 Vorschl' + #$00E4 + 'ge mit Ort und Kundennummer',
    Found);
  FCustomer.Search.OnSubmit(FCustomer.Search, 'Becker Bau GmbH');
  Check('Beispiel Kundensuche: Vorschlag wird als Kunde K-10017 ' + #$00FC + 'bernommen',
    (FCustomer.CustomerNo = 'K-10017') and (FCustomer.Search.ValidationState = pvsValid) and
    (Pos('K-10017', FCustomer.ResultLabel.Caption) > 0));
  FCustomer.Search.OnSubmit(FCustomer.Search, 'xyz');
  Check('Beispiel Kundensuche: unbekannter Name zeigt Fehler mit Hinweis',
    (FCustomer.CustomerNo = '') and (FCustomer.Search.ValidationState = pvsError) and
    (FCustomer.Search.ValidationHint <> ''));
  FCustomer.Search.OnChange(FCustomer.Search);
  Check('Beispiel Kundensuche: Weitertippen nimmt die Markierung zur' + #$00FC + 'ck',
    FCustomer.Search.ValidationState = pvsNone);
  FCustomer.Search.OnSubmit(FCustomer.Search, '');
  FCustomer.Search.ItemsEx.Clear;

  // Praxisbeispiel 2: Artikelliste filtern
  Check('Beispiel Artikelliste: anfangs alle 12 Artikel',
    (FFilter.List.Items.Count = 12) and (Pos('12 von 12', FFilter.CountLabel.Caption) > 0));
  FFilter.Search.OnSearch(FFilter.Search, 'kabel');
  Check('Beispiel Artikelliste: "kabel" filtert auf 5 Artikel',
    (FFilter.List.Items.Count = 5) and (Pos('5 von 12', FFilter.CountLabel.Caption) > 0) and
    (FFilter.Search.ValidationState = pvsNone));
  FFilter.Search.OnSearch(FFilter.Search, 'xyz');
  Check('Beispiel Artikelliste: ohne Treffer Warnung mit Hinweis',
    (FFilter.List.Items.Count = 0) and (FFilter.Search.ValidationState = pvsWarning) and
    (Pos('xyz', FFilter.Search.ValidationHint) > 0));
  FFilter.Search.OnSubmit(FFilter.Search, 'monitor');
  Check('Beispiel Artikelliste: Enter filtert und w' + #$00E4 + 'hlt den ersten Treffer',
    (FFilter.List.Items.Count = 2) and (FFilter.List.ItemIndex = 0) and
    (FFilter.List.Items[0] = 'Monitor 24 Zoll') and (FFilter.Search.ValidationState = pvsNone));
  FFilter.Search.OnSearch(FFilter.Search, '');
  Check('Beispiel Artikelliste: leeres Feld zeigt wieder alle Artikel',
    FFilter.List.Items.Count = 12);
end;

initialization
  RegisterShowcasePage('TPPGSearchEdit', TDemoShowSearchEditPage);

end.
