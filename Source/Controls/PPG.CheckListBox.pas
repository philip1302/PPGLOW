unit PPG.CheckListBox;

{ TPPGCheckListBox - ListBox mit Kaestchen, DFM-kompatibel zu TCheckListBox.

  Die Kaestchen zeichnet IPPGIndicatorRenderer des Presets (wie TPPGCheckBox).
  Zustand pro Zeile: bei Items in der Huelle der Zeile (wandert beim
  Sortieren/Verschieben mit), bei ItemsEx in TPPGItem.Checked, virtuell ueber
  OnGetItem (Data.Checked) und OnSetChecked.

  Bedienung wie TCheckListBox: Klick auf das Kaestchen oder Leertaste schaltet
  um (aus -> an -> gemischt, wenn AllowGrayed), danach OnClickCheck. Setzen
  im Code (Checked[], State[], CheckAll) loest kein Ereignis aus.
  Header[] macht eine Zeile zur Ueberschrift (ohne Kaestchen, nicht waehlbar). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.Types, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  PPG.Types, PPG.Items, PPG.Render.Intf, PPG.ItemPainter, PPG.UIA, PPG.ListBox;

type
  TPPGCustomCheckListBox = class(TPPGCustomListBox)
  private
    FAllowGrayed: Boolean;
    FFlat: Boolean;
    FHeaderColor: TColor;
    FHeaderBackgroundColor: TColor;
    FHeaderStyles: TPPGListStyles;
    FOnClickCheck: TNotifyEvent;
    FOnItemCheck: TPPGItemCheckEvent;
    FOnSetChecked: TPPGSetCheckedEvent;
    procedure SetFlat(const Value: Boolean);
    procedure SetHeaderColor(const Value: TColor);
    procedure SetHeaderBackgroundColor(const Value: TColor);
    procedure DrawNativeCheck(const ACanvas: IPPGCanvas; const R: TRect; AState: TCheckBoxState;
      AEnabled, AHot: Boolean);
    function GetState(Index: Integer): TCheckBoxState;
    procedure SetState(Index: Integer; const Value: TCheckBoxState);
    function GetChecked(Index: Integer): Boolean;
    procedure SetChecked(Index: Integer; const Value: Boolean);
    function GetItemEnabled(Index: Integer): Boolean;
    procedure SetItemEnabled(Index: Integer; const Value: Boolean);
    function GetHeader(Index: Integer): Boolean;
    procedure SetHeader(Index: Integer; const Value: Boolean);
    procedure CheckIndex(Index: Integer);
    function IndicatorSize: Integer;
    function IndicatorRect(const Row: TRect): TRect;
    function NextState(S: TCheckBoxState): TCheckBoxState;
  protected
    function SourceSetChecked(Index: Integer; Value: TCheckBoxState): Boolean; override;
    function ItemIndent(Index: Integer; const Data: TPPGItemData): Integer; override;
    procedure PaintItem(const ACanvas: IPPGCanvas; Index: Integer; const R: TRect;
      const Data: TPPGItemData; const Info: TPPGItemPaintInfo); override;
    function ItemMouseDown(Index: Integer; Shift: TShiftState; X, Y: Integer): Boolean; override;
    function ItemSpaceKey(Index: Integer): Boolean; override;
    procedure DoAccChildAction(Index: Integer); override;
    function AccChildRole(Id: Integer): Integer; override;
    function AccChildState(Id: Integer): Integer; override;
    function AccChildDefaultAction(Id: Integer): string; override;
    { UI Automation: Eintraege zusaetzlich mit Toggle-Muster }
    function UiaHasPattern(const Id: TPPGUiaId; PatternId: Integer): Boolean; override;
    procedure UiaExecute(const Id: TPPGUiaId; Action: TPPGUiaAction; const Value: string); override;
    /// Anwender schaltet um (Klick, Leertaste, Screenreader): Zustand, dann OnClickCheck.
    procedure ToggleByUser(Index: Integer); virtual;
    procedure ClickCheck; virtual;

    property AllowGrayed: Boolean read FAllowGrayed write FAllowGrayed default False;
    /// True: Kaestchen im Preset-Stil; False: natives Windows-Kaestchen (bzw. VCL-Style).
    property Flat: Boolean read FFlat write SetFlat default True;
    /// Textfarbe der Ueberschriften (Header[]); die Vorgabe clInfoText = wie das Preset.
    /// Styles.GroupHeader.TextColor hat Vorrang. Gilt im Hellen.
    property HeaderColor: TColor read FHeaderColor write SetHeaderColor default clInfoText;
    /// Hintergrund der Ueberschriften; die Vorgabe clInfoBk = wie das Preset.
    /// Styles.GroupHeader.Color hat Vorrang. Gilt im Hellen.
    property HeaderBackgroundColor: TColor read FHeaderBackgroundColor
      write SetHeaderBackgroundColor default clInfoBk;
    property OnClickCheck: TNotifyEvent read FOnClickCheck write FOnClickCheck;
    /// Wie OnClickCheck, mit dem Index des Eintrags (einheitlich mit CheckComboBox, TreeView).
    property OnItemCheck: TPPGItemCheckEvent read FOnItemCheck write FOnItemCheck;
    /// Virtueller Stil: Anwender hat ein Kaestchen umgeschaltet.
    property OnSetChecked: TPPGSetCheckedEvent read FOnSetChecked write FOnSetChecked;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Wie TCheckListBox.CheckAll: alle (bzw. nur aktivierte) Eintraege setzen.
    procedure CheckAll(AState: TCheckBoxState; AllowGrayed: Boolean = True;
      AllowDisabled: Boolean = True);
    property Checked[Index: Integer]: Boolean read GetChecked write SetChecked;
    property State[Index: Integer]: TCheckBoxState read GetState write SetState;
    property ItemEnabled[Index: Integer]: Boolean read GetItemEnabled write SetItemEnabled;
    property Header[Index: Integer]: Boolean read GetHeader write SetHeader;
  end;

  TPPGCheckListBox = class(TPPGCustomCheckListBox)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Images;
    property ItemsEx;
    property AllowMarkup;
    property AllowReorder;
    property Styles;
    property ScrollBarMode;
    property SmoothScrolling;
    property HighContrastSupport;
    { wie TCheckListBox }
    property AllowGrayed;
    property Align;
    property Anchors;
    property AutoComplete;
    property BiDiMode;
    property BorderStyle;
    property Color default clWindow;
    property Columns;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Flat;
    property Font;
    property HeaderColor;
    property HeaderBackgroundColor;
    property IntegralHeight;
    property ItemHeight;
    property Items;
    property MultiSelect;
    property ExtendedSelect;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ScrollWidth;
    property ShowHint;
    property ToolTips;
    property Sorted;
    property Style;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop default True;
    property TabWidth;
    property Visible;
    property Touch;
    property OnGesture;
    property ItemIndex;
    property OnClick;
    property OnClickCheck;
    property OnItemCheck;
    property OnContextPopup;
    property OnData;
    property OnDataFind;
    property OnDataObject;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDrawItem;
    property OnCustomDrawItem;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetItem;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMeasureItem;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnReorder;
    property OnScroll;
    property OnSetChecked;
    property OnStartDock;
    property OnStartDrag;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseWheel;
    property OnMouseActivate;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

implementation

uses
  PPG.Lang,
  System.SysUtils, Winapi.oleacc, PPG.UIA.Intf, PPG.Consts, PPG.Exceptions, PPG.Appearance,
  PPG.DpiUtils, PPG.Render.Registry, Vcl.Themes;

const
  BoxSize = 16;  // logische px
  BoxGap = 8;    // logische px zwischen Kaestchen und Inhalt

{ TPPGCustomCheckListBox }

constructor TPPGCustomCheckListBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFlat := True;
  FHeaderColor := clInfoText;
  FHeaderBackgroundColor := clInfoBk;
end;

destructor TPPGCustomCheckListBox.Destroy;
begin
  FreeAndNil(FHeaderStyles);
  inherited Destroy;
end;

procedure TPPGCustomCheckListBox.SetFlat(const Value: Boolean);
begin
  if FFlat <> Value then
  begin
    FFlat := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomCheckListBox.SetHeaderColor(const Value: TColor);
begin
  if FHeaderColor <> Value then
  begin
    FHeaderColor := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomCheckListBox.SetHeaderBackgroundColor(const Value: TColor);
begin
  if FHeaderBackgroundColor <> Value then
  begin
    FHeaderBackgroundColor := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomCheckListBox.DrawNativeCheck(const ACanvas: IPPGCanvas; const R: TRect;
  AState: TCheckBoxState; AEnabled, AHot: Boolean);
const
  Themed: array[TCheckBoxState, 0..2] of TThemedButton = (
    (tbCheckBoxUncheckedNormal, tbCheckBoxUncheckedHot, tbCheckBoxUncheckedDisabled),
    (tbCheckBoxCheckedNormal, tbCheckBoxCheckedHot, tbCheckBoxCheckedDisabled),
    (tbCheckBoxMixedNormal, tbCheckBoxMixedHot, tbCheckBoxMixedDisabled));
var
  DC: HDC;
  K: Integer;
  Flags: Cardinal;
  CR: TRect;
begin
  if not AEnabled then
    K := 2
  else if AHot then
    K := 1
  else
    K := 0;
  CR := R;
  DC := ACanvas.BeginGdi;
  try
    if StyleServices.Enabled then
      StyleServices.DrawElement(DC, StyleServices.GetElementDetails(Themed[AState, K]), CR)
    else
    begin
      // Klassisches Windows ohne Themes: 3D-Kaestchen wie TCheckListBox
      Flags := DFCS_BUTTONCHECK;
      if AState = cbChecked then
        Flags := Flags or DFCS_CHECKED
      else if AState = cbGrayed then
        Flags := DFCS_BUTTON3STATE or DFCS_CHECKED;
      if not AEnabled then
        Flags := Flags or DFCS_INACTIVE;
      DrawFrameControl(DC, CR, DFC_BUTTON, Flags);
    end;
  finally
    ACanvas.EndGdi(DC);
  end;
end;

procedure TPPGCustomCheckListBox.CheckIndex(Index: Integer);
begin
  if (Index < 0) or (Index >= ItemCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, ItemCount - 1]);
end;

function TPPGCustomCheckListBox.GetState(Index: Integer): TCheckBoxState;
var
  Data: TPPGItemData;
begin
  CheckIndex(Index);
  GetItemData(Index, Data);
  Result := Data.Checked;
end;

procedure TPPGCustomCheckListBox.SetState(Index: Integer; const Value: TCheckBoxState);
begin
  CheckIndex(Index);
  if SourceSetChecked(Index, Value) then
    ItemChanged(Index);
end;

function TPPGCustomCheckListBox.SourceSetChecked(Index: Integer;
  Value: TCheckBoxState): Boolean;
begin
  Result := True;
  case Mode of
    lmStrings:
      TPPGListBoxStrings(Items).Wrapper(Index).State := Value;
    lmItemsEx:
      ItemsEx[Index].Checked := Value; // meldet sich selbst
  else
    if Assigned(FOnSetChecked) then
      FOnSetChecked(Self, Index, Value)
    else
      Result := False;
  end;
end;

function TPPGCustomCheckListBox.GetChecked(Index: Integer): Boolean;
begin
  Result := GetState(Index) = cbChecked;
end;

procedure TPPGCustomCheckListBox.SetChecked(Index: Integer; const Value: Boolean);
begin
  if Value then
    SetState(Index, cbChecked)
  else
    SetState(Index, cbUnchecked);
end;

function TPPGCustomCheckListBox.GetItemEnabled(Index: Integer): Boolean;
var
  Data: TPPGItemData;
begin
  CheckIndex(Index);
  GetItemData(Index, Data);
  Result := Data.Enabled;
end;

procedure TPPGCustomCheckListBox.SetItemEnabled(Index: Integer; const Value: Boolean);
begin
  CheckIndex(Index);
  case Mode of
    lmStrings:
      begin
        TPPGListBoxStrings(Items).Wrapper(Index).Disabled := not Value;
        ItemChanged(Index);
      end;
    lmItemsEx:
      ItemsEx[Index].Enabled := Value;
  end;
end;

function TPPGCustomCheckListBox.GetHeader(Index: Integer): Boolean;
var
  Data: TPPGItemData;
begin
  CheckIndex(Index);
  GetItemData(Index, Data);
  Result := Data.IsHeader;
end;

procedure TPPGCustomCheckListBox.SetHeader(Index: Integer; const Value: Boolean);
begin
  CheckIndex(Index);
  // Ueberschriften gibt es wie bei TCheckListBox nur fuer Items
  if Mode = lmStrings then
  begin
    TPPGListBoxStrings(Items).Wrapper(Index).Header := Value;
    if Value and Selection.Selected[Index] then
      Selection.Selected[Index] := False;
    ItemChanged(Index);
  end;
end;

procedure TPPGCustomCheckListBox.CheckAll(AState: TCheckBoxState; AllowGrayed,
  AllowDisabled: Boolean);
var
  I: Integer;
  Data: TPPGItemData;
begin
  Items.BeginUpdate;
  try
    for I := 0 to ItemCount - 1 do
    begin
      GetItemData(I, Data);
      if Data.IsHeader then
        Continue;
      if not AllowDisabled and not Data.Enabled then
        Continue;
      if not AllowGrayed and (Data.Checked = cbGrayed) then
        Continue;
      SourceSetChecked(I, AState);
    end;
  finally
    Items.EndUpdate;
  end;
  Invalidate;
end;

function TPPGCustomCheckListBox.IndicatorSize: Integer;
begin
  Result := PPGScale(BoxSize, ScalePPI);
end;

function TPPGCustomCheckListBox.ItemIndent(Index: Integer; const Data: TPPGItemData): Integer;
begin
  if Data.IsHeader then
    Result := 0
  else
    Result := IndicatorSize + PPGScale(BoxGap, ScalePPI);
end;

function TPPGCustomCheckListBox.IndicatorRect(const Row: TRect): TRect;
var
  S, Pad: Integer;
begin
  S := IndicatorSize;
  Pad := PPGScale(PPGItemPadX, ScalePPI);
  Result.Top := (Row.Top + Row.Bottom - S) div 2;
  Result.Bottom := Result.Top + S;
  if UseRightToLeftAlignment then
  begin
    Result.Right := Row.Right - Pad;
    Result.Left := Result.Right - S;
  end
  else
  begin
    Result.Left := Row.Left + Pad;
    Result.Right := Result.Left + S;
  end;
end;

procedure TPPGCustomCheckListBox.PaintItem(const ACanvas: IPPGCanvas; Index: Integer;
  const R: TRect; const Data: TPPGItemData; const Info: TPPGItemPaintInfo);
var
  IR: IPPGIndicatorRenderer;
  A: TPPGAppearance;
  S: TPPGSurfaceStyle;
  PPI: Integer;
  ItemOn: Boolean;
  HInfo: TPPGItemPaintInfo;
begin
  // Ueberschriften mit HeaderColor/HeaderBackgroundColor (wenn nicht Vorgabe und
  // GroupHeader nichts Eigenes setzt)
  if Data.IsHeader and Info.UseColors and (Info.Styles <> nil) and
    ((FHeaderColor <> clInfoText) or (FHeaderBackgroundColor <> clInfoBk)) then
  begin
    if FHeaderStyles = nil then
      FHeaderStyles := TPPGListStyles.Create(nil);
    FHeaderStyles.Assign(Info.Styles);
    if (FHeaderColor <> clInfoText) and (FHeaderStyles.GroupHeader.TextColor = clDefault) then
      FHeaderStyles.GroupHeader.TextColor := FHeaderColor;
    if (FHeaderBackgroundColor <> clInfoBk) and (FHeaderStyles.GroupHeader.Color = clDefault) then
      FHeaderStyles.GroupHeader.Color := FHeaderBackgroundColor;
    HInfo := Info;
    HInfo.Styles := FHeaderStyles;
    inherited PaintItem(ACanvas, Index, R, Data, HInfo);
    Exit;
  end;
  inherited PaintItem(ACanvas, Index, R, Data, Info);
  if Data.IsHeader then
    Exit;
  if not FFlat and not (HighContrastSupport and PPGIsHighContrast) then
  begin
    DrawNativeCheck(ACanvas, IndicatorRect(R), Data.Checked, Enabled and Data.Enabled, Index = HotIndex);
    Exit;
  end;
  if not Supports(Renderer, IPPGIndicatorRenderer, IR) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
      IPPGIndicatorRenderer, IR);
  A := EffectiveAppearance;
  PPI := ScalePPI;
  ItemOn := Enabled and Data.Enabled;
  if not ItemOn then
  begin
    S := A.Resolve(vsDisabled, PPI, False);
    if Data.Checked <> cbUnchecked then
      S.TextColor := PPGColorToRGB(A.Disabled.TextColor);
  end
  else if Data.Checked = cbChecked then
    S := A.ResolveStyle(A.Checked, PPI, False)
  else
  begin
    if Index = HotIndex then
      S := A.Resolve(vsHot, PPI, False)
    else
      S := A.Resolve(vsNormal, PPI, False);
    if Data.Checked = cbGrayed then
      S.TextColor := PPGColorToRGB(A.Checked.Color); // kraeftige Akzentfarbe
  end;
  S.GlowAlpha := 0;
  S.GlowSize := 0;
  if HighContrastSupport and PPGIsHighContrast then
  begin
    S.Color := PPGColorToRGB(clWindow);
    S.ColorTo := S.Color;
    S.ColorMirror := S.Color;
    S.ColorMirrorTo := S.Color;
    S.BorderColor := PPGColorToRGB(clWindowText);
    S.TextColor := PPGColorToRGB(clWindowText);
  end;
  IR.DrawCheckIndicator(ACanvas, IndicatorRect(R), S, Data.Checked, PPI);
end;

function TPPGCustomCheckListBox.NextState(S: TCheckBoxState): TCheckBoxState;
begin
  case S of
    cbUnchecked: Result := cbChecked;
    cbChecked:
      if FAllowGrayed then
        Result := cbGrayed
      else
        Result := cbUnchecked;
  else
    Result := cbUnchecked;
  end;
end;

procedure TPPGCustomCheckListBox.ToggleByUser(Index: Integer);
var
  Data: TPPGItemData;
begin
  GetItemData(Index, Data);
  if Data.IsHeader or not Data.Enabled or not Enabled then
    Exit;
  // Zustand zuerst, dann das Ereignis (Exception im Ereignis: Zustand gilt)
  if SourceSetChecked(Index, NextState(Data.Checked)) then
  begin
    ItemChanged(Index);
    NotifyAccessibilityChild(EVENT_OBJECT_STATECHANGE, Index + 1);
    ClickCheck;
    if Assigned(FOnItemCheck) then
      FOnItemCheck(Self, Index);
  end;
end;

procedure TPPGCustomCheckListBox.ClickCheck;
begin
  if Assigned(FOnClickCheck) then
    FOnClickCheck(Self);
end;

function TPPGCustomCheckListBox.ItemMouseDown(Index: Integer; Shift: TShiftState;
  X, Y: Integer): Boolean;
var
  R: TRect;
begin
  Result := False;
  R := ItemRect(Index);
  R := IndicatorRect(R);
  InflateRect(R, PPGScale(3, ScalePPI), PPGScale(3, ScalePPI));
  if PtInRect(R, Point(X, Y)) then
    ToggleByUser(Index);
  // Weiter mit der Auswahl (wie TCheckListBox: der Eintrag wird auch gewaehlt)
end;

function TPPGCustomCheckListBox.ItemSpaceKey(Index: Integer): Boolean;
begin
  ToggleByUser(Index);
  Result := True;
end;

procedure TPPGCustomCheckListBox.DoAccChildAction(Index: Integer);
begin
  ToggleByUser(Index);
end;

function TPPGCustomCheckListBox.AccChildRole(Id: Integer): Integer;
var
  Data: TPPGItemData;
begin
  GetItemData(Id - 1, Data);
  if Data.IsHeader then
    Result := ROLE_SYSTEM_STATICTEXT
  else
    Result := ROLE_SYSTEM_CHECKBUTTON;
end;

function TPPGCustomCheckListBox.AccChildState(Id: Integer): Integer;
var
  Data: TPPGItemData;
begin
  Result := inherited AccChildState(Id);
  GetItemData(Id - 1, Data);
  case Data.Checked of
    cbChecked: Result := Result or STATE_SYSTEM_CHECKED;
    cbGrayed: Result := Result or STATE_SYSTEM_MIXED;
  end;
end;

function TPPGCustomCheckListBox.AccChildDefaultAction(Id: Integer): string;
var
  Data: TPPGItemData;
begin
  GetItemData(Id - 1, Data);
  if Data.Checked = cbChecked then
    Result := PPGStr(@SPPGAccUncheck)
  else
    Result := PPGStr(@SPPGAccCheck);
end;

{ ---- UI Automation ---- }

function TPPGCustomCheckListBox.UiaHasPattern(const Id: TPPGUiaId; PatternId: Integer): Boolean;
var
  R: Integer;
begin
  if PatternId = UIA_TogglePatternId then
  begin
    R := UiaRowOf(Id);
    Result := (R >= 0) and not Header[R];
  end
  else
    Result := inherited UiaHasPattern(Id, PatternId);
end;

procedure TPPGCustomCheckListBox.UiaExecute(const Id: TPPGUiaId; Action: TPPGUiaAction;
  const Value: string);
var
  R: Integer;
begin
  R := UiaRowOf(Id);
  if (Action = uaToggle) and (R >= 0) and Enabled and not Header[R] then
    ToggleByUser(R)
  else
    inherited UiaExecute(Id, Action, Value);
end;

end.
