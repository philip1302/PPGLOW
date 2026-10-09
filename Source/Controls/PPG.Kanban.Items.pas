unit PPG.Kanban.Items;

{ Modell des Kanban-Boards (Phase 14c): Spalten, Swimlanes und Karten.

  - Alles TOwnedCollections, im Objektinspektor und in der DFM pflegbar.
  - Karten liegen flach in einer Collection und gehoeren ueber ColumnId und
    LaneId zu einer Zelle; die Reihenfolge in der Zelle ist die Reihenfolge in
    der Collection (so braucht die DB-Variante nur ein Sortierfeld).
  - Ids werden fortlaufend vergeben und gestreamt; eine geladene Id hebt den
    Zaehler, damit neue Eintraege eindeutig bleiben.
  - Das Modell kennt das Control nicht: Aenderungen gehen ueber
    IPPGKanbanHost an den Besitzer. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.SysUtils, Vcl.Graphics;

type
  /// Besitzer des Modells (das Board).
  IPPGKanbanHost = interface
    ['{2E6B91D4-58C3-4F7A-A0D2-7C14E9B36F85}']
    procedure KanbanModelChanged;
  end;

  /// Inhalt einer Karte (fuer Zeichnen, Screenreader und virtuelle Karten).
  TPPGKanbanCardData = record
    Title: string;
    Text: string;       // mit Markup
    Labels: string;     // "Bug, UI"
    Assignee: string;   // Name, gezeigt als Initialen
    Due: TDateTime;     // 0 = keine Faelligkeit
    Progress: Integer;  // -1 = keine Anzeige, sonst 0..100
    Color: TColor;      // Farbstreifen links, clNone = keiner
    Tag: NativeInt;
  end;

  TPPGKanbanColumn = class(TCollectionItem)
  private
    FId: Integer;
    FTitle: string;
    FColor: TColor;
    FWipLimit: Integer;
    FCollapsed: Boolean;
    FWidth: Integer;
    FVisible: Boolean;
    FVirtualCount: Integer;
    FKey: string;
    FTag: NativeInt;
    procedure SetId(const Value: Integer);
    procedure SetTitle(const Value: string);
    procedure SetColor(const Value: TColor);
    procedure SetWipLimit(const Value: Integer);
    procedure SetCollapsed(const Value: Boolean);
    procedure SetWidth(const Value: Integer);
    procedure SetVisible(const Value: Boolean);
    procedure SetVirtualCount(const Value: Integer);
    procedure SetKey(const Value: string);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    /// Wert im Spaltenfeld der Datenbank (Key, sonst Id als Text).
    function MatchKey: string;
  published
    property Id: Integer read FId write SetId;
    property Title: string read FTitle write SetTitle;
    /// Farbe der Kopfleiste (clDefault = Akzent des Presets).
    property Color: TColor read FColor write SetColor default clDefault;
    /// Hoechstzahl Karten (0 = ohne Limit); darueber wird die Spalte gewarnt.
    property WipLimit: Integer read FWipLimit write SetWipLimit default 0;
    property Collapsed: Boolean read FCollapsed write SetCollapsed default False;
    /// Breite in logischen px (0 = Board.ColumnWidth).
    property Width: Integer read FWidth write SetWidth default 0;
    property Visible: Boolean read FVisible write SetVisible default True;
    /// > 0: virtuelle Spalte mit so vielen Karten (Inhalt ueber OnGetCard).
    property VirtualCount: Integer read FVirtualCount write SetVirtualCount default 0;
    /// Wert im Spaltenfeld der Datenbank ('' = Id).
    property Key: string read FKey write SetKey;
    property Tag: NativeInt read FTag write FTag default 0;
  end;

  TPPGKanbanColumns = class(TOwnedCollection)
  private
    FNextId: Integer;
    function GetItem(Index: Integer): TPPGKanbanColumn;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TPPGKanbanColumn;
    function AddColumn(const ATitle: string; AWipLimit: Integer = 0): TPPGKanbanColumn;
    function FindById(AId: Integer): TPPGKanbanColumn;
    function FindByKey(const AKey: string): TPPGKanbanColumn;
    property Items[Index: Integer]: TPPGKanbanColumn read GetItem; default;
  end;

  TPPGKanbanLane = class(TCollectionItem)
  private
    FId: Integer;
    FTitle: string;
    FCollapsed: Boolean;
    FVisible: Boolean;
    FKey: string;
    FTag: NativeInt;
    procedure SetId(const Value: Integer);
    procedure SetTitle(const Value: string);
    procedure SetCollapsed(const Value: Boolean);
    procedure SetVisible(const Value: Boolean);
    procedure SetKey(const Value: string);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    function MatchKey: string;
  published
    property Id: Integer read FId write SetId;
    property Title: string read FTitle write SetTitle;
    property Collapsed: Boolean read FCollapsed write SetCollapsed default False;
    property Visible: Boolean read FVisible write SetVisible default True;
    /// Wert im Swimlane-Feld der Datenbank ('' = Id).
    property Key: string read FKey write SetKey;
    property Tag: NativeInt read FTag write FTag default 0;
  end;

  TPPGKanbanLanes = class(TOwnedCollection)
  private
    FNextId: Integer;
    function GetItem(Index: Integer): TPPGKanbanLane;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TPPGKanbanLane;
    function AddLane(const ATitle: string): TPPGKanbanLane;
    function FindById(AId: Integer): TPPGKanbanLane;
    function FindByKey(const AKey: string): TPPGKanbanLane;
    property Items[Index: Integer]: TPPGKanbanLane read GetItem; default;
  end;

  TPPGKanbanCard = class(TCollectionItem)
  private
    FId: Integer;
    FTitle: string;
    FText: string;
    FColumnId: Integer;
    FLaneId: Integer;
    FLabels: string;
    FAssignee: string;
    FDue: TDateTime;
    FProgress: Integer;
    FColor: TColor;
    FTag: NativeInt;
    FData: Pointer;
    procedure SetId(const Value: Integer);
    procedure SetTitle(const Value: string);
    procedure SetText(const Value: string);
    procedure SetColumnId(const Value: Integer);
    procedure SetLaneId(const Value: Integer);
    procedure SetLabels(const Value: string);
    procedure SetAssignee(const Value: string);
    procedure SetDue(const Value: TDateTime);
    procedure SetProgress(const Value: Integer);
    procedure SetColor(const Value: TColor);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    function AsData: TPPGKanbanCardData;
    /// Freies Datum der Anwendung (nicht gestreamt).
    property Data: Pointer read FData write FData;
  published
    property Id: Integer read FId write SetId;
    property Title: string read FTitle write SetTitle;
    /// Text mit Markup (<b>, <i>, <color>, ...), hoechstens Board.MaxTextLines Zeilen.
    property Text: string read FText write SetText;
    property ColumnId: Integer read FColumnId write SetColumnId default 0;
    property LaneId: Integer read FLaneId write SetLaneId default 0;
    /// Plaketten, durch Komma getrennt ("Bug, UI").
    property Labels: string read FLabels write SetLabels;
    /// Name der Person (gezeigt als Initialen).
    property Assignee: string read FAssignee write SetAssignee;
    property Due: TDateTime read FDue write SetDue;
    /// Fortschritt 0..100, -1 = keine Anzeige.
    property Progress: Integer read FProgress write SetProgress default -1;
    property Color: TColor read FColor write SetColor default clDefault;
    property Tag: NativeInt read FTag write FTag default 0;
  end;

  TPPGKanbanCards = class(TOwnedCollection)
  private
    FNextId: Integer;
    function GetItem(Index: Integer): TPPGKanbanCard;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TPPGKanbanCard;
    function AddCard(AColumnId: Integer; const ATitle: string; const AText: string = '';
      ALaneId: Integer = 0): TPPGKanbanCard;
    function FindById(AId: Integer): TPPGKanbanCard;
    property Items[Index: Integer]: TPPGKanbanCard read GetItem; default;
  end;

procedure PPGKanbanClearData(var Data: TPPGKanbanCardData);

implementation

uses
  PPG.Types;

procedure PPGKanbanClearData(var Data: TPPGKanbanCardData);
begin
  Data.Title := '';
  Data.Text := '';
  Data.Labels := '';
  Data.Assignee := '';
  Data.Due := 0;
  Data.Progress := -1;
  Data.Color := clNone;
  Data.Tag := 0;
end;

procedure NotifyHost(C: TCollection);
var
  H: IPPGKanbanHost;
begin
  if (C <> nil) and (C.Owner <> nil) and Supports(C.Owner, IPPGKanbanHost, H) then
    H.KanbanModelChanged;
end;

{ TPPGKanbanColumn }

constructor TPPGKanbanColumn.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FColor := clDefault;
  FVisible := True;
  if Collection is TPPGKanbanColumns then
  begin
    FId := TPPGKanbanColumns(Collection).FNextId;
    Inc(TPPGKanbanColumns(Collection).FNextId);
  end;
end;

procedure TPPGKanbanColumn.Assign(Source: TPersistent);
var
  S: TPPGKanbanColumn;
begin
  if Source is TPPGKanbanColumn then
  begin
    S := TPPGKanbanColumn(Source);
    Id := S.FId;
    FTitle := S.FTitle;
    FColor := S.FColor;
    FWipLimit := S.FWipLimit;
    FCollapsed := S.FCollapsed;
    FWidth := S.FWidth;
    FVisible := S.FVisible;
    FVirtualCount := S.FVirtualCount;
    FKey := S.FKey;
    FTag := S.FTag;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGKanbanColumn.GetDisplayName: string;
begin
  if FTitle <> '' then
    Result := FTitle
  else
    Result := inherited GetDisplayName;
end;

function TPPGKanbanColumn.MatchKey: string;
begin
  if FKey <> '' then
    Result := FKey
  else
    Result := IntToStr(FId);
end;

procedure TPPGKanbanColumn.SetId(const Value: Integer);
begin
  if FId <> Value then
  begin
    FId := Value;
    if (Collection is TPPGKanbanColumns) and (Value >= TPPGKanbanColumns(Collection).FNextId) then
      TPPGKanbanColumns(Collection).FNextId := Value + 1;
    Changed(False);
  end;
end;

procedure TPPGKanbanColumn.SetTitle(const Value: string);
begin
  if FTitle <> Value then
  begin
    FTitle := Value;
    Changed(False);
  end;
end;

procedure TPPGKanbanColumn.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Changed(False);
  end;
end;

procedure TPPGKanbanColumn.SetWipLimit(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'WipLimit', Value, 0, 9999);
  if FWipLimit <> V then
  begin
    FWipLimit := V;
    Changed(False);
  end;
end;

procedure TPPGKanbanColumn.SetCollapsed(const Value: Boolean);
begin
  if FCollapsed <> Value then
  begin
    FCollapsed := Value;
    Changed(False);
  end;
end;

procedure TPPGKanbanColumn.SetWidth(const Value: Integer);
var
  V: Integer;
begin
  V := Value;
  if V <> 0 then
    V := PPGCheckRange(Self, 'Width', Value, PPGKanbanMinColumnWidth, 2000);
  if FWidth <> V then
  begin
    FWidth := V;
    Changed(False);
  end;
end;

procedure TPPGKanbanColumn.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    Changed(False);
  end;
end;

procedure TPPGKanbanColumn.SetVirtualCount(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'VirtualCount', Value, 0, MaxInt);
  if FVirtualCount <> V then
  begin
    FVirtualCount := V;
    Changed(False);
  end;
end;

procedure TPPGKanbanColumn.SetKey(const Value: string);
begin
  if FKey <> Value then
  begin
    FKey := Value;
    Changed(False);
  end;
end;

{ TPPGKanbanColumns }

constructor TPPGKanbanColumns.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TPPGKanbanColumn);
  FNextId := 1;
end;

function TPPGKanbanColumns.GetItem(Index: Integer): TPPGKanbanColumn;
begin
  Result := TPPGKanbanColumn(inherited Items[Index]);
end;

function TPPGKanbanColumns.Add: TPPGKanbanColumn;
begin
  Result := TPPGKanbanColumn(inherited Add);
end;

function TPPGKanbanColumns.AddColumn(const ATitle: string; AWipLimit: Integer): TPPGKanbanColumn;
begin
  BeginUpdate;
  try
    Result := Add;
    Result.FTitle := ATitle;
    Result.WipLimit := AWipLimit;
  finally
    EndUpdate;
  end;
end;

function TPPGKanbanColumns.FindById(AId: Integer): TPPGKanbanColumn;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Items[I].Id = AId then
      Exit(Items[I]);
  Result := nil;
end;

function TPPGKanbanColumns.FindByKey(const AKey: string): TPPGKanbanColumn;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if SameText(Items[I].MatchKey, AKey) then
      Exit(Items[I]);
  Result := nil;
end;

procedure TPPGKanbanColumns.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  NotifyHost(Self);
end;

{ TPPGKanbanLane }

constructor TPPGKanbanLane.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FVisible := True;
  if Collection is TPPGKanbanLanes then
  begin
    FId := TPPGKanbanLanes(Collection).FNextId;
    Inc(TPPGKanbanLanes(Collection).FNextId);
  end;
end;

procedure TPPGKanbanLane.Assign(Source: TPersistent);
var
  S: TPPGKanbanLane;
begin
  if Source is TPPGKanbanLane then
  begin
    S := TPPGKanbanLane(Source);
    Id := S.FId;
    FTitle := S.FTitle;
    FCollapsed := S.FCollapsed;
    FVisible := S.FVisible;
    FKey := S.FKey;
    FTag := S.FTag;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGKanbanLane.GetDisplayName: string;
begin
  if FTitle <> '' then
    Result := FTitle
  else
    Result := inherited GetDisplayName;
end;

function TPPGKanbanLane.MatchKey: string;
begin
  if FKey <> '' then
    Result := FKey
  else
    Result := IntToStr(FId);
end;

procedure TPPGKanbanLane.SetId(const Value: Integer);
begin
  if FId <> Value then
  begin
    FId := Value;
    if (Collection is TPPGKanbanLanes) and (Value >= TPPGKanbanLanes(Collection).FNextId) then
      TPPGKanbanLanes(Collection).FNextId := Value + 1;
    Changed(False);
  end;
end;

procedure TPPGKanbanLane.SetTitle(const Value: string);
begin
  if FTitle <> Value then
  begin
    FTitle := Value;
    Changed(False);
  end;
end;

procedure TPPGKanbanLane.SetCollapsed(const Value: Boolean);
begin
  if FCollapsed <> Value then
  begin
    FCollapsed := Value;
    Changed(False);
  end;
end;

procedure TPPGKanbanLane.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    Changed(False);
  end;
end;

procedure TPPGKanbanLane.SetKey(const Value: string);
begin
  if FKey <> Value then
  begin
    FKey := Value;
    Changed(False);
  end;
end;

{ TPPGKanbanLanes }

constructor TPPGKanbanLanes.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TPPGKanbanLane);
  FNextId := 1;
end;

function TPPGKanbanLanes.GetItem(Index: Integer): TPPGKanbanLane;
begin
  Result := TPPGKanbanLane(inherited Items[Index]);
end;

function TPPGKanbanLanes.Add: TPPGKanbanLane;
begin
  Result := TPPGKanbanLane(inherited Add);
end;

function TPPGKanbanLanes.AddLane(const ATitle: string): TPPGKanbanLane;
begin
  Result := Add;
  Result.Title := ATitle;
end;

function TPPGKanbanLanes.FindById(AId: Integer): TPPGKanbanLane;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Items[I].Id = AId then
      Exit(Items[I]);
  Result := nil;
end;

function TPPGKanbanLanes.FindByKey(const AKey: string): TPPGKanbanLane;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if SameText(Items[I].MatchKey, AKey) then
      Exit(Items[I]);
  Result := nil;
end;

procedure TPPGKanbanLanes.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  NotifyHost(Self);
end;

{ TPPGKanbanCard }

constructor TPPGKanbanCard.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FProgress := -1;
  FColor := clDefault;
  if Collection is TPPGKanbanCards then
  begin
    FId := TPPGKanbanCards(Collection).FNextId;
    Inc(TPPGKanbanCards(Collection).FNextId);
  end;
end;

procedure TPPGKanbanCard.Assign(Source: TPersistent);
var
  S: TPPGKanbanCard;
begin
  if Source is TPPGKanbanCard then
  begin
    S := TPPGKanbanCard(Source);
    // Audit 08.10.2026: Id mitkopieren (wie Spalten und Bahnen), sonst
    // nummeriert Cards := X neu und der Druck meldet andere Ids.
    Id := S.FId;
    FTitle := S.FTitle;
    FText := S.FText;
    FColumnId := S.FColumnId;
    FLaneId := S.FLaneId;
    FLabels := S.FLabels;
    FAssignee := S.FAssignee;
    FDue := S.FDue;
    FProgress := S.FProgress;
    FColor := S.FColor;
    FTag := S.FTag;
    FData := S.FData;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGKanbanCard.GetDisplayName: string;
begin
  if FTitle <> '' then
    Result := FTitle
  else
    Result := inherited GetDisplayName;
end;

function TPPGKanbanCard.AsData: TPPGKanbanCardData;
begin
  Result.Title := FTitle;
  Result.Text := FText;
  Result.Labels := FLabels;
  Result.Assignee := FAssignee;
  Result.Due := FDue;
  Result.Progress := FProgress;
  Result.Color := FColor;
  Result.Tag := FTag;
end;

procedure TPPGKanbanCard.SetId(const Value: Integer);
begin
  if FId <> Value then
  begin
    FId := Value;
    if (Collection is TPPGKanbanCards) and (Value >= TPPGKanbanCards(Collection).FNextId) then
      TPPGKanbanCards(Collection).FNextId := Value + 1;
    Changed(False);
  end;
end;

procedure TPPGKanbanCard.SetTitle(const Value: string);
begin
  if FTitle <> Value then
  begin
    FTitle := Value;
    Changed(False);
  end;
end;

procedure TPPGKanbanCard.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    Changed(False);
  end;
end;

procedure TPPGKanbanCard.SetColumnId(const Value: Integer);
begin
  if FColumnId <> Value then
  begin
    FColumnId := Value;
    Changed(False);
  end;
end;

procedure TPPGKanbanCard.SetLaneId(const Value: Integer);
begin
  if FLaneId <> Value then
  begin
    FLaneId := Value;
    Changed(False);
  end;
end;

procedure TPPGKanbanCard.SetLabels(const Value: string);
begin
  if FLabels <> Value then
  begin
    FLabels := Value;
    Changed(False);
  end;
end;

procedure TPPGKanbanCard.SetAssignee(const Value: string);
begin
  if FAssignee <> Value then
  begin
    FAssignee := Value;
    Changed(False);
  end;
end;

procedure TPPGKanbanCard.SetDue(const Value: TDateTime);
begin
  if FDue <> Value then
  begin
    FDue := Value;
    Changed(False);
  end;
end;

procedure TPPGKanbanCard.SetProgress(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'Progress', Value, -1, 100);
  if FProgress <> V then
  begin
    FProgress := V;
    Changed(False);
  end;
end;

procedure TPPGKanbanCard.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Changed(False);
  end;
end;

{ TPPGKanbanCards }

constructor TPPGKanbanCards.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TPPGKanbanCard);
  FNextId := 1;
end;

function TPPGKanbanCards.GetItem(Index: Integer): TPPGKanbanCard;
begin
  Result := TPPGKanbanCard(inherited Items[Index]);
end;

function TPPGKanbanCards.Add: TPPGKanbanCard;
begin
  Result := TPPGKanbanCard(inherited Add);
end;

function TPPGKanbanCards.AddCard(AColumnId: Integer; const ATitle, AText: string;
  ALaneId: Integer): TPPGKanbanCard;
begin
  BeginUpdate;
  try
    Result := Add;
    Result.FColumnId := AColumnId;
    Result.FLaneId := ALaneId;
    Result.FTitle := ATitle;
    Result.FText := AText;
  finally
    EndUpdate;
  end;
end;

function TPPGKanbanCards.FindById(AId: Integer): TPPGKanbanCard;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Items[I].Id = AId then
      Exit(Items[I]);
  Result := nil;
end;

procedure TPPGKanbanCards.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  NotifyHost(Self);
end;

end.
