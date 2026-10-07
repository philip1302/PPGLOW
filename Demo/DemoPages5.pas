unit DemoPages5;

{ Demo-Seite "Diagramme" (Phase 10): Dashboard mit KPI-Kacheln, Gauge,
  Saeulen-/Liniendiagramm, Ring und Live-Daten (ueber den gemeinsamen
  Animator, kein Timer). }

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Math, Vcl.Controls, Vcl.StdCtrls,
  PPG.Types, PPG.Animation, PPG.Panel, PPG.Labels, PPG.Button, PPG.ComboBox,
  PPG.Sparkline, PPG.Gauge, PPG.Chart.Series, PPG.Chart,
  DemoKit;

type
  TDemoChartsPage = class(TDemoPage)
  private
    FTiles: array[0..3] of TPPGKpiTile;
    FSales: TPPGChart;
    FKind: TPPGComboBox;
    FLegend: TPPGComboBox;
    FGauge: TPPGGauge;
    FDonut: TPPGChart;
    FLive: TPPGChart;
    FLiveSpark: TPPGSparkline;
    FLiveButton: TPPGButton;
    FLiveAnim: TPPGAnimation;
    FLivePhase: Single;
    FLiveValue: Double;
    FResult: TPPGLabel;
    procedure KindChange(Sender: TObject);
    procedure LegendChange(Sender: TObject);
    procedure LiveClick(Sender: TObject);
    procedure LiveStep(Sender: TObject);
    procedure TileClick(Sender: TObject);
    procedure SalesPointClick(Sender: TObject; SeriesIndex, PointIndex: Integer);
    procedure AddLiveValue;
  protected
    procedure Build; override;
  public
    destructor Destroy; override;
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

uses
  PPG.Controls.Base;

const
  FullW = 2 * 484 + CardGap;
  TileW = (FullW - 3 * CardGap) div 4;
  TileH = 120;
  SalesW = 600;
  SideW = FullW - SalesW - CardGap;
  Row2H = 360;
  Row3H = 300;
  HalfW = (FullW - CardGap) div 2;
  LiveMax = 60;

  Months: array[0..11] of string = ('Jan', 'Feb', 'M{ae}r', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug',
    'Sep', 'Okt', 'Nov', 'Dez');
  Plan: array[0..11] of Double = (40, 42, 45, 47, 50, 52, 55, 54, 58, 60, 63, 70);
  Actual: array[0..11] of Double = (38, 44, 43, 49, 53, 51, 57, 59, 56, 62, 66, 74);
  Returns: array[0..11] of Double = (4.1, 3.8, 4.4, 3.9, 3.5, 3.6, 3.2, 3.4, 3.1, 2.9, 3.0, 2.7);

destructor TDemoChartsPage.Destroy;
begin
  if FLiveAnim <> nil then
    FLiveAnim.OnStep := nil;
  FreeAndNil(FLiveAnim);
  inherited Destroy;
end;

procedure TDemoChartsPage.Build;
var
  Card: TPPGPanel;
  S: TPPGChartSeries;
  I, Y: Integer;
  Rg: TPPGGaugeRange;
  Line: TPPGChartReferenceLine;
begin
  NewPageHeader(Own, Sheet, 'Diagramme', 'Sparkline, Gauge, KPI-Kachel und Chart folgen Preset, ' +
    L('Dark Mode und Hochkontrast. Fahren Sie mit der Maus {ue}ber die Diagramme oder nutzen Sie ') +
    'die Pfeiltasten; ein Klick auf die Legende blendet eine Reihe aus.');

  // ---- KPI-Kacheln ----
  for I := 0 to 3 do
  begin
    FTiles[I] := TPPGKpiTile.Create(Own);
    FTiles[I].Parent := Sheet;
    FTiles[I].SetBounds(PageX + I * (TileW + CardGap), PageContentTop, TileW, TileH);
    FTiles[I].OnClick := TileClick;
  end;
  FTiles[0].Title := 'Umsatz 2026';
  FTiles[0].Value := 671000;
  FTiles[0].Units := L('{EUR}');
  FTiles[0].Change := 6.4;
  FTiles[0].SetSparkline(Actual);
  FTiles[1].Title := 'Bestellungen';
  FTiles[1].Value := 18420;
  FTiles[1].Change := 2.1;
  FTiles[1].SparklineKind := skColumn;
  FTiles[1].SparklineText := '12;14;13;15;17;16;18;19;18;21;22;24';
  FTiles[2].Title := 'Retourenquote';
  FTiles[2].ValueText := FormatFloat('0.0', 2.7) + ' %';
  FTiles[2].Change := -0.4;
  FTiles[2].InvertTrend := True; // weniger ist besser
  FTiles[2].SetSparkline(Returns);
  FTiles[3].Title := 'Live (Anfragen/s)';
  FTiles[3].ValueFormat := '0';
  FTiles[3].ChangeFormat := '+0;-0;0';
  FTiles[3].SparklineKind := skLine;
  Host.RegisterSpecial('kpi', FTiles[0]);

  // ---- Umsatz: Saeulen + Linie ----
  Y := PageContentTop + TileH + CardGap;
  Card := NewCard(Own, Sheet, PageX, Y, SalesW, Row2H, 'Umsatz je Monat',
    'Plan als S{ae}ulen, Ist als Linie, Ziel als Referenzlinie.');
  FSales := TPPGChart.Create(Own);
  FSales.Parent := Card;
  FSales.SetBounds(CardPad - 8, Card.Tag + 36, SalesW - 2 * CardPad + 16, Row2H - Card.Tag - 80);
  for I := 0 to High(Months) do
    FSales.Categories.Add(L(Months[I]));
  S := FSales.Series.Add;
  S.Title := 'Plan';
  S.Kind := cskColumn;
  S.SetValues(Plan);
  S := FSales.Series.Add;
  S.Title := 'Ist';
  S.Kind := cskLine;
  S.ShowMarkers := True;
  S.SetValues(Actual);
  S.ValueFormat := L('0 T{EUR}');
  FSales.YAxis.Title := L('T{EUR}');
  Line := FSales.ReferenceLines.Add;
  Line.Value := 60;
  Line.Caption := 'Ziel';
  FSales.OnPointClick := SalesPointClick;
  Host.RegisterSpecial('chart', FSales);
  FKind := TPPGComboBox.Create(Own);
  FKind.Parent := Card;
  FKind.Style := csDropDownList;
  FKind.SetBounds(CardPad, Card.Tag, 220, CtlH);
  FKind.Items.Add(L('S{ae}ulen + Linie'));
  FKind.Items.Add(L('Gestapelte S{ae}ulen'));
  FKind.Items.Add(L('100 % gestapelt'));
  FKind.Items.Add(L('Fl{ae}chen'));
  FKind.Items.Add('Stufenlinien');
  FKind.Items.Add('Balken (quer)');
  FKind.ItemIndex := 0;
  FKind.OnChange := KindChange;
  FLegend := TPPGComboBox.Create(Own);
  FLegend.Parent := Card;
  FLegend.Style := csDropDownList;
  FLegend.SetBounds(CardPad + 232, Card.Tag, 160, CtlH);
  FLegend.Items.Add('Legende unten');
  FLegend.Items.Add('Legende oben');
  FLegend.Items.Add('Legende rechts');
  FLegend.Items.Add('Ohne Legende');
  FLegend.ItemIndex := 0;
  FLegend.OnChange := LegendChange;
  FResult := NewResult(Own, Card, 'Punkt');

  // ---- Gauge ----
  Card := NewCard(Own, Sheet, PageX + SalesW + CardGap, Y, SideW, Row2H, 'Auslastung',
    'Bereiche in Signalfarben, Zielmarke bei 80 %. Als Schieberegler bedienbar.');
  FGauge := TPPGGauge.Create(Own);
  FGauge.Parent := Card;
  FGauge.SetBounds(CardPad, Card.Tag, SideW - 2 * CardPad, Row2H - Card.Tag - CardPad);
  FGauge.Caption := 'Rechenzentrum';
  FGauge.Units := ' %';
  Rg := FGauge.Ranges.Add;
  Rg.EndValue := 60;
  Rg.RangeColor := grcSuccess;
  Rg := FGauge.Ranges.Add;
  Rg.StartValue := 60;
  Rg.EndValue := 85;
  Rg.RangeColor := grcWarning;
  Rg := FGauge.Ranges.Add;
  Rg.StartValue := 85;
  Rg.EndValue := 100;
  Rg.RangeColor := grcDanger;
  FGauge.ShowTarget := True;
  FGauge.TargetValue := 80;
  FGauge.ReadOnly := False;
  FGauge.Increment := 5;
  FGauge.Value := 68;

  // ---- Ring: Umsatz nach Region ----
  Y := Y + Row2H + CardGap;
  Card := NewCard(Own, Sheet, PageX, Y, HalfW, Row3H, 'Umsatz nach Region',
    'Ring mit Summe in der Mitte; Segmente per Pfeiltasten.');
  FDonut := TPPGChart.Create(Own);
  FDonut.Parent := Card;
  FDonut.SetBounds(CardPad - 8, Card.Tag, HalfW - 2 * CardPad + 16, Row3H - Card.Tag - 12);
  FDonut.LegendPosition := clpRight;
  S := FDonut.Series.Add;
  S.Kind := cskDonut;
  S.ValueFormat := L('#,##0 T{EUR}');
  S.Add(248, 'Nord');
  S.Add(196, L('S{ue}d'));
  S.Add(131, 'West');
  S.Add(96, 'Ost');
  Host.RegisterSpecial('donut', FDonut);

  // ---- Live ----
  Card := NewCard(Own, Sheet, PageX + HalfW + CardGap, Y, HalfW, Row3H, 'Live-Daten',
    L('Neue Werte {ue}ber den gemeinsamen Animator, Lauffenster mit 60 Punkten.'));
  FLiveButton := NewButton(Own, Card, CardPad, Card.Tag, 120, 'Starten', LiveClick, True);
  FLiveSpark := TPPGSparkline.Create(Own);
  FLiveSpark.Parent := Card;
  FLiveSpark.SetBounds(CardPad + 140, Card.Tag, HalfW - 2 * CardPad - 140, CtlH);
  FLiveSpark.MaxCount := LiveMax;
  FLiveSpark.Kind := skWinLoss;
  FLiveSpark.Markers := [];
  FLive := TPPGChart.Create(Own);
  FLive.Parent := Card;
  FLive.SetBounds(CardPad - 8, Card.Tag + CtlH + 8, HalfW - 2 * CardPad + 16,
    Row3H - Card.Tag - CtlH - 20);
  FLive.LegendPosition := clpNone;
  FLive.XAxis.Visible := False;
  S := FLive.Series.Add;
  S.Title := 'Anfragen/s';
  S.Kind := cskArea;
  FLiveValue := 50;
  for I := 1 to 30 do
    AddLiveValue;
  FLiveAnim := TPPGAnimation.Create(Self);
  FLiveAnim.OnStep := LiveStep;
end;

procedure TDemoChartsPage.AddLiveValue;
var
  Old: Double;
  Last: TArray<Double>;
  I, N, First: Integer;
begin
  Old := FLiveValue;
  FLiveValue := EnsureRange(FLiveValue + (Random - 0.48) * 12, 5, 120);
  FLive.Series[0].Append(FLiveValue, LiveMax);
  FLiveSpark.AddValue(FLiveValue - Old);
  FTiles[3].Value := FLiveValue;
  FTiles[3].Change := FLiveValue - Old;
  // Kachel: die letzten 20 Werte als Sparkline
  N := FLive.Series[0].Count;
  First := Max(0, N - 20);
  SetLength(Last, N - First);
  for I := First to N - 1 do
    Last[I - First] := FLive.Series[0].Y[I];
  FTiles[3].SetSparkline(Last);
end;

procedure TDemoChartsPage.LiveClick(Sender: TObject);
begin
  if FLiveAnim.Running then
  begin
    FLiveAnim.Stop;
    FLiveButton.Caption := 'Starten';
    Host.Log('Diagramme', 'Live angehalten');
  end
  else
  begin
    FLivePhase := 0;
    FLiveAnim.StartLoop(400);
    FLiveButton.Caption := 'Anhalten';
    Host.Log('Diagramme', 'Live gestartet');
  end;
end;

procedure TDemoChartsPage.LiveStep(Sender: TObject);
begin
  // Ein neuer Wert pro Umlauf (Value springt von 1 auf 0 zurueck)
  if FLiveAnim.Value < FLivePhase then
    AddLiveValue;
  FLivePhase := FLiveAnim.Value;
end;

procedure TDemoChartsPage.KindChange(Sender: TObject);
begin
  FSales.BeginDataUpdate;
  try
    FSales.Stacking := cstNone;
    FSales.Series[1].YAxis := casPrimary;
    case FKind.ItemIndex of
      1:
        begin
          FSales.Series[0].Kind := cskColumn;
          FSales.Series[1].Kind := cskColumn;
          FSales.Stacking := cstStacked;
        end;
      2:
        begin
          FSales.Series[0].Kind := cskColumn;
          FSales.Series[1].Kind := cskColumn;
          FSales.Stacking := cstPercent;
        end;
      3:
        begin
          FSales.Series[0].Kind := cskArea;
          FSales.Series[1].Kind := cskArea;
        end;
      4:
        begin
          FSales.Series[0].Kind := cskStepLine;
          FSales.Series[1].Kind := cskStepLine;
        end;
      5:
        begin
          FSales.Series[0].Kind := cskBar;
          FSales.Series[1].Kind := cskBar;
        end;
    else
      FSales.Series[0].Kind := cskColumn;
      FSales.Series[1].Kind := cskLine;
    end;
  finally
    FSales.EndDataUpdate;
  end;
  Host.Log('Diagramme', 'Darstellung: ' + FKind.Text);
end;

procedure TDemoChartsPage.LegendChange(Sender: TObject);
begin
  case FLegend.ItemIndex of
    1: FSales.LegendPosition := clpTop;
    2: FSales.LegendPosition := clpRight;
    3: FSales.LegendPosition := clpNone;
  else
    FSales.LegendPosition := clpBottom;
  end;
end;

procedure TDemoChartsPage.TileClick(Sender: TObject);
begin
  Host.Log('Diagramme', 'Kachel: ' + TPPGKpiTile(Sender).Title);
end;

procedure TDemoChartsPage.SalesPointClick(Sender: TObject; SeriesIndex, PointIndex: Integer);
begin
  SetResult(FResult, Format('%s, %s: %s', [FSales.Series[SeriesIndex].Title,
    FSales.XLabel(SeriesIndex, PointIndex), FSales.ValueText(SeriesIndex,
    FSales.Series[SeriesIndex].Y[PointIndex])]));
  Host.Log('Diagramme', 'Punkt: ' + FSales.XLabel(SeriesIndex, PointIndex));
end;

procedure TDemoChartsPage.SelfTest(Check: TDemoCheck);
var
  P: TPoint;
  H: TPPGChartHit;
  N: Integer;
begin
  Check('Diagramme: Umsatz kartesisch', FSales.Layout.Mode = cmCartesian);
  Check('Diagramme: Achse ab Null', FSales.Layout.YScale.Min = 0);
  FKind.ItemIndex := 5;
  KindChange(nil);
  Check('Diagramme: Balken liegen quer', FSales.Layout.Mode = cmHorizontal);
  FKind.ItemIndex := 2;
  KindChange(nil);
  Check('Diagramme: 100 % gestapelt', FSales.Layout.YScale.Max = 100);
  FKind.ItemIndex := 0;
  KindChange(nil);
  Check('Diagramme: Punkt gefunden', FSales.PointPos(1, 3, P));
  H := FSales.HitTest(P.X, P.Y);
  Check('Diagramme: Treffer im Monat', (H.Kind = chkPlot) and (H.Index = 3));
  FSales.Series[1].Visible := False;
  Check('Diagramme: Reihe ausgeblendet', not FSales.Series[1].Visible);
  FSales.Series[1].Visible := True;
  Check('Diagramme: Ring', FDonut.Layout.Mode = cmPie);
  Check('Diagramme: Ring-Segment', FDonut.PointPos(0, 1, P) and (FDonut.HitTest(P.X, P.Y).Index = 1));
  Check('Diagramme: Retourenquote sinkt = gut', FTiles[2].ChangeColor = FTiles[0].ChangeColor);
  FGauge.Value := 95;
  Check('Diagramme: Gauge im roten Bereich',
    FGauge.ArcColor(FGauge.Value) <> FGauge.ArcColor(30));
  FGauge.Value := 68;
  N := FLive.Series[0].Count;
  AddLiveValue;
  Check('Diagramme: Live-Wert angehaengt', (FLive.Series[0].Count = Min(N + 1, LiveMax)) and
    (FTiles[3].Value = FLiveValue));
end;

end.
