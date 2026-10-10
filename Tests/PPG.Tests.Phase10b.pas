unit PPG.Tests.Phase10b;

{ Tests fuer Phase 10b: TPPGSparkline und PPGDrawSparkline. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics,
  PPG.Types, PPG.Tokens, PPG.Consts, PPG.Render.Intf, PPG.Render.Registry,
  PPG.Controls.Base, PPG.Exceptions, PPG.Sparkline, PPG.Tests.Controls;

type
  TSparklineTests = class(TControlTestCase)
  private
    function NewSpark: TPPGSparkline;
    function CountColor(B: TBitmap; C: TColor; Tol: Integer): Integer;
    function RoundTrip(C: TComponent): TComponent;
  published
    procedure ValuesTextParseAndFormat;
    procedure InvalidValuesTextRaisesAndKeepsValues;
    procedure LoadingInvalidValuesTextIsSkipped;
    procedure MaxCountIsSlidingWindow;
    procedure StreamingKeepsValuesAndOptions;
    procedure PaintsEveryKindWithGdiPlusAndGdi;
    procedure NegativeColumnsUseNegativeColor;
    procedure MarkersUseSignalColors;
    procedure ManyValuesAreCondensed;
    procedure DrawOnCanvasHelper;
    procedure DisabledHasNoAccent;
    procedure AccessibilitySummary;
    procedure IndexOutOfRangeRaises;
    procedure NonFiniteValuesAreSafe;
  end;

implementation

uses
  System.Math, Winapi.oleacc, PPG.Lang;

type
  TSparkAccess = class(TPPGSparkline);

function Near(A, B: TColor; Tol: Integer): Boolean;
begin
  A := ColorToRGB(A);
  B := ColorToRGB(B);
  Result := (Abs(GetRValue(A) - GetRValue(B)) <= Tol) and
    (Abs(GetGValue(A) - GetGValue(B)) <= Tol) and (Abs(GetBValue(A) - GetBValue(B)) <= Tol);
end;

function TSparklineTests.NewSpark: TPPGSparkline;
begin
  Result := TPPGSparkline.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 160, 40);
end;

function TSparklineTests.CountColor(B: TBitmap; C: TColor; Tol: Integer): Integer;
var
  X, Y: Integer;
begin
  Result := 0;
  for Y := 0 to B.Height - 1 do
    for X := 0 to B.Width - 1 do
      if Near(B.Canvas.Pixels[X, Y], C, Tol) then
        Inc(Result);
end;

function TSparklineTests.RoundTrip(C: TComponent): TComponent;
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

procedure TSparklineTests.ValuesTextParseAndFormat;
var
  S: TPPGSparkline;
  V: TArray<Double>;
begin
  S := NewSpark;
  S.ValuesText := '3; 5.5 ;-2';
  CheckEquals(3, S.Count);
  CheckEquals(5.5, S.Values[1], 1E-12);
  CheckEquals(-2, S.Values[2], 1E-12);
  CheckEquals('3;5.5;-2', S.ValuesText);
  S.ValuesText := '';
  CheckEquals(0, S.Count);
  CheckTrue(PPGParseValueList('1;;2', V), 'leere Teile ueberspringen');
  CheckEquals(2, Length(V));
  CheckFalse(PPGParseValueList('1;x', V));
  CheckEquals(0, Length(V));
  CheckEquals('1.25;2', PPGFormatValueList([1.25, 2]));
end;

procedure TSparklineTests.InvalidValuesTextRaisesAndKeepsValues;
var
  S: TPPGSparkline;
begin
  S := NewSpark;
  S.SetValues([1, 2, 3]);
  try
    S.ValuesText := '1;zwei';
    Fail('EPPGPropertyError erwartet');
  except
    on E: EPPGPropertyError do
      CheckEquals('ValuesText', E.PropertyName);
  end;
  CheckEquals(3, S.Count, 'Werte unveraendert');
end;

procedure TSparklineTests.LoadingInvalidValuesTextIsSkipped;
var
  Src, Bin: TMemoryStream;
  B: TBytes;
  S: TPPGSparkline;
begin
  RegisterClass(TPPGSparkline);
  Src := TMemoryStream.Create;
  Bin := TMemoryStream.Create;
  try
    B := TEncoding.UTF8.GetBytes('object Spark1: TPPGSparkline'#13#10 +
      '  ValuesText = ''1;b;3'''#13#10 + '  Kind = skColumn'#13#10 + 'end');
    Src.WriteBuffer(B[0], Length(B));
    Src.Position := 0;
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    S := Bin.ReadComponent(nil) as TPPGSparkline;
    try
      CheckEquals(0, S.Count);
      CheckTrue(S.Kind = skColumn, 'restliche Properties geladen');
    finally
      S.Free;
    end;
  finally
    Bin.Free;
    Src.Free;
  end;
end;

procedure TSparklineTests.MaxCountIsSlidingWindow;
var
  S: TPPGSparkline;
  I: Integer;
begin
  S := NewSpark;
  S.MaxCount := 3;
  for I := 1 to 5 do
    S.AddValue(I);
  CheckEquals(3, S.Count);
  CheckEquals(3, S.Values[0], 1E-12);
  CheckEquals(5, S.Values[2], 1E-12);
  S.MaxCount := 2;
  CheckEquals(2, S.Count);
  CheckEquals(4, S.Values[0], 1E-12);
  S.SetValues([1, 2, 3, 4]);
  CheckEquals(2, S.Count, 'SetValues beachtet MaxCount');
  try
    S.MaxCount := -1;
    Fail('EPPGPropertyError erwartet');
  except
    on EPPGPropertyError do;
  end;
  CheckEquals(2, S.MaxCount);
  S.MaxCount := 0;
  S.AddValue(9);
  CheckEquals(3, S.Count, '0 = unbegrenzt');
  S.Clear;
  CheckEquals(0, S.Count);
end;

procedure TSparklineTests.StreamingKeepsValuesAndOptions;
var
  S, S2: TPPGSparkline;
begin
  RegisterClass(TPPGSparkline);
  S := NewSpark;
  S.ValuesText := '1.5;-2;7';
  S.Kind := skWinLoss;
  S.Markers := [smMin, smFirst];
  S.UseRange := True;
  S.RangeMin := -5;
  S.RangeMax := 10.5;
  S.ShowReference := True;
  S.ReferenceValue := 2.25;
  S.LineColor := clRed;
  S2 := RoundTrip(S) as TPPGSparkline;
  try
    CheckEquals('1.5;-2;7', S2.ValuesText);
    CheckTrue(S2.Kind = skWinLoss);
    CheckTrue(S2.Markers = [smMin, smFirst]);
    CheckTrue(S2.UseRange);
    CheckEquals(-5, S2.RangeMin, 1E-12);
    CheckEquals(10.5, S2.RangeMax, 1E-12);
    CheckEquals(2.25, S2.ReferenceValue, 1E-12);
    CheckEquals(clRed, S2.LineColor);
  finally
    S2.Free;
  end;
end;

procedure TSparklineTests.PaintsEveryKindWithGdiPlusAndGdi;
var
  S: TPPGSparkline;
  K: TPPGSparklineKind;
  Gdi: Boolean;
  B: TBitmap;
  Accent: TColor;
begin
  FForm.Show;
  try
    S := NewSpark;
    S.SetValues([3, 5, -2, 8, 6, 9, -1, 11]);
    Accent := S.DrawOptions.Color;
    for Gdi := False to True do
      for K := Low(TPPGSparklineKind) to High(TPPGSparklineKind) do
      begin
        TPPGRendererRegistry.ForceGdiFallback := Gdi;
        S.Kind := K;
        B := RenderToBitmap(S);
        try
          CheckTrue(CountColor(B, Accent, 30) > 20, Format('Art %d GDI=%d: kaum Akzent',
            [Ord(K), Ord(Gdi)]));
        finally
          B.Free;
        end;
      end;
  finally
    TPPGRendererRegistry.ForceGdiFallback := False;
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TSparklineTests.NegativeColumnsUseNegativeColor;
var
  S: TPPGSparkline;
  B: TBitmap;
begin
  FForm.Show;
  try
    S := NewSpark;
    S.Kind := skColumn;
    S.Markers := [];
    S.NegativeColor := clRed;
    S.SetValues([3, -2, 4]);
    B := RenderToBitmap(S);
    try
      CheckTrue(CountColor(B, clRed, 10) > 20, 'negative Saeule rot');
      // Rote Pixel liegen unter der Nulllinie (untere Haelfte)
      CheckTrue(Near(B.Canvas.Pixels[S.Width div 2, S.Height - 8], clRed, 10), 'unten');
      CheckFalse(Near(B.Canvas.Pixels[S.Width div 2, 6], clRed, 10), 'oben nicht');
    finally
      B.Free;
    end;
  finally
    FForm.Hide;
  end;
end;

procedure TSparklineTests.MarkersUseSignalColors;
var
  S: TPPGSparkline;
  B: TBitmap;
  T: TPPGTokens;
begin
  FForm.Show;
  try
    S := NewSpark;
    S.Markers := [smMin, smMax];
    S.SetValues([5, 1, 9, 4]);
    T := TSparkAccess(S).Tokens;
    B := RenderToBitmap(S);
    try
      CheckTrue(CountColor(B, T.Danger, 20) >= 6, 'Minimum in Fehlerfarbe');
      CheckTrue(CountColor(B, T.Success, 20) >= 6, 'Maximum in Erfolgsfarbe');
    finally
      B.Free;
    end;
  finally
    FForm.Hide;
  end;
end;

procedure TSparklineTests.ManyValuesAreCondensed;
var
  S: TPPGSparkline;
  V: TArray<Double>;
  I: Integer;
  B: TBitmap;
begin
  // Audit 11a #7: Laufzeit im Benchmark (Bench11, vorher 1000 ms im Test)
  FForm.Show;
  try
    S := NewSpark;
    S.Width := 120;
    SetLength(V, 100000);
    for I := 0 to High(V) do
      V[I] := Sin(I / 500) * 10 + Random(3);
    S.SetValues(V);
    B := RenderToBitmap(S);
    try
      CheckTrue(CountColor(B, S.DrawOptions.Color, 40) > 50, 'Verlauf sichtbar');
    finally
      B.Free;
    end;
  finally
    FForm.Hide;
  end;
end;

procedure TSparklineTests.NonFiniteValuesAreSafe;
var
  Sp: TPPGSparkline;
  B: TBitmap;
  O: TPPGSparklineOptions;
  Raised: Integer;
  K: TPPGSparklineKind;
begin
  // Audit 08.10.2026: NaN/Unendlich machten Lo/Hi zu NaN, Round warf im
  // Paint (auch PPGDrawSparkline in Grid-Zellen).
  Sp := TPPGSparkline.Create(FForm);
  Sp.Parent := FForm;
  Sp.SetValues([1, 2]);
  Raised := 0;
  try
    Sp.AddValue(NaN);
  except
    on E: EPPGPropertyError do
      Inc(Raised);
  end;
  try
    Sp.RangeMax := Infinity;
  except
    on E: EPPGPropertyError do
      Inc(Raised);
  end;
  try
    Sp.ValuesText := '1;NAN;3';
  except
    on E: EPPGPropertyError do
      Inc(Raised);
  end;
  CheckEquals(3, Raised);
  CheckEquals(2, Sp.Count, 'Werte unveraendert');
  O := PPGDefaultSparklineOptions(PPGDefaultTokens(False), clWhite, 96);
  O.Color := clBlue;
  B := TBitmap.Create;
  try
    B.PixelFormat := pf24bit;
    B.SetSize(100, 30);
    for K := Low(TPPGSparklineKind) to High(TPPGSparklineKind) do
    begin
      O.Kind := K;
      PPGDrawSparklineOnCanvas(B.Canvas, Rect(0, 0, 100, 30), [NaN, 1, Infinity, 3, NegInfinity, 2], O);
      PPGDrawSparklineOnCanvas(B.Canvas, Rect(0, 0, 100, 30), [NaN, NaN], O);
    end;
    O.Kind := skLine;
    B.Canvas.Brush.Color := clWhite;
    B.Canvas.FillRect(Rect(0, 0, 100, 30));
    PPGDrawSparklineOnCanvas(B.Canvas, Rect(0, 0, 100, 30), [NaN, 1, 3, Infinity, 2], O);
    CheckTrue(CountColor(B, clBlue, 30) > 20, 'endliche Werte gezeichnet');
  finally
    B.Free;
  end;
end;

procedure TSparklineTests.DrawOnCanvasHelper;
var
  B: TBitmap;
  O: TPPGSparklineOptions;
  I: Integer;
  Gdi0: Cardinal;
begin
  O := PPGDefaultSparklineOptions(PPGDefaultTokens(False), clWhite, 96);
  O.Color := clBlue;
  B := TBitmap.Create;
  try
    B.PixelFormat := pf24bit;
    B.SetSize(100, 30);
    B.Canvas.Brush.Color := clWhite;
    B.Canvas.FillRect(Rect(0, 0, 100, 30));
    PPGDrawSparklineOnCanvas(B.Canvas, Rect(0, 0, 100, 30), [1, 3, 2, 5], O);
    CheckTrue(CountColor(B, clBlue, 30) > 20, 'gezeichnet');
    // Kein Handle-Zuwachs bei wiederholtem Zeichnen
    Gdi0 := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
    for I := 1 to 50 do
      PPGDrawSparklineOnCanvas(B.Canvas, Rect(0, 0, 100, 30), [1, 3, 2, 5], O);
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS) <= Gdi0 + 2, 'GDI-Handles');
    // Leere Werte und leeres Rechteck: nichts passiert
    PPGDrawSparklineOnCanvas(B.Canvas, Rect(0, 0, 100, 30), [], O);
    PPGDrawSparklineOnCanvas(B.Canvas, Rect(0, 0, 0, 0), [1, 2], O);
  finally
    B.Free;
  end;
end;

procedure TSparklineTests.DisabledHasNoAccent;
var
  S: TPPGSparkline;
  B: TBitmap;
  Accent: TColor;
begin
  FForm.Show;
  try
    S := NewSpark;
    S.SetValues([1, 4, 2, 6]);
    Accent := S.DrawOptions.Color;
    S.Enabled := False;
    B := RenderToBitmap(S);
    try
      CheckEquals(0, CountColor(B, Accent, 10), 'Akzent im deaktivierten Zustand');
    finally
      B.Free;
    end;
  finally
    FForm.Hide;
  end;
end;

procedure TSparklineTests.AccessibilitySummary;
var
  S: TPPGSparkline;
begin
  // Audit 11a #6: feste deutsche Formate; Erwartung als Literal (vorher
  // FloatToStr wie im Code)
  FormatSettings := PPGTestGermanFormat;
  S := NewSpark;
  S.Hint := 'Umsatz';
  CheckEquals(ROLE_SYSTEM_CHART, TSparkAccess(S).AccRole);
  CheckEquals('Umsatz', TSparkAccess(S).AccName);
  CheckEquals(PPGStr(@SPPGChartNoData), TSparkAccess(S).AccValue);
  S.SetValues([4, 1.5, 7, 3]);
  CheckEquals(Format(PPGStr(@SPPGSparklineSummary), ['1,5', '7', '3']),
    TSparkAccess(S).AccValue, 'Minimum, Maximum, letzter Wert');
  CheckTrue(TSparkAccess(S).AccState and STATE_SYSTEM_READONLY <> 0);
  CheckFalse(S.TabStop, 'kein Tabstopp');
end;

procedure TSparklineTests.IndexOutOfRangeRaises;
var
  S: TPPGSparkline;
  D: Double;
begin
  S := NewSpark;
  S.SetValues([1]);
  try
    D := S.Values[1];
    Status(FloatToStr(D));
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
end;

initialization
  RegisterTest('Phase10b', TSparklineTests.Suite);

end.
