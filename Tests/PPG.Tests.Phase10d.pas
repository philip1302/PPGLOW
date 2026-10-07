unit PPG.Tests.Phase10d;

{$WARN SYMBOL_PLATFORM OFF}

{ Tests fuer Phase 10d: TPPGChart (PPG.Chart, PPG.Chart.Series) sowie
  Zeichnen und Ressourcen aller Diagramm-Controls der Phase 10. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.DateUtils, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Clipbrd, System.TypInfo, Vcl.Imaging.pngimage,
  PPG.Types, PPG.Tokens, PPG.Consts, PPG.Render.Registry, PPG.Controls.Base,
  PPG.Exceptions, PPG.Accessibility, PPG.Chart.Scale, PPG.Chart.Series, PPG.Chart,
  PPG.Sparkline, PPG.Gauge, PPG.Tests.Controls;

type
  TChartTestCase = class(TControlTestCase)
  protected
    FLog: TStringList;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure LogPoint(Sender: TObject; SeriesIndex, PointIndex: Integer);
    procedure VirtualPoint(Sender: TObject; SeriesIndex, Index: Integer;
      var Point: TPPGChartPoint);
    function NewChart: TPPGChart;
    /// Saeulen "Plan" und Linie "Ist" ueber sechs Monate.
    function SampleChart: TPPGChart;
    function RoundTrip(C: TComponent): TComponent;
  end;

  TChartSeriesTests = class(TChartTestCase)
  published
    procedure AddDeleteClearAndAppend;
    procedure OutOfRangeRaises;
    procedure StreamingKeepsSeriesAxesAndLines;
    procedure VirtualModeAsksHost;
    procedure SeriesVisibilityAnimates;
  end;

  TChartLayoutTests = class(TChartTestCase)
  published
    procedure ModesFromSeries;
    procedure ColumnsIncludeZeroLinesDoNot;
    procedure StackedAndPercentScales;
    procedure SecondaryAxis;
    procedure FixedAxisBounds;
    procedure NumericAndDateAxes;
    procedure LegendPositions;
    procedure RightToLeftMirrorsAxisAndLegend;
  end;

  TChartInteractionTests = class(TChartTestCase)
  published
    procedure HitTestColumnsAndLines;
    procedure HoverShowsTooltipBand;
    procedure LegendClickTogglesSeries;
    procedure PointClickByMouseAndKeyboard;
    procedure KeyboardWalksPointsAndSeries;
    procedure PieHitTestAndLegend;
    procedure HorizontalBarsHitTest;
  end;

  TChartBehaviourTests = class(TChartTestCase)
  published
    procedure IntroAndChangeAnimation;
    procedure DataUpdateBatches;
    procedure ManyPointsAreFast;
    procedure ExportBitmapPngClipboard;
    procedure ExportShowsFinalState;
    procedure AccessibilityChildren;
    procedure EmptyChartShowsNoData;
    procedure FreeWhileAnimating;
  end;

  TPhase10PaintTests = class(TChartTestCase)
  published
    procedure PaintAllPresetsModesAndKinds;
    procedure NoHandleOrMemoryLeaks;
  end;

implementation

uses
  Winapi.oleacc, PPG.Lang, PPG.Theme;

type
  TChartAccess = class(TPPGChart);
  TWinAccess = class(TWinControl);

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

function AllocatedBytes: NativeUInt;
var
  S: TMemoryManagerState;
  I: Integer;
begin
  GetMemoryManagerState(S);
  Result := S.TotalAllocatedMediumBlockSize + S.TotalAllocatedLargeBlockSize;
  for I := Low(S.SmallBlockTypeStates) to High(S.SmallBlockTypeStates) do
    Inc(Result, S.SmallBlockTypeStates[I].AllocatedBlockCount *
      S.SmallBlockTypeStates[I].UseableBlockSize);
end;

function ContentPixels(B: TBitmap; Bg: TColor): Integer;
var
  X, Y: Integer;
begin
  Result := 0;
  Bg := ColorToRGB(Bg);
  for Y := 0 to B.Height - 1 do
    for X := 0 to B.Width - 1 do
      if B.Canvas.Pixels[X, Y] <> Bg then
        Inc(Result);
end;

function Center(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

{ TChartTestCase }

procedure TChartTestCase.SetUp;
begin
  inherited SetUp;
  FLog := TStringList.Create;
  FForm.SetBounds(0, 0, 500, 360);
end;

procedure TChartTestCase.TearDown;
begin
  FreeAndNil(FLog);
  inherited TearDown;
end;

procedure TChartTestCase.LogPoint(Sender: TObject; SeriesIndex, PointIndex: Integer);
begin
  FLog.Add(Format('point:%d:%d', [SeriesIndex, PointIndex]));
end;

procedure TChartTestCase.VirtualPoint(Sender: TObject; SeriesIndex, Index: Integer;
  var Point: TPPGChartPoint);
begin
  Point.Y := Index * 2;
  Point.Text := 'V' + IntToStr(Index);
end;

function TChartTestCase.NewChart: TPPGChart;
begin
  Result := TPPGChart.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 420, 280);
  Result.Animation.Enabled := False;
  Result.OnPointClick := LogPoint;
end;

function TChartTestCase.SampleChart: TPPGChart;
var
  S: TPPGChartSeries;
begin
  Result := NewChart;
  Result.Categories.CommaText := 'Jan,Feb,Mrz,Apr,Mai,Jun';
  S := Result.Series.Add;
  S.Title := 'Plan';
  S.Kind := cskColumn;
  S.SetValues([12, 14, 13, 17, 19, 21]);
  S := Result.Series.Add;
  S.Title := 'Ist';
  S.Kind := cskLine;
  S.SetValues([11, 15, 12, 18, 17, 23]);
end;

function TChartTestCase.RoundTrip(C: TComponent): TComponent;
var
  M: TMemoryStream;
begin
  M := TMemoryStream.Create;
  try
    M.WriteComponent(C);
    M.Position := 0;
    Result := M.ReadComponent(nil);
  finally
    M.Free;
  end;
end;

{ TChartSeriesTests }

procedure TChartSeriesTests.AddDeleteClearAndAppend;
var
  C: TPPGChart;
  S: TPPGChartSeries;
  I: Integer;
begin
  C := NewChart;
  S := C.Series.Add;
  CheckEquals(0, S.Add(5, 'A'));
  CheckEquals(1, S.Add(7));
  CheckEquals(2, S.AddXY(10, 3, 'C', clRed));
  CheckEquals(3, S.Count);
  CheckEquals(1, S.Points[1].X, 1E-12, 'X = Index');
  CheckEquals('A', S.Points[0].Text);
  CheckEquals(clRed, S.Points[2].Color);
  CheckEquals(clDefault, S.Points[0].Color);
  S.Y[1] := 8;
  CheckEquals(8, S.Y[1], 1E-12);
  S.Delete(0);
  CheckEquals(2, S.Count);
  CheckEquals(8, S.Y[0], 1E-12);
  S.Clear;
  CheckEquals(0, S.Count);
  for I := 1 to 10 do
    S.Append(I, 4);
  CheckEquals(4, S.Count, 'Lauffenster');
  CheckEquals(7, S.Y[0], 1E-12);
  CheckEquals(9, S.Points[3].X, 1E-12, 'X laeuft weiter');
  S.SetValues([1, 2, 3]);
  CheckEquals('1;2;3', S.ValuesText);
  CheckEquals(S.ClassName, S.DisplayName, 'DisplayName ohne Titel');
  S.Title := 'Umsatz';
  CheckEquals('Umsatz', S.DisplayName);
end;

procedure TChartSeriesTests.OutOfRangeRaises;
var
  C: TPPGChart;
  S: TPPGChartSeries;
  D: Double;
begin
  C := NewChart;
  S := C.Series.Add;
  S.SetValues([1, 2]);
  try
    D := S.Y[2];
    Fail('EPPGPropertyError erwartet ' + FloatToStr(D));
  except
    on EPPGPropertyError do;
  end;
  try
    S.Delete(5);
    Fail('EPPGPropertyError erwartet');
  except
    on EPPGPropertyError do;
  end;
  try
    S.LineWidth := 0;
    Fail('EPPGPropertyError erwartet');
  except
    on EPPGPropertyError do;
  end;
  CheckEquals(2, S.LineWidth);
  try
    S.ValuesText := '1;?';
    Fail('EPPGPropertyError erwartet');
  except
    on EPPGPropertyError do;
  end;
  CheckEquals(2, S.Count);
end;

procedure TChartSeriesTests.StreamingKeepsSeriesAxesAndLines;
var
  C, C2: TPPGChart;
  L: TPPGChartReferenceLine;
begin
  RegisterClass(TPPGChart);
  C := SampleChart;
  C.Title := 'Umsatz 2026';
  C.Series[0].Color := clGreen;
  C.Series[1].YAxis := casSecondary;
  C.Series[1].ShowMarkers := True;
  C.Series[1].ValueFormat := '0.0';
  C.Series[1].Visible := False;
  C.Stacking := cstStacked;
  C.LegendPosition := clpRight;
  C.ShowTooltips := False;
  C.YAxis.Title := 'Mio';
  C.YAxis.AutoMax := False;
  C.YAxis.Max := 50;
  C.YAxis.Format := '0';
  C.YAxis.ShowGrid := False;
  C.XAxis.ShowGrid := True;
  C.Y2Axis.Title := 'Prozent';
  L := C.ReferenceLines.Add;
  L.Value := 15.5;
  L.Caption := 'Ziel';
  L.Dashed := False;
  L.Axis := claY2;
  C2 := RoundTrip(C) as TPPGChart;
  try
    CheckEquals('Umsatz 2026', C2.Title);
    CheckEquals(2, C2.Series.Count);
    CheckEquals('12;14;13;17;19;21', C2.Series[0].ValuesText);
    CheckTrue(C2.Series[0].Kind = cskColumn);
    CheckEquals(clGreen, C2.Series[0].Color);
    CheckTrue(C2.Series[1].YAxis = casSecondary);
    CheckTrue(C2.Series[1].ShowMarkers);
    CheckEquals('0.0', C2.Series[1].ValueFormat);
    CheckFalse(C2.Series[1].Visible);
    CheckEquals('Jan,Feb,Mrz,Apr,Mai,Jun', C2.Categories.CommaText);
    CheckTrue(C2.Stacking = cstStacked);
    CheckTrue(C2.LegendPosition = clpRight);
    CheckFalse(C2.ShowTooltips);
    CheckEquals('Mio', C2.YAxis.Title);
    CheckFalse(C2.YAxis.AutoMax);
    CheckEquals(50, C2.YAxis.Max, 1E-12);
    CheckEquals('0', C2.YAxis.Format);
    CheckFalse(C2.YAxis.ShowGrid);
    CheckTrue(C2.XAxis.ShowGrid);
    CheckEquals('Prozent', C2.Y2Axis.Title);
    CheckEquals(1, C2.ReferenceLines.Count);
    CheckEquals(15.5, C2.ReferenceLines[0].Value, 1E-12);
    CheckEquals('Ziel', C2.ReferenceLines[0].Caption);
    CheckFalse(C2.ReferenceLines[0].Dashed);
    CheckTrue(C2.ReferenceLines[0].Axis = claY2);
  finally
    C2.Free;
  end;
end;

procedure TChartSeriesTests.VirtualModeAsksHost;
var
  C: TPPGChart;
  S: TPPGChartSeries;
  L: TPPGChartLayout;
begin
  C := NewChart;
  C.OnGetPoint := VirtualPoint;
  S := C.Series.Add;
  S.Add(99); // eigene Punkte werden im virtuellen Modus ignoriert
  S.VirtualCount := 1000;
  CheckEquals(1000, S.Count);
  CheckEquals(20, S.Points[10].Y, 1E-12);
  CheckEquals('V10', S.Points[10].Text);
  CheckEquals(10, S.Points[10].X, 1E-12, 'X = Index');
  L := C.Layout;
  CheckEquals(1000, L.CatCount);
  CheckFalse(IsStoredProp(S, 'ValuesText'), 'virtuell: keine Werte im DFM');
  S.VirtualCount := 0;
  CheckEquals(1, S.Count);
end;

procedure TChartSeriesTests.SeriesVisibilityAnimates;
var
  C: TPPGChart;
begin
  FForm.Show;
  try
    C := SampleChart;
    C.Animation.Enabled := False;
    C.Series[1].Visible := False;
    CheckEquals(0, C.Series[1].VisibleFactor, 1E-6, 'ohne Animation sofort');
    CheckFalse(C.Series[1].IsDrawn);
    C.Animation.Enabled := True;
    C.Series[1].Visible := True;
    if C.Animation.EffectiveEnabled then
    begin
      CheckTrue(C.Series[1].VisibleFactor < 1, 'blendet ein');
      CheckTrue(C.Series[1].IsDrawn, 'waehrend der Animation gezeichnet');
    end
    else
      Status('Systemanimationen aus');
  finally
    FForm.Hide;
  end;
end;

{ TChartLayoutTests }

procedure TChartLayoutTests.ModesFromSeries;
var
  C: TPPGChart;
  S: TPPGChartSeries;
begin
  C := NewChart;
  CheckTrue(C.Layout.Mode = cmEmpty, 'ohne Serien');
  S := C.Series.Add;
  CheckTrue(C.Layout.Mode = cmEmpty, 'ohne Punkte');
  S.SetValues([1, 2, 3]);
  CheckTrue(C.Layout.Mode = cmCartesian);
  S.Kind := cskBar;
  CheckTrue(C.Layout.Mode = cmHorizontal, 'nur Balken = quer');
  C.Series.Add.SetValues([4, 5, 6]);
  CheckTrue(C.Layout.Mode = cmCartesian, 'Balken + Linie = Saeulen');
  S.Kind := cskPie;
  CheckTrue(C.Layout.Mode = cmPie, 'erste Serie Kreis');
  CheckEquals(0, C.Layout.PieSeries);
  S.Visible := False;
  CheckTrue(C.Layout.Mode = cmCartesian, 'ausgeblendeter Kreis zaehlt nicht');
  S.Visible := True;
  S.Kind := cskDonut;
  CheckTrue(C.Layout.PieInner > 0, 'Ring mit Loch');
end;

procedure TChartLayoutTests.ColumnsIncludeZeroLinesDoNot;
var
  C: TPPGChart;
  S: TPPGChartSeries;
begin
  C := NewChart;
  S := C.Series.Add;
  S.SetValues([50, 65, 80]);
  S.Kind := cskLine;
  CheckTrue(C.Layout.YScale.Min > 0, 'Linie ohne Null: ' + FloatToStr(C.Layout.YScale.Min));
  S.Kind := cskColumn;
  CheckEquals(0, C.Layout.YScale.Min, 1E-12, 'Saeulen ab Null');
  CheckTrue(C.Layout.YScale.Max >= 80);
  S.Kind := cskArea;
  CheckEquals(0, C.Layout.YScale.Min, 1E-12, 'Flaeche ab Null');
end;

procedure TChartLayoutTests.StackedAndPercentScales;
var
  C: TPPGChart;
  S: TPPGChartSeries;
  P: TPoint;
  P1: TPoint;
begin
  C := NewChart;
  S := C.Series.Add;
  S.Kind := cskColumn;
  S.SetValues([1, 2]);
  S := C.Series.Add;
  S.Kind := cskColumn;
  S.SetValues([3, 4]);
  CheckTrue(C.Layout.YScale.Max < 6, 'gruppiert: Max nach Einzelwerten');
  C.Stacking := cstStacked;
  CheckTrue(C.Layout.YScale.Max >= 6, 'gestapelt: Summe 6');
  // Oberkante der zweiten Serie liegt ueber der ersten
  CheckTrue(C.PointPos(1, 1, P));
  CheckTrue(C.PointPos(0, 1, P1));
  CheckTrue(P.Y < P1.Y, 'gestapelt oben');
  CheckEquals(P.X, P1.X, 'gleiche Saeule');
  C.Stacking := cstPercent;
  CheckEquals(100, C.Layout.YScale.Max, 1E-9, '100 %');
  CheckTrue(C.PointPos(1, 0, P));
  CheckEquals(C.Layout.PlotR.Top, P.Y, 1, '100 % oben');
end;

procedure TChartLayoutTests.SecondaryAxis;
var
  C: TPPGChart;
  L: TPPGChartLayout;
  P, P2: TPoint;
begin
  C := SampleChart;
  CheckFalse(C.Layout.HasY2);
  C.Series[1].SetValues([0.1, 0.4, 0.2, 0.9, 0.5, 0.3]);
  C.Series[1].YAxis := casSecondary;
  L := C.Layout;
  CheckTrue(L.HasY2, 'zweite Achse');
  CheckTrue(L.Y2Scale.Max >= 0.9);
  CheckTrue(L.Y2Scale.Max <= 1.5, 'eigener Bereich');
  CheckTrue(L.YScale.Max >= 21);
  // 0,9 auf der zweiten Achse liegt weit oben, nicht an der Grundlinie
  CheckTrue(C.PointPos(1, 3, P));
  CheckTrue(C.PointPos(0, 3, P2));
  CheckTrue(P.Y < (L.PlotR.Top + L.PlotR.Bottom) div 2, 'oben');
  CheckTrue(L.PlotR.Right < C.ClientWidth - 20, 'Platz fuer die rechte Beschriftung');
end;

procedure TChartLayoutTests.FixedAxisBounds;
var
  C: TPPGChart;
  L: TPPGChartLayout;
begin
  C := SampleChart;
  C.YAxis.AutoMin := False;
  C.YAxis.Min := 10;
  C.YAxis.AutoMax := False;
  C.YAxis.Max := 30;
  L := C.Layout;
  CheckEquals(10, L.YScale.Min, 1E-12);
  CheckEquals(30, L.YScale.Max, 1E-12);
  C.YAxis.AutoMin := True;
  L := C.Layout;
  CheckEquals(30, L.YScale.Max, 1E-12, 'nur Max fest');
  CheckEquals(0, L.YScale.Min, 1E-12, 'Saeulen ab Null');
end;

procedure TChartLayoutTests.NumericAndDateAxes;
var
  C: TPPGChart;
  S: TPPGChartSeries;
  L: TPPGChartLayout;
  I: Integer;
  P0, P1: TPoint;
begin
  C := NewChart;
  C.XAxis.Kind := cxkNumeric;
  S := C.Series.Add;
  S.AddXY(0.5, 1);
  S.AddXY(2.5, 3);
  S.AddXY(10, 2);
  L := C.Layout;
  CheckTrue(L.XScale.Min <= 0.5);
  CheckTrue(L.XScale.Max >= 10);
  CheckTrue(C.PointPos(0, 0, P0));
  CheckTrue(C.PointPos(0, 2, P1));
  CheckTrue(P1.X - P0.X > (L.PlotR.Right - L.PlotR.Left) div 2, 'X proportional');
  CheckEquals(FormatFloat('#,##0.##', 2.5), C.XLabel(0, 1));
  // Datum: eine Woche stundenweise
  C.XAxis.Kind := cxkDateTime;
  S.Clear;
  for I := 0 to 7 * 24 do
    S.AddXY(EncodeDate(2026, 10, 1) + I / 24, I mod 24);
  L := C.Layout;
  CheckTrue(L.DateScale.DateUnit in [duDay, duWeek], 'Tage');
  CheckTrue(L.DateScale.Min <= EncodeDate(2026, 10, 1));
  CheckEquals(DateToStr(EncodeDate(2026, 10, 2)), C.XLabel(0, 24));
  CheckEquals(DateTimeToStr(EncodeDate(2026, 10, 2) + 0.5), C.XLabel(0, 36));
end;

procedure TChartLayoutTests.LegendPositions;
var
  C: TPPGChart;
  L: TPPGChartLayout;
begin
  C := SampleChart;
  L := C.Layout;
  CheckEquals(2, Length(L.Legend));
  CheckTrue(L.LegendR.Top > L.PlotR.Bottom, 'unten');
  CheckTrue(L.Legend[0].R.Right <= L.Legend[1].R.Left, 'nebeneinander');
  C.LegendPosition := clpTop;
  L := C.Layout;
  CheckTrue(L.LegendR.Bottom < L.PlotR.Top, 'oben');
  C.LegendPosition := clpRight;
  L := C.Layout;
  CheckTrue(L.LegendR.Left > L.PlotR.Right, 'rechts');
  CheckTrue(L.Legend[0].R.Bottom <= L.Legend[1].R.Top, 'untereinander');
  C.LegendPosition := clpNone;
  CheckEquals(0, Length(C.Layout.Legend));
  // Titel nimmt Platz oben weg
  C.LegendPosition := clpBottom;
  L := C.Layout;
  C.Title := 'Titel';
  CheckTrue(C.Layout.PlotR.Top > L.PlotR.Top, 'Titel ueber dem Diagramm');
end;

procedure TChartLayoutTests.RightToLeftMirrorsAxisAndLegend;
var
  C: TPPGChart;
  L, LR: TPPGChartLayout;
  P0, P1: TPoint;
begin
  C := SampleChart;
  L := C.Layout;
  C.BiDiMode := bdRightToLeft;
  LR := C.Layout;
  CheckTrue(LR.PlotR.Right < L.PlotR.Right, 'Y-Achse rechts');
  CheckTrue(LR.Legend[0].R.Left > LR.Legend[1].R.Left, 'Legende von rechts');
  // X-Richtung bleibt (wie Excel)
  CheckTrue(C.PointPos(0, 0, P0));
  CheckTrue(C.PointPos(0, 5, P1));
  CheckTrue(P0.X < P1.X, 'Januar links');
end;

{ TChartInteractionTests }

procedure TChartInteractionTests.HitTestColumnsAndLines;
var
  C: TPPGChart;
  P: TPoint;
  H: TPPGChartHit;
begin
  C := SampleChart;
  CheckTrue(C.PointPos(0, 2, P), 'Saeule');
  H := C.HitTest(P.X, P.Y + 5);
  CheckTrue(H.Kind = chkPlot);
  CheckEquals(2, H.Index);
  CheckEquals(0, H.Series, 'Saeule unter der Maus');
  CheckTrue(C.PointPos(1, 4, P), 'Linienpunkt');
  H := C.HitTest(P.X, P.Y);
  CheckEquals(4, H.Index);
  CheckTrue(H.Series in [0, 1]);
  H := C.HitTest(2, 2);
  CheckTrue(H.Kind = chkNone, 'ausserhalb');
end;

procedure TChartInteractionTests.HoverShowsTooltipBand;
var
  C: TPPGChart;
  P: TPoint;
  B0, B1: TBitmap;
  X, Y, Diff: Integer;
begin
  FForm.Show;
  try
    C := SampleChart;
    B0 := RenderToBitmap(C);
    try
      CheckTrue(C.PointPos(1, 3, P));
      C.Perform(CM_MOUSEENTER, 0, 0);
      C.Perform(WM_MOUSEMOVE, 0, MouseLParam(P.X, P.Y));
      CheckEquals(3, C.Hot.Index);
      B1 := RenderToBitmap(C);
      try
        Diff := 0;
        for Y := 0 to B0.Height - 1 do
          for X := 0 to B0.Width - 1 do
            if B0.Canvas.Pixels[X, Y] <> B1.Canvas.Pixels[X, Y] then
              Inc(Diff);
        CheckTrue(Diff > 500, Format('Tooltip/Band sichtbar (%d Pixel)', [Diff]));
      finally
        B1.Free;
      end;
      C.ShowTooltips := False;
      C.Perform(CM_MOUSELEAVE, 0, 0);
      CheckTrue(C.Hot.Kind = chkNone, 'Verlassen loescht Hover');
    finally
      B0.Free;
    end;
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TChartInteractionTests.LegendClickTogglesSeries;
var
  C: TPPGChart;
  L: TPPGChartLayout;
  P: TPoint;
  H: TPPGChartHit;
begin
  C := SampleChart;
  L := C.Layout;
  P := Center(L.Legend[1].R);
  H := C.HitTest(P.X, P.Y);
  CheckTrue(H.Kind = chkLegend);
  CheckEquals(1, H.Series);
  C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
  C.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y));
  CheckFalse(C.Series[1].Visible, 'ausgeblendet');
  CheckEquals(2, Length(C.Layout.Legend), 'bleibt in der Legende');
  C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
  C.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y));
  CheckTrue(C.Series[1].Visible, 'wieder da');
  C.LegendToggle := False;
  C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
  C.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y));
  CheckTrue(C.Series[1].Visible, 'LegendToggle aus');
  CheckEquals(0, FLog.Count, 'Legende ist kein Punkt-Klick');
end;

procedure TChartInteractionTests.PointClickByMouseAndKeyboard;
var
  C: TPPGChart;
  P: TPoint;
  K: Word;
begin
  FForm.Show;
  try
    C := SampleChart;
    CheckTrue(C.PointPos(0, 4, P));
    C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y + 3));
    C.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y + 3));
    CheckEquals('point:0:4', FLog.CommaText);
    CheckEquals(4, C.FocusIndex);
    K := VK_RETURN;
    TWinAccess(C).KeyDown(K, []);
    CheckEquals('point:0:4,point:0:4', FLog.CommaText, 'Enter');
  finally
    FForm.Hide;
  end;
end;

procedure TChartInteractionTests.KeyboardWalksPointsAndSeries;
var
  C: TPPGChart;
  K: Word;
begin
  FForm.Show;
  try
    C := SampleChart;
    C.SetFocus;
    K := VK_RIGHT;
    TWinAccess(C).KeyDown(K, []);
    CheckEquals(0, C.FocusSeries);
    CheckEquals(0, C.FocusIndex, 'erster Punkt');
    K := VK_RIGHT;
    TWinAccess(C).KeyDown(K, []);
    CheckEquals(1, C.FocusIndex);
    K := VK_END;
    TWinAccess(C).KeyDown(K, []);
    CheckEquals(5, C.FocusIndex);
    K := VK_RIGHT;
    TWinAccess(C).KeyDown(K, []);
    CheckEquals(5, C.FocusIndex, 'bleibt am Ende');
    K := VK_DOWN;
    TWinAccess(C).KeyDown(K, []);
    CheckEquals(1, C.FocusSeries, 'naechste Serie');
    CheckEquals(5, C.FocusIndex, 'gleicher Punkt');
    K := VK_DOWN;
    TWinAccess(C).KeyDown(K, []);
    CheckEquals(1, C.FocusSeries, 'letzte Serie bleibt');
    K := VK_UP;
    TWinAccess(C).KeyDown(K, []);
    CheckEquals(0, C.FocusSeries);
    K := VK_HOME;
    TWinAccess(C).KeyDown(K, []);
    CheckEquals(0, C.FocusIndex);
    K := VK_ESCAPE;
    TWinAccess(C).KeyDown(K, []);
    CheckEquals(-1, C.FocusIndex, 'Esc');
    CheckEquals(DLGC_WANTARROWS, C.Perform(WM_GETDLGCODE, 0, 0) and DLGC_WANTARROWS);
    // Ausgeblendete Serie wird uebersprungen
    C.Series[1].Visible := False;
    C.FocusPoint(0, 2);
    K := VK_DOWN;
    TWinAccess(C).KeyDown(K, []);
    CheckEquals(0, C.FocusSeries, 'ausgeblendete Serie uebersprungen');
  finally
    FForm.Hide;
  end;
end;

procedure TChartInteractionTests.PieHitTestAndLegend;
var
  C: TPPGChart;
  S: TPPGChartSeries;
  P: TPoint;
  H: TPPGChartHit;
  L: TPPGChartLayout;
  I: Integer;
  K: Word;
begin
  FForm.Show;
  try
    C := NewChart;
    S := C.Series.Add;
    S.Kind := cskDonut;
    S.Add(1, 'A');
    S.Add(1, 'B');
    S.Add(2, 'C');
    L := C.Layout;
    CheckEquals(3, Length(L.Legend), 'Legende = Segmente');
    for I := 0 to 2 do
    begin
      CheckTrue(C.PointPos(0, I, P));
      H := C.HitTest(P.X, P.Y);
      CheckTrue(H.Kind = chkPlot);
      CheckEquals(I, H.Index, 'Segment ' + IntToStr(I));
    end;
    // Loch des Rings: kein Treffer
    H := C.HitTest(L.PieCenter.X, L.PieCenter.Y);
    CheckTrue(H.Kind = chkNone, 'Loch');
    CheckEquals('C', C.XLabel(0, 2));
    // Legende blendet beim Kreis nichts aus
    P := Center(L.Legend[0].R);
    C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
    C.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y));
    CheckTrue(S.Visible);
    // Segmentfarben aus der Palette, eigene Punktfarbe gewinnt
    CheckNotEquals(C.SliceColor(0, 0), C.SliceColor(0, 1));
    S.Add(3, 'D', clFuchsia);
    CheckEquals(ColorToRGB(clFuchsia), C.SliceColor(0, 3));
    C.SetFocus;
    K := VK_RIGHT;
    TWinAccess(C).KeyDown(K, []);
    CheckEquals(0, C.FocusSeries, 'Tastatur im Kreis');
    RenderToBitmap(C).Free;
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TChartInteractionTests.HorizontalBarsHitTest;
var
  C: TPPGChart;
  S: TPPGChartSeries;
  P0, P1: TPoint;
  H: TPPGChartHit;
begin
  C := NewChart;
  C.Categories.CommaText := 'Nord,Sued,West';
  S := C.Series.Add;
  S.Kind := cskBar;
  S.SetValues([5, 9, 3]);
  CheckTrue(C.Layout.Mode = cmHorizontal);
  CheckTrue(C.PointPos(0, 0, P0));
  CheckTrue(C.PointPos(0, 1, P1));
  CheckTrue(P1.Y > P0.Y, 'Kategorien von oben');
  CheckTrue(P1.X > P0.X, '9 laenger als 5');
  H := C.HitTest(P1.X - 5, P1.Y);
  CheckEquals(1, H.Index);
  CheckEquals(0, H.Series);
end;

{ TChartBehaviourTests }

procedure TChartBehaviourTests.IntroAndChangeAnimation;
var
  C: TPPGChart;
begin
  FForm.Show;
  try
    C := NewChart;
    C.Animation.Enabled := True;
    if not C.Animation.EffectiveEnabled then
    begin
      Status('Systemanimationen aus - Animationen nicht pruefbar');
      Exit;
    end;
    CheckEquals(1, C.IntroProgress, 1E-6, 'ohne Daten kein Aufbau');
    C.Series.Add.SetValues([1, 2, 3]);
    CheckTrue(C.IntroProgress < 1, 'Aufbau mit den ersten Daten');
    // Gleiche Anzahl Punkte: weicher Uebergang
    C.Series[0].SetValues([3, 2, 1]);
    CheckTrue(C.ChangeProgress < 1, 'Uebergang');
    // Andere Anzahl: kein Uebergang
    C.Series[0].SetValues([1, 2, 3, 4]);
    CheckEquals(1, C.ChangeProgress, 1E-6, 'Sprung bei neuer Anzahl');
    // Ohne Animation: alles sofort
    C.Animation.Enabled := False;
    C.Series[0].SetValues([4, 3, 2, 1]);
    CheckEquals(1, C.ChangeProgress, 1E-6);
    // Regressionstest: Abschalten waehrend des Aufbaus liess das Diagramm
    // im Zwischenstand (Daten auf der Nulllinie) stehen
    C.Animation.Enabled := True;
    C.Series[0].SetValues([1, 2, 3, 4]);
    C.Series[0].Visible := False;
    C.Animation.Enabled := False;
    CheckEquals(1, C.IntroProgress, 1E-6, 'Aufbau beendet');
    CheckEquals(1, C.ChangeProgress, 1E-6, 'Uebergang beendet');
    CheckEquals(0, C.Series[0].VisibleFactor, 1E-6, 'Ausblenden beendet');
  finally
    FForm.Hide;
  end;
end;

procedure TChartBehaviourTests.DataUpdateBatches;
var
  C: TPPGChart;
  I: Integer;
begin
  FForm.Show;
  try
    C := SampleChart;
    C.HandleNeeded; // CreateWnd -> Aufbau erledigt, danach gibt es Uebergaenge
    C.Animation.Enabled := True;
    if not C.Animation.EffectiveEnabled then
    begin
      Status('Systemanimationen aus');
      Exit;
    end;
    C.BeginDataUpdate;
    try
      for I := 0 to 5 do
        C.Series[0].Y[I] := I * 3;
      CheckEquals(1, C.ChangeProgress, 1E-6, 'noch kein Uebergang waehrend des Updates');
    finally
      C.EndDataUpdate;
    end;
    CheckTrue(C.ChangeProgress < 1, 'ein Uebergang nach EndDataUpdate');
    // Der Uebergang startet bei den alten Werten
    CheckEquals(12, C.Series[0].OldY[0], 1E-9);
    CheckEquals(21, C.Series[0].OldY[5], 1E-9);
  finally
    FForm.Hide;
  end;
end;

procedure TChartBehaviourTests.ManyPointsAreFast;
var
  C: TPPGChart;
  S: TPPGChartSeries;
  V: TArray<Double>;
  I: Integer;
  T0, T1: Cardinal;
  B: TBitmap;
begin
  FForm.Show;
  try
    C := NewChart;
    SetLength(V, 100000);
    for I := 0 to High(V) do
      V[I] := Sin(I / 1000) * 100 + Random(10);
    S := C.Series.Add;
    S.SetValues(V);
    RenderToBitmap(C).Free; // Aufwaermen
    T0 := GetTickCount;
    B := RenderToBitmap(C);
    T1 := GetTickCount - T0;
    try
      Status(Format('100 000 Punkte: %d ms', [T1]));
      CheckTrue(T1 < 500, Format('zu langsam: %d ms', [T1]));
      CheckTrue(ContentPixels(B, FForm.Color) > 1000, 'gezeichnet');
    finally
      B.Free;
    end;
    // Live: Werte anhaengen mit Lauffenster
    T0 := GetTickCount;
    for I := 1 to 200 do
      S.Append(I, 100000);
    CheckTrue(GetTickCount - T0 < 2000, Format('Append: %d ms', [GetTickCount - T0]));
  finally
    FForm.Hide;
  end;
end;

procedure TChartBehaviourTests.ExportBitmapPngClipboard;
var
  C: TPPGChart;
  B, Back: TBitmap;
  Png: TPngImage;
  F: string;
  M: TFileStream;
  Sig: array[0..7] of Byte;
  Gdi: Boolean;
  X, Y, Diff: Integer;
begin
  C := SampleChart;
  C.Title := 'Export';
  F := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) + 'ppg_chart_test.png';
  // PNG kommt aus dem GDI+-Encoder - auch dann, wenn das Zeichnen per GDI laeuft
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    B := TBitmap.Create;
    Png := TPngImage.Create;
    Back := TBitmap.Create;
    try
      C.SaveToBitmap(B);
      CheckEquals(C.ClientWidth, B.Width);
      CheckEquals(C.ClientHeight, B.Height);
      CheckTrue(ContentPixels(B, B.Canvas.Pixels[0, 0]) > 1000, 'Inhalt');
      C.SaveToPng(F);
      M := TFileStream.Create(F, fmOpenRead);
      try
        CheckTrue(M.Size > 1000, 'PNG geschrieben');
        M.ReadBuffer(Sig, SizeOf(Sig));
        CheckTrue((Sig[0] = $89) and (Sig[1] = Ord('P')) and (Sig[2] = Ord('N')) and
          (Sig[3] = Ord('G')), 'PNG-Signatur');
      finally
        M.Free;
      end;
      // Zurueckgelesen: gleiche Groesse, gleiche Pixel wie SaveToBitmap
      Png.LoadFromFile(F);
      Back.Assign(Png);
      Back.PixelFormat := pf24bit;
      CheckEquals(B.Width, Back.Width, 'Breite');
      CheckEquals(B.Height, Back.Height, 'Hoehe');
      Diff := 0;
      for Y := 0 to B.Height - 1 do
        for X := 0 to B.Width - 1 do
          if B.Canvas.Pixels[X, Y] <> Back.Canvas.Pixels[X, Y] then
            Inc(Diff);
      CheckEquals(0, Diff, Format('abweichende Pixel (GDI=%d)', [Ord(Gdi)]));
    finally
      Back.Free;
      Png.Free;
      B.Free;
      DeleteFile(F);
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
  try
    C.CopyToClipboard;
    CheckTrue(Clipboard.HasFormat(CF_BITMAP), 'Zwischenablage');
  except
    on E: Exception do
      Status('Zwischenablage nicht verfuegbar: ' + E.Message);
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TChartBehaviourTests.ExportShowsFinalState;
var
  C: TPPGChart;
  B: TBitmap;
begin
  // Regressionstest: SaveToPng waehrend des Aufbaus zeigte einen halben Ring
  FForm.Show;
  try
    C := NewChart;
    C.Animation.Enabled := True;
    C.Series.Add.SetValues([1, 2, 3]);
    C.Series.Add.SetValues([3, 2, 1]);
    C.Series[1].Visible := False;
    B := TBitmap.Create;
    try
      C.SaveToBitmap(B);
    finally
      B.Free;
    end;
    CheckEquals(1, C.IntroProgress, 1E-6, 'Aufbau beendet');
    CheckEquals(1, C.ChangeProgress, 1E-6);
    CheckEquals(0, C.Series[1].VisibleFactor, 1E-6, 'Ausblenden beendet');
  finally
    FForm.Hide;
  end;
end;

procedure TChartBehaviourTests.AccessibilityChildren;
var
  C: TPPGChart;
  A: IPPGAccessibleChildren;
  R: TRect;
  P: TPoint;
begin
  FForm.Show;
  try
    C := SampleChart;
    C.Title := 'Umsatz';
    CheckTrue(Supports(C, IPPGAccessibleChildren, A));
    CheckEquals(ROLE_SYSTEM_CHART, TChartAccess(C).AccRole);
    CheckEquals('Umsatz', TChartAccess(C).AccName);
    CheckEquals(12, A.AccChildCount);
    CheckEquals(Format(PPGStr(@SPPGChartPointName), ['Plan', 'Jan', '12']), A.AccChildName(1));
    CheckEquals(Format(PPGStr(@SPPGChartPointName), ['Ist', 'Feb', '15']), A.AccChildName(8));
    CheckEquals(ROLE_SYSTEM_LISTITEM, A.AccChildRole(1));
    R := A.AccChildRect(8);
    CheckFalse(IsRectEmpty(R), 'Lage');
    CheckTrue(C.PointPos(1, 1, P));
    CheckTrue(PtInRect(R, P));
    CheckEquals('', A.AccChildName(13), 'ausserhalb');
    C.SetFocus;
    C.FocusPoint(1, 2);
    CheckEquals(9, A.AccFocusedChild);
    CheckTrue(A.AccChildState(9) and STATE_SYSTEM_FOCUSED <> 0);
    C.Series[0].Visible := False;
    CheckEquals(6, A.AccChildCount, 'ausgeblendete Serie ohne Kinder');
    CheckEquals(Format(PPGStr(@SPPGChartPointName), ['Ist', 'Jan', '11']), A.AccChildName(1));
    CheckTrue(Pos(Format(PPGStr(@SPPGChartSeriesHidden), ['Plan']), TChartAccess(C).AccValue) > 0);
  finally
    FForm.Hide;
  end;
end;

procedure TChartBehaviourTests.EmptyChartShowsNoData;
var
  C: TPPGChart;
  B: TBitmap;
begin
  FForm.Show;
  try
    C := NewChart;
    CheckEquals(PPGStr(@SPPGChartNoData), TChartAccess(C).AccValue);
    B := RenderToBitmap(C);
    try
      CheckTrue(ContentPixels(B, B.Canvas.Pixels[0, 0]) > 20, 'Hinweis "Keine Daten"');
    finally
      B.Free;
    end;
    C.Series.Add; // Serie ohne Punkte
    RenderToBitmap(C).Free;
    C.HitTest(100, 100);
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TChartBehaviourTests.FreeWhileAnimating;
var
  C: TPPGChart;
begin
  FForm.Show;
  try
    C := SampleChart;
    C.Animation.Enabled := True;
    C.Series[0].Visible := False;
    C.Series[1].SetValues([1, 2, 3, 4, 5, 6]);
    C.Free;
    Application.ProcessMessages;
    Sleep(50);
    Application.ProcessMessages;
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
  CheckEquals(0, FAppExceptions);
end;

{ TPhase10PaintTests }

procedure TPhase10PaintTests.PaintAllPresetsModesAndKinds;
var
  Names: TStringList;
  P, V: Integer;
  Dark, Gdi: Boolean;
  C: TPPGChart;
  S: TPPGChartSeries;
  G: TPPGGauge;
  K: TPPGKpiTile;
  Sp: TPPGSparkline;
  L: TPPGChartReferenceLine;
  I: Integer;
begin
  Names := TStringList.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    FForm.Show;
    try
      for P := 0 to Names.Count - 1 do
        for Dark := False to True do
          for Gdi := False to True do
          begin
            if Dark then
              TPPGTheme.Mode := tmDark
            else
              TPPGTheme.Mode := tmLight;
            TPPGRendererRegistry.ForceGdiFallback := Gdi;
            for V := 0 to 11 do
            begin
              C := SampleChart;
              C.Preset := Names[P];
              C.Title := 'Variante ' + IntToStr(V);
              case V of
                1: C.Stacking := cstStacked;
                2: C.Stacking := cstPercent;
                3:
                  begin
                    C.Series[0].Kind := cskArea;
                    C.Series[1].Kind := cskStepLine;
                  end;
                4:
                  begin
                    C.Series[0].Kind := cskBar;
                    C.Series[1].Kind := cskBar;
                  end;
                5: C.Series[0].Kind := cskPie;
                6: C.Series[0].Kind := cskDonut;
                7:
                  begin
                    C.XAxis.Kind := cxkNumeric;
                    C.XAxis.Title := 'X';
                    C.YAxis.Title := 'Y';
                  end;
                8:
                  begin
                    C.XAxis.Kind := cxkDateTime;
                    for I := 0 to 1 do
                    begin
                      S := C.Series[I];
                      S.Clear;
                      S.AddXY(EncodeDate(2026, 1, 1), 3);
                      S.AddXY(EncodeDate(2026, 6, 1), 5);
                      S.AddXY(EncodeDate(2026, 12, 1), 4);
                    end;
                  end;
                9:
                  begin
                    C.Series[1].YAxis := casSecondary;
                    C.Y2Axis.Title := 'Quote';
                    L := C.ReferenceLines.Add;
                    L.Value := 15;
                    L.Caption := 'Ziel';
                    L := C.ReferenceLines.Add;
                    L.Value := 0.5;
                    L.Axis := claY2;
                  end;
                10:
                  begin
                    C.LegendPosition := clpRight;
                    C.BiDiMode := bdRightToLeft;
                    C.Series[1].ShowMarkers := True;
                  end;
                11:
                  begin
                    C.Enabled := False;
                    C.Series.Add.SetValues([-3, 4, -2, 6, 1, 0]);
                  end;
              end;
              C.Perform(CM_MOUSEENTER, 0, 0);
              C.Perform(WM_MOUSEMOVE, 0, MouseLParam(C.Width div 2, C.Height div 2));
              RenderToBitmap(C).Free;
              C.Free;
            end;
            G := TPPGGauge.Create(FForm);
            G.Parent := FForm;
            G.Preset := Names[P];
            G.Value := 70;
            G.Caption := 'Last';
            G.Ranges.Add.EndValue := 50;
            G.ShowTarget := True;
            RenderToBitmap(G).Free;
            G.StartAngle := -90;
            G.SweepAngle := 180;
            RenderToBitmap(G).Free;
            G.Free;
            K := TPPGKpiTile.Create(FForm);
            K.Parent := FForm;
            K.Preset := Names[P];
            K.Title := 'Umsatz';
            K.Value := 12480;
            K.Change := -2;
            K.SparklineText := '1;3;2;4';
            RenderToBitmap(K).Free;
            K.Free;
            Sp := TPPGSparkline.Create(FForm);
            Sp.Parent := FForm;
            Sp.Preset := Names[P];
            Sp.ValuesText := '1;-3;2;4';
            Sp.ShowReference := True;
            Sp.ReferenceValue := 1;
            RenderToBitmap(Sp).Free;
            Sp.Free;
          end;
    finally
      FForm.Hide;
      TPPGTheme.Mode := tmLight;
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  finally
    Names.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPhase10PaintTests.NoHandleOrMemoryLeaks;

  procedure Cycle;
  var
    I: Integer;
    C: TPPGChart;
    G: TPPGGauge;
    K: TPPGKpiTile;
    Sp: TPPGSparkline;
    B: TBitmap;
  begin
    for I := 1 to 3 do
    begin
      C := SampleChart;
      C.Title := 'T';
      C.Perform(WM_MOUSEMOVE, 0, MouseLParam(200, 120));
      RenderToBitmap(C).Free;
      C.Series[0].Kind := cskDonut;
      RenderToBitmap(C).Free;
      B := TBitmap.Create;
      C.SaveToBitmap(B);
      B.Free;
      C.Free;
      G := TPPGGauge.Create(FForm);
      G.Parent := FForm;
      G.Ranges.Add.EndValue := 40;
      G.Value := 50;
      RenderToBitmap(G).Free;
      G.Free;
      K := TPPGKpiTile.Create(FForm);
      K.Parent := FForm;
      K.SparklineText := '1;2;3';
      RenderToBitmap(K).Free;
      K.Free;
      Sp := TPPGSparkline.Create(FForm);
      Sp.Parent := FForm;
      Sp.ValuesText := '1;2;3';
      RenderToBitmap(Sp).Free;
      Sp.Free;
    end;
  end;

var
  Gdi0, User0: Cardinal;
  M0, M1: NativeUInt;
begin
  FForm.Show;
  try
    Cycle;
    Gdi0 := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
    User0 := GetGuiResources(GetCurrentProcess, GR_USEROBJECTS);
    M0 := AllocatedBytes;
    Cycle;
    Cycle;
    M1 := AllocatedBytes;
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS) <= Gdi0 + 2, 'GDI-Handles wachsen');
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_USEROBJECTS) <= User0 + 2, 'USER-Handles wachsen');
    CheckTrue(M1 <= M0 + 4096, Format('Speicher waechst: %d -> %d', [M0, M1]));
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterClasses([TPPGChart, TPPGGauge, TPPGKpiTile, TPPGSparkline]);
  RegisterTest('Phase10d', TChartSeriesTests.Suite);
  RegisterTest('Phase10d', TChartLayoutTests.Suite);
  RegisterTest('Phase10d', TChartInteractionTests.Suite);
  RegisterTest('Phase10d', TChartBehaviourTests.Suite);
  RegisterTest('Phase10d', TPhase10PaintTests.Suite);

end.
