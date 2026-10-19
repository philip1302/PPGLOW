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
  - Kartenansicht (ViewStyle = dgvCards): je Datensatz eine Karte mit den
    sichtbaren Spalten als Zeilen "Beschriftung: Wert" (Columns wie in der
    Tabelle: Titel, Reihenfolge, Visible, Kaestchen, Nachschlagetexte, Stile).
    Das Grid legt seine Zellen ueber die Erweiterungspunkte der Basis
    (CustomCellLayout): Zeile = Datensatz des Puffers, Spalte = Feld; Fokus,
    Editor, Zellarten, Owner-Draw und UIA arbeiten so unveraendert. Karten
    fliessen nebeneinander (CardWidth, CardSpacing), brechen um und werden
    senkrecht pixelgenau gescrollt. Mit RecNo (IsSequenced) steht jede Karte
    nach ihrer Satznummer; der Puffer haelt die Kartenzeilen um den aktiven
    Satz und wird bei Bedarf ausgerichtet (Puffer verschieben, Satz bleibt).
    Ohne RecNo fliessen die Karten ab dem Pufferanfang. Pfeile/Bild/Pos1/Ende
    wechseln die Karte, Tab das Feld, F2/Enter/Doppelklick bearbeiten.
  - Bearbeitungsformular in der Zeile (EditMode = dgeForm, nur Tabelle): Enter,
    F2, Doppelklick, Tippen bzw. ShowEditForm klappen unter der aktiven Zeile
    einen Bereich auf (TPPGDBGridEditForm, Kind-Control des Grids). Er zeigt
    die Felder der Spalten (Reihenfolge wie in der Anzeige, Column.
    EditFormVisible/EditFormColSpan) als Beschriftung + Editor in
    EditForm.ColumnCount Spalten und die Schaltflaechen Uebernehmen/Abbrechen.
    Die Editoren sind die Zell-Editoren des Grids (Text, Auswahl, Zahl;
    Nachschlage-Spalten mit Liste; Kaestchen als TPPGCheckBox). Die Zeile
    wird dafuer hoeher (SetRowGap der Basis), die folgenden Zeilen ruecken
    nach unten, der Puffer zaehlt entsprechend weniger Zeilen. Werte gehen
    beim Uebernehmen (bzw. beim Buchen von aussen, UpdateData) in die Felder,
    dann Post; ein Fehler (Feldwert, Pflichtfeld, BeforePost) laesst das
    Formular offen und setzt den Fokus auf das Feld. Abbrechen (Esc) ruft
    Cancel. Wechselt der Datensatz (Navigator, Klick auf eine andere Zeile,
    Scrollen), bucht die Datenmenge wie ueblich und das Formular schliesst.
    Zellen der Tabelle sind in diesem Modus nicht direkt bearbeitbar.
  - Gruppieren (Columns[].GroupIndex, Ziehen in die Gruppenleiste
    ShowGroupPanel, GroupBy): nur dann liest das Grid die ganze Datenmenge
    (einmal mit DisableControls) und haelt je Satz eine Zeile im Speicher
    (Texte, Werte, Lesezeichen). Gruppen, Zuklappen, Gruppenfuesse und Summen
    (Column.Aggregate) rechnet die Basis wie im TPPGGrid; die Reihenfolge
    innerhalb einer Gruppe ist die der Datenmenge. Fokus auf einer Datenzeile
    stellt die Datenmenge per Lesezeichen auf den Satz; Satzwechsel von aussen
    (Navigator, Next, Locate) fokussieren die Zeile und klappen ihre Gruppen
    auf. Aenderungen von aussen (DataSetChanged: Refresh, Filter, Loeschen,
    First/Last, EnableControls ...) lesen die Datenmenge neu; Post/Cancel einer
    Bearbeitung liest nur den Satz. Zugeklappte Gruppen bleiben (nach
    Gruppenwert) beim Neulesen zugeklappt. Ohne Gruppenspalten bleibt alles
    beim Puffer wie oben. Grenzen: Speicher und Lesezeit wachsen mit der
    Datenmenge; Pfeil runter am Ende haengt keinen Satz an; ein neuer Satz
    steht bis zum Buchen in der Gruppe seiner Anfangswerte; OnDrawColumnCell
    kommt nur fuer Saetze im Puffer der Datenmenge; RowValue fuer andere als
    den aktiven Satz liefert die Felder der Spalten (alle Felder nur, wenn
    OnGetCellStyle/OnSelectCell beim Lesen zugewiesen waren); Kartenansicht
    gruppiert nicht.
  - Nicht unterstuetzt: Unterspalten (ADT/Array-Felder). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.Types,
  System.Generics.Collections, Vcl.Controls, Vcl.Graphics, Vcl.Grids, Vcl.DBGrids, Vcl.StdCtrls,
  System.TypInfo, // vor Data.DB: dessen ftCurrency/ftExtended gelten
  Data.DB,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Base, PPG.Panel, PPG.Button, PPG.Grid,
  PPG.Grid.Columns, PPG.Grid.Data, PPG.Grid.Styles, PPG.Grid.CellKinds, PPG.Grid.View,
  PPG.Grid.Edit, PPG.ColumnComboBox;

type
  TPPGCustomDBGrid = class;

  TPPGDBGridColumn = class;

  /// Bearbeiten im DB-Grid: dgeCells = in der Zelle (wie TDBGrid), dgeForm =
  /// Bearbeitungsformular unter der aktiven Zeile (nur in der Tabelle).
  TPPGDBGridEditMode = (dgeCells, dgeForm);

  /// Feld einer Spalte im Bearbeitungsformular: efvAuto = wie Column.Visible,
  /// efvShow = immer (auch bei ausgeblendeter Spalte), efvHide = nie.
  TPPGEditFormVisibility = (efvAuto, efvShow, efvHide);

  /// Editor eines Felds im Bearbeitungsformular: efeAuto = nach dem Feld
  /// (Memo-Felder mehrzeilig, Datumsfelder mit Kalender, sonst wie in der
  /// Zelle), efeText = wie in der Zelle, efeMemo = mehrzeilig (EditFormRows),
  /// efeDate = Datumsauswahl (nur Datums-/Zeitfelder, sonst wie efeText).
  TPPGEditFormEditor = (efeAuto, efeText, efeMemo, efeDate);

  /// Aufruf je ausgewaehltem Datensatz (ForEachSelected): die Datenmenge steht
  /// auf dem Satz.
  TPPGDBGridRecordProc = reference to procedure(DataSet: TDataSet);

  /// Darf der aktive Satz der Datenmenge in die Mehrfachauswahl (Allow)?
  TPPGDBGridCanSelectEvent = procedure(Sender: TObject; var Allow: Boolean) of object;

  /// Bearbeitungsformular geschlossen (Accepted = uebernommen, sonst verworfen).
  TPPGDBGridEditFormCloseEvent = procedure(Sender: TObject; Accepted: Boolean) of object;

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
    FEditFormVisible: TPPGEditFormVisibility;
    FEditFormColSpan: Integer;
    FListFieldIndex: Integer;
    FEditFormEditor: TPPGEditFormEditor;
    FEditFormRows: Integer;
    FEditFormGroup: string;
    FEditFormIndex: Integer;
    FEditFormNewRow: Boolean;
    procedure SetEditFormIndex(const Value: Integer);
    procedure SetEditFormNewRow(const Value: Boolean);
    procedure SetEditFormVisible(const Value: TPPGEditFormVisibility);
    procedure SetEditFormColSpan(const Value: Integer);
    procedure SetListFieldIndex(const Value: Integer);
    procedure SetEditFormEditor(const Value: TPPGEditFormEditor);
    procedure SetEditFormRows(const Value: Integer);
    procedure SetEditFormGroup(const Value: string);
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
    /// Angezeigtes Feld aus ListField (nach ListFieldIndex; ausserhalb der
    /// Liste das erste).
    function ListResultField: string;
    /// Felder aus ListField (Semikolon-Liste, ohne Leerzeichen).
    function ListFieldNames: TArray<string>;
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
    /// Felder der Liste, mehrere mit Semikolon ("Name;Ort"): die Zelle zeigt
    /// das Feld nach ListFieldIndex, die Auswahlliste (Zelle und Formular)
    /// zeigt alle als Spalten.
    property ListField: string read FListField write SetListField;
    /// Index des in der Zelle angezeigten Felds aus ListField (0-basiert, wie
    /// TDBLookupComboBox.ListFieldIndex; 0..31).
    property ListFieldIndex: Integer read FListFieldIndex write SetListFieldIndex default 0;
    /// Feld im Bearbeitungsformular (EditMode = dgeForm): efvAuto = wie
    /// Visible, efvShow = immer, efvHide = nie.
    property EditFormVisible: TPPGEditFormVisibility read FEditFormVisible
      write SetEditFormVisible default efvAuto;
    /// Spalten des Formular-Rasters, die das Feld belegt (1..8; hoechstens
    /// EditForm.ColumnCount).
    property EditFormColSpan: Integer read FEditFormColSpan write SetEditFormColSpan default 1;
    /// Editor im Bearbeitungsformular (efeAuto: nach dem Feld).
    property EditFormEditor: TPPGEditFormEditor read FEditFormEditor write SetEditFormEditor
      default efeAuto;
    /// Hoehe eines mehrzeiligen Felds im Formular in Rasterzeilen (1..20).
    property EditFormRows: Integer read FEditFormRows write SetEditFormRows default 3;
    /// Abschnitt im Formular: ein neuer Wert beginnt eine neue Zeile mit der
    /// Ueberschrift (leer = ohne Ueberschrift). Felder eines Abschnitts
    /// stehen in der Anzeige-Reihenfolge hintereinander.
    property EditFormGroup: string read FEditFormGroup write SetEditFormGroup;
    /// Reihenfolge im Formular (-1 = wie die Anzeige). Felder mit Index
    /// stehen zuerst, nach dem Index aufsteigend (gleich: wie die Anzeige),
    /// danach die ohne Index; Abschnitte (EditFormGroup) folgen dieser Folge.
    property EditFormIndex: Integer read FEditFormIndex write SetEditFormIndex default -1;
    /// Feld beginnt im Formular eine neue Rasterzeile (links).
    property EditFormNewRow: Boolean read FEditFormNewRow write SetEditFormNewRow default False;
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

  /// Darstellung des DB-Grids: Tabelle (wie TDBGrid) oder Karten (je
  /// Datensatz eine Karte mit "Beschriftung: Wert" je sichtbarer Spalte).
  TPPGDBGridViewStyle = (dgvTable, dgvCards);

  /// Masse der Kartenansicht in Pixeln (aus Properties, Schrift und DPI).
  TPPGDBGridCardMetrics = record
    View: TRect;     // Bereich der Karten (Client-Koordinaten)
    Gap: Integer;    // Abstand zwischen den Karten und zum Rand
    Pad: Integer;    // Innenabstand der Karte
    LineH: Integer;  // Hoehe einer Feldzeile
    CardW: Integer;
    CardH: Integer;
    LabelW: Integer; // Breite der Beschriftung (0 = keine)
    PerRow: Integer; // Karten je Zeile (mindestens 1)
    RowH: Integer;   // Kartenhoehe + Abstand
    Fields: Integer; // sichtbare Felder je Karte
  end;

  /// Einstellungen des Bearbeitungsformulars (TPPGCustomDBGrid.EditForm).
  TPPGDBGridEditFormOptions = class(TPersistent)
  private
    FGrid: TPPGCustomDBGrid;
    FColumnCount: Integer;
    FLabelWidth: Integer;
    FShowButtons: Boolean;
    procedure SetColumnCount(const Value: Integer);
    procedure SetLabelWidth(const Value: Integer);
    procedure SetShowButtons(const Value: Boolean);
    procedure Changed;
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AGrid: TPPGCustomDBGrid);
    procedure Assign(Source: TPersistent); override;
  published
    /// Spalten des Rasters (Paare Beschriftung + Editor nebeneinander), 1..8.
    property ColumnCount: Integer read FColumnCount write SetColumnCount default 2;
    /// Breite der Beschriftung (logische Pixel; 0 = ohne Beschriftung).
    /// Hoechstens die halbe Breite eines Feldes.
    property LabelWidth: Integer read FLabelWidth write SetLabelWidth default 120;
    /// Schaltflaechen Uebernehmen/Abbrechen unten im Formular.
    property ShowButtons: Boolean read FShowButtons write SetShowButtons default True;
  end;

  /// Ein Feld des Bearbeitungsformulars.
  TPPGDBGridEditFormItem = record
    DataCol: Integer;            // Datenspalte des Grids
    Editor: TPPGCustomControl;   // Zell-Editor bzw. TPPGCheckBox
    Kind: TPPGGridEditorKind;
    Editable: Boolean;
    Dirty: Boolean;              // vom Anwender geaendert, noch nicht geschrieben
    Original: string;            // Text beim Fuellen (Aenderung auch per Code)
    Caption: string;
    Cell, Row, Span: Integer;    // Lage im Raster
    RowSpan: Integer;            // belegte Rasterzeilen (mehrzeilig > 1)
    LabelR: TRect;               // Beschriftung beim Anordnen (ohne Scrollen)
    EditorR: TRect;              // Editor beim Anordnen (ohne Scrollen)
  end;

  /// Abschnitt des Bearbeitungsformulars (Column.EditFormGroup).
  TPPGDBGridEditFormGroup = record
    Caption: string;
    Row: Integer;                // Rasterzeile der Ueberschrift
    FirstItem: Integer;          // erstes Feld des Abschnitts
    R: TRect;                    // Ueberschrift beim Anordnen (ohne Scrollen)
  end;

  /// Bearbeitungsformular in der Zeile (Kind-Control des DB-Grids, wird vom
  /// Grid erzeugt, angeordnet und gefuellt). Scrollt senkrecht, wenn es
  /// hoeher ist als der Platz im Grid. Tab/Umschalt+Tab wechseln zwischen
  /// den Editoren und Schaltflaechen, Enter zum naechsten Feld (im letzten:
  /// Uebernehmen), Strg+Enter uebernimmt, Esc bricht ab.
  TPPGDBGridEditForm = class(TPPGCustomPanel)
  private
    FGrid: TPPGCustomDBGrid;
    FItems: array of TPPGDBGridEditFormItem;
    FGroups: array of TPPGDBGridEditFormGroup;
    FApply: TPPGButton;
    FCancel: TPPGButton;
    FCurrent: Integer;   // Fokusziel: Feld, dann Uebernehmen, Abbrechen
    FLoading: Integer;   // > 0: Editoren werden gefuellt (kein Dirty)
    FArrangedW: Integer;
    FArrangedPPI: Integer;
    procedure EditorChange(Sender: TObject);
    procedure EditorEnter(Sender: TObject);
    procedure EditorEllipsis(Sender: TObject);
    procedure ApplyClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure CMChildKey(var Message: TCMChildKey); message CM_CHILDKEY;
    /// Feld bzw. Ziel (Items, ItemCount = Uebernehmen, +1 = Abbrechen) eines
    /// Controls (auch des inneren Felds eines Editors); -1 = keins.
    function TargetOfControl(C: TControl): Integer;
    function TargetControl(T: Integer): TWinControl;
    procedure ClearItems;
  protected
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function GetBackgroundColor: TColor; override;
    function GetChildBackground(Child: TControl; out ColorTop, ColorBottom: TColor): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Grid: TPPGCustomDBGrid read FGrid;
    /// Felder im Formular (in der Reihenfolge der Anzeige).
    function ItemCount: Integer;
    /// Datenspalte bzw. Editor des Felds I.
    function ItemDataCol(I: Integer): Integer;
    function ItemEditor(I: Integer): TPPGCustomControl;
    /// Lage des Felds I im Raster (Spalte, Zeile, belegte Spalten).
    procedure ItemCell(I: Integer; out ACell, ARow, ASpan: Integer);
    /// Beschriftung des Felds I (Client-Koordinaten, mit Scrollen).
    function ItemLabelRect(I: Integer): TRect;
    /// Belegte Rasterzeilen des Felds I (mehrzeilige Felder > 1).
    function ItemRowSpan(I: Integer): Integer;
    /// Abschnitte mit Ueberschrift (Column.EditFormGroup).
    function GroupCount: Integer;
    function GroupCaption(I: Integer): string;
    /// Rasterzeile bzw. Flaeche der Ueberschrift (Client-Koordinaten, mit Scrollen).
    function GroupRow(I: Integer): Integer;
    function GroupRect(I: Integer): TRect;
    /// Aktuelles Fokusziel (Feld-Index, ItemCount = Uebernehmen, ItemCount + 1
    /// = Abbrechen).
    property Current: Integer read FCurrent;
    property ApplyButton: TPPGButton read FApply;
    property CancelButton: TPPGButton read FCancel;
  end;

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
    // Kartenansicht (ViewStyle = dgvCards)
    FViewStyle: TPPGDBGridViewStyle;
    FCardWidth: Integer;
    FCardSpacing: Integer;
    FCardLabelWidth: Integer;
    FCardTop: Integer;     // Satz (0-basiert) der ersten Pufferzeile in der Datenmenge
    FCardTotal: Integer;   // Saetze fuer die Anordnung (RecordCount bzw. Puffer)
    FCardSeq: Boolean;     // Datenmenge mit RecNo (IsSequenced)
    FCardActive: Integer;  // zuletzt angezeigter aktiver Satz (-1 = keiner)
    FCardNoReveal: Integer; // > 0: Fokuswechsel scrollt nicht
    FCardKeepScroll: Integer; // > 0: Satzwechsel durch Scrollen (Lage bleibt)
    FCardPlacing: Integer; // > 0: Puffer wird gerade verschoben
    // Bearbeitungsformular (EditMode = dgeForm)
    FEditMode: TPPGDBGridEditMode;
    FEditForm: TPPGDBGridEditFormOptions;
    FEditPanel: TPPGDBGridEditForm; // nil bis zum ersten Oeffnen
    FFormOpen: Boolean;
    FFormBm: TBookmark;    // Satz des Formulars (leer = neuer Satz)
    FFormGap: Integer;     // Hoehe des Formulars in der Zeile (Pixel)
    FFormBusy: Integer;    // > 0: Formular schreibt, bucht bzw. oeffnet
    FDownOnRow: Boolean;   // letzter Mausklick auf einer Datenzeile
    FFormReload: Boolean;  // Bearbeitung von aussen beendet: alle Felder neu
    FOnEditFormShow: TNotifyEvent;
    FOnEditFormClose: TPPGDBGridEditFormCloseEvent;
    FWriteEditor: TPPGCustomControl; // Formular schreibt gerade aus diesem Editor
    // Filterzeile ueber die Datenmenge (OnFilterRecord, vorheriger Zustand)
    FFltDS: TDataSet;
    FFltOldEvent: TFilterRecordEvent;
    FFltOldFiltered: Boolean;
    FFltOldText: string;
    FFltTextCleared: Boolean;
    FFltCols: array of Integer;
    FFltNames: array of string;
    FFltConds: array of TPPGFilterCondition;
    // Zeile fuer RowValue (OnGetCellStyle, OnSelectCell): Pufferzeile bzw.
    // Satz im Schnappschuss (Druck/Export); beide -1 = aktiver Satz
    FCtxRow: Integer;
    FCtxSnap: Integer;
    FSnapAll: array of array of Variant; // Werte aller Felder (nur mit OnGetCellStyle)
    // Fokussierter Datensatz (OnFocusedRecordChanged)
    FLastRecBm: TBookmark;
    FLastRecIns: Boolean;
    FOnFocusedRecordChanged: TNotifyEvent;
    FOnCanSelectRecord: TPPGDBGridCanSelectEvent;
    FNoVeto: Integer;
    // Gruppieren (Columns[].GroupIndex): die ganze Datenmenge im Speicher,
    // je Satz eine Zeile (FCache, FRowBms, FMarks dann je Satz statt je
    // Pufferzeile)
    FGrpOn: Boolean;
    FGrpVals: array of array of Variant; // Wert je Satz x Datenspalte
    FGrpAll: array of array of Variant;  // alle Felder je Satz (RowValue)
    FGrpIndex: TDictionary<string, Integer>; // Lesezeichen -> Satz
    FGrpActive: Integer;    // Satz des aktiven Datensatzes (-1 = keiner)
    FGrpIns: Integer;       // Zeile des neuen Satzes (dsInsert), sonst -1
    FGrpDirty: Boolean;     // ganz neu lesen
    FGrpRowDirty: Boolean;  // nur den aktiven Satz neu lesen (Post/Cancel)
    FGrpNeedApply: Boolean; // Gruppen neu bilden
    FGrpQuiet: Integer;     // > 0: eigener Satzwechsel (kein Neulesen)
    FGrpMoving: Integer;    // > 0: Fokuswechsel bewegt gerade die Datenmenge
    FGrpLoading: Boolean;
    FGrpEditBm: TBookmark;  // Satz der laufenden Bearbeitung (dsEdit)
    FGrpLastBm: TBookmark;  // zuletzt fokussierter Satz
    FGrpLastIns: Boolean;
    FAllowEdit: Boolean;
    FAllowInsert: Boolean;
    FAllowDelete: Boolean;
    FSortFromIndex: Boolean;
    FCardAutoWidth: Boolean;
    FCardAreaColor: TColor;
    FGrpBufRecs: array of Integer; // Pufferzeile -> Satz (OnDrawColumnCell)
    FGrpColSig: string;
    FGrpViewSig: string;
    FGrpViewVer: Integer;
    FGrpReadCount: Integer;
    FDrawRec: Integer;      // Owner-Draw im Gruppenmodus: gezeichneter Satz
    procedure FilterRecordHook(DataSet: TDataSet; var Accept: Boolean);
    procedure FilterHook(DS: TDataSet);
    procedure FilterUnhook;
    function FilterFieldMatches(const Cond: TPPGFilterCondition; ACol: Integer; F: TField): Boolean;
    procedure CheckFocusedRecord;
    /// OnCanSelectRecord fuer den aktiven Satz der Datenmenge.
    function AllowSelectCurrent: Boolean;
    /// OnCanSelectRecord fuer ein Lesezeichen (bewegt die Datenmenge kurz).
    function AllowSelectBookmark(const B: TBookmark): Boolean;
    /// Editor des Formulars fuer ein Feld (Memo, Datum, sonst wie die Zelle).
    function FormEditorOf(ACol: Integer): TPPGEditFormEditor;
    /// Nachschlage-Spalte mit mehreren Listenfeldern (mehrspaltige Auswahl)?
    function LookupHasColumns(ACol: Integer): Boolean;
    procedure FillLookupColumns(Combo: TPPGColumnComboBox; ACol: Integer);
    /// Memo- bzw. Datumsfeld des Formulars in den Satz schreiben.
    procedure FormWriteSpecial(I: Integer);
    procedure SetEditMode(const Value: TPPGDBGridEditMode);
    procedure SetEditForm(const Value: TPPGDBGridEditFormOptions);
    /// Bearbeitungsformular statt Zell-Editor (dgeForm in der Tabelle)?
    function FormMode: Boolean;
    /// Darf das Feld der Datenspalte im aktiven Satz bearbeitet werden (wie
    /// CanEditCell ohne die Sperre der Zellen im Formular-Modus)?
    function FormCanEdit(ACol: Integer): Boolean;
    /// Darf das Formular geoeffnet werden (Datenmenge bearbeitbar)?
    function FormAllowed: Boolean;
    /// Bearbeitbare Zelle (ohne die Sperre des Formular-Modus).
    function CellEditable(ACol, VRow: Integer): Boolean;
    /// Hoehe eines Editors im Formular (Pixel).
    function FormEditorHeight: Integer;
    /// Naechstes bzw. vorheriges bedienbares Ziel (im Kreis; -1 = keins).
    function FormNextTarget(T: Integer; Forward: Boolean): Integer;
    /// "..."-Knopf im Editor des Felds I.
    procedure FormEllipsis(I: Integer);
    /// Editoren fuer die Felder anlegen (Reihenfolge, Raster).
    procedure FormBuild;
    /// Lage der Felder im Raster (Spalten, Spanne).
    procedure FormLayoutCells;
    /// Steht Datenspalte A im Formular hinter B (EditFormIndex, Anzeige)?
    function FormOrderAfter(A, B: Integer): Boolean;
    /// Editoren aus dem aktiven Satz fuellen (OnlyClean: nur unveraenderte).
    procedure FormLoadValues(OnlyClean: Boolean);
    /// Editoren und Beschriftungen fuer die Breite des Formulars anordnen.
    procedure FormArrange(Force: Boolean);
    /// Benoetigte Hoehe des Formulars (Pixel, ohne Begrenzung).
    function FormNeededHeight: Integer;
    /// Hoehe der Luecke aus Bedarf und Platz im Grid.
    procedure FormUpdateGap;
    /// Luecke unter der aktiven Zeile und Lage des Formulars.
    procedure FormPlace;
    /// Geaenderte Editoren in die Felder schreiben (Fehler: Fokus aufs Feld).
    procedure FormWriteValues;
    /// Formular ausblenden; Refresh: Puffer und Anzeige neu.
    procedure FormClose(Accepted, Refresh: Boolean);
    function FormItemOfField(F: TField): Integer;
    function FormItemText(I: Integer): string;
    /// Feld I geaendert (Eingabe oder Wert per Code)?
    function FormItemChanged(I: Integer): Boolean;
    procedure FormScrollIntoView(T: Integer);
    procedure FormEditorChanged(I: Integer);
    /// Farben des Formulars (wie das Grid: Theme, Dunkelmodus, Hochkontrast).
    procedure EditFormColors(out Fill, Text, Line, Accent, LabelColor: TColor);
    procedure EditFormOptionsChanged;
    procedure SetViewStyle(const Value: TPPGDBGridViewStyle);
    procedure SetCardWidth(const Value: Integer);
    procedure SetCardSpacing(const Value: Integer);
    procedure SetCardLabelWidth(const Value: Integer);
    procedure SetSortFromIndex(const Value: Boolean);
    procedure SetCardAutoWidth(const Value: Boolean);
    procedure SetCardAreaColor(const Value: TColor);
    /// Darf die Zeile bearbeitet werden (neuer Satz: AllowInsert, sonst
    /// AllowEdit)?
    function EditAllowedAt(VRow: Integer): Boolean;
    /// Kartenansicht aktiv?
    function CardMode: Boolean;
    /// Hoechstens so viele Kartenzeilen beruehren die Ansicht.
    function CardVisibleRows(const M: TPPGDBGridCardMetrics): Integer;
    function CardBufferCount: Integer;
    /// Karte eines Satzes (Index in der Anordnung) in Client-Koordinaten.
    function CardClientRect(const M: TPPGDBGridCardMetrics; Slot: Integer): TRect;
    /// Feldzeile Index einer Karte: ganze Zeile, Beschriftung und Wert.
    function CardFieldRects(const M: TPPGDBGridCardMetrics; const Card: TRect; Index: Integer;
      out LabelR, ValueR: TRect): TRect;
    /// Beschriftung einer Datenspalte (Titel bzw. DisplayLabel).
    function CardLabel(ACol: Integer): string;
    /// Fokus und Lage nach einem Datensatzwechsel (statt SyncPosition).
    procedure CardSync;
    /// Beruehrt die Karte des aktiven Satzes die Ansicht?
    function CardActiveInView: Boolean;
    /// Puffer so legen, dass die Kartenzeilen um den aktiven Satz geladen sind.
    procedure CardPlaceWindow;
    /// Anwender hat gescrollt: aktive Karte aus dem Bild -> Satz nachziehen.
    procedure CardScrolled;
    function CardNavigateKey(var Key: Word; Shift: TShiftState): Boolean;
    procedure CardMouseDown(Shift: TShiftState; X, Y: Integer);
    /// Mehrfachauswahl nach Klick bzw. Taste (wie in der Tabelle).
    procedure CardSelectAfterMove(const OldBm: TBookmark; Shift: TShiftState; Step: Boolean);
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
    /// Auswahlliste einer Nachschlage-Spalte fuellen (Zell-Editor bzw. Formular).
    procedure FillLookupCombo(Editor: TPPGCustomControl; ACol: Integer);
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
    { Gruppieren (ganze Datenmenge im Speicher) }
    /// Gruppenmodus ein bzw. aus (Gruppenspalten, aktive Datenmenge, Tabelle).
    procedure UpdateGroupMode;
    /// DataSetChanged von aussen: ganz bzw. nur den Satz neu lesen.
    procedure GroupNoteChange;
    procedure GroupDataChanged;
    /// Alle Saetze lesen (DisableControls, Position bleibt).
    procedure GroupLoad;
    procedure GroupSetLength(N: Integer; All: Boolean);
    /// Aktiven Satz der Datenmenge in Zeile R lesen.
    procedure GroupReadRow(R: Integer; IsInsert: Boolean);
    /// Gruppen neu bilden (Fokus auf einer Gruppenzeile bleibt auf ihr).
    procedure GroupApply;
    /// Aktiven Satz bestimmen und fokussieren (nach jedem DataChanged).
    procedure GroupSync;
    /// Zeile sichtbar machen (Gruppen darueber aufklappen); sichtbare Zeile.
    function GroupReveal(ARow: Integer): Integer;
    procedure GroupFocusActive;
    /// Datenmenge auf Satz R stellen; False = Ansicht neu aufgebaut bzw.
    /// Satz nicht erreichbar (Fokus ist dann schon gesetzt).
    function GroupGoto(R: Integer): Boolean;
    function GroupIndexOfBm(const B: TBookmark): Integer;
    function GroupIndexOfCurrent: Integer;
    function GroupKeysOf(R: Integer): string;
    function GroupViewSignature: string;
    function GroupColSignature: string;
    function GroupPath(G: Integer): string;
    function GroupByPath(const P: string): Integer;
    /// Bereich in der Reihenfolge der Ansicht waehlen (statt der Datenmenge).
    procedure GroupSelectRange(const FromBm: TBookmark);
    procedure GroupRecordChanged;
    procedure GroupListChanged;
    /// Suche in der Reihenfolge der Ansicht (auch zugeklappte Gruppen).
    function GroupFind(const U: string; Forward, IncludeCurrent, Prefix,
      OneCol: Boolean): Boolean;
    /// Satz des aktiven Datensatzes: Pufferzeile bzw. (gruppiert) Satz.
    function ActiveDataIndex: Integer;
    /// Geladene Zeilen: Puffer bzw. (gruppiert) alle Saetze.
    function LoadedRowCount: Integer;
    procedure GotoDataIndex(R: Integer);
    function GetGroupPanel: Boolean;
    procedure SetGroupPanel(const Value: Boolean);
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
    function AllRowsInView: Boolean; override;
    function CompareDataRows(ACol, R1, R2: Integer): Integer; override;
    function ViewGroupKey(ACol, ARow: Integer): string; override;
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
    function MoveToNextCell: Boolean; override;
    function CanSortColumn(ACol: Integer): Boolean; override;
    function GroupDateValue(ACol, ARow: Integer; out D: TDateTime): Boolean; override;
    { IPPGViewPosition: ungruppiert die Datenmenge (RecNo, RecordCount) }
    function ViewRecordNo: Integer; override;
    function ViewRecordCount: Integer; override;
    function ViewCanMove(Move: TPPGViewMove): Boolean; override;
    function ViewMove(Move: TPPGViewMove): Boolean; override;
    procedure Scrolled; override;
    procedure Resize; override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure NavigateKey(var Key: Word; Shift: TShiftState); override;
    procedure ContentMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    /// Rueckfrage vor dem Loeschen (dgConfirmDelete). Standard: MessageDlg.
    function ConfirmDelete: Boolean; virtual;
    { Kartenansicht (Anordnung der Zellen in Karten) }
    function CustomCellLayout: Boolean; override;
    function CustomCellRect(ACol, VRow: Integer): TRect; override;
    function CustomMouseCoord(X, Y: Integer; out ACol, VRow: Integer): Boolean; override;
    procedure CustomMakeCellVisible(ACol, VRow: Integer); override;
    procedure PaintCustomLayout(const ACanvas: IPPGCanvas; const View: TRect); override;
    procedure EditorArrowMove(Down: Boolean); override;
    { Bearbeitungsformular }
    function DoubleClickEdits: Boolean; override;
    procedure DblClick; override;
    procedure KeyPress(var Key: Char); override;
    /// Fokus auf ein Ziel des Formulars (Feld-Index, ItemCount = Uebernehmen,
    /// ItemCount + 1 = Abbrechen) und ins Bild scrollen.
    procedure FormFocusTarget(T: Integer);
    /// Taste im Bearbeitungsformular (Tab, Enter, Strg+Enter, Esc); True =
    /// verarbeitet. Das Formular ruft es fuer die Tasten seiner Editoren.
    function EditFormKey(Key: Word; Shift: TShiftState): Boolean; virtual;
    /// OnEditFormShow bzw. OnEditFormClose ausloesen.
    procedure DoEditFormShow; virtual;
    procedure DoEditFormClose(Accepted: Boolean); virtual;
    { Filterzeile, Suche, Stile (ueber die Datenmenge) }
    function FiltersInView: Boolean; override;
    function SortsInView: Boolean; override;
    function FilterValueKind(ACol: Integer): TPPGFilterValueKind; override;
    procedure ApplyFilters; override;
    procedure BarsChanged; override;
    function FindFrom(Forward, IncludeCurrent: Boolean): Boolean; override;
    function IncrementalFind(const S: string; FromNext: Boolean): Boolean; override;
    procedure DoGetCellStyle(ACol, ARow: Integer; Purpose: TPPGGridStylePurpose;
      var Style: TPPGGridCellStyle); override;
    function CellEditorClass(ACol, ARow: Integer; Kind: TPPGGridEditorKind): TPPGGridEditorClass; override;
    /// OnFocusedRecordChanged ausloesen.
    procedure DoFocusedRecordChanged; virtual;
    /// Anderer Datensatz im Fokus (Navigation, Klick, Suche, Code; auch der
    /// neue Satz bei Einfuegen).
    property OnFocusedRecordChanged: TNotifyEvent read FOnFocusedRecordChanged
      write FOnFocusedRecordChanged;
    /// Veto fuer die Mehrfachauswahl: vor dem Aufnehmen eines Satzes steht die
    /// Datenmenge auf ihm (Felder lesen, Allow := False lehnt ab). Gilt fuer
    /// Klick, Tasten, Bereiche und SelectAll.
    property OnCanSelectRecord: TPPGDBGridCanSelectEvent read FOnCanSelectRecord
      write FOnCanSelectRecord;

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
    /// dgvTable: Tabelle; dgvCards: je Datensatz eine Karte mit den sichtbaren
    /// Spalten als Zeilen "Beschriftung: Wert", Karten fliessen nebeneinander
    /// und brechen um, senkrecht wird gescrollt.
    property ViewStyle: TPPGDBGridViewStyle read FViewStyle write SetViewStyle default dgvTable;
    /// Breite einer Karte (logische Pixel; schmaler, wenn die Ansicht nicht reicht).
    property CardWidth: Integer read FCardWidth write SetCardWidth default 280;
    /// Abstand zwischen den Karten und zum Rand (logische Pixel).
    property CardSpacing: Integer read FCardSpacing write SetCardSpacing default 8;
    /// Breite der Beschriftung in der Karte (logische Pixel; 0 = ohne
    /// Beschriftung, der Wert nutzt die ganze Breite).
    property CardLabelWidth: Integer read FCardLabelWidth write SetCardLabelWidth default 110;
    /// dgeCells: Bearbeiten in der Zelle; dgeForm: Bearbeitungsformular unter
    /// der aktiven Zeile (Enter, F2, Doppelklick, Tippen, Einfg). Nur in der
    /// Tabelle; die Kartenansicht bearbeitet immer in der Zelle.
    property EditMode: TPPGDBGridEditMode read FEditMode write SetEditMode default dgeCells;
    /// Spalten, Beschriftungsbreite und Schaltflaechen des Formulars.
    property EditForm: TPPGDBGridEditFormOptions read FEditForm write SetEditForm;
    /// Gruppenleiste ueber den Titeln: Spaltenkopf hineinziehen gruppiert
    /// (liest dann die ganze Datenmenge, siehe Kopf der Unit).
    property ShowGroupPanel: Boolean read GetGroupPanel write SetGroupPanel default False;
    /// Formular wurde geoeffnet (Editoren gefuellt, Fokus gesetzt).
    property OnEditFormShow: TNotifyEvent read FOnEditFormShow write FOnEditFormShow;
    /// Formular wurde geschlossen (Accepted = uebernommen).
    property OnEditFormClose: TPPGDBGridEditFormCloseEvent read FOnEditFormClose
      write FOnEditFormClose;
    /// Bearbeiten bestehender Saetze (Zelle, Formular); False = nur lesen.
    property AllowEdit: Boolean read FAllowEdit write FAllowEdit default True;
    /// Neue Saetze (Einfg, Pfeil runter am Ende) und deren Bearbeitung.
    property AllowInsert: Boolean read FAllowInsert write FAllowInsert default True;
    /// Loeschen mit Strg+Entf (ein Satz bzw. die Mehrfachauswahl).
    property AllowDelete: Boolean read FAllowDelete write FAllowDelete default True;
    /// Sortierpfeil nach IndexFieldNames der Datenmenge (erstes Feld; ":D"
    /// bzw. " DESC" = absteigend), beim Oeffnen und nach jeder Aenderung
    /// der Datenmenge (nicht beim Blaettern).
    property SortIndicatorFromIndex: Boolean read FSortFromIndex write SetSortFromIndex default False;
    /// Kartenansicht: Karten so breit, dass die Zeile gefuellt ist (CardWidth
    /// ist dann die Mindestbreite).
    property CardAutoWidth: Boolean read FCardAutoWidth write SetCardAutoWidth default False;
    /// Kartenansicht: Flaeche zwischen den Karten (clDefault = Theme).
    property CardAreaColor: TColor read FCardAreaColor write SetCardAreaColor default clDefault;
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
    /// Kartenansicht: Masse fuer die aktuelle Groesse, Schrift und DPI.
    function CardMetrics: TPPGDBGridCardMetrics;
    /// Kartenansicht: Karten je Zeile (Tabelle: 0).
    function CardsPerRow: Integer;
    /// Kartenansicht: Karte der Pufferzeile ARow (0 = erster geladener Satz,
    /// wie die Datenzeilen der Tabelle) in Client-Koordinaten; leer = keine.
    function CardRect(ARow: Integer): TRect;
    /// Bearbeitungsformular fuer den aktiven Satz oeffnen (nur EditMode =
    /// dgeForm in der Tabelle, bearbeitbare Datenmenge; im Zustand dsInsert
    /// fuer den neuen Satz).
    procedure ShowEditForm;
    /// Formular schliessen: Accept = Werte schreiben und buchen (Post; ein
    /// Fehler wird gemeldet und das Formular bleibt offen), sonst verwerfen
    /// (Cancel). True = geschlossen (bzw. war nicht offen).
    function HideEditForm(Accept: Boolean = True): Boolean;
    /// Editor des Felds einer Datenspalte im offenen Formular (nil = keiner).
    function EditFormEditor(ACol: Integer): TPPGCustomControl;
    /// Ist das Bearbeitungsformular offen?
    property EditFormActive: Boolean read FFormOpen;
    /// Das Formular (nil, solange es nie geoeffnet wurde).
    property EditFormControl: TPPGDBGridEditForm read FEditPanel;
    /// Wert eines Felds im Satz der gerade gefragten Zeile: in OnGetCellStyle
    /// (Bildschirm, Druck, Export) und OnSelectCell der Satz dieser Zeile,
    /// sonst der aktive Satz. Null bei leerem Feld; unbekanntes Feld: EPPGError.
    function RowValue(const FieldName: string): Variant;
    /// Anzahl der ausgewaehlten Saetze (SelectedRows.Count).
    function SelectedCount: Integer;
    /// Proc fuer jeden ausgewaehlten Satz (in der Reihenfolge der Lesezeichen),
    /// die Datenmenge steht dabei auf dem Satz; ohne Anzeige-Aktualisierung
    /// (DisableControls), danach wieder auf dem vorherigen Satz. Ergebnis:
    /// Anzahl der Aufrufe (ungueltige Lesezeichen werden uebersprungen).
    function ForEachSelected(const Proc: TPPGDBGridRecordProc): Integer;
    /// Werte eines Felds aller ausgewaehlten Saetze (Reihenfolge wie
    /// ForEachSelected). Unbekanntes Feld: EPPGError.
    function SelectedValues(const FieldName: string): TArray<Variant>;
    /// Gruppierte Ansicht aktiv (Gruppenspalten; ganze Datenmenge gelesen)?
    function GroupedView: Boolean;
    /// Datenzeile (wie Row) des aktiven Satzes; -1 = keiner.
    function ActiveDataRow: Integer;
    /// Gruppenwerte (Ebene 0 zuerst) des aktiven Satzes; leer ohne Gruppen.
    function ActiveGroupValues: TArray<string>;
    /// Wie TDataSet.Locate; gruppiert ohne Neulesen der Datenmenge (Treffer:
    /// Gruppen aufgeklappt, Zeile fokussiert). Offene Bearbeitung wird gebucht.
    function LocateRecord(const KeyFields: string; const KeyValues: Variant;
      Options: TLocateOptions): Boolean;
    /// Gruppierte Ansicht neu aus der Datenmenge lesen (ohne Gruppierung:
    /// nichts).
    procedure RefreshGroups;
    /// Anzahl kompletter Lesevorgaenge der Datenmenge im Gruppenmodus.
    property GroupReadCount: Integer read FGrpReadCount;
    /// Zeigt die sichtbare Zeile den aktiven Satz der Datenmenge?
    function IsActiveRecordRow(VRow: Integer): Boolean;
    /// Sortierpfeil nach IndexFieldNames setzen (siehe
    /// SortIndicatorFromIndex); True = Pfeil geaendert.
    function SyncSortIndicator: Boolean;
    function ColumnFilterValues(ACol: Integer; MaxCount: Integer = 1000): TArray<string>; override;
  end;

type
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
    property ViewStyle;
    property CardWidth;
    property CardSpacing;
    property CardLabelWidth;
    property CardAutoWidth;
    property CardAreaColor;
    property EditMode;
    property EditForm;
    property AllowEdit;
    property AllowInsert;
    property AllowDelete;
    property SortIndicatorFromIndex;
    property EnterMovesNext;
    property FindExtendedSyntax;
    property FilterValueMenu;
    property FixedColsRight;
    property HeaderMenu;
    property ShowFooter;
    property ShowGroupPanel;
    property GroupFooter;
    property ShowFilterRow;
    property FilterImmediate;
    property ShowFilterBar;
    property FindPanel;
    property IncrementalSearch;
    property SortOnHeaderClick default False;
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
    property OnCellDblClick;
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
    property OnGetGroupText;
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
    property OnEditFormShow;
    property OnEditFormClose;
    property OnFilterChanged;
    property OnSelectCell;
    property OnSorted;
    property OnSortRequest;
    property OnGetFilterValues;
    property OnFocusedRecordChanged;
    property OnCanSelectRecord;
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
  PPG.Controls.Scroll, PPG.Exceptions, PPG.DB.Controls, PPG.Grid.Paint,
  PPG.Render.Gdi, PPG.Controls.Field, PPG.CheckBox, PPG.Memo, PPG.DatePicker,
  System.StrUtils;

type
  TCtrlAccess = class(TPPGCustomControl);
  TFieldAccess = class(TPPGCustomField);
  TDateAccess = class(TPPGCustomDatePicker);

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
  FEditFormColSpan := 1;
  FEditFormRows := 3;
  FEditFormIndex := -1;
  inherited Create(Collection);
end;

procedure TPPGDBGridColumn.SetListFieldIndex(const Value: Integer);
begin
  if FListFieldIndex = Value then
    Exit;
  FListFieldIndex := PPGCheckRange(Self, 'ListFieldIndex', Value, 0, 31);
  ListChanged;
  Changed(False);
end;

procedure TPPGDBGridColumn.SetEditFormEditor(const Value: TPPGEditFormEditor);
begin
  if FEditFormEditor <> Value then
  begin
    FEditFormEditor := Value;
    Changed(False);
  end;
end;

procedure TPPGDBGridColumn.SetEditFormRows(const Value: Integer);
begin
  if FEditFormRows = Value then
    Exit;
  FEditFormRows := PPGCheckRange(Self, 'EditFormRows', Value, 1, 20);
  Changed(False);
end;

procedure TPPGDBGridColumn.SetEditFormIndex(const Value: Integer);
begin
  if FEditFormIndex = Value then
    Exit;
  FEditFormIndex := PPGCheckRange(Self, 'EditFormIndex', Value, -1, 9999);
  Changed(False);
end;

procedure TPPGDBGridColumn.SetEditFormNewRow(const Value: Boolean);
begin
  if FEditFormNewRow <> Value then
  begin
    FEditFormNewRow := Value;
    Changed(False);
  end;
end;

procedure TPPGDBGridColumn.SetEditFormGroup(const Value: string);
begin
  if FEditFormGroup <> Value then
  begin
    FEditFormGroup := Value;
    Changed(False);
  end;
end;

procedure TPPGDBGridColumn.SetEditFormVisible(const Value: TPPGEditFormVisibility);
begin
  if FEditFormVisible <> Value then
  begin
    FEditFormVisible := Value;
    Changed(False);
  end;
end;

procedure TPPGDBGridColumn.SetEditFormColSpan(const Value: Integer);
begin
  if FEditFormColSpan = Value then
    Exit;
  FEditFormColSpan := PPGCheckRange(Self, 'EditFormColSpan', Value, 1, 8);
  Changed(False);
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

function TPPGDBGridColumn.ListFieldNames: TArray<string>;
var
  L: TStringList;
  I: Integer;
begin
  SetLength(Result, 0);
  L := TStringList.Create;
  try
    L.StrictDelimiter := True;
    L.Delimiter := ';';
    L.DelimitedText := FListField;
    for I := 0 to L.Count - 1 do
      if Trim(L[I]) <> '' then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := Trim(L[I]);
      end;
  finally
    L.Free;
  end;
end;

function TPPGDBGridColumn.ListResultField: string;
var
  N: TArray<string>;
begin
  N := ListFieldNames;
  if Length(N) = 0 then
    Result := ''
  else if FListFieldIndex < Length(N) then
    Result := N[FListFieldIndex]
  else
    Result := N[0];
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
    FEditFormVisible := TPPGDBGridColumn(Source).FEditFormVisible;
    FEditFormColSpan := TPPGDBGridColumn(Source).FEditFormColSpan;
    FListFieldIndex := TPPGDBGridColumn(Source).FListFieldIndex;
    FEditFormEditor := TPPGDBGridColumn(Source).FEditFormEditor;
    FEditFormRows := TPPGDBGridColumn(Source).FEditFormRows;
    FEditFormGroup := TPPGDBGridColumn(Source).FEditFormGroup;
    FEditFormIndex := TPPGDBGridColumn(Source).FEditFormIndex;
    FEditFormNewRow := TPPGDBGridColumn(Source).FEditFormNewRow;
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
procedure MoveToBufferIndex(DS: TDataSet; Index: Integer);
var
  C, Moved: Integer;
begin
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

procedure GotoBookmarkAt(DS: TDataSet; const Bm: TBookmark; Index: Integer);
begin
  DS.Bookmark := Bm;
  MoveToBufferIndex(DS, Index);
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
    not Find(Item, I) and FGrid.AllowSelectBookmark(Item);
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
        // Veto der Anwendung je Satz (OnCanSelectRecord)
        if FGrid.AllowSelectCurrent then
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
  // Gruppiert: Aenderung von aussen -> neu lesen (nicht bei eigenen
  // Satzwechseln und waehrend ein PPGlow-Control die Datenmenge liest)
  if FGrid.FGrpOn and (FGrid.FGrpQuiet = 0) and not FGrid.FGrpLoading and not PPGDBReading then
    FGrid.GroupNoteChange;
  FGrid.DataChanged;
  if FGrid.FSortFromIndex then
    FGrid.SyncSortIndicator;
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
  // Bearbeitungsformular offen: Fokus auf den Editor des Felds
  if FGrid.FFormOpen then
  begin
    I := FGrid.FormItemOfField(Field^);
    if I >= 0 then
    begin
      FGrid.FormFocusTarget(I);
      Field^ := nil;
      Exit;
    end;
  end;
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
  FCardWidth := 280;
  FCardSpacing := 8;
  FCardLabelWidth := 110;
  FCardActive := -1;
  FAllowEdit := True;
  FAllowInsert := True;
  FAllowDelete := True;
  FCardAreaColor := clDefault;
  FCtxRow := -1;
  FCtxSnap := -1;
  FGrpActive := -1;
  FGrpIns := -1;
  FDrawRec := -1;
  FGrpIndex := TDictionary<string, Integer>.Create;
  FEditForm := TPPGDBGridEditFormOptions.Create(Self);
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
  // Filter der Datenmenge zuruecksetzen (OnFilterRecord, Filtered, Filter)
  FilterUnhook;
  // Formular nicht mehr bedienen (Kinder werden mit dem Grid freigegeben)
  FFormOpen := False;
  FFormBm := nil;
  if FEditPanel <> nil then
    FEditPanel.FGrid := nil;
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
  FreeAndNil(FEditForm);
  FreeAndNil(FGrpIndex);
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
  if (Operation = opRemove) and (AComponent = FFltDS) and (FFltDS <> nil) then
  begin
    // Datenmenge wird freigegeben: nichts mehr zuruecksetzen
    FFltDS := nil;
    FFltOldEvent := nil;
  end;
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
    // (nicht bei offenem Formular: seine Eingaben stehen noch nicht im Satz)
    if (dgCancelOnExit in FDBOptions) and FDataLink.Active and not FFormOpen and
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
  // Offenes Bearbeitungsformular nimmt den Platz von Zeilen ein
  Result := ((V.Bottom - V.Top) - FixedHeight - FFormGap) div DataRowHeight;
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
              // Gruppierung und Summen bleiben (Ziehen in die Gruppenleiste)
              C.GroupIndex := OldC.GroupIndex;
              C.Aggregate := OldC.Aggregate;
              C.FooterFormat := OldC.FooterFormat;
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
  // Gruppenmodus nach den Gruppenspalten; andere Felder: neu lesen
  UpdateGroupMode;
  if FGrpOn then
  begin
    if GroupColSignature <> FGrpColSig then
      FGrpDirty := True;
    FGrpColSig := GroupColSignature;
  end
  else
    FGrpColSig := '';
  // Offenes Formular folgt den Spalten (Werte neu aus dem Satz)
  if FFormOpen and (FEditPanel <> nil) and FDataLink.Active then
  begin
    FormBuild;
    FormLoadValues(False);
  end;
  UpdateBufferCount;
  DataChanged;
end;

procedure TPPGCustomDBGrid.UpdateBufferCount;
begin
  if not FDataLink.Active then
    Exit;
  if CardMode then
    FDataLink.BufferCount := CardBufferCount
  else
  begin
    FormUpdateGap;
    FDataLink.BufferCount := VisibleDataRows;
  end;
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
  // Kartenansicht: Lage des Puffers in der Datenmenge (Karten stehen nach
  // ihrer Satznummer, damit die Spalten beim Blaettern nicht springen)
  if CardMode then
  begin
    FCardSeq := FDataLink.DataSet.IsSequenced;
    if FCardSeq then
    begin
      // Neuer Satz (dsInsert) hat keine Nummer: Lage behalten
      R := FDataLink.DataSet.RecNo;
      if R > 0 then
        FCardTop := R - 1 - FDataLink.ActiveRecord;
      if FCardTop < 0 then
        FCardTop := 0;
      FCardTotal := FDataLink.DataSet.RecordCount;
    end
    else
    begin
      FCardTop := 0;
      FCardTotal := 0;
    end;
    if FCardTotal < FCardTop + N then
      FCardTotal := FCardTop + N;
  end;
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
      // Veto je Satz hier (die Datenmenge steht schon darauf)
      if AllowSelectCurrent then
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
  // Gruppiert: Bereich in der Reihenfolge der Ansicht
  if FGrpOn then
  begin
    GroupSelectRange(FromBm);
    Exit;
  end;
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
    Inc(FNoVeto); // schon beim Durchlaufen gefragt
    try
      for I := 0 to Found.Count - 1 do
        FSelected.AddBookmark(Found[I]);
    finally
      Dec(FNoVeto);
    end;
    try
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
  if Button = mbLeft then
    FDownOnRow := FDataLink.Active and MouseCoord(X, Y, C, V) and (DataRow(V) >= FixedRows) and
      (DataRow(V) - FixedRows < LoadedRowCount);
  if CardMode then
  begin
    // Linke Taste waehlt Karte und Feld; die uebrigen wie im Grid
    if Button = mbLeft then
      CardMouseDown(Shift, X, Y)
    else
      inherited ContentMouseDown(Button, Shift, X, Y);
    Exit;
  end;
  OnRow := MultiSelectActive and (Button = mbLeft) and not (ssDouble in Shift) and
    (SizingColAt(X, Y) < 0) and MouseCoord(X, Y, C, V) and (DataRow(V) >= FixedRows) and
    (DataRow(V) - FixedRows < LoadedRowCount);
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
  if (C < FixedCols) and (R <> ActiveDataIndex) then
    GotoDataIndex(R);
  // Wechsel abgelehnt (z.B. Pflichtfeld beim Buchen): Auswahl bleibt
  if not MultiSelectActive or (ActiveDataIndex <> R) then
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
  if not FDataLink.Active or FGrpOn then
    Exit;
  if CardMode then
  begin
    CardSync;
    Exit;
  end;
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
  FCardActive := -1;
  FCardTop := 0;
  if FSelected <> nil then
  begin
    FSelected.FCheckOrder := False;
    FSelected.Clear;
  end;
  HideEditor(False);
  // Formular gehoert zur alten Datenmenge bzw. zum alten Oeffnen
  FormClose(False, False);
  // Filter hingen an einer anderen Datenmenge: dort zuruecksetzen
  if (FFltDS <> nil) and (FFltDS <> FDataLink.DataSet) then
    FilterUnhook;
  BuildColumns;
  // Aktive Filter gelten auch fuer die neue bzw. wieder geoeffnete Datenmenge
  if Value and (FFltDS = nil) and FiltersActive then
    ApplyFilters;
  if Value and FSortFromIndex then
    SyncSortIndicator;
  NotifyViewPosition;
end;

procedure TPPGCustomDBGrid.LayoutChanged;
begin
  if not (csDestroying in ComponentState) then
    BuildColumns;
end;

procedure TPPGCustomDBGrid.DataChanged;
var
  N: Integer;
  DS: TDataSet;
begin
  FSnapValid := False;
  if (csDestroying in ComponentState) or FLayoutBusy or FGrpLoading then
    Exit;
  // Anderer Datensatz (Navigator, Code, Blaettern ueber den Puffer hinaus):
  // der offene Editor gehoert zum alten und wird verworfen
  if EditorMode and (Length(FEditBm) > 0) and FDataLink.Active and
    (FDataLink.DataSet.State = dsBrowse) and
    (FDataLink.DataSet.CompareBookmarks(FEditBm, FDataLink.DataSet.Bookmark) <> 0) then
    HideEditor(False);
  if not EditorMode then
    FEditBm := nil;
  // Gruppiert: alle Saetze im Speicher (neu gelesen nur nach Aenderungen)
  if FGrpOn then
    GroupDataChanged
  else
    RebuildCache;
  // Bearbeitungsformular: Bearbeitung von aussen beendet (Navigator, Code).
  // Anderer bzw. gebuchter neuer Satz: schliessen (die Datenmenge hat die
  // Eingaben ueber UpdateData schon gebucht); derselbe Satz: neu lesen
  // (Cancel von aussen)
  if FFormOpen and (FFormBusy = 0) then
  begin
    DS := FDataLink.DataSet;
    if not FDataLink.Active then
      FormClose(False, False)
    else if DS.State = dsBrowse then
    begin
      if DS.IsEmpty or (Length(FFormBm) = 0) or
        (DS.CompareBookmarks(FFormBm, DS.Bookmark) <> 0) then
      begin
        FormClose(False, False);
        UpdateBufferCount;
        if not FGrpOn then
          RebuildCache;
      end
      else
      begin
        // Cancel/Post von aussen: alle Felder; sonst (Groesse, Puffer) nur
        // die unveraenderten (Werte per Code bleiben)
        FormLoadValues(not FFormReload);
        FFormReload := False;
      end;
    end;
  end;
  if FGrpOn then
    GroupSync
  else
  begin
    // Mindestens eine (ggf. leere) Datenzeile: RowCount > FixedRows
    N := Length(FCache);
    if N < 1 then
      N := 1;
    if RowCount <> FixedRows + N then
      RowCount := FixedRows + N;
    SyncPosition;
  end;
  FormPlace;
  Invalidate;
  CheckFocusedRecord;
  NotifyViewPosition;
end;

procedure TPPGCustomDBGrid.CheckFocusedRecord;
var
  DS: TDataSet;
  B: TBookmark;
  Ins, Changed: Boolean;
begin
  if csDestroying in ComponentState then
    Exit;
  B := nil;
  Ins := False;
  DS := nil;
  if FDataLink.Active then
  begin
    DS := FDataLink.DataSet;
    Ins := DS.State = dsInsert;
    if not Ins and not DS.IsEmpty then
      B := DS.Bookmark;
  end;
  if Ins <> FLastRecIns then
    Changed := True
  else if (Length(B) = 0) or (Length(FLastRecBm) = 0) then
    Changed := Length(B) <> Length(FLastRecBm)
  else
    Changed := DS.CompareBookmarks(B, FLastRecBm) <> 0;
  FLastRecBm := B;
  FLastRecIns := Ins;
  if Changed then
    DoFocusedRecordChanged;
end;

procedure TPPGCustomDBGrid.DoFocusedRecordChanged;
begin
  if Assigned(FOnFocusedRecordChanged) then
    FOnFocusedRecordChanged(Self);
end;

procedure TPPGCustomDBGrid.EditingChanged;
begin
  // Bearbeitung von aussen beendet (Cancel, Post): das Formular liest beim
  // naechsten DataChanged alle Felder neu
  if FFormOpen and (FFormBusy = 0) and FDataLink.Active and not FDataLink.Editing then
    FFormReload := True;
  // Gruppiert: Post/Cancel dieser Bearbeitung liest nur den Satz neu
  if FGrpOn and FDataLink.Active then
  begin
    if FDataLink.DataSet.State = dsEdit then
      FGrpEditBm := FDataLink.DataSet.Bookmark
    else if FDataLink.DataSet.State = dsInsert then
      FGrpEditBm := nil;
  end;
  Invalidate;
end;

procedure TPPGCustomDBGrid.RecordChanged(Field: TField);
begin
  if csDestroying in ComponentState then
    Exit;
  // Nur der aktive Datensatz hat sich geaendert: Zwischenspeicher neu
  if FGrpOn then
    GroupRecordChanged
  else
    RebuildCache;
  // Formular: Felder, die der Anwender nicht geaendert hat, folgen dem Satz
  if FFormOpen and (FFormBusy = 0) then
    FormLoadValues(True);
  Invalidate;
end;

procedure TPPGCustomDBGrid.UpdateData;
begin
  // Datenmenge schreibt (Post): offenen Editor bzw. das Formular uebernehmen
  if EditorMode then
    HideEditor(True);
  if FFormOpen and (FFormBusy = 0) then
    FormWriteValues;
end;

{ ---- Erweiterungspunkte des Grids ---- }

function TPPGCustomDBGrid.CanGroup: Boolean;
begin
  // Gruppieren nur in der Tabelle; ohne Gruppenleiste und Gruppenspalten
  // bleibt alles wie ohne Gruppierung (auch das Kopfmenue)
  Result := not CardMode and (ShowGroupPanel or (Length(CurrentGroupColumns) > 0));
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
  // Gruppiert: Column.Aggregate rechnet das Grid ueber alle Saetze
  if FGrpOn and (C.Aggregate <> agNone) then
  begin
    Result := inherited CachedFooterText(ACol);
    if Assigned(FOnGetFooterText) then
      FOnGetFooterText(Self, TPPGDBGridColumn(C), Result);
    Exit;
  end;
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
  FSnapAll := nil;
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
      // Fuer RowValue in OnGetCellStyle (Druck/Export): alle Felder des Satzes
      if Assigned(OnGetCellStyle) then
      begin
        if N >= Length(FSnapAll) then
          SetLength(FSnapAll, Length(FSnap));
        SetLength(FSnapAll[N], DS.FieldCount);
        for C := 0 to DS.FieldCount - 1 do
          FSnapAll[N][C] := DS.Fields[C].Value;
      end;
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
    if Length(FSnapAll) > N then
      SetLength(FSnapAll, N);
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
  // Gruppiert: alle Saetze sind schon gelesen (Reihenfolge der Gruppen)
  if FGrpOn then
    Exit(inherited TableRowCount);
  EnsureSnapshot;
  Result := Length(FSnap);
end;

function TPPGCustomDBGrid.TableColumn(ACol: Integer): TPPGTableColumnInfo;
begin
  Result := inherited TableColumn(ACol + FixedCols);
end;

function TPPGCustomDBGrid.TableCellText(ACol, ARow: Integer): string;
var
  R, C: Integer;
begin
  if FGrpOn then
  begin
    Result := '';
    R := inherited TableStyleRow(ARow) - FixedRows;
    C := DataCol(ACol + FixedCols) - FixedCols;
    if (R >= 0) and (R < Length(FCache)) and (C >= 0) and (C < Length(FCache[R])) then
      Result := FCache[R][C];
    Exit;
  end;
  EnsureSnapshot;
  if (ARow >= 0) and (ARow < Length(FSnapText)) and (ACol >= 0) and (ACol < Length(FSnapText[ARow])) then
    Result := FSnapText[ARow][ACol]
  else
    Result := '';
end;

function TPPGCustomDBGrid.TableCellValue(ACol, ARow: Integer): Variant;
var
  R, C, DC: Integer;
  F: TField;
  S: string;
begin
  if FGrpOn then
  begin
    // Wie der Schnappschuss: Kaestchen als Wahrheitswert, Nachschlagen als
    // Text, Datum/Zahl als Wert
    Result := Null;
    R := inherited TableStyleRow(ARow) - FixedRows;
    DC := DataCol(ACol + FixedCols);
    C := DC - FixedCols;
    F := FieldOfCol(DC);
    if (F = nil) or (R < 0) or (R >= Length(FCache)) or (C < 0) or (C >= Length(FCache[R])) or
      (C >= Length(FGrpVals[R])) then
      Exit;
    S := FCache[R][C];
    if IsCheckColumn(DC) then
    begin
      if S = CheckStateText(cbChecked) then
        Result := True
      else if S = CheckStateText(cbUnchecked) then
        Result := False;
    end
    else if (ColumnLookup(DC) <> nil) or (F.FieldKind = fkLookup) then
    begin
      if S <> '' then
        Result := S;
    end
    else if VarIsNull(FGrpVals[R][C]) or VarIsEmpty(FGrpVals[R][C]) then
      Result := Null
    else if F.DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] then
      Result := VarAsType(FGrpVals[R][C], varDate)
    else if F.DataType in [ftBoolean, ftLargeint] then
      Result := FGrpVals[R][C]
    else if F.DataType in [ftSmallint, ftInteger, ftWord, ftFloat, ftCurrency, ftBCD,
      ftFMTBcd, ftAutoInc, ftShortint, ftByte, ftLongWord, ftExtended, ftSingle] then
      Result := VarAsType(FGrpVals[R][C], varDouble)
    else
      Result := S;
    Exit;
  end;
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
  // Gruppiert: OnGetCellStyle bekommt die Zeile des Grids (wie am Bildschirm)
  if FGrpOn then
    DoGetCellStyle(DataCol(ACol + FixedCols), inherited TableStyleRow(ARow), gspPrint, Result)
  else
    DoGetCellStyle(DataCol(ACol + FixedCols), ARow, gspPrint, Result);
end;

procedure TPPGCustomDBGrid.DoGetCellStyle(ACol, ARow: Integer; Purpose: TPPGGridStylePurpose;
  var Style: TPPGGridCellStyle);
var
  OldRow, OldSnap: Integer;
begin
  if not Assigned(OnGetCellStyle) then
    Exit;
  // RowValue liest den Satz der gefragten Zeile: Bildschirm = Pufferzeile,
  // Druck/Export = Satz im Schnappschuss
  OldRow := FCtxRow;
  OldSnap := FCtxSnap;
  if Purpose = gspScreen then
  begin
    FCtxRow := ARow - FixedRows;
    FCtxSnap := -1;
  end
  else
  begin
    FCtxRow := -1;
    if FGrpOn then
      FCtxSnap := ARow - FixedRows
    else
      FCtxSnap := ARow;
  end;
  try
    inherited DoGetCellStyle(ACol, ARow, Purpose, Style);
  finally
    FCtxRow := OldRow;
    FCtxSnap := OldSnap;
  end;
end;

function TPPGCustomDBGrid.RowValue(const FieldName: string): Variant;
var
  DS: TDataSet;
  F: TField;
  Old, I: Integer;
begin
  Result := Null;
  if not FDataLink.Active then
    Exit;
  DS := FDataLink.DataSet;
  F := DS.FindField(FieldName);
  if F = nil then
    raise EPPGError.CreateFmt(PPGStr(@SPPGDBFieldNotFound), [FieldName]);
  if FGrpOn then
  begin
    // Gruppiert: gespeicherte Werte des Satzes (aktiver Satz: das Feld)
    if FCtxSnap >= 0 then
      Old := FCtxSnap
    else
      Old := FCtxRow;
    if (Old < 0) or (Old = FGrpActive) or (Old >= Length(FCache)) then
      Exit(F.Value);
    I := DS.Fields.IndexOf(F);
    if (Old < Length(FGrpAll)) and (I >= 0) and (I < Length(FGrpAll[Old])) then
      Exit(FGrpAll[Old][I]);
    for I := 0 to High(FFields) do
      if (FFields[I] = F) and (I < Length(FGrpVals[Old])) then
        Exit(FGrpVals[Old][I]);
    Exit;
  end;
  if FCtxSnap >= 0 then
  begin
    // Druck/Export: Werte aus dem Schnappschuss (Datenmenge steht woanders)
    I := DS.Fields.IndexOf(F);
    if (FCtxSnap < Length(FSnapAll)) and (I >= 0) and (I < Length(FSnapAll[FCtxSnap])) then
      Result := FSnapAll[FCtxSnap][I];
    Exit;
  end;
  if (FCtxRow >= 0) and (FCtxRow < FDataLink.RecordCount) and
    (FCtxRow <> FDataLink.ActiveRecord) then
  begin
    // Bildschirm: Pufferzeile ohne Satzwechsel (wie beim Owner-Draw)
    Old := FDataLink.ActiveRecord;
    FDataLink.ActiveRecord := FCtxRow;
    try
      Result := F.Value;
    finally
      FDataLink.ActiveRecord := Old;
    end;
  end
  else
    Result := F.Value;
end;

function TPPGCustomDBGrid.PrintCellKind(ACol: Integer; out Ctx: TPPGCellKindContext): IPPGCellKind;
begin
  Result := inherited PrintCellKind(ACol + FixedCols, Ctx);
end;

function TPPGCustomDBGrid.ExportAggregate(ACol: Integer): TPPGGridAggregate;
begin
  // Summen rechnet die Datenmenge; gruppiert das Grid (Column.Aggregate)
  if FGrpOn then
    Result := inherited ExportAggregate(ACol + FixedCols)
  else
    Result := agNone;
end;

function TPPGCustomDBGrid.ExportMerges: TArray<TRect>;
begin
  SetLength(Result, 0);
end;

function TPPGCustomDBGrid.ExportOutline: TArray<TPPGOutlineRow>;
begin
  // Gruppiert: Gruppenzeilen wie im Grid
  if FGrpOn then
    Result := inherited ExportOutline
  else
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
  // OnGetCellStyle bekommt die Satznummer (0-basiert), wie beim Druck;
  // gruppiert die Zeile des Grids
  if FGrpOn then
    Result := inherited TableStyleRow(ARow)
  else
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
  // Kartenansicht: Kartenhoehe folgt den sichtbaren Spalten (erst nach
  // RebuildColumnMap bekannt), damit auch der Puffer
  if CardMode and FDataLink.Active and not (csLoading in ComponentState) and
    not FLayoutBusy and (FDataLink.BufferCount <> CardBufferCount) then
  begin
    UpdateBufferCount;
    DataChanged;
  end;
end;

function TPPGCustomDBGrid.RowScrollY: Integer;
begin
  // Der Puffer steht immer oben; die Leiste gehoert der Datenmenge.
  // Gruppiert scrollt das Grid wie TPPGGrid (alle Zeilen geladen)
  if FGrpOn then
    Result := inherited RowScrollY
  else
    Result := 0;
end;

function TPPGCustomDBGrid.RowsContentHeight: Integer;
var
  DS: TDataSet;
  N: Int64;
  V: TRect;
  M: TPPGDBGridCardMetrics;
begin
  if FGrpOn then
    Exit(inherited RowsContentHeight);
  if CardMode then
  begin
    // Alle Kartenzeilen der Datenmenge (ohne RecNo: die geladenen)
    V := ViewRect;
    Result := V.Bottom - V.Top;
    if not FDataLink.Active or (FCardTotal <= 0) then
      Exit;
    M := CardMetrics;
    N := Int64(M.Gap) + Int64((FCardTotal + M.PerRow - 1) div M.PerRow) * M.RowH;
    if N > MaxInt then
      N := MaxInt;
    if N > Result then
      Result := Integer(N);
    Exit;
  end;
  V := GridViewRect;
  Result := V.Bottom - V.Top;
  if not FDataLink.Active then
    Exit;
  DS := FDataLink.DataSet;
  if DS.IsSequenced and (DS.RecordCount > 0) then
  begin
    N := Int64(FixedHeight) + Int64(DS.RecordCount) * DataRowHeight + FFormGap;
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
  // Nur waagerecht: senkrecht bewegt sich die Datenmenge (gruppiert: beide)
  if FGrpOn then
    inherited ScrollCellsTo(X, Y)
  else
    ScrollTo(X, ScrollY);
end;

procedure TPPGCustomDBGrid.Scrolled;
var
  DS: TDataSet;
  RowH, Wanted, Top, Delta: Integer;
begin
  inherited Scrolled;
  if (FSyncing > 0) or not FDataLink.Active or FGrpOn then
    Exit;
  if CardMode then
  begin
    CardScrolled;
    Exit;
  end;
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
    if FDataLink.Active and (R = ActiveDataIndex) and (R < Length(FCache)) then
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
  if (F <> nil) and FDataLink.Active and (ARow - FixedRows = ActiveDataIndex) and
    not IsCheckColumn(ACol) and (ColumnLookup(ACol) = nil) then
    Result := F.Text
  else
    Result := GetCellText(ACol, ARow);
end;

function TPPGCustomDBGrid.CanEditCell(ACol, VRow: Integer): Boolean;
begin
  // Filterzeile: Filtertext je Feldspalte (auch ohne dgEditing und im
  // Formular-Modus; die Datenmenge wird nicht bearbeitet)
  if ShowFilterRow and (VRow = VFixedRows - 1) then
    Exit((ACol >= FixedCols) and (FieldOfCol(ACol) <> nil));
  // Formular-Modus: die Zellen bearbeitet nur das Bearbeitungsformular
  // (auch kein Kaestchen per Klick, kein Einfuegen, kein Entf)
  if FormMode then
    Exit(False);
  Result := CellEditable(ACol, VRow);
end;

function TPPGCustomDBGrid.CellEditable(ACol, VRow: Integer): Boolean;
var
  F: TField;
  C: TPPGDBGridColumn;
  L: TDataSet;
begin
  F := FieldOfCol(ACol);
  // Geladene Zeile (gruppiert: Datenzeile eines Satzes, keine Gruppenzeile)
  if FGrpOn then
    Result := (DataRow(VRow) >= FixedRows) and (DataRow(VRow) - FixedRows < Length(FCache))
  else
    Result := VRow - VisualRow(FixedRows) < Length(FCache);
  Result := Result and not FReadOnly and (dgEditing in FDBOptions) and FDataLink.Active and
    EditAllowedAt(VRow) and
    not FDataLink.ReadOnly and FDataLink.DataSet.CanModify and (F <> nil) and
    FieldEditable(F) and inherited CanEditCell(ACol, VRow);
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
    if FGrpOn then
      GroupListChanged
    else
      RebuildCache;
    Invalidate;
  finally
    FListBusy := False;
  end;
end;

procedure TPPGCustomDBGrid.FillLookupEditor(ACol: Integer);
begin
  FillLookupCombo(InplaceEditor, ACol);
end;

function TPPGCustomDBGrid.LookupHasColumns(ACol: Integer): Boolean;
var
  C: TPPGDBGridColumn;
begin
  C := ColumnLookup(ACol);
  Result := (C <> nil) and (Length(C.ListFieldNames) > 1);
end;

procedure TPPGCustomDBGrid.FillLookupColumns(Combo: TPPGColumnComboBox; ACol: Integer);
var
  Col: TPPGDBGridColumn;
  DS: TDataSet;
  KF, F: TField;
  Names: TArray<string>;
  Flds: array of TField;
  B: TBookmark;
  S, Key: string;
  I, W, Disp: Integer;
  CC: TPPGComboColumn;
  Target: TField;
begin
  Col := ColumnLookup(ACol);
  Target := FieldOfCol(ACol);
  if (Col = nil) or (Target = nil) then
    Exit;
  DS := Col.ListDataSet;
  Names := Col.ListFieldNames;
  Combo.Items.BeginUpdate;
  try
    Combo.Items.Clear;
    Combo.Columns.Clear;
    Combo.Delimiter := #9;
    // Spalte 0: Schluessel (ausgeblendet), dann die Felder aus ListField
    CC := Combo.Columns.Add;
    CC.Title := Col.KeyField;
    CC.Visible := False;
    SetLength(Flds, 0);
    KF := nil;
    if (DS <> nil) and DS.Active then
    begin
      KF := DS.FindField(Col.KeyField);
      for I := 0 to High(Names) do
      begin
        F := DS.FindField(Names[I]);
        if F = nil then
          Continue;
        SetLength(Flds, Length(Flds) + 1);
        Flds[High(Flds)] := F;
        CC := Combo.Columns.Add;
        CC.Title := F.DisplayLabel;
        W := F.DisplayWidth * 7 + 12;
        if W < 40 then
          W := 40;
        if W > 300 then
          W := 300;
        CC.Width := W;
        CC.Alignment := F.Alignment;
      end;
    end;
    if (KF <> nil) and (Length(Flds) > 0) then
    begin
      PPGDBBeginRead;
      DS.DisableControls;
      try
        B := DS.Bookmark;
        try
          DS.First;
          while not DS.Eof do
          begin
            S := KF.AsString;
            for I := 0 to High(Flds) do
              S := S + #9 + StringReplace(Flds[I].AsString, #9, ' ', [rfReplaceAll]);
            Combo.Items.Add(S);
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
    Combo.Items.EndUpdate;
  end;
  // Angezeigt wird das Feld nach ListFieldIndex (wie in der Zelle)
  Disp := 1;
  for I := 0 to High(Flds) do
    if SameText(Flds[I].FieldName, Col.ListResultField) then
      Disp := I + 1;
  Combo.KeyColumn := 0;
  Combo.DisplayColumn := Disp;
  if Target.IsNull then
    Combo.ItemIndex := -1
  else
  begin
    Key := Target.AsString;
    Combo.KeyValue := Key;
  end;
end;

procedure TPPGCustomDBGrid.FillLookupCombo(Editor: TPPGCustomControl; ACol: Integer);
var
  C: TPPGComboBox;
  DS: TDataSet;
  RF, T: TField;
  B: TBookmark;
  S, LK, LR: string;
  Plain: Boolean;
begin
  if Editor is TPPGColumnComboBox then
  begin
    FillLookupColumns(TPPGColumnComboBox(Editor), ACol);
    Exit;
  end;
  if not (Editor is TPPGComboBox) then
    Exit;
  C := TPPGComboBox(Editor);
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
  if (F = nil) or not FDataLink.Active or (ARow - FixedRows <> ActiveDataIndex) then
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
  Ed: TPPGCustomControl;
begin
  if not LookupSource(ACol, DS, LK, LR, T) then
    Exit;
  // Mehrspaltige Auswahl: der Schluessel der gewaehlten Zeile (eindeutig,
  // auch bei gleichen Texten)
  Ed := FWriteEditor;
  if Ed = nil then
    Ed := InplaceEditor;
  if (Ed is TPPGColumnComboBox) and (TPPGColumnComboBox(Ed).ItemIndex >= 0) then
  begin
    if T.AsString = TPPGColumnComboBox(Ed).KeyValue then
      Exit;
    if not FDataLink.Editing and not FDataLink.Edit then
      Exit;
    T.AsString := TPPGColumnComboBox(Ed).KeyValue;
    Exit;
  end;
  if FieldCellText(ACol, FieldOfCol(ACol)) = Value then
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
  // Filterzeile (ARow < 0) gehoert zu keinem Datensatz
  if (ARow >= 0) and FDataLink.Active and (FDataLink.DataSet.State = dsBrowse) then
    FEditBm := FDataLink.DataSet.Bookmark;
end;

function TPPGCustomDBGrid.CellEditorClass(ACol, ARow: Integer;
  Kind: TPPGGridEditorKind): TPPGGridEditorClass;
begin
  // Nachschlage-Spalte mit mehreren Listenfeldern: mehrspaltige Auswahl
  if (Kind = gekCombo) and LookupHasColumns(ACol) then
    Result := TPPGGridColumnCombo
  else
    Result := inherited CellEditorClass(ACol, ARow, Kind);
end;

function TPPGCustomDBGrid.SelectCell(ACol, ARow: Integer): Boolean;
var
  R, OldCtx: Integer;
begin
  if FGrpOn and (FSyncing = 0) and (ARow >= FixedRows) then
  begin
    // Gruppiert: Satz per Lesezeichen (Zeile = Satz)
    R := ARow - FixedRows;
    if R >= Length(FCache) then
      Exit(False);
    OldCtx := FCtxRow;
    FCtxRow := R;
    try
      Result := inherited SelectCell(ACol, ARow);
    finally
      FCtxRow := OldCtx;
    end;
    if Result then
      Result := GroupGoto(R);
    Exit;
  end;
  if (FSyncing = 0) and FDataLink.Active and (ARow >= FixedRows) then
  begin
    R := ARow - FixedRows;
    if R >= FDataLink.RecordCount then
      Exit(False); // leere Fuellzeile
    // OnSelectCell vor dem Satzwechsel (Veto); RowValue liest die Zielzeile
    OldCtx := FCtxRow;
    FCtxRow := R;
    try
      Result := inherited SelectCell(ACol, ARow);
    finally
      FCtxRow := OldCtx;
    end;
    if not Result then
      Exit;
    if R <> FDataLink.ActiveRecord then
    begin
      Inc(FSyncing);
      try
        FDataLink.MoveBy(R - FDataLink.ActiveRecord);
      finally
        Dec(FSyncing);
      end;
    end;
    Exit;
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
  // Sortierpfeil (SortOnHeaderClick): nur die Anzeige; sortieren muss die
  // Datenmenge (OnSorted, z. B. IndexFieldNames)
  if SortOnHeaderClick then
    inherited HeaderClicked(ACol, VRow);
end;

procedure TPPGCustomDBGrid.ContentMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  C, V: Integer;
  Col: TPPGGridColumn;
begin
  inherited ContentMouseUp(Button, Shift, X, Y);
  if (Button = mbLeft) and Assigned(FOnCellClick) and MouseCoord(X, Y, C, V) and
    ((FGrpOn and IsDataRow(V)) or (not FGrpOn and (V >= VisualRow(FixedRows)))) and
    (C >= FixedCols) then
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
  OrigKey, K2: Word;
  OldBm: TBookmark;
begin
  // Audit 7c #1: laeuft nach OnKeyDown (KeyDown der Grid-Basis)
  if not FDataLink.Active or EditorMode then
  begin
    inherited NavigateKey(Key, Shift);
    Exit;
  end;
  // Kartenansicht: Pfeile, Bild und Pos1/Ende bewegen zwischen den Karten
  if CardMode and CardNavigateKey(Key, Shift) then
    Exit;
  // Gruppenkopf: Pfeil links/rechts, +/-, Enter, Leertaste und F2 klappen
  // auf bzw. zu (wie im Grid)
  if FGrpOn and (GroupOfRow(FocusRow) >= 0) and (Shift * [ssCtrl, ssAlt] = []) then
    case Key of
      VK_LEFT, VK_RIGHT, VK_ADD, VK_SUBTRACT, VK_RETURN, VK_SPACE, VK_F2:
        begin
          inherited NavigateKey(Key, Shift);
          Exit;
        end;
    end;
  // Formular-Modus: Enter/F2 oeffnen das Bearbeitungsformular (bzw. holen
  // den Fokus hinein), Esc verwirft es
  if FormMode and (Shift * [ssCtrl, ssAlt] = []) then
    case Key of
      VK_RETURN, VK_F2:
        begin
          if FFormOpen then
            FormFocusTarget(Max(0, FEditPanel.FCurrent))
          else
            ShowEditForm;
          Key := 0;
          Exit;
        end;
      VK_ESCAPE:
        if FFormOpen then
        begin
          HideEditForm(False);
          Key := 0;
          Exit;
        end;
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
        if (ssCtrl in Shift) and (FSelected.Count > 0) and not FReadOnly and FAllowDelete and
          DS.CanModify then
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
      if (Key = VK_DOWN) and (ssShift in Shift) and (DS.State = dsBrowse) and not FGrpOn then
      begin
        DS.Next;
        Key := 0;
      end;
    end;
  end;
  // Gruppiert: die Pfeile bewegen den Fokus in der Ansicht (die Datenmenge
  // folgt per Lesezeichen); am Ende wird kein Satz angehaengt
  if FGrpOn then
    case Key of
      VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT:
        begin
          if (DS.State = dsInsert) and not DS.Modified and ((Key = VK_UP) or (Key = VK_DOWN)) then
          begin
            // Neuer, unveraenderter Satz: hoch verwirft ihn, runter bleibt
            if Key = VK_DOWN then
            begin
              Key := 0;
              Exit;
            end;
            DS.Cancel;
          end
          else
          begin
            K2 := Key;
            inherited NavigateKey(K2, Shift - [ssShift]);
          end;
          Key := 0;
        end;
      VK_HOME, VK_END:
        if ssCtrl in Shift then
        begin
          K2 := Key;
          inherited NavigateKey(K2, Shift - [ssShift]);
          Key := 0;
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
        if DS.Eof and (dgEditing in FDBOptions) and not FReadOnly and FAllowInsert and
          DS.CanModify then
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
      if (Shift = []) and (dgEditing in FDBOptions) and not FReadOnly and FAllowInsert and
        DS.CanModify then
      begin
        DS.Insert;
        Key := 0;
      end;
    VK_DELETE:
      if (ssCtrl in Shift) and not FReadOnly and FAllowDelete and DS.CanModify and
        not (DS.Bof and DS.Eof) then
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
  // Formular-Modus: neuer Satz (Einfg, Pfeil runter am Ende) im Formular
  if FormMode and (Key = 0) and not FFormOpen and ((OrigKey = VK_INSERT) or (OrigKey = VK_DOWN)) and
    FDataLink.Active and (DS.State = dsInsert) then
    ShowEditForm;
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
  DCol, Old, B, Rec, I, OldRec: Integer;
  Col: TPPGGridColumn;
  Fill, Txt: TColor;
begin
  inherited OwnerDrawCell(ACol, VRow, ARow, R, State);
  if not Assigned(FOnDrawColumnCell) or (gdFixed in State) or not FDataLink.Active then
    Exit;
  // Nur echte Datensaetze (keine leere Fuellzeile)
  B := ARow - FixedRows;
  Rec := B;
  if FGrpOn then
  begin
    // Gruppiert: nur Saetze im Puffer der Datenmenge (Feldzugriff im Ereignis)
    if (Rec < 0) or (Rec >= Length(FCache)) then
      Exit;
    B := -1;
    for I := 0 to High(FGrpBufRecs) do
      if FGrpBufRecs[I] = Rec then
        B := I;
    if (B < 0) or (B >= FDataLink.RecordCount) then
      Exit;
  end
  else if (B < 0) or (B >= FDataLink.RecordCount) or (B >= Length(FCache)) then
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
  OldRec := FDrawRec;
  FDrawRow := B;
  FDrawRec := Rec;
  try
    FDataLink.ActiveRecord := B;
    try
      DrawColumnCell(R, DCol - FixedCols, TPPGDBGridColumn(Col), State);
    finally
      FDataLink.ActiveRecord := Old;
    end;
  finally
    FDrawRow := -1;
    FDrawRec := OldRec;
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
  begin
    if FGrpOn then
      R := FDrawRec
    else
      R := FDrawRow;
  end
  else if FDataLink.Active then
    R := ActiveDataIndex
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

{ ---- Kartenansicht ---- }

const
  // Innenabstand der Karte und Mindestbreite des Werts (logische px)
  CardPad = 8;
  CardMinValue = 24;
  CardRadius = 6;

function TPPGCustomDBGrid.CardMode: Boolean;
begin
  Result := FViewStyle = dgvCards;
end;

procedure TPPGCustomDBGrid.SetViewStyle(const Value: TPPGDBGridViewStyle);
begin
  if FViewStyle = Value then
    Exit;
  // Offene Eingabe zuerst uebernehmen (lehnt die Datenmenge ab, bleibt alles)
  HideEditor(True);
  if FFormOpen and not HideEditForm(True) then
    Exit;
  FViewStyle := Value;
  FCardActive := -1;
  if csLoading in ComponentState then
    Exit;
  // Lage gehoert zur alten Ansicht (Tabelle: Lage in der Datenmenge)
  Inc(FSyncing);
  try
    ScrollTo(0, 0);
  finally
    Dec(FSyncing);
  end;
  // Karten gruppieren nicht
  UpdateGroupMode;
  InvalidateGeometry;
  UpdateBufferCount;
  DataChanged;
  Invalidate;
end;

procedure TPPGCustomDBGrid.SetCardWidth(const Value: Integer);
begin
  if FCardWidth = Value then
    Exit;
  FCardWidth := PPGCheckRange(Self, 'CardWidth', Value, 60, 4000);
  if CardMode and not (csLoading in ComponentState) then
  begin
    UpdateBufferCount;
    DataChanged;
  end;
end;

procedure TPPGCustomDBGrid.SetCardSpacing(const Value: Integer);
begin
  if FCardSpacing = Value then
    Exit;
  FCardSpacing := PPGCheckRange(Self, 'CardSpacing', Value, 0, 200);
  if CardMode and not (csLoading in ComponentState) then
  begin
    UpdateBufferCount;
    DataChanged;
  end;
end;

procedure TPPGCustomDBGrid.SetCardAutoWidth(const Value: Boolean);
begin
  if FCardAutoWidth = Value then
    Exit;
  FCardAutoWidth := Value;
  if CardMode and not (csLoading in ComponentState) then
  begin
    UpdateBufferCount;
    DataChanged;
  end;
end;

procedure TPPGCustomDBGrid.SetCardAreaColor(const Value: TColor);
begin
  if FCardAreaColor = Value then
    Exit;
  FCardAreaColor := Value;
  if CardMode then
    Invalidate;
end;

procedure TPPGCustomDBGrid.SetCardLabelWidth(const Value: Integer);
begin
  if FCardLabelWidth = Value then
    Exit;
  FCardLabelWidth := PPGCheckRange(Self, 'CardLabelWidth', Value, 0, 2000);
  if CardMode then
    Invalidate;
end;

function TPPGCustomDBGrid.CardMetrics: TPPGDBGridCardMetrics;
var
  PPI, W, MaxLabel: Integer;
begin
  PPI := ScalePPI;
  Result.View := ViewRect;
  Result.Gap := PPGScale(FCardSpacing, PPI);
  Result.Pad := PPGScale(CardPad, PPI);
  Result.LineH := DataRowHeight;
  Result.Fields := VisibleColCount - FixedCols;
  if Result.Fields < 0 then
    Result.Fields := 0;
  // Breite: hoechstens die Ansicht (schmale Fenster: eine schmalere Karte)
  W := (Result.View.Right - Result.View.Left) - 2 * Result.Gap;
  Result.CardW := PPGScale(FCardWidth, PPI);
  if Result.CardW > W then
    Result.CardW := W;
  if Result.CardW < 2 * Result.Pad + 1 then
    Result.CardW := 2 * Result.Pad + 1;
  Result.CardH := 2 * Result.Pad + Max(1, Result.Fields) * Result.LineH;
  Result.PerRow := ((Result.View.Right - Result.View.Left) - Result.Gap) div
    (Result.CardW + Result.Gap);
  if Result.PerRow < 1 then
    Result.PerRow := 1;
  // CardAutoWidth: die Karten teilen sich die ganze Breite
  if FCardAutoWidth and (W > 0) then
  begin
    W := ((Result.View.Right - Result.View.Left) - Result.Gap) div Result.PerRow - Result.Gap;
    if W > Result.CardW then
      Result.CardW := W;
  end;
  Result.RowH := Result.CardH + Result.Gap;
  // Beschriftung: der Wert behaelt mindestens CardMinValue
  Result.LabelW := PPGScale(FCardLabelWidth, PPI);
  MaxLabel := Result.CardW - 2 * Result.Pad - PPGScale(CardMinValue, PPI);
  if Result.LabelW > MaxLabel then
    Result.LabelW := MaxLabel;
  if Result.LabelW < 0 then
    Result.LabelW := 0;
end;

function TPPGCustomDBGrid.CardsPerRow: Integer;
begin
  if CardMode then
    Result := CardMetrics.PerRow
  else
    Result := 0;
end;

function TPPGCustomDBGrid.CardVisibleRows(const M: TPPGDBGridCardMetrics): Integer;
begin
  // Angeschnittene Zeilen oben und unten mitgezaehlt
  Result := ((M.View.Bottom - M.View.Top) + M.RowH - 1) div M.RowH + 1;
  if Result < 1 then
    Result := 1;
end;

function TPPGCustomDBGrid.CardBufferCount: Integer;
var
  M: TPPGDBGridCardMetrics;
begin
  // Kartenzeilen um den aktiven Satz: so viele darueber und darunter, wie
  // die Ansicht zeigen kann, und eine Reserve (CardPlaceWindow)
  M := CardMetrics;
  Result := M.PerRow * (2 * CardVisibleRows(M) + 2);
  if Result > 4096 then
    Result := 4096;
  if Result < 1 then
    Result := 1;
end;

function TPPGCustomDBGrid.CardClientRect(const M: TPPGDBGridCardMetrics; Slot: Integer): TRect;
var
  X, Y: Int64;
begin
  X := M.View.Left + M.Gap + Int64(Slot mod M.PerRow) * (M.CardW + M.Gap);
  Y := Int64(M.View.Top) + M.Gap + Int64(Slot div M.PerRow) * M.RowH - ScrollY;
  if Y > MaxInt div 2 then
    Y := MaxInt div 2;
  if Y < -(MaxInt div 2) then
    Y := -(MaxInt div 2);
  Result := Rect(Integer(X), Integer(Y), Integer(X) + M.CardW, Integer(Y) + M.CardH);
  if UseRightToLeftAlignment then
    Result := Rect(M.View.Left + M.View.Right - Result.Right, Result.Top,
      M.View.Left + M.View.Right - Result.Left, Result.Bottom);
end;

function TPPGCustomDBGrid.CardFieldRects(const M: TPPGDBGridCardMetrics; const Card: TRect;
  Index: Integer; out LabelR, ValueR: TRect): TRect;
var
  Y: Integer;
begin
  Y := Card.Top + M.Pad + Index * M.LineH;
  Result := Rect(Card.Left + M.Pad, Y, Card.Right - M.Pad, Y + M.LineH);
  if UseRightToLeftAlignment then
  begin
    LabelR := Rect(Result.Right - M.LabelW, Y, Result.Right, Result.Bottom);
    ValueR := Rect(Result.Left, Y, Result.Right - M.LabelW, Result.Bottom);
  end
  else
  begin
    LabelR := Rect(Result.Left, Y, Result.Left + M.LabelW, Result.Bottom);
    ValueR := Rect(Result.Left + M.LabelW, Y, Result.Right, Result.Bottom);
  end;
end;

function TPPGCustomDBGrid.CardRect(ARow: Integer): TRect;
begin
  Result := Rect(0, 0, 0, 0);
  if not CardMode or not FDataLink.Active or (ARow < 0) or (ARow >= Length(FCache)) or
    (ARow >= FDataLink.RecordCount) then
    Exit;
  Result := CardClientRect(CardMetrics, FCardTop + ARow);
end;

function TPPGCustomDBGrid.CardLabel(ACol: Integer): string;
var
  C: TPPGGridColumn;
  F: TField;
begin
  // Wie der Spaltentitel der Tabelle (auch ohne dgTitles)
  C := ColumnOf(ACol);
  F := FieldOfCol(ACol);
  if (C <> nil) and (C.Title <> '') then
    Result := C.Title
  else if F <> nil then
    Result := F.DisplayLabel
  else if C is TPPGDBGridColumn then
    Result := TPPGDBGridColumn(C).FieldName
  else
    Result := '';
  if FShowRequired and (F <> nil) and F.Required then
    Result := Result + ' *';
end;

function TPPGCustomDBGrid.CustomCellLayout: Boolean;
begin
  Result := CardMode;
end;

function TPPGCustomDBGrid.CustomCellRect(ACol, VRow: Integer): TRect;
var
  M: TPPGDBGridCardMetrics;
  R: Integer;
  Card, LabelR, ValueR, Tmp: TRect;
begin
  // Spalten vor den Datenspalten (Indikator): die ganze Karte; Datenspalte:
  // der Wert in ihrer Feldzeile; Kopfzeilen gibt es nicht
  Result := Rect(0, 0, 0, 0);
  R := DataRow(VRow) - FixedRows;
  if not FDataLink.Active or (R < 0) or (R >= Length(FCache)) or
    (R >= FDataLink.RecordCount) then
    Exit;
  M := CardMetrics;
  Card := CardClientRect(M, FCardTop + R);
  if ACol < FixedCols then
    Tmp := Card
  else
  begin
    if ACol - FixedCols >= M.Fields then
      Exit;
    CardFieldRects(M, Card, ACol - FixedCols, LabelR, ValueR);
    Tmp := ValueR;
  end;
  if IntersectRect(Card, Tmp, M.View) then
    Result := Tmp;
end;

function TPPGCustomDBGrid.CustomMouseCoord(X, Y: Integer; out ACol, VRow: Integer): Boolean;
var
  M: TPPGDBGridCardMetrics;
  CX, CY, C, Row, Slot, R, Idx: Integer;
begin
  Result := False;
  ACol := -1;
  VRow := -1;
  if not FDataLink.Active then
    Exit;
  M := CardMetrics;
  if (M.Fields = 0) or not PtInRect(M.View, Point(X, Y)) then
    Exit;
  // Gerechnet wird links -> rechts (Karten bei RTL gespiegelt)
  if UseRightToLeftAlignment then
    X := M.View.Left + M.View.Right - X - 1;
  CX := X - M.View.Left - M.Gap;
  CY := Y - M.View.Top + ScrollY - M.Gap;
  if (CX < 0) or (CY < 0) then
    Exit;
  C := CX div (M.CardW + M.Gap);
  if (C >= M.PerRow) or (CX mod (M.CardW + M.Gap) >= M.CardW) then
    Exit; // Abstand zwischen den Karten
  Row := CY div M.RowH;
  if CY mod M.RowH >= M.CardH then
    Exit;
  Slot := Row * M.PerRow + C;
  R := Slot - FCardTop;
  if (R < 0) or (R >= Length(FCache)) or (R >= FDataLink.RecordCount) then
    Exit;
  // Feldzeile unter der Maus (Innenabstand zaehlt zur naechsten Zeile)
  Idx := (CY mod M.RowH - M.Pad) div M.LineH;
  if CY mod M.RowH < M.Pad then
    Idx := 0;
  if Idx >= M.Fields then
    Idx := M.Fields - 1;
  ACol := FixedCols + Idx;
  VRow := VisualRow(FixedRows + R);
  Result := VRow >= 0;
end;

procedure TPPGCustomDBGrid.CustomMakeCellVisible(ACol, VRow: Integer);
var
  M: TPPGDBGridCardMetrics;
  R, ViewH, Top, Bottom, Y: Integer;
begin
  if (FCardNoReveal > 0) or not FDataLink.Active then
    Exit;
  R := DataRow(VRow) - FixedRows;
  if (R < 0) or (R >= FDataLink.RecordCount) then
    Exit;
  M := CardMetrics;
  ViewH := M.View.Bottom - M.View.Top;
  Top := M.Gap + ((FCardTop + R) div M.PerRow) * M.RowH;
  Bottom := Top + M.CardH;
  // Hoehere Karte als die Ansicht: nur die Feldzeile zeigen
  if (M.CardH + 2 * M.Gap > ViewH) and (ACol >= FixedCols) and (ACol - FixedCols < M.Fields) then
  begin
    Top := Top + M.Pad + (ACol - FixedCols) * M.LineH;
    Bottom := Top + M.LineH;
    if ACol = FixedCols then
      Dec(Top, M.Pad);
  end;
  Y := ScrollY;
  if Top - M.Gap < Y then
    Y := Top - M.Gap
  else if Bottom + M.Gap > Y + ViewH then
    Y := Min(Bottom + M.Gap - ViewH, Top - M.Gap);
  if Y < 0 then
    Y := 0;
  if Y = ScrollY then
    Exit;
  // Kein Satzwechsel durch dieses Scrollen (Scrolled)
  Inc(FSyncing);
  try
    ScrollTo(0, Y);
  finally
    Dec(FSyncing);
  end;
end;

function TPPGCustomDBGrid.CardActiveInView: Boolean;
var
  M: TPPGDBGridCardMetrics;
  Tmp: TRect;
begin
  M := CardMetrics;
  Result := IntersectRect(Tmp, CardClientRect(M, FCardTop + FDataLink.ActiveRecord), M.View);
end;

procedure TPPGCustomDBGrid.CardSync;
var
  A, VR: Integer;
  Quiet: Boolean;
begin
  if not FDataLink.Active then
    Exit;
  Inc(FSyncing);
  try
    // Inhaltshoehe neu (Anzahl Saetze, Kartengroesse)
    InvalidateGeometry;
    EnsureGeometry;
    A := FCardTop + FDataLink.ActiveRecord;
    // Nur ein anderer Satz holt seine Karte ins Bild, und nicht, wenn der
    // Wechsel vom Scrollen kommt (die Lage hat der Anwender bestimmt). Ist die
    // aktive Karte ganz aus dem Bild (andere Groesse, weniger Saetze), kommt
    // sie ebenfalls zurueck.
    Quiet := (FCardKeepScroll > 0) or ((A = FCardActive) and CardActiveInView);
    FCardActive := A;
    if FixedRows + FDataLink.ActiveRecord < RowCount then
    begin
      VR := VisualRow(FixedRows + FDataLink.ActiveRecord);
      if Quiet then
        Inc(FCardNoReveal);
      try
        MoveFocus(FocusCol, VR, False, False);
      finally
        if Quiet then
          Dec(FCardNoReveal);
      end;
    end;
  finally
    Dec(FSyncing);
  end;
  CardPlaceWindow;
end;

procedure TPPGCustomDBGrid.CardPlaceWindow;
var
  DS: TDataSet;
  M: TPPGDBGridCardMetrics;
  N, Cnt, A, ARow, VisRows, LastRow, NeedFirst, NeedLast, FirstFull, LastFull, WantTop: Integer;
begin
  // Nur mit RecNo und ausserhalb einer Bearbeitung (MoveBy wuerde buchen)
  if (FCardPlacing > 0) or not FDataLink.Active or not FCardSeq then
    Exit;
  DS := FDataLink.DataSet;
  if DS.State <> dsBrowse then
    Exit;
  Cnt := FDataLink.RecordCount;
  if Cnt >= FCardTotal then
    Exit; // alle Saetze geladen
  N := FDataLink.BufferCount;
  M := CardMetrics;
  VisRows := CardVisibleRows(M);
  A := FCardTop + FDataLink.ActiveRecord;
  ARow := A div M.PerRow;
  LastRow := (FCardTotal - 1) div M.PerRow;
  // Geladen sein muessen alle Kartenzeilen, die mit der aktiven Karte im Bild
  // stehen koennen, und zwar vollstaendig (sonst fehlen Karten in der Zeile)
  NeedFirst := Max(0, ARow - VisRows);
  NeedLast := Min(LastRow, ARow + VisRows);
  FirstFull := (FCardTop + M.PerRow - 1) div M.PerRow;
  if FCardTop + Cnt >= FCardTotal then
    LastFull := LastRow
  else
    LastFull := (FCardTop + Cnt) div M.PerRow - 1;
  if (FirstFull <= NeedFirst) and (LastFull >= NeedLast) then
    Exit;
  WantTop := NeedFirst * M.PerRow;
  if WantTop + N > FCardTotal then
    WantTop := Max(0, FCardTotal - N);
  if (WantTop = FCardTop) or (A - WantTop < 0) or (A - WantTop >= N) then
    Exit;
  // Puffer verschieben, der Satz bleibt: fuer andere PPGlow-Controls nur Lesen
  Inc(FCardPlacing);
  try
    PPGDBBeginRead;
    DS.DisableControls;
    try
      MoveToBufferIndex(DS, A - WantTop);
    finally
      DS.EnableControls; // loest DataChanged aus (neue Lage)
      PPGDBEndRead;
    end;
  finally
    Dec(FCardPlacing);
  end;
end;

procedure TPPGCustomDBGrid.CardScrolled;
var
  M: TPPGDBGridCardMetrics;
  A, Col, Top, Bottom, ViewH, Y, R, NewA: Integer;
begin
  // Ohne RecNo bleibt die Ansicht bei den geladenen Karten
  if not FCardSeq or (FCardTotal <= 0) or (FDataLink.RecordCount = 0) then
    Exit;
  M := CardMetrics;
  ViewH := M.View.Bottom - M.View.Top;
  Y := ScrollY;
  A := FCardTop + FDataLink.ActiveRecord;
  Col := A mod M.PerRow;
  Top := M.Gap + (A div M.PerRow) * M.RowH;
  Bottom := Top + M.CardH;
  if (Bottom > Y) and (Top < Y + ViewH) then
    Exit; // aktive Karte noch im Bild
  if Bottom <= Y then
  begin
    // Nach unten gescrollt: oberste ganz sichtbare Kartenzeile
    R := (Y - M.Gap + M.RowH - 1) div M.RowH;
    if (Y < M.Gap) or (M.Gap + R * M.RowH + M.CardH > Y + ViewH) then
      R := Max(0, (Y - M.Gap) div M.RowH);
  end
  else
  begin
    // Nach oben gescrollt: unterste ganz sichtbare Kartenzeile
    R := (Y + ViewH - M.Gap - M.CardH) div M.RowH;
    if (R < 0) or (M.Gap + R * M.RowH < Y) then
      R := Max(0, (Y + ViewH - 1 - M.Gap) div M.RowH);
  end;
  R := EnsureRange(R, 0, (FCardTotal - 1) div M.PerRow);
  NewA := Min(R * M.PerRow + Col, FCardTotal - 1);
  if NewA = A then
    Exit;
  Inc(FCardKeepScroll);
  try
    if Abs(NewA - A) > FDataLink.BufferCount then
      FDataLink.DataSet.RecNo := NewA + 1
    else
      FDataLink.MoveBy(NewA - A);
  finally
    Dec(FCardKeepScroll);
  end;
end;

procedure TPPGCustomDBGrid.CardSelectAfterMove(const OldBm: TBookmark; Shift: TShiftState;
  Step: Boolean);
begin
  if not MultiSelectActive then
    Exit;
  if ssShift in Shift then
  begin
    // Nachbarsatz: erweitern bzw. verkleinern; sonst Bereich vom Anker
    if Step then
      ExtendByStep(OldBm)
    else
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
    end;
  end
  else if ssCtrl in Shift then
    // Strg+Pfeil bewegt nur (danach Strg+Leertaste)
  else
  begin
    FSelected.Clear;
    FAnchor := FSelected.CurrentBookmark;
  end;
end;

function TPPGCustomDBGrid.CardNavigateKey(var Key: Word; Shift: TShiftState): Boolean;
var
  DS: TDataSet;
  M: TPPGDBGridCardMetrics;
  K: Word;
  A, Page: Integer;
  OldBm: TBookmark;
begin
  Result := False;
  K := Key;
  if UseRightToLeftAlignment then
    case K of
      VK_LEFT: K := VK_RIGHT;
      VK_RIGHT: K := VK_LEFT;
    end;
  if (ssAlt in Shift) or not ((K = VK_LEFT) or (K = VK_RIGHT) or (K = VK_UP) or
    (K = VK_DOWN) or (K = VK_PRIOR) or (K = VK_NEXT) or (K = VK_HOME) or (K = VK_END)) then
    Exit;
  Result := True;
  Key := 0;
  DS := FDataLink.DataSet;
  // Neuer, unveraenderter Satz verschwindet beim Verlassen (wie die Tabelle)
  if (DS.State = dsInsert) and not DS.Modified then
  begin
    DS.Cancel;
    Exit;
  end;
  M := CardMetrics;
  A := FCardTop + FDataLink.ActiveRecord;
  Page := Max(1, (M.View.Bottom - M.View.Top) div M.RowH) * M.PerRow;
  OldBm := nil;
  if MultiSelectActive then
    OldBm := FSelected.CurrentBookmark;
  case K of
    VK_LEFT: DS.Prior;
    VK_RIGHT: DS.Next;
    VK_UP:
      // Nur, wenn es darueber eine Karte gibt
      if not FCardSeq or (A >= M.PerRow) then
        FDataLink.MoveBy(-M.PerRow);
    VK_DOWN:
      if not FCardSeq or (A + M.PerRow < FCardTotal) then
        FDataLink.MoveBy(M.PerRow)
      else if A div M.PerRow < (FCardTotal - 1) div M.PerRow then
        DS.Last; // Zeile darunter ist kuerzer: letzte Karte
    VK_PRIOR: FDataLink.MoveBy(-Page);
    VK_NEXT: FDataLink.MoveBy(Page);
    VK_HOME: DS.First;
    VK_END: DS.Last;
  end;
  CardSelectAfterMove(OldBm, Shift, (K = VK_LEFT) or (K = VK_RIGHT));
end;

procedure TPPGCustomDBGrid.CardMouseDown(Shift: TShiftState; X, Y: Integer);
var
  C, V, R, Target, DCol: Integer;
  OldBm: TBookmark;
  K: IPPGCellKind;
  Act: TPPGCellAction;
  NewText: string;
  CR: TRect;
begin
  if CanFocus and not Focused and HandleAllocated and IsWindowVisible(Handle) and
    IsWindowEnabled(Handle) and not (csDesigning in ComponentState) then
    SetFocus;
  if not FDataLink.Active or not MouseCoord(X, Y, C, V) then
    Exit;
  R := DataRow(V) - FixedRows;
  if (R < 0) or (R >= FDataLink.RecordCount) then
    Exit;
  OldBm := nil;
  if MultiSelectActive then
    OldBm := FSelected.CurrentBookmark;
  // Satz der Karte (Lage in der Anordnung: der Puffer kann sich verschieben)
  Target := FCardTop + R;
  if R <> FDataLink.ActiveRecord then
    FDataLink.MoveBy(R - FDataLink.ActiveRecord);
  if FCardTop + FDataLink.ActiveRecord <> Target then
    Exit; // Wechsel abgelehnt (z.B. Pflichtfeld beim Buchen)
  // Feld unter der Maus wird Fokusfeld (wie die Fokuszelle der Tabelle)
  V := VisualRow(FixedRows + FDataLink.ActiveRecord);
  MoveFocus(C, V, False, True);
  // Mehrfachauswahl wie in der Tabelle (Strg schaltet um, Umschalt: Bereich)
  if MultiSelectActive and not (ssDouble in Shift) then
  begin
    if ssShift in Shift then
      CardSelectAfterMove(OldBm, Shift, False)
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
  // Zellart (Kaestchen, Link ...): Klick auf den Wert bedient sie
  if Shift * [ssShift, ssCtrl] <> [] then
    Exit;
  DCol := DataCol(C);
  K := KindOf(DCol);
  if K = nil then
    Exit;
  CR := CellRect(C, V);
  if not PtInRect(CR, Point(X, Y)) then
    Exit;
  Act := K.CellClick(KindContext(DCol), CR, Point(X, Y), GetCellText(DCol, DataRow(V)), NewText);
  if Act <> caNone then
    DoCellAction(Act, DCol, V, NewText);
end;

procedure TPPGCustomDBGrid.EditorArrowMove(Down: Boolean);
begin
  // Karte: Pfeil hoch/runter im Editor wechselt das Feld, nicht den Satz
  if not CardMode then
  begin
    inherited EditorArrowMove(Down);
    Exit;
  end;
  if Down then
    MoveFocus(FocusCol + 1, FocusRow, False, True)
  else
    MoveFocus(FocusCol - 1, FocusRow, False, True);
end;

procedure TPPGCustomDBGrid.PaintCustomLayout(const ACanvas: IPPGCanvas; const View: TRect);
var
  PC: TPPGGridPaintColors;
  M: TPPGDBGridCardMetrics;
  I, J, N, VC, DC, VR, D, Radius, BW, Margin, TextPad: Integer;
  Card, RowR, LabelR, ValueR, TR: TRect;
  CardFill, CardText, VFill, VText, LabelColor, LineColor, BC: TColor;
  State, FState: TGridDrawState;
  St: TPPGGridCellStyle;
  S: string;
  Col: TPPGGridColumn;
  K: IPPGCellKind;
  Ctx: TPPGCellKindContext;
  Al: TAlignment;
  HasStyles, Active: Boolean;
begin
  // Paint liest nur den Zwischenspeicher (Texte, Markierungen); Farben aus
  // dem Theme wie in der Tabelle (Dunkelmodus, Hochkontrast, Styles)
  PC := PaintColors;
  // Flaeche: CardAreaColor nur, wenn das Grid eigene Farben zeigt (nicht im
  // Hochkontrast)
  if (FCardAreaColor <> clDefault) and (FCardAreaColor <> clNone) and PC.UseColors then
    ACanvas.FillRoundRect(View, 0, ColorToRGB(FCardAreaColor), 255)
  else
    ACanvas.FillRoundRect(View, 0, PC.Header, 255);
  if not FDataLink.Active then
    Exit;
  M := CardMetrics;
  Radius := PPGScale(CardRadius, ScalePPI);
  Margin := PPGScale(4, ScalePPI);
  TextPad := PPGScale(CellPad, ScalePPI);
  HasStyles := (ConditionalFormats.Count > 0) or Assigned(OnGetCellStyle);
  N := Min(Length(FCache), FDataLink.RecordCount);
  for I := 0 to N - 1 do
  begin
    Card := CardClientRect(M, FCardTop + I);
    if not NeedsPaint(Card, Margin) then
      Continue;
    VR := VisualRow(FixedRows + I);
    D := FixedRows + I;
    Active := I = FDataLink.ActiveRecord;
    State := [];
    if (I < Length(FMarks)) and FMarks[I] then
      Include(State, gdSelected);
    // Flaeche der Karte ohne Spaltenstil (Zebra, Hover, Mehrfachauswahl)
    CellDrawColors(-1, VR, State, CardFill, CardText);
    ACanvas.FillRoundRect(Card, Radius, CardFill, 255);
    if PC.UseColors then
    begin
      LabelColor := PPGBlendColor(CardText, CardFill, 0.38);
      LineColor := PPGBlendColor(PC.Line, CardFill, 0.4);
    end
    else
    begin
      LabelColor := CardText;
      LineColor := PC.Line;
    end;
    for J := 0 to M.Fields - 1 do
    begin
      VC := FixedCols + J;
      DC := DataCol(VC);
      RowR := CardFieldRects(M, Card, J, LabelR, ValueR);
      if not NeedsPaint(RowR, Margin) then
        Continue;
      FState := State;
      if Active and (VC = FocusCol) and Focused then
        Include(FState, gdFocused);
      CellDrawColors(VC, VR, FState, VFill, VText);
      S := '';
      if (DC - FixedCols >= 0) and (DC - FixedCols < Length(FCache[I])) then
        S := FCache[I][DC - FixedCols];
      St.Reset;
      if HasStyles then
        St := CellStyle(DC, D, S);
      if St.Fill <> clNone then
        VFill := St.Fill;
      if St.TextColor <> clNone then
        VText := St.TextColor;
      if VFill <> CardFill then
        ACanvas.FillRoundRect(ValueR, 0, VFill, 255);
      // Beschriftung
      if (M.LabelW > 0) and not IsRectEmpty(LabelR) then
        ACanvas.DrawText(LabelR, CardLabel(DC), Font, LabelColor,
          DrawTextBiDiModeFlags(TPPGCellPainter.TextFlags(taLeftJustify)));
      // Wert: Zellart (Kaestchen ...) bzw. Text, nur mit DefaultDrawing
      Col := ColumnOf(DC);
      K := nil;
      if DefaultDrawing then
        K := KindOf(DC);
      if K <> nil then
      begin
        Ctx := KindContext(DC);
        Ctx.Canvas := ACanvas;
        Ctx.TextColor := VText;
        Ctx.FillColor := VFill;
        K.PaintCell(Ctx, ValueR, S);
      end
      else if DefaultDrawing and (S <> '') then
      begin
        TR := ValueR;
        InflateRect(TR, -TextPad, 0);
        if Col <> nil then
          Al := Col.Alignment
        else
          Al := taLeftJustify;
        ACanvas.DrawText(TR, S, CellFont(Col, St, []), VText,
          DrawTextBiDiModeFlags(TPPGCellPainter.TextFlags(Al)));
      end;
      // Linie zwischen den Feldzeilen (dgRowLines)
      if (dgRowLines in FDBOptions) and (J < M.Fields - 1) then
        ACanvas.FillRoundRect(Rect(RowR.Left, RowR.Bottom - 1, RowR.Right, RowR.Bottom), 0,
          LineColor, 255);
      // Fokusfeld der aktiven Karte
      if gdFocused in FState then
        ACanvas.FrameRoundRect(ValueR, PPGScale(3, ScalePPI), Max(1, PPGScale(1, ScalePPI)),
          PC.FocusFrame, 255);
      // Owner-Draw (OnDrawCell, OnDrawColumnCell) mit dem Wert als Zelle
      if OwnerDrawAssigned then
        DrawCell(ACanvas, VC, VR, ValueR);
    end;
    // Rand: aktive Karte in der Akzentfarbe (ohne Fokus gedaempft)
    if Active then
    begin
      BW := Max(2, PPGScale(2, ScalePPI));
      if Focused or not PC.UseColors then
        BC := PC.Accent
      else
        BC := PPGBlendColor(PC.Line, PC.Accent, 0.5);
    end
    else
    begin
      BW := Max(1, PPGScale(1, ScalePPI));
      BC := PC.Line;
    end;
    ACanvas.FrameRoundRect(Card, Radius, BW, BC, 255);
  end;
end;

{ ---- Bearbeitungsformular in der Zeile ---- }

const
  // Masse des Formulars (logische px)
  FormPad = 10;        // Rand innen
  FormVGap = 6;        // Abstand zwischen den Zeilen des Rasters
  FormHGap = 16;       // Abstand zwischen den Spalten des Rasters
  FormLabelGap = 8;    // Beschriftung -> Editor
  FormEditorMinH = 28; // Mindesthoehe eines Editors
  FormButtonW = 110;
  FormButtonH = 30;
  FormButtonGap = 8;
  FormMinGap = 24;     // kleinste Hoehe im Grid (sonst scrollt das Formular)

{ TPPGDBGridEditFormOptions }

constructor TPPGDBGridEditFormOptions.Create(AGrid: TPPGCustomDBGrid);
begin
  inherited Create;
  FGrid := AGrid;
  FColumnCount := 2;
  FLabelWidth := 120;
  FShowButtons := True;
end;

function TPPGDBGridEditFormOptions.GetOwner: TPersistent;
begin
  Result := FGrid;
end;

procedure TPPGDBGridEditFormOptions.Assign(Source: TPersistent);
begin
  if Source is TPPGDBGridEditFormOptions then
  begin
    FColumnCount := TPPGDBGridEditFormOptions(Source).FColumnCount;
    FLabelWidth := TPPGDBGridEditFormOptions(Source).FLabelWidth;
    FShowButtons := TPPGDBGridEditFormOptions(Source).FShowButtons;
    Changed;
  end
  else
    inherited Assign(Source);
end;

procedure TPPGDBGridEditFormOptions.Changed;
begin
  if FGrid <> nil then
    FGrid.EditFormOptionsChanged;
end;

procedure TPPGDBGridEditFormOptions.SetColumnCount(const Value: Integer);
begin
  if FColumnCount = Value then
    Exit;
  FColumnCount := PPGCheckRange(Self, 'ColumnCount', Value, 1, 8);
  Changed;
end;

procedure TPPGDBGridEditFormOptions.SetLabelWidth(const Value: Integer);
begin
  if FLabelWidth = Value then
    Exit;
  FLabelWidth := PPGCheckRange(Self, 'LabelWidth', Value, 0, 1000);
  Changed;
end;

procedure TPPGDBGridEditFormOptions.SetShowButtons(const Value: Boolean);
begin
  if FShowButtons = Value then
    Exit;
  FShowButtons := Value;
  Changed;
end;

{ TPPGDBGridEditForm }

constructor TPPGDBGridEditForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ShowCaption := False;
  NoFrame := True;
  AutoScroll := True;
  TabStop := False;
  FCurrent := -1;
  FArrangedW := -1;
  // Name fuer Screenreader (gezeichnet wird die Beschriftung nicht)
  Caption := PPGStr(@SPPGDBGridEditForm);
  FApply := TPPGButton.Create(Self);
  FApply.Parent := Self;
  FApply.Caption := PPGStr(@SPPGDBGridEditFormApply);
  FApply.OnClick := ApplyClick;
  FCancel := TPPGButton.Create(Self);
  FCancel.Parent := Self;
  FCancel.Caption := PPGStr(@SPPGDlgCancel);
  FCancel.OnClick := CancelClick;
end;

procedure TPPGDBGridEditForm.ClearItems;
var
  I: Integer;
begin
  for I := 0 to High(FItems) do
    FItems[I].Editor.Free;
  SetLength(FItems, 0);
  SetLength(FGroups, 0);
  FCurrent := -1;
  FArrangedW := -1;
end;

function TPPGDBGridEditForm.ItemCount: Integer;
begin
  Result := Length(FItems);
end;

function TPPGDBGridEditForm.ItemDataCol(I: Integer): Integer;
begin
  if (I < 0) or (I >= Length(FItems)) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [I, Length(FItems) - 1]);
  Result := FItems[I].DataCol;
end;

function TPPGDBGridEditForm.ItemEditor(I: Integer): TPPGCustomControl;
begin
  if (I < 0) or (I >= Length(FItems)) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [I, Length(FItems) - 1]);
  Result := FItems[I].Editor;
end;

procedure TPPGDBGridEditForm.ItemCell(I: Integer; out ACell, ARow, ASpan: Integer);
begin
  if (I < 0) or (I >= Length(FItems)) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [I, Length(FItems) - 1]);
  ACell := FItems[I].Cell;
  ARow := FItems[I].Row;
  ASpan := FItems[I].Span;
end;

function TPPGDBGridEditForm.ItemLabelRect(I: Integer): TRect;
var
  DX, DY: Integer;
begin
  if (I < 0) or (I >= Length(FItems)) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [I, Length(FItems) - 1]);
  // Beschriftung wandert mit dem Editor (Scrollen verschiebt die Kinder)
  Result := FItems[I].LabelR;
  if IsRectEmpty(Result) then
    Exit;
  DX := FItems[I].Editor.Left - FItems[I].EditorR.Left;
  DY := FItems[I].Editor.Top - FItems[I].EditorR.Top;
  OffsetRect(Result, DX, DY);
end;

function TPPGDBGridEditForm.ItemRowSpan(I: Integer): Integer;
begin
  if (I < 0) or (I >= Length(FItems)) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [I, Length(FItems) - 1]);
  Result := FItems[I].RowSpan;
end;

function TPPGDBGridEditForm.GroupCount: Integer;
begin
  Result := Length(FGroups);
end;

function TPPGDBGridEditForm.GroupCaption(I: Integer): string;
begin
  if (I < 0) or (I >= Length(FGroups)) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [I, Length(FGroups) - 1]);
  Result := FGroups[I].Caption;
end;

function TPPGDBGridEditForm.GroupRow(I: Integer): Integer;
begin
  if (I < 0) or (I >= Length(FGroups)) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [I, Length(FGroups) - 1]);
  Result := FGroups[I].Row;
end;

function TPPGDBGridEditForm.GroupRect(I: Integer): TRect;
var
  F: Integer;
begin
  if (I < 0) or (I >= Length(FGroups)) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [I, Length(FGroups) - 1]);
  // Ueberschrift wandert mit den Editoren (Scrollen verschiebt die Kinder)
  Result := FGroups[I].R;
  F := FGroups[I].FirstItem;
  if IsRectEmpty(Result) or (F < 0) or (F >= Length(FItems)) then
    Exit;
  OffsetRect(Result, FItems[F].Editor.Left - FItems[F].EditorR.Left,
    FItems[F].Editor.Top - FItems[F].EditorR.Top);
end;

function TPPGDBGridEditForm.TargetOfControl(C: TControl): Integer;
var
  I: Integer;
begin
  Result := -1;
  // Bis zum direkten Kind des Formulars (inneres Feld eines Editors)
  while (C <> nil) and (C.Parent <> Self) do
    C := C.Parent;
  if C = nil then
    Exit;
  for I := 0 to High(FItems) do
    if FItems[I].Editor = C then
      Exit(I);
  if C = FApply then
    Result := Length(FItems)
  else if C = FCancel then
    Result := Length(FItems) + 1;
end;

function TPPGDBGridEditForm.TargetControl(T: Integer): TWinControl;
begin
  if (T >= 0) and (T < Length(FItems)) then
    Result := FItems[T].Editor
  else if T = Length(FItems) then
    Result := FApply
  else if T = Length(FItems) + 1 then
    Result := FCancel
  else
    Result := nil;
end;

procedure TPPGDBGridEditForm.EditorChange(Sender: TObject);
var
  I: Integer;
begin
  if (FLoading > 0) or (FGrid = nil) or not (Sender is TControl) then
    Exit;
  I := TargetOfControl(TControl(Sender));
  if (I >= 0) and (I < Length(FItems)) then
    FGrid.FormEditorChanged(I);
end;

procedure TPPGDBGridEditForm.EditorEnter(Sender: TObject);
var
  T: Integer;
begin
  if Sender is TControl then
  begin
    T := TargetOfControl(TControl(Sender));
    if T >= 0 then
      FCurrent := T;
  end;
end;

procedure TPPGDBGridEditForm.EditorEllipsis(Sender: TObject);
var
  I: Integer;
begin
  if (FGrid = nil) or not (Sender is TControl) then
    Exit;
  I := TargetOfControl(TControl(Sender));
  if (I >= 0) and (I < Length(FItems)) then
    FGrid.FormEllipsis(I);
end;

procedure TPPGDBGridEditForm.ApplyClick(Sender: TObject);
begin
  if FGrid <> nil then
    FGrid.HideEditForm(True);
end;

procedure TPPGDBGridEditForm.CancelClick(Sender: TObject);
begin
  if FGrid <> nil then
    FGrid.HideEditForm(False);
end;

procedure TPPGDBGridEditForm.CMChildKey(var Message: TCMChildKey);
var
  T: Integer;
  Shift: TShiftState;
begin
  // Tab, Enter und Esc der Editoren und Schaltflaechen gehoeren dem Formular
  // (kommen vor der Dialog-Navigation des Fensters an)
  if (FGrid <> nil) and ((Message.CharCode = VK_TAB) or (Message.CharCode = VK_RETURN) or
    (Message.CharCode = VK_ESCAPE)) then
  begin
    T := TargetOfControl(Message.Sender);
    // Mehrzeiliges Feld: Enter ist ein Zeilenumbruch (Strg+Enter uebernimmt)
    if (T >= 0) and (T < Length(FItems)) and (FItems[T].Editor is TPPGCustomMemo) and
      (Message.CharCode = VK_RETURN) and (GetKeyState(VK_CONTROL) >= 0) then
      T := -1;
    if T >= 0 then
    begin
      Shift := [];
      if GetKeyState(VK_SHIFT) < 0 then
        Include(Shift, ssShift);
      if GetKeyState(VK_CONTROL) < 0 then
        Include(Shift, ssCtrl);
      if GetKeyState(VK_MENU) < 0 then
        Include(Shift, ssAlt);
      FCurrent := T;
      if FGrid.EditFormKey(Message.CharCode, Shift) then
      begin
        Message.Result := 1;
        Exit;
      end;
    end;
  end;
  inherited;
end;

function TPPGDBGridEditForm.GetBackgroundColor: TColor;
var
  Text, Line, Accent, LabelColor: TColor;
begin
  if FGrid = nil then
    Exit(inherited GetBackgroundColor);
  FGrid.EditFormColors(Result, Text, Line, Accent, LabelColor);
end;

function TPPGDBGridEditForm.GetChildBackground(Child: TControl; out ColorTop,
  ColorBottom: TColor): Boolean;
begin
  // Ecken der Editoren: einfarbige Flaeche des Formulars
  if FGrid = nil then
    Exit(inherited GetChildBackground(Child, ColorTop, ColorBottom));
  ColorTop := GetBackgroundColor;
  ColorBottom := ColorTop;
  Result := True;
end;

procedure TPPGDBGridEditForm.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  Fill, Text, Line, Accent, LabelColor: TColor;
  I, BW: Integer;
  R: TRect;
begin
  if FGrid = nil then
  begin
    inherited DoPaint(ACanvas, ClientR);
    Exit;
  end;
  FGrid.EditFormColors(Fill, Text, Line, Accent, LabelColor);
  ACanvas.FillRoundRect(ClientR, 0, Fill, 255);
  // Linien oben und unten, Akzent an der Seite (wie die aktive Zeile)
  ACanvas.FillRoundRect(Rect(ClientR.Left, ClientR.Top, ClientR.Right, ClientR.Top + 1), 0,
    Line, 255);
  ACanvas.FillRoundRect(Rect(ClientR.Left, ClientR.Bottom - 1, ClientR.Right, ClientR.Bottom), 0,
    Line, 255);
  BW := Max(2, PPGScale(3, ScalePPI));
  if UseRightToLeftAlignment then
    R := Rect(ClientR.Right - BW, ClientR.Top, ClientR.Right, ClientR.Bottom)
  else
    R := Rect(ClientR.Left, ClientR.Top, ClientR.Left + BW, ClientR.Bottom);
  ACanvas.FillRoundRect(R, 0, Accent, 255);
  // Abschnitts-Ueberschriften: Text in der Akzentfarbe, Linie darunter
  for I := 0 to High(FGroups) do
  begin
    R := GroupRect(I);
    if IsRectEmpty(R) or not NeedsPaint(R) then
      Continue;
    ACanvas.DrawText(R, FGroups[I].Caption, Font, Accent,
      DrawTextBiDiModeFlags(TPPGCellPainter.TextFlags(taLeftJustify)));
    ACanvas.FillRoundRect(Rect(R.Left, R.Bottom - 1, R.Right, R.Bottom), 0, Line, 255);
  end;
  // Beschriftungen (wandern beim Scrollen mit den Editoren)
  for I := 0 to High(FItems) do
  begin
    if FItems[I].Caption = '' then
      Continue;
    R := ItemLabelRect(I);
    if IsRectEmpty(R) or not NeedsPaint(R) then
      Continue;
    ACanvas.DrawText(R, FItems[I].Caption, Font, LabelColor,
      DrawTextBiDiModeFlags(TPPGCellPainter.TextFlags(taLeftJustify)));
  end;
  PaintScrollBars(ACanvas);
end;

{ Bearbeitungsformular im Grid }

function TPPGCustomDBGrid.FormMode: Boolean;
begin
  Result := (FEditMode = dgeForm) and not CardMode;
end;

function TPPGCustomDBGrid.FormAllowed: Boolean;
begin
  Result := FDataLink.Active and not FReadOnly and (dgEditing in FDBOptions) and
    not FDataLink.ReadOnly and FDataLink.DataSet.CanModify and HandleAllocated and
    not (csDesigning in ComponentState) and
    (FAllowEdit or (FAllowInsert and (FDataLink.DataSet.State = dsInsert)));
end;

function TPPGCustomDBGrid.FormCanEdit(ACol: Integer): Boolean;
begin
  Result := FDataLink.Active and CellEditable(ACol, VisualRow(FixedRows + ActiveDataIndex));
end;

procedure TPPGCustomDBGrid.SetEditMode(const Value: TPPGDBGridEditMode);
begin
  if FEditMode = Value then
    Exit;
  // Offene Eingabe uebernehmen (lehnt die Datenmenge ab, bleibt alles)
  if FFormOpen and not HideEditForm(True) then
    Exit;
  HideEditor(True);
  FEditMode := Value;
  Invalidate;
end;

procedure TPPGCustomDBGrid.SetEditForm(const Value: TPPGDBGridEditFormOptions);
begin
  FEditForm.Assign(Value);
end;

procedure TPPGCustomDBGrid.EditFormOptionsChanged;
begin
  if not FFormOpen or (FEditPanel = nil) or (csLoading in ComponentState) then
    Exit;
  // Raster und Hoehe neu (Editoren und Eingaben bleiben)
  FormLayoutCells;
  UpdateBufferCount;
  DataChanged;
end;

procedure TPPGCustomDBGrid.EditFormColors(out Fill, Text, Line, Accent, LabelColor: TColor);
var
  Base, Header: TColor;
begin
  // Flaeche wie der Kopf (hebt sich von den Zeilen und den Editoren ab)
  GetGridColors(Base, Text, Header, Line, Accent);
  Fill := Header;
  if UseOwnColors then
  begin
    Line := Styles.GridLine.FillFor(UseDarkMode, Line);
    LabelColor := PPGBlendColor(Text, Fill, 0.3);
  end
  else
    LabelColor := Text;
end;

function TPPGCustomDBGrid.FormItemText(I: Integer): string;
var
  Ed: TPPGCustomControl;
  DP: TDateAccess;
begin
  Ed := FEditPanel.FItems[I].Editor;
  if Ed is TPPGCheckBox then
    case TPPGCheckBox(Ed).State of
      cbChecked: Result := '1';
      cbUnchecked: Result := '0';
    else
      Result := PPGGridCheckGrayed;
    end
  else if Ed is TPPGCustomDatePicker then
  begin
    DP := TDateAccess(Ed);
    if (DP.ShowCheckbox and not DP.Checked) or (DP.DateTime = 0) then
      Result := ''
    else
      Result := DateTimeToStr(DP.DateTime);
  end
  else if Ed is TPPGCustomMemo then
    Result := TPPGCustomMemo(Ed).Text
  else
    Result := PPGGridEditorText(Ed);
end;

function TPPGCustomDBGrid.FormEditorOf(ACol: Integer): TPPGEditFormEditor;
var
  C: TPPGGridColumn;
  F: TField;
begin
  Result := efeAuto;
  C := ColumnOf(ACol);
  if C is TPPGDBGridColumn then
    Result := TPPGDBGridColumn(C).EditFormEditor;
  F := FieldOfCol(ACol);
  // Kaestchen und Nachschlagen behalten ihren Editor
  if (F = nil) or IsCheckColumn(ACol) or (ColumnLookup(ACol) <> nil) or
    (F.FieldKind = fkLookup) then
    Exit(efeText);
  if Result = efeAuto then
  begin
    if F.DataType in [ftMemo, ftWideMemo, ftFmtMemo] then
      Result := efeMemo
    else if F.DataType in [ftDate, ftDateTime, ftTimeStamp] then
      Result := efeDate
    else
      Result := efeText;
  end;
  // Datumsauswahl nur fuer Datumsfelder
  if (Result = efeDate) and not (F.DataType in [ftDate, ftDateTime, ftTimeStamp]) then
    Result := efeText;
end;

function TPPGCustomDBGrid.FormOrderAfter(A, B: Integer): Boolean;

  function Idx(ACol: Integer): Integer;
  var
    C: TPPGGridColumn;
  begin
    C := ColumnOf(ACol);
    if C is TPPGDBGridColumn then
      Result := TPPGDBGridColumn(C).EditFormIndex
    else
      Result := -1;
  end;

var
  IA, IB: Integer;
begin
  // Mit EditFormIndex zuerst (aufsteigend), dann die Anzeige-Reihenfolge
  IA := Idx(A);
  IB := Idx(B);
  if (IA >= 0) <> (IB >= 0) then
    Exit(IB >= 0);
  if (IA >= 0) and (IA <> IB) then
    Exit(IA > IB);
  Result := ColumnSortKey(A) > ColumnSortKey(B);
end;

procedure TPPGCustomDBGrid.FormBuild;
var
  Cols: array of Integer;
  I, J, N, ARow: Integer;
  C: TPPGGridColumn;
  Show: Boolean;
  Vis: TPPGEditFormVisibility;
  It: TPPGDBGridEditFormItem;
  Kind: TPPGGridEditorKind;
  Ed: TPPGCustomControl;
  Chk: TPPGCheckBox;
  Mode: TPPGEditFormEditor;
  Memo: TPPGMemo;
  DP: TPPGDatePicker;
begin
  FEditPanel.ClearItems;
  if not FDataLink.Active then
    Exit;
  ARow := FixedRows + ActiveDataIndex;
  // Datenspalten in der Reihenfolge der Anzeige (auch ausgeblendete mit
  // efvShow), stabil nach DisplayIndex einsortiert
  N := DataColCount;
  SetLength(Cols, 0);
  for I := FixedCols to FixedCols + N - 1 do
  begin
    C := ColumnOf(I);
    Vis := efvAuto;
    if C is TPPGDBGridColumn then
      Vis := TPPGDBGridColumn(C).EditFormVisible;
    case Vis of
      efvShow: Show := True;
      efvHide: Show := False;
    else
      Show := (C = nil) or C.Visible;
    end;
    if not Show or (FieldOfCol(I) = nil) then
      Continue;
    J := Length(Cols);
    SetLength(Cols, J + 1);
    while (J > 0) and FormOrderAfter(Cols[J - 1], I) do
    begin
      Cols[J] := Cols[J - 1];
      Dec(J);
    end;
    Cols[J] := I;
  end;
  SetLength(FEditPanel.FItems, Length(Cols));
  for I := 0 to High(Cols) do
  begin
    It.DataCol := Cols[I];
    It.Caption := CardLabel(Cols[I]);
    It.Editable := FormCanEdit(Cols[I]);
    It.Dirty := False;
    It.Original := '';
    It.Cell := 0;
    It.Row := 0;
    It.Span := 1;
    It.RowSpan := 1;
    It.LabelR := Rect(0, 0, 0, 0);
    It.EditorR := Rect(0, 0, 0, 0);
    Kind := CellEditorKind(Cols[I], ARow);
    Mode := efeText;
    if Kind <> gekCheck then
      Mode := FormEditorOf(Cols[I]);
    if Mode = efeMemo then
    begin
      // Mehrzeilig: Enter bricht um (Strg+Enter uebernimmt)
      Memo := TPPGMemo.Create(FEditPanel);
      Memo.Parent := FEditPanel;
      TCtrlAccess(Memo).Preset := TCtrlAccess(FEditPanel).Preset;
      TCtrlAccess(Memo).StyleManager := TCtrlAccess(FEditPanel).StyleManager;
      Memo.ScrollBars := ssVertical;
      Memo.OnChange := FEditPanel.EditorChange;
      TFieldAccess(Memo).ReadOnly := not It.Editable;
      Ed := Memo;
      Kind := gekText;
    end
    else if Mode = efeDate then
    begin
      // Datum mit Kalender; leerer Wert ueber das Kaestchen (nicht bei Pflichtfeldern)
      DP := TPPGDatePicker.Create(FEditPanel);
      DP.Parent := FEditPanel;
      TCtrlAccess(DP).Preset := TCtrlAccess(FEditPanel).Preset;
      TCtrlAccess(DP).StyleManager := TCtrlAccess(FEditPanel).StyleManager;
      TCtrlAccess(DP).AutoSize := False;
      DP.ShowCheckbox := not FieldOfCol(Cols[I]).Required;
      DP.OnChange := FEditPanel.EditorChange;
      TFieldAccess(DP).ReadOnly := not It.Editable;
      Ed := DP;
      Kind := gekText;
    end
    else if Kind = gekCheck then
    begin
      // Kaestchen (auch Null = grau); schreibgeschuetzt: deaktiviert
      Chk := TPPGCheckBox.Create(FEditPanel);
      Chk.Parent := FEditPanel;
      TCtrlAccess(Chk).Preset := TCtrlAccess(FEditPanel).Preset;
      TCtrlAccess(Chk).StyleManager := TCtrlAccess(FEditPanel).StyleManager;
      Chk.AllowGrayed := True;
      Chk.OnChange := FEditPanel.EditorChange;
      Chk.Enabled := It.Editable;
      Ed := Chk;
    end
    else
    begin
      // Zell-Editor der Spalte (Text, Auswahl, Zahl); nicht bearbeitbar:
      // Textfeld nur zum Lesen
      if (Kind = gekNone) or not It.Editable then
        Kind := gekText;
      // Nachschlage-Spalte mit mehreren Listenfeldern: mehrspaltige Auswahl
      Ed := PPGCreateGridEditorOf(CellEditorClass(Cols[I], ARow, Kind), FEditPanel, nil, nil);
      TCtrlAccess(Ed).StyleManager := TCtrlAccess(FEditPanel).StyleManager;
      if Ed is TPPGCustomField then
      begin
        TFieldAccess(Ed).OnChange := FEditPanel.EditorChange;
        TFieldAccess(Ed).ReadOnly := not It.Editable;
      end;
      if Ed is TPPGGridEdit then
        TPPGGridEdit(Ed).OnEllipsisClick := FEditPanel.EditorEllipsis;
      Ed.Visible := True;
    end;
    It.Kind := Kind;
    // Name fuer Screenreader und Hinweis: die Beschriftung
    Ed.Hint := It.Caption;
    TCtrlAccess(Ed).OnEnter := FEditPanel.EditorEnter;
    Ed.TabStop := True;
    It.Editor := Ed;
    FEditPanel.FItems[I] := It;
  end;
  FormLayoutCells;
end;

procedure TPPGCustomDBGrid.FormLayoutCells;
var
  I, K, Cnt, Cell, Row, Span, RS, Used, G: Integer;
  C: TPPGGridColumn;
  Occ: array of Cardinal; // belegte Zellen je Rasterzeile (Bit je Spalte)
  Group, CurGroup: string;
  NewRow: Boolean;

  function Free(ARow, ACell: Integer): Boolean;
  var
    R, X: Integer;
  begin
    for R := ARow to ARow + RS - 1 do
    begin
      if R >= Length(Occ) then
        Continue;
      for X := ACell to ACell + Span - 1 do
        if Occ[R] and (Cardinal(1) shl X) <> 0 then
          Exit(False);
    end;
    Result := True;
  end;

  procedure Mark(ARow, ACell, ASpan, ARows: Integer);
  var
    R, X: Integer;
  begin
    if Length(Occ) < ARow + ARows then
      SetLength(Occ, ARow + ARows);
    for R := ARow to ARow + ARows - 1 do
      for X := ACell to ACell + ASpan - 1 do
        Occ[R] := Occ[R] or (Cardinal(1) shl X);
    if Used < ARow + ARows then
      Used := ARow + ARows;
  end;

begin
  // Raster: Felder fliessen nach rechts und brechen um (Spanne passt ganz);
  // mehrzeilige Felder belegen mehrere Zeilen, ein neuer Abschnitt
  // (EditFormGroup) beginnt unter allem Belegten mit seiner Ueberschrift
  Cnt := FEditForm.ColumnCount;
  Cell := 0;
  Row := 0;
  Used := 0;
  SetLength(Occ, 0);
  SetLength(FEditPanel.FGroups, 0);
  CurGroup := '';
  for I := 0 to High(FEditPanel.FItems) do
  begin
    C := ColumnOf(FEditPanel.FItems[I].DataCol);
    Span := 1;
    RS := 1;
    Group := '';
    NewRow := False;
    if C is TPPGDBGridColumn then
    begin
      NewRow := TPPGDBGridColumn(C).EditFormNewRow;
      Span := TPPGDBGridColumn(C).EditFormColSpan;
      Group := TPPGDBGridColumn(C).EditFormGroup;
      if FEditPanel.FItems[I].Editor is TPPGCustomMemo then
        RS := TPPGDBGridColumn(C).EditFormRows;
    end
    else if FEditPanel.FItems[I].Editor is TPPGCustomMemo then
      RS := 3;
    Span := EnsureRange(Span, 1, Cnt);
    if Group <> CurGroup then
    begin
      CurGroup := Group;
      Row := Used;
      Cell := 0;
      if Group <> '' then
      begin
        G := Length(FEditPanel.FGroups);
        SetLength(FEditPanel.FGroups, G + 1);
        FEditPanel.FGroups[G].Caption := Group;
        FEditPanel.FGroups[G].Row := Row;
        FEditPanel.FGroups[G].FirstItem := I;
        FEditPanel.FGroups[G].R := Rect(0, 0, 0, 0);
        Mark(Row, 0, Cnt, 1);
        Inc(Row);
      end;
    end;
    // EditFormNewRow: in der naechsten Rasterzeile links beginnen
    if NewRow and (Cell > 0) then
    begin
      Cell := 0;
      Inc(Row);
    end;
    // Naechste freie Stelle ab (Row, Cell)
    K := 0;
    while True do
    begin
      if Cell + Span > Cnt then
      begin
        Cell := 0;
        Inc(Row);
      end;
      if Free(Row, Cell) then
        Break;
      Inc(Cell);
      Inc(K);
      if K > 10000 then
        Break; // Schutz (kann bei Cnt <= 32 nicht eintreten)
    end;
    Mark(Row, Cell, Span, RS);
    FEditPanel.FItems[I].Cell := Cell;
    FEditPanel.FItems[I].Row := Row;
    FEditPanel.FItems[I].Span := Span;
    FEditPanel.FItems[I].RowSpan := RS;
    Inc(Cell, Span);
  end;
  FEditPanel.FArrangedW := -1;
end;

procedure FormLoadDate(DP: TDateAccess; F: TField);
begin
  // Wie TPPGDBDatePicker: Null = Kaestchen aus (bzw. leer); nur das Datum
  if (F = nil) or F.IsNull then
  begin
    if DP.ShowCheckbox then
      DP.Checked := False
    else
      DP.DateTime := 0;
  end
  else
  begin
    DP.Date := Int(F.AsDateTime);
    DP.Checked := True;
  end;
end;

procedure TPPGCustomDBGrid.FormLoadValues(OnlyClean: Boolean);
var
  I, ARow, DC: Integer;
  S: string;
  Ed: TPPGCustomControl;
  F: TField;
begin
  if (FEditPanel = nil) or not FDataLink.Active then
    Exit;
  ARow := FixedRows + ActiveDataIndex;
  Inc(FEditPanel.FLoading);
  try
    for I := 0 to High(FEditPanel.FItems) do
    begin
      Ed := FEditPanel.FItems[I].Editor;
      // Geaenderte (und das gerade bediente) Feld behalten ihre Eingabe
      if OnlyClean and (FormItemChanged(I) or Ed.Focused) then
        Continue;
      DC := FEditPanel.FItems[I].DataCol;
      // Bearbeitbar: Field.Text (Bearbeitungsformat); sonst die Anzeige
      if FEditPanel.FItems[I].Editable then
        S := GetEditText(DC, ARow)
      else
        S := GetCellText(DC, ARow);
      if Ed is TPPGCustomDatePicker then
        FormLoadDate(TDateAccess(Ed), FieldOfCol(DC))
      else if Ed is TPPGCustomMemo then
      begin
        F := FieldOfCol(DC);
        if (F = nil) or F.IsNull then
          TPPGCustomMemo(Ed).Text := ''
        else
          TPPGCustomMemo(Ed).Text := F.AsString;
      end
      else if Ed is TPPGCheckBox then
      begin
        if TPPGCellPainter.IsGrayedText(S) then
          TPPGCheckBox(Ed).State := cbGrayed
        else if TPPGCellPainter.IsCheckedText(S) then
          TPPGCheckBox(Ed).State := cbChecked
        else
          TPPGCheckBox(Ed).State := cbUnchecked;
      end
      else
      begin
        PPGGridEditorBegin(Ed, S, ColumnOf(DC));
        if FEditPanel.FItems[I].Kind = gekCombo then
          FillLookupCombo(Ed, DC);
      end;
      FEditPanel.FItems[I].Dirty := False;
      FEditPanel.FItems[I].Original := FormItemText(I);
    end;
  finally
    Dec(FEditPanel.FLoading);
  end;
end;

function TPPGCustomDBGrid.FormItemChanged(I: Integer): Boolean;
begin
  // Eingabe des Anwenders oder Wert per Code (z. B. in OnEditFormShow)
  Result := FEditPanel.FItems[I].Dirty or (FormItemText(I) <> FEditPanel.FItems[I].Original);
end;

procedure TPPGCustomDBGrid.FormEditorChanged(I: Integer);
begin
  if not FFormOpen or (I < 0) or (I >= FEditPanel.ItemCount) or
    not FEditPanel.FItems[I].Editable then
    Exit;
  FEditPanel.FItems[I].Dirty := True;
  // Wie im Zell-Editor: Bearbeiten-Modus beim ersten Tastendruck
  EditorEdited;
end;

function TPPGCustomDBGrid.FormEditorHeight: Integer;
begin
  Result := Max(DataRowHeight, PPGScale(FormEditorMinH, ScalePPI));
end;

function TPPGCustomDBGrid.FormNeededHeight: Integer;
var
  I, Rows, PPI: Integer;
begin
  PPI := ScalePPI;
  Rows := 0;
  if FEditPanel <> nil then
    for I := 0 to High(FEditPanel.FItems) do
      Rows := Max(Rows, FEditPanel.FItems[I].Row + Max(1, FEditPanel.FItems[I].RowSpan));
  Result := 2 * PPGScale(FormPad, PPI) + Rows * FormEditorHeight +
    Max(0, Rows - 1) * PPGScale(FormVGap, PPI);
  if FEditForm.ShowButtons then
  begin
    Inc(Result, PPGScale(FormButtonH, PPI));
    if Rows > 0 then
      Inc(Result, 2 * PPGScale(FormVGap, PPI));
  end;
end;

procedure TPPGCustomDBGrid.FormUpdateGap;
var
  V: TRect;
  Need, Avail, MinGap: Integer;
begin
  if not FFormOpen or CardMode then
  begin
    FFormGap := 0;
    Exit;
  end;
  // So hoch wie noetig, hoechstens so, dass die aktive Zeile darueber passt;
  // reicht das nicht, scrollt das Formular selbst
  Need := FormNeededHeight;
  V := GridViewRect;
  Avail := (V.Bottom - V.Top) - FixedHeight - DataRowHeight;
  MinGap := Min(Need, PPGScale(FormMinGap, ScalePPI));
  FFormGap := Min(Need, Avail);
  if FFormGap < MinGap then
    FFormGap := MinGap;
end;

procedure TPPGCustomDBGrid.FormArrange(Force: Boolean);
var
  P: TPPGDBGridEditForm;
  PPI, Pad, VGap, HGap, LGap, EH, W, Cnt, CellW, LabelW, I, X, Y, IW, BW, BH, Rows: Integer;
  RS, EB: Integer;
  LR, ER, AR, CR: TRect;
  RTL: Boolean;

  function Mirror(const R: TRect): TRect;
  begin
    if RTL and not IsRectEmpty(R) then
      Result := Rect(W - R.Right, R.Top, W - R.Left, R.Bottom)
    else
      Result := R;
  end;

begin
  P := FEditPanel;
  if P = nil then
    Exit;
  PPI := ScalePPI;
  if not Force and (P.FArrangedW = P.Width) and (P.FArrangedPPI = PPI) then
    Exit;
  Pad := PPGScale(FormPad, PPI);
  VGap := PPGScale(FormVGap, PPI);
  HGap := PPGScale(FormHGap, PPI);
  LGap := PPGScale(FormLabelGap, PPI);
  EH := FormEditorHeight;
  // Breite ohne senkrechte Leiste, wenn das Formular scrollen muss
  W := P.Width;
  if FormNeededHeight > P.Height then
    Dec(W, P.BarThickness);
  Cnt := FEditForm.ColumnCount;
  CellW := (W - 2 * Pad - (Cnt - 1) * HGap) div Cnt;
  if CellW < 1 then
    CellW := 1;
  RTL := UseRightToLeftAlignment;
  // Anordnen ohne Verschiebung (Scrollen verschiebt danach die Kinder)
  P.ScrollTo(0, 0);
  Rows := 0;
  for I := 0 to High(P.FGroups) do
    P.FGroups[I].R := Mirror(Rect(Pad, Pad + P.FGroups[I].Row * (EH + VGap), W - Pad,
      Pad + P.FGroups[I].Row * (EH + VGap) + EH));
  for I := 0 to High(P.FItems) do
  begin
    X := Pad + P.FItems[I].Cell * (CellW + HGap);
    IW := P.FItems[I].Span * CellW + (P.FItems[I].Span - 1) * HGap;
    Y := Pad + P.FItems[I].Row * (EH + VGap);
    RS := Max(1, P.FItems[I].RowSpan);
    Rows := Max(Rows, P.FItems[I].Row + RS);
    LabelW := PPGScale(FEditForm.LabelWidth, PPI);
    if LabelW > IW div 2 then
      LabelW := IW div 2;
    // Mehrzeilig: Editor ueber RS Rasterzeilen, Beschriftung in der ersten
    EB := Y + RS * EH + (RS - 1) * VGap;
    if LabelW > 0 then
    begin
      LR := Rect(X, Y, X + LabelW, Y + EH);
      ER := Rect(X + LabelW + LGap, Y, X + IW, EB);
    end
    else
    begin
      LR := Rect(0, 0, 0, 0);
      ER := Rect(X, Y, X + IW, EB);
    end;
    LR := Mirror(LR);
    ER := Mirror(ER);
    P.FItems[I].LabelR := LR;
    P.FItems[I].EditorR := ER;
    P.FItems[I].Editor.BoundsRect := ER;
  end;
  // Schaltflaechen unten an der Endseite (Uebernehmen vor Abbrechen)
  P.FApply.Visible := FEditForm.ShowButtons;
  P.FCancel.Visible := FEditForm.ShowButtons;
  if FEditForm.ShowButtons then
  begin
    BW := PPGScale(FormButtonW, PPI);
    BH := PPGScale(FormButtonH, PPI);
    Y := Pad;
    if Rows > 0 then
      Y := Pad + Rows * (EH + VGap) + VGap;
    CR := Rect(W - Pad - BW, Y, W - Pad, Y + BH);
    AR := Rect(CR.Left - PPGScale(FormButtonGap, PPI) - BW, Y,
      CR.Left - PPGScale(FormButtonGap, PPI), Y + BH);
    P.FApply.BoundsRect := Mirror(AR);
    P.FCancel.BoundsRect := Mirror(CR);
  end;
  P.FArrangedW := P.Width;
  P.FArrangedPPI := PPI;
  P.Invalidate;
end;

procedure TPPGCustomDBGrid.FormPlace;
var
  V: Integer;
  R, GV: TRect;
begin
  if not FFormOpen or (FEditPanel = nil) or not FDataLink.Active or CardMode then
  begin
    if RowGapRow >= 0 then
    begin
      Inc(FSyncing);
      try
        SetRowGap(-1, 0);
      finally
        Dec(FSyncing);
      end;
    end;
    Exit;
  end;
  // Luecke unter der aktiven Zeile; das Formular fuellt sie ueber die ganze
  // Breite (scrollt nicht waagerecht mit den Spalten)
  V := VisualRow(FixedRows + ActiveDataIndex);
  Inc(FSyncing);
  try
    SetRowGap(V, FFormGap);
    EnsureGeometry;
  finally
    Dec(FSyncing);
  end;
  R := RawCellRect(0, V);
  GV := GridViewRect;
  FEditPanel.SetBounds(GV.Left, R.Bottom, GV.Right - GV.Left, FFormGap);
  FormArrange(False);
  if not FEditPanel.Visible then
    FEditPanel.Visible := True;
end;

procedure TPPGCustomDBGrid.FormWriteValues;
var
  I, ARow: Integer;
begin
  if (FEditPanel = nil) or not FDataLink.Active then
    Exit;
  ARow := FixedRows + ActiveDataIndex;
  Inc(FFormBusy);
  try
    for I := 0 to High(FEditPanel.FItems) do
      if FEditPanel.FItems[I].Editable and FormItemChanged(I) then
      begin
        FWriteEditor := FEditPanel.FItems[I].Editor;
        try
          try
            if (FWriteEditor is TPPGCustomDatePicker) or (FWriteEditor is TPPGCustomMemo) then
              FormWriteSpecial(I)
            else
              SetCellByUser(FEditPanel.FItems[I].DataCol, ARow, FormItemText(I));
          finally
            FWriteEditor := nil;
          end;
        except
          // Ungueltiger Wert: das Formular bleibt offen, Fokus auf das Feld
          FormFocusTarget(I);
          raise;
        end;
        FEditPanel.FItems[I].Dirty := False;
        FEditPanel.FItems[I].Original := FormItemText(I);
      end;
  finally
    Dec(FFormBusy);
  end;
end;

procedure TPPGCustomDBGrid.FormWriteSpecial(I: Integer);
var
  F: TField;
  Ed: TPPGCustomControl;
  DP: TDateAccess;
  T: Double;
  S: string;
begin
  F := FieldOfCol(FEditPanel.FItems[I].DataCol);
  Ed := FEditPanel.FItems[I].Editor;
  if (F = nil) or not FDataLink.Active then
    Exit;
  if Ed is TPPGCustomMemo then
  begin
    S := TPPGCustomMemo(Ed).Text;
    if not F.IsNull and (F.AsString = S) then
      Exit;
    if not FDataLink.Editing and not FDataLink.Edit then
      Exit;
    if S = '' then
      F.Clear
    else
      F.AsString := S;
    Exit;
  end;
  if not (Ed is TPPGCustomDatePicker) then
    Exit;
  DP := TDateAccess(Ed);
  // Getippter, noch nicht uebernommener Text zaehlt mit
  DP.CommitText(False);
  if not FDataLink.Editing and not FDataLink.Edit then
    Exit;
  // Wie TPPGDBDatePicker: Kaestchen aus bzw. kein Datum = leer; die Uhrzeit
  // eines Datum/Zeit-Felds bleibt erhalten
  if (DP.ShowCheckbox and not DP.Checked) or (DP.DateTime = 0) then
    F.Clear
  else
  begin
    if F.IsNull then
      T := 0
    else
      T := Frac(F.AsDateTime);
    F.AsDateTime := Int(DP.Date) + T;
  end;
end;

procedure TPPGCustomDBGrid.FormEllipsis(I: Integer);
begin
  // "..."-Knopf eines Felds: wie im Zell-Editor OnEditButtonClick, die
  // Fokusspalte ist dabei die Spalte des Felds (SelectedField)
  Inc(FSyncing);
  try
    Col := FEditPanel.FItems[I].DataCol;
  finally
    Dec(FSyncing);
  end;
  EditButtonClick;
end;

function TPPGCustomDBGrid.FormItemOfField(F: TField): Integer;
var
  I: Integer;
begin
  Result := -1;
  if (FEditPanel = nil) or (F = nil) then
    Exit;
  for I := 0 to High(FEditPanel.FItems) do
    if FieldOfCol(FEditPanel.FItems[I].DataCol) = F then
      Exit(I);
end;

function TPPGCustomDBGrid.FormNextTarget(T: Integer; Forward: Boolean): Integer;
var
  N, Total, K: Integer;
  C: TWinControl;
begin
  // Ziele: Felder (bedienbare), dann Uebernehmen und Abbrechen; im Kreis
  Result := -1;
  if FEditPanel = nil then
    Exit;
  N := FEditPanel.ItemCount;
  Total := N;
  if FEditForm.ShowButtons then
    Inc(Total, 2);
  if Total = 0 then
    Exit;
  for K := 1 to Total do
  begin
    if Forward then
      T := T + 1
    else
      T := T - 1;
    if T >= Total then
      T := 0
    else if T < 0 then
      T := Total - 1;
    C := FEditPanel.TargetControl(T);
    if (C <> nil) and C.Enabled and C.Visible then
      Exit(T);
  end;
end;

procedure TPPGCustomDBGrid.FormFocusTarget(T: Integer);
var
  C: TWinControl;
begin
  if FEditPanel = nil then
    Exit;
  C := FEditPanel.TargetControl(T);
  if C = nil then
    Exit;
  FEditPanel.FCurrent := T;
  // Ohne angezeigtes Fenster (z. B. Tests) nur das Ziel merken
  if C.CanFocus and HandleAllocated and IsWindowVisible(Handle) then
    C.SetFocus;
  FormScrollIntoView(T);
end;

procedure TPPGCustomDBGrid.FormScrollIntoView(T: Integer);
var
  P: TPPGDBGridEditForm;
  C: TWinControl;
  R, V: TRect;
  Y, Pad: Integer;
begin
  // Ziel mit dem Rand ins Bild (erstes Feld: ganz oben)
  P := FEditPanel;
  C := P.TargetControl(T);
  if C = nil then
    Exit;
  R := C.BoundsRect;
  OffsetRect(R, P.ScrollPos.X, P.ScrollPos.Y); // Lage im Inhalt
  Pad := PPGScale(FormPad, ScalePPI);
  InflateRect(R, 0, Pad);
  V := P.ViewArea;
  Y := P.ScrollPos.Y;
  if R.Top < Y then
    Y := R.Top
  else if R.Bottom > Y + (V.Bottom - V.Top) then
    Y := R.Bottom - (V.Bottom - V.Top);
  if Y < 0 then
    Y := 0;
  if Y <> P.ScrollPos.Y then
    P.ScrollTo(P.ScrollPos.X, Y);
end;

function TPPGCustomDBGrid.EditFormKey(Key: Word; Shift: TShiftState): Boolean;
var
  P: TPPGDBGridEditForm;
  T, N, Nx: Integer;
begin
  Result := False;
  P := FEditPanel;
  if not FFormOpen or (P = nil) or (ssAlt in Shift) then
    Exit;
  T := P.FCurrent;
  N := P.ItemCount;
  // Offene Auswahlliste behaelt Enter und Esc
  if (Key <> VK_TAB) and (T >= 0) and (T < N) and (P.FItems[T].Editor is TPPGComboBox) and
    TPPGComboBox(P.FItems[T].Editor).DroppedDown then
    Exit;
  case Key of
    VK_TAB:
      if not (ssCtrl in Shift) then
      begin
        FormFocusTarget(FormNextTarget(T, not (ssShift in Shift)));
        Result := True;
      end;
    VK_RETURN:
      begin
        Result := True;
        if (ssCtrl in Shift) or (T = N) then
          HideEditForm(True)
        else if T = N + 1 then
          HideEditForm(False)
        else
        begin
          // Naechstes Feld bzw. Uebernehmen; ohne Schaltflaechen uebernimmt
          // Enter im letzten Feld
          Nx := FormNextTarget(T, True);
          if (Nx <= T) or (Nx < 0) then
            HideEditForm(True)
          else
            FormFocusTarget(Nx);
        end;
      end;
    VK_ESCAPE:
      begin
        Result := True;
        HideEditForm(False);
      end;
  end;
end;

procedure TPPGCustomDBGrid.ShowEditForm;
var
  DS: TDataSet;
  T, I: Integer;
begin
  if FFormOpen or not FormMode or not FormAllowed then
    Exit;
  DS := FDataLink.DataSet;
  // Leere Datenmenge: erst Einfg (neuer Satz)
  if DS.IsEmpty and (DS.State <> dsInsert) then
    Exit;
  HideEditor(True);
  if EditorMode then
    Exit; // Zell-Editor lehnt ab (OnValidateCell)
  if FEditPanel = nil then
  begin
    FEditPanel := TPPGDBGridEditForm.Create(Self);
    FEditPanel.FGrid := Self;
    FEditPanel.Visible := False;
    FEditPanel.Parent := Self;
  end;
  TCtrlAccess(FEditPanel).Preset := Preset;
  TCtrlAccess(FEditPanel).StyleManager := StyleManager;
  TCtrlAccess(FEditPanel.FApply).Preset := Preset;
  TCtrlAccess(FEditPanel.FApply).StyleManager := StyleManager;
  TCtrlAccess(FEditPanel.FCancel).Preset := Preset;
  TCtrlAccess(FEditPanel.FCancel).StyleManager := StyleManager;
  Inc(FFormBusy);
  try
    try
      FFormOpen := True;
      FFormReload := False;
      FFormBm := nil;
      // Satz merken (neuer Satz: keiner, er schliesst nach dem Buchen)
      if (DS.State <> dsInsert) and not DS.IsEmpty then
        FFormBm := DS.Bookmark;
      FormBuild;
      FormLoadValues(False);
      // Weniger Zeilen im Puffer, Luecke unter der aktiven Zeile
      UpdateBufferCount;
      DataChanged;
    except
      FormClose(False, True);
      raise;
    end;
  finally
    Dec(FFormBusy);
  end;
  // Fokus: Feld der Fokusspalte, sonst das erste bedienbare
  T := -1;
  for I := 0 to FEditPanel.ItemCount - 1 do
    if (FEditPanel.FItems[I].DataCol = DataCol(FocusCol)) and FEditPanel.FItems[I].Editor.Enabled then
    begin
      T := I;
      Break;
    end;
  if T < 0 then
    T := FormNextTarget(-1, True);
  FormFocusTarget(T);
  DoEditFormShow;
end;

function TPPGCustomDBGrid.HideEditForm(Accept: Boolean): Boolean;
var
  DS: TDataSet;
begin
  Result := True;
  if not FFormOpen then
    Exit;
  if not FDataLink.Active then
  begin
    FormClose(False, True);
    Exit;
  end;
  DS := FDataLink.DataSet;
  Inc(FFormBusy);
  try
    if Accept then
    begin
      // Ein Fehler (Feldwert, Pflichtfeld, BeforePost) laesst das Formular offen
      FormWriteValues;
      if DS.State in dsEditModes then
      begin
        if DS.Modified then
          DS.Post
        else
          DS.Cancel; // unveraenderter neuer Satz verschwindet (wie TDBGrid)
      end;
    end
    else if DS.State in dsEditModes then
      DS.Cancel;
  finally
    Dec(FFormBusy);
  end;
  FormClose(Accept, True);
end;

procedure TPPGCustomDBGrid.FormClose(Accepted, Refresh: Boolean);
var
  HadFocus: Boolean;
begin
  if not FFormOpen then
    Exit;
  FFormOpen := False;
  FFormBm := nil;
  FFormGap := 0;
  if FEditPanel <> nil then
  begin
    HadFocus := FEditPanel.ContainsControl(FindControl(GetFocus));
    FEditPanel.Visible := False;
    FEditPanel.FCurrent := -1;
    if HadFocus and CanFocus and HandleAllocated and IsWindowVisible(Handle) then
      SetFocus;
  end;
  Inc(FSyncing);
  try
    SetRowGap(-1, 0);
  finally
    Dec(FSyncing);
  end;
  if Refresh and FDataLink.Active and not (csDestroying in ComponentState) then
  begin
    UpdateBufferCount;
    DataChanged;
  end;
  if not (csDestroying in ComponentState) then
    DoEditFormClose(Accepted);
end;

function TPPGCustomDBGrid.EditFormEditor(ACol: Integer): TPPGCustomControl;
var
  I: Integer;
begin
  Result := nil;
  if not FFormOpen or (FEditPanel = nil) then
    Exit;
  for I := 0 to High(FEditPanel.FItems) do
    if FEditPanel.FItems[I].DataCol = ACol then
      Exit(FEditPanel.FItems[I].Editor);
end;

procedure TPPGCustomDBGrid.DoEditFormShow;
begin
  if Assigned(FOnEditFormShow) then
    FOnEditFormShow(Self);
end;

procedure TPPGCustomDBGrid.DoEditFormClose(Accepted: Boolean);
begin
  if Assigned(FOnEditFormClose) then
    FOnEditFormClose(Self, Accepted);
end;

function TPPGCustomDBGrid.DoubleClickEdits: Boolean;
begin
  Result := inherited DoubleClickEdits or FFormOpen;
end;

procedure TPPGCustomDBGrid.DblClick;
begin
  // OnDblClick; Zell-Editor (nicht im Formular-Modus: CanEditCell)
  inherited DblClick;
  // Formular-Modus: Doppelklick auf eine Datenzeile oeffnet das Formular
  if FormMode and FDownOnRow and not FFormOpen and not EditorMode then
    ShowEditForm;
end;

procedure TPPGCustomDBGrid.KeyPress(var Key: Char);
var
  K: Char;
  I: Integer;
  Ed: TPPGCustomControl;
begin
  inherited KeyPress(Key);
  // Formular-Modus: Tippen oeffnet das Formular und beginnt im Feld der
  // Fokusspalte (Leertaste nicht: Mehrfachauswahl, Kaestchen)
  if not FormMode or FFormOpen or (Key <= ' ') or not FDataLink.Active then
    Exit;
  K := Key;
  Key := #0;
  ShowEditForm;
  if not FFormOpen then
    Exit;
  I := FEditPanel.FCurrent;
  if (I < 0) or (I >= FEditPanel.ItemCount) or not FEditPanel.FItems[I].Editable or
    (FEditPanel.FItems[I].Kind <> gekText) then
    Exit;
  Ed := FEditPanel.FItems[I].Editor;
  PPGGridEditorTypeChar(Ed, K);
end;

{ ---- Filterzeile ueber die Datenmenge ---- }

function TPPGCustomDBGrid.FiltersInView: Boolean;
begin
  // Der Puffer zeigt nur einen Ausschnitt: gefiltert wird die Datenmenge
  Result := False;
end;

function TPPGCustomDBGrid.SortsInView: Boolean;
begin
  // Sortieren ist Sache der Datenmenge (der Pfeil zeigt nur an)
  Result := False;
end;

function IsNumberField(F: TField): Boolean;
begin
  Result := F.DataType in [ftSmallint, ftInteger, ftWord, ftFloat, ftCurrency, ftBCD,
    ftAutoInc, ftLargeint, ftFMTBcd, ftShortint, ftByte, ftLongWord, ftExtended, ftSingle];
end;

function IsDateField(F: TField): Boolean;
begin
  Result := F.DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp];
end;

function TPPGCustomDBGrid.FilterValueKind(ACol: Integer): TPPGFilterValueKind;
var
  F: TField;
begin
  F := FieldOfCol(ACol);
  if F = nil then
    Result := fvkAuto
  else if IsCheckColumn(ACol) or (ColumnLookup(ACol) <> nil) or (F.FieldKind = fkLookup) then
    Result := fvkText
  else if IsNumberField(F) then
    Result := fvkNumber
  else if IsDateField(F) then
    Result := fvkDate
  else
    Result := fvkText;
end;

function TPPGCustomDBGrid.FilterFieldMatches(const Cond: TPPGFilterCondition; ACol: Integer;
  F: TField): Boolean;
begin
  if F = nil then
    Exit(True);
  // Kaestchen und Nachschlage-Spalten: der angezeigte Text (1/0 bzw. Listentext)
  if IsCheckColumn(ACol) or (ColumnLookup(ACol) <> nil) then
    Exit(Cond.MatchPlainText(FieldCellText(ACol, F)));
  if F.IsNull then
    Exit(Cond.MatchNull);
  if Cond.Compares then
  begin
    if IsNumberField(F) and Cond.NumOk then
      Exit(Cond.MatchNumber(F.AsFloat));
    if IsDateField(F) and Cond.DateOk then
      Exit(Cond.MatchDate(F.AsDateTime));
  end;
  Result := Cond.MatchPlainText(F.DisplayText);
end;

procedure TPPGCustomDBGrid.FilterRecordHook(DataSet: TDataSet; var Accept: Boolean);
var
  I: Integer;
begin
  // Filter der Anwendung zuerst (OnFilterRecord vor dem Grid)
  if Assigned(FFltOldEvent) then
  begin
    FFltOldEvent(DataSet, Accept);
    if not Accept then
      Exit;
  end;
  for I := 0 to High(FFltConds) do
    if not FilterFieldMatches(FFltConds[I], FFltCols[I], DataSet.FindField(FFltNames[I])) then
    begin
      Accept := False;
      Exit;
    end;
end;

procedure TPPGCustomDBGrid.FilterHook(DS: TDataSet);
begin
  if DS = nil then
    Exit;
  if FFltDS <> DS then
  begin
    FilterUnhook;
    // Zustand der Anwendung merken: OnFilterRecord laeuft weiter, Filter-Text
    // nur, wenn er aktiv war (Filtered = True schaltet ihn sonst mit ein)
    FFltDS := DS;
    FFltOldEvent := DS.OnFilterRecord;
    FFltOldFiltered := DS.Filtered;
    FFltOldText := DS.Filter;
    FFltTextCleared := not DS.Filtered and (DS.Filter <> '');
    DS.FreeNotification(Self);
    DS.OnFilterRecord := FilterRecordHook;
    if FFltTextCleared then
      DS.Filter := '';
  end;
  // Neu filtern (OnFilterRecord wirkt erst beim Einschalten)
  if DS.Filtered then
    DS.Filtered := False;
  DS.Filtered := True;
end;

procedure TPPGCustomDBGrid.FilterUnhook;
var
  DS: TDataSet;
  M: TFilterRecordEvent;
begin
  DS := FFltDS;
  if DS = nil then
    Exit;
  FFltDS := nil;
  if not (csDestroying in DS.ComponentState) then
  begin
    DS.RemoveFreeNotification(Self);
    M := DS.OnFilterRecord;
    if (TMethod(M).Data = Pointer(Self)) and
      (TMethod(M).Code = @TPPGCustomDBGrid.FilterRecordHook) then
      DS.OnFilterRecord := FFltOldEvent;
    if FFltOldFiltered then
    begin
      // Filter der Anwendung wieder allein (neu auswerten)
      DS.Filtered := False;
      DS.Filtered := True;
    end
    else
    begin
      DS.Filtered := False;
      if FFltTextCleared then
        DS.Filter := FFltOldText;
    end;
  end;
  FFltOldEvent := nil;
  FFltTextCleared := False;
end;

procedure TPPGCustomDBGrid.ApplyFilters;
var
  C, N: Integer;
  Cond: TPPGFilterCondition;
  F: TField;
begin
  // Bedingungen je Spalte lesen (Feld nach Namen: Spalten koennen sich aendern)
  N := 0;
  SetLength(FFltCols, ColCount);
  SetLength(FFltNames, ColCount);
  SetLength(FFltConds, ColCount);
  for C := FixedCols to ColCount - 1 do
  begin
    if Trim(Filters[C]) = '' then
      Continue;
    F := FieldOfCol(C);
    Cond := FilterCondition(C);
    if (F = nil) or not Cond.Active then
      Continue;
    FFltCols[N] := C;
    FFltNames[N] := F.FieldName;
    FFltConds[N] := Cond;
    Inc(N);
  end;
  SetLength(FFltCols, N);
  SetLength(FFltNames, N);
  SetLength(FFltConds, N);
  if N > 0 then
    FilterHook(FDataLink.DataSet)
  else
    FilterUnhook;
  inherited ApplyFilters;
end;

procedure TPPGCustomDBGrid.BarsChanged;
begin
  inherited BarsChanged;
  // Suchfeld und Filterleiste nehmen Platz von Datenzeilen
  if not (csLoading in ComponentState) and not (csDestroying in ComponentState) and
    (FDataLink <> nil) and FDataLink.Active and not FLayoutBusy then
  begin
    UpdateBufferCount;
    DataChanged;
  end;
end;

{ ---- Suche ueber die Datenmenge ---- }

function TPPGCustomDBGrid.FindFrom(Forward, IncludeCurrent: Boolean): Boolean;
var
  DS: TDataSet;
  Cols: array of Integer;
  NC, CI, I, Pos0, FoundCol, Skip: Integer;
  U: string;
  RowU: TArray<string>;
  Start: TBookmark;
  Wrapped: Boolean;

  function Match(VC: Integer): Boolean;
  var
    DC: Integer;
    F: TField;
  begin
    DC := DataCol(VC);
    F := FieldOfCol(DC);
    Result := (F <> nil) and (Pos(U, AnsiUpperCase(FieldCellText(DC, F))) > 0);
  end;

  function MatchAt(K: Integer): Boolean;
  begin
    if FindExtendedSyntax then
      Result := FindRowHit(RowU, K)
    else
      Result := Match(Cols[K]);
  end;

  procedure LoadRow;
  var
    K, DC: Integer;
    F: TField;
  begin
    // Erweiterte Suche: alle durchsuchten Zellen des Satzes
    if not FindExtendedSyntax then
      Exit;
    SetLength(RowU, NC);
    for K := 0 to NC - 1 do
    begin
      DC := DataCol(Cols[K]);
      F := FieldOfCol(DC);
      if F = nil then
        RowU[K] := ''
      else
        RowU[K] := AnsiUpperCase(FieldCellText(DC, F));
    end;
  end;

  function ScanRange(AFrom, ATo: Integer): Boolean;
  var
    K: Integer;
  begin
    // Spalten des aktuellen Satzes in Suchrichtung
    Result := False;
    LoadRow;
    if Forward then
    begin
      for K := Max(AFrom, 0) to Min(ATo, NC - 1) do
        if MatchAt(K) then
        begin
          FoundCol := Cols[K];
          Exit(True);
        end;
    end
    else
      for K := Min(AFrom, NC - 1) downto Max(ATo, 0) do
        if MatchAt(K) then
        begin
          FoundCol := Cols[K];
          Exit(True);
        end;
  end;

begin
  Result := False;
  U := AnsiUpperCase(FindText);
  if (U = '') or not FDataLink.Active then
    Exit;
  // Gruppiert: in der Reihenfolge der Ansicht (ohne Lesen der Datenmenge)
  if FGrpOn then
    Exit(GroupFind(U, Forward, IncludeCurrent, False, False));
  DS := FDataLink.DataSet;
  if DS.IsEmpty then
    Exit;
  SetLength(Cols, VColCount);
  NC := 0;
  for I := FixedCols to VColCount - 1 do
    if FindSearchColumn(DataCol(I)) then
    begin
      Cols[NC] := I;
      Inc(NC);
    end;
  if NC = 0 then
    Exit;
  CI := 0;
  for I := 0 to NC - 1 do
    if Cols[I] <= FocusCol then
      CI := I;
  // Eine offene Bearbeitung wird gebucht (wie beim Blaettern)
  if DS.State in dsEditModes then
    DS.CheckBrowseMode;
  Skip := Ord(not IncludeCurrent);
  FoundCol := -1;
  Pos0 := TDataSetAccess(DS).ActiveRecord;
  Start := DS.Bookmark;
  PPGDBBeginRead;
  DS.DisableControls;
  try
    try
      // 1. Aktueller Satz ab der Fokusspalte
      if Forward then
        ScanRange(CI + Skip, NC - 1)
      else
        ScanRange(CI - Skip, 0);
      // 2. Die anderen Saetze im Kreis, zuletzt der Rest des Startsatzes
      Wrapped := False;
      while FoundCol < 0 do
      begin
        if Forward then
        begin
          DS.Next;
          if DS.Eof then
          begin
            if Wrapped then
              Break;
            Wrapped := True;
            DS.First;
          end;
        end
        else
        begin
          DS.Prior;
          if DS.Bof then
          begin
            if Wrapped then
              Break;
            Wrapped := True;
            DS.Last;
          end;
        end;
        if DS.CompareBookmarks(DS.Bookmark, Start) = 0 then
        begin
          if Forward then
            ScanRange(0, CI - 1 + Skip)
          else
            ScanRange(NC - 1, CI + 1 - Skip);
          Break;
        end;
        if Forward then
          ScanRange(0, NC - 1)
        else
          ScanRange(NC - 1, 0);
      end;
    finally
      if FoundCol < 0 then
        GotoBookmarkAt(DS, Start, Pos0);
    end;
  finally
    // Treffer: die anderen Controls sollen den neuen Satz sehen
    if FoundCol >= 0 then
    begin
      PPGDBEndRead;
      DS.EnableControls;
    end
    else
    begin
      DS.EnableControls;
      PPGDBEndRead;
    end;
  end;
  if FoundCol >= 0 then
  begin
    MoveFocus(FoundCol, FocusRow, False, True);
    Invalidate;
    Result := True;
  end;
end;

function TPPGCustomDBGrid.IncrementalFind(const S: string; FromNext: Boolean): Boolean;
var
  DS: TDataSet;
  DC, Pos0: Integer;
  F: TField;
  U: string;
  Start: TBookmark;
  Found, Wrapped: Boolean;

  function Match: Boolean;
  begin
    Result := Copy(AnsiUpperCase(FieldCellText(DC, F)), 1, Length(U)) = U;
  end;

begin
  Result := False;
  U := AnsiUpperCase(S);
  DC := DataCol(FocusCol);
  F := FieldOfCol(DC);
  if (U = '') or (F = nil) or not FDataLink.Active then
    Exit;
  if FGrpOn then
    Exit(GroupFind(U, True, not FromNext, True, True));
  DS := FDataLink.DataSet;
  if DS.IsEmpty then
    Exit;
  if DS.State in dsEditModes then
    DS.CheckBrowseMode;
  Found := not FromNext and Match;
  if Found then
    Exit(True);
  Pos0 := TDataSetAccess(DS).ActiveRecord;
  Start := DS.Bookmark;
  PPGDBBeginRead;
  DS.DisableControls;
  try
    try
      Wrapped := False;
      while not Found do
      begin
        DS.Next;
        if DS.Eof then
        begin
          if Wrapped then
            Break;
          Wrapped := True;
          DS.First;
        end;
        if DS.CompareBookmarks(DS.Bookmark, Start) = 0 then
        begin
          Found := FromNext and Match;
          Break;
        end;
        Found := Match;
      end;
    finally
      if not Found then
        GotoBookmarkAt(DS, Start, Pos0);
    end;
  finally
    if Found then
    begin
      PPGDBEndRead;
      DS.EnableControls;
    end
    else
    begin
      DS.EnableControls;
      PPGDBEndRead;
    end;
  end;
  Result := Found;
end;

{ ---- Mehrfachauswahl: Helfer ---- }

function TPPGCustomDBGrid.AllowSelectCurrent: Boolean;
begin
  Result := True;
  if (FNoVeto = 0) and Assigned(FOnCanSelectRecord) then
    FOnCanSelectRecord(Self, Result);
end;

function TPPGCustomDBGrid.AllowSelectBookmark(const B: TBookmark): Boolean;
var
  DS: TDataSet;
  Cur: TBookmark;
  Pos0: Integer;
begin
  Result := True;
  if (FNoVeto > 0) or not Assigned(FOnCanSelectRecord) or not FDataLink.Active or
    (Length(B) = 0) then
    Exit;
  DS := FDataLink.DataSet;
  Cur := nil;
  if not DS.IsEmpty and (DS.State <> dsInsert) then
    Cur := DS.Bookmark;
  if (Length(Cur) > 0) and (DS.CompareBookmarks(Cur, B) = 0) then
    Exit(AllowSelectCurrent);
  if not DS.BookmarkValid(B) then
    Exit(False);
  // Kurz auf den Satz (ohne Anzeige), dann zurueck an dieselbe Pufferstelle
  Pos0 := TDataSetAccess(DS).ActiveRecord;
  PPGDBBeginRead;
  DS.DisableControls;
  try
    DS.Bookmark := B;
    try
      Result := AllowSelectCurrent;
    finally
      if (Length(Cur) > 0) and DS.BookmarkValid(Cur) then
        GotoBookmarkAt(DS, Cur, Pos0);
    end;
  finally
    DS.EnableControls;
    PPGDBEndRead;
  end;
end;

function TPPGCustomDBGrid.SelectedCount: Integer;
begin
  if FSelected = nil then
    Result := 0
  else
    Result := FSelected.Count;
end;

function TPPGCustomDBGrid.ForEachSelected(const Proc: TPPGDBGridRecordProc): Integer;
var
  DS: TDataSet;
  L: array of TBookmark;
  B: TBookmark;
  I, Pos0: Integer;
begin
  Result := 0;
  if not Assigned(Proc) or not MultiSelectActive or (FSelected.Count = 0) then
    Exit;
  DS := FDataLink.DataSet;
  // Lesezeichen erst kopieren: Proc darf die Auswahl aendern
  SetLength(L, FSelected.Count);
  for I := 0 to High(L) do
    L[I] := FSelected[I];
  if DS.State in dsEditModes then
    DS.CheckBrowseMode;
  Pos0 := TDataSetAccess(DS).ActiveRecord;
  DS.DisableControls;
  try
    B := nil;
    if not DS.IsEmpty then
      B := DS.Bookmark;
    try
      for I := 0 to High(L) do
        if DS.BookmarkValid(L[I]) then
        begin
          DS.Bookmark := L[I];
          Proc(DS);
          Inc(Result);
        end;
    finally
      if (Length(B) > 0) and DS.BookmarkValid(B) then
        GotoBookmarkAt(DS, B, Pos0);
    end;
  finally
    DS.EnableControls;
  end;
end;

function TPPGCustomDBGrid.SelectedValues(const FieldName: string): TArray<Variant>;
var
  Vals: TArray<Variant>;
  N: Integer;
begin
  SetLength(Result, 0);
  if not FDataLink.Active then
    Exit;
  if FDataLink.DataSet.FindField(FieldName) = nil then
    raise EPPGError.CreateFmt(PPGStr(@SPPGDBFieldNotFound), [FieldName]);
  SetLength(Vals, SelectedCount);
  N := 0;
  PPGDBBeginRead;
  try
    ForEachSelected(
      procedure(DataSet: TDataSet)
      begin
        Vals[N] := DataSet.FieldByName(FieldName).Value;
        Inc(N);
      end);
  finally
    PPGDBEndRead;
  end;
  SetLength(Vals, N);
  Result := Vals;
end;

{ ---- Gruppieren (ganze Datenmenge im Speicher) ---- }

/// Schluessel eines Lesezeichens fuer das Woerterbuch (ein Zeichen je Byte).
function BookmarkKey(const B: TBookmark): string;
var
  I: Integer;
begin
  SetLength(Result, Length(B));
  for I := 0 to High(B) do
    Result[I + 1] := Char(B[I]);
end;

/// Wert eines Felds fuer Vergleich, Export und RowValue (Binaerdaten: Null).
function GroupFieldValue(F: TField): Variant;
begin
  if (F = nil) or (F.IsBlob and not (F.DataType in [ftMemo, ftWideMemo, ftFmtMemo])) then
    Result := Null
  else
    Result := F.Value;
end;

function TPPGCustomDBGrid.AllRowsInView: Boolean;
begin
  // Ohne Gruppierung zeigt das Grid nur den Puffer der Datenmenge
  Result := FGrpOn and (Length(FCache) > 0);
end;

function TPPGCustomDBGrid.GroupedView: Boolean;
begin
  Result := FGrpOn;
end;

function TPPGCustomDBGrid.ActiveDataIndex: Integer;
begin
  if FGrpOn then
    Result := FGrpActive
  else if FDataLink.Active then
    Result := FDataLink.ActiveRecord
  else
    Result := -1;
end;

function TPPGCustomDBGrid.LoadedRowCount: Integer;
begin
  if FGrpOn then
    Result := Length(FCache)
  else
    Result := FDataLink.RecordCount;
end;

procedure TPPGCustomDBGrid.GotoDataIndex(R: Integer);
begin
  if FGrpOn then
    GroupGoto(R)
  else if R <> FDataLink.ActiveRecord then
    FDataLink.MoveBy(R - FDataLink.ActiveRecord);
end;

function TPPGCustomDBGrid.ActiveDataRow: Integer;
var
  R: Integer;
begin
  Result := -1;
  if not FDataLink.Active then
    Exit;
  R := ActiveDataIndex;
  if (R >= 0) and (R < LoadedRowCount) and (R < Length(FCache)) then
    Result := FixedRows + R;
end;

function TPPGCustomDBGrid.ActiveGroupValues: TArray<string>;
var
  G, N, I: Integer;
  Info: TPPGGridGroupInfo;
  S: string;
begin
  SetLength(Result, 0);
  if not FGrpOn or (FGrpActive < 0) or (FGrpActive >= Length(FCache)) then
    Exit;
  N := 0;
  G := DataRowGroup(FixedRows + FGrpActive);
  while G >= 0 do
  begin
    Info := GroupInfo(G);
    SetLength(Result, N + 1);
    Result[N] := Info.Key;
    Inc(N);
    G := Info.Parent;
  end;
  // Ebene 0 zuerst
  for I := 0 to N div 2 - 1 do
  begin
    S := Result[I];
    Result[I] := Result[N - 1 - I];
    Result[N - 1 - I] := S;
  end;
end;

function TPPGCustomDBGrid.GetGroupPanel: Boolean;
begin
  Result := inherited ShowGroupPanel;
end;

procedure TPPGCustomDBGrid.SetGroupPanel(const Value: Boolean);
begin
  if Value = inherited ShowGroupPanel then
    Exit;
  inherited ShowGroupPanel := Value;
  // Die Leiste nimmt Platz von Datenzeilen (wie Suchfeld und Filterleiste)
  if not (csLoading in ComponentState) and not (csDestroying in ComponentState) and
    (FDataLink <> nil) and FDataLink.Active and not FLayoutBusy then
  begin
    UpdateBufferCount;
    DataChanged;
  end;
end;

procedure TPPGCustomDBGrid.GroupSetLength(N: Integer; All: Boolean);
begin
  SetLength(FCache, N);
  SetLength(FRowBms, N);
  SetLength(FGrpVals, N);
  if All then
    SetLength(FGrpAll, N)
  else
    SetLength(FGrpAll, 0);
end;

procedure TPPGCustomDBGrid.UpdateGroupMode;
var
  NewOn: Boolean;
begin
  NewOn := FDataLink.Active and not CardMode and (Length(CurrentGroupColumns) > 0);
  if NewOn = FGrpOn then
    Exit;
  FGrpOn := NewOn;
  FGrpActive := -1;
  FGrpIns := -1;
  FGrpEditBm := nil;
  FGrpLastBm := nil;
  FGrpLastIns := False;
  FGrpRowDirty := False;
  FGrpNeedApply := False;
  FGrpViewSig := '';
  GroupSetLength(0, False);
  SetLength(FMarks, 0);
  SetLength(FGrpBufRecs, 0);
  if FGrpIndex <> nil then
    FGrpIndex.Clear;
  FGrpDirty := NewOn;
  if not NewOn then
  begin
    // Wieder der Puffer: die Leiste gehoert der Datenmenge, keine Gruppen
    Inc(FSyncing);
    try
      ScrollTo(ScrollX, 0);
      RebuildMap;
    finally
      Dec(FSyncing);
    end;
  end;
end;

procedure TPPGCustomDBGrid.GroupNoteChange;
var
  DS: TDataSet;
begin
  DS := FDataLink.DataSet;
  // Neuer Satz: eigene Zeile (GroupDataChanged), die Saetze bleiben
  if DS.State = dsInsert then
    Exit;
  // Post/Cancel einer Bearbeitung: nur dieser Satz hat sich geaendert
  if (DS.State = dsBrowse) and (Length(FGrpEditBm) > 0) and not FGrpDirty and
    not DS.IsEmpty and DS.BookmarkValid(FGrpEditBm) and
    (DS.CompareBookmarks(FGrpEditBm, DS.Bookmark) = 0) then
    FGrpRowDirty := True
  else
    FGrpDirty := True;
  if DS.State = dsBrowse then
    FGrpEditBm := nil;
end;

procedure TPPGCustomDBGrid.GroupReadRow(R: Integer; IsInsert: Boolean);
var
  C: Integer;
  F: TField;
  DS: TDataSet;
begin
  DS := FDataLink.DataSet;
  if IsInsert then
    FRowBms[R] := nil // neuer Satz hat kein Lesezeichen
  else
    FRowBms[R] := DS.Bookmark;
  SetLength(FCache[R], Length(FFields));
  SetLength(FGrpVals[R], Length(FFields));
  for C := 0 to High(FFields) do
  begin
    F := FFields[C];
    // Wie im Puffer: Kaestchen 1/0, Nachschlage-Spalte Listentext
    FCache[R][C] := FieldCellText(FixedCols + C, F);
    FGrpVals[R][C] := GroupFieldValue(F);
  end;
  if R < Length(FGrpAll) then
  begin
    SetLength(FGrpAll[R], DS.FieldCount);
    for C := 0 to DS.FieldCount - 1 do
      FGrpAll[R][C] := GroupFieldValue(DS.Fields[C]);
  end;
end;

procedure TPPGCustomDBGrid.GroupLoad;
var
  DS: TDataSet;
  B: TBookmark;
  Pos0, N: Integer;
  All: Boolean;
begin
  DS := FDataLink.DataSet;
  FGrpDirty := False;
  FGrpRowDirty := False;
  FGrpIns := -1;
  FGrpNeedApply := True;
  Inc(FGrpReadCount);
  FGrpIndex.Clear;
  // Alle Felder nur, wenn RowValue sie fuer andere Saetze braucht
  All := Assigned(OnGetCellStyle) or Assigned(OnSelectCell);
  GroupSetLength(0, False);
  Pos0 := TDataSetAccess(DS).ActiveRecord;
  B := nil;
  if not DS.IsEmpty then
    B := DS.Bookmark;
  N := 0;
  FGrpLoading := True;
  // Andere PPGlow-Controls an derselben Datenmenge sollen das EnableControls
  // am Ende nicht als Aenderung werten
  PPGDBBeginRead;
  DS.DisableControls;
  try
    try
      DS.First;
      while not DS.Eof do
      begin
        // geometrisch wachsen statt je Satz neu anlegen
        if N >= Length(FCache) then
          GroupSetLength(Max(64, Length(FCache) * 2), All);
        GroupReadRow(N, False);
        FGrpIndex.AddOrSetValue(BookmarkKey(FRowBms[N]), N);
        Inc(N);
        DS.Next;
      end;
    finally
      GroupSetLength(N, All);
      if (Length(B) > 0) and DS.BookmarkValid(B) then
        GotoBookmarkAt(DS, B, Pos0);
    end;
  finally
    try
      DS.EnableControls;
    finally
      PPGDBEndRead;
      FGrpLoading := False;
    end;
  end;
  UpdateMarks;
end;

function TPPGCustomDBGrid.GroupIndexOfBm(const B: TBookmark): Integer;
var
  I: Integer;
  DS: TDataSet;
begin
  Result := -1;
  if (Length(B) = 0) or (FGrpIndex = nil) or not FDataLink.Active then
    Exit;
  if FGrpIndex.TryGetValue(BookmarkKey(B), I) and (I < Length(FRowBms)) then
    Exit(I);
  // Datenmengen mit mehrdeutigen Lesezeichen-Bytes: vergleichen lassen
  DS := FDataLink.DataSet;
  for I := 0 to High(FRowBms) do
    if (Length(FRowBms[I]) > 0) and (DS.CompareBookmarks(FRowBms[I], B) = 0) then
      Exit(I);
end;

function TPPGCustomDBGrid.GroupIndexOfCurrent: Integer;
var
  DS: TDataSet;
begin
  DS := FDataLink.DataSet;
  if DS.State = dsInsert then
    Result := FGrpIns
  else if DS.IsEmpty then
    Result := -1
  else
    Result := GroupIndexOfBm(DS.Bookmark);
end;

function TPPGCustomDBGrid.GroupKeysOf(R: Integer): string;
var
  Cols: TArray<Integer>;
  I: Integer;
begin
  Result := '';
  Cols := CurrentGroupColumns;
  for I := 0 to High(Cols) do
    Result := Result + ViewGroupKey(Cols[I], FixedRows + R) + #1;
end;

function TPPGCustomDBGrid.GroupViewSignature: string;
var
  Cols: TArray<Integer>;
  I: Integer;
  C: TPPGGridColumn;
begin
  // Gruppenspalten und Summen-Spalten: aendern sie sich, neu gruppieren
  Result := '';
  Cols := CurrentGroupColumns;
  for I := 0 to High(Cols) do
  begin
    // mit GroupDateMode (Datumsgruppen)
    C := ColumnOf(Cols[I]);
    Result := Result + IntToStr(Cols[I]);
    if C <> nil then
      Result := Result + ':' + IntToStr(Ord(C.GroupDateMode));
    Result := Result + ',';
  end;
  Result := Result + '|';
  for I := FixedCols to ColCount - 1 do
  begin
    C := ColumnOf(I);
    if (C <> nil) and (C.Aggregate <> agNone) then
      Result := Result + IntToStr(I) + ':' + IntToStr(Ord(C.Aggregate)) + ';';
  end;
end;

function TPPGCustomDBGrid.GroupColSignature: string;
var
  I: Integer;
  C: TPPGGridColumn;
  L: TPPGDBGridColumn;
begin
  // Felder und Darstellung der Spalten: aendern sie sich, neu lesen
  Result := IntToStr(FixedCols);
  for I := 0 to High(FFields) do
  begin
    Result := Result + '|' + IntToHex(NativeUInt(Pointer(FFields[I])), SizeOf(Pointer) * 2) +
      IntToStr(Ord(IsCheckColumn(FixedCols + I)));
    C := ColumnOf(FixedCols + I);
    if C is TPPGDBGridColumn then
      Result := Result + #2 + TPPGDBGridColumn(C).ValueChecked + #2 +
        TPPGDBGridColumn(C).ValueUnchecked;
    L := ColumnLookup(FixedCols + I);
    if L <> nil then
      Result := Result + #2 + L.KeyField + #2 + L.ListField + #2 + IntToStr(L.ListFieldIndex);
  end;
end;

function TPPGCustomDBGrid.GroupPath(G: Integer): string;
var
  Info: TPPGGridGroupInfo;
begin
  Result := '';
  while G >= 0 do
  begin
    Info := GroupInfo(G);
    Result := IntToStr(Info.Column) + #2 + Info.Key + #1 + Result;
    G := Info.Parent;
  end;
end;

function TPPGCustomDBGrid.GroupByPath(const P: string): Integer;
var
  G: Integer;
begin
  for G := 0 to GroupCount - 1 do
    if GroupPath(G) = P then
      Exit(G);
  Result := -1;
end;

procedure TPPGCustomDBGrid.GroupDataChanged;
var
  DS: TDataSet;
  R, G: Integer;
  Keys: string;
begin
  if not FDataLink.Active then
    Exit;
  DS := FDataLink.DataSet;
  // Bearbeitung laeuft: erst nach Post/Cancel neu lesen (First wuerde buchen)
  if FGrpDirty and not (DS.State in dsEditModes) then
    GroupLoad
  else if FGrpRowDirty and (DS.State = dsBrowse) then
  begin
    FGrpRowDirty := False;
    R := GroupIndexOfCurrent;
    if R < 0 then
      GroupLoad
    else
    begin
      // Gruppe, in der die Zeile steht (die Feldaenderungen hat
      // RecordChanged schon gelesen)
      Keys := '';
      G := DataRowGroup(FixedRows + R);
      while G >= 0 do
      begin
        Keys := GroupInfo(G).Key + #1 + Keys;
        G := GroupInfo(G).Parent;
      end;
      GroupReadRow(R, False);
      // Anderer Gruppenwert: neu gruppieren, sonst nur die Summen
      if GroupKeysOf(R) <> Keys then
        FGrpNeedApply := True
      else
        RecalcAggregates;
    end;
  end;
  // Neuer Satz (Insert/Append): eigene Zeile, bis er gebucht ist
  if (DS.State = dsInsert) and (FGrpIns < 0) then
  begin
    R := Length(FCache);
    GroupSetLength(R + 1, Length(FGrpAll) > 0);
    GroupReadRow(R, True);
    FGrpIns := R;
    FGrpNeedApply := True;
  end
  else if (DS.State <> dsInsert) and (FGrpIns >= 0) then
    GroupLoad;
  if GroupViewSignature <> FGrpViewSig then
    FGrpNeedApply := True;
  if FGrpNeedApply then
    GroupApply;
end;

procedure TPPGCustomDBGrid.GroupApply;
var
  N, G, V: Integer;
  Path: string;
  Footer: Boolean;
begin
  FGrpNeedApply := False;
  FGrpViewSig := GroupViewSignature;
  Inc(FGrpViewVer);
  // Fokus auf einer Gruppenzeile: nach dem Neuaufbau dieselbe Gruppe
  Path := '';
  G := GroupAtRow(FocusRow, Footer);
  if G >= 0 then
    Path := GroupPath(G);
  N := Length(FCache);
  if N < 1 then
    N := 1;
  Inc(FSyncing);
  try
    if RowCount <> FixedRows + N then
      RowCount := FixedRows + N
    else
      RebuildMap;
    if Path <> '' then
    begin
      G := GroupByPath(Path);
      if G >= 0 then
      begin
        V := GroupRow(G);
        if V >= 0 then
          MoveFocus(FocusCol, V, False, False);
      end;
    end;
  finally
    Dec(FSyncing);
  end;
end;

function TPPGCustomDBGrid.GroupReveal(ARow: Integer): Integer;
var
  G: Integer;
  Info: TPPGGridGroupInfo;
begin
  Result := VisualRow(ARow);
  if Result >= 0 then
    Exit;
  // Zeile in einer zugeklappten Gruppe: die Gruppen darueber aufklappen
  G := DataRowGroup(ARow);
  while G >= 0 do
  begin
    Info := GroupInfo(G);
    if not Info.Expanded then
      ExpandGroup(G, True);
    G := Info.Parent;
  end;
  Result := VisualRow(ARow);
end;

procedure TPPGCustomDBGrid.GroupFocusActive;
var
  V: Integer;
begin
  if (FGrpActive < 0) or (FGrpActive >= Length(FCache)) then
    Exit;
  V := GroupReveal(FixedRows + FGrpActive);
  if V < 0 then
    Exit;
  Inc(FSyncing);
  try
    MoveFocus(FocusCol, V, False, False);
  finally
    Dec(FSyncing);
  end;
end;

procedure TPPGCustomDBGrid.GroupSync;
var
  DS: TDataSet;
  B: TBookmark;
  Ins, Changed: Boolean;
  I, Old: Integer;
begin
  if not FDataLink.Active then
    Exit;
  DS := FDataLink.DataSet;
  Ins := DS.State = dsInsert;
  B := nil;
  if not Ins and not DS.IsEmpty then
    B := DS.Bookmark;
  // Lesezeichen-Bytes vergleichen: CompareBookmarks meldet fuer einen
  // herausgefilterten Satz (TClientDataSet) Gleichheit
  if Ins <> FGrpLastIns then
    Changed := True
  else
    Changed := BookmarkKey(B) <> BookmarkKey(FGrpLastBm);
  FGrpLastBm := B;
  FGrpLastIns := Ins;
  if Ins then
    FGrpActive := FGrpIns
  else
    FGrpActive := GroupIndexOfBm(B);
  // Owner-Draw: Pufferzeilen der Datenmenge -> Saetze (OnDrawColumnCell
  // kommt nur fuer Saetze im Puffer)
  SetLength(FGrpBufRecs, 0);
  if Assigned(FOnDrawColumnCell) then
  begin
    SetLength(FGrpBufRecs, FDataLink.RecordCount);
    Old := FDataLink.ActiveRecord;
    try
      for I := 0 to High(FGrpBufRecs) do
        if I = Old then
          FGrpBufRecs[I] := FGrpActive
        else
        begin
          FDataLink.ActiveRecord := I;
          FGrpBufRecs[I] := GroupIndexOfBm(DS.Bookmark);
        end;
    finally
      FDataLink.ActiveRecord := Old;
    end;
  end;
  // Waehrend der Fokus die Datenmenge bewegt, setzt er auch die Zeile
  if (FGrpMoving > 0) or (FGrpActive < 0) then
    Exit;
  if not Changed then
  begin
    // Derselbe Satz: eine fokussierte Gruppenzeile bleibt
    if not IsDataRow(FocusRow) then
      Exit;
    if DataRow(FocusRow) = FixedRows + FGrpActive then
      Exit;
  end;
  GroupFocusActive;
end;

function TPPGCustomDBGrid.GroupGoto(R: Integer): Boolean;
var
  DS: TDataSet;
  B: TBookmark;
  Ver: Integer;
begin
  Result := True;
  DS := FDataLink.DataSet;
  if (R < 0) or (R >= Length(FCache)) then
    Exit(False);
  if DS.State = dsInsert then
  begin
    if R = FGrpIns then
      Exit;
  end
  else if R = FGrpActive then
    Exit;
  B := FRowBms[R];
  if Length(B) = 0 then
    Exit(False);
  Ver := FGrpViewVer;
  // Offene Bearbeitung buchen (wie MoveBy); das kann neu gruppieren
  if DS.State in dsEditModes then
    DS.CheckBrowseMode;
  if not DS.BookmarkValid(B) then
  begin
    if FGrpViewVer <> Ver then
      GroupFocusActive;
    Exit(False);
  end;
  Inc(FGrpMoving);
  Inc(FGrpQuiet);
  try
    DS.Bookmark := B;
  finally
    Dec(FGrpQuiet);
    Dec(FGrpMoving);
  end;
  if FGrpViewVer <> Ver then
  begin
    // Ansicht wurde neu aufgebaut (gebuchte Aenderung): Fokus selbst setzen
    GroupFocusActive;
    Result := False;
  end;
end;

procedure TPPGCustomDBGrid.GroupSelectRange(const FromBm: TBookmark);
var
  Order: TArray<Integer>;
  Cur: TBookmark;
  A, C, P0, P1, I, R: Integer;
begin
  Cur := FSelected.CurrentBookmark;
  if Length(Cur) = 0 then
    Exit;
  A := GroupIndexOfBm(FromBm);
  C := GroupIndexOfBm(Cur);
  if (A < 0) or (C < 0) then
  begin
    FSelected.AddBookmark(Cur);
    Exit;
  end;
  // Reihenfolge der Ansicht (auch zugeklappte Gruppen)
  Order := GroupDataRows(-1);
  P0 := -1;
  P1 := -1;
  for I := 0 to High(Order) do
  begin
    if Order[I] = FixedRows + A then
      P0 := I;
    if Order[I] = FixedRows + C then
      P1 := I;
  end;
  if (P0 < 0) or (P1 < 0) then
  begin
    FSelected.AddBookmark(Cur);
    Exit;
  end;
  if P0 > P1 then
  begin
    I := P0;
    P0 := P1;
    P1 := I;
  end;
  FSelected.BeginUpdate;
  try
    // AddBookmark fragt OnCanSelectRecord je Satz
    for I := P0 to P1 do
    begin
      R := Order[I] - FixedRows;
      if (R >= 0) and (R < Length(FRowBms)) and (Length(FRowBms[R]) > 0) then
        FSelected.AddBookmark(FRowBms[R]);
    end;
  finally
    FSelected.EndUpdate;
  end;
end;

procedure TPPGCustomDBGrid.GroupRecordChanged;
var
  R: Integer;
begin
  // Nur der aktive Satz (Feld geaendert); neu gruppiert wird nach dem Buchen
  if not FDataLink.Active then
    Exit;
  R := GroupIndexOfCurrent;
  if (R < 0) or (R >= Length(FCache)) then
    Exit;
  GroupReadRow(R, FDataLink.DataSet.State = dsInsert);
end;

procedure TPPGCustomDBGrid.GroupListChanged;
var
  R, C: Integer;
  L: TPPGDBGridColumn;
  Any: Boolean;
begin
  // Nachschlage-Spalten: Texte aus den gespeicherten Schluesseln neu
  Any := False;
  for C := 0 to High(FFields) do
  begin
    L := ColumnLookup(FixedCols + C);
    if L = nil then
      Continue;
    Any := True;
    for R := 0 to High(FCache) do
      if (C < Length(FCache[R])) and (C < Length(FGrpVals[R])) then
      begin
        if VarIsNull(FGrpVals[R][C]) or VarIsEmpty(FGrpVals[R][C]) then
          FCache[R][C] := ''
        else
          FCache[R][C] := L.LookupText(FGrpVals[R][C]);
      end;
  end;
  if Any then
    GroupApply;
end;

function TPPGCustomDBGrid.GroupFind(const U: string; Forward, IncludeCurrent, Prefix,
  OneCol: Boolean): Boolean;
var
  Order: TArray<Integer>;
  Cols: array of Integer;
  NC, CI, I, P, K, Total, Idx, R, DC, V, RowR, J, DJ: Integer;
  T: string;
  Ext: Boolean;
  RowU: TArray<string>;
begin
  Result := False;
  if (U = '') or (Length(FCache) = 0) then
    Exit;
  // Erweiterte Suche (nicht die Tippsuche): ganze Zeile pruefen
  Ext := FindExtendedSyntax and not Prefix;
  RowR := -1;
  // Spalten in Anzeige-Reihenfolge (Tippsuche: nur die Fokusspalte)
  SetLength(Cols, VisibleColCount);
  NC := 0;
  for I := FixedCols to VisibleColCount - 1 do
    if (OneCol and (I = FocusCol)) or (not OneCol and FindSearchColumn(DataCol(I))) then
    begin
      Cols[NC] := I;
      Inc(NC);
    end;
  if NC = 0 then
    Exit;
  CI := 0;
  for I := 0 to NC - 1 do
    if Cols[I] <= FocusCol then
      CI := I;
  // Zeilen in der Reihenfolge der Ansicht (auch zugeklappte Gruppen)
  Order := GroupDataRows(-1);
  P := 0;
  R := DataRow(FocusRow);
  if R < FixedRows then
    R := FixedRows + FGrpActive;
  for I := 0 to High(Order) do
    if Order[I] = R then
      P := I;
  Total := Length(Order) * NC;
  for K := 0 to Total - 1 do
  begin
    if Forward then
      Idx := P * NC + CI + K + Ord(not IncludeCurrent)
    else
      Idx := P * NC + CI - K - Ord(not IncludeCurrent);
    Idx := ((Idx mod Total) + Total) mod Total;
    R := Order[Idx div NC] - FixedRows;
    DC := DataCol(Cols[Idx mod NC]) - FixedCols;
    if (R < 0) or (R >= Length(FCache)) or (DC < 0) or (DC >= Length(FCache[R])) then
      Continue;
    T := AnsiUpperCase(FCache[R][DC]);
    if Ext then
    begin
      if R <> RowR then
      begin
        SetLength(RowU, NC);
        for J := 0 to NC - 1 do
        begin
          DJ := DataCol(Cols[J]) - FixedCols;
          if (DJ >= 0) and (DJ < Length(FCache[R])) then
            RowU[J] := AnsiUpperCase(FCache[R][DJ])
          else
            RowU[J] := '';
        end;
        RowR := R;
      end;
      if not FindRowHit(RowU, Idx mod NC) then
        Continue;
    end
    else if Prefix then
    begin
      if Copy(T, 1, Length(U)) <> U then
        Continue;
    end
    else if Pos(U, T) = 0 then
      Continue;
    // Treffer: Gruppen aufklappen, Zeile fokussieren (bewegt die Datenmenge)
    V := GroupReveal(FixedRows + R);
    if V < 0 then
      Exit;
    MoveFocus(Cols[Idx mod NC], V, False, True);
    Invalidate;
    Exit(True);
  end;
end;

function TPPGCustomDBGrid.EditAllowedAt(VRow: Integer): Boolean;
begin
  if FDataLink.Active and (FDataLink.DataSet.State = dsInsert) and IsActiveRecordRow(VRow) then
    Result := FAllowInsert
  else
    Result := FAllowEdit;
end;

function TPPGCustomDBGrid.IsActiveRecordRow(VRow: Integer): Boolean;
var
  R: Integer;
begin
  R := ActiveDataRow;
  Result := (R >= 0) and IsDataRow(VRow) and (DataRow(VRow) = R);
end;

function TPPGCustomDBGrid.MoveToNextCell: Boolean;
var
  DS: TDataSet;
begin
  // Am Zeilenende ungruppiert: naechster Satz der Datenmenge (bucht wie
  // Pfeil runter, haengt aber nichts an)
  if not FDataLink.Active or FGrpOn or CardMode or (FocusCol < VisibleColCount - 1) then
    Exit(inherited MoveToNextCell);
  DS := FDataLink.DataSet;
  if (DS.State = dsInsert) and not DS.Modified then
    Exit(False);
  DS.Next;
  if DS.Eof then
    Exit(False);
  Result := MoveFocus(FixedCols, FocusRow, False, True);
end;

function TPPGCustomDBGrid.CanSortColumn(ACol: Integer): Boolean;
var
  C: TPPGGridColumn;
begin
  // Kopfmenue wie der Kopfklick: Pfeil (SortOnHeaderClick), sortieren muss
  // die Datenmenge (OnSorted bzw. OnSortRequest)
  C := ColumnOf(ACol);
  Result := SortOnHeaderClick and (dgTitleClick in FDBOptions) and (ACol >= FixedCols) and
    (FieldOfCol(ACol) <> nil) and ((C = nil) or C.Sortable);
end;

function TPPGCustomDBGrid.GroupDateValue(ACol, ARow: Integer; out D: TDateTime): Boolean;
var
  R, C: Integer;
  F: TField;
  V: Variant;
begin
  R := ARow - FixedRows;
  C := ACol - FixedCols;
  F := FieldOfCol(ACol);
  if FGrpOn and (F <> nil) and IsDateField(F) and (R >= 0) and (R < Length(FGrpVals)) and
    (C >= 0) and (C < Length(FGrpVals[R])) then
  begin
    V := FGrpVals[R][C];
    Result := not (VarIsNull(V) or VarIsEmpty(V));
    if Result then
      D := VarToDateTime(V);
    Exit;
  end;
  Result := inherited GroupDateValue(ACol, ARow, D);
end;

function TPPGCustomDBGrid.ViewRecordNo: Integer;
var
  DS: TDataSet;
begin
  if FGrpOn then
    Exit(inherited ViewRecordNo);
  Result := 0;
  if not FDataLink.Active then
    Exit;
  DS := FDataLink.DataSet;
  if (DS.State <> dsInsert) and not DS.IsEmpty and DS.IsSequenced and (DS.RecNo > 0) then
    Result := DS.RecNo;
end;

function TPPGCustomDBGrid.ViewRecordCount: Integer;
begin
  if FGrpOn then
    Exit(inherited ViewRecordCount);
  Result := 0;
  if FDataLink.Active and not FDataLink.DataSet.IsEmpty then
    Result := Max(0, FDataLink.DataSet.RecordCount);
end;

function TPPGCustomDBGrid.ViewCanMove(Move: TPPGViewMove): Boolean;
var
  DS: TDataSet;
begin
  if FGrpOn then
    Exit(inherited ViewCanMove(Move));
  Result := False;
  if not FDataLink.Active then
    Exit;
  DS := FDataLink.DataSet;
  if DS.IsEmpty then
    Exit;
  if Move in [pvmFirst, pvmPrior] then
    Result := not DS.Bof
  else
    Result := not DS.Eof;
end;

function TPPGCustomDBGrid.ViewMove(Move: TPPGViewMove): Boolean;
var
  DS: TDataSet;
begin
  if FGrpOn then
    Exit(inherited ViewMove(Move));
  Result := ViewCanMove(Move);
  if not Result then
    Exit;
  DS := FDataLink.DataSet;
  case Move of
    pvmFirst: DS.First;
    pvmPrior: DS.Prior;
    pvmNext: DS.Next;
  else
    DS.Last;
  end;
end;

procedure TPPGCustomDBGrid.SetSortFromIndex(const Value: Boolean);
begin
  if FSortFromIndex = Value then
    Exit;
  FSortFromIndex := Value;
  if Value and not (csLoading in ComponentState) then
    SyncSortIndicator;
end;

function TPPGCustomDBGrid.SyncSortIndicator: Boolean;
var
  DS: TDataSet;
  S, Name: string;
  P, I, Col: Integer;
  Asc: Boolean;
  F: TField;
begin
  Result := False;
  if not FDataLink.Active then
    Exit;
  DS := FDataLink.DataSet;
  if not IsPublishedProp(DS, 'IndexFieldNames') then
    Exit;
  S := Trim(GetStrProp(DS, 'IndexFieldNames'));
  // Erstes Feld (Trenner ";"), Richtung ":D"/":A" bzw. " DESC"/" ASC"
  P := Pos(';', S);
  if P > 0 then
    S := Trim(Copy(S, 1, P - 1));
  Asc := True;
  Name := S;
  P := Pos(':', Name);
  if P > 0 then
  begin
    Asc := Pos('D', UpperCase(Copy(Name, P + 1, MaxInt))) = 0;
    Name := Trim(Copy(Name, 1, P - 1));
  end
  else if EndsText(' DESC', Name) then
  begin
    Asc := False;
    Name := Trim(Copy(Name, 1, Length(Name) - 5));
  end
  else if EndsText(' ASC', Name) then
    Name := Trim(Copy(Name, 1, Length(Name) - 4));
  Col := -1;
  if Name <> '' then
    for I := FixedCols to ColCount - 1 do
    begin
      F := FieldOfCol(I);
      if (F <> nil) and SameText(F.FieldName, Name) then
      begin
        Col := I;
        Break;
      end;
    end;
  if Col < 0 then
    Asc := True;
  if (Col = SortColumn) and (Asc = SortAscending) then
    Exit;
  SetSortIndicator(Col, Asc);
  Result := True;
end;

function TPPGCustomDBGrid.ColumnFilterValues(ACol, MaxCount: Integer): TArray<string>;
var
  DS: TDataSet;
  F: TField;
  Seen: TDictionary<string, Integer>;
  Texts: TArray<string>;
  Nums: TArray<Double>;
  Nulls: TArray<Boolean>;
  ByValue: Boolean;
  N, I, J, Pos0: Integer;
  S: string;
  Start: TBookmark;

  function Less(A, B: Integer): Boolean;
  begin
    if ByValue then
    begin
      if Nulls[A] or Nulls[B] then
        Exit(Nulls[A] and not Nulls[B]);
      Exit(Nums[A] < Nums[B]);
    end;
    Result := AnsiCompareText(Texts[A], Texts[B]) < 0;
  end;

var
  Order: TArray<Integer>;
  T: Integer;
begin
  // Gruppiert: alle Saetze im Speicher; ohne Datenmenge: nichts
  Result := nil;
  if not FDataLink.Active then
    Exit;
  if FGrpOn then
    Exit(inherited ColumnFilterValues(ACol, MaxCount));
  F := FieldOfCol(ACol);
  DS := FDataLink.DataSet;
  // Offene Bearbeitung: nur der Puffer (nichts buchen)
  if (F = nil) or (MaxCount <= 0) or (DS.State in dsEditModes) then
    Exit(inherited ColumnFilterValues(ACol, MaxCount));
  if DS.IsEmpty then
    Exit;
  ByValue := (F.FieldKind <> fkLookup) and not IsCheckColumn(ACol) and
    (ColumnLookup(ACol) = nil) and (IsNumberField(F) or IsDateField(F));
  Seen := TDictionary<string, Integer>.Create;
  try
    N := 0;
    Pos0 := TDataSetAccess(DS).ActiveRecord;
    Start := DS.Bookmark;
    PPGDBBeginRead;
    DS.DisableControls;
    try
      try
        DS.First;
        while not DS.Eof and (N < MaxCount) do
        begin
          S := Trim(FieldCellText(ACol, F));
          if not Seen.ContainsKey(S) then
          begin
            Seen.Add(S, N);
            SetLength(Texts, N + 1);
            SetLength(Nums, N + 1);
            SetLength(Nulls, N + 1);
            Texts[N] := S;
            Nulls[N] := F.IsNull;
            if ByValue and not F.IsNull then
              Nums[N] := F.AsFloat
            else
              Nums[N] := 0;
            Inc(N);
          end;
          DS.Next;
        end;
      finally
        GotoBookmarkAt(DS, Start, Pos0);
      end;
    finally
      DS.EnableControls;
      PPGDBEndRead;
    end;
  finally
    Seen.Free;
  end;
  SetLength(Order, N);
  for I := 0 to N - 1 do
    Order[I] := I;
  for I := 1 to N - 1 do
  begin
    T := Order[I];
    J := I - 1;
    while (J >= 0) and Less(T, Order[J]) do
    begin
      Order[J + 1] := Order[J];
      Dec(J);
    end;
    Order[J + 1] := T;
  end;
  SetLength(Result, N);
  for I := 0 to N - 1 do
    Result[I] := Texts[Order[I]];
end;

function TPPGCustomDBGrid.CompareDataRows(ACol, R1, R2: Integer): Integer;
var
  A, B, C: Integer;
  F: TField;
  V1, V2: Variant;
  N1, N2: Boolean;
  D1, D2: Double;
begin
  A := R1 - FixedRows;
  B := R2 - FixedRows;
  C := ACol - FixedCols;
  if not FGrpOn or (A < 0) or (B < 0) or (A >= Length(FGrpVals)) or (B >= Length(FGrpVals)) or
    (C < 0) or (C >= Length(FGrpVals[A])) or (C >= Length(FGrpVals[B])) then
    Exit(inherited CompareDataRows(ACol, R1, R2));
  // Zahlen und Datum nach Wert (leer zuerst), sonst nach dem angezeigten Text
  F := FieldOfCol(ACol);
  if (F <> nil) and (F.FieldKind <> fkLookup) and not IsCheckColumn(ACol) and
    (ColumnLookup(ACol) = nil) and (IsNumberField(F) or IsDateField(F)) then
  begin
    V1 := FGrpVals[A][C];
    V2 := FGrpVals[B][C];
    N1 := VarIsNull(V1) or VarIsEmpty(V1);
    N2 := VarIsNull(V2) or VarIsEmpty(V2);
    if N1 or N2 then
      Exit(Ord(not N1) - Ord(not N2));
    D1 := VarAsType(V1, varDouble);
    D2 := VarAsType(V2, varDouble);
    if D1 < D2 then
      Result := -1
    else if D1 > D2 then
      Result := 1
    else
      Result := 0;
    Exit;
  end;
  Result := AnsiCompareText(FCache[A][C], FCache[B][C]);
end;

function TPPGCustomDBGrid.ViewGroupKey(ACol, ARow: Integer): string;
var
  R, C: Integer;
  V: Variant;
begin
  Result := inherited ViewGroupKey(ACol, ARow);
  // Kaestchen gruppieren nach dem Wert (nicht nach 1/0)
  if not FGrpOn or not IsCheckColumn(ACol) then
    Exit;
  R := ARow - FixedRows;
  C := ACol - FixedCols;
  if (R < 0) or (R >= Length(FGrpVals)) or (C < 0) or (C >= Length(FGrpVals[R])) then
    Exit;
  V := FGrpVals[R][C];
  if VarIsNull(V) or VarIsEmpty(V) then
    Result := ''
  else
    Result := VarToStr(V);
end;

function TPPGCustomDBGrid.LocateRecord(const KeyFields: string; const KeyValues: Variant;
  Options: TLocateOptions): Boolean;
var
  DS: TDataSet;
begin
  Result := False;
  if not FDataLink.Active then
    Exit;
  DS := FDataLink.DataSet;
  // Offene Bearbeitung zuerst buchen (liest ggf. neu); der Satzwechsel selbst
  // liest nicht neu
  if DS.State in dsEditModes then
    DS.CheckBrowseMode;
  Inc(FGrpQuiet);
  try
    Result := DS.Locate(KeyFields, KeyValues, Options);
  finally
    Dec(FGrpQuiet);
  end;
end;

procedure TPPGCustomDBGrid.RefreshGroups;
begin
  if not FGrpOn then
    Exit;
  FGrpDirty := True;
  DataChanged;
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
