unit PPG.Ribbon;

{ TPPGRibbon - Menueband im Stil von Office (Phase 14b).

  Aufbau (von oben): Schnellzugriffsleiste (wahlweise ueber oder unter dem
  Band), Registerkartenzeile mit "Datei"-Button und Einklapp-Knopf, Band mit
  den Gruppen der aktiven Registerkarte. Das Ribbon liegt unter der normalen
  Titelleiste (kein Zeichnen im Nicht-Client-Bereich).

  - Modell: PPG.Ribbon.Items (Tabs -> Groups -> Items, Actions als Quelle).
  - Layout: PPG.Ribbon.Layout (reine Funktionen). Reicht die Breite nicht,
    schrumpfen die Gruppen in fester Reihenfolge: gross -> klein -> nur
    Symbol -> Gruppe als Dropdown. Die Geometrie einer Registerkarte haelt
    ein TPPGRibbonView; dieselbe Klasse dient dem Band, dem Popup des
    eingeklappten Bands und dem Popup einer geschrumpften Gruppe.
  - Eingebettete Controls (Item.Control) sind Kinder des Ribbons bzw. des
    offenen Popups. Ihre Lage wird nie im Paint gesetzt, sondern per
    geposteter Nachricht (UpdateLayout erzwingt es sofort).
  - KeyTips: Alt (bzw. F10) zeigt Plaketten ueber Registerkarten, "Datei"
    und Schnellzugriff, ein Buchstabe waehlt die Karte und zeigt die
    Plaketten ihrer Befehle; Esc geht eine Ebene zurueck. Die Plaketten
    zeichnet ein eigenes Overlay-Fenster je Monitor (auch ueber Popups).
    Tasten kommen ueber PPG.AppHooks, der Fokus bleibt im Formular.
  - Tastatur ohne Maus: nach Alt wechseln die Pfeiltasten in die
    Tastaturbedienung (Fokusrahmen, Enter/Leertaste loest aus).
  - Einklappen: Doppelklick auf eine Registerkarte, Strg+F1 oder der Knopf
    rechts; eingeklappt oeffnet ein Klick die Karte als Popup.
  - Schnellzugriff anpassbar ueber das Kontextmenue (hinzufuegen, entfernen,
    ueber/unter dem Band); Kontext-Registerkarten farbig hervorgehoben.
  - "Datei" zeigt den Backstage-Bereich (ein beliebiges Control, z.B. ein
    PageControl, ueber dem ganzen Formular) oder ein Anwendungsmenue.
  - Code setzt Werte ohne Ereignisse; Anwenderaktionen loesen sie aus.
  - Screenreader: Gruppierung "Menueband" mit Datei, Schnellzugriff,
    Registerkarten und den Befehlen der aktiven Karte als Kindern. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.Generics.Collections,
  {$IFDEF PPG_HAS_SYSTEM_ACTIONS}System.Actions,{$ENDIF} Vcl.ActnList, Vcl.Controls, Vcl.Graphics,
  Vcl.Menus, Vcl.ImgList, Vcl.Forms,
  PPG.Types, PPG.Items, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Base, PPG.Popup,
  PPG.ItemPainter, PPG.Ribbon.Layout, PPG.Ribbon.Items;

type
  TPPGCustomRibbon = class;

  TPPGRibbonPart = (rpNone, rpAppButton, rpQuickItem, rpQuickCustomize, rpTab, rpMinimize,
    rpItem, rpItemArrow, rpGroup, rpLauncher, rpGalleryTile, rpGalleryUp, rpGalleryDown,
    rpGalleryMore);

  TPPGQuickAccessPosition = (qapAbove, qapBelow);

  TPPGRibbonItemArray = array of TPPGRibbonItem;
  TPPGRibbonCells = array of TPPGRibbonCell;

  /// Lage einer Gruppe in einer Ansicht.
  TPPGRibbonGroupPlace = record
    Group: TPPGRibbonGroup;
    State: TPPGRibbonGroupState;
    Bounds: TRect;
    CaptionRect: TRect;
    LauncherRect: TRect;
    Items: TPPGRibbonItemArray;       // sichtbare Items in Layout-Reihenfolge
    Places: TPPGRibbonPlaces;         // gleiche Indizes wie Items
  end;

  /// Geometrie der Gruppen einer Registerkarte in einem Fenster (Band oder Popup).
  TPPGRibbonView = class
  public
    Tab: TPPGRibbonTab;
    /// Nur diese Gruppe, voll aufgeklappt (Popup einer geschrumpften Gruppe).
    SingleGroup: TPPGRibbonGroup;
    Host: TWinControl;
    Bounds: TRect;
    Groups: array of TPPGRibbonGroupPlace;
    Valid: Boolean;
    function GroupCount: Integer;
  end;

  /// Treffer: Teil des Ribbons bzw. einer Ansicht.
  TPPGRibbonHit = record
    Part: TPPGRibbonPart;
    View: TPPGRibbonView;   // nil = Kopfbereich des Ribbons
    Index: Integer;         // Registerkarte, Schnellzugriff-Item oder Gruppe der Ansicht
    Item: Integer;          // Item in der Gruppe (Layout-Reihenfolge)
    Tile: Integer;          // Galerie-Eintrag
  end;

  TPPGRibbonColors = record
    Back, Panel, Stroke, Text, TextSecondary, TextDisabled, Accent, OnAccent: TColor;
    HC: Boolean;
  end;

  TPPGRibbonItemEvent = procedure(Sender: TObject; Item: TPPGRibbonItem) of object;
  TPPGRibbonGroupEvent = procedure(Sender: TObject; Group: TPPGRibbonGroup) of object;
  TPPGRibbonGalleryEvent = procedure(Sender: TObject; Item: TPPGRibbonItem; Index: Integer) of object;
  TPPGRibbonGetGalleryItemEvent = procedure(Sender: TObject; Item: TPPGRibbonItem; Index: Integer;
    var Data: TPPGItemData; var Color: TColor) of object;
  TPPGRibbonDrawGalleryItemEvent = procedure(Sender: TObject; Item: TPPGRibbonItem; Index: Integer;
    Canvas: TCanvas; const Rect: TRect; Selected, Hot: Boolean; var Handled: Boolean) of object;
  TPPGRibbonTabChangingEvent = procedure(Sender: TObject; NewTab: TPPGRibbonTab;
    var AllowChange: Boolean) of object;

  /// Popup fuer das eingeklappte Band (ganze Registerkarte) oder eine
  /// geschrumpfte Gruppe. Zeichnen und Maus erledigt das Ribbon.
  TPPGRibbonPanelPopup = class(TPPGPopupWindow)
  private
    FRibbon: TPPGCustomRibbon;
    FView: TPPGRibbonView;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
  protected
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function PopupRounding: Integer; override;
  public
    constructor CreateFor(ARibbon: TPPGCustomRibbon);
    destructor Destroy; override;
    property View: TPPGRibbonView read FView;
  end;

  /// Aufgeklappte Galerie (virtuell: nur sichtbare Eintraege werden gezeichnet).
  TPPGRibbonGalleryPopup = class(TPPGPopupWindow)
  private
    FRibbon: TPPGCustomRibbon;
    FItem: TPPGRibbonItem;
    FCols: Integer;
    FTopRow: Integer;
    FHot: Integer;
    FFocus: Integer;
    FPressed: Integer;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function PopupRounding: Integer; override;
  public
    constructor CreateFor(ARibbon: TPPGCustomRibbon);
    function TileWidth: Integer;
    function TileHeight: Integer;
    function VisibleRows: Integer;
    function RowCount: Integer;
    function TileRect(Index: Integer): TRect;
    function TileAt(X, Y: Integer): Integer;
    procedure ScrollRows(Delta: Integer);
    procedure MakeVisible(Index: Integer);
    /// Tasten bei offener Galerie (True = verarbeitet).
    function HandleKey(Key: Word): Boolean;
    property Item: TPPGRibbonItem read FItem;
    property Columns: Integer read FCols;
    property TopRow: Integer read FTopRow;
    property FocusIndex: Integer read FFocus;
  end;

  /// Durchsichtiges Fenster mit den KeyTip-Plaketten (eines je Monitor).
  TPPGKeyTipOverlay = class(TCustomControl)
  private
    FTexts: array of string;
    FRects: array of TRect;
    FEnabled: array of Boolean;
    FBack, FText, FBorder: TColor;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    function TipCount: Integer;
  end;

  TPPGKeyTipTarget = record
    Hit: TPPGRibbonHit;
    Tip: string;
    Anchor: TPoint;       // Bildschirmkoordinaten, Mitte oben der Plakette
    Enabled: Boolean;
  end;

  TPPGRibbonElement = record
    Hit: TPPGRibbonHit;
    Rect: TRect;          // Client-Koordinaten des Ribbons
  end;

  TPPGCustomRibbon = class(TPPGCustomControl, IPPGRibbonHost, IPPGAccessibleChildren)
  private
    FTabs: TPPGRibbonTabs;
    FQuickAccess: TPPGRibbonItems;
    FTabIndex: Integer;
    FMinimized: Boolean;
    FQuickAccessPosition: TPPGQuickAccessPosition;
    FShowQuickAccess: Boolean;
    FQuickAccessCustomizable: Boolean;
    FShowApplicationButton: Boolean;
    FApplicationButtonCaption: string;
    FApplicationMenu: TPopupMenu;
    FBackstage: TControl;
    FLargeImages: TCustomImageList;
    FLargeImageLink: TChangeLink;
    FKeyTipsEnabled: Boolean;
    { Layout }
    FLayoutValid: Boolean;
    FLayoutWidth: Integer;
    FLayoutPPI: Integer;
    FLayoutLang: string;
    FControlLayoutPending: Boolean;
    FLayoutPosted: Boolean;
    FPlacingControls: Boolean;
    FMainView: TPPGRibbonView;
    FQatRect: TRect;
    FQatRects: array of TRect;
    FQatCustomizeRect: TRect;
    FTabRowRect: TRect;
    FAppRect: TRect;
    FMinimizeRect: TRect;
    FTabRects: array of TRect;
    FPanelRect: TRect;
    FTextCache: TDictionary<string, Integer>;
    FTextCachePPI: Integer;
    FPainter: TPPGItemPainter;
    { Bedienung }
    FHot: TPPGRibbonHit;
    FDown: TPPGRibbonHit;
    FPanelPopup: TPPGRibbonPanelPopup;
    FPopupTab: Integer;
    FGroupPopup: TPPGRibbonPanelPopup;
    FGalleryPopup: TPPGRibbonGalleryPopup;
    FHooked: Boolean;
    FAltDown: Boolean;
    FLeaveOnKeyUp: Boolean;
    FContextMenu: TPopupMenu;
    FContextHit: TPPGRibbonHit;
    FBusy: Integer;               // Menue/Ereignis laeuft: keine Haken-Aktionen
    { KeyTips und Tastatur }
    FKeyTipLevel: Integer;        // 0 = aus, 1 = Kopf, 2 = Registerkarte, 3 = Gruppe
    FKeyTipView: TPPGRibbonView;
    FKeyTips: array of TPPGKeyTipTarget;
    FKeyTyped: string;
    FOverlays: TObjectList<TPPGKeyTipOverlay>;
    FNavMode: Boolean;
    FNavIndex: Integer;
    { Backstage }
    FBackstageVisible: Boolean;
    FBackstageAlign: TAlign;
    FBackstageAnchors: TAnchors;
    FBackstageBounds: TRect;
    FBackstageWasVisible: Boolean;
    { Ereignisse }
    FOnItemClick: TPPGRibbonItemEvent;
    FOnTabChange: TNotifyEvent;
    FOnTabChanging: TPPGRibbonTabChangingEvent;
    FOnGalleryClick: TPPGRibbonGalleryEvent;
    FOnGetGalleryItem: TPPGRibbonGetGalleryItemEvent;
    FOnDrawGalleryItem: TPPGRibbonDrawGalleryItemEvent;
    FOnLauncherClick: TPPGRibbonGroupEvent;
    FOnMinimizedChange: TNotifyEvent;
    FOnQuickAccessChange: TNotifyEvent;
    FOnApplicationButtonClick: TNotifyEvent;
    FOnBackstageChange: TNotifyEvent;
    procedure SetTabs(const Value: TPPGRibbonTabs);
    procedure SetQuickAccess(const Value: TPPGRibbonItems);
    procedure SetTabIndex(const Value: Integer);
    procedure SetMinimized(const Value: Boolean);
    procedure SetQuickAccessPosition(const Value: TPPGQuickAccessPosition);
    procedure SetShowQuickAccess(const Value: Boolean);
    procedure SetShowApplicationButton(const Value: Boolean);
    procedure SetApplicationButtonCaption(const Value: string);
    procedure SetApplicationMenu(const Value: TPopupMenu);
    procedure SetBackstage(const Value: TControl);
    procedure SetLargeImages(const Value: TCustomImageList);
    procedure LargeImagesChange(Sender: TObject);
    function GetActiveTab: TPPGRibbonTab;
    { Masse }
    function TextWidth(const S: string): Integer;
    function TextHeight: Integer;
    function RowHeight: Integer;
    function ContentHeight: Integer;
    function CaptionHeight: Integer;
    function PanelHeight: Integer;
    function TabRowHeight: Integer;
    function QatHeight: Integer;
    function Sc(V: Integer): Integer;
    function Metrics(ContentTop: Integer): TPPGRibbonMetrics;
    function HasArrow(Item: TPPGRibbonItem): Boolean;
    procedure SplitCaption(const Caption: string; out Line1, Line2: string);
    function LargeWidth(Item: TPPGRibbonItem): Integer;
    function ItemWidth(Item: TPPGRibbonItem; Size: TPPGRibbonSize): Integer;
    function GalleryInlineColumns(Item: TPPGRibbonItem; Size: TPPGRibbonSize): Integer;
    function GroupCaptionWidth(Group: TPPGRibbonGroup): Integer;
    function CollapsedWidth(Group: TPPGRibbonGroup): Integer;
    function QuickVisibleCount: Integer;
    function QatVisible: Boolean;
    { Layout }
    procedure LayoutChanged;
    procedure LayoutQat(Y: Integer);
    procedure LayoutTabs;
    procedure MirrorRect(var R: TRect; HostWidth: Integer);
    procedure RequestControlLayout;
    procedure ApplyControlLayout;
    procedure PlaceViewControls(View: TPPGRibbonView; Shown: TList<TControl>);
    procedure HideControl(C: TControl);
    { Treffer }
    function HeadHitTest(X, Y: Integer): TPPGRibbonHit;
    function ViewHitTest(View: TPPGRibbonView; X, Y: Integer): TPPGRibbonHit;
    function SameHit(const A, B: TPPGRibbonHit): Boolean;
    function GalleryGeometry(Item: TPPGRibbonItem; const R: TRect; out Tiles, Strip: TRect;
      out Cols, Rows, TileW, TileH: Integer): Boolean;
    { Zeichnen }
    procedure PaintHead(const ACanvas: IPPGCanvas; const C: TPPGRibbonColors);
    procedure PaintFace(const ACanvas: IPPGCanvas; const R: TRect; Hot, Pressed, Checked,
      AEnabled: Boolean; const C: TPPGRibbonColors; out TextColor: TColor);
    procedure PaintIcon(const ACanvas: IPPGCanvas; Item: TPPGRibbonItem; const R: TRect;
      Large: Boolean; Color: TColor; AEnabled: Boolean);
    procedure PaintArrow(const ACanvas: IPPGCanvas; const R: TRect; Color: TColor);
    procedure PaintItem(const ACanvas: IPPGCanvas; View: TPPGRibbonView; G, I: Integer;
      const C: TPPGRibbonColors);
    procedure PaintGalleryTiles(const ACanvas: IPPGCanvas; Item: TPPGRibbonItem; const Tiles: TRect;
      Cols, TopRow, Rows, TileW, TileH, HotTile, FocusTile: Integer; const C: TPPGRibbonColors);
    procedure PaintGroup(const ACanvas: IPPGCanvas; View: TPPGRibbonView; G: Integer;
      const C: TPPGRibbonColors);
    procedure PaintKeyboardFocus(const ACanvas: IPPGCanvas; const C: TPPGRibbonColors);
    { Bedienung }
    procedure SetHot(const Hit: TPPGRibbonHit);
    procedure HitMouseDown(const Hit: TPPGRibbonHit; Shift: TShiftState);
    procedure HitMouseUp(const Hit: TPPGRibbonHit);
    procedure ActivateHit(const Hit: TPPGRibbonHit; ByKeyboard: Boolean);
    function HitScreenRect(const Hit: TPPGRibbonHit): TRect;
    function HitRect(const Hit: TPPGRibbonHit): TRect;
    function HitItem(const Hit: TPPGRibbonHit): TPPGRibbonItem;
    procedure UserSelectTab(Index: Integer);
    procedure UserToggleMinimized;
    procedure OpenTabPopup(Index: Integer);
    procedure OpenGroupPopup(View: TPPGRibbonView; G: Integer);
    procedure ReparentToPopup(Popup: TPPGRibbonPanelPopup);
    procedure ReturnControls(Popup: TPPGRibbonPanelPopup);
    procedure ClosePanelPopup;
    procedure CloseGroupPopup;
    procedure CloseGalleryPopup;
    procedure ShowItemMenu(Item: TPPGRibbonItem; const ScreenR: TRect);
    procedure ShowContextMenuAt(const Hit: TPPGRibbonHit; const ScreenPt: TPoint);
    procedure ContextAddClick(Sender: TObject);
    procedure ContextRemoveClick(Sender: TObject);
    procedure ContextPositionClick(Sender: TObject);
    procedure ContextMinimizeClick(Sender: TObject);
    function QuickIndexOf(Item: TPPGRibbonItem): Integer;
    function CanAddToQuickAccess(Item: TPPGRibbonItem): Boolean;
    procedure DesignerModified;
    { Haken }
    procedure UpdateHook;
    procedure Hook(var Msg: TMsg; var Handled: Boolean);
    procedure AppDeactivate(Sender: TObject);
    function BelongsToForm(Wnd: HWND): Boolean;
    function InPopup(Wnd: HWND): Boolean;
    { KeyTips }
    procedure BuildKeyTips;
    procedure ShowOverlays;
    procedure HideOverlays;
    procedure ExecuteKeyTip(Index: Integer);
    function KeyTipMatchCount(Ch: Char): Integer;
    { Tastaturbedienung }
    function Elements: TArray<TPPGRibbonElement>;
    procedure NavMove(Key: Word; Shift: TShiftState);
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMDesignHitTest(var Message: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure CMBiDiModeChanged(var Message: TMessage); message CM_BIDIMODECHANGED;
  protected
    procedure WndProc(var Message: TMessage); override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); override;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    function CalcAutoSize(out AWidth, AHeight: Integer): Boolean; override;
    function AutoSizeWidth: Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    { IPPGRibbonHost }
    procedure RibbonModelChanged;
    procedure RibbonWatch(AComponent: TComponent);
    procedure RibbonControlChanged(Item: TPPGRibbonItem; OldControl: TControl);
    { Barrierefreiheit }
    function AccName: string; override;
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
    /// Farben fuer Band, Popups und Overlay.
    function RibbonColors: TPPGRibbonColors;
    { Ansichten (auch fuer die Popups) }
    procedure BuildView(View: TPPGRibbonView; ATab: TPPGRibbonTab; ASingle: TPPGRibbonGroup;
      const ABounds: TRect; AHost: TWinControl);
    procedure EnsureView(View: TPPGRibbonView);
    procedure PaintView(const ACanvas: IPPGCanvas; View: TPPGRibbonView; const C: TPPGRibbonColors);
    procedure ViewMouseDown(View: TPPGRibbonView; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ViewMouseMove(View: TPPGRibbonView; X, Y: Integer);
    procedure ViewMouseUp(View: TPPGRibbonView; Button: TMouseButton; X, Y: Integer);
    function HintFor(const Hit: TPPGRibbonHit; out R: TRect): string;
    procedure GetGalleryData(Item: TPPGRibbonItem; Index: Integer; var Data: TPPGItemData;
      var Color: TColor);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure InitiateAction; override;
    /// Layout und Lage der eingebetteten Controls sofort berechnen.
    procedure UpdateLayout;
    procedure EnsureLayout;
    /// Item ausloesen wie per Klick (Umschalten, OnClick/Action, OnItemClick).
    procedure ClickItem(Item: TPPGRibbonItem);
    /// Schnellzugriff-Item ausloesen (wirkt auf das Item im Band, wenn es eines gibt).
    procedure ClickQuickItem(Index: Integer);
    /// Galerie-Eintrag waehlen wie per Klick (GalleryIndex, OnGalleryClick).
    procedure SelectGalleryItem(Item: TPPGRibbonItem; Index: Integer);
    /// "Datei" wie per Klick: OnApplicationButtonClick, dann Backstage bzw. Menue.
    procedure ClickApplicationButton;
    procedure ShowBackstage;
    procedure HideBackstage;
    /// Galerie aufklappen (Popup) bzw. schliessen.
    procedure OpenGallery(Item: TPPGRibbonItem);
    procedure ClosePopups;
    { Schnellzugriff }
    function AddToQuickAccess(Item: TPPGRibbonItem): TPPGRibbonItem;
    procedure RemoveFromQuickAccess(Index: Integer);
    /// Item im Band, auf das ein Schnellzugriff-Item wirkt (gleiche Action bzw.
    /// gleiche Beschriftung, Art und Symbol), sonst nil.
    function QuickSource(QuickItem: TPPGRibbonItem): TPPGRibbonItem;
    { KeyTips und Tastatur }
    procedure ShowKeyTips;
    procedure HideKeyTips;
    /// Tasten im KeyTip-Modus (auch fuer Tests). True = verarbeitet.
    function HandleKeyTipKey(Key: Word): Boolean;
    function HandleKeyTipChar(Ch: Char): Boolean;
    function KeyTipCount: Integer;
    function KeyTipText(Index: Integer): string;
    function KeyTipHit(Index: Integer): TPPGRibbonHit;
    function KeyTipOverlayCount: Integer;
    procedure EnterKeyboardNavigation;
    procedure LeaveKeyboardNavigation;
    /// Tasten der Tastaturbedienung (auch fuer Tests). True = verarbeitet.
    function HandleNavKey(Key: Word; Shift: TShiftState): Boolean;
    { Geometrie (Client-Koordinaten) }
    function TabRect(Index: Integer): TRect;
    function ApplicationButtonRect: TRect;
    function MinimizeButtonRect: TRect;
    function QuickItemRect(Index: Integer): TRect;
    function QuickCustomizeRect: TRect;
    function PanelRect: TRect;
    function GroupCount: Integer;
    function GroupRect(Index: Integer): TRect;
    function GroupState(Index: Integer): TPPGRibbonGroupState;
    function GroupPlaceOf(Group: TPPGRibbonGroup): Integer;
    /// Rechteck eines Items im Band (leer = nicht sichtbar, z.B. Gruppe geschrumpft).
    function ItemRect(Item: TPPGRibbonItem): TRect;
    function ItemSize(Item: TPPGRibbonItem): TPPGRibbonSize;
    function HitTest(X, Y: Integer): TPPGRibbonHit;
    /// Baut das Kontextmenue fuer einen Treffer (Schnellzugriff, Position,
    /// Einklappen), ohne es zu zeigen.
    function PrepareContextMenu(const Hit: TPPGRibbonHit): TPopupMenu;
    function ElementCount: Integer;
    property ActiveTab: TPPGRibbonTab read GetActiveTab;
    property MainView: TPPGRibbonView read FMainView;
    property PanelPopup: TPPGRibbonPanelPopup read FPanelPopup;
    property GroupPopup: TPPGRibbonPanelPopup read FGroupPopup;
    property GalleryPopup: TPPGRibbonGalleryPopup read FGalleryPopup;
    property KeyTipLevel: Integer read FKeyTipLevel;
    property KeyboardNavigation: Boolean read FNavMode;
    property NavIndex: Integer read FNavIndex;
    property BackstageVisible: Boolean read FBackstageVisible;
    property HotHit: TPPGRibbonHit read FHot;
    property ContextMenu: TPopupMenu read FContextMenu;

    property Tabs: TPPGRibbonTabs read FTabs write SetTabs;
    property TabIndex: Integer read FTabIndex write SetTabIndex default 0;
    property Minimized: Boolean read FMinimized write SetMinimized default False;
    property QuickAccess: TPPGRibbonItems read FQuickAccess write SetQuickAccess;
    property QuickAccessPosition: TPPGQuickAccessPosition read FQuickAccessPosition
      write SetQuickAccessPosition default qapAbove;
    property ShowQuickAccess: Boolean read FShowQuickAccess write SetShowQuickAccess default True;
    property QuickAccessCustomizable: Boolean read FQuickAccessCustomizable
      write FQuickAccessCustomizable default True;
    property ShowApplicationButton: Boolean read FShowApplicationButton
      write SetShowApplicationButton default True;
    /// Beschriftung des Datei-Buttons ('' = "Datei" in der aktuellen Sprache).
    property ApplicationButtonCaption: string read FApplicationButtonCaption
      write SetApplicationButtonCaption;
    property ApplicationMenu: TPopupMenu read FApplicationMenu write SetApplicationMenu;
    /// Backstage-Bereich: wird beim Klick auf "Datei" ueber das ganze Formular gelegt.
    property Backstage: TControl read FBackstage write SetBackstage;
    property LargeImages: TCustomImageList read FLargeImages write SetLargeImages;
    property KeyTipsEnabled: Boolean read FKeyTipsEnabled write FKeyTipsEnabled default True;
    property OnItemClick: TPPGRibbonItemEvent read FOnItemClick write FOnItemClick;
    property OnTabChange: TNotifyEvent read FOnTabChange write FOnTabChange;
    property OnTabChanging: TPPGRibbonTabChangingEvent read FOnTabChanging write FOnTabChanging;
    property OnGalleryClick: TPPGRibbonGalleryEvent read FOnGalleryClick write FOnGalleryClick;
    property OnGetGalleryItem: TPPGRibbonGetGalleryItemEvent read FOnGetGalleryItem write FOnGetGalleryItem;
    property OnDrawGalleryItem: TPPGRibbonDrawGalleryItemEvent read FOnDrawGalleryItem
      write FOnDrawGalleryItem;
    property OnLauncherClick: TPPGRibbonGroupEvent read FOnLauncherClick write FOnLauncherClick;
    property OnMinimizedChange: TNotifyEvent read FOnMinimizedChange write FOnMinimizedChange;
    property OnQuickAccessChange: TNotifyEvent read FOnQuickAccessChange write FOnQuickAccessChange;
    property OnApplicationButtonClick: TNotifyEvent read FOnApplicationButtonClick
      write FOnApplicationButtonClick;
    property OnBackstageChange: TNotifyEvent read FOnBackstageChange write FOnBackstageChange;
  end;

  TPPGRibbon = class(TPPGCustomRibbon)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighContrastSupport;
    property Images;
    property LargeImages;
    property Tabs;
    property TabIndex;
    property QuickAccess;
    property QuickAccessPosition;
    property ShowQuickAccess;
    property QuickAccessCustomizable;
    property ShowApplicationButton;
    property ApplicationButtonCaption;
    property ApplicationMenu;
    property Backstage;
    property Minimized;
    property KeyTipsEnabled;
    property Align default alTop;
    property Anchors;
    property AutoSize default True;
    property BiDiMode;
    property Constraints;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint default True;
    property Visible;
    property OnItemClick;
    property OnTabChange;
    property OnTabChanging;
    property OnGalleryClick;
    property OnGetGalleryItem;
    property OnDrawGalleryItem;
    property OnLauncherClick;
    property OnMinimizedChange;
    property OnQuickAccessChange;
    property OnApplicationButtonClick;
    property OnBackstageChange;
  end;

implementation

uses
  PPG.Lang,
  System.Math, Winapi.oleacc,
  PPG.Consts, PPG.Appearance, PPG.DpiUtils, PPG.Tokens, PPG.IconFont, PPG.Render.Gdi,
  Vcl.StdCtrls, PPG.Exceptions, PPG.Menus, PPG.AppHooks, PPG.KeyTips, PPG.Popup.Placement;

const
  PadX = 6;          // logische px links/rechts im Button
  IconSmall = 16;
  IconLarge = 32;
  ArrowW = 10;       // Platz fuer den Aufklapp-Pfeil
  SplitArrowW = 14;  // Pfeilteil eines Split-Buttons (mittel/klein)
  GroupGap = 1;      // zwischen Gruppen (Trennlinie)
  PanelPad = 4;      // Innenabstand des Bands
  GalleryStrip = 16; // Leiste mit Blaettern/Aufklappen rechts in der Galerie
  KeyTipKey = $00FE00FE; // Farbschluessel des Overlays (durchsichtig)

var
  GMsgLayout: Cardinal = 0;
  GMsgAccAction: Cardinal = 0;

function NoHit: TPPGRibbonHit;
begin
  Result.Part := rpNone;
  Result.View := nil;
  Result.Index := -1;
  Result.Item := -1;
  Result.Tile := -1;
end;

function MakeHit(APart: TPPGRibbonPart; AView: TPPGRibbonView; AIndex, AItem, ATile: Integer): TPPGRibbonHit;
begin
  Result.Part := APart;
  Result.View := AView;
  Result.Index := AIndex;
  Result.Item := AItem;
  Result.Tile := ATile;
end;

function SameMethod(const A, B: TNotifyEvent): Boolean;
begin
  Result := (TMethod(A).Code = TMethod(B).Code) and (TMethod(A).Data = TMethod(B).Data);
end;

function PointsRect(const A, B: TPoint): TRect;
begin
  Result.TopLeft := A;
  Result.BottomRight := B;
end;

function RectW(const R: TRect): Integer;
begin
  Result := R.Right - R.Left;
end;

function RectH(const R: TRect): Integer;
begin
  Result := R.Bottom - R.Top;
end;

{ TPPGRibbonView }

function TPPGRibbonView.GroupCount: Integer;
begin
  Result := Length(Groups);
end;

{ TPPGRibbonPanelPopup }

constructor TPPGRibbonPanelPopup.CreateFor(ARibbon: TPPGCustomRibbon);
begin
  inherited Create(nil);
  FRibbon := ARibbon;
  FView := TPPGRibbonView.Create;
  ControlStyle := ControlStyle + [csAcceptsControls];
  ShowHint := True;
end;

destructor TPPGRibbonPanelPopup.Destroy;
begin
  FreeAndNil(FView);
  inherited Destroy;
end;

function TPPGRibbonPanelPopup.PopupRounding: Integer;
begin
  Result := PPGScale(6, ScalePPI);
end;

procedure TPPGRibbonPanelPopup.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  C: TPPGRibbonColors;
begin
  if FRibbon = nil then
    Exit;
  C := FRibbon.RibbonColors;
  ACanvas.FillRoundRect(ClientR, 0, C.Panel, 255);
  FRibbon.EnsureView(FView);
  FRibbon.PaintView(ACanvas, FView, C);
  ACanvas.FrameRoundRect(ClientR, PopupRounding, 1, PPGBlendColor(C.Panel, C.Text, 0.25), 255);
end;

procedure TPPGRibbonPanelPopup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if FRibbon <> nil then
    FRibbon.ViewMouseDown(FView, Button, Shift, X, Y);
end;

procedure TPPGRibbonPanelPopup.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if FRibbon <> nil then
    FRibbon.ViewMouseMove(FView, X, Y);
end;

procedure TPPGRibbonPanelPopup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if FRibbon <> nil then
    FRibbon.ViewMouseUp(FView, Button, X, Y);
end;

procedure TPPGRibbonPanelPopup.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if (FRibbon <> nil) and (FRibbon.FHot.View = FView) then
    FRibbon.SetHot(NoHit);
end;

procedure TPPGRibbonPanelPopup.CMHintShow(var Message: TCMHintShow);
var
  S: string;
  R: TRect;
begin
  inherited;
  if (FRibbon = nil) or (FRibbon.FHot.View <> FView) then
  begin
    Message.Result := 1;
    Exit;
  end;
  S := FRibbon.HintFor(FRibbon.FHot, R);
  if S = '' then
    Message.Result := 1
  else
  begin
    Message.HintInfo^.HintStr := S;
    Message.HintInfo^.CursorRect := R;
  end;
end;

{ TPPGRibbonGalleryPopup }

constructor TPPGRibbonGalleryPopup.CreateFor(ARibbon: TPPGCustomRibbon);
begin
  inherited Create(nil);
  FRibbon := ARibbon;
  FHot := -1;
  FFocus := -1;
  FPressed := -1;
end;

function TPPGRibbonGalleryPopup.PopupRounding: Integer;
begin
  Result := PPGScale(6, ScalePPI);
end;

function TPPGRibbonGalleryPopup.TileWidth: Integer;
begin
  if FItem = nil then
    Result := PPGScale(72, ScalePPI)
  else
    Result := PPGScale(FItem.GalleryItemWidth, ScalePPI);
end;

function TPPGRibbonGalleryPopup.TileHeight: Integer;
begin
  if (FItem = nil) or (FItem.GalleryItemHeight = 0) then
    Result := FRibbon.ContentHeight - PPGScale(4, ScalePPI)
  else
    Result := PPGScale(FItem.GalleryItemHeight, ScalePPI);
end;

function TPPGRibbonGalleryPopup.RowCount: Integer;
begin
  if (FItem = nil) or (FCols < 1) then
    Result := 0
  else
    Result := (FItem.GalleryTotal + FCols - 1) div FCols;
end;

function TPPGRibbonGalleryPopup.VisibleRows: Integer;
var
  P: Integer;
begin
  P := PPGScale(4, ScalePPI);
  Result := Max(1, (FullHeight - 2 * P) div Max(1, TileHeight));
end;

function TPPGRibbonGalleryPopup.TileRect(Index: Integer): TRect;
var
  P, Row, Col: Integer;
begin
  Result := Rect(0, 0, 0, 0);
  if (FCols < 1) or (Index < 0) then
    Exit;
  P := PPGScale(4, ScalePPI);
  Row := Index div FCols - FTopRow;
  Col := Index mod FCols;
  if (Row < 0) or (Row >= VisibleRows) then
    Exit;
  Result := Rect(P + Col * TileWidth, P + Row * TileHeight, P + (Col + 1) * TileWidth,
    P + (Row + 1) * TileHeight);
  OffsetRect(Result, 0, ContentOffset);
  if UseRightToLeftAlignment then
    Result := Rect(Width - Result.Right, Result.Top, Width - Result.Left, Result.Bottom);
end;

function TPPGRibbonGalleryPopup.TileAt(X, Y: Integer): Integer;
var
  I, First, Last: Integer;
begin
  Result := -1;
  if FItem = nil then
    Exit;
  First := FTopRow * FCols;
  Last := Min(FItem.GalleryTotal, (FTopRow + VisibleRows) * FCols) - 1;
  for I := First to Last do
    if PtInRect(TileRect(I), Point(X, Y)) then
      Exit(I);
end;

procedure TPPGRibbonGalleryPopup.ScrollRows(Delta: Integer);
var
  N: Integer;
begin
  N := Max(0, Min(FTopRow + Delta, RowCount - VisibleRows));
  if N <> FTopRow then
  begin
    FTopRow := N;
    FHot := -1;
    Invalidate;
  end;
end;

procedure TPPGRibbonGalleryPopup.MakeVisible(Index: Integer);
var
  Row: Integer;
begin
  if (FCols < 1) or (Index < 0) then
    Exit;
  Row := Index div FCols;
  if Row < FTopRow then
    ScrollRows(Row - FTopRow)
  else if Row >= FTopRow + VisibleRows then
    ScrollRows(Row - (FTopRow + VisibleRows) + 1);
end;

function TPPGRibbonGalleryPopup.HandleKey(Key: Word): Boolean;
var
  N, F: Integer;
begin
  Result := True;
  if FItem = nil then
    Exit(False);
  N := FItem.GalleryTotal;
  F := FFocus;
  if F < 0 then
    F := Max(0, FItem.GalleryIndex);
  if UseRightToLeftAlignment then
    if Key = VK_LEFT then
      Key := VK_RIGHT
    else if Key = VK_RIGHT then
      Key := VK_LEFT;
  case Key of
    VK_LEFT: Dec(F);
    VK_RIGHT: Inc(F);
    VK_UP: Dec(F, FCols);
    VK_DOWN: Inc(F, FCols);
    VK_PRIOR: Dec(F, FCols * VisibleRows);
    VK_NEXT: Inc(F, FCols * VisibleRows);
    VK_HOME: F := 0;
    VK_END: F := N - 1;
    VK_RETURN, VK_SPACE:
      begin
        if (FFocus >= 0) and (FFocus < N) then
          FRibbon.SelectGalleryItem(FItem, FFocus)
        else
          FRibbon.CloseGalleryPopup;
        Exit;
      end;
    VK_ESCAPE:
      begin
        FRibbon.CloseGalleryPopup;
        Exit;
      end;
  else
    Exit(False);
  end;
  F := Max(0, Min(F, N - 1));
  if F <> FFocus then
  begin
    FFocus := F;
    MakeVisible(F);
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_FOCUS);
  end;
end;

procedure TPPGRibbonGalleryPopup.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  C: TPPGRibbonColors;
  P, Total, TrackH, ThumbH, ThumbY: Integer;
  Tiles, Track: TRect;
begin
  if (FRibbon = nil) or (FItem = nil) then
    Exit;
  C := FRibbon.RibbonColors;
  ACanvas.FillRoundRect(ClientR, 0, C.Panel, 255);
  P := PPGScale(4, ScalePPI);
  Tiles := Rect(P, P + ContentOffset, P + FCols * TileWidth, P + ContentOffset + VisibleRows * TileHeight);
  if UseRightToLeftAlignment then
    Tiles := Rect(Width - Tiles.Right, Tiles.Top, Width - Tiles.Left, Tiles.Bottom);
  FRibbon.PaintGalleryTiles(ACanvas, FItem, Tiles, FCols, FTopRow, VisibleRows, TileWidth, TileHeight,
    FHot, FFocus, C);
  // schmale Bildlaufanzeige, wenn nicht alles passt
  Total := RowCount;
  if Total > VisibleRows then
  begin
    Track := Rect(Width - P - PPGScale(4, ScalePPI), Tiles.Top, Width - P, Tiles.Bottom);
    if UseRightToLeftAlignment then
      Track := Rect(Width - Track.Right, Track.Top, Width - Track.Left, Track.Bottom);
    TrackH := RectH(Track);
    ThumbH := Max(PPGScale(16, ScalePPI), TrackH * VisibleRows div Total);
    ThumbY := Track.Top + (TrackH - ThumbH) * FTopRow div Max(1, Total - VisibleRows);
    ACanvas.FillRoundRect(Rect(Track.Left, ThumbY, Track.Right, ThumbY + ThumbH), PPGScale(2, ScalePPI),
      C.TextSecondary, 160);
  end;
  ACanvas.FrameRoundRect(ClientR, PopupRounding, 1, PPGBlendColor(C.Panel, C.Text, 0.25), 255);
end;

procedure TPPGRibbonGalleryPopup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P, Total: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button <> mbLeft then
    Exit;
  FPressed := TileAt(X, Y);
  if FPressed < 0 then
  begin
    // Klick in die Bildlaufleiste: seitenweise
    Total := RowCount;
    P := PPGScale(4, ScalePPI);
    if (Total > VisibleRows) and (X >= Width - P - PPGScale(8, ScalePPI)) then
      if Y < Height div 2 then
        ScrollRows(-VisibleRows)
      else
        ScrollRows(VisibleRows);
  end;
end;

procedure TPPGRibbonGalleryPopup.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  T: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  T := TileAt(X, Y);
  if T <> FHot then
  begin
    FHot := T;
    Invalidate;
  end;
end;

procedure TPPGRibbonGalleryPopup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  T, Pr: Integer;
begin
  inherited MouseUp(Button, Shift, X, Y);
  Pr := FPressed;
  FPressed := -1;
  if Button <> mbLeft then
    Exit;
  T := TileAt(X, Y);
  if (T >= 0) and (T = Pr) and (FRibbon <> nil) then
    FRibbon.SelectGalleryItem(FItem, T);
end;

procedure TPPGRibbonGalleryPopup.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHot <> -1 then
  begin
    FHot := -1;
    Invalidate;
  end;
end;

{ TPPGKeyTipOverlay }

constructor TPPGKeyTipOverlay.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csOpaque, csNoDesignVisible];
  Visible := False;
end;

procedure TPPGKeyTipOverlay.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP;
  // durchsichtig fuer die Maus, nie aktiv, ohne Taskleisten-Knopf
  Params.ExStyle := WS_EX_TOOLWINDOW or WS_EX_LAYERED or WS_EX_TRANSPARENT or WS_EX_NOACTIVATE;
  if (Owner is TWinControl) and TWinControl(Owner).HandleAllocated then
    Params.WndParent := GetAncestor(TWinControl(Owner).Handle, GA_ROOT)
  else
    Params.WndParent := Application.Handle;
end;

procedure TPPGKeyTipOverlay.CreateWnd;
begin
  inherited CreateWnd;
  // alles in der Schluesselfarbe ist durchsichtig
  SetLayeredWindowAttributes(Handle, KeyTipKey, 255, LWA_COLORKEY);
end;

procedure TPPGKeyTipOverlay.WMNCHitTest(var Message: TWMNCHitTest);
begin
  Message.Result := HTTRANSPARENT;
end;

procedure TPPGKeyTipOverlay.WMMouseActivate(var Message: TWMMouseActivate);
begin
  Message.Result := MA_NOACTIVATE;
end;

function TPPGKeyTipOverlay.TipCount: Integer;
begin
  Result := Length(FTexts);
end;

procedure TPPGKeyTipOverlay.Paint;
var
  I: Integer;
  R: TRect;
begin
  // Plaketten ohne Kantenglaettung: Mischpixel mit der Schluesselfarbe waeren Raender
  Canvas.Brush.Color := KeyTipKey;
  Canvas.FillRect(ClientRect);
  Canvas.Font := Font;
  for I := 0 to High(FTexts) do
  begin
    R := FRects[I];
    Canvas.Brush.Color := FBack;
    Canvas.Pen.Color := FBorder;
    Canvas.Rectangle(R);
    if FEnabled[I] then
      Canvas.Font.Color := FText
    else
      Canvas.Font.Color := PPGBlendColor(FBack, FText, 0.45);
    Canvas.Brush.Style := bsClear;
    Winapi.Windows.DrawText(Canvas.Handle, PChar(FTexts[I]), Length(FTexts[I]), R,
      DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
    Canvas.Brush.Style := bsSolid;
  end;
end;

{ TPPGCustomRibbon }

constructor TPPGCustomRibbon.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls, csDoubleClicks] - [csSetCaption, csClickEvents];
  FTabs := TPPGRibbonTabs.Create(Self);
  FQuickAccess := TPPGRibbonItems.Create(Self);
  FMainView := TPPGRibbonView.Create;
  FTextCache := TDictionary<string, Integer>.Create;
  FPainter := TPPGItemPainter.Create;
  FOverlays := TObjectList<TPPGKeyTipOverlay>.Create(True);
  FLargeImageLink := TChangeLink.Create;
  FLargeImageLink.OnChange := LargeImagesChange;
  FShowQuickAccess := True;
  FQuickAccessCustomizable := True;
  FShowApplicationButton := True;
  FKeyTipsEnabled := True;
  FPopupTab := -1;
  FNavIndex := -1;
  FHot := NoHit;
  FDown := NoHit;
  FContextHit := NoHit;
  TabStop := False;
  ShowHint := True;
  Align := alTop;
  Width := 600;
  Height := 140;
  AutoSize := True;
  if GMsgLayout = 0 then
    GMsgLayout := RegisterWindowMessage('PPGlow.RibbonLayout');
  if GMsgAccAction = 0 then
    GMsgAccAction := RegisterWindowMessage('PPGlow.RibbonAccAction');
end;

destructor TPPGCustomRibbon.Destroy;
begin
  if FHooked then
  begin
    PPGRemoveMessageHook(Hook);
    PPGRemoveDeactivateHook(AppDeactivate);
    FHooked := False;
  end;
  FKeyTipLevel := 0;
  FreeAndNil(FOverlays);
  // Popups zuerst: sie geben ihre Controls an das Ribbon zurueck
  if FPanelPopup <> nil then
    ReturnControls(FPanelPopup);
  if FGroupPopup <> nil then
    ReturnControls(FGroupPopup);
  FreeAndNil(FGalleryPopup);
  FreeAndNil(FGroupPopup);
  FreeAndNil(FPanelPopup);
  FreeAndNil(FContextMenu);
  FreeAndNil(FTabs);
  FreeAndNil(FQuickAccess);
  FreeAndNil(FMainView);
  FreeAndNil(FTextCache);
  FreeAndNil(FPainter);
  FreeAndNil(FLargeImageLink);
  inherited Destroy;
end;

procedure TPPGCustomRibbon.CreateWnd;
begin
  inherited CreateWnd;
  FLayoutPosted := False;
  UpdateHook;
  RequestControlLayout;
end;

procedure TPPGCustomRibbon.DestroyWnd;
begin
  HideKeyTips;
  ClosePopups;
  inherited DestroyWnd;
end;

procedure TPPGCustomRibbon.Loaded;
begin
  inherited Loaded;
  if (FTabIndex >= FTabs.Count) then
    FTabIndex := FTabs.Count - 1;
  LayoutChanged;
end;

procedure TPPGCustomRibbon.UpdateHook;
begin
  if FHooked or (csDesigning in ComponentState) then
    Exit;
  PPGAddMessageHook(Hook);
  PPGAddDeactivateHook(AppDeactivate);
  FHooked := True;
end;

procedure TPPGCustomRibbon.Notification(AComponent: TComponent; Operation: TOperation);

  procedure ClearIn(Items: TPPGRibbonItems);
  var
    I: Integer;
  begin
    for I := 0 to Items.Count - 1 do
    begin
      if Items[I].Action = AComponent then
        Items[I].Action := nil;
      if Items[I].DropDownMenu = AComponent then
        Items[I].DropDownMenu := nil;
      if Items[I].Control = AComponent then
        Items[I].Control := nil;
    end;
  end;

var
  T, G: Integer;
begin
  inherited Notification(AComponent, Operation);
  if Operation <> opRemove then
    Exit;
  if AComponent = FApplicationMenu then
    FApplicationMenu := nil;
  if AComponent = FBackstage then
  begin
    FBackstage := nil;
    FBackstageVisible := False;
  end;
  if AComponent = FLargeImages then
  begin
    FLargeImages := nil;
    LayoutChanged;
  end;
  if (FTabs = nil) or (FQuickAccess = nil) then
    Exit;
  for T := 0 to FTabs.Count - 1 do
    for G := 0 to FTabs[T].Groups.Count - 1 do
      ClearIn(FTabs[T].Groups[G].Items);
  ClearIn(FQuickAccess);
end;

procedure TPPGCustomRibbon.InitiateAction;

  procedure UpdateIn(Items: TPPGRibbonItems);
  var
    I: Integer;
  begin
    for I := 0 to Items.Count - 1 do
      if Items[I].ActionLink <> nil then
        Items[I].ActionLink.Update;
  end;

var
  T, G: Integer;
begin
  inherited InitiateAction;
  // Leerlauf: Actions aller Items aktualisieren (wie TControl.InitiateAction)
  for T := 0 to FTabs.Count - 1 do
    for G := 0 to FTabs[T].Groups.Count - 1 do
      UpdateIn(FTabs[T].Groups[G].Items);
  UpdateIn(FQuickAccess);
end;

{ ---- Properties ---- }

procedure TPPGCustomRibbon.SetTabs(const Value: TPPGRibbonTabs);
begin
  FTabs.Assign(Value);
end;

procedure TPPGCustomRibbon.SetQuickAccess(const Value: TPPGRibbonItems);
begin
  FQuickAccess.Assign(Value);
end;

function TPPGCustomRibbon.GetActiveTab: TPPGRibbonTab;
var
  I: Integer;
begin
  Result := nil;
  if (FTabIndex >= 0) and (FTabIndex < FTabs.Count) and FTabs[FTabIndex].Visible then
    Exit(FTabs[FTabIndex]);
  // Unsichtbare aktive Karte: die erste sichtbare
  for I := 0 to FTabs.Count - 1 do
    if FTabs[I].Visible then
      Exit(FTabs[I]);
end;

procedure TPPGCustomRibbon.SetTabIndex(const Value: Integer);
var
  V: Integer;
begin
  if csLoading in ComponentState then
  begin
    FTabIndex := Value;
    Exit;
  end;
  V := PPGCheckRange(Self, 'TabIndex', Value, -1, FTabs.Count - 1);
  if V = FTabIndex then
    Exit;
  FTabIndex := V;
  if FMinimized and (FPanelPopup <> nil) and FPanelPopup.IsOpen then
    ClosePanelPopup;
  LayoutChanged;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

procedure TPPGCustomRibbon.SetMinimized(const Value: Boolean);
begin
  if FMinimized = Value then
    Exit;
  FMinimized := Value;
  ClosePopups;
  LayoutChanged;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

procedure TPPGCustomRibbon.SetQuickAccessPosition(const Value: TPPGQuickAccessPosition);
begin
  if FQuickAccessPosition <> Value then
  begin
    FQuickAccessPosition := Value;
    LayoutChanged;
  end;
end;

procedure TPPGCustomRibbon.SetShowQuickAccess(const Value: Boolean);
begin
  if FShowQuickAccess <> Value then
  begin
    FShowQuickAccess := Value;
    LayoutChanged;
  end;
end;

procedure TPPGCustomRibbon.SetShowApplicationButton(const Value: Boolean);
begin
  if FShowApplicationButton <> Value then
  begin
    FShowApplicationButton := Value;
    LayoutChanged;
  end;
end;

procedure TPPGCustomRibbon.SetApplicationButtonCaption(const Value: string);
begin
  if FApplicationButtonCaption <> Value then
  begin
    FApplicationButtonCaption := Value;
    LayoutChanged;
  end;
end;

procedure TPPGCustomRibbon.SetApplicationMenu(const Value: TPopupMenu);
begin
  if FApplicationMenu <> Value then
  begin
    FApplicationMenu := Value;
    if Value <> nil then
      Value.FreeNotification(Self);
  end;
end;

procedure TPPGCustomRibbon.SetBackstage(const Value: TControl);
begin
  if FBackstage = Value then
    Exit;
  if Value = Self then
    raise EPPGPropertyError.CreateInvalid(Self, 'Backstage', Value.Name);
  if FBackstageVisible then
    HideBackstage;
  FBackstage := Value;
  if Value <> nil then
  begin
    Value.FreeNotification(Self);
    // Zur Laufzeit ist der Backstage-Bereich zunaechst verborgen
    if not (csDesigning in ComponentState) and not (csLoading in ComponentState) then
      Value.Visible := False;
  end;
end;

procedure TPPGCustomRibbon.SetLargeImages(const Value: TCustomImageList);
begin
  if FLargeImages = Value then
    Exit;
  if FLargeImages <> nil then
    FLargeImages.UnRegisterChanges(FLargeImageLink);
  FLargeImages := Value;
  if FLargeImages <> nil then
  begin
    FLargeImages.RegisterChanges(FLargeImageLink);
    FLargeImages.FreeNotification(Self);
  end;
  LayoutChanged;
end;

procedure TPPGCustomRibbon.LargeImagesChange(Sender: TObject);
begin
  LayoutChanged;
end;

{ ---- IPPGRibbonHost ---- }

procedure TPPGCustomRibbon.RibbonModelChanged;
begin
  LayoutChanged;
end;

procedure TPPGCustomRibbon.RibbonWatch(AComponent: TComponent);
begin
  if AComponent <> nil then
    AComponent.FreeNotification(Self);
end;

procedure TPPGCustomRibbon.RibbonControlChanged(Item: TPPGRibbonItem; OldControl: TControl);
var
  C: TControl;
begin
  if csDestroying in ComponentState then
    Exit;
  C := Item.Control;
  if (C <> nil) and (C is TControl) and (C <> Self) then
  begin
    if C.Parent <> Self then
      C.Parent := Self;
    C.Enabled := Item.Enabled;
  end;
  if (OldControl <> nil) and not (csDestroying in OldControl.ComponentState) and
    (OldControl.Parent <> Self) and (OldControl.Parent is TPPGRibbonPanelPopup) then
    OldControl.Parent := Self;
  LayoutChanged;
end;

{ ---- Masse ---- }

function TPPGCustomRibbon.Sc(V: Integer): Integer;
begin
  Result := PPGScale(V, ScalePPI);
end;

function TPPGCustomRibbon.TextWidth(const S: string): Integer;
begin
  if S = '' then
    Exit(0);
  if FTextCachePPI <> ScalePPI then
  begin
    FTextCache.Clear;
    FTextCachePPI := ScalePPI;
  end;
  if not FTextCache.TryGetValue(S, Result) then
  begin
    Result := PPGMeasureTextNoCanvas(S, Font, 0, False).cx;
    FTextCache.Add(S, Result);
  end;
end;

function TPPGCustomRibbon.TextHeight: Integer;
begin
  Result := PPGMeasureTextNoCanvas('Wg', Font, 0, False).cy;
end;

function TPPGCustomRibbon.RowHeight: Integer;
begin
  Result := Max(Sc(24), TextHeight + Sc(8));
end;

function TPPGCustomRibbon.ContentHeight: Integer;
begin
  Result := 3 * RowHeight;
end;

function TPPGCustomRibbon.CaptionHeight: Integer;
begin
  Result := TextHeight + Sc(6);
end;

function TPPGCustomRibbon.PanelHeight: Integer;
begin
  Result := Sc(PanelPad) + ContentHeight + Sc(2) + CaptionHeight + Sc(2);
end;

function TPPGCustomRibbon.TabRowHeight: Integer;
begin
  Result := Max(Sc(30), TextHeight + Sc(14));
end;

function TPPGCustomRibbon.QatHeight: Integer;
begin
  Result := Max(Sc(30), TextHeight + Sc(12));
end;

function TPPGCustomRibbon.Metrics(ContentTop: Integer): TPPGRibbonMetrics;
begin
  Result.ContentTop := ContentTop;
  Result.RowHeight := RowHeight;
  Result.Rows := 3;
  Result.ColumnGap := Sc(2);
  Result.Padding := Sc(4);
end;

function TPPGCustomRibbon.HasArrow(Item: TPPGRibbonItem): Boolean;
begin
  Result := (Item.Kind = rikSplitButton) or ((Item.Kind = rikButton) and (Item.DropDownMenu <> nil));
end;

procedure TPPGCustomRibbon.SplitCaption(const Caption: string; out Line1, Line2: string);
var
  S: string;
  I, Best, BestW, W: Integer;
begin
  S := StripHotkey(Caption);
  Line1 := S;
  Line2 := '';
  if Pos(' ', S) = 0 then
    Exit;
  // Umbruch an dem Leerzeichen, das die breitere Zeile am schmalsten macht
  Best := 0;
  BestW := MaxInt;
  for I := 2 to Length(S) - 1 do
    if S[I] = ' ' then
    begin
      W := Max(TextWidth(Copy(S, 1, I - 1)), TextWidth(Copy(S, I + 1, MaxInt)));
      if W < BestW then
      begin
        BestW := W;
        Best := I;
      end;
    end;
  if Best > 0 then
  begin
    Line1 := Copy(S, 1, Best - 1);
    Line2 := Copy(S, Best + 1, MaxInt);
  end;
end;

function TPPGCustomRibbon.LargeWidth(Item: TPPGRibbonItem): Integer;
var
  L1, L2: string;
  W2: Integer;
begin
  SplitCaption(Item.Caption, L1, L2);
  W2 := TextWidth(L2);
  if HasArrow(Item) or ((Item.Kind = rikGallery)) then
    Inc(W2, Sc(ArrowW) + Sc(2));
  Result := Max(Sc(IconLarge) + 2 * Sc(PadX), Max(TextWidth(L1), W2) + 2 * Sc(PadX));
end;

function TPPGCustomRibbon.GalleryInlineColumns(Item: TPPGRibbonItem; Size: TPPGRibbonSize): Integer;
begin
  if Size = rsMedium then
    Result := Max(1, (Item.GalleryColumns + 1) div 2)
  else
    Result := Item.GalleryColumns;
end;

function TPPGCustomRibbon.ItemWidth(Item: TPPGRibbonItem; Size: TPPGRibbonSize): Integer;
var
  Arrow, Lbl: Integer;
begin
  case Item.Kind of
    rikSeparator:
      Exit(Sc(9));
    rikControl:
      begin
        Lbl := 0;
        if Item.Caption <> '' then
          Lbl := TextWidth(StripHotkey(Item.Caption)) + Sc(PadX) + Sc(4);
        if Item.Control <> nil then
          Result := Lbl + Item.Control.Width
        else
          Result := Lbl + Sc(60);
        Exit;
      end;
    rikGallery:
      if Size = rsSmall then
        Exit(LargeWidth(Item))
      else
        Exit(GalleryInlineColumns(Item, Size) * Sc(Item.GalleryItemWidth) + Sc(GalleryStrip) + Sc(4));
  end;
  if Size = rsLarge then
    Exit(LargeWidth(Item));
  Arrow := 0;
  if Item.Kind = rikSplitButton then
    Arrow := Sc(SplitArrowW)
  else if HasArrow(Item) then
    Arrow := Sc(ArrowW);
  if Size = rsMedium then
    Result := Sc(PadX) + Sc(IconSmall) + Sc(5) + TextWidth(StripHotkey(Item.Caption)) + Sc(PadX) + Arrow
  else
    Result := Max(RowHeight, Sc(PadX) + Sc(IconSmall) + Sc(PadX) + Arrow);
end;

function TPPGCustomRibbon.GroupCaptionWidth(Group: TPPGRibbonGroup): Integer;
begin
  Result := TextWidth(Group.Caption) + 2 * Sc(8);
  if Group.ShowLauncher then
    Inc(Result, CaptionHeight);
end;

function TPPGCustomRibbon.CollapsedWidth(Group: TPPGRibbonGroup): Integer;
var
  L1, L2: string;
begin
  SplitCaption(Group.Caption, L1, L2);
  Result := Max(Sc(IconLarge) + 2 * Sc(PadX),
    Max(TextWidth(L1), TextWidth(L2) + Sc(ArrowW) + Sc(2)) + 2 * Sc(PadX)) + 2 * Sc(4);
end;

function TPPGCustomRibbon.QuickVisibleCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FQuickAccess.Count - 1 do
    if FQuickAccess[I].Visible then
      Inc(Result);
end;

function TPPGCustomRibbon.QatVisible: Boolean;
begin
  Result := FShowQuickAccess and ((QuickVisibleCount > 0) or FQuickAccessCustomizable);
end;

function TPPGCustomRibbon.AutoSizeWidth: Boolean;
begin
  Result := False;
end;

function TPPGCustomRibbon.CalcAutoSize(out AWidth, AHeight: Integer): Boolean;
begin
  AWidth := Width;
  AHeight := TabRowHeight;
  if QatVisible then
    Inc(AHeight, QatHeight);
  if not FMinimized then
    Inc(AHeight, PanelHeight);
  Result := True;
end;

{ ---- Layout ---- }

procedure TPPGCustomRibbon.LayoutChanged;
begin
  if (csDestroying in ComponentState) or (FTabs = nil) then
    Exit;
  FLayoutValid := False;
  if FPanelPopup <> nil then
    FPanelPopup.View.Valid := False;
  if FGroupPopup <> nil then
    FGroupPopup.View.Valid := False;
  RequestAutoSize;
  RequestControlLayout;
  Invalidate;
  if (FPanelPopup <> nil) and FPanelPopup.IsOpen then
    FPanelPopup.Invalidate;
  if (FGroupPopup <> nil) and FGroupPopup.IsOpen then
    FGroupPopup.Invalidate;
end;

procedure TPPGCustomRibbon.Resize;
begin
  inherited Resize;
  FLayoutValid := False;
  RequestControlLayout;
end;

procedure TPPGCustomRibbon.CMFontChanged(var Message: TMessage);
begin
  inherited;
  if FTextCache <> nil then
    FTextCache.Clear;
  LayoutChanged;
end;

procedure TPPGCustomRibbon.CMBiDiModeChanged(var Message: TMessage);
begin
  inherited;
  LayoutChanged;
end;

procedure TPPGCustomRibbon.MirrorRect(var R: TRect; HostWidth: Integer);
begin
  if not IsRectEmpty(R) then
    R := Rect(HostWidth - R.Right, R.Top, HostWidth - R.Left, R.Bottom);
end;

procedure TPPGCustomRibbon.LayoutQat(Y: Integer);
var
  I, X, B, H: Integer;
begin
  H := QatHeight;
  FQatRect := Rect(0, Y, Width, Y + H);
  SetLength(FQatRects, FQuickAccess.Count);
  B := H - Sc(6);
  X := Sc(PanelPad) + Sc(2);
  for I := 0 to FQuickAccess.Count - 1 do
  begin
    FQatRects[I] := Rect(0, 0, 0, 0);
    if not FQuickAccess[I].Visible then
      Continue;
    if FQuickAccess[I].Kind = rikSeparator then
    begin
      FQatRects[I] := Rect(X, Y + Sc(3), X + Sc(9), Y + H - Sc(3));
      Inc(X, Sc(9));
      Continue;
    end;
    FQatRects[I] := Rect(X, Y + Sc(3), X + B, Y + Sc(3) + B);
    Inc(X, B + Sc(1));
  end;
  if FQuickAccessCustomizable then
    FQatCustomizeRect := Rect(X, Y + Sc(3), X + Sc(18), Y + Sc(3) + B)
  else
    FQatCustomizeRect := Rect(0, 0, 0, 0);
end;

procedure TPPGCustomRibbon.LayoutTabs;
var
  I, X, Y, H: Integer;
  Cap: string;
begin
  Y := FTabRowRect.Top + Sc(4);
  H := FTabRowRect.Bottom - Y;
  X := Sc(PanelPad);
  if FShowApplicationButton then
  begin
    Cap := FApplicationButtonCaption;
    if Cap = '' then
      Cap := PPGStr(@SPPGRibbonFile);
    FAppRect := Rect(X, Y, X + TextWidth(StripHotkey(Cap)) + 2 * Sc(14), Y + H);
    X := FAppRect.Right + Sc(4);
  end
  else
    FAppRect := Rect(0, 0, 0, 0);
  SetLength(FTabRects, FTabs.Count);
  for I := 0 to FTabs.Count - 1 do
  begin
    FTabRects[I] := Rect(0, 0, 0, 0);
    if not FTabs[I].Visible then
      Continue;
    FTabRects[I] := Rect(X, Y, X + TextWidth(StripHotkey(FTabs[I].Caption)) + 2 * Sc(12), Y + H);
    X := FTabRects[I].Right + Sc(1);
  end;
  FMinimizeRect := Rect(Width - Sc(PanelPad) - Sc(28), Y + (H - Sc(24)) div 2,
    Width - Sc(PanelPad), Y + (H - Sc(24)) div 2 + Sc(24));
end;

procedure TPPGCustomRibbon.EnsureLayout;
var
  Y, I: Integer;
begin
  // Breite und DPI pruefen (ohne Fensterhandle kommt kein Resize), dazu die
  // Sprache: ein Wechsel zeichnet nur neu, "Datei" kann breiter werden
  if FLayoutValid and (FLayoutWidth = Width) and (FLayoutPPI = ScalePPI) and
    (FLayoutLang = PPGLanguage) then
    Exit;
  FLayoutValid := True;
  FLayoutWidth := Width;
  FLayoutPPI := ScalePPI;
  FLayoutLang := PPGLanguage;
  Y := 0;
  FQatRect := Rect(0, 0, 0, 0);
  FQatCustomizeRect := Rect(0, 0, 0, 0);
  SetLength(FQatRects, FQuickAccess.Count);
  for I := 0 to High(FQatRects) do
    FQatRects[I] := Rect(0, 0, 0, 0);
  if QatVisible and (FQuickAccessPosition = qapAbove) then
  begin
    LayoutQat(Y);
    Inc(Y, QatHeight);
  end;
  FTabRowRect := Rect(0, Y, Width, Y + TabRowHeight);
  LayoutTabs;
  Inc(Y, TabRowHeight);
  if not FMinimized and (ActiveTab <> nil) then
  begin
    FPanelRect := Rect(0, Y, Width, Y + PanelHeight);
    BuildView(FMainView, ActiveTab, nil, FPanelRect, Self);
  end
  else
  begin
    if FMinimized then
      FPanelRect := Rect(0, 0, 0, 0)
    else
      FPanelRect := Rect(0, Y, Width, Y + PanelHeight);
    BuildView(FMainView, nil, nil, FPanelRect, Self);
  end;
  if not FMinimized then
    Inc(Y, PanelHeight);
  if QatVisible and (FQuickAccessPosition = qapBelow) then
    LayoutQat(Y);
  if UseRightToLeftAlignment then
  begin
    MirrorRect(FAppRect, Width);
    MirrorRect(FMinimizeRect, Width);
    MirrorRect(FQatCustomizeRect, Width);
    for I := 0 to High(FTabRects) do
      MirrorRect(FTabRects[I], Width);
    for I := 0 to High(FQatRects) do
      MirrorRect(FQatRects[I], Width);
  end;
end;

procedure TPPGCustomRibbon.BuildView(View: TPPGRibbonView; ATab: TPPGRibbonTab;
  ASingle: TPPGRibbonGroup; const ABounds: TRect; AHost: TWinControl);
var
  Groups: array of TPPGRibbonGroup;
  Cells: array of TPPGRibbonCells;
  ItemsOf: array of TPPGRibbonItemArray;
  Widths: array of TPPGRibbonGroupWidths;
  Orders: array of Integer;
  States: TPPGRibbonGroupStates;
  Tmp: TPPGRibbonPlaces;
  M: TPPGRibbonMetrics;
  G, I, N, X, W, Top, Bottom, HostW: Integer;
  Grp: TPPGRibbonGroup;
  It: TPPGRibbonItem;
  S: TPPGRibbonSize;
  St: TPPGRibbonGroupState;
  Place: TPPGRibbonGroupPlace;
  Cell: TPPGRibbonCell;
begin
  View.Tab := ATab;
  View.SingleGroup := ASingle;
  View.Host := AHost;
  View.Bounds := ABounds;
  View.Valid := True;
  SetLength(View.Groups, 0);
  if (ATab = nil) or IsRectEmpty(ABounds) then
    Exit;
  // sichtbare Gruppen
  N := 0;
  for G := 0 to ATab.Groups.Count - 1 do
    if ATab.Groups[G].Visible and ((ASingle = nil) or (ATab.Groups[G] = ASingle)) then
      Inc(N);
  SetLength(Groups, N);
  N := 0;
  for G := 0 to ATab.Groups.Count - 1 do
    if ATab.Groups[G].Visible and ((ASingle = nil) or (ATab.Groups[G] = ASingle)) then
    begin
      Groups[N] := ATab.Groups[G];
      Inc(N);
    end;
  SetLength(Cells, N);
  SetLength(ItemsOf, N);
  SetLength(Widths, N);
  SetLength(Orders, N);
  Top := ABounds.Top + Sc(PanelPad);
  Bottom := ABounds.Bottom - Sc(2);
  M := Metrics(Top);
  for G := 0 to N - 1 do
  begin
    Grp := Groups[G];
    Orders[G] := Grp.ReduceOrder;
    SetLength(Cells[G], 0);
    SetLength(ItemsOf[G], 0);
    for I := 0 to Grp.Items.Count - 1 do
    begin
      It := Grp.Items[I];
      if not It.Visible then
        Continue;
      case It.Kind of
        rikSeparator: Cell.Kind := rckSeparator;
        rikControl: Cell.Kind := rckControl;
        rikGallery: Cell.Kind := rckGallery;
      else
        Cell.Kind := rckButton;
      end;
      Cell.MaxSize := It.Size;
      Cell.MinSize := It.MinSize;
      // MinSize groesser als Size (z.B. Size = klein, MinSize = gross) gilt nicht
      if Ord(Cell.MinSize) < Ord(Cell.MaxSize) then
        Cell.MinSize := Cell.MaxSize;
      if It.Kind in [rikControl, rikSeparator] then
      begin
        Cell.MaxSize := rsMedium;
        Cell.MinSize := rsSmall;
      end;
      if It.Kind = rikGallery then
        Cell.MaxSize := rsLarge;
      for S := Low(TPPGRibbonSize) to High(TPPGRibbonSize) do
        Cell.Width[S] := ItemWidth(It, S);
      Cell.BeginColumn := It.BeginColumn;
      Cell.SameRow := It.SameRow;
      SetLength(Cells[G], Length(Cells[G]) + 1);
      Cells[G][High(Cells[G])] := Cell;
      SetLength(ItemsOf[G], Length(ItemsOf[G]) + 1);
      ItemsOf[G][High(ItemsOf[G])] := It;
    end;
    for St := rgsLarge to rgsSmall do
      Widths[G][St] := PPGRibbonLayoutGroup(Cells[G], St, M, GroupCaptionWidth(Grp), Tmp);
    Widths[G][rgsCollapsed] := CollapsedWidth(Grp);
  end;
  if ASingle <> nil then
  begin
    SetLength(States, N);
    for G := 0 to N - 1 do
      States[G] := rgsLarge;
  end
  else
    States := PPGRibbonReduce(Widths, PPGRibbonReduceOrder(Orders),
      RectW(ABounds) - 2 * Sc(PanelPad), Sc(GroupGap));
  SetLength(View.Groups, N);
  X := ABounds.Left + Sc(PanelPad);
  for G := 0 to N - 1 do
  begin
    Place.Group := Groups[G];
    Place.State := States[G];
    W := Widths[G][States[G]];
    Place.Bounds := Rect(X, Top, X + W, Bottom);
    Place.Items := Copy(ItemsOf[G]);
    PPGRibbonLayoutGroup(Cells[G], States[G], M, GroupCaptionWidth(Groups[G]), Place.Places);
    for I := 0 to High(Place.Places) do
      if not IsRectEmpty(Place.Places[I].Bounds) then
        OffsetRect(Place.Places[I].Bounds, X, 0);
    Place.CaptionRect := Rect(X, Bottom - CaptionHeight, X + W, Bottom);
    if Groups[G].ShowLauncher and (States[G] <> rgsCollapsed) then
      Place.LauncherRect := Rect(X + W - CaptionHeight, Place.CaptionRect.Top, X + W, Bottom)
    else
      Place.LauncherRect := Rect(0, 0, 0, 0);
    View.Groups[G] := Place;
    Inc(X, W + Sc(GroupGap));
  end;
  if UseRightToLeftAlignment then
  begin
    HostW := ABounds.Left + ABounds.Right;
    for G := 0 to N - 1 do
    begin
      MirrorRect(View.Groups[G].Bounds, HostW);
      MirrorRect(View.Groups[G].CaptionRect, HostW);
      MirrorRect(View.Groups[G].LauncherRect, HostW);
      for I := 0 to High(View.Groups[G].Places) do
        MirrorRect(View.Groups[G].Places[I].Bounds, HostW);
    end;
  end;
end;

procedure TPPGCustomRibbon.EnsureView(View: TPPGRibbonView);
begin
  if View = FMainView then
    EnsureLayout
  else if (View <> nil) and not View.Valid then
    BuildView(View, View.Tab, View.SingleGroup, View.Bounds, View.Host);
end;

procedure TPPGCustomRibbon.UpdateLayout;
begin
  EnsureLayout;
  ApplyControlLayout;
end;

procedure TPPGCustomRibbon.RequestControlLayout;
begin
  if csDestroying in ComponentState then
    Exit;
  FControlLayoutPending := True;
  if HandleAllocated and not FLayoutPosted then
  begin
    FLayoutPosted := True;
    PostMessage(Handle, GMsgLayout, 0, 0);
  end;
end;

procedure TPPGCustomRibbon.HideControl(C: TControl);
begin
  if csDesigning in ComponentState then
  begin
    // im Designer nie Visible aendern (landete in der DFM): aus dem Blick schieben
    if (C.Left > -C.Width - 1000) then
      C.SetBounds(-C.Width - 10000, C.Top, C.Width, C.Height);
  end
  else if C.Visible then
    C.Visible := False;
end;

/// Zeigt das Fenster eines Controls und seiner sichtbaren Kind-Fenster ohne
/// Aktivierung (die VCL zeigt Kinder eines Popups ohne Parent nicht).
procedure ShowNativeTree(C: TWinControl);
var
  I: Integer;
begin
  if not C.Visible then
    Exit;
  C.HandleNeeded;
  ShowWindow(C.Handle, SW_SHOWNA);
  for I := 0 to C.ControlCount - 1 do
    if C.Controls[I] is TWinControl then
      ShowNativeTree(TWinControl(C.Controls[I]));
end;

procedure TPPGCustomRibbon.PlaceViewControls(View: TPPGRibbonView; Shown: TList<TControl>);
var
  G, I, Lbl, H, Y: Integer;
  It: TPPGRibbonItem;
  R: TRect;
  C: TControl;
begin
  if View = nil then
    Exit;
  EnsureView(View);
  for G := 0 to View.GroupCount - 1 do
  begin
    if View.Groups[G].State = rgsCollapsed then
      Continue;
    for I := 0 to High(View.Groups[G].Items) do
    begin
      It := View.Groups[G].Items[I];
      C := It.Control;
      if (It.Kind <> rikControl) or (C = nil) then
        Continue;
      R := View.Groups[G].Places[I].Bounds;
      if IsRectEmpty(R) then
        Continue;
      if C.Parent <> View.Host then
        C.Parent := View.Host;
      Lbl := 0;
      if It.Caption <> '' then
        Lbl := TextWidth(StripHotkey(It.Caption)) + Sc(PadX) + Sc(4);
      H := Min(C.Height, RectH(R));
      Y := R.Top + (RectH(R) - H) div 2;
      if UseRightToLeftAlignment then
        C.SetBounds(R.Right - Lbl - C.Width, Y, C.Width, H)
      else
        C.SetBounds(R.Left + Lbl, Y, C.Width, H);
      if not (csDesigning in ComponentState) and not C.Visible then
        C.Visible := True;
      // Im Popup: die VCL haelt das per API gezeigte Popup fuer unsichtbar und
      // zeigt seine Kinder deshalb nicht (wie der Kalender im DatePicker)
      if (View.Host <> Self) and (C is TWinControl) then
        ShowNativeTree(TWinControl(C));
      Shown.Add(C);
    end;
  end;
end;

procedure TPPGCustomRibbon.ApplyControlLayout;
var
  Shown: TList<TControl>;
  T, G, I: Integer;
  C: TControl;
begin
  FControlLayoutPending := False;
  if (csDestroying in ComponentState) or (csLoading in ComponentState) or FPlacingControls then
    Exit;
  FPlacingControls := True;
  Shown := TList<TControl>.Create;
  try
    EnsureLayout;
    if not FMinimized then
      PlaceViewControls(FMainView, Shown);
    if (FPanelPopup <> nil) and FPanelPopup.IsOpen then
      PlaceViewControls(FPanelPopup.View, Shown);
    if (FGroupPopup <> nil) and FGroupPopup.IsOpen then
      PlaceViewControls(FGroupPopup.View, Shown);
    // alle uebrigen eingebetteten Controls verbergen
    for T := 0 to FTabs.Count - 1 do
      for G := 0 to FTabs[T].Groups.Count - 1 do
        for I := 0 to FTabs[T].Groups[G].Items.Count - 1 do
        begin
          C := FTabs[T].Groups[G].Items[I].Control;
          if (C <> nil) and (FTabs[T].Groups[G].Items[I].Kind = rikControl) and
            (Shown.IndexOf(C) < 0) then
          begin
            if (C.Parent <> Self) and (C.Parent is TPPGRibbonPanelPopup) then
              C.Parent := Self;
            HideControl(C);
          end;
        end;
  finally
    Shown.Free;
    FPlacingControls := False;
  end;
end;

procedure TPPGCustomRibbon.AlignControls(AControl: TControl; var Rect: TRect);
begin
  inherited AlignControls(AControl, Rect);
  // Ein eingebettetes Control hat seine Groesse geaendert: neu auslegen
  if not FPlacingControls and (AControl <> nil) and not (csLoading in ComponentState) then
  begin
    FLayoutValid := False;
    RequestControlLayout;
    Invalidate;
  end;
end;

{ ---- Treffer ---- }

function TPPGCustomRibbon.SameHit(const A, B: TPPGRibbonHit): Boolean;
begin
  Result := (A.Part = B.Part) and (A.View = B.View) and (A.Index = B.Index) and
    (A.Item = B.Item) and (A.Tile = B.Tile);
end;

function TPPGCustomRibbon.HeadHitTest(X, Y: Integer): TPPGRibbonHit;
var
  I: Integer;
  P: TPoint;
begin
  Result := NoHit;
  P := Point(X, Y);
  if PtInRect(FAppRect, P) then
    Exit(MakeHit(rpAppButton, nil, 0, -1, -1));
  if PtInRect(FMinimizeRect, P) then
    Exit(MakeHit(rpMinimize, nil, 0, -1, -1));
  if PtInRect(FQatCustomizeRect, P) then
    Exit(MakeHit(rpQuickCustomize, nil, 0, -1, -1));
  for I := 0 to High(FTabRects) do
    if PtInRect(FTabRects[I], P) then
      Exit(MakeHit(rpTab, nil, I, -1, -1));
  for I := 0 to High(FQatRects) do
    if PtInRect(FQatRects[I], P) and (FQuickAccess[I].Kind <> rikSeparator) then
      Exit(MakeHit(rpQuickItem, nil, I, -1, -1));
end;

function TPPGCustomRibbon.GalleryGeometry(Item: TPPGRibbonItem; const R: TRect; out Tiles,
  Strip: TRect; out Cols, Rows, TileW, TileH: Integer): Boolean;
begin
  Result := not IsRectEmpty(R);
  TileW := Max(1, Sc(Item.GalleryItemWidth));
  if Item.GalleryItemHeight = 0 then
    TileH := RectH(R) - Sc(4)
  else
    TileH := Min(RectH(R) - Sc(4), Sc(Item.GalleryItemHeight));
  TileH := Max(1, TileH);
  if UseRightToLeftAlignment then
  begin
    Strip := Rect(R.Left, R.Top + Sc(2), R.Left + Sc(GalleryStrip), R.Bottom - Sc(2));
    Tiles := Rect(Strip.Right + Sc(2), R.Top + Sc(2), R.Right - Sc(2), R.Bottom - Sc(2));
  end
  else
  begin
    Strip := Rect(R.Right - Sc(GalleryStrip), R.Top + Sc(2), R.Right, R.Bottom - Sc(2));
    Tiles := Rect(R.Left + Sc(2), R.Top + Sc(2), Strip.Left - Sc(2), R.Bottom - Sc(2));
  end;
  Cols := Max(1, RectW(Tiles) div TileW);
  Rows := Max(1, RectH(Tiles) div TileH);
end;

function TPPGCustomRibbon.ViewHitTest(View: TPPGRibbonView; X, Y: Integer): TPPGRibbonHit;
var
  G, I, Cols, Rows, TileW, TileH, Row, Col, Idx, Third: Integer;
  P: TPoint;
  R, Tiles, Strip, ArrowR: TRect;
  It: TPPGRibbonItem;
  Size: TPPGRibbonSize;
begin
  Result := NoHit;
  if View = nil then
    Exit;
  EnsureView(View);
  P := Point(X, Y);
  for G := 0 to View.GroupCount - 1 do
  begin
    if not PtInRect(View.Groups[G].Bounds, P) then
      Continue;
    if View.Groups[G].State = rgsCollapsed then
      Exit(MakeHit(rpGroup, View, G, -1, -1));
    if PtInRect(View.Groups[G].LauncherRect, P) then
      Exit(MakeHit(rpLauncher, View, G, -1, -1));
    for I := 0 to High(View.Groups[G].Items) do
    begin
      R := View.Groups[G].Places[I].Bounds;
      if not PtInRect(R, P) then
        Continue;
      It := View.Groups[G].Items[I];
      Size := View.Groups[G].Places[I].Size;
      case It.Kind of
        rikSeparator, rikControl:
          Exit;
        rikGallery:
          begin
            if Size = rsSmall then
              Exit(MakeHit(rpGalleryMore, View, G, I, -1));
            GalleryGeometry(It, R, Tiles, Strip, Cols, Rows, TileW, TileH);
            if PtInRect(Strip, P) then
            begin
              Third := Max(1, RectH(Strip) div 3);
              if Y < Strip.Top + Third then
                Exit(MakeHit(rpGalleryUp, View, G, I, -1))
              else if Y < Strip.Top + 2 * Third then
                Exit(MakeHit(rpGalleryDown, View, G, I, -1))
              else
                Exit(MakeHit(rpGalleryMore, View, G, I, -1));
            end;
            if PtInRect(Tiles, P) then
            begin
              if UseRightToLeftAlignment then
                Col := (Tiles.Right - X) div TileW
              else
                Col := (X - Tiles.Left) div TileW;
              Row := (Y - Tiles.Top) div TileH;
              if (Col < Cols) and (Row < Rows) then
              begin
                Idx := (It.GalleryTopRow + Row) * Cols + Col;
                if Idx < It.GalleryTotal then
                  Exit(MakeHit(rpGalleryTile, View, G, I, Idx));
              end;
            end;
            Exit(MakeHit(rpItem, View, G, I, -1));
          end;
        rikSplitButton:
          begin
            if Size = rsLarge then
              ArrowR := Rect(R.Left, R.Top + Sc(PadX) + Sc(IconLarge) + Sc(2), R.Right, R.Bottom)
            else if UseRightToLeftAlignment then
              ArrowR := Rect(R.Left, R.Top, R.Left + Sc(SplitArrowW), R.Bottom)
            else
              ArrowR := Rect(R.Right - Sc(SplitArrowW), R.Top, R.Right, R.Bottom);
            if PtInRect(ArrowR, P) then
              Exit(MakeHit(rpItemArrow, View, G, I, -1));
            Exit(MakeHit(rpItem, View, G, I, -1));
          end;
      else
        Exit(MakeHit(rpItem, View, G, I, -1));
      end;
    end;
    Exit;
  end;
end;

function TPPGCustomRibbon.HitTest(X, Y: Integer): TPPGRibbonHit;
begin
  EnsureLayout;
  Result := HeadHitTest(X, Y);
  if (Result.Part = rpNone) and not FMinimized then
    Result := ViewHitTest(FMainView, X, Y);
end;

function TPPGCustomRibbon.HitItem(const Hit: TPPGRibbonHit): TPPGRibbonItem;
begin
  Result := nil;
  case Hit.Part of
    rpQuickItem:
      if (Hit.Index >= 0) and (Hit.Index < FQuickAccess.Count) then
        Result := FQuickAccess[Hit.Index];
    rpItem, rpItemArrow, rpGalleryTile, rpGalleryUp, rpGalleryDown, rpGalleryMore:
      if (Hit.View <> nil) and (Hit.Index >= 0) and (Hit.Index < Hit.View.GroupCount) and
        (Hit.Item >= 0) and (Hit.Item <= High(Hit.View.Groups[Hit.Index].Items)) then
        Result := Hit.View.Groups[Hit.Index].Items[Hit.Item];
  end;
end;

function TPPGCustomRibbon.HitRect(const Hit: TPPGRibbonHit): TRect;
var
  It: TPPGRibbonItem;
  Tiles, Strip: TRect;
  Cols, Rows, TileW, TileH, Third, Row, Col: Integer;
begin
  Result := Rect(0, 0, 0, 0);
  EnsureLayout;
  case Hit.Part of
    rpAppButton: Result := FAppRect;
    rpMinimize: Result := FMinimizeRect;
    rpQuickCustomize: Result := FQatCustomizeRect;
    rpTab:
      if (Hit.Index >= 0) and (Hit.Index <= High(FTabRects)) then
        Result := FTabRects[Hit.Index];
    rpQuickItem:
      if (Hit.Index >= 0) and (Hit.Index <= High(FQatRects)) then
        Result := FQatRects[Hit.Index];
    rpGroup:
      if (Hit.View <> nil) and (Hit.Index < Hit.View.GroupCount) then
        Result := Hit.View.Groups[Hit.Index].Bounds;
    rpLauncher:
      if (Hit.View <> nil) and (Hit.Index < Hit.View.GroupCount) then
        Result := Hit.View.Groups[Hit.Index].LauncherRect;
    rpItem, rpItemArrow, rpGalleryTile, rpGalleryUp, rpGalleryDown, rpGalleryMore:
      begin
        It := HitItem(Hit);
        if It = nil then
          Exit;
        Result := Hit.View.Groups[Hit.Index].Places[Hit.Item].Bounds;
        if (It.Kind = rikGallery) and (Hit.Part <> rpItem) and
          (Hit.View.Groups[Hit.Index].Places[Hit.Item].Size <> rsSmall) then
        begin
          GalleryGeometry(It, Result, Tiles, Strip, Cols, Rows, TileW, TileH);
          Third := Max(1, RectH(Strip) div 3);
          case Hit.Part of
            rpGalleryUp: Result := Rect(Strip.Left, Strip.Top, Strip.Right, Strip.Top + Third);
            rpGalleryDown: Result := Rect(Strip.Left, Strip.Top + Third, Strip.Right, Strip.Top + 2 * Third);
            rpGalleryMore: Result := Rect(Strip.Left, Strip.Top + 2 * Third, Strip.Right, Strip.Bottom);
            rpGalleryTile:
              begin
                Row := Hit.Tile div Cols - It.GalleryTopRow;
                Col := Hit.Tile mod Cols;
                if UseRightToLeftAlignment then
                  Result := Rect(Tiles.Right - (Col + 1) * TileW, Tiles.Top + Row * TileH,
                    Tiles.Right - Col * TileW, Tiles.Top + (Row + 1) * TileH)
                else
                  Result := Rect(Tiles.Left + Col * TileW, Tiles.Top + Row * TileH,
                    Tiles.Left + (Col + 1) * TileW, Tiles.Top + (Row + 1) * TileH);
              end;
          end;
        end;
      end;
  end;
end;

function TPPGCustomRibbon.HitScreenRect(const Hit: TPPGRibbonHit): TRect;
var
  R: TRect;
  Host: TWinControl;
begin
  R := HitRect(Hit);
  Host := Self;
  if (Hit.View <> nil) and (Hit.View.Host <> nil) then
    Host := Hit.View.Host;
  if Host.HandleAllocated then
  begin
    Result.TopLeft := Host.ClientToScreen(R.TopLeft);
    Result.BottomRight := Host.ClientToScreen(R.BottomRight);
  end
  else
    Result := R;
end;

{ ---- Geometrie (oeffentlich) ---- }

function TPPGCustomRibbon.TabRect(Index: Integer): TRect;
begin
  EnsureLayout;
  if (Index >= 0) and (Index <= High(FTabRects)) then
    Result := FTabRects[Index]
  else
    Result := Rect(0, 0, 0, 0);
end;

function TPPGCustomRibbon.ApplicationButtonRect: TRect;
begin
  EnsureLayout;
  Result := FAppRect;
end;

function TPPGCustomRibbon.MinimizeButtonRect: TRect;
begin
  EnsureLayout;
  Result := FMinimizeRect;
end;

function TPPGCustomRibbon.QuickItemRect(Index: Integer): TRect;
begin
  EnsureLayout;
  if (Index >= 0) and (Index <= High(FQatRects)) then
    Result := FQatRects[Index]
  else
    Result := Rect(0, 0, 0, 0);
end;

function TPPGCustomRibbon.QuickCustomizeRect: TRect;
begin
  EnsureLayout;
  Result := FQatCustomizeRect;
end;

function TPPGCustomRibbon.PanelRect: TRect;
begin
  EnsureLayout;
  Result := FPanelRect;
end;

function TPPGCustomRibbon.GroupCount: Integer;
begin
  EnsureLayout;
  Result := FMainView.GroupCount;
end;

function TPPGCustomRibbon.GroupRect(Index: Integer): TRect;
begin
  EnsureLayout;
  if (Index >= 0) and (Index < FMainView.GroupCount) then
    Result := FMainView.Groups[Index].Bounds
  else
    Result := Rect(0, 0, 0, 0);
end;

function TPPGCustomRibbon.GroupState(Index: Integer): TPPGRibbonGroupState;
begin
  EnsureLayout;
  if (Index >= 0) and (Index < FMainView.GroupCount) then
    Result := FMainView.Groups[Index].State
  else
    Result := rgsLarge;
end;

function TPPGCustomRibbon.GroupPlaceOf(Group: TPPGRibbonGroup): Integer;
var
  G: Integer;
begin
  EnsureLayout;
  for G := 0 to FMainView.GroupCount - 1 do
    if FMainView.Groups[G].Group = Group then
      Exit(G);
  Result := -1;
end;

function TPPGCustomRibbon.ItemRect(Item: TPPGRibbonItem): TRect;
var
  G, I: Integer;
begin
  EnsureLayout;
  Result := Rect(0, 0, 0, 0);
  for G := 0 to FMainView.GroupCount - 1 do
    if FMainView.Groups[G].State <> rgsCollapsed then
      for I := 0 to High(FMainView.Groups[G].Items) do
        if FMainView.Groups[G].Items[I] = Item then
          Exit(FMainView.Groups[G].Places[I].Bounds);
end;

function TPPGCustomRibbon.ItemSize(Item: TPPGRibbonItem): TPPGRibbonSize;
var
  G, I: Integer;
begin
  EnsureLayout;
  Result := rsSmall;
  for G := 0 to FMainView.GroupCount - 1 do
    for I := 0 to High(FMainView.Groups[G].Items) do
      if FMainView.Groups[G].Items[I] = Item then
        Exit(FMainView.Groups[G].Places[I].Size);
end;

{ ---- Zeichnen ---- }

function TPPGCustomRibbon.RibbonColors: TPPGRibbonColors;
var
  T: TPPGTokens;
  A: TPPGAppearance;
begin
  Result.HC := HighContrastSupport and PPGIsHighContrast;
  if Result.HC then
  begin
    Result.Back := PPGColorToRGB(clBtnFace);
    Result.Panel := PPGColorToRGB(clWindow);
    Result.Stroke := PPGColorToRGB(clWindowText);
    Result.Text := PPGColorToRGB(clWindowText);
    Result.TextSecondary := PPGColorToRGB(clWindowText);
    Result.TextDisabled := PPGColorToRGB(clGrayText);
    Result.Accent := PPGColorToRGB(clHighlight);
    Result.OnAccent := PPGColorToRGB(clHighlightText);
    Exit;
  end;
  T := Tokens;
  if UseVclStyle then
  begin
    A := EffectiveAppearance;
    Result.Panel := PPGColorToRGB(A.Normal.Color);
    Result.Text := PPGColorToRGB(A.Normal.TextColor);
    Result.Back := PPGBlendColor(Result.Panel, Result.Text, 0.05);
    Result.Stroke := PPGBlendColor(Result.Panel, Result.Text, 0.2);
    Result.TextSecondary := PPGBlendColor(Result.Panel, Result.Text, 0.7);
    Result.TextDisabled := PPGBlendColor(Result.Panel, Result.Text, 0.45);
    Result.Accent := PPGColorToRGB(A.FocusColor);
    Result.OnAccent := clWhite;
    Exit;
  end;
  Result.Back := T.Background;
  Result.Panel := T.Layer;
  Result.Stroke := T.Stroke;
  Result.Text := T.TextPrimary;
  Result.TextSecondary := T.TextSecondary;
  Result.TextDisabled := T.TextDisabled;
  Result.Accent := T.Accent;
  Result.OnAccent := T.OnAccent;
end;

procedure TPPGCustomRibbon.PaintFace(const ACanvas: IPPGCanvas; const R: TRect; Hot, Pressed,
  Checked, AEnabled: Boolean; const C: TPPGRibbonColors; out TextColor: TColor);
var
  A: TPPGAppearance;
  S: TPPGSurfaceStyle;
  PPI: Integer;
begin
  if AEnabled then
    TextColor := C.Text
  else
    TextColor := C.TextDisabled;
  if not (Hot or Pressed or Checked) or IsRectEmpty(R) then
    Exit;
  if C.HC then
  begin
    if Checked or Pressed then
    begin
      ACanvas.FillRoundRect(R, 0, C.Accent, 255);
      TextColor := C.OnAccent;
    end
    else
      ACanvas.FrameRoundRect(R, 0, 1, C.Text, 255);
    Exit;
  end;
  PPI := ScalePPI;
  A := EffectiveAppearance;
  if not AEnabled then
    S := A.Resolve(vsDisabled, PPI, False)
  else if Pressed or (Checked and not Hot) then
    S := A.Resolve(vsDown, PPI, False)
  else
    S := A.Resolve(vsHot, PPI, False);
  S.GlowAlpha := 0;
  S.Rounding := Min(S.Rounding, PPGScale(4, PPI));
  Renderer.DrawSurface(ACanvas, R, S);
  if AEnabled then
    TextColor := S.TextColor;
end;

procedure TPPGCustomRibbon.PaintIcon(const ACanvas: IPPGCanvas; Item: TPPGRibbonItem; const R: TRect;
  Large: Boolean; Color: TColor; AEnabled: Boolean);
var
  Idx, Sz, Cx, Cy, Half, Gap: Integer;
  L: TCustomImageList;
begin
  if Large then
    Sz := Sc(IconLarge)
  else
    Sz := Sc(IconSmall);
  L := nil;
  Idx := -1;
  if Large and (FLargeImages <> nil) then
  begin
    L := FLargeImages;
    Idx := Item.LargeImageIndex;
    if Idx < 0 then
      Idx := Item.ImageIndex;
  end;
  if ((L = nil) or (Idx < 0)) and (Images <> nil) and (Item.ImageIndex >= 0) then
  begin
    L := Images;
    Idx := Item.ImageIndex;
  end;
  if (L <> nil) and (Idx >= 0) and (Idx < L.Count) then
  begin
    ACanvas.DrawImage(L, Idx, (R.Left + R.Right - L.Width) div 2, (R.Top + R.Bottom - L.Height) div 2,
      AEnabled);
    Exit;
  end;
  if (Item.IconChar <> 0) and PPGDrawIconChar(ACanvas, R, Item.IconChar, Color, Sz) then
    Exit;
  if Item.Kind = rikGallery then
  begin
    // Galerie ohne Symbol: Raster aus vier Kacheln
    Cx := (R.Left + R.Right) div 2;
    Cy := (R.Top + R.Bottom) div 2;
    Half := Sz div 2 - Sc(1);
    Gap := Max(1, Sc(2));
    ACanvas.FrameRoundRect(Rect(Cx - Half, Cy - Half, Cx - Gap div 2, Cy - Gap div 2), Sc(2), 1, Color, 255);
    ACanvas.FrameRoundRect(Rect(Cx + Gap div 2, Cy - Half, Cx + Half, Cy - Gap div 2), Sc(2), 1, Color, 255);
    ACanvas.FrameRoundRect(Rect(Cx - Half, Cy + Gap div 2, Cx - Gap div 2, Cy + Half), Sc(2), 1, Color, 255);
    ACanvas.FillRoundRect(Rect(Cx + Gap div 2, Cy + Gap div 2, Cx + Half, Cy + Half), Sc(2), Color, 255);
    Exit;
  end;
  // kein Symbol: erster Buchstabe
  if StripHotkey(Item.Caption) <> '' then
    ACanvas.DrawText(R, Copy(StripHotkey(Item.Caption), 1, 1), Font, Color,
      DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
end;

procedure TPPGCustomRibbon.PaintArrow(const ACanvas: IPPGCanvas; const R: TRect; Color: TColor);
var
  Cx, Cy, S: Integer;
begin
  if PPGDrawIcon(ACanvas, R, igChevronDown, Color, Sc(8)) then
    Exit;
  Cx := (R.Left + R.Right) div 2;
  Cy := (R.Top + R.Bottom) div 2;
  S := Sc(3);
  ACanvas.DrawPolyline([Point(Cx - S, Cy - S div 2), Point(Cx, Cy + S div 2), Point(Cx + S, Cy - S div 2)],
    Max(1, Sc(1)), Color, 255);
end;

procedure TPPGCustomRibbon.PaintGalleryTiles(const ACanvas: IPPGCanvas; Item: TPPGRibbonItem;
  const Tiles: TRect; Cols, TopRow, Rows, TileW, TileH, HotTile, FocusTile: Integer;
  const C: TPPGRibbonColors);
var
  Info: TPPGItemPaintInfo;
  IR: IPPGItemRenderer;
  Data: TPPGItemData;
  Col: TColor;
  I, First, Last, Row, Cl: Integer;
  R, Inner, Sw: TRect;
  DC: HDC;
  Cv: TCanvas;
  Handled, Sel, Hot: Boolean;
begin
  if (Item = nil) or (Cols < 1) then
    Exit;
  IR := PPGItemRendererOf(Renderer);
  Info.ListStyle := EffectiveAppearance.Resolve(vsNormal, ScalePPI, False);
  Info.ListStyle.Color := C.Panel;
  Info.ListStyle.TextColor := C.Text;
  Info.ListStyle.GlowColor := C.Accent;
  Info.HighlightStyle := EffectiveAppearance.Resolve(vsHot, ScalePPI, False);
  if C.HC then
  begin
    Info.HighlightStyle.Color := C.Accent;
    Info.HighlightStyle.ColorTo := C.Accent;
    Info.HighlightStyle.TextColor := C.OnAccent;
  end;
  Info.Font := Font;
  Info.Images := Images;
  Info.AllowMarkup := False;
  Info.RightToLeft := UseRightToLeftAlignment;
  Info.Enabled := Enabled and Item.Enabled;
  Info.PPI := ScalePPI;
  First := TopRow * Cols;
  Last := Min(Item.GalleryTotal, (TopRow + Rows) * Cols) - 1;
  for I := First to Last do
  begin
    Row := I div Cols - TopRow;
    Cl := I mod Cols;
    if Info.RightToLeft then
      R := Rect(Tiles.Right - (Cl + 1) * TileW, Tiles.Top + Row * TileH, Tiles.Right - Cl * TileW,
        Tiles.Top + (Row + 1) * TileH)
    else
      R := Rect(Tiles.Left + Cl * TileW, Tiles.Top + Row * TileH, Tiles.Left + (Cl + 1) * TileW,
        Tiles.Top + (Row + 1) * TileH);
    Sel := I = Item.GalleryIndex;
    Hot := (I = HotTile) or (I = FocusTile);
    Handled := False;
    if Assigned(FOnDrawGalleryItem) then
    begin
      DC := ACanvas.BeginGdi;
      try
        Cv := TCanvas.Create;
        try
          Cv.Handle := DC;
          Cv.Font := Font;
          FOnDrawGalleryItem(Self, Item, I, Cv, R, Sel, Hot, Handled);
          Cv.Handle := 0;
        finally
          Cv.Free;
        end;
      finally
        ACanvas.EndGdi(DC);
      end;
    end;
    if Handled then
      Continue;
    Inner := R;
    InflateRect(Inner, -Sc(1), -Sc(1));
    FPainter.PaintBackground(ACanvas, IR, Inner, Info, Sel, I = FocusTile, Ord(Hot));
    Data.Text := '';
    Data.Detail := '';
    Data.Badge := '';
    Data.Group := '';
    Data.ImageIndex := -1;
    Data.Checked := cbUnchecked;
    Data.Enabled := Item.Enabled;
    Data.IsHeader := False;
    Data.Data := nil;
    Col := clNone;
    GetGalleryData(Item, I, Data, Col);
    if Col <> clNone then
    begin
      // Farbfeld: links quadratisch, bei hohen Kacheln oben
      if RectH(Inner) >= 2 * TextHeight + Sc(16) then
      begin
        Sw := Rect(Inner.Left + Sc(6), Inner.Top + Sc(6), Inner.Right - Sc(6),
          Inner.Bottom - TextHeight - Sc(8));
        Inner.Top := Sw.Bottom;
      end
      else
      begin
        Sw := Rect(Inner.Left + Sc(6), Inner.Top + Sc(5), Inner.Left + Sc(6) + RectH(Inner) - Sc(10),
          Inner.Bottom - Sc(5));
        Inner.Left := Sw.Right;
      end;
      ACanvas.FillRoundRect(Sw, Sc(3), PPGColorToRGB(Col), 255);
      ACanvas.FrameRoundRect(Sw, Sc(3), 1, PPGBlendColor(PPGColorToRGB(Col), C.Text, 0.3), 255);
    end;
    if (Data.Text <> '') or (Data.ImageIndex >= 0) then
      FPainter.PaintContent(ACanvas, IR, Inner, Data, Info, Hot or Sel);
  end;
end;

procedure TPPGCustomRibbon.GetGalleryData(Item: TPPGRibbonItem; Index: Integer; var Data: TPPGItemData;
  var Color: TColor);
begin
  if (Index >= 0) and (Index < Item.GalleryItems.Count) then
    Data.Text := Item.GalleryItems[Index];
  if Assigned(FOnGetGalleryItem) then
    FOnGetGalleryItem(Self, Item, Index, Data, Color);
end;

procedure TPPGCustomRibbon.PaintItem(const ACanvas: IPPGCanvas; View: TPPGRibbonView; G, I: Integer;
  const C: TPPGRibbonColors);
var
  It: TPPGRibbonItem;
  R, IconR, TextR, ArrowR, BodyR, Tiles, Strip: TRect;
  Size: TPPGRibbonSize;
  En, HotBody, HotArrow, DownBody, DownArrow, Checked: Boolean;
  TextCol, ArrowCol: TColor;
  L1, L2: string;
  Th, X, Cols, Rows, TileW, TileH, Third, HotTile: Integer;
  Flags: Cardinal;
  HotPart: TPPGRibbonPart;
begin
  It := View.Groups[G].Items[I];
  R := View.Groups[G].Places[I].Bounds;
  Size := View.Groups[G].Places[I].Size;
  if IsRectEmpty(R) then
    Exit;
  En := Enabled and It.Enabled;
  HotPart := rpNone;
  if (FHot.View = View) and (FHot.Index = G) and (FHot.Item = I) then
    HotPart := FHot.Part;
  DownBody := (FDown.View = View) and (FDown.Index = G) and (FDown.Item = I) and (FDown.Part = rpItem);
  DownArrow := (FDown.View = View) and (FDown.Index = G) and (FDown.Item = I) and (FDown.Part = rpItemArrow);
  Th := TextHeight;
  case It.Kind of
    rikSeparator:
      begin
        X := (R.Left + R.Right) div 2;
        ACanvas.FillRoundRect(Rect(X, R.Top + Sc(4), X + 1, R.Bottom - Sc(4)), 0,
          PPGBlendColor(C.Panel, C.Text, 0.2), 255);
        Exit;
      end;
    rikControl:
      begin
        if It.Caption <> '' then
        begin
          if En then
            TextCol := C.Text
          else
            TextCol := C.TextDisabled;
          TextR := Rect(R.Left + Sc(PadX), R.Top, R.Right, R.Bottom);
          if It.Control <> nil then
            if UseRightToLeftAlignment then
              TextR := Rect(R.Right - Sc(PadX) - TextWidth(StripHotkey(It.Caption)), R.Top, R.Right - Sc(PadX), R.Bottom)
            else
              TextR.Right := TextR.Left + TextWidth(StripHotkey(It.Caption));
          ACanvas.DrawText(TextR, StripHotkey(It.Caption), Font, TextCol,
            DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX));
        end;
        Exit;
      end;
    rikGallery:
      if Size <> rsSmall then
      begin
        GalleryGeometry(It, R, Tiles, Strip, Cols, Rows, TileW, TileH);
        // Rahmen der Galerie
        ACanvas.FrameRoundRect(R, Sc(3), 1, PPGBlendColor(C.Panel, C.Text, 0.18), 255);
        HotTile := -1;
        if HotPart = rpGalleryTile then
          HotTile := FHot.Tile;
        It.GalleryTopRow := Max(0, Min(It.GalleryTopRow,
          (It.GalleryTotal + Cols - 1) div Cols - Rows));
        PaintGalleryTiles(ACanvas, It, Tiles, Cols, It.GalleryTopRow, Rows, TileW, TileH, HotTile, -1, C);
        // Blaettern und Aufklappen
        Third := Max(1, RectH(Strip) div 3);
        ArrowR := Rect(Strip.Left, Strip.Top, Strip.Right, Strip.Top + Third);
        PaintFace(ACanvas, ArrowR, HotPart = rpGalleryUp, False, False, En, C, ArrowCol);
        if not PPGDrawIcon(ACanvas, ArrowR, igChevronUp, ArrowCol, Sc(8)) then
          PaintArrow(ACanvas, ArrowR, ArrowCol);
        ArrowR := Rect(Strip.Left, Strip.Top + Third, Strip.Right, Strip.Top + 2 * Third);
        PaintFace(ACanvas, ArrowR, HotPart = rpGalleryDown, False, False, En, C, ArrowCol);
        PaintArrow(ACanvas, ArrowR, ArrowCol);
        ArrowR := Rect(Strip.Left, Strip.Top + 2 * Third, Strip.Right, Strip.Bottom);
        PaintFace(ACanvas, ArrowR, HotPart = rpGalleryMore, False, False, En, C, ArrowCol);
        PaintArrow(ACanvas, ArrowR, ArrowCol);
        ACanvas.FillRoundRect(Rect(ArrowR.Left + Sc(4), ArrowR.Top + Sc(3), ArrowR.Right - Sc(4),
          ArrowR.Top + Sc(3) + Max(1, Sc(1))), 0, ArrowCol, 255);
        Exit;
      end;
  end;
  // Button-artige Items (auch Galerie als Dropdown)
  Checked := (It.Kind = rikCheck) and It.Down;
  HotBody := En and (HotPart in [rpItem, rpGalleryMore]);
  HotArrow := En and (HotPart = rpItemArrow);
  if It.Kind = rikSplitButton then
  begin
    if Size = rsLarge then
    begin
      BodyR := Rect(R.Left, R.Top, R.Right, R.Top + Sc(PadX) + Sc(IconLarge) + Sc(2));
      ArrowR := Rect(R.Left, BodyR.Bottom, R.Right, R.Bottom);
    end
    else if UseRightToLeftAlignment then
    begin
      ArrowR := Rect(R.Left, R.Top, R.Left + Sc(SplitArrowW), R.Bottom);
      BodyR := Rect(ArrowR.Right, R.Top, R.Right, R.Bottom);
    end
    else
    begin
      ArrowR := Rect(R.Right - Sc(SplitArrowW), R.Top, R.Right, R.Bottom);
      BodyR := Rect(R.Left, R.Top, ArrowR.Left, R.Bottom);
    end;
    // Hover: ganzer Button dezent, der Teil unter der Maus kraeftiger
    if HotBody or HotArrow then
      PaintFace(ACanvas, R, True, False, False, En, C, TextCol);
    PaintFace(ACanvas, BodyR, HotBody, DownBody, False, En, C, TextCol);
    PaintFace(ACanvas, ArrowR, HotArrow, DownArrow, False, En, C, ArrowCol);
    if not (HotBody or HotArrow or DownBody or DownArrow) then
    begin
      TextCol := IfThen(En, C.Text, C.TextDisabled);
      ArrowCol := TextCol;
    end;
  end
  else
  begin
    PaintFace(ACanvas, R, HotBody, DownBody, Checked, En, C, TextCol);
    ArrowCol := TextCol;
  end;
  Flags := DT_SINGLELINE or DT_NOPREFIX;
  // Galerie als Dropdown: wie ein grosser Button
  if It.Kind = rikGallery then
    Size := rsLarge;
  case Size of
    rsLarge:
      begin
        IconR := Rect(R.Left, R.Top + Sc(PadX) - Sc(2), R.Right, R.Top + Sc(PadX) - Sc(2) + Sc(IconLarge));
        PaintIcon(ACanvas, It, IconR, True, TextCol, En);
        SplitCaption(It.Caption, L1, L2);
        TextR := Rect(R.Left + Sc(2), IconR.Bottom + Sc(2), R.Right - Sc(2), IconR.Bottom + Sc(2) + Th);
        ACanvas.DrawText(TextR, L1, Font, TextCol, Flags or DT_CENTER or DT_END_ELLIPSIS);
        OffsetRect(TextR, 0, Th);
        if HasArrow(It) or (It.Kind = rikGallery) then
        begin
          // Pfeil hinter der zweiten Zeile (bzw. allein darin)
          X := (R.Left + R.Right + TextWidth(L2)) div 2 + Sc(1);
          if L2 <> '' then
          begin
            ACanvas.DrawText(Rect(TextR.Left, TextR.Top, X - Sc(ArrowW) div 2, TextR.Bottom), L2, Font, TextCol,
              Flags or DT_RIGHT or DT_END_ELLIPSIS);
            PaintArrow(ACanvas, Rect(X - Sc(ArrowW) div 2, TextR.Top, X + Sc(ArrowW) div 2 + Sc(ArrowW) div 2,
              TextR.Bottom), ArrowCol);
          end
          else
            PaintArrow(ACanvas, TextR, ArrowCol);
        end
        else if L2 <> '' then
          ACanvas.DrawText(TextR, L2, Font, TextCol, Flags or DT_CENTER or DT_END_ELLIPSIS);
      end;
  else
    begin
      if UseRightToLeftAlignment then
        IconR := Rect(R.Right - Sc(PadX) - Sc(IconSmall), R.Top, R.Right - Sc(PadX), R.Bottom)
      else
        IconR := Rect(R.Left + Sc(PadX), R.Top, R.Left + Sc(PadX) + Sc(IconSmall), R.Bottom);
      if Size = rsSmall then
      begin
        if HasArrow(It) then
        begin
          if UseRightToLeftAlignment then
            IconR := Rect(R.Right - Sc(PadX) - Sc(IconSmall), R.Top, R.Right - Sc(PadX), R.Bottom)
          else
            IconR := Rect(R.Left + Sc(PadX), R.Top, R.Left + Sc(PadX) + Sc(IconSmall), R.Bottom);
        end
        else
          IconR := Rect((R.Left + R.Right - Sc(IconSmall)) div 2, R.Top,
            (R.Left + R.Right + Sc(IconSmall)) div 2, R.Bottom);
      end;
      PaintIcon(ACanvas, It, IconR, False, TextCol, En);
      if Size = rsMedium then
      begin
        if UseRightToLeftAlignment then
          TextR := Rect(R.Left + Sc(PadX), R.Top, IconR.Left - Sc(5), R.Bottom)
        else
          TextR := Rect(IconR.Right + Sc(5), R.Top, R.Right - Sc(PadX), R.Bottom);
        if HasArrow(It) then
          if UseRightToLeftAlignment then
            Inc(TextR.Left, Sc(ArrowW))
          else
            Dec(TextR.Right, Sc(ArrowW));
        ACanvas.DrawText(TextR, StripHotkey(It.Caption), Font, TextCol,
          DrawTextBiDiModeFlags(Flags or DT_VCENTER or DT_END_ELLIPSIS));
      end;
      if HasArrow(It) then
      begin
        if It.Kind = rikSplitButton then
          PaintArrow(ACanvas, ArrowR, ArrowCol)
        else if UseRightToLeftAlignment then
          PaintArrow(ACanvas, Rect(R.Left + Sc(2), R.Top, R.Left + Sc(2) + Sc(ArrowW), R.Bottom), ArrowCol)
        else
          PaintArrow(ACanvas, Rect(R.Right - Sc(2) - Sc(ArrowW), R.Top, R.Right - Sc(2), R.Bottom), ArrowCol);
      end;
    end;
  end;
end;

procedure TPPGCustomRibbon.PaintGroup(const ACanvas: IPPGCanvas; View: TPPGRibbonView; G: Integer;
  const C: TPPGRibbonColors);
var
  P: TPPGRibbonGroupPlace;
  I, X, Th: Integer;
  R, IconR, TextR: TRect;
  Hot, Down, En: Boolean;
  TextCol: TColor;
  L1, L2: string;
  Dummy: TPPGRibbonItem;
begin
  P := View.Groups[G];
  En := Enabled;
  Th := TextHeight;
  // Trennlinie rechts (bei RTL links)
  if UseRightToLeftAlignment then
    X := P.Bounds.Left - 1
  else
    X := P.Bounds.Right;
  if (View.SingleGroup = nil) then
    ACanvas.FillRoundRect(Rect(X, P.Bounds.Top + Sc(2), X + 1, P.Bounds.Bottom - Sc(2)), 0,
      PPGBlendColor(C.Panel, C.Text, 0.15), 255);
  if P.State = rgsCollapsed then
  begin
    R := P.Bounds;
    InflateRect(R, -Sc(2), 0);
    Hot := (FHot.Part = rpGroup) and (FHot.View = View) and (FHot.Index = G);
    Down := ((FGroupPopup <> nil) and FGroupPopup.IsOpen and (FGroupPopup.View.SingleGroup = P.Group)) or
      ((FDown.Part = rpGroup) and (FDown.View = View) and (FDown.Index = G));
    PaintFace(ACanvas, R, Hot, Down, False, En, C, TextCol);
    IconR := Rect(R.Left, R.Top + Sc(PadX), R.Right, R.Top + Sc(PadX) + Sc(IconLarge));
    if (FLargeImages <> nil) and (P.Group.ImageIndex >= 0) and (P.Group.ImageIndex < FLargeImages.Count) then
      ACanvas.DrawImage(FLargeImages, P.Group.ImageIndex, (IconR.Left + IconR.Right - FLargeImages.Width) div 2,
        IconR.Top, En)
    else if (Images <> nil) and (P.Group.ImageIndex >= 0) and (P.Group.ImageIndex < Images.Count) then
      ACanvas.DrawImage(Images, P.Group.ImageIndex, (IconR.Left + IconR.Right - Images.Width) div 2,
        (IconR.Top + IconR.Bottom - Images.Height) div 2, En)
    else if (P.Group.IconChar = 0) or not PPGDrawIconChar(ACanvas, IconR, P.Group.IconChar, TextCol,
      Sc(IconLarge)) then
    begin
      // Ohne eigenes Symbol: das erste Item mit Symbol, sonst ein Kasten
      Dummy := nil;
      for I := 0 to P.Group.Items.Count - 1 do
        if P.Group.Items[I].Visible and P.Group.Items[I].HasIcon(Images, FLargeImages) then
        begin
          Dummy := P.Group.Items[I];
          Break;
        end;
      if Dummy <> nil then
        PaintIcon(ACanvas, Dummy, IconR, True, TextCol, En)
      else
        ACanvas.FrameRoundRect(Rect((IconR.Left + IconR.Right) div 2 - Sc(10), IconR.Top + Sc(6),
          (IconR.Left + IconR.Right) div 2 + Sc(10), IconR.Bottom - Sc(6)), Sc(3), 1, TextCol, 255);
    end;
    SplitCaption(P.Group.Caption, L1, L2);
    TextR := Rect(R.Left + Sc(2), IconR.Bottom + Sc(2), R.Right - Sc(2), IconR.Bottom + Sc(2) + Th);
    ACanvas.DrawText(TextR, L1, Font, TextCol, DT_SINGLELINE or DT_CENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
    OffsetRect(TextR, 0, Th);
    if L2 <> '' then
    begin
      X := (R.Left + R.Right + TextWidth(L2)) div 2;
      ACanvas.DrawText(Rect(TextR.Left, TextR.Top, X - Sc(ArrowW) div 2, TextR.Bottom), L2, Font, TextCol,
        DT_SINGLELINE or DT_RIGHT or DT_NOPREFIX or DT_END_ELLIPSIS);
      PaintArrow(ACanvas, Rect(X - Sc(ArrowW) div 2, TextR.Top, X + Sc(ArrowW), TextR.Bottom), TextCol);
    end
    else
      PaintArrow(ACanvas, TextR, TextCol);
    Exit;
  end;
  for I := 0 to High(P.Items) do
    PaintItem(ACanvas, View, G, I, C);
  // Beschriftung und Startknopf fuer den Dialog
  TextR := P.CaptionRect;
  if not IsRectEmpty(P.LauncherRect) then
    if UseRightToLeftAlignment then
      TextR.Left := P.LauncherRect.Right
    else
      TextR.Right := P.LauncherRect.Left;
  ACanvas.DrawText(TextR, P.Group.Caption, Font, IfThen(En, C.TextSecondary, C.TextDisabled),
    DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
  if not IsRectEmpty(P.LauncherRect) then
  begin
    R := P.LauncherRect;
    InflateRect(R, -Sc(3), -Sc(2));
    Hot := (FHot.Part = rpLauncher) and (FHot.View = View) and (FHot.Index = G);
    Down := (FDown.Part = rpLauncher) and (FDown.View = View) and (FDown.Index = G);
    PaintFace(ACanvas, R, Hot, Down, False, En, C, TextCol);
    if not Hot and not Down then
      TextCol := IfThen(En, C.TextSecondary, C.TextDisabled);
    // Pfeil nach rechts unten in einer Ecke
    X := Sc(4);
    ACanvas.DrawPolyline([Point(R.Left + Sc(3), R.Top + Sc(3) + X), Point(R.Left + Sc(3), R.Top + Sc(3)),
      Point(R.Left + Sc(3) + X, R.Top + Sc(3))], 1, TextCol, 255);
    ACanvas.DrawPolyline([Point(R.Left + Sc(5), R.Top + Sc(5)), Point(R.Right - Sc(4), R.Bottom - Sc(4))],
      1, TextCol, 255);
    ACanvas.DrawPolyline([Point(R.Right - Sc(4) - X, R.Bottom - Sc(4)), Point(R.Right - Sc(4), R.Bottom - Sc(4)),
      Point(R.Right - Sc(4), R.Bottom - Sc(4) - X)], 1, TextCol, 255);
  end;
end;

procedure TPPGCustomRibbon.PaintView(const ACanvas: IPPGCanvas; View: TPPGRibbonView;
  const C: TPPGRibbonColors);
var
  G: Integer;
begin
  if View = nil then
    Exit;
  for G := 0 to View.GroupCount - 1 do
    PaintGroup(ACanvas, View, G, C);
end;

procedure TPPGCustomRibbon.PaintHead(const ACanvas: IPPGCanvas; const C: TPPGRibbonColors);
var
  I, J, Rad: Integer;
  R, Bar: TRect;
  Hot, Down, Active, En: Boolean;
  TextCol, Ctx: TColor;
  Cap: string;
  It, Src: TPPGRibbonItem;
begin
  En := Enabled;
  Rad := Sc(4);
  // Schnellzugriff
  for I := 0 to High(FQatRects) do
  begin
    R := FQatRects[I];
    if IsRectEmpty(R) then
      Continue;
    It := FQuickAccess[I];
    if It.Kind = rikSeparator then
    begin
      J := (R.Left + R.Right) div 2;
      ACanvas.FillRoundRect(Rect(J, R.Top + Sc(4), J + 1, R.Bottom - Sc(4)), 0,
        PPGBlendColor(C.Back, C.Text, 0.25), 255);
      Continue;
    end;
    Src := QuickSource(It);
    if Src = nil then
      Src := It;
    Hot := (FHot.Part = rpQuickItem) and (FHot.Index = I);
    Down := (FDown.Part = rpQuickItem) and (FDown.Index = I);
    PaintFace(ACanvas, R, Hot and Src.Enabled and En, Down, (Src.Kind = rikCheck) and Src.Down,
      Src.Enabled and En, C, TextCol);
    PaintIcon(ACanvas, Src, R, False, TextCol, Src.Enabled and En);
  end;
  if not IsRectEmpty(FQatCustomizeRect) then
  begin
    Hot := FHot.Part = rpQuickCustomize;
    PaintFace(ACanvas, FQatCustomizeRect, Hot, FDown.Part = rpQuickCustomize, False, En, C, TextCol);
    PaintArrow(ACanvas, FQatCustomizeRect, TextCol);
  end;
  // Kontext-Registerkarten: farbige Leiste ueber zusammenhaengenden Karten
  for I := 0 to FTabs.Count - 1 do
  begin
    if IsRectEmpty(FTabRects[I]) or not FTabs[I].IsContextual then
      Continue;
    Ctx := FTabs[I].ContextColor;
    if (Ctx = clNone) or C.HC then
      Ctx := C.Accent
    else
      Ctx := PPGColorToRGB(Ctx);
    R := FTabRects[I];
    ACanvas.FillRoundRect(Rect(R.Left, FTabRowRect.Top, R.Right + Sc(1), R.Bottom), 0, Ctx, 26);
    Bar := Rect(R.Left, FTabRowRect.Top, R.Right + Sc(1), FTabRowRect.Top + Sc(3));
    ACanvas.FillRoundRect(Bar, 0, Ctx, 255);
  end;
  // Datei-Button
  if not IsRectEmpty(FAppRect) then
  begin
    Hot := FHot.Part = rpAppButton;
    Down := (FDown.Part = rpAppButton) or FBackstageVisible;
    R := FAppRect;
    InflateRect(R, 0, -Sc(2));
    if C.HC then
      ACanvas.FillRoundRect(R, 0, C.Accent, 255)
    else if not En then
      ACanvas.FillRoundRect(R, Rad, PPGBlendColor(C.Back, C.TextDisabled, 0.3), 255)
    else if Down then
      ACanvas.FillRoundRect(R, Rad, Tokens.AccentPressed, 255)
    else if Hot then
      ACanvas.FillRoundRect(R, Rad, Tokens.AccentHover, 255)
    else
      ACanvas.FillRoundRect(R, Rad, C.Accent, 255);
    Cap := FApplicationButtonCaption;
    if Cap = '' then
      Cap := PPGStr(@SPPGRibbonFile);
    ACanvas.DrawText(R, StripHotkey(Cap), Font, IfThen(En, C.OnAccent, PPGBlendColor(C.Back, C.TextDisabled, 0.9)),
      DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
  end;
  // Registerkarten
  for I := 0 to FTabs.Count - 1 do
  begin
    R := FTabRects[I];
    if IsRectEmpty(R) then
      Continue;
    Active := FTabs[I] = ActiveTab;
    Hot := (FHot.Part = rpTab) and (FHot.Index = I);
    if Active and not FMinimized then
    begin
      // gewaehlte Karte haengt mit dem Band zusammen
      ACanvas.FillRoundRect(Rect(R.Left, R.Top, R.Right, R.Bottom + Rad), Rad, C.Panel, 255);
      ACanvas.FrameRoundRect(Rect(R.Left, R.Top, R.Right, R.Bottom + Rad + Sc(2)), Rad, 1, C.Stroke, 255);
      ACanvas.FillRoundRect(Rect(R.Left + 1, R.Bottom - Sc(1), R.Right - 1, R.Bottom + Rad + Sc(2)), 0, C.Panel, 255);
    end
    else if Hot and En then
      ACanvas.FillRoundRect(Rect(R.Left, R.Top + Sc(2), R.Right, R.Bottom - Sc(2)), Rad, C.Text, 16);
    if (FPanelPopup <> nil) and FPanelPopup.IsOpen and (FPopupTab = I) then
      ACanvas.FillRoundRect(Rect(R.Left, R.Top + Sc(2), R.Right, R.Bottom - Sc(2)), Rad, C.Text, 24);
    if not En then
      TextCol := C.TextDisabled
    else if FTabs[I].IsContextual and not C.HC then
    begin
      Ctx := FTabs[I].ContextColor;
      if Ctx = clNone then
        Ctx := C.Accent
      else
        Ctx := PPGColorToRGB(Ctx);
      TextCol := PPGBlendColor(Ctx, C.Text, 0.35);
    end
    else
      TextCol := C.Text;
    ACanvas.DrawText(R, StripHotkey(FTabs[I].Caption), Font, TextCol,
      DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
    if Active and not FMinimized and not C.HC then
      ACanvas.FillRoundRect(Rect((R.Left + R.Right) div 2 - Sc(10), R.Bottom - Sc(4),
        (R.Left + R.Right) div 2 + Sc(10), R.Bottom - Sc(2)), Sc(1), C.Accent, 255)
    else if Active and C.HC and not FMinimized then
      ACanvas.FrameRoundRect(R, 0, 1, C.Text, 255);
  end;
  // Einklapp-Knopf
  if not IsRectEmpty(FMinimizeRect) then
  begin
    Hot := FHot.Part = rpMinimize;
    PaintFace(ACanvas, FMinimizeRect, Hot, FDown.Part = rpMinimize, False, En, C, TextCol);
    if FMinimized then
      PaintArrow(ACanvas, FMinimizeRect, TextCol)
    else if not PPGDrawIcon(ACanvas, FMinimizeRect, igChevronUp, TextCol, Sc(10)) then
      PaintArrow(ACanvas, FMinimizeRect, TextCol);
  end;
end;

procedure TPPGCustomRibbon.PaintKeyboardFocus(const ACanvas: IPPGCanvas; const C: TPPGRibbonColors);
var
  E: TArray<TPPGRibbonElement>;
begin
  if not FNavMode then
    Exit;
  E := Elements;
  if (FNavIndex >= 0) and (FNavIndex <= High(E)) and not IsRectEmpty(E[FNavIndex].Rect) then
    ACanvas.FrameRoundRect(E[FNavIndex].Rect, Sc(4), Sc(2), PPGColorToRGB(EffectiveAppearance.FocusColor), 255);
end;

procedure TPPGCustomRibbon.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  C: TPPGRibbonColors;
begin
  EnsureLayout;
  C := RibbonColors;
  ACanvas.FillRoundRect(ClientR, 0, C.Back, 255);
  if not IsRectEmpty(FPanelRect) then
  begin
    ACanvas.FillRoundRect(FPanelRect, 0, C.Panel, 255);
    ACanvas.FillRoundRect(Rect(FPanelRect.Left, FPanelRect.Top, FPanelRect.Right, FPanelRect.Top + 1), 0,
      C.Stroke, 255);
    ACanvas.FillRoundRect(Rect(FPanelRect.Left, FPanelRect.Bottom - 1, FPanelRect.Right, FPanelRect.Bottom),
      0, C.Stroke, 255);
  end
  else
    ACanvas.FillRoundRect(Rect(ClientR.Left, FTabRowRect.Bottom - 1, ClientR.Right, FTabRowRect.Bottom), 0,
      C.Stroke, 255);
  PaintHead(ACanvas, C);
  if not FMinimized then
    PaintView(ACanvas, FMainView, C);
  PaintKeyboardFocus(ACanvas, C);
end;

{ ---- Maus ---- }

function TPPGCustomRibbon.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGCustomRibbon.IsDown: Boolean;
begin
  Result := False;
end;

procedure TPPGCustomRibbon.SetHot(const Hit: TPPGRibbonHit);
var
  Old: TPPGRibbonHit;
begin
  if SameHit(Hit, FHot) then
    Exit;
  Old := FHot;
  FHot := Hit;
  if (Old.View = nil) or (Old.View = FMainView) or (Hit.View = nil) or (Hit.View = FMainView) then
    Invalidate;
  if (Old.View <> nil) and (Old.View <> FMainView) and (Old.View.Host <> nil) then
    Old.View.Host.Invalidate;
  if (Hit.View <> nil) and (Hit.View <> FMainView) and (Hit.View.Host <> nil) then
    Hit.View.Host.Invalidate;
  Application.CancelHint;
end;

procedure TPPGCustomRibbon.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Hit: TPPGRibbonHit;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if FKeyTipLevel > 0 then
    HideKeyTips;
  if FNavMode then
    LeaveKeyboardNavigation;
  if (Button <> mbLeft) or not Enabled then
    Exit;
  Hit := HitTest(X, Y);
  if csDesigning in ComponentState then
  begin
    if Hit.Part = rpTab then
      UserSelectTab(Hit.Index);
    Exit;
  end;
  // Doppelklick auf eine Registerkarte klappt das Band ein bzw. aus
  if (ssDouble in Shift) and (Hit.Part = rpTab) then
  begin
    UserToggleMinimized;
    Exit;
  end;
  // Klick ins Ribbon schliesst offene Popups; Ausnahmen: die Registerkarte
  // (oeffnet bzw. schliesst das Popup des eingeklappten Bands) und die
  // geschrumpfte Gruppe, deren Popup offen ist (zweiter Klick schliesst es)
  if Hit.Part = rpTab then
    CloseGroupPopup
  else if not ((Hit.Part = rpGroup) and (FGroupPopup <> nil) and FGroupPopup.IsOpen and
    (Hit.View <> nil) and (FGroupPopup.View.SingleGroup = Hit.View.Groups[Hit.Index].Group)) then
    ClosePopups;
  HitMouseDown(Hit, Shift);
end;

procedure TPPGCustomRibbon.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if csDesigning in ComponentState then
    Exit;
  SetHot(HitTest(X, Y));
end;

procedure TPPGCustomRibbon.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if (Button <> mbLeft) or (csDesigning in ComponentState) then
    Exit;
  HitMouseUp(HitTest(X, Y));
end;

procedure TPPGCustomRibbon.ViewMouseDown(View: TPPGRibbonView; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  if FKeyTipLevel > 0 then
    HideKeyTips;
  if (Button <> mbLeft) or not Enabled then
    Exit;
  HitMouseDown(ViewHitTest(View, X, Y), Shift);
end;

procedure TPPGCustomRibbon.ViewMouseMove(View: TPPGRibbonView; X, Y: Integer);
begin
  SetHot(ViewHitTest(View, X, Y));
end;

procedure TPPGCustomRibbon.ViewMouseUp(View: TPPGRibbonView; Button: TMouseButton; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;
  HitMouseUp(ViewHitTest(View, X, Y));
end;

procedure TPPGCustomRibbon.HitMouseDown(const Hit: TPPGRibbonHit; Shift: TShiftState);
var
  It: TPPGRibbonItem;
begin
  FDown := Hit;
  Invalidate;
  if (Hit.View <> nil) and (Hit.View.Host <> nil) and (Hit.View.Host <> Self) then
    Hit.View.Host.Invalidate;
  It := HitItem(Hit);
  // Aufklappen beim Druecken (wie Windows): Menues, Popups, Registerkarten
  case Hit.Part of
    rpTab:
      begin
        FDown := NoHit;
        UserSelectTab(Hit.Index);
      end;
    rpItemArrow, rpGroup, rpGalleryMore, rpQuickCustomize:
      begin
        FDown := NoHit;
        ActivateHit(Hit, False);
      end;
    rpItem:
      if (It <> nil) and (It.Kind = rikButton) and (It.DropDownMenu <> nil) and It.Enabled then
      begin
        FDown := NoHit;
        ActivateHit(Hit, False);
      end;
    rpNone:
      FDown := NoHit;
  end;
end;

procedure TPPGCustomRibbon.HitMouseUp(const Hit: TPPGRibbonHit);
var
  D: TPPGRibbonHit;
begin
  D := FDown;
  FDown := NoHit;
  Invalidate;
  if (D.View <> nil) and (D.View.Host <> nil) and (D.View.Host <> Self) then
    D.View.Host.Invalidate;
  if (D.Part = rpNone) or not SameHit(D, Hit) then
    Exit;
  ActivateHit(Hit, False);
end;

procedure TPPGCustomRibbon.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if (FHot.Part <> rpNone) and ((FHot.View = nil) or (FHot.View = FMainView)) then
    SetHot(NoHit);
end;

function TPPGCustomRibbon.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
var
  P: TPoint;
  Hit: TPPGRibbonHit;
  It: TPPGRibbonItem;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if Result or not HandleAllocated then
    Exit;
  P := ScreenToClient(MousePos);
  Hit := HitTest(P.X, P.Y);
  It := HitItem(Hit);
  // Rad ueber einer Galerie blaettert ihre Zeilen
  if (It <> nil) and (It.Kind = rikGallery) then
  begin
    if WheelDelta > 0 then
      It.GalleryTopRow := Max(0, It.GalleryTopRow - 1)
    else
      It.GalleryTopRow := It.GalleryTopRow + 1;
    Invalidate;
    Result := True;
  end;
end;

procedure TPPGCustomRibbon.CMDesignHitTest(var Message: TCMDesignHitTest);
begin
  // Im Designer: Klicks auf Registerkarten wechseln die Karte
  if HitTest(Message.XPos, Message.YPos).Part = rpTab then
    Message.Result := 1
  else
    Message.Result := 0;
end;

procedure TPPGCustomRibbon.DesignerModified;
var
  Form: TCustomForm;
begin
  if not (csDesigning in ComponentState) then
    Exit;
  Form := GetParentForm(Self);
  if (Form <> nil) and (Form.Designer <> nil) then
    Form.Designer.Modified;
end;

{ ---- Aktionen ---- }

procedure TPPGCustomRibbon.ActivateHit(const Hit: TPPGRibbonHit; ByKeyboard: Boolean);
var
  It: TPPGRibbonItem;
  R: TRect;
begin
  It := HitItem(Hit);
  case Hit.Part of
    rpAppButton:
      ClickApplicationButton;
    rpQuickItem:
      ClickQuickItem(Hit.Index);
    rpQuickCustomize:
      begin
        R := HitScreenRect(Hit);
        ShowContextMenuAt(Hit, Point(R.Left, R.Bottom));
      end;
    rpTab:
      UserSelectTab(Hit.Index);
    rpMinimize:
      UserToggleMinimized;
    rpGroup:
      if (Hit.View <> nil) and (Hit.Index < Hit.View.GroupCount) then
      begin
        if (FGroupPopup <> nil) and FGroupPopup.IsOpen and
          (FGroupPopup.View.SingleGroup = Hit.View.Groups[Hit.Index].Group) then
          CloseGroupPopup
        else
          OpenGroupPopup(Hit.View, Hit.Index);
      end;
    rpLauncher:
      if (Hit.View <> nil) and (Hit.Index < Hit.View.GroupCount) then
      begin
        ClosePopups;
        if Assigned(FOnLauncherClick) then
          FOnLauncherClick(Self, Hit.View.Groups[Hit.Index].Group);
      end;
    rpItem:
      if (It <> nil) and It.Enabled and Enabled then
      begin
        if (It.Kind = rikGallery) then
          OpenGallery(It)
        else if (It.Kind = rikButton) and (It.DropDownMenu <> nil) then
        begin
          R := HitScreenRect(Hit);
          if Assigned(It.OnClick) or (It.Action <> nil) then
            ClickItem(It);
          ShowItemMenu(It, R);
        end
        else if It.Kind = rikControl then
        begin
          if (It.Control is TWinControl) and TWinControl(It.Control).CanFocus then
            TWinControl(It.Control).SetFocus;
        end
        else
          ClickItem(It);
      end;
    rpItemArrow:
      if (It <> nil) and It.Enabled and Enabled then
        ShowItemMenu(It, HitScreenRect(Hit));
    rpGalleryTile:
      if (It <> nil) and It.Enabled and Enabled then
        SelectGalleryItem(It, Hit.Tile);
    rpGalleryUp:
      if It <> nil then
      begin
        It.GalleryTopRow := Max(0, It.GalleryTopRow - 1);
        Invalidate;
        if (Hit.View <> nil) and (Hit.View.Host <> Self) then
          Hit.View.Host.Invalidate;
      end;
    rpGalleryDown:
      if It <> nil then
      begin
        It.GalleryTopRow := It.GalleryTopRow + 1;
        Invalidate;
        if (Hit.View <> nil) and (Hit.View.Host <> Self) then
          Hit.View.Host.Invalidate;
      end;
    rpGalleryMore:
      if (It <> nil) and It.Enabled and Enabled then
        OpenGallery(It);
  end;
end;

procedure TPPGCustomRibbon.ClickItem(Item: TPPGRibbonItem);
begin
  if (Item = nil) or (Item.Kind in [rikSeparator, rikControl]) or not Item.Enabled or not Enabled then
    Exit;
  // Popups schliessen, bevor Anwender-Code laeuft (er darf Fenster oeffnen)
  ClosePopups;
  if Item.Kind = rikCheck then
    // AutoCheck-Actions schalten beim Ausfuehren selbst um
    if not ((Item.Action is TCustomAction) and TCustomAction(Item.Action).AutoCheck) then
    begin
      if not (Item.Down and (Item.GroupIndex <> 0)) then
        Item.Down := not Item.Down;
      if Item.Action is TCustomAction then
        TCustomAction(Item.Action).Checked := Item.Down;
    end;
  // Wie TControl.Click: eigenes OnClick vor der Action, sonst Action.Execute
  if Assigned(Item.OnClick) and (Item.Action <> nil) and not SameMethod(Item.OnClick, Item.Action.OnExecute) then
    Item.OnClick(Item)
  else if Item.ActionLink <> nil then
    Item.ActionLink.Execute(Self)
  else if Assigned(Item.OnClick) then
    Item.OnClick(Item);
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, Item);
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
end;

procedure TPPGCustomRibbon.ClickQuickItem(Index: Integer);
var
  Src: TPPGRibbonItem;
begin
  if (Index < 0) or (Index >= FQuickAccess.Count) then
    Exit;
  Src := QuickSource(FQuickAccess[Index]);
  if Src <> nil then
  begin
    if Src.Kind = rikGallery then
      OpenGallery(Src)
    else
      ClickItem(Src);
  end
  else
    ClickItem(FQuickAccess[Index]);
end;

procedure TPPGCustomRibbon.SelectGalleryItem(Item: TPPGRibbonItem; Index: Integer);
begin
  if (Item = nil) or (Index < 0) or (Index >= Item.GalleryTotal) then
    Exit;
  ClosePopups;
  Item.GalleryIndex := Index;
  if Assigned(FOnGalleryClick) then
    FOnGalleryClick(Self, Item, Index);
  NotifyAccessibility(EVENT_OBJECT_SELECTION);
end;

procedure TPPGCustomRibbon.ShowItemMenu(Item: TPPGRibbonItem; const ScreenR: TRect);
var
  M: TPopupMenu;
begin
  M := Item.DropDownMenu;
  if M = nil then
    Exit;
  // Menue des Bands schliesst die Popups nicht (es kann aus einem Popup kommen)
  Inc(FBusy);
  try
    M.PopupComponent := Self;
    M.BiDiMode := BiDiMode;
    if M is TPPGPopupMenu then
      TPPGPopupMenu(M).PopupAtRect(ScreenR)
    else if UseRightToLeftAlignment then
      M.Popup(ScreenR.Right, ScreenR.Bottom)
    else
      M.Popup(ScreenR.Left, ScreenR.Bottom);
  finally
    Dec(FBusy);
  end;
  FDown := NoHit;
  Invalidate;
end;

procedure TPPGCustomRibbon.ClickApplicationButton;
var
  P: TPoint;
begin
  ClosePopups;
  if Assigned(FOnApplicationButtonClick) then
    FOnApplicationButtonClick(Self);
  if FBackstage <> nil then
    ShowBackstage
  else if (FApplicationMenu <> nil) and HandleAllocated then
  begin
    EnsureLayout;
    FApplicationMenu.PopupComponent := Self;
    if FApplicationMenu is TPPGPopupMenu then
      TPPGPopupMenu(FApplicationMenu).PopupAtRect(PointsRect(ClientToScreen(FAppRect.TopLeft),
        ClientToScreen(FAppRect.BottomRight)))
    else
    begin
      P := ClientToScreen(Point(FAppRect.Left, FAppRect.Bottom));
      FApplicationMenu.Popup(P.X, P.Y);
    end;
  end;
end;

procedure TPPGCustomRibbon.ShowBackstage;
var
  P: TWinControl;
begin
  if (FBackstage = nil) or FBackstageVisible then
    Exit;
  P := FBackstage.Parent;
  if P = nil then
    P := Parent;
  if P = nil then
    Exit;
  ClosePopups;
  FBackstageAlign := FBackstage.Align;
  FBackstageAnchors := FBackstage.Anchors;
  FBackstageBounds := FBackstage.BoundsRect;
  FBackstageWasVisible := FBackstage.Visible;
  FBackstageVisible := True;
  if FBackstage.Parent <> P then
    FBackstage.Parent := P;
  FBackstage.Align := alNone;
  FBackstage.SetBounds(0, 0, P.ClientWidth, P.ClientHeight);
  FBackstage.Anchors := [akLeft, akTop, akRight, akBottom];
  FBackstage.Visible := True;
  FBackstage.BringToFront;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
  if Assigned(FOnBackstageChange) then
    FOnBackstageChange(Self);
end;

procedure TPPGCustomRibbon.HideBackstage;
begin
  if not FBackstageVisible then
    Exit;
  FBackstageVisible := False;
  if FBackstage <> nil then
  begin
    FBackstage.Visible := False;
    FBackstage.Anchors := FBackstageAnchors;
    FBackstage.Align := FBackstageAlign;
    if FBackstageAlign = alNone then
      FBackstage.BoundsRect := FBackstageBounds;
  end;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
  if Assigned(FOnBackstageChange) then
    FOnBackstageChange(Self);
end;

procedure TPPGCustomRibbon.UserSelectTab(Index: Integer);
var
  Allow: Boolean;
begin
  if (Index < 0) or (Index >= FTabs.Count) or not FTabs[Index].Visible then
    Exit;
  if FMinimized and not (csDesigning in ComponentState) then
  begin
    // Eingeklappt: Klick oeffnet die Karte als Popup (zweiter Klick schliesst)
    if (FPanelPopup <> nil) and FPanelPopup.IsOpen and (FPopupTab = Index) then
    begin
      ClosePanelPopup;
      Exit;
    end;
  end;
  if FTabs[Index] <> ActiveTab then
  begin
    Allow := True;
    if Assigned(FOnTabChanging) then
      FOnTabChanging(Self, FTabs[Index], Allow);
    if not Allow then
      Exit;
    FTabIndex := Index;
    ClosePopups;
    LayoutChanged;
    DesignerModified;
    NotifyAccessibilityChild(EVENT_OBJECT_SELECTION, AccSelectedChild);
    NotifyAccessibility(EVENT_OBJECT_REORDER);
    if Assigned(FOnTabChange) then
      FOnTabChange(Self);
  end;
  if FMinimized and not (csDesigning in ComponentState) then
    OpenTabPopup(Index);
end;

procedure TPPGCustomRibbon.UserToggleMinimized;
begin
  Minimized := not FMinimized;
  if Assigned(FOnMinimizedChange) then
    FOnMinimizedChange(Self);
end;

{ ---- Popups ---- }

procedure TPPGCustomRibbon.ReparentToPopup(Popup: TPPGRibbonPanelPopup);
var
  G, I: Integer;
  C: TControl;
begin
  EnsureView(Popup.View);
  for G := 0 to Popup.View.GroupCount - 1 do
    for I := 0 to High(Popup.View.Groups[G].Items) do
    begin
      C := Popup.View.Groups[G].Items[I].Control;
      if (C <> nil) and (Popup.View.Groups[G].Items[I].Kind = rikControl) then
        C.Parent := Popup;
    end;
end;

procedure TPPGCustomRibbon.ReturnControls(Popup: TPPGRibbonPanelPopup);
var
  I: Integer;
  C: TControl;
begin
  if Popup = nil then
    Exit;
  for I := Popup.ControlCount - 1 downto 0 do
  begin
    C := Popup.Controls[I];
    if csDestroying in ComponentState then
      C.Parent := nil
    else
    begin
      if not (csDesigning in ComponentState) then
        C.Visible := False;
      C.Parent := Self;
    end;
  end;
end;

procedure TPPGCustomRibbon.OpenTabPopup(Index: Integer);
var
  R: TRect;
  P: TPoint;
begin
  if not HandleAllocated or (Index < 0) or (Index >= FTabs.Count) then
    Exit;
  CloseGroupPopup;
  CloseGalleryPopup;
  if FPanelPopup = nil then
    FPanelPopup := TPPGRibbonPanelPopup.CreateFor(Self);
  if FPanelPopup.IsOpen then
  begin
    ReturnControls(FPanelPopup);
    FPanelPopup.ClosePopup;
  end;
  FPanelPopup.SyncFrom(Self);
  FPopupTab := Index;
  EnsureLayout;
  FPanelPopup.Width := Width;
  FPanelPopup.Height := PanelHeight;
  BuildView(FPanelPopup.View, FTabs[Index], nil, Rect(0, 0, Width, PanelHeight), FPanelPopup);
  ReparentToPopup(FPanelPopup);
  P := ClientToScreen(Point(0, FTabRowRect.Bottom));
  R := Rect(P.X, P.Y, P.X + Width, P.Y + PanelHeight);
  FPanelPopup.PopupAt(R, ppsBelow, 0);
  ApplyControlLayout;
  Invalidate;
end;

procedure TPPGCustomRibbon.OpenGroupPopup(View: TPPGRibbonView; G: Integer);
var
  Grp: TPPGRibbonGroup;
  W, H: Integer;
  Anchor: TRect;
  Pl: TPPGPlacement;
  Tmp: TPPGRibbonView;
begin
  if not HandleAllocated or (View = nil) or (G < 0) or (G >= View.GroupCount) then
    Exit;
  Grp := View.Groups[G].Group;
  CloseGalleryPopup;
  CloseGroupPopup;
  if FGroupPopup = nil then
    FGroupPopup := TPPGRibbonPanelPopup.CreateFor(Self);
  FGroupPopup.SyncFrom(Self);
  // Breite der voll aufgeklappten Gruppe
  Tmp := TPPGRibbonView.Create;
  try
    BuildView(Tmp, View.Tab, Grp, Rect(0, 0, 10000, PanelHeight), FGroupPopup);
    if Tmp.GroupCount > 0 then
      W := RectW(Tmp.Groups[0].Bounds) + 2 * Sc(PanelPad)
    else
      W := Sc(100);
  finally
    Tmp.Free;
  end;
  H := PanelHeight;
  FGroupPopup.Width := W;
  FGroupPopup.Height := H;
  BuildView(FGroupPopup.View, View.Tab, Grp, Rect(0, 0, W, H), FGroupPopup);
  ReparentToPopup(FGroupPopup);
  Anchor := HitScreenRect(MakeHit(rpGroup, View, G, -1, -1));
  Pl := PPGPlacePopup(Anchor, W, H, ppsBelow, FGroupPopup.MonitorWorkArea(Anchor),
    UseRightToLeftAlignment, False);
  FGroupPopup.PopupAt(Pl.Bounds, Pl.Side, 0);
  ApplyControlLayout;
  Invalidate;
  if View.Host <> Self then
    View.Host.Invalidate;
end;

procedure TPPGCustomRibbon.OpenGallery(Item: TPPGRibbonItem);
var
  Hit: TPPGRibbonHit;
  Anchor: TRect;
  G, I, Cols, Rows, W, H, P: Integer;
  View: TPPGRibbonView;
  Pl: TPPGPlacement;
begin
  if (Item = nil) or (Item.Kind <> rikGallery) or not HandleAllocated then
    Exit;
  CloseGalleryPopup;
  // Anker: das Item in der Ansicht, in der es sichtbar ist
  Hit := NoHit;
  View := nil;
  if (FGroupPopup <> nil) and FGroupPopup.IsOpen then
    View := FGroupPopup.View
  else if (FPanelPopup <> nil) and FPanelPopup.IsOpen then
    View := FPanelPopup.View
  else if not FMinimized then
    View := FMainView;
  if View <> nil then
  begin
    EnsureView(View);
    for G := 0 to View.GroupCount - 1 do
      for I := 0 to High(View.Groups[G].Items) do
        if (View.Groups[G].Items[I] = Item) and (View.Groups[G].State <> rgsCollapsed) then
          Hit := MakeHit(rpItem, View, G, I, -1);
  end;
  if Hit.Part <> rpNone then
    Anchor := HitScreenRect(Hit)
  else
    Anchor := PointsRect(ClientToScreen(Point(0, FTabRowRect.Bottom)), ClientToScreen(Point(Width, FTabRowRect.Bottom)));
  if FGalleryPopup = nil then
    FGalleryPopup := TPPGRibbonGalleryPopup.CreateFor(Self);
  FGalleryPopup.SyncFrom(Self);
  FGalleryPopup.FItem := Item;
  Cols := Item.GalleryPopupColumns;
  if Cols = 0 then
    Cols := Item.GalleryColumns + 1;
  FGalleryPopup.FCols := Max(1, Cols);
  FGalleryPopup.FHot := -1;
  FGalleryPopup.FFocus := Item.GalleryIndex;
  FGalleryPopup.FTopRow := 0;
  P := Sc(4);
  Rows := Max(1, Min(6, (Item.GalleryTotal + Cols - 1) div Cols));
  W := FGalleryPopup.FCols * FGalleryPopup.TileWidth + 2 * P + Sc(8);
  H := Rows * FGalleryPopup.TileHeight + 2 * P;
  if Hit.Part <> rpNone then
    // ueber der Galerie in der Leiste, links buendig
    Anchor := Rect(Anchor.Left, Anchor.Top, Anchor.Left, Anchor.Top);
  Pl := PPGPlacePopup(Anchor, W, H, ppsBelow, FGalleryPopup.MonitorWorkArea(Anchor),
    UseRightToLeftAlignment, True);
  FGalleryPopup.PopupAt(Pl.Bounds, Pl.Side, 0);
  FGalleryPopup.MakeVisible(Item.GalleryIndex);
  FGalleryPopup.NotifyAccessibility(EVENT_OBJECT_FOCUS);
end;

procedure TPPGCustomRibbon.ClosePanelPopup;
begin
  CloseGroupPopup;
  CloseGalleryPopup;
  if (FPanelPopup <> nil) and FPanelPopup.IsOpen then
  begin
    ReturnControls(FPanelPopup);
    FPanelPopup.ClosePopup;
    FPopupTab := -1;
    if (FHot.View = FPanelPopup.View) then
      FHot := NoHit;
    RequestControlLayout;
    Invalidate;
  end;
end;

procedure TPPGCustomRibbon.CloseGroupPopup;
begin
  CloseGalleryPopup;
  if (FGroupPopup <> nil) and FGroupPopup.IsOpen then
  begin
    ReturnControls(FGroupPopup);
    FGroupPopup.ClosePopup;
    if FHot.View = FGroupPopup.View then
      FHot := NoHit;
    RequestControlLayout;
    Invalidate;
    if (FPanelPopup <> nil) and FPanelPopup.IsOpen then
      FPanelPopup.Invalidate;
  end;
end;

procedure TPPGCustomRibbon.CloseGalleryPopup;
begin
  if (FGalleryPopup <> nil) and FGalleryPopup.IsOpen then
  begin
    FGalleryPopup.ClosePopup;
    FGalleryPopup.FItem := nil;
    Invalidate;
  end;
end;

procedure TPPGCustomRibbon.ClosePopups;
begin
  CloseGalleryPopup;
  CloseGroupPopup;
  ClosePanelPopup;
end;

function TPPGCustomRibbon.InPopup(Wnd: HWND): Boolean;

  function Inside(P: TWinControl): Boolean;
  begin
    Result := (P <> nil) and P.HandleAllocated and IsWindowVisible(P.Handle) and
      ((Wnd = P.Handle) or IsChild(P.Handle, Wnd));
  end;

begin
  Result := Inside(FPanelPopup) or Inside(FGroupPopup) or Inside(FGalleryPopup);
end;

{ ---- Schnellzugriff und Kontextmenue ---- }

function TPPGCustomRibbon.QuickSource(QuickItem: TPPGRibbonItem): TPPGRibbonItem;
var
  T, G, I: Integer;
  It: TPPGRibbonItem;
begin
  Result := nil;
  if QuickItem = nil then
    Exit;
  for T := 0 to FTabs.Count - 1 do
    for G := 0 to FTabs[T].Groups.Count - 1 do
      for I := 0 to FTabs[T].Groups[G].Items.Count - 1 do
      begin
        It := FTabs[T].Groups[G].Items[I];
        if It.Kind in [rikSeparator, rikControl] then
          Continue;
        if (QuickItem.Action <> nil) then
        begin
          if It.Action = QuickItem.Action then
            Exit(It);
        end
        else if (It.Action = nil) and (It.Caption = QuickItem.Caption) and (It.Kind = QuickItem.Kind) and
          (It.IconChar = QuickItem.IconChar) and (It.ImageIndex = QuickItem.ImageIndex) then
          Exit(It);
      end;
end;

function TPPGCustomRibbon.QuickIndexOf(Item: TPPGRibbonItem): Integer;
var
  I: Integer;
begin
  for I := 0 to FQuickAccess.Count - 1 do
    if (FQuickAccess[I] = Item) or (QuickSource(FQuickAccess[I]) = Item) then
      Exit(I);
  Result := -1;
end;

function TPPGCustomRibbon.CanAddToQuickAccess(Item: TPPGRibbonItem): Boolean;
begin
  Result := (Item <> nil) and not (Item.Kind in [rikSeparator, rikControl]) and
    (Item.Collection <> FQuickAccess) and (QuickIndexOf(Item) < 0);
end;

function TPPGCustomRibbon.AddToQuickAccess(Item: TPPGRibbonItem): TPPGRibbonItem;
begin
  Result := nil;
  if not CanAddToQuickAccess(Item) then
    Exit;
  Result := FQuickAccess.Add;
  Result.Assign(Item);
  Result.Size := rsSmall;
  Result.KeyTip := '';
  if Assigned(FOnQuickAccessChange) then
    FOnQuickAccessChange(Self);
end;

procedure TPPGCustomRibbon.RemoveFromQuickAccess(Index: Integer);
begin
  if (Index < 0) or (Index >= FQuickAccess.Count) then
    Exit;
  if FHot.Part = rpQuickItem then
    FHot := NoHit;
  FQuickAccess.Delete(Index);
  if Assigned(FOnQuickAccessChange) then
    FOnQuickAccessChange(Self);
end;

procedure TPPGCustomRibbon.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
var
  Hit: TPPGRibbonHit;
  P: TPoint;
begin
  if (csDesigning in ComponentState) or not FQuickAccessCustomizable then
  begin
    inherited DoContextPopup(MousePos, Handled);
    Exit;
  end;
  if (MousePos.X = -1) and (MousePos.Y = -1) then
    Hit := NoHit
  else
    Hit := HitTest(MousePos.X, MousePos.Y);
  P := ClientToScreen(MousePos);
  if (MousePos.X = -1) and (MousePos.Y = -1) then
    P := ClientToScreen(Point(0, Height));
  ShowContextMenuAt(Hit, P);
  Handled := True;
end;

function TPPGCustomRibbon.PrepareContextMenu(const Hit: TPPGRibbonHit): TPopupMenu;

  function AddItem(const ACaption: string; AOnClick: TNotifyEvent; AEnabled, AChecked: Boolean): TMenuItem;
  begin
    Result := TMenuItem.Create(FContextMenu);
    Result.Caption := ACaption;
    Result.OnClick := AOnClick;
    Result.Enabled := AEnabled;
    Result.Checked := AChecked;
    FContextMenu.Items.Add(Result);
  end;

var
  It: TPPGRibbonItem;
begin
  if FContextMenu = nil then
    FContextMenu := TPPGPopupMenu.Create(nil);
  FContextMenu.Items.Clear;
  FContextHit := Hit;
  It := HitItem(Hit);
  if Hit.Part = rpQuickItem then
    AddItem(PPGStr(@SPPGRibbonRemoveFromQat), ContextRemoveClick, True, False)
  else if (It <> nil) and not (It.Kind in [rikSeparator, rikControl]) then
    AddItem(PPGStr(@SPPGRibbonAddToQat), ContextAddClick, CanAddToQuickAccess(It), False);
  if FContextMenu.Items.Count > 0 then
    AddItem('-', nil, True, False);
  if FQuickAccessPosition = qapAbove then
    AddItem(PPGStr(@SPPGRibbonQatBelow), ContextPositionClick, True, False)
  else
    AddItem(PPGStr(@SPPGRibbonQatAbove), ContextPositionClick, True, False);
  AddItem(PPGStr(@SPPGRibbonMinimize), ContextMinimizeClick, True, FMinimized);
  FContextMenu.BiDiMode := BiDiMode;
  FContextMenu.PopupComponent := Self;
  Result := FContextMenu;
end;

procedure TPPGCustomRibbon.ShowContextMenuAt(const Hit: TPPGRibbonHit; const ScreenPt: TPoint);
begin
  if not HandleAllocated then
    Exit;
  PrepareContextMenu(Hit);
  Inc(FBusy);
  try
    FContextMenu.Popup(ScreenPt.X, ScreenPt.Y);
  finally
    Dec(FBusy);
  end;
end;

procedure TPPGCustomRibbon.ContextAddClick(Sender: TObject);
begin
  AddToQuickAccess(HitItem(FContextHit));
end;

procedure TPPGCustomRibbon.ContextRemoveClick(Sender: TObject);
begin
  if FContextHit.Part = rpQuickItem then
    RemoveFromQuickAccess(FContextHit.Index);
end;

procedure TPPGCustomRibbon.ContextPositionClick(Sender: TObject);
begin
  if FQuickAccessPosition = qapAbove then
    QuickAccessPosition := qapBelow
  else
    QuickAccessPosition := qapAbove;
  if Assigned(FOnQuickAccessChange) then
    FOnQuickAccessChange(Self);
end;

procedure TPPGCustomRibbon.ContextMinimizeClick(Sender: TObject);
begin
  UserToggleMinimized;
end;

{ ---- Tooltips ---- }

function TPPGCustomRibbon.HintFor(const Hit: TPPGRibbonHit; out R: TRect): string;
var
  It: TPPGRibbonItem;
  D: TPPGItemData;
  Col: TColor;
begin
  Result := '';
  R := HitRect(Hit);
  It := HitItem(Hit);
  case Hit.Part of
    rpAppButton:
      if FApplicationButtonCaption <> '' then
        Result := StripHotkey(FApplicationButtonCaption)
      else
        Result := PPGStr(@SPPGRibbonFile);
    rpMinimize:
      if FMinimized then
        Result := PPGStr(@SPPGRibbonExpand)
      else
        Result := PPGStr(@SPPGRibbonMinimize);
    rpQuickCustomize:
      Result := PPGStr(@SPPGRibbonCustomizeQat);
    rpGroup:
      if (Hit.View <> nil) and (Hit.Index < Hit.View.GroupCount) then
        Result := Hit.View.Groups[Hit.Index].Group.Caption;
    rpLauncher:
      if (Hit.View <> nil) and (Hit.Index < Hit.View.GroupCount) then
      begin
        Result := Hit.View.Groups[Hit.Index].Group.LauncherHint;
        if Result = '' then
          Result := Hit.View.Groups[Hit.Index].Group.Caption;
      end;
    rpGalleryUp:
      Result := PPGStr(@SPPGRibbonGalleryUp);
    rpGalleryDown:
      Result := PPGStr(@SPPGRibbonGalleryDown);
    rpGalleryMore:
      Result := PPGStr(@SPPGMoreOptions);
    rpGalleryTile:
      if It <> nil then
      begin
        D.Text := '';
        D.Detail := '';
        D.Badge := '';
        D.Group := '';
        D.ImageIndex := -1;
        D.Checked := cbUnchecked;
        D.Enabled := True;
        D.IsHeader := False;
        D.Data := nil;
        Col := clNone;
        GetGalleryData(It, Hit.Tile, D, Col);
        Result := D.Text;
      end;
    rpQuickItem, rpItem, rpItemArrow:
      if It <> nil then
      begin
        if It.Hint <> '' then
          Result := GetLongHint(It.Hint)
        else
          Result := StripHotkey(It.Caption);
        if (It.Hint <> '') and (GetShortHint(It.Hint) <> GetLongHint(It.Hint)) then
          Result := GetShortHint(It.Hint) + sLineBreak + GetLongHint(It.Hint);
      end;
  end;
end;

procedure TPPGCustomRibbon.CMHintShow(var Message: TCMHintShow);
var
  S: string;
  R: TRect;
begin
  inherited;
  S := HintFor(FHot, R);
  if (S = '') or ((FHot.View <> nil) and (FHot.View <> FMainView)) then
    Message.Result := 1
  else
  begin
    Message.HintInfo^.HintStr := S;
    Message.HintInfo^.CursorRect := R;
  end;
end;

{ ---- Haken (Tasten, Klicks daneben) ---- }

function TPPGCustomRibbon.BelongsToForm(Wnd: HWND): Boolean;
var
  F: TCustomForm;
begin
  F := GetParentForm(Self);
  Result := (F <> nil) and F.HandleAllocated and (Wnd <> 0) and
    ((GetAncestor(Wnd, GA_ROOT) = F.Handle) or InPopup(Wnd));
end;

procedure TPPGCustomRibbon.Hook(var Msg: TMsg; var Handled: Boolean);
var
  Ctrl: Boolean;
  Pt: TPoint;
  W: HWND;
begin
  if (FBusy > 0) or not HandleAllocated or not Showing then
    Exit;
  // Klick ausserhalb eines Popups schliesst es und alle darueber (auch bei
  // Klicks in andere Formulare der Anwendung)
  if (Msg.message = WM_LBUTTONDOWN) or (Msg.message = WM_RBUTTONDOWN) or (Msg.message = WM_MBUTTONDOWN) or
    (Msg.message = WM_NCLBUTTONDOWN) or (Msg.message = WM_NCRBUTTONDOWN) then
  begin
    if FKeyTipLevel > 0 then
      HideKeyTips;
    if FNavMode then
      LeaveKeyboardNavigation;
    FAltDown := False;
    // Klicks auf das Ribbon selbst entscheidet MouseDown (Registerkarte,
    // zweiter Klick auf eine geschrumpfte Gruppe schliesst ihr Popup)
    if Msg.hwnd = Handle then
      Exit;
    if (FGalleryPopup <> nil) and FGalleryPopup.IsOpen and FGalleryPopup.HandleAllocated and
      ((Msg.hwnd = FGalleryPopup.Handle) or IsChild(FGalleryPopup.Handle, Msg.hwnd)) then
      Exit;
    CloseGalleryPopup;
    if (FGroupPopup <> nil) and FGroupPopup.IsOpen and FGroupPopup.HandleAllocated and
      ((Msg.hwnd = FGroupPopup.Handle) or IsChild(FGroupPopup.Handle, Msg.hwnd)) then
      Exit;
    CloseGroupPopup;
    if (FPanelPopup <> nil) and FPanelPopup.IsOpen and FPanelPopup.HandleAllocated and
      ((Msg.hwnd = FPanelPopup.Handle) or IsChild(FPanelPopup.Handle, Msg.hwnd)) then
      Exit;
    ClosePanelPopup;
    Exit;
  end;
  if not BelongsToForm(Msg.hwnd) then
    Exit;
  // Rad ueber der offenen Galerie
  if (Msg.message = WM_MOUSEWHEEL) and (FGalleryPopup <> nil) and FGalleryPopup.IsOpen then
  begin
    GetCursorPos(Pt);
    W := WindowFromPoint(Pt);
    if W = FGalleryPopup.Handle then
    begin
      if SmallInt(HiWord(Msg.wParam)) > 0 then
        FGalleryPopup.ScrollRows(-1)
      else
        FGalleryPopup.ScrollRows(1);
      Handled := True;
    end;
    Exit;
  end;
  // KeyTip-Modus
  if FKeyTipLevel > 0 then
  begin
    case Msg.message of
      WM_KEYDOWN, WM_SYSKEYDOWN:
        begin
          if (Msg.wParam = VK_MENU) or (Msg.wParam = VK_F10) then
            FLeaveOnKeyUp := True
          else if not HandleKeyTipKey(Word(Msg.wParam)) then
          begin
            if Msg.message = WM_SYSKEYDOWN then
            begin
              // Alt+andere Taste: KeyTips verlassen, Windows bekommt die Taste
              HideKeyTips;
              Exit;
            end;
            // Zeichen: als WM_CHAR weiterreichen, das wir dann abfangen
            TranslateMessage(Msg);
          end;
          Handled := True;
        end;
      WM_CHAR, WM_SYSCHAR:
        begin
          HandleKeyTipChar(Char(Msg.wParam));
          Handled := True;
        end;
      WM_KEYUP, WM_SYSKEYUP:
        begin
          Handled := True;
          if FLeaveOnKeyUp and ((Msg.wParam = VK_MENU) or (Msg.wParam = VK_F10)) then
          begin
            FLeaveOnKeyUp := False;
            HideKeyTips;
          end;
        end;
    end;
    Exit;
  end;
  // Tastaturbedienung (ohne Plaketten)
  if FNavMode then
  begin
    case Msg.message of
      WM_KEYDOWN, WM_SYSKEYDOWN:
        begin
          if (Msg.wParam = VK_MENU) or (Msg.wParam = VK_F10) then
            FLeaveOnKeyUp := True
          else if not HandleNavKey(Word(Msg.wParam), KeyDataToShiftState(Msg.lParam)) then
            LeaveKeyboardNavigation;
          Handled := True;
        end;
      WM_CHAR, WM_SYSCHAR:
        Handled := True;
      WM_KEYUP, WM_SYSKEYUP:
        begin
          Handled := True;
          if FLeaveOnKeyUp and ((Msg.wParam = VK_MENU) or (Msg.wParam = VK_F10)) then
          begin
            FLeaveOnKeyUp := False;
            LeaveKeyboardNavigation;
          end;
        end;
    end;
    Exit;
  end;
  // Offene Galerie: Pfeile, Enter, Esc
  if (FGalleryPopup <> nil) and FGalleryPopup.IsOpen and (Msg.message = WM_KEYDOWN) then
  begin
    if FGalleryPopup.HandleKey(Word(Msg.wParam)) then
      Handled := True;
    Exit;
  end;
  if Msg.message = WM_KEYDOWN then
  begin
    Ctrl := GetKeyState(VK_CONTROL) < 0;
    if (Msg.wParam = VK_ESCAPE) then
    begin
      if (FGroupPopup <> nil) and FGroupPopup.IsOpen then
      begin
        CloseGroupPopup;
        Handled := True;
      end
      else if (FPanelPopup <> nil) and FPanelPopup.IsOpen then
      begin
        ClosePanelPopup;
        Handled := True;
      end
      else if FBackstageVisible then
      begin
        HideBackstage;
        Handled := True;
      end;
    end
    else if Ctrl and (Msg.wParam = VK_F1) and (GetKeyState(VK_SHIFT) >= 0) then
    begin
      UserToggleMinimized;
      Handled := True;
    end;
    FAltDown := False;
    Exit;
  end;
  if not FKeyTipsEnabled or FBackstageVisible then
    Exit;
  case Msg.message of
    WM_SYSKEYDOWN:
      begin
        if (Msg.wParam = VK_MENU) and (Msg.lParam and $40000000 = 0) then
          FAltDown := True
        else
        begin
          FAltDown := False;
          if Msg.wParam = VK_F10 then
          begin
            ShowKeyTips;
            Handled := True;
          end;
        end;
      end;
    WM_SYSKEYUP:
      if (Msg.wParam = VK_MENU) and FAltDown then
      begin
        FAltDown := False;
        ShowKeyTips;
        Handled := True;
      end;
    WM_SYSCHAR:
      begin
        FAltDown := False;
        // Alt+Buchstabe: direkt in die KeyTips, wenn eine Plakette der
        // obersten Ebene passt (Plaketten erst danach zeigen, kein Flackern)
        if (csDesigning in ComponentState) or FNavMode then
          Exit;
        FKeyTipLevel := 1;
        FKeyTipView := nil;
        FLeaveOnKeyUp := False;
        BuildKeyTips;
        if (KeyTipMatchCount(Char(Msg.wParam)) > 0) and HandleKeyTipChar(Char(Msg.wParam)) then
          Handled := True
        else
        begin
          FKeyTipLevel := 0;
          SetLength(FKeyTips, 0);
          FKeyTyped := '';
        end;
      end;
  end;
end;

procedure TPPGCustomRibbon.AppDeactivate(Sender: TObject);
begin
  FAltDown := False;
  if FKeyTipLevel > 0 then
    HideKeyTips;
  if FNavMode then
    LeaveKeyboardNavigation;
  ClosePopups;
end;

{ ---- KeyTips ---- }

procedure TPPGCustomRibbon.BuildKeyTips;
var
  Captions, Explicit: array of string;
  Tips: TArray<string>;
  N, I, G, J: Integer;
  View: TPPGRibbonView;
  It: TPPGRibbonItem;
  Hits: array of TPPGRibbonHit;
  R: TRect;
  Cap: string;

  procedure Add(const Hit: TPPGRibbonHit; const ACaption, AExplicit: string);
  begin
    SetLength(Hits, N + 1);
    SetLength(Captions, N + 1);
    SetLength(Explicit, N + 1);
    Hits[N] := Hit;
    Captions[N] := ACaption;
    Explicit[N] := AExplicit;
    Inc(N);
  end;

begin
  N := 0;
  EnsureLayout;
  if FKeyTipLevel = 1 then
  begin
    if not IsRectEmpty(FAppRect) then
    begin
      Cap := FApplicationButtonCaption;
      if Cap = '' then
        Cap := PPGStr(@SPPGRibbonFile);
      Add(MakeHit(rpAppButton, nil, 0, -1, -1), Cap, '');
    end;
    for I := 0 to FTabs.Count - 1 do
      if not IsRectEmpty(FTabRects[I]) then
        Add(MakeHit(rpTab, nil, I, -1, -1), FTabs[I].Caption, FTabs[I].KeyTip);
    // Schnellzugriff: Ziffern 1..9, danach 09, 08 ... (wie Office)
    J := 0;
    for I := 0 to FQuickAccess.Count - 1 do
      if not IsRectEmpty(FQatRects[I]) and (FQuickAccess[I].Kind <> rikSeparator) then
      begin
        Inc(J);
        if J <= 9 then
          Add(MakeHit(rpQuickItem, nil, I, -1, -1), FQuickAccess[I].Caption, IntToStr(J))
        else
          Add(MakeHit(rpQuickItem, nil, I, -1, -1), FQuickAccess[I].Caption, '0' + IntToStr(19 - J));
      end;
  end
  else
  begin
    View := FKeyTipView;
    if View <> nil then
    begin
      EnsureView(View);
      for G := 0 to View.GroupCount - 1 do
      begin
        if View.Groups[G].State = rgsCollapsed then
        begin
          Add(MakeHit(rpGroup, View, G, -1, -1), View.Groups[G].Group.Caption, View.Groups[G].Group.KeyTip);
          Continue;
        end;
        for I := 0 to High(View.Groups[G].Items) do
        begin
          It := View.Groups[G].Items[I];
          if It.Kind = rikSeparator then
            Continue;
          if It.Kind = rikGallery then
            Add(MakeHit(rpGalleryMore, View, G, I, -1), It.Caption, It.KeyTip)
          else
            Add(MakeHit(rpItem, View, G, I, -1), It.Caption, It.KeyTip);
        end;
        if not IsRectEmpty(View.Groups[G].LauncherRect) then
          Add(MakeHit(rpLauncher, View, G, -1, -1), View.Groups[G].Group.Caption, '');
      end;
    end;
  end;
  Tips := PPGAssignKeyTips(Captions, Explicit);
  SetLength(FKeyTips, N);
  for I := 0 to N - 1 do
  begin
    FKeyTips[I].Hit := Hits[I];
    FKeyTips[I].Tip := Tips[I];
    It := HitItem(Hits[I]);
    FKeyTips[I].Enabled := Enabled and ((It = nil) or It.Enabled);
    R := HitScreenRect(Hits[I]);
    if Hits[I].Part = rpGalleryMore then
      R := HitScreenRect(MakeHit(rpItem, Hits[I].View, Hits[I].Index, Hits[I].Item, -1));
    // Lage der Plakette: unter Kopf-Elementen, an der Unterkante grosser
    // Buttons, bei kleinen links unten am Symbol
    case Hits[I].Part of
      rpItem, rpGalleryMore:
        if (It <> nil) and (Hits[I].View.Groups[Hits[I].Index].Places[Hits[I].Item].Size <> rsLarge) and
          (It.Kind <> rikGallery) then
          FKeyTips[I].Anchor := Point(R.Left + Sc(PadX) + Sc(IconSmall) div 2, R.Bottom - Sc(8))
        else
          FKeyTips[I].Anchor := Point((R.Left + R.Right) div 2, R.Bottom - Sc(10));
      rpGroup:
        FKeyTips[I].Anchor := Point((R.Left + R.Right) div 2, R.Bottom - Sc(10));
      rpLauncher:
        FKeyTips[I].Anchor := Point((R.Left + R.Right) div 2, R.Top);
    else
      FKeyTips[I].Anchor := Point((R.Left + R.Right) div 2, R.Bottom - Sc(6));
    end;
  end;
  FKeyTyped := '';
end;

procedure TPPGCustomRibbon.ShowOverlays;
var
  I, J, W, H, Th: Integer;
  Mon: TMonitor;
  Mons: TList<TMonitor>;
  O: TPPGKeyTipOverlay;
  Bounds, R: TRect;
  C: TPPGRibbonColors;
  Shown: array of Boolean;
begin
  HideOverlays;
  if (Length(FKeyTips) = 0) or (csDesigning in ComponentState) then
    Exit;
  C := RibbonColors;
  Th := TextHeight;
  SetLength(Shown, Length(FKeyTips));
  for I := 0 to High(FKeyTips) do
    Shown[I] := (FKeyTyped = '') or (Copy(FKeyTips[I].Tip, 1, Length(FKeyTyped)) = FKeyTyped);
  Mons := TList<TMonitor>.Create;
  try
    for I := 0 to High(FKeyTips) do
    begin
      Mon := Screen.MonitorFromPoint(FKeyTips[I].Anchor, mdNearest);
      if (Mon <> nil) and (Mons.IndexOf(Mon) < 0) then
        Mons.Add(Mon);
    end;
    // Ein Fenster je Monitor, so gross wie die Plaketten darauf
    for J := 0 to Mons.Count - 1 do
    begin
      O := TPPGKeyTipOverlay.Create(Self);
      O.Font.Assign(Font);
      O.FBack := C.Text;
      O.FText := C.Panel;
      O.FBorder := C.Text;
      if C.HC then
      begin
        O.FBack := PPGColorToRGB(clInfoBk);
        O.FText := PPGColorToRGB(clInfoText);
        O.FBorder := PPGColorToRGB(clInfoText);
      end;
      Bounds := Rect(MaxInt, MaxInt, -MaxInt, -MaxInt);
      for I := 0 to High(FKeyTips) do
      begin
        if not Shown[I] or (Screen.MonitorFromPoint(FKeyTips[I].Anchor, mdNearest) <> Mons[J]) then
          Continue;
        W := Max(Th, TextWidth(FKeyTips[I].Tip) + Sc(8));
        H := Th + Sc(4);
        R := Rect(FKeyTips[I].Anchor.X - W div 2, FKeyTips[I].Anchor.Y, FKeyTips[I].Anchor.X - W div 2 + W,
          FKeyTips[I].Anchor.Y + H);
        SetLength(O.FTexts, Length(O.FTexts) + 1);
        SetLength(O.FRects, Length(O.FRects) + 1);
        SetLength(O.FEnabled, Length(O.FEnabled) + 1);
        O.FTexts[High(O.FTexts)] := FKeyTips[I].Tip;
        O.FRects[High(O.FRects)] := R;
        O.FEnabled[High(O.FEnabled)] := FKeyTips[I].Enabled;
        Bounds.Left := Min(Bounds.Left, R.Left);
        Bounds.Top := Min(Bounds.Top, R.Top);
        Bounds.Right := Max(Bounds.Right, R.Right);
        Bounds.Bottom := Max(Bounds.Bottom, R.Bottom);
      end;
      if Length(O.FTexts) = 0 then
      begin
        O.Free;
        Continue;
      end;
      for I := 0 to High(O.FRects) do
        OffsetRect(O.FRects[I], -Bounds.Left, -Bounds.Top);
      FOverlays.Add(O);
      O.HandleNeeded;
      SetWindowPos(O.Handle, HWND_TOP, Bounds.Left, Bounds.Top, RectW(Bounds), RectH(Bounds),
        SWP_NOACTIVATE or SWP_SHOWWINDOW);
      O.Invalidate;
    end;
  finally
    Mons.Free;
  end;
end;

procedure TPPGCustomRibbon.HideOverlays;
begin
  if FOverlays <> nil then
    FOverlays.Clear;
end;

procedure TPPGCustomRibbon.ShowKeyTips;
begin
  if (csDesigning in ComponentState) or not HandleAllocated or not Showing then
    Exit;
  if FNavMode then
    LeaveKeyboardNavigation;
  FKeyTipLevel := 1;
  FKeyTipView := nil;
  FLeaveOnKeyUp := False;
  BuildKeyTips;
  ShowOverlays;
  NotifyAccessibility(EVENT_SYSTEM_MENUSTART);
end;

procedure TPPGCustomRibbon.HideKeyTips;
begin
  if FKeyTipLevel = 0 then
    Exit;
  FKeyTipLevel := 0;
  FKeyTipView := nil;
  FKeyTyped := '';
  SetLength(FKeyTips, 0);
  HideOverlays;
  NotifyAccessibility(EVENT_SYSTEM_MENUEND);
end;

function TPPGCustomRibbon.KeyTipCount: Integer;
begin
  Result := Length(FKeyTips);
end;

function TPPGCustomRibbon.KeyTipText(Index: Integer): string;
begin
  if (Index >= 0) and (Index <= High(FKeyTips)) then
    Result := FKeyTips[Index].Tip
  else
    Result := '';
end;

function TPPGCustomRibbon.KeyTipHit(Index: Integer): TPPGRibbonHit;
begin
  if (Index >= 0) and (Index <= High(FKeyTips)) then
    Result := FKeyTips[Index].Hit
  else
    Result := NoHit;
end;

function TPPGCustomRibbon.KeyTipOverlayCount: Integer;
begin
  if FOverlays = nil then
    Result := 0
  else
    Result := FOverlays.Count;
end;

function TPPGCustomRibbon.HandleKeyTipKey(Key: Word): Boolean;
begin
  Result := True;
  case Key of
    VK_ESCAPE:
      begin
        // eine Ebene zurueck
        if FKeyTyped <> '' then
        begin
          FKeyTyped := '';
          ShowOverlays;
        end
        else if FKeyTipLevel = 3 then
        begin
          CloseGroupPopup;
          FKeyTipLevel := 2;
          if FMinimized and (FPanelPopup <> nil) and FPanelPopup.IsOpen then
            FKeyTipView := FPanelPopup.View
          else
            FKeyTipView := FMainView;
          BuildKeyTips;
          ShowOverlays;
        end
        else if FKeyTipLevel = 2 then
        begin
          ClosePanelPopup;
          FKeyTipLevel := 1;
          FKeyTipView := nil;
          BuildKeyTips;
          ShowOverlays;
        end
        else
          HideKeyTips;
      end;
    VK_BACK:
      if FKeyTyped <> '' then
      begin
        Delete(FKeyTyped, Length(FKeyTyped), 1);
        ShowOverlays;
      end;
    VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_TAB:
      begin
        // Pfeile wechseln in die Tastaturbedienung
        HideKeyTips;
        EnterKeyboardNavigation;
        if Key <> VK_DOWN then
          HandleNavKey(Key, []);
      end;
    VK_RETURN, VK_SPACE:
      ;
  else
    Result := False;
  end;
end;

function TPPGCustomRibbon.KeyTipMatchCount(Ch: Char): Integer;
var
  Tips: array of string;
  I, Exact: Integer;
begin
  SetLength(Tips, Length(FKeyTips));
  for I := 0 to High(FKeyTips) do
    Tips[I] := FKeyTips[I].Tip;
  Result := PPGMatchKeyTips(Tips, FKeyTyped + PPGKeyTipChar(Ch), Exact);
end;

function TPPGCustomRibbon.HandleKeyTipChar(Ch: Char): Boolean;
var
  S, Typed: string;
  Count, Exact: Integer;
  Tips: array of string;
  I: Integer;
begin
  Result := False;
  if FKeyTipLevel = 0 then
    Exit;
  S := PPGKeyTipChar(Ch);
  if S = '' then
    Exit;
  Typed := FKeyTyped + S;
  SetLength(Tips, Length(FKeyTips));
  for I := 0 to High(FKeyTips) do
    Tips[I] := FKeyTips[I].Tip;
  Count := PPGMatchKeyTips(Tips, Typed, Exact);
  if Count = 0 then
  begin
    MessageBeep(0);
    Exit;
  end;
  Result := True;
  if Exact >= 0 then
    ExecuteKeyTip(Exact)
  else
  begin
    // mehrstellige Plakette: nur noch die passenden zeigen
    FKeyTyped := Typed;
    ShowOverlays;
  end;
end;

procedure TPPGCustomRibbon.ExecuteKeyTip(Index: Integer);
var
  Hit: TPPGRibbonHit;
  It: TPPGRibbonItem;
begin
  Hit := FKeyTips[Index].Hit;
  if not FKeyTips[Index].Enabled then
  begin
    MessageBeep(0);
    FKeyTyped := '';
    ShowOverlays;
    Exit;
  end;
  It := HitItem(Hit);
  case Hit.Part of
    rpTab:
      begin
        UserSelectTab(Hit.Index);
        if FTabs[Hit.Index] <> ActiveTab then
        begin
          HideKeyTips;
          Exit;
        end;
        FKeyTipLevel := 2;
        if FMinimized and (FPanelPopup <> nil) and FPanelPopup.IsOpen then
          FKeyTipView := FPanelPopup.View
        else
          FKeyTipView := FMainView;
        UpdateLayout;
        BuildKeyTips;
        ShowOverlays;
      end;
    rpGroup:
      begin
        OpenGroupPopup(Hit.View, Hit.Index);
        if (FGroupPopup <> nil) and FGroupPopup.IsOpen then
        begin
          FKeyTipLevel := 3;
          FKeyTipView := FGroupPopup.View;
          BuildKeyTips;
          ShowOverlays;
        end
        else
          HideKeyTips;
      end;
  else
    begin
      HideKeyTips;
      if (Hit.Part = rpItem) and (It <> nil) and (It.Kind = rikSplitButton) and (It.DropDownMenu <> nil) then
        // wie Office: der KeyTip eines Split-Buttons oeffnet sein Menue
        ActivateHit(MakeHit(rpItemArrow, Hit.View, Hit.Index, Hit.Item, -1), True)
      else
        ActivateHit(Hit, True);
    end;
  end;
end;

{ ---- Tastaturbedienung ---- }

function TPPGCustomRibbon.Elements: TArray<TPPGRibbonElement>;
var
  N, I, G: Integer;
  It: TPPGRibbonItem;
  L: TArray<TPPGRibbonElement>;

  procedure Add(const Hit: TPPGRibbonHit);
  begin
    SetLength(L, N + 1);
    L[N].Hit := Hit;
    L[N].Rect := HitRect(Hit);
    Inc(N);
  end;

begin
  EnsureLayout;
  N := 0;
  SetLength(L, 0);
  if not IsRectEmpty(FAppRect) then
    Add(MakeHit(rpAppButton, nil, 0, -1, -1));
  for I := 0 to High(FQatRects) do
    if not IsRectEmpty(FQatRects[I]) and (FQuickAccess[I].Kind <> rikSeparator) then
      Add(MakeHit(rpQuickItem, nil, I, -1, -1));
  if not IsRectEmpty(FQatCustomizeRect) then
    Add(MakeHit(rpQuickCustomize, nil, 0, -1, -1));
  for I := 0 to High(FTabRects) do
    if not IsRectEmpty(FTabRects[I]) then
      Add(MakeHit(rpTab, nil, I, -1, -1));
  if not IsRectEmpty(FMinimizeRect) then
    Add(MakeHit(rpMinimize, nil, 0, -1, -1));
  if not FMinimized then
    for G := 0 to FMainView.GroupCount - 1 do
    begin
      if FMainView.Groups[G].State = rgsCollapsed then
      begin
        Add(MakeHit(rpGroup, FMainView, G, -1, -1));
        Continue;
      end;
      for I := 0 to High(FMainView.Groups[G].Items) do
      begin
        It := FMainView.Groups[G].Items[I];
        if It.Kind in [rikSeparator, rikControl] then
          Continue;
        if It.Kind = rikGallery then
          Add(MakeHit(rpGalleryMore, FMainView, G, I, -1))
        else
          Add(MakeHit(rpItem, FMainView, G, I, -1));
      end;
      if not IsRectEmpty(FMainView.Groups[G].LauncherRect) then
        Add(MakeHit(rpLauncher, FMainView, G, -1, -1));
    end;
  Result := L;
end;

function TPPGCustomRibbon.ElementCount: Integer;
begin
  Result := Length(Elements);
end;

procedure TPPGCustomRibbon.EnterKeyboardNavigation;
var
  E: TArray<TPPGRibbonElement>;
  I: Integer;
begin
  if csDesigning in ComponentState then
    Exit;
  HideKeyTips;
  E := Elements;
  FNavMode := True;
  FNavIndex := -1;
  // Start auf der aktiven Registerkarte
  for I := 0 to High(E) do
    if (E[I].Hit.Part = rpTab) and (FTabs[E[I].Hit.Index] = ActiveTab) then
      FNavIndex := I;
  if (FNavIndex < 0) and (Length(E) > 0) then
    FNavIndex := 0;
  Invalidate;
  NotifyAccessibility(EVENT_SYSTEM_MENUSTART);
  if FNavIndex >= 0 then
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, FNavIndex + 1);
end;

procedure TPPGCustomRibbon.LeaveKeyboardNavigation;
begin
  if not FNavMode then
    Exit;
  FNavMode := False;
  FLeaveOnKeyUp := False;
  Invalidate;
  NotifyAccessibility(EVENT_SYSTEM_MENUEND);
end;

procedure TPPGCustomRibbon.NavMove(Key: Word; Shift: TShiftState);
var
  E: TArray<TPPGRibbonElement>;
  I, N, Best: Integer;
  InPanel: Boolean;

  function IsPanel(Idx: Integer): Boolean;
  begin
    Result := E[Idx].Hit.View <> nil;
  end;

begin
  E := Elements;
  N := Length(E);
  if N = 0 then
    Exit;
  if (FNavIndex < 0) or (FNavIndex >= N) then
    FNavIndex := 0;
  InPanel := IsPanel(FNavIndex);
  if UseRightToLeftAlignment then
    if Key = VK_LEFT then
      Key := VK_RIGHT
    else if Key = VK_RIGHT then
      Key := VK_LEFT;
  case Key of
    VK_RIGHT:
      // innerhalb der Zeile (Kopf bzw. Band) weiter, mit Umlauf
      begin
        I := FNavIndex;
        repeat
          I := (I + 1) mod N;
        until (IsPanel(I) = InPanel) or (I = FNavIndex);
        FNavIndex := I;
      end;
    VK_LEFT:
      begin
        I := FNavIndex;
        repeat
          I := (I - 1 + N) mod N;
        until (IsPanel(I) = InPanel) or (I = FNavIndex);
        FNavIndex := I;
      end;
    VK_TAB:
      if ssShift in Shift then
        FNavIndex := (FNavIndex - 1 + N) mod N
      else
        FNavIndex := (FNavIndex + 1) mod N;
    VK_DOWN:
      if not InPanel then
      begin
        for I := 0 to N - 1 do
          if IsPanel(I) then
          begin
            FNavIndex := I;
            Break;
          end;
      end
      else
      begin
        // im Band: zum naechsten Element darunter in derselben Spalte
        Best := -1;
        for I := 0 to N - 1 do
          if IsPanel(I) and (E[I].Rect.Top >= E[FNavIndex].Rect.Bottom - 1) and
            (E[I].Rect.Left < E[FNavIndex].Rect.Right) and (E[I].Rect.Right > E[FNavIndex].Rect.Left) then
          begin
            if (Best < 0) or (E[I].Rect.Top < E[Best].Rect.Top) then
              Best := I;
          end;
        if Best >= 0 then
          FNavIndex := Best;
      end;
    VK_UP:
      if InPanel then
      begin
        Best := -1;
        for I := 0 to N - 1 do
          if IsPanel(I) and (E[I].Rect.Bottom <= E[FNavIndex].Rect.Top + 1) and
            (E[I].Rect.Left < E[FNavIndex].Rect.Right) and (E[I].Rect.Right > E[FNavIndex].Rect.Left) then
          begin
            if (Best < 0) or (E[I].Rect.Top > E[Best].Rect.Top) then
              Best := I;
          end;
        if Best >= 0 then
          FNavIndex := Best
        else
          // oben aus dem Band: zur aktiven Registerkarte
          for I := 0 to N - 1 do
            if (E[I].Hit.Part = rpTab) and (FTabs[E[I].Hit.Index] = ActiveTab) then
            begin
              FNavIndex := I;
              Break;
            end;
      end;
    VK_HOME:
      for I := 0 to N - 1 do
        if IsPanel(I) = InPanel then
        begin
          FNavIndex := I;
          Break;
        end;
    VK_END:
      for I := N - 1 downto 0 do
        if IsPanel(I) = InPanel then
        begin
          FNavIndex := I;
          Break;
        end;
  end;
  // Registerkarte unter dem Fokus wird aktiv (wie Office)
  if (E[FNavIndex].Hit.Part = rpTab) and (FTabs[E[FNavIndex].Hit.Index] <> ActiveTab) and
    (Key in [VK_LEFT, VK_RIGHT, VK_HOME, VK_END]) and not FMinimized then
  begin
    UserSelectTab(E[FNavIndex].Hit.Index);
    E := Elements;
  end;
  Invalidate;
  NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, FNavIndex + 1);
end;

function TPPGCustomRibbon.HandleNavKey(Key: Word; Shift: TShiftState): Boolean;
var
  E: TArray<TPPGRibbonElement>;
  Hit: TPPGRibbonHit;
begin
  Result := True;
  case Key of
    VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_TAB, VK_HOME, VK_END:
      NavMove(Key, Shift);
    VK_RETURN, VK_SPACE:
      begin
        E := Elements;
        if (FNavIndex < 0) or (FNavIndex > High(E)) then
          Exit;
        Hit := E[FNavIndex].Hit;
        if Hit.Part = rpTab then
        begin
          // Enter auf der Karte: ins Band
          UserSelectTab(Hit.Index);
          if not FMinimized then
            NavMove(VK_DOWN, []);
          Exit;
        end;
        LeaveKeyboardNavigation;
        ActivateHit(Hit, True);
      end;
    VK_ESCAPE:
      LeaveKeyboardNavigation;
  else
    Result := False;
  end;
end;

{ ---- Nachrichten ---- }

procedure TPPGCustomRibbon.WndProc(var Message: TMessage);
var
  E: TArray<TPPGRibbonElement>;
  Id: Integer;
begin
  if (GMsgLayout <> 0) and (Message.Msg = GMsgLayout) then
  begin
    FLayoutPosted := False;
    if FControlLayoutPending then
      ApplyControlLayout;
    Exit;
  end;
  if (GMsgAccAction <> 0) and (Message.Msg = GMsgAccAction) then
  begin
    Id := Integer(Message.WParam);
    E := Elements;
    if (Id >= 1) and (Id <= Length(E)) then
      ActivateHit(E[Id - 1].Hit, True);
    Exit;
  end;
  inherited WndProc(Message);
end;

{ ---- Barrierefreiheit: Kinder = Elements ---- }

function TPPGCustomRibbon.AccName: string;
begin
  Result := inherited AccName;
  if Result = '' then
    Result := PPGStr(@SPPGRibbonName);
end;

function TPPGCustomRibbon.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_GROUPING;
end;

function TPPGCustomRibbon.AccChildCount: Integer;
begin
  Result := ElementCount;
end;

function TPPGCustomRibbon.AccChildName(Id: Integer): string;
var
  E: TArray<TPPGRibbonElement>;
  It: TPPGRibbonItem;
  Hit: TPPGRibbonHit;
begin
  Result := '';
  E := Elements;
  if (Id < 1) or (Id > Length(E)) then
    Exit;
  Hit := E[Id - 1].Hit;
  It := HitItem(Hit);
  case Hit.Part of
    rpAppButton:
      if FApplicationButtonCaption <> '' then
        Result := StripHotkey(FApplicationButtonCaption)
      else
        Result := PPGStr(@SPPGRibbonFile);
    rpTab:
      begin
        Result := StripHotkey(FTabs[Hit.Index].Caption);
        if FTabs[Hit.Index].IsContextual then
          Result := Format(PPGStr(@SPPGRibbonContextTab), [FTabs[Hit.Index].ContextName, Result]);
      end;
    rpMinimize:
      if FMinimized then
        Result := PPGStr(@SPPGRibbonExpand)
      else
        Result := PPGStr(@SPPGRibbonMinimize);
    rpQuickCustomize:
      Result := PPGStr(@SPPGRibbonCustomizeQat);
    rpGroup:
      Result := Hit.View.Groups[Hit.Index].Group.Caption;
    rpLauncher:
      begin
        Result := Hit.View.Groups[Hit.Index].Group.LauncherHint;
        if Result = '' then
          Result := Hit.View.Groups[Hit.Index].Group.Caption;
      end;
  else
    if It <> nil then
    begin
      Result := StripHotkey(It.Caption);
      if Result = '' then
        Result := GetShortHint(It.Hint);
    end;
  end;
end;

function TPPGCustomRibbon.AccChildRole(Id: Integer): Integer;
var
  E: TArray<TPPGRibbonElement>;
  It: TPPGRibbonItem;
begin
  Result := ROLE_SYSTEM_PUSHBUTTON;
  E := Elements;
  if (Id < 1) or (Id > Length(E)) then
    Exit;
  It := HitItem(E[Id - 1].Hit);
  case E[Id - 1].Hit.Part of
    rpTab: Result := ROLE_SYSTEM_PAGETAB;
    rpAppButton:
      if (FApplicationMenu <> nil) and (FBackstage = nil) then
        Result := ROLE_SYSTEM_BUTTONMENU;
    rpQuickCustomize, rpGroup: Result := ROLE_SYSTEM_BUTTONMENU;
    rpGalleryMore: Result := ROLE_SYSTEM_BUTTONDROPDOWNGRID;
  else
    if It <> nil then
      case It.Kind of
        rikCheck: Result := ROLE_SYSTEM_CHECKBUTTON;
        rikSplitButton: Result := ROLE_SYSTEM_SPLITBUTTON;
        rikGallery: Result := ROLE_SYSTEM_BUTTONDROPDOWNGRID;
      else
        if It.DropDownMenu <> nil then
          Result := ROLE_SYSTEM_BUTTONMENU;
      end;
  end;
end;

function TPPGCustomRibbon.AccChildState(Id: Integer): Integer;
var
  E: TArray<TPPGRibbonElement>;
  It, Src: TPPGRibbonItem;
  Hit: TPPGRibbonHit;
begin
  Result := STATE_SYSTEM_FOCUSABLE;
  E := Elements;
  if (Id < 1) or (Id > Length(E)) then
    Exit(0);
  Hit := E[Id - 1].Hit;
  It := HitItem(Hit);
  if Hit.Part = rpQuickItem then
  begin
    Src := QuickSource(It);
    if Src <> nil then
      It := Src;
  end;
  if (not Enabled) or ((It <> nil) and not It.Enabled) then
    Result := STATE_SYSTEM_UNAVAILABLE;
  case Hit.Part of
    rpTab:
      begin
        Result := Result or STATE_SYSTEM_SELECTABLE;
        if FTabs[Hit.Index] = ActiveTab then
          Result := Result or STATE_SYSTEM_SELECTED;
      end;
    rpGroup, rpQuickCustomize, rpGalleryMore:
      Result := Result or STATE_SYSTEM_HASPOPUP;
  end;
  if (It <> nil) and (It.Kind = rikCheck) and It.Down then
    Result := Result or STATE_SYSTEM_CHECKED or STATE_SYSTEM_PRESSED;
  if (It <> nil) and (It.DropDownMenu <> nil) then
    Result := Result or STATE_SYSTEM_HASPOPUP;
  if FNavMode and (FNavIndex = Id - 1) then
    Result := Result or STATE_SYSTEM_FOCUSED;
end;

function TPPGCustomRibbon.AccChildRect(Id: Integer): TRect;
var
  E: TArray<TPPGRibbonElement>;
begin
  E := Elements;
  if (Id >= 1) and (Id <= Length(E)) then
    Result := E[Id - 1].Rect
  else
    Result := Rect(0, 0, 0, 0);
end;

function TPPGCustomRibbon.AccChildAt(X, Y: Integer): Integer;
var
  E: TArray<TPPGRibbonElement>;
  I: Integer;
begin
  E := Elements;
  for I := 0 to High(E) do
    if PtInRect(E[I].Rect, Point(X, Y)) then
      Exit(I + 1);
  Result := 0;
end;

function TPPGCustomRibbon.AccChildDefaultAction(Id: Integer): string;
var
  R: Integer;
begin
  R := AccChildRole(Id);
  case R of
    ROLE_SYSTEM_PAGETAB: Result := PPGStr(@SPPGAccSelect);
    ROLE_SYSTEM_CHECKBUTTON: Result := PPGStr(@SPPGAccToggle);
    ROLE_SYSTEM_BUTTONMENU, ROLE_SYSTEM_BUTTONDROPDOWNGRID: Result := PPGStr(@SPPGAccOpen);
  else
    Result := PPGStr(@SPPGAccPress);
  end;
end;

procedure TPPGCustomRibbon.AccChildDoDefault(Id: Integer);
begin
  if HandleAllocated then
    PostMessage(Handle, GMsgAccAction, WPARAM(Id), 0);
end;

function TPPGCustomRibbon.AccFocusedChild: Integer;
begin
  if FNavMode then
    Result := FNavIndex + 1
  else
    Result := 0;
end;

function TPPGCustomRibbon.AccSelectedChild: Integer;
var
  E: TArray<TPPGRibbonElement>;
  I: Integer;
begin
  Result := 0;
  E := Elements;
  for I := 0 to High(E) do
    if (E[I].Hit.Part = rpTab) and (FTabs[E[I].Hit.Index] = ActiveTab) then
      Exit(I + 1);
end;

initialization
  RegisterClass(TPPGRibbon);

end.
