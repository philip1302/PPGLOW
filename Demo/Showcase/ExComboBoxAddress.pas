unit ExComboBoxAddress;

// Praxisbeispiel 1 zu TPPGComboBox (Demo-Seite "Auswahl > TPPGComboBox"):
// Kundenadresse mit Anrede und Land (nur Auswahl, sortiert, OnSelect stellt
// das PLZ-Feld passend ein) und Branche (freie Eingabe mit Vorschlaegen).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls,
  PPG.StyleManager, PPG.Controls.Field, PPG.Labels, PPG.Edit, PPG.ComboBox, PPG.Button;

type
  /// Kundenadresse: Anrede und Land nur aus der Liste, Branche frei mit
  /// Vorschlaegen. Das Land stellt Vorwahl und PLZ-Laenge ein.
  TAddressForm = class(TComponent)
  private
    FStyles: TPPGStyleManager;
    FSalutation: TPPGComboBox;
    FCountry: TPPGComboBox;
    FZip: TPPGEdit;
    FCountryInfo: TPPGLabel;
    FIndustry: TPPGComboBox;
    FSave: TPPGButton;
    FStatus: TPPGLabel;
    function NewLabel(AParent: TWinControl; X, Y, W: Integer; const ACaption: string): TPPGLabel;
    function NewCombo(AParent: TWinControl; X, Y, W: Integer): TPPGComboBox;
    procedure CountrySelect(Sender: TObject);
    procedure SaveClick(Sender: TObject);
  public
    constructor CreateForm(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    /// Pflichtfelder pruefen und markieren; True = alles in Ordnung.
    function Validate: Boolean;
    property Salutation: TPPGComboBox read FSalutation;
    property Country: TPPGComboBox read FCountry;
    property Zip: TPPGEdit read FZip;
    property CountryInfo: TPPGLabel read FCountryInfo;
    property Industry: TPPGComboBox read FIndustry;
    property SaveButton: TPPGButton read FSave;
    property Status: TPPGLabel read FStatus;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
type
  TCountryInfo = record
    Name: string;
    Dial: string;
    ZipLength: Integer;
  end;

const
  // Bewusst unsortiert: Sorted = True ordnet die Liste alphabetisch
  Countries: array[0..6] of TCountryInfo = (
    (Name: 'Deutschland'; Dial: '+49'; ZipLength: 5),
    (Name: 'Schweiz'; Dial: '+41'; ZipLength: 4),
    (Name: 'Frankreich'; Dial: '+33'; ZipLength: 5),
    (Name: 'Niederlande'; Dial: '+31'; ZipLength: 7),
    (Name: 'Belgien'; Dial: '+32'; ZipLength: 4),
    (Name: 'Italien'; Dial: '+39'; ZipLength: 5),
    (Name: 'Polen'; Dial: '+48'; ZipLength: 6));

function TAddressForm.NewLabel(AParent: TWinControl; X, Y, W: Integer;
  const ACaption: string): TPPGLabel;
begin
  Result := TPPGLabel.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(X, Y, W, 20);
  Result.Caption := ACaption;
end;

function TAddressForm.NewCombo(AParent: TWinControl; X, Y, W: Integer): TPPGComboBox;
begin
  Result := TPPGComboBox.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(X, Y, W, 32);
  Result.StyleManager := FStyles;
end;

constructor TAddressForm.CreateForm(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
var
  I: Integer;
  Lbl: TPPGLabel;
begin
  inherited Create(AOwner);
  FStyles := AStyles;

  // Anrede: nur Eintraege der Liste, feste fachliche Reihenfolge
  Lbl := NewLabel(AParent, 16, 16, 120, '&Anrede');
  FSalutation := NewCombo(AParent, 16, 38, 120);
  Lbl.FocusControl := FSalutation;
  FSalutation.Style := csDropDownList;
  FSalutation.Items.Text := 'Herr' + sLineBreak + 'Frau' + sLineBreak + 'Divers' +
    sLineBreak + 'Firma';
  FSalutation.DropDownCount := 4;   // genau so viele Zeilen wie Eintraege
  FSalutation.ItemIndex := 3;       // Vorgabe aus dem Code: kein Ereignis

  // Land: Pflichtfeld, alphabetisch; das Objekt merkt sich den Tabellenindex
  Lbl := NewLabel(AParent, 152, 16, 200, '&Land');
  FCountry := NewCombo(AParent, 152, 38, 200);
  Lbl.FocusControl := FCountry;
  FCountry.Style := csDropDownList;
  FCountry.Sorted := True;
  FCountry.TextHint := 'Bitte Land angeben';
  for I := 0 to High(Countries) do
    FCountry.Items.AddObject(Countries[I].Name, TObject(NativeInt(I)));
  FCountry.OnSelect := CountrySelect;

  // PLZ: die Laenge kommt aus dem gewaehlten Land
  NewLabel(AParent, 16, 82, 120, 'PLZ');
  FZip := TPPGEdit.Create(Self);
  FZip.Parent := AParent;
  FZip.SetBounds(16, 104, 120, 32);
  FZip.StyleManager := AStyles;
  FZip.Enabled := False;   // erst mit einem Land
  FCountryInfo := NewLabel(AParent, 152, 110, 260, 'Erst das Land angeben.');

  // Branche: Liste nur als Vorschlag, eigener Text erlaubt (csDropDown)
  Lbl := NewLabel(AParent, 16, 148, 336, '&Branche');
  FIndustry := NewCombo(AParent, 16, 170, 336);
  Lbl.FocusControl := FIndustry;
  FIndustry.Items.Text := 'Dienstleistung' + sLineBreak + 'Handel' +
    sLineBreak + 'Handwerk' + sLineBreak + 'Industrie' + sLineBreak + 'Einzelhandel' +
    sLineBreak + 'Verwaltung';
  FIndustry.Sorted := True;
  FIndustry.AutoComplete := True;     // "Hand" ergaenzt zu "Handel"
  FIndustry.ShowClearButton := True;
  FIndustry.MaxLength := 40;          // Laenge des Datenbankfeldes
  FIndustry.TextHint := 'Aus der Liste oder eigener Text';

  FSave := TPPGButton.Create(Self);
  FSave.Parent := AParent;
  FSave.SetBounds(16, 218, 120, 32);
  FSave.Caption := 'Speichern';
  FSave.StyleManager := AStyles;
  FSave.OnClick := SaveClick;
  FStatus := NewLabel(AParent, 152, 224, 260, '');
end;

procedure TAddressForm.CountrySelect(Sender: TObject);
var
  C: TCountryInfo;
begin
  // OnSelect kommt nur bei Bedienung; Objects[] haelt den Tabellenindex
  // auch nach dem Sortieren
  C := Countries[NativeInt(FCountry.Items.Objects[FCountry.ItemIndex])];
  FZip.Enabled := True;
  FZip.MaxLength := C.ZipLength;
  FZip.TextHint := StringOfChar('0', C.ZipLength);
  FCountryInfo.Caption := Format('Vorwahl %s, PLZ %d-stellig', [C.Dial, C.ZipLength]);
  // Eine Fehlermarkierung verschwindet, sobald gewaehlt wurde
  FCountry.ValidationState := pvsNone;
  FCountry.ValidationHint := '';
end;

function TAddressForm.Validate: Boolean;
begin
  Result := FCountry.ItemIndex >= 0;
  if Result then
    FCountry.ValidationState := pvsNone
  else
  begin
    FCountry.ValidationState := pvsError;
    FCountry.ValidationHint := 'Das Land fehlt.';
  end;
end;

procedure TAddressForm.SaveClick(Sender: TObject);
begin
  if not Validate then
    FStatus.Caption := 'Land fehlt.'
  else
    // Branche: Text ist der Wert, auch ohne passenden Listeneintrag
    FStatus.Caption := Format('Gespeichert: %s, %s, %s',
      [FSalutation.Text, FCountry.Text, FIndustry.Text]);
end;
// EXAMPLE-END

end.
