unit PPG.Chart;

{ TPPGChart - Diagramm im Stil der Suite (Phase 10d).

  - Serien (PPG.Chart.Series): Linie, Stufe, Flaeche, Saeule, Balken, Kreis,
    Ring. Linien, Flaechen und Saeulen lassen sich mischen; sind alle
    sichtbaren Serien Balken, liegt das Diagramm quer (Kategorien senkrecht).
    Ist die erste sichtbare Serie ein Kreis/Ring, zeigt das Diagramm nur sie.
  - Achsen: X als Kategorie, Zahl oder Datum/Zeit; Y links und optional eine
    zweite Y-Achse rechts (Series.YAxis = casSecondary). Grenzen automatisch
    (PPG.Chart.Scale) oder fest; Referenzlinien (ReferenceLines).
  - Stapeln (Stacking) fuer Saeulen, Balken und Flaechen auf der
    Kategorieachse, auch als 100 %.
  - Legende oben, unten oder rechts; Klick blendet eine Serie aus/ein
    (animiert).
  - Tooltip beim Ueberfahren: rastet auf den naechsten X-Wert ein (Linie ueber
    alle Serien) bzw. auf das Segment beim Kreis. Der Tooltip ist Teil des
    Controls (kein eigenes Fenster): er erscheint so auch beim Export und in
    Screenshots.
  - Tastatur: Pfeile links/rechts laufen durch die Punkte, hoch/runter bzw.
    Bild wechseln die Serie, Pos1/Ende, Enter/Leertaste = OnPointClick,
    Esc blendet den Tooltip aus.
  - Animation ueber den gemeinsamen Animator: Aufbau beim ersten Zeigen,
    weicher Uebergang bei Datenaenderungen (bis 10 000 Punkte), Ein-/
    Ausblenden von Serien.
  - Viele Punkte: Linien werden pro Pixelspalte auf Min/Max verdichtet.
  - Export: SaveToBitmap, SaveToPng, CopyToClipboard (gleicher Zeichenweg).
  - Screenreader: Rolle Diagramm, Kinder = Datenpunkte ("Serie, Kategorie:
    Wert"), hoechstens 500 je Serie.
  - RTL: Y-Achse rechts, Legende von rechts; die X-Richtung bleibt (wie
    Excel). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Tokens, PPG.Animation, PPG.Render.Intf, PPG.Controls.Base,
  PPG.Accessibility, PPG.Chart.Scale, PPG.Chart.Series, PPG.ElementStyle;

type
  TPPGChartPointEvent = procedure(Sender: TObject; SeriesIndex, PointIndex: Integer) of object;
  TPPGChartGetPointEvent = procedure(Sender: TObject; SeriesIndex, Index: Integer;
    var Point: TPPGChartPoint) of object;

  TPPGChartMode = (cmEmpty, cmCartesian, cmHorizontal, cmPie);
  TPPGChartHitKind = (chkNone, chkPlot, chkLegend);

  TPPGChartHit = record
    Kind: TPPGChartHitKind;
    Series: Integer;   // Index in Series (-1 = keine bestimmte)
    Index: Integer;    // Punkt bzw. Kategorie (-1 = keiner)
  end;

  TPPGChartLegendItem = record
    R: TRect;
    Index: Integer;    // Serie (Kreis: Punkt)
  end;

  /// Ergebnis der Layout-Berechnung (rein aus dem Zustand, ohne Seiteneffekte).
  TPPGChartLayout = record
    Mode: TPPGChartMode;
    Content: TRect;
    TitleR: TRect;
    LegendR: TRect;
    PlotR: TRect;
    PieSeries: Integer;
    YScale: TPPGAxisScale;
    Y2Scale: TPPGAxisScale;
    XScale: TPPGAxisScale;
    DateScale: TPPGDateScale;
    HasY2: Boolean;
    CatCount: Integer;
    PieCenter: TPoint;
    PieRadius: Integer;
    PieInner: Integer;
    FontH: Integer;
    Legend: TArray<TPPGChartLegendItem>;
  end;

  /// Bereiche des Diagramms (nur gesetzte Werte zaehlen, clDefault = Preset).
  TPPGChartStyles = class(TPPGStyleGroup)
  public
    constructor Create(AOwner: TPersistent);
  published
    /// Titel: TextColor, Schrift (ohne eigene Schrift: 1,25-fach fett).
    property Title: TPPGElementStyle index 0 read GetItem write SetItem;
    /// Achsenbeschriftung und -titel: TextColor.
    property Axis: TPPGElementStyle index 1 read GetItem write SetItem;
    /// Gitterlinien: Color.
    property Grid: TPPGElementStyle index 2 read GetItem write SetItem;
    /// Legende: TextColor, Schrift.
    property Legend: TPPGElementStyle index 3 read GetItem write SetItem;
  end;

  TPPGCustomChart = class(TPPGCustomControl, IPPGChartHost, IPPGAccessibleChildren)
  private
    FSeries: TPPGChartSeriesList;
    FCategories: TStrings;
    FChartStyles: TPPGChartStyles;
    FFonts: TPPGFontCache;
    FXAxis: TPPGChartAxis;
    FYAxis: TPPGChartAxis;
    FY2Axis: TPPGChartAxis;
    FReferenceLines: TPPGChartReferenceLines;
    FStacking: TPPGChartStacking;
    FLegendPosition: TPPGChartLegendPosition;
    FTitle: string;
    FShowTooltips: Boolean;
    FLegendToggle: Boolean;
    FIntroAnim: TPPGAnimation;
    FChangeAnim: TPPGAnimation;
    FIntroDone: Boolean;
    FDataUpdateCount: Integer;
    FDataChangePending: Boolean;
    FSnapshotTaken: Boolean;
    FHot: TPPGChartHit;
    FHotDataX: Double;
    FMousePos: TPoint;
    FFocusSeries: Integer;
    FFocusIndex: Integer;
    FMarkedIndex: Integer;
    FOnPointClick: TPPGChartPointEvent;
    FOnGetPoint: TPPGChartGetPointEvent;
    procedure SetChartStyles(const Value: TPPGChartStyles);
    procedure ChartStylesChanged(Sender: TObject);
    /// Titel-Schrift: eigene (Styles.Title) bzw. 1,25-fach fett; Temp freigeben.
    function TitleFont(var Temp: TFont): TFont;
    function LegendFont: TFont;
    procedure SetSeries(const Value: TPPGChartSeriesList);
    procedure SetCategories(const Value: TStrings);
    procedure SetXAxis(const Value: TPPGChartAxis);
    procedure SetYAxis(const Value: TPPGChartAxis);
    procedure SetY2Axis(const Value: TPPGChartAxis);
    procedure SetReferenceLines(const Value: TPPGChartReferenceLines);
    procedure SetStacking(const Value: TPPGChartStacking);
    procedure SetLegendPosition(const Value: TPPGChartLegendPosition);
    procedure SetTitle(const Value: string);
    procedure SetShowTooltips(const Value: Boolean);
    procedure SetMarkedIndex(const Value: Integer);
    procedure AxisChanged(Sender: TObject);
    procedure CategoriesChanged(Sender: TObject);
    procedure AnimStep(Sender: TObject);
    procedure StartIntro;
    function TotalPoints: Integer;
    procedure SetHot(const Hit: TPPGChartHit; DataX: Double);
    procedure ClampFocus;
    function FirstDrawnSeries: Integer;
    /// Breiteste Kategorie-Beschriftung (Stichprobe aus etwa 60).
    function CategoryLabelWidth(Count: Integer): Integer;
    function NextDrawnSeries(From, Dir: Integer): Integer;
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    { IPPGChartHost }
    procedure ChartBeforeDataChange;
    procedure ChartDataChanged;
    procedure ChartInvalidate;
    function ChartCanAnimate: Boolean;
    function ChartAnimationDuration: Integer;
    procedure ChartGetPoint(Series: TPPGChartSeries; Index: Integer; var Point: TPPGChartPoint);
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

    procedure Loaded; override;
    procedure CreateWnd; override;
    procedure UpdateVisualState(Animate: Boolean = True); override;
    function IsHot: Boolean; override;
    /// Hover je Element; IsHot bleibt False (Audit 8a #2).
    function UsesHotAnimation: Boolean; override;
    function IsDown: Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure DoPointClick(SeriesIndex, PointIndex: Integer); virtual;
    /// Dauerhaft markierte Kategorie bzw. markierter Punkt (DB: aktueller
    /// Datensatz), -1 = keine. Zeichnet ein dezentes Band bzw. eine Linie.
    property MarkedIndex: Integer read FMarkedIndex write SetMarkedIndex;
    function AccName: string; override;
    function AccRole: Integer; override;
    function AccState: Integer; override;
    function AccValue: string; override;

    property Series: TPPGChartSeriesList read FSeries write SetSeries;
    /// Beschriftung der Kategorieachse (sonst Punkt-Text bzw. 1, 2, 3 ...).
    property Categories: TStrings read FCategories write SetCategories;
    property XAxis: TPPGChartAxis read FXAxis write SetXAxis;
    property YAxis: TPPGChartAxis read FYAxis write SetYAxis;
    /// Zweite Y-Achse rechts (nur sichtbar, wenn eine Serie sie nutzt).
    property Y2Axis: TPPGChartAxis read FY2Axis write SetY2Axis;
    property ReferenceLines: TPPGChartReferenceLines read FReferenceLines write SetReferenceLines;
    property Stacking: TPPGChartStacking read FStacking write SetStacking default cstNone;
    property LegendPosition: TPPGChartLegendPosition read FLegendPosition
      write SetLegendPosition default clpBottom;
    property Title: string read FTitle write SetTitle;
    property ShowTooltips: Boolean read FShowTooltips write SetShowTooltips default True;
    /// Klick auf einen Legendeneintrag blendet die Serie aus/ein.
    property LegendToggle: Boolean read FLegendToggle write FLegendToggle default True;
    /// Bereiche (Titel, Achsen, Gitter, Legende).
    property Styles: TPPGChartStyles read FChartStyles write SetChartStyles;
    property OnPointClick: TPPGChartPointEvent read FOnPointClick write FOnPointClick;
    property OnGetPoint: TPPGChartGetPointEvent read FOnGetPoint write FOnGetPoint;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Mehrere Datenaenderungen buendeln (ein Uebergang, ein Neuzeichnen).
    procedure BeginDataUpdate;
    procedure EndDataUpdate;
    /// Layout fuer die aktuelle Groesse (fuer Tests und Hit-Tests).
    function Layout: TPPGChartLayout;
    function HitTest(X, Y: Integer): TPPGChartHit;
    /// Pixel eines Datenpunkts (False, wenn nicht gezeichnet).
    function PointPos(SeriesIndex, PointIndex: Integer; out P: TPoint): Boolean;
    /// Farbe einer Serie bzw. eines Kreissegments, wie gezeichnet.
    function SeriesColor(SeriesIndex: Integer): TColor;
    function SliceColor(SeriesIndex, PointIndex: Integer): TColor;
    /// Text der Kategorie bzw. des X-Werts eines Punkts.
    function XLabel(SeriesIndex, PointIndex: Integer): string;
    function ValueText(SeriesIndex: Integer; Value: Double): string;
    /// Tastaturfokus auf einem Punkt (-1 = keiner).
    procedure FocusPoint(SeriesIndex, PointIndex: Integer);
    procedure SaveToBitmap(Bitmap: TBitmap);
    procedure SaveToPng(const FileName: string);
    procedure CopyToClipboard;
    property Hot: TPPGChartHit read FHot;
    property FocusSeries: Integer read FFocusSeries;
    property FocusIndex: Integer read FFocusIndex;
    /// Fortschritt der Aufbau-Animation (1 = fertig).
    function IntroProgress: Single;
    /// Fortschritt des Uebergangs nach einer Datenaenderung (1 = fertig).
    function ChangeProgress: Single;
  end;

  TPPGChart = class(TPPGCustomChart)
  published
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
    property Styles;
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
    property OnGetPoint;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnPointClick;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseActivate;
    property OnContextPopup;
    property StyleElements;
    property DragMode;
    property DragCursor;
    property OnDragDrop;
    property OnDragOver;
    property OnStartDrag;
    property OnEndDrag;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property Color;
    property ParentColor;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

implementation

uses
  PPG.Lang,
  System.Math, Winapi.oleacc, Vcl.Clipbrd,
  PPG.Consts, PPG.Exceptions, PPG.Appearance, PPG.DpiUtils, PPG.Chart.Palette,
  PPG.Render.Registry, PPG.Render.Gdi, PPG.Render.GdiPlus, PPG.Render.Shapes;

const
  ChartPad = 8;          // logische px Rand
  MaxSnapshotPoints = 10000;
  AccMaxPerSeries = 500;
  HoverRadius = 4;       // logische px Markierung am Tooltip-Punkt

type
  TSeriesFrame = record
    Index: Integer;
    Xs: TArray<Double>;    // Datenwerte X (Kategorie: Index)
    Ys: TArray<Double>;    // angezeigte Y (animiert)
    Lo: TArray<Double>;    // Stapel: Unterkante (sonst 0)
    Hi: TArray<Double>;    // Stapel: Oberkante (sonst Ys)
    Stacked: Boolean;
  end;

{ ---- Hilfen ---- }

function IsColumnKind(K: TPPGChartSeriesKind): Boolean;
begin
  Result := K in [cskColumn, cskBar];
end;

function IsStackKind(K: TPPGChartSeriesKind): Boolean;
begin
  Result := K in [cskColumn, cskBar, cskArea];
end;

function DefaultFormatValue(V: Double): string;
begin
  Result := FormatFloat('#,##0.##', V);
end;

{ TPPGChartStyles }

constructor TPPGChartStyles.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, 4);
end;

{ TPPGCustomChart }

constructor TPPGCustomChart.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption];
  FSeries := TPPGChartSeriesList.Create(Self);
  FChartStyles := TPPGChartStyles.Create(Self);
  FChartStyles.OnChange := ChartStylesChanged;
  FFonts := TPPGFontCache.Create;
  FCategories := TStringList.Create;
  TStringList(FCategories).OnChange := CategoriesChanged;
  FXAxis := TPPGChartAxis.Create(Self, False);
  FXAxis.IsXAxis := True;
  FXAxis.OnChange := AxisChanged;
  FYAxis := TPPGChartAxis.Create(Self, True);
  FYAxis.OnChange := AxisChanged;
  FY2Axis := TPPGChartAxis.Create(Self, False);
  FY2Axis.OnChange := AxisChanged;
  FReferenceLines := TPPGChartReferenceLines.Create(Self);
  FLegendPosition := clpBottom;
  FShowTooltips := True;
  FLegendToggle := True;
  FIntroAnim := TPPGAnimation.Create(Self);
  FIntroAnim.Jump(1);
  FIntroAnim.OnStep := AnimStep;
  FChangeAnim := TPPGAnimation.Create(Self);
  FChangeAnim.Jump(1);
  FChangeAnim.OnStep := AnimStep;
  FHot.Kind := chkNone;
  FHot.Series := -1;
  FHot.Index := -1;
  FFocusSeries := -1;
  FFocusIndex := -1;
  FMarkedIndex := -1;
  TabStop := True;
  Width := 400;
  Height := 260;
end;

procedure TPPGCustomChart.SetChartStyles(const Value: TPPGChartStyles);
begin
  FChartStyles.Assign(Value);
end;

procedure TPPGCustomChart.ChartStylesChanged(Sender: TObject);
begin
  FFonts.Clear;
  Invalidate;
end;

function TPPGCustomChart.TitleFont(var Temp: TFont): TFont;
begin
  if FChartStyles.Title.HasOwnFont then
    Result := PPGStyledFont(FChartStyles.Title.Font, FChartStyles.Title.FontStyle, Temp)
  else
  begin
    if Temp = nil then
      Temp := TFont.Create;
    Temp.Assign(Font);
    Temp.Style := [fsBold] + FChartStyles.Title.FontStyle;
    Temp.Height := Round(Font.Height * 1.25);
    Result := Temp;
  end;
end;

function TPPGCustomChart.LegendFont: TFont;
begin
  // Zwischengespeichert bis zum Ende des Zeichnens bzw. bis zur naechsten
  // Stil- oder Schriftaenderung
  Result := FFonts.ForStyle(FChartStyles.Legend, Font);
end;

destructor TPPGCustomChart.Destroy;
begin
  FreeAndNil(FFonts);
  if FChartStyles <> nil then
    FChartStyles.OnChange := nil;
  FreeAndNil(FChartStyles);
  if FIntroAnim <> nil then
    FIntroAnim.OnStep := nil;
  if FChangeAnim <> nil then
    FChangeAnim.OnStep := nil;
  FreeAndNil(FIntroAnim);
  FreeAndNil(FChangeAnim);
  // Serien zuerst: ihre Animationen und Rueckmeldungen brauchen uns noch
  FreeAndNil(FSeries);
  FreeAndNil(FReferenceLines);
  FreeAndNil(FXAxis);
  FreeAndNil(FYAxis);
  FreeAndNil(FY2Axis);
  if FCategories <> nil then
    TStringList(FCategories).OnChange := nil;
  FreeAndNil(FCategories);
  inherited Destroy;
end;

procedure TPPGCustomChart.Loaded;
begin
  inherited Loaded;
  ClampFocus;
  StartIntro;
end;

procedure TPPGCustomChart.CreateWnd;
begin
  inherited CreateWnd;
  StartIntro;
end;

procedure TPPGCustomChart.UpdateVisualState(Animate: Boolean);
var
  I: Integer;
begin
  inherited UpdateVisualState(Animate);
  // Animationen abgeschaltet (auch waehrend sie laufen): sofort ans Ziel,
  // sonst bliebe das Diagramm im Zwischenstand stehen
  if (FIntroAnim <> nil) and not Animation.EffectiveEnabled then
  begin
    FIntroAnim.Jump(1);
    FChangeAnim.Jump(1);
    if FSeries <> nil then
      for I := 0 to FSeries.Count - 1 do
        FSeries[I].FinishAnimation;
    Invalidate;
  end;
end;

function TPPGCustomChart.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGCustomChart.IsDown: Boolean;
begin
  Result := False;
end;

function TPPGCustomChart.UsesHotAnimation: Boolean;
begin
  Result := False;
end;

function TPPGCustomChart.IntroProgress: Single;
begin
  Result := FIntroAnim.Value;
end;

function TPPGCustomChart.ChangeProgress: Single;
begin
  Result := FChangeAnim.Value;
end;

procedure TPPGCustomChart.AnimStep(Sender: TObject);
begin
  Invalidate;
end;

procedure TPPGCustomChart.AxisChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TPPGCustomChart.CategoriesChanged(Sender: TObject);
begin
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

procedure TPPGCustomChart.SetSeries(const Value: TPPGChartSeriesList);
begin
  FSeries.Assign(Value);
end;

procedure TPPGCustomChart.SetCategories(const Value: TStrings);
begin
  FCategories.Assign(Value);
end;

procedure TPPGCustomChart.SetXAxis(const Value: TPPGChartAxis);
begin
  FXAxis.Assign(Value);
end;

procedure TPPGCustomChart.SetYAxis(const Value: TPPGChartAxis);
begin
  FYAxis.Assign(Value);
end;

procedure TPPGCustomChart.SetY2Axis(const Value: TPPGChartAxis);
begin
  FY2Axis.Assign(Value);
end;

procedure TPPGCustomChart.SetReferenceLines(const Value: TPPGChartReferenceLines);
begin
  FReferenceLines.Assign(Value);
end;

procedure TPPGCustomChart.SetStacking(const Value: TPPGChartStacking);
begin
  if FStacking <> Value then
  begin
    FStacking := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomChart.SetLegendPosition(const Value: TPPGChartLegendPosition);
begin
  if FLegendPosition <> Value then
  begin
    FLegendPosition := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomChart.SetTitle(const Value: string);
begin
  if FTitle <> Value then
  begin
    FTitle := Value;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_NAMECHANGE);
  end;
end;

procedure TPPGCustomChart.SetShowTooltips(const Value: Boolean);
begin
  if FShowTooltips <> Value then
  begin
    FShowTooltips := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomChart.SetMarkedIndex(const Value: Integer);
begin
  if FMarkedIndex <> Value then
  begin
    FMarkedIndex := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomChart.CMShowingChanged(var Message: TMessage);
begin
  inherited;
  StartIntro;
end;

procedure TPPGCustomChart.CMFontChanged(var Message: TMessage);
begin
  FFonts.Clear;
  inherited;
  Invalidate;
end;

procedure TPPGCustomChart.CMMouseLeave(var Message: TMessage);
var
  H: TPPGChartHit;
begin
  inherited;
  H.Kind := chkNone;
  H.Series := -1;
  H.Index := -1;
  SetHot(H, 0);
end;

procedure TPPGCustomChart.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

{ ---- Daten und Animation ---- }

function TPPGCustomChart.TotalPoints: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FSeries.Count - 1 do
    Inc(Result, FSeries[I].Count);
end;

function TPPGCustomChart.ChartCanAnimate: Boolean;
begin
  Result := HandleAllocated and Showing and not (csLoading in ComponentState) and
    not (csDesigning in ComponentState) and not (csDestroying in ComponentState) and
    Animation.EffectiveEnabled;
end;

function TPPGCustomChart.ChartAnimationDuration: Integer;
begin
  Result := Animation.Duration * 2;
end;

procedure TPPGCustomChart.StartIntro;
begin
  if FIntroDone or (csLoading in ComponentState) or not HandleAllocated or not Showing then
    Exit;
  if TotalPoints = 0 then
    Exit; // Aufbau erst mit den ersten Daten (ChartDataChanged)
  FIntroDone := True;
  if ChartCanAnimate then
  begin
    FIntroAnim.Jump(0);
    FIntroAnim.AnimateTo(1, Animation.Duration * 4, ekDecelerate);
  end;
end;

procedure TPPGCustomChart.ChartBeforeDataChange;
var
  I, J: Integer;
  S: TPPGChartSeries;
  V: TArray<Double>;
  T: Single;
begin
  if FSnapshotTaken or not FIntroDone or not ChartCanAnimate then
    Exit;
  FSnapshotTaken := True;
  if TotalPoints > MaxSnapshotPoints then
    Exit;
  // Angezeigte Werte merken (waehrend eines Uebergangs die Zwischenwerte)
  T := FChangeAnim.Value;
  for I := 0 to FSeries.Count - 1 do
  begin
    S := FSeries[I];
    SetLength(V, S.Count);
    for J := 0 to S.Count - 1 do
    begin
      V[J] := S.YAt(J);
      if FChangeAnim.Running and (J < Length(S.OldY)) then
        V[J] := S.OldY[J] + (V[J] - S.OldY[J]) * T;
    end;
    S.SnapshotOldY(V);
    V := nil;
  end;
end;

procedure TPPGCustomChart.ChartDataChanged;
var
  I: Integer;
  Same: Boolean;
begin
  if (FSeries = nil) or (csDestroying in ComponentState) then
    Exit;
  if FDataUpdateCount > 0 then
  begin
    FDataChangePending := True;
    Exit;
  end;
  FDataChangePending := False;
  if FSnapshotTaken then
  begin
    FSnapshotTaken := False;
    Same := True;
    for I := 0 to FSeries.Count - 1 do
      if Length(FSeries[I].OldY) <> FSeries[I].Count then
        Same := False;
    if Same and ChartCanAnimate and (TotalPoints <= MaxSnapshotPoints) then
    begin
      FChangeAnim.Jump(0);
      FChangeAnim.AnimateTo(1, ChartAnimationDuration, ekDecelerate);
    end
    else
    begin
      FChangeAnim.Jump(1);
      for I := 0 to FSeries.Count - 1 do
        FSeries[I].SnapshotOldY(nil);
    end;
  end;
  if not FIntroDone then
    StartIntro;
  ClampFocus;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

procedure TPPGCustomChart.ChartInvalidate;
begin
  Invalidate;
end;

procedure TPPGCustomChart.ChartGetPoint(Series: TPPGChartSeries; Index: Integer;
  var Point: TPPGChartPoint);
begin
  if Assigned(FOnGetPoint) then
    FOnGetPoint(Self, Series.Index, Index, Point);
end;

procedure TPPGCustomChart.BeginDataUpdate;
begin
  Inc(FDataUpdateCount);
end;

procedure TPPGCustomChart.EndDataUpdate;
begin
  if FDataUpdateCount > 0 then
    Dec(FDataUpdateCount);
  if (FDataUpdateCount = 0) and (FDataChangePending or FSnapshotTaken) then
    ChartDataChanged;
end;

{ ---- Farben und Texte ---- }

function TPPGCustomChart.SeriesColor(SeriesIndex: Integer): TColor;
var
  S: TPPGChartSeries;
begin
  if UseHighContrast then
    Exit(PPGChartHighContrastColor(SeriesIndex));
  if not Enabled then
    Exit(Tokens.TextDisabled);
  S := FSeries[SeriesIndex];
  if S.Color <> clDefault then
    Result := PPGColorToRGB(S.Color)
  else if SeriesIndex mod PPGChartPaletteSize = 0 then
    Result := PPGColorToRGB(EffectiveAppearance.FocusColor)
  else
    Result := PPGChartColor(Tokens, UseDarkMode, SeriesIndex);
end;

function TPPGCustomChart.SliceColor(SeriesIndex, PointIndex: Integer): TColor;
var
  P: TPPGChartPoint;
begin
  if UseHighContrast then
    Exit(PPGChartHighContrastColor(PointIndex));
  if not Enabled then
    Exit(PPGBlendColor(Tokens.TextDisabled, PPGColorToRGB(GetBackgroundColor),
      0.4 * (PointIndex mod 3)));
  P := FSeries[SeriesIndex].Points[PointIndex];
  if P.Color <> clDefault then
    Result := PPGColorToRGB(P.Color)
  else if PointIndex mod PPGChartPaletteSize = 0 then
    Result := PPGColorToRGB(EffectiveAppearance.FocusColor)
  else
    Result := PPGChartColor(Tokens, UseDarkMode, PointIndex);
end;

function TPPGCustomChart.ValueText(SeriesIndex: Integer; Value: Double): string;
var
  S: TPPGChartSeries;
  Axis: TPPGChartAxis;
begin
  if (SeriesIndex >= 0) and (SeriesIndex < FSeries.Count) then
  begin
    S := FSeries[SeriesIndex];
    if S.ValueFormat <> '' then
      Exit(FormatFloat(S.ValueFormat, Value));
    if S.YAxis = casSecondary then
      Axis := FY2Axis
    else
      Axis := FYAxis;
    if Axis.Format <> '' then
      Exit(FormatFloat(Axis.Format, Value));
  end;
  Result := DefaultFormatValue(Value);
end;

function TPPGCustomChart.XLabel(SeriesIndex, PointIndex: Integer): string;
var
  P: TPPGChartPoint;
  S: TPPGChartSeries;
  I: Integer;
begin
  Result := '';
  if (SeriesIndex < 0) or (SeriesIndex >= FSeries.Count) then
    Exit;
  S := FSeries[SeriesIndex];
  if (PointIndex < 0) or (PointIndex >= S.Count) then
  begin
    // Kategorie ohne Punkt in dieser Serie
    if (FXAxis.Kind = cxkCategory) and (PointIndex >= 0) then
    begin
      if PointIndex < FCategories.Count then
        Exit(FCategories[PointIndex]);
      Exit(IntToStr(PointIndex + 1));
    end;
    Exit;
  end;
  P := S.Points[PointIndex];
  if S.IsPie or (FXAxis.Kind = cxkCategory) then
  begin
    if (PointIndex < FCategories.Count) and not S.IsPie then
      Exit(FCategories[PointIndex]);
    if P.Text <> '' then
      Exit(P.Text);
    if PointIndex < FCategories.Count then
      Exit(FCategories[PointIndex]);
    // Text einer anderen Serie an derselben Stelle
    for I := 0 to FSeries.Count - 1 do
      if (I <> SeriesIndex) and (PointIndex < FSeries[I].Count) and
        (FSeries[I].VirtualCount = 0) and (FSeries[I].Points[PointIndex].Text <> '') then
        Exit(FSeries[I].Points[PointIndex].Text);
    Exit(IntToStr(PointIndex + 1));
  end;
  if FXAxis.Kind = cxkDateTime then
  begin
    if Frac(P.X) = 0 then
      Result := DateToStr(P.X)
    else
      Result := DateTimeToStr(P.X);
  end
  else if FXAxis.Format <> '' then
    Result := FormatFloat(FXAxis.Format, P.X)
  else
    Result := DefaultFormatValue(P.X);
end;

function SeriesTitle(S: TPPGChartSeries): string;
begin
  if S.Title <> '' then
    Result := S.Title
  else
    Result := Format(PPGStr(@SPPGChartSeriesDefault), [S.Index + 1]);
end;

{ ---- Layout ---- }

function TPPGCustomChart.FirstDrawnSeries: Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FSeries.Count - 1 do
    if FSeries[I].IsDrawn then
      Exit(I);
end;

function TPPGCustomChart.CategoryLabelWidth(Count: Integer): Integer;
var
  DC: HDC;
  I, Step, S: Integer;
begin
  Result := 0;
  if Count <= 0 then
    Exit;
  S := FirstDrawnSeries;
  // Bei vielen Kategorien nur eine Stichprobe messen (100 000 Texte
  // zu messen kostet mehr als das ganze Diagramm); die letzte immer dazu,
  // sie ist bei Zahlen meist die breiteste
  Step := System.Math.Max(1, Count div 60);
  DC := CreateCompatibleDC(0);
  if DC = 0 then
    Exit;
  try
    I := 0;
    while I < Count do
    begin
      Result := System.Math.Max(Result, PPGGdiMeasureText(DC, XLabel(S, I), Font, 0, False).cx);
      Inc(I, Step);
    end;
    Result := System.Math.Max(Result, PPGGdiMeasureText(DC, XLabel(S, Count - 1), Font, 0,
      False).cx);
  finally
    DeleteDC(DC);
  end;
end;

function TPPGCustomChart.Layout: TPPGChartLayout;
var
  LF: TFont;
  LegendFontH: Integer;
  PPI, Pad, I, J, N, Gap, Swatch, ItemW, X, Y, RowH, LegendH, LegendW, MaxTW: Integer;
  YLabelW, Y2LabelW, XLabelH, XTitleH, YTitleH, MaxTicks, Cnt: Integer;
  S: TPPGChartSeries;
  TF: TFont;
  Sz: TSize;
  AllBars, AnyDrawn, ZeroY, ZeroY2, HasY, HasY2, Percent: Boolean;
  YLo, YHi, Y2Lo, Y2Hi, XLo, XHi, V, PosSum, NegSum: Double;
  PosB, NegB: TArray<Double>;
  Names: TArray<string>;
  Indices: TArray<Integer>;
  Content: TRect;
  RTL: Boolean;

  procedure Grow(var Lo, Hi: Double; Value: Double; var Has: Boolean);
  begin
    if IsNan(Value) or IsInfinite(Value) then
      Exit;
    if not Has then
    begin
      Lo := Value;
      Hi := Value;
      Has := True;
    end
    else
    begin
      if Value < Lo then
        Lo := Value;
      if Value > Hi then
        Hi := Value;
    end;
  end;

  function MakeScale(Lo, Hi: Double; Has, Zero: Boolean; Axis: TPPGChartAxis;
    Ticks: Integer): TPPGAxisScale;
  begin
    if not Has then
    begin
      Lo := 0;
      Hi := 1;
    end;
    if not Axis.AutoMin and not Axis.AutoMax and (Axis.Max > Axis.Min) then
      Exit(PPGFixedScale(Axis.Min, Axis.Max, Ticks));
    if not Axis.AutoMin then
      Lo := Axis.Min;
    if not Axis.AutoMax then
      Hi := Axis.Max;
    Result := PPGNiceScale(Lo, Hi, Ticks, Zero);
    if not Axis.AutoMin then
      Result.Min := Axis.Min;
    if not Axis.AutoMax then
      Result.Max := Axis.Max;
    if Result.Max <= Result.Min then
      Result.Max := Result.Min + Result.Step;
  end;

  function LabelWidth(const Sc: TPPGAxisScale; Axis: TPPGChartAxis): Integer;
  var
    K, C: Integer;
  begin
    Result := 0;
    C := PPGScaleTickCount(Sc);
    for K := 0 to C - 1 do
      Result := System.Math.Max(Result, PPGMeasureTextNoCanvas(PPGFormatAxisValue(
        PPGScaleTick(Sc, K), Sc.Decimals, Axis.Format, FormatSettings), Font, 0, False).cx);
  end;

begin
  // Result kann ein altes Legenden-Array halten: erst freigeben, dann nullen
  Finalize(Result);
  FillChar(Result, SizeOf(Result), 0);
  Result.PieSeries := -1;
  PPI := ScalePPI;
  RTL := UseRightToLeftAlignment;
  Pad := PPGScale(ChartPad, PPI);
  Gap := PPGScale(6, PPI);
  Result.FontH := PPGMeasureTextNoCanvas('Wg', Font, 0, False).cy;
  Content := Rect(Pad, Pad, ClientWidth - Pad, ClientHeight - Pad);
  Result.Content := Content;

  // Titel
  if FTitle <> '' then
  begin
    TF := nil;
    try
      Sz := PPGMeasureTextNoCanvas(FTitle, TitleFont(TF), 0, False);
    finally
      TF.Free;
    end;
    Result.TitleR := Rect(Content.Left, Content.Top, Content.Right, Content.Top + Sz.cy);
    Content.Top := Result.TitleR.Bottom + Gap;
  end;

  // Art des Diagramms
  AnyDrawn := False;
  AllBars := True;
  for I := 0 to FSeries.Count - 1 do
  begin
    S := FSeries[I];
    if not S.IsDrawn then
      Continue;
    if not AnyDrawn and S.IsPie then
    begin
      Result.PieSeries := I;
      Break;
    end;
    AnyDrawn := True;
    if S.Kind <> cskBar then
      AllBars := False;
  end;
  if Result.PieSeries >= 0 then
    Result.Mode := cmPie
  else if not AnyDrawn or (TotalPoints = 0) then
    Result.Mode := cmEmpty
  else if AllBars then
    Result.Mode := cmHorizontal
  else
    Result.Mode := cmCartesian;

  // Legende: Serien bzw. Segmente des Kreises
  if Result.Mode = cmPie then
  begin
    S := FSeries[Result.PieSeries];
    N := System.Math.Min(S.Count, 50);
    SetLength(Names, N);
    SetLength(Indices, N);
    for I := 0 to N - 1 do
    begin
      Names[I] := XLabel(Result.PieSeries, I);
      Indices[I] := I;
    end;
  end
  else
  begin
    N := 0;
    SetLength(Names, FSeries.Count);
    SetLength(Indices, FSeries.Count);
    for I := 0 to FSeries.Count - 1 do
      if not FSeries[I].IsPie then
      begin
        Names[N] := SeriesTitle(FSeries[I]);
        Indices[N] := I;
        Inc(N);
      end;
    SetLength(Names, N);
    SetLength(Indices, N);
  end;
  if (FLegendPosition <> clpNone) and (N > 0) and (Result.Mode <> cmEmpty) then
  begin
    LF := LegendFont;
    LegendFontH := PPGMeasureTextNoCanvas('Wg', LF, 0, False).cy;
    Swatch := Round(LegendFontH * 0.75);
    RowH := LegendFontH + PPGScale(4, PPI);
    SetLength(Result.Legend, N);
    if FLegendPosition = clpRight then
    begin
      MaxTW := 0;
      for I := 0 to N - 1 do
        MaxTW := System.Math.Max(MaxTW, PPGMeasureTextNoCanvas(Names[I], LF, 0, False).cx);
      LegendW := System.Math.Min(Swatch + Gap + MaxTW, (Content.Right - Content.Left) div 3);
      if RTL then
      begin
        Result.LegendR := Rect(Content.Left, Content.Top, Content.Left + LegendW, Content.Bottom);
        Content.Left := Result.LegendR.Right + Gap * 2;
      end
      else
      begin
        Result.LegendR := Rect(Content.Right - LegendW, Content.Top, Content.Right, Content.Bottom);
        Content.Right := Result.LegendR.Left - Gap * 2;
      end;
      for I := 0 to N - 1 do
      begin
        Result.Legend[I].Index := Indices[I];
        Result.Legend[I].R := Rect(Result.LegendR.Left, Result.LegendR.Top + I * RowH,
          Result.LegendR.Right, Result.LegendR.Top + (I + 1) * RowH);
      end;
    end
    else
    begin
      // Zeilen umbrechen; gemessen wird von links, RTL spiegelt danach
      X := 0;
      Y := 0;
      for I := 0 to N - 1 do
      begin
        ItemW := Swatch + Gap + PPGMeasureTextNoCanvas(Names[I], LF, 0, False).cx;
        ItemW := System.Math.Min(ItemW, Content.Right - Content.Left);
        if (X > 0) and (X + ItemW > Content.Right - Content.Left) then
        begin
          X := 0;
          Inc(Y, RowH);
        end;
        Result.Legend[I].Index := Indices[I];
        Result.Legend[I].R := Rect(X, Y, X + ItemW, Y + RowH);
        Inc(X, ItemW + Gap * 3);
      end;
      LegendH := Y + RowH;
      if FLegendPosition = clpTop then
      begin
        Result.LegendR := Rect(Content.Left, Content.Top, Content.Right, Content.Top + LegendH);
        Content.Top := Result.LegendR.Bottom + Gap;
      end
      else
      begin
        Result.LegendR := Rect(Content.Left, Content.Bottom - LegendH, Content.Right, Content.Bottom);
        Content.Bottom := Result.LegendR.Top - Gap;
      end;
      for I := 0 to N - 1 do
      begin
        if RTL then
          Result.Legend[I].R := Rect(Result.LegendR.Right - Result.Legend[I].R.Right,
            Result.LegendR.Top + Result.Legend[I].R.Top,
            Result.LegendR.Right - Result.Legend[I].R.Left,
            Result.LegendR.Top + Result.Legend[I].R.Bottom)
        else
          OffsetRect(Result.Legend[I].R, Result.LegendR.Left, Result.LegendR.Top);
      end;
    end;
  end;

  if Result.Mode in [cmEmpty, cmPie] then
  begin
    Result.PlotR := Content;
    if Result.Mode = cmPie then
    begin
      Result.PieCenter := Point((Content.Left + Content.Right) div 2,
        (Content.Top + Content.Bottom) div 2);
      Result.PieRadius := System.Math.Max(System.Math.Min(Content.Right - Content.Left,
        Content.Bottom - Content.Top) div 2 - PPGScale(4, PPI), 4);
      if FSeries[Result.PieSeries].Kind = cskDonut then
        Result.PieInner := Round(Result.PieRadius * 0.6);
    end;
    Exit;
  end;

  // ---- Wertebereiche ----
  Percent := FStacking = cstPercent;
  HasY := False;
  HasY2 := False;
  ZeroY := False;
  ZeroY2 := False;
  YLo := 0;
  YHi := 0;
  Y2Lo := 0;
  Y2Hi := 0;
  Cnt := 0;
  for I := 0 to FSeries.Count - 1 do
    if FSeries[I].IsDrawn and not FSeries[I].IsPie then
      Cnt := System.Math.Max(Cnt, FSeries[I].Count);
  Result.CatCount := Cnt;
  SetLength(PosB, Cnt);
  SetLength(NegB, Cnt);
  for I := 0 to FSeries.Count - 1 do
  begin
    S := FSeries[I];
    if not S.IsDrawn or S.IsPie then
      Continue;
    if S.YAxis = casSecondary then
    begin
      Result.HasY2 := True;
      if IsStackKind(S.Kind) then
        ZeroY2 := True;
      for J := 0 to S.Count - 1 do
        Grow(Y2Lo, Y2Hi, S.YAt(J), HasY2);
      Continue;
    end;
    if IsStackKind(S.Kind) then
      ZeroY := True;
    if (FStacking <> cstNone) and IsStackKind(S.Kind) and (FXAxis.Kind = cxkCategory) then
    begin
      for J := 0 to S.Count - 1 do
      begin
        V := S.YAt(J);
        if V >= 0 then
          PosB[J] := PosB[J] + V
        else
          NegB[J] := NegB[J] + V;
      end;
    end
    else
      for J := 0 to S.Count - 1 do
        Grow(YLo, YHi, S.YAt(J), HasY);
  end;
  if FStacking <> cstNone then
  begin
    if Percent then
    begin
      for J := 0 to Cnt - 1 do
      begin
        if PosB[J] > 0 then
          Grow(YLo, YHi, 100, HasY);
        if NegB[J] < 0 then
          Grow(YLo, YHi, -100, HasY);
      end;
    end
    else
      for J := 0 to Cnt - 1 do
      begin
        PosSum := PosB[J];
        NegSum := NegB[J];
        Grow(YLo, YHi, PosSum, HasY);
        Grow(YLo, YHi, NegSum, HasY);
      end;
  end;
  for I := 0 to FReferenceLines.Count - 1 do
    case FReferenceLines[I].Axis of
      claY: Grow(YLo, YHi, FReferenceLines[I].Value, HasY);
      claY2: Grow(Y2Lo, Y2Hi, FReferenceLines[I].Value, HasY2);
    end;

  // ---- Platz fuer Achsen ----
  XTitleH := 0;
  if (FXAxis.Title <> '') and FXAxis.Visible then
    XTitleH := Result.FontH + Gap div 2;
  YTitleH := 0;
  if ((FYAxis.Title <> '') and FYAxis.Visible) or
    (Result.HasY2 and (FY2Axis.Title <> '') and FY2Axis.Visible) then
    YTitleH := Result.FontH + Gap div 2;
  if FXAxis.Visible then
    XLabelH := Result.FontH + Gap
  else
    XLabelH := 0;
  Content.Top := Content.Top + YTitleH + Result.FontH div 2;
  Content.Bottom := Content.Bottom - XTitleH;

  if Result.Mode = cmHorizontal then
  begin
    // Kategorien senkrecht, Werte waagerecht
    MaxTW := CategoryLabelWidth(Cnt);
    MaxTW := System.Math.Min(MaxTW, (Content.Right - Content.Left) * 2 div 5);
    if not FXAxis.Visible then
      MaxTW := 0;
    Result.PlotR := Rect(Content.Left + MaxTW + Gap, Content.Top, Content.Right - Gap * 2,
      Content.Bottom - XLabelH);
    if RTL then
      Result.PlotR := Rect(Content.Left + Gap * 2, Content.Top, Content.Right - MaxTW - Gap,
        Content.Bottom - XLabelH);
    MaxTicks := System.Math.Max(2, (Result.PlotR.Right - Result.PlotR.Left) div
      System.Math.Max(PPGMeasureTextNoCanvas('0000000', Font, 0, False).cx, 1));
    MaxTicks := System.Math.Min(MaxTicks, 10);
    Result.YScale := MakeScale(YLo, YHi, HasY, ZeroY, FYAxis, MaxTicks);
    if Percent then
      Result.YScale := PPGFixedScale(System.Math.Min(Result.YScale.Min, 0),
        System.Math.Max(Result.YScale.Max, 0), MaxTicks);
    Exit;
  end;

  MaxTicks := System.Math.Max(2, System.Math.Min(10,
    (Content.Bottom - XLabelH - Content.Top) div System.Math.Max(Result.FontH * 8 div 5, 1)));
  Result.YScale := MakeScale(YLo, YHi, HasY, ZeroY, FYAxis, MaxTicks);
  if Percent and HasY then
  begin
    Result.YScale := PPGNiceScale(YLo, YHi, MaxTicks, True);
    Result.YScale.Min := System.Math.Max(Result.YScale.Min, -100);
    Result.YScale.Max := System.Math.Min(Result.YScale.Max, 100);
  end;
  if Result.HasY2 then
    Result.Y2Scale := MakeScale(Y2Lo, Y2Hi, HasY2, ZeroY2, FY2Axis, MaxTicks);
  YLabelW := 0;
  if FYAxis.Visible then
    YLabelW := LabelWidth(Result.YScale, FYAxis) + Gap;
  Y2LabelW := 0;
  if Result.HasY2 and FY2Axis.Visible then
    Y2LabelW := LabelWidth(Result.Y2Scale, FY2Axis) + Gap;
  if RTL then
    Result.PlotR := Rect(Content.Left + Y2LabelW, Content.Top, Content.Right - YLabelW,
      Content.Bottom - XLabelH)
  else
    Result.PlotR := Rect(Content.Left + YLabelW, Content.Top, Content.Right - Y2LabelW,
      Content.Bottom - XLabelH);
  // Platz fuer die halbe letzte X-Beschriftung
  if (Y2LabelW = 0) and (FXAxis.Kind <> cxkCategory) then
  begin
    if RTL then
      Inc(Result.PlotR.Left, Gap * 2)
    else
      Dec(Result.PlotR.Right, Gap * 2);
  end;
  if Result.PlotR.Right <= Result.PlotR.Left then
    Result.PlotR.Right := Result.PlotR.Left + 1;
  if Result.PlotR.Bottom <= Result.PlotR.Top then
    Result.PlotR.Bottom := Result.PlotR.Top + 1;

  // X-Bereich (Zahl/Datum)
  if FXAxis.Kind <> cxkCategory then
  begin
    XLo := 0;
    XHi := 0;
    HasY := False; // wiederverwendet als "X vorhanden"
    for I := 0 to FSeries.Count - 1 do
    begin
      S := FSeries[I];
      if not S.IsDrawn or S.IsPie then
        Continue;
      for J := 0 to S.Count - 1 do
        Grow(XLo, XHi, S.XAt(J), HasY);
    end;
    for I := 0 to FReferenceLines.Count - 1 do
      if FReferenceLines[I].Axis = claX then
        Grow(XLo, XHi, FReferenceLines[I].Value, HasY);
    MaxTicks := System.Math.Max(2, System.Math.Min(12, (Result.PlotR.Right - Result.PlotR.Left) div
      System.Math.Max(PPGMeasureTextNoCanvas('00.00.0000', Font, 0, False).cx + Gap * 2, 1)));
    if FXAxis.Kind = cxkDateTime then
    begin
      if not FXAxis.AutoMin then
        XLo := FXAxis.Min;
      if not FXAxis.AutoMax then
        XHi := FXAxis.Max;
      Result.DateScale := PPGNiceDateScale(XLo, XHi, MaxTicks);
      if not FXAxis.AutoMin then
        Result.DateScale.Min := FXAxis.Min;
      if not FXAxis.AutoMax then
        Result.DateScale.Max := FXAxis.Max;
    end
    else
      Result.XScale := MakeScale(XLo, XHi, HasY, False, FXAxis, MaxTicks);
  end;
end;

{ ---- Abbildung Daten -> Pixel ---- }

function MapY(const L: TPPGChartLayout; const Sc: TPPGAxisScale; V: Double): Integer;
var
  Span: Double;
begin
  Span := Sc.Max - Sc.Min;
  if Span <= 0 then
    Exit((L.PlotR.Top + L.PlotR.Bottom) div 2);
  V := (V - Sc.Min) / Span;
  // Weit ausserhalb liegende Werte begrenzen (GDI-Koordinaten)
  // NaN uebersteht die Vergleiche unten und liesse Round werfen
  if IsNan(V) then
    V := 0;
  if V < -10 then
    V := -10;
  if V > 10 then
    V := 10;
  Result := L.PlotR.Bottom - Round(V * (L.PlotR.Bottom - L.PlotR.Top));
end;

function MapValueX(const L: TPPGChartLayout; V: Double): Integer;
var
  Span: Double;
begin
  // Wertachse waagerecht (Balken)
  Span := L.YScale.Max - L.YScale.Min;
  if Span <= 0 then
    Exit((L.PlotR.Left + L.PlotR.Right) div 2);
  V := (V - L.YScale.Min) / Span;
  if IsNan(V) then
    V := 0;
  if V < -10 then
    V := -10;
  if V > 10 then
    V := 10;
  Result := L.PlotR.Left + Round(V * (L.PlotR.Right - L.PlotR.Left));
end;

function MapX(const L: TPPGChartLayout; Kind: TPPGChartXKind; X: Double): Integer;
var
  Lo, Hi, Slot: Double;
begin
  case Kind of
    cxkCategory:
      begin
        if L.CatCount <= 0 then
          Exit(L.PlotR.Left);
        Slot := (L.PlotR.Right - L.PlotR.Left) / L.CatCount;
        Exit(L.PlotR.Left + Round(Slot * (X + 0.5)));
      end;
    cxkDateTime:
      begin
        Lo := L.DateScale.Min;
        Hi := L.DateScale.Max;
      end;
  else
    Lo := L.XScale.Min;
    Hi := L.XScale.Max;
  end;
  if Hi <= Lo then
    Exit((L.PlotR.Left + L.PlotR.Right) div 2);
  X := (X - Lo) / (Hi - Lo);
  if IsNan(X) then
    X := 0;
  if X < -10 then
    X := -10;
  if X > 10 then
    X := 10;
  Result := L.PlotR.Left + Round(X * (L.PlotR.Right - L.PlotR.Left));
end;

function UnmapX(const L: TPPGChartLayout; Kind: TPPGChartXKind; PX: Integer): Double;
var
  Lo, Hi: Double;
begin
  if Kind = cxkDateTime then
  begin
    Lo := L.DateScale.Min;
    Hi := L.DateScale.Max;
  end
  else
  begin
    Lo := L.XScale.Min;
    Hi := L.XScale.Max;
  end;
  if L.PlotR.Right <= L.PlotR.Left then
    Exit(Lo);
  Result := Lo + (PX - L.PlotR.Left) / (L.PlotR.Right - L.PlotR.Left) * (Hi - Lo);
end;

function ScaleOf(const L: TPPGChartLayout; S: TPPGChartSeries): TPPGAxisScale;
begin
  if S.YAxis = casSecondary then
    Result := L.Y2Scale
  else
    Result := L.YScale;
end;

function NearestIndex(S: TPPGChartSeries; X: Double): Integer;
var
  I: Integer;
  D, Best: Double;
begin
  Result := -1;
  Best := MaxDouble;
  for I := 0 to S.Count - 1 do
  begin
    D := Abs(S.XAt(I) - X);
    if D < Best then
    begin
      Best := D;
      Result := I;
    end;
  end;
end;

{ ---- Zeichnen ---- }

procedure TPPGCustomChart.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  L: TPPGChartLayout;
  T: TPPGTokens;
  CR: IPPGChartRenderer;
  PPI, I, J, K, N, X, Y, Y0, X0, W, Th, ColCount, ColNo, Gap: Integer;
  HC: Boolean;
  Bg, TextCol, SecCol, GridCol, Col, LineCol: TColor;
  Frames: TArray<TSeriesFrame>;
  S: TPPGChartSeries;
  Slot, GroupW, BarW, Factor, V, Total, Start, Sweep, Mid, Pct: Double;
  Pts, Poly: TArray<TPoint>;
  R, TR: TRect;
  Sz: TSize;
  Txt: string;
  TF: TFont;
  PosB, NegB, Totals: TArray<Double>;
  Dates: TArray<TDateTime>;
  Stack: Boolean;
  Hot: Single;
  P: TPoint;
  Lines: TArray<string>;
  LineColors: TArray<TColor>;
  RTL: Boolean;
  Flags: Cardinal;

  function AnimY(Ser: TPPGChartSeries; Idx: Integer; Raw: Double): Double;
  begin
    Result := Raw;
    if FChangeAnim.Running and (Idx < Length(Ser.OldY)) then
      Result := Ser.OldY[Idx] + (Raw - Ser.OldY[Idx]) * FChangeAnim.Value;
    Result := Result * Ser.VisibleFactor * FIntroAnim.Value;
  end;

  procedure DrawLegend;
  var
    LI: Integer;
    SR, TxR: TRect;
    Sw: Integer;
    C, TC: TColor;
    Name: string;
    Shown: Boolean;
  begin
    Sw := Round(L.FontH * 0.75);
    for LI := 0 to High(L.Legend) do
    begin
      if L.Mode = cmPie then
      begin
        C := SliceColor(L.PieSeries, L.Legend[LI].Index);
        Name := XLabel(L.PieSeries, L.Legend[LI].Index);
        Shown := True;
      end
      else
      begin
        C := SeriesColor(L.Legend[LI].Index);
        Name := SeriesTitle(FSeries[L.Legend[LI].Index]);
        Shown := FSeries[L.Legend[LI].Index].Visible;
      end;
      SR := L.Legend[LI].R;
      if RTL then
        SR.Left := SR.Right - Sw
      else
        SR.Right := SR.Left + Sw;
      SR.Top := (L.Legend[LI].R.Top + L.Legend[LI].R.Bottom - Sw) div 2;
      SR.Bottom := SR.Top + Sw;
      if Shown then
        ACanvas.FillRoundRect(SR, PPGScale(2, PPI), C, 255)
      else
        ACanvas.FrameRoundRect(SR, PPGScale(2, PPI), System.Math.Max(PPGScale(1, PPI), 1), C, 255);
      TxR := L.Legend[LI].R;
      if RTL then
        TxR.Right := SR.Left - Gap
      else
        TxR.Left := SR.Right + Gap;
      TC := TextCol;
      if UseOwnColors and Enabled then
        TC := FChartStyles.Legend.TextFor(UseDarkMode, TC);
      if not Shown then
        TC := SecCol;
      if (FHot.Kind = chkLegend) and (FHot.Series = L.Legend[LI].Index) and not HC then
        TC := PPGColorToRGB(EffectiveAppearance.FocusColor);
      Flags := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX;
      if RTL then
        Flags := Flags or DT_RIGHT or DT_RTLREADING;
      ACanvas.DrawText(TxR, Name, LegendFont, TC, Flags);
    end;
  end;

  procedure DrawTooltip(const Anchor: TPoint);
  var
    TI, TW, TH, LH, Sw, Pd: Integer;
    Box, LR: TRect;
    St: TPPGSurfaceStyle;
    TS: TSize;
  begin
    if Length(Lines) = 0 then
      Exit;
    Pd := PPGScale(8, PPI);
    Sw := Round(L.FontH * 0.6);
    LH := L.FontH + PPGScale(2, PPI);
    TW := 0;
    for TI := 0 to High(Lines) do
    begin
      TS := ACanvas.MeasureText(Lines[TI], Font, 0, False);
      if (TI > 0) and (LineColors[TI] <> clNone) then
        TS.cx := TS.cx + Sw + Gap;
      TW := System.Math.Max(TW, TS.cx);
    end;
    TW := TW + 2 * Pd;
    TH := Length(Lines) * LH + 2 * Pd - PPGScale(2, PPI);
    Box := Rect(Anchor.X + PPGScale(14, PPI), Anchor.Y - TH div 2, 0, 0);
    if Box.Left + TW > ClientR.Right - PPGScale(2, PPI) then
      Box.Left := Anchor.X - PPGScale(14, PPI) - TW;
    if Box.Left < ClientR.Left + PPGScale(2, PPI) then
      Box.Left := ClientR.Left + PPGScale(2, PPI);
    if Box.Top + TH > ClientR.Bottom - PPGScale(2, PPI) then
      Box.Top := ClientR.Bottom - PPGScale(2, PPI) - TH;
    if Box.Top < ClientR.Top + PPGScale(2, PPI) then
      Box.Top := ClientR.Top + PPGScale(2, PPI);
    Box.Right := Box.Left + TW;
    Box.Bottom := Box.Top + TH;
    FillChar(St, SizeOf(St), 0);
    if HC then
    begin
      // Sonderfall: Tooltip-Systemfarben wie die Hints
      St.Color := PPGColorToRGB(clInfoBk);
      St.BorderColor := PPGColorToRGB(clInfoText);
      St.TextColor := PPGColorToRGB(clInfoText);
    end
    else
    begin
      St.Color := T.Surface;
      St.BorderColor := T.StrokeStrong;
      St.TextColor := T.TextPrimary;
    end;
    St.BorderWidth := System.Math.Max(PPGScale(1, PPI), 1);
    St.Rounding := PPGScale(T.RadiusMedium, PPI);
    CR.DrawChartTooltip(ACanvas, Box, St, PPI);
    for TI := 0 to High(Lines) do
    begin
      LR := Rect(Box.Left + Pd, Box.Top + Pd + TI * LH, Box.Right - Pd, Box.Top + Pd + (TI + 1) * LH);
      if (TI > 0) and (LineColors[TI] <> clNone) then
      begin
        ACanvas.FillRoundRect(Rect(LR.Left, (LR.Top + LR.Bottom - Sw) div 2, LR.Left + Sw,
          (LR.Top + LR.Bottom + Sw) div 2), PPGScale(2, PPI), LineColors[TI], 255);
        LR.Left := LR.Left + Sw + Gap;
      end;
      ACanvas.DrawText(LR, Lines[TI], Font, St.TextColor, DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX);
    end;
  end;

  procedure AddLine(const Text: string; C: TColor);
  begin
    SetLength(Lines, Length(Lines) + 1);
    SetLength(LineColors, Length(LineColors) + 1);
    Lines[High(Lines)] := Text;
    LineColors[High(LineColors)] := C;
  end;

begin
  T := Tokens;
  PPI := ScalePPI;
  RTL := UseRightToLeftAlignment;
  HC := UseHighContrast;
  CR := PPGChartRendererOf(Renderer);
  Gap := PPGScale(6, PPI);
  Bg := PPGColorToRGB(GetBackgroundColor);
  // Hochkontrast: die Tokens liefern die Systemfarben
  if Enabled then
    TextCol := T.TextPrimary
  else
    TextCol := T.TextDisabled;
  SecCol := T.TextSecondary;
  if not Enabled then
    SecCol := T.TextDisabled;
  if HC then
    GridCol := T.StrokeDisabled // Sonderfall: Gitter sichtbar (clGrayText)
  else
    GridCol := PPGBlendColor(Bg, T.TextPrimary, 0.1);
  if UseOwnColors then
  begin
    GridCol := FChartStyles.Grid.FillFor(UseDarkMode, GridCol);
    if Enabled then
      SecCol := FChartStyles.Axis.TextFor(UseDarkMode, SecCol);
  end;
  L := Layout;

  // Titel
  if FTitle <> '' then
  begin
    TF := nil;
    try
      Flags := DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX;
      if RTL then
        Flags := Flags or DT_RIGHT or DT_RTLREADING;
      Col := TextCol;
      if UseOwnColors and Enabled then
        Col := FChartStyles.Title.TextFor(UseDarkMode, Col);
      ACanvas.DrawText(L.TitleR, FTitle, TitleFont(TF), Col, Flags);
    finally
      TF.Free;
    end;
  end;

  if L.Mode = cmEmpty then
  begin
    ACanvas.DrawText(L.PlotR, PPGStr(@SPPGChartNoData), Font, SecCol,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
    if FocusVisible then
      Renderer.DrawFocus(ACanvas, ClientR, GetCurrentStyle);
    Exit;
  end;

  DrawLegend;

  // ---- Kreis / Ring ----
  if L.Mode = cmPie then
  begin
    S := FSeries[L.PieSeries];
    Total := 0;
    for J := 0 to S.Count - 1 do
      Total := Total + Abs(S.YAt(J));
    Factor := S.VisibleFactor * FIntroAnim.Value;
    if Total > 0 then
    begin
      Start := 0;
      for J := 0 to S.Count - 1 do
      begin
        V := Abs(AnimY(S, J, S.YAt(J))) / (S.VisibleFactor * FIntroAnim.Value + 1E-12);
        Sweep := 360 * V / Total * Factor;
        if Sweep > 0.2 then
        begin
          P := L.PieCenter;
          if (FHot.Kind = chkPlot) and (FHot.Index = J) or
            ((FFocusIndex = J) and Focused) then
          begin
            // Hervorgehobenes Segment ruckt etwas nach aussen
            Mid := (Start + Sweep / 2 - 90) * Pi / 180;
            P.X := P.X + Round(PPGScale(4, PPI) * Cos(Mid));
            P.Y := P.Y + Round(PPGScale(4, PPI) * Sin(Mid));
          end;
          Poly := PPGArcSegmentPolygon(P, L.PieRadius, L.PieInner, Start, Sweep);
          PPGFillPolygon(ACanvas, Poly, SliceColor(L.PieSeries, J), 255);
          // Trennlinie in Hintergrundfarbe
          PPGShapeArcPoints(P, L.PieRadius, Start, 0, Pts);
          ACanvas.DrawPolyline([Point(P.X + (Pts[0].X - P.X) * L.PieInner div
            System.Math.Max(L.PieRadius, 1), P.Y + (Pts[0].Y - P.Y) * L.PieInner div
            System.Math.Max(L.PieRadius, 1)), Pts[0]], System.Math.Max(PPGScale(2, PPI), 1), Bg, 255);
          // Prozent im Segment, wenn genug Platz
          Pct := 100 * Abs(S.YAt(J)) / Total;
          if (Sweep >= 24) and (FIntroAnim.Value >= 1) then
          begin
            Mid := (Start + Sweep / 2 - 90) * Pi / 180;
            K := (L.PieRadius + L.PieInner) div 2;
            if L.PieInner = 0 then
              K := Round(L.PieRadius * 0.62);
            X := P.X + Round(K * Cos(Mid));
            Y := P.Y + Round(K * Sin(Mid));
            Txt := FormatFloat('0', Pct) + '%';
            Col := SliceColor(L.PieSeries, J);
            LineCol := PPGContrastTextColor(Col);
            ACanvas.DrawText(Rect(X - L.FontH * 2, Y - L.FontH, X + L.FontH * 2, Y + L.FontH),
              Txt, Font, LineCol, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
          end;
        end;
        Start := Start + Sweep;
      end;
      // Summe in der Mitte des Rings
      if (L.PieInner > L.FontH * 2) and (FIntroAnim.Value >= 1) then
      begin
        TF := TFont.Create;
        try
          TF.Assign(Font);
          TF.Style := [fsBold];
          TF.Height := -System.Math.Max(L.PieInner div 3, 8);
          ACanvas.DrawText(Rect(L.PieCenter.X - L.PieInner, L.PieCenter.Y - L.PieInner,
            L.PieCenter.X + L.PieInner, L.PieCenter.Y + L.PieInner),
            ValueText(L.PieSeries, Total), TF, TextCol,
            DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
        finally
          TF.Free;
        end;
      end;
    end;
    // Tooltip
    J := -1;
    P := FMousePos;
    if (FHot.Kind = chkPlot) and (FHot.Index >= 0) then
      J := FHot.Index
    else if Focused and (FFocusIndex >= 0) then
    begin
      J := FFocusIndex;
      P := L.PieCenter;
    end;
    if FShowTooltips and (J >= 0) and (J < S.Count) and (Total > 0) then
    begin
      AddLine(XLabel(L.PieSeries, J), clNone);
      AddLine(ValueText(L.PieSeries, S.YAt(J)) + ' (' +
        FormatFloat('0.#', 100 * Abs(S.YAt(J)) / Total) + '%)', SliceColor(L.PieSeries, J));
      DrawTooltip(P);
    end;
    if FocusVisible then
      Renderer.DrawFocus(ACanvas, ClientR, GetCurrentStyle);
    Exit;
  end;

  // ---- Gitter und Achsen ----
  W := System.Math.Max(PPGScale(1, PPI), 1);
  if L.Mode = cmHorizontal then
  begin
    N := PPGScaleTickCount(L.YScale);
    for I := 0 to N - 1 do
    begin
      V := PPGScaleTick(L.YScale, I);
      X := MapValueX(L, V);
      if FYAxis.ShowGrid then
        ACanvas.DrawPolyline([Point(X, L.PlotR.Top), Point(X, L.PlotR.Bottom)], W, GridCol, 255);
      if FXAxis.Visible then
        ACanvas.DrawText(Rect(X - 100, L.PlotR.Bottom + Gap div 2, X + 100, L.PlotR.Bottom + Gap div 2 + L.FontH),
          PPGFormatAxisValue(V, L.YScale.Decimals, FYAxis.Format, FormatSettings), Font, SecCol,
          DT_CENTER or DT_SINGLELINE or DT_NOPREFIX);
    end;
    // Wertachse unten: ihr Titel ist der der Y-Achse
    if (FYAxis.Title <> '') and FXAxis.Visible then
      ACanvas.DrawText(Rect(L.PlotR.Left, L.PlotR.Bottom + L.FontH + Gap, L.PlotR.Right,
        L.PlotR.Bottom + 2 * L.FontH + Gap * 2), FYAxis.Title, Font, SecCol,
        DT_CENTER or DT_SINGLELINE or DT_NOPREFIX);
    // Kategorien links (RTL: rechts) neben den Balken
    if FXAxis.Visible and (L.CatCount > 0) then
    begin
      Slot := (L.PlotR.Bottom - L.PlotR.Top) / L.CatCount;
      for J := 0 to L.CatCount - 1 do
      begin
        Y := L.PlotR.Top + Round(Slot * (J + 0.5));
        if RTL then
          ACanvas.DrawText(Rect(L.PlotR.Right + Gap, Y - L.FontH, ClientR.Right -
            PPGScale(ChartPad, PPI), Y + L.FontH), XLabel(FirstDrawnSeries, J), Font, SecCol,
            DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX or DT_RTLREADING)
        else
          ACanvas.DrawText(Rect(ClientR.Left + PPGScale(ChartPad, PPI), Y - L.FontH,
            L.PlotR.Left - Gap, Y + L.FontH), XLabel(FirstDrawnSeries, J), Font, SecCol,
            DT_RIGHT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
      end;
    end;
    // Grundlinie (Null) senkrecht
    X := MapValueX(L, System.Math.Max(L.YScale.Min, System.Math.Min(0, L.YScale.Max)));
    ACanvas.DrawPolyline([Point(X, L.PlotR.Top), Point(X, L.PlotR.Bottom)], W,
      PPGBlendColor(Bg, TextCol, 0.35), 255);
  end
  else
  begin
    if FYAxis.Visible or FYAxis.ShowGrid then
    begin
      N := PPGScaleTickCount(L.YScale);
      for I := 0 to N - 1 do
      begin
        V := PPGScaleTick(L.YScale, I);
        Y := MapY(L, L.YScale, V);
        if FYAxis.ShowGrid then
          ACanvas.DrawPolyline([Point(L.PlotR.Left, Y), Point(L.PlotR.Right, Y)], W, GridCol, 255);
        if FYAxis.Visible then
        begin
          Txt := PPGFormatAxisValue(V, L.YScale.Decimals, FYAxis.Format, FormatSettings);
          if RTL then
            ACanvas.DrawText(Rect(L.PlotR.Right + Gap, Y - L.FontH, ClientR.Right, Y + L.FontH),
              Txt, Font, SecCol, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX)
          else
            ACanvas.DrawText(Rect(ClientR.Left, Y - L.FontH, L.PlotR.Left - Gap, Y + L.FontH),
              Txt, Font, SecCol, DT_RIGHT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
        end;
      end;
    end;
    if L.HasY2 and FY2Axis.Visible then
    begin
      N := PPGScaleTickCount(L.Y2Scale);
      for I := 0 to N - 1 do
      begin
        V := PPGScaleTick(L.Y2Scale, I);
        Y := MapY(L, L.Y2Scale, V);
        if FY2Axis.ShowGrid then
          PPGDrawDashedLine(ACanvas, [Point(L.PlotR.Left, Y), Point(L.PlotR.Right, Y)], W,
            PPGScale(3, PPI), PPGScale(3, PPI), GridCol, 255);
        Txt := PPGFormatAxisValue(V, L.Y2Scale.Decimals, FY2Axis.Format, FormatSettings);
        if RTL then
          ACanvas.DrawText(Rect(ClientR.Left, Y - L.FontH, L.PlotR.Left - Gap, Y + L.FontH),
            Txt, Font, SecCol, DT_RIGHT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX)
        else
          ACanvas.DrawText(Rect(L.PlotR.Right + Gap, Y - L.FontH, ClientR.Right, Y + L.FontH),
            Txt, Font, SecCol, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
      end;
    end;
    // Achsentitel der Y-Achsen ueber den Beschriftungen
    if (FYAxis.Title <> '') and FYAxis.Visible then
    begin
      if RTL then
        ACanvas.DrawText(Rect(L.PlotR.Left, L.PlotR.Top - L.FontH * 2, ClientR.Right - PPGScale(ChartPad, PPI),
          L.PlotR.Top - L.FontH div 2), FYAxis.Title, Font, SecCol, DT_RIGHT or DT_BOTTOM or
          DT_SINGLELINE or DT_NOPREFIX or DT_RTLREADING)
      else
        ACanvas.DrawText(Rect(ClientR.Left + PPGScale(ChartPad, PPI), L.PlotR.Top - L.FontH * 2,
          L.PlotR.Right, L.PlotR.Top - L.FontH div 2), FYAxis.Title, Font, SecCol,
          DT_LEFT or DT_BOTTOM or DT_SINGLELINE or DT_NOPREFIX);
    end;
    if L.HasY2 and (FY2Axis.Title <> '') and FY2Axis.Visible then
      ACanvas.DrawText(Rect(L.PlotR.Left, L.PlotR.Top - L.FontH * 2, ClientR.Right - PPGScale(ChartPad, PPI),
        L.PlotR.Top - L.FontH div 2), FY2Axis.Title, Font, SecCol, DT_RIGHT or DT_BOTTOM or
        DT_SINGLELINE or DT_NOPREFIX);
    // X-Beschriftung
    if FXAxis.Visible then
    begin
      R := Rect(0, L.PlotR.Bottom + Gap div 2, 0, L.PlotR.Bottom + Gap div 2 + L.FontH);
      case FXAxis.Kind of
        cxkCategory:
          if L.CatCount > 0 then
          begin
            Slot := (L.PlotR.Right - L.PlotR.Left) / L.CatCount;
            // Jede k-te Beschriftung, damit sich nichts ueberlappt
            Th := CategoryLabelWidth(L.CatCount);
            // Slot kann unter 1 px liegen (sehr viele Kategorien) - nicht auf 1 runden,
            // sonst wird jede ~40. von 100 000 Beschriftungen gezeichnet
            K := System.Math.Max(1, Ceil((Th + Gap) / System.Math.Max(Slot, 1E-6)));
            J := 0;
            while J < L.CatCount do
            begin
              X := MapX(L, cxkCategory, J);
              ACanvas.DrawText(Rect(X - Round(Slot * K / 2), R.Top, X + Round(Slot * K / 2), R.Bottom),
                XLabel(FirstDrawnSeries, J), Font, SecCol,
                DT_CENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
              Inc(J, K);
            end;
          end;
        cxkNumeric:
          begin
            N := PPGScaleTickCount(L.XScale);
            for I := 0 to N - 1 do
            begin
              V := PPGScaleTick(L.XScale, I);
              X := MapX(L, cxkNumeric, V);
              if FXAxis.ShowGrid then
                ACanvas.DrawPolyline([Point(X, L.PlotR.Top), Point(X, L.PlotR.Bottom)], W, GridCol, 255);
              ACanvas.DrawText(Rect(X - 100, R.Top, X + 100, R.Bottom),
                PPGFormatAxisValue(V, L.XScale.Decimals, FXAxis.Format, FormatSettings), Font, SecCol,
                DT_CENTER or DT_SINGLELINE or DT_NOPREFIX);
            end;
          end;
        cxkDateTime:
          begin
            Dates := PPGDateTicks(L.DateScale);
            for I := 0 to High(Dates) do
            begin
              X := MapX(L, cxkDateTime, Dates[I]);
              if FXAxis.ShowGrid then
                ACanvas.DrawPolyline([Point(X, L.PlotR.Top), Point(X, L.PlotR.Bottom)], W, GridCol, 255);
              if FXAxis.Format <> '' then
                Txt := FormatDateTime(FXAxis.Format, Dates[I])
              else
                Txt := PPGFormatDateTick(Dates[I], L.DateScale, FormatSettings);
              ACanvas.DrawText(Rect(X - 100, R.Top, X + 100, R.Bottom), Txt, Font, SecCol,
                DT_CENTER or DT_SINGLELINE or DT_NOPREFIX);
            end;
          end;
      end;
      if FXAxis.Title <> '' then
        ACanvas.DrawText(Rect(L.PlotR.Left, R.Bottom + Gap div 2, L.PlotR.Right,
          R.Bottom + Gap div 2 + L.FontH), FXAxis.Title, Font, SecCol,
          DT_CENTER or DT_SINGLELINE or DT_NOPREFIX);
    end;
    // Grundlinie
    Y0 := MapY(L, L.YScale, System.Math.Max(L.YScale.Min, System.Math.Min(0, L.YScale.Max)));
    ACanvas.DrawPolyline([Point(L.PlotR.Left, Y0), Point(L.PlotR.Right, Y0)], W,
      PPGBlendColor(Bg, TextCol, 0.35), 255);
  end;

  // ---- Daten aufbereiten (animiert, gestapelt) ----
  Stack := (FStacking <> cstNone) and (FXAxis.Kind = cxkCategory);
  SetLength(PosB, L.CatCount);
  SetLength(NegB, L.CatCount);
  SetLength(Totals, L.CatCount);
  if FStacking = cstPercent then
    for I := 0 to FSeries.Count - 1 do
    begin
      S := FSeries[I];
      if S.IsDrawn and IsStackKind(S.Kind) and (S.YAxis = casPrimary) then
        for J := 0 to S.Count - 1 do
          Totals[J] := Totals[J] + Abs(S.YAt(J));
    end;
  SetLength(Frames, 0);
  for I := 0 to FSeries.Count - 1 do
  begin
    S := FSeries[I];
    if not S.IsDrawn or S.IsPie then
      Continue;
    N := S.Count;
    SetLength(Frames, Length(Frames) + 1);
    K := High(Frames);
    Frames[K].Index := I;
    SetLength(Frames[K].Xs, N);
    SetLength(Frames[K].Ys, N);
    SetLength(Frames[K].Lo, N);
    SetLength(Frames[K].Hi, N);
    Frames[K].Stacked := Stack and IsStackKind(S.Kind) and (S.YAxis = casPrimary);
    for J := 0 to N - 1 do
    begin
      if FXAxis.Kind = cxkCategory then
        Frames[K].Xs[J] := J
      else
        Frames[K].Xs[J] := S.XAt(J);
      V := S.YAt(J);
      if Frames[K].Stacked and (FStacking = cstPercent) then
      begin
        if Totals[J] > 0 then
          V := V / Totals[J] * 100
        else
          V := 0;
      end;
      V := AnimY(S, J, V);
      Frames[K].Ys[J] := V;
      if Frames[K].Stacked and (J < L.CatCount) then
      begin
        if V >= 0 then
        begin
          Frames[K].Lo[J] := PosB[J];
          PosB[J] := PosB[J] + V;
          Frames[K].Hi[J] := PosB[J];
        end
        else
        begin
          Frames[K].Lo[J] := NegB[J];
          NegB[J] := NegB[J] + V;
          Frames[K].Hi[J] := NegB[J];
        end;
      end
      else
      begin
        Frames[K].Lo[J] := 0;
        Frames[K].Hi[J] := V;
      end;
    end;
  end;

  ACanvas.PushClipRoundRect(Rect(L.PlotR.Left - PPGScale(6, PPI), L.PlotR.Top - PPGScale(6, PPI),
    L.PlotR.Right + PPGScale(6, PPI), L.PlotR.Bottom + PPGScale(1, PPI)), 0);
  try
    // Dauerhafte Markierung (z.B. aktueller Datensatz)
    if (FMarkedIndex >= 0) and (L.CatCount > 0) then
    begin
      if L.Mode = cmHorizontal then
      begin
        Slot := (L.PlotR.Bottom - L.PlotR.Top) / L.CatCount;
        R := Rect(L.PlotR.Left, L.PlotR.Top + Round(Slot * FMarkedIndex), L.PlotR.Right,
          L.PlotR.Top + Round(Slot * (FMarkedIndex + 1)));
        ACanvas.FillRoundRect(R, 0, PPGColorToRGB(EffectiveAppearance.FocusColor), 22);
      end
      else if FXAxis.Kind = cxkCategory then
      begin
        Slot := (L.PlotR.Right - L.PlotR.Left) / L.CatCount;
        R := Rect(L.PlotR.Left + Round(Slot * FMarkedIndex), L.PlotR.Top,
          L.PlotR.Left + Round(Slot * (FMarkedIndex + 1)), L.PlotR.Bottom);
        ACanvas.FillRoundRect(R, 0, PPGColorToRGB(EffectiveAppearance.FocusColor), 22);
      end
      else if (Length(Frames) > 0) and (FMarkedIndex < Length(Frames[0].Xs)) then
      begin
        X := MapX(L, FXAxis.Kind, Frames[0].Xs[FMarkedIndex]);
        ACanvas.DrawPolyline([Point(X, L.PlotR.Top), Point(X, L.PlotR.Bottom)], W,
          PPGColorToRGB(EffectiveAppearance.FocusColor), 200);
      end;
    end;
    // Hervorhebung der Kategorie (Saeulen) bzw. Linie am X-Wert
    if (FHot.Kind = chkPlot) and (FHot.Index >= 0) then
    begin
      if (FXAxis.Kind = cxkCategory) and (L.CatCount > 0) then
      begin
        Slot := ((L.PlotR.Right - L.PlotR.Left) / L.CatCount);
        if L.Mode = cmHorizontal then
        begin
          Slot := (L.PlotR.Bottom - L.PlotR.Top) / L.CatCount;
          R := Rect(L.PlotR.Left, L.PlotR.Top + Round(Slot * FHot.Index), L.PlotR.Right,
            L.PlotR.Top + Round(Slot * (FHot.Index + 1)));
        end
        else
          R := Rect(L.PlotR.Left + Round(Slot * FHot.Index), L.PlotR.Top,
            L.PlotR.Left + Round(Slot * (FHot.Index + 1)), L.PlotR.Bottom);
        ACanvas.FillRoundRect(R, 0, TextCol, 14);
      end
      else
      begin
        X := MapX(L, FXAxis.Kind, FHotDataX);
        ACanvas.DrawPolyline([Point(X, L.PlotR.Top), Point(X, L.PlotR.Bottom)], W, SecCol, 160);
      end;
    end;

    // Flaechen
    for K := 0 to High(Frames) do
    begin
      S := FSeries[Frames[K].Index];
      if (S.Kind <> cskArea) or (Length(Frames[K].Ys) = 0) or (L.Mode = cmHorizontal) then
        Continue;
      N := Length(Frames[K].Ys);
      SetLength(Poly, 2 * N);
      for J := 0 to N - 1 do
      begin
        X := MapX(L, FXAxis.Kind, Frames[K].Xs[J]);
        Poly[J] := Point(X, MapY(L, ScaleOf(L, S), Frames[K].Hi[J]));
        Poly[2 * N - 1 - J] := Point(X, MapY(L, ScaleOf(L, S), Frames[K].Lo[J]));
      end;
      Col := SeriesColor(Frames[K].Index);
      PPGFillPolygon(ACanvas, Poly, Col, Round(90 * S.VisibleFactor));
      SetLength(Pts, N);
      for J := 0 to N - 1 do
        Pts[J] := Poly[J];
      ACanvas.DrawPolyline(Pts, System.Math.Max(PPGScale(S.LineWidth, PPI), 1), Col,
        Round(255 * S.VisibleFactor));
    end;

    // Saeulen und Balken
    ColCount := 0;
    for K := 0 to High(Frames) do
      if IsColumnKind(FSeries[Frames[K].Index].Kind) then
        Inc(ColCount);
    if (ColCount > 0) and (L.CatCount > 0) then
    begin
      if L.Mode = cmHorizontal then
        Slot := (L.PlotR.Bottom - L.PlotR.Top) / L.CatCount
      else
        Slot := (L.PlotR.Right - L.PlotR.Left) / L.CatCount;
      GroupW := Slot * 0.72;
      if Stack then
        BarW := Slot * 0.56
      else
        BarW := GroupW / ColCount;
      ColNo := 0;
      for K := 0 to High(Frames) do
      begin
        S := FSeries[Frames[K].Index];
        if not IsColumnKind(S.Kind) then
          Continue;
        Col := SeriesColor(Frames[K].Index);
        for J := 0 to Length(Frames[K].Ys) - 1 do
        begin
          if J >= L.CatCount then
            Break;
          if Stack then
            Start := Slot * J + (Slot - BarW) / 2
          else
            Start := Slot * J + (Slot - GroupW) / 2 + BarW * ColNo;
          Hot := 0;
          if ((FHot.Kind = chkPlot) and (FHot.Index = J) and
            ((FHot.Series = Frames[K].Index) or (FHot.Series < 0))) or
            (Focused and (FFocusSeries = Frames[K].Index) and (FFocusIndex = J)) then
            Hot := 1;
          if L.Mode = cmHorizontal then
          begin
            X0 := MapValueX(L, Frames[K].Lo[J]);
            X := MapValueX(L, Frames[K].Hi[J]);
            R := Rect(System.Math.Min(X0, X), L.PlotR.Top + Round(Start),
              System.Math.Max(X0, X), L.PlotR.Top + Round(Start + BarW));
            if (not Stack) and (BarW > 6) then
              Dec(R.Bottom, PPGScale(1, PPI));
            CR.DrawChartBar(ACanvas, R, Col, Hot, False, Frames[K].Ys[J] < 0, PPI);
          end
          else
          begin
            Y0 := MapY(L, ScaleOf(L, S), Frames[K].Lo[J]);
            Y := MapY(L, ScaleOf(L, S), Frames[K].Hi[J]);
            R := Rect(L.PlotR.Left + Round(Start), System.Math.Min(Y0, Y),
              L.PlotR.Left + Round(Start + BarW), System.Math.Max(Y0, Y));
            if (not Stack) and (BarW > 6) then
              Dec(R.Right, PPGScale(1, PPI));
            CR.DrawChartBar(ACanvas, R, Col, Hot, True, Frames[K].Ys[J] < 0, PPI);
          end;
        end;
        Inc(ColNo);
      end;
    end;

    // Linien
    for K := 0 to High(Frames) do
    begin
      S := FSeries[Frames[K].Index];
      if not (S.Kind in [cskLine, cskStepLine]) or (L.Mode = cmHorizontal) then
        Continue;
      N := Length(Frames[K].Ys);
      if N = 0 then
        Continue;
      Col := SeriesColor(Frames[K].Index);
      Th := System.Math.Max(PPGScale(S.LineWidth, PPI), 1);
      if (N > 2 * (L.PlotR.Right - L.PlotR.Left)) and (S.Kind = cskLine) then
      begin
        // Verdichten: je Pixelspalte Min und Max (Reihenfolge der X-Werte)
        X0 := MaxInt;
        SetLength(Pts, 2 * (L.PlotR.Right - L.PlotR.Left + 2));
        I := 0;
        for J := 0 to N - 1 do
        begin
          X := MapX(L, FXAxis.Kind, Frames[K].Xs[J]);
          Y := MapY(L, ScaleOf(L, S), Frames[K].Ys[J]);
          if (I >= 2) and (X = X0) then
          begin
            if Y < Pts[I - 2].Y then
              Pts[I - 2].Y := Y;
            if Y > Pts[I - 1].Y then
              Pts[I - 1].Y := Y;
          end
          else
          begin
            if I + 2 > Length(Pts) then
              SetLength(Pts, Length(Pts) * 2 + 4);
            Pts[I] := Point(X, Y);
            Pts[I + 1] := Point(X, Y);
            Inc(I, 2);
            X0 := X;
          end;
        end;
        SetLength(Pts, I);
      end
      else if S.Kind = cskStepLine then
      begin
        SetLength(Pts, 2 * N - 1);
        for J := 0 to N - 1 do
        begin
          X := MapX(L, FXAxis.Kind, Frames[K].Xs[J]);
          Y := MapY(L, ScaleOf(L, S), Frames[K].Ys[J]);
          if J > 0 then
            Pts[2 * J - 1] := Point(X, Pts[2 * J - 2].Y);
          Pts[2 * J] := Point(X, Y);
        end;
      end
      else
      begin
        SetLength(Pts, N);
        for J := 0 to N - 1 do
          Pts[J] := Point(MapX(L, FXAxis.Kind, Frames[K].Xs[J]),
            MapY(L, ScaleOf(L, S), Frames[K].Ys[J]));
      end;
      if Length(Pts) >= 2 then
        ACanvas.DrawPolyline(Pts, Th, Col, Round(255 * S.VisibleFactor))
      else if Length(Pts) = 1 then
        CR.DrawChartMarker(ACanvas, Pts[0], Th, Col, Bg, PPI);
      if S.ShowMarkers and (N <= (L.PlotR.Right - L.PlotR.Left) div 4) then
        for J := 0 to N - 1 do
          CR.DrawChartMarker(ACanvas, Point(MapX(L, FXAxis.Kind, Frames[K].Xs[J]),
            MapY(L, ScaleOf(L, S), Frames[K].Ys[J])), Th + 1, Col, Bg, PPI);
    end;

    // Referenzlinien
    for I := 0 to FReferenceLines.Count - 1 do
    begin
      if FReferenceLines[I].Color = clDefault then
        LineCol := SecCol
      else
        LineCol := PPGColorToRGB(FReferenceLines[I].Color);
      if (FReferenceLines[I].Axis = claX) and (L.Mode = cmCartesian) then
      begin
        X := MapX(L, FXAxis.Kind, FReferenceLines[I].Value);
        Pts := nil;
        SetLength(Pts, 2);
        Pts[0] := Point(X, L.PlotR.Top);
        Pts[1] := Point(X, L.PlotR.Bottom);
      end
      else if L.Mode = cmHorizontal then
      begin
        if FReferenceLines[I].Axis <> claY then
          Continue;
        X := MapValueX(L, FReferenceLines[I].Value);
        SetLength(Pts, 2);
        Pts[0] := Point(X, L.PlotR.Top);
        Pts[1] := Point(X, L.PlotR.Bottom);
      end
      else
      begin
        if (FReferenceLines[I].Axis = claY2) and not L.HasY2 then
          Continue;
        if FReferenceLines[I].Axis = claY2 then
          Y := MapY(L, L.Y2Scale, FReferenceLines[I].Value)
        else
          Y := MapY(L, L.YScale, FReferenceLines[I].Value);
        SetLength(Pts, 2);
        Pts[0] := Point(L.PlotR.Left, Y);
        Pts[1] := Point(L.PlotR.Right, Y);
      end;
      if FReferenceLines[I].Dashed then
        PPGDrawDashedLine(ACanvas, Pts, W, PPGScale(5, PPI), PPGScale(3, PPI), LineCol, 255)
      else
        ACanvas.DrawPolyline(Pts, W, LineCol, 255);
      if FReferenceLines[I].Caption <> '' then
      begin
        Sz := ACanvas.MeasureText(FReferenceLines[I].Caption, Font, 0, False);
        if Pts[0].Y = Pts[1].Y then
          TR := Rect(L.PlotR.Right - Sz.cx - Gap, Pts[0].Y - Sz.cy - PPGScale(1, PPI),
            L.PlotR.Right - Gap, Pts[0].Y - PPGScale(1, PPI))
        else
          TR := Rect(Pts[0].X + Gap div 2, L.PlotR.Top, Pts[0].X + Gap div 2 + Sz.cx,
            L.PlotR.Top + Sz.cy);
        ACanvas.DrawText(TR, FReferenceLines[I].Caption, Font, LineCol,
          DT_SINGLELINE or DT_NOPREFIX);
      end;
    end;

    // Markierungen am Tooltip-Punkt (Linien und Flaechen)
    if FShowTooltips and (L.Mode = cmCartesian) then
    begin
      for K := 0 to High(Frames) do
      begin
        S := FSeries[Frames[K].Index];
        if IsColumnKind(S.Kind) or not S.Visible then
          Continue;
        J := -1;
        if (FHot.Kind = chkPlot) and (FHot.Index >= 0) then
        begin
          if FXAxis.Kind = cxkCategory then
            J := FHot.Index
          else
            J := NearestIndex(S, FHotDataX);
        end
        else if Focused and (FFocusSeries = Frames[K].Index) and (FFocusIndex >= 0) then
          J := FFocusIndex;
        if (J >= 0) and (J < Length(Frames[K].Ys)) then
          CR.DrawChartMarker(ACanvas, Point(MapX(L, FXAxis.Kind, Frames[K].Xs[J]),
            MapY(L, ScaleOf(L, S), Frames[K].Hi[J])), PPGScale(HoverRadius, PPI),
            SeriesColor(Frames[K].Index), Bg, PPI);
      end;
    end;
  finally
    ACanvas.PopClip;
  end;

  // ---- Tooltip ----
  if FShowTooltips then
  begin
    P := FMousePos;
    if (FHot.Kind = chkPlot) and (FHot.Index >= 0) then
    begin
      if FXAxis.Kind = cxkCategory then
        AddLine(XLabel(FirstDrawnSeries, FHot.Index), clNone)
      else
        AddLine('', clNone);
      for K := 0 to High(Frames) do
      begin
        S := FSeries[Frames[K].Index];
        if not S.Visible then
          Continue;
        if FXAxis.Kind = cxkCategory then
          J := FHot.Index
        else
          J := NearestIndex(S, FHotDataX);
        if (J < 0) or (J >= S.Count) then
          Continue;
        if Lines[0] = '' then
          Lines[0] := XLabel(Frames[K].Index, J);
        AddLine(SeriesTitle(S) + ': ' + ValueText(Frames[K].Index, S.YAt(J)),
          SeriesColor(Frames[K].Index));
      end;
      if Length(Lines) > 1 then
        DrawTooltip(P);
    end
    else if Focused and (FFocusSeries >= 0) and (FFocusSeries < FSeries.Count) and
      (FFocusIndex >= 0) and (FFocusIndex < FSeries[FFocusSeries].Count) then
    begin
      if PointPos(FFocusSeries, FFocusIndex, P) then
      begin
        AddLine(XLabel(FFocusSeries, FFocusIndex), clNone);
        AddLine(SeriesTitle(FSeries[FFocusSeries]) + ': ' +
          ValueText(FFocusSeries, FSeries[FFocusSeries].YAt(FFocusIndex)),
          SeriesColor(FFocusSeries));
        DrawTooltip(P);
      end;
    end;
  end;

  if FocusVisible then
    Renderer.DrawFocus(ACanvas, ClientR, GetCurrentStyle);
  FFonts.Clear; // keine Schrift-Handles ueber das Zeichnen hinaus
end;

{ ---- Treffer ---- }

function TPPGCustomChart.HitTest(X, Y: Integer): TPPGChartHit;
var
  L: TPPGChartLayout;
  I, K, ColCount, ColNo, Best: Integer;
  Slot, GroupW, BarW, A, D, Total, Start, Sweep, BestD: Double;
  S: TPPGChartSeries;
  P: TPoint;
begin
  Result.Kind := chkNone;
  Result.Series := -1;
  Result.Index := -1;
  L := Layout;
  for I := 0 to High(L.Legend) do
    if PtInRect(L.Legend[I].R, Point(X, Y)) then
    begin
      Result.Kind := chkLegend;
      Result.Series := L.Legend[I].Index;
      Exit;
    end;
  case L.Mode of
    cmPie:
      begin
        D := Sqrt(Sqr(X - L.PieCenter.X) + Sqr(Y - L.PieCenter.Y));
        if (D > L.PieRadius + PPGScale(4, ScalePPI)) or (D < L.PieInner) then
          Exit;
        S := FSeries[L.PieSeries];
        Total := 0;
        for I := 0 to S.Count - 1 do
          Total := Total + Abs(S.YAt(I));
        if Total <= 0 then
          Exit;
        A := ArcTan2(Y - L.PieCenter.Y, X - L.PieCenter.X) * 180 / Pi + 90;
        if A < 0 then
          A := A + 360;
        Start := 0;
        for I := 0 to S.Count - 1 do
        begin
          Sweep := 360 * Abs(S.YAt(I)) / Total;
          if (A >= Start) and (A < Start + Sweep) then
          begin
            Result.Kind := chkPlot;
            Result.Series := L.PieSeries;
            Result.Index := I;
            Exit;
          end;
          Start := Start + Sweep;
        end;
      end;
    cmCartesian, cmHorizontal:
      begin
        if not PtInRect(L.PlotR, Point(X, Y)) then
          Exit;
        Result.Kind := chkPlot;
        if (FXAxis.Kind = cxkCategory) or (L.Mode = cmHorizontal) then
        begin
          if L.CatCount <= 0 then
            Exit;
          if L.Mode = cmHorizontal then
          begin
            Slot := (L.PlotR.Bottom - L.PlotR.Top) / L.CatCount;
            Result.Index := System.Math.Min(Trunc((Y - L.PlotR.Top) / Slot), L.CatCount - 1);
            D := Y - L.PlotR.Top - Slot * Result.Index;
          end
          else
          begin
            Slot := (L.PlotR.Right - L.PlotR.Left) / L.CatCount;
            Result.Index := System.Math.Min(Trunc((X - L.PlotR.Left) / Slot), L.CatCount - 1);
            D := X - L.PlotR.Left - Slot * Result.Index;
          end;
          // Saeule unter der Maus (gruppiert) bzw. naechste Linie
          ColCount := 0;
          for I := 0 to FSeries.Count - 1 do
            if FSeries[I].IsDrawn and FSeries[I].Visible and IsColumnKind(FSeries[I].Kind) then
              Inc(ColCount);
          if (ColCount > 0) and (FStacking = cstNone) then
          begin
            GroupW := Slot * 0.72;
            BarW := GroupW / ColCount;
            ColNo := Floor((D - (Slot - GroupW) / 2) / BarW);
            K := 0;
            for I := 0 to FSeries.Count - 1 do
              if FSeries[I].IsDrawn and FSeries[I].Visible and IsColumnKind(FSeries[I].Kind) then
              begin
                if K = ColNo then
                begin
                  Result.Series := I;
                  Exit;
                end;
                Inc(K);
              end;
          end;
          Best := -1;
          BestD := MaxDouble;
          for I := 0 to FSeries.Count - 1 do
            if FSeries[I].Visible and not FSeries[I].IsPie and PointPos(I, Result.Index, P) then
            begin
              if L.Mode = cmHorizontal then
                D := Abs(P.X - X)
              else
                D := Abs(P.Y - Y);
              if D < BestD then
              begin
                BestD := D;
                Best := I;
              end;
            end;
          Result.Series := Best;
        end
        else
        begin
          // Zahl/Datum: naechster Punkt der naechsten Serie
          D := UnmapX(L, FXAxis.Kind, X);
          Best := -1;
          BestD := MaxDouble;
          for I := 0 to FSeries.Count - 1 do
          begin
            S := FSeries[I];
            if not S.Visible or S.IsPie then
              Continue;
            K := NearestIndex(S, D);
            if (K >= 0) and PointPos(I, K, P) then
              if Abs(P.Y - Y) + Abs(P.X - X) < BestD then
              begin
                BestD := Abs(P.Y - Y) + Abs(P.X - X);
                Best := I;
                Result.Index := K;
              end;
          end;
          Result.Series := Best;
        end;
      end;
  end;
end;

function TPPGCustomChart.PointPos(SeriesIndex, PointIndex: Integer; out P: TPoint): Boolean;
var
  L: TPPGChartLayout;
  S: TPPGChartSeries;
  Slot, Total, Start, A: Double;
  I, K, ColCount, ColNo: Integer;
  V, Base: Double;
begin
  Result := False;
  P := Point(0, 0);
  if (SeriesIndex < 0) or (SeriesIndex >= FSeries.Count) then
    Exit;
  S := FSeries[SeriesIndex];
  if (PointIndex < 0) or (PointIndex >= S.Count) or not S.IsDrawn then
    Exit;
  L := Layout;
  case L.Mode of
    cmPie:
      begin
        if SeriesIndex <> L.PieSeries then
          Exit;
        Total := 0;
        Start := 0;
        for I := 0 to S.Count - 1 do
        begin
          if I < PointIndex then
            Start := Start + Abs(S.YAt(I));
          Total := Total + Abs(S.YAt(I));
        end;
        if Total <= 0 then
          Exit;
        A := (360 * (Start + Abs(S.YAt(PointIndex)) / 2) / Total - 90) * Pi / 180;
        K := (L.PieRadius + L.PieInner) div 2;
        P := Point(L.PieCenter.X + Round(K * Cos(A)), L.PieCenter.Y + Round(K * Sin(A)));
        Result := True;
      end;
    cmCartesian, cmHorizontal:
      begin
        V := S.YAt(PointIndex);
        Base := 0;
        Total := 0;
        // Stapel: Oberkante ueber den vorigen Serien
        if (FStacking <> cstNone) and IsStackKind(S.Kind) and (FXAxis.Kind = cxkCategory) and
          (S.YAxis = casPrimary) then
        begin
          if FStacking = cstPercent then
          begin
            Total := 0;
            for I := 0 to FSeries.Count - 1 do
              if FSeries[I].IsDrawn and IsStackKind(FSeries[I].Kind) and
                (PointIndex < FSeries[I].Count) and (FSeries[I].YAxis = casPrimary) then
                Total := Total + Abs(FSeries[I].YAt(PointIndex));
            if Total > 0 then
              V := V / Total * 100
            else
              V := 0;
          end;
          for I := 0 to SeriesIndex - 1 do
            if FSeries[I].IsDrawn and IsStackKind(FSeries[I].Kind) and
              (PointIndex < FSeries[I].Count) and (FSeries[I].YAxis = casPrimary) and
              ((FSeries[I].YAt(PointIndex) >= 0) = (S.YAt(PointIndex) >= 0)) then
            begin
              if FStacking = cstPercent then
                Base := Base + FSeries[I].YAt(PointIndex) / System.Math.Max(Total, 1E-12) * 100
              else
                Base := Base + FSeries[I].YAt(PointIndex);
            end;
          V := Base + V;
        end;
        if L.Mode = cmHorizontal then
        begin
          if L.CatCount <= 0 then
            Exit;
          Slot := (L.PlotR.Bottom - L.PlotR.Top) / L.CatCount;
          P := Point(MapValueX(L, V), L.PlotR.Top + Round(Slot * (PointIndex + 0.5)));
          Result := True;
          Exit;
        end;
        if FXAxis.Kind = cxkCategory then
          P.X := MapX(L, cxkCategory, PointIndex)
        else
          P.X := MapX(L, FXAxis.Kind, S.XAt(PointIndex));
        P.Y := MapY(L, ScaleOf(L, S), V);
        // Gruppierte Saeule: Mitte der eigenen Saeule
        if IsColumnKind(S.Kind) and (FStacking = cstNone) and (FXAxis.Kind = cxkCategory) and
          (L.CatCount > 0) then
        begin
          ColCount := 0;
          ColNo := 0;
          for I := 0 to FSeries.Count - 1 do
            if FSeries[I].IsDrawn and IsColumnKind(FSeries[I].Kind) then
            begin
              if I = SeriesIndex then
                ColNo := ColCount;
              Inc(ColCount);
            end;
          Slot := (L.PlotR.Right - L.PlotR.Left) / L.CatCount;
          P.X := L.PlotR.Left + Round(Slot * PointIndex + Slot * 0.14 +
            Slot * 0.72 / ColCount * (ColNo + 0.5));
        end;
        Result := True;
      end;
  end;
end;

procedure TPPGCustomChart.SetHot(const Hit: TPPGChartHit; DataX: Double);
begin
  if (Hit.Kind = FHot.Kind) and (Hit.Series = FHot.Series) and (Hit.Index = FHot.Index) and
    (DataX = FHotDataX) then
    Exit;
  FHot := Hit;
  FHotDataX := DataX;
  Invalidate;
end;

procedure TPPGCustomChart.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  H: TPPGChartHit;
  DX: Double;
begin
  inherited MouseMove(Shift, X, Y);
  FMousePos := Point(X, Y);
  H := HitTest(X, Y);
  DX := 0;
  if (H.Kind = chkPlot) and (FXAxis.Kind <> cxkCategory) and (H.Series >= 0) and
    (H.Index >= 0) then
    DX := FSeries[H.Series].XAt(H.Index);
  if H.Kind = chkLegend then
    Cursor := crHandPoint
  else
    Cursor := crDefault;
  SetHot(H, DX);
  if (H.Kind = chkPlot) and FShowTooltips then
    Invalidate; // Tooltip folgt der Maus
end;

procedure TPPGCustomChart.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  H: TPPGChartHit;
  L: TPPGChartLayout;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button <> mbLeft then
    Exit;
  H := HitTest(X, Y);
  if (H.Kind = chkLegend) and FLegendToggle then
  begin
    L := Layout;
    if (L.Mode <> cmPie) and (H.Series >= 0) then
      FSeries[H.Series].Visible := not FSeries[H.Series].Visible;
  end
  else if (H.Kind = chkPlot) and (H.Series >= 0) and (H.Index >= 0) then
  begin
    FFocusSeries := H.Series;
    FFocusIndex := H.Index;
    DoPointClick(H.Series, H.Index);
  end;
end;

procedure TPPGCustomChart.DoPointClick(SeriesIndex, PointIndex: Integer);
begin
  if Assigned(FOnPointClick) then
    FOnPointClick(Self, SeriesIndex, PointIndex);
end;

{ ---- Tastatur ---- }

function TPPGCustomChart.NextDrawnSeries(From, Dir: Integer): Integer;
var
  I, N: Integer;
begin
  Result := From;
  N := FSeries.Count;
  if N = 0 then
    Exit(-1);
  I := From;
  repeat
    I := I + Dir;
    if (I < 0) or (I >= N) then
      Exit;
    if FSeries[I].Visible and (FSeries[I].Count > 0) and
      (FSeries[I].IsPie = ((From >= 0) and (From < N) and FSeries[From].IsPie)) then
      Exit(I);
  until False;
end;

procedure TPPGCustomChart.ClampFocus;
begin
  if (FFocusSeries < 0) or (FFocusSeries >= FSeries.Count) then
  begin
    FFocusSeries := -1;
    FFocusIndex := -1;
    Exit;
  end;
  if FFocusIndex >= FSeries[FFocusSeries].Count then
    FFocusIndex := FSeries[FFocusSeries].Count - 1;
end;

procedure TPPGCustomChart.FocusPoint(SeriesIndex, PointIndex: Integer);
begin
  if (SeriesIndex < 0) or (SeriesIndex >= FSeries.Count) then
  begin
    FFocusSeries := -1;
    FFocusIndex := -1;
  end
  else
  begin
    FFocusSeries := SeriesIndex;
    FFocusIndex := PointIndex;
    ClampFocus;
  end;
  Invalidate;
  if FFocusIndex >= 0 then
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, AccFocusedChild);
end;

procedure TPPGCustomChart.KeyDown(var Key: Word; Shift: TShiftState);
var
  S, Cnt: Integer;
begin
  if Enabled and (FSeries.Count > 0) then
  begin
    S := FFocusSeries;
    if (S < 0) or (S >= FSeries.Count) or not FSeries[S].Visible then
    begin
      S := Layout.PieSeries;
      if S < 0 then
        S := NextDrawnSeries(-1, 1);
    end;
    if S >= 0 then
    begin
      Cnt := FSeries[S].Count;
      case Key of
        VK_LEFT, VK_RIGHT:
          begin
            if FFocusIndex < 0 then
              FocusPoint(S, 0)
            else if (Key = VK_RIGHT) <> UseRightToLeftAlignment then
              FocusPoint(S, System.Math.Min(FFocusIndex + 1, Cnt - 1))
            else
              FocusPoint(S, System.Math.Max(FFocusIndex - 1, 0));
            Key := 0;
          end;
        VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT:
          begin
            if (Key = VK_DOWN) or (Key = VK_NEXT) then
              FocusPoint(NextDrawnSeries(S, 1), System.Math.Max(FFocusIndex, 0))
            else
              FocusPoint(NextDrawnSeries(S, -1), System.Math.Max(FFocusIndex, 0));
            Key := 0;
          end;
        VK_HOME:
          begin
            FocusPoint(S, 0);
            Key := 0;
          end;
        VK_END:
          begin
            FocusPoint(S, Cnt - 1);
            Key := 0;
          end;
        VK_RETURN:
          begin
            if (FFocusSeries >= 0) and (FFocusIndex >= 0) then
              DoPointClick(FFocusSeries, FFocusIndex);
            Key := 0;
          end;
        VK_ESCAPE:
          if FFocusIndex >= 0 then
          begin
            FFocusIndex := -1;
            Invalidate;
            Key := 0;
          end;
      end;
    end;
  end;
  inherited KeyDown(Key, Shift);
end;

procedure TPPGCustomChart.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TPPGCustomChart.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

{ ---- Barrierefreiheit ---- }

function TPPGCustomChart.AccName: string;
begin
  if FTitle <> '' then
    Result := FTitle
  else
    Result := Hint;
end;

function TPPGCustomChart.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_CHART;
end;

function TPPGCustomChart.AccState: Integer;
begin
  Result := (inherited AccState) or STATE_SYSTEM_READONLY;
end;

function TPPGCustomChart.AccValue: string;
var
  I: Integer;
begin
  Result := '';
  if TotalPoints = 0 then
    Exit(PPGStr(@SPPGChartNoData));
  for I := 0 to FSeries.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + '; ';
    if FSeries[I].Visible then
      Result := Result + Format(PPGStr(@SPPGChartSeriesName), [SeriesTitle(FSeries[I]),
        FSeries[I].Count])
    else
      Result := Result + Format(PPGStr(@SPPGChartSeriesHidden), [SeriesTitle(FSeries[I])]);
  end;
end;

function AccCount(S: TPPGChartSeries): Integer;
begin
  if not S.Visible then
    Exit(0);
  Result := System.Math.Min(S.Count, AccMaxPerSeries);
end;

function TPPGCustomChart.AccChildCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FSeries.Count - 1 do
    Inc(Result, AccCount(FSeries[I]));
end;

// Id (1..) -> Serie und Punkt
function ChildToPoint(Chart: TPPGCustomChart; Id: Integer; out SI, PIdx: Integer): Boolean;
var
  I, C: Integer;
begin
  Result := False;
  SI := -1;
  PIdx := -1;
  Dec(Id);
  if Id < 0 then
    Exit;
  for I := 0 to Chart.Series.Count - 1 do
  begin
    C := AccCount(Chart.Series[I]);
    if Id < C then
    begin
      SI := I;
      PIdx := Id;
      Exit(True);
    end;
    Dec(Id, C);
  end;
end;

function PointToChild(Chart: TPPGCustomChart; SI, PIdx: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  if (SI < 0) or (SI >= Chart.Series.Count) or (PIdx < 0) or
    (PIdx >= AccCount(Chart.Series[SI])) then
    Exit;
  for I := 0 to SI - 1 do
    Inc(Result, AccCount(Chart.Series[I]));
  Result := Result + PIdx + 1;
end;

function TPPGCustomChart.AccChildName(Id: Integer): string;
var
  SI, PIdx: Integer;
begin
  Result := '';
  if not ChildToPoint(Self, Id, SI, PIdx) then
    Exit;
  Result := Format(PPGStr(@SPPGChartPointName), [SeriesTitle(FSeries[SI]), XLabel(SI, PIdx),
    ValueText(SI, FSeries[SI].YAt(PIdx))]);
end;

function TPPGCustomChart.AccChildRole(Id: Integer): Integer;
begin
  Result := ROLE_SYSTEM_LISTITEM;
end;

function TPPGCustomChart.AccChildState(Id: Integer): Integer;
var
  SI, PIdx: Integer;
begin
  Result := STATE_SYSTEM_READONLY or STATE_SYSTEM_FOCUSABLE;
  if ChildToPoint(Self, Id, SI, PIdx) and (SI = FFocusSeries) and (PIdx = FFocusIndex) and Focused then
    Result := Result or STATE_SYSTEM_FOCUSED;
end;

function TPPGCustomChart.AccChildRect(Id: Integer): TRect;
var
  SI, PIdx, D: Integer;
  P: TPoint;
begin
  Result := Rect(0, 0, 0, 0);
  if ChildToPoint(Self, Id, SI, PIdx) and PointPos(SI, PIdx, P) then
  begin
    D := PPGScale(HoverRadius, ScalePPI);
    Result := Rect(P.X - D, P.Y - D, P.X + D, P.Y + D);
  end;
end;

function TPPGCustomChart.AccChildAt(X, Y: Integer): Integer;
var
  H: TPPGChartHit;
begin
  H := HitTest(X, Y);
  Result := 0;
  if (H.Kind = chkPlot) and (H.Series >= 0) then
    Result := PointToChild(Self, H.Series, H.Index);
end;

function TPPGCustomChart.AccChildDefaultAction(Id: Integer): string;
begin
  Result := '';
end;

procedure TPPGCustomChart.AccChildDoDefault(Id: Integer);
begin
  // Datenpunkte haben keine Standardaktion
end;

function TPPGCustomChart.AccFocusedChild: Integer;
begin
  Result := 0;
  if Focused then
    Result := PointToChild(Self, FFocusSeries, FFocusIndex);
end;

function TPPGCustomChart.AccSelectedChild: Integer;
begin
  Result := PointToChild(Self, FFocusSeries, FFocusIndex);
end;

{ ---- Export ---- }

procedure TPPGCustomChart.SaveToBitmap(Bitmap: TBitmap);
var
  C: IPPGCanvas;
  Bg: TColor;
  I: Integer;
begin
  // Ein Export zeigt immer den Endzustand, nie ein Zwischenbild einer
  // laufenden Animation (Aufbau, Uebergang, Ein-/Ausblenden)
  FIntroAnim.Jump(1);
  FChangeAnim.Jump(1);
  for I := 0 to FSeries.Count - 1 do
    FSeries[I].FinishAnimation;
  Bitmap.PixelFormat := pf24bit;
  Bitmap.SetSize(ClientWidth, ClientHeight);
  Bg := PPGColorToRGB(GetBackgroundColor);
  Bitmap.Canvas.Brush.Color := Bg;
  Bitmap.Canvas.FillRect(Rect(0, 0, ClientWidth, ClientHeight));
  C := TPPGRendererRegistry.CreateCanvas(Bitmap.Canvas.Handle);
  try
    DoPaint(C, Rect(0, 0, ClientWidth, ClientHeight));
  finally
    C := nil; // GDI+ gibt den DC frei, bevor TBitmap ihn wieder benutzt
  end;
end;

procedure TPPGCustomChart.SaveToPng(const FileName: string);
var
  Bmp: TBitmap;
begin
  // PNG ueber GDI+ statt Vcl.Imaging.pngimage: PPGlowR braucht so kein vclimg
  Bmp := TBitmap.Create;
  try
    SaveToBitmap(Bmp);
    PPGSaveBitmapAsPng(Bmp.Handle, FileName);
  finally
    Bmp.Free;
  end;
end;

procedure TPPGCustomChart.CopyToClipboard;
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    SaveToBitmap(Bmp);
    Clipboard.Assign(Bmp);
  finally
    Bmp.Free;
  end;
end;

end.
