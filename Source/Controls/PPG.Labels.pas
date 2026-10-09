unit PPG.Labels;

{ TPPGLabel und TPPGLinkLabel (Phase 7a).

  TPPGLabel - grafisches Control wie TLabel (kein Fensterhandle), DFM-kompatibel:
  - Textfarbe folgt dem Dark Mode (TPPGTheme): die Standardfarben
    (clWindowText/clBtnText/clBlack) werden im Dunkeln zu TextPrimary,
    deaktiviert zu TextDisabled. Eigene Farben bleiben.
  - Secondary = dezente Farbe (TextSecondary), z.B. fuer Hinweise.
  - AllowMarkup: Mini-Markup (fett, kursiv, Farbe, Bilder); Links sind hier
    nur Darstellung - klickbare Links bietet TPPGLinkLabel.
  - Bei aktivem VCL-Style zeichnet die VCL wie bei TLabel (Style-Farben).

  TPPGLinkLabel - Fenster-Control mit Fokus fuer Text mit Links (wie TLinkLabel):
  - Links per Markup (<a href="...">Text</a>), Hand-Cursor und Hover-Flaeche.
  - Tastatur: Pfeile wechseln den Link, Enter/Leertaste loest ihn aus.
  - OnLinkClick(Sender, Link, LinkType) wie TLinkLabel.
  - Screenreader: jeder Link ist ein Kind mit Rolle Link. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.ExtCtrls,
  PPG.Types, PPG.Render.Intf, PPG.Markup, PPG.Accessibility, PPG.Controls.Base;

type
  TPPGLabel = class(TCustomLabel)
  private
    FAllowMarkup: Boolean;
    FSecondary: Boolean;
    FMarkup: TPPGMarkupLayout;
    procedure SetAllowMarkup(const Value: Boolean);
    procedure SetSecondary(const Value: Boolean);
  protected
    procedure WndProc(var Message: TMessage); override;
    procedure DoDrawText(var Rect: TRect; Flags: Longint); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Tatsaechliche Textfarbe (Dark Mode, deaktiviert, Secondary).
    function TextColor: TColor;
    /// Farbe der Links im Markup (Link-Token; Hochkontrast/VCL-Style: clHotLight).
    function LinkColor: TColor;
  published
    property AllowMarkup: Boolean read FAllowMarkup write SetAllowMarkup default False;
    property Secondary: Boolean read FSecondary write SetSecondary default False;
    { wie TLabel }
    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BiDiMode;
    property Caption;
    property Color nodefault;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property EllipsisPosition;
    property Enabled;
    property FocusControl;
    property Font;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowAccelChar;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property Transparent;
    property Layout;
    property Visible;
    property Touch;
    property OnGesture;
    property WordWrap;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnStartDock;
    property OnStartDrag;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseWheel;
    // Audit 5d: Action wie TLabel
    property Action;
  end;

  TPPGCustomLinkLabel = class(TPPGCustomControl, IPPGAccessibleChildren)
  private
    FMarkup: TPPGMarkupLayout;
    FLayoutValid: Boolean;
    FFocusedLink: Integer;
    FHotLink: Integer;
    FDownLink: Integer;
    FAlignment: TAlignment;
    FOnLinkClick: TSysLinkEvent;
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
    procedure SetAlignment(const Value: TAlignment);
    procedure SetFocusedLink(Value: Integer);
    procedure EnsureLayout;
    function Origin: TPoint;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMEnter(var Message: TCMEnter); message CM_ENTER;
  protected
    procedure WndProc(var Message: TMessage); override;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure Resize; override;
    procedure ImagesChanged; override;
    function CalcAutoSize(out AWidth, AHeight: Integer): Boolean; override;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoLinkClick(Index: Integer); virtual;
    function TextColor: TColor;
    /// Link-Token; eigene FocusColor und VCL-Style gewinnen, Hochkontrast clHotLight.
    function LinkColor: TColor;
    function AccRole: Integer; override;
    function AccName: string; override;
    function AccDefaultAction: string; override;
    procedure AccDoDefaultAction; override;
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
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property OnLinkClick: TSysLinkEvent read FOnLinkClick write FOnLinkClick;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function LinkCount: Integer;
    function LinkTarget(Index: Integer): string;
    /// Lage eines Links in Client-Koordinaten.
    function LinkRect(Index: Integer): TRect;
    function LinkAtPos(X, Y: Integer): Integer;
    /// Link mit Tastaturfokus (-1 = keiner).
    property FocusedLink: Integer read FFocusedLink write SetFocusedLink;
    property HotLink: Integer read FHotLink;
  end;

  TPPGLinkLabel = class(TPPGCustomLinkLabel)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Images;
    property HighContrastSupport;
    { wie TLinkLabel }
    property Align;
    property Alignment;
    property Anchors;
    property AutoSize default True;
    property BiDiMode;
    property Caption;
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
    property TabStop default True;
    property Visible;
    property Touch;
    property OnGesture;
    property OnClick;
    property OnContextPopup;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnLinkClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnDblClick;
    property OnMouseWheel;
    property OnMouseActivate;
    property DragMode;
    property DragCursor;
    property OnDragDrop;
    property OnDragOver;
    property OnStartDrag;
    property OnEndDrag;
    property Color;
    property ParentColor;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
    property Action;
  end;

implementation

uses
  PPG.Lang,
  System.SysUtils, Winapi.oleacc, Vcl.Themes, Vcl.Forms,
  PPG.Consts, PPG.Appearance, PPG.Tokens, PPG.DpiUtils, PPG.VclStyles, PPG.Theme,
  PPG.Render.Registry;

var
  GMsgLinkAction: Cardinal = 0;

const
  LinkPadX = 2; // logische px um den Text (Platz fuer den Fokusrahmen)
  LinkPadY = 2;

function IsDefaultTextColor(C: TColor): Boolean;
begin
  Result := (C = clWindowText) or (C = clBtnText) or (C = clBlack) or (C = clCaptionText);
end;

{ TPPGLabel }

constructor TPPGLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMarkup := TPPGMarkupLayout.Create;
  TPPGTheme.AddClient(Self);
end;

destructor TPPGLabel.Destroy;
begin
  TPPGTheme.RemoveClient(Self);
  FreeAndNil(FMarkup);
  inherited Destroy;
end;

procedure TPPGLabel.WndProc(var Message: TMessage);
begin
  if (PPGThemeChangedMessage <> 0) and (Message.Msg = PPGThemeChangedMessage) then
  begin
    Invalidate; // Hell/Dunkel gewechselt
    Exit;
  end;
  inherited WndProc(Message);
end;

procedure TPPGLabel.SetAllowMarkup(const Value: Boolean);
begin
  if FAllowMarkup <> Value then
  begin
    FAllowMarkup := Value;
    AdjustBounds;
    Invalidate;
  end;
end;

procedure TPPGLabel.SetSecondary(const Value: Boolean);
begin
  if FSecondary <> Value then
  begin
    FSecondary := Value;
    Invalidate;
  end;
end;

function TPPGLabel.TextColor: TColor;
var
  T: TPPGTokens;
  Dark: Boolean;
begin
  if PPGIsHighContrast then
  begin
    if Enabled then
      Result := clWindowText
    else
      Result := clGrayText;
    Exit;
  end;
  Dark := TPPGTheme.IsDark and not PPGVclStyleActive;
  // Tokens des Standard-Presets (ein Label hat keine eigene Appearance)
  T := PPGPresetTokens('', Dark);
  if not Enabled then
    Result := T.TextDisabled
  else if FSecondary then
    Result := T.TextSecondary
  else if Dark and IsDefaultTextColor(Font.Color) then
    Result := T.TextPrimary
  else
    Result := Font.Color;
end;

function TPPGLabel.LinkColor: TColor;
begin
  if PPGIsHighContrast then
    Result := PPGColorToRGB(clHotLight)
  else if PPGVclStyleActive then
    Result := PPGColorToRGB(StyleServices.GetSystemColor(clHotLight))
  else
    Result := PPGPresetTokens('', TPPGTheme.IsDark).Link;
end;

procedure TPPGLabel.DoDrawText(var Rect: TRect; Flags: Longint);
var
  Text: string;
  C: IPPGCanvas;
  X, W: Integer;
begin
  Text := GetLabelText;
  // Mit VCL-Style ohne Markup: die VCL zeichnet in den Style-Farben
  if PPGVclStyleActive and not (FAllowMarkup and not PPGIsPlainText(Text))
    {$IFDEF PPG_HAS_STYLEELEMENTS} and (seFont in StyleElements) {$ENDIF} then
  begin
    inherited DoDrawText(Rect, Flags);
    Exit;
  end;
  if FAllowMarkup and not PPGIsPlainText(Text) then
  begin
    if WordWrap then
      W := Rect.Right - Rect.Left
    else
      W := 0;
    FMarkup.Layout(Text, Font, nil, W, WordWrap);
    if Flags and DT_CALCRECT <> 0 then
    begin
      Rect.Right := Rect.Left + FMarkup.Size.cx;
      Rect.Bottom := Rect.Top + FMarkup.Size.cy;
      Exit;
    end;
    X := Rect.Left;
    if Flags and DT_RIGHT <> 0 then
      X := Rect.Right - FMarkup.Size.cx
    else if Flags and DT_CENTER <> 0 then
      X := (Rect.Left + Rect.Right - FMarkup.Size.cx) div 2;
    C := TPPGRendererRegistry.CreateCanvas(Canvas.Handle);
    FMarkup.Draw(C, X, Rect.Top, TextColor, LinkColor, Enabled);
    C := nil;
    Exit;
  end;
  if (Flags and DT_CALCRECT <> 0) and ((Text = '') or ShowAccelChar and
    (Text[1] = '&') and (Length(Text) = 1)) then
    Text := Text + ' ';
  if not ShowAccelChar then
    Flags := Flags or DT_NOPREFIX;
  Flags := DrawTextBiDiModeFlags(Flags);
  Canvas.Font := Font;
  Canvas.Font.Color := TextColor;
  Winapi.Windows.DrawText(Canvas.Handle, PChar(Text), Length(Text), Rect, Flags);
end;

{ TPPGCustomLinkLabel }

constructor TPPGCustomLinkLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csClickEvents];
  FMarkup := TPPGMarkupLayout.Create;
  FFocusedLink := -1;
  FHotLink := -1;
  FDownLink := -1;
  TabStop := True;
  Width := 120;
  Height := 20;
  AutoSize := True;
  if GMsgLinkAction = 0 then
    GMsgLinkAction := RegisterWindowMessage('PPGlow.LinkAction');
end;

destructor TPPGCustomLinkLabel.Destroy;
begin
  FreeAndNil(FMarkup);
  inherited Destroy;
end;

procedure TPPGCustomLinkLabel.EnsureLayout;
var
  W: Integer;
begin
  if FLayoutValid then
    Exit;
  FLayoutValid := True;
  if AutoSize then
    W := 0
  else
    W := Width - 2 * PPGScale(LinkPadX, ScalePPI);
  FMarkup.Layout(Caption, Font, Images, W, not AutoSize);
end;

function TPPGCustomLinkLabel.Origin: TPoint;
var
  PX, Free: Integer;
begin
  EnsureLayout;
  PX := PPGScale(LinkPadX, ScalePPI);
  Free := Width - 2 * PX - FMarkup.Size.cx;
  case FAlignment of
    taRightJustify: Result.X := PX + Free;
    taCenter: Result.X := PX + Free div 2;
  else
    Result.X := PX;
  end;
  if UseRightToLeftAlignment and (FAlignment = taLeftJustify) then
    Result.X := PX + Free;
  Result.Y := (Height - FMarkup.Size.cy) div 2;
end;

procedure TPPGCustomLinkLabel.CMTextChanged(var Message: TMessage);
begin
  inherited;
  FLayoutValid := False;
  if FFocusedLink >= LinkCount then
    FFocusedLink := LinkCount - 1;
  RequestAutoSize;
  Invalidate;
end;

procedure TPPGCustomLinkLabel.CMFontChanged(var Message: TMessage);
begin
  inherited;
  FLayoutValid := False;
  RequestAutoSize;
end;

procedure TPPGCustomLinkLabel.Resize;
begin
  inherited Resize;
  if not AutoSize then
    FLayoutValid := False;
end;

procedure TPPGCustomLinkLabel.ImagesChanged;
begin
  inherited ImagesChanged;
  // Bild-Fragmente des Layouts halten die Liste; nach Wechsel oder
  // Freigabe neu aufbauen
  FLayoutValid := False;
  RequestAutoSize;
end;

function TPPGCustomLinkLabel.CalcAutoSize(out AWidth, AHeight: Integer): Boolean;
begin
  FLayoutValid := False;
  FMarkup.Layout(Caption, Font, Images, 0, False);
  FLayoutValid := True;
  AWidth := FMarkup.Size.cx + 2 * PPGScale(LinkPadX, ScalePPI);
  AHeight := FMarkup.Size.cy + 2 * PPGScale(LinkPadY, ScalePPI);
  if AHeight < PPGScale(16, ScalePPI) then
    AHeight := PPGScale(16, ScalePPI);
  Result := True;
end;

procedure TPPGCustomLinkLabel.SetAlignment(const Value: TAlignment);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    Invalidate;
  end;
end;

function TPPGCustomLinkLabel.LinkCount: Integer;
begin
  EnsureLayout;
  Result := FMarkup.LinkCount;
end;

function TPPGCustomLinkLabel.LinkTarget(Index: Integer): string;
begin
  EnsureLayout;
  Result := FMarkup.LinkTarget(Index);
end;

function TPPGCustomLinkLabel.LinkRect(Index: Integer): TRect;
var
  O: TPoint;
begin
  EnsureLayout;
  Result := FMarkup.LinkBounds(Index);
  O := Origin;
  OffsetRect(Result, O.X, O.Y);
end;

function TPPGCustomLinkLabel.LinkAtPos(X, Y: Integer): Integer;
var
  O: TPoint;
begin
  O := Origin;
  Result := FMarkup.LinkIndexAt(X - O.X, Y - O.Y);
end;

procedure TPPGCustomLinkLabel.SetFocusedLink(Value: Integer);
begin
  if Value >= LinkCount then
    Value := LinkCount - 1;
  if Value < -1 then
    Value := -1;
  if FFocusedLink <> Value then
  begin
    FFocusedLink := Value;
    Invalidate;
    if (Value >= 0) and Focused then
      NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, Value + 1);
  end;
end;

function TPPGCustomLinkLabel.IsHot: Boolean;
begin
  Result := False; // Hover gilt dem einzelnen Link, nicht dem Control
end;

function TPPGCustomLinkLabel.IsDown: Boolean;
begin
  Result := False;
end;

function TPPGCustomLinkLabel.TextColor: TColor;
var
  A: TPPGAppearance;
begin
  A := EffectiveAppearance;
  if HighContrastSupport and PPGIsHighContrast then
  begin
    if Enabled then
      Result := PPGColorToRGB(clWindowText)
    else
      Result := PPGColorToRGB(clGrayText);
  end
  else if not Enabled then
    Result := PPGColorToRGB(A.Disabled.TextColor)
  else if UseDarkMode or UseVclStyle then
    Result := PPGColorToRGB(A.Normal.TextColor)
  else
    Result := PPGColorToRGB(Font.Color);
end;

function TPPGCustomLinkLabel.LinkColor: TColor;
var
  T: TPPGTokens;
  F: TColor;
begin
  if HighContrastSupport and PPGIsHighContrast then
    Exit(PPGColorToRGB(clHotLight));
  F := PPGColorToRGB(EffectiveAppearance.FocusColor);
  T := Tokens;
  // VCL-Style und eigene FocusColor bleiben; sonst das Link-Token (4,5:1)
  if UseVclStyle or (F <> T.Accent) then
    Result := F
  else
    Result := T.Link;
end;

procedure TPPGCustomLinkLabel.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  O: TPoint;
  LinkCol: TColor;
  R: TRect;
  PPI: Integer;
begin
  EnsureLayout;
  PPI := ScalePPI;
  O := Origin;
  LinkCol := LinkColor;
  // Hover: dezente Flaeche hinter dem Link
  if (FHotLink >= 0) and Enabled then
  begin
    R := LinkRect(FHotLink);
    InflateRect(R, PPGScale(2, PPI), 0);
    ACanvas.FillRoundRect(R, PPGScale(3, PPI), LinkCol, 28);
  end;
  FMarkup.Draw(ACanvas, O.X, O.Y, TextColor, LinkCol, Enabled);
  if FocusVisible and (FFocusedLink >= 0) then
  begin
    R := LinkRect(FFocusedLink);
    // Nur 1 px nach aussen: sonst beruehrt der Rahmen die Nachbarwoerter
    InflateRect(R, PPGScale(1, PPI), PPGScale(1, PPI));
    ACanvas.FrameRoundRect(R, PPGScale(3, PPI), PPGScale(2, PPI), LinkCol, 255);
  end;
end;

procedure TPPGCustomLinkLabel.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button <> mbLeft then
    Exit;
  FDownLink := LinkAtPos(X, Y);
  if FDownLink >= 0 then
    SetFocusedLink(FDownLink);
end;

procedure TPPGCustomLinkLabel.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  I := LinkAtPos(X, Y);
  if I <> FHotLink then
  begin
    FHotLink := I;
    Invalidate;
  end;
end;

procedure TPPGCustomLinkLabel.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  I: Integer;
begin
  I := FDownLink;
  FDownLink := -1;
  inherited MouseUp(Button, Shift, X, Y);
  // Nur ausloesen, wenn auf demselben Link losgelassen wurde
  if (Button = mbLeft) and (I >= 0) and (LinkAtPos(X, Y) = I) then
    DoLinkClick(I)
  else if (Button = mbLeft) and (I < 0) and (LinkAtPos(X, Y) < 0) and
    PtInRect(ClientRect, Point(X, Y)) then
    // Audit 5b: OnClick fuer Klicks neben den Links (Links: OnLinkClick)
    Click;
end;

procedure TPPGCustomLinkLabel.WMSetCursor(var Message: TWMSetCursor);
begin
  // Audit 5b: Hand nur ueber einem Link, ohne die Property Cursor zu
  // ueberschreiben (ein eigener Cursor des Anwenders bleibt erhalten)
  if (FHotLink >= 0) and (Message.HitTest = HTCLIENT) and Enabled then
  begin
    Winapi.Windows.SetCursor(Screen.Cursors[crHandPoint]);
    Message.Result := 1;
    Exit;
  end;
  inherited;
end;

procedure TPPGCustomLinkLabel.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHotLink >= 0 then
  begin
    FHotLink := -1;
    Invalidate;
  end;
end;

procedure TPPGCustomLinkLabel.CMEnter(var Message: TCMEnter);
begin
  inherited;
  if (FFocusedLink < 0) and (LinkCount > 0) then
    SetFocusedLink(0);
end;

procedure TPPGCustomLinkLabel.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  if LinkCount > 1 then
    Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TPPGCustomLinkLabel.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  case Key of
    VK_LEFT, VK_UP:
      begin
        if FFocusedLink > 0 then
          SetFocusedLink(FFocusedLink - 1);
        Key := 0;
      end;
    VK_RIGHT, VK_DOWN:
      begin
        if FFocusedLink < LinkCount - 1 then
          SetFocusedLink(FFocusedLink + 1);
        Key := 0;
      end;
    VK_RETURN, VK_SPACE:
      if FFocusedLink >= 0 then
      begin
        DoLinkClick(FFocusedLink);
        Key := 0;
      end;
  end;
end;

procedure TPPGCustomLinkLabel.DoLinkClick(Index: Integer);
begin
  if Assigned(FOnLinkClick) then
    FOnLinkClick(Self, LinkTarget(Index), sltURL);
end;

procedure TPPGCustomLinkLabel.WndProc(var Message: TMessage);
begin
  if (GMsgLinkAction <> 0) and (Message.Msg = GMsgLinkAction) then
  begin
    // Aus AccChildDoDefault gepostet: Anwender-Code ausserhalb des COM-Aufrufs
    if (Integer(Message.WParam) >= 0) and (Integer(Message.WParam) < LinkCount) and Enabled then
      DoLinkClick(Integer(Message.WParam));
    Exit;
  end;
  inherited WndProc(Message);
end;

{ ---- Barrierefreiheit ---- }

function TPPGCustomLinkLabel.AccRole: Integer;
begin
  if LinkCount = 1 then
    Result := ROLE_SYSTEM_LINK
  else
    Result := ROLE_SYSTEM_STATICTEXT;
end;

function TPPGCustomLinkLabel.AccName: string;
begin
  Result := PPGStripMarkup(Caption);
end;

function TPPGCustomLinkLabel.AccDefaultAction: string;
begin
  // Audit 7d: genau ein Link = das Control ist der Link (wie die Link-Kinder);
  // sonst hat nur jeder Link seine Aktion
  if LinkCount = 1 then
    Result := PPGStr(@SPPGAccJump)
  else
    Result := '';
end;

procedure TPPGCustomLinkLabel.AccDoDefaultAction;
begin
  // Nie im COM-Aufruf ausloesen: wie AccChildDoDefault posten
  if (LinkCount = 1) and HandleAllocated then
    PostMessage(Handle, GMsgLinkAction, 0, 0);
end;

function TPPGCustomLinkLabel.AccChildCount: Integer;
begin
  Result := LinkCount;
end;

function TPPGCustomLinkLabel.AccChildName(Id: Integer): string;
begin
  EnsureLayout;
  Result := FMarkup.LinkText(Id - 1);
end;

function TPPGCustomLinkLabel.AccChildRole(Id: Integer): Integer;
begin
  Result := ROLE_SYSTEM_LINK;
end;

function TPPGCustomLinkLabel.AccChildState(Id: Integer): Integer;
begin
  Result := STATE_SYSTEM_FOCUSABLE or STATE_SYSTEM_LINKED;
  if Focused and (FFocusedLink = Id - 1) then
    Result := Result or STATE_SYSTEM_FOCUSED;
  if FHotLink = Id - 1 then
    Result := Result or STATE_SYSTEM_HOTTRACKED;
  if not Enabled then
    Result := Result or STATE_SYSTEM_UNAVAILABLE;
end;

function TPPGCustomLinkLabel.AccChildRect(Id: Integer): TRect;
begin
  Result := LinkRect(Id - 1);
end;

function TPPGCustomLinkLabel.AccChildAt(X, Y: Integer): Integer;
begin
  Result := LinkAtPos(X, Y) + 1;
end;

function TPPGCustomLinkLabel.AccChildDefaultAction(Id: Integer): string;
begin
  Result := PPGStr(@SPPGAccJump);
end;

procedure TPPGCustomLinkLabel.AccChildDoDefault(Id: Integer);
begin
  if HandleAllocated then
    PostMessage(Handle, GMsgLinkAction, WPARAM(Id - 1), 0);
end;

function TPPGCustomLinkLabel.AccFocusedChild: Integer;
begin
  if Focused then
    Result := FFocusedLink + 1
  else
    Result := 0;
end;

function TPPGCustomLinkLabel.AccSelectedChild: Integer;
begin
  Result := 0;
end;

end.
