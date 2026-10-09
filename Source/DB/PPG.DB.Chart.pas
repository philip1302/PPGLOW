unit PPG.DB.Chart;

{ TPPGDBChart - Diagramm aus einer Datenmenge (Phase 10e, Paket PPGlowDBR).

  - DataSource, ValueFields ("Umsatz;Kosten": je Feld eine Serie, in der
    Reihenfolge der Series; fehlende Serien werden angelegt und nach
    Field.DisplayLabel benannt), LabelField (Kategorie-Text) und XField
    (X-Wert fuer Zahl-/Datumsachse).
  - Gelesen wird die ganze Datenmenge (hoechstens MaxRecords) mit
    DisableControls und Lesezeichen; der aktuelle Datensatz bleibt stehen.
  - Anbinden, Oeffnen und Schliessen laden sofort. Datenaenderungen laden
    verzoegert neu (ReloadDelay ueber den gemeinsamen Animator, nie im
    Paint): viele Aenderungen hintereinander = ein Laden.
    Die Ereignisse des eigenen Lesens werden ignoriert.
  - ShowCurrentRecord markiert den aktuellen Datensatz (MarkedIndex);
    Klick auf einen Punkt springt zum Datensatz (JumpToRecord).
  - Eindirektionale Datenmengen werden nicht gelesen (kein Zurueckspringen).
  - Waehrend Edit/Insert wird nicht gelesen (First wuerde die Eingabe des
    Anwenders speichern); das Laden folgt nach Post bzw. Cancel. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.SysUtils, Data.DB,
  PPG.Animation, PPG.Chart, PPG.Chart.Series;

type
  TPPGCustomDBChart = class;

  TPPGChartDataLink = class(TDataLink)
  private
    FChart: TPPGCustomDBChart;
  protected
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure DataSetScrolled(Distance: Integer); override;
    procedure RecordChanged(Field: TField); override;
  public
    constructor Create(AChart: TPPGCustomDBChart);
  end;

  TPPGCustomDBChart = class(TPPGCustomChart)
  private
    FDataLink: TPPGChartDataLink;
    FValueFields: string;
    FLabelField: string;
    FXField: string;
    FMaxRecords: Integer;
    FReloadDelay: Integer;
    FShowCurrentRecord: Boolean;
    FJumpToRecord: Boolean;
    FReloadAnim: TPPGAnimation;
    FReloadPending: Boolean;
    FReading: Integer;
    FLoadedCount: Integer;
    FRowMarks: array of TBookmark;      // Lesezeichen je gelesenem Datensatz
    FPointRows: array of TArray<Integer>; // je Serie: Punkt -> Datensatz
    function RowOfRecord: Integer;
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    procedure SetValueFields(const Value: string);
    procedure SetLabelField(const Value: string);
    procedure SetXField(const Value: string);
    procedure SetMaxRecords(const Value: Integer);
    procedure SetReloadDelay(const Value: Integer);
    procedure SetShowCurrentRecord(const Value: Boolean);
    procedure ReloadStep(Sender: TObject);
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoPointClick(SeriesIndex, PointIndex: Integer); override;
    /// Neu laden anfordern (verzoegert).
    procedure ScheduleReload;
    procedure UpdateCurrentRecord;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property ValueFields: string read FValueFields write SetValueFields;
    property LabelField: string read FLabelField write SetLabelField;
    property XField: string read FXField write SetXField;
    property MaxRecords: Integer read FMaxRecords write SetMaxRecords default 10000;
    /// Wartezeit in ms vor dem Neuladen (0 = sofort).
    property ReloadDelay: Integer read FReloadDelay write SetReloadDelay default 100;
    property ShowCurrentRecord: Boolean read FShowCurrentRecord write SetShowCurrentRecord default True;
    property JumpToRecord: Boolean read FJumpToRecord write FJumpToRecord default True;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Sofort aus der Datenmenge lesen.
    procedure Reload;
    /// Eine ausstehende, verzoegerte Aktualisierung jetzt ausfuehren.
    procedure FlushReload;
    function ReloadPending: Boolean;
    /// Anzahl der zuletzt gelesenen Datensaetze.
    property LoadedCount: Integer read FLoadedCount;
    property DataLink: TPPGChartDataLink read FDataLink;
  end;

  TPPGDBChart = class(TPPGCustomDBChart)
  published
    property DataSource;
    property ValueFields;
    property LabelField;
    property XField;
    property MaxRecords;
    property ReloadDelay;
    property ShowCurrentRecord;
    property JumpToRecord;
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighContrastSupport;
    property Title;
    property Series;
    property Categories;
    property XAxis;
    property YAxis;
    property Y2Axis;
    property ReferenceLines;
    property Stacking;
    property LegendPosition;
    property ShowTooltips;
    property LegendToggle;
    property ChartStyles;
    property Align;
    property Anchors;
    property BiDiMode;
    property Constraints;
    property Enabled;
    property Font;
    property Hint;
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
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnPointClick;
  end;

implementation

uses
  System.Math, PPG.Types, PPG.DB.Controls;

{ TPPGChartDataLink }

constructor TPPGChartDataLink.Create(AChart: TPPGCustomDBChart);
begin
  inherited Create;
  FChart := AChart;
end;

procedure TPPGChartDataLink.ActiveChanged;
begin
  // Oeffnen/Schliessen bzw. neue DataSource: sofort lesen (nur Aenderungen
  // am Inhalt werden verzoegert, sonst bliebe das Diagramm zunaechst leer)
  if (FChart <> nil) and (FChart.FReading = 0) and
    not (csLoading in FChart.ComponentState) and not (csDestroying in FChart.ComponentState) then
    FChart.Reload;
end;

procedure TPPGChartDataLink.DataSetChanged;
begin
  if (FChart <> nil) and not PPGDBReading then
    FChart.ScheduleReload;
end;

procedure TPPGChartDataLink.DataSetScrolled(Distance: Integer);
begin
  if FChart <> nil then
    FChart.UpdateCurrentRecord;
end;

procedure TPPGChartDataLink.RecordChanged(Field: TField);
begin
  if FChart <> nil then
    FChart.ScheduleReload;
end;

{ TPPGCustomDBChart }

constructor TPPGCustomDBChart.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMaxRecords := 10000;
  FReloadDelay := 100;
  FShowCurrentRecord := True;
  FJumpToRecord := True;
  FReloadAnim := TPPGAnimation.Create(Self);
  FReloadAnim.OnStep := ReloadStep;
  FDataLink := TPPGChartDataLink.Create(Self);
end;

destructor TPPGCustomDBChart.Destroy;
begin
  if FDataLink <> nil then
    FDataLink.FChart := nil; // keine Rueckmeldungen mehr waehrend des Abbaus
  FreeAndNil(FDataLink);
  if FReloadAnim <> nil then
    FReloadAnim.OnStep := nil;
  FreeAndNil(FReloadAnim);
  inherited Destroy;
end;

procedure TPPGCustomDBChart.Loaded;
begin
  inherited Loaded;
  Reload;
end;

procedure TPPGCustomDBChart.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FDataLink <> nil) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TPPGCustomDBChart.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TPPGCustomDBChart.SetDataSource(Value: TDataSource);
begin
  PPGDBSetDataSource(Self, FDataLink, Value);
end;

procedure TPPGCustomDBChart.SetValueFields(const Value: string);
begin
  if FValueFields <> Value then
  begin
    FValueFields := Value;
    ScheduleReload;
  end;
end;

procedure TPPGCustomDBChart.SetLabelField(const Value: string);
begin
  if FLabelField <> Value then
  begin
    FLabelField := Value;
    ScheduleReload;
  end;
end;

procedure TPPGCustomDBChart.SetXField(const Value: string);
begin
  if FXField <> Value then
  begin
    FXField := Value;
    ScheduleReload;
  end;
end;

procedure TPPGCustomDBChart.SetMaxRecords(const Value: Integer);
begin
  if FMaxRecords = Value then
    Exit;
  FMaxRecords := PPGCheckRange(Self, 'MaxRecords', Value, 1, MaxInt);
  ScheduleReload;
end;

procedure TPPGCustomDBChart.SetReloadDelay(const Value: Integer);
begin
  FReloadDelay := PPGCheckRange(Self, 'ReloadDelay', Value, 0, 10000);
end;

procedure TPPGCustomDBChart.SetShowCurrentRecord(const Value: Boolean);
begin
  if FShowCurrentRecord <> Value then
  begin
    FShowCurrentRecord := Value;
    UpdateCurrentRecord;
  end;
end;

procedure TPPGCustomDBChart.ScheduleReload;
begin
  if (FReading > 0) or (csLoading in ComponentState) or (csDestroying in ComponentState) then
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

procedure TPPGCustomDBChart.ReloadStep(Sender: TObject);
begin
  if FReloadPending and not FReloadAnim.Running then
    Reload;
end;

function TPPGCustomDBChart.ReloadPending: Boolean;
begin
  Result := FReloadPending;
end;

procedure TPPGCustomDBChart.FlushReload;
begin
  if FReloadPending then
    Reload;
end;

procedure TPPGCustomDBChart.Reload;
var
  DS: TDataSet;
  Names: TArray<string>;
  Fields: array of TField;
  LabelF, XF: TField;
  I, N: Integer;
  Bm: TBookmark;
  S: TPPGChartSeries;
  XV: Double;
  Txt: string;
begin
  FReloadPending := False;
  if FReloadAnim.Running then
    FReloadAnim.Stop;
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  Names := PPGSplitString(FValueFields, ';', True);
  BeginDataUpdate;
  try
    // Ohne aktive Datenmenge: angebundene Serien leeren
    if not FDataLink.Active or (FDataLink.DataSet = nil) or
      FDataLink.DataSet.IsUniDirectional then
    begin
      for I := 0 to System.Math.Min(Length(Names), Series.Count) - 1 do
        Series[I].Clear;
      FLoadedCount := 0;
      SetLength(FRowMarks, 0);
      SetLength(FPointRows, 0);
      MarkedIndex := -1;
      Exit;
    end;
    DS := FDataLink.DataSet;
    // Waehrend der Anwender bearbeitet, nicht lesen: First wuerde die
    // Eingabe vorzeitig speichern (CheckBrowseMode). Nach Post meldet die
    // Datenmenge DataSetChanged, dann wird gelesen.
    if DS.State in dsEditModes then
    begin
      FReloadPending := True;
      Exit;
    end;
    SetLength(Fields, Length(Names));
    for I := 0 to High(Names) do
      Fields[I] := DS.FindField(Trim(Names[I]));
    LabelF := nil;
    if FLabelField <> '' then
      LabelF := DS.FindField(FLabelField);
    XF := nil;
    if FXField <> '' then
      XF := DS.FindField(FXField);
    // Fehlende Serien anlegen
    while Series.Count < Length(Names) do
      Series.Add;
    for I := 0 to High(Names) do
    begin
      S := Series[I];
      S.DataBound := True;
      if (S.Title = '') and (Fields[I] <> nil) then
        S.SetDataTitle(Fields[I].DisplayLabel);
      S.Clear;
    end;
    SetLength(FRowMarks, 0);
    SetLength(FPointRows, Length(Names));
    for I := 0 to High(FPointRows) do
      SetLength(FPointRows[I], 0);
    Inc(FReading);
    PPGDBBeginRead;
    try
      Bm := DS.Bookmark;
      DS.DisableControls;
      try
        DS.First;
        N := 0;
        while not DS.Eof and (N < FMaxRecords) do
        begin
          if XF <> nil then
            XV := XF.AsFloat
          else
            XV := N;
          if LabelF <> nil then
            Txt := LabelF.DisplayText
          else
            Txt := '';
          SetLength(FRowMarks, N + 1);
          FRowMarks[N] := DS.Bookmark;
          // Audit 4b: Null ist kein Wert 0 - der Punkt entfaellt (die Serie
          // merkt sich, zu welchem Datensatz jeder Punkt gehoert)
          for I := 0 to High(Names) do
            if (Fields[I] <> nil) and not Fields[I].IsNull then
            begin
              Series[I].AddXY(XV, Fields[I].AsFloat, Txt);
              SetLength(FPointRows[I], Length(FPointRows[I]) + 1);
              FPointRows[I][High(FPointRows[I])] := N;
            end;
          Inc(N);
          DS.Next;
        end;
        FLoadedCount := N;
      finally
        if (Length(Bm) > 0) and DS.BookmarkValid(Bm) then
          DS.Bookmark := Bm;
        DS.EnableControls;
      end;
    finally
      PPGDBEndRead;
      Dec(FReading);
    end;
  finally
    EndDataUpdate;
  end;
  UpdateCurrentRecord;
end;

procedure TPPGCustomDBChart.UpdateCurrentRecord;
var
  Rec, I: Integer;
begin
  if not FShowCurrentRecord or not FDataLink.Active or (FDataLink.DataSet = nil) then
  begin
    MarkedIndex := -1;
    Exit;
  end;
  // Punkt der ersten Serie zum aktuellen Datensatz (ueber Lesezeichen, auch
  // bei Datenmengen ohne fortlaufende RecNo)
  MarkedIndex := -1;
  Rec := RowOfRecord;
  if (Rec < 0) or (Length(FPointRows) = 0) then
    Exit;
  for I := 0 to High(FPointRows[0]) do
    if FPointRows[0][I] = Rec then
    begin
      MarkedIndex := I;
      Exit;
    end;
end;

function TPPGCustomDBChart.RowOfRecord: Integer;
var
  DS: TDataSet;
  B: TBookmark;
  I: Integer;
begin
  Result := -1;
  DS := FDataLink.DataSet;
  if (DS = nil) or not DS.Active or DS.IsEmpty then
    Exit;
  B := DS.Bookmark;
  if Length(B) = 0 then
    Exit;
  for I := 0 to High(FRowMarks) do
    if DS.CompareBookmarks(B, FRowMarks[I]) = 0 then
      Exit(I);
end;

procedure TPPGCustomDBChart.DoPointClick(SeriesIndex, PointIndex: Integer);
var
  Row: Integer;
  DS: TDataSet;
begin
  if FJumpToRecord and FDataLink.Active and (FDataLink.DataSet <> nil) and
    (SeriesIndex >= 0) and (SeriesIndex <= High(FPointRows)) and (PointIndex >= 0) and
    (PointIndex <= High(FPointRows[SeriesIndex])) then
  begin
    Row := FPointRows[SeriesIndex][PointIndex];
    DS := FDataLink.DataSet;
    if (Row <= High(FRowMarks)) and DS.BookmarkValid(FRowMarks[Row]) then
      DS.Bookmark := FRowMarks[Row];
  end;
  inherited DoPointClick(SeriesIndex, PointIndex);
end;

end.
