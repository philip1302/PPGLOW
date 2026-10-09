unit PPG.Tests.Phase13c;

{ Tests fuer Phase 13c: Gruppieren (Gruppenzeilen, Ebenen, Auf-/Zuklappen,
  Gruppenleiste) und Summen (Summenzeile, Gruppenfuss, agCustom). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids, Vcl.Menus,
  PPG.Types, PPG.UIA, PPG.UIA.Intf, PPG.Grid, PPG.Grid.Columns, PPG.Grid.Data,
  PPG.Tests.Controls;

type
  TGridGroupTests = class(TControlTestCase)
  private
    FOldFS: TFormatSettings;
    FCustomCalls: Integer;
    procedure CustomAggregate(Sender: TObject; ACol, Group: Integer; var Value: string);
    procedure GroupTextEvent(Sender: TObject; Group: Integer; var Text: string);
    function NewGrid: TPPGGrid;
    /// Spalten: # | Kategorie | Name | Menge (8 Zeilen).
    function SampleGrid: TPPGGrid;
    /// Inhalt der Ansicht: "G:<Schluessel>" fuer Gruppenkoepfe, "F" fuer Fuesse,
    /// sonst der Name der Zeile.
    function ViewText(G: TPPGGrid): string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure GroupByCreatesGroupRows;
    procedure GroupOrderFollowsSort;
    procedure TwoLevels;
    procedure ExpandCollapse;
    procedure CollapseStateSurvivesResort;
    procedure KeyboardOnGroupRow;
    procedure MouseOnGroupRow;
    procedure FooterAggregates;
    procedure FooterFollowsFilter;
    procedure CustomAggregateEvent;
    procedure GroupFooterRows;
    procedure DataChangeRecalcsLater;
    procedure GroupTextMarkup;
    procedure GroupPanelDragAndChips;
    procedure HeaderMenuGroups;
    procedure LayoutKeepsGroups;
    procedure UiaGroupElements;
    procedure ExportSkipsGroupRows;
    procedure PaintsAllParts;
    procedure ColumnGroupIndexInDfm;
  end;

implementation

uses
  PPG.Markup.Parser, PPG.Consts, PPG.Lang;

type
  TGridAccess = class(TPPGGrid);

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := MakeLParam(Word(SmallInt(X)), Word(SmallInt(Y)));
end;

function CenterOf(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

const
  Cats: array[1..8] of string = ('Obst', 'Gemuese', 'Obst', 'Brot', 'Gemuese', 'Obst', 'Brot', 'Obst');
  Names: array[1..8] of string = ('Apfel', 'Kohl', 'Birne', 'Laib', 'Lauch', 'Kiwi', 'Semmel', 'Pflaume');
  Qty: array[1..8] of string = ('10', '4', '6', '2', '8', '1', '30', '5');
  Kinds: array[1..8] of string = ('rot', 'gruen', 'gruen', 'hell', 'gruen', 'braun', 'hell', 'rot');

{ TGridGroupTests }

procedure TGridGroupTests.SetUp;
begin
  inherited SetUp;
  FOldFS := FormatSettings;
  FormatSettings := TFormatSettings.Create('de-DE');
end;

procedure TGridGroupTests.TearDown;
begin
  FormatSettings := FOldFS;
  inherited TearDown;
end;

procedure TGridGroupTests.CustomAggregate(Sender: TObject; ACol, Group: Integer;
  var Value: string);
var
  Rows: TArray<Integer>;
begin
  Inc(FCustomCalls);
  Rows := TPPGGrid(Sender).GroupDataRows(Group);
  Value := 'n=' + IntToStr(Length(Rows));
end;

procedure TGridGroupTests.GroupTextEvent(Sender: TObject; Group: Integer; var Text: string);
begin
  Text := '<i>' + TPPGGrid(Sender).GroupInfo(Group).Key + '</i>';
end;

function TGridGroupTests.NewGrid: TPPGGrid;
begin
  Result := TPPGGrid.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 420, 300);
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.HandleNeeded;
end;

function TGridGroupTests.SampleGrid: TPPGGrid;
var
  R: Integer;
begin
  Result := NewGrid;
  Result.Columns.Add.Title := '#';
  Result.Columns.Add.Title := 'Kategorie';
  Result.Columns.Add.Title := 'Name';
  Result.Columns.Add.Title := 'Menge';
  Result.Columns.Add.Title := 'Art';
  Result.FixedCols := 1;
  Result.RowCount := 9;
  for R := 1 to 8 do
  begin
    Result.Cells[0, R] := IntToStr(R);
    Result.Cells[1, R] := Cats[R];
    Result.Cells[2, R] := Names[R];
    Result.Cells[3, R] := Qty[R];
    Result.Cells[4, R] := Kinds[R];
  end;
end;

function TGridGroupTests.ViewText(G: TPPGGrid): string;
var
  V, D, Grp: Integer;
begin
  Result := '';
  for V := G.FixedRows to TGridAccess(G).VRowCount - 1 do
  begin
    if Result <> '' then
      Result := Result + ',';
    D := G.DataRow(V);
    Grp := G.GroupOfRow(V);
    if Grp >= 0 then
      Result := Result + 'G:' + G.GroupInfo(Grp).Key
    else if D < 0 then
      Result := Result + 'F'
    else
      Result := Result + G.Cells[2, D];
  end;
end;

procedure TGridGroupTests.GroupByCreatesGroupRows;
var
  G: TPPGGrid;
  V: Integer;
begin
  G := SampleGrid;
  G.GroupBy([1]);
  CheckEquals(3, G.GroupCount);
  CheckEquals(1, Length(G.GroupColumns));
  CheckEquals(0, G.Columns[1].GroupIndex, 'GroupIndex gesetzt');
  CheckEquals('G:Brot,Laib,Semmel,G:Gemuese,Kohl,Lauch,G:Obst,Apfel,Birne,Kiwi,Pflaume',
    ViewText(G), 'Gruppen aufsteigend, Reihenfolge innerhalb stabil');
  CheckEquals(4, G.GroupInfo(2).Count);
  CheckEquals(0, G.GroupInfo(2).Level);
  CheckEquals(1, G.GroupInfo(2).Column);
  CheckTrue(G.GroupInfo(2).Expanded);
  V := G.GroupRow(0);
  CheckEquals(1, V);
  CheckEquals(-3, G.DataRow(V), 'Gruppenkopf hat keine Datenzeile');
  CheckEquals(V, G.VisualRow(4) - 1, 'Laib direkt unter Brot');
  G.Ungroup;
  CheckEquals(0, G.GroupCount);
  CheckEquals('Apfel,Kohl,Birne,Laib,Lauch,Kiwi,Semmel,Pflaume', ViewText(G));
end;

procedure TGridGroupTests.GroupOrderFollowsSort;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.GroupBy([1]);
  G.SortBy(1, False);
  CheckEquals('G:Obst,Apfel,Birne,Kiwi,Pflaume,G:Gemuese,Kohl,Lauch,G:Brot,Laib,Semmel',
    ViewText(G), 'Gruppenspalte absteigend sortiert');
  G.SortBy(3, True); // nach Menge: Gruppen aufsteigend, darin nach Menge
  CheckEquals('G:Brot,Laib,Semmel,G:Gemuese,Kohl,Lauch,G:Obst,Kiwi,Pflaume,Birne,Apfel',
    ViewText(G));
end;

procedure TGridGroupTests.TwoLevels;
var
  G: TPPGGrid;
  I, Sub: Integer;
begin
  G := SampleGrid;
  G.GroupBy([1, 4]);
  CheckEquals(2, Length(G.GroupColumns));
  // Brot(hell) Gemuese(gruen) Obst(braun, gruen, rot)
  CheckEquals(3 + 1 + 1 + 3, G.GroupCount);
  CheckEquals('G:Brot,G:hell,Laib,Semmel,G:Gemuese,G:gruen,Kohl,Lauch,' +
    'G:Obst,G:braun,Kiwi,G:gruen,Birne,G:rot,Apfel,Pflaume', ViewText(G));
  Sub := 0;
  for I := 0 to G.GroupCount - 1 do
    if G.GroupInfo(I).Level = 1 then
    begin
      Inc(Sub);
      CheckTrue(G.GroupInfo(I).Parent >= 0);
      CheckEquals(0, G.GroupInfo(G.GroupInfo(I).Parent).Level);
    end;
  CheckEquals(5, Sub);
end;

procedure TGridGroupTests.ExpandCollapse;
var
  G: TPPGGrid;
  N0: Integer;
begin
  G := SampleGrid;
  G.GroupBy([1]);
  N0 := TGridAccess(G).VRowCount;
  G.Row := 5; // Lauch (Gemuese)
  G.ExpandGroup(1, False);
  CheckEquals('G:Brot,Laib,Semmel,G:Gemuese,G:Obst,Apfel,Birne,Kiwi,Pflaume', ViewText(G));
  CheckEquals(N0 - 2, TGridAccess(G).VRowCount);
  CheckEquals(G.GroupRow(1), G.FocusRow, 'Fokus auf die zugeklappte Gruppe');
  CheckEquals(-1, G.Row, 'Row auf Gruppenzeile');
  CheckEquals(-1, G.VisualRow(5), 'Zeile nicht sichtbar');
  CheckFalse(G.GroupInfo(1).Expanded);
  G.FullCollapse;
  CheckEquals('G:Brot,G:Gemuese,G:Obst', ViewText(G));
  G.FullExpand;
  CheckEquals(N0, TGridAccess(G).VRowCount);
  G.ExpandGroup(99, False); // unbekannt: nichts
end;

procedure TGridGroupTests.CollapseStateSurvivesResort;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.GroupBy([1]);
  G.ExpandGroup(2, False); // Obst zu
  G.SortBy(3, True);
  CheckEquals('G:Brot,Laib,Semmel,G:Gemuese,Kohl,Lauch,G:Obst', ViewText(G),
    'Zustand ueber den Pfad gemerkt');
  G.FullCollapse;
  G.SortBy(2, True);
  CheckEquals('G:Brot,G:Gemuese,G:Obst', ViewText(G));
end;

procedure TGridGroupTests.KeyboardOnGroupRow;
var
  G: TPPGGrid;
  K: Word;
begin
  G := SampleGrid;
  G.GroupBy([1, 4]);
  TGridAccess(G).MoveFocus(1, G.GroupRow(0), False, False); // Brot
  K := VK_LEFT;
  TGridAccess(G).KeyDown(K, []);
  CheckFalse(G.GroupInfo(0).Expanded, 'links klappt zu');
  K := VK_RIGHT;
  TGridAccess(G).KeyDown(K, []);
  CheckTrue(G.GroupInfo(0).Expanded, 'rechts klappt auf');
  K := VK_RIGHT;
  TGridAccess(G).KeyDown(K, []);
  CheckEquals(G.GroupRow(1), G.FocusRow, 'rechts auf offener Gruppe: zur ersten Untergruppe');
  K := VK_LEFT;
  TGridAccess(G).KeyDown(K, []);
  CheckFalse(G.GroupInfo(1).Expanded);
  K := VK_LEFT;
  TGridAccess(G).KeyDown(K, []);
  CheckEquals(G.GroupRow(0), G.FocusRow, 'links auf zugeklappter Untergruppe: zur Elterngruppe');
  K := VK_RETURN;
  TGridAccess(G).KeyDown(K, []);
  CheckFalse(G.GroupInfo(0).Expanded, 'Enter schaltet um');
  K := VK_SPACE;
  TGridAccess(G).KeyDown(K, []);
  CheckTrue(G.GroupInfo(0).Expanded);
  K := VK_DOWN;
  TGridAccess(G).KeyDown(K, []);
  CheckEquals(G.GroupRow(1), G.FocusRow, 'Pfeil runter wie gewohnt');
end;

procedure TGridGroupTests.MouseOnGroupRow;
var
  G: TPPGGrid;
  R: TRect;
  P: TPoint;
begin
  FForm.Show;
  try
    G := SampleGrid;
    G.GroupBy([1]);
    R := TGridAccess(G).GroupExpanderRect(G.GroupRow(1));
    CheckFalse(IsRectEmpty(R));
    P := CenterOf(R);
    G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
    G.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y));
    CheckFalse(G.GroupInfo(1).Expanded, 'Klick auf den Pfeil');
    CheckEquals(G.GroupRow(1), G.FocusRow);
    P := CenterOf(G.CellRect(3, G.GroupRow(1)));
    G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
    G.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y));
    CheckFalse(G.GroupInfo(1).Expanded, 'Einfachklick neben dem Pfeil: nur Fokus');
    G.Perform(WM_LBUTTONDBLCLK, MK_LBUTTON, MouseLParam(P.X, P.Y));
    G.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y));
    CheckTrue(G.GroupInfo(1).Expanded, 'Doppelklick');
    CheckFalse(G.EditorMode);
  finally
    FForm.Hide;
  end;
end;

procedure TGridGroupTests.FooterAggregates;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.ShowFooter := True;
  G.Columns[3].Aggregate := agSum;
  CheckEquals('66', G.FooterText(3), 'Summe 10+4+6+2+8+1+30+5');
  G.Columns[3].Aggregate := agAvg;
  CheckEquals('8,25', G.FooterText(3));
  G.Columns[3].FooterFormat := '0.000';
  CheckEquals('8,250', G.FooterText(3), 'FooterFormat');
  G.Columns[3].FooterFormat := '';
  G.Columns[3].Aggregate := agMin;
  CheckEquals('1', G.FooterText(3));
  G.Columns[3].Aggregate := agMax;
  CheckEquals('30', G.FooterText(3));
  G.Columns[2].Aggregate := agCount;
  CheckEquals('8', G.FooterText(2), 'Anzahl nicht leerer Werte');
  G.Columns[2].Aggregate := agSum;
  CheckEquals('', G.FooterText(2), 'Summe ohne Zahlen: kein Wert');
  CheckEquals('', G.FooterText(1), 'ohne Aggregate');
  G.Cells[3, 1] := '1.000,5';
  CheckEquals('1.000,5', G.FooterText(3), 'Tausendertrenner (Max)');
end;

procedure TGridGroupTests.FooterFollowsFilter;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.Columns[3].Aggregate := agSum;
  G.Filters[1] := 'Obst';
  CheckEquals('22', G.FooterText(3), 'nur gefilterte Zeilen');
  G.ClearFilters;
  CheckEquals('66', G.FooterText(3));
end;

procedure TGridGroupTests.CustomAggregateEvent;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.OnCustomAggregate := CustomAggregate;
  G.Columns[2].Aggregate := agCustom;
  G.GroupBy([1]);
  CheckEquals('n=8', G.FooterText(2));
  CheckEquals('n=4', G.GroupFooterText(2, 2), 'Obst');
  CheckTrue(FCustomCalls >= 4, 'Summenzeile + 3 Gruppen');
end;

procedure TGridGroupTests.GroupFooterRows;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.Columns[3].Aggregate := agSum;
  G.GroupFooter := True;
  G.GroupBy([1, 4]);
  CheckEquals('G:Brot,G:hell,Laib,Semmel,F,F,G:Gemuese,G:gruen,Kohl,Lauch,F,F,' +
    'G:Obst,G:braun,Kiwi,F,G:gruen,Birne,F,G:rot,Apfel,Pflaume,F,F', ViewText(G));
  CheckEquals('32', G.GroupFooterText(0, 3), 'Brot');
  CheckEquals('22', G.GroupFooterText(4, 3), 'Obst = Summe der Untergruppen');
  CheckEquals('15', G.GroupFooterText(7, 3), 'Obst/rot (Vorordnung: 4 Obst, 5 braun, 6 gruen, 7 rot)');
  CheckEquals('66', G.FooterText(3));
  G.ExpandGroup(0, False);
  CheckEquals('G:Brot,G:Gemuese', Copy(ViewText(G), 1, Length('G:Brot,G:Gemuese')),
    'zugeklappt ohne Fuss');
  G.GroupFooter := False;
  CheckEquals(0, Pos(',F', ViewText(G)));
end;

procedure TGridGroupTests.DataChangeRecalcsLater;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.Columns[3].Aggregate := agSum;
  CheckEquals('66', G.FooterText(3));
  G.Cells[3, 1] := '20';
  CheckEquals('66', TGridAccess(G).CachedFooterText(3), 'nicht sofort');
  Application.ProcessMessages;
  CheckEquals('76', TGridAccess(G).CachedFooterText(3), 'nach der Nachricht');
  G.Cells[3, 1] := '0';
  CheckEquals('56', G.FooterText(3), 'FooterText rechnet bei Bedarf');
end;

procedure TGridGroupTests.GroupTextMarkup;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.Cells[1, 1] := 'A<b>&';
  G.GroupBy([1]);
  CheckEquals('<b>Kategorie:</b> A&lt;b&gt;&amp; (1)', G.GroupText(0), 'Werte maskiert');
  CheckEquals('Kategorie: A<b>& (1)', PPGStripMarkup(G.GroupText(0)));
  G.OnGetGroupText := GroupTextEvent;
  CheckEquals('<i>A<b>&</i>', G.GroupText(0));
  CheckEquals('', G.GroupText(99));
end;

procedure TGridGroupTests.GroupPanelDragAndChips;
var
  G: TPPGGrid;
  P, Q: TPoint;
  Top0: Integer;
  Chips: TArray<TRect>;
begin
  FForm.Show;
  try
    G := SampleGrid;
    Top0 := G.CellRect(2, 0).Top;
    G.ShowGroupPanel := True;
    CheckTrue(G.CellRect(2, 0).Top > Top0, 'Leiste schiebt das Grid nach unten');
    // Kopf "Kategorie" in die Leiste ziehen
    P := CenterOf(G.CellRect(1, 0));
    Q := CenterOf(TGridAccess(G).GroupPanelRect);
    G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
    G.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P.X, P.Y - 10));
    G.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(Q.X, Q.Y));
    G.Perform(WM_LBUTTONUP, 0, MouseLParam(Q.X, Q.Y));
    CheckEquals(1, Length(G.GroupColumns), 'gruppiert');
    CheckEquals(1, G.GroupColumns[0]);
    CheckEquals(-1, G.SortColumn, 'Ziehen sortiert nicht');
    Chips := TGridAccess(G).GroupChipRects;
    CheckEquals(1, Length(Chips));
    // Chip anklicken: Gruppen absteigend
    P := Point(Chips[0].Left + 4, CenterOf(Chips[0]).Y);
    G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
    G.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y));
    CheckEquals(1, G.SortColumn);
    CheckFalse(G.SortAscending);
    // Kreuz: Gruppierung aufheben
    P := Point(Chips[0].Right - 6, CenterOf(Chips[0]).Y);
    G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
    G.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y));
    CheckEquals(0, Length(G.GroupColumns));
  finally
    FForm.Hide;
  end;
end;

procedure TGridGroupTests.HeaderMenuGroups;
var
  G: TPPGGrid;
  M: TPopupMenu;

  function ByTag(ATag: Integer): TMenuItem;
  var
    I: Integer;
  begin
    for I := 0 to M.Items.Count - 1 do
      if M.Items[I].Tag = ATag then
        Exit(M.Items[I]);
    Result := nil;
  end;

begin
  G := SampleGrid;
  M := G.CreateHeaderMenu(1);
  try
    CheckNotNull(ByTag(8), 'Nach dieser Spalte gruppieren');
    CheckNull(ByTag(10), 'Alle aufklappen erst mit Gruppen');
    ByTag(8).Click;
  finally
    M.Free;
  end;
  CheckEquals(3, G.GroupCount);
  M := G.CreateHeaderMenu(1);
  try
    CheckNull(ByTag(8));
    ByTag(11).Click; // alle zuklappen
    CheckFalse(G.GroupInfo(0).Expanded);
    ByTag(10).Click;
    CheckTrue(G.GroupInfo(0).Expanded);
    ByTag(9).Click; // Gruppierung aufheben
  finally
    M.Free;
  end;
  CheckEquals(0, G.GroupCount);
end;

procedure TGridGroupTests.LayoutKeepsGroups;
var
  G, G2: TPPGGrid;
  S: string;
begin
  G := SampleGrid;
  G.GroupBy([4, 1]);
  S := G.SaveLayout;
  CheckTrue(Pos('Group=4'#13#10'Group=1', S) > 0, S);
  G2 := SampleGrid;
  G2.LoadLayout(S);
  CheckEquals(2, Length(G2.GroupColumns));
  CheckEquals(4, G2.GroupColumns[0]);
  CheckEquals(1, G2.GroupColumns[1]);
  G2.LoadLayout('[PPGGridLayout]'#13#10'Version=1');
  CheckEquals(0, Length(G2.GroupColumns), 'Layout ohne Gruppen hebt auf');
end;

procedure TGridGroupTests.UiaGroupElements;
var
  G: TPPGGrid;
  A: TGridAccess;
  Id: TPPGUiaId;
begin
  G := SampleGrid;
  A := TGridAccess(G);
  G.GroupBy([1]);
  Id := A.UiaChild(PPGUiaId(0), G.FixedRows); // erste Zeile nach dem Kopf
  CheckEquals(PPGUiaKindGridGroup, Id.Kind);
  CheckEquals(0, Id.A);
  CheckTrue(A.UiaValid(Id));
  CheckEquals(Format(PPGStr(@SPPGGridGroupName), ['Kategorie', 'Brot', 2]), A.UiaName(Id));
  CheckTrue(A.UiaHasPattern(Id, UIA_ExpandCollapsePatternId));
  CheckEquals(ExpandCollapseState_Expanded, A.UiaExpandState(Id));
  A.UiaExecute(Id, uaCollapse, '');
  CheckFalse(G.GroupInfo(0).Expanded);
  CheckEquals(ExpandCollapseState_Collapsed, A.UiaExpandState(Id));
  CheckEquals(G.FixedRows, A.UiaIndexInParent(Id));
  A.UiaExecute(Id, uaExpand, '');
  CheckTrue(G.GroupInfo(0).Expanded);
  // Fokus auf der Gruppenzeile meldet das Gruppen-Element
  A.MoveFocus(1, G.GroupRow(2), False, False);
  Id := A.UiaCellId(1, G.FocusRow);
  CheckEquals(PPGUiaKindGridGroup, Id.Kind);
  CheckEquals(2, Id.A);
  G.ExpandGroup(0, False);
  Id := PPGUiaId(PPGUiaKindGridGroupFooter, 0);
  CheckFalse(A.UiaValid(Id), 'ohne Gruppenfuss');
end;

procedure TGridGroupTests.ExportSkipsGroupRows;
var
  G: TPPGGrid;
  T: IPPGTableSource;
  S: string;
begin
  G := SampleGrid;
  G.GroupBy([1]);
  G.ExpandGroup(0, False);
  Supports(G, IPPGTableSource, T);
  CheckEquals(8, T.TableRowCount, 'alle Datenzeilen, auch zugeklappte');
  CheckEquals('Laib', T.TableCellText(2, 0), 'Gruppenreihenfolge');
  S := G.ToCSV;
  CheckEquals(0, Pos('Brot (', S), 'keine Gruppenzeilen im CSV');
end;

procedure TGridGroupTests.PaintsAllParts;
var
  G: TPPGGrid;
  Bmp: TBitmap;
  I: Integer;
begin
  G := SampleGrid;
  G.ShowGroupPanel := True;
  G.ShowFooter := True;
  G.GroupFooter := True;
  G.Columns[3].Aggregate := agSum;
  G.Bands.Add.Caption := 'Band';
  G.Columns[2].Band := 0;
  G.FixedColsRight := 1;
  G.GroupBy([1, 4]);
  for I := 0 to 1 do
  begin
    if I = 1 then
      G.BiDiMode := bdRightToLeft;
    Bmp := RenderToBitmap(G);
    try
      CheckEquals(G.Width, Bmp.Width);
    finally
      Bmp.Free;
    end;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TGridGroupTests.ColumnGroupIndexInDfm;
var
  G, G2: TPPGGrid;
  M: TMemoryStream;
begin
  G := SampleGrid;
  G.Columns[3].Aggregate := agAvg;
  G.Columns[3].FooterFormat := '0.0';
  G.ShowFooter := True;
  G.GroupFooter := True;
  G.ShowGroupPanel := True;
  G.GroupBy([1]);
  M := TMemoryStream.Create;
  try
    M.WriteComponent(G);
    M.Position := 0;
    G2 := TPPGGrid.Create(FForm);
    G2.Parent := FForm;
    M.ReadComponent(G2);
    CheckEquals(0, G2.Columns[1].GroupIndex);
    CheckTrue(G2.Columns[3].Aggregate = agAvg);
    CheckEquals('0.0', G2.Columns[3].FooterFormat);
    CheckTrue(G2.ShowFooter and G2.GroupFooter and G2.ShowGroupPanel);
    G2.RowCount := 9;
    G2.Cells[1, 1] := 'x';
    G2.SortBy(-1);
    CheckTrue(G2.GroupCount > 0, 'nach dem Laden gruppiert');
  finally
    M.Free;
  end;
end;

initialization
  RegisterTest('Phase13c', TGridGroupTests.Suite);

end.
