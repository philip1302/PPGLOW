unit PPG.DB.Kanban;

{ TPPGDBKanban - Kanban-Board auf einer Datenmenge (Phase 14c, Paket PPGlowDBR).

  - Feldzuordnung: KeyField (ganze Zahl, Pflicht zum Schreiben), ColumnField
    (Wert = Column.Key, sonst Column.Id), OrderField (Reihenfolge in der
    Spalte), TitleField sowie optional LaneField (Wert = Lane.Key bzw. Id),
    TextField, LabelsField, AssigneeField, DueField, ProgressField, ColorField.
  - Laden: alle Datensaetze (hoechstens MaxRecords) werden in Cards
    gespiegelt, sortiert nach OrderField. Bestehende Karten werden per
    Schluessel aktualisiert (Auswahl bleibt).
  - Schreiben: nach jedem Verschieben durch den Anwender bekommt die Karte
    Spalte und Swimlane, die Karten von Quell- und Zielzelle werden in
    Zehnerschritten neu nummeriert (nur geaenderte Datensaetze).
  - Ohne KeyField ist das Board schreibgeschuetzt.
  - Datenaenderungen von aussen laden verzoegert neu (ReloadDelay ueber den
    Animator); eigenes Lesen und Schreiben loest kein Neuladen aus.
  - SyncRecord: die gewaehlte Karte wird zum aktuellen Datensatz. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.SysUtils, Data.DB,
  PPG.Animation, PPG.Kanban.Items, PPG.Kanban;

type
  TPPGCustomDBKanban = class;

  TPPGKanbanDataLink = class(TDataLink)
  private
    FKanban: TPPGCustomDBKanban;
  protected
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure RecordChanged(Field: TField); override;
  public
    constructor Create(AKanban: TPPGCustomDBKanban);
  end;

  TPPGCustomDBKanban = class(TPPGCustomKanban)
  private
    FDataLink: TPPGKanbanDataLink;
    FFields: array[0..10] of string;
    FMaxRecords: Integer;
    FReloadDelay: Integer;
    FSyncRecord: Boolean;
    FReloadAnim: TPPGAnimation;
    FReloadPending: Boolean;
    FBusy: Integer;
    FLoadedCount: Integer;
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    procedure SetField(Index: Integer; const Value: string);
    function GetField(Index: Integer): string;
    procedure SetMaxRecords(const Value: Integer);
    procedure SetReloadDelay(const Value: Integer);
    procedure ReloadStep(Sender: TObject);
    function Fld(Index: Integer): TField;
    function CanWrite: Boolean;
    function LocateKey(AId: Integer): Boolean;
    procedure RenumberCell(C, L: Integer);
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function DoMoveCard(const Move: TPPGKanbanMove): Boolean; override;
    procedure CardMoved(const Move: TPPGKanbanMove); override;
    procedure SelectedCardChanged; override;
    procedure ScheduleReload;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property KeyField: string index 0 read GetField write SetField;
    property ColumnField: string index 1 read GetField write SetField;
    property LaneField: string index 2 read GetField write SetField;
    property OrderField: string index 3 read GetField write SetField;
    property TitleField: string index 4 read GetField write SetField;
    property TextField: string index 5 read GetField write SetField;
    property LabelsField: string index 6 read GetField write SetField;
    property AssigneeField: string index 7 read GetField write SetField;
    property DueField: string index 8 read GetField write SetField;
    property ProgressField: string index 9 read GetField write SetField;
    property ColorField: string index 10 read GetField write SetField;
    property MaxRecords: Integer read FMaxRecords write SetMaxRecords default 10000;
    property ReloadDelay: Integer read FReloadDelay write SetReloadDelay default 100;
    property SyncRecord: Boolean read FSyncRecord write FSyncRecord default True;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Sofort aus der Datenmenge lesen.
    procedure Reload;
    procedure FlushReload;
    function ReloadPending: Boolean;
    property LoadedCount: Integer read FLoadedCount;
    property DataLink: TPPGKanbanDataLink read FDataLink;
  end;

  TPPGDBKanban = class(TPPGCustomDBKanban)
  published
    property DataSource;
    property KeyField;
    property ColumnField;
    property LaneField;
    property OrderField;
    property TitleField;
    property TextField;
    property LabelsField;
    property AssigneeField;
    property DueField;
    property ProgressField;
    property ColorField;
    property MaxRecords;
    property ReloadDelay;
    property SyncRecord;
    property Columns;
    property Lanes;
    property ColumnWidth;
    property CardGap;
    property MaxTextLines;
    property AllowDrag;
    property ReadOnly;
    property WipMode;
    property ShowCardCount;
    property KanbanStyles;
    property VirtualCardHeight;
    property OnCustomDrawCard;
    property OnKeyDown;
    property OnScroll;
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
    property Color;
    property Constraints;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Touch;
    property OnGesture;
    property OnCardMoving;
    property OnCardMoved;
    property OnCardClick;
    property OnCardOpen;
    property OnSelectionChange;
    property OnColumnCollapse;
    property FilterText;
    property FilterLabels;
    property FilterAssignee;
    property AllowColumnDrag;
    property OnFilterCard;
    property OnColumnMoving;
    property OnColumnMoved;
    property OnEnter;
    property OnExit;
  end;

implementation

uses
  System.Math, System.Generics.Collections, System.Generics.Defaults, Vcl.Graphics,
  PPG.Types, PPG.DB.Controls, PPG.Consts, PPG.Lang, PPG.Exceptions;

type
  TRow = record
    Key: Integer;
    Order: Double;
    Seq: Integer;
  end;

{ TPPGKanbanDataLink }

constructor TPPGKanbanDataLink.Create(AKanban: TPPGCustomDBKanban);
begin
  inherited Create;
  FKanban := AKanban;
end;

procedure TPPGKanbanDataLink.ActiveChanged;
begin
  if FKanban <> nil then
    FKanban.Reload;
end;

procedure TPPGKanbanDataLink.DataSetChanged;
begin
  if (FKanban <> nil) and not PPGDBReading then
    FKanban.ScheduleReload;
end;

procedure TPPGKanbanDataLink.RecordChanged(Field: TField);
begin
  if FKanban <> nil then
    FKanban.ScheduleReload;
end;

{ TPPGCustomDBKanban }

constructor TPPGCustomDBKanban.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMaxRecords := 10000;
  FReloadDelay := 100;
  FSyncRecord := True;
  FReloadAnim := TPPGAnimation.Create(Self);
  FReloadAnim.OnStep := ReloadStep;
  FDataLink := TPPGKanbanDataLink.Create(Self);
end;

destructor TPPGCustomDBKanban.Destroy;
begin
  if FDataLink <> nil then
    FDataLink.FKanban := nil;
  FreeAndNil(FDataLink);
  if FReloadAnim <> nil then
    FReloadAnim.OnStep := nil;
  FreeAndNil(FReloadAnim);
  inherited Destroy;
end;

procedure TPPGCustomDBKanban.Loaded;
begin
  inherited Loaded;
  Reload;
end;

procedure TPPGCustomDBKanban.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FDataLink <> nil) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TPPGCustomDBKanban.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TPPGCustomDBKanban.SetDataSource(Value: TDataSource);
begin
  PPGDBSetDataSource(Self, FDataLink, Value);
end;

function TPPGCustomDBKanban.GetField(Index: Integer): string;
begin
  Result := FFields[Index];
end;

procedure TPPGCustomDBKanban.SetField(Index: Integer; const Value: string);
begin
  if FFields[Index] = Value then
    Exit;
  FFields[Index] := Value;
  ScheduleReload;
end;

procedure TPPGCustomDBKanban.SetMaxRecords(const Value: Integer);
begin
  FMaxRecords := PPGCheckRange(Self, 'MaxRecords', Value, 1, MaxInt);
  ScheduleReload;
end;

procedure TPPGCustomDBKanban.SetReloadDelay(const Value: Integer);
begin
  FReloadDelay := PPGCheckRange(Self, 'ReloadDelay', Value, 0, 10000);
end;

function TPPGCustomDBKanban.Fld(Index: Integer): TField;
begin
  if (FFields[Index] = '') or (FDataLink.DataSet = nil) then
    Result := nil
  else
    Result := FDataLink.DataSet.FindField(FFields[Index]);
end;

function TPPGCustomDBKanban.CanWrite: Boolean;
begin
  Result := FDataLink.Active and (FDataLink.DataSet <> nil) and FDataLink.DataSet.CanModify and
    (Fld(0) <> nil) and (Fld(1) <> nil);
end;

procedure TPPGCustomDBKanban.ScheduleReload;
begin
  if (FBusy > 0) or (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  if (FReloadDelay = 0) or (csDesigning in ComponentState) then
  begin
    Reload;
    Exit;
  end;
  FReloadPending := True;
  FReloadAnim.Jump(0);
  FReloadAnim.AnimateTo(1, Cardinal(FReloadDelay), ekLinear);
end;

procedure TPPGCustomDBKanban.ReloadStep(Sender: TObject);
begin
  if FReloadPending and not FReloadAnim.Running then
    Reload;
end;

function TPPGCustomDBKanban.ReloadPending: Boolean;
begin
  Result := FReloadPending;
end;

procedure TPPGCustomDBKanban.FlushReload;
begin
  if FReloadPending then
    Reload;
end;

procedure TPPGCustomDBKanban.Reload;
var
  DS: TDataSet;
  FKey, FCol, FLane, FOrd, FTitle, FText, FLab, FAss, FDue, FProg, FColor: TField;
  ById: TDictionary<Integer, TPPGKanbanCard>;
  Seen: TDictionary<Integer, Boolean>;
  Rows: TList<TRow>;
  Row: TRow;
  Card: TPPGKanbanCard;
  Col: TPPGKanbanColumn;
  Lane: TPPGKanbanLane;
  Bm: TBookmark;
  I, N, Key: Integer;
  Sel: Integer;
begin
  FReloadPending := False;
  if FReloadAnim.Running then
    FReloadAnim.Stop;
  if (csLoading in ComponentState) or (csDestroying in ComponentState) or (FBusy > 0) then
    Exit;
  if not FDataLink.Active or (FDataLink.DataSet = nil) or FDataLink.DataSet.IsUniDirectional then
  begin
    Cards.Clear;
    FLoadedCount := 0;
    Exit;
  end;
  DS := FDataLink.DataSet;
  if DS.State in dsEditModes then
  begin
    FReloadPending := True;
    Exit;
  end;
  FKey := Fld(0);
  FCol := Fld(1);
  FLane := Fld(2);
  FOrd := Fld(3);
  FTitle := Fld(4);
  FText := Fld(5);
  FLab := Fld(6);
  FAss := Fld(7);
  FDue := Fld(8);
  FProg := Fld(9);
  FColor := Fld(10);
  Sel := -1;
  if SelectedCard <> nil then
    Sel := SelectedCard.Id;
  ById := TDictionary<Integer, TPPGKanbanCard>.Create;
  Seen := TDictionary<Integer, Boolean>.Create;
  Rows := TList<TRow>.Create;
  Cards.BeginUpdate;
  Inc(FBusy);
  try
    for I := 0 to Cards.Count - 1 do
      ById.AddOrSetValue(Cards[I].Id, Cards[I]);
    Bm := DS.Bookmark;
    PPGDBBeginRead;
    DS.DisableControls;
    try
      DS.First;
      N := 0;
      while not DS.Eof and (N < FMaxRecords) do
      begin
        if FKey <> nil then
          Key := FKey.AsInteger
        else
          Key := N + 1;
        // Ohne Schluessel bzw. doppelt: nicht zuordenbar. Mit Schluessel 0
        // (NULL) fielen solche Saetze sonst zu einer Karte zusammen, und die
        // Reihenfolge unten bekaeme mehr Zeilen als Karten.
        if ((FKey <> nil) and FKey.IsNull) or Seen.ContainsKey(Key) then
        begin
          DS.Next;
          Continue;
        end;
        if not ById.TryGetValue(Key, Card) then
        begin
          Card := Cards.Add;
          Card.Id := Key;
          ById.Add(Key, Card);
        end;
        Seen.AddOrSetValue(Key, True);
        Col := nil;
        if FCol <> nil then
          Col := Columns.FindByKey(FCol.AsString);
        if Col <> nil then
          Card.ColumnId := Col.Id
        else
          Card.ColumnId := 0;
        Lane := nil;
        if FLane <> nil then
          Lane := Lanes.FindByKey(FLane.AsString);
        if Lane <> nil then
          Card.LaneId := Lane.Id
        else
          Card.LaneId := 0;
        if FTitle <> nil then
          Card.Title := FTitle.AsString;
        if FText <> nil then
          Card.Text := FText.AsString;
        if FLab <> nil then
          Card.Labels := FLab.AsString;
        if FAss <> nil then
          Card.Assignee := FAss.AsString;
        if (FDue <> nil) and not FDue.IsNull then
          Card.Due := FDue.AsDateTime
        else
          Card.Due := 0;
        if (FProg <> nil) and not FProg.IsNull then
          Card.Progress := Max(-1, Min(100, FProg.AsInteger))
        else
          Card.Progress := -1;
        if (FColor <> nil) and not FColor.IsNull then
          Card.Color := TColor(FColor.AsInteger)
        else
          Card.Color := clNone;
        Row.Key := Key;
        if (FOrd <> nil) and not FOrd.IsNull then
          Row.Order := FOrd.AsFloat
        else
          Row.Order := N;
        Row.Seq := N;
        Rows.Add(Row);
        Inc(N);
        DS.Next;
      end;
      FLoadedCount := N;
    finally
      if DS.BookmarkValid(Bm) then
        DS.Bookmark := Bm;
      DS.EnableControls;
      PPGDBEndRead;
    end;
    // nicht mehr vorhandene Karten entfernen
    for I := Cards.Count - 1 downto 0 do
      if not Seen.ContainsKey(Cards[I].Id) then
        Cards.Delete(I);
    // Reihenfolge nach dem Sortierfeld (stabil ueber die Lesereihenfolge)
    Rows.Sort(TComparer<TRow>.Construct(
      function(const A, B: TRow): Integer
      begin
        if A.Order < B.Order then
          Result := -1
        else if A.Order > B.Order then
          Result := 1
        else
          Result := A.Seq - B.Seq;
      end));
    for I := 0 to Min(Rows.Count, Cards.Count) - 1 do
      if ById.TryGetValue(Rows[I].Key, Card) and (Card.Collection <> nil) then
        Card.Index := I;
  finally
    Dec(FBusy);
    Cards.EndUpdate;
    Rows.Free;
    Seen.Free;
    ById.Free;
  end;
  if Sel >= 0 then
    SelectedCard := Cards.FindById(Sel);
end;

function TPPGCustomDBKanban.LocateKey(AId: Integer): Boolean;
begin
  Result := (Fld(0) <> nil) and FDataLink.DataSet.Locate(FFields[0], AId, []);
end;

function TPPGCustomDBKanban.DoMoveCard(const Move: TPPGKanbanMove): Boolean;
begin
  if not CanWrite then
    Exit(False);
  Result := inherited DoMoveCard(Move);
end;

procedure TPPGCustomDBKanban.RenumberCell(C, L: Integer);
var
  I: Integer;
  Card: TPPGKanbanCard;
  FOrd: TField;
  DS: TDataSet;
begin
  FOrd := Fld(3);
  if FOrd = nil then
    Exit;
  DS := FDataLink.DataSet;
  for I := 0 to CardCount(C, L) - 1 do
  begin
    Card := CardAt(C, L, I);
    if (Card = nil) or not LocateKey(Card.Id) then
      Continue;
    if FOrd.IsNull or (FOrd.AsFloat <> (I + 1) * 10) then
    begin
      DS.Edit;
      FOrd.AsInteger := (I + 1) * 10;
      DS.Post;
    end;
  end;
end;

procedure TPPGCustomDBKanban.CardMoved(const Move: TPPGKanbanMove);
var
  DS: TDataSet;
  Bm: TBookmark;
  FCol, FLane: TField;
  I, FromL: Integer;
  Done: Boolean;
begin
  inherited CardMoved(Move);
  if (Move.Card = nil) or not CanWrite then
    Exit;
  DS := FDataLink.DataSet;
  // Offene Bearbeitung eines anderen Controls: Locate wuerde sie still
  // speichern. Ablehnen, die Anzeige laedt den Datenstand neu.
  if DS.State in dsEditModes then
  begin
    ScheduleReload;
    raise EPPGError.Create(PPGStr(@SPPGDBEditPending));
  end;
  FCol := Fld(1);
  FLane := Fld(2);
  Done := False;
  Inc(FBusy);
  try
    Bm := DS.Bookmark;
    DS.DisableControls;
    try
      try
        if LocateKey(Move.Card.Id) then
        begin
          DS.Edit;
          FCol.AsString := Move.ToColumn.MatchKey;
          if (FLane <> nil) and (Move.ToLane <> nil) then
            FLane.AsString := Move.ToLane.MatchKey;
          DS.Post;
        end;
        RenumberCell(ColumnIndexOf(Move.ToColumn), Focus.Lane);
        if (Move.FromColumn <> Move.ToColumn) or (Move.FromLane <> Move.ToLane) then
        begin
          FromL := 0;
          for I := 0 to LaneCount - 1 do
            if LayoutLane(I) = Move.FromLane then
              FromL := I;
          RenumberCell(ColumnIndexOf(Move.FromColumn), FromL);
        end;
      except
        // Vor dem Zuruecksetzen des Lesezeichens, das sonst erneut postet
        if DS.State in dsEditModes then
          DS.Cancel;
        raise;
      end;
      Done := True;
    finally
      if (Length(Bm) > 0) and DS.BookmarkValid(Bm) then
        DS.Bookmark := Bm;
      DS.EnableControls;
    end;
  finally
    Dec(FBusy);
    // Fehlgeschlagen: Karte steht in der Anzeige schon am Ziel
    if not Done then
      ScheduleReload;
  end;
  if FSyncRecord then
    SelectionChanged;
end;

procedure TPPGCustomDBKanban.SelectedCardChanged;
var
  Card: TPPGKanbanCard;
begin
  inherited SelectedCardChanged;
  Card := SelectedCard;
  if not FSyncRecord or (Card = nil) or not FDataLink.Active or (Fld(0) = nil) then
    Exit;
  if FDataLink.DataSet.State in dsEditModes then
    Exit;
  Inc(FBusy);
  try
    LocateKey(Card.Id);
  finally
    Dec(FBusy);
  end;
end;

end.
