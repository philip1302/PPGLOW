unit ExSpinEditOrder;

// Praxisbeispiel 1 zu TPPGSpinEdit (Demo-Seite "Eingabe > TPPGSpinEdit"):
// Bestellposition mit Menge (Min/Max = Lagerbestand) und Rabatt in
// 5er-Schritten (Increment, EditorEnabled = False); OnChange rechnet die
// Summe neu.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics,
  PPG.StyleManager, PPG.Labels, PPG.SpinEdit;

type
  /// Bestellposition: Menge 1 bis Lagerbestand, Rabatt 0 bis 30 % in
  /// 5er-Schritten, Summe wird bei jeder Aenderung neu berechnet.
  TOrderLine = class(TComponent)
  private
    FQuantity: TPPGSpinEdit;
    FDiscount: TPPGSpinEdit;
    FTotalLabel: TPPGLabel;
    FPriceCents: Integer;
    FTotalCents: Integer;
    function NewLabel(AParent: TWinControl; Y: Integer;
      const ACaption: string): TPPGLabel;
    procedure ValuesChange(Sender: TObject);
  public
    constructor CreateLine(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    property Quantity: TPPGSpinEdit read FQuantity;
    property Discount: TPPGSpinEdit read FDiscount;
    /// Summe der Position in Cent.
    property TotalCents: Integer read FTotalCents;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
const
  StockOnHand = 50; // Lagerbestand: mehr kann man nicht bestellen

function TOrderLine.NewLabel(AParent: TWinControl; Y: Integer;
  const ACaption: string): TPPGLabel;
begin
  Result := TPPGLabel.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(16, Y, 140, 20);
  Result.Caption := ACaption;
end;

constructor TOrderLine.CreateLine(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  FPriceCents := 490;
  NewLabel(AParent, 16, 'Artikel:').Width := 80;
  NewLabel(AParent, 16, 'Druckerpapier A4, 500 Blatt, 4,90 EUR').SetBounds(100, 16, 330, 20);

  // Menge: mindestens 1, hoechstens der Lagerbestand. Zahlen rechtsbuendig.
  FQuantity := TPPGSpinEdit.Create(Self);
  FQuantity.Parent := AParent;
  FQuantity.SetBounds(160, 52, 110, 32);
  FQuantity.StyleManager := AStyles;
  FQuantity.Min := 1;
  FQuantity.Max := StockOnHand;
  FQuantity.Value := 1;
  FQuantity.Alignment := taRightJustify;
  FQuantity.OnChange := ValuesChange;
  NewLabel(AParent, 58, '&Menge (Stk.):').FocusControl := FQuantity;
  NewLabel(AParent, 58, Format('Lager: %d', [StockOnHand])).SetBounds(284, 58, 140, 20);

  // Rabatt: nur feste Stufen 0, 5, 10 ... 30 %. Tippen ist gesperrt,
  // Pfeile, Pfeiltasten und Mausrad springen um Increment.
  FDiscount := TPPGSpinEdit.Create(Self);
  FDiscount.Parent := AParent;
  FDiscount.SetBounds(160, 96, 110, 32);
  FDiscount.StyleManager := AStyles;
  FDiscount.Min := 0;
  FDiscount.Max := 30;
  FDiscount.Increment := 5;
  FDiscount.EditorEnabled := False;
  FDiscount.Alignment := taRightJustify;
  FDiscount.OnChange := ValuesChange;
  NewLabel(AParent, 102, '&Rabatt (%):').FocusControl := FDiscount;

  FTotalLabel := NewLabel(AParent, 148, '');
  FTotalLabel.Width := 400;
  FTotalLabel.Font.Style := [fsBold];
  ValuesChange(nil);
end;

procedure TOrderLine.ValuesChange(Sender: TObject);
begin
  // Value ist immer im Bereich Min..Max, auch waehrend getippt wird
  FTotalCents := FQuantity.Value * FPriceCents * (100 - FDiscount.Value) div 100;
  FTotalLabel.Caption := Format('Summe: %d x 4,90 EUR - %d %% = %d,%.2d EUR',
    [FQuantity.Value, FDiscount.Value, FTotalCents div 100, FTotalCents mod 100]);
end;
// EXAMPLE-END

end.
