unit PPG.Ribbon.Items;

{ Modell des Ribbons (Phase 14b): Registerkarten -> Gruppen -> Items.

  - Alles sind TOwnedCollections und damit im Objektinspektor und in der
    DFM verschachtelt pflegbar (Tabs[i].Groups[j].Items[k]).
  - Items: Button (gross/mittel/klein), Split-Button, Umschalt-Button,
    Galerie, eingebettetes Control (z.B. TPPGComboBox) und Trenner.
  - Actions als Quelle (wie Menue und ToolBar): Caption, Hint, Enabled,
    Checked, Visible, ImageIndex und OnExecute.
  - Das Modell kennt das Control nicht. Aenderungen und Referenzen auf
    Komponenten (Action, Menue, Control) meldet es ueber IPPGRibbonHost an
    den Besitzer der obersten Collection. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, {$IFDEF PPG_HAS_IMAGENAME}System.UITypes,{$ENDIF} System.SysUtils,
  {$IFDEF PPG_HAS_SYSTEM_ACTIONS}System.Actions,{$ENDIF} Vcl.ActnList, Vcl.Controls,
  Vcl.Graphics, Vcl.Menus, Vcl.ImgList,
  PPG.Types, PPG.Ribbon.Layout;

type
  TPPGRibbonItem = class;
  TPPGRibbonGroup = class;
  TPPGRibbonTab = class;

  TPPGRibbonItemKind = (rikButton, rikSplitButton, rikCheck, rikGallery, rikControl, rikSeparator);

  /// Besitzer des Modells (das Ribbon).
  IPPGRibbonHost = interface
    ['{5B8E2C41-7A9D-4E36-B1F0-3C6D84A92E57}']
    /// Struktur oder Darstellung hat sich geaendert (neu auslegen und zeichnen).
    procedure RibbonModelChanged;
    /// Komponente wird referenziert (FreeNotification setzen).
    procedure RibbonWatch(AComponent: TComponent);
    /// Item.Control hat gewechselt (Parent und Lage verwaltet der Besitzer).
    procedure RibbonControlChanged(Item: TPPGRibbonItem; OldControl: TControl);
  end;

  TPPGRibbonItemActionLink = class(TActionLink)
  protected
    FClient: TPPGRibbonItem;
    procedure AssignClient(AClient: TObject); override;
    function IsCaptionLinked: Boolean; override;
    function IsCheckedLinked: Boolean; override;
    function IsEnabledLinked: Boolean; override;
    function IsHintLinked: Boolean; override;
    function IsImageIndexLinked: Boolean; override;
    function IsVisibleLinked: Boolean; override;
    function IsOnExecuteLinked: Boolean; override;
    procedure SetCaption(const Value: string); override;
    procedure SetChecked(Value: Boolean); override;
    procedure SetEnabled(Value: Boolean); override;
    procedure SetHint(const Value: string); override;
    procedure SetImageIndex(Value: Integer); override;
    procedure SetVisible(Value: Boolean); override;
  end;

  TPPGRibbonItem = class(TCollectionItem)
  private
    FCaption: string;
    FHint: string;
    FKind: TPPGRibbonItemKind;
    FSize: TPPGRibbonSize;
    FMinSize: TPPGRibbonSize;
    FImageIndex: TPPGImageIndex;
    FLargeImageIndex: TPPGImageIndex;
    FIconChar: Word;
    FDown: Boolean;
    FGroupIndex: Integer;
    FEnabled: Boolean;
    FVisible: Boolean;
    FTag: NativeInt;
    FKeyTip: string;
    FBeginColumn: Boolean;
    FSameRow: Boolean;
    FDropDownMenu: TPopupMenu;
    FControl: TControl;
    FGalleryItems: TStrings;
    FGalleryCount: Integer;
    FGalleryIndex: Integer;
    FGalleryColumns: Integer;
    FGalleryPopupColumns: Integer;
    FGalleryItemWidth: Integer;
    FGalleryItemHeight: Integer;
    FGalleryTopRow: Integer;
    FActionLink: TPPGRibbonItemActionLink;
    FOnClick: TNotifyEvent;
    {$IFDEF PPG_HAS_IMAGENAME}
    FImageName: TImageName;
    {$ENDIF}
    procedure SetGroupIndex(const Value: Integer);
    procedure SetCaption(const Value: string);
    procedure SetHint(const Value: string);
    procedure SetKind(const Value: TPPGRibbonItemKind);
    procedure SetSize(const Value: TPPGRibbonSize);
    procedure SetMinSize(const Value: TPPGRibbonSize);
    procedure SetImageIndex(const Value: TPPGImageIndex);
    procedure SetLargeImageIndex(const Value: TPPGImageIndex);
    procedure SetIconChar(const Value: Word);
    procedure SetDown(const Value: Boolean);
    procedure SetEnabled(const Value: Boolean);
    procedure SetVisible(const Value: Boolean);
    procedure SetKeyTip(const Value: string);
    procedure SetBeginColumn(const Value: Boolean);
    procedure SetSameRow(const Value: Boolean);
    procedure SetDropDownMenu(const Value: TPopupMenu);
    procedure SetControl(const Value: TControl);
    procedure SetGalleryItems(const Value: TStrings);
    procedure SetGalleryCount(const Value: Integer);
    procedure SetGalleryIndex(const Value: Integer);
    procedure SetGalleryColumns(const Value: Integer);
    procedure SetGalleryPopupColumns(const Value: Integer);
    procedure SetGalleryItemWidth(const Value: Integer);
    procedure SetGalleryItemHeight(const Value: Integer);
    procedure GalleryItemsChange(Sender: TObject);
    function GetAction: TBasicAction;
    procedure SetAction(const Value: TBasicAction);
    function IsCaptionStored: Boolean;
    function IsHintStored: Boolean;
    function IsEnabledStored: Boolean;
    function IsVisibleStored: Boolean;
    function IsDownStored: Boolean;
    function IsImageIndexStored: Boolean;
    function IsOnClickStored: Boolean;
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean);
    procedure DoActionChange(Sender: TObject);
    {$IFDEF PPG_HAS_IMAGENAME}
    procedure SetImageName(const Value: TImageName);
    {$ENDIF}
  protected
    function GetDisplayName: string; override;
  public
    {$IFDEF PPG_HAS_IMAGENAME}
    /// Bildindex aus ImageName neu bestimmen (ruft der Besitzer, wenn sich
    /// seine Images aendern).
    procedure ResolveImageName;
    {$ENDIF}
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    /// Gruppe des Items (nil fuer Items der Schnellzugriffsleiste).
    function Group: TPPGRibbonGroup;
    /// Besitzer des Modells (das Ribbon) oder nil.
    function RibbonOwner: TComponent;
    /// Anzahl der Galerie-Eintraege (GalleryCount, sonst GalleryItems.Count).
    function GalleryTotal: Integer;
    /// Hat ein Symbol (Bild, grosses Bild oder Zeichen der Symbolschrift).
    function HasIcon(Images, LargeImages: TCustomImageList): Boolean;
    property ActionLink: TPPGRibbonItemActionLink read FActionLink;
    /// Erste sichtbare Zeile der Galerie in der Leiste (Laufzeit, nicht gespeichert).
    property GalleryTopRow: Integer read FGalleryTopRow write FGalleryTopRow;
  published
    property Action: TBasicAction read GetAction write SetAction;
    property Caption: string read FCaption write SetCaption stored IsCaptionStored;
    property Hint: string read FHint write SetHint stored IsHintStored;
    property Kind: TPPGRibbonItemKind read FKind write SetKind default rikButton;
    /// Groesse, solange die Gruppe nicht schrumpfen muss.
    property Size: TPPGRibbonSize read FSize write SetSize default rsLarge;
    /// Kleinste Groesse beim Schrumpfen (rsLarge = bleibt gross).
    property MinSize: TPPGRibbonSize read FMinSize write SetMinSize default rsSmall;
    /// Bild aus Ribbon.Images (klein, 16 px).
    property ImageIndex: TPPGImageIndex read FImageIndex write SetImageIndex
      stored IsImageIndexStored default -1;
    {$IFDEF PPG_HAS_IMAGENAME}
    /// Bild per Namen (TVirtualImageList, ab 10.4); robust gegen Umsortieren.
    property ImageName: TImageName read FImageName write SetImageName;
    {$ENDIF}
    /// Bild aus Ribbon.LargeImages (gross, 32 px); -1 = ImageIndex.
    property LargeImageIndex: TPPGImageIndex read FLargeImageIndex write SetLargeImageIndex default -1;
    /// Zeichen der Symbolschrift (0 = keins), z.B. $E8C8 fuer "Kopieren".
    property IconChar: Word read FIconChar write SetIconChar default 0;
    /// Umschalt-Buttons mit gleichem GroupIndex <> 0 schliessen sich aus (je
    /// Ribbon). Steht vor Down, damit die DFM die Gruppe vor dem Zustand liest.
    property GroupIndex: Integer read FGroupIndex write SetGroupIndex default 0;
    /// Eingerastet (rikCheck).
    property Down: Boolean read FDown write SetDown stored IsDownStored default False;
    property Enabled: Boolean read FEnabled write SetEnabled stored IsEnabledStored default True;
    property Visible: Boolean read FVisible write SetVisible stored IsVisibleStored default True;
    property Tag: NativeInt read FTag write FTag default 0;
    /// Eigener KeyTip ('' = automatisch aus der Beschriftung).
    property KeyTip: string read FKeyTip write SetKeyTip;
    /// Beginnt einen neuen Stapel kleiner Items.
    property BeginColumn: Boolean read FBeginColumn write SetBeginColumn default False;
    /// Steht rechts neben dem vorigen kleinen Item in derselben Zeile.
    property SameRow: Boolean read FSameRow write SetSameRow default False;
    /// Menue des Split-Buttons bzw. eines Buttons, der nur aufklappt.
    property DropDownMenu: TPopupMenu read FDropDownMenu write SetDropDownMenu;
    /// Eingebettetes Control (rikControl); das Ribbon wird sein Parent.
    property Control: TControl read FControl write SetControl;
    /// Texte der Galerie-Eintraege (wenn GalleryCount = 0).
    property GalleryItems: TStrings read FGalleryItems write SetGalleryItems;
    /// Anzahl virtueller Galerie-Eintraege (Inhalt ueber OnGetGalleryItem).
    property GalleryCount: Integer read FGalleryCount write SetGalleryCount default 0;
    /// Gewaehlter Eintrag der Galerie (-1 = keiner).
    property GalleryIndex: Integer read FGalleryIndex write SetGalleryIndex default -1;
    /// Spalten der Galerie in der Leiste.
    property GalleryColumns: Integer read FGalleryColumns write SetGalleryColumns default 4;
    /// Spalten der aufgeklappten Galerie (0 = GalleryColumns + 1).
    property GalleryPopupColumns: Integer read FGalleryPopupColumns write SetGalleryPopupColumns default 0;
    /// Breite eines Galerie-Eintrags (logische px).
    property GalleryItemWidth: Integer read FGalleryItemWidth write SetGalleryItemWidth default 72;
    /// Hoehe eines Galerie-Eintrags (logische px, 0 = volle Hoehe der Leiste).
    property GalleryItemHeight: Integer read FGalleryItemHeight write SetGalleryItemHeight default 0;
    property OnClick: TNotifyEvent read FOnClick write FOnClick stored IsOnClickStored;
  end;

  TPPGRibbonItems = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGRibbonItem;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TPPGRibbonItem;
    function AddButton(const ACaption: string; AIconChar: Word = 0; ASize: TPPGRibbonSize = rsLarge;
      AOnClick: TNotifyEvent = nil): TPPGRibbonItem;
    function AddCheck(const ACaption: string; AIconChar: Word = 0; ASize: TPPGRibbonSize = rsSmall;
      AGroupIndex: Integer = 0): TPPGRibbonItem;
    function AddSeparator: TPPGRibbonItem;
    property Items[Index: Integer]: TPPGRibbonItem read GetItem; default;
  end;

  TPPGRibbonGroup = class(TCollectionItem)
  private
    FCaption: string;
    FItems: TPPGRibbonItems;
    FReduceOrder: Integer;
    FVisible: Boolean;
    FKeyTip: string;
    FImageIndex: TPPGImageIndex;
    FIconChar: Word;
    FShowLauncher: Boolean;
    FLauncherHint: string;
    FTag: NativeInt;
    procedure SetCaption(const Value: string);
    procedure SetItems(const Value: TPPGRibbonItems);
    procedure SetReduceOrder(const Value: Integer);
    procedure SetVisible(const Value: Boolean);
    procedure SetKeyTip(const Value: string);
    procedure SetImageIndex(const Value: TPPGImageIndex);
    procedure SetIconChar(const Value: Word);
    procedure SetShowLauncher(const Value: Boolean);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function Tab: TPPGRibbonTab;
  published
    property Caption: string read FCaption write SetCaption;
    property Items: TPPGRibbonItems read FItems write SetItems;
    /// Reihenfolge beim Schrumpfen: kleinere Werte zuerst, gleiche von rechts.
    property ReduceOrder: Integer read FReduceOrder write SetReduceOrder default 0;
    property Visible: Boolean read FVisible write SetVisible default True;
    /// KeyTip der als Dropdown geschrumpften Gruppe ('' = automatisch).
    property KeyTip: string read FKeyTip write SetKeyTip;
    /// Symbol der geschrumpften Gruppe (Ribbon.LargeImages bzw. Images).
    property ImageIndex: TPPGImageIndex read FImageIndex write SetImageIndex default -1;
    property IconChar: Word read FIconChar write SetIconChar default 0;
    /// Kleiner Pfeil unten rechts (oeffnet einen Dialog, OnLauncherClick).
    property ShowLauncher: Boolean read FShowLauncher write SetShowLauncher default False;
    property LauncherHint: string read FLauncherHint write FLauncherHint;
    property Tag: NativeInt read FTag write FTag default 0;
  end;

  TPPGRibbonGroups = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGRibbonGroup;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPPGRibbonTab);
    function Add: TPPGRibbonGroup;
    function AddGroup(const ACaption: string): TPPGRibbonGroup;
    property Items[Index: Integer]: TPPGRibbonGroup read GetItem; default;
  end;

  TPPGRibbonTab = class(TCollectionItem)
  private
    FCaption: string;
    FGroups: TPPGRibbonGroups;
    FVisible: Boolean;
    FKeyTip: string;
    FContextName: string;
    FContextColor: TColor;
    FTag: NativeInt;
    procedure SetCaption(const Value: string);
    procedure SetGroups(const Value: TPPGRibbonGroups);
    procedure SetVisible(const Value: Boolean);
    procedure SetKeyTip(const Value: string);
    procedure SetContextName(const Value: string);
    procedure SetContextColor(const Value: TColor);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    /// Kontext-Registerkarte (z.B. "Tabellentools"), farbig hervorgehoben.
    function IsContextual: Boolean;
  published
    property Caption: string read FCaption write SetCaption;
    property Groups: TPPGRibbonGroups read FGroups write SetGroups;
    property Visible: Boolean read FVisible write SetVisible default True;
    property KeyTip: string read FKeyTip write SetKeyTip;
    /// Name des Kontexts ('' = normale Registerkarte). Benachbarte Karten mit
    /// gleichem Namen bilden eine Gruppe.
    property ContextName: string read FContextName write SetContextName;
    /// Farbe des Kontexts (clDefault = Akzent des Presets).
    property ContextColor: TColor read FContextColor write SetContextColor default clDefault;
    property Tag: NativeInt read FTag write FTag default 0;
  end;

  TPPGRibbonTabs = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGRibbonTab;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TComponent);
    function Add: TPPGRibbonTab;
    function AddTab(const ACaption: string): TPPGRibbonTab;
    property Items[Index: Integer]: TPPGRibbonTab read GetItem; default;
  end;

/// Besitzer (IPPGRibbonHost) einer Collection bzw. eines Items, sonst nil.
function PPGRibbonHostOf(P: TPersistent; out Host: IPPGRibbonHost): Boolean;

implementation

uses
  PPG.Controls.Base,
  PPG.Exceptions;

function PPGRibbonHostOf(P: TPersistent; out Host: IPPGRibbonHost): Boolean;
var
  Depth: Integer;
begin
  Host := nil;
  Depth := 0;
  // Item -> Collection -> Gruppe -> Collection -> Tab -> Collection -> Ribbon
  while (P <> nil) and (Depth < 10) do
  begin
    if P is TComponent then
      Exit(Supports(P, IPPGRibbonHost, Host));
    if P is TCollectionItem then
      P := TCollectionItem(P).Collection
    else if P is TCollection then
      P := TCollection(P).Owner
    else
      Break;
    Inc(Depth);
  end;
  Result := False;
end;

procedure NotifyHost(P: TPersistent);
var
  H: IPPGRibbonHost;
begin
  if PPGRibbonHostOf(P, H) then
    H.RibbonModelChanged;
end;

procedure WatchComponent(P: TPersistent; AComponent: TComponent);
var
  H: IPPGRibbonHost;
begin
  if (AComponent <> nil) and PPGRibbonHostOf(P, H) then
    H.RibbonWatch(AComponent);
end;

function SameMethod(const A, B: TNotifyEvent): Boolean;
begin
  Result := (TMethod(A).Code = TMethod(B).Code) and (TMethod(A).Data = TMethod(B).Data);
end;

{ TPPGRibbonItemActionLink }

procedure TPPGRibbonItemActionLink.AssignClient(AClient: TObject);
begin
  FClient := AClient as TPPGRibbonItem;
end;

function TPPGRibbonItemActionLink.IsCaptionLinked: Boolean;
begin
  Result := inherited IsCaptionLinked and (Action is TCustomAction) and
    (FClient.Caption = TCustomAction(Action).Caption);
end;

function TPPGRibbonItemActionLink.IsCheckedLinked: Boolean;
begin
  Result := inherited IsCheckedLinked and (Action is TCustomAction) and
    (FClient.Down = TCustomAction(Action).Checked);
end;

function TPPGRibbonItemActionLink.IsEnabledLinked: Boolean;
begin
  Result := inherited IsEnabledLinked and (Action is TCustomAction) and
    (FClient.Enabled = TCustomAction(Action).Enabled);
end;

function TPPGRibbonItemActionLink.IsHintLinked: Boolean;
begin
  Result := inherited IsHintLinked and (Action is TCustomAction) and
    (FClient.Hint = TCustomAction(Action).Hint);
end;

function TPPGRibbonItemActionLink.IsImageIndexLinked: Boolean;
begin
  Result := inherited IsImageIndexLinked and (Action is TCustomAction) and
    (FClient.ImageIndex = TCustomAction(Action).ImageIndex);
end;

function TPPGRibbonItemActionLink.IsVisibleLinked: Boolean;
begin
  Result := inherited IsVisibleLinked and (Action is TCustomAction) and
    (FClient.Visible = TCustomAction(Action).Visible);
end;

function TPPGRibbonItemActionLink.IsOnExecuteLinked: Boolean;
begin
  Result := inherited IsOnExecuteLinked and SameMethod(FClient.OnClick, Action.OnExecute);
end;

procedure TPPGRibbonItemActionLink.SetCaption(const Value: string);
begin
  if IsCaptionLinked then
    FClient.Caption := Value;
end;

procedure TPPGRibbonItemActionLink.SetChecked(Value: Boolean);
begin
  if IsCheckedLinked then
    FClient.Down := Value;
end;

procedure TPPGRibbonItemActionLink.SetEnabled(Value: Boolean);
begin
  if IsEnabledLinked then
    FClient.Enabled := Value;
end;

procedure TPPGRibbonItemActionLink.SetHint(const Value: string);
begin
  if IsHintLinked then
    FClient.Hint := Value;
end;

procedure TPPGRibbonItemActionLink.SetImageIndex(Value: Integer);
begin
  if IsImageIndexLinked then
    FClient.ImageIndex := Value;
end;

procedure TPPGRibbonItemActionLink.SetVisible(Value: Boolean);
begin
  if IsVisibleLinked then
    FClient.Visible := Value;
end;

{ TPPGRibbonItem }

{$IFDEF PPG_HAS_IMAGENAME}
procedure TPPGRibbonItem.ResolveImageName;
var
  Imgs: TCustomImageList;
begin
  Imgs := PPGImagesOf(Self);
  // Unbekannter Name: -1 (die Liste kann zur Laufzeit befuellt werden)
  if (FImageName <> '') and (Imgs <> nil) and Imgs.IsImageNameAvailable then
    ImageIndex := Imgs.GetIndexByName(FImageName);
end;

procedure TPPGRibbonItem.SetImageName(const Value: TImageName);
begin
  if FImageName = Value then
    Exit;
  FImageName := Value;
  ResolveImageName;
end;
{$ENDIF}


constructor TPPGRibbonItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FSize := rsLarge;
  FMinSize := rsSmall;
  FImageIndex := -1;
  FLargeImageIndex := -1;
  FEnabled := True;
  FVisible := True;
  FGalleryIndex := -1;
  FGalleryColumns := 4;
  FGalleryItemWidth := 72;
  FGalleryItems := TStringList.Create;
  TStringList(FGalleryItems).OnChange := GalleryItemsChange;
end;

destructor TPPGRibbonItem.Destroy;
var
  Old: TControl;
  H: IPPGRibbonHost;
begin
  FreeAndNil(FActionLink);
  if FGalleryItems <> nil then
    TStringList(FGalleryItems).OnChange := nil;
  FreeAndNil(FGalleryItems);
  // Das Control bleibt bestehen; der Besitzer gibt es wieder frei
  if FControl <> nil then
  begin
    Old := FControl;
    FControl := nil;
    if PPGRibbonHostOf(Self, H) then
      H.RibbonControlChanged(Self, Old);
  end;
  inherited Destroy;
end;

procedure TPPGRibbonItem.Assign(Source: TPersistent);
var
  S: TPPGRibbonItem;
begin
  if Source is TPPGRibbonItem then
  begin
    S := TPPGRibbonItem(Source);
    FCaption := S.FCaption;
    FHint := S.FHint;
    FKind := S.FKind;
    FSize := S.FSize;
    FMinSize := S.FMinSize;
    FImageIndex := S.FImageIndex;
    FLargeImageIndex := S.FLargeImageIndex;
    FIconChar := S.FIconChar;
    FDown := S.FDown;
    FGroupIndex := S.FGroupIndex;
    FEnabled := S.FEnabled;
    FVisible := S.FVisible;
    FTag := S.FTag;
    FKeyTip := S.FKeyTip;
    FBeginColumn := S.FBeginColumn;
    FSameRow := S.FSameRow;
    FGalleryCount := S.FGalleryCount;
    FGalleryIndex := S.FGalleryIndex;
    FGalleryColumns := S.FGalleryColumns;
    FGalleryPopupColumns := S.FGalleryPopupColumns;
    FGalleryItemWidth := S.FGalleryItemWidth;
    FGalleryItemHeight := S.FGalleryItemHeight;
    FGalleryItems.Assign(S.FGalleryItems);
    FOnClick := S.FOnClick;
    DropDownMenu := S.FDropDownMenu;
    // Ein Control hat genau einen Platz: die Kopie bekommt es nicht
    Action := S.Action;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGRibbonItem.GetDisplayName: string;
begin
  if FKind = rikSeparator then
    Result := '-'
  else if FCaption <> '' then
    Result := FCaption
  else if (FControl <> nil) and (FControl.Name <> '') then
    Result := FControl.Name
  else
    Result := inherited GetDisplayName;
end;

function TPPGRibbonItem.Group: TPPGRibbonGroup;
begin
  if (Collection <> nil) and (Collection.Owner is TPPGRibbonGroup) then
    Result := TPPGRibbonGroup(Collection.Owner)
  else
    Result := nil;
end;

function TPPGRibbonItem.RibbonOwner: TComponent;
var
  P: TPersistent;
  Depth: Integer;
begin
  Result := nil;
  P := Self;
  Depth := 0;
  while (P <> nil) and (Depth < 10) do
  begin
    if P is TComponent then
      Exit(TComponent(P));
    if P is TCollectionItem then
      P := TCollectionItem(P).Collection
    else if P is TCollection then
      P := TCollection(P).Owner
    else
      Exit;
    Inc(Depth);
  end;
end;

function TPPGRibbonItem.GalleryTotal: Integer;
begin
  if FGalleryCount > 0 then
    Result := FGalleryCount
  else
    Result := FGalleryItems.Count;
end;

function TPPGRibbonItem.HasIcon(Images, LargeImages: TCustomImageList): Boolean;
begin
  Result := (FIconChar <> 0) or ((Images <> nil) and (FImageIndex >= 0)) or
    ((LargeImages <> nil) and ((FLargeImageIndex >= 0) or (FImageIndex >= 0)));
end;

procedure TPPGRibbonItem.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetHint(const Value: string);
begin
  FHint := Value; // nur fuer den Tooltip: kein neues Layout
end;

procedure TPPGRibbonItem.SetKind(const Value: TPPGRibbonItemKind);
begin
  if FKind <> Value then
  begin
    FKind := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetSize(const Value: TPPGRibbonSize);
begin
  if FSize <> Value then
  begin
    FSize := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetMinSize(const Value: TPPGRibbonSize);
begin
  if FMinSize <> Value then
  begin
    FMinSize := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetImageIndex(const Value: TPPGImageIndex);
begin
  if FImageIndex <> Value then
  begin
    FImageIndex := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetLargeImageIndex(const Value: TPPGImageIndex);
begin
  if FLargeImageIndex <> Value then
  begin
    FLargeImageIndex := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetIconChar(const Value: Word);
begin
  if FIconChar <> Value then
  begin
    FIconChar := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetGroupIndex(const Value: Integer);
begin
  if FGroupIndex = Value then
    Exit;
  FGroupIndex := Value;
  // Neue Gruppe: ein gedruecktes Item laesst die anderen der Gruppe ausrasten
  if FDown and (Value <> 0) then
  begin
    FDown := False;
    SetDown(True);
  end;
end;

procedure TPPGRibbonItem.SetDown(const Value: Boolean);
var
  Grp: TPPGRibbonGroup;
  T, G, I: Integer;
  Tabs: TCollection;
  Other: TPPGRibbonItem;
begin
  if FDown = Value then
    Exit;
  FDown := Value;
  // Gruppe von Umschalt-Buttons: die anderen im ganzen Ribbon rasten aus
  if Value and (FGroupIndex <> 0) then
  begin
    Grp := Group;
    Tabs := nil;
    if (Grp <> nil) and (Grp.Tab <> nil) then
      Tabs := Grp.Tab.Collection;
    if Tabs <> nil then
    begin
      for T := 0 to Tabs.Count - 1 do
        for G := 0 to TPPGRibbonTab(Tabs.Items[T]).Groups.Count - 1 do
          for I := 0 to TPPGRibbonTab(Tabs.Items[T]).Groups[G].Items.Count - 1 do
          begin
            Other := TPPGRibbonTab(Tabs.Items[T]).Groups[G].Items[I];
            if (Other <> Self) and (Other.FGroupIndex = FGroupIndex) and Other.FDown then
            begin
              Other.FDown := False;
              if Other.Action is TCustomAction then
                TCustomAction(Other.Action).Checked := False;
            end;
          end;
    end
    else if Collection <> nil then
      for I := 0 to Collection.Count - 1 do
      begin
        Other := TPPGRibbonItem(Collection.Items[I]);
        if (Other <> Self) and (Other.FGroupIndex = FGroupIndex) and Other.FDown then
          Other.FDown := False;
      end;
  end;
  Changed(False);
end;

procedure TPPGRibbonItem.SetEnabled(const Value: Boolean);
begin
  if FEnabled <> Value then
  begin
    FEnabled := Value;
    if FControl <> nil then
      FControl.Enabled := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetKeyTip(const Value: string);
begin
  if FKeyTip <> Value then
  begin
    FKeyTip := AnsiUpperCase(Trim(Value));
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetBeginColumn(const Value: Boolean);
begin
  if FBeginColumn <> Value then
  begin
    FBeginColumn := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetSameRow(const Value: Boolean);
begin
  if FSameRow <> Value then
  begin
    FSameRow := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetDropDownMenu(const Value: TPopupMenu);
begin
  if FDropDownMenu <> Value then
  begin
    FDropDownMenu := Value;
    WatchComponent(Self, Value);
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetControl(const Value: TControl);
var
  Old: TControl;
  H: IPPGRibbonHost;
begin
  if FControl = Value then
    Exit;
  if (Value <> nil) and (Value = RibbonOwner) then
    raise EPPGPropertyError.CreateInvalid(RibbonOwner, 'Control', Value.Name);
  Old := FControl;
  FControl := Value;
  if FControl <> nil then
    FKind := rikControl;
  if PPGRibbonHostOf(Self, H) then
  begin
    if Value <> nil then
      H.RibbonWatch(Value);
    H.RibbonControlChanged(Self, Old);
  end;
  Changed(False);
end;

procedure TPPGRibbonItem.SetGalleryItems(const Value: TStrings);
begin
  FGalleryItems.Assign(Value);
end;

procedure TPPGRibbonItem.GalleryItemsChange(Sender: TObject);
begin
  Changed(False);
end;

procedure TPPGRibbonItem.SetGalleryCount(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'GalleryCount', Value, 0, MaxInt);
  if FGalleryCount <> V then
  begin
    FGalleryCount := V;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetGalleryIndex(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'GalleryIndex', Value, -1, MaxInt);
  if FGalleryIndex <> V then
  begin
    FGalleryIndex := V;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetGalleryColumns(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'GalleryColumns', Value, 1, 50);
  if FGalleryColumns <> V then
  begin
    FGalleryColumns := V;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetGalleryPopupColumns(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'GalleryPopupColumns', Value, 0, 50);
  if FGalleryPopupColumns <> V then
  begin
    FGalleryPopupColumns := V;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetGalleryItemWidth(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'GalleryItemWidth', Value, 16, 1000);
  if FGalleryItemWidth <> V then
  begin
    FGalleryItemWidth := V;
    Changed(False);
  end;
end;

procedure TPPGRibbonItem.SetGalleryItemHeight(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'GalleryItemHeight', Value, 0, 1000);
  if FGalleryItemHeight <> V then
  begin
    FGalleryItemHeight := V;
    Changed(False);
  end;
end;

function TPPGRibbonItem.GetAction: TBasicAction;
begin
  if FActionLink <> nil then
    Result := FActionLink.Action
  else
    Result := nil;
end;

procedure TPPGRibbonItem.SetAction(const Value: TBasicAction);
begin
  if Value = nil then
  begin
    FreeAndNil(FActionLink);
    Exit;
  end;
  if FActionLink = nil then
    FActionLink := TPPGRibbonItemActionLink.Create(Self);
  FActionLink.Action := Value;
  FActionLink.OnChange := DoActionChange;
  ActionChange(Value, csLoading in Value.ComponentState);
  WatchComponent(Self, Value);
end;

procedure TPPGRibbonItem.DoActionChange(Sender: TObject);
begin
  if Sender = Action then
    ActionChange(Sender, False);
end;

procedure TPPGRibbonItem.ActionChange(Sender: TObject; CheckDefaults: Boolean);
var
  A: TCustomAction;
begin
  if not (Sender is TCustomAction) then
    Exit;
  A := TCustomAction(Sender);
  if not CheckDefaults or (FCaption = '') then
    FCaption := A.Caption;
  if not CheckDefaults or (FHint = '') then
    FHint := A.Hint;
  if not CheckDefaults or FEnabled then
    FEnabled := A.Enabled;
  if not CheckDefaults or FVisible then
    FVisible := A.Visible;
  if not CheckDefaults or not FDown then
    FDown := A.Checked;
  if not CheckDefaults or (FImageIndex = -1) then
    FImageIndex := A.ImageIndex;
  if not CheckDefaults or not Assigned(FOnClick) then
    FOnClick := A.OnExecute;
  if (A.Checked or A.AutoCheck) and (FKind = rikButton) then
    FKind := rikCheck;
  if A.GroupIndex <> 0 then
    FGroupIndex := A.GroupIndex;
  Changed(False);
end;

function TPPGRibbonItem.IsCaptionStored: Boolean;
begin
  Result := (FActionLink = nil) or not FActionLink.IsCaptionLinked;
end;

function TPPGRibbonItem.IsHintStored: Boolean;
begin
  Result := (FActionLink = nil) or not FActionLink.IsHintLinked;
end;

function TPPGRibbonItem.IsEnabledStored: Boolean;
begin
  Result := (FActionLink = nil) or not FActionLink.IsEnabledLinked;
end;

function TPPGRibbonItem.IsVisibleStored: Boolean;
begin
  Result := (FActionLink = nil) or not FActionLink.IsVisibleLinked;
end;

function TPPGRibbonItem.IsDownStored: Boolean;
begin
  Result := (FActionLink = nil) or not FActionLink.IsCheckedLinked;
end;

function TPPGRibbonItem.IsImageIndexStored: Boolean;
begin
  Result := (FActionLink = nil) or not FActionLink.IsImageIndexLinked;
end;

function TPPGRibbonItem.IsOnClickStored: Boolean;
begin
  Result := (FActionLink = nil) or not FActionLink.IsOnExecuteLinked;
end;

{ TPPGRibbonItems }

constructor TPPGRibbonItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TPPGRibbonItem);
end;

function TPPGRibbonItems.GetItem(Index: Integer): TPPGRibbonItem;
begin
  Result := TPPGRibbonItem(inherited Items[Index]);
end;

function TPPGRibbonItems.Add: TPPGRibbonItem;
begin
  Result := TPPGRibbonItem(inherited Add);
end;

function TPPGRibbonItems.AddButton(const ACaption: string; AIconChar: Word; ASize: TPPGRibbonSize;
  AOnClick: TNotifyEvent): TPPGRibbonItem;
begin
  BeginUpdate;
  try
    Result := Add;
    Result.FCaption := ACaption;
    Result.FIconChar := AIconChar;
    Result.FSize := ASize;
    Result.FOnClick := AOnClick;
  finally
    EndUpdate;
  end;
end;

function TPPGRibbonItems.AddCheck(const ACaption: string; AIconChar: Word; ASize: TPPGRibbonSize;
  AGroupIndex: Integer): TPPGRibbonItem;
begin
  BeginUpdate;
  try
    Result := Add;
    Result.FCaption := ACaption;
    Result.FIconChar := AIconChar;
    Result.FKind := rikCheck;
    Result.FSize := ASize;
    Result.FGroupIndex := AGroupIndex;
  finally
    EndUpdate;
  end;
end;

function TPPGRibbonItems.AddSeparator: TPPGRibbonItem;
begin
  BeginUpdate;
  try
    Result := Add;
    Result.FKind := rikSeparator;
  finally
    EndUpdate;
  end;
end;

procedure TPPGRibbonItems.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  NotifyHost(Self);
end;

{ TPPGRibbonGroup }

constructor TPPGRibbonGroup.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FItems := TPPGRibbonItems.Create(Self);
  FVisible := True;
  FImageIndex := -1;
end;

destructor TPPGRibbonGroup.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TPPGRibbonGroup.Assign(Source: TPersistent);
var
  S: TPPGRibbonGroup;
begin
  if Source is TPPGRibbonGroup then
  begin
    S := TPPGRibbonGroup(Source);
    FCaption := S.FCaption;
    FReduceOrder := S.FReduceOrder;
    FVisible := S.FVisible;
    FKeyTip := S.FKeyTip;
    FImageIndex := S.FImageIndex;
    FIconChar := S.FIconChar;
    FShowLauncher := S.FShowLauncher;
    FLauncherHint := S.FLauncherHint;
    FTag := S.FTag;
    FItems.Assign(S.FItems);
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGRibbonGroup.GetDisplayName: string;
begin
  if FCaption <> '' then
    Result := FCaption
  else
    Result := inherited GetDisplayName;
end;

function TPPGRibbonGroup.Tab: TPPGRibbonTab;
begin
  if (Collection <> nil) and (Collection.Owner is TPPGRibbonTab) then
    Result := TPPGRibbonTab(Collection.Owner)
  else
    Result := nil;
end;

procedure TPPGRibbonGroup.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonGroup.SetItems(const Value: TPPGRibbonItems);
begin
  FItems.Assign(Value);
end;

procedure TPPGRibbonGroup.SetReduceOrder(const Value: Integer);
begin
  if FReduceOrder <> Value then
  begin
    FReduceOrder := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonGroup.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonGroup.SetKeyTip(const Value: string);
begin
  if FKeyTip <> Value then
  begin
    FKeyTip := AnsiUpperCase(Trim(Value));
    Changed(False);
  end;
end;

procedure TPPGRibbonGroup.SetImageIndex(const Value: TPPGImageIndex);
begin
  if FImageIndex <> Value then
  begin
    FImageIndex := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonGroup.SetIconChar(const Value: Word);
begin
  if FIconChar <> Value then
  begin
    FIconChar := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonGroup.SetShowLauncher(const Value: Boolean);
begin
  if FShowLauncher <> Value then
  begin
    FShowLauncher := Value;
    Changed(False);
  end;
end;

{ TPPGRibbonGroups }

constructor TPPGRibbonGroups.Create(AOwner: TPPGRibbonTab);
begin
  inherited Create(AOwner, TPPGRibbonGroup);
end;

function TPPGRibbonGroups.GetItem(Index: Integer): TPPGRibbonGroup;
begin
  Result := TPPGRibbonGroup(inherited Items[Index]);
end;

function TPPGRibbonGroups.Add: TPPGRibbonGroup;
begin
  Result := TPPGRibbonGroup(inherited Add);
end;

function TPPGRibbonGroups.AddGroup(const ACaption: string): TPPGRibbonGroup;
begin
  Result := Add;
  Result.Caption := ACaption;
end;

procedure TPPGRibbonGroups.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  NotifyHost(Self);
end;

{ TPPGRibbonTab }

constructor TPPGRibbonTab.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FGroups := TPPGRibbonGroups.Create(Self);
  FVisible := True;
  FContextColor := clDefault;
end;

destructor TPPGRibbonTab.Destroy;
begin
  FreeAndNil(FGroups);
  inherited Destroy;
end;

procedure TPPGRibbonTab.Assign(Source: TPersistent);
var
  S: TPPGRibbonTab;
begin
  if Source is TPPGRibbonTab then
  begin
    S := TPPGRibbonTab(Source);
    FCaption := S.FCaption;
    FVisible := S.FVisible;
    FKeyTip := S.FKeyTip;
    FContextName := S.FContextName;
    FContextColor := S.FContextColor;
    FTag := S.FTag;
    FGroups.Assign(S.FGroups);
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGRibbonTab.GetDisplayName: string;
begin
  if FCaption <> '' then
    Result := FCaption
  else
    Result := inherited GetDisplayName;
end;

function TPPGRibbonTab.IsContextual: Boolean;
begin
  Result := FContextName <> '';
end;

procedure TPPGRibbonTab.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonTab.SetGroups(const Value: TPPGRibbonGroups);
begin
  FGroups.Assign(Value);
end;

procedure TPPGRibbonTab.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonTab.SetKeyTip(const Value: string);
begin
  if FKeyTip <> Value then
  begin
    FKeyTip := AnsiUpperCase(Trim(Value));
    Changed(False);
  end;
end;

procedure TPPGRibbonTab.SetContextName(const Value: string);
begin
  if FContextName <> Value then
  begin
    FContextName := Value;
    Changed(False);
  end;
end;

procedure TPPGRibbonTab.SetContextColor(const Value: TColor);
begin
  if FContextColor <> Value then
  begin
    FContextColor := Value;
    Changed(False);
  end;
end;

{ TPPGRibbonTabs }

constructor TPPGRibbonTabs.Create(AOwner: TComponent);
begin
  inherited Create(AOwner, TPPGRibbonTab);
end;

function TPPGRibbonTabs.GetItem(Index: Integer): TPPGRibbonTab;
begin
  Result := TPPGRibbonTab(inherited Items[Index]);
end;

function TPPGRibbonTabs.Add: TPPGRibbonTab;
begin
  Result := TPPGRibbonTab(inherited Add);
end;

function TPPGRibbonTabs.AddTab(const ACaption: string): TPPGRibbonTab;
begin
  Result := Add;
  Result.Caption := ACaption;
end;

procedure TPPGRibbonTabs.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  NotifyHost(Self);
end;

end.
