unit PPG.Tests.Core;

{ Unit-Tests ohne Fenster: Appearance, Validierung, Farben, Layout,
  Registry, Animation-Settings. }

interface

uses
  TestFramework, System.Classes, System.SysUtils, System.Types, Vcl.Graphics,
  PPG.Types, PPG.Appearance, PPG.Animation, PPG.Layout, PPG.Exceptions,
  PPG.Render.Intf, PPG.Render.Registry, PPG.Presets, PPG.Consts;

type
  TAppearanceTests = class(TTestCase)
  private
    FChangeCount: Integer;
    procedure CountChange(Sender: TObject);
  published
    procedure AssignCopiesAllValues;
    procedure AssignFiresSingleChange;
    procedure BeginEndUpdateBatchesChanges;
    procedure SetterWithSameValueDoesNotFireChange;
    procedure InvalidRoundingRaisesAndKeepsValue;
    procedure ResolveScalesWithPPI;
    procedure ResolveFocusUsesFocusColor;
    procedure AssignFromWrongTypeRaises;
  end;

  TColorTests = class(TTestCase)
  published
    procedure BlendEndpoints;
    procedure BlendMiddle;
    procedure BlendClampsT;
    procedure BlendResolvesSystemColors;
    procedure BlendSurfaceInterpolatesGlow;
  end;

  TLayoutTests = class(TTestCase)
  private
    function MakeInput(TextW, TextH, ImgW, ImgH: Integer; Pos: TPPGImagePosition): TPPGLayoutInput;
  published
    procedure TextOnlyIsCentered;
    procedure ImageLeftOfText;
    procedure RightToLeftMirrorsImage;
    procedure ImageTopStacksVertically;
    procedure EmptyBoundsGivesEmptyResult;
    procedure TooSmallBoundsNeverNegative;
  end;

  TRegistryTests = class(TTestCase)
  published
    procedure DefaultPresetsRegistered;
    procedure FindUnknownReturnsNil;
    procedure GetUnknownRaisesConfigError;
    procedure DuplicateRegistrationRaises;
    procedure NilClassRaises;
    procedure FindIsCaseInsensitive;
    procedure RendererInstanceIsShared;
    procedure CanvasFactoryHonoursForceGdi;
  end;

  TAnimationSettingsTests = class(TTestCase)
  published
    procedure DurationOutOfRangeRaises;
    procedure DisabledMeansNotEffective;
    procedure ZeroDurationMeansNotEffective;
    procedure AnimationJumpSetsValueImmediately;
  end;

implementation

uses
  Winapi.Windows;

{ TAppearanceTests }

procedure TAppearanceTests.CountChange(Sender: TObject);
begin
  Inc(FChangeCount);
end;

procedure TAppearanceTests.AssignCopiesAllValues;
var
  A, B: TPPGAppearance;
begin
  A := TPPGAppearance.Create(nil);
  B := TPPGAppearance.Create(nil);
  try
    TPPGRendererRegistry.Get(PPGPresetClassic).ApplyDefaults(A);
    A.Hot.GlowAlpha := 77;
    A.Rounding := 9;
    CheckFalse(A.Equals(B), 'vorher verschieden');
    B.Assign(A);
    CheckTrue(A.Equals(B), 'nach Assign gleich');
    CheckEquals(77, B.Hot.GlowAlpha);
    CheckEquals(9, B.Rounding);
  finally
    B.Free;
    A.Free;
  end;
end;

procedure TAppearanceTests.AssignFiresSingleChange;
var
  A, B: TPPGAppearance;
begin
  A := TPPGAppearance.Create(nil);
  B := TPPGAppearance.Create(nil);
  try
    TPPGRendererRegistry.Get(PPGPresetModernFlat).ApplyDefaults(A);
    FChangeCount := 0;
    B.OnChange := CountChange;
    B.Assign(A);
    CheckEquals(1, FChangeCount, 'Assign darf nur EIN OnChange ausloesen');
  finally
    B.Free;
    A.Free;
  end;
end;

procedure TAppearanceTests.BeginEndUpdateBatchesChanges;
var
  A: TPPGAppearance;
begin
  A := TPPGAppearance.Create(nil);
  try
    FChangeCount := 0;
    A.OnChange := CountChange;
    A.BeginUpdate;
    try
      A.Rounding := 10;
      A.GlowSize := 7;
      A.Normal.Color := clRed;
      CheckEquals(0, FChangeCount, 'waehrend Update keine Events');
    finally
      A.EndUpdate;
    end;
    CheckEquals(1, FChangeCount);
  finally
    A.Free;
  end;
end;

procedure TAppearanceTests.SetterWithSameValueDoesNotFireChange;
var
  A: TPPGAppearance;
begin
  A := TPPGAppearance.Create(nil);
  try
    A.Rounding := 5;
    FChangeCount := 0;
    A.OnChange := CountChange;
    A.Rounding := 5;
    A.Normal.Color := A.Normal.Color;
    CheckEquals(0, FChangeCount);
  finally
    A.Free;
  end;
end;

procedure TAppearanceTests.InvalidRoundingRaisesAndKeepsValue;
var
  A: TPPGAppearance;
  Raised: Boolean;
begin
  A := TPPGAppearance.Create(nil);
  try
    A.Rounding := 6;
    Raised := False;
    try
      A.Rounding := -1;
    except
      on E: EPPGPropertyError do
      begin
        Raised := True;
        CheckEquals('Rounding', E.PropertyName);
      end;
    end;
    CheckTrue(Raised, 'EPPGPropertyError erwartet');
    CheckEquals(6, A.Rounding, 'Wert muss unveraendert bleiben');
  finally
    A.Free;
  end;
end;

procedure TAppearanceTests.ResolveScalesWithPPI;
var
  A: TPPGAppearance;
  S: TPPGSurfaceStyle;
begin
  A := TPPGAppearance.Create(nil);
  try
    A.Rounding := 6;
    A.GlowSize := 5;
    A.BorderWidth := 1;
    S := A.Resolve(vsNormal, 96, False);
    CheckEquals(6, S.Rounding);
    S := A.Resolve(vsNormal, 192, False);
    CheckEquals(12, S.Rounding);
    CheckEquals(10, S.GlowSize);
    CheckEquals(2, S.BorderWidth);
    S := A.Resolve(vsNormal, 144, False);
    CheckEquals(9, S.Rounding);
  finally
    A.Free;
  end;
end;

procedure TAppearanceTests.ResolveFocusUsesFocusColor;
var
  A: TPPGAppearance;
  S: TPPGSurfaceStyle;
begin
  A := TPPGAppearance.Create(nil);
  try
    A.FocusColor := clRed;
    A.Normal.GlowAlpha := 0;
    S := A.Resolve(vsNormal, 96, True);
    CheckEquals(Integer(PPGColorToRGB(clRed)), Integer(S.BorderColor));
    CheckTrue(S.GlowAlpha > 0, 'Fokus muss sichtbar leuchten');
    CheckTrue(S.Focused);
  finally
    A.Free;
  end;
end;

procedure TAppearanceTests.AssignFromWrongTypeRaises;
var
  A: TPPGAppearance;
  L: TStringList;
begin
  A := TPPGAppearance.Create(nil);
  L := TStringList.Create;
  try
    try
      A.Assign(L);
      Fail('EConvertError erwartet');
    except
      on E: EConvertError do
        ; // erwartet
    end;
  finally
    L.Free;
    A.Free;
  end;
end;

{ TColorTests }

procedure TColorTests.BlendEndpoints;
begin
  CheckEquals(Integer(clRed), Integer(PPGBlendColor(clRed, clBlue, 0)));
  CheckEquals(Integer(clBlue), Integer(PPGBlendColor(clRed, clBlue, 1)));
end;

procedure TColorTests.BlendMiddle;
var
  C: Cardinal;
begin
  C := Cardinal(PPGBlendColor(clBlack, clWhite, 0.5));
  CheckTrue(Abs(GetRValue(C) - 128) <= 1);
  CheckTrue(Abs(GetGValue(C) - 128) <= 1);
  CheckTrue(Abs(GetBValue(C) - 128) <= 1);
end;

procedure TColorTests.BlendClampsT;
begin
  CheckEquals(Integer(clRed), Integer(PPGBlendColor(clRed, clBlue, -5)));
  CheckEquals(Integer(clBlue), Integer(PPGBlendColor(clRed, clBlue, 7)));
end;

procedure TColorTests.BlendResolvesSystemColors;
begin
  // clBtnFace ist eine Systemfarbe (negativ) -> muss echte RGB-Farbe liefern
  CheckEquals(Integer(ColorToRGB(clBtnFace)), Integer(PPGBlendColor(clBtnFace, clBlack, 0)));
end;

procedure TColorTests.BlendSurfaceInterpolatesGlow;
var
  A, B, R: TPPGSurfaceStyle;
begin
  FillChar(A, SizeOf(A), 0);
  FillChar(B, SizeOf(B), 0);
  A.GlowAlpha := 0;
  B.GlowAlpha := 200;
  A.Rounding := 4;
  B.Rounding := 8;
  R := PPGBlendSurface(A, B, 0.5);
  CheckEquals(100, R.GlowAlpha);
  CheckEquals(6, R.Rounding);
end;

{ TLayoutTests }

function TLayoutTests.MakeInput(TextW, TextH, ImgW, ImgH: Integer;
  Pos: TPPGImagePosition): TPPGLayoutInput;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Bounds := Rect(0, 0, 200, 40);
  Result.TextSize.cx := TextW;
  Result.TextSize.cy := TextH;
  Result.ImageSize.cx := ImgW;
  Result.ImageSize.cy := ImgH;
  Result.ImagePosition := Pos;
  Result.Spacing := 4;
  Result.Alignment := haCenter;
end;

procedure TLayoutTests.TextOnlyIsCentered;
var
  R: TPPGLayoutResult;
begin
  R := TPPGLayoutEngine.Calculate(MakeInput(100, 20, 0, 0, ipLeft));
  CheckEquals(50, R.TextRect.Left);
  CheckEquals(150, R.TextRect.Right);
  CheckEquals(10, R.TextRect.Top);
  CheckTrue(IsRectEmpty(R.ImageRect));
end;

procedure TLayoutTests.ImageLeftOfText;
var
  R: TPPGLayoutResult;
begin
  // Block: 16 + 4 + 100 = 120 breit -> Start bei 40
  R := TPPGLayoutEngine.Calculate(MakeInput(100, 20, 16, 16, ipLeft));
  CheckEquals(40, R.ImageRect.Left);
  CheckEquals(56, R.ImageRect.Right);
  CheckEquals(60, R.TextRect.Left);
  CheckEquals(12, R.ImageRect.Top, 'Bild vertikal zentriert');
end;

procedure TLayoutTests.RightToLeftMirrorsImage;
var
  Input: TPPGLayoutInput;
  R: TPPGLayoutResult;
begin
  Input := MakeInput(100, 20, 16, 16, ipLeft);
  Input.RightToLeft := True;
  R := TPPGLayoutEngine.Calculate(Input);
  CheckTrue(R.ImageRect.Left > R.TextRect.Left, 'Bild muss bei RTL rechts stehen');
end;

procedure TLayoutTests.ImageTopStacksVertically;
var
  Input: TPPGLayoutInput;
  R: TPPGLayoutResult;
begin
  Input := MakeInput(60, 14, 16, 16, ipTop);
  Input.Bounds := Rect(0, 0, 100, 60);
  R := TPPGLayoutEngine.Calculate(Input);
  CheckTrue(R.ImageRect.Bottom <= R.TextRect.Top, 'Bild ueber dem Text');
  CheckEquals(R.TextRect.Top - R.ImageRect.Bottom, 4, 'Abstand = Spacing');
end;

procedure TLayoutTests.EmptyBoundsGivesEmptyResult;
var
  Input: TPPGLayoutInput;
  R: TPPGLayoutResult;
begin
  Input := MakeInput(100, 20, 16, 16, ipLeft);
  Input.Bounds := Rect(10, 10, 10, 10);
  R := TPPGLayoutEngine.Calculate(Input);
  CheckTrue(IsRectEmpty(R.TextRect));
  CheckTrue(IsRectEmpty(R.ImageRect));
end;

procedure TLayoutTests.TooSmallBoundsNeverNegative;
var
  Input: TPPGLayoutInput;
  R: TPPGLayoutResult;
begin
  Input := MakeInput(300, 20, 32, 32, ipLeft);
  Input.Bounds := Rect(0, 0, 20, 10);
  R := TPPGLayoutEngine.Calculate(Input);
  CheckTrue(R.TextRect.Right >= R.TextRect.Left, 'Breite >= 0');
  CheckTrue(R.TextRect.Bottom >= R.TextRect.Top, 'Hoehe >= 0');
end;

{ TRegistryTests }

type
  TDummyRenderer = class(TPPGRendererBase)
  public
    function Name: string; override;
    procedure ApplyDefaults(Appearance: TPPGAppearance); override;
    procedure DrawSurface(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle); override;
  end;

function TDummyRenderer.Name: string;
begin
  Result := 'Dummy';
end;

procedure TDummyRenderer.ApplyDefaults(Appearance: TPPGAppearance);
begin
end;

procedure TDummyRenderer.DrawSurface(const Canvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle);
begin
end;

procedure TRegistryTests.DefaultPresetsRegistered;
begin
  CheckTrue(TPPGRendererRegistry.IsRegistered(PPGPresetClassic));
  CheckTrue(TPPGRendererRegistry.IsRegistered(PPGPresetModernFlat));
  CheckTrue(TPPGRendererRegistry.IsRegistered(TPPGRendererRegistry.DefaultName));
end;

procedure TRegistryTests.FindUnknownReturnsNil;
begin
  CheckTrue(TPPGRendererRegistry.Find('NoSuchPreset') = nil);
end;

procedure TRegistryTests.GetUnknownRaisesConfigError;
begin
  try
    TPPGRendererRegistry.Get('NoSuchPreset');
    Fail('EPPGConfigError erwartet');
  except
    on E: EPPGConfigError do
      ;
  end;
end;

procedure TRegistryTests.DuplicateRegistrationRaises;
begin
  TPPGRendererRegistry.RegisterRenderer('DupTest', TDummyRenderer);
  try
    try
      TPPGRendererRegistry.RegisterRenderer('duptest', TDummyRenderer);
      Fail('EPPGConfigError erwartet (Name case-insensitiv doppelt)');
    except
      on E: EPPGConfigError do
        ;
    end;
  finally
    TPPGRendererRegistry.UnregisterRenderer('DupTest');
  end;
  CheckFalse(TPPGRendererRegistry.IsRegistered('DupTest'));
end;

procedure TRegistryTests.NilClassRaises;
begin
  try
    TPPGRendererRegistry.RegisterRenderer('NilTest', nil);
    Fail('EPPGConfigError erwartet');
  except
    on E: EPPGConfigError do
      ;
  end;
  CheckFalse(TPPGRendererRegistry.IsRegistered('NilTest'));
end;

procedure TRegistryTests.FindIsCaseInsensitive;
begin
  CheckTrue(TPPGRendererRegistry.Find(UpperCase(PPGPresetClassic)) <> nil);
end;

procedure TRegistryTests.RendererInstanceIsShared;
var
  A, B: IPPGRenderer;
begin
  A := TPPGRendererRegistry.Get(PPGPresetClassic);
  B := TPPGRendererRegistry.Get(PPGPresetClassic);
  CheckTrue(A = B, 'Renderer sind zustandslos und werden geteilt');
end;

procedure TRegistryTests.CanvasFactoryHonoursForceGdi;
var
  Bmp: Vcl.Graphics.TBitmap;
  C: IPPGCanvas;
  Old: Boolean;
begin
  Old := TPPGRendererRegistry.ForceGdiFallback;
  Bmp := Vcl.Graphics.TBitmap.Create;
  try
    Bmp.SetSize(10, 10);
    TPPGRendererRegistry.ForceGdiFallback := True;
    C := TPPGRendererRegistry.CreateCanvas(Bmp.Canvas.Handle);
    CheckFalse(C.IsAntialiased, 'GDI-Fallback erwartet');
    C := nil;
    TPPGRendererRegistry.ForceGdiFallback := False;
    C := TPPGRendererRegistry.CreateCanvas(Bmp.Canvas.Handle);
    CheckTrue(C.IsAntialiased, 'GDI+ erwartet');
    C := nil;
  finally
    TPPGRendererRegistry.ForceGdiFallback := Old;
    Bmp.Free;
  end;
end;

{ TAnimationSettingsTests }

procedure TAnimationSettingsTests.DurationOutOfRangeRaises;
var
  S: TPPGAnimationSettings;
begin
  S := TPPGAnimationSettings.Create(nil);
  try
    try
      S.Duration := -10;
      Fail('EPPGPropertyError erwartet');
    except
      on E: EPPGPropertyError do
        ;
    end;
    CheckEquals(PPGDefaultAnimationDuration, S.Duration);
  finally
    S.Free;
  end;
end;

procedure TAnimationSettingsTests.DisabledMeansNotEffective;
var
  S: TPPGAnimationSettings;
begin
  S := TPPGAnimationSettings.Create(nil);
  try
    S.Enabled := False;
    CheckFalse(S.EffectiveEnabled);
  finally
    S.Free;
  end;
end;

procedure TAnimationSettingsTests.ZeroDurationMeansNotEffective;
var
  S: TPPGAnimationSettings;
begin
  S := TPPGAnimationSettings.Create(nil);
  try
    S.Duration := 0;
    CheckFalse(S.EffectiveEnabled);
  finally
    S.Free;
  end;
end;

procedure TAnimationSettingsTests.AnimationJumpSetsValueImmediately;
var
  A: TPPGAnimation;
begin
  A := TPPGAnimation.Create(nil);
  try
    A.AnimateTo(1, 0);
    CheckEquals(1.0, A.Value, 0.0001);
    CheckFalse(A.Running);
    A.AnimateTo(0, 500);
    CheckTrue(A.Running, 'mit Dauer laeuft die Animation');
    CheckEquals(1, PPGRunningAnimationCount);
  finally
    A.Free;
  end;
  CheckEquals(0, PPGRunningAnimationCount, 'Free muss beim Animator abmelden');
end;

initialization
  RegisterTest('Core', TAppearanceTests.Suite);
  RegisterTest('Core', TColorTests.Suite);
  RegisterTest('Core', TLayoutTests.Suite);
  RegisterTest('Core', TRegistryTests.Suite);
  RegisterTest('Core', TAnimationSettingsTests.Suite);

end.
