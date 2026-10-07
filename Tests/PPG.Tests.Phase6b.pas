unit PPG.Tests.Phase6b;

{$WARN SYMBOL_PLATFORM OFF}

{ Tests fuer Phase 6b: TPPGTreeView. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Vcl.ComCtrls,
  PPG.Types, PPG.Consts, PPG.Exceptions, PPG.Render.Registry, PPG.Accessibility,
  PPG.Controls.ItemList, PPG.TreeView, PPG.Tests.Controls;

type
  TTreeTests = class(TControlTestCase)
  private
    FChanges: Integer;
    FChangedNode: TPPGTreeNode;
    FDeletions: Integer;
    FAllow: Boolean;
    FChecked: Integer;
    FEdited: Integer;
    FDrops: Integer;
  protected
    procedure SetUp; override;
  private
    procedure OnChange(Sender: TObject; Node: TPPGTreeNode);
    procedure OnChanging(Sender: TObject; Node: TPPGTreeNode; var AllowChange: Boolean);
    procedure OnDeletion(Sender: TObject; Node: TPPGTreeNode);
    procedure OnExpandingRefuse(Sender: TObject; Node: TPPGTreeNode; var AllowExpansion: Boolean);
    procedure OnExpandingLazy(Sender: TObject; Node: TPPGTreeNode; var AllowExpansion: Boolean);
    procedure OnChecked(Sender: TObject; Node: TPPGTreeNode);
    procedure OnEdited(Sender: TObject; Node: TPPGTreeNode; var S: string);
    procedure OnEditingRefuse(Sender: TObject; Node: TPPGTreeNode; var AllowEdit: Boolean);
    procedure OnNodeDrop(Sender: TObject; Node, Target: TPPGTreeNode; Mode: TNodeAttachMode;
      var Allow: Boolean);
    procedure OnCompareReverse(Sender: TObject; Node1, Node2: TPPGTreeNode; var Compare: Integer);
    function NewTree: TPPGTreeView;
    /// Wurzel A (Kinder A1, A2 (Kind A2a)), Wurzel B (Kind B1)
    function SampleTree: TPPGTreeView;
    procedure Key(T: TPPGTreeView; VK: Word; Shift: TShiftState = []);
    procedure ClickAt(T: TPPGTreeView; X, Y: Integer);
    function Find(T: TPPGTreeView; const S: string): TPPGTreeNode;
  published
    procedure NodeApiLikeTTreeNodes;
    procedure DeleteFreesChildrenAndNotifies;
    procedure RowsFollowExpandAndCollapse;
    procedure SelectionStaysOnNode;
    procedure CollapseMovesSelectionToParent;
    procedure LazyLoadingOnExpanding;
    procedure ExpandCanBeRefused;
    procedure KeyboardLikeTreeView;
    procedure ClickOnExpanderTogglesWithoutSelecting;
    procedure ChangeAndChanging;
    procedure CheckBoxesPropagate;
    procedure RenameWithEditor;
    procedure RenameRespectsReadOnlyAndOnEditing;
    procedure DragNodeIntoAndBetween;
    procedure MoveIntoOwnChildRaises;
    procedure StreamingRoundTrip;
    procedure AlphaSortAndOnCompare;
    procedure Accessibility;
    procedure PaintAllPresetsAndModes;
    procedure HundredThousandNodes;
    procedure NoHandleOrMemoryLeaks;
  end;

implementation

uses
  Winapi.oleacc, PPG.Theme, PPG.Selection;

type
  TTreeAccess = class(TPPGTreeView);

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

function CenterOf(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

function ColorDist(A, B: TColor): Integer;
var
  CA, CB: Cardinal;
begin
  CA := ColorToRGB(A);
  CB := ColorToRGB(B);
  Result := Abs(GetRValue(CA) - GetRValue(CB)) + Abs(GetGValue(CA) - GetGValue(CB)) +
    Abs(GetBValue(CA) - GetBValue(CB));
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

{ TTreeTests }

procedure TTreeTests.SetUp;
begin
  inherited SetUp;
  // DUnit verwendet die Testobjekte wieder (Leak-Lauf: zwei Laeufe)
  FChanges := 0;
  FChangedNode := nil;
  FDeletions := 0;
  FAllow := False;
  FChecked := 0;
  FEdited := 0;
  FDrops := 0;
end;

procedure TTreeTests.OnChange(Sender: TObject; Node: TPPGTreeNode);
begin
  Inc(FChanges);
  FChangedNode := Node;
end;

procedure TTreeTests.OnChanging(Sender: TObject; Node: TPPGTreeNode; var AllowChange: Boolean);
begin
  AllowChange := FAllow;
end;

procedure TTreeTests.OnDeletion(Sender: TObject; Node: TPPGTreeNode);
begin
  Inc(FDeletions);
end;

procedure TTreeTests.OnExpandingRefuse(Sender: TObject; Node: TPPGTreeNode;
  var AllowExpansion: Boolean);
begin
  AllowExpansion := False;
end;

procedure TTreeTests.OnExpandingLazy(Sender: TObject; Node: TPPGTreeNode;
  var AllowExpansion: Boolean);
begin
  if (Node.Count = 0) and (Node.Text <> 'Leer') then
  begin
    TPPGTreeView(Sender).Items.AddChild(Node, 'Kind 1');
    TPPGTreeView(Sender).Items.AddChild(Node, 'Kind 2');
  end;
end;

procedure TTreeTests.OnChecked(Sender: TObject; Node: TPPGTreeNode);
begin
  Inc(FChecked);
end;

procedure TTreeTests.OnEdited(Sender: TObject; Node: TPPGTreeNode; var S: string);
begin
  Inc(FEdited);
  S := S + '!';
end;

procedure TTreeTests.OnEditingRefuse(Sender: TObject; Node: TPPGTreeNode; var AllowEdit: Boolean);
begin
  AllowEdit := False;
end;

procedure TTreeTests.OnNodeDrop(Sender: TObject; Node, Target: TPPGTreeNode;
  Mode: TNodeAttachMode; var Allow: Boolean);
begin
  Inc(FDrops);
  Allow := FAllow;
end;

procedure TTreeTests.OnCompareReverse(Sender: TObject; Node1, Node2: TPPGTreeNode;
  var Compare: Integer);
begin
  Compare := -CompareText(Node1.Text, Node2.Text);
end;

function TTreeTests.NewTree: TPPGTreeView;
begin
  Result := TPPGTreeView.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 220, 240);
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.OnChange := OnChange;
  Result.HandleNeeded;
  FAllow := True;
end;

function TTreeTests.SampleTree: TPPGTreeView;
var
  A, A2, B: TPPGTreeNode;
begin
  Result := NewTree;
  Result.Items.BeginUpdate;
  try
    A := Result.Items.Add(nil, 'A');
    Result.Items.AddChild(A, 'A1');
    A2 := Result.Items.AddChild(A, 'A2');
    Result.Items.AddChild(A2, 'A2a');
    B := Result.Items.Add(nil, 'B');
    Result.Items.AddChild(B, 'B1');
  finally
    Result.Items.EndUpdate;
  end;
end;

procedure TTreeTests.Key(T: TPPGTreeView; VK: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := VK;
  TTreeAccess(T).KeyDown(K, Shift);
end;

procedure TTreeTests.ClickAt(T: TPPGTreeView; X, Y: Integer);
begin
  T.Perform(WM_MOUSEMOVE, 0, MouseLParam(X, Y));
  T.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(X, Y));
  T.Perform(WM_LBUTTONUP, 0, MouseLParam(X, Y));
end;

function TTreeTests.Find(T: TPPGTreeView; const S: string): TPPGTreeNode;
var
  N: TPPGTreeNode;
begin
  N := T.Items.GetFirstNode;
  while N <> nil do
  begin
    if N.Text = S then
      Exit(N);
    N := N.GetNext;
  end;
  Result := nil;
end;

procedure TTreeTests.NodeApiLikeTTreeNodes;
var
  T: TPPGTreeView;
  A, B, X: TPPGTreeNode;
  I: Integer;
  S: string;
begin
  T := SampleTree;
  CheckEquals(6, T.Items.Count);
  A := Find(T, 'A');
  B := Find(T, 'B');
  CheckEquals(2, A.Count);
  CheckEquals('A2', A[1].Text);
  CheckEquals(2, Find(T, 'A2a').Level);
  CheckEquals(1, B.Index);
  CheckTrue(Find(T, 'A2a').HasAsParent(A));
  CheckTrue(Find(T, 'A1').Parent = A);
  CheckTrue(A.GetNextSibling = B);
  CheckTrue(B.GetPrevSibling = A);
  // Tiefensuche wie TTreeNodes.Item
  S := '';
  for I := 0 to T.Items.Count - 1 do
    S := S + T.Items[I].Text + ',';
  CheckEquals('A,A1,A2,A2a,B,B1,', S);
  CheckEquals(3, Find(T, 'A2a').AbsoluteIndex);
  CheckTrue(Find(T, 'B').GetPrev = Find(T, 'A2a'));
  X := T.Items.Insert(B, 'Zwischen');
  CheckEquals(1, X.Index, 'Insert vor dem Geschwister');
  X := T.Items.AddFirst(A, 'Erster');
  CheckEquals(0, X.Index);
  X := T.Items.AddChildFirst(A, 'Kind0');
  CheckEquals('Kind0', A[0].Text);
  CheckTrue(X.Parent = A);
  CheckEquals(9, T.Items.Count);
end;

procedure TTreeTests.DeleteFreesChildrenAndNotifies;
var
  T: TPPGTreeView;
begin
  T := SampleTree;
  T.OnDeletion := OnDeletion;
  Find(T, 'A').Delete;
  CheckEquals(4, FDeletions, 'A mit drei Nachfahren');
  CheckEquals(2, T.Items.Count);
  Find(T, 'B').DeleteChildren;
  CheckEquals(1, T.Items.Count);
  T.Items.Clear;
  CheckEquals(0, T.Items.Count);
  CheckEquals(0, T.RowCount);
end;

procedure TTreeTests.RowsFollowExpandAndCollapse;
var
  T: TPPGTreeView;
  A: TPPGTreeNode;
begin
  T := SampleTree;
  CheckEquals(2, T.RowCount, 'zugeklappt: nur Wurzeln');
  A := Find(T, 'A');
  CheckTrue(A.HasChildren);
  A.Expand(False);
  CheckEquals(4, T.RowCount);
  CheckEquals(1, T.RowOfNode(Find(T, 'A1')));
  CheckTrue(Find(T, 'A2a').IsVisible = False);
  A.Expand(True);
  CheckEquals(5, T.RowCount, 'rekursiv');
  A.Collapse(False);
  CheckEquals(2, T.RowCount);
  T.FullExpand;
  CheckEquals(6, T.RowCount);
  T.FullCollapse;
  CheckEquals(2, T.RowCount);
  CheckFalse(Find(T, 'A2').Expanded, 'FullCollapse rekursiv');
end;

procedure TTreeTests.SelectionStaysOnNode;
var
  T: TPPGTreeView;
  B: TPPGTreeNode;
begin
  T := SampleTree;
  B := Find(T, 'B');
  T.Selected := B;
  CheckEquals(1, T.ItemIndex);
  Find(T, 'A').Expand(False);
  CheckTrue(T.Selected = B, 'Zeilen verschieben sich, die Auswahl bleibt am Knoten');
  CheckEquals(3, T.ItemIndex);
  T.Items.AddChildFirst(Find(T, 'A'), 'Neu');
  CheckTrue(T.Selected = B);
end;

procedure TTreeTests.CollapseMovesSelectionToParent;
var
  T: TPPGTreeView;
  A: TPPGTreeNode;
begin
  T := SampleTree;
  A := Find(T, 'A');
  A.Expand(True);
  T.Selected := Find(T, 'A2a');
  FChanges := 0;
  A.Collapse(False);
  CheckTrue(T.Selected = A, 'Auswahl wandert zum sichtbaren Vorfahren');
  CheckEquals(1, FChanges, 'mit OnChange (wie TTreeView)');
end;

procedure TTreeTests.LazyLoadingOnExpanding;
var
  T: TPPGTreeView;
  N, E: TPPGTreeNode;
begin
  T := NewTree;
  T.OnExpanding := OnExpandingLazy;
  N := T.Items.Add(nil, 'Laufwerk');
  N.HasChildren := True;
  E := T.Items.Add(nil, 'Leer');
  E.HasChildren := True;
  CheckEquals(0, N.Count);
  CheckTrue(N.HasChildren, 'Pfeil ohne Kinder');
  N.Expand(False);
  CheckEquals(2, N.Count, 'OnExpanding hat Kinder angelegt');
  CheckTrue(N.Expanded);
  CheckEquals(4, T.RowCount);
  E.Expand(False);
  CheckFalse(E.Expanded);
  CheckFalse(E.HasChildren, 'nichts geliefert: Pfeil verschwindet');
end;

procedure TTreeTests.ExpandCanBeRefused;
var
  T: TPPGTreeView;
begin
  T := SampleTree;
  T.OnExpanding := OnExpandingRefuse;
  Find(T, 'A').Expand(False);
  CheckFalse(Find(T, 'A').Expanded);
  CheckEquals(2, T.RowCount);
end;

procedure TTreeTests.KeyboardLikeTreeView;
var
  T: TPPGTreeView;
  A: TPPGTreeNode;
begin
  T := SampleTree;
  A := Find(T, 'A');
  T.Selected := A;
  Key(T, VK_RIGHT);
  CheckTrue(A.Expanded, 'Rechts klappt auf');
  Key(T, VK_RIGHT);
  CheckTrue(T.Selected = Find(T, 'A1'), 'Rechts geht zum ersten Kind');
  Key(T, VK_LEFT);
  CheckTrue(T.Selected = A, 'Links geht zum Eltern-Knoten');
  Key(T, VK_LEFT);
  CheckFalse(A.Expanded, 'Links klappt zu');
  Key(T, VK_MULTIPLY);
  CheckTrue(Find(T, 'A2').Expanded, '* klappt alles darunter auf');
  Key(T, VK_SUBTRACT);
  CheckFalse(A.Expanded);
  Key(T, VK_ADD);
  CheckTrue(A.Expanded);
  Key(T, VK_DOWN);
  CheckTrue(T.Selected = Find(T, 'A1'));
end;

procedure TTreeTests.ClickOnExpanderTogglesWithoutSelecting;
var
  T: TPPGTreeView;
  R: TRect;
  X: Integer;
begin
  FForm.Show;
  try
    T := SampleTree;
    T.Selected := Find(T, 'B');
    FChanges := 0;
    R := T.NodeRect(Find(T, 'A'));
    // Pfeil der Wurzel: erste Spalte (6 px Rand + halbe Einzugbreite)
    X := R.Left + 6 + 9;
    ClickAt(T, X, (R.Top + R.Bottom) div 2);
    CheckTrue(Find(T, 'A').Expanded, 'Klick auf den Pfeil klappt auf');
    CheckTrue(T.Selected = Find(T, 'B'), 'Auswahl bleibt');
    CheckEquals(0, FChanges);
    R := T.NodeRect(Find(T, 'A1'));
    ClickAt(T, R.Right - 20, (R.Top + R.Bottom) div 2);
    CheckTrue(T.Selected = Find(T, 'A1'), 'Klick auf den Text waehlt');
    CheckEquals(1, FChanges);
  finally
    FForm.Hide;
  end;
end;

procedure TTreeTests.ChangeAndChanging;
var
  T: TPPGTreeView;
begin
  T := SampleTree;
  T.Selected := Find(T, 'B');
  CheckEquals(1, FChanges, 'Selected im Code loest OnChange aus (wie TTreeView)');
  CheckTrue(FChangedNode = Find(T, 'B'));
  T.Selected := Find(T, 'B');
  CheckEquals(1, FChanges, 'gleicher Knoten: kein Ereignis');
  T.OnChanging := OnChanging;
  FAllow := False;
  Key(T, VK_UP);
  CheckTrue(T.Selected = Find(T, 'B'), 'OnChanging verhindert den Wechsel');
  FAllow := True;
  Key(T, VK_UP);
  CheckTrue(T.Selected = Find(T, 'A'));
  CheckEquals(2, FChanges);
end;

procedure TTreeTests.CheckBoxesPropagate;
var
  T: TPPGTreeView;
  A: TPPGTreeNode;
begin
  T := SampleTree;
  T.CheckBoxes := True;
  T.OnChecked := OnChecked;
  A := Find(T, 'A');
  A.Checked := True;
  CheckTrue(Find(T, 'A1').Checked, 'an Kinder weitergegeben');
  CheckTrue(Find(T, 'A2a').Checked, 'auch an Enkel');
  Find(T, 'A1').Checked := False;
  CheckTrue(A.CheckState = cbGrayed, 'Eltern gemischt');
  Find(T, 'A1').Checked := True;
  CheckTrue(A.CheckState = cbChecked, 'alle an -> an');
  T.Items.AddChild(A, 'Neu');
  CheckTrue(A.CheckState = cbGrayed, 'neues leeres Kind -> gemischt');
  Find(T, 'Neu').Delete;
  CheckTrue(A.CheckState = cbChecked, 'nach dem Loeschen wieder an');
  CheckEquals(0, FChecked, 'Code loest kein OnChecked aus');
  T.Selected := Find(T, 'B');
  Key(T, VK_SPACE);
  CheckTrue(Find(T, 'B').Checked);
  CheckTrue(Find(T, 'B1').Checked);
  CheckEquals(1, FChecked, 'Leertaste: OnChecked');
  T.AutoCheck := False;
  Find(T, 'B').Checked := False;
  CheckTrue(Find(T, 'B1').Checked, 'ohne AutoCheck keine Weitergabe');
end;

procedure TTreeTests.RenameWithEditor;
var
  T: TPPGTreeView;
  A: TPPGTreeNode;
begin
  FForm.Show;
  try
    T := SampleTree;
    T.OnEdited := OnEdited;
    A := Find(T, 'A');
    T.Selected := A;
    T.SetFocus;
    Key(T, VK_F2);
    CheckTrue(T.IsEditing, 'F2 startet das Umbenennen');
    CheckTrue(T.Editor.Visible);
    CheckEquals('A', T.Editor.Text);
    T.Editor.Text := 'Alpha';
    T.Editor.Perform(WM_KEYDOWN, VK_RETURN, 0);
    CheckFalse(T.IsEditing);
    CheckEquals('Alpha!', A.Text, 'OnEdited darf den Text aendern');
    CheckEquals(1, FEdited);
    CheckTrue(A.EditText);
    T.Editor.Text := 'Verworfen';
    T.Editor.Perform(WM_KEYDOWN, VK_ESCAPE, 0);
    CheckEquals('Alpha!', A.Text, 'Esc verwirft');
    CheckEquals(1, FEdited);
    CheckTrue(A.EditText);
    T.Editor.Text := 'Gescrollt';
    T.ScrollBy(0, 10);
    T.EndEdit(True); // falls nicht scrollbar: Uebernahme explizit
    CheckFalse(T.IsEditing);
  finally
    FForm.Hide;
  end;
end;

procedure TTreeTests.RenameRespectsReadOnlyAndOnEditing;
var
  T: TPPGTreeView;
begin
  FForm.Show;
  try
    T := SampleTree;
    T.ReadOnly := True;
    CheckFalse(Find(T, 'A').EditText, 'ReadOnly');
    T.ReadOnly := False;
    T.OnEditing := OnEditingRefuse;
    CheckFalse(Find(T, 'A').EditText, 'OnEditing lehnt ab');
    CheckFalse(T.IsEditing);
  finally
    FForm.Hide;
  end;
end;

procedure TTreeTests.DragNodeIntoAndBetween;
var
  T: TPPGTreeView;
  P0, P1: TPoint;
  R: TRect;
  B1: TPPGTreeNode;
begin
  FForm.Show;
  try
    T := SampleTree;
    T.AllowReorder := True;
    T.OnNodeDrop := OnNodeDrop;
    T.FullExpand;
    // B1 in die Mitte von A1 ziehen: wird Kind von A1
    B1 := Find(T, 'B1');
    P0 := CenterOf(T.NodeRect(B1));
    R := T.NodeRect(Find(T, 'A1'));
    P1 := CenterOf(R);
    T.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P0.X, P0.Y));
    T.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P0.X, P0.Y - 20));
    T.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P1.X, P1.Y));
    CheckTrue(T.DropInside, 'Mitte: hinein');
    T.Perform(WM_LBUTTONUP, 0, MouseLParam(P1.X, P1.Y));
    CheckEquals(1, FDrops);
    CheckTrue(B1.Parent = Find(T, 'A1'), 'B1 ist jetzt Kind von A1');
    CheckTrue(T.Selected = B1);
    // A2 an den oberen Rand von A ziehen: davor (Wurzelebene)
    P0 := CenterOf(T.NodeRect(Find(T, 'A2')));
    R := T.NodeRect(Find(T, 'A'));
    P1 := Point(P0.X, R.Top + 1);
    T.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P0.X, P0.Y));
    T.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P0.X, P0.Y - 20));
    T.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P1.X, P1.Y));
    CheckFalse(T.DropInside, 'oberes Viertel: davor');
    T.Perform(WM_LBUTTONUP, 0, MouseLParam(P1.X, P1.Y));
    CheckTrue(Find(T, 'A2').Parent = nil, 'A2 ist Wurzel');
    CheckEquals(0, Find(T, 'A2').Index);
    // A in das eigene Kind A1 ziehen: abgelehnt
    FDrops := 0;
    P0 := CenterOf(T.NodeRect(Find(T, 'A')));
    P1 := CenterOf(T.NodeRect(Find(T, 'A1')));
    T.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P0.X, P0.Y));
    T.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P0.X, P0.Y + 20));
    T.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P1.X, P1.Y));
    T.Perform(WM_LBUTTONUP, 0, MouseLParam(P1.X, P1.Y));
    CheckEquals(0, FDrops, 'nicht in die eigenen Kinder');
    CheckTrue(Find(T, 'A1').Parent = Find(T, 'A'));
  finally
    FForm.Hide;
  end;
end;

procedure TTreeTests.MoveIntoOwnChildRaises;
var
  T: TPPGTreeView;
begin
  T := SampleTree;
  try
    Find(T, 'A').MoveTo(Find(T, 'A2a'), naAddChild);
    Fail('MoveTo in die eigenen Kinder muss werfen');
  except
    on E: EPPGError do
      CheckTrue(Find(T, 'A').Parent = nil, 'unveraendert');
  end;
  Find(T, 'B1').MoveTo(Find(T, 'A'), naAddChildFirst);
  CheckTrue(Find(T, 'A')[0] = Find(T, 'B1'));
end;

procedure TTreeTests.StreamingRoundTrip;
var
  T, T2: TPPGTreeView;
  S: TMemoryStream;
  N: TPPGTreeNode;
begin
  T := SampleTree;
  N := Find(T, 'A1');
  N.Text := 'Mit | Strich' + #13#10 + 'und Zeile \ Ende';
  N.Detail := 'Detail';
  N.Badge := '7';
  N.ImageIndex := 2;
  N.SelectedIndex := 3;
  N.Enabled := False;
  Find(T, 'A').Expand(False);
  Find(T, 'B1').HasChildren := True;
  S := TMemoryStream.Create;
  try
    S.WriteComponent(T);
    S.Position := 0;
    T2 := TPPGTreeView.Create(nil);
    try
      S.ReadComponent(T2);
      T2.Parent := FForm;
      CheckEquals(6, T2.Items.Count);
      N := T2.Items[1];
      CheckEquals('Mit | Strich' + #13#10 + 'und Zeile \ Ende', N.Text);
      CheckEquals('Detail', N.Detail);
      CheckEquals('7', N.Badge);
      CheckEquals(2, N.ImageIndex);
      CheckEquals(3, N.SelectedIndex);
      CheckFalse(N.Enabled);
      CheckTrue(T2.Items[0].Expanded, 'Aufklapp-Zustand gespeichert');
      CheckEquals(2, T2.Items[3].Level);
      CheckTrue(T2.Items[5].HasChildren, 'HasChildren gespeichert');
      CheckEquals(4, T2.RowCount);
    finally
      T2.Free;
    end;
  finally
    S.Free;
  end;
end;

procedure TTreeTests.AlphaSortAndOnCompare;
var
  T: TPPGTreeView;
  R: TPPGTreeNode;
begin
  T := NewTree;
  R := T.Items.Add(nil, 'Wurzel');
  T.Items.AddChild(R, 'c');
  T.Items.AddChild(R, 'a');
  T.Items.AddChild(R, 'b');
  T.Items.Add(nil, 'Anfang');
  T.AlphaSort;
  CheckEquals('Anfang', T.Items.Root(0).Text);
  R := Find(T, 'Wurzel');
  CheckEquals('a', R[0].Text);
  CheckEquals('c', R[2].Text);
  T.OnCompare := OnCompareReverse;
  T.AlphaSort;
  CheckEquals('c', R[0].Text, 'OnCompare bestimmt die Reihenfolge');
end;

procedure TTreeTests.Accessibility;
var
  T: TPPGTreeView;
  A: IPPGAccessibleChildren;
begin
  T := SampleTree;
  CheckTrue(Supports(T, IPPGAccessibleChildren, A));
  CheckEquals(ROLE_SYSTEM_OUTLINE, TTreeAccess(T).AccRole);
  CheckEquals(ROLE_SYSTEM_OUTLINEITEM, A.AccChildRole(1));
  CheckTrue(A.AccChildState(1) and STATE_SYSTEM_COLLAPSED <> 0);
  CheckEquals(SPPGAccExpand, A.AccChildDefaultAction(1));
  Find(T, 'A').Expand(False);
  CheckTrue(A.AccChildState(1) and STATE_SYSTEM_EXPANDED <> 0);
  CheckEquals(SPPGAccCollapse, A.AccChildDefaultAction(1));
  CheckEquals('A1', A.AccChildName(2));
  CheckEquals(4, A.AccChildCount);
end;

procedure TTreeTests.PaintAllPresetsAndModes;
var
  Names: TStringList;
  P: Integer;
  Dark, Gdi: Boolean;
  T: TPPGTreeView;
  Bmp: TBitmap;
  R: TRect;
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
            T := SampleTree;
            T.Preset := Names[P];
            T.CheckBoxes := True;
            T.ShowLines := True;
            T.FullExpand;
            T.Selected := Find(T, 'A2');
            T.SetFocus;
            Bmp := RenderToBitmap(T);
            try
              R := T.NodeRect(Find(T, 'A2'));
              CheckTrue(ColorDist(Bmp.Canvas.Pixels[R.Right - 12, (R.Top + R.Bottom) div 2],
                Bmp.Canvas.Pixels[R.Right - 12, T.NodeRect(Find(T, 'B1')).Bottom + 6]) > 6,
                Names[P] + ': Auswahl sichtbar');
            finally
              Bmp.Free;
            end;
            T.Free;
          end;
    finally
      FForm.Hide;
      TPPGTheme.Mode := tmLight;
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  finally
    Names.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TTreeTests.HundredThousandNodes;
var
  T: TPPGTreeView;
  Tick: Cardinal;
  I, J: Integer;
  R: TPPGTreeNode;
  Bmp: TBitmap;
begin
  FForm.Show;
  try
    T := NewTree;
    Tick := GetTickCount;
    T.Items.BeginUpdate;
    try
      for I := 0 to 99 do
      begin
        R := T.Items.Add(nil, 'Gruppe ' + IntToStr(I));
        for J := 0 to 999 do
          T.Items.AddChild(R, 'Knoten ' + IntToStr(J));
      end;
    finally
      T.Items.EndUpdate;
    end;
    T.FullExpand;
    T.Selected := T.Items[T.Items.Count - 1];
    Bmp := RenderToBitmap(T);
    Bmp.Free;
    CheckEquals(100100, T.RowCount);
    CheckTrue(GetTickCount - Tick < 2000, Format('100 000 Knoten: %d ms', [GetTickCount - Tick]));
    T.Items.Clear;
    CheckEquals(0, T.RowCount);
  finally
    FForm.Hide;
  end;
end;

procedure TTreeTests.NoHandleOrMemoryLeaks;

  procedure Cycle;
  var
    I: Integer;
    T: TPPGTreeView;
  begin
    for I := 1 to 10 do
    begin
      T := SampleTree;
      T.CheckBoxes := True;
      T.FullExpand;
      T.Selected := Find(T, 'A2a');
      RenderToBitmap(T).Free;
      T.Free;
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
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_USEROBJECTS) <= User0 + 2, 'USER-Handles wachsen');
    CheckTrue(M1 <= M0 + 2048, Format('Speicher waechst: %d -> %d', [M0, M1]));
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterClass(TPPGTreeView);
  RegisterTest('Phase6b', TTreeTests.Suite);

end.
