unit ExRadioButtonShipping;

// Praxisbeispiel 1 zu TPPGRadioButton (Demo-Seite "Auswahl > TPPGRadioButton"):
// Versandart in einem Bestellformular. Die drei Optionen liegen in einer
// GroupBox (gleicher Parent = eine Gruppe), ein gemeinsames OnClick wertet
// die gewaehlte Option ueber Tag aus, Enabled sperrt Express bei Sperrgut.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Labels, PPG.Edit, PPG.CheckBox, PPG.GroupBox, PPG.RadioButton;

type
  /// Versandart im Bestellformular: genau eine Option ist gewaehlt, die
  /// Versandkosten und das Adressfeld folgen der Auswahl.
  TShippingChoice = class(TComponent)
  private
    FStyles: TPPGStyleManager;
    FBox: TPPGGroupBox;
    FStandard: TPPGRadioButton;
    FExpress: TPPGRadioButton;
    FPickup: TPPGRadioButton;
    FBulky: TPPGCheckBox;
    FAddress: TPPGEdit;
    FCostLabel: TPPGLabel;
    function NewOption(Y, ACents: Integer; const ACaption: string): TPPGRadioButton;
    procedure OptionClick(Sender: TObject);
    procedure BulkyClick(Sender: TObject);
    procedure UpdateCosts;
    function GetCostCents: Integer;
  public
    constructor CreateChoice(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    property Standard: TPPGRadioButton read FStandard;
    property Express: TPPGRadioButton read FExpress;
    property Pickup: TPPGRadioButton read FPickup;
    property Bulky: TPPGCheckBox read FBulky;
    property Address: TPPGEdit read FAddress;
    property CostLabel: TPPGLabel read FCostLabel;
    /// Versandkosten der gewaehlten Option in Cent.
    property CostCents: Integer read GetCostCents;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TShippingChoice.NewOption(Y, ACents: Integer; const ACaption: string): TPPGRadioButton;
begin
  // Alle Optionen liegen in derselben GroupBox: Das macht sie zu einer Gruppe
  Result := TPPGRadioButton.Create(Self);
  Result.Parent := FBox;
  Result.SetBounds(16, Y, 380, 24);
  Result.Caption := ACaption;
  Result.Tag := ACents;               // Preis der Option, ausgewertet in OnClick
  Result.StyleManager := FStyles;
  Result.OnClick := OptionClick;      // ein Handler fuer alle Optionen
end;

constructor TShippingChoice.CreateChoice(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  FStyles := AStyles;

  FBox := TPPGGroupBox.Create(Self);
  FBox.Parent := AParent;
  FBox.SetBounds(16, 16, 414, 132);
  FBox.Caption := 'Versandart';
  FBox.StyleManager := AStyles;

  FStandard := NewOption(32, 490, '&Standard (3-5 Werktage) - 4,90 EUR');
  FExpress := NewOption(64, 990, '&Express (Lieferung morgen) - 9,90 EUR');
  FPickup := NewOption(96, 0, '&Abholung im Lager - kostenlos');
  FStandard.Checked := True;          // sinnvolle Vorauswahl statt keiner

  FBulky := TPPGCheckBox.Create(Self);
  FBulky.Parent := AParent;
  FBulky.SetBounds(16, 160, 414, 24);
  FBulky.Caption := 'Sperrgut (kein Express-Versand)';
  FBulky.StyleManager := AStyles;
  FBulky.OnClick := BulkyClick;

  FAddress := TPPGEdit.Create(Self);
  FAddress.Parent := AParent;
  FAddress.SetBounds(16, 192, 414, 32);
  FAddress.TextHint := 'Lieferadresse';
  FAddress.StyleManager := AStyles;

  FCostLabel := TPPGLabel.Create(Self);
  FCostLabel.Parent := AParent;
  FCostLabel.SetBounds(16, 236, 414, 20);
  UpdateCosts;
end;

procedure TShippingChoice.OptionClick(Sender: TObject);
begin
  // Beim Klick ist die Option schon eingeschaltet, die anderen sind aus
  UpdateCosts;
end;

procedure TShippingChoice.BulkyClick(Sender: TObject);
begin
  // Was nicht geht, sperren; war Express gewaehlt, auf Standard ausweichen
  FExpress.Enabled := not FBulky.Checked;
  if FBulky.Checked and FExpress.Checked then
    FStandard.Checked := True;
  UpdateCosts;
end;

function TShippingChoice.GetCostCents: Integer;
begin
  if FExpress.Checked then
    Result := FExpress.Tag
  else if FPickup.Checked then
    Result := FPickup.Tag
  else
    Result := FStandard.Tag;
end;

procedure TShippingChoice.UpdateCosts;
begin
  // Bei Abholung braucht es keine Lieferadresse
  FAddress.Enabled := not FPickup.Checked;
  FCostLabel.Caption := Format('Versandkosten: %d,%.2d EUR', [CostCents div 100, CostCents mod 100]);
end;
// EXAMPLE-END

end.
