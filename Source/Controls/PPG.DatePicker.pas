unit PPG.DatePicker;

{ TPPGDatePicker - Datumsfeld mit Kalender-Popup (Phase 7b).

  - Basis TPPGCustomField: natives Edit fuer die Eingabe, Kalender-Button
    rechts, optional ein Kontrollkaestchen links (ShowCheckbox/Checked wie
    TDateTimePicker: ohne Haken gilt "kein Datum").
  - Eingabe: Ziffern und Datumstrenner; Oben/Unten aendern den Tag
    (Strg: Monat). Beim Verlassen bzw. Enter wird geprueft: gueltig =
    uebernehmen (OnChange), ungueltig = ValidationState pvsError, der Text
    bleibt zum Korrigieren stehen. Grenzen MinDate/MaxDate.
  - Popup: TPPGCalendar in einem Popup ohne Aktivierung, auf der gemeinsamen
    Aufklapp-Basis TPPGCustomDropDownField (Audit 7a #3): das Feld behaelt
    Fokus und Maus (SetCapture) und reicht Maus, Pfeile, Bild, Pos1/Ende und
    Enter an den Kalender weiter. Klick ausserhalb, Esc und Fokusverlust
    schliessen ohne Uebernahme; Klick auf einen Tag, Enter, F4 und Alt+Pfeil
    uebernehmen.
  - DFM-nah zu TDateTimePicker: Date, Time, MinDate, MaxDate, ShowCheckbox,
    Checked, DateFormat, Format, CalAlignment, Kind, DateMode, ParseInput.
  - Kind: dtkDate (Datum mit Kalender), dtkTime (Uhrzeit, Auf/Ab-Knoepfe),
    dtkDateTime (Datum und Uhrzeit). Oben/Unten, Auf/Ab und das Rad aendern
    in der Uhrzeit den Teil unter der Einfuegemarke (Stunde, Minute, Sekunde,
    AM/PM; Strg = Stunde, wie der TimePicker), im Datum den Tag (Strg: Monat).
    Ohne Fokus (Text im Anzeigeformat) bleibt es bei Minute bzw. Tag.
  - Das Rad aendert den Wert nur mit Fokus (Audit 7b).
  - DateMode = dmUpDown: Auf/Ab-Knoepfe statt Kalender (Tag, Strg = Monat).
  - ParseInput + OnUserInput: eigene Auswertung der Eingabe (wie
    TDateTimePicker.OnUserInput), z. B. "morgen" oder "+3".
  - Code (Date := ...) loest kein OnChange aus.

  Kalender-Popup ohne DatePicker (PPGShowCalendarPopup):
  - Oeffnet TPPGCalendarPopup unter einem beliebigen PPGlow-Control (Anker,
    z. B. ein TPPGEdit mit eigenem Kalender-Knopf) und kehrt erst nach dem
    Schliessen zurueck: True = Tag uebernommen (ADate = gewaehlter Tag, die
    Uhrzeit von ADate bleibt), False = abgebrochen (ADate unveraendert).
  - Startdatum = ADate (0 = heute), in MinDate..MaxDate geholt; Optik, Schrift,
    DPI und Animation vom Anker (SyncFrom wie bei den Aufklapp-Feldern).
    Kalenderwochen (ISO 8601) schaltbar, Grenzen optional.
  - Bedienung wie beim DatePicker: Klick auf einen Tag bzw. Enter uebernimmt,
    Pfeile/Bild/Pos1/Ende bewegen den Fokus-Tag, F4 und Alt+Pfeil uebernehmen
    einen bewegten Fokus-Tag. Esc, Tab, Alt, Klick daneben (verbraucht),
    Fokuswechsel, Deaktivieren der Anwendung sowie Verstecken, Minimieren
    oder Freigeben von Anker bzw. Formular brechen ab.
  - Modal wie TPPGPopupMenu.Popup: eine Nachrichtenschleife
    (Application.HandleMessage), Tasten und Maus laufen ueber PPG.AppHooks
    (auch wenn die Anwendung Application.OnMessage selbst setzt). Das Popup
    wird nie aktiviert, der Fokus bleibt beim Anker. Release (caFree) des
    Formulars waehrend das Popup offen ist, wird bis nach der Rueckkehr
    verschoben. Besitzer ist das oberste Fenster des Ankers (bei MDI das
    Hauptformular). Nur ein Popup gleichzeitig: ein neuer Aufruf bricht das
    offene ab. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.ComCtrls,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Controls.Base, PPG.Controls.Field,
  PPG.Controls.DropDown, PPG.Popup, PPG.Calendar;

type
  TPPGCustomDatePicker = class;

  /// Popup mit Kalender (DatePicker bzw. PPGShowCalendarPopup). Maus und
  /// Tastatur kommen ueber die Drop*-Methoden vom Feld bzw. von der Schleife
  /// von PPGShowCalendarPopup (Audit 7a #3).
  TPPGCalendarPopup = class(TPPGDropPopup)
  private
    FCalendar: TPPGCalendar;
    FPicked: Boolean;
    FStartFocus: TDate;
    FMouseDown: Boolean;
    FDownDay: TDate;
    FForwarding: Integer;
    FOnDirectPick: TNotifyEvent;
    procedure CalendarChange(Sender: TObject);
    function CalPoint(X, Y: Integer): TPoint;
    function DayAt(X, Y: Integer): TDate;
    procedure SendMouse(Msg: Cardinal; Keys: WPARAM; X, Y: Integer);
  protected
    function PopupRounding: Integer; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SyncFrom(Source: TPPGCustomControl); override;
    /// Vor dem Zeigen: noch nichts gewaehlt, Ausgangspunkt der Tastatur.
    procedure StartPick;
    function PreferredSize(FieldWidth: Integer): TSize; override;
    procedure DropMouseMove(X, Y: Integer; Shift: TShiftState); override;
    function DropMouseDown(X, Y: Integer): TPPGDropAction; override;
    /// Loslassen auf einem Tag: uebernehmen (auch den schon gewaehlten).
    function DropMouseUp(X, Y: Integer): TPPGDropAction; override;
    /// Pfeile, Bild, Pos1/Ende bewegen den Fokus-Tag, Enter waehlt.
    function DropKeyDown(var Key: Word; Shift: TShiftState): TPPGDropAction; override;
    procedure DropWheel(Delta: Integer); override;
    procedure DropMouseLeave; override;
    /// Kalenderfenster zeigen bzw. verstecken. Das Popup hat keinen Parent, die
    /// VCL fuehrt deshalb kein UpdateShowing fuer seine Kinder aus.
    procedure ShowCalendar;
    procedure HideCalendar;
    property Calendar: TPPGCalendar read FCalendar;
    /// Ein Tag wurde gewaehlt (Klick bzw. Enter).
    property Picked: Boolean read FPicked;
    /// Fokus-Tag beim Aufklappen.
    property StartFocus: TDate read FStartFocus;
    /// Tag direkt am Kalender gewaehlt (nicht ueber Drop*, z. B. per
    /// Automation): der Besitzer uebernimmt und schliesst.
    property OnDirectPick: TNotifyEvent read FOnDirectPick write FOnDirectPick;
  end;

  /// Einstellungen fuer PPGShowCalendarPopup (Vorgabe: PPGCalendarPopupOptions).
  TPPGCalendarPopupOptions = record
    /// Kalenderwochen (ISO 8601) zeigen.
    ShowWeekNumbers: Boolean;
    /// Fruehester bzw. spaetester waehlbarer Tag (0 = keine Grenze).
    MinDate: TDate;
    MaxDate: TDate;
    /// Lage zum Anker, wenn das Popup breiter ist: links (Vorgabe), rechts, mittig.
    Alignment: TAlignment;
    /// Bereiche des Kalenders (nil = Preset); gehoeren dem Aufrufer.
    Styles: TPPGCalendarStyles;
    /// Eigenes Zeichnen der Tage (optional).
    OnCustomDrawDay: TPPGCalendarDrawDayEvent;
  end;

  TPPGCustomDatePicker = class(TPPGCustomDropDownField)
  private
    FDateTime: TDateTime;   // 0 = kein Datum
    FCalendarStyles: TPPGCalendarStyles;
    FOnCustomDrawDay: TPPGCalendarDrawDayEvent;
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
    FOnUserInput: TDTParseInputEvent;
    FQuiet: Integer;
    FEditing: Boolean;
    procedure SetCalendarStyles(const Value: TPPGCalendarStyles);
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
    procedure SetKind(const Value: TDateTimeKind);
    procedure SetDateMode(const Value: TDTDateMode);
    function TimeMode: Boolean;
    function DateTimeMode: Boolean;
    /// Auf/Ab-Knoepfe statt Kalender (Uhrzeit oder DateMode = dmUpDown).
    function SpinMode: Boolean;
    function EditFormatted(const DT: TDateTime): string;
    /// Oben/Unten bzw. Auf/Ab: Tag/Monat oder Minute/Stunde weiterzaehlen.
    procedure StepValue(Delta: Integer; Coarse: Boolean);
    /// Teil der Uhrzeit unter der Einfuegemarke (nur beim Bearbeiten im Feld;
    /// False = Datumsteil bzw. kein Bearbeitungstext).
    function TimeSegmentAtCaret(out Segment: Integer): Boolean;
    /// Oben/Unten, Auf/Ab und Rad: Teil unter der Marke bzw. Tag/Monat.
    procedure StepAtCaret(Delta: Integer; Coarse: Boolean);
    function GetDroppedDown: Boolean;
    procedure SetDroppedDown(const Value: Boolean);
    function GetCalendarPopup: TPPGCalendarPopup;
    procedure PopupDirectPick(Sender: TObject);
    procedure UpdateText;
    function ClampToRange(D: TDate): TDate;
    procedure ApplyDateRange;
  protected
    procedure Loaded; override;
    procedure GetButtons(var Buttons: TPPGFieldButtons); override;
    procedure ButtonClick(Id: Integer); override;
    procedure ClosedKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure FieldKeyPress(var Key: Char); override;
    function InputPending: Boolean; override;
    { Aufklapp-Basis }
    function CreatePopup: TPPGDropPopup; override;
    procedure PreparePopup(APopup: TPPGDropPopup); override;
    procedure AcceptPopup(APopup: TPPGDropPopup); override;
    function CanDropDown: Boolean; override;
    procedure PopupOpened; override;
    procedure PopupClosed; override;
    procedure FocusChanged; override;
    procedure Change; override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    procedure GetFieldColors(out Fill, Text: TColor); override;
    procedure DoPaintField(const ACanvas: IPPGCanvas; const Style: TPPGSurfaceStyle); override;
    function AccValue: string; override;
    /// Text des Edits pruefen und uebernehmen (True = gueltig oder leer erlaubt).
    function CommitText(UserAction: Boolean): Boolean;
    /// Datum durch den Anwender setzen (OnChange).
    procedure UserSetDate(D: TDate);
    procedure UserSetDateTime(const DT: TDateTime);
    /// Anwender hat Datum oder Kaestchen geaendert: loest OnChange aus.
    /// DB-Variante: Datensatz vorher in den Bearbeiten-Modus setzen.
    procedure UserChange; virtual;
    property Date: TDate read GetDate write SetDate;
    property Time: TTime read GetTime write SetTime;
    property MinDate: TDate read FMinDate write SetMinDate;
    property MaxDate: TDate read FMaxDate write SetMaxDate;
    property ShowCheckbox: Boolean read FShowCheckbox write SetShowCheckbox default False;
    /// Bereiche des aufklappenden Kalenders.
    property Styles: TPPGCalendarStyles read FCalendarStyles write SetCalendarStyles;
    /// Vor dem Zeichnen jedes Tages im aufklappenden Kalender.
    property OnCustomDrawDay: TPPGCalendarDrawDayEvent read FOnCustomDrawDay write FOnCustomDrawDay;
    property Checked: Boolean read FChecked write SetChecked default True;
    property DateFormat: TDTDateFormat read FDateFormat write SetDateFormat default dfShort;
    /// Anzeigeformat (FormatDateTime), leer = DateFormat.
    property Format: string read FFormat write SetFormat;
    /// dtkDate = Datum mit Kalender, dtkTime = Uhrzeit (Auf/Ab), dtkDateTime = beides.
    property Kind: TDateTimeKind read FKind write SetKind default dtkDate;
    /// dmComboBox = Kalender zum Aufklappen, dmUpDown = Auf/Ab-Knoepfe.
    property DateMode: TDTDateMode read FDateMode write SetDateMode default dmComboBox;
    property CalAlignment: TDTCalAlignment read FCalAlignment write FCalAlignment default dtaLeft;
    /// True: Eingaben zuerst an OnUserInput geben (eigene Auswertung).
    property ParseInput: Boolean read FParseInput write FParseInput default False;
    property OnUserInput: TDTParseInputEvent read FOnUserInput write FOnUserInput;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Text, wie er fuer ein Datum angezeigt wird.
    function FormatDate(D: TDate): string;
    /// Anzeige des Werts nach Kind (Datum, Uhrzeit oder beides).
    function FormatValue(const DT: TDateTime): string;
    /// Text nach Kind lesen (Uhrzeit: Datumsteil des aktuellen Werts bzw. heute).
    function ParseValue(const S: string; out DT: TDateTime): Boolean;
    /// Text in ein Datum wandeln (Anzeigeformat, dann Kurzformat).
    function ParseDate(const S: string; out D: TDate): Boolean;
    /// True, wenn ein Datum gilt (Checked und nicht leer).
    function HasDate: Boolean;
    property DateTime: TDateTime read FDateTime write SetDateTime;
    property DroppedDown: Boolean read GetDroppedDown write SetDroppedDown;
    /// Das Kalender-Popup (nil vor dem ersten Aufklappen).
    property Popup: TPPGCalendarPopup read GetCalendarPopup;
  end;

  TPPGDatePicker = class(TPPGCustomDatePicker)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property TextHint;
    property UseSystemContextMenu;
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
    property Styles;
    property OnCustomDrawDay;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop;
    property Time;
    property Visible;
    property Touch;
    property OnGesture;
    property OnChange;
    property OnClick;
    property OnCloseUp;
    property OnContextPopup;
    property OnDropDown;
    property OnUserInput;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseEnter;
    property OnMouseLeave;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseActivate;
    property DragMode;
    property DragCursor;
    property OnDragDrop;
    property OnDragOver;
    property OnStartDrag;
    property OnEndDrag;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
    // Audit 5d Stufe 3: wie VCL
    property TextHintVisibleOnFocus;
  end;

const
  /// Button-Ids des DatePickers.
  PPGDateButtonCalendar = 40;
  PPGDateButtonCheck = 41;
  PPGDateButtonUp = 42;
  PPGDateButtonDown = 43;

/// Vorgabe-Einstellungen: ohne Grenzen, links am Anker, Stile des Presets.
function PPGCalendarPopupOptions(ShowWeekNumbers: Boolean = False; MinDate: TDate = 0;
  MaxDate: TDate = 0): TPPGCalendarPopupOptions;
/// Kalender-Popup unter Anchor zeigen und warten, bis es schliesst (siehe
/// Unit-Kopf). True = Tag gewaehlt: ADate = Tag + Uhrzeit von ADate.
/// False = abgebrochen bzw. Anker nicht sichtbar: ADate bleibt.
function PPGShowCalendarPopup(Anchor: TPPGCustomControl; var ADate: TDateTime;
  const Options: TPPGCalendarPopupOptions): Boolean; overload;
function PPGShowCalendarPopup(Anchor: TPPGCustomControl; var ADate: TDateTime;
  ShowWeekNumbers: Boolean = False): Boolean; overload;
/// Das offene Popup von PPGShowCalendarPopup (nil = keins); Tests, Diagnose.
function PPGActiveCalendarPopup: TPPGCalendarPopup;
/// Offenes Popup von PPGShowCalendarPopup ohne Uebernahme schliessen.
procedure PPGCloseCalendarPopup;

implementation

uses
  PPG.Lang,
  System.Math, System.DateUtils, Winapi.oleacc, Vcl.Forms,
  PPG.Consts, PPG.Appearance, PPG.DpiUtils, PPG.Tokens, PPG.IconFont, PPG.TimePicker,
  PPG.AppHooks, PPG.Popup.Placement;

type
  TCalendarAccess = class(TPPGCalendar);
  TAnchorAccess = class(TPPGCustomControl);

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

{ TPPGCalendarPopup }

constructor TPPGCalendarPopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCalendar := TPPGCalendar.Create(Self);
  FCalendar.TabStop := False; // Fokus bleibt beim Feld
  FCalendar.ShowFocusAlways := True; // Tastatur kommt vom Feld: Fokus-Tag trotzdem zeigen
  // Die Maus haelt das Feld (SetCapture); der Kalender darf sie nicht an sich ziehen
  FCalendar.ControlStyle := FCalendar.ControlStyle - [csCaptureMouse];
  FCalendar.Parent := Self;
  FCalendar.OnChange := CalendarChange;
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

procedure TPPGCalendarPopup.StartPick;
begin
  FPicked := False;
  FMouseDown := False;
  FStartFocus := Trunc(FCalendar.FocusDate);
end;

procedure TPPGCalendarPopup.CalendarChange(Sender: TObject);
begin
  FPicked := True;
  // Direkt am Kalender gewaehlt (nicht ueber das Feld, z.B. per Automation):
  // der Besitzer uebernimmt wie bei einem Klick und schliesst
  if (FForwarding = 0) and Assigned(FOnDirectPick) then
    FOnDirectPick(Self);
end;

function TPPGCalendarPopup.PreferredSize(FieldWidth: Integer): TSize;
begin
  Result.cx := PPGScale(300, ScalePPI);
  // Kalenderwochen: eine achte Spalte, die Tage behalten ihre Breite
  if FCalendar.ShowWeekNumbers then
    Result.cx := Result.cx * 8 div 7;
  Result.cy := PPGScale(330, ScalePPI);
end;

function TPPGCalendarPopup.CalPoint(X, Y: Integer): TPoint;
begin
  Result := Point(X - FCalendar.Left, Y - FCalendar.Top);
end;

function TPPGCalendarPopup.DayAt(X, Y: Integer): TDate;
var
  I: Integer;
  P: TPoint;
begin
  // Tag unter dem Punkt (Popup-Koordinaten), nur in der Monatsansicht
  Result := 0;
  if FCalendar.View <> cvMonth then
    Exit;
  P := CalPoint(X, Y);
  for I := 0 to 41 do
    if PtInRect(FCalendar.CellRect(I), P) then
      Exit(Trunc(FCalendar.CellDate(I)));
end;

procedure TPPGCalendarPopup.SendMouse(Msg: Cardinal; Keys: WPARAM; X, Y: Integer);
var
  P: TPoint;
begin
  // Ueber die Nachrichten (nicht MouseDown/MouseUp direkt): so laufen auch die
  // Zustaende der Basis (gedrueckt, Hover) und die Maus-Ereignisse mit
  P := CalPoint(X, Y);
  Inc(FForwarding);
  try
    FCalendar.Perform(Msg, Keys, MouseLParam(P.X, P.Y));
  finally
    Dec(FForwarding);
  end;
end;

procedure TPPGCalendarPopup.DropMouseMove(X, Y: Integer; Shift: TShiftState);
var
  Keys: WPARAM;
begin
  Keys := 0;
  if ssLeft in Shift then
    Keys := MK_LBUTTON;
  SendMouse(WM_MOUSEMOVE, Keys, X, Y);
end;

function TPPGCalendarPopup.DropMouseDown(X, Y: Integer): TPPGDropAction;
begin
  FMouseDown := True;
  FDownDay := DayAt(X, Y);
  SendMouse(WM_LBUTTONDOWN, MK_LBUTTON, X, Y);
  Result := pdaKeepOpen;
end;

function TPPGCalendarPopup.DropMouseUp(X, Y: Integer): TPPGDropAction;
var
  Day: TDate;
begin
  Result := pdaNone;
  // Der oeffnende Klick (auf dem Feld) endet hier ebenfalls: nichts tun
  if not FMouseDown then
    Exit;
  FMouseDown := False;
  Day := DayAt(X, Y);
  SendMouse(WM_LBUTTONUP, 0, X, Y);
  if FPicked then
    Result := pdaAccept
  else if (Day <> 0) and (Day = FDownDay) and (Day = Trunc(FCalendar.Date)) then
    Result := pdaAccept; // der schon gewaehlte Tag: schliessen wie Windows
end;

function TPPGCalendarPopup.DropKeyDown(var Key: Word; Shift: TShiftState): TPPGDropAction;
var
  WasMonth: Boolean;
  K: Word;
begin
  Result := pdaNone;
  K := Key; // der Kalender setzt Key auf 0
  case K of
    VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT, VK_HOME, VK_END, VK_RETURN:
      begin
        WasMonth := FCalendar.View = cvMonth;
        Inc(FForwarding);
        try
          TCalendarAccess(FCalendar).KeyDown(Key, Shift);
        finally
          Dec(FForwarding);
        end;
        Result := pdaKeepOpen;
        // Enter waehlt den Fokus-Tag; auch der schon gewaehlte schliesst.
        // In Jahr/Jahrzehnt zoomt Enter nur hinein.
        if K = VK_RETURN then
          if FPicked or (WasMonth and (Trunc(FCalendar.FocusDate) = Trunc(FCalendar.Date))) then
            Result := pdaAccept;
        Key := 0;
      end;
  end;
end;

procedure TPPGCalendarPopup.DropWheel(Delta: Integer);
var
  N: Integer;
begin
  N := WheelSteps(Delta); // eine Seite je Raste (Audit 7b)
  while N > 0 do
  begin
    FCalendar.PrevPage;
    Dec(N);
  end;
  while N < 0 do
  begin
    FCalendar.NextPage;
    Inc(N);
  end;
end;

procedure TPPGCalendarPopup.DropMouseLeave;
begin
  FCalendar.Perform(CM_MOUSELEAVE, 0, 0);
end;

procedure TPPGCalendarPopup.SyncFrom(Source: TPPGCustomControl);
begin
  inherited SyncFrom(Source);
  if Source = nil then
    Exit;
  FCalendar.Preset := Preset;
  FCalendar.StyleManager := StyleManager;
  FCalendar.Appearance := Appearance;
  FCalendar.Font := Font;
  FCalendar.BiDiMode := Source.BiDiMode;
  // Stile und eigenes Zeichnen der Tage setzt der Besitzer (DatePicker:
  // PreparePopup, PPGShowCalendarPopup: Options)
end;

procedure TPPGCustomDatePicker.SetCalendarStyles(const Value: TPPGCalendarStyles);
begin
  FCalendarStyles.Assign(Value);
end;

{ TPPGCustomDatePicker }

constructor TPPGCustomDatePicker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChecked := True;
  FDateTime := System.SysUtils.Date; // wie TDateTimePicker: heute
  FCalendarStyles := TPPGCalendarStyles.Create(Self);
  UpdateText;
end;

destructor TPPGCustomDatePicker.Destroy;
begin
  // Das Popup gehoert dem Feld (Owner); die Basis schliesst es ohne Ereignisse
  inherited Destroy;
  FreeAndNil(FCalendarStyles);
end;

procedure TPPGCustomDatePicker.Loaded;
begin
  inherited Loaded;
  ApplyDateRange;
  UpdateText;
end;

function TPPGCustomDatePicker.HasDate: Boolean;
begin
  Result := (FDateTime <> 0) and (FChecked or not FShowCheckbox);
end;

function TPPGCustomDatePicker.TimeMode: Boolean;
begin
  Result := FKind = dtkTime;
end;

function TPPGCustomDatePicker.DateTimeMode: Boolean;
begin
  // dtkDateTime gibt es nicht in allen Delphi-Versionen: ueber Ord pruefen
  Result := Ord(FKind) > Ord(dtkTime);
end;

function TPPGCustomDatePicker.SpinMode: Boolean;
begin
  Result := TimeMode or (FDateMode = dmUpDown);
end;

procedure TPPGCustomDatePicker.SetKind(const Value: TDateTimeKind);
begin
  if FKind <> Value then
  begin
    FKind := Value;
    if DroppedDown and SpinMode then
      CloseUp(False);
    UpdateLayout; // Knoepfe: Kalender bzw. Auf/Ab
    if not (csLoading in ComponentState) then
      UpdateText;
  end;
end;

procedure TPPGCustomDatePicker.SetDateMode(const Value: TDTDateMode);
begin
  if FDateMode <> Value then
  begin
    FDateMode := Value;
    if DroppedDown and SpinMode then
      CloseUp(False);
    UpdateLayout;
  end;
end;

function TPPGCustomDatePicker.FormatValue(const DT: TDateTime): string;
begin
  if DT = 0 then
    Exit('');
  if TimeMode then
  begin
    if FFormat <> '' then
      Result := FormatDateTime(FFormat, DT)
    else
      Result := FormatDateTime(FormatSettings.LongTimeFormat, DT);
  end
  else if DateTimeMode then
  begin
    if FFormat <> '' then
      Result := FormatDateTime(FFormat, DT)
    else
      Result := FormatDate(Trunc(DT)) + ' ' + FormatDateTime(FormatSettings.ShortTimeFormat, DT);
  end
  else
    Result := FormatDate(Trunc(DT));
end;

function TPPGCustomDatePicker.EditFormatted(const DT: TDateTime): string;
begin
  // Bearbeiten in Formaten, die sich sicher zuruecklesen lassen
  if TimeMode then
    Result := FormatDateTime(FormatSettings.LongTimeFormat, DT)
  else if DateTimeMode then
    Result := FormatDateTime(FormatSettings.ShortDateFormat, DT) + ' ' +
      FormatDateTime(FormatSettings.ShortTimeFormat, DT)
  else
    Result := FormatDateTime(FormatSettings.ShortDateFormat, DT);
end;

function TPPGCustomDatePicker.ParseValue(const S: string; out DT: TDateTime): Boolean;
var
  D: TDate;
  T: TDateTime;
  Base: TDateTime;
  FS: TFormatSettings;
begin
  DT := 0;
  if TimeMode then
  begin
    FS := FormatSettings;
    Result := TryStrToTime(Trim(S), T, FS);
    if not Result and (FFormat <> '') then
    begin
      FS.LongTimeFormat := FFormat;
      Result := TryStrToTime(Trim(S), T, FS);
    end;
    if Result then
    begin
      Base := Trunc(FDateTime);
      if Base = 0 then
        Base := System.SysUtils.Date;
      DT := Base + Frac(T);
    end;
  end
  else if DateTimeMode then
  begin
    Result := TryStrToDateTime(Trim(S), T);
    if Result then
      DT := T
    else
    begin
      // nur ein Datum eingegeben: Uhrzeit beibehalten
      Result := ParseDate(S, D);
      if Result then
        DT := D + Frac(FDateTime);
    end;
  end
  else
  begin
    Result := ParseDate(S, D);
    if Result then
      DT := D;
  end;
end;

procedure TPPGCustomDatePicker.StepValue(Delta: Integer; Coarse: Boolean);
var
  DT: TDateTime;
begin
  if not ParseValue(Text, DT) then
  begin
    DT := FDateTime;
    if DT = 0 then
      DT := Now;
  end;
  if TimeMode then
  begin
    // Minute bzw. (Strg) Stunde, innerhalb des Tages umlaufend
    if Coarse then
      DT := Trunc(DT) + Frac(Frac(DT) + Delta / 24 + 1)
    else
      DT := Trunc(DT) + Frac(Frac(DT) + Delta / (24 * 60) + 1);
    UserSetDateTime(RecodeMilliSecond(DT, 0));
  end
  else
  begin
    if Coarse then
      DT := IncMonth(DT, Delta)
    else
      DT := DT + Delta;
    UserSetDateTime(ClampToRange(Trunc(DT)) + Frac(DT));
  end;
end;

function TPPGCustomDatePicker.TimeSegmentAtCaret(out Segment: Integer): Boolean;
var
  S: string;
  Caret, TimeStart: Integer;
begin
  // Audit 7c #6: Segmente wie im TimePicker. Nur im Bearbeitungsformat
  // (EditFormatted) ist die Lage der Teile bekannt.
  Result := False;
  Segment := 1;
  if not FEditing or (FDateTime = 0) then
    Exit;
  S := Text;
  Caret := SelStart;
  if TimeMode then
  begin
    Segment := PPGTimeSegmentAt(S, Caret, True);
    Result := True;
  end
  else if DateTimeMode then
  begin
    // "Datum Uhrzeit": die Uhrzeit beginnt hinter dem Leerzeichen nach dem Datum
    TimeStart := Length(FormatDateTime(FormatSettings.ShortDateFormat, FDateTime)) + 1;
    if (Caret >= TimeStart) and (Length(S) > TimeStart) and (S[TimeStart] = ' ') then
    begin
      Segment := PPGTimeSegmentAt(Copy(S, TimeStart + 1, MaxInt), Caret - TimeStart, False);
      Result := True;
    end;
  end;
end;

procedure TPPGCustomDatePicker.StepAtCaret(Delta: Integer; Coarse: Boolean);
var
  Seg, Caret: Integer;
  DT: TDateTime;
begin
  if not TimeSegmentAtCaret(Seg) then
  begin
    StepValue(Delta, Coarse);
    if FEditing then
      SelectAll;
    Exit;
  end;
  if Coarse then
    Seg := 0; // Strg: Stunde
  if not ParseValue(Text, DT) then
    DT := FDateTime;
  Caret := SelStart;
  UserSetDateTime(Trunc(DT) + PPGStepTimeSegment(DT, Seg, Delta));
  SelStart := Caret; // Einfuegemarke im selben Teil lassen
end;

function TPPGCustomDatePicker.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
var
  N: Integer;
begin
  // Offen: die Basis blaettert den Kalender; OnMouseWheel kommt zuerst
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  // Audit 7b/7c #6: nur mit Fokus, Teil unter der Einfuegemarke
  if Result or DroppedDown or ReadOnly or not Enabled or not FieldFocused or
    (WheelDelta = 0) then
    Exit;
  N := WheelSteps(WheelDelta);
  if N <> 0 then
    StepAtCaret(N, ssCtrl in Shift);
  Result := True;
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
      Text := EditFormatted(FDateTime)
    else
      Text := FormatValue(FDateTime);
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
var
  V: TDate;
begin
  V := Trunc(Value);
  if V = FMinDate then
    Exit;
  FMinDate := V;
  // Wie DayStartHour/DayEndHour im Planer: die Gegenseite folgt, damit nie
  // MinDate > MaxDate gilt (0 = keine Grenze). Beim Laden kommen beide
  // nacheinander, das Ergebnis stimmt danach wieder.
  if (FMinDate <> 0) and (FMaxDate <> 0) and (FMaxDate < FMinDate) then
    FMaxDate := FMinDate;
  ApplyDateRange;
end;

procedure TPPGCustomDatePicker.SetMaxDate(const Value: TDate);
var
  V: TDate;
begin
  V := Trunc(Value);
  if V = FMaxDate then
    Exit;
  FMaxDate := V;
  if (FMinDate <> 0) and (FMaxDate <> 0) and (FMinDate > FMaxDate) then
    FMinDate := FMaxDate;
  ApplyDateRange;
end;

procedure TPPGCustomDatePicker.ApplyDateRange;
var
  D: TDate;
begin
  // Datum in den Bereich holen, die Uhrzeit bleibt (Audit 08.10.2026: ein
  // Datum ausserhalb von MinDate..MaxDate blieb stehen). Reine Zeitfelder
  // haben keinen Datumsbereich.
  if (csLoading in ComponentState) or (FDateTime = 0) or TimeMode then
    Exit;
  D := ClampToRange(FDateTime);
  if D <> Trunc(FDateTime) then
    SetDateTime(D + Frac(FDateTime));
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
  DT: TDateTime;
  S: string;
  Allow: Boolean;
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
  Result := ParseValue(S, DT);
  // Eigene Auswertung (TDateTimePicker.OnUserInput): vorbelegt mit dem gelesenen
  // bzw. bisherigen Wert; AllowChange = False lehnt ab
  if FParseInput and Assigned(FOnUserInput) then
  begin
    if not Result then
      DT := FDateTime;
    Allow := True;
    FOnUserInput(Self, S, DT, Allow);
    Result := Allow;
  end;
  if Result and (Trunc(DT) <> ClampToRange(DT)) and not TimeMode then
    Result := False;
  if not Result then
  begin
    ValidationState := pvsError;
    Exit;
  end;
  if ValidationState = pvsError then
    ValidationState := pvsNone;
  if not TimeMode and not DateTimeMode then
    DT := Trunc(DT) + Frac(FDateTime);
  if FDateTime <> DT then
  begin
    if UserAction then
      UserSetDateTime(DT)
    else
      SetDateTime(DT);
  end
  else
    UpdateText;
end;

procedure TPPGCustomDatePicker.UserChange;
begin
  inherited Change;
end;

procedure TPPGCustomDatePicker.UserSetDateTime(const DT: TDateTime);
var
  Old: TDateTime;
begin
  Old := FDateTime;
  SetDateTime(DT);
  if FShowCheckbox and not FChecked then
    SetChecked(True);
  if FDateTime <> Old then
    UserChange; // OnChange
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

procedure TPPGCustomDatePicker.ClosedKeyDown(var Key: Word; Shift: TShiftState);
begin
  // Auf-/Zuklappen (F4, Alt+Pfeil) und die Tasten bei offenem Kalender
  // erledigt die Aufklapp-Basis
  case Key of
    VK_DOWN, VK_UP:
      if ReadOnly then
        Exit
      else
      begin
        // Oben/Unten: Teil der Uhrzeit unter der Marke bzw. Tag/Monat
        StepAtCaret(1 - 2 * Ord(Key = VK_DOWN), ssCtrl in Shift);
      end;
    VK_RETURN:
      // Nur getippten Text uebernehmen; sonst bleibt Enter frei (Audit 7a #2)
      if InputPending then
      begin
        CommitText(True);
        SelectAll;
      end
      else
        Exit;
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
  // Nur Ziffern und Datumstrenner (Maske nach ShortDateFormat); Uhrzeit, eigene
  // Formate und eigene Auswertung (ParseInput) frei
  if (Key >= #32) and not CharInSet(Key, ['0'..'9']) and (Key <> FormatSettings.DateSeparator) then
  begin
    if (FFormat = '') and (FDateFormat = dfShort) and (FKind = dtkDate) and not FParseInput then
    begin
      MessageBeep(0);
      Key := #0;
    end;
  end;
end;

function TPPGCustomDatePicker.InputPending: Boolean;
begin
  if FDateTime = 0 then
    Result := Trim(Text) <> ''
  else if FEditing then
    Result := Trim(Text) <> Trim(EditFormatted(FDateTime))
  else
    Result := Trim(Text) <> Trim(FormatValue(FDateTime));
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
    // Ein offener Kalender ist schon zu (Basis)
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
  N, I, J: Integer;
begin
  inherited GetButtons(Buttons); // mit dem Aufklapp-Knopf der Basis (Id 40)
  N := Length(Buttons);
  if SpinMode then
  begin
    // Auf/Ab statt Kalender: den Aufklapp-Knopf entfernen
    for I := N - 1 downto 0 do
      if Buttons[I].Id = PPGDropButton then
      begin
        for J := I to N - 2 do
          Buttons[J] := Buttons[J + 1];
        Dec(N);
      end;
    SetLength(Buttons, N + 2);
    Buttons[N].Id := PPGDateButtonDown;
    Buttons[N].Glyph := fgSpinDown;
    Buttons[N].ImageIndex := -1;
    Buttons[N].LeftSide := False;
    Buttons[N + 1].Id := PPGDateButtonUp;
    Buttons[N + 1].Glyph := fgSpinUp;
    Buttons[N + 1].ImageIndex := -1;
    Buttons[N + 1].LeftSide := False;
  end
  else
    for I := 0 to N - 1 do
      if Buttons[I].Id = PPGDropButton then
        Buttons[I].Glyph := fgNone; // Kalender-Symbol zeichnet DoPaintField
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

procedure TPPGCustomDatePicker.ButtonClick(Id: Integer);
begin
  if (Id = PPGDateButtonUp) or (Id = PPGDateButtonDown) then
  begin
    if not ReadOnly then
      StepAtCaret(1 - 2 * Ord(Id = PPGDateButtonDown), GetKeyState(VK_CONTROL) < 0);
    Exit;
  end;
  if Id = PPGDateButtonCheck then
  begin
    SetChecked(not FChecked);
    UserChange; // Anwender hat umgeschaltet
    Exit;
  end;
  inherited ButtonClick(Id);
end;

{ ---- Popup (Aufklapp-Basis) ---- }

function TPPGCustomDatePicker.CreatePopup: TPPGDropPopup;
var
  P: TPPGCalendarPopup;
begin
  P := TPPGCalendarPopup.Create(Self);
  P.OnDirectPick := PopupDirectPick;
  Result := P;
end;

procedure TPPGCustomDatePicker.PopupDirectPick(Sender: TObject);
begin
  // Direkt am Kalender gewaehlt (z.B. per Automation): uebernehmen und schliessen
  if DroppedDown then
    CloseUp(True);
end;

function TPPGCustomDatePicker.CanDropDown: Boolean;
begin
  Result := inherited CanDropDown and not SpinMode;
end;

procedure TPPGCustomDatePicker.PreparePopup(APopup: TPPGDropPopup);
var
  P: TPPGCalendarPopup;
  D: TDate;
begin
  P := TPPGCalendarPopup(APopup);
  // Stile und eigenes Zeichnen der Tage vom Datumsfeld
  P.Calendar.Styles := FCalendarStyles;
  P.Calendar.OnCustomDrawDay := FOnCustomDrawDay;
  P.Calendar.MinDate := FMinDate;
  P.Calendar.MaxDate := FMaxDate;
  P.Calendar.View := cvMonth;
  if not ParseDate(Text, D) then
    D := Trunc(FDateTime);
  if D = 0 then
    D := System.SysUtils.Date;
  P.Calendar.Date := D;
  if not HasDate then
    P.Calendar.ClearSelection;
  P.Calendar.FocusDate := D;
  P.Calendar.Animation.Enabled := Animation.Enabled;
  P.StartPick;
  // Lage zum Feld wie TDateTimePicker.CalAlignment (die Basis spiegelt bei RTL)
  if FCalAlignment = dtaRight then
    PopupAlign := taRightJustify
  else
    PopupAlign := taLeftJustify;
end;

procedure TPPGCustomDatePicker.PopupOpened;
begin
  inherited PopupOpened;
  Popup.ShowCalendar;
end;

procedure TPPGCustomDatePicker.PopupClosed;
begin
  inherited PopupClosed;
  Popup.HideCalendar;
end;

procedure TPPGCustomDatePicker.AcceptPopup(APopup: TPPGDropPopup);
var
  P: TPPGCalendarPopup;
  D: TDate;
begin
  P := TPPGCalendarPopup(APopup);
  // Gewaehlt (Klick, Enter): der gewaehlte Tag. Sonst (F4, Alt+Pfeil) der
  // Fokus-Tag, wenn die Tastatur ihn bewegt hat und er waehlbar ist.
  D := 0;
  if P.Picked then
    D := Trunc(P.Calendar.Date)
  else if (P.Calendar.View = cvMonth) and (Trunc(P.Calendar.FocusDate) <> P.StartFocus) and
    not P.Calendar.IsDateDisabled(P.Calendar.FocusDate) then
    D := Trunc(P.Calendar.FocusDate);
  if D <> 0 then
  begin
    UserSetDate(D);
    if FieldFocused then
      SelectAll;
  end;
end;

function TPPGCustomDatePicker.GetDroppedDown: Boolean;
begin
  Result := inherited DroppedDown;
end;

procedure TPPGCustomDatePicker.SetDroppedDown(const Value: Boolean);
begin
  if Value then
    DropDown
  else
    CloseUp(False);
end;

function TPPGCustomDatePicker.GetCalendarPopup: TPPGCalendarPopup;
begin
  Result := TPPGCalendarPopup(inherited Popup);
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
      PPGDrawIcon(ACanvas, B, igCheckMark, Tokens.OnAccent, PPGScale(10, PPI));
    end
    else
      ACanvas.FrameRoundRect(B, PPGScale(3, PPI), Max(1, PPGScale(1, PPI)), Col, 255);
  end;
end;

{ ---- Barrierefreiheit ---- }

function TPPGCustomDatePicker.AccValue: string;
begin
  if HasDate and TimeMode then
    Result := FormatDateTime(FormatSettings.LongTimeFormat, FDateTime)
  else if HasDate and DateTimeMode then
    Result := FormatDateTime(FormatSettings.LongDateFormat, FDateTime) + ' ' +
      FormatDateTime(FormatSettings.ShortTimeFormat, FDateTime)
  else if HasDate then
    Result := FormatDateTime(FormatSettings.LongDateFormat, FDateTime)
  else
    Result := '';
end;

{ ---- Kalender-Popup ohne DatePicker (PPGShowCalendarPopup) ---- }

type
  /// Eine Sitzung von PPGShowCalendarPopup: Popup, Haken und Schleife.
  /// Lebt nur waehrend des Aufrufs; FreeNotification auf Anker und Formular.
  TCalendarPopupRun = class(TComponent)
  private
    FAnchor: TPPGCustomControl;
    FAnchorWnd: HWND;
    FForm: TCustomForm;
    FFormWnd: HWND;
    FPopup: TPPGCalendarPopup;
    FAlign: TAlignment;
    FActive: Boolean;
    FAccepted: Boolean;
    FResult: TDate;
    FHooked: Boolean;
    FFocusWnd: HWND;
    FMouseIn: Boolean;
    FCloseOnKeyUp: Boolean;
    FDeferredRelease: TArray<HWND>;
    procedure Hook(var Msg: TMsg; var Handled: Boolean);
    procedure AppDeactivate(Sender: TObject);
    procedure PopupDirectPick(Sender: TObject);
    procedure PopupFollow(Sender: TObject);
    procedure PopupSourceHidden(Sender: TObject);
    procedure HandleKey(Key: Word; Shift: TShiftState);
    procedure HandleMouse(var Msg: TMsg; var Handled: Boolean);
    function IsPopupWnd(Wnd: HWND): Boolean;
    procedure Act(Action: TPPGDropAction);
    procedure AcceptFocusDay;
    procedure Place(Duration: Cardinal);
    procedure StartHooks;
    procedure StopHooks;
    procedure PostDeferredReleases;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    destructor Destroy; override;
    function Execute(Anchor: TPPGCustomControl; StartDate: TDate;
      const Options: TPPGCalendarPopupOptions): Boolean;
    procedure Finish(Accept: Boolean);
    property PickedDate: TDate read FResult;
  end;

var
  GActiveCalendarRun: TCalendarPopupRun = nil;

function PPGCalendarPopupOptions(ShowWeekNumbers: Boolean; MinDate: TDate;
  MaxDate: TDate): TPPGCalendarPopupOptions;
begin
  Result.ShowWeekNumbers := ShowWeekNumbers;
  Result.MinDate := MinDate;
  Result.MaxDate := MaxDate;
  Result.Alignment := taLeftJustify;
  Result.Styles := nil;
  Result.OnCustomDrawDay := nil;
end;

function PPGShowCalendarPopup(Anchor: TPPGCustomControl; var ADate: TDateTime;
  const Options: TPPGCalendarPopupOptions): Boolean;
var
  Run: TCalendarPopupRun;
begin
  Result := False;
  if (Anchor = nil) or (csDesigning in Anchor.ComponentState) or
    (csDestroying in Anchor.ComponentState) or not Anchor.HandleAllocated or
    not IsWindowVisible(Anchor.Handle) then
    Exit;
  // Nur ein Popup gleichzeitig: das offene bricht ab (sein Aufruf kehrt
  // zurueck, sobald dieser endet)
  if GActiveCalendarRun <> nil then
    GActiveCalendarRun.Finish(False);
  Run := TCalendarPopupRun.Create(nil);
  try
    if Run.Execute(Anchor, Trunc(ADate), Options) then
    begin
      ADate := Run.PickedDate + Frac(ADate);
      Result := True;
    end;
  finally
    Run.Free;
  end;
end;

function PPGShowCalendarPopup(Anchor: TPPGCustomControl; var ADate: TDateTime;
  ShowWeekNumbers: Boolean): Boolean;
begin
  Result := PPGShowCalendarPopup(Anchor, ADate, PPGCalendarPopupOptions(ShowWeekNumbers));
end;

function PPGActiveCalendarPopup: TPPGCalendarPopup;
begin
  if (GActiveCalendarRun <> nil) and GActiveCalendarRun.FActive then
    Result := GActiveCalendarRun.FPopup
  else
    Result := nil;
end;

procedure PPGCloseCalendarPopup;
begin
  if GActiveCalendarRun <> nil then
    GActiveCalendarRun.Finish(False);
end;

{ TCalendarPopupRun }

destructor TCalendarPopupRun.Destroy;
begin
  StopHooks;
  if GActiveCalendarRun = Self then
    GActiveCalendarRun := nil;
  FreeAndNil(FPopup);
  if FAnchor <> nil then
    FAnchor.RemoveFreeNotification(Self);
  if (FForm <> nil) and (TComponent(FForm) <> TComponent(FAnchor)) then
    FForm.RemoveFreeNotification(Self);
  FAnchor := nil;
  FForm := nil;
  inherited Destroy;
end;

procedure TCalendarPopupRun.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation <> opRemove then
    Exit;
  if AComponent = FAnchor then
  begin
    // Anker freigegeben: das Popup zeigt noch auf ihn (Besitzer, Optik)
    FAnchor := nil;
    FAnchorWnd := 0;
    if FPopup <> nil then
      FPopup.SyncFrom(nil);
    Finish(False);
  end;
  if AComponent = FForm then
  begin
    FForm := nil;
    FFormWnd := 0;
    Finish(False);
  end;
end;

function TCalendarPopupRun.Execute(Anchor: TPPGCustomControl; StartDate: TDate;
  const Options: TPPGCalendarPopupOptions): Boolean;
var
  Cal: TPPGCalendar;
  D: TDate;
  Duration: Cardinal;
begin
  FAnchor := Anchor;
  FAnchor.FreeNotification(Self);
  FAnchorWnd := Anchor.Handle;
  FForm := GetParentForm(Anchor);
  if FForm <> nil then
  begin
    FForm.FreeNotification(Self);
    if FForm.HandleAllocated then
      FFormWnd := FForm.Handle;
  end;
  FAlign := Options.Alignment;
  FPopup := TPPGCalendarPopup.Create(nil);
  FPopup.OnDirectPick := PopupDirectPick;
  FPopup.OnFollow := PopupFollow;
  FPopup.OnSourceHidden := PopupSourceHidden;
  FPopup.SyncFrom(Anchor);
  Cal := FPopup.Calendar;
  if Options.Styles <> nil then
    Cal.Styles := Options.Styles;
  Cal.OnCustomDrawDay := Options.OnCustomDrawDay;
  Cal.ShowWeekNumbers := Options.ShowWeekNumbers;
  Cal.MinDate := Options.MinDate;
  Cal.MaxDate := Options.MaxDate;
  Cal.View := cvMonth;
  // Startdatum: ADate (0 = heute), in den Bereich geholt
  D := StartDate;
  if D = 0 then
    D := System.SysUtils.Date;
  if (Options.MinDate <> 0) and (D < Trunc(Options.MinDate)) then
    D := Trunc(Options.MinDate);
  if (Options.MaxDate <> 0) and (D > Trunc(Options.MaxDate)) then
    D := Trunc(Options.MaxDate);
  Cal.Date := D;
  Cal.FocusDate := D;
  Cal.Animation.Enabled := TAnchorAccess(Anchor).Animation.Enabled;
  FPopup.StartPick;
  if TAnchorAccess(Anchor).Animation.EffectiveEnabled then
    Duration := TAnchorAccess(Anchor).Animation.Duration
  else
    Duration := 0;
  // Hinweise aus, eine gefangene Maus frei (Mausnachrichten gehen dann an
  // das Fenster unter dem Zeiger und laufen ueber den Haken)
  Application.CancelHint;
  if GetCapture <> 0 then
    ReleaseCapture;
  FActive := True;
  FAccepted := False;
  GActiveCalendarRun := Self;
  try
    Place(Duration);
    FPopup.ShowCalendar;
    FFocusWnd := GetFocus;
    StartHooks;
    while FActive and not Application.Terminated do
    begin
      Application.HandleMessage;
      // Fokus woanders hin (Code, anderes Fenster): abbrechen
      if FActive and (GetFocus <> FFocusWnd) then
        Finish(False);
    end;
  finally
    StopHooks;
    Finish(False);
    if GActiveCalendarRun = Self then
      GActiveCalendarRun := nil;
    PostDeferredReleases;
  end;
  Result := FAccepted and (FResult <> 0);
end;

procedure TCalendarPopupRun.Place(Duration: Cardinal);
var
  P: TPoint;
  A, WA: TRect;
  Sz: TSize;
  Pl: TPPGPlacement;
  AlignEnd: Boolean;
begin
  // Wie TPPGCustomDropDownField.PlacePopup: unter dem Anker, sonst darueber
  if (FAnchor = nil) or not FAnchor.HandleAllocated or (FPopup = nil) then
    Exit;
  P := FAnchor.ClientToScreen(Point(0, 0));
  A := Rect(P.X, P.Y, P.X + FAnchor.Width, P.Y + FAnchor.Height);
  WA := FPopup.MonitorWorkArea(A);
  Sz := FPopup.PreferredSize(FAnchor.Width);
  AlignEnd := FAnchor.UseRightToLeftAlignment;
  case FAlign of
    taRightJustify:
      AlignEnd := not AlignEnd;
    taCenter:
      begin
        A.Left := (A.Left + A.Right - Sz.cx) div 2;
        A.Right := A.Left + Sz.cx;
        AlignEnd := False;
      end;
  end;
  Pl := PPGPlacePopup(A, Sz.cx, Sz.cy, ppsBelow, WA, AlignEnd, True);
  FPopup.PopupAt(Pl.Bounds, Pl.Side, Duration);
end;

procedure TCalendarPopupRun.Finish(Accept: Boolean);
begin
  if not FActive then
    Exit;
  FActive := False;
  FAccepted := Accept;
  if FPopup <> nil then
  begin
    FPopup.HideCalendar;
    FPopup.ClosePopup;
  end;
end;

procedure TCalendarPopupRun.Act(Action: TPPGDropAction);
begin
  case Action of
    pdaAccept:
      if FPopup <> nil then
      begin
        FResult := Trunc(FPopup.Calendar.Date);
        Finish(FResult <> 0);
      end;
    pdaCancel:
      Finish(False);
  end;
end;

procedure TCalendarPopupRun.AcceptFocusDay;
var
  Cal: TPPGCalendar;
begin
  // F4/Alt+Pfeil wie beim DatePicker: gewaehlt bzw. bewegter Fokus-Tag
  if FPopup = nil then
    Exit;
  Cal := FPopup.Calendar;
  FResult := 0;
  if FPopup.Picked then
    FResult := Trunc(Cal.Date)
  else if (Cal.View = cvMonth) and (Trunc(Cal.FocusDate) <> FPopup.StartFocus) and
    not Cal.IsDateDisabled(Cal.FocusDate) then
    FResult := Trunc(Cal.FocusDate);
  Finish(FResult <> 0);
end;

procedure TCalendarPopupRun.PopupDirectPick(Sender: TObject);
begin
  if FActive and (FPopup <> nil) then
  begin
    FResult := Trunc(FPopup.Calendar.Date);
    Finish(FResult <> 0);
  end;
end;

procedure TCalendarPopupRun.PopupFollow(Sender: TObject);
begin
  // Formular bzw. Anker verschoben: neu platzieren
  if FActive then
    Place(0);
end;

procedure TCalendarPopupRun.PopupSourceHidden(Sender: TObject);
begin
  Finish(False);
end;

procedure TCalendarPopupRun.AppDeactivate(Sender: TObject);
begin
  Finish(False);
end;

procedure TCalendarPopupRun.StartHooks;
begin
  if FHooked then
    Exit;
  PPGAddMessageHook(Hook);
  PPGAddDeactivateHook(AppDeactivate);
  FHooked := True;
end;

procedure TCalendarPopupRun.StopHooks;
begin
  if not FHooked then
    Exit;
  PPGRemoveMessageHook(Hook);
  PPGRemoveDeactivateHook(AppDeactivate);
  FHooked := False;
end;

procedure TCalendarPopupRun.PostDeferredReleases;
var
  L: TArray<HWND>;
  I: Integer;
begin
  L := FDeferredRelease;
  FDeferredRelease := nil;
  for I := 0 to High(L) do
    if IsWindow(L[I]) then
      PostMessage(L[I], CM_RELEASE, 0, 0);
end;

function TCalendarPopupRun.IsPopupWnd(Wnd: HWND): Boolean;
begin
  Result := (FPopup <> nil) and FPopup.HandleAllocated and (Wnd <> 0) and
    ((Wnd = FPopup.Handle) or IsChild(FPopup.Handle, Wnd));
end;

procedure TCalendarPopupRun.HandleKey(Key: Word; Shift: TShiftState);
var
  K: Word;
begin
  case Key of
    VK_ESCAPE, VK_TAB:
      Finish(False);
    VK_MENU, VK_F10:
      // Erst beim Loslassen: sonst startet DefWindowProc die System-Menueschleife
      FCloseOnKeyUp := True;
    VK_F4:
      if Shift = [] then
        AcceptFocusDay
      else
        Finish(False);
    VK_UP, VK_DOWN:
      if ssAlt in Shift then
        AcceptFocusDay
      else
      begin
        K := Key;
        Act(FPopup.DropKeyDown(K, Shift));
      end;
  else
    // Pfeile, Bild, Pos1/Ende, Enter an den Kalender; alle anderen Tasten verbraucht
    if FPopup <> nil then
    begin
      K := Key;
      Act(FPopup.DropKeyDown(K, Shift));
    end;
  end;
end;

procedure TCalendarPopupRun.HandleMouse(var Msg: TMsg; var Handled: Boolean);
var
  Pt, PP: TPoint;
  R: TRect;
  InPopup, OwnWnd: Boolean;
begin
  // Bildschirmpunkt: Client-Nachrichten in Koordinaten des Zielfensters,
  // Rahmen-Nachrichten und das Rad schon in Bildschirmkoordinaten
  Pt := Point(SmallInt(LoWord(Cardinal(Msg.lParam))), SmallInt(HiWord(Cardinal(Msg.lParam))));
  if (Msg.message >= WM_MOUSEFIRST) and (Msg.message <= WM_MOUSELAST) and
    (Msg.message <> WM_MOUSEWHEEL) and (Msg.message <> WM_MOUSEHWHEEL) then
    Winapi.Windows.ClientToScreen(Msg.hwnd, Pt);
  InPopup := FPopup.HandleAllocated and GetWindowRect(FPopup.Handle, R) and PtInRect(R, Pt);
  PP := FPopup.ScreenToClient(Pt);
  OwnWnd := IsPopupWnd(Msg.hwnd);
  // Das Popup und der Kalender sehen nie rohe Mausnachrichten (sie wuerden
  // sonst den Fokus nehmen); alles geht ueber die Drop*-Methoden
  Handled := OwnWnd;
  case Msg.message of
    WM_MOUSEMOVE:
      if InPopup then
      begin
        FMouseIn := True;
        FPopup.DropMouseMove(PP.X, PP.Y, KeysToShiftState(Word(Msg.wParam)));
      end
      else if FMouseIn then
      begin
        FMouseIn := False;
        FPopup.DropMouseLeave;
      end;
    WM_LBUTTONDOWN, WM_LBUTTONDBLCLK:
      begin
        Handled := True;
        if InPopup then
          Act(FPopup.DropMouseDown(PP.X, PP.Y))
        else
          Finish(False); // Klick daneben: schliessen und verbrauchen
      end;
    WM_LBUTTONUP:
      begin
        // Ausserhalb losgelassen nur verbrauchen, wenn im Popup gedrueckt wurde
        if InPopup then
          Handled := True;
        Act(FPopup.DropMouseUp(PP.X, PP.Y));
      end;
    WM_RBUTTONDOWN, WM_RBUTTONDBLCLK, WM_MBUTTONDOWN, WM_MBUTTONDBLCLK,
    WM_XBUTTONDOWN, WM_XBUTTONDBLCLK,
    WM_NCLBUTTONDOWN, WM_NCLBUTTONDBLCLK, WM_NCRBUTTONDOWN, WM_NCRBUTTONDBLCLK,
    WM_NCMBUTTONDOWN, WM_NCMBUTTONDBLCLK, WM_NCXBUTTONDOWN, WM_NCXBUTTONDBLCLK:
      begin
        Handled := True;
        if not InPopup then
          Finish(False);
      end;
    WM_MOUSEWHEEL:
      begin
        // Geht an das Fenster mit Fokus: ueber dem Popup blaettern, sonst verbrauchen
        Handled := True;
        if InPopup then
          FPopup.DropWheel(SmallInt(HiWord(Cardinal(Msg.wParam))));
      end;
    WM_MOUSEHWHEEL:
      Handled := True;
  end;
end;

procedure TCalendarPopupRun.Hook(var Msg: TMsg; var Handled: Boolean);
begin
  if not FActive or (FPopup = nil) then
    Exit;
  case Msg.message of
    WM_KEYDOWN, WM_SYSKEYDOWN:
      begin
        Handled := True;
        HandleKey(Word(Msg.wParam), KeyDataToShiftState(Msg.lParam));
      end;
    WM_KEYUP, WM_SYSKEYUP:
      begin
        Handled := True;
        if FCloseOnKeyUp and ((Msg.wParam = VK_MENU) or (Msg.wParam = VK_F10)) then
        begin
          FCloseOnKeyUp := False;
          Finish(False);
        end;
      end;
    WM_CHAR, WM_SYSCHAR, WM_DEADCHAR, WM_SYSDEADCHAR:
      Handled := True; // nichts in das Feld tippen, solange das Popup offen ist
    WM_MOUSEFIRST..WM_MOUSELAST, WM_NCMOUSEMOVE..WM_NCXBUTTONDBLCLK:
      HandleMouse(Msg, Handled);
    CM_RELEASE:
      // Formular des Ankers gibt sich frei (Close mit caFree, Release): der
      // Aufrufer (z.B. ein Klick-Ereignis) liefe danach in freigegebenen
      // Objekten weiter. Erst schliessen, nach der Rueckkehr neu posten.
      if (Msg.hwnd <> 0) and (((FFormWnd <> 0) and (Msg.hwnd = FFormWnd)) or
        ((FAnchorWnd <> 0) and IsChild(Msg.hwnd, FAnchorWnd))) then
      begin
        SetLength(FDeferredRelease, Length(FDeferredRelease) + 1);
        FDeferredRelease[High(FDeferredRelease)] := Msg.hwnd;
        Handled := True;
        Finish(False);
      end;
  end;
end;

end.
