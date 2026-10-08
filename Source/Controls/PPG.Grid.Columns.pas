unit PPG.Grid.Columns;

{ Spalten des Grids (Phase 13a, aus PPG.Grid herausgeloest).

  - TPPGGridColumn/TPPGGridColumns wie bisher (DFM unveraendert: die Klassen
    behalten Namen und Properties; PPG.Grid stellt Aliase bereit).
  - Die Spalten kennen ihr Grid nicht: Aenderungen melden sie an den Owner
    ueber IPPGGridColumnsHost (DIP). Damit nutzen Grid, DB-Grid, Drucker
    und Export dieselben Spalten.
  - Phase 13b: Visible, DisplayIndex (Anzeigeposition; Index bleibt der
    Datenindex, DFMs bleiben stabil) und Band (Kopf ueber mehreren Spalten,
    TPPGGridBands, auch mehrstufig ueber ParentBand).
  - Phase 13c: Aggregate/FooterFormat (Summenzeile und Gruppen-Summen) und
    GroupIndex (Gruppieren nach dieser Spalte; Reihenfolge der Ebenen).
  - Phase 13d: CellKind (Zellart: Kaestchen, Fortschritt, Sparkline, Bewertung,
    Bild, Link, Button, Farbfeld, Markup; eigene ueber CellKindName). }

{$I ..\PPG.inc}

interface

uses
  System.Classes, PPG.ElementStyle;

type
  TPPGGridEditorKind = (gekText, gekNone, gekCombo, gekSpin, gekCheck);

  /// Zusammenfassung einer Spalte in Summenzeile und Gruppen-Fuss.
  TPPGGridAggregate = (agNone, agSum, agAvg, agMin, agMax, agCount, agCustom);

  /// Darstellung der Zellen einer Spalte (PPG.Grid.CellKinds).
  TPPGGridCellKind = (ckText, ckCheck, ckProgress, ckSparkline, ckRating, ckImage,
    ckLink, ckButton, ckColor, ckMarkup, ckCustom);

  /// Ausrichtung des Spaltentitels; gtaColumn = wie Alignment der Spalte.
  TPPGGridTitleAlignment = (gtaColumn, gtaLeft, gtaCenter, gtaRight);

  /// Owner der Spalten (Grid, DB-Grid): wird nach jeder Aenderung gerufen.
  IPPGGridColumnsHost = interface
    ['{3E7A2C91-5B4D-4F86-9C1E-D2A0B6F4E853}']
    procedure ColumnsChanged;
  end;

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
    FVisible: Boolean;
    FDisplayIndex: Integer;
    FBand: Integer;
    FAggregate: TPPGGridAggregate;
    FFooterFormat: string;
    FGroupIndex: Integer;
    FCellKind: TPPGGridCellKind;
    FCellKindName: string;
    FFormat: string;
    FStyle: TPPGElementStyle;
    FTitleStyle: TPPGElementStyle;
    FTitleAlignment: TPPGGridTitleAlignment;
    procedure SetStyle(const Value: TPPGElementStyle);
    procedure SetTitleStyle(const Value: TPPGElementStyle);
    procedure SetTitleAlignment(const Value: TPPGGridTitleAlignment);
    procedure StyleChanged(Sender: TObject);
    procedure SetCellKind(const Value: TPPGGridCellKind);
    procedure SetCellKindName(const Value: string);
    procedure SetAggregate(const Value: TPPGGridAggregate);
    procedure SetFooterFormat(const Value: string);
    procedure SetGroupIndex(const Value: Integer);
    procedure SetVisible(const Value: Boolean);
    procedure SetDisplayIndex(const Value: Integer);
    procedure SetBand(const Value: Integer);
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
    /// Ausrichtung des Titels (gtaColumn aufgeloest).
    function EffectiveTitleAlignment: TAlignment;
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
    property Visible: Boolean read FVisible write SetVisible default True;
    /// Position in der Anzeige unter den beweglichen Spalten (-1 = wie Index).
    /// Das Grid schreibt sie beim Verschieben fuer alle Spalten neu.
    property DisplayIndex: Integer read FDisplayIndex write SetDisplayIndex default -1;
    /// Band (Index in Grid.Bands) ueber dieser Spalte; -1 = keins.
    property Band: Integer read FBand write SetBand default -1;
    property Aggregate: TPPGGridAggregate read FAggregate write SetAggregate default agNone;
    /// FormatFloat-Muster fuer Summen ('' = '#,##0.##'); agCount immer ganzzahlig.
    property FooterFormat: string read FFooterFormat write SetFooterFormat;
    /// Ebene beim Gruppieren (0 = oberste); -1 = nicht gruppiert.
    property GroupIndex: Integer read FGroupIndex write SetGroupIndex default -1;
    property CellKind: TPPGGridCellKind read FCellKind write SetCellKind default ckText;
    /// Name einer registrierten Zellart (nur mit CellKind = ckCustom).
    property CellKindName: string read FCellKindName write SetCellKindName;
    /// Zahlen-/Datumsformat fuer den Export (Excel-Syntax, z.B. '#,##0.00',
    /// 'dd.mm.yyyy'); '' = Standard.
    property Format: string read FFormat write FFormat;
    /// Zellen dieser Spalte: Flaeche, Text und Schrift (clDefault = Grid).
    property Style: TPPGElementStyle read FStyle write SetStyle;
    /// Spaltenkopf: Flaeche, Text und Schrift (clDefault = Grid.Styles.Header).
    property TitleStyle: TPPGElementStyle read FTitleStyle write SetTitleStyle;
    property TitleAlignment: TPPGGridTitleAlignment read FTitleAlignment
      write SetTitleAlignment default gtaColumn;
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

  TPPGGridBand = class(TCollectionItem)
  private
    FCaption: string;
    FParentBand: Integer;
    FAlignment: TAlignment;
    procedure SetCaption(const Value: string);
    procedure SetParentBand(const Value: Integer);
    procedure SetAlignment(const Value: TAlignment);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
  published
    property Caption: string read FCaption write SetCaption;
    /// Uebergeordnetes Band (Index); -1 = oberste Ebene.
    property ParentBand: Integer read FParentBand write SetParentBand default -1;
    property Alignment: TAlignment read FAlignment write SetAlignment default taCenter;
  end;

  TPPGGridBands = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGGridBand;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    function Add: TPPGGridBand;
    /// Ebene eines Bands (0 = oben); Zyklen werden abgebrochen.
    function LevelOf(Index: Integer): Integer;
    /// Anzahl Ebenen (0 = keine Baender).
    function LevelCount: Integer;
    /// Band einer Kette auf Ebene Level, ausgehend vom Band Index (-1 = keins).
    function BandAtLevel(Index, Level: Integer): Integer;
    property Items[Index: Integer]: TPPGGridBand read GetItem; default;
  end;

implementation

uses
  System.SysUtils, PPG.Types;

{ TPPGGridColumn }

constructor TPPGGridColumn.Create(Collection: TCollection);
begin
  FPickList := TStringList.Create;
  FSortable := True;
  FVisible := True;
  FDisplayIndex := -1;
  FBand := -1;
  FGroupIndex := -1;
  FStyle := TPPGElementStyle.Create(Self);
  FStyle.OnChange := StyleChanged;
  FTitleStyle := TPPGElementStyle.Create(Self);
  FTitleStyle.OnChange := StyleChanged;
  inherited Create(Collection);
end;

destructor TPPGGridColumn.Destroy;
begin
  FreeAndNil(FPickList);
  FreeAndNil(FTitleStyle);
  FreeAndNil(FStyle);
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
    FVisible := S.FVisible;
    FDisplayIndex := S.FDisplayIndex;
    FBand := S.FBand;
    FAggregate := S.FAggregate;
    FFooterFormat := S.FFooterFormat;
    FGroupIndex := S.FGroupIndex;
    FCellKind := S.FCellKind;
    FCellKindName := S.FCellKindName;
    FFormat := S.FFormat;
    FStyle.OnChange := nil;
    FTitleStyle.OnChange := nil;
    try
      FStyle.Assign(S.FStyle);
      FTitleStyle.Assign(S.FTitleStyle);
    finally
      FStyle.OnChange := StyleChanged;
      FTitleStyle.OnChange := StyleChanged;
    end;
    FTitleAlignment := S.FTitleAlignment;
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

procedure TPPGGridColumn.SetStyle(const Value: TPPGElementStyle);
begin
  FStyle.Assign(Value);
end;

procedure TPPGGridColumn.SetTitleStyle(const Value: TPPGElementStyle);
begin
  FTitleStyle.Assign(Value);
end;

procedure TPPGGridColumn.StyleChanged(Sender: TObject);
begin
  Changed(False);
end;

procedure TPPGGridColumn.SetTitleAlignment(const Value: TPPGGridTitleAlignment);
begin
  if FTitleAlignment <> Value then
  begin
    FTitleAlignment := Value;
    Changed(False);
  end;
end;

function TPPGGridColumn.EffectiveTitleAlignment: TAlignment;
begin
  case FTitleAlignment of
    gtaLeft: Result := taLeftJustify;
    gtaCenter: Result := taCenter;
    gtaRight: Result := taRightJustify;
  else
    Result := FAlignment;
  end;
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

procedure TPPGGridColumn.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    Changed(True);
  end;
end;

procedure TPPGGridColumn.SetDisplayIndex(const Value: Integer);
begin
  if FDisplayIndex <> Value then
  begin
    FDisplayIndex := PPGCheckRange(Self, 'DisplayIndex', Value, -1, 100000);
    Changed(True);
  end;
end;

procedure TPPGGridColumn.SetBand(const Value: Integer);
begin
  if FBand <> Value then
  begin
    FBand := PPGCheckRange(Self, 'Band', Value, -1, 100000);
    Changed(True);
  end;
end;

procedure TPPGGridColumn.SetAggregate(const Value: TPPGGridAggregate);
begin
  if FAggregate <> Value then
  begin
    FAggregate := Value;
    Changed(True);
  end;
end;

procedure TPPGGridColumn.SetFooterFormat(const Value: string);
begin
  if FFooterFormat <> Value then
  begin
    FFooterFormat := Value;
    Changed(True);
  end;
end;

procedure TPPGGridColumn.SetGroupIndex(const Value: Integer);
begin
  if FGroupIndex <> Value then
  begin
    FGroupIndex := PPGCheckRange(Self, 'GroupIndex', Value, -1, 100);
    Changed(True);
  end;
end;

procedure TPPGGridColumn.SetCellKind(const Value: TPPGGridCellKind);
begin
  if FCellKind <> Value then
  begin
    FCellKind := Value;
    Changed(False);
  end;
end;

procedure TPPGGridColumn.SetCellKindName(const Value: string);
begin
  if FCellKindName <> Value then
  begin
    FCellKindName := Value;
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
  H: IPPGGridColumnsHost;
begin
  inherited Update(Item);
  if (GetOwner is TComponent) and (csLoading in TComponent(GetOwner).ComponentState) then
    Exit;
  if Supports(GetOwner, IPPGGridColumnsHost, H) then
    H.ColumnsChanged;
end;


{ TPPGGridBand }

constructor TPPGGridBand.Create(Collection: TCollection);
begin
  FParentBand := -1;
  FAlignment := taCenter;
  inherited Create(Collection);
end;

procedure TPPGGridBand.Assign(Source: TPersistent);
var
  S: TPPGGridBand;
begin
  if Source is TPPGGridBand then
  begin
    S := TPPGGridBand(Source);
    FCaption := S.FCaption;
    FParentBand := S.FParentBand;
    FAlignment := S.FAlignment;
    Changed(True);
  end
  else
    inherited Assign(Source);
end;

function TPPGGridBand.GetDisplayName: string;
begin
  if FCaption <> '' then
    Result := FCaption
  else
    Result := inherited GetDisplayName;
end;

procedure TPPGGridBand.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

procedure TPPGGridBand.SetParentBand(const Value: Integer);
begin
  if FParentBand <> Value then
  begin
    FParentBand := PPGCheckRange(Self, 'ParentBand', Value, -1, 100000);
    Changed(True);
  end;
end;

procedure TPPGGridBand.SetAlignment(const Value: TAlignment);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    Changed(False);
  end;
end;

{ TPPGGridBands }

function TPPGGridBands.Add: TPPGGridBand;
begin
  Result := TPPGGridBand(inherited Add);
end;

function TPPGGridBands.GetItem(Index: Integer): TPPGGridBand;
begin
  Result := TPPGGridBand(inherited Items[Index]);
end;

procedure TPPGGridBands.Update(Item: TCollectionItem);
var
  H: IPPGGridColumnsHost;
begin
  inherited Update(Item);
  if (GetOwner is TComponent) and (csLoading in TComponent(GetOwner).ComponentState) then
    Exit;
  if Supports(GetOwner, IPPGGridColumnsHost, H) then
    H.ColumnsChanged;
end;

function TPPGGridBands.LevelOf(Index: Integer): Integer;
var
  P, Guard: Integer;
begin
  Result := 0;
  if (Index < 0) or (Index >= Count) then
    Exit;
  P := Items[Index].ParentBand;
  Guard := Count - 1; // hoechstens Count Ebenen, auch bei Zyklen
  while (P >= 0) and (P < Count) and (Guard > 0) do
  begin
    Inc(Result);
    P := Items[P].ParentBand;
    Dec(Guard);
  end;
end;

function TPPGGridBands.LevelCount: Integer;
var
  I, L: Integer;
begin
  Result := 0;
  for I := 0 to Count - 1 do
  begin
    L := LevelOf(I) + 1;
    if L > Result then
      Result := L;
  end;
end;

function TPPGGridBands.BandAtLevel(Index, Level: Integer): Integer;
var
  L: Integer;
begin
  Result := -1;
  if (Index < 0) or (Index >= Count) then
    Exit;
  L := LevelOf(Index);
  if Level > L then
    Exit;
  Result := Index;
  while L > Level do
  begin
    Result := Items[Result].ParentBand;
    Dec(L);
  end;
end;

end.
