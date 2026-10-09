unit PPG.Controls.DropDown;

{ Gemeinsame Basis fuer Felder mit Aufklapp-Fenster (Phase 12d/e, 20e):
  ComboBox (mit SearchEdit, TimePicker), ColorPicker, CheckComboBox,
  ColumnComboBox, TagEdit. Das Popup (TPPGDropPopup) liegt in PPG.Popup.

  Verhalten:
  - Das Popup wird nie aktiviert. Das Feld behaelt Fokus und Tastatur und
    haelt die Maus per SetCapture; Mausnachrichten werden in Popup-
    Koordinaten an das Popup weitergereicht.
  - Klick ausserhalb, Fokusverlust, Capture-Verlust, Esc, Abschalten oder
    Ausblenden schliessen ohne Uebernahme; was das Popup als "uebernehmen"
    meldet (Klick, Enter), uebernimmt das Feld (Accept).
  - Tastatur: Alt+Pfeil runter/hoch und F4 klappen auf/zu; bei offenem Popup
    gehen Pfeile, Bild auf/ab, Pos1/Ende, Enter, Leertaste und Zeichen an das
    Popup (DropKeyDown/DropKeyPress). Enter/Esc gehoeren dann dem Feld, nicht
    Default-/Cancel-Button.
  - Barrierefreiheit: Rolle ComboBox, Zustand auf-/zugeklappt, Standardaktion
    Oeffnen/Schliessen (gepostet, nie im COM-Aufruf). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Base, PPG.Controls.Field, PPG.Popup,
  PPG.Popup.Placement;

type
  TPPGCustomDropDownField = class(TPPGCustomField)
  private
    FPopup: TPPGDropPopup;
    FDroppedDown: Boolean;
    FMouseInPopup: Boolean;
    FOnDropDown: TNotifyEvent;
    FOnCloseUp: TNotifyEvent;
    procedure HandleDroppedMouse(var Message: TMessage);
    procedure Act(Action: TPPGDropAction);
    procedure PlacePopup(Duration: Cardinal);
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
  protected
    procedure WndProc(var Message: TMessage); override;
    /// Neues Popup (einmal, beim ersten Aufklappen).
    function CreatePopup: TPPGDropPopup; virtual; abstract;
    /// Popup vor dem Zeigen mit dem Zustand des Felds fuellen.
    procedure PreparePopup(APopup: TPPGDropPopup); virtual;
    /// Auswahl des Popups uebernehmen (Anwenderaktion: Ereignisse erlaubt).
    procedure AcceptPopup(APopup: TPPGDropPopup); virtual; abstract;
    procedure DoDropDown; virtual;
    procedure DoCloseUp; virtual;
    /// Darf aufgeklappt werden? Vorgabe: nicht bei ReadOnly.
    function CanDropDown: Boolean; virtual;
    /// Nach dem Zeigen (Popup offen, Maus gefangen).
    procedure PopupOpened; virtual;
    /// Nach dem Schliessen, vor AcceptPopup und OnCloseUp.
    procedure PopupClosed; virtual;
    /// Offenes Popup neu platzieren (z.B. nach dem Filtern), ohne Animation.
    procedure RepositionPopup;
    /// Schliessen ohne Ereignisse und Popup freigeben (fuer Destruktoren, die
    /// vor dem Freigeben Daten des Popups abbauen).
    procedure FreePopup;
    procedure GetButtons(var Buttons: TPPGFieldButtons); override;
    procedure ButtonDown(Id: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure FieldKeyPress(var Key: Char); override;
    /// Taste bei geschlossenem Popup (z.B. Pfeile blaettern die Auswahl).
    procedure ClosedKeyDown(var Key: Word; Shift: TShiftState); virtual;
    procedure ClosedKeyPress(var Key: Char); virtual;
    function WantSpecialKey(Key: Word): Boolean; override;
    procedure FocusChanged; override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    function AccRole: Integer; override;
    function AccState: Integer; override;
    function AccDefaultAction: string; override;
    procedure AccDoDefaultAction; override;
    property OnDropDown: TNotifyEvent read FOnDropDown write FOnDropDown;
    property OnCloseUp: TNotifyEvent read FOnCloseUp write FOnCloseUp;
  public
    destructor Destroy; override;
    procedure DropDown;
    procedure CloseUp(Accept: Boolean);
    property DroppedDown: Boolean read FDroppedDown;
    /// Das Popup (nil vor dem ersten Aufklappen).
    property Popup: TPPGDropPopup read FPopup;
  end;

const
  PPGDropButton = 40;

implementation

uses
  System.SysUtils, Winapi.oleacc, PPG.Lang, PPG.Consts;

var
  GMsgToggle: Cardinal = 0;

{ TPPGCustomDropDownField }

destructor TPPGCustomDropDownField.Destroy;
begin
  // Ohne Ereignisse schliessen; das Popup gehoert dem Feld (Owner)
  if FDroppedDown and (FPopup <> nil) then
    FPopup.ClosePopup;
  FDroppedDown := False;
  inherited Destroy;
end;

procedure TPPGCustomDropDownField.PreparePopup(APopup: TPPGDropPopup);
begin
end;

procedure TPPGCustomDropDownField.DoDropDown;
begin
  if Assigned(FOnDropDown) then
    FOnDropDown(Self);
end;

procedure TPPGCustomDropDownField.DoCloseUp;
begin
  if Assigned(FOnCloseUp) then
    FOnCloseUp(Self);
end;

function TPPGCustomDropDownField.CanDropDown: Boolean;
begin
  Result := not ReadOnly;
end;

procedure TPPGCustomDropDownField.PopupOpened;
begin
end;

procedure TPPGCustomDropDownField.PopupClosed;
begin
end;

procedure TPPGCustomDropDownField.PlacePopup(Duration: Cardinal);
var
  Anchor, WA: TRect;
  P: TPoint;
  Sz: TSize;
  Pl: TPPGPlacement;
begin
  P := ClientToScreen(Point(0, 0));
  Anchor := Rect(P.X, P.Y, P.X + Width, P.Y + Height);
  WA := FPopup.MonitorWorkArea(Anchor);
  Sz := FPopup.PreferredSize(Width);
  Pl := PPGPlacePopup(Anchor, Sz.cx, Sz.cy, ppsBelow, WA, UseRightToLeftAlignment, True);
  FPopup.PopupAt(Pl.Bounds, Pl.Side, Duration);
end;

procedure TPPGCustomDropDownField.RepositionPopup;
begin
  if FDroppedDown and (FPopup <> nil) and HandleAllocated then
    PlacePopup(0);
end;

procedure TPPGCustomDropDownField.DropDown;
var
  Duration: Cardinal;
begin
  if FDroppedDown or not Enabled or not CanDropDown or (csDesigning in ComponentState) or
    not HandleAllocated or not IsWindowVisible(Handle) then
    Exit;
  DoDropDown; // darf die Eintraege noch aendern
  if FDroppedDown or not HandleAllocated then
    Exit;
  if FPopup = nil then
    FPopup := CreatePopup;
  FPopup.SyncFrom(Self);
  PreparePopup(FPopup);
  if Animation.EffectiveEnabled then
    Duration := Animation.Duration
  else
    Duration := 0;
  FDroppedDown := True;
  FMouseInPopup := False;
  PlacePopup(Duration);
  // Maus fuer Klicks ausserhalb; Tastatur bleibt beim Feld
  SetCapture(Handle);
  PopupOpened;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
end;

procedure TPPGCustomDropDownField.FreePopup;
begin
  if FDroppedDown then
  begin
    FDroppedDown := False;
    if FPopup <> nil then
      FPopup.ClosePopup;
    if HandleAllocated and (GetCapture = Handle) then
      ReleaseCapture;
  end;
  FPopup.Free;
  FPopup := nil;
end;

procedure TPPGCustomDropDownField.CloseUp(Accept: Boolean);
begin
  if not FDroppedDown then
    Exit;
  FDroppedDown := False;
  if FPopup <> nil then
    FPopup.ClosePopup;
  if HandleAllocated and (GetCapture = Handle) then
    ReleaseCapture;
  CancelButtonPress;
  PopupClosed;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
  // Zuerst uebernehmen (OnChange), dann OnCloseUp
  if Accept and (FPopup <> nil) then
    AcceptPopup(FPopup);
  DoCloseUp;
end;

procedure TPPGCustomDropDownField.Act(Action: TPPGDropAction);
begin
  case Action of
    pdaAccept: CloseUp(True);
    pdaCancel: CloseUp(False);
  end;
end;

procedure TPPGCustomDropDownField.GetButtons(var Buttons: TPPGFieldButtons);
var
  N: Integer;
begin
  inherited GetButtons(Buttons);
  N := Length(Buttons);
  SetLength(Buttons, N + 1);
  Buttons[N].Id := PPGDropButton;
  Buttons[N].Glyph := fgDropDown;
  Buttons[N].ImageIndex := -1;
  Buttons[N].LeftSide := False;
end;

procedure TPPGCustomDropDownField.ButtonDown(Id: Integer);
begin
  if Id = PPGDropButton then
  begin
    if FDroppedDown then
      CloseUp(False)
    else
    begin
      if CanFocus and not FieldFocused then
        SetFocus;
      DropDown;
    end;
  end
  else
    inherited ButtonDown(Id);
end;

procedure TPPGCustomDropDownField.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  // Ohne sichtbares Edit klappt das ganze Feld auf (wie Windows)
  if (Button = mbLeft) and Enabled and not InnerVisible and not FDroppedDown and
    (ButtonAt(X, Y) < 0) then
  begin
    if CanFocus and not FieldFocused then
      SetFocus;
    DropDown;
  end;
end;

procedure TPPGCustomDropDownField.WndProc(var Message: TMessage);
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

procedure TPPGCustomDropDownField.HandleDroppedMouse(var Message: TMessage);
var
  P, PP: TPoint;
  InPopup: Boolean;
  Shift: TShiftState;
begin
  Message.Result := 0;
  if FPopup = nil then
    Exit;
  // XPos/YPos sind SmallInt: ausserhalb links/oben negativ
  P := Point(TWMMouse(Message).XPos, TWMMouse(Message).YPos);
  PP := FPopup.ScreenToClient(ClientToScreen(P));
  InPopup := FPopup.HandleAllocated and PtInRect(Rect(0, 0, FPopup.Width, FPopup.Height), PP);
  case Message.Msg of
    WM_MOUSEMOVE:
      begin
        Shift := KeysToShiftState(TWMMouse(Message).Keys);
        if InPopup then
        begin
          FMouseInPopup := True;
          FPopup.DropMouseMove(PP.X, PP.Y, Shift);
        end
        else if FMouseInPopup then
        begin
          FMouseInPopup := False;
          FPopup.DropMouseLeave;
          // Ziehen (z.B. Farbfeld) laeuft auch ausserhalb weiter
          if ssLeft in Shift then
            FPopup.DropMouseMove(PP.X, PP.Y, Shift);
        end
        else if ssLeft in Shift then
          FPopup.DropMouseMove(PP.X, PP.Y, Shift);
      end;
    WM_LBUTTONDOWN, WM_LBUTTONDBLCLK:
      if InPopup then
        Act(FPopup.DropMouseDown(PP.X, PP.Y))
      else
        CloseUp(False); // Klick auf das Feld oder ausserhalb
    WM_LBUTTONUP:
      begin
        // Der oeffnende Klick hat ggf. den Button gedrueckt
        CancelButtonPress;
        ControlState := ControlState - [csClicked];
        Act(FPopup.DropMouseUp(PP.X, PP.Y));
      end;
    WM_RBUTTONDOWN, WM_RBUTTONDBLCLK, WM_MBUTTONDOWN, WM_MBUTTONDBLCLK:
      if not InPopup then
        CloseUp(False);
  end;
end;

procedure TPPGCustomDropDownField.WMCaptureChanged(var Message: TMessage);
begin
  inherited;
  // Maus verloren (Dialog, Alt+Tab): ohne Uebernahme schliessen
  if FDroppedDown and (HWND(Message.LParam) <> Handle) then
    CloseUp(False);
end;

procedure TPPGCustomDropDownField.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  // Ohne sichtbares Edit bekommt das Feld selbst Pfeiltasten und Zeichen
  if not InnerVisible then
    Message.Result := Message.Result or DLGC_WANTARROWS or DLGC_WANTCHARS;
end;

procedure TPPGCustomDropDownField.CMEnabledChanged(var Message: TMessage);
begin
  if not Enabled then
    CloseUp(False);
  inherited;
end;

procedure TPPGCustomDropDownField.CMVisibleChanged(var Message: TMessage);
begin
  if not Visible then
    CloseUp(False);
  inherited;
end;

procedure TPPGCustomDropDownField.FocusChanged;
begin
  inherited FocusChanged;
  if FDroppedDown and not FieldFocused and not (csDestroying in ComponentState) then
    CloseUp(False);
end;

function TPPGCustomDropDownField.WantSpecialKey(Key: Word): Boolean;
begin
  Result := FDroppedDown and ((Key = VK_RETURN) or (Key = VK_ESCAPE));
  if not Result then
    Result := inherited WantSpecialKey(Key);
end;

procedure TPPGCustomDropDownField.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift); // OnKeyDown
  if (Key <> 0) and not InnerVisible then
    FieldKeyDown(Key, Shift);
end;

procedure TPPGCustomDropDownField.KeyPress(var Key: Char);
begin
  inherited KeyPress(Key); // OnKeyPress
  if (Key <> #0) and not InnerVisible then
    FieldKeyPress(Key);
end;

procedure TPPGCustomDropDownField.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  // Auf-/Zuklappen
  if (((Key = VK_DOWN) or (Key = VK_UP)) and (ssAlt in Shift)) or
    ((Key = VK_F4) and (Shift = [])) then
  begin
    if FDroppedDown then
      CloseUp(True)
    else
      DropDown;
    Key := 0;
    Exit;
  end;
  if FDroppedDown and (FPopup <> nil) then
  begin
    if Key = VK_ESCAPE then
    begin
      CloseUp(False);
      Key := 0;
      Exit;
    end;
    Act(FPopup.DropKeyDown(Key, Shift));
    Exit;
  end;
  ClosedKeyDown(Key, Shift);
end;

procedure TPPGCustomDropDownField.FieldKeyPress(var Key: Char);
begin
  if FDroppedDown and (FPopup <> nil) then
  begin
    // Enter/Esc sind schon in KeyDown erledigt (kein Signalton)
    if (Key = #13) or (Key = #27) then
    begin
      Key := #0;
      Exit;
    end;
    Act(FPopup.DropKeyPress(Key));
    Key := #0;
    Exit;
  end;
  ClosedKeyPress(Key);
end;

procedure TPPGCustomDropDownField.ClosedKeyDown(var Key: Word; Shift: TShiftState);
begin
end;

procedure TPPGCustomDropDownField.ClosedKeyPress(var Key: Char);
begin
end;

function TPPGCustomDropDownField.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  if FDroppedDown and (FPopup <> nil) then
  begin
    FPopup.DropWheel(WheelDelta);
    Result := True;
    Exit;
  end;
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
end;

function TPPGCustomDropDownField.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_COMBOBOX;
end;

function TPPGCustomDropDownField.AccState: Integer;
begin
  Result := inherited AccState or STATE_SYSTEM_HASPOPUP;
  if FDroppedDown then
    Result := Result or STATE_SYSTEM_EXPANDED
  else
    Result := Result or STATE_SYSTEM_COLLAPSED;
end;

function TPPGCustomDropDownField.AccDefaultAction: string;
begin
  if FDroppedDown then
    Result := PPGStr(@SPPGAccClose)
  else
    Result := PPGStr(@SPPGAccOpen);
end;

procedure TPPGCustomDropDownField.AccDoDefaultAction;
begin
  if HandleAllocated then
    PostMessage(Handle, GMsgToggle, 0, 0);
end;

initialization
  GMsgToggle := RegisterWindowMessage('PPGlow.DropDownToggle');

end.
