unit PPG.Calendar;

{ TPPGCalendar - Monatskalender mit Jahres- und Dekadenansicht (Phase 7b).

  - Ansichten: Monat (Tage), Jahr (Monate), Dekade (Jahre). Klick auf den
    Titel bzw. Strg+Oben zoomt heraus, Klick auf einen Monat/ein Jahr bzw.
    Enter zoomt hinein. Wechsel und Blaettern sind animiert (gemeinsamer
    Animator, ekDecelerate).
  - Erster Wochentag aus dem Gebietsschema (LOCALE_IFIRSTDAYOFWEEK) oder fest;
    Wochennummern nach ISO 8601 (ShowWeekNumbers); Tages- und Monatsnamen aus
    FormatSettings.
  - Auswahl: einzelner Tag, Bereich (zwei Klicks bzw. Umschalt+Klick) oder
    mehrere Tage (Klick schaltet um). MinDate/MaxDate und OnIsDateDisabled
    sperren Tage. Heute ist markiert (ShowToday).
  - Tastatur: Pfeile (Tag/Woche), Bild auf/ab (Monat), Strg+Bild (Jahr),
    Pos1/Ende (Monatsanfang/-ende), Enter/Leertaste waehlen, Strg+Oben/Unten
    zoomen. RTL gespiegelt.
  - Code (Date := ...) loest kein OnChange aus; der Anwender schon.
  - Screenreader: Tabelle, Kinder sind die Tage (bzw. Monate/Jahre) mit
    Langdatum als Name, Zustaenden gewaehlt/fokussiert/gesperrt.
  - Link (Phase 14a): ein verbundener Planer (IPPGCalendarLink) markiert Tage
    mit Terminen fett und erfaehrt die Auswahl des Anwenders. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.Generics.Collections, Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Base, PPG.ElementStyle, PPG.CustomDraw;

type
  TPPGCalendarView = (cvMonth, cvYear, cvDecade);
  TPPGDateSelectionMode = (dsmSingle, dsmRange, dsmMultiple);
  TPPGFirstDayOfWeek = (fdLocale, fdMonday, fdTuesday, fdWednesday, fdThursday, fdFriday,
    fdSaturday, fdSunday);
  TPPGDateDisabledEvent = procedure(Sender: TObject; ADate: TDate; var Disabled: Boolean) of object;

  TPPGCalendarPart = (cpNone, cpTitle, cpPrev, cpNext, cpCell);

  /// Verbindung Kalender -> Planer (Phase 14a). Der Kalender kennt nur dieses
  /// Interface, nicht den Planer.
  IPPGCalendarLink = interface
    ['{B83E1F52-6C0A-4D97-8E24-5A19F7C3D061}']
    /// Tag fett zeichnen (z. B. Termine an diesem Tag).
    function CalendarDateMarked(ADate: TDate): Boolean;
    /// Anwender hat einen Tag gewaehlt.
    procedure CalendarDateSelected(Sender: TObject; ADate: TDate);
  end;

  /// Bereiche des Kalenders (nur gesetzte Werte zaehlen, clDefault = Preset).
  TPPGCalendarStyles = class(TPPGStyleGroup)
  public
    constructor Create(AOwner: TPersistent);
  published
    /// Flaeche (Color), Text (TextColor), Rahmen (BorderColor).
    property Background: TPPGElementStyle index 0 read GetItem write SetItem;
    /// Titel (Monat/Jahr) und Pfeile: TextColor, Schrift.
    property Header: TPPGElementStyle index 1 read GetItem write SetItem;
    /// Wochentagsnamen: TextColor, Schrift.
    property DayNames: TPPGElementStyle index 2 read GetItem write SetItem;
    /// Heute: BorderColor = Ring, TextColor.
    property Today: TPPGElementStyle index 3 read GetItem write SetItem;
    /// Gewaehlte Tage: Color = Flaeche, TextColor.
    property Selected: TPPGElementStyle index 4 read GetItem write SetItem;
    /// Samstag und Sonntag: Color, TextColor, Schrift.
    property Weekend: TPPGElementStyle index 5 read GetItem write SetItem;
    /// Tage anderer Monate: TextColor.
    property OtherMonth: TPPGElementStyle index 6 read GetItem write SetItem;
    /// Wochennummern: TextColor, Schrift.
    property WeekNumbers: TPPGElementStyle index 7 read GetItem write SetItem;
  end;

  /// Vor dem Zeichnen eines Tages (Monatsansicht): Style (z.B. Feiertag fett und
  /// farbig) oder ganz selbst zeichnen (DefaultDraw = False).
  TPPGCalendarDrawDayEvent = procedure(Sender: TObject; Canvas: TCanvas; ADate: TDate;
    const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
    var DefaultDraw: Boolean) of object;

  TPPGCustomCalendar = class(TPPGCustomControl, IPPGAccessibleChildren)
  private
    FView: TPPGCalendarView;
    FDisplayYear: Word;
    FDisplayMonth: Word;
    FFocusDate: TDate;
    FDate: TDate;
    FRangeStart: TDate;
    FRangeEnd: TDate;
    FSelected: TList<Integer>;
    FSelectionMode: TPPGDateSelectionMode;
    FMinDate: TDate;
    FMaxDate: TDate;
    FShowWeekNumbers: Boolean;
    FShowToday: Boolean;
    FFirstDayOfWeek: TPPGFirstDayOfWeek;
    FHotPart: TPPGCalendarPart;
    FHotCell: Integer;
    FDownPart: TPPGCalendarPart;
    FDownCell: Integer;
    FTransAnim: TPPGAnimation;
    FTransKind: Integer; // 0 = keine, 1 = Zoom hinein, 2 = Zoom heraus, 3 = vor, 4 = zurueck
    FBoldFont: TFont;
    FCalendarStyles: TPPGCalendarStyles;
    FOnCustomDrawDay: TPPGCalendarDrawDayEvent;
    FDrawCanvas: TCanvas;
    FFonts: TPPGFontCache;
    FTodayOverride: TDate;
    FShowFocusAlways: Boolean;
    FLink: TComponent;
    FOnChange: TNotifyEvent;
    FOnIsDateDisabled: TPPGDateDisabledEvent;
    FOnViewChange: TNotifyEvent;
    procedure SetCalendarStyles(const Value: TPPGCalendarStyles);
    procedure CalendarStylesChanged(Sender: TObject);
    procedure SetView(const Value: TPPGCalendarView);
    procedure SetDate(const Value: TDate);
    procedure SetSelectionMode(const Value: TPPGDateSelectionMode);
    procedure SetMinDate(const Value: TDate);
    procedure SetMaxDate(const Value: TDate);
    procedure SetShowWeekNumbers(const Value: Boolean);
    procedure SetShowToday(const Value: Boolean);
    procedure SetFirstDayOfWeek(const Value: TPPGFirstDayOfWeek);
    procedure SetFocusDate(const Value: TDate);
    procedure TransStep(Sender: TObject);
    procedure StartTransition(Kind: Integer);
    function Cols: Integer;
    function Rows: Integer;
    function CellCount: Integer;
    function CellFromPoint(X, Y: Integer): Integer;
    function PartAt(X, Y: Integer; out Cell: Integer): TPPGCalendarPart;
    function FocusCell: Integer;
    function FirstVisibleDate: TDate;
    function CellYear(Index: Integer): Integer;
    function DecadeStart: Integer;
    procedure UserPickCell(Index: Integer; Shift: TShiftState);
    procedure UserSelectDate(D: TDate; Shift: TShiftState);
    procedure MoveFocusDays(Delta: Integer);
    procedure MoveFocusMonths(Delta: Integer);
    function ClampDate(D: TDate): TDate;
    procedure ApplyDateRange;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure WndProc(var Message: TMessage); override;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure Change; virtual;
    procedure ViewChanged; virtual;
    function AccRole: Integer; override;
    function AccValue: string; override;
    { IPPGAccessibleChildren - Kinder sind die Zellen der aktuellen Ansicht }
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
    property View: TPPGCalendarView read FView write SetView default cvMonth;
    property Date: TDate read FDate write SetDate;
    property SelectionMode: TPPGDateSelectionMode read FSelectionMode write SetSelectionMode default dsmSingle;
    /// Fruehestes bzw. spaetestes waehlbares Datum (0 = ohne Grenze).
    property MinDate: TDate read FMinDate write SetMinDate;
    property MaxDate: TDate read FMaxDate write SetMaxDate;
    property ShowWeekNumbers: Boolean read FShowWeekNumbers write SetShowWeekNumbers default False;
    property ShowToday: Boolean read FShowToday write SetShowToday default True;
    property FirstDayOfWeek: TPPGFirstDayOfWeek read FFirstDayOfWeek write SetFirstDayOfWeek default fdLocale;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnIsDateDisabled: TPPGDateDisabledEvent read FOnIsDateDisabled write FOnIsDateDisabled;
    /// Bereiche (Hintergrund, Kopf, Wochentage, Heute, Auswahl, Wochenende ...).
    property Styles: TPPGCalendarStyles read FCalendarStyles write SetCalendarStyles;
    /// Vor dem Zeichnen jedes Tages (Monatsansicht).
    property OnCustomDrawDay: TPPGCalendarDrawDayEvent read FOnCustomDrawDay write FOnCustomDrawDay;
    property OnViewChange: TNotifyEvent read FOnViewChange write FOnViewChange;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Zeigt einen Monat (ohne Ereignis).
    procedure ShowMonth(AYear, AMonth: Word);
    procedure NextPage;
    procedure PrevPage;
    function IsDateDisabled(D: TDate): Boolean;
    function IsSelected(D: TDate): Boolean;
    procedure ClearSelection;
    /// Waehlt per Code (ohne Ereignis); bei dsmMultiple zusaetzlich.
    procedure Select(D: TDate);
    procedure SelectRange(AStart, AEnd: TDate);
    function SelectedCount: Integer;
    function SelectedDate(Index: Integer): TDate;
    /// Erster Wochentag nach ISO (1 = Montag .. 7 = Sonntag).
    function EffectiveFirstDay: Integer;
    /// Datum der Zelle (Monatsansicht) bzw. erster Tag des Monats/Jahres.
    function CellDate(Index: Integer): TDate;
    function CellRect(Index: Integer): TRect;
    function HeaderRect: TRect;
    function PartRect(Part: TPPGCalendarPart): TRect;
    function Today: TDate;
    /// ISO-8601-Woche einer Zeile der Monatsansicht (0..5).
    function WeekNumberOfRow(Row: Integer): Integer;
    property DisplayYear: Word read FDisplayYear;
    property DisplayMonth: Word read FDisplayMonth;
    property FocusDate: TDate read FFocusDate write SetFocusDate;
    property RangeStart: TDate read FRangeStart;
    property RangeEnd: TDate read FRangeEnd;
    /// Fester "heute"-Wert fuer Tests (0 = Systemdatum).
    property TodayOverride: TDate read FTodayOverride write FTodayOverride;
    /// Fokus-Tag auch ohne eigenen Fokus markieren (Kalender im Popup eines
    /// DatePickers: die Tastatur bleibt beim Feld).
    property ShowFocusAlways: Boolean read FShowFocusAlways write FShowFocusAlways;
    property HotCell: Integer read FHotCell;
    /// Verbundener Planer (muss IPPGCalendarLink unterstuetzen; nil = keiner).
    procedure SetLink(Value: TComponent);
    property Link: TComponent read FLink;
  end;

  TPPGCalendar = class(TPPGCustomCalendar)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighContrastSupport;
    property View;
    property Date;
    property SelectionMode;
    property MinDate;
    property MaxDate;
    property ShowWeekNumbers;
    property ShowToday;
    property FirstDayOfWeek;
    property Align;
    property Anchors;
    property BiDiMode;
    property Constraints;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Touch;
    property OnGesture;
    property OnChange;
    property OnEnter;
    property OnExit;
    property OnIsDateDisabled;
    property Styles;
    property OnCustomDrawDay;
    property OnViewChange;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseActivate;
    property OnContextPopup;
    property StyleElements;
    property DragMode;
    property DragCursor;
    property OnDragDrop;
    property OnDragOver;
    property OnStartDrag;
    property OnEndDrag;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property Color;
    property ParentColor;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

/// ISO-Wochentag (1 = Montag .. 7 = Sonntag).
function PPGIsoDayOfWeek(D: TDate): Integer;
/// Erster Wochentag des Gebietsschemas nach ISO.
function PPGLocaleFirstDayOfWeek: Integer;

implementation

uses
  PPG.Lang,
  System.Math, System.DateUtils, System.UITypes, Winapi.oleacc,
  PPG.Consts, PPG.Exceptions, PPG.Appearance, PPG.DpiUtils, PPG.Tokens, PPG.Render.Gdi;

const
  CalPad = 6;
  HeaderH = 40;
  DayNamesH = 28;
  NavBtn = 32;

var
  GMsgCalAction: Cardinal = 0;

function PPGIsoDayOfWeek(D: TDate): Integer;
begin
  Result := DayOfTheWeek(D); // System.DateUtils: 1 = Montag
end;

function PPGLocaleFirstDayOfWeek: Integer;
var
  Buf: array[0..3] of Char;
begin
  Result := 1;
  if GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_IFIRSTDAYOFWEEK, Buf, Length(Buf)) > 0 then
    if (Buf[0] >= '0') and (Buf[0] <= '6') then
      Result := Ord(Buf[0]) - Ord('0') + 1; // '0' = Montag
end;

function ContrastOn(Fill: TColor): TColor;
begin
  if PPGRelativeLuminance(Fill) < 0.4 then
    Result := clWhite
  else
    Result := clBlack;
end;

{ TPPGCustomCalendar }

constructor TPPGCustomCalendar.Create(AOwner: TComponent);
var
  Y, M, D: Word;
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption, csDoubleClicks]; // Audit 5d: OnClick wie TControl
  FSelected := TList<Integer>.Create;
  FShowToday := True;
  FHotCell := -1;
  FDownCell := -1;
  FBoldFont := TFont.Create;
  FCalendarStyles := TPPGCalendarStyles.Create(Self);
  FCalendarStyles.OnChange := CalendarStylesChanged;
  FDrawCanvas := TCanvas.Create;
  FFonts := TPPGFontCache.Create;
  DecodeDate(System.SysUtils.Date, Y, M, D);
  FDisplayYear := Y;
  FDisplayMonth := M;
  FFocusDate := System.SysUtils.Date;
  FTransAnim := TPPGAnimation.Create(Self);
  FTransAnim.Jump(1);
  FTransAnim.OnStep := TransStep;
  TabStop := True;
  Width := 300;
  Height := 330;
  if GMsgCalAction = 0 then
    GMsgCalAction := RegisterWindowMessage('PPGlow.CalendarAction');
end;

destructor TPPGCustomCalendar.Destroy;
begin
  if FTransAnim <> nil then
    FTransAnim.OnStep := nil;
  FreeAndNil(FTransAnim);
  FreeAndNil(FBoldFont);
  FreeAndNil(FFonts);
  FreeAndNil(FDrawCanvas);
  FreeAndNil(FCalendarStyles);
  FreeAndNil(FSelected);
  inherited Destroy;
end;

function TPPGCustomCalendar.Today: TDate;
begin
  if FTodayOverride <> 0 then
    Result := FTodayOverride
  else
    Result := System.SysUtils.Date;
end;

function TPPGCustomCalendar.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGCustomCalendar.IsDown: Boolean;
begin
  Result := False;
end;

function TPPGCustomCalendar.EffectiveFirstDay: Integer;
begin
  if FFirstDayOfWeek = fdLocale then
    Result := PPGLocaleFirstDayOfWeek
  else
    Result := Ord(FFirstDayOfWeek); // fdMonday = 1
end;

procedure TPPGCustomCalendar.SetLink(Value: TComponent);
begin
  if (Value <> nil) and not Supports(Value, IPPGCalendarLink) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGInvalidPropertyValue), ['Link', Value.ClassName]);
  if FLink = Value then
    Exit;
  if FLink <> nil then
    FLink.RemoveFreeNotification(Self);
  FLink := Value;
  if FLink <> nil then
    FLink.FreeNotification(Self);
  Invalidate;
end;

procedure TPPGCustomCalendar.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FLink) then
  begin
    FLink := nil;
    Invalidate;
  end;
end;

{ ---- Geometrie ---- }

function TPPGCustomCalendar.Cols: Integer;
begin
  if FView = cvMonth then
    Result := 7
  else
    Result := 4;
end;

function TPPGCustomCalendar.Rows: Integer;
begin
  if FView = cvMonth then
    Result := 6
  else
    Result := 3;
end;

function TPPGCustomCalendar.CellCount: Integer;
begin
  Result := Cols * Rows;
end;

function TPPGCustomCalendar.HeaderRect: TRect;
var
  P: Integer;
begin
  P := PPGScale(CalPad, ScalePPI);
  Result := Rect(P, P, Width - P, P + PPGScale(HeaderH, ScalePPI));
end;

function TPPGCustomCalendar.PartRect(Part: TPPGCalendarPart): TRect;
var
  H: TRect;
  B: Integer;
begin
  H := HeaderRect;
  B := PPGScale(NavBtn, ScalePPI);
  // Titel links, Zurueck/Vor rechts (RTL gespiegelt)
  case Part of
    cpPrev: Result := Rect(H.Right - 2 * B, H.Top + (H.Bottom - H.Top - B) div 2, H.Right - B,
      H.Top + (H.Bottom - H.Top + B) div 2);
    cpNext: Result := Rect(H.Right - B, H.Top + (H.Bottom - H.Top - B) div 2, H.Right,
      H.Top + (H.Bottom - H.Top + B) div 2);
    cpTitle: Result := Rect(H.Left, H.Top, H.Right - 2 * B - PPGScale(4, ScalePPI), H.Bottom);
  else
    Result := Rect(0, 0, 0, 0);
  end;
  if UseRightToLeftAlignment and not IsRectEmpty(Result) then
    Result := Rect(Width - Result.Right, Result.Top, Width - Result.Left, Result.Bottom);
end;

function GridArea(C: TPPGCustomCalendar; out WeekCol: Integer): TRect;
var
  P, Top: Integer;
begin
  P := PPGScale(CalPad, C.ScalePPI);
  Top := C.HeaderRect.Bottom;
  if C.View = cvMonth then
    Inc(Top, PPGScale(DayNamesH, C.ScalePPI));
  Result := Rect(P, Top, C.Width - P, C.Height - P);
  WeekCol := 0;
  if (C.View = cvMonth) and C.ShowWeekNumbers then
    WeekCol := (Result.Right - Result.Left) div 8;
end;

function TPPGCustomCalendar.CellRect(Index: Integer): TRect;
var
  G: TRect;
  WeekCol, CW, CH, R, C: Integer;
begin
  if (Index < 0) or (Index >= CellCount) then
    Exit(Rect(0, 0, 0, 0));
  G := GridArea(Self, WeekCol);
  CW := (G.Right - G.Left - WeekCol) div Cols;
  CH := (G.Bottom - G.Top) div Rows;
  R := Index div Cols;
  C := Index mod Cols;
  Result := Rect(G.Left + WeekCol + C * CW, G.Top + R * CH, G.Left + WeekCol + (C + 1) * CW,
    G.Top + (R + 1) * CH);
  if UseRightToLeftAlignment then
    Result := Rect(Width - Result.Right, Result.Top, Width - Result.Left, Result.Bottom);
end;

function TPPGCustomCalendar.CellFromPoint(X, Y: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to CellCount - 1 do
    if PtInRect(CellRect(I), Point(X, Y)) then
      Exit(I);
  Result := -1;
end;

function TPPGCustomCalendar.PartAt(X, Y: Integer; out Cell: Integer): TPPGCalendarPart;
begin
  Cell := -1;
  if PtInRect(PartRect(cpPrev), Point(X, Y)) then
    Exit(cpPrev);
  if PtInRect(PartRect(cpNext), Point(X, Y)) then
    Exit(cpNext);
  if PtInRect(PartRect(cpTitle), Point(X, Y)) then
  begin
    if FView = cvDecade then
      Exit(cpNone); // weiter heraus geht es nicht
    Exit(cpTitle);
  end;
  Cell := CellFromPoint(X, Y);
  if Cell >= 0 then
    Result := cpCell
  else
    Result := cpNone;
end;

{ ---- Datumslogik ---- }

function TPPGCustomCalendar.FirstVisibleDate: TDate;
var
  First: TDate;
  Offset: Integer;
begin
  First := EncodeDate(FDisplayYear, FDisplayMonth, 1);
  Offset := (PPGIsoDayOfWeek(First) - EffectiveFirstDay + 7) mod 7;
  Result := First - Offset;
end;

function TPPGCustomCalendar.DecadeStart: Integer;
begin
  Result := (FDisplayYear div 10) * 10;
end;

function TPPGCustomCalendar.CellYear(Index: Integer): Integer;
begin
  // Dekade: ein Jahr davor, zehn Jahre, ein Jahr danach
  Result := DecadeStart - 1 + Index;
end;

function TPPGCustomCalendar.CellDate(Index: Integer): TDate;
begin
  case FView of
    cvYear: Result := EncodeDate(FDisplayYear, Index + 1, 1);
    cvDecade: Result := EncodeDate(EnsureRange(CellYear(Index), 1, 9999), 1, 1);
  else
    Result := FirstVisibleDate + Index;
  end;
end;

function TPPGCustomCalendar.FocusCell: Integer;
var
  Y, M, D: Word;
begin
  DecodeDate(FFocusDate, Y, M, D);
  case FView of
    cvYear:
      if Y = FDisplayYear then
        Result := M - 1
      else
        Result := -1;
    cvDecade:
      begin
        Result := Y - (DecadeStart - 1);
        if (Result < 0) or (Result >= CellCount) then
          Result := -1;
      end;
  else
    Result := Trunc(FFocusDate) - Trunc(FirstVisibleDate);
    if (Result < 0) or (Result >= CellCount) then
      Result := -1;
  end;
end;

function TPPGCustomCalendar.IsDateDisabled(D: TDate): Boolean;
begin
  Result := ((FMinDate <> 0) and (Trunc(D) < Trunc(FMinDate))) or
    ((FMaxDate <> 0) and (Trunc(D) > Trunc(FMaxDate)));
  if not Result and Assigned(FOnIsDateDisabled) then
    FOnIsDateDisabled(Self, Trunc(D), Result);
end;

function TPPGCustomCalendar.IsSelected(D: TDate): Boolean;
var
  T: Integer;
begin
  T := Trunc(D);
  case FSelectionMode of
    dsmRange:
      if FRangeEnd = 0 then
        Result := (FRangeStart <> 0) and (T = Trunc(FRangeStart))
      else
        Result := (T >= Trunc(FRangeStart)) and (T <= Trunc(FRangeEnd));
    dsmMultiple:
      Result := FSelected.IndexOf(T) >= 0;
  else
    Result := (FDate <> 0) and (T = Trunc(FDate));
  end;
end;

function TPPGCustomCalendar.SelectedCount: Integer;
begin
  case FSelectionMode of
    dsmRange:
      if FRangeStart = 0 then
        Result := 0
      else if FRangeEnd = 0 then
        Result := 1
      else
        Result := Trunc(FRangeEnd) - Trunc(FRangeStart) + 1;
    dsmMultiple: Result := FSelected.Count;
  else
    if FDate = 0 then
      Result := 0
    else
      Result := 1;
  end;
end;

function TPPGCustomCalendar.SelectedDate(Index: Integer): TDate;
begin
  if (Index < 0) or (Index >= SelectedCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, SelectedCount - 1]);
  case FSelectionMode of
    dsmRange: Result := Trunc(FRangeStart) + Index;
    dsmMultiple: Result := FSelected[Index];
  else
    Result := Trunc(FDate);
  end;
end;

procedure TPPGCustomCalendar.ClearSelection;
begin
  FDate := 0;
  FRangeStart := 0;
  FRangeEnd := 0;
  FSelected.Clear;
  Invalidate;
end;

procedure TPPGCustomCalendar.Select(D: TDate);
var
  T, I: Integer;
begin
  T := Trunc(D);
  case FSelectionMode of
    dsmRange:
      begin
        FRangeStart := T;
        FRangeEnd := 0;
      end;
    dsmMultiple:
      if FSelected.IndexOf(T) < 0 then
      begin
        I := 0;
        while (I < FSelected.Count) and (FSelected[I] < T) do
          Inc(I);
        FSelected.Insert(I, T);
      end;
  end;
  FDate := T;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
end;

procedure TPPGCustomCalendar.SelectRange(AStart, AEnd: TDate);
var
  A, B: Integer;
begin
  A := Trunc(AStart);
  B := Trunc(AEnd);
  if B < A then
  begin
    FRangeStart := B;
    FRangeEnd := A;
  end
  else
  begin
    FRangeStart := A;
    FRangeEnd := B;
  end;
  FDate := FRangeStart;
  Invalidate;
end;

procedure TPPGCustomCalendar.SetDate(const Value: TDate);
var
  T: Integer;
  Y, M, D: Word;
begin
  T := Trunc(Value);
  if FSelectionMode = dsmMultiple then
    FSelected.Clear;
  if T = 0 then
  begin
    ClearSelection;
    Exit;
  end;
  Select(T);
  FFocusDate := T;
  DecodeDate(T, Y, M, D);
  if (Y <> FDisplayYear) or (M <> FDisplayMonth) then
  begin
    FDisplayYear := Y;
    FDisplayMonth := M;
  end;
  Invalidate;
end;

procedure TPPGCustomCalendar.SetSelectionMode(const Value: TPPGDateSelectionMode);
begin
  if FSelectionMode <> Value then
  begin
    FSelectionMode := Value;
    // Bisheriges Datum bleibt als einzige Auswahl
    FRangeStart := 0;
    FRangeEnd := 0;
    FSelected.Clear;
    if FDate <> 0 then
      Select(FDate);
    Invalidate;
  end;
end;

function TPPGCustomCalendar.ClampDate(D: TDate): TDate;
begin
  Result := Trunc(D);
  if (FMinDate <> 0) and (Result < Trunc(FMinDate)) then
    Result := Trunc(FMinDate);
  if (FMaxDate <> 0) and (Result > Trunc(FMaxDate)) then
    Result := Trunc(FMaxDate);
  if Result < EncodeDate(1, 1, 1) then
    Result := EncodeDate(1, 1, 1);
  if Result > EncodeDate(9999, 12, 31) then
    Result := EncodeDate(9999, 12, 31);
end;

procedure TPPGCustomCalendar.SetMinDate(const Value: TDate);
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
  Invalidate;
end;

procedure TPPGCustomCalendar.SetMaxDate(const Value: TDate);
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
  Invalidate;
end;

procedure TPPGCustomCalendar.ApplyDateRange;
var
  D: TDate;
begin
  // Gewaehltes Datum und Fokus in den Bereich holen (Audit 08.10.2026:
  // ein Datum ausserhalb von MinDate..MaxDate blieb stehen)
  if csLoading in ComponentState then
    Exit;
  if FFocusDate <> 0 then
    FFocusDate := ClampDate(FFocusDate);
  if (FSelectionMode = dsmSingle) and (FDate <> 0) then
  begin
    D := ClampDate(FDate);
    if D <> Trunc(FDate) then
      SetDate(D);
  end;
end;

procedure TPPGCustomCalendar.Loaded;
begin
  inherited Loaded;
  ApplyDateRange;
end;

procedure TPPGCustomCalendar.SetShowWeekNumbers(const Value: Boolean);
begin
  if FShowWeekNumbers <> Value then
  begin
    FShowWeekNumbers := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomCalendar.SetShowToday(const Value: Boolean);
begin
  if FShowToday <> Value then
  begin
    FShowToday := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomCalendar.SetFirstDayOfWeek(const Value: TPPGFirstDayOfWeek);
begin
  if FFirstDayOfWeek <> Value then
  begin
    FFirstDayOfWeek := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomCalendar.SetView(const Value: TPPGCalendarView);
begin
  if FView <> Value then
  begin
    FView := Value;
    FHotCell := -1;
    Invalidate;
    ViewChanged;
  end;
end;

procedure TPPGCustomCalendar.ViewChanged;
begin
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

procedure TPPGCustomCalendar.ShowMonth(AYear, AMonth: Word);
begin
  if (AYear < 1) or (AYear > 9999) or (AMonth < 1) or (AMonth > 12) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [AMonth, 12]);
  FDisplayYear := AYear;
  FDisplayMonth := AMonth;
  FHotCell := -1;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

procedure TPPGCustomCalendar.SetFocusDate(const Value: TDate);
var
  Old: TDate;
  Y, M, D: Word;
  Kind: Integer;
begin
  Old := FFocusDate;
  FFocusDate := ClampDate(Value);
  DecodeDate(FFocusDate, Y, M, D);
  Kind := 0;
  case FView of
    cvMonth:
      if (Y <> FDisplayYear) or (M <> FDisplayMonth) then
      begin
        if FFocusDate > Old then
          Kind := 3
        else
          Kind := 4;
        FDisplayYear := Y;
        FDisplayMonth := M;
      end;
    cvYear:
      if Y <> FDisplayYear then
      begin
        if Y > FDisplayYear then
          Kind := 3
        else
          Kind := 4;
        FDisplayYear := Y;
        FDisplayMonth := M;
      end;
    cvDecade:
      if (Y div 10) <> (FDisplayYear div 10) then
      begin
        if Y > FDisplayYear then
          Kind := 3
        else
          Kind := 4;
        FDisplayYear := Y;
      end
      else
        FDisplayYear := Y;
  end;
  if Kind <> 0 then
    StartTransition(Kind);
  Invalidate;
  if FocusCell >= 0 then
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, FocusCell + 1);
end;

procedure TPPGCustomCalendar.NextPage;
var
  Y, M, D: Word;
begin
  case FView of
    cvYear: if FDisplayYear < 9999 then Inc(FDisplayYear);
    cvDecade: if FDisplayYear < 9990 then Inc(FDisplayYear, 10);
  else
    if FDisplayMonth = 12 then
    begin
      if FDisplayYear < 9999 then
      begin
        FDisplayMonth := 1;
        Inc(FDisplayYear);
      end;
    end
    else
      Inc(FDisplayMonth);
  end;
  // Fokus wandert mit (gleicher Tag soweit moeglich)
  DecodeDate(FFocusDate, Y, M, D);
  if FView = cvMonth then
    FFocusDate := ClampDate(EncodeDate(FDisplayYear, FDisplayMonth,
      Min(D, DaysInAMonth(FDisplayYear, FDisplayMonth))));
  StartTransition(3);
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

procedure TPPGCustomCalendar.PrevPage;
var
  Y, M, D: Word;
begin
  case FView of
    cvYear: if FDisplayYear > 1 then Dec(FDisplayYear);
    cvDecade: if FDisplayYear > 10 then Dec(FDisplayYear, 10);
  else
    if FDisplayMonth = 1 then
    begin
      if FDisplayYear > 1 then
      begin
        FDisplayMonth := 12;
        Dec(FDisplayYear);
      end;
    end
    else
      Dec(FDisplayMonth);
  end;
  DecodeDate(FFocusDate, Y, M, D);
  if FView = cvMonth then
    FFocusDate := ClampDate(EncodeDate(FDisplayYear, FDisplayMonth,
      Min(D, DaysInAMonth(FDisplayYear, FDisplayMonth))));
  StartTransition(4);
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

procedure TPPGCustomCalendar.StartTransition(Kind: Integer);
begin
  FTransKind := Kind;
  // IsWindowVisible statt Showing: im Popup ist der Kalender ein Fenster, dessen
  // Sichtbarkeit die VCL nicht kennt (Popup ohne Parent)
  if HandleAllocated and IsWindowVisible(Handle) and Animation.EffectiveEnabled and
    not (csDesigning in ComponentState) then
  begin
    FTransAnim.Jump(0);
    FTransAnim.AnimateTo(1, Cardinal(Animation.Duration) + 50, ekDecelerate);
  end
  else
    FTransAnim.Jump(1);
end;

procedure TPPGCustomCalendar.TransStep(Sender: TObject);
begin
  Invalidate;
end;

procedure TPPGCustomCalendar.Change;
var
  L: IPPGCalendarLink;
begin
  if (FLink <> nil) and (FDate <> 0) and Supports(FLink, IPPGCalendarLink, L) then
    L.CalendarDateSelected(Self, FDate);
  NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGCustomCalendar.UserSelectDate(D: TDate; Shift: TShiftState);
var
  T, I: Integer;
begin
  T := Trunc(D);
  if IsDateDisabled(T) then
    Exit;
  case FSelectionMode of
    dsmRange:
      if (FRangeStart <> 0) and ((FRangeEnd = 0) or (ssShift in Shift)) then
      begin
        // Zweiter Klick (bzw. Umschalt): Bereich schliessen
        if T < Trunc(FRangeStart) then
        begin
          if FRangeEnd = 0 then
            FRangeEnd := FRangeStart;
          FRangeStart := T;
        end
        else
          FRangeEnd := T;
        if Trunc(FRangeEnd) = Trunc(FRangeStart) then
          FRangeEnd := FRangeStart;
        FDate := FRangeStart;
      end
      else
      begin
        FRangeStart := T;
        FRangeEnd := 0;
        FDate := T;
      end;
    dsmMultiple:
      begin
        I := FSelected.IndexOf(T);
        if I >= 0 then
          FSelected.Delete(I)
        else
          Select(T);
        FDate := T;
      end;
  else
    if Trunc(FDate) = T then
      Exit; // keine Aenderung, kein Ereignis
    FDate := T;
  end;
  FFocusDate := T;
  Invalidate;
  Change;
end;

procedure TPPGCustomCalendar.UserPickCell(Index: Integer; Shift: TShiftState);
var
  D: TDate;
  Y, M, Dd: Word;
begin
  if (Index < 0) or (Index >= CellCount) then
    Exit;
  D := CellDate(Index);
  case FView of
    cvYear:
      begin
        // Monat gewaehlt: hinein in die Monatsansicht
        DecodeDate(FFocusDate, Y, M, Dd);
        FDisplayMonth := Index + 1;
        FFocusDate := ClampDate(EncodeDate(FDisplayYear, FDisplayMonth,
          Min(Dd, DaysInAMonth(FDisplayYear, FDisplayMonth))));
        FView := cvMonth;
        StartTransition(1);
        Invalidate;
        ViewChanged;
        if Assigned(FOnViewChange) then
          FOnViewChange(Self);
      end;
    cvDecade:
      begin
        FDisplayYear := EnsureRange(CellYear(Index), 1, 9999);
        DecodeDate(FFocusDate, Y, M, Dd);
        FFocusDate := ClampDate(EncodeDate(FDisplayYear, M, Min(Dd, DaysInAMonth(FDisplayYear, M))));
        FView := cvYear;
        StartTransition(1);
        Invalidate;
        ViewChanged;
        if Assigned(FOnViewChange) then
          FOnViewChange(Self);
      end;
  else
    begin
      // Tag im Nachbarmonat: dorthin blaettern
      DecodeDate(D, Y, M, Dd);
      if (M <> FDisplayMonth) or (Y <> FDisplayYear) then
      begin
        if D > EncodeDate(FDisplayYear, FDisplayMonth, 1) then
          StartTransition(3)
        else
          StartTransition(4);
        FDisplayYear := Y;
        FDisplayMonth := M;
      end;
      UserSelectDate(D, Shift);
    end;
  end;
end;

procedure TPPGCustomCalendar.MoveFocusDays(Delta: Integer);
begin
  SetFocusDate(FFocusDate + Delta);
end;

procedure TPPGCustomCalendar.MoveFocusMonths(Delta: Integer);
begin
  SetFocusDate(IncMonth(FFocusDate, Delta));
end;

{ ---- Maus ---- }

procedure TPPGCustomCalendar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FDownPart := PartAt(X, Y, FDownCell);
    Invalidate;
  end;
end;

procedure TPPGCustomCalendar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P: TPPGCalendarPart;
  C: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  P := PartAt(X, Y, C);
  if (P <> FHotPart) or (C <> FHotCell) then
  begin
    FHotPart := P;
    FHotCell := C;
    Invalidate;
  end;
end;

procedure TPPGCustomCalendar.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P, Down: TPPGCalendarPart;
  C, DownCell: Integer;
begin
  Down := FDownPart;
  DownCell := FDownCell;
  FDownPart := cpNone;
  FDownCell := -1;
  Invalidate;
  inherited MouseUp(Button, Shift, X, Y);
  if (Button <> mbLeft) or not Enabled then
    Exit;
  P := PartAt(X, Y, C);
  if (P <> Down) or ((P = cpCell) and (C <> DownCell)) then
    Exit;
  case P of
    cpPrev: PrevPage;
    cpNext: NextPage;
    cpTitle:
      if FView < cvDecade then
      begin
        FView := Succ(FView);
        FHotCell := -1;
        StartTransition(2);
        Invalidate;
        ViewChanged;
        if Assigned(FOnViewChange) then
          FOnViewChange(Self);
      end;
    cpCell: UserPickCell(C, Shift);
  end;
end;

procedure TPPGCustomCalendar.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if (FHotPart <> cpNone) or (FHotCell >= 0) then
  begin
    FHotPart := cpNone;
    FHotCell := -1;
    Invalidate;
  end;
end;

function TPPGCustomCalendar.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
var
  N: Integer;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  // Audit 7b: nur mit Fokus (sonst scrollt die Seite), eine Seite je Raste
  if Result or not Enabled or WheelNeedsFocus then
    Exit;
  N := WheelSteps(WheelDelta);
  while N > 0 do
  begin
    PrevPage;
    Dec(N);
  end;
  while N < 0 do
  begin
    NextPage;
    Inc(N);
  end;
  Result := True;
end;

procedure TPPGCustomCalendar.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

{ ---- Tastatur ---- }

procedure TPPGCustomCalendar.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TPPGCustomCalendar.KeyDown(var Key: Word; Shift: TShiftState);
var
  K: Word;
  Step, Row: Integer;
  Y, M, D: Word;
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
  if FView = cvMonth then
    Row := 7
  else
    Row := 4;
  case K of
    VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN:
      begin
        if (ssCtrl in Shift) and ((K = VK_UP) or (K = VK_DOWN)) then
        begin
          // Strg+Oben/Unten: zoomen
          if (K = VK_UP) and (FView < cvDecade) then
          begin
            FView := Succ(FView);
            StartTransition(2);
            Invalidate;
            ViewChanged;
            if Assigned(FOnViewChange) then
              FOnViewChange(Self);
          end
          else if (K = VK_DOWN) and (FView > cvMonth) then
            UserPickCell(FocusCell, []);
          Key := 0;
          Exit;
        end;
        case K of
          VK_LEFT: Step := -1;
          VK_RIGHT: Step := 1;
          VK_UP: Step := -Row;
        else
          Step := Row;
        end;
        case FView of
          cvMonth: MoveFocusDays(Step);
          cvYear: MoveFocusMonths(Step);
        else
          MoveFocusMonths(Step * 12);
        end;
        Key := 0;
      end;
    VK_PRIOR, VK_NEXT:
      begin
        if K = VK_PRIOR then
          Step := -1
        else
          Step := 1;
        if (ssCtrl in Shift) or (FView = cvYear) then
          MoveFocusMonths(Step * 12)
        else if FView = cvDecade then
          MoveFocusMonths(Step * 120)
        else
          MoveFocusMonths(Step);
        Key := 0;
      end;
    VK_HOME, VK_END:
      if FView = cvMonth then
      begin
        DecodeDate(FFocusDate, Y, M, D);
        if K = VK_HOME then
          SetFocusDate(EncodeDate(Y, M, 1))
        else
          SetFocusDate(EncodeDate(Y, M, DaysInAMonth(Y, M)));
        Key := 0;
      end;
    VK_RETURN, VK_SPACE:
      begin
        if FView = cvMonth then
          UserSelectDate(FFocusDate, Shift)
        else
          UserPickCell(FocusCell, Shift);
        Key := 0;
      end;
  end;
end;

procedure TPPGCustomCalendar.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
  if FocusCell >= 0 then
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, FocusCell + 1);
end;

procedure TPPGCustomCalendar.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

{ ---- Zeichnen ---- }

{ TPPGCalendarStyles }

constructor TPPGCalendarStyles.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, 8);
end;

procedure TPPGCustomCalendar.SetCalendarStyles(const Value: TPPGCalendarStyles);
begin
  FCalendarStyles.Assign(Value);
end;

procedure TPPGCustomCalendar.CalendarStylesChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TPPGCustomCalendar.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  T: TPPGTokens;
  A: TPPGAppearance;
  PPI, I, Rad, WeekCol, Diam, R0, C0, Off, D0, FirstDay, Wk: Integer;
  HC, InRange, Sel, Dis, Other, IsToday: Boolean;
  Fill, Border, TextCol, Secondary, Accent, OnAccent, DisabledCol, HoverCol, C: TColor;
  CR, R, G, Body, Band, Clip: TRect;
  S: string;
  Dt: TDate;
  Y, M, D, DY, DM, DD: Word;
  Scale: Single;
  P: Single;
  Pts: array[0..2] of TPoint;
  TodayT, FocusI: Integer;
  TxtR: array[0..63] of TRect;
  TxtS: array[0..63] of string;
  TxtC: array[0..63] of TColor;
  TxtF: array[0..63] of TFont;
  NText, NHead: Integer;
  DC: HDC;
  LastColor: TColor;
  LastFont: TFont;
  Link: IPPGCalendarLink;
  Marked: Boolean;
  CS: TPPGCalendarStyles;
  UseColors, Dk, DrawIt, Weekend: Boolean;
  DS: TPPGDrawStyle;
  St: TPPGItemDrawState;
  CellFill, SelFill, TodayRing: TColor;
  TF, DayF: TFont;
  Extra: TFontStyles;

  procedure AddText(const AR: TRect; const AS_: string; AC: TColor; AF: TFont);
  begin
    if NText > High(TxtR) then
      Exit;
    TxtR[NText] := AR;
    TxtS[NText] := AS_;
    TxtC[NText] := AC;
    TxtF[NText] := AF;
    Inc(NText);
  end;

begin
  NText := 0;
  PPI := ScalePPI;
  if (FLink = nil) or not Supports(FLink, IPPGCalendarLink, Link) then
    Link := nil;
  T := Tokens;
  A := EffectiveAppearance;
  HC := HighContrastSupport and PPGIsHighContrast;
  if HC then
  begin
    Fill := PPGColorToRGB(clWindow);
    Border := PPGColorToRGB(clWindowText);
    TextCol := PPGColorToRGB(clWindowText);
    Secondary := TextCol;
    Accent := PPGColorToRGB(clHighlight);
    OnAccent := PPGColorToRGB(clHighlightText);
    DisabledCol := PPGColorToRGB(clGrayText);
  end
  else
  begin
    Fill := T.Layer;
    Border := T.Stroke;
    TextCol := T.TextPrimary;
    Secondary := T.TextSecondary;
    Accent := PPGColorToRGB(A.FocusColor);
    OnAccent := ContrastOn(Accent);
    DisabledCol := T.TextDisabled;
    if UseVclStyle then
    begin
      Fill := PPGColorToRGB(A.Normal.Color);
      TextCol := PPGColorToRGB(A.Normal.TextColor);
      Secondary := PPGBlendColor(TextCol, Fill, 0.4);
      DisabledCol := PPGBlendColor(TextCol, Fill, 0.6);
    end;
  end;
  // Element-Stile (Styles): Farben nur ohne Hochkontrast/VCL-Style
  CS := FCalendarStyles;
  UseColors := not HC and not UseVclStyle;
  Dk := UseDarkMode;
  FFonts.Clear;
  if UseColors then
  begin
    Fill := CS.Background.FillFor(Dk, Fill);
    TextCol := CS.Background.TextFor(Dk, TextCol);
    Border := CS.Background.BorderFor(Dk, Border);
  end;
  SelFill := Accent;
  TodayRing := Accent;
  if UseColors then
  begin
    SelFill := CS.Selected.FillFor(Dk, Accent);
    OnAccent := CS.Selected.TextFor(Dk, ContrastOn(SelFill));
    TodayRing := CS.Today.BorderFor(Dk, Accent);
  end;
  if not Enabled then
  begin
    TextCol := DisabledCol;
    Secondary := DisabledCol;
    Accent := PPGBlendColor(Accent, Fill, 0.5);
    SelFill := PPGBlendColor(SelFill, Fill, 0.5);
    TodayRing := PPGBlendColor(TodayRing, Fill, 0.5);
  end;
  HoverCol := TextCol;
  Body := ClientR;
  Rad := Min(PPGScale(T.RadiusLarge, PPI), (Body.Bottom - Body.Top) div 4);
  ACanvas.FillRoundRect(Body, Rad, Fill, 255);
  ACanvas.FrameRoundRect(Body, Rad, 1, Border, 255);

  // Kopf: Titel, Zurueck, Vor
  FBoldFont.Assign(Font);
  FBoldFont.Style := FBoldFont.Style + [fsBold];
  case FView of
    cvYear: S := IntToStr(FDisplayYear);
    cvDecade: S := Format('%d - %d', [DecadeStart, DecadeStart + 9]);
  else
    S := FormatSettings.LongMonthNames[FDisplayMonth] + ' ' + IntToStr(FDisplayYear);
  end;
  R := PartRect(cpTitle);
  if Enabled and (FHotPart = cpTitle) then
    ACanvas.FillRoundRect(R, PPGScale(4, PPI), HoverCol, 14);
  InflateRect(R, -PPGScale(8, PPI), 0);
  C := TextCol;
  if UseColors and Enabled then
    C := CS.Header.TextFor(Dk, C);
  ACanvas.DrawText(R, S, FFonts.ForStyle(CS.Header, FBoldFont), C,
    DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS));
  for I := 0 to 1 do
  begin
    if I = 0 then
      R := PartRect(cpPrev)
    else
      R := PartRect(cpNext);
    if Enabled and (((I = 0) and (FHotPart = cpPrev)) or ((I = 1) and (FHotPart = cpNext))) then
      ACanvas.FillRoundRect(R, PPGScale(4, PPI), HoverCol, 14);
    Off := PPGScale(4, PPI);
    // Chevron: zurueck zeigt nach links (RTL nach rechts)
    if (I = 0) <> UseRightToLeftAlignment then
    begin
      Pts[0] := Point((R.Left + R.Right) div 2 + Off div 2, (R.Top + R.Bottom) div 2 - Off);
      Pts[1] := Point((R.Left + R.Right) div 2 - Off div 2, (R.Top + R.Bottom) div 2);
      Pts[2] := Point((R.Left + R.Right) div 2 + Off div 2, (R.Top + R.Bottom) div 2 + Off);
    end
    else
    begin
      Pts[0] := Point((R.Left + R.Right) div 2 - Off div 2, (R.Top + R.Bottom) div 2 - Off);
      Pts[1] := Point((R.Left + R.Right) div 2 + Off div 2, (R.Top + R.Bottom) div 2);
      Pts[2] := Point((R.Left + R.Right) div 2 - Off div 2, (R.Top + R.Bottom) div 2 + Off);
    end;
    ACanvas.DrawPolyline(Pts, Max(1, Round(1.5 * PPI / 96)), C, 255);
  end;

  G := GridArea(Self, WeekCol);
  // Wochentage
  if FView = cvMonth then
  begin
    FirstDay := EffectiveFirstDay;
    for I := 0 to 6 do
    begin
      CR := CellRect(I);
      R := Rect(CR.Left, HeaderRect.Bottom, CR.Right, G.Top);
      D0 := (FirstDay - 1 + I) mod 7 + 1; // ISO
      S := Copy(FormatSettings.ShortDayNames[D0 mod 7 + 1], 1, 2);
      C := Secondary;
      if UseColors and Enabled then
        C := CS.DayNames.TextFor(Dk, C);
      AddText(R, S, C, FFonts.ForStyle(CS.DayNames, Font));
    end;
  end;
  NHead := NText;

  // Uebergang: Zoom (Skalierung um die Mitte) bzw. Blaettern (Verschiebung)
  P := FTransAnim.Value;
  Scale := 1;
  Off := 0;
  case FTransKind of
    1: if P < 1 then Scale := 0.85 + 0.15 * P;
    2: if P < 1 then Scale := 1.15 - 0.15 * P;
    3: if P < 1 then Off := Round((1 - P) * (G.Bottom - G.Top) * 0.25);
    4: if P < 1 then Off := -Round((1 - P) * (G.Bottom - G.Top) * 0.25);
  end;
  Clip := G;
  ACanvas.PushClipRoundRect(Clip, 0);
  try
    TodayT := Trunc(Today);
    FocusI := FocusCell;
    DecodeDate(Today, DY, DM, DD);
    for I := 0 to CellCount - 1 do
    begin
      CR := CellRect(I);
      if Scale <> 1 then
      begin
        R0 := (G.Left + G.Right) div 2;
        C0 := (G.Top + G.Bottom) div 2;
        CR := Rect(R0 + Round((CR.Left - R0) * Scale), C0 + Round((CR.Top - C0) * Scale),
          R0 + Round((CR.Right - R0) * Scale), C0 + Round((CR.Bottom - C0) * Scale));
      end;
      OffsetRect(CR, 0, Off);
      Dt := CellDate(I);
      DecodeDate(Dt, Y, M, D);
      Marked := False;
      case FView of
        cvYear:
          begin
            S := FormatSettings.ShortMonthNames[M];
            Sel := (FDate <> 0) and (YearOf(FDate) = Y) and (MonthOf(FDate) = M);
            IsToday := (DY = Y) and (DM = M);
            Other := False;
            Dis := ((FMinDate <> 0) and (EndOfTheMonth(Dt) < FMinDate)) or
              ((FMaxDate <> 0) and (Dt > FMaxDate));
            InRange := False;
          end;
        cvDecade:
          begin
            S := IntToStr(CellYear(I));
            Sel := (FDate <> 0) and (YearOf(FDate) = CellYear(I));
            IsToday := DY = CellYear(I);
            Other := (I = 0) or (I = CellCount - 1);
            Dis := ((FMinDate <> 0) and (CellYear(I) < YearOf(FMinDate))) or
              ((FMaxDate <> 0) and (CellYear(I) > YearOf(FMaxDate)));
            InRange := False;
          end;
      else
        S := IntToStr(D);
        Sel := IsSelected(Dt);
        IsToday := FShowToday and (Trunc(Dt) = TodayT);
        Other := M <> FDisplayMonth;
        Dis := IsDateDisabled(Dt);
        InRange := (FSelectionMode = dsmRange) and (FRangeEnd <> 0) and Sel;
        Marked := (Link <> nil) and Link.CalendarDateMarked(Dt);
      end;
      // Wochenende (Monatsansicht) und eigenes Zeichnen des Tages
      Weekend := (FView = cvMonth) and (DayOfTheWeek(Dt) >= 6);
      DS.Reset;
      DrawIt := True;
      if (FView = cvMonth) and Assigned(FOnCustomDrawDay) then
      begin
        St := [];
        if Sel then
          Include(St, idsSelected);
        if Enabled and (I = FHotCell) then
          Include(St, idsHot);
        if Dis then
          Include(St, idsDisabled);
        if IsToday then
          Include(St, idsToday);
        if I = FocusCell then
          Include(St, idsFocused);
        DC := ACanvas.BeginGdi;
        try
          FDrawCanvas.Handle := DC;
          try
            FDrawCanvas.Font := Font;
            FDrawCanvas.Brush.Style := bsClear;
            FOnCustomDrawDay(Self, FDrawCanvas, Dt, CR, St, DS, DrawIt);
          finally
            FDrawCanvas.Handle := 0;
          end;
        finally
          ACanvas.EndGdi(DC);
        end;
      end;
      if not DrawIt then
        Continue;
      Diam := Min(CR.Right - CR.Left, CR.Bottom - CR.Top) - PPGScale(4, PPI);
      if FView = cvMonth then
        R := Rect((CR.Left + CR.Right - Diam) div 2, (CR.Top + CR.Bottom - Diam) div 2,
          (CR.Left + CR.Right + Diam) div 2, (CR.Top + CR.Bottom + Diam) div 2)
      else
      begin
        R := CR;
        InflateRect(R, -PPGScale(4, PPI), -PPGScale(4, PPI));
      end;
      // Bereichsband zwischen Anfang und Ende
      if InRange and (Trunc(FRangeEnd) > Trunc(FRangeStart)) then
      begin
        Band := Rect(CR.Left, R.Top, CR.Right, R.Bottom);
        if Trunc(Dt) = Trunc(FRangeStart) then
          if UseRightToLeftAlignment then
            Band.Right := (CR.Left + CR.Right) div 2
          else
            Band.Left := (CR.Left + CR.Right) div 2;
        if Trunc(Dt) = Trunc(FRangeEnd) then
          if UseRightToLeftAlignment then
            Band.Left := (CR.Left + CR.Right) div 2
          else
            Band.Right := (CR.Left + CR.Right) div 2;
        ACanvas.FillRoundRect(Band, 0, Accent, 50);
      end;
      if FView = cvMonth then
        Rad := Diam div 2
      else
        Rad := PPGScale(4, PPI);
      // Endpunkte (bzw. einzelne Auswahl) voll in der Akzentfarbe
      if Sel and (not InRange or (Trunc(Dt) = Trunc(FRangeStart)) or (Trunc(Dt) = Trunc(FRangeEnd))) then
      begin
        ACanvas.FillRoundRect(R, Rad, SelFill, 255);
        C := OnAccent;
      end
      else
      begin
        // Eigene Flaeche: eigenes Zeichnen > Wochenende
        CellFill := clNone;
        if UseColors and Enabled then
        begin
          if Weekend and CS.Weekend.HasFill(Dk) then
            CellFill := CS.Weekend.FillFor(Dk, clNone);
          if DS.Fill <> clNone then
            CellFill := PPGColorToRGB(DS.Fill);
        end;
        if CellFill <> clNone then
          ACanvas.FillRoundRect(R, Rad, CellFill, 255);
        if Enabled and (I = FHotCell) and not Dis then
          ACanvas.FillRoundRect(R, Rad, HoverCol, 16);
        if Dis then
          C := DisabledCol
        else if Other then
        begin
          C := Secondary;
          if UseColors and Enabled then
            C := CS.OtherMonth.TextFor(Dk, C);
        end
        else
        begin
          C := TextCol;
          if UseColors and Enabled and Weekend then
            C := CS.Weekend.TextFor(Dk, C);
        end;
        if UseColors and Enabled and not Dis and (DS.TextColor <> clNone) then
          C := PPGColorToRGB(DS.TextColor);
      end;
      // Schrift: fett fuer markierte Tage, dazu Wochenende und eigenes Zeichnen
      Extra := DS.FontStyle;
      if Marked then
        Include(Extra, fsBold);
      if Weekend then
        DayF := FFonts.ForStyle(CS.Weekend, Font, Extra)
      else
        DayF := FFonts.Get(Font, Extra);
      if IsToday then
      begin
        if Sel then
          ACanvas.FrameRoundRect(Rect(R.Left + 2, R.Top + 2, R.Right - 2, R.Bottom - 2),
            Max(0, Rad - 2), Max(1, PPGScale(1, PPI)), OnAccent, 255)
        else
          ACanvas.FrameRoundRect(R, Rad, Max(1, PPGScale(1, PPI)) + 1, TodayRing, 255);
      end;
      if IsToday and not Sel then
      begin
        C := Accent;
        if UseColors and Enabled then
          C := CS.Today.TextFor(Dk, C);
        TF := FFonts.ForStyle(CS.Today, FBoldFont, DS.FontStyle);
        AddText(CR, S, C, TF);
      end
      else
        AddText(CR, S, C, DayF);
      if ((FocusVisible and Focused) or FShowFocusAlways) and (I = FocusI) then
        ACanvas.FrameRoundRect(Rect(R.Left - 2, R.Top - 2, R.Right + 2, R.Bottom + 2), Rad + 2,
          PPGScale(2, PPI), PPGColorToRGB(A.FocusColor), 255);
    end;
    // Wochennummern (ISO 8601)
    if WeekCol > 0 then
      for I := 0 to Rows - 1 do
      begin
        CR := CellRect(I * 7);
        if UseRightToLeftAlignment then
          R := Rect(CR.Right, CR.Top, CR.Right + WeekCol, CR.Bottom)
        else
          R := Rect(CR.Left - WeekCol, CR.Top, CR.Left, CR.Bottom);
        OffsetRect(R, 0, Off);
        Wk := WeekNumberOfRow(I);
        C := Secondary;
        if UseColors and Enabled then
          C := CS.WeekNumbers.TextFor(Dk, C);
        AddText(R, IntToStr(Wk), C, FFonts.ForStyle(CS.WeekNumbers, Font));
      end;
  finally
    ACanvas.PopClip;
  end;
  // Alle Texte in einem GDI-Block (42 einzelne GDI+-Textaufrufe waeren der
  // groesste Kostenpunkt): Wochentage frei, Zellen auf das Raster geschnitten
  if NText > 0 then
  begin
    DC := ACanvas.BeginGdi;
    try
      SetBkMode(DC, TRANSPARENT);
      LastColor := clNone;
      LastFont := Font;
      SelectObject(DC, Font.Handle);
      for I := 0 to NText - 1 do
      begin
        if I = NHead then
          IntersectClipRect(DC, G.Left, G.Top, G.Right, G.Bottom);
        if (TxtF[I] <> nil) and (TxtF[I] <> LastFont) then
        begin
          SelectObject(DC, TxtF[I].Handle);
          LastFont := TxtF[I];
        end;
        if TxtC[I] <> LastColor then
        begin
          Winapi.Windows.SetTextColor(DC, ColorToRGB(TxtC[I]));
          LastColor := TxtC[I];
        end;
        R := TxtR[I];
        Winapi.Windows.DrawText(DC, PChar(TxtS[I]), Length(TxtS[I]), R,
          DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
      end;
    finally
      ACanvas.EndGdi(DC); // stellt Schrift, Clip und Modus wieder her
    end;
  end;
  FFonts.Clear; // keine Schrift-Handles ueber das Zeichnen hinaus
end;

function TPPGCustomCalendar.WeekNumberOfRow(Row: Integer): Integer;
begin
  // Woche der Zeilenmitte: bei Wochenbeginn Montag exakt ISO, sonst die Woche
  // mit den meisten Tagen der Zeile
  Result := WeekOf(FirstVisibleDate + Row * 7 + 3);
end;

{ ---- Barrierefreiheit ---- }

procedure TPPGCustomCalendar.WndProc(var Message: TMessage);
begin
  if (GMsgCalAction <> 0) and (Message.Msg = GMsgCalAction) then
  begin
    // Aus AccChildDoDefault gepostet (ausserhalb des COM-Aufrufs)
    UserPickCell(Integer(Message.WParam) - 1, []);
    Exit;
  end;
  inherited WndProc(Message);
end;

function TPPGCustomCalendar.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_TABLE;
end;

function TPPGCustomCalendar.AccValue: string;
begin
  if FDate = 0 then
    Result := ''
  else
    Result := FormatDateTime(FormatSettings.LongDateFormat, FDate);
end;

function TPPGCustomCalendar.AccChildCount: Integer;
begin
  Result := CellCount;
end;

function TPPGCustomCalendar.AccChildName(Id: Integer): string;
var
  D: TDate;
begin
  if (Id < 1) or (Id > CellCount) then
    Exit('');
  D := CellDate(Id - 1);
  case FView of
    cvYear: Result := FormatSettings.LongMonthNames[MonthOf(D)] + ' ' + IntToStr(YearOf(D));
    cvDecade: Result := IntToStr(CellYear(Id - 1));
  else
    Result := FormatDateTime(FormatSettings.LongDateFormat, D);
  end;
end;

function TPPGCustomCalendar.AccChildRole(Id: Integer): Integer;
begin
  Result := ROLE_SYSTEM_CELL;
end;

function TPPGCustomCalendar.AccChildState(Id: Integer): Integer;
var
  D: TDate;
begin
  Result := STATE_SYSTEM_SELECTABLE or STATE_SYSTEM_FOCUSABLE;
  if (Id < 1) or (Id > CellCount) then
    Exit;
  D := CellDate(Id - 1);
  if (FView = cvMonth) then
  begin
    if IsSelected(D) then
      Result := Result or STATE_SYSTEM_SELECTED;
    if IsDateDisabled(D) then
      Result := STATE_SYSTEM_UNAVAILABLE;
  end;
  if Focused and (Id - 1 = FocusCell) then
    Result := Result or STATE_SYSTEM_FOCUSED;
end;

function TPPGCustomCalendar.AccChildRect(Id: Integer): TRect;
begin
  Result := CellRect(Id - 1);
end;

function TPPGCustomCalendar.AccChildAt(X, Y: Integer): Integer;
begin
  Result := CellFromPoint(X, Y) + 1;
end;

function TPPGCustomCalendar.AccChildDefaultAction(Id: Integer): string;
begin
  Result := PPGStr(@SPPGAccSelect);
end;

procedure TPPGCustomCalendar.AccChildDoDefault(Id: Integer);
begin
  if HandleAllocated then
    PostMessage(Handle, GMsgCalAction, WPARAM(Id), 0);
end;

function TPPGCustomCalendar.AccFocusedChild: Integer;
begin
  if Focused then
    Result := FocusCell + 1
  else
    Result := 0;
end;

function TPPGCustomCalendar.AccSelectedChild: Integer;
var
  I: Integer;
begin
  Result := 0;
  if (FView <> cvMonth) or (FDate = 0) then
    Exit;
  I := Trunc(FDate) - Trunc(FirstVisibleDate);
  if (I >= 0) and (I < CellCount) then
    Result := I + 1;
end;

end.
