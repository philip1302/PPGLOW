unit PPG.Tests.Phase10c;

{ Tests fuer Phase 10c: TPPGGauge und TPPGKpiTile. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics,
  PPG.Types, PPG.Tokens, PPG.Consts, PPG.Render.Registry, PPG.Controls.Base,
  PPG.Exceptions, PPG.Animation, PPG.Sparkline, PPG.Gauge, PPG.Tests.Controls;

type
  TGaugeTests = class(TControlTestCase)
  private
    FLog: TStringList;
    procedure LogChange(Sender: TObject);
    procedure LogClick(Sender: TObject);
    function NewGauge: TPPGGauge;
    function NewTile: TPPGKpiTile;
    function LoadDfm(const Text: string): TComponent;
    function RoundTrip(C: TComponent): TComponent;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure GaugeDefaultsAndClamping;
    procedure GaugeMinMaxValidation;
    procedure GaugeLoadingFixesInvalidRange;
    procedure GaugeRejectsNonFiniteValues;
    procedure GaugeAnglesAndValueAtPoint;
    procedure GaugeRangeColors;
    procedure GaugeAnimatesValueChange;
    procedure GaugeReadOnlyAndSliderInput;
    procedure GaugeAccessibility;
    procedure GaugeStreamingKeepsRanges;
    procedure GaugePaintsRangesAndValue;
    procedure KpiTrendColors;
    procedure KpiTexts;
    procedure KpiClickAndKeyboard;
    procedure KpiLayoutAndSparkline;
    procedure KpiAccessibility;
  end;

implementation

uses
  System.Math, Winapi.oleacc, PPG.Lang;

type
  TGaugeAccess = class(TPPGGauge);
  TTileAccess = class(TPPGKpiTile);
  TWinAccess = class(TWinControl);

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

function CountNear(B: TBitmap; C: TColor; Tol: Integer): Integer;
var
  X, Y: Integer;
  P: TColor;
begin
  Result := 0;
  C := ColorToRGB(C);
  for Y := 0 to B.Height - 1 do
    for X := 0 to B.Width - 1 do
    begin
      P := B.Canvas.Pixels[X, Y];
      if (Abs(GetRValue(P) - GetRValue(C)) <= Tol) and (Abs(GetGValue(P) - GetGValue(C)) <= Tol) and
        (Abs(GetBValue(P) - GetBValue(C)) <= Tol) then
        Inc(Result);
    end;
end;

procedure TGaugeTests.SetUp;
begin
  inherited SetUp;
  // Audit 11a #6: feste deutsche Formate statt der Systemeinstellung; die
  // Erwartungen sind Literale (vorher mit FormatFloat/FloatToStr wie im Code)
  FormatSettings := PPGTestGermanFormat;
  FLog := TStringList.Create;
end;

procedure TGaugeTests.TearDown;
begin
  FreeAndNil(FLog);
  inherited TearDown;
end;

procedure TGaugeTests.LogChange(Sender: TObject);
begin
  FLog.Add('change:' + FloatToStr(TPPGGauge(Sender).Value));
end;

procedure TGaugeTests.LogClick(Sender: TObject);
begin
  FLog.Add('click');
end;

function TGaugeTests.NewGauge: TPPGGauge;
begin
  Result := TPPGGauge.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 160, 160);
  Result.Animation.Enabled := False;
  Result.OnChange := LogChange;
end;

function TGaugeTests.NewTile: TPPGKpiTile;
begin
  Result := TPPGKpiTile.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 200, 120);
  Result.Animation.Enabled := False;
end;

function TGaugeTests.LoadDfm(const Text: string): TComponent;
var
  Src, Bin: TMemoryStream;
  B: TBytes;
begin
  Src := TMemoryStream.Create;
  Bin := TMemoryStream.Create;
  try
    B := TEncoding.UTF8.GetBytes(Text);
    Src.WriteBuffer(B[0], Length(B));
    Src.Position := 0;
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    Result := Bin.ReadComponent(nil);
  finally
    Bin.Free;
    Src.Free;
  end;
end;

function TGaugeTests.RoundTrip(C: TComponent): TComponent;
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

procedure TGaugeTests.GaugeDefaultsAndClamping;
var
  G: TPPGGauge;
begin
  G := NewGauge;
  CheckEquals(0, G.Min, 1E-12);
  CheckEquals(100, G.Max, 1E-12);
  CheckEquals(-135, G.StartAngle);
  CheckEquals(270, G.SweepAngle);
  CheckTrue(G.ReadOnly);
  CheckFalse(G.TabStop);
  G.Value := 150;
  CheckEquals(100, G.Value, 1E-12, 'oben geklemmt');
  G.Value := -5;
  CheckEquals(0, G.Value, 1E-12, 'unten geklemmt');
  CheckEquals(0, FLog.Count, 'Code ohne OnChange');
  try
    G.SweepAngle := 5;
    Fail('EPPGPropertyError erwartet');
  except
    on EPPGPropertyError do;
  end;
  CheckEquals(270, G.SweepAngle);
  try
    G.Increment := 0;
    Fail('EPPGPropertyError erwartet');
  except
    on EPPGPropertyError do;
  end;
end;

procedure TGaugeTests.GaugeMinMaxValidation;
var
  G: TPPGGauge;
begin
  G := NewGauge;
  G.Value := 50;
  try
    G.Max := -1;
    Fail('EPPGPropertyError erwartet');
  except
    on EPPGPropertyError do;
  end;
  CheckEquals(100, G.Max, 1E-12, 'Max unveraendert');
  try
    G.Min := 100;
    Fail('EPPGPropertyError erwartet');
  except
    on EPPGPropertyError do;
  end;
  CheckEquals(0, G.Min, 1E-12, 'Min unveraendert');
  G.Max := 40;
  CheckEquals(40, G.Value, 1E-12, 'Wert folgt neuem Max');
  G.Min := 20;
  G.Max := 30;
  CheckEquals(30, G.Value, 1E-12);
end;

procedure TGaugeTests.GaugeLoadingFixesInvalidRange;
var
  G: TPPGGauge;
begin
  RegisterClass(TPPGGauge);
  // Min > Max im DFM: oeffnen statt werfen; Max wird korrigiert
  G := LoadDfm('object Gauge1: TPPGGauge'#13#10 +
    '  Min = 200.000000000000000000'#13#10 +
    '  Max = 50.000000000000000000'#13#10 +
    '  Value = 500.000000000000000000'#13#10 + 'end') as TPPGGauge;
  try
    CheckEquals(200, G.Min, 1E-12);
    CheckTrue(G.Max > G.Min, 'Max > Min');
    CheckTrue((G.Value >= G.Min) and (G.Value <= G.Max), 'Wert geklemmt');
  finally
    G.Free;
  end;
  // Werte ausserhalb des Standardbereichs, Max vor Min im DFM
  G := LoadDfm('object Gauge1: TPPGGauge'#13#10 +
    '  Value = 150.000000000000000000'#13#10 +
    '  Max = 200.000000000000000000'#13#10 + 'end') as TPPGGauge;
  try
    CheckEquals(150, G.Value, 1E-12, 'Value vor Max gelesen');
  finally
    G.Free;
  end;
end;

procedure TGaugeTests.GaugeRejectsNonFiniteValues;
var
  G: TPPGGauge;
  B: TBitmap;
  Raised: Integer;
begin
  // Audit 08.10.2026: NaN ueberstand alle Vergleiche (Round(Cos(NaN)) im
  // Paint); Increment warf beim DFM-Laden statt zu klemmen.
  G := NewGauge;
  G.Value := 40;
  Raised := 0;
  try
    G.Value := NaN;
  except
    on E: EPPGPropertyError do
      Inc(Raised);
  end;
  try
    G.Min := NaN;
  except
    on E: EPPGPropertyError do
      Inc(Raised);
  end;
  try
    G.Max := Infinity;
  except
    on E: EPPGPropertyError do
      Inc(Raised);
  end;
  try
    G.Increment := 0;
  except
    on E: EPPGPropertyError do
      Inc(Raised);
  end;
  CheckEquals(4, Raised);
  CheckEquals(40, G.Value, 1E-12, 'Wert unveraendert');
  CheckEquals(0, G.Min, 1E-12);
  CheckEquals(100, G.Max, 1E-12);
  B := RenderToBitmap(G);
  B.Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
  RegisterClass(TPPGGauge);
  G := LoadDfm('object Gauge1: TPPGGauge'#13#10 +
    '  Increment = -2.000000000000000000'#13#10 + 'end') as TPPGGauge;
  try
    CheckEquals(1, G.Increment, 1E-12, 'beim Laden behalten statt werfen');
  finally
    G.Free;
  end;
end;

procedure TGaugeTests.GaugeAnglesAndValueAtPoint;
var
  G: TPPGGauge;
  C: TPoint;
  R, T: Integer;
begin
  G := NewGauge;
  CheckEquals(-135, G.AngleOfValue(0), 1E-6);
  CheckEquals(135, G.AngleOfValue(100), 1E-6);
  CheckEquals(0, G.AngleOfValue(50), 1E-6);
  G.GetGeometry(C, R, T);
  CheckTrue(R > 40, 'Radius');
  CheckTrue(T >= 2, 'Strich');
  // Oben = Mitte des Bogens = 50
  CheckEquals(50, G.ValueAtPoint(C.X, C.Y - R), 2);
  // Rechts (90 Grad): (90 + 135) / 270 = 83,3 %
  CheckEquals(83.3, G.ValueAtPoint(C.X + R, C.Y), 2);
  // Unten in der Luecke: naeheres Ende
  CheckEquals(100, G.ValueAtPoint(C.X + 5, C.Y + R), 1E-6);
  CheckEquals(0, G.ValueAtPoint(C.X - 5, C.Y + R), 1E-6);
  // Halbrund: Mittelpunkt unten, Bogen passt in die Breite
  G.StartAngle := -90;
  G.SweepAngle := 180;
  G.GetGeometry(C, R, T);
  CheckTrue(C.Y > G.Height div 2, 'Mittelpunkt unten');
  CheckTrue(C.X - R >= 0, 'links im Control');
  CheckTrue(C.X + R <= G.Width, 'rechts im Control');
end;

procedure TGaugeTests.GaugeRangeColors;
var
  G: TPPGGauge;
  T: TPPGTokens;
  Rg: TPPGGaugeRange;
begin
  G := NewGauge;
  T := TGaugeAccess(G).Tokens;
  Rg := G.Ranges.Add;
  Rg.StartValue := 0;
  Rg.EndValue := 60;
  Rg.Kind := grkSuccess;
  Rg := G.Ranges.Add;
  Rg.StartValue := 60;
  Rg.EndValue := 85;
  Rg.Kind := grkWarning;
  Rg := G.Ranges.Add;
  Rg.StartValue := 100;
  Rg.EndValue := 85; // vertauscht: zaehlt trotzdem
  Rg.Kind := grkError;
  CheckEquals(T.Success, G.ArcColor(30));
  CheckEquals(T.Warning, G.ArcColor(70));
  CheckEquals(T.Danger, G.ArcColor(95));
  CheckEquals(T.Warning, G.ArcColor(60), 'Ueberlappung: der letzte gewinnt');
  G.ValueColorFromRange := False;
  CheckEquals(PPGColorToRGB(TGaugeAccess(G).EffectiveAppearance.FocusColor), G.ArcColor(30));
  G.ValueColor := clFuchsia;
  CheckEquals(ColorToRGB(clFuchsia), G.ArcColor(30));
  Rg.Kind := grkCustom;
  Rg.Color := clTeal;
  G.ValueColorFromRange := True;
  G.ValueColor := clDefault;
  CheckEquals(ColorToRGB(clTeal), G.ArcColor(95));
end;

procedure TGaugeTests.GaugeAnimatesValueChange;
var
  G: TPPGGauge;
begin
  FForm.Show;
  try
    // Audit 11a #5: Systemanimationen eingespeist (vorher nur Status, wenn
    // sie im System aus sind)
    PPGSetSystemAnimationsReader(PPGTestAnimationsOn);
    G := NewGauge;
    G.Animation.Enabled := True;
    CheckTrue(G.Animation.EffectiveEnabled, 'Animation an');
    G.Value := 80;
    CheckTrue(G.DisplayValue < 80, 'gleitet hin');
    CheckEquals(80, G.Value, 1E-12, 'Value sofort');
    G.Animation.Enabled := False;
    G.Value := 30;
    CheckEquals(30, G.DisplayValue, 1E-12, 'ohne Animation sofort');
  finally
    FForm.Hide;
  end;
end;

procedure TGaugeTests.GaugeReadOnlyAndSliderInput;
var
  G: TPPGGauge;
  C: TPoint;
  R, T: Integer;
  K: Word;
begin
  FForm.Show;
  try
    G := NewGauge;
    G.Value := 40;
    G.GetGeometry(C, R, T);
    // Anzeige: keine Eingabe
    G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(C.X, C.Y - R));
    G.Perform(WM_LBUTTONUP, 0, MouseLParam(C.X, C.Y - R));
    CheckEquals(40, G.Value, 1E-12, 'ReadOnly ignoriert die Maus');
    K := VK_RIGHT;
    TWinAccess(G).KeyDown(K, []);
    CheckEquals(40, G.Value, 1E-12, 'ReadOnly ignoriert Tasten');
    // Schieberegler
    G.ReadOnly := False;
    CheckTrue(G.TabStop, 'Schieberegler mit Tabstopp');
    G.Increment := 5;
    K := VK_RIGHT;
    TWinAccess(G).KeyDown(K, []);
    CheckEquals(45, G.Value, 1E-12);
    K := VK_PRIOR;
    TWinAccess(G).KeyDown(K, []);
    CheckEquals(95, G.Value, 1E-12);
    K := VK_HOME;
    TWinAccess(G).KeyDown(K, []);
    CheckEquals(0, G.Value, 1E-12);
    K := VK_HOME;
    TWinAccess(G).KeyDown(K, []); // keine Aenderung -> kein Ereignis
    CheckEquals('change:45,change:95,change:0', FLog.CommaText);
    FLog.Clear;
    G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(C.X, C.Y - R));
    G.Perform(WM_LBUTTONUP, 0, MouseLParam(C.X, C.Y - R));
    CheckEquals(50, G.Value, 2, 'Klick oben = Mitte');
    CheckEquals(1, FLog.Count, 'ein OnChange');
    CheckEquals(DLGC_WANTARROWS, G.Perform(WM_GETDLGCODE, 0, 0) and DLGC_WANTARROWS);
  finally
    FForm.Hide;
  end;
end;

procedure TGaugeTests.GaugeAccessibility;
var
  G: TPPGGauge;
begin
  G := NewGauge;
  G.Units := ' %';
  G.Value := 68;
  CheckEquals(ROLE_SYSTEM_PROGRESSBAR, TGaugeAccess(G).AccRole);
  CheckTrue(TGaugeAccess(G).AccState and STATE_SYSTEM_READONLY <> 0);
  CheckEquals('68 %', TGaugeAccess(G).AccValue);
  G.ReadOnly := False;
  CheckEquals(ROLE_SYSTEM_SLIDER, TGaugeAccess(G).AccRole);
  CheckEquals(0, TGaugeAccess(G).AccState and STATE_SYSTEM_READONLY);
  G.ValueFormat := '0.0';
  CheckEquals('68,0 %', TGaugeAccess(G).AccValue);
end;

procedure TGaugeTests.GaugeStreamingKeepsRanges;
var
  G, G2: TPPGGauge;
  Rg: TPPGGaugeRange;
begin
  RegisterClass(TPPGGauge);
  G := NewGauge;
  G.Min := -50;
  G.Max := 50;
  G.Value := 12.5;
  G.Caption := 'Temperatur';
  G.Units := ' C';
  Rg := G.Ranges.Add;
  Rg.StartValue := -50;
  Rg.EndValue := 0;
  Rg.Kind := grkAccent;
  Rg := G.Ranges.Add;
  Rg.StartValue := 30;
  Rg.EndValue := 50;
  Rg.Kind := grkCustom;
  Rg.Color := clMaroon;
  G.ShowTarget := True;
  G.TargetValue := 21;
  G.ReadOnly := False;
  G2 := RoundTrip(G) as TPPGGauge;
  try
    CheckEquals(-50, G2.Min, 1E-12);
    CheckEquals(50, G2.Max, 1E-12);
    CheckEquals(12.5, G2.Value, 1E-12);
    CheckEquals('Temperatur', G2.Caption);
    CheckEquals(' C', G2.Units);
    CheckEquals(2, G2.Ranges.Count);
    CheckTrue(G2.Ranges[0].Kind = grkAccent);
    CheckEquals(clMaroon, G2.Ranges[1].Color);
    CheckEquals(30, G2.Ranges[1].StartValue, 1E-12);
    CheckTrue(G2.ShowTarget);
    CheckEquals(21, G2.TargetValue, 1E-12);
    CheckFalse(G2.ReadOnly);
    CheckTrue(G2.TabStop, 'TabStop des Schiebereglers');
  finally
    G2.Free;
  end;
end;

procedure TGaugeTests.GaugePaintsRangesAndValue;
var
  G: TPPGGauge;
  Rg: TPPGGaugeRange;
  B: TBitmap;
  Gdi: Boolean;
  T: TPPGTokens;
begin
  FForm.Show;
  try
    G := NewGauge;
    T := TGaugeAccess(G).Tokens;
    Rg := G.Ranges.Add;
    Rg.StartValue := 0;
    Rg.EndValue := 50;
    Rg.Kind := grkSuccess;
    G.Value := 40;
    G.ShowTarget := True;
    G.TargetValue := 70;
    G.Caption := 'Last';
    for Gdi := False to True do
    begin
      TPPGRendererRegistry.ForceGdiFallback := Gdi;
      B := RenderToBitmap(G);
      try
        // Wertbogen in Erfolgsfarbe (Wert liegt im Abschnitt)
        CheckTrue(CountNear(B, T.Success, 25) > 100, Format('Wertbogen GDI=%d', [Ord(Gdi)]));
      finally
        B.Free;
      end;
    end;
    // Leeres Control und winzige Groesse: kein Fehler
    G.SetBounds(0, 0, 3, 3);
    RenderToBitmap(G).Free;
  finally
    TPPGRendererRegistry.ForceGdiFallback := False;
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TGaugeTests.KpiTrendColors;
var
  K: TPPGKpiTile;
  T: TPPGTokens;
begin
  K := NewTile;
  T := TTileAccess(K).Tokens;
  CheckTrue(K.Trend = trNone);
  CheckEquals(T.TextSecondary, K.ChangeColor);
  K.Change := 4.2;
  CheckTrue(K.Trend = trUp);
  CheckEquals(T.Success, K.ChangeColor);
  K.Change := -1;
  CheckTrue(K.Trend = trDown);
  CheckEquals(T.Danger, K.ChangeColor);
  K.InvertTrend := True;
  CheckEquals(T.Success, K.ChangeColor, 'weniger ist besser');
  K.Enabled := False;
  CheckEquals(T.TextDisabled, K.ChangeColor);
end;

procedure TGaugeTests.KpiTexts;
var
  K: TPPGKpiTile;
begin
  K := NewTile;
  K.Value := 12480;
  K.Units := 'EUR';
  CheckEquals('12.480 EUR', K.DisplayValueText);
  K.ValueText := 'n/a';
  CheckEquals('n/a EUR', K.DisplayValueText);
  K.Units := '';
  CheckEquals('n/a', K.DisplayValueText);
  K.Change := 4.25;
  CheckEquals('+4,3%', K.DisplayChangeText, '4,25 kaufmaennisch gerundet');
  K.ChangeFormat := '';
  CheckEquals('4,25', K.DisplayChangeText);
end;

procedure TGaugeTests.KpiClickAndKeyboard;
var
  K: TPPGKpiTile;
  Key: Word;
  Ch: Char;
begin
  FForm.Show;
  try
    K := NewTile;
    K.OnClick := LogClick;
    K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(50, 50));
    K.Perform(WM_LBUTTONUP, 0, MouseLParam(50, 50));
    CheckEquals(1, FLog.Count, 'Klick');
    K.SetFocus;
    Key := VK_SPACE;
    TWinAccess(K).KeyDown(Key, []);
    Key := VK_SPACE;
    TWinAccess(K).KeyUp(Key, []);
    CheckEquals(2, FLog.Count, 'Leertaste');
    Ch := #13;
    TWinAccess(K).KeyPress(Ch);
    CheckEquals(3, FLog.Count, 'Enter');
    CheckEquals(#0, Ch, 'Enter verbraucht');
    K.Enabled := False;
    Ch := #13;
    TWinAccess(K).KeyPress(Ch);
    CheckEquals(3, FLog.Count, 'deaktiviert kein Klick');
  finally
    FForm.Hide;
  end;
end;

procedure TGaugeTests.KpiLayoutAndSparkline;
var
  K: TPPGKpiTile;
  TR, VR, CR, SR: TRect;
  B: TBitmap;
begin
  FForm.Show;
  try
    K := NewTile;
    K.Title := 'Umsatz';
    K.Value := 100;
    K.GetLayout(TR, VR, CR, SR);
    CheckTrue(IsRectEmpty(SR), 'ohne Werte keine Sparkline');
    K.SparklineText := '1;3;2;5';
    K.GetLayout(TR, VR, CR, SR);
    CheckFalse(IsRectEmpty(SR), 'Sparkline');
    CheckTrue(VR.Bottom - VR.Top > TR.Bottom - TR.Top, 'Wert groesser als Titel');
    CheckTrue(SR.Top >= CR.Bottom, 'Sparkline unter der Veraenderung');
    K.ShowSparkline := False;
    K.GetLayout(TR, VR, CR, SR);
    CheckTrue(IsRectEmpty(SR));
    K.ShowSparkline := True;
    K.Height := 70; // zu niedrig fuer die Sparkline
    K.GetLayout(TR, VR, CR, SR);
    CheckTrue(IsRectEmpty(SR), 'zu niedrig');
    K.Height := 120;
    K.Change := -3;
    B := RenderToBitmap(K);
    try
      CheckTrue(CountNear(B, K.ChangeColor, 25) > 10, 'Veraenderung farbig');
    finally
      B.Free;
    end;
    try
      K.SparklineText := 'a';
      Fail('EPPGPropertyError erwartet');
    except
      on EPPGPropertyError do;
    end;
    CheckEquals('1;3;2;5', K.SparklineText);
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TGaugeTests.KpiAccessibility;
var
  K: TPPGKpiTile;
begin
  K := NewTile;
  K.Title := 'Fehlerquote';
  K.ValueText := '2,1 %';
  K.Change := -0.3;
  CheckEquals('Fehlerquote', TTileAccess(K).AccName);
  CheckEquals(ROLE_SYSTEM_STATICTEXT, TTileAccess(K).AccRole);
  CheckEquals('2,1 %, ' + Format(PPGStr(@SPPGKpiChange), [K.DisplayChangeText]),
    TTileAccess(K).AccValue);
  K.OnClick := LogClick;
  CheckEquals(ROLE_SYSTEM_PUSHBUTTON, TTileAccess(K).AccRole, 'mit OnClick ein Button');
  K.ShowChange := False;
  CheckEquals('2,1 %', TTileAccess(K).AccValue);
end;

initialization
  RegisterTest('Phase10c', TGaugeTests.Suite);

end.
