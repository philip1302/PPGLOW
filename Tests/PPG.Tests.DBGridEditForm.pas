unit PPG.Tests.DBGridEditForm;

{ Tests fuer das Bearbeitungsformular in der Zeile des DB-Grids (EditMode =
  dgeForm): Vorgaben und Bereiche, Streaming, Raster und Lage (Luecke unter
  der aktiven Zeile, Puffer), Oeffnen und Schliessen (Tasten, Methode,
  Ereignisse), Uebernehmen und Abbrechen, Kaestchen und Nachschlage-Spalte,
  neuer Satz, Fehler beim Schreiben bzw. Buchen, Tastatur im Formular,
  Satzwechsel von aussen, gesperrte Zellen, Kartenansicht, Zeichnen (hell,
  dunkel, GDI), DPI und Scrollen. Dazu der Doppelklick zum Bearbeiten in der
  Tabelle (Zell-Editor und Formular).

  Daten aus einem TClientDataSet im Speicher. Gezeichnet wird mit PaintTo;
  ein Formular wird nur auf dem unsichtbaren Testdesktop (/hidden) angezeigt
  (Tests mit echtem Fokus). Erwartete Masse gelten fuer 96 PPI, BorderStyle =
  bsNone und ScrollBarMode = sbmNever: Grid 640 x 400, Kopf und Zeilen 24,
  Editor 28 hoch, Rand 10, Zeilenabstand 6, Spaltenabstand 16, Beschriftung
  120 + 8, Schaltflaechen 110 x 30. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.UITypes, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.DBGrids, Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Types, PPG.Theme, PPG.Render.Registry, PPG.Controls.Base, PPG.Controls.Scroll,
  PPG.Exceptions, PPG.Grid, PPG.Grid.Edit, PPG.ComboBox, PPG.CheckBox, PPG.DB.Grid,
  PPG.Lang, PPG.Consts, PPG.Tests.Controls, PPG.Tests.Phase9c, PPG.TestDesktop;

type
  TDBGridEditFormTests = class(TDBTestCase)
  private
    FShown: Integer;
    FClosed: Integer;
    FLastAccepted: Boolean;
    FOrte: TClientDataSet;
    FOrteSource: TDataSource;
    /// Grid 640 x 400 mit Spalten ID, Name, Aktiv, Preis; EditMode = dgeForm.
    function NewGrid(N: Integer; AParent: TWinControl = nil): TPPGDBGrid;
    procedure Key(G: TPPGDBGrid; AKey: Word; Shift: TShiftState = []);
    function FormKey(G: TPPGDBGrid; AKey: Word; Shift: TShiftState = []): Boolean;
    /// Datenspalte eines Felds.
    function ColOf(G: TPPGDBGrid; const FieldName: string): Integer;
    function Editor(G: TPPGDBGrid; const FieldName: string): TPPGCustomControl;
    function ItemOf(G: TPPGDBGrid; const FieldName: string): Integer;
    procedure SetText(G: TPPGDBGrid; const FieldName, Value: string);
    procedure ClickCell(G: TPPGDBGrid; ACol, ARow: Integer; DoubleClick: Boolean = False);
    procedure FormShown(Sender: TObject);
    procedure FormClosed(Sender: TObject; Accepted: Boolean);
    procedure RefusePost(DataSet: TDataSet);
  protected
    procedure SetUp; override;
  published
    procedure DefaultsAndRangeChecks;
    procedure StreamingKeepsEditFormProperties;
    procedure LayoutFollowsColumnsAndRaster;
    procedure GapPushesRowsAndShrinksBuffer;
    procedure KeysAndEventsOpenAndClose;
    procedure ApplyPostsAndCancelDiscards;
    procedure CheckBoxAndLookupEditors;
    procedure InsertThroughForm;
    procedure WriteErrorKeepsFormOpen;
    procedure RequiredFieldAndBeforePostKeepFormOpen;
    procedure TabEnterAndEscapeInsideForm;
    procedure RecordChangeFromOutside;
    procedure CellsLockedAndCardsUseCells;
    procedure PaintLightDarkAndGdi;
    procedure DpiScalesForm;
    procedure TallFormScrollsToField;
    procedure DoubleClickOpensCellEditor;
    procedure DoubleClickOpensEditFormWithFocus;
  end;

implementation

type
  TGridAccess = class(TPPGDBGrid);

procedure ForcePPI96(C: TControl);
begin
{$IF CompilerVersion >= 33.0}
  if C.CurrentPPI <> 96 then
    C.ScaleForPPI(96);
{$IFEND}
end;

function Center(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

function RectText(const R: TRect): string;
begin
  Result := Format('(%d,%d,%d,%d)', [R.Left, R.Top, R.Right, R.Bottom]);
end;

function Lum(C: TColor): Integer;
begin
  C := ColorToRGB(C);
  Result := GetRValue(C) + GetGValue(C) + GetBValue(C);
end;

{ TDBGridEditFormTests }

procedure TDBGridEditFormTests.SetUp;
begin
  inherited SetUp;
  FShown := 0;
  FClosed := 0;
  FLastAccepted := False;
  FOrte := nil;
  FOrteSource := nil;
end;

function TDBGridEditFormTests.NewGrid(N: Integer; AParent: TWinControl): TPPGDBGrid;

  procedure AddCol(const FieldName: string);
  begin
    TPPGDBGridColumn(Result.Columns.Add).FieldName := FieldName;
  end;

begin
  FillData(N);
  Result := TPPGDBGrid.Create(FForm);
  if AParent = nil then
    AParent := FForm;
  Result.Parent := AParent;
  ForcePPI96(Result);
  Result.BorderStyle := bsNone;
  Result.ScrollBarMode := sbmNever;
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.SetBounds(0, 0, 640, 400);
  Result.HandleNeeded;
  AddCol('ID');
  AddCol('Name');
  AddCol('Aktiv');
  AddCol('Preis');
  Result.EditMode := dgeForm;
  Result.OnEditFormShow := FormShown;
  Result.OnEditFormClose := FormClosed;
  Result.DataSource := FSource;
end;

procedure TDBGridEditFormTests.Key(G: TPPGDBGrid; AKey: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := AKey;
  TGridAccess(G).KeyDown(K, Shift);
end;

function TDBGridEditFormTests.FormKey(G: TPPGDBGrid; AKey: Word; Shift: TShiftState): Boolean;
begin
  Result := TGridAccess(G).EditFormKey(AKey, Shift);
end;

function TDBGridEditFormTests.ColOf(G: TPPGDBGrid; const FieldName: string): Integer;
var
  I: Integer;
begin
  for I := 0 to G.FieldCount - 1 do
    if SameText(G.Fields[I].FieldName, FieldName) then
      Exit(TGridAccess(G).FixedCols + I);
  Result := -1;
end;

function TDBGridEditFormTests.Editor(G: TPPGDBGrid; const FieldName: string): TPPGCustomControl;
begin
  Result := G.EditFormEditor(ColOf(G, FieldName));
  CheckNotNull(Result, 'Editor fuer ' + FieldName);
end;

function TDBGridEditFormTests.ItemOf(G: TPPGDBGrid; const FieldName: string): Integer;
var
  I: Integer;
begin
  for I := 0 to G.EditFormControl.ItemCount - 1 do
    if G.EditFormControl.ItemDataCol(I) = ColOf(G, FieldName) then
      Exit(I);
  Result := -1;
end;

procedure TDBGridEditFormTests.SetText(G: TPPGDBGrid; const FieldName, Value: string);
begin
  // Wie eine Eingabe des Anwenders: OnChange des Editors meldet die Aenderung
  TPPGGridEdit(Editor(G, FieldName)).Text := Value;
end;

procedure TDBGridEditFormTests.ClickCell(G: TPPGDBGrid; ACol, ARow: Integer; DoubleClick: Boolean);
var
  P: TPoint;
  LP: LPARAM;
begin
  P := Center(G.CellRect(G.VisualCol(ACol), G.VisualRow(ARow)));
  LP := MakeLParam(Word(SmallInt(P.X)), Word(SmallInt(P.Y)));
  G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, LP);
  G.Perform(WM_LBUTTONUP, 0, LP);
  if DoubleClick then
  begin
    G.Perform(WM_LBUTTONDBLCLK, MK_LBUTTON, LP);
    G.Perform(WM_LBUTTONUP, 0, LP);
  end;
end;

procedure TDBGridEditFormTests.FormShown(Sender: TObject);
begin
  Inc(FShown);
end;

procedure TDBGridEditFormTests.FormClosed(Sender: TObject; Accepted: Boolean);
begin
  Inc(FClosed);
  FLastAccepted := Accepted;
end;

procedure TDBGridEditFormTests.RefusePost(DataSet: TDataSet);
begin
  raise EDatabaseError.Create('Abgelehnt');
end;

procedure TDBGridEditFormTests.DefaultsAndRangeChecks;
var
  G: TPPGDBGrid;
  C: TPPGDBGridColumn;
begin
  G := TPPGDBGrid.Create(FForm);
  CheckTrue(G.EditMode = dgeCells, 'Vorgabe: Zellen');
  CheckEquals(2, G.EditForm.ColumnCount);
  CheckEquals(120, G.EditForm.LabelWidth);
  CheckTrue(G.EditForm.ShowButtons);
  CheckFalse(G.EditFormActive);
  CheckNull(G.EditFormControl, 'Formular erst beim Oeffnen');
  C := TPPGDBGridColumn(G.Columns.Add);
  CheckTrue(C.EditFormVisible = efvAuto);
  CheckEquals(1, C.EditFormColSpan);
  try
    G.EditForm.ColumnCount := 0;
    Fail('ColumnCount 0');
  except
    on E: EPPGPropertyError do
      ;
  end;
  try
    G.EditForm.ColumnCount := 9;
    Fail('ColumnCount 9');
  except
    on E: EPPGPropertyError do
      ;
  end;
  CheckEquals(2, G.EditForm.ColumnCount, 'unveraendert');
  try
    G.EditForm.LabelWidth := -1;
    Fail('LabelWidth -1');
  except
    on E: EPPGPropertyError do
      ;
  end;
  try
    C.EditFormColSpan := 0;
    Fail('EditFormColSpan 0');
  except
    on E: EPPGPropertyError do
      ;
  end;
  CheckEquals(1, C.EditFormColSpan, 'unveraendert');
  G.EditForm.ColumnCount := 8;
  G.EditForm.LabelWidth := 0;
  C.EditFormColSpan := 8;
  CheckEquals(8, G.EditForm.ColumnCount);
  CheckEquals(0, G.EditForm.LabelWidth);
  CheckEquals(8, C.EditFormColSpan);
  // Ohne Datenmenge und ohne Fenster: nichts passiert
  G.EditMode := dgeForm;
  G.ShowEditForm;
  CheckFalse(G.EditFormActive, 'ohne Datenmenge kein Formular');
  CheckTrue(G.HideEditForm(True), 'nicht offen: True');
end;

procedure TDBGridEditFormTests.StreamingKeepsEditFormProperties;
var
  G, G2: TPPGDBGrid;
  C: TPPGDBGridColumn;
  M: TMemoryStream;
  T: TStringStream;
begin
  G := TPPGDBGrid.Create(nil);
  M := TMemoryStream.Create;
  T := TStringStream.Create('');
  try
    C := TPPGDBGridColumn(G.Columns.Add);
    C.FieldName := 'Name';
    M.WriteComponent(G);
    M.Position := 0;
    ObjectBinaryToText(M, T);
    CheckEquals(0, Pos('EditMode', T.DataString), 'Vorgabe EditMode nicht gespeichert');
    CheckEquals(0, Pos('ColumnCount', T.DataString), 'Vorgabe ColumnCount nicht gespeichert');
    CheckEquals(0, Pos('EditFormColSpan', T.DataString), 'Vorgabe Spanne nicht gespeichert');
    CheckEquals(0, Pos('EditFormVisible', T.DataString), 'Vorgabe Sichtbarkeit nicht gespeichert');
    G.EditMode := dgeForm;
    G.EditForm.ColumnCount := 3;
    G.EditForm.LabelWidth := 90;
    G.EditForm.ShowButtons := False;
    C.EditFormColSpan := 2;
    C.EditFormVisible := efvShow;
    M.Clear;
    M.WriteComponent(G);
    M.Position := 0;
    G2 := TPPGDBGrid(M.ReadComponent(nil));
    try
      CheckTrue(G2.EditMode = dgeForm, 'EditMode');
      CheckEquals(3, G2.EditForm.ColumnCount, 'ColumnCount');
      CheckEquals(90, G2.EditForm.LabelWidth, 'LabelWidth');
      CheckFalse(G2.EditForm.ShowButtons, 'ShowButtons');
      CheckEquals(2, TPPGDBGridColumn(G2.Columns[0]).EditFormColSpan, 'EditFormColSpan');
      CheckTrue(TPPGDBGridColumn(G2.Columns[0]).EditFormVisible = efvShow, 'EditFormVisible');
    finally
      G2.Free;
    end;
  finally
    T.Free;
    M.Free;
    G.Free;
  end;
end;

procedure TDBGridEditFormTests.LayoutFollowsColumnsAndRaster;
var
  G: TPPGDBGrid;
  P: TPPGDBGridEditForm;
  ACell, ARow, ASpan: Integer;
begin
  G := NewGrid(30);
  G.ShowEditForm;
  CheckTrue(G.EditFormActive, 'offen');
  CheckEquals(1, FShown, 'OnEditFormShow');
  P := G.EditFormControl;
  CheckEquals(4, P.ItemCount, 'vier Felder');
  // Lage: unter der Zeile des aktiven Satzes (Kopf 24 + Zeile 24), ganze Breite
  CheckEquals(RectText(Rect(0, 48, 640, 172)), RectText(P.BoundsRect), 'Formular');
  // Raster 2 Spalten: Zellbreite (640 - 20 - 16) div 2 = 302
  CheckEquals(RectText(Rect(138, 10, 312, 38)), RectText(P.ItemEditor(0).BoundsRect), 'ID');
  CheckEquals(RectText(Rect(10, 10, 130, 38)), RectText(P.ItemLabelRect(0)), 'Beschriftung ID');
  CheckEquals(RectText(Rect(456, 10, 630, 38)), RectText(P.ItemEditor(1).BoundsRect), 'Name');
  CheckEquals(RectText(Rect(138, 44, 312, 72)), RectText(P.ItemEditor(2).BoundsRect), 'Aktiv');
  CheckEquals(RectText(Rect(456, 44, 630, 72)), RectText(P.ItemEditor(3).BoundsRect), 'Preis');
  CheckEquals(RectText(Rect(402, 84, 512, 114)), RectText(P.ApplyButton.BoundsRect), 'Uebernehmen');
  CheckEquals(RectText(Rect(520, 84, 630, 114)), RectText(P.CancelButton.BoundsRect), 'Abbrechen');
  CheckEquals(PPGStr(@SPPGDBGridEditFormApply), P.ApplyButton.Caption);
  CheckTrue(P.ItemEditor(2) is TPPGCheckBox, 'Boolean-Feld als Kaestchen');
  CheckTrue(P.ItemEditor(0) is TPPGGridEdit, 'Text-Editor des Grids');
  CheckEquals('1', TPPGGridEdit(P.ItemEditor(0)).Text, 'Wert ID');
  CheckEquals('Name1', TPPGGridEdit(P.ItemEditor(1)).Text, 'Wert Name');
  CheckEquals('Name', P.ItemEditor(1).Hint, 'Beschriftung als Name');
  // Reihenfolge der Anzeige, Spanne und Sichtbarkeit
  G.HideEditForm(False);
  G.MoveColumn(TGridAccess(G).FixedCols + 3, TGridAccess(G).FixedCols); // Preis nach vorn
  TPPGDBGridColumn(G.Columns[1]).EditFormColSpan := 2;                   // Name ganze Breite
  G.Columns[0].Visible := False;                                         // ID ausgeblendet
  TPPGDBGridColumn(G.Columns[2]).EditFormVisible := efvHide;             // Aktiv nie
  G.ShowEditForm;
  P := G.EditFormControl;
  CheckEquals(2, P.ItemCount, 'ID und Aktiv fehlen');
  CheckEquals(ColOf(G, 'Preis'), P.ItemDataCol(0), 'Preis zuerst');
  CheckEquals(ColOf(G, 'Name'), P.ItemDataCol(1), 'dann Name');
  P.ItemCell(1, ACell, ARow, ASpan);
  CheckEquals(0, ACell, 'Name bricht um');
  CheckEquals(1, ARow);
  CheckEquals(2, ASpan);
  CheckEquals(RectText(Rect(138, 44, 630, 72)), RectText(P.ItemEditor(1).BoundsRect), 'Spanne 2');
  // efvShow: auch die ausgeblendete Spalte
  TPPGDBGridColumn(G.Columns[0]).EditFormVisible := efvShow;
  CheckTrue(G.EditFormActive, 'bleibt offen bei Spaltenaenderung');
  CheckEquals(3, G.EditFormControl.ItemCount, 'ausgeblendete ID mit efvShow');
  // Eine Spalte, ohne Beschriftung: Editor ueber die ganze Breite
  G.EditForm.ColumnCount := 1;
  G.EditForm.LabelWidth := 0;
  CheckEquals(RectText(Rect(10, 10, 630, 38)), RectText(G.EditFormControl.ItemEditor(0).BoundsRect),
    'eine Spalte');
  CheckTrue(IsRectEmpty(G.EditFormControl.ItemLabelRect(0)), 'ohne Beschriftung');
  // RTL: gespiegelt (Beschriftung rechts)
  G.EditForm.ColumnCount := 2;
  G.EditForm.LabelWidth := 120;
  G.BiDiMode := bdRightToLeft;
  G.HandleNeeded;
  G.HideEditForm(False);
  G.ShowEditForm;
  P := G.EditFormControl;
  CheckEquals(RectText(Rect(640 - 130, 10, 640 - 10, 38)), RectText(P.ItemLabelRect(0)),
    'RTL: Beschriftung rechts');
  CheckEquals(RectText(Rect(640 - 312, 10, 640 - 138, 38)), RectText(P.ItemEditor(0).BoundsRect),
    'RTL: Editor links davon');
end;

procedure TDBGridEditFormTests.GapPushesRowsAndShrinksBuffer;
var
  G: TPPGDBGrid;
  FC, FR, C, V: Integer;
  R: TRect;
begin
  G := NewGrid(30);
  FC := TGridAccess(G).FixedCols;
  FR := TGridAccess(G).FixedRows;
  CheckEquals((400 - 24) div 24, TGridAccess(G).DataLink.BufferCount, 'Puffer ohne Formular');
  FData.RecNo := 5;
  CheckEquals(4, TGridAccess(G).DataLink.ActiveRecord, 'Satz 5 = Pufferzeile 4');
  G.ShowEditForm;
  // Hoehe: 2 * 10 + 2 Zeilen * 28 + 6 + 30 + 2 * 6 = 124
  CheckEquals(124, G.EditFormControl.Height, 'Hoehe');
  CheckEquals((400 - 24 - 124) div 24, TGridAccess(G).DataLink.BufferCount, 'Puffer kleiner');
  CheckEquals(5, FData.RecNo, 'Satz bleibt');
  R := G.CellRect(FC, G.VisualRow(FR + TGridAccess(G).DataLink.ActiveRecord));
  CheckEquals(24, R.Bottom - R.Top, 'Zelle der aktiven Zeile normal hoch');
  CheckEquals(R.Bottom, G.EditFormControl.Top, 'Formular direkt darunter');
  R := G.CellRect(FC, G.VisualRow(FR + TGridAccess(G).DataLink.ActiveRecord + 1));
  CheckEquals(G.EditFormControl.Top + 124, R.Top, 'folgende Zeile rueckt nach unten');
  CheckEquals(24, R.Bottom - R.Top);
  CheckFalse(G.MouseCoord(300, G.EditFormControl.Top + 50, C, V), 'Luecke ist keine Zelle');
  CheckTrue(G.MouseCoord(300, R.Top + 5, C, V), 'Zeile darunter');
  CheckEquals(G.VisualRow(FR + TGridAccess(G).DataLink.ActiveRecord + 1), V);
  // Kleineres Grid: Formular wird niedriger (scrollt selbst), Zeile passt
  G.Height := 150;
  CheckEquals(150 - 24 - 24, G.EditFormControl.Height, 'begrenzt auf den Platz');
  CheckEquals(1, TGridAccess(G).DataLink.BufferCount, 'nur die aktive Zeile');
  CheckEquals(5, FData.RecNo, 'Satz bleibt');
  G.Height := 400;
  G.HideEditForm(False);
  CheckEquals((400 - 24) div 24, TGridAccess(G).DataLink.BufferCount, 'Puffer wieder voll');
  R := G.CellRect(FC, G.VisualRow(FR + TGridAccess(G).DataLink.ActiveRecord + 1));
  CheckEquals(24, R.Top - G.CellRect(FC, G.VisualRow(FR + TGridAccess(G).DataLink.ActiveRecord)).Top,
    'keine Luecke mehr');
  CheckFalse(G.EditFormControl.Visible, 'ausgeblendet');
end;

procedure TDBGridEditFormTests.KeysAndEventsOpenAndClose;
var
  G: TPPGDBGrid;
  K: Char;
begin
  G := NewGrid(10);
  Key(G, VK_RETURN);
  CheckTrue(G.EditFormActive, 'Enter oeffnet');
  CheckEquals(1, FShown);
  CheckFalse(G.EditorMode, 'kein Zell-Editor');
  Key(G, VK_ESCAPE);
  CheckFalse(G.EditFormActive, 'Esc schliesst');
  CheckEquals(1, FClosed);
  CheckFalse(FLastAccepted, 'verworfen');
  Key(G, VK_F2);
  CheckTrue(G.EditFormActive, 'F2 oeffnet');
  CheckTrue(G.HideEditForm(True), 'Uebernehmen ohne Aenderung');
  CheckTrue(FLastAccepted, 'uebernommen');
  CheckTrue(FData.State = dsBrowse, 'nichts gebucht');
  // Tippen: oeffnet und beginnt im Feld der Fokusspalte (Name)
  G.Col := ColOf(G, 'Name');
  K := 'X';
  TGridAccess(G).KeyPress(K);
  CheckTrue(G.EditFormActive, 'Tippen oeffnet');
  CheckEquals(ItemOf(G, 'Name'), G.EditFormControl.Current, 'Fokus im Feld der Spalte');
  CheckEquals('X', TPPGGridEdit(Editor(G, 'Name')).Text, 'Zeichen im Editor');
  CheckTrue(FData.State = dsEdit, 'Bearbeiten beim ersten Zeichen');
  G.HideEditForm(False);
  CheckEquals('Name1', FData.FieldByName('Name').AsString, 'verworfen');
  // Zellen-Modus: kein Formular (Enter oeffnet dort den Zell-Editor)
  G.EditMode := dgeCells;
  G.ShowEditForm;
  CheckFalse(G.EditFormActive, 'Zellen-Modus');
  // ReadOnly: kein Formular
  G.EditMode := dgeForm;
  G.ReadOnly := True;
  G.ShowEditForm;
  CheckFalse(G.EditFormActive, 'ReadOnly');
end;

procedure TDBGridEditFormTests.ApplyPostsAndCancelDiscards;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(10);
  FData.RecNo := 3;
  G.ShowEditForm;
  CheckEquals('Name3', TPPGGridEdit(Editor(G, 'Name')).Text);
  SetText(G, 'Name', 'Neu');
  CheckTrue(FData.State = dsEdit, 'Bearbeiten beim ersten Zeichen');
  CheckEquals('Name3', FData.FieldByName('Name').AsString, 'erst beim Uebernehmen geschrieben');
  SetText(G, 'Preis', FloatToStr(7.25));
  CheckTrue(G.HideEditForm(True));
  CheckFalse(G.EditFormActive);
  CheckTrue(FData.State = dsBrowse, 'gebucht');
  CheckEquals(3, FData.RecNo, 'Satz bleibt');
  CheckEquals('Neu', FData.FieldByName('Name').AsString, 'Name');
  CheckEquals(7.25, FData.FieldByName('Preis').AsFloat, 0.0001, 'Preis');
  // Abbrechen verwirft
  G.ShowEditForm;
  SetText(G, 'Name', 'Weg');
  G.EditFormControl.CancelButton.Click;
  CheckFalse(G.EditFormActive, 'Abbrechen schliesst');
  CheckTrue(FData.State = dsBrowse);
  CheckEquals('Neu', FData.FieldByName('Name').AsString, 'verworfen');
  // Schaltflaeche Uebernehmen
  G.ShowEditForm;
  SetText(G, 'Name', 'Knopf');
  G.EditFormControl.ApplyButton.Click;
  CheckFalse(G.EditFormActive);
  CheckEquals('Knopf', FData.FieldByName('Name').AsString, 'Uebernehmen-Knopf');
  // Buchen von aussen (Navigator): Werte des Formulars gehen mit
  G.ShowEditForm;
  SetText(G, 'Name', 'Aussen');
  FData.Post;
  CheckEquals('Aussen', FData.FieldByName('Name').AsString, 'UpdateData schreibt das Formular');
  CheckTrue(G.EditFormActive, 'gleicher Satz: bleibt offen');
  CheckEquals('Aussen', TPPGGridEdit(Editor(G, 'Name')).Text);
  G.HideEditForm(False);
end;

procedure TDBGridEditFormTests.CheckBoxAndLookupEditors;
var
  G: TPPGDBGrid;
  C: TPPGDBGridColumn;
  Chk: TPPGCheckBox;
  Combo: TPPGComboBox;
  I: Integer;
begin
  G := NewGrid(10);
  FOrte := TClientDataSet.Create(FForm);
  FOrte.FieldDefs.Add('OrtID', ftInteger);
  FOrte.FieldDefs.Add('Ort', ftString, 20);
  FOrte.CreateDataSet;
  for I := 1 to 3 do
    FOrte.AppendRecord([I, 'Ort' + IntToStr(I)]);
  FOrteSource := TDataSource.Create(FForm);
  FOrteSource.DataSet := FOrte;
  C := TPPGDBGridColumn(G.Columns.Add);
  C.FieldName := 'OrtID';
  C.ListSource := FOrteSource;
  C.KeyField := 'OrtID';
  C.ListField := 'Ort';
  // Satz 2: Aktiv = False, OrtID = 3
  FData.RecNo := 2;
  G.ShowEditForm;
  Chk := Editor(G, 'Aktiv') as TPPGCheckBox;
  CheckTrue(Chk.State = cbUnchecked, 'Kaestchen aus');
  Combo := Editor(G, 'OrtID') as TPPGComboBox;
  CheckEquals(3, Combo.Items.Count, 'Liste der Orte');
  CheckEquals('Ort3', Combo.Text, 'Text aus der Liste');
  Chk.Checked := True;
  Combo.ItemIndex := 0;
  G.HideEditForm(True);
  CheckTrue(FData.FieldByName('Aktiv').AsBoolean, 'Kaestchen geschrieben');
  CheckEquals(1, FData.FieldByName('OrtID').AsInteger, 'Schluessel geschrieben');
  // Null: grau
  FData.Edit;
  FData.FieldByName('Aktiv').Clear;
  FData.Post;
  G.ShowEditForm;
  CheckTrue((Editor(G, 'Aktiv') as TPPGCheckBox).State = cbGrayed, 'Null = grau');
  G.HideEditForm(False);
  // Schreibgeschuetzte Spalte: Feld nur zum Lesen
  G.Columns[0].ReadOnly := True;
  G.ShowEditForm;
  CheckTrue(TPPGGridEdit(Editor(G, 'ID')).ReadOnly, 'ID nur lesen');
  CheckFalse(TPPGGridEdit(Editor(G, 'Name')).ReadOnly, 'Name bearbeitbar');
  G.HideEditForm(False);
end;

procedure TDBGridEditFormTests.InsertThroughForm;
var
  G: TPPGDBGrid;
  N: Integer;
begin
  G := NewGrid(10);
  N := FData.RecordCount;
  FData.RecNo := 4;
  Key(G, VK_INSERT);
  CheckTrue(FData.State = dsInsert, 'Einfg: neuer Satz');
  CheckTrue(G.EditFormActive, 'Formular fuer den neuen Satz');
  CheckEquals('', TPPGGridEdit(Editor(G, 'Name')).Text, 'leer');
  SetText(G, 'ID', '100');
  SetText(G, 'Name', 'Hundert');
  G.HideEditForm(True);
  CheckFalse(G.EditFormActive);
  CheckTrue(FData.State = dsBrowse, 'gebucht');
  CheckEquals(N + 1, FData.RecordCount, 'ein Satz mehr');
  CheckEquals('Hundert', FData.FieldByName('Name').AsString);
  // Unveraenderter neuer Satz verschwindet wieder (wie TDBGrid)
  Key(G, VK_INSERT);
  CheckTrue(G.EditFormActive);
  G.HideEditForm(True);
  CheckTrue(FData.State = dsBrowse);
  CheckEquals(N + 1, FData.RecordCount, 'leerer Satz nicht gebucht');
  // Abbrechen eines neuen Satzes
  Key(G, VK_INSERT);
  SetText(G, 'Name', 'Weg');
  Key(G, VK_ESCAPE); // Grid hat den Fokus: Esc verwirft das Formular
  CheckFalse(G.EditFormActive);
  CheckEquals(N + 1, FData.RecordCount, 'verworfen');
  // Leere Datenmenge: Formular nur ueber Einfg
  FData.EmptyDataSet;
  G.ShowEditForm;
  CheckFalse(G.EditFormActive, 'leer: kein Formular');
  Key(G, VK_INSERT);
  CheckTrue(G.EditFormActive, 'leer: Einfg oeffnet');
  SetText(G, 'ID', '1');
  G.HideEditForm(True);
  CheckEquals(1, FData.RecordCount, 'erster Satz');
end;

procedure TDBGridEditFormTests.WriteErrorKeepsFormOpen;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(10);
  G.ShowEditForm;
  SetText(G, 'Name', 'Gut');
  SetText(G, 'ID', 'abc');
  try
    G.HideEditForm(True);
    Fail('ungueltige Zahl');
  except
    on E: EDatabaseError do
      ;
  end;
  CheckTrue(G.EditFormActive, 'bleibt offen');
  CheckEquals(ItemOf(G, 'ID'), G.EditFormControl.Current, 'Fokus auf dem Feld');
  CheckEquals('abc', TPPGGridEdit(Editor(G, 'ID')).Text, 'Eingabe bleibt');
  CheckTrue(FData.State = dsEdit, 'noch in Bearbeitung');
  SetText(G, 'ID', '55');
  CheckTrue(G.HideEditForm(True), 'jetzt gueltig');
  CheckEquals(55, FData.FieldByName('ID').AsInteger);
  CheckEquals('Gut', FData.FieldByName('Name').AsString);
  CheckEquals(1, FClosed);
end;

procedure TDBGridEditFormTests.RequiredFieldAndBeforePostKeepFormOpen;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(10);
  FData.FieldByName('Name').Required := True;
  Key(G, VK_INSERT);
  SetText(G, 'ID', '77');
  try
    G.HideEditForm(True);
    Fail('Pflichtfeld');
  except
    on E: EDatabaseError do
      ;
  end;
  CheckTrue(G.EditFormActive, 'Pflichtfeld: bleibt offen');
  CheckEquals(ItemOf(G, 'Name'), G.EditFormControl.Current, 'Fokus auf dem Pflichtfeld');
  CheckTrue(FData.State = dsInsert);
  SetText(G, 'Name', 'Sieben');
  // BeforePost lehnt ab
  FData.BeforePost := RefusePost;
  try
    G.HideEditForm(True);
    Fail('BeforePost');
  except
    on E: EDatabaseError do
      ;
  end;
  CheckTrue(G.EditFormActive, 'BeforePost: bleibt offen');
  FData.BeforePost := nil;
  CheckTrue(G.HideEditForm(True));
  CheckEquals('Sieben', FData.FieldByName('Name').AsString);
  CheckEquals(11, FData.RecordCount);
end;

procedure TDBGridEditFormTests.TabEnterAndEscapeInsideForm;
var
  G: TPPGDBGrid;
  P: TPPGDBGridEditForm;
begin
  G := NewGrid(10);
  G.Col := ColOf(G, 'ID');
  G.ShowEditForm;
  P := G.EditFormControl;
  CheckEquals(0, P.Current, 'erstes Feld');
  CheckTrue(FormKey(G, VK_TAB), 'Tab');
  CheckEquals(1, P.Current, 'Tab: naechstes');
  CheckTrue(FormKey(G, VK_TAB, [ssShift]));
  CheckEquals(0, P.Current, 'Umschalt+Tab: zurueck');
  CheckTrue(FormKey(G, VK_TAB, [ssShift]));
  CheckEquals(P.ItemCount + 1, P.Current, 'im Kreis: Abbrechen');
  CheckTrue(FormKey(G, VK_TAB));
  CheckEquals(0, P.Current, 'wieder das erste Feld');
  // Tab ueber die Nachricht der Editoren (CM_CHILDKEY)
  P.Perform(CM_CHILDKEY, VK_TAB, LPARAM(P.ItemEditor(1)));
  CheckEquals(2, P.Current, 'CM_CHILDKEY aus dem zweiten Feld');
  // Enter: naechstes Feld, nach dem letzten die Schaltflaeche Uebernehmen
  CheckTrue(FormKey(G, VK_RETURN));
  CheckEquals(3, P.Current, 'Enter: naechstes Feld');
  CheckTrue(FormKey(G, VK_RETURN));
  CheckEquals(P.ItemCount, P.Current, 'Enter im letzten Feld: Uebernehmen');
  CheckTrue(G.EditFormActive, 'noch offen');
  SetText(G, 'Name', 'Enter');
  CheckTrue(FormKey(G, VK_RETURN), 'Enter auf Uebernehmen');
  CheckFalse(G.EditFormActive);
  CheckEquals('Enter', FData.FieldByName('Name').AsString, 'uebernommen');
  // Strg+Enter uebernimmt aus jedem Feld, Esc verwirft
  G.ShowEditForm;
  SetText(G, 'Name', 'Strg');
  CheckTrue(FormKey(G, VK_RETURN, [ssCtrl]));
  CheckFalse(G.EditFormActive);
  CheckEquals('Strg', FData.FieldByName('Name').AsString, 'Strg+Enter');
  G.ShowEditForm;
  SetText(G, 'Name', 'Esc');
  CheckTrue(FormKey(G, VK_ESCAPE));
  CheckFalse(G.EditFormActive);
  CheckEquals('Strg', FData.FieldByName('Name').AsString, 'Esc verwirft');
  // Ohne Schaltflaechen: Enter im letzten Feld uebernimmt
  G.EditForm.ShowButtons := False;
  G.ShowEditForm;
  P := G.EditFormControl;
  CheckFalse(P.ApplyButton.Visible, 'keine Schaltflaechen');
  CheckEquals(124 - 30 - 12, P.Height, 'niedriger ohne Schaltflaechen');
  SetText(G, 'Name', 'Letztes');
  TGridAccess(G).FormFocusTarget(P.ItemCount - 1);
  CheckTrue(FormKey(G, VK_RETURN));
  CheckFalse(G.EditFormActive, 'Enter im letzten Feld');
  CheckEquals('Letztes', FData.FieldByName('Name').AsString);
  // Alt und Strg+Tab gehoeren nicht dem Formular
  G.ShowEditForm;
  CheckFalse(FormKey(G, VK_TAB, [ssCtrl]), 'Strg+Tab');
  CheckFalse(FormKey(G, VK_RETURN, [ssAlt]), 'Alt+Enter');
  CheckFalse(FormKey(G, Ord('A')), 'andere Tasten');
  G.HideEditForm(False);
end;

procedure TDBGridEditFormTests.RecordChangeFromOutside;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(10);
  FData.RecNo := 2;
  G.ShowEditForm;
  SetText(G, 'Name', 'Gewechselt');
  // Navigator/Code: Datenmenge bucht (UpdateData schreibt das Formular) und
  // wechselt den Satz; das Formular schliesst
  FData.Next;
  CheckFalse(G.EditFormActive, 'anderer Satz: geschlossen');
  CheckEquals(1, FClosed);
  CheckEquals(3, FData.RecNo);
  CheckEquals((400 - 24) div 24, TGridAccess(G).DataLink.BufferCount, 'Puffer wieder voll');
  FData.RecNo := 2;
  CheckEquals('Gewechselt', FData.FieldByName('Name').AsString, 'Eingabe gebucht');
  // Cancel von aussen: Formular bleibt und zeigt wieder den Satz
  G.ShowEditForm;
  SetText(G, 'Name', 'Verworfen');
  FData.Cancel;
  CheckTrue(G.EditFormActive, 'gleicher Satz: offen');
  CheckEquals('Gewechselt', TPPGGridEdit(Editor(G, 'Name')).Text, 'neu gelesen');
  // Feldwert von aussen: unveraenderte Felder folgen
  FData.Edit;
  FData.FieldByName('Preis').AsFloat := 99;
  CheckEquals(FData.FieldByName('Preis').Text, TPPGGridEdit(Editor(G, 'Preis')).Text,
    'Preis folgt dem Satz');
  FData.Cancel;
  // Klick auf eine andere Zeile: bucht und schliesst
  SetText(G, 'Name', 'Klick');
  ClickCell(G, ColOf(G, 'Name'), TGridAccess(G).FixedRows + 4);
  CheckFalse(G.EditFormActive, 'Klick auf andere Zeile');
  CheckEquals(5, FData.RecNo);
  FData.RecNo := 2;
  CheckEquals('Klick', FData.FieldByName('Name').AsString, 'gebucht');
  // Datenmenge geschlossen
  G.ShowEditForm;
  FData.Close;
  CheckFalse(G.EditFormActive, 'geschlossen mit der Datenmenge');
  CheckEquals(0, FErrors.Count);
end;

procedure TDBGridEditFormTests.CellsLockedAndCardsUseCells;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(10);
  // Satz 2: Aktiv = False; Klick auf das Kaestchen schaltet nicht
  ClickCell(G, ColOf(G, 'Aktiv'), TGridAccess(G).FixedRows + 1);
  CheckEquals(2, FData.RecNo);
  CheckFalse(FData.FieldByName('Aktiv').AsBoolean, 'Zelle gesperrt');
  CheckTrue(FData.State = dsBrowse);
  // Entf leert keine Zellen
  G.Col := ColOf(G, 'Name');
  Key(G, VK_DELETE);
  CheckEquals('Name2', FData.FieldByName('Name').AsString, 'Entf');
  // Kartenansicht: Formular schliesst und bleibt aus, Zellen bearbeitbar
  G.ShowEditForm;
  SetText(G, 'Name', 'Karte');
  G.ViewStyle := dgvCards;
  CheckFalse(G.EditFormActive, 'Karten: geschlossen');
  CheckEquals('Karte', FData.FieldByName('Name').AsString, 'vorher uebernommen');
  G.ShowEditForm;
  CheckFalse(G.EditFormActive, 'Karten: kein Formular');
  CheckEquals(-1, TGridAccess(G).RowGapRow, 'keine Luecke');
  G.ViewStyle := dgvTable;
  G.ShowEditForm;
  CheckTrue(G.EditFormActive, 'Tabelle wieder');
  // EditMode zurueck auf Zellen schliesst (uebernimmt)
  SetText(G, 'Name', 'Modus');
  G.EditMode := dgeCells;
  CheckFalse(G.EditFormActive);
  CheckEquals('Modus', FData.FieldByName('Name').AsString);
end;

procedure TDBGridEditFormTests.PaintLightDarkAndGdi;
var
  G: TPPGDBGrid;
  Bmp: TBitmap;
  P: TPoint;
begin
  G := NewGrid(20);
  FData.RecNo := 3;
  G.ShowEditForm;
  // Punkt im Rand des Formulars (rechts oben, neben den Editoren)
  P := Point(G.EditFormControl.Left + 636, G.EditFormControl.Top + 5);
  Bmp := RenderToBitmap(G);
  try
    CheckTrue(Lum(Bmp.Canvas.Pixels[P.X, P.Y]) > 3 * 128, 'hell: Formular hell');
  finally
    Bmp.Free;
  end;
  CheckEquals(3, FData.RecNo, 'Zeichnen bewegt die Datenmenge nicht');
  TPPGTheme.Mode := tmDark;
  Bmp := RenderToBitmap(G);
  try
    CheckTrue(Lum(Bmp.Canvas.Pixels[P.X, P.Y]) < 3 * 128, 'dunkel: Formular dunkel');
  finally
    Bmp.Free;
  end;
  TPPGTheme.Mode := tmLight;
  TPPGRendererRegistry.ForceGdiFallback := True;
  Bmp := RenderToBitmap(G);
  try
    CheckTrue(Lum(Bmp.Canvas.Pixels[P.X, P.Y]) > 3 * 128, 'GDI: hell');
  finally
    Bmp.Free;
  end;
  // Formular allein, schmal und mit Scrollen
  G.Height := 120;
  Bmp := RenderToBitmap(G.EditFormControl);
  Bmp.Free;
  CheckTrue(G.EditFormActive);
  CheckEquals(0, FErrors.Count, 'keine Fehler beim Zeichnen');
end;

procedure TDBGridEditFormTests.DpiScalesForm;
{$IF CompilerVersion >= 33.0}
var
  G: TPPGDBGrid;
  Host: TPanel;
{$IFEND}
begin
{$IF CompilerVersion >= 33.0}
  FForm.Scaled := False;
  Host := TPanel.Create(FForm);
  Host.Parent := FForm;
  ForcePPI96(Host);
  Host.SetBounds(0, 0, 700, 450);
  G := NewGrid(10, Host);
  Host.ScaleForPPI(192);
  CheckEquals(192, G.CurrentPPI, 'PPI');
  G.ShowEditForm;
  CheckEquals(2 * 124, G.EditFormControl.Height, 'Hoehe doppelt');
  CheckEquals(2 * 28, G.EditFormControl.ItemEditor(0).Height, 'Editor doppelt');
  CheckEquals(2 * 120, G.EditFormControl.ItemLabelRect(0).Right - G.EditFormControl.ItemLabelRect(0).Left,
    'Beschriftung doppelt');
  CheckEquals(120, G.EditForm.LabelWidth, 'Property bleibt logisch');
{$ELSE}
  Skip('Erst ab Delphi 10.3 (ScaleForPPI)');
{$IFEND}
end;

procedure TDBGridEditFormTests.TallFormScrollsToField;
var
  G: TPPGDBGrid;
  I: Integer;
  P: TPPGDBGridEditForm;
  Ed: TPPGCustomControl;
begin
  // 30 Felder in einer Spalte: hoeher als das Grid, das Formular scrollt
  FData.Close;
  FData.FieldDefs.Clear;
  for I := 1 to 30 do
    FData.FieldDefs.Add('F' + IntToStr(I), ftInteger);
  FData.CreateDataSet;
  for I := 1 to 5 do
    FData.AppendRecord([I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I,
      I, I, I, I, I, I, I]);
  FData.First;
  G := TPPGDBGrid.Create(FForm);
  G.Parent := FForm;
  ForcePPI96(G);
  G.BorderStyle := bsNone;
  G.ScrollBarMode := sbmNever;
  G.SetBounds(0, 0, 640, 400);
  G.HandleNeeded;
  G.EditMode := dgeForm;
  G.EditForm.ColumnCount := 1;
  G.DataSource := FSource;
  G.ShowEditForm;
  P := G.EditFormControl;
  CheckEquals(30, P.ItemCount);
  CheckEquals(400 - 24 - 24, P.Height, 'so hoch wie Platz ist');
  CheckEquals(1, TGridAccess(G).DataLink.BufferCount, 'nur die aktive Zeile');
  TGridAccess(G).FormFocusTarget(29);
  Ed := P.ItemEditor(29);
  CheckTrue((Ed.Top >= 0) and (Ed.Top + Ed.Height <= P.Height), 'letztes Feld im Bild ' +
    RectText(Ed.BoundsRect));
  CheckTrue(P.ScrollPos.Y > 0, 'gescrollt');
  // Beschriftung wandert mit
  CheckEquals(Ed.Top, P.ItemLabelRect(29).Top, 'Beschriftung neben dem Editor');
  TGridAccess(G).FormFocusTarget(0);
  CheckEquals(0, P.ScrollPos.Y, 'erstes Feld: oben');
  G.HideEditForm(False);
end;

procedure TDBGridEditFormTests.DoubleClickOpensCellEditor;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(10);
  G.EditMode := dgeCells;
  // Echter Fokus: nur auf dem unsichtbaren Testdesktop (/hidden)
  if not PPGOnHiddenDesktop then
  begin
    Skip('Fokus braucht ein angezeigtes Formular, nur mit /hidden');
    Exit;
  end;
  FForm.Show;
  try
    G.SetFocus;
    ClickCell(G, ColOf(G, 'Name'), TGridAccess(G).FixedRows + 3, True);
    CheckEquals(4, FData.FieldByName('ID').AsInteger, 'Satz 4');
    CheckTrue(G.EditorMode, 'Doppelklick oeffnet den Editor (Tabelle)');
    CheckTrue(G.InplaceEditor.Focused, 'Fokus im Editor');
    G.HideEditor(False);
  finally
    FForm.Hide;
  end;
end;

procedure TDBGridEditFormTests.DoubleClickOpensEditFormWithFocus;
var
  G: TPPGDBGrid;
  P: TPPGDBGridEditForm;
  W: TWinControl;
begin
  G := NewGrid(10);
  if not PPGOnHiddenDesktop then
  begin
    Skip('Fokus braucht ein angezeigtes Formular, nur mit /hidden');
    Exit;
  end;
  FForm.Show;
  try
    G.SetFocus;
    ClickCell(G, ColOf(G, 'Name'), TGridAccess(G).FixedRows + 2, True);
    CheckEquals(3, FData.FieldByName('ID').AsInteger, 'Satz 3');
    CheckTrue(G.EditFormActive, 'Doppelklick oeffnet das Formular');
    P := G.EditFormControl;
    CheckTrue(P.ItemEditor(ItemOf(G, 'Name')).Focused, 'Fokus im Feld der angeklickten Spalte');
    // Tab ueber den echten Weg (CN_KEYDOWN des fokussierten Fensters)
    W := FindControl(GetFocus);
    CheckNotNull(W, 'fokussiertes Control');
    W.Perform(CN_KEYDOWN, VK_TAB, 0);
    CheckTrue(P.ItemEditor(ItemOf(G, 'Aktiv')).Focused, 'Tab: naechstes Feld');
    // Esc verwirft, der Fokus geht ins Grid zurueck
    W := FindControl(GetFocus);
    W.Perform(CN_KEYDOWN, VK_ESCAPE, 0);
    CheckFalse(G.EditFormActive, 'Esc');
    CheckTrue(G.Focused, 'Fokus wieder im Grid');
    // Enter oeffnet erneut, Fokus im Formular
    G.Perform(WM_KEYDOWN, VK_RETURN, 0);
    CheckTrue(G.EditFormActive, 'Enter');
    CheckFalse(G.Focused, 'Fokus im Formular');
    G.HideEditForm(False);
  finally
    FForm.Hide;
  end;
end;

initialization
  RegisterTest('DBGridEditForm', TDBGridEditFormTests.Suite);
end.
