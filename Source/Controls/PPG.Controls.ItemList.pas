unit PPG.Controls.ItemList;

{ TPPGCustomItemList - Basis von ListBox, CheckListBox und TreeView.

  Bausteine aus Phase 5, hier zusammengesetzt:
  - Daten ausschliesslich ueber IPPGItemSource (DIP): Strings, Collection,
    virtuell oder eine eigene Quelle des Nachfahren (Baum: sichtbare Knoten).
  - Zeilen ueber TPPGRowLayout (feste Hoehe O(1); variabel nur, wenn
    Gruppen-Ueberschriften, Detailzeilen oder OnMeasureItem es verlangen und
    die Quelle nicht virtuell ist), Auswahl ueber TPPGSelection.
  - Zeichnen ueber TPPGItemPainter + IPPGItemRenderer (Preset).
  - Scrollen, Overlay-Leisten, Mausrad, Auto-Scroll: TPPGCustomScrollControl.

  Ereignisse wie die VCL: Anwender-Aktionen (Maus, Tastatur, Tippsuche,
  Screenreader) rufen UserSelectionChanged (ListBox: OnClick); Aenderungen im
  Code loesen nichts aus. Paint sendet keine Nachrichten. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.ImgList,
  PPG.Types, PPG.Items, PPG.Selection, PPG.RowLayout, PPG.Render.Intf,
  PPG.Accessibility, PPG.UIA, PPG.Controls.Base, PPG.Controls.Scroll, PPG.ItemPainter,
  PPG.CustomDraw;

const
  /// UIA-Art der Eintraege (A = Index); 0 ist die Liste selbst.
  PPGUiaKindListItem = 1;

type
  TPPGReorderEvent = procedure(Sender: TObject; FromIndex, ToIndex: Integer;
    var Allow: Boolean) of object;

  TPPGCustomItemList = class(TPPGCustomScrollControl, IPPGAccessibleChildren,
    IPPGAccessibleMultiSelection, IPPGUiaSource)
  private
    FSource: IPPGItemSource;
    FSelection: TPPGSelection;
    FLayout: TPPGRowLayout;
    FPainter: TPPGItemPainter;
    FHeaders: TBits;          // Zeile beginnt mit Gruppen-Ueberschrift (variabel)
    FHeaderH: Integer;
    FLayoutValid: Boolean;
    FLayoutPPI: Integer;
    FLayoutFontH: Integer;
    FLayoutPosted: Boolean;
    FHotIndex: Integer;
    FItemHeight: Integer;
    FBorderStyle: TBorderStyle;
    FAllowMarkup: Boolean;
    FAllowReorder: Boolean;
    FTypeAhead: Boolean;
    FTypeBuf: TPPGTypeAhead;
    FToolTips: Boolean;
    FDownIndex: Integer;
    FDownPos: TPoint;
    FDragging: Boolean;
    FDropRow: Integer;        // Einfuegen vor dieser Zeile (0..Count), -1 = keine
    FMouseSelecting: Boolean;
    FSelChanges: Cardinal;
    FStructChanges: Cardinal; // Einfuegen/Loeschen/Neuaufbau der Eintraege
    FUserLevel: Integer;
    FUserStartChanges: Cardinal;
    FLastFocus: Integer;
    FInButtonUp: Boolean;
    FDropInside: Boolean;
    FOnReorder: TPPGReorderEvent;
    FListStyles: TPPGListStyles;
    FOnCustomDrawItem: TPPGCustomDrawItemEvent;
    FDrawCanvas: TCanvas;
    procedure ReleaseDownIndex;
    /// Hover-Zeile wechseln; neu gezeichnet werden nur alte und neue Zeile (8b).
    procedure SetHotIndex(Value: Integer);
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure SetListStyles(const Value: TPPGListStyles);
    procedure ListStylesChanged(Sender: TObject);
    procedure SetItemHeight(const Value: Integer);
    procedure SetBorderStyle(const Value: TBorderStyle);
    procedure SetAllowMarkup(const Value: Boolean);
    procedure SelectionChange(Sender: TObject);
    procedure SourceChange(Sender: TObject; Index: Integer);
    function GetItemIndex: Integer;
    procedure SetItemIndex(const Value: Integer);
    function GetTopIndex: Integer;
    procedure SetTopIndex(const Value: Integer);
    function GetSelected(Index: Integer): Boolean;
    procedure SetSelected(Index: Integer; const Value: Boolean);
    function GetSelCount: Integer;
    function GetSelection: TPPGSelection;
    function DropRowAt(Y: Integer): Integer;
    procedure UpdateDrag(X, Y: Integer);
    procedure CancelDrag;
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
    procedure WMLButtonUp(var Message: TWMLButtonUp); message WM_LBUTTONUP;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMEnter(var Message: TCMEnter); message CM_ENTER;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  protected
    procedure WndProc(var Message: TMessage); override;
    procedure Resize; override;
    { Daten }
    procedure SetSource(const Value: IPPGItemSource);
    /// Initialisiert Data und fragt die Quelle.
    procedure GetItemData(Index: Integer; var Data: TPPGItemData); virtual;
    /// Strukturaenderungen mit bekanntem Ort (Auswahl wandert mit).
    procedure ItemsInserted(Index, ACount: Integer);
    procedure ItemsDeleted(Index, ACount: Integer);
    /// Alles neu (Anzahl/Reihenfolge unbekannt geaendert).
    procedure ItemsReset;
    procedure ItemChanged(Index: Integer);
    { Layout }
    function FrameInset: Integer; override;
    procedure InvalidateLayout;
    procedure EnsureLayout;
    /// Audit 8d #6: vor jedem Zugriff auf Eintraege, Auswahl oder Layout; Unterklassen
    /// mit verzoegertem Aufbau (TreeView) holen ihn hier nach.
    procedure SyncItems; virtual;
    /// True: jede Zeile einzeln vermessen (Kosten O(n)). Standard: Quelle ist
    /// nicht virtuell und Gruppen/Detailzeilen vorhanden (siehe ScanRichItems).
    function UseVariableRows: Boolean; virtual;
    /// Hoehe einer Zeile ohne Ueberschrift (variabler Modus).
    function MeasureItem(Index: Integer; const Data: TPPGItemData): Integer; virtual;
    /// Standardhoehe (fester Modus bzw. ItemHeight).
    function DefaultItemHeight: Integer; virtual;
    /// Zweizeilige Eintraege (Detailzeile) im festen Modus.
    function TwoLineItems: Boolean; virtual;
    /// Mehrspaltig wie TListBox.Columns (0 = einspaltig; nur ohne Gruppen/Detailzeilen).
    function ListColumns: Integer; virtual;
    /// Breite fuer waagerechten Bildlauf in logischen px (0 = keiner), wie TListBox.ScrollWidth.
    function ListScrollWidth: Integer; virtual;
    /// Tabulatorbreite in Dialogeinheiten (0 = Tabs nicht aufloesen), wie TListBox.TabWidth.
    function ListTabWidth: Integer; virtual;
    /// Mehrspaltige Anordnung aktiv (nach EnsureLayout): Zeilen je Spalte, Spaltenbreite.
    function MultiColumn(out RowsPerCol, ColW: Integer): Boolean;
    /// Eintrag kann gewaehlt/fokussiert werden (Ueberschriften, deaktivierte nicht).
    function CanSelectItem(Index: Integer): Boolean; virtual;
    { Zeichnen }
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure PaintViewport(const ACanvas: IPPGCanvas; const View: TRect); override;
    procedure GetListStyles(out ListStyle, HighlightStyle: TPPGSurfaceStyle); virtual;
    function GetPaintInfo: TPPGItemPaintInfo;
    /// Eine Zeile (R ohne Ueberschrift). Nachfahren: Kaestchen, Einzug, Owner-Draw.
    procedure PaintItem(const ACanvas: IPPGCanvas; Index: Integer; const R: TRect;
      const Data: TPPGItemData; const Info: TPPGItemPaintInfo); virtual;
    /// Eintrag als gewaehlt zeichnen (Baum: HideSelection ohne Fokus = nein).
    function ItemPaintSelected(Index: Integer): Boolean; virtual;
    /// Einzug vor dem Inhalt (Baum, Kaestchen) in Pixeln.
    function ItemIndent(Index: Integer; const Data: TPPGItemData): Integer; virtual;
    /// Flaeche fuer Auswahl, Hover und Zeilenfarbe (Standard: ganze Zeile).
    function ItemHighlightRect(Index: Integer; const R: TRect; const Data: TPPGItemData): TRect; virtual;
    /// Eigenes Zeichnen eines Eintrags (OnCustomDrawItem); Ergebnis = DefaultDraw.
    /// Der Baum ueberschreibt das (Ereignis mit Knoten).
    function DoCustomDrawItem(const ACanvas: IPPGCanvas; Index: Integer; const R: TRect;
      State: TPPGItemDrawState; var Style: TPPGDrawStyle): Boolean; virtual;
    /// Ist eigenes Zeichnen eingehaengt?
    function HasCustomDraw: Boolean; virtual;
    /// Zusaetzliche Schriftstile eines Eintrags (Baum: HotTrack unterstreicht).
    function ItemExtraFontStyle(Index: Integer; Hot: Boolean): TFontStyles; virtual;
    /// TCanvas fuer eigenes Zeichnen (ohne eigenes Handle).
    property DrawCanvas: TCanvas read FDrawCanvas;
    function GetScrollStyle: TPPGSurfaceStyle; override;
    function GetBackgroundColor: TColor; override;
    /// Flaeche und Text der Liste (Hochkontrast > VCL-Style > Dark Mode > Color/Font).
    procedure GetListColors(out Fill, Text: TColor); virtual;
    { Eingabe }
    procedure ContentMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure ContentMouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure ContentMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoAutoScroll(const P: TPoint); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    /// Eigene Tastennavigation (Audit 7c #1): laeuft in KeyDown NACH OnKeyDown
    /// und nur, wenn das Ereignis die Taste nicht verbraucht hat (Key <> 0).
    /// Nachfahren ueberschreiben das statt KeyDown, damit OnKeyDown genau einmal kommt.
    procedure NavigateKey(var Key: Word; Shift: TShiftState); virtual;
    procedure KeyPress(var Key: Char); override;
    /// Klick auf einen Eintrag (vor der Auswahl). True = verbraucht (z.B. Kaestchen).
    function ItemMouseDown(Index: Integer; Shift: TShiftState; X, Y: Integer): Boolean; virtual;
    /// Leertaste auf dem Fokus-Eintrag. True = verbraucht.
    function ItemSpaceKey(Index: Integer): Boolean; virtual;
    /// Pfeil links/rechts (Baum). True = verbraucht.
    function ItemHorzKey(Index: Integer; Key: Word; Shift: TShiftState): Boolean; virtual;
    procedure BeginUserAction;
    procedure EndUserAction;
    /// Nach einer Anwender-Aktion, die die Auswahl geaendert hat.
    procedure UserSelectionChanged; virtual;
    /// Tippsuche: erster waehlbarer Eintrag ab Start (mit Umlauf), dessen Text mit
    /// S beginnt; -1 = keiner. Virtuelle Quellen koennen das schneller.
    function FindItemByPrefix(const S: string; Start: Integer): Integer; virtual;
    /// Darf der Anwender den Fokus auf Index setzen (Baum: OnChanging)?
    function CanChangeFocusTo(Index: Integer): Boolean; virtual;
    /// Ziel beim Ziehen: Zeile, vor der eingefuegt wird (0..Count), bzw. mit
    /// Inside = True die Zeile, in die abgelegt wird (Baum). Standard: dazwischen.
    function DropTargetAt(Y: Integer; out Inside: Boolean): Integer; virtual;
    /// Ablegen ausfuehren (Standard: Umsortieren mit OnReorder/DoReorder).
    /// True = Daten geaendert.
    function DoDropAt(FromIndex, TargetRow: Integer; Inside: Boolean): Boolean; virtual;
    /// Auswahl ersetzen (z.B. nach Neuaufbau der Zeilen), ohne dass das als
    /// Anwender-Aenderung zaehlt.
    procedure ReplaceSelection(const Rows: array of Integer; AFocus: Integer);
    /// Daten verschieben (Umsortieren). False = nicht unterstuetzt.
    function DoReorder(FromIndex, ToIndex: Integer): Boolean; virtual;
    procedure ItemsChanged; virtual;
    { Barrierefreiheit }
    function AccRole: Integer; override;
    function AccState: Integer; override;
    function AccValue: string; override;
    function AccChildCount: Integer;
    function AccChildName(Id: Integer): string; virtual;
    function AccChildRole(Id: Integer): Integer; virtual;
    function AccChildState(Id: Integer): Integer; virtual;
    function AccChildRect(Id: Integer): TRect;
    function AccChildAt(X, Y: Integer): Integer;
    function AccChildDefaultAction(Id: Integer): string; virtual;
    procedure AccChildDoDefault(Id: Integer);
    function AccFocusedChild: Integer;
    function AccSelectedChild: Integer;
    function AccSelectedChildren: TArray<Integer>;
    function AccChildSelect(Id: Integer; Flags: Integer): Boolean;
    /// Standardaktion eines Kindes (aus der geposteten Nachricht).
    procedure DoAccChildAction(Index: Integer); virtual;
    /// Auswahl wie accSelect (SELFLAG_*), als Anwender-Aktion.
    procedure DoAccSelect(Index: Integer; Flags: Integer);

    { UI Automation (IPPGUiaSource): Liste mit Eintraegen (Art 1, A = Index).
      Der Baum ueberschreibt die Struktur (Knoten statt Indizes). }
    function UiaValid(const Id: TPPGUiaId): Boolean; virtual;
    function UiaParent(const Id: TPPGUiaId): TPPGUiaId; virtual;
    function UiaChildCount(const Id: TPPGUiaId): Integer; virtual;
    function UiaChild(const Id: TPPGUiaId; Index: Integer): TPPGUiaId; virtual;
    function UiaIndexInParent(const Id: TPPGUiaId): Integer; virtual;
    function UiaElementAt(X, Y: Integer): TPPGUiaId; virtual;
    function UiaFocused: TPPGUiaId; virtual;
    function UiaFromAccChild(ChildId: Integer): TPPGUiaId; virtual;
    function UiaControlType(const Id: TPPGUiaId): Integer; virtual;
    function UiaName(const Id: TPPGUiaId): string; virtual;
    function UiaRect(const Id: TPPGUiaId): TRect; virtual;
    function UiaEnabled(const Id: TPPGUiaId): Boolean; virtual;
    function UiaFocusable(const Id: TPPGUiaId): Boolean; virtual;
    function UiaProperty(const Id: TPPGUiaId; PropertyId: Integer; out Value: OleVariant): Boolean; virtual;
    function UiaHasPattern(const Id: TPPGUiaId; PatternId: Integer): Boolean; virtual;
    function UiaCanSelectMultiple: Boolean; virtual;
    function UiaSelection: TPPGUiaIds; virtual;
    function UiaIsSelected(const Id: TPPGUiaId): Boolean; virtual;
    procedure UiaGridSize(out Rows, Cols: Integer); virtual;
    function UiaGridItem(Row, Col: Integer): TPPGUiaId; virtual;
    procedure UiaGridPos(const Id: TPPGUiaId; out Row, Col: Integer); virtual;
    function UiaHeaders(Columns: Boolean): TPPGUiaIds; virtual;
    function UiaItemHeaders(const Id: TPPGUiaId; Columns: Boolean): TPPGUiaIds; virtual;
    function UiaValue(const Id: TPPGUiaId): string; virtual;
    function UiaReadOnly(const Id: TPPGUiaId): Boolean; virtual;
    function UiaExpandState(const Id: TPPGUiaId): Integer; virtual;
    function UiaToggleState(const Id: TPPGUiaId): Integer; virtual;
    procedure UiaExecute(const Id: TPPGUiaId; Action: TPPGUiaAction; const Value: string); virtual;
    /// Zeile (Index) eines Elements; -1 = keins. Der Baum bildet Knoten ab.
    function UiaRowOf(const Id: TPPGUiaId): Integer; virtual;
    /// Element einer Zeile (Index); Wurzel = keins.
    function UiaIdOfRow(Row: Integer): TPPGUiaId; virtual;

    property Painter: TPPGItemPainter read FPainter;
    property ItemHeight: Integer read FItemHeight write SetItemHeight default 0;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
    property AllowMarkup: Boolean read FAllowMarkup write SetAllowMarkup default False;
    property AllowReorder: Boolean read FAllowReorder write FAllowReorder default False;
    /// Tippsuche ueber die Anfangsbuchstaben (TListBox.AutoComplete).
    property TypeAhead: Boolean read FTypeAhead write FTypeAhead default True;
    /// Wie TTreeView.ToolTips: abgeschnittene Texte als Hinweis (nur ohne eigenen
    /// Hint; braucht ShowHint).
    property ToolTips: Boolean read FToolTips write FToolTips default True;
    property OnReorder: TPPGReorderEvent read FOnReorder write FOnReorder;
    /// Bereiche der Liste (Auswahl, Zebra, Hover, Gruppenkopf, Detailzeile).
    property Styles: TPPGListStyles read FListStyles write SetListStyles;
    /// Vor dem Zeichnen jedes Eintrags: Style anpassen oder selbst zeichnen.
    property OnCustomDrawItem: TPPGCustomDrawItemEvent read FOnCustomDrawItem write FOnCustomDrawItem;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Eintrag unter dem Punkt (Client), -1 = keiner (Ueberschrift zaehlt nicht).
    function ItemAtPos(X, Y: Integer): Integer; overload;
    /// Lage eines Eintrags in Client-Koordinaten (ohne Ueberschrift), leer = ausserhalb.
    function ItemRect(Index: Integer): TRect;
    procedure MakeItemVisible(Index: Integer; Animate: Boolean = False);
    procedure SelectAll;
    procedure ClearSelection;
    /// Liegt Index unter einer Gruppen-Ueberschrift (beginnt eine Gruppe)?
    function ItemStartsGroup(Index: Integer): Boolean;
    /// Anzahl der Eintraege der Quelle.
    function ItemCount: Integer;
    property Source: IPPGItemSource read FSource;
    property Selection: TPPGSelection read GetSelection;
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
    property TopIndex: Integer read GetTopIndex write SetTopIndex;
    property Selected[Index: Integer]: Boolean read GetSelected write SetSelected;
    property SelCount: Integer read GetSelCount;
    property HotIndex: Integer read FHotIndex;
    /// Laufendes Umsortieren: Einfuegezeile (-1 = keins).
    property DropRow: Integer read FDropRow;
    /// Laufendes Ziehen: Ablegen IN die Zeile DropRow (statt davor).
    property DropInside: Boolean read FDropInside;
  end;

implementation

uses
  PPG.Lang,
  System.SysUtils, System.Math, Winapi.oleacc, Vcl.StdCtrls, PPG.UIA.Intf,
  PPG.Consts, PPG.Exceptions, PPG.Appearance, PPG.Tokens, PPG.DpiUtils, PPG.VclStyles,
  PPG.Render.Registry, PPG.Markup.Parser, PPG.Render.Gdi;

const
  MaxVariableRows = 200000;   // darueber nie einzeln vermessen

var
  GMsgChildAction: Cardinal = 0;
  GMsgChildSelect: Cardinal = 0;
  GMsgLayout: Cardinal = 0;

{ TPPGCustomItemList }

constructor TPPGCustomItemList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 185;
  Height := 140;
  // Kein OnClick beim Loslassen (TControl): die Liste meldet Auswahlwechsel selbst
  ControlStyle := ControlStyle - [csClickEvents];
  ParentColor := False;
  Color := clWindow;
  FBorderStyle := bsSingle;
  FTypeAhead := True;
  FToolTips := True;
  FHotIndex := -1;
  FDownIndex := -1;
  FDropRow := -1;
  FLastFocus := -1;
  FSelection := TPPGSelection.Create;
  FSelection.OnChange := SelectionChange;
  FLayout := TPPGRowLayout.Create;
  FHeaders := TBits.Create;
  FPainter := TPPGItemPainter.Create;
  FListStyles := TPPGListStyles.Create(Self);
  FListStyles.OnChange := ListStylesChanged;
  FDrawCanvas := TCanvas.Create;
  if GMsgChildAction = 0 then
    GMsgChildAction := RegisterWindowMessage('PPGlow.ItemListChildAction');
  if GMsgChildSelect = 0 then
    GMsgChildSelect := RegisterWindowMessage('PPGlow.ItemListChildSelect');
  if GMsgLayout = 0 then
    GMsgLayout := RegisterWindowMessage('PPGlow.ItemListLayout');
end;

destructor TPPGCustomItemList.Destroy;
begin
  if FSource <> nil then
    FSource.OnChanged := nil;
  FSource := nil;
  if FSelection <> nil then
    FSelection.OnChange := nil;
  FreeAndNil(FPainter);
  FreeAndNil(FDrawCanvas);
  FreeAndNil(FListStyles);
  FreeAndNil(FHeaders);
  FreeAndNil(FLayout);
  FreeAndNil(FSelection);
  inherited Destroy;
end;

{ ---- Daten ---- }

procedure TPPGCustomItemList.SetSource(const Value: IPPGItemSource);
begin
  if FSource = Value then
    Exit;
  if FSource <> nil then
    FSource.OnChanged := nil;
  FSource := Value;
  if FSource <> nil then
    FSource.OnChanged := SourceChange;
  ItemsReset;
end;

function TPPGCustomItemList.ItemCount: Integer;
begin
  if FSource = nil then
    Result := 0
  else
    Result := FSource.Count;
end;

procedure TPPGCustomItemList.GetItemData(Index: Integer; var Data: TPPGItemData);
begin
  PPGInitItemData(Data);
  if (FSource <> nil) and (Index >= 0) and (Index < FSource.Count) then
    FSource.GetItem(Index, Data);
end;

procedure TPPGCustomItemList.SourceChange(Sender: TObject; Index: Integer);
begin
  if Index >= 0 then
    ItemChanged(Index)
  else
    ItemsReset;
end;

procedure TPPGCustomItemList.ReleaseDownIndex;
begin
  CancelDrag;
  FDownIndex := -1;
end;

procedure TPPGCustomItemList.ItemsInserted(Index, ACount: Integer);
begin
  // Audit 08.10.2026: Der gedrueckte bzw. gezogene Eintrag behaelt nach
  // Einfuegen/Loeschen nicht seinen Index (z. B. OnClick ruft Items.Clear,
  // der Anwender zieht weiter -> FItems.Move wirft). Index nachfuehren bzw.
  // das Ziehen abbrechen.
  Inc(FStructChanges);
  if (FDownIndex >= 0) and (FDownIndex >= Index) then
    Inc(FDownIndex, ACount);
  FSelection.ItemsInserted(Index, ACount);
  if FHotIndex >= Index then
    FHotIndex := -1;
  InvalidateLayout;
  ItemsChanged;
end;

procedure TPPGCustomItemList.ItemsDeleted(Index, ACount: Integer);
begin
  Inc(FStructChanges);
  if FDownIndex >= Index + ACount then
    Dec(FDownIndex, ACount)
  else if FDownIndex >= Index then
    ReleaseDownIndex; // der gezogene Eintrag ist weg
  FSelection.ItemsDeleted(Index, ACount);
  if FHotIndex >= Index then
    FHotIndex := -1;
  InvalidateLayout;
  ItemsChanged;
end;

procedure TPPGCustomItemList.ItemsReset;
begin
  // Neu aufgebaut (Clear, Neuladen, Baum auf-/zuklappen): Ein Index
  // ausserhalb der Liste ist sicher ungueltig. Innerhalb bleibt er, damit
  // z. B. AutoExpand beim Klick das Ziehen desselben Knotens nicht abbricht.
  Inc(FStructChanges);
  if FDownIndex >= ItemCount then
    ReleaseDownIndex;
  FSelection.Count := ItemCount;
  FHotIndex := -1;
  InvalidateLayout;
  ItemsChanged;
end;

procedure TPPGCustomItemList.ItemChanged(Index: Integer);
begin
  // Hoehe kann sich geaendert haben (Gruppe, Detailzeile)
  if UseVariableRows then
    InvalidateLayout
  else
    Invalidate;
end;

procedure TPPGCustomItemList.ItemsChanged;
begin
  if HandleAllocated then
    NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

{ ---- Layout ---- }

function TPPGCustomItemList.FrameInset: Integer;
var
  S: TPPGSurfaceStyle;
begin
  if FBorderStyle = bsNone then
    Exit(0);
  S := EffectiveAppearance.Resolve(vsNormal, ScalePPI, False);
  Result := S.BorderWidth;
  if Result < 1 then
    Result := 1;
  // Kleiner Innenabstand, damit Zeilen die Rundung nicht beruehren
  Inc(Result, PPGScale(2, ScalePPI));
end;

procedure TPPGCustomItemList.InvalidateLayout;
begin
  FLayoutValid := False;
  // Neu vermessen ausserhalb von Paint (Paint darf keine Ereignisse wie
  // OnScroll ausloesen); viele Aenderungen hintereinander = ein Durchlauf
  if HandleAllocated and not FLayoutPosted and (GMsgLayout <> 0) then
  begin
    FLayoutPosted := True;
    PostMessage(Handle, GMsgLayout, 0, 0);
  end;
  Invalidate;
end;

function TPPGCustomItemList.TwoLineItems: Boolean;
begin
  Result := False;
end;

function TPPGCustomItemList.DefaultItemHeight: Integer;
var
  Min: Integer;
begin
  // ItemHeight ist eine Mindesthoehe (wie bei der Combo): alte TListBox-DFMs
  // speichern immer "ItemHeight = 13" - das waere fuer die Zeilen zu eng
  Result := TPPGItemPainter.RowHeight(Font, Images, TwoLineItems, ScalePPI);
  Min := PPGScale(FItemHeight, ScalePPI);
  if Result < Min then
    Result := Min;
end;

function TPPGCustomItemList.ListColumns: Integer;
begin
  Result := 0;
end;

function TPPGCustomItemList.ListScrollWidth: Integer;
begin
  Result := 0;
end;

function TPPGCustomItemList.ListTabWidth: Integer;
begin
  Result := 0;
end;

function TPPGCustomItemList.MultiColumn(out RowsPerCol, ColW: Integer): Boolean;
var
  V: TRect;
  Cols, H: Integer;
begin
  RowsPerCol := 1;
  ColW := 1;
  Cols := ListColumns;
  // Gruppen und Detailzeilen (variable Hoehen) bleiben einspaltig
  Result := (Cols > 0) and (FHeaders.Size = 0);
  if not Result then
    Exit;
  V := ViewRect;
  H := FLayout.DefaultHeight;
  if H < 1 then
    H := 1;
  RowsPerCol := Max(1, (V.Bottom - V.Top) div H);
  ColW := Max(1, (V.Right - V.Left) div Cols);
end;

function TPPGCustomItemList.UseVariableRows: Boolean;
begin
  Result := False;
end;

function TPPGCustomItemList.MeasureItem(Index: Integer; const Data: TPPGItemData): Integer;
begin
  // Audit 8d #2: EnsureLayout hat die Standardhoehe schon einmal berechnet
  // (vorher je Eintrag eine Textmessung mit eigenem DC)
  if FLayout.DefaultHeight > 0 then
    Result := FLayout.DefaultHeight
  else
    Result := DefaultItemHeight;
end;

procedure TPPGCustomItemList.EnsureLayout;
var
  N, I, H, W, RPC, CW: Integer;
  V: TRect;
  Data: TPPGItemData;
  Group: string;
  Variable: Boolean;
begin
  SyncItems;
  if FLayoutValid and (FLayoutPPI = ScalePPI) and (FLayoutFontH = Font.Height) then
    Exit;
  FLayoutValid := True;
  FLayoutPPI := ScalePPI;
  FLayoutFontH := Font.Height;
  N := ItemCount;
  FLayout.Count := 0;
  FLayout.DefaultHeight := DefaultItemHeight;
  FLayout.Count := N;
  FHeaderH := TPPGItemPainter.GroupHeaderHeight(Font, ScalePPI);
  Variable := (N <= MaxVariableRows) and UseVariableRows;
  // Erst leeren: TBits behaelt bei gleicher Groesse alte Ueberschriften
  FHeaders.Size := 0;
  if Variable then
    FHeaders.Size := N
  else
    FHeaders.Size := 0;
  if Variable then
  begin
    Group := '';
    for I := 0 to N - 1 do
    begin
      GetItemData(I, Data);
      H := MeasureItem(I, Data);
      // Neue Gruppe: Ueberschrift ueber dem ersten Eintrag
      if (Data.Group <> '') and ((I = 0) or (Data.Group <> Group)) then
      begin
        FHeaders[I] := True;
        Inc(H, FHeaderH);
      end;
      Group := Data.Group;
      if H < 1 then
        H := 1;
      if H <> FLayout.DefaultHeight then
        FLayout.SetRowHeight(I, H);
    end;
  end;
  // Mehrspaltig: Spalten nebeneinander, nur waagerechter Bildlauf
  if MultiColumn(RPC, CW) then
  begin
    SetContentSize(((N + RPC - 1) div RPC) * CW, 0);
    Exit;
  end;
  // Sonst waagerechter Bildlauf nur mit ScrollWidth (breiter als die Ansicht)
  W := PPGScale(ListScrollWidth, ScalePPI);
  V := ViewRect;
  if W <= V.Right - V.Left then
    W := 0;
  if FLayout.TotalHeight64 > MaxInt then
    SetContentSize(W, MaxInt)
  else
    SetContentSize(W, FLayout.TotalHeight);
end;

function TPPGCustomItemList.ItemStartsGroup(Index: Integer): Boolean;
begin
  EnsureLayout;
  Result := (Index >= 0) and (Index < FHeaders.Size) and FHeaders[Index];
end;

function TPPGCustomItemList.ItemRect(Index: Integer): TRect;
var
  V: TRect;
  Top: Int64;
  RPC, CW, X, Y: Integer;
begin
  Result := Rect(0, 0, 0, 0);
  EnsureLayout;
  if (Index < 0) or (Index >= FLayout.Count) then
    Exit;
  V := ViewRect;
  if MultiColumn(RPC, CW) then
  begin
    X := V.Left + (Index div RPC) * CW - ScrollX;
    Y := V.Top + (Index mod RPC) * FLayout.DefaultHeight;
    if (X >= V.Right) or (X + CW <= V.Left) then
      Exit;
    Exit(Rect(X, Y, X + CW, Y + FLayout.DefaultHeight));
  end;
  Top := FLayout.RowTop(Index) - ScrollY + V.Top;
  if (Top > V.Bottom) or (Top + FLayout.RowHeight(Index) < V.Top) then
    Exit;
  Result := Rect(V.Left, Integer(Top), V.Right, Integer(Top) + FLayout.RowHeight(Index));
  // Waagerechter Bildlauf (ScrollWidth): Zeile so breit wie der Inhalt
  if ContentWidth > V.Right - V.Left then
  begin
    Result.Left := V.Left - ScrollX;
    Result.Right := Result.Left + ContentWidth;
  end;
  if ItemStartsGroup(Index) then
    Inc(Result.Top, FHeaderH);
end;

function TPPGCustomItemList.ItemAtPos(X, Y: Integer): Integer;
var
  V: TRect;
  Row, RPC, CW, Col: Integer;
  CY: Int64;
begin
  Result := -1;
  EnsureLayout;
  V := ViewRect;
  if not PtInRect(V, Point(X, Y)) or (FLayout.Count = 0) then
    Exit;
  if MultiColumn(RPC, CW) then
  begin
    Col := (X - V.Left + ScrollX) div CW;
    Row := (Y - V.Top) div Max(1, FLayout.DefaultHeight);
    if (Col >= 0) and (Row >= 0) and (Row < RPC) and (Int64(Col) * RPC + Row < FLayout.Count) then
      Result := Col * RPC + Row;
    Exit;
  end;
  CY := Int64(Y - V.Top) + ScrollY;
  if CY >= FLayout.TotalHeight64 then
    Exit;
  Row := FLayout.RowAt(CY);
  if (Row < 0) or (Row >= FLayout.Count) then
    Exit;
  // Klick auf die Ueberschrift ist kein Eintrag
  if ItemStartsGroup(Row) and (CY < FLayout.RowTop(Row) + FHeaderH) then
    Exit;
  Result := Row;
end;

procedure TPPGCustomItemList.MakeItemVisible(Index: Integer; Animate: Boolean);
var
  Top: Int64;
  H, RPC, CW: Integer;
begin
  EnsureLayout;
  if (Index < 0) or (Index >= FLayout.Count) then
    Exit;
  if MultiColumn(RPC, CW) then
  begin
    MakeVisible(Rect((Index div RPC) * CW, 0, (Index div RPC + 1) * CW, 1), Animate);
    Exit;
  end;
  Top := FLayout.RowTop(Index);
  H := FLayout.RowHeight(Index);
  if Top > MaxInt - H then
    Exit;
  // waagerechte Lage beibehalten (ScrollWidth)
  MakeVisible(Rect(ScrollX, Integer(Top), ScrollX + 1, Integer(Top) + H), Animate);
end;

function TPPGCustomItemList.GetTopIndex: Integer;
var
  RPC, CW: Integer;
begin
  EnsureLayout;
  if FLayout.Count = 0 then
    Result := 0
  else if MultiColumn(RPC, CW) then
    Result := (ScrollX div CW) * RPC
  else
    Result := FLayout.RowAt(ScrollY);
end;

procedure TPPGCustomItemList.SetTopIndex(const Value: Integer);
var
  RPC, CW: Integer;
begin
  EnsureLayout;
  if MultiColumn(RPC, CW) then
  begin
    if (Value >= 0) and (Value < FLayout.Count) then
      ScrollTo((Value div RPC) * CW, 0);
    Exit;
  end;
  if (Value >= 0) and (Value < FLayout.Count) and (FLayout.RowTop(Value) <= MaxInt) then
    ScrollTo(0, Integer(FLayout.RowTop(Value)));
end;

procedure TPPGCustomItemList.Resize;
begin
  inherited Resize;
  // Spalten und Bildlaufbreite haengen von der Groesse ab
  if (ListColumns > 0) or (ListScrollWidth > 0) then
    InvalidateLayout
  else
    Invalidate;
end;

procedure TPPGCustomItemList.SetItemHeight(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'ItemHeight', Value, 0, 1000);
  if FItemHeight <> V then
  begin
    FItemHeight := V;
    InvalidateLayout;
  end;
end;

procedure TPPGCustomItemList.SetBorderStyle(const Value: TBorderStyle);
begin
  if FBorderStyle <> Value then
  begin
    FBorderStyle := Value;
    UpdateScrollGeometry;
  end;
end;

procedure TPPGCustomItemList.SetAllowMarkup(const Value: Boolean);
begin
  if FAllowMarkup <> Value then
  begin
    FAllowMarkup := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomItemList.CMFontChanged(var Message: TMessage);
begin
  inherited;
  InvalidateLayout;
end;

{ ---- Auswahl ---- }

procedure TPPGCustomItemList.SelectionChange(Sender: TObject);
var
  F: Integer;
begin
  Inc(FSelChanges);
  Invalidate;
  if not HandleAllocated then
    Exit;
  F := FSelection.Focus;
  if Focused and (F >= 0) and (F <> FLastFocus) then
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, F + 1);
  FLastFocus := F;
  if FSelection.Mode = smSingle then
  begin
    if FSelection.ItemIndex >= 0 then
      NotifyAccessibilityChild(EVENT_OBJECT_SELECTION, FSelection.ItemIndex + 1);
  end
  else
    NotifyAccessibility(EVENT_OBJECT_SELECTIONWITHIN);
end;

procedure TPPGCustomItemList.BeginUserAction;
begin
  if FUserLevel = 0 then
    FUserStartChanges := FSelChanges;
  Inc(FUserLevel);
end;

procedure TPPGCustomItemList.EndUserAction;
begin
  Dec(FUserLevel);
  if (FUserLevel = 0) and (FSelChanges <> FUserStartChanges) then
    UserSelectionChanged;
end;

procedure TPPGCustomItemList.UserSelectionChanged;
begin
end;

procedure TPPGCustomItemList.SyncItems;
begin
  // nichts: Quelle ist immer aktuell
end;

function TPPGCustomItemList.GetSelection: TPPGSelection;
begin
  SyncItems;
  Result := FSelection;
end;

function TPPGCustomItemList.GetItemIndex: Integer;
begin
  SyncItems;
  Result := FSelection.ItemIndex;
end;

procedure TPPGCustomItemList.SetItemIndex(const Value: Integer);
var
  V: Integer;
begin
  V := Value;
  if (V < -1) or (V >= ItemCount) then
    V := -1;
  // Im Code gesetzt: ohne Ereignis. Wie TListBox: einfache Auswahl waehlt den
  // Eintrag, Mehrfachauswahl setzt nur den Fokus (LB_SETCARETINDEX)
  FSelection.BeginUpdate;
  try
    if FSelection.Mode = smSingle then
    begin
      FSelection.Clear;
      if V >= 0 then
        FSelection.Selected[V] := True;
    end;
    FSelection.Focus := V;
  finally
    FSelection.EndUpdate;
  end;
  if V >= 0 then
    MakeItemVisible(V);
end;

function TPPGCustomItemList.GetSelected(Index: Integer): Boolean;
begin
  SyncItems;
  Result := FSelection.Selected[Index];
end;

procedure TPPGCustomItemList.SetSelected(Index: Integer; const Value: Boolean);
begin
  if (Index < 0) or (Index >= ItemCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, ItemCount - 1]);
  FSelection.Selected[Index] := Value;
end;

function TPPGCustomItemList.GetSelCount: Integer;
begin
  SyncItems;
  if FSelection.Mode = smSingle then
    Result := -1 // wie TListBox ohne MultiSelect
  else
    Result := FSelection.SelCount;
end;

procedure TPPGCustomItemList.SelectAll;
begin
  SyncItems;
  FSelection.SelectAll;
end;

procedure TPPGCustomItemList.ClearSelection;
begin
  SyncItems;
  FSelection.Clear;
end;

function TPPGCustomItemList.CanSelectItem(Index: Integer): Boolean;
var
  Data: TPPGItemData;
begin
  GetItemData(Index, Data);
  Result := not Data.IsHeader;
end;

{ ---- Farben und Zeichnen ---- }

procedure TPPGCustomItemList.GetListColors(out Fill, Text: TColor);
var
  SelFill, SelText: TColor;
  T: TPPGTokens;
begin
  if UseHighContrast or UseDarkMode then
  begin
    // Dunkle Tokens bzw. im Hochkontrast clWindow/clWindowText
    T := Tokens;
    Fill := T.Surface;
    Text := T.TextPrimary;
  end
  else if UseVclStyle then
    PPGVclStyleListColors(Fill, Text, SelFill, SelText)
  else
  begin
    Fill := PPGColorToRGB(Color);
    Text := PPGColorToRGB(Font.Color);
  end;
end;

procedure TPPGCustomItemList.GetListStyles(out ListStyle, HighlightStyle: TPPGSurfaceStyle);
var
  A: TPPGAppearance;
  T: TPPGTokens;
  PPI: Integer;
  Fill, Text, SelFill, SelText: TColor;
begin
  A := EffectiveAppearance;
  PPI := ScalePPI;
  ListStyle := A.Resolve(vsNormal, PPI, False);
  HighlightStyle := A.Resolve(vsHot, PPI, False);
  GetListColors(Fill, Text);
  ListStyle.Color := Fill;
  ListStyle.ColorTo := Fill;
  ListStyle.ColorMirror := Fill;
  ListStyle.ColorMirrorTo := Fill;
  ListStyle.TextColor := Text;
  ListStyle.GlowColor := PPGColorToRGB(A.FocusColor);
  ListStyle.GlowAlpha := 0;
  if not Enabled then
    ListStyle.BorderColor := PPGColorToRGB(A.Disabled.BorderColor);
  // Auf heller Flaeche ist die Hover-Flaeche der Buttons (fast weiss) zu
  // schwach: Hover dann als dezente Mischung mit der Textfarbe
  if PPGContrastRatio(HighlightStyle.Color, Fill) < 1.05 then
    HighlightStyle.Color := PPGBlendColor(Fill, Text, 0.06);
  if UseHighContrast then
  begin
    // Sonderfall: Rahmen in Textfarbe, Auswahl als volle Markierung
    T := Tokens;
    ListStyle.BorderColor := T.Stroke;
    ListStyle.GlowColor := T.Accent;
    SelFill := T.Accent;
    SelText := T.OnAccent;
    HighlightStyle.Color := SelFill;
    HighlightStyle.ColorTo := SelFill;
    HighlightStyle.ColorMirror := SelFill;
    HighlightStyle.ColorMirrorTo := SelFill;
    HighlightStyle.BorderColor := SelFill;
    HighlightStyle.TextColor := SelText;
  end
  else if UseVclStyle then
  begin
    PPGVclStyleListColors(Fill, Text, SelFill, SelText);
    ListStyle.GlowColor := SelFill;
    HighlightStyle.Color := SelFill;
    HighlightStyle.ColorTo := SelFill;
    HighlightStyle.ColorMirror := SelFill;
    HighlightStyle.ColorMirrorTo := SelFill;
    HighlightStyle.BorderColor := SelFill;
    HighlightStyle.TextColor := SelText;
  end;
  // Deaktiviert: Auswahl und Akzent-Indikator zuruecknehmen (Classic: sonst kraeftig gelb)
  if not Enabled and not UseHighContrast then
  begin
    HighlightStyle.Color := PPGBlendColor(PPGBlendColor(HighlightStyle.Color, Fill, 0.6),
      PPGBlendColor(Fill, Text, 0.08), 0.5);
    HighlightStyle.ColorTo := HighlightStyle.Color;
    HighlightStyle.ColorMirror := HighlightStyle.Color;
    HighlightStyle.ColorMirrorTo := HighlightStyle.Color;
    HighlightStyle.BorderColor := PPGBlendColor(HighlightStyle.BorderColor, Fill, 0.6);
    HighlightStyle.GlowAlpha := 0;
    ListStyle.GlowColor := PPGBlendColor(ListStyle.GlowColor, Fill, 0.6);
  end;
end;

function TPPGCustomItemList.GetPaintInfo: TPPGItemPaintInfo;
begin
  GetListStyles(Result.ListStyle, Result.HighlightStyle);
  Result.Font := Font;
  Result.Images := Images;
  Result.AllowMarkup := FAllowMarkup;
  Result.RightToLeft := UseRightToLeftAlignment;
  Result.Enabled := Enabled;
  Result.PPI := ScalePPI;
  Result.Styles := FListStyles;
  Result.UseColors := UseOwnColors;
  Result.Dark := UseDarkMode;
  Result.Focused := Focused;
  Result.TabWidth := 0;
  if ListTabWidth > 0 then
    Result.TabWidth := TPPGItemPainter.TabUnitsToPixels(Font, ListTabWidth);
end;

function TPPGCustomItemList.GetScrollStyle: TPPGSurfaceStyle;
var
  Fill, Text: TColor;
begin
  Result := inherited GetScrollStyle;
  GetListColors(Fill, Text);
  Result.Color := Fill;
  Result.TextColor := Text;
end;

function TPPGCustomItemList.GetBackgroundColor: TColor;
begin
  // Ecken ausserhalb der Rundung gehoeren dem Parent
  if (FBorderStyle = bsSingle) and (Parent <> nil) then
    Result := TPPGCustomItemList(Parent).Color
  else
    Result := Color;
end;

procedure TPPGCustomItemList.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  L, H: TPPGSurfaceStyle;
  CR: IPPGContainerRenderer;
  Fill, Text: TColor;
begin
  EnsureLayout;
  GetListStyles(L, H);
  if FBorderStyle = bsSingle then
  begin
    if L.BorderWidth < 1 then
      L.BorderWidth := 1;
    if not Supports(Renderer, IPPGContainerRenderer, CR) then
      Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
        IPPGContainerRenderer, CR);
    CR.DrawContainer(ACanvas, ClientR, L);
  end
  else
  begin
    GetListColors(Fill, Text);
    ACanvas.FillRoundRect(ClientR, 0, Fill, 255);
  end;
  inherited DoPaint(ACanvas, ClientR); // Ansicht (PaintViewport) + Leisten
end;

function TPPGCustomItemList.ItemPaintSelected(Index: Integer): Boolean;
begin
  Result := FSelection.Selected[Index];
end;

function TPPGCustomItemList.ItemIndent(Index: Integer; const Data: TPPGItemData): Integer;
begin
  Result := 0;
end;

function TPPGCustomItemList.ItemHighlightRect(Index: Integer; const R: TRect;
  const Data: TPPGItemData): TRect;
begin
  Result := R;
end;

procedure TPPGCustomItemList.SetListStyles(const Value: TPPGListStyles);
begin
  FListStyles.Assign(Value);
end;

procedure TPPGCustomItemList.ListStylesChanged(Sender: TObject);
begin
  Invalidate;
end;

function TPPGCustomItemList.HasCustomDraw: Boolean;
begin
  Result := Assigned(FOnCustomDrawItem);
end;

function TPPGCustomItemList.DoCustomDrawItem(const ACanvas: IPPGCanvas; Index: Integer;
  const R: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle): Boolean;
begin
  Result := PPGRunCustomDraw(ACanvas, FDrawCanvas, Font, FOnCustomDrawItem, Self, Index, R,
    State, Style);
end;

function TPPGCustomItemList.ItemExtraFontStyle(Index: Integer; Hot: Boolean): TFontStyles;
begin
  Result := [];
end;

procedure TPPGCustomItemList.PaintItem(const ACanvas: IPPGCanvas; Index: Integer;
  const R: TRect; const Data: TPPGItemData; const Info: TPPGItemPaintInfo);
var
  IR: IPPGItemRenderer;
  Sel, Foc: Boolean;
  Hot: Single;
  C: TRect;
  Indent: Integer;
  D: TPPGItemData;
  St: TPPGItemDrawState;
  DS: TPPGDrawStyle;
begin
  IR := PPGItemRendererOf(Renderer);
  if Data.IsHeader then
  begin
    FPainter.PaintGroupHeader(ACanvas, IR, R, Data.Text, Info);
    Exit;
  end;
  Sel := ItemPaintSelected(Index);
  Foc := FocusVisible and (Index = FSelection.Focus);
  if (Index = FHotIndex) and Data.Enabled and Enabled then
    Hot := 1
  else
    Hot := 0;
  D := Data;
  D.FontStyle := D.FontStyle + ItemExtraFontStyle(Index, Hot > 0);
  // Eigenes Zeichnen: Style aendert Farben/Schrift, DefaultDraw = False
  // ueberlaesst den ganzen Eintrag dem Ereignis
  if HasCustomDraw then
  begin
    St := [];
    if Sel then
      Include(St, idsSelected);
    if Foc then
      Include(St, idsFocused);
    if Hot > 0 then
      Include(St, idsHot);
    if not (Enabled and Data.Enabled) then
      Include(St, idsDisabled);
    if Data.Checked = cbChecked then
      Include(St, idsChecked);
    if not DoCustomDrawItem(ACanvas, Index, R, St, DS) then
      Exit;
    if DS.Fill <> clNone then
      D.Color := DS.Fill;
    if DS.TextColor <> clNone then
      D.TextColor := DS.TextColor;
    D.FontStyle := D.FontStyle + DS.FontStyle;
  end;
  FPainter.PaintItemBackground(ACanvas, IR, ItemHighlightRect(Index, R, D), Info, D, Index, Sel, Foc, Hot);
  C := R;
  Indent := ItemIndent(Index, Data);
  if Info.RightToLeft then
    Dec(C.Right, Indent)
  else
    Inc(C.Left, Indent);
  FPainter.PaintItemContent(ACanvas, IR, C, D, Info, Index, Sel, Hot);
end;

procedure TPPGCustomItemList.PaintViewport(const ACanvas: IPPGCanvas; const View: TRect);
var
  Info: TPPGItemPaintInfo;
  IR: IPPGItemRenderer;
  I, N, RPC, CW, X, RL, RR: Integer;
  Top: Int64;
  R, HR, DR, Clip: TRect;
  Data: TPPGItemData;
  Y, LineH, M: Integer;
begin
  EnsureLayout;
  N := FLayout.Count;
  if N = 0 then
    Exit;
  // Audit 8a #1: nur Zeilen im neu zu zeichnenden Bereich (Rand M fuer
  // Fokusrahmen und Glow, die ueber die Zeile hinausreichen koennen)
  Clip := ViewportClip;
  M := PPGScale(4, ScalePPI);
  Info := GetPaintInfo;
  IR := PPGItemRendererOf(Renderer);
  try
    if MultiColumn(RPC, CW) then
    begin
      // Spaltenweise: oben nach unten, dann die naechste Spalte
      I := (ScrollX div CW) * RPC;
      while I < N do
      begin
        X := View.Left + (I div RPC) * CW - ScrollX;
        if X >= View.Right then
          Break;
        Y := View.Top + (I mod RPC) * FLayout.DefaultHeight;
        R := Rect(X, Y, X + CW, Y + FLayout.DefaultHeight);
        if NeedsPaint(R, M) then
        begin
          GetItemData(I, Data);
          PaintItem(ACanvas, I, R, Data, Info);
        end;
        Inc(I);
      end;
      Exit;
    end;
    // Waagerechter Bildlauf (ScrollWidth): Zeilen so breit wie der Inhalt
    RL := View.Left;
    RR := View.Right;
    if ContentWidth > View.Right - View.Left then
    begin
      RL := View.Left - ScrollX;
      RR := RL + ContentWidth;
    end;
    Y := ScrollY;
    if Clip.Top - M > View.Top then
      Y := ScrollY + (Clip.Top - M - View.Top);
    I := FLayout.RowAt(Y);
    while (I >= 0) and (I < N) do
    begin
      Top := FLayout.RowTop(I) - ScrollY + View.Top;
      if (Top >= View.Bottom) or (Top >= Clip.Bottom + M) then
        Break;
      R := Rect(RL, Integer(Top), RR, Integer(Top) + FLayout.RowHeight(I));
      if not NeedsPaint(R, M) then
      begin
        Inc(I);
        Continue;
      end;
      GetItemData(I, Data);
      if ItemStartsGroup(I) then
      begin
        HR := R;
        HR.Bottom := HR.Top + FHeaderH;
        FPainter.PaintGroupHeader(ACanvas, IR, HR, Data.Group, Info);
        R.Top := HR.Bottom;
      end;
      PaintItem(ACanvas, I, R, Data, Info);
      Inc(I);
    end;
    // Ablegen in eine Zeile (Baum): Zeile als Ziel hervorheben
    if FDragging and FDropInside and (FDropRow >= 0) and (FDropRow < N) then
    begin
      R := ItemRect(FDropRow);
      if not IsRectEmpty(R) then
        IR.DrawItemBackground(ACanvas, R, Info.ListStyle, Info.HighlightStyle, False, True,
          1, Info.RightToLeft, Info.PPI);
    end
    // Einfuegemarke beim Umsortieren
    else if FDragging and (FDropRow >= 0) then
    begin
      if FDropRow < N then
        Y := Integer(FLayout.RowTop(FDropRow) - ScrollY) + View.Top
      else
        Y := Integer(FLayout.TotalHeight64 - ScrollY) + View.Top;
      LineH := PPGScale(2, ScalePPI);
      DR := Rect(View.Left + PPGScale(4, ScalePPI), Y - LineH div 2,
        View.Right - PPGScale(4, ScalePPI), Y - LineH div 2 + LineH);
      IR.DrawDropIndicator(ACanvas, DR, Info.ListStyle.GlowColor, Info.PPI);
    end;
  finally
    FPainter.EndPaint; // keine Schrift-Handles ueber das Zeichnen hinaus
  end;
end;

{ ---- Maus ---- }

function TPPGCustomItemList.ItemMouseDown(Index: Integer; Shift: TShiftState;
  X, Y: Integer): Boolean;
begin
  Result := False;
end;

procedure TPPGCustomItemList.ContentMouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  I: Integer;
  Changes: Cardinal;
begin
  // CanFocus allein genuegt nicht (unsichtbarer Vorfahr): Fenster pruefen
  if (Button = mbLeft) and CanFocus and not Focused and HandleAllocated and
    IsWindowVisible(Handle) and IsWindowEnabled(Handle) and
    not (csDesigning in ComponentState) then
    SetFocus;
  I := ItemAtPos(X, Y);
  if (Button <> mbLeft) or (I < 0) then
  begin
    // Rechtsklick waehlt wie im Explorer den Eintrag (ohne vorhandene
    // Mehrfachauswahl aufzuheben)
    if (Button = mbRight) and (I >= 0) and CanSelectItem(I) and
      not FSelection.Selected[I] and CanChangeFocusTo(I) then
    begin
      BeginUserAction;
      try
        FSelection.Click(I, []);
      finally
        EndUserAction;
      end;
    end;
    Exit;
  end;
  BeginUserAction;
  try
    Changes := FStructChanges;
    if ItemMouseDown(I, Shift, X, Y) then
      Exit;
    // ItemMouseDown kann Anwender-Code ausgeloest haben (CheckListBox:
    // OnClickCheck), der die Eintraege aendert: I gilt dann nicht mehr
    if (Changes <> FStructChanges) or (I >= ItemCount) then
      Exit;
    if not CanSelectItem(I) then
      Exit;
    if (I <> FSelection.Focus) and not CanChangeFocusTo(I) then
      Exit;
    FSelection.Click(I, Shift);
    FDownIndex := I;
    FDownPos := Point(X, Y);
    FMouseSelecting := (FSelection.Mode = smExtended) and not FAllowReorder;
  finally
    EndUserAction;
  end;
end;

procedure TPPGCustomItemList.ContentMouseMove(Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  I := ItemAtPos(X, Y);
  if (I >= 0) and not CanSelectItem(I) then
    I := -1;
  if I <> FHotIndex then
    SetHotIndex(I);
  if not (ssLeft in Shift) or (FDownIndex < 0) then
    Exit;
  if FAllowReorder and (ListColumns = 0) then
  begin
    if not FDragging and PPGDragExceeded(FDownPos, Point(X, Y)) then
      FDragging := True;
    if FDragging then
      UpdateDrag(X, Y);
  end
  else if FMouseSelecting then
  begin
    // Ziehen erweitert die Auswahl (wie eine Windows-Liste)
    if (I >= 0) and (I <> FSelection.Focus) then
    begin
      BeginUserAction;
      try
        FSelection.MoveTo(I, [ssShift]);
      finally
        EndUserAction;
      end;
    end;
    AutoScrollAt(X, Y);
  end;
end;

procedure TPPGCustomItemList.UpdateDrag(X, Y: Integer);
var
  R: Integer;
  Inside: Boolean;
begin
  R := DropTargetAt(Y, Inside);
  if (R <> FDropRow) or (Inside <> FDropInside) then
  begin
    FDropRow := R;
    FDropInside := Inside;
    Invalidate;
  end;
  AutoScrollAt(X, Y);
end;

procedure TPPGCustomItemList.DoAutoScroll(const P: TPoint);
var
  I: Integer;
begin
  inherited DoAutoScroll(P);
  if FDragging then
    UpdateDrag(P.X, P.Y)
  else if FMouseSelecting then
  begin
    I := ItemAtPos(P.X, EnsureRange(P.Y, ViewRect.Top, ViewRect.Bottom - 1));
    if (I >= 0) and (I <> FSelection.Focus) then
    begin
      BeginUserAction;
      try
        FSelection.MoveTo(I, [ssShift]);
      finally
        EndUserAction;
      end;
    end;
  end;
end;

function TPPGCustomItemList.DropRowAt(Y: Integer): Integer;
var
  V: TRect;
  CY: Int64;
  Row: Integer;
begin
  EnsureLayout;
  V := ViewRect;
  CY := Int64(Y - V.Top) + ScrollY;
  if CY <= 0 then
    Exit(0);
  if CY >= FLayout.TotalHeight64 then
    Exit(FLayout.Count);
  Row := FLayout.RowAt(CY);
  // Obere Haelfte: davor einfuegen, untere: danach
  if CY - FLayout.RowTop(Row) > FLayout.RowHeight(Row) div 2 then
    Result := Row + 1
  else
    Result := Row;
end;

procedure TPPGCustomItemList.ContentMouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  From, Target: Integer;
  Inside: Boolean;
begin
  StopAutoScroll;
  FMouseSelecting := False;
  if FDragging then
  begin
    From := FDownIndex;
    Target := FDropRow;
    Inside := FDropInside;
    CancelDrag;
    if (From >= 0) and (Target >= 0) then
      DoDropAt(From, Target, Inside);
  end;
  FDownIndex := -1;
end;

function TPPGCustomItemList.DoDropAt(FromIndex, TargetRow: Integer; Inside: Boolean): Boolean;
var
  Target: Integer;
  Allow: Boolean;
  Changes: Cardinal;
begin
  Result := False;
  if Inside then
    Exit; // Listen kennen kein "hinein"
  if (FromIndex < 0) or (FromIndex >= ItemCount) or (TargetRow < 0) or (TargetRow > ItemCount) then
    Exit;
  // Einfuegen vor TargetRow -> Endposition des verschobenen Eintrags
  Target := TargetRow;
  if Target > FromIndex then
    Dec(Target);
  if Target = FromIndex then
    Exit;
  Changes := FStructChanges;
  Allow := True;
  if Assigned(FOnReorder) then
    FOnReorder(Self, FromIndex, Target, Allow);
  // OnReorder kann die Eintraege geaendert haben
  if Changes <> FStructChanges then
    Exit;
  if Allow and DoReorder(FromIndex, Target) then
  begin
    Result := True;
    BeginUserAction;
    try
      FSelection.Click(Target, []);
    finally
      EndUserAction;
    end;
    MakeItemVisible(Target, True);
  end;
end;

function TPPGCustomItemList.DropTargetAt(Y: Integer; out Inside: Boolean): Integer;
begin
  Inside := False;
  Result := DropRowAt(Y);
end;

function TPPGCustomItemList.CanChangeFocusTo(Index: Integer): Boolean;
begin
  Result := True;
end;

procedure TPPGCustomItemList.ReplaceSelection(const Rows: array of Integer; AFocus: Integer);
var
  I: Integer;
  Old: Cardinal;
begin
  Old := FSelChanges;
  FSelection.BeginUpdate;
  try
    FSelection.Clear;
    if FSelection.Count <> ItemCount then
      FSelection.Count := ItemCount;
    for I := 0 to High(Rows) do
      if (Rows[I] >= 0) and (Rows[I] < ItemCount) then
        FSelection.Selected[Rows[I]] := True;
    if (AFocus >= -1) and (AFocus < ItemCount) then
      FSelection.Focus := AFocus;
  finally
    FSelection.EndUpdate;
  end;
  // Kein Anwender-Wechsel: zaehlt nicht fuer UserSelectionChanged
  FSelChanges := Old;
end;

procedure TPPGCustomItemList.CancelDrag;
begin
  if FDragging or (FDropRow >= 0) then
  begin
    FDragging := False;
    FDropRow := -1;
    Invalidate;
  end;
  StopAutoScroll;
end;

procedure TPPGCustomItemList.WMLButtonUp(var Message: TWMLButtonUp);
begin
  // TControl.WMLButtonUp gibt die Maus frei (WM_CAPTURECHANGED) VOR MouseUp:
  // das darf das Ziehen nicht abbrechen, MouseUp schliesst es ab
  FInButtonUp := True;
  try
    inherited;
  finally
    FInButtonUp := False;
  end;
end;

procedure TPPGCustomItemList.WMCaptureChanged(var Message: TMessage);
begin
  inherited;
  if (HWND(Message.LParam) <> Handle) and not FInButtonUp then
  begin
    CancelDrag;
    FMouseSelecting := False;
    FDownIndex := -1;
  end;
end;

procedure TPPGCustomItemList.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHotIndex >= 0 then
    SetHotIndex(-1);
end;

procedure TPPGCustomItemList.SetHotIndex(Value: Integer);
var
  R: TRect;
  M: Integer;
begin
  // Nur die Zeilen neu zeichnen (etwas Rand fuer Fokusrahmen und Glow)
  M := PPGScale(4, ScalePPI);
  R := ItemRect(FHotIndex);
  if not IsRectEmpty(R) then
  begin
    InflateRect(R, M, M);
    InvalidateArea(R);
  end;
  FHotIndex := Value;
  R := ItemRect(FHotIndex);
  if not IsRectEmpty(R) then
  begin
    InflateRect(R, M, M);
    InvalidateArea(R);
  end;
end;

procedure TPPGCustomItemList.CMEnter(var Message: TCMEnter);
begin
  inherited;
  // Ohne Fokus-Eintrag bekommt der erste waehlbare den Fokus-Rahmen
  if (FSelection.Focus < 0) and (ItemCount > 0) then
    FSelection.Focus := 0;
  Invalidate;
  if FSelection.Focus >= 0 then
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, FSelection.Focus + 1);
end;

procedure TPPGCustomItemList.CMExit(var Message: TCMExit);
begin
  inherited;
  CancelDrag;
  Invalidate;
end;

function TPPGCustomItemList.DoReorder(FromIndex, ToIndex: Integer): Boolean;
begin
  Result := False;
end;

{ ---- Tastatur ---- }

function TPPGCustomItemList.ItemSpaceKey(Index: Integer): Boolean;
begin
  Result := False;
end;

function TPPGCustomItemList.ItemHorzKey(Index: Integer; Key: Word; Shift: TShiftState): Boolean;
begin
  Result := False;
end;

procedure TPPGCustomItemList.KeyDown(var Key: Word; Shift: TShiftState);
var
  Scroll: Boolean;
begin
  // Audit 7c #1: OnKeyDown zuerst (inherited), dann die eigene Navigation,
  // erst danach das Scrollen per Tastatur der Basis.
  Scroll := KeyboardScrolling;
  KeyboardScrolling := False;
  try
    inherited KeyDown(Key, Shift);
  finally
    KeyboardScrolling := Scroll;
  end;
  // Eine Liste ist keine Schaltflaeche: Leertaste loest kein Click aus
  if KeyPressed then
    SetKeyPressed(False);
  if Key = 0 then
    Exit;
  NavigateKey(Key, Shift);
  if (Key <> 0) and KeyboardScrolling and ScrollKey(Key, Shift) then
    Key := 0;
end;

procedure TPPGCustomItemList.NavigateKey(var Key: Word; Shift: TShiftState);
var
  N, F, T, I, Dir, PageRows, RPC, CW: Integer;
  V: TRect;
  Horz: Boolean;
begin
  Horz := False;
  EnsureLayout;
  N := ItemCount;
  F := FSelection.Focus;
  T := -1;
  V := ViewRect;
  PageRows := (V.Bottom - V.Top) div DefaultItemHeight;
  if PageRows < 1 then
    PageRows := 1;
  case Key of
    VK_UP: T := F - 1;
    VK_DOWN: T := F + 1;
    VK_PRIOR: T := F - PageRows;
    VK_NEXT: T := F + PageRows;
    VK_HOME: T := 0;
    VK_END: T := N - 1;
    VK_LEFT, VK_RIGHT:
      if (F >= 0) and ItemHorzKey(F, Key, Shift) then
      begin
        Key := 0;
        Exit;
      end
      else if MultiColumn(RPC, CW) then
      begin
        // Mehrspaltig: eine Spalte weiter bzw. zurueck
        if Key = VK_LEFT then
          T := Max(0, F - RPC)
        else
          T := Min(N - 1, F + RPC);
        Horz := True;
      end;
    VK_SPACE:
      begin
        if F >= 0 then
        begin
          BeginUserAction;
          try
            if not ItemSpaceKey(F) and (FSelection.Mode <> smSingle) then
              FSelection.ToggleFocused;
          finally
            EndUserAction;
          end;
        end;
        Key := 0;
        Exit;
      end;
    Ord('A'):
      if (ssCtrl in Shift) and (FSelection.Mode <> smSingle) then
      begin
        BeginUserAction;
        try
          FSelection.SelectAll;
        finally
          EndUserAction;
        end;
        Key := 0;
        Exit;
      end;
  end;
  if (T <> -1) or Horz or (Key in [VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT, VK_HOME, VK_END]) then
  begin
    if N = 0 then
    begin
      Key := 0;
      Exit;
    end;
    if F < 0 then
    begin
      // Ohne Fokus: Ende springt ans Ende, alles andere an den Anfang
      if Key = VK_END then
        T := N - 1
      else
        T := 0;
    end;
    if T < 0 then
      T := 0;
    if T > N - 1 then
      T := N - 1;
    // Ueberschriften/nicht waehlbare Eintraege ueberspringen: in Laufrichtung
    // (zurueck bei hoch, Bild hoch, Ende und links), findet sich dort nichts
    // (Rand), in der Gegenrichtung
    if (Key = VK_UP) or (Key = VK_PRIOR) or (Key = VK_END) or (Key = VK_LEFT) then
      Dir := -1
    else
      Dir := 1;
    I := T;
    while (I >= 0) and (I < N) and not CanSelectItem(I) do
      Inc(I, Dir);
    if (I < 0) or (I >= N) then
    begin
      I := T - Dir;
      while (I >= 0) and (I < N) and not CanSelectItem(I) do
        Dec(I, Dir);
    end;
    T := I;
    if (T < 0) or (T >= N) or ((T <> F) and not CanChangeFocusTo(T)) then
    begin
      Key := 0;
      Exit;
    end;
    BeginUserAction;
    try
      FSelection.MoveTo(T, Shift);
    finally
      EndUserAction;
    end;
    MakeItemVisible(T, True);
    Key := 0;
    Exit;
  end;
end;

function TPPGCustomItemList.FindItemByPrefix(const S: string; Start: Integer): Integer;
var
  N, I, J: Integer;
  Data: TPPGItemData;
begin
  Result := -1;
  N := ItemCount;
  if (N = 0) or (S = '') then
    Exit;
  if (Start < 0) or (Start >= N) then
    Start := 0;
  for J := 0 to N - 1 do
  begin
    I := (Start + J) mod N;
    GetItemData(I, Data);
    if not Data.IsHeader and
      SameText(Copy(TPPGItemPainter.PlainText(Data), 1, Length(S)), S) then
      Exit(I);
  end;
end;

procedure TPPGCustomItemList.KeyPress(var Key: Char);
var
  Start, I: Integer;
  S: string;
begin
  inherited KeyPress(Key);
  if not FTypeAhead or (Key < ' ') or (ItemCount = 0) then
    Exit;
  // Tippsuche (TPPGTypeAhead): Puffer verfaellt nach 1 s; derselbe Buchstabe
  // wiederholt blaettert durch die Treffer
  S := FTypeBuf.Add(Key);
  Start := FSelection.Focus;
  if Length(S) = 1 then
    Inc(Start); // neuer Buchstabe: ab dem naechsten suchen
  I := FindItemByPrefix(S, Start);
  if (I >= 0) and CanSelectItem(I) and CanChangeFocusTo(I) then
  begin
    BeginUserAction;
    try
      FSelection.MoveTo(I, []);
    finally
      EndUserAction;
    end;
    MakeItemVisible(I, True);
  end;
  Key := #0;
end;

{ ---- Nachrichten ---- }

procedure TPPGCustomItemList.CMHintShow(var Message: TCMHintShow);
var
  I, Avail, W, PPI: Integer;
  R: TRect;
  D: TPPGItemData;
  S: string;
  F, Temp: TFont;
begin
  inherited;
  // Audit 7f #1: abgeschnittener Eintrag als Hinweis (wie TTreeView.ToolTips;
  // nur ohne eigenen Hint)
  if not FToolTips or (Hint <> '') or (Message.HintInfo = nil) then
    Exit;
  I := ItemAtPos(Message.HintInfo^.CursorPos.X, Message.HintInfo^.CursorPos.Y);
  if I < 0 then
    Exit;
  R := ItemRect(I);
  if IsRectEmpty(R) then
    Exit;
  GetItemData(I, D);
  S := TPPGItemPainter.PlainText(D);
  if S = '' then
    Exit;
  PPI := ScalePPI;
  Temp := nil;
  try
    F := PPGStyledFont(Font, D.FontStyle, Temp);
    W := PPGMeasureTextNoCanvas(S, F, 0, False).cx;
  finally
    Temp.Free;
  end;
  // Platz wie in TPPGItemPainter.PaintItemContent: Einzug, Rand, Bild, Plakette
  Avail := (R.Right - R.Left) - ItemIndent(I, D) - PPGScale(PPGItemPadX + 6, PPI);
  if (Images <> nil) and (D.ImageIndex >= 0) and (D.ImageIndex < Images.Count) then
    Dec(Avail, Images.Width + PPGScale(PPGItemGap, PPI));
  if D.Badge <> '' then
    Dec(Avail, PPGMeasureTextNoCanvas(D.Badge, Font, 0, False).cx +
      PPGScale(PPGItemGap + 12, PPI));
  if W <= Avail then
    Exit;
  Message.HintInfo^.HintStr := S;
  Message.HintInfo^.CursorRect := R;
end;

procedure TPPGCustomItemList.WndProc(var Message: TMessage);
var
  I: Integer;
begin
  if (GMsgLayout <> 0) and (Message.Msg = GMsgLayout) then
  begin
    FLayoutPosted := False;
    EnsureLayout;
    Exit;
  end;
  if (GMsgChildAction <> 0) and (Message.Msg = GMsgChildAction) then
  begin
    // Aus AccChildDoDefault gepostet: Anwender-Code ausserhalb des COM-Aufrufs
    I := Integer(Message.WParam);
    if (I >= 0) and (I < ItemCount) and Enabled then
      DoAccChildAction(I);
    Exit;
  end;
  if (GMsgChildSelect <> 0) and (Message.Msg = GMsgChildSelect) then
  begin
    I := Integer(Message.WParam);
    if (I >= 0) and (I < ItemCount) and Enabled then
      DoAccSelect(I, Integer(Message.LParam));
    Exit;
  end;
  inherited WndProc(Message);
end;

procedure TPPGCustomItemList.DoAccSelect(Index: Integer; Flags: Integer);
begin
  BeginUserAction;
  try
    if Flags and SELFLAG_TAKESELECTION <> 0 then
      FSelection.Click(Index, [])
    else if Flags and SELFLAG_EXTENDSELECTION <> 0 then
      FSelection.Click(Index, [ssShift])
    else if Flags and SELFLAG_ADDSELECTION <> 0 then
      FSelection.Selected[Index] := True
    else if Flags and SELFLAG_REMOVESELECTION <> 0 then
      FSelection.Selected[Index] := False;
    if Flags and SELFLAG_TAKEFOCUS <> 0 then
      FSelection.Focus := Index;
  finally
    EndUserAction;
  end;
end;

procedure TPPGCustomItemList.DoAccChildAction(Index: Integer);
begin
  BeginUserAction;
  try
    FSelection.Click(Index, []);
  finally
    EndUserAction;
  end;
  MakeItemVisible(Index);
end;

{ ---- Barrierefreiheit ---- }

function TPPGCustomItemList.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_LIST;
end;

function TPPGCustomItemList.AccState: Integer;
begin
  Result := inherited AccState;
  case FSelection.Mode of
    smMulti: Result := Result or STATE_SYSTEM_MULTISELECTABLE;
    smExtended: Result := Result or STATE_SYSTEM_MULTISELECTABLE or STATE_SYSTEM_EXTSELECTABLE;
  end;
end;

function TPPGCustomItemList.AccValue: string;
begin
  Result := '';
end;

function TPPGCustomItemList.AccChildCount: Integer;
begin
  Result := ItemCount;
end;

function TPPGCustomItemList.AccChildName(Id: Integer): string;
var
  Data: TPPGItemData;
begin
  GetItemData(Id - 1, Data);
  Result := TPPGItemPainter.PlainText(Data);
  if Data.Detail <> '' then
    Result := Result + ', ' + PPGStripMarkup(Data.Detail);
end;

function TPPGCustomItemList.AccChildRole(Id: Integer): Integer;
var
  Data: TPPGItemData;
begin
  GetItemData(Id - 1, Data);
  if Data.IsHeader then
    Result := ROLE_SYSTEM_STATICTEXT
  else
    Result := ROLE_SYSTEM_LISTITEM;
end;

function TPPGCustomItemList.AccChildState(Id: Integer): Integer;
var
  I: Integer;
  Data: TPPGItemData;
begin
  I := Id - 1;
  GetItemData(I, Data);
  if Data.IsHeader then
    Result := STATE_SYSTEM_READONLY
  else
  begin
    Result := STATE_SYSTEM_SELECTABLE or STATE_SYSTEM_FOCUSABLE;
    if FSelection.Selected[I] then
      Result := Result or STATE_SYSTEM_SELECTED;
    if Focused and (FSelection.Focus = I) then
      Result := Result or STATE_SYSTEM_FOCUSED;
  end;
  if not Data.Enabled or not Enabled then
    Result := Result or STATE_SYSTEM_UNAVAILABLE;
  if IsRectEmpty(ItemRect(I)) then
    Result := Result or STATE_SYSTEM_INVISIBLE or STATE_SYSTEM_OFFSCREEN;
end;

function TPPGCustomItemList.AccChildRect(Id: Integer): TRect;
begin
  Result := ItemRect(Id - 1);
end;

function TPPGCustomItemList.AccChildAt(X, Y: Integer): Integer;
begin
  Result := ItemAtPos(X, Y) + 1;
end;

function TPPGCustomItemList.AccChildDefaultAction(Id: Integer): string;
begin
  Result := PPGStr(@SPPGAccSelect);
end;

procedure TPPGCustomItemList.AccChildDoDefault(Id: Integer);
begin
  if HandleAllocated then
    PostMessage(Handle, GMsgChildAction, WPARAM(Id - 1), 0);
end;

function TPPGCustomItemList.AccFocusedChild: Integer;
begin
  if Focused then
    Result := FSelection.Focus + 1
  else
    Result := 0;
end;

function TPPGCustomItemList.AccSelectedChild: Integer;
begin
  Result := FSelection.ItemIndex + 1;
end;

function TPPGCustomItemList.AccSelectedChildren: TArray<Integer>;
var
  I, N: Integer;
begin
  SetLength(Result, 0);
  if FSelection.Mode = smSingle then
  begin
    if FSelection.ItemIndex >= 0 then
    begin
      SetLength(Result, 1);
      Result[0] := FSelection.ItemIndex + 1;
    end;
    Exit;
  end;
  SetLength(Result, FSelection.SelCount);
  N := 0;
  I := FSelection.NextSelected(0);
  while (I >= 0) and (N < Length(Result)) do
  begin
    Result[N] := I + 1;
    Inc(N);
    I := FSelection.NextSelected(I + 1);
  end;
  SetLength(Result, N);
end;

function TPPGCustomItemList.AccChildSelect(Id: Integer; Flags: Integer): Boolean;
begin
  Result := HandleAllocated and (Id >= 1) and (Id <= ItemCount);
  if Result then
    PostMessage(Handle, GMsgChildSelect, WPARAM(Id - 1), LPARAM(Flags));
end;

{ ---- UI Automation (IPPGUiaSource) ---- }

function TPPGCustomItemList.UiaRowOf(const Id: TPPGUiaId): Integer;
begin
  if (Id.Kind = PPGUiaKindListItem) and (Id.A >= 0) and (Id.A < ItemCount) then
    Result := Id.A
  else
    Result := -1;
end;

function TPPGCustomItemList.UiaIdOfRow(Row: Integer): TPPGUiaId;
begin
  if (Row >= 0) and (Row < ItemCount) then
    Result := PPGUiaId(PPGUiaKindListItem, Row)
  else
    Result := PPGUiaId(0);
end;

function TPPGCustomItemList.UiaValid(const Id: TPPGUiaId): Boolean;
begin
  Result := PPGUiaIsRoot(Id) or (UiaRowOf(Id) >= 0);
end;

function TPPGCustomItemList.UiaParent(const Id: TPPGUiaId): TPPGUiaId;
begin
  Result := PPGUiaId(0);
end;

function TPPGCustomItemList.UiaChildCount(const Id: TPPGUiaId): Integer;
begin
  if PPGUiaIsRoot(Id) then
    Result := ItemCount
  else
    Result := 0;
end;

function TPPGCustomItemList.UiaChild(const Id: TPPGUiaId; Index: Integer): TPPGUiaId;
begin
  if PPGUiaIsRoot(Id) then
    Result := UiaIdOfRow(Index)
  else
    Result := PPGUiaId(0);
end;

function TPPGCustomItemList.UiaIndexInParent(const Id: TPPGUiaId): Integer;
begin
  Result := UiaRowOf(Id);
end;

function TPPGCustomItemList.UiaElementAt(X, Y: Integer): TPPGUiaId;
begin
  Result := UiaIdOfRow(ItemAtPos(X, Y));
end;

function TPPGCustomItemList.UiaFocused: TPPGUiaId;
begin
  if Focused then
    Result := UiaIdOfRow(FSelection.Focus)
  else
    Result := PPGUiaId(0);
end;

function TPPGCustomItemList.UiaFromAccChild(ChildId: Integer): TPPGUiaId;
begin
  Result := UiaIdOfRow(ChildId - 1);
end;

function TPPGCustomItemList.UiaControlType(const Id: TPPGUiaId): Integer;
var
  Data: TPPGItemData;
begin
  if PPGUiaIsRoot(Id) then
    Exit(UIA_ListControlTypeId);
  GetItemData(UiaRowOf(Id), Data);
  if Data.IsHeader then
    Result := UIA_TextControlTypeId
  else
    Result := UIA_ListItemControlTypeId;
end;

function TPPGCustomItemList.UiaName(const Id: TPPGUiaId): string;
var
  R: Integer;
begin
  if PPGUiaIsRoot(Id) then
    Exit(AccName);
  R := UiaRowOf(Id);
  if R < 0 then
    Result := ''
  else
    Result := AccChildName(R + 1);
end;

function TPPGCustomItemList.UiaRect(const Id: TPPGUiaId): TRect;
var
  R: Integer;
begin
  R := UiaRowOf(Id);
  if R < 0 then
    Result := Rect(0, 0, 0, 0)
  else
    Result := ItemRect(R);
end;

function TPPGCustomItemList.UiaEnabled(const Id: TPPGUiaId): Boolean;
var
  Data: TPPGItemData;
begin
  Result := Enabled;
  if Result and not PPGUiaIsRoot(Id) then
  begin
    GetItemData(UiaRowOf(Id), Data);
    Result := Data.Enabled;
  end;
end;

function TPPGCustomItemList.UiaFocusable(const Id: TPPGUiaId): Boolean;
var
  R: Integer;
begin
  if PPGUiaIsRoot(Id) then
    Exit(TabStop and Enabled);
  R := UiaRowOf(Id);
  Result := (R >= 0) and CanSelectItem(R);
end;

function TPPGCustomItemList.UiaProperty(const Id: TPPGUiaId; PropertyId: Integer;
  out Value: OleVariant): Boolean;
var
  R: Integer;
begin
  Result := False;
  R := UiaRowOf(Id);
  if R < 0 then
    Exit;
  case PropertyId of
    UIA_PositionInSetPropertyId:
      begin
        Value := R + 1;
        Result := True;
      end;
    UIA_SizeOfSetPropertyId:
      begin
        Value := ItemCount;
        Result := True;
      end;
  end;
end;

function TPPGCustomItemList.UiaHasPattern(const Id: TPPGUiaId; PatternId: Integer): Boolean;
var
  R: Integer;
begin
  if PPGUiaIsRoot(Id) then
    Exit(PatternId = UIA_SelectionPatternId);
  R := UiaRowOf(Id);
  Result := (R >= 0) and CanSelectItem(R) and
    ((PatternId = UIA_SelectionItemPatternId) or (PatternId = UIA_ScrollItemPatternId));
end;

function TPPGCustomItemList.UiaCanSelectMultiple: Boolean;
begin
  Result := FSelection.Mode <> smSingle;
end;

function TPPGCustomItemList.UiaSelection: TPPGUiaIds;
var
  Rows: TArray<Integer>;
  I: Integer;
begin
  Rows := AccSelectedChildren;
  SetLength(Result, Length(Rows));
  for I := 0 to High(Rows) do
    Result[I] := UiaIdOfRow(Rows[I] - 1);
end;

function TPPGCustomItemList.UiaIsSelected(const Id: TPPGUiaId): Boolean;
var
  R: Integer;
begin
  R := UiaRowOf(Id);
  if R < 0 then
    Result := False
  else if FSelection.Mode = smSingle then
    Result := FSelection.ItemIndex = R
  else
    Result := FSelection.Selected[R];
end;

procedure TPPGCustomItemList.UiaGridSize(out Rows, Cols: Integer);
begin
  Rows := 0;
  Cols := 0;
end;

function TPPGCustomItemList.UiaGridItem(Row, Col: Integer): TPPGUiaId;
begin
  Result := PPGUiaId(0);
end;

procedure TPPGCustomItemList.UiaGridPos(const Id: TPPGUiaId; out Row, Col: Integer);
begin
  Row := 0;
  Col := 0;
end;

function TPPGCustomItemList.UiaHeaders(Columns: Boolean): TPPGUiaIds;
begin
  SetLength(Result, 0);
end;

function TPPGCustomItemList.UiaItemHeaders(const Id: TPPGUiaId; Columns: Boolean): TPPGUiaIds;
begin
  SetLength(Result, 0);
end;

function TPPGCustomItemList.UiaValue(const Id: TPPGUiaId): string;
begin
  Result := '';
end;

function TPPGCustomItemList.UiaReadOnly(const Id: TPPGUiaId): Boolean;
begin
  Result := True;
end;

function TPPGCustomItemList.UiaExpandState(const Id: TPPGUiaId): Integer;
begin
  Result := ExpandCollapseState_LeafNode;
end;

function TPPGCustomItemList.UiaToggleState(const Id: TPPGUiaId): Integer;
var
  Data: TPPGItemData;
begin
  GetItemData(UiaRowOf(Id), Data);
  case Data.Checked of
    cbChecked: Result := ToggleState_On;
    cbGrayed: Result := ToggleState_Indeterminate;
  else
    Result := ToggleState_Off;
  end;
end;

procedure TPPGCustomItemList.UiaExecute(const Id: TPPGUiaId; Action: TPPGUiaAction;
  const Value: string);
var
  R: Integer;
begin
  if not Enabled then
    Exit;
  R := UiaRowOf(Id);
  case Action of
    uaSetFocus:
      begin
        if CanFocus and not Focused then
          SetFocus;
        if R >= 0 then
          DoAccSelect(R, SELFLAG_TAKEFOCUS);
      end;
    uaSelect:
      if R >= 0 then
      begin
        DoAccSelect(R, SELFLAG_TAKESELECTION or SELFLAG_TAKEFOCUS);
        MakeItemVisible(R);
      end;
    uaAddToSelection:
      if R >= 0 then
      begin
        if FSelection.Mode = smSingle then
          DoAccSelect(R, SELFLAG_TAKESELECTION)
        else
          DoAccSelect(R, SELFLAG_ADDSELECTION);
      end;
    uaRemoveFromSelection:
      if (R >= 0) and (FSelection.Mode <> smSingle) then
        DoAccSelect(R, SELFLAG_REMOVESELECTION);
    uaScrollIntoView:
      if R >= 0 then
        MakeItemVisible(R);
    uaInvoke, uaToggle:
      if R >= 0 then
        DoAccChildAction(R);
  end;
end;

end.
