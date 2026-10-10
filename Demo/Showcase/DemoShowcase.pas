unit DemoShowcase;

// Komponentenseiten der Demo ("Showcase"): Navigation nach Funktionsgruppen,
// je Komponente eine eigene Seite mit
//   - Buehne (die Komponente, frisch wie aus der Palette) und Objektinspektor,
//     in dem sich jede Eigenschaft live aendern laesst,
//   - Erklaerung der gewaehlten Eigenschaft (Wirkung, Beispiel, Praxis; aus
//     Docs\Controls\props ueber DemoDocs),
//   - Ereignis-Protokoll, erzeugtem Pascal-Code und DFM-Text,
//   - Praxisbeispielen mit dem Quelltext, der sie baut,
//   - Ueberblick aus der Notiz der Klasse (Wofuer, Wann verwenden ...).
//
// ShowcaseEntries ist die eine Liste "Komponente -> Gruppe". Done: True heisst:
// die Seite ist fertig (eine Unit Showcase\DemoShow*.pas meldet ihre
// Seitenklasse mit RegisterShowcasePage an). Build\make-docs.ps1 liest die
// Liste und verlangt fuer fertige Komponenten Praxis-Texte zu jeder
// Eigenschaft. Format eines Eintrags deshalb: Cls, Group, Done, Summary.
//
// Seiten werden erst beim ersten Oeffnen aufgebaut (84 Seiten, schneller Start).

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Types,
  System.TypInfo, System.Generics.Collections, Vcl.Graphics, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.Forms, Vcl.Menus, {$IF CompilerVersion >= 24.0}System.Actions, {$IFEND}Vcl.ActnList, Vcl.ImgList,
  PPG.Types, PPG.Controls.Base, PPG.Button, PPG.Panel, PPG.Labels, PPG.PageControl,
  PPG.Memo, PPG.ListBox, PPG.Splitter, PPG.Menus, PPG.Hints,
  DemoKit, DemoInspector;

type
  TDemoGroup = (sgButtons, sgInput, sgChoice, sgLists, sgGrid, sgDates, sgLayout, sgMenus,
    sgFeedback, sgCharts, sgDatabase, sgPrint, sgStyle);

  TDemoGroupDef = record
    Caption: string;
    Icon: Word;
    Intro: string;
  end;

  TDemoShowcaseEntry = record
    Cls: string;
    Group: TDemoGroup;
    Done: Boolean;
    Summary: string;
  end;

const
  ShowcaseGroups: array[TDemoGroup] of TDemoGroupDef = (
    (Caption: 'Buttons & Aktionen'; Icon: $E8B0; Intro: 'Befehle ausl{oe}sen: einzelne Buttons, Symbolleisten und das Men{ue}band.'),
    (Caption: 'Eingabe'; Icon: $E70F; Intro: 'Felder f{ue}r Text, Zahlen, Masken, Kennw{oe}rter, Dateien, Stichw{oe}rter und Farben.'),
    (Caption: 'Auswahl'; Icon: $E9E9; Intro: 'Ein/Aus, eine aus mehreren, mehrere aus vielen, Regler und Bewertungen.'),
    (Caption: 'Listen & B{ae}ume'; Icon: $EA37; Intro: 'Eintr{ae}ge zeigen und w{ae}hlen: Listen, Listen mit Haken, B{ae}ume und Kacheln.'),
    (Caption: 'Tabelle'; Icon: $E80A; Intro: 'Das Grid: sortieren, filtern, gruppieren, summieren, bearbeiten und exportieren.'),
    (Caption: 'Datum & Planung'; Icon: $E787; Intro: 'Kalender, Datums- und Zeitfelder, Terminplaner und Kanban-Board.'),
    (Caption: 'Navigation & Layout'; Icon: $ECA5; Intro: 'Fl{ae}chen, Seiten, Reiter, Navigation, Teiler, Statusleiste und Assistent.'),
    (Caption: 'Men{ue}s & Dialoge'; Icon: $E8BD; Intro: 'Men{ue}leiste, Kontextmen{ue}, Dialoge, Hinweise und Sprechblasen.'),
    (Caption: 'R{ue}ckmeldung'; Icon: $EA8F; Intro: 'Beschriftungen, Plaketten, Fortschritt, Meldungen, Benachrichtigungen und Pr{ue}fung.'),
    (Caption: 'Diagramme'; Icon: $E9D2; Intro: 'Diagramme, Mini-Verl{ae}ufe, Tachos und Kennzahl-Kacheln.'),
    (Caption: 'Datenbank'; Icon: $E8F1; Intro: 'Die Controls mit DataSource und DataField: Felder, Tabelle, Diagramm, Planer, Board.'),
    (Caption: 'Druck & Export'; Icon: $E749; Intro: 'Drucken mit Vorschau: Tabelle, Terminplan und Board.'),
    (Caption: 'Darstellung & Stil'; Icon: $E771; Intro: 'Eine Stilquelle f{ue}r alle Controls: Preset, Hell/Dunkel, Hints, Toasts und Dialoge.'));

  // Jede Paletten-Komponente genau einmal (der Selbsttest gleicht mit
  // DemoMain.PaletteControls ab). Done = Seite fertig.
  ShowcaseEntries: array[0..83] of TDemoShowcaseEntry = (
    (Cls: 'TPPGButton'; Group: sgButtons; Done: True; Summary: 'Befehls-Button mit Symbol, Umschalter, Split-Men{ue} und Dialog-Logik.'),
    (Cls: 'TPPGToolBar'; Group: sgButtons; Done: False; Summary: 'Symbolleiste mit {Ue}berlauf-Men{ue}.'),
    (Cls: 'TPPGRibbon'; Group: sgButtons; Done: False; Summary: 'Men{ue}band wie in Office mit KeyTips und Schnellzugriff.'),
    (Cls: 'TPPGEdit'; Group: sgInput; Done: False; Summary: 'Einzeiliges Textfeld mit Hinweistext und Pr{ue}fzustand.'),
    (Cls: 'TPPGMemo'; Group: sgInput; Done: False; Summary: 'Mehrzeiliges Textfeld.'),
    (Cls: 'TPPGSpinEdit'; Group: sgInput; Done: False; Summary: 'Ganze Zahl mit Hoch/Runter.'),
    (Cls: 'TPPGNumberEdit'; Group: sgInput; Done: False; Summary: 'Zahlen, Betr{ae}ge und Prozente; rechnet einfache Ausdr{ue}cke.'),
    (Cls: 'TPPGMaskEdit'; Group: sgInput; Done: False; Summary: 'Eingabe nach Maske (PLZ, Telefon, IBAN).'),
    (Cls: 'TPPGPasswordEdit'; Group: sgInput; Done: False; Summary: 'Kennwortfeld mit Aufdecken.'),
    (Cls: 'TPPGFileEdit'; Group: sgInput; Done: False; Summary: 'Dateipfad mit {Oe}ffnen-Dialog und Ziehen.'),
    (Cls: 'TPPGSearchEdit'; Group: sgInput; Done: False; Summary: 'Suchfeld mit Vorschl{ae}gen.'),
    (Cls: 'TPPGTagEdit'; Group: sgInput; Done: False; Summary: 'Stichw{oe}rter als Chips.'),
    (Cls: 'TPPGColorPicker'; Group: sgInput; Done: False; Summary: 'Farbauswahl mit Palette und eigener Farbe.'),
    (Cls: 'TPPGCheckBox'; Group: sgChoice; Done: False; Summary: 'Kontrollk{ae}stchen, auch mit drittem Zustand.'),
    (Cls: 'TPPGRadioButton'; Group: sgChoice; Done: False; Summary: 'Optionsfeld: eine Wahl aus mehreren.'),
    (Cls: 'TPPGToggleSwitch'; Group: sgChoice; Done: False; Summary: 'Ein/Aus-Schalter f{ue}r Einstellungen.'),
    (Cls: 'TPPGRadioGroup'; Group: sgChoice; Done: False; Summary: 'Optionsgruppe, auch als Segment oder Auswahlkacheln.'),
    (Cls: 'TPPGCheckGroup'; Group: sgChoice; Done: False; Summary: 'Gruppe von Kontrollk{ae}stchen.'),
    (Cls: 'TPPGTrackBar'; Group: sgChoice; Done: False; Summary: 'Regler, auch mit Bereich.'),
    (Cls: 'TPPGRating'; Group: sgChoice; Done: False; Summary: 'Sterne-Bewertung.'),
    (Cls: 'TPPGComboBox'; Group: sgChoice; Done: False; Summary: 'Auswahlliste mit Bildern, Filter und eigenem Popup.'),
    (Cls: 'TPPGCheckComboBox'; Group: sgChoice; Done: False; Summary: 'Mehrfachauswahl im Aufklappfeld.'),
    (Cls: 'TPPGColumnComboBox'; Group: sgChoice; Done: False; Summary: 'Mehrspaltige Auswahlliste.'),
    (Cls: 'TPPGListBox'; Group: sgLists; Done: False; Summary: 'Liste mit Mehrfachauswahl, Bildern und Umsortieren.'),
    (Cls: 'TPPGCheckListBox'; Group: sgLists; Done: False; Summary: 'Liste mit Haken.'),
    (Cls: 'TPPGTreeView'; Group: sgLists; Done: False; Summary: 'Baum mit Nachladen und Bildern.'),
    (Cls: 'TPPGTileView'; Group: sgLists; Done: False; Summary: 'Kacheln und Karten wie im Explorer.'),
    (Cls: 'TPPGGrid'; Group: sgGrid; Done: False; Summary: 'Tabelle mit Sortieren, Filtern, Gruppieren und Summen.'),
    (Cls: 'TPPGCalendar'; Group: sgDates; Done: False; Summary: 'Monatskalender.'),
    (Cls: 'TPPGDatePicker'; Group: sgDates; Done: False; Summary: 'Datumsfeld mit Kalender.'),
    (Cls: 'TPPGTimePicker'; Group: sgDates; Done: False; Summary: 'Uhrzeitfeld.'),
    (Cls: 'TPPGPlanner'; Group: sgDates; Done: False; Summary: 'Terminplaner mit Tag, Woche, Monat und Ressourcen.'),
    (Cls: 'TPPGKanban'; Group: sgDates; Done: False; Summary: 'Kanban-Board mit Spalten, Karten und WIP-Grenzen.'),
    (Cls: 'TPPGPanel'; Group: sgLayout; Done: False; Summary: 'Fl{ae}che bzw. Karte im Stil des Presets.'),
    (Cls: 'TPPGScrollBox'; Group: sgLayout; Done: False; Summary: 'Scrollbereich.'),
    (Cls: 'TPPGGroupBox'; Group: sgLayout; Done: False; Summary: 'Gruppe mit Beschriftung.'),
    (Cls: 'TPPGExpander'; Group: sgLayout; Done: False; Summary: 'Aufklappbarer Abschnitt.'),
    (Cls: 'TPPGSplitter'; Group: sgLayout; Done: False; Summary: 'Teiler zum Gr{oe}{ss}e-Ziehen.'),
    (Cls: 'TPPGPageControl'; Group: sgLayout; Done: False; Summary: 'Seiten mit Reitern.'),
    (Cls: 'TPPGTabControl'; Group: sgLayout; Done: False; Summary: 'Reiterleiste, auch mit Schlie{ss}en.'),
    (Cls: 'TPPGNavigationView'; Group: sgLayout; Done: False; Summary: 'Navigation links wie in Windows 11.'),
    (Cls: 'TPPGBreadcrumb'; Group: sgLayout; Done: False; Summary: 'Pfad zum Anklicken.'),
    (Cls: 'TPPGStatusBar'; Group: sgLayout; Done: False; Summary: 'Statusleiste mit Feldern und Plaketten.'),
    (Cls: 'TPPGWizard'; Group: sgLayout; Done: False; Summary: 'Assistent mit Schritten.'),
    (Cls: 'TPPGMenuBar'; Group: sgMenus; Done: False; Summary: 'Men{ue}leiste f{ue}r ein TMainMenu.'),
    (Cls: 'TPPGPopupMenu'; Group: sgMenus; Done: False; Summary: 'Kontextmen{ue} im Stil des Presets.'),
    (Cls: 'TPPGTaskDialog'; Group: sgMenus; Done: False; Summary: 'Dialog mit Titel, Befehlslinks und Fu{ss}zeile.'),
    (Cls: 'TPPGHintManager'; Group: sgMenus; Done: False; Summary: 'Hinweise f{ue}r die ganze Anwendung.'),
    (Cls: 'TPPGCustomHint'; Group: sgMenus; Done: False; Summary: 'Hinweis mit Titel und Text f{ue}r einzelne Controls.'),
    (Cls: 'TPPGTeachingTip'; Group: sgMenus; Done: False; Summary: 'Sprechblase f{ue}r Tipps und Einf{ue}hrungen.'),
    (Cls: 'TPPGLabel'; Group: sgFeedback; Done: False; Summary: 'Beschriftung mit Mini-Markup.'),
    (Cls: 'TPPGLinkLabel'; Group: sgFeedback; Done: False; Summary: 'Text mit Links.'),
    (Cls: 'TPPGBadge'; Group: sgFeedback; Done: False; Summary: 'Plakette mit Zahl, Punkt oder Text.'),
    (Cls: 'TPPGProgressBar'; Group: sgFeedback; Done: False; Summary: 'Fortschrittsbalken.'),
    (Cls: 'TPPGProgressRing'; Group: sgFeedback; Done: False; Summary: 'Warte- und Fortschrittskreis.'),
    (Cls: 'TPPGInfoBar'; Group: sgFeedback; Done: False; Summary: 'Hinweisleiste mit Schweregrad und Aktion.'),
    (Cls: 'TPPGNotificationCenter'; Group: sgFeedback; Done: False; Summary: 'Toasts am Bildschirmrand.'),
    (Cls: 'TPPGBusyOverlay'; Group: sgFeedback; Done: False; Summary: 'Warten mit Abbrechen {ue}ber einer Fl{ae}che.'),
    (Cls: 'TPPGValidator'; Group: sgFeedback; Done: False; Summary: 'Pflichtfelder und Regeln f{ue}r ein Formular.'),
    (Cls: 'TPPGChart'; Group: sgCharts; Done: False; Summary: 'S{ae}ulen, Linien, Fl{ae}chen, Kreis und Ring.'),
    (Cls: 'TPPGSparkline'; Group: sgCharts; Done: False; Summary: 'Mini-Verlauf in einer Zeile.'),
    (Cls: 'TPPGGauge'; Group: sgCharts; Done: False; Summary: 'Tacho mit Bereichen.'),
    (Cls: 'TPPGKpiTile'; Group: sgCharts; Done: False; Summary: 'Kennzahl-Kachel mit Trend.'),
    (Cls: 'TPPGDBEdit'; Group: sgDatabase; Done: False; Summary: 'Textfeld an einem Datenfeld.'),
    (Cls: 'TPPGDBMemo'; Group: sgDatabase; Done: False; Summary: 'Memofeld an einem Datenfeld.'),
    (Cls: 'TPPGDBCheckBox'; Group: sgDatabase; Done: False; Summary: 'Kontrollk{ae}stchen an einem Datenfeld.'),
    (Cls: 'TPPGDBComboBox'; Group: sgDatabase; Done: False; Summary: 'Auswahlliste an einem Datenfeld.'),
    (Cls: 'TPPGDBLookupComboBox'; Group: sgDatabase; Done: False; Summary: 'Nachschlagen in einer zweiten Datenmenge.'),
    (Cls: 'TPPGDBDatePicker'; Group: sgDatabase; Done: False; Summary: 'Datumsfeld an einem Datenfeld.'),
    (Cls: 'TPPGDBGrid'; Group: sgDatabase; Done: False; Summary: 'Tabelle an einer Datenmenge.'),
    (Cls: 'TPPGDBChart'; Group: sgDatabase; Done: False; Summary: 'Diagramm aus einer Datenmenge.'),
    (Cls: 'TPPGDBPlanner'; Group: sgDatabase; Done: False; Summary: 'Terminplaner aus einer Datenmenge.'),
    (Cls: 'TPPGDBKanban'; Group: sgDatabase; Done: False; Summary: 'Board aus einer Datenmenge.'),
    (Cls: 'TPPGDBMaskEdit'; Group: sgDatabase; Done: False; Summary: 'Maskenfeld an einem Datenfeld.'),
    (Cls: 'TPPGDBNumberEdit'; Group: sgDatabase; Done: False; Summary: 'Zahlenfeld an einem Datenfeld.'),
    (Cls: 'TPPGDBColorPicker'; Group: sgDatabase; Done: False; Summary: 'Farbauswahl an einem Datenfeld.'),
    (Cls: 'TPPGDBCheckComboBox'; Group: sgDatabase; Done: False; Summary: 'Mehrfachauswahl an einem Datenfeld.'),
    (Cls: 'TPPGDBTagEdit'; Group: sgDatabase; Done: False; Summary: 'Stichw{oe}rter an einem Datenfeld.'),
    (Cls: 'TPPGDBNavigator'; Group: sgDatabase; Done: False; Summary: 'Bl{ae}ttern, Suchen und Filtern in einer Datenmenge.'),
    (Cls: 'TPPGDBRadioGroup'; Group: sgDatabase; Done: False; Summary: 'Optionsgruppe an einem Datenfeld.'),
    (Cls: 'TPPGGridPrinter'; Group: sgPrint; Done: False; Summary: 'Tabelle drucken mit Vorschau.'),
    (Cls: 'TPPGPlannerPrinter'; Group: sgPrint; Done: False; Summary: 'Terminplan drucken.'),
    (Cls: 'TPPGKanbanPrinter'; Group: sgPrint; Done: False; Summary: 'Board drucken.'),
    (Cls: 'TPPGStyleManager'; Group: sgStyle; Done: False; Summary: 'Eine Stilquelle f{ue}r alle Controls.'));

type
  TDemoComponentPage = class;
  TDemoComponentPageClass = class of TDemoComponentPage;

  /// Leitet die Ereignisse der Komponente auf der Buehne an die Seite weiter;
  /// je Ereignis eine Instanz, damit der Name bekannt ist.
  TDemoEventAdapter = class
  private
    FPage: TDemoComponentPage;
    FName: string;
    procedure Fire(const Detail: string);
  public
    constructor Create(APage: TDemoComponentPage; const AName: string);
    procedure Notify(Sender: TObject);
    procedure Key(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KeyPress(Sender: TObject; var Key: Char);
    procedure Mouse(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure MouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint; var Handled: Boolean);
    procedure MouseActivate(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y, HitTest: Integer; var MouseActivate: TMouseActivate);
    procedure DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure DragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState;
      var Accept: Boolean);
    procedure EndDrag(Sender, Target: TObject; X, Y: Integer);
    procedure StartDrag(Sender: TObject; var DragObject: TDragObject);
    procedure StartDock(Sender: TObject; var DragObject: TDragDockObject);
    procedure Gesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
    property Name: string read FName;
  end;

  /// Ein Praxisbeispiel: Beschreibung, Live-Flaeche, Code (ein-/ausblendbar).
  TDemoExampleView = class
  private
    FSheet: TPPGTabSheet;
    FTop: TPanel;
    FDesc: TPPGLabel;
    FLive: TPPGPanel;
    FCodePanel: TPanel;
    FCode: TPPGMemo;
    FToggle: TPPGButton;
    FUnitName: string;
    procedure ToggleClick(Sender: TObject);
    procedure CopyClick(Sender: TObject);
  public
    procedure ShowCode(AVisible: Boolean);
    property Sheet: TPPGTabSheet read FSheet;
    property Live: TPPGPanel read FLive;
    property Code: TPPGMemo read FCode;
    property CodePanel: TPanel read FCodePanel;
    property ToggleButton: TPPGButton read FToggle;
    property ExampleUnit: string read FUnitName;
  end;

  /// Seite mit lazy Aufbau beim ersten Oeffnen.
  TDemoShowcasePage = class(TDemoPage)
  private
    FBuilt: Boolean;
  protected
    procedure Build; override;
    procedure BuildContent; virtual; abstract;
  public
    procedure EnsureBuilt;
    procedure Activated; override;
    property Built: Boolean read FBuilt;
  end;

  /// Uebersicht einer Gruppe: eine Karte je Komponente.
  TDemoGroupPage = class(TDemoShowcasePage)
  private
    FGroup: TDemoGroup;
    FOpenButtons: TList<TPPGButton>;
    procedure OpenClick(Sender: TObject);
  protected
    procedure BuildContent; override;
  public
    destructor Destroy; override;
    procedure SelfTest(Check: TDemoCheck); override;
    property Group: TDemoGroup read FGroup write FGroup;
  end;

  /// Seite einer Komponente. Ableitungen geben die Klasse an, richten die
  /// Buehne ein und bauen die Praxisbeispiele.
  TDemoComponentPage = class(TDemoShowcasePage)
  private
    FRoot: TPanel;
    FTabs: TPPGPageControl;
    FHead: TPanel;
    FHeadText: TPPGLabel;
    FTrySheet: TPPGTabSheet;
    FStage: TPPGPanel;
    FStageHint: TPPGLabel;
    FRefHost: TPanel;
    FSubject: TComponent;
    FReference: TComponent;
    FInspector: TDemoInspector;
    FExplainBox: TPPGScrollBox;
    FExplain: TPPGLabel;
    FBottomTabs: TPPGPageControl;
    FEventList: TPPGListBox;
    FPascal: TPPGMemo;
    FDfm: TPPGMemo;
    FAdapters: TObjectList<TDemoEventAdapter>;
    FExamples: TObjectList<TDemoExampleView>;
    FLastEvent: string;
    FLastEventCount: Integer;
    FErrors: TStringList;
    FSelectedNode: TDemoPropNode;
    procedure InspectorSelect(Sender: TObject; Node: TDemoPropNode);
    procedure InspectorChanged(Sender: TObject; Node: TDemoPropNode);
    procedure InspectorError(Sender: TObject; Node: TDemoPropNode; const Msg: string);
    procedure ResetAllClick(Sender: TObject);
    procedure CopyCodeClick(Sender: TObject);
    procedure EventListClick(Sender: TObject);
    procedure StageResize(Sender: TObject);
    procedure RootResize(Sender: TObject);
    procedure ExplainResize(Sender: TObject);
    procedure LayoutTexts;
    procedure BuildHeader;
    procedure BuildTryTab;
    procedure BuildOverviewTab;
    procedure CreateSubject;
    procedure FreeSubject;
    procedure HookEvents;
    function UniqueName(const ABase: string): string;
    function MemoFor(AParent: TWinControl): TPPGMemo;
    procedure ShowExplanation(Node: TDemoPropNode; const AError: string = '');
  protected
    FCommonImages: TCustomImageList;
    FMenu: TPPGPopupMenu;
    FActions: TActionList;
    FAction: TAction;
    FHint: TPPGCustomHint;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure BuildContent; override;
    /// Klasse der Komponente auf der Buehne.
    function SubjectClass: TComponentClass; virtual; abstract;
    /// Buehne einrichten (Lage, Text) nach dem Erzeugen; Vorgabe: Caption = Name
    /// wie beim Ablegen aus der Palette.
    procedure SetupSubject(ASubject: TComponent); virtual;
    /// Komponenten fuer Verweis-Eigenschaften (Images, PopupMenu, Action ...).
    procedure AddCandidates(List: TList<TComponent>); virtual;
    /// Praxisbeispiele anlegen (AddExample).
    procedure BuildExamples; virtual;
    /// Ein Ereignis der Buehnen-Komponente; Detail = Parameter.
    procedure EventOccurred(const AName, ADetail: string); virtual;
    function AddExample(const ACaption, AUnitName, ADescription: string): TDemoExampleView;
    procedure LogEvent(const AName, ADetail: string);
    procedure RefreshCode;
    function GroupOf: TDemoGroup;
    property Subject: TComponent read FSubject;
    property Reference: TComponent read FReference;
    property Stage: TPPGPanel read FStage;
    property Tabs: TPPGPageControl read FTabs;
    property EventList: TPPGListBox read FEventList;
    property Examples: TObjectList<TDemoExampleView> read FExamples;
    property Errors: TStringList read FErrors;
    property PascalMemo: TPPGMemo read FPascal;
    property DfmMemo: TPPGMemo read FDfm;
    property ExplainLabel: TPPGLabel read FExplain;
  public
    destructor Destroy; override;
    procedure AppearanceChanged; override;
    procedure SelfTest(Check: TDemoCheck); override;
    /// Buehne und Inspektor auf den Ausgangszustand (frische Komponente).
    procedure ResetSubject;
    /// Reiter waehlen: 0 = Ausprobieren, 1.. = Praxisbeispiele, danach Ueberblick.
    procedure ShowTab(Index: Integer);
    /// Unten rechts: 0 = Ereignisse, 1 = Code (Pascal), 2 = DFM.
    procedure ShowBottomTab(Index: Integer);
    /// In allen Praxisbeispielen den Code einblenden.
    procedure ShowAllCode;
    property Inspector: TDemoInspector read FInspector;
  end;

procedure RegisterShowcasePage(const ACls: string; APage: TDemoComponentPageClass);
function ShowcasePageClass(const ACls: string): TDemoComponentPageClass;
function ShowcaseIndex(const ACls: string): Integer;

implementation

uses
  System.Math, Vcl.StdCtrls, Vcl.Clipbrd, PPG.Theme, PPG.Tokens, PPG.Edit, PPG.ComboBox,
  PPG.RadioGroup, DemoDocs, DemoCodeGen;

function AppearanceLines(const Code: string): string;
var
  Lines: TStringList;
  I: Integer;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    Lines.Text := Code;
    for I := 0 to Lines.Count - 1 do
      if Pos('.Appearance.', Lines[I]) > 0 then
        Result := Result + ' ' + Trim(Lines[I]);
  finally
    Lines.Free;
  end;
end;

function DfmIsValid(const S: string): Boolean;
var
  Src: TStringStream;
  Bin: TMemoryStream;
begin
  Result := False;
  if Trim(S) = '' then
    Exit;
  Src := TStringStream.Create(S);
  Bin := TMemoryStream.Create;
  try
    try
      ObjectTextToBinary(Src, Bin);
      Result := Bin.Size > 0;
    except
      on EParserError do
        Result := False;
    end;
  finally
    Bin.Free;
    Src.Free;
  end;
end;

var
  GPages: TDictionary<string, TDemoComponentPageClass>;

procedure RegisterShowcasePage(const ACls: string; APage: TDemoComponentPageClass);
begin
  if GPages = nil then
    GPages := TDictionary<string, TDemoComponentPageClass>.Create;
  GPages.AddOrSetValue(UpperCase(ACls), APage);
end;

function ShowcasePageClass(const ACls: string): TDemoComponentPageClass;
begin
  if (GPages = nil) or not GPages.TryGetValue(UpperCase(ACls), Result) then
    Result := nil;
end;

function ShowcaseIndex(const ACls: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(ShowcaseEntries) do
    if SameText(ShowcaseEntries[I].Cls, ACls) then
      Exit(I);
end;

// Label mit Umbruch auf die Breite des Parents (Hoehe nach Text)
procedure WrapToParent(Lbl: TPPGLabel);
var
  W: Integer;
begin
  if (Lbl = nil) or (Lbl.Parent = nil) then
    Exit;
  W := Max(200, Lbl.Parent.ClientWidth - Lbl.Left - 16);
  Lbl.AutoSize := False;
  Lbl.WordWrap := True;
  Lbl.Width := W;
  Lbl.AutoSize := True;
  Lbl.AutoSize := False;
  Lbl.Width := W;
end;

function NewPanel(AOwner: TComponent; AParent: TWinControl; AAlign: TAlign): TPanel;
begin
  Result := TPanel.Create(AOwner);
  Result.Parent := AParent;
  Result.Align := AAlign;
  Result.BevelOuter := bvNone;
  Result.Caption := '';
  Result.ShowCaption := False;
  Result.ParentColor := True;
  Result.ParentBackground := True;
end;

{ TDemoEventAdapter }

constructor TDemoEventAdapter.Create(APage: TDemoComponentPage; const AName: string);
begin
  inherited Create;
  FPage := APage;
  FName := AName;
end;

procedure TDemoEventAdapter.Fire(const Detail: string);
begin
  FPage.EventOccurred(FName, Detail);
end;

procedure TDemoEventAdapter.Notify(Sender: TObject);
begin
  Fire('');
end;

procedure TDemoEventAdapter.Key(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  Fire(Format('Key = %d', [Key]));
end;

procedure TDemoEventAdapter.KeyPress(Sender: TObject; var Key: Char);
begin
  if Key >= ' ' then
    Fire(Format('Key = ''%s''', [Key]))
  else
    Fire(Format('Key = #%d', [Ord(Key)]));
end;

procedure TDemoEventAdapter.Mouse(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Fire(Format('%s, X = %d, Y = %d', [GetEnumName(System.TypeInfo(TMouseButton), Ord(Button)), X, Y]));
end;

procedure TDemoEventAdapter.MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  Fire(Format('X = %d, Y = %d', [X, Y]));
end;

procedure TDemoEventAdapter.ContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
  Fire('');
end;

procedure TDemoEventAdapter.MouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint; var Handled: Boolean);
begin
  Fire(Format('WheelDelta = %d', [WheelDelta]));
end;

procedure TDemoEventAdapter.MouseActivate(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y, HitTest: Integer; var MouseActivate: TMouseActivate);
begin
  Fire('');
end;

procedure TDemoEventAdapter.DragDrop(Sender, Source: TObject; X, Y: Integer);
begin
  Fire('');
end;

procedure TDemoEventAdapter.DragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState;
  var Accept: Boolean);
begin
  Fire('');
end;

procedure TDemoEventAdapter.EndDrag(Sender, Target: TObject; X, Y: Integer);
begin
  Fire('');
end;

procedure TDemoEventAdapter.StartDrag(Sender: TObject; var DragObject: TDragObject);
begin
  Fire('');
end;

procedure TDemoEventAdapter.StartDock(Sender: TObject; var DragObject: TDragDockObject);
begin
  Fire('');
end;

procedure TDemoEventAdapter.Gesture(Sender: TObject; const EventInfo: TGestureEventInfo;
  var Handled: Boolean);
begin
  Fire(Format('GestureID = %d', [EventInfo.GestureID]));
end;

{ TDemoExampleView }

procedure TDemoExampleView.ShowCode(AVisible: Boolean);
begin
  FCodePanel.Visible := AVisible;
  if AVisible then
    FToggle.Caption := L('Code ausblenden')
  else
    FToggle.Caption := L('Code anzeigen');
end;

procedure TDemoExampleView.ToggleClick(Sender: TObject);
begin
  ShowCode(not FCodePanel.Visible);
end;

procedure TDemoExampleView.CopyClick(Sender: TObject);
begin
  Clipboard.AsText := FCode.Lines.Text;
end;

{ TDemoShowcasePage }

procedure TDemoShowcasePage.Build;
begin
  // Aufbau erst beim ersten Oeffnen (EnsureBuilt)
end;

procedure TDemoShowcasePage.EnsureBuilt;
begin
  if FBuilt then
    Exit;
  FBuilt := True;
  Sheet.DisableAlign;
  try
    BuildContent;
  finally
    Sheet.EnableAlign;
  end;
  ApplyDemoStyles(Sheet, nil);
  AppearanceChanged;
end;

procedure TDemoShowcasePage.Activated;
begin
  inherited Activated;
  EnsureBuilt;
end;

{ TDemoGroupPage }

destructor TDemoGroupPage.Destroy;
begin
  FOpenButtons.Free;
  inherited Destroy;
end;

procedure TDemoGroupPage.BuildContent;
const
  CardW = 300;
  CardH = 132;
var
  I, N, Col, X, Y, Cols: Integer;
  Card: TPPGPanel;
  Btn: TPPGButton;
  E: TDemoShowcaseEntry;
  Lbl: TPPGLabel;
begin
  FOpenButtons := TList<TPPGButton>.Create;
  NewPageHeader(Own, Sheet, ShowcaseGroups[FGroup].Caption, ShowcaseGroups[FGroup].Intro);
  Cols := 3;
  N := 0;
  for I := 0 to High(ShowcaseEntries) do
  begin
    E := ShowcaseEntries[I];
    if E.Group <> FGroup then
      Continue;
    Col := N mod Cols;
    X := PageX + Col * (CardW + CardGap);
    Y := PageContentTop + (N div Cols) * (CardH + CardGap);
    Card := NewCard(Own, Sheet, X, Y, CardW, CardH, E.Cls, E.Summary);
    if E.Done then
    begin
      Btn := NewButton(Own, Card, CardPad, CardH - CtlH - 14, 140, 'Seite {oe}ffnen', OpenClick, True);
      Btn.Hint := E.Cls;
      FOpenButtons.Add(Btn);
    end
    else
    begin
      Lbl := NewLabel(Own, Card, CardPad, CardH - 34, CardW - 2 * CardPad,
        'Seite folgt', tkCaption);
      Lbl.Anchors := [akLeft, akBottom];
    end;
    Inc(N);
  end;
end;

procedure TDemoGroupPage.OpenClick(Sender: TObject);
begin
  Host.ShowComponent(TPPGButton(Sender).Hint);
end;

procedure TDemoGroupPage.SelfTest(Check: TDemoCheck);
var
  I, Expected: Integer;
begin
  EnsureBuilt;
  Expected := 0;
  for I := 0 to High(ShowcaseEntries) do
    if (ShowcaseEntries[I].Group = FGroup) and ShowcaseEntries[I].Done then
      Inc(Expected);
  Check(Format('Gruppe %s: %d fertige Seite(n) verlinkt', [L(ShowcaseGroups[FGroup].Caption),
    Expected]), FOpenButtons.Count = Expected);
end;

{ TDemoComponentPage }

destructor TDemoComponentPage.Destroy;
begin
  // Buehne zuerst freigeben: ihre Ereignisse zeigen auf die Adapter
  FreeSubject;
  FAdapters.Free;
  FExamples.Free;
  FErrors.Free;
  inherited Destroy;
end;

function TDemoComponentPage.GroupOf: TDemoGroup;
var
  I: Integer;
begin
  I := ShowcaseIndex(SubjectClass.ClassName);
  if I >= 0 then
    Result := ShowcaseEntries[I].Group
  else
    Result := sgButtons;
end;

function TDemoComponentPage.UniqueName(const ABase: string): string;
var
  N: Integer;
begin
  N := 1;
  Result := ABase + IntToStr(N);
  while Own.FindComponent(Result) <> nil do
  begin
    Inc(N);
    Result := ABase + IntToStr(N);
  end;
end;

function TDemoComponentPage.MemoFor(AParent: TWinControl): TPPGMemo;
begin
  Result := TPPGMemo.Create(Own);
  Result.Parent := AParent;
  Result.Align := alClient;
  Result.ReadOnly := True;
  Result.WordWrap := False;
  Result.ScrollBars := ssBoth;
  Result.Font.Name := 'Consolas';
  Result.Font.Size := 10;
end;

procedure TDemoComponentPage.BuildContent;
begin
  FAdapters := TObjectList<TDemoEventAdapter>.Create(True);
  FExamples := TObjectList<TDemoExampleView>.Create(True);
  FErrors := TStringList.Create;
  FRoot := NewPanel(Own, Sheet, alClient);
  FRoot.OnResize := RootResize;
  BuildHeader;
  FTabs := TPPGPageControl.Create(Own);
  FTabs.Parent := FRoot;
  FTabs.Align := alClient;
  FTabs.AlignWithMargins := True;
  FTabs.Margins.SetBounds(PageX - 12, 4, 16, 12);
  BuildTryTab;
  BuildExamples;
  BuildOverviewTab;
  FTabs.ActivePageIndex := 0;
  CreateSubject;
end;

procedure TDemoComponentPage.BuildHeader;
var
  Head: TPanel;
  T, S, W: TPPGLabel;
  Idx: Integer;
  Summary, ForWhat: string;
begin
  Head := NewPanel(Own, FRoot, alTop);
  FHead := Head;
  Idx := ShowcaseIndex(SubjectClass.ClassName);
  Summary := '';
  if Idx >= 0 then
    Summary := ShowcaseEntries[Idx].Summary;
  T := NewLabel(Own, Head, PageX, PageTop - 8, 0, SubjectClass.ClassName, tkTitle);
  S := NewLabel(Own, Head, PageX, T.Top + T.Height + 2, 1000,
    Format('Unit %s {.} Gruppe %s {.} %s', [SubjectClass.UnitName,
    ShowcaseGroups[GroupOf].Caption, Summary]), tkSecondary);
  ForWhat := Docs.NoteSection(SubjectClass.ClassName, L('Wof{ue}r'));
  W := NewLabel(Own, Head, PageX, S.Top + S.Height + 6, 600, '', tkBody);
  W.AllowMarkup := True;
  W.Caption := DocToMarkup(ForWhat);
  FHeadText := W;
  WrapToParent(W);
  Head.Height := W.Top + W.Height + 8;
end;

procedure TDemoComponentPage.BuildTryTab;
var
  Right, Bottom, Tools, CodeTools: TPanel;
  Split: TPPGSplitter;
  Title: TPPGLabel;
  Btn: TPPGButton;
  Sheet2: TPPGTabSheet;
begin
  FTrySheet := TPPGTabSheet.Create(Own);
  FTrySheet.Caption := L('Ausprobieren');
  FTrySheet.PageControl := FTabs;

  // Rechts: Objektinspektor
  Right := NewPanel(Own, FTrySheet, alRight);
  Right.Width := 420;
  Right.AlignWithMargins := True;
  Right.Margins.SetBounds(0, 8, 0, 0);
  Tools := NewPanel(Own, Right, alTop);
  Tools.Height := 40;
  Title := NewLabel(Own, Tools, 0, 6, 0, 'Objektinspektor', tkCardTitle);
  Title.Top := 6;
  Btn := NewButton(Own, Tools, 0, 2, 150, 'Alles zur{ue}cksetzen', ResetAllClick);
  Btn.Anchors := [akTop, akRight];
  Btn.Left := Tools.Width - Btn.Width - 12;
  Btn.Hint := L('Neue Komponente wie frisch aus der Palette');
  FInspector := TDemoInspector.Create(Own);
  FInspector.Parent := Right;
  FInspector.Align := alClient;
  FInspector.OnSelect := InspectorSelect;
  FInspector.OnChanged := InspectorChanged;
  FInspector.OnError := InspectorError;
  FInspector.FreeNotification(Self);
  Split := TPPGSplitter.Create(Own);
  Split.Parent := FTrySheet;
  Split.Align := alRight;
  Split.Width := 8;

  // Unten: Erklaerung links, Ereignisse/Code rechts
  Bottom := NewPanel(Own, FTrySheet, alBottom);
  Bottom.Height := 250;
  FBottomTabs := TPPGPageControl.Create(Own);
  FBottomTabs.Parent := Bottom;
  FBottomTabs.Align := alRight;
  FBottomTabs.Width := 460;
  Sheet2 := TPPGTabSheet.Create(Own);
  Sheet2.Caption := L('Ereignisse');
  Sheet2.PageControl := FBottomTabs;
  FEventList := TPPGListBox.Create(Own);
  FEventList.Parent := Sheet2;
  FEventList.Align := alClient;
  FEventList.AllowMarkup := True;
  FEventList.OnClick := EventListClick;
  Sheet2 := TPPGTabSheet.Create(Own);
  Sheet2.Caption := L('Code (Pascal)');
  Sheet2.PageControl := FBottomTabs;
  CodeTools := NewPanel(Own, Sheet2, alTop);
  CodeTools.Height := 40;
  Btn := NewButton(Own, CodeTools, 4, 4, 110, 'Kopieren', CopyCodeClick);
  Btn.Tag := 1;
  NewLabel(Own, CodeTools, 124, 10, 300, 'Nur Abweichungen von einer neuen Komponente', tkCaption);
  FPascal := MemoFor(Sheet2);
  Sheet2 := TPPGTabSheet.Create(Own);
  Sheet2.Caption := L('DFM');
  Sheet2.PageControl := FBottomTabs;
  CodeTools := NewPanel(Own, Sheet2, alTop);
  CodeTools.Height := 40;
  Btn := NewButton(Own, CodeTools, 4, 4, 110, 'Kopieren', CopyCodeClick);
  Btn.Tag := 2;
  NewLabel(Own, CodeTools, 124, 10, 300, 'So speichert die IDE die Komponente', tkCaption);
  FDfm := MemoFor(Sheet2);
  FBottomTabs.ActivePageIndex := 0;
  Split := TPPGSplitter.Create(Own);
  Split.Parent := Bottom;
  Split.Align := alRight;
  Split.Width := 8;
  FExplainBox := TPPGScrollBox.Create(Own);
  FExplainBox.Parent := Bottom;
  FExplainBox.Align := alClient;
  FExplainBox.BorderStyle := bsNone;
  FExplainBox.OnResize := ExplainResize;
  FExplain := NewLabel(Own, FExplainBox, 4, 4, 600, '', tkBody);
  FExplain.AllowMarkup := True;
  FExplain.Anchors := [akLeft, akTop, akRight];
  Split := TPPGSplitter.Create(Own);
  Split.Parent := FTrySheet;
  Split.Align := alBottom;
  Split.Height := 8;

  // Mitte: Buehne
  FStage := TPPGPanel.Create(Own);
  FStage.Parent := FTrySheet;
  FStage.Align := alClient;
  FStage.AlignWithMargins := True;
  FStage.Margins.SetBounds(0, 8, 0, 0);
  FStage.ShowCaption := False;
  FStage.Caption := '';
  FStage.OnResize := StageResize;
  FStageHint := NewLabel(Own, FStage, 16, 12, 600,
    'B{ue}hne: Bedienen Sie die Komponente mit Maus und Tastatur. Rechts jede Eigenschaft '
    + 'ver{ae}ndern; unten erscheinen Erkl{ae}rung, Ereignisse und der passende Code.', tkCaption);
  FStageHint.Anchors := [akLeft, akTop, akRight];
  FRefHost := NewPanel(Own, FTrySheet, alNone);
  FRefHost.Visible := False;
  FRefHost.SetBounds(0, 0, 400, 300);

  // Verweis-Kandidaten (fuer Images, PopupMenu, DropDownMenu, Action, CustomHint ...)
  FCommonImages := Host.Images;
  FMenu := TPPGPopupMenu.Create(Own);
  FMenu.Name := UniqueName('PPGPopupMenu');
  FMenu.Items.Add(NewItem(L('Als PDF exportieren'), 0, False, True, nil, 0, ''));
  FMenu.Items.Add(NewItem(L('Als Excel-Datei exportieren'), 0, False, True, nil, 0, ''));
  FMenu.Items.Add(NewItem(L('In die Zwischenablage'), 0, False, True, nil, 0, ''));
  FActions := TActionList.Create(Own);
  FActions.Name := UniqueName('ActionList');
  FActions.Images := FCommonImages;
  FAction := TAction.Create(Own);
  FAction.Name := UniqueName('actSpeichern');
  FAction.ActionList := FActions;
  FAction.Caption := L('Speichern (aus der Action)');
  FAction.Hint := L('Speichert das Dokument (Text aus der Action)');
  FAction.ImageIndex := 0;
  FHint := TPPGCustomHint.Create(Own);
  FHint.Name := UniqueName('PPGCustomHint');
end;

procedure TDemoComponentPage.AddCandidates(List: TList<TComponent>);
begin
  if FCommonImages <> nil then
    List.Add(FCommonImages);
  List.Add(FMenu);
  List.Add(FAction);
  List.Add(FHint);
  if DemoStyles <> nil then
    List.Add(DemoStyles);
end;

procedure TDemoComponentPage.BuildExamples;
begin
end;

procedure TDemoComponentPage.BuildOverviewTab;
const
  Sections: array[0..3] of string = ('Wann verwenden', 'Unterschiede und Hinweise', 'Anpassung',
    'Beispiel');
var
  Sh: TPPGTabSheet;
  Box: TPPGScrollBox;
  I, Y: Integer;
  Text: string;
  Lbl: TPPGLabel;
  Memo: TPPGMemo;
begin
  Sh := TPPGTabSheet.Create(Own);
  Sh.Caption := L('{Ue}berblick');
  Sh.PageControl := FTabs;
  Box := TPPGScrollBox.Create(Own);
  Box.Parent := Sh;
  Box.Align := alClient;
  Box.BorderStyle := bsNone;
  Y := 16;
  Lbl := NewLabel(Own, Box, 16, Y, 0, 'Vorbild und Einordnung', tkSubtitle);
  Y := Lbl.Top + Lbl.Height + 6;
  for I := 0 to High(Sections) do
  begin
    Text := Docs.NoteSection(SubjectClass.ClassName, Sections[I]);
    if Text = '' then
      Continue;
    Lbl := NewLabel(Own, Box, 16, Y, 0, Sections[I], tkCardTitle);
    Y := Lbl.Top + Lbl.Height + 4;
    if Sections[I] = 'Beispiel' then
    begin
      Text := StringReplace(Text, '```pascal', '', []);
      Text := StringReplace(Text, '```', '', [rfReplaceAll]);
      Memo := TPPGMemo.Create(Own);
      Memo.Parent := Box;
      Memo.ReadOnly := True;
      Memo.Font.Name := 'Consolas';
      Memo.Font.Size := 10;
      Memo.Lines.Text := Trim(Text);
      Memo.SetBounds(16, Y, 900, 20 * Memo.Lines.Count + 24);
      Y := Memo.Top + Memo.Height + 16;
    end
    else
    begin
      Lbl := NewLabel(Own, Box, 16, Y, 900, '', tkBody);
      Lbl.AllowMarkup := True;
      Lbl.AutoSize := False;
      Lbl.WordWrap := True;
      Lbl.Width := 900;
      Lbl.Caption := DocToMarkup(Text);
      Lbl.AutoSize := True;
      Lbl.AutoSize := False;
      Lbl.Width := 900;
      Y := Lbl.Top + Lbl.Height + 16;
    end;
  end;
end;

function TDemoComponentPage.AddExample(const ACaption, AUnitName,
  ADescription: string): TDemoExampleView;
var
  V: TDemoExampleView;
  Top, Bar: TPanel;
  Desc: TPPGLabel;
  Btn: TPPGButton;
  Split: TPPGSplitter;
begin
  V := TDemoExampleView.Create;
  FExamples.Add(V);
  V.FUnitName := AUnitName;
  V.FSheet := TPPGTabSheet.Create(Own);
  V.FSheet.Caption := L(ACaption);
  V.FSheet.PageControl := FTabs;
  Top := NewPanel(Own, V.FSheet, alTop);
  V.FTop := Top;
  Desc := NewLabel(Own, Top, 8, 8, 600, ADescription, tkBody);
  Desc.AllowMarkup := True;
  V.FDesc := Desc;
  WrapToParent(Desc);
  V.FToggle := NewButton(Own, Top, 8, Desc.Top + Desc.Height + 8, 160, 'Code anzeigen',
    V.ToggleClick, True);
  Top.Height := V.FToggle.Top + V.FToggle.Height + 8;
  // Code rechts (ausgeblendet), Live-Flaeche links
  V.FCodePanel := NewPanel(Own, V.FSheet, alRight);
  V.FCodePanel.Width := 540;
  Bar := NewPanel(Own, V.FCodePanel, alTop);
  Bar.Height := 40;
  Btn := NewButton(Own, Bar, 8, 4, 110, 'Kopieren', V.CopyClick);
  NewLabel(Own, Bar, 128, 10, 470, Format('Quelltext aus %s.pas {-} genau der Code, der das Beispiel baut',
    [AUnitName]), tkCaption);
  V.FCode := MemoFor(V.FCodePanel);
  V.FCode.Lines.Text := TDemoDocs.ExampleCode(AUnitName);
  Split := TPPGSplitter.Create(Own);
  Split.Parent := V.FSheet;
  Split.Align := alRight;
  Split.Width := 8;
  V.FLive := TPPGPanel.Create(Own);
  V.FLive.Parent := V.FSheet;
  V.FLive.Align := alClient;
  V.FLive.AlignWithMargins := True;
  V.FLive.Margins.SetBounds(0, 4, 0, 0);
  V.FLive.ShowCaption := False;
  V.FLive.Caption := '';
  V.ShowCode(False);
  Btn.Hint := AUnitName;
  Result := V;
end;

procedure TDemoComponentPage.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  // Beim Schliessen gibt das Formular Buehne, Inspektor und (ueber den
  // Parent) die Vorgabe-Komponente vor dieser Seite frei
  if Operation = opRemove then
  begin
    if AComponent = FSubject then
      FSubject := nil;
    if AComponent = FReference then
      FReference := nil;
    if AComponent = FInspector then
      FInspector := nil;
  end;
end;

procedure TDemoComponentPage.SetupSubject(ASubject: TComponent);
begin
  if IsPublishedProp(ASubject, 'Caption') then
    SetStrProp(ASubject, 'Caption', ASubject.Name);
end;

procedure TDemoComponentPage.CreateSubject;
var
  Base: string;
begin
  Base := SubjectClass.ClassName;
  if (Length(Base) > 1) and (Base[1] = 'T') then
    Delete(Base, 1, 1);
  FSubject := SubjectClass.Create(Own);
  FSubject.Name := UniqueName(Base);
  FSubject.FreeNotification(Self);
  if FSubject is TControl then
  begin
    TControl(FSubject).Left := 32;
    TControl(FSubject).Top := 64;
    TControl(FSubject).Parent := FStage;
  end;
  SetupSubject(FSubject);
  FReference := SubjectClass.Create(nil);
  FReference.FreeNotification(Self);
  if FReference is TControl then
    TControl(FReference).Parent := FRefHost;
  HookEvents;
  FInspector.Candidates.Clear;
  AddCandidates(FInspector.Candidates);
  FInspector.Inspect(FSubject, FReference);
  ApplyDemoStyles(FInspector, nil);
  FInspector.SelectPath('Caption');
  RefreshCode;
end;

procedure TDemoComponentPage.FreeSubject;
begin
  FSelectedNode := nil;
  if FInspector <> nil then
    FInspector.Inspect(nil, nil);
  FreeAndNil(FSubject);
  FreeAndNil(FReference);
  if FAdapters <> nil then
    FAdapters.Clear;
end;

procedure TDemoComponentPage.ResetSubject;
begin
  FreeSubject;
  CreateSubject;
  FLastEvent := '';
  FLastEventCount := 0;
  if FEventList <> nil then
    FEventList.Items.Clear;
end;

procedure TDemoComponentPage.HookEvents;
var
  Props: PPropList;
  Count, I: Integer;
  P: PPropInfo;
  A: TDemoEventAdapter;
  M: TMethod;
  T: string;
begin
  Count := GetPropList(FSubject.ClassInfo, [tkMethod], nil, False);
  if Count = 0 then
    Exit;
  GetMem(Props, Count * SizeOf(PPropInfo));
  try
    GetPropList(FSubject.ClassInfo, [tkMethod], Props, False);
    for I := 0 to Count - 1 do
    begin
      P := Props^[I];
      T := string(P^.PropType^^.Name);
      A := TDemoEventAdapter.Create(Self, string(P^.Name));
      M.Data := A;
      if SameText(T, 'TNotifyEvent') then
        M.Code := @TDemoEventAdapter.Notify
      else if SameText(T, 'TKeyEvent') then
        M.Code := @TDemoEventAdapter.Key
      else if SameText(T, 'TKeyPressEvent') then
        M.Code := @TDemoEventAdapter.KeyPress
      else if SameText(T, 'TMouseEvent') then
        M.Code := @TDemoEventAdapter.Mouse
      else if SameText(T, 'TMouseMoveEvent') then
        M.Code := @TDemoEventAdapter.MouseMove
      else if SameText(T, 'TContextPopupEvent') then
        M.Code := @TDemoEventAdapter.ContextPopup
      else if SameText(T, 'TMouseWheelEvent') then
        M.Code := @TDemoEventAdapter.MouseWheel
      else if SameText(T, 'TMouseActivateEvent') then
        M.Code := @TDemoEventAdapter.MouseActivate
      else if SameText(T, 'TDragDropEvent') then
        M.Code := @TDemoEventAdapter.DragDrop
      else if SameText(T, 'TDragOverEvent') then
        M.Code := @TDemoEventAdapter.DragOver
      else if SameText(T, 'TEndDragEvent') then
        M.Code := @TDemoEventAdapter.EndDrag
      else if SameText(T, 'TStartDragEvent') then
        M.Code := @TDemoEventAdapter.StartDrag
      else if SameText(T, 'TStartDockEvent') then
        M.Code := @TDemoEventAdapter.StartDock
      else if SameText(T, 'TGestureEvent') then
        M.Code := @TDemoEventAdapter.Gesture
      else
      begin
        // Unbekannte Signatur: nicht protokollieren (Inspektor zeigt den Typ)
        A.Free;
        Continue;
      end;
      FAdapters.Add(A);
      SetMethodProp(FSubject, P, M);
    end;
  finally
    FreeMem(Props);
  end;
end;

procedure TDemoComponentPage.EventOccurred(const AName, ADetail: string);
begin
  LogEvent(AName, ADetail);
end;

procedure TDemoComponentPage.LogEvent(const AName, ADetail: string);
var
  S: string;
begin
  if FEventList = nil then
    Exit;
  if (AName = FLastEvent) and (FEventList.Items.Count > 0) then
  begin
    Inc(FLastEventCount);
    S := Format('<b>%s</b> (%d' + #$00D7 + ')', [AName, FLastEventCount]);
  end
  else
  begin
    FLastEvent := AName;
    FLastEventCount := 1;
    S := '<b>' + AName + '</b>';
    FEventList.Items.Insert(0, '');
  end;
  if ADetail <> '' then
    S := S + '  ' + MarkupEscape(ADetail);
  FEventList.Items[0] := S;
  while FEventList.Items.Count > 200 do
    FEventList.Items.Delete(FEventList.Items.Count - 1);
  if FInspector <> nil then
  begin
    FInspector.EventFired(AName);
    // Bedienung kann Werte aendern (Down, Fokus ...); Mausbewegung nicht
    if AName <> 'OnMouseMove' then
    begin
      FInspector.RefreshValues;
      RefreshCode;
    end;
  end;
end;

procedure TDemoComponentPage.EventListClick(Sender: TObject);
var
  S: string;
  P: Integer;
begin
  if FEventList.ItemIndex < 0 then
    Exit;
  S := FEventList.Items[FEventList.ItemIndex];
  S := StringReplace(S, '<b>', '', []);
  P := Pos('</b>', S);
  if P > 0 then
    FInspector.SelectPath(Copy(S, 1, P - 1));
end;

procedure TDemoComponentPage.RefreshCode;
begin
  if (FSubject = nil) or (FInspector = nil) or (FInspector.Model = nil) then
    Exit;
  FPascal.Lines.Text := PascalCode(FInspector.Model, FReference, FSubject.Name, 'Self');
  FDfm.Lines.Text := DfmText(FSubject);
end;

procedure TDemoComponentPage.CopyCodeClick(Sender: TObject);
begin
  if TComponent(Sender).Tag = 2 then
    Clipboard.AsText := FDfm.Lines.Text
  else
    Clipboard.AsText := FPascal.Lines.Text;
end;

procedure TDemoComponentPage.ResetAllClick(Sender: TObject);
begin
  ResetSubject;
end;

procedure TDemoComponentPage.LayoutTexts;
var
  V: TDemoExampleView;
begin
  if FHeadText <> nil then
  begin
    WrapToParent(FHeadText);
    FHead.Height := FHeadText.Top + FHeadText.Height + 8;
  end;
  if FExamples <> nil then
    for V in FExamples do
    begin
      WrapToParent(V.FDesc);
      V.FToggle.Top := V.FDesc.Top + V.FDesc.Height + 8;
      V.FTop.Height := V.FToggle.Top + V.FToggle.Height + 8;
    end;
end;

procedure TDemoComponentPage.RootResize(Sender: TObject);
begin
  LayoutTexts;
end;

procedure TDemoComponentPage.ExplainResize(Sender: TObject);
begin
  if FSelectedNode <> nil then
    ShowExplanation(FSelectedNode);
end;

procedure TDemoComponentPage.StageResize(Sender: TObject);
begin
  if FStageHint <> nil then
    FStageHint.Width := Max(100, FStage.ClientWidth - 32);
end;

procedure TDemoComponentPage.InspectorSelect(Sender: TObject; Node: TDemoPropNode);
begin
  FSelectedNode := Node;
  ShowExplanation(Node);
end;

procedure TDemoComponentPage.InspectorChanged(Sender: TObject; Node: TDemoPropNode);
begin
  RefreshCode;
  ShowExplanation(Node);
end;

procedure TDemoComponentPage.InspectorError(Sender: TObject; Node: TDemoPropNode; const Msg: string);
begin
  FErrors.Add(Node.Path + ': ' + Msg);
  ShowExplanation(Node, Msg);
end;

procedure TDemoComponentPage.ShowExplanation(Node: TDemoPropNode; const AError: string);
var
  Owner: TObject;
  D: TDemoPropDoc;
  S, Values, Def: string;
  TD: PTypeData;
  T: PTypeInfo;
  I: Integer;
begin
  if (Node = nil) or (FSubject = nil) then
    Exit;
  Owner := Node.OwnerIn(FSubject);
  if Owner = nil then
    Exit;
  D := Docs.Describe(Owner.ClassType, Node.Name);
  Values := '';
  T := nil;
  if Node.Kind in [pkEnum] then
    T := Node.PropType
  else if Node.Kind = pkSet then
    T := GetTypeData(Node.PropType)^.CompType^;
  if T <> nil then
  begin
    TD := GetTypeData(T);
    for I := TD^.MinValue to TD^.MaxValue do
    begin
      if Values <> '' then
        Values := Values + ', ';
      Values := Values + GetEnumName(T, I);
    end;
  end;
  S := '<b>' + MarkupEscape(Node.Path) + '</b>  ' + MarkupEscape(Node.TypeName);
  if not (Node.Kind in [pkEvent, pkObject, pkOther]) then
  begin
    S := S + '<br>' + L('Aktuell: ') + '<b>' + MarkupEscape(Node.Literal(FSubject)) + '</b>';
    if FReference <> nil then
    begin
      Def := Node.Literal(FReference);
      S := S + L('   {.}   Vorgabe einer neuen Komponente: ') + MarkupEscape(Def);
    end;
  end;
  if AError <> '' then
    S := S + '<br><br><color=#C42B2B><b>' + L('Nicht {ue}bernommen: ') + '</b>' +
      MarkupEscape(AError) + '</color>';
  if D.Text <> '' then
    S := S + '<br><br><b>' + L('Wirkung') + '</b><br>' + DocToMarkup(D.Text)
  else
    S := S + '<br><br>' + L('(Noch keine Beschreibung)');
  if Values <> '' then
    S := S + '<br>' + L('Werte: ') + MarkupEscape(Values);
  if D.Usage <> '' then
    S := S + '<br><br><b>' + L('Beispiel') + '</b><br>' + DocToMarkup(D.Usage);
  if D.Practice <> '' then
    S := S + '<br><br><b>' + L('So setzen Sie es in der Praxis ein') + '</b><br>' +
      DocToMarkup(D.Practice);
  FExplain.AutoSize := False;
  FExplain.WordWrap := True;
  FExplain.Width := Max(200, FExplainBox.ClientWidth - 24);
  FExplain.Caption := S;
  FExplain.AutoSize := True;
  FExplain.AutoSize := False;
  FExplain.Width := Max(200, FExplainBox.ClientWidth - 24);
  FExplainBox.ScrollTo(0, 0);
end;

procedure TDemoComponentPage.AppearanceChanged;
begin
  inherited AppearanceChanged;
  if (FInspector <> nil) and (DemoStyler <> nil) then
    FInspector.SetSelectionColor(DemoStyler.Tokens.SurfaceHover);
end;

procedure TDemoComponentPage.ShowTab(Index: Integer);
begin
  EnsureBuilt;
  if (Index >= 0) and (Index < FTabs.PageCount) then
    FTabs.ActivePageIndex := Index;
end;

procedure TDemoComponentPage.ShowBottomTab(Index: Integer);
begin
  EnsureBuilt;
  if (Index >= 0) and (Index < FBottomTabs.PageCount) then
    FBottomTabs.ActivePageIndex := Index;
end;

procedure TDemoComponentPage.ShowAllCode;
var
  V: TDemoExampleView;
begin
  EnsureBuilt;
  for V in FExamples do
    V.ShowCode(True);
end;

procedure TDemoComponentPage.SelfTest(Check: TDemoCheck);
var
  All: TList<TDemoPropNode>;
  N: TDemoPropNode;
  D: TDemoPropDoc;
  Owner: TObject;
  MissingText, MissingPractice, Failed, Name, Code: string;
  Row: TDemoInspRow;
  Value: string;
  I, Edited: Integer;
  Prefix: string;
  V: TDemoExampleView;
begin
  EnsureBuilt;
  Prefix := SubjectClass.ClassName + ': ';
  ResetSubject;
  // 1. Jede Eigenschaft (auch in Unterobjekten) hat Wirkung und Praxis-Text
  MissingText := '';
  MissingPractice := '';
  All := TList<TDemoPropNode>.Create;
  try
    FInspector.Model.GetAll(All);
    for N in All do
    begin
      Owner := N.OwnerIn(FSubject);
      if Owner = nil then
        Continue;
      D := Docs.Describe(Owner.ClassType, N.Name);
      if D.Text = '' then
        MissingText := MissingText + ' ' + N.Path;
      if D.Practice = '' then
        MissingPractice := MissingPractice + ' ' + N.Path;
    end;
    Check(Format('%s%d Eigenschaften und Ereignisse mit Wirkung%s', [Prefix, All.Count,
      MissingText]), MissingText = '');
    Check(Format('%s%d Eigenschaften und Ereignisse mit Praxis-Text%s', [Prefix, All.Count,
      MissingPractice]), MissingPractice = '');

    // 2. Jede bearbeitbare Zeile: anderen Wert setzen, zuruecksetzen
    FErrors.Clear;
    Failed := '';
    Edited := 0;
    for N in All do
    begin
      if (N.Kind in [pkObject, pkEvent, pkOther]) or N.ReadOnly then
        Continue;
      if (N.Parent = nil) and SameText(N.Name, 'Name') then
        Continue;
      Row := FInspector.RowOf(N.Path);
      if (Row = nil) or (Row.Editor = nil) then
      begin
        Failed := Failed + ' ' + N.Path + '(ohne Editor)';
        Continue;
      end;
      Value := '';
      case N.Kind of
        pkBoolean:
          if N.GetOrd(FSubject) <> 0 then Value := 'False' else Value := 'True';
        pkInteger, pkInt64:
          Value := IntToStr(N.GetOrd(FSubject) + 1);
        pkColor:
          if N.GetOrd(FSubject) = clRed then Value := 'clBlue' else Value := 'clRed';
        pkString:
          if Row.Editor is TPPGEdit then
            Value := N.GetStr(FSubject) + 'x';
        pkSet:
          if TPPGCheckGroup(Row.Editor).Items.Count > 0 then
          begin
            if TPPGCheckGroup(Row.Editor).Checked[0] then
              Value := ''
            else
              Value := TPPGCheckGroup(Row.Editor).Items[0];
          end;
      end;
      if Row.Editor is TPPGComboBox then
      begin
        // Einen anderen Eintrag der Liste waehlen
        Value := '';
        for I := 0 to TPPGComboBox(Row.Editor).Items.Count - 1 do
          if I <> TPPGComboBox(Row.Editor).ItemIndex then
          begin
            Value := TPPGComboBox(Row.Editor).Items[I];
            Break;
          end;
        if Value = '' then
          Continue;
      end;
      if (N.Kind = pkFloat) or ((N.Kind = pkString) and (Value = '') and not (Row.Editor is TPPGComboBox)) then
        Continue;
      if not FInspector.SetValueText(N.Path, Value) then
      begin
        Failed := Failed + ' ' + N.Path + '(setzen)';
        Continue;
      end;
      Inc(Edited);
      FInspector.ResetNode(N);
      if not N.SameIn(FSubject, FReference) then
        Failed := Failed + ' ' + N.Path + '(zur' + #$00FC + 'cksetzen)';
    end;
    for I := 0 to FErrors.Count - 1 do
      Failed := Failed + ' [' + FErrors[I] + ']';
    Check(Format('%s%d Zeilen gesetzt und zur' + #$00FC + 'ckgesetzt%s', [Prefix, Edited, Failed]),
      (Failed = '') and (Edited > 20));
  finally
    All.Free;
  end;

  // 3. Code: neue Komponente ohne Optik-Zeilen, Preset-Wechsel ohne Appearance-Werte
  ResetSubject;
  Code := FPascal.Lines.Text;
  Name := FSubject.Name;
  Check(Prefix + 'Pascal-Code einer neuen Komponente: Create, Parent, keine Appearance',
    (Pos(Name + ' := ' + SubjectClass.ClassName + '.Create(Self);', Code) > 0) and
    (Pos('.Parent := ', Code) > 0) and (Pos('.Appearance.', Code) = 0));
  if FInspector.RowOf('Preset') <> nil then
  begin
    FInspector.SetValueText('Preset', 'Classic');
    Code := FPascal.Lines.Text;
    Check(Prefix + 'Pascal-Code nach Preset-Wechsel: nur die Preset-Zeile, keine Farben' +
      AppearanceLines(Code),
      (Pos('.Preset := ''Classic'';', Code) > 0) and (Pos('.Appearance.', Code) = 0));
    FInspector.SetValueText('Appearance.Rounding', '11');
    Code := FPascal.Lines.Text;
    Check(Prefix + 'Pascal-Code nach eigener Rundung: Appearance.Rounding := 11',
      Pos('.Appearance.Rounding := 11;', Code) > 0);
  end;
  // 4. DFM: beginnt mit "object Name: Klasse" und laesst sich wieder einlesen
  Code := FDfm.Lines.Text;
  Check(Prefix + 'DFM-Text beginnt mit object ' + Name,
    Pos('object ' + Name + ': ' + SubjectClass.ClassName, Code) = 1);
  Check(Prefix + 'DFM-Text ist g' + #$00FC + 'ltig (ObjectTextToBinary)', DfmIsValid(Code));
  ResetSubject;
  // 5. Erklaerung zur gewaehlten Zeile
  FInspector.SelectPath('Caption');
  Check(Prefix + 'Erkl' + #$00E4 + 'rung zur Zeile Caption mit Wirkung und Praxis',
    (Pos('Caption', FExplain.Caption) > 0) and (Pos(L('Praxis'), FExplain.Caption) > 0));
  // 6. Praxisbeispiele: Code vorhanden
  for V in FExamples do
    Check(Format('%sBeispiel %s: Code aus der Ressource (%d Zeilen)', [Prefix, V.ExampleUnit,
      V.Code.Lines.Count]), V.Code.Lines.Count > 10);
end;

initialization

finalization
  FreeAndNil(GPages);

end.
