unit PPG.Kanban;

{ TPPGKanban - Kanban-Board (Phase 14c, Vorbild Trello / TMS FNC Kanban).

  - Spalten (Titel, Farbe, WIP-Limit mit Warnfarbe, einklappbar) und Karten
    (Titel, Text mit Markup, Plaketten, Faelligkeit, Person als Initialen,
    Fortschritt, Farbstreifen). Optional Swimlanes (Zeilen).
  - Ohne Swimlanes scrollt jede Spalte fuer sich (Mausrad, Daumen); das Board
    scrollt waagerecht. Mit Swimlanes scrollt das ganze Board, die
    Spaltenkoepfe bleiben stehen.
  - Virtuelle Spalten (Column.VirtualCount + OnGetCard): Karten fester Hoehe,
    Lage in O(1), es wird nur Sichtbares abgefragt und gezeichnet.
  - Ziehen innerhalb und zwischen Spalten (und Swimlanes): die Karte folgt
    der Maus, am Ziel oeffnet sich ein Platzhalter, die anderen Karten
    weichen animiert aus (gemeinsamer Animator). Am Rand scrollt das Board
    bzw. die Spalte. OnCardMoving (abbrechbar, z.B. WIP-Limit) und
    OnCardMoved; WipMode = kwmBlock lehnt Karten fuer volle Spalten ab.
  - Tastatur: Pfeile zwischen Karten, Strg+Pfeile verschieben die Karte
    (auch in die naechste Spalte bzw. Swimlane), Enter oeffnet, Esc bricht
    das Ziehen ab. Der Screenreader hoert "verschoben nach Spalte X,
    Position Y".
  - Code (Cards, Column.Collapsed, SelectedCard) loest keine Ereignisse aus. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.Generics.Collections, System.UITypes, Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Base,
  PPG.Controls.Scroll, PPG.Markup, PPG.Kanban.Layout, PPG.Kanban.Items, PPG.ElementStyle, PPG.CustomDraw;

type
  TPPGKanbanPart = (kpNone, kpCard, kpHeader, kpCollapse, kpLane, kpCell, kpThumb);
  TPPGKanbanWipMode = (kwmWarn, kwmBlock);

  /// Treffer bzw. Adresse einer Karte: sichtbare Spalte, Swimlane, Position.
  TPPGKanbanHit = record
    Part: TPPGKanbanPart;
    Col: Integer;
    Lane: Integer;
    Index: Integer;
  end;

  TPPGKanbanMove = record
    Card: TPPGKanbanCard;          // nil bei virtuellen Spalten
    FromColumn, ToColumn: TPPGKanbanColumn;
    FromLane, ToLane: TPPGKanbanLane; // nil ohne Swimlanes
    FromIndex, ToIndex: Integer;   // Position in der Zelle (ToIndex nach dem Verschieben)
    ByKeyboard: Boolean;
  end;

  TPPGKanbanMovingEvent = procedure(Sender: TObject; const Move: TPPGKanbanMove;
    var Allow: Boolean) of object;
  TPPGKanbanMovedEvent = procedure(Sender: TObject; const Move: TPPGKanbanMove) of object;
  TPPGKanbanCardEvent = procedure(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer;
    Card: TPPGKanbanCard) of object;
  TPPGKanbanGetCardEvent = procedure(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer;
    var Data: TPPGKanbanCardData) of object;
  TPPGKanbanColumnEvent = procedure(Sender: TObject; Column: TPPGKanbanColumn) of object;

  TPPGKanbanCell = record
    Cards: array of TPPGKanbanCard;  // leer bei virtuellen Spalten
    Count: Integer;
    Virtual: Boolean;
    Tops: TArray<Integer>;           // relativ zu Top (nicht virtuell)
    Heights: TArray<Integer>;
    Top: Integer;                    // Inhalts-Y der ersten Karte
    Bottom: Integer;                 // Inhalts-Y unter der letzten Karte
  end;

  TPPGKanbanColLayout = record
    Column: TPPGKanbanColumn;
    X, W: Integer;                   // Inhalts-Koordinaten (vor RTL-Spiegelung)
    Collapsed: Boolean;
    Cells: array of TPPGKanbanCell;  // je Swimlane
  end;

  TPPGKanbanLaneLayout = record
    Lane: TPPGKanbanLane;            // nil = ohne Swimlanes
    Top: Integer;                    // Inhalts-Y des Kopfs (ohne Swimlanes: Kopfhoehe der Spalten)
    BodyTop: Integer;
    BodyHeight: Integer;
  end;

  /// Bereiche des Boards (nur gesetzte Werte zaehlen, clDefault = Preset).
  TPPGKanbanStyles = class(TPPGStyleGroup)
  public
    constructor Create(AOwner: TPersistent);
  published
    /// Spalten: Color = Hintergrund, TextColor = Titel, Schrift des Titels.
    property Column: TPPGElementStyle index 0 read GetItem write SetItem;
    /// Karten: Color, TextColor, BorderColor = Rand, Schrift des Titels.
    property Card: TPPGElementStyle index 1 read GetItem write SetItem;
    /// Karte unter der Maus (Color).
    property HotCard: TPPGElementStyle index 2 read GetItem write SetItem;
    /// Gewaehlte Karte (BorderColor).
    property SelectedCard: TPPGElementStyle index 3 read GetItem write SetItem;
    /// Swimlane-Koepfe (TextColor, Schrift).
    property LaneHeader: TPPGElementStyle index 4 read GetItem write SetItem;
  end;

  /// Vor dem Zeichnen einer Karte: Style (Flaeche, Text, Rand, fett) oder
  /// ganz selbst zeichnen (DefaultDraw = False).
  TPPGKanbanDrawCardEvent = procedure(Sender: TObject; Canvas: TCanvas;
    const Card: TPPGKanbanCardData; const ARect: TRect; State: TPPGItemDrawState;
    var Style: TPPGDrawStyle; var DefaultDraw: Boolean) of object;

  TPPGCustomKanban = class(TPPGCustomScrollControl, IPPGKanbanHost, IPPGAccessibleChildren)
  private
    FColumns: TPPGKanbanColumns;
    FLanes: TPPGKanbanLanes;
    FKanbanStyles: TPPGKanbanStyles;
    FOnCustomDrawCard: TPPGKanbanDrawCardEvent;
    FDrawCanvas: TCanvas;
    FCards: TPPGKanbanCards;
    FColumnWidth: Integer;
    FCardGap: Integer;
    FMaxTextLines: Integer;
    FVirtualCardHeight: Integer;
    FAllowDrag: Boolean;
    FReadOnly: Boolean;
    FWipMode: TPPGKanbanWipMode;
    FShowCardCount: Boolean;
    { Layout }
    FLayoutValid: Boolean;
    FCols: array of TPPGKanbanColLayout;
    FLaneL: array of TPPGKanbanLaneLayout;
    FHeaderH: Integer;
    FColScroll: TDictionary<Integer, Integer>;
    FHeights: TDictionary<TPPGKanbanCard, Integer>;
    FMarkup: TPPGMarkupLayout;
    FBold: TFont;
    FSmall: TFont;
    { Bedienung }
    FFocus: TPPGKanbanHit;
    FHot: TPPGKanbanHit;
    FPress: TPPGKanbanHit;
    FPressPt: TPoint;
    FDragging: Boolean;
    FDragSrc: TPPGKanbanHit;
    FDragH: Integer;
    FDragData: TPPGKanbanCardData;
    FGrab: TPoint;
    FMousePt: TPoint;
    FDrop: TPPGKanbanHit;
    FPrevDrop: TPPGKanbanHit;
    FShiftAnim: TPPGAnimation;
    FColAuto: TPPGAnimation;
    FColAutoCol: Integer;
    FColAutoSpeed: Integer;
    FThumbCol: Integer;
    FThumbOffset: Integer;
    FAnnounce: string;
    { Ereignisse }
    FOnCardMoving: TPPGKanbanMovingEvent;
    FOnCardMoved: TPPGKanbanMovedEvent;
    FOnCardClick: TPPGKanbanCardEvent;
    FOnCardOpen: TPPGKanbanCardEvent;
    FOnGetCard: TPPGKanbanGetCardEvent;
    FOnSelectionChange: TNotifyEvent;
    FOnColumnCollapse: TPPGKanbanColumnEvent;
    procedure SetKanbanStyles(const Value: TPPGKanbanStyles);
    procedure KanbanStylesChanged(Sender: TObject);
    procedure SetColumns(const Value: TPPGKanbanColumns);
    procedure SetLanes(const Value: TPPGKanbanLanes);
    procedure SetCards(const Value: TPPGKanbanCards);
    procedure SetColumnWidth(const Value: Integer);
    procedure SetCardGap(const Value: Integer);
    procedure SetMaxTextLines(const Value: Integer);
    procedure SetVirtualCardHeight(const Value: Integer);
    procedure SetShowCardCount(const Value: Boolean);
    function GetSelectedCard: TPPGKanbanCard;
    procedure SetSelectedCard(const Value: TPPGKanbanCard);
    procedure ShiftStep(Sender: TObject);
    procedure ColAutoStep(Sender: TObject);
    procedure SyncFonts;
    { Masse }
    function Sc(V: Integer): Integer;
    function TextH(F: TFont): Integer;
    function CardPad: Integer;
    function ColGap: Integer;
    function BoardPad: Integer;
    function CollapsedWidth: Integer;
    function LaneHeaderHeight: Integer;
    function HasLanes: Boolean;
    function VirtualHeight: Integer;
    function MeasureCard(const D: TPPGKanbanCardData; W: Integer): Integer;
    function CardInnerWidth(C: Integer): Integer;
    { Layout }
    procedure LayoutChanged;
    function GetColScroll(C: Integer): Integer;
    procedure SetColScroll(C, Value: Integer);
    function ColMaxScroll(C: Integer): Integer;
    function BodyRect(C: Integer): TRect;
    function ToClientX(CX, W: Integer): Integer;
    function ToContentX(X: Integer): Integer;
    function ColClientRect(C: Integer): TRect;
    function CardOffsetY(C, L: Integer): Integer;
    function RawCardRect(C, L, I: Integer): TRect;
    function ThumbRectOf(C: Integer): TRect;
    { Ziehen }
    function ShiftFor(const Drop: TPPGKanbanHit; C, L, I: Integer): Integer;
    function CurrentShift(C, L, I: Integer): Integer;
    function DropAt(X, Y: Integer): TPPGKanbanHit;
    procedure UpdateDrop(X, Y: Integer);
    procedure EndDrag(Commit: Boolean);
    procedure ColumnAutoScroll(X, Y: Integer);
    { Zeichnen }
    procedure PaintColumn(const ACanvas: IPPGCanvas; C: Integer; const View: TRect);
    procedure PaintCard(const ACanvas: IPPGCanvas; const R: TRect; const D: TPPGKanbanCardData;
      const DS: TPPGDrawStyle;
      Selected, Hot, Ghost: Boolean);
    function DragWidth: Integer;
    function DropPlaceholderRect: TRect;
    function RawCardRectX(C: Integer): TRect;
    { Tastatur }
    function CellCount(C, L: Integer): Integer;
    function NextColumn(C, Dir: Integer; NeedCards: Boolean): Integer;
    procedure FocusHit(const H: TPPGKanbanHit; Notify: Boolean);
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    procedure WndProc(var Message: TMessage); override;
    procedure Resize; override;
    procedure Loaded; override;
    procedure PaintViewport(const ACanvas: IPPGCanvas; const View: TRect); override;
    procedure ContentMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure ContentMouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure ContentMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure DoAutoScroll(const P: TPoint); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure ThemeChanged; override;
    { IPPGKanbanHost }
    procedure KanbanModelChanged;
    { Barrierefreiheit: Kinder = Spaltenkoepfe und Karten }
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
    function AccIdOf(const H: TPPGKanbanHit): Integer;
    function AccHitOf(Id: Integer): TPPGKanbanHit;
    /// Ueberschreibbar (DB-Variante): Karte verschieben. True = ausgefuehrt.
    function DoMoveCard(const Move: TPPGKanbanMove): Boolean; virtual;
    /// Nach erfolgreichem Verschieben (DB-Variante: Datensaetze schreiben).
    procedure CardMoved(const Move: TPPGKanbanMove); virtual;
    procedure SelectionChanged; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure EnsureLayout;
    /// Hoehe, in der das ganze Board ohne Scrollen Platz hat (Druck, Bild).
    function BoardHeight: Integer;
    /// Breiten und eingeklappte Spalten/Swimlanes als Text (INI-Stil, wie
    /// TPPGGrid.SaveLayout) und zurueck; unbekannte Ids werden uebergangen.
    function SaveLayout: string;
    procedure LoadLayout(const S: string);
    { Abfragen (Treffer in Client-Koordinaten) }
    function HitTest(X, Y: Integer): TPPGKanbanHit;
    function ColumnCount: Integer;
    function LayoutColumn(C: Integer): TPPGKanbanColumn;
    function ColumnIndexOf(Column: TPPGKanbanColumn): Integer;
    function LaneCount: Integer;
    function LayoutLane(L: Integer): TPPGKanbanLane;
    function ColumnRect(C: Integer): TRect;
    function HeaderRect(C: Integer): TRect;
    function LaneHeaderRect(L: Integer): TRect;
    /// Karte an Position I der Zelle (C, L); leer = nicht sichtbar.
    function CardRect(C, L, I: Integer): TRect;
    /// Karten einer Zelle (virtuell: VirtualCount).
    function CardCount(C, L: Integer): Integer;
    function CardAt(C, L, I: Integer): TPPGKanbanCard;
    function CardData(C, L, I: Integer): TPPGKanbanCardData;
    /// Zelle und Position einer Karte (False = nicht sichtbar).
    function FindCard(Card: TPPGKanbanCard; out C, L, I: Integer): Boolean;
    /// Karten einer Spalte ueber alle Swimlanes (fuer das WIP-Limit).
    function ColumnCardCount(C: Integer): Integer;
    function WipState(C: Integer): TPPGKanbanWipState;
    function ColumnScroll(C: Integer): Integer;
    procedure ScrollColumn(C, Delta: Integer);
    procedure MakeCardVisible(C, L, I: Integer);
    /// Verschieben wie per Ziehen (mit OnCardMoving/OnCardMoved). ToIndex = Ziel
    /// nach dem Verschieben. True = verschoben.
    function MoveCard(C, L, I, ToC, ToL, ToIndex: Integer; ByKeyboard: Boolean = False): Boolean;
    /// Spalte ein-/ausklappen wie per Klick (mit OnColumnCollapse).
    procedure ToggleColumn(C: Integer);
    procedure ToggleLane(L: Integer);
    procedure Select(C, L, I: Integer);
    property Focus: TPPGKanbanHit read FFocus;
    property CardDragging: Boolean read FDragging;
    property DropTarget: TPPGKanbanHit read FDrop;
    /// Letzte Meldung an den Screenreader (z.B. "verschoben nach ...").
    property Announcement: string read FAnnounce;
    property SelectedCard: TPPGKanbanCard read GetSelectedCard write SetSelectedCard;

    property Columns: TPPGKanbanColumns read FColumns write SetColumns;
    property Lanes: TPPGKanbanLanes read FLanes write SetLanes;
    property Cards: TPPGKanbanCards read FCards write SetCards;
    property ColumnWidth: Integer read FColumnWidth write SetColumnWidth default 272;
    property CardGap: Integer read FCardGap write SetCardGap default 8;
    property MaxTextLines: Integer read FMaxTextLines write SetMaxTextLines default 3;
    /// Hoehe virtueller Karten in logischen px (0 = aus der Schrift).
    property VirtualCardHeight: Integer read FVirtualCardHeight write SetVirtualCardHeight default 0;
    property AllowDrag: Boolean read FAllowDrag write FAllowDrag default True;
    property ReadOnly: Boolean read FReadOnly write FReadOnly default False;
    property WipMode: TPPGKanbanWipMode read FWipMode write FWipMode default kwmWarn;
    property ShowCardCount: Boolean read FShowCardCount write SetShowCardCount default True;
    /// Bereiche (Spalten, Karten, Hover, Auswahl, Swimlane-Koepfe).
    property KanbanStyles: TPPGKanbanStyles read FKanbanStyles write SetKanbanStyles;
    property OnCustomDrawCard: TPPGKanbanDrawCardEvent read FOnCustomDrawCard write FOnCustomDrawCard;
    property OnCardMoving: TPPGKanbanMovingEvent read FOnCardMoving write FOnCardMoving;
    property OnCardMoved: TPPGKanbanMovedEvent read FOnCardMoved write FOnCardMoved;
    property OnCardClick: TPPGKanbanCardEvent read FOnCardClick write FOnCardClick;
    property OnCardOpen: TPPGKanbanCardEvent read FOnCardOpen write FOnCardOpen;
    property OnGetCard: TPPGKanbanGetCardEvent read FOnGetCard write FOnGetCard;
    property OnSelectionChange: TNotifyEvent read FOnSelectionChange write FOnSelectionChange;
    property OnColumnCollapse: TPPGKanbanColumnEvent read FOnColumnCollapse write FOnColumnCollapse;
  end;

  TPPGKanban = class(TPPGCustomKanban)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighContrastSupport;
    property Columns;
    property Lanes;
    property Cards;
    property ColumnWidth;
    property CardGap;
    property MaxTextLines;
    property VirtualCardHeight;
    property AllowDrag;
    property ReadOnly;
    property WipMode;
    property ShowCardCount;
    property KanbanStyles;
    property OnCustomDrawCard;
    property ScrollBarMode;
    property SmoothScrolling;
    property Align;
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
    property OnCardMoving;
    property OnCardMoved;
    property OnCardClick;
    property OnCardOpen;
    property OnGetCard;
    property OnSelectionChange;
    property OnColumnCollapse;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnScroll;
  end;

/// "Spalte, n Karten, Limit m" bzw. "Titel, Spalte X, Position Y von N, ..." (Screenreader).
function PPGKanbanCardSpeech(const D: TPPGKanbanCardData; const ColumnTitle: string;
  Position, Count: Integer): string;

implementation

uses
  PPG.Lang,
  System.Math, Winapi.oleacc,
  PPG.Exceptions, PPG.Consts, PPG.Appearance, PPG.DpiUtils, PPG.Tokens, PPG.IconFont, PPG.Render.Gdi,
  PPG.Chart.Palette;

var
  GMsgKanbanAction: Cardinal = 0;

function NoHit: TPPGKanbanHit;
begin
  Result.Part := kpNone;
  Result.Col := -1;
  Result.Lane := -1;
  Result.Index := -1;
end;

function KHit(APart: TPPGKanbanPart; ACol, ALane, AIndex: Integer): TPPGKanbanHit;
begin
  Result.Part := APart;
  Result.Col := ACol;
  Result.Lane := ALane;
  Result.Index := AIndex;
end;

function SameKHit(const A, B: TPPGKanbanHit): Boolean;
begin
  Result := (A.Part = B.Part) and (A.Col = B.Col) and (A.Lane = B.Lane) and (A.Index = B.Index);
end;

function PPGKanbanCardSpeech(const D: TPPGKanbanCardData; const ColumnTitle: string;
  Position, Count: Integer): string;
begin
  Result := Format(PPGStr(@SPPGKanbanAccCard), [D.Title, ColumnTitle, Position, Count]);
  if D.Due <> 0 then
    Result := Result + ', ' + Format(PPGStr(@SPPGKanbanAccDue), [FormatDateTime(FormatSettings.ShortDateFormat, D.Due)]);
  if D.Assignee <> '' then
    Result := Result + ', ' + D.Assignee;
  if D.Labels <> '' then
    Result := Result + ', ' + D.Labels;
  if D.Progress >= 0 then
    Result := Result + ', ' + IntToStr(D.Progress) + ' %';
end;

{ TPPGKanbanStyles }

constructor TPPGKanbanStyles.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, 5);
end;

{ TPPGCustomKanban }

constructor TPPGCustomKanban.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csDoubleClicks] - [csSetCaption, csClickEvents];
  FColumns := TPPGKanbanColumns.Create(Self);
  FLanes := TPPGKanbanLanes.Create(Self);
  FCards := TPPGKanbanCards.Create(Self);
  FColScroll := TDictionary<Integer, Integer>.Create;
  FHeights := TDictionary<TPPGKanbanCard, Integer>.Create;
  FMarkup := TPPGMarkupLayout.Create;
  FBold := TFont.Create;
  FKanbanStyles := TPPGKanbanStyles.Create(Self);
  FKanbanStyles.OnChange := KanbanStylesChanged;
  FDrawCanvas := TCanvas.Create;
  FSmall := TFont.Create;
  FShiftAnim := TPPGAnimation.Create(Self);
  FShiftAnim.OnStep := ShiftStep;
  FColAuto := TPPGAnimation.Create(Self);
  FColAuto.OnStep := ColAutoStep;
  FColumnWidth := 272;
  FCardGap := 8;
  FMaxTextLines := 3;
  FAllowDrag := True;
  FShowCardCount := True;
  FFocus := NoHit;
  FHot := NoHit;
  FPress := NoHit;
  FDrop := NoHit;
  FPrevDrop := NoHit;
  FThumbCol := -1;
  FColAutoCol := -1;
  TabStop := True;
  // Pfeile, Pos1, Ende gehoeren der Kartenauswahl, nicht dem Bildlauf
  KeyboardScrolling := False;
  Width := 640;
  Height := 400;
  SyncFonts;
  if GMsgKanbanAction = 0 then
    GMsgKanbanAction := RegisterWindowMessage('PPGlow.KanbanAction');
end;

destructor TPPGCustomKanban.Destroy;
begin
  if FShiftAnim <> nil then
    FShiftAnim.OnStep := nil;
  if FColAuto <> nil then
    FColAuto.OnStep := nil;
  FreeAndNil(FShiftAnim);
  FreeAndNil(FColAuto);
  FreeAndNil(FCards);
  FreeAndNil(FLanes);
  FreeAndNil(FColumns);
  FreeAndNil(FColScroll);
  FreeAndNil(FHeights);
  FreeAndNil(FMarkup);
  FreeAndNil(FBold);
  FreeAndNil(FDrawCanvas);
  FreeAndNil(FKanbanStyles);
  FreeAndNil(FSmall);
  inherited Destroy;
end;

procedure TPPGCustomKanban.Loaded;
begin
  inherited Loaded;
  LayoutChanged;
end;

procedure TPPGCustomKanban.SyncFonts;
begin
  if FBold = nil then
    Exit;
  FBold.Assign(Font);
  FBold.Style := Font.Style + [fsBold];
  FSmall.Assign(Font);
  // Untergrenze skaliert (Druck mit verkleinerter Aufloesung)
  FSmall.Height := -Max(Sc(9), Round(Abs(Font.Height) * 0.86));
end;

procedure TPPGCustomKanban.CMFontChanged(var Message: TMessage);
begin
  inherited;
  SyncFonts;
  LayoutChanged;
end;

procedure TPPGCustomKanban.ThemeChanged;
begin
  inherited ThemeChanged;
  LayoutChanged;
end;

procedure TPPGCustomKanban.KanbanModelChanged;
begin
  LayoutChanged;
end;

procedure TPPGCustomKanban.LayoutChanged;
begin
  if (csDestroying in ComponentState) or (FCards = nil) then
    Exit;
  FLayoutValid := False;
  if FHeights <> nil then
    FHeights.Clear;
  Invalidate;
end;

procedure TPPGCustomKanban.Resize;
begin
  inherited Resize;
  FLayoutValid := False;
end;

{ ---- Properties ---- }

procedure TPPGCustomKanban.SetColumns(const Value: TPPGKanbanColumns);
begin
  FColumns.Assign(Value);
end;

procedure TPPGCustomKanban.SetLanes(const Value: TPPGKanbanLanes);
begin
  FLanes.Assign(Value);
end;

procedure TPPGCustomKanban.SetCards(const Value: TPPGKanbanCards);
begin
  FCards.Assign(Value);
end;

procedure TPPGCustomKanban.SetColumnWidth(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'ColumnWidth', Value, 120, 2000);
  if V <> FColumnWidth then
  begin
    FColumnWidth := V;
    LayoutChanged;
  end;
end;

procedure TPPGCustomKanban.SetCardGap(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'CardGap', Value, 0, 64);
  if V <> FCardGap then
  begin
    FCardGap := V;
    LayoutChanged;
  end;
end;

procedure TPPGCustomKanban.SetMaxTextLines(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'MaxTextLines', Value, 0, 50);
  if V <> FMaxTextLines then
  begin
    FMaxTextLines := V;
    LayoutChanged;
  end;
end;

procedure TPPGCustomKanban.SetVirtualCardHeight(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'VirtualCardHeight', Value, 0, 1000);
  if V <> FVirtualCardHeight then
  begin
    FVirtualCardHeight := V;
    LayoutChanged;
  end;
end;

procedure TPPGCustomKanban.SetShowCardCount(const Value: Boolean);
begin
  if FShowCardCount <> Value then
  begin
    FShowCardCount := Value;
    Invalidate;
  end;
end;

function TPPGCustomKanban.GetSelectedCard: TPPGKanbanCard;
begin
  if FFocus.Part = kpCard then
    Result := CardAt(FFocus.Col, FFocus.Lane, FFocus.Index)
  else
    Result := nil;
end;

procedure TPPGCustomKanban.SetSelectedCard(const Value: TPPGKanbanCard);
var
  C, L, I: Integer;
begin
  if (Value <> nil) and FindCard(Value, C, L, I) then
    FFocus := KHit(kpCard, C, L, I)
  else
    FFocus := NoHit;
  Invalidate;
end;

{ ---- Masse ---- }

function TPPGCustomKanban.Sc(V: Integer): Integer;
begin
  Result := PPGScale(V, ScalePPI);
end;

function TPPGCustomKanban.TextH(F: TFont): Integer;
begin
  Result := PPGMeasureTextNoCanvas('Wg', F, 0, False).cy;
end;

function TPPGCustomKanban.CardPad: Integer;
begin
  Result := Sc(10);
end;

function TPPGCustomKanban.ColGap: Integer;
begin
  Result := Sc(12);
end;

function TPPGCustomKanban.BoardPad: Integer;
begin
  Result := Sc(12);
end;

function TPPGCustomKanban.CollapsedWidth: Integer;
begin
  Result := Sc(44);
end;

function TPPGCustomKanban.LaneHeaderHeight: Integer;
begin
  Result := TextH(FBold) + Sc(14);
end;

function TPPGCustomKanban.HasLanes: Boolean;
var
  I: Integer;
begin
  for I := 0 to FLanes.Count - 1 do
    if FLanes[I].Visible then
      Exit(True);
  Result := False;
end;

function TPPGCustomKanban.VirtualHeight: Integer;
begin
  if FVirtualCardHeight > 0 then
    Result := Sc(FVirtualCardHeight)
  else
    Result := 2 * CardPad + TextH(FBold) + Sc(6) + TextH(FSmall) + Sc(4);
end;

function TPPGCustomKanban.CardInnerWidth(C: Integer): Integer;
begin
  Result := FCols[C].W - 2 * Sc(8);
end;

function TPPGCustomKanban.MeasureCard(const D: TPPGKanbanCardData; W: Integer): Integer;
var
  Inner, Lh, TH: Integer;
  TitleF, Temp: TFont;
begin
  Inner := W - 2 * CardPad;
  if D.Color <> clNone then
    Dec(Inner, Sc(4));
  Result := CardPad;
  if D.Labels <> '' then
    Inc(Result, TextH(FSmall) + Sc(4) + Sc(6));
  // Titel: hoechstens zwei Zeilen, in der Schrift des Karten-Stils
  Temp := nil;
  try
    if FKanbanStyles.Card.HasOwnFont then
      TitleF := PPGStyledFont(FKanbanStyles.Card.Font, [fsBold] + FKanbanStyles.Card.FontStyle, Temp)
    else
      TitleF := PPGStyledFont(FBold, FKanbanStyles.Card.FontStyle, Temp);
    Lh := TextH(TitleF);
    TH := PPGMeasureTextNoCanvas(D.Title, TitleF, Max(10, Inner), True).cy;
    Inc(Result, Max(Lh, Min(TH, 2 * Lh)));
  finally
    Temp.Free;
  end;
  if (D.Text <> '') and (FMaxTextLines > 0) then
  begin
    FMarkup.Layout(D.Text, Font, nil, Max(10, Inner), True);
    Inc(Result, Sc(4) + Min(FMarkup.Size.cy, FMaxTextLines * TextH(Font)));
  end;
  if (D.Due <> 0) or (D.Assignee <> '') then
    Inc(Result, Sc(8) + Max(TextH(FSmall), Sc(22)));
  Inc(Result, CardPad);
  if D.Progress >= 0 then
    Inc(Result, Sc(6));
end;

{ ---- Layout ---- }

procedure TPPGCustomKanban.EnsureLayout;
var
  NC, NL, C, L, I, X, W, Y, MaxBottom, ContentW, ContentH, VH, CW: Integer;
  Col: TPPGKanbanColumn;
  Card: TPPGKanbanCard;
  Laned: Boolean;
  Cell: TPPGKanbanCell;
  H: Integer;
  LaneIds: array of Integer;
  Hts: TArray<Integer>;
  TitleTemp: TFont;
begin
  if FLayoutValid then
    Exit;
  FLayoutValid := True;
  // Kopfhoehe nach der Titel-Schrift des Spalten-Stils
  TitleTemp := nil;
  try
    if FKanbanStyles.Column.HasOwnFont then
      FHeaderH := TextH(PPGStyledFont(FKanbanStyles.Column.Font, [fsBold], TitleTemp)) + Sc(20)
    else
      FHeaderH := TextH(PPGStyledFont(FBold, FKanbanStyles.Column.FontStyle, TitleTemp)) + Sc(20);
  finally
    TitleTemp.Free;
  end;
  Laned := HasLanes;
  // Swimlanes
  NL := 0;
  if Laned then
  begin
    for L := 0 to FLanes.Count - 1 do
      if FLanes[L].Visible then
        Inc(NL);
    SetLength(FLaneL, NL);
    SetLength(LaneIds, NL);
    NL := 0;
    for L := 0 to FLanes.Count - 1 do
      if FLanes[L].Visible then
      begin
        FLaneL[NL].Lane := FLanes[L];
        LaneIds[NL] := FLanes[L].Id;
        Inc(NL);
      end;
  end
  else
  begin
    NL := 1;
    SetLength(FLaneL, 1);
    SetLength(LaneIds, 1);
    FLaneL[0].Lane := nil;
    LaneIds[0] := 0;
  end;
  // Spalten
  NC := 0;
  for C := 0 to FColumns.Count - 1 do
    if FColumns[C].Visible then
      Inc(NC);
  SetLength(FCols, NC);
  NC := 0;
  X := BoardPad;
  VH := VirtualHeight;
  for C := 0 to FColumns.Count - 1 do
  begin
    Col := FColumns[C];
    if not Col.Visible then
      Continue;
    FCols[NC].Column := Col;
    FCols[NC].Collapsed := Col.Collapsed;
    if Col.Collapsed then
      W := CollapsedWidth
    else if Col.Width > 0 then
      W := Sc(Col.Width)
    else
      W := Sc(FColumnWidth);
    FCols[NC].X := X;
    FCols[NC].W := W;
    SetLength(FCols[NC].Cells, NL);
    for L := 0 to NL - 1 do
    begin
      Cell.Cards := nil;
      Cell.Count := 0;
      Cell.Virtual := Col.VirtualCount > 0;
      Cell.Tops := nil;
      Cell.Heights := nil;
      Cell.Top := 0;
      Cell.Bottom := 0;
      if Cell.Virtual then
      begin
        // virtuelle Karten stehen in der ersten Swimlane
        if L = 0 then
          Cell.Count := Col.VirtualCount;
      end;
      FCols[NC].Cells[L] := Cell;
    end;
    Inc(NC);
    Inc(X, W + ColGap);
  end;
  ContentW := X - ColGap + BoardPad;
  if NC = 0 then
    ContentW := 0;
  // Karten in Zellen verteilen (Reihenfolge der Collection)
  for I := 0 to FCards.Count - 1 do
  begin
    Card := FCards[I];
    for C := 0 to NC - 1 do
      if (FCols[C].Column.Id = Card.ColumnId) and not FCols[C].Cells[0].Virtual then
      begin
        L := 0;
        if Laned then
        begin
          L := -1;
          for H := 0 to NL - 1 do
            if LaneIds[H] = Card.LaneId then
              L := H;
          // Karten unbekannter Swimlane: in die erste
          if L < 0 then
            L := 0;
        end;
        with FCols[C].Cells[L] do
        begin
          SetLength(Cards, Count + 1);
          Cards[Count] := Card;
          Inc(Count);
        end;
        Break;
      end;
  end;
  // Hoehen und Stapel
  for C := 0 to NC - 1 do
  begin
    CW := CardInnerWidth(C);
    for L := 0 to NL - 1 do
    begin
      if FCols[C].Cells[L].Virtual then
        Continue;
      SetLength(Hts, FCols[C].Cells[L].Count);
      for I := 0 to FCols[C].Cells[L].Count - 1 do
      begin
        Card := FCols[C].Cells[L].Cards[I];
        if not FHeights.TryGetValue(Card, H) then
        begin
          H := MeasureCard(Card.AsData, CW);
          FHeights.Add(Card, H);
        end;
        Hts[I] := H;
      end;
      FCols[C].Cells[L].Heights := Copy(Hts);
      PPGKanbanStack(Hts, 0, Sc(FCardGap), FCols[C].Cells[L].Tops);
    end;
  end;
  // Lage der Swimlanes und Zellen (Inhalts-Y)
  if Laned then
  begin
    Y := FHeaderH + Sc(4);
    for L := 0 to NL - 1 do
    begin
      FLaneL[L].Top := Y;
      FLaneL[L].BodyTop := Y + LaneHeaderHeight;
      MaxBottom := 0;
      if not FLaneL[L].Lane.Collapsed then
        for C := 0 to NC - 1 do
          if not FCols[C].Collapsed then
            with FCols[C].Cells[L] do
            begin
              if Virtual then
                H := Count * VH + Max(0, Count - 1) * Sc(FCardGap)
              else if Count > 0 then
                H := Tops[Count - 1] + Heights[Count - 1]
              else
                H := 0;
              MaxBottom := Max(MaxBottom, H);
            end;
      if FLaneL[L].Lane.Collapsed then
        FLaneL[L].BodyHeight := 0
      else
        FLaneL[L].BodyHeight := Max(Sc(64), MaxBottom + Sc(16));
      for C := 0 to NC - 1 do
      begin
        FCols[C].Cells[L].Top := FLaneL[L].BodyTop + Sc(8);
        FCols[C].Cells[L].Bottom := FLaneL[L].BodyTop + FLaneL[L].BodyHeight;
      end;
      Y := FLaneL[L].BodyTop + FLaneL[L].BodyHeight;
    end;
    ContentH := Y + Sc(8);
  end
  else
  begin
    FLaneL[0].Top := FHeaderH;
    FLaneL[0].BodyTop := FHeaderH;
    FLaneL[0].BodyHeight := 0;
    for C := 0 to NC - 1 do
      with FCols[C].Cells[0] do
      begin
        Top := FHeaderH + Sc(4);
        if Virtual then
          Bottom := Top + Count * VH + Max(0, Count - 1) * Sc(FCardGap)
        else if Count > 0 then
          Bottom := Top + Tops[Count - 1] + Heights[Count - 1]
        else
          Bottom := Top;
      end;
    // ohne Swimlanes scrollen die Spalten, nicht das Board
    ContentH := 0;
  end;
  SetContentSize(ContentW, ContentH);
  // Fokus und Scrollpositionen gueltig halten
  if (FFocus.Part = kpCard) and ((FFocus.Col >= NC) or (FFocus.Lane >= NL) or
    (FFocus.Index >= CellCount(FFocus.Col, FFocus.Lane))) then
    FFocus := NoHit;
end;

function TPPGCustomKanban.ColumnCount: Integer;
begin
  EnsureLayout;
  Result := Length(FCols);
end;

function TPPGCustomKanban.LayoutColumn(C: Integer): TPPGKanbanColumn;
begin
  EnsureLayout;
  if (C >= 0) and (C <= High(FCols)) then
    Result := FCols[C].Column
  else
    Result := nil;
end;

function TPPGCustomKanban.ColumnIndexOf(Column: TPPGKanbanColumn): Integer;
var
  C: Integer;
begin
  EnsureLayout;
  for C := 0 to High(FCols) do
    if FCols[C].Column = Column then
      Exit(C);
  Result := -1;
end;

function TPPGCustomKanban.LaneCount: Integer;
begin
  EnsureLayout;
  Result := Length(FLaneL);
end;

function TPPGCustomKanban.LayoutLane(L: Integer): TPPGKanbanLane;
begin
  EnsureLayout;
  if (L >= 0) and (L <= High(FLaneL)) then
    Result := FLaneL[L].Lane
  else
    Result := nil;
end;

function TPPGCustomKanban.CellCount(C, L: Integer): Integer;
begin
  if (C < 0) or (C > High(FCols)) or (L < 0) or (L > High(FCols[C].Cells)) then
    Result := 0
  else
    Result := FCols[C].Cells[L].Count;
end;

function TPPGCustomKanban.CardCount(C, L: Integer): Integer;
begin
  EnsureLayout;
  Result := CellCount(C, L);
end;

function TPPGCustomKanban.CardAt(C, L, I: Integer): TPPGKanbanCard;
begin
  EnsureLayout;
  Result := nil;
  if (I >= 0) and (I < CellCount(C, L)) and not FCols[C].Cells[L].Virtual then
    Result := FCols[C].Cells[L].Cards[I];
end;

function TPPGCustomKanban.CardData(C, L, I: Integer): TPPGKanbanCardData;
begin
  EnsureLayout;
  PPGKanbanClearData(Result);
  if (I < 0) or (I >= CellCount(C, L)) then
    Exit;
  if FCols[C].Cells[L].Virtual then
  begin
    if Assigned(FOnGetCard) then
      FOnGetCard(Self, FCols[C].Column, I, Result);
  end
  else
    Result := FCols[C].Cells[L].Cards[I].AsData;
end;

function TPPGCustomKanban.FindCard(Card: TPPGKanbanCard; out C, L, I: Integer): Boolean;
var
  CC, LL, II: Integer;
begin
  EnsureLayout;
  for CC := 0 to High(FCols) do
    for LL := 0 to High(FCols[CC].Cells) do
      for II := 0 to FCols[CC].Cells[LL].Count - 1 do
        if not FCols[CC].Cells[LL].Virtual and (FCols[CC].Cells[LL].Cards[II] = Card) then
        begin
          C := CC;
          L := LL;
          I := II;
          Exit(True);
        end;
  C := -1;
  L := -1;
  I := -1;
  Result := False;
end;

function TPPGCustomKanban.ColumnCardCount(C: Integer): Integer;
var
  L: Integer;
begin
  EnsureLayout;
  Result := 0;
  if (C < 0) or (C > High(FCols)) then
    Exit;
  for L := 0 to High(FCols[C].Cells) do
    Inc(Result, FCols[C].Cells[L].Count);
end;

function TPPGCustomKanban.WipState(C: Integer): TPPGKanbanWipState;
begin
  if (C < 0) or (C >= ColumnCount) then
    Result := kwsNone
  else
    Result := PPGKanbanWipState(ColumnCardCount(C), FCols[C].Column.WipLimit);
end;

{ ---- Koordinaten ---- }

function TPPGCustomKanban.ToClientX(CX, W: Integer): Integer;
var
  V: TRect;
begin
  V := ViewRect;
  if UseRightToLeftAlignment then
    Result := V.Right - (CX - ScrollX) - W
  else
    Result := V.Left + CX - ScrollX;
end;

function TPPGCustomKanban.ToContentX(X: Integer): Integer;
var
  V: TRect;
begin
  V := ViewRect;
  if UseRightToLeftAlignment then
    Result := V.Right - X + ScrollX
  else
    Result := X - V.Left + ScrollX;
end;

function TPPGCustomKanban.ColClientRect(C: Integer): TRect;
var
  V: TRect;
  L: Integer;
begin
  V := ViewRect;
  L := ToClientX(FCols[C].X, FCols[C].W);
  if HasLanes then
    Result := Rect(L, V.Top, L + FCols[C].W, Max(V.Top + FHeaderH,
      Min(V.Bottom, V.Top + ContentHeight - ScrollY - Sc(8))))
  else
    Result := Rect(L, V.Top, L + FCols[C].W, V.Bottom - Sc(4));
end;

function TPPGCustomKanban.ColumnRect(C: Integer): TRect;
begin
  EnsureLayout;
  if (C < 0) or (C > High(FCols)) then
    Exit(Rect(0, 0, 0, 0));
  Result := ColClientRect(C);
end;

function TPPGCustomKanban.HeaderRect(C: Integer): TRect;
begin
  Result := ColumnRect(C);
  if not IsRectEmpty(Result) and not FCols[C].Collapsed then
    Result.Bottom := Result.Top + FHeaderH;
end;

function TPPGCustomKanban.LaneHeaderRect(L: Integer): TRect;
var
  V: TRect;
  Y: Integer;
begin
  EnsureLayout;
  Result := Rect(0, 0, 0, 0);
  if not HasLanes or (L < 0) or (L > High(FLaneL)) then
    Exit;
  V := ViewRect;
  Y := V.Top + FLaneL[L].Top - ScrollY;
  Result := Rect(ToClientX(BoardPad, ContentWidth - 2 * BoardPad), Y,
    ToClientX(BoardPad, ContentWidth - 2 * BoardPad) + ContentWidth - 2 * BoardPad, Y + LaneHeaderHeight);
end;

function TPPGCustomKanban.BodyRect(C: Integer): TRect;
begin
  Result := ColClientRect(C);
  Result.Top := Result.Top + FHeaderH;
end;

function TPPGCustomKanban.GetColScroll(C: Integer): Integer;
begin
  if HasLanes or (C < 0) or (C > High(FCols)) or not FColScroll.TryGetValue(FCols[C].Column.Id, Result) then
    Result := 0;
end;

function TPPGCustomKanban.ColMaxScroll(C: Integer): Integer;
var
  B: TRect;
begin
  Result := 0;
  if HasLanes or (C < 0) or (C > High(FCols)) then
    Exit;
  B := BodyRect(C);
  Result := Max(0, (FCols[C].Cells[0].Bottom - FHeaderH) + Sc(12) - (B.Bottom - B.Top));
end;

procedure TPPGCustomKanban.SetColScroll(C, Value: Integer);
begin
  if HasLanes or (C < 0) or (C > High(FCols)) then
    Exit;
  Value := Max(0, Min(Value, ColMaxScroll(C)));
  FColScroll.AddOrSetValue(FCols[C].Column.Id, Value);
  Invalidate;
end;

function TPPGCustomKanban.ColumnScroll(C: Integer): Integer;
begin
  EnsureLayout;
  Result := GetColScroll(C);
end;

procedure TPPGCustomKanban.ScrollColumn(C, Delta: Integer);
begin
  EnsureLayout;
  SetColScroll(C, GetColScroll(C) + Delta);
end;

function TPPGCustomKanban.CardOffsetY(C, L: Integer): Integer;
var
  V: TRect;
begin
  // Inhalts-Y der Zelle -> Client-Y
  V := ViewRect;
  if HasLanes then
    Result := V.Top - ScrollY
  else
    Result := V.Top - GetColScroll(C);
end;

function TPPGCustomKanban.RawCardRect(C, L, I: Integer): TRect;
var
  Y, X, H: Integer;
begin
  with FCols[C].Cells[L] do
  begin
    if Virtual then
    begin
      H := VirtualHeight;
      Y := Top + I * (H + Sc(FCardGap));
    end
    else
    begin
      H := Heights[I];
      Y := Top + Tops[I];
    end;
  end;
  Y := Y + CardOffsetY(C, L);
  X := ToClientX(FCols[C].X, FCols[C].W) + Sc(8);
  Result := Rect(X, Y, X + CardInnerWidth(C), Y + H);
end;

function TPPGCustomKanban.CardRect(C, L, I: Integer): TRect;
begin
  EnsureLayout;
  if (I < 0) or (I >= CellCount(C, L)) or FCols[C].Collapsed or
    (HasLanes and FLaneL[L].Lane.Collapsed) then
    Exit(Rect(0, 0, 0, 0));
  Result := RawCardRect(C, L, I);
end;

function TPPGCustomKanban.ThumbRectOf(C: Integer): TRect;
var
  B: TRect;
  Total, View, Th, Y, Mx: Integer;
begin
  Result := Rect(0, 0, 0, 0);
  Mx := ColMaxScroll(C);
  if (Mx <= 0) or FCols[C].Collapsed then
    Exit;
  B := BodyRect(C);
  View := B.Bottom - B.Top;
  Total := View + Mx;
  Th := Max(Sc(24), View * View div Max(1, Total));
  Y := B.Top + (View - Th) * GetColScroll(C) div Mx;
  if UseRightToLeftAlignment then
    Result := Rect(B.Left + Sc(2), Y, B.Left + Sc(6), Y + Th)
  else
    Result := Rect(B.Right - Sc(6), Y, B.Right - Sc(2), Y + Th);
end;

procedure TPPGCustomKanban.MakeCardVisible(C, L, I: Integer);
var
  R, B: TRect;
  V: TRect;
begin
  EnsureLayout;
  if (I < 0) or (I >= CellCount(C, L)) then
    Exit;
  // waagerecht
  V := ViewRect;
  R := ColClientRect(C);
  if R.Left < V.Left then
    ScrollBy(-(V.Left - R.Left) * IfThen(UseRightToLeftAlignment, -1, 1), 0)
  else if R.Right > V.Right then
    ScrollBy((R.Right - V.Right) * IfThen(UseRightToLeftAlignment, -1, 1), 0);
  R := RawCardRect(C, L, I);
  if HasLanes then
  begin
    B := Rect(V.Left, V.Top + FHeaderH, V.Right, V.Bottom);
    if R.Top < B.Top then
      ScrollBy(0, R.Top - B.Top)
    else if R.Bottom > B.Bottom then
      ScrollBy(0, R.Bottom - B.Bottom);
  end
  else
  begin
    B := BodyRect(C);
    if R.Top < B.Top + Sc(4) then
      SetColScroll(C, GetColScroll(C) - (B.Top + Sc(4) - R.Top))
    else if R.Bottom > B.Bottom - Sc(4) then
      SetColScroll(C, GetColScroll(C) + (R.Bottom - (B.Bottom - Sc(4))));
  end;
end;

{ ---- Treffer ---- }

function TPPGCustomKanban.HitTest(X, Y: Integer): TPPGKanbanHit;
var
  C, L, I, CX, N, First: Integer;
  P: TPoint;
  R, B: TRect;
  Lo, Hi, Mid, VH, Step, Rel: Integer;
begin
  EnsureLayout;
  Result := NoHit;
  P := Point(X, Y);
  if not PtInRect(ViewRect, P) then
    Exit;
  CX := ToContentX(X);
  // Swimlane-Koepfe (ueber die ganze Breite)
  if HasLanes and (Y >= ViewRect.Top + FHeaderH) then
    for L := 0 to High(FLaneL) do
      if PtInRect(LaneHeaderRect(L), P) then
        Exit(KHit(kpLane, -1, L, -1));
  for C := 0 to High(FCols) do
  begin
    if (CX < FCols[C].X) or (CX >= FCols[C].X + FCols[C].W) then
      Continue;
    R := ColClientRect(C);
    if FCols[C].Collapsed then
      Exit(KHit(kpCollapse, C, -1, -1));
    if Y < R.Top + FHeaderH then
    begin
      // Einklapp-Knopf rechts im Kopf
      if (UseRightToLeftAlignment and (X < R.Left + Sc(32))) or
        (not UseRightToLeftAlignment and (X >= R.Right - Sc(32))) then
        Exit(KHit(kpCollapse, C, -1, -1));
      Exit(KHit(kpHeader, C, -1, -1));
    end;
    if PtInRect(ThumbRectOf(C), P) or (not IsRectEmpty(ThumbRectOf(C)) and
      (Abs(X - (ThumbRectOf(C).Left + ThumbRectOf(C).Right) div 2) <= Sc(5))) then
      Exit(KHit(kpThumb, C, -1, -1));
    // Swimlane unter der Maus
    L := 0;
    if HasLanes then
    begin
      L := -1;
      for I := 0 to High(FLaneL) do
      begin
        B := Rect(R.Left, ViewRect.Top + FLaneL[I].BodyTop - ScrollY, R.Right,
          ViewRect.Top + FLaneL[I].BodyTop + FLaneL[I].BodyHeight - ScrollY);
        if PtInRect(B, P) then
          L := I;
      end;
      if L < 0 then
        Exit;
    end;
    N := FCols[C].Cells[L].Count;
    if N > 0 then
    begin
      if FCols[C].Cells[L].Virtual then
      begin
        VH := VirtualHeight;
        Step := VH + Sc(FCardGap);
        Rel := Y - CardOffsetY(C, L) - FCols[C].Cells[L].Top;
        if Rel >= 0 then
        begin
          I := Rel div Step;
          if (I < N) and (Rel - I * Step < VH) then
            Exit(KHit(kpCard, C, L, I));
        end;
      end
      else
      begin
        // binaere Suche nach der Karte unter Y
        Lo := 0;
        Hi := N - 1;
        First := N;
        while Lo <= Hi do
        begin
          Mid := (Lo + Hi) div 2;
          if RawCardRect(C, L, Mid).Bottom > Y then
          begin
            First := Mid;
            Hi := Mid - 1;
          end
          else
            Lo := Mid + 1;
        end;
        if (First < N) and PtInRect(RawCardRect(C, L, First), P) then
          Exit(KHit(kpCard, C, L, First));
      end;
    end;
    Exit(KHit(kpCell, C, L, -1));
  end;
end;

{ ---- Layout speichern ---- }

function TPPGCustomKanban.BoardHeight: Integer;
var
  C: Integer;
begin
  EnsureLayout;
  if HasLanes then
    Exit(ContentHeight);
  // Ohne Swimlanes scrollen die Spalten einzeln: die laengste zaehlt
  Result := FHeaderH + Sc(16);
  for C := 0 to High(FCols) do
    if not FCols[C].Collapsed then
      Result := Max(Result, FCols[C].Cells[0].Bottom + Sc(16));
end;

function TPPGCustomKanban.SaveLayout: string;
var
  L: TStringList;
  I: Integer;
begin
  L := TStringList.Create;
  try
    L.Add('[PPGKanbanLayout]');
    L.Add('Version=1');
    for I := 0 to FColumns.Count - 1 do
      L.Add(Format('Column.%d=%d,%d', [FColumns[I].Id, FColumns[I].Width,
        Ord(FColumns[I].Collapsed)]));
    for I := 0 to FLanes.Count - 1 do
      L.Add(Format('Lane.%d=%d', [FLanes[I].Id, Ord(FLanes[I].Collapsed)]));
    Result := L.Text;
  finally
    L.Free;
  end;
end;

procedure TPPGCustomKanban.LoadLayout(const S: string);
var
  L: TStringList;
  I, P, Id, W, Cl: Integer;
  Key, Val: string;
  Col: TPPGKanbanColumn;
  Lane: TPPGKanbanLane;
begin
  L := TStringList.Create;
  try
    L.Text := S;
    if (L.Count = 0) or (Trim(L[0]) <> '[PPGKanbanLayout]') then
      Exit; // kein Layout dieses Boards: unveraendert lassen
    FColumns.BeginUpdate;
    FLanes.BeginUpdate;
    try
      for I := 0 to L.Count - 1 do
      begin
        P := Pos('=', L[I]);
        if P = 0 then
          Continue;
        Key := Copy(L[I], 1, P - 1);
        Val := Copy(L[I], P + 1, MaxInt);
        if SameText(Copy(Key, 1, 7), 'Column.') and
          TryStrToInt(Copy(Key, 8, MaxInt), Id) then
        begin
          Col := FColumns.FindById(Id);
          P := Pos(',', Val);
          if (Col <> nil) and (P > 0) and TryStrToInt(Copy(Val, 1, P - 1), W) and
            TryStrToInt(Copy(Val, P + 1, MaxInt), Cl) then
          begin
            Col.Collapsed := Cl <> 0;
            try
              Col.Width := W;
            except
              on EPPGPropertyError do
                ; // Breite ausserhalb des Bereichs: Vorgabe behalten
            end;
          end;
        end
        else if SameText(Copy(Key, 1, 5), 'Lane.') and
          TryStrToInt(Copy(Key, 6, MaxInt), Id) and TryStrToInt(Val, Cl) then
        begin
          Lane := FLanes.FindById(Id);
          if Lane <> nil then
            Lane.Collapsed := Cl <> 0;
        end;
      end;
    finally
      FLanes.EndUpdate;
      FColumns.EndUpdate;
    end;
  finally
    L.Free;
  end;
  LayoutChanged;
end;

{ ---- Zeichnen ---- }

procedure TPPGCustomKanban.SetKanbanStyles(const Value: TPPGKanbanStyles);
begin
  FKanbanStyles.Assign(Value);
end;

procedure TPPGCustomKanban.KanbanStylesChanged(Sender: TObject);
begin
  LayoutChanged; // Schrift der Kartentitel bestimmt die Hoehe
end;

procedure TPPGCustomKanban.PaintCard(const ACanvas: IPPGCanvas; const R: TRect;
  const D: TPPGKanbanCardData; const DS: TPPGDrawStyle; Selected, Hot, Ghost: Boolean);
var
  KS: TPPGKanbanStyles;
  SelCol: TColor;
  TitleF, Temp: TFont;
  T: TPPGTokens;
  Fill, Stroke, TextCol, Sec, Col: TColor;
  HC, Dark, RTL: Boolean;
  Inner, LR, TR, FR: TRect;
  Labels: TArray<string>;
  I, X, W, Lh, TH, Av, Rad: Integer;
  S: string;
  Overdue: Boolean;
begin
  T := Tokens;
  HC := HighContrastSupport and PPGIsHighContrast;
  Dark := UseDarkMode;
  RTL := UseRightToLeftAlignment;
  Rad := Sc(6);
  if HC then
  begin
    Fill := PPGColorToRGB(clWindow);
    Stroke := PPGColorToRGB(clWindowText);
    TextCol := PPGColorToRGB(clWindowText);
    Sec := TextCol;
  end
  else
  begin
    Fill := T.Surface;
    if Hot then
      Fill := T.SurfaceHover;
    Stroke := T.Stroke;
    TextCol := T.TextPrimary;
    Sec := T.TextSecondary;
    // Element-Stile (KanbanStyles) und eigenes Zeichnen
    if not UseVclStyle then
    begin
      KS := FKanbanStyles;
      Fill := KS.Card.FillFor(Dark, Fill);
      if Hot then
        Fill := KS.HotCard.FillFor(Dark, Fill);
      Stroke := KS.Card.BorderFor(Dark, Stroke);
      TextCol := KS.Card.TextFor(Dark, TextCol);
      if DS.Fill <> clNone then
        Fill := PPGColorToRGB(DS.Fill);
      if DS.BorderColor <> clNone then
        Stroke := PPGColorToRGB(DS.BorderColor);
      if DS.TextColor <> clNone then
        TextCol := PPGColorToRGB(DS.TextColor);
    end;
  end;
  SelCol := PPGColorToRGB(EffectiveAppearance.FocusColor);
  if not HC and not UseVclStyle then
    SelCol := FKanbanStyles.SelectedCard.BorderFor(Dark, SelCol);
  if Ghost then
    ACanvas.DrawOuterGlow(R, Rad, Sc(8), PPGColorToRGB(clBlack), 60);
  ACanvas.FillRoundRect(R, Rad, Fill, 255);
  if Selected then
    ACanvas.FrameRoundRect(R, Rad, Sc(2), SelCol, 255)
  else
    ACanvas.FrameRoundRect(R, Rad, 1, Stroke, 255);
  Inner := R;
  InflateRect(Inner, -CardPad, -CardPad);
  // Farbstreifen
  if D.Color <> clNone then
  begin
    if RTL then
    begin
      ACanvas.FillRoundRect(Rect(R.Right - Sc(5), R.Top + Sc(6), R.Right - Sc(2), R.Bottom - Sc(6)), Sc(2),
        PPGColorToRGB(D.Color), 255);
      Dec(Inner.Right, Sc(4));
    end
    else
    begin
      ACanvas.FillRoundRect(Rect(R.Left + Sc(2), R.Top + Sc(6), R.Left + Sc(5), R.Bottom - Sc(6)), Sc(2),
        PPGColorToRGB(D.Color), 255);
      Inc(Inner.Left, Sc(4));
    end;
  end;
  // Plaketten
  if D.Labels <> '' then
  begin
    Labels := PPGKanbanSplitLabels(D.Labels);
    Lh := TextH(FSmall) + Sc(4);
    X := Inner.Left;
    if RTL then
      X := Inner.Right;
    for I := 0 to High(Labels) do
    begin
      W := PPGMeasureTextNoCanvas(Labels[I], FSmall, 0, False).cx + Sc(12);
      if RTL then
      begin
        if X - W < Inner.Left then
          Break;
        LR := Rect(X - W, Inner.Top, X, Inner.Top + Lh);
        Dec(X, W + Sc(4));
      end
      else
      begin
        if X + W > Inner.Right then
          Break;
        LR := Rect(X, Inner.Top, X + W, Inner.Top + Lh);
        Inc(X, W + Sc(4));
      end;
      if HC then
      begin
        ACanvas.FrameRoundRect(LR, Lh div 2, 1, TextCol, 255);
        ACanvas.DrawText(LR, Labels[I], FSmall, TextCol, DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
      end
      else
      begin
        Col := PPGChartColor(T, Dark, PPGKanbanHashIndex(Labels[I], 8));
        ACanvas.FillRoundRect(LR, Lh div 2, Col, 40);
        ACanvas.DrawText(LR, Labels[I], FSmall, PPGBlendColor(Col, TextCol, 0.45),
          DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
      end;
    end;
    Inner.Top := Inner.Top + Lh + Sc(6);
  end;
  // Titel (hoechstens zwei Zeilen)
  Temp := nil;
  try
    // Titel-Schrift: Karten-Stil (eigene Schrift/Stile) und eigenes Zeichnen
    if FKanbanStyles.Card.HasOwnFont then
      TitleF := PPGStyledFont(FKanbanStyles.Card.Font, [fsBold] + FKanbanStyles.Card.FontStyle +
        DS.FontStyle, Temp)
    else
      TitleF := PPGStyledFont(FBold, FKanbanStyles.Card.FontStyle + DS.FontStyle, Temp);
    Lh := TextH(TitleF);
    TH := PPGMeasureTextNoCanvas(D.Title, TitleF, Max(10, Inner.Right - Inner.Left), True).cy;
    TH := Max(Lh, Min(TH, 2 * Lh));
    TR := Rect(Inner.Left, Inner.Top, Inner.Right, Inner.Top + TH);
    ACanvas.DrawText(TR, D.Title, TitleF, TextCol, DrawTextBiDiModeFlags(DT_WORDBREAK or DT_NOPREFIX or
      DT_END_ELLIPSIS or DT_EDITCONTROL));
  finally
    Temp.Free;
  end;
  Inner.Top := TR.Bottom;
  // Text mit Markup (hoechstens MaxTextLines Zeilen)
  if (D.Text <> '') and (FMaxTextLines > 0) then
  begin
    FMarkup.Layout(D.Text, Font, nil, Max(10, Inner.Right - Inner.Left), True);
    TH := Min(FMarkup.Size.cy, FMaxTextLines * TextH(Font));
    TR := Rect(Inner.Left, Inner.Top + Sc(4), Inner.Right, Inner.Top + Sc(4) + TH);
    ACanvas.PushClipRoundRect(TR, 0);
    try
      if RTL then
        FMarkup.Draw(ACanvas, TR.Right - FMarkup.Size.cx, TR.Top, Sec, PPGColorToRGB(EffectiveAppearance.FocusColor))
      else
        FMarkup.Draw(ACanvas, TR.Left, TR.Top, Sec, PPGColorToRGB(EffectiveAppearance.FocusColor));
    finally
      ACanvas.PopClip;
    end;
    Inner.Top := TR.Bottom;
  end;
  // Fusszeile: Faelligkeit und Person
  if (D.Due <> 0) or (D.Assignee <> '') then
  begin
    Av := Max(TextH(FSmall), Sc(22));
    FR := Rect(Inner.Left, Inner.Top + Sc(8), Inner.Right, Inner.Top + Sc(8) + Av);
    if D.Due <> 0 then
    begin
      Overdue := Trunc(D.Due) < Trunc(Now);
      if HC then
        Col := TextCol
      else if Overdue then
        Col := T.Danger
      else
        Col := Sec;
      S := FormatDateTime('dd.mm.', D.Due);
      if RTL then
        LR := Rect(FR.Right - Sc(16), FR.Top, FR.Right, FR.Bottom)
      else
        LR := Rect(FR.Left, FR.Top, FR.Left + Sc(16), FR.Bottom);
      if not PPGDrawIcon(ACanvas, LR, igCalendar, Col, Sc(12)) then
        ACanvas.FrameRoundRect(Rect(LR.Left + Sc(2), LR.Top + Sc(5), LR.Right - Sc(2), LR.Bottom - Sc(5)), Sc(2),
          1, Col, 255);
      if RTL then
        LR := Rect(FR.Left, FR.Top, LR.Left - Sc(4), FR.Bottom)
      else
        LR := Rect(LR.Right + Sc(4), FR.Top, FR.Right, FR.Bottom);
      ACanvas.DrawText(LR, S, FSmall, Col, DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX));
    end;
    if D.Assignee <> '' then
    begin
      if RTL then
        LR := Rect(FR.Left, FR.Top, FR.Left + Av, FR.Top + Av)
      else
        LR := Rect(FR.Right - Av, FR.Top, FR.Right, FR.Top + Av);
      if HC then
      begin
        ACanvas.FrameEllipse(LR, 1, TextCol, 255);
        Col := TextCol;
      end
      else
      begin
        Col := PPGChartColor(T, Dark, PPGKanbanHashIndex(D.Assignee, 8));
        ACanvas.FillEllipse(LR, Col, 255);
        Col := clWhite;
        if PPGContrastRatio(Col, PPGChartColor(T, Dark, PPGKanbanHashIndex(D.Assignee, 8))) < 3 then
          Col := clBlack;
      end;
      ACanvas.DrawText(LR, PPGKanbanInitials(D.Assignee), FSmall, Col,
        DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
    end;
  end;
  // Fortschritt als Balken unten
  if D.Progress >= 0 then
  begin
    LR := Rect(R.Left + CardPad, R.Bottom - Sc(8), R.Right - CardPad, R.Bottom - Sc(5));
    ACanvas.FillRoundRect(LR, Sc(2), PPGBlendColor(Fill, TextCol, 0.15), 255);
    W := (LR.Right - LR.Left) * D.Progress div 100;
    if W > 0 then
      if RTL then
        ACanvas.FillRoundRect(Rect(LR.Right - W, LR.Top, LR.Right, LR.Bottom), Sc(2), IfThen(D.Progress >= 100,
          T.Success, T.Accent), 255)
      else
        ACanvas.FillRoundRect(Rect(LR.Left, LR.Top, LR.Left + W, LR.Bottom), Sc(2), IfThen(D.Progress >= 100,
          T.Success, T.Accent), 255);
  end;
end;

procedure TPPGCustomKanban.PaintColumn(const ACanvas: IPPGCanvas; C: Integer; const View: TRect);
var
  Sw: Integer;
  T: TPPGTokens;
  R, HR, B, CR, Clip, Ph: TRect;
  HC: Boolean;
  Back, TextCol, Sec, Accent, Col: TColor;
  L, I, First, N, Sh, Cnt: Integer;
  S: string;
  W: TPPGKanbanWipState;
  D: TPPGKanbanCardData;
  DC: HDC;
  LF: TLogFont;
  Fnt, OldF: HFONT;
  Hot: Boolean;
  TitleF, Temp: TFont;
  DS: TPPGDrawStyle;
  St: TPPGItemDrawState;
  DrawIt, CardSel, CardHot: Boolean;
begin
  T := Tokens;
  HC := HighContrastSupport and PPGIsHighContrast;
  if HC then
  begin
    Back := PPGColorToRGB(clBtnFace);
    TextCol := PPGColorToRGB(clBtnText);
    Sec := TextCol;
    Accent := PPGColorToRGB(clHighlight);
  end
  else
  begin
    Back := PPGBlendColor(T.Background, T.TextPrimary, 0.04);
    TextCol := T.TextPrimary;
    Sec := T.TextSecondary;
    Accent := T.Accent;
    if not UseVclStyle then
    begin
      Back := FKanbanStyles.Column.FillFor(UseDarkMode, Back);
      TextCol := FKanbanStyles.Column.TextFor(UseDarkMode, TextCol);
    end;
  end;
  R := ColClientRect(C);
  if (R.Right < View.Left) or (R.Left > View.Right) then
    Exit;
  Col := FCols[C].Column.Color;
  if (Col = clNone) or HC then
    Col := Accent
  else
    Col := PPGColorToRGB(Col);
  W := WipState(C);
  Cnt := ColumnCardCount(C);
  ACanvas.FillRoundRect(R, Sc(8), Back, 255);
  if W = kwsOver then
    ACanvas.FillRoundRect(R, Sc(8), T.Danger, 22);
  // Kopf: Farbleiste, Titel, Anzahl, Einklappen
  ACanvas.FillRoundRect(Rect(R.Left + Sc(8), R.Top + Sc(4), R.Right - Sc(8), R.Top + Sc(7)), Sc(1), Col, 255);
  if FCols[C].Collapsed then
  begin
    // eingeklappt: Anzahl oben, Titel senkrecht
    S := IntToStr(Cnt);
    ACanvas.DrawText(Rect(R.Left, R.Top + Sc(10), R.Right, R.Top + Sc(10) + TextH(FSmall) + Sc(4)), S, FSmall,
      IfThen(W = kwsOver, T.Danger, Sec), DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
    DC := ACanvas.BeginGdi;
    try
      GetObject(FBold.Handle, SizeOf(LF), @LF);
      LF.lfEscapement := 2700;
      LF.lfOrientation := 2700;
      Fnt := CreateFontIndirect(LF);
      if Fnt <> 0 then
      try
        OldF := SelectObject(DC, Fnt);
        try
          SetBkMode(DC, TRANSPARENT);
          SetTextColor(DC, ColorToRGB(TextCol));
          // senkrecht von oben nach unten: Ursprung rechts oben
          TextOut(DC, (R.Left + R.Right) div 2 + TextH(FBold) div 2, R.Top + Sc(14) + TextH(FSmall) + Sc(8),
            PChar(FCols[C].Column.Title), Length(FCols[C].Column.Title));
        finally
          SelectObject(DC, OldF);
        end;
      finally
        DeleteObject(Fnt);
      end;
    finally
      ACanvas.EndGdi(DC);
    end;
    if (FHot.Part = kpCollapse) and (FHot.Col = C) then
      ACanvas.FrameRoundRect(R, Sc(8), 1, PPGBlendColor(Back, TextCol, 0.3), 255);
    Exit;
  end;
  if UseRightToLeftAlignment then
    HR := Rect(R.Left + Sc(36), R.Top + Sc(8), R.Right - Sc(12), R.Top + FHeaderH)
  else
    HR := Rect(R.Left + Sc(12), R.Top + Sc(8), R.Right - Sc(36), R.Top + FHeaderH);
  Temp := nil;
  try
    if FKanbanStyles.Column.HasOwnFont then
      TitleF := PPGStyledFont(FKanbanStyles.Column.Font, [fsBold] + FKanbanStyles.Column.FontStyle, Temp)
    else
      TitleF := PPGStyledFont(FBold, FKanbanStyles.Column.FontStyle, Temp);
    ACanvas.DrawText(HR, FCols[C].Column.Title, TitleF, TextCol,
      DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS));
  finally
    Temp.Free;
  end;
  if FShowCardCount then
  begin
    if FCols[C].Column.WipLimit > 0 then
      S := IntToStr(Cnt) + ' / ' + IntToStr(FCols[C].Column.WipLimit)
    else
      S := IntToStr(Cnt);
    case W of
      kwsOver: Sh := T.Danger;
      kwsFull: Sh := T.Warning;
    else
      Sh := Sec;
    end;
    if HC then
      Sh := TextCol;
    // Anzahl hinter dem Titel (bei RTL links davon)
    Sw := Min(PPGMeasureTextNoCanvas(FCols[C].Column.Title, FBold, 0, False).cx, HR.Right - HR.Left - Sc(30)) + Sc(8);
    if UseRightToLeftAlignment then
      HR.Right := HR.Right - Sw
    else
      HR.Left := HR.Left + Sw;
    ACanvas.DrawText(HR, S, FSmall, Sh, DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX));
  end;
  // Einklapp-Knopf
  if UseRightToLeftAlignment then
    CR := Rect(R.Left + Sc(4), R.Top + Sc(10), R.Left + Sc(28), R.Top + FHeaderH - Sc(2))
  else
    CR := Rect(R.Right - Sc(28), R.Top + Sc(10), R.Right - Sc(4), R.Top + FHeaderH - Sc(2));
  Hot := (FHot.Part = kpCollapse) and (FHot.Col = C);
  if Hot then
    ACanvas.FillRoundRect(CR, Sc(4), TextCol, 18);
  if not PPGDrawIcon(ACanvas, CR, igChevronLeft, Sec, Sc(10)) then
    ACanvas.DrawText(CR, '<', FSmall, Sec, DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
  // Karten (Clip: Koerper der Spalte)
  B := BodyRect(C);
  if HasLanes then
    B := Rect(R.Left, View.Top + FHeaderH, R.Right, Min(View.Bottom, R.Bottom));
  Clip := B;
  if Clip.Top >= Clip.Bottom then
    Exit;
  ACanvas.PushClipRoundRect(Clip, 0);
  try
    for L := 0 to High(FCols[C].Cells) do
    begin
      if HasLanes and FLaneL[L].Lane.Collapsed then
        Continue;
      N := FCols[C].Cells[L].Count;
      // Platzhalter am Ziel
      if FDragging and (FDrop.Col = C) and (FDrop.Lane = L) then
      begin
        Ph := DropPlaceholderRect;
        if not IsRectEmpty(Ph) then
          ACanvas.FrameRoundRect(Ph, Sc(6), Sc(2), PPGBlendColor(Back, Accent, 0.7), 200);
      end;
      if N = 0 then
        Continue;
      // erste sichtbare Karte suchen (nur sichtbare zeichnen)
      if FCols[C].Cells[L].Virtual then
        First := Max(0, (Clip.Top - (CardOffsetY(C, L) + FCols[C].Cells[L].Top)) div
          (VirtualHeight + Sc(FCardGap)) - 1)
      else
        First := Max(0, PPGKanbanFirstBelow(FCols[C].Cells[L].Tops, FCols[C].Cells[L].Heights,
          Clip.Top - CardOffsetY(C, L) - FCols[C].Cells[L].Top - VirtualHeight * 2) - 1);
      for I := First to N - 1 do
      begin
        if FDragging and (FDragSrc.Col = C) and (FDragSrc.Lane = L) and (FDragSrc.Index = I) then
          Continue;
        CR := RawCardRect(C, L, I);
        OffsetRect(CR, 0, CurrentShift(C, L, I));
        if CR.Top > Clip.Bottom + VirtualHeight * 2 then
          Break;
        if CR.Bottom < Clip.Top then
          Continue;
        D := CardData(C, L, I);
        CardSel := (FFocus.Part = kpCard) and (FFocus.Col = C) and (FFocus.Lane = L) and
          (FFocus.Index = I) and (Focused or not FDragging);
        CardHot := (FHot.Part = kpCard) and (FHot.Col = C) and (FHot.Lane = L) and
          (FHot.Index = I) and not FDragging;
        // Eigenes Zeichnen der Karte
        DS.Reset;
        DrawIt := True;
        if Assigned(FOnCustomDrawCard) then
        begin
          St := [];
          if CardSel then
            Include(St, idsSelected);
          if CardHot then
            Include(St, idsHot);
          if CardSel and Focused then
            Include(St, idsFocused);
          DC := ACanvas.BeginGdi;
          try
            FDrawCanvas.Handle := DC;
            try
              FDrawCanvas.Font := Font;
              FDrawCanvas.Brush.Style := bsClear;
              FOnCustomDrawCard(Self, FDrawCanvas, D, CR, St, DS, DrawIt);
            finally
              FDrawCanvas.Handle := 0;
            end;
          finally
            ACanvas.EndGdi(DC);
          end;
        end;
        if DrawIt then
          PaintCard(ACanvas, CR, D, DS, CardSel, CardHot, False);
      end;
    end;
  finally
    ACanvas.PopClip;
  end;
  // Scroll-Daumen der Spalte
  CR := ThumbRectOf(C);
  if not IsRectEmpty(CR) then
    ACanvas.FillRoundRect(CR, Sc(2), Sec, IfThen((FHot.Part = kpThumb) and (FHot.Col = C), 200, 110));
end;

procedure TPPGCustomKanban.PaintViewport(const ACanvas: IPPGCanvas; const View: TRect);
var
  DS: TPPGDrawStyle;
  C, L: Integer;
  R, CR: TRect;
  T: TPPGTokens;
  TextCol, Sec: TColor;
  HC: Boolean;
  S: string;
  Cnt: Integer;
begin
  EnsureLayout;
  T := Tokens;
  HC := HighContrastSupport and PPGIsHighContrast;
  if HC then
  begin
    TextCol := PPGColorToRGB(clWindowText);
    Sec := TextCol;
  end
  else
  begin
    TextCol := T.TextPrimary;
    Sec := T.TextSecondary;
  end;
  ACanvas.FillRoundRect(View, 0, PPGColorToRGB(GetBackgroundColor), 255);
  for C := 0 to High(FCols) do
    PaintColumn(ACanvas, C, View);
  // Swimlane-Koepfe als Band ueber den Spalten (unter den stehenden Spaltenkoepfen)
  if HasLanes then
  begin
    ACanvas.PushClipRoundRect(Rect(View.Left, View.Top + FHeaderH, View.Right, View.Bottom), 0);
    try
    for L := 0 to High(FLaneL) do
    begin
      R := LaneHeaderRect(L);
      if (R.Bottom < View.Top + FHeaderH) or (R.Top > View.Bottom) then
        Continue;
      ACanvas.FillRoundRect(Rect(R.Left - BoardPad, R.Top + Sc(2), R.Right + BoardPad, R.Bottom - Sc(2)), 0,
        PPGColorToRGB(GetBackgroundColor), 255);
      Cnt := 0;
      for C := 0 to High(FCols) do
        Inc(Cnt, FCols[C].Cells[L].Count);
      ACanvas.FillRoundRect(Rect(R.Left, R.Bottom - 1, R.Right, R.Bottom), 0, PPGBlendColor(
        PPGColorToRGB(GetBackgroundColor), TextCol, 0.18), 255);
      if UseRightToLeftAlignment then
        CR := Rect(R.Right - Sc(20), R.Top, R.Right, R.Bottom)
      else
        CR := Rect(R.Left, R.Top, R.Left + Sc(20), R.Bottom);
      if FLaneL[L].Lane.Collapsed then
      begin
        if not PPGDrawIcon(ACanvas, CR, igChevronRight, Sec, Sc(10)) then
          ACanvas.DrawText(CR, '>', FSmall, Sec, DT_SINGLELINE or DT_CENTER or DT_VCENTER);
      end
      else if not PPGDrawIcon(ACanvas, CR, igChevronDown, Sec, Sc(10)) then
        ACanvas.DrawText(CR, 'v', FSmall, Sec, DT_SINGLELINE or DT_CENTER or DT_VCENTER);
      S := FLaneL[L].Lane.Title + '  (' + IntToStr(Cnt) + ')';
      if UseRightToLeftAlignment then
        CR := Rect(R.Left, R.Top, R.Right - Sc(24), R.Bottom)
      else
        CR := Rect(R.Left + Sc(24), R.Top, R.Right, R.Bottom);
      ACanvas.DrawText(CR, S, FBold, TextCol, DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX));
    end;
    finally
      ACanvas.PopClip;
    end;
  end;
  // gezogene Karte folgt der Maus
  if FDragging then
  begin
    R := Rect(FMousePt.X - FGrab.X, FMousePt.Y - FGrab.Y, FMousePt.X - FGrab.X + DragWidth,
      FMousePt.Y - FGrab.Y + FDragH);
    DS.Reset;
    PaintCard(ACanvas, R, FDragData, DS, True, False, True);
  end;
  if Focused and (FFocus.Part = kpHeader) then
    ACanvas.FrameRoundRect(HeaderRect(FFocus.Col), Sc(8), Sc(2), PPGColorToRGB(EffectiveAppearance.FocusColor), 255);
end;

{ ---- Ziehen ---- }

function TPPGCustomKanban.ShiftFor(const Drop: TPPGKanbanHit; C, L, I: Integer): Integer;
var
  Step, V: Integer;
begin
  Result := 0;
  if not FDragging then
    Exit;
  Step := FDragH + Sc(FCardGap);
  V := I;
  if (C = FDragSrc.Col) and (L = FDragSrc.Lane) and (I > FDragSrc.Index) then
  begin
    Dec(Result, Step);   // Luecke der gezogenen Karte schliesst sich
    Dec(V);
  end;
  if (Drop.Part <> kpNone) and (C = Drop.Col) and (L = Drop.Lane) and (V >= Drop.Index) then
    Inc(Result, Step);   // Platz am Ziel
end;

function TPPGCustomKanban.CurrentShift(C, L, I: Integer): Integer;
var
  P: Single;
begin
  if not FDragging then
    Exit(0);
  P := FShiftAnim.Value;
  Result := Round(ShiftFor(FPrevDrop, C, L, I) * (1 - P) + ShiftFor(FDrop, C, L, I) * P);
end;

procedure TPPGCustomKanban.ShiftStep(Sender: TObject);
begin
  Invalidate;
end;

function TPPGCustomKanban.DropAt(X, Y: Integer): TPPGKanbanHit;
var
  H: TPPGKanbanHit;
  C, L, I, N, Skip, YC: Integer;
  Tops, Hts: TArray<Integer>;
  CX: Integer;
begin
  Result := NoHit;
  EnsureLayout;
  // Spalte unter der Maus (auch ueber Kopf und Luecken: naechste Spalte)
  CX := ToContentX(X);
  C := -1;
  for I := 0 to High(FCols) do
    if (CX >= FCols[I].X - ColGap div 2) and (CX < FCols[I].X + FCols[I].W + ColGap div 2) then
      C := I;
  if C < 0 then
    if (Length(FCols) > 0) and (CX < FCols[0].X) then
      C := 0
    else if Length(FCols) > 0 then
      C := High(FCols);
  if C < 0 then
    Exit;
  L := 0;
  if HasLanes then
  begin
    L := -1;
    for I := 0 to High(FLaneL) do
      if (Y >= ViewRect.Top + FLaneL[I].Top - ScrollY) then
        L := I;
    if L < 0 then
      L := 0;
    // eingeklappte Swimlane: an ihr Ende
  end;
  N := FCols[C].Cells[L].Count;
  // eingeklappte Spalte oder Swimlane: ans Ende
  if FCols[C].Collapsed or (HasLanes and FLaneL[L].Lane.Collapsed) then
    Exit(KHit(kpCell, C, L, N - Ord((C = FDragSrc.Col) and (L = FDragSrc.Lane))));
  Skip := -1;
  if (C = FDragSrc.Col) and (L = FDragSrc.Lane) then
    Skip := FDragSrc.Index;
  YC := Y - CardOffsetY(C, L) - FCols[C].Cells[L].Top;
  if FCols[C].Cells[L].Virtual then
  begin
    I := (YC + (VirtualHeight + Sc(FCardGap)) div 2) div (VirtualHeight + Sc(FCardGap));
    I := Max(0, Min(I, N));
    if (Skip >= 0) and (I > Skip) then
      Dec(I);
    Exit(KHit(kpCell, C, L, Min(I, N - Ord(Skip >= 0))));
  end;
  Tops := FCols[C].Cells[L].Tops;
  Hts := FCols[C].Cells[L].Heights;
  I := PPGKanbanDropIndex(Tops, Hts, YC, Skip);
  H := KHit(kpCell, C, L, I);
  Result := H;
end;

function TPPGCustomKanban.DragWidth: Integer;
begin
  if (FDragSrc.Col >= 0) and (FDragSrc.Col <= High(FCols)) then
    Result := CardInnerWidth(FDragSrc.Col)
  else
    Result := Sc(FColumnWidth) - 2 * Sc(8);
end;

function TPPGCustomKanban.DropPlaceholderRect: TRect;
var
  C, L, I, Y, N, Visual: Integer;
  R: TRect;
begin
  Result := Rect(0, 0, 0, 0);
  if not FDragging or (FDrop.Part = kpNone) then
    Exit;
  C := FDrop.Col;
  L := FDrop.Lane;
  if FCols[C].Collapsed or (HasLanes and FLaneL[L].Lane.Collapsed) then
    Exit;
  N := FCols[C].Cells[L].Count;
  // Oberkante der Karte, die am Ziel unter dem Platzhalter liegt (ohne Verschiebung)
  Visual := FDrop.Index;
  I := Visual;
  if (C = FDragSrc.Col) and (L = FDragSrc.Lane) and (I >= FDragSrc.Index) then
    Inc(I);
  if I < N then
  begin
    R := RawCardRect(C, L, I);
    if (C = FDragSrc.Col) and (L = FDragSrc.Lane) and (I > FDragSrc.Index) then
      OffsetRect(R, 0, -(FDragH + Sc(FCardGap)));
    Y := R.Top;
  end
  else if N > 0 then
  begin
    I := N - 1;
    if (C = FDragSrc.Col) and (L = FDragSrc.Lane) and (I = FDragSrc.Index) then
      Dec(I);
    if I >= 0 then
    begin
      R := RawCardRect(C, L, I);
      if (C = FDragSrc.Col) and (L = FDragSrc.Lane) and (I > FDragSrc.Index) then
        OffsetRect(R, 0, -(FDragH + Sc(FCardGap)));
      Y := R.Bottom + Sc(FCardGap);
    end
    else
      Y := CardOffsetY(C, L) + FCols[C].Cells[L].Top;
  end
  else
    Y := CardOffsetY(C, L) + FCols[C].Cells[L].Top;
  R := RawCardRectX(C);
  Result := Rect(R.Left, Y, R.Right, Y + FDragH);
end;

function TPPGCustomKanban.RawCardRectX(C: Integer): TRect;
var
  X: Integer;
begin
  X := ToClientX(FCols[C].X, FCols[C].W) + Sc(8);
  Result := Rect(X, 0, X + CardInnerWidth(C), 0);
end;

procedure TPPGCustomKanban.UpdateDrop(X, Y: Integer);
var
  D: TPPGKanbanHit;
begin
  D := DropAt(X, Y);
  if not SameKHit(D, FDrop) then
  begin
    FPrevDrop := FDrop;
    // Animation von der aktuell gezeigten Lage aus (verkuerzt: ab dem vorigen Ziel)
    FDrop := D;
    FShiftAnim.Jump(0);
    if Animation.EffectiveEnabled and Visible then
      FShiftAnim.AnimateTo(1, 150, ekDecelerate)
    else
      FShiftAnim.Jump(1);
  end;
  Invalidate;
end;

procedure TPPGCustomKanban.ColumnAutoScroll(X, Y: Integer);
var
  C: Integer;
  B: TRect;
  Edge: Integer;
begin
  // Ohne Swimlanes scrollt die Spalte unter der Maus am oberen/unteren Rand
  FColAutoSpeed := 0;
  FColAutoCol := -1;
  if HasLanes or not FDragging then
  begin
    FColAuto.Stop;
    Exit;
  end;
  C := DropAt(X, Y).Col;
  if (C < 0) or FCols[C].Collapsed then
  begin
    FColAuto.Stop;
    Exit;
  end;
  B := BodyRect(C);
  Edge := Sc(32);
  if Y < B.Top + Edge then
    FColAutoSpeed := -Max(1, (B.Top + Edge - Y) div 3)
  else if Y > B.Bottom - Edge then
    FColAutoSpeed := Max(1, (Y - (B.Bottom - Edge)) div 3);
  if FColAutoSpeed = 0 then
  begin
    FColAuto.Stop;
    Exit;
  end;
  FColAutoCol := C;
  if not FColAuto.Looping then
    FColAuto.StartLoop(1000);
end;

procedure TPPGCustomKanban.ColAutoStep(Sender: TObject);
begin
  if not FDragging or (FColAutoCol < 0) or (FColAutoSpeed = 0) then
  begin
    FColAuto.Stop;
    Exit;
  end;
  SetColScroll(FColAutoCol, GetColScroll(FColAutoCol) + FColAutoSpeed);
  UpdateDrop(FMousePt.X, FMousePt.Y);
end;

procedure TPPGCustomKanban.DoAutoScroll(const P: TPoint);
begin
  inherited DoAutoScroll(P);
  if FDragging then
    UpdateDrop(P.X, P.Y);
end;

procedure TPPGCustomKanban.EndDrag(Commit: Boolean);
var
  Src, Dst: TPPGKanbanHit;
begin
  if not FDragging then
    Exit;
  Src := FDragSrc;
  Dst := FDrop;
  FDragging := False;
  FColAuto.Stop;
  StopAutoScroll;
  FShiftAnim.Jump(0);
  FDrop := NoHit;
  FPrevDrop := NoHit;
  Invalidate;
  if Commit and (Dst.Part <> kpNone) then
    MoveCard(Src.Col, Src.Lane, Src.Index, Dst.Col, Dst.Lane, Dst.Index, False);
end;

function TPPGCustomKanban.MoveCard(C, L, I, ToC, ToL, ToIndex: Integer; ByKeyboard: Boolean): Boolean;
var
  M: TPPGKanbanMove;
  Allow: Boolean;
  N, Total: Integer;
  Same: Boolean;
begin
  Result := False;
  EnsureLayout;
  if FReadOnly or (I < 0) or (I >= CellCount(C, L)) or (ToC < 0) or (ToC > High(FCols)) or
    (ToL < 0) or (ToL > High(FCols[ToC].Cells)) then
    Exit;
  Same := (C = ToC) and (L = ToL);
  N := CellCount(ToC, ToL);
  if Same then
    ToIndex := Max(0, Min(ToIndex, N - 1))
  else
    ToIndex := Max(0, Min(ToIndex, N));
  if Same and (ToIndex = I) then
    Exit;
  // virtuelle Spalten nehmen keine fremden Karten (und geben keine ab)
  if (FCols[C].Cells[L].Virtual <> FCols[ToC].Cells[ToL].Virtual) then
    Exit;
  M.Card := CardAt(C, L, I);
  M.FromColumn := FCols[C].Column;
  M.ToColumn := FCols[ToC].Column;
  M.FromLane := FLaneL[L].Lane;
  M.ToLane := FLaneL[ToL].Lane;
  M.FromIndex := I;
  M.ToIndex := ToIndex;
  M.ByKeyboard := ByKeyboard;
  Allow := True;
  // WIP-Limit: im Sperrmodus keine Karte in eine volle Spalte
  if (C <> ToC) and (FWipMode = kwmBlock) and (FCols[ToC].Column.WipLimit > 0) then
  begin
    Total := ColumnCardCount(ToC);
    if Total >= FCols[ToC].Column.WipLimit then
      Allow := False;
  end;
  if Assigned(FOnCardMoving) then
    FOnCardMoving(Self, M, Allow);
  if not Allow then
  begin
    FAnnounce := Format(PPGStr(@SPPGKanbanMoveRejected), [M.ToColumn.Title]);
    NotifyAccessibilityChild(EVENT_OBJECT_NAMECHANGE, AccIdOf(KHit(kpCard, C, L, I)));
    Exit;
  end;
  if not DoMoveCard(M) then
    Exit;
  Result := True;
  EnsureLayout;
  // Fokus folgt der Karte
  FFocus := KHit(kpCard, ToC, ToL, ToIndex);
  FAnnounce := Format(PPGStr(@SPPGKanbanMoved), [M.ToColumn.Title, ToIndex + 1, CellCount(ToC, ToL)]);
  MakeCardVisible(ToC, ToL, ToIndex);
  Invalidate;
  CardMoved(M);
  if Assigned(FOnCardMoved) then
    FOnCardMoved(Self, M);
  NotifyAccessibility(EVENT_OBJECT_REORDER);
  NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, AccIdOf(FFocus));
  NotifyAccessibilityChild(EVENT_OBJECT_NAMECHANGE, AccIdOf(FFocus));
end;

function TPPGCustomKanban.DoMoveCard(const Move: TPPGKanbanMove): Boolean;
var
  C, L, ToC, ToL, I, NewIdx: Integer;
  Card, Neighbor: TPPGKanbanCard;
  Same: Boolean;
begin
  Result := True;
  Card := Move.Card;
  if Card = nil then
    Exit; // virtuell: die Anwendung verschiebt ihre Daten in OnCardMoved
  if not FindCard(Card, C, L, I) then
    Exit(False);
  ToC := ColumnIndexOf(Move.ToColumn);
  ToL := 0;
  if Move.ToLane <> nil then
    for I := 0 to High(FLaneL) do
      if FLaneL[I].Lane = Move.ToLane then
        ToL := I;
  Same := (C = ToC) and (L = ToL);
  // Nachbar am Ziel: die Karte, vor der eingefuegt wird (ohne die verschobene)
  Neighbor := nil;
  NewIdx := Move.ToIndex;
  if Same then
  begin
    if NewIdx >= Move.FromIndex then
      Inc(NewIdx);
    if NewIdx < FCols[ToC].Cells[ToL].Count then
      Neighbor := FCols[ToC].Cells[ToL].Cards[NewIdx];
  end
  else if NewIdx < FCols[ToC].Cells[ToL].Count then
    Neighbor := FCols[ToC].Cells[ToL].Cards[NewIdx];
  FCards.BeginUpdate;
  try
    Card.ColumnId := Move.ToColumn.Id;
    if Move.ToLane <> nil then
      Card.LaneId := Move.ToLane.Id;
    if Neighbor <> nil then
    begin
      if Card.Index < Neighbor.Index then
        Card.Index := Neighbor.Index - 1
      else
        Card.Index := Neighbor.Index;
    end
    else if FCols[ToC].Cells[ToL].Count > 0 then
    begin
      // ans Ende der Zelle: hinter die letzte Karte der Zelle
      Neighbor := FCols[ToC].Cells[ToL].Cards[FCols[ToC].Cells[ToL].Count - 1];
      if Neighbor <> Card then
        if Card.Index < Neighbor.Index then
          Card.Index := Neighbor.Index
        else
          Card.Index := Neighbor.Index + 1;
    end;
  finally
    FCards.EndUpdate;
  end;
  LayoutChanged;
end;

procedure TPPGCustomKanban.CardMoved(const Move: TPPGKanbanMove);
begin
end;

procedure TPPGCustomKanban.SelectionChanged;
begin
  if Assigned(FOnSelectionChange) then
    FOnSelectionChange(Self);
end;

procedure TPPGCustomKanban.ToggleColumn(C: Integer);
begin
  EnsureLayout;
  if (C < 0) or (C > High(FCols)) then
    Exit;
  FCols[C].Column.Collapsed := not FCols[C].Column.Collapsed;
  if Assigned(FOnColumnCollapse) then
    FOnColumnCollapse(Self, FCols[C].Column);
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

procedure TPPGCustomKanban.ToggleLane(L: Integer);
begin
  EnsureLayout;
  if not HasLanes or (L < 0) or (L > High(FLaneL)) then
    Exit;
  FLaneL[L].Lane.Collapsed := not FLaneL[L].Lane.Collapsed;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

{ ---- Maus ---- }

procedure TPPGCustomKanban.ContentMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  H: TPPGKanbanHit;
begin
  inherited ContentMouseDown(Button, Shift, X, Y);
  if not Enabled then
    Exit;
  if CanFocus and IsWindowVisible(Handle) and not Focused then
    SetFocus;
  H := HitTest(X, Y);
  FPress := H;
  FPressPt := Point(X, Y);
  if Button <> mbLeft then
    Exit;
  case H.Part of
    kpCard:
      Select(H.Col, H.Lane, H.Index);
    kpThumb:
      begin
        FThumbCol := H.Col;
        FThumbOffset := Y - ThumbRectOf(H.Col).Top;
      end;
    kpHeader:
      FocusHit(H, True);
  end;
end;

procedure TPPGCustomKanban.ContentMouseMove(Shift: TShiftState; X, Y: Integer);
var
  H: TPPGKanbanHit;
  R, B: TRect;
  Mx, View: Integer;
begin
  inherited ContentMouseMove(Shift, X, Y);
  FMousePt := Point(X, Y);
  if FThumbCol >= 0 then
  begin
    B := BodyRect(FThumbCol);
    R := ThumbRectOf(FThumbCol);
    Mx := ColMaxScroll(FThumbCol);
    View := (B.Bottom - B.Top) - (R.Bottom - R.Top);
    if View > 0 then
      SetColScroll(FThumbCol, (Y - FThumbOffset - B.Top) * Mx div View);
    Exit;
  end;
  if FDragging then
  begin
    UpdateDrop(X, Y);
    AutoScrollAt(X, Y);
    ColumnAutoScroll(X, Y);
    Exit;
  end;
  // Ziehen beginnt nach ein paar Pixeln
  if (ssLeft in Shift) and (FPress.Part = kpCard) and FAllowDrag and not FReadOnly and
    ((Abs(X - FPressPt.X) > Sc(4)) or (Abs(Y - FPressPt.Y) > Sc(4))) then
  begin
    R := RawCardRect(FPress.Col, FPress.Lane, FPress.Index);
    FDragSrc := FPress;
    FDragH := R.Bottom - R.Top;
    FDragData := CardData(FPress.Col, FPress.Lane, FPress.Index);
    FGrab := Point(FPressPt.X - R.Left, FPressPt.Y - R.Top);
    FDragging := True;
    // Start: Ziel = alte Lage, damit nichts springt
    FDrop := KHit(kpCell, FPress.Col, FPress.Lane, FPress.Index);
    FPrevDrop := FDrop;
    FShiftAnim.Jump(1);
    UpdateDrop(X, Y);
    Exit;
  end;
  H := HitTest(X, Y);
  if not SameKHit(H, FHot) then
  begin
    FHot := H;
    Invalidate;
  end;
end;

procedure TPPGCustomKanban.ContentMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  H, P: TPPGKanbanHit;
begin
  inherited ContentMouseUp(Button, Shift, X, Y);
  P := FPress;
  FPress := NoHit;
  if FThumbCol >= 0 then
  begin
    FThumbCol := -1;
    Exit;
  end;
  if FDragging then
  begin
    UpdateDrop(X, Y);
    EndDrag(True);
    Exit;
  end;
  if Button <> mbLeft then
    Exit;
  H := HitTest(X, Y);
  if not SameKHit(H, P) then
    Exit;
  case H.Part of
    kpCard:
      if Assigned(FOnCardClick) then
        FOnCardClick(Self, FCols[H.Col].Column, H.Index, CardAt(H.Col, H.Lane, H.Index));
    kpCollapse:
      ToggleColumn(H.Col);
    kpLane:
      ToggleLane(H.Lane);
  end;
end;

procedure TPPGCustomKanban.DblClick;
var
  P: TPoint;
  H: TPPGKanbanHit;
begin
  inherited DblClick;
  if not HandleAllocated then
    Exit;
  P := ScreenToClient(Mouse.CursorPos);
  H := HitTest(P.X, P.Y);
  if (H.Part = kpCard) and Assigned(FOnCardOpen) then
    FOnCardOpen(Self, FCols[H.Col].Column, H.Index, CardAt(H.Col, H.Lane, H.Index));
end;

procedure TPPGCustomKanban.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHot.Part <> kpNone then
  begin
    FHot := NoHit;
    Invalidate;
  end;
end;

function TPPGCustomKanban.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
var
  P: TPoint;
  H: TPPGKanbanHit;
  C: Integer;
begin
  // Ohne Swimlanes: das Rad scrollt die Spalte unter der Maus
  if not HasLanes and not (ssShift in Shift) and HandleAllocated then
  begin
    P := ScreenToClient(MousePos);
    H := HitTest(P.X, P.Y);
    C := H.Col;
    if (C >= 0) and (ColMaxScroll(C) > 0) then
    begin
      ScrollColumn(C, -WheelDelta * 3 * Sc(20) div WHEEL_DELTA);
      Exit(True);
    end;
  end;
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
end;

{ ---- Tastatur ---- }

procedure TPPGCustomKanban.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TPPGCustomKanban.Select(C, L, I: Integer);
begin
  EnsureLayout;
  if (I < 0) or (I >= CellCount(C, L)) then
    Exit;
  FocusHit(KHit(kpCard, C, L, I), True);
end;

procedure TPPGCustomKanban.FocusHit(const H: TPPGKanbanHit; Notify: Boolean);
var
  Changed: Boolean;
begin
  Changed := not SameKHit(H, FFocus);
  FFocus := H;
  FAnnounce := '';
  if H.Part = kpCard then
    MakeCardVisible(H.Col, H.Lane, H.Index);
  Invalidate;
  if Changed then
  begin
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, AccIdOf(H));
    if H.Part = kpCard then
      NotifyAccessibilityChild(EVENT_OBJECT_SELECTION, AccIdOf(H));
    if Notify then
      SelectionChanged;
  end;
end;

function TPPGCustomKanban.NextColumn(C, Dir: Integer; NeedCards: Boolean): Integer;
var
  I: Integer;
begin
  I := C + Dir;
  while (I >= 0) and (I <= High(FCols)) do
  begin
    if not FCols[I].Collapsed and (not NeedCards or (ColumnCardCount(I) > 0)) then
      Exit(I);
    Inc(I, Dir);
  end;
  Result := -1;
end;

procedure TPPGCustomKanban.KeyDown(var Key: Word; Shift: TShiftState);
var
  K: Word;
  F: TPPGKanbanHit;
  C, L, I, N, Dir: Integer;
  Ctrl: Boolean;
begin
  inherited KeyDown(Key, Shift);
  if not Enabled or (Key = 0) then
    Exit;
  EnsureLayout;
  if FDragging then
  begin
    if Key = VK_ESCAPE then
    begin
      EndDrag(False);
      Key := 0;
    end;
    Exit;
  end;
  K := Key;
  if UseRightToLeftAlignment then
    if K = VK_LEFT then
      K := VK_RIGHT
    else if K = VK_RIGHT then
      K := VK_LEFT;
  Ctrl := ssCtrl in Shift;
  F := FFocus;
  if (F.Part <> kpCard) and (K in [VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT, VK_HOME, VK_END]) then
  begin
    // erste Karte der ersten Spalte mit Karten
    C := NextColumn(-1, 1, True);
    if C >= 0 then
      for L := 0 to High(FLaneL) do
        if CellCount(C, L) > 0 then
        begin
          Select(C, L, 0);
          Break;
        end;
    Key := 0;
    Exit;
  end;
  C := F.Col;
  L := F.Lane;
  I := F.Index;
  case K of
    VK_UP, VK_DOWN:
      begin
        if K = VK_UP then
          Dir := -1
        else
          Dir := 1;
        if Ctrl then
        begin
          // innerhalb der Zelle verschieben; am Rand in die naechste Swimlane
          if (I + Dir >= 0) and (I + Dir < CellCount(C, L)) then
            MoveCard(C, L, I, C, L, I + Dir, True)
          else if HasLanes and (L + Dir >= 0) and (L + Dir <= High(FLaneL)) then
          begin
            if Dir < 0 then
              MoveCard(C, L, I, C, L - 1, CellCount(C, L - 1), True)
            else
              MoveCard(C, L, I, C, L + 1, 0, True);
          end;
        end
        else if (I + Dir >= 0) and (I + Dir < CellCount(C, L)) then
          Select(C, L, I + Dir)
        else if HasLanes then
        begin
          // naechste Swimlane mit Karten in dieser Spalte
          N := L + Dir;
          while (N >= 0) and (N <= High(FLaneL)) and (CellCount(C, N) = 0) do
            Inc(N, Dir);
          if (N >= 0) and (N <= High(FLaneL)) then
            if Dir > 0 then
              Select(C, N, 0)
            else
              Select(C, N, CellCount(C, N) - 1);
        end;
      end;
    VK_LEFT, VK_RIGHT:
      begin
        if K = VK_LEFT then
          Dir := -1
        else
          Dir := 1;
        if Ctrl then
        begin
          N := NextColumn(C, Dir, False);
          if N >= 0 then
            MoveCard(C, L, I, N, L, Min(I, CellCount(N, L)), True);
        end
        else
        begin
          N := NextColumn(C, Dir, True);
          if N >= 0 then
          begin
            if CellCount(N, L) > 0 then
              Select(N, L, Min(I, CellCount(N, L) - 1))
            else
              for I := 0 to High(FLaneL) do
                if CellCount(N, I) > 0 then
                begin
                  Select(N, I, 0);
                  Break;
                end;
          end;
        end;
      end;
    VK_HOME:
      Select(C, L, 0);
    VK_END:
      Select(C, L, CellCount(C, L) - 1);
    VK_PRIOR:
      if HasLanes then
        ScrollBy(0, -ClientHeight)
      else
        ScrollColumn(C, -(BodyRect(C).Bottom - BodyRect(C).Top));
    VK_NEXT:
      if HasLanes then
        ScrollBy(0, ClientHeight)
      else
        ScrollColumn(C, BodyRect(C).Bottom - BodyRect(C).Top);
    VK_RETURN:
      if Assigned(FOnCardOpen) then
        FOnCardOpen(Self, FCols[C].Column, I, CardAt(C, L, I));
  else
    Exit;
  end;
  Key := 0;
end;

procedure TPPGCustomKanban.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TPPGCustomKanban.DoExit;
begin
  inherited DoExit;
  if FDragging then
    EndDrag(False);
  Invalidate;
end;

procedure TPPGCustomKanban.WndProc(var Message: TMessage);
var
  H: TPPGKanbanHit;
begin
  if (GMsgKanbanAction <> 0) and (Message.Msg = GMsgKanbanAction) then
  begin
    H := AccHitOf(Integer(Message.WParam));
    if H.Part = kpCard then
      Select(H.Col, H.Lane, H.Index)
    else if H.Part = kpHeader then
      ToggleColumn(H.Col);
    Exit;
  end;
  if (Message.Msg = WM_CANCELMODE) and FDragging then
    EndDrag(False);
  inherited WndProc(Message);
end;

{ ---- Barrierefreiheit: Kinder = je Spalte der Kopf, dann ihre Karten ---- }

function TPPGCustomKanban.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_PANE;
end;

function TPPGCustomKanban.AccIdOf(const H: TPPGKanbanHit): Integer;
var
  C, L: Integer;
begin
  Result := 0;
  if (H.Col < 0) or (H.Col > High(FCols)) then
    Exit;
  Result := 1;
  for C := 0 to H.Col - 1 do
    Inc(Result, 1 + ColumnCardCount(C));
  if H.Part <> kpCard then
    Exit;
  Inc(Result);
  for L := 0 to H.Lane - 1 do
    Inc(Result, CellCount(H.Col, L));
  Inc(Result, H.Index);
end;

function TPPGCustomKanban.AccHitOf(Id: Integer): TPPGKanbanHit;
var
  C, L, N: Integer;
begin
  EnsureLayout;
  Result := NoHit;
  N := Id - 1;
  for C := 0 to High(FCols) do
  begin
    if N = 0 then
      Exit(KHit(kpHeader, C, -1, -1));
    Dec(N);
    for L := 0 to High(FCols[C].Cells) do
    begin
      if N < FCols[C].Cells[L].Count then
        Exit(KHit(kpCard, C, L, N));
      Dec(N, FCols[C].Cells[L].Count);
    end;
  end;
end;

function TPPGCustomKanban.AccChildCount: Integer;
var
  C: Integer;
begin
  EnsureLayout;
  Result := 0;
  for C := 0 to High(FCols) do
    Inc(Result, 1 + ColumnCardCount(C));
end;

function TPPGCustomKanban.AccChildName(Id: Integer): string;
var
  H: TPPGKanbanHit;
  Col: TPPGKanbanColumn;
begin
  H := AccHitOf(Id);
  Result := '';
  if H.Part = kpHeader then
  begin
    Col := FCols[H.Col].Column;
    Result := Format(PPGStr(@SPPGKanbanAccColumn), [Col.Title, ColumnCardCount(H.Col)]);
    if Col.WipLimit > 0 then
      Result := Result + ', ' + Format(PPGStr(@SPPGKanbanAccLimit), [Col.WipLimit]);
    if FCols[H.Col].Collapsed then
      Result := Result + ', ' + PPGStr(@SPPGKanbanAccCollapsed);
  end
  else if H.Part = kpCard then
  begin
    Result := PPGKanbanCardSpeech(CardData(H.Col, H.Lane, H.Index), FCols[H.Col].Column.Title, H.Index + 1,
      CellCount(H.Col, H.Lane));
    if HasLanes then
      Result := Result + ', ' + FLaneL[H.Lane].Lane.Title;
    if (FAnnounce <> '') and SameKHit(H, FFocus) then
      Result := FAnnounce + '. ' + Result;
  end;
end;

function TPPGCustomKanban.AccChildRole(Id: Integer): Integer;
begin
  if AccHitOf(Id).Part = kpHeader then
    Result := ROLE_SYSTEM_COLUMNHEADER
  else
    Result := ROLE_SYSTEM_LISTITEM;
end;

function TPPGCustomKanban.AccChildState(Id: Integer): Integer;
var
  H: TPPGKanbanHit;
  R: TRect;
begin
  H := AccHitOf(Id);
  Result := STATE_SYSTEM_FOCUSABLE;
  if H.Part = kpCard then
  begin
    Result := Result or STATE_SYSTEM_SELECTABLE;
    if not FReadOnly and FAllowDrag then
      Result := Result or STATE_SYSTEM_MOVEABLE;
    if SameKHit(H, FFocus) then
    begin
      Result := Result or STATE_SYSTEM_SELECTED;
      if Focused then
        Result := Result or STATE_SYSTEM_FOCUSED;
    end;
    R := CardRect(H.Col, H.Lane, H.Index);
    if IsRectEmpty(R) or (R.Bottom < ViewRect.Top) or (R.Top > ViewRect.Bottom) then
      Result := Result or STATE_SYSTEM_OFFSCREEN;
  end
  else if (H.Part = kpHeader) and FCols[H.Col].Collapsed then
    Result := Result or STATE_SYSTEM_COLLAPSED
  else if H.Part = kpHeader then
    Result := Result or STATE_SYSTEM_EXPANDED;
  if not Enabled then
    Result := Result or STATE_SYSTEM_UNAVAILABLE;
end;

function TPPGCustomKanban.AccChildRect(Id: Integer): TRect;
var
  H: TPPGKanbanHit;
begin
  H := AccHitOf(Id);
  case H.Part of
    kpHeader: Result := HeaderRect(H.Col);
    kpCard: Result := CardRect(H.Col, H.Lane, H.Index);
  else
    Result := Rect(0, 0, 0, 0);
  end;
end;

function TPPGCustomKanban.AccChildAt(X, Y: Integer): Integer;
var
  H: TPPGKanbanHit;
begin
  H := HitTest(X, Y);
  case H.Part of
    kpCard: Result := AccIdOf(H);
    kpHeader, kpCollapse: Result := AccIdOf(KHit(kpHeader, H.Col, -1, -1));
  else
    Result := 0;
  end;
end;

function TPPGCustomKanban.AccChildDefaultAction(Id: Integer): string;
var
  H: TPPGKanbanHit;
begin
  H := AccHitOf(Id);
  if H.Part = kpHeader then
  begin
    if FCols[H.Col].Collapsed then
      Result := PPGStr(@SPPGAccExpand)
    else
      Result := PPGStr(@SPPGAccCollapse);
  end
  else
    Result := PPGStr(@SPPGAccSelect);
end;

procedure TPPGCustomKanban.AccChildDoDefault(Id: Integer);
begin
  if HandleAllocated then
    PostMessage(Handle, GMsgKanbanAction, WPARAM(Id), 0);
end;

function TPPGCustomKanban.AccFocusedChild: Integer;
begin
  if Focused and (FFocus.Part <> kpNone) then
    Result := AccIdOf(FFocus)
  else
    Result := 0;
end;

function TPPGCustomKanban.AccSelectedChild: Integer;
begin
  if FFocus.Part = kpCard then
    Result := AccIdOf(FFocus)
  else
    Result := 0;
end;

initialization
  RegisterClass(TPPGKanban);

end.
