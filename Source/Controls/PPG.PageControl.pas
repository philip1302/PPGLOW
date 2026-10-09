unit PPG.PageControl;

{ TPPGPageControl + TPPGTabSheet - Seiten mit Reitern, DFM-kompatibel zu
  TPageControl/TTabSheet (ActivePage, TabPosition, TabWidth, TabHeight,
  HotTrack, Images; Seiten mit Caption, ImageIndex, PageIndex, TabVisible).

  - Seitenliste: Jede TPPGTabSheet, deren Parent das PageControl ist, ist
    eine Seite (auch per "Sheet.Parent := PC"). Die Reihenfolge ist die
    Einfuegereihenfolge bzw. PageIndex; GetChildren schreibt sie so in die DFM.
  - Nur die aktive Seite ist sichtbar (csNoDesignVisible: auch im Designer).
  - Wird die aktive Seite entfernt oder ihr Reiter ausgeblendet, wird die
    Nachbarseite aktiv (erst die folgende, sonst die vorige).
  - Lag der Fokus auf der alten Seite, geht er auf die neue (erstes Control).
  - Schliessen-Knopf: OnCloseQuery(Page, CanClose), dann OnClose(Page,
    Action) mit caHide (Reiter ausblenden, Standard), caFree oder caNone.
  - Designer: Klick auf Reiter wechselt die Seite; ein Control auf einer
    verdeckten Seite auswaehlen zeigt diese (ShowControl). Komponenteneditor
    "Neue Seite" usw. in PPG.Reg. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, {$IFDEF PPG_HAS_IMAGENAME}System.UITypes,{$ENDIF} System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.ImgList, Vcl.ComCtrls, Vcl.Forms,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Container, PPG.TabStrip, PPG.TabControl;

type
  TPPGPageControl = class;

  TPPGTabSheet = class(TPPGCustomContainer)
  private
    FImageIndex: TPPGImageIndex;
    FTabVisible: Boolean;
    FTabColor: TColor;
    FTabTextColor: TColor;
    FTabFontStyle: TFontStyles;
    FOnShow: TNotifyEvent;
    FOnHide: TNotifyEvent;
    {$IFDEF PPG_HAS_IMAGENAME}
    FImageName: TImageName;
    {$ENDIF}
    function GetPageControl: TPPGPageControl;
    procedure SetPageControl(const Value: TPPGPageControl);
    function GetPageIndex: Integer;
    procedure SetPageIndex(const Value: Integer);
    function GetTabIndex: Integer;
    procedure SetImageIndex(const Value: TPPGImageIndex);
    procedure SetTabVisible(const Value: Boolean);
    procedure SetTabColor(const Value: TColor);
    procedure SetTabTextColor(const Value: TColor);
    procedure SetTabFontStyle(const Value: TFontStyles);
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    {$IFDEF PPG_HAS_IMAGENAME}
    procedure SetImageName(const Value: TImageName);
    {$ENDIF}
  protected
    function GetBackgroundColor: TColor; override;
    function GetChildBackground(Child: TControl; out ColorTop, ColorBottom: TColor): Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function AccRole: Integer; override;
    procedure DoShow; virtual;
    procedure DoHide; virtual;
  public
    {$IFDEF PPG_HAS_IMAGENAME}
    /// Bildindex aus ImageName neu bestimmen (ruft der Besitzer, wenn sich
    /// seine Images aendern).
    procedure ResolveImageName;
    {$ENDIF}
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property PageControl: TPPGPageControl read GetPageControl write SetPageControl;
    /// Position unter den sichtbaren Reitern (-1 = Reiter ausgeblendet).
    property TabIndex: Integer read GetTabIndex;
  published
    property BorderWidth;
    property Caption;
    property Constraints;
    property DragMode;
    property Enabled;
    property Font;
    property Height stored False;
    property ImageIndex: TPPGImageIndex read FImageIndex write SetImageIndex default -1;
    {$IFDEF PPG_HAS_IMAGENAME}
    /// Bild per Namen (TVirtualImageList, ab 10.4); robust gegen Umsortieren.
    property ImageName: TImageName read FImageName write SetImageName;
    {$ENDIF}
    property Left stored False;
    property Padding;
    property PageIndex: Integer read GetPageIndex write SetPageIndex stored False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    /// Flaeche, Text und zusaetzliche Schriftstile des Reiters (clDefault = Styles).
    property TabColor: TColor read FTabColor write SetTabColor default clDefault;
    property TabTextColor: TColor read FTabTextColor write SetTabTextColor default clDefault;
    property TabFontStyle: TFontStyles read FTabFontStyle write SetTabFontStyle default [];
    property TabVisible: Boolean read FTabVisible write SetTabVisible default True;
    property Top stored False;
    property Width stored False;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnShow: TNotifyEvent read FOnShow write FOnShow;
    property OnStartDrag;
  end;

  TPPGPageCloseQueryEvent = procedure(Sender: TObject; Page: TPPGTabSheet;
    var CanClose: Boolean) of object;
  TPPGPageCloseEvent = procedure(Sender: TObject; Page: TPPGTabSheet;
    var Action: TCloseAction) of object;

  TPPGPageControl = class(TPPGCustomTabs)
  private
    FPages: TList;
    FActivePage: TPPGTabSheet;
    FOnCloseQuery: TPPGPageCloseQueryEvent;
    FOnClose: TPPGPageCloseEvent;
    function GetPage(Index: Integer): TPPGTabSheet;
    function GetPageCount: Integer;
    function GetActivePageIndex: Integer;
    procedure SetActivePageIndex(const Value: Integer);
    procedure SetActivePage(const Value: TPPGTabSheet);
    procedure InsertPage(Page: TPPGTabSheet);
    procedure RemovePage(Page: TPPGTabSheet);
    procedure ChangeActivePage(Page: TPPGTabSheet; Animate: Boolean);
    function NeighbourOf(Page: TPPGTabSheet): TPPGTabSheet;
    procedure CMControlChange(var Message: TCMControlChange); message CM_CONTROLCHANGE;
  protected
    /// Bildnamen der Eintraege neu aufloesen (ImageName).
    procedure ImagesChanged; override;
    procedure Loaded; override;
    procedure SetChildOrder(Child: TComponent; Order: Integer); override;
    procedure ShowControl(AControl: TControl); override;
    procedure FillTabs(Strip: TPPGTabStrip); override;
    function GetActiveTabIndex: Integer; override;
    procedure SetActiveTabIndex(Index: Integer); override;
    function TabCount: Integer; override;
    function TabSelectable(Index: Integer): Boolean; override;
    procedure CloseTab(Index: Integer); override;
    /// Seite hat sich geaendert (Caption, TabVisible, ...): Leiste neu.
    procedure PageChanged(Page: TPPGTabSheet);
    procedure MovePage(Page: TPPGTabSheet; NewIndex: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    /// Naechste bzw. vorige Seite (ringfoermig); CheckTabVisible ueberspringt
    /// ausgeblendete Reiter. nil, wenn es keine gibt.
    function FindNextPage(CurPage: TPPGTabSheet; GoForward, CheckTabVisible: Boolean): TPPGTabSheet;
    /// Wie Strg+Tab (mit OnChanging/OnChange).
    procedure SelectNextPage(GoForward: Boolean; CheckTabVisible: Boolean = True);
    property ActivePageIndex: Integer read GetActivePageIndex write SetActivePageIndex;
    property PageCount: Integer read GetPageCount;
    property Pages[Index: Integer]: TPPGTabSheet read GetPage;
  published
    property ActivePage: TPPGTabSheet read FActivePage write SetActivePage;
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property ShowCloseButton;
    property Styles;
    property MultiLine;
    property OwnerDraw;
    property RaggedRight;
    property ScrollOpposite;
    property Style;
    property HighContrastSupport;
    { wie TPageControl }
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
    property TabStop default True;
    property TabWidth;
    property Visible;
    property Touch;
    property OnGesture;
    property OnChange;
    property OnChanging;
    property OnDrawTab;
    property OnCustomDrawItem;
    property OnClose: TPPGPageCloseEvent read FOnClose write FOnClose;
    property OnClosing: TPPGPageCloseQueryEvent read FOnCloseQuery write FOnCloseQuery;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnClick;
    property OnDblClick;
    property OnMouseWheel;
    property OnMouseActivate;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property Color;
    property ParentColor;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

implementation

uses
  PPG.Controls.Base,
  System.SysUtils, Winapi.oleacc;

{ TPPGTabSheet }

{$IFDEF PPG_HAS_IMAGENAME}
procedure TPPGTabSheet.ResolveImageName;
var
  Imgs: TCustomImageList;
begin
  Imgs := PPGImagesOf(Self);
  // Unbekannter Name: -1 (die Liste kann zur Laufzeit befuellt werden)
  if (FImageName <> '') and (Imgs <> nil) and Imgs.IsImageNameAvailable then
    ImageIndex := Imgs.GetIndexByName(FImageName);
end;

procedure TPPGTabSheet.SetImageName(const Value: TImageName);
begin
  if FImageName = Value then
    Exit;
  FImageName := Value;
  ResolveImageName;
end;
{$ENDIF}


constructor TPPGTabSheet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Wie TTabSheet: nur die aktive Seite ist sichtbar - auch im Designer
  ControlStyle := ControlStyle + [csNoDesignVisible];
  ParentBackground := False;
  Align := alClient;
  Visible := False;
  FImageIndex := -1;
  FTabVisible := True;
  FTabColor := clDefault;
  FTabTextColor := clDefault;
end;

destructor TPPGTabSheet.Destroy;
begin
  // Parent := nil meldet die Seite beim PageControl ab (CM_CONTROLCHANGE)
  if Parent is TPPGPageControl then
    Parent := nil;
  inherited Destroy;
end;

function TPPGTabSheet.GetPageControl: TPPGPageControl;
begin
  if Parent is TPPGPageControl then
    Result := TPPGPageControl(Parent)
  else
    Result := nil;
end;

procedure TPPGTabSheet.SetPageControl(const Value: TPPGPageControl);
begin
  Parent := Value;
end;

function TPPGTabSheet.GetPageIndex: Integer;
begin
  if PageControl <> nil then
    Result := PageControl.FPages.IndexOf(Self)
  else
    Result := -1;
end;

procedure TPPGTabSheet.SetPageIndex(const Value: Integer);
begin
  if PageControl <> nil then
    PageControl.MovePage(Self, Value);
end;

function TPPGTabSheet.GetTabIndex: Integer;
begin
  if PageControl <> nil then
    Result := PageControl.Strip.PosOf(PageIndex)
  else
    Result := -1;
end;

procedure TPPGTabSheet.SetImageIndex(const Value: TPPGImageIndex);
begin
  if FImageIndex <> Value then
  begin
    FImageIndex := Value;
    if PageControl <> nil then
      PageControl.PageChanged(Self);
  end;
end;

procedure TPPGTabSheet.SetTabColor(const Value: TColor);
begin
  if FTabColor <> Value then
  begin
    FTabColor := Value;
    if PageControl <> nil then
      PageControl.PageChanged(Self);
  end;
end;

procedure TPPGTabSheet.SetTabTextColor(const Value: TColor);
begin
  if FTabTextColor <> Value then
  begin
    FTabTextColor := Value;
    if PageControl <> nil then
      PageControl.PageChanged(Self);
  end;
end;

procedure TPPGTabSheet.SetTabFontStyle(const Value: TFontStyles);
begin
  if FTabFontStyle <> Value then
  begin
    FTabFontStyle := Value;
    if PageControl <> nil then
      PageControl.PageChanged(Self);
  end;
end;

procedure TPPGTabSheet.SetTabVisible(const Value: Boolean);
begin
  if FTabVisible <> Value then
  begin
    FTabVisible := Value;
    if PageControl <> nil then
      PageControl.PageChanged(Self);
  end;
end;

procedure TPPGTabSheet.CMTextChanged(var Message: TMessage);
begin
  inherited;
  if PageControl <> nil then
    PageControl.PageChanged(Self);
end;

procedure TPPGTabSheet.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  if PageControl <> nil then
    PageControl.PageChanged(Self);
end;

function TPPGTabSheet.GetBackgroundColor: TColor;
begin
  // Die Seite hat die Flaechenfarbe ihres PageControls (einfarbig)
  if PageControl <> nil then
    Result := PageControl.PageColor
  else
    Result := GetContainerStyle(False).Color;
end;

function TPPGTabSheet.GetChildBackground(Child: TControl; out ColorTop,
  ColorBottom: TColor): Boolean;
begin
  // Seite ist einfarbig und ohne Rahmen: jedes Kind sieht die Seitenfarbe
  ColorTop := GetBackgroundColor;
  ColorBottom := ColorTop;
  Result := True;
end;

procedure TPPGTabSheet.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
begin
  // Nur der Hintergrund (FillBackground); Rahmen zeichnet das PageControl
end;

function TPPGTabSheet.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_PROPERTYPAGE;
end;

procedure TPPGTabSheet.DoShow;
begin
  if Assigned(FOnShow) then
    FOnShow(Self);
end;

procedure TPPGTabSheet.DoHide;
begin
  if Assigned(FOnHide) then
    FOnHide(Self);
end;

{ TPPGPageControl }

procedure TPPGPageControl.ImagesChanged;
{$IFDEF PPG_HAS_IMAGENAME}
var
  I: Integer;
{$ENDIF}
begin
  inherited ImagesChanged;
{$IFDEF PPG_HAS_IMAGENAME}
  for I := 0 to PageCount - 1 do
    Pages[I].ResolveImageName;
{$ENDIF}
end;


constructor TPPGPageControl.Create(AOwner: TComponent);
begin
  FPages := TList.Create;
  inherited Create(AOwner);
  // Controls landen auf den Seiten, nicht auf dem PageControl selbst
  ControlStyle := ControlStyle - [csAcceptsControls];
end;

destructor TPPGPageControl.Destroy;
begin
  // inherited zerstoert die Seiten (Kinder); sie melden sich dabei ab
  inherited Destroy;
  FreeAndNil(FPages);
end;

procedure TPPGPageControl.Loaded;
begin
  inherited Loaded;
  // Ohne gespeicherte ActivePage: erste Seite mit Reiter
  if (FActivePage = nil) and (PageCount > 0) then
    ChangeActivePage(FindNextPage(nil, True, True), False);
end;

function TPPGPageControl.GetPage(Index: Integer): TPPGTabSheet;
begin
  Result := TPPGTabSheet(FPages[Index]);
end;

function TPPGPageControl.GetPageCount: Integer;
begin
  if FPages = nil then
    Result := 0
  else
    Result := FPages.Count;
end;

function TPPGPageControl.GetActivePageIndex: Integer;
begin
  if FActivePage = nil then
    Result := -1
  else
    Result := FPages.IndexOf(FActivePage);
end;

procedure TPPGPageControl.SetActivePageIndex(const Value: Integer);
begin
  if (Value >= 0) and (Value < PageCount) then
    SetActivePage(Pages[Value])
  else
    SetActivePage(nil);
end;

procedure TPPGPageControl.SetActivePage(const Value: TPPGTabSheet);
begin
  // Im Code gesetzt: kein OnChanging/OnChange (wie TPageControl)
  if (Value <> nil) and (Value.PageControl <> Self) then
    Exit;
  ChangeActivePage(Value, False);
end;

procedure TPPGPageControl.CMControlChange(var Message: TCMControlChange);
begin
  inherited;
  // Jede TabSheet mit diesem Parent ist eine Seite (Einfuegen: nach dem
  // Eintragen in Controls, Entfernen: davor)
  if Message.Control is TPPGTabSheet then
    if Message.Inserting then
      InsertPage(TPPGTabSheet(Message.Control))
    else
      RemovePage(TPPGTabSheet(Message.Control));
end;

procedure TPPGPageControl.InsertPage(Page: TPPGTabSheet);
begin
  if FPages.IndexOf(Page) >= 0 then
    Exit;
  FPages.Add(Page);
  if (csLoading in ComponentState) or (csReading in Page.ComponentState) then
    Exit; // Loaded baut die Leiste auf, ActivePage kommt aus der DFM
  TabsChanged;
  // Erste Seite eines leeren PageControls wird sichtbar
  if FActivePage = nil then
    ChangeActivePage(Page, False);
end;

function TPPGPageControl.NeighbourOf(Page: TPPGTabSheet): TPPGTabSheet;
var
  I, Start: Integer;
begin
  Result := nil;
  Start := FPages.IndexOf(Page);
  if Start < 0 then
    Exit;
  for I := Start + 1 to FPages.Count - 1 do
    if Pages[I].TabVisible then
      Exit(Pages[I]);
  for I := Start - 1 downto 0 do
    if Pages[I].TabVisible then
      Exit(Pages[I]);
end;

procedure TPPGPageControl.RemovePage(Page: TPPGTabSheet);
var
  Next: TPPGTabSheet;
begin
  if FPages.IndexOf(Page) < 0 then
    Exit;
  if csDestroying in ComponentState then
  begin
    FPages.Remove(Page);
    if FActivePage = Page then
      FActivePage := nil;
    Exit;
  end;
  Next := nil;
  if FActivePage = Page then
    Next := NeighbourOf(Page);
  FPages.Remove(Page);
  if FActivePage = Page then
  begin
    FActivePage := nil; // die Seite geht, sie wird nicht mehr ausgeblendet
    ChangeActivePage(Next, False);
  end;
  TabsChanged;
end;

procedure TPPGPageControl.MovePage(Page: TPPGTabSheet; NewIndex: Integer);
var
  Cur: Integer;
begin
  Cur := FPages.IndexOf(Page);
  if Cur < 0 then
    Exit;
  if NewIndex < 0 then
    NewIndex := 0;
  if NewIndex > FPages.Count - 1 then
    NewIndex := FPages.Count - 1;
  if NewIndex = Cur then
    Exit;
  FPages.Move(Cur, NewIndex);
  TabsChanged;
end;

procedure TPPGPageControl.PageChanged(Page: TPPGTabSheet);
begin
  if csLoading in ComponentState then
    Exit;
  // Reiter der aktiven Seite ausgeblendet: Nachbarseite zeigen. Gibt es keine
  // (alle Reiter aus, z.B. Assistent oder NavigationView), bleibt sie aktiv.
  if (Page = FActivePage) and not Page.TabVisible and not (csDesigning in ComponentState) and
    (NeighbourOf(Page) <> nil) then
    ChangeActivePage(NeighbourOf(Page), False);
  TabsChanged;
end;

procedure TPPGPageControl.ChangeActivePage(Page: TPPGTabSheet; Animate: Boolean);
var
  Old: TPPGTabSheet;
  Form: TCustomForm;
  FocusInOld: Boolean;
begin
  if Page = FActivePage then
    Exit;
  Old := FActivePage;
  Form := GetParentForm(Self);
  FocusInOld := (Old <> nil) and (Form <> nil) and (Form.ActiveControl <> nil) and
    Old.ContainsControl(Form.ActiveControl) and not (csLoading in ComponentState);
  // Erst die neue zeigen, dann die alte verstecken (kein Aufblitzen)
  if Page <> nil then
  begin
    Page.BringToFront;
    Page.Visible := True;
  end;
  FActivePage := Page;
  if Old <> nil then
    Old.Visible := False;
  if FocusInOld then
  begin
    // Fokus nicht auf einer unsichtbaren Seite lassen
    if (Page <> nil) and Page.CanFocus then
      Page.SelectFirst;
    if ((Page = nil) or not Page.ContainsControl(Form.ActiveControl)) and CanFocus then
      SetFocus;
  end;
  if not (csLoading in ComponentState) then
  begin
    if Old <> nil then
      Old.DoHide;
    if Page <> nil then
      Page.DoShow;
  end;
  ActiveTabChanged(Animate);
end;

function TPPGPageControl.FindNextPage(CurPage: TPPGTabSheet; GoForward,
  CheckTabVisible: Boolean): TPPGTabSheet;
var
  I, Start, N, Idx: Integer;
begin
  Result := nil;
  N := FPages.Count;
  if N = 0 then
    Exit;
  Start := FPages.IndexOf(CurPage);
  if Start < 0 then
    if GoForward then
      Start := N - 1
    else
      Start := 0;
  for I := 1 to N do
  begin
    if GoForward then
      Idx := (Start + I) mod N
    else
      Idx := (Start - I + 2 * N) mod N;
    if not CheckTabVisible or Pages[Idx].TabVisible then
      Exit(Pages[Idx]);
  end;
end;

procedure TPPGPageControl.SelectNextPage(GoForward, CheckTabVisible: Boolean);
var
  P: TPPGTabSheet;
begin
  P := FindNextPage(FActivePage, GoForward, CheckTabVisible);
  if (P = nil) or (P = FActivePage) then
    Exit;
  if P.TabVisible and P.Enabled then
    SelectTabByUser(FPages.IndexOf(P))
  else if CanChange then
  begin
    ChangeActivePage(P, True);
    Change;
  end;
end;

procedure TPPGPageControl.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  I: Integer;
  C: TControl;
begin
  // Seiten in Seitenreihenfolge, danach sonstige Kinder
  for I := 0 to FPages.Count - 1 do
    Proc(TComponent(FPages[I]));
  for I := 0 to ControlCount - 1 do
  begin
    C := Controls[I];
    if not (C is TPPGTabSheet) and (C.Owner = Root) then
      Proc(C);
  end;
end;

procedure TPPGPageControl.SetChildOrder(Child: TComponent; Order: Integer);
begin
  if Child is TPPGTabSheet then
    TPPGTabSheet(Child).PageIndex := Order
  else
    inherited SetChildOrder(Child, Order);
end;

procedure TPPGPageControl.ShowControl(AControl: TControl);
begin
  // Designer/Code zeigt ein Control auf einer verdeckten Seite: Seite wechseln
  if (AControl is TPPGTabSheet) and (TPPGTabSheet(AControl).PageControl = Self) then
    SetActivePage(TPPGTabSheet(AControl));
  inherited ShowControl(AControl);
end;

{ ---- Anbindung an die Reiterleiste ---- }

procedure TPPGPageControl.FillTabs(Strip: TPPGTabStrip);
var
  I: Integer;
  P: TPPGTabSheet;
begin
  for I := 0 to FPages.Count - 1 do
  begin
    P := Pages[I];
    if P.TabVisible then
    begin
      Strip.Add(P.Caption, P.ImageIndex, P.Enabled, I);
      Strip.SetTabStyle(Strip.Count - 1, P.TabColor, P.TabTextColor, P.TabFontStyle);
    end;
  end;
end;

function TPPGPageControl.GetActiveTabIndex: Integer;
begin
  Result := GetActivePageIndex;
end;

procedure TPPGPageControl.SetActiveTabIndex(Index: Integer);
begin
  if (Index >= 0) and (Index < PageCount) then
    ChangeActivePage(Pages[Index], True);
end;

function TPPGPageControl.TabCount: Integer;
begin
  Result := PageCount;
end;

function TPPGPageControl.TabSelectable(Index: Integer): Boolean;
begin
  Result := (Index >= 0) and (Index < PageCount) and Pages[Index].TabVisible and
    Pages[Index].Enabled;
end;

procedure TPPGPageControl.CloseTab(Index: Integer);
var
  P: TPPGTabSheet;
  CanClose: Boolean;
  Action: TCloseAction;
begin
  if (Index < 0) or (Index >= PageCount) then
    Exit;
  P := Pages[Index];
  CanClose := True;
  if Assigned(FOnCloseQuery) then
    FOnCloseQuery(Self, P, CanClose);
  // Die Ereignisse duerfen die Seite selbst freigeben oder umhaengen; dann
  // ist P nicht mehr gueltig bzw. nicht mehr unsere Seite.
  if not CanClose or (FPages.IndexOf(P) < 0) then
    Exit;
  Action := caHide;
  if Assigned(FOnClose) then
    FOnClose(Self, P, Action);
  if FPages.IndexOf(P) < 0 then
    Exit;
  case Action of
    caHide, caMinimize:
      P.TabVisible := False; // aktive Seite: Nachbar wird aktiv
    caFree:
      P.Free;
  end;
end;

initialization
  // Seiten werden auch ohne Formularfeld gefunden (z.B. Frames, dynamisch
  // geladene DFMs)
  RegisterClass(TPPGTabSheet);

end.
