unit PPG.Tests.Phase9b;

{ Tests fuer Phase 9b: nativer UI-Automation-Provider fuer Grid, TreeView,
  ListBox und CheckListBox (PPG.UIA, PPG.UIA.Intf).

  Die meisten Tests rufen die Provider-Interfaces direkt auf (wie es UIA tut).
  TUiaClientTests fragt zusaetzlich ueber die echte Client-API von
  UIAutomationCore.dll ab - aus einem eigenen Thread, waehrend der Haupt-
  Thread Nachrichten verarbeitet (UIA ruft den Provider im Haupt-Thread
  auf). Damit ist auch geprueft, dass GUIDs und Methodenreihenfolge der
  eigenen Interface-Deklarationen stimmen. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, Winapi.ActiveX, System.Classes,
  System.SysUtils, System.Variants, System.Win.Registry, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.Grids,
  PPG.Types, PPG.Exceptions, PPG.Controls.Base, PPG.UIA.Intf, PPG.UIA,
  PPG.Grid, PPG.TreeView, PPG.ListBox, PPG.CheckListBox, PPG.Controls.ItemList,
  PPG.Tests.Controls;

type
  TUiaTestCase = class(TControlTestCase)
  protected
    FRoot: TPPGUiaRoot;
    FRootRef: IInterface;
    FOwnRoot: Boolean; // True: nicht die Wurzel des Controls (ohne UIA-DLL)
    FClicks: Integer;
    procedure TearDown; override;
    procedure CountClick(Sender: TObject);
    procedure Pump;
    function MakeRoot(C: TPPGCustomControl): TPPGUiaRoot;
    function El(const Id: TPPGUiaId): IRawElementProviderSimple;
    function ElName(const E: IRawElementProviderSimple): string;
    function PropOf(const E: IRawElementProviderSimple; PropId: Integer): OleVariant;
    function NewGrid: TPPGGrid;
  end;

  TUiaHostTests = class(TUiaTestCase)
  published
    procedure OnlyDataControlsAnswerUiaRequest;
    procedure SwitchOffKeepsMsaa;
    procedure RootReleasedWithWindow;
    procedure InterfaceGuidsMatchWindows;
  end;

  TUiaGridTests = class(TUiaTestCase)
  published
    procedure GridAndTablePatterns;
    procedure NavigationRowsAndCells;
    procedure SortingKeepsElementsOnData;
    procedure RemovedRowBecomesUnavailable;
    procedure SetValueRunsQueuedWithValidation;
    procedure ReadOnlyCellRejectsValue;
    procedure ToggleCheckColumnAndInvokeHeader;
    procedure SelectionFollowsFocus;
    procedure ExceptionsStayInsideCom;
  end;

  TUiaTreeTests = class(TUiaTestCase)
  published
    procedure HierarchyFollowsExpansion;
    procedure ExpandCollapseQueued;
    procedure LevelAndPositionProperties;
    procedure DeletedNodeUnavailable;
    procedure ToggleWithCheckBoxes;
  end;

  TUiaListTests = class(TUiaTestCase)
  published
    procedure ListItemsAndSelectFiresClick;
    procedure MultiSelectAddAndRemove;
    procedure CheckListBoxToggle;
  end;

  TUiaClientTests = class(TUiaTestCase)
  published
    procedure ClientReadsAutomationIdAndGridCell;
  end;

implementation

type
  TTreeAccess = class(TPPGTreeView);

/// UIA-Kennung eines Knotens (wie sie der Baum vergibt).
function NodeId(T: TPPGTreeView; N: TPPGTreeNode): TPPGUiaId;
begin
  Result := PPGUiaId(PPGUiaKindListItem, TTreeAccess(T).NodeUiaId(N));
end;

type
  /// Grid, dessen Name im UIA-Aufruf eine Exception wirft (Fehlergrenze).
  TRaisingGrid = class(TPPGGrid)
  protected
    function UiaName(const Id: TPPGUiaId): string; override;
  end;

function TRaisingGrid.UiaName(const Id: TPPGUiaId): string;
begin
  raise EPPGError.Create('Simulierter Fehler in UiaName');
end;

{ TUiaTestCase }

procedure TUiaTestCase.TearDown;
begin
  // Die Wurzel eines Controls trennt das Control selbst beim Freigeben
  if FOwnRoot and (FRoot <> nil) then
    FRoot.Disconnect;
  FOwnRoot := False;
  FRoot := nil;
  FRootRef := nil;
  // DUnit verwendet die Testobjekte wieder (Leak-Lauf: zwei Laeufe)
  FClicks := 0;
  inherited TearDown;
end;

procedure TUiaTestCase.CountClick(Sender: TObject);
begin
  Inc(FClicks);
end;

procedure TUiaTestCase.Pump;
var
  Msg: TMsg;
begin
  // Gepostete UIA-Aktionen ausfuehren
  while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
  if FOwnRoot then
    FRoot.RunQueued;
end;

function TUiaTestCase.MakeRoot(C: TPPGCustomControl): TPPGUiaRoot;
begin
  C.HandleNeeded;
  // Die Wurzel des Controls selbst (wie ein Screenreader per WM_GETOBJECT):
  // nur sie fuehrt die gepostete Aktionsnachricht im WndProc aus
  if PPGUiaAvailable then
  begin
    SendMessage(C.Handle, WM_GETOBJECT, 0, LPARAM(PPGUiaRootObjectId));
    FRoot := C.UiaRoot;
  end;
  // Ohne UIAutomationCore.dll: eigene Wurzel, Pump fuehrt die Aktionen aus
  if FRoot = nil then
  begin
    FRoot := TPPGUiaRoot.CreateRoot(C as IPPGUiaSource, C.Handle, C.Name, C.ClassName);
    FOwnRoot := True;
  end;
  FRootRef := FRoot as IInterface;
  Result := FRoot;
end;

function TUiaTestCase.El(const Id: TPPGUiaId): IRawElementProviderSimple;
begin
  Result := FRoot.ElementFor(Id);
end;

function TUiaTestCase.PropOf(const E: IRawElementProviderSimple; PropId: Integer): OleVariant;
begin
  CheckEquals(S_OK, E.GetPropertyValue(PropId, Result), 'GetPropertyValue');
end;

function TUiaTestCase.ElName(const E: IRawElementProviderSimple): string;
begin
  Result := VarToStr(PropOf(E, UIA_NamePropertyId));
end;

function TUiaTestCase.NewGrid: TPPGGrid;
begin
  // 1 feste Zeile, 1 feste Spalte, 3 Datenzeilen, 3 Datenspalten
  Result := TPPGGrid.Create(FForm);
  Result.Name := 'Grid1';
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 380, 260);
  Result.ColCount := 4;
  Result.RowCount := 4;
  Result.Options := Result.Options + [goEditing];
  // Spalten zuerst und in einem Schritt: Columns bestimmt ColCount, einzelne
  // Add-Aufrufe wuerden das Grid zwischendurch auf 1 Spalte verkleinern
  // (Zellen weg, FixedCols = 0)
  Result.Columns.BeginUpdate;
  try
    Result.Columns.Add;
    Result.Columns.Add;
    Result.Columns.Add;
    Result.Columns.Add.EditorKind := gekCheck; // Spalte 3
  finally
    Result.Columns.EndUpdate;
  end;
  Result.Columns[2].ReadOnly := True;        // Preis nur lesen
  Result.Cells[1, 0] := 'Name';
  Result.Cells[2, 0] := 'Preis';
  Result.Cells[3, 0] := 'Aktiv';
  Result.Cells[0, 1] := 'R1';
  Result.Cells[0, 2] := 'R2';
  Result.Cells[0, 3] := 'R3';
  Result.Cells[1, 1] := 'Birne';
  Result.Cells[1, 2] := 'Apfel';
  Result.Cells[1, 3] := 'Kiwi';
  Result.Cells[2, 1] := '3';
  Result.Cells[2, 2] := '1';
  Result.Cells[2, 3] := '2';
  Result.Cells[3, 1] := '0';
  Result.Cells[3, 2] := '1';
  Result.Cells[3, 3] := '0';
  Result.HandleNeeded;
end;

{ TUiaHostTests }

procedure TUiaHostTests.OnlyDataControlsAnswerUiaRequest;
var
  G: TPPGGrid;
  B: TPPGCustomControl;
  R: LRESULT;
begin
  if not PPGUiaAvailable then
  begin
    Status('UIAutomationCore.dll fehlt - Test entfaellt');
    Exit;
  end;
  G := NewGrid;
  B := NewButton('Knopf');
  R := SendMessage(G.Handle, WM_GETOBJECT, 0, LPARAM(PPGUiaRootObjectId));
  CheckTrue(R <> 0, 'Grid liefert einen UIA-Provider');
  CheckNotNull(G.UiaRoot, 'Wurzel angelegt');
  R := SendMessage(B.Handle, WM_GETOBJECT, 0, LPARAM(PPGUiaRootObjectId));
  CheckEquals(0, Integer(R), 'Button bleibt bei MSAA');
end;

procedure TUiaHostTests.SwitchOffKeepsMsaa;
var
  G: TPPGGrid;
begin
  G := NewGrid;
  PPGUiaEnabled := False;
  try
    CheckEquals(0, Integer(SendMessage(G.Handle, WM_GETOBJECT, 0, LPARAM(PPGUiaRootObjectId))));
    CheckNull(G.UiaRoot);
  finally
    PPGUiaEnabled := True;
  end;
end;

procedure TUiaHostTests.RootReleasedWithWindow;
var
  G: TPPGGrid;
  Held: IRawElementProviderSimple;
  V: OleVariant;
begin
  if not PPGUiaAvailable then
    Exit;
  G := NewGrid;
  SendMessage(G.Handle, WM_GETOBJECT, 0, LPARAM(PPGUiaRootObjectId));
  Held := G.UiaRoot.ElementFor(PPGUiaId(PPGUiaKindGridCell, 1, 1));
  G.Free;
  // Ein Screenreader haelt das Element noch: es antwortet, stuerzt aber nicht
  CheckEquals(UIA_E_ELEMENTNOTAVAILABLE, Held.GetPropertyValue(UIA_NamePropertyId, V));
end;

procedure TUiaHostTests.InterfaceGuidsMatchWindows;

  procedure CheckGuid(const Guid: TGUID; const Name: string);
  var
    Reg: TRegistry;
    Key: string;
  begin
    // Windows registriert die Proxys der UIA-Interfaces unter ihrer GUID.
    // Eine falsche GUID faellt sonst nur auf, wenn ein Screenreader das
    // Muster ueber COM-Marshalling holt (es kommt dann still nil zurueck).
    Reg := TRegistry.Create(KEY_READ);
    try
      Reg.RootKey := HKEY_CLASSES_ROOT;
      Key := 'Interface\' + GUIDToString(Guid);
      if not Reg.OpenKeyReadOnly(Key) then
        Fail(Name + ': GUID ' + GUIDToString(Guid) + ' ist in Windows nicht registriert');
      CheckEquals(Name, Reg.ReadString(''), 'Name zur GUID');
    finally
      Reg.Free;
    end;
  end;

begin
  if not PPGUiaAvailable then
  begin
    Status('UIAutomationCore.dll fehlt - Test entfaellt');
    Exit;
  end;
  CheckGuid(IRawElementProviderSimple, 'IRawElementProviderSimple');
  CheckGuid(IRawElementProviderFragment, 'IRawElementProviderFragment');
  CheckGuid(IRawElementProviderFragmentRoot, 'IRawElementProviderFragmentRoot');
  CheckGuid(IInvokeProvider, 'IInvokeProvider');
  CheckGuid(ISelectionProvider, 'ISelectionProvider');
  CheckGuid(ISelectionItemProvider, 'ISelectionItemProvider');
  CheckGuid(IValueProvider, 'IValueProvider');
  CheckGuid(IExpandCollapseProvider, 'IExpandCollapseProvider');
  CheckGuid(IGridProvider, 'IGridProvider');
  CheckGuid(IGridItemProvider, 'IGridItemProvider');
  CheckGuid(ITableProvider, 'ITableProvider');
  CheckGuid(ITableItemProvider, 'ITableItemProvider');
  CheckGuid(IToggleProvider, 'IToggleProvider');
  CheckGuid(IScrollItemProvider, 'IScrollItemProvider');
end;

{ TUiaGridTests }

procedure TUiaGridTests.GridAndTablePatterns;
var
  G: TPPGGrid;
  Grid: IGridProvider;
  Table: ITableProvider;
  Cell: IRawElementProviderSimple;
  GI: IGridItemProvider;
  TI: ITableItemProvider;
  Unk: IUnknown;
  N: Integer;
  SA: PSafeArray;
begin
  G := NewGrid;
  MakeRoot(G);
  CheckEquals(UIA_DataGridControlTypeId, Integer(PropOf(FRoot, UIA_ControlTypePropertyId)));
  CheckEquals('Grid1', VarToStr(PropOf(FRoot, UIA_AutomationIdPropertyId)));
  CheckEquals(S_OK, FRoot.GetPatternProvider(UIA_GridPatternId, Unk));
  CheckNotNull(Unk, 'Grid-Muster');
  Grid := Unk as IGridProvider;
  Grid.get_RowCount(N);
  CheckEquals(3, N, 'Datenzeilen ohne Kopf');
  Grid.get_ColumnCount(N);
  CheckEquals(3, N, 'Datenspalten ohne feste Spalte');
  CheckEquals(E_INVALIDARG, Grid.GetItem(3, 0, Cell));
  CheckEquals(S_OK, Grid.GetItem(1, 0, Cell));
  CheckEquals('Apfel', ElName(Cell));
  CheckEquals(S_OK, Cell.GetPatternProvider(UIA_GridItemPatternId, Unk));
  GI := Unk as IGridItemProvider;
  GI.get_Row(N);
  CheckEquals(1, N);
  GI.get_Column(N);
  CheckEquals(0, N);
  CheckEquals(S_OK, Cell.GetPatternProvider(UIA_TableItemPatternId, Unk));
  TI := Unk as ITableItemProvider;
  CheckEquals(S_OK, TI.GetColumnHeaderItems(SA));
  CheckTrue(SA <> nil, 'Spaltenkopf der Zelle');
  SafeArrayDestroy(SA);
  CheckEquals(S_OK, FRoot.GetPatternProvider(UIA_TablePatternId, Unk));
  Table := Unk as ITableProvider;
  CheckEquals(S_OK, Table.GetColumnHeaders(SA));
  CheckTrue(SA <> nil);
  SafeArrayDestroy(SA);
  // Zeilen haben kein Grid-Muster
  El(PPGUiaId(PPGUiaKindGridRow, 1)).GetPatternProvider(UIA_GridItemPatternId, Unk);
  CheckNull(Unk);
end;

procedure TUiaGridTests.NavigationRowsAndCells;
var
  G: TPPGGrid;
  RootF, Header, Row, Cell0, Cell1, Up, Up2, None: IRawElementProviderFragment;
begin
  // Eigene Variablen je Schritt: eine Interface-Variable nie zugleich als
  // Objekt des Aufrufs und als out-Parameter verwenden (out gibt sie vorher frei)
  G := NewGrid;
  MakeRoot(G);
  RootF := FRoot as IRawElementProviderFragment;
  CheckEquals(S_OK, RootF.Navigate(NavigateDirection_FirstChild, Header));
  CheckEquals(UIA_HeaderControlTypeId,
    Integer(PropOf(Header as IRawElementProviderSimple, UIA_ControlTypePropertyId)), 'Kopfzeile zuerst');
  Header.Navigate(NavigateDirection_NextSibling, Row);
  CheckNotNull(Row, 'erste Datenzeile');
  CheckEquals(UIA_DataItemControlTypeId,
    Integer(PropOf(Row as IRawElementProviderSimple, UIA_ControlTypePropertyId)));
  Row.Navigate(NavigateDirection_FirstChild, Cell0);
  CheckEquals('R1', ElName(Cell0 as IRawElementProviderSimple), 'Zeilenkopf-Zelle');
  Cell0.Navigate(NavigateDirection_NextSibling, Cell1);
  CheckEquals('Birne', ElName(Cell1 as IRawElementProviderSimple));
  Cell1.Navigate(NavigateDirection_Parent, Up);
  Up.Navigate(NavigateDirection_Parent, Up2);
  CheckTrue(Up2 = RootF, 'zurueck zur Wurzel');
  RootF.Navigate(NavigateDirection_Parent, None);
  CheckNull(None, 'Eltern der Wurzel liefert UIA ueber das Fenster');
end;

procedure TUiaGridTests.SortingKeepsElementsOnData;
var
  G: TPPGGrid;
  Grid: IGridProvider;
  Unk: IUnknown;
  Cell, Held: IRawElementProviderSimple;
  GI: IGridItemProvider;
  N: Integer;
begin
  G := NewGrid;
  MakeRoot(G);
  FRoot.GetPatternProvider(UIA_GridPatternId, Unk);
  Grid := Unk as IGridProvider;
  Grid.GetItem(0, 0, Held);
  CheckEquals('Birne', ElName(Held));
  G.SortBy(1, True);
  Grid.GetItem(0, 0, Cell);
  CheckEquals('Apfel', ElName(Cell), 'sichtbare Reihenfolge');
  // Das gehaltene Element zeigt weiter auf "Birne", jetzt in Zeile 1
  CheckEquals('Birne', ElName(Held));
  Held.GetPatternProvider(UIA_GridItemPatternId, Unk);
  GI := Unk as IGridItemProvider;
  GI.get_Row(N);
  CheckEquals(1, N);
end;

procedure TUiaGridTests.RemovedRowBecomesUnavailable;
var
  G: TPPGGrid;
  E: IRawElementProviderSimple;
  V: OleVariant;
begin
  G := NewGrid;
  MakeRoot(G);
  E := El(PPGUiaId(PPGUiaKindGridCell, 3, 1));
  CheckEquals('Kiwi', ElName(E));
  G.RowCount := 3;
  CheckEquals(UIA_E_ELEMENTNOTAVAILABLE, E.GetPropertyValue(UIA_NamePropertyId, V));
  // Herausgefiltert ist ebenfalls nicht verfuegbar
  E := El(PPGUiaId(PPGUiaKindGridCell, 1, 1));
  G.ShowFilterRow := True;
  G.Filters[1] := 'Apf';
  CheckEquals(UIA_E_ELEMENTNOTAVAILABLE, E.GetPropertyValue(UIA_NamePropertyId, V));
end;

procedure TUiaGridTests.SetValueRunsQueuedWithValidation;
var
  G: TPPGGrid;
  Unk: IUnknown;
  Val: IValueProvider;
  W: WideString;
begin
  G := NewGrid;
  MakeRoot(G);
  El(PPGUiaId(PPGUiaKindGridCell, 1, 1)).GetPatternProvider(UIA_ValuePatternId, Unk);
  Val := Unk as IValueProvider;
  W := 'Quitte';
  CheckEquals(S_OK, Val.SetValue(PWideChar(W)));
  CheckEquals('Birne', G.Cells[1, 1], 'nicht im COM-Aufruf');
  CheckEquals(1, FRoot.QueuedCount);
  Pump;
  CheckEquals('Quitte', G.Cells[1, 1], 'nach der Nachricht');
  Val.get_Value(W);
  CheckEquals('Quitte', string(W));
end;

procedure TUiaGridTests.ReadOnlyCellRejectsValue;
var
  G: TPPGGrid;
  Unk: IUnknown;
  Val: IValueProvider;
  RO: BOOL;
  W: WideString;
begin
  G := NewGrid;
  MakeRoot(G);
  El(PPGUiaId(PPGUiaKindGridCell, 1, 2)).GetPatternProvider(UIA_ValuePatternId, Unk);
  Val := Unk as IValueProvider;
  Val.get_IsReadOnly(RO);
  CheckTrue(RO, 'Spalte Preis ist ReadOnly');
  W := '9';
  CheckEquals(UIA_E_INVALIDOPERATION, Val.SetValue(PWideChar(W)));
  G.Enabled := False;
  El(PPGUiaId(PPGUiaKindGridCell, 1, 1)).GetPatternProvider(UIA_ValuePatternId, Unk);
  Val := Unk as IValueProvider;
  CheckEquals(UIA_E_ELEMENTNOTENABLED, Val.SetValue(PWideChar(W)));
end;

procedure TUiaGridTests.ToggleCheckColumnAndInvokeHeader;
var
  G: TPPGGrid;
  Unk: IUnknown;
  T: IToggleProvider;
  State: Integer;
begin
  G := NewGrid;
  MakeRoot(G);
  El(PPGUiaId(PPGUiaKindGridCell, 1, 1)).GetPatternProvider(UIA_TogglePatternId, Unk);
  CheckNull(Unk, 'Textspalte ohne Toggle');
  El(PPGUiaId(PPGUiaKindGridCell, 1, 3)).GetPatternProvider(UIA_TogglePatternId, Unk);
  T := Unk as IToggleProvider;
  T.get_ToggleState(State);
  CheckEquals(ToggleState_Off, State);
  CheckEquals(S_OK, T.Toggle);
  Pump;
  CheckEquals('1', G.Cells[3, 1]);
  // Kopfzelle "Name": Invoke sortiert
  El(PPGUiaId(PPGUiaKindGridHeaderCell, 0, 1)).GetPatternProvider(UIA_InvokePatternId, Unk);
  CheckEquals(S_OK, (Unk as IInvokeProvider).Invoke);
  Pump;
  CheckEquals(1, G.SortColumn);
  CheckEquals('Sorted ascending',
    VarToStr(PropOf(El(PPGUiaId(PPGUiaKindGridHeaderCell, 0, 1)), UIA_ItemStatusPropertyId)));
end;

procedure TUiaGridTests.SelectionFollowsFocus;
var
  G: TPPGGrid;
  Unk: IUnknown;
  SI: ISelectionItemProvider;
  Sel: BOOL;
begin
  G := NewGrid;
  MakeRoot(G);
  El(PPGUiaId(PPGUiaKindGridCell, 2, 2)).GetPatternProvider(UIA_SelectionItemPatternId, Unk);
  SI := Unk as ISelectionItemProvider;
  SI.get_IsSelected(Sel);
  CheckFalse(Sel);
  CheckEquals(S_OK, SI.Select);
  Pump;
  CheckEquals(2, G.Col);
  CheckEquals(2, G.Row);
  SI.get_IsSelected(Sel);
  CheckTrue(Sel);
end;

procedure TUiaGridTests.ExceptionsStayInsideCom;
var
  G: TRaisingGrid;
  V: OleVariant;
begin
  G := TRaisingGrid.Create(FForm);
  G.Parent := FForm;
  MakeRoot(G);
  CheckEquals(E_FAIL, El(PPGUiaId(PPGUiaKindGridCell, 1, 1)).GetPropertyValue(UIA_NamePropertyId, V));
  CheckEquals(S_OK, FRoot.GetPropertyValue(UIA_ControlTypePropertyId, V), 'andere Eigenschaften gehen');
end;

{ TUiaTreeTests }

function NewTree(Form: TForm): TPPGTreeView;
var
  A: TPPGTreeNode;
begin
  Result := TPPGTreeView.Create(Form);
  Result.Parent := Form;
  Result.SetBounds(0, 0, 240, 300);
  A := Result.Items.Add(nil, 'A');
  Result.Items.AddChild(A, 'A1');
  Result.Items.AddChild(A, 'A2');
  Result.Items.Add(nil, 'B');
  Result.HandleNeeded;
end;

procedure TUiaTreeTests.HierarchyFollowsExpansion;
var
  T: TPPGTreeView;
  A: TPPGUiaId;
begin
  T := NewTree(FForm);
  MakeRoot(T);
  CheckEquals(2, TTreeAccess(T).UiaChildCount(PPGUiaId(0)), 'zwei Wurzeln');
  A := NodeId(T, T.Items[0]);
  CheckEquals(0, TTreeAccess(T).UiaChildCount(A), 'zugeklappt: keine Kinder');
  T.Items[0].Expand(False);
  CheckEquals(2, TTreeAccess(T).UiaChildCount(A));
  CheckEquals('A2', ElName(El(NodeId(T, T.Items[2]))));
  CheckEquals(UIA_TreeItemControlTypeId, Integer(PropOf(El(A), UIA_ControlTypePropertyId)));
end;

procedure TUiaTreeTests.ExpandCollapseQueued;
var
  T: TPPGTreeView;
  Unk: IUnknown;
  EC: IExpandCollapseProvider;
  State: Integer;
begin
  T := NewTree(FForm);
  MakeRoot(T);
  El(NodeId(T, T.Items[0])).GetPatternProvider(UIA_ExpandCollapsePatternId, Unk);
  EC := Unk as IExpandCollapseProvider;
  EC.get_ExpandCollapseState(State);
  CheckEquals(ExpandCollapseState_Collapsed, State);
  CheckEquals(S_OK, EC.Expand);
  CheckFalse(T.Items[0].Expanded, 'nicht im COM-Aufruf');
  Pump;
  CheckTrue(T.Items[0].Expanded);
  EC.get_ExpandCollapseState(State);
  CheckEquals(ExpandCollapseState_Expanded, State);
  // Blatt: Expand ist ungueltig
  El(NodeId(T, T.Items[1])).GetPatternProvider(UIA_ExpandCollapsePatternId, Unk);
  CheckEquals(UIA_E_INVALIDOPERATION, (Unk as IExpandCollapseProvider).Expand);
end;

procedure TUiaTreeTests.LevelAndPositionProperties;
var
  T: TPPGTreeView;
  E: IRawElementProviderSimple;
begin
  T := NewTree(FForm);
  T.Items[0].Expand(False);
  MakeRoot(T);
  E := El(NodeId(T, T.Items[2])); // A2
  CheckEquals(2, Integer(PropOf(E, UIA_LevelPropertyId)));
  CheckEquals(2, Integer(PropOf(E, UIA_PositionInSetPropertyId)));
  CheckEquals(2, Integer(PropOf(E, UIA_SizeOfSetPropertyId)));
end;

procedure TUiaTreeTests.DeletedNodeUnavailable;
var
  T: TPPGTreeView;
  E: IRawElementProviderSimple;
  V: OleVariant;
begin
  T := NewTree(FForm);
  MakeRoot(T);
  E := El(NodeId(T, T.Items.Root(1)));
  CheckEquals('B', ElName(E));
  T.Items.Root(1).Delete;
  CheckEquals(UIA_E_ELEMENTNOTAVAILABLE, E.GetPropertyValue(UIA_NamePropertyId, V));
  // Neue Knoten bekommen neue Nummern (keine Verwechslung)
  T.Items.Add(nil, 'C');
  CheckEquals(UIA_E_ELEMENTNOTAVAILABLE, E.GetPropertyValue(UIA_NamePropertyId, V));
end;

procedure TUiaTreeTests.ToggleWithCheckBoxes;
var
  T: TPPGTreeView;
  Unk: IUnknown;
  State: Integer;
begin
  T := NewTree(FForm);
  MakeRoot(T);
  El(NodeId(T, T.Items.Root(1))).GetPatternProvider(UIA_TogglePatternId, Unk);
  CheckNull(Unk, 'ohne CheckBoxes kein Toggle');
  T.CheckBoxes := True;
  El(NodeId(T, T.Items.Root(1))).GetPatternProvider(UIA_TogglePatternId, Unk);
  CheckEquals(S_OK, (Unk as IToggleProvider).Toggle);
  Pump;
  CheckTrue(T.Items.Root(1).Checked);
  (Unk as IToggleProvider).get_ToggleState(State);
  CheckEquals(ToggleState_On, State);
end;

{ TUiaListTests }

procedure TUiaListTests.ListItemsAndSelectFiresClick;
var
  L: TPPGListBox;
  Unk: IUnknown;
  SA: PSafeArray;
begin
  L := TPPGListBox.Create(FForm);
  L.Parent := FForm;
  L.Items.CommaText := 'Eins,Zwei,Drei';
  L.OnClick := CountClick;
  MakeRoot(L);
  CheckEquals(UIA_ListControlTypeId, Integer(PropOf(FRoot, UIA_ControlTypePropertyId)));
  CheckEquals('Drei', ElName(El(PPGUiaId(PPGUiaKindListItem, 2))));
  CheckEquals(3, Integer(PropOf(El(PPGUiaId(PPGUiaKindListItem, 2)), UIA_PositionInSetPropertyId)));
  El(PPGUiaId(PPGUiaKindListItem, 2)).GetPatternProvider(UIA_SelectionItemPatternId, Unk);
  CheckEquals(S_OK, (Unk as ISelectionItemProvider).Select);
  CheckEquals(0, FClicks);
  Pump;
  CheckEquals(2, L.ItemIndex);
  CheckEquals(1, FClicks, 'Anwender-Aktion wie ein Klick');
  FRoot.GetPatternProvider(UIA_SelectionPatternId, Unk);
  CheckEquals(S_OK, (Unk as ISelectionProvider).GetSelection(SA));
  CheckTrue(SA <> nil);
  SafeArrayDestroy(SA);
  // Wert aendern geht in der Liste nicht
  El(PPGUiaId(PPGUiaKindListItem, 0)).GetPatternProvider(UIA_ValuePatternId, Unk);
  CheckNull(Unk);
end;

procedure TUiaListTests.MultiSelectAddAndRemove;
var
  L: TPPGListBox;
  Unk: IUnknown;
  Multi: BOOL;
begin
  L := TPPGListBox.Create(FForm);
  L.Parent := FForm;
  L.Items.CommaText := 'Eins,Zwei,Drei';
  L.MultiSelect := True;
  MakeRoot(L);
  FRoot.GetPatternProvider(UIA_SelectionPatternId, Unk);
  (Unk as ISelectionProvider).get_CanSelectMultiple(Multi);
  CheckTrue(Multi);
  El(PPGUiaId(PPGUiaKindListItem, 0)).GetPatternProvider(UIA_SelectionItemPatternId, Unk);
  (Unk as ISelectionItemProvider).AddToSelection;
  El(PPGUiaId(PPGUiaKindListItem, 2)).GetPatternProvider(UIA_SelectionItemPatternId, Unk);
  (Unk as ISelectionItemProvider).AddToSelection;
  Pump;
  CheckEquals(2, L.SelCount);
  (Unk as ISelectionItemProvider).RemoveFromSelection;
  Pump;
  CheckEquals(1, L.SelCount);
  CheckTrue(L.Selected[0]);
end;

procedure TUiaListTests.CheckListBoxToggle;
var
  L: TPPGCheckListBox;
  Unk: IUnknown;
  State: Integer;
begin
  L := TPPGCheckListBox.Create(FForm);
  L.Parent := FForm;
  L.Items.CommaText := 'Eins,Zwei';
  L.Header[0] := True;
  MakeRoot(L);
  El(PPGUiaId(PPGUiaKindListItem, 0)).GetPatternProvider(UIA_TogglePatternId, Unk);
  CheckNull(Unk, 'Ueberschrift ohne Kaestchen');
  El(PPGUiaId(PPGUiaKindListItem, 1)).GetPatternProvider(UIA_TogglePatternId, Unk);
  CheckEquals(S_OK, (Unk as IToggleProvider).Toggle);
  Pump;
  CheckTrue(L.Checked[1]);
  (Unk as IToggleProvider).get_ToggleState(State);
  CheckEquals(ToggleState_On, State);
end;

{ TUiaClientTests }

type
  HUIANODE = Pointer;
  HUIAPATTERNOBJECT = Pointer;
  TUiaNodeFromHandle = function(hwnd: HWND; out phnode: HUIANODE): HResult; stdcall;
  TUiaGetPropertyValue = function(hnode: HUIANODE; propertyId: Integer; out pValue: OleVariant): HResult; stdcall;
  TUiaGetPatternProvider = function(hnode: HUIANODE; patternId: Integer; out phobj: HUIAPATTERNOBJECT): HResult; stdcall;
  TGridPatternGetItem = function(hobj: HUIAPATTERNOBJECT; row, column: Integer; out pResult: HUIANODE): HResult; stdcall;
  TUiaNodeRelease = function(hnode: HUIANODE): BOOL; stdcall;
  TUiaPatternRelease = function(hobj: HUIAPATTERNOBJECT): BOOL; stdcall;

  /// Fragt das Grid ueber die Client-API ab (eigener Thread, MTA).
  TUiaClientThread = class(TThread)
  private
    FWnd: HWND;
  protected
    procedure Execute; override;
  public
    AutomationId: string;
    CellName: string;
    Error: string;
    constructor Create(AWnd: HWND);
  end;

constructor TUiaClientThread.Create(AWnd: HWND);
begin
  FWnd := AWnd;
  inherited Create(False);
end;

procedure TUiaClientThread.Execute;
var
  Lib: HMODULE;
  NodeFromHandle: TUiaNodeFromHandle;
  GetProp: TUiaGetPropertyValue;
  GetPattern: TUiaGetPatternProvider;
  GetItem: TGridPatternGetItem;
  NodeRelease: TUiaNodeRelease;
  PatternRelease: TUiaPatternRelease;
  Node, Cell: HUIANODE;
  Grid: HUIAPATTERNOBJECT;
  V: OleVariant;
  R: HResult;
begin
  CoInitializeEx(nil, COINIT_MULTITHREADED);
  try
    Lib := LoadLibrary('UIAutomationCore.dll');
    @NodeFromHandle := GetProcAddress(Lib, 'UiaNodeFromHandle');
    @GetProp := GetProcAddress(Lib, 'UiaGetPropertyValue');
    @GetPattern := GetProcAddress(Lib, 'UiaGetPatternProvider');
    @GetItem := GetProcAddress(Lib, 'GridPattern_GetItem');
    @NodeRelease := GetProcAddress(Lib, 'UiaNodeRelease');
    @PatternRelease := GetProcAddress(Lib, 'UiaPatternRelease');
    if not Assigned(NodeFromHandle) or not Assigned(GetItem) then
    begin
      Error := 'Client-API fehlt';
      Exit;
    end;
    if Failed(NodeFromHandle(FWnd, Node)) then
    begin
      Error := 'UiaNodeFromHandle';
      Exit;
    end;
    try
      if Succeeded(GetProp(Node, UIA_AutomationIdPropertyId, V)) then
        AutomationId := VarToStr(V);
      // Jeder Schritt mit eigener Meldung: sonst sagt ein leerer Name nichts
      R := GetPattern(Node, UIA_GridPatternId, Grid);
      if Failed(R) or (Grid = nil) then
        Error := Format('UiaGetPatternProvider(Grid): %x', [R])
      else
      try
        R := GetItem(Grid, 1, 0, Cell);
        if Failed(R) or (Cell = nil) then
          Error := Format('GridPattern_GetItem: %x', [R])
        else
        try
          R := GetProp(Cell, UIA_NamePropertyId, V);
          if Failed(R) then
            Error := Format('UiaGetPropertyValue(Name) der Zelle: %x', [R])
          else
            CellName := VarToStr(V);
        finally
          NodeRelease(Cell);
        end;
      finally
        PatternRelease(Grid);
      end;
    finally
      NodeRelease(Node);
    end;
  finally
    CoUninitialize;
  end;
end;

procedure TUiaClientTests.ClientReadsAutomationIdAndGridCell;
var
  G: TPPGGrid;
  T: TUiaClientThread;
  Start: Cardinal;
begin
  if not PPGUiaAvailable then
  begin
    Status('UIAutomationCore.dll fehlt - Test entfaellt');
    Exit;
  end;
  G := NewGrid;
  FForm.Show;
  try
    T := TUiaClientThread.Create(G.Handle);
    try
      // UIA ruft den Provider im Haupt-Thread: Nachrichten verarbeiten
      Start := GetTickCount;
      while not T.Finished and (GetTickCount - Start < 10000) do
      begin
        Application.ProcessMessages;
        Sleep(5);
      end;
      CheckTrue(T.Finished, 'Client-Thread haengt (Zeitgrenze 10 s)');
      T.WaitFor;
      CheckEquals('', T.Error, T.Error);
      CheckEquals('Grid1', T.AutomationId, 'eigener Provider (GUID von IRawElementProviderSimple)');
      CheckEquals('Apfel', T.CellName, 'Grid-Muster ueber die Client-API (GUID/vtable von IGridProvider)');
    finally
      if T.Finished then
        T.Free;
    end;
  finally
    FForm.Hide;
  end;
end;

initialization
  RegisterTest('Phase9b', TUiaHostTests.Suite);
  RegisterTest('Phase9b', TUiaGridTests.Suite);
  RegisterTest('Phase9b', TUiaTreeTests.Suite);
  RegisterTest('Phase9b', TUiaListTests.Suite);
  RegisterTest('Phase9b', TUiaClientTests.Suite);

end.
