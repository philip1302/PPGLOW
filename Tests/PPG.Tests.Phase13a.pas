unit PPG.Tests.Phase13a;

{ Tests fuer Phase 13a: Schichten des Grids (PPG.Grid.View, PPG.Grid.Data,
  PPG.Grid.Paint, PPG.Grid.Edit). Das Verhalten des Grids selbst pruefen
  weiterhin die Suiten aus Phase 6c/9c unveraendert. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Variants, System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids,
  PPG.Types, PPG.Render.Intf, PPG.Grid, PPG.Grid.Columns, PPG.Grid.View, PPG.Grid.Data,
  PPG.Grid.Paint, PPG.Grid.Edit, PPG.NumberEdit, PPG.Tests.Controls;

type
  /// Host fuer die Ansicht ohne Grid: Werte je Datenzeile.
  TFakeViewHost = class(TInterfacedObject, IPPGGridViewHost)
  public
    Values: TArray<Integer>;
    MinValue: Integer;
    Compares: Integer;
    function ViewRowPasses(ARow: Integer): Boolean;
    function ViewCompareRows(ACol, R1, R2: Integer): Integer;
    function ViewGroupKey(ACol, ARow: Integer): string;
  end;

  TGridViewTests = class(TTestCase)
  private
    FHost: TFakeViewHost;
    FHostRef: IPPGGridViewHost;
    FView: TPPGGridView;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure IdentityWithoutStages;
    procedure FilterKeepsOrder;
    procedure SortIsStable;
    procedure SortDescending;
    procedure FilterThenSort;
    procedure ExtraStageRunsLast;
  end;

  TGridDataTests = class(TControlTestCase)
  published
    procedure CellStoreGrowsAndTruncates;
    procedure CellStoreReportsChange;
    procedure StringSourceValues;
    procedure GridIsTableSourceOfTheView;
    procedure DBStyleCellsUnchanged;
  end;

  TGridPaintEditTests = class(TControlTestCase)
  private
    function NewGrid: TPPGGrid;
  published
    procedure PainterHelpers;
    procedure PainterBatchFlushes;
    procedure CustomCellRendererIsUsed;
    procedure DefaultEditorsRegistered;
    procedure FieldValueEditorWorks;
    procedure TypedCharStartsEditor;
  end;

implementation

uses
  PPG.Render.Registry, PPG.Render.GdiPlus;

{ TFakeViewHost }

function TFakeViewHost.ViewGroupKey(ACol, ARow: Integer): string;
begin
  Result := IntToStr(Values[ARow]);
end;

function TFakeViewHost.ViewRowPasses(ARow: Integer): Boolean;
begin
  Result := Values[ARow] >= MinValue;
end;

function TFakeViewHost.ViewCompareRows(ACol, R1, R2: Integer): Integer;
begin
  Inc(Compares);
  Result := Values[R1] - Values[R2];
end;

type
  /// Zusatzstufe: kehrt die Reihenfolge um.
  TReverseStage = class(TInterfacedObject, IPPGGridViewStage)
  public
    function StageActive: Boolean;
    procedure StageApply(var Rows: TArray<Integer>; const Host: IPPGGridViewHost);
  end;

function TReverseStage.StageActive: Boolean;
begin
  Result := True;
end;

procedure TReverseStage.StageApply(var Rows: TArray<Integer>; const Host: IPPGGridViewHost);
var
  I, T: Integer;
begin
  for I := 0 to Length(Rows) div 2 - 1 do
  begin
    T := Rows[I];
    Rows[I] := Rows[High(Rows) - I];
    Rows[High(Rows) - I] := T;
  end;
end;

{ TGridViewTests }

procedure TGridViewTests.SetUp;
begin
  inherited SetUp;
  FHost := TFakeViewHost.Create;
  FHostRef := FHost;
  // Zeile 0 = Kopf (ausserhalb der Ansicht), Daten ab 1
  FHost.Values := TArray<Integer>.Create(0, 5, 3, 5, 1, 3, 9);
  FHost.MinValue := Low(Integer);
  FView := TPPGGridView.Create;
end;

procedure TGridViewTests.TearDown;
begin
  FreeAndNil(FView);
  FHostRef := nil;
  inherited TearDown;
end;

procedure TGridViewTests.IdentityWithoutStages;
begin
  FView.Rebuild(FHostRef, 1, 7);
  CheckFalse(FView.Mapped, 'ohne Stufe keine Abbildung');
  CheckEquals(6, FView.Count);
  CheckEquals(1, FView.DataRowOf(0));
  CheckEquals(6, FView.DataRowOf(5));
  CheckEquals(-1, FView.DataRowOf(6));
  CheckEquals(-1, FView.DataRowOf(-1));
  CheckEquals(0, FView.ViewIndexOf(1));
  CheckEquals(-1, FView.ViewIndexOf(0), 'Kopf ist keine Ansichtszeile');
  CheckEquals(-1, FView.ViewIndexOf(7));
  CheckEquals(0, FHost.Compares);
end;

procedure TGridViewTests.FilterKeepsOrder;
begin
  FHost.MinValue := 4;
  FView.Filter.Active := True;
  FView.Rebuild(FHostRef, 1, 7);
  CheckTrue(FView.Mapped);
  CheckEquals(3, FView.Count);
  CheckEquals(1, FView.DataRowOf(0));
  CheckEquals(3, FView.DataRowOf(1));
  CheckEquals(6, FView.DataRowOf(2));
  CheckEquals(-1, FView.ViewIndexOf(2), 'herausgefiltert');
  CheckEquals(1, FView.ViewIndexOf(3));
end;

procedure TGridViewTests.SortIsStable;
begin
  FView.Sort.Column := 0;
  FView.Rebuild(FHostRef, 1, 7);
  // Werte 5,3,5,1,3,9 -> 1(4), 3(2), 3(5), 5(1), 5(3), 9(6)
  CheckEquals(4, FView.DataRowOf(0));
  CheckEquals(2, FView.DataRowOf(1));
  CheckEquals(5, FView.DataRowOf(2), 'gleiche Werte behalten ihre Reihenfolge');
  CheckEquals(1, FView.DataRowOf(3));
  CheckEquals(3, FView.DataRowOf(4));
  CheckEquals(6, FView.DataRowOf(5));
  CheckEquals(3, FView.ViewIndexOf(1));
end;

procedure TGridViewTests.SortDescending;
begin
  FView.Sort.Column := 0;
  FView.Sort.Ascending := False;
  FView.Rebuild(FHostRef, 1, 7);
  CheckEquals(6, FView.DataRowOf(0));
  CheckEquals(1, FView.DataRowOf(1), 'stabil auch absteigend');
  CheckEquals(3, FView.DataRowOf(2));
  CheckEquals(4, FView.DataRowOf(5));
end;

procedure TGridViewTests.FilterThenSort;
begin
  FHost.MinValue := 3;
  FView.Filter.Active := True;
  FView.Sort.Column := 0;
  FView.Rebuild(FHostRef, 1, 7);
  CheckEquals(5, FView.Count);
  CheckEquals(2, FView.DataRowOf(0));
  CheckEquals(6, FView.DataRowOf(4));
  CheckEquals(-1, FView.ViewIndexOf(4));
  // zurueck auf Identitaet
  FView.Filter.Active := False;
  FView.Sort.Column := -1;
  FView.Rebuild(FHostRef, 1, 7);
  CheckFalse(FView.Mapped);
  CheckEquals(6, FView.Count);
end;

procedure TGridViewTests.ExtraStageRunsLast;
begin
  FView.AddStage(TReverseStage.Create);
  FView.Sort.Column := 0;
  FView.Rebuild(FHostRef, 1, 7);
  CheckEquals(6, FView.DataRowOf(0), 'nach dem Sortieren umgekehrt');
  CheckEquals(4, FView.DataRowOf(5));
end;

{ TGridDataTests }

procedure TGridDataTests.CellStoreGrowsAndTruncates;
var
  S: TPPGCellStore;
begin
  S := TPPGCellStore.Create;
  try
    S.SetColCount(3);
    CheckEquals('', S.Get(2, 1000), 'leer ohne Speicher');
    S.Put(2, 10, 'x');
    CheckEquals('x', S.Get(2, 10));
    CheckEquals('', S.Get(-1, 10));
    S.Put(5, 1, 'breit');
    CheckEquals('breit', S.Get(5, 1), 'Spalten wachsen mit');
    S.SetColCount(2);
    CheckEquals('', S.Get(2, 10), 'Spalte gekuerzt');
    S.Put(1, 10, 'y');
    S.TruncateRows(5);
    CheckEquals('', S.Get(1, 10), 'Zeile gekuerzt');
    S.Clear;
    CheckEquals('', S.Get(0, 1));
  finally
    S.Free;
  end;
end;

procedure TGridDataTests.CellStoreReportsChange;
var
  S: TPPGCellStore;
begin
  S := TPPGCellStore.Create;
  try
    S.SetColCount(2);
    CheckTrue(S.Put(0, 0, 'a'));
    CheckFalse(S.Put(0, 0, 'a'), 'gleicher Wert');
    CheckFalse(S.Put(1, 3, ''), 'leer bleibt leer');
  finally
    S.Free;
  end;
end;

procedure TGridDataTests.StringSourceValues;
var
  Src: TPPGStringTableSource;
  T: IPPGTableSource;
  OldFS: TFormatSettings;
begin
  OldFS := FormatSettings;
  FormatSettings := TFormatSettings.Create('de-DE');
  try
    Src := TPPGStringTableSource.Create(['Name', 'Preis']);
    T := Src;
    Src.SetColumn(1, 80, taRightJustify);
    CheckEquals(0, Src.AddRow(['Mutter', '1,5']));
    CheckEquals(1, Src.AddRow(['Schraube']));
    CheckEquals(2, T.TableColCount);
    CheckEquals(2, T.TableRowCount);
    CheckEquals('Preis', T.TableColumn(1).Title);
    CheckEquals(80, T.TableColumn(1).Width);
    CheckTrue(T.TableColumn(1).Alignment = taRightJustify);
    CheckEquals('Mutter', T.TableCellText(0, 0));
    CheckTrue(VarIsNumeric(T.TableCellValue(1, 0)), 'Zahl als Zahl');
    CheckEquals(1.5, Double(T.TableCellValue(1, 0)), 0.0001);
    CheckTrue(VarIsNull(T.TableCellValue(1, 1)), 'leer = Null');
    CheckTrue(VarIsStr(T.TableCellValue(0, 1)));
  finally
    FormatSettings := OldFS;
  end;
end;

procedure TGridDataTests.GridIsTableSourceOfTheView;
var
  G: TPPGGrid;
  T: IPPGTableSource;
begin
  G := TPPGGrid.Create(FForm);
  G.Parent := FForm;
  G.Columns.Add.Title := 'Name';
  G.Columns.Add.Alignment := taRightJustify;
  G.FixedCols := 0;
  G.ColCount := 2;
  G.RowCount := 4;
  G.Cells[0, 0] := 'Name';
  G.Cells[1, 0] := 'Zahl';
  G.Cells[0, 1] := 'b';
  G.Cells[1, 1] := '20';
  G.Cells[0, 2] := 'a';
  G.Cells[1, 2] := '3';
  G.Cells[0, 3] := 'c';
  G.Cells[1, 3] := '100';
  CheckTrue(Supports(G, IPPGTableSource, T));
  CheckEquals(2, T.TableColCount);
  CheckEquals(3, T.TableRowCount);
  CheckEquals('Zahl', T.TableColumn(1).Title, 'Titel aus der Kopfzeile');
  CheckTrue(T.TableColumn(1).Alignment = taRightJustify);
  CheckEquals('b', T.TableCellText(0, 0));
  G.SortBy(1, True);
  CheckEquals('a', T.TableCellText(0, 0), 'Export folgt der Sortierung');
  CheckEquals('c', T.TableCellText(0, 2));
  CheckEquals(100, Integer(T.TableCellValue(1, 2)));
  G.Filters[0] := 'b';
  CheckEquals(1, T.TableRowCount, 'und dem Filter');
  CheckEquals('20', T.TableCellText(1, 0));
end;

procedure TGridDataTests.DBStyleCellsUnchanged;
var
  G: TPPGGrid;
begin
  // Cells[] verhaelt sich wie vor dem Umbau (Bereichspruefung, Leerwerte)
  G := TPPGGrid.Create(FForm);
  G.ColCount := 3;
  G.RowCount := 3;
  CheckEquals('', G.Cells[2, 2]);
  G.Cells[2, 2] := 'z';
  CheckEquals('z', G.Cells[2, 2]);
  G.ColCount := 2;
  G.ColCount := 3;
  CheckEquals('', G.Cells[2, 2], 'Spalte beim Verkleinern verworfen');
  try
    G.Cells[3, 0] := 'x';
    Fail('Index ausserhalb');
  except
    on E: Exception do
      if E is ETestFailure then
        raise;
  end;
end;

{ TGridPaintEditTests }

type
  TCountingCellRenderer = class(TInterfacedObject, IPPGGridCellRenderer)
  public
    Checks, Arrows: Integer;
    procedure DrawGridCheck(const ACanvas: IPPGCanvas; const R: TRect; Checked: Boolean;
      const Style: TPPGSurfaceStyle; PPI: Integer);
    procedure DrawGridSortArrow(const ACanvas: IPPGCanvas; const R: TRect;
      Ascending: Boolean; Color: TColor; PPI: Integer);
    procedure DrawGridExpander(const ACanvas: IPPGCanvas; const R: TRect; Color: TColor;
      Expanded, RightToLeft: Boolean; PPI: Integer);
  end;

procedure TCountingCellRenderer.DrawGridExpander(const ACanvas: IPPGCanvas; const R: TRect;
  Color: TColor; Expanded, RightToLeft: Boolean; PPI: Integer);
begin
end;

procedure TCountingCellRenderer.DrawGridCheck(const ACanvas: IPPGCanvas; const R: TRect;
  Checked: Boolean; const Style: TPPGSurfaceStyle; PPI: Integer);
begin
  Inc(Checks);
end;

procedure TCountingCellRenderer.DrawGridSortArrow(const ACanvas: IPPGCanvas; const R: TRect;
  Ascending: Boolean; Color: TColor; PPI: Integer);
begin
  Inc(Arrows);
end;

function TGridPaintEditTests.NewGrid: TPPGGrid;
begin
  Result := TPPGGrid.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 360, 240);
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.HandleNeeded;
end;

procedure TGridPaintEditTests.PainterHelpers;
begin
  CheckTrue(TPPGCellPainter.IsCheckedText('1'));
  CheckTrue(TPPGCellPainter.IsCheckedText('true'));
  CheckTrue(TPPGCellPainter.IsCheckedText('Ja'));
  CheckFalse(TPPGCellPainter.IsCheckedText('0'));
  CheckFalse(TPPGCellPainter.IsCheckedText(''));
  CheckTrue(TPPGCellPainter.TextFlags(taRightJustify) and DT_RIGHT <> 0);
  CheckTrue(TPPGCellPainter.TextFlags(taCenter) and DT_CENTER <> 0);
  CheckTrue(TPPGCellPainter.TextFlags(taLeftJustify) and (DT_RIGHT or DT_CENTER) = 0);
  CheckTrue(TPPGCellPainter.TextFlags(taLeftJustify) and DT_END_ELLIPSIS <> 0);
end;

procedure TGridPaintEditTests.PainterBatchFlushes;
var
  P: TPPGCellPainter;
  B: TBitmap;
  I: Integer;
begin
  P := TPPGCellPainter.Create;
  B := TBitmap.Create;
  try
    B.SetSize(200, 40);
    B.Canvas.Brush.Color := clWhite;
    B.Canvas.FillRect(Rect(0, 0, 200, 40));
    P.Prepare(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName));
    CheckNotNull(P.Cells, 'Standard-Zellrenderer');
    // mehr als die Startkapazitaet: Arrays wachsen
    for I := 0 to 99 do
      P.AddText(Rect(0, 0, 200, 40), 'XXXX', clBlack, TPPGCellPainter.TextFlags(taLeftJustify));
    P.FlushTexts(B.Canvas.Handle, B.Canvas.Font.Handle);
    CheckTrue(B.Canvas.Pixels[4, 20] <> clWhite, 'Text gezeichnet');
    B.Canvas.FillRect(Rect(0, 0, 200, 40));
    P.FlushTexts(B.Canvas.Handle, B.Canvas.Font.Handle);
    CheckEquals(clWhite, B.Canvas.Pixels[4, 20], 'nach Flush leer');
  finally
    B.Free;
    P.Free;
  end;
end;

procedure TGridPaintEditTests.CustomCellRendererIsUsed;
var
  P: TPPGCellPainter;
  CR: TCountingCellRenderer;
  Ref: IPPGGridCellRenderer;
  Bmp: TBitmap;
  G: TPPGGrid;
begin
  // Ein Renderer, der IPPGGridCellRenderer selbst umsetzt, wird direkt genutzt
  CR := TCountingCellRenderer.Create;
  Ref := CR;
  P := TPPGCellPainter.Create;
  try
    P.Prepare(nil);
    CheckNotNull(P.Cells, 'ohne Renderer: Standard');
    CheckFalse(P.Cells = Ref);
    P.Prepare(Ref);
    CheckTrue(P.Cells = Ref, 'eigener Zellrenderer');
    P.DrawCheck(nil, Rect(0, 0, 40, 20), True, Default(TPPGSurfaceStyle), 96);
    P.DrawSortArrow(nil, Rect(0, 0, 40, 20), True, False, clBlack, 96);
    CheckEquals(1, CR.Checks);
    CheckEquals(1, CR.Arrows);
  finally
    P.Free;
  end;
  // Im Grid: Kaestchen und Sortierpfeil gehen ueber den Painter
  G := NewGrid;
  G.FixedCols := 0;
  G.ColCount := 2;
  G.RowCount := 3;
  G.Columns.Add;
  G.Columns.Add.EditorKind := gekCheck;
  G.Cells[1, 1] := '1';
  G.SortBy(0, True);
  Bmp := RenderToBitmap(G);
  try
    CheckTrue(Bmp.Width > 0);
  finally
    Bmp.Free;
  end;
end;

procedure TGridPaintEditTests.DefaultEditorsRegistered;
begin
  CheckTrue(PPGGridEditorClass(gekText) = TPPGGridEdit);
  CheckTrue(PPGGridEditorClass(gekCombo) = TPPGGridCombo);
  CheckTrue(PPGGridEditorClass(gekSpin) = TPPGGridSpin);
  CheckTrue(PPGGridEditorClass(gekNone) = nil);
  CheckTrue(PPGGridEditorClass(gekCheck) = nil);
  // Aliase in PPG.Grid zeigen auf dieselben Klassen
  CheckTrue(PPG.Grid.TPPGGridEdit = PPG.Grid.Edit.TPPGGridEdit);
end;

procedure TGridPaintEditTests.FieldValueEditorWorks;
var
  G: TPPGGrid;
  Old: TPPGGridEditorClass;
begin
  // Ein Phase-12-Feld ohne IPPGGridCellEditor: Text ueber IPPGFieldValue
  Old := PPGGridEditorClass(gekSpin);
  PPGRegisterGridEditor(gekSpin, TPPGNumberEdit);
  FForm.Show;
  try
    G := NewGrid;
    G.FixedCols := 0;
    G.ColCount := 1;
    G.RowCount := 3;
    G.Columns.Add.EditorKind := gekSpin;
    G.Cells[0, 1] := '12';
    G.Options := G.Options + [goEditing];
    G.Row := 1;
    G.Col := 0;
    G.SetFocus;
    G.ShowEditor;
    CheckTrue(G.InplaceEditor is TPPGNumberEdit, 'registrierte Klasse');
    CheckEquals(12, Round(TPPGNumberEdit(G.InplaceEditor).Value));
    TPPGNumberEdit(G.InplaceEditor).Value := 42;
    G.HideEditor(True);
    CheckEquals('42', G.Cells[0, 1]);
  finally
    PPGRegisterGridEditor(gekSpin, Old);
    FForm.Hide;
  end;
end;

procedure TGridPaintEditTests.TypedCharStartsEditor;
var
  G: TPPGGrid;
  C: Char;
begin
  FForm.Show;
  try
    G := NewGrid;
    G.FixedCols := 0;
    G.ColCount := 1;
    G.RowCount := 3;
    G.Options := G.Options + [goEditing];
    G.Row := 1;
    G.Col := 0;
    G.SetFocus;
    C := 'Q';
    G.Perform(WM_CHAR, Ord(C), 0);
    CheckTrue(G.EditorMode);
    CheckEquals('Q', PPGGridEditorText(G.InplaceEditor));
    G.HideEditor(True);
    CheckEquals('Q', G.Cells[0, 1]);
  finally
    FForm.Hide;
  end;
end;

initialization
  RegisterTest('Phase13a', TGridViewTests.Suite);
  RegisterTest('Phase13a', TGridDataTests.Suite);
  RegisterTest('Phase13a', TGridPaintEditTests.Suite);

end.
