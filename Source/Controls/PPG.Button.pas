unit PPG.Button;

{ TPPGButton - Glow-Button mit Bild, ModalResult, Default/Cancel,
  Toggle-Gruppen (GroupIndex/Down), DropDownMenu und Action-Unterstuetzung.

  Stolpersteine:
  - CS_DBLCLKS wird entfernt: sonst wird bei schnellem Doppelklick der zweite
    Klick als DblClick geliefert und "verschluckt".
  - Default/Cancel folgen exakt der Logik von TButton (CM_FOCUSCHANGED /
    CM_DIALOGKEY), damit gemischte Formulare konsistent reagieren.
  - GroupIndex wird vor Down gestreamt (Deklarationsreihenfolge!).
  - Gruppen-Benachrichtigung nutzt eine EIGENE registrierte Nachricht statt
    CM_BUTTONPRESSED: TSpeedButton castet LParam von CM_BUTTONPRESSED blind
    auf TSpeedButton und wuerde bei gleichem GroupIndex unseren Speicher
    als TSpeedButton lesen/schreiben.
  - Split-Button: Das Menue oeffnet beim Druecken auf den Pfeil (wie Windows).
    csClicked wird dabei entfernt, damit beim Loslassen KEIN OnClick folgt. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Forms, Vcl.Menus, Vcl.ActnList, Vcl.ImgList,
  PPG.Types, PPG.Layout, PPG.Render.Intf, PPG.Controls.Base;

type
  TPPGCustomButton = class;

  /// pbsPushButton: normaler Button (mit DropDownMenu: Klick + Menue)
  /// pbsSplitButton: eigener Pfeilbereich; Klick auf den Koerper = OnClick,
  /// Pfeil (oder Alt+Pfeil runter / F4) = OnDropDownClick + DropDownMenu
  TPPGButtonStyle = (pbsPushButton, pbsSplitButton);

  TPPGButtonActionLink = class(TWinControlActionLink)
  protected
    FClient: TPPGCustomButton;
    procedure AssignClient(AClient: TObject); override;
    function IsCheckedLinked: Boolean; override;
    function IsImageIndexLinked: Boolean; override;
    procedure SetChecked(Value: Boolean); override;
    procedure SetImageIndex(Value: Integer); override;
  end;

  TPPGCustomButton = class(TPPGCustomControl)
  private
    FModalResult: TModalResult;
    FDefault: Boolean;
    FCancel: Boolean;
    FActive: Boolean;
    FDropDownMenu: TPopupMenu;
    FGroupIndex: Integer;
    FDown: Boolean;
    FAllowAllUp: Boolean;
    FStyle: TPPGButtonStyle;
    FDropDownOpen: Boolean;
    FOnDropDownClick: TNotifyEvent;
    FAlignment: TAlignment;
    FMargin: Integer;
    procedure SetAlignment(const Value: TAlignment);
    procedure SetMargin(const Value: Integer);
    procedure SetStyle(const Value: TPPGButtonStyle);
    procedure SetDefault(const Value: Boolean);
    procedure SetDropDownMenu(const Value: TPopupMenu);
    procedure SetGroupIndex(const Value: Integer);
    procedure SetDown(const Value: Boolean);
    procedure SetAllowAllUp(const Value: Boolean);
    procedure UpdateExclusive;
    function IsImageIndexStored: Boolean;
    function IsDownStored: Boolean;
    procedure CMDialogKey(var Message: TCMDialogKey); message CM_DIALOGKEY;
    procedure CMFocusChanged(var Message: TCMFocusChanged); message CM_FOCUSCHANGED;
    procedure PPGButtonPressed(var Message: TMessage);
  protected
    procedure WndProc(var Message: TMessage); override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function IsDown: Boolean; override;
    function GetActionLinkClass: TControlActionLinkClass; override;
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean); override;
    procedure ShowDropDownMenu; virtual;
    /// Pfeil betaetigt: OnDropDownClick, dann DropDownMenu.
    procedure DoDropDownClick; virtual;
    function HasArrow: Boolean;
    function ArrowRect(const Body: TRect): TRect;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function GetContentRect(const Body: TRect; const Style: TPPGSurfaceStyle): TRect; override;
    procedure DoPaintContent(const ACanvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle); override;
    function AutoSizeExtraWidth: Integer; override;
    function GetCaptionAlignment: TPPGHorzAlign; override;
    function AccRole: Integer; override;
    function AccState: Integer; override;

    property ModalResult: TModalResult read FModalResult write FModalResult default 0;
    property Default: Boolean read FDefault write SetDefault default False;
    property Cancel: Boolean read FCancel write FCancel default False;
    property Style: TPPGButtonStyle read FStyle write SetStyle default pbsPushButton;
    property DropDownMenu: TPopupMenu read FDropDownMenu write SetDropDownMenu;
    property OnDropDownClick: TNotifyEvent read FOnDropDownClick write FOnDropDownClick;
    property GroupIndex: Integer read FGroupIndex write SetGroupIndex default 0;
    property Down: Boolean read FDown write SetDown stored IsDownStored;
    property AllowAllUp: Boolean read FAllowAllUp write SetAllowAllUp default False;
    property ImageIndex stored IsImageIndexStored;
    /// Lage von Bild und Text im Button (taCenter wie TButton).
    property Alignment: TAlignment read FAlignment write SetAlignment default taCenter;
    /// Wie TBitBtn.Margin: Abstand von Bild/Text zum Rand in logischen px
    /// (-1 = nach Alignment ausgerichtet ohne festen Abstand).
    property Margin: Integer read FMargin write SetMargin default -1;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Click; override;
    /// True, wenn Enter diesen Button ausloest (fokussiert oder Default).
    property Active: Boolean read FActive;
  end;

  TPPGButton = class(TPPGCustomButton)
  published
    { PPGlow - Reihenfolge ist Streaming-Reihenfolge: Preset VOR Appearance,
      GroupIndex VOR Down }
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Images;
    property ImageIndex;
    {$IFDEF PPG_HAS_IMAGENAME}
    property ImageName;
    {$ENDIF}
    property HotImageIndex;
    property DisabledImageIndex;
    property PressedImageIndex;
    {$IFDEF PPG_HAS_IMAGENAME}
    property HotImageName;
    property DisabledImageName;
    property PressedImageName;
    {$ENDIF}
    property ImageTint;
    property ImagePosition;
    property Spacing;
    property Alignment;
    property Margin;
    property RoundedCorners;
    property Shadow;
    property WordWrap;
    property ShowFocusRect;
    property HighContrastSupport;
    property ModalResult;
    property Default;
    property Cancel;
    property Style;
    property DropDownMenu;
    property OnDropDownClick;
    property GroupIndex;
    property AllowAllUp;
    property Down;
    { VCL-Standard }
    property Action;
    property Align;
    property Anchors;
    property AutoSize;
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
    property OnClick;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
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
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

uses
  System.SysUtils, Vcl.StdCtrls, Winapi.oleacc, PPG.Exceptions, PPG.Appearance;

var
  GMsgButtonPressed: Cardinal = 0;

{ TPPGButtonActionLink }

procedure TPPGButtonActionLink.AssignClient(AClient: TObject);
begin
  inherited AssignClient(AClient);
  FClient := AClient as TPPGCustomButton;
end;

function TPPGButtonActionLink.IsCheckedLinked: Boolean;
begin
  Result := inherited IsCheckedLinked and (FClient.GroupIndex <> 0) and
    (FClient.Down = (Action as TCustomAction).Checked);
end;

function TPPGButtonActionLink.IsImageIndexLinked: Boolean;
begin
  Result := inherited IsImageIndexLinked and
    (FClient.ImageIndex = (Action as TCustomAction).ImageIndex);
end;

procedure TPPGButtonActionLink.SetChecked(Value: Boolean);
begin
  if IsCheckedLinked then
    FClient.Down := Value;
end;

procedure TPPGButtonActionLink.SetImageIndex(Value: Integer);
begin
  if IsImageIndexLinked then
    FClient.ImageIndex := Value;
end;

{ TPPGCustomButton }

procedure TPPGCustomButton.WndProc(var Message: TMessage);
begin
  if (GMsgButtonPressed <> 0) and (Message.Msg = GMsgButtonPressed) then
    PPGButtonPressed(Message)
  else
    inherited WndProc(Message);
end;

constructor TPPGCustomButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlignment := taCenter;
  FMargin := -1;
  ControlStyle := ControlStyle - [csDoubleClicks];
  TabStop := True;
  Width := 100;
  Height := 32;
end;

procedure TPPGCustomButton.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WindowClass.style := Params.WindowClass.style and not CS_DBLCLKS;
end;

procedure TPPGCustomButton.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FDropDownMenu) then
  begin
    FDropDownMenu := nil;
    RequestAutoSize; // Pfeil entfaellt
    Invalidate;
  end;
end;

function TPPGCustomButton.IsDown: Boolean;
begin
  Result := inherited IsDown or ((FGroupIndex <> 0) and FDown);
end;

procedure TPPGCustomButton.Click;
var
  Form: TCustomForm;
begin
  // Interne Zustandsaenderungen VOR dem Anwender-Code: wirft OnClick eine
  // Exception, ist der Button trotzdem in einem konsistenten Zustand.
  if FGroupIndex <> 0 then
  begin
    if FDown then
    begin
      if FAllowAllUp then
        SetDown(False);
    end
    else
      SetDown(True);
  end;
  Form := GetParentForm(Self);
  if (Form <> nil) and (FModalResult <> mrNone) then
    Form.ModalResult := FModalResult;
  inherited Click; // OnClick bzw. Action.Execute
  // Beim Split-Button oeffnet nur der Pfeil das Menue
  if (FDropDownMenu <> nil) and (FStyle = pbsPushButton) then
    ShowDropDownMenu;
end;

function TPPGCustomButton.AccRole: Integer;
begin
  if FStyle = pbsSplitButton then
    Result := ROLE_SYSTEM_SPLITBUTTON
  else if FDropDownMenu <> nil then
    Result := ROLE_SYSTEM_BUTTONMENU
  else
    Result := ROLE_SYSTEM_PUSHBUTTON;
end;

function TPPGCustomButton.AccState: Integer;
begin
  Result := inherited AccState;
  if (FDropDownMenu <> nil) or (FStyle = pbsSplitButton) then
    Result := Result or STATE_SYSTEM_HASPOPUP;
  if (FGroupIndex <> 0) and FDown then
    Result := Result or STATE_SYSTEM_PRESSED;
end;

{ ---- Split-Button / Pfeil ---- }

const
  ArrowAreaWidth = 18; // logische px

function TPPGCustomButton.HasArrow: Boolean;
begin
  Result := (FStyle = pbsSplitButton) or (FDropDownMenu <> nil);
end;

function TPPGCustomButton.ArrowRect(const Body: TRect): TRect;
var
  W: Integer;
begin
  Result := Body;
  if not HasArrow then
  begin
    Result.Left := Result.Right; // leer
    Exit;
  end;
  W := PPGScale(ArrowAreaWidth, ScalePPI);
  if UseRightToLeftAlignment then
    Result.Right := Result.Left + W
  else
    Result.Left := Result.Right - W;
end;

function TPPGCustomButton.GetCaptionAlignment: TPPGHorzAlign;
var
  A: TAlignment;
begin
  A := FAlignment;
  // Margin ohne eigene Ausrichtung: wie TBitBtn links (RTL rechts)
  if (FMargin >= 0) and (A = taCenter) then
    A := taLeftJustify;
  if UseRightToLeftAlignment then
    case A of
      taLeftJustify: A := taRightJustify;
      taRightJustify: A := taLeftJustify;
    end;
  case A of
    taLeftJustify: Result := haLeft;
    taRightJustify: Result := haRight;
  else
    Result := haCenter;
  end;
end;

procedure TPPGCustomButton.SetAlignment(const Value: TAlignment);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomButton.SetMargin(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'Margin', Value, -1, 1000);
  if FMargin <> V then
  begin
    FMargin := V;
    Invalidate;
  end;
end;

function TPPGCustomButton.AutoSizeExtraWidth: Integer;
begin
  if HasArrow then
    Result := PPGScale(ArrowAreaWidth, ScalePPI)
  else
    Result := 0;
end;

procedure TPPGCustomButton.SetStyle(const Value: TPPGButtonStyle);
begin
  if FStyle <> Value then
  begin
    FStyle := Value;
    RequestAutoSize;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
  end;
end;

function TPPGCustomButton.GetContentRect(const Body: TRect;
  const Style: TPPGSurfaceStyle): TRect;
var
  AR: TRect;
  M: Integer;
begin
  Result := inherited GetContentRect(Body, Style);
  // Margin: fester Abstand zum Rand auf der Seite der Ausrichtung
  if FMargin >= 0 then
  begin
    M := Body.Left + Style.BorderWidth + PPGScale(FMargin, ScalePPI);
    if GetCaptionAlignment = haRight then
      Result.Right := Body.Right - Style.BorderWidth - PPGScale(FMargin, ScalePPI)
    else
      Result.Left := M;
  end;
  if not HasArrow then
    Exit;
  // Text/Bild nicht unter den Pfeil legen
  AR := ArrowRect(Body);
  if UseRightToLeftAlignment then
  begin
    if Result.Left < AR.Right then
      Result.Left := AR.Right;
  end
  else if Result.Right > AR.Left then
    Result.Right := AR.Left;
end;

procedure TPPGCustomButton.DoPaintContent(const ACanvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle);
var
  AR: TRect;
  PPI, CX, CY, S, X, Inset: Integer;
  Pressed: TPPGSurfaceStyle;
begin
  inherited DoPaintContent(ACanvas, Body, Style);
  if not HasArrow then
    Exit;
  PPI := ScalePPI;
  AR := ArrowRect(Body);
  if FStyle = pbsSplitButton then
  begin
    if FDropDownOpen then
    begin
      // Pfeilbereich gedrueckt darstellen, solange das Menue offen ist
      Pressed := EffectiveAppearance.Resolve(vsDown, PPI, False);
      ACanvas.PushClipRoundRect(Body, Style.Rounding);
      try
        ACanvas.FillRoundRect(AR, 0, Pressed.Color, 170);
      finally
        ACanvas.PopClip;
      end;
    end;
    // Trennlinie zwischen Koerper und Pfeil
    if UseRightToLeftAlignment then
      X := AR.Right
    else
      X := AR.Left;
    Inset := PPGScale(6, PPI);
    ACanvas.DrawPolyline([Point(X, Body.Top + Inset), Point(X, Body.Bottom - Inset)],
      1, Style.BorderColor, 170);
  end;
  // Chevron
  CX := (AR.Left + AR.Right) div 2;
  CY := (AR.Top + AR.Bottom) div 2;
  S := PPGScale(4, PPI);
  ACanvas.DrawPolyline([Point(CX - S, CY - S div 2), Point(CX, CY + S div 2),
    Point(CX + S, CY - S div 2)], PPGScale(2, PPI), Style.TextColor, 255);
end;

procedure TPPGCustomButton.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  InArrow: Boolean;
begin
  InArrow := (Button = mbLeft) and Enabled and (FStyle = pbsSplitButton) and
    PtInRect(ArrowRect(LayoutBodyRect), Point(X, Y));
  inherited MouseDown(Button, Shift, X, Y); // OnMouseDown, Fokus
  if InArrow then
  begin
    // Kein Click beim Loslassen, kein haengender Druckzustand nach dem Menue
    ControlState := ControlState - [csClicked];
    MouseCapture := False;
    ResetInteractionState;
    DoDropDownClick;
  end;
end;

procedure TPPGCustomButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  // Windows-Konvention fuer Split-/Menue-Buttons: Alt+Pfeil runter oder F4
  if HasArrow and Enabled and
    (((Key = VK_DOWN) and (Shift = [ssAlt])) or ((Key = VK_F4) and (Shift = []))) then
  begin
    Key := 0;
    DoDropDownClick;
    Exit;
  end;
  inherited KeyDown(Key, Shift);
end;

procedure TPPGCustomButton.DoDropDownClick;
begin
  FDropDownOpen := True;
  Invalidate;
  try
    if Assigned(FOnDropDownClick) then
      FOnDropDownClick(Self);
    if FDropDownMenu <> nil then
      ShowDropDownMenu; // modal bis das Menue geschlossen ist
  finally
    FDropDownOpen := False;
    Invalidate;
  end;
end;

procedure TPPGCustomButton.ShowDropDownMenu;
var
  P: TPoint;
begin
  if (FDropDownMenu = nil) or not HandleAllocated then
    Exit;
  if UseRightToLeftAlignment then
    P := ClientToScreen(Point(Width, Height))
  else
    P := ClientToScreen(Point(0, Height));
  FDropDownMenu.PopupComponent := Self;
  FDropDownMenu.Popup(P.X, P.Y);
end;

procedure TPPGCustomButton.CMDialogKey(var Message: TCMDialogKey);
begin
  if (((Message.CharCode = VK_RETURN) and FActive) or
      ((Message.CharCode = VK_ESCAPE) and FCancel)) and
    (KeyDataToShiftState(Message.KeyData) = []) and CanFocus then
  begin
    Click;
    Message.Result := 1;
  end
  else
    inherited;
end;

procedure TPPGCustomButton.CMFocusChanged(var Message: TCMFocusChanged);
var
  NewActive: Boolean;
begin
  // Wie TButton: fokussierter Button ist aktiv; sonst der Default-Button,
  // sofern der Fokus nicht auf einem anderen Button liegt.
  if Message.Sender = Self then
    NewActive := True
  else
    NewActive := FDefault and not ((Message.Sender is TPPGCustomButton) or
      (Message.Sender is TCustomButton));
  if NewActive <> FActive then
  begin
    FActive := NewActive;
    Invalidate;
  end;
  inherited;
end;

procedure TPPGCustomButton.PPGButtonPressed(var Message: TMessage);
var
  Sender: TPPGCustomButton;
begin
  // Exklusive Gruppe: anderer Button der Gruppe wurde gedrueckt
  if (Message.WParam = WPARAM(FGroupIndex)) and (FGroupIndex <> 0) then
  begin
    Sender := TPPGCustomButton(Message.LParam);
    if (Sender <> Self) and FDown then
    begin
      FDown := False;
      UpdateVisualState(False);
      NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
    end;
  end;
end;

procedure TPPGCustomButton.UpdateExclusive;
var
  Msg: TMessage;
begin
  if (FGroupIndex <> 0) and (Parent <> nil) then
  begin
    Msg.Msg := GMsgButtonPressed;
    Msg.WParam := WPARAM(FGroupIndex);
    Msg.LParam := LPARAM(Self);
    Msg.Result := 0;
    Parent.Broadcast(Msg);
  end;
end;

procedure TPPGCustomButton.SetDefault(const Value: Boolean);
var
  Form: TCustomForm;
begin
  if FDefault = Value then
    Exit;
  FDefault := Value;
  if HandleAllocated then
  begin
    Form := GetParentForm(Self);
    if Form <> nil then
      Form.Perform(CM_FOCUSCHANGED, 0, LPARAM(Form.ActiveControl));
  end;
end;

procedure TPPGCustomButton.SetDropDownMenu(const Value: TPopupMenu);
begin
  if FDropDownMenu = Value then
    Exit;
  // Abmelden nur, wenn das Menue nicht zugleich PopupMenu ist: Die
  // Benachrichtigung gilt fuer beide Referenzen (TControl.FPopupMenu)
  if (FDropDownMenu <> nil) and (FDropDownMenu <> PopupMenu) then
    FDropDownMenu.RemoveFreeNotification(Self);
  FDropDownMenu := Value;
  if FDropDownMenu <> nil then
    FDropDownMenu.FreeNotification(Self);
  RequestAutoSize;
  Invalidate;
end;

procedure TPPGCustomButton.SetGroupIndex(const Value: Integer);
begin
  if FGroupIndex <> Value then
  begin
    FGroupIndex := Value;
    if FGroupIndex = 0 then
      FDown := False
    else if FDown then
      UpdateExclusive;
    UpdateVisualState(False);
  end;
end;

procedure TPPGCustomButton.SetDown(const Value: Boolean);
var
  V: Boolean;
begin
  V := Value;
  // Ohne Gruppe gibt es keinen dauerhaften Down-Zustand (wie TSpeedButton).
  // Beim Laden nicht korrigieren: GroupIndex kann noch fehlen.
  if (FGroupIndex = 0) and not (csLoading in ComponentState) then
    V := False;
  if V = FDown then
    Exit;
  // Letzten gedrueckten Button der Gruppe nicht loesen, wenn AllowAllUp=False
  if FDown and not V and not FAllowAllUp and (FGroupIndex <> 0) and
    not (csLoading in ComponentState) then
    Exit;
  FDown := V;
  if V then
    UpdateExclusive;
  UpdateVisualState(False);
  NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
end;

procedure TPPGCustomButton.SetAllowAllUp(const Value: Boolean);
begin
  FAllowAllUp := Value;
end;

function TPPGCustomButton.IsDownStored: Boolean;
begin
  Result := FDown and ((ActionLink = nil) or
    not TPPGButtonActionLink(ActionLink).IsCheckedLinked);
end;

function TPPGCustomButton.IsImageIndexStored: Boolean;
begin
  Result := IsImageIndexStoredByName and ((ActionLink = nil) or
    not TPPGButtonActionLink(ActionLink).IsImageIndexLinked);
end;

function TPPGCustomButton.GetActionLinkClass: TControlActionLinkClass;
begin
  Result := TPPGButtonActionLink;
end;

procedure TPPGCustomButton.ActionChange(Sender: TObject; CheckDefaults: Boolean);
begin
  inherited ActionChange(Sender, CheckDefaults);
  if Sender is TCustomAction then
  begin
    if not CheckDefaults or (ImageIndex = -1) then
      ImageIndex := TCustomAction(Sender).ImageIndex;
    if (FGroupIndex <> 0) and (not CheckDefaults or not FDown) then
      Down := TCustomAction(Sender).Checked;
  end;
end;

initialization
  GMsgButtonPressed := RegisterWindowMessage('PPGlow.ButtonPressed');

end.
