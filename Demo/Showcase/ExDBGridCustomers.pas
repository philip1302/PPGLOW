unit ExDBGridCustomers;

// Praxisbeispiel 1 zu TPPGDBGrid (Demo-Seite "Datenbank > TPPGDBGrid"):
// Kundenliste aus einer Datenmenge (TClientDataSet im Speicher). Filter nach
// Ort und Sortierung per Klick auf den Spaltentitel macht die Datenmenge
// (Filter, IndexFieldNames), das Grid zeigt nur an. Summenzeile aus einem
// TAggregateField; Excel-Export genau der Ansicht (gefiltert, sortiert).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.Dialogs, Vcl.DBGrids,
  Data.DB, Datasnap.DBClient,
  PPG.StyleManager, PPG.Labels, PPG.Button, PPG.ComboBox, PPG.Grid.Data, PPG.Grid.Export,
  PPG.DB.Grid;

type
  /// Kundenliste: Ort waehlen (Filter), Titel anklicken (Sortierung),
  /// Summe unten, Export der aktuellen Ansicht nach Excel.
  TCustomerList = class(TComponent)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    FGrid: TPPGDBGrid;
    FCity: TPPGComboBox;
    FExport: TPPGButton;
    FReset: TPPGButton;
    FStatus: TPPGLabel;
    procedure CreateData;
    function AddColumn(const AFieldName, ATitle: string; AWidth: Integer): TPPGDBGridColumn;
    procedure CityChange(Sender: TObject);
    procedure GridTitleClick(Column: TPPGDBGridColumn);
    procedure ExportClick(Sender: TObject);
    procedure ResetClick(Sender: TObject);
  public
    constructor CreateList(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    /// Nur Kunden aus ACity zeigen ('' = alle).
    procedure FilterCity(const ACity: string);
    /// Schreibt die aktuelle Ansicht als xlsx; Ergebnis = Anzahl Zeilen.
    function ExportTo(const AFileName: string): Integer;
    property Data: TClientDataSet read FData;
    property Grid: TPPGDBGrid read FGrid;
    property CityBox: TPPGComboBox read FCity;
    property ExportButton: TPPGButton read FExport;
    property ResetButton: TPPGButton read FReset;
    property Status: TPPGLabel read FStatus;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
procedure TCustomerList.CreateData;
var
  Total: TAggregateField;
begin
  // In der Anwendung kommt die Datenmenge aus dem Datenmodul (FDQuery ...)
  FData := TClientDataSet.Create(Self);
  FData.FieldDefs.Add('Nr', ftInteger);
  FData.FieldDefs.Add('Kunde', ftWideString, 40);
  FData.FieldDefs.Add('Ort', ftWideString, 30);
  FData.FieldDefs.Add('Umsatz', ftFloat);
  FData.CreateDataSet;
  // Summe fuer die Summenzeile: rechnet die Datenmenge, nicht das Grid
  FData.Close;
  Total := TAggregateField.Create(FData);
  Total.FieldName := 'UmsatzSumme';
  Total.Expression := 'SUM(Umsatz)';
  Total.DisplayFormat := '#,##0.00';
  Total.Active := True;
  Total.DataSet := FData;
  FData.AggregatesActive := True;
  FData.Open;
  TFloatField(FData.FieldByName('Umsatz')).DisplayFormat := '#,##0.00';
  FData.AppendRecord([1001, 'Mueller GmbH', 'Hamburg', 12500]);
  FData.AppendRecord([1002, 'Becker & Sohn KG', 'Bremen', 8420.5]);
  FData.AppendRecord([1003, 'Schmidt AG', 'Berlin', 31200]);
  FData.AppendRecord([1004, 'Weber Handel', 'Hamburg', 1980]);
  FData.AppendRecord([1005, 'Fischer IT', 'Leipzig', 15340.9]);
  FData.AppendRecord([1006, 'Hoffmann OHG', 'Berlin', 670]);
  FData.AppendRecord([1007, 'Keller Bau', 'Hamburg', 22105.4]);
  FData.AppendRecord([1008, 'Wagner & Co.', 'Bremen', 4990]);
  FData.First;
  FSource := TDataSource.Create(Self);
  FSource.DataSet := FData;
end;

function TCustomerList.AddColumn(const AFieldName, ATitle: string;
  AWidth: Integer): TPPGDBGridColumn;
begin
  Result := TPPGDBGridColumn(FGrid.Columns.Add);
  Result.FieldName := AFieldName;
  Result.Title := ATitle;
  Result.Width := AWidth;
end;

constructor TCustomerList.CreateList(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  CreateData;

  FCity := TPPGComboBox.Create(Self);
  FCity.Parent := AParent;
  FCity.SetBounds(16, 16, 200, 32);
  FCity.StyleManager := AStyles;
  FCity.Style := csDropDownList;
  FCity.Items.Text := '(alle Orte)'#13#10'Berlin'#13#10'Bremen'#13#10'Hamburg'#13#10'Leipzig';
  FCity.ItemIndex := 0;
  FCity.OnChange := CityChange;

  FGrid := TPPGDBGrid.Create(Self);
  FGrid.Parent := AParent;
  FGrid.SetBounds(16, 60, 418, 252);
  FGrid.StyleManager := AStyles;
  // Nur ansehen: ganze Zeile waehlen, nichts bearbeiten
  FGrid.Options := FGrid.Options + [dgRowSelect] - [dgEditing];
  FGrid.ReadOnly := True;
  AddColumn('Nr', 'Nr.', 44);
  AddColumn('Kunde', 'Kunde', 128);
  AddColumn('Ort', 'Ort', 76);
  AddColumn('Umsatz', 'Umsatz', 96).FooterField := 'UmsatzSumme';
  FGrid.ShowFooter := True;                   // Summe aus dem TAggregateField
  FGrid.OnTitleClick := GridTitleClick;       // Sortieren macht die Datenmenge
  FGrid.DataSource := FSource;

  FExport := TPPGButton.Create(Self);
  FExport.Parent := AParent;
  FExport.SetBounds(16, 324, 200, 32);
  FExport.Caption := 'Nach &Excel exportieren ...';
  FExport.StyleManager := AStyles;
  FExport.OnClick := ExportClick;

  FReset := TPPGButton.Create(Self);
  FReset.Parent := AParent;
  FReset.SetBounds(224, 324, 210, 32);
  FReset.Caption := 'Filter und Sortierung &aufheben';
  FReset.StyleManager := AStyles;
  FReset.OnClick := ResetClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 368, 418, 20);
  FStatus.Caption := 'Noch nichts exportiert.';
end;

procedure TCustomerList.FilterCity(const ACity: string);
begin
  // Filter der Datenmenge: Grid, Summe und Export folgen ihm
  FData.Filtered := False;
  if ACity <> '' then
  begin
    FData.Filter := 'Ort = ' + QuotedStr(ACity);
    FData.Filtered := True;
  end;
end;

procedure TCustomerList.CityChange(Sender: TObject);
begin
  if FCity.ItemIndex > 0 then
    FilterCity(FCity.Text)
  else
    FilterCity('');
end;

procedure TCustomerList.GridTitleClick(Column: TPPGDBGridColumn);
begin
  // Wie bei TDBGrid sortiert die Datenmenge, das Grid zeigt nur an
  FData.IndexFieldNames := Column.FieldName;
end;

function TCustomerList.ExportTo(const AFileName: string): Integer;
var
  Source: IPPGTableSource;
begin
  // Das Grid liest die Datenmenge dafuer einmal ganz (gefiltert, sortiert,
  // nur die Spalten des Grids)
  Source := FGrid as IPPGTableSource;
  PPGExportXlsx(Source, AFileName, 'Kunden');
  Result := Source.TableRowCount;
  FStatus.Caption := Format('%d Kunden nach %s exportiert.',
    [Result, ExtractFileName(AFileName)]);
end;

procedure TCustomerList.ExportClick(Sender: TObject);
var
  Dlg: TSaveDialog;
begin
  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Filter := 'Excel-Arbeitsmappe (*.xlsx)|*.xlsx';
    Dlg.DefaultExt := 'xlsx';
    Dlg.FileName := 'Kunden.xlsx';
    Dlg.Options := Dlg.Options + [ofOverwritePrompt];
    if Dlg.Execute then
      ExportTo(Dlg.FileName);
  finally
    Dlg.Free;
  end;
end;

procedure TCustomerList.ResetClick(Sender: TObject);
begin
  FCity.ItemIndex := 0;
  FilterCity('');
  FData.IndexFieldNames := '';                // urspruengliche Reihenfolge
  FData.First;
end;
// EXAMPLE-END

end.
