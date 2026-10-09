unit PPG.Popup;

{ Aufklapp-Fenster der Suite (ComboBox-Liste, spaeter z.B. DatePicker).

  TPPGPopupWindow - Fenster ohne Aktivierung:
  - WS_POPUP + WS_EX_TOOLWINDOW, Besitzer ist das Formular des Ausloesers.
    Kein Parent: das Fenster liegt ueber allem und wird nicht abgeschnitten.
  - Wird mit SWP_NOACTIVATE gezeigt, WM_MOUSEACTIVATE = MA_NOACTIVATE:
    Fokus und Titelleiste des Formulars bleiben beim Ausloeser.
  - Maus und Tastatur bedient der AUSLOESER (er haelt die Maus per SetCapture
    und gibt Mausaktionen mit Popup-Koordinaten weiter). So erkennt er Klicks
    ausserhalb, Fokus- und Capture-Verlust und schliesst das Popup.
  - Platzierung unter dem Anker, sonst darueber, wenn oben mehr Platz ist
    (Arbeitsflaeche des Monitors); Aufklappen als Hoehen-Animation.

  TPPGPopupList - Liste im Popup:
  - zeichnet nur sichtbare Zeilen, schmale eigene Scrollleiste (ziehbar)
  - Hervorhebung folgt Maus und Tastatur, der aktuelle Wert ist markiert
  - Barrierefreiheit: Rolle LIST mit virtuellen LISTITEM-Kindern }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms,
  Vcl.ImgList, PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Accessibility,
  PPG.Controls.Base, PPG.Items, PPG.ItemPainter, PPG.Popup.Placement, PPG.CustomDraw;

type
  TPPGPopupItemEvent = procedure(Sender: TObject; Index: Integer) of object;

  /// Ausloeser einer Liste mit Stilen/eigenem Zeichnen (z.B. ComboBox).
  IPPGListStylesSource = interface
    ['{5C2B8E41-7D93-4A06-B1F7-3E8D20C964A5}']
    function GetListStyles: TPPGListStyles;
    function GetCustomDrawItem: TPPGCustomDrawItemEvent;
  end;

  TPPGPopupWindow = class(TPPGCustomControl)
  private
    FPPI: Integer;
    FOpen: Boolean;
    FOpenedAbove: Boolean;
    FFullRect: TRect;  // Zielgroesse in Bildschirmkoordinaten
    FDropAnim: TPPGAnimation;
    FSource: TPPGCustomControl;
    procedure DropAnimStep(Sender: TObject);
    procedure ApplyBounds(Progress: Single);
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    function GetFullHeight: Integer;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Resize; override;
    /// Rundung des Popups (fuer die Fensterregion), 0 = eckig.
    function PopupRounding: Integer; virtual;
    /// Fensterregion (Standard: abgerundetes Rechteck nach PopupRounding).
    procedure ApplyRegion; virtual;
    /// Versatz des Inhalts waehrend des Aufklappens (oberhalb: von unten her).
    function ContentOffset: Integer;
    property FullHeight: Integer read GetFullHeight;
    /// Farben eines Popups (Liste, Menue): Fill/Text = Flaeche und Schrift,
    /// dazu Hochkontrast und VCL-Style. HighlightStyle = hervorgehobener Eintrag.
    procedure GetPopupStyles(Fill, Text: TColor; out ListStyle, HighlightStyle: TPPGSurfaceStyle);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ScalePPI: Integer; override;
    /// Optik, Schrift und DPI vom Ausloeser uebernehmen (vor Popup aufrufen).
    procedure SyncFrom(Source: TPPGCustomControl); virtual;
    /// Zeigt das Popup am Anker (Bildschirmkoordinaten, z.B. das Feld).
    /// DurationMs = 0: ohne Animation.
    procedure Popup(const Anchor: TRect; AWidth, AHeight: Integer;
      AlignRight: Boolean; DurationMs: Cardinal);
    /// Zeigt das Popup im fertig platzierten Rechteck (PPG.Popup.Placement).
    /// Side = ppsAbove klappt von unten nach oben auf.
    procedure PopupAt(const Bounds: TRect; Side: TPPGPopupSide; DurationMs: Cardinal);
    /// Arbeitsflaeche des Monitors zu R (Bildschirmkoordinaten).
    function MonitorWorkArea(const R: TRect): TRect;
    /// Blendet das Popup aus (ohne Ereignisse - die loest der Ausloeser aus).
    procedure ClosePopup;
    function IsOpen: Boolean;
    property OpenedAbove: Boolean read FOpenedAbove;
    /// Der Ausloeser (fuer Name und Barrierefreiheit).
    property Source: TPPGCustomControl read FSource;
    /// PPI fuer das Zeichnen ohne PPGlow-Ausloeser (0 = aus dem Fenster).
    property PopupPPI: Integer read FPPI write FPPI;
  end;

  /// Antwort des Popups auf Maus oder Taste.
  TPPGDropAction = (pdaNone, pdaKeepOpen, pdaAccept, pdaCancel);

  /// Popup eines Felds mit Aufklapp-Fenster (TPPGCustomDropDownField):
  /// das Feld reicht Maus und Tastatur in Popup-Koordinaten weiter.
  TPPGDropPopup = class(TPPGPopupWindow)
  public
    /// Groesse fuer ein Feld der Breite FieldWidth (physische px).
    function PreferredSize(FieldWidth: Integer): TSize; virtual;
    procedure DropMouseMove(X, Y: Integer; Shift: TShiftState); virtual;
    function DropMouseDown(X, Y: Integer): TPPGDropAction; virtual;
    function DropMouseUp(X, Y: Integer): TPPGDropAction; virtual;
    function DropKeyDown(var Key: Word; Shift: TShiftState): TPPGDropAction; virtual;
    function DropKeyPress(var Key: Char): TPPGDropAction; virtual;
    procedure DropWheel(Delta: Integer); virtual;
    /// Maus hat das Popup verlassen (Hervorhebung zuruecksetzen).
    procedure DropMouseLeave; virtual;
  end;

  TPPGPopupList = class(TPPGDropPopup, IPPGAccessibleChildren)
  private
    FItems: TStrings;
    FSource: IPPGItemSource;
    FMap: TArray<Integer>;   // Filter: Zeile -> Eintrag
    FFiltered: Boolean;
    FTwoLineItems: Boolean;
    FPainter: TPPGItemPainter;
    FItemIndex: Integer;
    FDropDownCount: Integer;
    FDropDownWidth: Integer;
    FHighlight: Integer;
    FTopIndex: Integer;
    FMinItemHeight: Integer;
    FListColor: TColor;
    FTextColor: TColor;
    FScrollHot: Boolean;
    FThumbDrag: Boolean;
    FDragOffset: Integer;
    FPressedItem: Integer;
    FListName: string;
    FOnItemClick: TPPGPopupItemEvent;
    FListStyles: TPPGListStyles;     // gehoert dem Ausloeser
    FOnCustomDrawItem: TPPGCustomDrawItemEvent;
    FDrawCanvas: TCanvas;
    FStyleSource: TObject;
    procedure SetItemIndex(Value: Integer);
    procedure SetTopIndex(Value: Integer);
    procedure SetListColor(const Value: TColor);
    function Inset: Integer;
    function ScrollBarWidth: Integer;
    function NeedScrollBar: Boolean;
    function TrackRect: TRect;
    function ThumbRect: TRect;
    function ItemTotal: Integer;
    procedure GetRowData(Item: Integer; var Data: TPPGItemData);
    procedure GetStyles(out ListStyle, HighlightStyle: TPPGSurfaceStyle);
    procedure PaintRowBackground(const ACanvas: IPPGCanvas; const LR: IPPGListRenderer;
      const R: TRect; const L, H: TPPGSurfaceStyle; const Info: TPPGItemPaintInfo;
      const Data: TPPGItemData; Row: Integer; Selected: Boolean; Hl: Single);
  protected
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure WndProc(var Message: TMessage); override;
    function PopupRounding: Integer; override;
    function AccName: string; override;
    function AccRole: Integer; override;
    function AccState: Integer; override;
    function AccDefaultAction: string; override;
    procedure AccDoDefaultAction; override;
    { IPPGAccessibleChildren - Kinder sind die Zeilen (bei Filter nur die Treffer) }
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
    procedure SyncFrom(Source: TPPGCustomControl); override;
    /// Hoechstens DropDownCount Zeilen, mindestens DropDownWidth breit.
    function PreferredSize(FieldWidth: Integer): TSize; override;
    procedure DropMouseMove(X, Y: Integer; Shift: TShiftState); override;
    function DropMouseDown(X, Y: Integer): TPPGDropAction; override;
    /// Loslassen ueber einem Eintrag: hervorheben und uebernehmen.
    function DropMouseUp(X, Y: Integer): TPPGDropAction; override;
    /// Pfeile, Bild auf/ab, Pos1/Ende bewegen die Hervorhebung, Enter uebernimmt.
    function DropKeyDown(var Key: Word; Shift: TShiftState): TPPGDropAction; override;
    procedure DropWheel(Delta: Integer); override;
    procedure DropMouseLeave; override;
    /// Hoehe einer Zeile in Pixeln (Schrift + Abstand, mindestens MinItemHeight).
    function ItemHeight: Integer;
    /// Benoetigte Fensterhoehe fuer Rows Zeilen.
    function HeightForRows(Rows: Integer): Integer;
    /// Zeilen, die in die aktuelle Hoehe passen.
    function VisibleRows: Integer;
    /// Anzahl der Zeilen (bei Filter nur die Treffer).
    function RowCount: Integer;
    /// Eintrag einer Zeile bzw. Zeile eines Eintrags (-1 = nicht in der Liste).
    function ItemOfRow(Row: Integer): Integer;
    function RowOfItem(Item: Integer): Integer;
    /// Nur diese Eintraege zeigen (in dieser Reihenfolge); ClearFilter = alle.
    procedure SetFilter(const Items: TArray<Integer>);
    procedure ClearFilter;
    function ItemRect(Index: Integer): TRect;
    /// Eintrag unter dem Punkt (Client-Koordinaten), -1 = keiner.
    function ItemAtPos(X, Y: Integer): Integer;
    procedure MakeVisible(Index: Integer);
    /// Hervorhebung setzen (mit Meldung an Screenreader), -1 = keine.
    procedure SetHighlight(Index: Integer);
    /// Hervorhebung um Delta Zeilen verschieben.
    procedure MoveHighlight(Delta: Integer);
    procedure ScrollLines(Delta: Integer);
    { Mausaktionen des Ausloesers (Client-Koordinaten des Popups) }
    procedure MouseDownAt(X, Y: Integer);
    procedure MouseMoveAt(X, Y: Integer);
    /// Liefert den Eintrag, auf dem losgelassen wurde (-1 = keiner/Scrollleiste).
    function MouseUpAt(X, Y: Integer): Integer;
    /// Texte der Eintraege (Index = Eintrag).
    property Items: TStrings read FItems write FItems;
    /// Optional: reiche Eintraege (Bild, Detail, Plakette) - gleiche Indizes wie Items.
    property Source: IPPGItemSource read FSource write FSource;
    /// Zweizeilige Eintraege (Detailzeile).
    property TwoLineItems: Boolean read FTwoLineItems write FTwoLineItems;
    property Filtered: Boolean read FFiltered;
    property ItemIndex: Integer read FItemIndex write SetItemIndex;
    property Highlight: Integer read FHighlight;
    /// Erste sichtbare Zeile.
    property TopIndex: Integer read FTopIndex write SetTopIndex;
    /// Mindesthoehe einer Zeile in logischen px (0 = nur Schrift).
    property MinItemHeight: Integer read FMinItemHeight write FMinItemHeight;
    property ListColor: TColor read FListColor write SetListColor;
    property TextColor: TColor read FTextColor write FTextColor;
    property ListName: string read FListName write FListName;
    property ThumbDragging: Boolean read FThumbDrag;
    /// Standardaktion eines Eintrags (Screenreader), asynchron ausgeloest.
    property OnItemClick: TPPGPopupItemEvent read FOnItemClick write FOnItemClick;
    /// Zeilen fuer PreferredSize (wie TComboBox.DropDownCount).
    property DropDownCount: Integer read FDropDownCount write FDropDownCount;
    /// Mindestbreite fuer PreferredSize (0 = Feldbreite).
    property DropDownWidth: Integer read FDropDownWidth write FDropDownWidth;
  end;

implementation

uses
  PPG.Lang,
  System.SysUtils, Winapi.oleacc,
  PPG.Consts, PPG.Appearance, PPG.DpiUtils, PPG.VclStyles,
  PPG.Render.Registry, PPG.Render.Gdi;

type
  TSourceAccess = class(TPPGCustomControl);

var
  GMsgItemAction: Cardinal = 0;

const
  ItemPadY = 5;      // logische px ueber/unter dem Text einer Zeile
  ItemPadX = 12;     // logische px links (Platz fuer den Akzentbalken)
  ListPadY = 3;      // logische px zwischen Rahmen und erster Zeile
  ScrollWidth = 6;   // logische px der Scrollleiste
  MinThumb = 16;     // logische px Mindesthoehe des Scroll-Daumens

{ TPPGPopupWindow }

constructor TPPGPopupWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csOpaque, csNoDesignVisible, csCaptureMouse];
  ParentBackground := False;
  Visible := False;
  FDropAnim := TPPGAnimation.Create(Self);
  FDropAnim.OnStep := DropAnimStep;
end;

destructor TPPGPopupWindow.Destroy;
begin
  if FDropAnim <> nil then
    FDropAnim.OnStep := nil;
  FreeAndNil(FDropAnim); // meldet sich selbst beim Animator ab
  FSource := nil;
  inherited Destroy;
end;

procedure TPPGPopupWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP or WS_CLIPCHILDREN;
  Params.ExStyle := WS_EX_TOOLWINDOW;
  // Schatten des Systems (beachtet die Einstellung "Schatten unter Fenstern")
  Params.WindowClass.style := Params.WindowClass.style or CS_DROPSHADOW or CS_SAVEBITS;
  if (FSource <> nil) and FSource.HandleAllocated then
    Params.WndParent := GetAncestor(FSource.Handle, GA_ROOT)
  else if Application.MainFormOnTaskBar and (Application.MainForm <> nil) and
    Application.MainForm.HandleAllocated then
    Params.WndParent := Application.MainForm.Handle
  else
    Params.WndParent := Application.Handle;
end;

function TPPGPopupWindow.ScalePPI: Integer;
begin
  if FPPI > 0 then
    Result := FPPI
  else
    Result := inherited ScalePPI;
end;

procedure TPPGPopupWindow.SyncFrom(Source: TPPGCustomControl);
var
  S: TSourceAccess;
begin
  FSource := Source;
  if Source = nil then
    Exit;
  S := TSourceAccess(Source);
  FPPI := S.ScalePPI;
  BeginUpdate;
  try
    Preset := S.Preset;
    Appearance.Assign(S.Appearance);
    Animation.Assign(S.Animation);
    HighContrastSupport := S.HighContrastSupport;
{$IFDEF PPG_HAS_STYLEELEMENTS}
    StyleElements := S.StyleElements;
{$ENDIF}
    BiDiMode := S.BiDiMode;
    Images := S.Images; // Bilder reicher Eintraege
    // Schrift in Pixeln uebernehmen: das Popup zeichnet in der PPI des Ausloesers
    Font.Assign(S.Font);
  finally
    EndUpdate;
  end;
end;

function TPPGPopupWindow.PopupRounding: Integer;
begin
  Result := 0;
end;

function TPPGPopupWindow.GetFullHeight: Integer;
begin
  Result := FFullRect.Bottom - FFullRect.Top;
end;

function TPPGPopupWindow.ContentOffset: Integer;
begin
  // Oberhalb geoeffnet: der untere Teil erscheint zuerst (rollt nach oben auf)
  if FOpenedAbove then
    Result := Height - FullHeight
  else
    Result := 0;
end;

procedure TPPGPopupWindow.Popup(const Anchor: TRect; AWidth, AHeight: Integer;
  AlignRight: Boolean; DurationMs: Cardinal);
var
  Pl: TPPGPlacement;
begin
  // Liste unter dem Feld, sonst darueber (Hoehe auf den Platz gekuerzt)
  Pl := PPGPlacePopup(Anchor, AWidth, AHeight, ppsBelow, MonitorWorkArea(Anchor),
    AlignRight, True);
  PopupAt(Pl.Bounds, Pl.Side, DurationMs);
end;

function TPPGPopupWindow.MonitorWorkArea(const R: TRect): TRect;
var
  Mon: TMonitor;
begin
  Mon := Screen.MonitorFromRect(R, mdNearest);
  if Mon <> nil then
    Result := Mon.WorkareaRect
  else
    Result := Screen.WorkAreaRect;
end;

procedure TPPGPopupWindow.PopupAt(const Bounds: TRect; Side: TPPGPopupSide;
  DurationMs: Cardinal);
begin
  FFullRect := Bounds;
  FOpenedAbove := Side = ppsAbove;
  HandleNeeded;
  // Besitzer = Formular des Ausloesers: Popup liegt immer ueber ihm
  if (FSource <> nil) and FSource.HandleAllocated then
    SetWindowLongPtr(Handle, GWLP_HWNDPARENT, LONG_PTR(GetAncestor(FSource.Handle, GA_ROOT)));
  FOpen := True;
  if (DurationMs > 0) and not (csDesigning in ComponentState) then
  begin
    FDropAnim.Jump(0.15);
    ApplyBounds(FDropAnim.Value);
    FDropAnim.AnimateTo(1, DurationMs, ekDecelerate);
  end
  else
  begin
    FDropAnim.Jump(1);
    ApplyBounds(1);
  end;
  NotifyAccessibility(EVENT_OBJECT_SHOW);
end;

procedure TPPGPopupWindow.ApplyBounds(Progress: Single);
var
  H, Y, Flags: Integer;
  After: HWND;
begin
  if not HandleAllocated then
    Exit;
  H := Round((FFullRect.Bottom - FFullRect.Top) * PPGClampSingle(Progress, 0, 1));
  if H < 1 then
    H := 1;
  if FOpenedAbove then
    Y := FFullRect.Bottom - H
  else
    Y := FFullRect.Top;
  // Topmost-Formular: das Popup muss ebenfalls topmost sein
  After := HWND_TOP;
  if (FSource <> nil) and FSource.HandleAllocated and
    (GetWindowLong(GetAncestor(FSource.Handle, GA_ROOT), GWL_EXSTYLE) and WS_EX_TOPMOST <> 0) then
    After := HWND_TOPMOST;
  Flags := SWP_NOACTIVATE or SWP_SHOWWINDOW;
  SetWindowPos(Handle, After, FFullRect.Left, Y, FFullRect.Right - FFullRect.Left, H, Flags);
  Invalidate;
end;

procedure TPPGPopupWindow.DropAnimStep(Sender: TObject);
begin
  if FOpen then
    ApplyBounds(FDropAnim.Value);
end;

procedure TPPGPopupWindow.ClosePopup;
begin
  if not FOpen then
    Exit;
  FOpen := False;
  FDropAnim.Jump(0);
  if HandleAllocated then
  begin
    NotifyAccessibility(EVENT_OBJECT_HIDE);
    ShowWindow(Handle, SW_HIDE);
  end;
end;

function TPPGPopupWindow.IsOpen: Boolean;
begin
  Result := FOpen;
end;

procedure TPPGPopupWindow.Resize;
begin
  inherited Resize;
  ApplyRegion;
end;

procedure TPPGPopupWindow.ApplyRegion;
var
  R: Integer;
  Rgn: HRGN;
begin
  if not HandleAllocated then
    Exit;
  R := PopupRounding;
  if R <= 0 then
  begin
    SetWindowRgn(Handle, 0, True);
    Exit;
  end;
  // Abgerundete Ecken auch fuer das Fenster selbst (sonst stehen Ecken ueber)
  Rgn := CreateRoundRectRgn(0, 0, Width + 1, Height + 1, 2 * R, 2 * R);
  if Rgn <> 0 then
    if SetWindowRgn(Handle, Rgn, True) = 0 then
      DeleteObject(Rgn); // nur bei Fehler gehoert die Region noch uns
end;

procedure TPPGPopupWindow.WMMouseActivate(var Message: TWMMouseActivate);
begin
  Message.Result := MA_NOACTIVATE;
end;

procedure TPPGPopupWindow.WMNCHitTest(var Message: TWMNCHitTest);
begin
  Message.Result := HTCLIENT;
end;

{ TPPGPopupList }

constructor TPPGPopupList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDropDownCount := 8;
  FItemIndex := -1;
  FHighlight := -1;
  FPressedItem := -1;
  FListColor := clWindow;
  FTextColor := clWindowText;
  FPainter := TPPGItemPainter.Create;
  FDrawCanvas := TCanvas.Create;
  if GMsgItemAction = 0 then
    GMsgItemAction := RegisterWindowMessage('PPGlow.PopupItemAction');
end;

destructor TPPGPopupList.Destroy;
begin
  FSource := nil;
  FreeAndNil(FPainter);
  FreeAndNil(FDrawCanvas);
  inherited Destroy;
end;

procedure TPPGPopupList.SyncFrom(Source: TPPGCustomControl);
var
  LS: IPPGListStylesSource;
begin
  inherited SyncFrom(Source);
  // Stile und eigenes Zeichnen des Ausloesers (nur waehrend die Liste offen ist)
  FListStyles := nil;
  FOnCustomDrawItem := nil;
  if Supports(Source, IPPGListStylesSource, LS) then
  begin
    FListStyles := LS.GetListStyles;
    FOnCustomDrawItem := LS.GetCustomDrawItem;
    FStyleSource := Source;
  end;
  FScrollHot := False;
  FThumbDrag := False;
  FPressedItem := -1;
end;

function TPPGPopupList.PopupRounding: Integer;
var
  L, H: TPPGSurfaceStyle;
begin
  GetStyles(L, H);
  Result := L.Rounding;
end;

function TPPGPopupList.Inset: Integer;
var
  PPI: Integer;
begin
  PPI := ScalePPI;
  Result := PPGScale(1, PPI) + PPGScale(ListPadY, PPI);
end;

function TPPGPopupList.ScrollBarWidth: Integer;
begin
  Result := PPGScale(ScrollWidth, ScalePPI);
end;

function TPPGPopupList.ItemTotal: Integer;
begin
  if FItems = nil then
    Result := 0
  else
    Result := FItems.Count;
end;

function TPPGPopupList.RowCount: Integer;
begin
  if FFiltered then
    Result := Length(FMap)
  else
    Result := ItemTotal;
end;

function TPPGPopupList.ItemOfRow(Row: Integer): Integer;
begin
  if (Row < 0) or (Row >= RowCount) then
    Result := -1
  else if FFiltered then
    Result := FMap[Row]
  else
    Result := Row;
end;

function TPPGPopupList.RowOfItem(Item: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  if (Item < 0) or (Item >= ItemTotal) then
    Exit;
  if not FFiltered then
    Exit(Item);
  for I := 0 to High(FMap) do
    if FMap[I] = Item then
      Exit(I);
end;

procedure TPPGPopupList.SetFilter(const Items: TArray<Integer>);
var
  I, N, Total: Integer;
begin
  Total := ItemTotal;
  SetLength(FMap, Length(Items));
  N := 0;
  for I := 0 to High(Items) do
    if (Items[I] >= 0) and (Items[I] < Total) then
    begin
      FMap[N] := Items[I];
      Inc(N);
    end;
  SetLength(FMap, N);
  FFiltered := True;
  FTopIndex := 0;
  if RowOfItem(FHighlight) < 0 then
    FHighlight := -1;
  Invalidate;
  if FOpen then
    NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

procedure TPPGPopupList.ClearFilter;
begin
  if not FFiltered then
    Exit;
  FFiltered := False;
  SetLength(FMap, 0);
  SetTopIndex(FTopIndex);
  Invalidate;
  if FOpen then
    NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

procedure TPPGPopupList.GetRowData(Item: Integer; var Data: TPPGItemData);
begin
  PPGInitItemData(Data);
  if (FSource <> nil) and (Item >= 0) and (Item < FSource.Count) then
    FSource.GetItem(Item, Data)
  else if (FItems <> nil) and (Item >= 0) and (Item < FItems.Count) then
    Data.Text := FItems[Item];
end;

function TPPGPopupList.ItemHeight: Integer;
var
  PPI, Min: Integer;
  Img: TCustomImageList;
begin
  PPI := ScalePPI;
  // Bilder nur mit reichen Eintraegen (Source); sonst Hoehe wie bisher
  Img := nil;
  if FSource <> nil then
    Img := Images;
  Result := TPPGItemPainter.RowHeight(Font, Img, FTwoLineItems, PPI);
  Min := PPGScale(FMinItemHeight, PPI);
  if Result < Min then
    Result := Min;
  if Result < 1 then
    Result := 1;
end;

function TPPGPopupList.HeightForRows(Rows: Integer): Integer;
begin
  if Rows < 1 then
    Rows := 1;
  Result := Rows * ItemHeight + 2 * Inset;
end;

function TPPGPopupList.VisibleRows: Integer;
var
  H: Integer;
begin
  H := FullHeight;
  if H <= 0 then
    H := Height;
  Result := (H - 2 * Inset) div ItemHeight;
  if Result < 1 then
    Result := 1;
end;

function TPPGPopupList.NeedScrollBar: Boolean;
begin
  Result := RowCount > VisibleRows;
end;

procedure TPPGPopupList.SetTopIndex(Value: Integer);
var
  MaxTop: Integer;
begin
  MaxTop := RowCount - VisibleRows;
  if Value > MaxTop then
    Value := MaxTop;
  if Value < 0 then
    Value := 0;
  if FTopIndex <> Value then
  begin
    FTopIndex := Value;
    Invalidate;
  end;
end;

procedure TPPGPopupList.SetListColor(const Value: TColor);
begin
  FListColor := Value;
  Color := Value; // Hintergrund ausserhalb der Rundung (vor der Region)
end;

procedure TPPGPopupList.SetItemIndex(Value: Integer);
begin
  if FItemIndex <> Value then
  begin
    FItemIndex := Value;
    Invalidate;
  end;
end;

function TPPGPopupList.ItemRect(Index: Integer): TRect;
var
  Row, IH, Top, Right: Integer;
begin
  Result := Rect(0, 0, 0, 0);
  Row := RowOfItem(Index);
  if (Row < FTopIndex) then
    Exit;
  Row := Row - FTopIndex;
  if Row >= VisibleRows then
    Exit;
  IH := ItemHeight;
  Top := Inset + Row * IH + ContentOffset;
  Right := Width - PPGScale(1, ScalePPI);
  if NeedScrollBar then
    Dec(Right, ScrollBarWidth + PPGScale(2, ScalePPI));
  Result := Rect(PPGScale(1, ScalePPI), Top, Right, Top + IH);
  if UseRightToLeftAlignment then
    Result := Rect(Width - Result.Right, Result.Top, Width - Result.Left, Result.Bottom);
end;

function TPPGPopupList.ItemAtPos(X, Y: Integer): Integer;
var
  Row, Last, I: Integer;
begin
  Result := -1;
  Last := FTopIndex + VisibleRows - 1;
  if Last > RowCount - 1 then
    Last := RowCount - 1;
  for Row := FTopIndex to Last do
  begin
    I := ItemOfRow(Row);
    if PtInRect(ItemRect(I), Point(X, Y)) then
      Exit(I);
  end;
end;

function TPPGPopupList.TrackRect: TRect;
var
  PPI, W: Integer;
begin
  if not NeedScrollBar then
    Exit(Rect(0, 0, 0, 0));
  PPI := ScalePPI;
  W := ScrollBarWidth;
  Result := Rect(Width - PPGScale(2, PPI) - W, Inset + ContentOffset,
    Width - PPGScale(2, PPI), FullHeight - Inset + ContentOffset);
  if UseRightToLeftAlignment then
    Result := Rect(Width - Result.Right, Result.Top, Width - Result.Left, Result.Bottom);
end;

function TPPGPopupList.ThumbRect: TRect;
var
  T: TRect;
  TrackH, ThumbH, MaxTop, Pos, N: Integer;
begin
  T := TrackRect;
  if IsRectEmpty(T) then
    Exit(T);
  N := RowCount;
  TrackH := T.Bottom - T.Top;
  ThumbH := MulDiv(TrackH, VisibleRows, N);
  if ThumbH < PPGScale(MinThumb, ScalePPI) then
    ThumbH := PPGScale(MinThumb, ScalePPI);
  if ThumbH > TrackH then
    ThumbH := TrackH;
  MaxTop := N - VisibleRows;
  if MaxTop > 0 then
    Pos := MulDiv(TrackH - ThumbH, FTopIndex, MaxTop)
  else
    Pos := 0;
  Result := Rect(T.Left, T.Top + Pos, T.Right, T.Top + Pos + ThumbH);
end;

procedure TPPGPopupList.MakeVisible(Index: Integer);
var
  Row: Integer;
begin
  Row := RowOfItem(Index);
  if Row < 0 then
    Exit;
  if Row < FTopIndex then
    SetTopIndex(Row)
  else if Row >= FTopIndex + VisibleRows then
    SetTopIndex(Row - VisibleRows + 1);
end;

procedure TPPGPopupList.SetHighlight(Index: Integer);
var
  Row: Integer;
begin
  Row := RowOfItem(Index);
  if Row < 0 then
    Index := -1;
  if FHighlight = Index then
    Exit;
  FHighlight := Index;
  MakeVisible(Index);
  Invalidate;
  if (Index >= 0) and FOpen then
  begin
    // Wie die Liste einer Windows-ComboBox: der Screenreader liest den Eintrag
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, Row + 1);
    NotifyAccessibilityChild(EVENT_OBJECT_SELECTION, Row + 1);
  end;
end;

procedure TPPGPopupList.MoveHighlight(Delta: Integer);
var
  R, N: Integer;
begin
  N := RowCount;
  if N = 0 then
    Exit;
  R := RowOfItem(FHighlight);
  if R < 0 then
  begin
    if Delta > 0 then
      R := 0
    else
      R := N - 1;
  end
  else
    R := R + Delta;
  if R < 0 then
    R := 0;
  if R > N - 1 then
    R := N - 1;
  SetHighlight(ItemOfRow(R));
end;

{ TPPGDropPopup }

function TPPGDropPopup.PreferredSize(FieldWidth: Integer): TSize;
begin
  Result.cx := FieldWidth;
  Result.cy := 200;
end;

procedure TPPGDropPopup.DropMouseMove(X, Y: Integer; Shift: TShiftState);
begin
end;

function TPPGDropPopup.DropMouseDown(X, Y: Integer): TPPGDropAction;
begin
  Result := pdaNone;
end;

function TPPGDropPopup.DropMouseUp(X, Y: Integer): TPPGDropAction;
begin
  Result := pdaNone;
end;

function TPPGDropPopup.DropKeyDown(var Key: Word; Shift: TShiftState): TPPGDropAction;
begin
  Result := pdaNone;
end;

function TPPGDropPopup.DropKeyPress(var Key: Char): TPPGDropAction;
begin
  Result := pdaNone;
end;

procedure TPPGDropPopup.DropWheel(Delta: Integer);
begin
end;

procedure TPPGDropPopup.DropMouseLeave;
begin
end;

{ TPPGPopupList: Bedienung als Popup eines Aufklapp-Felds }

function TPPGPopupList.PreferredSize(FieldWidth: Integer): TSize;
var
  Rows: Integer;
begin
  Rows := RowCount;
  if Rows > FDropDownCount then
    Rows := FDropDownCount;
  if Rows < 1 then
    Rows := 1;
  Result.cx := FieldWidth;
  if FDropDownWidth > Result.cx then
    Result.cx := FDropDownWidth;
  Result.cy := HeightForRows(Rows);
end;

procedure TPPGPopupList.DropMouseMove(X, Y: Integer; Shift: TShiftState);
begin
  MouseMoveAt(X, Y);
end;

function TPPGPopupList.DropMouseDown(X, Y: Integer): TPPGDropAction;
begin
  MouseDownAt(X, Y);
  Result := pdaKeepOpen;
end;

function TPPGPopupList.DropMouseUp(X, Y: Integer): TPPGDropAction;
var
  Idx: Integer;
begin
  Result := pdaNone;
  Idx := MouseUpAt(X, Y);
  if (Idx >= 0) and PtInRect(Rect(0, 0, Width, Height), Point(X, Y)) then
  begin
    SetHighlight(Idx);
    Result := pdaAccept;
  end;
end;

function TPPGPopupList.DropKeyDown(var Key: Word; Shift: TShiftState): TPPGDropAction;
var
  Page: Integer;
begin
  Result := pdaKeepOpen;
  Page := VisibleRows - 1;
  if Page < 1 then
    Page := 1;
  case Key of
    VK_UP: MoveHighlight(-1);
    VK_DOWN: MoveHighlight(1);
    VK_PRIOR: MoveHighlight(-Page);
    VK_NEXT: MoveHighlight(Page);
    // Zeilen der (ggf. gefilterten) Liste
    VK_HOME:
      if RowCount > 0 then
        SetHighlight(ItemOfRow(0));
    VK_END:
      if RowCount > 0 then
        SetHighlight(ItemOfRow(RowCount - 1));
    VK_RETURN: Result := pdaAccept;
  else
    Exit(pdaNone); // z.B. Pfeil links im Edit: Taste bleibt erhalten
  end;
  Key := 0;
end;

procedure TPPGPopupList.DropWheel(Delta: Integer);
const
  WheelLines = 3;
begin
  if Delta > 0 then
    ScrollLines(-WheelLines)
  else if Delta < 0 then
    ScrollLines(WheelLines);
end;

procedure TPPGPopupList.DropMouseLeave;
begin
  // Hervorhebung bleibt (wie Windows); nur die Scrollleiste ist nicht mehr heiss
  if not FThumbDrag then
    MouseMoveAt(-1, -1);
end;

procedure TPPGPopupList.ScrollLines(Delta: Integer);
begin
  SetTopIndex(FTopIndex + Delta);
end;

procedure TPPGPopupList.MouseDownAt(X, Y: Integer);
var
  Th, Tr: TRect;
begin
  FPressedItem := -1;
  Th := ThumbRect;
  Tr := TrackRect;
  if not IsRectEmpty(Th) and PtInRect(Th, Point(X, Y)) then
  begin
    FThumbDrag := True;
    FDragOffset := Y - Th.Top;
  end
  else if not IsRectEmpty(Tr) and PtInRect(Tr, Point(X, Y)) then
  begin
    // Klick in die Spur blaettert seitenweise
    if Y < Th.Top then
      ScrollLines(-(VisibleRows - 1))
    else
      ScrollLines(VisibleRows - 1);
  end
  else
  begin
    FPressedItem := ItemAtPos(X, Y);
    if FPressedItem >= 0 then
      SetHighlight(FPressedItem);
  end;
end;

procedure TPPGPopupList.MouseMoveAt(X, Y: Integer);
var
  Tr, Th: TRect;
  Hot: Boolean;
  MaxTop, Range, I: Integer;
begin
  Tr := TrackRect;
  if FThumbDrag then
  begin
    Th := ThumbRect;
    Range := (Tr.Bottom - Tr.Top) - (Th.Bottom - Th.Top);
    MaxTop := RowCount - VisibleRows;
    if (Range > 0) and (MaxTop > 0) then
      SetTopIndex(MulDiv(Y - FDragOffset - Tr.Top, MaxTop, Range));
    Exit;
  end;
  Hot := not IsRectEmpty(Tr) and (X >= Tr.Left - PPGScale(4, ScalePPI)) and
    (X < Tr.Right + PPGScale(4, ScalePPI)) and (Y >= 0) and (Y < Height);
  if Hot <> FScrollHot then
  begin
    FScrollHot := Hot;
    Invalidate;
  end;
  // Hervorhebung folgt der Maus (wie die Liste einer Windows-ComboBox)
  I := ItemAtPos(X, Y);
  if I >= 0 then
    SetHighlight(I);
end;

function TPPGPopupList.MouseUpAt(X, Y: Integer): Integer;
begin
  Result := -1;
  if FThumbDrag then
  begin
    FThumbDrag := False;
    Invalidate;
    Exit;
  end;
  Result := ItemAtPos(X, Y);
  FPressedItem := -1;
end;

procedure TPPGPopupList.GetStyles(out ListStyle, HighlightStyle: TPPGSurfaceStyle);
begin
  GetPopupStyles(FListColor, FTextColor, ListStyle, HighlightStyle);
end;

procedure TPPGPopupWindow.GetPopupStyles(Fill, Text: TColor; out ListStyle,
  HighlightStyle: TPPGSurfaceStyle);
var
  A: TPPGAppearance;
  PPI: Integer;
  SelFill, SelText: TColor;
begin
  A := EffectiveAppearance;
  PPI := ScalePPI;
  ListStyle := A.Resolve(vsNormal, PPI, False);
  HighlightStyle := A.Resolve(vsHot, PPI, False);
  ListStyle.Color := PPGColorToRGB(Fill);
  ListStyle.TextColor := PPGColorToRGB(Text);
  ListStyle.GlowColor := PPGColorToRGB(A.FocusColor);
  // Rahmen des Popups etwas kraeftiger als der eines Felds (liegt ueber Inhalt)
  ListStyle.BorderColor := PPGBlendColor(ListStyle.BorderColor, ListStyle.TextColor, 0.15);
  if ListStyle.BorderWidth < 1 then
    ListStyle.BorderWidth := 1;
  if ListStyle.Rounding > PPGScale(8, PPI) then
    ListStyle.Rounding := PPGScale(8, PPI);
  if HighContrastSupport and PPGIsHighContrast then
  begin
    ListStyle.Color := PPGColorToRGB(clWindow);
    ListStyle.TextColor := PPGColorToRGB(clWindowText);
    ListStyle.BorderColor := PPGColorToRGB(clWindowText);
    ListStyle.GlowColor := PPGColorToRGB(clHighlight);
    SelFill := PPGColorToRGB(clHighlight);
    SelText := PPGColorToRGB(clHighlightText);
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
    ListStyle.Color := Fill;
    ListStyle.TextColor := Text;
    ListStyle.GlowColor := SelFill;
    HighlightStyle.Color := SelFill;
    HighlightStyle.ColorTo := SelFill;
    HighlightStyle.ColorMirror := SelFill;
    HighlightStyle.ColorMirrorTo := SelFill;
    HighlightStyle.BorderColor := SelFill;
    HighlightStyle.TextColor := SelText;
  end;
end;

procedure TPPGPopupList.PaintRowBackground(const ACanvas: IPPGCanvas; const LR: IPPGListRenderer;
  const R: TRect; const L, H: TPPGSurfaceStyle; const Info: TPPGItemPaintInfo;
  const Data: TPPGItemData; Row: Integer; Selected: Boolean; Hl: Single);
var
  HS: TPPGSurfaceStyle;
  Fill, C: TColor;
  S: TPPGListStyles;
  OwnSel: Boolean;
begin
  HS := H;
  S := FListStyles;
  OwnSel := False;
  if Info.UseColors then
  begin
    Fill := clNone;
    if (S <> nil) and Odd(Row) and S.AlternateRow.HasFill(Info.Dark) then
      Fill := S.AlternateRow.FillFor(Info.Dark, clNone);
    if (Data.Color <> clDefault) and (Data.Color <> clNone) then
      Fill := PPGColorToRGB(Data.Color);
    if Fill <> clNone then
      ACanvas.FillRoundRect(R, 0, Fill, 255);
    if S <> nil then
    begin
      if S.HotItem.HasFill(Info.Dark) then
      begin
        C := S.HotItem.FillFor(Info.Dark, HS.Color);
        HS.Color := C;
        HS.ColorTo := C;
        HS.ColorMirror := C;
        HS.ColorMirrorTo := C;
      end;
      if Selected and S.Selection.HasFill(Info.Dark) then
      begin
        OwnSel := True;
        ACanvas.FillRoundRect(R, PPGScale(4, Info.PPI), S.Selection.FillFor(Info.Dark, clNone), 255);
      end;
    end;
  end;
  LR.DrawListItem(ACanvas, R, L, HS, Selected and not OwnSel, Hl, Info.PPI);
end;

procedure TPPGPopupList.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  LR: IPPGListRenderer;
  IR: IPPGItemRenderer;
  L, H: TPPGSurfaceStyle;
  PPI, Row, Last, I: Integer;
  Frame, R: TRect;
  Hl: Single;
  Info: TPPGItemPaintInfo;
  Data: TPPGItemData;
  Sel: Boolean;
  St: TPPGItemDrawState;
  DS: TPPGDrawStyle;
begin
  PPI := ScalePPI;
  GetStyles(L, H);
  if not Supports(Renderer, IPPGListRenderer, LR) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName), IPPGListRenderer, LR);
  IR := PPGItemRendererOf(Renderer);
  Frame := Rect(0, ContentOffset, Width, ContentOffset + FullHeight);
  LR.DrawPopupFrame(ACanvas, Frame, L, PPI);
  if FItems = nil then
    Exit;
  Info.ListStyle := L;
  Info.HighlightStyle := H;
  Info.Font := Font;
  if FSource <> nil then
    Info.Images := Images
  else
    Info.Images := nil;
  Info.AllowMarkup := FSource <> nil;
  Info.RightToLeft := UseRightToLeftAlignment;
  Info.Enabled := True;
  Info.PPI := PPI;
  Info.Styles := FListStyles;
  Info.UseColors := not (HighContrastSupport and PPGIsHighContrast) and not UseVclStyle;
  Info.Dark := UseDarkMode;
  Info.Focused := True;
  Info.TabWidth := 0;
  Last := FTopIndex + VisibleRows - 1;
  if Last > RowCount - 1 then
    Last := RowCount - 1;
  for Row := FTopIndex to Last do
  begin
    I := ItemOfRow(Row);
    R := ItemRect(I);
    if I = FHighlight then
      Hl := 1
    else
      Hl := 0;
    GetRowData(I, Data);
    Sel := I = FItemIndex;
    // Eigenes Zeichnen (Style) bzw. ganz selbst (DefaultDraw = False)
    if Assigned(FOnCustomDrawItem) then
    begin
      St := [];
      if Sel then
        Include(St, idsSelected);
      if Hl > 0 then
        Include(St, idsHot);
      if not Data.Enabled then
        Include(St, idsDisabled);
      if not PPGRunCustomDraw(ACanvas, FDrawCanvas, Font, FOnCustomDrawItem, FStyleSource, I,
        R, St, DS) then
        Continue;
      if DS.Fill <> clNone then
        Data.Color := DS.Fill;
      if DS.TextColor <> clNone then
        Data.TextColor := DS.TextColor;
      Data.FontStyle := Data.FontStyle + DS.FontStyle;
    end;
    PaintRowBackground(ACanvas, LR, R, L, H, Info, Data, Row, Sel, Hl);
    // Text: hervorgehoben nur beim Hover; die Auswahl-Stile gelten fuer den
    // aktuellen Wert, wenn sie gesetzt sind
    FPainter.PaintItemContent(ACanvas, IR, R, Data, Info, Row,
      Sel and (FListStyles <> nil) and not FListStyles.Selection.IsEmpty, Hl);
  end;
  FPainter.EndPaint;
  if NeedScrollBar then
    LR.DrawScrollThumb(ACanvas, TrackRect, ThumbRect, L, FScrollHot or FThumbDrag, PPI);
end;

procedure TPPGPopupList.WndProc(var Message: TMessage);
var
  I: Integer;
begin
  if (GMsgItemAction <> 0) and (Message.Msg = GMsgItemAction) then
  begin
    // Aus AccChildDoDefault gepostet: Anwender-Code ausserhalb des COM-Aufrufs.
    // WParam = Zeile, LParam = Eintrag zum Zeitpunkt des Postens. Hat der
    // Filter die Zeilen inzwischen umgestellt, nichts ausloesen.
    I := ItemOfRow(Integer(Message.WParam));
    if Assigned(FOnItemClick) and (I >= 0) and (I = Integer(Message.LParam)) then
      FOnItemClick(Self, I);
    Exit;
  end;
  inherited WndProc(Message);
end;

{ ---- Barrierefreiheit ---- }

function TPPGPopupList.AccName: string;
begin
  Result := FListName;
end;

function TPPGPopupList.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_LIST;
end;

function TPPGPopupList.AccState: Integer;
begin
  Result := 0;
  if not FOpen then
    Result := STATE_SYSTEM_INVISIBLE;
end;

function TPPGPopupList.AccDefaultAction: string;
begin
  Result := '';
end;

procedure TPPGPopupList.AccDoDefaultAction;
begin
  // Die Liste selbst hat keine Standardaktion (nur ihre Eintraege)
end;

function TPPGPopupList.AccChildCount: Integer;
begin
  Result := RowCount;
end;

function TPPGPopupList.AccChildName(Id: Integer): string;
var
  Data: TPPGItemData;
begin
  GetRowData(ItemOfRow(Id - 1), Data);
  Result := TPPGItemPainter.PlainText(Data);
end;

function TPPGPopupList.AccChildRole(Id: Integer): Integer;
begin
  Result := ROLE_SYSTEM_LISTITEM;
end;

function TPPGPopupList.AccChildState(Id: Integer): Integer;
var
  Row: Integer;
begin
  Row := Id - 1;
  Result := STATE_SYSTEM_SELECTABLE or STATE_SYSTEM_FOCUSABLE;
  if ItemOfRow(Row) = FHighlight then
    Result := Result or STATE_SYSTEM_SELECTED or STATE_SYSTEM_FOCUSED;
  if (Row < FTopIndex) or (Row >= FTopIndex + VisibleRows) then
    Result := Result or STATE_SYSTEM_INVISIBLE or STATE_SYSTEM_OFFSCREEN;
end;

function TPPGPopupList.AccChildRect(Id: Integer): TRect;
begin
  Result := ItemRect(ItemOfRow(Id - 1));
end;

function TPPGPopupList.AccChildAt(X, Y: Integer): Integer;
begin
  Result := RowOfItem(ItemAtPos(X, Y)) + 1;
end;

function TPPGPopupList.AccChildDefaultAction(Id: Integer): string;
begin
  Result := PPGStr(@SPPGAccSelect);
end;

procedure TPPGPopupList.AccChildDoDefault(Id: Integer);
begin
  if HandleAllocated and (ItemOfRow(Id - 1) >= 0) then
    PostMessage(Handle, GMsgItemAction, WPARAM(Id - 1), LPARAM(ItemOfRow(Id - 1)));
end;

function TPPGPopupList.AccFocusedChild: Integer;
begin
  Result := RowOfItem(FHighlight) + 1;
end;

function TPPGPopupList.AccSelectedChild: Integer;
begin
  Result := RowOfItem(FHighlight) + 1;
end;

end.
