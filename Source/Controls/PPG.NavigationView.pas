unit PPG.NavigationView;

{ TPPGNavigationView - Seitenleiste wie WinUI NavigationView (Phase 7c).

  - Eintraege (Items, verschachtelt): Symbol (Icon-Schrift-Zeichen oder
    ImageIndex), Text, Plakette (Zahl oder Punkt), Gruppenueberschrift,
    Trenner, Untereintraege (aufklappbar), Fussbereich (Footer = True, z.B.
    Einstellungen).
  - Hamburger-Knopf klappt die Leiste zwischen voller Breite
    (OpenPaneLength) und kompakter Symbolleiste (CompactPaneLength) um; die
    Breite ist animiert. DisplayMode pdmAuto wechselt nach der Breite des
    Parents (CompactModeThresholdWidth). Kompakt zeigt einen Tooltip mit dem
    Text des Eintrags.
  - Der Auswahl-Indikator gleitet zum gewaehlten Eintrag (ekDecelerate). Ist
    der gewaehlte Eintrag verborgen (zugeklappter Elterneintrag, kompakt),
    steht der Indikator am sichtbaren Vorfahren.
  - PageControl: Ist eins verbunden, zeigt die Auswahl die Seite
    Item.PageIndex.
  - Tastatur: Oben/Unten, Pos1/Ende, Enter/Leertaste waehlen, Rechts/Links
    klappen auf/zu (bzw. springen zum Elterneintrag).
  - Code (Selected := ...) loest kein Ereignis aus; der Anwender loest
    OnItemClick und bei geaenderter Auswahl OnChange aus.
  - Screenreader: Gliederung; Kinder sind die sichtbaren Zeilen und der
    Menue-Knopf. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, {$IFDEF PPG_HAS_IMAGENAME}System.UITypes,{$ENDIF} System.Types, System.SysUtils,
  System.Generics.Collections, Vcl.Controls, Vcl.Graphics, Vcl.ImgList, Vcl.Forms,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Base,
  PPG.PageControl, PPG.ElementStyle, PPG.CustomDraw;

type
  TPPGNavigationView = class;
  TPPGNavItems = class;

  TPPGNavItemKind = (nikItem, nikHeader, nikSeparator);
  TPPGNavDisplayMode = (pdmLeft, pdmLeftCompact, pdmAuto);

  TPPGNavItem = class(TCollectionItem)
  private
    FColor: TColor;
    FTextColor: TColor;
    FFontStyle: TFontStyles;
    FCaption: string;
    FKind: TPPGNavItemKind;
    FIconChar: Word;
    FImageIndex: TPPGImageIndex;
    FBadgeCount: Integer;
    FBadgeDot: Boolean;
    FEnabled: Boolean;
    FVisible: Boolean;
    FFooter: Boolean;
    FPageIndex: Integer;
    FExpanded: Boolean;
    FHint: string;
    FTag: NativeInt;
    FItems: TPPGNavItems;
    FData: Pointer;
    {$IFDEF PPG_HAS_IMAGENAME}
    FImageName: TImageName;
    {$ENDIF}
    procedure SetPageIndex(const Value: Integer);
    procedure SetCaption(const Value: string);
    procedure SetKind(const Value: TPPGNavItemKind);
    procedure SetIconChar(const Value: Word);
    procedure SetImageIndex(const Value: TPPGImageIndex);
    procedure SetBadgeCount(const Value: Integer);
    procedure SetBadgeDot(const Value: Boolean);
    procedure SetEnabled(const Value: Boolean);
    procedure SetVisible(const Value: Boolean);
    procedure SetFooter(const Value: Boolean);
    procedure SetExpanded(const Value: Boolean);
    procedure SetItems(const Value: TPPGNavItems);
    procedure SetColor(const Value: TColor);
    procedure SetTextColor(const Value: TColor);
    procedure SetFontStyle(const Value: TFontStyles);
    function GetLevel: Integer;
    function GetParentItem: TPPGNavItem;
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
    function NavigationView: TPPGNavigationView;
    function HasChildren: Boolean;
    /// Selektierbar: sichtbarer, aktiver Eintrag ohne Kinder.
    function Selectable: Boolean;
    property Level: Integer read GetLevel;
    property ParentItem: TPPGNavItem read GetParentItem;
    property Data: Pointer read FData write FData;
  published
    property Caption: string read FCaption write SetCaption;
    property Kind: TPPGNavItemKind read FKind write SetKind default nikItem;
    /// Zeichen der Symbolschrift (Segoe Fluent Icons/MDL2), 0 = keins.
    property IconChar: Word read FIconChar write SetIconChar default 0;
    property ImageIndex: TPPGImageIndex read FImageIndex write SetImageIndex default -1;
    {$IFDEF PPG_HAS_IMAGENAME}
    /// Bild per Namen (TVirtualImageList, ab 10.4); robust gegen Umsortieren.
    property ImageName: TImageName read FImageName write SetImageName;
    {$ENDIF}
    /// Zahl auf der Plakette (0 = keine).
    property BadgeCount: Integer read FBadgeCount write SetBadgeCount default 0;
    property BadgeDot: Boolean read FBadgeDot write SetBadgeDot default False;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Visible: Boolean read FVisible write SetVisible default True;
    property Footer: Boolean read FFooter write SetFooter default False;
    /// Seite im verbundenen PageControl (-1 = keine).
    property PageIndex: Integer read FPageIndex write SetPageIndex default -1;
    property Expanded: Boolean read FExpanded write SetExpanded default False;
    property Hint: string read FHint write FHint;
    property Tag: NativeInt read FTag write FTag default 0;
    property Items: TPPGNavItems read FItems write SetItems;
    /// Flaeche, Text und zusaetzliche Schriftstile des Eintrags (clDefault = Styles).
    property Color: TColor read FColor write SetColor default clDefault;
    property TextColor: TColor read FTextColor write SetTextColor default clDefault;
    property FontStyle: TFontStyles read FFontStyle write SetFontStyle default [];
  end;

  /// Bereiche der Navigation (nur gesetzte Werte zaehlen, clDefault = Preset).
  TPPGNavStyles = class(TPPGStyleGroup)
  public
    constructor Create(AOwner: TPersistent);
  published
    /// Leiste (Color = Hintergrund, TextColor = Text, BorderColor = Trennlinie).
    property Pane: TPPGElementStyle index 0 read GetItem write SetItem;
    /// Eintraege in Ruhe.
    property Item: TPPGElementStyle index 1 read GetItem write SetItem;
    /// Eintrag unter der Maus.
    property HotItem: TPPGElementStyle index 2 read GetItem write SetItem;
    /// Gewaehlter Eintrag.
    property SelectedItem: TPPGElementStyle index 3 read GetItem write SetItem;
    /// Ueberschriften (Kind = nikHeader).
    property Header: TPPGElementStyle index 4 read GetItem write SetItem;
    /// Auswahl-Indikator (Color).
    property Indicator: TPPGElementStyle index 5 read GetItem write SetItem;
    /// Titel der Leiste.
    property PaneTitle: TPPGElementStyle index 6 read GetItem write SetItem;
  end;

  TPPGNavCustomDrawEvent = procedure(Sender: TObject; Canvas: TCanvas; Item: TPPGNavItem;
    const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
    var DefaultDraw: Boolean) of object;

  TPPGNavItems = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGNavItem;
  protected
    procedure Update(Item: TCollectionItem); override;
    procedure Notify(Item: TCollectionItem; Action: TCollectionNotification); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TPPGNavItem;
    /// Eintrag mit Text und Symbol anfuegen.
    function AddItem(const ACaption: string; AIconChar: Word = 0; APageIndex: Integer = -1): TPPGNavItem;
    function AddHeader(const ACaption: string): TPPGNavItem;
    function AddSeparator: TPPGNavItem;
    function NavigationView: TPPGNavigationView;
    property Items[Index: Integer]: TPPGNavItem read GetItem; default;
  end;

  TPPGNavItemEvent = procedure(Sender: TObject; Item: TPPGNavItem) of object;

  TPPGNavigationView = class(TPPGCustomControl, IPPGAccessibleChildren)
  private
    FImageTint: TPPGImageTint;
    FNavStyles: TPPGNavStyles;
    FOnCustomDrawItem: TPPGNavCustomDrawEvent;
    FDrawCanvas: TCanvas;
    FFonts: TPPGFontCache;
    FItems: TPPGNavItems;
    FSelected: TPPGNavItem;
    FLoadedSelectedIndex: Integer;
    FFocusItem: TPPGNavItem;
    FHotRow: Integer;       // -1 = keine, -2 = Menue-Knopf
    FDownRow: Integer;
    FRows: TList<TPPGNavItem>;
    FFooterRows: TList<TPPGNavItem>;
    FRowsValid: Boolean;
    FRowsPPI: Integer;
    FMainTops: TArray<Integer>;   // Oberkante je Hauptzeile (relativ)
    FFooterTops: TArray<Integer>;
    FMainHeight: Integer;
    FFooterHeight: Integer;
    FIsPaneOpen: Boolean;
    FDisplayMode: TPPGNavDisplayMode;
    FOpenPaneLength: Integer;
    FCompactPaneLength: Integer;
    FCompactThreshold: Integer;
    FPaneTitle: string;
    FShowMenuButton: Boolean;
    FPageControl: TPPGPageControl;
    FPaneAnim: TPPGAnimation;
    FIndicatorAnim: TPPGAnimation;
    FIndicatorFrom: Integer;
    FIndicatorTo: Integer;
    FScrollY: Integer;
    FInternalSize: Boolean;
    FAutoCompact: Boolean;
    FUpdating: Integer;
    FWatched: TWinControl;
    FOnSelectionChange: TNotifyEvent;
    FOnItemInvoked: TPPGNavItemEvent;
    FOnPaneChange: TNotifyEvent;
    function GetSelectedIndex: Integer;
    procedure SetSelectedIndex(const Value: Integer);
    procedure SetCompactModeThresholdWidth(const Value: Integer);
    procedure DrawItemImage(const ACanvas: IPPGCanvas; Index, X, Y: Integer; AEnabled: Boolean;
      Color: TColor);
    procedure SetImageTint(const Value: TPPGImageTint);
    procedure SetNavStyles(const Value: TPPGNavStyles);
    procedure NavStylesChanged(Sender: TObject);
    procedure SetItems(const Value: TPPGNavItems);
    procedure SetSelected(const Value: TPPGNavItem);
    procedure SetIsPaneOpen(const Value: Boolean);
    procedure SetDisplayMode(const Value: TPPGNavDisplayMode);
    procedure SetOpenPaneLength(const Value: Integer);
    procedure SetCompactPaneLength(const Value: Integer);
    procedure SetPaneTitle(const Value: string);
    procedure SetShowMenuButton(const Value: Boolean);
    procedure SetPageControl(const Value: TPPGPageControl);
    procedure PaneStep(Sender: TObject);
    procedure IndicatorStep(Sender: TObject);
    procedure ApplyPaneWidth;
    procedure BuildRows;
    procedure AddRows(List: TList<TPPGNavItem>; Items: TPPGNavItems; Footer: Boolean);
    function RowHeight(Item: TPPGNavItem): Integer;
    function PaneOpenNow: Boolean;
    function MenuRect: TRect;
    function MainTop: Integer;
    function FooterTop: Integer;
    function RowCountAll: Integer;
    function RowItem(Row: Integer): TPPGNavItem;
    function IndicatorItem: TPPGNavItem;
    function IndicatorY(Item: TPPGNavItem): Integer;
    procedure MoveIndicator(Animate: Boolean);
    procedure EnsureVisible(Item: TPPGNavItem);
    procedure MaxScroll(out Max: Integer);
    procedure ShowPage(Item: TPPGNavItem);
    procedure CheckAutoMode;
    procedure AttachParentWatch;
    procedure DetachParentWatch;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    /// Bildnamen der Eintraege neu aufloesen (ImageName).
    procedure ImagesChanged; override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure WndProc(var Message: TMessage); override;
    procedure Resize; override;
    procedure SetParent(AParent: TWinControl); override;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure ItemsChanged; virtual;
    /// Eintrag durch den Anwender ausloesen (Klick, Enter, Screenreader).
    procedure InvokeItem(Item: TPPGNavItem); virtual;
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
    procedure BeginItemsUpdate;
    procedure EndItemsUpdate;
    /// Menue-Knopf wie per Klick (OnPaneChange).
    procedure TogglePane;
    /// Zeile (sichtbar: Haupt- und Fussbereich) unter dem Punkt, -1 = keine,
    /// -2 = Menue-Knopf.
    function RowAt(X, Y: Integer): Integer;
    function RowRect(Row: Integer): TRect;
    function RowOfItem(Item: TPPGNavItem): Integer;
    /// Sichtbare Zeilen (Haupt- dann Fussbereich).
    function VisibleRowCount: Integer;
    function VisibleRow(Row: Integer): TPPGNavItem;
    /// Ersten Eintrag mit diesem Text suchen (auch in Untereintraegen).
    function FindItem(const ACaption: string): TPPGNavItem;
    /// Aktuelle Y-Mitte des Indikators (fuer Tests).
    function IndicatorPos: Integer;
    property Selected: TPPGNavItem read FSelected write SetSelected;
    property FocusItem: TPPGNavItem read FFocusItem;
    property HotRow: Integer read FHotRow;
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighContrastSupport;
    property Images;
    property Items: TPPGNavItems read FItems write SetItems;
    /// Startauswahl (Index in Items, auch im Designer); -1 = keine.
    property SelectedIndex: Integer read GetSelectedIndex write SetSelectedIndex default -1;
    property IsPaneOpen: Boolean read FIsPaneOpen write SetIsPaneOpen default True;
    property DisplayMode: TPPGNavDisplayMode read FDisplayMode write SetDisplayMode default pdmLeft;
    /// Breiten in logischen px (96 DPI).
    property OpenPaneLength: Integer read FOpenPaneLength write SetOpenPaneLength default 280;
    property CompactPaneLength: Integer read FCompactPaneLength write SetCompactPaneLength default 48;
    property CompactModeThresholdWidth: Integer read FCompactThreshold write SetCompactModeThresholdWidth default 640;
    property PaneTitle: string read FPaneTitle write SetPaneTitle;
    property ShowMenuButton: Boolean read FShowMenuButton write SetShowMenuButton default True;
    /// itTextColor: Symbole einfarbig in der Textfarbe (Hover, Dunkel, Deaktiviert).
    property ImageTint: TPPGImageTint read FImageTint write SetImageTint default itNone;
    property PageControl: TPPGPageControl read FPageControl write SetPageControl;
    /// Bereiche der Leiste (Hintergrund, Eintraege, Hover, Auswahl, Ueberschriften).
    property Styles: TPPGNavStyles read FNavStyles write SetNavStyles;
    /// Vor dem Zeichnen jedes Eintrags: Style anpassen oder selbst zeichnen.
    property OnCustomDrawItem: TPPGNavCustomDrawEvent read FOnCustomDrawItem write FOnCustomDrawItem;
    property Align default alLeft;
    property Anchors;
    property BiDiMode;
    property Color;
    property Constraints;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Touch;
    property OnGesture;
    property OnEnter;
    property OnExit;
    property OnItemClick: TPPGNavItemEvent read FOnItemInvoked write FOnItemInvoked;
    property OnPaneChange: TNotifyEvent read FOnPaneChange write FOnPaneChange;
    property OnChange: TNotifyEvent read FOnSelectionChange write FOnSelectionChange;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseActivate;
    property OnContextPopup;
    property StyleElements;
    property DragMode;
    property DragCursor;
    property OnDragDrop;
    property OnDragOver;
    property OnStartDrag;
    property OnEndDrag;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

const
  /// Zeichen der Symbolschrift fuer haeufige Eintraege.
  PPGNavIconHome = $E80F;
  PPGNavIconSettings = $E713;
  PPGNavIconDocument = $E8A5;
  PPGNavIconMail = $E715;
  PPGNavIconPeople = $E716;
  PPGNavIconCalendar = $E787;
  PPGNavIconList = $EA37;
  PPGNavIconFolder = $E8B7;
  PPGNavIconEdit = $E70F;
  PPGNavIconFavorite = $E734;
  PPGNavIconTable = $E80A;
  PPGNavIconTree = $E8F1;
  PPGNavIconColor = $E790;
  PPGNavIconInfo = $E946;

implementation

uses
  PPG.Lang,
  System.Math, Winapi.oleacc,
  PPG.Consts, PPG.Appearance, PPG.DpiUtils, PPG.Tokens, PPG.IconFont, PPG.ItemPainter,
  PPG.Render.Gdi;

const
  RowH = 40;
  HeaderRowH = 32;
  SepRowH = 9;
  MenuH = 44;
  IndentW = 16;
  RowInset = 4;

var
  GMsgNavAction: Cardinal = 0;

type
  /// Beobachtet WM_SIZE des Parents (fuer DisplayMode pdmAuto). Gehoert dem
  /// Parent und bleibt bis zu dessen Ende in der Kette der Fensterprozeduren,
  /// auch wenn die Leiste vorher freigegeben wird (sonst bricht die Kette).
  TPPGParentWatcher = class(TComponent)
  private
    FTarget: TWinControl;
    FOldProc: TWndMethod;
    FClients: TList<TPPGNavigationView>;
    procedure WatchProc(var Message: TMessage);
  public
    constructor CreateFor(ATarget: TWinControl);
    destructor Destroy; override;
  end;

constructor TPPGParentWatcher.CreateFor(ATarget: TWinControl);
begin
  inherited Create(ATarget);
  FTarget := ATarget;
  FClients := TList<TPPGNavigationView>.Create;
  FOldProc := ATarget.WindowProc;
  ATarget.WindowProc := WatchProc;
end;

destructor TPPGParentWatcher.Destroy;
var
  M: TWndMethod;
begin
  // Nur zuruecksetzen, wenn niemand nach uns eingehaengt hat
  M := WatchProc;
  if (FTarget <> nil) and (TMethod(FTarget.WindowProc).Code = TMethod(M).Code) and
    (TMethod(FTarget.WindowProc).Data = Self) then
    FTarget.WindowProc := FOldProc;
  FreeAndNil(FClients);
  inherited Destroy;
end;

procedure TPPGParentWatcher.WatchProc(var Message: TMessage);
var
  I: Integer;
begin
  FOldProc(Message);
  if (Message.Msg = WM_SIZE) and (FClients <> nil) then
    for I := FClients.Count - 1 downto 0 do
      FClients[I].CheckAutoMode;
end;

function FindWatcher(P: TWinControl): TPPGParentWatcher;
var
  I: Integer;
begin
  for I := 0 to P.ComponentCount - 1 do
    if P.Components[I] is TPPGParentWatcher then
      Exit(TPPGParentWatcher(P.Components[I]));
  Result := nil;
end;

{ TPPGNavItem }

{$IFDEF PPG_HAS_IMAGENAME}
procedure TPPGNavItem.ResolveImageName;
var
  Imgs: TCustomImageList;
begin
  Imgs := PPGImagesOf(Self);
  // Unbekannter Name: -1 (die Liste kann zur Laufzeit befuellt werden)
  if (FImageName <> '') and (Imgs <> nil) and Imgs.IsImageNameAvailable then
    ImageIndex := Imgs.GetIndexByName(FImageName);
end;

procedure TPPGNavItem.SetImageName(const Value: TImageName);
begin
  if FImageName = Value then
    Exit;
  FImageName := Value;
  ResolveImageName;
end;
{$ENDIF}


constructor TPPGNavItem.Create(Collection: TCollection);
begin
  FImageIndex := -1;
  FEnabled := True;
  FVisible := True;
  FPageIndex := -1;
  FColor := clDefault;
  FTextColor := clDefault;
  FItems := TPPGNavItems.Create(Self);
  inherited Create(Collection);
end;

destructor TPPGNavItem.Destroy;
var
  N: TPPGNavigationView;
  P: TPPGNavItem;
begin
  N := NavigationView;
  if N <> nil then
  begin
    // Verweise der Leiste auf diesen Eintrag oder einen Nachfahren loesen
    P := N.FSelected;
    while P <> nil do
    begin
      if P = Self then
      begin
        N.FSelected := nil;
        Break;
      end;
      P := P.ParentItem;
    end;
    P := N.FFocusItem;
    while P <> nil do
    begin
      if P = Self then
      begin
        N.FFocusItem := nil;
        Break;
      end;
      P := P.ParentItem;
    end;
    N.FRowsValid := False;
  end;
  FItems.Clear;
  inherited Destroy;
  FreeAndNil(FItems);
end;

procedure TPPGNavItem.Assign(Source: TPersistent);
var
  S: TPPGNavItem;
begin
  if Source is TPPGNavItem then
  begin
    S := TPPGNavItem(Source);
    FCaption := S.FCaption;
    FKind := S.FKind;
    FIconChar := S.FIconChar;
    FImageIndex := S.FImageIndex;
    FBadgeCount := S.FBadgeCount;
    FBadgeDot := S.FBadgeDot;
    FEnabled := S.FEnabled;
    FVisible := S.FVisible;
    FFooter := S.FFooter;
    FPageIndex := S.FPageIndex;
    FExpanded := S.FExpanded;
    FHint := S.FHint;
    FTag := S.FTag;
    FColor := S.FColor;
    FTextColor := S.FTextColor;
    FFontStyle := S.FFontStyle;
    FItems.Assign(S.FItems);
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGNavItem.GetDisplayName: string;
begin
  case FKind of
    nikSeparator: Result := '-';
    nikHeader: Result := '[' + FCaption + ']';
  else
    Result := FCaption;
  end;
  if Result = '' then
    Result := inherited GetDisplayName;
end;

function TPPGNavItem.NavigationView: TPPGNavigationView;
begin
  if Collection is TPPGNavItems then
    Result := TPPGNavItems(Collection).NavigationView
  else
    Result := nil;
end;

function TPPGNavItem.GetParentItem: TPPGNavItem;
begin
  if (Collection <> nil) and (Collection.Owner is TPPGNavItem) then
    Result := TPPGNavItem(Collection.Owner)
  else
    Result := nil;
end;

function TPPGNavItem.GetLevel: Integer;
var
  P: TPPGNavItem;
begin
  Result := 0;
  P := GetParentItem;
  while P <> nil do
  begin
    Inc(Result);
    P := P.GetParentItem;
  end;
end;

function TPPGNavItem.HasChildren: Boolean;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    if FItems[I].Visible then
      Exit(True);
  Result := False;
end;

function TPPGNavItem.Selectable: Boolean;
begin
  Result := (FKind = nikItem) and FVisible and FEnabled and not HasChildren;
end;

procedure TPPGNavItem.SetPageIndex(const Value: Integer);
var
  P: TPersistent;
begin
  if FPageIndex = Value then
    Exit;
  FPageIndex := Value;
  // Gewaehlter Eintrag: die neue Seite gleich zeigen (wie beim Waehlen)
  P := Collection;
  while (P is TCollection) and (TCollection(P).Owner <> nil) do
  begin
    P := TCollection(P).Owner;
    if P is TPPGNavigationView then
    begin
      if TPPGNavigationView(P).Selected = Self then
        TPPGNavigationView(P).ShowPage(Self);
      Break;
    end;
    if P is TCollectionItem then
      P := TCollectionItem(P).Collection;
  end;
end;

procedure TPPGNavItem.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

procedure TPPGNavItem.SetKind(const Value: TPPGNavItemKind);
begin
  if FKind <> Value then
  begin
    FKind := Value;
    Changed(False);
  end;
end;

procedure TPPGNavItem.SetIconChar(const Value: Word);
begin
  if FIconChar <> Value then
  begin
    FIconChar := Value;
    Changed(False);
  end;
end;

procedure TPPGNavItem.SetImageIndex(const Value: TPPGImageIndex);
begin
  if FImageIndex <> Value then
  begin
    FImageIndex := Value;
    Changed(False);
  end;
end;

procedure TPPGNavItem.SetBadgeCount(const Value: Integer);
begin
  if FBadgeCount <> Value then
  begin
    FBadgeCount := PPGCheckRange(Self, 'BadgeCount', Value, 0, MaxInt);
    Changed(False);
  end;
end;

procedure TPPGNavItem.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Changed(False);
  end;
end;

procedure TPPGNavItem.SetTextColor(const Value: TColor);
begin
  if FTextColor <> Value then
  begin
    FTextColor := Value;
    Changed(False);
  end;
end;

procedure TPPGNavItem.SetFontStyle(const Value: TFontStyles);
begin
  if FFontStyle <> Value then
  begin
    FFontStyle := Value;
    Changed(False);
  end;
end;

procedure TPPGNavItem.SetBadgeDot(const Value: Boolean);
begin
  if FBadgeDot <> Value then
  begin
    FBadgeDot := Value;
    Changed(False);
  end;
end;

procedure TPPGNavItem.SetEnabled(const Value: Boolean);
begin
  if FEnabled <> Value then
  begin
    FEnabled := Value;
    Changed(False);
  end;
end;

procedure TPPGNavItem.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    Changed(False);
  end;
end;

procedure TPPGNavItem.SetFooter(const Value: Boolean);
begin
  if FFooter <> Value then
  begin
    FFooter := Value;
    Changed(False);
  end;
end;

procedure TPPGNavItem.SetExpanded(const Value: Boolean);
begin
  if FExpanded <> Value then
  begin
    FExpanded := Value;
    Changed(False);
  end;
end;

procedure TPPGNavItem.SetItems(const Value: TPPGNavItems);
begin
  FItems.Assign(Value);
end;

{ TPPGNavItems }

constructor TPPGNavItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TPPGNavItem);
end;

function TPPGNavItems.GetItem(Index: Integer): TPPGNavItem;
begin
  Result := TPPGNavItem(inherited Items[Index]);
end;

function TPPGNavItems.Add: TPPGNavItem;
begin
  Result := TPPGNavItem(inherited Add);
end;

function TPPGNavItems.AddItem(const ACaption: string; AIconChar: Word;
  APageIndex: Integer): TPPGNavItem;
begin
  Result := Add;
  Result.FCaption := ACaption;
  Result.FIconChar := AIconChar;
  Result.FPageIndex := APageIndex;
  Result.Changed(False);
end;

function TPPGNavItems.AddHeader(const ACaption: string): TPPGNavItem;
begin
  Result := Add;
  Result.FCaption := ACaption;
  Result.FKind := nikHeader;
  Result.Changed(False);
end;

function TPPGNavItems.AddSeparator: TPPGNavItem;
begin
  Result := Add;
  Result.FKind := nikSeparator;
  Result.Changed(False);
end;

function TPPGNavItems.NavigationView: TPPGNavigationView;
var
  O: TPersistent;
begin
  O := Owner;
  while O is TPPGNavItem do
    O := TPPGNavItem(O).Collection.Owner;
  if O is TPPGNavigationView then
    Result := TPPGNavigationView(O)
  else
    Result := nil;
end;

procedure TPPGNavItems.Update(Item: TCollectionItem);
var
  N: TPPGNavigationView;
begin
  inherited Update(Item);
  N := NavigationView;
  if N <> nil then
    N.ItemsChanged;
end;

procedure TPPGNavItems.Notify(Item: TCollectionItem; Action: TCollectionNotification);
var
  N: TPPGNavigationView;
begin
  inherited Notify(Item, Action);
  N := NavigationView;
  if N = nil then
    Exit;
  if Action in [cnExtracting, cnDeleting] then
  begin
    if N.FSelected = Item then
      N.FSelected := nil;
    if N.FFocusItem = Item then
      N.FFocusItem := nil;
  end;
  N.FRowsValid := False;
end;

{ TPPGNavigationView }

{ TPPGNavStyles }

constructor TPPGNavStyles.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, 7);
end;

{ TPPGNavigationView }

procedure TPPGNavigationView.ImagesChanged;
{$IFDEF PPG_HAS_IMAGENAME}
  procedure Walk(Items: TPPGNavItems);
  var
    I: Integer;
  begin
    for I := 0 to Items.Count - 1 do
    begin
      Items[I].ResolveImageName;
      Walk(Items[I].Items);
    end;
  end;
{$ENDIF}
begin
  inherited ImagesChanged;
{$IFDEF PPG_HAS_IMAGENAME}
  Walk(FItems);
{$ENDIF}
end;


procedure TPPGNavigationView.DrawItemImage(const ACanvas: IPPGCanvas; Index, X, Y: Integer;
  AEnabled: Boolean; Color: TColor);
var
  DC: HDC;
begin
  if FImageTint = itNone then
  begin
    ACanvas.DrawImage(Images, Index, X, Y, AEnabled);
    Exit;
  end;
  DC := ACanvas.BeginGdi;
  try
    PPGGdiDrawImageTinted(DC, Images, Index, X, Y, Color);
  finally
    ACanvas.EndGdi(DC);
  end;
end;

procedure TPPGNavigationView.SetImageTint(const Value: TPPGImageTint);
begin
  if FImageTint <> Value then
  begin
    FImageTint := Value;
    Invalidate;
  end;
end;

constructor TPPGNavigationView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption, csDoubleClicks]; // Audit 5d: OnClick wie TControl
  FItems := TPPGNavItems.Create(Self);
  FNavStyles := TPPGNavStyles.Create(Self);
  FNavStyles.OnChange := NavStylesChanged;
  FDrawCanvas := TCanvas.Create;
  FFonts := TPPGFontCache.Create;
  FRows := TList<TPPGNavItem>.Create;
  FFooterRows := TList<TPPGNavItem>.Create;
  FHotRow := -1;
  FDownRow := -1;
  FIsPaneOpen := True;
  FOpenPaneLength := 280;
  FCompactPaneLength := 48;
  FCompactThreshold := 640;
  FLoadedSelectedIndex := -1;
  FShowMenuButton := True;
  FPaneAnim := TPPGAnimation.Create(Self);
  FPaneAnim.Jump(1);
  FPaneAnim.OnStep := PaneStep;
  FIndicatorAnim := TPPGAnimation.Create(Self);
  FIndicatorAnim.Jump(1);
  FIndicatorAnim.OnStep := IndicatorStep;
  TabStop := True;
  Align := alLeft;
  Width := 280;
  Height := 400;
  if GMsgNavAction = 0 then
    GMsgNavAction := RegisterWindowMessage('PPGlow.NavigationAction');
end;

destructor TPPGNavigationView.Destroy;
begin
  DetachParentWatch;
  if FPaneAnim <> nil then
    FPaneAnim.OnStep := nil;
  if FIndicatorAnim <> nil then
    FIndicatorAnim.OnStep := nil;
  FreeAndNil(FPaneAnim);
  FreeAndNil(FIndicatorAnim);
  FSelected := nil;
  FFocusItem := nil;
  FreeAndNil(FItems);
  FreeAndNil(FRows);
  FreeAndNil(FFooterRows);
  FreeAndNil(FFonts);
  FreeAndNil(FDrawCanvas);
  FreeAndNil(FNavStyles);
  inherited Destroy;
end;

procedure TPPGNavigationView.SetNavStyles(const Value: TPPGNavStyles);
begin
  FNavStyles.Assign(Value);
end;

procedure TPPGNavigationView.NavStylesChanged(Sender: TObject);
begin
  Invalidate;
end;

function TPPGNavigationView.GetSelectedIndex: Integer;
begin
  if (FSelected <> nil) and (FSelected.Collection = FItems) then
    Result := FSelected.Index
  else
    Result := -1;
end;

procedure TPPGNavigationView.SetSelectedIndex(const Value: Integer);
begin
  if csLoading in ComponentState then
  begin
    FLoadedSelectedIndex := Value; // Items kommen in der DFM ggf. spaeter
    Exit;
  end;
  if Value < 0 then
    Selected := nil
  else
    Selected := FItems[PPGCheckRange(Self, 'SelectedIndex', Value, 0, FItems.Count - 1)];
end;

procedure TPPGNavigationView.Loaded;
begin
  inherited Loaded;
  if (FLoadedSelectedIndex >= 0) and (FLoadedSelectedIndex < FItems.Count) then
    Selected := FItems[FLoadedSelectedIndex];
  FLoadedSelectedIndex := -1;
  FRowsValid := False;
  CheckAutoMode;
  if PaneOpenNow then
    FPaneAnim.Jump(1)
  else
    FPaneAnim.Jump(0);
  ApplyPaneWidth;
end;

procedure TPPGNavigationView.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FPageControl) then
    FPageControl := nil;
end;

function TPPGNavigationView.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGNavigationView.IsDown: Boolean;
begin
  Result := False;
end;

procedure TPPGNavigationView.BeginItemsUpdate;
begin
  Inc(FUpdating);
  FItems.BeginUpdate;
end;

procedure TPPGNavigationView.EndItemsUpdate;
begin
  FItems.EndUpdate;
  Dec(FUpdating);
  if FUpdating = 0 then
    ItemsChanged;
end;

procedure TPPGNavigationView.ItemsChanged;
begin
  if (FUpdating > 0) or (csDestroying in ComponentState) then
    Exit;
  FRowsValid := False;
  MoveIndicator(False);
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

procedure TPPGNavigationView.SetItems(const Value: TPPGNavItems);
begin
  FItems.Assign(Value);
end;

{ ---- Zeilen ---- }

procedure TPPGNavigationView.AddRows(List: TList<TPPGNavItem>; Items: TPPGNavItems; Footer: Boolean);
var
  I: Integer;
  It: TPPGNavItem;
begin
  for I := 0 to Items.Count - 1 do
  begin
    It := Items[I];
    if not It.Visible then
      Continue;
    // Fussbereich gilt nur auf oberster Ebene
    if (It.Level = 0) and (It.Footer <> Footer) then
      Continue;
    // Kompakt: keine Ueberschriften (nur Trenner) und keine Untereintraege
    if not PaneOpenNow and (It.Kind = nikHeader) then
      Continue;
    List.Add(It);
    if (It.Kind = nikItem) and It.Expanded and PaneOpenNow and It.HasChildren then
      AddRows(List, It.Items, Footer);
  end;
end;

procedure TPPGNavigationView.BuildRows;
var
  I, Y: Integer;
begin
  if FRowsValid and (FRowsPPI = ScalePPI) then
    Exit;
  FRows.Clear;
  FFooterRows.Clear;
  AddRows(FRows, FItems, False);
  AddRows(FFooterRows, FItems, True);
  FRowsPPI := ScalePPI;
  // Zeilenanfaenge einmal berechnen: RowRect/RowAt ohne Summieren (O(1)/O(log n))
  SetLength(FMainTops, FRows.Count);
  Y := 0;
  for I := 0 to FRows.Count - 1 do
  begin
    FMainTops[I] := Y;
    Inc(Y, RowHeight(FRows[I]));
  end;
  FMainHeight := Y;
  SetLength(FFooterTops, FFooterRows.Count);
  Y := 0;
  for I := 0 to FFooterRows.Count - 1 do
  begin
    FFooterTops[I] := Y;
    Inc(Y, RowHeight(FFooterRows[I]));
  end;
  FFooterHeight := Y;
  FRowsValid := True;
end;

function TPPGNavigationView.RowHeight(Item: TPPGNavItem): Integer;
begin
  case Item.Kind of
    nikHeader: Result := PPGScale(HeaderRowH, ScalePPI);
    nikSeparator: Result := PPGScale(SepRowH, ScalePPI);
  else
    Result := PPGScale(RowH, ScalePPI);
  end;
end;

function TPPGNavigationView.PaneOpenNow: Boolean;
begin
  case FDisplayMode of
    pdmLeftCompact: Result := FIsPaneOpen;
    pdmAuto: Result := FIsPaneOpen and not FAutoCompact;
  else
    Result := FIsPaneOpen;
  end;
end;

function TPPGNavigationView.MenuRect: TRect;
var
  C: Integer;
begin
  if not FShowMenuButton then
    Exit(Rect(0, 0, 0, 0));
  C := PPGScale(FCompactPaneLength, ScalePPI);
  Result := Rect(PPGScale(RowInset, ScalePPI), PPGScale(4, ScalePPI),
    C - PPGScale(RowInset, ScalePPI), PPGScale(MenuH, ScalePPI) - PPGScale(4, ScalePPI));
  if UseRightToLeftAlignment then
    Result := Rect(Width - Result.Right, Result.Top, Width - Result.Left, Result.Bottom);
end;

function TPPGNavigationView.MainTop: Integer;
begin
  if FShowMenuButton or (FPaneTitle <> '') then
    Result := PPGScale(MenuH, ScalePPI)
  else
    Result := PPGScale(4, ScalePPI);
end;

function TPPGNavigationView.FooterTop: Integer;
begin
  BuildRows;
  Result := Height - FFooterHeight - PPGScale(4, ScalePPI);
end;

function TPPGNavigationView.RowCountAll: Integer;
begin
  BuildRows;
  Result := FRows.Count + FFooterRows.Count;
end;

function TPPGNavigationView.VisibleRowCount: Integer;
begin
  Result := RowCountAll;
end;

function TPPGNavigationView.RowItem(Row: Integer): TPPGNavItem;
begin
  BuildRows;
  if (Row >= 0) and (Row < FRows.Count) then
    Result := FRows[Row]
  else if (Row >= FRows.Count) and (Row < FRows.Count + FFooterRows.Count) then
    Result := FFooterRows[Row - FRows.Count]
  else
    Result := nil;
end;

function TPPGNavigationView.VisibleRow(Row: Integer): TPPGNavItem;
begin
  Result := RowItem(Row);
end;

function TPPGNavigationView.RowOfItem(Item: TPPGNavItem): Integer;
var
  I: Integer;
begin
  BuildRows;
  I := FRows.IndexOf(Item);
  if I >= 0 then
    Exit(I);
  I := FFooterRows.IndexOf(Item);
  if I >= 0 then
    Exit(FRows.Count + I);
  Result := -1;
end;

function TPPGNavigationView.RowRect(Row: Integer): TRect;
var
  Y: Integer;
begin
  BuildRows;
  if (Row < 0) or (Row >= RowCountAll) then
    Exit(Rect(0, 0, 0, 0));
  if Row < FRows.Count then
  begin
    Y := MainTop - FScrollY + FMainTops[Row];
    Result := Rect(0, Y, Width, Y + RowHeight(FRows[Row]));
  end
  else
  begin
    Y := FooterTop + FFooterTops[Row - FRows.Count];
    Result := Rect(0, Y, Width, Y + RowHeight(FFooterRows[Row - FRows.Count]));
  end;
end;

function TPPGNavigationView.RowAt(X, Y: Integer): Integer;
var
  I, Lo, Hi, Mid, Rel: Integer;
  R: TRect;
begin
  if PtInRect(MenuRect, Point(X, Y)) then
    Exit(-2);
  if (X < 0) or (X >= Width) then
    Exit(-1);
  BuildRows;
  // Fussbereich (wenige Zeilen)
  for I := 0 to FFooterRows.Count - 1 do
  begin
    R := RowRect(FRows.Count + I);
    if (Y >= R.Top) and (Y < R.Bottom) then
      Exit(FRows.Count + I);
  end;
  // Hauptzeilen nur zwischen Kopf und Fussbereich; binaere Suche
  if (Y < MainTop) or (Y >= FooterTop) or (FRows.Count = 0) then
    Exit(-1);
  Rel := Y - MainTop + FScrollY;
  if (Rel < 0) or (Rel >= FMainHeight) then
    Exit(-1);
  Lo := 0;
  Hi := FRows.Count - 1;
  while Lo < Hi do
  begin
    Mid := (Lo + Hi + 1) div 2;
    if FMainTops[Mid] <= Rel then
      Lo := Mid
    else
      Hi := Mid - 1;
  end;
  Result := Lo;
end;

procedure TPPGNavigationView.MaxScroll(out Max: Integer);
begin
  BuildRows;
  Max := FMainHeight - (FooterTop - MainTop);
  if Max < 0 then
    Max := 0;
end;

procedure TPPGNavigationView.EnsureVisible(Item: TPPGNavItem);
var
  Row, M: Integer;
  R: TRect;
begin
  Row := RowOfItem(Item);
  if (Row < 0) or (Row >= FRows.Count) then
    Exit;
  R := RowRect(Row);
  if R.Top < MainTop then
    Dec(FScrollY, MainTop - R.Top)
  else if R.Bottom > FooterTop then
    Inc(FScrollY, R.Bottom - FooterTop);
  MaxScroll(M);
  FScrollY := EnsureRange(FScrollY, 0, M);
end;

function TPPGNavigationView.FindItem(const ACaption: string): TPPGNavItem;

  function Search(Items: TPPGNavItems): TPPGNavItem;
  var
    I: Integer;
  begin
    for I := 0 to Items.Count - 1 do
    begin
      if SameText(Items[I].Caption, ACaption) then
        Exit(Items[I]);
      Result := Search(Items[I].Items);
      if Result <> nil then
        Exit;
    end;
    Result := nil;
  end;

begin
  Result := Search(FItems);
end;

{ ---- Auswahl und Indikator ---- }

function TPPGNavigationView.IndicatorItem: TPPGNavItem;
begin
  // Gewaehlter Eintrag bzw. sein sichtbarer Vorfahr
  Result := FSelected;
  while (Result <> nil) and (RowOfItem(Result) < 0) do
    Result := Result.ParentItem;
end;

function TPPGNavigationView.IndicatorY(Item: TPPGNavItem): Integer;
var
  R: TRect;
begin
  if Item = nil then
    Exit(-1);
  R := RowRect(RowOfItem(Item));
  Result := (R.Top + R.Bottom) div 2;
end;

procedure TPPGNavigationView.MoveIndicator(Animate: Boolean);
var
  NewY: Integer;
begin
  NewY := IndicatorY(IndicatorItem);
  if Animate and (FIndicatorTo >= 0) and (NewY >= 0) and HandleAllocated and Showing and
    Animation.EffectiveEnabled then
  begin
    FIndicatorFrom := IndicatorPos;
    FIndicatorTo := NewY;
    FIndicatorAnim.Jump(0);
    FIndicatorAnim.AnimateTo(1, Cardinal(Animation.Duration) + 80, ekDecelerate);
  end
  else
  begin
    FIndicatorFrom := NewY;
    FIndicatorTo := NewY;
    FIndicatorAnim.Jump(1);
  end;
end;

function TPPGNavigationView.IndicatorPos: Integer;
begin
  Result := FIndicatorFrom + Round((FIndicatorTo - FIndicatorFrom) * FIndicatorAnim.Value);
end;

procedure TPPGNavigationView.IndicatorStep(Sender: TObject);
begin
  Invalidate;
end;

procedure TPPGNavigationView.SetSelected(const Value: TPPGNavItem);
var
  P: TPPGNavItem;
begin
  if FSelected = Value then
    Exit;
  if (Value <> nil) and (Value.NavigationView <> Self) then
    Exit;
  FSelected := Value;
  if Value <> nil then
  begin
    FFocusItem := Value;
    // Vorfahren aufklappen, damit die Auswahl sichtbar ist
    P := Value.ParentItem;
    while P <> nil do
    begin
      if not P.FExpanded then
      begin
        P.FExpanded := True;
        FRowsValid := False;
      end;
      P := P.ParentItem;
    end;
    EnsureVisible(Value);
  end;
  ShowPage(FSelected); // Folge der Auswahl, kein Ereignis
  MoveIndicator(True);
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_SELECTION);
end;

procedure TPPGNavigationView.ShowPage(Item: TPPGNavItem);
begin
  if (FPageControl <> nil) and (Item <> nil) and (Item.PageIndex >= 0) and
    (Item.PageIndex < FPageControl.PageCount) then
    FPageControl.ActivePageIndex := Item.PageIndex;
end;

procedure TPPGNavigationView.InvokeItem(Item: TPPGNavItem);
var
  Old: TPPGNavItem;
begin
  if (Item = nil) or (Item.Kind <> nikItem) or not Item.Enabled or not Enabled then
    Exit;
  FFocusItem := Item;
  if Item.HasChildren then
  begin
    // Elterneintrag: aufklappen (kompakt: erst die Leiste oeffnen)
    if not PaneOpenNow then
    begin
      Item.FExpanded := True;
      TogglePane;
    end
    else
    begin
      Item.FExpanded := not Item.FExpanded;
      FRowsValid := False;
      MoveIndicator(False);
    end;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_REORDER);
    if Assigned(FOnItemInvoked) then
      FOnItemInvoked(Self, Item);
    Exit;
  end;
  Old := FSelected;
  FSelected := Item;
  MoveIndicator(Old <> nil);
  Invalidate;
  if Assigned(FOnItemInvoked) then
    FOnItemInvoked(Self, Item);
  if FSelected <> Old then
  begin
    ShowPage(FSelected);
    NotifyAccessibilityChild(EVENT_OBJECT_SELECTION, RowOfItem(FSelected) + 1);
    if Assigned(FOnSelectionChange) then
      FOnSelectionChange(Self);
  end;
end;

{ ---- Leiste ---- }

procedure TPPGNavigationView.SetIsPaneOpen(const Value: Boolean);
begin
  if FIsPaneOpen = Value then
    Exit;
  FIsPaneOpen := Value;
  if csLoading in ComponentState then
    Exit;
  FRowsValid := False;
  if HandleAllocated and Showing and Animation.EffectiveEnabled and
    not (csDesigning in ComponentState) then
  begin
    if PaneOpenNow then
      FPaneAnim.AnimateTo(1, Cardinal(Animation.Duration) + 80, ekDecelerate)
    else
      FPaneAnim.AnimateTo(0, Cardinal(Animation.Duration) + 80, ekDecelerate);
  end
  else
  begin
    if PaneOpenNow then
      FPaneAnim.Jump(1)
    else
      FPaneAnim.Jump(0);
    ApplyPaneWidth;
  end;
  MoveIndicator(False);
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

procedure TPPGNavigationView.TogglePane;
begin
  SetIsPaneOpen(not FIsPaneOpen);
  if FAutoCompact and FIsPaneOpen and (FDisplayMode = pdmAuto) then
  begin
    // Auto zu schmal: oeffnen hebt die Kompakt-Automatik auf
    FAutoCompact := False;
    SetIsPaneOpen(True);
    FRowsValid := False;
    FPaneAnim.Jump(1);
    ApplyPaneWidth;
  end;
  if Assigned(FOnPaneChange) then
    FOnPaneChange(Self);
end;

procedure TPPGNavigationView.PaneStep(Sender: TObject);
begin
  ApplyPaneWidth;
end;

procedure TPPGNavigationView.ApplyPaneWidth;
var
  W, O, C: Integer;
begin
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  if not (Align in [alLeft, alRight]) and (Align <> alNone) then
  begin
    Invalidate;
    Exit;
  end;
  O := PPGScale(FOpenPaneLength, ScalePPI);
  C := PPGScale(FCompactPaneLength, ScalePPI);
  W := C + Round((O - C) * FPaneAnim.Value);
  if W <> Width then
  begin
    FInternalSize := True;
    try
      Width := W;
    finally
      FInternalSize := False;
    end;
  end;
  MoveIndicator(False);
  Invalidate;
end;

procedure TPPGNavigationView.SetCompactModeThresholdWidth(const Value: Integer);
begin
  if FCompactThreshold = Value then
    Exit;
  FCompactThreshold := PPGCheckRange(Self, 'CompactModeThresholdWidth', Value, 0, 100000);
  CheckAutoMode;
end;

procedure TPPGNavigationView.CheckAutoMode;
var
  Narrow: Boolean;
begin
  if (FDisplayMode <> pdmAuto) or (Parent = nil) then
  begin
    FAutoCompact := False;
    Exit;
  end;
  Narrow := Parent.ClientWidth < PPGScale(FCompactThreshold, ScalePPI);
  if Narrow <> FAutoCompact then
  begin
    FAutoCompact := Narrow;
    FRowsValid := False;
    if PaneOpenNow then
      FPaneAnim.Jump(1)
    else
      FPaneAnim.Jump(0);
    ApplyPaneWidth;
  end;
end;

procedure TPPGNavigationView.SetParent(AParent: TWinControl);
begin
  DetachParentWatch;
  inherited SetParent(AParent);
  AttachParentWatch;
end;

procedure TPPGNavigationView.AttachParentWatch;
var
  W: TPPGParentWatcher;
begin
  if (Parent = nil) or (csDesigning in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  W := FindWatcher(Parent);
  if W = nil then
    W := TPPGParentWatcher.CreateFor(Parent);
  if W.FClients.IndexOf(Self) < 0 then
    W.FClients.Add(Self);
  FWatched := Parent;
end;

procedure TPPGNavigationView.DetachParentWatch;
var
  W: TPPGParentWatcher;
begin
  if FWatched = nil then
    Exit;
  W := FindWatcher(FWatched);
  if (W <> nil) and (W.FClients <> nil) then
    W.FClients.Remove(Self);
  FWatched := nil;
end;

procedure TPPGNavigationView.Resize;
begin
  inherited Resize;
  if not FInternalSize then
  begin
    CheckAutoMode;
    MoveIndicator(False);
  end;
end;

procedure TPPGNavigationView.SetDisplayMode(const Value: TPPGNavDisplayMode);
begin
  if FDisplayMode <> Value then
  begin
    FDisplayMode := Value;
    if Value = pdmLeftCompact then
      FIsPaneOpen := False;
    FRowsValid := False;
    CheckAutoMode;
    if PaneOpenNow then
      FPaneAnim.Jump(1)
    else
      FPaneAnim.Jump(0);
    ApplyPaneWidth;
  end;
end;

procedure TPPGNavigationView.SetOpenPaneLength(const Value: Integer);
begin
  FOpenPaneLength := PPGCheckRange(Self, 'OpenPaneLength', Value, 48, 2000);
  ApplyPaneWidth;
end;

procedure TPPGNavigationView.SetCompactPaneLength(const Value: Integer);
begin
  FCompactPaneLength := PPGCheckRange(Self, 'CompactPaneLength', Value, 24, 200);
  ApplyPaneWidth;
end;

procedure TPPGNavigationView.SetPaneTitle(const Value: string);
begin
  if FPaneTitle <> Value then
  begin
    FPaneTitle := Value;
    Invalidate;
  end;
end;

procedure TPPGNavigationView.SetShowMenuButton(const Value: Boolean);
begin
  if FShowMenuButton <> Value then
  begin
    FShowMenuButton := Value;
    MoveIndicator(False);
    Invalidate;
  end;
end;

procedure TPPGNavigationView.SetPageControl(const Value: TPPGPageControl);
begin
  if FPageControl <> Value then
  begin
    if FPageControl <> nil then
      FPageControl.RemoveFreeNotification(Self);
    FPageControl := Value;
    if FPageControl <> nil then
    begin
      FPageControl.FreeNotification(Self);
      ShowPage(FSelected);
    end;
  end;
end;

procedure TPPGNavigationView.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

{ ---- Maus ---- }

procedure TPPGNavigationView.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FDownRow := RowAt(X, Y);
    Invalidate;
  end;
end;

procedure TPPGNavigationView.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  R: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  R := RowAt(X, Y);
  if R <> FHotRow then
  begin
    FHotRow := R;
    Invalidate;
    Application.CancelHint; // Tooltip zum neuen Eintrag
  end;
end;

procedure TPPGNavigationView.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Down, R: Integer;
begin
  Down := FDownRow;
  FDownRow := -1;
  Invalidate;
  inherited MouseUp(Button, Shift, X, Y);
  if (Button <> mbLeft) or not Enabled then
    Exit;
  R := RowAt(X, Y);
  if R <> Down then
    Exit;
  if R = -2 then
    TogglePane
  else if R >= 0 then
    InvokeItem(RowItem(R));
end;

procedure TPPGNavigationView.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHotRow <> -1 then
  begin
    FHotRow := -1;
    Invalidate;
  end;
end;

function TPPGNavigationView.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
var
  M, Lines, Step: Integer;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if Result then
    Exit;
  MaxScroll(M);
  if M = 0 then
    Exit;
  // Audit 7b: Zeilen aus der Systemeinstellung, Teil-Deltas gesammelt
  Lines := PPGWheelScrollLines;
  if Lines < 0 then
    Step := ClientHeight // seitenweise
  else
    Step := Lines * PPGScale(RowH, ScalePPI);
  FScrollY := EnsureRange(FScrollY - WheelSteps(WheelDelta, Step), 0, M);
  MoveIndicator(False);
  Invalidate;
  Result := True;
end;

procedure TPPGNavigationView.CMHintShow(var Message: TCMHintShow);
var
  It: TPPGNavItem;
begin
  inherited;
  // Kompakt: Tooltip mit dem Text; sonst Item.Hint
  if FHotRow = -2 then
  begin
    Message.HintInfo^.HintStr := PPGStr(@SPPGNavMenu);
    Message.HintInfo^.CursorRect := MenuRect;
    Exit;
  end;
  It := RowItem(FHotRow);
  if It = nil then
    Exit;
  if It.Hint <> '' then
    Message.HintInfo^.HintStr := It.Hint
  else if not PaneOpenNow then
    Message.HintInfo^.HintStr := It.Caption
  else
    Message.Result := 1; // kein Tooltip
  Message.HintInfo^.CursorRect := RowRect(FHotRow);
end;

{ ---- Tastatur ---- }

procedure TPPGNavigationView.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TPPGNavigationView.KeyDown(var Key: Word; Shift: TShiftState);

  function NextFocusable(FromRow, Dir: Integer): Integer;
  var
    R: Integer;
    It: TPPGNavItem;
  begin
    R := FromRow + Dir;
    while (R >= 0) and (R < RowCountAll) do
    begin
      It := RowItem(R);
      if (It.Kind = nikItem) and It.Enabled then
        Exit(R);
      Inc(R, Dir);
    end;
    Result := -1;
  end;

var
  Row, N: Integer;
  K: Word;
  It: TPPGNavItem;
begin
  inherited KeyDown(Key, Shift);
  if not Enabled then
    Exit;
  Row := RowOfItem(FFocusItem);
  K := Key;
  if UseRightToLeftAlignment then
    if K = VK_LEFT then
      K := VK_RIGHT
    else if K = VK_RIGHT then
      K := VK_LEFT;
  N := -1;
  case K of
    VK_UP: N := NextFocusable(Max(Row, 0) + Ord(Row < 0), -1);
    VK_DOWN: N := NextFocusable(Row, 1);
    VK_HOME: N := NextFocusable(-1, 1);
    VK_END: N := NextFocusable(RowCountAll, -1);
    VK_RETURN, VK_SPACE:
      begin
        InvokeItem(FFocusItem);
        Key := 0;
        Exit;
      end;
    VK_RIGHT:
      begin
        It := FFocusItem;
        if (It <> nil) and It.HasChildren and not It.Expanded then
          InvokeItem(It)
        else if (It <> nil) and It.HasChildren and It.Expanded then
          N := NextFocusable(Row, 1);
        Key := 0;
      end;
    VK_LEFT:
      begin
        It := FFocusItem;
        if (It <> nil) and It.HasChildren and It.Expanded then
          InvokeItem(It)
        else if (It <> nil) and (It.ParentItem <> nil) then
          N := RowOfItem(It.ParentItem);
        Key := 0;
      end;
  else
    Exit;
  end;
  if N >= 0 then
  begin
    FFocusItem := RowItem(N);
    EnsureVisible(FFocusItem);
    MoveIndicator(False);
    Invalidate;
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, N + 1);
  end;
  Key := 0;
end;

procedure TPPGNavigationView.DoEnter;
begin
  inherited DoEnter;
  if FFocusItem = nil then
    if FSelected <> nil then
      FFocusItem := IndicatorItem
    else
      FFocusItem := RowItem(0);
  Invalidate;
end;

procedure TPPGNavigationView.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

{ ---- Zeichnen ---- }

procedure TPPGNavigationView.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  T: TPPGTokens;
  A: TPPGAppearance;
  IR: IPPGItemRenderer;
  PPI, I, X, IconW, Rad, BadgeH, Y, FooterT, Lvl: Integer;
  HC, Open, Sel, Hot, Down: Boolean;
  Fill, Border, TextCol, Secondary, Accent, DisabledCol, C: TColor;
  R, RR, IconR, TextR, BR, Clip: TRect;
  It, IndItem: TPPGNavItem;
  S: string;
  Pts: array[0..2] of TPoint;
  Sz: TSize;
  UseColors, Dk, DrawIt: Boolean;
  NS: TPPGNavStyles;
  E: TPPGElementStyle;
  DS: TPPGDrawStyle;
  St: TPPGItemDrawState;
  F, TF: TFont;
  ItemFill: TColor;
  DC: HDC;
begin
  PPI := ScalePPI;
  T := Tokens;
  A := EffectiveAppearance;
  HC := HighContrastSupport and PPGIsHighContrast;
  if HC then
  begin
    Fill := PPGColorToRGB(clWindow);
    Border := PPGColorToRGB(clWindowText);
    TextCol := PPGColorToRGB(clWindowText);
    Secondary := TextCol;
    Accent := PPGColorToRGB(clHighlight);
    DisabledCol := PPGColorToRGB(clGrayText);
  end
  else
  begin
    Fill := PPGBlendColor(T.Background, T.Layer, 0.5);
    Border := T.Stroke;
    TextCol := T.TextPrimary;
    Secondary := T.TextSecondary;
    Accent := PPGColorToRGB(A.FocusColor);
    DisabledCol := T.TextDisabled;
    if UseVclStyle then
    begin
      Fill := PPGColorToRGB(A.Normal.Color);
      TextCol := PPGColorToRGB(A.Normal.TextColor);
      Secondary := PPGBlendColor(TextCol, Fill, 0.4);
      DisabledCol := PPGBlendColor(TextCol, Fill, 0.6);
    end;
  end;
  // Element-Stile (Styles): Leiste, Ueberschriften; Eintraege unten
  NS := FNavStyles;
  UseColors := not HC and not UseVclStyle;
  Dk := UseDarkMode;
  if UseColors then
  begin
    Fill := NS.Pane.FillFor(Dk, Fill);
    TextCol := NS.Pane.TextFor(Dk, TextCol);
    Border := NS.Pane.BorderFor(Dk, Border);
    Secondary := NS.Header.TextFor(Dk, Secondary);
  end;
  FFonts.Clear;
  try
    if not Enabled then
    begin
      TextCol := DisabledCol;
      Secondary := DisabledCol;
      Accent := PPGBlendColor(Accent, Fill, 0.6); // Plaketten und Indikator zuruecknehmen
    end;
    ACanvas.FillRoundRect(ClientR, 0, Fill, 255);
    // Trennlinie zum Inhalt
    if UseRightToLeftAlignment then
      ACanvas.FillRoundRect(Rect(ClientR.Left, ClientR.Top, ClientR.Left + 1, ClientR.Bottom), 0, Border, 255)
    else
      ACanvas.FillRoundRect(Rect(ClientR.Right - 1, ClientR.Top, ClientR.Right, ClientR.Bottom), 0, Border, 255);
    BuildRows;
    Open := PaneOpenNow;
    IconW := PPGScale(FCompactPaneLength, PPI);
    Rad := PPGScale(4, PPI);

    // Menue-Knopf und Titel
    if FShowMenuButton then
    begin
      R := MenuRect;
      if Enabled and (FHotRow = -2) then
        ACanvas.FillRoundRect(R, Rad, TextCol, IfThen(FDownRow = -2, 24, 14));
      if not PPGDrawIcon(ACanvas, R, igMenu, TextCol, PPGScale(16, PPI)) then
        for I := -1 to 1 do
          ACanvas.FillRoundRect(Rect((R.Left + R.Right) div 2 - PPGScale(8, PPI),
            (R.Top + R.Bottom) div 2 + I * PPGScale(5, PPI) - 1,
            (R.Left + R.Right) div 2 + PPGScale(8, PPI),
            (R.Top + R.Bottom) div 2 + I * PPGScale(5, PPI) + 1), 0, TextCol, 255);
      if FocusVisible and Focused and (FFocusItem = nil) then
        ACanvas.FrameRoundRect(R, Rad, PPGScale(2, PPI), Accent, 255);
    end;
    if (FPaneTitle <> '') and (Width > IconW + PPGScale(24, PPI)) then
    begin
      if FShowMenuButton then
        R := Rect(IconW, 0, Width - PPGScale(8, PPI), MainTop)
      else
        R := Rect(PPGScale(16, PPI), 0, Width - PPGScale(8, PPI), MainTop);
      if UseRightToLeftAlignment then
        R := Rect(Width - R.Right, R.Top, Width - R.Left, R.Bottom);
      TF := FFonts.ForStyle(NS.PaneTitle, Font);
      C := TextCol;
      if UseColors and Enabled then
        C := NS.PaneTitle.TextFor(Dk, C);
      ACanvas.DrawText(R, FPaneTitle, TF, C,
        DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX));
    end;

    IndItem := IndicatorItem;
    FooterT := FooterTop;
    IR := PPGItemRendererOf(Renderer);
    for I := 0 to RowCountAll - 1 do
    begin
      It := RowItem(I);
      R := RowRect(I);
      if I < FRows.Count then
      begin
        if (R.Bottom <= MainTop) or (R.Top >= FooterT) then
          Continue;
        Clip := Rect(0, MainTop, Width, FooterT);
      end
      else
        Clip := ClientR;
      ACanvas.PushClipRoundRect(Clip, 0);
      try
        case It.Kind of
          nikSeparator:
            ACanvas.FillRoundRect(Rect(R.Left + PPGScale(12, PPI), (R.Top + R.Bottom) div 2,
              R.Right - PPGScale(12, PPI), (R.Top + R.Bottom) div 2 + 1), 0, Border, 255);
          nikHeader:
            begin
              TextR := Rect(R.Left + PPGScale(16, PPI), R.Top, R.Right - PPGScale(8, PPI), R.Bottom);
              if UseRightToLeftAlignment then
                TextR := Rect(Width - TextR.Right, TextR.Top, Width - TextR.Left, TextR.Bottom);
              ACanvas.DrawText(TextR, It.Caption, FFonts.ForStyle(NS.Header, Font), Secondary,
                DrawTextBiDiModeFlags(DT_SINGLELINE or DT_BOTTOM or DT_END_ELLIPSIS or DT_NOPREFIX));
            end;
        else
          begin
            RR := Rect(R.Left + PPGScale(RowInset, PPI), R.Top + PPGScale(2, PPI),
              R.Right - PPGScale(RowInset, PPI), R.Bottom - PPGScale(2, PPI));
            Sel := (It = IndItem);
            Hot := Enabled and It.Enabled and (I = FHotRow);
            Down := Hot and (I = FDownRow);
            // Eigenes Zeichnen (vor dem Eintrag)
            DS.Reset;
            DrawIt := True;
            if Assigned(FOnCustomDrawItem) then
            begin
              St := [];
              if Sel then
                Include(St, idsSelected);
              if Hot then
                Include(St, idsHot);
              if not (Enabled and It.Enabled) then
                Include(St, idsDisabled);
              if It.Expanded then
                Include(St, idsExpanded);
              if FocusVisible and Focused and (It = FFocusItem) then
                Include(St, idsFocused);
              DC := ACanvas.BeginGdi;
              try
                FDrawCanvas.Handle := DC;
                try
                  FDrawCanvas.Font := Font;
                  FDrawCanvas.Brush.Style := bsClear;
                  FOnCustomDrawItem(Self, FDrawCanvas, It, RR, St, DS, DrawIt);
                finally
                  FDrawCanvas.Handle := 0;
                end;
              finally
                ACanvas.EndGdi(DC);
              end;
            end;
            if not DrawIt then
              Continue;
            if Sel then
              E := NS.SelectedItem
            else if Hot then
              E := NS.HotItem
            else
              E := NS.Item;
            // Flaeche: eigene Farbe deckend, sonst die dezente Preset-Flaeche
            ItemFill := clNone;
            if UseColors then
            begin
              if E.HasFill(Dk) then
                ItemFill := E.FillFor(Dk, clNone);
              if (It.Color <> clDefault) and (It.Color <> clNone) then
                ItemFill := PPGColorToRGB(It.Color);
              if DS.Fill <> clNone then
                ItemFill := PPGColorToRGB(DS.Fill);
            end;
            if ItemFill <> clNone then
              ACanvas.FillRoundRect(RR, Rad, ItemFill, 255)
            else if Sel then
              ACanvas.FillRoundRect(RR, Rad, TextCol, IfThen(Hot, 22, 16))
            else if Down then
              ACanvas.FillRoundRect(RR, Rad, TextCol, 20)
            else if Hot then
              ACanvas.FillRoundRect(RR, Rad, TextCol, 10);
            if It.Enabled then
              C := TextCol
            else
              C := DisabledCol;
            if UseColors and It.Enabled and Enabled then
            begin
              C := E.TextFor(Dk, C);
              if (It.TextColor <> clDefault) and (It.TextColor <> clNone) then
                C := PPGColorToRGB(It.TextColor);
              if DS.TextColor <> clNone then
                C := PPGColorToRGB(DS.TextColor);
            end;
            F := FFonts.ForStyle(E, Font, It.FontStyle + DS.FontStyle);
            Lvl := 0;
            if Open then
              Lvl := It.Level;
            X := Lvl * PPGScale(IndentW, PPI);
            IconR := Rect(X, R.Top, X + IconW, R.Bottom);
            if UseRightToLeftAlignment then
              IconR := Rect(Width - IconR.Right, IconR.Top, Width - IconR.Left, IconR.Bottom);
            if (Images <> nil) and (It.ImageIndex >= 0) and (It.ImageIndex < Images.Count) then
              DrawItemImage(ACanvas, It.ImageIndex, (IconR.Left + IconR.Right - Images.Width) div 2,
                (IconR.Top + IconR.Bottom - Images.Height) div 2, Enabled and It.Enabled, C)
            else if It.IconChar <> 0 then
            begin
              if not PPGDrawIconChar(ACanvas, IconR, It.IconChar, C, PPGScale(16, PPI)) then
                // Ersatz ohne Symbolschrift: Anfangsbuchstabe
                ACanvas.DrawText(IconR, Copy(It.Caption, 1, 1), Font, C,
                  DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
            end
            else if not Open then
              ACanvas.DrawText(IconR, Copy(It.Caption, 1, 1), Font, C,
                DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
            // Plakette: offen rechts, kompakt oben rechts am Symbol
            if (It.BadgeCount > 0) or It.BadgeDot then
            begin
              if It.BadgeDot or not Open then
              begin
                BadgeH := PPGScale(8, PPI);
                if It.BadgeDot then
                  BR := Rect((IconR.Left + IconR.Right) div 2 + PPGScale(5, PPI), R.Top + PPGScale(8, PPI),
                    (IconR.Left + IconR.Right) div 2 + PPGScale(5, PPI) + BadgeH, R.Top + PPGScale(8, PPI) + BadgeH)
                else
                  BR := Rect(0, 0, 0, 0);
                if not IsRectEmpty(BR) then
                  ACanvas.FillEllipse(BR, Accent, 255)
                else
                begin
                  S := IntToStr(Min(It.BadgeCount, 99));
                  Sz := PPGMeasureTextNoCanvas(S, Font, 0, False);
                  BR := Rect((IconR.Left + IconR.Right) div 2 + PPGScale(2, PPI), R.Top + PPGScale(3, PPI),
                    (IconR.Left + IconR.Right) div 2 + PPGScale(2, PPI) + Max(Sz.cx + PPGScale(6, PPI), Sz.cy),
                    R.Top + PPGScale(3, PPI) + Sz.cy);
                  IR.DrawBadge(ACanvas, BR, S, Font, Accent, PPGContrastTextColor(Accent), PPI);
                end;
              end;
            end;
            if Open then
            begin
              TextR := Rect(IconR.Right, R.Top, R.Right - PPGScale(12, PPI), R.Bottom);
              if UseRightToLeftAlignment then
                TextR := Rect(R.Left + PPGScale(12, PPI), R.Top, IconR.Left, R.Bottom);
              // Chevron fuer Untereintraege
              if It.HasChildren then
              begin
                BR := Rect(TextR.Right - PPGScale(20, PPI), R.Top, TextR.Right, R.Bottom);
                if UseRightToLeftAlignment then
                  BR := Rect(TextR.Left, R.Top, TextR.Left + PPGScale(20, PPI), R.Bottom);
                Y := (BR.Top + BR.Bottom) div 2;
                if It.Expanded then
                begin
                  Pts[0] := Point((BR.Left + BR.Right) div 2 - PPGScale(4, PPI), Y + PPGScale(2, PPI));
                  Pts[1] := Point((BR.Left + BR.Right) div 2, Y - PPGScale(2, PPI));
                  Pts[2] := Point((BR.Left + BR.Right) div 2 + PPGScale(4, PPI), Y + PPGScale(2, PPI));
                end
                else
                begin
                  Pts[0] := Point((BR.Left + BR.Right) div 2 - PPGScale(4, PPI), Y - PPGScale(2, PPI));
                  Pts[1] := Point((BR.Left + BR.Right) div 2, Y + PPGScale(2, PPI));
                  Pts[2] := Point((BR.Left + BR.Right) div 2 + PPGScale(4, PPI), Y - PPGScale(2, PPI));
                end;
                ACanvas.DrawPolyline(Pts, Max(1, Round(1.5 * PPI / 96)), C, 255);
                if UseRightToLeftAlignment then
                  TextR.Left := BR.Right
                else
                  TextR.Right := BR.Left;
              end;
              if It.BadgeCount > 0 then
              begin
                S := IntToStr(It.BadgeCount);
                if It.BadgeCount > 99 then
                  S := '99+';
                Sz := IR.BadgeSize(ACanvas, S, Font, PPI);
                if UseRightToLeftAlignment then
                begin
                  BR := Rect(TextR.Left, (R.Top + R.Bottom - Sz.cy) div 2, TextR.Left + Sz.cx,
                    (R.Top + R.Bottom + Sz.cy) div 2);
                  TextR.Left := BR.Right + PPGScale(6, PPI);
                end
                else
                begin
                  BR := Rect(TextR.Right - Sz.cx, (R.Top + R.Bottom - Sz.cy) div 2, TextR.Right,
                    (R.Top + R.Bottom + Sz.cy) div 2);
                  TextR.Right := BR.Left - PPGScale(6, PPI);
                end;
                IR.DrawBadge(ACanvas, BR, S, Font, Accent, PPGContrastTextColor(Accent), PPI);
              end;
              ACanvas.DrawText(TextR, It.Caption, F, C,
                DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX));
            end;
            if FocusVisible and Focused and (It = FFocusItem) then
              ACanvas.FrameRoundRect(RR, Rad, PPGScale(2, PPI), Accent, 255);
          end;
        end;
      finally
        ACanvas.PopClip;
      end;
    end;

    // Auswahl-Indikator (gleitet)
    if IndItem <> nil then
    begin
      Y := IndicatorPos;
      R := Rect(PPGScale(RowInset, PPI) + PPGScale(2, PPI), Y - PPGScale(8, PPI),
        PPGScale(RowInset, PPI) + PPGScale(5, PPI), Y + PPGScale(8, PPI));
      if UseRightToLeftAlignment then
        R := Rect(Width - R.Right, R.Top, Width - R.Left, R.Bottom);
      if RowOfItem(IndItem) < FRows.Count then
        Clip := Rect(0, MainTop, Width, FooterT)
      else
        Clip := ClientR;
      ACanvas.PushClipRoundRect(Clip, 0);
      try
        if UseColors and Enabled then
          ACanvas.FillRoundRect(R, PPGScale(2, PPI), NS.Indicator.FillFor(Dk, Accent), 255)
        else
          ACanvas.FillRoundRect(R, PPGScale(2, PPI), Accent, 255);
      finally
        ACanvas.PopClip;
      end;
    end;
  finally
    FFonts.Clear; // keine Schrift-Handles ueber das Zeichnen hinaus
  end;
end;

{ ---- Barrierefreiheit ---- }

procedure TPPGNavigationView.WndProc(var Message: TMessage);
var
  Id: Integer;
begin
  if (GMsgNavAction <> 0) and (Message.Msg = GMsgNavAction) then
  begin
    // LParam: das gemeinte Item (0 = Umschalter). Haben sich die Zeilen bis
    // hierher geaendert, steht an der Stelle ein anderes Item: nichts tun.
    // Nur Zeiger vergleichen, LParam nie dereferenzieren.
    Id := Integer(Message.WParam);
    if Message.LParam = 0 then
    begin
      if Id = RowCountAll + 1 then
        TogglePane;
    end
    else if (Id >= 1) and (NativeInt(RowItem(Id - 1)) = NativeInt(Message.LParam)) then
      InvokeItem(RowItem(Id - 1));
    Exit;
  end;
  inherited WndProc(Message);
end;

function TPPGNavigationView.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_OUTLINE;
end;

function TPPGNavigationView.AccChildCount: Integer;
begin
  // Zeilen + Menue-Knopf
  Result := RowCountAll + Ord(FShowMenuButton);
end;

function TPPGNavigationView.AccChildName(Id: Integer): string;
var
  It: TPPGNavItem;
begin
  if FShowMenuButton and (Id = RowCountAll + 1) then
    Exit(PPGStr(@SPPGNavMenu));
  It := RowItem(Id - 1);
  if It = nil then
    Exit('');
  Result := It.Caption;
  if It.BadgeCount > 0 then
    Result := Result + ' (' + IntToStr(It.BadgeCount) + ')';
end;

function TPPGNavigationView.AccChildRole(Id: Integer): Integer;
var
  It: TPPGNavItem;
begin
  if FShowMenuButton and (Id = RowCountAll + 1) then
    Exit(ROLE_SYSTEM_PUSHBUTTON);
  It := RowItem(Id - 1);
  if It = nil then
    Exit(ROLE_SYSTEM_OUTLINEITEM);
  case It.Kind of
    nikHeader: Result := ROLE_SYSTEM_STATICTEXT;
    nikSeparator: Result := ROLE_SYSTEM_SEPARATOR;
  else
    Result := ROLE_SYSTEM_OUTLINEITEM;
  end;
end;

function TPPGNavigationView.AccChildState(Id: Integer): Integer;
var
  It: TPPGNavItem;
begin
  if FShowMenuButton and (Id = RowCountAll + 1) then
    Exit(STATE_SYSTEM_FOCUSABLE);
  It := RowItem(Id - 1);
  if (It = nil) or (It.Kind <> nikItem) then
    Exit(STATE_SYSTEM_READONLY);
  Result := STATE_SYSTEM_FOCUSABLE or STATE_SYSTEM_SELECTABLE;
  if not It.Enabled then
    Result := STATE_SYSTEM_UNAVAILABLE;
  if It = FSelected then
    Result := Result or STATE_SYSTEM_SELECTED;
  if Focused and (It = FFocusItem) then
    Result := Result or STATE_SYSTEM_FOCUSED;
  if It.HasChildren then
    if It.Expanded then
      Result := Result or STATE_SYSTEM_EXPANDED
    else
      Result := Result or STATE_SYSTEM_COLLAPSED;
end;

function TPPGNavigationView.AccChildRect(Id: Integer): TRect;
begin
  if FShowMenuButton and (Id = RowCountAll + 1) then
    Result := MenuRect
  else
    Result := RowRect(Id - 1);
end;

function TPPGNavigationView.AccChildAt(X, Y: Integer): Integer;
var
  R: Integer;
begin
  R := RowAt(X, Y);
  if R = -2 then
    Result := RowCountAll + 1
  else
    Result := R + 1;
end;

function TPPGNavigationView.AccChildDefaultAction(Id: Integer): string;
var
  It: TPPGNavItem;
begin
  if FShowMenuButton and (Id = RowCountAll + 1) then
    Exit(PPGStr(@SPPGAccPress));
  It := RowItem(Id - 1);
  if (It = nil) or (It.Kind <> nikItem) then
    Result := ''
  else if It.HasChildren then
  begin
    if It.Expanded then
      Result := PPGStr(@SPPGAccCollapse)
    else
      Result := PPGStr(@SPPGAccExpand);
  end
  else
    Result := PPGStr(@SPPGAccSelect);
end;

procedure TPPGNavigationView.AccChildDoDefault(Id: Integer);
var
  It: TPPGNavItem;
begin
  if not HandleAllocated then
    Exit;
  if Id = RowCountAll + 1 then
    PostMessage(Handle, GMsgNavAction, WPARAM(Id), 0)
  else
  begin
    It := RowItem(Id - 1);
    if It <> nil then
      PostMessage(Handle, GMsgNavAction, WPARAM(Id), LPARAM(It));
  end;
end;

function TPPGNavigationView.AccFocusedChild: Integer;
begin
  if Focused and (FFocusItem <> nil) then
    Result := RowOfItem(FFocusItem) + 1
  else
    Result := 0;
end;

function TPPGNavigationView.AccSelectedChild: Integer;
begin
  Result := RowOfItem(FSelected) + 1;
end;

end.
