unit PPG.Tests.Phase13e;

{ Tests fuer Phase 13e: TPPGGridPrinter (Seitenaufteilung, Platzhalter,
  Zeichnen einer Seite), Vorschau und Seite einrichten. Gedruckt wird nicht:
  Seiten werden auf Bitmaps gezeichnet. }

interface

uses
  TestFramework, Winapi.Windows, System.Classes, System.SysUtils, System.Types,
  System.Variants, Vcl.Graphics, Vcl.Forms, Vcl.Printers, Vcl.Controls,
  PPG.Grid, PPG.Grid.Columns, PPG.Grid.Data, PPG.Grid.Styles, PPG.Grid.Print,
  PPG.Tests.Controls, PPG.Exceptions;

type
  /// Virtuelle Quelle, die zaehlt, welche Zeilen gelesen werden.
  TCountingSource = class(TInterfacedObject, IPPGTableSource)
  public
    Rows, Cols, Width: Integer;
    MinRead, MaxRead: Integer;
    constructor Create(ARows, ACols, AWidth: Integer);
    function TableColCount: Integer;
    function TableRowCount: Integer;
    function TableColumn(ACol: Integer): TPPGTableColumnInfo;
    function TableCellText(ACol, ARow: Integer): string;
    function TableCellValue(ACol, ARow: Integer): Variant;
  end;

  TGridPrintTests = class(TControlTestCase)
  private
    FPrn: TPPGGridPrinter;
    function RenderToBmp(PageIndex: Integer; const Dev: TPPGPrintDevice): TBitmap;
    function NonWhite(B: TBitmap; const R: TRect): Integer;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure DeviceA4AndMargins;
    procedure RowsSplitIntoPages;
    procedure RepeatHeaderOff;
    procedure ColumnsAcrossPages;
    procedure FitToWidthScales;
    procedure Placeholders;
    procedure RenderDrawsContent;
    procedure VirtualRowsPerPage;
    procedure GridAsSource;
    procedure EmptySource;
    procedure PreviewForm;
    procedure PageSetupApplies;
    procedure DfmRoundTrip;
    procedure MarginsClampWhileLoading;
    procedure FreedSourceComponentIsDropped;
  end;

implementation

{ TCountingSource }

constructor TCountingSource.Create(ARows, ACols, AWidth: Integer);
begin
  inherited Create;
  Rows := ARows;
  Cols := ACols;
  Width := AWidth;
  MinRead := MaxInt;
  MaxRead := -1;
end;

function TCountingSource.TableColCount: Integer;
begin
  Result := Cols;
end;

function TCountingSource.TableRowCount: Integer;
begin
  Result := Rows;
end;

function TCountingSource.TableColumn(ACol: Integer): TPPGTableColumnInfo;
begin
  Result.Title := 'Spalte ' + IntToStr(ACol);
  Result.Width := Width;
  Result.Alignment := taLeftJustify;
end;

function TCountingSource.TableCellText(ACol, ARow: Integer): string;
begin
  if ARow < MinRead then
    MinRead := ARow;
  if ARow > MaxRead then
    MaxRead := ARow;
  Result := Format('%d/%d', [ARow, ACol]);
end;

function TCountingSource.TableCellValue(ACol, ARow: Integer): Variant;
begin
  Result := TableCellText(ACol, ARow);
end;

{ TGridPrintTests }

procedure TGridPrintTests.SetUp;
begin
  inherited SetUp;
  FPrn := TPPGGridPrinter.Create(nil);
  FPrn.FooterText := 'Seite [Seite] von [Seiten]';
end;

procedure TGridPrintTests.TearDown;
begin
  FreeAndNil(FPrn);
  inherited TearDown;
end;

function TGridPrintTests.RenderToBmp(PageIndex: Integer; const Dev: TPPGPrintDevice): TBitmap;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(Dev.PageWidth, Dev.PageHeight);
  Result.Canvas.Brush.Color := clWhite;
  Result.Canvas.FillRect(Rect(0, 0, Dev.PageWidth, Dev.PageHeight));
  FPrn.RenderPage(PageIndex, Result.Canvas.Handle, Dev);
end;

function TGridPrintTests.NonWhite(B: TBitmap; const R: TRect): Integer;
var
  X, Y: Integer;
begin
  Result := 0;
  Y := R.Top;
  while Y < R.Bottom do
  begin
    X := R.Left;
    while X < R.Right do
    begin
      if B.Canvas.Pixels[X, Y] <> clWhite then
        Inc(Result);
      Inc(X, 2);
    end;
    Inc(Y, 2);
  end;
end;

procedure TGridPrintTests.DeviceA4AndMargins;
var
  D: TPPGPrintDevice;
  R: TRect;
begin
  D := TPPGPrintDevice.A4(254, False); // 10 Punkte je mm
  CheckEquals(2100, D.PhysWidth);
  CheckEquals(2970, D.PhysHeight);
  CheckEquals(40, D.OffsetX, '4 mm nicht bedruckbar');
  D := TPPGPrintDevice.A4(254, True);
  CheckEquals(2970, D.PhysWidth, 'quer');
  D := TPPGPrintDevice.A4(254, False);
  FPrn.SetSource(TCountingSource.Create(1, 1, 50));
  FPrn.Margins.Left := 20;
  FPrn.Margins.Top := 10;
  FPrn.Layout(D);
  R := FPrn.ContentRect;
  CheckEquals(200 - 40, R.Left, 'Rand ab Blattkante, abzueglich nicht bedruckbar');
  CheckEquals(100 - 40, R.Top);
  CheckEquals(2100 - 150 - 40, R.Right);
  CheckTrue(D.SameAs(TPPGPrintDevice.A4(254, False)));
end;

procedure TGridPrintTests.RowsSplitIntoPages;
var
  D: TPPGPrintDevice;
  Src: TCountingSource;
  N, PerPage, I, Total: Integer;
begin
  D := TPPGPrintDevice.A4(150, False);
  Src := TCountingSource.Create(500, 3, 80);
  FPrn.SetSource(Src);
  N := FPrn.PageCount(D);
  CheckTrue(N > 1, 'mehrere Seiten');
  PerPage := FPrn.Page(0).RowCount;
  CheckEquals((500 + PerPage - 1) div PerPage, N);
  Total := 0;
  for I := 0 to N - 1 do
  begin
    CheckEquals(Total, FPrn.Page(I).RowFirst, 'lueckenlos');
    CheckTrue(FPrn.Page(I).WithHeader, 'Kopf auf jeder Seite');
    Inc(Total, FPrn.Page(I).RowCount);
  end;
  CheckEquals(500, Total);
  // Hoeherer Rand -> weniger Zeilen je Seite
  FPrn.Margins.Top := 60;
  CheckTrue(FPrn.PageCount(D) >= N);
  CheckTrue(FPrn.Page(0).RowCount < PerPage);
end;

procedure TGridPrintTests.RepeatHeaderOff;
var
  D: TPPGPrintDevice;
begin
  D := TPPGPrintDevice.A4(150, False);
  FPrn.SetSource(TCountingSource.Create(500, 3, 80));
  FPrn.RepeatHeader := False;
  FPrn.Invalidate;
  FPrn.PageCount(D);
  CheckTrue(FPrn.Page(0).WithHeader);
  CheckFalse(FPrn.Page(1).WithHeader);
  CheckEquals(FPrn.Page(0).RowCount + 1, FPrn.Page(1).RowCount, 'eine Zeile mehr ohne Kopf');
end;

procedure TGridPrintTests.ColumnsAcrossPages;
var
  D: TPPGPrintDevice;
  N: Integer;
begin
  D := TPPGPrintDevice.A4(96, False);
  // 10 Spalten zu 200 px (96 dpi) = 2000 px, die Seite hat etwa 680 px
  FPrn.SetSource(TCountingSource.Create(10, 10, 200));
  FPrn.FitToPageWidth := False;
  N := FPrn.PageCount(D);
  CheckEquals(4, N, '3 Spalten je Seite: 3+3+3+1');
  CheckEquals(0, FPrn.Page(0).ColFirst);
  CheckEquals(3, FPrn.Page(0).ColCount);
  CheckEquals(9, FPrn.Page(3).ColFirst);
  CheckEquals(1, FPrn.Page(3).ColCount);
  CheckEquals(0, FPrn.Page(3).RowFirst, 'erst nach rechts, dann nach unten');
  CheckEquals(200, FPrn.LayoutColWidth(0));
end;

procedure TGridPrintTests.FitToWidthScales;
var
  D: TPPGPrintDevice;
  I, Sum: Integer;
begin
  D := TPPGPrintDevice.A4(96, False);
  FPrn.SetSource(TCountingSource.Create(10, 10, 200));
  CheckEquals(1, FPrn.PageCount(D), 'eingepasst: eine Seite');
  Sum := 0;
  for I := 0 to 9 do
    Inc(Sum, FPrn.LayoutColWidth(I));
  CheckTrue(Sum <= FPrn.ContentRect.Right - FPrn.ContentRect.Left);
  CheckTrue(Sum > (FPrn.ContentRect.Right - FPrn.ContentRect.Left) - 10, 'nutzt die Breite');
end;

procedure TGridPrintTests.Placeholders;
begin
  FPrn.Title := 'Liste';
  CheckEquals('Seite 2 von 5', FPrn.ExpandText('Seite [Seite] von [Seiten]', 2, 5));
  CheckEquals('Page 2 of 5 - Liste', FPrn.ExpandText('Page [page] of [PAGES] - [Title]', 2, 5));
  CheckEquals(DateToStr(Date), FPrn.ExpandText('[Datum]', 1, 1));
  CheckEquals(DateToStr(Date), FPrn.ExpandText('[Date]', 1, 1));
end;

procedure TGridPrintTests.RenderDrawsContent;
var
  D: TPPGPrintDevice;
  B: TBitmap;
  C: TRect;
begin
  D := TPPGPrintDevice.A4(96, False);
  FPrn.SetSource(TCountingSource.Create(30, 3, 120));
  FPrn.HeaderText := '[Titel]';
  FPrn.Title := 'Bericht';
  B := RenderToBmp(0, D);
  try
    C := FPrn.ContentRect;
    CheckTrue(NonWhite(B, Rect(C.Left, C.Top, C.Right, C.Top + 40)) > 0, 'Kopfzeile');
    CheckTrue(NonWhite(B, Rect(C.Left, C.Top + 40, C.Left + 360, C.Top + 400)) > 50, 'Tabelle');
    CheckTrue(NonWhite(B, Rect(C.Left, C.Bottom - 30, C.Right, C.Bottom)) > 0, 'Fusszeile');
    CheckEquals(0, NonWhite(B, Rect(C.Left + 400, C.Top + 60, C.Right, C.Top + 400)),
      'rechts der Spalten frei');
  finally
    B.Free;
  end;
  FPrn.PrintGridLines := False;
  FPrn.PrintColors := False;
  B := RenderToBmp(0, D);
  B.Free;
  FPrn.RenderPage(99, 0, D); // ausserhalb: nichts
end;

procedure TGridPrintTests.VirtualRowsPerPage;
var
  D: TPPGPrintDevice;
  Src: TCountingSource;
  B: TBitmap;
begin
  D := TPPGPrintDevice.A4(96, False);
  Src := TCountingSource.Create(1000000, 4, 100);
  FPrn.SetSource(Src);
  CheckTrue(FPrn.PageCount(D) > 1000);
  B := RenderToBmp(5, D);
  B.Free;
  CheckEquals(FPrn.Page(5).RowFirst, Src.MinRead, 'nur Zeilen der Seite gelesen');
  CheckEquals(FPrn.Page(5).RowFirst + FPrn.Page(5).RowCount - 1, Src.MaxRead);
end;

procedure TGridPrintTests.GridAsSource;
var
  G: TPPGGrid;
  D: TPPGPrintDevice;
  B: TBitmap;
  I: Integer;
  F: TPPGGridConditionalFormat;
  St: TPPGGridCellStyle;
  PS: IPPGGridPrintSource;
begin
  G := TPPGGrid.Create(FForm);
  G.Parent := FForm;
  G.Columns.Add.Title := 'Name';
  G.Columns.Add.Title := 'Wert';
  G.Columns.Add.CellKind := ckCheck;
  G.FixedCols := 0;
  G.RowCount := 21;
  for I := 1 to 20 do
  begin
    G.Cells[0, I] := 'Zeile ' + IntToStr(I);
    G.Cells[1, I] := IntToStr(I);
    G.Cells[2, I] := IntToStr(I mod 2);
  end;
  F := G.ConditionalFormats.Add;
  F.Column := 1;
  F.Rule := crRange;
  F.Value1 := '10';
  FPrn.Grid := G;
  D := TPPGPrintDevice.A4(96, False);
  CheckEquals(1, FPrn.PageCount(D));
  CheckEquals(20, FPrn.Page(0).RowCount);
  CheckTrue(Supports(FPrn.Source, IPPGGridPrintSource, PS));
  St := PS.PrintCellStyle(1, 12, '12');
  CheckTrue(St.Fill <> clNone, 'bedingtes Format im Druck');
  B := RenderToBmp(0, D);
  B.Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
  G.GroupBy([2]);
  FPrn.Invalidate;
  CheckEquals(20, FPrn.Source.TableRowCount, 'nur Datenzeilen, keine Gruppenzeilen');
  G.Free;
  CheckNull(FPrn.Grid, 'FreeNotification');
end;

procedure TGridPrintTests.EmptySource;
var
  D: TPPGPrintDevice;
  B: TBitmap;
begin
  D := TPPGPrintDevice.A4(96, False);
  CheckEquals(1, FPrn.PageCount(D), 'ohne Quelle: eine leere Seite');
  CheckEquals(0, FPrn.Page(0).RowCount);
  B := RenderToBmp(0, D);
  B.Free;
  try
    FPrn.Page(5);
    Fail('Index ausserhalb');
  except
    on E: Exception do
      if E is ETestFailure then
        raise;
  end;
end;

procedure TGridPrintTests.PreviewForm;
var
  F: TPPGPrintPreviewForm;
  I, N: Integer;
begin
  FPrn.SetSource(TCountingSource.Create(400, 3, 100));
  F := TPPGPrintPreviewForm.CreateFor(FPrn);
  try
    F.Show;
    Application.ProcessMessages;
    N := FPrn.PageCount(FPrn.PrinterDevice);
    CheckEquals(N, F.PageList.Items.Count, 'Seitenleiste');
    F.GoToPage(N - 1);
    CheckEquals(N - 1, F.View.PageIndex);
    F.GoToPage(999);
    CheckEquals(N - 1, F.View.PageIndex, 'begrenzt');
    for I := 0 to N - 1 do
      F.View.PageMetafile(I);
    CheckTrue(F.View.CachedPages <= 8, 'nur wenige Seiten im Speicher');
    F.View.Zoom := 100;
    F.View.Zoom := -1;
    F.View.Repaint;
    F.Hide;
  finally
    F.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TGridPrintTests.PageSetupApplies;
var
  F: TPPGPageSetupForm;
begin
  FPrn.Orientation := poPortrait;
  F := TPPGPageSetupForm.CreateFor(FPrn);
  try
    F.Apply; // unveraendert uebernehmen
    CheckTrue(FPrn.Orientation = poPortrait);
    CheckEquals(15, FPrn.Margins.Left);
    CheckEquals('Seite [Seite] von [Seiten]', FPrn.FooterText);
  finally
    F.Free;
  end;
end;

procedure TGridPrintTests.DfmRoundTrip;
var
  M: TMemoryStream;
  P2: TPPGGridPrinter;
begin
  FPrn.Title := 'T';
  FPrn.HeaderText := 'Kopf';
  FPrn.Orientation := poLandscape;
  FPrn.Margins.Bottom := 25;
  FPrn.FitToPageWidth := False;
  FPrn.PrintColors := False;
  FPrn.PrinterName := 'X';
  M := TMemoryStream.Create;
  P2 := TPPGGridPrinter.Create(nil);
  try
    M.WriteComponent(FPrn);
    M.Position := 0;
    M.ReadComponent(P2);
    CheckEquals('T', P2.Title);
    CheckEquals('Kopf', P2.HeaderText);
    CheckTrue(P2.Orientation = poLandscape);
    CheckEquals(25, P2.Margins.Bottom);
    CheckFalse(P2.FitToPageWidth);
    CheckFalse(P2.PrintColors);
    CheckEquals('X', P2.PrinterName);
    CheckEquals('Seite [Seite] von [Seiten]', P2.FooterText);
  finally
    P2.Free;
    M.Free;
  end;
end;

procedure TGridPrintTests.MarginsClampWhileLoading;
var
  Src, Bin: TStringStream;
  P2: TPPGGridPrinter;
begin
  // Audit 08.10.2026: TPPGPrintMargins hatte keinen Owner; PPGCheckRange
  // erkannte das DFM-Laden nicht und warf, das Formular liess sich nicht oeffnen.
  Src := TStringStream.Create('object Prn: TPPGGridPrinter'#13#10'  Margins.Left = 500'#13#10'end'#13#10);
  Bin := TStringStream.Create('');
  P2 := TPPGGridPrinter.Create(nil);
  try
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    Bin.ReadComponent(P2);
    CheckEquals(100, P2.Margins.Left, 'beim Laden geklemmt');
  finally
    P2.Free;
    Bin.Free;
    Src.Free;
  end;
  // Zur Laufzeit bleibt es bei der Exception
  try
    FPrn.Margins.Left := 500;
    Fail('Exception erwartet');
  except
    on E: EPPGPropertyError do
      CheckEquals(15, FPrn.Margins.Left, 'unveraendert');
  end;
end;

procedure TGridPrintTests.FreedSourceComponentIsDropped;
var
  G: TPPGGrid;
  S: IPPGTableSource;
begin
  // Audit 08.10.2026: Source hielt ein Grid als rohe Interface-Referenz;
  // nach dessen Freigabe trafen Druck und _Release freigegebenen Speicher.
  G := TPPGGrid.Create(nil);
  Supports(G, IPPGTableSource, S);
  FPrn.SetSource(S);
  S := nil;
  CheckNotNull(FPrn.Source);
  G.Free;
  CheckNull(FPrn.Source, 'Quelle nach Freigabe weg');
  CheckEquals(1, FPrn.PageCount(TPPGPrintDevice.A4(300, False)), 'leere Seite statt Zugriff auf Freigegebenes');
end;

initialization
  RegisterTest('Phase13e', TGridPrintTests.Suite);

end.
