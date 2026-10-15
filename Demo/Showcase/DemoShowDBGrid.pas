unit DemoShowDBGrid;

// Komponentenseite TPPGDBGrid (Gruppe "Datenbank"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten des
// DB-Grids (Datenmenge im Speicher fuer die Buehne, Spalten mit FieldName,
// Ereignisse mit eigener Signatur im Protokoll, Kategorien im Inspektor)
// und die beiden Praxisbeispiele (ExDBGridCustomers, ExDBGridOrderItems).

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, Vcl.Controls, Vcl.Menus,
  Data.DB, Datasnap.DBClient,
  PPG.DB.Grid, DemoKit, DemoShowcase, DemoInspector, ExDBGridCustomers, ExDBGridOrderItems;

type
  TDemoShowDBGridPage = class(TDemoComponentPage)
  private
    FStageData: TClientDataSet;
    FStageSource: TDataSource;
    FCustomers: TCustomerList;
    FItems: TOrderItems;
    function FreeName(const ABase: string): string;
    procedure CreateStageData;
    procedure SubjectTitleClick(Column: TPPGDBGridColumn);
    procedure SubjectCellClick(Column: TPPGDBGridColumn);
    procedure SubjectColumnMoved(Sender: TObject; FromIndex, ToIndex: Longint);
    procedure SubjectHeaderMenu(Sender: TObject; ACol: Integer; Menu: TPopupMenu);
  protected
    function SubjectClass: TComponentClass; override;
    procedure SetupSubject(ASubject: TComponent); override;
    procedure AddCandidates(List: TList<TComponent>); override;
    function InitialPath: string; override;
    procedure BuildExamples; override;
    procedure CategoryFor(Sender: TObject; const AName: string; var ACategory: string); override;
    procedure EventOccurred(const AName, ADetail: string); override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

uses
  Winapi.Windows, System.IOUtils, System.Variants, PPG.Grid.Data, PPG.Xlsx,
  PPG.Edit;

type
  /// Zugriff auf den Klick auf einen Spaltentitel (geschuetzt) fuer den Selbsttest.
  TDBGridAccess = class(TPPGDBGrid);

const
  // Buehne: Spalten des Grids (0 = Datensatzzeiger)
  StageNo = 1;
  StageCustomer = 2;
  StageCity = 3;
  StageSales = 4;
  StageActive = 5;

function TDemoShowDBGridPage.SubjectClass: TComponentClass;
begin
  Result := TPPGDBGrid;
end;

function TDemoShowDBGridPage.FreeName(const ABase: string): string;
var
  N: Integer;
begin
  N := 1;
  Result := ABase + IntToStr(N);
  while Own.FindComponent(Result) <> nil do
  begin
    Inc(N);
    Result := ABase + IntToStr(N);
  end;
end;

procedure TDemoShowDBGridPage.CreateStageData;
var
  Total: TAggregateField;
begin
  // Datenmenge im Speicher wie ein TClientDataSet auf dem Formular; sie
  // bleibt ueber "Alles zuruecksetzen" erhalten (nur das Grid ist neu)
  FStageData := TClientDataSet.Create(Own);
  FStageData.Name := FreeName('ClientDataSet');
  FStageData.FieldDefs.Add('Nr', ftInteger);
  FStageData.FieldDefs.Add('Kunde', ftWideString, 40);
  FStageData.FieldDefs.Add('Ort', ftWideString, 30);
  FStageData.FieldDefs.Add('Umsatz', ftFloat);
  FStageData.FieldDefs.Add('Aktiv', ftBoolean);
  FStageData.CreateDataSet;
  FStageData.Close;
  Total := TAggregateField.Create(FStageData);
  Total.FieldName := 'UmsatzSumme';
  Total.Expression := 'SUM(Umsatz)';
  Total.DisplayFormat := '#,##0.00';
  Total.Active := True;
  Total.DataSet := FStageData;
  FStageData.AggregatesActive := True;
  FStageData.Open;
  TFloatField(FStageData.FieldByName('Umsatz')).DisplayFormat := '#,##0.00';
  FStageData.FieldByName('Kunde').Required := True;
  FStageData.AppendRecord([1001, 'Mueller GmbH', 'Hamburg', 12500, True]);
  FStageData.AppendRecord([1002, 'Becker & Sohn KG', 'Bremen', 8420.5, True]);
  FStageData.AppendRecord([1003, 'Schmidt AG', 'Berlin', 31200, True]);
  FStageData.AppendRecord([1004, 'Weber Handel', 'Hamburg', 1980, False]);
  FStageData.AppendRecord([1005, 'Fischer IT', 'Leipzig', 15340.9, True]);
  FStageData.AppendRecord([1006, 'Hoffmann OHG', 'Berlin', 670, False]);
  FStageData.AppendRecord([1007, 'Keller Bau', 'Dresden', 22105.4, True]);
  FStageData.AppendRecord([1008, 'Wagner & Co.', 'Bremen', 4990, True]);
  FStageData.AppendRecord([1009, 'Schulz Logistik', 'Hamburg', 9870, True]);
  FStageData.AppendRecord([1010, 'Neumann Praxis', 'Leipzig', 2340, False]);
  FStageSource := TDataSource.Create(Own);
  FStageSource.Name := FreeName('DataSource');
  FStageSource.DataSet := FStageData;
end;

procedure TDemoShowDBGridPage.SetupSubject(ASubject: TComponent);

  procedure AddCol(G: TPPGDBGrid; const AField, ATitle: string; AWidth: Integer);
  var
    C: TPPGDBGridColumn;
  begin
    C := TPPGDBGridColumn(G.Columns.Add);
    C.FieldName := AField;
    C.Title := ATitle;
    C.Width := AWidth;
  end;

var
  G: TPPGDBGrid;
begin
  inherited SetupSubject(ASubject);
  if FStageData = nil then
    CreateStageData;
  if FStageData.State in dsEditModes then
    FStageData.Cancel;
  FStageData.IndexFieldNames := '';
  FStageData.First;
  G := ASubject as TPPGDBGrid;
  G.Width := 500;
  G.Height := 268;
  G.Columns.BeginUpdate;
  try
    AddCol(G, 'Nr', 'Nr.', 56);
    AddCol(G, 'Kunde', 'Kunde', 140);
    AddCol(G, 'Ort', 'Ort', 96);
    AddCol(G, 'Umsatz', 'Umsatz', 100);
    AddCol(G, 'Aktiv', 'Aktiv', 60);
  finally
    G.Columns.EndUpdate;
  end;
  // Summe fuer ShowFooter: rechnet die Datenmenge (TAggregateField)
  TPPGDBGridColumn(G.Columns[StageSales - 1]).FooterField := 'UmsatzSumme';
  G.DataSource := FStageSource;
  // Eigene Signaturen: werden nicht automatisch protokolliert
  G.OnTitleClick := SubjectTitleClick;
  G.OnCellClick := SubjectCellClick;
  G.OnColumnMoved := SubjectColumnMoved;
  G.OnHeaderMenu := SubjectHeaderMenu;
end;

procedure TDemoShowDBGridPage.AddCandidates(List: TList<TComponent>);
begin
  inherited AddCandidates(List);
  if FStageSource <> nil then
    List.Add(FStageSource);
end;

function TDemoShowDBGridPage.InitialPath: string;
begin
  Result := 'DataSource';
end;

procedure TDemoShowDBGridPage.SubjectTitleClick(Column: TPPGDBGridColumn);
begin
  // Wie im Formular: die Datenmenge sortiert, das Grid zeigt nur an
  if (FStageData <> nil) and (FStageData.FindField(Column.FieldName) <> nil) and
    not (FStageData.State in dsEditModes) then
    FStageData.IndexFieldNames := Column.FieldName;
  LogEvent('OnTitleClick', Format('Column.FieldName = %s, IndexFieldNames := %s',
    [Column.FieldName, Column.FieldName]));
end;

procedure TDemoShowDBGridPage.SubjectCellClick(Column: TPPGDBGridColumn);
var
  F: TField;
begin
  F := nil;
  if FStageData <> nil then
    F := FStageData.FindField(Column.FieldName);
  if F <> nil then
    LogEvent('OnCellClick', Format('Column.FieldName = %s, Wert = "%s"',
      [Column.FieldName, F.DisplayText]))
  else
    LogEvent('OnCellClick', 'Column.FieldName = ' + Column.FieldName);
end;

procedure TDemoShowDBGridPage.SubjectColumnMoved(Sender: TObject; FromIndex, ToIndex: Longint);
begin
  LogEvent('OnColumnMoved', Format('FromIndex = %d, ToIndex = %d', [FromIndex, ToIndex]));
end;

procedure TDemoShowDBGridPage.SubjectHeaderMenu(Sender: TObject; ACol: Integer; Menu: TPopupMenu);
begin
  LogEvent('OnHeaderMenu', Format(L('ACol = %d, %d Men{ue}eintr{ae}ge'), [ACol, Menu.Items.Count]));
end;

procedure TDemoShowDBGridPage.EventOccurred(const AName, ADetail: string);
var
  Detail: string;
begin
  Detail := ADetail;
  if (FStageData <> nil) and FStageData.Active and ((AName = 'OnClick') or
    (AName = 'OnDblClick') or (AName = 'OnColEnter')) then
    Detail := Format('RecNo = %d, Kunde = %s', [FStageData.RecNo,
      FStageData.FieldByName('Kunde').DisplayText]);
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowDBGridPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'Bands') then
    ACategory := 'Inhalt'
  else if SameText(AName, 'ExportMaxRecords') then
    ACategory := 'Daten'
  else if SameText(AName, 'Options') or SameText(AName, 'ShowFooter') or
    SameText(AName, 'ShowRequired') or SameText(AName, 'HeaderMenu') or
    SameText(AName, 'ToolTips') then
    ACategory := 'Verhalten'
  else if SameText(AName, 'ConditionalFormats') or SameText(AName, 'GridLineWidth') or
    SameText(AName, 'ScrollBarMode') or SameText(AName, 'SmoothScrolling') then
    ACategory := 'PPGlow'
  else if SameText(AName, 'DrawingStyle') or SameText(AName, 'FixedColor') or
    SameText(AName, 'GradientStartColor') or SameText(AName, 'GradientEndColor') or
    SameText(AName, 'BorderStyle') or SameText(AName, 'DefaultDrawing') or
    SameText(AName, 'TitleFont') then
    ACategory := 'Darstellung (VCL)'
  else if SameText(AName, 'FixedColsRight') then
    ACategory := 'Layout';
end;

procedure TDemoShowDBGridPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Kundenliste nach Excel', 'ExDBGridCustomers',
    'Eine Kundenliste aus einer Datenmenge (<b>DataSource</b>, <b>Columns</b> mit '
    + '<b>FieldName</b>). Filtern und Sortieren macht die Datenmenge: Ort w{ae}hlen setzt '
    + '<i>Filter</i>, ein Klick auf den Titel (<b>OnTitleClick</b>) <i>IndexFieldNames</i>. '
    + 'Die Summe kommt aus einem TAggregateField (<b>FooterField</b>). <b>PPGExportXlsx</b> '
    + 'schreibt genau die Ansicht. Probieren Sie: Ort "Hamburg", Klick auf "Umsatz", '
    + 'dann exportieren und die Datei in Excel {oe}ffnen.');
  FCustomers := TCustomerList.CreateList(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Bestellpositionen erfassen', 'ExDBGridOrderItems',
    'Positionen direkt in der Tabelle bearbeiten (<b>dgEditing</b>). Die Regeln stehen an '
    + 'den Feldern: Menge mindestens 1 (OnValidate), Artikel Pflicht (<b>ShowRequired</b> '
    + 'zeigt das Sternchen). Artikel aus einer Auswahlliste (<b>EditorKind</b> gekCombo, '
    + '<b>PickList</b>), Pos. schreibgesch{ue}tzt (<b>ReadOnly</b> der Spalte), Bestellwert in '
    + 'der Summenzeile (<b>FooterField</b>, Beschriftung per <b>OnGetFooterText</b>). '
    + 'Probieren Sie: Doppelklick auf eine Menge, <i>0</i> und Enter '
    + '(abgelehnt), dann <i>3</i> und Enter; "Position hinzuf{ue}gen" und Pfeil runter.');
  FItems := TOrderItems.CreateItems(Own, V.Live, DemoStyles);
end;

procedure TDemoShowDBGridPage.SelfTest(Check: TDemoCheck);
var
  G: TPPGDBGrid;
  Source: IPPGTableSource;
  Rd: TPPGXlsxReader;
  FileName, Msg: string;
  I, Count: Integer;
  AllCity, Sorted, Raised: Boolean;
  Last: Double;
  DS: TClientDataSet;
begin
  inherited SelfTest(Check);
  // Buehne: Datenmenge, Titelklick sortiert, Summe, Indikator
  ResetSubject;
  G := TPPGDBGrid(Subject);
  Check('TPPGDBGrid: B' + #$00FC + 'hne mit DataSource, 5 Spalten und 10 Datens' + #$00E4 + 'tzen',
    (G.DataSource = FStageSource) and (G.FieldCount = 5) and (G.Fields[4] <> nil) and
    (G.Fields[4].DataType = ftBoolean) and (FStageData.RecordCount = 10));
  TDBGridAccess(G).HeaderClicked(StageSales, 0);
  Check('TPPGDBGrid: Klick auf den Titel "Umsatz" erscheint als OnTitleClick und sortiert ' +
    'die Datenmenge',
    (EventList.Items.Count > 0) and (Pos('OnTitleClick', EventList.Items[0]) > 0) and
    (FStageData.IndexFieldNames = 'Umsatz'));
  FStageData.First;
  Check('TPPGDBGrid: nach Umsatz sortiert steht Hoffmann OHG (670) vorn',
    FStageData.FieldByName('Kunde').AsString = 'Hoffmann OHG');
  G.ShowFooter := True;
  Check('TPPGDBGrid: ShowFooter zeigt die Summe aus dem TAggregateField (FooterField)',
    G.FooterText(StageSales) = FormatFloat('#,##0.00', 12500 + 8420.5 + 31200 + 1980 +
    15340.9 + 670 + 22105.4 + 4990 + 9870 + 2340));
  Inspector.SetValueText('Options', '');
  Check('TPPGDBGrid: Options ohne dgIndicator und dgTitles: keine feste Spalte und Zeile',
    (TDBGridAccess(G).FixedCols = 0) and (TDBGridAccess(G).FixedRows = 0) and (G.FieldCount = 5));
  ResetSubject;
  Check('TPPGDBGrid: Zur' + #$00FC + 'cksetzen stellt die urspr' + #$00FC +
    'ngliche Reihenfolge wieder her',
    (FStageData.IndexFieldNames = '') and (FStageData.FieldByName('Nr').AsInteger = 1001) and
    (TDBGridAccess(Subject).FixedCols = 1));

  // Praxisbeispiel 1: Filter, Sortierung, Summe und Excel-Export
  G := FCustomers.Grid;
  Source := G as IPPGTableSource;
  Check('Beispiel Kunden: 8 Kunden, Summenzeile aus dem TAggregateField',
    (Source.TableRowCount = 8) and (G.FooterText(4) = FormatFloat('#,##0.00', 12500 + 8420.5 +
    31200 + 1980 + 15340.9 + 670 + 22105.4 + 4990)));
  FCustomers.CityBox.ItemIndex := FCustomers.CityBox.Items.IndexOf('Hamburg');
  FCustomers.FilterCity(FCustomers.CityBox.Text);
  Check('Beispiel Kunden: Filter "Hamburg" zeigt 3 Kunden',
    FCustomers.Data.Filtered and (Source.TableRowCount = 3));
  TDBGridAccess(G).HeaderClicked(4, 0);
  Check('Beispiel Kunden: Titelklick auf "Umsatz" sortiert die Datenmenge (IndexFieldNames)',
    FCustomers.Data.IndexFieldNames = 'Umsatz');
  FileName := TPath.Combine(TPath.GetTempPath, Format('PPGlowDemo-DBGrid-%d.xlsx',
    [GetCurrentProcessId]));
  try
    Count := FCustomers.ExportTo(FileName);
    Check('Beispiel Kunden: ExportTo meldet 3 Zeilen und zeigt es an',
      (Count = 3) and (Pos('3 ', FCustomers.Status.Caption) = 1));
    Rd := TPPGXlsxReader.Create;
    try
      Rd.LoadFromFile(FileName);
      Check('Beispiel Kunden: Datei hat Kopf + 3 Zeilen und die 4 Spalten des Grids',
        (Rd.RowCount = 4) and (Rd.ColCount = 4) and (Rd.Cells[0, 0] = 'Nr.') and
        (Rd.Cells[1, 0] = 'Kunde') and (Rd.Cells[3, 0] = 'Umsatz'));
      AllCity := True;
      Sorted := True;
      Last := -1;
      for I := 1 to Rd.RowCount - 1 do
      begin
        if Rd.Cells[2, I] <> 'Hamburg' then
          AllCity := False;
        if VarIsNumeric(Rd.Values[3, I]) then
        begin
          if Double(Rd.Values[3, I]) < Last then
            Sorted := False;
          Last := Double(Rd.Values[3, I]);
        end
        else
          Sorted := False;
      end;
      Check('Beispiel Kunden: nur gefilterte Kunden, Umsatz als Zahl aufsteigend wie im Grid',
        AllCity and Sorted and (Rd.RowCount > 1) and (Rd.Cells[1, 1] = 'Weber Handel') and
        VarIsNumeric(Rd.Values[3, 1]) and (Abs(Double(Rd.Values[3, 1]) - 1980) < 0.001));
    finally
      Rd.Free;
    end;
  finally
    if FileExists(FileName) then
      System.SysUtils.DeleteFile(FileName);
  end;
  Check('Beispiel Kunden: Testdatei wieder gel' + #$00F6 + 'scht', not FileExists(FileName));
  FCustomers.ResetButton.Click;
  Check('Beispiel Kunden: "aufheben" zeigt wieder alle 8 Kunden unsortiert',
    (Source.TableRowCount = 8) and not FCustomers.Data.Filtered and
    (FCustomers.Data.IndexFieldNames = '') and (FCustomers.CityBox.ItemIndex = 0));
  Source := nil;

  // Praxisbeispiel 2: Pruefung am Feld, Summe, neue Position
  G := FItems.Grid;
  DS := FItems.Data;
  Check('Beispiel Positionen: 3 Positionen, Bestellwert in der Summenzeile, ' +
    'Beschriftung aus OnGetFooterText',
    (DS.RecordCount = 3) and (Abs(FItems.Total - 1186.8) < 0.001) and
    (G.FooterText(4) = FormatFloat('#,##0.00', 1186.8)) and (G.FooterText(2) = 'Bestellwert'));
  DS.First;
  G.HandleNeeded;
  G.Col := TDBGridAccess(G).FixedCols + 2;
  G.ShowEditor;
  Check('Beispiel Positionen: Editor f' + #$00FC + 'r die Menge ge' + #$00F6 + 'ffnet',
    G.EditorMode and (G.InplaceEditor is TPPGEdit));
  if G.InplaceEditor is TPPGEdit then
  begin
    TPPGEdit(G.InplaceEditor).Text := '0';
    Raised := False;
    Msg := '';
    try
      G.HideEditor(True);
    except
      on E: EDatabaseError do
      begin
        Raised := True;
        Msg := E.Message;
      end;
    end;
    Check('Beispiel Positionen: Menge 0 wird am Feld abgelehnt (OnValidate), Editor bleibt offen',
      Raised and (Pos('Menge', Msg) > 0) and G.EditorMode and
      (DS.FieldByName('Menge').AsInteger = 2));
    TPPGEdit(G.InplaceEditor).Text := '3';
    G.HideEditor(True);
    if DS.State in dsEditModes then
      DS.Post;
    Check('Beispiel Positionen: Menge 3 wird gebucht, der Bestellwert folgt',
      (not G.EditorMode) and (DS.FieldByName('Menge').AsInteger = 3) and
      (Abs(FItems.Total - (1186.8 + 279)) < 0.001));
    DS.Edit;
    DS.FieldByName('Menge').AsInteger := 2;
    DS.Post;
  end;
  G.Col := TDBGridAccess(G).FixedCols;
  G.ShowEditor;
  Check('Beispiel Positionen: Spalte Pos. ist schreibgesch' + #$00FC + 'tzt (Column.ReadOnly)',
    not G.EditorMode);
  FItems.AddButton.Click;
  Check('Beispiel Positionen: "Position hinzuf' + #$00FC + 'gen" legt Pos. 4 mit Menge 1 an',
    (DS.State = dsInsert) and (DS.FieldByName('Pos').AsInteger = 4) and
    (DS.FieldByName('Menge').AsInteger = 1) and (G.Col = TDBGridAccess(G).FixedCols + 1));
  Raised := False;
  try
    DS.Post;
  except
    on EDatabaseError do
      Raised := True;
  end;
  Check('Beispiel Positionen: ohne Artikel nicht speicherbar (Required)',
    Raised and (DS.State = dsInsert));
  DS.FieldByName('Artikel').AsString := 'Rollcontainer';
  DS.FieldByName('Preis').AsFloat := 129;
  DS.Post;
  Check('Beispiel Positionen: mit Artikel gebucht, 4 Positionen',
    (DS.RecordCount = 4) and (Abs(FItems.Total - (1186.8 + 129)) < 0.001) and
    (Pos('4 Positionen', FItems.Status.Caption) = 1));
  FItems.DeleteButton.Click;
  Check('Beispiel Positionen: "Position l' + #$00F6 + 'schen" entfernt sie wieder',
    (DS.RecordCount = 3) and (Abs(FItems.Total - 1186.8) < 0.001));
end;

initialization
  RegisterShowcasePage('TPPGDBGrid', TDemoShowDBGridPage);

end.
