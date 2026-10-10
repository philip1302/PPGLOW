unit ExNumberEditInvoice;

// Praxisbeispiel 1 zu TPPGNumberEdit (Demo-Seite "Eingabe > TPPGNumberEdit"):
// Rechnungsposition mit Menge (nkInteger, Spin-Buttons), Einzelpreis
// (nkCurrency, Rechnen im Feld), Rabatt (nkPercent, Min/Max) und dem
// berechneten Gesamtbetrag (ReadOnly). OnChange rechnet die Summe neu.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics,
  PPG.NumberFormat, PPG.StyleManager, PPG.Labels, PPG.NumberEdit;

type
  /// Eine Rechnungsposition: Menge x Einzelpreis abzueglich Rabatt.
  TInvoiceLine = class(TComponent)
  private
    FStyles: TPPGStyleManager;
    FQuantity: TPPGNumberEdit;
    FPrice: TPPGNumberEdit;
    FDiscount: TPPGNumberEdit;
    FTotal: TPPGNumberEdit;
    function NewField(AParent: TWinControl; Y: Integer; const ACaption: string;
      AKind: TPPGNumberKind): TPPGNumberEdit;
    procedure ValueChanged(Sender: TObject);
  public
    constructor CreateLine(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    /// Gesamt = Menge * Einzelpreis * (100 - Rabatt) / 100
    procedure Recalculate;
    property Quantity: TPPGNumberEdit read FQuantity;
    property Price: TPPGNumberEdit read FPrice;
    property Discount: TPPGNumberEdit read FDiscount;
    property Total: TPPGNumberEdit read FTotal;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TInvoiceLine.NewField(AParent: TWinControl; Y: Integer; const ACaption: string;
  AKind: TPPGNumberKind): TPPGNumberEdit;
var
  Lbl: TPPGLabel;
begin
  Lbl := TPPGLabel.Create(Self);
  Lbl.Parent := AParent;
  Lbl.SetBounds(16, Y + 6, 150, 20);
  Lbl.Caption := ACaption;

  Result := TPPGNumberEdit.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(176, Y, 180, 32);
  Result.Kind := AKind;
  Result.StyleManager := FStyles;
  Result.OnChange := ValueChanged;
  Lbl.FocusControl := Result;
end;

constructor TInvoiceLine.CreateLine(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
var
  Tip: TPPGLabel;
begin
  inherited Create(AOwner);
  FStyles := AStyles;

  // Menge: ganze Stueck, 1 bis 9999, Spin-Buttons und Bild auf/ab = 10
  FQuantity := NewField(AParent, 16, '&Menge (Stk.):', nkInteger);
  FQuantity.Min := 1;
  FQuantity.Max := 9999;
  FQuantity.LargeIncrement := 10;
  FQuantity.ShowSpinButtons := True;
  FQuantity.Value := 1;

  // Einzelpreis: Geldbetrag; man darf rechnen ("3*19,99")
  FPrice := NewField(AParent, 60, '&Einzelpreis:', nkCurrency);
  FPrice.Min := 0;
  FPrice.Max := 1000000;
  FPrice.AllowExpressions := True;
  FPrice.Increment := 0.05;
  FPrice.Hint := 'Netto je Stueck; Rechnen erlaubt, z. B. 3*19,99';
  FPrice.ShowHint := True;

  // Rabatt: Prozent mit einer Nachkommastelle, nie ueber 100
  FDiscount := NewField(AParent, 104, '&Rabatt:', nkPercent);
  FDiscount.Decimals := 1;
  FDiscount.Min := 0;
  FDiscount.Max := 100;
  FDiscount.Increment := 0.5;
  FDiscount.LargeIncrement := 5;
  FDiscount.ShowSpinButtons := True;

  // Gesamt: berechnet, nur lesen; Tab springt darueber hinweg
  FTotal := NewField(AParent, 156, 'Gesamt netto:', nkCurrency);
  FTotal.ReadOnly := True;
  FTotal.TabStop := False;
  FTotal.ReadOnlyStyle.FontStyle := [fsBold];

  Tip := TPPGLabel.Create(Self);
  Tip.Parent := AParent;
  Tip.SetBounds(16, 204, 418, 20);
  Tip.Caption := 'Enter oder Tab uebernimmt den Wert, Esc verwirft die Eingabe.';
  Recalculate;
end;

procedure TInvoiceLine.ValueChanged(Sender: TObject);
begin
  // Kommt nur bei uebernommenen Aenderungen (Enter, Tab, Spin), nicht je Taste
  Recalculate;
end;

procedure TInvoiceLine.Recalculate;
begin
  // In Currency rechnen: keine Rundungsfehler bei Geld
  FTotal.AsCurrency := FPrice.AsCurrency * FQuantity.AsInteger *
    (100 - FDiscount.Value) / 100;
end;
// EXAMPLE-END

end.
