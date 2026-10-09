unit PPG.ListBox;

{ TPPGListBox - Liste im Stil der Suite, DFM-kompatibel zu TListBox.

  Datenquellen (in dieser Rangfolge):
  - Style = lbVirtual/lbVirtualOwnerDraw: Count + OnGetItem bzw. OnData
    (wie TListBox) - Millionen Eintraege, Daten bleiben beim Anwender
  - ItemsEx (Collection): Text, Detail, Bild, Plakette, Gruppe - im Designer
    pflegbar; sobald ItemsEx Eintraege hat, ist es die Quelle
  - Items (TStrings): wie TListBox ("Items.Strings" in der DFM)

  Items ist eine eigene TStringList, die Einfuegen/Loeschen mit Index meldet:
  Auswahl und Fokus wandern mit. Pro Zeile haelt sie eine kleine Huelle
  (Objects[] des Anwenders, Kaestchen-Zustand der CheckListBox), die beim
  Sortieren und Verschieben mitwandert.

  Owner-Draw (lbOwnerDrawFixed/Variable): OnDrawItem zeichnet auf Canvas
  (waehrend des Aufrufs ein TCanvas auf dem Zeichenpuffer, Hintergrund und
  Auswahl hat das Preset schon gezeichnet), OnMeasureItem liefert Hoehen. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  PPG.Types, PPG.Items, PPG.Render.Intf, PPG.Controls.ItemList, PPG.ItemPainter;

type
  TPPGCustomListBox = class;

  /// Huelle pro Zeile von Items (intern; Objects[] liefert das Anwender-Objekt).
  TPPGListItemWrapper = class
  public
    Obj: TObject;
    State: TCheckBoxState;
    Disabled: Boolean;
    Header: Boolean;
  end;

  /// Items der ListBox: meldet Aenderungen mit Index an die ListBox.
  TPPGListBoxStrings = class(TStringList)
  private
    FOwner: TPPGCustomListBox;
    FInsertRaw: Boolean;
  protected
    function GetObject(Index: Integer): TObject; override;
    procedure PutObject(Index: Integer; AObject: TObject); override;
    procedure Put(Index: Integer; const S: string); override;
    procedure InsertItem(Index: Integer; const S: string; AObject: TObject); override;
  public
    constructor Create(AOwner: TPPGCustomListBox);
    destructor Destroy; override;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Exchange(Index1, Index2: Integer); override;
    procedure Move(CurIndex, NewIndex: Integer); override;
    procedure CustomSort(Compare: TStringListSortCompare); override;
    /// Huelle einer Zeile (nie nil fuer gueltige Indizes).
    function Wrapper(Index: Integer): TPPGListItemWrapper;
  end;

  TPPGListBoxMode = (lmStrings, lmItemsEx, lmVirtual);

  TPPGCustomListBox = class(TPPGCustomItemList)
  private
    FItems: TPPGListBoxStrings;
    FItemsEx: TPPGItems;
    FStyle: TListBoxStyle;
    FMultiSelect: Boolean;
    FExtendedSelect: Boolean;
    FVirtualCount: Integer;
    FColumns: Integer;
    FIntegralHeight: Boolean;
    FScrollWidth: Integer;
    FTabWidth: Integer;
    FHasDetail: Boolean;
    FHasGroups: Boolean;
    FLoadedItemIndex: Integer;
    FItemCanvas: TCanvas;
    FInOwnerDraw: Boolean;
    FOnData: TLBGetDataEvent;
    FOnDataObject: TLBGetDataObjectEvent;
    FOnDataFind: TLBFindDataEvent;
    FOnGetItem: TPPGGetItemEvent;
    FOnDrawItem: TDrawItemEvent;
    FOnMeasureItem: TMeasureItemEvent;
    function GetItems: TStrings;
    procedure SetItems(const Value: TStrings);
    procedure SetItemsEx(const Value: TPPGItems);
    procedure SetStyle(const Value: TListBoxStyle);
    procedure SetMultiSelect(const Value: Boolean);
    procedure SetExtendedSelect(const Value: Boolean);
    procedure SetVirtualCount(const Value: Integer);
    function GetSorted: Boolean;
    procedure SetSorted(const Value: Boolean);
    function GetCanvas: TCanvas;
    function GetAutoComplete: Boolean;
    procedure SetAutoComplete(const Value: Boolean);
    function GetListItemIndex: Integer;
    procedure SetListItemIndex(const Value: Integer);
    procedure UpdateSelectMode;
    procedure ItemsExChange(Sender: TObject; Index: Integer);
    procedure ScanItemsEx;
    function IsVirtualStyle: Boolean;
    function IsOwnerDraw: Boolean;
    procedure SetColumns(const Value: Integer);
    procedure SetIntegralHeight(const Value: Boolean);
    procedure SetScrollWidth(const Value: Integer);
    procedure SetTabWidth(const Value: Integer);
    function IntegralHeightFor(AHeight: Integer): Integer;
    procedure ApplyIntegralHeight;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    procedure Loaded; override;
    function ListColumns: Integer; override;
    function ListScrollWidth: Integer; override;
    function ListTabWidth: Integer; override;
    function Mode: TPPGListBoxMode;
    { Meldungen von Items }
    procedure StringsInserted(Index: Integer); virtual;
    procedure StringsDeleted(Index: Integer); virtual;
    procedure StringsReset; virtual;
    procedure StringChanged(Index: Integer); virtual;
    { TPPGCustomItemList }
    procedure GetItemData(Index: Integer; var Data: TPPGItemData); override;
    function UseVariableRows: Boolean; override;
    function MeasureItem(Index: Integer; const Data: TPPGItemData): Integer; override;
    function TwoLineItems: Boolean; override;
    function CanSelectItem(Index: Integer): Boolean; override;
    procedure PaintItem(const ACanvas: IPPGCanvas; Index: Integer; const R: TRect;
      const Data: TPPGItemData; const Info: TPPGItemPaintInfo); override;
    function DoReorder(FromIndex, ToIndex: Integer): Boolean; override;
    function FindItemByPrefix(const S: string; Start: Integer): Integer; override;
    procedure UserSelectionChanged; override;
    { Schnittstelle fuer die CheckListBox }
    function SourceSetChecked(Index: Integer; Value: TCheckBoxState): Boolean; virtual;

    property Items: TStrings read GetItems write SetItems;
    property ItemsEx: TPPGItems read FItemsEx write SetItemsEx;
    property Style: TListBoxStyle read FStyle write SetStyle default lbStandard;
    property MultiSelect: Boolean read FMultiSelect write SetMultiSelect default False;
    property ExtendedSelect: Boolean read FExtendedSelect write SetExtendedSelect default True;
    property Sorted: Boolean read GetSorted write SetSorted default False;
    /// Tippsuche ueber die Anfangsbuchstaben (wie TListBox.AutoComplete).
    property AutoComplete: Boolean read GetAutoComplete write SetAutoComplete default True;
    /// Wie TListBox.Columns: Eintraege in so vielen sichtbaren Spalten nebeneinander,
    /// waagerechter Bildlauf (0 = einspaltig; Gruppen/Detailzeilen bleiben einspaltig).
    property Columns: Integer read FColumns write SetColumns default 0;
    /// Hoehe auf ganze Zeilen runden (nur ohne Align = alClient/alLeft/alRight).
    property IntegralHeight: Boolean read FIntegralHeight write SetIntegralHeight default False;
    /// Breite fuer waagerechten Bildlauf in px (0 = keiner).
    property ScrollWidth: Integer read FScrollWidth write SetScrollWidth default 0;
    /// Tabulatorabstand in Dialogeinheiten (1/4 mittlere Zeichenbreite); 0 = Tabs nicht aufloesen.
    property TabWidth: Integer read FTabWidth write SetTabWidth default 0;
  public
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  protected
    property OnData: TLBGetDataEvent read FOnData write FOnData;
    property OnDataObject: TLBGetDataObjectEvent read FOnDataObject write FOnDataObject;
    property OnDataFind: TLBFindDataEvent read FOnDataFind write FOnDataFind;
    /// Virtuell mit allen Angaben (Text, Detail, Bild, Plakette, Kaestchen).
    property OnGetItem: TPPGGetItemEvent read FOnGetItem write FOnGetItem;
    property OnDrawItem: TDrawItemEvent read FOnDrawItem write FOnDrawItem;
    property OnMeasureItem: TMeasureItemEvent read FOnMeasureItem write FOnMeasureItem;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear; virtual;
    procedure AddItem(const Item: string; AObject: TObject);
    procedure DeleteSelected;
    procedure CopySelection(Destination: TCustomListControl); overload;
    procedure MoveSelection(Destination: TCustomListControl); overload;
    /// Wie TListBox: Existing = False liefert unterhalb des letzten Eintrags Count.
    function ItemAtPos(Pos: TPoint; Existing: Boolean): Integer; overload;
    /// Waehrend OnDrawItem der Zeichen-Canvas, sonst der des Controls.
    property Canvas: TCanvas read GetCanvas;
    /// Anzahl im virtuellen Stil (wie TListBox.Count).
    property Count: Integer read ItemCount write SetVirtualCount;
    property ItemIndex: Integer read GetListItemIndex write SetListItemIndex default -1;
  end;

  TPPGListBox = class(TPPGCustomListBox)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Images;
    property ItemsEx;
    property AllowMarkup;
    property AllowReorder;
    property Styles;
    property ScrollBarMode;
    property SmoothScrolling;
    property HighContrastSupport;
    { wie TListBox }
    property Align;
    property Anchors;
    property AutoComplete;
    property BiDiMode;
    property BorderStyle;
    property Color default clWindow;
    property Columns;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property ExtendedSelect;
    property Font;
    property IntegralHeight;
    property ItemHeight;
    property Items;
    property MultiSelect;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ScrollWidth;
    property ShowHint;
    property Sorted;
    property Style;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop default True;
    property TabWidth;
    property Visible;
    property Touch;
    property OnGesture;
    property ItemIndex;
    property OnClick;
    property OnContextPopup;
    property OnData;
    property OnDataFind;
    property OnDataObject;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDrawItem;
    property OnCustomDrawItem;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetItem;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMeasureItem;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnReorder;
    property OnScroll;
    property OnStartDock;
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
  PPG.Lang,
  System.SysUtils, PPG.Consts, PPG.Exceptions, PPG.Appearance, PPG.Selection;

type
  /// Quelle der ListBox: fragt je nach Modus Items, ItemsEx oder die Ereignisse.
  TPPGListBoxSource = class(TPPGItemSourceBase)
  private
    FOwner: TPPGCustomListBox;
  public
    constructor Create(AOwner: TPPGCustomListBox);
    function Count: Integer; override;
    procedure GetItem(Index: Integer; var Data: TPPGItemData); override;
    function SetChecked(Index: Integer; Value: TCheckBoxState): Boolean; override;
  end;

{ TPPGListBoxSource }

constructor TPPGListBoxSource.Create(AOwner: TPPGCustomListBox);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TPPGListBoxSource.Count: Integer;
begin
  if FOwner = nil then
    Exit(0);
  case FOwner.Mode of
    lmVirtual: Result := FOwner.FVirtualCount;
    lmItemsEx: Result := FOwner.FItemsEx.Count;
  else
    Result := FOwner.FItems.Count;
  end;
end;

procedure TPPGListBoxSource.GetItem(Index: Integer; var Data: TPPGItemData);
begin
  if FOwner <> nil then
    FOwner.GetItemData(Index, Data);
end;

function TPPGListBoxSource.SetChecked(Index: Integer; Value: TCheckBoxState): Boolean;
begin
  Result := (FOwner <> nil) and FOwner.SourceSetChecked(Index, Value);
end;

{ TPPGListBoxStrings }

constructor TPPGListBoxStrings.Create(AOwner: TPPGCustomListBox);
begin
  inherited Create;
  FOwner := AOwner;
  // Die Huellen gehoeren der Liste: Delete/Clear/Destroy geben sie frei
  OwnsObjects := True;
end;

destructor TPPGListBoxStrings.Destroy;
begin
  FOwner := nil;
  inherited Destroy;
end;

function TPPGListBoxStrings.Wrapper(Index: Integer): TPPGListItemWrapper;
begin
  Result := TPPGListItemWrapper(inherited GetObject(Index));
end;

function TPPGListBoxStrings.GetObject(Index: Integer): TObject;
var
  W: TPPGListItemWrapper;
begin
  W := Wrapper(Index);
  if W = nil then
    Result := nil
  else
    Result := W.Obj;
end;

procedure TPPGListBoxStrings.PutObject(Index: Integer; AObject: TObject);
var
  W: TPPGListItemWrapper;
begin
  W := Wrapper(Index);
  if W <> nil then
    W.Obj := AObject;
end;

procedure TPPGListBoxStrings.Put(Index: Integer; const S: string);
begin
  inherited Put(Index, S);
  if FOwner <> nil then
    FOwner.StringChanged(Index);
end;

procedure TPPGListBoxStrings.InsertItem(Index: Integer; const S: string; AObject: TObject);
var
  W: TPPGListItemWrapper;
begin
  if FInsertRaw then
    inherited InsertItem(Index, S, AObject) // Move: Huelle wandert mit
  else
  begin
    W := TPPGListItemWrapper.Create;
    try
      W.Obj := AObject;
      inherited InsertItem(Index, S, W);
    except
      W.Free;
      raise;
    end;
  end;
  if FOwner <> nil then
    FOwner.StringsInserted(Index);
end;

procedure TPPGListBoxStrings.Delete(Index: Integer);
begin
  inherited Delete(Index);
  if FOwner <> nil then
    FOwner.StringsDeleted(Index);
end;

procedure TPPGListBoxStrings.Clear;
begin
  inherited Clear;
  if FOwner <> nil then
    FOwner.StringsReset;
end;

procedure TPPGListBoxStrings.Exchange(Index1, Index2: Integer);
begin
  inherited Exchange(Index1, Index2);
  if FOwner <> nil then
    FOwner.StringsReset;
end;

procedure TPPGListBoxStrings.Move(CurIndex, NewIndex: Integer);
var
  S: string;
  W: TObject;
begin
  if CurIndex = NewIndex then
    Exit;
  if Sorted then
    raise EPPGError.Create(PPGStr(@SPPGSortedListMove));
  BeginUpdate;
  try
    S := Get(CurIndex);
    W := Wrapper(CurIndex);
    // Huelle nicht freigeben, sondern an der neuen Stelle wieder einsetzen
    OwnsObjects := False;
    try
      Delete(CurIndex);
    finally
      OwnsObjects := True;
    end;
    FInsertRaw := True;
    try
      InsertObject(NewIndex, S, W);
    finally
      FInsertRaw := False;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TPPGListBoxStrings.CustomSort(Compare: TStringListSortCompare);
begin
  inherited CustomSort(Compare);
  if FOwner <> nil then
    FOwner.StringsReset;
end;

{ TPPGCustomListBox }

function TPPGCustomListBox.ListColumns: Integer;
begin
  Result := FColumns;
end;

function TPPGCustomListBox.ListScrollWidth: Integer;
begin
  Result := FScrollWidth;
end;

function TPPGCustomListBox.ListTabWidth: Integer;
begin
  Result := FTabWidth;
end;

procedure TPPGCustomListBox.SetColumns(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'Columns', Value, 0, 1000);
  if FColumns <> V then
  begin
    FColumns := V;
    InvalidateLayout;
  end;
end;

procedure TPPGCustomListBox.SetScrollWidth(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'ScrollWidth', Value, 0, 100000);
  if FScrollWidth <> V then
  begin
    FScrollWidth := V;
    InvalidateLayout;
  end;
end;

procedure TPPGCustomListBox.SetTabWidth(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'TabWidth', Value, 0, 1000);
  if FTabWidth <> V then
  begin
    FTabWidth := V;
    Invalidate;
  end;
end;

procedure TPPGCustomListBox.SetIntegralHeight(const Value: Boolean);
begin
  if FIntegralHeight <> Value then
  begin
    FIntegralHeight := Value;
    ApplyIntegralHeight;
  end;
end;

function TPPGCustomListBox.IntegralHeightFor(AHeight: Integer): Integer;
var
  Frame, RowH, N: Integer;
begin
  // Wie LBS_NOINTEGRALHEIGHT aus: nach unten auf ganze Zeilen, mindestens eine
  Frame := 2 * FrameInset;
  RowH := DefaultItemHeight;
  if RowH < 1 then
    Exit(AHeight);
  N := (AHeight - Frame) div RowH;
  if N < 1 then
    N := 1;
  Result := N * RowH + Frame;
end;

procedure TPPGCustomListBox.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  if FIntegralHeight and not (csLoading in ComponentState) and
    (Align in [alNone, alTop, alBottom, alCustom]) then
    AHeight := IntegralHeightFor(AHeight);
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
end;

procedure TPPGCustomListBox.ApplyIntegralHeight;
begin
  if FIntegralHeight and not (csLoading in ComponentState) then
    SetBounds(Left, Top, Width, Height);
end;

procedure TPPGCustomListBox.CMFontChanged(var Message: TMessage);
begin
  inherited;
  ApplyIntegralHeight;
end;

constructor TPPGCustomListBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FExtendedSelect := True;
  FLoadedItemIndex := -1;
  FItems := TPPGListBoxStrings.Create(Self);
  FItemsEx := TPPGItems.Create(Self);
  FItemsEx.OnChange := ItemsExChange;
  FItemCanvas := TCanvas.Create;
  SetSource(TPPGListBoxSource.Create(Self));
end;

destructor TPPGCustomListBox.Destroy;
begin
  // Meldungen der Datenhaltung abkoppeln, bevor sie freigegeben wird
  if FItems <> nil then
    FItems.FOwner := nil;
  if FItemsEx <> nil then
    FItemsEx.OnChange := nil;
  if Source <> nil then
    TPPGListBoxSource(Source as TObject).FOwner := nil;
  SetSource(nil);
  FreeAndNil(FItemCanvas);
  FreeAndNil(FItemsEx);
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TPPGCustomListBox.Loaded;
begin
  inherited Loaded;
  ScanItemsEx;
  ItemsReset;
  // ItemIndex kann in der DFM vor Items stehen: erst jetzt anwenden
  if FLoadedItemIndex >= 0 then
    SetListItemIndex(FLoadedItemIndex);
  FLoadedItemIndex := -1;
  ApplyIntegralHeight;
end;

function TPPGCustomListBox.IsVirtualStyle: Boolean;
begin
  Result := FStyle in [lbVirtual, lbVirtualOwnerDraw];
end;

function TPPGCustomListBox.IsOwnerDraw: Boolean;
begin
  Result := FStyle in [lbOwnerDrawFixed, lbOwnerDrawVariable, lbVirtualOwnerDraw];
end;

function TPPGCustomListBox.Mode: TPPGListBoxMode;
begin
  if IsVirtualStyle then
    Result := lmVirtual
  else if (FItemsEx <> nil) and (FItemsEx.Count > 0) then
    Result := lmItemsEx
  else
    Result := lmStrings;
end;

function TPPGCustomListBox.GetItems: TStrings;
begin
  Result := FItems;
end;

procedure TPPGCustomListBox.SetItems(const Value: TStrings);
begin
  FItems.Assign(Value);
end;

procedure TPPGCustomListBox.SetItemsEx(const Value: TPPGItems);
begin
  FItemsEx.Assign(Value);
end;

procedure TPPGCustomListBox.StringsInserted(Index: Integer);
begin
  if Mode = lmStrings then
    ItemsInserted(Index, 1);
end;

procedure TPPGCustomListBox.StringsDeleted(Index: Integer);
begin
  if Mode = lmStrings then
    ItemsDeleted(Index, 1);
end;

procedure TPPGCustomListBox.StringsReset;
begin
  if Mode = lmStrings then
    ItemsReset;
end;

procedure TPPGCustomListBox.StringChanged(Index: Integer);
begin
  if Mode = lmStrings then
    ItemChanged(Index);
end;

procedure TPPGCustomListBox.ScanItemsEx;
var
  I: Integer;
begin
  FHasDetail := False;
  FHasGroups := False;
  for I := 0 to FItemsEx.Count - 1 do
  begin
    if FItemsEx[I].Detail <> '' then
      FHasDetail := True;
    if FItemsEx[I].Group <> '' then
      FHasGroups := True;
  end;
end;

procedure TPPGCustomListBox.ItemsExChange(Sender: TObject; Index: Integer);
var
  OldDetail, OldGroups: Boolean;
begin
  if csLoading in ComponentState then
    Exit; // Loaded baut alles neu auf
  OldDetail := FHasDetail;
  OldGroups := FHasGroups;
  ScanItemsEx;
  if (Index >= 0) and (OldDetail = FHasDetail) and (OldGroups = FHasGroups) then
    ItemChanged(Index)
  else
    ItemsReset;
end;

procedure TPPGCustomListBox.GetItemData(Index: Integer; var Data: TPPGItemData);
var
  W: TPPGListItemWrapper;
  It: TPPGItem;
  S: string;
  Obj: TObject;
begin
  PPGInitItemData(Data);
  case Mode of
    lmVirtual:
      if (Index >= 0) and (Index < FVirtualCount) then
      begin
        if Assigned(FOnGetItem) then
          FOnGetItem(Self, Index, Data)
        else
        begin
          S := '';
          if Assigned(FOnData) then
            FOnData(Self, Index, S);
          Data.Text := S;
          if Assigned(FOnDataObject) then
          begin
            Obj := nil;
            FOnDataObject(Self, Index, Obj);
            Data.Data := Obj;
          end;
        end;
      end;
    lmItemsEx:
      if (Index >= 0) and (Index < FItemsEx.Count) then
      begin
        It := FItemsEx[Index];
        Data.Text := It.Text;
        Data.Detail := It.Detail;
        Data.Badge := It.Badge;
        Data.Group := It.Group;
        Data.ImageIndex := It.ImageIndex;
        Data.Checked := It.Checked;
        Data.Enabled := It.Enabled;
        Data.Data := It.Data;
        Data.Color := It.Color;
        Data.TextColor := It.TextColor;
        Data.FontStyle := It.FontStyle;
      end;
  else
    if (Index >= 0) and (Index < FItems.Count) then
    begin
      Data.Text := FItems[Index];
      W := FItems.Wrapper(Index);
      if W <> nil then
      begin
        Data.Data := W.Obj;
        Data.Checked := W.State;
        Data.Enabled := not W.Disabled;
        Data.IsHeader := W.Header;
      end;
    end;
  end;
end;

function TPPGCustomListBox.SourceSetChecked(Index: Integer; Value: TCheckBoxState): Boolean;
begin
  Result := False;
end;

function TPPGCustomListBox.UseVariableRows: Boolean;
begin
  if Mode = lmVirtual then
    Result := False
  else if (FStyle = lbOwnerDrawVariable) and Assigned(FOnMeasureItem) then
    Result := True
  else
    Result := (Mode = lmItemsEx) and FHasGroups;
end;

function TPPGCustomListBox.MeasureItem(Index: Integer; const Data: TPPGItemData): Integer;
begin
  Result := DefaultItemHeight;
  if (FStyle = lbOwnerDrawVariable) and Assigned(FOnMeasureItem) then
    FOnMeasureItem(Self, Index, Result);
end;

function TPPGCustomListBox.TwoLineItems: Boolean;
begin
  Result := (Mode = lmItemsEx) and FHasDetail;
end;

function TPPGCustomListBox.CanSelectItem(Index: Integer): Boolean;
var
  W: TPPGListItemWrapper;
begin
  // Schnell ohne GetItemData: nur Ueberschriften der Strings sind nicht waehlbar
  if (Mode = lmStrings) and (Index >= 0) and (Index < FItems.Count) then
  begin
    W := FItems.Wrapper(Index);
    Result := (W = nil) or not W.Header;
  end
  else
    Result := (Index >= 0) and (Index < Source.Count);
end;

procedure TPPGCustomListBox.PaintItem(const ACanvas: IPPGCanvas; Index: Integer;
  const R: TRect; const Data: TPPGItemData; const Info: TPPGItemPaintInfo);
var
  DC: HDC;
  State: TOwnerDrawState;
  IR: IPPGItemRenderer;
  Sel: Boolean;
begin
  if not IsOwnerDraw or not Assigned(FOnDrawItem) then
  begin
    inherited PaintItem(ACanvas, Index, R, Data, Info);
    Exit;
  end;
  // Owner-Draw: Hintergrund/Auswahl im Stil des Presets, den Inhalt zeichnet
  // der Anwender auf einen TCanvas ueber dem Zeichenpuffer
  Sel := Selection.Selected[Index];
  IR := PPGItemRendererOf(Renderer);
  Painter.PaintItemBackground(ACanvas, IR, R, Info, Data, Index, Sel,
    FocusVisible and (Index = Selection.Focus), Ord(Index = HotIndex));
  State := [];
  if Sel then
    Include(State, odSelected);
  if Focused and (Index = Selection.Focus) then
    Include(State, odFocused);
  if not Enabled or not Data.Enabled then
    Include(State, odDisabled);
  DC := ACanvas.BeginGdi;
  try
    FItemCanvas.Handle := DC;
    try
      FItemCanvas.Font := Font;
      FItemCanvas.Font.Color := Info.ListStyle.TextColor;
      FItemCanvas.Brush.Style := bsClear;
      FInOwnerDraw := True;
      try
        FOnDrawItem(Self, Index, R, State);
      finally
        FInOwnerDraw := False;
      end;
    finally
      FItemCanvas.Handle := 0;
    end;
  finally
    ACanvas.EndGdi(DC);
  end;
end;

function TPPGCustomListBox.GetAutoComplete: Boolean;
begin
  Result := TypeAhead;
end;

procedure TPPGCustomListBox.SetAutoComplete(const Value: Boolean);
begin
  TypeAhead := Value;
end;

function TPPGCustomListBox.GetCanvas: TCanvas;
begin
  if FInOwnerDraw then
    Result := FItemCanvas
  else
    Result := inherited Canvas;
end;

function TPPGCustomListBox.DoReorder(FromIndex, ToIndex: Integer): Boolean;
begin
  Result := False;
  case Mode of
    lmStrings:
      if not FItems.Sorted then
      begin
        FItems.Move(FromIndex, ToIndex);
        Result := True;
      end;
    lmItemsEx:
      begin
        FItemsEx[FromIndex].Index := ToIndex;
        Result := True;
      end;
  end;
end;

function TPPGCustomListBox.FindItemByPrefix(const S: string; Start: Integer): Integer;
begin
  // Virtuell: der Anwender sucht selbst (wie TListBox.OnDataFind)
  if (Mode = lmVirtual) and Assigned(FOnDataFind) then
    Result := FOnDataFind(Self, S)
  else
    Result := inherited FindItemByPrefix(S, Start);
end;

procedure TPPGCustomListBox.UserSelectionChanged;
begin
  inherited UserSelectionChanged;
  Click; // wie TListBox (LBN_SELCHANGE -> OnClick)
end;

procedure TPPGCustomListBox.SetStyle(const Value: TListBoxStyle);
begin
  if FStyle <> Value then
  begin
    FStyle := Value;
    ItemsReset;
  end;
end;

procedure TPPGCustomListBox.UpdateSelectMode;
begin
  if not FMultiSelect then
    Selection.Mode := smSingle
  else if FExtendedSelect then
    Selection.Mode := smExtended
  else
    Selection.Mode := smMulti;
  Invalidate;
end;

procedure TPPGCustomListBox.SetMultiSelect(const Value: Boolean);
begin
  if FMultiSelect <> Value then
  begin
    FMultiSelect := Value;
    UpdateSelectMode;
  end;
end;

procedure TPPGCustomListBox.SetExtendedSelect(const Value: Boolean);
begin
  if FExtendedSelect <> Value then
  begin
    FExtendedSelect := Value;
    UpdateSelectMode;
  end;
end;

procedure TPPGCustomListBox.SetVirtualCount(const Value: Integer);
begin
  if Value < 0 then
    raise EPPGPropertyError.CreateInvalid(Self, 'Count', IntToStr(Value));
  if FVirtualCount <> Value then
  begin
    FVirtualCount := Value;
    if Mode = lmVirtual then
      ItemsReset;
  end;
end;

function TPPGCustomListBox.GetSorted: Boolean;
begin
  Result := FItems.Sorted;
end;

procedure TPPGCustomListBox.SetSorted(const Value: Boolean);
begin
  FItems.Sorted := Value; // sortiert sofort (CustomSort meldet Reset)
end;

function TPPGCustomListBox.GetListItemIndex: Integer;
begin
  Result := inherited ItemIndex;
end;

procedure TPPGCustomListBox.SetListItemIndex(const Value: Integer);
begin
  if csLoading in ComponentState then
  begin
    FLoadedItemIndex := Value;
    Exit;
  end;
  inherited ItemIndex := Value;
end;

procedure TPPGCustomListBox.Clear;
begin
  FItems.Clear;
  FItemsEx.Clear;
  if Mode = lmVirtual then
    Count := 0;
end;

procedure TPPGCustomListBox.AddItem(const Item: string; AObject: TObject);
begin
  FItems.AddObject(Item, AObject);
end;

procedure TPPGCustomListBox.DeleteSelected;
var
  I: Integer;
begin
  case Mode of
    lmStrings:
      begin
        FItems.BeginUpdate;
        try
          for I := FItems.Count - 1 downto 0 do
            if Selection.Selected[I] then
              FItems.Delete(I);
        finally
          FItems.EndUpdate;
        end;
      end;
    lmItemsEx:
      begin
        FItemsEx.BeginUpdate;
        try
          for I := FItemsEx.Count - 1 downto 0 do
            if Selection.Selected[I] then
              FItemsEx.Delete(I);
        finally
          FItemsEx.EndUpdate;
        end;
      end;
  end;
end;

procedure TPPGCustomListBox.CopySelection(Destination: TCustomListControl);
var
  I: Integer;
begin
  if Destination = nil then
    Exit;
  for I := 0 to FItems.Count - 1 do
    if Selection.Selected[I] then
      Destination.AddItem(FItems[I], FItems.Objects[I]);
end;

procedure TPPGCustomListBox.MoveSelection(Destination: TCustomListControl);
begin
  CopySelection(Destination);
  DeleteSelected;
end;

function TPPGCustomListBox.ItemAtPos(Pos: TPoint; Existing: Boolean): Integer;
begin
  Result := inherited ItemAtPos(Pos.X, Pos.Y);
  if (Result < 0) and not Existing and PtInRect(ViewRect, Pos) then
    Result := Source.Count;
end;

end.
