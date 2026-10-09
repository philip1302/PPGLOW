unit PPG.Menus;

{ Menues im Stil der Suite (Phase 11b).

  Modell bleibt die VCL: TPopupMenu/TMainMenu mit TMenuItem (Menue-Designer,
  Actions, ShortCut, ImageIndex, Checked/RadioItem, Default, Break, Hint,
  OnClick, DFM). Ersetzt wird nur die Darstellung:

  - TPPGMenuWindow: eine Menue-Ebene als Popup ohne Aktivierung (wie die
    ComboBox-Liste). Spalten Bild/Haken | Text mit Mnemonic | Tastenkuerzel |
    Pfeil; Trenner, Break-Spalten, Blaettern bei sehr langen Menues.
  - TPPGMenuLoop: steuert alle offenen Ebenen. Solange ein Menue offen ist,
    leitet ein Haken in PPG.AppHooks Tasten und Mausklicks an das Menue
    (Fokus und Titelleiste bleiben beim Formular, wie bei Windows-Menues).
    Klick ausserhalb schliesst (und wird verbraucht, wie bei Windows),
    Deaktivieren der Anwendung schliesst.
  - Ausloesen: erst alles schliessen, dann TMenuItem.Click ueber eine
    gepostete Nachricht - wie die VCL (WM_COMMAND nach TrackPopupMenu). So
    laeuft Anwender-Code nie mit offenem Menue oder aus einem Menuefenster.
  - TPPGPopupMenu = TPopupMenu mit eigener Darstellung: bestehende
    PopupMenu-Properties, Split-Button-DropDownMenu usw. funktionieren
    unveraendert. Popup(X, Y) kehrt wie bei der VCL erst nach dem Schliessen
    zurueck.
  - Barrierefreiheit: ROLE_SYSTEM_MENUPOPUP/MENUITEM, EVENT_SYSTEM_MENUPOPUPSTART
    /END, EVENT_OBJECT_FOCUS fuer den hervorgehobenen Eintrag - nur damit lesen
    Narrator und NVDA eigene Menues vor.
  - Owner-Draw fremder Menues (OnDrawItem/OnAdvancedDrawItem) wird weiter
    aufgerufen. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.Generics.Collections, System.UITypes, Vcl.Controls, Vcl.Graphics, Vcl.Menus, Vcl.ImgList,
  Vcl.Forms,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Base,
  PPG.StyleManager, PPG.Popup, PPG.Popup.Placement, PPG.ElementStyle, PPG.CustomDraw;

type
  TPPGMenuLoop = class;

  /// Bereiche der Menues (nur gesetzte Werte zaehlen, clDefault = Preset).
  TPPGMenuStyles = class(TPPGStyleGroup)
  public
    constructor Create(AOwner: TPersistent);
  published
    /// Menue: Flaeche (Color), Text (TextColor), Schrift.
    property Menu: TPPGElementStyle index 0 read GetItem write SetItem;
    /// Hervorgehobener Eintrag.
    property HotItem: TPPGElementStyle index 1 read GetItem write SetItem;
    /// Trennlinien (Color).
    property Separator: TPPGElementStyle index 2 read GetItem write SetItem;
    /// Tastenkuerzel (TextColor, Schrift).
    property Shortcut: TPPGElementStyle index 3 read GetItem write SetItem;
  end;

  /// Vor dem Zeichnen eines Menue-Eintrags (siehe PPG.CustomDraw).
  TPPGMenuCustomDrawEvent = procedure(Sender: TObject; Canvas: TCanvas; Item: TMenuItem;
    const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
    var DefaultDraw: Boolean) of object;

  /// Rueckmeldungen der Schleife an eine Menueleiste (TPPGMenuBar).
  IPPGMenuBarHost = interface
    ['{C6B2A713-0E4F-4B85-9D61-2F7A93E5B048}']
    /// Pfeil links/rechts auf der obersten Ebene: Nachbar der Leiste oeffnen.
    procedure MenuBarStep(Delta: Integer);
    /// Die Schleife hat geschlossen. Escaped = Esc auf der obersten Ebene
    /// (die Leiste bleibt dann im Tastaturmodus).
    procedure MenuBarClosed(Escaped: Boolean);
    /// True, wenn der Klick (Bildschirmpunkt) der Leiste gehoert.
    function MenuBarOwnsPoint(const ScreenPt: TPoint): Boolean;
  end;

  TPPGMenuWindow = class(TPPGPopupWindow, IPPGAccessibleChildren)
  private
    FLoop: TPPGMenuLoop;
    FLevel: Integer;
    FParentItem: TMenuItem;
    FItems: TArray<TMenuItem>;
    FRects: TArray<TRect>;      // Inhalt-Koordinaten (ohne Blaettern)
    FCols: TArray<Integer>;     // Spalte je Eintrag
    FColLeft: TArray<Integer>;
    FColWidth: TArray<Integer>;
    FIconW: Integer;
    FShortcutW: TArray<Integer>;
    FHasArrow: TArray<Boolean>;
    FHot: Integer;
    FContentHeight: Integer;
    FScrollY: Integer;
    FScrollable: Boolean;
    FScrollDir: Integer;
    FScrollAnim: TPPGAnimation;
    FBoldFont: TFont;
    procedure ScrollStep(Sender: TObject);
    function ArrowH: Integer;
    function Pad: Integer;
    function ItemFont(Item: TMenuItem): TFont;
    procedure PaintItem(const ACanvas: IPPGCanvas; Index: Integer; const R: TRect;
      const L, H: TPPGSurfaceStyle; MR: IPPGMenuRenderer);
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure ApplyMenuStyles(var L, H: TPPGSurfaceStyle);
  protected
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function PopupRounding: Integer; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure WndProc(var Message: TMessage); override;
    function AccName: string; override;
    function AccRole: Integer; override;
    function AccState: Integer; override;
    { IPPGAccessibleChildren }
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
    /// Eintraege der Ebene uebernehmen (sichtbare Kinder von Parent) und
    /// messen. Liefert die benoetigte Groesse.
    function LoadItems(Parent: TMenuItem): TSize;
    function ItemCount: Integer;
    function Item(Index: Integer): TMenuItem;
    /// Lage eines Eintrags im Fenster (Client-Koordinaten, mit Blaettern).
    function ItemRect(Index: Integer): TRect;
    function ItemAtPos(X, Y: Integer): Integer;
    function IsSelectable(Index: Integer): Boolean;
    /// Hervorhebung setzen (-1 = keine), meldet Screenreader und Hint.
    procedure SetHot(Index: Integer);
    /// Naechster waehlbarer Eintrag in Richtung Delta (mit Umlauf).
    procedure MoveHot(Delta: Integer);
    procedure HotFirst;
    procedure HotLast;
    procedure ScrollBy(Delta: Integer);
    procedure MakeVisible(Index: Integer);
    property Hot: Integer read FHot;
    property Level: Integer read FLevel;
    property ParentItem: TMenuItem read FParentItem;
    property Loop: TPPGMenuLoop read FLoop;
    property Scrollable: Boolean read FScrollable;
    /// Ereignis fuer Screenreader (z.B. EVENT_SYSTEM_MENUPOPUPSTART).
    procedure NotifyMenuEvent(Event: DWORD);
    /// Hoehe eines normalen Eintrags (Mausrad).
    function LineHeight: Integer;
    property Font;
    property BiDiMode;
    property Preset;
    property StyleManager;
  end;

  TPPGMenuLoop = class
  private
    FWindows: TObjectList<TPPGMenuWindow>;
    FOpenCount: Integer;
    FActive: Boolean;
    FModal: Boolean;
    FStyleSource: TPPGCustomControl;
    FStyleManager: TPPGStyleManager;
    FPreset: string;
    FBiDiMode: TBiDiMode;
    FShowAccelerators: Boolean;
    FBar: IPPGMenuBarHost;
    FDelay: TPPGAnimation;
    FPendingWindow: TPPGMenuWindow;
    FPendingIndex: Integer;
    FSelected: TMenuItem;
    FHooked: Boolean;
    FCloseOnKeyUp: Boolean;   // Alt/F10 gedrueckt: beim Loslassen schliessen
    FAnimate: Boolean;
    FOnClosed: TNotifyEvent;
    FMenuStyles: TPPGMenuStyles;
    FOnCustomDrawItem: TPPGMenuCustomDrawEvent;
    FDrawSender: TObject;
    procedure SetPreset(const Value: string);
    procedure Hook(var Msg: TMsg; var Handled: Boolean);
    procedure AppDeactivate(Sender: TObject);
    procedure DelayStep(Sender: TObject);
    procedure StartHooks;
    procedure StopHooks;
    function WindowAt(const ScreenPt: TPoint): TPPGMenuWindow;
    function IsMenuWindow(Wnd: HWND): Boolean;
    function PrepareWindow(Level: Integer): TPPGMenuWindow;
    function AnimationMs: Cardinal;
    procedure InitiateActions(Parent: TMenuItem);
    procedure Finish(Escaped: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    /// Oeffnet die oberste Ebene am Anker (Punkt oder Rechteck).
    procedure OpenPopup(Items: TMenuItem; const Anchor: TRect; Side: TPPGPopupSide;
      AlignEnd: Boolean);
    /// Oeffnet das Untermenue des Eintrags Index von Window.
    procedure OpenSubmenu(Window: TPPGMenuWindow; Index: Integer; SelectFirst: Boolean);
    /// Schliesst alle Ebenen ab Level (0 = alles).
    procedure CloseFrom(Level: Integer);
    procedure CloseAll;
    /// Eintrag ausloesen: alles schliessen, Click per gepostete Nachricht.
    procedure Execute(Item: TMenuItem);
    /// Hover auf einem Eintrag: Untermenue verzoegert oeffnen bzw. schliessen.
    procedure HoverItem(Window: TPPGMenuWindow; Index: Integer);
    /// Tastatur (auch fuer Tests direkt aufrufbar). True = verarbeitet.
    function HandleKey(Key: Word; Shift: TShiftState): Boolean;
    function HandleChar(Ch: Char): Boolean;
    /// Wartet, bis das Menue geschlossen ist (wie TrackPopupMenu).
    procedure RunModal;
    function TopWindow: TPPGMenuWindow;
    function OpenCount: Integer;
    function Window(Level: Integer): TPPGMenuWindow;
    property Active: Boolean read FActive;
    property Modal: Boolean read FModal write FModal;
    /// Zuletzt ausgeloester Eintrag (nil = abgebrochen).
    property Selected: TMenuItem read FSelected;
    property StyleSource: TPPGCustomControl read FStyleSource write FStyleSource;
    property StyleManager: TPPGStyleManager read FStyleManager write FStyleManager;
    property Preset: string read FPreset write SetPreset;
    property BiDiMode: TBiDiMode read FBiDiMode write FBiDiMode;
    /// Unterstrichene Mnemonics zeigen (Oeffnen per Tastatur).
    property ShowAccelerators: Boolean read FShowAccelerators write FShowAccelerators;
    /// Aufklappen animieren (Systemeinstellung vorausgesetzt); False fuer Tests/Bilder.
    property Animate: Boolean read FAnimate write FAnimate;
    property Bar: IPPGMenuBarHost read FBar write FBar;
    property OnClosed: TNotifyEvent read FOnClosed write FOnClosed;
    /// Stile und eigenes Zeichnen des Ausloesers (gehoeren ihm, nicht der Schleife).
    property Styles: TPPGMenuStyles read FMenuStyles write FMenuStyles;
    property OnCustomDrawItem: TPPGMenuCustomDrawEvent read FOnCustomDrawItem write FOnCustomDrawItem;
    property DrawSender: TObject read FDrawSender write FDrawSender;
  end;

  TPPGPopupMenu = class(TPopupMenu)
  private
    FStyleManager: TPPGStyleManager;
    FPreset: string;
    FLoop: TPPGMenuLoop;
    FMenuStyles: TPPGMenuStyles;
    FOnCustomDrawItem: TPPGMenuCustomDrawEvent;
    // Zeigt waehrend PopupAtRect auf eine lokale Variable: Destroy meldet
    // dort, dass das Menue in der modalen Schleife freigegeben wurde
    FDestroyedFlag: PBoolean;
    procedure SetPreset(const Value: string);
    procedure SetStyleManager(const Value: TPPGStyleManager);
    procedure SetMenuStyles(const Value: TPPGMenuStyles);
    function StyleSourceControl: TPPGCustomControl;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Popup(X, Y: Integer); override;
    /// Am Rechteck (Bildschirmkoordinaten) aufklappen, z.B. unter einem Button.
    /// Kehrt wie Popup erst nach dem Schliessen zurueck.
    procedure PopupAtRect(const Anchor: TRect; ShowAccelerators: Boolean = False);
    /// Das offene Menue (waehrend Popup), sonst nil - fuer Tests und Diagnose.
    property Loop: TPPGMenuLoop read FLoop;
  published
    /// Optik wie die Controls (Preset, Appearance); sonst die des Ausloesers.
    property StyleManager: TPPGStyleManager read FStyleManager write SetStyleManager;
    /// Preset ohne StyleManager ('' = des Ausloesers bzw. Standard).
    property Preset: string read FPreset write SetPreset;
    /// Bereiche des Menues (Flaeche, Hover, Trennlinien, Kuerzel).
    property Styles: TPPGMenuStyles read FMenuStyles write SetMenuStyles;
    /// Vor dem Zeichnen jedes Eintrags: Style anpassen oder selbst zeichnen.
    property OnCustomDrawItem: TPPGMenuCustomDrawEvent read FOnCustomDrawItem write FOnCustomDrawItem;
  end;

/// Das gerade offene Menue der Anwendung (nil = keins).
function PPGActiveMenuLoop: TPPGMenuLoop;
/// Gepostete Ausloesungen sofort verarbeiten (Tests).
procedure PPGFlushMenuExecute;

implementation

uses
  PPG.Lang,
  System.Math, Winapi.oleacc,
  PPG.Consts, PPG.Appearance, PPG.Tokens, PPG.DpiUtils, PPG.AppHooks,
  PPG.Render.Registry, PPG.Render.Gdi;

const
  WM_PPG_MENUEXECUTE = WM_APP + $3A1;
  MinItemH = 28;     // logische px
  SepH = 9;
  IconCol = 28;
  ArrowCol = 20;
  ShortcutGap = 24;
  TextPadR = 12;
  ScrollArrowH = 16;
  MaxTextW = 480;

type
  TMenuItemAccess = class(TMenuItem);
  TPopupAccess = class(TPopupMenu);

  /// Fuehrt einen Eintrag nach dem Schliessen aus (gepostete Nachricht).
  /// Lebt bis zum Programmende; FreeNotification sichert gegen geloeschte
  /// Eintraege.
  TMenuExecutor = class(TComponent)
  private
    FWnd: HWND;
    FPending: TMenuItem;
    procedure WndProc(var Message: TMessage);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Post(Item: TMenuItem);
    procedure Flush;
  end;

var
  GExecutor: TMenuExecutor = nil;
  // Nach der Finalisierung nichts mehr anlegen (Formulare werden spaeter
  // abgebaut, siehe PPG.Animation)
  GFinalized: Boolean = False;
  // Untermenue per Screenreader oeffnen: gepostet, nie im COM-Aufruf
  GMsgMenuWindowAction: Cardinal = 0;
  GActiveLoop: TPPGMenuLoop = nil;

function Executor: TMenuExecutor;
begin
  if (GExecutor = nil) and not GFinalized then
    GExecutor := TMenuExecutor.Create(nil);
  Result := GExecutor;
end;

function PPGActiveMenuLoop: TPPGMenuLoop;
begin
  Result := GActiveLoop;
end;

procedure PPGFlushMenuExecute;
begin
  if GExecutor <> nil then
    GExecutor.Flush;
end;

{ TMenuExecutor }

constructor TMenuExecutor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FWnd := AllocateHWnd(WndProc);
end;

destructor TMenuExecutor.Destroy;
begin
  if FWnd <> 0 then
    DeallocateHWnd(FWnd);
  FWnd := 0;
  inherited Destroy;
end;

procedure TMenuExecutor.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FPending) then
    FPending := nil;
end;

procedure TMenuExecutor.Post(Item: TMenuItem);
begin
  if FPending <> nil then
    FPending.RemoveFreeNotification(Self);
  FPending := Item;
  if Item <> nil then
  begin
    Item.FreeNotification(Self);
    PostMessage(FWnd, WM_PPG_MENUEXECUTE, 0, 0);
  end;
end;

procedure TMenuExecutor.Flush;
var
  Item: TMenuItem;
begin
  Item := FPending;
  if Item = nil then
    Exit;
  FPending := nil;
  Item.RemoveFreeNotification(Self);
  // Letzte Anweisung: Click darf Menue, Formular oder Anwendung beenden
  Item.Click;
end;

procedure TMenuExecutor.WndProc(var Message: TMessage);
begin
  if Message.Msg = WM_PPG_MENUEXECUTE then
  begin
    try
      Flush;
    except
      Application.HandleException(Self);
    end;
  end
  else
    Message.Result := DefWindowProc(FWnd, Message.Msg, Message.WParam, Message.LParam);
end;

{ Hilfen }

function HotkeyChar(Item: TMenuItem): Char;
var
  S: string;
begin
  S := GetHotkey(Item.Caption);
  if S = '' then
    Result := #0
  else
    Result := UpCase(S[1]);
end;

function MenuSettingBool(Action: UINT): Boolean;
var
  B: BOOL;
begin
  B := False;
  if SystemParametersInfo(Action, 0, @B, 0) then
    Result := B
  else
    Result := False;
end;

function MenuShowDelay: Cardinal;
var
  V: DWORD;
begin
  V := 400;
  if not SystemParametersInfo(SPI_GETMENUSHOWDELAY, 0, @V, 0) then
    V := 400;
  if V < 1 then
    V := 1;
  Result := V;
end;

{ TPPGMenuWindow }

constructor TPPGMenuWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHot := -1;
  FBoldFont := TFont.Create;
  FScrollAnim := TPPGAnimation.Create(Self);
  FScrollAnim.OnStep := ScrollStep;
  if GMsgMenuWindowAction = 0 then
    GMsgMenuWindowAction := RegisterWindowMessage('PPGlow.MenuWindowAction');
end;

destructor TPPGMenuWindow.Destroy;
begin
  if FScrollAnim <> nil then
    FScrollAnim.OnStep := nil;
  FreeAndNil(FScrollAnim);
  FreeAndNil(FBoldFont);
  inherited Destroy;
end;

function TPPGMenuWindow.Pad: Integer;
begin
  Result := PPGScale(4, ScalePPI);
end;

function TPPGMenuWindow.ArrowH: Integer;
begin
  Result := PPGScale(ScrollArrowH, ScalePPI);
end;

function TPPGMenuWindow.ItemFont(Item: TMenuItem): TFont;
begin
  if Item.Default then
  begin
    FBoldFont.Assign(Font);
    FBoldFont.Style := FBoldFont.Style + [fsBold];
    Result := FBoldFont;
  end
  else
    Result := Font;
end;

function TPPGMenuWindow.PopupRounding: Integer;
var
  L, H: TPPGSurfaceStyle;
  T: TPPGTokens;
begin
  T := Tokens;
  GetPopupStyles(T.Layer, T.TextPrimary, L, H);
  Result := L.Rounding;
end;

function TPPGMenuWindow.LoadItems(Parent: TMenuItem): TSize;
var
  I, N, Col, Y, PPI, ItemH, TH, ColStart, W, MaxTW, MaxSW, J: Integer;
  It: TMenuItem;
  Images: TCustomImageList;
  S: TSize;
  Arrow: Boolean;
  Heights: TArray<Integer>;
begin
  FParentItem := Parent;
  FHot := -1;
  FScrollY := 0;
  PPI := ScalePPI;
  N := 0;
  SetLength(FItems, Parent.Count);
  for I := 0 to Parent.Count - 1 do
    if Parent.Items[I].Visible then
    begin
      FItems[N] := Parent.Items[I];
      Inc(N);
    end;
  // Trenner am Anfang/Ende und doppelte Trenner weglassen (wie AutoLineReduction)
  J := 0;
  for I := 0 to N - 1 do
    if not (FItems[I].IsLine and ((J = 0) or FItems[J - 1].IsLine)) then
    begin
      FItems[J] := FItems[I];
      Inc(J);
    end;
  while (J > 0) and FItems[J - 1].IsLine do
    Dec(J);
  N := J;
  SetLength(FItems, N);
  SetLength(FRects, N);
  SetLength(FCols, N);
  SetLength(Heights, N);

  // Bildspalte: Platz fuer Haken bzw. das groesste Bild
  FIconW := PPGScale(IconCol, PPI);
  Images := Parent.GetImageList;
  if (Images <> nil) and (Images.Width + PPGScale(12, PPI) > FIconW) then
    FIconW := Images.Width + PPGScale(12, PPI);

  TH := PPGMeasureTextNoCanvas('Wg', Font, 0, False).cy;
  ItemH := Max(TH + PPGScale(10, PPI), PPGScale(MinItemH, PPI));

  // Spalten (Break = mbBreak/mbBarBreak beginnt eine neue Spalte)
  Col := 0;
  for I := 0 to N - 1 do
  begin
    if (I > 0) and (FItems[I].Break <> mbNone) then
      Inc(Col);
    FCols[I] := Col;
    if FItems[I].IsLine then
      Heights[I] := PPGScale(SepH, PPI)
    else
      Heights[I] := ItemH;
  end;
  SetLength(FColLeft, Col + 1);
  SetLength(FColWidth, Col + 1);
  SetLength(FShortcutW, Col + 1);
  SetLength(FHasArrow, Col + 1);

  // Breiten je Spalte
  Result.cx := 0;
  Result.cy := 0;
  W := Pad;
  ColStart := 0;
  for Col := 0 to High(FColLeft) do
  begin
    MaxTW := 0;
    MaxSW := 0;
    Arrow := False;
    Y := Pad;
    for I := ColStart to N - 1 do
    begin
      if FCols[I] <> Col then
        Break;
      It := FItems[I];
      if not It.IsLine then
      begin
        S := PPGMeasureTextNoCanvas(It.Caption, ItemFont(It), 0, False);
        MaxTW := Max(MaxTW, Min(S.cx, PPGScale(MaxTextW, PPI)));
        if It.ShortCut <> 0 then
          MaxSW := Max(MaxSW, PPGMeasureTextNoCanvas(ShortCutToText(It.ShortCut), Font, 0,
            False).cx);
        if It.Count > 0 then
          Arrow := True;
      end;
      FRects[I] := Rect(0, Y, 0, Y + Heights[I]);
      Inc(Y, Heights[I]);
      ColStart := I + 1;
    end;
    FColLeft[Col] := W;
    FShortcutW[Col] := MaxSW;
    FHasArrow[Col] := Arrow;
    FColWidth[Col] := FIconW + MaxTW + PPGScale(TextPadR, PPI);
    if MaxSW > 0 then
      Inc(FColWidth[Col], MaxSW + PPGScale(ShortcutGap, PPI));
    if Arrow then
      Inc(FColWidth[Col], PPGScale(ArrowCol, PPI));
    FColWidth[Col] := Max(FColWidth[Col], PPGScale(120, PPI));
    Inc(W, FColWidth[Col]);
    Result.cy := Max(Result.cy, Y + Pad);
  end;
  for I := 0 to N - 1 do
  begin
    FRects[I].Left := FColLeft[FCols[I]];
    FRects[I].Right := FRects[I].Left + FColWidth[FCols[I]];
  end;
  Result.cx := W + Pad;
  FContentHeight := Result.cy;
  if N = 0 then
  begin
    Result.cx := PPGScale(120, PPI);
    Result.cy := 2 * Pad;
  end;
end;

procedure TPPGMenuWindow.NotifyMenuEvent(Event: DWORD);
begin
  NotifyAccessibility(Event);
end;

function TPPGMenuWindow.LineHeight: Integer;
begin
  Result := Max(PPGMeasureTextNoCanvas('Wg', Font, 0, False).cy + PPGScale(10, ScalePPI),
    PPGScale(MinItemH, ScalePPI));
end;

function TPPGMenuWindow.ItemCount: Integer;
begin
  Result := Length(FItems);
end;

function TPPGMenuWindow.Item(Index: Integer): TMenuItem;
begin
  Result := FItems[Index];
end;

function TPPGMenuWindow.ItemRect(Index: Integer): TRect;
begin
  Result := FRects[Index];
  if FScrollable then
    OffsetRect(Result, 0, ArrowH - FScrollY);
  if UseRightToLeftAlignment then
  begin
    // Spalten und Eintrag spiegeln
    Result := Rect(ClientWidth - Result.Right, Result.Top, ClientWidth - Result.Left,
      Result.Bottom);
  end;
end;

function TPPGMenuWindow.ItemAtPos(X, Y: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  if FScrollable and ((Y < ArrowH) or (Y >= ClientHeight - ArrowH)) then
    Exit;
  for I := 0 to High(FItems) do
    if PtInRect(ItemRect(I), Point(X, Y)) then
      Exit(I);
end;

function TPPGMenuWindow.IsSelectable(Index: Integer): Boolean;
begin
  // Wie Windows: deaktivierte Eintraege sind per Tastatur erreichbar, aber
  // nicht ausloesbar; Trenner nie
  Result := (Index >= 0) and (Index < Length(FItems)) and not FItems[Index].IsLine;
end;

procedure TPPGMenuWindow.SetHot(Index: Integer);
begin
  if (Index >= 0) and not IsSelectable(Index) then
    Index := -1;
  if FHot = Index then
    Exit;
  FHot := Index;
  Invalidate;
  if FHot >= 0 then
  begin
    Application.Hint := GetLongHint(FItems[FHot].Hint);
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, FHot + 1);
  end
  else
    Application.Hint := '';
end;

procedure TPPGMenuWindow.MoveHot(Delta: Integer);
var
  I, N, Start: Integer;
begin
  N := Length(FItems);
  if N = 0 then
    Exit;
  Start := FHot;
  if Start < 0 then
  begin
    if Delta > 0 then
      Start := -1
    else
      Start := N;
  end;
  I := Start;
  repeat
    I := I + Delta;
    if I >= N then
      I := 0;
    if I < 0 then
      I := N - 1;
    if IsSelectable(I) then
    begin
      SetHot(I);
      MakeVisible(I);
      Exit;
    end;
  until I = Start;
end;

procedure TPPGMenuWindow.HotFirst;
begin
  FHot := -1;
  MoveHot(1);
end;

procedure TPPGMenuWindow.HotLast;
begin
  FHot := -1;
  MoveHot(-1);
end;

procedure TPPGMenuWindow.ScrollBy(Delta: Integer);
var
  MaxY: Integer;
begin
  if not FScrollable then
    Exit;
  MaxY := Max(0, FContentHeight - (ClientHeight - 2 * ArrowH));
  FScrollY := EnsureRange(FScrollY + Delta, 0, MaxY);
  Invalidate;
end;

procedure TPPGMenuWindow.MakeVisible(Index: Integer);
var
  Top, Bottom, View: Integer;
begin
  if not FScrollable or (Index < 0) then
    Exit;
  Top := FRects[Index].Top;
  Bottom := FRects[Index].Bottom;
  View := ClientHeight - 2 * ArrowH;
  if Top < FScrollY then
    FScrollY := Top
  else if Bottom > FScrollY + View then
    FScrollY := Bottom - View;
  Invalidate;
end;

procedure TPPGMenuWindow.ScrollStep(Sender: TObject);
begin
  // Endlosschleife waehrend die Maus auf einem Blaetterpfeil steht
  if FScrollDir <> 0 then
    ScrollBy(FScrollDir * PPGScale(6, ScalePPI));
end;

procedure TPPGMenuWindow.PaintItem(const ACanvas: IPPGCanvas; Index: Integer;
  const R: TRect; const L, H: TPPGSurfaceStyle; MR: IPPGMenuRenderer);
var
  It: TMenuItem;
  PPI, Col, X: Integer;
  T: TPPGTokens;
  TextCol, SecCol, SepCol: TColor;
  Images: TCustomImageList;
  IconR, TextR, ShortR, ArrowR: TRect;
  Flags, Base: Cardinal;
  HC, RTL, Hot: Boolean;
  DC: HDC;
  C: TCanvas;
  State: TOwnerDrawState;
  Img: Integer;
  MS: TPPGMenuStyles;
  UseColors, Dk, DrawIt: Boolean;
  DS: TPPGDrawStyle;
  St: TPPGItemDrawState;
  Body: TRect;
  F, Temp: TFont;
  ShortCol: TColor;
begin
  It := FItems[Index];
  MS := FLoop.Styles;
  PPI := ScalePPI;
  T := Tokens;
  HC := HighContrastSupport and PPGIsHighContrast;
  RTL := UseRightToLeftAlignment;
  Hot := Index = FHot;
  Col := FCols[Index];
  UseColors := not HC and not UseVclStyle;
  Dk := UseDarkMode;
  if It.IsLine then
  begin
    if HC then
      SepCol := PPGColorToRGB(clGrayText)
    else
      SepCol := PPGBlendColor(L.Color, L.TextColor, 0.15);
    if (MS <> nil) and UseColors then
      SepCol := MS.Separator.FillFor(Dk, SepCol);
    MR.DrawMenuSeparator(ACanvas, Rect(R.Left + PPGScale(8, PPI), R.Top,
      R.Right - PPGScale(8, PPI), R.Bottom), SepCol, PPI);
    Exit;
  end;
  // Fremdes Owner-Draw: das Ereignis zeichnet den ganzen Eintrag - unter
  // derselben Bedingung wie die VCL (OwnerDraw oder ImageList am Menue)
  if (It.GetParentMenu <> nil) and (It.GetParentMenu.OwnerDraw or (It.GetImageList <> nil)) and
    (Assigned(It.OnAdvancedDrawItem) or Assigned(It.OnDrawItem)) then
  begin
    DC := ACanvas.BeginGdi;
    try
      C := TCanvas.Create;
      try
        C.Handle := DC;
        C.Font := ItemFont(It);
        State := [];
        if Hot then
          Include(State, odSelected);
        if not It.Enabled then
          Include(State, odDisabled);
        if It.Checked then
          Include(State, odChecked);
        if It.Default then
          Include(State, odDefault);
        TMenuItemAccess(It).AdvancedDrawItem(C, R, State, False);
      finally
        C.Handle := 0;
        C.Free;
      end;
    finally
      ACanvas.EndGdi(DC);
    end;
    Exit;
  end;

  // Eigenes Zeichnen (Style) bzw. ganz selbst (DefaultDraw = False)
  DS.Reset;
  DrawIt := True;
  if Assigned(FLoop.OnCustomDrawItem) then
  begin
    St := [];
    if Hot then
      Include(St, idsSelected);
    if Hot then
      Include(St, idsHot);
    if not It.Enabled then
      Include(St, idsDisabled);
    if It.Checked then
      Include(St, idsChecked);
    DC := ACanvas.BeginGdi;
    try
      C := TCanvas.Create;
      try
        C.Handle := DC;
        C.Font := ItemFont(It);
        C.Brush.Style := bsClear;
        FLoop.OnCustomDrawItem(FLoop.DrawSender, C, It, R, St, DS, DrawIt);
      finally
        C.Handle := 0;
        C.Free;
      end;
    finally
      ACanvas.EndGdi(DC);
    end;
  end;
  if not DrawIt then
    Exit;
  Body := Rect(R.Left + PPGScale(4, PPI), R.Top + PPGScale(1, PPI),
    R.Right - PPGScale(4, PPI), R.Bottom - PPGScale(1, PPI));
  if UseColors and (DS.Fill <> clNone) then
    ACanvas.FillRoundRect(Body, PPGScale(4, PPI), PPGColorToRGB(DS.Fill), 255);
  if Hot then
    MR.DrawMenuItem(ACanvas, Body, L, H, 1, PPI);
  if HC then
  begin
    if not It.Enabled then
      TextCol := PPGColorToRGB(clGrayText)
    else if Hot then
      TextCol := H.TextColor
    else
      TextCol := L.TextColor;
  end
  else if not It.Enabled then
    TextCol := T.TextDisabled
  else if Hot then
    TextCol := H.TextColor // wie die Listen (Classic: dunkle Schrift auf Glanz)
  else
    TextCol := L.TextColor;
  if UseColors and It.Enabled then
  begin
    if Hot and (MS <> nil) then
      TextCol := MS.HotItem.TextFor(Dk, TextCol);
    if DS.TextColor <> clNone then
      TextCol := PPGColorToRGB(DS.TextColor);
  end;
  if HC or not It.Enabled then
    SecCol := TextCol
  else
    SecCol := PPGBlendColor(TextCol, L.Color, 0.35);
  ShortCol := SecCol;
  if (MS <> nil) and UseColors and It.Enabled then
    ShortCol := MS.Shortcut.TextFor(Dk, ShortCol);

  // Spalten: Bild/Haken | Text | Kuerzel | Pfeil (RTL gespiegelt)
  IconR := Rect(R.Left, R.Top, R.Left + FIconW, R.Bottom);
  ArrowR := Rect(R.Right - PPGScale(ArrowCol, PPI), R.Top, R.Right, R.Bottom);
  ShortR := Rect(R.Right - PPGScale(ArrowCol, PPI) - FShortcutW[Col], R.Top,
    R.Right - PPGScale(ArrowCol, PPI), R.Bottom);
  TextR := Rect(IconR.Right, R.Top, ShortR.Left - PPGScale(8, PPI), R.Bottom);
  if RTL then
  begin
    X := R.Left + R.Right;
    IconR := Rect(X - IconR.Right, IconR.Top, X - IconR.Left, IconR.Bottom);
    ArrowR := Rect(X - ArrowR.Right, ArrowR.Top, X - ArrowR.Left, ArrowR.Bottom);
    ShortR := Rect(X - ShortR.Right, ShortR.Top, X - ShortR.Left, ShortR.Bottom);
    TextR := Rect(X - TextR.Right, TextR.Top, X - TextR.Left, TextR.Bottom);
  end;

  Images := It.Parent.GetImageList;
  Img := It.ImageIndex;
  if (Images <> nil) and (Img >= 0) and (Img < Images.Count) then
  begin
    if It.Checked then
      ACanvas.FrameRoundRect(Rect((IconR.Left + IconR.Right - Images.Width) div 2 - 2,
        (IconR.Top + IconR.Bottom - Images.Height) div 2 - 2,
        (IconR.Left + IconR.Right + Images.Width) div 2 + 2,
        (IconR.Top + IconR.Bottom + Images.Height) div 2 + 2), PPGScale(3, PPI),
        PPGScale(1, PPI), PPGColorToRGB(EffectiveAppearance.FocusColor), 255);
    ACanvas.DrawImage(Images, Img, (IconR.Left + IconR.Right - Images.Width) div 2,
      (IconR.Top + IconR.Bottom - Images.Height) div 2, It.Enabled);
  end
  else if It.Checked then
  begin
    X := PPGScale(16, PPI);
    MR.DrawMenuCheck(ACanvas, Rect((IconR.Left + IconR.Right - X) div 2,
      (IconR.Top + IconR.Bottom - X) div 2, (IconR.Left + IconR.Right + X) div 2,
      (IconR.Top + IconR.Bottom + X) div 2), It.RadioItem, TextCol, PPI);
  end;

  Base := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
  if not FLoop.ShowAccelerators and not MenuSettingBool(SPI_GETKEYBOARDCUES) then
    Base := Base or DT_HIDEPREFIX;
  Flags := Base;
  if RTL then
    Flags := Flags or DT_RIGHT or DT_RTLREADING;
  Temp := nil;
  try
    F := ItemFont(It);
    if MS <> nil then
    begin
      if Hot then
        F := PPGStyledFont(F, MS.Menu.FontStyle + MS.HotItem.FontStyle + DS.FontStyle, Temp)
      else
        F := PPGStyledFont(F, MS.Menu.FontStyle + DS.FontStyle, Temp);
    end
    else
      F := PPGStyledFont(F, DS.FontStyle, Temp);
    ACanvas.DrawText(TextR, It.Caption, F, TextCol, Flags);
  finally
    Temp.Free;
  end;
  if It.ShortCut <> 0 then
  begin
    if RTL then
      Flags := DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_LEFT
    else
      Flags := DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_RIGHT;
    ACanvas.DrawText(ShortR, ShortCutToText(It.ShortCut), Font, ShortCol, Flags);
  end;
  if It.Count > 0 then
    MR.DrawMenuSubArrow(ACanvas, ArrowR, TextCol, RTL, PPI);
end;

procedure TPPGMenuWindow.ApplyMenuStyles(var L, H: TPPGSurfaceStyle);
var
  MS: TPPGMenuStyles;
  Dk: Boolean;
  C: TColor;
begin
  MS := FLoop.Styles;
  if (MS = nil) or (HighContrastSupport and PPGIsHighContrast) or UseVclStyle then
    Exit;
  Dk := UseDarkMode;
  if MS.Menu.HasFill(Dk) then
  begin
    C := MS.Menu.FillFor(Dk, L.Color);
    L.Color := C;
    L.ColorTo := C;
    L.ColorMirror := C;
    L.ColorMirrorTo := C;
  end;
  L.TextColor := MS.Menu.TextFor(Dk, L.TextColor);
  L.BorderColor := MS.Menu.BorderFor(Dk, L.BorderColor);
  if MS.HotItem.HasFill(Dk) then
  begin
    C := MS.HotItem.FillFor(Dk, H.Color);
    H.Color := C;
    H.ColorTo := C;
    H.ColorMirror := C;
    H.ColorMirrorTo := C;
  end;
end;

procedure TPPGMenuWindow.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  L, H: TPPGSurfaceStyle;
  T: TPPGTokens;
  MR: IPPGMenuRenderer;
  I, PPI, A: Integer;
  R, Clip: TRect;
  Arrow: TColor;
begin
  PPI := ScalePPI;
  T := Tokens;
  GetPopupStyles(T.Layer, T.TextPrimary, L, H);
  ApplyMenuStyles(L, H);
  if not Supports(Renderer, IPPGMenuRenderer, MR) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName), IPPGMenuRenderer, MR);
  MR.DrawMenuFrame(ACanvas, Rect(0, -ContentOffset, ClientWidth, FullHeight - ContentOffset),
    L, PPI);
  Clip := ClientR;
  if FScrollable then
    Clip := Rect(0, ArrowH, ClientWidth, ClientHeight - ArrowH);
  ACanvas.PushClipRoundRect(Clip, 0);
  try
    for I := 0 to High(FItems) do
    begin
      R := ItemRect(I);
      if (R.Bottom < Clip.Top) or (R.Top > Clip.Bottom) then
        Continue;
      PaintItem(ACanvas, I, R, L, H, MR);
    end;
    // Trennlinie zwischen Spalten bei mbBarBreak
    for I := 1 to High(FItems) do
      if (FItems[I].Break = mbBarBreak) and (FCols[I] <> FCols[I - 1]) then
      begin
        R := ItemRect(I);
        ACanvas.FillRoundRect(Rect(R.Left - PPGScale(1, PPI), Pad, R.Left, ClientHeight - Pad),
          0, PPGBlendColor(L.Color, L.TextColor, 0.15), 255);
      end;
  finally
    ACanvas.PopClip;
  end;
  if FScrollable then
  begin
    Arrow := L.TextColor;
    A := PPGScale(4, PPI);
    I := ClientWidth div 2;
    if FScrollY > 0 then
      ACanvas.DrawPolyline([Point(I - A, ArrowH div 2 + A div 2), Point(I, ArrowH div 2 - A div 2),
        Point(I + A, ArrowH div 2 + A div 2)], Max(PPGScale(1, PPI), 1), Arrow, 255);
    if FScrollY < FContentHeight - (ClientHeight - 2 * ArrowH) then
      ACanvas.DrawPolyline([Point(I - A, ClientHeight - ArrowH div 2 - A div 2),
        Point(I, ClientHeight - ArrowH div 2 + A div 2),
        Point(I + A, ClientHeight - ArrowH div 2 - A div 2)], Max(PPGScale(1, PPI), 1), Arrow, 255);
  end;
end;

procedure TPPGMenuWindow.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  I, Dir: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  // Blaetterpfeile: solange die Maus darauf steht, laufen
  Dir := 0;
  if FScrollable then
  begin
    if Y < ArrowH then
      Dir := -1
    else if Y >= ClientHeight - ArrowH then
      Dir := 1;
  end;
  if Dir <> FScrollDir then
  begin
    FScrollDir := Dir;
    if Dir <> 0 then
      FScrollAnim.StartLoop(1000)
    else
      FScrollAnim.Stop;
  end;
  I := ItemAtPos(X, Y);
  if (I >= 0) and (I <> FHot) then
  begin
    SetHot(I);
    FLoop.HoverItem(Self, I);
  end;
end;

procedure TPPGMenuWindow.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  I := ItemAtPos(X, Y);
  // Untermenue sofort beim Druecken (nicht erst nach der Verzoegerung)
  if (Button = mbLeft) and (I >= 0) and FItems[I].Enabled and (FItems[I].Count > 0) then
    FLoop.OpenSubmenu(Self, I, False);
end;

procedure TPPGMenuWindow.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button <> mbLeft then
    Exit;
  I := ItemAtPos(X, Y);
  if (I >= 0) and FItems[I].Enabled and (FItems[I].Count = 0) then
    FLoop.Execute(FItems[I]);
end;

procedure TPPGMenuWindow.CMMouseLeave(var Message: TMessage);
var
  Sub: TPPGMenuWindow;
begin
  inherited;
  FScrollDir := 0;
  FScrollAnim.Stop;
  // Hervorhebung bleibt nur auf dem Eintrag, dessen Untermenue offen ist
  Sub := nil;
  if FLoop.OpenCount > FLevel + 1 then
    Sub := FLoop.Window(FLevel + 1);
  if (FHot >= 0) and ((Sub = nil) or (Sub.ParentItem <> FItems[FHot])) then
    SetHot(-1);
end;

function TPPGMenuWindow.AccName: string;
begin
  if FParentItem <> nil then
    Result := StripHotkey(FParentItem.Caption)
  else
    Result := '';
end;

function TPPGMenuWindow.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_MENUPOPUP;
end;

function TPPGMenuWindow.AccState: Integer;
begin
  Result := 0;
end;

function TPPGMenuWindow.AccChildCount: Integer;
begin
  Result := Length(FItems);
end;

function TPPGMenuWindow.AccChildName(Id: Integer): string;
var
  It: TMenuItem;
begin
  Result := '';
  if (Id < 1) or (Id > Length(FItems)) then
    Exit;
  It := FItems[Id - 1];
  if It.IsLine then
    Exit;
  Result := StripHotkey(It.Caption);
end;

function TPPGMenuWindow.AccChildRole(Id: Integer): Integer;
begin
  if (Id >= 1) and (Id <= Length(FItems)) and FItems[Id - 1].IsLine then
    Result := ROLE_SYSTEM_SEPARATOR
  else
    Result := ROLE_SYSTEM_MENUITEM;
end;

function TPPGMenuWindow.AccChildState(Id: Integer): Integer;
var
  It: TMenuItem;
begin
  Result := 0;
  if (Id < 1) or (Id > Length(FItems)) then
    Exit;
  It := FItems[Id - 1];
  if not It.Enabled then
    Result := Result or STATE_SYSTEM_UNAVAILABLE;
  if It.Checked then
    Result := Result or STATE_SYSTEM_CHECKED;
  if It.Count > 0 then
    Result := Result or STATE_SYSTEM_HASPOPUP;
  if Id - 1 = FHot then
    Result := Result or STATE_SYSTEM_FOCUSED or STATE_SYSTEM_HOTTRACKED;
  Result := Result or STATE_SYSTEM_FOCUSABLE;
end;

function TPPGMenuWindow.AccChildRect(Id: Integer): TRect;
begin
  if (Id < 1) or (Id > Length(FItems)) then
    Result := Rect(0, 0, 0, 0)
  else
    Result := ItemRect(Id - 1);
end;

function TPPGMenuWindow.AccChildAt(X, Y: Integer): Integer;
begin
  Result := ItemAtPos(X, Y) + 1;
end;

function TPPGMenuWindow.AccChildDefaultAction(Id: Integer): string;
begin
  if (Id >= 1) and (Id <= Length(FItems)) and (FItems[Id - 1].Count > 0) then
    Result := PPGStr(@SPPGAccOpen)
  else
    Result := PPGStr(@SPPGAccPress);
end;

procedure TPPGMenuWindow.AccChildDoDefault(Id: Integer);
begin
  // Ausloesen nie im COM-Aufruf: Execute postet den Klick ohnehin, das
  // Oeffnen eines Untermenues (ruft OnClick) wird ebenfalls gepostet
  if (Id >= 1) and (Id <= Length(FItems)) and FItems[Id - 1].Enabled and
    not FItems[Id - 1].IsLine then
  begin
    if FItems[Id - 1].Count > 0 then
    begin
      if HandleAllocated then
        PostMessage(Handle, GMsgMenuWindowAction, WPARAM(Id - 1), LPARAM(FItems[Id - 1].Command));
    end
    else
      FLoop.Execute(FItems[Id - 1]);
  end;
end;

procedure TPPGMenuWindow.WndProc(var Message: TMessage);
var
  I: Integer;
begin
  if (GMsgMenuWindowAction <> 0) and (Message.Msg = GMsgMenuWindowAction) then
  begin
    I := Integer(Message.WParam);
    // Menue inzwischen zu oder umgebaut: nichts tun
    if (FLoop <> nil) and FLoop.Active and IsOpen and (I >= 0) and (I < Length(FItems)) and
      (FItems[I].Command = Word(Message.LParam)) then
      FLoop.OpenSubmenu(Self, I, True);
    Exit;
  end;
  inherited WndProc(Message);
end;

function TPPGMenuWindow.AccFocusedChild: Integer;
begin
  Result := FHot + 1;
end;

function TPPGMenuWindow.AccSelectedChild: Integer;
begin
  Result := FHot + 1;
end;

{ TPPGMenuStyles }

constructor TPPGMenuStyles.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, 4);
end;

{ TPPGMenuLoop }

procedure TPPGMenuLoop.SetPreset(const Value: string);
begin
  // Audit 5a: wie TPPGCustomControl.SetPreset pruefen (interne Schleife, keine DFM)
  FPreset := PPGCheckPreset(nil, Value);
end;

constructor TPPGMenuLoop.Create;
begin
  inherited Create;
  FWindows := TObjectList<TPPGMenuWindow>.Create(True);
  FDelay := TPPGAnimation.Create(Self);
  FDelay.OnStep := DelayStep;
  FBiDiMode := bdLeftToRight;
  FAnimate := True;
end;

destructor TPPGMenuLoop.Destroy;
begin
  CloseAll;
  StopHooks;
  if GActiveLoop = Self then
    GActiveLoop := nil;
  if FDelay <> nil then
    FDelay.OnStep := nil;
  FreeAndNil(FDelay);
  FreeAndNil(FWindows);
  inherited Destroy;
end;

function TPPGMenuLoop.AnimationMs: Cardinal;
begin
  if FAnimate and MenuSettingBool(SPI_GETMENUANIMATION) and not PPGIsRemoteSession and
    PPGSystemAnimationsEnabled then
    Result := 120
  else
    Result := 0;
end;

function TPPGMenuLoop.PrepareWindow(Level: Integer): TPPGMenuWindow;
begin
  while FWindows.Count <= Level do
  begin
    Result := TPPGMenuWindow.Create(nil);
    Result.FLoop := Self;
    Result.FLevel := FWindows.Count;
    FWindows.Add(Result);
  end;
  Result := FWindows[Level];
  // Optik: StyleManager > Ausloeser > Preset
  if FStyleSource <> nil then
    Result.SyncFrom(FStyleSource)
  else
  begin
    Result.SyncFrom(nil);
    Result.Font.Assign(Screen.MenuFont);
    Result.PopupPPI := Screen.PixelsPerInch;
  end;
  if FStyleManager <> nil then
    Result.StyleManager := FStyleManager
  else if FPreset <> '' then
    Result.Preset := FPreset;
  Result.BiDiMode := FBiDiMode;
end;

procedure TPPGMenuLoop.InitiateActions(Parent: TMenuItem);
var
  I: Integer;
begin
  // Wie die VCL vor dem Zeigen: Actions aktualisieren (Enabled, Checked ...)
  for I := 0 to Parent.Count - 1 do
    Parent.Items[I].InitiateAction;
end;

procedure TPPGMenuLoop.StartHooks;
begin
  if FHooked then
    Exit;
  PPGAddMessageHook(Hook);
  PPGAddDeactivateHook(AppDeactivate);
  FHooked := True;
end;

procedure TPPGMenuLoop.StopHooks;
begin
  if not FHooked then
    Exit;
  PPGRemoveMessageHook(Hook);
  PPGRemoveDeactivateHook(AppDeactivate);
  FHooked := False;
end;

procedure TPPGMenuLoop.OpenPopup(Items: TMenuItem; const Anchor: TRect;
  Side: TPPGPopupSide; AlignEnd: Boolean);
var
  W: TPPGMenuWindow;
  Size: TSize;
  Pl: TPPGPlacement;
begin
  // Nur ein Menue gleichzeitig (wie Windows)
  if (GActiveLoop <> nil) and (GActiveLoop <> Self) then
    GActiveLoop.CloseAll;
  CloseAll;
  FSelected := nil;
  InitiateActions(Items);
  W := PrepareWindow(0);
  Size := W.LoadItems(Items);
  Pl := PPGPlacePopup(Anchor, Size.cx, Size.cy, Side, W.MonitorWorkArea(Anchor), AlignEnd, True);
  W.FScrollable := Pl.Clipped;
  FOpenCount := 1;
  FActive := True;
  GActiveLoop := Self;
  StartHooks;
  W.PopupAt(Pl.Bounds, Pl.Side, AnimationMs);
  W.NotifyMenuEvent(EVENT_SYSTEM_MENUPOPUPSTART);
  if FShowAccelerators then
    W.HotFirst;
end;

procedure TPPGMenuLoop.OpenSubmenu(Window: TPPGMenuWindow; Index: Integer;
  SelectFirst: Boolean);
var
  It: TMenuItem;
  W: TPPGMenuWindow;
  Size: TSize;
  Anchor: TRect;
  Pl: TPPGPlacement;
  Side: TPPGPopupSide;
  P: TPoint;
begin
  if (Window = nil) or (Index < 0) or (Index >= Window.ItemCount) then
    Exit;
  It := Window.Item(Index);
  if not It.Enabled or (It.Count = 0) then
    Exit;
  FDelay.Stop;
  FPendingWindow := nil;
  // Schon offen?
  if (FOpenCount > Window.Level + 1) and (FWindows[Window.Level + 1].ParentItem = It) then
  begin
    if SelectFirst then
      FWindows[Window.Level + 1].HotFirst;
    Exit;
  end;
  CloseFrom(Window.Level + 1);
  Window.SetHot(Index);
  // Ein Eintrag mit OnClick und Untermenue: VCL ruft OnClick beim Oeffnen
  It.Click;
  // OnClick kann die Schleife beendet haben (Dialog, CloseAll) oder das
  // Untermenue geleert haben: dann kein Fenster ohne Hooks oeffnen
  if not FActive or (It.Count = 0) then
    Exit;
  InitiateActions(It);
  W := PrepareWindow(Window.Level + 1);
  Size := W.LoadItems(It);
  Anchor := Window.ItemRect(Index);
  P := Window.ClientToScreen(Point(0, 0));
  OffsetRect(Anchor, P.X, P.Y);
  // Leicht ueberlappend, wie Windows (Rahmen an Rahmen)
  InflateRect(Anchor, -PPGScale(2, Window.ScalePPI), PPGScale(4, Window.ScalePPI));
  if FBiDiMode = bdRightToLeft then
    Side := ppsLeft
  else
    Side := ppsRight;
  Pl := PPGPlacePopup(Anchor, Size.cx, Size.cy, Side, W.MonitorWorkArea(Anchor), False, False);
  if Pl.Bounds.Bottom - Pl.Bounds.Top < Size.cy then
    W.FScrollable := True
  else
    W.FScrollable := False;
  FOpenCount := Window.Level + 2;
  W.PopupAt(Pl.Bounds, ppsBelow, 0);
  W.NotifyMenuEvent(EVENT_SYSTEM_MENUPOPUPSTART);
  if SelectFirst then
    W.HotFirst;
end;

procedure TPPGMenuLoop.CloseFrom(Level: Integer);
var
  I: Integer;
begin
  if Level < 0 then
    Level := 0;
  for I := FOpenCount - 1 downto Level do
  begin
    FWindows[I].SetHot(-1);
    FWindows[I].FScrollDir := 0;
    FWindows[I].FScrollAnim.Stop;
    if FWindows[I].IsOpen then
    begin
      FWindows[I].NotifyMenuEvent(EVENT_SYSTEM_MENUPOPUPEND);
      FWindows[I].ClosePopup;
    end;
  end;
  if FOpenCount > Level then
    FOpenCount := Level;
end;

procedure TPPGMenuLoop.Finish(Escaped: Boolean);
var
  WasActive: Boolean;
begin
  FCloseOnKeyUp := False;
  WasActive := FActive;
  FDelay.Stop;
  FPendingWindow := nil;
  CloseFrom(0);
  FActive := False;
  StopHooks;
  if GActiveLoop = Self then
    GActiveLoop := nil;
  if WasActive then
  begin
    Application.Hint := '';
    if FBar <> nil then
      FBar.MenuBarClosed(Escaped);
    if Assigned(FOnClosed) then
      FOnClosed(Self);
  end;
end;

procedure TPPGMenuLoop.CloseAll;
begin
  Finish(False);
end;

procedure TPPGMenuLoop.Execute(Item: TMenuItem);
begin
  if (Item = nil) or not Item.Enabled or (Item.Count > 0) then
    Exit;
  FSelected := Item;
  Finish(False);
  // Wie die VCL: der Klick kommt nach dem Schliessen ueber die Nachrichtenschleife
  if Executor <> nil then
    Executor.Post(Item);
end;

procedure TPPGMenuLoop.HoverItem(Window: TPPGMenuWindow; Index: Integer);
var
  Sub: TPPGMenuWindow;
begin
  // Untermenue oeffnen bzw. ein anderes schliessen erst nach der
  // System-Verzoegerung: diagonal zum offenen Untermenue laufende Maus
  // (ueber andere Eintraege) schliesst es so nicht (Gnadenzeit)
  Sub := nil;
  if FOpenCount > Window.Level + 1 then
    Sub := FWindows[Window.Level + 1];
  if (Sub <> nil) and (Sub.ParentItem = Window.Item(Index)) then
  begin
    FDelay.Stop;
    FPendingWindow := nil;
    Exit;
  end;
  FPendingWindow := Window;
  FPendingIndex := Index;
  FDelay.Jump(0);
  FDelay.AnimateTo(1, MenuShowDelay, ekLinear);
end;

procedure TPPGMenuLoop.DelayStep(Sender: TObject);
var
  W: TPPGMenuWindow;
  I: Integer;
begin
  if FDelay.Running or (FPendingWindow = nil) then
    Exit;
  W := FPendingWindow;
  I := FPendingIndex;
  FPendingWindow := nil;
  if not FActive or (W.Level >= FOpenCount) or (W.Hot <> I) then
    Exit;
  if W.Item(I).Count > 0 then
    OpenSubmenu(W, I, False)
  else
    CloseFrom(W.Level + 1);
end;

function TPPGMenuLoop.TopWindow: TPPGMenuWindow;
begin
  if FOpenCount > 0 then
    Result := FWindows[FOpenCount - 1]
  else
    Result := nil;
end;

function TPPGMenuLoop.OpenCount: Integer;
begin
  Result := FOpenCount;
end;

function TPPGMenuLoop.Window(Level: Integer): TPPGMenuWindow;
begin
  Result := FWindows[Level];
end;

function TPPGMenuLoop.HandleKey(Key: Word; Shift: TShiftState): Boolean;
var
  W: TPPGMenuWindow;
  Fwd, Back: Word;
begin
  Result := True;
  W := TopWindow;
  if W = nil then
    Exit(False);
  FShowAccelerators := True;
  if FBiDiMode = bdRightToLeft then
  begin
    Fwd := VK_LEFT;
    Back := VK_RIGHT;
  end
  else
  begin
    Fwd := VK_RIGHT;
    Back := VK_LEFT;
  end;
  case Key of
    VK_UP: W.MoveHot(-1);
    VK_DOWN: W.MoveHot(1);
    VK_HOME: W.HotFirst;
    VK_END: W.HotLast;
    VK_PRIOR: W.ScrollBy(-W.ClientHeight);
    VK_NEXT: W.ScrollBy(W.ClientHeight);
    VK_RETURN:
      if W.Hot >= 0 then
      begin
        if W.Item(W.Hot).Count > 0 then
          OpenSubmenu(W, W.Hot, True)
        else if W.Item(W.Hot).Enabled then
          Execute(W.Item(W.Hot));
      end;
    VK_ESCAPE:
      if W.Level > 0 then
        CloseFrom(W.Level)
      else
        Finish(True);
    VK_MENU, VK_F10:
      Finish(False);
  else
    if Key = Fwd then
    begin
      if (W.Hot >= 0) and (W.Item(W.Hot).Count > 0) and W.Item(W.Hot).Enabled then
        OpenSubmenu(W, W.Hot, True)
      else if FBar <> nil then
        FBar.MenuBarStep(1);
    end
    else if Key = Back then
    begin
      if W.Level > 0 then
        CloseFrom(W.Level)
      else if FBar <> nil then
        FBar.MenuBarStep(-1);
    end;
  end;
  if (W.Hot >= 0) and W.IsOpen then
    W.Invalidate;
end;

function TPPGMenuLoop.HandleChar(Ch: Char): Boolean;
var
  W: TPPGMenuWindow;
  I, N, First, Count, Start: Integer;
  C: Char;
begin
  Result := True;
  W := TopWindow;
  if (W = nil) or (Ch < ' ') then
    Exit(W <> nil);
  C := UpCase(Ch);
  N := W.ItemCount;
  // Mnemonic: eindeutig = ausloesen/oeffnen, mehrfach = reihum hervorheben;
  // ohne & zaehlt wie bei Windows der erste Buchstabe
  First := -1;
  Count := 0;
  for I := 0 to N - 1 do
    if W.IsSelectable(I) and ((HotkeyChar(W.Item(I)) = C) or ((HotkeyChar(W.Item(I)) = #0) and
      (StripHotkey(W.Item(I).Caption) <> '') and
      (UpCase(StripHotkey(W.Item(I).Caption)[1]) = C))) then
    begin
      Inc(Count);
      if First < 0 then
        First := I;
    end;
  if Count = 0 then
  begin
    MessageBeep(0);
    Exit;
  end;
  if Count = 1 then
  begin
    W.SetHot(First);
    if W.Item(First).Count > 0 then
      OpenSubmenu(W, First, True)
    else if W.Item(First).Enabled then
      Execute(W.Item(First));
    Exit;
  end;
  // Mehrfach: naechsten Treffer nach der aktuellen Hervorhebung
  Start := W.Hot;
  for I := 1 to N do
  begin
    First := (Start + I + N) mod N;
    if W.IsSelectable(First) and ((HotkeyChar(W.Item(First)) = C) or
      ((HotkeyChar(W.Item(First)) = #0) and (StripHotkey(W.Item(First).Caption) <> '') and
      (UpCase(StripHotkey(W.Item(First).Caption)[1]) = C))) then
    begin
      W.SetHot(First);
      W.MakeVisible(First);
      Exit;
    end;
  end;
end;

function TPPGMenuLoop.IsMenuWindow(Wnd: HWND): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FOpenCount - 1 do
    if FWindows[I].HandleAllocated and (FWindows[I].Handle = Wnd) then
      Exit(True);
end;

function TPPGMenuLoop.WindowAt(const ScreenPt: TPoint): TPPGMenuWindow;
var
  I: Integer;
  R: TRect;
begin
  Result := nil;
  for I := FOpenCount - 1 downto 0 do
    if FWindows[I].HandleAllocated and GetWindowRect(FWindows[I].Handle, R) and
      PtInRect(R, ScreenPt) then
      Exit(FWindows[I]);
end;

procedure TPPGMenuLoop.Hook(var Msg: TMsg; var Handled: Boolean);
var
  Pt: TPoint;
  W: TPPGMenuWindow;
  Shift: TShiftState;
  Delta: SmallInt;
  Lines: Integer;
begin
  if not FActive or (FOpenCount = 0) then
    Exit;
  case Msg.message of
    WM_KEYDOWN, WM_SYSKEYDOWN:
      begin
        // Alt/F10 schliessen erst beim Loslassen: sonst ginge WM_SYSKEYUP
        // an Windows, und DefWindowProc startet die System-Menueschleife
        if (Msg.wParam = VK_MENU) or (Msg.wParam = VK_F10) then
          FCloseOnKeyUp := True
        else
        begin
          Shift := KeyDataToShiftState(Msg.lParam);
          HandleKey(Word(Msg.wParam), Shift);
        end;
        Handled := True;
      end;
    WM_CHAR, WM_SYSCHAR:
      begin
        HandleChar(Char(Msg.wParam));
        Handled := True;
      end;
    WM_KEYUP, WM_SYSKEYUP:
      begin
        Handled := True;
        if FCloseOnKeyUp and ((Msg.wParam = VK_MENU) or (Msg.wParam = VK_F10)) then
        begin
          FCloseOnKeyUp := False;
          Finish(False);
        end;
      end;
    WM_MOUSEWHEEL:
      begin
        GetCursorPos(Pt);
        W := WindowAt(Pt);
        if (W <> nil) and W.Scrollable then
        begin
          Delta := SmallInt(HiWord(Msg.wParam));
          // Audit 7b: Zeilen aus der Systemeinstellung, Teil-Deltas gesammelt
          Lines := PPGWheelScrollLines;
          if Lines < 0 then
            Lines := Max(1, W.ClientHeight div Max(1, W.LineHeight)); // seitenweise
          W.ScrollBy(-W.WheelSteps(Delta, Lines * W.LineHeight));
        end;
        Handled := True;
      end;
    WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN, WM_XBUTTONDOWN,
    WM_NCLBUTTONDOWN, WM_NCRBUTTONDOWN, WM_NCMBUTTONDOWN, WM_NCXBUTTONDOWN:
      begin
        if IsMenuWindow(Msg.hwnd) then
          Exit;
        // Position zum Zeitpunkt der Nachricht (nicht die aktuelle Maus)
        Pt := Msg.pt;
        if (FBar <> nil) and FBar.MenuBarOwnsPoint(Pt) then
          Exit; // die Leiste entscheidet selbst (umschalten bzw. schliessen)
        // Klick ausserhalb: schliessen und verbrauchen (wie Windows-Menues)
        Finish(False);
        Handled := True;
      end;
  end;
end;

procedure TPPGMenuLoop.AppDeactivate(Sender: TObject);
begin
  Finish(False);
end;

procedure TPPGMenuLoop.RunModal;
begin
  FModal := True;
  try
    while FActive and not Application.Terminated do
      Application.HandleMessage;
  finally
    FModal := False;
  end;
end;

{ TPPGPopupMenu }

procedure TPPGPopupMenu.SetPreset(const Value: string);
begin
  // Audit 5a: wie TPPGCustomControl.SetPreset pruefen
  FPreset := PPGCheckPreset(Self, Value);
end;

destructor TPPGPopupMenu.Destroy;
begin
  if FDestroyedFlag <> nil then
    FDestroyedFlag^ := True;
  if FLoop <> nil then
    FLoop.CloseAll;
  FStyleManager := nil;
  inherited Destroy;
  FreeAndNil(FMenuStyles);
end;

procedure TPPGPopupMenu.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FStyleManager) then
    FStyleManager := nil;
end;

procedure TPPGPopupMenu.SetStyleManager(const Value: TPPGStyleManager);
begin
  if FStyleManager = Value then
    Exit;
  if FStyleManager <> nil then
    FStyleManager.RemoveFreeNotification(Self);
  FStyleManager := Value;
  if FStyleManager <> nil then
    FStyleManager.FreeNotification(Self);
end;

function TPPGPopupMenu.StyleSourceControl: TPPGCustomControl;
var
  C: TWinControl;
begin
  Result := nil;
  if PopupComponent is TPPGCustomControl then
    Exit(TPPGCustomControl(PopupComponent));
  // Ausloeser ist ein VCL-Control: naechstes PPGlow-Control des Formulars
  // liefert Preset und Schrift nicht - dann gilt StyleManager/Preset bzw.
  // Standard; nur ein PPGlow-Eltern-Control wird uebernommen
  if PopupComponent is TControl then
  begin
    C := TControl(PopupComponent).Parent;
    while C <> nil do
    begin
      if C is TPPGCustomControl then
        Exit(TPPGCustomControl(C));
      C := C.Parent;
    end;
  end;
end;

procedure TPPGPopupMenu.Popup(X, Y: Integer);
begin
  PopupAtRect(Rect(X, Y, X, Y));
end;

constructor TPPGPopupMenu.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMenuStyles := TPPGMenuStyles.Create(Self);
end;

procedure TPPGPopupMenu.SetMenuStyles(const Value: TPPGMenuStyles);
begin
  FMenuStyles.Assign(Value);
end;

procedure TPPGPopupMenu.PopupAtRect(const Anchor: TRect; ShowAccelerators: Boolean);
var
  Loop: TPPGMenuLoop;
  AlignEnd: Boolean;
  Destroyed: Boolean;
  OldFlag: PBoolean;
begin
  if csDesigning in ComponentState then
  begin
    inherited Popup(Anchor.Left, Anchor.Bottom);
    Exit;
  end;
  SetPopupPoint(Point(Anchor.Left, Anchor.Bottom));
  DoPopup(Self);
  Loop := TPPGMenuLoop.Create;
  FLoop := Loop;
  Destroyed := False;
  OldFlag := FDestroyedFlag;
  FDestroyedFlag := @Destroyed;
  try
    Loop.StyleSource := StyleSourceControl;
    Loop.StyleManager := FStyleManager;
    Loop.Preset := FPreset;
    Loop.BiDiMode := BiDiMode;
    Loop.Styles := FMenuStyles;
    Loop.OnCustomDrawItem := FOnCustomDrawItem;
    Loop.DrawSender := Self;
    Loop.ShowAccelerators := ShowAccelerators;
    AlignEnd := (Alignment = paRight) <> (BiDiMode = bdRightToLeft);
    Loop.OpenPopup(Items, Anchor, ppsBelow, AlignEnd);
    Loop.RunModal;
  finally
    // RunModal pumpt Nachrichten: das Menue (z.B. mit seinem Besitzer) kann
    // dabei freigegeben worden sein. Dann kein Zugriff mehr auf Self.
    if not Destroyed then
    begin
      FLoop := nil;
      FDestroyedFlag := OldFlag;
    end;
    Loop.Free;
  end;
  if not Destroyed then
    DoClose;
end;

initialization

finalization
  GFinalized := True;
  FreeAndNil(GExecutor);

end.
