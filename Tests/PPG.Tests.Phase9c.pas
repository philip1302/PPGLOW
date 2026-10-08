unit PPG.Tests.Phase9c;

{ Tests fuer Phase 9c: DB-Controls (PPG.DB.Controls, PPG.DB.Lookup,
  PPG.DB.Grid). Datenmenge ist ein TClientDataSet im Speicher (MidasLib ist
  statisch gelinkt, keine midas.dll noetig - von XE2 bis 13 vorhanden). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Variants, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.Graphics, Vcl.DBGrids,
  Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Types, PPG.Controls.Field, PPG.Edit, PPG.Grid,
  PPG.DB.Controls, PPG.DB.Lookup, PPG.DB.Grid, PPG.Tests.Controls;

type
  TDBTestCase = class(TControlTestCase)
  protected
    FData: TClientDataSet;
    FSource: TDataSource;
    FGetTextCalls: Integer;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure CountGetText(Sender: TField; var Text: string; DisplayText: Boolean);
    /// Datenmenge mit N Datensaetzen (ID, Name, Aktiv, Geboren, Notiz, Preis, OrtID).
    procedure FillData(N: Integer);
  end;

  TDBEditTests = class(TDBTestCase)
  published
    procedure ShowsFieldAndFollowsRecord;
    procedure UserChangeEditsAndPosts;
    procedure EscapeResetsValue;
    procedure InvalidValueMarksFieldAndKeepsFocus;
    procedure ReadOnlyDataSetLocksEdit;
    procedure DataSourceFreedIsSafe;
  end;

  TDBOtherControlTests = class(TDBTestCase)
  published
    procedure MemoShowsAndWritesMemoField;
    procedure CheckBoxBooleanAndNull;
    procedure CheckBoxValueStrings;
    procedure ComboBoxSelectWritesText;
    procedure LookupComboShowsListAndWritesKey;
    procedure DatePickerWritesDate;
  end;

  TDBGridTests = class(TDBTestCase)
  private
    function NewGrid: TPPGDBGrid;
  published
    procedure AutoColumnsFromFields;
    procedure BufferHoldsOnlyVisibleRows;
    procedure KeyboardMovesDataSet;
    procedure ScrollBarFollowsRecNo;
    procedure EditCellWritesField;
    procedure InsertAndEscape;
    procedure PersistentColumns;
    procedure PaintDoesNotTouchDataSet;
    procedure EmptyDataSetKeepsFillerRow;
    procedure StreamingKeepsColumnsAndOptions;
    procedure EditorDiscardedOnRecordChange;
    procedure SnapshotRefusesWhileEditing;
    procedure TitlesToggleOnEmptyDataSet;
  end;

implementation

uses
  PPG.Exceptions;

type
  TEditAccess = class(TPPGDBEdit);
  TComboAccess = class(TPPGDBComboBox);
  TLookupAccess = class(TPPGDBLookupComboBox);
  TDateAccess = class(TPPGDBDatePicker);
  TGridAccess = class(TPPGDBGrid);

{ TDBTestCase }

procedure TDBTestCase.SetUp;
begin
  inherited SetUp;
  FData := TClientDataSet.Create(FForm);
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
  FGetTextCalls := 0;
end;

procedure TDBTestCase.TearDown;
begin
  FSource := nil;
  FData := nil;
  inherited TearDown;
end;

procedure TDBTestCase.CountGetText(Sender: TField; var Text: string; DisplayText: Boolean);
begin
  Inc(FGetTextCalls);
  Text := Sender.AsString;
end;

procedure TDBTestCase.FillData(N: Integer);
var
  I: Integer;
begin
  FData.Close;
  FData.FieldDefs.Clear;
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Name', ftString, 20);
  FData.FieldDefs.Add('Aktiv', ftBoolean);
  FData.FieldDefs.Add('Geboren', ftDate);
  FData.FieldDefs.Add('Notiz', ftMemo);
  FData.FieldDefs.Add('Preis', ftFloat);
  FData.FieldDefs.Add('OrtID', ftInteger);
  FData.CreateDataSet;
  for I := 1 to N do
    FData.AppendRecord([I, 'Name' + IntToStr(I), Odd(I), EncodeDate(2000, 1, 1) + I,
      'Notiz ' + IntToStr(I), I * 1.5, (I mod 3) + 1]);
  FData.First;
end;

{ TDBEditTests }

function NewEdit(Form: TForm; Source: TDataSource; const Field: string): TPPGDBEdit;
begin
  Result := TPPGDBEdit.Create(Form);
  Result.Parent := Form;
  Result.SetBounds(10, 10, 200, 32);
  Result.DataSource := Source;
  Result.DataField := Field;
end;

procedure TDBEditTests.ShowsFieldAndFollowsRecord;
var
  E: TPPGDBEdit;
begin
  FillData(3);
  E := NewEdit(FForm, FSource, 'Name');
  CheckEquals('Name1', E.Text);
  FData.Next;
  CheckEquals('Name2', E.Text, 'folgt dem Datensatz');
  CheckTrue(E.Field = FData.FieldByName('Name'));
  CheckFalse(E.Modified);
end;

procedure TDBEditTests.UserChangeEditsAndPosts;
var
  E: TPPGDBEdit;
begin
  FillData(3);
  E := NewEdit(FForm, FSource, 'Name');
  CheckTrue(FData.State = dsBrowse);
  E.Text := 'Neu';  // wie eine Eingabe des Anwenders
  CheckTrue(FData.State = dsEdit, 'Bearbeiten-Modus');
  CheckEquals('Neu', E.Text, 'Wert nicht von DataChange ueberschrieben');
  FData.Post;
  CheckEquals('Neu', FData.FieldByName('Name').AsString);
end;

procedure TDBEditTests.EscapeResetsValue;
var
  E: TPPGDBEdit;
  Key: Word;
begin
  FillData(3);
  E := NewEdit(FForm, FSource, 'Name');
  E.Text := 'Falsch';
  Key := VK_ESCAPE;
  TEditAccess(E).FieldKeyDown(Key, []);
  CheckEquals(0, Key, 'Esc verbraucht');
  CheckEquals('Name1', E.Text, 'Wert aus dem Feld');
  CheckTrue(TEditAccess(E).WantSpecialKey(VK_ESCAPE), 'Esc gehoert dem Feld waehrend der Bearbeitung');
end;

procedure TDBEditTests.InvalidValueMarksFieldAndKeepsFocus;
var
  E: TPPGDBEdit;
  Aborted: Boolean;
begin
  FillData(3);
  E := NewEdit(FForm, FSource, 'ID');
  E.Text := 'abc';
  Aborted := False;
  try
    E.Perform(CM_EXIT, 0, 0);
  except
    on EAbort do
      Aborted := True;
  end;
  CheckTrue(Aborted, 'Verlassen wird still abgebrochen');
  CheckTrue(E.ValidationState = pvsError);
  CheckTrue(E.ValidationHint <> '', 'Meldung als Hinweis');
  // Gueltiger Wert: Zustand verschwindet
  E.Text := '42';
  E.Perform(CM_EXIT, 0, 0);
  CheckTrue(E.ValidationState = pvsNone);
  CheckEquals(42, FData.FieldByName('ID').AsInteger);
end;

procedure TDBEditTests.ReadOnlyDataSetLocksEdit;
var
  E: TPPGDBEdit;
begin
  FillData(3);
  E := NewEdit(FForm, FSource, 'Name');
  CheckFalse(TPPGEdit(E).ReadOnly, 'aenderbar');
  E.ReadOnly := True;
  CheckTrue(TPPGEdit(E).ReadOnly, 'ReadOnly des Controls');
  E.ReadOnly := False;
  CheckFalse(TPPGEdit(E).ReadOnly);
  // Feld nur lesbar: beim naechsten Datensatzwechsel gesperrt
  FData.FieldByName('Name').ReadOnly := True;
  FData.Next;
  CheckTrue(TPPGEdit(E).ReadOnly, 'Feld nur lesbar');
end;

procedure TDBEditTests.DataSourceFreedIsSafe;
var
  E: TPPGDBEdit;
begin
  FillData(3);
  E := NewEdit(FForm, FSource, 'Name');
  FreeAndNil(FSource);
  CheckNull(E.DataSource, 'FreeNotification');
  CheckEquals('', E.Text);
end;

{ TDBOtherControlTests }

procedure TDBOtherControlTests.MemoShowsAndWritesMemoField;
var
  M: TPPGDBMemo;
begin
  FillData(2);
  M := TPPGDBMemo.Create(FForm);
  M.Parent := FForm;
  M.DataSource := FSource;
  M.DataField := 'Notiz';
  CheckEquals('Notiz 1', Trim(M.Text));
  M.Text := 'Zeile A' + sLineBreak + 'Zeile B';
  FData.Post;
  CheckEquals('Zeile A' + sLineBreak + 'Zeile B', FData.FieldByName('Notiz').AsString);
  // AutoDisplay = False: BLOB erst auf Wunsch laden
  M.AutoDisplay := False;
  FData.Next;
  CheckEquals('(Notiz)', M.Text);
  M.LoadMemo;
  CheckEquals('Notiz 2', Trim(M.Text));
end;

procedure TDBOtherControlTests.CheckBoxBooleanAndNull;
var
  C: TPPGDBCheckBox;
begin
  FillData(2);
  C := TPPGDBCheckBox.Create(FForm);
  C.Parent := FForm;
  C.DataSource := FSource;
  C.DataField := 'Aktiv';
  CheckTrue(C.State = cbChecked, 'Datensatz 1 ist aktiv');
  C.Click; // Anwender schaltet um
  CheckTrue(FData.State = dsEdit);
  CheckTrue(C.State = cbUnchecked);
  FData.Post;
  CheckFalse(FData.FieldByName('Aktiv').AsBoolean);
  FData.Edit;
  FData.FieldByName('Aktiv').Clear;
  FData.Post;
  CheckTrue(C.State = cbGrayed, 'Null = gemischt');
end;

procedure TDBOtherControlTests.CheckBoxValueStrings;
var
  C: TPPGDBCheckBox;
begin
  FillData(1);
  FData.Edit;
  FData.FieldByName('Name').AsString := 'Ja';
  FData.Post;
  C := TPPGDBCheckBox.Create(FForm);
  C.Parent := FForm;
  C.ValueChecked := 'J;Ja';
  C.ValueUnchecked := 'N;Nein';
  C.DataSource := FSource;
  C.DataField := 'Name';
  CheckTrue(C.State = cbChecked, 'zweiter Wert passt');
  C.Click;
  FData.Post;
  CheckEquals('N', FData.FieldByName('Name').AsString, 'erster Wert wird geschrieben');
end;

procedure TDBOtherControlTests.ComboBoxSelectWritesText;
var
  C: TPPGDBComboBox;
begin
  FillData(2);
  C := TPPGDBComboBox.Create(FForm);
  C.Parent := FForm;
  C.Style := csDropDownList;
  C.Items.CommaText := 'Name1,Name2,Anders';
  C.DataSource := FSource;
  C.DataField := 'Name';
  CheckEquals(0, C.ItemIndex);
  TComboAccess(C).SelectIndex(2); // Auswahl durch den Anwender
  CheckTrue(FData.State = dsEdit);
  FData.Post;
  CheckEquals('Anders', FData.FieldByName('Name').AsString);
  FData.Next;
  CheckEquals(1, C.ItemIndex, 'folgt dem Datensatz');
end;

procedure TDBOtherControlTests.LookupComboShowsListAndWritesKey;
var
  Orte: TClientDataSet;
  OrtSrc: TDataSource;
  L: TPPGDBLookupComboBox;
begin
  FillData(3);
  Orte := TClientDataSet.Create(FForm);
  Orte.FieldDefs.Add('ID', ftInteger);
  Orte.FieldDefs.Add('Ort', ftString, 20);
  Orte.FieldDefs.Add('PLZ', ftString, 5);
  Orte.CreateDataSet;
  Orte.AppendRecord([1, 'Berlin', '10115']);
  Orte.AppendRecord([2, 'Hamburg', '20095']);
  Orte.AppendRecord([3, 'Koeln', '50667']);
  Orte.RecNo := 2;
  OrtSrc := TDataSource.Create(FForm);
  OrtSrc.DataSet := Orte;
  L := TPPGDBLookupComboBox.Create(FForm);
  L.Parent := FForm;
  L.ListSource := OrtSrc;
  L.KeyField := 'ID';
  L.ListField := 'Ort;PLZ';
  L.DataSource := FSource;
  L.DataField := 'OrtID';
  CheckEquals(3, L.KeyCount);
  CheckEquals('Berlin', L.ItemsEx[0].Text);
  CheckEquals('10115', L.ItemsEx[0].Detail, 'weitere Felder als Detail');
  CheckEquals(2, Orte.RecNo, 'Lesezeichen der Liste wiederhergestellt');
  // Datensatz 1: OrtID = (1 mod 3) + 1 = 2 -> Hamburg
  CheckEquals(1, L.ItemIndex);
  CheckEquals(2, Integer(L.KeyValue));
  TLookupAccess(L).SelectIndex(2);
  FData.Post;
  CheckEquals(3, FData.FieldByName('OrtID').AsInteger, 'Schluessel geschrieben');
end;

procedure TDBOtherControlTests.DatePickerWritesDate;
var
  D: TPPGDBDatePicker;
begin
  FillData(2);
  D := TPPGDBDatePicker.Create(FForm);
  D.Parent := FForm;
  D.DataSource := FSource;
  D.DataField := 'Geboren';
  CheckEquals(EncodeDate(2000, 1, 2), D.Date);
  TDateAccess(D).UserSetDate(EncodeDate(2024, 2, 29));
  CheckTrue(FData.State = dsEdit);
  FData.Post;
  CheckEquals(EncodeDate(2024, 2, 29), FData.FieldByName('Geboren').AsDateTime);
end;

{ TDBGridTests }

function TDBGridTests.NewGrid: TPPGDBGrid;
begin
  Result := TPPGDBGrid.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 380, 24 * 6 + 2); // Titel + 5 Datenzeilen
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.HandleNeeded;
  Result.DataSource := FSource;
end;

procedure TDBGridTests.AutoColumnsFromFields;
var
  G: TPPGDBGrid;
begin
  FillData(10);
  G := NewGrid;
  CheckEquals(7, G.FieldCount, 'alle sichtbaren Felder');
  CheckTrue(G.Fields[1] = FData.FieldByName('Name'));
  CheckEquals('Name', TGridAccess(G).GetCellText(2, 0), 'Titel = DisplayLabel');
  CheckEquals('Name1', TGridAccess(G).GetCellText(2, 1));
  CheckTrue(TGridAccess(G).ColumnOf(3).EditorKind = gekCheck, 'Boolean als Kaestchen');
  CheckEquals('1', TGridAccess(G).GetCellText(3, 1), 'Datensatz 1 aktiv');
  CheckTrue(TGridAccess(G).GetCellText(0, 1) <> '', 'Indikator in der aktiven Zeile');
  CheckEquals('', TGridAccess(G).GetCellText(0, 2));
end;

procedure TDBGridTests.BufferHoldsOnlyVisibleRows;
var
  G: TPPGDBGrid;
begin
  FillData(1000);
  G := NewGrid;
  CheckTrue(TGridAccess(G).DataLink.BufferCount <= 6, 'Puffer = sichtbare Zeilen');
  CheckTrue(TGridAccess(G).RowCount <= 7, 'nie die ganze Tabelle');
  G.Height := G.Height + 24 * 3;
  CheckTrue(TGridAccess(G).DataLink.BufferCount >= 7, 'Puffer waechst mit');
end;

procedure TDBGridTests.KeyboardMovesDataSet;
var
  G: TPPGDBGrid;
  Key: Word;
begin
  FillData(50);
  G := NewGrid;
  Key := VK_DOWN;
  TGridAccess(G).KeyDown(Key, []);
  CheckEquals(2, FData.RecNo);
  CheckEquals(TGridAccess(G).VisualRow(TGridAccess(G).FixedRows + 1), G.FocusRow, 'Fokus folgt');
  Key := VK_END;
  TGridAccess(G).KeyDown(Key, [ssCtrl]);
  CheckEquals(50, FData.RecNo);
  Key := VK_HOME;
  TGridAccess(G).KeyDown(Key, [ssCtrl]);
  CheckEquals(1, FData.RecNo);
  Key := VK_NEXT;
  TGridAccess(G).KeyDown(Key, []);
  CheckTrue(FData.RecNo > 1, 'Bild runter');
end;

procedure TDBGridTests.ScrollBarFollowsRecNo;
var
  G: TPPGDBGrid;
begin
  FillData(200);
  G := NewGrid;
  CheckEquals(0, G.ScrollY, 'oben');
  CheckTrue(G.ContentHeight > G.Height * 10, 'Leiste fuer 200 Datensaetze');
  FData.Last;
  CheckTrue(G.ScrollY > 0, 'Leiste unten');
  // Ziehen der Leiste bewegt die Datenmenge
  G.ScrollTo(0, 0);
  CheckTrue(FData.RecNo <= TGridAccess(G).DataLink.BufferCount, 'zurueck am Anfang');
end;

procedure TDBGridTests.EditCellWritesField;
var
  G: TPPGDBGrid;
begin
  FillData(5);
  G := NewGrid;
  CheckTrue(TGridAccess(G).CanEditCell(2, TGridAccess(G).VisualRow(1)));
  TGridAccess(G).SetCellByUser(2, 1, 'Geaendert');
  CheckTrue(FData.State = dsEdit);
  CheckEquals('Geaendert', FData.FieldByName('Name').AsString);
  FData.Post;
  CheckEquals('Geaendert', TGridAccess(G).GetCellText(2, 1), 'Zwischenspeicher aktualisiert');
  // Kaestchen-Spalte (Boolean)
  TGridAccess(G).SetCellByUser(3, 1, '0');
  FData.Post;
  CheckFalse(FData.FieldByName('Aktiv').AsBoolean);
  // Andere Pufferzeile als die aktive: nichts
  TGridAccess(G).SetCellByUser(2, 2, 'X');
  CheckTrue(FData.State = dsBrowse);
end;

procedure TDBGridTests.InsertAndEscape;
var
  G: TPPGDBGrid;
  Key: Word;
begin
  FillData(5);
  G := NewGrid;
  Key := VK_INSERT;
  TGridAccess(G).KeyDown(Key, []);
  CheckTrue(FData.State = dsInsert);
  CheckEquals('*', TGridAccess(G).GetCellText(0, 1 + TGridAccess(G).DataLink.ActiveRecord));
  Key := VK_ESCAPE;
  TGridAccess(G).KeyDown(Key, []);
  CheckTrue(FData.State = dsBrowse);
  CheckEquals(5, FData.RecordCount);
end;

procedure TDBGridTests.PersistentColumns;
var
  G: TPPGDBGrid;
  C: TPPGDBGridColumn;
begin
  FillData(5);
  G := NewGrid;
  C := TPPGDBGridColumn(G.Columns.Add);
  C.FieldName := 'Preis';
  C.Title := 'Betrag';
  C := TPPGDBGridColumn(G.Columns.Add);
  C.FieldName := 'Name';
  CheckEquals(2, G.FieldCount);
  CheckEquals('Betrag', TGridAccess(G).GetCellText(1, 0));
  CheckEquals('Name', TGridAccess(G).GetCellText(2, 0));
  CheckEquals('Name1', TGridAccess(G).GetCellText(2, 1));
  CheckTrue(G.SelectedField <> nil);
end;

procedure TDBGridTests.PaintDoesNotTouchDataSet;
var
  G: TPPGDBGrid;
  Bmp: TBitmap;
begin
  FillData(20);
  FData.FieldByName('Name').OnGetText := CountGetText;
  G := NewGrid;
  FGetTextCalls := 0;
  Bmp := RenderToBitmap(G);
  try
    CheckEquals(0, FGetTextCalls, 'Paint liest nur den Zwischenspeicher');
  finally
    Bmp.Free;
  end;
  FData.Next;
  CheckTrue(FGetTextCalls > 0, 'Zwischenspeicher wird im Ereignis gefuellt');
end;

procedure TDBGridTests.EmptyDataSetKeepsFillerRow;
var
  G: TPPGDBGrid;
begin
  FillData(0);
  G := NewGrid;
  CheckEquals(1, TGridAccess(G).FixedRows);
  CheckEquals(2, TGridAccess(G).RowCount, 'Titel + leere Zeile');
  CheckFalse(TGridAccess(G).CanEditCell(2, 1), 'Fuellzeile nicht bearbeitbar');
end;

procedure TDBGridTests.EditorDiscardedOnRecordChange;
var
  G: TPPGDBGrid;
begin
  // Audit 08.10.2026: Ein offener Zell-Editor blieb beim Datensatzwechsel
  // stehen; die Eingabe landete im neuen Datensatz oder ging verloren.
  FillData(50);
  FForm.Show;
  try
    G := NewGrid;
    G.Col := 2;
    G.ShowEditor;
    CheckTrue(G.EditorMode, 'Editor offen');
    FData.Last; // ueber den Puffer hinaus: ActiveRecord bleibt gleich
    CheckFalse(G.EditorMode, 'Editor des alten Datensatzes verworfen');
    CheckEquals('Name1', VarToStr(FData.Lookup('ID', 1, 'Name')), 'nichts geschrieben');
    CheckEquals('Name50', FData.FieldByName('Name').AsString);
  finally
    FForm.Hide;
  end;
end;

procedure TDBGridTests.SnapshotRefusesWhileEditing;
var
  G: TPPGDBGrid;
  Raised: Boolean;
begin
  // Audit 08.10.2026: Export/Druck lief mit First durch die Datenmenge und
  // buchte dabei eine offene Bearbeitung still.
  FillData(5);
  G := NewGrid;
  FData.Edit;
  FData.FieldByName('Name').AsString := 'offen';
  Raised := False;
  try
    TGridAccess(G).TableRowCount;
  except
    on E: EPPGError do
      Raised := True;
  end;
  CheckTrue(Raised, 'PPG-Exception statt stillem Post');
  CheckTrue(FData.State = dsEdit, 'Bearbeitung bleibt offen');
  FData.Cancel;
  CheckEquals('Name1', FData.FieldByName('Name').AsString, 'nicht gebucht');
  CheckEquals(5, TGridAccess(G).TableRowCount, 'danach normal');
end;

procedure TDBGridTests.TitlesToggleOnEmptyDataSet;
var
  G: TPPGDBGrid;
begin
  // Audit 08.10.2026: dgTitles wieder einschalten bei leerer bzw. inaktiver
  // Datenmenge warf (FixedRows := 1 bei RowCount = 1).
  FillData(0);
  G := NewGrid;
  G.Options := G.Options - [dgTitles];
  CheckEquals(0, TGridAccess(G).FixedRows);
  G.Options := G.Options + [dgTitles];
  CheckEquals(1, TGridAccess(G).FixedRows);
  CheckTrue(dgTitles in G.Options);
  FData.Close;
  G.Options := G.Options - [dgTitles];
  G.Options := G.Options + [dgTitles];
  CheckEquals(1, TGridAccess(G).FixedRows, 'auch inaktiv');
  CheckTrue(TGridAccess(G).RowCount > TGridAccess(G).FixedRows);
end;

procedure TDBGridTests.StreamingKeepsColumnsAndOptions;
var
  G, G2: TPPGDBGrid;
  E, E2: TPPGDBEdit;
  M: TMemoryStream;
  C: TPPGDBGridColumn;
begin
  G := TPPGDBGrid.Create(nil);
  E := TPPGDBEdit.Create(nil);
  M := TMemoryStream.Create;
  try
    C := TPPGDBGridColumn(G.Columns.Add);
    C.FieldName := 'Preis';
    C.Title := 'Betrag';
    C.Width := 90;
    G.Options := G.Options - [dgIndicator, dgConfirmDelete];
    G.ReadOnly := True;
    M.WriteComponent(G);
    M.Position := 0;
    G2 := TPPGDBGrid(M.ReadComponent(nil));
    try
      CheckEquals(1, G2.Columns.Count);
      CheckEquals('Preis', TPPGDBGridColumn(G2.Columns[0]).FieldName);
      CheckEquals('Betrag', G2.Columns[0].Title);
      CheckEquals(90, G2.Columns[0].Width);
      CheckFalse(dgIndicator in G2.Options);
      CheckFalse(dgConfirmDelete in G2.Options);
      CheckTrue(dgEditing in G2.Options);
      CheckTrue(G2.ReadOnly);
    finally
      G2.Free;
    end;
    E.DataField := 'Name';
    E.ReadOnly := True;
    M.Clear;
    M.WriteComponent(E);
    M.Position := 0;
    E2 := TPPGDBEdit(M.ReadComponent(nil));
    try
      CheckEquals('Name', E2.DataField);
      CheckTrue(E2.ReadOnly);
    finally
      E2.Free;
    end;
  finally
    M.Free;
    E.Free;
    G.Free;
  end;
end;

initialization
  RegisterClasses([TPPGDBGrid, TPPGDBEdit, TPPGDBMemo, TPPGDBCheckBox, TPPGDBComboBox,
    TPPGDBLookupComboBox, TPPGDBDatePicker]);
  RegisterTest('Phase9c', TDBEditTests.Suite);
  RegisterTest('Phase9c', TDBOtherControlTests.Suite);
  RegisterTest('Phase9c', TDBGridTests.Suite);

end.
