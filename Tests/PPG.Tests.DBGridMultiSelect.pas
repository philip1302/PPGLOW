unit PPG.Tests.DBGridMultiSelect;

{ Tests fuer die Mehrfachauswahl des DB-Grids (dgMultiSelect, SelectedRows,
  OnSelectionChanged). Datenmenge ist ein TClientDataSet im Speicher
  (MidasLib statisch gelinkt). Maus und Tastatur werden ueber Nachrichten
  bzw. KeyDown simuliert. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids, Vcl.DBGrids,
  Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Grid, PPG.DB.Grid, PPG.Theme, PPG.Exceptions, PPG.Tests.Controls, PPG.Tests.Phase9c;

type
  /// Grid mit abgefangener Rueckfrage beim Loeschen der Auswahl.
  TConfirmDBGrid = class(TPPGDBGrid)
  public
    Asked: Integer;
    AskedCount: Integer;
    Answer: Boolean;
  protected
    function ConfirmDeleteSelected(ACount: Integer): Boolean; override;
  end;

  TDBGridMultiSelectTests = class(TDBTestCase)
  private
    FChanges: Integer;
    FDrawSelected: array of Boolean;
    function NewGrid(Multi: Boolean = True): TPPGDBGrid;
    procedure CountChange(Sender: TObject);
    procedure RecordDrawState(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    /// Linksklick auf eine Pufferzeile (0 = erste Datenzeile) in der Spalte ID.
    procedure ClickRow(G: TPPGDBGrid; ARow: Integer; Keys: Integer = 0; ACol: Integer = 1);
    procedure Key(G: TPPGDBGrid; AKey: Word; Shift: TShiftState);
    /// IDs der ausgewaehlten Datensaetze, aufsteigend als Text ("1,3,5").
    function SelectedIds(G: TPPGDBGrid): string;
  published
    procedure DefaultIsOffAndListStaysEmpty;
    procedure CurrentRowSelectedReadsAndWrites;
    procedure SelectAllAndClear;
    procedure FindIndexOfAndItems;
    procedure DeleteRemovesSelectedRecords;
    procedure RefreshRemovesInvalidBookmarks;
    procedure SelectionChangedFiresOncePerChange;
    procedure ClearedOnCloseSourceChangeAndOptionOff;
    procedure CtrlClickTogglesShiftClickSelectsRange;
    procedure IndicatorClickSelectsRow;
    procedure ShiftArrowsExtendAndShrink;
    procedure PlainNavigationClearsCtrlArrowKeeps;
    procedure CtrlAAndSpace;
    procedure CtrlDeleteAsksAndDeletes;
    procedure PaintMarksSelectedRows;
    procedure DarkModeUsesSelectionColor;
    procedure OrderFollowsIndexChange;
    procedure SelectInDisableControlsLoop;
  end;

implementation

type
  TGridAccess = class(TPPGDBGrid);
  TDataSetAccess = class(TDataSet);

{ TConfirmDBGrid }

function TConfirmDBGrid.ConfirmDeleteSelected(ACount: Integer): Boolean;
begin
  Inc(Asked);
  AskedCount := ACount;
  Result := Answer;
end;

{ TDBGridMultiSelectTests }

function TDBGridMultiSelectTests.NewGrid(Multi: Boolean): TPPGDBGrid;
begin
  Result := TPPGDBGrid.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 420, 24 * 9 + 2); // Titel + 8 Datenzeilen
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.HandleNeeded;
  if Multi then
    Result.Options := Result.Options + [dgMultiSelect];
  Result.DataSource := FSource;
end;

procedure TDBGridMultiSelectTests.CountChange(Sender: TObject);
begin
  Inc(FChanges);
end;

procedure TDBGridMultiSelectTests.RecordDrawState(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
begin
  if (ACol = 2) and (ARow >= 0) and (ARow < Length(FDrawSelected)) then
    FDrawSelected[ARow] := gdSelected in State;
end;

procedure TDBGridMultiSelectTests.ClickRow(G: TPPGDBGrid; ARow, Keys, ACol: Integer);
var
  R: TRect;
  LP: LPARAM;
begin
  R := G.CellRect(ACol, TGridAccess(G).VisualRow(TGridAccess(G).FixedRows + ARow));
  LP := MakeLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
  G.Perform(WM_LBUTTONDOWN, MK_LBUTTON or Keys, LP);
  G.Perform(WM_LBUTTONUP, Keys, LP);
end;

procedure TDBGridMultiSelectTests.Key(G: TPPGDBGrid; AKey: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := AKey;
  TGridAccess(G).KeyDown(K, Shift);
end;

function TDBGridMultiSelectTests.SelectedIds(G: TPPGDBGrid): string;
var
  I, Pos, C: Integer;
  B: TBookmark;
  L: TStringList;
begin
  L := TStringList.Create;
  try
    B := FData.Bookmark;
    Pos := TDataSetAccess(FData).ActiveRecord;
    FData.DisableControls;
    try
      for I := 0 to G.SelectedRows.Count - 1 do
      begin
        FData.Bookmark := G.SelectedRows[I];
        L.Add(Format('%.4d', [FData.FieldByName('ID').AsInteger]));
      end;
      // Zurueck an dieselbe Pufferzeile (GotoBookmark mittet), sonst
      // verschiebt die Pruefung die Anzeige fuer den naechsten Klick
      FData.Bookmark := B;
      C := TDataSetAccess(FData).ActiveRecord;
      if C > Pos then
        FData.MoveBy(-FData.MoveBy(TDataSetAccess(FData).BufferCount - 1 - Pos))
      else if C < Pos then
        FData.MoveBy(-FData.MoveBy(-Pos));
    finally
      FData.EnableControls;
    end;
    L.Sort;
    for I := 0 to L.Count - 1 do
      L[I] := IntToStr(StrToInt(L[I]));
    L.Delimiter := ',';
    Result := L.DelimitedText;
  finally
    L.Free;
  end;
end;

procedure TDBGridMultiSelectTests.DefaultIsOffAndListStaysEmpty;
var
  G: TPPGDBGrid;
begin
  FillData(10);
  G := NewGrid(False);
  CheckFalse(dgMultiSelect in G.Options, 'Vorgabe aus');
  CheckNotNull(G.SelectedRows);
  G.SelectedRows.CurrentRowSelected := True;
  G.SelectedRows.SelectAll;
  CheckEquals(0, G.SelectedRows.Count, 'ohne dgMultiSelect keine Auswahl');
  ClickRow(G, 2, MK_CONTROL);
  CheckEquals(3, FData.FieldByName('ID').AsInteger, 'Klick bewegt die Datenmenge');
  CheckEquals(0, G.SelectedRows.Count, 'Strg+Klick waehlt nichts');
  Key(G, Ord('A'), [ssCtrl]);
  CheckEquals(0, G.SelectedRows.Count, 'Strg+A waehlt keine Datensaetze');
end;

procedure TDBGridMultiSelectTests.CurrentRowSelectedReadsAndWrites;
var
  G: TPPGDBGrid;
begin
  FillData(10);
  G := NewGrid;
  CheckFalse(G.SelectedRows.CurrentRowSelected);
  G.SelectedRows.CurrentRowSelected := True;
  CheckTrue(G.SelectedRows.CurrentRowSelected);
  CheckEquals(1, G.SelectedRows.Count);
  G.SelectedRows.CurrentRowSelected := True;
  CheckEquals(1, G.SelectedRows.Count, 'kein Doppel');
  FData.Next;
  CheckFalse(G.SelectedRows.CurrentRowSelected, 'anderer Satz');
  G.SelectedRows.CurrentRowSelected := True;
  CheckEquals('1,2', SelectedIds(G));
  FData.First;
  G.SelectedRows.CurrentRowSelected := False;
  CheckEquals('2', SelectedIds(G));
  // Neuer Satz hat kein Lesezeichen: weder gewaehlt noch waehlbar
  FData.Append;
  CheckFalse(G.SelectedRows.CurrentRowSelected);
  G.SelectedRows.CurrentRowSelected := True;
  CheckEquals(1, G.SelectedRows.Count, 'neuer Satz nicht gewaehlt');
  FData.Cancel;
end;

procedure TDBGridMultiSelectTests.SelectAllAndClear;
var
  G: TPPGDBGrid;
begin
  FillData(30);
  G := NewGrid;
  FData.RecNo := 7;
  G.SelectedRows.SelectAll;
  CheckEquals(30, G.SelectedRows.Count);
  CheckEquals(7, FData.RecNo, 'Position bleibt');
  CheckTrue(G.SelectedRows.CurrentRowSelected);
  G.SelectedRows.Clear;
  CheckEquals(0, G.SelectedRows.Count);
  CheckFalse(G.SelectedRows.CurrentRowSelected);
end;

procedure TDBGridMultiSelectTests.FindIndexOfAndItems;
var
  G: TPPGDBGrid;
  B3, B5: TBookmark;
  I: Integer;
begin
  FillData(10);
  G := NewGrid;
  FData.RecNo := 5;
  B5 := FData.Bookmark;
  G.SelectedRows.CurrentRowSelected := True;
  FData.RecNo := 3;
  B3 := FData.Bookmark;
  G.SelectedRows.CurrentRowSelected := True;
  FData.RecNo := 8;
  G.SelectedRows.CurrentRowSelected := True;
  CheckEquals(3, G.SelectedRows.Count);
  // sortiert nach CompareBookmarks: 3, 5, 8
  CheckEquals(0, G.SelectedRows.IndexOf(B3));
  CheckEquals(1, G.SelectedRows.IndexOf(B5));
  CheckTrue(G.SelectedRows.Find(B5, I));
  CheckEquals(1, I);
  FData.RecNo := 4;
  CheckEquals(-1, G.SelectedRows.IndexOf(FData.Bookmark));
  CheckFalse(G.SelectedRows.Find(FData.Bookmark, I));
  CheckEquals(1, I, 'Einfuegeposition');
  CheckEquals(0, FData.CompareBookmarks(G.SelectedRows[1], B5), 'Items[1]');
  CheckEquals(-1, G.SelectedRows.IndexOf(nil), 'leeres Lesezeichen');
  try
    B3 := G.SelectedRows.Items[3];
    Fail('Index ausserhalb');
  except
    on E: EPPGError do
      ;
  end;
end;

procedure TDBGridMultiSelectTests.DeleteRemovesSelectedRecords;
var
  G: TPPGDBGrid;
  I: Integer;
begin
  FillData(10);
  G := NewGrid;
  for I := 1 to 10 do
    if I in [2, 4, 6] then
    begin
      FData.RecNo := I;
      G.SelectedRows.CurrentRowSelected := True;
    end;
  G.SelectedRows.Delete;
  CheckEquals(7, FData.RecordCount);
  CheckEquals(0, G.SelectedRows.Count);
  FData.First;
  while not FData.Eof do
  begin
    CheckFalse(FData.FieldByName('ID').AsInteger in [2, 4, 6], 'geloescht');
    FData.Next;
  end;
end;

procedure TDBGridMultiSelectTests.RefreshRemovesInvalidBookmarks;
var
  G: TPPGDBGrid;
begin
  FillData(10);
  G := NewGrid;
  FData.RecNo := 2;
  G.SelectedRows.CurrentRowSelected := True;
  FData.RecNo := 3;
  G.SelectedRows.CurrentRowSelected := True;
  FData.RecNo := 4;
  G.SelectedRows.CurrentRowSelected := True;
  // Satz an der Liste vorbei geloescht: Lesezeichen bleibt bis Refresh
  FData.RecNo := 3;
  FData.Delete;
  CheckEquals(3, G.SelectedRows.Count);
  FChanges := 0;
  G.OnSelectionChanged := CountChange;
  CheckTrue(G.SelectedRows.Refresh, 'ungueltiges entfernt');
  CheckEquals(2, G.SelectedRows.Count);
  CheckEquals('2,4', SelectedIds(G));
  CheckEquals(1, FChanges, 'Ereignis');
  CheckFalse(G.SelectedRows.Refresh, 'nichts mehr zu entfernen');
  CheckEquals(1, FChanges, 'kein weiteres Ereignis');
end;

procedure TDBGridMultiSelectTests.SelectionChangedFiresOncePerChange;
var
  G: TPPGDBGrid;
begin
  FillData(10);
  G := NewGrid;
  G.OnSelectionChanged := CountChange;
  FChanges := 0;
  G.SelectedRows.CurrentRowSelected := True;
  CheckEquals(1, FChanges);
  G.SelectedRows.CurrentRowSelected := True;
  CheckEquals(1, FChanges, 'unveraendert');
  G.SelectedRows.SelectAll;
  CheckEquals(2, FChanges, 'SelectAll einmal');
  G.SelectedRows.Clear;
  CheckEquals(3, FChanges);
  G.SelectedRows.Clear;
  CheckEquals(3, FChanges, 'leere Liste');
  // Bereich per Umschalt+Klick: ein Ereignis
  ClickRow(G, 0);
  FChanges := 0;
  ClickRow(G, 4, MK_SHIFT);
  CheckEquals(5, G.SelectedRows.Count);
  CheckEquals(1, FChanges, 'Bereich einmal');
end;

procedure TDBGridMultiSelectTests.ClearedOnCloseSourceChangeAndOptionOff;
var
  G: TPPGDBGrid;
  S2: TDataSource;
begin
  FillData(10);
  G := NewGrid;
  G.SelectedRows.SelectAll;
  CheckEquals(10, G.SelectedRows.Count);
  FData.Close;
  CheckEquals(0, G.SelectedRows.Count, 'Schliessen');
  FData.Open;
  G.SelectedRows.SelectAll;
  CheckEquals(10, G.SelectedRows.Count);
  S2 := TDataSource.Create(FForm);
  S2.DataSet := FData;
  G.DataSource := S2;
  CheckEquals(0, G.SelectedRows.Count, 'andere DataSource');
  G.SelectedRows.SelectAll;
  CheckEquals(10, G.SelectedRows.Count);
  S2.DataSet := nil;
  CheckEquals(0, G.SelectedRows.Count, 'DataSet der DataSource weg');
  G.DataSource := FSource;
  G.SelectedRows.SelectAll;
  CheckEquals(10, G.SelectedRows.Count);
  G.Options := G.Options - [dgMultiSelect];
  CheckEquals(0, G.SelectedRows.Count, 'Option aus');
end;

procedure TDBGridMultiSelectTests.CtrlClickTogglesShiftClickSelectsRange;
var
  G: TPPGDBGrid;
begin
  FillData(10);
  G := NewGrid;
  G.Options := G.Options - [dgEditing];
  ClickRow(G, 0);
  CheckEquals('1', SelectedIds(G), 'Klick waehlt den Satz (wie TDBGrid)');
  ClickRow(G, 2, MK_CONTROL);
  CheckEquals('1,3', SelectedIds(G), 'Strg+Klick nimmt dazu');
  CheckEquals(3, FData.FieldByName('ID').AsInteger);
  ClickRow(G, 2, MK_CONTROL);
  CheckEquals('1', SelectedIds(G), 'Strg+Klick nimmt heraus');
  ClickRow(G, 5, MK_SHIFT);
  CheckEquals('3,4,5,6', SelectedIds(G), 'Umschalt+Klick: Bereich vom Anker');
  CheckEquals('1', TGridAccess(G).GetCellText(1, TGridAccess(G).FixedRows), 'Anzeige springt nicht');
  ClickRow(G, 1, MK_SHIFT);
  CheckEquals('2,3', SelectedIds(G), 'Bereich nach oben, Anker bleibt');
  ClickRow(G, 6, MK_SHIFT or MK_CONTROL);
  CheckEquals('2,3,4,5,6,7', SelectedIds(G), 'Strg+Umschalt: Bereich dazu');
  ClickRow(G, 4);
  CheckEquals('5', SelectedIds(G), 'Klick ohne Taste hebt auf');
end;

procedure TDBGridMultiSelectTests.IndicatorClickSelectsRow;
var
  G: TPPGDBGrid;
begin
  FillData(10);
  G := NewGrid;
  ClickRow(G, 3, MK_CONTROL, 0);
  CheckEquals(4, FData.FieldByName('ID').AsInteger, 'Indikator wechselt den Satz');
  CheckEquals('4', SelectedIds(G));
end;

procedure TDBGridMultiSelectTests.ShiftArrowsExtendAndShrink;
var
  G: TPPGDBGrid;
  N: Integer;
begin
  FillData(5);
  G := NewGrid;
  Key(G, VK_DOWN, [ssShift]);
  Key(G, VK_DOWN, [ssShift]);
  CheckEquals('1,2,3', SelectedIds(G), 'erweitert');
  Key(G, VK_UP, [ssShift]);
  CheckEquals('1,2', SelectedIds(G), 'zum Anker hin verkleinert');
  Key(G, VK_UP, [ssShift]);
  CheckEquals('1', SelectedIds(G));
  // am Ende: Umschalt+Pfeil runter haengt keinen Satz an (dgEditing ist an)
  FData.Last;
  G.SelectedRows.Clear;
  N := FData.RecordCount;
  Key(G, VK_DOWN, [ssShift]);
  CheckEquals(N, FData.RecordCount, 'kein Anhaengen');
  CheckTrue(FData.State = dsBrowse);
  CheckEquals('5', SelectedIds(G));
  // Umschalt+Strg+Pos1: Bereich bis zum Anfang
  Key(G, VK_HOME, [ssShift, ssCtrl]);
  CheckEquals('1,2,3,4,5', SelectedIds(G));
end;

procedure TDBGridMultiSelectTests.PlainNavigationClearsCtrlArrowKeeps;
var
  G: TPPGDBGrid;
begin
  FillData(10);
  G := NewGrid;
  G.SelectedRows.CurrentRowSelected := True;
  Key(G, VK_DOWN, [ssCtrl]);
  CheckEquals(2, FData.RecNo);
  CheckEquals('1', SelectedIds(G), 'Strg+Pfeil bewegt nur');
  Key(G, VK_SPACE, [ssCtrl]);
  CheckEquals('1,2', SelectedIds(G), 'Strg+Leertaste nimmt dazu');
  Key(G, VK_DOWN, []);
  CheckEquals(3, FData.RecNo);
  CheckEquals(0, G.SelectedRows.Count, 'Pfeil ohne Taste hebt auf');
  G.SelectedRows.CurrentRowSelected := True;
  Key(G, VK_NEXT, []);
  CheckEquals(0, G.SelectedRows.Count, 'Bild runter hebt auf');
end;

procedure TDBGridMultiSelectTests.CtrlAAndSpace;
var
  G: TPPGDBGrid;
begin
  FillData(12);
  G := NewGrid;
  Key(G, Ord('A'), [ssCtrl]);
  CheckEquals(12, G.SelectedRows.Count, 'Strg+A');
  Key(G, VK_SPACE, [ssCtrl]);
  CheckEquals(11, G.SelectedRows.Count, 'Strg+Leertaste nimmt heraus');
  CheckFalse(G.SelectedRows.CurrentRowSelected);
  // Leertaste in einer Textspalte schaltet ebenfalls um
  G.Col := 2;
  Key(G, VK_SPACE, []);
  CheckTrue(G.SelectedRows.CurrentRowSelected, 'Leertaste');
end;

procedure TDBGridMultiSelectTests.CtrlDeleteAsksAndDeletes;
var
  G: TConfirmDBGrid;
begin
  FillData(10);
  G := TConfirmDBGrid.Create(FForm);
  G.Parent := FForm;
  G.SetBounds(0, 0, 420, 24 * 9 + 2);
  G.Animation.Enabled := False;
  G.HandleNeeded;
  G.Options := G.Options + [dgMultiSelect];
  G.DataSource := FSource;
  FData.RecNo := 2;
  G.SelectedRows.CurrentRowSelected := True;
  FData.RecNo := 5;
  G.SelectedRows.CurrentRowSelected := True;
  G.Answer := False;
  Key(G, VK_DELETE, [ssCtrl]);
  CheckEquals(1, G.Asked, 'Rueckfrage');
  CheckEquals(2, G.AskedCount, 'Anzahl in der Rueckfrage');
  CheckEquals(10, FData.RecordCount, 'abgelehnt');
  CheckEquals(2, G.SelectedRows.Count);
  G.Answer := True;
  Key(G, VK_DELETE, [ssCtrl]);
  CheckEquals(8, FData.RecordCount, 'beide geloescht');
  CheckEquals(0, G.SelectedRows.Count);
  // ohne Auswahl: Strg+Entf loescht wie bisher den aktiven Satz
  G.Options := G.Options - [dgConfirmDelete];
  Key(G, VK_DELETE, [ssCtrl]);
  CheckEquals(7, FData.RecordCount, 'aktiver Satz');
  CheckEquals(2, G.Asked, 'ohne dgConfirmDelete keine Rueckfrage');
end;

procedure TDBGridMultiSelectTests.PaintMarksSelectedRows;
var
  G: TPPGDBGrid;
  Bmp: TBitmap;
  R2, R3: TRect;
  X: Integer;
  D: Integer;
begin
  FillData(10);
  G := NewGrid;
  G.Options := G.Options - [dgEditing];
  FData.RecNo := 3;
  G.SelectedRows.CurrentRowSelected := True;
  FData.First;
  // Indikator: Haken fuer gewaehlte Saetze, Zeiger fuer den aktiven
  D := TGridAccess(G).FixedRows;
  CheckEquals(#$2713, TGridAccess(G).GetCellText(0, D + 2), 'Haken');
  CheckEquals('', TGridAccess(G).GetCellText(0, D + 3));
  CheckNotEquals('', TGridAccess(G).GetCellText(0, D), 'Zeiger');
  // Paint liest nur den Zwischenspeicher (kein OnGetText waehrend Paint)
  FData.FieldByName('Name').OnGetText := CountGetText;
  G.Invalidate;
  FData.Next;
  FData.Prior;
  FGetTextCalls := 0;
  SetLength(FDrawSelected, D + 8);
  G.OnDrawCell := RecordDrawState;
  Bmp := RenderToBitmap(G);
  try
    CheckEquals(0, FGetTextCalls, 'Paint ohne Datenzugriff');
    R2 := G.CellRect(2, TGridAccess(G).VisualRow(D + 2));
    R3 := G.CellRect(2, TGridAccess(G).VisualRow(D + 3));
    X := R2.Right - 4;
    CheckNotEquals(Integer(Bmp.Canvas.Pixels[X, (R3.Top + R3.Bottom) div 2]),
      Integer(Bmp.Canvas.Pixels[X, (R2.Top + R2.Bottom) div 2]), 'gewaehlte Zeile hervorgehoben');
    CheckTrue(FDrawSelected[D + 2], 'OnDrawCell: gdSelected');
    CheckFalse(FDrawSelected[D + 3], 'OnDrawCell: nicht gewaehlt');
  finally
    Bmp.Free;
  end;
end;

procedure TDBGridMultiSelectTests.DarkModeUsesSelectionColor;
var
  G: TPPGDBGrid;
  Bmp: TBitmap;
  R2, R3: TRect;
  X: Integer;
  D: Integer;
  C2, C3: TColor;
begin
  TPPGTheme.Mode := tmDark;
  FillData(10);
  G := NewGrid;
  G.Options := G.Options - [dgEditing];
  FData.RecNo := 3;
  G.SelectedRows.CurrentRowSelected := True;
  FData.First;
  D := TGridAccess(G).FixedRows;
  Bmp := RenderToBitmap(G);
  try
    R2 := G.CellRect(2, TGridAccess(G).VisualRow(D + 2));
    R3 := G.CellRect(2, TGridAccess(G).VisualRow(D + 3));
    X := R2.Right - 4;
    C2 := ColorToRGB(Bmp.Canvas.Pixels[X, (R2.Top + R2.Bottom) div 2]);
    C3 := ColorToRGB(Bmp.Canvas.Pixels[X, (R3.Top + R3.Bottom) div 2]);
    CheckNotEquals(Integer(C3), Integer(C2), 'dunkel: gewaehlte Zeile hervorgehoben');
    // Dunkle Flaeche bleibt dunkel (keine helle Systemfarbe)
    CheckTrue(GetRValue(C3) + GetGValue(C3) + GetBValue(C3) < 3 * 128, 'Hintergrund dunkel');
    CheckTrue(GetRValue(C2) + GetGValue(C2) + GetBValue(C2) < 3 * 160, 'Auswahl dunkel');
  finally
    Bmp.Free;
  end;
end;

procedure TDBGridMultiSelectTests.OrderFollowsIndexChange;
var
  G: TPPGDBGrid;
  I: Integer;
begin
  FillData(20);
  G := NewGrid;
  for I := 1 to 20 do
    if I mod 4 = 0 then
    begin
      FData.RecNo := I;
      G.SelectedRows.CurrentRowSelected := True;
    end;
  CheckEquals('4,8,12,16,20', SelectedIds(G));
  // Andere Sortierung
  FData.AddIndex('Absteigend', 'ID', [ixDescending]);
  FData.IndexName := 'Absteigend';
  FData.First;
  CheckEquals(20, FData.FieldByName('ID').AsInteger, 'absteigend');
  // Lesezeichen des ClientDataSets haengen am Index: Refresh liest sie neu
  CheckFalse(G.SelectedRows.Refresh, 'alle gueltig');
  CheckEquals(20, FData.FieldByName('ID').AsInteger, 'Position bleibt');
  CheckTrue(G.SelectedRows.CurrentRowSelected, '20 gewaehlt');
  FData.Next;
  CheckFalse(G.SelectedRows.CurrentRowSelected, '19 nicht gewaehlt');
  FData.RecNo := 5; // ID 16
  CheckEquals(16, FData.FieldByName('ID').AsInteger);
  CheckTrue(G.SelectedRows.CurrentRowSelected, '16 gewaehlt');
  CheckEquals(5, G.SelectedRows.Count);
  CheckEquals('4,8,12,16,20', SelectedIds(G));
end;

procedure TDBGridMultiSelectTests.SelectInDisableControlsLoop;
var
  G: TPPGDBGrid;
  N, M: Integer;
  S: string;
begin
  // Typisches Muster im Anwendungscode: die Auswahl darf den Satzzeiger
  // waehrend der Schleife nicht verstellen
  FillData(10);
  G := NewGrid;
  N := 0;
  FData.DisableControls;
  try
    FData.First;
    while not FData.Eof do
    begin
      Inc(N);
      CheckTrue(N <= 10, 'Schleife endet');
      if Odd(FData.FieldByName('ID').AsInteger) then
        G.SelectedRows.CurrentRowSelected := True;
      FData.Next;
    end;
  finally
    FData.EnableControls;
  end;
  CheckEquals(10, N);
  CheckEquals('1,3,5,7,9', SelectedIds(G));
  // Indikator nach EnableControls: Haken bei ungeraden IDs (ausser dem
  // aktiven Satz 10, der den Zeiger zeigt)
  M := 0;
  for N := TGridAccess(G).FixedRows to TGridAccess(G).RowCount - 1 do
  begin
    S := TGridAccess(G).GetCellText(1, N);
    if (S = '') or (S = '10') then
      Continue;
    Inc(M);
    if Odd(StrToInt(S)) then
      CheckEquals(#$2713, TGridAccess(G).GetCellText(0, N), 'Haken bei ' + S)
    else
      CheckEquals('', TGridAccess(G).GetCellText(0, N), 'kein Haken bei ' + S);
  end;
  CheckTrue(M >= 2, 'Zeilen geprueft');
end;

initialization
  RegisterTest('DBGridMultiSelect', TDBGridMultiSelectTests.Suite);

end.
