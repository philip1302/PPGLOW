unit DemoPages4;

{ Demo-Seite "Datenbank" (Phase 9f): die DB-Controls aus PPGlowDBR an einer
  TClientDataSet im Speicher (MidasLib im Projekt, keine DLL noetig). }

interface

uses
  System.SysUtils, System.Classes, System.Variants, Vcl.Controls,
  Data.DB, Datasnap.DBClient,
  PPG.Types, PPG.Controls.Base, PPG.Feedback, PPG.Panel, PPG.Labels, PPG.ToolBar, PPG.Grid,
  PPG.DB.Controls, PPG.DB.Lookup, PPG.DB.Grid, PPG.Chart.Series, PPG.DB.Chart,
  PPG.NumberFormat, PPG.DB.Fields, PPG.DB.Navigator, PPG.Validator, PPG.Controls.Field, Vcl.DBCtrls,
  Vcl.Dialogs, PPG.Grid.Data, PPG.Grid.Export,
  DemoKit;

type
  TDemoDatabasePage = class(TDemoPage)
  private
    FCustomers: TClientDataSet;
    FCategories: TClientDataSet;
    FSource: TDataSource;
    FCatSource: TDataSource;
    FGrid: TPPGDBGrid;
    FNav: TPPGDBNavigator;
    FName: TPPGDBEdit;
    FCity: TPPGDBComboBox;
    FSince: TPPGDBDatePicker;
    FCategory: TPPGDBLookupComboBox;
    FActive: TPPGDBCheckBox;
    FSales: TPPGDBNumberEdit;
    FNotes: TPPGDBMemo;
    FTags: TPPGDBTagEdit;
    FResult: TPPGLabel;
    FChart: TPPGDBChart;
    FDetail: TPPGPanel;
    FValidator: TPPGValidator;
    procedure BuildData;
    procedure NavBeforeAction(Sender: TObject; Button: TNavigateBtn);
    procedure CustomersNewRecord(DataSet: TDataSet);
    procedure ToolClick(Sender: TObject; Item: TPPGToolItem);
    procedure SourceChange(Sender: TObject; Field: TField);
    procedure SourceStateChange(Sender: TObject);
    procedure SalesValidate(Sender: TField);
    procedure UpdateResult;
  protected
    procedure Build; override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
    procedure GridFooter(Sender: TObject; Column: TPPGDBGridColumn; var Text: string);
    procedure ExportExcel;
  end;

implementation

const
  ColW = 484;
  FullW = 2 * ColW + CardGap;
  Col3W = (FullW - 2 * CardPad - 2 * CardGap) div 3;
  GridH = 290;
  DetailH = 334;
  ChartH = 300;

  IcoPrior = $E76B;
  IcoNext = $E76C;
  IcoAdd = $E710;
  IcoDelete = $E74D;
  IcoPost = $E74E;
  IcoCancel = $E711;

{ TDemoDatabasePage }

function TagsOf(I: Integer): string;
begin
  case I mod 3 of
    0: Result := 'Stammkunde;Rabatt';
    1: Result := 'Neukunde';
  else
    Result := '';
  end;
end;

procedure TDemoDatabasePage.BuildData;
const
  Cats: array[0..3] of string = ('Handel', 'Handwerk', 'Beh{oe}rde', 'Privat');
  Names: array[0..7] of string = ('M{ue}ller & S{oe}hne', 'B{ae}ckerei Krause', 'Stadtwerke Ulm',
    'Schmidt IT', 'Weber Elektro', 'Zimmerei Lang', 'Amt f{ue}r Statistik', 'Familie Wagner');
  Cities: array[0..7] of string = ('Berlin', 'Hamburg', 'Ulm', 'M{ue}nchen', 'K{oe}ln', 'Ulm',
    'Berlin', 'Hamburg');
  CatOf: array[0..7] of Integer = (1, 2, 3, 1, 2, 2, 3, 4);
  Sales: array[0..7] of Double = (48200, 12950.5, 210000, 87400, 23100, 9800, 0, 1250);
var
  Agg: TAggregateField;
  I: Integer;
begin
  FCategories := TClientDataSet.Create(Own);
  FCategories.FieldDefs.Add('ID', ftInteger);
  FCategories.FieldDefs.Add('Name', ftWideString, 30);
  FCategories.CreateDataSet;
  for I := 0 to High(Cats) do
    FCategories.AppendRecord([I + 1, L(Cats[I])]);
  FCatSource := TDataSource.Create(Own);
  FCatSource.DataSet := FCategories;

  FCustomers := TClientDataSet.Create(Own);
  FCustomers.FieldDefs.Add('ID', ftInteger);
  FCustomers.FieldDefs.Add('Name', ftWideString, 40);
  FCustomers.FieldDefs.Add('City', ftWideString, 30);
  FCustomers.FieldDefs.Add('Since', ftDate);
  FCustomers.FieldDefs.Add('CategoryID', ftInteger);
  FCustomers.FieldDefs.Add('Active', ftBoolean);
  FCustomers.FieldDefs.Add('Sales', ftFloat);
  FCustomers.FieldDefs.Add('Notes', ftWideMemo);
  FCustomers.FieldDefs.Add('Tags', ftWideString, 120);
  FCustomers.CreateDataSet;
  // Summe fuer die Summenzeile des DB-Grids: TAggregateField der Datenmenge
  FCustomers.Close;
  Agg := TAggregateField.Create(FCustomers);
  Agg.FieldName := 'SalesTotal';
  Agg.Expression := 'SUM(Sales)';
  Agg.DisplayFormat := '#,##0.00';
  Agg.Active := True;
  Agg.DataSet := FCustomers;
  FCustomers.AggregatesActive := True;
  FCustomers.Open;
  FCustomers.FieldByName('Name').DisplayLabel := 'Kunde';
  FCustomers.FieldByName('City').DisplayLabel := 'Ort';
  FCustomers.FieldByName('Since').DisplayLabel := 'Kunde seit';
  FCustomers.FieldByName('Sales').DisplayLabel := L('Umsatz ({EUR})');
  TFloatField(FCustomers.FieldByName('Sales')).DisplayFormat := '#,##0.00';
  FCustomers.FieldByName('Sales').OnValidate := SalesValidate;
  // Pflicht und Laenge kommen aus dem TField: der Validator liest sie selbst
  FCustomers.FieldByName('Name').Required := True;
  for I := 0 to High(Names) do
    FCustomers.AppendRecord([I + 1, L(Names[I]), L(Cities[I]), EncodeDate(2015 + I, 1 + I, 3 + I),
      CatOf[I], I mod 3 <> 2, Sales[I], '', TagsOf(I)]);
  FCustomers.First;
  FCustomers.OnNewRecord := CustomersNewRecord;
  FSource := TDataSource.Create(Own);
  FSource.DataSet := FCustomers;
  FSource.OnDataChange := SourceChange;
  FSource.OnStateChange := SourceStateChange;
end;

procedure TDemoDatabasePage.Build;
const
  Titles: array[0..4] of string = ('Kunde', 'Ort', 'Kunde seit', 'Aktiv', 'Umsatz');
  Fields: array[0..4] of string = ('Name', 'City', 'Since', 'Active', 'Sales');
  Widths: array[0..4] of Integer = (300, 180, 140, 90, 160);
var
  Card: TPPGPanel;
  TB: TPPGToolBar;
  Col: TPPGDBGridColumn;
  I, Y, X2, X3: Integer;

  procedure AddCaption(X, AY: Integer; const S: string);
  begin
    NewLabel(Own, Card, X, AY, Col3W, S, tkCaption);
  end;

begin
  NewPageHeader(Own, Sheet, 'Datenbank', 'Die DB-Controls aus PPGlowDBR an einer Kundentabelle ' +
    'im Speicher. Tabelle und Formular zeigen denselben Datensatz; ein negativer Umsatz wird am ' +
    'Feld abgelehnt.');
  BuildData;

  // Tabelle mit Navigation
  Card := NewCard(Own, Sheet, PageX, PageContentTop, FullW, GridH, '', '');
  // Navigator (Phase 18c): Knoepfe, Zaehler, Suche im Namen, "Nur Treffer"
  FNav := TPPGDBNavigator.Create(Own);
  FNav.Parent := Card;
  FNav.SetBounds(CardPad - 2, 14, FullW - 2 * CardPad - 120, 36);
  FNav.ShowSearch := True;
  FNav.ShowFilter := True;
  FNav.SearchField := 'Name';
  FNav.ShowHint := True;
  FNav.DataSource := FSource;
  TB := TPPGToolBar.Create(Own);
  TB.Parent := Card;
  TB.Align := alNone;
  TB.SetBounds(FullW - CardPad - 110, 12, 110, 40);
  TB.Items.AddButton('Excel', $EDE1);
  TB.OnItemClick := ToolClick;
  FGrid := TPPGDBGrid.Create(Own);
  FGrid.Parent := Card;
  FGrid.SetBounds(CardPad, 58, FullW - 2 * CardPad, GridH - 58 - CardPad);
  for I := 0 to High(Fields) do
  begin
    Col := TPPGDBGridColumn(FGrid.Columns.Add);
    Col.FieldName := Fields[I];
    Col.Title := L(Titles[I]);
    Col.Width := Widths[I];
  end;
  FGrid.DataSource := FSource;
  // Summenzeile: Umsatz aus dem TAggregateField, Anzahl ueber das Ereignis
  FGrid.ShowFooter := True;
  TPPGDBGridColumn(FGrid.Columns[4]).FooterField := 'SalesTotal';
  FGrid.OnGetFooterText := GridFooter;

  // Formular zum aktuellen Datensatz
  Card := NewCard(Own, Sheet, PageX, PageContentTop + GridH + CardGap, FullW, DetailH,
    'Aktueller Datensatz', 'Tippen startet die Bearbeitung, Speichern oder ein Datensatzwechsel ' +
    'schreibt zur{ue}ck. Kunde ist Pflicht (TField.Required): der Validator pr{ue}ft ' +
    'das ohne eigene Regel, bevor der Navigator speichert.');
  FDetail := Card;
  X2 := CardPad + Col3W + CardGap;
  X3 := X2 + Col3W + CardGap;
  Y := Card.Tag;
  AddCaption(CardPad, Y, 'Kunde');
  FName := TPPGDBEdit.Create(Own);
  FName.Parent := Card;
  FName.SetBounds(CardPad, Y + 20, Col3W, CtlH);
  FName.DataSource := FSource;
  FName.DataField := 'Name';
  Host.RegisterSpecial('dbedit', FName);
  FValidator := TPPGValidator.Create(Own);
  FValidator.CheckOnClose := False;
  FNav.BeforeAction := NavBeforeAction;
  Host.RegisterSpecial('dbgrid', FGrid);
  AddCaption(X2, Y, 'Ort');
  FCity := TPPGDBComboBox.Create(Own);
  FCity.Parent := Card;
  FCity.SetBounds(X2, Y + 20, Col3W, CtlH);
  FCity.Items.Add('Berlin');
  FCity.Items.Add('Hamburg');
  FCity.Items.Add(L('K{oe}ln'));
  FCity.Items.Add(L('M{ue}nchen'));
  FCity.Items.Add('Ulm');
  FCity.DataSource := FSource;
  FCity.DataField := 'City';
  AddCaption(X3, Y, 'Kunde seit');
  FSince := TPPGDBDatePicker.Create(Own);
  FSince.Parent := Card;
  FSince.SetBounds(X3, Y + 20, Col3W, CtlH);
  FSince.DataSource := FSource;
  FSince.DataField := 'Since';

  Inc(Y, 64);
  AddCaption(CardPad, Y, 'Kategorie (Nachschlagefeld)');
  FCategory := TPPGDBLookupComboBox.Create(Own);
  FCategory.Parent := Card;
  FCategory.SetBounds(CardPad, Y + 20, Col3W, CtlH);
  FCategory.ListSource := FCatSource;
  FCategory.KeyField := 'ID';
  FCategory.ListField := 'Name';
  FCategory.DataSource := FSource;
  FCategory.DataField := 'CategoryID';
  AddCaption(X2, Y, L('Umsatz ({EUR})'));
  // Betrag als Zahlenfeld (Phase 12): Waehrung, rechnet, Null bleibt Null
  FSales := TPPGDBNumberEdit.Create(Own);
  FSales.Parent := Card;
  FSales.Kind := nkCurrency;
  FSales.SetBounds(X2, Y + 20, Col3W, CtlH);
  FSales.DataSource := FSource;
  FSales.DataField := 'Sales';
  FActive := TPPGDBCheckBox.Create(Own);
  FActive.Parent := Card;
  FActive.SetBounds(X3, Y + 22, Col3W, 28);
  FActive.Caption := 'Aktiver Kunde';
  FActive.DataSource := FSource;
  FActive.DataField := 'Active';

  Inc(Y, 64);
  AddCaption(CardPad, Y, 'Notiz');
  FNotes := TPPGDBMemo.Create(Own);
  FNotes.Parent := Card;
  FNotes.SetBounds(CardPad, Y + 20, (FullW - 2 * CardPad) div 2 - 8, 48);
  FNotes.DataSource := FSource;
  FNotes.DataField := 'Notes';
  AddCaption(CardPad + (FullW - 2 * CardPad) div 2 + 8, Y, L('Schlagw{oe}rter (TPPGDBTagEdit)'));
  FTags := TPPGDBTagEdit.Create(Own);
  FTags.Parent := Card;
  FTags.SetBounds(CardPad + (FullW - 2 * CardPad) div 2 + 8, Y + 20, (FullW - 2 * CardPad) div 2 - 8, CtlH);
  FTags.AutoSize := False;
  FTags.Height := 48;
  FTags.Suggestions.CommaText := 'Stammkunde,Neukunde,Rabatt,Export,Messe';
  FTags.DataSource := FSource;
  FTags.DataField := 'Tags';

  FResult := NewResult(Own, Card, 'Datensatz');

  // Diagramm aus derselben Datenmenge (TPPGDBChart)
  Card := NewCard(Own, Sheet, PageX, PageContentTop + GridH + DetailH + 2 * CardGap, FullW,
    ChartH, 'Umsatz je Kunde (TPPGDBChart)', 'Folgt jeder {Ae}nderung der Tabelle; der aktuelle ' +
    'Datensatz ist markiert, ein Klick auf eine S{ae}ule springt zum Kunden.');
  FChart := TPPGDBChart.Create(Own);
  FChart.Parent := Card;
  FChart.SetBounds(CardPad - 8, Card.Tag, FullW - 2 * CardPad + 16, ChartH - Card.Tag - 8);
  FChart.LegendPosition := clpNone;
  FChart.ValueFields := 'Sales';
  FChart.LabelField := 'Name';
  FChart.Series.Add.Kind := cskColumn;
  FChart.Series[0].ValueFormat := L('#,##0 {EUR}');
  FChart.DataSource := FSource;
  Host.RegisterSpecial('dbchart', FChart);
  UpdateResult;
end;

procedure TDemoDatabasePage.NavBeforeAction(Sender: TObject; Button: TNavigateBtn);
begin
  // Vor dem Speichern: Regeln aus den Datenfeldern (nur das Formular dieser Seite)
  if (Button = nbPost) and not FValidator.ValidateChildren(FDetail) then
  begin
    FValidator.FocusFirstError;
    Host.Log('Validator', L('Speichern abgelehnt: Pflichtfeld leer'));
    Abort;
  end;
end;

procedure TDemoDatabasePage.SalesValidate(Sender: TField);
begin
  if Sender.AsFloat < 0 then
    DatabaseError(L('Der Umsatz darf nicht negativ sein.'));
end;

procedure TDemoDatabasePage.UpdateResult;
const
  States: array[TDataSetState] of string = ('geschlossen', 'Ansicht', 'Bearbeiten', 'Neu',
    'Setzen', 'Berechnet', 'Filter', 'Neuer Wert', 'Alter Wert', 'Aktueller Wert', 'Block lesen',
    'intern', '{Oe}ffnen');
begin
  if (FResult = nil) or (FCustomers = nil) then
    Exit;
  if FCustomers.State = dsInsert then
    SetResult(FResult, Format('neu  {.}  %d gesamt', [FCustomers.RecordCount]))
  else
    SetResult(FResult, Format('%d von %d  {.}  %s', [FCustomers.RecNo, FCustomers.RecordCount,
      States[FCustomers.State]]));
end;

procedure TDemoDatabasePage.SourceChange(Sender: TObject; Field: TField);
begin
  if Field = nil then
    UpdateResult;
end;

procedure TDemoDatabasePage.SourceStateChange(Sender: TObject);
begin
  UpdateResult;
  if FCustomers <> nil then
    case FCustomers.State of
      dsEdit: Host.Log('Datenbank', 'Bearbeiten: ' + FCustomers.FieldByName('Name').AsString);
      dsInsert: Host.Log('Datenbank', 'Neuer Datensatz');
    end;
end;

procedure TDemoDatabasePage.CustomersNewRecord(DataSet: TDataSet);
begin
  // Vorbelegung fuer "Neu" (Navigator wie frueher der Knopf der Leiste)
  DataSet.FieldByName('ID').AsInteger := DataSet.RecordCount + 1;
  DataSet.FieldByName('Since').AsDateTime := Date;
  DataSet.FieldByName('Active').AsBoolean := True;
end;

procedure TDemoDatabasePage.ToolClick(Sender: TObject; Item: TPPGToolItem);
begin
  try
    case Item.IconChar of
      IcoPrior: FCustomers.Prior;
      IcoNext: FCustomers.Next;
      $EDE1: ExportExcel;
      IcoAdd:
        begin
          FCustomers.Append;
          FCustomers.FieldByName('ID').AsInteger := FCustomers.RecordCount + 1;
          FCustomers.FieldByName('Since').AsDateTime := Date;
          FCustomers.FieldByName('Active').AsBoolean := True;
          FName.SetFocus;
        end;
      IcoDelete:
        if not FCustomers.IsEmpty then
        begin
          Host.Log('Datenbank', L('Gel{oe}scht: ') + FCustomers.FieldByName('Name').AsString);
          FCustomers.Delete;
        end;
      IcoPost:
        if FCustomers.State in dsEditModes then
        begin
          FCustomers.Post;
          Host.Log('Datenbank', 'Gespeichert: ' + FCustomers.FieldByName('Name').AsString);
        end;
      IcoCancel:
        if FCustomers.State in dsEditModes then
        begin
          FCustomers.Cancel;
          Host.Log('Datenbank', 'Verworfen');
        end;
    end;
  except
    on E: EDatabaseError do
      Host.Notifier.Show('Datenbank', MarkupEscape(E.Message), psError);
  end;
  UpdateResult;
end;

procedure TDemoDatabasePage.GridFooter(Sender: TObject; Column: TPPGDBGridColumn;
  var Text: string);
begin
  if Column.FieldName = 'Name' then
    Text := IntToStr(FCustomers.RecordCount) + ' Kunden';
end;

procedure TDemoDatabasePage.ExportExcel;
var
  D: TSaveDialog;
begin
  D := TSaveDialog.Create(nil);
  try
    D.Filter := 'Excel (*.xlsx)|*.xlsx';
    D.DefaultExt := 'xlsx';
    D.FileName := 'Kunden';
    D.Options := D.Options + [ofOverwritePrompt];
    if D.Execute then
    begin
      PPGExportXlsx(FGrid as IPPGTableSource, D.FileName, 'Kunden');
      Host.Notifier.Show('Exportiert', D.FileName, psSuccess);
    end;
  finally
    D.Free;
  end;
end;

procedure TDemoDatabasePage.SelfTest(Check: TDemoCheck);
var
  N: Integer;
begin
  FCustomers.First;
  Check('Datenbank: Feld zeigt ersten Datensatz',
    FName.Text = FCustomers.FieldByName('Name').AsString);
  FCustomers.Next;
  Check('Datenbank: Feld folgt dem Datensatz',
    (FName.Text = FCustomers.FieldByName('Name').AsString) and
    (FCity.Text = FCustomers.FieldByName('City').AsString));
  Check('Datenbank: Nachschlagefeld zeigt Kategorie',
    FCategory.KeyValue = FCustomers.FieldByName('CategoryID').Value);
  Check('Datenbank: Kontrollkaestchen folgt dem Feld',
    FActive.Checked = FCustomers.FieldByName('Active').AsBoolean);
  N := FCustomers.RecordCount;
  FCustomers.Append;
  FCustomers.FieldByName('ID').AsInteger := N + 1;
  FCustomers.FieldByName('Name').AsString := 'Selbsttest';
  FCustomers.Post;
  Check('Datenbank: Datensatz angehaengt', (FCustomers.RecordCount = N + 1) and
    (FName.Text = 'Selbsttest'));
  FCustomers.Delete;
  Check('Datenbank: Datensatz geloescht', FCustomers.RecordCount = N);
  FChart.FlushReload;
  Check('Datenbank: Diagramm folgt der Tabelle', FChart.Series[0].Count = N);
  FCustomers.RecNo := 2;
  Check('Datenbank: Diagramm laedt alle Kunden', FChart.LoadedCount = N);
  FCustomers.Edit;
  try
    FCustomers.FieldByName('Sales').AsFloat := -1;
    Check('Datenbank: negativer Umsatz abgelehnt', False);
  except
    on EDatabaseError do
      Check('Datenbank: negativer Umsatz abgelehnt', True);
  end;
  FCustomers.Cancel;
  UpdateResult;
  Check('Datenbank: Ergebniszeile', Pos(IntToStr(FCustomers.RecordCount), FResult.Caption) > 0);
  Check('Datenbank: Summenzeile aus TAggregateField', FGrid.FooterText(5) <> '');
  Check('Datenbank: Export liest alle Saetze',
    (FGrid as IPPGTableSource).TableRowCount = FCustomers.RecordCount);
  FCustomers.First;
  Check('Datenbank: Navigator zaehlt', Pos(IntToStr(FCustomers.RecordCount), FNav.CounterText) > 0);
  Check('Datenbank: Navigator sucht', FNav.FindText(Copy(FCustomers.FieldByName('Name').AsString, 2, 3), False) or
    (FCustomers.RecNo = 1));
  FNav.SetQuickFilter(True);
  FNav.SetQuickFilter(False);
  Check('Datenbank: Filter aus stellt alle her', not FCustomers.Filtered);
  // Validator mit Regeln aus TField (Required) vor dem Speichern
  FCustomers.Edit;
  FName.Text := '';
  Check('Validator: Pflichtfeld aus TField', not FValidator.ValidateChildren(FDetail) and
    (FName.ValidationState = pvsError));
  FCustomers.Cancel;
  FValidator.ClearResults;
  Check('Validator: ohne Bearbeitung keine Feldregeln', FValidator.ValidateChildren(FDetail));
end;

end.
