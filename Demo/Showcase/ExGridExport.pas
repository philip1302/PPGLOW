unit ExGridExport;

// Praxisbeispiel 1 zu TPPGGrid (Demo-Seite "Tabelle > TPPGGrid"):
// Auftragsliste mit Spalten (Columns), Filterzeile, Sortieren per Kopfklick,
// Summenzeile und Excel-Export genau der Ansicht, die der Anwender sieht
// (gefiltert, sortiert, nur sichtbare Spalten).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Grids, Vcl.Dialogs,
  PPG.StyleManager, PPG.Labels, PPG.Button, PPG.Grid, PPG.Grid.Columns, PPG.Grid.Data,
  PPG.Grid.Export;

const
  // Datenspalten der Auftragsliste
  colOrder = 0;
  colCustNo = 1;
  colCustomer = 2;
  colState = 3;
  colAmount = 4;

type
  /// Auftragsliste: filtern (Zeile unter dem Kopf), sortieren (Klick auf den
  /// Kopf), Summe unten und Export der aktuellen Ansicht nach Excel.
  TOrderList = class(TComponent)
  private
    FGrid: TPPGGrid;
    FExport: TPPGButton;
    FReset: TPPGButton;
    FStatus: TPPGLabel;
    function AddColumn(const ATitle: string; AWidth: Integer): TPPGGridColumn;
    procedure AddOrder(ARow: Integer; const ANo, ACustNo, ACustomer, AState: string;
      AAmount: Double);
    procedure ExportClick(Sender: TObject);
    procedure ResetClick(Sender: TObject);
  public
    constructor CreateList(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    /// Schreibt die aktuelle Ansicht als xlsx; Ergebnis = Anzahl Zeilen.
    function ExportTo(const AFileName: string): Integer;
    property Grid: TPPGGrid read FGrid;
    property ExportButton: TPPGButton read FExport;
    property ResetButton: TPPGButton read FReset;
    property Status: TPPGLabel read FStatus;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TOrderList.AddColumn(const ATitle: string; AWidth: Integer): TPPGGridColumn;
begin
  Result := FGrid.Columns.Add;
  Result.Title := ATitle;
  Result.Width := AWidth;
end;

procedure TOrderList.AddOrder(ARow: Integer; const ANo, ACustNo, ACustomer, AState: string;
  AAmount: Double);
begin
  FGrid.Cells[colOrder, ARow] := ANo;
  FGrid.Cells[colCustNo, ARow] := ACustNo;
  FGrid.Cells[colCustomer, ARow] := ACustomer;
  FGrid.Cells[colState, ARow] := AState;
  // Zahlen als Text im Landesformat: Sortieren, Summe und Export erkennen sie
  FGrid.Cells[colAmount, ARow] := FormatFloat('#,##0.00', AAmount);
end;

constructor TOrderList.CreateList(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
var
  Amount: TPPGGridColumn;
begin
  inherited Create(AOwner);
  FGrid := TPPGGrid.Create(Self);
  FGrid.Parent := AParent;
  FGrid.SetBounds(16, 16, 418, 292);
  FGrid.StyleManager := AStyles;
  FGrid.FixedCols := 0;                       // keine feste Spalte links
  FGrid.Options := FGrid.Options + [goRowSelect, goColSizing];
  FGrid.ShowFilterRow := True;                // Eingabezeile unter dem Kopf
  FGrid.ShowFooter := True;                   // Summenzeile unten

  // Spalten: Columns bestimmt ColCount
  AddColumn('Auftrag', 76);
  AddColumn('Kd.-Nr.', 70).Visible := False;  // intern, nicht anzeigen
  AddColumn('Kunde', 142);
  AddColumn('Status', 82);
  Amount := AddColumn('Betrag', 96);
  Amount.Alignment := taRightJustify;
  Amount.Aggregate := agSum;                  // Summe in der Fusszeile
  Amount.FooterFormat := '#,##0.00';
  Amount.Format := '#,##0.00';                // Zahlenformat in Excel

  FGrid.RowCount := 1 + 8;                    // Kopf + 8 Auftraege
  AddOrder(1, 'A-1001', 'K-201', 'Mueller GmbH', 'offen', 1250);
  AddOrder(2, 'A-1002', 'K-118', 'Becker & Sohn KG', 'bezahlt', 980.5);
  AddOrder(3, 'A-1003', 'K-305', 'Schmidt AG', 'offen', 4300);
  AddOrder(4, 'A-1004', 'K-077', 'Weber Handel', 'storniert', 150);
  AddOrder(5, 'A-1005', 'K-412', 'Fischer IT', 'offen', 2780.9);
  AddOrder(6, 'A-1006', 'K-150', 'Hoffmann OHG', 'bezahlt', 615);
  AddOrder(7, 'A-1007', 'K-233', 'Keller Bau', 'offen', 3125.4);
  AddOrder(8, 'A-1008', 'K-019', 'Wagner & Co.', 'bezahlt', 1990);

  FExport := TPPGButton.Create(Self);
  FExport.Parent := AParent;
  FExport.SetBounds(16, 320, 200, 32);
  FExport.Caption := 'Nach &Excel exportieren ...';
  FExport.StyleManager := AStyles;
  FExport.OnClick := ExportClick;

  FReset := TPPGButton.Create(Self);
  FReset.Parent := AParent;
  FReset.SetBounds(224, 320, 210, 32);
  FReset.Caption := 'Filter und Sortierung &aufheben';
  FReset.StyleManager := AStyles;
  FReset.OnClick := ResetClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 364, 418, 20);
  FStatus.Caption := 'Noch nichts exportiert.';
end;

function TOrderList.ExportTo(const AFileName: string): Integer;
var
  Source: IPPGTableSource;
begin
  // Das Grid ist selbst die Quelle: exportiert wird, was der Anwender sieht
  // (Filter, Sortierung, sichtbare Spalten in Anzeige-Reihenfolge, Summe)
  Source := FGrid as IPPGTableSource;
  PPGExportXlsx(Source, AFileName, 'Auftraege');
  Result := Source.TableRowCount;
  FStatus.Caption := Format('%d Auftr' + #$00E4 + 'ge nach %s exportiert.',
    [Result, ExtractFileName(AFileName)]);
end;

procedure TOrderList.ExportClick(Sender: TObject);
var
  Dlg: TSaveDialog;
begin
  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Filter := 'Excel-Arbeitsmappe (*.xlsx)|*.xlsx';
    Dlg.DefaultExt := 'xlsx';
    Dlg.FileName := 'Auftraege.xlsx';
    Dlg.Options := Dlg.Options + [ofOverwritePrompt];
    if Dlg.Execute then
      ExportTo(Dlg.FileName);
  finally
    Dlg.Free;
  end;
end;

procedure TOrderList.ResetClick(Sender: TObject);
begin
  FGrid.ClearFilters;
  FGrid.SortBy(-1);                           // urspruengliche Reihenfolge
end;
// EXAMPLE-END

end.
