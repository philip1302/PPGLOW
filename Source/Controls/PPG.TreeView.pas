unit PPG.TreeView;

{ TPPGTreeView - Baum im Stil der Suite (Phase 6b).

  Aufbau: Die sichtbaren Knoten bilden eine flache Zeilenliste; sie ist die
  IPPGItemSource der Listen-Basis. Zeichnen, Scrollen, Auswahl, Tippsuche
  und Barrierefreiheit kommen damit aus TPPGCustomItemList; der Baum fuegt
  Einzug, Auf-/Zuklapp-Pfeil, Linien, Kaestchen und das Umbenennen hinzu.

  - Knoten: TPPGTreeNode/TPPGTreeNodes mit einer API wie TTreeNode/TTreeNodes
    (Add, AddChild, Insert, MoveTo, Expand, Collapse, GetNext, ...).
  - Lazy Loading wie bei TTreeView: HasChildren := True zeigt den Pfeil ohne
    Kinder; OnExpanding fuellt die Kinder beim ersten Aufklappen.
  - Kaestchen (CheckBoxes) mit drei Zustaenden; AutoCheck gibt den Zustand an
    Kinder weiter und berechnet die Eltern (alle an / alle aus / gemischt).
  - Umbenennen (ReadOnly = False) mit F2 bzw. EditText ueber ein natives Edit:
    Enter uebernimmt, Esc verwirft, Fokusverlust und Scrollen uebernehmen.
  - Knoten ziehen (AllowReorder): oberes/unteres Viertel = davor/danach,
    Mitte = hinein; OnNodeDrop kann ablehnen.
  - Ereignisse: OnChange auch bei Selected im Code (wie TTreeView);
    Aufklappen ruft OnExpanding auch aus dem Code (noetig fuer Lazy Loading).
  - Streaming: Items als lesbare Zeilenliste ("Items.Nodes"); binaere
    TTreeView-Knoten aus alten DFMs werden nicht gelesen. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.ComCtrls,
  System.Generics.Collections,
  PPG.Types, PPG.Items, PPG.Animation, PPG.Render.Intf, PPG.ItemPainter, PPG.UIA,
  PPG.Controls.ItemList, PPG.CustomDraw;

type
  TPPGTreeNodes = class;
  TPPGCustomTreeView = class;

  TPPGTreeNode = class(TPersistent)
  private
    FOwner: TPPGTreeNodes;
    FParent: TPPGTreeNode;
    FChildren: TList;
    FText: string;
    FDetail: string;
    FBadge: string;
    FImageIndex: Integer;
    FSelectedIndex: Integer;
    FCheckState: TCheckBoxState;
    FEnabled: Boolean;
    FExpanded: Boolean;
    FHasChildren: Boolean;
    FData: Pointer;
    FRow: Integer;
    FRowGen: Cardinal;
    FUiaId: Integer; // UI Automation: stabile Nummer (0 = noch keine)
    FColor: TColor;
    FTextColor: TColor;
    FFontStyle: TFontStyles;
    procedure SetColor(const Value: TColor);
    procedure SetTextColor(const Value: TColor);
    procedure SetFontStyle(const Value: TFontStyles);
    function GetCount: Integer;
    function GetItem(Index: Integer): TPPGTreeNode;
    function GetIndex: Integer;
    function GetLevel: Integer;
    function GetHasChildren: Boolean;
    procedure SetHasChildren(const Value: Boolean);
    procedure SetText(const Value: string);
    procedure SetDetail(const Value: string);
    procedure SetBadge(const Value: string);
    procedure SetImageIndex(const Value: Integer);
    procedure SetSelectedIndex(const Value: Integer);
    procedure SetEnabled(const Value: Boolean);
    procedure SetExpanded(const Value: Boolean);
    function GetChecked: Boolean;
    procedure SetChecked(const Value: Boolean);
    procedure SetCheckState(const Value: TCheckBoxState);
    function GetSelected: Boolean;
    procedure SetSelected(const Value: Boolean);
    function GetFocused: Boolean;
    function GetTreeView: TPPGCustomTreeView;
    function GetAbsoluteIndex: Integer;
    function Siblings: TList;
    procedure Changed;
  public
    constructor Create(AOwner: TPPGTreeNodes);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function GetFirstChild: TPPGTreeNode;
    function GetLastChild: TPPGTreeNode;
    function GetNextSibling: TPPGTreeNode;
    function GetPrevSibling: TPPGTreeNode;
    /// Naechster/voriger Knoten in Tiefensuche (unabhaengig vom Aufklappen).
    function GetNext: TPPGTreeNode;
    function GetPrev: TPPGTreeNode;
    /// Naechster/voriger sichtbarer Knoten (Zeile).
    function GetNextVisible: TPPGTreeNode;
    function GetPrevVisible: TPPGTreeNode;
    function HasAsParent(Value: TPPGTreeNode): Boolean;
    function IndexOf(Value: TPPGTreeNode): Integer;
    function IsVisible: Boolean;
    procedure Expand(Recurse: Boolean);
    procedure Collapse(Recurse: Boolean);
    procedure MakeVisible;
    procedure Delete;
    procedure DeleteChildren;
    procedure MoveTo(Destination: TPPGTreeNode; Mode: TNodeAttachMode);
    /// Startet das Umbenennen (False = nicht moeglich, z.B. ReadOnly).
    function EditText: Boolean;
    property Owner: TPPGTreeNodes read FOwner;
    property TreeView: TPPGCustomTreeView read GetTreeView;
    property Parent: TPPGTreeNode read FParent;
    property Count: Integer read GetCount;
    property Item[Index: Integer]: TPPGTreeNode read GetItem; default;
    property Index: Integer read GetIndex;
    property AbsoluteIndex: Integer read GetAbsoluteIndex;
    property Level: Integer read GetLevel;
    property Text: string read FText write SetText;
    property Detail: string read FDetail write SetDetail;
    property Badge: string read FBadge write SetBadge;
    property ImageIndex: Integer read FImageIndex write SetImageIndex;
    property SelectedIndex: Integer read FSelectedIndex write SetSelectedIndex;
    property Data: Pointer read FData write FData;
    property Enabled: Boolean read FEnabled write SetEnabled;
    property Expanded: Boolean read FExpanded write SetExpanded;
    property HasChildren: Boolean read GetHasChildren write SetHasChildren;
    property CheckState: TCheckBoxState read FCheckState write SetCheckState;
    property Checked: Boolean read GetChecked write SetChecked;
    property Selected: Boolean read GetSelected write SetSelected;
    property Focused: Boolean read GetFocused;
    /// Flaeche, Text und zusaetzliche Schriftstile dieses Knotens
    /// (clDefault = Baum; nur zur Laufzeit, nicht in der DFM).
    property Color: TColor read FColor write SetColor;
    property TextColor: TColor read FTextColor write SetTextColor;
    property FontStyle: TFontStyles read FFontStyle write SetFontStyle;
  end;

  TPPGTreeNodes = class(TPersistent)
  private
    FOwner: TPPGCustomTreeView;
    FRoots: TList;
    FCount: Integer;
    FUpdateCount: Integer;
    FCacheNode: TPPGTreeNode;
    FCacheIndex: Integer;
    function GetItem(Index: Integer): TPPGTreeNode;
    function Attach(Node, Dest: TPPGTreeNode; Mode: TNodeAttachMode): TPPGTreeNode;
    procedure Detach(Node: TPPGTreeNode);
    procedure ReadNodes(Reader: TReader);
    procedure WriteNodes(Writer: TWriter);
    procedure FreeNode(Node: TPPGTreeNode);
    procedure Changed;
  protected
    procedure DefineProperties(Filer: TFiler); override;
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TPPGCustomTreeView);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function Add(Sibling: TPPGTreeNode; const S: string): TPPGTreeNode;
    function AddObject(Sibling: TPPGTreeNode; const S: string; Ptr: Pointer): TPPGTreeNode;
    function AddFirst(Sibling: TPPGTreeNode; const S: string): TPPGTreeNode;
    function AddChild(Parent: TPPGTreeNode; const S: string): TPPGTreeNode;
    function AddChildObject(Parent: TPPGTreeNode; const S: string; Ptr: Pointer): TPPGTreeNode;
    function AddChildFirst(Parent: TPPGTreeNode; const S: string): TPPGTreeNode;
    function Insert(Sibling: TPPGTreeNode; const S: string): TPPGTreeNode;
    procedure Delete(Node: TPPGTreeNode);
    procedure Clear;
    procedure BeginUpdate;
    procedure EndUpdate;
    function GetFirstNode: TPPGTreeNode;
    /// Knoten ohne Eltern (Wurzeln).
    function RootCount: Integer;
    function Root(Index: Integer): TPPGTreeNode;
    /// Gesamtzahl aller Knoten.
    property Count: Integer read FCount;
    /// Knoten in Tiefensuche-Reihenfolge (wie TTreeNodes.Item).
    property Item[Index: Integer]: TPPGTreeNode read GetItem; default;
    property Owner: TPPGCustomTreeView read FOwner;
  end;

  TPPGTVChangedEvent = procedure(Sender: TObject; Node: TPPGTreeNode) of object;
  TPPGTVChangingEvent = procedure(Sender: TObject; Node: TPPGTreeNode;
    var AllowChange: Boolean) of object;
  TPPGTVExpandingEvent = procedure(Sender: TObject; Node: TPPGTreeNode;
    var AllowExpansion: Boolean) of object;
  TPPGTVCollapsingEvent = procedure(Sender: TObject; Node: TPPGTreeNode;
    var AllowCollapse: Boolean) of object;
  TPPGTVExpandedEvent = procedure(Sender: TObject; Node: TPPGTreeNode) of object;
  TPPGTVEditingEvent = procedure(Sender: TObject; Node: TPPGTreeNode;
    var AllowEdit: Boolean) of object;
  TPPGTVEditedEvent = procedure(Sender: TObject; Node: TPPGTreeNode; var S: string) of object;
  TPPGTVCompareEvent = procedure(Sender: TObject; Node1, Node2: TPPGTreeNode;
    var Compare: Integer) of object;
  TPPGTVNodeDropEvent = procedure(Sender: TObject; Node, Target: TPPGTreeNode;
    Mode: TNodeAttachMode; var Allow: Boolean) of object;

  /// Eigenes Zeichnen eines Knotens (vor dem Zeichnen; siehe PPG.CustomDraw).
  TPPGTVCustomDrawEvent = procedure(Sender: TObject; Canvas: TCanvas; Node: TPPGTreeNode;
    const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
    var DefaultDraw: Boolean) of object;

  /// Editor fuer das Umbenennen (Enter/Esc gehoeren ihm, nicht dem Dialog).
  TPPGTreeEdit = class(TEdit)
  private
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure DoExit; override;
  end;

  TPPGCustomTreeView = class(TPPGCustomItemList)
  private
    FItems: TPPGTreeNodes;
    FRows: TList;
    FGen: Cardinal;
    FRowsDirty: Boolean;
    FHasDetail: Boolean;
    FIndent: Integer;
    FShowLines: Boolean;
    FShowRoot: Boolean;
    FShowButtons: Boolean;
    FCheckBoxes: Boolean;
    FAutoCheck: Boolean;
    FReadOnly: Boolean;
    FRowSelect: Boolean;
    FHideSelection: Boolean;
    FHotTrack: Boolean;
    FToolTips: Boolean;
    FOnCustomDrawNode: TPPGTVCustomDrawEvent;
    FAutoExpand: Boolean;
    FMultiSelect: Boolean;
    FExpandAnim: TPPGAnimation;
    FAnimNode: TPPGTreeNode;
    FAnimFrom: Single;
    FAnimTo: Single;
    FEditor: TPPGTreeEdit;
    FEditNode: TPPGTreeNode;
    FLastSelected: TPPGTreeNode;
    FUiaNodes: TDictionary<Integer, TPPGTreeNode>; // UIA-Nummer -> Knoten
    FUiaNext: Integer;
    FOnChange: TPPGTVChangedEvent;
    FOnChanging: TPPGTVChangingEvent;
    FOnExpanding: TPPGTVExpandingEvent;
    FOnExpanded: TPPGTVExpandedEvent;
    FOnCollapsing: TPPGTVCollapsingEvent;
    FOnCollapsed: TPPGTVExpandedEvent;
    FOnEditing: TPPGTVEditingEvent;
    FOnEdited: TPPGTVEditedEvent;
    FOnDeletion: TPPGTVExpandedEvent;
    FOnChecked: TPPGTVChangedEvent;
    FOnCompare: TPPGTVCompareEvent;
    FOnNodeDrop: TPPGTVNodeDropEvent;
    procedure SetRowSelect(const Value: Boolean);
    procedure SetHotTrack(const Value: Boolean);
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure SetItems(const Value: TPPGTreeNodes);
    procedure SetIndent(const Value: Integer);
    procedure SetShowLines(const Value: Boolean);
    procedure SetShowRoot(const Value: Boolean);
    procedure SetShowButtons(const Value: Boolean);
    procedure SetCheckBoxes(const Value: Boolean);
    procedure SetHideSelection(const Value: Boolean);
    procedure SetMultiSelect(const Value: Boolean);
    function GetSelected: TPPGTreeNode;
    procedure SetSelected(const Value: TPPGTreeNode);
    function GetTopItem: TPPGTreeNode;
    procedure SetTopItem(const Value: TPPGTreeNode);
    procedure ExpandAnimStep(Sender: TObject);
    procedure StructureChanged;
    procedure NodeChanged(Node: TPPGTreeNode);
    procedure NodeDeleting(Node: TPPGTreeNode);
    procedure NodeAttached(Node: TPPGTreeNode);
    function IndentPx: Integer;
    function ColumnLeft(const Row: TRect; Column: Integer): Integer;
    function ExpanderRect(Node: TPPGTreeNode; const Row: TRect): TRect;
    function CheckRect(Node: TPPGTreeNode; const Row: TRect): TRect;
    function NodeColumn(Node: TPPGTreeNode): Integer;
    function ShowsButton(Node: TPPGTreeNode): Boolean;
    procedure PaintLines(const ACanvas: IPPGCanvas; Node: TPPGTreeNode; const Row: TRect;
      Color: TColor);
    procedure UpdateCheckParents(Node: TPPGTreeNode);
    procedure RecalcChecksFrom(P: TPPGTreeNode);
    /// Kinder hinzugefuegt/entfernt: Kaestchen der Eltern neu berechnen.
    procedure ChildrenChanged(P: TPPGTreeNode);
    procedure SetDescendantChecks(Node: TPPGTreeNode; State: TCheckBoxState);
    procedure SelectByUser(Node: TPPGTreeNode);
    procedure SortList(L: TList; Recurse: Boolean);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Loaded; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DblClick; override;
    procedure Scrolled; override;
    { TPPGCustomItemList }
    procedure GetItemData(Index: Integer; var Data: TPPGItemData); override;
    function TwoLineItems: Boolean; override;
    function ItemIndent(Index: Integer; const Data: TPPGItemData): Integer; override;
    function ItemHighlightRect(Index: Integer; const R: TRect; const Data: TPPGItemData): TRect; override;
    function ItemPaintSelected(Index: Integer): Boolean; override;
    function HasCustomDraw: Boolean; override;
    function DoCustomDrawItem(const ACanvas: IPPGCanvas; Index: Integer; const R: TRect;
      State: TPPGItemDrawState; var Style: TPPGDrawStyle): Boolean; override;
    function ItemExtraFontStyle(Index: Integer; Hot: Boolean): TFontStyles; override;
    procedure PaintItem(const ACanvas: IPPGCanvas; Index: Integer; const R: TRect;
      const Data: TPPGItemData; const Info: TPPGItemPaintInfo); override;
    function ItemMouseDown(Index: Integer; Shift: TShiftState; X, Y: Integer): Boolean; override;
    function ItemSpaceKey(Index: Integer): Boolean; override;
    function ItemHorzKey(Index: Integer; Key: Word; Shift: TShiftState): Boolean; override;
    function CanChangeFocusTo(Index: Integer): Boolean; override;
    procedure UserSelectionChanged; override;
    function DropTargetAt(Y: Integer; out Inside: Boolean): Integer; override;
    function DoDropAt(FromIndex, TargetRow: Integer; Inside: Boolean): Boolean; override;
    procedure DoAccChildAction(Index: Integer); override;
    { UI Automation: Baum mit Knoten (Art 1, A = UIA-Nummer des Knotens).
      Kinder eines Knotens sind nur bei aufgeklapptem Knoten sichtbar. }
    function UiaRowOf(const Id: TPPGUiaId): Integer; override;
    function UiaIdOfRow(Row: Integer): TPPGUiaId; override;
    function UiaParent(const Id: TPPGUiaId): TPPGUiaId; override;
    function UiaChildCount(const Id: TPPGUiaId): Integer; override;
    function UiaChild(const Id: TPPGUiaId; Index: Integer): TPPGUiaId; override;
    function UiaIndexInParent(const Id: TPPGUiaId): Integer; override;
    function UiaControlType(const Id: TPPGUiaId): Integer; override;
    function UiaProperty(const Id: TPPGUiaId; PropertyId: Integer; out Value: OleVariant): Boolean; override;
    function UiaHasPattern(const Id: TPPGUiaId; PatternId: Integer): Boolean; override;
    function UiaExpandState(const Id: TPPGUiaId): Integer; override;
    procedure UiaExecute(const Id: TPPGUiaId; Action: TPPGUiaAction; const Value: string); override;
    /// Stabile UIA-Nummer eines Knotens (wird beim ersten Bedarf vergeben).
    function NodeUiaId(Node: TPPGTreeNode): Integer;
    /// Knoten zu einer UIA-Nummer; nil = geloescht oder unbekannt.
    function NodeFromUiaId(AId: Integer): TPPGTreeNode;
    function AccRole: Integer; override;
    function AccChildRole(Id: Integer): Integer; override;
    function AccChildState(Id: Integer): Integer; override;
    function AccChildDefaultAction(Id: Integer): string; override;
    { Baum }
    /// Zeilen (sichtbare Knoten) neu aufbauen; Auswahl bleibt an den Knoten.
    procedure RebuildRows;
    /// Aufklappen/Zuklappen; ByUser: mit Animation des Pfeils.
    function DoExpand(Node: TPPGTreeNode; Recurse, ByUser: Boolean): Boolean;
    function DoCollapse(Node: TPPGTreeNode; Recurse, ByUser: Boolean): Boolean;
    procedure ToggleNode(Node: TPPGTreeNode; ByUser: Boolean);
    procedure SetNodeCheck(Node: TPPGTreeNode; State: TCheckBoxState; ByUser: Boolean);
    procedure Change(Node: TPPGTreeNode); virtual;
    procedure EditorKey(Key: Word);

    property Items: TPPGTreeNodes read FItems write SetItems;
    property Indent: Integer read FIndent write SetIndent default 19;
    property ShowLines: Boolean read FShowLines write SetShowLines default False;
    property ShowRoot: Boolean read FShowRoot write SetShowRoot default True;
    property ShowButtons: Boolean read FShowButtons write SetShowButtons default True;
    property CheckBoxes: Boolean read FCheckBoxes write SetCheckBoxes default False;
    property AutoCheck: Boolean read FAutoCheck write FAutoCheck default True;
    property ReadOnly: Boolean read FReadOnly write FReadOnly default False;
    /// True: Auswahl und Hover ueber die ganze Zeile; False: nur hinter Bild und Text
    /// (wie TTreeView ohne RowSelect).
    property RowSelect: Boolean read FRowSelect write SetRowSelect default True;
    property HideSelection: Boolean read FHideSelection write SetHideSelection default False;
    /// Wie TTreeView: Knoten unter der Maus unterstrichen.
    property HotTrack: Boolean read FHotTrack write SetHotTrack default False;
    /// Wie TTreeView: abgeschnittene Knotentexte als Hinweis (braucht ShowHint).
    property ToolTips: Boolean read FToolTips write FToolTips default True;
    /// Vor dem Zeichnen jedes Knotens: Style anpassen oder selbst zeichnen
    /// (Pfeil, Linien und Kaestchen zeichnet der Baum immer).
    property OnCustomDrawNode: TPPGTVCustomDrawEvent read FOnCustomDrawNode write FOnCustomDrawNode;
    /// Beim Waehlen per Tastatur/Maus automatisch aufklappen.
    property AutoExpand: Boolean read FAutoExpand write FAutoExpand default False;
    property MultiSelect: Boolean read FMultiSelect write SetMultiSelect default False;
    property OnChange: TPPGTVChangedEvent read FOnChange write FOnChange;
    property OnChanging: TPPGTVChangingEvent read FOnChanging write FOnChanging;
    property OnExpanding: TPPGTVExpandingEvent read FOnExpanding write FOnExpanding;
    property OnExpanded: TPPGTVExpandedEvent read FOnExpanded write FOnExpanded;
    property OnCollapsing: TPPGTVCollapsingEvent read FOnCollapsing write FOnCollapsing;
    property OnCollapsed: TPPGTVExpandedEvent read FOnCollapsed write FOnCollapsed;
    property OnEditing: TPPGTVEditingEvent read FOnEditing write FOnEditing;
    property OnEdited: TPPGTVEditedEvent read FOnEdited write FOnEdited;
    property OnDeletion: TPPGTVExpandedEvent read FOnDeletion write FOnDeletion;
    property OnItemCheck: TPPGTVChangedEvent read FOnChecked write FOnChecked;
    property OnCompare: TPPGTVCompareEvent read FOnCompare write FOnCompare;
    property OnNodeDrop: TPPGTVNodeDropEvent read FOnNodeDrop write FOnNodeDrop;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure FullExpand;
    procedure FullCollapse;
    /// Sortiert nach Text (bzw. OnCompare); Recurse = auch alle Kinder.
    procedure AlphaSort(Recurse: Boolean = True);
    /// Knoten unter dem Punkt (Client), nil = keiner.
    function GetNodeAt(X, Y: Integer): TPPGTreeNode;
    /// Zeile eines Knotens (-1 = nicht sichtbar).
    function RowOfNode(Node: TPPGTreeNode): Integer;
    function NodeOfRow(Row: Integer): TPPGTreeNode;
    /// Lage eines Knotens in Client-Koordinaten (leer = nicht sichtbar).
    function NodeRect(Node: TPPGTreeNode): TRect;
    function EditNode(Node: TPPGTreeNode): Boolean;
    procedure EndEdit(Accept: Boolean);
    function IsEditing: Boolean;
    property Editor: TPPGTreeEdit read FEditor;
    property Selected: TPPGTreeNode read GetSelected write SetSelected;
    property TopItem: TPPGTreeNode read GetTopItem write SetTopItem;
    /// Anzahl sichtbarer Zeilen.
    property RowCount: Integer read ItemCount;
  end;

  TPPGTreeView = class(TPPGCustomTreeView)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Images;
    property AllowMarkup;
    property AllowReorder;
    property Styles;
    property ScrollBarMode;
    property SmoothScrolling;
    property HighContrastSupport;
    { wie TTreeView }
    property Align;
    property Anchors;
    property AutoCheck;
    property AutoExpand;
    property BiDiMode;
    property BorderStyle;
    property CheckBoxes;
    property Color default clWindow;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property HideSelection;
    property HotTrack;
    property Indent;
    property ItemHeight;
    property Items;
    property MultiSelect;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property RowSelect;
    property ShowButtons;
    property ShowHint;
    property ShowLines;
    property ShowRoot;
    property ToolTips;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Touch;
    property OnGesture;
    property OnChange;
    property OnChanging;
    property OnItemCheck;
    property OnClick;
    property OnCollapsed;
    property OnCollapsing;
    property OnCompare;
    property OnCustomDrawNode;
    property OnContextPopup;
    property OnDblClick;
    property OnDeletion;
    property OnDragDrop;
    property OnDragOver;
    property OnEdited;
    property OnEditing;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnExpanded;
    property OnExpanding;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnNodeDrop;
    property OnScroll;
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

uses
  PPG.Lang,
  System.SysUtils, System.Math, Winapi.oleacc, PPG.UIA.Intf,
  PPG.Consts, PPG.Exceptions, PPG.Appearance, PPG.DpiUtils, PPG.Markup,
  PPG.Selection, PPG.Render.Registry, PPG.Render.Gdi, Vcl.Forms;

type
  /// Zeilen des Baums als Quelle der Listen-Basis.
  TPPGTreeSource = class(TPPGItemSourceBase)
  private
    FOwner: TPPGCustomTreeView;
  public
    function Count: Integer; override;
    procedure GetItem(Index: Integer; var Data: TPPGItemData); override;
  end;

const
  BoxSize = 16;   // logische px (Kaestchen)
  ColLeft = 6;    // logische px vom Zeilenrand bis zur ersten Spalte

function TPPGTreeSource.Count: Integer;
begin
  if (FOwner = nil) or (FOwner.FRows = nil) then
    Result := 0
  else
    Result := FOwner.FRows.Count;
end;

procedure TPPGTreeSource.GetItem(Index: Integer; var Data: TPPGItemData);
begin
  if FOwner <> nil then
    FOwner.GetItemData(Index, Data);
end;

{ Kodierung einer Knotenzeile fuer die DFM }

function EscapeField(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
    case S[I] of
      '\': Result := Result + '\\';
      '|': Result := Result + '\p';
      #13: Result := Result + '\r';
      #10: Result := Result + '\n';
    else
      Result := Result + S[I];
    end;
end;

function UnescapeField(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(S) do
  begin
    if (S[I] = '\') and (I < Length(S)) then
    begin
      Inc(I);
      case S[I] of
        'p': Result := Result + '|';
        'r': Result := Result + #13;
        'n': Result := Result + #10;
      else
        Result := Result + S[I];
      end;
    end
    else
      Result := Result + S[I];
    Inc(I);
  end;
end;

procedure SplitFields(const S: string; Fields: TStrings);
var
  I, Start: Integer;
begin
  Fields.Clear;
  Start := 1;
  I := 1;
  while I <= Length(S) do
  begin
    if (S[I] = '\') and (I < Length(S)) then
      Inc(I)
    else if S[I] = '|' then
    begin
      Fields.Add(Copy(S, Start, I - Start));
      Start := I + 1;
    end;
    Inc(I);
  end;
  Fields.Add(Copy(S, Start, MaxInt));
end;

{ TPPGTreeNode }

constructor TPPGTreeNode.Create(AOwner: TPPGTreeNodes);
begin
  inherited Create;
  FOwner := AOwner;
  FImageIndex := -1;
  FSelectedIndex := -1;
  FEnabled := True;
  FRow := -1;
  FColor := clDefault;
  FTextColor := clDefault;
end;

destructor TPPGTreeNode.Destroy;
begin
  FreeAndNil(FChildren);
  inherited Destroy;
end;

procedure TPPGTreeNode.Assign(Source: TPersistent);
var
  S: TPPGTreeNode;
begin
  if Source is TPPGTreeNode then
  begin
    S := TPPGTreeNode(Source);
    FText := S.FText;
    FDetail := S.FDetail;
    FBadge := S.FBadge;
    FImageIndex := S.FImageIndex;
    FSelectedIndex := S.FSelectedIndex;
    FCheckState := S.FCheckState;
    FEnabled := S.FEnabled;
    FHasChildren := S.FHasChildren;
    FData := S.FData;
    FColor := S.FColor;
    FTextColor := S.FTextColor;
    FFontStyle := S.FFontStyle;
    Changed;
  end
  else
    inherited Assign(Source);
end;

function TPPGTreeNode.GetTreeView: TPPGCustomTreeView;
begin
  if FOwner = nil then
    Result := nil
  else
    Result := FOwner.FOwner;
end;

procedure TPPGTreeNode.Changed;
begin
  if (FOwner <> nil) and (FOwner.FOwner <> nil) then
    FOwner.FOwner.NodeChanged(Self);
end;

function TPPGTreeNode.Siblings: TList;
begin
  if FParent <> nil then
    Result := FParent.FChildren
  else if FOwner <> nil then
    Result := FOwner.FRoots
  else
    Result := nil;
end;

function TPPGTreeNode.GetCount: Integer;
begin
  if FChildren = nil then
    Result := 0
  else
    Result := FChildren.Count;
end;

function TPPGTreeNode.GetItem(Index: Integer): TPPGTreeNode;
begin
  if (Index < 0) or (Index >= Count) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, Count - 1]);
  Result := TPPGTreeNode(FChildren[Index]);
end;

function TPPGTreeNode.GetIndex: Integer;
var
  L: TList;
begin
  L := Siblings;
  if L = nil then
    Result := -1
  else
    Result := L.IndexOf(Self);
end;

function TPPGTreeNode.GetLevel: Integer;
var
  P: TPPGTreeNode;
begin
  Result := 0;
  P := FParent;
  while P <> nil do
  begin
    Inc(Result);
    P := P.FParent;
  end;
end;

function TPPGTreeNode.GetAbsoluteIndex: Integer;
var
  N: TPPGTreeNode;
begin
  Result := -1;
  if FOwner = nil then
    Exit;
  N := FOwner.GetFirstNode;
  Result := 0;
  while (N <> nil) and (N <> Self) do
  begin
    N := N.GetNext;
    Inc(Result);
  end;
  if N = nil then
    Result := -1;
end;

function TPPGTreeNode.GetHasChildren: Boolean;
begin
  Result := (Count > 0) or FHasChildren;
end;

procedure TPPGTreeNode.SetHasChildren(const Value: Boolean);
begin
  if FHasChildren <> Value then
  begin
    FHasChildren := Value;
    Changed;
  end;
end;

procedure TPPGTreeNode.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    Changed;
  end;
end;

procedure TPPGTreeNode.SetDetail(const Value: string);
begin
  if FDetail <> Value then
  begin
    FDetail := Value;
    Changed;
  end;
end;

procedure TPPGTreeNode.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Changed;
  end;
end;

procedure TPPGTreeNode.SetTextColor(const Value: TColor);
begin
  if FTextColor <> Value then
  begin
    FTextColor := Value;
    Changed;
  end;
end;

procedure TPPGTreeNode.SetFontStyle(const Value: TFontStyles);
begin
  if FFontStyle <> Value then
  begin
    FFontStyle := Value;
    Changed;
  end;
end;

procedure TPPGTreeNode.SetBadge(const Value: string);
begin
  if FBadge <> Value then
  begin
    FBadge := Value;
    Changed;
  end;
end;

procedure TPPGTreeNode.SetImageIndex(const Value: Integer);
begin
  if FImageIndex <> Value then
  begin
    FImageIndex := Value;
    Changed;
  end;
end;

procedure TPPGTreeNode.SetSelectedIndex(const Value: Integer);
begin
  if FSelectedIndex <> Value then
  begin
    FSelectedIndex := Value;
    Changed;
  end;
end;

procedure TPPGTreeNode.SetEnabled(const Value: Boolean);
begin
  if FEnabled <> Value then
  begin
    FEnabled := Value;
    Changed;
  end;
end;

procedure TPPGTreeNode.SetExpanded(const Value: Boolean);
begin
  if Value then
    Expand(False)
  else
    Collapse(False);
end;

function TPPGTreeNode.GetChecked: Boolean;
begin
  Result := FCheckState = cbChecked;
end;

procedure TPPGTreeNode.SetChecked(const Value: Boolean);
begin
  if Value then
    SetCheckState(cbChecked)
  else
    SetCheckState(cbUnchecked);
end;

procedure TPPGTreeNode.SetCheckState(const Value: TCheckBoxState);
begin
  if TreeView <> nil then
    TreeView.SetNodeCheck(Self, Value, False)
  else
    FCheckState := Value;
end;

function TPPGTreeNode.GetSelected: Boolean;
var
  R: Integer;
begin
  Result := False;
  if TreeView = nil then
    Exit;
  R := TreeView.RowOfNode(Self);
  Result := (R >= 0) and TreeView.Selection.Selected[R];
end;

procedure TPPGTreeNode.SetSelected(const Value: Boolean);
var
  R: Integer;
begin
  if TreeView = nil then
    Exit;
  if Value and not TreeView.MultiSelect then
    TreeView.Selected := Self
  else
  begin
    MakeVisible;
    R := TreeView.RowOfNode(Self);
    if R >= 0 then
      TreeView.Selection.Selected[R] := Value;
  end;
end;

function TPPGTreeNode.GetFocused: Boolean;
begin
  Result := (TreeView <> nil) and (TreeView.NodeOfRow(TreeView.Selection.Focus) = Self);
end;

function TPPGTreeNode.GetFirstChild: TPPGTreeNode;
begin
  if Count = 0 then
    Result := nil
  else
    Result := TPPGTreeNode(FChildren[0]);
end;

function TPPGTreeNode.GetLastChild: TPPGTreeNode;
begin
  if Count = 0 then
    Result := nil
  else
    Result := TPPGTreeNode(FChildren[FChildren.Count - 1]);
end;

function TPPGTreeNode.GetNextSibling: TPPGTreeNode;
var
  L: TList;
  I: Integer;
begin
  Result := nil;
  L := Siblings;
  if L = nil then
    Exit;
  I := L.IndexOf(Self);
  if (I >= 0) and (I < L.Count - 1) then
    Result := TPPGTreeNode(L[I + 1]);
end;

function TPPGTreeNode.GetPrevSibling: TPPGTreeNode;
var
  L: TList;
  I: Integer;
begin
  Result := nil;
  L := Siblings;
  if L = nil then
    Exit;
  I := L.IndexOf(Self);
  if I > 0 then
    Result := TPPGTreeNode(L[I - 1]);
end;

function TPPGTreeNode.GetNext: TPPGTreeNode;
var
  N: TPPGTreeNode;
begin
  Result := GetFirstChild;
  if Result <> nil then
    Exit;
  N := Self;
  while N <> nil do
  begin
    Result := N.GetNextSibling;
    if Result <> nil then
      Exit;
    N := N.FParent;
  end;
end;

function TPPGTreeNode.GetPrev: TPPGTreeNode;
begin
  Result := GetPrevSibling;
  if Result = nil then
    Result := FParent
  else
    while Result.Count > 0 do
      Result := Result.GetLastChild;
end;

function TPPGTreeNode.GetNextVisible: TPPGTreeNode;
var
  R: Integer;
begin
  Result := nil;
  if TreeView = nil then
    Exit;
  R := TreeView.RowOfNode(Self);
  if R >= 0 then
    Result := TreeView.NodeOfRow(R + 1);
end;

function TPPGTreeNode.GetPrevVisible: TPPGTreeNode;
var
  R: Integer;
begin
  Result := nil;
  if TreeView = nil then
    Exit;
  R := TreeView.RowOfNode(Self);
  if R > 0 then
    Result := TreeView.NodeOfRow(R - 1);
end;

function TPPGTreeNode.HasAsParent(Value: TPPGTreeNode): Boolean;
var
  P: TPPGTreeNode;
begin
  Result := False;
  P := FParent;
  while P <> nil do
  begin
    if P = Value then
      Exit(True);
    P := P.FParent;
  end;
end;

function TPPGTreeNode.IndexOf(Value: TPPGTreeNode): Integer;
begin
  if FChildren = nil then
    Result := -1
  else
    Result := FChildren.IndexOf(Value);
end;

function TPPGTreeNode.IsVisible: Boolean;
begin
  Result := (TreeView <> nil) and (TreeView.RowOfNode(Self) >= 0);
end;

procedure TPPGTreeNode.Expand(Recurse: Boolean);
begin
  if TreeView <> nil then
    TreeView.DoExpand(Self, Recurse, False)
  else
    FExpanded := True;
end;

procedure TPPGTreeNode.Collapse(Recurse: Boolean);
begin
  if TreeView <> nil then
    TreeView.DoCollapse(Self, Recurse, False)
  else
    FExpanded := False;
end;

procedure TPPGTreeNode.MakeVisible;
var
  P: TPPGTreeNode;
  R: Integer;
begin
  if TreeView = nil then
    Exit;
  TreeView.Items.BeginUpdate;
  try
    P := FParent;
    while P <> nil do
    begin
      if not P.FExpanded then
        TreeView.DoExpand(P, False, False);
      P := P.FParent;
    end;
  finally
    TreeView.Items.EndUpdate;
  end;
  R := TreeView.RowOfNode(Self);
  if R >= 0 then
    TreeView.MakeItemVisible(R);
end;

procedure TPPGTreeNode.Delete;
begin
  if FOwner <> nil then
    FOwner.Delete(Self)
  else
    Free;
end;

procedure TPPGTreeNode.DeleteChildren;
begin
  if FOwner = nil then
    Exit;
  FOwner.BeginUpdate;
  try
    while Count > 0 do
      FOwner.Delete(GetLastChild);
  finally
    FOwner.EndUpdate;
  end;
end;

procedure TPPGTreeNode.MoveTo(Destination: TPPGTreeNode; Mode: TNodeAttachMode);
var
  OldParent: TPPGTreeNode;
begin
  if (FOwner = nil) or (Destination = Self) then
    Exit;
  if (Destination <> nil) and Destination.HasAsParent(Self) then
    raise EPPGError.Create(PPGStr(@SPPGTreeMoveIntoChild));
  FOwner.BeginUpdate;
  try
    OldParent := FParent;
    FOwner.Detach(Self);
    if FOwner.FOwner <> nil then
      FOwner.FOwner.ChildrenChanged(OldParent);
    FOwner.Attach(Self, Destination, Mode);
  finally
    FOwner.EndUpdate;
  end;
end;

function TPPGTreeNode.EditText: Boolean;
begin
  Result := (TreeView <> nil) and TreeView.EditNode(Self);
end;

{ TPPGTreeNodes }

constructor TPPGTreeNodes.Create(AOwner: TPPGCustomTreeView);
begin
  inherited Create;
  FOwner := AOwner;
  FRoots := TList.Create;
end;

destructor TPPGTreeNodes.Destroy;
begin
  // Ohne Meldungen an den Baum (der wird gerade freigegeben)
  FOwner := nil;
  Clear;
  FreeAndNil(FRoots);
  inherited Destroy;
end;

function TPPGTreeNodes.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TPPGTreeNodes.Changed;
begin
  FCacheNode := nil;
  if (FUpdateCount = 0) and (FOwner <> nil) then
    FOwner.StructureChanged;
end;

procedure TPPGTreeNodes.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TPPGTreeNodes.EndUpdate;
begin
  if FUpdateCount > 0 then
    Dec(FUpdateCount);
  if FUpdateCount = 0 then
    Changed;
end;

function TPPGTreeNodes.Attach(Node, Dest: TPPGTreeNode; Mode: TNodeAttachMode): TPPGTreeNode;
var
  L: TList;
  I: Integer;
begin
  Result := Node;
  Node.FOwner := Self;
  case Mode of
    naAddChild, naAddChildFirst:
      if Dest = nil then
      begin
        Node.FParent := nil;
        if Mode = naAddChild then
          FRoots.Add(Node)
        else
          FRoots.Insert(0, Node);
      end
      else
      begin
        Node.FParent := Dest;
        if Dest.FChildren = nil then
          Dest.FChildren := TList.Create;
        if Mode = naAddChild then
          Dest.FChildren.Add(Node)
        else
          Dest.FChildren.Insert(0, Node);
      end;
  else
    begin
      // Geschwister von Dest (nil = Wurzelebene)
      if Dest = nil then
      begin
        Node.FParent := nil;
        L := FRoots;
      end
      else
      begin
        Node.FParent := Dest.FParent;
        L := Dest.Siblings;
      end;
      case Mode of
        naAddFirst:
          L.Insert(0, Node);
        naInsert:
          begin
            if Dest = nil then
              I := L.Count
            else
              I := L.IndexOf(Dest);
            if I < 0 then
              I := L.Count;
            L.Insert(I, Node);
          end;
      else
        L.Add(Node);
      end;
    end;
  end;
  FCacheNode := nil;
  if FOwner <> nil then
  begin
    FOwner.ChildrenChanged(Node.FParent);
    FOwner.NodeAttached(Node);
  end;
end;

procedure TPPGTreeNodes.Detach(Node: TPPGTreeNode);
var
  L: TList;
begin
  L := Node.Siblings;
  if L <> nil then
    L.Remove(Node);
  Node.FParent := nil;
end;

function TPPGTreeNodes.Add(Sibling: TPPGTreeNode; const S: string): TPPGTreeNode;
begin
  Result := AddObject(Sibling, S, nil);
end;

function TPPGTreeNodes.AddObject(Sibling: TPPGTreeNode; const S: string;
  Ptr: Pointer): TPPGTreeNode;
begin
  Result := TPPGTreeNode.Create(Self);
  Result.FText := S;
  Result.FData := Ptr;
  Inc(FCount);
  Attach(Result, Sibling, naAdd);
end;

function TPPGTreeNodes.AddFirst(Sibling: TPPGTreeNode; const S: string): TPPGTreeNode;
begin
  Result := TPPGTreeNode.Create(Self);
  Result.FText := S;
  Inc(FCount);
  Attach(Result, Sibling, naAddFirst);
end;

function TPPGTreeNodes.AddChild(Parent: TPPGTreeNode; const S: string): TPPGTreeNode;
begin
  Result := AddChildObject(Parent, S, nil);
end;

function TPPGTreeNodes.AddChildObject(Parent: TPPGTreeNode; const S: string;
  Ptr: Pointer): TPPGTreeNode;
begin
  Result := TPPGTreeNode.Create(Self);
  Result.FText := S;
  Result.FData := Ptr;
  Inc(FCount);
  Attach(Result, Parent, naAddChild);
end;

function TPPGTreeNodes.AddChildFirst(Parent: TPPGTreeNode; const S: string): TPPGTreeNode;
begin
  Result := TPPGTreeNode.Create(Self);
  Result.FText := S;
  Inc(FCount);
  Attach(Result, Parent, naAddChildFirst);
end;

function TPPGTreeNodes.Insert(Sibling: TPPGTreeNode; const S: string): TPPGTreeNode;
begin
  Result := TPPGTreeNode.Create(Self);
  Result.FText := S;
  Inc(FCount);
  Attach(Result, Sibling, naInsert);
end;

procedure TPPGTreeNodes.FreeNode(Node: TPPGTreeNode);
var
  Child: TPPGTreeNode;
begin
  // Kinder zuerst (OnDeletion von innen nach aussen, wie TTreeView).
  // Audit 08.10.2026: Jedes Kind verlaesst die Liste vor seiner Freigabe;
  // vorher sah OnDeletion (Anwendercode) bereits freigegebene Geschwister.
  // Parent bleibt im OnDeletion lesbar.
  while Node.Count > 0 do
  begin
    Child := TPPGTreeNode(Node.FChildren[Node.Count - 1]);
    Node.FChildren.Delete(Node.Count - 1);
    FreeNode(Child);
  end;
  FCacheNode := nil;
  if FOwner <> nil then
    FOwner.NodeDeleting(Node);
  FCacheNode := nil;
  Dec(FCount);
  Node.FOwner := nil;
  Node.Free;
end;

procedure TPPGTreeNodes.Delete(Node: TPPGTreeNode);
var
  P: TPPGTreeNode;
begin
  if (Node = nil) or (Node.FOwner <> Self) then
    Exit;
  P := Node.FParent;
  Detach(Node);
  FreeNode(Node);
  if FOwner <> nil then
    FOwner.ChildrenChanged(P);
  Changed;
end;

procedure TPPGTreeNodes.Clear;
var
  N: TPPGTreeNode;
begin
  if FRoots = nil then
    Exit;
  BeginUpdate;
  try
    // Wurzel vor der Freigabe aus FRoots nehmen (siehe FreeNode)
    while FRoots.Count > 0 do
    begin
      N := TPPGTreeNode(FRoots[FRoots.Count - 1]);
      FRoots.Delete(FRoots.Count - 1);
      FreeNode(N);
    end;
    FCount := 0;
    FCacheNode := nil;
  finally
    EndUpdate;
  end;
end;

function TPPGTreeNodes.GetFirstNode: TPPGTreeNode;
begin
  if FRoots.Count = 0 then
    Result := nil
  else
    Result := TPPGTreeNode(FRoots[0]);
end;

function TPPGTreeNodes.RootCount: Integer;
begin
  Result := FRoots.Count;
end;

function TPPGTreeNodes.Root(Index: Integer): TPPGTreeNode;
begin
  Result := TPPGTreeNode(FRoots[Index]);
end;

function TPPGTreeNodes.GetItem(Index: Integer): TPPGTreeNode;
var
  N: TPPGTreeNode;
  I: Integer;
begin
  if (Index < 0) or (Index >= FCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, FCount - 1]);
  // Fortlaufender Zugriff (for I := 0 to Count - 1) ueber den letzten Treffer
  if (FCacheNode <> nil) and (FCacheIndex <= Index) then
  begin
    N := FCacheNode;
    I := FCacheIndex;
  end
  else
  begin
    N := GetFirstNode;
    I := 0;
  end;
  while (N <> nil) and (I < Index) do
  begin
    N := N.GetNext;
    Inc(I);
  end;
  FCacheNode := N;
  FCacheIndex := Index;
  Result := N;
end;

procedure TPPGTreeNodes.Assign(Source: TPersistent);

  procedure CopyChildren(SrcParent: TPPGTreeNode; SrcList: TList; DstParent: TPPGTreeNode);
  var
    I: Integer;
    S, D: TPPGTreeNode;
  begin
    for I := 0 to SrcList.Count - 1 do
    begin
      S := TPPGTreeNode(SrcList[I]);
      D := AddChild(DstParent, S.Text);
      D.Assign(S);
      D.FExpanded := S.FExpanded;
      if S.FChildren <> nil then
        CopyChildren(S, S.FChildren, D);
    end;
  end;

begin
  if Source is TPPGTreeNodes then
  begin
    BeginUpdate;
    try
      Clear;
      CopyChildren(nil, TPPGTreeNodes(Source).FRoots, nil);
    finally
      EndUpdate;
    end;
  end
  else
    inherited Assign(Source);
end;

procedure TPPGTreeNodes.DefineProperties(Filer: TFiler);

  function DoWrite: Boolean;
  begin
    if Filer.Ancestor is TPPGTreeNodes then
      Result := True // keine Vererbung von Knoten: immer vollstaendig
    else
      Result := FCount > 0;
  end;

begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('Nodes', ReadNodes, WriteNodes, DoWrite);
end;

procedure TPPGTreeNodes.WriteNodes(Writer: TWriter);
var
  N: TPPGTreeNode;
  Flags: string;
begin
  // Eine lesbare Zeile pro Knoten: Ebene|Flags|Bild|Bild gewaehlt|Text|Detail|Plakette
  Writer.WriteListBegin;
  N := GetFirstNode;
  while N <> nil do
  begin
    Flags := '';
    if N.FExpanded then
      Flags := Flags + 'E';
    case N.FCheckState of
      cbChecked: Flags := Flags + 'C';
      cbGrayed: Flags := Flags + 'G';
    end;
    if not N.FEnabled then
      Flags := Flags + 'D';
    if N.FHasChildren then
      Flags := Flags + 'H';
    Writer.WriteString(Format('%d|%s|%d|%d|%s|%s|%s', [N.Level, Flags, N.FImageIndex,
      N.FSelectedIndex, EscapeField(N.FText), EscapeField(N.FDetail),
      EscapeField(N.FBadge)]));
    N := N.GetNext;
  end;
  Writer.WriteListEnd;
end;

procedure TPPGTreeNodes.ReadNodes(Reader: TReader);
var
  Fields: TStringList;
  Stack: TList;
  Lvl: Integer;
  N, P: TPPGTreeNode;
  Flags: string;
begin
  Fields := TStringList.Create;
  Stack := TList.Create;
  BeginUpdate;
  try
    Clear;
    Reader.ReadListBegin;
    while not Reader.EndOfList do
    begin
      SplitFields(Reader.ReadString, Fields);
      if Fields.Count < 5 then
        Continue; // beschaedigte Zeile: auslassen statt abbrechen
      Lvl := StrToIntDef(Fields[0], 0);
      if Lvl < 0 then
        Lvl := 0;
      if Lvl > Stack.Count then
        Lvl := Stack.Count; // Luecke in den Ebenen: unter den letzten haengen
      if Lvl = 0 then
        P := nil
      else
        P := TPPGTreeNode(Stack[Lvl - 1]);
      N := AddChild(P, UnescapeField(Fields[4]));
      Flags := Fields[1];
      N.FExpanded := Pos('E', Flags) > 0;
      if Pos('C', Flags) > 0 then
        N.FCheckState := cbChecked
      else if Pos('G', Flags) > 0 then
        N.FCheckState := cbGrayed;
      N.FEnabled := Pos('D', Flags) = 0;
      N.FHasChildren := Pos('H', Flags) > 0;
      N.FImageIndex := StrToIntDef(Fields[2], -1);
      N.FSelectedIndex := StrToIntDef(Fields[3], -1);
      if Fields.Count > 5 then
        N.FDetail := UnescapeField(Fields[5]);
      if Fields.Count > 6 then
        N.FBadge := UnescapeField(Fields[6]);
      while Stack.Count > Lvl do
        Stack.Delete(Stack.Count - 1);
      Stack.Add(N);
    end;
    Reader.ReadListEnd;
  finally
    EndUpdate;
    Stack.Free;
    Fields.Free;
  end;
end;

{ TPPGTreeEdit }

procedure TPPGTreeEdit.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTALLKEYS;
end;

procedure TPPGTreeEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if (Key = VK_RETURN) or (Key = VK_ESCAPE) then
  begin
    if Owner is TPPGCustomTreeView then
      TPPGCustomTreeView(Owner).EditorKey(Key);
    Key := 0;
  end;
end;

procedure TPPGTreeEdit.KeyPress(var Key: Char);
begin
  inherited KeyPress(Key);
  if (Key = #13) or (Key = #27) then
    Key := #0; // kein Signalton
end;

procedure TPPGTreeEdit.DoExit;
begin
  inherited DoExit;
  // Fokusverlust uebernimmt (wie Explorer)
  if Owner is TPPGCustomTreeView then
    TPPGCustomTreeView(Owner).EndEdit(True);
end;

{ TPPGCustomTreeView }

constructor TPPGCustomTreeView.Create(AOwner: TComponent);
var
  Src: TPPGTreeSource;
begin
  inherited Create(AOwner);
  FIndent := 19;
  FShowRoot := True;
  FShowButtons := True;
  FAutoCheck := True;
  FRowSelect := True;
  FToolTips := True;
  FRows := TList.Create;
  FItems := TPPGTreeNodes.Create(Self);
  FExpandAnim := TPPGAnimation.Create(Self);
  FExpandAnim.OnStep := ExpandAnimStep;
  Src := TPPGTreeSource.Create;
  Src.FOwner := Self;
  SetSource(Src);
end;

destructor TPPGCustomTreeView.Destroy;
begin
  if Source <> nil then
    TPPGTreeSource(Source as TObject).FOwner := nil;
  SetSource(nil);
  if FExpandAnim <> nil then
    FExpandAnim.OnStep := nil;
  FreeAndNil(FExpandAnim);
  FEditNode := nil;
  FAnimNode := nil;
  FLastSelected := nil;
  FreeAndNil(FItems); // ohne OnDeletion (wie TTreeView beim Zerstoeren)
  FreeAndNil(FUiaNodes);
  FreeAndNil(FRows);
  inherited Destroy;
end;

procedure TPPGCustomTreeView.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Den Editor beim Umbenennen nie uebermalen
  Params.Style := Params.Style or WS_CLIPCHILDREN;
end;

procedure TPPGCustomTreeView.Loaded;
begin
  inherited Loaded;
  RebuildRows;
end;

procedure TPPGCustomTreeView.SetItems(const Value: TPPGTreeNodes);
begin
  FItems.Assign(Value);
end;

{ ---- Zeilen ---- }

function TPPGCustomTreeView.RowOfNode(Node: TPPGTreeNode): Integer;
begin
  if (Node <> nil) and (Node.FRowGen = FGen) and (Node.FRow >= 0) and
    (Node.FRow < FRows.Count) and (FRows[Node.FRow] = Node) then
    Result := Node.FRow
  else
    Result := -1;
end;

function TPPGCustomTreeView.NodeOfRow(Row: Integer): TPPGTreeNode;
begin
  if (FRows = nil) or (Row < 0) or (Row >= FRows.Count) then
    Result := nil
  else
    Result := TPPGTreeNode(FRows[Row]);
end;

procedure TPPGCustomTreeView.RebuildRows;
var
  SelNodes: TList;
  FocusNode, N, OldSel: TPPGTreeNode;
  I, R, FocusRow: Integer;
  Rows: array of Integer;

  procedure AddVisible(Node: TPPGTreeNode);
  var
    J: Integer;
  begin
    Node.FRow := FRows.Add(Node);
    Node.FRowGen := FGen;
    if Node.FDetail <> '' then
      FHasDetail := True;
    if Node.FExpanded and (Node.FChildren <> nil) then
      for J := 0 to Node.FChildren.Count - 1 do
        AddVisible(TPPGTreeNode(Node.FChildren[J]));
  end;

begin
  if (FItems = nil) or (csDestroying in ComponentState) then
    Exit;
  if FItems.FUpdateCount > 0 then
  begin
    FRowsDirty := True;
    Exit;
  end;
  FRowsDirty := False;
  OldSel := GetSelected;
  // Auswahl an den Knoten merken (Zeilen verschieben sich)
  SelNodes := TList.Create;
  try
    I := Selection.NextSelected(0);
    while I >= 0 do
    begin
      SelNodes.Add(NodeOfRow(I));
      I := Selection.NextSelected(I + 1);
    end;
    FocusNode := NodeOfRow(Selection.Focus);
    Inc(FGen);
    FRows.Clear;
    FHasDetail := False;
    for I := 0 to FItems.FRoots.Count - 1 do
      AddVisible(TPPGTreeNode(FItems.FRoots[I]));
    // Unsichtbar gewordene Knoten: Fokus/Auswahl wandert zum sichtbaren Vorfahren
    while (FocusNode <> nil) and (RowOfNode(FocusNode) < 0) do
      FocusNode := FocusNode.FParent;
    SetLength(Rows, 0);
    for I := 0 to SelNodes.Count - 1 do
    begin
      N := TPPGTreeNode(SelNodes[I]);
      if (N <> nil) and (N.FOwner = FItems) then
      begin
        while (N <> nil) and (RowOfNode(N) < 0) do
          N := N.FParent;
        R := RowOfNode(N);
        if R >= 0 then
        begin
          SetLength(Rows, Length(Rows) + 1);
          Rows[High(Rows)] := R;
        end;
      end;
    end;
  finally
    SelNodes.Free;
  end;
  FocusRow := RowOfNode(FocusNode);
  ItemsReset;
  ReplaceSelection(Rows, FocusRow);
  FLastSelected := GetSelected;
  // Auswahl ist durch das Zuklappen auf einen anderen Knoten gewandert
  if (OldSel <> nil) and (FLastSelected <> OldSel) and not (csLoading in ComponentState) then
    Change(FLastSelected);
end;

procedure TPPGCustomTreeView.StructureChanged;
begin
  RebuildRows;
end;

procedure TPPGCustomTreeView.NodeChanged(Node: TPPGTreeNode);
var
  R: Integer;
begin
  R := RowOfNode(Node);
  if R >= 0 then
  begin
    if (Node.FDetail <> '') and not FHasDetail then
      StructureChanged // Zeilen werden zweizeilig
    else
      ItemChanged(R);
  end;
end;

procedure TPPGCustomTreeView.NodeAttached(Node: TPPGTreeNode);
var
  P: TPPGTreeNode;
begin
  if FItems.FUpdateCount > 0 then
  begin
    FRowsDirty := True;
    Exit;
  end;
  // Unter einem zugeklappten bzw. unsichtbaren Eltern-Knoten aendert sich keine
  // Zeile: nur den Pfeil des Eltern-Knotens neu zeichnen (viele Add ohne
  // BeginUpdate bleiben so schnell)
  P := Node.FParent;
  if (P <> nil) and (not P.FExpanded or (RowOfNode(P) < 0)) then
  begin
    NodeChanged(P);
    Exit;
  end;
  RebuildRows;
end;

procedure TPPGCustomTreeView.NodeDeleting(Node: TPPGTreeNode);
begin
  // Zeile leeren: bis zum Neuaufbau keine haengenden Zeiger in der Zeilenliste
  if RowOfNode(Node) >= 0 then
    FRows[Node.FRow] := nil;
  if Node = FEditNode then
    EndEdit(False);
  if Node = FAnimNode then
  begin
    FAnimNode := nil;
    FExpandAnim.Stop;
  end;
  if Node = FLastSelected then
    FLastSelected := nil;
  // UIA-Elemente des Knotens antworten ab jetzt "nicht verfuegbar"
  if (Node.FUiaId <> 0) and (FUiaNodes <> nil) then
    FUiaNodes.Remove(Node.FUiaId);
  if Assigned(FOnDeletion) and not (csDestroying in ComponentState) then
    FOnDeletion(Self, Node);
end;

function TPPGCustomTreeView.TwoLineItems: Boolean;
begin
  Result := FHasDetail;
end;

procedure TPPGCustomTreeView.GetItemData(Index: Integer; var Data: TPPGItemData);
var
  N: TPPGTreeNode;
begin
  PPGInitItemData(Data);
  N := NodeOfRow(Index);
  if N = nil then
    Exit;
  Data.Text := N.FText;
  Data.Detail := N.FDetail;
  Data.Badge := N.FBadge;
  Data.ImageIndex := N.FImageIndex;
  if (N.FSelectedIndex >= 0) and Selection.Selected[Index] then
    Data.ImageIndex := N.FSelectedIndex;
  Data.Checked := N.FCheckState;
  Data.Enabled := N.FEnabled;
  Data.Data := N;
  Data.Color := N.FColor;
  Data.TextColor := N.FTextColor;
  Data.FontStyle := N.FFontStyle;
end;

{ ---- Geometrie ---- }

function TPPGCustomTreeView.IndentPx: Integer;
begin
  Result := PPGScale(FIndent, ScalePPI);
end;

function TPPGCustomTreeView.NodeColumn(Node: TPPGTreeNode): Integer;
begin
  // Spalte des Pfeils; ohne ShowRoot haben Wurzeln keine eigene Spalte
  Result := Node.Level;
  if not FShowRoot then
    Dec(Result);
end;

function TPPGCustomTreeView.ColumnLeft(const Row: TRect; Column: Integer): Integer;
begin
  if UseRightToLeftAlignment then
    Result := Row.Right - PPGScale(ColLeft, ScalePPI) - (Column + 1) * IndentPx
  else
    Result := Row.Left + PPGScale(ColLeft, ScalePPI) + Column * IndentPx;
end;

function TPPGCustomTreeView.ShowsButton(Node: TPPGTreeNode): Boolean;
begin
  Result := FShowButtons and Node.HasChildren and (NodeColumn(Node) >= 0);
end;

function TPPGCustomTreeView.ExpanderRect(Node: TPPGTreeNode; const Row: TRect): TRect;
var
  X: Integer;
begin
  X := ColumnLeft(Row, NodeColumn(Node));
  Result := Rect(X, Row.Top, X + IndentPx, Row.Bottom);
end;

function TPPGCustomTreeView.CheckRect(Node: TPPGTreeNode; const Row: TRect): TRect;
var
  X, S: Integer;
begin
  S := PPGScale(BoxSize, ScalePPI);
  X := ColumnLeft(Row, NodeColumn(Node) + 1) + PPGScale(2, ScalePPI);
  if UseRightToLeftAlignment then
    X := ColumnLeft(Row, NodeColumn(Node) + 1) + IndentPx - PPGScale(2, ScalePPI) - S;
  Result.Left := X;
  Result.Right := X + S;
  Result.Top := (Row.Top + Row.Bottom - S) div 2;
  Result.Bottom := Result.Top + S;
end;

procedure TPPGCustomTreeView.SetRowSelect(const Value: Boolean);
begin
  if FRowSelect <> Value then
  begin
    FRowSelect := Value;
    Invalidate;
  end;
end;

function TPPGCustomTreeView.ItemHighlightRect(Index: Integer; const R: TRect;
  const Data: TPPGItemData): TRect;
var
  Indent, W, PPI: Integer;
  F, Temp: TFont;
begin
  Result := R;
  if FRowSelect then
    Exit;
  // Nur Bild und Text hervorheben: Breite wie der Zeichner sie belegt
  PPI := ScalePPI;
  Indent := ItemIndent(Index, Data);
  Temp := nil;
  try
    F := PPGStyledFont(Font, Data.FontStyle, Temp);
    W := PPGMeasureTextNoCanvas(PPGStripMarkup(Data.Text), F, 0, False).cx;
  finally
    Temp.Free;
  end;
  Inc(W, PPGScale(PPGItemPadX + 10, PPI));
  if (Images <> nil) and (Data.ImageIndex >= 0) then
    Inc(W, Images.Width + PPGScale(6, PPI));
  if UseRightToLeftAlignment then
  begin
    Result.Right := R.Right - Indent;
    Result.Left := Max(R.Left, Result.Right - W);
  end
  else
  begin
    Result.Left := R.Left + Indent;
    Result.Right := Min(R.Right, Result.Left + W);
  end;
end;

function TPPGCustomTreeView.ItemIndent(Index: Integer; const Data: TPPGItemData): Integer;
var
  N: TPPGTreeNode;
begin
  N := NodeOfRow(Index);
  if N = nil then
    Exit(0);
  // Inhalt beginnt hinter der Pfeil-Spalte; der Zeichner fuegt PPGItemPadX hinzu
  Result := PPGScale(ColLeft, ScalePPI) + (NodeColumn(N) + 1) * IndentPx +
    PPGScale(2, ScalePPI) - PPGScale(PPGItemPadX, ScalePPI);
  if FCheckBoxes then
    Inc(Result, PPGScale(BoxSize + 6, ScalePPI));
  if Result < 0 then
    Result := 0;
end;

function TPPGCustomTreeView.NodeRect(Node: TPPGTreeNode): TRect;
begin
  Result := ItemRect(RowOfNode(Node));
end;

function TPPGCustomTreeView.GetNodeAt(X, Y: Integer): TPPGTreeNode;
begin
  Result := NodeOfRow(ItemAtPos(X, Y));
end;

{ ---- Zeichnen ---- }

function TPPGCustomTreeView.ItemPaintSelected(Index: Integer): Boolean;
begin
  Result := inherited ItemPaintSelected(Index) and not (FHideSelection and not Focused);
end;

procedure TPPGCustomTreeView.PaintLines(const ACanvas: IPPGCanvas; Node: TPPGTreeNode;
  const Row: TRect; Color: TColor);
var
  IR: IPPGItemRenderer;
  P: TPPGTreeNode;
  Col, CX, CY, X2: Integer;
  Pts: array[0..1] of TPoint;
begin
  IR := PPGItemRendererOf(Renderer);
  CY := (Row.Top + Row.Bottom) div 2;
  // Senkrechte Linien der Vorfahren, die noch Geschwister nach sich haben
  P := Node.FParent;
  while P <> nil do
  begin
    Col := NodeColumn(P);
    if (Col >= 0) and (P.GetNextSibling <> nil) then
    begin
      CX := ColumnLeft(Row, Col) + IndentPx div 2;
      Pts[0] := Point(CX, Row.Top);
      Pts[1] := Point(CX, Row.Bottom);
      IR.DrawTreeLine(ACanvas, Pts, Color, ScalePPI);
    end;
    P := P.FParent;
  end;
  Col := NodeColumn(Node);
  if Col < 0 then
    Exit;
  CX := ColumnLeft(Row, Col) + IndentPx div 2;
  // Eigene Linie: von oben (bzw. Mitte bei der ersten Wurzel) bis zur Mitte,
  // weiter nach unten, wenn Geschwister folgen; waagerecht zum Inhalt
  if (Node.FParent = nil) and (Node.GetPrevSibling = nil) then
    Pts[0] := Point(CX, CY)
  else
    Pts[0] := Point(CX, Row.Top);
  if Node.GetNextSibling <> nil then
    Pts[1] := Point(CX, Row.Bottom)
  else
    Pts[1] := Point(CX, CY);
  IR.DrawTreeLine(ACanvas, Pts, Color, ScalePPI);
  if UseRightToLeftAlignment then
    X2 := CX - IndentPx div 2
  else
    X2 := CX + IndentPx div 2;
  Pts[0] := Point(CX, CY);
  Pts[1] := Point(X2, CY);
  IR.DrawTreeLine(ACanvas, Pts, Color, ScalePPI);
end;

procedure TPPGCustomTreeView.PaintItem(const ACanvas: IPPGCanvas; Index: Integer;
  const R: TRect; const Data: TPPGItemData; const Info: TPPGItemPaintInfo);
var
  N: TPPGTreeNode;
  IR: IPPGItemRenderer;
  Ind: IPPGIndicatorRenderer;
  Rot: Single;
  LineColor: TColor;
  A: TPPGAppearance;
  S: TPPGSurfaceStyle;
  ER: TRect;
begin
  inherited PaintItem(ACanvas, Index, R, Data, Info);
  N := NodeOfRow(Index);
  if N = nil then
    Exit;
  IR := PPGItemRendererOf(Renderer);
  LineColor := PPGBlendColor(Info.ListStyle.TextColor, Info.ListStyle.Color, 0.45);
  if FShowLines then
    PaintLines(ACanvas, N, R, LineColor);
  if ShowsButton(N) then
  begin
    if (N = FAnimNode) and FExpandAnim.Running then
      Rot := FAnimFrom + (FAnimTo - FAnimFrom) * FExpandAnim.Value
    else
      Rot := Ord(N.FExpanded);
    ER := ExpanderRect(N, R);
    if FShowLines then
      // Linie unter dem Pfeil abdecken: kleine Flaeche in Listenfarbe
      ACanvas.FillRoundRect(Rect((ER.Left + ER.Right) div 2 - PPGScale(5, Info.PPI),
        (ER.Top + ER.Bottom) div 2 - PPGScale(5, Info.PPI),
        (ER.Left + ER.Right) div 2 + PPGScale(5, Info.PPI),
        (ER.Top + ER.Bottom) div 2 + PPGScale(5, Info.PPI)), PPGScale(2, Info.PPI),
        Info.ListStyle.Color, 255);
    IR.DrawExpander(ACanvas, ER, PPGBlendColor(Info.ListStyle.TextColor,
      Info.ListStyle.Color, 0.25), Rot, Info.RightToLeft, Info.PPI);
  end;
  if FCheckBoxes then
  begin
    if not Supports(Renderer, IPPGIndicatorRenderer, Ind) then
      Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
        IPPGIndicatorRenderer, Ind);
    A := EffectiveAppearance;
    if not (Enabled and N.FEnabled) then
      S := A.Resolve(vsDisabled, Info.PPI, False)
    else if N.FCheckState = cbChecked then
      S := A.ResolveStyle(A.Checked, Info.PPI, False)
    else
    begin
      S := A.Resolve(vsNormal, Info.PPI, False);
      if N.FCheckState = cbGrayed then
        S.TextColor := PPGColorToRGB(A.Checked.Color);
    end;
    S.GlowAlpha := 0;
    S.GlowSize := 0;
    if HighContrastSupport and PPGIsHighContrast then
    begin
      S.Color := PPGColorToRGB(clWindow);
      S.ColorTo := S.Color;
      S.ColorMirror := S.Color;
      S.ColorMirrorTo := S.Color;
      S.BorderColor := PPGColorToRGB(clWindowText);
      S.TextColor := PPGColorToRGB(clWindowText);
    end;
    Ind.DrawCheckIndicator(ACanvas, CheckRect(N, R), S, N.FCheckState, Info.PPI);
  end;
end;

procedure TPPGCustomTreeView.ExpandAnimStep(Sender: TObject);
begin
  Invalidate;
end;

{ ---- Aufklappen ---- }

function TPPGCustomTreeView.DoExpand(Node: TPPGTreeNode; Recurse, ByUser: Boolean): Boolean;
var
  Allow: Boolean;
  I: Integer;
begin
  Result := False;
  if (Node = nil) or (Node.FOwner <> FItems) then
    Exit;
  FItems.BeginUpdate;
  try
    if not Node.FExpanded and Node.HasChildren then
    begin
      Allow := True;
      if Assigned(FOnExpanding) then
        FOnExpanding(Self, Node, Allow); // Lazy Loading: Kinder jetzt anlegen
      if Allow then
      begin
        if Node.Count = 0 then
          Node.FHasChildren := False // nichts gekommen: Pfeil verschwindet
        else
        begin
          Node.FExpanded := True;
          Result := True;
          if ByUser and Animation.EffectiveEnabled and HandleAllocated and
            IsWindowVisible(Handle) then
          begin
            FAnimNode := Node;
            FAnimFrom := 0;
            FAnimTo := 1;
            FExpandAnim.Jump(0);
            FExpandAnim.AnimateTo(1, Animation.Duration, ekDecelerate);
          end;
          if Assigned(FOnExpanded) then
            FOnExpanded(Self, Node);
        end;
      end;
    end;
    if Recurse then
      for I := 0 to Node.Count - 1 do
        DoExpand(Node[I], True, False);
  finally
    FItems.EndUpdate;
  end;
end;

function TPPGCustomTreeView.DoCollapse(Node: TPPGTreeNode; Recurse, ByUser: Boolean): Boolean;
var
  Allow: Boolean;
  I: Integer;
begin
  Result := False;
  if (Node = nil) or (Node.FOwner <> FItems) then
    Exit;
  FItems.BeginUpdate;
  try
    if Node.FExpanded then
    begin
      Allow := True;
      if Assigned(FOnCollapsing) then
        FOnCollapsing(Self, Node, Allow);
      if Allow then
      begin
        Node.FExpanded := False;
        Result := True;
        if ByUser and Animation.EffectiveEnabled and HandleAllocated and
          IsWindowVisible(Handle) then
        begin
          FAnimNode := Node;
          FAnimFrom := 1;
          FAnimTo := 0;
          FExpandAnim.Jump(0);
          FExpandAnim.AnimateTo(1, Animation.Duration, ekDecelerate);
        end;
        if Assigned(FOnCollapsed) then
          FOnCollapsed(Self, Node);
      end;
    end;
    if Recurse then
      for I := 0 to Node.Count - 1 do
        DoCollapse(Node[I], True, False);
  finally
    FItems.EndUpdate;
  end;
end;

procedure TPPGCustomTreeView.ToggleNode(Node: TPPGTreeNode; ByUser: Boolean);
var
  Done: Boolean;
begin
  if Node = nil then
    Exit;
  BeginUserAction;
  try
    if Node.FExpanded then
      Done := DoCollapse(Node, False, ByUser)
    else
      Done := DoExpand(Node, False, ByUser);
  finally
    EndUserAction;
  end;
  // Screenreader: aufgeklappt/zugeklappt (MSAA und UIA)
  if Done and ByUser and (RowOfNode(Node) >= 0) then
    NotifyAccessibilityChild(EVENT_OBJECT_STATECHANGE, RowOfNode(Node) + 1);
end;

procedure TPPGCustomTreeView.FullExpand;
var
  I: Integer;
begin
  FItems.BeginUpdate;
  try
    for I := 0 to FItems.FRoots.Count - 1 do
      DoExpand(TPPGTreeNode(FItems.FRoots[I]), True, False);
  finally
    FItems.EndUpdate;
  end;
end;

procedure TPPGCustomTreeView.FullCollapse;
var
  I: Integer;
begin
  FItems.BeginUpdate;
  try
    for I := 0 to FItems.FRoots.Count - 1 do
      DoCollapse(TPPGTreeNode(FItems.FRoots[I]), True, False);
  finally
    FItems.EndUpdate;
  end;
end;

{ ---- Kaestchen ---- }

procedure TPPGCustomTreeView.SetDescendantChecks(Node: TPPGTreeNode; State: TCheckBoxState);
var
  I: Integer;
begin
  for I := 0 to Node.Count - 1 do
  begin
    Node[I].FCheckState := State;
    SetDescendantChecks(Node[I], State);
  end;
end;

procedure TPPGCustomTreeView.UpdateCheckParents(Node: TPPGTreeNode);
begin
  RecalcChecksFrom(Node.FParent);
end;

procedure TPPGCustomTreeView.RecalcChecksFrom(P: TPPGTreeNode);
var
  I, OnCount, OffCount: Integer;
begin
  // Eltern aus den Kindern: alle an / alle aus / gemischt
  while (P <> nil) and (P.Count > 0) do
  begin
    OnCount := 0;
    OffCount := 0;
    for I := 0 to P.Count - 1 do
      case P[I].FCheckState of
        cbChecked: Inc(OnCount);
        cbUnchecked: Inc(OffCount);
      end;
    if OnCount = P.Count then
      P.FCheckState := cbChecked
    else if OffCount = P.Count then
      P.FCheckState := cbUnchecked
    else
      P.FCheckState := cbGrayed;
    P := P.FParent;
  end;
end;

procedure TPPGCustomTreeView.ChildrenChanged(P: TPPGTreeNode);
begin
  if FCheckBoxes and FAutoCheck and (P <> nil) then
    RecalcChecksFrom(P);
end;

procedure TPPGCustomTreeView.SetNodeCheck(Node: TPPGTreeNode; State: TCheckBoxState;
  ByUser: Boolean);
begin
  if Node = nil then
    Exit;
  Node.FCheckState := State;
  if FAutoCheck and (State <> cbGrayed) then
  begin
    SetDescendantChecks(Node, State);
    UpdateCheckParents(Node);
  end;
  Invalidate;
  if ByUser then
  begin
    NotifyAccessibilityChild(EVENT_OBJECT_STATECHANGE, RowOfNode(Node) + 1);
    if Assigned(FOnChecked) then
      FOnChecked(Self, Node);
  end;
end;

{ ---- Auswahl ---- }

function TPPGCustomTreeView.GetSelected: TPPGTreeNode;
begin
  Result := NodeOfRow(Selection.ItemIndex);
end;

procedure TPPGCustomTreeView.SetSelected(const Value: TPPGTreeNode);
var
  R: Integer;
begin
  if Value = GetSelected then
    Exit;
  if Value <> nil then
    Value.MakeVisible;
  R := RowOfNode(Value);
  ItemIndex := R;
  FLastSelected := GetSelected;
  // Wie TTreeView: OnChange auch bei Auswahl im Code
  Change(FLastSelected);
end;

procedure TPPGCustomTreeView.SelectByUser(Node: TPPGTreeNode);
var
  R: Integer;
begin
  R := RowOfNode(Node);
  if (R < 0) or not CanChangeFocusTo(R) then
    Exit;
  BeginUserAction;
  try
    Selection.MoveTo(R, []);
  finally
    EndUserAction;
  end;
  MakeItemVisible(R, True);
end;

function TPPGCustomTreeView.CanChangeFocusTo(Index: Integer): Boolean;
begin
  Result := True;
  if Assigned(FOnChanging) then
    FOnChanging(Self, NodeOfRow(Index), Result);
end;

procedure TPPGCustomTreeView.UserSelectionChanged;
var
  N: TPPGTreeNode;
begin
  inherited UserSelectionChanged;
  N := GetSelected;
  if N <> FLastSelected then
  begin
    FLastSelected := N;
    if FAutoExpand and (N <> nil) and N.HasChildren and not N.FExpanded then
      DoExpand(N, False, True);
    Change(N);
  end;
  Click;
end;

procedure TPPGCustomTreeView.Change(Node: TPPGTreeNode);
begin
  if Assigned(FOnChange) then
    FOnChange(Self, Node);
end;

function TPPGCustomTreeView.GetTopItem: TPPGTreeNode;
begin
  Result := NodeOfRow(TopIndex);
end;

procedure TPPGCustomTreeView.SetTopItem(const Value: TPPGTreeNode);
begin
  if Value <> nil then
  begin
    Value.MakeVisible;
    TopIndex := RowOfNode(Value);
  end;
end;

procedure TPPGCustomTreeView.SetMultiSelect(const Value: Boolean);
begin
  if FMultiSelect <> Value then
  begin
    FMultiSelect := Value;
    if Value then
      Selection.Mode := smExtended
    else
      Selection.Mode := smSingle;
    Invalidate;
  end;
end;

{ ---- Maus und Tastatur ---- }

function TPPGCustomTreeView.ItemMouseDown(Index: Integer; Shift: TShiftState;
  X, Y: Integer): Boolean;
var
  N: TPPGTreeNode;
  R: TRect;
begin
  Result := False;
  N := NodeOfRow(Index);
  if N = nil then
    Exit;
  R := Rect(ViewRect.Left, ItemRect(Index).Top, ViewRect.Right, ItemRect(Index).Bottom);
  if ShowsButton(N) and PtInRect(ExpanderRect(N, R), Point(X, Y)) then
  begin
    // Pfeil: auf-/zuklappen ohne die Auswahl zu aendern (wie TTreeView)
    ToggleNode(N, True);
    Result := True;
    Exit;
  end;
  if FCheckBoxes and N.FEnabled then
  begin
    R := CheckRect(N, R);
    InflateRect(R, PPGScale(3, ScalePPI), PPGScale(3, ScalePPI));
    if PtInRect(R, Point(X, Y)) then
    begin
      if N.FCheckState = cbChecked then
        SetNodeCheck(N, cbUnchecked, True)
      else
        SetNodeCheck(N, cbChecked, True);
      Result := True;
    end;
  end;
end;

procedure TPPGCustomTreeView.DblClick;
var
  P: TPoint;
  N: TPPGTreeNode;
  R: TRect;
begin
  inherited DblClick;
  // Doppelklick auf einen Knoten klappt ihn auf/zu (wie TTreeView)
  P := ScreenToClient(Mouse.CursorPos);
  N := GetNodeAt(P.X, P.Y);
  if (N = nil) or not N.HasChildren then
    Exit;
  // Auf dem Pfeil hat schon der Klick umgeschaltet
  R := ItemRect(RowOfNode(N));
  R := Rect(ViewRect.Left, R.Top, ViewRect.Right, R.Bottom);
  if ShowsButton(N) and PtInRect(ExpanderRect(N, R), P) then
    Exit;
  ToggleNode(N, True);
end;

function TPPGCustomTreeView.ItemSpaceKey(Index: Integer): Boolean;
var
  N: TPPGTreeNode;
begin
  Result := False;
  N := NodeOfRow(Index);
  if FCheckBoxes and (N <> nil) and N.FEnabled then
  begin
    if N.FCheckState = cbChecked then
      SetNodeCheck(N, cbUnchecked, True)
    else
      SetNodeCheck(N, cbChecked, True);
    Result := True;
  end;
end;

function TPPGCustomTreeView.ItemHorzKey(Index: Integer; Key: Word; Shift: TShiftState): Boolean;
var
  N: TPPGTreeNode;
  K: Word;
begin
  Result := True;
  N := NodeOfRow(Index);
  if N = nil then
    Exit;
  K := Key;
  if UseRightToLeftAlignment then
    if K = VK_LEFT then
      K := VK_RIGHT
    else
      K := VK_LEFT;
  if K = VK_LEFT then
  begin
    // Links: zuklappen, sonst zum Eltern-Knoten
    if N.FExpanded then
      ToggleNode(N, True)
    else if N.FParent <> nil then
      SelectByUser(N.FParent);
  end
  else
  begin
    // Rechts: aufklappen, sonst zum ersten Kind
    if N.HasChildren and not N.FExpanded then
      ToggleNode(N, True)
    else if N.Count > 0 then
      SelectByUser(N.GetFirstChild);
  end;
end;

procedure TPPGCustomTreeView.KeyDown(var Key: Word; Shift: TShiftState);
var
  N: TPPGTreeNode;
begin
  N := GetSelected;
  case Key of
    VK_ADD, VK_SUBTRACT, VK_MULTIPLY:
      if N <> nil then
      begin
        BeginUserAction;
        try
          if Key = VK_ADD then
            DoExpand(N, False, True)
          else if Key = VK_SUBTRACT then
            DoCollapse(N, False, True)
          else
            DoExpand(N, True, False); // * : alles darunter aufklappen
        finally
          EndUserAction;
        end;
        Key := 0;
        Exit;
      end;
    VK_F2:
      if (N <> nil) and (Shift = []) then
      begin
        EditNode(N);
        Key := 0;
        Exit;
      end;
  end;
  inherited KeyDown(Key, Shift);
end;

{ ---- Ziehen ---- }

function TPPGCustomTreeView.DropTargetAt(Y: Integer; out Inside: Boolean): Integer;
var
  Row, H, Off: Integer;
  R: TRect;
begin
  Inside := False;
  Row := ItemAtPos(ViewRect.Left + 1, Y);
  if Row < 0 then
  begin
    Result := inherited DropTargetAt(Y, Inside);
    Exit;
  end;
  R := ItemRect(Row);
  H := R.Bottom - R.Top;
  Off := Y - R.Top;
  // Oberes Viertel: davor, unteres Viertel: danach, Mitte: hinein
  if Off < H div 4 then
    Result := Row
  else if Off >= H - H div 4 then
    Result := Row + 1
  else
  begin
    Result := Row;
    Inside := True;
  end;
end;

function TPPGCustomTreeView.DoDropAt(FromIndex, TargetRow: Integer; Inside: Boolean): Boolean;
var
  Node, Dest: TPPGTreeNode;
  Mode: TNodeAttachMode;
  Allow: Boolean;
begin
  Result := False;
  Node := NodeOfRow(FromIndex);
  if Node = nil then
    Exit;
  if Inside then
  begin
    Dest := NodeOfRow(TargetRow);
    Mode := naAddChild;
  end
  else if TargetRow < RowCount then
  begin
    Dest := NodeOfRow(TargetRow);
    Mode := naInsert;
  end
  else
  begin
    Dest := NodeOfRow(RowCount - 1);
    Mode := naAdd;
  end;
  // Nicht auf sich selbst oder in die eigenen Kinder
  if (Dest = nil) or (Dest = Node) or Dest.HasAsParent(Node) then
    Exit;
  if (Mode = naInsert) and (Dest = Node.GetNextSibling) then
    Exit; // gleiche Stelle
  Allow := True;
  if Assigned(FOnNodeDrop) then
    FOnNodeDrop(Self, Node, Dest, Mode, Allow);
  if not Allow then
    Exit;
  Node.MoveTo(Dest, Mode);
  if Inside and not Dest.FExpanded then
    DoExpand(Dest, False, False);
  SelectByUser(Node);
  Result := True;
end;

{ ---- Umbenennen ---- }

function TPPGCustomTreeView.EditNode(Node: TPPGTreeNode): Boolean;
var
  Allow: Boolean;
  R: TRect;
  Data: TPPGItemData;
  X, H, Row: Integer;
  Fill, Text: TColor;
begin
  Result := False;
  if FReadOnly or (Node = nil) or (Node.FOwner <> FItems) or not Node.FEnabled or
    not HandleAllocated then
    Exit;
  EndEdit(True);
  Allow := True;
  if Assigned(FOnEditing) then
    FOnEditing(Self, Node, Allow);
  if not Allow then
    Exit;
  Node.MakeVisible;
  Row := RowOfNode(Node);
  R := ItemRect(Row);
  if IsRectEmpty(R) then
    Exit;
  GetItemData(Row, Data);
  // Edit an der Stelle des Texts (hinter Einzug, Kaestchen und Bild)
  X := R.Left + ItemIndent(Row, Data) + PPGScale(PPGItemPadX, ScalePPI);
  if (Images <> nil) and (Node.FImageIndex >= 0) then
    Inc(X, Images.Width + PPGScale(PPGItemGap, ScalePPI));
  H := TPPGItemPainter.TextLineHeight(Font) + PPGScale(4, ScalePPI);
  if FEditor = nil then
  begin
    FEditor := TPPGTreeEdit.Create(Self);
    FEditor.Visible := False;
    FEditor.Parent := Self;
    FEditor.BorderStyle := bsSingle;
    FEditor.AutoSize := False;
  end;
  GetListColors(Fill, Text);
  FEditor.Color := Fill;
  FEditor.Font := Font;
  FEditor.Font.Color := Text;
  FEditor.SetBounds(X - PPGScale(3, ScalePPI), (R.Top + R.Bottom - H) div 2,
    R.Right - X - PPGScale(6, ScalePPI), H);
  FEditor.Text := PPGStripMarkup(Node.FText);
  FEditNode := Node;
  FEditor.Visible := True;
  FEditor.SelectAll;
  if FEditor.CanFocus then
    FEditor.SetFocus;
  Result := True;
end;

procedure TPPGCustomTreeView.EditorKey(Key: Word);
begin
  EndEdit(Key = VK_RETURN);
end;

procedure TPPGCustomTreeView.EndEdit(Accept: Boolean);
var
  N: TPPGTreeNode;
  S: string;
  HadFocus: Boolean;
begin
  if (FEditNode = nil) or (FEditor = nil) then
    Exit;
  N := FEditNode;
  FEditNode := nil; // vor den Ereignissen (DoExit ruft erneut)
  S := FEditor.Text;
  HadFocus := FEditor.Focused;
  FEditor.Visible := False;
  if HadFocus and CanFocus and HandleAllocated and IsWindowVisible(Handle) then
    SetFocus;
  if Accept and (N.FOwner = FItems) then
  begin
    if Assigned(FOnEdited) then
      FOnEdited(Self, N, S);
    N.Text := S;
  end;
end;

function TPPGCustomTreeView.IsEditing: Boolean;
begin
  Result := FEditNode <> nil;
end;

procedure TPPGCustomTreeView.Scrolled;
begin
  inherited Scrolled;
  EndEdit(True); // Scrollen schliesst den Editor (er wuerde sonst danebenstehen)
end;

{ ---- Sortieren ---- }

procedure TPPGCustomTreeView.SortList(L: TList; Recurse: Boolean);
var
  I, J, C: Integer;
  A, B: TPPGTreeNode;
begin
  if (L = nil) or (L.Count < 2) then
  begin
    if Recurse and (L <> nil) then
      for I := 0 to L.Count - 1 do
        SortList(TPPGTreeNode(L[I]).FChildren, True);
    Exit;
  end;
  // Einfuegesortierung: stabil, ohne zusaetzlichen Speicher (Kinderlisten
  // sind in Baeumen klein)
  for I := 1 to L.Count - 1 do
  begin
    A := TPPGTreeNode(L[I]);
    J := I - 1;
    while J >= 0 do
    begin
      B := TPPGTreeNode(L[J]);
      if Assigned(FOnCompare) then
      begin
        C := 0;
        FOnCompare(Self, B, A, C);
      end
      else
        C := AnsiCompareText(PPGStripMarkup(B.FText), PPGStripMarkup(A.FText));
      if C <= 0 then
        Break;
      L[J + 1] := L[J];
      Dec(J);
    end;
    L[J + 1] := A;
  end;
  if Recurse then
    for I := 0 to L.Count - 1 do
      SortList(TPPGTreeNode(L[I]).FChildren, True);
end;

procedure TPPGCustomTreeView.AlphaSort(Recurse: Boolean);
begin
  FItems.BeginUpdate;
  try
    SortList(FItems.FRoots, Recurse);
  finally
    FItems.EndUpdate;
  end;
end;

{ ---- Properties ---- }

procedure TPPGCustomTreeView.SetIndent(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'Indent', Value, 0, 200);
  if FIndent <> V then
  begin
    FIndent := V;
    Invalidate;
  end;
end;

procedure TPPGCustomTreeView.SetShowLines(const Value: Boolean);
begin
  if FShowLines <> Value then
  begin
    FShowLines := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomTreeView.SetShowRoot(const Value: Boolean);
begin
  if FShowRoot <> Value then
  begin
    FShowRoot := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomTreeView.SetShowButtons(const Value: Boolean);
begin
  if FShowButtons <> Value then
  begin
    FShowButtons := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomTreeView.SetCheckBoxes(const Value: Boolean);
begin
  if FCheckBoxes <> Value then
  begin
    FCheckBoxes := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomTreeView.SetHotTrack(const Value: Boolean);
begin
  if FHotTrack <> Value then
  begin
    FHotTrack := Value;
    Invalidate;
  end;
end;

function TPPGCustomTreeView.ItemExtraFontStyle(Index: Integer; Hot: Boolean): TFontStyles;
begin
  if FHotTrack and Hot then
    Result := [fsUnderline]
  else
    Result := [];
end;

function TPPGCustomTreeView.HasCustomDraw: Boolean;
begin
  Result := Assigned(FOnCustomDrawNode) or inherited HasCustomDraw;
end;

function TPPGCustomTreeView.DoCustomDrawItem(const ACanvas: IPPGCanvas; Index: Integer;
  const R: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle): Boolean;
var
  N: TPPGTreeNode;
  DC: HDC;
begin
  // Mit Knoten-Ereignis dieses, sonst das allgemeine OnCustomDrawItem (Zeile)
  Style.Reset;
  if not Assigned(FOnCustomDrawNode) then
    Exit(inherited DoCustomDrawItem(ACanvas, Index, R, State, Style));
  Result := True;
  N := NodeOfRow(Index);
  if N = nil then
    Exit;
  if N.FExpanded then
    Include(State, idsExpanded);
  DC := ACanvas.BeginGdi;
  try
    DrawCanvas.Handle := DC;
    try
      DrawCanvas.Font := Font;
      DrawCanvas.Brush.Style := bsClear;
      FOnCustomDrawNode(Self, DrawCanvas, N, R, State, Style, Result);
    finally
      DrawCanvas.Handle := 0;
    end;
  finally
    ACanvas.EndGdi(DC);
  end;
end;

procedure TPPGCustomTreeView.CMHintShow(var Message: TCMHintShow);
var
  N: TPPGTreeNode;
  P: TPoint;
  R: TRect;
  Avail, W: Integer;
  Row: Integer;
  D: TPPGItemData;
begin
  inherited;
  // ToolTips: abgeschnittener Knotentext als Hinweis (nur ohne eigenen Hint)
  if not FToolTips or (Hint <> '') or (Message.HintInfo = nil) then
    Exit;
  P := Message.HintInfo^.CursorPos;
  N := GetNodeAt(P.X, P.Y);
  Row := RowOfNode(N);
  if Row < 0 then
    Exit;
  R := ItemRect(Row);
  if IsRectEmpty(R) then
    Exit;
  PPGInitItemData(D);
  W := PPGMeasureTextNoCanvas(PPGStripMarkup(N.FText), Font, 0, False).cx;
  Avail := (R.Right - R.Left) - ItemIndent(Row, D) -
    PPGScale(PPGItemPadX + 6, ScalePPI);
  if Images <> nil then
    Dec(Avail, Images.Width + PPGScale(PPGItemGap, ScalePPI));
  if W <= Avail then
    Exit;
  Message.HintInfo^.HintStr := PPGStripMarkup(N.FText);
  Message.HintInfo^.CursorRect := R;
end;

procedure TPPGCustomTreeView.SetHideSelection(const Value: Boolean);
begin
  if FHideSelection <> Value then
  begin
    FHideSelection := Value;
    Invalidate;
  end;
end;

{ ---- Barrierefreiheit ---- }

procedure TPPGCustomTreeView.DoAccChildAction(Index: Integer);
var
  N: TPPGTreeNode;
begin
  N := NodeOfRow(Index);
  if (N <> nil) and N.HasChildren then
    ToggleNode(N, True)
  else
    inherited DoAccChildAction(Index);
end;

function TPPGCustomTreeView.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_OUTLINE;
end;

function TPPGCustomTreeView.AccChildRole(Id: Integer): Integer;
begin
  Result := ROLE_SYSTEM_OUTLINEITEM;
end;

function TPPGCustomTreeView.AccChildState(Id: Integer): Integer;
var
  N: TPPGTreeNode;
begin
  Result := inherited AccChildState(Id);
  N := NodeOfRow(Id - 1);
  if N = nil then
    Exit;
  if N.HasChildren then
    if N.FExpanded then
      Result := Result or STATE_SYSTEM_EXPANDED
    else
      Result := Result or STATE_SYSTEM_COLLAPSED;
  if FCheckBoxes then
    case N.FCheckState of
      cbChecked: Result := Result or STATE_SYSTEM_CHECKED;
      cbGrayed: Result := Result or STATE_SYSTEM_MIXED;
    end;
end;

function TPPGCustomTreeView.AccChildDefaultAction(Id: Integer): string;
var
  N: TPPGTreeNode;
begin
  N := NodeOfRow(Id - 1);
  if (N <> nil) and N.HasChildren then
  begin
    if N.FExpanded then
      Result := PPGStr(@SPPGAccCollapse)
    else
      Result := PPGStr(@SPPGAccExpand);
  end
  else
    Result := inherited AccChildDefaultAction(Id);
end;

{ ---- UI Automation ---- }

function TPPGCustomTreeView.NodeUiaId(Node: TPPGTreeNode): Integer;
begin
  Result := 0;
  if Node = nil then
    Exit;
  if Node.FUiaId = 0 then
  begin
    if FUiaNodes = nil then
      FUiaNodes := TDictionary<Integer, TPPGTreeNode>.Create;
    Inc(FUiaNext);
    Node.FUiaId := FUiaNext;
    FUiaNodes.Add(Node.FUiaId, Node);
  end;
  Result := Node.FUiaId;
end;

function TPPGCustomTreeView.NodeFromUiaId(AId: Integer): TPPGTreeNode;
begin
  if (FUiaNodes = nil) or not FUiaNodes.TryGetValue(AId, Result) then
    Result := nil;
end;

function TPPGCustomTreeView.UiaRowOf(const Id: TPPGUiaId): Integer;
begin
  if Id.Kind = PPGUiaKindListItem then
    Result := RowOfNode(NodeFromUiaId(Id.A))
  else
    Result := -1;
end;

function TPPGCustomTreeView.UiaIdOfRow(Row: Integer): TPPGUiaId;
var
  N: TPPGTreeNode;
begin
  N := NodeOfRow(Row);
  if N = nil then
    Result := PPGUiaId(0)
  else
    Result := PPGUiaId(PPGUiaKindListItem, NodeUiaId(N));
end;

function TPPGCustomTreeView.UiaParent(const Id: TPPGUiaId): TPPGUiaId;
var
  N: TPPGTreeNode;
begin
  N := NodeOfRow(UiaRowOf(Id));
  if (N = nil) or (N.FParent = nil) then
    Result := PPGUiaId(0)
  else
    Result := PPGUiaId(PPGUiaKindListItem, NodeUiaId(N.FParent));
end;

function TPPGCustomTreeView.UiaChildCount(const Id: TPPGUiaId): Integer;
var
  N: TPPGTreeNode;
begin
  if PPGUiaIsRoot(Id) then
    Exit(FItems.RootCount);
  N := NodeOfRow(UiaRowOf(Id));
  if (N <> nil) and N.FExpanded then
    Result := N.Count
  else
    Result := 0;
end;

function TPPGCustomTreeView.UiaChild(const Id: TPPGUiaId; Index: Integer): TPPGUiaId;
var
  N, C: TPPGTreeNode;
begin
  C := nil;
  if PPGUiaIsRoot(Id) then
  begin
    if (Index >= 0) and (Index < FItems.RootCount) then
      C := FItems.Root(Index);
  end
  else
  begin
    N := NodeOfRow(UiaRowOf(Id));
    if (N <> nil) and N.FExpanded and (Index >= 0) and (Index < N.Count) then
      C := N[Index];
  end;
  if C = nil then
    Result := PPGUiaId(0)
  else
    Result := PPGUiaId(PPGUiaKindListItem, NodeUiaId(C));
end;

function TPPGCustomTreeView.UiaIndexInParent(const Id: TPPGUiaId): Integer;
var
  N: TPPGTreeNode;
begin
  N := NodeOfRow(UiaRowOf(Id));
  if N = nil then
    Result := -1
  else
    Result := N.Index;
end;

function TPPGCustomTreeView.UiaControlType(const Id: TPPGUiaId): Integer;
begin
  if PPGUiaIsRoot(Id) then
    Result := UIA_TreeControlTypeId
  else
    Result := UIA_TreeItemControlTypeId;
end;

function TPPGCustomTreeView.UiaProperty(const Id: TPPGUiaId; PropertyId: Integer;
  out Value: OleVariant): Boolean;
var
  N: TPPGTreeNode;
  L: TList;
begin
  Result := False;
  N := NodeOfRow(UiaRowOf(Id));
  if N = nil then
    Exit;
  case PropertyId of
    UIA_LevelPropertyId:
      begin
        Value := N.Level + 1;
        Result := True;
      end;
    UIA_PositionInSetPropertyId:
      begin
        Value := N.Index + 1;
        Result := True;
      end;
    UIA_SizeOfSetPropertyId:
      begin
        L := N.Siblings;
        if L <> nil then
        begin
          Value := L.Count;
          Result := True;
        end;
      end;
  end;
end;

function TPPGCustomTreeView.UiaHasPattern(const Id: TPPGUiaId; PatternId: Integer): Boolean;
begin
  if PPGUiaIsRoot(Id) or (UiaRowOf(Id) < 0) then
    Exit(inherited UiaHasPattern(Id, PatternId));
  case PatternId of
    UIA_SelectionItemPatternId, UIA_ScrollItemPatternId, UIA_ExpandCollapsePatternId:
      Result := True;
    UIA_TogglePatternId:
      Result := FCheckBoxes;
  else
    Result := False;
  end;
end;

function TPPGCustomTreeView.UiaExpandState(const Id: TPPGUiaId): Integer;
var
  N: TPPGTreeNode;
begin
  N := NodeOfRow(UiaRowOf(Id));
  if (N = nil) or not N.HasChildren then
    Result := ExpandCollapseState_LeafNode
  else if N.FExpanded then
    Result := ExpandCollapseState_Expanded
  else
    Result := ExpandCollapseState_Collapsed;
end;

procedure TPPGCustomTreeView.UiaExecute(const Id: TPPGUiaId; Action: TPPGUiaAction;
  const Value: string);
var
  N: TPPGTreeNode;
  R: Integer;
begin
  R := UiaRowOf(Id);
  N := NodeOfRow(R);
  if (N = nil) or not Enabled then
  begin
    inherited UiaExecute(Id, Action, Value);
    Exit;
  end;
  case Action of
    uaSelect:
      SelectByUser(N);
    uaExpand:
      if not N.FExpanded then
        ToggleNode(N, True);
    uaCollapse:
      if N.FExpanded then
        ToggleNode(N, True);
    uaToggle:
      if FCheckBoxes and N.FEnabled then
        ItemSpaceKey(R);
    uaScrollIntoView:
      MakeItemVisible(R);
  else
    inherited UiaExecute(Id, Action, Value);
  end;
end;

end.
