unit ExEditCustomer;

// Praxisbeispiel 2 zu TPPGEdit (Demo-Seite "Eingabe > TPPGEdit"):
// Kundenstammdaten mit ReadOnly (+ ReadOnlyStyle), MaxLength, NumbersOnly,
// TextHint, ValidationState/ValidationHint und RightButton (E-Mail schreiben,
// nur bei gueltiger Adresse frei). Speichern ist erst frei, wenn alles passt.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics, Vcl.ImgList,
  PPG.StyleManager, PPG.Controls.Field, PPG.Labels, PPG.Edit, PPG.Button;

type
  /// Formular "Kunde bearbeiten": Kundennummer nur lesen, Name Pflicht,
  /// PLZ fuenf Ziffern, E-Mail wird beim Tippen geprueft.
  TCustomerForm = class(TComponent)
  private
    FStyles: TPPGStyleManager;
    FNumber: TPPGEdit;
    FName: TPPGEdit;
    FZip: TPPGEdit;
    FCity: TPPGEdit;
    FMail: TPPGEdit;
    FSave: TPPGButton;
    FStatus: TPPGLabel;
    FLastSaved: string;
    function NewEdit(AParent: TWinControl; X, Y, W: Integer; const ALabel: string): TPPGEdit;
    procedure FieldChange(Sender: TObject);
    procedure MailButtonClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
  public
    constructor CreateForm(AOwner: TComponent; AParent: TWinControl;
      AImages: TCustomImageList; AStyles: TPPGStyleManager);
    property NumberEdit: TPPGEdit read FNumber;
    property NameEdit: TPPGEdit read FName;
    property ZipEdit: TPPGEdit read FZip;
    property CityEdit: TPPGEdit read FCity;
    property MailEdit: TPPGEdit read FMail;
    property SaveButton: TPPGButton read FSave;
    property Status: TPPGLabel read FStatus;
    property LastSaved: string read FLastSaved;
  end;

/// Einfache Pruefung: etwas vor dem @, danach ein Punkt, keine Leerzeichen.
function IsMailAddress(const S: string): Boolean;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
const
  ImgMail = 4;   // Symbol "Post" in der Bildliste

function IsMailAddress(const S: string): Boolean;
var
  P: Integer;
begin
  P := Pos('@', S);
  Result := (P > 1) and (Pos(' ', S) = 0) and (Pos('.', Copy(S, P + 2, MaxInt)) > 0) and
    (S[Length(S)] <> '.');
end;

function TCustomerForm.NewEdit(AParent: TWinControl; X, Y, W: Integer;
  const ALabel: string): TPPGEdit;
var
  Lbl: TPPGLabel;
begin
  Result := TPPGEdit.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(X, Y, W, 32);
  Result.StyleManager := FStyles;
  if ALabel <> '' then
  begin
    Lbl := TPPGLabel.Create(Self);
    Lbl.Parent := AParent;
    Lbl.SetBounds(16, Y + 6, 90, 20);
    Lbl.Caption := ALabel;
    Lbl.FocusControl := Result;   // Alt+Buchstabe springt ins Feld
  end;
end;

constructor TCustomerForm.CreateForm(AOwner: TComponent; AParent: TWinControl;
  AImages: TCustomImageList; AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  FStyles := AStyles;

  // Kundennummer: lesen und kopieren ja, aendern nein
  FNumber := NewEdit(AParent, 110, 16, 120, 'Kunden-Nr.:');
  FNumber.Text := 'K-10427';
  FNumber.ReadOnly := True;
  FNumber.TabStop := False;
  FNumber.ReadOnlyStyle.Color := $00F3F3F3;
  FNumber.ReadOnlyStyle.TextColor := clGrayText;

  // Name: Pflichtfeld, so lang wie die Datenbankspalte
  FName := NewEdit(AParent, 110, 56, 320, '&Name:');
  FName.MaxLength := 40;
  FName.TextHint := 'Firma oder Nachname';

  // PLZ: nur Ziffern, genau fuenf; Ort daneben
  FZip := NewEdit(AParent, 110, 96, 80, '&PLZ / Ort:');
  FZip.NumbersOnly := True;
  FZip.MaxLength := 5;
  FZip.TextHint := '12345';
  FCity := NewEdit(AParent, 198, 96, 232, '');
  FCity.MaxLength := 30;

  // E-Mail: Pruefung beim Tippen, Knopf rechts schreibt eine E-Mail
  FMail := NewEdit(AParent, 110, 136, 320, '&E-Mail:');
  FMail.TextHint := 'name@firma.de';
  FMail.Images := AImages;
  FMail.RightButton.ImageIndex := ImgMail;
  FMail.RightButton.Visible := True;
  FMail.OnRightButtonClick := MailButtonClick;

  FSave := TPPGButton.Create(Self);
  FSave.Parent := AParent;
  FSave.SetBounds(326, 184, 104, 32);
  FSave.Caption := '&Speichern';
  FSave.StyleManager := AStyles;
  FSave.OnClick := SaveClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 190, 300, 20);

  // Erst jetzt verbinden: alle Felder existieren, Text setzen oben loest nichts aus
  FName.OnChange := FieldChange;
  FZip.OnChange := FieldChange;
  FMail.OnChange := FieldChange;
  FieldChange(nil);
end;

procedure TCustomerForm.FieldChange(Sender: TObject);
var
  Mail: string;
begin
  // PLZ: unvollstaendig = Warnung, leer oder fuenf Ziffern = neutral
  if (FZip.Text <> '') and (Length(FZip.Text) < 5) then
  begin
    FZip.ValidationState := pvsWarning;
    FZip.ValidationHint := 'Die PLZ hat 5 Ziffern.';
  end
  else
  begin
    FZip.ValidationState := pvsNone;
    FZip.ValidationHint := '';
  end;

  // E-Mail: leer = neutral, gueltig = gruen, sonst Fehler mit Erklaerung
  Mail := Trim(FMail.Text);
  if Mail = '' then
  begin
    FMail.ValidationState := pvsNone;
    FMail.ValidationHint := '';
  end
  else if IsMailAddress(Mail) then
  begin
    FMail.ValidationState := pvsValid;
    FMail.ValidationHint := '';
  end
  else
  begin
    FMail.ValidationState := pvsError;
    FMail.ValidationHint := 'Bitte eine Adresse wie name@firma.de eingeben.';
  end;
  FMail.RightButton.Enabled := FMail.ValidationState = pvsValid;

  // Speichern erst, wenn der Name da ist und kein Feld einen Fehler zeigt
  FSave.Enabled := (Trim(FName.Text) <> '') and (FZip.ValidationState = pvsNone) and
    (FMail.ValidationState <> pvsError);
  if FSave.Enabled then
    FStatus.Caption := 'Bereit zum Speichern.'
  else
    FStatus.Caption := 'Name fehlt oder ein Feld ist rot/gelb.';
end;

procedure TCustomerForm.MailButtonClick(Sender: TObject);
begin
  // In der Anwendung z. B. ShellExecute mit 'mailto:' + Adresse
  FStatus.Caption := 'E-Mail an ' + Trim(FMail.Text) + ' wird geoeffnet.';
end;

procedure TCustomerForm.SaveClick(Sender: TObject);
begin
  FLastSaved := Trim(FName.Text);
  FStatus.Caption := 'Gespeichert: ' + FLastSaved;
end;
// EXAMPLE-END

end.
