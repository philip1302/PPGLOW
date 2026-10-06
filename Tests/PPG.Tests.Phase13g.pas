unit PPG.Tests.Phase13g;

{ Tests fuer Phase 13g: DB-Grid - Spalten verschieben/ausblenden (auch
  automatische Spalten), Layout, Summenzeile aus der Datenmenge, Druck und
  Export ueber die ganze Datenmenge. }

interface

uses
  TestFramework, Winapi.Windows, System.Classes, System.SysUtils, System.Variants,
  System.IOUtils, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids, Vcl.Menus,
  Data.DB, Datasnap.DBClient, MidasLib, Vcl.DBGrids,
  PPG.Grid, PPG.Grid.Columns, PPG.Grid.Data, PPG.Grid.Print, PPG.Grid.Export, PPG.Xlsx,
  PPG.DB.Grid, PPG.Tests.Controls;

type
  TDBGridColumnTests = class(TControlTestCase)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    FOldFS: TFormatSettings;
    procedure FooterText(Sender: TObject; Column: TPPGDBGridColumn; var Text: string);
    function NewGrid: TPPGDBGrid;
    function Titles(G: TPPGDBGrid): string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure ColumnResizeAllowsMoving;
    procedure MoveAutoColumnSurvivesRebuild;
    procedure HideAutoColumn;
    procedure PersistentColumnsMove;
    procedure LayoutByFieldName;
    procedure FooterFromAggregateField;
    procedure FooterEvent;
    procedure HeaderMenuWithoutSortAndGroups;
    procedure ExportReadsWholeDataSet;
    procedure ExportMaxRecords;
    procedure SnapshotFollowsData;
    procedure PrintWholeDataSet;
  end;

implementation

type
  TGridAccess = class(TPPGDBGrid);
  TBaseAccess = class(TPPGCustomGrid); // Options des Grids (TGridOptions)

{ TDBGridColumnTests }

procedure TDBGridColumnTests.SetUp;
var
  I: Integer;
  Agg: TAggregateField;
begin
  inherited SetUp;
  FOldFS := FormatSettings;
  FormatSettings := TFormatSettings.Create('de-DE');
  FData := TClientDataSet.Create(FForm);
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Name', ftString, 20);
  FData.FieldDefs.Add('Preis', ftFloat);
  FData.FieldDefs.Add('Datum', ftDate);
  FData.CreateDataSet;
  // Summe als TAggregateField (Feld erst nach CreateDataSet anlegen)
  FData.Close;
  Agg := TAggregateField.Create(FData);
  Agg.FieldName := 'Gesamt';
  Agg.Expression := 'SUM(Preis)';
  Agg.Active := True;
  Agg.DisplayFormat := '#,##0.00';
  Agg.DataSet := FData;
  FData.AggregatesActive := True;
  FData.Open;
  for I := 1 to 60 do
    FData.AppendRecord([I, 'Name ' + IntToStr(I), I * 0.5, EncodeDate(2026, 1, 1) + I]);
  FData.First;
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
end;

procedure TDBGridColumnTests.TearDown;
begin
  FormatSettings := FOldFS;
  inherited TearDown;
end;

procedure TDBGridColumnTests.FooterText(Sender: TObject; Column: TPPGDBGridColumn; var Text: string);
begin
  if Column.FieldName = 'ID' then
    Text := 'Anzahl ' + IntToStr(TPPGDBGrid(Sender).DataSource.DataSet.RecordCount);
end;

function TDBGridColumnTests.NewGrid: TPPGDBGrid;
begin
  Result := TPPGDBGrid.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 500, 240);
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.HandleNeeded;
  Result.DataSource := FSource;
end;

function TDBGridColumnTests.Titles(G: TPPGDBGrid): string;
var
  T: IPPGTableSource;
  C: Integer;
begin
  Result := '';
  Supports(G, IPPGTableSource, T);
  for C := 0 to T.TableColCount - 1 do
  begin
    if C > 0 then
      Result := Result + ',';
    Result := Result + T.TableColumn(C).Title;
  end;
end;

procedure TDBGridColumnTests.ColumnResizeAllowsMoving;
var
  G: TPPGDBGrid;
begin
  G := NewGrid;
  CheckTrue(goColMoving in TBaseAccess(G).Options, 'wie TDBGrid');
  G.Options := G.Options - [dgColumnResize];
  CheckFalse(goColMoving in TBaseAccess(G).Options);
end;

procedure TDBGridColumnTests.MoveAutoColumnSurvivesRebuild;
var
  G: TPPGDBGrid;
begin
  G := NewGrid;
  CheckEquals('ID,Name,Preis,Datum', Titles(G), 'ohne Indikator');
  G.MoveColumn(1, 3); // ID hinter Preis (Anzeige 0 = Indikator)
  CheckEquals('Name,Preis,ID,Datum', Titles(G));
  FData.Close;
  FData.Open; // Spalten werden neu aufgebaut
  CheckEquals('Name,Preis,ID,Datum', Titles(G), 'Reihenfolge bleibt');
end;

procedure TDBGridColumnTests.HideAutoColumn;
var
  G: TPPGDBGrid;
  C: TPPGGridColumn;
begin
  G := NewGrid;
  C := TGridAccess(G).ColumnOf(3); // Preis
  C.Visible := False;
  CheckEquals('ID,Name,Datum', Titles(G));
  FData.Close;
  FData.Open;
  CheckEquals('ID,Name,Datum', Titles(G), 'nach Neuaufbau weiter ausgeblendet');
  TGridAccess(G).ColumnOf(3).Visible := True;
  CheckEquals('ID,Name,Preis,Datum', Titles(G));
end;

procedure TDBGridColumnTests.PersistentColumnsMove;
var
  G: TPPGDBGrid;
begin
  G := NewGrid;
  TPPGDBGridColumn(G.Columns.Add).FieldName := 'Name';
  TPPGDBGridColumn(G.Columns.Add).FieldName := 'Preis';
  TPPGDBGridColumn(G.Columns.Add).FieldName := 'ID';
  CheckEquals('Name,Preis,ID', Titles(G));
  G.MoveColumn(3, 1);
  CheckEquals('ID,Name,Preis', Titles(G));
  CheckEquals(0, G.Columns[2].DisplayIndex, 'DisplayIndex in den Columns');
end;

procedure TDBGridColumnTests.LayoutByFieldName;
var
  G, G2: TPPGDBGrid;
  S: string;
begin
  G := NewGrid;
  G.MoveColumn(4, 1); // Datum nach vorn
  TGridAccess(G).ColumnOf(2).Visible := False; // Name
  S := G.SaveLayout;
  CheckTrue(Pos('Col=1,', S) > 0);
  CheckTrue(Pos(',Datum'#13#10, S) > 0, 'Schluessel = Feldname');
  CheckTrue(Pos('Col=0,', S) > 0, 'Name ausgeblendet');
  G2 := NewGrid;
  G2.LoadLayout(S);
  CheckEquals('Datum,ID,Preis', Titles(G2));
end;

procedure TDBGridColumnTests.FooterFromAggregateField;
var
  G: TPPGDBGrid;
  Bmp: TBitmap;
begin
  G := NewGrid;
  G.ShowFooter := True;
  TPPGDBGridColumn(TGridAccess(G).ColumnOf(3)).FooterField := 'Gesamt';
  // 0,5 + 1 + ... + 30 = 0,5 * 60 * 61 / 2 = 915
  CheckEquals('915,00', G.FooterText(3), 'aus dem TAggregateField');
  FData.Edit;
  FData.FieldByName('Preis').AsFloat := 100.5;
  FData.Post;
  CheckEquals('1.015,00', G.FooterText(3), 'folgt der Datenmenge');
  CheckEquals('', G.FooterText(2), 'ohne FooterField');
  Bmp := RenderToBitmap(G);
  Bmp.Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TDBGridColumnTests.FooterEvent;
var
  G: TPPGDBGrid;
begin
  G := NewGrid;
  G.OnGetFooterText := FooterText;
  CheckEquals('Anzahl 60', G.FooterText(1));
  TGridAccess(G).ColumnOf(3).Aggregate := agSum;
  CheckEquals('', G.FooterText(3), 'Aggregate rechnet das DB-Grid nicht selbst');
end;

procedure TDBGridColumnTests.HeaderMenuWithoutSortAndGroups;
var
  G: TPPGDBGrid;
  M: TPopupMenu;
  I: Integer;
begin
  G := NewGrid;
  M := G.CreateHeaderMenu(2);
  try
    CheckFalse(M.Items[0].Enabled, 'Sortieren ist Sache der Datenmenge');
    for I := 0 to M.Items.Count - 1 do
      CheckTrue(M.Items[I].Tag <> 8, 'kein Gruppieren');
  finally
    M.Free;
  end;
  G.GroupBy([2]);
  CheckEquals(0, G.GroupCount);
end;

procedure TDBGridColumnTests.ExportReadsWholeDataSet;
var
  G: TPPGDBGrid;
  T: IPPGTableSource;
  F: string;
  Rd: TPPGXlsxReader;
begin
  G := NewGrid;
  FData.RecNo := 7;
  Supports(G, IPPGTableSource, T);
  CheckEquals(4, T.TableColCount, 'ohne Indikator');
  CheckEquals(60, T.TableRowCount, 'alle Saetze, nicht nur der Puffer');
  CheckEquals(7, FData.RecNo, 'Position wieder hergestellt');
  CheckEquals('Name 60', T.TableCellText(1, 59));
  CheckTrue(VarIsNumeric(T.TableCellValue(2, 0)), 'Preis als Zahl');
  CheckEquals(varDate, VarType(T.TableCellValue(3, 0)), 'Datum als Datum');
  F := TPath.Combine(TPath.GetTempPath, 'PPGlowDB' + IntToStr(GetCurrentProcessId) + '.xlsx');
  try
    PPGExportXlsx(T, F);
    Rd := TPPGXlsxReader.Create;
    try
      Rd.LoadFromFile(F);
      CheckEquals(61, Rd.RowCount);
      CheckEquals('Preis', Rd.Cells[2, 0]);
      CheckEquals(30, Double(Rd.Values[2, 60]), 0.0001);
      CheckEquals(PPGExcelSerial(EncodeDate(2026, 1, 2)), Double(Rd.Values[3, 1]), 0);
    finally
      Rd.Free;
    end;
  finally
    System.SysUtils.DeleteFile(F);
  end;
end;

procedure TDBGridColumnTests.ExportMaxRecords;
var
  G: TPPGDBGrid;
  T: IPPGTableSource;
begin
  G := NewGrid;
  G.ExportMaxRecords := 25;
  FData.RecNo := 40;
  Supports(G, IPPGTableSource, T);
  CheckEquals(25, T.TableRowCount);
  CheckEquals(40, FData.RecNo);
end;

procedure TDBGridColumnTests.SnapshotFollowsData;
var
  G: TPPGDBGrid;
  T: IPPGTableSource;
begin
  G := NewGrid;
  Supports(G, IPPGTableSource, T);
  CheckEquals(60, T.TableRowCount);
  FData.AppendRecord([61, 'Neu', 1.0, Date]);
  CheckEquals(61, T.TableRowCount, 'nach Aenderung neu gelesen');
  CheckEquals('Neu', T.TableCellText(1, 60));
end;

procedure TDBGridColumnTests.PrintWholeDataSet;
var
  G: TPPGDBGrid;
  P: TPPGGridPrinter;
  D: TPPGPrintDevice;
  Bmp: TBitmap;
  I, Rows: Integer;
begin
  G := NewGrid;
  P := TPPGGridPrinter.Create(nil);
  try
    P.Grid := G;
    D := TPPGPrintDevice.A4(96, False);
    Rows := 0;
    for I := 0 to P.PageCount(D) - 1 do
      Inc(Rows, P.Page(I).RowCount);
    CheckEquals(60, Rows, 'alle Saetze gedruckt');
    Bmp := TBitmap.Create;
    try
      Bmp.SetSize(D.PageWidth, D.PageHeight);
      P.RenderPage(0, Bmp.Canvas.Handle, D);
    finally
      Bmp.Free;
    end;
  finally
    P.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterTest('Phase13g', TDBGridColumnTests.Suite);

end.
