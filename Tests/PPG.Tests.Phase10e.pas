unit PPG.Tests.Phase10e;

{ Tests fuer Phase 10e: TPPGDBChart (PPG.DB.Chart). Datenmenge ist ein
  TClientDataSet im Speicher (MidasLib statisch gelinkt). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.DateUtils, Vcl.Controls, Vcl.Forms, Vcl.Graphics,
  Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Types, PPG.Exceptions, PPG.Chart.Series, PPG.Chart, PPG.DB.Chart, PPG.Tests.Controls;

type
  TDBChartTests = class(TControlTestCase)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    procedure FillData(N: Integer);
    function NewChart: TPPGDBChart;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure LoadsAllRecordsAndKeepsPosition;
    procedure ActivationLoadsWithoutDelay;
    procedure MaxRecordsLimits;
    procedure ChangesReloadDelayed;
    procedure OwnReadingDoesNotReschedule;
    procedure EditInProgressIsNotPosted;
    procedure ScrollMarksCurrentRecord;
    procedure ClickJumpsToRecord;
    procedure DateFieldOnDateAxis;
    procedure ClosedDataSetClearsSeries;
    procedure MissingFieldAndNullValues;
    procedure DataSourceFreedIsSafe;
    procedure StreamingKeepsFieldOptions;
    procedure PaintsWithData;
  end;

implementation

uses
  PPG.Tests.Visual, PPG.Render.Registry;

type
  TDBChartAccess = class(TPPGDBChart);

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

const
  Monate: array[0..11] of string = ('Jan', 'Feb', 'Mrz', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug',
    'Sep', 'Okt', 'Nov', 'Dez');

procedure TDBChartTests.SetUp;
begin
  inherited SetUp;
  FForm.SetBounds(0, 0, 500, 360);
  FData := TClientDataSet.Create(FForm);
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
end;

procedure TDBChartTests.TearDown;
begin
  FData := nil;
  FSource := nil;
  inherited TearDown;
end;

procedure TDBChartTests.FillData(N: Integer);
var
  I: Integer;
begin
  FData.Close;
  FData.FieldDefs.Clear;
  FData.FieldDefs.Add('Monat', ftString, 10);
  FData.FieldDefs.Add('Umsatz', ftFloat);
  FData.FieldDefs.Add('Kosten', ftFloat);
  FData.FieldDefs.Add('Datum', ftDate);
  FData.CreateDataSet;
  FData.FieldByName('Umsatz').DisplayLabel := 'Umsatz (EUR)';
  for I := 0 to N - 1 do
  begin
    FData.Append;
    FData.FieldByName('Monat').AsString := Monate[I mod 12];
    FData.FieldByName('Umsatz').AsFloat := 100 + I * 10;
    FData.FieldByName('Kosten').AsFloat := 80 + I * 5;
    FData.FieldByName('Datum').AsDateTime := EncodeDate(2026, 1, 1) + I * 7;
    FData.Post;
  end;
  FData.First;
end;

function TDBChartTests.NewChart: TPPGDBChart;
begin
  Result := TPPGDBChart.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 420, 280);
  Result.Animation.Enabled := False;
  Result.ReloadDelay := 0;
  Result.ValueFields := 'Umsatz;Kosten';
  Result.LabelField := 'Monat';
  Result.DataSource := FSource;
end;

procedure TDBChartTests.LoadsAllRecordsAndKeepsPosition;
var
  C: TPPGDBChart;
begin
  FillData(12);
  FData.RecNo := 5;
  C := NewChart;
  CheckEquals(12, C.LoadedCount);
  CheckEquals(2, C.Series.Count, 'je Feld eine Serie');
  CheckEquals('Umsatz (EUR)', C.Series[0].Title, 'DisplayLabel');
  CheckEquals('Kosten', C.Series[1].Title);
  CheckEquals(12, C.Series[0].Count);
  CheckEquals(150, C.Series[0].Y[5], 1E-9);
  CheckEquals(85, C.Series[1].Y[1], 1E-9);
  CheckEquals('Mrz', C.XLabel(0, 2));
  CheckEquals(5, FData.RecNo, 'aktueller Datensatz bleibt');
  // Eigene Serientitel werden nicht ueberschrieben
  C.Series[1].Title := 'Aufwand';
  C.Reload;
  CheckEquals('Aufwand', C.Series[1].Title);
end;

procedure TDBChartTests.ActivationLoadsWithoutDelay;
var
  C: TPPGDBChart;
begin
  // Regressionstest: das erste Laden wartete ReloadDelay ab, das Diagramm
  // blieb bis dahin leer ("Keine Daten" in Demo-Export)
  FillData(6);
  C := TPPGDBChart.Create(FForm);
  C.Parent := FForm;
  C.ReloadDelay := 500;
  C.ValueFields := 'Umsatz';
  C.DataSource := FSource;
  CheckEquals(6, C.Series[0].Count, 'sofort beim Anbinden');
  CheckFalse(C.ReloadPending);
  FData.Close;
  CheckEquals(0, C.Series[0].Count, 'sofort beim Schliessen');
  FData.Open;
  CheckEquals(6, C.Series[0].Count, 'sofort beim Oeffnen');
end;

procedure TDBChartTests.MaxRecordsLimits;
var
  C: TPPGDBChart;
begin
  FillData(30);
  C := NewChart;
  CheckEquals(30, C.Series[0].Count);
  C.MaxRecords := 5;
  CheckEquals(5, C.Series[0].Count);
  CheckEquals(5, C.LoadedCount);
  try
    C.MaxRecords := 0;
    Fail('EPPGPropertyError erwartet');
  except
    on EPPGPropertyError do;
  end;
  CheckEquals(5, C.MaxRecords);
end;

procedure TDBChartTests.ChangesReloadDelayed;
var
  C: TPPGDBChart;
begin
  FillData(6);
  C := NewChart;
  C.ReloadDelay := 100;
  FData.RecNo := 3;
  FData.Edit;
  FData.FieldByName('Umsatz').AsFloat := 999;
  FData.Post;
  CheckTrue(C.ReloadPending, 'verzoegert');
  CheckEquals(120, C.Series[0].Y[2], 1E-9, 'noch alter Wert');
  C.FlushReload;
  CheckFalse(C.ReloadPending);
  CheckEquals(999, C.Series[0].Y[2], 1E-9, 'neuer Wert');
  // Neuer Datensatz
  FData.Append;
  FData.FieldByName('Umsatz').AsFloat := 1;
  FData.Post;
  C.FlushReload;
  CheckEquals(7, C.Series[0].Count);
  // Ohne Verzoegerung sofort
  C.ReloadDelay := 0;
  FData.Delete;
  CheckFalse(C.ReloadPending);
  CheckEquals(6, C.Series[0].Count);
end;

procedure TDBChartTests.OwnReadingDoesNotReschedule;
var
  C: TPPGDBChart;
begin
  FillData(10);
  C := NewChart;
  C.ReloadDelay := 100;
  C.Reload;
  // EnableControls nach dem Lesen meldet DataSetChanged - das darf kein
  // neues Laden ausloesen (sonst Endlosschleife)
  CheckFalse(C.ReloadPending, 'eigenes Lesen');
  FData.Next;
  CheckFalse(C.ReloadPending, 'Blaettern laedt nicht neu');
end;

procedure TDBChartTests.EditInProgressIsNotPosted;
var
  C: TPPGDBChart;
begin
  FillData(5);
  C := NewChart; // ReloadDelay = 0: jede Meldung laedt sofort
  FData.RecNo := 2;
  FData.Edit;
  FData.FieldByName('Umsatz').AsFloat := 555;
  // Regressionstest: Reload rief First auf und speicherte die Eingabe
  CheckTrue(FData.State = dsEdit, 'Bearbeitung laeuft weiter');
  CheckTrue(C.ReloadPending, 'Laden wartet');
  FData.Cancel;
  CheckEquals(110, FData.FieldByName('Umsatz').AsFloat, 1E-9, 'Abbruch moeglich');
  CheckFalse(C.ReloadPending);
  FData.Edit;
  FData.FieldByName('Umsatz').AsFloat := 555;
  FData.Post;
  CheckEquals(555, C.Series[0].Y[1], 1E-9, 'nach Post gelesen');
  CheckEquals(2, FData.RecNo);
end;

procedure TDBChartTests.ScrollMarksCurrentRecord;
var
  C: TPPGDBChart;
begin
  FillData(8);
  C := NewChart;
  FData.RecNo := 4;
  CheckEquals(3, TDBChartAccess(C).MarkedIndex);
  FData.Last;
  CheckEquals(7, TDBChartAccess(C).MarkedIndex);
  C.ShowCurrentRecord := False;
  CheckEquals(-1, TDBChartAccess(C).MarkedIndex);
end;

procedure TDBChartTests.ClickJumpsToRecord;
var
  C: TPPGDBChart;
  P: TPoint;
begin
  FForm.Show;
  try
    FillData(8);
    C := NewChart;
    C.Series[0].Kind := cskColumn;
    CheckTrue(C.PointPos(0, 6, P));
    C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y + 3));
    C.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y + 3));
    CheckEquals(7, FData.RecNo, 'Sprung zum Datensatz');
    C.JumpToRecord := False;
    CheckTrue(C.PointPos(0, 1, P));
    C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y + 3));
    C.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y + 3));
    CheckEquals(7, FData.RecNo, 'JumpToRecord aus');
  finally
    FForm.Hide;
  end;
end;

procedure TDBChartTests.DateFieldOnDateAxis;
var
  C: TPPGDBChart;
  L: TPPGChartLayout;
begin
  FillData(10);
  C := NewChart;
  C.XAxis.Kind := cxkDateTime;
  C.XField := 'Datum';
  CheckEquals(EncodeDate(2026, 1, 8), C.Series[0].Points[1].X, 1E-9);
  L := C.Layout;
  CheckTrue(L.DateScale.Min <= EncodeDate(2026, 1, 1));
  CheckTrue(L.DateScale.Max >= EncodeDate(2026, 1, 1) + 63);
end;

procedure TDBChartTests.ClosedDataSetClearsSeries;
var
  C: TPPGDBChart;
begin
  FillData(5);
  C := NewChart;
  CheckEquals(5, C.Series[0].Count);
  FData.Close;
  CheckEquals(0, C.Series[0].Count, 'geschlossen = leer');
  CheckEquals(0, C.LoadedCount);
  FData.Open;
  CheckEquals(5, C.Series[0].Count, 'wieder offen');
end;

procedure TDBChartTests.MissingFieldAndNullValues;
var
  C: TPPGDBChart;
begin
  FillData(4);
  FData.First;
  FData.Edit;
  FData.FieldByName('Kosten').Clear;
  FData.Post;
  C := NewChart;
  // Audit 4b: NULL ist kein Wert 0 - der Punkt entfaellt
  CheckEquals(3, C.Series[1].Count, 'NULL: kein Punkt');
  CheckEquals(4, C.Series[0].Count, 'andere Serie vollstaendig');
  C.ValueFields := 'Umsatz;GibtsNicht';
  CheckEquals(0, C.Series[1].Count, 'fehlendes Feld: leere Serie statt Fehler');
  C.LabelField := 'GibtsAuchNicht';
  CheckEquals(4, C.Series[0].Count);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TDBChartTests.DataSourceFreedIsSafe;
var
  C: TPPGDBChart;
begin
  FillData(3);
  C := NewChart;
  FreeAndNil(FSource);
  CheckNull(C.DataSource, 'Verweis geloescht');
  C.Reload;
  CheckEquals(0, C.Series[0].Count);
  FForm.Show;
  try
    RenderToBitmap(C).Free;
  finally
    FForm.Hide;
  end;
end;

procedure TDBChartTests.StreamingKeepsFieldOptions;
var
  C, C2: TPPGDBChart;
  M: TMemoryStream;
begin
  RegisterClass(TPPGDBChart);
  C := TPPGDBChart.Create(nil);
  try
    C.ValueFields := 'A;B';
    C.LabelField := 'L';
    C.XField := 'X';
    C.MaxRecords := 500;
    C.ReloadDelay := 250;
    C.ShowCurrentRecord := False;
    C.JumpToRecord := False;
    M := TMemoryStream.Create;
    try
      M.WriteComponent(C);
      M.Position := 0;
      C2 := M.ReadComponent(nil) as TPPGDBChart;
    finally
      M.Free;
    end;
    try
      CheckEquals('A;B', C2.ValueFields);
      CheckEquals('L', C2.LabelField);
      CheckEquals('X', C2.XField);
      CheckEquals(500, C2.MaxRecords);
      CheckEquals(250, C2.ReloadDelay);
      CheckFalse(C2.ShowCurrentRecord);
      CheckFalse(C2.JumpToRecord);
    finally
      C2.Free;
    end;
  finally
    C.Free;
  end;
end;

procedure TDBChartTests.PaintsWithData;
var
  C: TPPGDBChart;
  A, B: TBitmap;
  Gdi: Boolean;
begin
  FForm.Show;
  try
    FillData(12);
    C := NewChart;
    C.Series[0].Kind := cskColumn;
    FData.RecNo := 3;
    PPGPaintCheck(Self, C, 'C');
    C.XAxis.Kind := cxkDateTime;
    C.XField := 'Datum';
    PPGPaintCheck(Self, C, 'C');
  finally
    FForm.Hide;
  end;
  // Audit 11b: der aktuelle Datensatz ist markiert - anderer Datensatz, anderes
  // Bild (GDI+ und GDI); deaktiviert sichtbar
  FForm.Show;
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    FData.RecNo := 3;
    A := RenderToBitmap(C);
    FData.RecNo := 7;
    B := RenderToBitmap(C);
    try
      PPGCheckPainted(Self, A, 'DBChart');
      PPGCheckDiffers(Self, A, B, 'DBChart Datensatzmarke');
    finally
      A.Free;
      B.Free;
    end;
  end;
  TPPGRendererRegistry.ForceGdiFallback := False;
  PPGCheckStates(Self, C, 'DBChart', False, False, True, Point(0, 0));
  FForm.Hide;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterTest('Phase10e', TDBChartTests.Suite);

end.
