unit PPG.DB.Navigator;

{ TPPGDBNavigator und TPPGDBRadioGroup (Phase 18c).

  TPPGDBNavigator - DFM wie TDBNavigator (DataSource, VisibleButtons, Hints,
  ConfirmDelete, Flat, BeforeAction, OnClick mit TNavigateBtn). Mehrwert:
  - ShowCounter: "Datensatz 12 von 340" bzw. "Neuer Datensatz" (auch fuer
    Screenreader), ohne RecNo-Unterstuetzung nur die Anzahl.
  - ShowSearch: Suchfeld; Tippen sucht ab dem aktuellen Datensatz (Feld
    SearchField bzw. alle Textfelder, enthaelt, ohne Gross-/Kleinschreibung),
    Enter springt zum naechsten Treffer, ohne Treffer rot markiert.
  - ShowFilter: Knopf "Nur Treffer" filtert die Datenmenge auf das Suchwort.
    Dafuer haengt sich der Navigator in OnFilterRecord ein und ruft einen
    vorhandenen Handler zuerst auf; Filtered und Handler werden beim
    Aufheben wiederhergestellt.
  - Ueberlauf: Passen nicht alle Knoepfe, kommen die hinteren in ein Menue.
  - Tastatur (mit Fokus): Pfeile wechseln den Knopf, Leertaste/Enter loest
    aus; Strg+Pos1/Ende, Bild auf/ab, Einfg, Strg+Entf, F2, Strg+Enter, Esc.
  - Ein Control mit selbst gezeichneten Knoepfen und Fluent-Symbolen; das
    Suchfeld ist ein eingebettetes TPPGSearchEdit.

  TPPGDBRadioGroup - wie TDBRadioGroup (Items, Values, DataField, ReadOnly)
  auf TPPGRadioGroup: Segmente und Kacheln auch fuer Datenbankfelder.

  Eigene Unit (statt PPG.DB.Controls), damit die laufenden Arbeiten an den
  DB-Controls (Audit Paket 4) unabhaengig bleiben. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.Menus, Vcl.DBCtrls, Data.DB,
  PPG.Types, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Base, PPG.SearchEdit,
  PPG.RadioGroup, PPG.DB.Controls;

type
  TPPGNavDataLink = class;

  TPPGCustomDBNavigator = class(TPPGCustomControl, IPPGAccessibleChildren)
  private
    FDataLink: TPPGNavDataLink;
    FVisibleButtons: TNavButtonSet;
    FHints: TStrings;
    FConfirmDelete: Boolean;
    FFlat: Boolean;
    FShowCounter: Boolean;
    FShowSearch: Boolean;
    FShowFilter: Boolean;
    FSearchField: string;
    FSearch: TPPGSearchEdit;
    FFilterOn: Boolean;
    FFilterText: string;
    FFilterSet: TDataSet;
    FOldFilterRecord: TFilterRecordEvent;
    FOldFiltered: Boolean;
    FOverflow: TPopupMenu;
    // Layout
    FRects: array of record
      Btn: TNavigateBtn;
      R: TRect;
    end;
    FMoreRect, FFilterRect, FCounterRect: TRect;
    FHidden: TNavButtonSet;
    FLaidW, FLaidH: Integer;  // Groesse des letzten Layouts (-1 = neu rechnen)
    FHot, FDown, FFocusPart: Integer; // Index in FRects; -2 = Filter, -3 = Mehr
    FBeforeAction: ENavClick;
    FOnNavClick: ENavClick;
    procedure SetVisibleButtons(const Value: TNavButtonSet);
    procedure SetHints(const Value: TStrings);
    procedure SetFlat(const Value: Boolean);
    procedure SetShowCounter(const Value: Boolean);
    procedure SetShowSearch(const Value: Boolean);
    procedure SetShowFilter(const Value: Boolean);
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    procedure HintsChanged(Sender: TObject);
    procedure SearchTyped(Sender: TObject; const SearchText: string);
    procedure SearchSubmit(Sender: TObject; const SearchText: string);
    procedure OverflowClick(Sender: TObject);
    procedure NavFilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Resize; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure UpdateVisualState(Animate: Boolean = True); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure WndProc(var Message: TMessage); override;
    /// Datenmenge hat sich geaendert (Zustand der Knoepfe, Zaehler).
    procedure DataChanged; virtual;
    procedure DoLayout;
    /// Layout bei Bedarf (Groesse geaendert; auch ohne Fensterhandle).
    procedure EnsureLayout;
    function PartAt(X, Y: Integer): Integer;
    function ButtonHint(Btn: TNavigateBtn): string;
    function AccRole: Integer; override;
    function AccValue: string; override;
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
    /// Wie TDBNavigator.BtnClick: Aktion ausfuehren (BeforeAction, Aktion, OnClick).
    procedure BtnClick(Index: TNavigateBtn); virtual;
    /// Ist der Knopf im aktuellen Zustand der Datenmenge bedienbar?
    function ButtonEnabled(Btn: TNavigateBtn): Boolean;
    /// Lage eines Knopfs (Client); leer = unsichtbar oder im Ueberlauf.
    function ButtonRect(Btn: TNavigateBtn): TRect;
    /// Text des Zaehlers (wie angezeigt bzw. vorgelesen).
    function CounterText: string;
    /// Naechsten Treffer ab dem Datensatz nach dem aktuellen suchen
    /// (FromCurrent: einschliesslich des aktuellen). False = keiner.
    function FindText(const S: string; FromCurrent: Boolean): Boolean;
    /// Schnellfilter auf das Suchwort ein-/ausschalten.
    procedure SetQuickFilter(Active: Boolean);
    property QuickFilterActive: Boolean read FFilterOn;
    property SearchEdit: TPPGSearchEdit read FSearch;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property VisibleButtons: TNavButtonSet read FVisibleButtons write SetVisibleButtons
      default [nbFirst, nbPrior, nbNext, nbLast, nbInsert, nbDelete, nbEdit, nbPost, nbCancel, nbRefresh];
    property Hints: TStrings read FHints write SetHints;
    property ConfirmDelete: Boolean read FConfirmDelete write FConfirmDelete default True;
    property Flat: Boolean read FFlat write SetFlat default False;
    property ShowCounter: Boolean read FShowCounter write SetShowCounter default True;
    property ShowSearch: Boolean read FShowSearch write SetShowSearch default False;
    property ShowFilter: Boolean read FShowFilter write SetShowFilter default False;
    /// Feld fuer Suche und Filter ('' = alle Textfelder).
    property SearchField: string read FSearchField write FSearchField;
    property BeforeAction: ENavClick read FBeforeAction write FBeforeAction;
    property OnClick: ENavClick read FOnNavClick write FOnNavClick;
  end;

  TPPGNavDataLink = class(TDataLink)
  private
    FNavigator: TPPGCustomDBNavigator;
  protected
    procedure EditingChanged; override;
    procedure DataSetChanged; override;
    procedure ActiveChanged; override;
  public
    constructor Create(ANav: TPPGCustomDBNavigator);
  end;

  TPPGDBNavigator = class(TPPGCustomDBNavigator)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighContrastSupport;
    property DataSource;
    property VisibleButtons;
    property Hints;
    property ConfirmDelete;
    property Flat;
    property ShowCounter;
    property ShowSearch;
    property ShowFilter;
    property SearchField;
    { VCL-Standard }
    property Align;
    property Anchors;
    property BiDiMode;
    property Constraints;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop;
    property Visible;
    property BeforeAction;
    property OnClick;
    property OnContextPopup;
    property OnEnter;
    property OnExit;
    property OnResize;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseActivate;
    property DragMode;
    property DragCursor;
    property OnDragDrop;
    property OnDragOver;
    property OnStartDrag;
    property OnEndDrag;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property Color;
    property ParentColor;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

  TPPGDBRadioGroup = class(TPPGRadioGroup)
  private
    FBinding: TPPGDBBinding;
    FValues: TStrings;
    procedure ShowField(Sender: TObject);
    procedure WriteField(Sender: TObject);
    function GetDataField: string;
    procedure SetDataField(const Value: string);
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetReadOnly(const Value: Boolean);
    procedure SetValues(const Value: TStrings);
    procedure ValuesChanged(Sender: TObject);
    function ItemDbValue(Index: Integer): string;
    procedure CMGetDataLink(var Message: TMessage); message CM_GETDATALINK;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure ActivateItem(Index: Integer); override;
    procedure ItemsChanged; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ExecuteAction(Action: TBasicAction): Boolean; override;
    function UpdateAction(Action: TBasicAction): Boolean; override;
    property Field: TField read GetField;
  published
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    /// Werte fuer das Feld je Eintrag (leer bzw. fehlend = Beschriftung), wie TDBRadioGroup.
    property Values: TStrings read FValues write SetValues;
    property ItemIndex stored False;
  end;

implementation

uses
  System.Math, System.UITypes, System.StrUtils, Vcl.Forms, Vcl.Dialogs, Winapi.oleacc,
  PPG.Appearance, PPG.Exceptions, PPG.Lang, PPG.Consts, PPG.DpiUtils, PPG.Render.Gdi,
  PPG.IconFont, PPG.Tokens, PPG.Controls.Field, PPG.Dialogs, PPG.DB.Validator;

const
  BtnIcons: array[TNavigateBtn] of Word = ($E892, $E76B, $E76C, $E893, $E710, $E74D, $E70F,
    $E73E, $E711, $E72C, $E74E, $E7A7);
  BtnW = 36;          // logische px
  SearchW = 180;
  CounterMinW = 120;
  PartFilter = -2;
  PartMore = -3;

var
  GMsgNavAction: Cardinal;

function BtnHintRes(Btn: TNavigateBtn): string;
begin
  case Btn of
    nbFirst: Result := PPGStr(@SPPGNavFirst);
    nbPrior: Result := PPGStr(@SPPGNavPrior);
    nbNext: Result := PPGStr(@SPPGNavNext);
    nbLast: Result := PPGStr(@SPPGNavLast);
    nbInsert: Result := PPGStr(@SPPGNavInsert);
    nbDelete: Result := PPGStr(@SPPGNavDelete);
    nbEdit: Result := PPGStr(@SPPGNavEdit);
    nbPost: Result := PPGStr(@SPPGNavPost);
    nbCancel: Result := PPGStr(@SPPGNavCancel);
    nbRefresh: Result := PPGStr(@SPPGNavRefresh);
    {$IFDEF PPG_HAS_DATASETCOMMANDS}
    nbApplyUpdates: Result := PPGStr(@SPPGNavApply);
    {$ENDIF}
  else
    Result := PPGStr(@SPPGNavCancelUpdates);
  end;
end;

{ TPPGNavDataLink }

constructor TPPGNavDataLink.Create(ANav: TPPGCustomDBNavigator);
begin
  inherited Create;
  FNavigator := ANav;
  VisualControl := True;
end;

procedure TPPGNavDataLink.EditingChanged;
begin
  if FNavigator <> nil then
    FNavigator.DataChanged;
end;

procedure TPPGNavDataLink.DataSetChanged;
begin
  if (FNavigator <> nil) and not PPGDBReading then
    FNavigator.DataChanged;
end;

procedure TPPGNavDataLink.ActiveChanged;
begin
  if FNavigator <> nil then
    FNavigator.DataChanged;
end;

{ TPPGCustomDBNavigator }

constructor TPPGCustomDBNavigator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csAcceptsControls, csSetCaption, csClickEvents] + [csCaptureMouse];
  Width := 420;
  Height := 36;
  TabStop := False;
  FDataLink := TPPGNavDataLink.Create(Self);
  FVisibleButtons := [nbFirst, nbPrior, nbNext, nbLast, nbInsert, nbDelete, nbEdit, nbPost,
    nbCancel, nbRefresh];
  FHints := TStringList.Create;
  TStringList(FHints).OnChange := HintsChanged;
  FConfirmDelete := True;
  FShowCounter := True;
  FHot := -1;
  FDown := -1;
  FFocusPart := 0;
  FLaidW := -1;
  FLaidH := -1;
end;

destructor TPPGCustomDBNavigator.Destroy;
begin
  // Filter der Datenmenge wiederherstellen, bevor der Handler ins Leere zeigt
  if FFilterOn then
    SetQuickFilter(False);
  FDataLink.FNavigator := nil;
  FreeAndNil(FDataLink);
  FreeAndNil(FHints);
  inherited Destroy;
end;

procedure TPPGCustomDBNavigator.Loaded;
begin
  inherited Loaded;
  DoLayout;
  DataChanged;
end;

procedure TPPGCustomDBNavigator.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation <> opRemove then
    Exit;
  if (FDataLink <> nil) and (AComponent = DataSource) then
    DataSource := nil;
  if AComponent = FFilterSet then
  begin
    // Datenmenge weg: nichts mehr wiederherzustellen
    FFilterSet := nil;
    FFilterOn := False;
  end;
  if AComponent = FSearch then
    FSearch := nil;
  if AComponent = FOverflow then
    FOverflow := nil;
end;

function TPPGCustomDBNavigator.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TPPGCustomDBNavigator.SetDataSource(Value: TDataSource);
begin
  if FFilterOn then
    SetQuickFilter(False);
  PPGDBSetDataSource(Self, FDataLink, Value);
  DataChanged;
end;

procedure TPPGCustomDBNavigator.SetVisibleButtons(const Value: TNavButtonSet);
begin
  if FVisibleButtons <> Value then
  begin
    FVisibleButtons := Value;
    DoLayout;
    Invalidate;
  end;
end;

procedure TPPGCustomDBNavigator.SetHints(const Value: TStrings);
begin
  FHints.Assign(Value);
end;

procedure TPPGCustomDBNavigator.HintsChanged(Sender: TObject);
begin
  NotifyAccessibility(EVENT_OBJECT_NAMECHANGE);
end;

procedure TPPGCustomDBNavigator.SetFlat(const Value: Boolean);
begin
  if FFlat <> Value then
  begin
    FFlat := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomDBNavigator.SetShowCounter(const Value: Boolean);
begin
  if FShowCounter <> Value then
  begin
    FShowCounter := Value;
    DoLayout;
    Invalidate;
  end;
end;

procedure TPPGCustomDBNavigator.SetShowSearch(const Value: Boolean);
begin
  if FShowSearch = Value then
    Exit;
  FShowSearch := Value;
  if Value and (FSearch = nil) then
  begin
    FSearch := TPPGSearchEdit.Create(Self);
    FSearch.FreeNotification(Self);
    FSearch.Parent := Self;
    FSearch.TextHint := PPGStr(@SPPGNavSearchHint);
    FSearch.OnSearch := SearchTyped;
    FSearch.OnSubmit := SearchSubmit;
  end;
  if FSearch <> nil then
    FSearch.Visible := Value;
  if not Value and FFilterOn then
    SetQuickFilter(False);
  DoLayout;
  Invalidate;
end;

procedure TPPGCustomDBNavigator.SetShowFilter(const Value: Boolean);
begin
  if FShowFilter <> Value then
  begin
    FShowFilter := Value;
    if not Value and FFilterOn then
      SetQuickFilter(False);
    DoLayout;
    Invalidate;
  end;
end;

procedure TPPGCustomDBNavigator.CMFontChanged(var Message: TMessage);
begin
  inherited;
  DoLayout;
end;

procedure TPPGCustomDBNavigator.Resize;
begin
  inherited Resize;
  DoLayout;
end;

procedure TPPGCustomDBNavigator.DataChanged;
begin
  if csDestroying in ComponentState then
    Exit;
  NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
  Invalidate;
end;

{ Zustand }

function TPPGCustomDBNavigator.ButtonEnabled(Btn: TNavigateBtn): Boolean;
var
  DS: TDataSet;
  {$IFDEF PPG_HAS_DATASETCOMMANDS}
  Cmd: IDataSetCommandSupport;
  {$ENDIF}
  Browse, CanMod, Empty: Boolean;
begin
  Result := False;
  if not Enabled or not FDataLink.Active then
    Exit;
  DS := FDataLink.DataSet;
  Browse := not (DS.State in dsEditModes);
  CanMod := DS.CanModify;
  Empty := DS.IsEmpty;
  // Wie TDBNavigator.EditingChanged/DataChanged
  case Btn of
    nbFirst, nbPrior: Result := Browse and not DS.Bof;
    nbNext, nbLast: Result := Browse and not DS.Eof;
    nbInsert: Result := CanMod;
    nbDelete: Result := CanMod and not Empty and Browse;
    nbEdit: Result := CanMod and Browse and not Empty;
    nbPost, nbCancel: Result := CanMod and not Browse;
    nbRefresh: Result := Browse;
    {$IFDEF PPG_HAS_DATASETCOMMANDS}
    nbApplyUpdates: Result := Supports(DS, IDataSetCommandSupport, Cmd) and
      (dcEnabled in Cmd.GetCommandStates(sApplyUpdatesDataSetCommand));
    nbCancelUpdates: Result := Supports(DS, IDataSetCommandSupport, Cmd) and
      (dcEnabled in Cmd.GetCommandStates(sCancelUpdatesDataSetCommand));
    {$ENDIF}
  end;
end;

function TPPGCustomDBNavigator.CounterText: string;
var
  DS: TDataSet;
  N, R: Integer;
begin
  Result := '';
  if not FDataLink.Active then
    Exit;
  DS := FDataLink.DataSet;
  if DS.State = dsInsert then
    Exit(PPGStr(@SPPGNavNewRecord));
  N := DS.RecordCount;
  if (N = 0) or DS.IsEmpty then
    Exit(PPGStr(@SPPGNavNoRecords));
  R := DS.RecNo;
  if (R >= 1) and (N >= 1) then
    Result := Format(PPGStr(@SPPGNavCounter), [R, N])
  else if N > 0 then
    Result := Format(PPGStr(@SPPGNavCount), [N]);
end;

function TPPGCustomDBNavigator.ButtonHint(Btn: TNavigateBtn): string;
begin
  // Eigene Hints wie TDBNavigator: Zeile je Knopf in der Reihenfolge von TNavigateBtn
  if (Ord(Btn) < FHints.Count) and (FHints[Ord(Btn)] <> '') then
    Result := FHints[Ord(Btn)]
  else
    Result := BtnHintRes(Btn);
end;

{ Layout }

procedure TPPGCustomDBNavigator.DoLayout;
var
  PPI, W, X, Right, H, N, I, Need, CW: Integer;
  B: TNavigateBtn;
  Btns: array of TNavigateBtn;
  Fits: Boolean;
begin
  // Width/Height statt ClientWidth/ClientHeight: ohne Rahmen gleich, und kein Fensterhandle noetig
  // (beim Laden aus der DFM gibt es noch keinen Parent)
  if csLoading in ComponentState then
  begin
    FLaidW := -1;
    Exit;
  end;
  FLaidW := Width;
  FLaidH := Height;
  PPI := ScalePPI;
  W := PPGScale(BtnW, PPI);
  H := Height;
  N := 0;
  SetLength(Btns, Ord(High(TNavigateBtn)) + 1);
  for B := Low(TNavigateBtn) to High(TNavigateBtn) do
    if B in FVisibleButtons then
    begin
      Btns[N] := B;
      Inc(N);
    end;
  // Platz rechts: Suchfeld, Filterknopf, Zaehler
  Right := Width;
  if FShowSearch and (FSearch <> nil) then
  begin
    Dec(Right, PPGScale(SearchW, PPI));
    FSearch.SetBounds(Right, (H - FSearch.Height) div 2, PPGScale(SearchW, PPI), FSearch.Height);
    if FShowFilter then
    begin
      FFilterRect := Rect(Right - W - PPGScale(4, PPI), 0, Right - PPGScale(4, PPI), H);
      Right := FFilterRect.Left;
    end
    else
      FFilterRect := Rect(0, 0, 0, 0);
    Dec(Right, PPGScale(8, PPI));
  end
  else
    FFilterRect := Rect(0, 0, 0, 0);
  CW := 0;
  if FShowCounter then
    CW := PPGScale(CounterMinW, PPI);
  // Passen alle Knoepfe und der Zaehler? Sonst erst der Zaehler, dann Ueberlauf
  Need := N * W + CW;
  if (Need > Right) and (CW > 0) then
  begin
    CW := 0;
    Need := N * W;
  end;
  Fits := Need <= Right;
  FHidden := [];
  SetLength(FRects, 0);
  FMoreRect := Rect(0, 0, 0, 0);
  X := 0;
  for I := 0 to N - 1 do
  begin
    if not Fits and (X + 2 * W > Right) then
    begin
      // Rest ins Ueberlaufmenue
      FMoreRect := Rect(X, 0, X + W, H);
      for N := I to High(Btns) do
        if Btns[N] in FVisibleButtons then
          Include(FHidden, Btns[N]);
      Inc(X, W);
      Break;
    end;
    SetLength(FRects, Length(FRects) + 1);
    FRects[High(FRects)].Btn := Btns[I];
    FRects[High(FRects)].R := Rect(X, 0, X + W, H);
    Inc(X, W);
  end;
  if CW > 0 then
    FCounterRect := Rect(X + PPGScale(8, PPI), 0, Right, H)
  else
    FCounterRect := Rect(0, 0, 0, 0);
  // RTL: Knoepfe von rechts
  if UseRightToLeftAlignment then
  begin
    for I := 0 to High(FRects) do
      FRects[I].R := Rect(Width - FRects[I].R.Right, 0, Width - FRects[I].R.Left, H);
    if not IsRectEmpty(FMoreRect) then
      FMoreRect := Rect(Width - FMoreRect.Right, 0, Width - FMoreRect.Left, H);
    if not IsRectEmpty(FCounterRect) then
      FCounterRect := Rect(Width - FCounterRect.Right, 0, Width - FCounterRect.Left, H);
    if not IsRectEmpty(FFilterRect) then
      FFilterRect := Rect(Width - FFilterRect.Right, 0, Width - FFilterRect.Left, H);
    if FShowSearch and (FSearch <> nil) then
      FSearch.Left := 0;
  end;
  if FFocusPart > High(FRects) then
    FFocusPart := Max(High(FRects), 0);
end;

procedure TPPGCustomDBNavigator.EnsureLayout;
begin
  if (FLaidW <> Width) or (FLaidH <> Height) then
    DoLayout;
end;

function TPPGCustomDBNavigator.ButtonRect(Btn: TNavigateBtn): TRect;
var
  I: Integer;
begin
  EnsureLayout;
  for I := 0 to High(FRects) do
    if FRects[I].Btn = Btn then
      Exit(FRects[I].R);
  Result := Rect(0, 0, 0, 0);
end;

function TPPGCustomDBNavigator.PartAt(X, Y: Integer): Integer;
var
  I: Integer;
  P: TPoint;
begin
  EnsureLayout;
  P := Point(X, Y);
  for I := 0 to High(FRects) do
    if PtInRect(FRects[I].R, P) then
      Exit(I);
  if PtInRect(FFilterRect, P) then
    Exit(PartFilter);
  if PtInRect(FMoreRect, P) then
    Exit(PartMore);
  Result := -1;
end;

{ Zeichnen }

procedure TPPGCustomDBNavigator.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  PPI, I, Rad, Sz: Integer;
  A: TPPGAppearance;
  St: TPPGSurfaceStyle;
  Txt, Dis, Accent, C: TColor;
  R: TRect;
  En: Boolean;
  Temp: TFont;
  F: TFont;
  HC: Boolean;

  procedure DrawPart(const PR: TRect; Part: Integer; Icon: Word; Enabled, Pressed: Boolean);
  var
    BR: TRect;
  begin
    BR := PR;
    InflateRect(BR, -PPGScale(2, PPI), -PPGScale(2, PPI));
    if Pressed then
      ACanvas.FillRoundRect(BR, Rad, Accent, 60)
    else if (Part = FDown) and (Part = FHot) and Enabled then
      ACanvas.FillRoundRect(BR, Rad, Txt, 40)
    else if (Part = FHot) and Enabled then
      ACanvas.FillRoundRect(BR, Rad, Txt, 20)
    else if not FFlat then
      ACanvas.FrameRoundRect(BR, Rad, Max(1, PPGScale(1, PPI)), St.BorderColor, 255);
    if Enabled then
      C := Txt
    else
      C := Dis;
    PPGDrawIconChar(ACanvas, BR, Icon, C, Sz);
    if Focused and FocusVisible and (Part = FFocusPart) then
      ACanvas.FrameRoundRect(BR, Rad, PPGScale(2, PPI), Accent, 255);
  end;

begin
  EnsureLayout;
  PPI := ScalePPI;
  A := EffectiveAppearance;
  St := A.Resolve(vsNormal, PPI, False);
  HC := UseHighContrast;
  // Hochkontrast: die Appearance liefert die Systemfarben (Text clBtnText)
  if HC then
    Txt := PPGColorToRGB(A.Normal.TextColor)
  else if UseDarkMode then
    Txt := Tokens.TextPrimary
  else
    Txt := PPGColorToRGB(Font.Color);
  Dis := PPGColorToRGB(A.Disabled.TextColor);
  Accent := PPGColorToRGB(A.FocusColor);
  Rad := Max(St.Rounding, PPGScale(4, PPI));
  Sz := PPGScale(16, PPI);
  for I := 0 to High(FRects) do
  begin
    En := ButtonEnabled(FRects[I].Btn);
    DrawPart(FRects[I].R, I, BtnIcons[FRects[I].Btn], En, False);
  end;
  if not IsRectEmpty(FMoreRect) then
    DrawPart(FMoreRect, PartMore, Ord(PPGIconChar(igMore)), Enabled, False);
  if not IsRectEmpty(FFilterRect) then
    DrawPart(FFilterRect, PartFilter, $E71C, Enabled and FDataLink.Active, FFilterOn);
  if not IsRectEmpty(FCounterRect) and FDataLink.Active then
  begin
    R := FCounterRect;
    Temp := nil;
    try
      F := PPGStyledFont(Font, [], Temp);
      if Enabled then
        ACanvas.DrawText(R, CounterText, F, PPGBlendColor(Txt, GetBackgroundColor, 0.25),
          DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS))
      else
        ACanvas.DrawText(R, CounterText, F, Dis,
          DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS));
    finally
      Temp.Free;
    end;
  end;
end;

procedure TPPGCustomDBNavigator.UpdateVisualState(Animate: Boolean);
begin
  Invalidate;
end;

{ Aktionen }

procedure TPPGCustomDBNavigator.BtnClick(Index: TNavigateBtn);
var
  DS: TDataSet;
  {$IFDEF PPG_HAS_DATASETCOMMANDS}
  Cmd: IDataSetCommandSupport;
  {$ENDIF}
begin
  if not FDataLink.Active or not ButtonEnabled(Index) then
    Exit;
  if Assigned(FBeforeAction) then
    FBeforeAction(Self, Index);
  DS := FDataLink.DataSet;
  case Index of
    nbFirst: DS.First;
    nbPrior: DS.Prior;
    nbNext: DS.Next;
    nbLast: DS.Last;
    nbInsert: DS.Insert;
    nbEdit: DS.Edit;
    nbCancel: DS.Cancel;
    nbPost: DS.Post;
    nbRefresh: DS.Refresh;
    nbDelete:
      if not FConfirmDelete or (PPGMessageDlg(PPGStr(@SPPGNavDeleteConfirm), mtConfirmation,
        [mbYes, mbNo], 0, mbNo) = mrYes) then
        DS.Delete;
    {$IFDEF PPG_HAS_DATASETCOMMANDS}
    // Wie TDBNavigator ueber IDataSetCommandSupport (FireDAC, ClientDataSet)
    nbApplyUpdates:
      if Supports(DS, IDataSetCommandSupport, Cmd) then
        Cmd.ExecuteCommand(sApplyUpdatesDataSetCommand, [-1]);
    nbCancelUpdates:
      if Supports(DS, IDataSetCommandSupport, Cmd) then
        Cmd.ExecuteCommand(sCancelUpdatesDataSetCommand, [-1]);
    {$ENDIF}
  end;
  if Assigned(FOnNavClick) then
    FOnNavClick(Self, Index);
end;

procedure TPPGCustomDBNavigator.OverflowClick(Sender: TObject);
begin
  BtnClick(TNavigateBtn((Sender as TMenuItem).Tag));
end;

{ Suche und Filter }

function FieldMatches(F: TField; const U: string): Boolean;
begin
  Result := (F <> nil) and not F.IsNull and (Pos(U, AnsiUpperCase(F.DisplayText)) > 0);
end;

function RecordMatches(DS: TDataSet; const FieldName, U: string): Boolean;
var
  I: Integer;
begin
  if FieldName <> '' then
    Exit(FieldMatches(DS.FindField(FieldName), U));
  for I := 0 to DS.FieldCount - 1 do
    if (DS.Fields[I].DataType in [ftString, ftWideString, ftMemo, ftWideMemo, ftFixedChar,
      ftFixedWideChar]) and FieldMatches(DS.Fields[I], U) then
      Exit(True);
  Result := False;
end;

function TPPGCustomDBNavigator.FindText(const S: string; FromCurrent: Boolean): Boolean;
var
  DS: TDataSet;
  BM: TBookmark;
  U: string;
  Wrapped: Boolean;
begin
  Result := False;
  if (S = '') or not FDataLink.Active then
    Exit;
  DS := FDataLink.DataSet;
  if DS.State in dsEditModes then
    Exit; // keine offene Bearbeitung verlassen
  U := AnsiUpperCase(S);
  BM := DS.GetBookmark;
  PPGDBBeginRead;
  DS.DisableControls;
  try
    // Ab dem aktuellen bzw. naechsten Satz bis zum Ende, dann von vorn
    if not FromCurrent then
      DS.Next;
    Wrapped := False;
    while True do
    begin
      if DS.Eof then
      begin
        if Wrapped then
          Break;
        Wrapped := True;
        DS.First;
      end;
      if DS.Eof then
        Break;
      if RecordMatches(DS, FSearchField, U) then
      begin
        Result := True;
        Break;
      end;
      if Wrapped and DS.BookmarkValid(BM) and (DS.CompareBookmarks(DS.GetBookmark, BM) = 0) then
        Break;
      DS.Next;
    end;
    if not Result and DS.BookmarkValid(BM) then
      DS.GotoBookmark(BM);
  finally
    DS.FreeBookmark(BM);
    DS.EnableControls;
    PPGDBEndRead;
  end;
  DataChanged;
end;

procedure TPPGCustomDBNavigator.SearchTyped(Sender: TObject; const SearchText: string);
begin
  if FFilterOn then
  begin
    // Filter folgt dem Suchwort
    FFilterText := AnsiUpperCase(SearchText);
    if FFilterSet <> nil then
      FFilterSet.Refresh;
    Exit;
  end;
  if (SearchText <> '') and not FindText(SearchText, True) then
    FSearch.ValidationState := pvsError
  else
    FSearch.ValidationState := pvsNone;
end;

procedure TPPGCustomDBNavigator.SearchSubmit(Sender: TObject; const SearchText: string);
begin
  if FFilterOn then
    Exit;
  if (SearchText <> '') and not FindText(SearchText, False) then
    FSearch.ValidationState := pvsError
  else
    FSearch.ValidationState := pvsNone;
end;

procedure TPPGCustomDBNavigator.NavFilterRecord(DataSet: TDataSet; var Accept: Boolean);
begin
  // Vorhandener Filter zuerst, dann das Suchwort
  if Assigned(FOldFilterRecord) then
    FOldFilterRecord(DataSet, Accept);
  if Accept and (FFilterText <> '') then
    Accept := RecordMatches(DataSet, FSearchField, FFilterText);
end;

procedure TPPGCustomDBNavigator.SetQuickFilter(Active: Boolean);
var
  DS: TDataSet;
begin
  if Active = FFilterOn then
    Exit;
  if Active then
  begin
    if not FDataLink.Active then
      Exit;
    DS := FDataLink.DataSet;
    if DS.State in dsEditModes then
      DS.Post;
    FFilterSet := DS;
    DS.FreeNotification(Self);
    FOldFilterRecord := DS.OnFilterRecord;
    FOldFiltered := DS.Filtered;
    if FSearch <> nil then
      FFilterText := AnsiUpperCase(FSearch.Text)
    else
      FFilterText := '';
    DS.OnFilterRecord := NavFilterRecord;
    FFilterOn := True;
    DS.Filtered := False;
    DS.Filtered := True;
  end
  else
  begin
    FFilterOn := False;
    DS := FFilterSet;
    FFilterSet := nil;
    if DS <> nil then
    begin
      if not (csDestroying in DS.ComponentState) then
      begin
        DS.OnFilterRecord := FOldFilterRecord;
        DS.Filtered := False;
        DS.Filtered := FOldFiltered;
      end;
      DS.RemoveFreeNotification(Self);
    end;
    FOldFilterRecord := nil;
  end;
  if FSearch <> nil then
    FSearch.ValidationState := pvsNone;
  Invalidate;
end;

{ Bedienung }

procedure TPPGCustomDBNavigator.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = mbLeft then
  begin
    FDown := PartAt(X, Y);
    Invalidate;
  end;
end;

procedure TPPGCustomDBNavigator.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  P := PartAt(X, Y);
  if P <> FHot then
  begin
    FHot := P;
    Application.CancelHint;
    Invalidate;
  end;
end;

procedure TPPGCustomDBNavigator.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P, D: Integer;
  B: TNavigateBtn;
  Item: TMenuItem;
  Pt: TPoint;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button <> mbLeft then
    Exit;
  D := FDown;
  FDown := -1;
  P := PartAt(X, Y);
  Invalidate;
  if (P <> D) or (P = -1) then
    Exit;
  if P >= 0 then
  begin
    FFocusPart := P;
    BtnClick(FRects[P].Btn);
  end
  else if P = PartFilter then
    SetQuickFilter(not FFilterOn)
  else if P = PartMore then
  begin
    // Ausgeblendete Knoepfe als natives Menue (Screenreader-tauglich)
    if FOverflow = nil then
    begin
      FOverflow := TPopupMenu.Create(Self);
      FOverflow.FreeNotification(Self);
    end;
    FOverflow.Items.Clear;
    for B := Low(TNavigateBtn) to High(TNavigateBtn) do
      if B in FHidden then
      begin
        Item := TMenuItem.Create(FOverflow);
        Item.Caption := ButtonHint(B);
        Item.Tag := Ord(B);
        Item.Enabled := ButtonEnabled(B);
        Item.OnClick := OverflowClick;
        FOverflow.Items.Add(Item);
      end;
    Pt := ClientToScreen(Point(FMoreRect.Left, FMoreRect.Bottom));
    FOverflow.Popup(Pt.X, Pt.Y);
  end;
end;

procedure TPPGCustomDBNavigator.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHot <> -1 then
  begin
    FHot := -1;
    Invalidate;
  end;
end;

procedure TPPGCustomDBNavigator.CMHintShow(var Message: TCMHintShow);
var
  P: Integer;
begin
  inherited;
  P := PartAt(Message.HintInfo.CursorPos.X, Message.HintInfo.CursorPos.Y);
  if P >= 0 then
  begin
    Message.HintInfo.HintStr := ButtonHint(FRects[P].Btn);
    Message.HintInfo.CursorRect := FRects[P].R;
  end
  else if P = PartFilter then
  begin
    Message.HintInfo.HintStr := PPGStr(@SPPGNavFilter);
    Message.HintInfo.CursorRect := FFilterRect;
  end
  else if P = PartMore then
  begin
    Message.HintInfo.HintStr := PPGStr(@SPPGMoreOptions);
    Message.HintInfo.CursorRect := FMoreRect;
  end;
end;

procedure TPPGCustomDBNavigator.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TPPGCustomDBNavigator.KeyDown(var Key: Word; Shift: TShiftState);

  procedure Run(B: TNavigateBtn);
  begin
    if B in FVisibleButtons then
      BtnClick(B);
    Key := 0;
  end;

begin
  EnsureLayout;
  inherited KeyDown(Key, Shift);
  case Key of
    VK_LEFT, VK_RIGHT:
      if Length(FRects) > 0 then
      begin
        if (Key = VK_RIGHT) xor UseRightToLeftAlignment then
          FFocusPart := Min(FFocusPart + 1, High(FRects))
        else
          FFocusPart := Max(FFocusPart - 1, 0);
        NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, FFocusPart + 1);
        Invalidate;
        Key := 0;
      end;
    VK_SPACE:
      if (FFocusPart >= 0) and (FFocusPart <= High(FRects)) then
      begin
        BtnClick(FRects[FFocusPart].Btn);
        Key := 0;
      end;
    VK_RETURN:
      if ssCtrl in Shift then
        Run(nbPost)
      else if (FFocusPart >= 0) and (FFocusPart <= High(FRects)) then
      begin
        BtnClick(FRects[FFocusPart].Btn);
        Key := 0;
      end;
    VK_HOME: if ssCtrl in Shift then Run(nbFirst);
    VK_END: if ssCtrl in Shift then Run(nbLast);
    VK_PRIOR: Run(nbPrior);
    VK_NEXT: Run(nbNext);
    VK_INSERT: Run(nbInsert);
    VK_DELETE: if ssCtrl in Shift then Run(nbDelete);
    VK_F2: Run(nbEdit);
    VK_ESCAPE: if FDataLink.Active and (FDataLink.DataSet.State in dsEditModes) then Run(nbCancel);
  end;
end;

procedure TPPGCustomDBNavigator.WndProc(var Message: TMessage);
var
  Id: Integer;
begin
  if (GMsgNavAction <> 0) and (Message.Msg = GMsgNavAction) then
  begin
    // Standardaktion des Screenreaders (nie im COM-Aufruf selbst)
    Id := Integer(Message.WParam) - 1;
    if (Id >= 0) and (Id <= High(FRects)) then
      BtnClick(FRects[Id].Btn);
    Exit;
  end;
  inherited WndProc(Message);
end;

{ Barrierefreiheit }

function TPPGCustomDBNavigator.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_TOOLBAR;
end;

function TPPGCustomDBNavigator.AccValue: string;
begin
  Result := CounterText;
end;

function TPPGCustomDBNavigator.AccChildCount: Integer;
begin
  EnsureLayout;
  Result := Length(FRects);
end;

function TPPGCustomDBNavigator.AccChildName(Id: Integer): string;
begin
  if (Id >= 1) and (Id <= Length(FRects)) then
    Result := ButtonHint(FRects[Id - 1].Btn)
  else
    Result := '';
end;

function TPPGCustomDBNavigator.AccChildRole(Id: Integer): Integer;
begin
  Result := ROLE_SYSTEM_PUSHBUTTON;
end;

function TPPGCustomDBNavigator.AccChildState(Id: Integer): Integer;
begin
  Result := 0;
  if (Id < 1) or (Id > Length(FRects)) then
    Exit;
  if not ButtonEnabled(FRects[Id - 1].Btn) then
    Exit(STATE_SYSTEM_UNAVAILABLE);
  Result := STATE_SYSTEM_FOCUSABLE;
  if Focused and (Id - 1 = FFocusPart) then
    Result := Result or STATE_SYSTEM_FOCUSED;
end;

function TPPGCustomDBNavigator.AccChildRect(Id: Integer): TRect;
begin
  if (Id >= 1) and (Id <= Length(FRects)) then
    Result := FRects[Id - 1].R
  else
    Result := Rect(0, 0, 0, 0);
end;

function TPPGCustomDBNavigator.AccChildAt(X, Y: Integer): Integer;
var
  P: Integer;
begin
  P := PartAt(X, Y);
  if P >= 0 then
    Result := P + 1
  else
    Result := 0;
end;

function TPPGCustomDBNavigator.AccChildDefaultAction(Id: Integer): string;
begin
  Result := PPGStr(@SPPGAccPress);
end;

procedure TPPGCustomDBNavigator.AccChildDoDefault(Id: Integer);
begin
  if HandleAllocated and (GMsgNavAction <> 0) then
    PostMessage(Handle, GMsgNavAction, WPARAM(Id), 0);
end;

function TPPGCustomDBNavigator.AccFocusedChild: Integer;
begin
  if Focused then
    Result := FFocusPart + 1
  else
    Result := 0;
end;

function TPPGCustomDBNavigator.AccSelectedChild: Integer;
begin
  Result := 0;
end;

{ TPPGDBRadioGroup }

constructor TPPGDBRadioGroup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FValues := TStringList.Create;
  TStringList(FValues).OnChange := ValuesChanged;
  // Kein Feld-Control: ActivateItem prueft die Aenderbarkeit selbst
  FBinding := TPPGDBBinding.Create(Self, False);
  FBinding.OnShow := ShowField;
  FBinding.OnWrite := WriteField;
end;

destructor TPPGDBRadioGroup.Destroy;
begin
  FreeAndNil(FBinding);
  inherited Destroy;
  FreeAndNil(FValues);
end;

procedure TPPGDBRadioGroup.Loaded;
begin
  inherited Loaded;
  FBinding.Reload;
end;

procedure TPPGDBRadioGroup.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if FBinding <> nil then
    FBinding.Notify(AComponent, Operation);
end;

function TPPGDBRadioGroup.GetDataField: string;
begin
  Result := FBinding.DataField;
end;

procedure TPPGDBRadioGroup.SetDataField(const Value: string);
begin
  FBinding.DataField := Value;
end;

function TPPGDBRadioGroup.GetDataSource: TDataSource;
begin
  Result := FBinding.DataSource;
end;

procedure TPPGDBRadioGroup.SetDataSource(Value: TDataSource);
begin
  FBinding.DataSource := Value;
end;

function TPPGDBRadioGroup.GetField: TField;
begin
  Result := FBinding.Field;
end;

function TPPGDBRadioGroup.GetReadOnly: Boolean;
begin
  Result := FBinding.ReadOnly;
end;

procedure TPPGDBRadioGroup.SetReadOnly(const Value: Boolean);
begin
  FBinding.ReadOnly := Value;
end;

procedure TPPGDBRadioGroup.SetValues(const Value: TStrings);
begin
  FValues.Assign(Value);
end;

procedure TPPGDBRadioGroup.ValuesChanged(Sender: TObject);
begin
  if FBinding <> nil then
    FBinding.Reload;
end;

procedure TPPGDBRadioGroup.ItemsChanged;
begin
  inherited ItemsChanged;
  if (FBinding <> nil) and not FBinding.Setting then
    FBinding.Reload;
end;

function TPPGDBRadioGroup.ItemDbValue(Index: Integer): string;
begin
  // Values[i] wie TDBRadioGroup, sonst die Beschriftung
  if (Index < FValues.Count) and (FValues[Index] <> '') then
    Result := FValues[Index]
  else if ItemsEx[Index].Value <> '' then
    Result := ItemsEx[Index].Value
  else
    Result := Items[Index];
end;

procedure TPPGDBRadioGroup.ShowField(Sender: TObject);
var
  F: TField;
  S: string;
  I, Found: Integer;
begin
  if csLoading in ComponentState then
    Exit;
  F := FBinding.Field;
  Found := -1;
  if (F <> nil) and not F.IsNull then
  begin
    S := F.Text;
    for I := 0 to Count - 1 do
      if SameText(ItemDbValue(I), S) then
      begin
        Found := I;
        Break;
      end;
  end;
  ItemIndex := Found;
end;

procedure TPPGDBRadioGroup.WriteField(Sender: TObject);
begin
  if ItemIndex < 0 then
    FBinding.Field.Clear
  else
    FBinding.Field.Text := ItemDbValue(ItemIndex);
end;

procedure TPPGDBRadioGroup.ActivateItem(Index: Integer);
begin
  // Erst Bearbeiten-Modus (ReadOnly, nicht aenderbare Menge: nichts tun)
  if (csDesigning in ComponentState) or (Index = ItemIndex) then
    Exit;
  if not FBinding.TryEdit then
    Exit;
  inherited ActivateItem(Index);
  FBinding.Link.Modified;
end;

procedure TPPGDBRadioGroup.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if FBinding.HandleEscape(Key) then
    Exit;
  inherited KeyDown(Key, Shift);
end;

procedure TPPGDBRadioGroup.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FBinding.Link);
end;

procedure TPPGDBRadioGroup.CMExit(var Message: TCMExit);
begin
  // Im Destruktor ist FBinding schon frei; der Fokusverlust beim
  // Zerstoeren des Fensters schickt trotzdem noch CM_EXIT
  if FBinding = nil then
  begin
    inherited;
    Exit;
  end;
  if FBinding.Link.Editing and FBinding.Link.Active then
  try
    FBinding.Link.UpdateRecord;
  except
    on Exception do
    begin
      // Wie die Felder: kein Dialog, Fokus bleibt, Fehler am Control
      ValidationState := pvsError;
      if CanFocus and IsWindowVisible(Handle) then
        SetFocus;
      Exit;
    end;
  end;
  inherited;
end;

function TPPGDBRadioGroup.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FBinding <> nil) and FBinding.ExecuteAction(Action));
end;

function TPPGDBRadioGroup.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FBinding <> nil) and FBinding.UpdateAction(Action));
end;

initialization
  GMsgNavAction := RegisterWindowMessage('PPGlow.DBNavigator.Action');

end.
