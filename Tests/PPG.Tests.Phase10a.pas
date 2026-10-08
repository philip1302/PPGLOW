unit PPG.Tests.Phase10a;

{ Tests fuer Phase 10a: Achsen (PPG.Chart.Scale), Serienpalette
  (PPG.Chart.Palette), freie Formen (IPPGShapeCanvas, PPG.Render.Shapes) und
  den Diagramm-Renderer (IPPGChartRenderer). }

interface

uses
  TestFramework, Winapi.Windows, System.Classes, System.SysUtils, System.Types,
  System.DateUtils, Vcl.Graphics,
  PPG.Types, PPG.Tokens, PPG.Render.Intf, PPG.Render.Registry, PPG.Render.Shapes,
  PPG.Chart.Scale, PPG.Chart.Palette, PPG.Tests.Controls;

type
  TChartScaleTests = class(TTestCase)
  published
    procedure NiceScaleBasics;
    procedure NiceScaleEdgeCases;
    procedure TicksWithoutRoundingResidue;
    procedure FixedScaleKeepsBounds;
    procedure DateScaleMonthsAndYearChange;
    procedure DateScaleWeeksStartMonday;
    procedure StripYearFromDateFormat;
    procedure DateScaleOutsideYearRange;
  end;

  TChartPaletteTests = class(TTestCase)
  published
    procedure PaletteContrastAllPresets;
    procedure PaletteWrapsAndIsDistinct;
  end;

  TChartShapeTests = class(TControlTestCase)
  private
    function NewBitmap(W, H: Integer): TBitmap;
  published
    procedure FillPolygonGdiPlusAndGdi;
    procedure FillPolygonWithAlpha;
    procedure DashedLineHasGaps;
    procedure ArcSegmentPolygons;
    procedure ChartRendererForEveryPreset;
    procedure ClassicBarIsGlossy;
  end;

implementation

uses
  System.Math, PPG.Consts, PPG.Presets;

function Invariant: TFormatSettings;
begin
  Result := FormatSettings;
  Result.DecimalSeparator := '.';
  Result.ThousandSeparator := ',';
end;

{ TChartScaleTests }

procedure TChartScaleTests.NiceScaleBasics;
var
  S: TPPGAxisScale;
begin
  S := PPGNiceScale(0, 97, 6, True);
  CheckEquals(0, S.Min, 1E-9);
  CheckEquals(100, S.Max, 1E-9);
  CheckEquals(20, S.Step, 1E-9);
  CheckEquals(0, S.Decimals);
  CheckEquals(6, PPGScaleTickCount(S));
  CheckEquals(60, PPGScaleTick(S, 3), 1E-9);
  // Ohne Null: Bereich eng um die Daten
  S := PPGNiceScale(52, 81, 5, False);
  CheckTrue(S.Min <= 52, 'Min');
  CheckTrue(S.Min >= 40, 'Min zu klein: ' + FloatToStr(S.Min));
  CheckTrue(S.Max >= 81, 'Max');
  CheckTrue(S.Max <= 90, 'Max zu gross: ' + FloatToStr(S.Max));
end;

procedure TChartScaleTests.NiceScaleEdgeCases;
var
  S: TPPGAxisScale;
begin
  // Alle Werte gleich
  S := PPGNiceScale(5, 5, 5, False);
  CheckTrue((S.Min < 5) and (S.Max > 5), 'gleich: Bereich um den Wert');
  // Nur Null
  S := PPGNiceScale(0, 0, 5, True);
  CheckEquals(0, S.Min, 1E-9);
  CheckTrue(S.Max > 0, 'nur Null');
  // Nur negativ mit Null
  S := PPGNiceScale(-37, -3, 5, True);
  CheckEquals(0, S.Max, 1E-9);
  CheckTrue(S.Min <= -37, 'negativ');
  // Kleine Werte: Nachkommastellen
  S := PPGNiceScale(0.1, 0.7, 6, False);
  CheckTrue(S.Decimals >= 1, 'Nachkommastellen');
  CheckTrue(S.Step < 0.5, 'Schritt');
  // Sehr gross
  S := PPGNiceScale(0, 4.2E9, 5, True);
  CheckEquals(1E9, S.Step, 1);
  CheckEquals(5E9, S.Max, 1);
  // Ungueltig (NaN) -> Ersatzbereich statt Exception
  S := PPGNiceScale(NaN, 3, 5, False);
  CheckTrue(S.Max > S.Min, 'NaN');
  // Vertauschte Grenzen
  S := PPGNiceScale(10, 2, 5, False);
  CheckTrue((S.Min <= 2) and (S.Max >= 10), 'vertauscht');
end;

procedure TChartScaleTests.TicksWithoutRoundingResidue;
var
  S: TPPGAxisScale;
  I: Integer;
begin
  S := PPGNiceScale(0, 1, 11, False);
  CheckEquals(0.1, S.Step, 1E-12);
  CheckEquals('0.3', FloatToStr(PPGScaleTick(S, 3), Invariant));
  CheckEquals('0.7', FloatToStr(PPGScaleTick(S, 7), Invariant));
  for I := 0 to PPGScaleTickCount(S) - 1 do
    CheckTrue(Length(FloatToStr(PPGScaleTick(S, I), Invariant)) <= 3,
      'Rest: ' + FloatToStr(PPGScaleTick(S, I), Invariant));
  CheckEquals('1,000.5', PPGFormatAxisValue(1000.5, 1, '', Invariant));
  CheckEquals('12.50', PPGFormatAxisValue(12.5, 1, '0.00', Invariant));
  // Negative Null wird zu 0
  S := PPGNiceScale(-1, 1, 5, False);
  for I := 0 to PPGScaleTickCount(S) - 1 do
    CheckNotEquals('-0', FloatToStr(PPGScaleTick(S, I), Invariant));
end;

procedure TChartScaleTests.FixedScaleKeepsBounds;
var
  S: TPPGAxisScale;
begin
  S := PPGFixedScale(0, 7, 5);
  CheckEquals(0, S.Min, 1E-9);
  CheckEquals(7, S.Max, 1E-9);
  CheckEquals(2, S.Step, 1E-9);
  CheckEquals(4, PPGScaleTickCount(S)); // 0, 2, 4, 6
  // Ungueltige feste Grenzen -> automatisch
  S := PPGFixedScale(5, 5, 5);
  CheckTrue(S.Max > S.Min);
end;

procedure TChartScaleTests.DateScaleMonthsAndYearChange;
var
  S: TPPGDateScale;
  T: TArray<TDateTime>;
  FS: TFormatSettings;
begin
  S := PPGNiceDateScale(EncodeDate(2026, 1, 1), EncodeDate(2026, 12, 31), 6);
  CheckTrue(S.DateUnit = duMonth, 'Monate');
  CheckEquals(3, S.Count);
  CheckEquals(EncodeDate(2026, 1, 1), S.Min, 1E-9);
  CheckEquals(EncodeDate(2027, 1, 1), S.Max, 1E-9);
  T := PPGDateTicks(S);
  CheckEquals(5, Length(T));
  CheckEquals(EncodeDate(2026, 7, 1), T[2], 1E-9);
  // Ueber den Jahreswechsel in Tagen
  S := PPGNiceDateScale(EncodeDate(2025, 12, 30), EncodeDate(2026, 1, 3), 6);
  CheckTrue(S.DateUnit = duDay, 'Tage');
  T := PPGDateTicks(S);
  CheckEquals(5, Length(T));
  FS := FormatSettings;
  FS.ShortDateFormat := 'dd.MM.yyyy';
  FS.DateSeparator := '.';
  // Jahre verschieden -> mit Jahr
  CheckEquals('01.01.2026', PPGFormatDateTick(T[2], S, FS));
  // Stunden
  S := PPGNiceDateScale(EncodeDateTime(2026, 10, 4, 8, 10, 0, 0),
    EncodeDateTime(2026, 10, 4, 17, 50, 0, 0), 6);
  CheckTrue(S.DateUnit = duHour, 'Stunden');
  CheckEquals(EncodeDateTime(2026, 10, 4, 6, 0, 0, 0), S.Min, 1E-7);
end;

procedure TChartScaleTests.DateScaleWeeksStartMonday;
var
  S: TPPGDateScale;
  T: TArray<TDateTime>;
  I: Integer;
begin
  // Mittwoch, 7.10.2026; 30 Tage, 6 Striche -> Wochen
  S := PPGNiceDateScale(EncodeDate(2026, 10, 7), EncodeDate(2026, 11, 6), 6);
  CheckTrue(S.DateUnit = duWeek, 'Wochen');
  CheckEquals(EncodeDate(2026, 10, 5), S.Min, 1E-9);
  T := PPGDateTicks(S);
  for I := 0 to High(T) do
    CheckEquals(1, DayOfTheWeek(T[I]), 'Montag');
  CheckTrue(S.Max >= EncodeDate(2026, 11, 6));
end;

procedure TChartScaleTests.DateScaleOutsideYearRange;
var
  S: TPPGDateScale;
  T: TArray<TDateTime>;
  I: Integer;
  Txt: string;
begin
  // Audit 08.10.2026: Unix-Zeitstempel (Sekunden) als Datum lagen weit
  // hinter dem Jahr 9999; IncYear/FormatDateTime warfen EConvertError.
  S := PPGNiceDateScale(1.7E9, 1.8E9, 6);
  T := PPGDateTicks(S);
  for I := 0 to High(T) do
    Txt := PPGFormatDateTick(T[I], S, Invariant);
  S := PPGNiceDateScale(-1E9, 10, 6);
  T := PPGDateTicks(S);
  CheckTrue(Length(T) < 10000);
  S.Min := 1E12;
  S.Max := 2E12;
  S.DateUnit := duDay;
  S.Count := 1;
  T := PPGDateTicks(S);
  CheckEquals(0, Length(T), 'ausserhalb: keine Ticks');
  CheckEquals('', PPGFormatDateTick(1E12, S, Invariant));
  S := PPGNiceDateScale(NaN, Infinity, 6);
  CheckTrue(Txt = Txt);
end;

procedure TChartScaleTests.StripYearFromDateFormat;
begin
  CheckEquals('dd.MM', PPGStripYearFormat('dd.MM.yyyy'));
  CheckEquals('M/d', PPGStripYearFormat('M/d/yyyy'));
  CheckEquals('MM-dd', PPGStripYearFormat('yyyy-MM-dd'));
  CheckEquals('d. MMMM', PPGStripYearFormat('d. MMMM yyyy'));
end;

{ TChartPaletteTests }

procedure TChartPaletteTests.PaletteContrastAllPresets;
var
  Names: TStringList;
  P, I: Integer;
  Dark: Boolean;
  TR: IPPGThemeRenderer;
  T: TPPGTokens;
  C: TColor;
  Errors: TStringList;
begin
  Names := TStringList.Create;
  Errors := TStringList.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    for P := 0 to Names.Count - 1 do
      for Dark := False to True do
      begin
        if not Supports(TPPGRendererRegistry.Get(Names[P]), IPPGThemeRenderer, TR) then
          Continue;
        T := TR.Tokens(Dark);
        for I := 0 to PPGChartPaletteSize - 1 do
        begin
          C := PPGChartColor(T, Dark, I);
          // WCAG 1.4.11: grafische Objekte mindestens 3:1 zur Umgebung
          if PPGContrastRatio(C, T.Layer) < 3 then
            Errors.Add(Format('%s %d Farbe %d: %.2f zu Layer', [Names[P], Ord(Dark), I,
              PPGContrastRatio(C, T.Layer)]));
          if PPGContrastRatio(C, T.Background) < 3 then
            Errors.Add(Format('%s %d Farbe %d: %.2f zu Background', [Names[P], Ord(Dark), I,
              PPGContrastRatio(C, T.Background)]));
        end;
      end;
    CheckEquals('', Errors.Text, Errors.Text);
  finally
    Errors.Free;
    Names.Free;
  end;
end;

procedure TChartPaletteTests.PaletteWrapsAndIsDistinct;
var
  T: TPPGTokens;
  I, J: Integer;
begin
  T := PPGDefaultTokens(False);
  CheckEquals(T.Accent, PPGChartColor(T, False, 0));
  CheckEquals(PPGChartColor(T, False, 1), PPGChartColor(T, False, 1 + PPGChartPaletteSize));
  CheckEquals(PPGChartColor(T, False, 0), PPGChartColor(T, False, -3), 'negativ = 0');
  for I := 0 to PPGChartPaletteSize - 1 do
    for J := I + 1 to PPGChartPaletteSize - 1 do
      CheckNotEquals(PPGChartColor(T, False, I), PPGChartColor(T, False, J),
        Format('Farben %d und %d gleich', [I, J]));
  CheckEquals(PPGColorToRGB(clHighlight), PPGChartHighContrastColor(0));
  CheckEquals(PPGChartHighContrastColor(1), PPGChartHighContrastColor(5));
end;

{ TChartShapeTests }

function TChartShapeTests.NewBitmap(W, H: Integer): TBitmap;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(W, H);
  Result.Canvas.Brush.Color := clWhite;
  Result.Canvas.FillRect(Rect(0, 0, W, H));
end;

procedure TChartShapeTests.FillPolygonGdiPlusAndGdi;
var
  Gdi: Boolean;
  B: TBitmap;
  C: IPPGCanvas;
begin
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    B := NewBitmap(40, 40);
    try
      C := TPPGRendererRegistry.CreateCanvas(B.Canvas.Handle);
      CheckTrue(Supports(C, IPPGShapeCanvas), 'IPPGShapeCanvas');
      PPGFillPolygon(C, [Point(5, 5), Point(35, 5), Point(20, 35)], clRed, 255);
      C := nil;
      CheckEquals(ColorToRGB(clRed), B.Canvas.Pixels[20, 12], 'innen');
      CheckEquals(ColorToRGB(clWhite), B.Canvas.Pixels[3, 30], 'aussen');
      CheckEquals(ColorToRGB(clWhite), B.Canvas.Pixels[35, 30], 'aussen rechts');
    finally
      B.Free;
    end;
  end;
  TPPGRendererRegistry.ForceGdiFallback := False;
end;

procedure TChartShapeTests.FillPolygonWithAlpha;
var
  Gdi: Boolean;
  B: TBitmap;
  C: IPPGCanvas;
  Px: TColor;
begin
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    B := NewBitmap(40, 40);
    try
      C := TPPGRendererRegistry.CreateCanvas(B.Canvas.Handle);
      PPGFillPolygon(C, [Point(0, 0), Point(40, 0), Point(40, 40), Point(0, 40)], clBlack, 128);
      C := nil;
      Px := B.Canvas.Pixels[20, 20];
      // halb schwarz auf weiss: Grau um 127
      CheckTrue(Abs(GetRValue(Px) - 127) <= 3, Format('Alpha (GDI=%d): %d', [Ord(Gdi), GetRValue(Px)]));
    finally
      B.Free;
    end;
  end;
  TPPGRendererRegistry.ForceGdiFallback := False;
end;

procedure TChartShapeTests.DashedLineHasGaps;
var
  Gdi: Boolean;
  B: TBitmap;
  C: IPPGCanvas;
  X, Dark: Integer;
begin
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    B := NewBitmap(100, 20);
    try
      C := TPPGRendererRegistry.CreateCanvas(B.Canvas.Handle);
      PPGDrawDashedLine(C, [Point(0, 10), Point(100, 10)], 2, 5, 5, clBlack, 255);
      C := nil;
      Dark := 0;
      for X := 0 to 99 do
        if GetRValue(B.Canvas.Pixels[X, 10]) < 128 then
          Inc(Dark);
      CheckTrue((Dark >= 30) and (Dark <= 70), Format('Strichanteil (GDI=%d): %d', [Ord(Gdi), Dark]));
    finally
      B.Free;
    end;
  end;
  TPPGRendererRegistry.ForceGdiFallback := False;
end;

procedure TChartShapeTests.ArcSegmentPolygons;
var
  P: TArray<TPoint>;
  I, N: Integer;
  D: Double;
begin
  // Kreissegment: beginnt im Mittelpunkt
  P := PPGArcSegmentPolygon(Point(50, 50), 40, 0, 0, 90);
  CheckEquals(50, P[0].X);
  CheckEquals(50, P[0].Y);
  CheckEquals(50, P[1].X, 'Start oben');
  CheckEquals(10, P[1].Y, 'Start oben');
  CheckEquals(90, P[High(P)].X, 'Ende rechts');
  // Ringsegment: aussen dann innen (rueckwaerts)
  P := PPGArcSegmentPolygon(Point(50, 50), 40, 20, 0, 180);
  N := Length(P) div 2;
  for I := 0 to N - 1 do
  begin
    D := Sqrt(Sqr(P[I].X - 50) + Sqr(P[I].Y - 50));
    CheckEquals(40, D, 1.0, 'aussen');
  end;
  for I := N to High(P) do
  begin
    D := Sqrt(Sqr(P[I].X - 50) + Sqr(P[I].Y - 50));
    CheckEquals(20, D, 1.0, 'innen');
  end;
  // Voller Kreis ohne Mittelpunkt (sonst entsteht ein Strich)
  P := PPGArcSegmentPolygon(Point(50, 50), 40, 0, 0, 360);
  CheckTrue((P[0].X <> 50) or (P[0].Y <> 50));
end;

procedure TChartShapeTests.ChartRendererForEveryPreset;
var
  Names: TStringList;
  I: Integer;
begin
  Names := TStringList.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    for I := 0 to Names.Count - 1 do
      CheckNotNull(PPGChartRendererOf(TPPGRendererRegistry.Get(Names[I])), Names[I]);
    CheckNotNull(PPGChartRendererOf(nil), 'nil -> Standard');
  finally
    Names.Free;
  end;
end;

procedure TChartShapeTests.ClassicBarIsGlossy;
var
  B: TBitmap;
  C: IPPGCanvas;
  Left, Right: TColor;
begin
  // Standard: einfarbige Saeule
  B := NewBitmap(40, 60);
  try
    C := TPPGRendererRegistry.CreateCanvas(B.Canvas.Handle);
    PPGChartRendererOf(TPPGRendererRegistry.Get(PPGPresetModernFlat)).DrawChartBar(C,
      Rect(10, 10, 30, 50), clBlue, 0, True, False, 96);
    C := nil;
    CheckEquals(B.Canvas.Pixels[13, 40], B.Canvas.Pixels[27, 40], 'flach');
    CheckEquals(ColorToRGB(clWhite), B.Canvas.Pixels[20, 5], 'ueber der Saeule');
  finally
    B.Free;
  end;
  // Classic: Glanz quer zur Saeule
  B := NewBitmap(40, 60);
  try
    C := TPPGRendererRegistry.CreateCanvas(B.Canvas.Handle);
    PPGChartRendererOf(TPPGRendererRegistry.Get(PPGPresetClassic)).DrawChartBar(C,
      Rect(10, 10, 30, 50), clBlue, 0, True, False, 96);
    C := nil;
    Left := B.Canvas.Pixels[12, 30];
    Right := B.Canvas.Pixels[27, 30];
    CheckTrue(Left <> Right, 'Classic mit Verlauf');
  finally
    B.Free;
  end;
end;

initialization
  RegisterTest('Phase10a', TChartScaleTests.Suite);
  RegisterTest('Phase10a', TChartPaletteTests.Suite);
  RegisterTest('Phase10a', TChartShapeTests.Suite);

end.
