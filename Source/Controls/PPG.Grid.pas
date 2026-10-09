unit PPG.Grid;

{ TPPGGrid - Tabelle im Stil der Suite (Phase 6c).

  - Ein einziges Fenster, alle Zellen gezeichnet (keine Kind-Controls ausser
    dem gerade aktiven Editor). Scrollen, Overlay-Leisten, Mausrad und
    Auto-Scroll kommen aus TPPGCustomScrollControl.
  - Feste Kopfzeilen/-spalten (FixedRows/FixedCols) bleiben beim Scrollen
    stehen. Zeilenpositionen ueber TPPGRowLayout: 1 000 000 Zeilen in O(1).
  - Daten: Cells[] (wie TStringGrid) oder virtuell ueber OnGetCellText.
  - Sortieren (Klick auf den Kopf) und Filtern (Filterzeile) arbeiten auf
    einem Index-Array "sichtbare Zeile -> Datenzeile", nie auf den Daten.
    Row und Cells[] verwenden immer DATEN-Zeilen; Selection (TGridRect) ist
    in sichtbaren Zeilen (wie bei TStringGrid ohne Sortierung identisch).
  - Spalten (Columns): Titel, Breite, Ausrichtung, Editor (Text, Auswahl,
    Zahl, Kaestchen), Auswahlliste, Schreibschutz.
  - Spalten in der Anzeige (Phase 13b): verschieben (Ziehen am Kopf,
    goColMoving), ausblenden (Visible, Kopfmenue), Breite per Doppelklick,
    rechts fixieren (FixedColsRight), Baender (Bands) und Layout speichern.
  - Gruppieren und Summen (Phase 13c): Column.GroupIndex bzw. GroupBy, Gruppen-
    leiste (ShowGroupPanel, Kopf hineinziehen), Gruppenzeilen mit Pfeil und
    Markup-Text (OnGetGroupText), Summenzeile (ShowFooter) und Gruppenfuss
    (GroupFooter) ueber Column.Aggregate. Summen gelten fuer die Ansicht
    (gefiltert), werden beim Aendern von Ansicht oder Daten neu berechnet und
    zwischengespeichert - nie beim Zeichnen.
  - Zellen (Phase 13d): verbundene Zellen (MergeCells; nur ohne Sortierung,
    Filter und Gruppierung - dann ruhen sie), bedingte Formate
    (ConditionalFormats, OnGetCellStyle) und Zellarten je Spalte
    (Column.CellKind ueber IPPGCellKind: Kaestchen, Fortschritt, Sparkline,
    Bewertung, Bild, Link, Button, Farbfeld, Markup).
    Intern sind Spalten-Indizes von Geometrie, Fokus und Auswahl ANZEIGE-
    Spalten (wie sichtbare Zeilen); Cells[], Col, Columns[] und Ereignisse
    verwenden DATEN-Spalten. DataCol/VisualCol rechnen um.
  - Editoren sind PPGlow-Felder (TPPGEdit/TPPGComboBox/TPPGSpinEdit) ueber der
    Zelle: Enter uebernimmt, Esc verwirft, Tab uebernimmt und geht weiter,
    Scrollen und Fokusverlust uebernehmen.
  - Zwischenablage als TSV (Strg+C / Strg+V), Export als CSV.
  - DFM-kompatibel zu TStringGrid in den Grundproperties (ColCount, RowCount,
    FixedCols/Rows, DefaultColWidth/RowHeight, Options, ColWidths/RowHeights).
    Breiten und Hoehen sind wie ueberall in PPGlow logische 96-DPI-Pixel. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.Grids, Vcl.StdCtrls, Vcl.Forms, Vcl.Menus,
  PPG.Types, PPG.RowLayout, PPG.Render.Intf, PPG.Accessibility, PPG.UIA,
  PPG.Controls.Base, PPG.Controls.Scroll,
  PPG.Grid.Columns, PPG.Grid.View, PPG.Grid.Data, PPG.Grid.Paint, PPG.Grid.Edit, PPG.Markup, PPG.Markup.Parser,
  PPG.Grid.CellKinds, PPG.Grid.Styles, PPG.ElementStyle;

const
  gekText = PPG.Grid.Columns.gekText;
  gekNone = PPG.Grid.Columns.gekNone;
  gekCombo = PPG.Grid.Columns.gekCombo;
  gekSpin = PPG.Grid.Columns.gekSpin;
  gekCheck = PPG.Grid.Columns.gekCheck;

const
  // UI Automation: Arten der Elemente (0 = das Grid selbst)
  PPGUiaKindGridRow = 1;        // Datenzeile, A = Datenzeile
  PPGUiaKindGridCell = 2;       // Zelle, A = Datenzeile, B = Spalte
  PPGUiaKindGridHeaderRow = 3;  // feste Kopfzeile, A = Zeile
  PPGUiaKindGridHeaderCell = 4; // Kopfzelle, A = feste Zeile, B = Spalte
  PPGUiaKindGridGroup = 5;      // Gruppenkopf, A = Gruppe (13c)
  PPGUiaKindGridGroupFooter = 6; // Gruppenfuss, A = Gruppe

type
  // Spalten stehen seit Phase 13a in PPG.Grid.Columns; Aliase halten
  // bestehenden Code (uses PPG.Grid) unveraendert lauffaehig.
  TPPGGridEditorKind = PPG.Grid.Columns.TPPGGridEditorKind;
  TPPGGridColumn = PPG.Grid.Columns.TPPGGridColumn;
  TPPGGridColumns = PPG.Grid.Columns.TPPGGridColumns;

  TPPGGetCellTextEvent = procedure(Sender: TObject; ACol, ARow: Integer;
    var Text: string) of object;
  TPPGCompareCellsEvent = procedure(Sender: TObject; ACol, ARow1, ARow2: Integer;
    var Compare: Integer) of object;
  TPPGValidateCellEvent = procedure(Sender: TObject; ACol, ARow: Integer;
    var Value: string; var Accept: Boolean) of object;
  /// Kopfmenue anpassen (Eintraege ergaenzen, entfernen); ACol = Datenspalte.
  TPPGGridHeaderMenuEvent = procedure(Sender: TObject; ACol: Integer;
    Menu: TPopupMenu) of object;
  /// Text einer Gruppenzeile (Markup erlaubt); Group = Index fuer GroupInfo.
  TPPGGridGroupTextEvent = procedure(Sender: TObject; Group: Integer;
    var Text: string) of object;
  /// agCustom: Wert fuer Spalte ACol in Gruppe Group (-1 = Summenzeile).
  /// Die Zeilen liefert GroupDataRows(Group).
  TPPGGridCustomAggregateEvent = procedure(Sender: TObject; ACol, Group: Integer;
    var Value: string) of object;

  /// Darstellung je Zelle (nach den bedingten Formaten).
  TPPGGridCellStyleEvent = procedure(Sender: TObject; ACol, ARow: Integer;
    var Style: TPPGGridCellStyle) of object;
  /// Link-Zelle bzw. Link im Markup angeklickt (Link = Ziel bzw. Zelltext).
  TPPGGridLinkEvent = procedure(Sender: TObject; ACol, ARow: Integer;
    const Link: string) of object;
  TPPGGridCellEvent = procedure(Sender: TObject; ACol, ARow: Integer) of object;

  /// Verbundene Zellen (Datenspalte/-zeile der Ursprungszelle).
  TPPGGridMerge = record
    Col, Row, ColSpan, RowSpan: Integer;
  end;

  TPPGGridGroupInfo = record
    Level: Integer;
    Column: Integer;
    Key: string;
    Count: Integer;
    Expanded: Boolean;
    Parent: Integer;
  end;

  TPPGCustomGrid = class;

  /// Eine Zellaenderung fuer die inkrementelle Summe (intern, Audit 8c #6).
  TPPGGridAggChange = record
    Col, Row: Integer;
    OldText, NewText: string;
  end;

  // Editoren stehen seit Phase 13a in PPG.Grid.Edit (Registry).
  TPPGGridEdit = PPG.Grid.Edit.TPPGGridEdit;
  TPPGGridCombo = PPG.Grid.Edit.TPPGGridCombo;
  TPPGGridSpin = PPG.Grid.Edit.TPPGGridSpin;

  /// Farben eines Zeichenvorgangs (einmal berechnet, nicht je Zelle).
  TPPGGridPaintColors = record
    Fill, Text, Header, Line, Accent, Hint: TColor;
    // Anpassbarkeit: Kopftext, Linien im Kopf, Fokusrahmen; Modus der Stile
    HeaderText, HeaderLine, FocusFrame: TColor;
    UseColors: Boolean; // False: Hochkontrast oder VCL-Style (nur Schriften)
    Dark: Boolean;
    Gradient: Boolean; // DrawingStyle = gdsGradient
    CellStyles: Boolean; // Zeilen-/Spaltenflaechen aus Element-Stilen
    HeaderFont: TFont; // je Zeichenvorgang aus FFontCache
  end;

  TPPGCustomGrid = class(TPPGCustomScrollControl, IPPGAccessibleChildren, IPPGUiaSource,
    IPPGGridColumnsHost, IPPGGridViewHost, IPPGGridViewSortKeys, IPPGGridViewFilterKey,
    IPPGTableSource,
    IPPGGridStylesHost, IPPGGridPrintSource, IPPGTableExport, IPPGTableLook)
  private
    FPaint: TPPGGridPaintColors;
    FColCount: Integer;
    FRowCount: Integer;
    FFixedCols: Integer;
    FFixedRows: Integer;
    // FixedRows aus der DFM, das (alte Reihenfolge) vor RowCount kam
    FLoadFixedRows: Integer;
    FDefaultColWidth: Integer;
    FDefaultRowHeight: Integer;
    FColWidths: array of Integer;   // logisch, 0 = Standard (ohne Spalte)
    // Eigene Zeilenhoehen je Datenzeile (logisch), duenn besetzt (Audit 8c #5)
    FRowHeightStore: TPPGRowLayout;
    FHasRowHeights: Boolean;
    FStore: TPPGCellStore;         // Cells[] (PPG.Grid.Data)
    FPainter: TPPGCellPainter;     // Texte, Zellarten (PPG.Grid.Paint)
    FOptions: TGridOptions;
    FColumns: TPPGGridColumns;
    FBands: TPPGGridBands;
    FVisCols: array of Integer;     // Anzeige-Spalte -> Datenspalte (sichtbare)
    FColVis: array of Integer;      // Datenspalte -> Anzeige-Spalte (-1 = aus)
    FFixedColsRight: Integer;
    FHeaderMenu: Boolean;
    FColDragging: Boolean;
    FColDropAt: Integer;            // Einfuegeposition (Anzeige) beim Ziehen
    FHeaderMenuObj: TPopupMenu;     // zuletzt gezeigtes Kopfmenue
    FShowFooter: Boolean;
    FGroupFooter: Boolean;
    FShowGroupPanel: Boolean;
    FGroupCols: TArray<Integer>;    // angewandte Gruppenspalten (Ebene 0 zuerst)
    FAggCols: TArray<Integer>;      // Datenspalten mit Aggregate
    FFooterAcc: array of TPPGAggregateAcc;
    FGroupAcc: array of array of TPPGAggregateAcc; // [Gruppe][k]
    FFooterCustom: array of string;
    FGroupCustom: array of array of string;
    FAggDirty: Boolean;
    FAggPosted: Boolean;
    // Audit 8c #6: Einzelaenderungen fuer die inkrementelle Summe (verzoegert
    // bis zur geposteten Nachricht bzw. FooterText)
    FAggPend: array of TPPGGridAggChange;
    FAggPendCount: Integer;
    FAggHasCustom: Boolean;      // agCustom in der letzten Rechnung
    FAggRowLeaf: TArray<Integer>; // Datenzeile -> unterste Gruppe (bei Bedarf)
    FDataVersion: Integer;       // zaehlt Datenaenderungen (Cells, Zeilenzahl)
    FAggViewKey: string;         // Zeilenmenge der letzten Rechnung (Audit 8c #7)
    FFilterEvalCount: Integer;   // Aufrufe von RowPassesFilter (Tests)
    FDropToGroup: Boolean;
    FGroupMarkup: TPPGMarkupLayout;
    FCondFormats: TPPGGridConditionalFormats;
    FMerges: array of TPPGGridMerge;
    FKindCtx: TPPGCellKindContext;  // je Zeichenvorgang gefuellt
    FStyles: TPPGGridStyles;
    // Schriften der Element-Stile; bleiben ueber Zeichenvorgaenge (Audit 8c
    // #10), geleert bei Schrift-, Stil-, Spalten-, DPI- und Theme-Aenderung
    FFontCache: TPPGFontCache;
    FFontCachePPI: Integer;
    // Waehrend PaintViewport: Werte, die RawCellRect/ColLeft je Zelle brauchen
    FPaintCached: Boolean;
    FPaintGV: TRect;
    FPaintMaxColScroll: Integer;
    FPaintFirstRight: Integer;
    FHotV: Integer;              // Zeile unter der Maus (Styles.HotRow)
    FGridLineWidth: Integer;
    FDrawingStyle: TGridDrawingStyle;
    FGradientStartColor: TColor;
    FGradientEndColor: TColor;
    FLayout: TPPGRowLayout;
    FColX: array of Integer;        // Pixel-Anfang je Spalte (+ Ende)
    // Audit 8c #2/#5: Spalten- und Zeilengeometrie getrennt (Spaltenbreite
    // ziehen baut die Zeilen nicht neu auf)
    FColGeomValid: Boolean;
    FRowGeomValid: Boolean;
    FGeomPPI: Integer;
    FAggSig: string;            // Aggregate der Spalten bei der letzten Rechnung
    FAggRecalcCount: Integer;   // volle Neuberechnungen (Tests)
    FRowGeomCount: Integer;     // Neuaufbau der Zeilengeometrie (Tests)
    FView: TPPGGridView;           // Filter -> Sortieren (PPG.Grid.View)
    FSortCol: Integer;
    FSortAscending: Boolean;
    FSortOnHeaderClick: Boolean;
    FFilters: array of string;
    FFilterUpper: array of string;  // Filter in Grossbuchstaben (je Lauf, Audit 8c #3)
    FShowFilterRow: Boolean;
    FFocusC: Integer;
    FFocusV: Integer;
    FAnchorC: Integer;
    FAnchorV: Integer;
    FMouseSel: Boolean;
    FSizingCol: Integer;
    FSizingStartX: Integer;
    FSizingStartW: Integer;
    FHeaderDown: Integer;
    FHeaderDownPos: TPoint;
    FEditor: TPPGCustomControl;
    FEditKind: TPPGGridEditorKind;
    FEditC: Integer;
    FEditV: Integer;
    FEditCanceled: Boolean;
    FItemCanvas: TCanvas;
    FInOwnerDraw: Boolean;
    FDefaultDrawing: Boolean;
    FToolTips: Boolean;
    FLastFocusRow: Integer;
    FBorderStyle: TBorderStyle;
    FOnGetCellText: TPPGGetCellTextEvent;
    FOnCompareCells: TPPGCompareCellsEvent;
    FOnValidateCell: TPPGValidateCellEvent;
    FOnSelectCell: TSelectCellEvent;
    FOnDrawCell: TDrawCellEvent;
    FOnGetEditText: TGetEditEvent;
    FOnSetEditText: TSetEditEvent;
    FOnFixedCellClick: TFixedCellClickEvent;
    FOnTopLeftChanged: TNotifyEvent;
    FOnSorted: TNotifyEvent;
    FOnColumnMoved: TMovedEvent;
    FOnHeaderMenu: TPPGGridHeaderMenuEvent;
    FOnGetGroupText: TPPGGridGroupTextEvent;
    FOnCustomAggregate: TPPGGridCustomAggregateEvent;
    FOnGetCellStyle: TPPGGridCellStyleEvent;
    FOnLinkClick: TPPGGridLinkEvent;
    FOnCellButtonClick: TPPGGridCellEvent;
    FOnColEnter: TNotifyEvent;
    FOnColExit: TNotifyEvent;
    FOnEditButtonClick: TNotifyEvent;
    procedure SetDefaultDrawing(const Value: Boolean);
    procedure SetColCount(const Value: Integer);
    procedure SetRowCount(const Value: Integer);
    procedure SetFixedCols(const Value: Integer);
    procedure SetFixedRows(const Value: Integer);
    procedure SetDefaultColWidth(const Value: Integer);
    procedure SetDefaultRowHeight(const Value: Integer);
    procedure SetOptions(const Value: TGridOptions);
    procedure SetColumns(const Value: TPPGGridColumns);
    procedure SetBands(const Value: TPPGGridBands);
    procedure SetFixedColsRight(const Value: Integer);
    procedure HeaderMenuClick(Sender: TObject);
    procedure SetShowFooter(const Value: Boolean);
    procedure SetGroupFooter(const Value: Boolean);
    procedure SetShowGroupPanel(const Value: Boolean);
    procedure AggregatesChanged;
    procedure SetConditionalFormats(const Value: TPPGGridConditionalFormats);
    procedure SetShowFilterRow(const Value: Boolean);
    procedure SetBorderStyle(const Value: TBorderStyle);
    procedure SetStyles(const Value: TPPGGridStyles);
    procedure StylesObjChanged(Sender: TObject);
    procedure SetGridLineWidth(const Value: Integer);
    procedure SetDrawingStyle(const Value: TGridDrawingStyle);
    procedure SetGradientStartColor(const Value: TColor);
    procedure SetGradientEndColor(const Value: TColor);
    function GetFixedColor: TColor;
    procedure SetFixedColor(const Value: TColor);
    procedure SetHotRow(VRow: Integer);
    /// Nur eine sichtbare Zeile neu zeichnen (ganze Breite), Audit 8b.
    procedure InvalidateViewRow(VRow: Integer);
    function GetCells(ACol, ARow: Integer): string;
    procedure SetCells(ACol, ARow: Integer; const Value: string);
    function GetColWidths(Index: Integer): Integer;
    procedure SetColWidths(Index: Integer; const Value: Integer);
    function GetRowHeights(Index: Integer): Integer;
    procedure SetRowHeights(Index: Integer; const Value: Integer);
    function GetFilter(ACol: Integer): string;
    procedure SetFilter(ACol: Integer; const Value: string);
    function GetRow: Integer;
    procedure SetRow(const Value: Integer);
    function GetCol: Integer;
    procedure SetCol(const Value: Integer);
    function GetSelection: TGridRect;
    procedure SetSelection(const Value: TGridRect);
    function GetEditorMode: Boolean;
    procedure SetEditorMode(const Value: Boolean);
    function GetCanvas: TCanvas;
    procedure ReadColWidths(Reader: TReader);
    procedure WriteColWidths(Writer: TWriter);
    procedure ReadRowHeights(Reader: TReader);
    procedure WriteRowHeights(Writer: TWriter);
    procedure CheckCell(ACol, ARow: Integer);
    procedure EditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditorChange(Sender: TObject);
    procedure EditorExit(Sender: TObject);
    function EditorText: string;
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
    procedure CMEnter(var Message: TCMEnter); message CM_ENTER;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
  protected
    procedure WndProc(var Message: TMessage); override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure Scrolled; override;
    { Geometrie }
    procedure InvalidateGeometry;
    /// Nur die Spalten (Breite, Reihenfolge, Sichtbarkeit) neu.
    procedure InvalidateColGeometry;
    procedure EnsureGeometry;
    procedure BuildRowGeometry(PPI: Integer);
    /// Aggregate der Spalten als Text (aendert er sich, wird neu gerechnet).
    function AggSignature: string;
    /// Zaehler fuer Tests: volle Summen-Rechnungen, Neuaufbau der Zeilen.
    property AggRecalcCount: Integer read FAggRecalcCount;
    property RowGeomCount: Integer read FRowGeomCount;
    function VFixedRows: Integer;
    function VRowCount: Integer;
    function FixedWidth: Integer;
    function FixedHeight: Integer;
    function ColPixelWidth(ACol: Integer): Integer;
    { Spalten in der Anzeige (Phase 13b) }
    procedure RebuildColumnMap;
    function VColCount: Integer;
    /// Erste rechts fixierte Anzeige-Spalte (= VColCount ohne solche).
    function FirstRightCol: Integer;
    function FixedRightWidth: Integer;
    /// Hoehe der Baender ueber dem Kopf (Pixel).
    function BandHeight: Integer;
    /// ViewRect ohne Baender: hier liegen die Zellen.
    function GridViewRect: TRect;
    /// Linke Kante einer Anzeige-Spalte relativ zur Ansicht (ohne RTL).
    function ColLeft(VCol: Integer): Integer;
    function MaxColScroll: Integer;
    /// Darf die Anzeige-Spalte verschoben werden (Spalten vorhanden, nicht fest)?
    function CanMoveColumn(VCol: Integer): Boolean;
    /// Sortierschluessel der Anzeige-Reihenfolge (DisplayIndex bzw. Index).
    function ColumnSortKey(ACol: Integer): Integer;
    /// Einfuegeposition (Anzeige) fuer Mausposition X beim Ziehen.
    function ColumnDropAt(X: Integer): Integer;
    procedure PaintBands(const ACanvas: IPPGCanvas; const View: TRect);
    /// Schluessel einer Datenspalte fuer SaveLayout (Standard: Index; DB-Grid:
    /// Feldname).
    function ColumnKey(ACol: Integer): string; virtual;
    /// Kopfmenue zeigen (Bildschirmkoordinaten).
    procedure ShowHeaderMenu(ACol: Integer; const P: TPoint);
    { Gruppieren und Summen (Phase 13c) }
    /// Darf das Grid gruppieren? (DB-Grid: nein)
    /// Darf das Grid gruppieren und rechnet es Summen/Sortierung selbst
    /// (Ansicht im Speicher)? DB-Grid: nein - das ist Sache der Datenmenge.
    function CanGroup: Boolean; virtual;
    /// Collection der angezeigten Spalten (fuer BeginUpdate/EndUpdate).
    function ColumnCollection: TPPGGridColumns; virtual;
    /// Gruppenspalten aus Columns[].GroupIndex.
    function CurrentGroupColumns: TArray<Integer>;
    function ViewGroupKey(ACol, ARow: Integer): string; virtual;
    function GroupPanelHeight: Integer;
    function FooterHeight: Integer;
    function GroupPanelRect: TRect;
    /// Rechtecke der Gruppen-Chips in der Leiste (Client-Koordinaten).
    function GroupChipRects: TArray<TRect>;
    procedure PaintGroupPanel(const ACanvas: IPPGCanvas; const R: TRect);
    procedure PaintFooter(const ACanvas: IPPGCanvas; const R: TRect);
    procedure PaintGroupRow(const ACanvas: IPPGCanvas; VRow: Integer; const Clip: TRect;
      MainArea: Boolean);
    /// Gruppe einer Ansichtszeile (-1 = keine Gruppenzeile); Footer = Gruppenfuss.
    function GroupAtRow(VRow: Integer; out Footer: Boolean): Integer;
    /// Text einer Gruppenzeile (Kopf: GroupText, Fuss: Summen) fuer Screenreader.
    function GroupRowName(VRow: Integer): string;
    /// Gruppe einer Gruppenfuss-Zeile (-1 = keine).
    function GroupOfFooterRow(VRow: Integer): Integer;
    function AggIndex(ACol: Integer): Integer;
    /// Zwischengespeicherte Summen (ohne Neuberechnung; fuer das Zeichnen).
    function CachedFooterText(ACol: Integer): string; virtual;
    function CachedGroupFooterText(Group, ACol: Integer): string;
    function GroupChipCaption(Index: Integer): string;
    /// Pfeil einer Gruppenkopfzeile (Client-Koordinaten).
    function GroupExpanderRect(VRow: Integer): TRect;
    /// Spalte zur Gruppierung hinzufuegen bzw. herausnehmen.
    procedure AddGroupColumn(ACol: Integer);
    procedure RemoveGroupColumn(ACol: Integer);
    procedure GroupPanelClick(X, Y: Integer);
    /// Kopf ziehen erlaubt (Verschieben oder in die Gruppenleiste)?
    function CanDragColumn(VCol: Integer): Boolean;
    { Zellen (Phase 13d) }
    /// IPPGGridStylesHost: Regeln geaendert.
    procedure StylesChanged;
    /// Zellart einer Datenspalte (nil = Text).
    function KindOf(ACol: Integer): IPPGCellKind; virtual;
    /// Kontext fuer Zellarten (Farben, Schrift ...) fuer diesen Zeichenvorgang.
    procedure PrepareKindContext(const ACanvas: IPPGCanvas);
    /// Zellart-Kontext mit dem Bereich der Spalte.
    function KindContext(ACol: Integer): TPPGCellKindContext;
    /// Aktion einer Zellart ausfuehren (Wert setzen, Link, Button).
    procedure DoCellAction(Action: TPPGCellAction; ACol, VRow: Integer; const NewText: string);
    /// Taste an die Zellart der Fokuszelle; True = verarbeitet.
    function KindKey(Key: Word; CharKey: Boolean = False): Boolean;
    /// Stil einer Datenzelle (bedingte Formate + OnGetCellStyle).
    function CellStyle(ACol, ARow: Integer; const Text: string): TPPGGridCellStyle;
    /// Verbindungen wirken nur ohne Sortierung/Filter/Gruppierung.
    function MergesActive: Boolean;
    /// Anzeige-Bereich (inklusive) der Verbindung I; False = ruht.
    function VisualMerge(I: Integer; out C0, R0, C1, R1: Integer): Boolean;
    /// Verbindung, die die Anzeige-Zelle enthaelt.
    function MergeAtCell(VCol, VRow: Integer; out C0, R0, C1, R1: Integer): Boolean;
    /// Pixel-Rechteck eines Anzeige-Bereichs (ohne Sichtbarkeitspruefung).
    function RangeRect(C0, R0, C1, R1: Integer): TRect;
    procedure ComputeCondStats;
    /// Summen oder Statistiken fuer bedingte Formate muessen nach einer
    /// Zellaenderung neu gerechnet werden.
    function StatsNeeded: Boolean;
    { Inkrementelle Summen (Audit 8c #6) }
    /// Eine Datenzelle hat sich geaendert (Cells, SetCellByUser).
    procedure CellDataChanged(ACol, ARow: Integer; const OldText, NewText: string;
      HaveOld: Boolean);
    /// Laesst sich eine Aenderung dieser Spalte inkrementell verrechnen?
    function AggIncrementalOk(ACol: Integer): Boolean;
    /// Vorgemerkte Einzelaenderungen verrechnen (sonst voll neu rechnen).
    procedure ApplyPendingAggregates;
    function ApplyAggChange(const Ch: TPPGGridAggChange): Boolean;
    procedure ClearPendingAggregates;
    procedure PostAggregateMessage;
    /// Unterste Gruppe einer Datenzeile (-1 = nicht in der Ansicht).
    function LeafGroupOf(ARow: Integer): Integer;
    /// Datenzeile in der (ungruppierten) Ansicht?
    function RowInView(ARow: Integer): Boolean;
    /// Text kommt direkt aus Cells (kein OnGetCellText, GetCellText nicht
    /// ueberschrieben)?
    function PlainCellText: Boolean;
    { Zeilen-Abbildung (Sortieren/Filtern) }
    procedure RebuildMap;
    function CompareDataRows(ACol, R1, R2: Integer): Integer; virtual;
    function RowPassesFilter(ARow: Integer): Boolean; virtual;
    /// Filtertexte in Grossbuchstaben vorbereiten (vor jedem Filterlauf).
    procedure PrepareFilters;
    { IPPGGridViewHost }
    function ViewRowPasses(ARow: Integer): Boolean;
    function ViewCompareRows(ACol, R1, R2: Integer): Integer;
    { IPPGGridViewSortKeys (Audit 8c #1): nur mit dem Standardvergleich }
    function ViewSortKeys(ACol: Integer; const Rows: TArray<Integer>;
      out Keys: TArray<TPPGGridSortKey>): Boolean;
    /// Vergleicht das Grid mit der Standardlogik (kein OnCompareCells, kein
    /// ueberschriebenes CompareDataRows)?
    function StandardCompare: Boolean;
    { IPPGGridViewFilterKey (Audit 8c #7): Filtertexte + Datenstand; '' bei
      virtuellen Texten oder eigenem RowPassesFilter }
    function ViewFilterKey: string;
    /// Schluessel der Zeilenmenge, ueber die summiert wird ('' = immer neu
    /// rechnen): gleich = reines Umsortieren, die Summen bleiben.
    function AggViewKey: string;
    /// Zaehler fuer Tests: Aufrufe von RowPassesFilter.
    property FilterEvalCount: Integer read FFilterEvalCount;
    { IPPGTableSource (Druck, Export) }
    function TableColCount: Integer; virtual;
    function TableRowCount: Integer; virtual;
    function TableColumn(ACol: Integer): TPPGTableColumnInfo; virtual;
    function TableCellText(ACol, ARow: Integer): string; virtual;
    function TableCellValue(ACol, ARow: Integer): Variant; virtual;
    { IPPGGridPrintSource (Druck) }
    function PrintCellStyle(ACol, ARow: Integer; const Text: string): TPPGGridCellStyle; virtual;
    function PrintCellKind(ACol: Integer; out Ctx: TPPGCellKindContext): IPPGCellKind; virtual;
    function PrintFont: TFont;
    function PrintRowHeight: Integer;
    { IPPGTableExport (xlsx) }
    function ExportAggregate(ACol: Integer): TPPGGridAggregate; virtual;
    function ExportMerges: TArray<TRect>; virtual;
    function ExportOutline: TArray<TPPGOutlineRow>; virtual;
    { IPPGTableLook (xlsx: Optik wie im Grid, immer hell) }
    function ExportLook: TPPGTableLook;
    function ExportColumnLook(ACol: Integer): TPPGTableColumnLook; virtual;
    function ExportCellStyle(ACol, ARow: Integer; const Text: string;
      Alternate: Boolean): TPPGGridCellStyle;
    function ExportBands: TArray<TPPGTableBand>;
    function ExportFooterText(ACol: Integer): string;
    /// Datenspalte einer Tabellen-Spalte (DB-Grid: ohne Indikator).
    function TableDataCol(ACol: Integer): Integer; virtual;
    /// Zeile fuer OnGetCellStyle beim Export (Grid: Datenzeile, DB-Grid: Satz).
    function TableStyleRow(ARow: Integer): Integer; virtual;
    { Daten }
    /// Text einer Datenzelle (Cells bzw. OnGetCellText, Kopf aus Columns).
    function GetCellText(ACol, ARow: Integer): string; virtual;
    /// Wert setzen (Editor, Einfuegen): Cells + OnSetEditText.
    procedure SetCellByUser(ACol, ARow: Integer; const Value: string); virtual;
    /// Editor ist sichtbar geworden (ARow = Datenzeile, FilterRowMark = Filter).
    procedure EditorOpened(ACol, ARow: Integer); virtual;
    /// Der Anwender hat den Text im Editor einer Datenzeile geaendert (DB-Grid:
    /// Bearbeiten-Modus beim ersten Tastendruck).
    procedure EditorEdited; virtual;
    /// Vor einem Umbau der Ansicht: offenen Editor uebernehmen, bei
    /// abgelehnter Validierung verwerfen (sonst zeigt er auf eine andere Zeile).
    procedure EndEditorForRebuild;
    /// Text fuer den Editor (Standard: Zelltext + OnGetEditText). Das DB-Grid
    /// liefert Field.Text statt des Anzeigetexts.
    function GetEditText(ACol, ARow: Integer): string; virtual;
    function ColumnOf(ACol: Integer): TPPGGridColumn; virtual;
    /// Erzeugt die Spalten-Collection (DB-Grid: eigene Spaltenklasse).
    function CreateColumns: TPPGGridColumns; virtual;
    /// Spalten geaendert (Standard: Spaltenzahl folgt den Spalten).
    procedure ColumnsChanged; virtual;
    /// Senkrechte Verschiebung der Datenzeilen in Pixeln. Standard: ScrollY.
    /// Das DB-Grid zeigt nur seinen Puffer (immer 0) und nutzt die Leiste
    /// fuer die Lage in der Datenmenge.
    function RowScrollY: Integer; virtual;
    /// Inhaltshoehe fuer die Scroll-Basis (Standard: Hoehe aller Zeilen).
    function RowsContentHeight: Integer; virtual;
    /// Lage setzen, um eine Zelle sichtbar zu machen (Standard: ScrollTo).
    procedure ScrollCellsTo(X, Y: Integer); virtual;
    function CellEditorKind(ACol, ARow: Integer): TPPGGridEditorKind; virtual;
    procedure ColEnter; virtual;
    procedure ColExit; virtual;
    procedure EditButtonClick; virtual;
    procedure EditorEllipsisClick(Sender: TObject);
    /// ACol = Datenspalte, VRow = sichtbare Zeile.
    function CanEditCell(ACol, VRow: Integer): Boolean; virtual;
    { Zeichnen }
    function FrameInset: Integer; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure PaintViewport(const ACanvas: IPPGCanvas; const View: TRect); override;
    /// Owner-Draw einer Zelle (OnDrawCell); Hintergrund und Text sind gezeichnet.
    procedure DrawCell(const ACanvas: IPPGCanvas; ACol, VRow: Integer; const R: TRect); virtual;
    procedure DrawCellExtras(const ACanvas: IPPGCanvas; ACol, VRow: Integer;
      const R: TRect; const S: string);
    procedure PaintRegion(const ACanvas: IPPGCanvas; ColFrom, ColTo, RowFrom, RowTo: Integer;
      const AClip: TRect; FixedArea: Boolean);
    function RawCellRect(ACol, VRow: Integer): TRect;
    function GetScrollStyle: TPPGSurfaceStyle; override;
    function GetBackgroundColor: TColor; override;
    procedure GetGridColors(out Fill, Text, Header, Line, Accent: TColor);
    /// Farben und Schriften der Element-Stile fuer diesen Zeichenvorgang.
    procedure PrepareStyleColors;
    /// Schrift (und Textfarbe) einer Datenzelle nach Spalte, Zeile und Zellstil.
    function CellFont(Col: TPPGGridColumn; const St: TPPGGridCellStyle; Extra: TFontStyles): TFont;
    /// Schriften der Element-Stile verwerfen (Schrift, Stil, Spalten geaendert).
    procedure FontsChanged;
    { Eingabe }
    procedure ContentMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure ContentMouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure ContentMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoAutoScroll(const P: TPoint); override;
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    /// Eigene Tastennavigation (Audit 7c #1): laeuft in KeyDown NACH OnKeyDown
    /// und nur, wenn das Ereignis die Taste nicht verbraucht hat (Key <> 0).
    procedure NavigateKey(var Key: Word; Shift: TShiftState); virtual;
    procedure KeyPress(var Key: Char); override;
    function SizingColAt(X, Y: Integer): Integer;
    /// Fokus auf eine Zelle (sichtbare Zeile); Extend = Bereich vom Anker.
    function MoveFocus(ACol, VRow: Integer; Extend, ByUser: Boolean): Boolean;
    function SelectCell(ACol, ARow: Integer): Boolean; virtual;
    /// ACol = Datenspalte, VRow = sichtbare Zeile.
    procedure ToggleCheck(ACol, VRow: Integer);
    /// ACol = Datenspalte, VRow = feste Zeile.
    procedure HeaderClicked(ACol, VRow: Integer); virtual;
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); override;
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
    { UI Automation (IPPGUiaSource): Tabelle mit Kopfzeilen (Art 3/4) und
      Datenzeilen (Art 1) mit Zellen (Art 2). Grid-/Table-Muster zaehlen nur
      Datenzeilen und -spalten (ohne feste Zeilen/Spalten und Filterzeile). }
    function UiaValid(const Id: TPPGUiaId): Boolean; virtual;
    function UiaParent(const Id: TPPGUiaId): TPPGUiaId; virtual;
    function UiaChildCount(const Id: TPPGUiaId): Integer; virtual;
    function UiaChild(const Id: TPPGUiaId; Index: Integer): TPPGUiaId; virtual;
    function UiaIndexInParent(const Id: TPPGUiaId): Integer; virtual;
    function UiaElementAt(X, Y: Integer): TPPGUiaId; virtual;
    function UiaFocused: TPPGUiaId; virtual;
    function UiaFromAccChild(ChildId: Integer): TPPGUiaId; virtual;
    function UiaControlType(const Id: TPPGUiaId): Integer; virtual;
    function UiaName(const Id: TPPGUiaId): string; virtual;
    function UiaRect(const Id: TPPGUiaId): TRect; virtual;
    function UiaEnabled(const Id: TPPGUiaId): Boolean; virtual;
    function UiaFocusable(const Id: TPPGUiaId): Boolean; virtual;
    function UiaProperty(const Id: TPPGUiaId; PropertyId: Integer; out Value: OleVariant): Boolean; virtual;
    function UiaHasPattern(const Id: TPPGUiaId; PatternId: Integer): Boolean; virtual;
    function UiaCanSelectMultiple: Boolean; virtual;
    function UiaSelection: TPPGUiaIds; virtual;
    function UiaIsSelected(const Id: TPPGUiaId): Boolean; virtual;
    procedure UiaGridSize(out Rows, Cols: Integer); virtual;
    function UiaGridItem(Row, Col: Integer): TPPGUiaId; virtual;
    procedure UiaGridPos(const Id: TPPGUiaId; out Row, Col: Integer); virtual;
    function UiaHeaders(Columns: Boolean): TPPGUiaIds; virtual;
    function UiaItemHeaders(const Id: TPPGUiaId; Columns: Boolean): TPPGUiaIds; virtual;
    function UiaValue(const Id: TPPGUiaId): string; virtual;
    function UiaReadOnly(const Id: TPPGUiaId): Boolean; virtual;
    function UiaExpandState(const Id: TPPGUiaId): Integer; virtual;
    function UiaToggleState(const Id: TPPGUiaId): Integer; virtual;
    procedure UiaExecute(const Id: TPPGUiaId; Action: TPPGUiaAction; const Value: string); virtual;
    /// Sichtbare Zeile eines Elements (Zeile/Zelle/Kopf); -1 = keine.
    function UiaVRow(const Id: TPPGUiaId): Integer;
    /// Element der Fokuszelle bzw. einer Zelle (Spalte, sichtbare Zeile).
    function UiaCellId(ACol, VRow: Integer): TPPGUiaId;
    /// Element einer Gruppenzeile (Kopf oder Fuss).
    function UiaGroupId(VRow: Integer): TPPGUiaId;

    property ColCount: Integer read FColCount write SetColCount default 5;
    property RowCount: Integer read FRowCount write SetRowCount default 5;
    property FixedCols: Integer read FFixedCols write SetFixedCols default 1;
    property FixedRows: Integer read FFixedRows write SetFixedRows default 1;
    property DefaultColWidth: Integer read FDefaultColWidth write SetDefaultColWidth default 64;
    property DefaultRowHeight: Integer read FDefaultRowHeight write SetDefaultRowHeight default 24;
    property DefaultDrawing: Boolean read FDefaultDrawing write SetDefaultDrawing default True;
    /// Abgeschnittene Zelltexte als Hinweis (wie TTreeView.ToolTips; nur ohne
    /// eigenen Hint, braucht ShowHint). Audit 7f #1.
    property ToolTips: Boolean read FToolTips write FToolTips default True;
    property Options: TGridOptions read FOptions write SetOptions
      default [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect];
    property Columns: TPPGGridColumns read FColumns write SetColumns;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
    property ShowFilterRow: Boolean read FShowFilterRow write SetShowFilterRow default False;
    property SortOnHeaderClick: Boolean read FSortOnHeaderClick write FSortOnHeaderClick default True;
    property OnGetCellText: TPPGGetCellTextEvent read FOnGetCellText write FOnGetCellText;
    property OnCompareCells: TPPGCompareCellsEvent read FOnCompareCells write FOnCompareCells;
    property OnValidateCell: TPPGValidateCellEvent read FOnValidateCell write FOnValidateCell;
    property OnSelectCell: TSelectCellEvent read FOnSelectCell write FOnSelectCell;
    property OnDrawCell: TDrawCellEvent read FOnDrawCell write FOnDrawCell;
    property OnGetEditText: TGetEditEvent read FOnGetEditText write FOnGetEditText;
    property OnSetEditText: TSetEditEvent read FOnSetEditText write FOnSetEditText;
    property OnFixedCellClick: TFixedCellClickEvent read FOnFixedCellClick write FOnFixedCellClick;
    property OnTopLeftChange: TNotifyEvent read FOnTopLeftChanged write FOnTopLeftChanged;
    property OnSorted: TNotifyEvent read FOnSorted write FOnSorted;
    property Bands: TPPGGridBands read FBands write SetBands;
    /// Anzahl Spalten, die rechts stehen bleiben (z.B. Aktionsspalte).
    property FixedColsRight: Integer read FFixedColsRight write SetFixedColsRight default 0;
    /// Rechtsklick auf den Kopf: Sortieren, Ausblenden, Spaltenauswahl, Breite.
    property HeaderMenu: Boolean read FHeaderMenu write FHeaderMenu default True;
    /// Spalte verschoben (FromIndex/ToIndex = Anzeige-Positionen).
    property OnColumnMoved: TMovedEvent read FOnColumnMoved write FOnColumnMoved;
    property OnHeaderMenu: TPPGGridHeaderMenuEvent read FOnHeaderMenu write FOnHeaderMenu;
    /// Summenzeile unten (Column.Aggregate).
    property ShowFooter: Boolean read FShowFooter write SetShowFooter default False;
    /// Fusszeile mit Summen unter jeder Gruppe.
    property GroupFooter: Boolean read FGroupFooter write SetGroupFooter default False;
    /// Leiste ueber dem Grid: Kopf hineinziehen gruppiert nach der Spalte.
    property ShowGroupPanel: Boolean read FShowGroupPanel write SetShowGroupPanel default False;
    property OnGetGroupText: TPPGGridGroupTextEvent read FOnGetGroupText write FOnGetGroupText;
    property OnCustomAggregate: TPPGGridCustomAggregateEvent read FOnCustomAggregate
      write FOnCustomAggregate;
    property ConditionalFormats: TPPGGridConditionalFormats read FCondFormats
      write SetConditionalFormats;
    property OnGetCellStyle: TPPGGridCellStyleEvent read FOnGetCellStyle write FOnGetCellStyle;
    property OnLinkClick: TPPGGridLinkEvent read FOnLinkClick write FOnLinkClick;
    property OnCellButtonClick: TPPGGridCellEvent read FOnCellButtonClick write FOnCellButtonClick;
    /// Fokusspalte gewechselt bzw. wird verlassen (wie TDBGrid).
    property OnColEnter: TNotifyEvent read FOnColEnter write FOnColEnter;
    property OnColExit: TNotifyEvent read FOnColExit write FOnColExit;
    /// "..."-Knopf im Editor bzw. Strg+Enter (Spalte mit ShowsEllipsis, wie TDBGrid).
    property OnEditButtonClick: TNotifyEvent read FOnEditButtonClick write FOnEditButtonClick;
    /// Bereiche (Kopf, Auswahl, Zebra, Linien ...): nur gesetzte Werte zaehlen.
    property Styles: TPPGGridStyles read FStyles write SetStyles;
    /// Breite der Gitterlinien in logischen Pixeln (0 = keine Linien; wie TStringGrid).
    property GridLineWidth: Integer read FGridLineWidth write SetGridLineWidth default 1;
    /// Wie TStringGrid: gdsGradient = Kopf als Verlauf GradientStartColor ->
    /// GradientEndColor (nur hell); gdsClassic/gdsThemed = Kopf vom Preset.
    property DrawingStyle: TGridDrawingStyle read FDrawingStyle write SetDrawingStyle default gdsThemed;
    property GradientStartColor: TColor read FGradientStartColor write SetGradientStartColor default clWhite;
    property GradientEndColor: TColor read FGradientEndColor write SetGradientEndColor default clBtnFace;
    /// Wie TStringGrid.FixedColor (= Styles.Header.Color, nicht gespeichert);
    /// clBtnFace = Kopf vom Preset.
    property FixedColor: TColor read GetFixedColor write SetFixedColor stored False;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Sichtbare Zeile einer Datenzeile (-1 = herausgefiltert) und umgekehrt
    /// (-1 = feste Zeile/Filterzeile ohne Daten; -2 = Filterzeile).
    function VisualRow(ARow: Integer): Integer;
    function DataRow(VRow: Integer): Integer;
    /// Datenspalte einer Anzeige-Spalte (-1 = keine) und umgekehrt (-1 =
    /// ausgeblendet).
    function DataCol(VCol: Integer): Integer;
    function VisualCol(ACol: Integer): Integer;
    /// Spalte von Anzeige-Position FromIndex nach ToIndex verschieben (nur
    /// bewegliche Spalten, braucht Columns). Schreibt DisplayIndex neu.
    procedure MoveColumn(FromIndex, ToIndex: Integer);
    /// Breite der Datenspalte an den Inhalt anpassen (Kopf + Zeilen; bei mehr
    /// als 1000 Zeilen eine Stichprobe).
    procedure AutoSizeColumn(ACol: Integer);
    /// Kopfmenue einer Datenspalte (der Aufrufer gibt es frei).
    function CreateHeaderMenu(ACol: Integer): TPopupMenu; virtual;
    /// Reihenfolge, Breiten, Sichtbarkeit und Sortierung als Text (INI-Stil).
    function SaveLayout: string; virtual;
    procedure LoadLayout(const S: string); virtual;
    /// Nach Datenspalten gruppieren (Ebene 0 zuerst; braucht Columns).
    procedure GroupBy(const ACols: array of Integer);
    procedure Ungroup;
    /// Anzahl Gruppen (alle Ebenen) und Angaben zu einer Gruppe.
    function GroupCount: Integer;
    function GroupInfo(Group: Integer): TPPGGridGroupInfo;
    /// Gruppenspalten (Ebene 0 zuerst).
    function GroupColumns: TArray<Integer>;
    procedure ExpandGroup(Group: Integer; Expanded: Boolean);
    procedure FullExpand;
    procedure FullCollapse;
    /// Gruppe einer sichtbaren Zeile (-1 = keine Gruppenkopfzeile).
    function GroupOfRow(VRow: Integer): Integer;
    /// Sichtbare Zeile des Gruppenkopfs (-1 = in zugeklappter Gruppe).
    function GroupRow(Group: Integer): Integer;
    /// Text der Gruppenzeile (mit Markup) bzw. ohne Markup fuer Screenreader.
    function GroupText(Group: Integer): string;
    /// Datenzeilen einer Gruppe (-1 = alle Zeilen der Ansicht).
    function GroupDataRows(Group: Integer): TArray<Integer>;
    /// Summen neu berechnen (sonst verzoegert nach Datenaenderung).
    procedure RecalcAggregates;
    /// Text der Summenzeile bzw. des Gruppenfusses fuer eine Datenspalte.
    function FooterText(ACol: Integer): string;
    function GroupFooterText(Group, ACol: Integer): string;
    /// Zellen verbinden (Datenspalte/-zeile der Ursprungszelle). Ueberlappung
    /// mit einer vorhandenen Verbindung ist ein Fehler.
    procedure MergeCells(ACol, ARow, AColSpan, ARowSpan: Integer);
    procedure UnmergeCells(ACol, ARow: Integer);
    procedure ClearMerges;
    function MergeCount: Integer;
    function MergeInfo(Index: Integer): TPPGGridMerge;
    /// Zelle (Anzeige-Spalte, sichtbare Zeile) in Client-Koordinaten.
    function CellRect(ACol, VRow: Integer): TRect;
    /// Zelle unter dem Punkt; False = keine.
    function MouseCoord(X, Y: Integer; out ACol, VRow: Integer): Boolean;
    procedure MakeCellVisible(ACol, VRow: Integer);
    /// Sortiert nach Spalte (-1 = urspruengliche Reihenfolge).
    procedure SortBy(ACol: Integer; Ascending: Boolean = True);
    procedure ClearFilters;
    procedure ShowEditor;
    procedure HideEditor(Accept: Boolean = True);
    procedure CopyToClipboard;
    procedure PasteFromClipboard;
    /// Leert die editierbaren Zellen der Auswahl (Entf), je Zelle ueber
    /// SetCellByUser wie beim Einfuegen. Audit 7c #5.
    procedure ClearSelection;
    /// Kopiert die Auswahl und leert danach ihre editierbaren Zellen.
    procedure CutToClipboard;
    /// Auswahl als TSV (Tab/CRLF) bzw. Text einfuegen ab der Fokuszelle.
    function SelectionAsText: string;
    procedure PasteText(const S: string);
    /// Alle sichtbaren Zeilen (inkl. feste) und Spalten (Anzeige-Reihenfolge) als CSV.
    function ToCSV(Separator: Char = ';'): string;
    procedure SaveToCSV(const FileName: string; Separator: Char = ';');
    procedure SelectAll;
    property Cells[ACol, ARow: Integer]: string read GetCells write SetCells;
    property ColWidths[Index: Integer]: Integer read GetColWidths write SetColWidths;
    property RowHeights[Index: Integer]: Integer read GetRowHeights write SetRowHeights;
    property Filters[ACol: Integer]: string read GetFilter write SetFilter;
    /// Datenspalte der Fokuszelle.
    property Col: Integer read GetCol write SetCol;
    /// Datenzeile der Fokuszelle.
    property Row: Integer read GetRow write SetRow;
    /// Sichtbare Zeile der Fokuszelle.
    property FocusRow: Integer read FFocusV;
    /// Anzeige-Spalte der Fokuszelle.
    property FocusCol: Integer read FFocusC;
    /// Anzahl angezeigter Spalten (ohne ausgeblendete).
    property VisibleColCount: Integer read VColCount;
    property Selection: TGridRect read GetSelection write SetSelection;
    property SortColumn: Integer read FSortCol;
    property SortAscending: Boolean read FSortAscending;
    property EditorMode: Boolean read GetEditorMode write SetEditorMode;
    property InplaceEditor: TPPGCustomControl read FEditor;
    property Canvas: TCanvas read GetCanvas;
  end;

  TPPGGrid = class(TPPGCustomGrid)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Images;
    property Bands;
    property Columns;
    property ShowFilterRow;
    property FixedColsRight;
    property HeaderMenu;
    property ShowFooter;
    property GroupFooter;
    property ShowGroupPanel;
    property ConditionalFormats;
    property SortOnHeaderClick;
    property ScrollBarMode;
    property ScrollBars;
    property SmoothScrolling;
    property HighContrastSupport;
    property Styles;
    property GridLineWidth;
    { wie TStringGrid }
    property DrawingStyle;
    property FixedColor;
    property GradientEndColor;
    property GradientStartColor;
    property Align;
    property Anchors;
    property BiDiMode;
    property BorderStyle;
    property Color default clWindow;
    property ColCount;
    property Constraints;
    property DefaultColWidth;
    property DefaultDrawing;
    property DefaultRowHeight;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property FixedCols;
    // Streaming-Reihenfolge: RowCount vor FixedRows (wie ColCount vor FixedCols)
    property RowCount;
    property FixedRows;
    property Font;
    property Options;
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
    property OnClick;
    property OnCompareCells;
    property OnCellButtonClick;
    property OnColumnMoved;
    property OnCustomAggregate;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDrawCell;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnFixedCellClick;
    property OnGetCellText;
    property OnGetEditText;
    property OnGetGroupText;
    property OnGetCellStyle;
    property OnHeaderMenu;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnLinkClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnScroll;
    property OnSelectCell;
    property OnSetEditText;
    property OnSorted;
    property OnStartDock;
    property OnStartDrag;
    property OnTopLeftChange;
    property OnValidateCell;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseWheel;
    property OnMouseActivate;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

implementation

uses
  PPG.Lang,
  System.SysUtils, System.Generics.Collections, Winapi.oleacc, Vcl.Clipbrd, PPG.UIA.Intf,
  PPG.Consts, PPG.Exceptions, PPG.Appearance, PPG.Tokens, PPG.DpiUtils, PPG.VclStyles,
  PPG.Render.Registry, PPG.Render.Gdi, PPG.Menus, PPG.Render.Shapes, System.UITypes,
  PPG.Controls.Field;

type
  /// OnChange der Feld-Editoren (geschuetzt in der Feld-Basis).
  TGridEditorFieldAccess = class(TPPGCustomField);

const
  CellPadX = 6;      // logische px Text-Abstand links/rechts
  SizeZone = 4;      // logische px Greifzone fuer die Spaltenbreite
  MinColWidth = 8;   // logische px
  FilterRowMark = -2;
  GroupRowMark = -3;     // Gruppenkopf (DataRow)
  GroupFooterMark = -4;  // Gruppenfuss (DataRow)

type
  TCtrlAccess = class(TPPGCustomControl);

var
  GMsgRowAction: Cardinal = 0;
  GMsgAggregate: Cardinal = 0;

function EnsureRangeInt(V, Lo, Hi: Integer): Integer;
begin
  Result := V;
  if Result > Hi then
    Result := Hi;
  if Result < Lo then
    Result := Lo;
end;

{ TPPGCustomGrid }

constructor TPPGCustomGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 320;
  Height := 160;
  ParentColor := False;
  Color := clWindow;
  ControlStyle := ControlStyle - [csClickEvents];
  FDefaultColWidth := 64;
  FDefaultRowHeight := 24;
  FFixedCols := 1;
  FFixedRows := 1;
  FOptions := [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect];
  FDefaultDrawing := True;
  FToolTips := True;
  FBorderStyle := bsSingle;
  FView := TPPGGridView.Create;
  FStore := TPPGCellStore.Create;
  FPainter := TPPGCellPainter.Create;
  FGroupMarkup := TPPGMarkupLayout.Create;
  FCondFormats := TPPGGridConditionalFormats.Create(Self, TPPGGridConditionalFormat);
  FStyles := TPPGGridStyles.Create(Self);
  FStyles.OnChange := StylesObjChanged;
  FFontCache := TPPGFontCache.Create;
  FHotV := -1;
  FGridLineWidth := 1;
  FDrawingStyle := gdsThemed;
  FGradientStartColor := clWhite;
  FGradientEndColor := clBtnFace;
  FSortCol := -1;
  FSortAscending := True;
  FSortOnHeaderClick := True;
  FSizingCol := -1;
  FHeaderDown := -1;
  FLoadFixedRows := -1;
  FEditC := -1;
  FEditV := -1;
  FLastFocusRow := -1;
  FLayout := TPPGRowLayout.Create;
  FRowHeightStore := TPPGRowLayout.Create;
  FColumns := CreateColumns;
  FBands := TPPGGridBands.Create(Self, TPPGGridBand);
  FHeaderMenu := True;
  FColDropAt := -1;
  FItemCanvas := TCanvas.Create;
  FColCount := 0;
  FRowCount := 0;
  SetColCount(5);
  SetRowCount(5);
  FFocusC := 1;
  FFocusV := 1;
  FAnchorC := 1;
  FAnchorV := 1;
  if GMsgRowAction = 0 then
    GMsgRowAction := RegisterWindowMessage('PPGlow.GridRowAction');
  if GMsgAggregate = 0 then
    GMsgAggregate := RegisterWindowMessage('PPGlow.GridAggregate');
end;

destructor TPPGCustomGrid.Destroy;
begin
  FEditor := nil; // gehoert dem Grid (Owner), wird mit ihm freigegeben
  FreeAndNil(FItemCanvas);
  FreeAndNil(FColumns);
  FreeAndNil(FBands);
  FreeAndNil(FLayout);
  FreeAndNil(FRowHeightStore);
  FreeAndNil(FView);
  FreeAndNil(FStore);
  FreeAndNil(FPainter);
  FreeAndNil(FGroupMarkup);
  FreeAndNil(FCondFormats);
  FreeAndNil(FFontCache);
  FreeAndNil(FStyles);
  inherited Destroy;
end;

procedure TPPGCustomGrid.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or WS_CLIPCHILDREN; // Editor nie uebermalen
end;

procedure TPPGCustomGrid.CreateWnd;
begin
  inherited CreateWnd;
  // Summen/Statistiken, die vor dem Fenster geaendert wurden, jetzt nachholen
  // (eine fuer ein frueheres Fenster gepostete Nachricht ging verloren)
  FAggPosted := False;
  if (FAggDirty or (FAggPendCount > 0)) and (GMsgAggregate <> 0) then
  begin
    FAggPosted := True;
    PostMessage(Handle, GMsgAggregate, 0, 0);
  end;
end;

procedure TPPGCustomGrid.Loaded;
begin
  if FLoadFixedRows >= 0 then
  begin
    // noch im Ladezustand: klemmt mit Warnung statt zu werfen
    FFixedRows := PPGCheckRange(Self, 'FixedRows', FLoadFixedRows, 0, FRowCount - 1);
    FLoadFixedRows := -1;
  end;
  inherited Loaded;
  ColumnsChanged;
  RebuildColumnMap;
  RebuildMap;
  InvalidateGeometry;
end;

function TPPGCustomGrid.CreateColumns: TPPGGridColumns;
begin
  Result := TPPGGridColumns.Create(Self, TPPGGridColumn);
end;

procedure TPPGCustomGrid.ColumnsChanged;
var
  G: TArray<Integer>;
  I: Integer;
  Same: Boolean;
begin
  // Spaltenstile koennen eigene Schriften haben
  FontsChanged;
  // Spalten bestimmen die Spaltenzahl
  if (FColumns.Count > 0) and (FColCount <> FColumns.Count) then
    ColCount := FColumns.Count
  else
  begin
    RebuildColumnMap;
    // Spalten aendern nur die Spaltengeometrie (Audit 8c #2)
    InvalidateColGeometry;
    Invalidate;
  end;
  if csLoading in ComponentState then
    Exit;
  // GroupIndex geaendert: neu gruppieren; sonst Summen nur bei geaenderten
  // Aggregaten (Breite, Titel, Stil ... rechnen nicht neu, Audit 8c #2)
  if CanGroup then
    G := CurrentGroupColumns
  else
    G := nil;
  Same := Length(G) = Length(FGroupCols);
  if Same then
    for I := 0 to High(G) do
      if G[I] <> FGroupCols[I] then
        Same := False;
  if not Same then
    RebuildMap
  else if AggSignature <> FAggSig then
    AggregatesChanged;
end;

function TPPGCustomGrid.AggSignature: string;
var
  I: Integer;
  C: TPPGGridColumn;
begin
  SetLength(Result, FColCount);
  for I := 0 to FColCount - 1 do
  begin
    C := ColumnOf(I);
    if C = nil then
      Result[I + 1] := '-'
    else
      Result[I + 1] := Chr(Ord('A') + Ord(C.Aggregate));
  end;
end;

function TPPGCustomGrid.RowScrollY: Integer;
begin
  Result := ScrollY;
end;

function TPPGCustomGrid.RowsContentHeight: Integer;
begin
  if FLayout.TotalHeight64 > MaxInt then
    Result := MaxInt
  else
    Result := FLayout.TotalHeight;
end;

procedure TPPGCustomGrid.ScrollCellsTo(X, Y: Integer);
begin
  ScrollTo(X, Y);
end;

{ ---- Streaming (wie TCustomGrid) ---- }

procedure TPPGCustomGrid.DefineProperties(Filer: TFiler);

  function HasColWidths: Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := 0 to High(FColWidths) do
      if FColWidths[I] > 0 then
        Exit(True);
  end;

begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('ColWidths', ReadColWidths, WriteColWidths, HasColWidths);
  Filer.DefineProperty('RowHeights', ReadRowHeights, WriteRowHeights, FHasRowHeights);
end;

procedure TPPGCustomGrid.ReadColWidths(Reader: TReader);
var
  I: Integer;
begin
  Reader.ReadListBegin;
  I := 0;
  while not Reader.EndOfList do
  begin
    if I >= Length(FColWidths) then
      SetLength(FColWidths, I + 1);
    FColWidths[I] := Reader.ReadInteger;
    Inc(I);
  end;
  Reader.ReadListEnd;
end;

procedure TPPGCustomGrid.WriteColWidths(Writer: TWriter);
var
  I: Integer;
begin
  Writer.WriteListBegin;
  for I := 0 to FColCount - 1 do
    Writer.WriteInteger(GetColWidths(I));
  Writer.WriteListEnd;
end;

procedure TPPGCustomGrid.ReadRowHeights(Reader: TReader);
var
  I, V: Integer;
begin
  Reader.ReadListBegin;
  I := 0;
  while not Reader.EndOfList do
  begin
    V := Reader.ReadInteger;
    // Standardhoehe = keine eigene Hoehe (folgt spaeter DefaultRowHeight)
    if V <> FDefaultRowHeight then
    begin
      FHasRowHeights := True;
      if (V > 0) and (I < FRowHeightStore.Count) then
        FRowHeightStore.SetRowHeight(I, V);
    end;
    Inc(I);
  end;
  Reader.ReadListEnd;
end;

procedure TPPGCustomGrid.WriteRowHeights(Writer: TWriter);
var
  I: Integer;
begin
  Writer.WriteListBegin;
  for I := 0 to FRowCount - 1 do
    Writer.WriteInteger(GetRowHeights(I));
  Writer.WriteListEnd;
end;

{ ---- Dimensionen ---- }

procedure TPPGCustomGrid.SetColCount(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'ColCount', Value, 1, 100000);
  if V = FColCount then
    Exit;
  HideEditor(False);
  FColCount := V;
  Inc(FDataVersion);
  SetLength(FColWidths, V);
  SetLength(FFilters, V);
  FStore.SetColCount(V);
  if FFixedCols >= V then
    FFixedCols := V - 1;
  if FSortCol >= V then
    FSortCol := -1;
  RebuildColumnMap;
  RebuildMap;
end;

procedure TPPGCustomGrid.SetRowCount(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'RowCount', Value, 1, MaxInt div 2);
  if V = FRowCount then
    Exit;
  HideEditor(False);
  FRowCount := V;
  Inc(FDataVersion);
  FStore.TruncateRows(V);
  FRowHeightStore.Count := V; // Hoehen dahinter verfallen
  if FFixedRows >= V then
    FFixedRows := V - 1;
  RebuildMap;
end;

procedure TPPGCustomGrid.SetFixedCols(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'FixedCols', Value, 0, FColCount - 1);
  if V <> FFixedCols then
  begin
    HideEditor(False);
    FFixedCols := V;
    RebuildColumnMap;
    InvalidateGeometry;
  end;
end;

procedure TPPGCustomGrid.SetFixedRows(const Value: Integer);
var
  V: Integer;
begin
  // Aeltere DFMs streamen FixedRows vor RowCount: Wert merken und in
  // Loaded gegen die dann bekannte Zeilenzahl pruefen
  if (csLoading in ComponentState) and (Value >= FRowCount) then
  begin
    FLoadFixedRows := Value;
    V := FRowCount - 1;
  end
  else
    V := PPGCheckRange(Self, 'FixedRows', Value, 0, FRowCount - 1);
  if V <> FFixedRows then
  begin
    HideEditor(False);
    FFixedRows := V;
    RebuildMap;
  end;
end;

procedure TPPGCustomGrid.SetDefaultColWidth(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'DefaultColWidth', Value, 1, 10000);
  if V <> FDefaultColWidth then
  begin
    FDefaultColWidth := V;
    InvalidateGeometry;
  end;
end;

procedure TPPGCustomGrid.SetDefaultRowHeight(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'DefaultRowHeight', Value, 1, 10000);
  if V <> FDefaultRowHeight then
  begin
    FDefaultRowHeight := V;
    InvalidateGeometry;
  end;
end;

procedure TPPGCustomGrid.SetOptions(const Value: TGridOptions);
begin
  if FOptions <> Value then
  begin
    FOptions := Value;
    if not (goEditing in FOptions) then
      HideEditor(True);
    Invalidate;
  end;
end;

procedure TPPGCustomGrid.SetColumns(const Value: TPPGGridColumns);
begin
  FColumns.Assign(Value);
end;

procedure TPPGCustomGrid.SetBands(const Value: TPPGGridBands);
begin
  FBands.Assign(Value);
end;

procedure TPPGCustomGrid.SetFixedColsRight(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'FixedColsRight', Value, 0, 100);
  if V <> FFixedColsRight then
  begin
    HideEditor(True);
    FFixedColsRight := V;
    InvalidateGeometry;
  end;
end;

procedure TPPGCustomGrid.SetShowFilterRow(const Value: Boolean);
begin
  if FShowFilterRow <> Value then
  begin
    HideEditor(False);
    FShowFilterRow := Value;
    if not Value then
      ClearFilters
    else
      RebuildMap;
  end;
end;

function TPPGCustomGrid.GetColWidths(Index: Integer): Integer;
var
  C: TPPGGridColumn;
begin
  if (Index < 0) or (Index >= FColCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, FColCount - 1]);
  C := ColumnOf(Index);
  if (C <> nil) and (C.Width > 0) then
    Result := C.Width
  else if FColWidths[Index] > 0 then
    Result := FColWidths[Index]
  else
    Result := FDefaultColWidth;
end;

procedure TPPGCustomGrid.SetColWidths(Index: Integer; const Value: Integer);
var
  C: TPPGGridColumn;
  V: Integer;
begin
  if (Index < 0) or (Index >= FColCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, FColCount - 1]);
  V := PPGCheckRange(Self, 'ColWidths', Value, 0, 10000);
  C := ColumnOf(Index);
  // Mit Spalte meldet die Spalte selbst (ColumnsChanged); kein zweites
  // InvalidateGeometry (Audit 8c #2)
  if C <> nil then
    C.Width := V
  else if FColWidths[Index] <> V then
  begin
    FColWidths[Index] := V;
    InvalidateColGeometry;
  end;
end;

function TPPGCustomGrid.GetRowHeights(Index: Integer): Integer;
begin
  if (Index < 0) or (Index >= FRowCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, FRowCount - 1]);
  Result := FRowHeightStore.OwnHeight(Index);
  if Result <= 0 then
    Result := FDefaultRowHeight;
end;

procedure TPPGCustomGrid.SetRowHeights(Index: Integer; const Value: Integer);
var
  V: Integer;
begin
  if (Index < 0) or (Index >= FRowCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, FRowCount - 1]);
  V := PPGCheckRange(Self, 'RowHeights', Value, 0, 10000);
  if (V > 0) and (V <> FDefaultRowHeight) then
    FHasRowHeights := True;
  if FRowHeightStore.OwnHeight(Index) = V then
    Exit;
  FRowHeightStore.SetRowHeight(Index, V);
  // Nur die Zeilen neu (Audit 8c #5)
  FRowGeomValid := False;
  Invalidate;
  if HandleAllocated and not (csLoading in ComponentState) then
    EnsureGeometry;
end;

{ ---- Zellen ---- }

procedure TPPGCustomGrid.CheckCell(ACol, ARow: Integer);
begin
  if (ACol < 0) or (ACol >= FColCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [ACol, FColCount - 1]);
  if (ARow < 0) or (ARow >= FRowCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [ARow, FRowCount - 1]);
end;

function TPPGCustomGrid.GetCells(ACol, ARow: Integer): string;
begin
  CheckCell(ACol, ARow);
  Result := FStore.Get(ACol, ARow);
end;

procedure TPPGCustomGrid.SetCells(ACol, ARow: Integer; const Value: string);
var
  Old: string;
  HaveOld: Boolean;
begin
  CheckCell(ACol, ARow);
  // Alten Text nur, wenn er fuer eine inkrementelle Summe gebraucht wird
  HaveOld := not FAggDirty and StatsNeeded;
  if HaveOld then
    Old := FStore.Get(ACol, ARow);
  if FStore.Put(ACol, ARow, Value) then
  begin
    Invalidate;
    CellDataChanged(ACol, ARow, Old, Value, HaveOld);
  end;
end;

function TPPGCustomGrid.ColumnOf(ACol: Integer): TPPGGridColumn;
begin
  if (ACol >= 0) and (ACol < FColumns.Count) then
    Result := FColumns[ACol]
  else
    Result := nil;
end;

function TPPGCustomGrid.GetCellText(ACol, ARow: Integer): string;
var
  C: TPPGGridColumn;
begin
  Result := FStore.Get(ACol, ARow);
  if Assigned(FOnGetCellText) then
    FOnGetCellText(Self, ACol, ARow, Result);
  // Kopfzeile: Spaltentitel, solange die Zelle selbst leer ist
  if (Result = '') and (ARow = 0) and (FFixedRows > 0) then
  begin
    C := ColumnOf(ACol);
    if C <> nil then
      Result := C.Title;
  end;
end;

function TPPGCustomGrid.GetEditText(ACol, ARow: Integer): string;
begin
  Result := GetCellText(ACol, ARow);
  if Assigned(FOnGetEditText) then
    FOnGetEditText(Self, ACol, ARow, Result);
end;

procedure TPPGCustomGrid.SetCellByUser(ACol, ARow: Integer; const Value: string);
var
  Old: string;
  HaveOld: Boolean;
begin
  HaveOld := not FAggDirty and StatsNeeded;
  if HaveOld then
    Old := FStore.Get(ACol, ARow);
  FStore.Put(ACol, ARow, Value);
  // Summen vormerken, bevor das Ereignis weitere Zellen aendern kann
  CellDataChanged(ACol, ARow, Old, Value, HaveOld);
  if Assigned(FOnSetEditText) then
    FOnSetEditText(Self, ACol, ARow, Value);
  Invalidate;
end;

function TPPGCustomGrid.GetFilter(ACol: Integer): string;
begin
  if (ACol < 0) or (ACol >= Length(FFilters)) then
    Result := ''
  else
    Result := FFilters[ACol];
end;

procedure TPPGCustomGrid.SetFilter(ACol: Integer; const Value: string);
begin
  if (ACol < 0) or (ACol >= FColCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [ACol, FColCount - 1]);
  if FFilters[ACol] <> Value then
  begin
    FFilters[ACol] := Value;
    RebuildMap;
  end;
end;

procedure TPPGCustomGrid.ClearFilters;
var
  I: Integer;
begin
  for I := 0 to High(FFilters) do
    FFilters[I] := '';
  RebuildMap;
end;

{ ---- Zeilen-Abbildung ---- }

function TPPGCustomGrid.VFixedRows: Integer;
begin
  Result := FFixedRows + Ord(FShowFilterRow);
end;

function TPPGCustomGrid.VRowCount: Integer;
begin
  Result := VFixedRows + FView.Count;
end;

function TPPGCustomGrid.DataRow(VRow: Integer): Integer;
begin
  if VRow < FFixedRows then
    Result := VRow
  else if FShowFilterRow and (VRow = FFixedRows) then
    Result := FilterRowMark
  else
  begin
    Result := FView.DataRowOf(VRow - VFixedRows);
    // Gruppenzeilen haben keine Datenzeile
    if Result <= -2 then
    begin
      if PPGGridEntryIsFooter(Result) then
        Result := GroupFooterMark
      else
        Result := GroupRowMark;
    end;
  end;
end;

function TPPGCustomGrid.VisualRow(ARow: Integer): Integer;
begin
  if (ARow < 0) or (ARow >= FRowCount) then
    Result := -1
  else if ARow < FFixedRows then
    Result := ARow
  else
  begin
    Result := FView.ViewIndexOf(ARow);
    if Result >= 0 then
      Inc(Result, VFixedRows);
  end;
end;

procedure TPPGCustomGrid.PrepareFilters;
var
  C: Integer;
begin
  SetLength(FFilterUpper, Length(FFilters));
  for C := 0 to High(FFilters) do
    FFilterUpper[C] := AnsiUpperCase(FFilters[C]);
end;

function TPPGCustomGrid.RowPassesFilter(ARow: Integer): Boolean;
var
  C: Integer;
begin
  // Filtertexte stehen schon in Grossbuchstaben (PrepareFilters, einmal je Lauf)
  if Length(FFilterUpper) <> Length(FFilters) then
    PrepareFilters;
  Inc(FFilterEvalCount);
  Result := True;
  for C := 0 to High(FFilters) do
    if (FFilters[C] <> '') and
      (Pos(FFilterUpper[C], AnsiUpperCase(GetCellText(C, ARow))) = 0) then
      Exit(False);
end;

function TPPGCustomGrid.CompareDataRows(ACol, R1, R2: Integer): Integer;
var
  S1, S2: string;
  F1, F2: Double;
begin
  if Assigned(FOnCompareCells) then
  begin
    Result := 0;
    FOnCompareCells(Self, ACol, R1, R2, Result);
    Exit;
  end;
  S1 := GetCellText(ACol, R1);
  S2 := GetCellText(ACol, R2);
  // Zahlen als Zahlen vergleichen (2 vor 10)
  if TryStrToFloat(S1, F1) and TryStrToFloat(S2, F2) then
  begin
    if F1 < F2 then
      Result := -1
    else if F1 > F2 then
      Result := 1
    else
      Result := 0;
  end
  else
    Result := AnsiCompareText(S1, S2);
end;

procedure TPPGCustomGrid.RebuildMap;
var
  Filtered: Boolean;
  I, FocusData: Integer;
begin
  if FLayout = nil then
    Exit;
  EndEditorForRebuild;
  FocusData := DataRow(FFocusV);
  PrepareFilters;
  Filtered := False;
  for I := 0 to High(FFilters) do
    if FFilters[I] <> '' then
      Filtered := True;
  FView.Filter.Active := Filtered;
  FView.Sort.Column := FSortCol;
  FView.Sort.Ascending := FSortAscending;
  if CanGroup then
    FGroupCols := CurrentGroupColumns
  else
    FGroupCols := nil;
  FView.Group.Columns := FGroupCols;
  FView.Group.SortColumn := FSortCol;
  FView.Group.SortAscending := FSortAscending;
  FView.Group.Footers := FGroupFooter;
  FView.Rebuild(Self, FFixedRows, FRowCount);
  // Summen gehoeren zur Ansicht: gleich mit neu (nicht beim Zeichnen).
  // Reines Umsortieren ohne Gruppen aendert die Zeilenmenge nicht: die
  // Summen (und Statistiken) bleiben (Audit 8c #7)
  if FAggDirty or (FAggViewKey = '') or (AggViewKey <> FAggViewKey) or
    (AggSignature <> FAggSig) then
    RecalcAggregates;
  // Fokus bleibt an der Datenzeile (sonst erste sichtbare Datenzeile)
  if FocusData >= 0 then
    I := VisualRow(FocusData)
  else
    I := FFocusV;
  if (I < 0) or (I >= VRowCount) then
    I := VFixedRows;
  if I >= VRowCount then
    I := VRowCount - 1;
  if I < 0 then
    I := 0;
  FFocusV := I;
  FAnchorV := I;
  InvalidateGeometry;
end;

function TPPGCustomGrid.ViewRowPasses(ARow: Integer): Boolean;
begin
  Result := RowPassesFilter(ARow);
end;

function TPPGCustomGrid.ViewCompareRows(ACol, R1, R2: Integer): Integer;
begin
  Result := CompareDataRows(ACol, R1, R2);
end;

function TPPGCustomGrid.ViewFilterKey: string;
var
  M: function(ARow: Integer): Boolean of object;
  I: Integer;
begin
  Result := '';
  // Virtuelle Texte koennen sich unbemerkt aendern; eigener Filter: unbekannt
  M := RowPassesFilter;
  if not PlainCellText or (TMethod(M).Code <> @TPPGCustomGrid.RowPassesFilter) then
    Exit;
  Result := IntToStr(FDataVersion) + '|' + IntToStr(FFixedRows) + '|' + IntToStr(FRowCount);
  for I := 0 to High(FFilters) do
    Result := Result + #1 + FFilters[I];
end;

function TPPGCustomGrid.AggViewKey: string;
begin
  Result := '';
  if not CanGroup or FView.Grouped or (Length(FGroupCols) > 0) or not PlainCellText then
    Exit;
  if FView.Filter.Active then
  begin
    Result := ViewFilterKey;
    if Result <> '' then
      Result := 'F' + Result;
  end
  else
    Result := 'A|' + IntToStr(FFixedRows) + '|' + IntToStr(FRowCount);
end;

function TPPGCustomGrid.StandardCompare: Boolean;
var
  M: function(ACol, R1, R2: Integer): Integer of object;
begin
  M := CompareDataRows;
  Result := not Assigned(FOnCompareCells) and
    (TMethod(M).Code = @TPPGCustomGrid.CompareDataRows);
end;

function TPPGCustomGrid.ViewSortKeys(ACol: Integer; const Rows: TArray<Integer>;
  out Keys: TArray<TPPGGridSortKey>): Boolean;
var
  I: Integer;
begin
  // Gleiche Logik wie CompareDataRows, nur einmal je Zeile: Text lesen
  // (Cells bzw. OnGetCellText) und Zahl erkennen
  Result := StandardCompare;
  if not Result then
    Exit;
  SetLength(Keys, Length(Rows));
  for I := 0 to High(Rows) do
  begin
    Keys[I].Text := GetCellText(ACol, Rows[I]);
    Keys[I].IsNum := TryStrToFloat(Keys[I].Text, Keys[I].Num);
  end;
end;

{ ---- IPPGTableSource: Ansicht ohne feste Zeilen, alle Spalten ---- }

function TPPGCustomGrid.TableColCount: Integer;
begin
  // Was der Anwender sieht: angezeigte Spalten in Anzeige-Reihenfolge
  Result := VColCount;
end;

function TPPGCustomGrid.TableRowCount: Integer;
begin
  // Nur Datenzeilen (ohne Gruppenzeilen, auch zugeklappte)
  Result := FView.AllRowCount;
end;

function TPPGCustomGrid.TableColumn(ACol: Integer): TPPGTableColumnInfo;
var
  C: TPPGGridColumn;
begin
  ACol := DataCol(ACol);
  C := ColumnOf(ACol);
  if FFixedRows > 0 then
    Result.Title := GetCellText(ACol, 0)
  else if C <> nil then
    Result.Title := C.Title
  else
    Result.Title := '';
  Result.Width := GetColWidths(ACol);
  if C <> nil then
    Result.Alignment := C.Alignment
  else
    Result.Alignment := taLeftJustify;
  if C <> nil then
    Result.Format := C.Format
  else
    Result.Format := '';
end;

function TPPGCustomGrid.TableCellText(ACol, ARow: Integer): string;
begin
  Result := GetCellText(DataCol(ACol), FView.AllRow(ARow));
end;

function TPPGCustomGrid.TableCellValue(ACol, ARow: Integer): Variant;
begin
  Result := PPGTableValueOf(TableCellText(ACol, ARow));
end;

function TPPGCustomGrid.PrintCellStyle(ACol, ARow: Integer; const Text: string): TPPGGridCellStyle;
var
  D: Integer;
begin
  // Wie im Grid, aber Fuellfarben fuer weisses Papier
  Result.Reset;
  D := FView.AllRow(ARow);
  ACol := DataCol(ACol);
  if FCondFormats.Count > 0 then
    FCondFormats.Apply(ACol, Text, Tokens, clWhite, Result);
  if Assigned(FOnGetCellStyle) then
    FOnGetCellStyle(Self, ACol, D, Result);
end;

function TPPGCustomGrid.PrintCellKind(ACol: Integer; out Ctx: TPPGCellKindContext): IPPGCellKind;
begin
  ACol := DataCol(ACol);
  Result := KindOf(ACol);
  Ctx := KindContext(ACol);
end;

function TPPGCustomGrid.PrintFont: TFont;
begin
  Result := Font;
end;

function TPPGCustomGrid.PrintRowHeight: Integer;
begin
  Result := FDefaultRowHeight;
end;

function TPPGCustomGrid.ExportAggregate(ACol: Integer): TPPGGridAggregate;
var
  C: TPPGGridColumn;
begin
  C := ColumnOf(DataCol(ACol));
  if C = nil then
    Result := agNone
  else
    Result := C.Aggregate;
end;

function TPPGCustomGrid.ExportMerges: TArray<TRect>;
var
  I, N, C0, R0, C1, R1: Integer;
begin
  SetLength(Result, 0);
  if not MergesActive then
    Exit;
  N := 0;
  for I := 0 to High(FMerges) do
    // Nur Datenzeilen (Kopfzeilen gehoeren nicht zur Tabelle)
    if VisualMerge(I, C0, R0, C1, R1) and (R0 >= VFixedRows) then
    begin
      SetLength(Result, N + 1);
      Result[N] := Rect(C0, R0 - VFixedRows, C1, R1 - VFixedRows);
      Inc(N);
    end;
end;

function TPPGCustomGrid.ExportOutline: TArray<TPPGOutlineRow>;
var
  N, G: Integer;

  procedure Add(ARow, ALevel: Integer; const AText: string);
  begin
    if N >= Length(Result) then
      SetLength(Result, N * 2 + 64);
    Result[N].Row := ARow;
    Result[N].Level := ALevel;
    Result[N].Text := AText;
    Inc(N);
  end;

  procedure Emit(AG: Integer);
  var
    C, J: Integer;
    Gr: TPPGGridGroup;
  begin
    Gr := FView.Group.Groups[AG];
    Add(-1, Gr.Level, PPGStripMarkup(GroupText(AG)));
    if Gr.FirstChild >= 0 then
    begin
      C := Gr.FirstChild;
      while C >= 0 do
      begin
        Emit(C);
        C := FView.Group.Groups[C].Next;
      end;
    end
    else
      // Tabellenzeile = Position in der Gruppenreihenfolge (TableCellText)
      for J := Gr.First to Gr.First + Gr.Count - 1 do
        Add(J, Gr.Level + 1, '');
  end;

begin
  SetLength(Result, 0);
  N := 0;
  if not FView.Grouped or (GroupCount = 0) then
    Exit;
  G := 0;
  while G >= 0 do
  begin
    Emit(G);
    G := FView.Group.Groups[G].Next;
  end;
  SetLength(Result, N);
end;

{ ---- IPPGTableLook: Optik fuer den xlsx-Export (helle Darstellung) ---- }

/// Schriftstil eines Element-Stils (eigene Schrift bzw. Base, plus FontStyle).
function ExportFontStyle(S: TPPGElementStyle; Base: TFont): TFontStyles;
begin
  if S.HasOwnFont then
    Result := S.Font.Style + S.FontStyle
  else
    Result := Base.Style + S.FontStyle;
end;

function ExportTokens(const Renderer: IPPGRenderer): TPPGTokens;
var
  TR: IPPGThemeRenderer;
begin
  if Supports(Renderer, IPPGThemeRenderer, TR) then
    Result := TR.Tokens(False)
  else
    Result := PPGDefaultTokens(False);
end;

function TPPGCustomGrid.TableDataCol(ACol: Integer): Integer;
begin
  Result := DataCol(ACol);
end;

function TPPGCustomGrid.TableStyleRow(ARow: Integer): Integer;
begin
  Result := FView.AllRow(ARow);
end;

function TPPGCustomGrid.ExportLook: TPPGTableLook;
var
  T: TPPGTokens;
  Fill, Text, Head: TColor;
begin
  // Wie GetGridColors ohne Dark Mode, VCL-Style und Hochkontrast: die Datei
  // soll auf weissem Papier bzw. in Excel hell aussehen
  Result.Reset;
  // Statistik der bedingten Formate (Oben-N, Farbskala) aktuell halten: der
  // Export kann vor dem ersten Zeichnen kommen
  if FAggDirty then
    RecalcAggregates;
  T := ExportTokens(Renderer);
  Fill := PPGColorToRGB(Color);
  Text := PPGColorToRGB(Font.Color);
  Head := PPGBlendColor(Fill, Text, 0.05);
  Result.Fill := Fill;
  Result.Text := Text;
  Result.HeaderFill := FStyles.Header.FillFor(False, Head);
  Result.HeaderText := FStyles.Header.TextFor(False, Text);
  Result.HeaderFontStyle := ExportFontStyle(FStyles.Header, Font);
  if (goVertLine in FOptions) or (goHorzLine in FOptions) then
    Result.Line := FStyles.GridLine.FillFor(False, PPGBlendColor(Fill, Text, 0.13))
  else
    Result.Line := clNone;
  Result.HeaderLine := FStyles.Header.BorderFor(False, PPGBlendColor(Fill, Text, 0.13));
  Result.GroupFill := FStyles.GroupRow.FillFor(False, PPGBlendColor(Fill, Head, 0.6));
  Result.GroupText := FStyles.GroupRow.TextFor(False, Text);
  Result.GroupFontStyle := ExportFontStyle(FStyles.GroupRow, Font);
  Result.FooterFill := FStyles.Footer.FillFor(False, Result.HeaderFill);
  Result.FooterText := FStyles.Footer.TextFor(False, Result.HeaderText);
  Result.FooterFontStyle := Result.HeaderFontStyle + FStyles.Footer.FontStyle;
  Result.Accent := T.Accent;
  Result.Warning := T.Warning;
  Result.Hint := PPGBlendColor(Text, Fill, 0.55);
  Result.FontName := Font.Name;
  Result.FontSize := Abs(Font.Size);
  if Result.FontSize = 0 then
    Result.FontSize := 9;
  Result.RowHeight := FDefaultRowHeight;
end;

function TPPGCustomGrid.ExportColumnLook(ACol: Integer): TPPGTableColumnLook;
var
  C: TPPGGridColumn;
  D, I: Integer;
  R: TPPGGridConditionalFormat;
begin
  Result.Reset;
  D := TableDataCol(ACol);
  C := ColumnOf(D);
  if C <> nil then
  begin
    if C.EditorKind = gekCheck then
      Result.Kind := ckCheck
    else
      Result.Kind := C.CellKind;
    Result.MinValue := C.MinValue;
    Result.MaxValue := C.MaxValue;
    Result.HeaderAlignment := C.EffectiveTitleAlignment;
    Result.FooterFormat := C.FooterFormat;
    Result.Header.Fill := C.TitleStyle.FillFor(False, clNone);
    Result.Header.TextColor := C.TitleStyle.TextFor(False, clNone);
    if C.TitleStyle.HasOwnFont then
      Result.Header.FontStyle := C.TitleStyle.Font.Style + C.TitleStyle.FontStyle
    else
      Result.Header.FontStyle := C.TitleStyle.FontStyle;
  end;
  // Datenbalken und Symbolsatz rechnet Excel selbst (gleiche Skala: Min..Max
  // der Spalte), damit sie nach dem Bearbeiten in Excel stimmen
  for I := 0 to FCondFormats.Count - 1 do
  begin
    R := FCondFormats[I];
    if not R.Enabled or (R.Column <> D) or (D < 0) then
      Continue;
    if (R.Rule = crDataBar) and not Result.DataBar then
    begin
      Result.DataBar := True;
      Result.DataBarColor := R.RuleColor(ExportTokens(Renderer));
    end
    else if R.Rule = crIconSet then
      Result.IconSet := True;
  end;
end;

function TPPGCustomGrid.ExportCellStyle(ACol, ARow: Integer; const Text: string;
  Alternate: Boolean): TPPGGridCellStyle;
var
  D: Integer;
  C: TPPGGridColumn;
  Fill, TextColor: TColor;
begin
  // Reihenfolge wie beim Zeichnen: Flaeche Zebra -> Spalte -> Zellstil,
  // Text Spalte -> Zebra -> Zellstil
  Result.Reset;
  D := TableDataCol(ACol);
  C := ColumnOf(D);
  Fill := clNone;
  TextColor := clNone;
  if C <> nil then
    TextColor := C.Style.TextFor(False, clNone);
  if Alternate and FStyles.AlternateRow.HasFill(False) then
  begin
    Fill := FStyles.AlternateRow.FillFor(False, clNone);
    TextColor := FStyles.AlternateRow.TextFor(False, TextColor);
    Result.FontStyle := Result.FontStyle + FStyles.AlternateRow.FontStyle;
  end;
  if C <> nil then
  begin
    Fill := C.Style.FillFor(False, Fill);
    if C.Style.HasOwnFont then
    begin
      Result.FontStyle := Result.FontStyle + C.Style.Font.Style;
      Result.FontName := C.Style.Font.Name;
      Result.FontSize := Abs(C.Style.Font.Size);
    end;
    Result.FontStyle := Result.FontStyle + C.Style.FontStyle;
  end;
  if FCondFormats.Count > 0 then
    FCondFormats.Apply(D, Text, ExportTokens(Renderer), PPGColorToRGB(Color), Result);
  if Assigned(FOnGetCellStyle) then
    FOnGetCellStyle(Self, D, TableStyleRow(ARow), Result);
  if Result.Fill = clNone then
    Result.Fill := Fill;
  if Result.TextColor = clNone then
    Result.TextColor := TextColor;
end;

function TPPGCustomGrid.ExportFooterText(ACol: Integer): string;
begin
  // Nur mit sichtbarer Summenzeile (wie am Bildschirm)
  if FShowFooter then
    Result := FooterText(TableDataCol(ACol))
  else
    Result := '';
end;

function TPPGCustomGrid.ExportBands: TArray<TPPGTableBand>;
var
  Levels, L, C, First, B, N, Cols: Integer;

  function BandOf(ACol, ALevel: Integer): Integer;
  var
    Col: TPPGGridColumn;
  begin
    Col := ColumnOf(TableDataCol(ACol));
    if Col = nil then
      Result := -1
    else
      Result := FBands.BandAtLevel(Col.Band, ALevel);
  end;

begin
  SetLength(Result, 0);
  Levels := FBands.LevelCount;
  if (FFixedRows = 0) or (Levels = 0) then
    Exit;
  Cols := TableColCount;
  N := 0;
  for L := 0 to Levels - 1 do
  begin
    // Laeufe gleicher Baender in Anzeige-Reihenfolge (wie PaintBands)
    C := 0;
    while C < Cols do
    begin
      B := BandOf(C, L);
      First := C;
      Inc(C);
      while (C < Cols) and (BandOf(C, L) = B) do
        Inc(C);
      if B < 0 then
        Continue;
      SetLength(Result, N + 1);
      Result[N].Caption := FBands[B].Caption;
      Result[N].Level := L;
      Result[N].ColFirst := First;
      Result[N].ColLast := C - 1;
      Result[N].Alignment := FBands[B].Alignment;
      Inc(N);
    end;
  end;
end;

procedure TPPGCustomGrid.SortBy(ACol: Integer; Ascending: Boolean);
begin
  HideEditor(True);
  if (ACol < -1) or (ACol >= FColCount) then
    ACol := -1;
  FSortCol := ACol;
  FSortAscending := Ascending;
  RebuildMap;
  if Assigned(FOnSorted) then
    FOnSorted(Self);
end;

{ ---- Spalten in der Anzeige (Phase 13b) ---- }

procedure TPPGCustomGrid.RebuildColumnMap;
var
  Order, Keys: array of Integer;
  I, J, K, N, T, FD, AD: Integer;
  C: TPPGGridColumn;
  Sorted: Boolean;
begin
  EndEditorForRebuild;
  // Fokus und Anker bleiben an ihrer Datenspalte
  FD := DataCol(FFocusC);
  AD := DataCol(FAnchorC);
  N := FColCount;
  SetLength(Order, N);
  SetLength(Keys, N);
  Sorted := True;
  for I := 0 to N - 1 do
  begin
    Order[I] := I;
    C := nil;
    if I >= FFixedCols then
      C := ColumnOf(I);
    if (C <> nil) and (C.DisplayIndex >= 0) then
      Keys[I] := C.DisplayIndex
    else
      Keys[I] := I - FFixedCols;
    if (I > FFixedCols) and (Keys[I] < Keys[I - 1]) then
      Sorted := False;
  end;
  // Bewegliche Spalten stabil nach DisplayIndex (feste bleiben vorn)
  if not Sorted then
    for I := FFixedCols + 1 to N - 1 do
    begin
      T := Order[I];
      J := I - 1;
      while (J >= FFixedCols) and (Keys[Order[J]] > Keys[T]) do
      begin
        Order[J + 1] := Order[J];
        Dec(J);
      end;
      Order[J + 1] := T;
    end;
  SetLength(FVisCols, N);
  K := 0;
  for I := 0 to N - 1 do
  begin
    C := nil;
    if Order[I] >= FFixedCols then
      C := ColumnOf(Order[I]);
    if (C = nil) or C.Visible then
    begin
      FVisCols[K] := Order[I];
      Inc(K);
    end;
  end;
  // Mindestens eine bewegliche Spalte bleibt sichtbar
  if (K <= FFixedCols) and (N > FFixedCols) then
  begin
    FVisCols[K] := Order[FFixedCols];
    Inc(K);
  end;
  SetLength(FVisCols, K);
  SetLength(FColVis, N);
  for I := 0 to N - 1 do
    FColVis[I] := -1;
  for I := 0 to K - 1 do
    FColVis[FVisCols[I]] := I;
  if K > FFixedCols then
  begin
    I := VisualCol(FD);
    if I < 0 then
      I := FFocusC;
    FFocusC := EnsureRangeInt(I, FFixedCols, K - 1);
    I := VisualCol(AD);
    if I < 0 then
      I := FFocusC;
    FAnchorC := EnsureRangeInt(I, FFixedCols, K - 1);
  end;
  FColGeomValid := False;
end;

function TPPGCustomGrid.VColCount: Integer;
begin
  Result := Length(FVisCols);
end;

function TPPGCustomGrid.DataCol(VCol: Integer): Integer;
begin
  if (VCol >= 0) and (VCol < Length(FVisCols)) then
    Result := FVisCols[VCol]
  else
    Result := -1;
end;

function TPPGCustomGrid.VisualCol(ACol: Integer): Integer;
begin
  if (ACol >= 0) and (ACol < Length(FColVis)) then
    Result := FColVis[ACol]
  else
    Result := -1;
end;

function TPPGCustomGrid.FirstRightCol: Integer;
var
  N: Integer;
begin
  N := FFixedColsRight;
  // Mindestens eine scrollbare Spalte bleibt
  if N > VColCount - FFixedCols - 1 then
    N := VColCount - FFixedCols - 1;
  if N < 0 then
    N := 0;
  Result := VColCount - N;
end;

function TPPGCustomGrid.FixedRightWidth: Integer;
begin
  EnsureGeometry;
  Result := FColX[VColCount] - FColX[FirstRightCol];
end;

function TPPGCustomGrid.BandHeight: Integer;
var
  L: Integer;
begin
  Result := 0;
  if (FFixedRows = 0) or (FBands.Count = 0) then
    Exit;
  L := FBands.LevelCount;
  Result := L * PPGScale(FDefaultRowHeight, ScalePPI);
end;

function TPPGCustomGrid.GridViewRect: TRect;
begin
  // Oben Gruppenleiste und Baender, unten die Summenzeile
  Result := ViewRect;
  Inc(Result.Top, GroupPanelHeight + BandHeight);
  Dec(Result.Bottom, FooterHeight);
  if Result.Top > Result.Bottom then
    Result.Top := Result.Bottom;
end;

function TPPGCustomGrid.MaxColScroll: Integer;
var
  V: TRect;
begin
  EnsureGeometry;
  V := GridViewRect;
  Result := FColX[VColCount] - (V.Right - V.Left);
  if Result < 0 then
    Result := 0;
end;

function TPPGCustomGrid.ColLeft(VCol: Integer): Integer;
begin
  // Feste links stehen, rechts fixierte stehen am rechten Rand (als waere
  // ganz nach rechts gescrollt), die uebrigen scrollen
  if VCol < FFixedCols then
    Result := FColX[VCol]
  else if FPaintCached then
  begin
    // Waehrend des Zeichnens einmal berechnet (Audit 8c #8)
    if VCol >= FPaintFirstRight then
      Result := FColX[VCol] - FPaintMaxColScroll
    else
      Result := FColX[VCol] - ScrollX;
  end
  else if VCol >= FirstRightCol then
    Result := FColX[VCol] - MaxColScroll
  else
    Result := FColX[VCol] - ScrollX;
end;

function TPPGCustomGrid.CanMoveColumn(VCol: Integer): Boolean;
begin
  Result := (VCol >= FFixedCols) and (VCol < FirstRightCol) and
    (ColumnOf(DataCol(VCol)) <> nil);
end;

function TPPGCustomGrid.ColumnDropAt(X: Integer): Integer;
var
  V: TRect;
  CX, I, L, W: Integer;
begin
  V := GridViewRect;
  if UseRightToLeftAlignment then
    X := V.Left + V.Right - X - 1;
  CX := X - V.Left;
  Result := FirstRightCol;
  for I := FFixedCols to FirstRightCol - 1 do
  begin
    L := ColLeft(I);
    W := FColX[I + 1] - FColX[I];
    if CX < L + W div 2 then
      Exit(I);
  end;
end;

procedure TPPGCustomGrid.MoveColumn(FromIndex, ToIndex: Integer);
var
  Order: array of Integer;
  I, J, N, D, DTo, P: Integer;
  C: TPPGGridColumn;
begin
  if (FromIndex = ToIndex) or not CanMoveColumn(FromIndex) or not CanMoveColumn(ToIndex) then
    Exit;
  HideEditor(True);
  D := DataCol(FromIndex);
  DTo := DataCol(ToIndex);
  // Vollstaendige Reihenfolge der beweglichen Spalten (auch ausgeblendete)
  N := 0;
  SetLength(Order, FColCount);
  for I := FFixedCols to FColCount - 1 do
  begin
    Order[N] := I;
    Inc(N);
  end;
  for I := 1 to N - 1 do
  begin
    P := Order[I];
    J := I - 1;
    while (J >= 0) and (ColumnSortKey(Order[J]) > ColumnSortKey(P)) do
    begin
      Order[J + 1] := Order[J];
      Dec(J);
    end;
    Order[J + 1] := P;
  end;
  // D herausnehmen und vor bzw. hinter DTo einsetzen
  P := -1;
  for I := 0 to N - 1 do
    if Order[I] = D then
      P := I;
  for I := P to N - 2 do
    Order[I] := Order[I + 1];
  for I := 0 to N - 2 do
    if Order[I] = DTo then
    begin
      if ToIndex > FromIndex then
        P := I + 1
      else
        P := I;
      Break;
    end;
  for I := N - 1 downto P + 1 do
    Order[I] := Order[I - 1];
  Order[P] := D;
  ColumnCollection.BeginUpdate;
  try
    for I := 0 to N - 1 do
    begin
      C := ColumnOf(Order[I]);
      if C <> nil then
        C.DisplayIndex := I;
    end;
  finally
    ColumnCollection.EndUpdate;
  end;
  RebuildColumnMap;
  InvalidateGeometry;
  if Assigned(FOnColumnMoved) then
    FOnColumnMoved(Self, FromIndex, ToIndex);
end;

function TPPGCustomGrid.ColumnSortKey(ACol: Integer): Integer;
var
  C: TPPGGridColumn;
begin
  C := ColumnOf(ACol);
  if (C <> nil) and (C.DisplayIndex >= 0) then
    Result := C.DisplayIndex
  else
    Result := ACol - FFixedCols;
end;

procedure TPPGCustomGrid.AutoSizeColumn(ACol: Integer);
const
  SampleMax = 1000; // nie alle Zeilen messen (1 000 000 Zeilen)
var
  DC: HDC;
  Old: HGDIOBJ;
  Sz: TSize;
  MaxW, HeadW, I, N, K, Cnt, D, PPI, W: Integer;

  function TextW(const T: string): Integer;
  begin
    Result := 0;
    if (T <> '') and GetTextExtentPoint32(DC, PChar(T), Length(T), Sz) then
      Result := Sz.cx;
  end;

begin
  if (ACol < 0) or (ACol >= FColCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [ACol, FColCount - 1]);
  HideEditor(True);
  PPI := ScalePPI;
  MaxW := 0;
  HeadW := 0;
  DC := GetDC(0);
  try
    Old := SelectObject(DC, Font.Handle);
    try
      for I := 0 to FFixedRows - 1 do
      begin
        W := TextW(GetCellText(ACol, I));
        if W > HeadW then
          HeadW := W;
      end;
      if HeadW > 0 then
        Inc(HeadW, PPGScale(TPPGCellPainter.SortArrowSpace, PPI));
      if (FFixedRows < FRowCount) and (CellEditorKind(ACol, FFixedRows) = gekCheck) then
        MaxW := PPGScale(16, PPI)
      else
      begin
        // Zeilen der Ansicht; bei vielen Zeilen gleichmaessig verteilte Stichprobe
        N := FView.Count;
        Cnt := N;
        if Cnt > SampleMax then
          Cnt := SampleMax;
        for K := 0 to Cnt - 1 do
        begin
          D := FView.DataRowOf(Integer(Int64(K) * N div Cnt));
          if D >= 0 then
          begin
            W := TextW(GetCellText(ACol, D));
            if W > MaxW then
              MaxW := W;
          end;
        end;
      end;
    finally
      SelectObject(DC, Old);
    end;
  finally
    ReleaseDC(0, DC);
  end;
  if HeadW > MaxW then
    MaxW := HeadW;
  Inc(MaxW, 2 * PPGScale(CellPadX, PPI) + 2);
  W := MulDiv(MaxW, 96, PPI); // logisch speichern
  if W < MinColWidth then
    W := MinColWidth;
  SetColWidths(ACol, W);
end;

function TPPGCustomGrid.ColumnKey(ACol: Integer): string;
begin
  Result := IntToStr(ACol);
end;

const
  HMSortAsc = 1;
  HMSortDesc = 2;
  HMSortNone = 3;
  HMHide = 4;
  HMBestFit = 5;
  HMBestFitAll = 6;
  HMShowAll = 7;
  HMGroupBy = 8;
  HMUngroup = 9;
  HMExpandAll = 10;
  HMCollapseAll = 11;
  HMColumnBase = 1000; // + Datenspalte (Spaltenauswahl)

function TPPGCustomGrid.CreateHeaderMenu(ACol: Integer): TPopupMenu;
var
  M: TPPGPopupMenu;
  Sub, It: TMenuItem;
  Col, C2: TPPGGridColumn;
  I, Shown: Integer;
  Sortable: Boolean;

  function Add(Parent: TMenuItem; const Caption: string; ATag: Integer): TMenuItem;
  begin
    Result := TMenuItem.Create(M);
    Result.Caption := Caption;
    Result.Tag := ATag;
    if ATag <> 0 then
      Result.OnClick := HeaderMenuClick;
    Parent.Add(Result);
  end;

  function ColCaption(D: Integer): string;
  var
    C: TPPGGridColumn;
  begin
    Result := '';
    if FFixedRows > 0 then
      Result := GetCellText(D, 0);
    C := ColumnOf(D);
    if (Result = '') and (C <> nil) then
      Result := C.Title;
    if Result = '' then
      Result := IntToStr(D);
    Result := StringReplace(Result, '&', '&&', [rfReplaceAll]);
  end;

begin
  M := TPPGPopupMenu.Create(Self);
  M.Tag := ACol;
  Col := ColumnOf(ACol);
  Sortable := (ACol >= FFixedCols) and ((Col = nil) or Col.Sortable);
  if not CanGroup then
    Sortable := False; // DB-Grid: Sortieren ist Sache der Datenmenge
  It := Add(M.Items, PPGStr(@SPPGGridSortAsc), HMSortAsc);
  It.Enabled := Sortable;
  It.Checked := (FSortCol = ACol) and FSortAscending;
  It := Add(M.Items, PPGStr(@SPPGGridSortDesc), HMSortDesc);
  It.Enabled := Sortable;
  It.Checked := (FSortCol = ACol) and not FSortAscending;
  Add(M.Items, PPGStr(@SPPGGridSortNone), HMSortNone).Enabled := FSortCol >= 0;
  if CanGroup and (Col <> nil) and (ACol >= FFixedCols) then
  begin
    Add(M.Items, '-', 0);
    if Col.GroupIndex >= 0 then
      Add(M.Items, PPGStr(@SPPGGridUngroup), HMUngroup)
    else
      Add(M.Items, PPGStr(@SPPGGridGroupBy), HMGroupBy);
    if GroupCount > 0 then
    begin
      Add(M.Items, PPGStr(@SPPGGridExpandAll), HMExpandAll);
      Add(M.Items, PPGStr(@SPPGGridCollapseAll), HMCollapseAll);
    end;
  end;
  Add(M.Items, '-', 0);
  // Spaltenauswahl (Kaestchen) nur mit Spalten-Objekten
  Shown := 0;
  for I := FFixedCols to FColCount - 1 do
  begin
    C2 := ColumnOf(I);
    if (C2 <> nil) and C2.Visible then
      Inc(Shown);
  end;
  Add(M.Items, PPGStr(@SPPGGridHideColumn), HMHide).Enabled :=
    (Col <> nil) and (ACol >= FFixedCols) and (Shown > 1);
  Sub := Add(M.Items, PPGStr(@SPPGGridColumnChooser), 0);
  for I := FFixedCols to FColCount - 1 do
  begin
    C2 := ColumnOf(I);
    if C2 = nil then
      Continue;
    It := Add(Sub, ColCaption(I), HMColumnBase + I);
    It.Checked := C2.Visible;
    // Die letzte sichtbare Spalte bleibt
    It.Enabled := not C2.Visible or (Shown > 1);
  end;
  Sub.Enabled := Sub.Count > 0;
  if Sub.Count > 0 then
  begin
    Add(Sub, '-', 0);
    Add(Sub, PPGStr(@SPPGGridShowAll), HMShowAll);
  end;
  Add(M.Items, '-', 0);
  Add(M.Items, PPGStr(@SPPGGridBestFit), HMBestFit);
  Add(M.Items, PPGStr(@SPPGGridBestFitAll), HMBestFitAll);
  if Assigned(FOnHeaderMenu) then
    FOnHeaderMenu(Self, ACol, M);
  Result := M;
end;

procedure TPPGCustomGrid.HeaderMenuClick(Sender: TObject);
var
  It: TMenuItem;
  M: TMenu;
  ACol, I: Integer;
  C: TPPGGridColumn;
begin
  if not (Sender is TMenuItem) then
    Exit;
  It := TMenuItem(Sender);
  M := It.GetParentMenu;
  if M = nil then
    Exit;
  ACol := M.Tag;
  C := ColumnOf(ACol);
  case It.Tag of
    HMSortAsc: SortBy(ACol, True);
    HMSortDesc: SortBy(ACol, False);
    HMSortNone: SortBy(-1);
    HMHide:
      if C <> nil then
        C.Visible := False;
    HMBestFit: AutoSizeColumn(ACol);
    HMBestFitAll:
      for I := FFixedCols to VColCount - 1 do
        AutoSizeColumn(DataCol(I));
    HMGroupBy: AddGroupColumn(ACol);
    HMUngroup: RemoveGroupColumn(ACol);
    HMExpandAll: FullExpand;
    HMCollapseAll: FullCollapse;
    HMShowAll:
      begin
        ColumnCollection.BeginUpdate;
        try
          for I := 0 to FColCount - 1 do
          begin
            C := ColumnOf(I);
            if C <> nil then
              C.Visible := True;
          end;
        finally
          ColumnCollection.EndUpdate;
        end;
      end;
  else
    if It.Tag >= HMColumnBase then
    begin
      C := ColumnOf(It.Tag - HMColumnBase);
      if C <> nil then
        C.Visible := not C.Visible;
    end;
  end;
end;

procedure TPPGCustomGrid.ShowHeaderMenu(ACol: Integer; const P: TPoint);
var
  M: TPopupMenu;
begin
  // Das Menue bleibt bis zum naechsten Aufruf bestehen: die Auswahl wird
  // nach dem Schliessen ausgeloest (PPG.Menus), dann muss es noch leben
  FreeAndNil(FHeaderMenuObj);
  M := CreateHeaderMenu(ACol);
  FHeaderMenuObj := M;
  M.PopupComponent := Self;
  M.Popup(P.X, P.Y);
end;

procedure TPPGCustomGrid.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
var
  C, V: Integer;
  R: TRect;
begin
  if FHeaderMenu and (FFixedRows > 0) and not (csDesigning in ComponentState) then
  begin
    if (MousePos.X = -1) and (MousePos.Y = -1) then
    begin
      // Tastatur (Umschalt+F10, Menuetaste) ohne eigenes PopupMenu:
      // Kopfmenue der Fokusspalte
      if (PopupMenu = nil) and (FFocusC >= FFixedCols) then
      begin
        R := CellRect(FFocusC, FFixedRows - 1);
        ShowHeaderMenu(DataCol(FFocusC), ClientToScreen(Point(R.Left, R.Bottom)));
        Handled := True;
        Exit;
      end;
    end
    else if MouseCoord(MousePos.X, MousePos.Y, C, V) and (V < FFixedRows) then
    begin
      ShowHeaderMenu(DataCol(C), ClientToScreen(MousePos));
      Handled := True;
      Exit;
    end;
  end;
  inherited DoContextPopup(MousePos, Handled);
end;

function TPPGCustomGrid.SaveLayout: string;
var
  SB: TStringBuilder;
  I, D: Integer;
  Order: array of Integer;
  J, T: Integer;
  C: TPPGGridColumn;
begin
  // Alle beweglichen Spalten in Anzeige-Reihenfolge (auch ausgeblendete)
  SetLength(Order, FColCount - FFixedCols);
  for I := 0 to High(Order) do
    Order[I] := FFixedCols + I;
  for I := 1 to High(Order) do
  begin
    T := Order[I];
    J := I - 1;
    while (J >= 0) and (ColumnSortKey(Order[J]) > ColumnSortKey(T)) do
    begin
      Order[J + 1] := Order[J];
      Dec(J);
    end;
    Order[J + 1] := T;
  end;
  SB := TStringBuilder.Create;
  try
    SB.Append('[PPGGridLayout]'#13#10'Version=1'#13#10);
    for I := 0 to High(Order) do
    begin
      D := Order[I];
      C := ColumnOf(D);
      // Col=<sichtbar>,<Breite>,<Schluessel> (Schluessel zuletzt: darf Kommas haben)
      SB.Append('Col=');
      if (C = nil) or C.Visible then
        SB.Append('1,')
      else
        SB.Append('0,');
      SB.Append(IntToStr(GetColWidths(D)));
      SB.Append(',');
      SB.Append(ColumnKey(D));
      SB.Append(#13#10);
    end;
    // Group=<Schluessel> je Ebene
    for I := 0 to High(FGroupCols) do
    begin
      SB.Append('Group=');
      SB.Append(ColumnKey(FGroupCols[I]));
      SB.Append(#13#10);
    end;
    if FSortCol >= 0 then
    begin
      SB.Append('Sort=');
      if FSortAscending then
        SB.Append('A,')
      else
        SB.Append('D,');
      SB.Append(ColumnKey(FSortCol));
      SB.Append(#13#10);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TPPGCustomGrid.LoadLayout(const S: string);
var
  GroupKeys: TArray<Integer>;
  L: TStringList;
  I, P, D, N, W, K, Pos2: Integer;
  Line, Name, Value, Key: string;
  Placed: array of Boolean;
  C: TPPGGridColumn;
  SortD: Integer;
  SortAsc: Boolean;

  function FindKey(const AKey: string): Integer;
  var
    J: Integer;
  begin
    for J := FFixedCols to FColCount - 1 do
      if ColumnKey(J) = AKey then
        Exit(J);
    Result := -1;
  end;

begin
  L := TStringList.Create;
  try
    L.Text := S;
    if (L.Count = 0) or (Trim(L[0]) <> '[PPGGridLayout]') then
      Exit; // kein Layout dieses Grids: unveraendert lassen
    HideEditor(True);
    SetLength(Placed, FColCount);
    N := 0;
    SortD := -1;
    SortAsc := True;
    ColumnCollection.BeginUpdate;
    try
      for I := 1 to L.Count - 1 do
      begin
        Line := L[I];
        P := Pos('=', Line);
        if P = 0 then
          Continue;
        Name := Copy(Line, 1, P - 1);
        Value := Copy(Line, P + 1, MaxInt);
        if Name = 'Col' then
        begin
          // <sichtbar>,<Breite>,<Schluessel>
          P := Pos(',', Value);
          if P = 0 then
            Continue;
          Pos2 := P + Pos(',', Copy(Value, P + 1, MaxInt));
          if Pos2 = P then
            Continue;
          W := StrToIntDef(Copy(Value, P + 1, Pos2 - P - 1), 0);
          Key := Copy(Value, Pos2 + 1, MaxInt);
          D := FindKey(Key);
          if (D < 0) or Placed[D] then
            Continue; // Spalte gibt es nicht mehr
          Placed[D] := True;
          C := ColumnOf(D);
          if C <> nil then
          begin
            C.DisplayIndex := N;
            C.Visible := Copy(Value, 1, P - 1) <> '0';
          end;
          // Klemmen statt werfen: Eine Ausnahme mitten im Laden liesse den
          // Rest (weitere Spalten, Gruppen, Sortierung) weg. Erlaubt ist, was
          // SetColWidths erlaubt (auch schmaler als MinColWidth).
          if W > 0 then
            SetColWidths(D, EnsureRangeInt(W, 1, 10000));
          Inc(N);
        end
        else if Name = 'Group' then
        begin
          D := FindKey(Value);
          if D >= 0 then
          begin
            SetLength(GroupKeys, Length(GroupKeys) + 1);
            GroupKeys[High(GroupKeys)] := D;
          end;
        end
        else if Name = 'Sort' then
        begin
          SortAsc := Copy(Value, 1, 1) <> 'D';
          SortD := FindKey(Copy(Value, 3, MaxInt));
        end;
      end;
      // Gruppierung aus dem Layout (ersetzt die bisherige)
      for K := 0 to FColCount - 1 do
      begin
        C := ColumnOf(K);
        if C <> nil then
          C.GroupIndex := -1;
      end;
      for K := 0 to High(GroupKeys) do
      begin
        C := ColumnOf(GroupKeys[K]);
        if C <> nil then
          C.GroupIndex := K;
      end;
      // Neue Spalten (nicht im Layout) hinten in bisheriger Reihenfolge
      for K := FFixedCols to FColCount - 1 do
        if not Placed[K] then
        begin
          C := ColumnOf(K);
          if C <> nil then
          begin
            C.DisplayIndex := N;
            Inc(N);
          end;
        end;
    finally
      ColumnCollection.EndUpdate;
    end;
    RebuildColumnMap;
    InvalidateGeometry;
    SortBy(SortD, SortAsc);
  finally
    L.Free;
  end;
end;
{ ---- Gruppieren und Summen (Phase 13c) ---- }

function TPPGCustomGrid.CanGroup: Boolean;
begin
  Result := True;
end;

function TPPGCustomGrid.ColumnCollection: TPPGGridColumns;
begin
  Result := FColumns;
end;

function TPPGCustomGrid.CurrentGroupColumns: TArray<Integer>;
var
  I, J, N: Integer;
  C: TPPGGridColumn;
  Keys: TArray<Integer>;
begin
  SetLength(Result, FColCount);
  SetLength(Keys, FColCount);
  N := 0;
  for I := FFixedCols to FColCount - 1 do
  begin
    C := ColumnOf(I);
    if (C <> nil) and (C.GroupIndex >= 0) then
    begin
      // Einfuegen nach GroupIndex (bei Gleichstand Datenindex)
      J := N - 1;
      while (J >= 0) and (Keys[J] > C.GroupIndex) do
      begin
        Result[J + 1] := Result[J];
        Keys[J + 1] := Keys[J];
        Dec(J);
      end;
      Result[J + 1] := I;
      Keys[J + 1] := C.GroupIndex;
      Inc(N);
    end;
  end;
  SetLength(Result, N);
end;

function TPPGCustomGrid.ViewGroupKey(ACol, ARow: Integer): string;
begin
  Result := GetCellText(ACol, ARow);
end;

procedure TPPGCustomGrid.GroupBy(const ACols: array of Integer);
var
  I, N: Integer;
  C: TPPGGridColumn;
begin
  HideEditor(True);
  ColumnCollection.BeginUpdate;
  try
    for I := 0 to FColCount - 1 do
    begin
      C := ColumnOf(I);
      if C <> nil then
        C.GroupIndex := -1;
    end;
    N := 0;
    for I := 0 to High(ACols) do
    begin
      C := ColumnOf(ACols[I]);
      if (C <> nil) and (ACols[I] >= FFixedCols) and (C.GroupIndex < 0) then
      begin
        C.GroupIndex := N;
        Inc(N);
      end;
    end;
  finally
    ColumnCollection.EndUpdate; // -> ColumnsChanged -> RebuildMap
  end;
end;

procedure TPPGCustomGrid.Ungroup;
begin
  GroupBy([]);
end;

function TPPGCustomGrid.GroupColumns: TArray<Integer>;
begin
  Result := Copy(FGroupCols);
end;

function TPPGCustomGrid.GroupCount: Integer;
begin
  if FView.Grouped then
    Result := FView.Group.Count
  else
    Result := 0;
end;

function TPPGCustomGrid.GroupInfo(Group: Integer): TPPGGridGroupInfo;
var
  G: TPPGGridGroup;
begin
  if (Group < 0) or (Group >= GroupCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Group, GroupCount - 1]);
  G := FView.Group.Groups[Group];
  Result.Level := G.Level;
  Result.Column := G.Column;
  Result.Key := G.Key;
  Result.Count := G.Count;
  Result.Expanded := G.Expanded;
  Result.Parent := G.Parent;
end;

function TPPGCustomGrid.GroupAtRow(VRow: Integer; out Footer: Boolean): Integer;
var
  E: Integer;
begin
  Result := -1;
  Footer := False;
  if (VRow < VFixedRows) or not FView.Grouped then
    Exit;
  E := FView.DataRowOf(VRow - VFixedRows);
  if PPGGridEntryIsGroup(E) then
  begin
    Result := PPGGridEntryGroup(E);
    Footer := PPGGridEntryIsFooter(E);
  end;
end;

function TPPGCustomGrid.GroupOfRow(VRow: Integer): Integer;
var
  Footer: Boolean;
begin
  Result := GroupAtRow(VRow, Footer);
  if Footer then
    Result := -1;
end;

function TPPGCustomGrid.GroupOfFooterRow(VRow: Integer): Integer;
var
  Footer: Boolean;
begin
  Result := GroupAtRow(VRow, Footer);
  if not Footer then
    Result := -1;
end;

function TPPGCustomGrid.GroupRow(Group: Integer): Integer;
begin
  Result := -1;
  if (Group >= 0) and (Group < GroupCount) and (FView.Group.HeaderAt[Group] >= 0) then
    Result := VFixedRows + FView.Group.HeaderAt[Group];
end;

procedure TPPGCustomGrid.ExpandGroup(Group: Integer; Expanded: Boolean);
var
  FD, FG, V: Integer;
  Footer: Boolean;
begin
  if (Group < 0) or (Group >= GroupCount) then
    Exit;
  if FView.Group.Groups[Group].Expanded = Expanded then
    Exit;
  HideEditor(True);
  // Fokus: an der Datenzeile bzw. Gruppenzeile bleiben, sonst auf die Gruppe
  FD := DataRow(FFocusV);
  FG := GroupAtRow(FFocusV, Footer);
  if Footer then
    FG := -1;
  FView.Group.SetExpanded(Group, Expanded);
  FView.Reflatten;
  if FD >= 0 then
    V := VisualRow(FD)
  else if FG >= 0 then
    V := GroupRow(FG)
  else
    V := -1;
  if V < 0 then
    V := GroupRow(Group);
  if V < VFixedRows then
    V := VFixedRows;
  FFocusV := EnsureRangeInt(V, 0, VRowCount - 1);
  FAnchorV := FFocusV;
  InvalidateGeometry;
end;

procedure TPPGCustomGrid.FullExpand;
begin
  if not FView.Grouped then
    Exit;
  HideEditor(True);
  FView.Group.ExpandAll(True);
  FView.Reflatten;
  FFocusV := EnsureRangeInt(FFocusV, VFixedRows, VRowCount - 1);
  FAnchorV := FFocusV;
  InvalidateGeometry;
end;

procedure TPPGCustomGrid.FullCollapse;
var
  G: Integer;
  Footer: Boolean;
begin
  if not FView.Grouped then
    Exit;
  HideEditor(True);
  // Fokus auf die oberste Gruppe der bisherigen Zeile
  G := GroupAtRow(FFocusV, Footer);
  if (G < 0) and (DataRow(FFocusV) >= 0) then
    G := -1;
  FView.Group.ExpandAll(False);
  FView.Reflatten;
  while (G >= 0) and (FView.Group.Groups[G].Parent >= 0) do
    G := FView.Group.Groups[G].Parent;
  if G >= 0 then
    FFocusV := GroupRow(G)
  else
    FFocusV := VFixedRows;
  FFocusV := EnsureRangeInt(FFocusV, 0, VRowCount - 1);
  FAnchorV := FFocusV;
  InvalidateGeometry;
end;

function MarkupEscape(const S: string): string;
begin
  Result := StringReplace(S, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
end;

function TPPGCustomGrid.GroupText(Group: Integer): string;
var
  G: TPPGGridGroup;
  Title: string;
  C: TPPGGridColumn;
begin
  Result := '';
  if (Group < 0) or (Group >= GroupCount) then
    Exit;
  G := FView.Group.Groups[Group];
  Title := '';
  if FFixedRows > 0 then
    Title := GetCellText(G.Column, 0);
  C := ColumnOf(G.Column);
  if (Title = '') and (C <> nil) then
    Title := C.Title;
  Result := '<b>' + MarkupEscape(Title) + ':</b> ' + MarkupEscape(G.Key) + ' (' +
    IntToStr(G.Count) + ')';
  if Assigned(FOnGetGroupText) then
    FOnGetGroupText(Self, Group, Result);
end;

function TPPGCustomGrid.GroupRowName(VRow: Integer): string;
var
  G, K: Integer;
  Footer: Boolean;
  Gr: TPPGGridGroup;
  S, Title: string;
begin
  Result := '';
  G := GroupAtRow(VRow, Footer);
  if G < 0 then
    Exit;
  Gr := FView.Group.Groups[G];
  if not Footer then
  begin
    if Assigned(FOnGetGroupText) then
      Result := PPGStripMarkup(GroupText(G))
    else
    begin
      Title := '';
      if FFixedRows > 0 then
        Title := GetCellText(Gr.Column, 0);
      Result := Format(PPGStr(@SPPGGridGroupName), [Title, Gr.Key, Gr.Count]);
    end;
    Exit;
  end;
  // Fuss: "Spalte: Wert; ..." der Summen
  for K := 0 to High(FAggCols) do
  begin
    S := GroupFooterText(G, FAggCols[K]);
    if S = '' then
      Continue;
    Title := '';
    if FFixedRows > 0 then
      Title := GetCellText(FAggCols[K], 0);
    if Result <> '' then
      Result := Result + '; ';
    Result := Result + Title + ': ' + S;
  end;
end;

function TPPGCustomGrid.GroupDataRows(Group: Integer): TArray<Integer>;
var
  I: Integer;
  G: TPPGGridGroup;
begin
  if (Group >= 0) and (Group < GroupCount) then
  begin
    G := FView.Group.Groups[Group];
    Result := Copy(FView.Group.Grouped, G.First, G.Count);
  end
  else
  begin
    SetLength(Result, FView.AllRowCount);
    for I := 0 to High(Result) do
      Result[I] := FView.AllRow(I);
  end;
end;

procedure TPPGCustomGrid.AggregatesChanged;
begin
  if [csLoading, csDestroying] * ComponentState <> [] then
    Exit;
  // Verzoegert neu rechnen: viele Aenderungen hintereinander (Cells in einer
  // Schleife) loesen nur EINE Berechnung aus
  FAggDirty := True;
  ClearPendingAggregates; // die volle Rechnung deckt sie ab
  PostAggregateMessage;
  Invalidate;
end;

procedure TPPGCustomGrid.PostAggregateMessage;
begin
  if HandleAllocated and not FAggPosted and (GMsgAggregate <> 0) then
  begin
    FAggPosted := True;
    PostMessage(Handle, GMsgAggregate, 0, 0);
  end;
end;

procedure TPPGCustomGrid.ClearPendingAggregates;
var
  I: Integer;
begin
  for I := 0 to FAggPendCount - 1 do
  begin
    FAggPend[I].OldText := '';
    FAggPend[I].NewText := '';
  end;
  FAggPendCount := 0;
end;

function TPPGCustomGrid.PlainCellText: Boolean;
var
  M: function(ACol, ARow: Integer): string of object;
begin
  M := GetCellText;
  Result := not Assigned(FOnGetCellText) and
    (TMethod(M).Code = @TPPGCustomGrid.GetCellText);
end;

function TPPGCustomGrid.AggIncrementalOk(ACol: Integer): Boolean;
const
  MaxPending = 4096; // danach ist eine volle Rechnung billiger
var
  I: Integer;
begin
  // Voll rechnen: Custom (Ereignis sieht alle Zeilen), virtuelle bzw.
  // umgeleitete Texte, Gruppenspalte, Statistik der bedingten Formate
  Result := CanGroup and not FAggHasCustom and (FAggPendCount < MaxPending) and PlainCellText;
  if not Result then
    Exit;
  for I := 0 to High(FGroupCols) do
    if FGroupCols[I] = ACol then
      Exit(False);
  for I := 0 to FCondFormats.Count - 1 do
    if FCondFormats[I].NeedsStats and (FCondFormats[I].Column = ACol) then
      Exit(False);
end;

procedure TPPGCustomGrid.CellDataChanged(ACol, ARow: Integer; const OldText, NewText: string;
  HaveOld: Boolean);
var
  N: Integer;
begin
  Inc(FDataVersion);
  if not StatsNeeded or ([csLoading, csDestroying] * ComponentState <> []) then
    Exit;
  if not HaveOld or FAggDirty or not AggIncrementalOk(ACol) then
  begin
    AggregatesChanged;
    Exit;
  end;
  // Spalte ohne Summe (und ohne Statistik): an den Summen aendert sich nichts
  if AggIndex(ACol) < 0 then
    Exit;
  // Vormerken: die Nachricht (bzw. FooterText) verrechnet alle zusammen
  if FAggPendCount >= Length(FAggPend) then
  begin
    N := Length(FAggPend) * 2;
    if N < 16 then
      N := 16;
    SetLength(FAggPend, N);
  end;
  FAggPend[FAggPendCount].Col := ACol;
  FAggPend[FAggPendCount].Row := ARow;
  FAggPend[FAggPendCount].OldText := OldText;
  FAggPend[FAggPendCount].NewText := NewText;
  Inc(FAggPendCount);
  PostAggregateMessage;
end;

function TPPGCustomGrid.RowInView(ARow: Integer): Boolean;
begin
  if (ARow < FFixedRows) or (ARow >= FRowCount) then
    Result := False
  else if not FView.Mapped then
    Result := True
  else
    Result := FView.ViewIndexOf(ARow) >= 0;
end;

function TPPGCustomGrid.LeafGroupOf(ARow: Integer): Integer;
var
  G, R: Integer;
  Gr: TPPGGridGroup;
  Rows: TArray<Integer>;
begin
  // Datenzeile -> unterste Gruppe, einmal je Rechnung aufgebaut
  if FAggRowLeaf = nil then
  begin
    SetLength(FAggRowLeaf, FRowCount);
    for R := 0 to High(FAggRowLeaf) do
      FAggRowLeaf[R] := -1;
    Rows := FView.Group.Grouped;
    for G := 0 to GroupCount - 1 do
    begin
      Gr := FView.Group.Groups[G];
      if Gr.FirstChild < 0 then
        for R := Gr.First to Gr.First + Gr.Count - 1 do
          if (Rows[R] >= 0) and (Rows[R] < Length(FAggRowLeaf)) then
            FAggRowLeaf[Rows[R]] := G;
    end;
  end;
  if (ARow >= 0) and (ARow < Length(FAggRowLeaf)) then
    Result := FAggRowLeaf[ARow]
  else
    Result := -1;
end;

function TPPGCustomGrid.ApplyAggChange(const Ch: TPPGGridAggChange): Boolean;
var
  K, G, P: Integer;
  C: TPPGGridColumn;
  Kind: TPPGGridAggregate;
begin
  Result := True;
  K := AggIndex(Ch.Col);
  if (K < 0) or (K >= Length(FFooterAcc)) then
    Exit;
  C := ColumnOf(Ch.Col);
  if (C = nil) or (C.Aggregate = agCustom) then
    Exit(False);
  Kind := C.Aggregate;
  // Gehoert die Zeile zur Ansicht (und zu welcher Gruppe)?
  if FView.Grouped then
  begin
    G := LeafGroupOf(Ch.Row);
    if G < 0 then
      Exit;
  end
  else
  begin
    if not RowInView(Ch.Row) then
      Exit;
    G := -1;
  end;
  // Min/Max nur aufbauend, sonst voll rechnen
  if not FFooterAcc[K].CanReplace(Kind, Ch.OldText, Ch.NewText) then
    Exit(False);
  P := G;
  while P >= 0 do
  begin
    if (P >= Length(FGroupAcc)) or (K >= Length(FGroupAcc[P])) then
      Exit(False);
    if not FGroupAcc[P][K].CanReplace(Kind, Ch.OldText, Ch.NewText) then
      Exit(False);
    P := FView.Group.Groups[P].Parent;
  end;
  // Gruppe, ihre Eltern und die Summenzeile
  FFooterAcc[K].Remove(Ch.OldText);
  FFooterAcc[K].Add(Ch.NewText);
  P := G;
  while P >= 0 do
  begin
    FGroupAcc[P][K].Remove(Ch.OldText);
    FGroupAcc[P][K].Add(Ch.NewText);
    P := FView.Group.Groups[P].Parent;
  end;
end;

procedure TPPGCustomGrid.ApplyPendingAggregates;
var
  I: Integer;
  Ok: Boolean;
begin
  if FAggPendCount = 0 then
    Exit;
  if FAggDirty then
  begin
    RecalcAggregates;
    Exit;
  end;
  Ok := True;
  for I := 0 to FAggPendCount - 1 do
    if not ApplyAggChange(FAggPend[I]) then
    begin
      Ok := False;
      Break;
    end;
  ClearPendingAggregates;
  if not Ok then
    RecalcAggregates;
end;

procedure TPPGCustomGrid.RecalcAggregates;
var
  I, K, G, GC, R, P, Col, NAgg: Integer;
  C: TPPGGridColumn;
  HasCustom: Boolean;
  Rows: TArray<Integer>;
  Groups: TArray<TPPGGridGroup>;
  S: string;
begin
  FAggDirty := False;
  Inc(FAggRecalcCount);
  FAggSig := AggSignature;
  ClearPendingAggregates;
  FAggRowLeaf := nil;
  FAggHasCustom := False;
  FAggViewKey := '';
  // Spalten mit Zusammenfassung
  SetLength(FAggCols, FColCount);
  NAgg := 0;
  HasCustom := False;
  for I := 0 to FColCount - 1 do
  begin
    C := ColumnOf(I);
    if (C <> nil) and (C.Aggregate <> agNone) then
    begin
      FAggCols[NAgg] := I;
      Inc(NAgg);
      if C.Aggregate = agCustom then
        HasCustom := True;
    end;
  end;
  SetLength(FAggCols, NAgg);
  SetLength(FFooterAcc, NAgg);
  SetLength(FFooterCustom, NAgg);
  FAggHasCustom := HasCustom;
  // agCustom kann von der Reihenfolge abhaengen: dann immer neu rechnen
  if not HasCustom then
    FAggViewKey := AggViewKey;
  for K := 0 to NAgg - 1 do
  begin
    FFooterAcc[K].Reset;
    FFooterCustom[K] := '';
  end;
  GC := GroupCount;
  SetLength(FGroupAcc, 0);
  SetLength(FGroupCustom, 0);
  // Statistiken fuer bedingte Formate (Oben-N, Farbskala, Datenbalken ...)
  // Ansicht nicht im Speicher (DB-Grid): Summen liefert die Datenmenge
  if not CanGroup then
  begin
    SetLength(FAggCols, 0);
    SetLength(FFooterAcc, 0);
    SetLength(FFooterCustom, 0);
    Exit;
  end;
  if (FCondFormats <> nil) and FCondFormats.NeedsStats then
    ComputeCondStats;
  if NAgg = 0 then
    Exit;
  SetLength(FGroupAcc, GC);
  SetLength(Groups, GC);
  for G := 0 to GC - 1 do
  begin
    SetLength(FGroupAcc[G], NAgg);
    for K := 0 to NAgg - 1 do
      FGroupAcc[G][K].Reset;
    Groups[G] := FView.Group.Groups[G];
  end;
  if GC > 0 then
    Rows := FView.Group.Grouped;
  for K := 0 to NAgg - 1 do
  begin
    Col := FAggCols[K];
    if ColumnOf(Col).Aggregate = agCustom then
      Continue;
    if GC > 0 then
    begin
      // Unterste Gruppen lesen die Zeilen, die oberen fuehren nur zusammen
      for G := 0 to GC - 1 do
        if Groups[G].FirstChild < 0 then
          for R := Groups[G].First to Groups[G].First + Groups[G].Count - 1 do
            FGroupAcc[G][K].Add(GetCellText(Col, Rows[R]));
      // Vorordnung: Untergruppen haben hoehere Nummern als ihre Eltern
      for G := GC - 1 downto 0 do
      begin
        P := Groups[G].Parent;
        if P >= 0 then
          FGroupAcc[P][K].Merge(FGroupAcc[G][K])
        else
          FFooterAcc[K].Merge(FGroupAcc[G][K]);
      end;
    end
    else
      for R := 0 to FView.AllRowCount - 1 do
        FFooterAcc[K].Add(GetCellText(Col, FView.AllRow(R)));
  end;
  // agCustom ueber das Ereignis
  if HasCustom then
  begin
    SetLength(FGroupCustom, GC);
    for G := 0 to GC - 1 do
      SetLength(FGroupCustom[G], NAgg);
    for K := 0 to NAgg - 1 do
    begin
      Col := FAggCols[K];
      if ColumnOf(Col).Aggregate <> agCustom then
        Continue;
      S := '';
      if Assigned(FOnCustomAggregate) then
        FOnCustomAggregate(Self, Col, -1, S);
      FFooterCustom[K] := S;
      for G := 0 to GC - 1 do
      begin
        S := '';
        if Assigned(FOnCustomAggregate) then
          FOnCustomAggregate(Self, Col, G, S);
        FGroupCustom[G][K] := S;
      end;
    end;
  end;
end;

function TPPGCustomGrid.AggIndex(ACol: Integer): Integer;
var
  K: Integer;
begin
  for K := 0 to High(FAggCols) do
    if FAggCols[K] = ACol then
      Exit(K);
  Result := -1;
end;

function TPPGCustomGrid.CachedFooterText(ACol: Integer): string;
var
  K: Integer;
  C: TPPGGridColumn;
begin
  Result := '';
  K := AggIndex(ACol);
  C := ColumnOf(ACol);
  if (K < 0) or (C = nil) or (K >= Length(FFooterAcc)) then
    Exit;
  if C.Aggregate = agCustom then
    Result := FFooterCustom[K]
  else
    Result := FFooterAcc[K].Text(C.Aggregate, C.FooterFormat);
end;

function TPPGCustomGrid.CachedGroupFooterText(Group, ACol: Integer): string;
var
  K: Integer;
  C: TPPGGridColumn;
begin
  Result := '';
  K := AggIndex(ACol);
  C := ColumnOf(ACol);
  if (K < 0) or (C = nil) or (Group < 0) or (Group >= Length(FGroupAcc)) or
    (K >= Length(FGroupAcc[Group])) then
    Exit;
  if C.Aggregate = agCustom then
  begin
    if (Group < Length(FGroupCustom)) and (K < Length(FGroupCustom[Group])) then
      Result := FGroupCustom[Group][K];
  end
  else
    Result := FGroupAcc[Group][K].Text(C.Aggregate, C.FooterFormat);
end;

function TPPGCustomGrid.FooterText(ACol: Integer): string;
begin
  if FAggDirty then
    RecalcAggregates
  else
    ApplyPendingAggregates;
  Result := CachedFooterText(ACol);
end;

function TPPGCustomGrid.GroupFooterText(Group, ACol: Integer): string;
begin
  if FAggDirty then
    RecalcAggregates
  else
    ApplyPendingAggregates;
  Result := CachedGroupFooterText(Group, ACol);
end;

procedure TPPGCustomGrid.SetShowFooter(const Value: Boolean);
begin
  if FShowFooter <> Value then
  begin
    FShowFooter := Value;
    InvalidateGeometry;
  end;
end;

procedure TPPGCustomGrid.SetGroupFooter(const Value: Boolean);
begin
  if FGroupFooter <> Value then
  begin
    FGroupFooter := Value;
    HideEditor(True);
    FView.Group.Footers := Value;
    if FView.Grouped then
    begin
      FView.Reflatten;
      FFocusV := EnsureRangeInt(FFocusV, 0, VRowCount - 1);
      FAnchorV := FFocusV;
    end;
    InvalidateGeometry;
  end;
end;

procedure TPPGCustomGrid.SetShowGroupPanel(const Value: Boolean);
begin
  if FShowGroupPanel <> Value then
  begin
    FShowGroupPanel := Value;
    InvalidateGeometry;
  end;
end;

function TPPGCustomGrid.GroupPanelHeight: Integer;
begin
  if FShowGroupPanel then
    Result := PPGScale(FDefaultRowHeight + 14, ScalePPI)
  else
    Result := 0;
end;

function TPPGCustomGrid.FooterHeight: Integer;
begin
  if FShowFooter then
    Result := PPGScale(FDefaultRowHeight, ScalePPI)
  else
    Result := 0;
end;

function TPPGCustomGrid.GroupPanelRect: TRect;
var
  V: TRect;
begin
  V := ViewRect;
  Result := Rect(V.Left, V.Top, V.Right, V.Top + GroupPanelHeight);
end;

function TPPGCustomGrid.GroupChipCaption(Index: Integer): string;
var
  C: TPPGGridColumn;
begin
  Result := '';
  if FFixedRows > 0 then
    Result := GetCellText(FGroupCols[Index], 0);
  C := ColumnOf(FGroupCols[Index]);
  if (Result = '') and (C <> nil) then
    Result := C.Title;
end;

function TPPGCustomGrid.GroupChipRects: TArray<TRect>;
var
  PR, R: TRect;
  I, X, W, PPI, VPad: Integer;
  DC: HDC;
  Old: HGDIOBJ;
  Sz: TSize;
  T: string;
begin
  SetLength(Result, Length(FGroupCols));
  if Length(Result) = 0 then
    Exit;
  PR := GroupPanelRect;
  PPI := ScalePPI;
  VPad := PPGScale(6, PPI);
  X := PR.Left + PPGScale(8, PPI);
  DC := GetDC(0);
  try
    Old := SelectObject(DC, Font.Handle);
    try
      for I := 0 to High(Result) do
      begin
        T := GroupChipCaption(I);
        Sz.cx := 0;
        if T <> '' then
          GetTextExtentPoint32(DC, PChar(T), Length(T), Sz);
        // Text + Abstand + Schliessen-Zeichen
        W := Sz.cx + PPGScale(8 + 6 + 14, PPI);
        R := Rect(X, PR.Top + VPad, X + W, PR.Bottom - VPad);
        if UseRightToLeftAlignment then
          R := Rect(PR.Left + PR.Right - R.Right, R.Top, PR.Left + PR.Right - R.Left, R.Bottom);
        Result[I] := R;
        Inc(X, W + PPGScale(10, PPI));
      end;
    finally
      SelectObject(DC, Old);
    end;
  finally
    ReleaseDC(0, DC);
  end;
end;

procedure DrawTextGdi(const ACanvas: IPPGCanvas; AFont: TFont; const S: string;
  R: TRect; Color: TColor; Flags: Cardinal);
var
  DC: HDC;
begin
  if (S = '') or IsRectEmpty(R) then
    Exit;
  DC := ACanvas.BeginGdi;
  try
    SelectObject(DC, AFont.Handle);
    SetBkMode(DC, TRANSPARENT);
    SetTextColor(DC, ColorToRGB(Color));
    Winapi.Windows.DrawText(DC, PChar(S), Length(S), R, Flags);
  finally
    ACanvas.EndGdi(DC);
  end;
end;

procedure TPPGCustomGrid.PaintGroupPanel(const ACanvas: IPPGCanvas; const R: TRect);
var
  Rects: TArray<TRect>;
  I, PPI, CW: Integer;
  TR, XR: TRect;
  Fl: Cardinal;
begin
  PPI := ScalePPI;
  ACanvas.FillRoundRect(R, 0, PPGBlendColor(FPaint.Fill, FPaint.Header, 0.5), 255);
  ACanvas.FillRoundRect(Rect(R.Left, R.Bottom - 1, R.Right, R.Bottom), 0, FPaint.Line, 255);
  Fl := DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
  if Length(FGroupCols) = 0 then
  begin
    TR := R;
    InflateRect(TR, -PPGScale(10, PPI), 0);
    DrawTextGdi(ACanvas, Font, PPGStr(@SPPGGridGroupPanelHint), TR, FPaint.Hint, Fl);
  end
  else
  begin
    Rects := GroupChipRects;
    CW := PPGScale(14, PPI);
    for I := 0 to High(Rects) do
    begin
      ACanvas.FillRoundRect(Rects[I], PPGScale(4, PPI), FPaint.Fill, 255);
      ACanvas.FrameRoundRect(Rects[I], PPGScale(4, PPI), PPGScale(4, PPI), FPaint.Line, 255);
      TR := Rects[I];
      XR := TR;
      if UseRightToLeftAlignment then
      begin
        XR.Right := XR.Left + CW + PPGScale(4, PPI);
        TR.Left := XR.Right;
        Dec(TR.Right, PPGScale(8, PPI));
      end
      else
      begin
        XR.Left := XR.Right - CW - PPGScale(4, PPI);
        TR.Right := XR.Left;
        Inc(TR.Left, PPGScale(8, PPI));
      end;
      DrawTextGdi(ACanvas, Font, GroupChipCaption(I), TR, FPaint.Text, Fl);
      // Schliessen-Zeichen (Malkreuz)
      DrawTextGdi(ACanvas, Font, Char($D7), XR, FPaint.Hint,
        DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_NOPREFIX);
    end;
  end;
  // Ziel beim Hineinziehen eines Spaltenkopfs
  if FColDragging and FDropToGroup then
  begin
    TR := R;
    InflateRect(TR, -1, -1);
    ACanvas.FrameRoundRect(TR, 0, 0, FPaint.Accent, 255);
  end;
end;

procedure TPPGCustomGrid.PaintFooter(const ACanvas: IPPGCanvas; const R: TRect);
var
  FR, Pad, PPI: Integer;
  GV: TRect;
  FootFont: TFont;
  FootText: TColor;

  procedure Area(VFrom, VTo: Integer; ALeft, ARight: Integer);
  var
    VC, X0, X1: Integer;
    AR, CR, TR: TRect;
    S: string;
    Col: TPPGGridColumn;
    Al: TAlignment;
  begin
    if (VFrom > VTo) or (ALeft >= ARight) then
      Exit;
    AR := Rect(ALeft, R.Top, ARight, R.Bottom);
    if UseRightToLeftAlignment then
      AR := Rect(GV.Left + GV.Right - AR.Right, AR.Top, GV.Left + GV.Right - AR.Left, AR.Bottom);
    ACanvas.PushClipRoundRect(AR, 0);
    try
      for VC := VFrom to VTo do
      begin
        X0 := GV.Left + ColLeft(VC);
        X1 := X0 + FColX[VC + 1] - FColX[VC];
        CR := Rect(X0, R.Top, X1, R.Bottom);
        if UseRightToLeftAlignment then
          CR := Rect(GV.Left + GV.Right - CR.Right, CR.Top, GV.Left + GV.Right - CR.Left, CR.Bottom);
        // Trennlinie wie im Kopf
        if goFixedVertLine in FOptions then
          if UseRightToLeftAlignment then
            ACanvas.FillRoundRect(Rect(CR.Left, CR.Top, CR.Left + 1, CR.Bottom), 0, FPaint.Line, 255)
          else
            ACanvas.FillRoundRect(Rect(CR.Right - 1, CR.Top, CR.Right, CR.Bottom), 0, FPaint.Line, 255);
        S := CachedFooterText(FVisCols[VC]);
        if S = '' then
          Continue;
        Col := ColumnOf(FVisCols[VC]);
        Al := taRightJustify; // Summen stehen rechts, ausser die Spalte will anders
        if (Col <> nil) and (Col.Alignment <> taLeftJustify) then
          Al := Col.Alignment;
        TR := CR;
        InflateRect(TR, -Pad, 0);
        DrawTextGdi(ACanvas, FootFont, S, TR, FootText,
          DrawTextBiDiModeFlags(TPPGCellPainter.TextFlags(Al)));
      end;
    finally
      ACanvas.PopClip;
    end;
  end;

begin
  PPI := ScalePPI;
  Pad := PPGScale(CellPadX, PPI);
  GV := GridViewRect;
  // Styles.Footer, ohne Werte wie der Kopf
  FootFont := FFontCache.ForStyle(FStyles.Footer, FPaint.HeaderFont);
  FootText := FPaint.HeaderText;
  if FPaint.UseColors then
  begin
    FootText := FStyles.Footer.TextFor(FPaint.Dark, FootText);
    ACanvas.FillRoundRect(R, 0, FStyles.Footer.FillFor(FPaint.Dark, FPaint.Header), 255);
  end
  else
    ACanvas.FillRoundRect(R, 0, FPaint.Header, 255);
  ACanvas.FillRoundRect(Rect(R.Left, R.Top, R.Right, R.Top + 1), 0, FPaint.HeaderLine, 255);
  FR := FirstRightCol;
  Area(0, FFixedCols - 1, GV.Left, GV.Left + FixedWidth);
  if FR < VColCount then
  begin
    Area(FFixedCols, FR - 1, GV.Left + FixedWidth, GV.Left + ColLeft(FR));
    Area(FR, VColCount - 1, GV.Left + ColLeft(FR), GV.Right);
  end
  else
    Area(FFixedCols, VColCount - 1, GV.Left + FixedWidth, GV.Right);
end;

function TPPGCustomGrid.GroupExpanderRect(VRow: Integer): TRect;
var
  G, PPI, X: Integer;
  RR, GV: TRect;
begin
  Result := Rect(0, 0, 0, 0);
  G := GroupOfRow(VRow);
  if G < 0 then
    Exit;
  PPI := ScalePPI;
  GV := GridViewRect;
  RR := RawCellRect(FFixedCols, VRow);
  X := GV.Left + FixedWidth + PPGScale(4, PPI) +
    FView.Group.Groups[G].Level * PPGScale(16, PPI);
  Result := Rect(X, RR.Top, X + PPGScale(16, PPI), RR.Bottom);
  if UseRightToLeftAlignment then
    Result := Rect(GV.Left + GV.Right - Result.Right, Result.Top,
      GV.Left + GV.Right - Result.Left, Result.Bottom);
end;

procedure TPPGCustomGrid.PaintGroupRow(const ACanvas: IPPGCanvas; VRow: Integer;
  const Clip: TRect; MainArea: Boolean);
var
  G, PPI, TX, TY: Integer;
  RR, Row, ER: TRect;
  GF: TFont;
  GT: TColor;
begin
  G := GroupOfRow(VRow);
  if G < 0 then
    Exit;
  PPI := ScalePPI;
  RR := RawCellRect(FFixedCols, VRow);
  Row := Rect(Clip.Left, RR.Top, Clip.Right, RR.Bottom);
  IntersectRect(Row, Row, Clip);
  if IsRectEmpty(Row) then
    Exit;
  // Deckend ueber Zellen und Gitterlinien: die Gruppenzeile ist eine Zeile
  if FPaint.UseColors and FStyles.GroupRow.HasFill(FPaint.Dark) then
    ACanvas.FillRoundRect(Row, 0, FStyles.GroupRow.FillFor(FPaint.Dark, FPaint.Fill), 255)
  else
    ACanvas.FillRoundRect(Row, 0, PPGBlendColor(FPaint.Fill, FPaint.Header, 0.6), 255);
  ACanvas.FillRoundRect(Rect(Row.Left, RR.Bottom - 1, Row.Right, RR.Bottom), 0, FPaint.Line, 255);
  if VRow = FFocusV then
  begin
    if Focused then
      ACanvas.FillRoundRect(Row, 0, FPaint.Accent, 46)
    else
      ACanvas.FillRoundRect(Row, 0, FPaint.Text, 22);
  end;
  if not MainArea then
    Exit;
  ER := GroupExpanderRect(VRow);
  FPainter.DrawExpander(ACanvas, ER, PPGBlendColor(FPaint.Text, FPaint.Header, 0.2),
    FView.Group.Groups[G].Expanded, UseRightToLeftAlignment, PPI);
  GF := FFontCache.ForStyle(FStyles.GroupRow, Font);
  GT := FPaint.Text;
  if FPaint.UseColors then
    GT := FStyles.GroupRow.TextFor(FPaint.Dark, GT);
  FGroupMarkup.Layout(GroupText(G), GF, nil, 0, False);
  TY := RR.Top + ((RR.Bottom - RR.Top) - FGroupMarkup.Size.cy) div 2;
  if UseRightToLeftAlignment then
    TX := ER.Left - PPGScale(4, PPI) - FGroupMarkup.Size.cx
  else
    TX := ER.Right + PPGScale(4, PPI);
  FGroupMarkup.Draw(ACanvas, TX, TY, GT, FPaint.Accent, Enabled);
end;

procedure TPPGCustomGrid.AddGroupColumn(ACol: Integer);
var
  L: TArray<Integer>;
  I: Integer;
begin
  for I := 0 to High(FGroupCols) do
    if FGroupCols[I] = ACol then
      Exit;
  L := Copy(FGroupCols);
  SetLength(L, Length(L) + 1);
  L[High(L)] := ACol;
  GroupBy(L);
end;

procedure TPPGCustomGrid.RemoveGroupColumn(ACol: Integer);
var
  L: TArray<Integer>;
  I, N: Integer;
begin
  SetLength(L, Length(FGroupCols));
  N := 0;
  for I := 0 to High(FGroupCols) do
    if FGroupCols[I] <> ACol then
    begin
      L[N] := FGroupCols[I];
      Inc(N);
    end;
  SetLength(L, N);
  GroupBy(L);
end;

procedure TPPGCustomGrid.GroupPanelClick(X, Y: Integer);
var
  Rects: TArray<TRect>;
  I, Col, CW: Integer;
  XR: TRect;
begin
  Rects := GroupChipRects;
  CW := PPGScale(14 + 4, ScalePPI);
  for I := 0 to High(Rects) do
    if PtInRect(Rects[I], Point(X, Y)) then
    begin
      Col := FGroupCols[I];
      XR := Rects[I];
      if UseRightToLeftAlignment then
        XR.Right := XR.Left + CW
      else
        XR.Left := XR.Right - CW;
      if PtInRect(XR, Point(X, Y)) then
        RemoveGroupColumn(Col) // Kreuz: Gruppierung aufheben
      else if FSortCol = Col then
        SortBy(Col, not FSortAscending) // Chip: Reihenfolge der Gruppen umkehren
      else
        SortBy(Col, False);
      Exit;
    end;
end;

function TPPGCustomGrid.CanDragColumn(VCol: Integer): Boolean;
begin
  Result := ((goColMoving in FOptions) and CanMoveColumn(VCol)) or
    (FShowGroupPanel and CanGroup and (VCol >= FFixedCols) and (ColumnOf(DataCol(VCol)) <> nil));
end;

{ ---- Zellen: Zellarten, bedingte Formate, Verbindungen (Phase 13d) ---- }

procedure TPPGCustomGrid.SetConditionalFormats(const Value: TPPGGridConditionalFormats);
begin
  FCondFormats.Assign(Value);
end;

procedure TPPGCustomGrid.StylesChanged;
begin
  // Statistiken (Oben-N, Farbskala ...) werden mit den Summen neu berechnet
  FAggDirty := True;
  AggregatesChanged;
  Invalidate;
end;

function TPPGCustomGrid.KindOf(ACol: Integer): IPPGCellKind;
var
  C: TPPGGridColumn;
begin
  Result := nil;
  C := ColumnOf(ACol);
  if C = nil then
    Exit;
  if (C.EditorKind = gekCheck) or (C.CellKind = ckCheck) then
    Result := PPGCellKind(ckCheck)
  else if C.CellKind <> ckText then
    Result := PPGCellKind(C.CellKind, C.CellKindName);
end;

procedure TPPGCustomGrid.PrepareKindContext(const ACanvas: IPPGCanvas);
var
  A: TPPGAppearance;
  PPI: Integer;
begin
  PPI := ScalePPI;
  A := EffectiveAppearance;
  FKindCtx.Canvas := ACanvas;
  FKindCtx.Painter := FPainter;
  FKindCtx.PPI := PPI;
  FKindCtx.Font := Font;
  FKindCtx.Images := Images;
  FKindCtx.Tokens := Tokens;
  FKindCtx.TextColor := FPaint.Text;
  FKindCtx.FillColor := FPaint.Fill;
  FKindCtx.LineColor := FPaint.Line;
  FKindCtx.AccentColor := FPaint.Accent;
  FKindCtx.HintColor := FPaint.Hint;
  FKindCtx.CheckedStyle := A.ResolveStyle(A.Checked, PPI, False);
  FKindCtx.CheckedStyle.GlowAlpha := 0;
  FKindCtx.CheckedStyle.GlowSize := 0;
  FKindCtx.UncheckedStyle := A.Resolve(vsNormal, PPI, False);
  FKindCtx.UncheckedStyle.GlowAlpha := 0;
  FKindCtx.UncheckedStyle.GlowSize := 0;
  FKindCtx.Enabled := Enabled;
  FKindCtx.RightToLeft := UseRightToLeftAlignment;
  FKindCtx.MinValue := 0;
  FKindCtx.MaxValue := 0;
end;

function TPPGCustomGrid.KindContext(ACol: Integer): TPPGCellKindContext;
var
  C: TPPGGridColumn;
begin
  // Ausserhalb des Zeichnens (Maus, Tastatur, Screenreader): ohne Canvas
  if FKindCtx.Painter = nil then
    PrepareKindContext(nil);
  Result := FKindCtx;
  C := ColumnOf(ACol);
  if C <> nil then
  begin
    Result.MinValue := C.MinValue;
    Result.MaxValue := C.MaxValue;
  end;
end;

procedure TPPGCustomGrid.DoCellAction(Action: TPPGCellAction; ACol, VRow: Integer;
  const NewText: string);
var
  D: Integer;
  S: string;
  Ok: Boolean;
begin
  D := DataRow(VRow);
  if D < FFixedRows then
    Exit;
  case Action of
    caSetValue:
      if CanEditCell(ACol, VRow) then
      begin
        // Wie beim Editor: OnValidateCell darf ablehnen oder aendern
        S := NewText;
        Ok := True;
        if Assigned(FOnValidateCell) then
          FOnValidateCell(Self, ACol, D, S, Ok);
        if Ok then
          SetCellByUser(ACol, D, S);
      end;
    caLink:
      if Assigned(FOnLinkClick) then
        FOnLinkClick(Self, ACol, D, NewText);
    caButton:
      if Assigned(FOnCellButtonClick) then
        FOnCellButtonClick(Self, ACol, D);
  end;
end;

function TPPGCustomGrid.CellStyle(ACol, ARow: Integer; const Text: string): TPPGGridCellStyle;
begin
  Result.Reset;
  if FCondFormats.Count > 0 then
    FCondFormats.Apply(ACol, Text, FKindCtx.Tokens, FPaint.Fill, Result);
  if Assigned(FOnGetCellStyle) then
    FOnGetCellStyle(Self, ACol, ARow, Result);
end;

procedure TPPGCustomGrid.MergeCells(ACol, ARow, AColSpan, ARowSpan: Integer);
var
  I, N: Integer;
  M: TPPGGridMerge;
begin
  if (ACol < 0) or (ACol + AColSpan > FColCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [ACol, FColCount - 1]);
  if (ARow < 0) or (ARow + ARowSpan > FRowCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [ARow, FRowCount - 1]);
  if (AColSpan < 1) or (ARowSpan < 1) or (AColSpan * ARowSpan < 2) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGInvalidArgument), [AColSpan * ARowSpan, 'Span']);
  for I := 0 to High(FMerges) do
  begin
    M := FMerges[I];
    if not ((ACol + AColSpan <= M.Col) or (M.Col + M.ColSpan <= ACol) or
      (ARow + ARowSpan <= M.Row) or (M.Row + M.RowSpan <= ARow)) then
      raise EPPGError.CreateFmt(PPGStr(@SPPGInvalidArgument), [I, 'MergeCells']);
  end;
  N := Length(FMerges);
  SetLength(FMerges, N + 1);
  FMerges[N].Col := ACol;
  FMerges[N].Row := ARow;
  FMerges[N].ColSpan := AColSpan;
  FMerges[N].RowSpan := ARowSpan;
  HideEditor(True);
  Invalidate;
end;

procedure TPPGCustomGrid.UnmergeCells(ACol, ARow: Integer);
var
  I, J: Integer;
begin
  for I := High(FMerges) downto 0 do
    if (ACol >= FMerges[I].Col) and (ACol < FMerges[I].Col + FMerges[I].ColSpan) and
      (ARow >= FMerges[I].Row) and (ARow < FMerges[I].Row + FMerges[I].RowSpan) then
    begin
      for J := I to High(FMerges) - 1 do
        FMerges[J] := FMerges[J + 1];
      SetLength(FMerges, Length(FMerges) - 1);
      Invalidate;
    end;
end;

procedure TPPGCustomGrid.ClearMerges;
begin
  FMerges := nil;
  Invalidate;
end;

function TPPGCustomGrid.MergeCount: Integer;
begin
  Result := Length(FMerges);
end;

function TPPGCustomGrid.MergeInfo(Index: Integer): TPPGGridMerge;
begin
  if (Index < 0) or (Index > High(FMerges)) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, High(FMerges)]);
  Result := FMerges[Index];
end;

function TPPGCustomGrid.MergesActive: Boolean;
begin
  // Sortieren, Filtern und Gruppieren aendern die Zeilenfolge: dann ruhen
  // die Verbindungen (wie bei TMS)
  Result := (Length(FMerges) > 0) and not FView.Mapped;
end;

function TPPGCustomGrid.VisualMerge(I: Integer; out C0, R0, C1, R1: Integer): Boolean;
var
  K: Integer;
  M: TPPGGridMerge;
begin
  Result := False;
  M := FMerges[I];
  C0 := VisualCol(M.Col);
  R0 := VisualRow(M.Row);
  if (C0 < 0) or (R0 < 0) then
    Exit;
  // Spalten muessen zusammenhaengend angezeigt werden (verschoben/ausgeblendet: ruht)
  for K := 1 to M.ColSpan - 1 do
    if VisualCol(M.Col + K) <> C0 + K then
      Exit;
  C1 := C0 + M.ColSpan - 1;
  R1 := R0 + M.RowSpan - 1;
  if VisualRow(M.Row + M.RowSpan - 1) <> R1 then
    Exit;
  // Nicht ueber die Grenze fester/scrollbarer/rechts fixierter Bereiche
  if ((C0 < FFixedCols) <> (C1 < FFixedCols)) or
    ((C0 >= FirstRightCol) <> (C1 >= FirstRightCol)) or
    ((R0 < VFixedRows) <> (R1 < VFixedRows)) then
    Exit;
  Result := True;
end;

function TPPGCustomGrid.MergeAtCell(VCol, VRow: Integer; out C0, R0, C1, R1: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  if not MergesActive then
    Exit;
  for I := 0 to High(FMerges) do
    if VisualMerge(I, C0, R0, C1, R1) and (VCol >= C0) and (VCol <= C1) and
      (VRow >= R0) and (VRow <= R1) then
      Exit(True);
end;

function TPPGCustomGrid.RangeRect(C0, R0, C1, R1: Integer): TRect;
begin
  UnionRect(Result, RawCellRect(C0, R0), RawCellRect(C1, R1));
end;

function TPPGCustomGrid.StatsNeeded: Boolean;
begin
  // Audit 08.10.2026: Farbskala, Datenbalken und Oben-N blieben ohne
  // Summenspalte nach einer Zellaenderung veraltet
  Result := (Length(FAggCols) > 0) or ((FCondFormats <> nil) and FCondFormats.NeedsStats);
end;

procedure TPPGCustomGrid.ComputeCondStats;
var
  I, J, R, Col, N: Integer;
  Rule: TPPGGridConditionalFormat;
  Vals: TArray<Double>;
  Done: array of Boolean;
  V: Double;
  S: string;
begin
  SetLength(Done, FCondFormats.Count);
  for I := 0 to FCondFormats.Count - 1 do
  begin
    Rule := FCondFormats[I];
    if Done[I] or not Rule.NeedsStats or (Rule.Column >= FColCount) then
      Continue;
    Col := Rule.Column;
    SetLength(Vals, FView.AllRowCount);
    N := 0;
    for R := 0 to FView.AllRowCount - 1 do
    begin
      S := GetCellText(Col, FView.AllRow(R));
      if PPGCondParseNumber(S, V) then
      begin
        Vals[N] := V;
        Inc(N);
      end;
    end;
    SetLength(Vals, N);
    // Alle Regeln dieser Spalte mit denselben Werten (Spalte nur einmal lesen)
    for J := I to FCondFormats.Count - 1 do
      if not Done[J] and FCondFormats[J].NeedsStats and (FCondFormats[J].Column = Col) then
      begin
        FCondFormats[J].ComputeStats(Vals);
        Done[J] := True;
      end;
  end;
end;

{ ---- Geometrie ---- }

procedure TPPGCustomGrid.InvalidateGeometry;
begin
  FColGeomValid := False;
  FRowGeomValid := False;
  Invalidate;
  if HandleAllocated and not (csLoading in ComponentState) then
    EnsureGeometry;
end;

procedure TPPGCustomGrid.InvalidateColGeometry;
begin
  FColGeomValid := False;
  Invalidate;
  if HandleAllocated and not (csLoading in ComponentState) then
    EnsureGeometry;
end;

function TPPGCustomGrid.ColPixelWidth(ACol: Integer): Integer;
begin
  Result := PPGScale(GetColWidths(ACol), ScalePPI);
  if Result < 0 then
    Result := 0;
end;

procedure TPPGCustomGrid.EnsureGeometry;
var
  I, N, X, H, BH: Integer;
  PPI: Integer;
begin
  PPI := ScalePPI;
  if FColGeomValid and FRowGeomValid and (FGeomPPI = PPI) then
    Exit;
  FPaintCached := False; // Geometrie aendert sich: keine Paint-Werte mehr
  if FGeomPPI <> PPI then
  begin
    FColGeomValid := False;
    FRowGeomValid := False;
  end;
  FGeomPPI := PPI;
  // Spalten in Anzeige-Reihenfolge (ausgeblendete fehlen)
  N := VColCount;
  if not FColGeomValid or (Length(FColX) <> N + 1) then
  begin
    FColGeomValid := True;
    SetLength(FColX, N + 1);
    X := 0;
    for I := 0 to N - 1 do
    begin
      FColX[I] := X;
      Inc(X, ColPixelWidth(FVisCols[I]));
    end;
    FColX[N] := X;
  end;
  X := FColX[N];
  if not FRowGeomValid then
    BuildRowGeometry(PPI);
  // Baender liegen ueber dem Kopf und gehoeren zur Inhaltshoehe
  BH := BandHeight + GroupPanelHeight + FooterHeight;
  H := RowsContentHeight;
  if H > MaxInt - BH then
    H := MaxInt - BH;
  SetContentSize(X, H + BH);
end;

procedure TPPGCustomGrid.BuildRowGeometry(PPI: Integer);
var
  J, N, V, H, Def: Integer;
  Pairs: TArray<Int64>;
  Sorted: Boolean;
begin
  FRowGeomValid := True;
  Inc(FRowGeomCount);
  Def := PPGScale(FDefaultRowHeight, PPI);
  FLayout.Count := 0;
  FLayout.DefaultHeight := Def;
  FLayout.Count := VRowCount;
  if not FHasRowHeights or (FRowHeightStore.OwnHeightCount = 0) then
    Exit;
  // Nur die k Zeilen mit eigener Hoehe (Audit 8c #5): Datenzeile ->
  // sichtbare Zeile, aufsteigend ins Layout (Anhaengen ist O(1))
  SetLength(Pairs, FRowHeightStore.OwnHeightCount);
  N := 0;
  Sorted := True;
  for J := 0 to FRowHeightStore.OwnHeightCount - 1 do
  begin
    H := PPGScale(FRowHeightStore.OwnHeightValue(J), PPI);
    if H = Def then
      Continue;
    V := VisualRow(FRowHeightStore.OwnHeightRow(J));
    if (V < 0) or (V >= FLayout.Count) then
      Continue;
    Pairs[N] := (Int64(V) shl 32) or Cardinal(H);
    if (N > 0) and (Pairs[N] < Pairs[N - 1]) then
      Sorted := False;
    Inc(N);
  end;
  SetLength(Pairs, N);
  if not Sorted then
    TArray.Sort<Int64>(Pairs);
  for J := 0 to N - 1 do
    FLayout.SetRowHeight(Integer(Pairs[J] shr 32), Integer(Pairs[J] and $FFFFFFFF));
end;

function TPPGCustomGrid.FixedWidth: Integer;
begin
  EnsureGeometry;
  Result := FColX[FFixedCols];
end;

function TPPGCustomGrid.FixedHeight: Integer;
begin
  EnsureGeometry;
  if VFixedRows >= FLayout.Count then
    Result := Integer(FLayout.TotalHeight64)
  else
    Result := Integer(FLayout.RowTop(VFixedRows));
end;

function TPPGCustomGrid.CellRect(ACol, VRow: Integer): TRect;
var
  V: TRect;
  X, Y: Int64;
  W: Integer;
begin
  Result := Rect(0, 0, 0, 0);
  EnsureGeometry;
  if (ACol < 0) or (ACol >= VColCount) or (VRow < 0) or (VRow >= FLayout.Count) then
    Exit;
  V := GridViewRect;
  X := ColLeft(ACol);
  Y := FLayout.RowTop(VRow);
  if VRow >= VFixedRows then
    Y := Y - RowScrollY;
  W := FColX[ACol + 1] - FColX[ACol];
  if (Y > V.Bottom - V.Top) or (Y + FLayout.RowHeight(VRow) < 0) then
    Exit;
  Result := Rect(V.Left + Integer(X), V.Top + Integer(Y), V.Left + Integer(X) + W,
    V.Top + Integer(Y) + FLayout.RowHeight(VRow));
  if UseRightToLeftAlignment then
    Result := Rect(V.Left + V.Right - Result.Right, Result.Top,
      V.Left + V.Right - Result.Left, Result.Bottom);
end;

function TPPGCustomGrid.MouseCoord(X, Y: Integer; out ACol, VRow: Integer): Boolean;
var
  V: TRect;
  CX, Lo, Hi, Off: Integer;
  CY: Int64;
  I: Integer;
begin
  Result := False;
  ACol := -1;
  VRow := -1;
  EnsureGeometry;
  V := GridViewRect;
  if not PtInRect(V, Point(X, Y)) then
    Exit;
  if UseRightToLeftAlignment then
    X := V.Left + V.Right - X - 1;
  CX := X - V.Left;
  // Bereich bestimmen: feste links, rechts fixierte oder scrollbare Spalten
  if CX < FixedWidth then
  begin
    Lo := 0;
    Hi := FFixedCols - 1;
    Off := 0;
  end
  else if (FirstRightCol < VColCount) and (CX >= ColLeft(FirstRightCol)) then
  begin
    Lo := FirstRightCol;
    Hi := VColCount - 1;
    Off := MaxColScroll;
  end
  else
  begin
    Lo := FFixedCols;
    Hi := FirstRightCol - 1;
    Off := ScrollX;
  end;
  Inc(CX, Off);
  for I := Lo to Hi do
    if (CX >= FColX[I]) and (CX < FColX[I + 1]) then
    begin
      ACol := I;
      Break;
    end;
  CY := Y - V.Top;
  if CY >= FixedHeight then
    Inc(CY, RowScrollY);
  if (CY < FLayout.TotalHeight64) and (FLayout.Count > 0) then
    VRow := FLayout.RowAt(CY);
  Result := (ACol >= 0) and (VRow >= 0);
end;

procedure TPPGCustomGrid.MakeCellVisible(ACol, VRow: Integer);
var
  V: TRect;
  X, Y, VW, VH, CL, CR: Integer;
  RT, RB: Int64;
begin
  EnsureGeometry;
  if (ACol < 0) or (ACol >= VColCount) or (VRow < 0) or (VRow >= FLayout.Count) then
    Exit;
  V := GridViewRect;
  X := ScrollX;
  Y := RowScrollY;
  VW := (V.Right - V.Left) - FixedWidth - FixedRightWidth;
  VH := (V.Bottom - V.Top) - FixedHeight;
  if (ACol >= FFixedCols) and (ACol < FirstRightCol) then
  begin
    CL := FColX[ACol] - FixedWidth;
    CR := FColX[ACol + 1] - FixedWidth;
    if CL < X then
      X := CL
    else if CR > X + VW then
      X := CR - VW;
  end;
  if VRow >= VFixedRows then
  begin
    RT := FLayout.RowTop(VRow) - FixedHeight;
    RB := RT + FLayout.RowHeight(VRow);
    if RT < Y then
      Y := Integer(RT)
    else if RB > Y + VH then
      Y := Integer(RB - VH);
  end;
  ScrollCellsTo(X, Y);
end;

procedure TPPGCustomGrid.Resize;
begin
  inherited Resize;
  HideEditor(True);
end;

procedure TPPGCustomGrid.Scrolled;
begin
  inherited Scrolled;
  // Editor wuerde sonst neben der Zelle stehen: uebernehmen und schliessen
  HideEditor(True);
  if Assigned(FOnTopLeftChanged) then
    FOnTopLeftChanged(Self);
end;

procedure TPPGCustomGrid.CMFontChanged(var Message: TMessage);
begin
  inherited;
  FontsChanged;
  InvalidateGeometry;
end;

procedure TPPGCustomGrid.FontsChanged;
begin
  if FFontCache <> nil then
    FFontCache.Clear;
end;

{ ---- Farben und Zeichnen ---- }

{ ---- Element-Stile (Anpassbarkeit) ---- }

procedure TPPGCustomGrid.SetStyles(const Value: TPPGGridStyles);
begin
  FStyles.Assign(Value);
end;

procedure TPPGCustomGrid.StylesObjChanged(Sender: TObject);
begin
  FontsChanged; // Schrift eines Element-Stils kann sich geaendert haben
  Invalidate;
end;

procedure TPPGCustomGrid.SetGridLineWidth(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'GridLineWidth', Value, 0, 10);
  if FGridLineWidth <> V then
  begin
    FGridLineWidth := V;
    Invalidate;
  end;
end;

procedure TPPGCustomGrid.SetDrawingStyle(const Value: TGridDrawingStyle);
begin
  if FDrawingStyle <> Value then
  begin
    FDrawingStyle := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomGrid.SetGradientStartColor(const Value: TColor);
begin
  if FGradientStartColor <> Value then
  begin
    FGradientStartColor := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomGrid.SetGradientEndColor(const Value: TColor);
begin
  if FGradientEndColor <> Value then
  begin
    FGradientEndColor := Value;
    Invalidate;
  end;
end;

function TPPGCustomGrid.GetFixedColor: TColor;
begin
  if FStyles.Header.Color = clDefault then
    Result := clBtnFace
  else
    Result := FStyles.Header.Color;
end;

procedure TPPGCustomGrid.SetFixedColor(const Value: TColor);
begin
  // clBtnFace ist die Vorgabe von TStringGrid: Kopf vom Preset
  if Value = clBtnFace then
    FStyles.Header.Color := clDefault
  else
    FStyles.Header.Color := Value;
end;

procedure TPPGCustomGrid.SetHotRow(VRow: Integer);
var
  Old: Integer;
begin
  if FHotV = VRow then
    Exit;
  Old := FHotV;
  FHotV := VRow;
  // Nur neu zeichnen, wenn die Zeile ueberhaupt hervorgehoben wird - und
  // nur die alte und die neue Zeile (Audit 8b)
  if FStyles.HotRow.HasFill(UseDarkMode) or FStyles.HotRow.HasText(UseDarkMode) or
    (FStyles.HotRow.FontStyle <> []) then
  begin
    if Assigned(FOnDrawCell) or Assigned(FOnGetCellStyle) or MergesActive then
      Invalidate
    else
    begin
      InvalidateViewRow(Old);
      InvalidateViewRow(VRow);
    end;
  end;
end;

procedure TPPGCustomGrid.InvalidateViewRow(VRow: Integer);
var
  R, GV: TRect;
begin
  // Ganze Breite der Zeile (feste und rechts fixierte Spalten eingeschlossen)
  if (VRow < 0) or not HandleAllocated then
    Exit;
  EnsureGeometry;
  if VRow >= FLayout.Count then
    Exit;
  GV := GridViewRect;
  R := RawCellRect(0, VRow);
  R.Left := GV.Left;
  R.Right := GV.Right;
  // Feste Zeilen bleiben oben stehen, scrollende nicht darueber
  if (VRow >= VFixedRows) and (R.Top < GV.Top + FixedHeight) then
    R.Top := GV.Top + FixedHeight;
  IntersectRect(R, R, GV);
  InvalidateArea(R);
end;

procedure TPPGCustomGrid.PrepareStyleColors;
var
  I: Integer;
begin
  FPaint.UseColors := UseOwnColors;
  FPaint.Dark := UseDarkMode;
  FPaint.HeaderText := FPaint.Text;
  FPaint.FocusFrame := FPaint.Accent;
  if FPaint.UseColors then
  begin
    FPaint.Line := FStyles.GridLine.FillFor(FPaint.Dark, FPaint.Line);
    FPaint.Header := FStyles.Header.FillFor(FPaint.Dark, FPaint.Header);
    FPaint.HeaderText := FStyles.Header.TextFor(FPaint.Dark, FPaint.Text);
    FPaint.FocusFrame := FStyles.FocusedCell.BorderFor(FPaint.Dark, FPaint.Accent);
  end;
  FPaint.HeaderLine := FPaint.Line;
  if FPaint.UseColors then
    FPaint.HeaderLine := FStyles.Header.BorderFor(FPaint.Dark, FPaint.Line);
  FPaint.Gradient := FPaint.UseColors and not FPaint.Dark and (FDrawingStyle = gdsGradient);
  FPaint.CellStyles := FStyles.AlternateRow.HasFill(FPaint.Dark) or
    FStyles.HotRow.HasFill(FPaint.Dark) or FStyles.FilterRow.HasFill(FPaint.Dark) or
    FStyles.Footer.HasFill(FPaint.Dark);
  if not FPaint.CellStyles then
    for I := 0 to FColumns.Count - 1 do
      if FColumns[I].Style.HasFill(FPaint.Dark) or FColumns[I].TitleStyle.HasFill(FPaint.Dark) then
      begin
        FPaint.CellStyles := True;
        Break;
      end;
  FPaint.HeaderFont := FFontCache.ForStyle(FStyles.Header, Font);
end;

function TPPGCustomGrid.CellFont(Col: TPPGGridColumn; const St: TPPGGridCellStyle;
  Extra: TFontStyles): TFont;
var
  Base: TFont;
begin
  // Spaltenschrift (eigene Schrift auf die PPI des Grids, plus FontStyle)
  if Col <> nil then
    Base := FFontCache.ForStyle(Col.Style, Font)
  else
    Base := Font;
  Extra := Extra + St.FontStyle;
  if St.Bold then
    Include(Extra, fsBold);
  Result := FFontCache.Get(Base, Extra, St.FontName, St.FontSize);
end;

procedure TPPGCustomGrid.GetGridColors(out Fill, Text, Header, Line, Accent: TColor);
var
  T: TPPGTokens;
  SelFill, SelText: TColor;
begin
  Accent := PPGColorToRGB(EffectiveAppearance.FocusColor);
  if UseHighContrast then
  begin
    // Sonderfall: keine Mischfarben; Linien in Textfarbe (Tokens = Systemfarben)
    T := Tokens;
    Fill := T.Surface;
    Text := T.TextPrimary;
    Header := T.Layer;
    Line := T.Stroke;
    Accent := T.Accent;
    if not Enabled then
      Text := T.TextDisabled;
    Exit;
  end;
  if UseVclStyle then
  begin
    PPGVclStyleListColors(Fill, Text, SelFill, SelText);
    Accent := SelFill;
  end
  else if UseDarkMode then
  begin
    T := Tokens;
    Fill := T.Surface;
    Text := T.TextPrimary;
  end
  else
  begin
    Fill := PPGColorToRGB(Color);
    Text := PPGColorToRGB(Font.Color);
  end;
  Header := PPGBlendColor(Fill, Text, 0.05);
  Line := PPGBlendColor(Fill, Text, 0.13);
  // Deaktiviert: Text und Auswahl zuruecknehmen (Flaechen bleiben)
  if not Enabled then
  begin
    Text := PPGBlendColor(Text, Fill, 0.55);
    Accent := PPGBlendColor(Accent, Fill, 0.65);
  end;
end;

function TPPGCustomGrid.GetScrollStyle: TPPGSurfaceStyle;
var
  Fill, Text, Header, Line, Accent: TColor;
begin
  Result := inherited GetScrollStyle;
  GetGridColors(Fill, Text, Header, Line, Accent);
  Result.Color := Fill;
  Result.TextColor := Text;
end;

function TPPGCustomGrid.GetBackgroundColor: TColor;
var
  Fill, Text, Header, Line, Accent: TColor;
begin
  // Mit Rahmen gehoeren die Ecken ausserhalb der Rundung dem Parent
  if (FBorderStyle = bsSingle) and (Parent <> nil) then
    Exit(TCtrlAccess(Parent).Color);
  GetGridColors(Fill, Text, Header, Line, Accent);
  Result := Fill;
end;

procedure TPPGCustomGrid.SetDefaultDrawing(const Value: Boolean);
begin
  if FDefaultDrawing = Value then
    Exit;
  FDefaultDrawing := Value;
  Invalidate;
end;

function TPPGCustomGrid.CellEditorKind(ACol, ARow: Integer): TPPGGridEditorKind;
var
  C: TPPGGridColumn;
begin
  C := ColumnOf(ACol);
  if C = nil then
    Result := gekText
  else
    Result := C.EditorKind;
  // Zellarten ohne Texteingabe
  if C <> nil then
    case C.CellKind of
      ckCheck: Result := gekCheck;
      ckLink, ckButton:
        if Result = gekText then
          Result := gekNone;
    end;
end;

function TPPGCustomGrid.RawCellRect(ACol, VRow: Integer): TRect;
var
  V: TRect;
  X, Y: Int64;
begin
  // Wie CellRect, aber ohne Sichtbarkeitspruefung (fuer Auswahl-Rechtecke)
  if FPaintCached then
    V := FPaintGV
  else
    V := GridViewRect;
  X := ColLeft(ACol);
  Y := FLayout.RowTop(VRow);
  if VRow >= VFixedRows then
    Y := Y - RowScrollY;
  if Y > MaxInt div 2 then
    Y := MaxInt div 2;
  if Y < -(MaxInt div 2) then
    Y := -(MaxInt div 2);
  Result := Rect(V.Left + Integer(X), V.Top + Integer(Y),
    V.Left + Integer(X) + FColX[ACol + 1] - FColX[ACol],
    V.Top + Integer(Y) + FLayout.RowHeight(VRow));
  if UseRightToLeftAlignment then
    Result := Rect(V.Left + V.Right - Result.Right, Result.Top,
      V.Left + V.Right - Result.Left, Result.Bottom);
end;

procedure TPPGCustomGrid.DrawCellExtras(const ACanvas: IPPGCanvas; ACol, VRow: Integer;
  const R: TRect; const S: string);
var
  PPI: Integer;
  D: Integer;
  K: IPPGCellKind;
  Ctx: TPPGCellKindContext;
begin
  PPI := ScalePPI;
  D := DataRow(VRow);
  // Zellart (Kaestchen, Fortschritt, Link ...)
  if (D >= FFixedRows) and (VisualCol(ACol) >= FFixedCols) then
  begin
    K := KindOf(ACol);
    if K <> nil then
    begin
      Ctx := KindContext(ACol);
      Ctx.Canvas := ACanvas;
      K.PaintCell(Ctx, R, S);
    end;
  end;
  // Sortierpfeil in der Kopfzeile
  if (D = 0) and (FFixedRows > 0) and (ACol = FSortCol) then
    FPainter.DrawSortArrow(ACanvas, R, FSortAscending, UseRightToLeftAlignment,
      PPGBlendColor(FPaint.HeaderText, FPaint.Header, 0.3), PPI);
end;

procedure TPPGCustomGrid.DrawCell(const ACanvas: IPPGCanvas; ACol, VRow: Integer;
  const R: TRect);
var
  State: TGridDrawState;
  Sl: TGridRect;
  D: Integer;
  DC: HDC;
begin
  // Owner-Draw (wie TStringGrid.OnDrawCell) auf einem TCanvas; Hintergrund,
  // Linien und (bei DefaultDrawing) Text sind schon gezeichnet. ACol ist die
  // Anzeige-Spalte; das Ereignis bekommt Daten-Spalte und -Zeile.
  D := DataRow(VRow);
  if not Assigned(FOnDrawCell) or (D < 0) then
    Exit;
  Sl := GetSelection;
  State := [];
  if (ACol >= Sl.Left) and (ACol <= Sl.Right) and (VRow >= Sl.Top) and (VRow <= Sl.Bottom) then
    Include(State, gdSelected);
  if (ACol = FFocusC) and (VRow = FFocusV) and Focused then
    Include(State, gdFocused);
  if (ACol < FFixedCols) or (D < FFixedRows) then
    Include(State, gdFixed);
  DC := ACanvas.BeginGdi;
  try
    FItemCanvas.Handle := DC;
    try
      FItemCanvas.Font := Font;
      FItemCanvas.Font.Color := FPaint.Text;
      FItemCanvas.Brush.Style := bsClear;
      FInOwnerDraw := True;
      try
        FOnDrawCell(Self, DataCol(ACol), D, R, State);
      finally
        FInOwnerDraw := False;
      end;
    finally
      FItemCanvas.Handle := 0;
    end;
  finally
    ACanvas.EndGdi(DC);
  end;
end;

function TPPGCustomGrid.GetCanvas: TCanvas;
begin
  if FInOwnerDraw then
    Result := FItemCanvas
  else
    Result := inherited Canvas;
end;

procedure TPPGCustomGrid.PaintRegion(const ACanvas: IPPGCanvas; ColFrom, ColTo,
  RowFrom, RowTo: Integer; const AClip: TRect; FixedArea: Boolean);
type
  TVisMerge = record
    C0, R0, C1, R1: Integer;
    R: TRect;
  end;
var
  Clip, BR: TRect;
  C, V, D, DCol, Pad, PPI, I, K, NX, NM, W, Idx, IconW: Integer;
  HasGroups, HasStyles: Boolean;
  R, LR, SR, TR: TRect;
  Sl: TGridRect;
  ExtraC, ExtraV: array of Integer;
  ExtraS: array of string;
  StyleRec: array of TPPGGridCellStyle;
  StyleIcon: array of Boolean;
  VM: array of TVisMerge;
  S: string;
  TC: TColor;
  Col: TPPGGridColumn;
  DC: HDC;
  LineBrush: HBRUSH;
  VLine, HLine, HasKind: Boolean;
  St: TPPGGridCellStyle;
  Pts: array[0..3] of TPoint;
  LW: Integer;           // Linienbreite (px)
  HasSel: Boolean;
  SelSt: TPPGElementStyle;
  F: TFont;
  Extra: TFontStyles;
  Al: TAlignment;
  IsHead: Boolean;
  Cut: array of TPoint; // ausgesparte Abschnitte (Von, Bis) einer Linie
  // Audit 8c #12: Text je Zelle nur einmal je Zeichnen lesen
  CellTexts: array of string;
  HaveText: array of Boolean;
  // Zellart und ihr Kontext je Spalte (statt je Zelle)
  KindArr: array of IPPGCellKind;
  KindCtxArr: array of TPPGCellKindContext;
  HaveCtx: array of Boolean;
  K2: IPPGCellKind;
  // Audit 8c #8: deckende Flaechen gesammelt, per GDI in einem Block
  FillR: array of TRect;
  FillC: array of TColor;
  NF: Integer;

  function CellIndex(AC, AV: Integer): Integer;
  begin
    Result := (AV - RowFrom) * (ColTo - ColFrom + 1) + (AC - ColFrom);
  end;

  function CellText(AC, AV, AD, ADCol: Integer): string;
  var
    J: Integer;
  begin
    J := CellIndex(AC, AV);
    if not HaveText[J] then
    begin
      CellTexts[J] := GetCellText(ADCol, AD);
      HaveText[J] := True;
    end;
    Result := CellTexts[J];
  end;

  procedure AddFill(const AR: TRect; AColor: TColor);
  var
    L: Integer;
  begin
    if IsRectEmpty(AR) then
      Exit;
    // Nachbarzellen gleicher Farbe in derselben Zeile zu einer Spanne
    L := NF - 1;
    if (L >= 0) and (FillC[L] = AColor) and (FillR[L].Top = AR.Top) and
      (FillR[L].Bottom = AR.Bottom) and ((FillR[L].Right = AR.Left) or (AR.Right = FillR[L].Left)) then
    begin
      if AR.Left < FillR[L].Left then
        FillR[L].Left := AR.Left;
      if AR.Right > FillR[L].Right then
        FillR[L].Right := AR.Right;
      Exit;
    end;
    if NF >= Length(FillR) then
    begin
      SetLength(FillR, NF * 2 + 16);
      SetLength(FillC, NF * 2 + 16);
    end;
    FillR[NF] := AR;
    FillC[NF] := AColor;
    Inc(NF);
  end;

  procedure FlushFills;
  var
    J: Integer;
    FDC: HDC;
    B: HBRUSH;
    BC: TColor;
  begin
    if NF = 0 then
      Exit;
    FDC := ACanvas.BeginGdi;
    try
      B := 0;
      BC := clNone;
      try
        for J := 0 to NF - 1 do
        begin
          if (B = 0) or (FillC[J] <> BC) then
          begin
            if B <> 0 then
              DeleteObject(B);
            B := CreateSolidBrush(ColorToRGB(FillC[J]));
            BC := FillC[J];
          end;
          if B <> 0 then
            Winapi.Windows.FillRect(FDC, FillR[J], B);
        end;
      finally
        if B <> 0 then
          DeleteObject(B);
      end;
    finally
      ACanvas.EndGdi(FDC);
    end;
    NF := 0;
  end;

  function InMerge(AC, AV: Integer): Boolean;
  var
    J: Integer;
  begin
    for J := 0 to NM - 1 do
      if (AC >= VM[J].C0) and (AC <= VM[J].C1) and (AV >= VM[J].R0) and (AV <= VM[J].R1) then
        Exit(True);
    Result := False;
  end;

  procedure AddCellText(const ATR: TRect; const AS_: string; AC: TColor; AAl: TAlignment;
    AF: TFont);
  begin
    if (AF = nil) or (AF = Font) then
      FPainter.AddText(ATR, AS_, AC, DrawTextBiDiModeFlags(TPPGCellPainter.TextFlags(AAl)))
    else
      FPainter.AddTextFont(ATR, AS_, AC, DrawTextBiDiModeFlags(TPPGCellPainter.TextFlags(AAl)),
        AF.Handle);
  end;

  function InSel(AC, AV: Integer): Boolean;
  begin
    Result := HasSel and (AC >= Sl.Left) and (AC <= Sl.Right) and (AV >= Sl.Top) and
      (AV <= Sl.Bottom);
  end;

  function IsZebraRow(AV: Integer): Boolean;
  begin
    Result := Odd(AV - VFixedRows);
  end;

  procedure StyleBackgrounds;
  var
    AV, AC, AD: Integer;
    CR: TRect;
    RowFill, CF: TColor;
    ACol: TPPGGridColumn;
    Dk, HotRow: Boolean;
  begin
    // Element-Stile: Filterzeile, Gruppenfuss, Zebra, Hover-Zeile, Spalten und
    // Spaltenkoepfe (nur gesetzte Farben)
    Dk := FPaint.Dark;
    for AV := RowFrom to RowTo do
    begin
      AD := DataRow(AV);
      RowFill := clNone;
      HotRow := False;
      if AD = FilterRowMark then
      begin
        if FStyles.FilterRow.HasFill(Dk) then
          RowFill := FStyles.FilterRow.FillFor(Dk, clNone);
      end
      else if AD = GroupFooterMark then
      begin
        if FStyles.Footer.HasFill(Dk) then
          RowFill := FStyles.Footer.FillFor(Dk, clNone);
      end
      else if AD >= FFixedRows then
      begin
        if FStyles.AlternateRow.HasFill(Dk) and IsZebraRow(AV) then
          RowFill := FStyles.AlternateRow.FillFor(Dk, clNone);
        if (AV = FHotV) and FStyles.HotRow.HasFill(Dk) then
        begin
          RowFill := FStyles.HotRow.FillFor(Dk, clNone);
          HotRow := True;
        end;
      end
      else if AD < 0 then
        Continue;
      for AC := ColFrom to ColTo do
      begin
        CF := RowFill;
        ACol := ColumnOf(FVisCols[AC]);
        if ACol <> nil then
          if (AD = 0) and (FFixedRows > 0) then
          begin
            if ACol.TitleStyle.HasFill(Dk) then
              CF := ACol.TitleStyle.FillFor(Dk, CF);
          end
          else if (AD >= FFixedRows) and (AC >= FFixedCols) and not HotRow and
            ACol.Style.HasFill(Dk) then
            CF := ACol.Style.FillFor(Dk, CF);
        if CF = clNone then
          Continue;
        CR := RawCellRect(AC, AV);
        IntersectRect(CR, CR, Clip);
        if not IsRectEmpty(CR) then
          AddFill(CR, CF);
      end;
    end;
    FlushFills;
  end;

  procedure LineSegments(AFrom, ATo: Integer; Vertical: Boolean; Fixed: Integer);
  var
    J, P, T: Integer;
  begin
    // Linie von AFrom bis ATo zeichnen, ohne die Abschnitte in Cut
    P := AFrom;
    while P < ATo do
    begin
      T := ATo;
      for J := 0 to High(Cut) do
        if (Cut[J].X <= P) and (Cut[J].Y > P) then
        begin
          P := Cut[J].Y; // im ausgesparten Abschnitt: dahinter weiter
          T := -1;
          Break;
        end
        else if (Cut[J].X > P) and (Cut[J].X < T) then
          T := Cut[J].X;
      if T < 0 then
        Continue;
      if Vertical then
      begin
        if UseRightToLeftAlignment then
          Winapi.Windows.FillRect(DC, Rect(Fixed, P, Fixed + LW, T), LineBrush)
        else
          Winapi.Windows.FillRect(DC, Rect(Fixed - LW + 1, P, Fixed + 1, T), LineBrush);
      end
      else
        Winapi.Windows.FillRect(DC, Rect(P, Fixed - LW, T, Fixed), LineBrush);
      P := T;
    end;
  end;

begin
  if IsRectEmpty(AClip) or (ColFrom > ColTo) or (RowFrom > RowTo) then
    Exit;
  // Nur so weit wie die Zellen reichen (rechts der letzten Spalte und unter
  // der letzten Zeile bleibt die Flaeche des Grids)
  UnionRect(BR, RawCellRect(ColFrom, RowFrom), RawCellRect(ColTo, RowTo));
  IntersectRect(Clip, AClip, BR);
  if IsRectEmpty(Clip) then
    Exit;
  PPI := ScalePPI;
  Pad := PPGScale(CellPadX, PPI);
  IconW := PPGScale(14, PPI);
  I := (ColTo - ColFrom + 1) * (RowTo - RowFrom + 1);
  SetLength(CellTexts, I);
  SetLength(HaveText, I);
  SetLength(KindArr, ColTo - ColFrom + 1);
  SetLength(KindCtxArr, ColTo - ColFrom + 1);
  SetLength(HaveCtx, ColTo - ColFrom + 1);
  for C := ColFrom to ColTo do
    KindArr[C - ColFrom] := KindOf(FVisCols[C]);
  NF := 0;
  ACanvas.PushClipRoundRect(Clip, 0);
  try
    // 0. Verbundene Zellen in diesem Bereich (auch mit Ursprung ausserhalb)
    NM := 0;
    if MergesActive then
      for I := 0 to High(FMerges) do
      begin
        SetLength(VM, NM + 1);
        if VisualMerge(I, VM[NM].C0, VM[NM].R0, VM[NM].C1, VM[NM].R1) and
          (VM[NM].C1 >= ColFrom) and (VM[NM].C0 <= ColTo) and
          (VM[NM].R1 >= RowFrom) and (VM[NM].R0 <= RowTo) then
        begin
          VM[NM].R := RangeRect(VM[NM].C0, VM[NM].R0, VM[NM].C1, VM[NM].R1);
          Inc(NM);
        end;
      end;
    // 1. Hintergrund (deckend, GDI)
    DC := ACanvas.BeginGdi;
    try
      if FixedArea then
      begin
        if not FPaint.Gradient then
          TPPGCellPainter.FillGdi(DC, Clip, FPaint.Header);
      end
      else
        TPPGCellPainter.FillGdi(DC, Clip, FPaint.Fill);
    finally
      ACanvas.EndGdi(DC);
    end;
    // Kopf als Verlauf (DrawingStyle = gdsGradient, wie TStringGrid)
    if FixedArea and FPaint.Gradient then
      ACanvas.FillGradientRect(Clip, PPGColorToRGB(FGradientStartColor),
        PPGColorToRGB(FGradientEndColor), gdVertical, 255);
    // Auswahl (Anzeige-Zeilen) fuer Flaechen und Textfarben
    HasSel := False;
    if not FixedArea and (ColFrom >= FFixedCols) then
    begin
      Sl := GetSelection;
      HasSel := (Sl.Top >= VFixedRows) and (Sl.Right >= ColFrom) and (Sl.Left <= ColTo) and
        (Sl.Bottom >= RowFrom) and (Sl.Top <= RowTo);
    end;
    if Focused then
      SelSt := FStyles.Selection
    else
      SelSt := FStyles.SelectionInactive;
    // 1a. Element-Stile (Spalten, Zebra, Hover-Zeile, Filterzeile, Koepfe)
    if FPaint.UseColors and FPaint.CellStyles then
      StyleBackgrounds;
    // 1b. Gruppenfuss-Zeilen leicht abgesetzt
    HasGroups := FView.Grouped;
    if HasGroups then
      for V := RowFrom to RowTo do
        if DataRow(V) = GroupFooterMark then
        begin
          R := RawCellRect(ColFrom, V);
          SR := Rect(Clip.Left, R.Top, Clip.Right, R.Bottom);
          IntersectRect(SR, SR, Clip);
          if not IsRectEmpty(SR) and not (FPaint.UseColors and FStyles.Footer.HasFill(FPaint.Dark)) then
            ACanvas.FillRoundRect(SR, 0, PPGBlendColor(FPaint.Fill, FPaint.Header, 0.35), 255);
        end;
    // 1c. Bedingte Formate: Flaechen, Datenbalken, Symbole (nur Datenzellen)
    HasStyles := not FixedArea and ((FCondFormats.Count > 0) or Assigned(FOnGetCellStyle));
      if HasStyles then
    begin
      I := (ColTo - ColFrom + 1) * (RowTo - RowFrom + 1);
      SetLength(StyleRec, I);
      SetLength(StyleIcon, I);
      for V := RowFrom to RowTo do
      begin
        D := DataRow(V);
        for C := ColFrom to ColTo do
        begin
          Idx := CellIndex(C, V);
          StyleRec[Idx].Reset;
          StyleIcon[Idx] := False;
          DCol := FVisCols[C];
          if (D < FFixedRows) or (C < FFixedCols) or
            not (Assigned(FOnGetCellStyle) or FCondFormats.HasRulesFor(DCol)) then
            Continue;
          St := CellStyle(DCol, D, CellText(C, V, D, DCol));
          if St.IsDefault then
            Continue;
          // Flaechen erst sammeln (ein GDI-Block), Balken und Symbole danach
          if St.Fill <> clNone then
            AddFill(RawCellRect(C, V), St.Fill);
          StyleRec[Idx] := St;
          StyleIcon[Idx] := St.Icon >= 0;
        end;
      end;
      FlushFills;
      for V := RowFrom to RowTo do
        for C := ColFrom to ColTo do
        begin
          Idx := CellIndex(C, V);
          St := StyleRec[Idx];
          if (St.Bar < 0) and (St.Icon < 0) then
            Continue;
          R := RawCellRect(C, V);
          if St.Bar >= 0 then
          begin
            SR := R;
            InflateRect(SR, -PPGScale(2, PPI), -PPGScale(4, PPI));
            W := Round((SR.Right - SR.Left) * St.Bar);
            if UseRightToLeftAlignment then
              SR.Left := SR.Right - W
            else
              SR.Right := SR.Left + W;
            if W > 0 then
              ACanvas.FillRoundRect(SR, PPGScale(2, PPI), St.BarColor, 110);
          end;
          if St.Icon >= 0 then
          begin
            // Symbol: Dreieck hoch/runter, Raute fuer "gleich"
            K := (R.Top + R.Bottom) div 2;
            if UseRightToLeftAlignment then
              W := R.Right - Pad - IconW div 2
            else
              W := R.Left + Pad + IconW div 2;
            case St.Icon of
              2:
                begin
                  Pts[0] := Point(W, K - IconW div 3);
                  Pts[1] := Point(W + IconW div 3, K + IconW div 4);
                  Pts[2] := Point(W - IconW div 3, K + IconW div 4);
                  Pts[3] := Pts[0];
                end;
              0:
                begin
                  Pts[0] := Point(W, K + IconW div 3);
                  Pts[1] := Point(W + IconW div 3, K - IconW div 4);
                  Pts[2] := Point(W - IconW div 3, K - IconW div 4);
                  Pts[3] := Pts[0];
                end;
            else
              Pts[0] := Point(W, K - IconW div 4);
              Pts[1] := Point(W + IconW div 4, K);
              Pts[2] := Point(W, K + IconW div 4);
              Pts[3] := Point(W - IconW div 4, K);
            end;
            PPGFillPolygon(ACanvas, Pts, St.IconColor, 255);
          end;
        end;
    end;
    // 2. Auswahl als ein halbtransparentes Rechteck (nur Datenzellen)
    if HasSel then
    begin
      begin
        SR := RawCellRect(Sl.Left, Sl.Top);
        LR := RawCellRect(Sl.Right, Sl.Bottom);
        UnionRect(SR, SR, LR);
        // Verbundene Zellen in der Auswahl ganz markieren
        for I := 0 to NM - 1 do
          if (VM[I].C1 >= Sl.Left) and (VM[I].C0 <= Sl.Right) and
            (VM[I].R1 >= Sl.Top) and (VM[I].R0 <= Sl.Bottom) then
            UnionRect(SR, SR, VM[I].R);
        IntersectRect(SR, SR, Clip);
        if not IsRectEmpty(SR) then
        begin
          // Eigene Auswahlfarbe deckend, sonst halbtransparent (Akzent)
          if FPaint.UseColors and SelSt.HasFill(FPaint.Dark) then
            ACanvas.FillRoundRect(SR, 0, SelSt.FillFor(FPaint.Dark, FPaint.Accent), 255)
          else if Focused then
            ACanvas.FillRoundRect(SR, 0, FPaint.Accent, 46)
          else
            ACanvas.FillRoundRect(SR, 0, FPaint.Text, 22);
        end;
      end;
    end;
    // 2b. Flaeche der Fokuszelle (Styles.FocusedCell.Color)
    if not FixedArea and Focused and FPaint.UseColors and FStyles.FocusedCell.HasFill(FPaint.Dark) and
      (FFocusC >= ColFrom) and (FFocusC <= ColTo) and (FFocusV >= RowFrom) and (FFocusV <= RowTo) and
      (DataRow(FFocusV) >= FFixedRows) then
    begin
      SR := RawCellRect(FFocusC, FFocusV);
      IntersectRect(SR, SR, Clip);
      if not IsRectEmpty(SR) then
        ACanvas.FillRoundRect(SR, 0, FStyles.FocusedCell.FillFor(FPaint.Dark, FPaint.Fill), 255);
    end;
    // 3. Texte sammeln (Zellarten/Sortierpfeil merken)
    NX := 0;
    I := (ColTo - ColFrom + 1) * (RowTo - RowFrom + 1);
    SetLength(ExtraC, I);
    SetLength(ExtraV, I);
    SetLength(ExtraS, I);
    for V := RowFrom to RowTo do
    begin
      D := DataRow(V);
      for C := ColFrom to ColTo do
      begin
        TC := FPaint.Text;
        DCol := FVisCols[C]; // Datenspalte der Anzeige-Spalte
        if (NM > 0) and InMerge(C, V) then
          Continue // verbundene Zelle: Text der Ursprungszelle unten
        else if D = GroupRowMark then
          Continue // Gruppenkopf: eigene Zeile (Schritt 5b)
        else if D = GroupFooterMark then
        begin
          // Gruppenfuss: Summen der Gruppe, rechtsbuendig wie in der Summenzeile
          if FixedArea then
            Continue;
          S := CachedGroupFooterText(GroupOfFooterRow(V), DCol);
          if (S = '') or not FDefaultDrawing then
            Continue;
          TR := RawCellRect(C, V);
          InflateRect(TR, -Pad, 0);
          Col := ColumnOf(DCol);
          if FPaint.UseColors then
            TC := FStyles.Footer.TextFor(FPaint.Dark, FPaint.HeaderText)
          else
            TC := FPaint.Text;
          F := FFontCache.ForStyle(FStyles.Footer, FPaint.HeaderFont);
          if (Col <> nil) and (Col.Alignment <> taLeftJustify) then
            Al := Col.Alignment
          else
            Al := taRightJustify;
          AddCellText(TR, S, TC, Al, F);
          Continue;
        end
        else if D = FilterRowMark then
        begin
          S := GetFilter(DCol);
          if FPaint.UseColors then
            TC := FStyles.FilterRow.TextFor(FPaint.Dark, TC);
          if S = '' then
          begin
            S := PPGStr(@SPPGGridFilterHint);
            TC := FPaint.Hint;
          end;
        end
        else if D >= 0 then
          S := CellText(C, V, D, DCol)
        else
          S := '';
        HasKind := (D >= FFixedRows) and (C >= FFixedCols) and (KindArr[C - ColFrom] <> nil);
        if HasKind or ((D = 0) and (FFixedRows > 0) and (DCol = FSortCol)) then
        begin
          ExtraC[NX] := C;
          ExtraV[NX] := V;
          ExtraS[NX] := S;
          Inc(NX);
          if HasKind then
            Continue; // Zellart zeichnet selbst
        end;
        if (S = '') or not FDefaultDrawing then
          Continue;
        R := RawCellRect(C, V);
        TR := R;
        InflateRect(TR, -Pad, 0);
        if (D = 0) and (DCol = FSortCol) then
          if UseRightToLeftAlignment then
            Inc(TR.Left, PPGScale(TPPGCellPainter.SortArrowSpace, PPI))
          else
            Dec(TR.Right, PPGScale(TPPGCellPainter.SortArrowSpace, PPI));
        Col := ColumnOf(DCol);
        if Col <> nil then
          Al := Col.Alignment
        else
          Al := taLeftJustify;
        St.Reset;
        Extra := [];
        IsHead := (D >= 0) and ((D < FFixedRows) or (C < FFixedCols));
        if IsHead then
        begin
          // Kopfzellen: Styles.Header, Spaltenkopf: Column.TitleStyle
          TC := FPaint.HeaderText;
          F := FPaint.HeaderFont;
          if (D = 0) and (Col <> nil) then
          begin
            Al := Col.EffectiveTitleAlignment;
            F := FFontCache.ForStyle(Col.TitleStyle, FPaint.HeaderFont);
            if FPaint.UseColors then
              TC := Col.TitleStyle.TextFor(FPaint.Dark, TC);
          end;
        end
        else if D = FilterRowMark then
          F := FFontCache.ForStyle(FStyles.FilterRow, Font)
        else
        begin
          // Datenzelle: Spalte -> Zebra -> Hover -> Zellstil -> Auswahl -> Fokus
          if FPaint.UseColors then
          begin
            if Col <> nil then
              TC := Col.Style.TextFor(FPaint.Dark, TC);
            if FStyles.AlternateRow.HasFill(FPaint.Dark) and IsZebraRow(V) then
            begin
              TC := FStyles.AlternateRow.TextFor(FPaint.Dark, TC);
              Extra := Extra + FStyles.AlternateRow.FontStyle;
            end;
            if V = FHotV then
            begin
              TC := FStyles.HotRow.TextFor(FPaint.Dark, TC);
              Extra := Extra + FStyles.HotRow.FontStyle;
            end;
          end;
          if HasStyles then
          begin
            Idx := CellIndex(C, V);
            St := StyleRec[Idx];
            if St.TextColor <> clNone then
              TC := St.TextColor;
            if StyleIcon[Idx] then
              if UseRightToLeftAlignment then
                Dec(TR.Right, IconW + Pad div 2)
              else
                Inc(TR.Left, IconW + Pad div 2);
          end;
          if InSel(C, V) then
          begin
            if FPaint.UseColors then
              TC := SelSt.TextFor(FPaint.Dark, TC);
            Extra := Extra + SelSt.FontStyle;
          end;
          if (C = FFocusC) and (V = FFocusV) and Focused then
          begin
            if FPaint.UseColors then
              TC := FStyles.FocusedCell.TextFor(FPaint.Dark, TC);
            Extra := Extra + FStyles.FocusedCell.FontStyle;
          end;
          F := CellFont(Col, St, Extra);
        end;
        AddCellText(TR, S, TC, Al, F);
      end;
    end;
    // 3b. Verbundene Zellen: Text der Ursprungszelle ueber die ganze Flaeche
    if FDefaultDrawing then
      for I := 0 to NM - 1 do
      begin
        D := DataRow(VM[I].R0);
        if D < 0 then
          Continue;
        DCol := FVisCols[VM[I].C0];
        S := GetCellText(DCol, D);
        if S = '' then
          Continue;
        TR := VM[I].R;
        InflateRect(TR, -Pad, 0);
        Col := ColumnOf(DCol);
        St.Reset;
        TC := FPaint.Text;
        if (Col <> nil) and FPaint.UseColors then
          TC := Col.Style.TextFor(FPaint.Dark, TC);
        if Col <> nil then
          AddCellText(TR, S, TC, Col.Alignment, CellFont(Col, St, []))
        else
          AddCellText(TR, S, TC, taLeftJustify, Font);
      end;
    // 4. Gitterlinien und Texte in EINEM GDI-Block (GetHDC/Schrift nur einmal)
    if FixedArea then
    begin
      VLine := goFixedVertLine in FOptions;
      HLine := goFixedHorzLine in FOptions;
    end
    else
    begin
      VLine := goVertLine in FOptions;
      HLine := goHorzLine in FOptions;
    end;
    // Linienbreite (GridLineWidth, 0 = keine Linien wie TStringGrid)
    LW := PPGScale(FGridLineWidth, PPI);
    if (FGridLineWidth > 0) and (LW < 1) then
      LW := 1;
    if LW = 0 then
    begin
      VLine := False;
      HLine := False;
    end;
    DC := ACanvas.BeginGdi;
    try
      if FixedArea then
        LineBrush := CreateSolidBrush(ColorToRGB(FPaint.HeaderLine))
      else
        LineBrush := CreateSolidBrush(ColorToRGB(FPaint.Line));
      if LineBrush <> 0 then
      try
        if VLine then
          for C := ColFrom to ColTo do
          begin
            R := RawCellRect(C, RowFrom);
            if UseRightToLeftAlignment then
              W := R.Left
            else
              W := R.Right - 1;
            // Linien nicht durch verbundene Zellen
            SetLength(Cut, 0);
            for I := 0 to NM - 1 do
              if (C >= VM[I].C0) and (C < VM[I].C1) then
              begin
                SetLength(Cut, Length(Cut) + 1);
                Cut[High(Cut)] := Point(VM[I].R.Top, VM[I].R.Bottom - 1);
              end;
            LineSegments(Clip.Top, Clip.Bottom, True, W);
          end;
        if HLine then
          for V := RowFrom to RowTo do
          begin
            R := RawCellRect(ColFrom, V);
            SetLength(Cut, 0);
            for I := 0 to NM - 1 do
              if (V >= VM[I].R0) and (V < VM[I].R1) then
              begin
                SetLength(Cut, Length(Cut) + 1);
                Cut[High(Cut)] := Point(VM[I].R.Left, VM[I].R.Right - 1);
              end;
            LineSegments(Clip.Left, Clip.Right, False, R.Bottom);
          end;
      finally
        DeleteObject(LineBrush);
      end;
      FPainter.FlushTexts(DC, Font.Handle);
    finally
      ACanvas.EndGdi(DC); // stellt Schrift, Farbe und Modus wieder her
    end;
    // 5. Zellarten und Sortierpfeil (Preset-Renderer). Wie DrawCellExtras,
    // aber Zellart und Kontext je Spalte; Texte eingebauter Zellarten in
    // EINEM GDI-Block (Audit 8c #9)
    if NX > 0 then
    begin
      try
        for I := 0 to NX - 1 do
        begin
          C := ExtraC[I];
          V := ExtraV[I];
          DCol := FVisCols[C];
          D := DataRow(V);
          R := RawCellRect(C, V);
          K2 := KindArr[C - ColFrom];
          if (K2 <> nil) and (D >= FFixedRows) and (C >= FFixedCols) then
          begin
            Idx := C - ColFrom;
            if not HaveCtx[Idx] then
            begin
              KindCtxArr[Idx] := KindContext(DCol);
              KindCtxArr[Idx].Canvas := ACanvas;
              HaveCtx[Idx] := True;
            end;
            FPainter.CollectTexts := PPGCellKindIsBuiltIn(K2);
            K2.PaintCell(KindCtxArr[Idx], R, ExtraS[I]);
            FPainter.CollectTexts := False;
          end;
          if (D = 0) and (FFixedRows > 0) and (DCol = FSortCol) then
            FPainter.DrawSortArrow(ACanvas, R, FSortAscending, UseRightToLeftAlignment,
              PPGBlendColor(FPaint.HeaderText, FPaint.Header, 0.3), PPI);
        end;
      finally
        FPainter.CollectTexts := False;
      end;
      if FPainter.TextCount > 0 then
      begin
        DC := ACanvas.BeginGdi;
        try
          FPainter.FlushTexts(DC, Font.Handle);
        finally
          ACanvas.EndGdi(DC);
        end;
      end;
    end;
    // 5b. Gruppenkopf-Zeilen ueber die ganze Breite (Text nur im scrollbaren
    // Bereich, dort bleibt er beim waagerechten Scrollen stehen)
    if HasGroups then
      for V := RowFrom to RowTo do
        if DataRow(V) = GroupRowMark then
          PaintGroupRow(ACanvas, V, Clip, not FixedArea and (ColFrom >= FFixedCols) and
            (ColFrom < FirstRightCol));
    // 6. Fokuszelle und Owner-Draw
    if not FixedArea and FocusVisible and (FFocusV >= RowFrom) and (FFocusV <= RowTo) and
      (DataRow(FFocusV) = GroupRowMark) then
    begin
      // Gruppenzeile: Rahmen um die Zeile (nur im Hauptbereich)
      if (ColFrom >= FFixedCols) and (ColFrom < FirstRightCol) then
      begin
        LR := RawCellRect(ColFrom, FFocusV);
        LR := Rect(Clip.Left, LR.Top, Clip.Right, LR.Bottom);
        InflateRect(LR, -1, -1);
        ACanvas.FrameRoundRect(LR, PPGScale(2, PPI), PPGScale(2, PPI), FPaint.FocusFrame, 255);
      end;
    end
    else if not FixedArea and FocusVisible and (FFocusC >= ColFrom) and (FFocusC <= ColTo) and
      (FFocusV >= RowFrom) and (FFocusV <= RowTo) then
    begin
      LR := RawCellRect(FFocusC, FFocusV);
      // Ursprung einer Verbindung: Rahmen um die ganze Flaeche
      for I := 0 to NM - 1 do
        if (VM[I].C0 = FFocusC) and (VM[I].R0 = FFocusV) then
          LR := VM[I].R;
      InflateRect(LR, -1, -1);
      ACanvas.FrameRoundRect(LR, PPGScale(2, PPI), PPGScale(2, PPI), FPaint.FocusFrame, 255);
    end;
    if Assigned(FOnDrawCell) then
      for V := RowFrom to RowTo do
        for C := ColFrom to ColTo do
          DrawCell(ACanvas, C, V, RawCellRect(C, V));
  finally
    ACanvas.PopClip;
  end;
end;

procedure TPPGCustomGrid.PaintViewport(const ACanvas: IPPGCanvas; const View: TRect);
var
  FW, FH, C0, C1, R0, R1, FR, MidRight, X, PH, BH: Integer;
  CX: Integer;
  CY: Int64;
  GV: TRect;
  M, CR0, CR1: Integer;
  VC, R: TRect;

  function Mirror(const R: TRect): TRect;
  begin
    // Bereiche werden links->rechts berechnet und bei RTL gespiegelt
    if UseRightToLeftAlignment then
      Result := Rect(GV.Left + GV.Right - R.Right, R.Top, GV.Left + GV.Right - R.Left, R.Bottom)
    else
      Result := R;
  end;

  procedure PaintRegionIn(ColFrom, ColTo, RowFrom, RowTo: Integer; const AClip: TRect;
    FixedArea: Boolean);
  begin
    // Bereich ausserhalb des neu zu zeichnenden Teils: gar nicht anfassen
    if NeedsPaint(AClip, M) then
      PaintRegion(ACanvas, ColFrom, ColTo, RowFrom, RowTo, AClip, FixedArea);
  end;

begin
  EnsureGeometry;
  if (VColCount = 0) or (FLayout.Count = 0) then
    Exit;
  // Farben einmal pro Zeichnen (nicht je Zelle)
  GetGridColors(FPaint.Fill, FPaint.Text, FPaint.Header, FPaint.Line, FPaint.Accent);
  // Schriften bleiben ueber Zeichenvorgaenge (Audit 8c #10); neu bei anderer
  // DPI bzw. wenn sich zu viele angesammelt haben
  if (FFontCachePPI <> ScalePPI) or (FFontCache.Count > 64) then
  begin
    FFontCache.Clear;
    FFontCachePPI := ScalePPI;
  end;
  PrepareStyleColors;
  FPaint.Hint := PPGBlendColor(FPaint.HeaderText, FPaint.Header, 0.55);
  FPainter.Prepare(Renderer);
  PrepareKindContext(ACanvas);
  // Werte fuer RawCellRect/ColLeft einmal je Zeichnen (Audit 8c #8)
  FPaintGV := GridViewRect;
  FPaintMaxColScroll := MaxColScroll;
  FPaintFirstRight := FirstRightCol;
  FPaintCached := True;
  FPainter.Painting := True;
  try
    GV := View;
    PH := GroupPanelHeight;
    BH := BandHeight;
    Inc(GV.Top, PH + BH);
    Dec(GV.Bottom, FooterHeight);
    if GV.Top > GV.Bottom then
      GV.Top := GV.Bottom;
    FW := FixedWidth;
    FH := FixedHeight;
    FR := FirstRightCol;
    // Rechter Rand der scrollbaren Spalten (rechts fixierte stehen dahinter)
    if FR < VColCount then
      MidRight := ColLeft(FR)
    else
      MidRight := GV.Right - GV.Left;
    // Sichtbare scrollbare Spalten/Zeilen
    CX := ScrollX + FW;
    C0 := FFixedCols;
    while (C0 < FR - 1) and (FColX[C0 + 1] <= CX) do
      Inc(C0);
    C1 := C0;
    while (C1 < FR - 1) and (FColX[C1 + 1] < CX + MidRight - FW) do
      Inc(C1);
    CY := Int64(RowScrollY) + FH;
    if CY >= FLayout.TotalHeight64 then
      R0 := FLayout.Count
    else
      R0 := FLayout.RowAt(CY);
    if R0 < VFixedRows then
      R0 := VFixedRows;
    R1 := R0;
    while (R1 < FLayout.Count - 1) and
      (FLayout.RowTop(R1 + 1) < CY + (GV.Bottom - GV.Top) - FH) do
      Inc(R1);
    if R0 >= FLayout.Count then
      R1 := R0 - 1; // keine Datenzeilen sichtbar
    // Audit 8E: nur Zeilen im neu zu zeichnenden Bereich (Rand M fuer den
    // Fokusrahmen). Nicht bei verbundenen Zellen (Rahmen und Text haengen am
    // Ursprung, der ausserhalb liegen kann) und nicht beim Verlauf der festen
    // Spalte (er reicht ueber die ganze Hoehe des Bereichs).
    M := PPGScale(4, ScalePPI);
    VC := ViewportClip;
    CR0 := R0;
    CR1 := R1;
    if (R0 <= R1) and not MergesActive then
    begin
      while (CR0 < CR1) and (RawCellRect(0, CR0).Bottom <= VC.Top - M) do
        Inc(CR0);
      while (CR1 > CR0) and (RawCellRect(0, CR1).Top >= VC.Bottom + M) do
        Dec(CR1);
    end;
    // Bereiche: Daten, Kopfzeilen, Kopfspalten, rechts fixierte, Ecke
    // (ganz uebersprungen, wenn sie den Bereich nicht beruehren)
    PaintRegionIn(C0, C1, CR0, CR1,
      Mirror(Rect(GV.Left + FW, GV.Top + FH, GV.Left + MidRight, GV.Bottom)), False);
    PaintRegionIn(C0, C1, 0, VFixedRows - 1,
      Mirror(Rect(GV.Left + FW, GV.Top, GV.Left + MidRight, GV.Top + FH)), True);
    if FPaint.Gradient then
      PaintRegionIn(0, FFixedCols - 1, R0, R1,
        Mirror(Rect(GV.Left, GV.Top + FH, GV.Left + FW, GV.Bottom)), True)
    else
      PaintRegionIn(0, FFixedCols - 1, CR0, CR1,
        Mirror(Rect(GV.Left, GV.Top + FH, GV.Left + FW, GV.Bottom)), True);
    if FR < VColCount then
    begin
      PaintRegionIn(FR, VColCount - 1, CR0, CR1,
        Mirror(Rect(GV.Left + MidRight, GV.Top + FH, GV.Right, GV.Bottom)), False);
      PaintRegionIn(FR, VColCount - 1, 0, VFixedRows - 1,
        Mirror(Rect(GV.Left + MidRight, GV.Top, GV.Right, GV.Top + FH)), True);
    end;
    PaintRegionIn(0, FFixedCols - 1, 0, VFixedRows - 1,
      Mirror(Rect(GV.Left, GV.Top, GV.Left + FW, GV.Top + FH)), True);
    R := Rect(View.Left, View.Top + PH, View.Right, View.Top + PH + BH);
    if (BH > 0) and NeedsPaint(R, M) then
      PaintBands(ACanvas, R);
    R := Rect(View.Left, View.Top, View.Right, View.Top + PH);
    if (PH > 0) and NeedsPaint(R, M) then
      PaintGroupPanel(ACanvas, R);
    R := Rect(View.Left, GV.Bottom, View.Right, View.Bottom);
    if (GV.Bottom < View.Bottom) and NeedsPaint(R, M) then
      PaintFooter(ACanvas, R);
    // Einfuegemarke beim Verschieben einer Spalte
    if FColDragging and not FDropToGroup and (FColDropAt >= 0) and HandleAllocated and
      (GetCapture = Handle) then
    begin
      X := GV.Left + ColLeft(FColDropAt);
      if UseRightToLeftAlignment then
        X := GV.Left + GV.Right - X;
      ACanvas.FillRoundRect(Rect(X - PPGScale(1, ScalePPI), View.Top + PH,
        X + PPGScale(1, ScalePPI), GV.Top + FH), 0, FPaint.Accent, 255);
    end;
  finally
    FPaintCached := False;
    FPainter.Painting := False;
    FPainter.CollectTexts := False;
    FKindCtx.Canvas := nil; // Canvas gilt nur waehrend des Zeichnens
    FPaint.HeaderFont := nil;
  end;
end;

procedure TPPGCustomGrid.PaintBands(const ACanvas: IPPGCanvas; const View: TRect);
var
  L, Levels, RH, VC, First, B, Y0, Pad: Integer;
  R, TR, LR: TRect;
  DC: HDC;
  LineBrush: HBRUSH;

  function BandOf(AVCol: Integer; ALevel: Integer): Integer;
  var
    C: TPPGGridColumn;
  begin
    C := ColumnOf(FVisCols[AVCol]);
    if (C = nil) or (AVCol < FFixedCols) then
      Result := -1
    else
      Result := FBands.BandAtLevel(C.Band, ALevel);
  end;

  procedure EmitRun(AFirst, ALast, ABand: Integer);
  var
    X0, X1: Integer;
    Clip: TRect;
  begin
    X0 := View.Left + ColLeft(AFirst);
    X1 := View.Left + ColLeft(ALast) + FColX[ALast + 1] - FColX[ALast];
    R := Rect(X0, Y0, X1, Y0 + RH);
    // Scrollbare Baender nicht ueber die festen bzw. rechts fixierten Spalten
    Clip := View;
    if AFirst < FirstRightCol then
    begin
      Clip.Left := View.Left + FixedWidth;
      if FirstRightCol < VColCount then
        Clip.Right := View.Left + ColLeft(FirstRightCol);
    end;
    IntersectRect(R, R, Clip);
    if IsRectEmpty(R) then
      Exit;
    if UseRightToLeftAlignment then
      R := Rect(View.Left + View.Right - R.Right, R.Top, View.Left + View.Right - R.Left, R.Bottom);
    // Linien: rechts und unten
    if UseRightToLeftAlignment then
      LR := Rect(R.Left, R.Top, R.Left + 1, R.Bottom)
    else
      LR := Rect(R.Right - 1, R.Top, R.Right, R.Bottom);
    Winapi.Windows.FillRect(DC, LR, LineBrush);
    LR := Rect(R.Left, R.Bottom - 1, R.Right, R.Bottom);
    Winapi.Windows.FillRect(DC, LR, LineBrush);
    TR := R;
    InflateRect(TR, -Pad, 0);
    FPainter.AddText(TR, FBands[ABand].Caption, FPaint.HeaderText,
      DrawTextBiDiModeFlags(TPPGCellPainter.TextFlags(FBands[ABand].Alignment)));
  end;

begin
  Levels := FBands.LevelCount;
  if Levels = 0 then
    Exit;
  RH := (View.Bottom - View.Top) div Levels;
  Pad := PPGScale(CellPadX, ScalePPI);
  DC := ACanvas.BeginGdi;
  try
    TPPGCellPainter.FillGdi(DC, View, FPaint.Header);
    LineBrush := CreateSolidBrush(ColorToRGB(FPaint.HeaderLine));
    if LineBrush = 0 then
      Exit;
    try
      for L := 0 to Levels - 1 do
      begin
        Y0 := View.Top + L * RH;
        // Laeufe gleicher Baender in Anzeige-Reihenfolge (getrennt nach
        // scrollbaren und rechts fixierten Spalten)
        VC := FFixedCols;
        while VC < VColCount do
        begin
          B := BandOf(VC, L);
          First := VC;
          Inc(VC);
          while (VC < VColCount) and (VC <> FirstRightCol) and (BandOf(VC, L) = B) do
            Inc(VC);
          if B >= 0 then
            EmitRun(First, VC - 1, B);
        end;
      end;
    finally
      DeleteObject(LineBrush);
    end;
    FPainter.FlushTexts(DC, FPaint.HeaderFont.Handle);
  finally
    ACanvas.EndGdi(DC);
  end;
end;

procedure TPPGCustomGrid.SetBorderStyle(const Value: TBorderStyle);
begin
  if FBorderStyle <> Value then
  begin
    FBorderStyle := Value;
    UpdateScrollGeometry;
  end;
end;

function TPPGCustomGrid.FrameInset: Integer;
var
  S: TPPGSurfaceStyle;
begin
  if FBorderStyle = bsNone then
    Exit(0);
  S := EffectiveAppearance.Resolve(vsNormal, ScalePPI, False);
  Result := S.BorderWidth;
  if Result < 1 then
    Result := 1;
  // Abstand, damit eckige Zellen die Rundung des Rahmens nicht beruehren
  Inc(Result, (S.Rounding * 3 + 9) div 10);
end;

procedure TPPGCustomGrid.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  S: TPPGSurfaceStyle;
  CR: IPPGContainerRenderer;
  Fill, Text, Header, Line, Accent: TColor;
begin
  EnsureGeometry;
  GetGridColors(Fill, Text, Header, Line, Accent);
  if FBorderStyle = bsSingle then
  begin
    S := EffectiveAppearance.Resolve(vsNormal, ScalePPI, False);
    S.Color := Fill;
    S.ColorTo := Fill;
    S.ColorMirror := Fill;
    S.ColorMirrorTo := Fill;
    S.GlowAlpha := 0;
    if UseHighContrast then
      S.BorderColor := Tokens.Stroke;
    if S.BorderWidth < 1 then
      S.BorderWidth := 1;
    if not Supports(Renderer, IPPGContainerRenderer, CR) then
      Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
        IPPGContainerRenderer, CR);
    CR.DrawContainer(ACanvas, ClientR, S);
  end
  else
    ACanvas.FillRoundRect(ClientR, 0, Fill, 255);
  inherited DoPaint(ACanvas, ClientR);
end;

{ ---- Auswahl ---- }

function TPPGCustomGrid.GetSelection: TGridRect;
begin
  if goRowSelect in FOptions then
  begin
    Result.Left := FFixedCols;
    Result.Right := VColCount - 1;
  end
  else if goRangeSelect in FOptions then
  begin
    if FAnchorC < FFocusC then
    begin
      Result.Left := FAnchorC;
      Result.Right := FFocusC;
    end
    else
    begin
      Result.Left := FFocusC;
      Result.Right := FAnchorC;
    end;
  end
  else
  begin
    Result.Left := FFocusC;
    Result.Right := FFocusC;
  end;
  if (goRangeSelect in FOptions) or (goRowSelect in FOptions) then
  begin
    if FAnchorV < FFocusV then
    begin
      Result.Top := FAnchorV;
      Result.Bottom := FFocusV;
    end
    else
    begin
      Result.Top := FFocusV;
      Result.Bottom := FAnchorV;
    end;
    if not (goRangeSelect in FOptions) then
    begin
      Result.Top := FFocusV;
      Result.Bottom := FFocusV;
    end;
  end
  else
  begin
    Result.Top := FFocusV;
    Result.Bottom := FFocusV;
  end;
end;

procedure TPPGCustomGrid.SetSelection(const Value: TGridRect);
begin
  FAnchorC := EnsureRangeInt(Value.Left, FFixedCols, VColCount - 1);
  FAnchorV := EnsureRangeInt(Value.Top, VFixedRows, VRowCount - 1);
  FFocusC := EnsureRangeInt(Value.Right, FFixedCols, VColCount - 1);
  FFocusV := EnsureRangeInt(Value.Bottom, VFixedRows, VRowCount - 1);
  Invalidate;
end;

procedure TPPGCustomGrid.SelectAll;
begin
  if not (goRangeSelect in FOptions) then
    Exit;
  FAnchorC := FFixedCols;
  FAnchorV := VFixedRows;
  FFocusC := VColCount - 1;
  FFocusV := VRowCount - 1;
  Invalidate;
end;

function TPPGCustomGrid.SelectCell(ACol, ARow: Integer): Boolean;
begin
  Result := True;
  if Assigned(FOnSelectCell) then
    FOnSelectCell(Self, ACol, ARow, Result);
end;

function TPPGCustomGrid.MoveFocus(ACol, VRow: Integer; Extend, ByUser: Boolean): Boolean;
var
  D, M0, N0, M1, N1, OldV, SX, SY: Integer;
  ColChanged: Boolean;
  OldSel, NewSel: TGridRect;
begin
  Result := False;
  ACol := EnsureRangeInt(ACol, FFixedCols, VColCount - 1);
  VRow := EnsureRangeInt(VRow, VFixedRows, VRowCount - 1);
  if (ACol < FFixedCols) or (VRow < VFixedRows) then
    Exit;
  // Verbundene Zelle: Fokus auf den Ursprung
  if MergeAtCell(ACol, VRow, M0, N0, M1, N1) then
  begin
    ACol := M0;
    VRow := N0;
  end;
  D := DataRow(VRow);
  if ((ACol <> FFocusC) or (VRow <> FFocusV)) and (D >= 0) and not SelectCell(DataCol(ACol), D) then
    Exit;
  HideEditor(True);
  ColChanged := ACol <> FFocusC;
  if ColChanged then
    ColExit;
  OldSel := GetSelection;
  OldV := FFocusV;
  SX := ScrollX;
  SY := ScrollY;
  FFocusC := ACol;
  FFocusV := VRow;
  if not Extend or not (goRangeSelect in FOptions) then
  begin
    FAnchorC := ACol;
    FAnchorV := VRow;
  end;
  MakeCellVisible(ACol, VRow);
  // Audit 8b: ohne Scrollen und ohne Bereich ueber mehrere Zeilen nur die
  // alte und die neue Zeile neu zeichnen (Fokusrahmen, Auswahl, Fokuszelle)
  NewSel := GetSelection;
  if (SX = ScrollX) and (SY = ScrollY) and (OldSel.Top = OldSel.Bottom) and
    (NewSel.Top = NewSel.Bottom) and not Assigned(FOnDrawCell) and
    not Assigned(FOnGetCellStyle) and not MergesActive then
  begin
    InvalidateViewRow(OldV);
    InvalidateViewRow(VRow);
  end
  else
    Invalidate;
  if HandleAllocated and Focused and (VRow <> FLastFocusRow) then
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, VRow + 1);
  FLastFocusRow := VRow;
  if ColChanged then
    ColEnter;
  if ByUser then
    Click;
  Result := True;
end;

procedure TPPGCustomGrid.ColEnter;
begin
  if Assigned(FOnColEnter) then
    FOnColEnter(Self);
end;

procedure TPPGCustomGrid.ColExit;
begin
  if Assigned(FOnColExit) then
    FOnColExit(Self);
end;

procedure TPPGCustomGrid.EditButtonClick;
begin
  if Assigned(FOnEditButtonClick) then
    FOnEditButtonClick(Self);
end;

procedure TPPGCustomGrid.EditorEllipsisClick(Sender: TObject);
begin
  EditButtonClick;
end;

function TPPGCustomGrid.GetRow: Integer;
begin
  Result := DataRow(FFocusV);
  if Result < 0 then
    Result := -1; // Gruppenzeile
end;

procedure TPPGCustomGrid.SetRow(const Value: Integer);
var
  V: Integer;
begin
  V := VisualRow(Value);
  if V >= VFixedRows then
    MoveFocus(FFocusC, V, False, False);
end;

function TPPGCustomGrid.GetCol: Integer;
begin
  Result := DataCol(FFocusC);
end;

procedure TPPGCustomGrid.SetCol(const Value: Integer);
var
  V: Integer;
begin
  V := VisualCol(Value);
  if V >= FFixedCols then
    MoveFocus(V, FFocusV, False, False);
end;

procedure TPPGCustomGrid.CMEnter(var Message: TCMEnter);
begin
  inherited;
  Invalidate;
end;

procedure TPPGCustomGrid.CMExit(var Message: TCMExit);
begin
  inherited;
  // Fokus ging nicht an den eigenen Editor: Editor uebernehmen
  if (FEditor <> nil) and not FEditor.Focused and not FEditor.ContainsControl(
    FindControl(GetFocus)) then
    HideEditor(True);
  Invalidate;
end;

{ ---- Maus ---- }

function TPPGCustomGrid.SizingColAt(X, Y: Integer): Integer;
var
  C, V, I, Zone: Integer;
  R: TRect;
begin
  Result := -1;
  if not (goColSizing in FOptions) or not MouseCoord(X, Y, C, V) then
    Exit;
  if V >= FFixedRows then
    Exit; // nur in der Kopfzeile
  Zone := PPGScale(SizeZone, ScalePPI);
  for I := C - 1 to C do
    if I >= 0 then
    begin
      R := CellRect(I, V);
      if UseRightToLeftAlignment then
      begin
        if Abs(X - R.Left) <= Zone then
          Exit(I);
      end
      else if Abs(X - R.Right) <= Zone then
        Exit(I);
    end;
end;

procedure TPPGCustomGrid.WMSetCursor(var Message: TWMSetCursor);
var
  P: TPoint;
  C, V: Integer;
  K: IPPGCellKind;
begin
  if (Message.HitTest = HTCLIENT) and not (csDesigning in ComponentState) then
  begin
    P := ScreenToClient(Mouse.CursorPos);
    if (FSizingCol >= 0) or (SizingColAt(P.X, P.Y) >= 0) then
    begin
      Winapi.Windows.SetCursor(Screen.Cursors[crHSplit]);
      Message.Result := 1;
      Exit;
    end;
    if MouseCoord(P.X, P.Y, C, V) and (C >= FFixedCols) and (DataRow(V) >= FFixedRows) then
    begin
      K := KindOf(DataCol(C));
      if (K <> nil) and (K.CellCursor(KindContext(DataCol(C)), CellRect(C, V), P,
        GetCellText(DataCol(C), DataRow(V))) = crHandPoint) then
      begin
        Winapi.Windows.SetCursor(Screen.Cursors[crHandPoint]);
        Message.Result := 1;
        Exit;
      end;
    end;
  end;
  inherited;
end;

procedure TPPGCustomGrid.ContentMouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  C, V, S: Integer;
  R: TRect;
  K: IPPGCellKind;
  Act: TPPGCellAction;
  NewText: string;
begin
  if (Button = mbLeft) and CanFocus and not Focused and HandleAllocated and
    IsWindowVisible(Handle) and IsWindowEnabled(Handle) and
    not (csDesigning in ComponentState) then
    SetFocus;
  FColDragging := False;
  FColDropAt := -1;
  if Button <> mbLeft then
    Exit;
  // Gruppenleiste: Chip anklicken (Kreuz = Gruppierung aufheben)
  if FShowGroupPanel and PtInRect(GroupPanelRect, Point(X, Y)) then
  begin
    GroupPanelClick(X, Y);
    Exit;
  end;
  S := SizingColAt(X, Y);
  if S >= 0 then
  begin
    HideEditor(True);
    // Doppelklick auf die Kante: Breite an den Inhalt anpassen
    if ssDouble in Shift then
    begin
      AutoSizeColumn(DataCol(S));
      Exit;
    end;
    FSizingCol := S;
    FSizingStartX := X;
    FSizingStartW := ColPixelWidth(DataCol(S));
    Exit;
  end;
  if not MouseCoord(X, Y, C, V) then
    Exit;
  if DataRow(V) = FilterRowMark then
  begin
    // Filterzeile: Klick bearbeitet den Filter der Spalte
    HideEditor(True);
    FFocusC := EnsureRangeInt(C, FFixedCols, VColCount - 1);
    FEditC := FFocusC;
    FEditV := V;
    ShowEditor;
    Exit;
  end;
  if (V < FFixedRows) or (C < FFixedCols) then
  begin
    FHeaderDown := C;
    FHeaderDownPos := Point(X, Y);
    FColDragging := False;
    if V >= FFixedRows then
      FHeaderDown := -1;
    if Assigned(FOnFixedCellClick) then
      FOnFixedCellClick(Self, DataCol(C), DataRow(V));
    Exit;
  end;
  // Gruppenzeile: Pfeil klappt (Einfachklick), sonst Doppelklick
  if DataRow(V) = GroupRowMark then
  begin
    MoveFocus(C, V, False, True);
    S := GroupOfRow(V);
    if S >= 0 then
    begin
      if PtInRect(GroupExpanderRect(V), Point(X, Y)) then
      begin
        if not (ssDouble in Shift) then
          ExpandGroup(S, not FView.Group.Groups[S].Expanded);
      end
      else if ssDouble in Shift then
        ExpandGroup(S, not FView.Group.Groups[S].Expanded);
    end;
    Exit;
  end;
  if DataRow(V) = GroupFooterMark then
  begin
    MoveFocus(C, V, False, True);
    Exit;
  end;
  // Zellart: Klick bedient die Zelle (Kaestchen, Bewertung, Link, Button)
  K := KindOf(DataCol(C));
  if (K <> nil) and (DataRow(V) >= FFixedRows) and (C >= FFixedCols) and
    (Shift * [ssShift, ssCtrl] = []) then
  begin
    MoveFocus(C, V, False, True);
    R := CellRect(C, V);
    Act := K.CellClick(KindContext(DataCol(C)), R, Point(X, Y),
      GetCellText(DataCol(C), DataRow(V)), NewText);
    if Act <> caNone then
      DoCellAction(Act, DataCol(C), V, NewText);
    Exit;
  end;
  MoveFocus(C, V, ssShift in Shift, True);
  FMouseSel := goRangeSelect in FOptions;
end;

procedure TPPGCustomGrid.ContentMouseMove(Shift: TShiftState; X, Y: Integer);
var
  C, V, W: Integer;
  ToGroup: Boolean;
begin
  // Zeile unter der Maus (nur Datenzeilen) fuer Styles.HotRow
  if MouseCoord(X, Y, C, V) and (DataRow(V) >= FFixedRows) then
    SetHotRow(V)
  else
    SetHotRow(-1);
  if FSizingCol >= 0 then
  begin
    if UseRightToLeftAlignment then
      W := FSizingStartW - (X - FSizingStartX)
    else
      W := FSizingStartW + (X - FSizingStartX);
    W := MulDiv(W, 96, ScalePPI); // logisch speichern
    if W < MinColWidth then
      W := MinColWidth;
    if W <> GetColWidths(DataCol(FSizingCol)) then
      ColWidths[DataCol(FSizingCol)] := W;
    Exit;
  end;
  // Kopf ziehen: verschiebt die Spalte (goColMoving) bzw. gruppiert (Leiste)
  if (FHeaderDown >= 0) and (ssLeft in Shift) and CanDragColumn(FHeaderDown) then
  begin
    if not FColDragging and PPGDragExceeded(FHeaderDownPos, Point(X, Y)) then
      FColDragging := True;
    if FColDragging then
    begin
      ToGroup := FShowGroupPanel and CanGroup and PtInRect(GroupPanelRect, Point(X, Y));
      if ToGroup then
        W := -1
      else if (goColMoving in FOptions) and CanMoveColumn(FHeaderDown) then
        W := ColumnDropAt(X)
      else
        W := -1;
      if (W <> FColDropAt) or (ToGroup <> FDropToGroup) then
      begin
        FColDropAt := W;
        FDropToGroup := ToGroup;
        Invalidate;
      end;
      if not ToGroup then
        AutoScrollAt(X, Y);
    end;
    Exit;
  end;
  if FMouseSel and (ssLeft in Shift) then
  begin
    if MouseCoord(X, Y, C, V) and ((C <> FFocusC) or (V <> FFocusV)) then
      MoveFocus(C, V, True, False);
    AutoScrollAt(X, Y);
  end;
end;

procedure TPPGCustomGrid.DoAutoScroll(const P: TPoint);
var
  C, V: Integer;
  Q: TPoint;
  VR: TRect;
begin
  inherited DoAutoScroll(P);
  if not FMouseSel then
    Exit;
  VR := ViewRect;
  Q := Point(EnsureRangeInt(P.X, VR.Left, VR.Right - 1), EnsureRangeInt(P.Y, VR.Top, VR.Bottom - 1));
  if MouseCoord(Q.X, Q.Y, C, V) and ((C <> FFocusC) or (V <> FFocusV)) then
    MoveFocus(C, V, True, False);
end;

procedure TPPGCustomGrid.ContentMouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  C, V: Integer;
begin
  StopAutoScroll;
  FMouseSel := False;
  if FSizingCol >= 0 then
  begin
    FSizingCol := -1;
    Exit;
  end;
  if FColDragging then
  begin
    // Einfuegeposition -> Zielposition der Spalte
    C := FColDropAt;
    if C > FHeaderDown then
      Dec(C);
    FColDragging := False;
    FColDropAt := -1;
    V := FHeaderDown;
    FHeaderDown := -1;
    Invalidate;
    if FDropToGroup then
    begin
      // In die Gruppenleiste gezogen: nach der Spalte gruppieren
      FDropToGroup := False;
      if Button = mbLeft then
        AddGroupColumn(DataCol(V));
      Exit;
    end;
    if (C >= 0) and (C <> V) and (Button = mbLeft) then
      MoveColumn(V, C);
    Exit;
  end;
  // Klick (ohne Ziehen) auf den Spaltenkopf sortiert
  if (FHeaderDown >= 0) and MouseCoord(X, Y, C, V) and (C = FHeaderDown) and (V < FFixedRows) then
    HeaderClicked(DataCol(C), V);
  FHeaderDown := -1;
end;

procedure TPPGCustomGrid.HeaderClicked(ACol, VRow: Integer);
var
  Col: TPPGGridColumn;
begin
  if not FSortOnHeaderClick or (ACol < FFixedCols) or (VRow <> 0) then
    Exit;
  Col := ColumnOf(ACol);
  if (Col <> nil) and not Col.Sortable then
    Exit;
  // Erster Klick aufsteigend, zweiter absteigend, dritter wieder unsortiert
  if FSortCol <> ACol then
    SortBy(ACol, True)
  else if FSortAscending then
    SortBy(ACol, False)
  else
    SortBy(-1);
end;

procedure TPPGCustomGrid.WMCaptureChanged(var Message: TMessage);
begin
  inherited;
  if HWND(Message.LParam) <> Handle then
  begin
    FSizingCol := -1;
    FMouseSel := False;
    // Spalte ziehen: VCL gibt die Maus VOR MouseUp frei - der Zustand bleibt
    // fuer ContentMouseUp; die Marke zeichnet nur, solange die Maus gefangen ist
    if FColDragging then
      Invalidate;
  end;
end;

procedure TPPGCustomGrid.DblClick;
var
  P: TPoint;
begin
  inherited DblClick;
  // Doppelklick auf eine Kopf-Kante passt die Breite an (ContentMouseDown)
  P := ScreenToClient(Mouse.CursorPos);
  if SizingColAt(P.X, P.Y) >= 0 then
    Exit;
  if CanEditCell(DataCol(FFocusC), FFocusV) and
    (CellEditorKind(DataCol(FFocusC), DataRow(FFocusV)) <> gekCheck) then
    ShowEditor;
end;

procedure TPPGCustomGrid.ToggleCheck(ACol, VRow: Integer);
var
  D: Integer;
  S: string;
begin
  D := DataRow(VRow);
  if (D < FFixedRows) or not CanEditCell(ACol, VRow) then
    Exit;
  S := GetCellText(ACol, D);
  if TPPGCellPainter.IsCheckedText(S) then
    SetCellByUser(ACol, D, '0')
  else
    SetCellByUser(ACol, D, '1');
end;

{ ---- Tastatur ---- }

procedure TPPGCustomGrid.KeyDown(var Key: Word; Shift: TShiftState);
var
  Scroll: Boolean;
begin
  // Audit 7c #1: OnKeyDown zuerst (inherited), dann die eigene Navigation,
  // erst danach das Scrollen per Tastatur der Basis.
  Scroll := KeyboardScrolling;
  KeyboardScrolling := False;
  try
    inherited KeyDown(Key, Shift);
  finally
    KeyboardScrolling := Scroll;
  end;
  // Das Grid ist keine Schaltflaeche: Leertaste loest kein Click aus
  if KeyPressed then
    SetKeyPressed(False);
  if Key = 0 then
    Exit;
  NavigateKey(Key, Shift);
  if (Key <> 0) and KeyboardScrolling and ScrollKey(Key, Shift) then
    Key := 0;
end;

procedure TPPGCustomGrid.NavigateKey(var Key: Word; Shift: TShiftState);
var
  C, V, Page, PageRows, M0, N0, M1, N1: Integer;
  Ext: Boolean;
  VR: TRect;
begin
  // Gruppenkopf: Pfeil links/rechts klappt (bei RTL gespiegelt), Enter/Leertaste
  // schalten um, links auf zugeklappter Gruppe springt zur Elterngruppe
  C := GroupOfRow(FFocusV);
  if (C >= 0) and (Shift * [ssCtrl, ssAlt] = []) then
  begin
    V := -1;
    case Key of
      VK_LEFT, VK_RIGHT, VK_ADD, VK_SUBTRACT:
        begin
          Ext := (Key = VK_ADD) or ((Key = VK_RIGHT) <> UseRightToLeftAlignment);
          if Key = VK_SUBTRACT then
            Ext := False;
          if Ext <> FView.Group.Groups[C].Expanded then
            ExpandGroup(C, Ext)
          else if not Ext and (FView.Group.Groups[C].Parent >= 0) then
            V := GroupRow(FView.Group.Groups[C].Parent)
          else if Ext and (Key <> VK_ADD) then
            V := FFocusV + 1;
          Key := 0;
        end;
      VK_RETURN, VK_SPACE, VK_F2:
        begin
          ExpandGroup(C, not FView.Group.Groups[C].Expanded);
          Key := 0;
        end;
    end;
    if V >= 0 then
      MoveFocus(FFocusC, V, False, True);
    if Key = 0 then
      Exit;
  end;
  C := FFocusC;
  V := FFocusV;
  Ext := ssShift in Shift;
  VR := GridViewRect;
  PageRows := ((VR.Bottom - VR.Top) - FixedHeight) div PPGScale(FDefaultRowHeight, ScalePPI);
  if PageRows < 1 then
    PageRows := 1;
  Page := PageRows;
  case Key of
    VK_UP: Dec(V);
    VK_DOWN: Inc(V);
    VK_LEFT:
      if UseRightToLeftAlignment then
        Inc(C)
      else
        Dec(C);
    VK_RIGHT:
      if UseRightToLeftAlignment then
        Dec(C)
      else
        Inc(C);
    VK_PRIOR: Dec(V, Page);
    VK_NEXT: Inc(V, Page);
    VK_HOME:
      if ssCtrl in Shift then
      begin
        C := FFixedCols;
        V := VFixedRows;
      end
      else
        C := FFixedCols;
    VK_END:
      if ssCtrl in Shift then
      begin
        C := VColCount - 1;
        V := VRowCount - 1;
      end
      else
        C := VColCount - 1;
    VK_TAB:
      if goTabs in FOptions then
      begin
        if ssShift in Shift then
          Dec(C)
        else
          Inc(C);
        Ext := False;
      end
      else
        Exit;
    VK_F2, VK_RETURN:
      begin
        if (Key = VK_RETURN) and KindKey(Key) then
        begin
          Key := 0;
          Exit;
        end;
        if CanEditCell(DataCol(FFocusC), FFocusV) then
        begin
          if CellEditorKind(DataCol(FFocusC), DataRow(FFocusV)) = gekCheck then
            ToggleCheck(DataCol(FFocusC), FFocusV)
          else
            ShowEditor;
        end;
        Key := 0;
        Exit;
      end;
    VK_SPACE:
      begin
        if KindKey(Key) then
          Key := 0;
        Exit;
      end;
    Ord('C'):
      if ssCtrl in Shift then
      begin
        CopyToClipboard;
        Key := 0;
        Exit;
      end
      else
        Exit;
    VK_INSERT:
      begin
        // Strg+Einfg kopiert, Umschalt+Einfg fuegt ein (wie Windows-Edits)
        if ssCtrl in Shift then
          CopyToClipboard
        else if ssShift in Shift then
          PasteFromClipboard
        else
          Exit;
        Key := 0;
        Exit;
      end;
    VK_DELETE:
      begin
        // Entf leert die Auswahl, Umschalt+Entf schneidet aus (Audit 7c #5)
        if Shift = [] then
          ClearSelection
        else if Shift = [ssShift] then
          CutToClipboard
        else
          Exit;
        Key := 0;
        Exit;
      end;
    Ord('X'):
      if ssCtrl in Shift then
      begin
        CutToClipboard;
        Key := 0;
        Exit;
      end
      else
        Exit;
    Ord('V'):
      if ssCtrl in Shift then
      begin
        PasteFromClipboard;
        Key := 0;
        Exit;
      end
      else
        Exit;
    Ord('A'):
      if ssCtrl in Shift then
      begin
        SelectAll;
        Key := 0;
        Exit;
      end
      else
        Exit;
  else
    Exit;
  end;
  if MergeAtCell(FFocusC, FFocusV, M0, N0, M1, N1) then
  begin
    if C > FFocusC then
      C := M1 + (C - FFocusC);
    if V > FFocusV then
      V := N1 + (V - FFocusV);
  end;
  MoveFocus(C, V, Ext, True);
  Key := 0;
end;

function TPPGCustomGrid.KindKey(Key: Word; CharKey: Boolean): Boolean;
var
  K: IPPGCellKind;
  Act: TPPGCellAction;
  NewText: string;
  D: Integer;
begin
  // Taste an die Zellart der Fokuszelle (Leertaste, Enter, Ziffern)
  Result := False;
  D := DataRow(FFocusV);
  if (D < FFixedRows) or (FFocusC < FFixedCols) or EditorMode then
    Exit;
  K := KindOf(DataCol(FFocusC));
  if K = nil then
    Exit;
  Act := K.CellKey(KindContext(DataCol(FFocusC)), Key, GetCellText(DataCol(FFocusC), D), NewText);
  if Act = caNone then
    Exit;
  DoCellAction(Act, DataCol(FFocusC), FFocusV, NewText);
  Result := True;
end;

procedure TPPGCustomGrid.KeyPress(var Key: Char);
var
  K: Char;
begin
  inherited KeyPress(Key);
  // Zeichen fuer Zellarten (z.B. Ziffer = Bewertung); Leertaste kam schon als Taste
  if (Key > ' ') and KindKey(Ord(UpCase(Key)), True) then
  begin
    Key := #0;
    Exit;
  end;
  // Tippen startet den Editor mit dem Zeichen (wie Excel/TStringGrid)
  if (Key >= ' ') and CanEditCell(DataCol(FFocusC), FFocusV) and
    (CellEditorKind(DataCol(FFocusC), DataRow(FFocusV)) = gekText) then
  begin
    K := Key;
    Key := #0;
    ShowEditor;
    if EditorMode then
      PPGGridEditorTypeChar(FEditor, K);
  end;
end;

{ ---- Editor ---- }

function TPPGCustomGrid.CanEditCell(ACol, VRow: Integer): Boolean;
var
  D: Integer;
  C: TPPGGridColumn;
begin
  Result := False;
  D := DataRow(VRow);
  if D = FilterRowMark then
    Exit(FShowFilterRow);
  if not (goEditing in FOptions) or (D < FFixedRows) or (ACol < FFixedCols) or
    (ACol >= FColCount) then
    Exit;
  C := ColumnOf(ACol);
  Result := (C = nil) or (not C.ReadOnly and (C.EditorKind <> gekNone));
end;

function TPPGCustomGrid.GetEditorMode: Boolean;
begin
  Result := (FEditor <> nil) and FEditor.Visible;
end;

procedure TPPGCustomGrid.SetEditorMode(const Value: Boolean);
begin
  if Value then
    ShowEditor
  else
    HideEditor(True);
end;

procedure TPPGCustomGrid.ShowEditor;
var
  Kind: TPPGGridEditorKind;
  D, V, M0, N0, M1, N1: Integer;
  R: TRect;
  S: string;
  Col: TPPGGridColumn;
begin
  if (csDesigning in ComponentState) or not HandleAllocated then
    Exit;
  if FEditV < 0 then
  begin
    FEditC := FFocusC;
    FEditV := FFocusV;
  end;
  V := FEditV;
  D := DataRow(V);
  if not CanEditCell(DataCol(FEditC), V) then
  begin
    FEditC := -1;
    FEditV := -1;
    Exit;
  end;
  if D = FilterRowMark then
  begin
    Kind := gekText;
    S := GetFilter(DataCol(FEditC));
  end
  else
  begin
    Kind := CellEditorKind(DataCol(FEditC), D);
    if Kind in [gekCheck, gekNone] then
    begin
      FEditC := -1;
      FEditV := -1;
      Exit;
    end;
    S := GetEditText(DataCol(FEditC), D);
  end;
  MakeCellVisible(FEditC, V);
  R := CellRect(FEditC, V);
  if MergeAtCell(FEditC, V, M0, N0, M1, N1) and (M0 = FEditC) and (N0 = V) then
    IntersectRect(R, RangeRect(M0, N0, M1, N1), GridViewRect);
  if IsRectEmpty(R) then
    Exit;
  // Editor passender Art (wiederverwendet, solange die Art gleich bleibt)
  if (FEditor <> nil) and (FEditKind <> Kind) then
  begin
    FEditor.Visible := False;
    FreeAndNil(FEditor);
  end;
  Col := ColumnOf(DataCol(FEditC));
  if FEditor = nil then
  begin
    FEditor := PPGCreateGridEditor(Kind, Self, EditorKeyDown, EditorExit);
    FEditKind := Kind;
  end;
  TCtrlAccess(FEditor).Font := Font;
  FEditor.BoundsRect := R;
  // Text setzen ist keine Anwender-Aenderung: OnChange erst danach
  if FEditor is TPPGCustomField then
    TGridEditorFieldAccess(FEditor).OnChange := nil;
  PPGGridEditorBegin(FEditor, S, Col);
  if FEditor is TPPGGridEdit then
    TPPGGridEdit(FEditor).OnEllipsisClick := EditorEllipsisClick;
  if FEditor is TPPGCustomField then
    TGridEditorFieldAccess(FEditor).OnChange := EditorChange;
  FEditCanceled := False;
  FEditor.Visible := True;
  if FEditor.CanFocus then
    FEditor.SetFocus;
  EditorOpened(DataCol(FEditC), D);
end;

procedure TPPGCustomGrid.EditorOpened(ACol, ARow: Integer);
begin
  // Erweiterungspunkt (DB-Grid merkt sich den Datensatz)
end;

procedure TPPGCustomGrid.EditorEdited;
begin
  // Erweiterungspunkt (DB-Grid: Datensatz in Bearbeitung)
end;

procedure TPPGCustomGrid.EditorChange(Sender: TObject);
begin
  if (FEditor <> nil) and FEditor.Visible and (FEditV >= 0) and
    (DataRow(FEditV) <> FilterRowMark) then
    EditorEdited;
end;

procedure TPPGCustomGrid.EndEditorForRebuild;
begin
  // FEditV < 0 bei sichtbarem Editor: HideEditor schreibt gerade selbst
  if (FEditor = nil) or not FEditor.Visible or (FEditV < 0) then
    Exit;
  HideEditor(True);
  if (FEditor <> nil) and FEditor.Visible and (FEditV >= 0) then
    HideEditor(False);
end;

function TPPGCustomGrid.EditorText: string;
begin
  if FEditor = nil then
    Result := ''
  else
    Result := PPGGridEditorText(FEditor);
end;

procedure TPPGCustomGrid.HideEditor(Accept: Boolean);
var
  C, V, D, EC: Integer;
  S: string;
  Ok, HadFocus: Boolean;
begin
  if (FEditor = nil) or not FEditor.Visible or (FEditV < 0) then
  begin
    FEditC := -1;
    FEditV := -1;
    Exit;
  end;
  EC := FEditC;
  C := DataCol(EC);
  V := FEditV;
  D := DataRow(V);
  S := EditorText;
  if Accept and (D <> FilterRowMark) and Assigned(FOnValidateCell) then
  begin
    Ok := True;
    FOnValidateCell(Self, C, D, S, Ok);
    if not Ok then
      Exit; // ungueltig: Editor bleibt offen
  end;
  // Zustand vor den Ereignissen zuruecksetzen (OnExit ruft erneut)
  FEditC := -1;
  FEditV := -1;
  if Accept then
  begin
    // Erst schreiben, dann ausblenden: Lehnt das Schreiben ab (z. B. DB-Feld
    // mit ungueltigem Text), bleibt der Editor mit der Eingabe offen.
    try
      if D = FilterRowMark then
      begin
        if (C >= 0) and (C < FColCount) and (FFilters[C] <> S) then
        begin
          FFilters[C] := S;
          RebuildMap;
        end;
      end
      else if (D >= FFixedRows) and (GetCellText(C, D) <> S) then
        SetCellByUser(C, D, S);
    except
      if (FEditor <> nil) and FEditor.Visible then
      begin
        FEditC := EC;
        FEditV := V;
      end;
      raise;
    end;
  end;
  if (FEditor = nil) or not FEditor.Visible then
    Exit;
  HadFocus := FEditor.Focused or FEditor.ContainsControl(FindControl(GetFocus));
  FEditor.Visible := False;
  if HadFocus and CanFocus and HandleAllocated and IsWindowVisible(Handle) then
    SetFocus;
end;

procedure TPPGCustomGrid.EditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      begin
        // Strg+Enter: "..."-Knopf der Spalte (wie TDBGrid)
        if (ssCtrl in Shift) and (Sender is TPPGGridEdit) and TPPGGridEdit(Sender).Ellipsis then
          EditButtonClick
        else
          HideEditor(True);
        Key := 0;
      end;
    VK_ESCAPE:
      begin
        HideEditor(False);
        Key := 0;
      end;
    VK_TAB:
      begin
        HideEditor(True);
        if ssShift in Shift then
          MoveFocus(FFocusC - 1, FFocusV, False, True)
        else
          MoveFocus(FFocusC + 1, FFocusV, False, True);
        Key := 0;
      end;
    VK_UP, VK_DOWN:
      if PPGGridEditorArrowsLeave(Sender) then
      begin
        // Text-Editor: Pfeil hoch/runter uebernimmt und wechselt die Zeile
        HideEditor(True);
        if Key = VK_UP then
          MoveFocus(FFocusC, FFocusV - 1, False, True)
        else
          MoveFocus(FFocusC, FFocusV + 1, False, True);
        Key := 0;
      end;
  end;
end;

procedure TPPGCustomGrid.EditorExit(Sender: TObject);
begin
  // Fokus woanders hin: uebernehmen (nicht, wenn er ins Grid zurueckgeht -
  // das hat HideEditor selbst ausgeloest)
  if FEditV >= 0 then
    HideEditor(True);
end;

{ ---- Zwischenablage und CSV ---- }

function TPPGCustomGrid.SelectionAsText: string;
var
  Sl: TGridRect;
  C, V, D: Integer;
  SB: TStringBuilder;
begin
  Sl := GetSelection;
  SB := TStringBuilder.Create;
  try
    for V := Sl.Top to Sl.Bottom do
    begin
      D := DataRow(V);
      if D < 0 then
        Continue;
      for C := Sl.Left to Sl.Right do
      begin
        if C > Sl.Left then
          SB.Append(#9);
        SB.Append(StringReplace(StringReplace(GetCellText(DataCol(C), D), #9, ' ', [rfReplaceAll]),
          #13#10, ' ', [rfReplaceAll]));
      end;
      SB.Append(#13#10);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TPPGCustomGrid.CopyToClipboard;
begin
  Clipboard.AsText := SelectionAsText;
end;

procedure TPPGCustomGrid.PasteFromClipboard;
begin
  if Clipboard.HasFormat(CF_TEXT) then
    PasteText(Clipboard.AsText);
end;

procedure TPPGCustomGrid.ClearSelection;
var
  Sl: TGridRect;
  C, V, D, DC: Integer;
begin
  // Nur editierbare Zellen (CanEditCell: goEditing, ReadOnly, DB-Grid ReadOnly),
  // je Zelle ueber SetCellByUser wie beim Einfuegen (OnSetEditText)
  HideEditor(True);
  Sl := GetSelection;
  for V := Sl.Top to Sl.Bottom do
  begin
    if V >= VRowCount then
      Break;
    D := DataRow(V);
    if D < FFixedRows then
      Continue;
    for C := Sl.Left to Sl.Right do
    begin
      if C >= VColCount then
        Break;
      DC := DataCol(C);
      // Kaestchen bleiben: leer hiesse still "aus"
      if CanEditCell(DC, V) and (CellEditorKind(DC, D) <> gekCheck) and
        (GetCellText(DC, D) <> '') then
        SetCellByUser(DC, D, '');
    end;
  end;
end;

procedure TPPGCustomGrid.CutToClipboard;
begin
  CopyToClipboard;
  ClearSelection;
end;

procedure TPPGCustomGrid.CMHintShow(var Message: TCMHintShow);
var
  C, V, D, DC, Avail, W, PPI, M0, N0, M1, N1: Integer;
  R: TRect;
  S: string;
  Col: TPPGGridColumn;
  F, Temp: TFont;
begin
  inherited;
  // Audit 7f #1: abgeschnittener Zelltext als Hinweis (nur ohne eigenen Hint)
  if not FToolTips or (Hint <> '') or (Message.HintInfo = nil) then
    Exit;
  if not MouseCoord(Message.HintInfo^.CursorPos.X, Message.HintInfo^.CursorPos.Y, C, V) then
    Exit;
  D := DataRow(V);
  if D < 0 then
    Exit; // Filterzeile, Gruppenkopf und -fuss
  DC := DataCol(C);
  // Zellarten (Haken, Fortschritt ...) zeichnen selbst; verbundene Zellen nicht
  if (D >= FFixedRows) and (C >= FFixedCols) and (KindOf(DC) <> nil) then
    Exit;
  if MergesActive and MergeAtCell(C, V, M0, N0, M1, N1) then
    Exit;
  S := GetCellText(DC, D);
  if S = '' then
    Exit;
  R := CellRect(C, V);
  if IsRectEmpty(R) then
    Exit;
  PPI := ScalePPI;
  Avail := (R.Right - R.Left) - 2 * PPGScale(CellPadX, PPI);
  if (D = 0) and (DC = FSortCol) then
    Dec(Avail, PPGScale(TPPGCellPainter.SortArrowSpace, PPI));
  Col := ColumnOf(DC);
  Temp := nil;
  try
    if (D < FFixedRows) or (C < FFixedCols) then
      F := PPGElementFont(FStyles.Header, Font, [], Temp)
    else if Col <> nil then
      F := PPGElementFont(Col.Style, Font, [], Temp)
    else
      F := Font;
    W := PPGMeasureTextNoCanvas(S, F, 0, False).cx;
  finally
    Temp.Free;
  end;
  if W <= Avail then
    Exit;
  Message.HintInfo^.HintStr := S;
  Message.HintInfo^.CursorRect := R;
end;

procedure TPPGCustomGrid.PasteText(const S: string);
var
  Lines, Cells: TStringList;
  I, J, C, V, D: Integer;
begin
  if not (goEditing in FOptions) then
    Exit;
  HideEditor(True);
  Lines := TStringList.Create;
  Cells := TStringList.Create;
  try
    Lines.Text := S;
    Cells.Delimiter := #9;
    Cells.StrictDelimiter := True;
    for I := 0 to Lines.Count - 1 do
    begin
      V := FFocusV + I;
      if V >= VRowCount then
        Break;
      D := DataRow(V);
      if D < FFixedRows then
        Continue;
      Cells.DelimitedText := Lines[I];
      for J := 0 to Cells.Count - 1 do
      begin
        C := FFocusC + J;
        if C >= VColCount then
          Break;
        if CanEditCell(DataCol(C), V) then
          SetCellByUser(DataCol(C), D, Cells[J]);
      end;
    end;
  finally
    Cells.Free;
    Lines.Free;
  end;
end;

function TPPGCustomGrid.ToCSV(Separator: Char): string;
var
  V, C, D: Integer;
  SB: TStringBuilder;

  function Quote(const F: string): string;
  begin
    // RFC 4180: Felder mit Trenner, Anfuehrungszeichen oder Zeilenumbruch
    if (Pos(Separator, F) > 0) or (Pos('"', F) > 0) or (Pos(#13, F) > 0) or
      (Pos(#10, F) > 0) then
      Result := '"' + StringReplace(F, '"', '""', [rfReplaceAll]) + '"'
    else
      Result := F;
  end;

begin
  SB := TStringBuilder.Create;
  try
    for V := 0 to VRowCount - 1 do
    begin
      D := DataRow(V);
      if D < 0 then
        Continue; // Filterzeile
      for C := 0 to VColCount - 1 do
      begin
        if C > 0 then
          SB.Append(Separator);
        SB.Append(Quote(GetCellText(DataCol(C), D)));
      end;
      SB.Append(#13#10);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TPPGCustomGrid.SaveToCSV(const FileName: string; Separator: Char);
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Text := ToCSV(Separator);
    L.SaveToFile(FileName, TEncoding.UTF8);
  finally
    L.Free;
  end;
end;

procedure TPPGCustomGrid.WndProc(var Message: TMessage);
begin
  if (GMsgAggregate <> 0) and (Message.Msg = GMsgAggregate) then
  begin
    FAggPosted := False;
    if FAggDirty then
    begin
      RecalcAggregates;
      Invalidate;
    end
    else if FAggPendCount > 0 then
    begin
      // Einzelaenderungen inkrementell (Audit 8c #6)
      ApplyPendingAggregates;
      Invalidate;
    end;
    Exit;
  end;
  if Message.Msg = CM_MOUSELEAVE then
    SetHotRow(-1);
  // Theme bzw. Systemfarben: Schriften neu (Audit 8c #10)
  if (Message.Msg = CM_STYLECHANGED) or (Message.Msg = CM_SYSCOLORCHANGE) or
    (Message.Msg = WM_THEMECHANGED) or (Message.Msg = WM_SETTINGCHANGE) or
    (Message.Msg = CM_PARENTFONTCHANGED) then
    FontsChanged;
  if (GMsgRowAction <> 0) and (Message.Msg = GMsgRowAction) then
  begin
    if (Integer(Message.WParam) >= VFixedRows) and (Integer(Message.WParam) < VRowCount) then
      MoveFocus(FFocusC, Integer(Message.WParam), False, True);
    Exit;
  end;
  inherited WndProc(Message);
end;

{ ---- Barrierefreiheit ---- }

function TPPGCustomGrid.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_TABLE;
end;

function TPPGCustomGrid.AccValue: string;
var
  D: Integer;
begin
  D := DataRow(FFocusV);
  if D >= 0 then
    Result := GetCellText(DataCol(FFocusC), D)
  else
    Result := '';
end;

function TPPGCustomGrid.AccChildCount: Integer;
begin
  Result := VRowCount;
end;

function TPPGCustomGrid.AccChildName(Id: Integer): string;
var
  C, D: Integer;
begin
  Result := '';
  D := DataRow(Id - 1);
  if (D = GroupRowMark) or (D = GroupFooterMark) then
    Exit(PPGStripMarkup(GroupRowName(Id - 1)));
  if D < 0 then
    Exit;
  for C := 0 to VColCount - 1 do
  begin
    if C > 0 then
      Result := Result + '; ';
    Result := Result + GetCellText(DataCol(C), D);
  end;
end;

function TPPGCustomGrid.AccChildRole(Id: Integer): Integer;
begin
  if Id - 1 < FFixedRows then
    Result := ROLE_SYSTEM_COLUMNHEADER
  else
    Result := ROLE_SYSTEM_ROW;
end;

function TPPGCustomGrid.AccChildState(Id: Integer): Integer;
var
  V: Integer;
  Sl: TGridRect;
begin
  V := Id - 1;
  Result := STATE_SYSTEM_SELECTABLE or STATE_SYSTEM_FOCUSABLE;
  Sl := GetSelection;
  if (V >= Sl.Top) and (V <= Sl.Bottom) then
    Result := Result or STATE_SYSTEM_SELECTED;
  if Focused and (V = FFocusV) then
    Result := Result or STATE_SYSTEM_FOCUSED;
  if IsRectEmpty(CellRect(FFixedCols, V)) and IsRectEmpty(CellRect(0, V)) then
    Result := Result or STATE_SYSTEM_INVISIBLE or STATE_SYSTEM_OFFSCREEN;
end;

function TPPGCustomGrid.AccChildRect(Id: Integer): TRect;
var
  A, B: TRect;
begin
  A := CellRect(0, Id - 1);
  B := CellRect(VColCount - 1, Id - 1);
  if IsRectEmpty(A) then
    Result := B
  else if IsRectEmpty(B) then
    Result := A
  else
    UnionRect(Result, A, B);
end;

function TPPGCustomGrid.AccChildAt(X, Y: Integer): Integer;
var
  C, V: Integer;
begin
  if MouseCoord(X, Y, C, V) then
    Result := V + 1
  else
    Result := 0;
end;

function TPPGCustomGrid.AccChildDefaultAction(Id: Integer): string;
begin
  Result := PPGStr(@SPPGAccSelect);
end;

procedure TPPGCustomGrid.AccChildDoDefault(Id: Integer);
begin
  // Kein Anwender-Code im COM-Aufruf (MoveFocus loest OnSelectCell aus):
  // ueber die Nachrichtenschlange
  if HandleAllocated then
    PostMessage(Handle, GMsgRowAction, WPARAM(Id - 1), 0);
end;

function TPPGCustomGrid.AccFocusedChild: Integer;
begin
  if Focused then
    Result := FFocusV + 1
  else
    Result := 0;
end;

function TPPGCustomGrid.AccSelectedChild: Integer;
begin
  Result := FFocusV + 1;
end;

{ ---- UI Automation (IPPGUiaSource) ---- }

const
  /// Hoechstens so viele Elemente liefern Auswahl und Zeilenkoepfe (UIA
  /// fragt sonst bei 1 000 000 Zeilen nach einem riesigen Feld).
  UiaMaxList = 1000;

function TPPGCustomGrid.UiaVRow(const Id: TPPGUiaId): Integer;
begin
  case Id.Kind of
    PPGUiaKindGridRow, PPGUiaKindGridCell:
      if (Id.A >= FFixedRows) and (Id.A < FRowCount) then
        Result := VisualRow(Id.A)
      else
        Result := -1;
    PPGUiaKindGridHeaderRow, PPGUiaKindGridHeaderCell:
      if (Id.A >= 0) and (Id.A < FFixedRows) then
        Result := Id.A
      else
        Result := -1;
    PPGUiaKindGridGroup:
      if (Id.A >= 0) and (Id.A < GroupCount) and (FView.Group.HeaderAt[Id.A] >= 0) then
        Result := VFixedRows + FView.Group.HeaderAt[Id.A]
      else
        Result := -1;
    PPGUiaKindGridGroupFooter:
      if (Id.A >= 0) and (Id.A < GroupCount) and (FView.Group.FooterAt[Id.A] >= 0) then
        Result := VFixedRows + FView.Group.FooterAt[Id.A]
      else
        Result := -1;
  else
    Result := -1;
  end;
end;

function TPPGCustomGrid.UiaCellId(ACol, VRow: Integer): TPPGUiaId;
var
  D: Integer;
begin
  Result := PPGUiaId(0);
  // ACol = Anzeige-Spalte; das Element traegt die Datenspalte (bleibt beim
  // Verschieben gleich)
  if (ACol < 0) or (ACol >= VColCount) or (VRow < 0) or (VRow >= VRowCount) then
    Exit;
  if VRow < FFixedRows then
    Exit(PPGUiaId(PPGUiaKindGridHeaderCell, VRow, DataCol(ACol)));
  D := DataRow(VRow);
  if (D = GroupRowMark) or (D = GroupFooterMark) then
    Exit(UiaGroupId(VRow));
  if D >= FFixedRows then
    Result := PPGUiaId(PPGUiaKindGridCell, D, DataCol(ACol));
end;

function TPPGCustomGrid.UiaGroupId(VRow: Integer): TPPGUiaId;
var
  G: Integer;
  Footer: Boolean;
begin
  G := GroupAtRow(VRow, Footer);
  if G < 0 then
    Result := PPGUiaId(0)
  else if Footer then
    Result := PPGUiaId(PPGUiaKindGridGroupFooter, G)
  else
    Result := PPGUiaId(PPGUiaKindGridGroup, G);
end;

function TPPGCustomGrid.UiaValid(const Id: TPPGUiaId): Boolean;
begin
  case Id.Kind of
    0: Result := True;
    PPGUiaKindGridRow, PPGUiaKindGridHeaderRow:
      Result := UiaVRow(Id) >= 0;
    PPGUiaKindGridCell, PPGUiaKindGridHeaderCell:
      Result := (UiaVRow(Id) >= 0) and (VisualCol(Id.B) >= 0);
    PPGUiaKindGridGroup, PPGUiaKindGridGroupFooter:
      Result := UiaVRow(Id) >= 0;
  else
    Result := False;
  end;
end;

function TPPGCustomGrid.UiaParent(const Id: TPPGUiaId): TPPGUiaId;
begin
  case Id.Kind of
    PPGUiaKindGridCell: Result := PPGUiaId(PPGUiaKindGridRow, Id.A);
    PPGUiaKindGridHeaderCell: Result := PPGUiaId(PPGUiaKindGridHeaderRow, Id.A);
  else
    Result := PPGUiaId(0);
  end;
end;

function TPPGCustomGrid.UiaChildCount(const Id: TPPGUiaId): Integer;
begin
  case Id.Kind of
    0: Result := FFixedRows + (VRowCount - VFixedRows);
    PPGUiaKindGridRow, PPGUiaKindGridHeaderRow: Result := VColCount;
  else
    Result := 0;
  end;
end;

function TPPGCustomGrid.UiaChild(const Id: TPPGUiaId; Index: Integer): TPPGUiaId;
var
  D: Integer;
begin
  Result := PPGUiaId(0);
  if Index < 0 then
    Exit;
  case Id.Kind of
    0:
      if Index < FFixedRows then
        Result := PPGUiaId(PPGUiaKindGridHeaderRow, Index)
      else
      begin
        // Datenzeilen in der sichtbaren Reihenfolge (Sortierung, Filter)
        D := DataRow(VFixedRows + Index - FFixedRows);
        if D >= FFixedRows then
          Result := PPGUiaId(PPGUiaKindGridRow, D)
        else if (D = GroupRowMark) or (D = GroupFooterMark) then
          Result := UiaGroupId(VFixedRows + Index - FFixedRows);
      end;
    PPGUiaKindGridRow:
      if Index < VColCount then
        Result := PPGUiaId(PPGUiaKindGridCell, Id.A, DataCol(Index));
    PPGUiaKindGridHeaderRow:
      if Index < VColCount then
        Result := PPGUiaId(PPGUiaKindGridHeaderCell, Id.A, DataCol(Index));
  end;
end;

function TPPGCustomGrid.UiaIndexInParent(const Id: TPPGUiaId): Integer;
begin
  case Id.Kind of
    PPGUiaKindGridHeaderRow: Result := Id.A;
    PPGUiaKindGridRow: Result := FFixedRows + UiaVRow(Id) - VFixedRows;
    PPGUiaKindGridGroup, PPGUiaKindGridGroupFooter:
      Result := FFixedRows + UiaVRow(Id) - VFixedRows;
    PPGUiaKindGridCell, PPGUiaKindGridHeaderCell: Result := VisualCol(Id.B);
  else
    Result := -1;
  end;
end;

function TPPGCustomGrid.UiaElementAt(X, Y: Integer): TPPGUiaId;
var
  C, V: Integer;
begin
  if MouseCoord(X, Y, C, V) then
    Result := UiaCellId(C, V)
  else
    Result := PPGUiaId(0);
end;

function TPPGCustomGrid.UiaFocused: TPPGUiaId;
begin
  if Focused and not EditorMode then
    Result := UiaCellId(FFocusC, FFocusV)
  else
    Result := PPGUiaId(0);
end;

function TPPGCustomGrid.UiaFromAccChild(ChildId: Integer): TPPGUiaId;
var
  V, D: Integer;
begin
  // Das Grid meldet den Fokus je Zeile: UIA bekommt die Fokuszelle
  V := ChildId - 1;
  if V = FFocusV then
    Exit(UiaCellId(FFocusC, V));
  Result := PPGUiaId(0);
  if (V >= 0) and (V < FFixedRows) then
    Result := PPGUiaId(PPGUiaKindGridHeaderRow, V)
  else
  begin
    D := DataRow(V);
    if D >= FFixedRows then
      Result := PPGUiaId(PPGUiaKindGridRow, D);
    if (D = GroupRowMark) or (D = GroupFooterMark) then
      Result := UiaGroupId(V);
  end;
end;

function TPPGCustomGrid.UiaControlType(const Id: TPPGUiaId): Integer;
begin
  case Id.Kind of
    PPGUiaKindGridRow, PPGUiaKindGridGroup, PPGUiaKindGridGroupFooter:
      Result := UIA_DataItemControlTypeId;
    PPGUiaKindGridHeaderRow: Result := UIA_HeaderControlTypeId;
    PPGUiaKindGridHeaderCell: Result := UIA_HeaderItemControlTypeId;
    PPGUiaKindGridCell:
      if Id.B < FFixedCols then
        Result := UIA_HeaderItemControlTypeId
      else if (ColumnOf(Id.B) <> nil) and (ColumnOf(Id.B).CellKind = ckButton) then
        Result := UIA_ButtonControlTypeId
      else if (ColumnOf(Id.B) <> nil) and (ColumnOf(Id.B).CellKind = ckLink) then
        Result := UIA_HyperlinkControlTypeId
      else if CellEditorKind(Id.B, Id.A) = gekCheck then
        Result := UIA_CheckBoxControlTypeId
      else if CanEditCell(Id.B, UiaVRow(Id)) then
        Result := UIA_EditControlTypeId
      else
        Result := UIA_TextControlTypeId;
  else
    Result := UIA_DataGridControlTypeId;
  end;
end;

function TPPGCustomGrid.UiaName(const Id: TPPGUiaId): string;
var
  V: Integer;
begin
  case Id.Kind of
    0: Result := AccName;
    PPGUiaKindGridCell, PPGUiaKindGridHeaderCell:
      Result := GetCellText(Id.B, Id.A);
    PPGUiaKindGridGroup, PPGUiaKindGridGroupFooter:
      Result := PPGStripMarkup(GroupRowName(UiaVRow(Id)));
    PPGUiaKindGridRow, PPGUiaKindGridHeaderRow:
      begin
        V := UiaVRow(Id);
        if V >= 0 then
          Result := AccChildName(V + 1)
        else
          Result := '';
      end;
  else
    Result := '';
  end;
end;

function TPPGCustomGrid.UiaRect(const Id: TPPGUiaId): TRect;
var
  V: Integer;
begin
  V := UiaVRow(Id);
  if V < 0 then
    Exit(Rect(0, 0, 0, 0));
  case Id.Kind of
    PPGUiaKindGridCell, PPGUiaKindGridHeaderCell: Result := CellRect(VisualCol(Id.B), V);
  else
    Result := AccChildRect(V + 1);
  end;
end;

function TPPGCustomGrid.UiaEnabled(const Id: TPPGUiaId): Boolean;
begin
  Result := Enabled;
end;

function TPPGCustomGrid.UiaFocusable(const Id: TPPGUiaId): Boolean;
begin
  case Id.Kind of
    0: Result := TabStop and Enabled;
    PPGUiaKindGridCell: Result := Id.B >= FFixedCols;
    PPGUiaKindGridGroup: Result := True;
  else
    Result := False;
  end;
end;

function TPPGCustomGrid.UiaProperty(const Id: TPPGUiaId; PropertyId: Integer;
  out Value: OleVariant): Boolean;
begin
  // Sortierrichtung der Kopfzelle als Zustand (z.B. "aufsteigend sortiert")
  Result := (PropertyId = UIA_ItemStatusPropertyId) and (Id.Kind = PPGUiaKindGridHeaderCell) and
    (Id.B = FSortCol);
  if Result then
  begin
    if FSortAscending then
      Value := PPGStr(@SPPGSortAscending)
    else
      Value := PPGStr(@SPPGSortDescending);
  end;
end;

function TPPGCustomGrid.UiaHasPattern(const Id: TPPGUiaId; PatternId: Integer): Boolean;
var
  DataCell: Boolean;
begin
  case Id.Kind of
    0:
      Result := (PatternId = UIA_GridPatternId) or (PatternId = UIA_TablePatternId) or
        (PatternId = UIA_SelectionPatternId);
    PPGUiaKindGridCell:
      begin
        DataCell := Id.B >= FFixedCols;
        case PatternId of
          UIA_GridItemPatternId, UIA_TableItemPatternId, UIA_SelectionItemPatternId:
            Result := DataCell;
          UIA_ScrollItemPatternId, UIA_ValuePatternId:
            Result := True;
          UIA_InvokePatternId:
            Result := DataCell and (ColumnOf(Id.B) <> nil) and
              (ColumnOf(Id.B).CellKind in [ckButton, ckLink]);
          UIA_TogglePatternId:
            Result := DataCell and (CellEditorKind(Id.B, Id.A) = gekCheck);
        else
          Result := False;
        end;
      end;
    PPGUiaKindGridHeaderCell:
      // Klick auf den Kopf sortiert (wie mit der Maus)
      Result := (PatternId = UIA_InvokePatternId) and FSortOnHeaderClick and
        (Id.A = 0) and (Id.B >= FFixedCols);
    PPGUiaKindGridRow:
      Result := PatternId = UIA_ScrollItemPatternId;
    PPGUiaKindGridGroup:
      Result := (PatternId = UIA_ExpandCollapsePatternId) or
        (PatternId = UIA_ScrollItemPatternId);
    PPGUiaKindGridGroupFooter:
      Result := PatternId = UIA_ScrollItemPatternId;
  else
    Result := False;
  end;
end;

function TPPGCustomGrid.UiaCanSelectMultiple: Boolean;
begin
  Result := (goRangeSelect in FOptions) or (goRowSelect in FOptions);
end;

function TPPGCustomGrid.UiaSelection: TPPGUiaIds;
var
  Sl: TGridRect;
  C, V, N: Integer;
begin
  SetLength(Result, 0);
  if FFocusV < VFixedRows then
    Exit;
  Sl := GetSelection;
  // Grosse Bereiche: nur die Fokuszelle (UIA erwartet keine Millionen Elemente)
  if (Int64(Sl.Right - Sl.Left + 1) * (Sl.Bottom - Sl.Top + 1)) > UiaMaxList then
  begin
    SetLength(Result, 1);
    Result[0] := UiaCellId(FFocusC, FFocusV);
    Exit;
  end;
  SetLength(Result, (Sl.Right - Sl.Left + 1) * (Sl.Bottom - Sl.Top + 1));
  N := 0;
  for V := Sl.Top to Sl.Bottom do
    for C := Sl.Left to Sl.Right do
    begin
      if (C > Sl.Left) and (DataRow(V) < 0) then
        Continue; // Gruppenzeile: ein Element fuer die ganze Zeile
      Result[N] := UiaCellId(C, V);
      if not PPGUiaIsRoot(Result[N]) then
        Inc(N);
    end;
  SetLength(Result, N);
end;

function TPPGCustomGrid.UiaIsSelected(const Id: TPPGUiaId): Boolean;
var
  Sl: TGridRect;
  V: Integer;
begin
  Result := False;
  if Id.Kind <> PPGUiaKindGridCell then
    Exit;
  V := UiaVRow(Id);
  Sl := GetSelection;
  Result := (V >= Sl.Top) and (V <= Sl.Bottom) and (VisualCol(Id.B) >= Sl.Left) and
    (VisualCol(Id.B) <= Sl.Right);
end;

procedure TPPGCustomGrid.UiaGridSize(out Rows, Cols: Integer);
begin
  Rows := VRowCount - VFixedRows;
  if Rows < 0 then
    Rows := 0;
  Cols := VColCount - FFixedCols;
  if Cols < 0 then
    Cols := 0;
end;

function TPPGCustomGrid.UiaGridItem(Row, Col: Integer): TPPGUiaId;
begin
  Result := UiaCellId(FFixedCols + Col, VFixedRows + Row);
end;

procedure TPPGCustomGrid.UiaGridPos(const Id: TPPGUiaId; out Row, Col: Integer);
begin
  Row := UiaVRow(Id) - VFixedRows;
  Col := VisualCol(Id.B) - FFixedCols;
end;

function TPPGCustomGrid.UiaHeaders(Columns: Boolean): TPPGUiaIds;
var
  I, N, Rows, Cols: Integer;
begin
  SetLength(Result, 0);
  UiaGridSize(Rows, Cols);
  if Columns then
  begin
    // Spaltenkoepfe: unterste feste Zeile
    if FFixedRows = 0 then
      Exit;
    SetLength(Result, Cols);
    for I := 0 to Cols - 1 do
      Result[I] := PPGUiaId(PPGUiaKindGridHeaderCell, FFixedRows - 1, DataCol(FFixedCols + I));
  end
  else
  begin
    // Zeilenkoepfe: erste feste Spalte (bei sehr vielen Zeilen keine Liste)
    if (FFixedCols = 0) or (Rows > UiaMaxList) then
      Exit;
    SetLength(Result, Rows);
    N := 0;
    for I := 0 to Rows - 1 do
    begin
      Result[N] := UiaCellId(0, VFixedRows + I);
      if not PPGUiaIsRoot(Result[N]) then
        Inc(N);
    end;
    SetLength(Result, N);
  end;
end;

function TPPGCustomGrid.UiaItemHeaders(const Id: TPPGUiaId; Columns: Boolean): TPPGUiaIds;
begin
  SetLength(Result, 0);
  if Id.Kind <> PPGUiaKindGridCell then
    Exit;
  if Columns and (FFixedRows > 0) then
  begin
    SetLength(Result, 1);
    Result[0] := PPGUiaId(PPGUiaKindGridHeaderCell, FFixedRows - 1, Id.B);
  end
  else if not Columns and (FFixedCols > 0) then
  begin
    SetLength(Result, 1);
    Result[0] := PPGUiaId(PPGUiaKindGridCell, Id.A, 0);
  end;
end;

function TPPGCustomGrid.UiaValue(const Id: TPPGUiaId): string;
var
  K: IPPGCellKind;
begin
  if (Id.Kind = PPGUiaKindGridCell) and (Id.B >= FFixedCols) then
  begin
    K := KindOf(Id.B);
    Result := GetCellText(Id.B, Id.A);
    if K <> nil then
      Result := K.CellAccText(KindContext(Id.B), Result);
  end
  else if Id.Kind in [PPGUiaKindGridCell, PPGUiaKindGridHeaderCell] then
    Result := GetCellText(Id.B, Id.A)
  else
    Result := '';
end;

function TPPGCustomGrid.UiaReadOnly(const Id: TPPGUiaId): Boolean;
begin
  Result := (Id.Kind <> PPGUiaKindGridCell) or not CanEditCell(Id.B, UiaVRow(Id)) or
    (CellEditorKind(Id.B, Id.A) = gekCheck);
end;

function TPPGCustomGrid.UiaExpandState(const Id: TPPGUiaId): Integer;
begin
  Result := ExpandCollapseState_LeafNode;
  if (Id.Kind = PPGUiaKindGridGroup) and (Id.A >= 0) and (Id.A < GroupCount) then
  begin
    if FView.Group.Groups[Id.A].Expanded then
      Result := ExpandCollapseState_Expanded
    else
      Result := ExpandCollapseState_Collapsed;
  end;
end;

function TPPGCustomGrid.UiaToggleState(const Id: TPPGUiaId): Integer;
var
  S: string;
begin
  S := UiaValue(Id);
  if TPPGCellPainter.IsCheckedText(S) then
    Result := ToggleState_On
  else
    Result := ToggleState_Off;
end;

procedure TPPGCustomGrid.UiaExecute(const Id: TPPGUiaId; Action: TPPGUiaAction;
  const Value: string);
var
  V: Integer;
  S: string;
  Ok: Boolean;
begin
  if not Enabled then
    Exit;
  V := UiaVRow(Id);
  if Id.Kind = PPGUiaKindGridGroup then
  begin
    case Action of
      uaExpand, uaCollapse:
        if (Id.A >= 0) and (Id.A < GroupCount) then
          ExpandGroup(Id.A, Action = uaExpand);
      uaSetFocus, uaSelect, uaAddToSelection:
        begin
          if (Action = uaSetFocus) and CanFocus and not Focused then
            SetFocus;
          if V >= 0 then
            MoveFocus(FFocusC, V, False, True);
        end;
      uaScrollIntoView:
        if V >= 0 then
          MakeCellVisible(FFixedCols, V);
    end;
    Exit;
  end;
  V := UiaVRow(Id);
  case Action of
    uaSetFocus:
      begin
        if CanFocus and not Focused then
          SetFocus;
        if (Id.Kind = PPGUiaKindGridCell) and (Id.B >= FFixedCols) then
          MoveFocus(VisualCol(Id.B), V, False, True);
      end;
    uaSelect, uaAddToSelection:
      if (Id.Kind = PPGUiaKindGridCell) and (Id.B >= FFixedCols) then
        MoveFocus(VisualCol(Id.B), V, (Action = uaAddToSelection) and UiaCanSelectMultiple, True);
    uaScrollIntoView:
      if V >= 0 then
      begin
        if Id.Kind in [PPGUiaKindGridCell, PPGUiaKindGridHeaderCell] then
          MakeCellVisible(VisualCol(Id.B), V)
        else
          MakeCellVisible(FFixedCols, V);
      end;
    uaToggle:
      if Id.Kind = PPGUiaKindGridCell then
        ToggleCheck(Id.B, V);
    uaInvoke:
      if Id.Kind = PPGUiaKindGridHeaderCell then
        HeaderClicked(Id.B, Id.A)
      else if (Id.Kind = PPGUiaKindGridCell) and (V >= 0) and (ColumnOf(Id.B) <> nil) and
        (ColumnOf(Id.B).CellKind in [ckButton, ckLink]) then
      begin
        if ColumnOf(Id.B).CellKind = ckButton then
          DoCellAction(caButton, Id.B, V, '')
        else
          DoCellAction(caLink, Id.B, V, GetCellText(Id.B, Id.A));
      end;
    uaSetValue:
      if (Id.Kind = PPGUiaKindGridCell) and CanEditCell(Id.B, V) then
      begin
        // Wie beim Editor: OnValidateCell darf ablehnen oder aendern
        S := Value;
        Ok := True;
        if Assigned(FOnValidateCell) then
          FOnValidateCell(Self, Id.B, Id.A, S, Ok);
        if Ok then
          SetCellByUser(Id.B, Id.A, S);
      end;
  end;
end;

end.
