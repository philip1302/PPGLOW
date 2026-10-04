unit PPG.DatePicker;

{ TPPGDatePicker - Datumsfeld mit Kalender-Popup (Phase 7b).

  - Basis TPPGCustomField: natives Edit fuer die Eingabe, Kalender-Button
    rechts, optional ein Kontrollkaestchen links (ShowCheckbox/Checked wie
    TDateTimePicker: ohne Haken gilt "kein Datum").
  - Eingabe: Ziffern und Datumstrenner; Oben/Unten aendern den Tag
    (Strg: Monat). Beim Verlassen bzw. Enter wird geprueft: gueltig =
    uebernehmen (OnChange), ungueltig = ValidationState pvsError, der Text
    bleibt zum Korrigieren stehen. Grenzen MinDate/MaxDate.
  - Popup: TPPGCalendar in einem Popup ohne Aktivierung. Das Feld behaelt
    den Fokus und leitet Pfeile, Bild, Pos1/Ende und Enter an den Kalender
    weiter. Klick ausserhalb (Maus-Hook des Threads, solange offen), Esc und
    Fokusverlust schliessen; Klick auf einen Tag uebernimmt.
  - DFM-nah zu TDateTimePicker (Kind = dtkDate): Date, Time, MinDate,
    MaxDate, ShowCheckbox, Checked, DateFormat, Format, CalAlignment; Kind,
    DateMode und ParseInput werden gelesen und gespeichert, aendern aber
    nichts (fuer Zeiten gibt es TPPGTimePicker).
  - Code (Date := ...) loest kein OnChange aus. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.ComCtrls,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Controls.Base, PPG.Controls.Field,
  PPG.Popup, PPG.Calendar;

type
  TPPGCustomDatePicker = class;

  /// Popup mit Kalender (gehoert dem DatePicker).
  TPPGCalendarPopup = class(TPPGPopupWindow)
  private
    FCalendar: TPPGCalendar;
  protected
    function PopupRounding: Integer; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SyncFrom(Source: TPPGCustomControl); override;
    /// Kalenderfenster zeigen bzw. verstecken. Das Popup hat keinen Parent, die
    /// VCL fuehrt deshalb kein UpdateShowing fuer seine Kinder aus.
    procedure ShowCalendar;
    procedure HideCalendar;
    property Calendar: TPPGCalendar read FCalendar;
  end;

  TPPGCustomDatePicker = class(TPPGCustomField)
  private
    FDateTime: TDateTime;   // 0 = kein Datum
    FMinDate: TDate;
    FMaxDate: TDate;
    FShowCheckbox: Boolean;
    FChecked: Boolean;
    FDateFormat: TDTDateFormat;
    FFormat: string;
    FKind: TDateTimeKind;
    FDateMode: TDTDateMode;
    FCalAlignment: TDTCalAlignment;
    FParseInput: Boolean;
    FPopup: TPPGCalendarPopup;
    FDroppedDown: Boolean;
    FQuiet: Integer;
    FEditing: Boolean;
    FOnDropDown: TNotifyEvent;
    FOnCloseUp: TNotifyEvent;
    function GetDate: TDate;
    procedure SetDate(const Value: TDate);
    function GetTime: TTime;
    procedure SetTime(const Value: TTime);
    procedure SetDateTime(const Value: TDateTime);
    procedure SetMinDate(const Value: TDate);
    procedure SetMaxDate(const Value: TDate);
    procedure SetShowCheckbox(const Value: Boolean);
    procedure SetChecked(const Value: Boolean);
    procedure SetDateFormat(const Value: TDTDateFormat);
    procedure SetFormat(const Value: string);
    procedure SetDroppedDown(const Value: Boolean);
    procedure UpdateText;
    procedure CalendarChange(Sender: TObject);
    function ClampToRange(D: TDate): TDate;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  protected
    procedure Loaded; override;
    procedure GetButtons(var Buttons: TPPGFieldButtons); override;
    procedure ButtonDown(Id: Integer); override;
    procedure ButtonClick(Id: Integer); override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure FieldKeyPress(var Key: Char); override;
    function WantSpecialKey(Key: Word): Boolean; override;
    procedure FocusChanged; override;
    procedure Change; override;
    procedure GetFieldColors(out Fill, Text: TColor); override;
    procedure DoPaintField(const ACanvas: IPPGCanvas; const Style: TPPGSurfaceStyle); override;
    function AccRole: Integer; override;
    function AccValue: string; override;
    function AccState: Integer; override;
    function AccDefaultAction: string; override;
    procedure AccDoDefaultAction; override;
    procedure WndProc(var Message: TMessage); override;
    /// Text des Edits pruefen und uebernehmen (True = gueltig oder leer erlaubt).
    function CommitText(UserAction: Boolean): Boolean;
    /// Datum durch den Anwender setzen (OnChange).
    procedure UserSetDate(D: TDate);
    /// Anwender hat Datum oder Kaestchen geaendert: loest OnChange aus.
    /// DB-Variante: Datensatz vorher in den Bearbeiten-Modus setzen.
    procedure UserChange; virtual;
    procedure DoDropDown; virtual;
    procedure DoCloseUp; virtual;
    property Date: TDate read GetDate write SetDate;
    property Time: TTime read GetTime write SetTime;
    property MinDate: TDate read FMinDate write SetMinDate;
    property MaxDate: TDate read FMaxDate write SetMaxDate;
    property ShowCheckbox: Boolean read FShowCheckbox write SetShowCheckbox default False;
    property Checked: Boolean read FChecked write SetChecked default True;
    property DateFormat: TDTDateFormat read FDateFormat write SetDateFormat default dfShort;
    /// Anzeigeformat (FormatDateTime), leer = DateFormat.
    property Format: string read FFormat write SetFormat;
    property Kind: TDateTimeKind read FKind write FKind default dtkDate;
    property DateMode: TDTDateMode read FDateMode write FDateMode default dmComboBox;
    property CalAlignment: TDTCalAlignment read FCalAlignment write FCalAlignment default dtaLeft;
    property ParseInput: Boolean read FParseInput write FParseInput default False;
    property OnDropDown: TNotifyEvent read FOnDropDown write FOnDropDown;
    property OnCloseUp: TNotifyEvent read FOnCloseUp write FOnCloseUp;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DropDown;
    procedure CloseUp(Accept: Boolean);
    /// Text, wie er fuer ein Datum angezeigt wird.
    function FormatDate(D: TDate): string;
    /// Text in ein Datum wandeln (Anzeigeformat, dann Kurzformat).
    function ParseDate(const S: string; out D: TDate): Boolean;
    /// True, wenn ein Datum gilt (Checked und nicht leer).
    function HasDate: Boolean;
    property DateTime: TDateTime read FDateTime write SetDateTime;
    property DroppedDown: Boolean read FDroppedDown write SetDroppedDown;
    property Popup: TPPGCalendarPopup read FPopup;
  end;

  TPPGDatePicker = class(TPPGCustomDatePicker)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property TextHint;
    property ValidationState;
    property ValidationHint;
    property HighContrastSupport;
    { wie TDateTimePicker }
    property Align;
    property Anchors;
    property AutoSize default True;
    property BiDiMode;
    property BorderStyle;
    property CalAlignment;
    property Checked;
    property Color default clWindow;
    property Constraints;
    property Date;
    property DateFormat;
    property DateMode;
    property Enabled;
    property Font;
    property Format;
    property Kind;
    property MaxDate;
    property MinDate;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property ParseInput;
    property PopupMenu;
    property ShowCheckbox;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop;
    property Time;
    property Visible;
    property OnChange;
    property OnClick;
    property OnCloseUp;
    property OnContextPopup;
    property OnDropDown;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseEnter;
    property OnMouseLeave;
  end;

const
  /// Button-Ids des DatePickers.
  PPGDateButtonCalendar = 40;
  PPGDateButtonCheck = 41;

implementation

uses
  PPG.Lang,
  System.Math, System.DateUtils, Winapi.oleacc,
  PPG.Consts, PPG.Appearance, PPG.DpiUtils, PPG.Tokens, PPG.IconFont;

type
  TCalendarAccess = class(TPPGCalendar);

var
  GMsgDateToggle: Cardinal = 0;
  GMouseHook: HHOOK = 0;
  GOpenPicker: TPPGCustomDatePicker = nil;

function DateMouseHook(Code: Integer; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  Info: PMouseHookStruct;
  P: TPoint;
  R: TRect;
begin
  // Klick ausserhalb von Feld und Popup schliesst (asynchron per Nachricht)
  if (Code = HC_ACTION) and (GOpenPicker <> nil) then
    case WParam of
      WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN,
      WM_NCLBUTTONDOWN, WM_NCRBUTTONDOWN, WM_NCMBUTTONDOWN:
        begin
          Info := PMouseHookStruct(LParam);
          P := Info^.pt;
          GetWindowRect(GOpenPicker.Handle, R);
          if not PtInRect(R, P) and (GOpenPicker.Popup <> nil) and
            GOpenPicker.Popup.HandleAllocated then
          begin
            GetWindowRect(GOpenPicker.Popup.Handle, R);
            if not PtInRect(R, P) then
              PostMessage(GOpenPicker.Handle, GMsgDateToggle, 0, 1);
          end;
        end;
    end;
  Result := CallNextHookEx(GMouseHook, Code, WParam, LParam);
end;

{ TPPGCalendarPopup }

constructor TPPGCalendarPopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCalendar := TPPGCalendar.Create(Self);
  FCalendar.TabStop := False; // Fokus bleibt beim Feld
  FCalendar.ShowFocusAlways := True; // Tastatur kommt vom Feld: Fokus-Tag trotzdem zeigen
  FCalendar.Parent := Self;
end;

function TPPGCalendarPopup.PopupRounding: Integer;
begin
  Result := PPGScale(Tokens.RadiusLarge, ScalePPI);
end;

procedure TPPGCalendarPopup.Resize;
begin
  inherited Resize;
  // Kalender in voller Groesse; beim Aufklappen schneidet die Region ab
  if FCalendar <> nil then
    FCalendar.SetBounds(0, ContentOffset, Width, FullHeight);
end;

procedure TPPGCalendarPopup.ShowCalendar;
begin
  if not HandleAllocated then
    Exit;
  FCalendar.HandleNeeded;
  FCalendar.SetBounds(0, ContentOffset, Width, FullHeight);
  ShowWindow(FCalendar.Handle, SW_SHOWNA);
  FCalendar.Invalidate;
end;

procedure TPPGCalendarPopup.HideCalendar;
begin
  if FCalendar.HandleAllocated then
    ShowWindow(FCalendar.Handle, SW_HIDE);
end;

procedure TPPGCalendarPopup.SyncFrom(Source: TPPGCustomControl);
begin
  inherited SyncFrom(Source);
  FCalendar.Preset := Preset;
  FCalendar.StyleManager := StyleManager;
  FCalendar.Appearance := Appearance;
  FCalendar.Font := Font;
  FCalendar.BiDiMode := Source.BiDiMode;
end;

{ TPPGCustomDatePicker }

constructor TPPGCustomDatePicker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChecked := True;
  FDateTime := System.SysUtils.Date; // wie TDateTimePicker: heute
  if GMsgDateToggle = 0 then
    GMsgDateToggle := RegisterWindowMessage('PPGlow.DatePickerToggle');
  UpdateText;
end;

destructor TPPGCustomDatePicker.Destroy;
begin
  if GOpenPicker = Self then
  begin
    GOpenPicker := nil;
    if GMouseHook <> 0 then
    begin
      UnhookWindowsHookEx(GMouseHook);
      GMouseHook := 0;
    end;
  end;
  FreeAndNil(FPopup);
  inherited Destroy;
end;

procedure TPPGCustomDatePicker.Loaded;
begin
  inherited Loaded;
  UpdateText;
end;

function TPPGCustomDatePicker.HasDate: Boolean;
begin
  Result := (FDateTime <> 0) and (FChecked or not FShowCheckbox);
end;

function TPPGCustomDatePicker.FormatDate(D: TDate): string;
begin
  if D = 0 then
    Exit('');
  if FFormat <> '' then
    Result := FormatDateTime(FFormat, D)
  else if FDateFormat = dfLong then
    Result := FormatDateTime(FormatSettings.LongDateFormat, D)
  else
    Result := FormatDateTime(FormatSettings.ShortDateFormat, D);
end;

function TPPGCustomDatePicker.ParseDate(const S: string; out D: TDate): Boolean;
var
  FS: TFormatSettings;
  DT: TDateTime;
  T: string;
begin
  T := Trim(S);
  Result := False;
  D := 0;
  if T = '' then
    Exit;
  FS := FormatSettings;
  if FFormat <> '' then
  begin
    FS.ShortDateFormat := FFormat;
    if TryStrToDate(T, DT, FS) then
    begin
      D := Trunc(DT);
      Exit(True);
    end;
    FS := FormatSettings;
  end;
  if TryStrToDate(T, DT, FS) then
  begin
    D := Trunc(DT);
    Exit(True);
  end;
  // Das Langformat kann StrToDate nicht lesen; es wird nur angezeigt und beim
  // Bearbeiten im Kurzformat geschrieben (siehe FocusChanged).
end;

procedure TPPGCustomDatePicker.UpdateText;
begin
  Inc(FQuiet);
  try
    if FDateTime = 0 then
      Text := ''
    else if FEditing then
      Text := FormatDateTime(FormatSettings.ShortDateFormat, FDateTime)
    else
      Text := FormatDate(FDateTime);
  finally
    Dec(FQuiet);
  end;
  InvalidateInner;
  Invalidate;
end;

function TPPGCustomDatePicker.ClampToRange(D: TDate): TDate;
begin
  Result := Trunc(D);
  if (FMinDate <> 0) and (Result < Trunc(FMinDate)) then
    Result := Trunc(FMinDate);
  if (FMaxDate <> 0) and (Result > Trunc(FMaxDate)) then
    Result := Trunc(FMaxDate);
end;

function TPPGCustomDatePicker.GetDate: TDate;
begin
  Result := Trunc(FDateTime);
end;

procedure TPPGCustomDatePicker.SetDate(const Value: TDate);
begin
  if Value = 0 then
    SetDateTime(0)
  else
    SetDateTime(Trunc(Value) + Frac(FDateTime));
end;

function TPPGCustomDatePicker.GetTime: TTime;
begin
  Result := Frac(FDateTime);
end;

procedure TPPGCustomDatePicker.SetTime(const Value: TTime);
begin
  SetDateTime(Trunc(FDateTime) + Frac(Value));
end;

procedure TPPGCustomDatePicker.SetDateTime(const Value: TDateTime);
begin
  if FDateTime <> Value then
  begin
    FDateTime := Value;
    if not (csLoading in ComponentState) then
      UpdateText;
    NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
  end;
  if ValidationState = pvsError then
    ValidationState := pvsNone;
end;

procedure TPPGCustomDatePicker.SetMinDate(const Value: TDate);
begin
  FMinDate := Trunc(Value);
end;

procedure TPPGCustomDatePicker.SetMaxDate(const Value: TDate);
begin
  FMaxDate := Trunc(Value);
end;

procedure TPPGCustomDatePicker.SetShowCheckbox(const Value: Boolean);
begin
  if FShowCheckbox <> Value then
  begin
    FShowCheckbox := Value;
    UpdateLayout;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TPPGCustomDatePicker.SetChecked(const Value: Boolean);
begin
  if FChecked <> Value then
  begin
    FChecked := Value;
    UpdateColors;
    InvalidateInner;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
  end;
end;

procedure TPPGCustomDatePicker.SetDateFormat(const Value: TDTDateFormat);
begin
  if FDateFormat <> Value then
  begin
    FDateFormat := Value;
    UpdateText;
  end;
end;

procedure TPPGCustomDatePicker.SetFormat(const Value: string);
begin
  if FFormat <> Value then
  begin
    FFormat := Value;
    UpdateText;
  end;
end;

procedure TPPGCustomDatePicker.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  if not Enabled then
    CloseUp(False);
end;

{ ---- Eingabe ---- }

procedure TPPGCustomDatePicker.Change;
begin
  if FQuiet > 0 then
    Exit;
  // Getippt: pruefen erst beim Verlassen/Enter; ein alter Fehler verschwindet
  if ValidationState = pvsError then
    ValidationState := pvsNone;
end;

function TPPGCustomDatePicker.CommitText(UserAction: Boolean): Boolean;
var
  D: TDate;
  S: string;
begin
  S := Trim(Text);
  if S = '' then
  begin
    // Leer: nur mit Kontrollkaestchen erlaubt (= kein Datum)
    if FShowCheckbox then
    begin
      if FDateTime <> 0 then
      begin
        FDateTime := 0;
        if UserAction then
          UserChange;
      end;
      Exit(True);
    end;
    UpdateText; // altes Datum wieder anzeigen
    Exit(True);
  end;
  Result := ParseDate(S, D);
  if Result and (D <> ClampToRange(D)) then
    Result := False;
  if not Result then
  begin
    ValidationState := pvsError;
    Exit;
  end;
  if ValidationState = pvsError then
    ValidationState := pvsNone;
  if Trunc(FDateTime) <> D then
  begin
    if UserAction then
      UserSetDate(D)
    else
      SetDate(D);
  end
  else
    UpdateText;
end;

procedure TPPGCustomDatePicker.UserChange;
begin
  inherited Change;
end;

procedure TPPGCustomDatePicker.UserSetDate(D: TDate);
var
  Old: TDateTime;
begin
  Old := FDateTime;
  SetDate(D);
  if FShowCheckbox and not FChecked then
    SetChecked(True);
  if FDateTime <> Old then
    UserChange; // OnChange
end;

procedure TPPGCustomDatePicker.FieldKeyDown(var Key: Word; Shift: TShiftState);
var
  D: TDate;
begin
  if FDroppedDown and (FPopup <> nil) then
  begin
    case Key of
      VK_ESCAPE:
        CloseUp(False);
      VK_F4:
        CloseUp(False);
      VK_UP, VK_DOWN:
        if ssAlt in Shift then
          CloseUp(False)
        else
          TCalendarAccess(FPopup.Calendar).KeyDown(Key, Shift);
      VK_LEFT, VK_RIGHT, VK_PRIOR, VK_NEXT, VK_HOME, VK_END, VK_RETURN:
        TCalendarAccess(FPopup.Calendar).KeyDown(Key, Shift);
    else
      Exit;
    end;
    Key := 0;
    Exit;
  end;
  case Key of
    VK_F4:
      if Shift = [] then
        DropDown
      else
        Exit;
    VK_DOWN, VK_UP:
      if ssAlt in Shift then
      begin
        if Key = VK_DOWN then
          DropDown;
      end
      else if not ReadOnly then
      begin
        // Oben/Unten: Tag (Strg: Monat) ab dem eingegebenen bzw. heutigen Datum
        if not ParseDate(Text, D) then
          D := System.SysUtils.Date;
        if ssCtrl in Shift then
        begin
          if Key = VK_UP then
            D := IncMonth(D, 1)
          else
            D := IncMonth(D, -1);
        end
        else if Key = VK_UP then
          D := D + 1
        else
          D := D - 1;
        UserSetDate(ClampToRange(D));
        SelectAll;
      end;
    VK_RETURN:
      begin
        CommitText(True);
        SelectAll;
      end;
  else
    Exit;
  end;
  Key := 0;
end;

procedure TPPGCustomDatePicker.FieldKeyPress(var Key: Char);
begin
  if (Key = #13) or (Key = #27) then
  begin
    Key := #0; // kein Signalton
    Exit;
  end;
  // Nur Ziffern und Datumstrenner (Maske nach ShortDateFormat)
  if (Key >= #32) and not CharInSet(Key, ['0'..'9']) and (Key <> FormatSettings.DateSeparator) then
  begin
    if (FFormat = '') and (FDateFormat = dfShort) then
    begin
      MessageBeep(0);
      Key := #0;
    end;
  end;
end;

function TPPGCustomDatePicker.WantSpecialKey(Key: Word): Boolean;
begin
  Result := (Key = VK_RETURN) or (FDroppedDown and (Key = VK_ESCAPE));
end;

procedure TPPGCustomDatePicker.FocusChanged;
begin
  inherited FocusChanged;
  if csDestroying in ComponentState then
    Exit;
  if FieldFocused then
  begin
    // Bearbeiten im Kurzformat (Langformat laesst sich nicht zuverlaessig lesen)
    if not FEditing then
    begin
      FEditing := True;
      if (FFormat <> '') or (FDateFormat = dfLong) then
        UpdateText;
    end;
  end
  else
  begin
    if FDroppedDown then
      CloseUp(False);
    FEditing := False;
    if CommitText(True) then
      UpdateText;
  end;
end;

procedure TPPGCustomDatePicker.GetFieldColors(out Fill, Text: TColor);
begin
  inherited GetFieldColors(Fill, Text);
  // Ohne Haken gilt kein Datum: Text abgeblendet
  if FShowCheckbox and not FChecked then
    Text := PPGBlendColor(Text, Fill, 0.55);
end;

{ ---- Buttons ---- }

procedure TPPGCustomDatePicker.GetButtons(var Buttons: TPPGFieldButtons);
var
  N: Integer;
begin
  inherited GetButtons(Buttons);
  N := Length(Buttons);
  SetLength(Buttons, N + 1);
  Buttons[N].Id := PPGDateButtonCalendar;
  Buttons[N].Glyph := fgNone; // Kalender-Symbol zeichnet DoPaintField
  Buttons[N].ImageIndex := -1;
  Buttons[N].LeftSide := False;
  if FShowCheckbox then
  begin
    N := Length(Buttons);
    SetLength(Buttons, N + 1);
    Buttons[N].Id := PPGDateButtonCheck;
    Buttons[N].Glyph := fgNone;
    Buttons[N].ImageIndex := -1;
    Buttons[N].LeftSide := True;
  end;
end;

procedure TPPGCustomDatePicker.ButtonDown(Id: Integer);
begin
  if Id = PPGDateButtonCalendar then
  begin
    if FDroppedDown then
      CloseUp(False)
    else
      DropDown;
  end
  else
    inherited ButtonDown(Id);
end;

procedure TPPGCustomDatePicker.ButtonClick(Id: Integer);
begin
  if Id = PPGDateButtonCheck then
  begin
    SetChecked(not FChecked);
    UserChange; // Anwender hat umgeschaltet
    Exit;
  end;
  inherited ButtonClick(Id);
end;

{ ---- Popup ---- }

procedure TPPGCustomDatePicker.DropDown;
var
  P: TPoint;
  Anchor: TRect;
  W, H: Integer;
  D: TDate;
  Duration: Cardinal;
begin
  if FDroppedDown or not Enabled or ReadOnly or (csDesigning in ComponentState) or
    not HandleAllocated or not IsWindowVisible(Handle) then
    Exit;
  DoDropDown;
  if FDroppedDown or not HandleAllocated then
    Exit;
  if FPopup = nil then
  begin
    FPopup := TPPGCalendarPopup.Create(Self);
    FPopup.Calendar.OnChange := CalendarChange;
  end;
  FPopup.SyncFrom(Self);
  FPopup.Calendar.MinDate := FMinDate;
  FPopup.Calendar.MaxDate := FMaxDate;
  FPopup.Calendar.View := cvMonth;
  if not ParseDate(Text, D) then
    D := Trunc(FDateTime);
  if D = 0 then
    D := System.SysUtils.Date;
  FPopup.Calendar.Date := D;
  if not HasDate then
    FPopup.Calendar.ClearSelection;
  FPopup.Calendar.FocusDate := D;
  if Animation.EffectiveEnabled then
    Duration := Animation.Duration
  else
    Duration := 0;
  FPopup.Calendar.Animation.Enabled := Animation.Enabled;
  W := PPGScale(300, ScalePPI);
  H := PPGScale(330, ScalePPI);
  P := ClientToScreen(Point(0, 0));
  Anchor := Rect(P.X, P.Y, P.X + Width, P.Y + Height);
  FDroppedDown := True;
  FPopup.Popup(Anchor, W, H, (FCalAlignment = dtaRight) <> UseRightToLeftAlignment, Duration);
  FPopup.ShowCalendar;
  GOpenPicker := Self;
  if GMouseHook = 0 then
    GMouseHook := SetWindowsHookEx(WH_MOUSE, @DateMouseHook, 0, GetCurrentThreadId);
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
end;

procedure TPPGCustomDatePicker.CloseUp(Accept: Boolean);
var
  D: TDate;
begin
  if not FDroppedDown then
    Exit;
  FDroppedDown := False;
  if GOpenPicker = Self then
  begin
    GOpenPicker := nil;
    if GMouseHook <> 0 then
    begin
      UnhookWindowsHookEx(GMouseHook);
      GMouseHook := 0;
    end;
  end;
  D := 0;
  if FPopup <> nil then
  begin
    D := FPopup.Calendar.Date;
    FPopup.HideCalendar;
    FPopup.ClosePopup;
  end;
  CancelButtonPress;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
  if Accept and (D <> 0) then
  begin
    UserSetDate(D);
    if FieldFocused then
      SelectAll;
  end;
  DoCloseUp;
end;

procedure TPPGCustomDatePicker.CalendarChange(Sender: TObject);
begin
  // Tag im Popup gewaehlt (Klick oder Enter): uebernehmen und schliessen
  if FDroppedDown then
    CloseUp(True);
end;

procedure TPPGCustomDatePicker.SetDroppedDown(const Value: Boolean);
begin
  if Value then
    DropDown
  else
    CloseUp(False);
end;

procedure TPPGCustomDatePicker.DoDropDown;
begin
  if Assigned(FOnDropDown) then
    FOnDropDown(Self);
end;

procedure TPPGCustomDatePicker.DoCloseUp;
begin
  if Assigned(FOnCloseUp) then
    FOnCloseUp(Self);
end;

procedure TPPGCustomDatePicker.WndProc(var Message: TMessage);
begin
  if (GMsgDateToggle <> 0) and (Message.Msg = GMsgDateToggle) then
  begin
    // LParam 1: Klick ausserhalb (Hook), 0: Screenreader-Aktion
    if FDroppedDown then
      CloseUp(False)
    else if Message.LParam = 0 then
      DropDown;
    Exit;
  end;
  inherited WndProc(Message);
end;

{ ---- Zeichnen ---- }

procedure TPPGCustomDatePicker.DoPaintField(const ACanvas: IPPGCanvas;
  const Style: TPPGSurfaceStyle);
var
  R, B: TRect;
  PPI, W, S: Integer;
  Col: TColor;
begin
  inherited DoPaintField(ACanvas, Style);
  PPI := ScalePPI;
  Col := Style.TextColor;
  R := ButtonRect(PPGDateButtonCalendar);
  if not IsRectEmpty(R) then
    if not PPGDrawIcon(ACanvas, R, igCalendar, Col, PPGScale(12, PPI)) then
    begin
      // Ersatz: Kalenderblatt mit Kopfleiste
      S := PPGScale(11, PPI);
      B := Rect((R.Left + R.Right - S) div 2, (R.Top + R.Bottom - S) div 2,
        (R.Left + R.Right + S) div 2, (R.Top + R.Bottom + S) div 2);
      W := Max(1, PPGScale(1, PPI));
      ACanvas.FrameRoundRect(B, PPGScale(2, PPI), W, Col, 255);
      ACanvas.FillRoundRect(Rect(B.Left, B.Top, B.Right, B.Top + S div 3), 0, Col, 255);
    end;
  R := ButtonRect(PPGDateButtonCheck);
  if not IsRectEmpty(R) then
  begin
    S := PPGScale(14, PPI);
    B := Rect((R.Left + R.Right - S) div 2, (R.Top + R.Bottom - S) div 2,
      (R.Left + R.Right + S) div 2, (R.Top + R.Bottom + S) div 2);
    if FChecked then
    begin
      ACanvas.FillRoundRect(B, PPGScale(3, PPI), PPGColorToRGB(EffectiveAppearance.FocusColor), 255);
      PPGDrawIcon(ACanvas, B, igCheckMark, clWhite, PPGScale(10, PPI));
    end
    else
      ACanvas.FrameRoundRect(B, PPGScale(3, PPI), Max(1, PPGScale(1, PPI)), Col, 255);
  end;
end;

{ ---- Barrierefreiheit ---- }

function TPPGCustomDatePicker.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_COMBOBOX;
end;

function TPPGCustomDatePicker.AccValue: string;
begin
  if HasDate then
    Result := FormatDateTime(FormatSettings.LongDateFormat, FDateTime)
  else
    Result := '';
end;

function TPPGCustomDatePicker.AccState: Integer;
begin
  Result := inherited AccState;
  if FDroppedDown then
    Result := Result or STATE_SYSTEM_EXPANDED
  else
    Result := Result or STATE_SYSTEM_COLLAPSED;
end;

function TPPGCustomDatePicker.AccDefaultAction: string;
begin
  if FDroppedDown then
    Result := PPGStr(@SPPGAccClose)
  else
    Result := PPGStr(@SPPGAccOpen);
end;

procedure TPPGCustomDatePicker.AccDoDefaultAction;
begin
  if HandleAllocated then
    PostMessage(Handle, GMsgDateToggle, 0, 0);
end;

end.
