unit PPG.Chart.Series;

{ Datenmodell von TPPGChart (Phase 10d): Serien, Punkte, Achsen,
  Referenzlinien. Zeichnet nichts.

  - TPPGChartSeries haelt ihre Punkte selbst (X, Y, Text, Farbe) oder holt
    sie im virtuellen Modus (VirtualCount > 0) ueber den Host (OnGetPoint).
  - Jede Datenaenderung meldet sich VOR der Aenderung beim Host
    (BeforeDataChange: Host merkt sich die angezeigten Werte fuer den
    weichen Uebergang) und danach (DataChanged).
  - Ein-/Ausblenden gleitet ueber eine eigene Animation (VisibleFactor).
  - Im DFM stehen die Y-Werte als ValuesText ("3;5;2.5", Punkt als
    Dezimaltrenner); X ist dann der Index (Kategorieachse). }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.SysUtils, Vcl.Graphics,
  PPG.Animation;

type
  TPPGChartSeriesKind = (cskLine, cskStepLine, cskArea, cskColumn, cskBar, cskPie, cskDonut);
  TPPGChartAxisSide = (casPrimary, casSecondary);
  TPPGChartXKind = (cxkCategory, cxkNumeric, cxkDateTime);
  TPPGChartStacking = (cstNone, cstStacked, cstPercent);
  TPPGChartLegendPosition = (clpNone, clpTop, clpBottom, clpRight);
  TPPGChartLineAxis = (claY, claY2, claX);

  TPPGChartPoint = record
    X: Double;
    Y: Double;
    Text: string;
    Color: TColor;   // clDefault = Serienfarbe (Kreis: Palette)
  end;

  TPPGChartSeries = class;

  /// Rueckmeldungen der Serien an das Diagramm (implementiert von TPPGChart).
  IPPGChartHost = interface
    ['{7D3B9E51-2A64-4C8F-B90E-5F1A6C3D2E87}']
    procedure ChartBeforeDataChange;
    procedure ChartDataChanged;
    procedure ChartInvalidate;
    function ChartCanAnimate: Boolean;
    function ChartAnimationDuration: Integer;
    procedure ChartGetPoint(Series: TPPGChartSeries; Index: Integer; var Point: TPPGChartPoint);
  end;

  TPPGChartSeries = class(TCollectionItem)
  private
    FTitle: string;
    FKind: TPPGChartSeriesKind;
    FColor: TColor;
    FVisible: Boolean;
    FYAxis: TPPGChartAxisSide;
    FLineWidth: Integer;
    FShowMarkers: Boolean;
    FValueFormat: string;
    // Getrennte Arrays statt TList<Record>: Lesen von X/Y ohne Kopie des
    // Records (String-Feld = CopyRecord), Text und Farbe nur bei Bedarf.
    // FStart: Versatz fuer das Lauffenster (Append), damit vorne Entfernen
    // nicht jedes Mal alle Werte verschiebt.
    FXs: TArray<Double>;
    FYs: TArray<Double>;
    FTexts: TArray<string>;
    FColors: TArray<TColor>;
    FStart: Integer;
    FCount: Integer;
    FVirtualCount: Integer;
    FVisAnim: TPPGAnimation;
    FOldY: TArray<Double>;   // angezeigte Werte vor der letzten Aenderung
    FTag: NativeInt;
    procedure Reserve(N: Integer);
    procedure Compact;
    procedure StoreAt(Phys: Integer; const X, Y: Double; const Text: string; Color: TColor);
    function Host: IPPGChartHost;
    procedure BeforeChange;
    procedure AfterChange;
    procedure SetTitle(const Value: string);
    procedure SetKind(const Value: TPPGChartSeriesKind);
    procedure SetColor(const Value: TColor);
    procedure SetVisible(const Value: Boolean);
    procedure SetYAxis(const Value: TPPGChartAxisSide);
    procedure SetLineWidth(const Value: Integer);
    procedure SetShowMarkers(const Value: Boolean);
    procedure SetValueFormat(const Value: string);
    procedure SetVirtualCount(const Value: Integer);
    function GetValuesText: string;
    procedure SetValuesText(const Value: string);
    function GetCount: Integer;
    function GetPoint(Index: Integer): TPPGChartPoint;
    function GetY(Index: Integer): Double;
    procedure SetY(Index: Integer; const Value: Double);
    procedure VisStep(Sender: TObject);
    function IsValuesTextStored: Boolean;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    /// Neuer Punkt auf der Kategorieachse (X = Index).
    function Add(const Y: Double; const Text: string = ''; Color: TColor = clDefault): Integer;
    function AddXY(const X, Y: Double; const Text: string = ''; Color: TColor = clDefault): Integer;
    procedure Delete(Index: Integer);
    procedure Clear;
    /// Alle Werte ersetzen (X = Index).
    procedure SetValues(const AValues: array of Double);
    /// Wert anhaengen und vorne kuerzen (Live-Daten; X = laufende Nummer).
    procedure Append(const Y: Double; MaxCount: Integer);
    /// Sichtbarkeit inkl. Ein-/Ausblend-Animation (0..1).
    function VisibleFactor: Single;
    /// Ein-/Ausblenden sofort beenden (Animationen abgeschaltet).
    procedure FinishAnimation;
    /// True, solange die Serie (auch ausblendend) gezeichnet wird.
    function IsDrawn: Boolean;
    function IsPie: Boolean;
    /// Fuer den Host: angezeigte Werte vor der Aenderung merken bzw. holen.
    procedure SnapshotOldY(const Values: TArray<Double>);
    property OldY: TArray<Double> read FOldY;
    property Count: Integer read GetCount;
    property Points[Index: Integer]: TPPGChartPoint read GetPoint;
    /// Schneller Zugriff ohne Record (Zeichnen, Layout). Virtuell: OnGetPoint.
    function XAt(Index: Integer): Double;
    function YAt(Index: Integer): Double;
    property Y[Index: Integer]: Double read GetY write SetY;
    property Tag: NativeInt read FTag write FTag;
  published
    property Title: string read FTitle write SetTitle;
    property Kind: TPPGChartSeriesKind read FKind write SetKind default cskLine;
    /// clDefault = Palette (Akzent zuerst).
    property Color: TColor read FColor write SetColor default clDefault;
    property Visible: Boolean read FVisible write SetVisible default True;
    property YAxis: TPPGChartAxisSide read FYAxis write SetYAxis default casPrimary;
    /// Strichstaerke in logischen px.
    property LineWidth: Integer read FLineWidth write SetLineWidth default 2;
    property ShowMarkers: Boolean read FShowMarkers write SetShowMarkers default False;
    /// FormatFloat-Maske im Tooltip (leer = Format der Achse).
    property ValueFormat: string read FValueFormat write SetValueFormat;
    /// > 0: Punkte kommen aus OnGetPoint (eigene Punkte werden ignoriert).
    property VirtualCount: Integer read FVirtualCount write SetVirtualCount default 0;
    property ValuesText: string read GetValuesText write SetValuesText stored IsValuesTextStored;
  end;

  TPPGChartSeriesList = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGChartSeries;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TPPGChartSeries;
    property Items[Index: Integer]: TPPGChartSeries read GetItem; default;
  end;

  TPPGChartAxis = class(TPersistent)
  private
    FOwner: TPersistent;
    FVisible: Boolean;
    FTitle: string;
    FAutoMin: Boolean;
    FAutoMax: Boolean;
    FMin: Double;
    FMax: Double;
    FFormat: string;
    FShowGrid: Boolean;
    FKind: TPPGChartXKind;
    FDefaultGrid: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetVisible(const Value: Boolean);
    procedure SetTitle(const Value: string);
    procedure SetAutoMin(const Value: Boolean);
    procedure SetAutoMax(const Value: Boolean);
    procedure SetMin(const Value: Double);
    procedure SetMax(const Value: Double);
    procedure SetFormat(const Value: string);
    procedure SetShowGrid(const Value: Boolean);
    procedure SetKind(const Value: TPPGChartXKind);
    function IsMinStored: Boolean;
    function IsMaxStored: Boolean;
    function IsShowGridStored: Boolean;
  protected
    procedure Changed;
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TPersistent; DefaultGrid: Boolean);
    procedure Assign(Source: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Visible: Boolean read FVisible write SetVisible default True;
    property Title: string read FTitle write SetTitle;
    property AutoMin: Boolean read FAutoMin write SetAutoMin default True;
    property AutoMax: Boolean read FAutoMax write SetAutoMax default True;
    property Min: Double read FMin write SetMin stored IsMinStored;
    property Max: Double read FMax write SetMax stored IsMaxStored;
    /// FormatFloat-Maske der Beschriftung (leer = aus der Schrittweite).
    property Format: string read FFormat write SetFormat;
    property ShowGrid: Boolean read FShowGrid write SetShowGrid stored IsShowGridStored;
    /// Nur X-Achse: Kategorien, Zahlen oder Datum/Zeit.
    property Kind: TPPGChartXKind read FKind write SetKind default cxkCategory;
  end;

  TPPGChartReferenceLine = class(TCollectionItem)
  private
    FValue: Double;
    FAxis: TPPGChartLineAxis;
    FCaption: string;
    FColor: TColor;
    FDashed: Boolean;
    procedure SetValue(const AValue: Double);
    procedure SetAxis(const AValue: TPPGChartLineAxis);
    procedure SetCaption(const AValue: string);
    procedure SetColor(const AValue: TColor);
    procedure SetDashed(const AValue: Boolean);
    function IsValueStored: Boolean;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
  published
    property Value: Double read FValue write SetValue stored IsValueStored;
    property Axis: TPPGChartLineAxis read FAxis write SetAxis default claY;
    property Caption: string read FCaption write SetCaption;
    /// clDefault = Sekundaertext.
    property Color: TColor read FColor write SetColor default clDefault;
    property Dashed: Boolean read FDashed write SetDashed default True;
  end;

  TPPGChartReferenceLines = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGChartReferenceLine;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TPPGChartReferenceLine;
    property Items[Index: Integer]: TPPGChartReferenceLine read GetItem; default;
  end;

implementation

uses
  PPG.Lang,
  System.Math, Vcl.Controls,
  PPG.Types, PPG.Consts, PPG.Exceptions, PPG.ErrorHandler, PPG.Sparkline;

{ TPPGChartSeries }

constructor TPPGChartSeries.Create(Collection: TCollection);
begin
  FColor := clDefault;
  FVisible := True;
  FLineWidth := 2;
  FVisAnim := TPPGAnimation.Create(Self);
  FVisAnim.Jump(1);
  FVisAnim.OnStep := VisStep;
  inherited Create(Collection);
end;

destructor TPPGChartSeries.Destroy;
begin
  if FVisAnim <> nil then
    FVisAnim.OnStep := nil;
  FreeAndNil(FVisAnim);
  inherited Destroy; // meldet sich bei der Collection ab (Update)
end;

procedure TPPGChartSeries.Assign(Source: TPersistent);
var
  S: TPPGChartSeries;
  I: Integer;
begin
  if Source is TPPGChartSeries then
  begin
    S := TPPGChartSeries(Source);
    BeforeChange;
    FTitle := S.FTitle;
    FKind := S.FKind;
    FColor := S.FColor;
    FVisible := S.FVisible;
    FVisAnim.Jump(Ord(FVisible));
    FYAxis := S.FYAxis;
    FLineWidth := S.FLineWidth;
    FShowMarkers := S.FShowMarkers;
    FValueFormat := S.FValueFormat;
    FVirtualCount := S.FVirtualCount;
    FStart := 0;
    FCount := S.FCount;
    SetLength(FXs, FCount);
    SetLength(FYs, FCount);
    for I := 0 to FCount - 1 do
    begin
      FXs[I] := S.FXs[S.FStart + I];
      FYs[I] := S.FYs[S.FStart + I];
    end;
    FTexts := nil;
    FColors := nil;
    if S.FTexts <> nil then
    begin
      SetLength(FTexts, FCount);
      for I := 0 to FCount - 1 do
        FTexts[I] := S.FTexts[S.FStart + I];
    end;
    if S.FColors <> nil then
    begin
      SetLength(FColors, FCount);
      for I := 0 to FCount - 1 do
        FColors[I] := S.FColors[S.FStart + I];
    end;
    AfterChange;
  end
  else
    inherited Assign(Source);
end;

function TPPGChartSeries.GetDisplayName: string;
begin
  if FTitle <> '' then
    Result := FTitle
  else
    Result := inherited GetDisplayName;
end;

function TPPGChartSeries.Host: IPPGChartHost;
begin
  Result := nil;
  if (Collection <> nil) and (TOwnedCollection(Collection).Owner <> nil) then
    Supports(TOwnedCollection(Collection).Owner, IPPGChartHost, Result);
end;

procedure TPPGChartSeries.BeforeChange;
var
  H: IPPGChartHost;
begin
  H := Host;
  if H <> nil then
    H.ChartBeforeDataChange;
end;

procedure TPPGChartSeries.AfterChange;
var
  H: IPPGChartHost;
begin
  H := Host;
  if H <> nil then
    H.ChartDataChanged;
end;

procedure TPPGChartSeries.VisStep(Sender: TObject);
var
  H: IPPGChartHost;
begin
  H := Host;
  if H <> nil then
    H.ChartInvalidate;
end;

procedure TPPGChartSeries.SnapshotOldY(const Values: TArray<Double>);
begin
  FOldY := Values;
end;

function TPPGChartSeries.VisibleFactor: Single;
begin
  Result := FVisAnim.Value;
end;

procedure TPPGChartSeries.FinishAnimation;
begin
  FVisAnim.Jump(Ord(FVisible));
end;

function TPPGChartSeries.IsDrawn: Boolean;
begin
  Result := FVisible or FVisAnim.Running;
end;

function TPPGChartSeries.IsPie: Boolean;
begin
  Result := FKind in [cskPie, cskDonut];
end;

function TPPGChartSeries.GetCount: Integer;
begin
  if FVirtualCount > 0 then
    Result := FVirtualCount
  else
    Result := FCount;
end;

procedure TPPGChartSeries.Compact;
var
  I: Integer;
begin
  if FStart = 0 then
    Exit;
  for I := 0 to FCount - 1 do
  begin
    FXs[I] := FXs[FStart + I];
    FYs[I] := FYs[FStart + I];
  end;
  if FTexts <> nil then
  begin
    for I := 0 to FCount - 1 do
      FTexts[I] := FTexts[FStart + I];
    for I := FCount to FCount + FStart - 1 do
      FTexts[I] := '';
  end;
  if FColors <> nil then
    for I := 0 to FCount - 1 do
      FColors[I] := FColors[FStart + I];
  FStart := 0;
end;

procedure TPPGChartSeries.Reserve(N: Integer);
var
  Cap: Integer;
begin
  // Platz fuer N Punkte ab FStart; vorne frei gewordenen Platz zuerst nutzen
  if FStart + N <= Length(FXs) then
    Exit;
  if (FStart > 0) and (N <= Length(FXs)) then
  begin
    Compact;
    Exit;
  end;
  Compact;
  Cap := Length(FXs) * 2;
  if Cap < 16 then
    Cap := 16;
  if Cap < N then
    Cap := N;
  SetLength(FXs, Cap);
  SetLength(FYs, Cap);
  if FTexts <> nil then
    SetLength(FTexts, Cap);
  if FColors <> nil then
    SetLength(FColors, Cap);
end;

procedure TPPGChartSeries.StoreAt(Phys: Integer; const X, Y: Double; const Text: string;
  Color: TColor);
var
  I: Integer;
begin
  FXs[Phys] := X;
  FYs[Phys] := Y;
  if (Text <> '') and (FTexts = nil) then
    SetLength(FTexts, Length(FXs));
  if FTexts <> nil then
    FTexts[Phys] := Text;
  if (Color <> clDefault) and (FColors = nil) then
  begin
    SetLength(FColors, Length(FXs));
    for I := 0 to High(FColors) do
      FColors[I] := clDefault;
  end;
  if FColors <> nil then
    FColors[Phys] := Color;
end;

function TPPGChartSeries.GetPoint(Index: Integer): TPPGChartPoint;
var
  H: IPPGChartHost;
begin
  if (Index < 0) or (Index >= Count) then
    raise EPPGPropertyError.CreateRange(Self, 'Points', Index, 0, Count - 1);
  if FVirtualCount > 0 then
  begin
    Result.X := Index;
    Result.Y := 0;
    Result.Text := '';
    Result.Color := clDefault;
    H := Host;
    if H <> nil then
      H.ChartGetPoint(Self, Index, Result);
    // Werte aus dem Ereignis: nicht endliche wie 0 bzw. Index behandeln,
    // sonst scheitern Round in Layout, Paint und Hit-Test
    if not PPGIsFinite(Result.X) then
      Result.X := Index;
    if not PPGIsFinite(Result.Y) then
      Result.Y := 0;
    Exit;
  end;
  Result.X := FXs[FStart + Index];
  Result.Y := FYs[FStart + Index];
  if FTexts <> nil then
    Result.Text := FTexts[FStart + Index]
  else
    Result.Text := '';
  if FColors <> nil then
    Result.Color := FColors[FStart + Index]
  else
    Result.Color := clDefault;
end;

function TPPGChartSeries.XAt(Index: Integer): Double;
begin
  if (FVirtualCount = 0) and (Index >= 0) and (Index < FCount) then
    Result := FXs[FStart + Index]
  else
    Result := GetPoint(Index).X;
end;

function TPPGChartSeries.YAt(Index: Integer): Double;
begin
  if (FVirtualCount = 0) and (Index >= 0) and (Index < FCount) then
    Result := FYs[FStart + Index]
  else
    Result := GetPoint(Index).Y;
end;

function TPPGChartSeries.GetY(Index: Integer): Double;
begin
  Result := GetPoint(Index).Y;
end;

procedure TPPGChartSeries.SetY(Index: Integer; const Value: Double);
begin
  if (Index < 0) or (Index >= FCount) then
    raise EPPGPropertyError.CreateRange(Self, 'Y', Index, 0, FCount - 1);
  // Audit 08.10.2026: NaN/Unendlich liessen Round in Layout und Hit-Test
  // scheitern (auch bei Mausbewegung) -> erst pruefen, dann aendern
  PPGCheckFinite(Self, 'Y', Value);
  BeforeChange;
  FYs[FStart + Index] := Value;
  AfterChange;
end;

function TPPGChartSeries.Add(const Y: Double; const Text: string; Color: TColor): Integer;
begin
  Result := AddXY(FCount, Y, Text, Color);
end;

function TPPGChartSeries.AddXY(const X, Y: Double; const Text: string; Color: TColor): Integer;
begin
  PPGCheckFinite(Self, 'X', X);
  PPGCheckFinite(Self, 'Y', Y);
  BeforeChange;
  Reserve(FCount + 1);
  StoreAt(FStart + FCount, X, Y, Text, Color);
  Result := FCount;
  Inc(FCount);
  AfterChange;
end;

procedure TPPGChartSeries.Delete(Index: Integer);
var
  I, P: Integer;
begin
  if (Index < 0) or (Index >= FCount) then
    raise EPPGPropertyError.CreateRange(Self, 'Index', Index, 0, FCount - 1);
  BeforeChange;
  if Index = 0 then
  begin
    // Vorne: nur den Versatz erhoehen (Lauffenster)
    if FTexts <> nil then
      FTexts[FStart] := '';
    Inc(FStart);
  end
  else
  begin
    P := FStart + Index;
    for I := P to FStart + FCount - 2 do
    begin
      FXs[I] := FXs[I + 1];
      FYs[I] := FYs[I + 1];
      if FTexts <> nil then
        FTexts[I] := FTexts[I + 1];
      if FColors <> nil then
        FColors[I] := FColors[I + 1];
    end;
    if FTexts <> nil then
      FTexts[FStart + FCount - 1] := '';
  end;
  Dec(FCount);
  if FCount = 0 then
    FStart := 0;
  AfterChange;
end;

procedure TPPGChartSeries.Clear;
begin
  if FCount = 0 then
    Exit;
  BeforeChange;
  FXs := nil;
  FYs := nil;
  FTexts := nil;
  FColors := nil;
  FStart := 0;
  FCount := 0;
  AfterChange;
end;

procedure TPPGChartSeries.SetValues(const AValues: array of Double);
var
  I: Integer;
begin
  for I := 0 to High(AValues) do
    PPGCheckFinite(Self, 'Values', AValues[I]);
  BeforeChange;
  FStart := 0;
  FCount := Length(AValues);
  FXs := nil;
  FYs := nil;
  FTexts := nil;
  FColors := nil;
  SetLength(FXs, FCount);
  SetLength(FYs, FCount);
  for I := 0 to FCount - 1 do
  begin
    FXs[I] := I;
    FYs[I] := AValues[I];
  end;
  AfterChange;
end;

procedure TPPGChartSeries.Append(const Y: Double; MaxCount: Integer);
var
  X: Double;
begin
  PPGCheckFinite(Self, 'Y', Y);
  BeforeChange;
  if FCount > 0 then
    X := FXs[FStart + FCount - 1] + 1
  else
    X := 0;
  Reserve(FCount + 1);
  StoreAt(FStart + FCount, X, Y, '', clDefault);
  Inc(FCount);
  if MaxCount > 0 then
    while FCount > MaxCount do
    begin
      if FTexts <> nil then
        FTexts[FStart] := '';
      Inc(FStart);
      Dec(FCount);
    end;
  AfterChange;
end;

function TPPGChartSeries.GetValuesText: string;
var
  V: TArray<Double>;
  I: Integer;
begin
  SetLength(V, FCount);
  for I := 0 to FCount - 1 do
    V[I] := FYs[FStart + I];
  Result := PPGFormatValueList(V);
end;

procedure TPPGChartSeries.SetValuesText(const Value: string);
var
  V: TArray<Double>;
begin
  if not PPGParseValueList(Value, V) then
  begin
    if not PPGIsLoading(Self) then
      raise EPPGPropertyError.CreateInvalid(Self, 'ValuesText', Value);
    TPPGErrorHandler.LogWarning(Self, System.SysUtils.Format(PPGStr(@SPPGInvalidValueList), [Value]));
    Exit;
  end;
  SetValues(V);
end;

function TPPGChartSeries.IsValuesTextStored: Boolean;
begin
  Result := (FVirtualCount = 0) and (FCount > 0);
end;

procedure TPPGChartSeries.SetTitle(const Value: string);
begin
  if FTitle <> Value then
  begin
    FTitle := Value;
    Changed(False);
  end;
end;

procedure TPPGChartSeries.SetKind(const Value: TPPGChartSeriesKind);
begin
  if FKind <> Value then
  begin
    FKind := Value;
    Changed(False);
  end;
end;

procedure TPPGChartSeries.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Changed(False);
  end;
end;

procedure TPPGChartSeries.SetVisible(const Value: Boolean);
var
  H: IPPGChartHost;
begin
  if FVisible = Value then
    Exit;
  FVisible := Value;
  H := Host;
  if (H <> nil) and H.ChartCanAnimate then
    FVisAnim.AnimateTo(Ord(Value), H.ChartAnimationDuration, ekDecelerate)
  else
    FVisAnim.Jump(Ord(Value));
  Changed(False);
end;

procedure TPPGChartSeries.SetYAxis(const Value: TPPGChartAxisSide);
begin
  if FYAxis <> Value then
  begin
    FYAxis := Value;
    Changed(False);
  end;
end;

procedure TPPGChartSeries.SetLineWidth(const Value: Integer);
begin
  FLineWidth := PPGCheckRange(Self, 'LineWidth', Value, 1, 20);
  Changed(False);
end;

procedure TPPGChartSeries.SetShowMarkers(const Value: Boolean);
begin
  if FShowMarkers <> Value then
  begin
    FShowMarkers := Value;
    Changed(False);
  end;
end;

procedure TPPGChartSeries.SetValueFormat(const Value: string);
begin
  if FValueFormat <> Value then
  begin
    FValueFormat := Value;
    Changed(False);
  end;
end;

procedure TPPGChartSeries.SetVirtualCount(const Value: Integer);
begin
  if FVirtualCount = Value then
    Exit;
  FVirtualCount := PPGCheckRange(Self, 'VirtualCount', Value, 0, MaxInt);
  AfterChange;
end;

{ TPPGChartSeriesList }

constructor TPPGChartSeriesList.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TPPGChartSeries);
end;

function TPPGChartSeriesList.Add: TPPGChartSeries;
begin
  Result := TPPGChartSeries(inherited Add);
end;

function TPPGChartSeriesList.GetItem(Index: Integer): TPPGChartSeries;
begin
  Result := TPPGChartSeries(inherited Items[Index]);
end;

procedure TPPGChartSeriesList.Update(Item: TCollectionItem);
var
  H: IPPGChartHost;
begin
  inherited Update(Item);
  if (Owner <> nil) and Supports(Owner, IPPGChartHost, H) then
    H.ChartDataChanged;
end;

{ TPPGChartAxis }

constructor TPPGChartAxis.Create(AOwner: TPersistent; DefaultGrid: Boolean);
begin
  inherited Create;
  FOwner := AOwner;
  FVisible := True;
  FAutoMin := True;
  FAutoMax := True;
  FDefaultGrid := DefaultGrid;
  FShowGrid := DefaultGrid;
end;

procedure TPPGChartAxis.Assign(Source: TPersistent);
var
  A: TPPGChartAxis;
begin
  if Source is TPPGChartAxis then
  begin
    A := TPPGChartAxis(Source);
    FVisible := A.FVisible;
    FTitle := A.FTitle;
    FAutoMin := A.FAutoMin;
    FAutoMax := A.FAutoMax;
    FMin := A.FMin;
    FMax := A.FMax;
    FFormat := A.FFormat;
    FShowGrid := A.FShowGrid;
    FKind := A.FKind;
    Changed;
  end
  else
    inherited Assign(Source);
end;

function TPPGChartAxis.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TPPGChartAxis.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGChartAxis.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    Changed;
  end;
end;

procedure TPPGChartAxis.SetTitle(const Value: string);
begin
  if FTitle <> Value then
  begin
    FTitle := Value;
    Changed;
  end;
end;

procedure TPPGChartAxis.SetAutoMin(const Value: Boolean);
begin
  if FAutoMin <> Value then
  begin
    FAutoMin := Value;
    Changed;
  end;
end;

procedure TPPGChartAxis.SetAutoMax(const Value: Boolean);
begin
  if FAutoMax <> Value then
  begin
    FAutoMax := Value;
    Changed;
  end;
end;

procedure TPPGChartAxis.SetMin(const Value: Double);
begin
  PPGCheckFinite(Self, 'Min', Value);
  if FMin <> Value then
  begin
    FMin := Value;
    Changed;
  end;
end;

procedure TPPGChartAxis.SetMax(const Value: Double);
begin
  PPGCheckFinite(Self, 'Max', Value);
  if FMax <> Value then
  begin
    FMax := Value;
    Changed;
  end;
end;

procedure TPPGChartAxis.SetFormat(const Value: string);
begin
  if FFormat <> Value then
  begin
    FFormat := Value;
    Changed;
  end;
end;

procedure TPPGChartAxis.SetShowGrid(const Value: Boolean);
begin
  if FShowGrid <> Value then
  begin
    FShowGrid := Value;
    Changed;
  end;
end;

procedure TPPGChartAxis.SetKind(const Value: TPPGChartXKind);
begin
  if FKind <> Value then
  begin
    FKind := Value;
    Changed;
  end;
end;

function TPPGChartAxis.IsMinStored: Boolean;
begin
  Result := FMin <> 0;
end;

function TPPGChartAxis.IsMaxStored: Boolean;
begin
  Result := FMax <> 0;
end;

function TPPGChartAxis.IsShowGridStored: Boolean;
begin
  Result := FShowGrid <> FDefaultGrid;
end;

{ TPPGChartReferenceLine }

constructor TPPGChartReferenceLine.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FColor := clDefault;
  FDashed := True;
end;

procedure TPPGChartReferenceLine.Assign(Source: TPersistent);
var
  L: TPPGChartReferenceLine;
begin
  if Source is TPPGChartReferenceLine then
  begin
    L := TPPGChartReferenceLine(Source);
    FValue := L.FValue;
    FAxis := L.FAxis;
    FCaption := L.FCaption;
    FColor := L.FColor;
    FDashed := L.FDashed;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGChartReferenceLine.IsValueStored: Boolean;
begin
  Result := FValue <> 0;
end;

procedure TPPGChartReferenceLine.SetValue(const AValue: Double);
begin
  PPGCheckFinite(Self, 'Value', AValue);
  if FValue <> AValue then
  begin
    FValue := AValue;
    Changed(False);
  end;
end;

procedure TPPGChartReferenceLine.SetAxis(const AValue: TPPGChartLineAxis);
begin
  if FAxis <> AValue then
  begin
    FAxis := AValue;
    Changed(False);
  end;
end;

procedure TPPGChartReferenceLine.SetCaption(const AValue: string);
begin
  if FCaption <> AValue then
  begin
    FCaption := AValue;
    Changed(False);
  end;
end;

procedure TPPGChartReferenceLine.SetColor(const AValue: TColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;
    Changed(False);
  end;
end;

procedure TPPGChartReferenceLine.SetDashed(const AValue: Boolean);
begin
  if FDashed <> AValue then
  begin
    FDashed := AValue;
    Changed(False);
  end;
end;

{ TPPGChartReferenceLines }

constructor TPPGChartReferenceLines.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TPPGChartReferenceLine);
end;

function TPPGChartReferenceLines.Add: TPPGChartReferenceLine;
begin
  Result := TPPGChartReferenceLine(inherited Add);
end;

function TPPGChartReferenceLines.GetItem(Index: Integer): TPPGChartReferenceLine;
begin
  Result := TPPGChartReferenceLine(inherited Items[Index]);
end;

procedure TPPGChartReferenceLines.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Owner is TControl then
    TControl(Owner).Invalidate;
end;

end.
