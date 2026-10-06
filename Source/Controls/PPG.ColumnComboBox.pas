unit PPG.ColumnComboBox;

{ TPPGColumnComboBox - mehrspaltige Auswahl mit Kopfzeile (Phase 12e,
  Vorbild TMS TAdvMultiColumnComboBox).

  - Columns (Titel, Breite in logischen px, Ausrichtung) und Zeilen aus Items:
    jede Zeile enthaelt die Zellen getrennt durch ColumnDelimiter ("1001|Mueller|Berlin").
    Virtuell: VirtualRowCount > 0 und OnGetCellText liefern die Zellen
    (z.B. 100 000 Zeilen ohne Kopie).
  - Kopfzeile im Popup; Klick sortiert (aufsteigend/absteigend), die
    Reihenfolge der Daten bleibt unveraendert (nur die Ansicht).
  - KeyColumn/KeyValue fuer den Schluessel (DB-Anbindung), DisplayColumn fuer
    den Text im Feld. Tippsuche in der Anzeigespalte (offen und geschlossen).
  - Zeichnen: schlanke eigene Zeile; die Zellroutine des Grids
    (TPPGCellPainter, Phase 13) soll das spaeter uebernehmen.
  - OnChange nur bei Auswahl durch den Anwender; ItemIndex/KeyValue aus Code
    ohne Ereignis. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.Variants, Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Tokens, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Base,
  PPG.Controls.Field, PPG.Controls.DropDown, PPG.RowPopup;

type
  TPPGColumnComboBox = class;

  TPPGComboColumn = class(TCollectionItem)
  private
    FTitle: string;
    FWidth: Integer;
    FAlignment: TAlignment;
    FVisible: Boolean;
    procedure SetWidth(const Value: Integer);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
  published
    property Title: string read FTitle write FTitle;
    /// Breite in logischen px.
    property Width: Integer read FWidth write SetWidth default 100;
    property Alignment: TAlignment read FAlignment write FAlignment default taLeftJustify;
    property Visible: Boolean read FVisible write FVisible default True;
  end;

  TPPGComboColumns = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGComboColumn;
  public
    function Add: TPPGComboColumn;
    property Items[Index: Integer]: TPPGComboColumn read GetItem; default;
  end;

  TPPGGetCellTextEvent = procedure(Sender: TObject; Row, Column: Integer;
    var Text: string) of object;

  TPPGColumnPopup = class(TPPGRowPopup, IPPGAccessibleChildren)
  private
    FCombo: TPPGColumnComboBox;
    FOrder: TArray<Integer>;   // Zeile der Ansicht -> Datenzeile
    FSortColumn: Integer;
    FSortAsc: Boolean;
    procedure BuildOrder;
    function ColumnLeft(Col: Integer; const R: TRect): Integer;
  protected
    function RowCount: Integer; override;
    procedure PaintRow(const ACanvas: IPPGCanvas; Index: Integer; const R: TRect;
      const ListStyle, HighlightStyle: TPPGSurfaceStyle; Hot, Focused: Boolean); override;
    procedure PaintHeader(const ACanvas: IPPGCanvas; const R: TRect;
      const ListStyle: TPPGSurfaceStyle); override;
    procedure HeaderClick(X: Integer); override;
    function RowActivate(Index: Integer; ByMouse: Boolean; X: Integer): TPPGDropAction; override;
    function TypeAhead(Key: Char): Boolean; override;
    function AccName: string; override;
    function AccRole: Integer; override;
    { IPPGAccessibleChildren }
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
  public
    procedure Prepare(ACombo: TPPGColumnComboBox);
    function PreferredSize(FieldWidth: Integer): TSize; override;
    /// Datenzeile einer Ansichtszeile.
    function DataRow(ViewRow: Integer): Integer;
    function ViewRowOf(DataRow: Integer): Integer;
    procedure SortBy(Column: Integer; Ascending: Boolean);
    property SortColumn: Integer read FSortColumn;
    property SortAscending: Boolean read FSortAsc;
  end;

  TPPGColumnComboBox = class(TPPGCustomDropDownField, IPPGFieldValue)
  private
    FColumns: TPPGComboColumns;
    FItems: TStrings;
    FColumnDelimiter: Char;
    FVirtualRowCount: Integer;
    FItemIndex: Integer;
    FKeyColumn: Integer;
    FDisplayColumn: Integer;
    FDropDownCount: Integer;
    FDropDownWidth: Integer;
    FSearch: string;
    FSearchTick: Cardinal;
    FOnGetCellText: TPPGGetCellTextEvent;
    procedure SetColumns(const Value: TPPGComboColumns);
    procedure SetItems(const Value: TStrings);
    procedure SetItemIndex(const Value: Integer);
    function GetKeyValue: string;
    procedure SetKeyValue(const Value: string);
    procedure SetVirtualRowCount(const Value: Integer);
    procedure ItemsChanged(Sender: TObject);
    procedure SetDropDownCount(const Value: Integer);
  protected
    function CreatePopup: TPPGDropPopup; override;
    procedure PreparePopup(APopup: TPPGDropPopup); override;
    procedure AcceptPopup(APopup: TPPGDropPopup); override;
    procedure ClosedKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure ClosedKeyPress(var Key: Char); override;
    procedure DoPaintField(const ACanvas: IPPGCanvas; const Style: TPPGSurfaceStyle); override;
    function AccValue: string; override;
    { IPPGFieldValue }
    function FieldIsNull: Boolean;
    procedure FieldClear;
    function GetFieldValue: Variant;
    procedure SetFieldValue(const Value: Variant);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function RowCount: Integer;
    function CellText(Row, Column: Integer): string;
    /// Erste Zeile ab Start, deren Anzeigespalte mit Prefix beginnt (-1 = keine).
    function FindRow(const Prefix: string; Start: Integer): Integer;
    /// Auswahl wie durch den Anwender (OnChange).
    procedure SelectRow(Row: Integer);
    /// Text der Anzeigespalte der gewaehlten Zeile.
    function DisplayText: string;
    property ItemIndex: Integer read FItemIndex write SetItemIndex;
    property KeyValue: string read GetKeyValue write SetKeyValue;
  published
    property Columns: TPPGComboColumns read FColumns write SetColumns;
    property Items: TStrings read FItems write SetItems;
    property ColumnDelimiter: Char read FColumnDelimiter write FColumnDelimiter default '|';
    /// > 0: Zeilen kommen aus OnGetCellText (Items wird nicht benutzt).
    property VirtualRowCount: Integer read FVirtualRowCount write SetVirtualRowCount default 0;
    property KeyColumn: Integer read FKeyColumn write FKeyColumn default 0;
    property DisplayColumn: Integer read FDisplayColumn write FDisplayColumn default 0;
    property DropDownCount: Integer read FDropDownCount write SetDropDownCount default 10;
    /// Breite des Popups in logischen px (0 = Summe der Spalten).
    property DropDownWidth: Integer read FDropDownWidth write FDropDownWidth default 0;
    property OnGetCellText: TPPGGetCellTextEvent read FOnGetCellText write FOnGetCellText;
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property TextHint;
    property ValidationState;
    property ValidationHint;
    property HighContrastSupport;
    property Align;
    property Anchors;
    property AutoSize default True;
    property BiDiMode;
    property BorderStyle;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop;
    property Visible;
    property OnChange;
    property OnCloseUp;
    property OnDropDown;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
  end;

implementation

uses
  System.Math, System.Generics.Defaults, System.Generics.Collections, Winapi.oleacc,
  PPG.Appearance, PPG.DpiUtils, PPG.Lang, PPG.Consts, PPG.Exceptions;

const
  SearchResetMs = 1000;

{ TPPGComboColumn }

constructor TPPGComboColumn.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FWidth := 100;
  FVisible := True;
end;

procedure TPPGComboColumn.Assign(Source: TPersistent);
begin
  if Source is TPPGComboColumn then
  begin
    FTitle := TPPGComboColumn(Source).FTitle;
    FWidth := TPPGComboColumn(Source).FWidth;
    FAlignment := TPPGComboColumn(Source).FAlignment;
    FVisible := TPPGComboColumn(Source).FVisible;
  end
  else
    inherited Assign(Source);
end;

function TPPGComboColumn.GetDisplayName: string;
begin
  Result := FTitle;
  if Result = '' then
    Result := inherited GetDisplayName;
end;

procedure TPPGComboColumn.SetWidth(const Value: Integer);
begin
  FWidth := PPGCheckRange(Self, 'Width', Value, 10, 2000);
end;

{ TPPGComboColumns }

function TPPGComboColumns.Add: TPPGComboColumn;
begin
  Result := TPPGComboColumn(inherited Add);
end;

function TPPGComboColumns.GetItem(Index: Integer): TPPGComboColumn;
begin
  Result := TPPGComboColumn(inherited GetItem(Index));
end;

{ TPPGColumnPopup }

procedure TPPGColumnPopup.Prepare(ACombo: TPPGColumnComboBox);
begin
  FCombo := ACombo;
  MaxRows := ACombo.DropDownCount;
  HeaderHeight := RowHeight;
  FilterEnabled := False;
  BuildOrder;
  ResetView(ViewRowOf(ACombo.ItemIndex));
  if FocusRow >= 0 then
    EnsureVisible(FocusRow)
  else if RowCount > 0 then
    SetFocusRow(0);
end;

procedure TPPGColumnPopup.BuildOrder;
var
  I, N: Integer;
  Col: Integer;
  Asc: Boolean;
  Combo: TPPGColumnComboBox;
begin
  N := FCombo.RowCount;
  SetLength(FOrder, N);
  for I := 0 to N - 1 do
    FOrder[I] := I;
  if FSortColumn = 0 then
    Exit;
  Col := FSortColumn - 1;
  Asc := FSortAsc;
  Combo := FCombo;
  TArray.Sort<Integer>(FOrder, TComparer<Integer>.Construct(
    function(const A, B: Integer): Integer
    begin
      Result := AnsiCompareText(Combo.CellText(A, Col), Combo.CellText(B, Col));
      if Result = 0 then
        Result := A - B; // stabil
      if not Asc then
        Result := -Result;
    end));
end;

procedure TPPGColumnPopup.SortBy(Column: Integer; Ascending: Boolean);
var
  Data: Integer;
begin
  Data := DataRow(FocusRow);
  FSortColumn := Column + 1;
  FSortAsc := Ascending;
  BuildOrder;
  SetFocusRow(ViewRowOf(Data));
  Invalidate;
end;

function TPPGColumnPopup.RowCount: Integer;
begin
  Result := Length(FOrder);
end;

function TPPGColumnPopup.DataRow(ViewRow: Integer): Integer;
begin
  if (ViewRow >= 0) and (ViewRow < Length(FOrder)) then
    Result := FOrder[ViewRow]
  else
    Result := -1;
end;

function TPPGColumnPopup.ViewRowOf(DataRow: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FOrder) do
    if FOrder[I] = DataRow then
      Exit(I);
  Result := -1;
end;

function TPPGColumnPopup.PreferredSize(FieldWidth: Integer): TSize;
var
  I, W: Integer;
begin
  Result := inherited PreferredSize(FieldWidth);
  if FCombo.DropDownWidth > 0 then
    W := PPGScale(FCombo.DropDownWidth, ScalePPI)
  else
  begin
    W := 2 * Pad + PPGScale(14, ScalePPI);
    for I := 0 to FCombo.Columns.Count - 1 do
      if FCombo.Columns[I].Visible then
        Inc(W, PPGScale(FCombo.Columns[I].Width, ScalePPI));
  end;
  Result.cx := Max(W, FieldWidth);
end;

function TPPGColumnPopup.ColumnLeft(Col: Integer; const R: TRect): Integer;
var
  I: Integer;
begin
  Result := R.Left + PPGScale(8, ScalePPI);
  for I := 0 to Col - 1 do
    if FCombo.Columns[I].Visible then
      Inc(Result, PPGScale(FCombo.Columns[I].Width, ScalePPI));
end;

procedure TPPGColumnPopup.PaintHeader(const ACanvas: IPPGCanvas; const R: TRect;
  const ListStyle: TPPGSurfaceStyle);
var
  I, X, W: Integer;
  CR: TRect;
  S: string;
  F: Cardinal;
  C: TPPGComboColumn;
begin
  for I := 0 to FCombo.Columns.Count - 1 do
  begin
    C := FCombo.Columns[I];
    if not C.Visible then
      Continue;
    X := ColumnLeft(I, R);
    W := PPGScale(C.Width, ScalePPI);
    CR := Rect(X, R.Top, Min(X + W - PPGScale(6, ScalePPI), R.Right), R.Bottom);
    S := C.Title;
    if FSortColumn = I + 1 then
    begin
      if FSortAsc then
        S := S + ' ' + #$25B4
      else
        S := S + ' ' + #$25BE;
    end;
    case C.Alignment of
      taRightJustify: F := DT_RIGHT;
      taCenter: F := DT_CENTER;
    else
      F := DT_LEFT;
    end;
    ACanvas.DrawText(CR, S, Font, PPGBlendColor(ListStyle.TextColor, ListStyle.Color, 0.3),
      F or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
  end;
  ACanvas.FillRoundRect(Rect(R.Left, R.Bottom - 1, R.Right, R.Bottom), 0,
    PPGBlendColor(ListStyle.Color, ListStyle.TextColor, 0.15), 255);
end;

procedure TPPGColumnPopup.HeaderClick(X: Integer);
var
  I, L: Integer;
  R: TRect;
begin
  R := Rect(Pad, 0, ClientWidth - Pad, 0);
  for I := FCombo.Columns.Count - 1 downto 0 do
  begin
    if not FCombo.Columns[I].Visible then
      Continue;
    L := ColumnLeft(I, R);
    if X >= L then
    begin
      // Gleiche Spalte: Richtung umkehren
      if FSortColumn = I + 1 then
        SortBy(I, not FSortAsc)
      else
        SortBy(I, True);
      Exit;
    end;
  end;
end;

procedure TPPGColumnPopup.PaintRow(const ACanvas: IPPGCanvas; Index: Integer;
  const R: TRect; const ListStyle, HighlightStyle: TPPGSurfaceStyle; Hot, Focused: Boolean);
var
  I, X, W, Data: Integer;
  CR: TRect;
  F: Cardinal;
  C: TPPGComboColumn;
  TextColor: TColor;
begin
  Data := DataRow(Index);
  if Hot then
    TextColor := HighlightStyle.TextColor
  else
    TextColor := ListStyle.TextColor;
  // Gewaehlte Zeile: Akzentstrich links (wie die Listen der Suite)
  if Data = FCombo.ItemIndex then
    ACanvas.FillRoundRect(Rect(R.Left + 1, R.Top + PPGScale(8, ScalePPI),
      R.Left + 1 + PPGScale(3, ScalePPI), R.Bottom - PPGScale(8, ScalePPI)),
      PPGScale(2, ScalePPI), Tokens.Accent, 255);
  for I := 0 to FCombo.Columns.Count - 1 do
  begin
    C := FCombo.Columns[I];
    if not C.Visible then
      Continue;
    X := ColumnLeft(I, R);
    W := PPGScale(C.Width, ScalePPI);
    CR := Rect(X, R.Top, Min(X + W - PPGScale(6, ScalePPI), R.Right), R.Bottom);
    case C.Alignment of
      taRightJustify: F := DT_RIGHT;
      taCenter: F := DT_CENTER;
    else
      F := DT_LEFT;
    end;
    ACanvas.DrawText(CR, FCombo.CellText(Data, I), Font, TextColor,
      F or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
  end;
end;

function TPPGColumnPopup.RowActivate(Index: Integer; ByMouse: Boolean;
  X: Integer): TPPGDropAction;
begin
  Result := pdaAccept;
end;

function TPPGColumnPopup.TypeAhead(Key: Char): Boolean;
var
  Row: Integer;
begin
  // Tippsuche in der Anzeigespalte, in der Reihenfolge der Ansicht
  FCombo.FSearch := FCombo.FSearch + Key;
  if GetTickCount - FCombo.FSearchTick > SearchResetMs then
    FCombo.FSearch := Key;
  FCombo.FSearchTick := GetTickCount;
  Result := True;
  for Row := 0 to RowCount - 1 do
    if Pos(AnsiLowerCase(FCombo.FSearch),
      AnsiLowerCase(FCombo.CellText(DataRow(Row), FCombo.DisplayColumn))) = 1 then
    begin
      SetFocusRow(Row);
      Exit;
    end;
end;

function TPPGColumnPopup.AccName: string;
begin
  if FCombo <> nil then
    Result := FCombo.AccName
  else
    Result := '';
end;

function TPPGColumnPopup.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_LIST;
end;

function TPPGColumnPopup.AccChildCount: Integer;
begin
  Result := RowCount;
end;

function TPPGColumnPopup.AccChildName(Id: Integer): string;
var
  I, Data: Integer;
begin
  // Alle Zellen, mit Spaltentitel ("Nr 1001, Name Mueller")
  Result := '';
  Data := DataRow(Id - 1);
  if Data < 0 then
    Exit;
  for I := 0 to FCombo.Columns.Count - 1 do
    if FCombo.Columns[I].Visible then
    begin
      if Result <> '' then
        Result := Result + ', ';
      if FCombo.Columns[I].Title <> '' then
        Result := Result + FCombo.Columns[I].Title + ' ';
      Result := Result + FCombo.CellText(Data, I);
    end;
end;

function TPPGColumnPopup.AccChildRole(Id: Integer): Integer;
begin
  Result := ROLE_SYSTEM_LISTITEM;
end;

function TPPGColumnPopup.AccChildState(Id: Integer): Integer;
begin
  Result := STATE_SYSTEM_FOCUSABLE or STATE_SYSTEM_SELECTABLE;
  if DataRow(Id - 1) = FCombo.ItemIndex then
    Result := Result or STATE_SYSTEM_SELECTED;
  if Id - 1 = FocusRow then
    Result := Result or STATE_SYSTEM_FOCUSED;
end;

function TPPGColumnPopup.AccChildRect(Id: Integer): TRect;
begin
  Result := RowRect(Id - 1);
end;

function TPPGColumnPopup.AccChildAt(X, Y: Integer): Integer;
begin
  Result := RowAt(X, Y) + 1;
end;

function TPPGColumnPopup.AccChildDefaultAction(Id: Integer): string;
begin
  Result := PPGStr(@SPPGAccSelect);
end;

procedure TPPGColumnPopup.AccChildDoDefault(Id: Integer);
begin
  if (Id >= 1) and (Id <= RowCount) and (FCombo <> nil) and FCombo.HandleAllocated then
  begin
    SetFocusRow(Id - 1);
    PostMessage(FCombo.Handle, WM_KEYDOWN, VK_RETURN, 0);
  end;
end;

function TPPGColumnPopup.AccFocusedChild: Integer;
begin
  Result := FocusRow + 1;
end;

function TPPGColumnPopup.AccSelectedChild: Integer;
begin
  Result := ViewRowOf(FCombo.ItemIndex) + 1;
end;

{ TPPGColumnComboBox }

constructor TPPGColumnComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColumns := TPPGComboColumns.Create(Self, TPPGComboColumn);
  FItems := TStringList.Create;
  TStringList(FItems).OnChange := ItemsChanged;
  FColumnDelimiter := '|';
  FItemIndex := -1;
  FDropDownCount := 10;
  SetInnerVisible(False);
end;

destructor TPPGColumnComboBox.Destroy;
begin
  FreeAndNil(FItems);
  FreeAndNil(FColumns);
  inherited Destroy;
end;

procedure TPPGColumnComboBox.SetColumns(const Value: TPPGComboColumns);
begin
  FColumns.Assign(Value);
end;

procedure TPPGColumnComboBox.SetItems(const Value: TStrings);
begin
  FItems.Assign(Value);
end;

procedure TPPGColumnComboBox.ItemsChanged(Sender: TObject);
begin
  if FItemIndex >= RowCount then
    FItemIndex := -1;
  Invalidate;
end;

procedure TPPGColumnComboBox.SetVirtualRowCount(const Value: Integer);
begin
  FVirtualRowCount := PPGCheckRange(Self, 'VirtualRowCount', Value, 0, MaxInt);
  if FItemIndex >= RowCount then
    FItemIndex := -1;
  Invalidate;
end;

procedure TPPGColumnComboBox.SetDropDownCount(const Value: Integer);
begin
  FDropDownCount := PPGCheckRange(Self, 'DropDownCount', Value, 1, 100);
end;

function TPPGColumnComboBox.RowCount: Integer;
begin
  if FVirtualRowCount > 0 then
    Result := FVirtualRowCount
  else
    Result := FItems.Count;
end;

function TPPGColumnComboBox.CellText(Row, Column: Integer): string;
var
  Parts: TArray<string>;
begin
  Result := '';
  if (Row < 0) or (Row >= RowCount) then
    Exit;
  if FVirtualRowCount > 0 then
  begin
    if Assigned(FOnGetCellText) then
      FOnGetCellText(Self, Row, Column, Result);
    Exit;
  end;
  Parts := PPGSplitString(FItems[Row], FColumnDelimiter, False);
  if (Column >= 0) and (Column <= High(Parts)) then
    Result := Parts[Column];
end;

function TPPGColumnComboBox.FindRow(const Prefix: string; Start: Integer): Integer;
var
  I, N: Integer;
  P: string;
begin
  Result := -1;
  N := RowCount;
  if (N = 0) or (Prefix = '') then
    Exit;
  P := AnsiLowerCase(Prefix);
  for I := 0 to N - 1 do
    if Pos(P, AnsiLowerCase(CellText((Start + I) mod N, FDisplayColumn))) = 1 then
      Exit((Start + I) mod N);
end;

procedure TPPGColumnComboBox.SetItemIndex(const Value: Integer);
begin
  // Aus Code: ohne OnChange
  if (Value < -1) or (Value >= RowCount) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Value, RowCount - 1]);
  if FItemIndex = Value then
    Exit;
  FItemIndex := Value;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
end;

procedure TPPGColumnComboBox.SelectRow(Row: Integer);
begin
  if ReadOnly or not Enabled or (Row < 0) or (Row >= RowCount) or (Row = FItemIndex) then
    Exit;
  FItemIndex := Row;
  Invalidate;
  Change;
end;

function TPPGColumnComboBox.GetKeyValue: string;
begin
  Result := CellText(FItemIndex, FKeyColumn);
end;

procedure TPPGColumnComboBox.SetKeyValue(const Value: string);
var
  I: Integer;
begin
  for I := 0 to RowCount - 1 do
    if CellText(I, FKeyColumn) = Value then
    begin
      SetItemIndex(I);
      Exit;
    end;
  SetItemIndex(-1);
end;

function TPPGColumnComboBox.DisplayText: string;
begin
  Result := CellText(FItemIndex, FDisplayColumn);
end;

function TPPGColumnComboBox.CreatePopup: TPPGDropPopup;
begin
  Result := TPPGColumnPopup.Create(Self);
end;

procedure TPPGColumnComboBox.PreparePopup(APopup: TPPGDropPopup);
begin
  FSearch := '';
  TPPGColumnPopup(APopup).Prepare(Self);
end;

procedure TPPGColumnComboBox.AcceptPopup(APopup: TPPGDropPopup);
var
  P: TPPGColumnPopup;
begin
  P := TPPGColumnPopup(APopup);
  SelectRow(P.DataRow(P.FocusRow));
end;

procedure TPPGColumnComboBox.ClosedKeyDown(var Key: Word; Shift: TShiftState);
begin
  // Geschlossen: Pfeile blaettern die Auswahl (wie eine DropDownList)
  case Key of
    VK_UP:
      if FItemIndex > 0 then
        SelectRow(FItemIndex - 1);
    VK_DOWN:
      if FItemIndex < RowCount - 1 then
        SelectRow(FItemIndex + 1);
    VK_HOME:
      SelectRow(0);
    VK_END:
      SelectRow(RowCount - 1);
  else
    Exit;
  end;
  Key := 0;
end;

procedure TPPGColumnComboBox.ClosedKeyPress(var Key: Char);
var
  Row: Integer;
begin
  if Key < #32 then
    Exit;
  if GetTickCount - FSearchTick > SearchResetMs then
    FSearch := '';
  FSearch := FSearch + Key;
  FSearchTick := GetTickCount;
  Row := FindRow(FSearch, Max(FItemIndex, 0));
  if Row >= 0 then
    SelectRow(Row);
  Key := #0;
end;

procedure TPPGColumnComboBox.DoPaintField(const ACanvas: IPPGCanvas;
  const Style: TPPGSurfaceStyle);
var
  R, B: TRect;
  S: string;
  C: TColor;
begin
  inherited DoPaintField(ACanvas, Style);
  R := ClientRect;
  InflateRect(R, -PPGScale(10, ScalePPI), 0);
  B := ButtonRect(PPGDropButton);
  if not IsRectEmpty(B) then
    R.Right := B.Left - PPGScale(4, ScalePPI);
  S := DisplayText;
  C := Style.TextColor;
  if FItemIndex < 0 then
  begin
    S := TextHint;
    C := HintColor;
  end;
  ACanvas.DrawText(R, S, Font, C,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
end;

function TPPGColumnComboBox.AccValue: string;
begin
  Result := DisplayText;
end;

function TPPGColumnComboBox.FieldIsNull: Boolean;
begin
  Result := FItemIndex < 0;
end;

procedure TPPGColumnComboBox.FieldClear;
begin
  SetItemIndex(-1);
end;

function TPPGColumnComboBox.GetFieldValue: Variant;
begin
  if FItemIndex < 0 then
    Result := Null
  else
    Result := GetKeyValue;
end;

procedure TPPGColumnComboBox.SetFieldValue(const Value: Variant);
begin
  if VarIsNull(Value) or VarIsEmpty(Value) then
    SetItemIndex(-1)
  else
    SetKeyValue(VarToStr(Value));
end;

end.
