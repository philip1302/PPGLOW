unit PPG.TabControl;

{ Reiter-Controls der Suite.

  TPPGCustomTabs - gemeinsame Basis von TPPGTabControl und TPPGPageControl:
  - Reiterleiste (TPPGTabStrip) oben oder unten, darunter bzw. darueber die
    Seite als Container-Flaeche. Der gewaehlte Reiter haengt mit der Seite
    zusammen; ModernFlat zeigt zusaetzlich einen gleitenden Unterstrich.
  - Maus: Klick waehlt (OnChanging kann abbrechen, danach OnChange),
    Schliessen-Knopf (ShowCloseButtons), Blaetterpfeile bei Ueberlauf.
  - Tastatur: Strg+Tab / Strg+Umschalt+Tab / Strg+Bild auf/ab, wenn der
    Fokus im Control liegt (das innerste Reiter-Control gewinnt);
    Links/Rechts/Pos1/Ende, wenn das Control selbst den Fokus hat;
    Accelerator (&) in den Beschriftungen.
  - Designer: Klicks auf die Reiter erreichen das Control (CM_DESIGNHITTEST).
  - Barrierefreiheit: Rolle PAGETABLIST mit virtuellen PAGETAB-Kindern.
  - Wie bei TPageControl loest das Setzen im Code (TabIndex, ActivePage)
    kein OnChanging/OnChange aus.

  TPPGTabControl - wie TTabControl: Tabs (TStrings) + TabIndex; der Inhalt
  wechselt nicht selbst, die Anwendung reagiert in OnChange. Kinder liegen
  direkt im Innenbereich. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.ComCtrls, Vcl.Forms,
  PPG.Types, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Base,
  PPG.Controls.Container, PPG.TabStrip, PPG.CustomDraw;

type
  TPPGTabCloseQueryEvent = procedure(Sender: TObject; Index: Integer;
    var CanClose: Boolean) of object;
  TPPGTabCloseEvent = procedure(Sender: TObject; Index: Integer;
    var Action: TCloseAction) of object;
  /// Wie TDrawTabEvent (OwnerDraw): Inhalt eines Reiters auf Canvas zeichnen.
  TPPGDrawTabEvent = procedure(Control: TObject; TabIndex: Integer; const Rect: TRect;
    Active: Boolean) of object;

  TPPGCustomTabs = class(TPPGCustomContainer, IPPGAccessibleChildren)
  private
    FStrip: TPPGTabStrip;
    FTabPosition: TTabPosition;
    FTabWidth: Integer;
    FTabHeight: Integer;
    FHotTrack: Boolean;
    FShowCloseButtons: Boolean;
    FPressedClose: Integer;
    FOnChange: TNotifyEvent;
    FOnChanging: TTabChangingEvent;
    FTabStyles: TPPGTabStyles;
    FMultiLine: Boolean;
    FRaggedRight: Boolean;
    FScrollOpposite: Boolean;
    FStyle: TTabStyle;
    FOwnerDraw: Boolean;
    FOnDrawTab: TPPGDrawTabEvent;
    FOnCustomDrawItem: TPPGCustomDrawItemEvent;
    FDrawCanvas: TCanvas;
    FInOwnerDraw: Boolean;
    procedure StripChanged(Sender: TObject);
    procedure SetTabStyles(const Value: TPPGTabStyles);
    procedure TabStylesChanged(Sender: TObject);
    procedure SetMultiLine(const Value: Boolean);
    procedure SetRaggedRight(const Value: Boolean);
    procedure SetStyle(const Value: TTabStyle);
    procedure SetOwnerDraw(const Value: Boolean);
    function GetCanvas: TCanvas;
    procedure StripDrawTab(Pos: Integer; const ACanvas: IPPGCanvas; const R: TRect;
      Active: Boolean; var Style: TPPGDrawStyle; var DefaultDraw: Boolean);
    function StripDrawContent(Pos: Integer; const ACanvas: IPPGCanvas; const R: TRect;
      Active: Boolean): Boolean;
    procedure SetTabPosition(const Value: TTabPosition);
    procedure SetTabWidth(const Value: Integer);
    procedure SetTabHeight(const Value: Integer);
    procedure SetHotTrack(const Value: Boolean);
    procedure SetShowCloseButtons(const Value: Boolean);
    function IsBottom: Boolean;
    function IsVertical: Boolean;
    /// ScrollOpposite: Bereich der Reihen auf der Gegenseite (leer = keiner).
    function OppositeRect: TRect;
    procedure SetScrollOpposite(const Value: Boolean);
    function InnermostTabsOf(Wnd: HWND): TPPGCustomTabs;
    procedure CMDialogKey(var Message: TCMDialogKey); message CM_DIALOGKEY;
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
    procedure CMDesignHitTest(var Message: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMBiDiModeChanged(var Message: TMessage); message CM_BIDIMODECHANGED;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure WndProc(var Message: TMessage); override;
    procedure AppearanceUpdated; override;
    procedure ImagesChanged; override;
    procedure AdjustClientRect(var Rect: TRect); override;
    function GetBackgroundColor: TColor; override;
    function ChildSurface(out Body: TRect; out Style: TPPGSurfaceStyle): Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoAccelerator; override;
    function AccRole: Integer; override;
    function AccValue: string; override;
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

    { Erweiterungspunkte der Nachfahren }
    /// Reiter in die Leiste eintragen (Strip.Add; Index = eigener Index).
    procedure FillTabs(Strip: TPPGTabStrip); virtual; abstract;
    function GetActiveTabIndex: Integer; virtual; abstract;
    /// Wechselt den aktiven Reiter (ohne Ereignisse) und ruft ActiveTabChanged.
    procedure SetActiveTabIndex(Index: Integer); virtual; abstract;
    function TabCount: Integer; virtual; abstract;
    /// Reiter sichtbar und waehlbar?
    function TabSelectable(Index: Integer): Boolean; virtual; abstract;
    /// Schliessen-Knopf: Nachfahren fragen nach und schliessen.
    procedure CloseTab(Index: Integer); virtual; abstract;
    function CanChange: Boolean; virtual;
    procedure Change; virtual;

    /// Reiterleiste neu aufbauen (Reiter, Texte, Sichtbarkeit geaendert).
    procedure TabsChanged;
    /// Nur neu anordnen (Groesse, Schrift, DPI).
    procedure LayoutTabs;
    /// Nach einem Wechsel: Unterstrich, Neuzeichnen, Screenreader.
    procedure ActiveTabChanged(Animate: Boolean);
    /// Wahl durch den Anwender: OnChanging, Wechsel, OnChange.
    function SelectTabByUser(Index: Integer): Boolean;
    /// Naechster waehlbarer Reiter; Wrap = am Ende von vorn (Strg+Tab), sonst
    /// stehen bleiben (Pfeiltasten, wie Windows).
    procedure SelectAdjacentTab(GoForward, Wrap: Boolean);
    function StripRect: TRect;
    function PageRect: TRect;
    function PageStyle: TPPGSurfaceStyle;
    function TabRenderer: IPPGTabRenderer;
    /// Aenderungen im Designer melden (z.B. Seitenwechsel per Klick).
    procedure DesignerModified;

    property HotTrack: Boolean read FHotTrack write SetHotTrack default True;
    property ShowCloseButtons: Boolean read FShowCloseButtons write SetShowCloseButtons default False;
    property TabHeight: Integer read FTabHeight write SetTabHeight default 0;
    property TabPosition: TTabPosition read FTabPosition write SetTabPosition default tpTop;
    property TabWidth: Integer read FTabWidth write SetTabWidth default 0;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnChanging: TTabChangingEvent read FOnChanging write FOnChanging;
    /// Bereiche der Reiterleiste (Reiter, Hover, gewaehlt, Leiste, Unterstrich).
    property TabStyles: TPPGTabStyles read FTabStyles write SetTabStyles;
    /// Wie TPageControl: mehrere Reihen statt Blaetterpfeilen.
    property MultiLine: Boolean read FMultiLine write SetMultiLine default False;
    /// Mit MultiLine: Reihen nicht auf volle Breite strecken.
    property RaggedRight: Boolean read FRaggedRight write SetRaggedRight default False;
    /// Mit MultiLine: Reihen zwischen dem gewaehlten Reiter und der Seite wechseln auf
    /// die Gegenseite (wie TPageControl.ScrollOpposite); nur oben/unten.
    property ScrollOpposite: Boolean read FScrollOpposite write SetScrollOpposite default False;
    /// Reiter, Knoepfe oder flache Knoepfe (wie TTabControl.Style).
    property Style: TTabStyle read FStyle write SetStyle default tsTabs;
    /// Mit OnDrawTab zeichnet die Anwendung den Inhalt der Reiter.
    property OwnerDraw: Boolean read FOwnerDraw write SetOwnerDraw default False;
    property OnDrawTab: TPPGDrawTabEvent read FOnDrawTab write FOnDrawTab;
    /// Vor dem Zeichnen jedes Reiters: Style anpassen oder selbst zeichnen.
    property OnCustomDrawItem: TPPGCustomDrawItemEvent read FOnCustomDrawItem write FOnCustomDrawItem;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Reiter unter dem Punkt (Client-Koordinaten), -1 = keiner.
    function IndexOfTabAt(X, Y: Integer): Integer;
    /// Rechteck eines Reiters, leer = nicht sichtbar (Ueberlauf, TabVisible).
    function TabRect(Index: Integer): TRect;
    /// Innenbereich fuer Kinder bzw. Seiten (wie TCustomTabControl.DisplayRect).
    function DisplayRect: TRect;
    /// Flaechenfarbe der Seite (fuer TabSheets und eigene Kinder).
    function PageColor: TColor;
    /// Naechsten waehlbaren Reiter waehlen (wie Strg+Tab).
    procedure SelectNextTab(GoForward: Boolean);
    property Strip: TPPGTabStrip read FStrip;
    /// Waehrend OnDrawTab: Canvas des Reiters (wie TTabControl.Canvas).
    property Canvas: TCanvas read GetCanvas;
  end;

  TPPGCustomTabControl = class(TPPGCustomTabs)
  private
    FTabs: TStringList;
    FTabIndex: Integer;
    FLoadedTabIndex: Integer;
    FOnGetImageIndex: TTabGetImageEvent;
    FOnCloseQuery: TPPGTabCloseQueryEvent;
    FOnClose: TPPGTabCloseEvent;
    function GetTabs: TStrings;
    procedure SetTabs(const Value: TStrings);
    procedure SetTabIndex(const Value: Integer);
    procedure TabsListChanged(Sender: TObject);
  protected
    procedure Loaded; override;
    procedure FillTabs(Strip: TPPGTabStrip); override;
    function GetActiveTabIndex: Integer; override;
    procedure SetActiveTabIndex(Index: Integer); override;
    function TabCount: Integer; override;
    function TabSelectable(Index: Integer): Boolean; override;
    procedure CloseTab(Index: Integer); override;
    function GetImageIndex(TabIndex: Integer): Integer; virtual;
    property Tabs: TStrings read GetTabs write SetTabs;
    property TabIndex: Integer read FTabIndex write SetTabIndex default -1;
    property OnClose: TPPGTabCloseEvent read FOnClose write FOnClose;
    property OnCloseQuery: TPPGTabCloseQueryEvent read FOnCloseQuery write FOnCloseQuery;
    property OnGetImageIndex: TTabGetImageEvent read FOnGetImageIndex write FOnGetImageIndex;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TPPGTabControl = class(TPPGCustomTabControl)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property ShowCloseButtons;
    property HighContrastSupport;
    property TabStyles;
    { wie TTabControl }
    property MultiLine;
    property OwnerDraw;
    property RaggedRight;
    property ScrollOpposite;
    property Style;
    property OnDrawTab;
    property OnCustomDrawItem;
    property Align;
    property Anchors;
    property BiDiMode;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property HotTrack;
    property Images;
    property Padding;
    property ParentBiDiMode;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabHeight;
    property TabOrder;
    property TabPosition;
    property Tabs;
    property TabIndex;
    property TabStop default True;
    property TabWidth;
    property Visible;
    property Touch;
    property OnGesture;
    property OnChange;
    property OnChanging;
    property OnClose;
    property OnCloseQuery;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetImageIndex;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

uses
  PPG.Lang,
  System.SysUtils, Winapi.oleacc,
  PPG.Consts, PPG.Appearance, PPG.DpiUtils, PPG.Render.Registry;

type
  TControlAccess = class(TControl);

var
  GMsgTabAction: Cardinal = 0;

{ TPPGCustomTabs }

constructor TPPGCustomTabs.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption];
  FStrip := TPPGTabStrip.Create;
  FStrip.OnChange := StripChanged;
  FHotTrack := True;
  FPressedClose := -1;
  FTabStyles := TPPGTabStyles.Create(Self);
  FTabStyles.OnChange := TabStylesChanged;
  FDrawCanvas := TCanvas.Create;
  Width := 289;
  Height := 193;
  TabStop := True;
  if GMsgTabAction = 0 then
    GMsgTabAction := RegisterWindowMessage('PPGlow.TabAction');
end;

destructor TPPGCustomTabs.Destroy;
begin
  if FStrip <> nil then
    FStrip.OnChange := nil;
  inherited Destroy;
  FreeAndNil(FStrip); // nach inherited: Kinder melden sich beim Zerstoeren noch ab
  FreeAndNil(FDrawCanvas);
  FreeAndNil(FTabStyles);
end;

procedure TPPGCustomTabs.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Auch ohne csAcceptsControls (PageControl): Kinder nicht uebermalen,
  // Tab-Navigation in die Seiten
  Params.Style := Params.Style or WS_CLIPCHILDREN;
  Params.ExStyle := Params.ExStyle or WS_EX_CONTROLPARENT;
end;

procedure TPPGCustomTabs.Loaded;
begin
  inherited Loaded;
  TabsChanged;
end;

procedure TPPGCustomTabs.Resize;
begin
  inherited Resize;
  LayoutTabs;
end;

procedure TPPGCustomTabs.AppearanceUpdated;
begin
  inherited AppearanceUpdated;
  LayoutTabs;
end;

procedure TPPGCustomTabs.StripChanged(Sender: TObject);
begin
  Invalidate;
end;

function TPPGCustomTabs.IsBottom: Boolean;
begin
  // senkrecht: True = Leiste rechts
  Result := FTabPosition in [tpBottom, tpRight];
end;

function TPPGCustomTabs.IsVertical: Boolean;
begin
  Result := FTabPosition in [tpLeft, tpRight];
end;

function TPPGCustomTabs.OppositeRect: TRect;
var
  H: Integer;
begin
  Result := Rect(0, 0, 0, 0);
  if (FStrip = nil) or IsVertical or not FScrollOpposite or not FMultiLine then
    Exit;
  H := FStrip.OppositeHeight;
  if H <= 0 then
    Exit;
  if IsBottom then
    Result := Rect(0, 0, Width, H)
  else
    Result := Rect(0, Height - H, Width, Height);
end;

procedure TPPGCustomTabs.SetScrollOpposite(const Value: Boolean);
begin
  if FScrollOpposite <> Value then
  begin
    FScrollOpposite := Value;
    LayoutTabs;
  end;
end;

function TPPGCustomTabs.StripRect: TRect;
var
  H: Integer;
begin
  if IsVertical then
  begin
    // Leiste links bzw. rechts ueber die ganze Hoehe
    H := FStrip.StripWidth;
    if (FStrip.Count = 0) and not (csDesigning in ComponentState) then
      H := 0;
    if H > Width then
      H := Width;
    if IsBottom then
      Result := Rect(Width - H, 0, Width, Height)
    else
      Result := Rect(0, 0, H, Height);
    Exit;
  end;
  // Width/Height statt ClientRect: kein Fensterhandle im Konstruktor erzwingen
  H := FStrip.StripHeight;
  // Keine sichtbaren Reiter (wie TPageControl): keine Leiste
  if (FStrip.Count = 0) and not (csDesigning in ComponentState) then
    H := 0;
  if H > Height then
    H := Height;
  if IsBottom then
    Result := Rect(0, Height - H, Width, Height)
  else
    Result := Rect(0, 0, Width, H);
end;

function TPPGCustomTabs.PageRect: TRect;
var
  S, O: TRect;
begin
  S := StripRect;
  if IsVertical then
  begin
    if IsBottom then
      Result := Rect(0, 0, S.Left, Height)
    else
      Result := Rect(S.Right, 0, Width, Height);
    Exit;
  end;
  O := OppositeRect;
  if IsBottom then
    Result := Rect(0, O.Bottom, Width, S.Top)
  else
  begin
    Result := Rect(0, S.Bottom, Width, Height);
    if not IsRectEmpty(O) then
      Result.Bottom := O.Top;
  end;
end;

function TPPGCustomTabs.DisplayRect: TRect;
begin
  Result := PageRect;
  AdjustClientRect(Result);
end;

procedure TPPGCustomTabs.AdjustClientRect(var Rect: TRect);
var
  D: Integer;
begin
  Rect := PageRect;
  D := ContentInset;
  InflateRect(Rect, -D, -D);
  if Rect.Right < Rect.Left then
    Rect.Right := Rect.Left;
  if Rect.Bottom < Rect.Top then
    Rect.Bottom := Rect.Top;
end;

procedure TPPGCustomTabs.LayoutTabs;
begin
  if FStrip = nil then
    Exit;
  FStrip.Font := Font;
  FStrip.Images := Images;
  FStrip.PPI := ScalePPI;
  FStrip.TabWidth := FTabWidth;
  FStrip.TabHeight := FTabHeight;
  FStrip.ShowClose := FShowCloseButtons;
  FStrip.Bottom := IsBottom;
  FStrip.Vertical := IsVertical;
  FStrip.ScrollOpposite := FScrollOpposite;
  FStrip.RightToLeft := UseRightToLeftAlignment;
  FStrip.MultiLine := FMultiLine;
  FStrip.RaggedRight := FRaggedRight;
  FStrip.ButtonStyle := TPPGTabButtonStyle(Ord(FStyle));
  FStrip.AvailWidth := Width;
  FStrip.OppositeRect := OppositeRect;
  FStrip.Layout(StripRect);
  if not (csLoading in ComponentState) and not (csDestroying in ComponentState) then
    Realign;
  Invalidate;
end;

procedure TPPGCustomTabs.ImagesChanged;
begin
  inherited ImagesChanged;
  // Die Leiste haelt eine Kopie des Zeigers. Nach der Freigabe der Liste
  // (Images ist dann schon nil) darf sie nicht mehr darauf zeigen.
  if FStrip = nil then
    Exit;
  FStrip.Images := Images;
  if not (csDestroying in ComponentState) then
    LayoutTabs;
end;

procedure TPPGCustomTabs.TabsChanged;
begin
  if (FStrip = nil) or (csLoading in ComponentState) or
    (csDestroying in ComponentState) then
    Exit;
  FStrip.Clear;
  FillTabs(FStrip);
  LayoutTabs;
  FStrip.Select(GetActiveTabIndex, False, 0);
  Invalidate;
end;

procedure TPPGCustomTabs.ActiveTabChanged(Animate: Boolean);
var
  Duration: Cardinal;
  Pos: Integer;
begin
  if (FStrip = nil) or (csLoading in ComponentState) then
    Exit;
  Duration := 0;
  if Animate and Animation.EffectiveEnabled and HandleAllocated and
    IsWindowVisible(Handle) and not (csDesigning in ComponentState) then
    Duration := Animation.Duration;
  FStrip.Select(GetActiveTabIndex, Duration > 0, Duration);
  // ScrollOpposite: andere Reihe gewaehlt = andere Aufteilung der Reihen und Seite
  if FScrollOpposite and FMultiLine and not IsVertical then
    LayoutTabs;
  Invalidate;
  Pos := FStrip.Selected;
  if Pos >= 0 then
  begin
    NotifyAccessibilityChild(EVENT_OBJECT_SELECTION, Pos + 1);
    if Focused then
      NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, Pos + 1);
  end;
end;

function TPPGCustomTabs.CanChange: Boolean;
begin
  Result := True;
  if Assigned(FOnChanging) then
    FOnChanging(Self, Result);
end;

procedure TPPGCustomTabs.Change;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TPPGCustomTabs.SelectTabByUser(Index: Integer): Boolean;
begin
  Result := False;
  if (Index < 0) or (Index >= TabCount) or (Index = GetActiveTabIndex) or
    not TabSelectable(Index) then
    Exit;
  if not CanChange then
    Exit;
  SetActiveTabIndex(Index);
  Result := GetActiveTabIndex = Index;
  if Result then
  begin
    DesignerModified;
    Change;
  end;
end;

procedure TPPGCustomTabs.SelectNextTab(GoForward: Boolean);
begin
  SelectAdjacentTab(GoForward, True);
end;

procedure TPPGCustomTabs.SelectAdjacentTab(GoForward, Wrap: Boolean);
var
  N, I, Start, Idx: Integer;
begin
  N := TabCount;
  if N = 0 then
    Exit;
  Start := GetActiveTabIndex;
  for I := 1 to N do
  begin
    if GoForward then
      Idx := Start + I
    else
      Idx := Start - I;
    if not Wrap and ((Idx < 0) or (Idx >= N)) then
      Exit;
    Idx := (Idx + N * 2) mod N;
    if (Idx <> Start) and TabSelectable(Idx) then
    begin
      SelectTabByUser(Idx);
      Exit;
    end;
  end;
end;

procedure TPPGCustomTabs.DesignerModified;
var
  Form: TCustomForm;
begin
  if not (csDesigning in ComponentState) then
    Exit;
  Form := GetParentForm(Self);
  if (Form <> nil) and (Form.Designer <> nil) then
    Form.Designer.Modified;
end;

function TPPGCustomTabs.IndexOfTabAt(X, Y: Integer): Integer;
begin
  if FStrip.HitTest(X, Y, Result) = thNone then
    Result := -1;
end;

function TPPGCustomTabs.TabRect(Index: Integer): TRect;
begin
  Result := FStrip.TabRectAt(FStrip.PosOf(Index));
end;

{ ---- Properties ---- }

procedure TPPGCustomTabs.SetTabPosition(const Value: TTabPosition);
begin
  if FTabPosition <> Value then
  begin
    FTabPosition := Value;
    LayoutTabs;
  end;
end;

procedure TPPGCustomTabs.SetTabWidth(const Value: Integer);
begin
  FTabWidth := PPGCheckRange(Self, 'TabWidth', Value, 0, 1000);
  LayoutTabs;
end;

procedure TPPGCustomTabs.SetTabHeight(const Value: Integer);
begin
  FTabHeight := PPGCheckRange(Self, 'TabHeight', Value, 0, 1000);
  LayoutTabs;
end;

procedure TPPGCustomTabs.SetHotTrack(const Value: Boolean);
begin
  if FHotTrack <> Value then
  begin
    FHotTrack := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomTabs.SetShowCloseButtons(const Value: Boolean);
begin
  if FShowCloseButtons <> Value then
  begin
    FShowCloseButtons := Value;
    LayoutTabs;
  end;
end;

procedure TPPGCustomTabs.SetTabStyles(const Value: TPPGTabStyles);
begin
  FTabStyles.Assign(Value);
end;

procedure TPPGCustomTabs.TabStylesChanged(Sender: TObject);
begin
  // Schrift-Stile koennen die Reiterbreite aendern
  LayoutTabs;
end;

procedure TPPGCustomTabs.SetMultiLine(const Value: Boolean);
begin
  if FMultiLine <> Value then
  begin
    FMultiLine := Value;
    LayoutTabs;
  end;
end;

procedure TPPGCustomTabs.SetRaggedRight(const Value: Boolean);
begin
  if FRaggedRight <> Value then
  begin
    FRaggedRight := Value;
    LayoutTabs;
  end;
end;

procedure TPPGCustomTabs.SetStyle(const Value: TTabStyle);
begin
  if FStyle <> Value then
  begin
    FStyle := Value;
    LayoutTabs;
  end;
end;

procedure TPPGCustomTabs.SetOwnerDraw(const Value: Boolean);
begin
  if FOwnerDraw <> Value then
  begin
    FOwnerDraw := Value;
    Invalidate;
  end;
end;

function TPPGCustomTabs.GetCanvas: TCanvas;
begin
  if FInOwnerDraw then
    Result := FDrawCanvas
  else
    Result := inherited Canvas;
end;

procedure TPPGCustomTabs.StripDrawTab(Pos: Integer; const ACanvas: IPPGCanvas;
  const R: TRect; Active: Boolean; var Style: TPPGDrawStyle; var DefaultDraw: Boolean);
var
  St: TPPGItemDrawState;
  T: TPPGTabInfo;
begin
  T := FStrip.Tab(Pos);
  St := [];
  if Active then
    Include(St, idsSelected);
  if Pos = FStrip.HotTab then
    Include(St, idsHot);
  if not (Enabled and T.Enabled) then
    Include(St, idsDisabled);
  DefaultDraw := PPGRunCustomDraw(ACanvas, FDrawCanvas, Font, FOnCustomDrawItem, Self,
    T.Index, R, St, Style);
end;

function TPPGCustomTabs.StripDrawContent(Pos: Integer; const ACanvas: IPPGCanvas;
  const R: TRect; Active: Boolean): Boolean;
var
  DC: HDC;
begin
  // OwnerDraw wie TTabControl: Hintergrund ist gezeichnet, den Inhalt zeichnet
  // die Anwendung auf Canvas
  Result := True;
  DC := ACanvas.BeginGdi;
  try
    FDrawCanvas.Handle := DC;
    try
      FDrawCanvas.Font := Font;
      FDrawCanvas.Brush.Style := bsClear;
      FInOwnerDraw := True;
      try
        FOnDrawTab(Self, FStrip.Tab(Pos).Index, R, Active);
      finally
        FInOwnerDraw := False;
      end;
    finally
      FDrawCanvas.Handle := 0;
    end;
  finally
    ACanvas.EndGdi(DC);
  end;
end;

{ ---- Zeichnen ---- }

function TPPGCustomTabs.GetBackgroundColor: TColor;
begin
  // Hinter den Reitern und den Ecken liegt der Parent
  if Parent <> nil then
    Result := TControlAccess(Parent).Color
  else
    Result := Color;
end;

function TPPGCustomTabs.PageStyle: TPPGSurfaceStyle;
begin
  Result := GetContainerStyle(False);
  // Seiten einfarbig: TabSheets und Kinder fuellen sich in derselben Farbe
  Result.ColorTo := Result.Color;
  Result.ColorMirror := Result.Color;
  Result.ColorMirrorTo := Result.Color;
end;

function TPPGCustomTabs.ChildSurface(out Body: TRect; out Style: TPPGSurfaceStyle): Boolean;
begin
  Body := PageRect;
  Style := PageStyle;
  Result := True;
end;

function TPPGCustomTabs.PageColor: TColor;
begin
  Result := PageStyle.Color;
end;

function TPPGCustomTabs.TabRenderer: IPPGTabRenderer;
begin
  if not Supports(Renderer, IPPGTabRenderer, Result) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
      IPPGTabRenderer, Result);
end;

procedure TPPGCustomTabs.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  PS: TPPGSurfaceStyle;
  Info: TPPGTabPaintInfo;
  A: TPPGAppearance;
  PPI: Integer;
  HC: Boolean;
begin
  PPI := ScalePPI;
  PS := PageStyle;
  ContainerRenderer.DrawContainer(ACanvas, PageRect, PS);

  A := EffectiveAppearance;
  HC := HighContrastSupport and PPGIsHighContrast;
  Info.Strip := PS;
  Info.Strip.Color := clNone; // Hintergrund (Parent) ist schon gezeichnet
  Info.Tab := A.Resolve(vsNormal, PPI, False);
  Info.Tab.TextColor := PS.TextColor;
  Info.HotTab := A.Resolve(vsHot, PPI, False);
  Info.Selected := PS;
  Info.Accent := PPGColorToRGB(A.FocusColor);
  Info.DisabledText := PPGColorToRGB(A.Disabled.TextColor);
  if UseVclStyle or HC then
    Info.HotTab.TextColor := PS.TextColor;
  if UseVclStyle then
    // Deaktiviert-Farbe des Styles ist auf dunklen Seiten kaum lesbar
    Info.DisabledText := PPGBlendColor(PS.TextColor, PS.Color, 0.55);
  if HC then
  begin
    Info.Tab.BorderColor := PS.BorderColor;
    Info.HotTab.BorderColor := PS.BorderColor;
    Info.Accent := PPGColorToRGB(clHighlight);
    Info.DisabledText := PPGColorToRGB(clGrayText);
  end;
  Info.Overlap := PS.BorderWidth;
  Info.HotTrack := FHotTrack and not (csDesigning in ComponentState);
  Info.Focused := FocusVisible;
  Info.ShowAccel := AcceleratorCuesVisible;
  Info.Enabled := Enabled;
  Info.Styles := FTabStyles;
  Info.UseColors := not HC and not UseVclStyle;
  Info.Dark := UseDarkMode;
  Info.OnDrawTab := nil;
  Info.OnDrawContent := nil;
  if Assigned(FOnCustomDrawItem) then
    Info.OnDrawTab := StripDrawTab;
  if FOwnerDraw and Assigned(FOnDrawTab) then
    Info.OnDrawContent := StripDrawContent;
  FStrip.Paint(ACanvas, TabRenderer, Info);
end;

{ ---- Maus ---- }

procedure TPPGCustomTabs.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button <> mbLeft) or not Enabled then
    Exit;
  case FStrip.HitTest(X, Y, Idx) of
    thPrev:
      FStrip.Scroll(-1);
    thNext:
      FStrip.Scroll(1);
    thClose:
      FPressedClose := Idx;
    thTab:
      begin
        // Wie TPageControl: Klick auf einen Reiter fokussiert das Control
        if TabStop and CanFocus and not Focused and not (csDesigning in ComponentState) then
          SetFocus;
        SelectTabByUser(Idx);
      end;
  end;
end;

procedure TPPGCustomTabs.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if FStrip.UpdateHot(X, Y) then
    Invalidate;
end;

procedure TPPGCustomTabs.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Idx, Pressed: Integer;
begin
  Pressed := FPressedClose;
  FPressedClose := -1;
  inherited MouseUp(Button, Shift, X, Y);
  if (Button = mbLeft) and (Pressed >= 0) and (FStrip.HitTest(X, Y, Idx) = thClose) and
    (Idx = Pressed) then
    CloseTab(Idx);
end;

procedure TPPGCustomTabs.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FStrip.ClearHot then
    Invalidate;
end;

procedure TPPGCustomTabs.CMDesignHitTest(var Message: TCMDesignHitTest);
var
  Idx: Integer;
begin
  // Im Designer: Klicks auf Reiter und Pfeile gehen an das Control
  if FStrip.HitTest(Message.XPos, Message.YPos, Idx) in [thTab, thPrev, thNext] then
    Message.Result := 1
  else
    Message.Result := 0;
end;

{ ---- Tastatur ---- }

procedure TPPGCustomTabs.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TPPGCustomTabs.KeyDown(var Key: Word; Shift: TShiftState);
var
  Fwd: Boolean;
  I, N: Integer;
begin
  inherited KeyDown(Key, Shift);
  if Shift * [ssCtrl, ssAlt] <> [] then
    Exit;
  N := TabCount;
  case Key of
    VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN:
      begin
        Fwd := (Key = VK_RIGHT) or (Key = VK_DOWN);
        if UseRightToLeftAlignment and ((Key = VK_LEFT) or (Key = VK_RIGHT)) then
          Fwd := not Fwd;
        SelectAdjacentTab(Fwd, False);
        Key := 0;
      end;
    VK_HOME:
      begin
        for I := 0 to N - 1 do
          if TabSelectable(I) then
          begin
            SelectTabByUser(I);
            Break;
          end;
        Key := 0;
      end;
    VK_END:
      begin
        for I := N - 1 downto 0 do
          if TabSelectable(I) then
          begin
            SelectTabByUser(I);
            Break;
          end;
        Key := 0;
      end;
  end;
end;

function TPPGCustomTabs.InnermostTabsOf(Wnd: HWND): TPPGCustomTabs;
var
  C: TWinControl;
begin
  Result := nil;
  C := FindControl(Wnd);
  while (C <> nil) and not (C is TPPGCustomTabs) do
    C := C.Parent;
  if C <> nil then
    Result := TPPGCustomTabs(C);
end;

procedure TPPGCustomTabs.CMDialogKey(var Message: TCMDialogKey);
var
  Fwd: Boolean;
begin
  // Strg+Tab usw. - nur das innerste Reiter-Control mit dem Fokus reagiert
  if (GetKeyState(VK_CONTROL) < 0) and (GetKeyState(VK_MENU) >= 0) and
    ((Message.CharCode = VK_TAB) or (Message.CharCode = VK_PRIOR) or
    (Message.CharCode = VK_NEXT)) and not (csDesigning in ComponentState) and
    HandleAllocated and (InnermostTabsOf(GetFocus) = Self) then
  begin
    if Message.CharCode = VK_TAB then
      Fwd := GetKeyState(VK_SHIFT) >= 0
    else
      Fwd := Message.CharCode = VK_NEXT;
    SelectNextTab(Fwd);
    Message.Result := 1;
    Exit;
  end;
  inherited;
end;

procedure TPPGCustomTabs.CMDialogChar(var Message: TCMDialogChar);
var
  I: Integer;
  T: TPPGTabInfo;
begin
  if Enabled and not (csDesigning in ComponentState) then
    for I := 0 to FStrip.Count - 1 do
    begin
      T := FStrip.Tab(I);
      if T.Enabled and IsAccel(Message.CharCode, T.Caption) and CanFocus then
      begin
        SelectTabByUser(T.Index);
        if not Focused then
          SetFocus;
        Message.Result := 1;
        Exit;
      end;
    end;
  inherited;
end;

procedure TPPGCustomTabs.DoAccelerator;
begin
  // Kein eigener Accelerator (Caption wird nicht angezeigt)
end;

procedure TPPGCustomTabs.CMFontChanged(var Message: TMessage);
begin
  inherited;
  LayoutTabs;
end;

procedure TPPGCustomTabs.CMBiDiModeChanged(var Message: TMessage);
begin
  inherited;
  LayoutTabs;
end;

procedure TPPGCustomTabs.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TPPGCustomTabs.WndProc(var Message: TMessage);
begin
  if (GMsgTabAction <> 0) and (Message.Msg = GMsgTabAction) then
  begin
    // Aus AccChildDoDefault gepostet (ausserhalb des COM-Aufrufs)
    if Enabled then
      SelectTabByUser(Integer(Message.WParam));
    Exit;
  end;
  inherited WndProc(Message);
end;

{ ---- Barrierefreiheit ---- }

function TPPGCustomTabs.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_PAGETABLIST;
end;

function TPPGCustomTabs.AccValue: string;
begin
  if FStrip.Selected >= 0 then
    Result := PPGAccStripHotkey(FStrip.Tab(FStrip.Selected).Caption)
  else
    Result := '';
end;

function TPPGCustomTabs.AccChildCount: Integer;
begin
  Result := FStrip.Count;
end;

function TPPGCustomTabs.AccChildName(Id: Integer): string;
begin
  Result := PPGAccStripHotkey(FStrip.Tab(Id - 1).Caption);
end;

function TPPGCustomTabs.AccChildRole(Id: Integer): Integer;
begin
  Result := ROLE_SYSTEM_PAGETAB;
end;

function TPPGCustomTabs.AccChildState(Id: Integer): Integer;
var
  Pos: Integer;
begin
  Pos := Id - 1;
  Result := STATE_SYSTEM_SELECTABLE or STATE_SYSTEM_FOCUSABLE;
  if Pos = FStrip.Selected then
  begin
    Result := Result or STATE_SYSTEM_SELECTED;
    if Focused then
      Result := Result or STATE_SYSTEM_FOCUSED;
  end;
  if not (Enabled and FStrip.Tab(Pos).Enabled) then
    Result := Result or STATE_SYSTEM_UNAVAILABLE;
  if IsRectEmpty(FStrip.TabRectAt(Pos)) then
    Result := Result or STATE_SYSTEM_INVISIBLE or STATE_SYSTEM_OFFSCREEN;
end;

function TPPGCustomTabs.AccChildRect(Id: Integer): TRect;
begin
  Result := FStrip.TabRectAt(Id - 1);
end;

function TPPGCustomTabs.AccChildAt(X, Y: Integer): Integer;
var
  Idx: Integer;
begin
  if FStrip.HitTest(X, Y, Idx) in [thTab, thClose] then
    Result := FStrip.PosOf(Idx) + 1
  else
    Result := 0;
end;

function TPPGCustomTabs.AccChildDefaultAction(Id: Integer): string;
begin
  Result := PPGStr(@SPPGAccSelect);
end;

procedure TPPGCustomTabs.AccChildDoDefault(Id: Integer);
begin
  if HandleAllocated then
    PostMessage(Handle, GMsgTabAction, WPARAM(FStrip.Tab(Id - 1).Index), 0);
end;

function TPPGCustomTabs.AccFocusedChild: Integer;
begin
  if Focused and (FStrip.Selected >= 0) then
    Result := FStrip.Selected + 1
  else
    Result := 0;
end;

function TPPGCustomTabs.AccSelectedChild: Integer;
begin
  Result := FStrip.Selected + 1;
end;

{ TPPGCustomTabControl }

constructor TPPGCustomTabControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTabs := TStringList.Create;
  FTabs.OnChange := TabsListChanged;
  FTabIndex := -1;
  FLoadedTabIndex := -2;
end;

destructor TPPGCustomTabControl.Destroy;
begin
  if FTabs <> nil then
    FTabs.OnChange := nil;
  inherited Destroy;
  FreeAndNil(FTabs);
end;

procedure TPPGCustomTabControl.Loaded;
begin
  if FLoadedTabIndex >= -1 then
  begin
    if FLoadedTabIndex < FTabs.Count then
      FTabIndex := FLoadedTabIndex;
    FLoadedTabIndex := -2;
  end;
  inherited Loaded; // baut die Leiste auf
end;

function TPPGCustomTabControl.GetTabs: TStrings;
begin
  Result := FTabs;
end;

procedure TPPGCustomTabControl.SetTabs(const Value: TStrings);
begin
  FTabs.Assign(Value);
end;

procedure TPPGCustomTabControl.TabsListChanged(Sender: TObject);
begin
  if csLoading in ComponentState then
    Exit;
  // Wie TTabControl: der Index bleibt, solange es den Reiter gibt
  if FTabIndex >= FTabs.Count then
    FTabIndex := FTabs.Count - 1;
  if (FTabIndex < 0) and (FTabs.Count > 0) then
    FTabIndex := 0;
  TabsChanged;
end;

procedure TPPGCustomTabControl.SetTabIndex(const Value: Integer);
begin
  if csLoading in ComponentState then
  begin
    FLoadedTabIndex := Value;
    Exit;
  end;
  // Wie TTabControl: ungueltige Werte werden ignoriert
  if (Value < -1) or (Value >= FTabs.Count) or (Value = FTabIndex) then
    Exit;
  FTabIndex := Value;
  ActiveTabChanged(False);
end;

procedure TPPGCustomTabControl.FillTabs(Strip: TPPGTabStrip);
var
  I: Integer;
begin
  for I := 0 to FTabs.Count - 1 do
    Strip.Add(FTabs[I], GetImageIndex(I), True, I);
end;

function TPPGCustomTabControl.GetImageIndex(TabIndex: Integer): Integer;
begin
  // Wie TTabControl: Bild = Reiterindex, per OnGetImageIndex aenderbar
  Result := TabIndex;
  if Assigned(FOnGetImageIndex) then
    FOnGetImageIndex(Self, TabIndex, Result);
end;

function TPPGCustomTabControl.GetActiveTabIndex: Integer;
begin
  Result := FTabIndex;
end;

procedure TPPGCustomTabControl.SetActiveTabIndex(Index: Integer);
begin
  FTabIndex := Index;
  ActiveTabChanged(True);
end;

function TPPGCustomTabControl.TabCount: Integer;
begin
  Result := FTabs.Count;
end;

function TPPGCustomTabControl.TabSelectable(Index: Integer): Boolean;
begin
  Result := (Index >= 0) and (Index < FTabs.Count);
end;

procedure TPPGCustomTabControl.CloseTab(Index: Integer);
var
  CanClose: Boolean;
  Action: TCloseAction;
  WasActive: Boolean;
  OldCount: Integer;
  OldText: string;

  // Hat ein Ereignis die Reiter selbst geaendert (z.B. den Reiter schon
  // geloescht), gehoert Index nicht mehr zum geklickten Reiter.
  function TabsUnchanged: Boolean;
  begin
    Result := (FTabs.Count = OldCount) and (FTabs[Index] = OldText);
  end;

begin
  if (Index < 0) or (Index >= FTabs.Count) then
    Exit;
  OldCount := FTabs.Count;
  OldText := FTabs[Index];
  CanClose := True;
  if Assigned(FOnCloseQuery) then
    FOnCloseQuery(Self, Index, CanClose);
  if not CanClose or not TabsUnchanged then
    Exit;
  Action := caFree;
  if Assigned(FOnClose) then
    FOnClose(Self, Index, Action);
  if (Action = caNone) or not TabsUnchanged then
    Exit;
  WasActive := Index = FTabIndex;
  // Nachbar waehlen: der folgende Reiter rueckt nach, sonst der vorige
  if Index < FTabIndex then
    Dec(FTabIndex);
  FTabs.Delete(Index); // TabsListChanged begrenzt den Index
  if WasActive then
    Change;
end;

end.
