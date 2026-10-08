unit PPG.ToolBar;

{ TPPGToolBar - Befehlsleiste (Phase 7c, wie WinUI CommandBar).

  - Items: Buttons, Umschalt-Buttons (tisCheck, mit GroupIndex wie
    Radiobuttons) und Trenner; Symbol aus Images oder der Symbolschrift
    (IconChar), Text wahlweise daneben (ShowCaptions).
  - Optik aus dem Preset: Hover/gedrueckt/eingerastet ueber den Renderer wie
    TPPGButton, in Ruhe flach.
  - Ueberlauf: Was nicht in die Breite passt, landet in einem "..."-Menue am
    Ende (Menue im Stil der Suite mit Haken fuer Umschalt-Buttons, Phase 11).
  - Actions: Item.Action verbindet Caption, Hint, Enabled, Checked, Visible,
    ImageIndex und OnExecute; die Leiste aktualisiert die Actions im Leerlauf
    (InitiateAction) wie die VCL-Controls.
  - Tastatur: Links/Rechts, Pos1/Ende, Enter/Leertaste.
  - Code (Down := ...) loest kein Ereignis aus; ein Klick loest
    Item.OnClick (bzw. Action.Execute) und danach OnItemClick aus.
  - Screenreader: Symbolleiste; Kinder Buttons/Umschalt-Buttons/Trenner und
    der Ueberlauf-Knopf. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  {$IFDEF PPG_HAS_SYSTEM_ACTIONS}System.Actions,{$ENDIF} Vcl.ActnList, Vcl.Controls, Vcl.Graphics, Vcl.Menus, Vcl.ImgList,
  PPG.Types, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Base;

type
  TPPGToolBar = class;
  TPPGToolItem = class;

  TPPGToolItemStyle = (tisButton, tisCheck, tisSeparator);

  TPPGToolItemActionLink = class(TActionLink)
  protected
    FClient: TPPGToolItem;
    procedure AssignClient(AClient: TObject); override;
    function IsCaptionLinked: Boolean; override;
    function IsCheckedLinked: Boolean; override;
    function IsEnabledLinked: Boolean; override;
    function IsHintLinked: Boolean; override;
    function IsImageIndexLinked: Boolean; override;
    function IsVisibleLinked: Boolean; override;
    function IsOnExecuteLinked: Boolean; override;
    procedure SetCaption(const Value: string); override;
    procedure SetChecked(Value: Boolean); override;
    procedure SetEnabled(Value: Boolean); override;
    procedure SetHint(const Value: string); override;
    procedure SetImageIndex(Value: Integer); override;
    procedure SetVisible(Value: Boolean); override;
  end;

  TPPGToolItem = class(TCollectionItem)
  private
    FCaption: string;
    FHint: string;
    FStyle: TPPGToolItemStyle;
    FImageIndex: TPPGImageIndex;
    FIconChar: Word;
    FDown: Boolean;
    FGroupIndex: Integer;
    FEnabled: Boolean;
    FVisible: Boolean;
    FTag: NativeInt;
    FColor: TColor;
    FTextColor: TColor;
    FFontStyle: TFontStyles;
    FActionLink: TPPGToolItemActionLink;
    FOnClick: TNotifyEvent;
    procedure SetCaption(const Value: string);
    procedure SetStyle(const Value: TPPGToolItemStyle);
    procedure SetImageIndex(const Value: TPPGImageIndex);
    procedure SetIconChar(const Value: Word);
    procedure SetDown(const Value: Boolean);
    procedure SetEnabled(const Value: Boolean);
    procedure SetVisible(const Value: Boolean);
    procedure SetColor(const Value: TColor);
    procedure SetTextColor(const Value: TColor);
    procedure SetFontStyle(const Value: TFontStyles);
    function GetAction: TBasicAction;
    procedure SetAction(const Value: TBasicAction);
    function IsCaptionStored: Boolean;
    function IsHintStored: Boolean;
    function IsEnabledStored: Boolean;
    function IsVisibleStored: Boolean;
    function IsDownStored: Boolean;
    function IsImageIndexStored: Boolean;
    function IsOnClickStored: Boolean;
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean);
    procedure DoActionChange(Sender: TObject);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function ToolBar: TPPGToolBar;
    property ActionLink: TPPGToolItemActionLink read FActionLink;
  published
    property Action: TBasicAction read GetAction write SetAction;
    property Caption: string read FCaption write SetCaption stored IsCaptionStored;
    property Hint: string read FHint write FHint stored IsHintStored;
    property Style: TPPGToolItemStyle read FStyle write SetStyle default tisButton;
    property ImageIndex: TPPGImageIndex read FImageIndex write SetImageIndex
      stored IsImageIndexStored default -1;
    /// Zeichen der Symbolschrift (0 = keins).
    property IconChar: Word read FIconChar write SetIconChar default 0;
    /// Eingerastet (nur tisCheck).
    property Down: Boolean read FDown write SetDown stored IsDownStored default False;
    /// Umschalt-Buttons mit gleichem GroupIndex <> 0 schliessen sich aus.
    property GroupIndex: Integer read FGroupIndex write FGroupIndex default 0;
    property Enabled: Boolean read FEnabled write SetEnabled stored IsEnabledStored default True;
    property Visible: Boolean read FVisible write SetVisible stored IsVisibleStored default True;
    property Tag: NativeInt read FTag write FTag default 0;
    /// Flaeche (auch in Ruhe, z.B. fuer die Hauptaktion), Text und Schriftstile.
    property Color: TColor read FColor write SetColor default clDefault;
    property TextColor: TColor read FTextColor write SetTextColor default clDefault;
    property FontStyle: TFontStyles read FFontStyle write SetFontStyle default [];
    property OnClick: TNotifyEvent read FOnClick write FOnClick stored IsOnClickStored;
  end;

  TPPGToolItems = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGToolItem;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPPGToolBar);
    function Add: TPPGToolItem;
    function AddButton(const ACaption: string; AIconChar: Word = 0; AOnClick: TNotifyEvent = nil): TPPGToolItem;
    function AddCheck(const ACaption: string; AIconChar: Word = 0; AGroupIndex: Integer = 0): TPPGToolItem;
    function AddSeparator: TPPGToolItem;
    property Items[Index: Integer]: TPPGToolItem read GetItem; default;
  end;

  TPPGToolItemEvent = procedure(Sender: TObject; Item: TPPGToolItem) of object;

  TPPGToolBar = class(TPPGCustomControl, IPPGAccessibleChildren)
  private
    FImageTint: TPPGImageTint;
    FItems: TPPGToolItems;
    FShowCaptions: Boolean;
    FLayoutValid: Boolean;
    FRects: array of TRect;   // je Item, leer = verborgen/Ueberlauf
    FOverflow: Boolean;
    FOverflowRect: TRect;
    FHotPart: Integer;        // Item-Index, -2 = Ueberlauf, -1 = nichts
    FDownPart: Integer;
    FFocusPart: Integer;
    FMenu: TPopupMenu;
    FOnItemClick: TPPGToolItemEvent;
    procedure DrawItemImage(const ACanvas: IPPGCanvas; Index, X, Y: Integer; AEnabled: Boolean;
      Color: TColor);
    procedure SetImageTint(const Value: TPPGImageTint);
    procedure SetItems(const Value: TPPGToolItems);
    procedure SetShowCaptions(const Value: Boolean);
    procedure EnsureLayout;
    function ItemWidth(Item: TPPGToolItem): Integer;
    function ButtonHeight: Integer;
    procedure MenuItemClick(Sender: TObject);
    function NextFocusable(From, Dir: Integer): Integer;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    procedure WndProc(var Message: TMessage); override;
    procedure Resize; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    function CalcAutoSize(out AWidth, AHeight: Integer): Boolean; override;
    function AutoSizeWidth: Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure ItemsChanged; virtual;
    function AccRole: Integer; override;
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
    procedure InitiateAction; override;
    /// Item ausloesen wie per Klick (Umschalten, OnClick/Action, OnItemClick).
    procedure ClickItem(Item: TPPGToolItem);
    function ItemRect(Index: Integer): TRect;
    /// Item unter dem Punkt (-2 = Ueberlauf, -1 = nichts).
    function PartAt(X, Y: Integer): Integer;
    /// Items, die gerade im Ueberlauf-Menue liegen.
    function IsInOverflow(Index: Integer): Boolean;
    function HasOverflow: Boolean;
    function OverflowRect: TRect;
    procedure ShowOverflowMenu;
    property HotPart: Integer read FHotPart;
    property FocusPart: Integer read FFocusPart;
    property OverflowMenu: TPopupMenu read FMenu;
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property HighContrastSupport;
    property Images;
    property Items: TPPGToolItems read FItems write SetItems;
    property ShowCaptions: Boolean read FShowCaptions write SetShowCaptions default True;
    /// itTextColor: Symbole einfarbig in der Textfarbe (Hover, Dunkel, Deaktiviert).
    property ImageTint: TPPGImageTint read FImageTint write SetImageTint default itNone;
    property Align default alTop;
    property Anchors;
    property AutoSize default True;
    property BiDiMode;
    property Color;
    property Constraints;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint default True;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Touch;
    property OnGesture;
    property OnEnter;
    property OnExit;
    property OnItemClick: TPPGToolItemEvent read FOnItemClick write FOnItemClick;
  end;

implementation

uses
  PPG.Lang,
  System.Math, Winapi.oleacc, Vcl.Forms,
  PPG.Consts, PPG.Appearance, PPG.DpiUtils, PPG.Tokens, PPG.IconFont, PPG.Render.Gdi,
  PPG.Menus;

const
  BtnPadH = 10;
  IconSz = 16;
  SepW = 9;
  BarPad = 4;

var
  GMsgToolAction: Cardinal = 0;

{ TPPGToolItemActionLink }

procedure TPPGToolItemActionLink.AssignClient(AClient: TObject);
begin
  FClient := AClient as TPPGToolItem;
end;

function TPPGToolItemActionLink.IsCaptionLinked: Boolean;
begin
  Result := inherited IsCaptionLinked and (Action is TCustomAction) and
    (FClient.Caption = TCustomAction(Action).Caption);
end;

function TPPGToolItemActionLink.IsCheckedLinked: Boolean;
begin
  Result := inherited IsCheckedLinked and (Action is TCustomAction) and
    (FClient.Down = TCustomAction(Action).Checked);
end;

function TPPGToolItemActionLink.IsEnabledLinked: Boolean;
begin
  Result := inherited IsEnabledLinked and (Action is TCustomAction) and
    (FClient.Enabled = TCustomAction(Action).Enabled);
end;

function TPPGToolItemActionLink.IsHintLinked: Boolean;
begin
  Result := inherited IsHintLinked and (Action is TCustomAction) and
    (FClient.Hint = TCustomAction(Action).Hint);
end;

function TPPGToolItemActionLink.IsImageIndexLinked: Boolean;
begin
  Result := inherited IsImageIndexLinked and (Action is TCustomAction) and
    (FClient.ImageIndex = TCustomAction(Action).ImageIndex);
end;

function TPPGToolItemActionLink.IsVisibleLinked: Boolean;
begin
  Result := inherited IsVisibleLinked and (Action is TCustomAction) and
    (FClient.Visible = TCustomAction(Action).Visible);
end;

function SameMethod(const A, B: TNotifyEvent): Boolean;
begin
  Result := (TMethod(A).Code = TMethod(B).Code) and (TMethod(A).Data = TMethod(B).Data);
end;

function TPPGToolItemActionLink.IsOnExecuteLinked: Boolean;
begin
  Result := inherited IsOnExecuteLinked and SameMethod(FClient.OnClick, Action.OnExecute);
end;

procedure TPPGToolItemActionLink.SetCaption(const Value: string);
begin
  if IsCaptionLinked then
    FClient.Caption := Value;
end;

procedure TPPGToolItemActionLink.SetChecked(Value: Boolean);
begin
  if IsCheckedLinked then
    FClient.Down := Value;
end;

procedure TPPGToolItemActionLink.SetEnabled(Value: Boolean);
begin
  if IsEnabledLinked then
    FClient.Enabled := Value;
end;

procedure TPPGToolItemActionLink.SetHint(const Value: string);
begin
  if IsHintLinked then
    FClient.Hint := Value;
end;

procedure TPPGToolItemActionLink.SetImageIndex(Value: Integer);
begin
  if IsImageIndexLinked then
    FClient.ImageIndex := Value;
end;

procedure TPPGToolItemActionLink.SetVisible(Value: Boolean);
begin
  if IsVisibleLinked then
    FClient.Visible := Value;
end;

{ TPPGToolItem }

constructor TPPGToolItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FImageIndex := -1;
  FEnabled := True;
  FVisible := True;
  FColor := clDefault;
  FTextColor := clDefault;
end;

destructor TPPGToolItem.Destroy;
begin
  FreeAndNil(FActionLink);
  inherited Destroy;
end;

procedure TPPGToolItem.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Changed(False);
  end;
end;

procedure TPPGToolItem.SetTextColor(const Value: TColor);
begin
  if FTextColor <> Value then
  begin
    FTextColor := Value;
    Changed(False);
  end;
end;

procedure TPPGToolItem.SetFontStyle(const Value: TFontStyles);
begin
  if FFontStyle <> Value then
  begin
    FFontStyle := Value;
    Changed(True); // Breite aendert sich
  end;
end;

procedure TPPGToolItem.Assign(Source: TPersistent);
var
  S: TPPGToolItem;
begin
  if Source is TPPGToolItem then
  begin
    S := TPPGToolItem(Source);
    FCaption := S.FCaption;
    FHint := S.FHint;
    FStyle := S.FStyle;
    FImageIndex := S.FImageIndex;
    FIconChar := S.FIconChar;
    FDown := S.FDown;
    FGroupIndex := S.FGroupIndex;
    FEnabled := S.FEnabled;
    FVisible := S.FVisible;
    FTag := S.FTag;
    FColor := S.FColor;
    FTextColor := S.FTextColor;
    FFontStyle := S.FFontStyle;
    FOnClick := S.FOnClick;
    Action := S.Action;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGToolItem.GetDisplayName: string;
begin
  if FStyle = tisSeparator then
    Result := '-'
  else if FCaption <> '' then
    Result := FCaption
  else
    Result := inherited GetDisplayName;
end;

function TPPGToolItem.ToolBar: TPPGToolBar;
begin
  if (Collection <> nil) and (Collection.Owner is TPPGToolBar) then
    Result := TPPGToolBar(Collection.Owner)
  else
    Result := nil;
end;

procedure TPPGToolItem.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

procedure TPPGToolItem.SetStyle(const Value: TPPGToolItemStyle);
begin
  if FStyle <> Value then
  begin
    FStyle := Value;
    Changed(False);
  end;
end;

procedure TPPGToolItem.SetImageIndex(const Value: TPPGImageIndex);
begin
  if FImageIndex <> Value then
  begin
    FImageIndex := Value;
    Changed(False);
  end;
end;

procedure TPPGToolItem.SetIconChar(const Value: Word);
begin
  if FIconChar <> Value then
  begin
    FIconChar := Value;
    Changed(False);
  end;
end;

procedure TPPGToolItem.SetDown(const Value: Boolean);
var
  I: Integer;
  Other: TPPGToolItem;
begin
  if FDown = Value then
    Exit;
  FDown := Value;
  // Gruppe: die anderen rasten aus
  if Value and (FGroupIndex <> 0) and (Collection <> nil) then
    for I := 0 to Collection.Count - 1 do
    begin
      Other := TPPGToolItem(Collection.Items[I]);
      if (Other <> Self) and (Other.FGroupIndex = FGroupIndex) and Other.FDown then
      begin
        Other.FDown := False;
        if (Other.Action is TCustomAction) then
          TCustomAction(Other.Action).Checked := False;
      end;
    end;
  Changed(False);
end;

procedure TPPGToolItem.SetEnabled(const Value: Boolean);
begin
  if FEnabled <> Value then
  begin
    FEnabled := Value;
    Changed(False);
  end;
end;

procedure TPPGToolItem.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    Changed(False);
  end;
end;

function TPPGToolItem.GetAction: TBasicAction;
begin
  if FActionLink <> nil then
    Result := FActionLink.Action
  else
    Result := nil;
end;

procedure TPPGToolItem.SetAction(const Value: TBasicAction);
begin
  if Value = nil then
  begin
    FreeAndNil(FActionLink);
    Exit;
  end;
  if FActionLink = nil then
    FActionLink := TPPGToolItemActionLink.Create(Self);
  FActionLink.Action := Value;
  FActionLink.OnChange := DoActionChange;
  ActionChange(Value, csLoading in Value.ComponentState);
  if ToolBar <> nil then
    Value.FreeNotification(ToolBar);
end;

procedure TPPGToolItem.DoActionChange(Sender: TObject);
begin
  if Sender = Action then
    ActionChange(Sender, False);
end;

procedure TPPGToolItem.ActionChange(Sender: TObject; CheckDefaults: Boolean);
var
  A: TCustomAction;
begin
  if not (Sender is TCustomAction) then
    Exit;
  A := TCustomAction(Sender);
  if not CheckDefaults or (FCaption = '') then
    FCaption := A.Caption;
  if not CheckDefaults or (FHint = '') then
    FHint := A.Hint;
  if not CheckDefaults or FEnabled then
    FEnabled := A.Enabled;
  if not CheckDefaults or FVisible then
    FVisible := A.Visible;
  if not CheckDefaults or not FDown then
    FDown := A.Checked;
  if not CheckDefaults or (FImageIndex = -1) then
    FImageIndex := A.ImageIndex;
  if not CheckDefaults or not Assigned(FOnClick) then
    FOnClick := A.OnExecute;
  if A.Checked or A.AutoCheck then
    FStyle := tisCheck;
  if A.GroupIndex <> 0 then
    FGroupIndex := A.GroupIndex;
  Changed(False);
end;

function TPPGToolItem.IsCaptionStored: Boolean;
begin
  Result := (FActionLink = nil) or not FActionLink.IsCaptionLinked;
end;

function TPPGToolItem.IsHintStored: Boolean;
begin
  Result := (FActionLink = nil) or not FActionLink.IsHintLinked;
end;

function TPPGToolItem.IsEnabledStored: Boolean;
begin
  Result := (FActionLink = nil) or not FActionLink.IsEnabledLinked;
end;

function TPPGToolItem.IsVisibleStored: Boolean;
begin
  Result := (FActionLink = nil) or not FActionLink.IsVisibleLinked;
end;

function TPPGToolItem.IsDownStored: Boolean;
begin
  Result := (FActionLink = nil) or not FActionLink.IsCheckedLinked;
end;

function TPPGToolItem.IsImageIndexStored: Boolean;
begin
  Result := (FActionLink = nil) or not FActionLink.IsImageIndexLinked;
end;

function TPPGToolItem.IsOnClickStored: Boolean;
begin
  Result := (FActionLink = nil) or not FActionLink.IsOnExecuteLinked;
end;

{ TPPGToolItems }

constructor TPPGToolItems.Create(AOwner: TPPGToolBar);
begin
  inherited Create(AOwner, TPPGToolItem);
end;

function TPPGToolItems.GetItem(Index: Integer): TPPGToolItem;
begin
  Result := TPPGToolItem(inherited Items[Index]);
end;

function TPPGToolItems.Add: TPPGToolItem;
begin
  Result := TPPGToolItem(inherited Add);
end;

function TPPGToolItems.AddButton(const ACaption: string; AIconChar: Word;
  AOnClick: TNotifyEvent): TPPGToolItem;
begin
  Result := Add;
  Result.FCaption := ACaption;
  Result.FIconChar := AIconChar;
  Result.FOnClick := AOnClick;
  Result.Changed(False);
end;

function TPPGToolItems.AddCheck(const ACaption: string; AIconChar: Word;
  AGroupIndex: Integer): TPPGToolItem;
begin
  Result := Add;
  Result.FCaption := ACaption;
  Result.FIconChar := AIconChar;
  Result.FStyle := tisCheck;
  Result.FGroupIndex := AGroupIndex;
  Result.Changed(False);
end;

function TPPGToolItems.AddSeparator: TPPGToolItem;
begin
  Result := Add;
  Result.FStyle := tisSeparator;
  Result.Changed(False);
end;

procedure TPPGToolItems.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Owner is TPPGToolBar then
  begin
    // Item = nil: Eintraege hinzugefuegt, geloescht oder umsortiert. Hover
    // und gedrueckter Eintrag sind Positionen und zeigen dann auf andere
    // Buttons (bzw. ins Leere).
    if Item = nil then
    begin
      TPPGToolBar(Owner).FHotPart := -1;
      TPPGToolBar(Owner).FDownPart := -1;
    end;
    TPPGToolBar(Owner).ItemsChanged;
  end;
end;

{ TPPGToolBar }

procedure TPPGToolBar.DrawItemImage(const ACanvas: IPPGCanvas; Index, X, Y: Integer;
  AEnabled: Boolean; Color: TColor);
var
  DC: HDC;
begin
  if FImageTint = itNone then
  begin
    ACanvas.DrawImage(Images, Index, X, Y, AEnabled);
    Exit;
  end;
  DC := ACanvas.BeginGdi;
  try
    PPGGdiDrawImageTinted(DC, Images, Index, X, Y, Color);
  finally
    ACanvas.EndGdi(DC);
  end;
end;

procedure TPPGToolBar.SetImageTint(const Value: TPPGImageTint);
begin
  if FImageTint <> Value then
  begin
    FImageTint := Value;
    Invalidate;
  end;
end;

constructor TPPGToolBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption, csClickEvents, csDoubleClicks];
  FItems := TPPGToolItems.Create(Self);
  FShowCaptions := True;
  FHotPart := -1;
  FDownPart := -1;
  FFocusPart := -1;
  TabStop := True;
  ShowHint := True;
  Align := alTop;
  Width := 400;
  Height := 40;
  AutoSize := True;
  if GMsgToolAction = 0 then
    GMsgToolAction := RegisterWindowMessage('PPGlow.ToolBarAction');
end;

destructor TPPGToolBar.Destroy;
begin
  FreeAndNil(FMenu);
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TPPGToolBar.Notification(AComponent: TComponent; Operation: TOperation);
var
  I: Integer;
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FItems <> nil) and (AComponent is TBasicAction) then
    for I := 0 to FItems.Count - 1 do
      if FItems[I].Action = AComponent then
        FItems[I].Action := nil;
end;

procedure TPPGToolBar.InitiateAction;
var
  I: Integer;
begin
  inherited InitiateAction;
  // Leerlauf: Actions der Items aktualisieren (wie TControl.InitiateAction)
  for I := 0 to FItems.Count - 1 do
    if FItems[I].ActionLink <> nil then
      FItems[I].ActionLink.Update;
end;

procedure TPPGToolBar.SetItems(const Value: TPPGToolItems);
begin
  FItems.Assign(Value);
end;

procedure TPPGToolBar.SetShowCaptions(const Value: Boolean);
begin
  if FShowCaptions <> Value then
  begin
    FShowCaptions := Value;
    ItemsChanged;
  end;
end;

procedure TPPGToolBar.ItemsChanged;
begin
  if csDestroying in ComponentState then
    Exit;
  FLayoutValid := False;
  if FFocusPart >= FItems.Count then
    FFocusPart := -1;
  RequestAutoSize;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

function TPPGToolBar.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGToolBar.IsDown: Boolean;
begin
  Result := False;
end;

function TPPGToolBar.ButtonHeight: Integer;
begin
  Result := Max(PPGScale(32, ScalePPI), PPGMeasureTextNoCanvas('Wg', Font, 0, False).cy +
    2 * PPGScale(6, ScalePPI));
end;

function TPPGToolBar.ItemWidth(Item: TPPGToolItem): Integer;
var
  PPI: Integer;
  HasIcon: Boolean;
  Temp: TFont;
begin
  PPI := ScalePPI;
  if Item.Style = tisSeparator then
    Exit(PPGScale(SepW, PPI));
  HasIcon := (Item.IconChar <> 0) or ((Images <> nil) and (Item.ImageIndex >= 0));
  Result := 2 * PPGScale(BtnPadH, PPI);
  if HasIcon then
    Inc(Result, PPGScale(IconSz, PPI));
  if (FShowCaptions or not HasIcon) and (Item.Caption <> '') then
  begin
    if HasIcon then
      Inc(Result, PPGScale(8, PPI));
    // Breite mit den Schriftstilen des Eintrags (fett ist breiter)
    Temp := nil;
    try
      Inc(Result, PPGMeasureTextNoCanvas(StripHotkey(Item.Caption),
        PPGStyledFont(Font, Item.FontStyle, Temp), 0, False).cx);
    finally
      Temp.Free;
    end;
  end;
  if Result < ButtonHeight then
    Result := ButtonHeight;
end;

procedure TPPGToolBar.EnsureLayout;
var
  I, X, W, Avail, BH, Top, Last: Integer;
begin
  if FLayoutValid then
    Exit;
  FLayoutValid := True;
  SetLength(FRects, FItems.Count);
  BH := ButtonHeight;
  Top := (Height - BH) div 2;
  X := PPGScale(BarPad, ScalePPI);
  FOverflow := False;
  // Erst pruefen, ob alles passt; sonst Platz fuer den Ueberlauf-Knopf lassen
  W := X;
  for I := 0 to FItems.Count - 1 do
    if FItems[I].Visible then
      Inc(W, ItemWidth(FItems[I]) + PPGScale(2, ScalePPI));
  Avail := Width - PPGScale(BarPad, ScalePPI);
  if W > Avail then
  begin
    FOverflow := True;
    Dec(Avail, BH + PPGScale(2, ScalePPI));
  end;
  Last := -1;
  for I := 0 to FItems.Count - 1 do
  begin
    FRects[I] := Rect(0, 0, 0, 0);
    if not FItems[I].Visible then
      Continue;
    W := ItemWidth(FItems[I]);
    if FOverflow and (X + W > Avail) then
    begin
      // ab hier alles in den Ueberlauf (Reihenfolge bleibt)
      X := MaxInt div 2;
      Continue;
    end;
    FRects[I] := Rect(X, Top, X + W, Top + BH);
    Last := I;
    Inc(X, W + PPGScale(2, ScalePPI));
  end;
  // Trenner am Ende der sichtbaren Reihe weglassen
  if (Last >= 0) and (FItems[Last].Style = tisSeparator) then
    FRects[Last] := Rect(0, 0, 0, 0);
  if FOverflow then
    FOverflowRect := Rect(Width - PPGScale(BarPad, ScalePPI) - BH, Top,
      Width - PPGScale(BarPad, ScalePPI), Top + BH)
  else
    FOverflowRect := Rect(0, 0, 0, 0);
  if UseRightToLeftAlignment then
  begin
    for I := 0 to High(FRects) do
      if not IsRectEmpty(FRects[I]) then
        FRects[I] := Rect(Width - FRects[I].Right, FRects[I].Top, Width - FRects[I].Left, FRects[I].Bottom);
    if FOverflow then
      FOverflowRect := Rect(Width - FOverflowRect.Right, FOverflowRect.Top, Width - FOverflowRect.Left,
        FOverflowRect.Bottom);
  end;
end;

function TPPGToolBar.ItemRect(Index: Integer): TRect;
begin
  EnsureLayout;
  if (Index >= 0) and (Index < Length(FRects)) then
    Result := FRects[Index]
  else
    Result := Rect(0, 0, 0, 0);
end;

function TPPGToolBar.HasOverflow: Boolean;
var
  I: Integer;
begin
  EnsureLayout;
  Result := False;
  if FOverflow then
    for I := 0 to FItems.Count - 1 do
      if IsInOverflow(I) then
        Exit(True);
end;

function TPPGToolBar.IsInOverflow(Index: Integer): Boolean;
begin
  EnsureLayout;
  Result := FOverflow and (Index >= 0) and (Index < FItems.Count) and FItems[Index].Visible and
    IsRectEmpty(FRects[Index]) and (FItems[Index].Style <> tisSeparator);
end;

function TPPGToolBar.OverflowRect: TRect;
begin
  EnsureLayout;
  Result := FOverflowRect;
end;

function TPPGToolBar.PartAt(X, Y: Integer): Integer;
var
  I: Integer;
begin
  EnsureLayout;
  if FOverflow and PtInRect(FOverflowRect, Point(X, Y)) then
    Exit(-2);
  for I := 0 to FItems.Count - 1 do
    if (FItems[I].Style <> tisSeparator) and PtInRect(FRects[I], Point(X, Y)) then
      Exit(I);
  Result := -1;
end;

function TPPGToolBar.AutoSizeWidth: Boolean;
begin
  Result := False; // nur die Hoehe folgt der Schrift
end;

function TPPGToolBar.CalcAutoSize(out AWidth, AHeight: Integer): Boolean;
begin
  AWidth := Width;
  AHeight := ButtonHeight + 2 * PPGScale(BarPad, ScalePPI);
  Result := True;
end;

procedure TPPGToolBar.Resize;
begin
  inherited Resize;
  FLayoutValid := False;
end;

procedure TPPGToolBar.CMFontChanged(var Message: TMessage);
begin
  inherited;
  ItemsChanged;
end;

procedure TPPGToolBar.ClickItem(Item: TPPGToolItem);
var
  ItemId: Integer;
begin
  if (Item = nil) or (Item.Style = tisSeparator) or not Item.Enabled or not Enabled then
    Exit;
  if Item.Style = tisCheck then
    // AutoCheck-Actions schalten beim Ausfuehren selbst um
    if not ((Item.Action is TCustomAction) and TCustomAction(Item.Action).AutoCheck) then
    begin
      // In der Gruppe rastet ein Klick auf den eingerasteten Button nicht aus
      if not (Item.Down and (Item.GroupIndex <> 0)) then
        Item.Down := not Item.Down;
      if Item.Action is TCustomAction then
        TCustomAction(Item.Action).Checked := Item.Down;
    end;
  // Wie TControl.Click: eigenes OnClick vor der Action, sonst Action.Execute
  ItemId := Item.ID;
  if Assigned(Item.OnClick) and (Item.Action <> nil) and
    not SameMethod(Item.OnClick, Item.Action.OnExecute) then
    Item.OnClick(Item)
  else if Item.ActionLink <> nil then
    Item.ActionLink.Execute(Self)
  else if Assigned(Item.OnClick) then
    Item.OnClick(Item);
  // Der Handler darf den eigenen Button entfernen: nur ein noch vorhandenes
  // Item an OnItemClick geben (Suche ueber die Kennung, ohne Item anzufassen)
  if FItems.FindItemID(ItemId) <> Item then
    Exit;
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, Item);
  NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
end;

procedure TPPGToolBar.ShowOverflowMenu;
var
  I: Integer;
  M: TMenuItem;
  P: TPoint;
  It: TPPGToolItem;
  PrevSep: Boolean;
begin
  if not HasOverflow or not HandleAllocated then
    Exit;
  if FMenu = nil then
    FMenu := TPPGPopupMenu.Create(nil);
  FMenu.Items.Clear;
  FMenu.Images := Images;
  PrevSep := True;
  for I := 0 to FItems.Count - 1 do
  begin
    It := FItems[I];
    if not FItems[I].Visible or not IsRectEmpty(FRects[I]) then
      Continue;
    M := TMenuItem.Create(FMenu);
    if It.Style = tisSeparator then
    begin
      if PrevSep then
      begin
        M.Free;
        Continue;
      end;
      M.Caption := '-';
      PrevSep := True;
    end
    else
    begin
      M.Caption := It.Caption;
      M.Hint := It.Hint;
      M.Enabled := It.Enabled;
      M.Checked := (It.Style = tisCheck) and It.Down;
      M.ImageIndex := It.ImageIndex;
      M.Tag := I;
      M.OnClick := MenuItemClick;
      PrevSep := False;
    end;
    FMenu.Items.Add(M);
  end;
  FMenu.BiDiMode := BiDiMode;
  if UseRightToLeftAlignment then
    FMenu.Alignment := paLeft
  else
    FMenu.Alignment := paRight;
  // Menue im Stil der Suite unter dem Ueberlauf-Knopf (Preset vom ToolBar)
  FMenu.PopupComponent := Self;
  P := ClientToScreen(FOverflowRect.TopLeft);
  TPPGPopupMenu(FMenu).PopupAtRect(Rect(P.X, P.Y, P.X + FOverflowRect.Right - FOverflowRect.Left,
    P.Y + FOverflowRect.Bottom - FOverflowRect.Top));
end;

procedure TPPGToolBar.MenuItemClick(Sender: TObject);
var
  I: Integer;
begin
  I := TMenuItem(Sender).Tag;
  if (I >= 0) and (I < FItems.Count) then
    ClickItem(FItems[I]);
end;

{ ---- Zeichnen ---- }

procedure TPPGToolBar.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  T: TPPGTokens;
  A: TPPGAppearance;
  PPI, I, X, Rad: Integer;
  HC, HasIcon, Hot, Down, Checked: Boolean;
  R, IconR, TextR: TRect;
  It: TPPGToolItem;
  S: TPPGSurfaceStyle;
  TextCol, C: TColor;
  UseColors, OwnFill: Boolean;
  F, Temp: TFont;
begin
  EnsureLayout;
  PPI := ScalePPI;
  T := Tokens;
  A := EffectiveAppearance;
  HC := HighContrastSupport and PPGIsHighContrast;
  if HC then
    TextCol := PPGColorToRGB(clBtnText)
  else if UseVclStyle then
    TextCol := PPGColorToRGB(A.Normal.TextColor)
  else
    TextCol := T.TextPrimary;
  for I := 0 to FItems.Count - 1 do
  begin
    It := FItems[I];
    R := FRects[I];
    if IsRectEmpty(R) then
      Continue;
    if It.Style = tisSeparator then
    begin
      X := (R.Left + R.Right) div 2;
      ACanvas.FillRoundRect(Rect(X, R.Top + PPGScale(6, PPI), X + 1, R.Bottom - PPGScale(6, PPI)), 0,
        PPGBlendColor(PPGColorToRGB(GetBackgroundColor), TextCol, 0.25), 255);
      Continue;
    end;
    Hot := Enabled and It.Enabled and (FHotPart = I);
    Down := Hot and (FDownPart = I);
    Checked := (It.Style = tisCheck) and It.Down;
    // Eigene Flaeche des Eintrags (auch in Ruhe); Hover/Druck dann als Abdunkelung
    UseColors := not HC and not UseVclStyle;
    OwnFill := UseColors and (It.Color <> clDefault) and (It.Color <> clNone);
    if OwnFill then
    begin
      Rad := PPGScale(6, PPI);
      ACanvas.FillRoundRect(R, Rad, PPGColorToRGB(It.Color), 255);
      if Down or Checked then
        ACanvas.FillRoundRect(R, Rad, TextCol, 36)
      else if Hot then
        ACanvas.FillRoundRect(R, Rad, TextCol, 18);
      C := TextCol;
    end
    // In Ruhe flach; Hover/Druck/eingerastet in der Optik des Presets
    else if Hot or Down or Checked then
    begin
      if not (Enabled and It.Enabled) then
        S := A.Resolve(vsDisabled, PPI, False)
      else if Down then
        S := A.Resolve(vsDown, PPI, False)
      else if Checked and not Hot then
        S := A.Resolve(vsDown, PPI, False)
      else
        S := A.Resolve(vsHot, PPI, False);
      S.GlowAlpha := 0;
      Rad := Min(S.Rounding, PPGScale(6, PPI));
      S.Rounding := Rad;
      Renderer.DrawSurface(ACanvas, R, S);
      C := S.TextColor;
      if Checked and not HC then
        ACanvas.FillRoundRect(Rect(R.Left + (R.Right - R.Left) div 2 - PPGScale(8, PPI),
          R.Bottom - PPGScale(3, PPI), R.Left + (R.Right - R.Left) div 2 + PPGScale(8, PPI),
          R.Bottom - PPGScale(1, PPI)), PPGScale(1, PPI), IfThen(Enabled and It.Enabled,
          PPGColorToRGB(A.FocusColor), PPGBlendColor(PPGColorToRGB(A.FocusColor), TextCol, 0.5)), 255);
    end
    else
      C := TextCol;
    if UseColors and (It.TextColor <> clDefault) and (It.TextColor <> clNone) then
      C := PPGColorToRGB(It.TextColor);
    if not (Enabled and It.Enabled) then
      if HC then
        C := PPGColorToRGB(clGrayText)
      else
        C := T.TextDisabled;
    HasIcon := (It.IconChar <> 0) or ((Images <> nil) and (It.ImageIndex >= 0));
    TextR := Rect(R.Left + PPGScale(BtnPadH, PPI), R.Top, R.Right - PPGScale(BtnPadH, PPI), R.Bottom);
    if HasIcon then
    begin
      if (FShowCaptions and (It.Caption <> '')) then
      begin
        if UseRightToLeftAlignment then
        begin
          IconR := Rect(TextR.Right - PPGScale(IconSz, PPI), R.Top, TextR.Right, R.Bottom);
          TextR.Right := IconR.Left - PPGScale(8, PPI);
        end
        else
        begin
          IconR := Rect(TextR.Left, R.Top, TextR.Left + PPGScale(IconSz, PPI), R.Bottom);
          TextR.Left := IconR.Right + PPGScale(8, PPI);
        end;
      end
      else
        IconR := R;
      if (Images <> nil) and (It.ImageIndex >= 0) and (It.ImageIndex < Images.Count) then
        DrawItemImage(ACanvas, It.ImageIndex, (IconR.Left + IconR.Right - Images.Width) div 2,
          (IconR.Top + IconR.Bottom - Images.Height) div 2, Enabled and It.Enabled, C)
      else if not PPGDrawIconChar(ACanvas, IconR, It.IconChar, C, PPGScale(IconSz, PPI)) then
        ACanvas.DrawText(IconR, Copy(StripHotkey(It.Caption), 1, 1), Font, C,
          DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
    end;
    if (FShowCaptions or not HasIcon) and (It.Caption <> '') then
    begin
      Temp := nil;
      try
        F := PPGStyledFont(Font, It.FontStyle, Temp);
        ACanvas.DrawText(TextR, StripHotkey(It.Caption), F, C,
          DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS or
          IfThen(HasIcon, 0, DT_CENTER)));
      finally
        Temp.Free;
      end;
    end;
    if FocusVisible and Focused and (FFocusPart = I) then
      ACanvas.FrameRoundRect(R, PPGScale(4, PPI), PPGScale(2, PPI), PPGColorToRGB(A.FocusColor), 255);
  end;
  if FOverflow then
  begin
    R := FOverflowRect;
    if Enabled and (FHotPart = -2) then
      ACanvas.FillRoundRect(R, PPGScale(4, PPI), TextCol, IfThen(FDownPart = -2, 24, 14));
    if not PPGDrawIcon(ACanvas, R, igMore, TextCol, PPGScale(IconSz, PPI)) then
      ACanvas.DrawText(R, '...', Font, TextCol, DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
    if FocusVisible and Focused and (FFocusPart = -2) then
      ACanvas.FrameRoundRect(R, PPGScale(4, PPI), PPGScale(2, PPI), PPGColorToRGB(A.FocusColor), 255);
  end;
end;

{ ---- Maus und Tastatur ---- }

procedure TPPGToolBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FDownPart := PartAt(X, Y);
    Invalidate;
  end;
end;

procedure TPPGToolBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  P := PartAt(X, Y);
  if P <> FHotPart then
  begin
    FHotPart := P;
    Invalidate;
    Application.CancelHint;
  end;
end;

procedure TPPGToolBar.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P, D: Integer;
begin
  D := FDownPart;
  FDownPart := -1;
  Invalidate;
  inherited MouseUp(Button, Shift, X, Y);
  if (Button <> mbLeft) or not Enabled then
    Exit;
  P := PartAt(X, Y);
  if (P <> D) or (P = -1) then
    Exit;
  if P = -2 then
    ShowOverflowMenu
  else
    ClickItem(FItems[P]);
end;

procedure TPPGToolBar.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHotPart <> -1 then
  begin
    FHotPart := -1;
    Invalidate;
  end;
end;

procedure TPPGToolBar.CMHintShow(var Message: TCMHintShow);
var
  It: TPPGToolItem;
begin
  inherited;
  if FHotPart = -2 then
  begin
    Message.HintInfo^.HintStr := PPGStr(@SPPGMoreOptions);
    Message.HintInfo^.CursorRect := FOverflowRect;
    Exit;
  end;
  if (FHotPart < 0) or (FHotPart >= FItems.Count) then
    Exit;
  It := FItems[FHotPart];
  if It.Hint <> '' then
    Message.HintInfo^.HintStr := GetShortHint(It.Hint)
  else if not FShowCaptions then
    Message.HintInfo^.HintStr := StripHotkey(It.Caption)
  else
    Message.Result := 1;
  Message.HintInfo^.CursorRect := FRects[FHotPart];
end;

procedure TPPGToolBar.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

function TPPGToolBar.NextFocusable(From, Dir: Integer): Integer;
var
  I: Integer;
begin
  EnsureLayout;
  I := From + Dir;
  while (I >= 0) and (I < FItems.Count) do
  begin
    if not IsRectEmpty(FRects[I]) and (FItems[I].Style <> tisSeparator) and FItems[I].Enabled then
      Exit(I);
    Inc(I, Dir);
  end;
  if (Dir > 0) and FOverflow then
    Result := -2
  else
    Result := -1;
end;

procedure TPPGToolBar.KeyDown(var Key: Word; Shift: TShiftState);
var
  K: Word;
  N: Integer;
begin
  inherited KeyDown(Key, Shift);
  if not Enabled then
    Exit;
  K := Key;
  if UseRightToLeftAlignment then
    if K = VK_LEFT then
      K := VK_RIGHT
    else if K = VK_RIGHT then
      K := VK_LEFT;
  N := -3;
  case K of
    VK_RIGHT:
      if FFocusPart <> -2 then
        N := NextFocusable(FFocusPart, 1);
    VK_LEFT:
      if FFocusPart = -2 then
        N := NextFocusable(FItems.Count, -1)
      else
        N := NextFocusable(FFocusPart, -1);
    VK_HOME: N := NextFocusable(-1, 1);
    VK_END:
      if FOverflow then
        N := -2
      else
        N := NextFocusable(FItems.Count, -1);
    VK_RETURN, VK_SPACE:
      begin
        if FFocusPart = -2 then
          ShowOverflowMenu
        else if (FFocusPart >= 0) and (FFocusPart < FItems.Count) then
          ClickItem(FItems[FFocusPart]);
        Key := 0;
        Exit;
      end;
  else
    Exit;
  end;
  if N <> -3 then
  begin
    if N <> -1 then
      FFocusPart := N;
    Invalidate;
    if FFocusPart = -2 then
      NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, FItems.Count + 1)
    else if FFocusPart >= 0 then
      NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, FFocusPart + 1);
  end;
  Key := 0;
end;

procedure TPPGToolBar.DoEnter;
begin
  inherited DoEnter;
  if (FFocusPart = -1) or ((FFocusPart >= 0) and IsRectEmpty(ItemRect(FFocusPart))) then
    FFocusPart := NextFocusable(-1, 1);
  Invalidate;
end;

procedure TPPGToolBar.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

{ ---- Barrierefreiheit: Kinder 1..Count = Items, Count+1 = Ueberlauf ---- }

procedure TPPGToolBar.WndProc(var Message: TMessage);
var
  Id: Integer;
begin
  if (GMsgToolAction <> 0) and (Message.Msg = GMsgToolAction) then
  begin
    // LParam: Kennung (ID) des Items bzw. -1 fuer den Ueberlauf. Inzwischen
    // geaenderte Leiste: nur das gemeinte Item ausloesen.
    Id := Integer(Message.WParam);
    if Integer(Message.LParam) = -1 then
    begin
      if Id = FItems.Count + 1 then
        ShowOverflowMenu;
    end
    else
      ClickItem(TPPGToolItem(FItems.FindItemID(Integer(Message.LParam))));
    Exit;
  end;
  inherited WndProc(Message);
end;

function TPPGToolBar.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_TOOLBAR;
end;

function TPPGToolBar.AccChildCount: Integer;
begin
  EnsureLayout;
  Result := FItems.Count + Ord(FOverflow);
end;

function TPPGToolBar.AccChildName(Id: Integer): string;
begin
  if Id = FItems.Count + 1 then
    Result := PPGStr(@SPPGMoreOptions)
  else if (Id >= 1) and (Id <= FItems.Count) then
  begin
    Result := StripHotkey(FItems[Id - 1].Caption);
    if Result = '' then
      Result := GetShortHint(FItems[Id - 1].Hint);
  end
  else
    Result := '';
end;

function TPPGToolBar.AccChildRole(Id: Integer): Integer;
begin
  if Id = FItems.Count + 1 then
    Exit(ROLE_SYSTEM_BUTTONMENU);
  if (Id < 1) or (Id > FItems.Count) then
    Exit(ROLE_SYSTEM_PUSHBUTTON);
  case FItems[Id - 1].Style of
    tisCheck: Result := ROLE_SYSTEM_CHECKBUTTON;
    tisSeparator: Result := ROLE_SYSTEM_SEPARATOR;
  else
    Result := ROLE_SYSTEM_PUSHBUTTON;
  end;
end;

function TPPGToolBar.AccChildState(Id: Integer): Integer;
var
  It: TPPGToolItem;
begin
  Result := STATE_SYSTEM_FOCUSABLE;
  if Id = FItems.Count + 1 then
    Exit;
  if (Id < 1) or (Id > FItems.Count) then
    Exit(0);
  It := FItems[Id - 1];
  if not It.Visible then
    Exit(STATE_SYSTEM_INVISIBLE);
  if IsInOverflow(Id - 1) then
    Result := Result or STATE_SYSTEM_OFFSCREEN;
  if not It.Enabled then
    Result := STATE_SYSTEM_UNAVAILABLE;
  if (It.Style = tisCheck) and It.Down then
    Result := Result or STATE_SYSTEM_CHECKED or STATE_SYSTEM_PRESSED;
  if Focused and (FFocusPart = Id - 1) then
    Result := Result or STATE_SYSTEM_FOCUSED;
end;

function TPPGToolBar.AccChildRect(Id: Integer): TRect;
begin
  if Id = FItems.Count + 1 then
    Result := OverflowRect
  else
    Result := ItemRect(Id - 1);
end;

function TPPGToolBar.AccChildAt(X, Y: Integer): Integer;
var
  P: Integer;
begin
  P := PartAt(X, Y);
  if P = -2 then
    Result := FItems.Count + 1
  else
    Result := P + 1;
end;

function TPPGToolBar.AccChildDefaultAction(Id: Integer): string;
begin
  if Id = FItems.Count + 1 then
    Result := PPGStr(@SPPGAccOpen)
  else if (Id >= 1) and (Id <= FItems.Count) and (FItems[Id - 1].Style = tisCheck) then
    Result := PPGStr(@SPPGAccToggle)
  else
    Result := PPGStr(@SPPGAccPress);
end;

procedure TPPGToolBar.AccChildDoDefault(Id: Integer);
begin
  if not HandleAllocated then
    Exit;
  if (Id >= 1) and (Id <= FItems.Count) then
    PostMessage(Handle, GMsgToolAction, WPARAM(Id), LPARAM(FItems[Id - 1].ID))
  else if Id = FItems.Count + 1 then
    PostMessage(Handle, GMsgToolAction, WPARAM(Id), LPARAM(-1));
end;

function TPPGToolBar.AccFocusedChild: Integer;
begin
  if not Focused then
    Result := 0
  else if FFocusPart = -2 then
    Result := FItems.Count + 1
  else
    Result := FFocusPart + 1;
end;

function TPPGToolBar.AccSelectedChild: Integer;
begin
  Result := 0;
end;

end.
