unit ExEditSearch;

// Praxisbeispiel 1 zu TPPGEdit (Demo-Seite "Eingabe > TPPGEdit"):
// Kundensuche ueber einer Liste mit TextHint, ShowClearButton, LeftButton
// (Bild und DropDownMenu fuer den Suchbereich), OnChange (filtern),
// OnKeyDown (Enter uebernimmt den ersten Treffer) und ValidationState
// (Warnung, wenn nichts gefunden wurde).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Menus, Vcl.ImgList,
  PPG.StyleManager, PPG.Controls.Field, PPG.Labels, PPG.Edit, PPG.ListBox, PPG.Menus;

type
  TCustomerSearchIn = (siName, siCity);

  /// Kundensuche: Tippen filtert die Liste, der Knopf links waehlt, ob im
  /// Namen oder im Ort gesucht wird, Enter uebernimmt den ersten Treffer.
  TCustomerSearch = class(TComponent)
  private
    FCustomers: TStringList;   // Name=Ort
    FSearchIn: TCustomerSearchIn;
    FSearch: TPPGEdit;
    FSearchMenu: TPPGPopupMenu;
    FList: TPPGListBox;
    FStatus: TPPGLabel;
    FSelected: string;
    procedure SearchChange(Sender: TObject);
    procedure SearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure SearchInClick(Sender: TObject);
    procedure ApplyFilter;
  public
    constructor CreateSearch(AOwner: TComponent; AParent: TWinControl;
      AImages: TCustomImageList; AStyles: TPPGStyleManager);
    destructor Destroy; override;
    property SearchEdit: TPPGEdit read FSearch;
    property SearchMenu: TPPGPopupMenu read FSearchMenu;
    property ResultList: TPPGListBox read FList;
    property SearchIn: TCustomerSearchIn read FSearchIn;
    property Selected: string read FSelected;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
const
  ImgPerson = 14;   // Symbol "Person" in der Bildliste

constructor TCustomerSearch.CreateSearch(AOwner: TComponent; AParent: TWinControl;
  AImages: TCustomImageList; AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  FCustomers := TStringList.Create;
  FCustomers.Text := 'Albers GmbH=Bremen' + sLineBreak + 'Becker und Sohn=Hamburg' + sLineBreak +
    'Hansen Logistik=Kiel' + sLineBreak + 'Hanke Software=Berlin' + sLineBreak +
    'Krause Bau=Dresden' + sLineBreak + 'Meyer Elektro=Hamburg' + sLineBreak +
    'Schmidt Druck=Berlin' + sLineBreak + 'Wagner IT=Stuttgart';

  // Menue des linken Knopfs: worin gesucht wird
  FSearchMenu := TPPGPopupMenu.Create(Self);
  FSearchMenu.StyleManager := AStyles;
  FSearchMenu.Items.Add(NewItem('Suchen im Namen', 0, True, True, SearchInClick, 0, 'miName'));
  FSearchMenu.Items.Add(NewItem('Suchen im Ort', 0, False, True, SearchInClick, 0, 'miCity'));
  FSearchMenu.Items[0].RadioItem := True;
  FSearchMenu.Items[1].RadioItem := True;

  FSearch := TPPGEdit.Create(Self);
  FSearch.Parent := AParent;
  FSearch.SetBounds(16, 16, 414, 32);
  FSearch.StyleManager := AStyles;
  FSearch.TextHint := 'Kunde suchen (Name) ...';
  FSearch.TextHintVisibleOnFocus := True;   // Hinweis bleibt bis zum Tippen
  FSearch.ShowClearButton := True;          // "x" leert das Feld, OnChange folgt
  FSearch.Images := AImages;
  FSearch.LeftButton.ImageIndex := ImgPerson;
  FSearch.LeftButton.DropDownMenu := FSearchMenu;
  FSearch.LeftButton.Visible := True;
  FSearch.OnChange := SearchChange;
  FSearch.OnKeyDown := SearchKeyDown;

  FList := TPPGListBox.Create(Self);
  FList.Parent := AParent;
  FList.SetBounds(16, 56, 414, 150);
  FList.StyleManager := AStyles;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 214, 414, 20);

  ApplyFilter;
end;

destructor TCustomerSearch.Destroy;
begin
  FCustomers.Free;
  inherited Destroy;
end;

procedure TCustomerSearch.ApplyFilter;
var
  I: Integer;
  Term, Value: string;
begin
  Term := LowerCase(Trim(FSearch.Text));
  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;
    for I := 0 to FCustomers.Count - 1 do
    begin
      if FSearchIn = siName then
        Value := FCustomers.Names[I]
      else
        Value := FCustomers.ValueFromIndex[I];
      if (Term = '') or (Pos(Term, LowerCase(Value)) > 0) then
        FList.Items.Add(FCustomers.Names[I] + ' (' + FCustomers.ValueFromIndex[I] + ')');
    end;
  finally
    FList.Items.EndUpdate;
  end;
  // Keine Treffer: Warnung am Feld statt einer Meldung
  if FList.Items.Count = 0 then
  begin
    FSearch.ValidationState := pvsWarning;
    FSearch.ValidationHint := 'Kein Kunde gefunden. Suchbereich pruefen (Knopf links).';
  end
  else
  begin
    FSearch.ValidationState := pvsNone;
    FSearch.ValidationHint := '';
  end;
  FStatus.Caption := Format('%d von %d Kunden. Enter uebernimmt den ersten Treffer.',
    [FList.Items.Count, FCustomers.Count]);
end;

procedure TCustomerSearch.SearchChange(Sender: TObject);
begin
  ApplyFilter;
end;

procedure TCustomerSearch.SearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (FList.Items.Count > 0) then
  begin
    FSelected := FList.Items[0];
    FStatus.Caption := 'Uebernommen: ' + FSelected;
    Key := 0;
  end
  else if (Key = VK_DOWN) and (FList.Items.Count > 0) then
  begin
    // Pfeil runter springt in die Trefferliste
    FList.ItemIndex := 0;
    if FList.CanFocus then
      FList.SetFocus;
    Key := 0;
  end;
end;

procedure TCustomerSearch.SearchInClick(Sender: TObject);
begin
  TMenuItem(Sender).Checked := True;
  if TMenuItem(Sender).MenuIndex = 0 then
  begin
    FSearchIn := siName;
    FSearch.TextHint := 'Kunde suchen (Name) ...';
  end
  else
  begin
    FSearchIn := siCity;
    FSearch.TextHint := 'Kunde suchen (Ort) ...';
  end;
  ApplyFilter;
end;
// EXAMPLE-END

end.
