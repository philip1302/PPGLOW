unit ExComboBoxArticle;

// Praxisbeispiel 2 zu TPPGComboBox (Demo-Seite "Auswahl > TPPGComboBox"):
// Artikel fuer eine Auftragsposition waehlen. Artikel mit reichen Eintraegen
// (ItemsEx: Detailzeile, Plakette, gesperrter Eintrag) und Filter beim Tippen;
// das Lager laedt seine Eintraege erst beim Aufklappen (OnDropDown) und hebt
// knappe Bestaende hervor (OnCustomDrawItem).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, System.Types, Vcl.Controls, Vcl.StdCtrls, Vcl.Graphics,
  PPG.StyleManager, PPG.Controls.Field, PPG.Items, PPG.CustomDraw, PPG.Labels, PPG.ComboBox;

type
  /// Auftragsposition: Artikel suchen und waehlen, danach ein Lager mit Bestand.
  TArticlePicker = class(TComponent)
  private
    FArticle: TPPGComboBox;
    FWarehouse: TPPGComboBox;
    FPrice: TPPGLabel;
    function NewLabel(AParent: TWinControl; X, Y, W: Integer; const ACaption: string): TPPGLabel;
    procedure ArticleSelect(Sender: TObject);
    procedure ArticleChange(Sender: TObject);
    procedure ArticleExit(Sender: TObject);
    procedure WarehouseDropDown(Sender: TObject);
    procedure WarehouseDrawItem(Sender: TObject; Canvas: TCanvas; Index: Integer;
      const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
      var DefaultDraw: Boolean);
  public
    constructor CreatePicker(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    property Article: TPPGComboBox read FArticle;
    property Warehouse: TPPGComboBox read FWarehouse;
    property Price: TPPGLabel read FPrice;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
type
  TArticle = record
    Name: string;
    Number: Integer;
    Price: Currency;
    Badge: string;
  end;

const
  Articles: array[0..6] of TArticle = (
    (Name: 'Notebook 14 Zoll'; Number: 10014; Price: 899.00; Badge: ''),
    (Name: 'Dockingstation USB-C'; Number: 10220; Price: 189.00; Badge: 'neu'),
    (Name: 'Monitor 27 Zoll'; Number: 10310; Price: 329.00; Badge: ''),
    (Name: 'Tastatur kabellos'; Number: 10412; Price: 49.90; Badge: ''),
    (Name: 'Maus kabellos'; Number: 10413; Price: 29.90; Badge: 'Aktion'),
    (Name: 'Toner schwarz 59A'; Number: 20059; Price: 119.00; Badge: ''),
    (Name: 'Headset Office'; Number: 10520; Price: 79.00; Badge: 'ausverkauft'));
  Warehouses: array[0..2] of string = ('Berlin', 'Hamburg', 'Leipzig');
  // Bestand je Artikel (Zeile) und Lager (Spalte)
  Stock: array[0..6, 0..2] of Integer = (
    (12, 0, 3), (4, 8, 0), (0, 6, 9), (25, 30, 14), (40, 0, 22), (2, 5, 1), (0, 0, 0));
  LowStock = 5;

function TArticlePicker.NewLabel(AParent: TWinControl; X, Y, W: Integer;
  const ACaption: string): TPPGLabel;
begin
  Result := TPPGLabel.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(X, Y, W, 20);
  Result.Caption := ACaption;
end;

constructor TArticlePicker.CreatePicker(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
var
  I: Integer;
  Item: TPPGItem;
begin
  inherited Create(AOwner);
  NewLabel(AParent, 16, 16, 400, '&Artikel');
  FArticle := TPPGComboBox.Create(Self);
  FArticle.Parent := AParent;
  FArticle.SetBounds(16, 38, 400, 32);
  FArticle.StyleManager := AStyles;
  FArticle.TextHint := 'Artikel suchen, z. B. "kabellos"';
  FArticle.FilterMode := fmContains;   // Tippen filtert die Liste
  FArticle.ShowClearButton := True;
  FArticle.DropDownCount := 5;
  FArticle.Styles.AlternateRow.Color := $00FAF7F2;   // Zebra fuer lange Listen
  // Reiche Eintraege: Text zum Suchen, Detailzeile und Plakette zum Entscheiden
  for I := 0 to High(Articles) do
  begin
    Item := FArticle.ItemsEx.Add(Articles[I].Name);
    Item.Detail := Format('Art.-Nr. %d, %s EUR', [Articles[I].Number,
      FormatFloat('#,##0.00', Articles[I].Price)]);
    Item.Badge := Articles[I].Badge;
    Item.Tag := I;   // Index in der Artikeltabelle
    // Ausverkauft: sichtbar, aber nicht waehlbar
    Item.Enabled := (Stock[I, 0] + Stock[I, 1] + Stock[I, 2]) > 0;
  end;
  FArticle.OnSelect := ArticleSelect;   // Wahl aus der Liste
  FArticle.OnChange := ArticleChange;   // Tippen
  FArticle.OnExit := ArticleExit;       // Pruefen beim Verlassen

  NewLabel(AParent, 16, 82, 200, '&Lager');
  FWarehouse := TPPGComboBox.Create(Self);
  FWarehouse.Parent := AParent;
  FWarehouse.SetBounds(16, 104, 200, 32);
  FWarehouse.StyleManager := AStyles;
  FWarehouse.Style := csDropDownList;
  FWarehouse.TextHint := 'Zuerst den Artikel';
  FWarehouse.Enabled := False;
  FWarehouse.OnDropDown := WarehouseDropDown;
  FWarehouse.OnCustomDrawItem := WarehouseDrawItem;

  FPrice := NewLabel(AParent, 232, 110, 184, '');
end;

procedure TArticlePicker.ArticleSelect(Sender: TObject);
var
  A: TArticle;
begin
  A := Articles[FArticle.ItemsEx[FArticle.ItemIndex].Tag];
  FPrice.Caption := Format('Preis: %s EUR', [FormatFloat('#,##0.00', A.Price)]);
  FArticle.ValidationState := pvsNone;
  // Das Lager haengt vom Artikel ab: neu waehlen lassen
  FWarehouse.Items.Clear;
  FWarehouse.Enabled := True;
  FWarehouse.TextHint := 'Lager aussuchen';
end;

procedure TArticlePicker.ArticleChange(Sender: TObject);
begin
  // Getippter Text, der (noch) keinem Artikel entspricht: kein Lager
  if FArticle.ItemIndex < 0 then
  begin
    FWarehouse.Items.Clear;
    FWarehouse.Enabled := False;
    FPrice.Caption := '';
  end;
end;

procedure TArticlePicker.ArticleExit(Sender: TObject);
begin
  if (FArticle.Text <> '') and (FArticle.ItemIndex < 0) then
  begin
    FArticle.ValidationState := pvsWarning;
    FArticle.ValidationHint := 'Kein Artikel mit diesem Namen.';
  end
  else
    FArticle.ValidationState := pvsNone;
end;

procedure TArticlePicker.WarehouseDropDown(Sender: TObject);
var
  A, I: Integer;
begin
  // Erst beim Aufklappen laden: nur Lager mit Bestand fuer diesen Artikel
  if FArticle.ItemIndex < 0 then
    Exit;
  A := FArticle.ItemsEx[FArticle.ItemIndex].Tag;
  FWarehouse.Items.BeginUpdate;
  try
    FWarehouse.Items.Clear;
    for I := 0 to High(Warehouses) do
      if Stock[A, I] > 0 then
        FWarehouse.Items.AddObject(Format('%s (%d Stk.)', [Warehouses[I], Stock[A, I]]),
          TObject(NativeInt(Stock[A, I])));
  finally
    FWarehouse.Items.EndUpdate;
  end;
end;

procedure TArticlePicker.WarehouseDrawItem(Sender: TObject; Canvas: TCanvas; Index: Integer;
  const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
  var DefaultDraw: Boolean);
begin
  // Knapper Bestand kursiv; gezeichnet wird weiter von der Combo
  if NativeInt(FWarehouse.Items.Objects[Index]) < LowStock then
    Style.FontStyle := [fsItalic];
end;
// EXAMPLE-END

end.
