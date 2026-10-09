unit PPG.Tests.Audit8C;

{ Audit-Paket 8C (Docs\Audit-Paket8-Plan.md, 8d #1-#10): Regressionstests.
  Die meisten Tests halten das Verhalten fest (vor dem Umbau gegen den alten
  Code gruen): Knoten-Index und Nachbarn nach allen Aenderungen, stabile
  Sortierung mit Markup, AutoCheck, Zeilen des Baums direkt nach Add,
  CheckAll, Gruppen-Layout, Markup-Layout, Auswahl und ComboBox-Eintraege.
  Die Zaehltests am Ende pruefen die Einsparung selbst. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Vcl.ComCtrls,
  PPG.Types, PPG.Items, PPG.Selection, PPG.Markup, PPG.ItemPainter, PPG.Render.Gdi,
  PPG.Controls.ItemList, PPG.ListBox, PPG.CheckListBox, PPG.TreeView, PPG.ComboBox,
  PPG.Tests.Controls;

type
  TAudit8CTests = class(TControlTestCase)
  private
    FChanges: Integer;
    FSelChanges: Integer;
    function NewTree: TPPGTreeView;
    procedure CheckTree(TV: TPPGTreeView; const Context: string);
    procedure TreeChange(Sender: TObject; Node: TPPGTreeNode);
    procedure CompareByLength(Sender: TObject; Node1, Node2: TPPGTreeNode;
      var Compare: Integer);
    procedure SelChange(Sender: TObject);
    procedure MeasureVar(Control: TWinControl; Index: Integer; var Height: Integer);
  published
    { 8d #4: Geschwister-Index }
    procedure TreeIndexAfterMutations;
    procedure TreeItemsLoopMatchesWalk;
    { 8d #3: AlphaSort }
    procedure AlphaSortStableWithMarkup;
    procedure AlphaSortOnCompareStable;
    { 8d #5: AutoCheck }
    procedure AutoCheckWithoutUpdate;
    procedure AutoCheckInsideUpdate;
    { 8d #6: Zeilen ohne Update-Klammer }
    procedure TreeRowsAfterAddWithoutUpdate;
    procedure TreeSelectionFollowsInsertedRows;
    procedure TreeDeleteSelectedFiresChangeAtOnce;
    { 8d #1: CheckAll }
    procedure CheckAllItemsEx;
    procedure CheckAllStringsSkipsHeaders;
    { 8d #2 / #8: Hoehen, Gruppen, Detailzeilen }
    procedure GroupLayoutHeights;
    procedure OwnerDrawVariableMeasureStillUsed;
    procedure TextLineHeightFollowsFont;
    procedure ItemsExSingleChangesUpdateFlags;
    procedure ListBoxItemsExAddKeepsSelection;
    { 8d #7: Markup }
    procedure MarkupLayoutFollowsBaseFont;
    { 8d #9: Auswahl }
    procedure SelectionSingleItemIndex;
    procedure SelectionInsertDeleteWithoutSelection;
    procedure SelectionSingleModeWithTwoSelected;
    { 8d #10: ComboBox }
    procedure ComboItemsExAddUnsorted;
    procedure ComboItemsExAddSorted;
    procedure ComboItemsExReplacesStrings;
    { Zaehltests }
    procedure CountTreeRebuildsWithoutUpdate;
    procedure CountDefaultHeightInGroupLayout;
  end;

implementation

type
  TLBAccess = class(TPPGListBox);

  /// Zaehlt Neuaufbauten der Zeilen (ItemsReset ruft ItemsChanged).
  TCountingTree = class(TPPGTreeView)
  protected
    procedure ItemsChanged; override;
  public
    Resets: Integer;
  end;

  /// Zaehlt, wie oft die Standardhoehe berechnet wird.
  TCountingListBox = class(TPPGListBox)
  protected
    function DefaultItemHeight: Integer; override;
  public
    Calls: Integer;
  end;

procedure TCountingTree.ItemsChanged;
begin
  Inc(Resets);
  inherited ItemsChanged;
end;

function TCountingListBox.DefaultItemHeight: Integer;
begin
  Inc(Calls);
  Result := inherited DefaultItemHeight;
end;

{ Helfer }

function TAudit8CTests.NewTree: TPPGTreeView;
begin
  Result := TPPGTreeView.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 220, 2000);
end;

procedure TAudit8CTests.TreeChange(Sender: TObject; Node: TPPGTreeNode);
begin
  Inc(FChanges);
end;

procedure TAudit8CTests.SelChange(Sender: TObject);
begin
  Inc(FSelChanges);
end;

procedure TAudit8CTests.CompareByLength(Sender: TObject; Node1, Node2: TPPGTreeNode;
  var Compare: Integer);
begin
  Compare := Length(Node1.Text) - Length(Node2.Text);
end;

procedure TAudit8CTests.MeasureVar(Control: TWinControl; Index: Integer; var Height: Integer);
begin
  Height := 20 + (Index mod 3) * 7;
end;

procedure TAudit8CTests.CheckTree(TV: TPPGTreeView; const Context: string);
var
  Order: TList;
  K: Integer;
  N: TPPGTreeNode;

  procedure Walk(P: TPPGTreeNode; Count: Integer);
  var
    I: Integer;
    C, Prev, Next: TPPGTreeNode;
  begin
    for I := 0 to Count - 1 do
    begin
      if P = nil then
        C := TV.Items.Root(I)
      else
        C := P.Item[I];
      CheckEquals(I, C.Index, Context + ': Index von ' + C.Text);
      CheckTrue(C.Parent = P, Context + ': Parent von ' + C.Text);
      if I = 0 then
        Prev := nil
      else if P = nil then
        Prev := TV.Items.Root(I - 1)
      else
        Prev := P.Item[I - 1];
      if I = Count - 1 then
        Next := nil
      else if P = nil then
        Next := TV.Items.Root(I + 1)
      else
        Next := P.Item[I + 1];
      CheckTrue(C.GetPrevSibling = Prev, Context + ': PrevSibling von ' + C.Text);
      CheckTrue(C.GetNextSibling = Next, Context + ': NextSibling von ' + C.Text);
      if P <> nil then
        CheckEquals(I, P.IndexOf(C), Context + ': IndexOf von ' + C.Text);
      Order.Add(C);
      Walk(C, C.Count);
    end;
  end;

begin
  Order := TList.Create;
  try
    Walk(nil, TV.Items.RootCount);
    CheckEquals(Order.Count, TV.Items.Count, Context + ': Anzahl');
    for K := 0 to Order.Count - 1 do
      CheckTrue(TV.Items[K] = TPPGTreeNode(Order[K]), Context + ': Items[' + IntToStr(K) + ']');
    // Rueckwaerts und mit Spruengen (Cache des letzten Treffers)
    for K := Order.Count - 1 downto 0 do
      CheckTrue(TV.Items[K] = TPPGTreeNode(Order[K]), Context + ': Items rueckwaerts');
    N := TV.Items.GetFirstNode;
    K := 0;
    while N <> nil do
    begin
      CheckTrue(N = TPPGTreeNode(Order[K]), Context + ': GetNext ' + IntToStr(K));
      if K mod 7 = 0 then
        CheckEquals(K, N.AbsoluteIndex, Context + ': AbsoluteIndex');
      N := N.GetNext;
      Inc(K);
    end;
    CheckEquals(Order.Count, K, Context + ': GetNext-Kette');
    N := TV.Items.GetFirstNode;
    if N <> nil then
    begin
      // GetPrev rueckwaerts vom letzten Knoten
      N := TPPGTreeNode(Order[Order.Count - 1]);
      K := Order.Count - 1;
      while N <> nil do
      begin
        CheckTrue(N = TPPGTreeNode(Order[K]), Context + ': GetPrev ' + IntToStr(K));
        N := N.GetPrev;
        Dec(K);
      end;
      CheckEquals(-1, K, Context + ': GetPrev-Kette');
    end;
  finally
    Order.Free;
  end;
end;

{ 8d #4 }

procedure TAudit8CTests.TreeIndexAfterMutations;
var
  TV: TPPGTreeView;
  A, B, C, D, A0, A1, A2, X: TPPGTreeNode;
begin
  TV := NewTree;
  A := TV.Items.Add(nil, 'A');
  B := TV.Items.Add(nil, 'B');
  C := TV.Items.AddFirst(B, 'C');
  D := TV.Items.Insert(B, 'D');
  CheckTree(TV, 'Wurzeln');
  A1 := TV.Items.AddChild(A, 'A1');
  A0 := TV.Items.AddChildFirst(A, 'A0');
  A2 := TV.Items.AddChild(A, 'A2');
  TV.Items.Insert(A1, 'A05');
  TV.Items.Insert(A0, 'A00');
  CheckTree(TV, 'Kinder');
  TV.Items.Delete(A1);
  CheckTree(TV, 'Delete Mitte');
  B.MoveTo(A, naAddChild);
  CheckTree(TV, 'MoveTo AddChild');
  A0.MoveTo(C, naInsert);
  CheckTree(TV, 'MoveTo Insert');
  D.MoveTo(nil, naAdd);
  CheckTree(TV, 'MoveTo Wurzel');
  C.MoveTo(A2, naAddFirst);
  CheckTree(TV, 'MoveTo AddFirst');
  A2.MoveTo(A, naAddChildFirst);
  CheckTree(TV, 'MoveTo AddChildFirst');
  TV.Items.BeginUpdate;
  try
    X := TV.Items.AddChildFirst(nil, 'X');
    TV.Items.Insert(X, 'W');
    TV.Items.AddFirst(nil, 'V');
    A.Item[0].Delete;
  finally
    TV.Items.EndUpdate;
  end;
  CheckTree(TV, 'Update-Klammer');
  TV.AlphaSort(True);
  CheckTree(TV, 'AlphaSort');
  A.DeleteChildren;
  CheckTree(TV, 'DeleteChildren');
  TV.Items.Delete(A);
  CheckTree(TV, 'Delete Wurzel');
  TV.Items.Clear;
  CheckTree(TV, 'Clear');
  CheckEquals(0, TV.Items.Count);
end;

procedure TAudit8CTests.TreeItemsLoopMatchesWalk;
var
  TV: TPPGTreeView;
  I, J: Integer;
  R: TPPGTreeNode;
begin
  TV := NewTree;
  TV.Items.BeginUpdate;
  try
    for I := 0 to 99 do
    begin
      R := TV.Items.Add(nil, 'R' + IntToStr(I));
      for J := 0 to 2 do
        TV.Items.AddChild(R, 'C' + IntToStr(J));
    end;
  finally
    TV.Items.EndUpdate;
  end;
  CheckTree(TV, 'Aufbau');
  // Vorne einfuegen verschiebt alle Indizes
  TV.Items.AddFirst(nil, 'Erste');
  TV.Items.Insert(TV.Items.Root(50), 'Mitte');
  CheckTree(TV, 'Einfuegen');
  TV.Items.Root(0).Delete;
  TV.Items.Root(10).Delete;
  CheckTree(TV, 'Loeschen');
end;

{ 8d #3 }

procedure TAudit8CTests.AlphaSortStableWithMarkup;
const
  Texts: array[0..5] of string = ('c', '<b>b</b>', 'a', 'B', '<i>A</i>', 'b');
  Expected: array[0..5] of Integer = (2, 4, 1, 3, 5, 0);
var
  TV: TPPGTreeView;
  I: Integer;
  N, P: TPPGTreeNode;
begin
  TV := NewTree;
  for I := 0 to High(Texts) do
    TV.Items.AddObject(nil, Texts[I], Pointer(I));
  P := TV.Items.Root(0); // 'c'
  TV.Items.AddChild(P, 'z');
  TV.Items.AddChild(P, 'y');
  TV.AlphaSort(False);
  for I := 0 to High(Expected) do
  begin
    N := TV.Items.Root(I);
    CheckEquals(Expected[I], Integer(N.Data), 'Reihenfolge ' + IntToStr(I));
  end;
  CheckEquals('z', P.Item[0].Text, 'Recurse = False laesst Kinder');
  CheckTree(TV, 'Sortiert flach');
  TV.AlphaSort(True);
  CheckEquals('y', P.Item[0].Text, 'Recurse = True sortiert Kinder');
  CheckEquals('z', P.Item[1].Text);
  CheckTree(TV, 'Sortiert rekursiv');
end;

procedure TAudit8CTests.AlphaSortOnCompareStable;
const
  Texts: array[0..6] of string = ('ccc', 'a', 'bb', 'x', 'ddd', 'yy', 'e');
  Expected: array[0..6] of Integer = (1, 3, 6, 2, 5, 0, 4);
var
  TV: TPPGTreeView;
  I: Integer;
begin
  TV := NewTree;
  TV.OnCompare := CompareByLength;
  for I := 0 to High(Texts) do
    TV.Items.AddObject(nil, Texts[I], Pointer(I));
  TV.AlphaSort;
  for I := 0 to High(Expected) do
    CheckEquals(Expected[I], Integer(TV.Items.Root(I).Data), 'Reihenfolge ' + IntToStr(I));
  CheckTree(TV, 'OnCompare');
end;

{ 8d #5 }

procedure TAudit8CTests.AutoCheckWithoutUpdate;
var
  TV: TPPGTreeView;
  P, C1, C2, C3: TPPGTreeNode;
begin
  TV := NewTree;
  TV.CheckBoxes := True;
  P := TV.Items.Add(nil, 'P');
  C1 := TV.Items.AddChild(P, 'C1');
  C2 := TV.Items.AddChild(P, 'C2');
  CheckEquals(Ord(cbUnchecked), Ord(P.CheckState));
  C1.Checked := True;
  CheckEquals(Ord(cbGrayed), Ord(P.CheckState));
  C2.Checked := True;
  CheckEquals(Ord(cbChecked), Ord(P.CheckState));
  C3 := TV.Items.AddChild(P, 'C3');
  CheckEquals(Ord(cbGrayed), Ord(P.CheckState), 'neues Kind aus');
  C3.Delete;
  CheckEquals(Ord(cbChecked), Ord(P.CheckState), 'nach Delete');
  P.Checked := False;
  CheckFalse(C1.Checked);
  CheckFalse(C2.Checked);
  C1.Checked := True;
  C1.MoveTo(nil, naAdd);
  CheckEquals(Ord(cbUnchecked), Ord(P.CheckState), 'nach MoveTo');
  C1.MoveTo(P, naAddChild);
  CheckEquals(Ord(cbGrayed), Ord(P.CheckState), 'zurueck');
end;

procedure TAudit8CTests.AutoCheckInsideUpdate;
var
  TV: TPPGTreeView;
  Q, G, R: TPPGTreeNode;
  I: Integer;
begin
  TV := NewTree;
  TV.CheckBoxes := True;
  TV.Items.BeginUpdate;
  try
    Q := TV.Items.Add(nil, 'Q');
    for I := 0 to 4 do
      TV.Items.AddChild(Q, 'K' + IntToStr(I));
    CheckEquals(Ord(cbUnchecked), Ord(Q.CheckState), 'in der Klammer');
    Q.Item[0].Checked := True;
    CheckEquals(Ord(cbGrayed), Ord(Q.CheckState), 'gemischt in der Klammer');
    for I := 1 to 4 do
      Q.Item[I].Checked := True;
    CheckEquals(Ord(cbChecked), Ord(Q.CheckState), 'alle an in der Klammer');
    TV.Items.AddChild(Q, 'K5');
    CheckEquals(Ord(cbGrayed), Ord(Q.CheckState), 'neues Kind in der Klammer');
    // Enkel unter einem gesetzten Kind: Kind wird aus, Q bleibt gemischt
    G := TV.Items.AddChild(Q.Item[0], 'G');
    CheckEquals(Ord(cbUnchecked), Ord(Q.Item[0].CheckState), 'Kind mit Enkel');
    CheckFalse(G.Checked);
    // Explizit gesetzter Zustand nach dem Aufbau gilt
    R := TV.Items.Add(nil, 'R');
    TV.Items.AddChild(R, 'R1');
    TV.Items.AddChild(R, 'R2');
    R.Checked := True;
    CheckTrue(R.Item[0].Checked);
    CheckTrue(R.Item[1].Checked);
  finally
    TV.Items.EndUpdate;
  end;
  CheckEquals(Ord(cbGrayed), Ord(Q.CheckState), 'nach EndUpdate');
  CheckEquals(Ord(cbUnchecked), Ord(Q.Item[0].CheckState));
  CheckEquals(Ord(cbChecked), Ord(R.CheckState));
  // Geloeschte Eltern in der Klammer duerfen nichts hinterlassen
  TV.Items.BeginUpdate;
  try
    TV.Items.AddChild(R, 'R3');
    R.Delete;
  finally
    TV.Items.EndUpdate;
  end;
  CheckEquals(1, TV.Items.RootCount);
  CheckEquals(Ord(cbGrayed), Ord(Q.CheckState));
end;

{ 8d #6 }

procedure TAudit8CTests.TreeRowsAfterAddWithoutUpdate;
var
  TV: TPPGTreeView;
  R0, Last, C, C0, Z: TPPGTreeNode;
  I: Integer;
  NR: TRect;
begin
  TV := NewTree;
  R0 := TV.Items.Add(nil, 'R0');
  TV.Selected := R0;
  for I := 1 to 3 do
    TV.Items.Add(nil, 'R' + IntToStr(I));
  Last := TV.Items.Add(nil, 'R4');
  CheckEquals(5, TV.RowCount, 'RowCount');
  CheckEquals(5, TV.ItemCount, 'ItemCount');
  CheckEquals(4, TV.RowOfNode(Last), 'RowOfNode');
  CheckTrue(TV.NodeOfRow(4) = Last, 'NodeOfRow');
  CheckTrue(TV.Selected = R0, 'Selected');
  CheckEquals(0, TV.ItemIndex);
  C := TV.Items.AddChild(R0, 'C');
  CheckEquals(5, TV.RowCount, 'unter zugeklapptem Knoten');
  CheckEquals(-1, TV.RowOfNode(C));
  CheckFalse(C.IsVisible);
  R0.Expand(False);
  CheckEquals(6, TV.RowCount);
  CheckEquals(1, TV.RowOfNode(C));
  C0 := TV.Items.AddChildFirst(R0, 'C0');
  CheckEquals(2, TV.RowOfNode(C), 'sofort verschoben');
  CheckTrue(R0.GetNextVisible = C0, 'GetNextVisible');
  CheckTrue(C.GetPrevVisible = C0, 'GetPrevVisible');
  CheckTrue(C0.IsVisible);
  Z := TV.Items.Insert(R0, 'Z');
  CheckEquals(0, TV.RowOfNode(Z));
  CheckEquals(3, TV.RowOfNode(C));
  CheckTrue(TV.Selected = R0, 'Auswahl bleibt am Knoten');
  CheckEquals(1, TV.ItemIndex, 'ItemIndex folgt');
  CheckEquals(1, TV.Selection.ItemIndex, 'Selection folgt');
  CheckTrue(TV.Selection.Selected[1]);
  TV.Items.Add(nil, 'Neu');
  NR := TV.NodeRect(C);
  CheckFalse(IsRectEmpty(NR), 'NodeRect');
  TV.Items.AddFirst(nil, 'Ganz vorne');
  CheckTrue(TV.GetNodeAt(NR.Left + 4, (NR.Top + NR.Bottom) div 2) <> C,
    'GetNodeAt sieht die neue Zeile');
  NR := TV.NodeRect(C);
  CheckTrue(TV.GetNodeAt(NR.Left + 4, (NR.Top + NR.Bottom) div 2) = C, 'GetNodeAt');
  TV.Items.Add(nil, 'Ende');
  TV.ItemIndex := 0;
  CheckEquals('Ganz vorne', TV.Selected.Text, 'ItemIndex setzen');
  TV.Items.AddFirst(nil, 'Noch weiter vorne');
  CheckEquals('Ganz vorne', TV.Selected.Text);
  CheckEquals(1, TV.Selection.Focus, 'Fokus folgt');
  TV.Items.Add(nil, 'Oben');
  TV.Height := 60;
  TV.TopItem := TV.Items.Root(2);
  CheckTrue(TV.TopItem = TV.Items.Root(2), 'TopItem');
  Application.ProcessMessages;
  CheckEquals(TV.Items.RootCount + 2, TV.RowCount, 'nach den Nachrichten');
  RenderToBitmap(TV).Free;
  CheckEquals(0, FErrors.Count, 'Fehler beim Zeichnen');
end;

procedure TAudit8CTests.TreeSelectionFollowsInsertedRows;
var
  TV: TPPGTreeView;
  N: TPPGTreeNode;
  I: Integer;
begin
  TV := NewTree;
  TV.MultiSelect := True;
  for I := 0 to 9 do
    TV.Items.Add(nil, 'N' + IntToStr(I));
  TV.Items.Root(3).Selected := True;
  TV.Items.Root(7).Selected := True;
  TV.Items.AddFirst(nil, 'A');
  TV.Items.Insert(TV.Items.Root(6), 'B');
  CheckTrue(TV.Items.Root(4).Selected, 'N3 gewaehlt');
  CheckEquals('N3', TV.Items.Root(4).Text);
  N := TV.Items.Root(9);
  CheckEquals('N7', N.Text);
  CheckTrue(N.Selected, 'N7 gewaehlt');
  CheckEquals(2, TV.SelCount);
  CheckTrue(TV.Selection.Selected[4]);
  CheckTrue(TV.Selection.Selected[9]);
end;

procedure TAudit8CTests.TreeDeleteSelectedFiresChangeAtOnce;
var
  TV: TPPGTreeView;
  P: TPPGTreeNode;
  I: Integer;
begin
  TV := NewTree;
  TV.OnChange := TreeChange;
  P := TV.Items.Add(nil, 'P');
  for I := 0 to 4 do
    TV.Items.AddChild(P, 'K' + IntToStr(I));
  P.Expand(False);
  FChanges := 0;
  TV.Selected := P.Item[2];
  CheckEquals(1, FChanges, 'Selected im Code');
  for I := 0 to 3 do
    TV.Items.Add(nil, 'X' + IntToStr(I));
  CheckEquals(1, FChanges, 'Add aendert die Auswahl nicht');
  P.Item[2].Delete;
  CheckTrue(TV.Selected = nil, 'Auswahl sofort weg');
  CheckEquals(9, TV.RowCount);
  TV.Selected := P.Item[0];
  CheckEquals(2, FChanges);
  FChanges := 0;
  P.Collapse(False);
  CheckEquals(1, FChanges, 'Zuklappen meldet sofort');
  CheckTrue(TV.Selected = P);
end;

{ 8d #1 }

procedure TAudit8CTests.CheckAllItemsEx;
var
  L: TPPGCheckListBox;
  I: Integer;
begin
  L := TPPGCheckListBox.Create(FForm);
  L.Parent := FForm;
  for I := 0 to 19 do
    L.ItemsEx.Add('E' + IntToStr(I));
  L.ItemsEx[3].Enabled := False;
  L.ItemsEx[5].Checked := cbGrayed;
  L.ItemIndex := 4;
  L.CheckAll(cbChecked, False, False);
  for I := 0 to 19 do
    if I = 3 then
      CheckEquals(Ord(cbUnchecked), Ord(L.State[I]), 'gesperrt')
    else if I = 5 then
      CheckEquals(Ord(cbGrayed), Ord(L.State[I]), 'grau')
    else
      CheckEquals(Ord(cbChecked), Ord(L.State[I]), 'Eintrag ' + IntToStr(I));
  CheckEquals(4, L.ItemIndex, 'Auswahl bleibt');
  L.CheckAll(cbUnchecked);
  for I := 0 to 19 do
    CheckEquals(Ord(cbUnchecked), Ord(L.State[I]), 'alle aus ' + IntToStr(I));
  CheckEquals(20, L.ItemCount);
end;

procedure TAudit8CTests.CheckAllStringsSkipsHeaders;
var
  L: TPPGCheckListBox;
  I: Integer;
begin
  L := TPPGCheckListBox.Create(FForm);
  L.Parent := FForm;
  for I := 0 to 9 do
    L.Items.Add('S' + IntToStr(I));
  L.Header[2] := True;
  L.CheckAll(cbChecked);
  for I := 0 to 9 do
    CheckEquals(I <> 2, L.Checked[I], 'Eintrag ' + IntToStr(I));
end;

{ 8d #2 / #8 }

procedure TAudit8CTests.GroupLayoutHeights;
var
  L: TPPGListBox;
  I, H, GH, Big: Integer;
  R, Prev: TRect;
begin
  L := TPPGListBox.Create(FForm);
  L.Parent := FForm;
  L.SetBounds(0, 0, 200, 3000);
  for I := 0 to 29 do
    L.ItemsEx.Add('E' + IntToStr(I)).Group := 'G' + IntToStr(I div 10);
  H := TLBAccess(L).DefaultItemHeight;
  GH := TPPGItemPainter.GroupHeaderHeight(L.Font, L.ScalePPI);
  CheckEquals(TPPGItemPainter.RowHeight(L.Font, nil, False, L.ScalePPI), H);
  Prev := L.ItemRect(0);
  CheckEquals(H, Prev.Bottom - Prev.Top, 'Hoehe 0');
  for I := 1 to 29 do
  begin
    R := L.ItemRect(I);
    CheckEquals(H, R.Bottom - R.Top, 'Hoehe ' + IntToStr(I));
    if I mod 10 = 0 then
    begin
      CheckEquals(GH, R.Top - Prev.Bottom, 'Ueberschrift vor ' + IntToStr(I));
      CheckTrue(L.ItemStartsGroup(I));
    end
    else
    begin
      CheckEquals(0, R.Top - Prev.Bottom, 'Abstand ' + IntToStr(I));
      CheckFalse(L.ItemStartsGroup(I));
    end;
    Prev := R;
  end;
  // Neue Schrift: neue Hoehen (Zwischenspeicher je Schrift)
  L.Font.Size := L.Font.Size * 2;
  R := L.ItemRect(1);
  Big := R.Bottom - R.Top;
  CheckTrue(Big > H, 'groessere Schrift');
  CheckEquals(TPPGItemPainter.RowHeight(L.Font, nil, False, L.ScalePPI), Big);
end;

procedure TAudit8CTests.OwnerDrawVariableMeasureStillUsed;
var
  L: TPPGListBox;
  I: Integer;
  R: TRect;
begin
  L := TPPGListBox.Create(FForm);
  L.Parent := FForm;
  L.SetBounds(0, 0, 200, 3000);
  L.Style := lbOwnerDrawVariable;
  L.OnMeasureItem := MeasureVar;
  for I := 0 to 11 do
    L.ItemsEx.Add('E' + IntToStr(I)).Group := 'G' + IntToStr(I div 4);
  for I := 0 to 11 do
  begin
    R := L.ItemRect(I);
    CheckEquals(20 + (I mod 3) * 7, R.Bottom - R.Top, 'OnMeasureItem ' + IntToStr(I));
  end;
end;

procedure TAudit8CTests.TextLineHeightFollowsFont;
var
  F1, F2: TFont;
  H1, H2: Integer;
begin
  F1 := TFont.Create;
  F2 := TFont.Create;
  try
    F1.Name := 'Segoe UI';
    F1.Size := 9;
    H1 := TPPGItemPainter.TextLineHeight(F1);
    CheckEquals(PPGMeasureTextNoCanvas('Wg', F1, 0, False).cy, H1);
    F1.Size := 18;
    H2 := TPPGItemPainter.TextLineHeight(F1);
    CheckEquals(PPGMeasureTextNoCanvas('Wg', F1, 0, False).cy, H2);
    CheckTrue(H2 > H1, 'gleiches Objekt, neue Groesse');
    F1.Size := 9;
    CheckEquals(H1, TPPGItemPainter.TextLineHeight(F1));
    F2.Assign(F1);
    CheckEquals(H1, TPPGItemPainter.TextLineHeight(F2), 'anderes Objekt');
    F2.Name := 'Courier New';
    F2.Size := 30;
    CheckEquals(PPGMeasureTextNoCanvas('Wg', F2, 0, False).cy,
      TPPGItemPainter.TextLineHeight(F2), 'andere Schrift');
    F2.Style := [fsBold];
    CheckEquals(PPGMeasureTextNoCanvas('Wg', F2, 0, False).cy,
      TPPGItemPainter.TextLineHeight(F2), 'fett');
  finally
    F2.Free;
    F1.Free;
  end;
end;

procedure TAudit8CTests.ItemsExSingleChangesUpdateFlags;
var
  L: TPPGListBox;
  I, H1, H2: Integer;
  R: TRect;
begin
  L := TPPGListBox.Create(FForm);
  L.Parent := FForm;
  L.SetBounds(0, 0, 200, 1000);
  for I := 0 to 4 do
    L.ItemsEx.Add('E' + IntToStr(I));
  R := L.ItemRect(0);
  H1 := R.Bottom - R.Top;
  L.ItemsEx[2].Detail := 'Detail';
  R := L.ItemRect(0);
  H2 := R.Bottom - R.Top;
  CheckTrue(H2 > H1, 'Detailzeile');
  L.ItemsEx[4].Detail := 'Noch eins';
  L.ItemsEx[2].Detail := '';
  R := L.ItemRect(0);
  CheckEquals(H2, R.Bottom - R.Top, 'eine Detailzeile bleibt');
  L.ItemsEx[4].Detail := '';
  R := L.ItemRect(0);
  CheckEquals(H1, R.Bottom - R.Top, 'keine Detailzeile mehr');
  L.ItemsEx[3].Group := 'G';
  CheckTrue(L.ItemStartsGroup(3), 'Gruppe');
  L.ItemsEx[1].Group := 'H';
  L.ItemsEx[3].Group := '';
  CheckTrue(L.ItemStartsGroup(1), 'andere Gruppe bleibt');
  CheckFalse(L.ItemStartsGroup(3));
  L.ItemsEx[1].Group := '';
  CheckFalse(L.ItemStartsGroup(1), 'keine Gruppe');
  R := L.ItemRect(1);
  CheckEquals(H1, R.Bottom - R.Top);
  // Neuer Eintrag mit Gruppe/Detail
  L.ItemsEx.Add('Neu').Detail := 'd';
  R := L.ItemRect(0);
  CheckEquals(H2, R.Bottom - R.Top, 'Add mit Detail');
end;

procedure TAudit8CTests.ListBoxItemsExAddKeepsSelection;
var
  L: TPPGListBox;
  I: Integer;
begin
  L := TPPGListBox.Create(FForm);
  L.Parent := FForm;
  for I := 0 to 4 do
    L.ItemsEx.Add('E' + IntToStr(I));
  L.ItemIndex := 2;
  L.ItemsEx.Add('Neu');
  CheckEquals(6, L.ItemCount);
  CheckEquals(2, L.ItemIndex, 'Auswahl bleibt');
  L.ItemsEx.Insert(0).Text := 'Vorne';
  CheckEquals(7, L.ItemCount);
  CheckEquals('Vorne', L.ItemsEx[0].Text);
  L.ItemsEx.Delete(0);
  CheckEquals(6, L.ItemCount);
  CheckEquals(6, L.Selection.Count);
end;

{ 8d #7 }

procedure TAudit8CTests.MarkupLayoutFollowsBaseFont;
const
  S = 'a <b>fett</b> <i>kursiv</i> <u>unter</u> <a href="x">Link</a> Ende';
var
  ML, Fresh: TPPGMarkupLayout;
  F1, F2: TFont;
  S1, S2: TSize;
  L1: Integer;
begin
  ML := TPPGMarkupLayout.Create;
  Fresh := TPPGMarkupLayout.Create;
  F1 := TFont.Create;
  F2 := TFont.Create;
  try
    F1.Name := 'Segoe UI';
    F1.Size := 9;
    F2.Assign(F1);
    F2.Size := 16;
    ML.Layout(S, F1, nil, 0, False);
    S1 := ML.Size;
    ML.Layout(S, F2, nil, 0, False);
    S2 := ML.Size;
    CheckTrue(S2.cx > S1.cx, 'groessere Schrift');
    ML.Layout(S, F1, nil, 0, False);
    CheckEquals(S1.cx, ML.Size.cx, 'zurueck');
    CheckEquals(S1.cy, ML.Size.cy);
    // Dasselbe Font-Objekt, geaendert
    F1.Size := 16;
    ML.Layout(S, F1, nil, 0, False);
    CheckEquals(S2.cx, ML.Size.cx, 'Objekt geaendert');
    F1.Size := 9;
    F1.Style := [fsBold];
    ML.Layout(S, F1, nil, 0, False);
    Fresh.Layout(S, F1, nil, 0, False);
    CheckEquals(Fresh.Size.cx, ML.Size.cx, 'Grundstil fett');
    CheckTrue(ML.Size.cx > S1.cx);
    F1.Style := [];
    F1.Name := 'Courier New';
    ML.Layout(S, F1, nil, 0, False);
    Fresh.Free;
    Fresh := TPPGMarkupLayout.Create;
    Fresh.Layout(S, F1, nil, 0, False);
    CheckEquals(Fresh.Size.cx, ML.Size.cx, 'andere Schrift');
    // Umbruch
    ML.Layout(S, F1, nil, 60, True);
    L1 := ML.LineCount;
    Fresh.Layout(S, F1, nil, 60, True);
    CheckEquals(Fresh.LineCount, L1);
    CheckEquals(Fresh.Size.cy, ML.Size.cy);
    CheckTrue(L1 > 1);
    CheckEquals(1, ML.LinkCount);
  finally
    F2.Free;
    F1.Free;
    Fresh.Free;
    ML.Free;
  end;
end;

{ 8d #9 }

procedure TAudit8CTests.SelectionSingleItemIndex;
var
  S: TPPGSelection;
begin
  S := TPPGSelection.Create;
  try
    S.OnChange := SelChange;
    S.Count := 100;
    CheckEquals(-1, S.ItemIndex);
    S.Selected[50] := True;
    CheckEquals(50, S.ItemIndex);
    S.ItemsInserted(0, 3);
    CheckEquals(53, S.ItemIndex);
    S.ItemsInserted(60, 2);
    CheckEquals(53, S.ItemIndex);
    S.ItemsDeleted(0, 1);
    CheckEquals(52, S.ItemIndex);
    CheckEquals(104, S.Count);
    S.ItemsDeleted(52, 1);
    CheckEquals(-1, S.ItemIndex, 'geloescht');
    CheckEquals(0, S.SelCount);
    S.Selected[103 - 1] := True;
    CheckEquals(102, S.ItemIndex);
    S.Count := 50;
    CheckEquals(-1, S.ItemIndex, 'abgeschnitten');
    S.Count := 120;
    CheckEquals(-1, S.NextSelected(0), 'kein Geist');
    S.MoveTo(7, []);
    CheckEquals(7, S.ItemIndex);
    S.Click(9, []);
    CheckEquals(9, S.ItemIndex);
    CheckEquals(1, S.SelCount);
    S.Clear;
    CheckEquals(-1, S.ItemIndex);
    S.Selected[0] := True;
    S.ItemsInserted(0, 1);
    CheckEquals(1, S.ItemIndex);
    S.ItemsDeleted(0, 5);
    CheckEquals(-1, S.ItemIndex);
    S.Mode := smExtended;
    S.Focus := 4;
    CheckEquals(4, S.ItemIndex, 'Fokus im Mehrfachmodus');
  finally
    S.Free;
  end;
end;

procedure TAudit8CTests.SelectionInsertDeleteWithoutSelection;
var
  S: TPPGSelection;
  I: Integer;
begin
  S := TPPGSelection.Create;
  try
    S.Mode := smExtended;
    S.OnChange := SelChange;
    S.Count := 64;
    S.SelectRange(10, 20, False);
    S.Clear;
    FSelChanges := 0;
    for I := 0 to 9 do
      S.ItemsInserted(0, 1);
    CheckEquals(10, FSelChanges, 'je Einfuegen eine Meldung');
    CheckEquals(74, S.Count);
    CheckEquals(-1, S.NextSelected(0));
    for I := 0 to 9 do
      S.ItemsDeleted(0, 1);
    CheckEquals(64, S.Count);
    CheckEquals(-1, S.NextSelected(0));
    S.Count := 70;
    CheckEquals(-1, S.NextSelected(0), 'kein Geist nach Vergroessern');
    CheckEquals(0, S.SelCount);
    S.SelectRange(60, 69, False);
    CheckEquals(10, S.SelCount);
    S.ItemsInserted(0, 2);
    CheckEquals(62, S.NextSelected(0));
    S.ItemsDeleted(0, 2);
    CheckEquals(60, S.NextSelected(0));
    CheckEquals(10, S.SelCount);
  finally
    S.Free;
  end;
end;

procedure TAudit8CTests.SelectionSingleModeWithTwoSelected;
var
  S: TPPGSelection;
begin
  S := TPPGSelection.Create;
  try
    S.Count := 40;
    S.Selected[10] := True;
    S.Focus := 20;
    S.ToggleFocused;
    CheckEquals(2, S.SelCount, 'zwei gewaehlt im Single-Modus');
    CheckEquals(10, S.ItemIndex);
    S.Selected[10] := False;
    CheckEquals(20, S.ItemIndex);
    S.ItemsDeleted(0, 5);
    CheckEquals(15, S.ItemIndex);
    S.SelectRange(1, 3, True);
    CheckEquals(3, S.ItemIndex);
    S.ItemsInserted(2, 1);
    CheckEquals(4, S.ItemIndex);
    S.Selected[4] := False;
    CheckEquals(16, S.ItemIndex);
  finally
    S.Free;
  end;
end;

{ 8d #10 }

procedure TAudit8CTests.ComboItemsExAddUnsorted;
var
  CB: TPPGComboBox;
  It: TPPGItem;
begin
  CB := TPPGComboBox.Create(FForm);
  CB.Parent := FForm;
  CB.ItemsEx.Add('<b>Beta</b>');
  CB.ItemsEx.Add('Alpha');
  CB.ItemsEx.Add('Gamma');
  CheckEquals(3, CB.Items.Count);
  CheckEquals('Beta', CB.Items[0]);
  CheckEquals('Alpha', CB.Items[1]);
  CB.ItemIndex := 1;
  CheckEquals('Alpha', CB.Text);
  CB.ItemsEx.Add('Delta');
  CheckEquals(4, CB.Items.Count);
  CheckEquals('Delta', CB.Items[3]);
  CheckEquals(1, CB.ItemIndex, 'Auswahl bleibt');
  CheckEquals('Alpha', CB.Text);
  It := CB.ItemsEx.Add;
  It.Text := '<i>Eps</i>';
  CheckEquals('Eps', CB.Items[4]);
  CB.ItemsEx[0].Text := 'Beta2';
  CheckEquals('Beta2', CB.Items[0]);
  CB.ItemsEx.Insert(0).Text := 'Null';
  CheckEquals('Null', CB.Items[0]);
  CheckEquals(6, CB.Items.Count);
  CheckEquals('Alpha', CB.Text);
  CheckEquals(2, CB.ItemIndex, 'Auswahl findet den Eintrag wieder');
end;

procedure TAudit8CTests.ComboItemsExAddSorted;
const
  Texts: array[0..4] of string = ('d', 'b', 'a', 'c', 'B');
  Expected: array[0..4] of Integer = (2, 1, 4, 3, 0);
var
  CB: TPPGComboBox;
  It: TPPGItem;
  I: Integer;
begin
  CB := TPPGComboBox.Create(FForm);
  CB.Parent := FForm;
  CB.Sorted := True;
  for I := 0 to High(Texts) do
    CB.ItemsEx.Add(Texts[I]).Tag := I;
  CheckEquals(5, CB.Items.Count);
  for I := 0 to High(Expected) do
  begin
    CheckEquals(Expected[I], CB.ItemsEx[I].Tag, 'Reihenfolge ' + IntToStr(I));
    CheckEquals(PPGStripMarkup(CB.ItemsEx[I].Text), CB.Items[I], 'Items ' + IntToStr(I));
  end;
  CB.ItemIndex := 3;
  CheckEquals('c', CB.Text);
  CB.ItemsEx.Add('<b>a2</b>');
  CheckEquals('a2', CB.Items[1]);
  CheckEquals('<b>a2</b>', CB.ItemsEx[1].Text);
  CheckEquals(4, CB.ItemIndex, 'Auswahl folgt dem Eintrag');
  CheckEquals('c', CB.Text);
  CB.ItemsEx.Add('zz');
  CheckEquals('zz', CB.Items[6]);
  It := CB.ItemsEx.Add;
  It.Text := 'bb';
  CheckEquals(8, CB.Items.Count);
  for I := 0 to CB.Items.Count - 1 do
    CheckEquals(PPGStripMarkup(CB.ItemsEx[I].Text), CB.Items[I], 'Abgleich ' + IntToStr(I));
  for I := 1 to CB.Items.Count - 1 do
    CheckTrue(AnsiCompareText(CB.Items[I - 1], CB.Items[I]) <= 0, 'sortiert ' + IntToStr(I));
  CheckEquals('c', CB.Text);
  CheckEquals('c', CB.Items[CB.ItemIndex]);
end;

procedure TAudit8CTests.ComboItemsExReplacesStrings;
var
  CB: TPPGComboBox;
begin
  CB := TPPGComboBox.Create(FForm);
  CB.Parent := FForm;
  CB.Items.Add('x');
  CB.Items.Add('y');
  CB.ItemsEx.Add('z');
  CheckEquals(1, CB.Items.Count, 'ItemsEx uebernimmt');
  CheckEquals('z', CB.Items[0]);
  CB.ItemsEx.Add('w');
  CheckEquals(2, CB.Items.Count);
  CheckEquals('w', CB.Items[1]);
  CB.ItemsEx.Clear;
  CheckEquals(0, CB.Items.Count);
end;

{ Zaehltests }

procedure TAudit8CTests.CountTreeRebuildsWithoutUpdate;
var
  TV: TCountingTree;
  I: Integer;
begin
  TV := TCountingTree.Create(FForm);
  TV.Parent := FForm;
  TV.Resets := 0;
  for I := 0 to 49 do
    TV.Items.Add(nil, 'N' + IntToStr(I));
  CheckEquals(50, TV.RowCount);
  CheckTrue(TV.Resets <= 1, 'Neuaufbauten: ' + IntToStr(TV.Resets));
end;

procedure TAudit8CTests.CountDefaultHeightInGroupLayout;
var
  L: TCountingListBox;
  I: Integer;
begin
  L := TCountingListBox.Create(FForm);
  L.Parent := FForm;
  L.ItemsEx.BeginUpdate;
  try
    for I := 0 to 499 do
      L.ItemsEx.Add('E' + IntToStr(I)).Group := 'G' + IntToStr(I div 50);
  finally
    L.ItemsEx.EndUpdate;
  end;
  L.Calls := 0;
  L.ItemRect(0);
  CheckTrue(L.Calls <= 2, 'Standardhoehe berechnet: ' + IntToStr(L.Calls));
end;

initialization
  RegisterTest('Audit8C', TAudit8CTests.Suite);

end.
