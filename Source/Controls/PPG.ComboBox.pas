unit PPG.ComboBox;

{ TPPGComboBox - Auswahlfeld mit eigener Aufklappliste in der Optik des Presets.

  - Basis TPPGCustomDropDownField (seit Phase 20e, wie ColorPicker und
    CheckComboBox): csDropDown nutzt das native Edit (frei editierbar,
    AutoComplete), csDropDownList blendet es aus - dann ist das Feld selbst
    Tabstopp und zeichnet den Eintrag.
  - Die Liste ist ein TPPGPopupList (PPG.Popup): ohne Aktivierung, die Combo
    behaelt Fokus und Tastatur und haelt die Maus per SetCapture (alles in
    der Basis). Klick ausserhalb, Fokusverlust, Capture-Verlust und Esc
    schliessen ohne Uebernahme; Klick auf einen Eintrag und Enter uebernehmen.
  - Anders als die Basis: Zeichen gehen auch bei offener Liste ins Edit
    (FieldKeyPress), Pos1/Ende im editierbaren Stil bewegen den Cursor, und
    ReadOnly verhindert das Aufklappen nicht (TComboBox kennt kein ReadOnly).
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
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Controls.Field, PPG.Controls.DropDown,
  PPG.Popup, PPG.Items,
  PPG.ItemPainter, PPG.CustomDraw;

type
  /// Filtern beim Tippen (csDropDown): keiner, Anfang, irgendwo im Text.
  TPPGFilterMode = (fmNone, fmPrefix, fmContains);

  TPPGCustomComboBox = class(TPPGCustomDropDownField, IPPGListStylesSource)
  private
    FListStyles: TPPGListStyles;
    FOnCustomDrawItem: TPPGCustomDrawItemEvent;
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
    // Sorted gilt fuer Items oder (bei ItemsEx) fuer ItemsEx; Items bleibt
    // dann unsortiert, damit die Indizes beider Listen gleich bleiben.
    FSorted: Boolean;
    FSortingEx: Boolean;
    FOnSelect: TNotifyEvent;
    function IsItemsStored: Boolean;
    procedure SetListStyles(const Value: TPPGListStyles);
    { IPPGListStylesSource }
    function GetListStyles: TPPGListStyles;
    function GetCustomDrawItem: TPPGCustomDrawItemEvent;
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
    function GetDroppedDown: Boolean;
    function GetPopupList: TPPGPopupList;
    function GetComboText: string;
    procedure SetComboText(const Value: string);
    procedure SetTextQuiet(const Value: string);
    procedure ItemsChanged(Sender: TObject);
    procedure ArrowAnimStep(Sender: TObject);
    procedure PopupItemClick(Sender: TObject; Index: Integer);
    procedure TypeAhead(Key: Char);
    procedure StepSelection(Delta: Integer);
    procedure SyncPopupToText;
    procedure SetItemsEx(const Value: TPPGItems);
    procedure ItemsExChange(Sender: TObject; Index: Integer);
    procedure SyncItemsFromEx;
    procedure SortItemsEx;
    procedure ApplySorted;
    function UseItemsEx: Boolean;
    function ItemsExHasDetail: Boolean;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    procedure Loaded; override;
    /// Offene Liste nach Theme-/Appearance-Wechsel neu einfaerben.
    procedure AppearanceUpdated; override;
    procedure GetButtons(var Buttons: TPPGFieldButtons); override;
    procedure ButtonClick(Id: Integer); override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure FieldKeyPress(var Key: Char); override;
    procedure ClosedKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure Change; override;
    procedure DoPaintField(const ACanvas: IPPGCanvas; const Style: TPPGSurfaceStyle); override;
    function AccValue: string; override;
    { Aufklapp-Basis }
    function CreatePopup: TPPGDropPopup; override;
    procedure PreparePopup(APopup: TPPGDropPopup); override;
    procedure AcceptPopup(APopup: TPPGDropPopup); override;
    function CanDropDown: Boolean; override;
    procedure PopupOpened; override;
    procedure PopupClosed; override;
    /// True bei csDropDown/csSimple (Text frei editierbar).
    function EditableStyle: Boolean;
    /// Eintrag mit genau diesem Text (ohne Gross-/Kleinschreibung), -1 = keiner.
    function IndexOfText(const S: string): Integer;
    /// Auswahl durch den Anwender: setzt ItemIndex und loest OnClick und
    /// OnSelect (bzw. OnChange) aus - nur, wenn sich etwas aendert.
    procedure SelectIndex(Index: Integer);
    procedure DoSelect; virtual;
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
    /// Bei ItemsEx kommen die Texte aus ItemsEx (nicht doppelt in der DFM).
    property Items: TStrings read GetItems write SetItems stored IsItemsStored;
    property Sorted: Boolean read GetSorted write SetSorted default False;
    property Style: TComboBoxStyle read FStyle write SetStyle default csDropDown;
    /// Reiche Eintraege (Bild aus Images, Detailzeile, Plakette, Markup). Sind
    /// welche vorhanden, sind sie die Eintraege (Items enthaelt dann ihre Texte).
    property ItemsEx: TPPGItems read FItemsEx write SetItemsEx;
    /// Filtern beim Tippen (nur csDropDown): die Liste zeigt nur Treffer.
    property FilterMode: TPPGFilterMode read FFilterMode write FFilterMode default fmNone;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Wie TComboBox.Clear: leert Eintraege und Text.
    procedure Clear; override;
    procedure AddItem(const Item: string; AObject: TObject);
    /// Fortschritt der Pfeildrehung (0 = zu, 1 = offen).
    function ArrowProgress: Single;
    /// Wie TComboBox.DroppedDown (auch schreibbar).
    property DroppedDown: Boolean read GetDroppedDown write SetDroppedDown;
    /// Die Aufklappliste (nil, solange sie nie geoeffnet wurde).
    property PopupList: TPPGPopupList read GetPopupList;
    /// Bereiche der Aufklappliste (Auswahl = aktueller Wert, Zebra, Hover ...).
    property ListStyles: TPPGListStyles read FListStyles write SetListStyles;
    /// Vor dem Zeichnen jedes Eintrags der Aufklappliste.
    property OnCustomDrawItem: TPPGCustomDrawItemEvent read FOnCustomDrawItem write FOnCustomDrawItem;
    property Text: string read GetComboText write SetComboText;
  end;

  TPPGComboBox = class(TPPGCustomComboBox)
  published
    property RoundedCorners;
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Images;
    property ItemsEx;
    property FilterMode;
    property ListStyles;
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
    property Touch;
    property OnGesture;
    property OnChange;
    property OnCustomDrawItem;
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
  /// Button-Id des Aufklapp-Pfeils (die der Aufklapp-Basis).
  PPGComboButtonDrop = PPGDropButton;

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
  Data.Color := It.Color;
  Data.TextColor := It.TextColor;
  Data.FontStyle := It.FontStyle;
end;

const
  SearchResetMs = 1000; // Tippsuche: Pause, nach der ein neuer Suchtext beginnt

{ TPPGCustomComboBox }

procedure TPPGCustomComboBox.SetListStyles(const Value: TPPGListStyles);
begin
  FListStyles.Assign(Value);
end;

function TPPGCustomComboBox.GetListStyles: TPPGListStyles;
begin
  Result := FListStyles;
end;

function TPPGCustomComboBox.GetCustomDrawItem: TPPGCustomDrawItemEvent;
begin
  Result := FOnCustomDrawItem;
end;

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
  FListStyles := TPPGListStyles.Create(Self);
  FItemsExSource := TComboExSource.Create;
  TComboExSource(FItemsExSource as TObject).FOwner := Self;
  FArrowAnim := TPPGAnimation.Create(Self);
  FArrowAnim.OnStep := ArrowAnimStep;
  Width := 145;
end;

destructor TPPGCustomComboBox.Destroy;
begin
  // Zuerst das Popup schliessen und freigeben (ohne Ereignisse): es greift
  // beim Zeichnen auf ListStyles und Items zu
  FreePopup;
  FreeAndNil(FListStyles);
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
  ApplySorted;
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

function TPPGCustomComboBox.IsItemsStored: Boolean;
begin
  Result := not UseItemsEx and (FItems.Count > 0);
end;

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
  if PopupList <> nil then
    PopupList.ItemIndex := V;
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
    if PopupList <> nil then
      PopupList.ItemIndex := I;
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
  Result := FSorted;
end;

procedure TPPGCustomComboBox.SetSorted(const Value: Boolean);
begin
  if FSorted = Value then
    Exit;
  FSorted := Value;
  if csLoading in ComponentState then
  begin
    // Ohne ItemsEx sortiert Items schon beim Lesen; Loaded gleicht ab
    FItems.Sorted := Value;
    Exit;
  end;
  ApplySorted; // ItemsChanged findet den gewaehlten Eintrag wieder
end;

procedure TPPGCustomComboBox.ApplySorted;
begin
  if UseItemsEx then
  begin
    // Audit 08.10.2026: Sortiert wird ItemsEx, Items folgt in derselben
    // Reihenfolge. Ein sortiertes Items wuerde die Indizes beider Listen
    // trennen (Bilder an falschen Zeilen, EStringListError beim Aendern).
    if FSorted then
      SortItemsEx
    else
      SyncItemsFromEx;
  end
  else
    FItems.Sorted := FSorted;
end;

procedure TPPGCustomComboBox.SortItemsEx;
type
  TKeyed = record
    Item: TPPGItem;
    Key: string;
  end;
var
  Arr: array of TKeyed;
  T: TKeyed;
  I, J: Integer;
begin
  // Stabil (Einfuegen), damit gleiche Texte ihre Reihenfolge behalten
  SetLength(Arr, FItemsEx.Count);
  for I := 0 to FItemsEx.Count - 1 do
  begin
    Arr[I].Item := FItemsEx[I];
    Arr[I].Key := PPGStripMarkup(FItemsEx[I].Text);
  end;
  for I := 1 to High(Arr) do
  begin
    T := Arr[I];
    J := I - 1;
    while (J >= 0) and (AnsiCompareText(Arr[J].Key, T.Key) > 0) do
    begin
      Arr[J + 1] := Arr[J];
      Dec(J);
    end;
    Arr[J + 1] := T;
  end;
  FSortingEx := True;
  try
    FItemsEx.BeginUpdate;
    try
      for I := 0 to High(Arr) do
        Arr[I].Item.Index := I;
    finally
      FItemsEx.EndUpdate; // meldet -1: ItemsExChange baut Items neu auf
    end;
  finally
    FSortingEx := False;
  end;
  SyncItemsFromEx;
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
  if PopupList <> nil then
  begin
    // Audit 08.10.2026: Die Filter-Zuordnung (Zeile -> Eintrag) zeigt nach
    // einer Aenderung der Eintraege auf falsche oder fehlende Indizes
    if PopupList.Filtered then
    begin
      if DroppedDown then
        ApplyFilter
      else
        PopupList.ClearFilter;
    end;
    PopupList.ItemIndex := FItemIndex;
    if PopupList.Highlight >= FItems.Count then
      PopupList.SetHighlight(-1);
    PopupList.TopIndex := PopupList.TopIndex; // auf gueltigen Bereich begrenzen
    PopupList.Invalidate;
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
      // Bei ItemsEx sortiert SortItemsEx; Items folgt unsortiert
      FItems.Sorted := FSorted and (FItemsEx.Count = 0);
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
  if FSortingEx then
    Exit; // SortItemsEx baut Items danach selbst auf
  if FSorted then
    SortItemsEx // neuer oder geaenderter Text: Reihenfolge neu
  else if (Index >= 0) and (Index < FItems.Count) and (FItems.Count = FItemsEx.Count) then
    FItems[Index] := PPGStripMarkup(FItemsEx[Index].Text)
  else
    SyncItemsFromEx;
  if PopupList <> nil then
    PopupList.Invalidate;
  Invalidate;
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
    if DroppedDown and (PopupList <> nil) and PopupList.Filtered then
    begin
      PopupList.ClearFilter;
      RepositionPopup;
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
  if not DroppedDown then
    DropDown;
  if not DroppedDown or (PopupList = nil) then
    Exit;
  PopupList.SetFilter(Map);
  RepositionPopup;
  PopupList.SetHighlight(Map[0]);
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
  if PopupList <> nil then
    PopupList.ItemIndex := FItemIndex;
  if WasTyping and (FFilterMode <> fmNone) and EditableStyle then
    ApplyFilter
  else
  begin
    if WasTyping and FAutoDropDown and not DroppedDown then
      DropDown;
    SyncPopupToText;
  end;
  inherited Change;
end;

procedure TPPGCustomComboBox.SyncPopupToText;
var
  I: Integer;
begin
  if not DroppedDown or (PopupList = nil) then
    Exit;
  // Offene Liste folgt dem getippten Text
  if FItemIndex >= 0 then
    PopupList.SetHighlight(FItemIndex)
  else if FDisplayText <> '' then
    for I := 0 to FItems.Count - 1 do
      if AnsiStartsText(FDisplayText, FItems[I]) then
      begin
        PopupList.SetHighlight(I);
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
  if DroppedDown then
    Cur := PopupList.Highlight
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
      if DroppedDown then
      begin
        PopupList.SetHighlight(J);
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

function TPPGCustomComboBox.GetDroppedDown: Boolean;
begin
  Result := inherited DroppedDown;
end;

function TPPGCustomComboBox.GetPopupList: TPPGPopupList;
begin
  Result := TPPGPopupList(Popup);
end;

function TPPGCustomComboBox.CreatePopup: TPPGDropPopup;
var
  L: TPPGPopupList;
begin
  L := TPPGPopupList.Create(Self);
  L.Items := FItems;
  L.OnItemClick := PopupItemClick;
  Result := L;
end;

procedure TPPGCustomComboBox.PreparePopup(APopup: TPPGDropPopup);
var
  L: TPPGPopupList;
  Fill, TextColor: TColor;
begin
  inherited PreparePopup(APopup);
  L := TPPGPopupList(APopup);
  GetFieldColors(Fill, TextColor);
  L.ListColor := Fill;
  L.TextColor := TextColor;
  L.MinItemHeight := FItemHeight;
  L.ListName := AccName;
  L.ItemIndex := FItemIndex;
  L.ClearFilter;
  // Reiche Eintraege: Bild, Detailzeile, Plakette ueber die Quelle
  if UseItemsEx then
    L.Source := FItemsExSource
  else
    L.Source := nil;
  L.TwoLineItems := ItemsExHasDetail;
  L.DropDownCount := FDropDownCount;
  L.DropDownWidth := FDropDownWidth;
  L.SetHighlight(-1);
end;

function TPPGCustomComboBox.CanDropDown: Boolean;
begin
  Result := True; // wie bisher: ReadOnly sperrt nur das Edit
end;

procedure TPPGCustomComboBox.PopupOpened;
begin
  inherited PopupOpened;
  // Erst jetzt hat die Liste ihre Groesse (MakeVisible)
  PopupList.TopIndex := 0;
  PopupList.SetHighlight(FItemIndex);
  if Animation.EffectiveEnabled then
    FArrowAnim.AnimateTo(1, Animation.Duration)
  else
    FArrowAnim.Jump(1);
end;

procedure TPPGCustomComboBox.PopupClosed;
begin
  inherited PopupClosed;
  // Die Hervorhebung ist ein Eintrag (keine Zeile): bleibt fuer AcceptPopup
  PopupList.ClearFilter;
  if Animation.EffectiveEnabled and HandleAllocated and IsWindowVisible(Handle) then
    FArrowAnim.AnimateTo(0, Animation.Duration)
  else
    FArrowAnim.Jump(0);
end;

procedure TPPGCustomComboBox.AcceptPopup(APopup: TPPGDropPopup);
begin
  // Vor OnCloseUp: dort ist ItemIndex schon aktuell
  if TPPGPopupList(APopup).Highlight >= 0 then
    SelectIndex(TPPGPopupList(APopup).Highlight);
end;

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
  if PopupList <> nil then
  begin
    GetFieldColors(Fill, TextColor);
    PopupList.ListColor := Fill;
    PopupList.TextColor := TextColor;
    PopupList.Invalidate;
  end;
end;

procedure TPPGCustomComboBox.PopupItemClick(Sender: TObject; Index: Integer);
begin
  // Standardaktion eines Eintrags (Screenreader)
  if DroppedDown then
  begin
    PopupList.SetHighlight(Index);
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

{ ---- Buttons ---- }

procedure TPPGCustomComboBox.GetButtons(var Buttons: TPPGFieldButtons);
var
  I: Integer;
begin
  inherited GetButtons(Buttons);
  for I := 0 to High(Buttons) do
    if Buttons[I].Id = PPGComboButtonDrop then
      Buttons[I].Glyph := fgNone; // Pfeil zeichnet DoPaintField (mit Drehung)
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

procedure TPPGCustomComboBox.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  // csDropDownList: das Feld selbst bekommt Pfeiltasten und Zeichen
  Message.Result := Message.Result or DLGC_WANTARROWS or DLGC_WANTCHARS;
end;

procedure TPPGCustomComboBox.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  // Pos1/Ende bewegen im editierbaren Stil den Cursor im Edit (auch offen)
  if EditableStyle and ((Key = VK_HOME) or (Key = VK_END)) then
    Exit;
  inherited FieldKeyDown(Key, Shift);
end;

procedure TPPGCustomComboBox.ClosedKeyDown(var Key: Word; Shift: TShiftState);
var
  Page: Integer;
begin
  // Geschlossen waehlen Pfeile und Bild auf/ab direkt (wie TComboBox)
  Page := FDropDownCount - 1;
  if Page < 1 then
    Page := 1;
  case Key of
    VK_UP: StepSelection(-1);
    VK_DOWN: StepSelection(1);
    VK_PRIOR: StepSelection(-Page);
    VK_NEXT: StepSelection(Page);
    VK_HOME, VK_END:
      begin
        if FItems.Count = 0 then
          Exit;
        if Key = VK_HOME then
          SelectIndex(0)
        else
          SelectIndex(FItems.Count - 1);
      end;
  else
    Exit;
  end;
  Key := 0;
end;

procedure TPPGCustomComboBox.FieldKeyPress(var Key: Char);
begin
  // Ersetzt die Basis ganz: Zeichen gehen auch bei offener Liste ins Edit
  // (csDropDown) bzw. in die Tippsuche (csDropDownList)
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
    S := DisplayTextHint;
    C := HintColor;
  end
  else
    Exit;
  Flags := DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS;
  Flags := DrawTextBiDiModeFlags(Flags);
  ACanvas.DrawText(R, S, Font, C, Flags);
end;

{ ---- Barrierefreiheit ---- }

function TPPGCustomComboBox.AccValue: string;
begin
  Result := FDisplayText;
end;

end.
