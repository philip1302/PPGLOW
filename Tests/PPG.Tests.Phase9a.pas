unit PPG.Tests.Phase9a;

{ Tests fuer Phase 9a: Logik und Dialoge der Designer-Editoren
  (PPG.Editors.Logic, PPG.Editors.Forms). Die IDE-Anbindung (PPG.Reg) ist
  bewusst duenn und nur im Designer pruefbar. }

interface

uses
  TestFramework, System.Classes, System.SysUtils, Vcl.Controls, Vcl.Forms, Vcl.Graphics,
  Vcl.StdCtrls, Vcl.ComCtrls,
  PPG.Types, PPG.Consts, PPG.Exceptions, PPG.Appearance, PPG.Controls.Base,
  PPG.Button, PPG.CheckBox, PPG.StyleManager, PPG.NavigationView, PPG.TreeView,
  PPG.Editors.Logic, PPG.Editors.Forms, PPG.Tests.Controls;

type
  TPresetTargetTests = class(TControlTestCase)
  published
    procedure CollectFindsControlsAndManagers;
    procedure ApplySkipsStyleManagerClients;
    procedure ApplyUnknownPresetChangesNothing;
  end;

  TStructureOpsTests = class(TControlTestCase)
  private
    function NewNav: TPPGNavigationView;
    function NewTree: TPPGTreeView;
  published
    procedure NavIndentOutdentAndMove;
    procedure NavIndentNeedsItemAbove;
    procedure NavAddAfterAndChild;
    procedure TreeIndentOutdentAndMove;
  end;

  TAppearanceSessionTests = class(TControlTestCase)
  published
    procedure WorksOnCopyUntilApply;
    procedure ResetToPresetRestoresDefaults;
    procedure NilTargetRaises;
  end;

  TEditorDialogTests = class(TControlTestCase)
  published
    procedure AppearanceDialogEditsCopyAndPreview;
    procedure AppearanceDialogStateSwitchLoadsValues;
    procedure GalleryListsPresetsAndPicksMostUsed;
    procedure NavItemsDialogWorksOnCopy;
    procedure TreeItemsDialogWorksOnCopy;
    procedure DialogsFreeWithoutLeaks;
  end;

implementation

uses
  PPG.Render.Registry;

{ TPresetTargetTests }

procedure TPresetTargetTests.CollectFindsControlsAndManagers;
var
  B: TPPGButton;
  M: TPPGStyleManager;
  Plain: TComponent;
begin
  B := NewButton('A');
  M := TPPGStyleManager.Create(FForm);
  Plain := TComponent.Create(FForm);
  CheckEquals(2, TPPGPresetTargets.Collect(FForm, nil), 'Anzahl ohne Liste');
  CheckTrue(TPPGPresetTargets.HasPreset(B));
  CheckTrue(TPPGPresetTargets.HasPreset(M));
  CheckFalse(TPPGPresetTargets.HasPreset(Plain));
  CheckEquals(0, TPPGPresetTargets.Collect(nil, nil), 'nil-Root');
end;

procedure TPresetTargetTests.ApplySkipsStyleManagerClients;
var
  B: TPPGButton;
  C: TPPGCheckBox;
  M: TPPGStyleManager;
  N: Integer;
begin
  B := NewButton('A');
  B.Preset := PPGPresetModernFlat;
  M := TPPGStyleManager.Create(FForm);
  M.Preset := PPGPresetModernFlat;
  C := TPPGCheckBox.Create(FForm);
  C.Parent := FForm;
  C.StyleManager := M;
  N := TPPGPresetTargets.Apply(FForm, PPGPresetClassic);
  CheckEquals(2, N, 'Button und Manager, nicht der Manager-Kunde');
  CheckEquals(PPGPresetClassic, B.Preset);
  CheckEquals(PPGPresetClassic, M.Preset);
  // Der Kunde folgt seinem Manager
  CheckEquals(PPGPresetClassic, C.Preset);
  // Zweiter Lauf aendert nichts mehr
  CheckEquals(0, TPPGPresetTargets.Apply(FForm, PPGPresetClassic));
end;

procedure TPresetTargetTests.ApplyUnknownPresetChangesNothing;
var
  B: TPPGButton;
  Raised: Boolean;
begin
  B := NewButton('A');
  B.Preset := PPGPresetModernFlat;
  Raised := False;
  try
    TPPGPresetTargets.Apply(FForm, 'GibtEsNicht');
  except
    on E: EPPGPropertyError do
      Raised := True;
  end;
  CheckTrue(Raised, 'EPPGPropertyError erwartet');
  CheckEquals(PPGPresetModernFlat, B.Preset, 'unveraendert');
end;

{ TStructureOpsTests }

function TStructureOpsTests.NewNav: TPPGNavigationView;
begin
  Result := TPPGNavigationView.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 240, 300);
  Result.Items.AddItem('A');
  Result.Items.AddItem('B');
  Result.Items.AddItem('C');
end;

function TStructureOpsTests.NewTree: TPPGTreeView;
begin
  Result := TPPGTreeView.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 240, 300);
  Result.Items.Add(nil, 'A');
  Result.Items.Add(nil, 'B');
  Result.Items.Add(nil, 'C');
end;

procedure TStructureOpsTests.NavIndentOutdentAndMove;
var
  Nav: TPPGNavigationView;
  A, B, C: TPPGNavItem;
begin
  Nav := NewNav;
  A := Nav.Items[0];
  B := Nav.Items[1];
  C := Nav.Items[2];
  CheckTrue(TPPGNavItemOps.Indent(B));
  CheckEquals(2, Nav.Items.Count);
  CheckTrue(B.ParentItem = A, 'B ist Kind von A');
  CheckTrue(A.Expanded, 'Elterneintrag aufgeklappt');
  CheckEquals(1, B.Level);
  CheckTrue(TPPGNavItemOps.Outdent(B));
  CheckTrue(B.ParentItem = nil);
  CheckEquals(1, B.Index, 'direkt hinter dem frueheren Eltern');
  CheckFalse(TPPGNavItemOps.Outdent(B), 'oberste Ebene');
  CheckTrue(TPPGNavItemOps.Move(C, -1));
  CheckEquals(1, C.Index);
  CheckFalse(TPPGNavItemOps.Move(A, -1), 'erster Eintrag');
  CheckFalse(TPPGNavItemOps.Move(Nav.Items[2], 1), 'letzter Eintrag');
  CheckFalse(TPPGNavItemOps.Move(A, 0));
  CheckFalse(TPPGNavItemOps.Indent(nil));
end;

procedure TStructureOpsTests.NavIndentNeedsItemAbove;
var
  Nav: TPPGNavigationView;
  H, X: TPPGNavItem;
begin
  Nav := NewNav;
  CheckFalse(TPPGNavItemOps.Indent(Nav.Items[0]), 'erster Eintrag');
  H := Nav.Items.AddHeader('Kopf');
  X := Nav.Items.AddItem('X');
  CheckFalse(TPPGNavItemOps.Indent(X), 'unter eine Kopfzeile geht nicht');
  CheckTrue(X.ParentItem = nil);
  CheckEquals(H.Index + 1, X.Index);
end;

procedure TStructureOpsTests.NavAddAfterAndChild;
var
  Nav: TPPGNavigationView;
  N, Child: TPPGNavItem;
begin
  Nav := NewNav;
  N := TPPGNavItemOps.AddAfter(Nav, Nav.Items[0], nikItem, 'Neu');
  CheckEquals(1, N.Index, 'hinter A');
  CheckEquals('Neu', N.Caption);
  N := TPPGNavItemOps.AddAfter(Nav, nil, nikSeparator, '');
  CheckEquals(Nav.Items.Count - 1, N.Index, 'ohne Bezug am Ende');
  CheckTrue(N.Kind = nikSeparator);
  Child := TPPGNavItemOps.AddChild(Nav.Items[0], 'Kind');
  CheckNotNull(Child);
  CheckTrue(Child.ParentItem = Nav.Items[0]);
  CheckNull(TPPGNavItemOps.AddChild(N, 'x'), 'Trenner hat keine Kinder');
end;

procedure TStructureOpsTests.TreeIndentOutdentAndMove;
var
  T: TPPGTreeView;
  A, B, C: TPPGTreeNode;
begin
  T := NewTree;
  A := T.Items.Root(0);
  B := T.Items.Root(1);
  C := T.Items.Root(2);
  CheckFalse(TPPGTreeNodeOps.Indent(A), 'kein Geschwister davor');
  CheckTrue(TPPGTreeNodeOps.Indent(B));
  CheckTrue(B.Parent = A);
  CheckEquals(2, T.Items.RootCount);
  CheckTrue(TPPGTreeNodeOps.Outdent(B));
  CheckTrue(B.Parent = nil);
  CheckEquals(1, B.Index, 'hinter A');
  CheckTrue(TPPGTreeNodeOps.Move(C, -1));
  CheckEquals(1, C.Index);
  CheckTrue(TPPGTreeNodeOps.Move(C, 1));
  CheckEquals(2, C.Index);
  CheckFalse(TPPGTreeNodeOps.Move(C, 1), 'letzter Knoten');
  // Ausruecken des letzten Kindes eines letzten Knotens: wird letzter Knoten
  CheckTrue(TPPGTreeNodeOps.Indent(C));
  CheckTrue(TPPGTreeNodeOps.Outdent(C));
  CheckTrue(C.Parent = nil);
  CheckEquals(2, C.Index);
  CheckEquals(3, T.Items.Count, 'kein Knoten verloren');
end;

{ TAppearanceSessionTests }

procedure TAppearanceSessionTests.WorksOnCopyUntilApply;
var
  B: TPPGButton;
  S: TPPGAppearanceSession;
  Orig: TColor;
begin
  B := NewButton('A');
  Orig := B.Appearance.Normal.Color;
  S := TPPGAppearanceSession.Create(B);
  try
    CheckFalse(S.Modified, 'Kopie gleich Ziel');
    S.Work.Normal.Color := clRed;
    CheckTrue(S.Modified);
    CheckEquals(Orig, B.Appearance.Normal.Color, 'Ziel unveraendert');
    S.Apply;
    CheckEquals(clRed, B.Appearance.Normal.Color);
    CheckFalse(S.Modified);
  finally
    S.Free;
  end;
end;

procedure TAppearanceSessionTests.ResetToPresetRestoresDefaults;
var
  B: TPPGButton;
  S: TPPGAppearanceSession;
begin
  B := NewButton('A');
  B.ResetToPresetDefaults;
  S := TPPGAppearanceSession.Create(B);
  try
    S.Work.Rounding := 17;
    S.Work.Hot.TextColor := clLime;
    S.ResetToPreset;
    CheckFalse(S.Modified, 'wieder gleich den Preset-Werten');
  finally
    S.Free;
  end;
end;

procedure TAppearanceSessionTests.NilTargetRaises;
var
  Raised: Boolean;
begin
  Raised := False;
  try
    TPPGAppearanceSession.Create(nil).Free;
  except
    on E: EPPGError do
      Raised := True;
  end;
  CheckTrue(Raised);
end;

{ TEditorDialogTests }

procedure TEditorDialogTests.AppearanceDialogEditsCopyAndPreview;
var
  B: TPPGButton;
  D: TPPGAppearanceDialog;
  Orig: Integer;
begin
  B := NewButton('A');
  Orig := B.Appearance.Rounding;
  D := TPPGAppearanceDialog.CreateFor(nil, B);
  try
    CheckNotNull(D.Preview, 'Vorschau ist ein echter Button');
    CheckTrue(D.Preview is TPPGButton);
    CheckEquals(B.Preset, TPPGButton(D.Preview).Preset);
    D.RoundingEdit.Value := Orig + 3;
    CheckEquals(Orig + 3, D.Session.Work.Rounding, 'Kopie geaendert');
    CheckEquals(Orig + 3, TPPGButton(D.Preview).Appearance.Rounding, 'Vorschau folgt');
    CheckEquals(Orig, B.Appearance.Rounding, 'Ziel erst nach OK');
    CheckTrue(D.Session.Modified);
  finally
    D.Free;
  end;
  CheckEquals(Orig, B.Appearance.Rounding, 'Abbrechen verwirft');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TEditorDialogTests.AppearanceDialogStateSwitchLoadsValues;
var
  B: TPPGButton;
  D: TPPGAppearanceDialog;
begin
  B := NewButton('A');
  B.Appearance.Normal.Color := clYellow;
  B.Appearance.Hot.Color := clAqua;
  D := TPPGAppearanceDialog.CreateFor(nil, B);
  try
    CheckEquals(clYellow, D.ColorBox0.Selected, 'Normal');
    D.StateBox.ItemIndex := 1;
    D.StateBox.OnClick(D.StateBox);
    CheckEquals(clAqua, D.ColorBox0.Selected, 'Hot');
    // Laden der Werte darf die Kopie nicht veraendern
    CheckFalse(D.Session.Modified);
  finally
    D.Free;
  end;
end;

procedure TEditorDialogTests.GalleryListsPresetsAndPicksMostUsed;
var
  D: TPPGPresetGalleryDialog;
  B1, B2, B3: TPPGButton;
begin
  B1 := NewButton('1');
  B2 := NewButton('2');
  B3 := NewButton('3');
  B1.Preset := PPGPresetClassic;
  B2.Preset := PPGPresetClassic;
  B3.Preset := PPGPresetFluent11;
  D := TPPGPresetGalleryDialog.CreateFor(nil, FForm);
  try
    CheckTrue(D.PresetNames.IndexOf(PPGPresetClassic) >= 0);
    CheckTrue(D.PresetNames.IndexOf(PPGPresetModernFlat) >= 0);
    CheckTrue(D.PresetNames.IndexOf(PPGPresetFluent11) >= 0);
    CheckEquals(PPGPresetClassic, D.SelectedPreset, 'meistgenutztes Preset');
    CheckEquals(3, D.TargetCount);
    D.SelectedPreset := PPGPresetFluent11;
    CheckEquals(PPGPresetFluent11, D.SelectedPreset);
  finally
    D.Free;
  end;
  CheckEquals(PPGPresetClassic, B1.Preset, 'Galerie selbst aendert nichts');
end;

procedure TEditorDialogTests.NavItemsDialogWorksOnCopy;
var
  Nav: TPPGNavigationView;
  D: TPPGNavItemsDialog;
begin
  Nav := TPPGNavigationView.Create(FForm);
  Nav.Parent := FForm;
  Nav.Items.AddItem('Start');
  Nav.Items.AddItem('Ende').Items.AddItem('Kind');
  D := TPPGNavItemsDialog.CreateFor(nil, Nav);
  try
    CheckEquals(3, D.StructureTree.Items.Count, 'Struktur mit Kind');
    CheckTrue(D.SelectedItem = D.View.Items[0], 'erster Eintrag gewaehlt');
    D.CaptionEdit.Text := 'Anfang';
    CheckEquals('Anfang', D.View.Items[0].Caption, 'Kopie geaendert');
    CheckEquals('Start', Nav.Items[0].Caption, 'Ziel erst nach OK');
    D.SelectItem(D.View.Items[1].Items[0]);
    CheckEquals('Kind', D.CaptionEdit.Text);
    Nav.Items.Assign(D.View.Items);
  finally
    D.Free;
  end;
  CheckEquals('Anfang', Nav.Items[0].Caption);
  CheckEquals('Kind', Nav.Items[1].Items[0].Caption, 'verschachtelt uebernommen');
end;

procedure TEditorDialogTests.TreeItemsDialogWorksOnCopy;
var
  T: TPPGTreeView;
  D: TPPGTreeItemsDialog;
begin
  T := TPPGTreeView.Create(FForm);
  T.Parent := FForm;
  T.Items.AddChild(T.Items.Add(nil, 'Wurzel'), 'Kind');
  D := TPPGTreeItemsDialog.CreateFor(nil, T);
  try
    CheckEquals(2, D.Tree.Items.Count);
    CheckEquals('Wurzel', D.TextEdit.Text, 'erster Knoten gewaehlt');
    D.TextEdit.Text := 'Basis';
    CheckEquals('Basis', D.Tree.Items[0].Text);
    CheckEquals('Wurzel', T.Items[0].Text, 'Ziel erst nach OK');
    T.Items.Assign(D.Tree.Items);
  finally
    D.Free;
  end;
  CheckEquals('Basis', T.Items[0].Text);
  CheckEquals('Kind', T.Items[1].Text);
end;

procedure TEditorDialogTests.DialogsFreeWithoutLeaks;
var
  B: TPPGButton;
  I: Integer;
  Before: Integer;
begin
  B := NewButton('A');
  // Aufwaermen (Klassen, Ressourcen einmalig)
  TPPGAppearanceDialog.CreateFor(nil, B).Free;
  TPPGPresetGalleryDialog.CreateFor(nil, FForm).Free;
  Before := Screen.FormCount;
  for I := 1 to 5 do
  begin
    TPPGAppearanceDialog.CreateFor(nil, B).Free;
    TPPGPresetGalleryDialog.CreateFor(nil, FForm).Free;
  end;
  CheckEquals(Before, Screen.FormCount, 'keine Formulare uebrig');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterTest('Phase9a', TPresetTargetTests.Suite);
  RegisterTest('Phase9a', TStructureOpsTests.Suite);
  RegisterTest('Phase9a', TAppearanceSessionTests.Suite);
  RegisterTest('Phase9a', TEditorDialogTests.Suite);

end.
