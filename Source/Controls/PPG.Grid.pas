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
  Vcl.Controls, Vcl.Graphics, Vcl.Grids, Vcl.StdCtrls, Vcl.Forms,
  PPG.Types, PPG.RowLayout, PPG.Render.Intf, PPG.Accessibility, PPG.UIA,
  PPG.Controls.Base, PPG.Controls.Scroll, PPG.Edit, PPG.ComboBox, PPG.SpinEdit;

const
  // UI Automation: Arten der Elemente (0 = das Grid selbst)
  PPGUiaKindGridRow = 1;        // Datenzeile, A = Datenzeile
  PPGUiaKindGridCell = 2;       // Zelle, A = Datenzeile, B = Spalte
  PPGUiaKindGridHeaderRow = 3;  // feste Kopfzeile, A = Zeile
  PPGUiaKindGridHeaderCell = 4; // Kopfzelle, A = feste Zeile, B = Spalte

type
  TPPGGridEditorKind = (gekText, gekNone, gekCombo, gekSpin, gekCheck);

  TPPGGridColumn = class(TCollectionItem)
  private
    FTitle: string;
    FWidth: Integer;
    FAlignment: TAlignment;
    FEditorKind: TPPGGridEditorKind;
    FPickList: TStrings;
    FReadOnly: Boolean;
    FMinValue: Integer;
    FMaxValue: Integer;
    FSortable: Boolean;
    procedure SetTitle(const Value: string);
    procedure SetWidth(const Value: Integer);
    procedure SetAlignment(const Value: TAlignment);
    procedure SetPickList(const Value: TStrings);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    property Title: string read FTitle write SetTitle;
    /// Logische Breite (0 = DefaultColWidth).
    property Width: Integer read FWidth write SetWidth default 0;
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property EditorKind: TPPGGridEditorKind read FEditorKind write FEditorKind default gekText;
    property PickList: TStrings read FPickList write SetPickList;
    property ReadOnly: Boolean read FReadOnly write FReadOnly default False;
    property MinValue: Integer read FMinValue write FMinValue default 0;
    property MaxValue: Integer read FMaxValue write FMaxValue default 0;
    property Sortable: Boolean read FSortable write FSortable default True;
  end;

  TPPGGridColumns = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGGridColumn;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    function Add: TPPGGridColumn;
    property Items[Index: Integer]: TPPGGridColumn read GetItem; default;
  end;

  TPPGGetCellTextEvent = procedure(Sender: TObject; ACol, ARow: Integer;
    var Text: string) of object;
  TPPGCompareCellsEvent = procedure(Sender: TObject; ACol, ARow1, ARow2: Integer;
    var Compare: Integer) of object;
  TPPGValidateCellEvent = procedure(Sender: TObject; ACol, ARow: Integer;
    var Value: string; var Accept: Boolean) of object;

  TPPGCustomGrid = class;

  /// Editor-Felder: Enter/Esc/Tab gehoeren dem Grid, nicht dem Dialog.
  TPPGGridEdit = class(TPPGEdit)
  protected
    function WantSpecialKey(Key: Word): Boolean; override;
  end;

  TPPGGridCombo = class(TPPGComboBox)
  protected
    function WantSpecialKey(Key: Word): Boolean; override;
  end;

  TPPGGridSpin = class(TPPGSpinEdit)
  protected
    function WantSpecialKey(Key: Word): Boolean; override;
  end;

  /// Farben eines Zeichenvorgangs (einmal berechnet, nicht je Zelle).
  TPPGGridPaintColors = record
    Fill, Text, Header, Line, Accent, Hint: TColor;
  end;

  TPPGCustomGrid = class(TPPGCustomScrollControl, IPPGAccessibleChildren, IPPGUiaSource)
  private
    FPaint: TPPGGridPaintColors;
    FColCount: Integer;
    FRowCount: Integer;
    FFixedCols: Integer;
    FFixedRows: Integer;
    FDefaultColWidth: Integer;
    FDefaultRowHeight: Integer;
    FColWidths: array of Integer;   // logisch, 0 = Standard (ohne Spalte)
    FRowHeights: array of Integer;  // logisch je Datenzeile, 0 = Standard
    FHasRowHeights: Boolean;
    FCells: array of array of string;
    FOptions: TGridOptions;
    FColumns: TPPGGridColumns;
    FLayout: TPPGRowLayout;
    FColX: array of Integer;        // Pixel-Anfang je Spalte (+ Ende)
    FGeomValid: Boolean;
    FGeomPPI: Integer;
    FMapped: Boolean;
    FRowMap: array of Integer;      // sichtbare Datenzeile -> Datenzeile
    FInvMap: array of Integer;      // Datenzeile -> sichtbare Datenzeile (-1)
    FSortCol: Integer;
    FSortAscending: Boolean;
    FSortOnHeaderClick: Boolean;
    FFilters: array of string;
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
    procedure SetColCount(const Value: Integer);
    procedure SetRowCount(const Value: Integer);
    procedure SetFixedCols(const Value: Integer);
    procedure SetFixedRows(const Value: Integer);
    procedure SetDefaultColWidth(const Value: Integer);
    procedure SetDefaultRowHeight(const Value: Integer);
    procedure SetOptions(const Value: TGridOptions);
    procedure SetColumns(const Value: TPPGGridColumns);
    procedure SetShowFilterRow(const Value: Boolean);
    procedure SetBorderStyle(const Value: TBorderStyle);
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
    procedure EnsureCellStorage(ARow: Integer);
    procedure CheckCell(ACol, ARow: Integer);
    procedure EditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditorExit(Sender: TObject);
    function EditorText: string;
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
    procedure CMEnter(var Message: TCMEnter); message CM_ENTER;
  protected
    procedure WndProc(var Message: TMessage); override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure Scrolled; override;
    { Geometrie }
    procedure InvalidateGeometry;
    procedure EnsureGeometry;
    function VFixedRows: Integer;
    function VRowCount: Integer;
    function FixedWidth: Integer;
    function FixedHeight: Integer;
    function ColPixelWidth(ACol: Integer): Integer;
    { Zeilen-Abbildung (Sortieren/Filtern) }
    procedure RebuildMap;
    function CompareDataRows(ACol, R1, R2: Integer): Integer; virtual;
    function RowPassesFilter(ARow: Integer): Boolean; virtual;
    { Daten }
    /// Text einer Datenzelle (Cells bzw. OnGetCellText, Kopf aus Columns).
    function GetCellText(ACol, ARow: Integer): string; virtual;
    /// Wert setzen (Editor, Einfuegen): Cells + OnSetEditText.
    procedure SetCellByUser(ACol, ARow: Integer; const Value: string); virtual;
    function ColumnOf(ACol: Integer): TPPGGridColumn;
    function CellEditorKind(ACol, ARow: Integer): TPPGGridEditorKind;
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
    { Eingabe }
    procedure ContentMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure ContentMouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure ContentMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoAutoScroll(const P: TPoint); override;
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    function SizingColAt(X, Y: Integer): Integer;
    /// Fokus auf eine Zelle (sichtbare Zeile); Extend = Bereich vom Anker.
    function MoveFocus(ACol, VRow: Integer; Extend, ByUser: Boolean): Boolean;
    function SelectCell(ACol, ARow: Integer): Boolean; virtual;
    procedure ToggleCheck(ACol, VRow: Integer);
    procedure HeaderClicked(ACol, VRow: Integer); virtual;
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

    property ColCount: Integer read FColCount write SetColCount default 5;
    property RowCount: Integer read FRowCount write SetRowCount default 5;
    property FixedCols: Integer read FFixedCols write SetFixedCols default 1;
    property FixedRows: Integer read FFixedRows write SetFixedRows default 1;
    property DefaultColWidth: Integer read FDefaultColWidth write SetDefaultColWidth default 64;
    property DefaultRowHeight: Integer read FDefaultRowHeight write SetDefaultRowHeight default 24;
    property DefaultDrawing: Boolean read FDefaultDrawing write FDefaultDrawing default True;
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
    property OnTopLeftChanged: TNotifyEvent read FOnTopLeftChanged write FOnTopLeftChanged;
    property OnSorted: TNotifyEvent read FOnSorted write FOnSorted;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Sichtbare Zeile einer Datenzeile (-1 = herausgefiltert) und umgekehrt
    /// (-1 = feste Zeile/Filterzeile ohne Daten; -2 = Filterzeile).
    function VisualRow(ARow: Integer): Integer;
    function DataRow(VRow: Integer): Integer;
    /// Zelle (Spalte, sichtbare Zeile) in Client-Koordinaten.
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
    /// Auswahl als TSV (Tab/CRLF) bzw. Text einfuegen ab der Fokuszelle.
    function SelectionAsText: string;
    procedure PasteText(const S: string);
    /// Alle sichtbaren Zeilen (inkl. feste) als CSV.
    function ToCSV(Separator: Char = ';'): string;
    procedure SaveToCSV(const FileName: string; Separator: Char = ';');
    procedure SelectAll;
    property Cells[ACol, ARow: Integer]: string read GetCells write SetCells;
    property ColWidths[Index: Integer]: Integer read GetColWidths write SetColWidths;
    property RowHeights[Index: Integer]: Integer read GetRowHeights write SetRowHeights;
    property Filters[ACol: Integer]: string read GetFilter write SetFilter;
    property Col: Integer read FFocusC write SetCol;
    /// Datenzeile der Fokuszelle.
    property Row: Integer read GetRow write SetRow;
    /// Sichtbare Zeile der Fokuszelle.
    property FocusRow: Integer read FFocusV;
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
    property Columns;
    property ShowFilterRow;
    property SortOnHeaderClick;
    property ScrollBarMode;
    property SmoothScrolling;
    property HighContrastSupport;
    { wie TStringGrid }
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
    property FixedRows;
    property Font;
    property Options;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property RowCount;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop default True;
    property Visible;
    property OnClick;
    property OnCompareCells;
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
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
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
    property OnTopLeftChanged;
    property OnValidateCell;
  end;

implementation

uses
  System.SysUtils, Winapi.oleacc, Vcl.Clipbrd, PPG.UIA.Intf,
  PPG.Consts, PPG.Exceptions, PPG.Appearance, PPG.Tokens, PPG.DpiUtils, PPG.VclStyles,
  PPG.Render.Registry, PPG.Render.Gdi;

const
  CellPadX = 6;      // logische px Text-Abstand links/rechts
  SizeZone = 4;      // logische px Greifzone fuer die Spaltenbreite
  MinColWidth = 8;   // logische px
  FilterRowMark = -2;

type
  TCtrlAccess = class(TPPGCustomControl);

var
  GMsgRowAction: Cardinal = 0;

function EnsureRangeInt(V, Lo, Hi: Integer): Integer;
begin
  Result := V;
  if Result > Hi then
    Result := Hi;
  if Result < Lo then
    Result := Lo;
end;

{ TPPGGridEdit / TPPGGridCombo / TPPGGridSpin }

function TPPGGridEdit.WantSpecialKey(Key: Word): Boolean;
begin
  Result := (Key = VK_RETURN) or (Key = VK_ESCAPE) or (Key = VK_TAB) or
    inherited WantSpecialKey(Key);
end;

function TPPGGridCombo.WantSpecialKey(Key: Word): Boolean;
begin
  Result := (Key = VK_RETURN) or (Key = VK_ESCAPE) or (Key = VK_TAB) or
    inherited WantSpecialKey(Key);
end;

function TPPGGridSpin.WantSpecialKey(Key: Word): Boolean;
begin
  Result := (Key = VK_RETURN) or (Key = VK_ESCAPE) or (Key = VK_TAB) or
    inherited WantSpecialKey(Key);
end;

{ TPPGGridColumn }

constructor TPPGGridColumn.Create(Collection: TCollection);
begin
  FPickList := TStringList.Create;
  FSortable := True;
  inherited Create(Collection);
end;

destructor TPPGGridColumn.Destroy;
begin
  FreeAndNil(FPickList);
  inherited Destroy;
end;

procedure TPPGGridColumn.Assign(Source: TPersistent);
var
  S: TPPGGridColumn;
begin
  if Source is TPPGGridColumn then
  begin
    S := TPPGGridColumn(Source);
    FTitle := S.FTitle;
    FWidth := S.FWidth;
    FAlignment := S.FAlignment;
    FEditorKind := S.FEditorKind;
    FPickList.Assign(S.FPickList);
    FReadOnly := S.FReadOnly;
    FMinValue := S.FMinValue;
    FMaxValue := S.FMaxValue;
    FSortable := S.FSortable;
    Changed(True);
  end
  else
    inherited Assign(Source);
end;

function TPPGGridColumn.GetDisplayName: string;
begin
  if FTitle <> '' then
    Result := FTitle
  else
    Result := inherited GetDisplayName;
end;

procedure TPPGGridColumn.SetTitle(const Value: string);
begin
  if FTitle <> Value then
  begin
    FTitle := Value;
    Changed(False);
  end;
end;

procedure TPPGGridColumn.SetWidth(const Value: Integer);
begin
  if FWidth <> Value then
  begin
    FWidth := PPGCheckRange(Self, 'Width', Value, 0, 10000);
    Changed(True);
  end;
end;

procedure TPPGGridColumn.SetAlignment(const Value: TAlignment);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    Changed(False);
  end;
end;

procedure TPPGGridColumn.SetPickList(const Value: TStrings);
begin
  FPickList.Assign(Value);
end;

{ TPPGGridColumns }

function TPPGGridColumns.Add: TPPGGridColumn;
begin
  Result := TPPGGridColumn(inherited Add);
end;

function TPPGGridColumns.GetItem(Index: Integer): TPPGGridColumn;
begin
  Result := TPPGGridColumn(inherited Items[Index]);
end;

procedure TPPGGridColumns.Update(Item: TCollectionItem);
var
  G: TPPGCustomGrid;
begin
  inherited Update(Item);
  if not (GetOwner is TPPGCustomGrid) then
    Exit;
  G := TPPGCustomGrid(GetOwner);
  if csLoading in G.ComponentState then
    Exit;
  // Spalten bestimmen die Spaltenzahl
  if (Count > 0) and (G.FColCount <> Count) then
    G.ColCount := Count
  else
  begin
    G.InvalidateGeometry;
    G.Invalidate;
  end;
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
  FBorderStyle := bsSingle;
  FSortCol := -1;
  FSortAscending := True;
  FSortOnHeaderClick := True;
  FSizingCol := -1;
  FHeaderDown := -1;
  FEditC := -1;
  FEditV := -1;
  FLastFocusRow := -1;
  FLayout := TPPGRowLayout.Create;
  FColumns := TPPGGridColumns.Create(Self, TPPGGridColumn);
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
end;

destructor TPPGCustomGrid.Destroy;
begin
  FEditor := nil; // gehoert dem Grid (Owner), wird mit ihm freigegeben
  FreeAndNil(FItemCanvas);
  FreeAndNil(FColumns);
  FreeAndNil(FLayout);
  inherited Destroy;
end;

procedure TPPGCustomGrid.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or WS_CLIPCHILDREN; // Editor nie uebermalen
end;

procedure TPPGCustomGrid.Loaded;
begin
  inherited Loaded;
  if (FColumns.Count > 0) and (FColCount <> FColumns.Count) then
    ColCount := FColumns.Count;
  RebuildMap;
  InvalidateGeometry;
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
  I: Integer;
begin
  Reader.ReadListBegin;
  I := 0;
  while not Reader.EndOfList do
  begin
    if I >= Length(FRowHeights) then
      SetLength(FRowHeights, I + 1);
    FRowHeights[I] := Reader.ReadInteger;
    if FRowHeights[I] = FDefaultRowHeight then
      FRowHeights[I] := 0
    else
      FHasRowHeights := True;
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
  V, I: Integer;
begin
  V := PPGCheckRange(Self, 'ColCount', Value, 1, 100000);
  if V = FColCount then
    Exit;
  HideEditor(False);
  FColCount := V;
  SetLength(FColWidths, V);
  SetLength(FFilters, V);
  for I := 0 to High(FCells) do
    if Length(FCells[I]) > V then
      SetLength(FCells[I], V);
  if FFixedCols >= V then
    FFixedCols := V - 1;
  if FFocusC >= V then
    FFocusC := V - 1;
  if FAnchorC >= V then
    FAnchorC := V - 1;
  if FSortCol >= V then
    FSortCol := -1;
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
  if Length(FCells) > V then
    SetLength(FCells, V);
  if Length(FRowHeights) > V then
    SetLength(FRowHeights, V);
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
    if FFocusC < V then
      FFocusC := V;
    if FAnchorC < V then
      FAnchorC := V;
    InvalidateGeometry;
  end;
end;

procedure TPPGCustomGrid.SetFixedRows(const Value: Integer);
var
  V: Integer;
begin
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
    raise EPPGError.CreateResFmt(@SPPGIndexOutOfRange, [Index, FColCount - 1]);
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
    raise EPPGError.CreateResFmt(@SPPGIndexOutOfRange, [Index, FColCount - 1]);
  V := PPGCheckRange(Self, 'ColWidths', Value, 0, 10000);
  C := ColumnOf(Index);
  if C <> nil then
    C.Width := V
  else
    FColWidths[Index] := V;
  InvalidateGeometry;
end;

function TPPGCustomGrid.GetRowHeights(Index: Integer): Integer;
begin
  if (Index < 0) or (Index >= FRowCount) then
    raise EPPGError.CreateResFmt(@SPPGIndexOutOfRange, [Index, FRowCount - 1]);
  if (Index < Length(FRowHeights)) and (FRowHeights[Index] > 0) then
    Result := FRowHeights[Index]
  else
    Result := FDefaultRowHeight;
end;

procedure TPPGCustomGrid.SetRowHeights(Index: Integer; const Value: Integer);
var
  V: Integer;
begin
  if (Index < 0) or (Index >= FRowCount) then
    raise EPPGError.CreateResFmt(@SPPGIndexOutOfRange, [Index, FRowCount - 1]);
  V := PPGCheckRange(Self, 'RowHeights', Value, 0, 10000);
  if Length(FRowHeights) < FRowCount then
    SetLength(FRowHeights, FRowCount);
  FRowHeights[Index] := V;
  if (V > 0) and (V <> FDefaultRowHeight) then
    FHasRowHeights := True;
  InvalidateGeometry;
end;

{ ---- Zellen ---- }

procedure TPPGCustomGrid.CheckCell(ACol, ARow: Integer);
begin
  if (ACol < 0) or (ACol >= FColCount) then
    raise EPPGError.CreateResFmt(@SPPGIndexOutOfRange, [ACol, FColCount - 1]);
  if (ARow < 0) or (ARow >= FRowCount) then
    raise EPPGError.CreateResFmt(@SPPGIndexOutOfRange, [ARow, FRowCount - 1]);
end;

procedure TPPGCustomGrid.EnsureCellStorage(ARow: Integer);
begin
  if Length(FCells) <= ARow then
    SetLength(FCells, ARow + 1);
  if Length(FCells[ARow]) < FColCount then
    SetLength(FCells[ARow], FColCount);
end;

function TPPGCustomGrid.GetCells(ACol, ARow: Integer): string;
begin
  CheckCell(ACol, ARow);
  if (ARow < Length(FCells)) and (ACol < Length(FCells[ARow])) then
    Result := FCells[ARow][ACol]
  else
    Result := '';
end;

procedure TPPGCustomGrid.SetCells(ACol, ARow: Integer; const Value: string);
begin
  CheckCell(ACol, ARow);
  EnsureCellStorage(ARow);
  if FCells[ARow][ACol] = Value then
    Exit;
  FCells[ARow][ACol] := Value;
  Invalidate;
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
  Result := '';
  if (ARow < Length(FCells)) and (ACol < Length(FCells[ARow])) then
    Result := FCells[ARow][ACol];
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

procedure TPPGCustomGrid.SetCellByUser(ACol, ARow: Integer; const Value: string);
begin
  EnsureCellStorage(ARow);
  FCells[ARow][ACol] := Value;
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
    raise EPPGError.CreateResFmt(@SPPGIndexOutOfRange, [ACol, FColCount - 1]);
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
  if FMapped then
    Result := VFixedRows + Length(FRowMap)
  else
    Result := VFixedRows + (FRowCount - FFixedRows);
end;

function TPPGCustomGrid.DataRow(VRow: Integer): Integer;
var
  I: Integer;
begin
  if VRow < FFixedRows then
    Result := VRow
  else if FShowFilterRow and (VRow = FFixedRows) then
    Result := FilterRowMark
  else
  begin
    I := VRow - VFixedRows;
    if FMapped then
    begin
      if (I >= 0) and (I < Length(FRowMap)) then
        Result := FRowMap[I]
      else
        Result := -1;
    end
    else if (I >= 0) and (I < FRowCount - FFixedRows) then
      Result := FFixedRows + I
    else
      Result := -1;
  end;
end;

function TPPGCustomGrid.VisualRow(ARow: Integer): Integer;
begin
  if (ARow < 0) or (ARow >= FRowCount) then
    Result := -1
  else if ARow < FFixedRows then
    Result := ARow
  else if FMapped then
  begin
    if (ARow < Length(FInvMap)) and (FInvMap[ARow] >= 0) then
      Result := VFixedRows + FInvMap[ARow]
    else
      Result := -1;
  end
  else
    Result := VFixedRows + ARow - FFixedRows;
end;

function TPPGCustomGrid.RowPassesFilter(ARow: Integer): Boolean;
var
  C: Integer;
begin
  Result := True;
  for C := 0 to High(FFilters) do
    if (FFilters[C] <> '') and
      (Pos(AnsiUpperCase(FFilters[C]), AnsiUpperCase(GetCellText(C, ARow))) = 0) then
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
  I, N, FocusData: Integer;
  Tmp: array of Integer;

  procedure MergeSort(L, R: Integer);
  var
    M, I1, I2, K, C: Integer;
  begin
    if R - L < 1 then
      Exit;
    M := (L + R) div 2;
    MergeSort(L, M);
    MergeSort(M + 1, R);
    I1 := L;
    I2 := M + 1;
    K := L;
    while (I1 <= M) and (I2 <= R) do
    begin
      C := CompareDataRows(FSortCol, FRowMap[I1], FRowMap[I2]);
      if not FSortAscending then
        C := -C;
      // stabil: bei Gleichheit links zuerst
      if C <= 0 then
      begin
        Tmp[K] := FRowMap[I1];
        Inc(I1);
      end
      else
      begin
        Tmp[K] := FRowMap[I2];
        Inc(I2);
      end;
      Inc(K);
    end;
    while I1 <= M do
    begin
      Tmp[K] := FRowMap[I1];
      Inc(I1);
      Inc(K);
    end;
    while I2 <= R do
    begin
      Tmp[K] := FRowMap[I2];
      Inc(I2);
      Inc(K);
    end;
    for K := L to R do
      FRowMap[K] := Tmp[K];
  end;

begin
  if FLayout = nil then
    Exit;
  FocusData := DataRow(FFocusV);
  Filtered := False;
  for I := 0 to High(FFilters) do
    if FFilters[I] <> '' then
      Filtered := True;
  FMapped := Filtered or (FSortCol >= 0);
  if FMapped then
  begin
    SetLength(FRowMap, FRowCount - FFixedRows);
    N := 0;
    for I := FFixedRows to FRowCount - 1 do
      if not Filtered or RowPassesFilter(I) then
      begin
        FRowMap[N] := I;
        Inc(N);
      end;
    SetLength(FRowMap, N);
    if (FSortCol >= 0) and (N > 1) then
    begin
      SetLength(Tmp, N);
      MergeSort(0, N - 1);
      SetLength(Tmp, 0);
    end;
    SetLength(FInvMap, FRowCount);
    for I := 0 to FRowCount - 1 do
      FInvMap[I] := -1;
    for I := 0 to N - 1 do
      FInvMap[FRowMap[I]] := I;
  end
  else
  begin
    SetLength(FRowMap, 0);
    SetLength(FInvMap, 0);
  end;
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

{ ---- Geometrie ---- }

procedure TPPGCustomGrid.InvalidateGeometry;
begin
  FGeomValid := False;
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
  I, X, V, D, H, Def: Integer;
  PPI: Integer;
begin
  PPI := ScalePPI;
  if FGeomValid and (FGeomPPI = PPI) then
    Exit;
  FGeomValid := True;
  FGeomPPI := PPI;
  SetLength(FColX, FColCount + 1);
  X := 0;
  for I := 0 to FColCount - 1 do
  begin
    FColX[I] := X;
    Inc(X, ColPixelWidth(I));
  end;
  FColX[FColCount] := X;
  Def := PPGScale(FDefaultRowHeight, PPI);
  FLayout.Count := 0;
  FLayout.DefaultHeight := Def;
  FLayout.Count := VRowCount;
  if FHasRowHeights then
    for V := 0 to FLayout.Count - 1 do
    begin
      D := DataRow(V);
      if D >= 0 then
      begin
        H := PPGScale(GetRowHeights(D), PPI);
        if H <> Def then
          FLayout.SetRowHeight(V, H);
      end;
    end;
  if FLayout.TotalHeight64 > MaxInt then
    SetContentSize(X, MaxInt)
  else
    SetContentSize(X, FLayout.TotalHeight);
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
  if (ACol < 0) or (ACol >= FColCount) or (VRow < 0) or (VRow >= FLayout.Count) then
    Exit;
  V := ViewRect;
  X := FColX[ACol];
  if ACol >= FFixedCols then
    X := X - ScrollX;
  Y := FLayout.RowTop(VRow);
  if VRow >= VFixedRows then
    Y := Y - ScrollY;
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
  CX: Integer;
  CY: Int64;
  I: Integer;
begin
  Result := False;
  ACol := -1;
  VRow := -1;
  EnsureGeometry;
  V := ViewRect;
  if not PtInRect(V, Point(X, Y)) then
    Exit;
  if UseRightToLeftAlignment then
    X := V.Left + V.Right - X - 1;
  CX := X - V.Left;
  if CX >= FixedWidth then
    Inc(CX, ScrollX);
  for I := 0 to FColCount - 1 do
    if (CX >= FColX[I]) and (CX < FColX[I + 1]) then
    begin
      ACol := I;
      Break;
    end;
  CY := Y - V.Top;
  if CY >= FixedHeight then
    Inc(CY, ScrollY);
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
  if (ACol < 0) or (ACol >= FColCount) or (VRow < 0) or (VRow >= FLayout.Count) then
    Exit;
  V := ViewRect;
  X := ScrollX;
  Y := ScrollY;
  VW := (V.Right - V.Left) - FixedWidth;
  VH := (V.Bottom - V.Top) - FixedHeight;
  if ACol >= FFixedCols then
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
  ScrollTo(X, Y);
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
  InvalidateGeometry;
end;

{ ---- Farben und Zeichnen ---- }

procedure TPPGCustomGrid.GetGridColors(out Fill, Text, Header, Line, Accent: TColor);
var
  T: TPPGTokens;
  SelFill, SelText: TColor;
begin
  Accent := PPGColorToRGB(EffectiveAppearance.FocusColor);
  if HighContrastSupport and PPGIsHighContrast then
  begin
    Fill := PPGColorToRGB(clWindow);
    Text := PPGColorToRGB(clWindowText);
    Header := PPGColorToRGB(clBtnFace);
    Line := PPGColorToRGB(clWindowText);
    Accent := PPGColorToRGB(clHighlight);
    if not Enabled then
      Text := PPGColorToRGB(clGrayText);
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

function TPPGCustomGrid.CellEditorKind(ACol, ARow: Integer): TPPGGridEditorKind;
var
  C: TPPGGridColumn;
begin
  C := ColumnOf(ACol);
  if C = nil then
    Result := gekText
  else
    Result := C.EditorKind;
end;

function TPPGCustomGrid.RawCellRect(ACol, VRow: Integer): TRect;
var
  V: TRect;
  X, Y: Int64;
begin
  // Wie CellRect, aber ohne Sichtbarkeitspruefung (fuer Auswahl-Rechtecke)
  V := ViewRect;
  X := FColX[ACol];
  if ACol >= FFixedCols then
    X := X - ScrollX;
  Y := FLayout.RowTop(VRow);
  if VRow >= VFixedRows then
    Y := Y - ScrollY;
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
  Checked: Boolean;
  Ind: IPPGIndicatorRenderer;
  A: TPPGAppearance;
  St: TPPGSurfaceStyle;
  IR2, LR: TRect;
  LRen: IPPGListRenderer;
  D: Integer;
begin
  PPI := ScalePPI;
  D := DataRow(VRow);
  // Kaestchen-Spalte
  if (D >= FFixedRows) and (ACol >= FFixedCols) and (CellEditorKind(ACol, D) = gekCheck) then
  begin
    Checked := (S = '1') or SameText(S, 'True') or SameText(S, 'Ja');
    if not Supports(Renderer, IPPGIndicatorRenderer, Ind) then
      Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
        IPPGIndicatorRenderer, Ind);
    A := EffectiveAppearance;
    if Checked then
      St := A.ResolveStyle(A.Checked, PPI, False)
    else
      St := A.Resolve(vsNormal, PPI, False);
    St.GlowAlpha := 0;
    St.GlowSize := 0;
    IR2.Left := (R.Left + R.Right - PPGScale(16, PPI)) div 2;
    IR2.Top := (R.Top + R.Bottom - PPGScale(16, PPI)) div 2;
    IR2.Right := IR2.Left + PPGScale(16, PPI);
    IR2.Bottom := IR2.Top + PPGScale(16, PPI);
    if Checked then
      Ind.DrawCheckIndicator(ACanvas, IR2, St, cbChecked, PPI)
    else
      Ind.DrawCheckIndicator(ACanvas, IR2, St, cbUnchecked, PPI);
  end;
  // Sortierpfeil in der Kopfzeile
  if (D = 0) and (FFixedRows > 0) and (ACol = FSortCol) then
  begin
    if not Supports(Renderer, IPPGListRenderer, LRen) then
      Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
        IPPGListRenderer, LRen);
    LR := R;
    if UseRightToLeftAlignment then
      LR.Right := LR.Left + PPGScale(18, PPI)
    else
      LR.Left := LR.Right - PPGScale(18, PPI);
    LRen.DrawDropArrow(ACanvas, LR, PPGBlendColor(FPaint.Text, FPaint.Header, 0.3),
      Ord(FSortAscending), PPI);
  end;
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
  // Linien und (bei DefaultDrawing) Text sind schon gezeichnet
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
        FOnDrawCell(Self, ACol, D, R, State);
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

procedure GdiFill(DC: HDC; const R: TRect; Color: TColor);
var
  B: HBRUSH;
begin
  if IsRectEmpty(R) then
    Exit;
  B := CreateSolidBrush(ColorToRGB(Color));
  if B = 0 then
    Exit;
  try
    Winapi.Windows.FillRect(DC, R, B);
  finally
    DeleteObject(B);
  end;
end;

procedure TPPGCustomGrid.PaintRegion(const ACanvas: IPPGCanvas; ColFrom, ColTo,
  RowFrom, RowTo: Integer; const AClip: TRect; FixedArea: Boolean);
var
  Clip, BR: TRect;
  C, V, D, Pad, PPI, I, N, NX: Integer;
  R, LR, SR, TR: TRect;
  Sl: TGridRect;
  Texts: array of string;
  Rects: array of TRect;
  Colors: array of TColor;
  FlagsArr: array of Cardinal;
  ExtraC, ExtraV: array of Integer;
  ExtraS: array of string;
  S: string;
  TC, LastColor: TColor;
  Flags: Cardinal;
  Col: TPPGGridColumn;
  DC: HDC;
  LineBrush: HBRUSH;
  VLine, HLine, IsCheck: Boolean;
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
  ACanvas.PushClipRoundRect(Clip, 0);
  try
    // 1. Hintergrund (deckend, GDI)
    DC := ACanvas.BeginGdi;
    try
      if FixedArea then
        GdiFill(DC, Clip, FPaint.Header)
      else
        GdiFill(DC, Clip, FPaint.Fill);
    finally
      ACanvas.EndGdi(DC);
    end;
    // 2. Auswahl als ein halbtransparentes Rechteck (nur Datenzellen)
    if not FixedArea and (ColFrom >= FFixedCols) then
    begin
      Sl := GetSelection;
      if (Sl.Right >= ColFrom) and (Sl.Left <= ColTo) and (Sl.Bottom >= RowFrom) and
        (Sl.Top <= RowTo) and (Sl.Top >= VFixedRows) then
      begin
        SR := RawCellRect(Sl.Left, Sl.Top);
        LR := RawCellRect(Sl.Right, Sl.Bottom);
        UnionRect(SR, SR, LR);
        IntersectRect(SR, SR, Clip);
        if not IsRectEmpty(SR) then
        begin
          if Focused then
            ACanvas.FillRoundRect(SR, 0, FPaint.Accent, 46)
          else
            ACanvas.FillRoundRect(SR, 0, FPaint.Text, 22);
        end;
      end;
    end;
    // 3. Texte sammeln (Kaestchen/Sortierpfeil merken)
    N := 0;
    NX := 0;
    I := (ColTo - ColFrom + 1) * (RowTo - RowFrom + 1);
    SetLength(Texts, I);
    SetLength(Rects, I);
    SetLength(Colors, I);
    SetLength(FlagsArr, I);
    SetLength(ExtraC, I);
    SetLength(ExtraV, I);
    SetLength(ExtraS, I);
    for V := RowFrom to RowTo do
    begin
      D := DataRow(V);
      for C := ColFrom to ColTo do
      begin
        TC := FPaint.Text;
        if D = FilterRowMark then
        begin
          S := GetFilter(C);
          if S = '' then
          begin
            S := SPPGGridFilterHint;
            TC := FPaint.Hint;
          end;
        end
        else if D >= 0 then
          S := GetCellText(C, D)
        else
          S := '';
        IsCheck := (D >= FFixedRows) and (C >= FFixedCols) and (CellEditorKind(C, D) = gekCheck);
        if IsCheck or ((D = 0) and (FFixedRows > 0) and (C = FSortCol)) then
        begin
          ExtraC[NX] := C;
          ExtraV[NX] := V;
          ExtraS[NX] := S;
          Inc(NX);
          if IsCheck then
            Continue; // Kaestchen statt Text
        end;
        if (S = '') or not FDefaultDrawing then
          Continue;
        R := RawCellRect(C, V);
        TR := R;
        InflateRect(TR, -Pad, 0);
        if (D = 0) and (C = FSortCol) then
          if UseRightToLeftAlignment then
            Inc(TR.Left, PPGScale(14, PPI))
          else
            Dec(TR.Right, PPGScale(14, PPI));
        Flags := DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS;
        Col := ColumnOf(C);
        if Col <> nil then
          case Col.Alignment of
            taRightJustify: Flags := Flags or DT_RIGHT;
            taCenter: Flags := Flags or DT_CENTER;
          end;
        Rects[N] := TR;
        FlagsArr[N] := DrawTextBiDiModeFlags(Flags);
        Texts[N] := S;
        Colors[N] := TC;
        Inc(N);
      end;
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
    DC := ACanvas.BeginGdi;
    try
      LineBrush := CreateSolidBrush(ColorToRGB(FPaint.Line));
      if LineBrush <> 0 then
      try
        if VLine then
          for C := ColFrom to ColTo do
          begin
            R := RawCellRect(C, RowFrom);
            if UseRightToLeftAlignment then
              LR := Rect(R.Left, Clip.Top, R.Left + 1, Clip.Bottom)
            else
              LR := Rect(R.Right - 1, Clip.Top, R.Right, Clip.Bottom);
            Winapi.Windows.FillRect(DC, LR, LineBrush);
          end;
        if HLine then
          for V := RowFrom to RowTo do
          begin
            R := RawCellRect(ColFrom, V);
            LR := Rect(Clip.Left, R.Bottom - 1, Clip.Right, R.Bottom);
            Winapi.Windows.FillRect(DC, LR, LineBrush);
          end;
      finally
        DeleteObject(LineBrush);
      end;
      if N > 0 then
      begin
        SelectObject(DC, Font.Handle);
        SetBkMode(DC, TRANSPARENT);
        LastColor := clNone;
        for I := 0 to N - 1 do
        begin
          if Colors[I] <> LastColor then
          begin
            SetTextColor(DC, ColorToRGB(Colors[I]));
            LastColor := Colors[I];
          end;
          TR := Rects[I];
          Winapi.Windows.DrawText(DC, PChar(Texts[I]), Length(Texts[I]), TR, FlagsArr[I]);
        end;
      end;
    finally
      ACanvas.EndGdi(DC); // stellt Schrift, Farbe und Modus wieder her
    end;
    // 5. Kaestchen und Sortierpfeil (Preset-Renderer)
    for I := 0 to NX - 1 do
      DrawCellExtras(ACanvas, ExtraC[I], ExtraV[I], RawCellRect(ExtraC[I], ExtraV[I]),
        ExtraS[I]);
    // 6. Fokuszelle und Owner-Draw
    if not FixedArea and FocusVisible and (FFocusC >= ColFrom) and (FFocusC <= ColTo) and
      (FFocusV >= RowFrom) and (FFocusV <= RowTo) then
    begin
      LR := RawCellRect(FFocusC, FFocusV);
      InflateRect(LR, -1, -1);
      ACanvas.FrameRoundRect(LR, PPGScale(2, PPI), PPGScale(2, PPI), FPaint.Accent, 255);
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
  FW, FH, C0, C1, R0, R1: Integer;
  CX: Integer;
  CY: Int64;
  Region: TRect;
begin
  EnsureGeometry;
  if (FColCount = 0) or (FLayout.Count = 0) then
    Exit;
  // Farben einmal pro Zeichnen (nicht je Zelle)
  GetGridColors(FPaint.Fill, FPaint.Text, FPaint.Header, FPaint.Line, FPaint.Accent);
  FPaint.Hint := PPGBlendColor(FPaint.Text, FPaint.Header, 0.55);
  FW := FixedWidth;
  FH := FixedHeight;
  // Sichtbare scrollbare Spalten/Zeilen
  CX := ScrollX + FW;
  C0 := FFixedCols;
  while (C0 < FColCount - 1) and (FColX[C0 + 1] <= CX) do
    Inc(C0);
  C1 := C0;
  while (C1 < FColCount - 1) and (FColX[C1 + 1] < CX + (View.Right - View.Left) - FW) do
    Inc(C1);
  CY := Int64(ScrollY) + FH;
  if CY >= FLayout.TotalHeight64 then
    R0 := FLayout.Count
  else
    R0 := FLayout.RowAt(CY);
  if R0 < VFixedRows then
    R0 := VFixedRows;
  R1 := R0;
  while (R1 < FLayout.Count - 1) and
    (FLayout.RowTop(R1 + 1) < CY + (View.Bottom - View.Top) - FH) do
    Inc(R1);
  if R0 >= FLayout.Count then
    R1 := R0 - 1; // keine Datenzeilen sichtbar
  // Bereiche: Daten, Kopfzeilen, Kopfspalten, Ecke (RTL gespiegelt)
  if UseRightToLeftAlignment then
  begin
    Region := Rect(View.Left, View.Top + FH, View.Right - FW, View.Bottom);
    PaintRegion(ACanvas, C0, C1, R0, R1, Region, False);
    Region := Rect(View.Left, View.Top, View.Right - FW, View.Top + FH);
    PaintRegion(ACanvas, C0, C1, 0, VFixedRows - 1, Region, True);
    Region := Rect(View.Right - FW, View.Top + FH, View.Right, View.Bottom);
    PaintRegion(ACanvas, 0, FFixedCols - 1, R0, R1, Region, True);
    Region := Rect(View.Right - FW, View.Top, View.Right, View.Top + FH);
  end
  else
  begin
    Region := Rect(View.Left + FW, View.Top + FH, View.Right, View.Bottom);
    PaintRegion(ACanvas, C0, C1, R0, R1, Region, False);
    Region := Rect(View.Left + FW, View.Top, View.Right, View.Top + FH);
    PaintRegion(ACanvas, C0, C1, 0, VFixedRows - 1, Region, True);
    Region := Rect(View.Left, View.Top + FH, View.Left + FW, View.Bottom);
    PaintRegion(ACanvas, 0, FFixedCols - 1, R0, R1, Region, True);
    Region := Rect(View.Left, View.Top, View.Left + FW, View.Top + FH);
  end;
  PaintRegion(ACanvas, 0, FFixedCols - 1, 0, VFixedRows - 1, Region, True);
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
    if HighContrastSupport and PPGIsHighContrast then
      S.BorderColor := PPGColorToRGB(clWindowText);
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
    Result.Right := FColCount - 1;
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
  FAnchorC := EnsureRangeInt(Value.Left, FFixedCols, FColCount - 1);
  FAnchorV := EnsureRangeInt(Value.Top, VFixedRows, VRowCount - 1);
  FFocusC := EnsureRangeInt(Value.Right, FFixedCols, FColCount - 1);
  FFocusV := EnsureRangeInt(Value.Bottom, VFixedRows, VRowCount - 1);
  Invalidate;
end;

procedure TPPGCustomGrid.SelectAll;
begin
  if not (goRangeSelect in FOptions) then
    Exit;
  FAnchorC := FFixedCols;
  FAnchorV := VFixedRows;
  FFocusC := FColCount - 1;
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
  D: Integer;
begin
  Result := False;
  ACol := EnsureRangeInt(ACol, FFixedCols, FColCount - 1);
  VRow := EnsureRangeInt(VRow, VFixedRows, VRowCount - 1);
  if (ACol < FFixedCols) or (VRow < VFixedRows) then
    Exit;
  D := DataRow(VRow);
  if ((ACol <> FFocusC) or (VRow <> FFocusV)) and not SelectCell(ACol, D) then
    Exit;
  HideEditor(True);
  FFocusC := ACol;
  FFocusV := VRow;
  if not Extend or not (goRangeSelect in FOptions) then
  begin
    FAnchorC := ACol;
    FAnchorV := VRow;
  end;
  MakeCellVisible(ACol, VRow);
  Invalidate;
  if HandleAllocated and Focused and (VRow <> FLastFocusRow) then
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, VRow + 1);
  FLastFocusRow := VRow;
  if ByUser then
    Click;
  Result := True;
end;

function TPPGCustomGrid.GetRow: Integer;
begin
  Result := DataRow(FFocusV);
end;

procedure TPPGCustomGrid.SetRow(const Value: Integer);
var
  V: Integer;
begin
  V := VisualRow(Value);
  if V >= VFixedRows then
    MoveFocus(FFocusC, V, False, False);
end;

procedure TPPGCustomGrid.SetCol(const Value: Integer);
begin
  if (Value >= FFixedCols) and (Value < FColCount) then
    MoveFocus(Value, FFocusV, False, False);
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
  end;
  inherited;
end;

procedure TPPGCustomGrid.ContentMouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  C, V, S: Integer;
  R, B: TRect;
begin
  if (Button = mbLeft) and CanFocus and not Focused and HandleAllocated and
    IsWindowVisible(Handle) and IsWindowEnabled(Handle) and
    not (csDesigning in ComponentState) then
    SetFocus;
  if Button <> mbLeft then
    Exit;
  S := SizingColAt(X, Y);
  if S >= 0 then
  begin
    HideEditor(True);
    FSizingCol := S;
    FSizingStartX := X;
    FSizingStartW := ColPixelWidth(S);
    Exit;
  end;
  if not MouseCoord(X, Y, C, V) then
    Exit;
  if DataRow(V) = FilterRowMark then
  begin
    // Filterzeile: Klick bearbeitet den Filter der Spalte
    HideEditor(True);
    FFocusC := EnsureRangeInt(C, FFixedCols, FColCount - 1);
    FEditC := FFocusC;
    FEditV := V;
    ShowEditor;
    Exit;
  end;
  if (V < FFixedRows) or (C < FFixedCols) then
  begin
    FHeaderDown := C;
    FHeaderDownPos := Point(X, Y);
    if V >= FFixedRows then
      FHeaderDown := -1;
    if Assigned(FOnFixedCellClick) then
      FOnFixedCellClick(Self, C, DataRow(V));
    Exit;
  end;
  // Kaestchen-Zelle: Klick schaltet direkt um
  if (CellEditorKind(C, DataRow(V)) = gekCheck) and (Shift * [ssShift, ssCtrl] = []) then
  begin
    MoveFocus(C, V, False, True);
    R := CellRect(C, V);
    B := Rect((R.Left + R.Right) div 2 - PPGScale(10, ScalePPI), R.Top,
      (R.Left + R.Right) div 2 + PPGScale(10, ScalePPI), R.Bottom);
    if PtInRect(B, Point(X, Y)) then
      ToggleCheck(C, V);
    Exit;
  end;
  MoveFocus(C, V, ssShift in Shift, True);
  FMouseSel := goRangeSelect in FOptions;
end;

procedure TPPGCustomGrid.ContentMouseMove(Shift: TShiftState; X, Y: Integer);
var
  C, V, W: Integer;
begin
  if FSizingCol >= 0 then
  begin
    if UseRightToLeftAlignment then
      W := FSizingStartW - (X - FSizingStartX)
    else
      W := FSizingStartW + (X - FSizingStartX);
    W := MulDiv(W, 96, ScalePPI); // logisch speichern
    if W < MinColWidth then
      W := MinColWidth;
    if W <> GetColWidths(FSizingCol) then
      ColWidths[FSizingCol] := W;
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
  // Klick (ohne Ziehen) auf den Spaltenkopf sortiert
  if (FHeaderDown >= 0) and MouseCoord(X, Y, C, V) and (C = FHeaderDown) and (V < FFixedRows) then
    HeaderClicked(C, V);
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
  end;
end;

procedure TPPGCustomGrid.DblClick;
begin
  inherited DblClick;
  if CanEditCell(FFocusC, FFocusV) and (CellEditorKind(FFocusC, DataRow(FFocusV)) <> gekCheck) then
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
  if (S = '1') or SameText(S, 'True') or SameText(S, 'Ja') then
    SetCellByUser(ACol, D, '0')
  else
    SetCellByUser(ACol, D, '1');
end;

{ ---- Tastatur ---- }

procedure TPPGCustomGrid.KeyDown(var Key: Word; Shift: TShiftState);
var
  C, V, Page, PageRows: Integer;
  Ext: Boolean;
  VR: TRect;
begin
  C := FFocusC;
  V := FFocusV;
  Ext := ssShift in Shift;
  VR := ViewRect;
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
        C := FColCount - 1;
        V := VRowCount - 1;
      end
      else
        C := FColCount - 1;
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
      begin
        inherited KeyDown(Key, Shift);
        Exit;
      end;
    VK_F2, VK_RETURN:
      begin
        if CanEditCell(FFocusC, FFocusV) then
        begin
          if CellEditorKind(FFocusC, DataRow(FFocusV)) = gekCheck then
            ToggleCheck(FFocusC, FFocusV)
          else
            ShowEditor;
        end;
        Key := 0;
        Exit;
      end;
    VK_SPACE:
      begin
        if CellEditorKind(FFocusC, DataRow(FFocusV)) = gekCheck then
        begin
          ToggleCheck(FFocusC, FFocusV);
          Key := 0;
        end;
        Exit;
      end;
    Ord('C'), VK_INSERT:
      if ssCtrl in Shift then
      begin
        CopyToClipboard;
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
    begin
      inherited KeyDown(Key, Shift);
      Exit;
    end;
  end;
  MoveFocus(C, V, Ext, True);
  Key := 0;
end;

procedure TPPGCustomGrid.KeyPress(var Key: Char);
var
  K: Char;
begin
  inherited KeyPress(Key);
  // Tippen startet den Editor mit dem Zeichen (wie Excel/TStringGrid)
  if (Key >= ' ') and CanEditCell(FFocusC, FFocusV) and
    (CellEditorKind(FFocusC, DataRow(FFocusV)) = gekText) then
  begin
    K := Key;
    Key := #0;
    ShowEditor;
    if FEditor is TPPGGridEdit then
    begin
      TPPGGridEdit(FEditor).Text := K;
      TPPGGridEdit(FEditor).SelStart := 1;
    end;
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
  D, V: Integer;
  R: TRect;
  S: string;
  Col: TPPGGridColumn;
  E: TPPGCustomControl;
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
  if not CanEditCell(FEditC, V) then
  begin
    FEditC := -1;
    FEditV := -1;
    Exit;
  end;
  if D = FilterRowMark then
  begin
    Kind := gekText;
    S := GetFilter(FEditC);
  end
  else
  begin
    Kind := CellEditorKind(FEditC, D);
    if Kind = gekCheck then
    begin
      FEditC := -1;
      FEditV := -1;
      Exit;
    end;
    S := GetCellText(FEditC, D);
    if Assigned(FOnGetEditText) then
      FOnGetEditText(Self, FEditC, D, S);
  end;
  MakeCellVisible(FEditC, V);
  R := CellRect(FEditC, V);
  if IsRectEmpty(R) then
    Exit;
  // Editor passender Art (wiederverwendet, solange die Art gleich bleibt)
  if (FEditor <> nil) and (FEditKind <> Kind) then
  begin
    FEditor.Visible := False;
    FreeAndNil(FEditor);
  end;
  Col := ColumnOf(FEditC);
  if FEditor = nil then
  begin
    case Kind of
      gekCombo: E := TPPGGridCombo.Create(Self);
      gekSpin: E := TPPGGridSpin.Create(Self);
    else
      E := TPPGGridEdit.Create(Self);
    end;
    E.Visible := False;
    E.Parent := Self;
    TCtrlAccess(E).Preset := Preset;
    TCtrlAccess(E).Animation.Enabled := False;
    if E is TPPGGridEdit then
    begin
      TPPGGridEdit(E).AutoSize := False;
      TPPGGridEdit(E).OnKeyDown := EditorKeyDown;
      TPPGGridEdit(E).OnExit := EditorExit;
    end
    else if E is TPPGGridCombo then
    begin
      TPPGGridCombo(E).AutoSize := False;
      TPPGGridCombo(E).OnKeyDown := EditorKeyDown;
      TPPGGridCombo(E).OnExit := EditorExit;
    end
    else if E is TPPGGridSpin then
    begin
      TPPGGridSpin(E).AutoSize := False;
      TPPGGridSpin(E).OnKeyDown := EditorKeyDown;
      TPPGGridSpin(E).OnExit := EditorExit;
    end;
    FEditor := E;
    FEditKind := Kind;
  end;
  TCtrlAccess(FEditor).Font := Font;
  FEditor.BoundsRect := R;
  if FEditor is TPPGGridEdit then
  begin
    TPPGGridEdit(FEditor).Text := S;
    TPPGGridEdit(FEditor).SelectAll;
  end
  else if FEditor is TPPGGridCombo then
  begin
    if Col <> nil then
      TPPGGridCombo(FEditor).Items.Assign(Col.PickList);
    TPPGGridCombo(FEditor).Text := S;
  end
  else if FEditor is TPPGGridSpin then
  begin
    if Col <> nil then
    begin
      TPPGGridSpin(FEditor).MinValue := Col.MinValue;
      TPPGGridSpin(FEditor).MaxValue := Col.MaxValue;
    end;
    TPPGGridSpin(FEditor).Value := StrToIntDef(S, 0);
  end;
  FEditCanceled := False;
  FEditor.Visible := True;
  if FEditor.CanFocus then
    FEditor.SetFocus;
end;

function TPPGCustomGrid.EditorText: string;
begin
  if FEditor is TPPGGridEdit then
    Result := TPPGGridEdit(FEditor).Text
  else if FEditor is TPPGGridCombo then
    Result := TPPGGridCombo(FEditor).Text
  else if FEditor is TPPGGridSpin then
    Result := IntToStr(TPPGGridSpin(FEditor).Value)
  else
    Result := '';
end;

procedure TPPGCustomGrid.HideEditor(Accept: Boolean);
var
  C, V, D: Integer;
  S: string;
  Ok, HadFocus: Boolean;
begin
  if (FEditor = nil) or not FEditor.Visible or (FEditV < 0) then
  begin
    FEditC := -1;
    FEditV := -1;
    Exit;
  end;
  C := FEditC;
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
  HadFocus := FEditor.Focused or FEditor.ContainsControl(FindControl(GetFocus));
  FEditor.Visible := False;
  if HadFocus and CanFocus and HandleAllocated and IsWindowVisible(Handle) then
    SetFocus;
  if not Accept then
    Exit;
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
end;

procedure TPPGCustomGrid.EditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      begin
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
      if Sender is TPPGGridEdit then
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
        SB.Append(StringReplace(StringReplace(GetCellText(C, D), #9, ' ', [rfReplaceAll]),
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
        if C >= FColCount then
          Break;
        if CanEditCell(C, V) then
          SetCellByUser(C, D, Cells[J]);
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
      for C := 0 to FColCount - 1 do
      begin
        if C > 0 then
          SB.Append(Separator);
        SB.Append(Quote(GetCellText(C, D)));
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
    Result := GetCellText(FFocusC, D)
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
  if D < 0 then
    Exit;
  for C := 0 to FColCount - 1 do
  begin
    if C > 0 then
      Result := Result + '; ';
    Result := Result + GetCellText(C, D);
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
  B := CellRect(FColCount - 1, Id - 1);
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
  Result := SPPGAccSelect;
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
  else
    Result := -1;
  end;
end;

function TPPGCustomGrid.UiaCellId(ACol, VRow: Integer): TPPGUiaId;
var
  D: Integer;
begin
  Result := PPGUiaId(0);
  if (ACol < 0) or (ACol >= FColCount) or (VRow < 0) or (VRow >= VRowCount) then
    Exit;
  if VRow < FFixedRows then
    Exit(PPGUiaId(PPGUiaKindGridHeaderCell, VRow, ACol));
  D := DataRow(VRow);
  if D >= FFixedRows then
    Result := PPGUiaId(PPGUiaKindGridCell, D, ACol);
end;

function TPPGCustomGrid.UiaValid(const Id: TPPGUiaId): Boolean;
begin
  case Id.Kind of
    0: Result := True;
    PPGUiaKindGridRow, PPGUiaKindGridHeaderRow:
      Result := UiaVRow(Id) >= 0;
    PPGUiaKindGridCell, PPGUiaKindGridHeaderCell:
      Result := (UiaVRow(Id) >= 0) and (Id.B >= 0) and (Id.B < FColCount);
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
    PPGUiaKindGridRow, PPGUiaKindGridHeaderRow: Result := FColCount;
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
          Result := PPGUiaId(PPGUiaKindGridRow, D);
      end;
    PPGUiaKindGridRow:
      if Index < FColCount then
        Result := PPGUiaId(PPGUiaKindGridCell, Id.A, Index);
    PPGUiaKindGridHeaderRow:
      if Index < FColCount then
        Result := PPGUiaId(PPGUiaKindGridHeaderCell, Id.A, Index);
  end;
end;

function TPPGCustomGrid.UiaIndexInParent(const Id: TPPGUiaId): Integer;
begin
  case Id.Kind of
    PPGUiaKindGridHeaderRow: Result := Id.A;
    PPGUiaKindGridRow: Result := FFixedRows + UiaVRow(Id) - VFixedRows;
    PPGUiaKindGridCell, PPGUiaKindGridHeaderCell: Result := Id.B;
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
  end;
end;

function TPPGCustomGrid.UiaControlType(const Id: TPPGUiaId): Integer;
begin
  case Id.Kind of
    PPGUiaKindGridRow: Result := UIA_DataItemControlTypeId;
    PPGUiaKindGridHeaderRow: Result := UIA_HeaderControlTypeId;
    PPGUiaKindGridHeaderCell: Result := UIA_HeaderItemControlTypeId;
    PPGUiaKindGridCell:
      if Id.B < FFixedCols then
        Result := UIA_HeaderItemControlTypeId
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
    PPGUiaKindGridCell, PPGUiaKindGridHeaderCell: Result := CellRect(Id.B, V);
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
      Value := SPPGSortAscending
    else
      Value := SPPGSortDescending;
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
  Result := (V >= Sl.Top) and (V <= Sl.Bottom) and (Id.B >= Sl.Left) and (Id.B <= Sl.Right);
end;

procedure TPPGCustomGrid.UiaGridSize(out Rows, Cols: Integer);
begin
  Rows := VRowCount - VFixedRows;
  if Rows < 0 then
    Rows := 0;
  Cols := FColCount - FFixedCols;
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
  Col := Id.B - FFixedCols;
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
      Result[I] := PPGUiaId(PPGUiaKindGridHeaderCell, FFixedRows - 1, FFixedCols + I);
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
begin
  if Id.Kind in [PPGUiaKindGridCell, PPGUiaKindGridHeaderCell] then
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
end;

function TPPGCustomGrid.UiaToggleState(const Id: TPPGUiaId): Integer;
var
  S: string;
begin
  S := UiaValue(Id);
  if (S = '1') or SameText(S, 'True') or SameText(S, 'Ja') then
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
  case Action of
    uaSetFocus:
      begin
        if CanFocus and not Focused then
          SetFocus;
        if (Id.Kind = PPGUiaKindGridCell) and (Id.B >= FFixedCols) then
          MoveFocus(Id.B, V, False, True);
      end;
    uaSelect, uaAddToSelection:
      if (Id.Kind = PPGUiaKindGridCell) and (Id.B >= FFixedCols) then
        MoveFocus(Id.B, V, (Action = uaAddToSelection) and UiaCanSelectMultiple, True);
    uaScrollIntoView:
      if V >= 0 then
      begin
        if Id.Kind in [PPGUiaKindGridCell, PPGUiaKindGridHeaderCell] then
          MakeCellVisible(Id.B, V)
        else
          MakeCellVisible(FFixedCols, V);
      end;
    uaToggle:
      if Id.Kind = PPGUiaKindGridCell then
        ToggleCheck(Id.B, V);
    uaInvoke:
      if Id.Kind = PPGUiaKindGridHeaderCell then
        HeaderClicked(Id.B, Id.A);
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
