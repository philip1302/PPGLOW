unit ExCheckBoxOrder;

// Praxisbeispiel 1 zu TPPGCheckBox (Demo-Seite "Auswahl > TPPGCheckBox"):
// Abschluss einer Bestellung mit Lieferadresse (Checked, OnChange),
// Newsletter (Hint) und AGB-Zustimmung (WordWrap, sperrt den Button).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Labels, PPG.Edit, PPG.Button, PPG.CheckBox;

type
  /// Bestellabschluss: Lieferadresse nur bei Bedarf, Newsletter freiwillig,
  /// Absenden erst nach Zustimmung zu den AGB.
  TOrderCheckout = class(TComponent)
  private
    FSameAddress: TPPGCheckBox;
    FDelivery: TPPGEdit;
    FNewsletter: TPPGCheckBox;
    FTerms: TPPGCheckBox;
    FSubmit: TPPGButton;
    FStatus: TPPGLabel;
    function NewCheckBox(AParent: TWinControl; Y: Integer; const ACaption: string;
      AStyles: TPPGStyleManager): TPPGCheckBox;
    procedure SameAddressChange(Sender: TObject);
    procedure TermsChange(Sender: TObject);
    procedure SubmitClick(Sender: TObject);
  public
    constructor CreateCheckout(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    property SameAddress: TPPGCheckBox read FSameAddress;
    property DeliveryEdit: TPPGEdit read FDelivery;
    property Newsletter: TPPGCheckBox read FNewsletter;
    property Terms: TPPGCheckBox read FTerms;
    property SubmitButton: TPPGButton read FSubmit;
    property Status: TPPGLabel read FStatus;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TOrderCheckout.NewCheckBox(AParent: TWinControl; Y: Integer;
  const ACaption: string; AStyles: TPPGStyleManager): TPPGCheckBox;
begin
  Result := TPPGCheckBox.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(16, Y, 400, 24);
  Result.Caption := ACaption;
  Result.StyleManager := AStyles;
end;

constructor TOrderCheckout.CreateCheckout(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);

  // Haeufigster Fall vorbelegt: Lieferung an die Rechnungsadresse.
  // Checked im Code loest nur OnChange aus, kein OnClick.
  FSameAddress := NewCheckBox(AParent, 16, '&Lieferadresse wie Rechnungsadresse', AStyles);
  FSameAddress.Checked := True;
  FSameAddress.OnChange := SameAddressChange;

  FDelivery := TPPGEdit.Create(Self);
  FDelivery.Parent := AParent;
  FDelivery.SetBounds(40, 46, 376, 32);
  FDelivery.TextHint := 'Abweichende Lieferadresse';
  FDelivery.StyleManager := AStyles;
  FDelivery.Enabled := False;

  // Freiwillig und deshalb nicht vorbelegt; der Hint erklaert den Nutzen
  FNewsletter := NewCheckBox(AParent, 92, '&Newsletter mit Angeboten abonnieren', AStyles);
  FNewsletter.Hint := 'Hoechstens einmal im Monat, jederzeit abbestellbar';
  FNewsletter.ShowHint := True;

  // Langer Text: WordWrap bricht um, die Hoehe reicht fuer zwei Zeilen
  FTerms := NewCheckBox(AParent, 126, 'Ich habe die &AGB und die Widerrufsbelehrung ' +
    'gelesen und akzeptiere sie.', AStyles);
  FTerms.WordWrap := True;
  FTerms.Height := 44;
  FTerms.OnChange := TermsChange;

  FSubmit := TPPGButton.Create(Self);
  FSubmit.Parent := AParent;
  FSubmit.SetBounds(16, 180, 180, 32);
  FSubmit.Caption := 'Bestellung absenden';
  FSubmit.StyleManager := AStyles;
  FSubmit.Enabled := False;   // erst nach Zustimmung zu den AGB
  FSubmit.OnClick := SubmitClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 224, 400, 20);
  FStatus.Caption := 'Noch nicht abgeschickt.';
end;

procedure TOrderCheckout.SameAddressChange(Sender: TObject);
begin
  // Das Feld braucht man nur, wenn die Lieferadresse abweicht
  FDelivery.Enabled := not FSameAddress.Checked;
  if FDelivery.Enabled and FDelivery.CanFocus then
    FDelivery.SetFocus;
end;

procedure TOrderCheckout.TermsChange(Sender: TObject);
begin
  FSubmit.Enabled := FTerms.Checked;
end;

procedure TOrderCheckout.SubmitClick(Sender: TObject);
var
  Address: string;
begin
  if FSameAddress.Checked then
    Address := 'Rechnungsadresse'
  else
    Address := Trim(FDelivery.Text);
  if FNewsletter.Checked then
    FStatus.Caption := 'Bestellt, Lieferung an ' + Address + ', mit Newsletter.'
  else
    FStatus.Caption := 'Bestellt, Lieferung an ' + Address + ', ohne Newsletter.';
end;
// EXAMPLE-END

end.
