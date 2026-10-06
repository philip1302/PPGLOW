unit PPG.ComboBox;

{ TPPGComboBox - Auswahlfeld mit eigener Aufklappliste in der Optik des Presets.

  - Basis TPPGCustomField: csDropDown nutzt das native Edit (frei editierbar,
    AutoComplete), csDropDownList blendet es aus - dann ist das Feld selbst
    Tabstopp und zeichnet den Eintrag.
  - Die Liste ist ein eigenes Popup (PPG.Popup): ohne Aktivierung, die Combo
    behaelt Fokus und Tastatur und haelt die Maus per SetCapture. Klick
    ausserhalb, Fokusverlust, Capture-Verlust und Esc schliessen ohne
    Uebernahme; Klick auf einen Eintrag und Enter uebernehmen.
  - Ereignisse wie TComboBox: Auswahl durch den Anwender loest OnClick und
    danach OnSelect aus - ist OnSelect nicht zugewiesen, stattdessen OnChange.
    Tippen im Edit loest OnChange aus. ItemIndex/Text im Code setzen loest
    (wie bei TComboBox) kein Ereignis aus.
  - Tastatur: Alt+Unten/Alt+Oben/F4 klappen auf/zu; geschlossen waehlen
    Oben/Unten/Bild/(Pos1/Ende bei csDropDownList) direkt; offen bewegen sie
    die Hervorhebung, Enter uebernimmt, Esc verwirft. Tippsuche ueber die
    Anfangsbuchstaben bei csDropDownList.
  - Migration: Property-Namen von TComboBox (Style, Items, ItemIndex,
    DropDownCount, Sorted, AutoComplete, ...). csSimple wird wie csDropDown,
    csOwnerDraw* wie csDropDownList behandelt (Owner-Draw gibt es nicht).
    ItemHeight ist eine Mindesthoehe der Zeilen (0 = aus der Schrift). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Controls.Field, PPG.Popup, PPG.Items;

type
  /// Filtern beim Tippen (csDropDown): keiner, Anfang, irgendwo im Text.
  TPPGFilterMode = (fmNone, fmPrefix, fmContains);

  TPPGCustomComboBox = class(TPPGCustomField)
  private
    FItems: TStringList;
    FItemIndex: Integer;
    FLoadedItemIndex: Integer;
    FStyle: TComboBoxStyle;
    FDropDownCount: Integer;
    FDropDownWidth: Integer;
    FItemHeight: Integer;
    FAutoComplete: Boolean;
    FAutoDropDown: Boolean;
    FAutoCloseUp: Boolean;
    FPopup: TPPGPopupList;
    FDroppedDown: Boolean;
    FArrowAnim: TPPGAnimation;
    FQuiet: Integer;
    FTyping: Boolean;
    FSearchText: string;
    FSearchTick: Cardinal;
    FDisplayText: string; // Text ohne WM_GETTEXT (Paint sendet keine Nachrichten)
    FItemsEx: TPPGItems;
    FItemsExSource: IPPGItemSource;
    FFilterMode: TPPGFilterMode;
    FSyncingItems: Boolean;
    FOnSelect: TNotifyEvent;
    FOnDropDown: TNotifyEvent;
    FOnCloseUp: TNotifyEvent;
    function GetItems: TStrings;
    procedure SetItems(const Value: TStrings);
    procedure SetItemIndex(const Value: Integer);
    procedure SetStyle(const Value: TComboBoxStyle);
    procedure SetDropDownCount(const Value: Integer);
    procedure SetDropDownWidth(const Value: Integer);
    procedure SetItemHeight(const Value: Integer);
    function GetSorted: Boolean;
    procedure SetSorted(const Value: Boolean);
    procedure SetDroppedDown(const Value: Boolean);
    function GetComboText: string;
    procedure SetComboText(const Value: string);
    procedure SetTextQuiet(const Value: string);
    procedure ItemsChanged(Sender: TObject);
    procedure ArrowAnimStep(Sender: TObject);
    procedure PopupItemClick(Sender: TObject; Index: Integer);
    procedure HandleDroppedMouse(var Message: TMessage);
    procedure TypeAhead(Key: Char);
    procedure StepSelection(Delta: Integer);
    procedure SyncPopupToText;
    procedure SetItemsEx(const Value: TPPGItems);
    procedure ItemsExChange(Sender: TObject; Index: Integer);
    procedure SyncItemsFromEx;
    procedure PlacePopup(Duration: Cardinal);
    function UseItemsEx: Boolean;
    function ItemsExHasDetail: Boolean;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    procedure Loaded; override;
    procedure WndProc(var Message: TMessage); override;
    /// Offene Liste nach Theme-/Appearance-Wechsel neu einfaerben.
    procedure AppearanceUpdated; override;
    procedure GetButtons(var Buttons: TPPGFieldButtons); override;
    procedure ButtonDown(Id: Integer); override;
    procedure ButtonClick(Id: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure FieldKeyPress(var Key: Char); override;
    function WantSpecialKey(Key: Word): Boolean; override;
    procedure FocusChanged; override;
    procedure Change; override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    procedure DoPaintField(const ACanvas: IPPGCanvas; const Style: TPPGSurfaceStyle); override;
    function AccRole: Integer; override;
    function AccState: Integer; override;
    function AccValue: string; override;
    function AccDefaultAction: string; override;
    procedure AccDoDefaultAction; override;
    /// True bei csDropDown/csSimple (Text frei editierbar).
    function EditableStyle: Boolean;
    /// Eintrag mit genau diesem Text (ohne Gross-/Kleinschreibung), -1 = keiner.
    function IndexOfText(const S: string): Integer;
    /// Auswahl durch den Anwender: setzt ItemIndex und loest OnClick und
    /// OnSelect (bzw. OnChange) aus - nur, wenn sich etwas aendert.
    procedure SelectIndex(Index: Integer);
    procedure DoSelect; virtual;
    procedure DoDropDown; virtual;
    procedure DoCloseUp; virtual;
    /// Liste nach dem getippten Text filtern (FilterMode) und ggf. aufklappen.
    procedure ApplyFilter;
    /// True, solange der Text im Code gesetzt wird (keine Ereignisse).
    function IsQuiet: Boolean;

    property AutoCloseUp: Boolean read FAutoCloseUp write FAutoCloseUp default False;
    property AutoComplete: Boolean read FAutoComplete write FAutoComplete default True;
    property AutoDropDown: Boolean read FAutoDropDown write FAutoDropDown default False;
    property DropDownCount: Integer read FDropDownCount write SetDropDownCount default 8;
    property DropDownWidth: Integer read FDropDownWidth write SetDropDownWidth default 0;
    property ItemHeight: Integer read FItemHeight write SetItemHeight default 0;
    property ItemIndex: Integer read FItemIndex write SetItemIndex default -1;
    property Items: TStrings read GetItems write SetItems;
    property Sorted: Boolean read GetSorted write SetSorted default False;
    property Style: TComboBoxStyle read FStyle write SetStyle default csDropDown;
    /// Reiche Eintraege (Bild aus Images, Detailzeile, Plakette, Markup). Sind
    /// welche vorhanden, sind sie die Eintraege (Items enthaelt dann ihre Texte).
    property ItemsEx: TPPGItems read FItemsEx write SetItemsEx;
    /// Filtern beim Tippen (nur csDropDown): die Liste zeigt nur Treffer.
    property FilterMode: TPPGFilterMode read FFilterMode write FFilterMode default fmNone;
    property OnCloseUp: TNotifyEvent read FOnCloseUp write FOnCloseUp;
    property OnDropDown: TNotifyEvent read FOnDropDown write FOnDropDown;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Wie TComboBox.Clear: leert Eintraege und Text.
    procedure Clear; override;
    procedure AddItem(const Item: string; AObject: TObject);
    /// Klappt die Liste auf (OnDropDown) bzw. zu (Accept: Hervorhebung uebernehmen).
    procedure DropDown;
    procedure CloseUp(Accept: Boolean);
    /// Fortschritt der Pfeildrehung (0 = zu, 1 = offen).
    function ArrowProgress: Single;
    property DroppedDown: Boolean read FDroppedDown write SetDroppedDown;
    /// Die Aufklappliste (nil, solange sie nie geoeffnet wurde).
    property PopupList: TPPGPopupList read FPopup;
    property Text: string read GetComboText write SetComboText;
  end;

  TPPGComboBox = class(TPPGCustomComboBox)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Images;
    property ItemsEx;
    property FilterMode;
    property ShowClearButton;
    property TextHint;
    property UseSystemContextMenu;
    property TextHintVisibleOnFocus;
    property ValidationState;
    property ValidationHint;
    property HighContrastSupport;
    { wie TComboBox }
    property Align;
    property Anchors;
    property AutoCloseUp;
    property AutoComplete;
    property AutoDropDown;
    property AutoSize default True;
    property BiDiMode;
    property BorderStyle;
    property CharCase;
    property Color default clWindow;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property DropDownCount;
    property DropDownWidth;
    property Enabled;
    property Font;
    property ItemHeight;
    property Items;
    property ItemIndex;
    property MaxLength;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Sorted;
    property Style;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop;
    property Text;
    property Visible;
    property OnChange;
    property OnClick;
    property OnCloseUp;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDropDown;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnSelect;
    property OnStartDock;
    property OnStartDrag;
  end;

const
  /// Button-Id des Aufklapp-Pfeils.
  PPGComboButtonDrop = 20;

implementation

uses
  PPG.Lang,
  System.SysUtils, System.StrUtils, Winapi.oleacc,
  PPG.Consts, PPG.Appearance, PPG.Render.Registry, PPG.Markup;

type
  /// Reiche Eintraege der Combo fuer die Liste (Indizes wie Items).
  TComboExSource = class(TPPGItemSourceBase)
  private
    FOwner: TPPGCustomComboBox;
  public
    function Count: Integer; override;
    procedure GetItem(Index: Integer; var Data: TPPGItemData); override;
  end;

function TComboExSource.Count: Integer;
begin
  if (FOwner = nil) or (FOwner.FItemsEx = nil) then
    Result := 0
  else
    Result := FOwner.FItemsEx.Count;
end;

procedure TComboExSource.GetItem(Index: Integer; var Data: TPPGItemData);
var
  It: TPPGItem;
begin
  if (Index < 0) or (Index >= Count) then
    Exit;
  It := FOwner.FItemsEx[Index];
  Data.Text := It.Text;
  Data.Detail := It.Detail;
  Data.Badge := It.Badge;
  Data.ImageIndex := It.ImageIndex;
  Data.Enabled := It.Enabled;
  Data.Data := It.Data;
end;

var
  GMsgToggle: Cardinal = 0;

const
  SearchResetMs = 1000; // Tippsuche: Pause, nach der ein neuer Suchtext beginnt
  WheelLines = 3;

{ TPPGCustomComboBox }

constructor TPPGCustomComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TStringList.Create;
  FItems.OnChange := ItemsChanged;
  FItemIndex := -1;
  FLoadedItemIndex := -2;
  FStyle := csDropDown;
  FDropDownCount := 8;
  FAutoComplete := True;
  FItemsEx := TPPGItems.Create(Self);
  FItemsEx.OnChange := ItemsExChange;
  FItemsExSource := TComboExSource.Create;
  TComboExSource(FItemsExSource as TObject).FOwner := Self;
  FArrowAnim := TPPGAnimation.Create(Self);
  FArrowAnim.OnStep := ArrowAnimStep;
  Width := 145;
  if GMsgToggle = 0 then
    GMsgToggle := RegisterWindowMessage('PPGlow.ComboToggle');
end;

destructor TPPGCustomComboBox.Destroy;
begin
  // Zuerst das Popup schliessen und freigeben (ohne Ereignisse)
  if FDroppedDown then
  begin
    FDroppedDown := False;
    if HandleAllocated and (GetCapture = Handle) then
      ReleaseCapture;
  end;
  FreeAndNil(FPopup);
  if FArrowAnim <> nil then
    FArrowAnim.OnStep := nil;
  FreeAndNil(FArrowAnim); // meldet sich selbst beim Animator ab
  if FItemsEx <> nil then
    FItemsEx.OnChange := nil;
  if FItemsExSource <> nil then
    TComboExSource(FItemsExSource as TObject).FOwner := nil;
  FItemsExSource := nil;
  if FItems <> nil then
    FItems.OnChange := nil;
  inherited Destroy;
  FreeAndNil(FItemsEx);
  FreeAndNil(FItems);
end;

procedure TPPGCustomComboBox.Loaded;
var
  I: Integer;
begin
  inherited Loaded;
  if UseItemsEx then
    SyncItemsFromEx;
  SetInnerVisible(EditableStyle);
  // ItemIndex wird erst jetzt angewendet: Items koennen in der DFM spaeter kommen
  I := FLoadedItemIndex;
  FLoadedItemIndex := -2;
  if I >= 0 then
    SetItemIndex(I)
  else
  begin
    FItemIndex := IndexOfText(GetComboText);
    if not EditableStyle and (FItemIndex < 0) then
      SetTextQuiet('')
    else
      FDisplayText := GetComboText;
  end;
end;

function TPPGCustomComboBox.EditableStyle: Boolean;
begin
  Result := FStyle in [csDropDown, csSimple];
end;

function TPPGCustomComboBox.IndexOfText(const S: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  if FItems = nil then
    Exit;
  for I := 0 to FItems.Count - 1 do
    if AnsiSameText(FItems[I], S) then
      Exit(I);
end;

{ ---- Properties ---- }

function TPPGCustomComboBox.GetItems: TStrings;
begin
  Result := FItems;
end;

procedure TPPGCustomComboBox.SetItems(const Value: TStrings);
begin
  FItems.Assign(Value);
end;

procedure TPPGCustomComboBox.SetItemIndex(const Value: Integer);
var
  V: Integer;
begin
  if csLoading in ComponentState then
  begin
    FLoadedItemIndex := Value;
    Exit;
  end;
  // Wie TComboBox: ungueltiger Index = keine Auswahl (ohne Exception)
  V := Value;
  if (V < -1) or (V >= FItems.Count) then
    V := -1;
  FItemIndex := V;
  if V >= 0 then
    SetTextQuiet(FItems[V])
  else
    SetTextQuiet('');
  if FPopup <> nil then
    FPopup.ItemIndex := V;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
end;

procedure TPPGCustomComboBox.SetTextQuiet(const Value: string);
begin
  Inc(FQuiet);
  try
    TPPGCustomField(Self).Text := Value;
  finally
    Dec(FQuiet);
  end;
  FDisplayText := Value;
end;

function TPPGCustomComboBox.GetComboText: string;
begin
  Result := TPPGCustomField(Self).Text;
end;

procedure TPPGCustomComboBox.SetComboText(const Value: string);
var
  I: Integer;
begin
  if csLoading in ComponentState then
  begin
    SetTextQuiet(Value); // Loaded gleicht mit den Eintraegen ab
    Exit;
  end;
  I := IndexOfText(Value);
  if EditableStyle then
  begin
    SetTextQuiet(Value);
    FItemIndex := I;
    if FPopup <> nil then
      FPopup.ItemIndex := I;
    NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
  end
  else if I >= 0 then
    SetItemIndex(I); // Liste: nur vorhandene Eintraege (sonst unveraendert)
end;

procedure TPPGCustomComboBox.SetStyle(const Value: TComboBoxStyle);
begin
  if FStyle = Value then
    Exit;
  CloseUp(False);
  FStyle := Value;
  if csLoading in ComponentState then
    Exit; // Loaded blendet das Edit passend ein/aus
  SetInnerVisible(EditableStyle);
  if not EditableStyle and (FItemIndex < 0) then
    SetTextQuiet('');
  Invalidate;
end;

procedure TPPGCustomComboBox.SetDropDownCount(const Value: Integer);
begin
  FDropDownCount := PPGCheckRange(Self, 'DropDownCount', Value, 1, MaxInt);
end;

procedure TPPGCustomComboBox.SetDropDownWidth(const Value: Integer);
begin
  FDropDownWidth := PPGCheckRange(Self, 'DropDownWidth', Value, 0, MaxInt);
end;

procedure TPPGCustomComboBox.SetItemHeight(const Value: Integer);
begin
  FItemHeight := PPGCheckRange(Self, 'ItemHeight', Value, 0, 1000);
end;

function TPPGCustomComboBox.GetSorted: Boolean;
begin
  Result := FItems.Sorted;
end;

procedure TPPGCustomComboBox.SetSorted(const Value: Boolean);
begin
  FItems.Sorted := Value; // ItemsChanged findet den gewaehlten Eintrag wieder
end;

procedure TPPGCustomComboBox.ItemsChanged(Sender: TObject);
var
  S: string;
begin
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  // Auswahl behalten, solange der Eintrag noch passt; sonst ueber den Text
  // wiederfinden (z.B. nach dem Sortieren)
  S := FDisplayText;
  if not ((FItemIndex >= 0) and (FItemIndex < FItems.Count) and
    AnsiSameText(FItems[FItemIndex], S)) then
  begin
    FItemIndex := IndexOfText(S);
    if not EditableStyle and (FItemIndex < 0) and (S <> '') then
      SetTextQuiet('');
    NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
  end;
  if FPopup <> nil then
  begin
    FPopup.ItemIndex := FItemIndex;
    if FPopup.Highlight >= FItems.Count then
      FPopup.SetHighlight(-1);
    FPopup.TopIndex := FPopup.TopIndex; // auf gueltigen Bereich begrenzen
    FPopup.Invalidate;
  end;
  Invalidate;
end;

function TPPGCustomComboBox.UseItemsEx: Boolean;
begin
  Result := (FItemsEx <> nil) and (FItemsEx.Count > 0);
end;

function TPPGCustomComboBox.ItemsExHasDetail: Boolean;
var
  I: Integer;
begin
  Result := False;
  if UseItemsEx then
    for I := 0 to FItemsEx.Count - 1 do
      if FItemsEx[I].Detail <> '' then
        Exit(True);
end;

procedure TPPGCustomComboBox.SetItemsEx(const Value: TPPGItems);
begin
  FItemsEx.Assign(Value);
end;

procedure TPPGCustomComboBox.SyncItemsFromEx;
var
  I: Integer;
begin
  // Items enthaelt die (markupfreien) Texte: Suche, AutoComplete, Text und
  // Screenreader arbeiten unveraendert ueber Items
  FSyncingItems := True;
  try
    FItems.BeginUpdate;
    try
      FItems.Clear;
      for I := 0 to FItemsEx.Count - 1 do
        FItems.Add(PPGStripMarkup(FItemsEx[I].Text));
    finally
      FItems.EndUpdate;
    end;
  finally
    FSyncingItems := False;
  end;
end;

procedure TPPGCustomComboBox.ItemsExChange(Sender: TObject; Index: Integer);
begin
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit; // Loaded gleicht ab
  if Index >= 0 then
  begin
    if (Index < FItems.Count) then
      FItems[Index] := PPGStripMarkup(FItemsEx[Index].Text);
  end
  else
    SyncItemsFromEx;
  if FPopup <> nil then
    FPopup.Invalidate;
  Invalidate;
end;

procedure TPPGCustomComboBox.PlacePopup(Duration: Cardinal);
var
  P: TPoint;
  Anchor: TRect;
  Rows, W: Integer;
begin
  Rows := FPopup.RowCount;
  if Rows > FDropDownCount then
    Rows := FDropDownCount;
  if Rows < 1 then
    Rows := 1;
  W := Width;
  if FDropDownWidth > W then
    W := FDropDownWidth;
  P := ClientToScreen(Point(0, 0));
  Anchor := Rect(P.X, P.Y, P.X + Width, P.Y + Height);
  FPopup.Popup(Anchor, W, FPopup.HeightForRows(Rows), UseRightToLeftAlignment, Duration);
end;

procedure TPPGCustomComboBox.ApplyFilter;
var
  Map: TArray<Integer>;
  I, N: Integer;
  S: string;
  Match: Boolean;
begin
  S := FDisplayText;
  if S = '' then
  begin
    // Leerer Text: wieder alle Eintraege
    if FDroppedDown and (FPopup <> nil) and FPopup.Filtered then
    begin
      FPopup.ClearFilter;
      PlacePopup(0);
    end;
    Exit;
  end;
  SetLength(Map, FItems.Count);
  N := 0;
  for I := 0 to FItems.Count - 1 do
  begin
    if FFilterMode = fmContains then
      Match := AnsiContainsText(FItems[I], S)
    else
      Match := AnsiStartsText(S, FItems[I]);
    if Match then
    begin
      Map[N] := I;
      Inc(N);
    end;
  end;
  SetLength(Map, N);
  if N = 0 then
  begin
    CloseUp(False); // keine Treffer: Liste zu, Text bleibt
    Exit;
  end;
  if not FDroppedDown then
    DropDown;
  if not FDroppedDown or (FPopup = nil) then
    Exit;
  FPopup.SetFilter(Map);
  PlacePopup(0);
  FPopup.SetHighlight(Map[0]);
end;

function TPPGCustomComboBox.IsQuiet: Boolean;
begin
  Result := FQuiet > 0;
end;

procedure TPPGCustomComboBox.Clear;
begin
  CloseUp(False);
  FItems.Clear;
  SetItemIndex(-1);
end;

procedure TPPGCustomComboBox.AddItem(const Item: string; AObject: TObject);
begin
  FItems.AddObject(Item, AObject);
end;

{ ---- Auswahl ---- }

procedure TPPGCustomComboBox.SelectIndex(Index: Integer);
begin
  if (Index < -1) or (Index >= FItems.Count) then
    Exit;
  if (Index = FItemIndex) and ((Index < 0) or (FItems[Index] = FDisplayText)) then
    Exit;
  SetItemIndex(Index);
  if EditableStyle and FieldFocused then
    SelectAll;
  Click;
  DoSelect;
end;

procedure TPPGCustomComboBox.DoSelect;
begin
  // Wie TComboBox.Select: OnSelect, sonst OnChange
  if Assigned(FOnSelect) then
    FOnSelect(Self)
  else
    inherited Change;
end;

procedure TPPGCustomComboBox.StepSelection(Delta: Integer);
var
  I: Integer;
begin
  if FItems.Count = 0 then
    Exit;
  if FItemIndex < 0 then
  begin
    if Delta > 0 then
      I := 0
    else
      Exit;
  end
  else
    I := FItemIndex + Delta;
  if I < 0 then
    I := 0;
  if I > FItems.Count - 1 then
    I := FItems.Count - 1;
  SelectIndex(I);
end;

procedure TPPGCustomComboBox.Change;
var
  S: string;
  I: Integer;
  WasTyping: Boolean;
begin
  // Text im Code gesetzt: kein Ereignis (wie TComboBox)
  if FQuiet > 0 then
    Exit;
  WasTyping := FTyping;
  FTyping := False;
  S := GetComboText;
  // AutoComplete: getippten Anfang zum ersten passenden Eintrag ergaenzen,
  // der ergaenzte Rest bleibt markiert (Weitertippen ueberschreibt ihn)
  // (Mit FilterMode filtert die Liste statt zu ergaenzen.)
  if WasTyping and FAutoComplete and (FFilterMode = fmNone) and (S <> '') and
    (SelStart = Length(S)) then
    for I := 0 to FItems.Count - 1 do
      if AnsiStartsText(S, FItems[I]) then
      begin
        if Length(FItems[I]) > Length(S) then
        begin
          SetTextQuiet(FItems[I]);
          SelStart := Length(S);
          SelLength := Length(FItems[I]) - Length(S);
          S := FItems[I];
        end;
        Break;
      end;
  FDisplayText := S;
  FItemIndex := IndexOfText(S);
  if FPopup <> nil then
    FPopup.ItemIndex := FItemIndex;
  if WasTyping and (FFilterMode <> fmNone) and EditableStyle then
    ApplyFilter
  else
  begin
    if WasTyping and FAutoDropDown and not FDroppedDown then
      DropDown;
    SyncPopupToText;
  end;
  inherited Change;
end;

procedure TPPGCustomComboBox.SyncPopupToText;
var
  I: Integer;
begin
  if not FDroppedDown or (FPopup = nil) then
    Exit;
  // Offene Liste folgt dem getippten Text
  if FItemIndex >= 0 then
    FPopup.SetHighlight(FItemIndex)
  else if FDisplayText <> '' then
    for I := 0 to FItems.Count - 1 do
      if AnsiStartsText(FDisplayText, FItems[I]) then
      begin
        FPopup.SetHighlight(I);
        Break;
      end;
end;

procedure TPPGCustomComboBox.TypeAhead(Key: Char);
var
  Now: Cardinal;
  Cur, Start, I, J, N: Integer;
  S: string;
  Same: Boolean;
begin
  N := FItems.Count;
  if N = 0 then
    Exit;
  Now := GetTickCount;
  if Now - FSearchTick > SearchResetMs then
    FSearchText := '';
  FSearchTick := Now;
  FSearchText := FSearchText + Key;
  if FDroppedDown then
    Cur := FPopup.Highlight
  else
    Cur := FItemIndex;
  // Derselbe Buchstabe wiederholt: durch die Eintraege mit diesem Anfang
  // blaettern (wie Windows); sonst Praefix ab dem aktuellen Eintrag suchen
  Same := True;
  for I := 2 to Length(FSearchText) do
    if FSearchText[I] <> FSearchText[1] then
      Same := False;
  if Same then
  begin
    S := FSearchText[1];
    Start := Cur + 1;
  end
  else
  begin
    S := FSearchText;
    Start := Cur;
  end;
  if Start < 0 then
    Start := 0;
  for I := 0 to N - 1 do
  begin
    J := (Start + I) mod N;
    if AnsiStartsText(S, FItems[J]) then
    begin
      if FDroppedDown then
      begin
        FPopup.SetHighlight(J);
        if FAutoCloseUp then
          CloseUp(True);
      end
      else
        SelectIndex(J);
      Exit;
    end;
  end;
end;

{ ---- Aufklappen ---- }

procedure TPPGCustomComboBox.SetDroppedDown(const Value: Boolean);
begin
  if Value then
    DropDown
  else
    CloseUp(False);
end;

procedure TPPGCustomComboBox.AppearanceUpdated;
var
  Fill, TextColor: TColor;
begin
  inherited AppearanceUpdated;
  if FPopup <> nil then
  begin
    GetFieldColors(Fill, TextColor);
    FPopup.ListColor := Fill;
    FPopup.TextColor := TextColor;
    FPopup.Invalidate;
  end;
end;

procedure TPPGCustomComboBox.DropDown;
var
  Fill, TextColor: TColor;
  Duration: Cardinal;
begin
  if FDroppedDown or not Enabled or (csDesigning in ComponentState) or
    not HandleAllocated or not IsWindowVisible(Handle) then
    Exit;
  DoDropDown; // darf die Eintraege noch aendern
  if FDroppedDown or not HandleAllocated then
    Exit;
  if FPopup = nil then
  begin
    FPopup := TPPGPopupList.Create(Self);
    FPopup.Items := FItems;
    FPopup.OnItemClick := PopupItemClick;
  end;
  FPopup.SyncFrom(Self);
  GetFieldColors(Fill, TextColor);
  FPopup.ListColor := Fill;
  FPopup.TextColor := TextColor;
  FPopup.MinItemHeight := FItemHeight;
  FPopup.ListName := AccName;
  FPopup.ItemIndex := FItemIndex;
  FPopup.ClearFilter;
  // Reiche Eintraege: Bild, Detailzeile, Plakette ueber die Quelle
  if UseItemsEx then
    FPopup.Source := FItemsExSource
  else
    FPopup.Source := nil;
  FPopup.TwoLineItems := ItemsExHasDetail;
  FPopup.SetHighlight(-1);
  if Animation.EffectiveEnabled then
    Duration := Animation.Duration
  else
    Duration := 0;

  FDroppedDown := True;
  PlacePopup(Duration);
  FPopup.TopIndex := 0;
  FPopup.SetHighlight(FItemIndex);
  // Maus fuer Klicks ausserhalb; Tastatur bleibt beim Feld bzw. Edit
  SetCapture(Handle);
  if Duration > 0 then
    FArrowAnim.AnimateTo(1, Duration)
  else
    FArrowAnim.Jump(1);
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
end;

procedure TPPGCustomComboBox.CloseUp(Accept: Boolean);
var
  Idx: Integer;
begin
  if not FDroppedDown then
    Exit;
  FDroppedDown := False;
  Idx := -1;
  if FPopup <> nil then
  begin
    Idx := FPopup.Highlight;
    FPopup.ClosePopup;
    FPopup.ClearFilter;
  end;
  if HandleAllocated and (GetCapture = Handle) then
    ReleaseCapture;
  CancelButtonPress;
  if Animation.EffectiveEnabled and HandleAllocated and IsWindowVisible(Handle) then
    FArrowAnim.AnimateTo(0, Animation.Duration)
  else
    FArrowAnim.Jump(0);
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
  // Zuerst die Auswahl (OnClick/OnSelect), dann OnCloseUp - dort ist
  // ItemIndex schon aktuell
  if Accept and (Idx >= 0) then
    SelectIndex(Idx);
  DoCloseUp;
end;

procedure TPPGCustomComboBox.DoDropDown;
begin
  if Assigned(FOnDropDown) then
    FOnDropDown(Self);
end;

procedure TPPGCustomComboBox.DoCloseUp;
begin
  if Assigned(FOnCloseUp) then
    FOnCloseUp(Self);
end;

procedure TPPGCustomComboBox.PopupItemClick(Sender: TObject; Index: Integer);
begin
  // Standardaktion eines Eintrags (Screenreader)
  if FDroppedDown then
  begin
    FPopup.SetHighlight(Index);
    CloseUp(True);
  end
  else
    SelectIndex(Index);
end;

function TPPGCustomComboBox.ArrowProgress: Single;
begin
  if FArrowAnim = nil then
    Result := 0
  else
    Result := FArrowAnim.Value;
end;

procedure TPPGCustomComboBox.ArrowAnimStep(Sender: TObject);
begin
  Invalidate;
end;

{ ---- Maus ---- }

procedure TPPGCustomComboBox.WndProc(var Message: TMessage);
begin
  if FDroppedDown then
    case Message.Msg of
      WM_MOUSEMOVE, WM_LBUTTONDOWN, WM_LBUTTONDBLCLK, WM_LBUTTONUP,
      WM_RBUTTONDOWN, WM_RBUTTONDBLCLK, WM_RBUTTONUP,
      WM_MBUTTONDOWN, WM_MBUTTONDBLCLK, WM_MBUTTONUP:
        begin
          HandleDroppedMouse(Message);
          Exit;
        end;
    end;
  if (GMsgToggle <> 0) and (Message.Msg = GMsgToggle) then
  begin
    // Aus AccDoDefaultAction gepostet (ausserhalb des COM-Aufrufs)
    if FDroppedDown then
      CloseUp(False)
    else
      DropDown;
    Exit;
  end;
  inherited WndProc(Message);
end;

procedure TPPGCustomComboBox.HandleDroppedMouse(var Message: TMessage);
var
  P, PP: TPoint;
  InPopup: Boolean;
  Idx: Integer;
begin
  Message.Result := 0;
  if FPopup = nil then
    Exit;
  // Maus gehoert der Combo (SetCapture): Koordinaten ins Popup umrechnen
  // XPos/YPos sind SmallInt: ausserhalb links/oben negativ (kein LoWord!)
  P := Point(TWMMouse(Message).XPos, TWMMouse(Message).YPos);
  PP := FPopup.ScreenToClient(ClientToScreen(P));
  InPopup := FPopup.HandleAllocated and
    PtInRect(Rect(0, 0, FPopup.Width, FPopup.Height), PP);
  case Message.Msg of
    WM_MOUSEMOVE:
      FPopup.MouseMoveAt(PP.X, PP.Y);
    WM_LBUTTONDOWN, WM_LBUTTONDBLCLK:
      if InPopup then
        FPopup.MouseDownAt(PP.X, PP.Y)
      else
        CloseUp(False); // Klick auf das Feld oder ausserhalb: schliessen
    WM_LBUTTONUP:
      begin
        // Der oeffnende Klick hat ggf. den Pfeil-Button gedrueckt
        CancelButtonPress;
        ControlState := ControlState - [csClicked];
        Idx := FPopup.MouseUpAt(PP.X, PP.Y);
        if InPopup and (Idx >= 0) then
        begin
          FPopup.SetHighlight(Idx);
          CloseUp(True);
        end;
      end;
    WM_RBUTTONDOWN, WM_RBUTTONDBLCLK, WM_MBUTTONDOWN, WM_MBUTTONDBLCLK:
      if not InPopup then
        CloseUp(False);
  end;
end;

procedure TPPGCustomComboBox.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  // csDropDownList: das ganze Feld klappt auf (wie Windows)
  if (Button = mbLeft) and Enabled and not EditableStyle and not FDroppedDown and
    (ButtonAt(X, Y) < 0) then
    DropDown;
end;

procedure TPPGCustomComboBox.WMCaptureChanged(var Message: TMessage);
begin
  inherited;
  // Maus verloren (Dialog, Alt+Tab, anderes Fenster): ohne Uebernahme schliessen
  if FDroppedDown and (HWND(Message.LParam) <> Handle) then
    CloseUp(False);
end;

procedure TPPGCustomComboBox.CMEnabledChanged(var Message: TMessage);
begin
  if not Enabled then
    CloseUp(False);
  inherited;
end;

procedure TPPGCustomComboBox.CMVisibleChanged(var Message: TMessage);
begin
  if not Visible then
    CloseUp(False);
  inherited;
end;

function TPPGCustomComboBox.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  if FDroppedDown and (FPopup <> nil) then
  begin
    if WheelDelta > 0 then
      FPopup.ScrollLines(-WheelLines)
    else if WheelDelta < 0 then
      FPopup.ScrollLines(WheelLines);
    Result := True;
    Exit;
  end;
  // Geschlossen aendert das Rad die Auswahl bewusst nicht (versehentliches
  // Umstellen beim Scrollen des Formulars)
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
end;

{ ---- Buttons ---- }

procedure TPPGCustomComboBox.GetButtons(var Buttons: TPPGFieldButtons);
var
  N: Integer;
begin
  inherited GetButtons(Buttons);
  N := Length(Buttons);
  SetLength(Buttons, N + 1);
  Buttons[N].Id := PPGComboButtonDrop;
  Buttons[N].Glyph := fgNone; // Pfeil zeichnet DoPaintField (mit Drehung)
  Buttons[N].ImageIndex := -1;
  Buttons[N].LeftSide := False;
end;

procedure TPPGCustomComboBox.ButtonDown(Id: Integer);
begin
  if Id = PPGComboButtonDrop then
    DropDown // Schliessen per Klick erledigt HandleDroppedMouse
  else
    inherited ButtonDown(Id);
end;

procedure TPPGCustomComboBox.ButtonClick(Id: Integer);
begin
  if Id = PPGFieldButtonClear then
  begin
    if (FItemIndex <> -1) or (FDisplayText <> '') then
    begin
      SetItemIndex(-1);
      inherited Change; // Anwender hat geleert: OnChange
    end;
    if not FieldFocused and CanFocus then
      SetFocus;
    Exit;
  end;
  inherited ButtonClick(Id);
end;

{ ---- Tastatur ---- }

function TPPGCustomComboBox.WantSpecialKey(Key: Word): Boolean;
begin
  // Offene Liste: Enter/Esc gehoeren ihr, nicht Default-/Cancel-Button
  Result := FDroppedDown and ((Key = VK_RETURN) or (Key = VK_ESCAPE));
end;

procedure TPPGCustomComboBox.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  // csDropDownList: das Feld selbst bekommt Pfeiltasten und Zeichen
  Message.Result := Message.Result or DLGC_WANTARROWS or DLGC_WANTCHARS;
end;

procedure TPPGCustomComboBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift); // OnKeyDown
  if (Key <> 0) and not InnerVisible then
    FieldKeyDown(Key, Shift);
end;

procedure TPPGCustomComboBox.KeyPress(var Key: Char);
begin
  inherited KeyPress(Key); // OnKeyPress
  if (Key <> #0) and not InnerVisible then
    FieldKeyPress(Key);
end;

procedure TPPGCustomComboBox.FieldKeyDown(var Key: Word; Shift: TShiftState);
var
  Page: Integer;
begin
  if FDroppedDown and (FPopup <> nil) then
    Page := FPopup.VisibleRows - 1
  else
    Page := FDropDownCount - 1;
  if Page < 1 then
    Page := 1;
  case Key of
    VK_UP, VK_DOWN:
      if ssAlt in Shift then
      begin
        if FDroppedDown then
          CloseUp(True)
        else
          DropDown;
      end
      else if FDroppedDown then
      begin
        if Key = VK_UP then
          FPopup.MoveHighlight(-1)
        else
          FPopup.MoveHighlight(1);
      end
      else if Key = VK_UP then
        StepSelection(-1)
      else
        StepSelection(1);
    VK_F4:
      if Shift = [] then
      begin
        if FDroppedDown then
          CloseUp(True)
        else
          DropDown;
      end
      else
        Exit;
    VK_PRIOR, VK_NEXT:
      if FDroppedDown then
      begin
        if Key = VK_PRIOR then
          FPopup.MoveHighlight(-Page)
        else
          FPopup.MoveHighlight(Page);
      end
      else if Key = VK_PRIOR then
        StepSelection(-Page)
      else
        StepSelection(Page);
    VK_HOME, VK_END:
      begin
        if EditableStyle then
          Exit; // Pos1/Ende bewegen den Cursor im Edit
        if FItems.Count = 0 then
          Exit;
        if FDroppedDown then
        begin
          // Zeilen der (ggf. gefilterten) Liste
          if Key = VK_HOME then
            FPopup.SetHighlight(FPopup.ItemOfRow(0))
          else
            FPopup.SetHighlight(FPopup.ItemOfRow(FPopup.RowCount - 1));
        end
        else if Key = VK_HOME then
          SelectIndex(0)
        else
          SelectIndex(FItems.Count - 1);
      end;
    VK_RETURN:
      if FDroppedDown then
        CloseUp(True)
      else
        Exit;
    VK_ESCAPE:
      if FDroppedDown then
        CloseUp(False)
      else
        Exit;
  else
    Exit;
  end;
  Key := 0;
end;

procedure TPPGCustomComboBox.FieldKeyPress(var Key: Char);
begin
  if (Key = #13) or (Key = #27) then
  begin
    Key := #0; // kein Signalton des einzeiligen Edits
    Exit;
  end;
  if EditableStyle then
    FTyping := Key >= #32 // nur echte Zeichen ergaenzen (nicht Ruecktaste)
  else if Key >= #32 then
  begin
    TypeAhead(Key);
    Key := #0;
  end;
end;

procedure TPPGCustomComboBox.FocusChanged;
begin
  inherited FocusChanged;
  // Fokus woanders hin (Tab, Klick in ein anderes Fenster): ohne Uebernahme zu
  if FDroppedDown and not FieldFocused and not (csDestroying in ComponentState) then
    CloseUp(False);
end;

{ ---- Zeichnen ---- }

procedure TPPGCustomComboBox.DoPaintField(const ACanvas: IPPGCanvas;
  const Style: TPPGSurfaceStyle);
var
  LR: IPPGListRenderer;
  R: TRect;
  S: string;
  C: TColor;
  Flags: Cardinal;
begin
  inherited DoPaintField(ACanvas, Style);
  if not Supports(Renderer, IPPGListRenderer, LR) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName), IPPGListRenderer, LR);
  R := ButtonRect(PPGComboButtonDrop);
  LR.DrawDropArrow(ACanvas, R, Style.TextColor, ArrowProgress, ScalePPI);
  if InnerVisible then
    Exit;
  // csDropDownList: Eintrag (bzw. TextHint) an der Stelle des Edits
  R := Inner.BoundsRect;
  // Bild des gewaehlten reichen Eintrags vor dem Text
  if UseItemsEx and (Images <> nil) and (FItemIndex >= 0) and
    (FItemIndex < FItemsEx.Count) and (FItemsEx[FItemIndex].ImageIndex >= 0) and
    (FItemsEx[FItemIndex].ImageIndex < Images.Count) then
  begin
    if UseRightToLeftAlignment then
    begin
      ACanvas.DrawImage(Images, FItemsEx[FItemIndex].ImageIndex, R.Right - Images.Width,
        (R.Top + R.Bottom - Images.Height) div 2, Enabled);
      Dec(R.Right, Images.Width + PPGScale(6, ScalePPI));
    end
    else
    begin
      ACanvas.DrawImage(Images, FItemsEx[FItemIndex].ImageIndex, R.Left,
        (R.Top + R.Bottom - Images.Height) div 2, Enabled);
      Inc(R.Left, Images.Width + PPGScale(6, ScalePPI));
    end;
  end;
  if FDisplayText <> '' then
  begin
    S := FDisplayText;
    C := Style.TextColor;
  end
  else if TextHintShowing then
  begin
    S := TextHint;
    C := HintColor;
  end
  else
    Exit;
  Flags := DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS;
  Flags := DrawTextBiDiModeFlags(Flags);
  ACanvas.DrawText(R, S, Font, C, Flags);
end;

{ ---- Barrierefreiheit ---- }

function TPPGCustomComboBox.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_COMBOBOX;
end;

function TPPGCustomComboBox.AccState: Integer;
begin
  Result := inherited AccState or STATE_SYSTEM_HASPOPUP;
  if FDroppedDown then
    Result := Result or STATE_SYSTEM_EXPANDED
  else
    Result := Result or STATE_SYSTEM_COLLAPSED;
end;

function TPPGCustomComboBox.AccValue: string;
begin
  Result := FDisplayText;
end;

function TPPGCustomComboBox.AccDefaultAction: string;
begin
  if FDroppedDown then
    Result := PPGStr(@SPPGAccClose)
  else
    Result := PPGStr(@SPPGAccOpen);
end;

procedure TPPGCustomComboBox.AccDoDefaultAction;
begin
  if HandleAllocated then
    PostMessage(Handle, GMsgToggle, 0, 0);
end;

end.
