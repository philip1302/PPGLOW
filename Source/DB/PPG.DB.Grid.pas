unit PPG.DB.Grid;

{ TPPGDBGrid - Tabelle einer Datenmenge (Phase 9c), wie TDBGrid.

  Aufbau:
  - Erbt von TPPGCustomGrid (Zeichnen, Editoren, Tastatur, UIA bleiben).
  - Zeilen sind der Puffer des TDataLink (BufferCount = sichtbare Zeilen),
    nie die ganze Tabelle. Die Kopfzeile zeigt die Titel, die feste Spalte
    links den Datensatzzeiger (Indikator).
  - Die Texte des Puffers werden in den DataLink-Ereignissen gelesen und
    zwischengespeichert. Paint liest nur den Zwischenspeicher: kein
    Datensatzwechsel und keine Anwender-Ereignisse (OnGetText,
    OnCalcFields) waehrend des Zeichnens (Fallstrick aus der Roadmap).
  - Die senkrechte Leiste zeigt die Lage in der Datenmenge: bei
    IsSequenced nach RecNo/RecordCount, sonst dreistufig (Anfang, Mitte,
    Ende) wie TDBGrid. Ziehen, Mausrad und Blaettern bewegen die Datenmenge.
  - Spalten: ohne Columns alle sichtbaren Felder (Titel = DisplayLabel,
    Breite aus DisplayWidth); mit Columns (FieldName je Spalte) genau diese.
  - Bearbeiten mit den Grid-Editoren; der Editor zeigt Field.Text, Schreiben
    setzt Field.Text (Boolean-Felder: Kaestchen-Spalte).
  - Kaestchen-Spalten: Boolean-Felder sowie Spalten mit EditorKind = gekCheck
    bzw. CellKind = ckCheck. ValueChecked/ValueUnchecked (wie TDBCheckBox,
    Listen mit Semikolon) fuer Text- und Zahlfelder. Null bzw. ein unbekannter
    Wert erscheint grau (unbestimmt). Klick und Leertaste schalten um
    (nur mit dgEditing, ohne ReadOnly).
  - Nachschlagen: Nachschlagefelder (FieldKind = fkLookup) und Spalten mit
    ListSource/KeyField/ListField (wie TDBLookupComboBox) zeigen den Text aus
    der Liste; bearbeitet wird per Auswahlliste, geschrieben wird der
    Schluessel. Aufgeloeste Texte werden je Spalte zwischengespeichert und
    verworfen, sobald sich die Listen-Datenmenge aendert.
  - Owner-Draw wie TDBGrid: OnDrawColumnCell (Rect, DataCol, Column, State)
    nach OnDrawCell; waehrend des Ereignisses steht die Datenmenge auf dem
    gezeichneten Satz (Column.Field liefert dessen Werte, die Datenmenge darf
    nicht bewegt werden). DefaultDrawColumnCell zeichnet Text bzw. Kaestchen
    mit Canvas (Brush/Font). DefaultDrawing = False: das Grid zeichnet nur
    Flaechen (Theme, Stile, Auswahl), keine Texte und Kaestchen.
    Reihenfolge je Zelle: bedingte Formate und OnGetCellStyle (Flaeche,
    Textfarbe) -> Auswahl/Mehrfachauswahl -> Text/Kaestchen (DefaultDrawing)
    -> Fokusrahmen -> OnDrawCell -> OnDrawColumnCell.
  - Tastatur wie TDBGrid: Pfeile/Bild/Strg+Pos1/Ende bewegen die Datenmenge,
    Pfeil runter am Ende haengt an (dgEditing), Einfg fuegt ein, Strg+Entf
    loescht (mit Rueckfrage bei dgConfirmDelete), Esc bricht ab.
  - Sortieren ist Sache der Datenmenge: Klick auf den Titel loest
    OnTitleClick aus (dgTitleClick).
  - Spalten verschieben (dgColumnResize, wie TDBGrid), ausblenden, Layout
    speichern (Schluessel = Feldname) wie im Grid (Phase 13g); automatische
    Spalten behalten Position, Sichtbarkeit und Breite beim Neuaufbau.
  - Summenzeile (ShowFooter) aus der Datenmenge: Column.FooterField (z.B. ein
    TAggregateField) oder OnGetFooterText. Das Grid liest dafuer nie die
    ganze Datenmenge (Paint-Regel aus Phase 9).
  - Drucken und Export (IPPGTableSource): die Datenmenge wird einmal mit
    DisableControls und Lesezeichen durchlaufen (hoechstens ExportMaxRecords).
  - Mehrfachauswahl (dgMultiSelect) wie TDBGrid: SelectedRows haelt Lesezeichen
    (sortiert nach CompareBookmarks). Strg+Klick schaltet eine Zeile um,
    Umschalt+Klick waehlt den Bereich vom Anker, Umschalt+Pfeil erweitert,
    Strg+A waehlt alles, Strg+Leertaste (bzw. Leertaste ausserhalb von
    Kaestchen) schaltet um, Strg+Entf loescht die Auswahl. Klick und
    Navigation ohne Umschalt/Strg heben die Auswahl auf (Klick waehlt dann die
    angeklickte Zeile, wie TDBGrid). Schliessen der Datenmenge und Wechsel der
    DataSource leeren die Auswahl. Nach einem Wechsel von Index oder
    Sortierung SelectedRows.Refresh aufrufen (manche Datenmengen liefern dann
    andere Lesezeichen fuer denselben Satz).
  - Nicht unterstuetzt: Gruppieren (braeuchte die ganze Datenmenge im Speicher;
    GROUP BY in der Abfrage nutzen), Unterspalten (ADT/Array-Felder). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.Types,
  System.Generics.Collections, Vcl.Controls, Vcl.Graphics, Vcl.Grids, Vcl.DBGrids, Vcl.StdCtrls,
  Data.DB,
  PPG.Types, PPG.Grid, PPG.Grid.Columns, PPG.Grid.Data, PPG.Grid.Styles, PPG.Grid.CellKinds;

type
  TPPGCustomDBGrid = class;

  TPPGDBGridColumn = class;

  /// Verbindung einer Nachschlage-Spalte zu ihrer Listen-Datenmenge.
  TPPGDBGridListLink = class(TDataLink)
  private
    FColumn: TPPGDBGridColumn;
  protected
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure LayoutChanged; override;
    procedure RecordChanged(Field: TField); override;
  public
    constructor Create(AColumn: TPPGDBGridColumn);
  end;

  /// Spalte mit Feldname (Columns des DB-Grids).
  TPPGDBGridColumn = class(TPPGGridColumn)
  private
    FFieldName: string;
    FFooterField: string;
    FAlignmentSet: Boolean;
    FButtonStyle: TColumnButtonStyle;
    FValueChecked: string;
    FValueUnchecked: string;
    FListLink: TPPGDBGridListLink;
    FKeyField: string;
    FListField: string;
    FLookupCache: TDictionary<string, string>;
    procedure SetFieldName(const Value: string);
    procedure SetFooterField(const Value: string);
    function GetAlignment: TAlignment;
    procedure SetAlignment(const Value: TAlignment);
    procedure SetValueChecked(const Value: string);
    procedure SetValueUnchecked(const Value: string);
    function GetListSource: TDataSource;
    procedure SetListSource(Value: TDataSource);
    procedure SetKeyField(const Value: string);
    procedure SetListField(const Value: string);
    function Grid: TPPGCustomDBGrid;
    function GetField: TField;
  protected
    function GetDisplayName: string; override;
    /// Listen-Datenmenge geaendert: aufgeloeste Texte verwerfen.
    procedure ListChanged;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function ShowsEllipsis: Boolean; override;
    /// Ausrichtung aus dem Feld, solange die Spalte keine eigene hat.
    procedure ApplyFieldAlignment(F: TField);
    /// Nachschlage-Spalte (ListSource mit DataSet, KeyField und ListField gesetzt)?
    function IsLookup: Boolean;
    /// Datenmenge der Liste (nil = keine bzw. ListSource ohne DataSet).
    function ListDataSet: TDataSet;
    /// Erstes Feld aus ListField (das angezeigte).
    function ListResultField: string;
    /// Anzeigetext zum Schluessel (aus der Liste, zwischengespeichert);
    /// '' = Null oder nicht gefunden.
    function LookupText(const Key: Variant): string;
    /// Feld der Spalte in der offenen Datenmenge (nil = keins), wie TColumn.Field.
    property Field: TField read GetField;
  published
    property FieldName: string read FFieldName write SetFieldName;
    /// Feld fuer die Summenzeile (z.B. TAggregateField der Datenmenge).
    property FooterField: string read FFooterField write SetFooterField;
    /// Ohne eigenen Wert die Ausrichtung des Felds (wie TColumn.Alignment).
    property Alignment: TAlignment read GetAlignment write SetAlignment stored FAlignmentSet;
    /// Wie TColumn.ButtonStyle: cbsAuto (Auswahlliste bei PickList bzw. Nachschlagefeld),
    /// cbsEllipsis (Textfeld mit "..."-Knopf: OnEditButtonClick), cbsNone (nur Text).
    property ButtonStyle: TColumnButtonStyle read FButtonStyle write FButtonStyle default cbsAuto;
    /// Kaestchen-Spalte: Wert(e) fuer "an" (wie TDBCheckBox.ValueChecked,
    /// mehrere mit Semikolon; geschrieben wird der erste). Leer = '1'/'True'/
    /// 'Ja' gelten als an, geschrieben wird '1'. Boolean-Felder: ohne Wirkung.
    property ValueChecked: string read FValueChecked write SetValueChecked;
    /// Wert(e) fuer "aus". Leer = jeder andere Wert ist aus (geschrieben: '0');
    /// gesetzt = andere Werte erscheinen grau (unbestimmt).
    property ValueUnchecked: string read FValueUnchecked write SetValueUnchecked;
    /// Nachschlage-Spalte (wie TDBLookupComboBox): Liste mit den Eintraegen.
    /// FieldName ist das Schluesselfeld der Datenmenge.
    property ListSource: TDataSource read GetListSource write SetListSource;
    /// Schluesselfeld in der Liste (passt zum Wert von FieldName).
    property KeyField: string read FKeyField write SetKeyField;
    /// Angezeigtes Feld der Liste (weitere mit Semikolon werden ignoriert).
    property ListField: string read FListField write SetListField;
  end;

  /// Ausgewaehlte Datensaetze des DB-Grids (Mehrfachauswahl, dgMultiSelect)
  /// als Lesezeichen, wie TBookmarkList (TDBGrid.SelectedRows). Die Liste ist
  /// nach DataSet.CompareBookmarks sortiert.
  TPPGBookmarkList = class
  private
    FGrid: TPPGCustomDBGrid;
    FList: TList<TBookmark>;
    FUpdateCount: Integer;
    FChanged: Boolean;
    FCheckOrder: Boolean;
    function DataSet: TDataSet;
    function GetCount: Integer;
    function GetItem(Index: Integer): TBookmark;
    function GetCurrentRowSelected: Boolean;
    procedure SetCurrentRowSelected(Value: Boolean);
    procedure Changed;
    procedure SortList;
    procedure EnsureOrder;
  protected
    procedure BeginUpdate;
    procedure EndUpdate;
    /// Lesezeichen aufnehmen bzw. entfernen (True = Liste geaendert).
    function AddBookmark(const Item: TBookmark): Boolean;
    function RemoveBookmark(const Item: TBookmark): Boolean;
    /// Lesezeichen des aktiven Datensatzes (leer = keiner, z.B. neuer Satz).
    function CurrentBookmark: TBookmark;
  public
    constructor Create(AGrid: TPPGCustomDBGrid);
    destructor Destroy; override;
    /// Auswahl aufheben.
    procedure Clear;
    /// Alle Datensaetze der Datenmenge waehlen (einmal durchlaufen).
    procedure SelectAll;
    /// Ausgewaehlte Datensaetze loeschen (ohne Rueckfrage, wie TBookmarkList).
    procedure Delete;
    /// Index des Lesezeichens bzw. Einfuegeposition; True = gefunden.
    function Find(const Item: TBookmark; var Index: Integer): Boolean;
    function IndexOf(const Item: TBookmark): Integer;
    /// Ungueltige Lesezeichen entfernen, die uebrigen neu lesen und sortieren
    /// (nach einem Wechsel von Index oder Sortierung); True = entfernt.
    function Refresh: Boolean;
    property Count: Integer read GetCount;
    property CurrentRowSelected: Boolean read GetCurrentRowSelected write SetCurrentRowSelected;
    property Items[Index: Integer]: TBookmark read GetItem; default;
  end;

  /// Verbindung des Grids zur Datenmenge.
  TPPGGridDataLink = class(TDataLink)
  private
    FGrid: TPPGCustomDBGrid;
  protected
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure DataSetScrolled(Distance: Integer); override;
    procedure LayoutChanged; override;
    procedure EditingChanged; override;
    procedure RecordChanged(Field: TField); override;
    procedure UpdateData; override;
    procedure FocusControl(Field: TFieldRef); override;
  public
    constructor Create(AGrid: TPPGCustomDBGrid);
  end;

  /// Wie TDBGridClickEvent (ohne Sender), damit migrierte Handler passen.
  TPPGDBGridColumnEvent = procedure(Column: TPPGDBGridColumn) of object;
  /// Text der Summenzeile fuer eine Spalte (nach FooterField).
  TPPGDBGridFooterEvent = procedure(Sender: TObject; Column: TPPGDBGridColumn;
    var Text: string) of object;
  /// Wie TDrawColumnCellEvent (Column als TPPGDBGridColumn): Owner-Draw einer
  /// Datenzelle. DataCol = Index der Spalte in Columns (bzw. den automatischen
  /// Spalten), unabhaengig von der Anzeige-Reihenfolge.
  TPPGDrawColumnCellEvent = procedure(Sender: TObject; const Rect: TRect; DataCol: Integer;
    Column: TPPGDBGridColumn; State: TGridDrawState) of object;

  TPPGCustomDBGrid = class(TPPGCustomGrid)
  private
    FDataLink: TPPGGridDataLink;
    FDBOptions: TDBGridOptions;
    FAutoColumns: TPPGGridColumns;  // ohne Columns: je sichtbares Feld eine
    FAutoState: TPPGGridColumns;    // Zustand der Auto-Spalten (Position, Breite ...)
    FFields: array of TField;       // Feld je Datenspalte
    FCache: array of array of string; // Puffer-Zeile x Datenspalte
    FSyncing: Integer;
    FLayoutBusy: Boolean;
    FReadOnly: Boolean;
    FOnTitleClick: TPPGDBGridColumnEvent;
    FOnCellClick: TPPGDBGridColumnEvent;
    FOnGetFooterText: TPPGDBGridFooterEvent;
    FExportMaxRecords: Integer;
    FShowRequired: Boolean;
    FSnap: array of array of Variant;   // Export: Werte [Satz][Feld]
    FSnapText: array of array of string;
    FSnapValid: Boolean;
    // Datensatz, auf dem der Zell-Editor geoeffnet wurde
    FEditBm: TBookmark;
    // Mehrfachauswahl: Liste, Anker fuer Bereiche, Markierung je Pufferzeile
    FSelected: TPPGBookmarkList;
    FAnchor: TBookmark;
    FMarks: array of Boolean;
    FRowBms: array of TBookmark; // Lesezeichen je Pufferzeile (nur dgMultiSelect)
    FOnSelectionChanged: TNotifyEvent;
    FOnDrawColumnCell: TPPGDrawColumnCellEvent;
    // Owner-Draw: gezeichnete Pufferzeile (-1 = ausserhalb von OnDrawColumnCell)
    FDrawRow: Integer;
    FDrawBrush: TColor; // vorbereitete Pinselfarbe (DefaultDrawColumnCell)
    FListBusy: Boolean;
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    procedure SetDBOptions(const Value: TDBGridOptions);
    function GetSelectedField: TField;
    function GetFieldCount: Integer;
    function GetField(Index: Integer): TField;
    procedure CMGetDataLink(var Message: TMessage); message CM_GETDATALINK;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
    procedure SetExportMaxRecords(const Value: Integer);
    procedure SetShowRequired(const Value: Boolean);
    function FieldEditable(F: TField): Boolean;
    /// Nachschlage-Quelle einer Datenspalte (Nachschlagefeld oder Spalte mit
    /// ListSource): Liste, deren Schluessel- und Anzeigefeld, Zielfeld.
    function LookupSource(ACol: Integer; out ListDS: TDataSet; out ListKey,
      ListResult: string; out Target: TField): Boolean;
    /// Spalte mit ListSource/KeyField/ListField (nicht: Nachschlagefeld).
    function ColumnLookup(ACol: Integer): TPPGDBGridColumn;
    procedure FillLookupEditor(ACol: Integer);
    procedure SetLookupByUser(ACol, ARow: Integer; const Value: string);
    /// Zustand eines Kaestchens im aktiven Datensatz.
    function FieldCheckState(F: TField; C: TPPGGridColumn): TCheckBoxState;
    function CheckStateText(State: TCheckBoxState): string;
    /// Text einer Datenzelle im aktiven Datensatz (wie im Zwischenspeicher).
    function FieldCellText(ACol: Integer; F: TField): string;
    function MultiSelectActive: Boolean;
    /// Datensaetze vom Lesezeichen bis zum aktiven Satz waehlen (ohne Abwahl).
    procedure SelectRangeTo(const FromBm: TBookmark);
    /// Umschalt+Pfeil: Auswahl um den neuen Satz erweitern bzw. verkleinern.
    procedure ExtendByStep(const OldBm: TBookmark);
  protected
    /// Kaestchen-Spalte (Boolean-Feld, gekCheck oder ckCheck)?
    function IsCheckColumn(ACol: Integer): Boolean;
    /// Listen-Datenmenge einer Nachschlage-Spalte geaendert.
    procedure ListDataChanged; virtual;
    { Owner-Draw }
    function OwnerDrawAssigned: Boolean; override;
    procedure OwnerDrawCell(ACol, VRow, ARow: Integer; const R: TRect;
      State: TGridDrawState); override;
    function DefaultDrawsKinds: Boolean; override;
    /// OnDrawColumnCell ausloesen (Datenmenge steht auf dem Satz).
    procedure DrawColumnCell(const Rect: TRect; DataCol: Integer; Column: TPPGDBGridColumn;
      State: TGridDrawState); virtual;
    /// Auswahl geaendert: Markierungen neu, OnSelectionChanged.
    procedure SelectionChanged; virtual;
    /// Markierung je Pufferzeile aus SelectedRows (ausserhalb von Paint).
    procedure UpdateMarks;
    function RowMarked(ARow: Integer): Boolean; override;
    procedure ContentMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    /// Rueckfrage vor dem Loeschen der Auswahl (dgConfirmDelete). Standard: MessageDlg.
    function ConfirmDeleteSelected(ACount: Integer): Boolean; virtual;
    { Ereignisse des DataLinks }
    procedure LinkActive(Value: Boolean); virtual;
    procedure DataChanged; virtual;
    procedure LayoutChanged; virtual;
    procedure EditingChanged; virtual;
    procedure RecordChanged(Field: TField); virtual;
    procedure UpdateData; virtual;
    { Aufbau }
    procedure BuildColumns;
    procedure UpdateBufferCount;
    procedure RebuildCache;
    procedure SyncPosition;
    function DataRowHeight: Integer;
    function VisibleDataRows: Integer;
    function FieldOfCol(ACol: Integer): TField;
    function DataColCount: Integer;
    { Erweiterungspunkte des Grids }
    function CreateColumns: TPPGGridColumns; override;
    function ColumnOf(ACol: Integer): TPPGGridColumn; override;
    function ColumnKey(ACol: Integer): string; override;
    function CanGroup: Boolean; override;
    function ColumnCollection: TPPGGridColumns; override;
    function KindOf(ACol: Integer): IPPGCellKind; override;
    function CachedFooterText(ACol: Integer): string; override;
    { Druck und Export: Felder der Datenmenge (ohne Indikator) }
    procedure EnsureSnapshot;
    function TableColCount: Integer; override;
    function TableRowCount: Integer; override;
    function TableColumn(ACol: Integer): TPPGTableColumnInfo; override;
    function TableCellText(ACol, ARow: Integer): string; override;
    function TableCellValue(ACol, ARow: Integer): Variant; override;
    function PrintCellStyle(ACol, ARow: Integer; const Text: string): TPPGGridCellStyle; override;
    function PrintCellKind(ACol: Integer; out Ctx: TPPGCellKindContext): IPPGCellKind; override;
    function ExportAggregate(ACol: Integer): TPPGGridAggregate; override;
    function ExportMerges: TArray<TRect>; override;
    function ExportOutline: TArray<TPPGOutlineRow>; override;
    function ExportColumnLook(ACol: Integer): TPPGTableColumnLook; override;
    function TableDataCol(ACol: Integer): Integer; override;
    function TableStyleRow(ARow: Integer): Integer; override;
    procedure ColumnsChanged; override;
    function RowScrollY: Integer; override;
    function RowsContentHeight: Integer; override;
    procedure ScrollCellsTo(X, Y: Integer); override;
    function GetCellText(ACol, ARow: Integer): string; override;
    function GetEditText(ACol, ARow: Integer): string; override;
    procedure SetCellByUser(ACol, ARow: Integer; const Value: string); override;
    procedure EditorOpened(ACol, ARow: Integer); override;
    procedure EditorPrepare(ACol, ARow: Integer); override;
    procedure EditorEdited; override;
    function CanEditCell(ACol, VRow: Integer): Boolean; override;
    function CellEditorKind(ACol, ARow: Integer): TPPGGridEditorKind; override;
    function SelectCell(ACol, ARow: Integer): Boolean; override;
    procedure HeaderClicked(ACol, VRow: Integer); override;
    procedure Scrolled; override;
    procedure Resize; override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure NavigateKey(var Key: Word; Shift: TShiftState); override;
    procedure ContentMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    /// Rueckfrage vor dem Loeschen (dgConfirmDelete). Standard: MessageDlg.
    function ConfirmDelete: Boolean; virtual;

    property DataLink: TPPGGridDataLink read FDataLink;
    property Options: TDBGridOptions read FDBOptions write SetDBOptions
      default [dgEditing, dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines,
        dgTabs, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack];
    property ReadOnly: Boolean read FReadOnly write FReadOnly default False;
    property OnTitleClick: TPPGDBGridColumnEvent read FOnTitleClick write FOnTitleClick;
    property OnCellClick: TPPGDBGridColumnEvent read FOnCellClick write FOnCellClick;
    property OnGetFooterText: TPPGDBGridFooterEvent read FOnGetFooterText write FOnGetFooterText;
    /// Druck/Export lesen hoechstens so viele Saetze.
    property ExportMaxRecords: Integer read FExportMaxRecords write SetExportMaxRecords default 100000;
    /// Pflichtfelder (TField.Required) mit einem Sternchen im Spaltentitel.
    property ShowRequired: Boolean read FShowRequired write SetShowRequired default False;
    /// Auswahl der Mehrfachauswahl geaendert (SelectedRows).
    property OnSelectionChanged: TNotifyEvent read FOnSelectionChanged write FOnSelectionChanged;
    /// Owner-Draw einer Datenzelle wie TDBGrid.OnDrawColumnCell (nach
    /// OnDrawCell). Canvas ist vorbereitet wie bei TDBGrid: Schrift der
    /// Spalte, Font.Color und Brush.Color (bsSolid) in den Farben der Zelle
    /// (Theme, Dunkelmodus, Auswahl). Die Datenmenge steht auf dem
    /// gezeichneten Satz.
    property OnDrawColumnCell: TPPGDrawColumnCellEvent read FOnDrawColumnCell write FOnDrawColumnCell;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ExecuteAction(Action: TBasicAction): Boolean; override;
    function UpdateAction(Action: TBasicAction): Boolean; override;
    /// Feld der Fokusspalte.
    property SelectedField: TField read GetSelectedField;
    /// Felder der angezeigten Spalten (ohne Indikator).
    property FieldCount: Integer read GetFieldCount;
    property Fields[Index: Integer]: TField read GetField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    /// Ausgewaehlte Datensaetze (nur mit dgMultiSelect), wie TDBGrid.SelectedRows.
    property SelectedRows: TPPGBookmarkList read FSelected;
    /// Wie TDBGrid.DefaultDrawColumnCell: zeichnet den Inhalt der Zelle (Text
    /// bzw. Kaestchen/Zellart) in Rect, Text in Canvas.Font. Wurde
    /// Canvas.Brush.Color gegenueber der vorbereiteten Farbe geaendert, wird
    /// Rect vorher damit gefuellt (sonst bleibt die gezeichnete Flaeche mit
    /// Stilen und Auswahl). Fuer OnDrawColumnCell gedacht (sonst: aktiver
    /// Datensatz, Fuellung bei Brush.Style <> bsClear).
    procedure DefaultDrawColumnCell(const Rect: TRect; DataCol: Integer;
      Column: TPPGDBGridColumn; State: TGridDrawState);
  end;

  TPPGDBGrid = class(TPPGCustomDBGrid)
  private
    function GetTitleFont: TFont;
    procedure SetTitleFont(const Value: TFont);
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Columns;
    property Bands;
    property ConditionalFormats;
    property ExportMaxRecords;
    property ShowRequired;
    property FixedColsRight;
    property HeaderMenu;
    property ShowFooter;
    property DataSource;
    property Options;
    property ReadOnly;
    property ScrollBarMode;
    property SmoothScrolling;
    property HighContrastSupport;
    property Styles;
    property GridLineWidth;
    property DrawingStyle;
    property FixedColor;
    property GradientEndColor;
    property GradientStartColor;
    /// Wie TDBGrid.TitleFont (= Styles.Header.Font, nicht gespeichert).
    property TitleFont: TFont read GetTitleFont write SetTitleFont stored False;
    { wie TDBGrid }
    property Align;
    property Anchors;
    property BiDiMode;
    property BorderStyle;
    property Color default clWindow;
    property Constraints;
    property DefaultDrawing;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property ToolTips;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Touch;
    property OnGesture;
    property OnCellClick;
    property OnColumnMoved;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDrawCell;
    property OnDrawColumnCell;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetCellStyle;
    property OnGetFooterText;
    property OnHeaderMenu;
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
    property OnTitleClick;
    property OnSelectionChanged;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnClick;
    property OnMouseWheel;
    property OnMouseActivate;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
    // Audit 5d Stufe 3: wie TDBGrid
    property OnColEnter;
    property OnColExit;
    property OnEditButtonClick;
  end;

implementation

uses
  PPG.Lang,
  PPG.ComboBox, System.Math, System.UITypes, System.Variants, Vcl.Dialogs,
  System.Generics.Defaults,
  PPG.Consts, PPG.Appearance,
  PPG.Controls.Scroll, PPG.Exceptions, PPG.DB.Controls, PPG.Grid.Paint, PPG.Render.Intf,
  PPG.Render.Gdi;

const
  // Indikator (Zeichen der Schrift, im Quelltext als Zeichencode: ASCII-Regel)
  IndBrowse = #$25B6;  // Dreieck
  IndEdit = #$270E;    // Stift
  IndInsert = '*';
  IndSelected = #$2713; // Haken: Satz der Mehrfachauswahl
  // Dreistufige Leiste ohne RecNo: Anfang, Mitte, Ende (in Zeilen)
  ThreeStateRows = 2;
  // Text-Abstand links/rechts (logische px, wie im Grid)
  CellPad = 6;

{ TPPGDBGridListLink }

constructor TPPGDBGridListLink.Create(AColumn: TPPGDBGridColumn);
begin
  inherited Create;
  FColumn := AColumn;
end;

procedure TPPGDBGridListLink.ActiveChanged;
begin
  if FColumn <> nil then
    FColumn.ListChanged;
end;

procedure TPPGDBGridListLink.DataSetChanged;
begin
  if FColumn <> nil then
    FColumn.ListChanged;
end;

procedure TPPGDBGridListLink.LayoutChanged;
begin
  // Nicht inherited: TDataLink.LayoutChanged ruft DataSetChanged (doppelt)
  if FColumn <> nil then
    FColumn.ListChanged;
end;

procedure TPPGDBGridListLink.RecordChanged(Field: TField);
begin
  // Aenderungen eines Satzes in Bearbeitung zaehlen erst nach Post
  // (DataSetChanged); ListChanged prueft den Zustand
  if FColumn <> nil then
    FColumn.ListChanged;
end;

{ TPPGDBGridColumn }

constructor TPPGDBGridColumn.Create(Collection: TCollection);
begin
  FListLink := TPPGDBGridListLink.Create(Self);
  inherited Create(Collection);
end;

destructor TPPGDBGridColumn.Destroy;
begin
  if FListLink <> nil then
    FListLink.FColumn := nil;
  FreeAndNil(FListLink);
  FreeAndNil(FLookupCache);
  inherited Destroy;
end;

function TPPGDBGridColumn.Grid: TPPGCustomDBGrid;
begin
  Result := nil;
  if (Collection <> nil) and (Collection.Owner is TPPGCustomDBGrid) then
    Result := TPPGCustomDBGrid(Collection.Owner);
end;

function TPPGDBGridColumn.GetField: TField;
var
  G: TPPGCustomDBGrid;
begin
  Result := nil;
  G := Grid;
  if (G <> nil) and (FFieldName <> '') and G.FDataLink.Active then
    Result := G.FDataLink.DataSet.FindField(FFieldName);
end;

procedure TPPGDBGridColumn.SetValueChecked(const Value: string);
begin
  if FValueChecked <> Value then
  begin
    FValueChecked := Value;
    Changed(False);
  end;
end;

procedure TPPGDBGridColumn.SetValueUnchecked(const Value: string);
begin
  if FValueUnchecked <> Value then
  begin
    FValueUnchecked := Value;
    Changed(False);
  end;
end;

function TPPGDBGridColumn.GetListSource: TDataSource;
begin
  if FListLink <> nil then
    Result := FListLink.DataSource
  else
    Result := nil;
end;

procedure TPPGDBGridColumn.SetListSource(Value: TDataSource);
begin
  if (FListLink = nil) or (FListLink.DataSource = Value) then
    Exit;
  // Freigabe der DataSource trennt den Link selbst (TDataSource.Destroy)
  FListLink.DataSource := Value;
  ListChanged;
  Changed(False);
end;

procedure TPPGDBGridColumn.SetKeyField(const Value: string);
begin
  if FKeyField <> Value then
  begin
    FKeyField := Value;
    ListChanged;
    Changed(False);
  end;
end;

procedure TPPGDBGridColumn.SetListField(const Value: string);
begin
  if FListField <> Value then
  begin
    FListField := Value;
    ListChanged;
    Changed(False);
  end;
end;

procedure TPPGDBGridColumn.ListChanged;
var
  G: TPPGCustomDBGrid;
  DS: TDataSet;
begin
  // Liste wird bearbeitet: alte Texte behalten, neu gelesen wird nach Post
  // bzw. Cancel (Lookup wuerde die offene Bearbeitung buchen)
  DS := ListDataSet;
  if (DS <> nil) and DS.Active and (DS.State in dsEditModes) then
    Exit;
  if FLookupCache <> nil then
    FLookupCache.Clear;
  // Waehrend ein PPGlow-Control die Liste liest, aendert sich nichts
  G := Grid;
  if (G <> nil) and not PPGDBReading then
    G.ListDataChanged;
end;

function TPPGDBGridColumn.IsLookup: Boolean;
begin
  // Ohne Datenmenge (auch waehrend die DataSource freigegeben wird) keine Liste
  Result := (ListDataSet <> nil) and (FKeyField <> '') and (FListField <> '');
end;

function TPPGDBGridColumn.ListDataSet: TDataSet;
begin
  Result := nil;
  if GetListSource <> nil then
    Result := GetListSource.DataSet;
end;

function TPPGDBGridColumn.ListResultField: string;
begin
  Result := Trim(PPGDBFirstValue(FListField));
end;

function TPPGDBGridColumn.LookupText(const Key: Variant): string;
var
  DS: TDataSet;
  K: string;
  V: Variant;
begin
  Result := '';
  if VarIsNull(Key) or VarIsEmpty(Key) or not IsLookup then
    Exit;
  DS := ListDataSet;
  if (DS = nil) or not DS.Active or (Pos(';', FKeyField) > 0) or
    (DS.FindField(ListResultField) = nil) then
    Exit;
  K := VarToStr(Key);
  if FLookupCache = nil then
    FLookupCache := TDictionary<string, string>.Create;
  if FLookupCache.TryGetValue(K, Result) then
    Exit;
  // Lookup (z.B. TClientDataSet) bucht eine offene Bearbeitung der Liste:
  // dann lieber leer anzeigen (nicht merken)
  if DS.State <> dsBrowse then
    Exit('');
  // Lookup bewegt den Satzzeiger der Liste nicht; die Klammer haelt
  // Meldungen anderer Datenmengen-Arten von den PPGlow-Links fern
  PPGDBBeginRead;
  try
    V := DS.Lookup(FKeyField, Key, ListResultField);
  finally
    PPGDBEndRead;
  end;
  if VarIsNull(V) or VarIsEmpty(V) then
    Result := ''
  else
    Result := VarToStr(V);
  FLookupCache.AddOrSetValue(K, Result);
end;

procedure TPPGDBGridColumn.Assign(Source: TPersistent);
begin
  if Source is TPPGDBGridColumn then
  begin
    FFieldName := TPPGDBGridColumn(Source).FFieldName;
    FFooterField := TPPGDBGridColumn(Source).FFooterField;
    FButtonStyle := TPPGDBGridColumn(Source).FButtonStyle;
    FValueChecked := TPPGDBGridColumn(Source).FValueChecked;
    FValueUnchecked := TPPGDBGridColumn(Source).FValueUnchecked;
    FKeyField := TPPGDBGridColumn(Source).FKeyField;
    FListField := TPPGDBGridColumn(Source).FListField;
    if FLookupCache <> nil then
      FLookupCache.Clear;
    if FListLink <> nil then
      FListLink.DataSource := TPPGDBGridColumn(Source).GetListSource;
  end;
  inherited Assign(Source);
  if Source is TPPGDBGridColumn then
    FAlignmentSet := TPPGDBGridColumn(Source).FAlignmentSet;
end;

function TPPGDBGridColumn.ShowsEllipsis: Boolean;
begin
  Result := FButtonStyle = cbsEllipsis;
end;

function TPPGDBGridColumn.GetAlignment: TAlignment;
begin
  Result := inherited Alignment;
end;

procedure TPPGDBGridColumn.SetAlignment(const Value: TAlignment);
begin
  FAlignmentSet := True;
  inherited Alignment := Value;
end;

procedure TPPGDBGridColumn.ApplyFieldAlignment(F: TField);
begin
  if not FAlignmentSet and (F <> nil) then
    inherited Alignment := F.Alignment;
end;

procedure TPPGDBGridColumn.SetFooterField(const Value: string);
begin
  if FFooterField <> Value then
  begin
    FFooterField := Value;
    Changed(False);
  end;
end;

function TPPGDBGridColumn.GetDisplayName: string;
begin
  if Title <> '' then
    Result := Title
  else if FFieldName <> '' then
    Result := FFieldName
  else
    Result := inherited GetDisplayName;
end;

procedure TPPGDBGridColumn.SetFieldName(const Value: string);
begin
  if FFieldName <> Value then
  begin
    FFieldName := Value;
    Changed(False);
  end;
end;

type
  TDataSetAccess = class(TDataSet);

/// Zum Lesezeichen gehen und den Satz wieder an dieselbe Stelle im Puffer
/// bringen (GotoBookmark mittet ihn sonst; die Anzeige wuerde springen).
/// Index = Pufferzeile der Datenmenge vorher (TDataSet.ActiveRecord).
procedure GotoBookmarkAt(DS: TDataSet; const Bm: TBookmark; Index: Integer);
var
  C, Moved: Integer;
begin
  DS.Bookmark := Bm;
  C := TDataSetAccess(DS).ActiveRecord;
  if C > Index then
  begin
    // Fenster nach unten schieben: ueber das Pufferende hinaus und zurueck
    Moved := DS.MoveBy(TDataSetAccess(DS).BufferCount - 1 - C + (C - Index));
    DS.MoveBy(-Moved);
  end
  else if C < Index then
  begin
    // Fenster nach oben schieben: ueber den Pufferanfang hinaus und zurueck
    Moved := DS.MoveBy(-Index);
    DS.MoveBy(-Moved);
  end;
end;

{ TPPGBookmarkList }

constructor TPPGBookmarkList.Create(AGrid: TPPGCustomDBGrid);
begin
  inherited Create;
  FGrid := AGrid;
  FList := TList<TBookmark>.Create;
end;

destructor TPPGBookmarkList.Destroy;
begin
  // Lesezeichen sind dynamische Arrays: die Liste gibt sie mit frei
  FList.Free;
  inherited Destroy;
end;

function TPPGBookmarkList.DataSet: TDataSet;
begin
  Result := nil;
  if (FGrid <> nil) and (FGrid.FDataLink <> nil) and FGrid.FDataLink.Active then
    Result := FGrid.FDataLink.DataSet;
end;

function TPPGBookmarkList.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TPPGBookmarkList.GetItem(Index: Integer): TBookmark;
begin
  if (Index < 0) or (Index >= FList.Count) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, FList.Count - 1]);
  Result := FList[Index];
end;

procedure TPPGBookmarkList.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TPPGBookmarkList.EndUpdate;
begin
  Dec(FUpdateCount);
  if (FUpdateCount = 0) and FChanged then
  begin
    FChanged := False;
    if FGrid <> nil then
      FGrid.SelectionChanged;
  end;
end;

procedure TPPGBookmarkList.Changed;
begin
  if FUpdateCount > 0 then
    FChanged := True
  else if FGrid <> nil then
    FGrid.SelectionChanged;
end;

procedure TPPGBookmarkList.SortList;
var
  DS: TDataSet;
begin
  DS := DataSet;
  if (DS = nil) or (FList.Count < 2) then
    Exit;
  FList.Sort(TComparer<TBookmark>.Construct(
    function(const A, B: TBookmark): Integer
    begin
      Result := DS.CompareBookmarks(A, B);
    end));
end;

procedure TPPGBookmarkList.EnsureOrder;
var
  DS: TDataSet;
  I: Integer;
begin
  // Nach DataSetChanged (anderer Index, Refresh) einmal pruefen, ob die
  // Reihenfolge noch zu CompareBookmarks passt; sonst neu sortieren
  if not FCheckOrder then
    Exit;
  FCheckOrder := False;
  DS := DataSet;
  if DS = nil then
    Exit;
  for I := 1 to FList.Count - 1 do
    if DS.CompareBookmarks(FList[I - 1], FList[I]) > 0 then
    begin
      SortList;
      Exit;
    end;
end;

function TPPGBookmarkList.Find(const Item: TBookmark; var Index: Integer): Boolean;
var
  DS: TDataSet;
  L, H, I, C: Integer;
begin
  // Binaere Suche wie TBookmarkList.Find
  Result := False;
  Index := 0;
  DS := DataSet;
  if (DS = nil) or (Length(Item) = 0) then
    Exit;
  EnsureOrder;
  L := 0;
  H := FList.Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    C := DS.CompareBookmarks(FList[I], Item);
    if C < 0 then
      L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Result := True;
        L := I;
      end;
    end;
  end;
  Index := L;
end;

function TPPGBookmarkList.IndexOf(const Item: TBookmark): Integer;
begin
  if not Find(Item, Result) then
    Result := -1;
end;

function TPPGBookmarkList.AddBookmark(const Item: TBookmark): Boolean;
var
  I: Integer;
begin
  // Nur mit dgMultiSelect (ohne Option bleibt die Liste leer, wie TDBGrid)
  Result := (FGrid <> nil) and FGrid.MultiSelectActive and (Length(Item) > 0) and
    not Find(Item, I);
  if Result then
  begin
    FList.Insert(I, Copy(Item));
    Changed;
  end;
end;

function TPPGBookmarkList.RemoveBookmark(const Item: TBookmark): Boolean;
var
  I: Integer;
begin
  Result := Find(Item, I);
  if Result then
  begin
    FList.Delete(I);
    Changed;
  end;
end;

function TPPGBookmarkList.CurrentBookmark: TBookmark;
var
  DS: TDataSet;
begin
  Result := nil;
  DS := DataSet;
  // Neuer, noch nicht gebuchter Satz hat kein Lesezeichen
  if (DS <> nil) and not DS.IsEmpty and (DS.State <> dsInsert) then
    Result := DS.Bookmark;
end;

function TPPGBookmarkList.GetCurrentRowSelected: Boolean;
var
  I: Integer;
begin
  Result := Find(CurrentBookmark, I);
end;

procedure TPPGBookmarkList.SetCurrentRowSelected(Value: Boolean);
var
  B: TBookmark;
begin
  B := CurrentBookmark;
  if Length(B) = 0 then
    Exit;
  if Value then
    AddBookmark(B)
  else
    RemoveBookmark(B);
end;

procedure TPPGBookmarkList.Clear;
begin
  if FList.Count = 0 then
    Exit;
  FList.Clear;
  Changed;
end;

procedure TPPGBookmarkList.SelectAll;
var
  DS: TDataSet;
  B: TBookmark;
  Pos: Integer;
begin
  DS := DataSet;
  if (DS = nil) or not FGrid.MultiSelectActive then
    Exit;
  // First wuerde eine offene Bearbeitung still buchen (wie EnsureSnapshot)
  if DS.State in dsEditModes then
    DS.CheckBrowseMode;
  Pos := TDataSetAccess(DS).ActiveRecord;
  PPGDBBeginRead;
  DS.DisableControls;
  try
    B := DS.Bookmark;
    try
      FList.Clear;
      DS.First;
      while not DS.Eof do
      begin
        FList.Add(DS.Bookmark);
        DS.Next;
      end;
    finally
      if (Length(B) > 0) and DS.BookmarkValid(B) then
        GotoBookmarkAt(DS, B, Pos);
    end;
  finally
    DS.EnableControls;
    PPGDBEndRead;
  end;
  // Reihenfolge der Datenmenge muss nicht die von CompareBookmarks sein
  SortList;
  FCheckOrder := False;
  Changed;
end;

procedure TPPGBookmarkList.Delete;
var
  DS: TDataSet;
  I: Integer;
begin
  DS := DataSet;
  if (DS = nil) or (FList.Count = 0) then
    Exit;
  DS.DisableControls;
  try
    // Von hinten: die uebrigen Lesezeichen bleiben gueltig
    for I := FList.Count - 1 downto 0 do
    begin
      if DS.BookmarkValid(FList[I]) then
      begin
        DS.Bookmark := FList[I];
        DS.Delete;
      end;
      FList.Delete(I);
    end;
  finally
    DS.EnableControls;
    Changed;
  end;
end;

function TPPGBookmarkList.Refresh: Boolean;
var
  DS: TDataSet;
  I, Pos: Integer;
  B: TBookmark;
begin
  Result := False;
  DS := DataSet;
  if DS = nil then
  begin
    Result := FList.Count > 0;
    FList.Clear;
  end
  else if FList.Count > 0 then
  begin
    // Ungueltige entfernen. Gueltige neu lesen: manche Datenmengen (z.B.
    // TClientDataSet) liefern nach einem Indexwechsel andere Lesezeichen fuer
    // denselben Satz; danach neu sortieren
    if DS.State in dsEditModes then
      DS.CheckBrowseMode;
    Pos := TDataSetAccess(DS).ActiveRecord;
    PPGDBBeginRead;
    DS.DisableControls;
    try
      B := DS.Bookmark;
      try
        for I := FList.Count - 1 downto 0 do
          if not DS.BookmarkValid(FList[I]) then
          begin
            FList.Delete(I);
            Result := True;
          end
          else
          begin
            DS.Bookmark := FList[I];
            FList[I] := DS.Bookmark;
          end;
      finally
        if (Length(B) > 0) and DS.BookmarkValid(B) then
          GotoBookmarkAt(DS, B, Pos);
      end;
    finally
      DS.EnableControls;
      PPGDBEndRead;
    end;
    SortList;
    FCheckOrder := False;
  end;
  if Result then
    Changed
  else if FGrid <> nil then
  begin
    // Markierungen der sichtbaren Zeilen mit den neuen Lesezeichen
    FGrid.UpdateMarks;
    FGrid.Invalidate;
  end;
end;

{ TPPGGridDataLink }

constructor TPPGGridDataLink.Create(AGrid: TPPGCustomDBGrid);
begin
  inherited Create;
  FGrid := AGrid;
  VisualControl := True;
end;

procedure TPPGGridDataLink.ActiveChanged;
begin
  if FGrid <> nil then
    FGrid.LinkActive(Active);
end;

procedure TPPGGridDataLink.DataSetChanged;
begin
  if FGrid = nil then
    Exit;
  // Sortierung der Datenmenge kann sich geaendert haben (Index, Refresh):
  // Reihenfolge der Lesezeichen vor der naechsten Suche pruefen
  if FGrid.FSelected <> nil then
    FGrid.FSelected.FCheckOrder := True;
  FGrid.DataChanged;
end;

procedure TPPGGridDataLink.DataSetScrolled(Distance: Integer);
begin
  if FGrid <> nil then
    FGrid.DataChanged;
end;

procedure TPPGGridDataLink.LayoutChanged;
begin
  if FGrid <> nil then
    FGrid.LayoutChanged;
  inherited LayoutChanged;
end;

procedure TPPGGridDataLink.EditingChanged;
begin
  if FGrid <> nil then
    FGrid.EditingChanged;
end;

procedure TPPGGridDataLink.RecordChanged(Field: TField);
begin
  if FGrid <> nil then
    FGrid.RecordChanged(Field);
end;

procedure TPPGGridDataLink.UpdateData;
begin
  if FGrid <> nil then
    FGrid.UpdateData;
end;

procedure TPPGGridDataLink.FocusControl(Field: TFieldRef);
var
  I: Integer;
begin
  // Datenmenge will ein Feld fokussieren (z.B. Pflichtfeld leer): Spalte waehlen
  if (FGrid = nil) or (Field = nil) or (Field^ = nil) then
    Exit;
  for I := 0 to FGrid.DataColCount - 1 do
    if FGrid.FFields[I] = Field^ then
    begin
      FGrid.Col := FGrid.FixedCols + I;
      if FGrid.CanFocus then
        FGrid.SetFocus;
      Field^ := nil;
      Exit;
    end;
end;

{ TPPGCustomDBGrid }

constructor TPPGCustomDBGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDBOptions := [dgEditing, dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines,
    dgTabs, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack];
  FAutoColumns := TPPGGridColumns.Create(Self, TPPGDBGridColumn);
  FAutoState := TPPGGridColumns.Create(nil, TPPGDBGridColumn);
  FExportMaxRecords := 100000;
  FDrawRow := -1;
  FDataLink := TPPGGridDataLink.Create(Self);
  FSelected := TPPGBookmarkList.Create(Self);
  // Sortieren ist Sache der Datenmenge
  SortOnHeaderClick := False;
  SetDBOptions(FDBOptions);
  FixedCols := 1;
  FixedRows := 1;
  ColCount := 2;
  RowCount := 2;
end;

destructor TPPGCustomDBGrid.Destroy;
begin
  if FDataLink <> nil then
    FDataLink.FGrid := nil;
  FreeAndNil(FDataLink);
  if FSelected <> nil then
    FSelected.FGrid := nil;
  FreeAndNil(FSelected);
  FAnchor := nil;
  FreeAndNil(FAutoColumns);
  FreeAndNil(FAutoState);
  inherited Destroy;
end;

procedure TPPGCustomDBGrid.SetShowRequired(const Value: Boolean);
begin
  if FShowRequired <> Value then
  begin
    FShowRequired := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomDBGrid.SetExportMaxRecords(const Value: Integer);
begin
  FExportMaxRecords := PPGCheckRange(Self, 'ExportMaxRecords', Value, 1, MaxInt);
end;

function TPPGCustomDBGrid.CreateColumns: TPPGGridColumns;
begin
  Result := TPPGGridColumns.Create(Self, TPPGDBGridColumn);
end;

procedure TPPGCustomDBGrid.Loaded;
begin
  inherited Loaded;
  BuildColumns;
end;

procedure TPPGCustomDBGrid.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FDataLink <> nil) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TPPGCustomDBGrid.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TPPGCustomDBGrid.SetDataSource(Value: TDataSource);
begin
  if Value = FDataLink.DataSource then
    Exit;
  FDataLink.DataSource := Value;
  if Value <> nil then
    Value.FreeNotification(Self);
  LinkActive(FDataLink.Active);
end;

procedure TPPGCustomDBGrid.SetDBOptions(const Value: TDBGridOptions);
var
  G: TGridOptions;
begin
  FDBOptions := Value;
  // Ohne Mehrfachauswahl keine ausgewaehlten Saetze (wie TDBGrid)
  if not (dgMultiSelect in Value) and (FSelected <> nil) then
  begin
    FAnchor := nil;
    FSelected.Clear;
  end;
  G := [goRangeSelect];
  if dgEditing in Value then
    Include(G, goEditing);
  if dgColLines in Value then
    G := G + [goVertLine, goFixedVertLine];
  if dgRowLines in Value then
    G := G + [goHorzLine, goFixedHorzLine];
  if dgColumnResize in Value then
    G := G + [goColSizing, goColMoving];
  if dgTabs in Value then
    Include(G, goTabs);
  if dgRowSelect in Value then
    G := G - [goRangeSelect] + [goRowSelect];
  if dgColumnResize in Value then
    Include(G, goColSizing);
  inherited Options := G;
  if not (csLoading in ComponentState) then
    BuildColumns;
end;

function TPPGCustomDBGrid.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FDataLink <> nil) and FDataLink.ExecuteAction(Action));
end;

function TPPGCustomDBGrid.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FDataLink <> nil) and FDataLink.UpdateAction(Action));
end;

procedure TPPGCustomDBGrid.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FDataLink);
end;

procedure TPPGCustomDBGrid.CMExit(var Message: TCMExit);
begin
  try
    HideEditor(True);
    // Leerer, unveraenderter neuer Datensatz verschwindet wieder (TDBGrid)
    if (dgCancelOnExit in FDBOptions) and FDataLink.Active and
      (FDataLink.DataSet.State = dsInsert) and not FDataLink.DataSet.Modified then
      FDataLink.DataSet.Cancel;
  except
    if CanFocus then
      SetFocus;
    raise;
  end;
  inherited;
end;

{ ---- Aufbau ---- }

function TPPGCustomDBGrid.DataRowHeight: Integer;
begin
  Result := PPGScale(DefaultRowHeight, ScalePPI);
  if Result < 1 then
    Result := 1;
end;

function TPPGCustomDBGrid.VisibleDataRows: Integer;
var
  V: TRect;
begin
  V := GridViewRect;
  Result := ((V.Bottom - V.Top) - FixedHeight) div DataRowHeight;
  if Result < 1 then
    Result := 1;
end;

function TPPGCustomDBGrid.DataColCount: Integer;
begin
  Result := Length(FFields);
end;

function TPPGCustomDBGrid.FieldOfCol(ACol: Integer): TField;
var
  I: Integer;
begin
  I := ACol - FixedCols;
  if (I >= 0) and (I < Length(FFields)) then
    Result := FFields[I]
  else
    Result := nil;
end;

function TPPGCustomDBGrid.GetFieldCount: Integer;
begin
  Result := Length(FFields);
end;

function TPPGCustomDBGrid.GetField(Index: Integer): TField;
begin
  if (Index >= 0) and (Index < Length(FFields)) then
    Result := FFields[Index]
  else
    Result := nil;
end;

function TPPGCustomDBGrid.GetSelectedField: TField;
begin
  Result := FieldOfCol(Col);
end;

procedure TPPGCustomDBGrid.BuildColumns;
var
  DS: TDataSet;
  I, N, W, K: Integer;
  Keep: TStringList;
  OldC: TPPGDBGridColumn;
  F: TField;
  C: TPPGDBGridColumn;
  CharW: Integer;
begin
  if FLayoutBusy or (csLoading in ComponentState) then
    Exit;
  FLayoutBusy := True;
  Keep := TStringList.Create;
  try
    // Titel und Indikator
    if dgIndicator in FDBOptions then
      N := 1
    else
      N := 0;
    SetLength(FFields, 0);
    DS := nil;
    if FDataLink.Active then
      DS := FDataLink.DataSet;
    if Columns.Count > 0 then
    begin
      SetLength(FFields, Columns.Count);
      for I := 0 to Columns.Count - 1 do
      begin
        if DS <> nil then
          FFields[I] := DS.FindField(TPPGDBGridColumn(Columns[I]).FieldName)
        else
          FFields[I] := nil;
        // Audit 4b: wie TDBGrid die Ausrichtung des Felds (nur zur Laufzeit)
        if not (csDesigning in ComponentState) then
          TPPGDBGridColumn(Columns[I]).ApplyFieldAlignment(FFields[I]);
      end;
    end
    else
    begin
      FAutoColumns.BeginUpdate;
      try
        // Position, Sichtbarkeit und Breite je Feld merken (Verschieben,
        // Ausblenden und Breite aendern bauen die Spalten neu auf)
        // (auch ueber eine geschlossene Datenmenge hinweg: FAutoState)
        if FAutoColumns.Count > 0 then
          FAutoState.Assign(FAutoColumns);
        Keep.Clear;
        for I := 0 to FAutoState.Count - 1 do
          Keep.Add(TPPGDBGridColumn(FAutoState.Items[I]).FieldName);
        FAutoColumns.Clear;
        if DS <> nil then
        begin
          // Breite aus DisplayWidth (Zeichen) in logischen Pixeln
          CharW := 7;
          for I := 0 to DS.FieldCount - 1 do
          begin
            F := DS.Fields[I];
            if not F.Visible then
              Continue;
            SetLength(FFields, Length(FFields) + 1);
            FFields[High(FFields)] := F;
            C := TPPGDBGridColumn(FAutoColumns.Add);
            C.FieldName := F.FieldName;
            C.Title := F.DisplayLabel;
            C.ApplyFieldAlignment(F);
            C.ReadOnly := F.ReadOnly;
            W := F.DisplayWidth * CharW + 12;
            if W < 32 then
              W := 32;
            if W > 400 then
              W := 400;
            C.Width := W;
            if F.DataType = ftBoolean then
              C.EditorKind := gekCheck;
            K := Keep.IndexOf(F.FieldName);
            if K >= 0 then
            begin
              OldC := TPPGDBGridColumn(FAutoState.Items[K]);
              C.DisplayIndex := OldC.DisplayIndex;
              C.Visible := OldC.Visible;
              C.Width := OldC.Width;
              C.Band := OldC.Band;
              C.FooterField := OldC.FooterField;
            end;
          end;
        end;
      finally
        FAutoColumns.EndUpdate;
      end;
    end;
    if Length(FFields) = 0 then
      ColCount := N + 1
    else
      ColCount := N + Length(FFields);
    FixedCols := N;
    if dgTitles in FDBOptions then
    begin
      // Leere/inaktive Datenmenge: RowCount = 1, FixedRows = 1 waere ungueltig
      if RowCount < 2 then
        RowCount := 2;
      FixedRows := 1;
    end
    else
      FixedRows := 0;
    if Col < FixedCols then
      Col := FixedCols;
  finally
    Keep.Free;
    FLayoutBusy := False;
  end;
  UpdateBufferCount;
  DataChanged;
end;

procedure TPPGCustomDBGrid.UpdateBufferCount;
begin
  if FDataLink.Active then
    FDataLink.BufferCount := VisibleDataRows;
end;

procedure TPPGCustomDBGrid.RebuildCache;
var
  R, C, N, Old: Integer;
  F: TField;
begin
  if not FDataLink.Active then
  begin
    SetLength(FCache, 0);
    SetLength(FMarks, 0);
    SetLength(FRowBms, 0);
    Exit;
  end;
  N := FDataLink.RecordCount;
  SetLength(FCache, N);
  // Lesezeichen je Zeile fuer die Markierung der Mehrfachauswahl: so muss
  // UpdateMarks den Satzzeiger nie bewegen (auch nicht bei DisableControls)
  if dgMultiSelect in FDBOptions then
    SetLength(FRowBms, N)
  else
    SetLength(FRowBms, 0);
  Old := FDataLink.ActiveRecord;
  try
    for R := 0 to N - 1 do
    begin
      FDataLink.ActiveRecord := R;
      if R < Length(FRowBms) then
        FRowBms[R] := FDataLink.DataSet.Bookmark; // leer bei neuem Satz
      SetLength(FCache[R], Length(FFields));
      for C := 0 to High(FFields) do
      begin
        F := FFields[C];
        // Kaestchen: 1/0, grau = PPGGridCheckGrayed; Nachschlage-Spalte: Text
        // aus der Liste; sonst DisplayText
        FCache[R][C] := FieldCellText(FixedCols + C, F);
      end;
    end;
  finally
    FDataLink.ActiveRecord := Old;
  end;
  UpdateMarks;
end;

{ ---- Mehrfachauswahl ---- }

function TPPGCustomDBGrid.MultiSelectActive: Boolean;
begin
  Result := (dgMultiSelect in FDBOptions) and FDataLink.Active and (FSelected <> nil);
end;

procedure TPPGCustomDBGrid.UpdateMarks;
var
  R: Integer;
begin
  if not FDataLink.Active or (FSelected = nil) or (FSelected.Count = 0) then
  begin
    SetLength(FMarks, 0);
    Exit;
  end;
  // Nur Lesezeichen vergleichen (aus RebuildCache), kein Satzwechsel
  SetLength(FMarks, Length(FRowBms));
  for R := 0 to High(FRowBms) do
    FMarks[R] := (Length(FRowBms[R]) > 0) and (FSelected.IndexOf(FRowBms[R]) >= 0);
end;

function TPPGCustomDBGrid.RowMarked(ARow: Integer): Boolean;
var
  R: Integer;
begin
  // Paint: nur der Zwischenspeicher (UpdateMarks)
  R := ARow - FixedRows;
  Result := (R >= 0) and (R < Length(FMarks)) and FMarks[R];
end;

procedure TPPGCustomDBGrid.SelectionChanged;
begin
  if csDestroying in ComponentState then
    Exit;
  // Leere Auswahl: der naechste Bereich beginnt am dann aktiven Satz
  if FSelected.Count = 0 then
    FAnchor := nil;
  UpdateMarks;
  Invalidate;
  if Assigned(FOnSelectionChanged) then
    FOnSelectionChanged(Self);
end;

function TPPGCustomDBGrid.ConfirmDeleteSelected(ACount: Integer): Boolean;
begin
  Result := MessageDlg(Format(PPGStr(@SPPGDBGridConfirmDeleteSelected), [ACount]),
    mtConfirmation, [mbOK, mbCancel], 0) = mrOK;
end;

procedure TPPGCustomDBGrid.SelectRangeTo(const FromBm: TBookmark);
var
  DS: TDataSet;
  Cur: TBookmark;
  Found: TList<TBookmark>;
  I, Pos: Integer;

  function Walk(Forward: Boolean): Boolean;
  begin
    // Vom Anker in eine Richtung bis zum aktiven Satz; False = nicht erreicht
    Result := False;
    Found.Clear;
    DS.Bookmark := FromBm;
    while True do
    begin
      Found.Add(DS.Bookmark);
      if DS.CompareBookmarks(DS.Bookmark, Cur) = 0 then
      begin
        Result := True;
        Exit;
      end;
      if Forward then
        DS.Next
      else
        DS.Prior;
      if (Forward and DS.Eof) or (not Forward and DS.Bof) then
        Exit;
    end;
  end;

begin
  if not MultiSelectActive then
    Exit;
  DS := FDataLink.DataSet;
  Cur := FSelected.CurrentBookmark;
  if Length(Cur) = 0 then
    Exit;
  if (Length(FromBm) = 0) or not DS.BookmarkValid(FromBm) then
  begin
    FSelected.AddBookmark(Cur);
    Exit;
  end;
  Pos := TDataSetAccess(DS).ActiveRecord;
  Found := TList<TBookmark>.Create;
  try
    PPGDBBeginRead;
    DS.DisableControls;
    try
      try
        // Richtung nach CompareBookmarks raten, sonst die andere versuchen
        if DS.CompareBookmarks(FromBm, Cur) <= 0 then
        begin
          if not Walk(True) and not Walk(False) then
            Found.Clear;
        end
        else if not Walk(False) and not Walk(True) then
          Found.Clear;
      finally
        GotoBookmarkAt(DS, Cur, Pos);
      end;
    finally
      DS.EnableControls;
      PPGDBEndRead;
    end;
    FSelected.BeginUpdate;
    try
      for I := 0 to Found.Count - 1 do
        FSelected.AddBookmark(Found[I]);
      FSelected.AddBookmark(Cur);
    finally
      FSelected.EndUpdate;
    end;
  finally
    Found.Free;
  end;
end;

procedure TPPGCustomDBGrid.ExtendByStep(const OldBm: TBookmark);
var
  NewBm: TBookmark;
  DS: TDataSet;
begin
  // Wie TDBGrid: vom Anker weg kommt der neue Satz dazu, zum Anker hin
  // faellt der verlassene Satz heraus
  DS := FDataLink.DataSet;
  NewBm := FSelected.CurrentBookmark;
  if Length(FAnchor) = 0 then
    FAnchor := OldBm;
  if Length(NewBm) = 0 then
    Exit;
  FSelected.BeginUpdate;
  try
    if (Length(OldBm) = 0) or (DS.CompareBookmarks(OldBm, NewBm) = 0) then
      FSelected.AddBookmark(NewBm)
    else if (FSelected.IndexOf(NewBm) >= 0) and (Length(FAnchor) > 0) and
      (DS.CompareBookmarks(OldBm, FAnchor) <> 0) then
      FSelected.RemoveBookmark(OldBm)
    else
    begin
      FSelected.AddBookmark(OldBm);
      FSelected.AddBookmark(NewBm);
    end;
  finally
    FSelected.EndUpdate;
  end;
end;

procedure TPPGCustomDBGrid.ContentMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  C, V, R: Integer;
  OnRow: Boolean;
  OldBm: TBookmark;
  BaseShift: TShiftState;
begin
  OnRow := MultiSelectActive and (Button = mbLeft) and not (ssDouble in Shift) and
    (SizingColAt(X, Y) < 0) and MouseCoord(X, Y, C, V) and (DataRow(V) >= FixedRows) and
    (DataRow(V) - FixedRows < FDataLink.RecordCount);
  if not OnRow then
  begin
    inherited ContentMouseDown(Button, Shift, X, Y);
    Exit;
  end;
  OldBm := FSelected.CurrentBookmark;
  R := DataRow(V) - FixedRows;
  // Umschalt waehlt hier Datensaetze, keinen Zellbereich; Strg statt Umschalt
  // haelt die Basis auch davon ab, ein Kaestchen per Klick umzuschalten
  BaseShift := Shift;
  if ssShift in BaseShift then
    BaseShift := BaseShift - [ssShift] + [ssCtrl];
  inherited ContentMouseDown(Button, BaseShift, X, Y);
  if not MultiSelectActive then
    Exit;
  // Klick in den Indikator: Datensatz wechseln wie TDBGrid
  if (C < FixedCols) and (R <> FDataLink.ActiveRecord) then
    FDataLink.MoveBy(R - FDataLink.ActiveRecord);
  // Wechsel abgelehnt (z.B. Pflichtfeld beim Buchen): Auswahl bleibt
  if not MultiSelectActive or (FDataLink.ActiveRecord <> R) then
    Exit;
  if ssShift in Shift then
  begin
    if Length(FAnchor) = 0 then
      FAnchor := OldBm;
    FSelected.BeginUpdate;
    try
      if not (ssCtrl in Shift) then
        FSelected.Clear;
      SelectRangeTo(FAnchor);
    finally
      FSelected.EndUpdate;
    end;
  end
  else if ssCtrl in Shift then
  begin
    FSelected.CurrentRowSelected := not FSelected.CurrentRowSelected;
    FAnchor := FSelected.CurrentBookmark;
  end
  else
  begin
    // Wie TDBGrid: Auswahl aufheben, angeklickten Satz waehlen
    FSelected.BeginUpdate;
    try
      FSelected.Clear;
      FSelected.CurrentRowSelected := True;
    finally
      FSelected.EndUpdate;
    end;
    FAnchor := FSelected.CurrentBookmark;
  end;
end;

procedure TPPGCustomDBGrid.SyncPosition;
var
  DS: TDataSet;
  RowH, Top, MaxY, Target: Integer;
begin
  if not FDataLink.Active then
    Exit;
  DS := FDataLink.DataSet;
  Inc(FSyncing);
  try
    // Fokus auf die aktive Zeile des Puffers
    if FixedRows + FDataLink.ActiveRecord < RowCount then
      MoveFocus(FocusCol, VisualRow(FixedRows + FDataLink.ActiveRecord), False, False);
    // Leiste auf die Lage in der Datenmenge (Inhaltshoehe zuerst neu)
    InvalidateGeometry;
    EnsureGeometry;
    RowH := DataRowHeight;
    MaxY := MaxScroll(saVert);
    if DS.IsSequenced and (DS.RecNo > 0) then
    begin
      Top := DS.RecNo - 1 - FDataLink.ActiveRecord;
      if Top < 0 then
        Top := 0;
      Target := Top * RowH;
    end
    else if DS.Bof then
      Target := 0
    else if DS.Eof then
      Target := MaxY
    else
      Target := MaxY div 2;
    if Target > MaxY then
      Target := MaxY;
    if ScrollY <> Target then
      ScrollTo(ScrollX, Target);
  finally
    Dec(FSyncing);
  end;
end;

{ ---- Ereignisse des DataLinks ---- }

procedure TPPGCustomDBGrid.LinkActive(Value: Boolean);
begin
  if (csDestroying in ComponentState) then
    Exit;
  // Lesezeichen gehoeren zur alten Datenmenge bzw. zum alten Oeffnen
  FAnchor := nil;
  if FSelected <> nil then
  begin
    FSelected.FCheckOrder := False;
    FSelected.Clear;
  end;
  HideEditor(False);
  BuildColumns;
end;

procedure TPPGCustomDBGrid.LayoutChanged;
begin
  if not (csDestroying in ComponentState) then
    BuildColumns;
end;

procedure TPPGCustomDBGrid.DataChanged;
var
  N: Integer;
begin
  FSnapValid := False;
  if (csDestroying in ComponentState) or FLayoutBusy then
    Exit;
  // Anderer Datensatz (Navigator, Code, Blaettern ueber den Puffer hinaus):
  // der offene Editor gehoert zum alten und wird verworfen
  if EditorMode and (Length(FEditBm) > 0) and FDataLink.Active and
    (FDataLink.DataSet.State = dsBrowse) and
    (FDataLink.DataSet.CompareBookmarks(FEditBm, FDataLink.DataSet.Bookmark) <> 0) then
    HideEditor(False);
  if not EditorMode then
    FEditBm := nil;
  RebuildCache;
  // Mindestens eine (ggf. leere) Datenzeile: RowCount > FixedRows
  N := Length(FCache);
  if N < 1 then
    N := 1;
  if RowCount <> FixedRows + N then
    RowCount := FixedRows + N;
  SyncPosition;
  Invalidate;
end;

procedure TPPGCustomDBGrid.EditingChanged;
begin
  Invalidate;
end;

procedure TPPGCustomDBGrid.RecordChanged(Field: TField);
begin
  if csDestroying in ComponentState then
    Exit;
  // Nur der aktive Datensatz hat sich geaendert: Zwischenspeicher neu
  RebuildCache;
  Invalidate;
end;

procedure TPPGCustomDBGrid.UpdateData;
begin
  // Datenmenge schreibt (Post): offenen Editor uebernehmen
  if EditorMode then
    HideEditor(True);
end;

{ ---- Erweiterungspunkte des Grids ---- }

function TPPGCustomDBGrid.CanGroup: Boolean;
begin
  // Kein Gruppieren im DB-Grid (Phase 13: Datenmenge bleibt die Quelle)
  Result := False;
end;

function TPPGCustomDBGrid.ColumnKey(ACol: Integer): string;
var
  C: TPPGGridColumn;
begin
  // Layout ueber Feldnamen: bleibt gueltig, wenn sich die Felder verschieben
  C := ColumnOf(ACol);
  if (C is TPPGDBGridColumn) and (TPPGDBGridColumn(C).FieldName <> '') then
    Result := TPPGDBGridColumn(C).FieldName
  else
    Result := inherited ColumnKey(ACol);
end;

function TPPGCustomDBGrid.ColumnOf(ACol: Integer): TPPGGridColumn;
var
  I: Integer;
begin
  Result := nil;
  I := ACol - FixedCols;
  if I < 0 then
    Exit;
  if Columns.Count > 0 then
  begin
    if I < Columns.Count then
      Result := Columns[I];
  end
  else if (FAutoColumns <> nil) and (I < FAutoColumns.Count) then
    Result := FAutoColumns[I];
end;

function TPPGCustomDBGrid.KindOf(ACol: Integer): IPPGCellKind;
begin
  // Boolean-Felder als Kaestchen, auch in eigenen Columns ohne EditorKind
  Result := inherited KindOf(ACol);
  if (Result = nil) and IsCheckColumn(ACol) then
    Result := PPGCellKind(ckCheck);
end;

function TPPGCustomDBGrid.ColumnCollection: TPPGGridColumns;
begin
  if Columns.Count > 0 then
    Result := Columns
  else
    Result := FAutoColumns;
end;

function TPPGCustomDBGrid.CachedFooterText(ACol: Integer): string;
var
  C: TPPGGridColumn;
  F: TField;
begin
  // Summen liefert die Datenmenge (TAggregateField) oder das Ereignis
  Result := '';
  C := ColumnOf(ACol);
  if not (C is TPPGDBGridColumn) then
    Exit;
  if (TPPGDBGridColumn(C).FooterField <> '') and FDataLink.Active then
  begin
    F := FDataLink.DataSet.FindField(TPPGDBGridColumn(C).FooterField);
    if F <> nil then
    try
      Result := F.DisplayText;
    except
      // Aggregate noch nicht bereit (AggregatesActive = False): leer lassen.
      // Nur Datenbankfehler; alles andere (z. B. Zugriffsverletzung) ist ein
      // echter Fehler und darf nicht verschwinden.
      on E: EDatabaseError do
        Result := '';
    end;
  end;
  if Assigned(FOnGetFooterText) then
    FOnGetFooterText(Self, TPPGDBGridColumn(C), Result);
end;

procedure TPPGCustomDBGrid.EnsureSnapshot;
var
  DS: TDataSet;
  BM: TBookmark;
  N, C, Cols, DC: Integer;
  F: TField;
  St: TCheckBoxState;
begin
  if FSnapValid then
    Exit;
  FSnap := nil;
  FSnapText := nil;
  if not FDataLink.Active then
  begin
    FSnapValid := True;
    Exit;
  end;
  DS := FDataLink.DataSet;
  // First wuerde eine offene Bearbeitung still buchen (CheckBrowseMode)
  if DS.State in dsEditModes then
    raise EPPGError.Create(PPGStr(@SPPGDBEditPending));
  Cols := TableColCount;
  // Einmal durch die Datenmenge (Muster aus PPG.DB.Chart): ohne Anzeige-
  // Aktualisierung, Position danach wieder herstellen
  // Andere PPGlow-Controls an derselben Datenmenge (Diagramm, Planer ...)
  // sollen das EnableControls am Ende nicht als Aenderung werten
  PPGDBBeginRead;
  DS.DisableControls;
  BM := DS.GetBookmark;
  try
    DS.First;
    N := 0;
    while not DS.Eof and (N < FExportMaxRecords) do
    begin
      // geometrisch wachsen statt je Zeile neu anlegen
      if N >= Length(FSnap) then
      begin
        SetLength(FSnap, Max(16, Length(FSnap) * 2));
        SetLength(FSnapText, Length(FSnap));
      end;
      SetLength(FSnap[N], Cols);
      SetLength(FSnapText[N], Cols);
      for C := 0 to Cols - 1 do
      begin
        DC := DataCol(C + FixedCols);
        F := FieldOfCol(DC);
        if (F = nil) or F.IsNull then
        begin
          FSnap[N][C] := Null;
          FSnapText[N][C] := '';
        end
        else if IsCheckColumn(DC) then
        begin
          // Kaestchen: Wahrheitswert; Text bei Boolean wie bisher DisplayText,
          // sonst 1/0 bzw. grau (Druck zeichnet daraus das Kaestchen)
          St := FieldCheckState(F, ColumnOf(DC));
          if St = cbGrayed then
            FSnap[N][C] := Null
          else
            FSnap[N][C] := St = cbChecked;
          if F.DataType = ftBoolean then
            FSnapText[N][C] := F.DisplayText
          else
            FSnapText[N][C] := CheckStateText(St);
        end
        else if ColumnLookup(DC) <> nil then
        begin
          FSnapText[N][C] := FieldCellText(DC, F);
          if FSnapText[N][C] = '' then
            FSnap[N][C] := Null
          else
            FSnap[N][C] := FSnapText[N][C];
        end
        else
        begin
          FSnapText[N][C] := F.DisplayText;
          if F.DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] then
            FSnap[N][C] := VarFromDateTime(F.AsDateTime)
          else if F.DataType = ftBoolean then
            FSnap[N][C] := F.AsBoolean
          else if F.DataType = ftLargeint then
            FSnap[N][C] := F.AsLargeInt // exakt, AsFloat rundet ab 2^53
          else if F.DataType in [ftSmallint, ftInteger, ftWord, ftFloat, ftCurrency, ftBCD,
            ftFMTBcd, ftAutoInc, ftShortint, ftByte, ftLongWord, ftExtended,
            ftSingle] then
            FSnap[N][C] := F.AsFloat
          else
            FSnap[N][C] := F.DisplayText;
        end;
      end;
      Inc(N);
      DS.Next;
    end;
    SetLength(FSnap, N);
    SetLength(FSnapText, N);
  finally
    if DS.BookmarkValid(BM) then
      DS.GotoBookmark(BM);
    DS.FreeBookmark(BM);
    DS.EnableControls; // loest DataChanged aus (verwirft den Schnappschuss) ...
    PPGDBEndRead;
  end;
  FSnapValid := True; // ... deshalb erst danach gueltig
end;

function TPPGCustomDBGrid.TableColCount: Integer;
begin
  // ohne Indikator
  Result := VisibleColCount - FixedCols;
  if Result < 0 then
    Result := 0;
end;

function TPPGCustomDBGrid.TableRowCount: Integer;
begin
  EnsureSnapshot;
  Result := Length(FSnap);
end;

function TPPGCustomDBGrid.TableColumn(ACol: Integer): TPPGTableColumnInfo;
begin
  Result := inherited TableColumn(ACol + FixedCols);
end;

function TPPGCustomDBGrid.TableCellText(ACol, ARow: Integer): string;
begin
  EnsureSnapshot;
  if (ARow >= 0) and (ARow < Length(FSnapText)) and (ACol >= 0) and (ACol < Length(FSnapText[ARow])) then
    Result := FSnapText[ARow][ACol]
  else
    Result := '';
end;

function TPPGCustomDBGrid.TableCellValue(ACol, ARow: Integer): Variant;
begin
  EnsureSnapshot;
  if (ARow >= 0) and (ARow < Length(FSnap)) and (ACol >= 0) and (ACol < Length(FSnap[ARow])) then
    Result := FSnap[ARow][ACol]
  else
    Result := Null;
end;

function TPPGCustomDBGrid.PrintCellStyle(ACol, ARow: Integer; const Text: string): TPPGGridCellStyle;
begin
  // Bedingte Formate je Feld; OnGetCellStyle bekommt die Satznummer (0-basiert)
  Result.Reset;
  if ConditionalFormats.Count > 0 then
    ConditionalFormats.Apply(DataCol(ACol + FixedCols), Text, Tokens, clWhite, Result);
  if Assigned(OnGetCellStyle) then
    OnGetCellStyle(Self, DataCol(ACol + FixedCols), ARow, Result);
end;

function TPPGCustomDBGrid.PrintCellKind(ACol: Integer; out Ctx: TPPGCellKindContext): IPPGCellKind;
begin
  Result := inherited PrintCellKind(ACol + FixedCols, Ctx);
end;

function TPPGCustomDBGrid.ExportAggregate(ACol: Integer): TPPGGridAggregate;
begin
  Result := agNone; // Summen rechnet die Datenmenge
end;

function TPPGCustomDBGrid.ExportMerges: TArray<TRect>;
begin
  SetLength(Result, 0);
end;

function TPPGCustomDBGrid.ExportOutline: TArray<TPPGOutlineRow>;
begin
  SetLength(Result, 0);
end;

function TPPGCustomDBGrid.ExportColumnLook(ACol: Integer): TPPGTableColumnLook;
begin
  // Kaestchen-Spalten (Boolean-Felder ...) als Kaestchen (wie KindOf)
  Result := inherited ExportColumnLook(ACol);
  if (Result.Kind = ckText) and IsCheckColumn(TableDataCol(ACol)) then
    Result.Kind := ckCheck;
end;

function TPPGCustomDBGrid.TableDataCol(ACol: Integer): Integer;
begin
  // ohne Indikator
  Result := DataCol(ACol + FixedCols);
end;

function TPPGCustomDBGrid.TableStyleRow(ARow: Integer): Integer;
begin
  // OnGetCellStyle bekommt die Satznummer (0-basiert), wie beim Druck
  Result := ARow;
end;

procedure TPPGCustomDBGrid.ColumnsChanged;
begin
  // Persistente Spalten geaendert: Felder neu zuordnen
  FontsChanged; // Spaltenstile koennen eigene Schriften haben (Audit 8c #10)
  if not (csLoading in ComponentState) and not FLayoutBusy then
    BuildColumns;
  RebuildColumnMap;
  InvalidateGeometry;
  Invalidate;
end;

function TPPGCustomDBGrid.RowScrollY: Integer;
begin
  // Der Puffer steht immer oben; die Leiste gehoert der Datenmenge
  Result := 0;
end;

function TPPGCustomDBGrid.RowsContentHeight: Integer;
var
  DS: TDataSet;
  N: Int64;
  V: TRect;
begin
  V := GridViewRect;
  Result := V.Bottom - V.Top;
  if not FDataLink.Active then
    Exit;
  DS := FDataLink.DataSet;
  if DS.IsSequenced and (DS.RecordCount > 0) then
  begin
    N := Int64(FixedHeight) + Int64(DS.RecordCount) * DataRowHeight;
    if N > MaxInt then
      N := MaxInt;
    if N > Result then
      Result := Integer(N);
  end
  else if not (DS.Bof and DS.Eof) then
    Result := Result + ThreeStateRows * DataRowHeight;
end;

procedure TPPGCustomDBGrid.ScrollCellsTo(X, Y: Integer);
begin
  // Nur waagerecht: senkrecht bewegt sich die Datenmenge
  ScrollTo(X, ScrollY);
end;

procedure TPPGCustomDBGrid.Scrolled;
var
  DS: TDataSet;
  RowH, Wanted, Top, Delta: Integer;
begin
  inherited Scrolled;
  if (FSyncing > 0) or not FDataLink.Active then
    Exit;
  DS := FDataLink.DataSet;
  RowH := DataRowHeight;
  Inc(FSyncing);
  try
    if DS.IsSequenced and (DS.RecNo > 0) then
    begin
      Wanted := ScrollY div RowH;
      Top := DS.RecNo - 1 - FDataLink.ActiveRecord;
      Delta := Wanted - Top;
      if Delta = 0 then
        Exit;
      // Grosse Spruenge (Daumen gezogen) direkt, kleine (Mausrad) schrittweise
      if Abs(Delta) > FDataLink.BufferCount then
        DS.RecNo := Min(DS.RecordCount, Wanted + 1 + FDataLink.ActiveRecord)
      else
        FDataLink.MoveBy(Delta);
    end
    else if ScrollY = 0 then
      DS.First
    else if ScrollY >= MaxScroll(saVert) then
      DS.Last
    else if ScrollY > MaxScroll(saVert) div 2 then
      FDataLink.MoveBy(FDataLink.BufferCount)
    else
      FDataLink.MoveBy(-FDataLink.BufferCount);
  finally
    Dec(FSyncing);
  end;
  SyncPosition;
end;

procedure TPPGCustomDBGrid.Resize;
begin
  inherited Resize;
  if not (csLoading in ComponentState) and (FDataLink <> nil) then
  begin
    UpdateBufferCount;
    DataChanged;
  end;
end;

function TPPGCustomDBGrid.GetCellText(ACol, ARow: Integer): string;
var
  C: TPPGGridColumn;
  F: TField;
  R: Integer;
begin
  Result := '';
  if ARow < FixedRows then
  begin
    // Titel
    if ACol < FixedCols then
      Exit;
    C := ColumnOf(ACol);
    F := FieldOfCol(ACol);
    if (C <> nil) and (C.Title <> '') then
      Result := C.Title
    else if F <> nil then
      Result := F.DisplayLabel;
    if FShowRequired and (F <> nil) and F.Required then
      Result := Result + ' *';
    Exit;
  end;
  R := ARow - FixedRows;
  if ACol < FixedCols then
  begin
    // Indikator: Datensatzzeiger und Zustand
    if FDataLink.Active and (R = FDataLink.ActiveRecord) and (R < Length(FCache)) then
      case FDataLink.DataSet.State of
        dsEdit: Result := IndEdit;
        dsInsert: Result := IndInsert;
      else
        Result := IndBrowse;
      end
    else if (R >= 0) and (R < Length(FMarks)) and FMarks[R] then
      Result := IndSelected;
    Exit;
  end;
  if (R >= 0) and (R < Length(FCache)) and (ACol - FixedCols < Length(FCache[R])) then
    Result := FCache[R][ACol - FixedCols];
end;

function TPPGCustomDBGrid.GetEditText(ACol, ARow: Integer): string;
var
  F: TField;
begin
  // Der Editor bearbeitet den aktiven Datensatz: Field.Text (Bearbeitungsformat)
  F := FieldOfCol(ACol);
  if (F <> nil) and FDataLink.Active and (ARow - FixedRows = FDataLink.ActiveRecord) and
    not IsCheckColumn(ACol) and (ColumnLookup(ACol) = nil) then
    Result := F.Text
  else
    Result := GetCellText(ACol, ARow);
end;

function TPPGCustomDBGrid.CanEditCell(ACol, VRow: Integer): Boolean;
var
  F: TField;
  C: TPPGDBGridColumn;
  L: TDataSet;
begin
  F := FieldOfCol(ACol);
  Result := not FReadOnly and (dgEditing in FDBOptions) and FDataLink.Active and
    not FDataLink.ReadOnly and FDataLink.DataSet.CanModify and (F <> nil) and
    FieldEditable(F) and (VRow - VisualRow(FixedRows) < Length(FCache)) and
    inherited CanEditCell(ACol, VRow);
  if Result then
  begin
    // Nachschlage-Spalte: nur mit offener Liste und einem Schluesselfeld
    C := ColumnLookup(ACol);
    if C <> nil then
    begin
      L := C.ListDataSet;
      Result := (L <> nil) and L.Active and (Pos(';', C.KeyField) = 0);
    end;
  end;
end;

/// Nachschlagefeld mit einem Schluesselfeld (Mehrfachschluessel: nur lesen).
function LookupKeyField(F: TField): TField;
begin
  Result := nil;
  if (F = nil) or (F.FieldKind <> fkLookup) or (Pos(';', F.KeyFields) > 0) or
    (F.LookupDataSet = nil) or (F.DataSet = nil) then
    Exit;
  Result := F.DataSet.FindField(F.KeyFields);
end;

function TPPGCustomDBGrid.FieldEditable(F: TField): Boolean;
var
  K: TField;
begin
  // Nachschlagefeld: aenderbar ueber sein Schluesselfeld (wie TDBGrid)
  if F.FieldKind = fkLookup then
  begin
    K := LookupKeyField(F);
    Result := (K <> nil) and K.CanModify and F.LookupDataSet.Active;
  end
  else
    Result := F.CanModify;
end;

function TPPGCustomDBGrid.CellEditorKind(ACol, ARow: Integer): TPPGGridEditorKind;
var
  C: TPPGGridColumn;
  L: TDataSet;
  LK, LR: string;
  T: TField;
begin
  Result := inherited CellEditorKind(ACol, ARow);
  // Kaestchen-Spalte (auch Boolean-Feld in einer eigenen Spalte ohne EditorKind)
  if IsCheckColumn(ACol) then
    Exit(gekCheck);
  // ButtonStyle cbsEllipsis/cbsNone: Textfeld statt Auswahlliste
  C := ColumnOf(ACol);
  if (C is TPPGDBGridColumn) and (TPPGDBGridColumn(C).ButtonStyle <> cbsAuto) then
  begin
    if Result = gekCombo then
      Result := gekText;
    Exit;
  end;
  // Nachschlagefeld bzw. -Spalte: Auswahl aus der Liste statt Freitext
  if (Result = gekText) and LookupSource(ACol, L, LK, LR, T) then
    Result := gekCombo;
end;

function TPPGCustomDBGrid.ColumnLookup(ACol: Integer): TPPGDBGridColumn;
var
  C: TPPGGridColumn;
  F: TField;
begin
  // Spalte mit ListSource/KeyField/ListField an einem gewoehnlichen Feld
  Result := nil;
  C := ColumnOf(ACol);
  if not (C is TPPGDBGridColumn) or not TPPGDBGridColumn(C).IsLookup then
    Exit;
  F := FieldOfCol(ACol);
  if (F <> nil) and (F.FieldKind <> fkLookup) then
    Result := TPPGDBGridColumn(C);
end;

function TPPGCustomDBGrid.LookupSource(ACol: Integer; out ListDS: TDataSet; out ListKey,
  ListResult: string; out Target: TField): Boolean;
var
  F: TField;
  C: TPPGDBGridColumn;
begin
  ListDS := nil;
  ListKey := '';
  ListResult := '';
  Target := nil;
  F := FieldOfCol(ACol);
  if F = nil then
    Exit(False);
  if F.FieldKind = fkLookup then
  begin
    Target := LookupKeyField(F);
    if Target <> nil then
    begin
      ListDS := F.LookupDataSet;
      ListKey := F.LookupKeyFields;
      ListResult := F.LookupResultField;
    end;
  end
  else
  begin
    C := ColumnLookup(ACol);
    if (C <> nil) and (Pos(';', C.KeyField) = 0) then
    begin
      ListDS := C.ListDataSet;
      ListKey := C.KeyField;
      ListResult := C.ListResultField;
      Target := F;
    end;
  end;
  Result := ListDS <> nil;
end;

function TPPGCustomDBGrid.IsCheckColumn(ACol: Integer): Boolean;
var
  F: TField;
  C: TPPGGridColumn;
begin
  F := FieldOfCol(ACol);
  if F = nil then
    Exit(False);
  if F.DataType = ftBoolean then
    Exit(True);
  C := ColumnOf(ACol);
  Result := (C <> nil) and ((C.EditorKind = gekCheck) or (C.CellKind = ckCheck));
end;

function TPPGCustomDBGrid.FieldCheckState(F: TField; C: TPPGGridColumn): TCheckBoxState;
var
  S, VC, VU: string;
  On: Boolean;
begin
  // Wie TDBCheckBox: Null = grau; Boolean nach AsBoolean; sonst Field.Text
  // gegen ValueChecked/ValueUnchecked (leer: 1/True/Ja = an, Rest = aus)
  if (F = nil) or F.IsNull then
    Exit(cbGrayed);
  if F.DataType = ftBoolean then
  begin
    if F.AsBoolean then
      Result := cbChecked
    else
      Result := cbUnchecked;
    Exit;
  end;
  VC := '';
  VU := '';
  if C is TPPGDBGridColumn then
  begin
    VC := TPPGDBGridColumn(C).ValueChecked;
    VU := TPPGDBGridColumn(C).ValueUnchecked;
  end;
  S := F.Text;
  if VC <> '' then
    On := PPGDBMatchesValue(S, VC)
  else
    On := TPPGCellPainter.IsCheckedText(S);
  if On then
    Result := cbChecked
  else if (VU = '') or PPGDBMatchesValue(S, VU) then
    Result := cbUnchecked
  else
    Result := cbGrayed;
end;

function TPPGCustomDBGrid.CheckStateText(State: TCheckBoxState): string;
begin
  case State of
    cbChecked: Result := '1';
    cbUnchecked: Result := '0';
  else
    Result := PPGGridCheckGrayed;
  end;
end;

function TPPGCustomDBGrid.FieldCellText(ACol: Integer; F: TField): string;
var
  C: TPPGDBGridColumn;
begin
  if F = nil then
    Exit('');
  if IsCheckColumn(ACol) then
    Exit(CheckStateText(FieldCheckState(F, ColumnOf(ACol))));
  C := ColumnLookup(ACol);
  if C <> nil then
  begin
    if F.IsNull then
      Result := ''
    else
      Result := C.LookupText(F.Value);
  end
  else
    Result := F.DisplayText;
end;

procedure TPPGCustomDBGrid.ListDataChanged;
begin
  if FListBusy or (csDestroying in ComponentState) or (csLoading in ComponentState) then
    Exit;
  FListBusy := True;
  try
    FSnapValid := False;
    RebuildCache;
    Invalidate;
  finally
    FListBusy := False;
  end;
end;

procedure TPPGCustomDBGrid.FillLookupEditor(ACol: Integer);
var
  C: TPPGComboBox;
  DS: TDataSet;
  RF, T: TField;
  B: TBookmark;
  S, LK, LR: string;
  Plain: Boolean;
begin
  if not (InplaceEditor is TPPGComboBox) then
    Exit;
  C := TPPGComboBox(InplaceEditor);
  if not LookupSource(ACol, DS, LK, LR, T) then
  begin
    C.Style := csDropDown;
    Exit;
  end;
  // Nachschlage-Spalte: Texte wie LookupText (Wert als Text), Nachschlagefeld:
  // DisplayText wie das Feld
  Plain := ColumnLookup(ACol) <> nil;
  S := FieldCellText(ACol, FieldOfCol(ACol));
  C.Items.BeginUpdate;
  try
    C.Items.Clear;
    RF := DS.FindField(LR);
    if (RF <> nil) and DS.Active then
    begin
      PPGDBBeginRead;
      DS.DisableControls;
      try
        B := DS.Bookmark;
        try
          DS.First;
          while not DS.Eof do
          begin
            if Plain then
              C.Items.Add(RF.AsString)
            else
              C.Items.Add(RF.DisplayText);
            DS.Next;
          end;
        finally
          if (Length(B) > 0) and DS.BookmarkValid(B) then
            DS.Bookmark := B;
        end;
      finally
        DS.EnableControls;
        PPGDBEndRead;
      end;
    end;
  finally
    C.Items.EndUpdate;
  end;
  C.Style := csDropDownList;
  C.ItemIndex := C.Items.IndexOf(S);
end;

procedure TPPGCustomDBGrid.EditorEdited;
begin
  // Wie TDBGrid: Bearbeiten-Modus beim ersten Tastendruck, nicht erst beim
  // Uebernehmen (Navigator und Datensatz-Anzeige sehen sofort dsEdit)
  if FDataLink.Active and not FDataLink.Editing and not FReadOnly then
    FDataLink.Edit;
end;

procedure TPPGCustomDBGrid.SetCellByUser(ACol, ARow: Integer; const Value: string);
var
  F: TField;
  C: TPPGGridColumn;
  NewSt: TCheckBoxState;
  VC, VU: string;
begin
  F := FieldOfCol(ACol);
  if (F = nil) or not FDataLink.Active or (ARow - FixedRows <> FDataLink.ActiveRecord) then
    Exit;
  if (F.FieldKind = fkLookup) or (ColumnLookup(ACol) <> nil) then
  begin
    SetLookupByUser(ACol, ARow, Value);
    Exit;
  end;
  if IsCheckColumn(ACol) then
  begin
    C := ColumnOf(ACol);
    if TPPGCellPainter.IsCheckedText(Value) then
      NewSt := cbChecked
    else if TPPGCellPainter.IsGrayedText(Value) then
      NewSt := cbGrayed
    else
      NewSt := cbUnchecked;
    if FieldCheckState(F, C) = NewSt then
      Exit;
    if not FDataLink.Editing and not FDataLink.Edit then
      Exit;
    VC := '';
    VU := '';
    if C is TPPGDBGridColumn then
    begin
      VC := Trim(PPGDBFirstValue(TPPGDBGridColumn(C).ValueChecked));
      VU := Trim(PPGDBFirstValue(TPPGDBGridColumn(C).ValueUnchecked));
    end;
    if VC = '' then
      VC := '1';
    if VU = '' then
      VU := '0';
    if NewSt = cbGrayed then
      F.Clear
    else if F.DataType = ftBoolean then
      F.AsBoolean := NewSt = cbChecked
    else if NewSt = cbChecked then
      F.Text := VC
    else
      F.Text := VU;
    Exit;
  end;
  if F.Text = Value then
    Exit;
  if not FDataLink.Editing and not FDataLink.Edit then
    Exit;
  F.Text := Value;
end;

procedure TPPGCustomDBGrid.SetLookupByUser(ACol, ARow: Integer; const Value: string);
var
  DS: TDataSet;
  T: TField;
  LK, LR: string;
  Key: Variant;
begin
  if not LookupSource(ACol, DS, LK, LR, T) or
    (FieldCellText(ACol, FieldOfCol(ACol)) = Value) then
    Exit;
  if Value = '' then
    Key := Null
  else
  begin
    PPGDBBeginRead;
    try
      Key := DS.Lookup(LR, Value, LK);
    finally
      PPGDBEndRead;
    end;
    // Unbekannter Text: nichts aendern (vorher wurde der Schluessel still Null)
    if VarIsNull(Key) or VarIsEmpty(Key) then
      Exit;
  end;
  if not FDataLink.Editing and not FDataLink.Edit then
    Exit;
  T.Value := Key;
end;

procedure TPPGCustomDBGrid.EditorPrepare(ACol, ARow: Integer);
begin
  inherited EditorPrepare(ACol, ARow);
  // Vor dem Fokus: der Stilwechsel der Auswahl blendet das innere Feld aus
  FillLookupEditor(ACol);
end;

procedure TPPGCustomDBGrid.EditorOpened(ACol, ARow: Integer);
begin
  inherited EditorOpened(ACol, ARow);
  FEditBm := nil;
  if FDataLink.Active and (FDataLink.DataSet.State = dsBrowse) then
    FEditBm := FDataLink.DataSet.Bookmark;
end;

function TPPGCustomDBGrid.SelectCell(ACol, ARow: Integer): Boolean;
var
  R: Integer;
begin
  if (FSyncing = 0) and FDataLink.Active and (ARow >= FixedRows) then
  begin
    R := ARow - FixedRows;
    if R >= FDataLink.RecordCount then
      Exit(False); // leere Fuellzeile
    if R <> FDataLink.ActiveRecord then
    begin
      Inc(FSyncing);
      try
        FDataLink.MoveBy(R - FDataLink.ActiveRecord);
      finally
        Dec(FSyncing);
      end;
    end;
  end;
  Result := inherited SelectCell(ACol, ARow);
end;

procedure TPPGCustomDBGrid.HeaderClicked(ACol, VRow: Integer);
var
  C: TPPGGridColumn;
begin
  if not (dgTitleClick in FDBOptions) or (ACol < FixedCols) then
    Exit;
  C := ColumnOf(ACol);
  if Assigned(FOnTitleClick) and (C is TPPGDBGridColumn) then
    FOnTitleClick(TPPGDBGridColumn(C));
end;

procedure TPPGCustomDBGrid.ContentMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  C, V: Integer;
  Col: TPPGGridColumn;
begin
  inherited ContentMouseUp(Button, Shift, X, Y);
  if (Button = mbLeft) and Assigned(FOnCellClick) and MouseCoord(X, Y, C, V) and
    (V >= VisualRow(FixedRows)) and (C >= FixedCols) then
  begin
    Col := ColumnOf(DataCol(C));
    if Col is TPPGDBGridColumn then
      FOnCellClick(TPPGDBGridColumn(Col));
  end;
end;

function TPPGCustomDBGrid.ConfirmDelete: Boolean;
begin
  Result := MessageDlg(PPGStr(@SPPGDBGridConfirmDelete), mtConfirmation, [mbOK, mbCancel], 0) = mrOK;
end;

procedure TPPGCustomDBGrid.NavigateKey(var Key: Word; Shift: TShiftState);
var
  DS: TDataSet;
  RowKey: Boolean;
  OrigKey: Word;
  OldBm: TBookmark;
begin
  // Audit 7c #1: laeuft nach OnKeyDown (KeyDown der Grid-Basis)
  if not FDataLink.Active or EditorMode then
  begin
    inherited NavigateKey(Key, Shift);
    Exit;
  end;
  DS := FDataLink.DataSet;
  OrigKey := Key;
  RowKey := False;
  if MultiSelectActive then
  begin
    case Key of
      Ord('A'):
        if Shift = [ssCtrl] then
        begin
          FSelected.SelectAll;
          Key := 0;
          Exit;
        end;
      VK_SPACE:
        // Strg+Leertaste immer, Leertaste nur ausserhalb von Zellarten (Kaestchen)
        if (Shift = [ssCtrl]) or ((Shift = []) and (KindOf(DataCol(FocusCol)) = nil)) then
        begin
          FSelected.CurrentRowSelected := not FSelected.CurrentRowSelected;
          FAnchor := FSelected.CurrentBookmark;
          Key := 0;
          Exit;
        end;
      VK_DELETE:
        if (ssCtrl in Shift) and (FSelected.Count > 0) and not FReadOnly and DS.CanModify then
        begin
          if not (dgConfirmDelete in FDBOptions) or ConfirmDeleteSelected(FSelected.Count) then
          begin
            FAnchor := nil;
            FSelected.Delete;
          end;
          Key := 0;
          Exit;
        end;
      VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT:
        RowKey := True;
      VK_HOME, VK_END:
        RowKey := ssCtrl in Shift;
    end;
    if RowKey then
    begin
      OldBm := FSelected.CurrentBookmark;
      // Umschalt+Pfeil runter am Ende waehlt, haengt aber keinen Satz an
      if (Key = VK_DOWN) and (ssShift in Shift) and (DS.State = dsBrowse) then
      begin
        DS.Next;
        Key := 0;
      end;
    end;
  end;
  case Key of
    VK_UP:
      begin
        // Neuer, unveraenderter Datensatz am Ende verschwindet wieder (TDBGrid)
        if (DS.State = dsInsert) and not DS.Modified and DS.Eof then
          DS.Cancel
        else
          DS.Prior;
        Key := 0;
      end;
    VK_DOWN:
      begin
        if (DS.State = dsInsert) and not DS.Modified then
        begin
          Key := 0;
          Exit;
        end;
        DS.Next;
        if DS.Eof and (dgEditing in FDBOptions) and not FReadOnly and DS.CanModify then
          DS.Append;
        Key := 0;
      end;
    VK_PRIOR:
      begin
        FDataLink.MoveBy(-VisibleDataRows);
        Key := 0;
      end;
    VK_NEXT:
      begin
        FDataLink.MoveBy(VisibleDataRows);
        Key := 0;
      end;
    VK_HOME, VK_END:
      if ssCtrl in Shift then
      begin
        if Key = VK_HOME then
          DS.First
        else
          DS.Last;
        Key := 0;
      end;
    VK_INSERT:
      if (Shift = []) and (dgEditing in FDBOptions) and not FReadOnly and DS.CanModify then
      begin
        DS.Insert;
        Key := 0;
      end;
    VK_DELETE:
      if (ssCtrl in Shift) and not FReadOnly and DS.CanModify and not (DS.Bof and DS.Eof) then
      begin
        if not (dgConfirmDelete in FDBOptions) or ConfirmDelete then
          DS.Delete;
        Key := 0;
      end;
    VK_ESCAPE:
      if DS.State in [dsEdit, dsInsert] then
      begin
        DS.Cancel;
        Key := 0;
      end;
  end;
  if Key <> 0 then
    inherited NavigateKey(Key, Shift)
  else if RowKey and MultiSelectActive then
  begin
    // Mehrfachauswahl nach dem Satzwechsel
    if ssShift in Shift then
    begin
      if (OrigKey = VK_UP) or (OrigKey = VK_DOWN) then
        ExtendByStep(OldBm)
      else
      begin
        if Length(FAnchor) = 0 then
          FAnchor := OldBm;
        SelectRangeTo(FAnchor);
      end;
    end
    else if (ssCtrl in Shift) and ((OrigKey = VK_UP) or (OrigKey = VK_DOWN)) then
      // Strg+Pfeil bewegt nur (danach Strg+Leertaste)
    else
    begin
      FSelected.Clear;
      FAnchor := FSelected.CurrentBookmark;
    end;
  end;
end;

{ ---- Owner-Draw ---- }

function TPPGCustomDBGrid.OwnerDrawAssigned: Boolean;
begin
  Result := inherited OwnerDrawAssigned or Assigned(FOnDrawColumnCell);
end;

function TPPGCustomDBGrid.DefaultDrawsKinds: Boolean;
begin
  // Wie TDBGrid: ohne DefaultDrawing zeichnet das Ereignis den Inhalt
  // (DefaultDrawColumnCell zeichnet bei Bedarf Text bzw. Kaestchen)
  Result := DefaultDrawing;
end;

procedure TPPGCustomDBGrid.OwnerDrawCell(ACol, VRow, ARow: Integer; const R: TRect;
  State: TGridDrawState);
var
  DCol, Old, B: Integer;
  Col: TPPGGridColumn;
  Fill, Txt: TColor;
begin
  inherited OwnerDrawCell(ACol, VRow, ARow, R, State);
  if not Assigned(FOnDrawColumnCell) or (gdFixed in State) or not FDataLink.Active then
    Exit;
  // Nur echte Datensaetze (keine leere Fuellzeile)
  B := ARow - FixedRows;
  if (B < 0) or (B >= FDataLink.RecordCount) or (B >= Length(FCache)) then
    Exit;
  DCol := DataCol(ACol);
  Col := ColumnOf(DCol);
  if not (Col is TPPGDBGridColumn) then
    Exit;
  // Wie TDBGrid: Schrift und Pinsel in den Farben der Zelle (auch nach
  // Aenderungen in OnDrawCell)
  PrepareItemCanvas(ACol, VRow, State);
  CellDrawColors(ACol, VRow, State, Fill, Txt);
  Canvas.Brush.Color := Fill; // bsSolid
  FDrawBrush := ColorToRGB(Canvas.Brush.Color);
  // Wie TDBGrid: die Datenmenge steht waehrend des Ereignisses auf dem
  // gezeichneten Satz (ActiveRecord des Puffers, ohne Satzwechsel)
  Old := FDataLink.ActiveRecord;
  FDrawRow := B;
  try
    FDataLink.ActiveRecord := B;
    try
      DrawColumnCell(R, DCol - FixedCols, TPPGDBGridColumn(Col), State);
    finally
      FDataLink.ActiveRecord := Old;
    end;
  finally
    FDrawRow := -1;
  end;
end;

procedure TPPGCustomDBGrid.DrawColumnCell(const Rect: TRect; DataCol: Integer;
  Column: TPPGDBGridColumn; State: TGridDrawState);
begin
  if Assigned(FOnDrawColumnCell) then
    FOnDrawColumnCell(Self, Rect, DataCol, Column, State);
end;

procedure TPPGCustomDBGrid.DefaultDrawColumnCell(const Rect: TRect; DataCol: Integer;
  Column: TPPGDBGridColumn; State: TGridDrawState);
var
  Cv: TCanvas;
  ACol, R: Integer;
  S: string;
  K: IPPGCellKind;
  Ctx: TPPGCellKindContext;
  GC: IPPGCanvas;
  TR: TRect;
  Fmt: TTextFormat;
  Al: TAlignment;
begin
  Cv := Canvas;
  // Nur eine geaenderte Pinselfarbe fuellt: die vorbereitete Farbe ist die
  // Flaeche der Zelle, das Grid hat sie (mit bedingten Formaten, Balken,
  // halbtransparenter Auswahl) schon genauer gezeichnet
  if (Cv.Brush.Style <> bsClear) and
    ((FDrawRow < 0) or (ColorToRGB(Cv.Brush.Color) <> FDrawBrush)) then
    Cv.FillRect(Rect);
  ACol := FixedCols + DataCol;
  if FDrawRow >= 0 then
    R := FDrawRow
  else if FDataLink.Active then
    R := FDataLink.ActiveRecord
  else
    R := -1;
  S := '';
  // Text aus dem Zwischenspeicher (Paint-Regel: kein Feldzugriff)
  if (R >= 0) and (R < Length(FCache)) and (DataCol >= 0) and (DataCol < Length(FCache[R])) then
    S := FCache[R][DataCol];
  K := KindOf(ACol);
  if K <> nil then
  begin
    // Kaestchen bzw. Zellart im Theme (auch im Dunkelmodus)
    Ctx := KindContext(ACol);
    if Ctx.Painter = nil then
      Exit;
    GC := TPPGGdiCanvas.Create(Cv.Handle);
    Ctx.Canvas := GC;
    K.PaintCell(Ctx, Rect, S);
    Exit;
  end;
  if S = '' then
    Exit;
  TR := Rect;
  InflateRect(TR, -PPGScale(CellPad, ScalePPI), 0);
  if Column <> nil then
    Al := Column.Alignment
  else
    Al := taLeftJustify;
  if UseRightToLeftAlignment then
    case Al of
      taLeftJustify: Al := taRightJustify;
      taRightJustify: Al := taLeftJustify;
    end;
  Fmt := [tfSingleLine, tfVerticalCenter, tfEndEllipsis, tfNoPrefix];
  case Al of
    taRightJustify: Include(Fmt, tfRight);
    taCenter: Include(Fmt, tfCenter);
  end;
  if UseRightToLeftReading then
    Include(Fmt, tfRtlReading);
  Cv.Brush.Style := bsClear;
  Cv.TextRect(TR, S, Fmt);
end;

{ TPPGDBGrid }

function TPPGDBGrid.GetTitleFont: TFont;
begin
  Result := Styles.Header.Font;
end;

procedure TPPGDBGrid.SetTitleFont(const Value: TFont);
begin
  Styles.Header.Font := Value; // setzt ParentFont := False
end;

end.
