unit ExNumberEditStock;

// Praxisbeispiel 2 zu TPPGNumberEdit (Demo-Seite "Eingabe > TPPGNumberEdit"):
// Lagerdaten eines Artikels mit Bestand, optionalem Meldebestand (AllowNull,
// TextHint), Gewicht (Decimals 3) und Einkaufspreis in CHF (CurrencyString,
// ohne Rechnen). Liegt der Bestand unter dem Meldebestand, warnt das Feld
// ueber ValidationState.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.NumberFormat, PPG.Controls.Field, PPG.StyleManager, PPG.Labels, PPG.NumberEdit;

type
  /// Lagerdaten eines Artikels mit Warnung "nachbestellen".
  TStockData = class(TComponent)
  private
    FStyles: TPPGStyleManager;
    FStock: TPPGNumberEdit;
    FReorder: TPPGNumberEdit;
    FWeight: TPPGNumberEdit;
    FPurchase: TPPGNumberEdit;
    FStatus: TPPGLabel;
    function NewField(AParent: TWinControl; Y: Integer; const ACaption: string;
      AKind: TPPGNumberKind): TPPGNumberEdit;
    procedure StockChanged(Sender: TObject);
  public
    constructor CreateStock(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    /// Bestand mit Meldebestand vergleichen und die Warnung setzen.
    procedure CheckStock;
    function NeedsReorder: Boolean;
    property Stock: TPPGNumberEdit read FStock;
    property Reorder: TPPGNumberEdit read FReorder;
    property Weight: TPPGNumberEdit read FWeight;
    property Purchase: TPPGNumberEdit read FPurchase;
    property Status: TPPGLabel read FStatus;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TStockData.NewField(AParent: TWinControl; Y: Integer; const ACaption: string;
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
  Lbl.FocusControl := Result;
end;

constructor TStockData.CreateStock(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  FStyles := AStyles;

  // Bestand: ganze Stueck, nie negativ
  FStock := NewField(AParent, 16, '&Bestand (Stk.):', nkInteger);
  FStock.Min := 0;
  FStock.Max := 99999;
  FStock.ShowSpinButtons := True;
  FStock.Value := 25;
  FStock.OnChange := StockChanged;

  // Meldebestand: optional. Leer = keine Warnung (IsNull), nicht 0
  FReorder := NewField(AParent, 60, '&Meldebestand:', nkInteger);
  FReorder.AllowNull := True;
  FReorder.TextHint := 'leer = keine Warnung';
  FReorder.Min := 0;
  FReorder.Max := 99999;
  FReorder.Value := 10;
  FReorder.OnChange := StockChanged;

  // Gewicht in kg mit Gramm-Genauigkeit
  FWeight := NewField(AParent, 104, '&Gewicht (kg):', nkFloat);
  FWeight.Decimals := 3;
  FWeight.Value := 1.25;

  // Einkaufspreis beim Lieferanten in Franken; nur Zahlen, kein Rechnen
  FPurchase := NewField(AParent, 148, '&Einkauf (CHF):', nkCurrency);
  FPurchase.CurrencyString := 'CHF';
  FPurchase.AllowExpressions := False;
  FPurchase.AsCurrency := 1234.5;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 196, 418, 20);
  CheckStock;
end;

procedure TStockData.StockChanged(Sender: TObject);
begin
  CheckStock;
end;

function TStockData.NeedsReorder: Boolean;
begin
  // Ohne Meldebestand (leeres Feld) gibt es keine Warnung
  Result := (not FReorder.IsNull) and (FStock.AsInteger < FReorder.AsInteger);
end;

procedure TStockData.CheckStock;
begin
  if NeedsReorder then
  begin
    FStock.ValidationState := pvsWarning;
    FStock.ValidationHint := 'Bestand unter Meldebestand - bitte nachbestellen';
    FStatus.Caption := Format('Nachbestellen: %d Stk. fehlen bis zum Meldebestand.',
      [FReorder.AsInteger - FStock.AsInteger]);
  end
  else
  begin
    FStock.ValidationState := pvsNone;
    FStock.ValidationHint := '';
    if FReorder.IsNull then
      FStatus.Caption := 'Kein Meldebestand: keine Warnung.'
    else
      FStatus.Caption := 'Bestand ausreichend.';
  end;
end;
// EXAMPLE-END

end.
