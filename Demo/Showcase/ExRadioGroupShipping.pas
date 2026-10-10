unit ExRadioGroupShipping;

// Praxisbeispiel 1 zu TPPGRadioGroup (Demo-Seite "Auswahl > TPPGRadioGroup"):
// Versandart im Bestellformular als Auswahlkacheln (ChoiceStyle = csCards)
// mit Beschreibung, Symbol, Wert und gesperrtem Eintrag je Kachel (ItemsEx),
// Pflichtauswahl mit ValidationState/ValidationHint und OnChange.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.Controls.Field, PPG.StyleManager, PPG.Labels, PPG.Button, PPG.RadioGroup;

type
  /// Versandart im Bestellformular: drei Kacheln untereinander, eine gesperrt.
  /// Bestellen geht erst, wenn eine Versandart gewaehlt ist.
  TShippingChoice = class(TComponent)
  private
    FShipping: TPPGRadioGroup;
    FTotal: TPPGLabel;
    FOrder: TPPGButton;
    FStatus: TPPGLabel;
    procedure AddShipping(const ACaption, ADescription: string; AIcon: Word;
      const ACents: string);
    procedure ShippingChange(Sender: TObject);
    procedure OrderClick(Sender: TObject);
  public
    constructor CreateChoice(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    /// Versandkosten in Cent aus dem Value der gewaehlten Kachel; -1 = keine.
    function ShippingCents: Integer;
    property Shipping: TPPGRadioGroup read FShipping;
    property OrderButton: TPPGButton read FOrder;
    property Total: TPPGLabel read FTotal;
    property Status: TPPGLabel read FStatus;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
const
  GoodsCents = 12000;   // Warenwert 120,00 EUR

constructor TShippingChoice.CreateChoice(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);

  // Kacheln: jede mit Symbol, Titel und Beschreibung
  FShipping := TPPGRadioGroup.Create(Self);
  FShipping.Parent := AParent;
  FShipping.SetBounds(16, 16, 418, 290);
  FShipping.Caption := '&Versandart';
  FShipping.ChoiceStyle := csCards;
  FShipping.Columns := 1;          // untereinander: Platz fuer die Beschreibung
  FShipping.ShowHint := True;          // Hint je Eintrag
  FShipping.StyleManager := AStyles;
  AddShipping('Standard', '3 bis 5 Werktage', $E715, '490');
  AddShipping('Express', 'Morgen bei Ihnen', $E916, '990');
  AddShipping('Abholung', 'Filiale geschlossen', $E80F, '0');
  FShipping.ItemsEx[1].Hint := 'Bei Bestellung bis 14 Uhr';
  FShipping.ItemsEx[2].Enabled := False;   // sichtbar, aber nicht waehlbar
  // ItemIndex bleibt -1: Der Kunde soll bewusst waehlen (Pflichtauswahl)
  FShipping.OnChange := ShippingChange;

  FTotal := TPPGLabel.Create(Self);
  FTotal.Parent := AParent;
  FTotal.SetBounds(16, 316, 418, 20);
  FTotal.Caption := 'Warenwert 120,00 EUR, Versand noch offen';

  FOrder := TPPGButton.Create(Self);
  FOrder.Parent := AParent;
  FOrder.SetBounds(16, 348, 130, 32);
  FOrder.Caption := '&Bestellen';
  FOrder.StyleManager := AStyles;
  FOrder.OnClick := OrderClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(160, 354, 274, 20);
  FStatus.Caption := '';
end;

procedure TShippingChoice.AddShipping(const ACaption, ADescription: string; AIcon: Word;
  const ACents: string);
var
  It: TPPGChoiceItem;
begin
  It := FShipping.ItemsEx.Add;
  It.Caption := ACaption;
  It.Description := ADescription;
  It.Icon := AIcon;          // Zeichen aus Segoe Fluent Icons
  It.Value := ACents;        // Wert fuer das Programm, unabhaengig vom Text
end;

function TShippingChoice.ShippingCents: Integer;
begin
  // Value statt ItemIndex: Reihenfolge und Texte duerfen sich aendern
  Result := StrToIntDef(FShipping.Value, -1);
end;

procedure TShippingChoice.ShippingChange(Sender: TObject);
begin
  // Der Kunde hat gewaehlt: Fehlermarke weg, Summe neu
  FShipping.ValidationState := pvsNone;
  FStatus.Caption := '';
  FTotal.Caption := Format('Warenwert 120,00 EUR + Versand %.2f EUR = %.2f EUR',
    [ShippingCents / 100, (GoodsCents + ShippingCents) / 100]);
end;

procedure TShippingChoice.OrderClick(Sender: TObject);
begin
  if FShipping.ItemIndex < 0 then
  begin
    // Pflichtauswahl fehlt: Gruppe rot markieren, Text als Tooltip
    FShipping.ValidationHint := 'Bitte eine Versandart anklicken.';
    FShipping.ValidationState := pvsError;
    FStatus.Caption := 'Versandart fehlt.';
    Exit;
  end;
  FStatus.Caption := 'Bestellt mit ' + FShipping.ItemsEx[FShipping.ItemIndex].Caption + '.';
end;
// EXAMPLE-END

end.
