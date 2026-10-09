unit PPG.TileView;

{ TPPGTileView - Kachel-, Karten- und Galerie-Ansicht (Phase 18b).

  Mehrwert gegenueber TListView (vsIcon) und TMS: drei Ansichten mit
  Kartenvorlage (Bild, Titel, Detail, Plakette), Suche mit Hervorhebung der
  Treffer, Zoom (Strg+Rad), Gruppen mit Kopf (klappbar), virtuell fuer grosse
  Mengen, Gummiband-Auswahl, Export und Druck ueber IPPGTableSource
  (xlsx, HTML, PDF wie beim Grid).

  Aufbau:
  - Basis TPPGCustomScrollControl (Overlay-Leisten, weiches Scrollen,
    Auto-Scroll beim Ziehen). Daten ueber IPPGItemSource: Items (Collection
    TPPGItems) oder virtuell (ItemCount + OnGetItem).
  - Layout: Rechtecke aller sichtbaren (gefilterten) Eintraege in
    Inhaltskoordinaten, nach Gruppen. Neu berechnet bei Groesse, Zoom,
    Filter, Ansicht und Datenaenderung; gezeichnet wird nur, was im Bild ist
    (binaere Suche ueber die Oberkante).
  - Auswahl: TPPGSelection (Windows-Semantik) ueber den Positionen der
    Ansicht; Selected[] und ItemIndex sprechen in Daten-Indizes.
  - Symbole: Images (ImageIndex), OnGetItemIcon (Zeichen der Symbolschrift)
    oder OnGetPicture (Vorschaubild, gehoert dem Aufrufer).
  - Tastatur: Pfeile in zwei Dimensionen (naechster Eintrag in der Richtung),
    Pos1/Ende, Bild auf/ab, Umschalt/Strg wie Windows, Tippsuche, F2 benennt um,
    Enter = OnItemDblClick.
  - Code setzt Auswahl und Filter ohne OnChange (PPGlow-Regel). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.Variants,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.ImgList,
  PPG.Types, PPG.Items, PPG.Selection, PPG.Render.Intf, PPG.Accessibility, PPG.ElementStyle,
  PPG.Controls.Scroll, PPG.Grid.Data;

type
  TPPGTileStyle = (tsIcons, tsTiles, tsCards);

  TPPGTileIconEvent = procedure(Sender: TObject; Index: Integer; var CodePoint: Word) of object;
  TPPGTilePictureEvent = procedure(Sender: TObject; Index: Integer; var Picture: TGraphic) of object;
  TPPGTileFilterEvent = procedure(Sender: TObject; Index: Integer; const Data: TPPGItemData;
    var Accept: Boolean) of object;
  TPPGTileRenameEvent = procedure(Sender: TObject; Index: Integer; var NewText: string;
    var Accept: Boolean) of object;
  TPPGTileItemEvent = procedure(Sender: TObject; Index: Integer) of object;

  TPPGCustomTileView = class(TPPGCustomScrollControl, IPPGAccessibleChildren, IPPGTableSource)
  private
    FItems: TPPGItems;
    FCollectionSource: IPPGItemSource;
    FVirtual: TPPGVirtualSource;
    FVirtualSource: IPPGItemSource;
    FSource: IPPGItemSource;
    FOwnerData: Boolean;
    FTileStyle: TPPGTileStyle;
    FZoom: Integer;
    FImages: TCustomImageList;
    FFilterText: string;
    FGroupView: Boolean;
    FCollapsed: TStringList;
    FCheckboxes: Boolean;
    FMultiSelect: Boolean;
    FReadOnly: Boolean;
    FEmptyText: string;
    FItemStyle: TPPGElementStyle;
    FSelectedStyle: TPPGElementStyle;
    FGroupStyle: TPPGElementStyle;
    FSelection: TPPGSelection;
    // Layout (Ansicht): Position -> Daten-Index, Rechteck; Gruppenkoepfe
    FLayoutValid: Boolean;
    FViewIndex: array of Integer;
    FViewRect: array of TRect;
    FHeads: array of record
      Text: string;
      R: TRect;
      First, Count: Integer;  // Positionen der Ansicht
      Collapsed: Boolean;
    end;
    FDataToView: array of Integer;
    FHot: Integer;           // Position, -1 = keine
    FHotHead: Integer;
    FBandStart: TPoint;      // Inhaltskoordinaten
    FBandRect: TRect;
    FBanding: Boolean;
    FBandBase: array of Boolean;
    FDownPos: Integer;
    FTypeBuf: TPPGTypeAhead;
    FEditor: TEdit;
    FEditIndex: Integer;
    FUpdating: Integer;
    FOnChange: TNotifyEvent;
    FOnGetItem: TPPGGetItemEvent;
    FOnGetItemIcon: TPPGTileIconEvent;
    FOnGetPicture: TPPGTilePictureEvent;
    FOnFilterItem: TPPGTileFilterEvent;
    FOnRename: TPPGTileRenameEvent;
    FOnItemClick: TPPGTileItemEvent;
    FOnItemDblClick: TPPGTileItemEvent;
    procedure SetItems(const Value: TPPGItems);
    procedure SetOwnerData(const Value: Boolean);
    function GetItemCount: Integer;
    procedure SetItemCount(const Value: Integer);
    procedure SetTileStyle(const Value: TPPGTileStyle);
    procedure SetZoom(const Value: Integer);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetFilterText(const Value: string);
    procedure SetGroupView(const Value: Boolean);
    procedure SetCheckboxes(const Value: Boolean);
    procedure SetMultiSelect(const Value: Boolean);
    procedure SetEmptyText(const Value: string);
    procedure SetItemStyle(const Value: TPPGElementStyle);
    procedure SetSelectedStyle(const Value: TPPGElementStyle);
    procedure SetGroupStyle(const Value: TPPGElementStyle);
    function GetItemIndex: Integer;
    procedure SetItemIndex(const Value: Integer);
    function GetSelected(Index: Integer): Boolean;
    procedure SetSelected(Index: Integer; const Value: Boolean);
    function GetSelCount: Integer;
    function GetVisibleCount: Integer;
    function GetGroupCollapsed(const Group: string): Boolean;
    procedure SetGroupCollapsed(const Group: string; const Value: Boolean);
    procedure SourceChanged(Sender: TObject; Index: Integer);
    procedure VirtualGetItem(Sender: TObject; Index: Integer; var Data: TPPGItemData);
    procedure SelectionChanged(Sender: TObject);
    procedure StyleChanged(Sender: TObject);
    procedure EditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditorExit(Sender: TObject);
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    /// Beschriftung (Titel oder Detail) der Kachel an Pos abgeschnitten? Audit 7f #2.
    function TileTextTruncated(Pos: Integer): Boolean;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMBiDiModeChanged(var Message: TMessage); message CM_BIDIMODECHANGED;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure PaintViewport(const ACanvas: IPPGCanvas; const View: TRect); override;
    procedure ContentMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure ContentMouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure ContentMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DblClick; override;
    procedure DoEnter; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    procedure DoAutoScroll(const P: TPoint); override;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure WndProc(var Message: TMessage); override;
    procedure DoChange; virtual;
    function GetItemData(Index: Integer): TPPGItemData;
    /// Layout neu berechnen (bei Bedarf).
    procedure EnsureLayout;
    procedure InvalidateLayout;
    /// Groesse einer Kachel (Geraetepixel) fuer die Ansicht.
    function TileSize: TSize;
    function TileGap: Integer;
    function HeadHeight: Integer;
    /// Position der Ansicht unter dem Punkt (Client-Koordinaten), -1 = keine.
    function PosAt(X, Y: Integer): Integer;
    function HeadAt(X, Y: Integer): Integer;
    function PosClientRect(Pos: Integer): TRect;
    /// Naechste Position in der Richtung (Tastatur), -1 = keine.
    function PosInDirection(From: Integer; DX, DY: Integer): Integer;
    procedure FocusPos(Pos: Integer; Shift: TShiftState);
    procedure PaintTile(const ACanvas: IPPGCanvas; Pos: Integer; const R: TRect);
    procedure PaintHead(const ACanvas: IPPGCanvas; H: Integer; const R: TRect);
    function HighlightMarkup(const S: string; Accent: TColor): string;
    function AccRole: Integer; override;
    function AccChildCount: Integer;
    function AccChildName(Id: Integer): string;
    function AccChildRole(Id: Integer): Integer;
    function AccChildState(Id: Integer): Integer;
    function AccChildRect(Id: Integer): TRect;
    function AccChildAt(X, Y: Integer): Integer;
    function AccChildDefaultAction(Id: Integer): string;
    procedure AccChildDoDefault(Id: Integer);
    function AccFocusedChild: Integer;
    function AccSelectedChild: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    /// Virtuell: Daten haben sich geaendert (Index = -1: alles).
    procedure InvalidateItem(Index: Integer);
    /// Daten-Index unter dem Punkt (Client-Koordinaten), -1 = keiner.
    function ItemAt(X, Y: Integer): Integer;
    /// Lage eines Eintrags (Client-Koordinaten); leer = ausgefiltert/zugeklappt.
    function ItemRect(Index: Integer): TRect;
    /// Position eines Daten-Index in der Ansicht (-1 = nicht sichtbar).
    function ViewPos(Index: Integer): Integer;
    /// Daten-Index einer Position der Ansicht.
    function ViewItem(Pos: Integer): Integer;
    procedure SelectAll;
    procedure ClearSelection;
    procedure MakeItemVisible(Index: Integer);
    /// Beschriftung bearbeiten (wie F2); False = nicht moeglich.
    function EditItem(Index: Integer): Boolean;
    property Selected[Index: Integer]: Boolean read GetSelected write SetSelected;
    property SelCount: Integer read GetSelCount;
    /// Eintraege nach Filter und ohne zugeklappte Gruppen.
    property VisibleCount: Integer read GetVisibleCount;
    property GroupCollapsed[const Group: string]: Boolean read GetGroupCollapsed
      write SetGroupCollapsed;
    property Items: TPPGItems read FItems write SetItems;
    property OwnerData: Boolean read FOwnerData write SetOwnerData default False;
    property ItemCount: Integer read GetItemCount write SetItemCount;
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
    property TileStyle: TPPGTileStyle read FTileStyle write SetTileStyle default tsTiles;
    /// Groesse in Prozent (50..200), Strg+Mausrad aendert sie.
    property Zoom: Integer read FZoom write SetZoom default 100;
    property Images: TCustomImageList read FImages write SetImages;
    /// Suche: zeigt nur Eintraege, deren Text oder Detail den Begriff enthaelt
    /// (ohne Gross-/Kleinschreibung), und hebt ihn hervor.
    property FilterText: string read FFilterText write SetFilterText;
    property GroupView: Boolean read FGroupView write SetGroupView default True;
    property Checkboxes: Boolean read FCheckboxes write SetCheckboxes default False;
    property MultiSelect: Boolean read FMultiSelect write SetMultiSelect default False;
    property ReadOnly: Boolean read FReadOnly write FReadOnly default False;
    /// Text, wenn nichts zu zeigen ist ('' = Vorgabe "Keine Eintraege").
    property EmptyText: string read FEmptyText write SetEmptyText;
    property ItemStyle: TPPGElementStyle read FItemStyle write SetItemStyle;
    property SelectedStyle: TPPGElementStyle read FSelectedStyle write SetSelectedStyle;
    property GroupStyle: TPPGElementStyle read FGroupStyle write SetGroupStyle;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnGetItem: TPPGGetItemEvent read FOnGetItem write FOnGetItem;
    property OnGetItemIcon: TPPGTileIconEvent read FOnGetItemIcon write FOnGetItemIcon;
    property OnGetPicture: TPPGTilePictureEvent read FOnGetPicture write FOnGetPicture;
    property OnFilterItem: TPPGTileFilterEvent read FOnFilterItem write FOnFilterItem;
    property OnRename: TPPGTileRenameEvent read FOnRename write FOnRename;
    property OnItemClick: TPPGTileItemEvent read FOnItemClick write FOnItemClick;
    property OnItemDblClick: TPPGTileItemEvent read FOnItemDblClick write FOnItemDblClick;
    { IPPGTableSource (Export, Druck): Titel, Detail, Plakette, Gruppe }
    function TableColCount: Integer;
    function TableRowCount: Integer;
    function TableColumn(ACol: Integer): TPPGTableColumnInfo;
    function TableCellText(ACol, ARow: Integer): string;
    function TableCellValue(ACol, ARow: Integer): Variant;
  end;

  TPPGTileView = class(TPPGCustomTileView)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighContrastSupport;
    property Items;
    property OwnerData;
    property ItemCount;
    property TileStyle;
    property Zoom;
    property Images;
    property FilterText;
    property GroupView;
    property Checkboxes;
    property MultiSelect;
    property ReadOnly;
    property EmptyText;
    property ItemStyle;
    property SelectedStyle;
    property GroupStyle;
    property ScrollBarMode;
    property SmoothScrolling;
    { VCL-Standard }
    property Align;
    property Anchors;
    property BiDiMode;
    property Color;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Touch;
    property OnGesture;
    property OnChange;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetItem;
    property OnGetItemIcon;
    property OnGetPicture;
    property OnFilterItem;
    property OnItemClick;
    property OnItemDblClick;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnRename;
    property OnScroll;
    property OnStartDrag;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseWheel;
    property OnMouseActivate;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

implementation

uses
  System.SysUtils, System.Math, System.StrUtils, Vcl.Forms, Winapi.oleacc, PPG.Appearance,
  PPG.Exceptions, PPG.Lang, PPG.Consts, PPG.DpiUtils, PPG.Render.Gdi, PPG.Render.Registry,
  PPG.IconFont, PPG.Markup, PPG.Tokens;

const
  // Logische Groessen bei Zoom 100 %
  IconsW = 104;
  IconsH = 112;
  TilesW = 280;
  TilesH = 72;
  CardsW = 220;
  CardsH = 216;
  Gap = 8;
  Pad = 10;
  HeadH = 32;

var
  GMsgTileAction: Cardinal;

function CssLikeEscape(const S: string): string;
begin
  // Markup-Sonderzeichen maskieren (der Text wird zu Markup)
  Result := StringReplace(S, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
end;

function ColorHex(C: TColor): string;
var
  RGB: Integer;
begin
  RGB := ColorToRGB(C);
  Result := Format('#%.2x%.2x%.2x', [RGB and $FF, (RGB shr 8) and $FF, (RGB shr 16) and $FF]);
end;

{ TPPGCustomTileView }

constructor TPPGCustomTileView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csCaptureMouse, csDoubleClicks];
  Width := 400;
  Height := 260;
  TabStop := True;
  Color := clWindow;
  FItems := TPPGItems.Create(Self);
  FCollectionSource := TPPGCollectionSource.Create(FItems);
  FVirtual := TPPGVirtualSource.Create;
  FVirtual.OnGetItem := VirtualGetItem;
  FVirtualSource := FVirtual;
  FSource := FCollectionSource;
  FSource.OnChanged := SourceChanged;
  FTileStyle := tsTiles;
  FZoom := 100;
  FGroupView := True;
  FCollapsed := TStringList.Create;
  FCollapsed.CaseSensitive := False;
  FItemStyle := TPPGElementStyle.Create(Self);
  FItemStyle.OnChange := StyleChanged;
  FSelectedStyle := TPPGElementStyle.Create(Self);
  FSelectedStyle.OnChange := StyleChanged;
  FGroupStyle := TPPGElementStyle.Create(Self);
  FGroupStyle.OnChange := StyleChanged;
  FSelection := TPPGSelection.Create;
  FSelection.OnChange := SelectionChanged;
  FHot := -1;
  FHotHead := -1;
  FDownPos := -1;
  FEditIndex := -1;
  // Pfeile, Bild auf/ab bewegen den Fokus (nicht die Ansicht)
  KeyboardScrolling := False;
end;

destructor TPPGCustomTileView.Destroy;
begin
  if FSource <> nil then
    FSource.OnChanged := nil;
  FSource := nil;
  FCollectionSource := nil;
  FVirtualSource := nil;
  FVirtual := nil;
  inherited Destroy;
  FreeAndNil(FSelection);
  FreeAndNil(FCollapsed);
  FreeAndNil(FGroupStyle);
  FreeAndNil(FSelectedStyle);
  FreeAndNil(FItemStyle);
  FreeAndNil(FItems);
end;

procedure TPPGCustomTileView.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FImages) then
  begin
    FImages := nil;
    Invalidate;
  end;
end;

procedure TPPGCustomTileView.Loaded;
begin
  inherited Loaded;
  InvalidateLayout;
end;

procedure TPPGCustomTileView.BeginUpdate;
begin
  Inc(FUpdating);
end;

procedure TPPGCustomTileView.EndUpdate;
begin
  if FUpdating > 0 then
    Dec(FUpdating);
  if FUpdating = 0 then
    InvalidateLayout;
end;

procedure TPPGCustomTileView.InvalidateLayout;
begin
  FLayoutValid := False;
  if (FUpdating = 0) and not (csLoading in ComponentState) and
    not (csDestroying in ComponentState) then
  begin
    EnsureLayout;
    // Nicht aus EnsureLayout: das laeuft auch im Paint (dort keine Ereignisse)
    NotifyAccessibility(EVENT_OBJECT_REORDER);
    Invalidate;
  end;
end;

procedure TPPGCustomTileView.InvalidateItem(Index: Integer);
begin
  if Index < 0 then
    InvalidateLayout
  else
    Invalidate;
end;

procedure TPPGCustomTileView.SourceChanged(Sender: TObject; Index: Integer);
begin
  if csDestroying in ComponentState then
    Exit;
  if (Index >= 0) and FLayoutValid and (FFilterText = '') then
    Invalidate // nur ein Eintrag geaendert (Gruppe/Filter koennen sich nicht verschieben)
  else
    InvalidateLayout;
end;

procedure TPPGCustomTileView.VirtualGetItem(Sender: TObject; Index: Integer; var Data: TPPGItemData);
begin
  if Assigned(FOnGetItem) then
    FOnGetItem(Self, Index, Data);
end;

function TPPGCustomTileView.GetItemData(Index: Integer): TPPGItemData;
begin
  PPGInitItemData(Result);
  if (Index >= 0) and (Index < FSource.Count) then
    FSource.GetItem(Index, Result);
end;

procedure TPPGCustomTileView.SetItems(const Value: TPPGItems);
begin
  FItems.Assign(Value);
end;

procedure TPPGCustomTileView.SetOwnerData(const Value: Boolean);
begin
  if FOwnerData = Value then
    Exit;
  FSource.OnChanged := nil;
  FOwnerData := Value;
  if Value then
    FSource := FVirtualSource
  else
    FSource := FCollectionSource;
  FSource.OnChanged := SourceChanged;
  FSelection.Clear;
  InvalidateLayout;
end;

function TPPGCustomTileView.GetItemCount: Integer;
begin
  Result := FSource.Count;
end;

procedure TPPGCustomTileView.SetItemCount(const Value: Integer);
begin
  // Nur virtuell (wie TListView.Items.Count bei OwnerData)
  if not FOwnerData then
    Exit;
  if Value < 0 then
    raise EPPGError.CreateFmt(PPGStr(@SPPGInvalidArgument), [Value, 'ItemCount']);
  if FVirtual.Count <> Value then
  begin
    FVirtual.ItemCount := Value;
    FSelection.Clear;
    InvalidateLayout;
  end;
end;

procedure TPPGCustomTileView.SetTileStyle(const Value: TPPGTileStyle);
begin
  if FTileStyle <> Value then
  begin
    FTileStyle := Value;
    InvalidateLayout;
  end;
end;

procedure TPPGCustomTileView.SetZoom(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'Zoom', Value, 50, 200);
  if FZoom <> V then
  begin
    FZoom := V;
    InvalidateLayout;
  end;
end;

procedure TPPGCustomTileView.SetImages(const Value: TCustomImageList);
begin
  if FImages <> Value then
  begin
    if FImages <> nil then
      FImages.RemoveFreeNotification(Self);
    FImages := Value;
    if FImages <> nil then
      FImages.FreeNotification(Self);
    Invalidate;
  end;
end;

procedure TPPGCustomTileView.SetFilterText(const Value: string);
begin
  if FFilterText <> Value then
  begin
    FFilterText := Value;
    InvalidateLayout;
  end;
end;

procedure TPPGCustomTileView.SetGroupView(const Value: Boolean);
begin
  if FGroupView <> Value then
  begin
    FGroupView := Value;
    InvalidateLayout;
  end;
end;

procedure TPPGCustomTileView.SetCheckboxes(const Value: Boolean);
begin
  if FCheckboxes <> Value then
  begin
    FCheckboxes := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomTileView.SetMultiSelect(const Value: Boolean);
begin
  if FMultiSelect <> Value then
  begin
    FMultiSelect := Value;
    if Value then
      FSelection.Mode := smExtended
    else
      FSelection.Mode := smSingle;
    Invalidate;
  end;
end;

procedure TPPGCustomTileView.SetEmptyText(const Value: string);
begin
  if FEmptyText <> Value then
  begin
    FEmptyText := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomTileView.SetItemStyle(const Value: TPPGElementStyle);
begin
  FItemStyle.Assign(Value);
end;

procedure TPPGCustomTileView.SetSelectedStyle(const Value: TPPGElementStyle);
begin
  FSelectedStyle.Assign(Value);
end;

procedure TPPGCustomTileView.SetGroupStyle(const Value: TPPGElementStyle);
begin
  FGroupStyle.Assign(Value);
end;

procedure TPPGCustomTileView.StyleChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TPPGCustomTileView.CMFontChanged(var Message: TMessage);
begin
  inherited;
  InvalidateLayout;
end;

procedure TPPGCustomTileView.CMBiDiModeChanged(var Message: TMessage);
begin
  inherited;
  // RTL spiegelt die Spalten: Layout neu
  InvalidateLayout;
end;

procedure TPPGCustomTileView.Resize;
begin
  inherited Resize;
  InvalidateLayout;
end;

{ Auswahl }

procedure TPPGCustomTileView.SelectionChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TPPGCustomTileView.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TPPGCustomTileView.ViewPos(Index: Integer): Integer;
begin
  EnsureLayout;
  if (Index >= 0) and (Index < Length(FDataToView)) then
    Result := FDataToView[Index]
  else
    Result := -1;
end;

function TPPGCustomTileView.ViewItem(Pos: Integer): Integer;
begin
  EnsureLayout;
  if (Pos >= 0) and (Pos < Length(FViewIndex)) then
    Result := FViewIndex[Pos]
  else
    Result := -1;
end;

function TPPGCustomTileView.GetItemIndex: Integer;
begin
  EnsureLayout;
  Result := ViewItem(FSelection.Focus);
  if (Result >= 0) and not FSelection.Selected[FSelection.Focus] then
    Result := ViewItem(FSelection.NextSelected(-1));
end;

procedure TPPGCustomTileView.SetItemIndex(const Value: Integer);
var
  P: Integer;
begin
  EnsureLayout;
  if Value = -1 then
  begin
    FSelection.Clear;
    Exit;
  end;
  if (Value < 0) or (Value >= FSource.Count) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Value, FSource.Count - 1]);
  P := ViewPos(Value);
  if P < 0 then
    raise EPPGError.CreateFmt(PPGStr(@SPPGInvalidArgument), [Value, 'ItemIndex']);
  FSelection.BeginUpdate;
  try
    FSelection.Clear;
    FSelection.Focus := P;
    FSelection.Selected[P] := True;
  finally
    FSelection.EndUpdate;
  end;
end;

function TPPGCustomTileView.GetSelected(Index: Integer): Boolean;
var
  P: Integer;
begin
  P := ViewPos(Index);
  Result := (P >= 0) and FSelection.Selected[P];
end;

procedure TPPGCustomTileView.SetSelected(Index: Integer; const Value: Boolean);
var
  P: Integer;
begin
  if (Index < 0) or (Index >= FSource.Count) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, FSource.Count - 1]);
  P := ViewPos(Index);
  if P >= 0 then
  begin
    if Value and not FMultiSelect then
      FSelection.Clear;
    FSelection.Selected[P] := Value;
  end;
end;

function TPPGCustomTileView.GetSelCount: Integer;
begin
  Result := FSelection.SelCount;
end;

function TPPGCustomTileView.GetVisibleCount: Integer;
begin
  EnsureLayout;
  Result := Length(FViewIndex);
end;

procedure TPPGCustomTileView.SelectAll;
begin
  if FMultiSelect then
    FSelection.SelectAll;
end;

procedure TPPGCustomTileView.ClearSelection;
begin
  FSelection.Clear;
end;

function TPPGCustomTileView.GetGroupCollapsed(const Group: string): Boolean;
begin
  Result := FCollapsed.IndexOf(Group) >= 0;
end;

procedure TPPGCustomTileView.SetGroupCollapsed(const Group: string; const Value: Boolean);
var
  I: Integer;
begin
  I := FCollapsed.IndexOf(Group);
  if Value and (I < 0) then
    FCollapsed.Add(Group)
  else if not Value and (I >= 0) then
    FCollapsed.Delete(I)
  else
    Exit;
  InvalidateLayout;
end;

{ Layout }

function TPPGCustomTileView.TileGap: Integer;
begin
  Result := PPGScale(Gap, ScalePPI);
end;

function TPPGCustomTileView.HeadHeight: Integer;
begin
  Result := PPGScale(HeadH, ScalePPI);
end;

function TPPGCustomTileView.TileSize: TSize;
var
  W, H: Integer;
begin
  case FTileStyle of
    tsIcons:
      begin
        W := IconsW;
        H := IconsH;
      end;
    tsCards:
      begin
        W := CardsW;
        H := CardsH;
      end;
  else
    begin
      W := TilesW;
      H := TilesH;
    end;
  end;
  Result.cx := PPGScale(MulDiv(W, FZoom, 100), ScalePPI);
  Result.cy := PPGScale(MulDiv(H, FZoom, 100), ScalePPI);
end;

procedure TPPGCustomTileView.EnsureLayout;
var
  N, I, J, K, Cols, Col, X0, Y, Avail, CW, G, NH, P, SX: Integer;
  View: TRect;
  D: TPPGItemData;
  Groups: TStringList;
  GroupOf: array of Integer;
  Order: array of Integer;
  Filter: string;
  Accept, HasGroups: Boolean;
  Sz: TSize;
  OldSel: array of Integer; // Daten-Indizes der Auswahl vor dem Neuaufbau
  OldFocus: Integer;
begin
  if FLayoutValid then
    Exit;
  FLayoutValid := True;
  N := FSource.Count;
  // Auswahl gehoert zu Eintraegen, nicht zu Positionen: vor dem Neuaufbau merken
  SetLength(OldSel, 0);
  OldFocus := -1;
  if FSelection.Count = Length(FViewIndex) then
  begin
    I := FSelection.NextSelected(-1);
    while I >= 0 do
    begin
      if FViewIndex[I] < N then
      begin
        SetLength(OldSel, Length(OldSel) + 1);
        OldSel[High(OldSel)] := FViewIndex[I];
      end;
      I := FSelection.NextSelected(I + 1); // NextSelected sucht ab einschliesslich From
    end;
    if (FSelection.Focus >= 0) and (FSelection.Focus < Length(FViewIndex)) then
      OldFocus := FViewIndex[FSelection.Focus];
  end;
  Filter := AnsiUpperCase(FFilterText);
  // 1. Filtern und Gruppen ermitteln (eine Abfrage je Eintrag)
  SetLength(GroupOf, N);
  SetLength(FDataToView, N);
  Groups := TStringList.Create;
  try
    Groups.CaseSensitive := False;
    HasGroups := False;
    K := 0;
    SetLength(Order, N);
    for I := 0 to N - 1 do
    begin
      FDataToView[I] := -1;
      D := GetItemData(I);
      Accept := (Filter = '') or (Pos(Filter, AnsiUpperCase(D.Text)) > 0) or
        (Pos(Filter, AnsiUpperCase(D.Detail)) > 0);
      if Assigned(FOnFilterItem) then
        FOnFilterItem(Self, I, D, Accept);
      if not Accept then
      begin
        GroupOf[I] := -1;
        Continue;
      end;
      if FGroupView and (D.Group <> '') then
        HasGroups := True;
      if FGroupView then
      begin
        J := Groups.IndexOf(D.Group);
        if J < 0 then
          J := Groups.Add(D.Group);
      end
      else
        J := 0;
      GroupOf[I] := J;
      Order[K] := I;
      Inc(K);
    end;
    if not HasGroups then
      for I := 0 to K - 1 do
        GroupOf[Order[I]] := 0;
    // 2. Positionen: gruppenweise in Reihenfolge des ersten Auftretens
    View := ViewRect;
    Sz := TileSize;
    G := TileGap;
    Avail := (View.Right - View.Left) - G;
    Cols := Max(1, Avail div (Sz.cx + G));
    // Kacheln und Karten fuellen die Breite, Symbole behalten ihre Breite
    if FTileStyle = tsIcons then
      CW := Sz.cx
    else
      CW := Max(Sz.cx, (Avail - Cols * G) div Cols);
    if (FTileStyle <> tsIcons) and (CW > Sz.cx * 2) then
      CW := Sz.cx * 2;
    SetLength(FViewIndex, K);
    SetLength(FViewRect, K);
    if HasGroups then
      NH := Groups.Count
    else
      NH := 0;
    SetLength(FHeads, NH);
    Y := G;
    P := 0;
    X0 := G;
    for J := 0 to Max(Groups.Count, 1) - 1 do
    begin
      if HasGroups then
      begin
        FHeads[J].Text := Groups[J];
        FHeads[J].R := Rect(0, Y, Avail + G, Y + HeadHeight);
        FHeads[J].First := P;
        FHeads[J].Collapsed := GetGroupCollapsed(Groups[J]);
        Inc(Y, HeadHeight + G div 2);
      end;
      Col := 0;
      for I := 0 to K - 1 do
        if (GroupOf[Order[I]] = J) or (not HasGroups) then
        begin
          if HasGroups and FHeads[J].Collapsed then
            Continue;
          FViewIndex[P] := Order[I];
          FDataToView[Order[I]] := P;
          FViewRect[P] := Rect(X0 + Col * (CW + G), Y, X0 + Col * (CW + G) + CW, Y + Sz.cy);
          Inc(P);
          Inc(Col);
          if Col >= Cols then
          begin
            Col := 0;
            Inc(Y, Sz.cy + G);
          end;
        end;
      if Col > 0 then
        Inc(Y, Sz.cy + G);
      if HasGroups then
      begin
        FHeads[J].Count := P - FHeads[J].First;
        Inc(Y, G);
      end;
      if not HasGroups then
        Break;
    end;
  finally
    Groups.Free;
  end;
  SetLength(FViewIndex, P);
  SetLength(FViewRect, P);
  // RTL: Spalten spiegeln
  if UseRightToLeftAlignment then
  begin
    SX := Avail + G;
    for I := 0 to P - 1 do
      FViewRect[I] := Rect(SX - FViewRect[I].Right, FViewRect[I].Top, SX - FViewRect[I].Left,
        FViewRect[I].Bottom);
  end;
  // Auswahl auf die neuen Positionen uebertragen (ausgefilterte fallen heraus)
  FSelection.BeginUpdate;
  try
    FSelection.Clear;
    FSelection.Count := P;
    for I := 0 to High(OldSel) do
      if (OldSel[I] < N) and (FDataToView[OldSel[I]] >= 0) then
        FSelection.Selected[FDataToView[OldSel[I]]] := True;
    if (OldFocus >= 0) and (OldFocus < N) and (FDataToView[OldFocus] >= 0) then
      FSelection.Focus := FDataToView[OldFocus];
  finally
    FSelection.EndUpdate;
  end;
  if FHot >= P then
    FHot := -1;
  SetContentSize(View.Right - View.Left, Y);
end;

function TPPGCustomTileView.PosClientRect(Pos: Integer): TRect;
var
  View: TRect;
begin
  EnsureLayout;
  if (Pos < 0) or (Pos >= Length(FViewRect)) then
    Exit(Rect(0, 0, 0, 0));
  View := ViewRect;
  Result := FViewRect[Pos];
  OffsetRect(Result, View.Left - ScrollX, View.Top - ScrollY);
end;

function TPPGCustomTileView.ItemRect(Index: Integer): TRect;
begin
  Result := PosClientRect(ViewPos(Index));
end;

function TPPGCustomTileView.PosAt(X, Y: Integer): Integer;
var
  View: TRect;
  CX, CY, Lo, Hi, Mid, I: Integer;
begin
  Result := -1;
  EnsureLayout;
  View := ViewRect;
  if not PtInRect(View, Point(X, Y)) then
    Exit;
  CX := X - View.Left + ScrollX;
  CY := Y - View.Top + ScrollY;
  // Erste Kachel, deren Unterkante unter CY liegt (Rechtecke nach Oberkante sortiert)
  Lo := 0;
  Hi := High(FViewRect);
  while Lo < Hi do
  begin
    Mid := (Lo + Hi) div 2;
    if FViewRect[Mid].Bottom <= CY then
      Lo := Mid + 1
    else
      Hi := Mid;
  end;
  for I := Lo to High(FViewRect) do
  begin
    if FViewRect[I].Top > CY then
      Break;
    if PtInRect(FViewRect[I], Point(CX, CY)) then
      Exit(I);
  end;
end;

function TPPGCustomTileView.ItemAt(X, Y: Integer): Integer;
begin
  Result := ViewItem(PosAt(X, Y));
end;

function TPPGCustomTileView.HeadAt(X, Y: Integer): Integer;
var
  View: TRect;
  I: Integer;
  P: TPoint;
begin
  Result := -1;
  EnsureLayout;
  View := ViewRect;
  P := Point(X - View.Left + ScrollX, Y - View.Top + ScrollY);
  for I := 0 to High(FHeads) do
    if PtInRect(FHeads[I].R, P) then
      Exit(I);
end;

procedure TPPGCustomTileView.MakeItemVisible(Index: Integer);
var
  P: Integer;
begin
  P := ViewPos(Index);
  if P >= 0 then
    MakeVisible(FViewRect[P], SmoothScrolling);
end;

function TPPGCustomTileView.PosInDirection(From: Integer; DX, DY: Integer): Integer;
var
  I, Best, BestD, D, CX, CY, ICX, ICY: Integer;
  R: TRect;
begin
  Result := -1;
  if (From < 0) or (From >= Length(FViewRect)) then
    Exit;
  if DX <> 0 then
  begin
    // Waagerecht: Nachbar in der Lesereihenfolge (wie Explorer)
    if UseRightToLeftAlignment then
      DX := -DX;
    I := From + DX;
    if (I >= 0) and (I < Length(FViewRect)) then
      Result := I;
    Exit;
  end;
  // Senkrecht: naechste Zeile, dort die Kachel mit der naechsten Mitte
  R := FViewRect[From];
  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;
  Best := -1;
  BestD := MaxInt;
  I := From + DY;
  while (I >= 0) and (I < Length(FViewRect)) do
  begin
    ICY := (FViewRect[I].Top + FViewRect[I].Bottom) div 2;
    if ((DY > 0) and (ICY > CY)) or ((DY < 0) and (ICY < CY)) then
    begin
      if (Best >= 0) and (Abs(ICY - CY) > Abs(((FViewRect[Best].Top + FViewRect[Best].Bottom) div 2) - CY)) then
        Break; // eine Zeile weiter: fertig
      ICX := (FViewRect[I].Left + FViewRect[I].Right) div 2;
      D := Abs(ICX - CX);
      if D < BestD then
      begin
        BestD := D;
        Best := I;
      end;
    end;
    Inc(I, DY);
  end;
  Result := Best;
end;

procedure TPPGCustomTileView.FocusPos(Pos: Integer; Shift: TShiftState);
begin
  if (Pos < 0) or (Pos >= Length(FViewIndex)) then
    Exit;
  if FMultiSelect then
    FSelection.MoveTo(Pos, Shift)
  else
    FSelection.MoveTo(Pos, []);
  MakeVisible(FViewRect[Pos], SmoothScrolling);
  NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, Pos + 1);
  DoChange;
end;

{ Zeichnen }

function TPPGCustomTileView.HighlightMarkup(const S: string; Accent: TColor): string;
var
  P, L: Integer;
  U: string;
begin
  // Treffer der Suche fett in Akzentfarbe, Rest maskiert
  U := AnsiUpperCase(S);
  P := Pos(AnsiUpperCase(FFilterText), U);
  if (FFilterText = '') or (P = 0) then
    Exit(CssLikeEscape(S));
  L := Length(FFilterText);
  Result := CssLikeEscape(Copy(S, 1, P - 1)) + '<b><color=' + ColorHex(Accent) + '>' +
    CssLikeEscape(Copy(S, P, L)) + '</color></b>' + CssLikeEscape(Copy(S, P + L, MaxInt));
end;

procedure TPPGCustomTileView.PaintHead(const ACanvas: IPPGCanvas; H: Integer; const R: TRect);
var
  PPI: Integer;
  TR, AR: TRect;
  C: TColor;
  F, Temp: TFont;
  Dark: Boolean;
begin
  PPI := ScalePPI;
  Dark := UseDarkMode;
  if UseDarkMode then
    C := Tokens.TextPrimary
  else
    C := PPGColorToRGB(Font.Color);
  C := FGroupStyle.TextFor(Dark, C);
  if FGroupStyle.HasFill(Dark) then
    ACanvas.FillRoundRect(R, PPGScale(4, PPI), FGroupStyle.FillFor(Dark, clNone), 255)
  else if H = FHotHead then
    ACanvas.FillRoundRect(R, PPGScale(4, PPI), C, 14);
  // Pfeil (zu = nach rechts) und Text mit Anzahl
  AR := Rect(R.Left + PPGScale(4, PPI), R.Top, R.Left + PPGScale(24, PPI), R.Bottom);
  if FHeads[H].Collapsed then
    PPGDrawIcon(ACanvas, AR, igChevronRight, C, PPGScale(12, PPI))
  else
    PPGDrawIcon(ACanvas, AR, igChevronDown, C, PPGScale(12, PPI));
  TR := Rect(AR.Right + PPGScale(4, PPI), R.Top, R.Right, R.Bottom);
  Temp := nil;
  try
    F := PPGElementFont(FGroupStyle, Font, [fsBold], Temp);
    ACanvas.DrawText(TR, FHeads[H].Text + '  (' + IntToStr(FHeads[H].Count) + ')', F, C,
      DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS));
  finally
    Temp.Free;
  end;
  ACanvas.FillRoundRect(Rect(R.Left, R.Bottom - 1, R.Right, R.Bottom), 0, C, 40);
end;

procedure TPPGCustomTileView.PaintTile(const ACanvas: IPPGCanvas; Pos: Integer; const R: TRect);
var
  PPI, P, Rad, IconSz, TH, X, Y, Ix: Integer;
  D: TPPGItemData;
  Idx: Integer;
  A: TPPGAppearance;
  Base: TPPGSurfaceStyle;
  Dark, HC, Sel, Hot, Foc, Usable: Boolean;
  Fill, Border, Txt, Normal, Secondary, Accent: TColor;
  SymR, TitleR, DetR, PicR, BadgeR, ChkR: TRect;
  Code: Word;
  Pic: TGraphic;
  F, FB, Temp, TempB: TFont;
  Flags: Cardinal;
  ML: TPPGMarkupLayout;
  DC: HDC;
  Cv: TCanvas;
  IR: IPPGIndicatorRenderer;
  ChkStyle: TPPGSurfaceStyle;
  BadgeW: Integer;

  procedure DrawSymbol(const SR: TRect; Color: TColor);
  begin
    if (FImages <> nil) and (D.ImageIndex >= 0) and (D.ImageIndex < FImages.Count) then
      ACanvas.DrawImage(FImages, D.ImageIndex, (SR.Left + SR.Right - FImages.Width) div 2,
        (SR.Top + SR.Bottom - FImages.Height) div 2, Usable)
    else if Code <> 0 then
      PPGDrawIconChar(ACanvas, SR, Code, Color, SR.Bottom - SR.Top);
  end;

  procedure DrawLine(const LR: TRect; const S: string; AFont: TFont; Color: TColor;
    AFlags: Cardinal);
  begin
    if S = '' then
      Exit;
    if FFilterText <> '' then
    begin
      // Treffer hervorheben (Markup, ohne Ellipse; der Clip schneidet ab)
      ML.Layout(HighlightMarkup(S, Accent), AFont, nil, LR.Right - LR.Left,
        AFlags and DT_WORDBREAK <> 0);
      ACanvas.PushClipRoundRect(LR, 0);
      try
        if AFlags and DT_CENTER <> 0 then
          ML.Draw(ACanvas, (LR.Left + LR.Right - ML.Size.cx) div 2, LR.Top, Color, Accent, Usable)
        else if AFlags and DT_VCENTER <> 0 then
          ML.Draw(ACanvas, LR.Left, (LR.Top + LR.Bottom - ML.Size.cy) div 2, Color, Accent, Usable)
        else
          ML.Draw(ACanvas, LR.Left, LR.Top, Color, Accent, Usable);
      finally
        ACanvas.PopClip;
      end;
    end
    else
      ACanvas.DrawText(LR, S, AFont, Color, DrawTextBiDiModeFlags(AFlags or DT_NOPREFIX or
        DT_END_ELLIPSIS));
  end;

begin
  Idx := FViewIndex[Pos];
  D := GetItemData(Idx);
  PPI := ScalePPI;
  P := PPGScale(MulDiv(Pad, FZoom, 100), PPI);
  A := EffectiveAppearance;
  Base := A.Resolve(vsNormal, PPI, False);
  Dark := UseDarkMode;
  HC := HighContrastSupport and PPGIsHighContrast;
  Sel := FSelection.Selected[Pos];
  Hot := Pos = FHot;
  Foc := Focused and FocusVisible and (Pos = FSelection.Focus);
  Usable := Enabled and D.Enabled;
  Rad := Max(Base.Rounding, PPGScale(6, PPI));
  Accent := PPGColorToRGB(A.FocusColor);
  if Dark then
    Txt := Tokens.TextPrimary
  else
    Txt := PPGColorToRGB(Font.Color);
  if D.TextColor <> clDefault then
    Txt := PPGColorToRGB(D.TextColor);
  Txt := FItemStyle.TextFor(Dark, Txt);
  // Flaeche und Rand aus der normalen Textfarbe (auch deaktiviert gut erkennbar)
  Normal := Txt;
  if not Usable then
    Txt := PPGColorToRGB(A.Disabled.TextColor);
  Secondary := PPGBlendColor(Txt, GetBackgroundColor, 0.4);
  // Flaeche: Karten und Kacheln immer, Symbole nur bei Hover/Auswahl
  if FTileStyle = tsIcons then
    Fill := clNone
  else
    Fill := FItemStyle.FillFor(Dark, PPGBlendColor(GetBackgroundColor, Normal, 0.03));
  if D.Color <> clDefault then
    Fill := PPGColorToRGB(D.Color);
  Border := FItemStyle.BorderFor(Dark, PPGBlendColor(GetBackgroundColor, Normal, 0.14));
  if FTileStyle = tsIcons then
    Border := clNone;
  if Sel and Usable then
  begin
    Fill := FSelectedStyle.FillFor(Dark, PPGBlendColor(GetBackgroundColor, Accent, 0.16));
    Border := FSelectedStyle.BorderFor(Dark, Accent);
    Txt := FSelectedStyle.TextFor(Dark, Txt);
  end
  else if Sel then
  begin
    // Gewaehlt, aber gesperrt: graue Flaeche und grauer Rand statt Akzent
    Border := PPGColorToRGB(A.Disabled.TextColor);
    Fill := PPGBlendColor(GetBackgroundColor, Border, 0.22);
  end
  else if Hot and Usable then
  begin
    if Fill = clNone then
      Fill := PPGBlendColor(GetBackgroundColor, Txt, 0.06)
    else
      Fill := PPGBlendColor(Fill, Txt, 0.04);
    if Border <> clNone then
      Border := PPGBlendColor(Border, Txt, 0.3);
  end;
  if HC then
  begin
    Txt := PPGColorToRGB(clWindowText);
    Secondary := Txt;
    if Sel then
    begin
      Fill := PPGColorToRGB(clHighlight);
      Txt := PPGColorToRGB(clHighlightText);
      Secondary := Txt;
    end
    else
      Fill := PPGColorToRGB(clWindow);
    Border := PPGColorToRGB(clWindowText);
  end;
  if Fill <> clNone then
    ACanvas.FillRoundRect(R, Rad, Fill, 255);
  if Border <> clNone then
    if Sel then
      ACanvas.FrameRoundRect(R, Rad, PPGScale(2, PPI), Border, 255)
    else
      ACanvas.FrameRoundRect(R, Rad, Max(1, PPGScale(1, PPI)), Border, 255);
  Code := 0;
  if Assigned(FOnGetItemIcon) then
    FOnGetItemIcon(Self, Idx, Code);
  Pic := nil;
  if (FTileStyle = tsCards) and Assigned(FOnGetPicture) then
    FOnGetPicture(Self, Idx, Pic);
  ML := nil;
  Temp := nil;
  TempB := nil;
  try
    if FFilterText <> '' then
      ML := TPPGMarkupLayout.Create;
    F := PPGElementFont(FItemStyle, Font, D.FontStyle, Temp);
    FB := PPGElementFont(FItemStyle, Font, D.FontStyle + [fsBold], TempB);
    TH := ACanvas.MeasureText('Ag', F, 0, False).cy;
    Flags := DT_SINGLELINE or DT_TOP or DT_LEFT;
    BadgeR := Rect(0, 0, 0, 0);
    case FTileStyle of
      tsIcons:
        begin
          IconSz := Min(R.Right - R.Left - 2 * P, (R.Bottom - R.Top) - 2 * TH - 3 * P div 2);
          SymR := Rect((R.Left + R.Right - IconSz) div 2, R.Top + P, (R.Left + R.Right + IconSz) div 2,
            R.Top + P + IconSz);
          DrawSymbol(SymR, Txt);
          TitleR := Rect(R.Left + P div 2, SymR.Bottom + P div 2, R.Right - P div 2, R.Bottom - P div 2);
          DrawLine(TitleR, D.Text, F, Txt, DT_CENTER or DT_WORDBREAK or DT_TOP);
        end;
      tsTiles:
        begin
          IconSz := (R.Bottom - R.Top) - 2 * P;
          SymR := Rect(R.Left + P, R.Top + P, R.Left + P + IconSz, R.Top + P + IconSz);
          if UseRightToLeftAlignment then
            SymR := Rect(R.Right - P - IconSz, SymR.Top, R.Right - P, SymR.Bottom);
          if (Code <> 0) or ((FImages <> nil) and (D.ImageIndex >= 0)) then
          begin
            // Symbol auf zarter Akzentflaeche (wie Fluent-Kacheln)
            ACanvas.FillRoundRect(SymR, PPGScale(6, PPI), Accent, 26);
            Ix := IconSz * 3 div 5;
            DrawSymbol(Rect((SymR.Left + SymR.Right - Ix) div 2, (SymR.Top + SymR.Bottom - Ix) div 2,
              (SymR.Left + SymR.Right + Ix) div 2, (SymR.Top + SymR.Bottom + Ix) div 2), Accent);
            if UseRightToLeftAlignment then
              TitleR := Rect(R.Left + P, R.Top, SymR.Left - P, R.Bottom)
            else
              TitleR := Rect(SymR.Right + P, R.Top, R.Right - P, R.Bottom);
          end
          else
            TitleR := Rect(R.Left + P, R.Top, R.Right - P, R.Bottom);
          if D.Badge <> '' then
          begin
            BadgeW := ACanvas.MeasureText(D.Badge, F, 0, False).cx + P;
            if UseRightToLeftAlignment then
            begin
              BadgeR := Rect(TitleR.Left, R.Top + P, TitleR.Left + BadgeW, R.Top + P + TH + 2);
              TitleR.Left := BadgeR.Right + P div 2;
            end
            else
            begin
              BadgeR := Rect(TitleR.Right - BadgeW, R.Top + P, TitleR.Right, R.Top + P + TH + 2);
              TitleR.Right := BadgeR.Left - P div 2;
            end;
          end;
          Y := (R.Top + R.Bottom) div 2 - TH;
          if D.Detail = '' then
            Y := (R.Top + R.Bottom - TH) div 2;
          DrawLine(Rect(TitleR.Left, Y, TitleR.Right, Y + TH), D.Text, FB, Txt, Flags);
          DrawLine(Rect(TitleR.Left, Y + TH + 2, TitleR.Right, Y + 2 * TH + 2), D.Detail, F,
            Secondary, Flags);
        end;
    else
      begin
        // Karte: Bild oben, darunter Titel und zwei Zeilen Detail
        PicR := Rect(R.Left + 1, R.Top + 1, R.Right - 1, R.Top + (R.Bottom - R.Top) * 11 div 20);
        ACanvas.PushClipRoundRect(PicR, Rad);
        try
          if Pic <> nil then
          begin
            DC := ACanvas.BeginGdi;
            try
              Cv := TCanvas.Create;
              try
                Cv.Handle := DC;
                // Seitenverhaeltnis halten, Flaeche fuellen
                if (Pic.Width > 0) and (Pic.Height > 0) then
                begin
                  X := PicR.Right - PicR.Left;
                  Y := MulDiv(X, Pic.Height, Pic.Width);
                  if Y < PicR.Bottom - PicR.Top then
                  begin
                    Y := PicR.Bottom - PicR.Top;
                    X := MulDiv(Y, Pic.Width, Pic.Height);
                  end;
                  Cv.StretchDraw(Rect((PicR.Left + PicR.Right - X) div 2, (PicR.Top + PicR.Bottom - Y) div 2,
                    (PicR.Left + PicR.Right + X) div 2, (PicR.Top + PicR.Bottom + Y) div 2), Pic);
                end;
              finally
                Cv.Handle := 0;
                Cv.Free;
              end;
            finally
              ACanvas.EndGdi(DC);
            end;
          end
          else
          begin
            ACanvas.FillRoundRect(PicR, 0, Accent, 30);
            IconSz := (PicR.Bottom - PicR.Top) div 2;
            DrawSymbol(Rect((PicR.Left + PicR.Right - IconSz) div 2, (PicR.Top + PicR.Bottom - IconSz) div 2,
              (PicR.Left + PicR.Right + IconSz) div 2, (PicR.Top + PicR.Bottom + IconSz) div 2), Accent);
          end;
        finally
          ACanvas.PopClip;
        end;
        if D.Badge <> '' then
        begin
          BadgeW := ACanvas.MeasureText(D.Badge, F, 0, False).cx + P;
          BadgeR := Rect(PicR.Right - P - BadgeW, PicR.Top + P, PicR.Right - P, PicR.Top + P + TH + 2);
          if UseRightToLeftAlignment then
            BadgeR := Rect(PicR.Left + P, BadgeR.Top, PicR.Left + P + BadgeW, BadgeR.Bottom);
        end;
        TitleR := Rect(R.Left + P, PicR.Bottom + P div 2, R.Right - P, PicR.Bottom + P div 2 + TH);
        DrawLine(TitleR, D.Text, FB, Txt, Flags);
        DetR := Rect(R.Left + P, TitleR.Bottom + 2, R.Right - P, R.Bottom - P div 2);
        DrawLine(DetR, D.Detail, F, Secondary, DT_WORDBREAK or DT_TOP or DT_LEFT);
      end;
    end;
    // Plakette (Badge)
    if not IsRectEmpty(BadgeR) then
    begin
      if Usable then
        ACanvas.FillRoundRect(BadgeR, (BadgeR.Bottom - BadgeR.Top) div 2, Accent, 255)
      else
        ACanvas.FillRoundRect(BadgeR, (BadgeR.Bottom - BadgeR.Top) div 2, Txt, 120);
      ACanvas.DrawText(BadgeR, D.Badge, F, Tokens.OnAccent,
        DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_NOPREFIX);
    end;
    // Kaestchen oben links
    if FCheckboxes then
    begin
      IconSz := PPGScale(16, PPI);
      ChkR := Rect(R.Left + P div 2, R.Top + P div 2, R.Left + P div 2 + IconSz, R.Top + P div 2 + IconSz);
      if UseRightToLeftAlignment then
        ChkR := Rect(R.Right - P div 2 - IconSz, ChkR.Top, R.Right - P div 2, ChkR.Bottom);
      if not Supports(Renderer, IPPGIndicatorRenderer, IR) then
        Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName), IPPGIndicatorRenderer, IR);
      if D.Checked <> cbUnchecked then
        ChkStyle := A.ResolveStyle(A.Checked, PPI, False)
      else if Usable then
        ChkStyle := A.Resolve(vsNormal, PPI, False)
      else
        ChkStyle := A.Resolve(vsDisabled, PPI, False);
      ChkStyle.GlowAlpha := 0;
      if IR <> nil then
        IR.DrawCheckIndicator(ACanvas, ChkR, ChkStyle, D.Checked, PPI);
    end;
  finally
    TempB.Free;
    Temp.Free;
    ML.Free;
  end;
  if Foc then
  begin
    SymR := R;
    InflateRect(SymR, PPGScale(2, PPI), PPGScale(2, PPI));
    ACanvas.FrameRoundRect(SymR, Rad + PPGScale(2, PPI), PPGScale(2, PPI), Accent, 255);
  end;
end;

procedure TPPGCustomTileView.PaintViewport(const ACanvas: IPPGCanvas; const View: TRect);
var
  I, Lo, Hi, Mid, Top, Bottom: Integer;
  R: TRect;
  S: string;
  C: TColor;
  Temp: TFont;
  F: TFont;
begin
  EnsureLayout;
  Top := ScrollY;
  Bottom := ScrollY + (View.Bottom - View.Top);
  for I := 0 to High(FHeads) do
    if (FHeads[I].R.Bottom > Top) and (FHeads[I].R.Top < Bottom) then
    begin
      R := FHeads[I].R;
      OffsetRect(R, View.Left - ScrollX, View.Top - ScrollY);
      PaintHead(ACanvas, I, R);
    end;
  if Length(FViewRect) = 0 then
  begin
    // Nichts zu zeigen: Hinweis mittig
    S := FEmptyText;
    if S = '' then
      if (FFilterText <> '') and (FSource.Count > 0) then
        S := PPGStr(@SPPGTileNoMatch)
      else
        S := PPGStr(@SPPGTileEmpty);
    if UseDarkMode then
      C := Tokens.TextSecondary
    else
      C := PPGBlendColor(PPGColorToRGB(Font.Color), GetBackgroundColor, 0.45);
    Temp := nil;
    try
      F := PPGStyledFont(Font, [], Temp);
      ACanvas.DrawText(View, S, F, C, DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_NOPREFIX);
    finally
      Temp.Free;
    end;
  end;
  // Erste sichtbare Kachel per binaerer Suche
  Lo := 0;
  Hi := High(FViewRect);
  while Lo < Hi do
  begin
    Mid := (Lo + Hi) div 2;
    if FViewRect[Mid].Bottom <= Top then
      Lo := Mid + 1
    else
      Hi := Mid;
  end;
  for I := Lo to High(FViewRect) do
  begin
    if FViewRect[I].Top >= Bottom then
      Break;
    R := FViewRect[I];
    OffsetRect(R, View.Left - ScrollX, View.Top - ScrollY);
    PaintTile(ACanvas, I, R);
  end;
  // Gummiband
  if FBanding then
  begin
    R := FBandRect;
    OffsetRect(R, View.Left - ScrollX, View.Top - ScrollY);
    ACanvas.FillRoundRect(R, 0, PPGColorToRGB(EffectiveAppearance.FocusColor), 40);
    ACanvas.FrameRoundRect(R, 0, 1, PPGColorToRGB(EffectiveAppearance.FocusColor), 200);
  end;
end;

{ Maus }

procedure TPPGCustomTileView.ContentMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P, H, I: Integer;
  View, ChkR: TRect;
  D: TPPGItemData;
  St: TCheckBoxState;
begin
  if FEditor <> nil then
    EditorExit(nil);
  if Button <> mbLeft then
  begin
    // Rechtsklick waehlt den Eintrag (Kontextmenue)
    P := PosAt(X, Y);
    if (P >= 0) and not FSelection.Selected[P] then
      FocusPos(P, []);
    Exit;
  end;
  H := HeadAt(X, Y);
  if (H >= 0) and (PosAt(X, Y) < 0) then
  begin
    SetGroupCollapsed(FHeads[H].Text, not FHeads[H].Collapsed);
    Exit;
  end;
  P := PosAt(X, Y);
  FDownPos := P;
  if P < 0 then
  begin
    // Leere Flaeche: Gummiband (Strg = hinzufuegen)
    if not (ssCtrl in Shift) then
      FSelection.Clear;
    if FMultiSelect then
    begin
      View := ViewRect;
      FBandStart := Point(X - View.Left + ScrollX, Y - View.Top + ScrollY);
      FBandRect := Rect(FBandStart.X, FBandStart.Y, FBandStart.X, FBandStart.Y);
      FBanding := True;
      SetLength(FBandBase, Length(FViewIndex));
      for I := 0 to High(FBandBase) do
        FBandBase[I] := FSelection.Selected[I];
    end;
    DoChange;
    Exit;
  end;
  // Kaestchen?
  if FCheckboxes then
  begin
    ChkR := PosClientRect(P);
    ChkR := Rect(ChkR.Left, ChkR.Top, ChkR.Left + PPGScale(28, ScalePPI), ChkR.Top + PPGScale(28, ScalePPI));
    if UseRightToLeftAlignment then
      ChkR := Rect(PosClientRect(P).Right - PPGScale(28, ScalePPI), ChkR.Top, PosClientRect(P).Right,
        ChkR.Bottom);
    if PtInRect(ChkR, Point(X, Y)) then
    begin
      D := GetItemData(FViewIndex[P]);
      if D.Enabled and not FReadOnly then
      begin
        if D.Checked = cbChecked then
          St := cbUnchecked
        else
          St := cbChecked;
        FSource.SetChecked(FViewIndex[P], St);
        NotifyAccessibilityChild(EVENT_OBJECT_STATECHANGE, P + 1);
      end;
      Exit;
    end;
  end;
  if FMultiSelect then
    FSelection.Click(P, Shift)
  else
    FSelection.Click(P, []);
  NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, P + 1);
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, FViewIndex[P]);
  DoChange;
end;

procedure TPPGCustomTileView.ContentMouseMove(Shift: TShiftState; X, Y: Integer);
var
  P, H, I: Integer;
  View, Inter: TRect;
  C: TPoint;
begin
  if FBanding then
  begin
    View := ViewRect;
    C := Point(X - View.Left + ScrollX, Y - View.Top + ScrollY);
    FBandRect := Rect(Min(FBandStart.X, C.X), Min(FBandStart.Y, C.Y), Max(FBandStart.X, C.X),
      Max(FBandStart.Y, C.Y));
    FSelection.BeginUpdate;
    try
      for I := 0 to High(FViewRect) do
        if I <= High(FBandBase) then
          FSelection.Selected[I] := FBandBase[I] or IntersectRect(Inter, FViewRect[I], FBandRect);
    finally
      FSelection.EndUpdate;
    end;
    AutoScrollAt(X, Y);
    Invalidate;
    Exit;
  end;
  P := PosAt(X, Y);
  H := -1;
  if P < 0 then
    H := HeadAt(X, Y);
  if (P <> FHot) or (H <> FHotHead) then
  begin
    FHot := P;
    FHotHead := H;
    Application.CancelHint;
    Invalidate;
  end;
end;

procedure TPPGCustomTileView.ContentMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if FBanding then
  begin
    FBanding := False;
    StopAutoScroll;
    SetLength(FBandBase, 0);
    DoChange;
    Invalidate;
  end;
  FDownPos := -1;
end;

procedure TPPGCustomTileView.DoAutoScroll(const P: TPoint);
begin
  inherited DoAutoScroll(P);
  if FBanding then
    ContentMouseMove([ssLeft], P.X, P.Y);
end;

procedure TPPGCustomTileView.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if (FHot <> -1) or (FHotHead <> -1) then
  begin
    FHot := -1;
    FHotHead := -1;
    Invalidate;
  end;
end;

procedure TPPGCustomTileView.DoEnter;
begin
  inherited DoEnter;
  // Wie der Explorer: ohne Fokus-Eintrag traegt der erste den Fokusrahmen
  EnsureLayout;
  if (FSelection.Focus < 0) and (Length(FViewIndex) > 0) then
    FSelection.Focus := 0;
  if FSelection.Focus >= 0 then
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, FSelection.Focus + 1);
  Invalidate;
end;

procedure TPPGCustomTileView.DblClick;
var
  I: Integer;
begin
  inherited DblClick;
  I := ViewItem(FSelection.Focus);
  if (I >= 0) and Assigned(FOnItemDblClick) and (FHot = FSelection.Focus) then
    FOnItemDblClick(Self, I);
end;

function TPPGCustomTileView.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  if ssCtrl in Shift then
  begin
    // Strg+Rad: Zoom in 10er-Schritten
    if WheelDelta > 0 then
      Zoom := Min(200, FZoom + 10)
    else
      Zoom := Max(50, FZoom - 10);
    Result := True;
    Exit;
  end;
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
end;

function TPPGCustomTileView.TileTextTruncated(Pos: Integer): Boolean;
var
  R: TRect;
  PPI, P, TH, IconSz, W, H, PicBottom: Integer;
  D: TPPGItemData;
  Code: Word;
  F, FB, Temp, TempB: TFont;
  Sz: TSize;
begin
  // Dieselbe Aufteilung wie PaintTile, nur gemessen (ohne Canvas)
  Result := False;
  R := PosClientRect(Pos);
  if IsRectEmpty(R) then
    Exit;
  D := GetItemData(FViewIndex[Pos]);
  PPI := ScalePPI;
  P := PPGScale(MulDiv(Pad, FZoom, 100), PPI);
  Temp := nil;
  TempB := nil;
  try
    F := PPGElementFont(FItemStyle, Font, D.FontStyle, Temp);
    FB := PPGElementFont(FItemStyle, Font, D.FontStyle + [fsBold], TempB);
    TH := PPGMeasureTextNoCanvas('Ag', F, 0, False).cy;
    case FTileStyle of
      tsIcons:
        begin
          // Titel unter dem Symbol, umbrechend
          IconSz := Min(R.Right - R.Left - 2 * P, (R.Bottom - R.Top) - 2 * TH - 3 * P div 2);
          W := (R.Right - R.Left) - 2 * (P div 2);
          H := (R.Bottom - P div 2) - (R.Top + P + IconSz + P div 2);
          Sz := PPGMeasureTextNoCanvas(D.Text, F, Max(W, 1), True);
          Result := (Sz.cx > W) or (Sz.cy > H);
        end;
      tsTiles:
        begin
          // Titel und Detail je eine Zeile neben dem Symbol, vor der Plakette
          IconSz := (R.Bottom - R.Top) - 2 * P;
          Code := 0;
          if Assigned(FOnGetItemIcon) then
            FOnGetItemIcon(Self, FViewIndex[Pos], Code);
          W := (R.Right - R.Left) - 2 * P;
          if (Code <> 0) or ((FImages <> nil) and (D.ImageIndex >= 0)) then
            Dec(W, IconSz + P);
          if D.Badge <> '' then
            Dec(W, PPGMeasureTextNoCanvas(D.Badge, F, 0, False).cx + P + P div 2);
          Result := (PPGMeasureTextNoCanvas(D.Text, FB, 0, False).cx > W) or
            (PPGMeasureTextNoCanvas(D.Detail, F, 0, False).cx > W);
        end;
    else
      begin
        // Karte: Titel eine Zeile, Detail umbrechend bis zum unteren Rand
        W := (R.Right - R.Left) - 2 * P;
        PicBottom := R.Top + (R.Bottom - R.Top) * 11 div 20;
        H := (R.Bottom - P div 2) - (PicBottom + P div 2 + TH + 2);
        Result := PPGMeasureTextNoCanvas(D.Text, FB, 0, False).cx > W;
        if not Result and (D.Detail <> '') then
        begin
          Sz := PPGMeasureTextNoCanvas(D.Detail, F, Max(W, 1), True);
          Result := (Sz.cx > W) or (Sz.cy > H);
        end;
      end;
    end;
  finally
    TempB.Free;
    Temp.Free;
  end;
end;

procedure TPPGCustomTileView.CMHintShow(var Message: TCMHintShow);
var
  P: Integer;
  D: TPPGItemData;
begin
  inherited;
  // Audit 7f #2: eigener Hint hat Vorrang; sonst nur abgeschnittene Beschriftung
  if (Hint <> '') or (Message.HintInfo = nil) then
    Exit;
  P := PosAt(Message.HintInfo.CursorPos.X, Message.HintInfo.CursorPos.Y);
  if (P >= 0) and TileTextTruncated(P) then
  begin
    // Abgeschnittene Beschriftung als Hint (Titel und Detail)
    D := GetItemData(FViewIndex[P]);
    Message.HintInfo.HintStr := D.Text;
    if D.Detail <> '' then
      Message.HintInfo.HintStr := Message.HintInfo.HintStr + #13#10 + D.Detail;
    Message.HintInfo.CursorRect := PosClientRect(P);
  end;
end;

{ Tastatur }

procedure TPPGCustomTileView.KeyDown(var Key: Word; Shift: TShiftState);
var
  F, N, I, Page: Integer;
begin
  EnsureLayout;
  F := FSelection.Focus;
  N := -2;
  case Key of
    VK_LEFT: N := PosInDirection(F, -1, 0);
    VK_RIGHT: N := PosInDirection(F, 1, 0);
    VK_UP: N := PosInDirection(F, 0, -1);
    VK_DOWN: N := PosInDirection(F, 0, 1);
    VK_HOME: if Length(FViewIndex) > 0 then N := 0;
    VK_END: if Length(FViewIndex) > 0 then N := High(FViewIndex);
    VK_PRIOR, VK_NEXT:
      if (F >= 0) and (Length(FViewIndex) > 0) then
      begin
        // Um eine Ansichtshoehe weiter (zeilenweise, bis die Hoehe erreicht ist)
        Page := ViewRect.Bottom - ViewRect.Top;
        N := F;
        repeat
          if Key = VK_NEXT then
            I := PosInDirection(N, 0, 1)
          else
            I := PosInDirection(N, 0, -1);
          if I < 0 then
            Break;
          N := I;
        until Abs(FViewRect[N].Top - FViewRect[F].Top) >= Page - TileSize.cy;
      end;
    VK_SPACE:
      if F >= 0 then
      begin
        if FCheckboxes and not FReadOnly then
        begin
          if GetItemData(FViewIndex[F]).Checked = cbChecked then
            FSource.SetChecked(FViewIndex[F], cbUnchecked)
          else
            FSource.SetChecked(FViewIndex[F], cbChecked);
        end
        else if FMultiSelect and (ssCtrl in Shift) then
          FSelection.ToggleFocused;
        DoChange;
        Key := 0;
      end;
    VK_RETURN:
      if (F >= 0) and Assigned(FOnItemDblClick) then
      begin
        FOnItemDblClick(Self, FViewIndex[F]);
        Key := 0;
      end;
    VK_F2:
      if F >= 0 then
      begin
        EditItem(FViewIndex[F]);
        Key := 0;
      end;
    Ord('A'):
      if (ssCtrl in Shift) and FMultiSelect then
      begin
        SelectAll;
        DoChange;
        Key := 0;
      end;
  end;
  if N >= -1 then
  begin
    if (N < 0) and (F < 0) and (Length(FViewIndex) > 0) then
      N := 0;
    if N >= 0 then
      FocusPos(N, Shift);
    Key := 0;
  end;
  inherited KeyDown(Key, Shift);
end;

procedure TPPGCustomTileView.KeyPress(var Key: Char);
var
  I, Start, P: Integer;
  S, Text: string;
begin
  inherited KeyPress(Key);
  if (Key < ' ') or (Length(FViewIndex) = 0) then
    Exit;
  // Tippsuche (TPPGTypeAhead): Anfang der Beschriftung, Zeichen innerhalb
  // einer Sekunde sammeln; derselbe Buchstabe wiederholt blaettert weiter
  Text := FTypeBuf.Add(Key);
  Start := FSelection.Focus;
  if Length(Text) = 1 then
    Inc(Start);
  if Start < 0 then
    Start := 0;
  for I := 0 to High(FViewIndex) do
  begin
    P := (Start + I) mod Length(FViewIndex);
    S := GetItemData(FViewIndex[P]).Text;
    if AnsiStartsText(Text, S) then
    begin
      FocusPos(P, []);
      Break;
    end;
  end;
  Key := #0;
end;

{ Umbenennen }

function TPPGCustomTileView.EditItem(Index: Integer): Boolean;
var
  R: TRect;
  D: TPPGItemData;
begin
  Result := False;
  if FReadOnly or not Enabled or (ViewPos(Index) < 0) or not HandleAllocated then
    Exit;
  D := GetItemData(Index);
  if not D.Enabled then
    Exit;
  MakeItemVisible(Index);
  R := ItemRect(Index);
  if FEditor = nil then
  begin
    FEditor := TEdit.Create(Self);
    FEditor.Parent := Self;
    FEditor.OnKeyDown := EditorKeyDown;
    FEditor.OnExit := EditorExit;
  end;
  FEditIndex := Index;
  FEditor.Font := Font;
  FEditor.Text := D.Text;
  FEditor.SetBounds(R.Left + 4, R.Bottom - FEditor.Height - 4, R.Right - R.Left - 8, FEditor.Height);
  FEditor.Visible := True;
  if FEditor.CanFocus then
    FEditor.SetFocus;
  FEditor.SelectAll;
  Result := True;
end;

procedure TPPGCustomTileView.EditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    EditorExit(Sender);
    if CanFocus and IsWindowVisible(Handle) then
      SetFocus;
  end
  else if Key = VK_ESCAPE then
  begin
    Key := 0;
    FEditIndex := -1;
    FEditor.Visible := False;
    if CanFocus and IsWindowVisible(Handle) then
      SetFocus;
  end;
end;

procedure TPPGCustomTileView.EditorExit(Sender: TObject);
var
  S: string;
  Accept: Boolean;
  I: Integer;
begin
  if (FEditor = nil) or not FEditor.Visible then
    Exit;
  I := FEditIndex;
  FEditIndex := -1;
  FEditor.Visible := False;
  if I < 0 then
    Exit;
  S := FEditor.Text;
  Accept := S <> '';
  if Assigned(FOnRename) then
    FOnRename(Self, I, S, Accept);
  if Accept and not FOwnerData and (I < FItems.Count) then
    FItems[I].Text := S;
end;

procedure TPPGCustomTileView.WndProc(var Message: TMessage);
begin
  if (GMsgTileAction <> 0) and (Message.Msg = GMsgTileAction) then
  begin
    // Standardaktion des Screenreaders: Eintrag waehlen
    FocusPos(Integer(Message.WParam) - 1, []);
    Exit;
  end;
  inherited WndProc(Message);
end;

{ Barrierefreiheit }

function TPPGCustomTileView.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_LIST;
end;

function TPPGCustomTileView.AccChildCount: Integer;
begin
  Result := VisibleCount;
end;

function TPPGCustomTileView.AccChildName(Id: Integer): string;
var
  D: TPPGItemData;
begin
  Result := '';
  if (Id < 1) or (Id > VisibleCount) then
    Exit;
  D := GetItemData(FViewIndex[Id - 1]);
  Result := D.Text;
  if D.Detail <> '' then
    Result := Result + ', ' + D.Detail;
  if D.Badge <> '' then
    Result := Result + ', ' + D.Badge;
end;

function TPPGCustomTileView.AccChildRole(Id: Integer): Integer;
begin
  if FCheckboxes then
    Result := ROLE_SYSTEM_CHECKBUTTON
  else
    Result := ROLE_SYSTEM_LISTITEM;
end;

function TPPGCustomTileView.AccChildState(Id: Integer): Integer;
var
  P: Integer;
  D: TPPGItemData;
  R: TRect;
begin
  Result := 0;
  P := Id - 1;
  if (P < 0) or (P >= VisibleCount) then
    Exit;
  D := GetItemData(FViewIndex[P]);
  if not Enabled or not D.Enabled then
    Exit(STATE_SYSTEM_UNAVAILABLE);
  Result := STATE_SYSTEM_FOCUSABLE or STATE_SYSTEM_SELECTABLE;
  if FMultiSelect then
    Result := Result or STATE_SYSTEM_MULTISELECTABLE or STATE_SYSTEM_EXTSELECTABLE;
  if FSelection.Selected[P] then
    Result := Result or STATE_SYSTEM_SELECTED;
  if Focused and (P = FSelection.Focus) then
    Result := Result or STATE_SYSTEM_FOCUSED;
  if FCheckboxes and (D.Checked = cbChecked) then
    Result := Result or STATE_SYSTEM_CHECKED;
  R := PosClientRect(P);
  if not IntersectRect(R, R, ViewRect) then
    Result := Result or STATE_SYSTEM_OFFSCREEN;
end;

function TPPGCustomTileView.AccChildRect(Id: Integer): TRect;
begin
  Result := PosClientRect(Id - 1);
end;

function TPPGCustomTileView.AccChildAt(X, Y: Integer): Integer;
begin
  Result := PosAt(X, Y) + 1;
end;

function TPPGCustomTileView.AccChildDefaultAction(Id: Integer): string;
begin
  Result := PPGStr(@SPPGAccSelect);
end;

procedure TPPGCustomTileView.AccChildDoDefault(Id: Integer);
begin
  if HandleAllocated and (GMsgTileAction <> 0) then
    PostMessage(Handle, GMsgTileAction, WPARAM(Id), 0);
end;

function TPPGCustomTileView.AccFocusedChild: Integer;
begin
  if Focused then
    Result := FSelection.Focus + 1
  else
    Result := 0;
end;

function TPPGCustomTileView.AccSelectedChild: Integer;
begin
  Result := FSelection.NextSelected(-1) + 1;
end;

{ IPPGTableSource }

function TPPGCustomTileView.TableColCount: Integer;
begin
  Result := 4;
end;

function TPPGCustomTileView.TableRowCount: Integer;
begin
  Result := VisibleCount;
end;

function TPPGCustomTileView.TableColumn(ACol: Integer): TPPGTableColumnInfo;
begin
  case ACol of
    0:
      begin
        Result.Title := PPGStr(@SPPGTileColText);
        Result.Width := 240;
      end;
    1:
      begin
        Result.Title := PPGStr(@SPPGTileColDetail);
        Result.Width := 260;
      end;
    2:
      begin
        Result.Title := PPGStr(@SPPGTileColBadge);
        Result.Width := 80;
      end;
  else
    begin
      Result.Title := PPGStr(@SPPGTileColGroup);
      Result.Width := 140;
    end;
  end;
  Result.Alignment := taLeftJustify;
  Result.Format := '';
end;

function TPPGCustomTileView.TableCellText(ACol, ARow: Integer): string;
var
  D: TPPGItemData;
begin
  D := GetItemData(ViewItem(ARow));
  case ACol of
    0: Result := D.Text;
    1: Result := D.Detail;
    2: Result := D.Badge;
  else
    Result := D.Group;
  end;
end;

function TPPGCustomTileView.TableCellValue(ACol, ARow: Integer): Variant;
begin
  Result := PPGTableValueOf(TableCellText(ACol, ARow));
end;

initialization
  GMsgTileAction := RegisterWindowMessage('PPGlow.TileView.Action');

end.
