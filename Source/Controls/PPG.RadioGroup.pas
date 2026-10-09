unit PPG.RadioGroup;

{ TPPGRadioGroup und TPPGCheckGroup - Auswahlgruppen (Phase 18a).

  Mehrwert gegenueber TRadioGroup/TcxRadioGroup:
  - ChoiceStyle: csList (Kreise bzw. Kaestchen wie die VCL), csSegmented
    (Umschalter in einer Zeile mit gleitendem Akzent) und csCards (Kacheln
    mit Symbol, Titel und Beschreibung).
  - ItemsEx: je Eintrag Beschreibung, Symbol (Zeichen der Symbolschrift oder
    ImageIndex), Enabled, Hint und Value. Items bleibt als einfache Sicht
    (TStrings) und laedt alte DFMs von TRadioGroup unveraendert.
  - Columns = 0 passt die Spalten der Breite an.
  - ValidationState wie bei den Feldern (Pflichtauswahl rot markieren).

  Aufbau:
  - Basis TPPGCustomGroupBox (Rahmen und Plakette); ein Fenster, Eintraege
    selbst gezeichnet (keine Fensterflut). ShowFrame = False ohne Rahmen.
  - Gespeichert wird ItemsEx nur, wenn ein Eintrag mehr als die Beschriftung
    hat, sonst Items.Strings (wie TRadioGroup).
  - csList ordnet wie TRadioGroup spaltenweise (erst nach unten), die Zeilen
    teilen sich die Hoehe. Kacheln, Segmente und Columns = 0 ordnen zeilenweise.
  - Ereignisse: Anwender waehlt -> OnClick, dann OnChange. Code setzt
    ItemIndex bzw. Checked[] ohne Ereignis (PPGlow-Regel, wie CheckBox).
  - Tastatur: Pfeile wechseln (RadioGroup: Auswahl folgt), Leertaste kreuzt
    an (CheckGroup), Pos1/Ende, Accelerator & in den Eintraegen.
  - Screenreader: jeder Eintrag ist ein Kind (Optionsfeld bzw. Kontrollkaestchen). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, Vcl.Controls, Vcl.Graphics,
  Vcl.StdCtrls, Vcl.ImgList, PPG.Types, PPG.Render.Intf, PPG.Accessibility, PPG.Animation,
  PPG.ElementStyle, PPG.Controls.Field, PPG.GroupBox;

type
  TPPGChoiceStyle = (csList, csSegmented, csCards);

  TPPGChoiceItem = class(TCollectionItem)
  private
    FCaption: string;
    FDescription: string;
    FIcon: Word;
    FImageIndex: TPPGImageIndex;
    FEnabled: Boolean;
    FHint: string;
    FValue: string;
    FState: TCheckBoxState;
    FData: TObject;
    procedure SetCaption(const Value: string);
    procedure SetDescription(const Value: string);
    procedure SetIcon(const Value: Word);
    procedure SetImageIndex(const Value: TPPGImageIndex);
    procedure SetEnabled(const Value: Boolean);
    procedure SetState(const Value: TCheckBoxState);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    /// Mehr als eine Beschriftung (dann wird ItemsEx gespeichert).
    function HasExtras: Boolean;
    /// Objekt wie TStrings.Objects (nicht gespeichert).
    property Data: TObject read FData write FData;
  published
    property Caption: string read FCaption write SetCaption;
    /// Zweite Zeile (Kacheln) bzw. Hinweis in der Liste.
    property Description: string read FDescription write SetDescription;
    /// Zeichen der Symbolschrift (z.B. $E80F); 0 = keins.
    property Icon: Word read FIcon write SetIcon default 0;
    /// Bild aus Images (vor Icon); -1 = keins.
    property ImageIndex: TPPGImageIndex read FImageIndex write SetImageIndex default -1;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Hint: string read FHint write FHint;
    /// Wert fuer Programm und Datenbank ('' = Caption).
    property Value: string read FValue write FValue;
    /// Nur CheckGroup: Zustand des Kaestchens.
    property State: TCheckBoxState read FState write SetState default cbUnchecked;
  end;

  TPPGChoiceItems = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGChoiceItem;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    function Add: TPPGChoiceItem;
    function HasExtras: Boolean;
    property Items[Index: Integer]: TPPGChoiceItem read GetItem; default;
  end;

  TPPGChoiceItemEvent = procedure(Sender: TObject; Index: Integer) of object;

  TPPGCustomChoiceGroup = class(TPPGCustomGroupBox, IPPGAccessibleChildren)
  private
    FItemsEx: TPPGChoiceItems;
    FItems: TStrings;
    FItemIndex: Integer;
    FColumns: Integer;
    FChoiceStyle: TPPGChoiceStyle;
    FShowFrame: Boolean;
    FMulti: Boolean;
    FAllowGrayed: Boolean;
    FValidationState: TPPGValidationState;
    FImages: TCustomImageList;
    FItemStyle: TPPGElementStyle;
    FSelectedStyle: TPPGElementStyle;
    FHot, FDown, FFocusIndex: Integer;
    FSlide: TPPGAnimation;
    FSlideFrom: TRect;
    FUpdating: Integer;
    FOnChange: TNotifyEvent;
    FOnItemClick: TPPGChoiceItemEvent;
    procedure SetItems(const Value: TStrings);
    procedure SetItemsEx(const Value: TPPGChoiceItems);
    procedure SetItemIndex(const Value: Integer);
    procedure SetColumns(const Value: Integer);
    procedure SetChoiceStyle(const Value: TPPGChoiceStyle);
    procedure SetShowFrame(const Value: Boolean);
    procedure SetAllowGrayed(const Value: Boolean);
    procedure SetValidationState(const Value: TPPGValidationState);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetItemStyle(const Value: TPPGElementStyle);
    procedure SetSelectedStyle(const Value: TPPGElementStyle);
    function GetChecked(Index: Integer): Boolean;
    procedure SetChecked(Index: Integer; const Value: Boolean);
    function GetItemState(Index: Integer): TCheckBoxState;
    procedure SetItemState(Index: Integer; const Value: TCheckBoxState);
    function GetItemEnabled(Index: Integer): Boolean;
    procedure SetItemEnabled(Index: Integer; const Value: Boolean);
    function GetValue: string;
    procedure SetValue(const Value: string);
    function IsItemsStored: Boolean;
    function IsItemsExStored: Boolean;
    procedure StyleChanged(Sender: TObject);
    procedure SlideStep(Sender: TObject);
    procedure CheckIndex(Index: Integer);
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  protected
    procedure ItemsChanged; virtual;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure UpdateVisualState(Animate: Boolean = True); override;
    procedure DoAccelerator; override;
    /// Fokus nur, wenn das Fenster ihn annehmen kann.
    function TryFocus: Boolean;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoEnter; override;
    procedure WndProc(var Message: TMessage); override;
    /// Anwenderaktion auf einem Eintrag (Klick, Leertaste, Accelerator).
    procedure ActivateItem(Index: Integer); virtual;
    procedure DoChange; virtual;
    /// Innenbereich, in dem die Eintraege liegen (Client-Koordinaten).
    function ItemsArea: TRect;
    /// Spalten und Zeilen der aktuellen Anordnung.
    procedure GetGrid(out Cols, Rows: Integer);
    function ItemTextWidth(Index: Integer): Integer;
    function CardHeight: Integer;
    function SegmentHeight: Integer;
    function NextEnabled(From, Delta: Integer): Integer;
    procedure SetFocusIndex(Value: Integer);
    procedure PaintList(const ACanvas: IPPGCanvas; const Area: TRect);
    procedure PaintSegments(const ACanvas: IPPGCanvas; const Area: TRect);
    procedure PaintCards(const ACanvas: IPPGCanvas; const Area: TRect);
    function IndicatorStyle(Index: Integer; Checked: Boolean): TPPGSurfaceStyle;
    function GroupTextColor: TColor;
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
    property Multi: Boolean read FMulti write FMulti;
    property AllowGrayed: Boolean read FAllowGrayed write SetAllowGrayed default False;
    property OnItemClick: TPPGChoiceItemEvent read FOnItemClick write FOnItemClick;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    /// Lage eines Eintrags (Client-Koordinaten); leer = keiner.
    function ItemRect(Index: Integer): TRect;
    /// Eintrag unter dem Punkt (Client-Koordinaten), -1 = keiner.
    function ItemAt(X, Y: Integer): Integer;
    function Count: Integer;
    /// Fokus-Eintrag (Tastatur).
    property FocusIndex: Integer read FFocusIndex write SetFocusIndex;
    property Checked[Index: Integer]: Boolean read GetChecked write SetChecked;
    property ItemState[Index: Integer]: TCheckBoxState read GetItemState write SetItemState;
    property ItemEnabled[Index: Integer]: Boolean read GetItemEnabled write SetItemEnabled;
    /// RadioGroup: Value des gewaehlten Eintrags; CheckGroup: Werte aller
    /// angekreuzten als Kommaliste. Setzen waehlt bzw. kreuzt passend an.
    property Value: string read GetValue write SetValue;
    property Items: TStrings read FItems write SetItems stored IsItemsStored;
    property ItemsEx: TPPGChoiceItems read FItemsEx write SetItemsEx stored IsItemsExStored;
    property ItemIndex: Integer read FItemIndex write SetItemIndex default -1;
    /// Spalten (wie TRadioGroup); 0 = nach Breite.
    property Columns: Integer read FColumns write SetColumns default 1;
    property ChoiceStyle: TPPGChoiceStyle read FChoiceStyle write SetChoiceStyle default csList;
    /// Rahmen und Plakette (False: nur die Eintraege, z.B. Segmente in einer Leiste).
    property ShowFrame: Boolean read FShowFrame write SetShowFrame default True;
    property ValidationState: TPPGValidationState read FValidationState
      write SetValidationState default pvsNone;
    property Images: TCustomImageList read FImages write SetImages;
    /// Eintraege: Flaeche, Text, Rand, Schrift (Segmente, Kacheln, Text der Liste).
    property ItemStyle: TPPGElementStyle read FItemStyle write SetItemStyle;
    /// Gewaehlter Eintrag (ueberschreibt den Akzent).
    property SelectedStyle: TPPGElementStyle read FSelectedStyle write SetSelectedStyle;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TPPGRadioGroup = class(TPPGCustomChoiceGroup)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighlightFocus;
    property CaptionStyle;
    property HighContrastSupport;
    property Items;
    property ItemsEx;
    property ItemIndex;
    property Columns;
    property ChoiceStyle;
    property ShowFrame;
    property ValidationState;
    property Images;
    property ItemStyle;
    property SelectedStyle;
    { VCL-Standard }
    property Align;
    property Anchors;
    property BiDiMode;
    property Caption;
    property Color;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentBackground default True;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Touch;
    property OnGesture;
    property OnChange;
    property OnClick;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnStartDock;
    property OnStartDrag;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseActivate;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

  TPPGCheckGroup = class(TPPGCustomChoiceGroup)
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighlightFocus;
    property CaptionStyle;
    property HighContrastSupport;
    property Items;
    property ItemsEx;
    property AllowGrayed;
    property Columns;
    property ChoiceStyle;
    property ShowFrame;
    property ValidationState;
    property Images;
    property ItemStyle;
    property SelectedStyle;
    { VCL-Standard }
    property Align;
    property Anchors;
    property BiDiMode;
    property Caption;
    property Color;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentBackground default True;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Touch;
    property OnGesture;
    property OnChange;
    property OnClick;
    property OnItemClick;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnStartDock;
    property OnStartDrag;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseActivate;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

implementation

uses
  System.SysUtils, System.Math, Vcl.Forms, Vcl.Menus, Winapi.oleacc, PPG.Appearance, PPG.Exceptions,
  PPG.Lang, PPG.Consts, PPG.DpiUtils, PPG.Render.Gdi, PPG.Render.Registry, PPG.IconFont,
  PPG.Tokens, PPG.VclStyles;

const
  ItemGap = 6;          // logische px zwischen Spalten
  IndSize = 16;         // Kreis/Kaestchen
  IndGap = 8;           // Kreis -> Text
  CardMinWidth = 170;   // Kacheln bei Columns = 0
  CardPad = 10;
  CardIcon = 24;
  SegPadH = 14;

var
  GMsgChoiceAction: Cardinal;

type
  /// Items als TStrings-Sicht auf ItemsEx (Captions).
  TPPGChoiceStrings = class(TStrings)
  private
    FOwner: TPPGCustomChoiceGroup;
  protected
    function Get(Index: Integer): string; override;
    function GetCount: Integer; override;
    function GetObject(Index: Integer): TObject; override;
    procedure Put(Index: Integer; const S: string); override;
    procedure PutObject(Index: Integer; AObject: TObject); override;
    procedure SetUpdateState(Updating: Boolean); override;
  public
    constructor Create(AOwner: TPPGCustomChoiceGroup);
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Insert(Index: Integer; const S: string); override;
  end;

{ TPPGChoiceStrings }

constructor TPPGChoiceStrings.Create(AOwner: TPPGCustomChoiceGroup);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TPPGChoiceStrings.Get(Index: Integer): string;
begin
  Result := FOwner.FItemsEx[Index].Caption;
end;

function TPPGChoiceStrings.GetCount: Integer;
begin
  Result := FOwner.FItemsEx.Count;
end;

function TPPGChoiceStrings.GetObject(Index: Integer): TObject;
begin
  Result := FOwner.FItemsEx[Index].Data;
end;

procedure TPPGChoiceStrings.Put(Index: Integer; const S: string);
begin
  FOwner.FItemsEx[Index].Caption := S;
end;

procedure TPPGChoiceStrings.PutObject(Index: Integer; AObject: TObject);
begin
  FOwner.FItemsEx[Index].Data := AObject;
end;

procedure TPPGChoiceStrings.SetUpdateState(Updating: Boolean);
begin
  if Updating then
    FOwner.BeginUpdate
  else
    FOwner.EndUpdate;
end;

procedure TPPGChoiceStrings.Clear;
begin
  FOwner.FItemsEx.Clear;
end;

procedure TPPGChoiceStrings.Delete(Index: Integer);
begin
  FOwner.FItemsEx.Delete(Index);
end;

procedure TPPGChoiceStrings.Insert(Index: Integer; const S: string);
var
  It: TPPGChoiceItem;
begin
  It := TPPGChoiceItem(FOwner.FItemsEx.Insert(Index));
  It.Caption := S;
end;

{ TPPGChoiceItem }

constructor TPPGChoiceItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FImageIndex := -1;
  FEnabled := True;
end;

procedure TPPGChoiceItem.Assign(Source: TPersistent);
var
  S: TPPGChoiceItem;
begin
  if Source is TPPGChoiceItem then
  begin
    S := TPPGChoiceItem(Source);
    FCaption := S.FCaption;
    FDescription := S.FDescription;
    FIcon := S.FIcon;
    FImageIndex := S.FImageIndex;
    FEnabled := S.FEnabled;
    FHint := S.FHint;
    FValue := S.FValue;
    FState := S.FState;
    FData := S.FData;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGChoiceItem.GetDisplayName: string;
begin
  Result := FCaption;
  if Result = '' then
    Result := inherited GetDisplayName;
end;

function TPPGChoiceItem.HasExtras: Boolean;
begin
  Result := (FDescription <> '') or (FIcon <> 0) or (FImageIndex >= 0) or not FEnabled or
    (FHint <> '') or (FValue <> '') or (FState <> cbUnchecked);
end;

procedure TPPGChoiceItem.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

procedure TPPGChoiceItem.SetDescription(const Value: string);
begin
  if FDescription <> Value then
  begin
    FDescription := Value;
    Changed(False);
  end;
end;

procedure TPPGChoiceItem.SetIcon(const Value: Word);
begin
  if FIcon <> Value then
  begin
    FIcon := Value;
    Changed(False);
  end;
end;

procedure TPPGChoiceItem.SetImageIndex(const Value: TPPGImageIndex);
begin
  if FImageIndex <> Value then
  begin
    FImageIndex := Value;
    Changed(False);
  end;
end;

procedure TPPGChoiceItem.SetEnabled(const Value: Boolean);
begin
  if FEnabled <> Value then
  begin
    FEnabled := Value;
    Changed(False);
  end;
end;

procedure TPPGChoiceItem.SetState(const Value: TCheckBoxState);
begin
  if FState <> Value then
  begin
    FState := Value;
    Changed(False);
  end;
end;

{ TPPGChoiceItems }

function TPPGChoiceItems.Add: TPPGChoiceItem;
begin
  Result := TPPGChoiceItem(inherited Add);
end;

function TPPGChoiceItems.GetItem(Index: Integer): TPPGChoiceItem;
begin
  Result := TPPGChoiceItem(inherited GetItem(Index));
end;

function TPPGChoiceItems.HasExtras: Boolean;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Items[I].HasExtras then
      Exit(True);
  Result := False;
end;

procedure TPPGChoiceItems.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if GetOwner is TPPGCustomChoiceGroup then
    TPPGCustomChoiceGroup(GetOwner).ItemsChanged;
end;

{ TPPGCustomChoiceGroup }

constructor TPPGCustomChoiceGroup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Keine Kind-Controls (wie TRadioGroup), aber fokussierbar
  // Ohne csClickEvents: OnClick kommt nur bei einem Wechsel (wie TRadioGroup),
  // nicht bei jedem Loslassen
  ControlStyle := ControlStyle - [csAcceptsControls, csClickEvents] + [csCaptureMouse];
  TabStop := True;
  FItemsEx := TPPGChoiceItems.Create(Self, TPPGChoiceItem);
  FItems := TPPGChoiceStrings.Create(Self);
  FItemIndex := -1;
  FColumns := 1;
  FShowFrame := True;
  FHot := -1;
  FDown := -1;
  FFocusIndex := -1;
  FItemStyle := TPPGElementStyle.Create(Self);
  FItemStyle.OnChange := StyleChanged;
  FSelectedStyle := TPPGElementStyle.Create(Self);
  FSelectedStyle.OnChange := StyleChanged;
  FSlide := TPPGAnimation.Create(Self);
  FSlide.OnStep := SlideStep;
  FSlide.Jump(1);
end;

destructor TPPGCustomChoiceGroup.Destroy;
begin
  FreeAndNil(FSlide);
  inherited Destroy;
  FreeAndNil(FItems);
  FreeAndNil(FItemsEx);
  FreeAndNil(FSelectedStyle);
  FreeAndNil(FItemStyle);
end;

procedure TPPGCustomChoiceGroup.BeginUpdate;
begin
  Inc(FUpdating);
end;

procedure TPPGCustomChoiceGroup.EndUpdate;
begin
  if FUpdating > 0 then
    Dec(FUpdating);
  if FUpdating = 0 then
    ItemsChanged;
end;

procedure TPPGCustomChoiceGroup.ItemsChanged;
begin
  if (FUpdating > 0) or (csDestroying in ComponentState) then
    Exit;
  if FItemIndex >= FItemsEx.Count then
    FItemIndex := -1;
  if FFocusIndex >= FItemsEx.Count then
    FFocusIndex := -1;
  if FHot >= FItemsEx.Count then
    FHot := -1;
  if not (csLoading in ComponentState) then
    NotifyAccessibility(EVENT_OBJECT_REORDER);
  Invalidate;
end;

procedure TPPGCustomChoiceGroup.Loaded;
begin
  inherited Loaded;
  if FItemIndex >= FItemsEx.Count then
    FItemIndex := -1;
  Invalidate;
end;

procedure TPPGCustomChoiceGroup.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FImages) then
  begin
    FImages := nil;
    Invalidate;
  end;
end;

function TPPGCustomChoiceGroup.Count: Integer;
begin
  Result := FItemsEx.Count;
end;

procedure TPPGCustomChoiceGroup.CheckIndex(Index: Integer);
begin
  if (Index < 0) or (Index >= FItemsEx.Count) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, FItemsEx.Count - 1]);
end;

procedure TPPGCustomChoiceGroup.SetItems(const Value: TStrings);
begin
  FItems.Assign(Value);
end;

procedure TPPGCustomChoiceGroup.SetItemsEx(const Value: TPPGChoiceItems);
begin
  FItemsEx.Assign(Value);
end;

function TPPGCustomChoiceGroup.IsItemsStored: Boolean;
begin
  Result := (FItemsEx.Count > 0) and not FItemsEx.HasExtras;
end;

function TPPGCustomChoiceGroup.IsItemsExStored: Boolean;
begin
  Result := FItemsEx.HasExtras;
end;

procedure TPPGCustomChoiceGroup.SetItemIndex(const Value: Integer);
var
  Old: TRect;
begin
  if FItemIndex = Value then
    Exit;
  // Beim Laden kommen ItemIndex und Items in beliebiger Reihenfolge
  if not (csLoading in ComponentState) and (Value <> -1) then
    CheckIndex(Value);
  if Value < -1 then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Value, FItemsEx.Count - 1]);
  Old := ItemRect(FItemIndex);
  FItemIndex := Value;
  // Segmente: Akzent gleitet vom alten zum neuen Eintrag
  if (FChoiceStyle = csSegmented) and not IsRectEmpty(Old) and (Value >= 0) and HandleAllocated and
    Animation.EffectiveEnabled then
  begin
    FSlideFrom := Old;
    FSlide.Jump(0);
    FSlide.AnimateTo(1, Animation.Duration, ekDecelerate);
  end
  else
    FSlide.Jump(1);
  if not (csLoading in ComponentState) then
    NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
  Invalidate;
end;

procedure TPPGCustomChoiceGroup.SlideStep(Sender: TObject);
begin
  Invalidate;
end;

procedure TPPGCustomChoiceGroup.SetColumns(const Value: Integer);
begin
  if FColumns <> Value then
  begin
    FColumns := PPGCheckRange(Self, 'Columns', Value, 0, 16);
    Invalidate;
  end;
end;

procedure TPPGCustomChoiceGroup.SetChoiceStyle(const Value: TPPGChoiceStyle);
begin
  if FChoiceStyle <> Value then
  begin
    FChoiceStyle := Value;
    FSlide.Jump(1);
    Invalidate;
  end;
end;

procedure TPPGCustomChoiceGroup.SetShowFrame(const Value: Boolean);
begin
  if FShowFrame <> Value then
  begin
    FShowFrame := Value;
    LayoutChanged;
  end;
end;

procedure TPPGCustomChoiceGroup.SetAllowGrayed(const Value: Boolean);
var
  I: Integer;
begin
  if FAllowGrayed <> Value then
  begin
    FAllowGrayed := Value;
    if not Value then
      for I := 0 to FItemsEx.Count - 1 do
        if FItemsEx[I].State = cbGrayed then
          FItemsEx[I].State := cbUnchecked;
  end;
end;

procedure TPPGCustomChoiceGroup.SetValidationState(const Value: TPPGValidationState);
begin
  if FValidationState <> Value then
  begin
    FValidationState := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomChoiceGroup.SetImages(const Value: TCustomImageList);
begin
  if FImages <> Value then
  begin
    if FImages <> nil then
      FImages.RemoveFreeNotification(Self);
    FImages := Value;
    if FImages <> nil then
      FImages.FreeNotification(Self);
    Invalidate;
  end;
end;

procedure TPPGCustomChoiceGroup.SetItemStyle(const Value: TPPGElementStyle);
begin
  FItemStyle.Assign(Value);
end;

procedure TPPGCustomChoiceGroup.SetSelectedStyle(const Value: TPPGElementStyle);
begin
  FSelectedStyle.Assign(Value);
end;

procedure TPPGCustomChoiceGroup.StyleChanged(Sender: TObject);
begin
  Invalidate;
end;

function TPPGCustomChoiceGroup.GetChecked(Index: Integer): Boolean;
begin
  CheckIndex(Index);
  if FMulti then
    Result := FItemsEx[Index].State = cbChecked
  else
    Result := Index = FItemIndex;
end;

procedure TPPGCustomChoiceGroup.SetChecked(Index: Integer; const Value: Boolean);
begin
  CheckIndex(Index);
  if FMulti then
  begin
    if Value then
      FItemsEx[Index].State := cbChecked
    else
      FItemsEx[Index].State := cbUnchecked;
  end
  else if Value then
    ItemIndex := Index
  else if FItemIndex = Index then
    ItemIndex := -1;
end;

function TPPGCustomChoiceGroup.GetItemState(Index: Integer): TCheckBoxState;
begin
  CheckIndex(Index);
  if FMulti then
    Result := FItemsEx[Index].State
  else if Index = FItemIndex then
    Result := cbChecked
  else
    Result := cbUnchecked;
end;

procedure TPPGCustomChoiceGroup.SetItemState(Index: Integer; const Value: TCheckBoxState);
begin
  CheckIndex(Index);
  if (Value = cbGrayed) and not FAllowGrayed then
    raise EPPGError.CreateFmt(PPGStr(@SPPGInvalidArgument), [Ord(Value), 'ItemState']);
  if FMulti then
    FItemsEx[Index].State := Value
  else
    SetChecked(Index, Value = cbChecked);
end;

function TPPGCustomChoiceGroup.GetItemEnabled(Index: Integer): Boolean;
begin
  CheckIndex(Index);
  Result := FItemsEx[Index].Enabled;
end;

procedure TPPGCustomChoiceGroup.SetItemEnabled(Index: Integer; const Value: Boolean);
begin
  CheckIndex(Index);
  FItemsEx[Index].Enabled := Value;
end;

function ItemValue(It: TPPGChoiceItem): string;
begin
  if It.Value <> '' then
    Result := It.Value
  else
    Result := It.Caption;
end;

function TPPGCustomChoiceGroup.GetValue: string;
var
  I: Integer;
  L: TStringList;
begin
  if not FMulti then
  begin
    if FItemIndex >= 0 then
      Result := ItemValue(FItemsEx[FItemIndex])
    else
      Result := '';
    Exit;
  end;
  L := TStringList.Create;
  try
    L.StrictDelimiter := True;
    for I := 0 to FItemsEx.Count - 1 do
      if FItemsEx[I].State = cbChecked then
        L.Add(ItemValue(FItemsEx[I]));
    Result := L.CommaText;
  finally
    L.Free;
  end;
end;

procedure TPPGCustomChoiceGroup.SetValue(const Value: string);
var
  I: Integer;
  L: TStringList;
begin
  if not FMulti then
  begin
    for I := 0 to FItemsEx.Count - 1 do
      if SameText(ItemValue(FItemsEx[I]), Value) then
      begin
        ItemIndex := I;
        Exit;
      end;
    ItemIndex := -1;
    Exit;
  end;
  L := TStringList.Create;
  try
    L.StrictDelimiter := True;
    L.CommaText := Value;
    BeginUpdate;
    try
      for I := 0 to FItemsEx.Count - 1 do
        if L.IndexOf(ItemValue(FItemsEx[I])) >= 0 then
          FItemsEx[I].State := cbChecked
        else
          FItemsEx[I].State := cbUnchecked;
    finally
      EndUpdate;
    end;
  finally
    L.Free;
  end;
end;

{ Geometrie }

procedure TPPGCustomChoiceGroup.AdjustClientRect(var Rect: TRect);
begin
  if FShowFrame then
    inherited AdjustClientRect(Rect);
end;

function TPPGCustomChoiceGroup.ItemsArea: TRect;
begin
  Result := ClientRect;
  AdjustClientRect(Result);
end;

function TPPGCustomChoiceGroup.ItemTextWidth(Index: Integer): Integer;
begin
  Result := PPGMeasureTextNoCanvas(StripHotkey(FItemsEx[Index].Caption), Font, 0, False).cx;
end;

function TPPGCustomChoiceGroup.CardHeight: Integer;
var
  PPI, TH: Integer;
begin
  PPI := ScalePPI;
  TH := PPGMeasureTextNoCanvas('Ag', Font, 0, False).cy;
  // Titel + zwei Zeilen Beschreibung bzw. Symbol, je nachdem was hoeher ist
  Result := 2 * PPGScale(CardPad, PPI) + Max(PPGScale(CardIcon, PPI), TH * 3 + PPGScale(4, PPI));
end;

function TPPGCustomChoiceGroup.SegmentHeight: Integer;
begin
  Result := PPGMeasureTextNoCanvas('Ag', Font, 0, False).cy + PPGScale(14, ScalePPI);
end;

procedure TPPGCustomChoiceGroup.GetGrid(out Cols, Rows: Integer);
var
  N, W, I, MaxW, PPI: Integer;
  A: TRect;
begin
  N := FItemsEx.Count;
  PPI := ScalePPI;
  A := ItemsArea;
  W := A.Right - A.Left;
  if FChoiceStyle = csSegmented then
  begin
    Cols := Max(N, 1);
    Rows := 1;
    Exit;
  end;
  Cols := FColumns;
  if Cols = 0 then
  begin
    if FChoiceStyle = csCards then
      MaxW := PPGScale(CardMinWidth, PPI)
    else
    begin
      MaxW := 0;
      for I := 0 to N - 1 do
        MaxW := Max(MaxW, ItemTextWidth(I));
      Inc(MaxW, PPGScale(IndSize + IndGap + ItemGap * 2, PPI));
    end;
    Cols := Max(1, (W + PPGScale(ItemGap, PPI)) div Max(MaxW + PPGScale(ItemGap, PPI), 1));
  end;
  if Cols > N then
    Cols := Max(N, 1);
  Rows := (N + Cols - 1) div Max(Cols, 1);
  if Rows < 1 then
    Rows := 1;
end;

function TPPGCustomChoiceGroup.ItemRect(Index: Integer): TRect;
var
  Cols, Rows, C, R, PPI, Gap, CW, RH, X: Integer;
  A: TRect;
begin
  Result := Rect(0, 0, 0, 0);
  if (Index < 0) or (Index >= FItemsEx.Count) then
    Exit;
  PPI := ScalePPI;
  Gap := PPGScale(ItemGap, PPI);
  A := ItemsArea;
  GetGrid(Cols, Rows);
  case FChoiceStyle of
    csList:
      begin
        // Wie TRadioGroup: spaltenweise, Zeilen teilen sich die Hoehe. Spalten
        // nach Breite (Columns = 0) zeilenweise, damit die Reihenfolge beim
        // Umbruch lesbar bleibt (Mo Di Mi ...)
        if FColumns = 0 then
        begin
          C := Index mod Cols;
          R := Index div Cols;
        end
        else
        begin
          C := Index div Rows;
          R := Index mod Rows;
        end;
        RH := Max((A.Bottom - A.Top) div Rows, PPGMeasureTextNoCanvas('Ag', Font, 0, False).cy +
          PPGScale(6, PPI));
        CW := (A.Right - A.Left) div Max(Cols, 1);
        Result := Rect(A.Left + C * CW, A.Top + R * RH, A.Left + (C + 1) * CW, A.Top + (R + 1) * RH);
      end;
    csSegmented:
      begin
        CW := (A.Right - A.Left) div Max(Cols, 1);
        RH := Min(SegmentHeight, A.Bottom - A.Top);
        Result := Rect(A.Left + Index * CW, A.Top, A.Left + (Index + 1) * CW, A.Top + RH);
        if Index = FItemsEx.Count - 1 then
          Result.Right := A.Right;
      end;
  else
    begin
      // Kacheln zeilenweise
      C := Index mod Cols;
      R := Index div Cols;
      CW := ((A.Right - A.Left) - (Cols - 1) * Gap) div Max(Cols, 1);
      RH := CardHeight;
      Result := Rect(A.Left + C * (CW + Gap), A.Top + R * (RH + Gap),
        A.Left + C * (CW + Gap) + CW, A.Top + R * (RH + Gap) + RH);
    end;
  end;
  if UseRightToLeftAlignment then
  begin
    X := A.Left + A.Right - Result.Right;
    Result := Rect(X, Result.Top, X + (Result.Right - Result.Left), Result.Bottom);
  end;
end;

function TPPGCustomChoiceGroup.ItemAt(X, Y: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to FItemsEx.Count - 1 do
    if PtInRect(ItemRect(I), Point(X, Y)) then
      Exit(I);
  Result := -1;
end;

{ Zeichnen }

function TPPGCustomChoiceGroup.GroupTextColor: TColor;
begin
  if HighContrastSupport and PPGIsHighContrast then
  begin
    if Enabled then
      Result := PPGColorToRGB(clWindowText)
    else
      Result := PPGColorToRGB(clGrayText);
  end
  else if UseVclStyle then
    Result := PPGVclStyleCheckTextColor(Enabled)
  else
  begin
    Result := GetContainerStyle(True).TextColor;
    if Enabled and not (HighContrastSupport and PPGIsHighContrast) then
      Result := FItemStyle.TextFor(UseDarkMode, Result);
  end;
end;

function TPPGCustomChoiceGroup.IndicatorStyle(Index: Integer; Checked: Boolean): TPPGSurfaceStyle;
var
  PPI: Integer;
  A: TPPGAppearance;
  H: TPPGSurfaceStyle;
  Usable: Boolean;
begin
  PPI := ScalePPI;
  A := EffectiveAppearance;
  Usable := Enabled and FItemsEx[Index].Enabled;
  if not Usable then
    Result := A.Resolve(vsDisabled, PPI, False)
  else if Checked then
    Result := A.ResolveStyle(A.Checked, PPI, False)
  else if (Index = FDown) and (Index = FHot) then
    Result := A.Resolve(vsDown, PPI, False)
  else if Index = FHot then
    Result := A.Resolve(vsHot, PPI, False)
  else
    Result := A.Resolve(vsNormal, PPI, False);
  if Usable and (Index = FHot) and (Result.GlowAlpha = 0) then
    if Checked then
    begin
      // Auch der gewaehlte Eintrag reagiert auf die Maus (wie die CheckBox)
      H := A.Resolve(vsHot, PPI, False);
      Result.Color := PPGBlendColor(Result.Color, H.Color, 0.18);
      Result.ColorTo := Result.Color;
      Result.ColorMirror := Result.Color;
      Result.ColorMirrorTo := Result.Color;
      Result.BorderColor := PPGBlendColor(Result.BorderColor, H.TextColor, 0.25);
    end
    else
      Result.BorderColor := PPGBlendColor(Result.BorderColor, Result.TextColor, 0.35);
  Result.GlowSize := Min(Result.GlowSize, PPGScale(3, PPI));
  if Focused and FocusVisible and (Index = FFocusIndex) then
  begin
    Result.Focused := True;
    Result.BorderColor := PPGColorToRGB(A.FocusColor);
  end;
  if HighContrastSupport and PPGIsHighContrast then
  begin
    Result.GlowAlpha := 0;
    Result.Color := PPGColorToRGB(clWindow);
    Result.ColorTo := Result.Color;
    Result.ColorMirror := Result.Color;
    Result.ColorMirrorTo := Result.Color;
    if Usable then
      Result.TextColor := PPGColorToRGB(clWindowText)
    else
      Result.TextColor := PPGColorToRGB(clGrayText);
    if Result.Focused or (Index = FHot) then
      Result.BorderColor := PPGColorToRGB(clHighlight)
    else
      Result.BorderColor := Result.TextColor;
  end;
end;

procedure DrawItemSymbol(const ACanvas: IPPGCanvas; Group: TPPGCustomChoiceGroup;
  It: TPPGChoiceItem; const R: TRect; Color: TColor; Usable: Boolean);
var
  X, Y: Integer;
begin
  if (Group.Images <> nil) and (It.ImageIndex >= 0) and (It.ImageIndex < Group.Images.Count) then
  begin
    X := (R.Left + R.Right - Group.Images.Width) div 2;
    Y := (R.Top + R.Bottom - Group.Images.Height) div 2;
    ACanvas.DrawImage(Group.Images, It.ImageIndex, X, Y, Usable);
  end
  else if It.Icon <> 0 then
    PPGDrawIconChar(ACanvas, R, It.Icon, Color, R.Bottom - R.Top);
end;

procedure TPPGCustomChoiceGroup.PaintList(const ACanvas: IPPGCanvas; const Area: TRect);
var
  I, PPI, S, Gap: Integer;
  R, IndR, TR: TRect;
  IR: IPPGIndicatorRenderer;
  St: TPPGSurfaceStyle;
  It: TPPGChoiceItem;
  Flags: Cardinal;
  Txt, Disabled: TColor;
  Temp: TFont;
  F: TFont;
  IsChecked: Boolean;
begin
  PPI := ScalePPI;
  S := PPGScale(IndSize, PPI);
  Gap := PPGScale(IndGap, PPI);
  if not Supports(Renderer, IPPGIndicatorRenderer, IR) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName), IPPGIndicatorRenderer, IR);
  Txt := GroupTextColor;
  Disabled := PPGColorToRGB(EffectiveAppearance.Disabled.TextColor);
  Flags := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_LEFT;
  if not AcceleratorCuesVisible then
    Flags := Flags or DT_HIDEPREFIX;
  Flags := DrawTextBiDiModeFlags(Flags);
  for I := 0 to FItemsEx.Count - 1 do
  begin
    It := FItemsEx[I];
    R := ItemRect(I);
    if IsRectEmpty(R) then
      Continue;
    IsChecked := (FMulti and (It.State <> cbUnchecked)) or (not FMulti and (I = FItemIndex));
    IndR.Top := (R.Top + R.Bottom - S) div 2;
    IndR.Bottom := IndR.Top + S;
    if UseRightToLeftAlignment then
    begin
      IndR.Right := R.Right - PPGScale(2, PPI);
      IndR.Left := IndR.Right - S;
      TR := Rect(R.Left, R.Top, IndR.Left - Gap, R.Bottom);
    end
    else
    begin
      IndR.Left := R.Left + PPGScale(2, PPI);
      IndR.Right := IndR.Left + S;
      TR := Rect(IndR.Right + Gap, R.Top, R.Right - PPGScale(2, PPI), R.Bottom);
    end;
    St := IndicatorStyle(I, IsChecked);
    if IR <> nil then
      if FMulti then
        IR.DrawCheckIndicator(ACanvas, IndR, St, It.State, PPI)
      else
        IR.DrawRadioIndicator(ACanvas, IndR, St, IsChecked, PPI);
    Temp := nil;
    try
      if IsChecked then
        F := PPGElementFont(FSelectedStyle, Font, FItemStyle.FontStyle, Temp)
      else
        F := PPGElementFont(FItemStyle, Font, [], Temp);
      if Enabled and It.Enabled then
        ACanvas.DrawText(TR, It.Caption, F, Txt, Flags)
      else
        ACanvas.DrawText(TR, It.Caption, F, Disabled, Flags);
    finally
      Temp.Free;
    end;
  end;
end;

procedure TPPGCustomChoiceGroup.PaintSegments(const ACanvas: IPPGCanvas; const Area: TRect);
var
  I, PPI, Rad, T: Integer;
  Track, R, Sel, SymR, TR: TRect;
  A: TPPGAppearance;
  Base, Chk: TPPGSurfaceStyle;
  It: TPPGChoiceItem;
  Flags: Cardinal;
  Txt, SelText, SelFill, Line, C: TColor;
  Temp: TFont;
  F: TFont;
  Dark, HC: Boolean;
  P: Single;
begin
  if FItemsEx.Count = 0 then
    Exit;
  PPI := ScalePPI;
  A := EffectiveAppearance;
  Dark := UseDarkMode;
  HC := HighContrastSupport and PPGIsHighContrast;
  Base := A.Resolve(vsNormal, PPI, False);
  Chk := A.ResolveStyle(A.Checked, PPI, False);
  Track := ItemRect(0);
  Track.Right := ItemRect(FItemsEx.Count - 1).Right;
  if UseRightToLeftAlignment then
  begin
    Track.Left := ItemRect(FItemsEx.Count - 1).Left;
    Track.Right := ItemRect(0).Right;
  end;
  Rad := Max(Base.Rounding, PPGScale(4, PPI));
  // Spur
  C := FItemStyle.FillFor(Dark, PPGBlendColor(Base.Color, Base.TextColor, 0.06));
  Line := FItemStyle.BorderFor(Dark, Base.BorderColor);
  Txt := GroupTextColor;
  SelFill := FSelectedStyle.FillFor(Dark, PPGColorToRGB(A.FocusColor));
  SelText := FSelectedStyle.TextFor(Dark, Chk.TextColor);
  SelText := PPGReadableTextColor(SelText, SelFill);
  if HC then
  begin
    C := PPGColorToRGB(clWindow);
    Line := PPGColorToRGB(clWindowText);
    SelFill := PPGColorToRGB(clHighlight);
    SelText := PPGColorToRGB(clHighlightText);
  end;
  if not Enabled then
    SelFill := PPGBlendColor(SelFill, C, 0.6);
  ACanvas.FillRoundRect(Track, Rad, C, 255);
  ACanvas.FrameRoundRect(Track, Rad, Max(1, PPGScale(1, PPI)), Line, 255);
  // Gewaehlter Abschnitt: gleitet beim Wechsel
  if FItemIndex >= 0 then
  begin
    Sel := ItemRect(FItemIndex);
    P := FSlide.Value;
    if P < 1 then
    begin
      Sel.Left := Round(FSlideFrom.Left + (Sel.Left - FSlideFrom.Left) * P);
      Sel.Right := Round(FSlideFrom.Right + (Sel.Right - FSlideFrom.Right) * P);
    end;
    T := PPGScale(3, PPI);
    InflateRect(Sel, -T, -T);
    ACanvas.FillRoundRect(Sel, Max(Rad - T, 2), SelFill, 255);
  end;
  Flags := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_CENTER;
  if not AcceleratorCuesVisible then
    Flags := Flags or DT_HIDEPREFIX;
  Flags := DrawTextBiDiModeFlags(Flags);
  for I := 0 to FItemsEx.Count - 1 do
  begin
    It := FItemsEx[I];
    R := ItemRect(I);
    // Trennlinie zwischen nicht gewaehlten Nachbarn
    if (I > 0) and (I <> FItemIndex) and (I - 1 <> FItemIndex) then
    begin
      T := PPGScale(8, PPI);
      if UseRightToLeftAlignment then
        ACanvas.FillRoundRect(Rect(R.Right, R.Top + T, R.Right + 1, R.Bottom - T), 0, Line, 160)
      else
        ACanvas.FillRoundRect(Rect(R.Left, R.Top + T, R.Left + 1, R.Bottom - T), 0, Line, 160);
    end;
    if (I = FHot) and (I <> FItemIndex) and Enabled and It.Enabled then
    begin
      TR := R;
      InflateRect(TR, -PPGScale(3, PPI), -PPGScale(3, PPI));
      ACanvas.FillRoundRect(TR, Max(Rad - 3, 2), Txt, 18);
    end;
    if I = FItemIndex then
      C := SelText
    else if Enabled and It.Enabled then
      C := Txt
    else
      C := PPGColorToRGB(A.Disabled.TextColor);
    TR := R;
    InflateRect(TR, -PPGScale(SegPadH, PPI) div 2, 0);
    if (It.Icon <> 0) or ((FImages <> nil) and (It.ImageIndex >= 0)) then
    begin
      // Symbol vor dem Text (Gruppe mittig)
      T := PPGScale(16, PPI);
      SymR := Rect(TR.Left, (R.Top + R.Bottom - T) div 2, TR.Left + T, (R.Top + R.Bottom + T) div 2);
      if It.Caption <> '' then
      begin
        SymR.Left := (TR.Left + TR.Right - T - ItemTextWidth(I) - PPGScale(6, PPI)) div 2;
        SymR.Right := SymR.Left + T;
        TR.Left := SymR.Right + PPGScale(6, PPI);
        TR.Right := TR.Left + ItemTextWidth(I) + 1;
      end
      else
      begin
        SymR.Left := (R.Left + R.Right - T) div 2;
        SymR.Right := SymR.Left + T;
      end;
      DrawItemSymbol(ACanvas, Self, It, SymR, C, Enabled and It.Enabled);
    end;
    Temp := nil;
    try
      if I = FItemIndex then
        F := PPGElementFont(FSelectedStyle, Font, [], Temp)
      else
        F := PPGElementFont(FItemStyle, Font, [], Temp);
      ACanvas.DrawText(TR, It.Caption, F, C, Flags);
    finally
      Temp.Free;
    end;
    if Focused and FocusVisible and (I = FFocusIndex) then
    begin
      TR := R;
      InflateRect(TR, -PPGScale(1, PPI), -PPGScale(1, PPI));
      ACanvas.FrameRoundRect(TR, Rad, PPGScale(2, PPI), PPGColorToRGB(A.FocusColor), 255);
    end;
  end;
end;

procedure TPPGCustomChoiceGroup.PaintCards(const ACanvas: IPPGCanvas; const Area: TRect);
var
  I, PPI, Pad, Ic, Rad, TH, S: Integer;
  R, SymR, TitleR, DescR, IndR: TRect;
  A: TPPGAppearance;
  Base: TPPGSurfaceStyle;
  It: TPPGChoiceItem;
  Fill, Border, Txt, Secondary, Accent, C: TColor;
  Temp, TempB: TFont;
  F, FB: TFont;
  Sel, Usable, Dark, HC: Boolean;
  IR: IPPGIndicatorRenderer;
  Flags: Cardinal;
begin
  PPI := ScalePPI;
  A := EffectiveAppearance;
  Base := A.Resolve(vsNormal, PPI, False);
  Dark := UseDarkMode;
  HC := HighContrastSupport and PPGIsHighContrast;
  Pad := PPGScale(CardPad, PPI);
  Ic := PPGScale(CardIcon, PPI);
  S := PPGScale(IndSize, PPI);
  Rad := Max(Base.Rounding, PPGScale(6, PPI));
  Accent := FSelectedStyle.BorderFor(Dark, PPGColorToRGB(A.FocusColor));
  Txt := GroupTextColor;
  Secondary := PPGBlendColor(Txt, Base.Color, 0.35);
  if not Supports(Renderer, IPPGIndicatorRenderer, IR) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName), IPPGIndicatorRenderer, IR);
  Flags := DT_SINGLELINE or DT_TOP or DT_END_ELLIPSIS or DT_LEFT;
  if not AcceleratorCuesVisible then
    Flags := Flags or DT_HIDEPREFIX;
  Flags := DrawTextBiDiModeFlags(Flags);
  for I := 0 to FItemsEx.Count - 1 do
  begin
    It := FItemsEx[I];
    R := ItemRect(I);
    if IsRectEmpty(R) then
      Continue;
    Sel := (FMulti and (It.State <> cbUnchecked)) or (not FMulti and (I = FItemIndex));
    Usable := Enabled and It.Enabled;
    Fill := FItemStyle.FillFor(Dark, Base.Color);
    Border := FItemStyle.BorderFor(Dark, Base.BorderColor);
    if Sel and not Usable then
    begin
      // Gesperrt: grau statt Akzent (wie die uebrigen deaktivierten Controls)
      Border := PPGColorToRGB(A.Disabled.TextColor);
      Fill := PPGBlendColor(Fill, Border, 0.06);
    end
    else if Sel then
    begin
      // Gewaehlt: Akzent-Hauch, unter der Maus etwas kraeftiger
      if (I = FHot) and Usable then
        Fill := FSelectedStyle.FillFor(Dark, PPGBlendColor(Fill, Accent, 0.18))
      else
        Fill := FSelectedStyle.FillFor(Dark, PPGBlendColor(Fill, Accent, 0.10));
      Border := Accent;
    end
    else if (I = FHot) and Usable then
      Border := PPGBlendColor(Border, Txt, 0.35);
    if HC then
    begin
      Fill := PPGColorToRGB(clWindow);
      if Sel or (I = FHot) then
        Border := PPGColorToRGB(clHighlight)
      else
        Border := PPGColorToRGB(clWindowText);
    end;
    ACanvas.FillRoundRect(R, Rad, Fill, 255);
    if Sel then
      ACanvas.FrameRoundRect(R, Rad, PPGScale(2, PPI), Border, 255)
    else
      ACanvas.FrameRoundRect(R, Rad, Max(1, PPGScale(1, PPI)), Border, 255);
    if Usable then
      C := Txt
    else
      C := PPGColorToRGB(A.Disabled.TextColor);
    // Symbol links oben, Kreis/Kaestchen rechts oben, Text dazwischen
    SymR := Rect(0, 0, 0, 0);
    if (It.Icon <> 0) or ((FImages <> nil) and (It.ImageIndex >= 0)) then
    begin
      SymR := Rect(R.Left + Pad, R.Top + Pad, R.Left + Pad + Ic, R.Top + Pad + Ic);
      if UseRightToLeftAlignment then
        SymR := Rect(R.Right - Pad - Ic, SymR.Top, R.Right - Pad, SymR.Bottom);
      if Sel and Usable then
        DrawItemSymbol(ACanvas, Self, It, SymR, Accent, Usable)
      else
        DrawItemSymbol(ACanvas, Self, It, SymR, C, Usable);
    end;
    IndR := Rect(R.Right - Pad - S, R.Top + Pad, R.Right - Pad, R.Top + Pad + S);
    if UseRightToLeftAlignment then
      IndR := Rect(R.Left + Pad, IndR.Top, R.Left + Pad + S, IndR.Bottom);
    if IR <> nil then
      if FMulti then
        IR.DrawCheckIndicator(ACanvas, IndR, IndicatorStyle(I, Sel), It.State, PPI)
      else
        IR.DrawRadioIndicator(ACanvas, IndR, IndicatorStyle(I, Sel), Sel, PPI);
    TitleR := Rect(R.Left + Pad, R.Top + Pad, R.Right - Pad - S - Pad div 2, R.Bottom - Pad);
    if not IsRectEmpty(SymR) then
      if UseRightToLeftAlignment then
        TitleR.Right := SymR.Left - Pad
      else
        TitleR.Left := SymR.Right + Pad;
    if UseRightToLeftAlignment then
    begin
      TitleR.Left := IndR.Right + Pad div 2;
      if IsRectEmpty(SymR) then
        TitleR.Right := R.Right - Pad;
    end;
    Temp := nil;
    TempB := nil;
    try
      FB := PPGElementFont(FItemStyle, Font, [fsBold], TempB);
      F := PPGElementFont(FItemStyle, Font, [], Temp);
      TH := ACanvas.MeasureText('Ag', FB, 0, False).cy;
      ACanvas.DrawText(TitleR, It.Caption, FB, C, Flags);
      if It.Description <> '' then
      begin
        DescR := Rect(TitleR.Left, TitleR.Top + TH + PPGScale(2, PPI), TitleR.Right, R.Bottom - Pad);
        if Usable then
          ACanvas.DrawText(DescR, It.Description, F, Secondary,
            DrawTextBiDiModeFlags(DT_WORDBREAK or DT_END_ELLIPSIS or DT_NOPREFIX or DT_LEFT))
        else
          ACanvas.DrawText(DescR, It.Description, F, C,
            DrawTextBiDiModeFlags(DT_WORDBREAK or DT_END_ELLIPSIS or DT_NOPREFIX or DT_LEFT));
      end;
    finally
      TempB.Free;
      Temp.Free;
    end;
    if Focused and FocusVisible and (I = FFocusIndex) then
    begin
      SymR := R;
      InflateRect(SymR, PPGScale(2, PPI), PPGScale(2, PPI));
      ACanvas.FrameRoundRect(SymR, Rad + PPGScale(2, PPI), PPGScale(2, PPI),
        PPGColorToRGB(A.FocusColor), 255);
    end;
  end;
end;

procedure TPPGCustomChoiceGroup.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  Area, Body, Plate: TRect;
  BodyTop: Integer;
  St: TPPGSurfaceStyle;
  C: TColor;
begin
  if FShowFrame then
    inherited DoPaint(ACanvas, ClientR);
  // Pruefzustand: Rahmen (bzw. ohne Rahmen eine Linie darunter) in Signalfarbe
  if FValidationState in [pvsWarning, pvsError] then
  begin
    if FValidationState = pvsError then
      C := Tokens.Danger
    else
      C := Tokens.Warning;
    St := GetContainerStyle(True);
    if FShowFrame then
    begin
      GetHeader(Plate, BodyTop);
      Body := ClientR;
      Body.Top := BodyTop;
      ACanvas.FrameRoundRect(Body, St.Rounding, Max(2, PPGScale(2, ScalePPI)), C, 255);
    end
    else
      ACanvas.FillRoundRect(Rect(ClientR.Left, ClientR.Bottom - PPGScale(2, ScalePPI),
        ClientR.Right, ClientR.Bottom), 0, C, 255);
  end;
  Area := ItemsArea;
  case FChoiceStyle of
    csSegmented: PaintSegments(ACanvas, Area);
    csCards: PaintCards(ACanvas, Area);
  else
    PaintList(ACanvas, Area);
  end;
end;

procedure TPPGCustomChoiceGroup.UpdateVisualState(Animate: Boolean);
begin
  // Fokus und Hover zeigen sich an den Eintraegen
  Invalidate;
end;

{ Bedienung }

function TPPGCustomChoiceGroup.NextEnabled(From, Delta: Integer): Integer;
var
  I, N: Integer;
begin
  N := FItemsEx.Count;
  Result := -1;
  I := From;
  while True do
  begin
    Inc(I, Delta);
    if (I < 0) or (I >= N) then
      Exit;
    if FItemsEx[I].Enabled then
      Exit(I);
  end;
end;

procedure TPPGCustomChoiceGroup.SetFocusIndex(Value: Integer);
begin
  if (Value < -1) or (Value >= FItemsEx.Count) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Value, FItemsEx.Count - 1]);
  if FFocusIndex <> Value then
  begin
    FFocusIndex := Value;
    if Focused and (Value >= 0) then
      NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, Value + 1);
    Invalidate;
  end;
end;

procedure TPPGCustomChoiceGroup.DoChange;
begin
  Perform(CM_PPGVALUECHANGED, 0, 0);
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGCustomChoiceGroup.ActivateItem(Index: Integer);
var
  It: TPPGChoiceItem;
begin
  if (Index < 0) or (Index >= FItemsEx.Count) or not Enabled then
    Exit;
  It := FItemsEx[Index];
  if not It.Enabled then
    Exit;
  SetFocusIndex(Index);
  if FMulti then
  begin
    // Zyklus wie die CheckBox: aus -> an (-> grau) -> aus
    case It.State of
      cbUnchecked: It.State := cbChecked;
      cbChecked:
        if FAllowGrayed then
          It.State := cbGrayed
        else
          It.State := cbUnchecked;
    else
      It.State := cbUnchecked;
    end;
    NotifyAccessibilityChild(EVENT_OBJECT_STATECHANGE, Index + 1);
    if Assigned(FOnItemClick) then
      FOnItemClick(Self, Index);
    Click;
    DoChange;
  end
  else if Index <> FItemIndex then
  begin
    ItemIndex := Index;
    NotifyAccessibilityChild(EVENT_OBJECT_STATECHANGE, Index + 1);
    Click;
    DoChange;
  end;
end;

procedure TPPGCustomChoiceGroup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // Fokus setzt die Basis (mit Pruefung des Fensterzustands)
  if (Button = mbLeft) and Enabled then
  begin
    FDown := ItemAt(X, Y);
    Invalidate;
  end;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TPPGCustomChoiceGroup.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  H: Integer;
begin
  H := ItemAt(X, Y);
  if (H >= 0) and not FItemsEx[H].Enabled then
    H := -1;
  if H <> FHot then
  begin
    FHot := H;
    Application.CancelHint;
    Invalidate;
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TPPGCustomChoiceGroup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  if (Button = mbLeft) and (FDown >= 0) then
  begin
    I := ItemAt(X, Y);
    // Nur loslassen auf demselben Eintrag waehlt (wie ein Button)
    if (I >= 0) and (I = FDown) then
    begin
      FDown := -1;
      ActivateItem(I);
    end;
    FDown := -1;
    Invalidate;
  end;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TPPGCustomChoiceGroup.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHot <> -1 then
  begin
    FHot := -1;
    Invalidate;
  end;
end;

procedure TPPGCustomChoiceGroup.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TPPGCustomChoiceGroup.DoEnter;
begin
  inherited DoEnter;
  if FFocusIndex < 0 then
  begin
    if (FItemIndex >= 0) and FItemsEx[FItemIndex].Enabled then
      FFocusIndex := FItemIndex
    else
      FFocusIndex := NextEnabled(-1, 1);
  end;
  if FFocusIndex >= 0 then
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, FFocusIndex + 1);
  Invalidate;
end;

procedure TPPGCustomChoiceGroup.KeyDown(var Key: Word; Shift: TShiftState);
var
  N, Cols, Rows, Step: Integer;
  Back: Boolean;
begin
  inherited KeyDown(Key, Shift);
  if (Key = 0) or not Enabled or (FItemsEx.Count = 0) then
    Exit;
  GetGrid(Cols, Rows);
  N := -2;
  Back := UseRightToLeftAlignment;
  // Links/rechts = naechster Eintrag; hoch/runter: Liste (spaltenweise) ebenso,
  // Kacheln und Segmente (zeilenweise) eine Zeile weiter
  if (FChoiceStyle = csList) and (FColumns <> 0) then
    Step := 1
  else
    Step := Cols;
  case Key of
    VK_LEFT:
      if Back then
        N := NextEnabled(FFocusIndex, 1)
      else
        N := NextEnabled(FFocusIndex, -1);
    VK_RIGHT:
      if Back then
        N := NextEnabled(FFocusIndex, -1)
      else
        N := NextEnabled(FFocusIndex, 1);
    VK_UP:
      N := NextEnabled(FFocusIndex, -Step);
    VK_DOWN:
      N := NextEnabled(FFocusIndex, Step);
    VK_HOME:
      N := NextEnabled(-1, 1);
    VK_END:
      N := NextEnabled(FItemsEx.Count, -1);
    VK_SPACE:
      begin
        if FFocusIndex >= 0 then
          ActivateItem(FFocusIndex);
        Key := 0;
        Exit;
      end;
  end;
  if N = -2 then
    Exit;
  Key := 0;
  if N < 0 then
    Exit;
  // RadioGroup: Auswahl folgt dem Fokus (wie die VCL), CheckGroup: nur Fokus
  if FMulti then
    SetFocusIndex(N)
  else
    ActivateItem(N);
end;

function TPPGCustomChoiceGroup.TryFocus: Boolean;
begin
  // CanFocus allein genuegt nicht (unsichtbarer Vorfahr): Fenster pruefen
  Result := Focused;
  if not Result and CanFocus and HandleAllocated and IsWindowVisible(Handle) and
    IsWindowEnabled(GetAncestor(Handle, GA_ROOT)) then
  begin
    SetFocus;
    Result := True;
  end;
end;

procedure TPPGCustomChoiceGroup.DoAccelerator;
begin
  TryFocus;
end;

procedure TPPGCustomChoiceGroup.CMDialogChar(var Message: TCMDialogChar);
var
  I: Integer;
begin
  if Enabled and CanFocus then
    for I := 0 to FItemsEx.Count - 1 do
      if FItemsEx[I].Enabled and IsAccel(Message.CharCode, FItemsEx[I].Caption) then
      begin
        TryFocus;
        ActivateItem(I);
        Message.Result := 1;
        Exit;
      end;
  inherited;
end;

procedure TPPGCustomChoiceGroup.CMHintShow(var Message: TCMHintShow);
var
  I: Integer;
begin
  inherited;
  I := ItemAt(Message.HintInfo.CursorPos.X, Message.HintInfo.CursorPos.Y);
  if (I >= 0) and (FItemsEx[I].Hint <> '') then
  begin
    Message.HintInfo.HintStr := FItemsEx[I].Hint;
    Message.HintInfo.CursorRect := ItemRect(I);
  end;
end;

procedure TPPGCustomChoiceGroup.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  FHot := -1;
  Invalidate;
end;

procedure TPPGCustomChoiceGroup.WndProc(var Message: TMessage);
begin
  if (GMsgChoiceAction <> 0) and (Message.Msg = GMsgChoiceAction) then
  begin
    // Standardaktion des Screenreaders (nie im COM-Aufruf selbst)
    ActivateItem(Integer(Message.WParam) - 1);
    Exit;
  end;
  inherited WndProc(Message);
end;

{ Barrierefreiheit }

function TPPGCustomChoiceGroup.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_GROUPING;
end;

function TPPGCustomChoiceGroup.AccValue: string;
begin
  Result := StripHotkey(Value);
end;

function TPPGCustomChoiceGroup.AccChildCount: Integer;
begin
  Result := FItemsEx.Count;
end;

function TPPGCustomChoiceGroup.AccChildName(Id: Integer): string;
begin
  if (Id >= 1) and (Id <= FItemsEx.Count) then
  begin
    Result := StripHotkey(FItemsEx[Id - 1].Caption);
    if FItemsEx[Id - 1].Description <> '' then
      Result := Result + ', ' + FItemsEx[Id - 1].Description;
  end
  else
    Result := '';
end;

function TPPGCustomChoiceGroup.AccChildRole(Id: Integer): Integer;
begin
  if FMulti then
    Result := ROLE_SYSTEM_CHECKBUTTON
  else
    Result := ROLE_SYSTEM_RADIOBUTTON;
end;

function TPPGCustomChoiceGroup.AccChildState(Id: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  I := Id - 1;
  if (I < 0) or (I >= FItemsEx.Count) then
    Exit;
  if not Enabled or not FItemsEx[I].Enabled then
    Exit(STATE_SYSTEM_UNAVAILABLE);
  Result := STATE_SYSTEM_FOCUSABLE;
  if Focused and (I = FFocusIndex) then
    Result := Result or STATE_SYSTEM_FOCUSED;
  case GetItemState(I) of
    cbChecked: Result := Result or STATE_SYSTEM_CHECKED;
    cbGrayed: Result := Result or STATE_SYSTEM_MIXED;
  end;
end;

function TPPGCustomChoiceGroup.AccChildRect(Id: Integer): TRect;
begin
  Result := ItemRect(Id - 1);
end;

function TPPGCustomChoiceGroup.AccChildAt(X, Y: Integer): Integer;
begin
  Result := ItemAt(X, Y) + 1;
end;

function TPPGCustomChoiceGroup.AccChildDefaultAction(Id: Integer): string;
begin
  if not FMulti then
    Result := PPGStr(@SPPGAccSelect)
  else if (Id >= 1) and (Id <= FItemsEx.Count) and (FItemsEx[Id - 1].State = cbChecked) then
    Result := PPGStr(@SPPGAccUncheck)
  else
    Result := PPGStr(@SPPGAccCheck);
end;

procedure TPPGCustomChoiceGroup.AccChildDoDefault(Id: Integer);
begin
  if HandleAllocated and (GMsgChoiceAction <> 0) then
    PostMessage(Handle, GMsgChoiceAction, WPARAM(Id), 0);
end;

function TPPGCustomChoiceGroup.AccFocusedChild: Integer;
begin
  if Focused then
    Result := FFocusIndex + 1
  else
    Result := 0;
end;

function TPPGCustomChoiceGroup.AccSelectedChild: Integer;
begin
  if FMulti then
    Result := 0
  else
    Result := FItemIndex + 1;
end;

{ TPPGCheckGroup }

constructor TPPGCheckGroup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Multi := True;
end;

initialization
  GMsgChoiceAction := RegisterWindowMessage('PPGlow.ChoiceGroup.Action');

end.
