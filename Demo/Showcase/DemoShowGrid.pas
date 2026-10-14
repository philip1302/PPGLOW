unit DemoShowGrid;

// Komponentenseite TPPGGrid (Gruppe "Tabelle"): Buehne und Inspektor kommen
// aus TDemoComponentPage; hier stehen nur die Besonderheiten des Grids
// (Spalten, Band und Daten auf der Buehne, Ereignisse mit eigener Signatur im
// Protokoll, Kategorien im Inspektor) und die beiden Praxisbeispiele
// (ExGridExport, ExGridStock).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Menus,
  PPG.Grid, DemoKit, DemoShowcase, DemoInspector, ExGridExport, ExGridStock;

type
  TDemoShowGridPage = class(TDemoComponentPage)
  private
    FOrders: TOrderList;
    FStock: TStockEditor;
    procedure SubjectSelectCell(Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean);
    procedure SubjectFixedCellClick(Sender: TObject; ACol, ARow: Longint);
    procedure SubjectColumnMoved(Sender: TObject; FromIndex, ToIndex: Longint);
    procedure SubjectSetEditText(Sender: TObject; ACol, ARow: Longint; const Value: string);
    procedure SubjectValidateCell(Sender: TObject; ACol, ARow: Integer; var Value: string;
      var Accept: Boolean);
    procedure SubjectHeaderMenu(Sender: TObject; ACol: Integer; Menu: TPopupMenu);
    procedure SubjectLinkClick(Sender: TObject; ACol, ARow: Integer; const Link: string);
    procedure SubjectCellButtonClick(Sender: TObject; ACol, ARow: Integer);
  protected
    function SubjectClass: TComponentClass; override;
    procedure SetupSubject(ASubject: TComponent); override;
    function InitialPath: string; override;
    function SkipInRoundTrip(Node: TDemoPropNode; var AReason: string): Boolean; override;
    procedure BuildExamples; override;
    procedure CategoryFor(Sender: TObject; const AName: string; var ACategory: string); override;
    procedure EventOccurred(const AName, ADetail: string); override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

uses
  Winapi.Windows, System.IOUtils, System.Variants, Vcl.Graphics, PPG.Grid.Columns,
  PPG.Grid.Data, PPG.Grid.Styles, PPG.Xlsx, PPG.Edit;

const
  // Buehne: Datenspalten
  StageNo = 0;
  StageCustomer = 1;
  StageCity = 2;
  StageSales = 3;
  StageState = 4;

function TDemoShowGridPage.SubjectClass: TComponentClass;
begin
  Result := TPPGGrid;
end;

procedure TDemoShowGridPage.SetupSubject(ASubject: TComponent);

  procedure AddRow(G: TPPGGrid; ARow: Integer; const ACustomer, ACity: string; ASales: Double;
    const AState: string);
  begin
    G.Cells[StageNo, ARow] := IntToStr(1000 + ARow);
    G.Cells[StageCustomer, ARow] := ACustomer;
    G.Cells[StageCity, ARow] := ACity;
    G.Cells[StageSales, ARow] := FormatFloat('#,##0.00', ASales);
    G.Cells[StageState, ARow] := AState;
  end;

  function AddCol(G: TPPGGrid; const ATitle: string; AWidth: Integer): TPPGGridColumn;
  begin
    Result := G.Columns.Add;
    Result.Title := ATitle;
    Result.Width := AWidth;
  end;

var
  G: TPPGGrid;
begin
  inherited SetupSubject(ASubject);
  G := ASubject as TPPGGrid;
  G.Width := 500;
  G.Height := 268;
  // Fuenf Spalten wie ColCount einer neuen Komponente; Nr. ist die feste Spalte.
  // BeginUpdate: sonst durchlaeuft ColCount beim Anlegen 1, 2, 3 ... und
  // FixedCols = 1 wird dabei auf 0 geklemmt (siehe Bericht).
  G.Columns.BeginUpdate;
  try
    AddCol(G, 'Nr.', 50);
    AddCol(G, 'Kunde', 140).Band := 0;
    AddCol(G, 'Ort', 100).Band := 0;
    AddCol(G, 'Umsatz', 100).Alignment := taRightJustify;
    G.Columns[StageSales].Aggregate := agSum;
    AddCol(G, 'Status', 86);
  finally
    G.Columns.EndUpdate;
  end;
  G.Bands.Add.Caption := 'Anschrift';
  G.RowCount := 1 + 8;
  AddRow(G, 1, 'Mueller GmbH', 'Hamburg', 12500, 'aktiv');
  AddRow(G, 2, 'Becker & Sohn KG', 'Bremen', 8420.5, 'aktiv');
  AddRow(G, 3, 'Schmidt AG', 'Berlin', 31200, 'aktiv');
  AddRow(G, 4, 'Weber Handel', 'Hamburg', 1980, 'gesperrt');
  AddRow(G, 5, 'Fischer IT', 'Leipzig', 15340.9, 'aktiv');
  AddRow(G, 6, 'Hoffmann OHG', 'Berlin', 670, 'neu');
  AddRow(G, 7, 'Keller Bau', 'Dresden', 22105.4, 'aktiv');
  AddRow(G, 8, 'Wagner & Co.', 'Bremen', 4990, 'neu');
  // Eigene Signaturen: werden nicht automatisch protokolliert
  G.OnSelectCell := SubjectSelectCell;
  G.OnFixedCellClick := SubjectFixedCellClick;
  G.OnColumnMoved := SubjectColumnMoved;
  G.OnSetEditText := SubjectSetEditText;
  G.OnValidateCell := SubjectValidateCell;
  G.OnHeaderMenu := SubjectHeaderMenu;
  G.OnLinkClick := SubjectLinkClick;
  G.OnCellButtonClick := SubjectCellButtonClick;
end;

function TDemoShowGridPage.SkipInRoundTrip(Node: TDemoPropNode; var AReason: string): Boolean;
begin
  // Umgehung Geruest-Fehler: DemoCodeGen.PascalCode fuellt die Collections der
  // Vorgabe-Instanz zum Vergleich auf und loescht die Eintraege danach wieder.
  // Beim Grid setzt Columns.Add dabei ColCount = Columns.Count; nach dem
  // Loeschen bleibt die Vorgabe auf ColCount = 1 (und FixedCols = 0) stehen.
  // Zuruecksetzen auf diese Vorgabe waere falsch.
  Result := (Node.Parent = nil) and (SameText(Node.Name, 'ColCount') or
    SameText(Node.Name, 'FixedCols'));
  if Result then
    AReason := 'Vorgabe-Instanz nach der Code-Erzeugung mit ColCount = 1, Geruest-Fehler';
end;

function TDemoShowGridPage.InitialPath: string;
begin
  Result := 'Columns';
end;

procedure TDemoShowGridPage.SubjectSelectCell(Sender: TObject; ACol, ARow: Longint;
  var CanSelect: Boolean);
begin
  LogEvent('OnSelectCell', Format('ACol = %d, ARow = %d', [ACol, ARow]));
end;

procedure TDemoShowGridPage.SubjectFixedCellClick(Sender: TObject; ACol, ARow: Longint);
begin
  LogEvent('OnFixedCellClick', Format('ACol = %d, ARow = %d', [ACol, ARow]));
end;

procedure TDemoShowGridPage.SubjectColumnMoved(Sender: TObject; FromIndex, ToIndex: Longint);
begin
  LogEvent('OnColumnMoved', Format('FromIndex = %d, ToIndex = %d', [FromIndex, ToIndex]));
end;

procedure TDemoShowGridPage.SubjectSetEditText(Sender: TObject; ACol, ARow: Longint;
  const Value: string);
begin
  LogEvent('OnSetEditText', Format('ACol = %d, ARow = %d, Value = "%s"', [ACol, ARow, Value]));
end;

procedure TDemoShowGridPage.SubjectValidateCell(Sender: TObject; ACol, ARow: Integer;
  var Value: string; var Accept: Boolean);
begin
  LogEvent('OnValidateCell', Format('ACol = %d, ARow = %d, Value = "%s"', [ACol, ARow, Value]));
end;

procedure TDemoShowGridPage.SubjectHeaderMenu(Sender: TObject; ACol: Integer; Menu: TPopupMenu);
begin
  LogEvent('OnHeaderMenu', Format(L('ACol = %d, %d Men{ue}eintr{ae}ge'), [ACol, Menu.Items.Count]));
end;

procedure TDemoShowGridPage.SubjectLinkClick(Sender: TObject; ACol, ARow: Integer;
  const Link: string);
begin
  LogEvent('OnLinkClick', Format('ACol = %d, ARow = %d, Link = %s', [ACol, ARow, Link]));
end;

procedure TDemoShowGridPage.SubjectCellButtonClick(Sender: TObject; ACol, ARow: Integer);
begin
  LogEvent('OnCellButtonClick', Format('ACol = %d, ARow = %d', [ACol, ARow]));
end;

procedure TDemoShowGridPage.EventOccurred(const AName, ADetail: string);
var
  G: TPPGGrid;
  Detail: string;
begin
  Detail := ADetail;
  if Subject is TPPGGrid then
  begin
    G := TPPGGrid(Subject);
    if AName = 'OnSorted' then
    begin
      if G.SortColumn < 0 then
        Detail := L('unsortiert (urspr{ue}ngliche Reihenfolge)')
      else
        Detail := Format('SortColumn = %d, SortAscending = %s',
          [G.SortColumn, BoolToStr(G.SortAscending, True)]);
    end
    else if (AName = 'OnClick') or (AName = 'OnDblClick') then
      Detail := Format('Col = %d, Row = %d', [G.Col, G.Row]);
  end;
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowGridPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'Bands') or SameText(AName, 'ColCount') or SameText(AName, 'RowCount') or
    SameText(AName, 'FixedCols') or SameText(AName, 'FixedRows') or
    SameText(AName, 'FixedColsRight') then
    ACategory := 'Inhalt'
  else if SameText(AName, 'Options') or SameText(AName, 'ShowFilterRow') or
    SameText(AName, 'SortOnHeaderClick') or SameText(AName, 'HeaderMenu') or
    SameText(AName, 'ShowFooter') or SameText(AName, 'GroupFooter') or
    SameText(AName, 'ShowGroupPanel') or SameText(AName, 'ToolTips') then
    ACategory := 'Verhalten'
  else if SameText(AName, 'ConditionalFormats') or SameText(AName, 'GridLineWidth') or
    SameText(AName, 'ScrollBarMode') or SameText(AName, 'SmoothScrolling') then
    ACategory := 'PPGlow'
  else if SameText(AName, 'DrawingStyle') or SameText(AName, 'FixedColor') or
    SameText(AName, 'GradientStartColor') or SameText(AName, 'GradientEndColor') or
    SameText(AName, 'BorderStyle') or SameText(AName, 'DefaultDrawing') or
    SameText(AName, 'ScrollBars') then
    ACategory := 'Darstellung (VCL)'
  else if SameText(AName, 'DefaultColWidth') or SameText(AName, 'DefaultRowHeight') then
    ACategory := 'Layout';
end;

procedure TDemoShowGridPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Auftr{ae}ge nach Excel', 'ExGridExport',
    'Eine Auftragsliste mit <b>Columns</b> (eine Spalte unsichtbar), <b>ShowFilterRow</b>, '
    + 'Sortieren per Kopfklick und <b>ShowFooter</b> mit Summe (<b>Aggregate</b>). '
    + '<b>PPGExportXlsx</b> schreibt genau die Ansicht in eine Excel-Datei: gefiltert, sortiert, '
    + 'nur sichtbare Spalten. Probieren Sie: in der Filterzeile unter "Status" <i>offen</i> '
    + 'eingeben, auf "Betrag" klicken, dann exportieren und die Datei in Excel {oe}ffnen.');
  FOrders := TOrderList.CreateList(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Lagerbestand pflegen', 'ExGridStock',
    'Bearbeiten direkt in der Tabelle (<b>goEditing</b>): Auswahlliste f{ue}r die Kategorie '
    + '(<b>gekCombo</b>), Zahlenfeld f{ue}r den Bestand (<b>gekSpin</b>), K{ae}stchen '
    + '(<b>ckCheck</b>). <b>OnValidateCell</b> pr{ue}ft den Preis, <b>ConditionalFormats</b> '
    + 'markiert wenig Bestand. Probieren Sie: Doppelklick auf einen Preis, <i>abc</i> eingeben '
    + 'und Enter (abgelehnt), dann <i>5</i> und Enter; zuletzt nach Kategorie gruppieren.');
  FStock := TStockEditor.CreateEditor(Own, V.Live, DemoStyles);
end;

procedure TDemoShowGridPage.SelfTest(Check: TDemoCheck);
var
  G: TPPGGrid;
  Source: IPPGTableSource;
  PS: IPPGGridPrintSource;
  Rd: TPPGXlsxReader;
  FileName: string;
  I, Count: Integer;
  AllOpen, Sorted: Boolean;
  Last: Double;
  St: TPPGGridCellStyle;
begin
  inherited SelfTest(Check);
  // Buehne: Sortieren, Fokuswechsel und Summe
  ResetSubject;
  G := TPPGGrid(Subject);
  Check('TPPGGrid: B' + #$00FC + 'hne mit 5 Spalten, Band "Anschrift" und fester Spalte Nr.',
    (G.Columns.Count = 5) and (G.ColCount = 5) and (G.FixedCols = 1) and (G.Bands.Count = 1));
  G.SortBy(StageSales, False);
  Check('TPPGGrid: SortBy erscheint als OnSorted mit Spalte und Richtung im Protokoll',
    (EventList.Items.Count > 0) and (Pos('OnSorted', EventList.Items[0]) > 0) and
    (Pos('SortColumn = 3', EventList.Items[0]) > 0));
  Check('TPPGGrid: absteigend sortiert, Cells[] bleibt bei den Datenzeilen',
    (G.Cells[StageCustomer, 3] = 'Schmidt AG') and (G.VisualRow(3) < G.VisualRow(7)) and
    (G.VisualRow(7) < G.VisualRow(5)) and (G.VisualRow(5) < G.VisualRow(1)));
  G.Row := 5;
  Check('TPPGGrid: Fokuswechsel per Row erscheint als OnSelectCell',
    (Pos('OnSelectCell', EventList.Items[0]) > 0) and (G.Row = 5));
  G.ShowFooter := True;
  Check('TPPGGrid: ShowFooter zeigt die Summe der Spalte Umsatz (Aggregate = agSum)',
    G.FooterText(StageSales) = FormatFloat('#,##0.##', 12500 + 8420.5 + 31200 + 1980 +
    15340.9 + 670 + 22105.4 + 4990));
  ResetSubject;

  // Praxisbeispiel 1: Filter, Sortierung, Summe und Excel-Export
  G := FOrders.Grid;
  Source := G as IPPGTableSource;
  Check('Beispiel Excel: Summenzeile = Summe aller 8 Betr' + #$00E4 + 'ge',
    G.FooterText(colAmount) = FormatFloat('#,##0.00', 1250 + 980.5 + 4300 + 150 + 2780.9 + 615 +
    3125.4 + 1990));
  G.Filters[colState] := 'offen';
  Check('Beispiel Excel: Filter "offen" zeigt 4 Auftr' + #$00E4 + 'ge, die Summe folgt dem Filter',
    (Source.TableRowCount = 4) and
    (G.FooterText(colAmount) = FormatFloat('#,##0.00', 1250 + 4300 + 2780.9 + 3125.4)));
  G.SortBy(colAmount, False);
  FileName := TPath.Combine(TPath.GetTempPath, Format('PPGlowDemo-Grid-%d.xlsx',
    [GetCurrentProcessId]));
  try
    Count := FOrders.ExportTo(FileName);
    Check('Beispiel Excel: ExportTo meldet 4 Zeilen und zeigt es an',
      (Count = 4) and (Pos('4 ', FOrders.Status.Caption) = 1));
    Rd := TPPGXlsxReader.Create;
    try
      Rd.LoadFromFile(FileName);
      Check('Beispiel Excel: Datei hat Kopf + 4 Zeilen und 4 Spalten (Kd.-Nr. ist ausgeblendet)',
        (Rd.RowCount = 5) and (Rd.ColCount = 4) and (Rd.Cells[0, 0] = 'Auftrag') and
        (Rd.Cells[1, 0] = 'Kunde') and (Rd.Cells[3, 0] = 'Betrag'));
      AllOpen := True;
      Sorted := True;
      Last := MaxInt;
      for I := 1 to Rd.RowCount - 1 do
      begin
        if Rd.Cells[2, I] <> 'offen' then
          AllOpen := False;
        if VarIsNumeric(Rd.Values[3, I]) then
        begin
          if Double(Rd.Values[3, I]) > Last then
            Sorted := False;
          Last := Double(Rd.Values[3, I]);
        end
        else
          Sorted := False;
      end;
      Check('Beispiel Excel: nur gefilterte Zeilen, Betrag als Zahl absteigend wie im Grid',
        AllOpen and Sorted and (Rd.RowCount > 1) and (Rd.Cells[0, 1] = 'A-1003') and
        VarIsNumeric(Rd.Values[3, 1]) and (Abs(Double(Rd.Values[3, 1]) - 4300) < 0.001));
    finally
      Rd.Free;
    end;
  finally
    if FileExists(FileName) then
      System.SysUtils.DeleteFile(FileName);
  end;
  Check('Beispiel Excel: Testdatei wieder gel' + #$00F6 + 'scht', not FileExists(FileName));
  FOrders.ResetButton.Click;
  Check('Beispiel Excel: "aufheben" zeigt wieder alle 8 Auftr' + #$00E4 + 'ge unsortiert',
    (Source.TableRowCount = 8) and (G.SortColumn < 0) and (G.Filters[colState] = ''));
  Source := nil;

  // Praxisbeispiel 2: bedingtes Format, Pruefung beim Bearbeiten, Gruppieren
  G := FStock.Grid;
  if Supports(G, IPPGGridPrintSource, PS) then
  begin
    St := PS.PrintCellStyle(colStock, 1, G.Cells[colStock, 2]);
    Check('Beispiel Lager: Bestand 4 ist markiert (ConditionalFormats), Bestand 12 nicht',
      (G.Cells[colStock, 2] = '4') and (St.Fill <> clNone) and St.Bold and
      PS.PrintCellStyle(colStock, 0, G.Cells[colStock, 1]).IsDefault);
    PS := nil;
  end
  else
    Check('Beispiel Lager: Grid liefert IPPGGridPrintSource', False);
  G.HandleNeeded;
  G.Col := colPrice;
  G.Row := 2;
  G.ShowEditor;
  Check('Beispiel Lager: Editor f' + #$00FC + 'r den Preis ge' + #$00F6 + 'ffnet',
    G.EditorMode and (G.InplaceEditor is TPPGEdit));
  if G.InplaceEditor is TPPGEdit then
  begin
    Count := FStock.Changes;
    TPPGEdit(G.InplaceEditor).Text := 'abc';
    G.HideEditor(True);
    Check('Beispiel Lager: OnValidateCell lehnt "abc" ab, Editor bleibt offen, Zelle unver' +
      #$00E4 + 'ndert',
      G.EditorMode and (G.Cells[colPrice, 2] = FormatFloat('#,##0.00', 279)) and
      (FStock.Changes = Count) and (Pos('Preis', FStock.Status.Caption) > 0));
    TPPGEdit(G.InplaceEditor).Text := FloatToStr(12.5);
    G.HideEditor(True);
    Check('Beispiel Lager: g' + #$00FC + 'ltiger Preis wird formatiert ' + #$00FC +
      'bernommen (OnSetEditText)',
      (not G.EditorMode) and (G.Cells[colPrice, 2] = FormatFloat('#,##0.00', 12.5)) and
      (FStock.Changes = Count + 1));
    G.Cells[colPrice, 2] := FormatFloat('#,##0.00', 279);
  end;
  FStock.GroupCheck.Click;
  Check('Beispiel Lager: Gruppieren nach Kategorie ergibt 3 Gruppen mit Text aus OnGetGroupText',
    FStock.GroupCheck.Checked and (G.GroupCount = 3) and (Pos('Artikel)', G.GroupText(0)) > 0) and
    (G.GroupFooterText(0, colStock) <> ''));
  FStock.GroupCheck.Click;
  Check('Beispiel Lager: Gruppierung wieder aufgehoben',
    (not FStock.GroupCheck.Checked) and (G.GroupCount = 0));
end;

initialization
  RegisterShowcasePage('TPPGGrid', TDemoShowGridPage);

end.
