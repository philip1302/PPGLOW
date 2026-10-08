unit PPG.MenuBar;

{ TPPGMenuBar - Hauptmenue als Control im Stil der Suite (Phase 11c).

  - Modell ist ein normales TMainMenu (Menue-Designer, Actions, DFM). Die
    Leiste zeigt seine Eintraege; Untermenues kommen aus PPG.Menus.
  - Zur Laufzeit wird Form.Menu geleert (die Menue-Leiste im Nicht-Client-
    Bereich laesst sich weder stylen noch auf Dark Mode umstellen); beim
    Freigeben der Leiste wird es wiederhergestellt. Zur Entwurfszeit bleibt
    das Formular-Menue sichtbar.
  - Weil Form.Menu leer ist, loest die VCL die Tastenkuerzel der Eintraege
    nicht mehr aus: das uebernimmt die Leiste (TMenu.IsShortCut, wie
    TCustomForm.IsShortCut).
  - Tastatur wie Windows: Alt allein bzw. F10 markiert die Leiste, Alt+
    Buchstabe oeffnet den Eintrag, Pfeile wechseln, Esc verlaesst. Haken in
    PPG.AppHooks, nur fuer Nachrichten des eigenen Formulars.
  - Barrierefreiheit: Rolle MENUBAR mit Eintraegen als Kindern,
    EVENT_SYSTEM_MENUSTART/END. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.Menus, Vcl.Forms,
  PPG.Types, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Base, PPG.Menus;

type
  TPPGCustomMenuBar = class(TPPGCustomControl, IPPGMenuBarHost, IPPGAccessibleChildren)
  private
    FMenu: TMainMenu;
    FHiddenFormMenu: TMainMenu;  // Form.Menu, das zur Laufzeit geleert wurde
    FHiddenForm: TCustomForm;
    FLoop: TPPGMenuLoop;
    FHot: Integer;               // hervorgehobener Eintrag (Maus/Tastatur)
    FOpen: Integer;              // Eintrag mit offenem Untermenue (-1)
    FKeyboardMode: Boolean;
    FAltDown: Boolean;
    FLeaveOnKeyUp: Boolean;      // Alt/F10 im Tastaturmodus: beim Loslassen verlassen
    FSwitching: Boolean;         // OpenItem wechselt das Untermenue (kein "geschlossen")
    FHooked: Boolean;
    FMenuStyles: TPPGMenuStyles;
    FOnCustomDrawItem: TPPGMenuCustomDrawEvent;
    procedure SetMenuStyles(const Value: TPPGMenuStyles);
    procedure SetMenu(const Value: TMainMenu);
    procedure Hook(var Msg: TMsg; var Handled: Boolean);
    procedure AppDeactivate(Sender: TObject);
    function OwnForm: TCustomForm;
    function BelongsToForm(Wnd: HWND): Boolean;
    procedure HideFormMenu;
    procedure RestoreFormMenu;
    procedure UpdateHook;
    procedure SetHot(Index: Integer);
    function MatchMnemonic(Ch: Char): Integer;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    { IPPGMenuBarHost }
    procedure MenuBarStep(Delta: Integer);
    procedure MenuBarClosed(Escaped: Boolean);
    function MenuBarOwnsPoint(const ScreenPt: TPoint): Boolean;
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

    procedure Loaded; override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    function CalcAutoSize(out AWidth, AHeight: Integer): Boolean; override;
    function AutoSizeWidth: Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    function AccRole: Integer; override;
    function AccName: string; override;
    property Menu: TMainMenu read FMenu write SetMenu;
    /// Bereiche der Untermenues (Flaeche, Hover, Trennlinien, Kuerzel).
    property MenuStyles: TPPGMenuStyles read FMenuStyles write SetMenuStyles;
    /// Vor dem Zeichnen jedes Eintrags der Untermenues.
    property OnCustomDrawItem: TPPGMenuCustomDrawEvent read FOnCustomDrawItem write FOnCustomDrawItem;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Sichtbare Eintraege der obersten Ebene.
    function ItemCount: Integer;
    function Item(Index: Integer): TMenuItem;
    function ItemRect(Index: Integer): TRect;
    function ItemAtPos(X, Y: Integer): Integer;
    /// Untermenue eines Eintrags oeffnen (SelectFirst = per Tastatur).
    procedure OpenItem(Index: Integer; SelectFirst: Boolean);
    procedure CloseMenus;
    /// Tastaturmodus (Alt/F10) ein- bzw. ausschalten.
    procedure EnterKeyboardMode;
    procedure LeaveKeyboardMode;
    /// Tasten der Leiste (auch direkt fuer Tests). True = verarbeitet.
    function HandleBarKey(Key: Word): Boolean;
    function HandleBarChar(Ch: Char): Boolean;
    property Hot: Integer read FHot;
    property OpenIndex: Integer read FOpen;
    property KeyboardMode: Boolean read FKeyboardMode;
    property Loop: TPPGMenuLoop read FLoop;
  end;

  TPPGMenuBar = class(TPPGCustomMenuBar)
  published
    property Menu;
    property MenuStyles;
    property OnCustomDrawItem;
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighContrastSupport;
    property Align default alTop;
    property Anchors;
    property AutoSize default True;
    property BiDiMode;
    property Constraints;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentFont;
    property Visible;
    property Touch;
    property OnGesture;
  end;

implementation

uses
  PPG.Lang,
  System.Math, Winapi.oleacc,
  PPG.Consts, PPG.Appearance, PPG.Tokens, PPG.DpiUtils, PPG.AppHooks, PPG.Popup.Placement,
  PPG.Render.Registry, PPG.Render.Gdi;

const
  ItemPadX = 10;   // logische px links/rechts im Eintrag
  BarPadY = 4;

{ TPPGCustomMenuBar }

constructor TPPGCustomMenuBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption, csDoubleClicks];
  FHot := -1;
  FOpen := -1;
  TabStop := False;
  Align := alTop;
  Height := 30;
  AutoSize := True;
  FLoop := TPPGMenuLoop.Create;
  FLoop.Bar := Self;
  FMenuStyles := TPPGMenuStyles.Create(Self);
end;

procedure TPPGCustomMenuBar.SetMenuStyles(const Value: TPPGMenuStyles);
begin
  FMenuStyles.Assign(Value);
end;

destructor TPPGCustomMenuBar.Destroy;
begin
  if FHooked then
  begin
    PPGRemoveMessageHook(Hook);
    PPGRemoveDeactivateHook(AppDeactivate);
    FHooked := False;
  end;
  if FLoop <> nil then
  begin
    FLoop.Bar := nil;
    FLoop.CloseAll;
  end;
  FreeAndNil(FLoop);
  RestoreFormMenu;
  inherited Destroy;
  FreeAndNil(FMenuStyles);
end;

function TPPGCustomMenuBar.OwnForm: TCustomForm;
begin
  Result := GetParentForm(Self);
end;

procedure TPPGCustomMenuBar.HideFormMenu;
var
  F: TCustomForm;
begin
  if (csDesigning in ComponentState) or (csLoading in ComponentState) or (FMenu = nil) then
    Exit;
  F := OwnForm;
  if (F <> nil) and (F.Menu = FMenu) then
  begin
    FHiddenForm := F;
    FHiddenFormMenu := FMenu;
    F.FreeNotification(Self);
    F.Menu := nil;
  end;
end;

procedure TPPGCustomMenuBar.RestoreFormMenu;
begin
  if (FHiddenForm <> nil) and (FHiddenFormMenu <> nil) and
    not (csDestroying in FHiddenForm.ComponentState) then
    FHiddenForm.Menu := FHiddenFormMenu;
  FHiddenForm := nil;
  FHiddenFormMenu := nil;
end;

procedure TPPGCustomMenuBar.SetMenu(const Value: TMainMenu);
begin
  if FMenu = Value then
    Exit;
  CloseMenus;
  RestoreFormMenu;
  if FMenu <> nil then
    FMenu.RemoveFreeNotification(Self);
  FMenu := Value;
  if FMenu <> nil then
    FMenu.FreeNotification(Self);
  HideFormMenu;
  RequestAutoSize;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

procedure TPPGCustomMenuBar.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation <> opRemove then
    Exit;
  if AComponent = FMenu then
  begin
    if FLoop <> nil then
      FLoop.CloseAll;
    FMenu := nil;
    FHiddenFormMenu := nil;
    Invalidate;
  end;
  if AComponent = FHiddenForm then
  begin
    FHiddenForm := nil;
    FHiddenFormMenu := nil;
  end;
end;

procedure TPPGCustomMenuBar.Loaded;
begin
  inherited Loaded;
  HideFormMenu;
end;

procedure TPPGCustomMenuBar.CreateWnd;
begin
  inherited CreateWnd;
  HideFormMenu;
  UpdateHook;
end;

procedure TPPGCustomMenuBar.DestroyWnd;
begin
  CloseMenus;
  inherited DestroyWnd;
end;

procedure TPPGCustomMenuBar.UpdateHook;
begin
  if FHooked or (csDesigning in ComponentState) then
    Exit;
  PPGAddMessageHook(Hook);
  PPGAddDeactivateHook(AppDeactivate);
  FHooked := True;
end;

function TPPGCustomMenuBar.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGCustomMenuBar.IsDown: Boolean;
begin
  Result := False;
end;

function TPPGCustomMenuBar.AutoSizeWidth: Boolean;
begin
  Result := False;
end;

function TPPGCustomMenuBar.CalcAutoSize(out AWidth, AHeight: Integer): Boolean;
begin
  AWidth := Width;
  AHeight := PPGMeasureTextNoCanvas('Wg', Font, 0, False).cy + 2 * PPGScale(BarPadY + 4, ScalePPI);
  Result := True;
end;

procedure TPPGCustomMenuBar.CMFontChanged(var Message: TMessage);
begin
  inherited;
  RequestAutoSize;
  Invalidate;
end;

function TPPGCustomMenuBar.ItemCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  if FMenu = nil then
    Exit;
  for I := 0 to FMenu.Items.Count - 1 do
    if FMenu.Items[I].Visible then
      Inc(Result);
end;

function TPPGCustomMenuBar.Item(Index: Integer): TMenuItem;
var
  I, N: Integer;
begin
  Result := nil;
  if FMenu = nil then
    Exit;
  N := 0;
  for I := 0 to FMenu.Items.Count - 1 do
    if FMenu.Items[I].Visible then
    begin
      if N = Index then
        Exit(FMenu.Items[I]);
      Inc(N);
    end;
end;

function TPPGCustomMenuBar.ItemRect(Index: Integer): TRect;
var
  I, X, W, PPI, Pad: Integer;
begin
  // Eintraege nebeneinander; jedes Mal neu gerechnet (Menue kann sich zur
  // Laufzeit aendern: Visible, Caption, MDI-Zusammenfuehrung)
  PPI := ScalePPI;
  Pad := PPGScale(ItemPadX, PPI);
  X := PPGScale(4, PPI);
  Result := Rect(0, 0, 0, 0);
  for I := 0 to Index do
  begin
    W := PPGMeasureTextNoCanvas(Item(I).Caption, Font, 0, False).cx + 2 * Pad;
    if I = Index then
      Result := Rect(X, PPGScale(BarPadY, PPI), X + W, ClientHeight - PPGScale(BarPadY, PPI))
    else
      Inc(X, W);
  end;
  if UseRightToLeftAlignment then
    Result := Rect(ClientWidth - Result.Right, Result.Top, ClientWidth - Result.Left,
      Result.Bottom);
end;

function TPPGCustomMenuBar.ItemAtPos(X, Y: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to ItemCount - 1 do
    if PtInRect(ItemRect(I), Point(X, Y)) then
      Exit(I);
end;

procedure TPPGCustomMenuBar.SetHot(Index: Integer);
begin
  if FHot = Index then
    Exit;
  FHot := Index;
  Invalidate;
  if FHot >= 0 then
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, FHot + 1);
end;

procedure TPPGCustomMenuBar.OpenItem(Index: Integer; SelectFirst: Boolean);
var
  It: TMenuItem;
  R: TRect;
  P: TPoint;
begin
  if (Index < 0) or (Index >= ItemCount) or not HandleAllocated then
    Exit;
  It := Item(Index);
  if not It.Enabled then
    Exit;
  if It.Count = 0 then
  begin
    // Eintrag ohne Untermenue in der Leiste: direkt ausloesen
    CloseMenus;
    LeaveKeyboardMode;
    It.Click;
    Exit;
  end;
  if not FLoop.Active and not FKeyboardMode then
    NotifyAccessibility(EVENT_SYSTEM_MENUSTART);
  // Wie bei Windows ruft das Oeffnen OnClick des Eintrags (dynamische Menues)
  It.Click;
  FOpen := Index;
  SetHot(Index);
  R := ItemRect(Index);
  P := ClientToScreen(R.TopLeft);
  R := Rect(P.X, P.Y, P.X + R.Right - R.Left, P.Y + R.Bottom - R.Top);
  FLoop.StyleSource := Self;
  FLoop.BiDiMode := BiDiMode;
  FLoop.MenuStyles := FMenuStyles;
  FLoop.OnCustomDrawItem := FOnCustomDrawItem;
  FLoop.DrawSender := Self;
  FLoop.ShowAccelerators := SelectFirst or FKeyboardMode;
  FSwitching := True;
  try
    FLoop.OpenPopup(It, R, ppsBelow, UseRightToLeftAlignment);
  finally
    FSwitching := False;
  end;
  if SelectFirst and (FLoop.TopWindow <> nil) then
    FLoop.TopWindow.HotFirst;
  Invalidate;
end;

procedure TPPGCustomMenuBar.CloseMenus;
begin
  if (FLoop <> nil) and FLoop.Active then
    FLoop.CloseAll;
  FOpen := -1;
  Invalidate;
end;

procedure TPPGCustomMenuBar.EnterKeyboardMode;
begin
  if ItemCount = 0 then
    Exit;
  if not FKeyboardMode then
    NotifyAccessibility(EVENT_SYSTEM_MENUSTART);
  FKeyboardMode := True;
  if FHot < 0 then
    SetHot(0);
  Invalidate;
end;

procedure TPPGCustomMenuBar.LeaveKeyboardMode;
begin
  FLeaveOnKeyUp := False;
  if FKeyboardMode then
    NotifyAccessibility(EVENT_SYSTEM_MENUEND);
  FKeyboardMode := False;
  SetHot(-1);
  Invalidate;
end;

{ IPPGMenuBarHost }

procedure TPPGCustomMenuBar.MenuBarStep(Delta: Integer);
var
  N, I: Integer;
begin
  N := ItemCount;
  if N = 0 then
    Exit;
  if UseRightToLeftAlignment then
    Delta := -Delta;
  I := FOpen;
  if I < 0 then
    I := FHot;
  I := (I + Delta + N) mod N;
  OpenItem(I, True);
end;

procedure TPPGCustomMenuBar.MenuBarClosed(Escaped: Boolean);
var
  WasOpen: Integer;
begin
  if FSwitching then
    Exit;
  WasOpen := FOpen;
  FOpen := -1;
  if Escaped and (WasOpen >= 0) then
  begin
    // Esc auf der obersten Ebene: Leiste bleibt markiert (wie Windows)
    FKeyboardMode := True;
    SetHot(WasOpen);
  end
  else
  begin
    if FKeyboardMode or (WasOpen >= 0) then
      NotifyAccessibility(EVENT_SYSTEM_MENUEND);
    FKeyboardMode := False;
    SetHot(-1);
  end;
  Invalidate;
end;

function TPPGCustomMenuBar.MenuBarOwnsPoint(const ScreenPt: TPoint): Boolean;
var
  P: TPoint;
begin
  Result := False;
  if not HandleAllocated or not Showing then
    Exit;
  P := ScreenToClient(ScreenPt);
  Result := PtInRect(ClientRect, P);
end;

{ Maus }

procedure TPPGCustomMenuBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button <> mbLeft) or (csDesigning in ComponentState) then
    Exit;
  I := ItemAtPos(X, Y);
  if (I >= 0) and (I = FOpen) and FLoop.Active then
  begin
    // Zweiter Klick auf den offenen Eintrag schliesst (wie Windows)
    CloseMenus;
    LeaveKeyboardMode;
    Exit;
  end;
  if I >= 0 then
    OpenItem(I, False)
  else
  begin
    CloseMenus;
    LeaveKeyboardMode;
  end;
end;

procedure TPPGCustomMenuBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  I := ItemAtPos(X, Y);
  // Bei offenem Untermenue wechselt Ueberfahren den Eintrag (Hot-Tracking)
  if FLoop.Active and (I >= 0) and (I <> FOpen) then
    OpenItem(I, False)
  else if not FLoop.Active and not FKeyboardMode then
    SetHot(I);
end;

procedure TPPGCustomMenuBar.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if not FLoop.Active and not FKeyboardMode then
    SetHot(-1);
end;

{ Tastatur }

function TPPGCustomMenuBar.MatchMnemonic(Ch: Char): Integer;
var
  I: Integer;
  S: string;
begin
  Result := -1;
  Ch := UpCase(Ch);
  for I := 0 to ItemCount - 1 do
  begin
    S := GetHotkey(Item(I).Caption);
    if (S <> '') and (UpCase(S[1]) = Ch) and Item(I).Enabled then
      Exit(I);
  end;
end;

function TPPGCustomMenuBar.HandleBarKey(Key: Word): Boolean;
var
  N, Fwd, Back: Integer;
begin
  Result := True;
  N := ItemCount;
  if N = 0 then
    Exit(False);
  if UseRightToLeftAlignment then
  begin
    Fwd := VK_LEFT;
    Back := VK_RIGHT;
  end
  else
  begin
    Fwd := VK_RIGHT;
    Back := VK_LEFT;
  end;
  if Key = Fwd then
    SetHot((Max(FHot, 0) + 1) mod N)
  else if Key = Back then
    SetHot((Max(FHot, 0) - 1 + N) mod N)
  else
    case Key of
      VK_HOME: SetHot(0);
      VK_END: SetHot(N - 1);
      VK_DOWN, VK_UP, VK_RETURN, VK_SPACE:
        OpenItem(Max(FHot, 0), True);
      VK_ESCAPE, VK_MENU, VK_F10:
        LeaveKeyboardMode;
    else
      Result := False;
    end;
end;

function TPPGCustomMenuBar.HandleBarChar(Ch: Char): Boolean;
var
  I: Integer;
begin
  I := MatchMnemonic(Ch);
  Result := I >= 0;
  if Result then
    OpenItem(I, True)
  else
    MessageBeep(0);
end;

function TPPGCustomMenuBar.BelongsToForm(Wnd: HWND): Boolean;
var
  F: TCustomForm;
begin
  F := OwnForm;
  Result := (F <> nil) and F.HandleAllocated and (Wnd <> 0) and
    (GetAncestor(Wnd, GA_ROOT) = F.Handle);
end;

procedure TPPGCustomMenuBar.Hook(var Msg: TMsg; var Handled: Boolean);
var
  Key: TWMKey;
  F: TCustomForm;
begin
  if (FMenu = nil) or not HandleAllocated or not Showing or not Enabled then
    Exit;
  // Offene Untermenues bedient die Menue-Schleife (eigener, spaeter
  // angemeldeter Haken - wird vorher aufgerufen)
  if FLoop.Active then
    Exit;
  if not BelongsToForm(Msg.hwnd) then
    Exit;
  F := OwnForm;
  if (F <> nil) and (F.Menu <> nil) then
    Exit; // Formular hat wieder ein natives Menue: nicht einmischen

  if FKeyboardMode then
  begin
    case Msg.message of
      WM_KEYDOWN, WM_SYSKEYDOWN:
        begin
          // Alt/F10 erst beim Loslassen: WM_SYSKEYUP darf nicht an Windows gehen
          // (DefWindowProc startet sonst die System-Menueschleife)
          if (Msg.wParam = VK_MENU) or (Msg.wParam = VK_F10) then
            FLeaveOnKeyUp := True
          else if not HandleBarKey(Word(Msg.wParam)) then
            LeaveKeyboardMode;
          Handled := True;
        end;
      WM_CHAR, WM_SYSCHAR:
        begin
          HandleBarChar(Char(Msg.wParam));
          Handled := True;
        end;
      WM_KEYUP, WM_SYSKEYUP:
        begin
          Handled := True;
          if FLeaveOnKeyUp and ((Msg.wParam = VK_MENU) or (Msg.wParam = VK_F10)) then
          begin
            FLeaveOnKeyUp := False;
            LeaveKeyboardMode;
          end;
        end;
      WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN, WM_NCLBUTTONDOWN:
        if Msg.hwnd <> Handle then
          LeaveKeyboardMode;
    end;
    Exit;
  end;

  case Msg.message of
    WM_SYSKEYDOWN:
      begin
        if (Msg.wParam = VK_MENU) and (Msg.lParam and $40000000 = 0) then
          FAltDown := True
        else
        begin
          FAltDown := False;
          if Msg.wParam = VK_F10 then
          begin
            EnterKeyboardMode;
            Handled := True;
            Exit;
          end;
        end;
        // Tastenkuerzel der Eintraege (Alt+...) wie TCustomForm.IsShortCut
        if Msg.wParam <> VK_MENU then
        begin
          Key.Msg := Msg.message;
          Key.CharCode := Word(Msg.wParam);
          Key.KeyData := Msg.lParam;
          if FMenu.IsShortCut(Key) then
            Handled := True;
        end;
      end;
    WM_SYSKEYUP:
      if (Msg.wParam = VK_MENU) and FAltDown then
      begin
        FAltDown := False;
        EnterKeyboardMode;
        Handled := True;
      end;
    WM_SYSCHAR:
      begin
        FAltDown := False;
        // Alt+Buchstabe: Eintrag der Leiste (Formular-Mnemonics nur, wenn
        // die Leiste keinen passenden Eintrag hat)
        if MatchMnemonic(Char(Msg.wParam)) >= 0 then
        begin
          EnterKeyboardMode;
          HandleBarChar(Char(Msg.wParam));
          Handled := True;
        end;
      end;
    WM_KEYDOWN:
      begin
        FAltDown := False;
        Key.Msg := Msg.message;
        Key.CharCode := Word(Msg.wParam);
        Key.KeyData := Msg.lParam;
        if FMenu.IsShortCut(Key) then
          Handled := True;
      end;
    WM_LBUTTONDOWN, WM_RBUTTONDOWN:
      FAltDown := False;
  end;
end;

procedure TPPGCustomMenuBar.AppDeactivate(Sender: TObject);
begin
  FAltDown := False;
  if FKeyboardMode then
    LeaveKeyboardMode;
end;

{ Zeichnen }

procedure TPPGCustomMenuBar.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  MR: IPPGMenuRenderer;
  A: TPPGAppearance;
  L, H: TPPGSurfaceStyle;
  T: TPPGTokens;
  PPI, I: Integer;
  R: TRect;
  TextCol: TColor;
  HC: Boolean;
  Flags: Cardinal;
  Hot: Single;
begin
  PPI := ScalePPI;
  T := Tokens;
  A := EffectiveAppearance;
  HC := HighContrastSupport and PPGIsHighContrast;
  L := A.Resolve(vsNormal, PPI, False);
  H := A.Resolve(vsHot, PPI, False);
  if HC then
  begin
    L.Color := PPGColorToRGB(clMenuBar);
    L.TextColor := PPGColorToRGB(clMenuText);
    H.Color := PPGColorToRGB(clHighlight);
    H.ColorTo := H.Color;
    H.ColorMirror := H.Color;
    H.ColorMirrorTo := H.Color;
    H.BorderColor := H.Color;
    H.TextColor := PPGColorToRGB(clHighlightText);
  end
  else
  begin
    if UseDarkMode then
      L.Color := T.Background
    else
      L.Color := PPGColorToRGB(GetBackgroundColor);
    L.TextColor := T.TextPrimary;
  end;
  if not Supports(Renderer, IPPGMenuRenderer, MR) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName), IPPGMenuRenderer, MR);
  MR.DrawMenuBar(ACanvas, ClientR, L, PPI);
  Flags := DT_SINGLELINE or DT_VCENTER or DT_CENTER;
  if not FKeyboardMode and not (FLoop.Active and FLoop.ShowAccelerators) and
    not AcceleratorCuesVisible then
    Flags := Flags or DT_HIDEPREFIX;
  if UseRightToLeftAlignment then
    Flags := Flags or DT_RTLREADING;
  for I := 0 to ItemCount - 1 do
  begin
    R := ItemRect(I);
    Hot := 0;
    if I = FHot then
      Hot := 1;
    MR.DrawMenuBarItem(ACanvas, R, L, H, Hot, I = FOpen, PPI);
    if not Enabled or not Item(I).Enabled then
    begin
      if HC then
        TextCol := PPGColorToRGB(clGrayText)
      else
        TextCol := T.TextDisabled;
    end
    else if HC and ((I = FHot) or (I = FOpen)) then
      TextCol := H.TextColor
    else
      TextCol := L.TextColor;
    ACanvas.DrawText(R, Item(I).Caption, Font, TextCol, Flags);
  end;
end;

{ Barrierefreiheit }

function TPPGCustomMenuBar.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_MENUBAR;
end;

function TPPGCustomMenuBar.AccName: string;
begin
  Result := '';
end;

function TPPGCustomMenuBar.AccChildCount: Integer;
begin
  Result := ItemCount;
end;

function TPPGCustomMenuBar.AccChildName(Id: Integer): string;
begin
  if (Id >= 1) and (Id <= ItemCount) then
    Result := StripHotkey(Item(Id - 1).Caption)
  else
    Result := '';
end;

function TPPGCustomMenuBar.AccChildRole(Id: Integer): Integer;
begin
  Result := ROLE_SYSTEM_MENUITEM;
end;

function TPPGCustomMenuBar.AccChildState(Id: Integer): Integer;
begin
  Result := STATE_SYSTEM_FOCUSABLE;
  if (Id < 1) or (Id > ItemCount) then
    Exit;
  if not Item(Id - 1).Enabled then
    Result := Result or STATE_SYSTEM_UNAVAILABLE;
  if Item(Id - 1).Count > 0 then
    Result := Result or STATE_SYSTEM_HASPOPUP;
  if Id - 1 = FHot then
    Result := Result or STATE_SYSTEM_FOCUSED or STATE_SYSTEM_HOTTRACKED;
  if Id - 1 = FOpen then
    Result := Result or STATE_SYSTEM_EXPANDED;
end;

function TPPGCustomMenuBar.AccChildRect(Id: Integer): TRect;
begin
  if (Id >= 1) and (Id <= ItemCount) then
    Result := ItemRect(Id - 1)
  else
    Result := Rect(0, 0, 0, 0);
end;

function TPPGCustomMenuBar.AccChildAt(X, Y: Integer): Integer;
begin
  Result := ItemAtPos(X, Y) + 1;
end;

function TPPGCustomMenuBar.AccChildDefaultAction(Id: Integer): string;
begin
  Result := PPGStr(@SPPGAccOpen);
end;

procedure TPPGCustomMenuBar.AccChildDoDefault(Id: Integer);
begin
  if (Id >= 1) and (Id <= ItemCount) then
    OpenItem(Id - 1, True);
end;

function TPPGCustomMenuBar.AccFocusedChild: Integer;
begin
  Result := FHot + 1;
end;

function TPPGCustomMenuBar.AccSelectedChild: Integer;
begin
  Result := FOpen + 1;
end;

end.
