unit ExDBGridOrderItems;

// Praxisbeispiel 2 zu TPPGDBGrid (Demo-Seite "Datenbank > TPPGDBGrid"):
// Positionen einer Bestellung direkt in der Tabelle erfassen. Die Regeln
// stehen an den Feldern der Datenmenge (Required, OnValidate), das Grid
// zeigt die Meldung und laesst den Editor offen. Artikel aus einer
// Auswahlliste (PickList), Positionsnummer schreibgeschuetzt (Column.ReadOnly), Bestellwert
// als TAggregateField in der Summenzeile.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, System.Variants, Vcl.Controls, Data.DB, Datasnap.DBClient,
  PPG.StyleManager, PPG.Labels, PPG.Button, PPG.Grid.Columns, PPG.DB.Grid;

type
  /// Bestellpositionen: Menge und Preis werden am Feld geprueft, der
  /// Bestellwert steht unten in der Summenzeile.
  TOrderItems = class(TComponent)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    FGrid: TPPGDBGrid;
    FAdd: TPPGButton;
    FDelete: TPPGButton;
    FStatus: TPPGLabel;
    FNextPos: Integer;
    procedure CreateData;
    function AddColumn(const AFieldName, ATitle: string; AWidth: Integer): TPPGDBGridColumn;
    procedure DataNewRecord(DataSet: TDataSet);
    procedure QuantityValidate(Sender: TField);
    procedure PriceValidate(Sender: TField);
    procedure GridFooterText(Sender: TObject; Column: TPPGDBGridColumn; var Text: string);
    procedure SourceDataChange(Sender: TObject; Field: TField);
    procedure AddClick(Sender: TObject);
    procedure DeleteClick(Sender: TObject);
  public
    constructor CreateItems(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    /// Bestellwert (Summe Menge x Preis) aus der Datenmenge.
    function Total: Double;
    property Data: TClientDataSet read FData;
    property Grid: TPPGDBGrid read FGrid;
    property AddButton: TPPGButton read FAdd;
    property DeleteButton: TPPGButton read FDelete;
    property Status: TPPGLabel read FStatus;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
procedure TOrderItems.CreateData;
var
  Sum: TAggregateField;
begin
  FData := TClientDataSet.Create(Self);
  FData.FieldDefs.Add('Pos', ftInteger);
  FData.FieldDefs.Add('Artikel', ftWideString, 30);
  FData.FieldDefs.Add('Menge', ftInteger);
  FData.FieldDefs.Add('Preis', ftFloat);
  FData.CreateDataSet;
  FData.Close;
  Sum := TAggregateField.Create(FData);
  Sum.FieldName := 'Bestellwert';
  Sum.Expression := 'SUM(Menge * Preis)';
  Sum.DisplayFormat := '#,##0.00';
  Sum.Active := True;
  Sum.DataSet := FData;
  FData.AggregatesActive := True;
  FData.Open;
  // Regeln gehoeren an die Felder: sie gelten in Grid, Formular und Import
  FData.FieldByName('Artikel').Required := True;
  FData.FieldByName('Menge').OnValidate := QuantityValidate;
  FData.FieldByName('Preis').OnValidate := PriceValidate;
  TFloatField(FData.FieldByName('Preis')).DisplayFormat := '#,##0.00';
  FData.AppendRecord([1, 'Buerostuhl Comfort', 2, 279]);
  FData.AppendRecord([2, 'Schreibtisch 160 cm', 1, 449]);
  FData.AppendRecord([3, 'Monitorarm', 2, 89.9]);
  FNextPos := 4;
  FData.OnNewRecord := DataNewRecord;
  FData.First;
  FSource := TDataSource.Create(Self);
  FSource.DataSet := FData;
  FSource.OnDataChange := SourceDataChange;
end;

function TOrderItems.AddColumn(const AFieldName, ATitle: string;
  AWidth: Integer): TPPGDBGridColumn;
begin
  Result := TPPGDBGridColumn(FGrid.Columns.Add);
  Result.FieldName := AFieldName;
  Result.Title := ATitle;
  Result.Width := AWidth;
end;

constructor TOrderItems.CreateItems(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
var
  Article: TPPGDBGridColumn;
begin
  inherited Create(AOwner);
  CreateData;
  FGrid := TPPGDBGrid.Create(Self);
  FGrid.Parent := AParent;
  FGrid.SetBounds(16, 16, 418, 220);
  FGrid.StyleManager := AStyles;
  FGrid.ShowRequired := True;                 // Artikel* = Pflichtfeld
  AddColumn('Pos', 'Pos.', 40).ReadOnly := True;  // vergibt das Programm
  Article := AddColumn('Artikel', 'Artikel', 140);
  Article.EditorKind := gekCombo;             // Auswahl statt Freitext
  Article.PickList.Text := 'Buerostuhl Comfort'#13#10'Schreibtisch 160 cm'#13#10 +
    'Monitorarm'#13#10'Rollcontainer'#13#10'Schreibtischlampe';
  AddColumn('Menge', 'Menge', 56);
  AddColumn('Preis', 'Preis', 100).FooterField := 'Bestellwert';
  FGrid.ShowFooter := True;
  FGrid.OnGetFooterText := GridFooterText;    // Beschriftung der Summe
  FGrid.DataSource := FSource;

  FAdd := TPPGButton.Create(Self);
  FAdd.Parent := AParent;
  FAdd.SetBounds(16, 248, 200, 32);
  FAdd.Caption := 'Position &hinzuf' + #$00FC + 'gen';
  FAdd.StyleManager := AStyles;
  FAdd.OnClick := AddClick;

  FDelete := TPPGButton.Create(Self);
  FDelete.Parent := AParent;
  FDelete.SetBounds(224, 248, 210, 32);
  FDelete.Caption := 'Position &l' + #$00F6 + 'schen';
  FDelete.StyleManager := AStyles;
  FDelete.OnClick := DeleteClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 292, 418, 20);
  SourceDataChange(nil, nil);
end;

procedure TOrderItems.DataNewRecord(DataSet: TDataSet);
begin
  // Vorbelegung neuer Positionen
  DataSet.FieldByName('Pos').AsInteger := FNextPos;
  DataSet.FieldByName('Menge').AsInteger := 1;
  Inc(FNextPos);
end;

procedure TOrderItems.QuantityValidate(Sender: TField);
begin
  // Ausnahme lehnt den Wert ab; das Grid zeigt sie, der Editor bleibt offen
  if Sender.AsInteger < 1 then
    DatabaseError('Die Menge muss mindestens 1 sein.');
end;

procedure TOrderItems.PriceValidate(Sender: TField);
begin
  if Sender.AsFloat < 0 then
    DatabaseError('Der Preis darf nicht negativ sein.');
end;

function TOrderItems.Total: Double;
var
  V: Variant;
begin
  V := FData.FieldByName('Bestellwert').Value;
  if VarIsNull(V) or VarIsEmpty(V) then
    Result := 0
  else
    Result := V;
end;

procedure TOrderItems.GridFooterText(Sender: TObject; Column: TPPGDBGridColumn;
  var Text: string);
begin
  // Text ist mit dem FooterField vorbelegt; hier nur die Beschriftung links
  if Column.FieldName = 'Artikel' then
    Text := 'Bestellwert';
end;

procedure TOrderItems.SourceDataChange(Sender: TObject; Field: TField);
begin
  FStatus.Caption := Format('%d Positionen, Bestellwert %s',
    [FData.RecordCount, FormatFloat('#,##0.00', Total)]);
end;

procedure TOrderItems.AddClick(Sender: TObject);
begin
  FData.Append;                               // OnNewRecord belegt Pos und Menge
  FGrid.Col := 2;                             // Artikel (0 = Datensatzzeiger)
  if FGrid.CanFocus then
    FGrid.SetFocus;
end;

procedure TOrderItems.DeleteClick(Sender: TObject);
begin
  if not FData.IsEmpty then
    FData.Delete;
end;
// EXAMPLE-END

end.
