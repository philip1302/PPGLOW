unit PPG.Planner;

{ TPPGPlanner - Terminplaner (Phase 14a).

  - Ansichten: Tag (DayCount Tage), Arbeitswoche (WorkDays), Woche, Monat
    (6 Wochen), Zeitleiste (waagerecht, Zeilen = Ressourcen) und Agenda
    (Liste nach Tagen).
  - Termine kommen aus Appointments (Collection, im DFM) oder einer eigenen
    IPPGAppointmentSource (Source); abgefragt wird nur der sichtbare Zeitraum.
  - Zeiten: Anzeige in der Zone TimeZone ('' = Rechner), gespeichert nach
    TimeZoneMode (Vorgabe UTC). Das Zeitraster ist die Wanduhr: am Tag der
    Sommerzeit-Umstellung hat jede Spalte 24 Felder (wie Outlook); ein Termin
    02:00-04:00 Ortszeit belegt zwei Stunden, dauert aber nur eine.
  - Ganztaegige und mehrtaegige Termine (Dauer >= 1 Tag) liegen im Band ueber
    dem Raster; Termine ueber Mitternacht werden auf die Tage geteilt und
    bekommen Fortsetzungsmarken.
  - Ressourcen (Resources) werden als Spaltengruppen (GroupByResource) bzw.
    als Zeilen der Zeitleiste gezeigt.
  - Bedienung: Ziehen verschiebt (Strg kopiert), die Kanten aendern die Dauer,
    alles rastet am Raster (SlotMinutes). Ziehen auf freier Flaeche waehlt
    Zeitfelder; Doppelklick, Enter oder Tippen legt einen Termin an
    (OnCreateAppointment, abbrechbar) und oeffnet die Bearbeitung des
    Betreffs. Vorkommen einer Serie werden beim Aendern herausgeloest.
  - Ereignisse: OnAppointmentChanging (abbrechbar, Werte aenderbar),
    OnAppointmentChanged, OnAppointmentCreated, OnDeleting, OnAppointmentOpen,
    OnSelectionChange, OnRangeChange. Code (Date := ...) loest nur
    OnRangeChange aus (die DB-Variante laedt darueber nach).
  - Tastatur: Pfeile wandern durch die Zeitfelder (Umschalt erweitert), Tab
    durch die Termine, Strg+Pfeile verschieben den gewaehlten Termin,
    Strg+Umschalt+Oben/Unten aendern die Dauer, Enter oeffnet bzw. legt an,
    F2 bearbeitet den Betreff, Entf loescht, Bild auf/ab blaettert, Pos1
    springt zu heute.
  - "Jetzt"-Linie ueber den Animator (Schleife, neu gezeichnet nur bei einer
    neuen Minute), kein eigener Timer.
  - Calendar: verbundener TPPGCalendar zeigt Tage mit Terminen fett, seine
    Auswahl stellt den Zeitraum ein.
  - Screenreader: Tabelle, Kinder sind die sichtbaren Termine
    ("Betreff, Beginn bis Ende, Ort"). RTL gespiegelt. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Base,
  PPG.Controls.Scroll, PPG.Edit, PPG.Calendar, PPG.TimeZones, PPG.Planner.Model, PPG.ElementStyle, PPG.CustomDraw;

type
  TPPGPlannerView = (pvDay, pvWorkWeek, pvWeek, pvMonth, pvTimeline, pvAgenda);
  TPPGWeekDay = (wdMonday, wdTuesday, wdWednesday, wdThursday, wdFriday, wdSaturday, wdSunday);
  TPPGWeekDays = set of TPPGWeekDay;

  TPPGPlannerHitKind = (phNone, phHeader, phAllDay, phSlot, phAppointment, phResizeStart,
    phResizeEnd, phMore);

  TPPGPlannerHit = record
    Kind: TPPGPlannerHitKind;
    /// Beginn des Zeitfelds bzw. Tag unter dem Punkt (Anzeige-Zeit).
    Time: TDateTime;
    ResourceId: Integer;
    /// Vorkommen (Index in Items), sonst -1.
    Item: Integer;
  end;

  /// Lage eines Stuecks: fest (Kopf, Band, Monat) oder im gescrollten Inhalt.
  TPPGPlannerArea = (paFixed, paBodyY, paBodyXY);

  /// Sichtbares Stueck eines Termins (ein Termin ueber mehrere Tage hat
  /// mehrere Stuecke).
  TPPGPlannerPiece = record
    Item: Integer;
    R: TRect;
    Area: TPPGPlannerArea;
    Band: Boolean;
    ContBefore, ContAfter: Boolean;
  end;

  TPPGAppointmentChangeKind = (ackMove, ackResize, ackCopy, ackSubject, ackLocation, ackDialog);

  /// Aendern eines Vorkommens einer Serie: nachfragen (Vorgabe), immer nur
  /// das Vorkommen (herausloesen) oder immer die ganze Serie.
  TPPGSeriesEditMode = (semAsk, semOccurrence, semSeries);
  TPPGSeriesAction = (saMove, saResize, saSubject, saLocation, saDelete, saEdit);
  TPPGSeriesChoice = (scOccurrence, scSeries, scCancel);
  TPPGSeriesEditEvent = procedure(Sender: TObject; const Occurrence: TPPGOccurrence;
    Action: TPPGSeriesAction; var Choice: TPPGSeriesChoice) of object;

  TPPGAppointmentChangingEvent = procedure(Sender: TObject; Appointment: TPPGAppointment;
    Kind: TPPGAppointmentChangeKind; var NewStart, NewFinish: TDateTime;
    var NewResourceId: Integer; var Allow: Boolean) of object;
  TPPGAppointmentEvent = procedure(Sender: TObject; Appointment: TPPGAppointment) of object;
  TPPGAppointmentAllowEvent = procedure(Sender: TObject; Appointment: TPPGAppointment;
    var Allow: Boolean) of object;
  TPPGCreateAppointmentEvent = procedure(Sender: TObject; AStart, AFinish: TDateTime;
    AResourceId: Integer; AAllDay: Boolean; var Allow: Boolean) of object;
  TPPGAppointmentColorEvent = procedure(Sender: TObject; Appointment: TPPGAppointment;
    var AColor: TColor) of object;

  TPPGPlannerResource = class(TCollectionItem)
  private
    FId: Integer;
    FCaption: string;
    FColor: TColor;
    procedure SetId(const Value: Integer);
    procedure SetCaption(const Value: string);
    procedure SetColor(const Value: TColor);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
  published
    /// Wert von TPPGAppointment.ResourceId. Neue Ressourcen (Collection-
    /// Editor, Add) bekommen die naechste freie Nummer; beim Laden gilt der
    /// gespeicherte Wert (fehlt er in alten DFMs, bleibt es 0). Ohne
    /// default, damit auch 0 gespeichert wird.
    property Id: Integer read FId write SetId;
    property Caption: string read FCaption write SetCaption;
    /// Farbe der Termine ohne Kategorie (clDefault = Akzent).
    property Color: TColor read FColor write SetColor default clDefault;
  end;

  TPPGPlannerResources = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGPlannerResource;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TPPGPlannerResource;
    function AddResource(AId: Integer; const ACaption: string): TPPGPlannerResource;
    function IndexOfId(AId: Integer): Integer;
    property Items[Index: Integer]: TPPGPlannerResource read GetItem; default;
  end;

  /// Kategorie (wie Outlook): Name und Farbe; Appointment.Category = Index.
  TPPGPlannerCategory = class(TCollectionItem)
  private
    FCaption: string;
    FColor: TColor;
    procedure SetCaption(const Value: string);
    procedure SetColor(const Value: TColor);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
  published
    property Caption: string read FCaption write SetCaption;
    /// clDefault = Farbe aus der Diagrammpalette.
    property Color: TColor read FColor write SetColor default clDefault;
  end;

  TPPGPlannerCategories = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGPlannerCategory;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    function Add: TPPGPlannerCategory;
    /// Kategorie mit Name und Farbe anfuegen (Index = Wert fuer Appointment.Category).
    function AddCategory(const ACaption: string; AColor: TColor): TPPGPlannerCategory;
    property Items[Index: Integer]: TPPGPlannerCategory read GetItem; default;
  end;

  /// Bereiche des Planers (nur gesetzte Werte zaehlen, clDefault = Preset).
  TPPGPlannerStyles = class(TPPGStyleGroup)
  public
    constructor Create(AOwner: TPersistent);
  published
    /// Flaeche (Color), Text (TextColor), Linien (BorderColor).
    property Background: TPPGElementStyle index 0 read GetItem write SetItem;
    /// Kopf (Tage, Ressourcen): Color, TextColor, Schrift.
    property Header: TPPGElementStyle index 1 read GetItem write SetItem;
    /// Zeitleiste: TextColor, Schrift.
    property TimeRuler: TPPGElementStyle index 2 read GetItem write SetItem;
    /// Ausserhalb der Arbeitszeit und freie Tage (Color).
    property NonWorkHours: TPPGElementStyle index 3 read GetItem write SetItem;
    /// Heute: TextColor = Tageskopf, BorderColor = Markierung.
    property Today: TPPGElementStyle index 4 read GetItem write SetItem;
    /// Jetzt-Linie (Color).
    property NowLine: TPPGElementStyle index 5 read GetItem write SetItem;
    /// Termine: TextColor, Schrift.
    property Appointment: TPPGElementStyle index 6 read GetItem write SetItem;
    /// Gewaehlte Zeitfelder (Color).
    property SelectedSlot: TPPGElementStyle index 7 read GetItem write SetItem;
  end;

  /// Vor dem Zeichnen eines Termins: Style (Fill = Terminfarbe, TextColor,
  /// FontStyle fett) oder ganz selbst zeichnen (DefaultDraw = False).
  TPPGPlannerDrawEvent = procedure(Sender: TObject; Canvas: TCanvas; Appointment: TPPGAppointment;
    const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
    var DefaultDraw: Boolean) of object;

  TPPGPlannerEdit = class(TPPGEdit)
  protected
    function WantSpecialKey(Key: Word): Boolean; override;
  end;

  TPPGPlannerDrag = (pdNone, pdSelect, pdPending, pdMove, pdResizeStart, pdResizeEnd);

  TPPGAgendaRow = record
    Day: TDate;
    Item: Integer;  // -1 = Tageskopf
    Top, Height: Integer;
  end;

  TPPGCustomPlanner = class(TPPGCustomScrollControl, IPPGAppointmentsHost, IPPGCalendarLink,
    IPPGAccessibleChildren)
  private
    FAppointments: TPPGAppointments;
    FResources: TPPGPlannerResources;
    FCategories: TPPGPlannerCategories;
    FPlannerStyles: TPPGPlannerStyles;
    FOnCustomDrawAppointment: TPPGPlannerDrawEvent;
    FDrawCanvas: TCanvas;
    FFonts: TPPGFontCache;
    FSource: IPPGAppointmentSource;
    FView: TPPGPlannerView;
    FDate: TDate;
    FDayCount: Integer;
    FFirstDayOfWeek: TPPGFirstDayOfWeek;
    FWorkDays: TPPGWeekDays;
    FWorkStart: Integer;
    FWorkEnd: Integer;
    FDayStartHour: Integer;
    FDayEndHour: Integer;
    FSlotMinutes: Integer;
    FSlotHeight: Integer;
    FSlotWidth: Integer;
    FTimelineDays: Integer;
    FAgendaDays: Integer;
    FGroupByResource: Boolean;
    FShowNowLine: Boolean;
    FReadOnly: Boolean;
    FTimeZone: string;
    FCalendar: TPPGCustomCalendar;
    FNowOverride: TDateTime;
    FBoldFont: TFont;
    // Layout
    FLayoutValid: Boolean;
    FV: TRect;
    FRtl: Boolean;
    FDays: TArray<TDate>;
    FResCols: TArray<Integer>;
    FGrouped: Boolean;
    FItems: TArray<TPPGOccurrence>;
    FPieces: TArray<TPPGPlannerPiece>;
    FPieceCount: Integer;
    FColX: TArray<Integer>;
    FRowY: TArray<Integer>;
    FHeadH: Integer;
    FHeaderH: Integer;
    FBandH: Integer;
    FBodyH: Integer;
    FBodyW: Integer;
    FBodyLeft: Integer;
    FMore: TArray<Integer>;
    FMonthLines: Integer;
    FTLRowTop: TArray<Integer>;
    FTLRowH: TArray<Integer>;
    FAgenda: TArray<TPPGAgendaRow>;
    FInitialScroll: Boolean;
    // Auswahl
    FSelItem: Integer;
    FSelAppt: TPPGAppointment;
    FSelOccStart: TDateTime;
    FSelFrom: TDateTime;
    FSelTo: TDateTime;
    FSelAnchor: TDateTime;
    FSelRes: Integer;
    FSelAllDay: Boolean;
    // Ziehen
    FDrag: TPPGPlannerDrag;
    FDragItem: Integer;
    FDragOcc: TPPGOccurrence;
    FDragDown: TPoint;
    FDragHit: TPPGPlannerHit;
    FDragBand: Boolean;
    FGhostStart: TDateTime;
    FGhostFinish: TDateTime;
    FGhostRes: Integer;
    FGhostCopy: Boolean;
    FHot: TPPGPlannerHit;
    // Bearbeiten
    FEditor: TPPGPlannerEdit;
    FEditAppt: TPPGAppointment;
    FEditNew: Boolean;
    FEditLocation: Boolean;
    FEditOcc: TPPGOccurrence;
    FSeriesEditMode: TPPGSeriesEditMode;
    FDefaultEditor: Boolean;
    FOnSeriesEdit: TPPGSeriesEditEvent;
    // Kalender-Markierungen
    FMarkFrom: Integer;
    FMarkTo: Integer;
    FMarks: TArray<Boolean>;
    // Jetzt-Linie
    FNowAnim: TPPGAnimation;
    FNowMinute: Integer;
    FUpdatingCalendar: Boolean;
    FOnAppointmentChanging: TPPGAppointmentChangingEvent;
    FOnAppointmentChanged: TPPGAppointmentEvent;
    FOnAppointmentCreated: TPPGAppointmentEvent;
    FOnAppointmentOpen: TPPGAppointmentEvent;
    FOnDeleting: TPPGAppointmentAllowEvent;
    FOnCreateAppointment: TPPGCreateAppointmentEvent;
    FOnGetAppointmentColor: TPPGAppointmentColorEvent;
    FOnSelectionChange: TNotifyEvent;
    FOnRangeChange: TNotifyEvent;
    procedure SetCategories(const Value: TPPGPlannerCategories);
    procedure SetPlannerStyles(const Value: TPPGPlannerStyles);
    procedure PlannerStylesChanged(Sender: TObject);
    procedure SetAppointments(const Value: TPPGAppointments);
    procedure SetResources(const Value: TPPGPlannerResources);
    procedure SetSource(const Value: IPPGAppointmentSource);
    procedure SetView(const Value: TPPGPlannerView);
    procedure SetDate(const Value: TDate);
    procedure SetDayCount(const Value: Integer);
    procedure SetFirstDayOfWeek(const Value: TPPGFirstDayOfWeek);
    procedure SetWorkDays(const Value: TPPGWeekDays);
    procedure SetWorkStart(const Value: Integer);
    procedure SetWorkEnd(const Value: Integer);
    procedure SetDayStartHour(const Value: Integer);
    procedure SetDayEndHour(const Value: Integer);
    procedure SetSlotMinutes(const Value: Integer);
    procedure SetSlotHeight(const Value: Integer);
    procedure SetSlotWidth(const Value: Integer);
    procedure SetTimelineDays(const Value: Integer);
    procedure SetAgendaDays(const Value: Integer);
    procedure SetGroupByResource(const Value: Boolean);
    procedure SetShowNowLine(const Value: Boolean);
    procedure SetTimeZone(const Value: string);
    function GetTimeZoneMode: TPPGTimeZoneMode;
    procedure SetTimeZoneMode(const Value: TPPGTimeZoneMode);
    procedure SetCalendar(const Value: TPPGCustomCalendar);
    function GetRangeStart: TDateTime;
    function GetRangeEnd: TDateTime;
    function GetSelectedAppointment: TPPGAppointment;
    // Layout
    function S(V: Integer): Integer;
    function SlotH: Integer;
    function SlotW: Integer;
    function SlotCount: Integer;
    function IsTimeGrid: Boolean;
    function WeekStart(D: TDate): TDate;
    procedure ComputeDays;
    procedure LayoutTimeGrid;
    procedure LayoutMonth;
    procedure LayoutTimeline;
    procedure LayoutAgenda;
    procedure AddPiece(AItem: Integer; const AR: TRect; AArea: TPPGPlannerArea;
      ABand, ABefore, AAfter: Boolean);
    function InBand(const O: TPPGOccurrence): Boolean;
    function DayIndexFrom(T: TDateTime): Integer;
    function DayIndexTo(T: TDateTime): Integer;
    function GroupOf(ResourceId: Integer): Integer;
    function TimeToY(Day: TDate; T: TDateTime): Integer;
    function TimeToX(T: TDateTime): Integer;
    function XToTime(X: Integer; Round_: Boolean): TDateTime;
    function DayHeaderText(D: TDate; Width: Integer): string;
    function Mirror(const R: TRect): TRect;
    function LogicalRect(const R: TRect; Area: TPPGPlannerArea): TRect;
    function ColumnAt(LX: Integer): Integer;
    function HitLogical(LX, LY: Integer): TPPGPlannerHit;
    function ItemFirstPiece(Item: Integer): Integer;
    procedure RestoreSelection;
    // Zeichnen
    procedure PaintTimeGrid(const ACanvas: IPPGCanvas);
    procedure PaintMonth(const ACanvas: IPPGCanvas);
    procedure PaintTimeline(const ACanvas: IPPGCanvas);
    procedure PaintAgenda(const ACanvas: IPPGCanvas);
    procedure PaintPieces(const ACanvas: IPPGCanvas; const Clip: TRect; Areas: array of TPPGPlannerArea);
    procedure PaintGhost(const ACanvas: IPPGCanvas);
    function GhostRects: TArray<TRect>;
    // Ziehen / Auswahl
    procedure StartDrag(const Hit: TPPGPlannerHit; Shift: TShiftState);
    procedure UpdateDrag(X, Y: Integer; Shift: TShiftState);
    procedure FinishDrag(Commit: Boolean);
    procedure SetSlotSelection(AFrom, ATo: TDateTime; ARes: Integer; AAllDay: Boolean);
    procedure SelectItemIndex(Item: Integer; Notify: Boolean);
    procedure MoveSlotFocus(DSlots, DDays: Integer; Extend: Boolean);
    procedure SelectNextItem(Backwards: Boolean);
    function CurrentSlotLength: TDateTime;
    // Bearbeiten
    procedure EditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditorExit(Sender: TObject);
    procedure BeginEditField(Location: Boolean; InitialChar: Char);
    procedure OpenItem(Item: Integer);
    // Jetzt-Linie
    procedure NowStep(Sender: TObject);
    procedure UpdateNowLoop;
    procedure UserSetDate(D: TDate);
    procedure SyncCalendar;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure CreateWnd; override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure WndProc(var Message: TMessage); override;
    procedure PaintViewport(const ACanvas: IPPGCanvas; const View: TRect); override;
    procedure ContentMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure ContentMouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure ContentMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoAutoScroll(const P: TPoint); override;
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    function LineHeight: Integer; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure ThemeChanged; override;
    { Erweiterungspunkte (DB-Planer) }
    /// Neuer Termin im Speicher (Vorgabe: in Appointments).
    function DoCreateAppointment(AStart, AFinish: TDateTime; AResourceId: Integer;
      AAllDay: Boolean): TPPGAppointment; virtual;
    procedure DoDeleteAppointment(A: TPPGAppointment); virtual;
    /// Nach jeder Aenderung eines Termins durch den Anwender (DB: schreiben).
    procedure AppointmentWritten(A: TPPGAppointment); virtual;
    /// Sichtbarer Zeitraum hat sich geaendert.
    procedure RangeChanged; virtual;
    procedure SelectionChanged; virtual;
    function AppointmentColor(A: TPPGAppointment): TColor; virtual;
    /// Abfrage "nur dieses Vorkommen oder ganze Serie" (Vorgabe: Aufgabendialog).
    function DoAskSeries(const Occ: TPPGOccurrence; Action: TPPGSeriesAction): TPPGSeriesChoice; virtual;
    { IPPGAppointmentsHost }
    procedure AppointmentsChanged;
    procedure AppointmentRemoving(A: TPPGAppointment);
    { IPPGCalendarLink }
    function CalendarDateMarked(ADate: TDate): Boolean;
    procedure CalendarDateSelected(Sender: TObject; ADate: TDate);
    { Barrierefreiheit }
    function AccRole: Integer; override;
    function AccValue: string; override;
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

    property Resources: TPPGPlannerResources read FResources write SetResources;
    /// Kategorien mit Name und Farbe (Appointment.Category = Index).
    property Categories: TPPGPlannerCategories read FCategories write SetCategories;
    /// Bereiche (Hintergrund, Kopf, Zeitleiste, Arbeitszeit, Heute, Jetzt-Linie ...).
    property PlannerStyles: TPPGPlannerStyles read FPlannerStyles write SetPlannerStyles;
    property OnCustomDrawAppointment: TPPGPlannerDrawEvent read FOnCustomDrawAppointment
      write FOnCustomDrawAppointment;
    property View: TPPGPlannerView read FView write SetView default pvWeek;
    /// Bezugstag des Zeitraums (nicht gespeichert: Vorgabe heute).
    property Date: TDate read FDate write SetDate stored False;
    property DayCount: Integer read FDayCount write SetDayCount default 1;
    property FirstDayOfWeek: TPPGFirstDayOfWeek read FFirstDayOfWeek write SetFirstDayOfWeek default fdLocale;
    property WorkDays: TPPGWeekDays read FWorkDays write SetWorkDays
      default [wdMonday, wdTuesday, wdWednesday, wdThursday, wdFriday];
    /// Arbeitszeit in Minuten nach Mitternacht.
    property WorkStart: Integer read FWorkStart write SetWorkStart default 480;
    property WorkEnd: Integer read FWorkEnd write SetWorkEnd default 1020;
    /// Gezeigte Stunden des Rasters (0..24).
    property DayStartHour: Integer read FDayStartHour write SetDayStartHour default 0;
    property DayEndHour: Integer read FDayEndHour write SetDayEndHour default 24;
    /// Raster in Minuten: 5, 10, 15, 20, 30 oder 60.
    property SlotMinutes: Integer read FSlotMinutes write SetSlotMinutes default 30;
    property SlotHeight: Integer read FSlotHeight write SetSlotHeight default 22;
    /// Breite eines Felds in der Zeitleiste (logische px).
    property SlotWidth: Integer read FSlotWidth write SetSlotWidth default 40;
    property TimelineDays: Integer read FTimelineDays write SetTimelineDays default 7;
    property AgendaDays: Integer read FAgendaDays write SetAgendaDays default 14;
    property GroupByResource: Boolean read FGroupByResource write SetGroupByResource default True;
    property ShowNowLine: Boolean read FShowNowLine write SetShowNowLine default True;
    property ReadOnly: Boolean read FReadOnly write FReadOnly default False;
    /// Anzeige-Zone (Windows- oder IANA-Name); '' = Zone des Rechners.
    property TimeZone: string read FTimeZone write SetTimeZone;
    property TimeZoneMode: TPPGTimeZoneMode read GetTimeZoneMode write SetTimeZoneMode default tzmUtc;
    property Calendar: TPPGCustomCalendar read FCalendar write SetCalendar;
    property OnAppointmentChanging: TPPGAppointmentChangingEvent read FOnAppointmentChanging write FOnAppointmentChanging;
    property OnAppointmentChanged: TPPGAppointmentEvent read FOnAppointmentChanged write FOnAppointmentChanged;
    property OnAppointmentCreated: TPPGAppointmentEvent read FOnAppointmentCreated write FOnAppointmentCreated;
    property OnAppointmentOpen: TPPGAppointmentEvent read FOnAppointmentOpen write FOnAppointmentOpen;
    property OnDeleting: TPPGAppointmentAllowEvent read FOnDeleting write FOnDeleting;
    property OnCreateAppointment: TPPGCreateAppointmentEvent read FOnCreateAppointment write FOnCreateAppointment;
    property OnGetAppointmentColor: TPPGAppointmentColorEvent read FOnGetAppointmentColor write FOnGetAppointmentColor;
    property OnSelectionChange: TNotifyEvent read FOnSelectionChange write FOnSelectionChange;
    property OnRangeChange: TNotifyEvent read FOnRangeChange write FOnRangeChange;
    property SeriesEditMode: TPPGSeriesEditMode read FSeriesEditMode write FSeriesEditMode default semAsk;
    /// Ohne OnAppointmentOpen: Doppelklick/Enter oeffnen den Termin-Dialog
    /// (PPG.Planner.Dialog); False = Betreff direkt bearbeiten wie bisher.
    property DefaultEditor: Boolean read FDefaultEditor write FDefaultEditor default True;
    /// Ersetzt die Serienabfrage (Choice vorbelegt mit scOccurrence).
    property OnSeriesEdit: TPPGSeriesEditEvent read FOnSeriesEdit write FOnSeriesEdit;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Invalidate; override;
    /// Ansicht, Tage, Raster und Gruppierung als Text (INI-Stil, wie
    /// TPPGGrid.SaveLayout) und zurueck; ungueltige Werte werden uebergangen.
    function SaveLayout: string;
    procedure LoadLayout(const S: string);
    /// Layout jetzt berechnen (sonst beim Zeichnen bzw. bei Abfragen).
    procedure EnsureLayout;
    procedure InvalidateLayout;
    procedure NextPage;
    procedure PrevPage;
    procedure GoToToday;
    /// Erster Wochentag nach ISO (1 = Montag).
    function EffectiveFirstDay: Integer;
    /// Vorkommen in [AFrom, ATo) aus Source bzw. Appointments (Anzeige-Zeit).
    function GetOccurrences(AFrom, ATo: TDateTime): TArray<TPPGOccurrence>;
    function HitTest(X, Y: Integer): TPPGPlannerHit;
    /// Sichtbare Vorkommen (nach Beginn sortiert).
    function ItemCount: Integer;
    function Item(Index: Integer): TPPGOccurrence;
    /// Erstes Stueck eines Vorkommens in Client-Koordinaten (leer = keins).
    function ItemRect(Index: Integer): TRect;
    function PieceCount: Integer;
    function Piece(Index: Integer): TPPGPlannerPiece;
    function PieceRect(Index: Integer): TRect;
    /// Zeitfeld (Client-Koordinaten); leer, wenn nicht im Raster sichtbar.
    function SlotRect(ATime: TDateTime; AResourceId: Integer = 0): TRect;
    /// Tage der Ansicht (Spalten, Monatszellen, Zeitleiste, Agenda).
    function DayCountVisible: Integer;
    function VisibleDay(Index: Integer): TDate;
    function Now_: TDateTime;
    /// Termin waehlen (nil = keiner); scrollt ihn in die Ansicht.
    procedure SelectAppointment(A: TPPGAppointment);
    procedure SelectSlots(AFrom, ATo: TDateTime; AResourceId: Integer = 0);
    /// Wie durch den Anwender (mit Ereignissen); True = geaendert.
    function ChangeAppointment(const Occ: TPPGOccurrence; Kind: TPPGAppointmentChangeKind;
      NewStart, NewFinish: TDateTime; NewResourceId: Integer): Boolean;
    function CreateAppointment(AStart, AFinish: TDateTime; AResourceId: Integer = 0;
      AAllDay: Boolean = False; InitialChar: Char = #0): TPPGAppointment;
    function DeleteSelected: Boolean;
    /// Gewaehlten Termin verschieben (Minuten, Tage) bzw. Dauer aendern.
    function MoveSelected(DMinutes, DDays: Integer; Resize: Boolean = False): Boolean;
    procedure BeginEditSubject(InitialChar: Char = #0);
    /// Ort direkt bearbeiten (Umschalt+F2).
    procedure BeginEditLocation;
    procedure EndEditSubject(Accept: Boolean);
    /// Welcher Teil einer Serie gemeint ist (Abfrage nach SeriesEditMode);
    /// fuer Termine ohne Serie immer scOccurrence.
    function SeriesChoice(const Occ: TPPGOccurrence; Action: TPPGSeriesAction): TPPGSeriesChoice;
    /// Termin-Dialog fuer das Vorkommen Item (-1 = gewaehlter); True = geaendert.
    function EditAppointment(Item: Integer = -1): Boolean;
    function Editing: Boolean;
    /// Zeit (Anzeige) auf das Raster.
    function SnapTime(T: TDateTime): TDateTime;
    /// Termine (beim DB-Planer der Spiegel der Datenmenge, nicht gespeichert).
    property Appointments: TPPGAppointments read FAppointments write SetAppointments;
    property Source: IPPGAppointmentSource read FSource write SetSource;
    property RangeStart: TDateTime read GetRangeStart;
    property RangeEnd: TDateTime read GetRangeEnd;
    property SelectedItem: Integer read FSelItem;
    property SelectedAppointment: TPPGAppointment read GetSelectedAppointment;
    property SelStart: TDateTime read FSelFrom;
    property SelFinish: TDateTime read FSelTo;
    property SelResourceId: Integer read FSelRes;
    property SelAllDay: Boolean read FSelAllDay;
    property Editor: TPPGPlannerEdit read FEditor;
    property HeaderHeight: Integer read FHeaderH;
    property DragState: TPPGPlannerDrag read FDrag;
    /// Fester "jetzt"-Wert fuer Tests (0 = Systemzeit, Anzeige-Zeit).
    property NowOverride: TDateTime read FNowOverride write FNowOverride;
  end;

  TPPGPlanner = class(TPPGCustomPlanner)
  published
    property Appointments;
    property Resources;
    property Categories;
    property PlannerStyles;
    property View;
    property Date;
    property DayCount;
    property FirstDayOfWeek;
    property WorkDays;
    property WorkStart;
    property WorkEnd;
    property DayStartHour;
    property DayEndHour;
    property SlotMinutes;
    property SlotHeight;
    property SlotWidth;
    property TimelineDays;
    property AgendaDays;
    property GroupByResource;
    property ShowNowLine;
    property ReadOnly;
    property TimeZone;
    property TimeZoneMode;
    property Calendar;
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighContrastSupport;
    property ScrollBarMode;
    property SmoothScrolling;
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
    property OnAppointmentChanging;
    property OnAppointmentChanged;
    property OnAppointmentCreated;
    property OnAppointmentOpen;
    property OnDeleting;
    property OnCreateAppointment;
    property OnGetAppointmentColor;
    property OnCustomDrawAppointment;
    property OnSelectionChange;
    property OnRangeChange;
    property SeriesEditMode;
    property DefaultEditor;
    property OnSeriesEdit;
    property OnScroll;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnMouseDown;
    property OnMouseUp;
  end;

implementation

uses
  PPG.Lang,
  System.Math, System.DateUtils, System.UITypes, System.TypInfo, Winapi.oleacc,
  PPG.Consts, PPG.Exceptions, PPG.Appearance, PPG.DpiUtils, PPG.Tokens, PPG.Chart.Palette,
  PPG.Planner.Layout, Vcl.Dialogs, PPG.Dialogs, PPG.Planner.Dialog;

const
  HeadH = 30;        // Tageskopf
  ResHeadH = 24;     // Ressourcenkopf
  BandRowH = 22;     // Zeile im Band
  RulerW = 56;       // Zeitleiste links
  ColGap = 10;       // frei rechts in jeder Spalte (Klickflaeche)
  EdgeH = 5;         // Griff zum Aendern der Dauer
  MonthHeadH = 26;
  MonthDayH = 22;
  MonthLineH = 20;
  TLHeadH = 48;
  TLResW = 140;
  TLLaneH = 26;
  AgendaDayH = 32;
  AgendaRowH = 28;
  AgendaTimeW = 120;
  OneMinute = 1 / MinsPerDay;
  Eps = 0.5 / SecsPerDay;

var
  GMsgPlannerAction: Cardinal = 0;

type
  TCalendarAccess = class(TPPGCustomCalendar);

  TPlannerColors = record
    HC: Boolean;
    Fill, Alt, Line, LineSoft, Text, Secondary, Accent, OnAccent, NowCol, Header: TColor;
    // Anpassbarkeit (PlannerStyles)
    HeaderText, RulerText, TodayText, TodayBar, AppText, SelSlot: TColor;
  end;

  /// Texte sammeln und in einem GDI-Block zeichnen (wie im Kalender).
  TTextBatch = class
  private
    FR: array of TRect;
    FS: array of string;
    FC: array of TColor;
    FB: array of Boolean;
    FF: array of Cardinal;
    FN: Integer;
  public
    procedure Add(const R: TRect; const S: string; C: TColor; Bold: Boolean; Flags: Cardinal);
    procedure Flush(const ACanvas: IPPGCanvas; const Clip: TRect; Normal, Bold: TFont);
  end;

procedure TTextBatch.Add(const R: TRect; const S: string; C: TColor; Bold: Boolean; Flags: Cardinal);
begin
  if (S = '') or (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;
  if FN >= Length(FR) then
  begin
    SetLength(FR, FN * 2 + 16);
    SetLength(FS, Length(FR));
    SetLength(FC, Length(FR));
    SetLength(FB, Length(FR));
    SetLength(FF, Length(FR));
  end;
  FR[FN] := R;
  FS[FN] := S;
  FC[FN] := C;
  FB[FN] := Bold;
  FF[FN] := Flags;
  Inc(FN);
end;

procedure TTextBatch.Flush(const ACanvas: IPPGCanvas; const Clip: TRect; Normal, Bold: TFont);
var
  DC: HDC;
  I: Integer;
  R: TRect;
  LastC: TColor;
  LastB: Boolean;
begin
  if FN = 0 then
    Exit;
  DC := ACanvas.BeginGdi;
  try
    SetBkMode(DC, TRANSPARENT);
    IntersectClipRect(DC, Clip.Left, Clip.Top, Clip.Right, Clip.Bottom);
    SelectObject(DC, Normal.Handle);
    LastB := False;
    LastC := clNone;
    for I := 0 to FN - 1 do
    begin
      if FB[I] <> LastB then
      begin
        if FB[I] then
          SelectObject(DC, Bold.Handle)
        else
          SelectObject(DC, Normal.Handle);
        LastB := FB[I];
      end;
      if FC[I] <> LastC then
      begin
        Winapi.Windows.SetTextColor(DC, ColorToRGB(FC[I]));
        LastC := FC[I];
      end;
      R := FR[I];
      Winapi.Windows.DrawText(DC, PChar(FS[I]), Length(FS[I]), R, FF[I] or DT_NOPREFIX);
    end;
  finally
    ACanvas.EndGdi(DC);
  end;
  FN := 0;
end;

function ContrastOn(Fill: TColor): TColor;
begin
  if PPGRelativeLuminance(Fill) < 0.4 then
    Result := clWhite
  else
    Result := clBlack;
end;

function TimeText(T: TDateTime): string;
begin
  Result := FormatDateTime(FormatSettings.ShortTimeFormat, T);
end;

{ TPPGPlannerCategory }

constructor TPPGPlannerCategory.Create(Collection: TCollection);
begin
  FColor := clDefault;
  inherited Create(Collection);
end;

procedure TPPGPlannerCategory.Assign(Source: TPersistent);
begin
  if Source is TPPGPlannerCategory then
  begin
    FCaption := TPPGPlannerCategory(Source).FCaption;
    FColor := TPPGPlannerCategory(Source).FColor;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGPlannerCategory.GetDisplayName: string;
begin
  if FCaption <> '' then
    Result := FCaption
  else
    Result := inherited GetDisplayName;
end;

procedure TPPGPlannerCategory.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

procedure TPPGPlannerCategory.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Changed(False);
  end;
end;

{ TPPGPlannerCategories }

function TPPGPlannerCategories.GetItem(Index: Integer): TPPGPlannerCategory;
begin
  Result := TPPGPlannerCategory(inherited Items[Index]);
end;

function TPPGPlannerCategories.Add: TPPGPlannerCategory;
begin
  Result := TPPGPlannerCategory(inherited Add);
end;

function TPPGPlannerCategories.AddCategory(const ACaption: string;
  AColor: TColor): TPPGPlannerCategory;
begin
  Result := Add;
  Result.Caption := ACaption;
  Result.Color := AColor;
end;

procedure TPPGPlannerCategories.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if GetOwner is TControl then
    TControl(GetOwner).Invalidate;
end;

{ TPPGPlannerStyles }

constructor TPPGPlannerStyles.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, 8);
end;

{ TPPGPlannerResource }

constructor TPPGPlannerResource.Create(Collection: TCollection);
var
  I, MaxId: Integer;
  Loading: Boolean;
begin
  FColor := clDefault;
  // Audit 08.10.2026: Vorher hatten alle neuen Ressourcen Id 0, dadurch
  // funktionierten IndexOfId, ResourceId und GroupByResource nicht.
  Loading := (Collection <> nil) and (Collection.Owner is TComponent) and
    (csLoading in TComponent(Collection.Owner).ComponentState);
  if (Collection <> nil) and not Loading then
  begin
    MaxId := 0;
    for I := 0 to Collection.Count - 1 do
      if TPPGPlannerResource(Collection.Items[I]).FId > MaxId then
        MaxId := TPPGPlannerResource(Collection.Items[I]).FId;
    FId := MaxId + 1;
  end;
  inherited Create(Collection);
end;

procedure TPPGPlannerResource.Assign(Source: TPersistent);
begin
  if Source is TPPGPlannerResource then
  begin
    FId := TPPGPlannerResource(Source).FId;
    FCaption := TPPGPlannerResource(Source).FCaption;
    FColor := TPPGPlannerResource(Source).FColor;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGPlannerResource.GetDisplayName: string;
begin
  if FCaption <> '' then
    Result := FCaption
  else
    Result := inherited GetDisplayName;
end;

procedure TPPGPlannerResource.SetId(const Value: Integer);
begin
  if FId <> Value then
  begin
    FId := Value;
    Changed(False);
  end;
end;

procedure TPPGPlannerResource.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

procedure TPPGPlannerResource.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Changed(False);
  end;
end;

{ TPPGPlannerResources }

constructor TPPGPlannerResources.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TPPGPlannerResource);
end;

function TPPGPlannerResources.Add: TPPGPlannerResource;
begin
  Result := TPPGPlannerResource(inherited Add);
end;

function TPPGPlannerResources.AddResource(AId: Integer; const ACaption: string): TPPGPlannerResource;
begin
  BeginUpdate;
  try
    Result := Add;
    Result.Id := AId;
    Result.Caption := ACaption;
  finally
    EndUpdate;
  end;
end;

function TPPGPlannerResources.GetItem(Index: Integer): TPPGPlannerResource;
begin
  Result := TPPGPlannerResource(inherited Items[Index]);
end;

function TPPGPlannerResources.IndexOfId(AId: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Items[I].Id = AId then
      Exit(I);
  Result := -1;
end;

procedure TPPGPlannerResources.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if GetOwner is TPPGCustomPlanner then
    TPPGCustomPlanner(GetOwner).InvalidateLayout;
end;

{ TPPGPlannerEdit }

function TPPGPlannerEdit.WantSpecialKey(Key: Word): Boolean;
begin
  Result := (Key = VK_RETURN) or (Key = VK_ESCAPE) or inherited WantSpecialKey(Key);
end;

{ TPPGCustomPlanner }

constructor TPPGCustomPlanner.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csDoubleClicks];
  FAppointments := TPPGAppointments.Create(Self);
  FResources := TPPGPlannerResources.Create(Self);
  FCategories := TPPGPlannerCategories.Create(Self, TPPGPlannerCategory);
  FPlannerStyles := TPPGPlannerStyles.Create(Self);
  FPlannerStyles.OnChange := PlannerStylesChanged;
  FDrawCanvas := TCanvas.Create;
  FFonts := TPPGFontCache.Create;
  FView := pvWeek;
  FSeriesEditMode := semAsk;
  FDefaultEditor := True;
  FDate := System.SysUtils.Date;
  FDayCount := 1;
  FWorkDays := [wdMonday, wdTuesday, wdWednesday, wdThursday, wdFriday];
  FWorkStart := 480;
  FWorkEnd := 1020;
  FDayEndHour := 24;
  FSlotMinutes := 30;
  FSlotHeight := 22;
  FSlotWidth := 40;
  FTimelineDays := 7;
  FAgendaDays := 14;
  FGroupByResource := True;
  FShowNowLine := True;
  FSelItem := -1;
  FDragItem := -1;
  FHot.Item := -1;
  FNowMinute := -1;
  FMarkFrom := 1;
  FMarkTo := 0;
  FBoldFont := TFont.Create;
  FNowAnim := TPPGAnimation.Create(Self);
  FNowAnim.OnStep := NowStep;
  KeyboardScrolling := False;
  TabStop := True;
  Width := 640;
  Height := 480;
  if GMsgPlannerAction = 0 then
    GMsgPlannerAction := RegisterWindowMessage('PPGlow.PlannerAction');
end;

destructor TPPGCustomPlanner.Destroy;
begin
  if FNowAnim <> nil then
    FNowAnim.OnStep := nil;
  FreeAndNil(FNowAnim);
  if FCalendar <> nil then
  begin
    FCalendar.SetLink(nil);
    FCalendar.RemoveFreeNotification(Self);
    FCalendar := nil;
  end;
  FSource := nil;
  FreeAndNil(FResources);
  FreeAndNil(FCategories);
  FreeAndNil(FPlannerStyles);
  FreeAndNil(FDrawCanvas);
  FreeAndNil(FFonts);
  FreeAndNil(FAppointments);
  FreeAndNil(FBoldFont);
  inherited Destroy;
end;

procedure TPPGCustomPlanner.Loaded;
begin
  inherited Loaded;
  if FTimeZone <> '' then
    SetTimeZone(FTimeZone);
  InvalidateLayout;
end;

procedure TPPGCustomPlanner.CreateWnd;
begin
  inherited CreateWnd;
  InvalidateLayout;
end;

procedure TPPGCustomPlanner.Resize;
begin
  inherited Resize;
  FLayoutValid := False;
end;

procedure TPPGCustomPlanner.Invalidate;
begin
  inherited Invalidate;
end;

procedure TPPGCustomPlanner.InvalidateLayout;
begin
  FLayoutValid := False;
  FMarkFrom := 1;
  FMarkTo := 0;
  Invalidate;
  if FCalendar <> nil then
    FCalendar.Invalidate;
end;

procedure TPPGCustomPlanner.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FCalendar) then
    FCalendar := nil;
end;

procedure TPPGCustomPlanner.ThemeChanged;
begin
  inherited ThemeChanged;
  Invalidate;
end;

procedure TPPGCustomPlanner.CMFontChanged(var Message: TMessage);
begin
  inherited;
  InvalidateLayout;
end;

procedure TPPGCustomPlanner.CMShowingChanged(var Message: TMessage);
begin
  inherited;
  UpdateNowLoop;
end;

{ ---- Properties ---- }

procedure TPPGCustomPlanner.SetAppointments(const Value: TPPGAppointments);
begin
  FAppointments.Assign(Value);
end;

procedure TPPGCustomPlanner.SetResources(const Value: TPPGPlannerResources);
begin
  FResources.Assign(Value);
end;

procedure TPPGCustomPlanner.SetSource(const Value: IPPGAppointmentSource);
begin
  FSource := Value;
  InvalidateLayout;
end;

procedure TPPGCustomPlanner.SetView(const Value: TPPGPlannerView);
begin
  if FView <> Value then
  begin
    EndEditSubject(True);
    FView := Value;
    FInitialScroll := False;
    ScrollTo(0, 0);
    InvalidateLayout;
    RangeChanged;
  end;
end;

procedure TPPGCustomPlanner.SetDate(const Value: TDate);
var
  OldStart, OldEnd: TDateTime;
begin
  if Trunc(Value) = Trunc(FDate) then
    Exit;
  EnsureLayout;
  OldStart := RangeStart;
  OldEnd := RangeEnd;
  FDate := Trunc(Value);
  InvalidateLayout;
  ComputeDays;
  SyncCalendar;
  if (RangeStart <> OldStart) or (RangeEnd <> OldEnd) then
    RangeChanged;
end;

procedure TPPGCustomPlanner.SetDayCount(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'DayCount', Value, 1, 31);
  // Gleicher Wert: kein RangeChanged (der DB-Planer laedt dabei neu)
  if V = FDayCount then
    Exit;
  FDayCount := V;
  InvalidateLayout;
  RangeChanged;
end;

procedure TPPGCustomPlanner.SetFirstDayOfWeek(const Value: TPPGFirstDayOfWeek);
begin
  if FFirstDayOfWeek <> Value then
  begin
    FFirstDayOfWeek := Value;
    InvalidateLayout;
    RangeChanged;
  end;
end;

procedure TPPGCustomPlanner.SetWorkDays(const Value: TPPGWeekDays);
begin
  if FWorkDays <> Value then
  begin
    FWorkDays := Value;
    InvalidateLayout;
  end;
end;

procedure TPPGCustomPlanner.SetWorkStart(const Value: Integer);
begin
  FWorkStart := PPGCheckRange(Self, 'WorkStart', Value, 0, MinsPerDay);
  // Wie DayStartHour/DayEndHour: die Gegenseite folgt, damit nie
  // WorkStart > WorkEnd gilt (beim Laden kommen beide nacheinander)
  if FWorkEnd < FWorkStart then
    FWorkEnd := FWorkStart;
  Invalidate;
end;

procedure TPPGCustomPlanner.SetWorkEnd(const Value: Integer);
begin
  FWorkEnd := PPGCheckRange(Self, 'WorkEnd', Value, 0, MinsPerDay);
  if FWorkStart > FWorkEnd then
    FWorkStart := FWorkEnd;
  Invalidate;
end;

procedure TPPGCustomPlanner.SetDayStartHour(const Value: Integer);
begin
  FDayStartHour := PPGCheckRange(Self, 'DayStartHour', Value, 0, 23);
  if FDayEndHour <= FDayStartHour then
    FDayEndHour := FDayStartHour + 1;
  InvalidateLayout;
end;

procedure TPPGCustomPlanner.SetDayEndHour(const Value: Integer);
begin
  FDayEndHour := PPGCheckRange(Self, 'DayEndHour', Value, 1, 24);
  if FDayStartHour >= FDayEndHour then
    FDayStartHour := FDayEndHour - 1;
  InvalidateLayout;
end;

procedure TPPGCustomPlanner.SetSlotMinutes(const Value: Integer);
begin
  case Value of
    5, 10, 15, 20, 30, 60: FSlotMinutes := Value;
  else
    if PPGIsLoading(Self) then
      FSlotMinutes := 30
    else
      raise EPPGPropertyError.CreateInvalid(Self, 'SlotMinutes', IntToStr(Value));
  end;
  InvalidateLayout;
end;

procedure TPPGCustomPlanner.SetSlotHeight(const Value: Integer);
begin
  FSlotHeight := PPGCheckRange(Self, 'SlotHeight', Value, 8, 200);
  InvalidateLayout;
end;

procedure TPPGCustomPlanner.SetSlotWidth(const Value: Integer);
begin
  FSlotWidth := PPGCheckRange(Self, 'SlotWidth', Value, 8, 400);
  InvalidateLayout;
end;

procedure TPPGCustomPlanner.SetTimelineDays(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'TimelineDays', Value, 1, 366);
  if V = FTimelineDays then
    Exit;
  FTimelineDays := V;
  InvalidateLayout;
  if FView = pvTimeline then
    RangeChanged;
end;

procedure TPPGCustomPlanner.SetAgendaDays(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'AgendaDays', Value, 1, 366);
  if V = FAgendaDays then
    Exit;
  FAgendaDays := V;
  InvalidateLayout;
  if FView = pvAgenda then
    RangeChanged;
end;

procedure TPPGCustomPlanner.SetGroupByResource(const Value: Boolean);
begin
  if FGroupByResource <> Value then
  begin
    FGroupByResource := Value;
    InvalidateLayout;
  end;
end;

procedure TPPGCustomPlanner.SetShowNowLine(const Value: Boolean);
begin
  if FShowNowLine <> Value then
  begin
    FShowNowLine := Value;
    UpdateNowLoop;
    Invalidate;
  end;
end;

procedure TPPGCustomPlanner.SetTimeZone(const Value: string);
var
  Z: IPPGTimeZone;
begin
  if Value = '' then
    Z := PPGLocalTimeZone
  else
    Z := PPGFindTimeZone(Value);
  if Z = nil then
  begin
    if PPGIsLoading(Self) then
      Z := PPGLocalTimeZone
    else
      raise EPPGPropertyError.CreateInvalid(Self, 'TimeZone', Value);
  end;
  FTimeZone := Value;
  if not (csLoading in ComponentState) then
    FAppointments.SetDisplayZone(Z);
end;

function TPPGCustomPlanner.GetTimeZoneMode: TPPGTimeZoneMode;
begin
  Result := FAppointments.TimeZoneMode;
end;

procedure TPPGCustomPlanner.SetTimeZoneMode(const Value: TPPGTimeZoneMode);
begin
  FAppointments.TimeZoneMode := Value;
end;

procedure TPPGCustomPlanner.SetCalendar(const Value: TPPGCustomCalendar);
begin
  if FCalendar = Value then
    Exit;
  if FCalendar <> nil then
  begin
    FCalendar.SetLink(nil);
    FCalendar.RemoveFreeNotification(Self);
  end;
  FCalendar := Value;
  if FCalendar <> nil then
  begin
    FCalendar.FreeNotification(Self);
    FCalendar.SetLink(Self);
    SyncCalendar;
  end;
end;

procedure TPPGCustomPlanner.SyncCalendar;
begin
  if (FCalendar = nil) or FUpdatingCalendar or (csLoading in ComponentState) then
    Exit;
  FUpdatingCalendar := True;
  try
    TCalendarAccess(FCalendar).Date := FDate;
  finally
    FUpdatingCalendar := False;
  end;
end;

function TPPGCustomPlanner.GetRangeStart: TDateTime;
begin
  EnsureLayout;
  if Length(FDays) = 0 then
    Result := FDate
  else
    Result := FDays[0];
end;

function TPPGCustomPlanner.GetRangeEnd: TDateTime;
begin
  EnsureLayout;
  if Length(FDays) = 0 then
    Result := FDate + 1
  else
    Result := FDays[High(FDays)] + 1;
end;

function TPPGCustomPlanner.GetSelectedAppointment: TPPGAppointment;
begin
  EnsureLayout;
  if (FSelItem >= 0) and (FSelItem < Length(FItems)) then
    Result := FItems[FSelItem].Appointment
  else
    Result := nil;
end;

function TPPGCustomPlanner.Now_: TDateTime;
begin
  if FNowOverride <> 0 then
    Result := FNowOverride
  else if FAppointments.TimeZoneMode = tzmUtc then
    Result := FAppointments.DisplayZone.ToLocal(TTimeZone.Local.ToUniversalTime(System.SysUtils.Now))
  else
    Result := System.SysUtils.Now;
end;

function TPPGCustomPlanner.EffectiveFirstDay: Integer;
begin
  if FFirstDayOfWeek = fdLocale then
    Result := PPGLocaleFirstDayOfWeek
  else
    Result := Ord(FFirstDayOfWeek);
end;

function TPPGCustomPlanner.GetOccurrences(AFrom, ATo: TDateTime): TArray<TPPGOccurrence>;
begin
  if FSource <> nil then
    Result := FSource.GetOccurrences(AFrom, ATo)
  else
    Result := FAppointments.GetOccurrences(AFrom, ATo);
end;

{ ---- Layout speichern ---- }

function TPPGCustomPlanner.SaveLayout: string;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Add('[PPGPlannerLayout]');
    L.Add('Version=1');
    L.Add('View=' + GetEnumName(TypeInfo(TPPGPlannerView), Ord(FView)));
    L.Add('DayCount=' + IntToStr(FDayCount));
    L.Add('SlotMinutes=' + IntToStr(FSlotMinutes));
    L.Add('SlotHeight=' + IntToStr(FSlotHeight));
    L.Add('SlotWidth=' + IntToStr(FSlotWidth));
    L.Add('TimelineDays=' + IntToStr(FTimelineDays));
    L.Add('AgendaDays=' + IntToStr(FAgendaDays));
    L.Add('GroupByResource=' + IntToStr(Ord(FGroupByResource)));
    Result := L.Text;
  finally
    L.Free;
  end;
end;

procedure TPPGCustomPlanner.LoadLayout(const S: string);
var
  L: TStringList;
  I, P, N: Integer;
  Key, Val: string;
begin
  L := TStringList.Create;
  try
    L.Text := S;
    if (L.Count = 0) or (Trim(L[0]) <> '[PPGPlannerLayout]') then
      Exit; // kein Layout dieses Planers: unveraendert lassen
    for I := 1 to L.Count - 1 do
    begin
      P := Pos('=', L[I]);
      if P = 0 then
        Continue;
      Key := Trim(Copy(L[I], 1, P - 1));
      Val := Trim(Copy(L[I], P + 1, MaxInt));
      try
        if SameText(Key, 'View') then
        begin
          N := GetEnumValue(TypeInfo(TPPGPlannerView), Val);
          if (N >= Ord(Low(TPPGPlannerView))) and (N <= Ord(High(TPPGPlannerView))) then
            View := TPPGPlannerView(N);
        end
        else if TryStrToInt(Val, N) then
        begin
          if SameText(Key, 'DayCount') then
            DayCount := N
          else if SameText(Key, 'SlotMinutes') then
            SlotMinutes := N
          else if SameText(Key, 'SlotHeight') then
            SlotHeight := N
          else if SameText(Key, 'SlotWidth') then
            SlotWidth := N
          else if SameText(Key, 'TimelineDays') then
            TimelineDays := N
          else if SameText(Key, 'AgendaDays') then
            AgendaDays := N
          else if SameText(Key, 'GroupByResource') then
            GroupByResource := N <> 0;
        end;
      except
        on EPPGPropertyError do
          ; // Wert ausserhalb des Bereichs (z. B. alte Datei): Eintrag uebergehen
      end;
    end;
  finally
    L.Free;
  end;
end;

{ ---- Layout ---- }

function TPPGCustomPlanner.S(V: Integer): Integer;
begin
  Result := PPGScale(V, ScalePPI);
end;

function TPPGCustomPlanner.SlotH: Integer;
begin
  Result := Max(6, S(FSlotHeight));
end;

function TPPGCustomPlanner.SlotW: Integer;
begin
  Result := Max(6, S(FSlotWidth));
end;

function TPPGCustomPlanner.SlotCount: Integer;
begin
  Result := (FDayEndHour - FDayStartHour) * 60 div FSlotMinutes;
end;

function TPPGCustomPlanner.IsTimeGrid: Boolean;
begin
  Result := FView in [pvDay, pvWorkWeek, pvWeek];
end;

function TPPGCustomPlanner.WeekStart(D: TDate): TDate;
begin
  Result := Trunc(D) - ((PPGIsoDayOfWeek(D) - EffectiveFirstDay + 7) mod 7);
end;

procedure TPPGCustomPlanner.ComputeDays;
var
  Start: TDate;
  I, N: Integer;
  Y, M, D: Word;
begin
  case FView of
    pvDay:
      begin
        SetLength(FDays, FDayCount);
        for I := 0 to FDayCount - 1 do
          FDays[I] := Trunc(FDate) + I;
      end;
    pvWorkWeek:
      begin
        Start := WeekStart(FDate);
        SetLength(FDays, 7);
        N := 0;
        for I := 0 to 6 do
          if TPPGWeekDay(PPGIsoDayOfWeek(Start + I) - 1) in FWorkDays then
          begin
            FDays[N] := Start + I;
            Inc(N);
          end;
        if N = 0 then
          for I := 0 to 6 do
          begin
            FDays[N] := Start + I;
            Inc(N);
          end;
        SetLength(FDays, N);
      end;
    pvWeek:
      begin
        Start := WeekStart(FDate);
        SetLength(FDays, 7);
        for I := 0 to 6 do
          FDays[I] := Start + I;
      end;
    pvMonth:
      begin
        DecodeDate(FDate, Y, M, D);
        Start := WeekStart(EncodeDate(Y, M, 1));
        SetLength(FDays, 42);
        for I := 0 to 41 do
          FDays[I] := Start + I;
      end;
    pvTimeline:
      begin
        SetLength(FDays, FTimelineDays);
        for I := 0 to FTimelineDays - 1 do
          FDays[I] := Trunc(FDate) + I;
      end;
  else
    SetLength(FDays, FAgendaDays);
    for I := 0 to FAgendaDays - 1 do
      FDays[I] := Trunc(FDate) + I;
  end;
end;

function TPPGCustomPlanner.InBand(const O: TPPGOccurrence): Boolean;
begin
  Result := O.Appointment.AllDay or (O.Finish - O.Start >= 1 - Eps);
end;

function TPPGCustomPlanner.DayIndexFrom(T: TDateTime): Integer;
var
  I: Integer;
begin
  // Erste Spalte, deren Tag T beruehrt oder danach liegt
  for I := 0 to High(FDays) do
    if FDays[I] + 1 > T + Eps then
      Exit(I);
  Result := Length(FDays);
end;

function TPPGCustomPlanner.DayIndexTo(T: TDateTime): Integer;
var
  I: Integer;
begin
  // Letzte Spalte, deren Tag vor T beginnt (T exklusiv)
  for I := High(FDays) downto 0 do
    if FDays[I] < T - Eps then
      Exit(I);
  Result := -1;
end;

function TPPGCustomPlanner.GroupOf(ResourceId: Integer): Integer;
var
  I: Integer;
begin
  if not FGrouped then
    Exit(0);
  for I := 0 to High(FResCols) do
    if FResCols[I] = ResourceId then
      Exit(I);
  Result := -1;
end;

function TPPGCustomPlanner.TimeToY(Day: TDate; T: TDateTime): Integer;
var
  M: Double;
begin
  M := (T - Day) * MinsPerDay - FDayStartHour * 60;
  M := EnsureRange(M, 0, (FDayEndHour - FDayStartHour) * 60);
  Result := Round(M / FSlotMinutes * SlotH);
end;

function TPPGCustomPlanner.TimeToX(T: TDateTime): Integer;
var
  D: Integer;
  M: Double;
  DayW: Integer;
begin
  // Zeitleiste: je Tag die gezeigten Stunden
  DayW := SlotCount * SlotW;
  if Length(FDays) = 0 then
    Exit(0);
  if T <= FDays[0] then
    Exit(0);
  D := Trunc(T + Eps) - Trunc(FDays[0]);
  if D >= Length(FDays) then
    Exit(Length(FDays) * DayW);
  M := (T - FDays[D]) * MinsPerDay - FDayStartHour * 60;
  M := EnsureRange(M, 0, (FDayEndHour - FDayStartHour) * 60);
  Result := D * DayW + Round(M / FSlotMinutes * SlotW);
end;

function TPPGCustomPlanner.XToTime(X: Integer; Round_: Boolean): TDateTime;
var
  DayW, D, Slot: Integer;
begin
  DayW := SlotCount * SlotW;
  if DayW <= 0 then
    Exit(FDate);
  X := EnsureRange(X, 0, Length(FDays) * DayW);
  D := Min(X div DayW, High(FDays));
  if Round_ then
    Slot := Round((X - D * DayW) / SlotW)
  else
    Slot := (X - D * DayW) div SlotW;
  Slot := EnsureRange(Slot, 0, SlotCount);
  Result := FDays[D] + (FDayStartHour * 60 + Slot * FSlotMinutes) * OneMinute;
end;

procedure TPPGCustomPlanner.AddPiece(AItem: Integer; const AR: TRect; AArea: TPPGPlannerArea;
  ABand, ABefore, AAfter: Boolean);
begin
  if FPieceCount >= Length(FPieces) then
    SetLength(FPieces, FPieceCount * 2 + 16);
  FPieces[FPieceCount].Item := AItem;
  FPieces[FPieceCount].R := AR;
  FPieces[FPieceCount].Area := AArea;
  FPieces[FPieceCount].Band := ABand;
  FPieces[FPieceCount].ContBefore := ABefore;
  FPieces[FPieceCount].ContAfter := AAfter;
  Inc(FPieceCount);
end;

procedure TPPGCustomPlanner.EnsureLayout;
var
  I: Integer;
begin
  if FLayoutValid and EqualRect(FV, ViewRect) then
    Exit;
  FLayoutValid := True;
  FV := ViewRect;
  FRtl := UseRightToLeftAlignment;
  FBoldFont.Assign(Font);
  FBoldFont.Style := FBoldFont.Style + [fsBold];
  ComputeDays;
  FGrouped := FGroupByResource and (FResources.Count > 0) and (FView <> pvTimeline);
  if FGrouped then
  begin
    SetLength(FResCols, FResources.Count);
    for I := 0 to FResources.Count - 1 do
      FResCols[I] := FResources[I].Id;
  end
  else
  begin
    SetLength(FResCols, 1);
    FResCols[0] := 0;
  end;
  FItems := GetOccurrences(FDays[0], FDays[High(FDays)] + 1);
  FPieceCount := 0;
  FHeaderH := 0;
  FBandH := 0;
  FBodyH := 0;
  FBodyW := 0;
  FBodyLeft := 0;
  SetLength(FMore, 0);
  SetLength(FAgenda, 0);
  case FView of
    pvMonth: LayoutMonth;
    pvTimeline: LayoutTimeline;
    pvAgenda: LayoutAgenda;
  else
    LayoutTimeGrid;
  end;
  RestoreSelection;
  // Inhaltsgroesse setzen; aendert sich dabei die Ansicht (Leiste), neu
  if FView = pvTimeline then
    SetContentSize(FBodyLeft + FBodyW, FHeaderH + FBodyH)
  else
    SetContentSize(0, FHeaderH + FBodyH);
  if not EqualRect(FV, ViewRect) then
  begin
    FLayoutValid := False;
    EnsureLayout;
    Exit;
  end;
  if not FInitialScroll and HandleAllocated then
  begin
    FInitialScroll := True;
    if IsTimeGrid and (FWorkStart > FDayStartHour * 60) then
      ScrollTo(0, Round((FWorkStart - FDayStartHour * 60) / FSlotMinutes * SlotH));
    if FView = pvTimeline then
      ScrollTo(Round((FWorkStart - FDayStartHour * 60) / FSlotMinutes * SlotW), 0);
  end;
  UpdateNowLoop;
end;

procedure TPPGCustomPlanner.LayoutTimeGrid;
var
  N, G, Cols, C, Gi, D, I, K, Cnt, Rows, BH, MaxBand, X0, X1, Y0, Y1, W, First, Last: Integer;
  Spans: TArray<TPPGSpan>;
  Idx: TArray<Integer>;
  Slots: TArray<TPPGSpanSlot>;
  RowOf: TArray<Integer>;
  O: TPPGOccurrence;
  DayS, DayE, CS, CF: TDateTime;
begin
  N := Length(FDays);
  G := Length(FResCols);
  Cols := N * G;
  W := FV.Right - FV.Left;
  SetLength(FColX, Cols + 1);
  for C := 0 to Cols do
    FColX[C] := S(RulerW) + MulDiv(C, Max(0, W - S(RulerW)), Cols);
  FHeadH := S(HeadH);
  if FGrouped then
    Inc(FHeadH, S(ResHeadH));
  // Band: ganztaegige und mehrtaegige Termine, Zeilen je Gruppe
  BH := S(BandRowH);
  MaxBand := 0;
  SetLength(Spans, Length(FItems));
  SetLength(Idx, Length(FItems));
  for Gi := 0 to G - 1 do
  begin
    Cnt := 0;
    for I := 0 to High(FItems) do
    begin
      O := FItems[I];
      if not InBand(O) or (GroupOf(O.Appointment.ResourceId) <> Gi) then
        Continue;
      First := DayIndexFrom(O.Start);
      Last := DayIndexTo(Max(O.Finish, O.Start + OneMinute));
      if (First > Last) or (First >= N) or (Last < 0) then
        Continue;
      Spans[Cnt] := PPGSpan(First, Last + 1);
      Idx[Cnt] := I;
      Inc(Cnt);
    end;
    RowOf := PPGLayoutRows(Copy(Spans, 0, Cnt), Rows);
    MaxBand := Max(MaxBand, Rows);
    for K := 0 to Cnt - 1 do
    begin
      First := Round(Spans[K].Start);
      Last := Round(Spans[K].Finish) - 1;
      O := FItems[Idx[K]];
      AddPiece(Idx[K], Rect(FColX[Gi * N + First] + 2, FHeadH + 2 + RowOf[K] * BH,
        FColX[Gi * N + Last + 1] - 2, FHeadH + 2 + RowOf[K] * BH + BH - 2), paFixed, True,
        O.Start < FDays[First] - Eps, O.Finish > FDays[Last] + 1 + Eps);
    end;
  end;
  FBandH := BH * Max(1, MaxBand) + 4;
  // Hoechstens 40 % der Hoehe
  if FBandH > (FV.Bottom - FV.Top) * 2 div 5 then
    FBandH := Max(BH + 4, (FV.Bottom - FV.Top) * 2 div 5);
  FHeaderH := FHeadH + FBandH;
  FBodyH := SlotCount * SlotH;
  // Raster: je Spalte die Termine des Tages, Ueberschneidungen in Spalten
  for Gi := 0 to G - 1 do
    for D := 0 to N - 1 do
    begin
      C := Gi * N + D;
      DayS := FDays[D] + FDayStartHour / 24;
      DayE := FDays[D] + FDayEndHour / 24;
      Cnt := 0;
      for I := 0 to High(FItems) do
      begin
        O := FItems[I];
        if InBand(O) or (GroupOf(O.Appointment.ResourceId) <> Gi) then
          Continue;
        if not PPGOverlaps(O.Start, O.Finish, DayS, DayE) then
          Continue;
        CS := Max(O.Start, DayS);
        CF := Min(Max(O.Finish, O.Start), DayE);
        Spans[Cnt] := PPGSpan(CS, CF);
        Idx[Cnt] := I;
        Inc(Cnt);
      end;
      if Cnt = 0 then
        Continue;
      Slots := PPGLayoutColumns(Copy(Spans, 0, Cnt), FSlotMinutes * OneMinute);
      X0 := FColX[C] + 1;
      X1 := FColX[C + 1] - S(ColGap);
      if X1 - X0 < S(12) then
        X1 := FColX[C + 1] - 1;
      for K := 0 to Cnt - 1 do
      begin
        O := FItems[Idx[K]];
        Y0 := TimeToY(FDays[D], Spans[K].Start);
        Y1 := Max(TimeToY(FDays[D], Spans[K].Finish), Y0 + SlotH);
        Y1 := Min(Y1, FBodyH);
        if Y1 - Y0 < S(6) then
          Y0 := Y1 - S(6);
        AddPiece(Idx[K], Rect(X0 + MulDiv(X1 - X0, Slots[K].Column, Slots[K].ColumnCount),
          Y0 + 1, X0 + MulDiv(X1 - X0, Slots[K].Column + Slots[K].ColSpan, Slots[K].ColumnCount) - 2,
          Y1 - 1), paBodyY, False, O.Start < Spans[K].Start - Eps, O.Finish > Spans[K].Finish + Eps);
      end;
    end;
end;

procedure TPPGCustomPlanner.LayoutMonth;
var
  W, H, Rw, Day0, I, K, Cnt, Rows, VisRows, First, Last, D, LineH: Integer;
  Spans: TArray<TPPGSpan>;
  Idx: TArray<Integer>;
  RowOf: TArray<Integer>;
  O: TPPGOccurrence;
  WS, WE: TDateTime;
begin
  W := FV.Right - FV.Left;
  H := FV.Bottom - FV.Top;
  FHeadH := S(MonthHeadH);
  FHeaderH := 0;
  SetLength(FColX, 8);
  for I := 0 to 7 do
    FColX[I] := MulDiv(I, W, 7);
  SetLength(FRowY, 7);
  for I := 0 to 6 do
    FRowY[I] := FHeadH + MulDiv(I, Max(0, H - FHeadH), 6);
  SetLength(FMore, 42);
  LineH := S(MonthLineH);
  SetLength(Spans, Length(FItems));
  SetLength(Idx, Length(FItems));
  FMonthLines := Max(1, ((FRowY[1] - FRowY[0]) - S(MonthDayH)) div LineH);
  for Rw := 0 to 5 do
  begin
    Day0 := Rw * 7;
    WS := FDays[Day0];
    WE := WS + 7;
    Cnt := 0;
    for I := 0 to High(FItems) do
    begin
      O := FItems[I];
      if not PPGOverlaps(O.Start, O.Finish, WS, WE) then
        Continue;
      First := Max(DayIndexFrom(O.Start), Day0);
      Last := Min(DayIndexTo(Max(O.Finish, O.Start + OneMinute)), Day0 + 6);
      if First > Last then
        Continue;
      Spans[Cnt] := PPGSpan(First, Last + 1);
      Idx[Cnt] := I;
      Inc(Cnt);
    end;
    RowOf := PPGLayoutRows(Copy(Spans, 0, Cnt), Rows);
    VisRows := FMonthLines;
    if Rows > FMonthLines then
      VisRows := FMonthLines - 1;
    for K := 0 to Cnt - 1 do
    begin
      First := Round(Spans[K].Start);
      Last := Round(Spans[K].Finish) - 1;
      if RowOf[K] >= VisRows then
      begin
        for D := First to Last do
          Inc(FMore[D]);
        Continue;
      end;
      O := FItems[Idx[K]];
      AddPiece(Idx[K], Rect(FColX[First - Day0] + 3,
        FRowY[Rw] + S(MonthDayH) + RowOf[K] * LineH + 1,
        FColX[Last - Day0 + 1] - 3, FRowY[Rw] + S(MonthDayH) + RowOf[K] * LineH + LineH - 1),
        paFixed, InBand(O) or (Last > First), O.Start < FDays[First] - Eps,
        O.Finish > FDays[Last] + 1 + Eps);
    end;
  end;
end;

procedure TPPGCustomPlanner.LayoutTimeline;
var
  NR, R, I, K, Cnt, Lanes, Top, LaneH, X0, X1, Res: Integer;
  Spans: TArray<TPPGSpan>;
  Idx: TArray<Integer>;
  RowOf: TArray<Integer>;
  O: TPPGOccurrence;
  RS, RE: TDateTime;
begin
  FHeaderH := S(TLHeadH);
  FBodyLeft := S(TLResW);
  FBodyW := Length(FDays) * SlotCount * SlotW;
  NR := Max(1, FResources.Count);
  SetLength(FTLRowTop, NR + 1);
  SetLength(FTLRowH, NR);
  SetLength(Spans, Length(FItems));
  SetLength(Idx, Length(FItems));
  LaneH := S(TLLaneH);
  RS := FDays[0];
  RE := FDays[High(FDays)] + 1;
  Top := 0;
  for R := 0 to NR - 1 do
  begin
    Cnt := 0;
    if FResources.Count > 0 then
      Res := FResources[R].Id
    else
      Res := 0;
    for I := 0 to High(FItems) do
    begin
      O := FItems[I];
      if (FResources.Count > 0) and (O.Appointment.ResourceId <> Res) then
        Continue;
      Spans[Cnt] := PPGSpan(Max(O.Start, RS), Min(Max(O.Finish, O.Start), RE));
      Idx[Cnt] := I;
      Inc(Cnt);
    end;
    RowOf := PPGLayoutRows(Copy(Spans, 0, Cnt), Lanes, FSlotMinutes * OneMinute);
    FTLRowTop[R] := Top;
    FTLRowH[R] := Max(1, Lanes) * LaneH + S(6);
    for K := 0 to Cnt - 1 do
    begin
      O := FItems[Idx[K]];
      X0 := TimeToX(Spans[K].Start);
      X1 := Max(TimeToX(Spans[K].Finish), X0 + S(6));
      AddPiece(Idx[K], Rect(X0 + 1, Top + S(3) + RowOf[K] * LaneH, X1 - 1,
        Top + S(3) + RowOf[K] * LaneH + LaneH - 2), paBodyXY, False,
        O.Start < Spans[K].Start - Eps, O.Finish > Spans[K].Finish + Eps);
    end;
    Inc(Top, FTLRowH[R]);
  end;
  FTLRowTop[NR] := Top;
  FBodyH := Top;
end;

procedure TPPGCustomPlanner.LayoutAgenda;
var
  D, I, N, Top, W: Integer;
  O: TPPGOccurrence;
  Any: Boolean;

  procedure AddRow(ADay: TDate; AItem, AHeight: Integer);
  begin
    if N >= Length(FAgenda) then
      SetLength(FAgenda, N * 2 + 16);
    FAgenda[N].Day := ADay;
    FAgenda[N].Item := AItem;
    FAgenda[N].Top := Top;
    FAgenda[N].Height := AHeight;
    Inc(N);
    Inc(Top, AHeight);
  end;

begin
  FHeaderH := 0;
  W := FV.Right - FV.Left;
  N := 0;
  Top := 0;
  for D := 0 to High(FDays) do
  begin
    Any := False;
    for I := 0 to High(FItems) do
    begin
      O := FItems[I];
      if not PPGOverlaps(O.Start, O.Finish, FDays[D], FDays[D] + 1) then
        Continue;
      if not Any then
      begin
        AddRow(FDays[D], -1, S(AgendaDayH));
        Any := True;
      end;
      AddPiece(I, Rect(S(8), Top + 1, W - S(8), Top + S(AgendaRowH) - 1), paBodyY, False,
        O.Start < FDays[D] - Eps, O.Finish > FDays[D] + 1 + Eps);
      AddRow(FDays[D], I, S(AgendaRowH));
    end;
  end;
  SetLength(FAgenda, N);
  FBodyH := Top;
end;

procedure TPPGCustomPlanner.RestoreSelection;
var
  I: Integer;
begin
  FSelItem := -1;
  if FSelAppt = nil then
    Exit;
  for I := 0 to High(FItems) do
    if (FItems[I].Appointment = FSelAppt) and
      (not FItems[I].Recurring or (Abs(FItems[I].Start - FSelOccStart) < Eps)) then
    begin
      FSelItem := I;
      Exit;
    end;
end;

function TPPGCustomPlanner.Mirror(const R: TRect): TRect;
begin
  if FRtl then
    Result := Rect(FV.Left + FV.Right - R.Right, R.Top, FV.Left + FV.Right - R.Left, R.Bottom)
  else
    Result := R;
end;

function TPPGCustomPlanner.LogicalRect(const R: TRect; Area: TPPGPlannerArea): TRect;
begin
  Result := R;
  case Area of
    paFixed: OffsetRect(Result, FV.Left, FV.Top);
    paBodyY: OffsetRect(Result, FV.Left, FV.Top + FHeaderH - ScrollY);
    paBodyXY: OffsetRect(Result, FV.Left + FBodyLeft - ScrollX, FV.Top + FHeaderH - ScrollY);
  end;
end;

function TPPGCustomPlanner.ItemCount: Integer;
begin
  EnsureLayout;
  Result := Length(FItems);
end;

function TPPGCustomPlanner.Item(Index: Integer): TPPGOccurrence;
begin
  EnsureLayout;
  if (Index < 0) or (Index >= Length(FItems)) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, Length(FItems) - 1]);
  Result := FItems[Index];
end;

function TPPGCustomPlanner.PieceCount: Integer;
begin
  EnsureLayout;
  Result := FPieceCount;
end;

function TPPGCustomPlanner.Piece(Index: Integer): TPPGPlannerPiece;
begin
  EnsureLayout;
  if (Index < 0) or (Index >= FPieceCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, FPieceCount - 1]);
  Result := FPieces[Index];
end;

function TPPGCustomPlanner.PieceRect(Index: Integer): TRect;
begin
  EnsureLayout;
  if (Index < 0) or (Index >= FPieceCount) then
    Exit(Rect(0, 0, 0, 0));
  Result := Mirror(LogicalRect(FPieces[Index].R, FPieces[Index].Area));
end;

function TPPGCustomPlanner.ItemFirstPiece(Item: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to FPieceCount - 1 do
    if FPieces[I].Item = Item then
      Exit(I);
  Result := -1;
end;

function TPPGCustomPlanner.ItemRect(Index: Integer): TRect;
begin
  EnsureLayout;
  Result := PieceRect(ItemFirstPiece(Index));
end;

function TPPGCustomPlanner.DayCountVisible: Integer;
begin
  EnsureLayout;
  Result := Length(FDays);
end;

function TPPGCustomPlanner.VisibleDay(Index: Integer): TDate;
begin
  EnsureLayout;
  if (Index < 0) or (Index >= Length(FDays)) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, Length(FDays) - 1]);
  Result := FDays[Index];
end;

function TPPGCustomPlanner.SlotRect(ATime: TDateTime; AResourceId: Integer): TRect;
var
  D, G, C, Y, R: Integer;
  T: TDateTime;
begin
  EnsureLayout;
  Result := Rect(0, 0, 0, 0);
  T := SnapTime(ATime);
  case FView of
    pvDay, pvWorkWeek, pvWeek:
      begin
        D := DayIndexFrom(T);
        if (D >= Length(FDays)) or (Trunc(T + Eps) <> FDays[D]) then
          Exit;
        G := GroupOf(AResourceId);
        if G < 0 then
          Exit;
        C := G * Length(FDays) + D;
        Y := TimeToY(FDays[D], T);
        Result := Mirror(LogicalRect(Rect(FColX[C], Y, FColX[C + 1], Y + SlotH), paBodyY));
      end;
    pvMonth:
      begin
        D := Trunc(T + Eps) - Trunc(FDays[0]);
        if (D < 0) or (D > 41) then
          Exit;
        Result := Mirror(LogicalRect(Rect(FColX[D mod 7], FRowY[D div 7], FColX[D mod 7 + 1],
          FRowY[D div 7 + 1]), paFixed));
      end;
    pvTimeline:
      begin
        R := Max(0, FResources.IndexOfId(AResourceId));
        if R >= Length(FTLRowH) then
          Exit;
        Y := TimeToX(T);
        Result := Mirror(LogicalRect(Rect(Y, FTLRowTop[R], Y + SlotW, FTLRowTop[R] + FTLRowH[R]),
          paBodyXY));
      end;
  end;
end;

function TPPGCustomPlanner.SnapTime(T: TDateTime): TDateTime;
var
  M: Int64;
begin
  M := Round((T - Trunc(T + Eps)) * MinsPerDay);
  Result := Trunc(T + Eps) + (M div FSlotMinutes) * FSlotMinutes * OneMinute;
end;

function TPPGCustomPlanner.CurrentSlotLength: TDateTime;
begin
  if FView = pvMonth then
    Result := 1
  else
    Result := FSlotMinutes * OneMinute;
end;

function TPPGCustomPlanner.ColumnAt(LX: Integer): Integer;
var
  C: Integer;
begin
  for C := 0 to High(FColX) - 1 do
    if (LX >= FV.Left + FColX[C]) and (LX < FV.Left + FColX[C + 1]) then
      Exit(C);
  Result := -1;
end;

function TPPGCustomPlanner.HitLogical(LX, LY: Integer): TPPGPlannerHit;
var
  I, C, N, D, Y, R: Integer;
  PR: TRect;
  Body: Boolean;
begin
  Result.Kind := phNone;
  Result.Time := 0;
  Result.ResourceId := 0;
  Result.Item := -1;
  if not PtInRect(FV, Point(LX, LY)) then
    Exit;
  // Termine (oben liegende zuerst)
  for I := FPieceCount - 1 downto 0 do
  begin
    PR := LogicalRect(FPieces[I].R, FPieces[I].Area);
    Body := FPieces[I].Area <> paFixed;
    if Body and (LY < FV.Top + FHeaderH) then
      Continue;
    if FPieces[I].Area = paBodyXY then
      if LX < FV.Left + FBodyLeft then
        Continue;
    if PtInRect(PR, Point(LX, LY)) then
    begin
      Result.Kind := phAppointment;
      Result.Item := FPieces[I].Item;
      Result.ResourceId := FItems[Result.Item].Appointment.ResourceId;
      if IsTimeGrid and Body and (PR.Bottom - PR.Top > 3 * S(EdgeH)) then
      begin
        if (LY < PR.Top + S(EdgeH)) and not FPieces[I].ContBefore then
          Result.Kind := phResizeStart
        else if (LY >= PR.Bottom - S(EdgeH)) and not FPieces[I].ContAfter then
          Result.Kind := phResizeEnd;
      end
      else if (FView = pvTimeline) and (PR.Right - PR.Left > 3 * S(EdgeH)) then
      begin
        if (LX < PR.Left + S(EdgeH)) and not FPieces[I].ContBefore then
          Result.Kind := phResizeStart
        else if (LX >= PR.Right - S(EdgeH)) and not FPieces[I].ContAfter then
          Result.Kind := phResizeEnd;
      end;
      Break;
    end;
  end;
  case FView of
    pvDay, pvWorkWeek, pvWeek:
      begin
        C := ColumnAt(LX);
        if C < 0 then
          Exit;
        N := Length(FDays);
        D := C mod N;
        if FGrouped then
          Result.ResourceId := FResCols[C div N]
        else if Result.Item < 0 then
          Result.ResourceId := 0;
        if Result.Item >= 0 then
        begin
          Result.Time := FDays[D];
          if LY >= FV.Top + FHeaderH then
          begin
            Y := LY - (FV.Top + FHeaderH) + ScrollY;
            Result.Time := FDays[D] + (FDayStartHour * 60 + EnsureRange(Y div SlotH, 0,
              SlotCount - 1) * FSlotMinutes) * OneMinute;
          end;
          Exit;
        end;
        if LY < FV.Top + FHeadH then
        begin
          Result.Kind := phHeader;
          Result.Time := FDays[D];
        end
        else if LY < FV.Top + FHeaderH then
        begin
          Result.Kind := phAllDay;
          Result.Time := FDays[D];
        end
        else
        begin
          Y := LY - (FV.Top + FHeaderH) + ScrollY;
          if Y >= FBodyH then
            Exit;
          Result.Kind := phSlot;
          Result.Time := FDays[D] + (FDayStartHour * 60 + (Y div SlotH) * FSlotMinutes) * OneMinute;
        end;
      end;
    pvMonth:
      begin
        if LY < FV.Top + FHeadH then
        begin
          if Result.Item < 0 then
            Result.Kind := phHeader;
          Exit;
        end;
        C := ColumnAt(LX);
        R := -1;
        for I := 0 to 5 do
          if (LY >= FV.Top + FRowY[I]) and (LY < FV.Top + FRowY[I + 1]) then
            R := I;
        if (C < 0) or (R < 0) then
          Exit;
        D := R * 7 + C;
        Result.Time := FDays[D];
        if Result.Item >= 0 then
          Exit;
        Result.Kind := phAllDay;
        if (FMore[D] > 0) and (LY >= FV.Top + FRowY[R + 1] - S(MonthLineH) - 2) then
          Result.Kind := phMore;
      end;
    pvTimeline:
      begin
        if Result.Item >= 0 then
        begin
          if LX >= FV.Left + FBodyLeft then
            Result.Time := XToTime(LX - (FV.Left + FBodyLeft) + ScrollX, False);
          Exit;
        end;
        if LY < FV.Top + FHeaderH then
        begin
          Result.Kind := phHeader;
          if LX >= FV.Left + FBodyLeft then
            Result.Time := XToTime(LX - (FV.Left + FBodyLeft) + ScrollX, False);
          Exit;
        end;
        Y := LY - (FV.Top + FHeaderH) + ScrollY;
        R := -1;
        for I := 0 to High(FTLRowH) do
          if (Y >= FTLRowTop[I]) and (Y < FTLRowTop[I + 1]) then
            R := I;
        if R < 0 then
          Exit;
        if FResources.Count > 0 then
          Result.ResourceId := FResources[R].Id;
        if LX < FV.Left + FBodyLeft then
        begin
          Result.Kind := phHeader;
          Exit;
        end;
        Result.Kind := phSlot;
        Result.Time := XToTime(LX - (FV.Left + FBodyLeft) + ScrollX, False);
      end;
  end;
end;

function TPPGCustomPlanner.HitTest(X, Y: Integer): TPPGPlannerHit;
begin
  EnsureLayout;
  if FRtl then
    X := FV.Left + FV.Right - 1 - X;
  Result := HitLogical(X, Y);
end;

{ ---- Zeichnen ---- }

function GetColors(P: TPPGCustomPlanner): TPlannerColors;
var
  T: TPPGTokens;
  A: TPPGAppearance;
  UseStyles, Dk: Boolean;
  St: TPPGPlannerStyles;
begin
  T := P.Tokens;
  A := P.EffectiveAppearance;
  Result.HC := P.HighContrastSupport and PPGIsHighContrast;
  if Result.HC then
  begin
    Result.Fill := PPGColorToRGB(clWindow);
    Result.Alt := Result.Fill;
    Result.Line := PPGColorToRGB(clWindowText);
    Result.LineSoft := PPGColorToRGB(clGrayText);
    Result.Text := PPGColorToRGB(clWindowText);
    Result.Secondary := Result.Text;
    Result.Accent := PPGColorToRGB(clHighlight);
    Result.OnAccent := PPGColorToRGB(clHighlightText);
    Result.NowCol := Result.Accent;
    Result.Header := Result.Fill;
    Result.HeaderText := Result.Text;
    Result.RulerText := Result.Text;
    Result.TodayText := Result.Accent;
    Result.TodayBar := Result.Accent;
    Result.AppText := Result.Text;
    Result.SelSlot := Result.Accent;
    Exit;
  end;
  Result.Fill := T.Layer;
  Result.Text := T.TextPrimary;
  Result.Secondary := T.TextSecondary;
  if P.UseVclStyle then
  begin
    Result.Fill := PPGColorToRGB(A.Normal.Color);
    Result.Text := PPGColorToRGB(A.Normal.TextColor);
    Result.Secondary := PPGBlendColor(Result.Text, Result.Fill, 0.4);
  end;
  UseStyles := not P.UseVclStyle;
  Dk := P.UseDarkMode;
  St := P.FPlannerStyles;
  if UseStyles then
  begin
    Result.Fill := St.Background.FillFor(Dk, Result.Fill);
    Result.Text := St.Background.TextFor(Dk, Result.Text);
  end;
  Result.Alt := PPGBlendColor(Result.Fill, Result.Text, 0.045);
  Result.Line := PPGBlendColor(Result.Fill, Result.Text, 0.18);
  Result.LineSoft := PPGBlendColor(Result.Fill, Result.Text, 0.08);
  Result.Accent := PPGColorToRGB(A.FocusColor);
  Result.OnAccent := ContrastOn(Result.Accent);
  Result.NowCol := T.Danger;
  Result.Header := Result.Fill;
  Result.HeaderText := Result.Text;
  Result.RulerText := Result.Secondary;
  Result.TodayText := Result.Accent;
  Result.TodayBar := Result.Accent;
  Result.AppText := Result.Text;
  Result.SelSlot := Result.Accent;
  if UseStyles then
  begin
    Result.Line := St.Background.BorderFor(Dk, Result.Line);
    Result.Alt := St.NonWorkHours.FillFor(Dk, Result.Alt);
    Result.Header := St.Header.FillFor(Dk, Result.Header);
    Result.HeaderText := St.Header.TextFor(Dk, Result.HeaderText);
    Result.RulerText := St.TimeRuler.TextFor(Dk, Result.RulerText);
    Result.TodayText := St.Today.TextFor(Dk, Result.TodayText);
    Result.TodayBar := St.Today.BorderFor(Dk, Result.TodayBar);
    Result.NowCol := St.NowLine.FillFor(Dk, Result.NowCol);
    Result.AppText := St.Appointment.TextFor(Dk, Result.AppText);
    Result.SelSlot := St.SelectedSlot.FillFor(Dk, Result.SelSlot);
  end;
  if not P.Enabled then
  begin
    Result.Text := T.TextDisabled;
    Result.Secondary := T.TextDisabled;
    Result.HeaderText := T.TextDisabled;
    Result.RulerText := T.TextDisabled;
    Result.AppText := T.TextDisabled;
  end;
end;

function TPPGCustomPlanner.AppointmentColor(A: TPPGAppointment): TColor;
var
  R: Integer;
begin
  if HighContrastSupport and PPGIsHighContrast then
    Exit(PPGColorToRGB(clHighlight));
  if (A.Category >= 0) and (A.Category < FCategories.Count) and
    (FCategories[A.Category].Color <> clDefault) then
    Result := PPGColorToRGB(FCategories[A.Category].Color)
  else if A.Category >= 0 then
    Result := PPGChartColor(Tokens, UseDarkMode, A.Category)
  else
  begin
    Result := PPGColorToRGB(EffectiveAppearance.FocusColor);
    R := FResources.IndexOfId(A.ResourceId);
    if (R >= 0) and (FResources[R].Color <> clDefault) then
      Result := PPGColorToRGB(FResources[R].Color);
  end;
  if Assigned(FOnGetAppointmentColor) then
    FOnGetAppointmentColor(Self, A, Result);
end;

function TPPGCustomPlanner.DayHeaderText(D: TDate; Width: Integer): string;
var
  Wd: Integer;
begin
  Wd := DayOfWeek(D);
  if (Length(FDays) = 1) and (Width > S(220)) then
    Result := FormatDateTime(FormatSettings.LongDateFormat, D)
  else if Width > S(110) then
    Result := FormatSettings.LongDayNames[Wd] + ' ' + IntToStr(DayOf(D))
  else
    Result := FormatSettings.ShortDayNames[Wd] + ' ' + IntToStr(DayOf(D));
end;

procedure TPPGCustomPlanner.SetCategories(const Value: TPPGPlannerCategories);
begin
  FCategories.Assign(Value);
end;

procedure TPPGCustomPlanner.SetPlannerStyles(const Value: TPPGPlannerStyles);
begin
  FPlannerStyles.Assign(Value);
end;

procedure TPPGCustomPlanner.PlannerStylesChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TPPGCustomPlanner.PaintViewport(const ACanvas: IPPGCanvas; const View: TRect);
var
  Col: TPlannerColors;
begin
  EnsureLayout;
  Col := GetColors(Self);
  ACanvas.FillRoundRect(View, 0, Col.Fill, 255);
  case FView of
    pvMonth: PaintMonth(ACanvas);
    pvTimeline: PaintTimeline(ACanvas);
    pvAgenda: PaintAgenda(ACanvas);
  else
    PaintTimeGrid(ACanvas);
  end;
end;

procedure TPPGCustomPlanner.PaintPieces(const ACanvas: IPPGCanvas; const Clip: TRect;
  Areas: array of TPPGPlannerArea);
var
  Col: TPlannerColors;
  I, K, Bar, Rad, Th: Integer;
  P: TPPGPlannerPiece;
  R, TR: TRect;
  A: TPPGAppointment;
  C, Fill, TextC: TColor;
  Sel, Match, Short, Hot: Boolean;
  Txt: string;
  Batch: TTextBatch;
  Flags: Cardinal;
  Pts: array[0..2] of TPoint;
  DS: TPPGDrawStyle;
  St: TPPGItemDrawState;
  DrawIt: Boolean;
  DC: HDC;
  AF: TFont;
begin
  Col := GetColors(Self);
  Batch := TTextBatch.Create;
  try
    ACanvas.PushClipRoundRect(Clip, 0);
    try
      for I := 0 to FPieceCount - 1 do
      begin
        P := FPieces[I];
        Match := False;
        for K := 0 to High(Areas) do
          if P.Area = Areas[K] then
            Match := True;
        if not Match then
          Continue;
        R := Mirror(LogicalRect(P.R, P.Area));
        if not IntersectRect(TR, R, Clip) then
          Continue;
        A := FItems[P.Item].Appointment;
        C := AppointmentColor(A);
        Sel := P.Item = FSelItem;
        Hot := (P.Item = FHot.Item) and (FDrag = pdNone);
        // Eigenes Zeichnen: Fill = Terminfarbe, TextColor, fett; DefaultDraw = False
        DS.Reset;
        DrawIt := True;
        if Assigned(FOnCustomDrawAppointment) then
        begin
          St := [];
          if Sel then
            Include(St, idsSelected);
          if Hot then
            Include(St, idsHot);
          if Sel and Focused then
            Include(St, idsFocused);
          DC := ACanvas.BeginGdi;
          try
            FDrawCanvas.Handle := DC;
            try
              FDrawCanvas.Font := Font;
              FDrawCanvas.Brush.Style := bsClear;
              FOnCustomDrawAppointment(Self, FDrawCanvas, A, R, St, DS, DrawIt);
            finally
              FDrawCanvas.Handle := 0;
            end;
          finally
            ACanvas.EndGdi(DC);
          end;
        end;
        if not DrawIt then
          Continue;
        if (DS.Fill <> clNone) and not Col.HC then
          C := PPGColorToRGB(DS.Fill);
        Rad := S(4);
        Short := (FView = pvMonth) and not P.Band;
        if Col.HC then
        begin
          if Sel then
            Fill := Col.Accent
          else
            Fill := Col.Fill;
        end
        else if Short then
        begin
          if Sel then
            Fill := C
          else if Hot then
            Fill := PPGBlendColor(Col.Fill, C, 0.12)
          else
            Fill := Col.Fill;
        end
        else if Sel then
          Fill := C
        else if Hot then
          Fill := PPGBlendColor(Col.Fill, C, 0.28)
        else
          Fill := PPGBlendColor(Col.Fill, C, 0.18);
        if Sel then
          TextC := ContrastOn(Fill)
        else
          TextC := Col.AppText;
        if (DS.TextColor <> clNone) and not Col.HC then
          TextC := PPGColorToRGB(DS.TextColor);
        if Col.HC and Sel then
          TextC := Col.OnAccent;
        if FView = pvAgenda then
        begin
          // Liste: Zeile mit Farbstreifen
          if Sel then
            ACanvas.FillRoundRect(R, Rad, Col.Accent, 40)
          else if Hot then
            ACanvas.FillRoundRect(R, Rad, Col.Text, 12);
          Bar := S(4);
          TR := Mirror(Rect(R.Left + S(AgendaTimeW), R.Top + S(4), R.Left + S(AgendaTimeW) + Bar,
            R.Bottom - S(4)));
          if FRtl then
            TR := Rect(R.Right - S(AgendaTimeW) - Bar, R.Top + S(4), R.Right - S(AgendaTimeW), R.Bottom - S(4));
          ACanvas.FillRoundRect(TR, Bar div 2, C, 255);
          if A.AllDay then
            Txt := PPGStr(@SPPGPlannerAllDay)
          else
            Txt := TimeText(FItems[P.Item].Start) + ' - ' + TimeText(FItems[P.Item].Finish);
          if FRtl then
            TR := Rect(R.Right - S(AgendaTimeW) + S(4), R.Top, R.Right - S(8), R.Bottom)
          else
            TR := Rect(R.Left + S(8), R.Top, R.Left + S(AgendaTimeW) - S(4), R.Bottom);
          Batch.Add(TR, Txt, Col.Secondary, False,
            DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS));
          Txt := A.Subject;
          if Txt = '' then
            Txt := PPGStr(@SPPGPlannerNoSubject);
          if A.Location <> '' then
            Txt := Txt + '  ' + #$2013 + '  ' + A.Location;
          if FRtl then
            TR := Rect(R.Left + S(8), R.Top, R.Right - S(AgendaTimeW) - S(12), R.Bottom)
          else
            TR := Rect(R.Left + S(AgendaTimeW) + S(12), R.Top, R.Right - S(8), R.Bottom);
          Batch.Add(TR, Txt, Col.Text, False,
            DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS));
          if Sel and Focused and FocusVisible then
            ACanvas.FrameRoundRect(R, Rad, S(2), Col.Accent, 255);
          Continue;
        end;
        // Monat, Termin mit Uhrzeit: ohne Flaeche (nur Punkt), ausser gewaehlt/Hover
        if not Short or Sel or Hot or Col.HC then
          ACanvas.FillRoundRect(R, Rad, Fill, 255);
        if Col.HC then
          ACanvas.FrameRoundRect(R, Rad, 1, Col.Line, 255)
        else if not Short then
        begin
          // Farbstreifen am Anfang
          Bar := Min(S(4), (R.Right - R.Left) div 3);
          if FRtl then
            TR := Rect(R.Right - Bar, R.Top, R.Right, R.Bottom)
          else
            TR := Rect(R.Left, R.Top, R.Left + Bar, R.Bottom);
          if not P.ContBefore then
            ACanvas.FillRoundRect(TR, Min(Rad, Bar), C, 255);
        end
        else
        begin
          // Monat, Termin mit Uhrzeit: Punkt
          Th := S(8);
          TR := Rect(R.Left + S(4), (R.Top + R.Bottom - Th) div 2, R.Left + S(4) + Th,
            (R.Top + R.Bottom + Th) div 2);
          if FRtl then
            TR := Rect(R.Right - S(4) - Th, TR.Top, R.Right - S(4), TR.Bottom);
          if Sel then
            ACanvas.FillEllipse(TR, TextC, 255)
          else
            ACanvas.FillEllipse(TR, C, 255);
        end;
        if Sel and Focused and FocusVisible then
          ACanvas.FrameRoundRect(Rect(R.Left - 1, R.Top - 1, R.Right + 1, R.Bottom + 1), Rad + 1,
            S(2), Col.Text, 255);
        // Fortsetzungsmarken (Dreiecke)
        Th := S(4);
        if P.ContBefore or P.ContAfter then
        begin
          if IsTimeGrid and not P.Band then
          begin
            if P.ContBefore then
            begin
              Pts[0] := Point((R.Left + R.Right) div 2 - Th, R.Top + Th + 1);
              Pts[1] := Point((R.Left + R.Right) div 2, R.Top + 1);
              Pts[2] := Point((R.Left + R.Right) div 2 + Th, R.Top + Th + 1);
              ACanvas.DrawPolyline(Pts, Max(1, S(1)), TextC, 200);
            end;
            if P.ContAfter then
            begin
              Pts[0] := Point((R.Left + R.Right) div 2 - Th, R.Bottom - Th - 2);
              Pts[1] := Point((R.Left + R.Right) div 2, R.Bottom - 2);
              Pts[2] := Point((R.Left + R.Right) div 2 + Th, R.Bottom - Th - 2);
              ACanvas.DrawPolyline(Pts, Max(1, S(1)), TextC, 200);
            end;
          end
          else
          begin
            if P.ContBefore <> FRtl then
            begin
              Pts[0] := Point(R.Left + Th + 2, (R.Top + R.Bottom) div 2 - Th);
              Pts[1] := Point(R.Left + 2, (R.Top + R.Bottom) div 2);
              Pts[2] := Point(R.Left + Th + 2, (R.Top + R.Bottom) div 2 + Th);
              if P.ContBefore or P.ContAfter then
                ACanvas.DrawPolyline(Pts, Max(1, S(1)), TextC, 200);
            end;
            if (P.ContAfter and not FRtl) or (P.ContBefore and FRtl) then
            begin
              Pts[0] := Point(R.Right - Th - 2, (R.Top + R.Bottom) div 2 - Th);
              Pts[1] := Point(R.Right - 2, (R.Top + R.Bottom) div 2);
              Pts[2] := Point(R.Right - Th - 2, (R.Top + R.Bottom) div 2 + Th);
              ACanvas.DrawPolyline(Pts, Max(1, S(1)), TextC, 200);
            end;
          end;
        end;
        // Text
        TR := R;
        InflateRect(TR, -S(4), -S(2));
        if not Short and not P.ContBefore and not Col.HC then
          if FRtl then
            Dec(TR.Right, S(4))
          else
            Inc(TR.Left, S(4));
        if Short then
          if FRtl then
            Dec(TR.Right, S(12))
          else
            Inc(TR.Left, S(12));
        // Waagerechte Fortsetzungsmarken freihalten
        if not (IsTimeGrid and not P.Band) then
        begin
          if P.ContBefore <> FRtl then
            Inc(TR.Left, S(8));
          if (P.ContAfter and not FRtl) or (P.ContBefore and FRtl) then
            Dec(TR.Right, S(8));
        end;
        // Teilweise herausgescrollt: Text bleibt am sichtbaren Rand
        if TR.Left < Clip.Left + S(4) then
          TR.Left := Min(Clip.Left + S(4), TR.Right);
        if TR.Right > Clip.Right - S(4) then
          TR.Right := Max(Clip.Right - S(4), TR.Left);
        if (P.Area <> paFixed) and (TR.Top < Clip.Top + S(2)) then
          TR.Top := Min(Clip.Top + S(2), TR.Bottom);
        Txt := A.Subject;
        if Txt = '' then
          Txt := PPGStr(@SPPGPlannerNoSubject);
        if Short and not A.AllDay then
          Txt := TimeText(FItems[P.Item].Start) + ' ' + Txt;
        if IsTimeGrid and not P.Band and (R.Bottom - R.Top >= 2 * S(MonthLineH)) then
        begin
          if A.Location <> '' then
            Txt := Txt + #13#10 + A.Location;
          // Ganze Woerter umbrechen; zu lange Woerter enden mit "..."
          Flags := DT_WORDBREAK or DT_WORD_ELLIPSIS or DT_END_ELLIPSIS;
        end
        else
        begin
          if (A.Location <> '') and not Short then
            Txt := Txt + ' ' + #$2013 + ' ' + A.Location;
          Flags := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
        end;
        Batch.Add(TR, Txt, TextC, fsBold in DS.FontStyle, DrawTextBiDiModeFlags(Flags));
      end;
    finally
      ACanvas.PopClip;
    end;
    AF := FFonts.ForStyle(FPlannerStyles.Appointment, Font);
    Batch.Flush(ACanvas, Clip, AF, FFonts.Get(AF, [fsBold]));
    FFonts.Clear;
  finally
    Batch.Free;
  end;
end;

function TPPGCustomPlanner.GhostRects: TArray<TRect>;
var
  N, G, D, First, Last, Y0, Y1, C, R, X0, X1, Cnt: Integer;
  DayS, DayE, CS, CF: TDateTime;
begin
  SetLength(Result, 0);
  if not (FDrag in [pdMove, pdResizeStart, pdResizeEnd]) then
    Exit;
  N := Length(FDays);
  case FView of
    pvDay, pvWorkWeek, pvWeek:
      begin
        G := GroupOf(FGhostRes);
        if G < 0 then
          G := 0;
        if FDragBand then
        begin
          First := DayIndexFrom(FGhostStart);
          Last := DayIndexTo(Max(FGhostFinish, FGhostStart + OneMinute));
          if (First > Last) or (First >= N) or (Last < 0) then
            Exit;
          SetLength(Result, 1);
          Result[0] := Mirror(LogicalRect(Rect(FColX[G * N + First] + 2, FHeadH + 2,
            FColX[G * N + Last + 1] - 2, FHeadH + S(BandRowH)), paFixed));
          Exit;
        end;
        SetLength(Result, N);
        Cnt := 0;
        for D := 0 to N - 1 do
        begin
          DayS := FDays[D] + FDayStartHour / 24;
          DayE := FDays[D] + FDayEndHour / 24;
          if not PPGOverlaps(FGhostStart, FGhostFinish, DayS, DayE) then
            Continue;
          CS := Max(FGhostStart, DayS);
          CF := Min(FGhostFinish, DayE);
          C := G * N + D;
          Y0 := TimeToY(FDays[D], CS);
          Y1 := Max(TimeToY(FDays[D], CF), Y0 + S(6));
          Result[Cnt] := Mirror(LogicalRect(Rect(FColX[C] + 1, Y0 + 1, FColX[C + 1] - S(ColGap),
            Y1 - 1), paBodyY));
          Inc(Cnt);
        end;
        SetLength(Result, Cnt);
      end;
    pvMonth:
      begin
        First := Max(0, DayIndexFrom(FGhostStart));
        Last := Min(41, DayIndexTo(Max(FGhostFinish, FGhostStart + OneMinute)));
        SetLength(Result, 6);
        Cnt := 0;
        for R := 0 to 5 do
        begin
          X0 := Max(First, R * 7);
          X1 := Min(Last, R * 7 + 6);
          if X0 > X1 then
            Continue;
          Result[Cnt] := Mirror(LogicalRect(Rect(FColX[X0 - R * 7] + 3, FRowY[R] + S(MonthDayH),
            FColX[X1 - R * 7 + 1] - 3, FRowY[R] + S(MonthDayH) + S(MonthLineH)), paFixed));
          Inc(Cnt);
        end;
        SetLength(Result, Cnt);
      end;
    pvTimeline:
      begin
        R := Max(0, FResources.IndexOfId(FGhostRes));
        if R >= Length(FTLRowH) then
          Exit;
        X0 := TimeToX(FGhostStart);
        X1 := Max(TimeToX(FGhostFinish), X0 + S(6));
        SetLength(Result, 1);
        Result[0] := Mirror(LogicalRect(Rect(X0, FTLRowTop[R] + S(3), X1,
          FTLRowTop[R] + S(3) + S(TLLaneH) - 2), paBodyXY));
      end;
  end;
end;

procedure TPPGCustomPlanner.PaintGhost(const ACanvas: IPPGCanvas);
var
  Rs: TArray<TRect>;
  I: Integer;
  Col: TPlannerColors;
  C: TColor;
begin
  Rs := GhostRects;
  if Length(Rs) = 0 then
    Exit;
  Col := GetColors(Self);
  C := AppointmentColor(FDragOcc.Appointment);
  for I := 0 to High(Rs) do
  begin
    ACanvas.FillRoundRect(Rs[I], S(4), C, 90);
    ACanvas.FrameRoundRect(Rs[I], S(4), S(2), C, 255);
  end;
end;

procedure TPPGCustomPlanner.PaintTimeGrid(const ACanvas: IPPGCanvas);
var
  Col: TPlannerColors;
  N, G, C, D, I, Y, YT, X0, X1, Slots, M, Gi, H, Wd: Integer;
  Body, Ruler, R, Head: TRect;
  Batch: TTextBatch;
  NowT: TDateTime;
  Work, IsToday: Boolean;
  S_: string;
  RF, HF: TFont;
begin
  Col := GetColors(Self);
  N := Length(FDays);
  G := Length(FResCols);
  Slots := SlotCount;
  Body := Rect(FV.Left, FV.Top + FHeaderH, FV.Right, FV.Bottom);
  Ruler := Mirror(Rect(FV.Left, Body.Top, FV.Left + S(RulerW), FV.Bottom));
  Batch := TTextBatch.Create;
  try
    // ---- Raster ----
    ACanvas.PushClipRoundRect(Body, 0);
    try
      Y := FV.Top + FHeaderH - ScrollY;
      for C := 0 to N * G - 1 do
      begin
        D := C mod N;
        Wd := PPGIsoDayOfWeek(FDays[D]);
        Work := TPPGWeekDay(Wd - 1) in FWorkDays;
        X0 := FV.Left + FColX[C];
        X1 := FV.Left + FColX[C + 1];
        if not Work then
          ACanvas.FillRoundRect(Mirror(Rect(X0, Y, X1, Y + FBodyH)), 0, Col.Alt, 255)
        else
        begin
          if FWorkStart > FDayStartHour * 60 then
            ACanvas.FillRoundRect(Mirror(Rect(X0, Y, X1, Y + TimeToY(0, FWorkStart * OneMinute))), 0,
              Col.Alt, 255);
          if FWorkEnd < FDayEndHour * 60 then
            ACanvas.FillRoundRect(Mirror(Rect(X0, Y + TimeToY(0, FWorkEnd * OneMinute), X1,
              Y + FBodyH)), 0, Col.Alt, 255);
        end;
      end;
      // Gewaehlte Zeitfelder
      if (FSelItem < 0) and (FSelTo > FSelFrom) and not FSelAllDay then
      begin
        Gi := GroupOf(FSelRes);
        if Gi >= 0 then
          for D := 0 to N - 1 do
            if PPGOverlaps(FSelFrom, FSelTo, FDays[D], FDays[D] + 1) then
            begin
              C := Gi * N + D;
              R := Rect(FV.Left + FColX[C], Y + TimeToY(FDays[D], Max(FSelFrom, FDays[D])),
                FV.Left + FColX[C + 1], Y + TimeToY(FDays[D], Min(FSelTo, FDays[D] + 1)));
              ACanvas.FillRoundRect(Mirror(R), 0, Col.SelSlot, 60);
            end;
      end;
      // Linien: volle Stunde kraeftig, Zwischenfelder schwach
      for I := 0 to Slots do
      begin
        YT := Y + I * SlotH;
        if (YT < Body.Top - 1) or (YT > Body.Bottom) then
          Continue;
        M := FDayStartHour * 60 + I * FSlotMinutes;
        if M mod 60 = 0 then
          ACanvas.FillRoundRect(Mirror(Rect(FV.Left + S(RulerW) - S(6), YT, FV.Right, YT + 1)), 0,
            Col.Line, 255)
        else
          ACanvas.FillRoundRect(Mirror(Rect(FV.Left + S(RulerW), YT, FV.Right, YT + 1)), 0,
            Col.LineSoft, 255);
        if (M mod 60 = 0) and (I < Slots) then
          Batch.Add(Mirror(Rect(FV.Left, YT + 2, FV.Left + S(RulerW) - S(8), YT + 2 + Font.Height * -2)),
            TimeText(M * OneMinute), Col.RulerText, False,
            DT_SINGLELINE or DT_TOP or IfThen(FRtl, DT_LEFT, DT_RIGHT));
      end;
      for C := 0 to N * G do
      begin
        if (C mod N = 0) and (C > 0) and (C < N * G) then
          H := 2
        else
          H := 1;
        ACanvas.FillRoundRect(Mirror(Rect(FV.Left + FColX[C], Body.Top, FV.Left + FColX[C] + H,
          Body.Bottom)), 0, Col.Line, 255);
      end;
    finally
      ACanvas.PopClip;
    end;
    RF := FFonts.ForStyle(FPlannerStyles.TimeRuler, Font);
    Batch.Flush(ACanvas, Ruler, RF, RF);
    PaintPieces(ACanvas, Rect(Body.Left + S(RulerW), Body.Top, Body.Right, Body.Bottom), [paBodyY]);
    // Jetzt-Linie
    NowT := Now_;
    if FShowNowLine then
      for D := 0 to N - 1 do
        if (Trunc(NowT) = FDays[D]) and (NowT >= FDays[D] + FDayStartHour / 24) and
          (NowT < FDays[D] + FDayEndHour / 24) then
        begin
          ACanvas.PushClipRoundRect(Body, 0);
          try
            YT := Y + TimeToY(FDays[D], NowT);
            for Gi := 0 to G - 1 do
            begin
              C := Gi * N + D;
              ACanvas.FillRoundRect(Mirror(Rect(FV.Left + FColX[C], YT - S(1), FV.Left + FColX[C + 1],
                YT + S(1))), 0, Col.NowCol, 255);
              R := Mirror(Rect(FV.Left + FColX[C] - S(4), YT - S(4), FV.Left + FColX[C] + S(4), YT + S(4)));
              ACanvas.FillEllipse(R, Col.NowCol, 255);
            end;
          finally
            ACanvas.PopClip;
          end;
        end;
    ACanvas.PushClipRoundRect(Body, 0);
    try
      if not FDragBand then
        PaintGhost(ACanvas);
    finally
      ACanvas.PopClip;
    end;

    // ---- Kopf ----
    Head := Rect(FV.Left, FV.Top, FV.Right, FV.Top + FHeaderH);
    ACanvas.FillRoundRect(Head, 0, Col.Header, 255);
    for C := 0 to N * G - 1 do
    begin
      D := C mod N;
      Gi := C div N;
      IsToday := FDays[D] = Trunc(Now_);
      X0 := FV.Left + FColX[C];
      X1 := FV.Left + FColX[C + 1];
      if FGrouped and (D = 0) then
      begin
        R := Rect(X0, FV.Top, FV.Left + FColX[C + N], FV.Top + S(ResHeadH));
        S_ := FResources[Gi].Caption;
        Batch.Add(Mirror(Rect(R.Left + S(6), R.Top, R.Right - S(6), R.Bottom)), S_, Col.HeaderText, True,
          DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_END_ELLIPSIS));
        ACanvas.FillRoundRect(Mirror(Rect(R.Left, R.Bottom - 1, R.Right, R.Bottom)), 0, Col.Line, 255);
      end;
      if FGrouped then
        R := Rect(X0, FV.Top + S(ResHeadH), X1, FV.Top + FHeadH)
      else
        R := Rect(X0, FV.Top, X1, FV.Top + FHeadH);
      if IsToday then
      begin
        ACanvas.FillRoundRect(Mirror(Rect(R.Left + 1, R.Bottom - S(3), R.Right - 1, R.Bottom)), 0,
          Col.TodayBar, 255);
        Batch.Add(Mirror(Rect(R.Left + S(6), R.Top, R.Right - S(4), R.Bottom)),
          DayHeaderText(FDays[D], R.Right - R.Left), Col.TodayText, True,
          DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS));
      end
      else
        Batch.Add(Mirror(Rect(R.Left + S(6), R.Top, R.Right - S(4), R.Bottom)),
          DayHeaderText(FDays[D], R.Right - R.Left), Col.HeaderText, False,
          DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS));
      ACanvas.FillRoundRect(Mirror(Rect(X0, FV.Top + FHeadH, X0 + 1, FV.Top + FHeaderH)), 0,
        Col.Line, 255);
    end;
    // Band
    if FSelAllDay and (FSelItem < 0) and (FSelTo > FSelFrom) then
    begin
      Gi := GroupOf(FSelRes);
      if Gi >= 0 then
        for D := 0 to N - 1 do
          if PPGOverlaps(FSelFrom, FSelTo, FDays[D], FDays[D] + 1) then
            ACanvas.FillRoundRect(Mirror(Rect(FV.Left + FColX[Gi * N + D], FV.Top + FHeadH,
              FV.Left + FColX[Gi * N + D + 1], FV.Top + FHeaderH)), 0, Col.Accent, 60);
    end;
    Batch.Add(Mirror(Rect(FV.Left + S(4), FV.Top + FHeadH, FV.Left + S(RulerW) - S(4),
      FV.Top + FHeadH + S(BandRowH))), PPGStr(@SPPGPlannerAllDay), Col.Secondary, False,
      DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or IfThen(FRtl, DT_LEFT, DT_RIGHT));
    ACanvas.FillRoundRect(Rect(FV.Left, FV.Top + FHeadH - 1, FV.Right, FV.Top + FHeadH), 0,
      Col.Line, 255);
    ACanvas.FillRoundRect(Rect(FV.Left, FV.Top + FHeaderH - 1, FV.Right, FV.Top + FHeaderH), 0,
      Col.Line, 255);
    HF := FFonts.ForStyle(FPlannerStyles.Header, Font);
    Batch.Flush(ACanvas, Head, HF, FFonts.Get(HF, [fsBold]));
    PaintPieces(ACanvas, Rect(FV.Left, FV.Top + FHeadH, FV.Right, FV.Top + FHeaderH - 1), [paFixed]);
    if FDragBand then
      PaintGhost(ACanvas);
  finally
    Batch.Free;
  end;
end;

procedure TPPGCustomPlanner.PaintMonth(const ACanvas: IPPGCanvas);
var
  Col: TPlannerColors;
  I, D, Rw, Cc, Wd, FirstDay: Integer;
  R, CellR: TRect;
  Batch: TTextBatch;
  Dt: TDate;
  Y, M, Dd: Word;
  IsToday, Other, Work: Boolean;
  S_: string;
begin
  Col := GetColors(Self);
  Batch := TTextBatch.Create;
  try
    DecodeDate(FDate, Y, M, Dd);
    FirstDay := EffectiveFirstDay;
    // Wochentage
    for I := 0 to 6 do
    begin
      Wd := (FirstDay - 1 + I) mod 7 + 1;
      R := Mirror(Rect(FV.Left + FColX[I] + S(6), FV.Top, FV.Left + FColX[I + 1] - S(4), FV.Top + FHeadH));
      if FColX[1] - FColX[0] > S(110) then
        S_ := FormatSettings.LongDayNames[Wd mod 7 + 1]
      else
        S_ := FormatSettings.ShortDayNames[Wd mod 7 + 1];
      Batch.Add(R, S_, Col.Secondary, False,
        DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS));
    end;
    for D := 0 to 41 do
    begin
      Rw := D div 7;
      Cc := D mod 7;
      Dt := FDays[D];
      CellR := Mirror(Rect(FV.Left + FColX[Cc], FV.Top + FRowY[Rw], FV.Left + FColX[Cc + 1],
        FV.Top + FRowY[Rw + 1]));
      Other := MonthOf(Dt) <> M;
      Work := TPPGWeekDay(PPGIsoDayOfWeek(Dt) - 1) in FWorkDays;
      if Other or not Work then
        ACanvas.FillRoundRect(CellR, 0, Col.Alt, 255);
      if FSelAllDay and (FSelItem < 0) and (Dt >= Trunc(FSelFrom)) and (Dt < FSelTo - Eps) then
        ACanvas.FillRoundRect(CellR, 0, Col.Accent, 50);
      IsToday := Dt = Trunc(Now_);
      R := Rect(CellR.Left + S(6), CellR.Top + S(2), CellR.Right - S(6), CellR.Top + S(MonthDayH));
      if Dd = 0 then
        S_ := ''
      else if (DayOf(Dt) = 1) then
        S_ := IntToStr(DayOf(Dt)) + '. ' + FormatSettings.ShortMonthNames[MonthOf(Dt)]
      else
        S_ := IntToStr(DayOf(Dt));
      if IsToday then
      begin
        ACanvas.FillRoundRect(Rect(R.Left - S(4), R.Top, R.Left + ACanvas.MeasureText(S_, FBoldFont, 0, False).cx + S(4),
          R.Bottom), S(4), Col.TodayBar, 255);
        Batch.Add(R, S_, ContrastOn(Col.TodayBar), True, DT_SINGLELINE or DT_VCENTER or DT_LEFT);
      end
      else if Other then
        Batch.Add(R, S_, Col.Secondary, False,
          DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER))
      else
        Batch.Add(R, S_, Col.Text, False, DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER));
      if FMore[D] > 0 then
      begin
        R := Rect(CellR.Left + S(6), CellR.Bottom - S(MonthLineH) - 2, CellR.Right - S(6),
          CellR.Bottom - 2);
        Batch.Add(R, Format(PPGStr(@SPPGPlannerMore), [FMore[D]]), Col.Accent, True,
          DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS));
      end;
    end;
    // Linien
    for I := 0 to 6 do
      ACanvas.FillRoundRect(Rect(FV.Left, FV.Top + FRowY[I], FV.Right, FV.Top + FRowY[I] + 1), 0,
        Col.Line, 255);
    for I := 1 to 6 do
      ACanvas.FillRoundRect(Mirror(Rect(FV.Left + FColX[I], FV.Top + FHeadH, FV.Left + FColX[I] + 1,
        FV.Bottom)), 0, Col.Line, 255);
    Batch.Flush(ACanvas, FV, Font, FBoldFont);
    PaintPieces(ACanvas, Rect(FV.Left, FV.Top + FHeadH, FV.Right, FV.Bottom), [paFixed]);
    PaintGhost(ACanvas);
  finally
    Batch.Free;
  end;
end;

procedure TPPGCustomPlanner.PaintTimeline(const ACanvas: IPPGCanvas);
var
  Col: TPlannerColors;
  I, D, K, X, Y0, DayW, Slots, M, NR, Wd: Integer;
  Body, Res, Head, R: TRect;
  Batch: TTextBatch;
  NowT: TDateTime;
  S_: string;
begin
  Col := GetColors(Self);
  Slots := SlotCount;
  DayW := Slots * SlotW;
  NR := Length(FTLRowH);
  Body := Rect(FV.Left + FBodyLeft, FV.Top + FHeaderH, FV.Right, FV.Bottom);
  Res := Rect(FV.Left, FV.Top + FHeaderH, FV.Left + FBodyLeft, FV.Bottom);
  Head := Rect(FV.Left + FBodyLeft, FV.Top, FV.Right, FV.Top + FHeaderH);
  X := FV.Left + FBodyLeft - ScrollX;
  Y0 := FV.Top + FHeaderH - ScrollY;
  Batch := TTextBatch.Create;
  try
    ACanvas.PushClipRoundRect(Mirror(Body), 0);
    try
      for D := 0 to High(FDays) do
      begin
        Wd := PPGIsoDayOfWeek(FDays[D]);
        if not (TPPGWeekDay(Wd - 1) in FWorkDays) then
          ACanvas.FillRoundRect(Mirror(Rect(X + D * DayW, Body.Top, X + (D + 1) * DayW, Body.Bottom)), 0,
            Col.Alt, 255);
        for K := 0 to Slots - 1 do
        begin
          M := FDayStartHour * 60 + K * FSlotMinutes;
          if (M < FWorkStart) or (M >= FWorkEnd) then
            ACanvas.FillRoundRect(Mirror(Rect(X + D * DayW + K * SlotW, Body.Top,
              X + D * DayW + (K + 1) * SlotW, Body.Bottom)), 0, Col.Alt, 255);
          ACanvas.FillRoundRect(Mirror(Rect(X + D * DayW + K * SlotW, Body.Top,
            X + D * DayW + K * SlotW + 1, Body.Bottom)), 0, Col.LineSoft, 255);
        end;
        ACanvas.FillRoundRect(Mirror(Rect(X + D * DayW, FV.Top, X + D * DayW + 1, Body.Bottom)), 0,
          Col.Line, 255);
      end;
      for I := 0 to NR do
        ACanvas.FillRoundRect(Mirror(Rect(Body.Left, Y0 + FTLRowTop[I], Body.Right, Y0 + FTLRowTop[I] + 1)),
          0, Col.Line, 255);
      if (FSelItem < 0) and (FSelTo > FSelFrom) then
      begin
        K := Max(0, FResources.IndexOfId(FSelRes));
        if K < NR then
          ACanvas.FillRoundRect(Mirror(Rect(X + TimeToX(FSelFrom), Y0 + FTLRowTop[K], X + TimeToX(FSelTo),
            Y0 + FTLRowTop[K + 1])), 0, Col.Accent, 60);
      end;
    finally
      ACanvas.PopClip;
    end;
    PaintPieces(ACanvas, Mirror(Body), [paBodyXY]);
    NowT := Now_;
    if FShowNowLine and (NowT >= RangeStart) and (NowT < RangeEnd) then
    begin
      ACanvas.PushClipRoundRect(Mirror(Body), 0);
      try
        K := X + TimeToX(NowT);
        ACanvas.FillRoundRect(Mirror(Rect(K - S(1), Body.Top, K + S(1), Body.Bottom)), 0, Col.NowCol, 255);
      finally
        ACanvas.PopClip;
      end;
    end;
    ACanvas.PushClipRoundRect(Mirror(Body), 0);
    try
      PaintGhost(ACanvas);
    finally
      ACanvas.PopClip;
    end;
    // Kopf: Tage und Uhrzeiten
    ACanvas.FillRoundRect(Mirror(Head), 0, Col.Header, 255);
    for D := 0 to High(FDays) do
    begin
      R := Rect(X + D * DayW + S(6), FV.Top, X + (D + 1) * DayW - S(4), FV.Top + FHeaderH div 2);
      // Tagesname bleibt sichtbar, solange der Tag es ist
      if R.Left < Head.Left + S(6) then
        R.Left := Min(Head.Left + S(6), R.Right);
      if FDays[D] = Trunc(NowT) then
        Batch.Add(Mirror(R), DayHeaderText(FDays[D], DayW), Col.TodayText, True,
          DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS))
      else
        Batch.Add(Mirror(R), DayHeaderText(FDays[D], DayW), Col.HeaderText, True,
          DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS));
      for K := 0 to Slots - 1 do
      begin
        M := FDayStartHour * 60 + K * FSlotMinutes;
        if (M mod 60 <> 0) and (SlotW < S(36)) then
          Continue;
        R := Rect(X + D * DayW + K * SlotW + S(3), FV.Top + FHeaderH div 2,
          X + D * DayW + (K + 1) * SlotW + IfThen(M mod 60 = 0, SlotW, 0), FV.Top + FHeaderH);
        Batch.Add(Mirror(R), TimeText(M * OneMinute), Col.Secondary, False,
          DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER));
      end;
    end;
    ACanvas.FillRoundRect(Mirror(Rect(Head.Left, Head.Bottom - 1, Head.Right, Head.Bottom)), 0, Col.Line, 255);
    Batch.Flush(ACanvas, Mirror(Head), FFonts.ForStyle(FPlannerStyles.Header, Font),
      FFonts.Get(FFonts.ForStyle(FPlannerStyles.Header, Font), [fsBold]));
    // Ressourcen links
    ACanvas.FillRoundRect(Mirror(Rect(FV.Left, FV.Top, FV.Left + FBodyLeft, FV.Bottom)), 0, Col.Header, 255);
    for I := 0 to NR - 1 do
    begin
      if FResources.Count > 0 then
        S_ := FResources[I].Caption
      else
        S_ := '';
      R := Rect(FV.Left + S(8), Y0 + FTLRowTop[I], FV.Left + FBodyLeft - S(6), Y0 + FTLRowTop[I + 1]);
      Batch.Add(Mirror(R), S_, Col.HeaderText, False,
        DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS));
      ACanvas.FillRoundRect(Mirror(Rect(FV.Left, Y0 + FTLRowTop[I + 1], FV.Left + FBodyLeft,
        Y0 + FTLRowTop[I + 1] + 1)), 0, Col.Line, 255);
    end;
    ACanvas.FillRoundRect(Mirror(Rect(FV.Left + FBodyLeft - 1, FV.Top, FV.Left + FBodyLeft, FV.Bottom)), 0,
      Col.Line, 255);
    Batch.Flush(ACanvas, Mirror(Res), FFonts.ForStyle(FPlannerStyles.Header, Font),
      FFonts.Get(FFonts.ForStyle(FPlannerStyles.Header, Font), [fsBold]));
    FFonts.Clear;
  finally
    Batch.Free;
  end;
end;

procedure TPPGCustomPlanner.PaintAgenda(const ACanvas: IPPGCanvas);
var
  Col: TPlannerColors;
  I, Y0: Integer;
  R: TRect;
  Batch: TTextBatch;
  S_: string;
begin
  Col := GetColors(Self);
  Y0 := FV.Top - ScrollY;
  Batch := TTextBatch.Create;
  try
    if Length(FAgenda) = 0 then
      Batch.Add(FV, PPGStr(@SPPGPlannerNone), Col.Secondary, False,
        DT_SINGLELINE or DT_VCENTER or DT_CENTER)
    else
      for I := 0 to High(FAgenda) do
        if FAgenda[I].Item < 0 then
        begin
          R := Rect(FV.Left + S(8), Y0 + FAgenda[I].Top, FV.Right - S(8), Y0 + FAgenda[I].Top + FAgenda[I].Height);
          if (R.Bottom < FV.Top) or (R.Top > FV.Bottom) then
            Continue;
          S_ := FormatDateTime(FormatSettings.LongDateFormat, FAgenda[I].Day);
          if FAgenda[I].Day = Trunc(Now_) then
            Batch.Add(Mirror(R), S_, Col.Accent, True,
              DrawTextBiDiModeFlags(DT_SINGLELINE or DT_BOTTOM or DT_END_ELLIPSIS))
          else
            Batch.Add(Mirror(R), S_, Col.Text, True,
              DrawTextBiDiModeFlags(DT_SINGLELINE or DT_BOTTOM or DT_END_ELLIPSIS));
          ACanvas.FillRoundRect(Rect(R.Left, R.Bottom - 1, R.Right, R.Bottom), 0, Col.Line, 255);
        end;
    Batch.Flush(ACanvas, FV, Font, FBoldFont);
  finally
    Batch.Free;
  end;
  PaintPieces(ACanvas, FV, [paBodyY]);
end;

{ ---- Auswahl ---- }

procedure TPPGCustomPlanner.SelectItemIndex(Item: Integer; Notify: Boolean);
var
  R: TRect;
  P: Integer;
begin
  if (Item < -1) or (Item >= Length(FItems)) then
    Item := -1;
  if Item = FSelItem then
    Exit;
  FSelItem := Item;
  if Item >= 0 then
  begin
    FSelAppt := FItems[Item].Appointment;
    FSelOccStart := FItems[Item].Start;
    FSelFrom := FItems[Item].Start;
    FSelTo := FItems[Item].Finish;
    FSelRes := FItems[Item].Appointment.ResourceId;
    FSelAllDay := InBand(FItems[Item]);
    // In die Ansicht holen (nur gescrollte Stuecke)
    P := ItemFirstPiece(Item);
    if (P >= 0) and (FPieces[P].Area <> paFixed) then
    begin
      R := FPieces[P].R;
      if FPieces[P].Area = paBodyY then
        MakeVisible(Rect(0, FHeaderH + R.Top, 0, FHeaderH + R.Bottom))
      else
        MakeVisible(Rect(FBodyLeft + R.Left, FHeaderH + R.Top, FBodyLeft + R.Right, FHeaderH + R.Bottom));
    end;
  end
  else
    FSelAppt := nil;
  Invalidate;
  if Item >= 0 then
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, Item + 1);
  if Notify then
    SelectionChanged;
end;

procedure TPPGCustomPlanner.SelectAppointment(A: TPPGAppointment);
var
  I: Integer;
begin
  EnsureLayout;
  if A = nil then
  begin
    SelectItemIndex(-1, False);
    Exit;
  end;
  for I := 0 to High(FItems) do
    if FItems[I].Appointment = A then
    begin
      SelectItemIndex(I, False);
      Exit;
    end;
  // Ausserhalb des Zeitraums: dorthin
  FDate := Trunc(A.Start);
  FSelAppt := A;
  FSelOccStart := A.Start;
  InvalidateLayout;
  EnsureLayout;
  RangeChanged;
  for I := 0 to High(FItems) do
    if FItems[I].Appointment = A then
    begin
      FSelItem := -1;
      SelectItemIndex(I, False);
      Exit;
    end;
end;

procedure TPPGCustomPlanner.SetSlotSelection(AFrom, ATo: TDateTime; ARes: Integer; AAllDay: Boolean);
var
  Y: Integer;
begin
  FSelItem := -1;
  FSelAppt := nil;
  FSelFrom := AFrom;
  FSelTo := ATo;
  FSelRes := ARes;
  FSelAllDay := AAllDay;
  if IsTimeGrid and not AAllDay and (Length(FDays) > 0) then
  begin
    Y := TimeToY(Trunc(AFrom + Eps), AFrom);
    MakeVisible(Rect(0, FHeaderH + Y, 0, FHeaderH + Y + SlotH));
  end
  else if FView = pvTimeline then
  begin
    Y := TimeToX(AFrom);
    MakeVisible(Rect(FBodyLeft + Y, 0, FBodyLeft + Y + SlotW, 0));
  end;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
end;

procedure TPPGCustomPlanner.SelectSlots(AFrom, ATo: TDateTime; AResourceId: Integer);
begin
  EnsureLayout;
  FSelAnchor := Min(AFrom, ATo);
  if ATo < AFrom then
    SetSlotSelection(ATo, AFrom, AResourceId, False)
  else
    SetSlotSelection(AFrom, ATo, AResourceId, False);
end;

procedure TPPGCustomPlanner.SelectionChanged;
begin
  if Assigned(FOnSelectionChange) then
    FOnSelectionChange(Self);
end;

procedure TPPGCustomPlanner.RangeChanged;
begin
  if Assigned(FOnRangeChange) then
    FOnRangeChange(Self);
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

procedure TPPGCustomPlanner.AppointmentsChanged;
begin
  if FDrag in [pdMove, pdResizeStart, pdResizeEnd, pdPending] then
  begin
    FDrag := pdNone;
    StopAutoScroll;
  end;
  InvalidateLayout;
end;

procedure TPPGCustomPlanner.AppointmentRemoving(A: TPPGAppointment);
begin
  // Kommt vor der Freigabe von A (Delete, Free, Clear, DB-Reload). Danach
  // darf kein Feld mehr auf A zeigen.
  if csDestroying in ComponentState then
    Exit;
  if A = FEditAppt then
  begin
    FEditAppt := nil;
    FEditNew := False;
    if FEditor <> nil then
      FEditor.Visible := False;
  end;
  if A = FSelAppt then
  begin
    FSelAppt := nil;
    FSelItem := -1;
  end;
  if (FDrag in [pdMove, pdResizeStart, pdResizeEnd, pdPending]) and (FDragOcc.Appointment = A) then
  begin
    FDrag := pdNone;
    StopAutoScroll;
    MouseCapture := False;
  end;
  // Die Vorkommen in FItems zeigen ebenfalls auf A
  FLayoutValid := False;
end;

{ ---- Navigation ---- }

procedure TPPGCustomPlanner.UserSetDate(D: TDate);
begin
  EndEditSubject(True);
  SetDate(D);
end;

procedure TPPGCustomPlanner.NextPage;
begin
  case FView of
    pvDay: UserSetDate(FDate + FDayCount);
    pvWorkWeek, pvWeek: UserSetDate(FDate + 7);
    pvMonth: UserSetDate(IncMonth(FDate, 1));
    pvTimeline: UserSetDate(FDate + FTimelineDays);
  else
    UserSetDate(FDate + FAgendaDays);
  end;
end;

procedure TPPGCustomPlanner.PrevPage;
begin
  case FView of
    pvDay: UserSetDate(FDate - FDayCount);
    pvWorkWeek, pvWeek: UserSetDate(FDate - 7);
    pvMonth: UserSetDate(IncMonth(FDate, -1));
    pvTimeline: UserSetDate(FDate - FTimelineDays);
  else
    UserSetDate(FDate - FAgendaDays);
  end;
end;

procedure TPPGCustomPlanner.GoToToday;
begin
  UserSetDate(Trunc(Now_));
end;

{ ---- Aendern ---- }

function TPPGCustomPlanner.DoCreateAppointment(AStart, AFinish: TDateTime; AResourceId: Integer;
  AAllDay: Boolean): TPPGAppointment;
begin
  FAppointments.BeginUpdate;
  try
    Result := FAppointments.Add;
    Result.AllDay := AAllDay;
    Result.Start := AStart;
    Result.Finish := AFinish;
    Result.ResourceId := AResourceId;
  finally
    FAppointments.EndUpdate;
  end;
end;

procedure TPPGCustomPlanner.DoDeleteAppointment(A: TPPGAppointment);
begin
  A.Free;
end;

procedure TPPGCustomPlanner.AppointmentWritten(A: TPPGAppointment);
begin
  // DB-Planer schreibt hier in die Datenmenge
end;

function TPPGCustomPlanner.ChangeAppointment(const Occ: TPPGOccurrence;
  Kind: TPPGAppointmentChangeKind; NewStart, NewFinish: TDateTime; NewResourceId: Integer): Boolean;
var
  A, Series: TPPGAppointment;
  Allow: Boolean;
  Choice: TPPGSeriesChoice;
begin
  Result := False;
  A := Occ.Appointment;
  if (A = nil) or FReadOnly or (A.ReadOnly and (Kind <> ackCopy)) then
    Exit;
  if NewFinish < NewStart then
    NewFinish := NewStart;
  if (Kind <> ackCopy) and (Abs(NewStart - Occ.Start) < Eps) and (Abs(NewFinish - Occ.Finish) < Eps) and
    (NewResourceId = A.ResourceId) then
    Exit;
  Allow := True;
  if Assigned(FOnAppointmentChanging) then
    FOnAppointmentChanging(Self, A, Kind, NewStart, NewFinish, NewResourceId, Allow);
  if not Allow then
    Exit;
  Choice := scOccurrence;
  if (Kind <> ackCopy) and Occ.Recurring then
  begin
    if Kind = ackResize then
      Choice := SeriesChoice(Occ, saResize)
    else
      Choice := SeriesChoice(Occ, saMove);
    if Choice = scCancel then
      Exit;
  end;
  if Kind = ackCopy then
  begin
    Series := A;
    A := DoCreateAppointment(NewStart, NewFinish, NewResourceId, Series.AllDay);
    A.Collection.BeginUpdate;
    try
      A.Subject := Series.Subject;
      A.Location := Series.Location;
      A.Body := Series.Body;
      A.Category := Series.Category;
      A.Tag := Series.Tag;
    finally
      A.Collection.EndUpdate;
    end;
  end
  else if Choice = scSeries then
  begin
    // Ganze Serie: Beginn um dieselbe Spanne, Dauer wie das Vorkommen
    A.ShiftSeries(NewStart - Occ.Start, NewFinish - NewStart);
    if NewResourceId <> A.ResourceId then
      A.ResourceId := NewResourceId;
  end
  else
  begin
    if Occ.Recurring and (A.Collection is TPPGAppointments) then
    begin
      // Vorkommen einer Serie: herausloesen, die Serie bekommt eine Ausnahme
      Series := A;
      A := TPPGAppointments(A.Collection).DetachOccurrence(Occ);
      AppointmentWritten(Series);
    end;
    A.Collection.BeginUpdate;
    try
      A.Start := NewStart;
      A.Finish := NewFinish;
      A.ResourceId := NewResourceId;
    finally
      A.Collection.EndUpdate;
    end;
  end;
  AppointmentWritten(A);
  FSelAppt := A;
  FSelOccStart := NewStart;
  InvalidateLayout;
  EnsureLayout;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
  if Kind = ackCopy then
  begin
    if Assigned(FOnAppointmentCreated) then
      FOnAppointmentCreated(Self, A);
  end
  else if Assigned(FOnAppointmentChanged) then
    FOnAppointmentChanged(Self, A);
  SelectionChanged;
  Result := True;
end;

function TPPGCustomPlanner.CreateAppointment(AStart, AFinish: TDateTime; AResourceId: Integer;
  AAllDay: Boolean; InitialChar: Char): TPPGAppointment;
var
  Allow: Boolean;
begin
  Result := nil;
  if FReadOnly then
    Exit;
  Allow := True;
  if Assigned(FOnCreateAppointment) then
    FOnCreateAppointment(Self, AStart, AFinish, AResourceId, AAllDay, Allow);
  if not Allow then
    Exit;
  Result := DoCreateAppointment(AStart, AFinish, AResourceId, AAllDay);
  AppointmentWritten(Result);
  FSelAppt := Result;
  FSelOccStart := Result.Start;
  InvalidateLayout;
  EnsureLayout;
  if Assigned(FOnAppointmentCreated) then
    FOnAppointmentCreated(Self, Result);
  SelectionChanged;
  if HandleAllocated and (FSelItem >= 0) then
  begin
    BeginEditSubject(InitialChar);
    FEditNew := True;
  end;
end;

function TPPGCustomPlanner.DeleteSelected: Boolean;
var
  A: TPPGAppointment;
  Occ: TPPGOccurrence;
  Allow: Boolean;
  ResId, I: Integer;
  Choice: TPPGSeriesChoice;
begin
  Result := False;
  EnsureLayout;
  if FReadOnly or (FSelItem < 0) then
    Exit;
  Occ := FItems[FSelItem];
  A := Occ.Appointment;
  if A.ReadOnly then
    Exit;
  Allow := True;
  if Assigned(FOnDeleting) then
    FOnDeleting(Self, A, Allow);
  // OnDeleting kann den Termin selbst entfernt haben
  if not Allow or (FSelAppt <> A) then
    Exit;
  Choice := SeriesChoice(Occ, saDelete);
  if Choice = scCancel then
    Exit;
  // Vor dem Loeschen sichern: DoDeleteAppointment gibt A frei
  ResId := A.ResourceId;
  FSelItem := -1;
  FSelAppt := nil;
  if Occ.Recurring and (Choice = scOccurrence) then
  begin
    // Nur dieses Vorkommen
    A.AddException(Occ.Start);
    AppointmentWritten(A);
  end
  else
  begin
    // Ganze Serie: auch die herausgeloesten Einzeltermine
    if Occ.Recurring and (A.Collection = FAppointments) then
      for I := FAppointments.Count - 1 downto 0 do
        if (FAppointments[I] <> A) and (A.Id <> 0) and (FAppointments[I].RecurrenceParent = A.Id) then
          DoDeleteAppointment(FAppointments[I]);
    DoDeleteAppointment(A);
  end;
  SetSlotSelection(Occ.Start, Occ.Start + CurrentSlotLength, ResId, False);
  InvalidateLayout;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
  SelectionChanged;
  Result := True;
end;

function TPPGCustomPlanner.MoveSelected(DMinutes, DDays: Integer; Resize: Boolean): Boolean;
var
  Occ: TPPGOccurrence;
  NS, NF, Delta: TDateTime;
begin
  Result := False;
  EnsureLayout;
  if FSelItem < 0 then
    Exit;
  Occ := FItems[FSelItem];
  Delta := DMinutes * OneMinute + DDays;
  if Resize then
  begin
    NS := Occ.Start;
    NF := Occ.Finish + Delta;
    if NF < NS + CurrentSlotLength - Eps then
      Exit;
    Result := ChangeAppointment(Occ, ackResize, NS, NF, Occ.Appointment.ResourceId);
  end
  else
  begin
    NS := Occ.Start + Delta;
    NF := Occ.Finish + Delta;
    Result := ChangeAppointment(Occ, ackMove, NS, NF, Occ.Appointment.ResourceId);
  end;
end;

{ ---- Serien ---- }

function TPPGCustomPlanner.SeriesChoice(const Occ: TPPGOccurrence;
  Action: TPPGSeriesAction): TPPGSeriesChoice;
begin
  Result := scOccurrence;
  if not Occ.Recurring then
    Exit;
  case FSeriesEditMode of
    semOccurrence:
      Exit;
    semSeries:
      Exit(scSeries);
  end;
  if Assigned(FOnSeriesEdit) then
  begin
    FOnSeriesEdit(Self, Occ, Action, Result);
    Exit;
  end;
  // Ohne sichtbares Fenster nicht fragen (Laeufe ohne Bediener): wie bisher
  if (csDesigning in ComponentState) or not HandleAllocated or not IsWindowVisible(Handle) then
    Exit;
  Result := DoAskSeries(Occ, Action);
end;

function TPPGCustomPlanner.DoAskSeries(const Occ: TPPGOccurrence;
  Action: TPPGSeriesAction): TPPGSeriesChoice;
var
  D: TPPGTaskDialog;
  B: TTaskDialogBaseButtonItem;
  Subject: string;
begin
  Result := scCancel;
  Subject := '';
  if Occ.Appointment <> nil then
    Subject := Occ.Appointment.Subject;
  D := TPPGTaskDialog.Create(nil);
  try
    D.Caption := PPGStr(@SPPGPlannerSeriesTitle);
    if Action = saDelete then
      D.Title := Format(PPGStr(@SPPGPlannerSeriesDelete), [Subject])
    else
      D.Title := Format(PPGStr(@SPPGPlannerSeriesChange), [Subject]);
    D.Text := PPGStr(@SPPGPlannerSeriesText);
    D.MainIcon := tdiInformation;
    D.Flags := [tfUseCommandLinks, tfAllowDialogCancellation, tfPositionRelativeToWindow];
    D.CommonButtons := [tcbCancel];
    B := D.Buttons.Add;
    B.Caption := PPGStr(@SPPGPlannerSeriesOne);
    TTaskDialogButtonItem(B).CommandLinkHint := PPGStr(@SPPGPlannerSeriesOneHint);
    B.ModalResult := 100;
    B.Default := True;
    B := D.Buttons.Add;
    B.Caption := PPGStr(@SPPGPlannerSeriesAll);
    TTaskDialogButtonItem(B).CommandLinkHint := PPGStr(@SPPGPlannerSeriesAllHint);
    B.ModalResult := 101;
    if D.Execute(Handle) then
      case D.ModalResult of
        100: Result := scOccurrence;
        101: Result := scSeries;
      end;
  finally
    D.Free;
  end;
end;

procedure TPPGCustomPlanner.OpenItem(Item: Integer);
begin
  if (Item < 0) or (Item > High(FItems)) then
    Exit;
  if Assigned(FOnAppointmentOpen) then
    FOnAppointmentOpen(Self, FItems[Item].Appointment)
  else if FDefaultEditor and not FReadOnly then
    EditAppointment(Item)
  else
    BeginEditSubject;
end;

function TPPGCustomPlanner.EditAppointment(Item: Integer): Boolean;
var
  Occ: TPPGOccurrence;
  A, Series, Copy_: TPPGAppointment;
  Choice: TPPGSeriesChoice;
  Allow: Boolean;
  NS, NF: TDateTime;
  NR: Integer;
begin
  Result := False;
  EnsureLayout;
  if Item < 0 then
    Item := FSelItem;
  if FReadOnly or (Item < 0) or (Item > High(FItems)) then
    Exit;
  Occ := FItems[Item];
  A := Occ.Appointment;
  if (A = nil) or A.ReadOnly then
    Exit;
  Choice := SeriesChoice(Occ, saEdit);
  if Choice = scCancel then
    Exit;
  Allow := True;
  NS := A.Start;
  NF := A.Finish;
  NR := A.ResourceId;
  if Assigned(FOnAppointmentChanging) then
    FOnAppointmentChanging(Self, A, ackDialog, NS, NF, NR, Allow);
  if not Allow then
    Exit;
  if Occ.Recurring and (Choice = scOccurrence) and (A.Collection is TPPGAppointments) then
  begin
    // Nur dieses Vorkommen: eine Kopie bearbeiten, erst nach OK herausloesen
    Copy_ := TPPGAppointment.Create(nil);
    try
      Copy_.Assign(A);
      Copy_.Recurrence := '';
      Copy_.ExDates := '';
      Copy_.Start := Occ.Start;
      Copy_.Finish := Occ.Finish;
      if not PPGEditAppointmentDialog(Self, Copy_, False) then
        Exit;
      Series := A;
      A := TPPGAppointments(Series.Collection).DetachOccurrence(Occ);
      A.Collection.BeginUpdate;
      try
        A.AllDay := Copy_.AllDay;
        A.Start := Copy_.Start;
        A.Finish := Copy_.Finish;
        A.Subject := Copy_.Subject;
        A.Location := Copy_.Location;
        A.Body := Copy_.Body;
        A.Category := Copy_.Category;
        A.ResourceId := Copy_.ResourceId;
      finally
        A.Collection.EndUpdate;
      end;
      AppointmentWritten(Series);
    finally
      Copy_.Free;
    end;
  end
  else if not PPGEditAppointmentDialog(Self, A, True) then
    Exit;
  AppointmentWritten(A);
  FSelAppt := A;
  FSelOccStart := A.Start;
  InvalidateLayout;
  EnsureLayout;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
  if Assigned(FOnAppointmentChanged) then
    FOnAppointmentChanged(Self, A);
  SelectionChanged;
  Result := True;
end;

{ ---- Betreff bearbeiten ---- }

function TPPGCustomPlanner.Editing: Boolean;
begin
  Result := (FEditor <> nil) and FEditor.Visible;
end;

procedure TPPGCustomPlanner.BeginEditSubject(InitialChar: Char);
begin
  BeginEditField(False, InitialChar);
end;

procedure TPPGCustomPlanner.BeginEditLocation;
begin
  BeginEditField(True, #0);
end;

procedure TPPGCustomPlanner.BeginEditField(Location: Boolean; InitialChar: Char);
var
  R: TRect;
  H: Integer;
begin
  EnsureLayout;
  if (csDesigning in ComponentState) or not HandleAllocated or FReadOnly or (FSelItem < 0) then
    Exit;
  if FItems[FSelItem].Appointment.ReadOnly then
    Exit;
  R := ItemRect(FSelItem);
  if IsRectEmpty(R) then
    Exit;
  if FEditor = nil then
  begin
    FEditor := TPPGPlannerEdit.Create(Self);
    FEditor.Parent := Self;
    FEditor.OnKeyDown := EditorKeyDown;
    FEditor.OnExit := EditorExit;
    FEditor.AutoSize := False;
  end;
  FEditAppt := FItems[FSelItem].Appointment;
  FEditOcc := FItems[FSelItem];
  FEditNew := False;
  FEditLocation := Location;
  FEditor.Font := Font;
  H := Max(-Font.Height * 2, S(28));
  if R.Bottom - R.Top > H then
    R.Bottom := R.Top + H
  else if R.Bottom - R.Top < H then
    R.Bottom := R.Top + H;
  R.Right := Max(R.Right, R.Left + S(120));
  FEditor.BoundsRect := R;
  if InitialChar <> #0 then
  begin
    FEditor.Text := InitialChar;
    FEditor.SelStart := 1;
  end
  else if Location then
  begin
    FEditor.Text := FEditAppt.Location;
    FEditor.SelectAll;
  end
  else
  begin
    FEditor.Text := FEditAppt.Subject;
    FEditor.SelectAll;
  end;
  FEditor.Visible := True;
  if FEditor.CanFocus and IsWindowVisible(FEditor.Handle) then
    FEditor.SetFocus;
end;

procedure TPPGCustomPlanner.EndEditSubject(Accept: Boolean);
var
  A, Series: TPPGAppointment;
  S_: string;
  Allow, HadFocus, WasNew, IsLoc: Boolean;
  NS, NF: TDateTime;
  NR: Integer;
  Occ: TPPGOccurrence;
  Kind: TPPGAppointmentChangeKind;
  Choice: TPPGSeriesChoice;
begin
  if not Editing or (FEditAppt = nil) then
    Exit;
  A := FEditAppt;
  WasNew := FEditNew;
  IsLoc := FEditLocation;
  Occ := FEditOcc;
  FEditAppt := nil;
  FEditNew := False;
  FEditLocation := False;
  S_ := FEditor.Text;
  HadFocus := FEditor.Focused;
  FEditor.Visible := False;
  if HadFocus and CanFocus and HandleAllocated and IsWindowVisible(Handle) then
    SetFocus;
  if not Accept then
  begin
    // Neuer Termin ohne Betreff: wieder weg (wie Outlook)
    if WasNew and (A.Subject = '') then
    begin
      FSelItem := -1;
      FSelAppt := nil;
      DoDeleteAppointment(A);
      InvalidateLayout;
    end;
    Exit;
  end;
  if (IsLoc and (S_ = A.Location)) or (not IsLoc and (S_ = A.Subject)) then
    Exit;
  Allow := True;
  NS := A.Start;
  NF := A.Finish;
  NR := A.ResourceId;
  if IsLoc then
    Kind := ackLocation
  else
    Kind := ackSubject;
  if Assigned(FOnAppointmentChanging) then
    FOnAppointmentChanging(Self, A, Kind, NS, NF, NR, Allow);
  if not Allow then
    Exit;
  if Occ.Recurring and not WasNew then
  begin
    if IsLoc then
      Choice := SeriesChoice(Occ, saLocation)
    else
      Choice := SeriesChoice(Occ, saSubject);
    if Choice = scCancel then
      Exit;
    if (Choice = scOccurrence) and (A.Collection is TPPGAppointments) then
    begin
      Series := A;
      A := TPPGAppointments(A.Collection).DetachOccurrence(Occ);
      AppointmentWritten(Series);
      FSelAppt := A;
      FSelOccStart := A.Start;
    end;
  end;
  if IsLoc then
    A.Location := S_
  else
    A.Subject := S_;
  AppointmentWritten(A);
  InvalidateLayout;
  if Assigned(FOnAppointmentChanged) then
    FOnAppointmentChanged(Self, A);
  Invalidate;
end;

procedure TPPGCustomPlanner.EditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      begin
        EndEditSubject(True);
        Key := 0;
      end;
    VK_ESCAPE:
      begin
        EndEditSubject(False);
        Key := 0;
      end;
  end;
end;

procedure TPPGCustomPlanner.EditorExit(Sender: TObject);
begin
  if FEditAppt <> nil then
    EndEditSubject(True);
end;

{ ---- Maus ---- }

procedure TPPGCustomPlanner.StartDrag(const Hit: TPPGPlannerHit; Shift: TShiftState);
begin
  FDragHit := Hit;
  case Hit.Kind of
    phAppointment, phResizeStart, phResizeEnd:
      begin
        FDragItem := Hit.Item;
        FDragOcc := FItems[Hit.Item];
        FDragBand := (FView = pvMonth) or (IsTimeGrid and InBand(FDragOcc));
        FGhostStart := FDragOcc.Start;
        FGhostFinish := FDragOcc.Finish;
        FGhostRes := FDragOcc.Appointment.ResourceId;
        FDrag := pdPending;
      end;
    phSlot, phAllDay:
      begin
        FDrag := pdSelect;
        FSelAnchor := Hit.Time;
        if ssShift in Shift then
          FSelAnchor := FSelFrom;
        SetSlotSelection(Min(FSelAnchor, Hit.Time), Max(FSelAnchor, Hit.Time) + CurrentSlotLength * Ord(Hit.Kind = phSlot) +
          Ord(Hit.Kind = phAllDay), Hit.ResourceId, Hit.Kind = phAllDay);
        SelectionChanged;
      end;
  else
    FDrag := pdNone;
  end;
end;

procedure TPPGCustomPlanner.UpdateDrag(X, Y: Integer; Shift: TShiftState);
var
  Hit: TPPGPlannerHit;
  Delta, Dur, T, Base, Len: TDateTime;
  LX: Integer;
begin
  LX := X;
  if FRtl then
    LX := FV.Left + FV.Right - 1 - X;
  // Fuer das Ziehen zaehlt nur die Flaeche (keine Termine darunter)
  Hit := HitLogical(EnsureRange(LX, FV.Left, FV.Right - 1), EnsureRange(Y, FV.Top, FV.Bottom - 1));
  case FDrag of
    pdSelect:
      begin
        if Hit.Kind in [phNone, phHeader] then
          Exit;
        if FSelAllDay then
          Len := 1
        else
          Len := CurrentSlotLength;
        if (Hit.Kind = phSlot) and FSelAllDay then
          Exit;
        T := Hit.Time;
        if (Hit.Kind = phAppointment) and not FSelAllDay and IsTimeGrid then
          T := SnapTime(T);
        if T < FSelAnchor then
          SetSlotSelection(T, FSelAnchor + Len, FSelRes, FSelAllDay)
        else
          SetSlotSelection(FSelAnchor, T + Len, FSelRes, FSelAllDay);
      end;
    pdPending, pdMove, pdResizeStart, pdResizeEnd:
      begin
        if FDrag = pdPending then
        begin
          if (Abs(X - FDragDown.X) < GetSystemMetrics(SM_CXDRAG)) and
            (Abs(Y - FDragDown.Y) < GetSystemMetrics(SM_CYDRAG)) then
            Exit;
          if FReadOnly or (FDragOcc.Appointment.ReadOnly and not (ssCtrl in Shift)) then
          begin
            FDrag := pdNone;
            Exit;
          end;
          case FDragHit.Kind of
            phResizeStart: FDrag := pdResizeStart;
            phResizeEnd: FDrag := pdResizeEnd;
          else
            FDrag := pdMove;
          end;
        end;
        if Hit.Time = 0 then
          Exit;
        Dur := FDragOcc.Finish - FDragOcc.Start;
        FGhostCopy := (ssCtrl in Shift) and (FDrag = pdMove);
        case FDrag of
          pdMove:
            begin
              if FDragBand or (FView = pvMonth) then
                Delta := Trunc(Hit.Time + Eps) - Trunc(FDragHit.Time + Eps)
              else
              begin
                Base := FDragHit.Time;
                Delta := Round((SnapTime(Hit.Time) - SnapTime(Base)) * MinsPerDay) * OneMinute;
              end;
              FGhostStart := FDragOcc.Start + Delta;
              FGhostFinish := FGhostStart + Dur;
              if (Hit.Kind in [phSlot, phAllDay, phAppointment]) and (FGrouped or (FView = pvTimeline)) then
                FGhostRes := Hit.ResourceId;
            end;
          pdResizeStart:
            begin
              if FView = pvTimeline then
                T := XToTime(LX - (FV.Left + FBodyLeft) + ScrollX, True)
              else
                T := SnapTime(Hit.Time);
              FGhostStart := Min(T, FDragOcc.Finish - FSlotMinutes * OneMinute);
              FGhostFinish := FDragOcc.Finish;
            end;
          pdResizeEnd:
            begin
              if FView = pvTimeline then
                T := XToTime(LX - (FV.Left + FBodyLeft) + ScrollX, True)
              else
                T := SnapTime(Hit.Time) + FSlotMinutes * OneMinute;
              FGhostStart := FDragOcc.Start;
              FGhostFinish := Max(T, FDragOcc.Start + FSlotMinutes * OneMinute);
            end;
        end;
        Invalidate;
      end;
  end;
end;

procedure TPPGCustomPlanner.FinishDrag(Commit: Boolean);
var
  Kind: TPPGAppointmentChangeKind;
  Drag: TPPGPlannerDrag;
begin
  Drag := FDrag;
  FDrag := pdNone;
  StopAutoScroll;
  Invalidate;
  if not Commit then
    Exit;
  case Drag of
    pdPending:
      ; // Klick: Auswahl ist schon gesetzt
    pdMove, pdResizeStart, pdResizeEnd:
      begin
        if Drag = pdMove then
        begin
          if FGhostCopy then
            Kind := ackCopy
          else
            Kind := ackMove;
        end
        else
          Kind := ackResize;
        ChangeAppointment(FDragOcc, Kind, FGhostStart, FGhostFinish, FGhostRes);
      end;
  end;
end;

procedure TPPGCustomPlanner.ContentMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Hit: TPPGPlannerHit;
begin
  inherited ContentMouseDown(Button, Shift, X, Y);
  // Nach DblClick schickt die VCL noch ein MouseDown mit ssDouble: nicht
  // die eben geoeffnete Bearbeitung beenden
  if not Enabled or (ssDouble in Shift) then
    Exit;
  if Editing then
    EndEditSubject(True);
  if not Focused and CanFocus and IsWindowVisible(Handle) then
    SetFocus;
  Hit := HitTest(X, Y);
  FDragDown := Point(X, Y);
  if Button <> mbLeft then
  begin
    // Rechtsklick: Termin bzw. Feld waehlen (Kontextmenue)
    if Hit.Item >= 0 then
      SelectItemIndex(Hit.Item, True)
    else if Hit.Kind in [phSlot, phAllDay] then
      if not ((FSelItem < 0) and (Hit.Time >= FSelFrom) and (Hit.Time < FSelTo)) then
      begin
        SetSlotSelection(Hit.Time, Hit.Time + IfThen(Hit.Kind = phAllDay, 1, CurrentSlotLength),
          Hit.ResourceId, Hit.Kind = phAllDay);
        SelectionChanged;
      end;
    Exit;
  end;
  case Hit.Kind of
    phAppointment, phResizeStart, phResizeEnd:
      SelectItemIndex(Hit.Item, True);
    phMore:
      begin
        FView := pvDay;
        FDayCount := 1;
        FDate := Trunc(Hit.Time);
        InvalidateLayout;
        RangeChanged;
        Exit;
      end;
  end;
  StartDrag(Hit, Shift);
end;

procedure TPPGCustomPlanner.ContentMouseMove(Shift: TShiftState; X, Y: Integer);
var
  Hit: TPPGPlannerHit;
begin
  inherited ContentMouseMove(Shift, X, Y);
  if FDrag <> pdNone then
  begin
    UpdateDrag(X, Y, Shift);
    if FDrag in [pdSelect, pdMove, pdResizeStart, pdResizeEnd] then
      AutoScrollAt(X, Y);
    Exit;
  end;
  Hit := HitTest(X, Y);
  if Hit.Item <> FHot.Item then
  begin
    FHot := Hit;
    Application.CancelHint;
    Invalidate;
  end;
  FHot := Hit;
end;

procedure TPPGCustomPlanner.ContentMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited ContentMouseUp(Button, Shift, X, Y);
  if (Button = mbLeft) and (FDrag <> pdNone) then
    FinishDrag(True);
end;

procedure TPPGCustomPlanner.DoAutoScroll(const P: TPoint);
begin
  inherited DoAutoScroll(P);
  if FDrag <> pdNone then
    UpdateDrag(P.X, P.Y, KeyboardStateToShiftState);
end;

procedure TPPGCustomPlanner.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHot.Item >= 0 then
  begin
    FHot.Item := -1;
    FHot.Kind := phNone;
    Invalidate;
  end;
end;

procedure TPPGCustomPlanner.DblClick;
var
  P: TPoint;
  Hit: TPPGPlannerHit;
begin
  inherited DblClick;
  if not Enabled or not HandleAllocated then
    Exit;
  FDrag := pdNone;
  StopAutoScroll;
  // Ort des Doppelklicks = letztes MouseDown (nicht Mouse.CursorPos)
  P := FDragDown;
  Hit := HitTest(P.X, P.Y);
  case Hit.Kind of
    phAppointment, phResizeStart, phResizeEnd:
      OpenItem(Hit.Item);
    phSlot:
      if (FSelItem < 0) and (Hit.Time >= FSelFrom - Eps) and (Hit.Time < FSelTo - Eps) and not FSelAllDay then
        CreateAppointment(FSelFrom, FSelTo, FSelRes, False)
      else
        CreateAppointment(Hit.Time, Hit.Time + CurrentSlotLength, Hit.ResourceId, False);
    phAllDay:
      if (FSelItem < 0) and FSelAllDay and (Hit.Time >= FSelFrom - Eps) and (Hit.Time < FSelTo - Eps) then
        CreateAppointment(Trunc(FSelFrom), Trunc(FSelTo + Eps), FSelRes, True)
      else
        CreateAppointment(Trunc(Hit.Time), Trunc(Hit.Time) + 1, Hit.ResourceId, True);
  end;
end;

procedure TPPGCustomPlanner.WMSetCursor(var Message: TWMSetCursor);
var
  P: TPoint;
  Hit: TPPGPlannerHit;
begin
  if (Message.HitTest = HTCLIENT) and not (csDesigning in ComponentState) and not FReadOnly then
  begin
    P := ScreenToClient(Mouse.CursorPos);
    Hit := HitTest(P.X, P.Y);
    if (FDrag in [pdResizeStart, pdResizeEnd]) or (Hit.Kind in [phResizeStart, phResizeEnd]) then
    begin
      if FView = pvTimeline then
        Winapi.Windows.SetCursor(Screen.Cursors[crSizeWE])
      else
        Winapi.Windows.SetCursor(Screen.Cursors[crSizeNS]);
      Message.Result := 1;
      Exit;
    end;
    if Hit.Kind = phMore then
    begin
      Winapi.Windows.SetCursor(Screen.Cursors[crHandPoint]);
      Message.Result := 1;
      Exit;
    end;
  end;
  inherited;
end;

procedure TPPGCustomPlanner.CMHintShow(var Message: TCMHintShow);
var
  A: TPPGAppointment;
  S_: string;
begin
  inherited;
  if (FHot.Item < 0) or (FHot.Item >= Length(FItems)) or (FDrag <> pdNone) then
    Exit;
  A := FItems[FHot.Item].Appointment;
  S_ := AccChildName(FHot.Item + 1);
  if A.Body <> '' then
    S_ := S_ + #13#10 + A.Body;
  Message.HintInfo^.HintStr := S_;
  Message.HintInfo^.CursorRect := ItemRect(FHot.Item);
end;

function TPPGCustomPlanner.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  if (FView = pvMonth) and not (ssShift in Shift) then
  begin
    if WheelDelta > 0 then
      PrevPage
    else if WheelDelta < 0 then
      NextPage;
    Result := True;
    Exit;
  end;
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
end;

function TPPGCustomPlanner.LineHeight: Integer;
begin
  if IsTimeGrid then
    Result := SlotH
  else
    Result := inherited LineHeight;
end;

{ ---- Tastatur ---- }

procedure TPPGCustomPlanner.WMGetDlgCode(var Message: TWMGetDlgCode);
var
  Back: Boolean;
  I: Integer;
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS or DLGC_WANTCHARS;
  // Tab bleibt im Planer, solange es einen naechsten Termin gibt
  if (TMessage(Message).WParam = VK_TAB) and FLayoutValid then
  begin
    Back := GetKeyState(VK_SHIFT) < 0;
    if Back then
      I := FSelItem - 1
    else
      I := FSelItem + 1;
    if FSelItem < 0 then
      if Back then
        I := High(FItems)
      else
        I := 0;
    if (I >= 0) and (I < Length(FItems)) then
      Message.Result := Message.Result or DLGC_WANTTAB;
  end;
end;

procedure TPPGCustomPlanner.SelectNextItem(Backwards: Boolean);
var
  I: Integer;
begin
  EnsureLayout;
  if Length(FItems) = 0 then
    Exit;
  if FSelItem < 0 then
  begin
    if Backwards then
      I := High(FItems)
    else
      I := 0;
  end
  else if Backwards then
    I := FSelItem - 1
  else
    I := FSelItem + 1;
  if (I >= 0) and (I < Length(FItems)) then
    SelectItemIndex(I, True);
end;

procedure TPPGCustomPlanner.MoveSlotFocus(DSlots, DDays: Integer; Extend: Boolean);
var
  Len, Cur, NewT, Lo: TDateTime;
  Res, R: Integer;
begin
  EnsureLayout;
  Len := CurrentSlotLength;
  if FSelTo <= FSelFrom then
  begin
    FSelFrom := SnapTime(FDate + FWorkStart * OneMinute);
    if FView = pvMonth then
      FSelFrom := FDate;
    FSelTo := FSelFrom + Len;
    FSelAnchor := FSelFrom;
  end;
  Res := FSelRes;
  if FSelItem >= 0 then
  begin
    // Vom gewaehlten Termin aus ins Raster
    FSelAnchor := SnapTime(FItems[FSelItem].Start);
    FSelFrom := FSelAnchor;
    FSelTo := FSelAnchor + Len;
  end;
  // Bewegt wird das freie Ende der Auswahl (nicht der Anker)
  if FSelFrom < FSelAnchor - Eps then
    Cur := FSelFrom
  else
    Cur := FSelTo - Len;
  if (FView = pvTimeline) and (DSlots <> 0) and not Extend then
  begin
    // Zeitleiste: hoch/runter wechselt die Ressource
    R := Max(0, FResources.IndexOfId(Res)) + DSlots;
    if (R >= 0) and (R < FResources.Count) then
      Res := FResources[R].Id;
    DSlots := 0;
  end;
  if FView = pvAgenda then
  begin
    SelectNextItem(DSlots < 0);
    Exit;
  end;
  if FView = pvMonth then
    NewT := Cur + DDays + DSlots * 7
  else if FView = pvTimeline then
    NewT := Cur + DDays * Len
  else
    NewT := Cur + DSlots * Len + DDays;
  // Ausserhalb des Zeitraums: blaettern
  if (NewT < RangeStart - Eps) or (NewT >= RangeEnd - Eps) then
  begin
    FDate := Trunc(NewT + Eps);
    InvalidateLayout;
    EnsureLayout;
    RangeChanged;
    SyncCalendar;
  end;
  if IsTimeGrid then
  begin
    // Innerhalb der gezeigten Stunden bleiben
    Lo := Trunc(NewT + Eps) + FDayStartHour / 24;
    if NewT < Lo - Eps then
      NewT := Lo;
    if NewT > Trunc(NewT + Eps) + FDayEndHour / 24 - Len + Eps then
      NewT := Trunc(NewT + Eps) + FDayEndHour / 24 - Len;
  end;
  if Extend then
  begin
    if NewT < FSelAnchor then
      SetSlotSelection(NewT, FSelAnchor + Len, Res, FSelAllDay)
    else
      SetSlotSelection(FSelAnchor, NewT + Len, Res, FSelAllDay);
  end
  else
  begin
    FSelAnchor := NewT;
    SetSlotSelection(NewT, NewT + Len, Res, FView = pvMonth);
  end;
  SelectionChanged;
end;

procedure TPPGCustomPlanner.KeyDown(var Key: Word; Shift: TShiftState);
var
  K: Word;
begin
  if FDrag <> pdNone then
  begin
    if Key = VK_ESCAPE then
    begin
      FinishDrag(False);
      Key := 0;
    end;
    Exit;
  end;
  inherited KeyDown(Key, Shift);
  if not Enabled or (Key = 0) then
    Exit;
  K := Key;
  if UseRightToLeftAlignment then
    if K = VK_LEFT then
      K := VK_RIGHT
    else if K = VK_RIGHT then
      K := VK_LEFT;
  case K of
    VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT:
      begin
        if (ssCtrl in Shift) and (FSelItem >= 0) then
        begin
          // Gewaehlten Termin verschieben bzw. Dauer aendern
          case K of
            VK_UP:
              if FView = pvMonth then
                MoveSelected(0, -7, False)
              else
                MoveSelected(-FSlotMinutes, 0, ssShift in Shift);
            VK_DOWN:
              if FView = pvMonth then
                MoveSelected(0, 7, False)
              else
                MoveSelected(FSlotMinutes, 0, ssShift in Shift);
            VK_LEFT:
              if FView = pvTimeline then
                MoveSelected(-FSlotMinutes, 0, ssShift in Shift)
              else
                MoveSelected(0, -1, False);
          else
            if FView = pvTimeline then
              MoveSelected(FSlotMinutes, 0, ssShift in Shift)
            else
              MoveSelected(0, 1, False);
          end;
        end
        else
          case K of
            VK_UP: MoveSlotFocus(-1, 0, ssShift in Shift);
            VK_DOWN: MoveSlotFocus(1, 0, ssShift in Shift);
            VK_LEFT: MoveSlotFocus(0, -1, ssShift in Shift);
          else
            MoveSlotFocus(0, 1, ssShift in Shift);
          end;
        Key := 0;
      end;
    VK_TAB:
      if not (ssCtrl in Shift) then
      begin
        SelectNextItem(ssShift in Shift);
        Key := 0;
      end;
    VK_PRIOR:
      begin
        PrevPage;
        Key := 0;
      end;
    VK_NEXT:
      begin
        NextPage;
        Key := 0;
      end;
    VK_HOME:
      begin
        GoToToday;
        Key := 0;
      end;
    VK_RETURN:
      begin
        if FSelItem >= 0 then
          OpenItem(FSelItem)
        else if FSelTo > FSelFrom then
          CreateAppointment(FSelFrom, FSelTo, FSelRes, FSelAllDay);
        Key := 0;
      end;
    VK_F2:
      begin
        if ssShift in Shift then
          BeginEditLocation
        else
          BeginEditSubject;
        Key := 0;
      end;
    VK_DELETE:
      begin
        DeleteSelected;
        Key := 0;
      end;
  end;
end;

procedure TPPGCustomPlanner.KeyPress(var Key: Char);
begin
  inherited KeyPress(Key);
  // Tippen auf gewaehlten Zeitfeldern legt einen Termin an
  if (Key >= ' ') and Enabled and not FReadOnly and (FSelItem < 0) and (FSelTo > FSelFrom) then
  begin
    CreateAppointment(FSelFrom, FSelTo, FSelRes, FSelAllDay, Key);
    Key := #0;
  end;
end;

procedure TPPGCustomPlanner.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
  if FSelItem >= 0 then
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, FSelItem + 1);
end;

procedure TPPGCustomPlanner.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

{ ---- Jetzt-Linie ---- }

procedure TPPGCustomPlanner.UpdateNowLoop;
var
  Need: Boolean;
  T: TDateTime;
begin
  if FNowAnim = nil then
    Exit;
  T := Now_;
  Need := FShowNowLine and HandleAllocated and Showing and (FNowOverride = 0) and
    not (csDesigning in ComponentState) and (FView <> pvAgenda) and (FView <> pvMonth) and
    (Length(FDays) > 0) and (T >= FDays[0]) and (T < FDays[High(FDays)] + 1);
  if Need and not FNowAnim.Looping then
  begin
    FNowMinute := Trunc(T * MinsPerDay);
    FNowAnim.StartLoop(60000);
  end
  else if not Need and FNowAnim.Looping then
    FNowAnim.Stop;
end;

procedure TPPGCustomPlanner.NowStep(Sender: TObject);
var
  M: Integer;
begin
  M := Trunc(Now_ * MinsPerDay);
  if M <> FNowMinute then
  begin
    FNowMinute := M;
    Invalidate;
  end;
end;

{ ---- Kalender ---- }

function TPPGCustomPlanner.CalendarDateMarked(ADate: TDate): Boolean;
var
  D, I, K: Integer;
  O: TArray<TPPGOccurrence>;
begin
  D := Trunc(ADate);
  if (D < FMarkFrom) or (D >= FMarkTo) then
  begin
    // Fenster um den Tag (ein Kalendermonat mit Rand) auf einmal abfragen
    FMarkFrom := D - 45;
    FMarkTo := D + 45;
    SetLength(FMarks, FMarkTo - FMarkFrom);
    for I := 0 to High(FMarks) do
      FMarks[I] := False;
    O := GetOccurrences(FMarkFrom, FMarkTo);
    for I := 0 to High(O) do
      for K := Max(FMarkFrom, Trunc(O[I].Start)) to Min(FMarkTo - 1, Trunc(Max(O[I].Start, O[I].Finish - Eps))) do
        FMarks[K - FMarkFrom] := True;
  end;
  Result := FMarks[D - FMarkFrom];
end;

procedure TPPGCustomPlanner.CalendarDateSelected(Sender: TObject; ADate: TDate);
begin
  if FUpdatingCalendar then
    Exit;
  FUpdatingCalendar := True;
  try
    UserSetDate(ADate);
  finally
    FUpdatingCalendar := False;
  end;
end;

{ ---- Barrierefreiheit ---- }

procedure TPPGCustomPlanner.WndProc(var Message: TMessage);
begin
  if (GMsgPlannerAction <> 0) and (Message.Msg = GMsgPlannerAction) then
  begin
    // Aus AccChildDoDefault gepostet (ausserhalb des COM-Aufrufs)
    EnsureLayout;
    if (Integer(Message.WParam) >= 1) and (Integer(Message.WParam) <= Length(FItems)) then
    begin
      SelectItemIndex(Integer(Message.WParam) - 1, True);
      if FSelItem >= 0 then
        OpenItem(FSelItem);
    end;
    Exit;
  end;
  inherited WndProc(Message);
end;

function TPPGCustomPlanner.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_TABLE;
end;

function TPPGCustomPlanner.AccValue: string;
begin
  if FSelItem >= 0 then
    Result := AccChildName(FSelItem + 1)
  else if FSelTo > FSelFrom then
  begin
    if FSelAllDay then
      Result := FormatDateTime(FormatSettings.LongDateFormat, FSelFrom)
    else
      Result := Format(PPGStr(@SPPGPlannerAccSlot), [
        FormatDateTime(FormatSettings.LongDateFormat, FSelFrom) + ' ' + TimeText(FSelFrom),
        TimeText(FSelTo)]);
  end
  else
    Result := FormatDateTime(FormatSettings.LongDateFormat, FDate);
end;

function TPPGCustomPlanner.AccChildCount: Integer;
begin
  EnsureLayout;
  Result := Length(FItems);
end;

function TPPGCustomPlanner.AccChildName(Id: Integer): string;
var
  O: TPPGOccurrence;
  Subj, FromS, ToS: string;
begin
  if (Id < 1) or (Id > Length(FItems)) then
    Exit('');
  O := FItems[Id - 1];
  Subj := O.Appointment.Subject;
  if Subj = '' then
    Subj := PPGStr(@SPPGPlannerNoSubject);
  if O.Appointment.AllDay then
  begin
    FromS := FormatDateTime(FormatSettings.ShortDateFormat, O.Start);
    ToS := FormatDateTime(FormatSettings.ShortDateFormat, Max(O.Start, O.Finish - 1));
  end
  else
  begin
    FromS := FormatDateTime(FormatSettings.ShortDateFormat, O.Start) + ' ' + TimeText(O.Start);
    if Trunc(O.Finish - Eps) = Trunc(O.Start) then
      ToS := TimeText(O.Finish)
    else
      ToS := FormatDateTime(FormatSettings.ShortDateFormat, O.Finish) + ' ' + TimeText(O.Finish);
  end;
  Result := Format(PPGStr(@SPPGPlannerAccItem), [Subj, FromS, ToS]);
  if O.Appointment.Location <> '' then
    Result := Result + ', ' + O.Appointment.Location;
end;

function TPPGCustomPlanner.AccChildRole(Id: Integer): Integer;
begin
  Result := ROLE_SYSTEM_LISTITEM;
end;

function TPPGCustomPlanner.AccChildState(Id: Integer): Integer;
begin
  Result := STATE_SYSTEM_SELECTABLE or STATE_SYSTEM_FOCUSABLE;
  if Id - 1 = FSelItem then
  begin
    Result := Result or STATE_SYSTEM_SELECTED;
    if Focused then
      Result := Result or STATE_SYSTEM_FOCUSED;
  end;
  if (Id >= 1) and (Id <= Length(FItems)) and (FReadOnly or FItems[Id - 1].Appointment.ReadOnly) then
    Result := Result or STATE_SYSTEM_READONLY;
  if IsRectEmpty(AccChildRect(Id)) then
    Result := Result or STATE_SYSTEM_INVISIBLE or STATE_SYSTEM_OFFSCREEN;
end;

function TPPGCustomPlanner.AccChildRect(Id: Integer): TRect;
var
  R: TRect;
begin
  Result := ItemRect(Id - 1);
  if not IntersectRect(R, Result, ClientRect) then
    Result := Rect(0, 0, 0, 0);
end;

function TPPGCustomPlanner.AccChildAt(X, Y: Integer): Integer;
var
  Hit: TPPGPlannerHit;
begin
  Hit := HitTest(X, Y);
  Result := Hit.Item + 1;
end;

function TPPGCustomPlanner.AccChildDefaultAction(Id: Integer): string;
begin
  Result := PPGStr(@SPPGAccOpen);
end;

procedure TPPGCustomPlanner.AccChildDoDefault(Id: Integer);
begin
  if HandleAllocated then
    PostMessage(Handle, GMsgPlannerAction, WPARAM(Id), 0);
end;

function TPPGCustomPlanner.AccFocusedChild: Integer;
begin
  if Focused and (FSelItem >= 0) then
    Result := FSelItem + 1
  else
    Result := 0;
end;

function TPPGCustomPlanner.AccSelectedChild: Integer;
begin
  Result := FSelItem + 1;
end;

end.
