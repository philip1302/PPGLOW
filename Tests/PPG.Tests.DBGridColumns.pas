unit PPG.Tests.DBGridColumns;

{ Tests fuer Kaestchen- und Nachschlage-Spalten des DB-Grids sowie
  OnDrawColumnCell/DefaultDrawColumnCell/DefaultDrawing. Daten aus
  TClientDataSet im Speicher (MidasLib statisch gelinkt). Gezeichnet wird mit
  PaintTo in eine Bitmap; kein Formular wird angezeigt. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.UITypes, System.Variants, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids,
  Vcl.DBGrids, Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Grid, PPG.Grid.Columns, PPG.Grid.Paint, PPG.DB.Grid, PPG.Theme, PPG.ComboBox,
  PPG.Tests.Controls, PPG.Tests.Phase9c, PPG.TestDesktop;

type
  TDBGridColumnsTests = class(TDBTestCase)
  private
    FOrte: TClientDataSet;
    FOrteSource: TDataSource;
    // Aufzeichnung aus OnDrawColumnCell
    FDrawCalls: Integer;
    FDrawIds: TStringList;
    FDrawSelected: TStringList;
    FFontColor, FBrushColor: TColor;
    FSelBrush: TColor;
    FPaintRedId: Integer;
    FDefaultInEvent: Boolean;
    function NewGrid: TPPGDBGrid;
    function AddCol(G: TPPGDBGrid; const FieldName: string): TPPGDBGridColumn;
    /// Datenmenge mit Kaestchen-Feldern: ID, Flag (Text), Num (Zahl), Aktiv.
    procedure FillFlags;
    /// Liste der Orte (ID 1..3, Name Ort1..Ort3).
    procedure FillOrte;
    function Cell(G: TPPGDBGrid; ACol, ABufRow: Integer): string;
    procedure RecordDraw(Sender: TObject; const Rect: TRect; DataCol: Integer;
      Column: TPPGDBGridColumn; State: TGridDrawState);
    procedure PaintIdRed(Sender: TObject; const Rect: TRect; DataCol: Integer;
      Column: TPPGDBGridColumn; State: TGridDrawState);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure BooleanNullIsGrayed;
    procedure PersistentBooleanColumnIsCheck;
    procedure ValueCheckedStringsAndNumbers;
    procedure ToggleWritesConfiguredValues;
    procedure ClickAndSpaceToggle;
    procedure ReadOnlyAndNoEditingBlockToggle;
    procedure GrayedPaintsOwnState;
    procedure LookupFieldShowsAndWritesKey;
    procedure LookupColumnResolvesAndWritesKey;
    procedure LookupColumnFollowsListChanges;
    procedure LookupColumnEditorListsEntries;
    procedure ExportUsesCheckAndLookup;
    procedure DrawColumnCellSeesDrawnRecord;
    procedure DrawColumnCellCanvasFollowsDarkModeAndSelection;
    procedure DefaultDrawColumnCellFillsBrush;
    procedure DefaultDrawingOffSkipsTextAndCheck;
  end;

implementation

type
  TGridAccess = class(TPPGDBGrid);

{ TDBGridColumnsTests }

procedure TDBGridColumnsTests.SetUp;
begin
  inherited SetUp;
  FOrte := TClientDataSet.Create(FForm);
  FOrteSource := TDataSource.Create(FForm);
  FOrteSource.DataSet := FOrte;
  FDrawIds := TStringList.Create;
  FDrawSelected := TStringList.Create;
  FDrawCalls := 0;
  FPaintRedId := -1;
  FDefaultInEvent := False;
end;

procedure TDBGridColumnsTests.TearDown;
begin
  FreeAndNil(FDrawIds);
  FreeAndNil(FDrawSelected);
  FOrte := nil;
  FOrteSource := nil;
  inherited TearDown;
end;

function TDBGridColumnsTests.NewGrid: TPPGDBGrid;
begin
  Result := TPPGDBGrid.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 520, 24 * 9 + 2); // Titel + 8 Datenzeilen
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.HandleNeeded;
  Result.DataSource := FSource;
end;

function TDBGridColumnsTests.AddCol(G: TPPGDBGrid; const FieldName: string): TPPGDBGridColumn;
begin
  Result := TPPGDBGridColumn(G.Columns.Add);
  Result.FieldName := FieldName;
  Result.Width := 100;
end;

procedure TDBGridColumnsTests.FillFlags;
begin
  FData.Close;
  FData.FieldDefs.Clear;
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Flag', ftString, 5);
  FData.FieldDefs.Add('Num', ftInteger);
  FData.FieldDefs.Add('Aktiv', ftBoolean);
  FData.CreateDataSet;
  FData.AppendRecord([1, 'J', 1, True]);
  FData.AppendRecord([2, 'N', 0, False]);
  FData.AppendRecord([3, 'X', 7, Null]);
  FData.AppendRecord([4, Null, Null, True]);
  FData.First;
end;

procedure TDBGridColumnsTests.FillOrte;
var
  I: Integer;
begin
  FOrte.Close;
  FOrte.FieldDefs.Clear;
  FOrte.FieldDefs.Add('ID', ftInteger);
  FOrte.FieldDefs.Add('Name', ftString, 20);
  FOrte.CreateDataSet;
  for I := 1 to 3 do
    FOrte.AppendRecord([I, 'Ort' + IntToStr(I)]);
  FOrte.First;
end;

function TDBGridColumnsTests.Cell(G: TPPGDBGrid; ACol, ABufRow: Integer): string;
begin
  Result := TGridAccess(G).GetCellText(ACol, TGridAccess(G).FixedRows + ABufRow);
end;

procedure TDBGridColumnsTests.RecordDraw(Sender: TObject; const Rect: TRect; DataCol: Integer;
  Column: TPPGDBGridColumn; State: TGridDrawState);
var
  G: TPPGDBGrid;
begin
  Inc(FDrawCalls);
  G := Sender as TPPGDBGrid;
  if Column.FieldName = 'ID' then
  begin
    // Datenmenge steht auf dem gezeichneten Satz: Column.Field liefert ihn
    FDrawIds.Add(Column.Field.AsString);
    if gdSelected in State then
    begin
      FDrawSelected.Add(Column.Field.AsString);
      FSelBrush := G.Canvas.Brush.Color;
    end
    else
    begin
      FFontColor := G.Canvas.Font.Color;
      FBrushColor := G.Canvas.Brush.Color;
    end;
    CheckTrue(G.Canvas.Brush.Style = bsSolid, 'Pinsel wie TDBGrid in der Zellfarbe');
  end;
  if FDefaultInEvent then
    G.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;

procedure TDBGridColumnsTests.PaintIdRed(Sender: TObject; const Rect: TRect; DataCol: Integer;
  Column: TPPGDBGridColumn; State: TGridDrawState);
var
  G: TPPGDBGrid;
begin
  G := Sender as TPPGDBGrid;
  // Typisches Muster aus TDBGrid-Code: Farbe setzen, Standard zeichnen
  if (G.DataSource.DataSet.FieldByName('ID').AsInteger = FPaintRedId) then
  begin
    G.Canvas.Brush.Color := clRed;
    G.DefaultDrawColumnCell(Rect, DataCol, Column, State);
  end;
end;

procedure TDBGridColumnsTests.BooleanNullIsGrayed;
var
  G: TPPGDBGrid;
begin
  FillFlags;
  G := NewGrid;
  // Automatische Spalten: ID, Flag, Num, Aktiv (Datenspalten 1..4)
  CheckEquals('1', Cell(G, 4, 0));
  CheckEquals('0', Cell(G, 4, 1));
  CheckEquals(PPGGridCheckGrayed, Cell(G, 4, 2), 'Null = grau');
  CheckTrue(TGridAccess(G).CellEditorKind(4, 1) = gekCheck);
  CheckTrue(TGridAccess(G).KindOf(4) <> nil, 'Kaestchen');
  // Ohne Konfiguration bleiben Text-Spalten Text
  CheckEquals('J', Cell(G, 2, 0));
  CheckTrue(TGridAccess(G).KindOf(2) = nil);
end;

procedure TDBGridColumnsTests.PersistentBooleanColumnIsCheck;
var
  G: TPPGDBGrid;
begin
  FillFlags;
  G := NewGrid;
  AddCol(G, 'ID');
  AddCol(G, 'Aktiv'); // ohne EditorKind
  CheckTrue(TGridAccess(G).CellEditorKind(2, 1) = gekCheck, 'Kaestchen statt Texteditor');
  CheckTrue(TGridAccess(G).KindOf(2) <> nil);
  CheckEquals(PPGGridCheckGrayed, Cell(G, 2, 2));
  CheckTrue(G.Columns[1] is TPPGDBGridColumn);
  CheckTrue(TPPGDBGridColumn(G.Columns[1]).Field = FData.FieldByName('Aktiv'), 'Column.Field');
end;

procedure TDBGridColumnsTests.ValueCheckedStringsAndNumbers;
var
  G: TPPGDBGrid;
  C: TPPGDBGridColumn;
begin
  FillFlags;
  G := NewGrid;
  AddCol(G, 'ID');
  C := AddCol(G, 'Flag');
  C.EditorKind := gekCheck;
  C.ValueChecked := 'J;Ja';
  C.ValueUnchecked := 'N';
  C := AddCol(G, 'Num');
  C.CellKind := ckCheck;
  CheckTrue(TGridAccess(G).CellEditorKind(3, 1) = gekCheck, 'CellKind ckCheck: Kaestchen');
  // Flag: J an, N aus, X unbekannt = grau, Null = grau
  CheckEquals('1', Cell(G, 2, 0));
  CheckEquals('0', Cell(G, 2, 1));
  CheckEquals(PPGGridCheckGrayed, Cell(G, 2, 2));
  CheckEquals(PPGGridCheckGrayed, Cell(G, 2, 3));
  // Num ohne Werte: 1 an, alles andere aus, Null grau
  CheckEquals('1', Cell(G, 3, 0));
  CheckEquals('0', Cell(G, 3, 1));
  CheckEquals('0', Cell(G, 3, 2));
  CheckEquals(PPGGridCheckGrayed, Cell(G, 3, 3));
  // Mit Werten: 7 unbekannt = grau
  C.ValueChecked := '1';
  C.ValueUnchecked := '0';
  CheckEquals(PPGGridCheckGrayed, Cell(G, 3, 2), 'Num 7 mit Werteliste');
  // Gross-/Kleinschreibung wie TDBCheckBox egal
  FData.First;
  FData.Edit;
  FData.FieldByName('Flag').AsString := 'ja';
  FData.Post;
  CheckEquals('1', Cell(G, 2, 0));
end;

procedure TDBGridColumnsTests.ToggleWritesConfiguredValues;
var
  G: TPPGDBGrid;
  C: TPPGDBGridColumn;
begin
  FillFlags;
  G := NewGrid;
  AddCol(G, 'ID');
  C := AddCol(G, 'Flag');
  C.EditorKind := gekCheck;
  C.ValueChecked := 'J;Ja';
  C.ValueUnchecked := 'N;Nein';
  C := AddCol(G, 'Num');
  C.EditorKind := gekCheck;
  AddCol(G, 'Aktiv');
  // Satz 1: Flag J -> aus schreibt den ersten Aus-Wert
  TGridAccess(G).SetCellByUser(2, TGridAccess(G).FixedRows, '0');
  CheckTrue(FData.State = dsEdit, 'Bearbeiten-Modus');
  CheckEquals('N', FData.FieldByName('Flag').AsString);
  TGridAccess(G).SetCellByUser(2, TGridAccess(G).FixedRows, '1');
  CheckEquals('J', FData.FieldByName('Flag').AsString);
  // Num ohne Werte: 0/1
  TGridAccess(G).SetCellByUser(3, TGridAccess(G).FixedRows, '0');
  CheckEquals(0, FData.FieldByName('Num').AsInteger);
  FData.Post;
  // Satz 3: Aktiv Null (grau) -> an
  FData.RecNo := 3;
  TGridAccess(G).SetCellByUser(4, TGridAccess(G).FixedRows + 2, '1');
  CheckTrue(FData.FieldByName('Aktiv').AsBoolean);
  // Grau zuruecksetzen leert das Feld
  TGridAccess(G).SetCellByUser(4, TGridAccess(G).FixedRows + 2, PPGGridCheckGrayed);
  CheckTrue(FData.FieldByName('Aktiv').IsNull);
  FData.Post;
  // Gleicher Zustand: kein Bearbeiten-Modus
  TGridAccess(G).SetCellByUser(2, TGridAccess(G).FixedRows + 2, PPGGridCheckGrayed);
  CheckTrue(FData.State = dsBrowse, 'unveraendert');
end;

procedure TDBGridColumnsTests.ClickAndSpaceToggle;
var
  G: TPPGDBGrid;
  R: TRect;
  LP: LPARAM;
  Key: Word;
begin
  FillFlags;
  G := NewGrid;
  AddCol(G, 'ID');
  AddCol(G, 'Aktiv');
  // Klick auf das Kaestchen des aktiven Satzes (ID 1, an)
  R := G.CellRect(2, TGridAccess(G).VisualRow(TGridAccess(G).FixedRows));
  LP := MakeLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
  G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, LP);
  G.Perform(WM_LBUTTONUP, 0, LP);
  CheckFalse(FData.FieldByName('Aktiv').AsBoolean, 'Klick schaltet aus');
  CheckEquals('0', Cell(G, 2, 0));
  // Leertaste auf der Fokuszelle schaltet wieder an
  G.Col := 2;
  Key := VK_SPACE;
  TGridAccess(G).KeyDown(Key, []);
  CheckTrue(FData.FieldByName('Aktiv').AsBoolean, 'Leertaste schaltet an');
  FData.Post;
end;

procedure TDBGridColumnsTests.ReadOnlyAndNoEditingBlockToggle;
var
  G: TPPGDBGrid;
  Key: Word;
begin
  FillFlags;
  G := NewGrid;
  AddCol(G, 'ID');
  AddCol(G, 'Aktiv');
  G.Col := 2;
  G.ReadOnly := True;
  Key := VK_SPACE;
  TGridAccess(G).KeyDown(Key, []);
  CheckTrue(FData.FieldByName('Aktiv').AsBoolean, 'ReadOnly: unveraendert');
  CheckTrue(FData.State = dsBrowse);
  G.ReadOnly := False;
  G.Options := G.Options - [dgEditing];
  Key := VK_SPACE;
  TGridAccess(G).KeyDown(Key, []);
  CheckTrue(FData.FieldByName('Aktiv').AsBoolean, 'ohne dgEditing: unveraendert');
  // Spalte ReadOnly
  G.Options := G.Options + [dgEditing];
  TPPGDBGridColumn(G.Columns[1]).ReadOnly := True;
  G.Col := 2;
  Key := VK_SPACE;
  TGridAccess(G).KeyDown(Key, []);
  CheckTrue(FData.FieldByName('Aktiv').AsBoolean, 'Spalte ReadOnly: unveraendert');
  CheckTrue(FData.State = dsBrowse);
end;

procedure TDBGridColumnsTests.GrayedPaintsOwnState;
var
  G: TPPGDBGrid;
  Bmp: TBitmap;
  P: array[0..2] of TColor;
  I: Integer;
  R: TRect;
begin
  FillFlags;
  G := NewGrid;
  G.Options := G.Options - [dgEditing];
  AddCol(G, 'ID');
  AddCol(G, 'Aktiv');
  FData.Last; // Satz 1..3 ohne Fokus/Auswahl
  Bmp := RenderToBitmap(G);
  try
    for I := 0 to 2 do
    begin
      R := G.CellRect(2, TGridAccess(G).VisualRow(TGridAccess(G).FixedRows + I));
      P[I] := Bmp.Canvas.Pixels[(R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2];
    end;
  finally
    Bmp.Free;
  end;
  // an / aus / grau: drei verschiedene Mitten
  CheckNotEquals(Integer(P[0]), Integer(P[1]), 'an <> aus');
  CheckNotEquals(Integer(P[2]), Integer(P[1]), 'grau <> aus');
end;

procedure TDBGridColumnsTests.LookupFieldShowsAndWritesKey;
var
  G: TPPGDBGrid;
  F: TField;
begin
  FillOrte;
  FData.Close;
  FData.FieldDefs.Clear;
  FData.Fields.Clear;
  F := TIntegerField.Create(FData);
  F.FieldName := 'ID';
  F.DataSet := FData;
  F := TIntegerField.Create(FData);
  F.FieldName := 'OrtID';
  F.DataSet := FData;
  F := TStringField.Create(FData);
  F.FieldName := 'OrtName';
  F.Size := 20;
  F.FieldKind := fkLookup;
  F.KeyFields := 'OrtID';
  F.LookupDataSet := FOrte;
  F.LookupKeyFields := 'ID';
  F.LookupResultField := 'Name';
  F.DataSet := FData;
  FData.CreateDataSet;
  FData.AppendRecord([1, 2]);
  FData.AppendRecord([2, Null]);
  FData.First;
  G := NewGrid;
  AddCol(G, 'ID');
  AddCol(G, 'OrtName');
  CheckEquals('Ort2', Cell(G, 2, 0));
  CheckEquals('', Cell(G, 2, 1));
  CheckTrue(TGridAccess(G).CellEditorKind(2, 1) = gekCombo, 'Auswahlliste');
  CheckTrue(TGridAccess(G).CanEditCell(2, TGridAccess(G).VisualRow(TGridAccess(G).FixedRows)));
  TGridAccess(G).SetCellByUser(2, TGridAccess(G).FixedRows, 'Ort3');
  CheckEquals(3, FData.FieldByName('OrtID').AsInteger, 'Schluessel geschrieben');
  FData.Post;
  CheckEquals('Ort3', Cell(G, 2, 0));
end;

procedure TDBGridColumnsTests.LookupColumnResolvesAndWritesKey;
var
  G: TPPGDBGrid;
  C: TPPGDBGridColumn;
begin
  FillOrte;
  FillData(5); // OrtID = (I mod 3) + 1: 2, 3, 1, 2, 3
  G := NewGrid;
  AddCol(G, 'ID');
  C := AddCol(G, 'OrtID');
  C.ListSource := FOrteSource;
  C.KeyField := 'ID';
  C.ListField := 'Name';
  CheckTrue(C.IsLookup);
  CheckEquals('Ort2', Cell(G, 2, 0));
  CheckEquals('Ort3', Cell(G, 2, 1));
  CheckEquals('Ort1', Cell(G, 2, 2));
  CheckTrue(TGridAccess(G).CellEditorKind(2, 1) = gekCombo, 'Auswahlliste');
  CheckEquals('Ort2', TGridAccess(G).GetEditText(2, TGridAccess(G).FixedRows),
    'Editor zeigt den Text, nicht den Schluessel');
  // Schreiben: Schluessel des Eintrags
  TGridAccess(G).SetCellByUser(2, TGridAccess(G).FixedRows, 'Ort1');
  CheckEquals(1, FData.FieldByName('OrtID').AsInteger);
  FData.Post;
  CheckEquals('Ort1', Cell(G, 2, 0));
  // Unbekannter Text: nichts aendern
  TGridAccess(G).SetCellByUser(2, TGridAccess(G).FixedRows, 'Gibtsnicht');
  CheckTrue(FData.State = dsBrowse, 'unbekannt: unveraendert');
  CheckEquals(1, FData.FieldByName('OrtID').AsInteger);
  // Leer: Schluessel Null
  TGridAccess(G).SetCellByUser(2, TGridAccess(G).FixedRows, '');
  CheckTrue(FData.FieldByName('OrtID').IsNull);
  FData.Cancel;
  // Unbekannter Schluessel in den Daten: leer
  FData.Edit;
  FData.FieldByName('OrtID').AsInteger := 99;
  FData.Post;
  CheckEquals('', Cell(G, 2, 0));
  // Liste geschlossen: nicht bearbeitbar
  FOrte.Close;
  CheckFalse(TGridAccess(G).CanEditCell(2, TGridAccess(G).VisualRow(TGridAccess(G).FixedRows)));
  CheckEquals('', Cell(G, 2, 1));
end;

procedure TDBGridColumnsTests.LookupColumnFollowsListChanges;
var
  G: TPPGDBGrid;
  C: TPPGDBGridColumn;
begin
  FillOrte;
  FillData(3);
  G := NewGrid;
  AddCol(G, 'ID');
  C := AddCol(G, 'OrtID');
  C.ListSource := FOrteSource;
  C.KeyField := 'ID';
  C.ListField := 'Name';
  CheckEquals('Ort2', Cell(G, 2, 0));
  // Eintrag der Liste umbenennen: Zwischenspeicher verworfen
  FOrte.Locate('ID', 2, []);
  FOrte.Edit;
  FOrte.FieldByName('Name').AsString := 'Neustadt';
  FOrte.Post;
  CheckEquals('Neustadt', Cell(G, 2, 0), 'Liste geaendert');
  // ListSource wieder weg: Feldwert bleibt, Spalte zeigt den Schluessel
  C.ListSource := nil;
  CheckFalse(C.IsLookup);
  CheckEquals('2', Cell(G, 2, 0));
  // Freigabe der Listen-DataSource trennt die Spalte
  C.ListSource := FOrteSource;
  CheckEquals('Neustadt', Cell(G, 2, 0));
  FreeAndNil(FOrteSource);
  CheckTrue(C.ListSource = nil, 'DataSource freigegeben');
  CheckEquals('2', Cell(G, 2, 0));
end;

procedure TDBGridColumnsTests.LookupColumnEditorListsEntries;
var
  G: TPPGDBGrid;
  C: TPPGDBGridColumn;
  E: TControl;
begin
  FillOrte;
  FillData(3);
  G := NewGrid;
  AddCol(G, 'ID');
  C := AddCol(G, 'OrtID');
  C.ListSource := FOrteSource;
  C.KeyField := 'ID';
  C.ListField := 'Name';
  // Der Editor braucht ein angezeigtes Formular: nur auf dem unsichtbaren
  // Testdesktop (/hidden), nie auf dem Bildschirm
  if not PPGOnHiddenDesktop then
  begin
    Status('nur mit /hidden');
    Exit;
  end;
  FForm.Show;
  try
    G.Col := 2;
    G.ShowEditor;
    CheckTrue(G.EditorMode, 'Editor offen');
    E := TGridAccess(G).InplaceEditor;
    CheckTrue(E is TPPGComboBox, 'Auswahlliste als Editor');
    CheckEquals(3, TPPGComboBox(E).Items.Count, 'Eintraege der Liste');
    CheckEquals('Ort2', TPPGComboBox(E).Text, 'aktueller Eintrag');
    CheckEquals(1, FOrte.RecNo, 'Listen-Position unveraendert');
    G.HideEditor(False);
  finally
    FForm.Hide;
  end;
end;

procedure TDBGridColumnsTests.ExportUsesCheckAndLookup;
var
  G: TPPGDBGrid;
  C: TPPGDBGridColumn;
begin
  FillOrte;
  FillFlags;
  FData.Close;
  FData.FieldDefs.Add('OrtID', ftInteger);
  FData.CreateDataSet;
  FData.AppendRecord([1, 'J', 1, True, 3]);
  FData.AppendRecord([2, 'X', 0, Null, 1]);
  FData.First;
  G := NewGrid;
  AddCol(G, 'ID');
  C := AddCol(G, 'Flag');
  C.EditorKind := gekCheck;
  C.ValueChecked := 'J';
  C.ValueUnchecked := 'N';
  C := AddCol(G, 'OrtID');
  C.ListSource := FOrteSource;
  C.KeyField := 'ID';
  C.ListField := 'Name';
  CheckEquals(2, TGridAccess(G).TableRowCount);
  CheckEquals('Ort3', TGridAccess(G).TableCellText(2, 0), 'Nachschlage-Text');
  CheckEquals('Ort1', VarToStr(TGridAccess(G).TableCellValue(2, 1)));
  CheckEquals('1', TGridAccess(G).TableCellText(1, 0), 'Kaestchen an');
  CheckTrue(TGridAccess(G).TableCellValue(1, 0) = True);
  CheckEquals(PPGGridCheckGrayed, TGridAccess(G).TableCellText(1, 1), 'grau');
  CheckTrue(VarIsNull(TGridAccess(G).TableCellValue(1, 1)));
  CheckTrue(TGridAccess(G).ExportColumnLook(1).Kind = ckCheck, 'xlsx: Kaestchen');
end;

procedure TDBGridColumnsTests.DrawColumnCellSeesDrawnRecord;
var
  G: TPPGDBGrid;
  Bmp: TBitmap;
begin
  FillData(5);
  G := NewGrid;
  AddCol(G, 'ID');
  AddCol(G, 'Name');
  FData.RecNo := 3;
  G.OnDrawColumnCell := RecordDraw;
  Bmp := RenderToBitmap(G);
  try
    CheckEquals(10, FDrawCalls, '5 Saetze x 2 Spalten, ohne Titel und Fuellzeilen');
    CheckEquals('1,2,3,4,5', FDrawIds.CommaText, 'Column.Field = gezeichneter Satz');
  finally
    Bmp.Free;
  end;
  CheckEquals(3, FData.FieldByName('ID').AsInteger, 'Satzzeiger unveraendert');
  CheckTrue(FData.State = dsBrowse);
end;

procedure TDBGridColumnsTests.DrawColumnCellCanvasFollowsDarkModeAndSelection;
var
  G: TPPGDBGrid;
  Bmp: TBitmap;
begin
  TPPGTheme.Mode := tmDark;
  FillData(5);
  G := NewGrid;
  G.Options := G.Options - [dgEditing] + [dgMultiSelect];
  AddCol(G, 'ID');
  FData.RecNo := 2;
  G.SelectedRows.CurrentRowSelected := True;
  FData.RecNo := 4;
  G.OnDrawColumnCell := RecordDraw;
  Bmp := RenderToBitmap(G);
  try
    CheckTrue(FDrawSelected.IndexOf('2') >= 0, 'gdSelected fuer den gewaehlten Satz');
    CheckTrue(FDrawSelected.IndexOf('1') < 0, 'nicht gewaehlt');
    CheckTrue(GetRValue(ColorToRGB(FBrushColor)) + GetGValue(ColorToRGB(FBrushColor)) +
      GetBValue(ColorToRGB(FBrushColor)) < 3 * 128, 'Flaeche dunkel');
    CheckTrue(GetRValue(ColorToRGB(FFontColor)) + GetGValue(ColorToRGB(FFontColor)) +
      GetBValue(ColorToRGB(FFontColor)) > 3 * 128, 'Text hell');
    CheckNotEquals(Integer(ColorToRGB(FBrushColor)), Integer(ColorToRGB(FSelBrush)),
      'Auswahl hat eigene Flaeche');
  finally
    Bmp.Free;
  end;
end;

procedure TDBGridColumnsTests.DefaultDrawColumnCellFillsBrush;
var
  G: TPPGDBGrid;
  Bmp: TBitmap;
  R2, R3: TRect;
begin
  FillData(5);
  G := NewGrid;
  G.Options := G.Options - [dgEditing];
  AddCol(G, 'ID');
  AddCol(G, 'Name');
  FData.Last;
  FPaintRedId := 2;
  G.OnDrawColumnCell := PaintIdRed;
  Bmp := RenderToBitmap(G);
  try
    R2 := G.CellRect(2, TGridAccess(G).VisualRow(TGridAccess(G).FixedRows + 1));
    R3 := G.CellRect(2, TGridAccess(G).VisualRow(TGridAccess(G).FixedRows + 2));
    CheckEquals(Integer(clRed), Integer(ColorToRGB(Bmp.Canvas.Pixels[R2.Right - 3, R2.Top + 3])),
      'Satz 2 rot');
    CheckNotEquals(Integer(clRed), Integer(ColorToRGB(Bmp.Canvas.Pixels[R3.Right - 3, R3.Top + 3])),
      'Satz 3 nicht');
  finally
    Bmp.Free;
  end;
end;

procedure TDBGridColumnsTests.DefaultDrawingOffSkipsTextAndCheck;

  function Distinct(Bmp: TBitmap; const R: TRect): Integer;
  var
    X, Y: Integer;
    L: TList;
    C: TColor;
  begin
    // Anzahl verschiedener Farben im Inneren der Zelle (Text/Kaestchen > 1)
    L := TList.Create;
    try
      for Y := R.Top + 2 to R.Bottom - 3 do
        for X := R.Left + 2 to R.Right - 3 do
        begin
          C := Bmp.Canvas.Pixels[X, Y];
          if L.IndexOf(Pointer(C)) < 0 then
            L.Add(Pointer(C));
        end;
      Result := L.Count;
    finally
      L.Free;
    end;
  end;

var
  G: TPPGDBGrid;
  Bmp: TBitmap;
  RName, RCheck: TRect;
begin
  FillData(5);
  G := NewGrid;
  G.Options := G.Options - [dgEditing];
  AddCol(G, 'Name');
  AddCol(G, 'Aktiv');
  FData.Last;
  RName := G.CellRect(1, TGridAccess(G).VisualRow(TGridAccess(G).FixedRows));
  RCheck := G.CellRect(2, TGridAccess(G).VisualRow(TGridAccess(G).FixedRows));
  Bmp := RenderToBitmap(G);
  try
    CheckTrue(Distinct(Bmp, RName) > 1, 'mit DefaultDrawing: Text');
    CheckTrue(Distinct(Bmp, RCheck) > 1, 'mit DefaultDrawing: Kaestchen');
  finally
    Bmp.Free;
  end;
  G.DefaultDrawing := False;
  Bmp := RenderToBitmap(G);
  try
    CheckEquals(1, Distinct(Bmp, RName), 'ohne DefaultDrawing: kein Text');
    CheckEquals(1, Distinct(Bmp, RCheck), 'ohne DefaultDrawing: kein Kaestchen');
  finally
    Bmp.Free;
  end;
  // Das Ereignis zeichnet mit DefaultDrawColumnCell selbst
  FDefaultInEvent := True;
  G.OnDrawColumnCell := RecordDraw;
  Bmp := RenderToBitmap(G);
  try
    CheckTrue(Distinct(Bmp, RName) > 1, 'DefaultDrawColumnCell: Text');
    CheckTrue(Distinct(Bmp, RCheck) > 1, 'DefaultDrawColumnCell: Kaestchen');
  finally
    Bmp.Free;
  end;
end;

initialization
  RegisterTest('DBGridColumns', TDBGridColumnsTests.Suite);

end.
