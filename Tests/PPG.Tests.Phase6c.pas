unit PPG.Tests.Phase6c;

{$WARN SYMBOL_PLATFORM OFF}

{ Tests fuer Phase 6c: TPPGGrid. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids,
  PPG.Types, PPG.Consts, PPG.Exceptions, PPG.Render.Registry, PPG.Accessibility,
  PPG.Grid, PPG.Tests.Controls;

type
  TGridTests = class(TControlTestCase)
  private
    FSetEdits: Integer;
    FSorted: Integer;
    FAllowSelect: Boolean;
    FRejectValue: string;
    FFailSetEdit: Boolean;
  protected
    procedure SetUp; override;
  private
    procedure SetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
    procedure Sorted(Sender: TObject);
    procedure SelectCellEvent(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure ValidateCell(Sender: TObject; ACol, ARow: Integer; var Value: string;
      var Accept: Boolean);
    procedure VirtualText(Sender: TObject; ACol, ARow: Integer; var Text: string);
    function NewGrid: TPPGGrid;
    /// 3 Spalten (Name, Zahl, Text), 6 Datenzeilen.
    function SampleGrid: TPPGGrid;
    procedure Key(G: TPPGGrid; VK: Word; Shift: TShiftState = []);
    procedure ClickCell(G: TPPGGrid; ACol, VRow: Integer);
  published
    procedure DefaultsLikeTStringGrid;
    procedure CellsAndBounds;
    procedure LoadsTStringGridDfm;
    procedure RoundTripColumnsAndWidths;
    procedure SortByHeaderClick;
    procedure FilterRowAndSortTogether;
    procedure KeyboardAndRangeSelection;
    procedure MouseSelectsAndOnSelectCellRefuses;
    procedure EditTextCommitAndCancel;
    procedure ValidationKeepsEditorOpen;
    procedure FailedWriteKeepsEditorOpen;
    procedure RejectedEditorClosesBeforeSort;
    procedure LoadLayoutKeepsNarrowColumns;
    procedure FixedRowsBeforeRowCountInDfm;
    procedure TypingStartsEditor;
    procedure ComboAndSpinEditors;
    procedure CheckColumnToggles;
    procedure ClipboardTextAndPaste;
    procedure CsvQuoting;
    procedure ColumnResizeByDragging;
    procedure EditorClosesOnScroll;
    procedure VirtualMillionRows;
    procedure Accessibility;
    procedure PaintAllPresetsAndModes;
    procedure NoHandleOrMemoryLeaks;
  end;

implementation

uses
  PPG.Tests.Visual,
  Winapi.oleacc, PPG.Theme;

type
  TGridAccess = class(TPPGGrid);

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

function CenterOf(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

function AllocatedBytes: NativeUInt;
var
  S: TMemoryManagerState;
  I: Integer;
begin
  GetMemoryManagerState(S);
  Result := S.TotalAllocatedMediumBlockSize + S.TotalAllocatedLargeBlockSize;
  for I := Low(S.SmallBlockTypeStates) to High(S.SmallBlockTypeStates) do
    Inc(Result, S.SmallBlockTypeStates[I].AllocatedBlockCount *
      S.SmallBlockTypeStates[I].UseableBlockSize);
end;

function LoadDfm(const Text: string): TComponent;
var
  Src, Bin: TMemoryStream;
  B: TBytes;
begin
  Src := TMemoryStream.Create;
  Bin := TMemoryStream.Create;
  try
    B := TEncoding.UTF8.GetBytes(Text);
    if Length(B) > 0 then
      Src.WriteBuffer(B[0], Length(B));
    Src.Position := 0;
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    Result := Bin.ReadComponent(nil);
  finally
    Bin.Free;
    Src.Free;
  end;
end;

{ TGridTests }

procedure TGridTests.SetUp;
begin
  inherited SetUp;
  // DUnit verwendet die Testobjekte wieder (Leak-Lauf: zwei Laeufe)
  FSetEdits := 0;
  FSorted := 0;
  FAllowSelect := False;
  FRejectValue := '';
  FFailSetEdit := False;
end;

procedure TGridTests.SetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
begin
  Inc(FSetEdits);
  if FFailSetEdit then
    raise EPPGError.Create('Schreiben abgelehnt');
end;

procedure TGridTests.Sorted(Sender: TObject);
begin
  Inc(FSorted);
end;

procedure TGridTests.SelectCellEvent(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
begin
  CanSelect := FAllowSelect;
end;

procedure TGridTests.ValidateCell(Sender: TObject; ACol, ARow: Integer; var Value: string;
  var Accept: Boolean);
begin
  Accept := Value <> FRejectValue;
end;

procedure TGridTests.VirtualText(Sender: TObject; ACol, ARow: Integer; var Text: string);
begin
  Text := IntToStr(ARow) + ':' + IntToStr(ACol);
end;

function TGridTests.NewGrid: TPPGGrid;
begin
  Result := TPPGGrid.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 360, 240);
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.OnSetEditText := SetEditText;
  Result.HandleNeeded;
  FAllowSelect := True;
end;

function TGridTests.SampleGrid: TPPGGrid;
const
  Names: array[1..6] of string = ('Mutter', 'Schraube', 'Duebel', 'Mutter klein', 'Winkel', 'Kabel');
  Nums: array[1..6] of string = ('10', '2', '33', '2', '100', '7');
var
  I: Integer;
begin
  Result := NewGrid;
  Result.FixedCols := 0;
  Result.ColCount := 3;
  Result.RowCount := 7;
  Result.Cells[0, 0] := 'Name';
  Result.Cells[1, 0] := 'Zahl';
  Result.Cells[2, 0] := 'Text';
  for I := 1 to 6 do
  begin
    Result.Cells[0, I] := Names[I];
    Result.Cells[1, I] := Nums[I];
    Result.Cells[2, I] := 'T' + IntToStr(I);
  end;
end;

procedure TGridTests.Key(G: TPPGGrid; VK: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := VK;
  TGridAccess(G).KeyDown(K, Shift);
end;

procedure TGridTests.ClickCell(G: TPPGGrid; ACol, VRow: Integer);
var
  P: TPoint;
begin
  P := CenterOf(G.CellRect(ACol, VRow));
  G.Perform(WM_MOUSEMOVE, 0, MouseLParam(P.X, P.Y));
  G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
  G.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y));
end;

procedure TGridTests.DefaultsLikeTStringGrid;
var
  G: TPPGGrid;
begin
  G := NewGrid;
  CheckEquals(5, G.ColCount);
  CheckEquals(5, G.RowCount);
  CheckEquals(1, G.FixedCols);
  CheckEquals(1, G.FixedRows);
  CheckEquals(64, G.DefaultColWidth);
  CheckEquals(24, G.DefaultRowHeight);
  CheckTrue(G.Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect]);
  CheckEquals(1, G.Col);
  CheckEquals(1, G.Row);
  CheckEquals(64, G.ColWidths[2]);
  CheckTrue(G.TabStop);
end;

procedure TGridTests.CellsAndBounds;
var
  G: TPPGGrid;
begin
  G := NewGrid;
  G.Cells[3, 4] := 'X';
  CheckEquals('X', G.Cells[3, 4]);
  CheckEquals('', G.Cells[2, 2]);
  try
    G.Cells[5, 0] := 'Y';
    Fail('ausserhalb muss werfen');
  except
    on E: EPPGError do ;
  end;
  G.ColCount := 3;
  G.ColCount := 5;
  CheckEquals('', G.Cells[3, 4], 'beim Verkleinern geloescht');
  try
    G.ColCount := 0;
    Fail('ColCount 0 muss werfen');
  except
    on E: EPPGPropertyError do
      CheckEquals(5, G.ColCount, 'unveraendert');
  end;
end;

procedure TGridTests.LoadsTStringGridDfm;
var
  G: TPPGGrid;
begin
  G := LoadDfm(
    'object StringGrid1: TPPGGrid'#13#10 +
    '  Left = 8'#13#10 +
    '  Top = 8'#13#10 +
    '  Width = 320'#13#10 +
    '  Height = 120'#13#10 +
    '  ColCount = 4'#13#10 +
    '  DefaultColWidth = 70'#13#10 +
    '  FixedCols = 0'#13#10 +
    '  RowCount = 10'#13#10 +
    '  Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing]'#13#10 +
    '  TabOrder = 0'#13#10 +
    '  ColWidths = ('#13#10 +
    '    70'#13#10 +
    '    120'#13#10 +
    '    70'#13#10 +
    '    70)'#13#10 +
    '  RowHeights = ('#13#10 +
    '    24'#13#10 +
    '    40'#13#10 +
    '    24'#13#10 +
    '    24'#13#10 +
    '    24'#13#10 +
    '    24'#13#10 +
    '    24'#13#10 +
    '    24'#13#10 +
    '    24'#13#10 +
    '    24)'#13#10 +
    'end') as TPPGGrid;
  try
    CheckEquals(4, G.ColCount);
    CheckEquals(10, G.RowCount);
    CheckEquals(0, G.FixedCols);
    CheckEquals(120, G.ColWidths[1]);
    CheckEquals(40, G.RowHeights[1]);
    CheckEquals(24, G.RowHeights[2]);
    CheckTrue(goEditing in G.Options);
  finally
    G.Free;
  end;
end;

procedure TGridTests.RoundTripColumnsAndWidths;
var
  G, G2: TPPGGrid;
  S: TMemoryStream;
  C: TPPGGridColumn;
begin
  G := NewGrid;
  C := G.Columns.Add;
  C.Title := 'A';
  C.Width := 120;
  C := G.Columns.Add;
  C.Title := 'B';
  C.EditorKind := gekCombo;
  C.PickList.CommaText := 'x,y';
  CheckEquals(2, G.ColCount, 'Spalten bestimmen ColCount');
  G.RowHeights[1] := 50;
  S := TMemoryStream.Create;
  try
    S.WriteComponent(G);
    S.Position := 0;
    G2 := TPPGGrid.Create(nil);
    try
      S.ReadComponent(G2);
      CheckEquals(2, G2.Columns.Count);
      CheckEquals(2, G2.ColCount);
      CheckEquals(120, G2.ColWidths[0]);
      CheckEquals('x,y', G2.Columns[1].PickList.CommaText);
      CheckTrue(G2.Columns[1].EditorKind = gekCombo);
      CheckEquals(50, G2.RowHeights[1]);
    finally
      G2.Free;
    end;
  finally
    S.Free;
  end;
end;

procedure TGridTests.SortByHeaderClick;
var
  G: TPPGGrid;
  I: Integer;
  S: string;
begin
  FForm.Show;
  try
    G := SampleGrid;
    G.OnSorted := Sorted;
    G.Row := 1; // "Mutter"
    ClickCell(G, 1, 0);
    CheckEquals(1, G.SortColumn);
    CheckTrue(G.SortAscending);
    CheckEquals(1, FSorted);
    S := '';
    for I := 1 to 6 do
      S := S + G.Cells[1, G.DataRow(I)] + ',';
    CheckEquals('2,2,7,10,33,100,', S, 'Zahlen numerisch sortiert');
    CheckEquals('Schraube', G.Cells[0, G.DataRow(1)], 'stabil: gleiche Werte in alter Reihenfolge');
    CheckEquals('Mutter', G.Cells[0, 1], 'Daten selbst unveraendert');
    CheckEquals(1, G.Row, 'Fokus bleibt an der Datenzeile');
    CheckEquals(4, G.FocusRow);
    ClickCell(G, 1, 0);
    CheckFalse(G.SortAscending, 'zweiter Klick: absteigend');
    CheckEquals('100', G.Cells[1, G.DataRow(1)]);
    ClickCell(G, 1, 0);
    CheckEquals(-1, G.SortColumn, 'dritter Klick: unsortiert');
    CheckEquals('Mutter', G.Cells[0, G.DataRow(1)]);
  finally
    FForm.Hide;
  end;
end;

procedure TGridTests.FilterRowAndSortTogether;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.ShowFilterRow := True;
  CheckEquals(-2, G.DataRow(1), 'sichtbare Zeile 1 ist die Filterzeile');
  CheckEquals(1, G.DataRow(2));
  G.Filters[0] := 'mut';
  CheckEquals(1, G.DataRow(2), 'Mutter');
  CheckEquals(4, G.DataRow(3), 'Mutter klein');
  CheckEquals(-1, G.DataRow(4), 'nur zwei Treffer');
  CheckEquals(-1, G.VisualRow(2), 'Schraube herausgefiltert');
  G.SortBy(0, False);
  CheckEquals(4, G.DataRow(2), 'absteigend: Mutter klein zuerst');
  G.ClearFilters;
  CheckEquals(5, G.DataRow(2), 'alle wieder da, absteigend: Winkel zuerst');
  CheckEquals(3, G.DataRow(7), 'Duebel zuletzt');
  CheckEquals(-1, G.DataRow(8));
  G.ShowFilterRow := False;
  CheckEquals(5, G.DataRow(1), 'ohne Filterzeile; absteigend: Winkel');
end;

procedure TGridTests.KeyboardAndRangeSelection;
var
  G: TPPGGrid;
  Sel: TGridRect;
begin
  G := SampleGrid;
  G.Row := 1;
  G.Col := 0;
  Key(G, VK_DOWN);
  CheckEquals(2, G.Row);
  Key(G, VK_RIGHT);
  CheckEquals(1, G.Col);
  Key(G, VK_DOWN, [ssShift]);
  Key(G, VK_RIGHT, [ssShift]);
  Sel := G.Selection;
  CheckEquals(1, Sel.Left);
  CheckEquals(2, Sel.Right);
  CheckEquals(2, Sel.Top);
  CheckEquals(3, Sel.Bottom, 'Umschalt erweitert den Bereich');
  Key(G, VK_END, [ssCtrl]);
  CheckEquals(6, G.Row);
  CheckEquals(2, G.Col);
  Key(G, VK_HOME, [ssCtrl]);
  CheckEquals(1, G.Row);
  CheckEquals(0, G.Col);
  G.Options := G.Options + [goTabs];
  Key(G, VK_TAB);
  CheckEquals(1, G.Col, 'Tab geht weiter');
  G.Options := G.Options + [goRowSelect];
  Sel := G.Selection;
  CheckEquals(0, Sel.Left);
  CheckEquals(2, Sel.Right, 'Zeilenauswahl');
  Key(G, VK_UP);
  CheckEquals(1, G.Row, 'nicht in die Kopfzeile');
end;

procedure TGridTests.MouseSelectsAndOnSelectCellRefuses;
var
  G: TPPGGrid;
begin
  FForm.Show;
  try
    G := SampleGrid;
    ClickCell(G, 2, 3);
    CheckEquals(2, G.Col);
    CheckEquals(3, G.Row);
    CheckTrue(G.Focused);
    G.OnSelectCell := SelectCellEvent;
    FAllowSelect := False;
    ClickCell(G, 0, 5);
    CheckEquals(3, G.Row, 'OnSelectCell verhindert den Wechsel');
  finally
    FForm.Hide;
  end;
end;

procedure TGridTests.EditTextCommitAndCancel;
var
  G: TPPGGrid;
  C: TPPGGridColumn;
begin
  FForm.Show;
  try
    G := SampleGrid;
    C := G.Columns.Add;
    G.Columns.Add;
    G.Columns.Add.ReadOnly := True;
    CheckEquals(3, G.ColCount);
    G.Options := G.Options + [goEditing];
    G.Row := 2;
    G.Col := 0;
    G.SetFocus;
    Key(G, VK_F2);
    CheckTrue(G.EditorMode, 'F2 oeffnet den Editor');
    CheckTrue(G.InplaceEditor is TPPGGridEdit);
    CheckEquals('Schraube', TPPGGridEdit(G.InplaceEditor).Text);
    TPPGGridEdit(G.InplaceEditor).Text := 'Bolzen';
    G.InplaceEditor.Perform(WM_KEYDOWN, VK_RETURN, 0);
    CheckFalse(G.EditorMode, 'Enter uebernimmt');
    CheckEquals('Bolzen', G.Cells[0, 2]);
    CheckEquals(1, FSetEdits, 'OnSetEditText');
    G.ShowEditor;
    TPPGGridEdit(G.InplaceEditor).Text := 'Verworfen';
    G.InplaceEditor.Perform(WM_KEYDOWN, VK_ESCAPE, 0);
    CheckEquals('Bolzen', G.Cells[0, 2], 'Esc verwirft');
    G.Col := 2;
    Key(G, VK_F2);
    CheckFalse(G.EditorMode, 'ReadOnly-Spalte');
    CheckTrue(C <> nil);
  finally
    FForm.Hide;
  end;
end;

procedure TGridTests.ValidationKeepsEditorOpen;
var
  G: TPPGGrid;
begin
  FForm.Show;
  try
    G := SampleGrid;
    G.Options := G.Options + [goEditing];
    G.OnValidateCell := ValidateCell;
    FRejectValue := 'falsch';
    G.Row := 1;
    G.Col := 2;
    G.SetFocus;
    G.ShowEditor;
    TPPGGridEdit(G.InplaceEditor).Text := 'falsch';
    G.InplaceEditor.Perform(WM_KEYDOWN, VK_RETURN, 0);
    CheckTrue(G.EditorMode, 'ungueltig: Editor bleibt offen');
    CheckEquals('T1', G.Cells[2, 1]);
    TPPGGridEdit(G.InplaceEditor).Text := 'richtig';
    G.InplaceEditor.Perform(WM_KEYDOWN, VK_RETURN, 0);
    CheckFalse(G.EditorMode);
    CheckEquals('richtig', G.Cells[2, 1]);
  finally
    FForm.Hide;
  end;
end;

procedure TGridTests.FailedWriteKeepsEditorOpen;
var
  G: TPPGGrid;
  Raised: Boolean;
begin
  // Audit 08.10.2026: Der Editor wurde vor dem Schreiben geschlossen; warf
  // das Schreiben, war die Eingabe weg.
  FForm.Show;
  try
    G := SampleGrid;
    G.Options := G.Options + [goEditing];
    G.Row := 1;
    G.Col := 2;
    G.SetFocus;
    G.ShowEditor;
    TPPGGridEdit(G.InplaceEditor).Text := 'neu';
    FFailSetEdit := True;
    Raised := False;
    try
      G.HideEditor(True);
    except
      on E: EPPGError do
        Raised := True;
    end;
    CheckTrue(Raised, 'Fehler kommt beim Aufrufer an');
    CheckTrue(G.EditorMode, 'Editor bleibt offen');
    CheckEquals('neu', TPPGGridEdit(G.InplaceEditor).Text, 'Eingabe bleibt erhalten');
    FFailSetEdit := False;
    G.HideEditor(True);
    CheckFalse(G.EditorMode);
    CheckEquals('neu', G.Cells[2, 1]);
  finally
    FForm.Hide;
  end;
end;

procedure TGridTests.RejectedEditorClosesBeforeSort;
var
  G: TPPGGrid;
  I: Integer;
begin
  // Audit 08.10.2026: Nach abgelehnter Validierung blieb der Editor offen,
  // Sortieren baute trotzdem um, und der Editor zeigte auf eine andere Zeile.
  FForm.Show;
  try
    G := SampleGrid;
    G.Options := G.Options + [goEditing];
    G.OnValidateCell := ValidateCell;
    FRejectValue := 'falsch';
    G.Row := 1;
    G.Col := 2;
    G.SetFocus;
    G.ShowEditor;
    TPPGGridEdit(G.InplaceEditor).Text := 'falsch';
    G.SortBy(0);
    CheckFalse(G.EditorMode, 'Umbau verwirft den abgelehnten Editor');
    for I := 1 to 6 do
      CheckEquals('T' + IntToStr(I), G.Cells[2, I], 'keine Zeile beschrieben');
  finally
    FForm.Hide;
  end;
end;

procedure TGridTests.LoadLayoutKeepsNarrowColumns;
var
  G: TPPGGrid;
  S: string;
begin
  // Audit 08.10.2026: LoadLayout warf bei Breiten unter MinColWidth mitten im
  // Laden; Sortierung und folgende Spalten fehlten danach.
  G := SampleGrid;
  G.ColWidths[0] := 5;
  G.SortBy(1, False);
  S := G.SaveLayout;
  G.SortBy(-1);
  G.ColWidths[0] := 80;
  G.LoadLayout(S);
  CheckEquals(5, G.ColWidths[0], 'schmale Spalte wieder da');
  CheckEquals(1, G.SortColumn, 'Rest des Layouts geladen');
end;

procedure TGridTests.FixedRowsBeforeRowCountInDfm;
var
  G, G2: TPPGGrid;
  M: TMemoryStream;
begin
  // Audit 08.10.2026: FixedRows wurde vor RowCount gestreamt und beim Laden
  // gegen RowCount = 5 auf 4 geklemmt.
  G := LoadDfm(
    'object Grid1: TPPGGrid'#13#10 +
    '  FixedRows = 6'#13#10 +
    '  RowCount = 20'#13#10 +
    'end') as TPPGGrid;
  try
    CheckEquals(20, G.RowCount);
    CheckEquals(6, G.FixedRows, 'alte Reihenfolge in der DFM');
    M := TMemoryStream.Create;
    try
      M.WriteComponent(G);
      M.Position := 0;
      G2 := TPPGGrid(M.ReadComponent(nil));
      try
        CheckEquals(20, G2.RowCount);
        CheckEquals(6, G2.FixedRows, 'neue Reihenfolge');
      finally
        G2.Free;
      end;
    finally
      M.Free;
    end;
  finally
    G.Free;
  end;
end;

procedure TGridTests.TypingStartsEditor;
var
  G: TPPGGrid;
  K: Char;
begin
  FForm.Show;
  try
    G := SampleGrid;
    G.Options := G.Options + [goEditing];
    G.Row := 1;
    G.Col := 2;
    G.SetFocus;
    K := 'Q';
    TGridAccess(G).KeyPress(K);
    CheckTrue(G.EditorMode, 'Tippen startet den Editor');
    CheckEquals('Q', TPPGGridEdit(G.InplaceEditor).Text, 'mit dem Zeichen');
    G.HideEditor(True);
    CheckEquals('Q', G.Cells[2, 1]);
  finally
    FForm.Hide;
  end;
end;

procedure TGridTests.ComboAndSpinEditors;
var
  G: TPPGGrid;
  C: TPPGGridColumn;
begin
  FForm.Show;
  try
    G := NewGrid;
    G.FixedCols := 0;
    C := G.Columns.Add;
    C.EditorKind := gekCombo;
    C.PickList.CommaText := 'Rot,Gruen,Blau';
    C := G.Columns.Add;
    C.EditorKind := gekSpin;
    C.MinValue := 0;
    C.MaxValue := 10;
    G.Options := G.Options + [goEditing];
    G.Row := 1;
    G.Col := 0;
    G.SetFocus;
    G.ShowEditor;
    CheckTrue(G.InplaceEditor is TPPGGridCombo, 'Auswahl-Editor');
    CheckEquals(3, TPPGGridCombo(G.InplaceEditor).Items.Count);
    TPPGGridCombo(G.InplaceEditor).ItemIndex := 2;
    G.HideEditor(True);
    CheckEquals('Blau', G.Cells[0, 1]);
    G.Col := 1;
    G.ShowEditor;
    CheckTrue(G.InplaceEditor is TPPGGridSpin, 'Zahl-Editor');
    TPPGGridSpin(G.InplaceEditor).Value := 7;
    G.HideEditor(True);
    CheckEquals('7', G.Cells[1, 1]);
  finally
    FForm.Hide;
  end;
end;

procedure TGridTests.CheckColumnToggles;
var
  G: TPPGGrid;
  C: TPPGGridColumn;
begin
  FForm.Show;
  try
    G := NewGrid;
    G.FixedCols := 0;
    C := G.Columns.Add;
    C.EditorKind := gekCheck;
    G.Columns.Add;
    G.Options := G.Options + [goEditing];
    G.Row := 1;
    G.Col := 0;
    Key(G, VK_SPACE);
    CheckEquals('1', G.Cells[0, 1], 'Leertaste schaltet ein');
    ClickCell(G, 0, 1);
    CheckEquals('0', G.Cells[0, 1], 'Klick auf das Kaestchen schaltet aus');
    CheckEquals(2, FSetEdits);
    G.ShowEditor;
    CheckFalse(G.EditorMode, 'Kaestchen haben keinen Editor');
  finally
    FForm.Hide;
  end;
end;

procedure TGridTests.ClipboardTextAndPaste;
var
  G: TPPGGrid;
  R: TGridRect;
begin
  G := SampleGrid;
  R.Left := 0;
  R.Top := 1;
  R.Right := 1;
  R.Bottom := 2;
  G.Selection := R;
  CheckEquals('Mutter'#9'10'#13#10'Schraube'#9'2'#13#10, G.SelectionAsText);
  G.Options := G.Options + [goEditing];
  G.Row := 3;
  G.Col := 1;
  G.PasteText('A'#9'B'#13#10'C'#9'D');
  CheckEquals('A', G.Cells[1, 3]);
  CheckEquals('B', G.Cells[2, 3]);
  CheckEquals('C', G.Cells[1, 4]);
  CheckEquals('D', G.Cells[2, 4]);
  CheckEquals(4, FSetEdits);
end;

procedure TGridTests.CsvQuoting;
var
  G: TPPGGrid;
  L: TStringList;
begin
  G := NewGrid;
  G.ColCount := 2;
  G.RowCount := 2;
  G.Cells[0, 0] := 'a;b';
  G.Cells[1, 0] := 'Er sagte "Hallo"';
  G.Cells[0, 1] := 'Zeile'#13#10'zwei';
  G.Cells[1, 1] := 'normal';
  CheckEquals('"a;b";"Er sagte ""Hallo"""'#13#10'"Zeile'#13#10'zwei";normal'#13#10, G.ToCSV(';'));
  L := TStringList.Create;
  try
    L.Text := G.ToCSV(',');
    CheckEquals('a;b,"Er sagte ""Hallo"""', L[0], 'Komma als Trenner');
  finally
    L.Free;
  end;
end;

procedure TGridTests.ColumnResizeByDragging;
var
  G: TPPGGrid;
  R: TRect;
  Y: Integer;
begin
  FForm.Show;
  try
    G := SampleGrid;
    G.Options := G.Options + [goColSizing];
    R := G.CellRect(0, 0);
    Y := (R.Top + R.Bottom) div 2;
    G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(R.Right - 1, Y));
    G.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(R.Right + 40, Y));
    G.Perform(WM_LBUTTONUP, 0, MouseLParam(R.Right + 40, Y));
    CheckTrue(Abs(G.ColWidths[0] - MulDiv(64 * TGridAccess(G).ScalePPI div 96 + 41, 96,
      TGridAccess(G).ScalePPI)) <= 2, Format('Breite gezogen: %d', [G.ColWidths[0]]));
    CheckEquals(-1, G.SortColumn, 'Ziehen sortiert nicht');
  finally
    FForm.Hide;
  end;
end;

procedure TGridTests.EditorClosesOnScroll;
var
  G: TPPGGrid;
begin
  FForm.Show;
  try
    G := NewGrid;
    G.RowCount := 100;
    G.Options := G.Options + [goEditing];
    G.SetFocus;
    G.ShowEditor;
    CheckTrue(G.EditorMode);
    TPPGGridEdit(G.InplaceEditor).Text := 'Weg';
    G.ScrollBy(0, 100);
    CheckFalse(G.EditorMode, 'Scrollen schliesst den Editor');
    CheckEquals('Weg', G.Cells[1, 1], 'und uebernimmt');
  finally
    FForm.Hide;
  end;
end;

procedure TGridTests.VirtualMillionRows;
var
  G: TPPGGrid;
  Bmp: TBitmap;
begin
  // Audit 11a #7: Laufzeit im Benchmark (Bench11, vorher 1000 ms im Test)
  FForm.Show;
  try
    G := NewGrid;
    G.OnGetCellText := VirtualText;
    G.ColCount := 20;
    G.RowCount := 1000001;
    G.Row := 1000000;
    G.Col := 19;
    Bmp := RenderToBitmap(G);
    Bmp.Free;
    CheckFalse(IsRectEmpty(G.CellRect(19, G.FocusRow)), 'letzte Zelle sichtbar');
    CheckEquals('', G.Cells[19, 1000000], 'virtuell: Cells bleibt leer');
    CheckEquals('1000000:19', TGridAccess(G).AccValue, 'der Text kommt aus dem Ereignis');
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    FForm.Hide;
  end;
end;

procedure TGridTests.Accessibility;
var
  G: TPPGGrid;
  A: IPPGAccessibleChildren;
begin
  G := SampleGrid;
  CheckTrue(Supports(G, IPPGAccessibleChildren, A));
  CheckEquals(ROLE_SYSTEM_TABLE, TGridAccess(G).AccRole);
  CheckEquals(7, A.AccChildCount);
  CheckEquals(ROLE_SYSTEM_COLUMNHEADER, A.AccChildRole(1));
  CheckEquals(ROLE_SYSTEM_ROW, A.AccChildRole(2));
  CheckEquals('Mutter; 10; T1', A.AccChildName(2));
  G.Row := 2;
  G.Col := 1;
  CheckEquals('2', TGridAccess(G).AccValue, 'Wert = Fokuszelle');
end;

procedure TGridTests.PaintAllPresetsAndModes;
var
  Names: TStringList;
  P: Integer;
  Dark, Gdi: Boolean;
  G: TPPGGrid;
begin
  Names := TStringList.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    FForm.Show;
    try
      for P := 0 to Names.Count - 1 do
        for Dark := False to True do
          for Gdi := False to True do
          begin
            if Dark then
              TPPGTheme.Mode := tmDark
            else
              TPPGTheme.Mode := tmLight;
            TPPGRendererRegistry.ForceGdiFallback := Gdi;
            G := SampleGrid;
            G.Preset := Names[P];
            G.ShowFilterRow := True;
            G.SortBy(1);
            G.Columns.Add;
            G.SetFocus;
            PPGPaintCheck(Self, G, 'G');
            G.Free;
          end;
    finally
      FForm.Hide;
      TPPGTheme.Mode := tmLight;
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  finally
    Names.Free;
  end;
  // Audit 11b: Fokus und Deaktiviert sichtbar (GDI+ und GDI); Grid ohne Hover
  FForm.Show;
  G := SampleGrid;
  PPGCheckStates(Self, G, 'Grid', False, True, True, Point(0, 0));
  FForm.Hide;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TGridTests.NoHandleOrMemoryLeaks;

  procedure Cycle;
  var
    I: Integer;
    G: TPPGGrid;
  begin
    for I := 1 to 10 do
    begin
      G := SampleGrid;
      G.Options := G.Options + [goEditing];
      G.ShowFilterRow := True;
      G.SortBy(0);
      G.SetFocus;
      G.ShowEditor;
      RenderToBitmap(G).Free;
      G.Free;
    end;
  end;

var
  Gdi0, User0: Cardinal;
  M0, M1: NativeUInt;
begin
  FForm.Show;
  try
    Cycle;
    Gdi0 := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
    User0 := GetGuiResources(GetCurrentProcess, GR_USEROBJECTS);
    M0 := AllocatedBytes;
    Cycle;
    Cycle;
    M1 := AllocatedBytes;
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS) <= Gdi0 + 2, 'GDI-Handles wachsen');
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_USEROBJECTS) <= User0 + 4, 'USER-Handles wachsen');
    CheckTrue(M1 <= M0 + 4096, Format('Speicher waechst: %d -> %d', [M0, M1]));
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterClass(TPPGGrid);
  RegisterTest('Phase6c', TGridTests.Suite);

end.
