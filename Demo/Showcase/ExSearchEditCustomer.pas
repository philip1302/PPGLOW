unit ExSearchEditCustomer;

// Praxisbeispiel 1 zu TPPGSearchEdit (Demo-Seite "Eingabe > TPPGSearchEdit"):
// Kundensuche im Kopf einer Auftragsmaske. OnSearch fuellt die Vorschlaege
// (ItemsEx mit Detailzeile), OnSubmit uebernimmt den Kunden und meldet
// unbekannte Namen ueber ValidationState.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.Items, PPG.StyleManager, PPG.Controls.Field, PPG.ComboBox, PPG.Labels, PPG.SearchEdit;

type
  /// Kundensuche: Vorschlaege beim Tippen, Uebernahme mit Enter, Lupe oder
  /// Klick auf einen Vorschlag.
  TCustomerSearch = class(TComponent)
  private
    FPrompt: TPPGLabel;
    FSearch: TPPGSearchEdit;
    FResult: TPPGLabel;
    FCustomerNo: string;
    procedure SearchSuggest(Sender: TObject; const SearchText: string);
    procedure SearchSubmit(Sender: TObject; const SearchText: string);
    procedure SearchChange(Sender: TObject);
  public
    constructor CreateIn(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    property Search: TPPGSearchEdit read FSearch;
    property ResultLabel: TPPGLabel read FResult;
    /// Kundennummer des uebernommenen Kunden; '' = keiner.
    property CustomerNo: string read FCustomerNo;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
type
  TCustomer = record
    Name: string;
    City: string;
    No: string;
  end;

const
  // Steht hier stellvertretend fuer eine Abfrage in der Datenbank
  Customers: array[0..7] of TCustomer = (
    (Name: 'Becker Bau GmbH'; City: 'Bremen'; No: 'K-10017'),
    (Name: 'Becker Druck OHG'; City: 'Bonn'; No: 'K-10042'),
    (Name: 'Hansen Logistik AG'; City: 'Kiel'; No: 'K-10103'),
    (Name: 'Klein IT-Service'; City: 'Mainz'; No: 'K-10155'),
    (Name: 'Meyer & Sohn KG'; City: 'Leipzig'; No: 'K-10208'),
    (Name: 'Nordbau Schulte'; City: 'Hamburg'; No: 'K-10231'),
    (Name: 'Schneider Elektro'; City: 'Dresden'; No: 'K-10307'),
    (Name: 'Wagner Holzbau'; City: 'Essen'; No: 'K-10359'));

constructor TCustomerSearch.CreateIn(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  FPrompt := TPPGLabel.Create(Self);
  FPrompt.Parent := AParent;
  FPrompt.SetBounds(16, 16, 414, 20);
  FPrompt.Caption := '&Kunde des neuen Auftrags:';

  FSearch := TPPGSearchEdit.Create(Self);
  FSearch.Parent := AParent;
  FSearch.SetBounds(16, 40, 320, 32);
  FSearch.StyleManager := AStyles;
  FSearch.TextHint := 'Name eingeben, z. B. bau';
  FSearch.SearchDelay := 250;      // erst suchen, wenn der Anwender kurz innehaelt
  FSearch.FilterMode := fmNone;    // die "Datenbank" filtert schon selbst
  FSearch.DropDownCount := 6;
  FSearch.OnSearch := SearchSuggest;
  FSearch.OnSubmit := SearchSubmit;
  FSearch.OnChange := SearchChange;
  FPrompt.FocusControl := FSearch;

  FResult := TPPGLabel.Create(Self);
  FResult.Parent := AParent;
  FResult.SetBounds(16, 88, 414, 20);
  FResult.Caption := 'Noch kein Kunde ausgesucht.';
end;

procedure TCustomerSearch.SearchSuggest(Sender: TObject; const SearchText: string);
var
  Key: string;
  I: Integer;
  Item: TPPGItem;
begin
  // SearchDelay ms nach dem Tippen: Vorschlaege neu fuellen. Danach zeigt
  // das Feld die Liste von selbst.
  Key := LowerCase(Trim(SearchText));
  FSearch.ItemsEx.BeginUpdate;
  try
    FSearch.ItemsEx.Clear;
    if Length(Key) >= 2 then
      for I := 0 to High(Customers) do
        if Pos(Key, LowerCase(Customers[I].Name)) > 0 then
        begin
          Item := FSearch.ItemsEx.Add(Customers[I].Name);
          Item.Detail := Customers[I].City + ', ' + Customers[I].No;
        end;
  finally
    FSearch.ItemsEx.EndUpdate;
  end;
end;

procedure TCustomerSearch.SearchSubmit(Sender: TObject; const SearchText: string);
var
  I: Integer;
begin
  // Enter, Lupe oder Klick auf einen Vorschlag: Kunden uebernehmen
  FCustomerNo := '';
  for I := 0 to High(Customers) do
    if SameText(Customers[I].Name, Trim(SearchText)) then
    begin
      FCustomerNo := Customers[I].No;
      FResult.Caption := 'Kunde ' + Customers[I].No + ': ' + Customers[I].Name + ', ' +
        Customers[I].City;
    end;
  if FCustomerNo <> '' then
  begin
    FSearch.ValidationState := pvsValid;
    FSearch.ValidationHint := '';
  end
  else if Trim(SearchText) = '' then
  begin
    FSearch.ValidationState := pvsNone;
    FResult.Caption := 'Noch kein Kunde ausgesucht.';
  end
  else
  begin
    FSearch.ValidationState := pvsError;
    FSearch.ValidationHint := 'Kein Kunde mit diesem Namen. Bitte einen Vorschlag nehmen.';
    FResult.Caption := 'Kein Kunde "' + Trim(SearchText) + '" gefunden.';
  end;
end;

procedure TCustomerSearch.SearchChange(Sender: TObject);
begin
  // Wer weitertippt, hat den Kunden wieder abgewaehlt
  if FSearch.ValidationState <> pvsNone then
  begin
    FSearch.ValidationState := pvsNone;
    FSearch.ValidationHint := '';
  end;
end;
// EXAMPLE-END

end.
