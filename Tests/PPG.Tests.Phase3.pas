unit PPG.Tests.Phase3;

{ Tests fuer Phase 3: ProgressBar, TrackBar, Panel, GroupBox. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, Winapi.ActiveX, Winapi.oleacc,
  System.Classes, System.SysUtils, System.Types, System.Variants, System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Themes,
  PPG.Types, PPG.Consts, PPG.Exceptions, PPG.Appearance, PPG.Animation,
  PPG.Render.Intf, PPG.Render.Registry, PPG.Button, PPG.CheckBox,
  PPG.ProgressBar, PPG.TrackBar, PPG.Panel, PPG.GroupBox,
  PPG.Tests.Controls, PPG.Tests.Gaps;

type
  TPhase3TestCase = class(TGapTestCase)
  protected
    FChanges: Integer;
    procedure SetUp; override;
    procedure CountChange(Sender: TObject);
    procedure RaisingChange(Sender: TObject);
    function NewProgress(W: Integer = 200; H: Integer = 20): TPPGProgressBar;
    function NewTrack(W: Integer = 200; H: Integer = 40): TPPGTrackBar;
    function NewPanel: TPPGPanel;
    function NewGroup(const ACaption: string = 'Gruppe'): TPPGGroupBox;
  end;

  TRangeTests = class(TPhase3TestCase)
  published
    procedure DefaultsMatchVcl;
    procedure PositionIsClampedSilently;
    procedure MinAboveMaxRaisesAndKeepsState;
    procedure SetRangeSetsBothBounds;
    procedure OnChangeOnlyOnRealChange;
    procedure LoadsInAnyOrderWithoutEvents;
    procedure InconsistentDfmIsRepaired;
    procedure InvalidValuesRaiseAndKeepState;
    procedure HugeRangeDoesNotOverflow;
    procedure RoundTripKeepsAllProperties;
  end;

  TProgressBarTests = class(TPhase3TestCase)
  published
    procedure FillFollowsPositionGdiPlusAndGdi;
    procedure RightToLeftAndVerticalFillFromTheEnd;
    procedure ErrorStateIsRed;
    procedure TextOnFillUsesFillTextColor;
    procedure GdiTextRespectsCanvasClip;
    procedure StepItAndStepBy;
    procedure MarqueeRunsOnlyWhileShowing;
    procedure MarqueeIsStaticWithoutAnimation;
    procedure PositionAnimatesOnlyWhenVisible;
    procedure AccessibilityRoleAndValue;
  end;

  TTrackBarTests = class(TPhase3TestCase)
  published
    procedure KeyboardMovesByLineAndPage;
    procedure RightToLeftMirrorsArrowKeys;
    procedure WantsArrowKeys;
    procedure ClickOnTrackJumpsAndDrags;
    procedure GrabbingThumbDoesNotJump;
    procedure MouseWheelUsesLineSize;
    procedure DisabledIgnoresInput;
    procedure ExceptionInOnChangeKeepsPosition;
    procedure VerticalHasMinAtTopAndSwapsSize;
    procedure ThumbAndFillArePaintedAtPosition;
    procedure AutoSizeAdjustsThicknessOnly;
    procedure AccessibilityRoleAndValue;
  end;

  TContainerTests = class(TPhase3TestCase)
  published
    procedure AcceptsControlsAndClipsChildren;
    procedure AlignedChildStaysInsideBorderAndRounding;
    procedure PaddingIsAddedToInset;
    procedure AppearanceChangeRealignsChildren;
    procedure GroupBoxChildrenStartBelowCaption;
    procedure GroupBoxFontChangeRealigns;
    procedure NoHoverAnimationOnContainers;
    procedure GroupBoxAcceleratorFocusesFirstChild;
    procedure GroupBoxTracksFocusInside;
    procedure ChildPaintsOnPanelBackground;
    procedure LoadsVclStyleDfms;
    procedure AccessibilityExposesChildren;
  end;

  TPhase3PaintTests = class(TPhase3TestCase)
  published
    procedure AllControlsAllVariantsPaintWithoutErrors;
    procedure ExtremeSizesPaintWithoutErrors;
    procedure NoHandleOrMemoryLeaks;
  end;

implementation

{$WARN SYMBOL_PLATFORM OFF}

type
  TPBAccess = class(TPPGProgressBar);
  TTBAccess = class(TPPGTrackBar);
  TPanelAccess = class(TPPGPanel);
  TGroupAccess = class(TPPGGroupBox);

const
  GR_GDIOBJECTS = 0;
  GR_USEROBJECTS = 1;

// Eigener Import: Winapi.oleacc deklariert das Ergebnis-Array als einzelnes
// "out VARIANT" (dann wuerde nur das erste Element korrekt verwaltet)
function PPG_AccessibleChildren(paccContainer: IAccessible; iChildStart, cChildren: Longint;
  rgvarChildren: POleVariant; out pcObtained: Longint): HResult; stdcall;
  external 'oleacc.dll' name 'AccessibleChildren';

function ColorDist(A, B: TColor): Integer;
var
  CA, CB: Cardinal;
begin
  CA := ColorToRGB(A);
  CB := ColorToRGB(B);
  Result := Abs(GetRValue(CA) - GetRValue(CB)) + Abs(GetGValue(CA) - GetGValue(CB)) +
    Abs(GetBValue(CA) - GetBValue(CB));
end;

function MouseLParam(X, Y: Integer): LPARAM;
begin
  // Negative Koordinaten (ausserhalb links/oben) wie Windows als SmallInt kodieren
  Result := LPARAM(Cardinal(Word(SmallInt(X))) or (Cardinal(Word(SmallInt(Y))) shl 16));
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

function LoadDfm(const Text: string; Instance: TComponent): TComponent;
var
  Src: TStringStream;
  Bin: TMemoryStream;
begin
  Src := TStringStream.Create(Text);
  Bin := TMemoryStream.Create;
  try
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    Result := Bin.ReadComponent(Instance);
  finally
    Bin.Free;
    Src.Free;
  end;
end;

{ TPhase3TestCase }

procedure TPhase3TestCase.SetUp;
begin
  inherited;
  FChanges := 0;
end;

procedure TPhase3TestCase.CountChange(Sender: TObject);
begin
  Inc(FChanges);
end;

procedure TPhase3TestCase.RaisingChange(Sender: TObject);
begin
  raise EAbort.Create('OnChange failed');
end;

function TPhase3TestCase.NewProgress(W, H: Integer): TPPGProgressBar;
begin
  Result := TPPGProgressBar.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, W, H);
  Result.Preset := PPGPresetModernFlat;
  Result.Animation.Enabled := False;
  Result.OnChange := CountChange;
  Result.HandleNeeded;
end;

function TPhase3TestCase.NewTrack(W, H: Integer): TPPGTrackBar;
begin
  Result := TPPGTrackBar.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 50, W, H);
  Result.Preset := PPGPresetModernFlat;
  Result.Animation.Enabled := False;
  Result.OnChange := CountChange;
  Result.HandleNeeded;
end;

function TPhase3TestCase.NewPanel: TPPGPanel;
begin
  Result := TPPGPanel.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 200, 100);
  Result.Preset := PPGPresetModernFlat;
  Result.Caption := '';
  Result.HandleNeeded;
end;

function TPhase3TestCase.NewGroup(const ACaption: string): TPPGGroupBox;
begin
  Result := TPPGGroupBox.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 220, 140);
  Result.Preset := PPGPresetModernFlat;
  Result.Caption := ACaption;
  Result.HandleNeeded;
end;

{ TRangeTests }

procedure TRangeTests.DefaultsMatchVcl;
var
  P: TPPGProgressBar;
  T: TPPGTrackBar;
begin
  // Gleiche Vorgaben wie TProgressBar/TTrackBar: nicht gespeicherte Werte
  // einer migrierten DFM bedeuten dasselbe
  P := NewProgress;
  CheckEquals(0, P.Min);
  CheckEquals(100, P.Max);
  CheckEquals(0, P.Position);
  CheckEquals(10, P.Step);
  CheckEquals(10, P.MarqueeInterval);
  CheckTrue(P.Style = pbstNormal);
  CheckFalse(P.TabStop);
  CheckEquals('', P.Caption, 'kein Komponentenname als Text');
  T := NewTrack;
  CheckEquals(0, T.Min);
  CheckEquals(10, T.Max);
  CheckEquals(1, T.Frequency);
  CheckEquals(1, T.LineSize);
  CheckEquals(2, T.PageSize);
  CheckEquals(20, T.ThumbLength);
  CheckTrue(T.TickMarks = tmBottomRight);
  CheckTrue(T.TickStyle = tsAuto);
  CheckTrue(T.TabStop);
end;

procedure TRangeTests.PositionIsClampedSilently;
var
  P: TPPGProgressBar;
begin
  P := NewProgress;
  P.Position := 150;
  CheckEquals(100, P.Position, 'wie TProgressBar: still auf Max begrenzt');
  P.Position := -5;
  CheckEquals(0, P.Position);
  P.Position := P.Position + 1000;
  CheckEquals(100, P.Position);
end;

procedure TRangeTests.MinAboveMaxRaisesAndKeepsState;
var
  P: TPPGProgressBar;
begin
  P := NewProgress;
  P.Position := 40;
  try
    P.Min := 200;
    Fail('EPPGPropertyError erwartet');
  except
    on E: EPPGPropertyError do
      CheckEquals('Min', E.PropertyName);
  end;
  try
    P.Max := -1;
    Fail('EPPGPropertyError erwartet');
  except
    on E: EPPGPropertyError do
      CheckEquals('Max', E.PropertyName);
  end;
  CheckEquals(0, P.Min);
  CheckEquals(100, P.Max);
  CheckEquals(40, P.Position);
  CheckEquals(1, FChanges, 'nur die gueltige Positionsaenderung');
end;

procedure TRangeTests.SetRangeSetsBothBounds;
var
  P: TPPGProgressBar;
begin
  P := NewProgress;
  P.Position := 20;
  FChanges := 0;
  P.SetRange(200, 300); // einzeln waere Min = 200 > Max = 100 ungueltig
  CheckEquals(200, P.Min);
  CheckEquals(300, P.Max);
  CheckEquals(200, P.Position, 'Position folgt dem Bereich');
  CheckEquals(1, FChanges);
  try
    P.SetRange(10, 5);
    Fail('EPPGPropertyError erwartet');
  except
    on E: EPPGPropertyError do
      ;
  end;
  CheckEquals(200, P.Min);
  CheckEquals(300, P.Max);
end;

procedure TRangeTests.OnChangeOnlyOnRealChange;
var
  T: TPPGTrackBar;
begin
  T := NewTrack;
  T.Position := 0;
  CheckEquals(0, FChanges, 'gleicher Wert');
  T.Position := 3;
  CheckEquals(1, FChanges);
  T.Position := 99; // -> 10
  CheckEquals(2, FChanges);
  T.Position := 50; // geklemmt auf 10 = unveraendert
  CheckEquals(2, FChanges);
end;

procedure TRangeTests.LoadsInAnyOrderWithoutEvents;
var
  P: TPPGProgressBar;
  T: TPPGTrackBar;
begin
  // Min vor Max mit Min > Vorgabe-Max: darf beim Laden NICHT scheitern
  P := TPPGProgressBar.Create(FForm);
  P.OnChange := CountChange;
  LoadDfm(
    'object PB: TPPGProgressBar'#13#10 +
    '  Min = 200'#13#10 +
    '  Max = 300'#13#10 +
    '  Position = 250'#13#10 +
    'end', P);
  CheckEquals(200, P.Min);
  CheckEquals(300, P.Max);
  CheckEquals(250, P.Position);
  // Position vor Max (von Hand bearbeitete DFM)
  T := TPPGTrackBar.Create(FForm);
  T.OnChange := CountChange;
  LoadDfm(
    'object TB: TPPGTrackBar'#13#10 +
    '  Position = 40'#13#10 +
    '  Max = 50'#13#10 +
    'end', T);
  CheckEquals(40, T.Position);
  CheckEquals(0, FChanges, 'Beim Laden kein OnChange');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TRangeTests.InconsistentDfmIsRepaired;
var
  P: TPPGProgressBar;
begin
  P := TPPGProgressBar.Create(FForm);
  LoadDfm(
    'object PB: TPPGProgressBar'#13#10 +
    '  Min = 50'#13#10 +
    '  Max = 10'#13#10 +
    '  Position = 99'#13#10 +
    'end', P);
  // Formular muss sich oeffnen lassen: reparieren + protokollieren, nicht werfen
  CheckEquals(50, P.Min);
  CheckEquals(50, P.Max);
  CheckEquals(50, P.Position);
end;

procedure TRangeTests.InvalidValuesRaiseAndKeepState;

  procedure Expect(const Prop: string; Proc: TProc);
  begin
    try
      Proc();
      Fail(Prop + ': EPPGPropertyError erwartet');
    except
      on E: EPPGPropertyError do
        CheckEquals(Prop, E.PropertyName);
    end;
  end;

var
  P: TPPGProgressBar;
  T: TPPGTrackBar;
begin
  P := NewProgress;
  T := NewTrack;
  Expect('MarqueeInterval', procedure begin P.MarqueeInterval := 0; end);
  Expect('Frequency', procedure begin T.Frequency := 0; end);
  Expect('LineSize', procedure begin T.LineSize := -1; end);
  Expect('PageSize', procedure begin T.PageSize := 0; end);
  Expect('ThumbLength', procedure begin T.ThumbLength := 2; end);
  CheckEquals(10, P.MarqueeInterval);
  CheckEquals(1, T.Frequency);
  CheckEquals(1, T.LineSize);
  CheckEquals(2, T.PageSize);
  CheckEquals(20, T.ThumbLength);
end;

procedure TRangeTests.HugeRangeDoesNotOverflow;
var
  P: TPPGProgressBar;
  T: TPPGTrackBar;
begin
  P := NewProgress;
  P.SetRange(Low(Integer), High(Integer));
  P.Position := 0;
  CheckEquals(50, P.Percent);
  P.ShowText := True;
  RenderToBitmap(P).Free;
  T := NewTrack;
  T.SetRange(Low(Integer), High(Integer));
  T.Position := High(Integer);
  T.Perform(WM_KEYDOWN, VK_RIGHT, 0); // darf nicht ueberlaufen
  CheckEquals(High(Integer), T.Position);
  T.Perform(WM_KEYDOWN, VK_HOME, 0);
  CheckEquals(Low(Integer), T.Position);
  RenderToBitmap(T).Free; // Ticks: zu dicht -> nur die Enden
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TRangeTests.RoundTripKeepsAllProperties;
var
  A, B: TPPGProgressBar;
  TA, TB: TPPGTrackBar;
  S: TMemoryStream;
begin
  A := NewProgress;
  A.SetRange(5, 500);
  A.Position := 123;
  A.Step := 7;
  A.Orientation := pbVertical;
  A.Style := pbstMarquee;
  A.State := pbsPaused;
  A.MarqueeInterval := 20;
  A.ShowText := True;
  A.Appearance.Checked.Color := clRed;
  B := nil;
  S := TMemoryStream.Create;
  try
    S.WriteComponent(A);
    S.Position := 0;
    // Ohne Owner: zwei unbenannte gelesene Komponenten hiessen sonst beide "_1"
    B := TPPGProgressBar.Create(nil);
    S.ReadComponent(B);
    CheckEquals(5, B.Min);
    CheckEquals(500, B.Max);
    CheckEquals(123, B.Position);
    CheckEquals(7, B.Step);
    CheckTrue(B.Orientation = pbVertical);
    CheckTrue(B.Style = pbstMarquee);
    CheckTrue(B.State = pbsPaused);
    CheckEquals(20, B.MarqueeInterval);
    CheckTrue(B.ShowText);
    CheckTrue(A.Appearance.Equals(B.Appearance));
  finally
    B.Free;
    S.Free;
  end;

  TA := NewTrack;
  TA.SetRange(-10, 10);
  TA.Position := -3;
  TA.Frequency := 5;
  TA.LineSize := 2;
  TA.PageSize := 4;
  TA.TickMarks := tmBoth;
  TA.TickStyle := tsManual;
  TA.ThumbLength := 26;
  TA.ShowSlider := False;
  TB := nil;
  S := TMemoryStream.Create;
  try
    S.WriteComponent(TA);
    S.Position := 0;
    TB := TPPGTrackBar.Create(nil);
    S.ReadComponent(TB);
    CheckEquals(-10, TB.Min);
    CheckEquals(10, TB.Max);
    CheckEquals(-3, TB.Position);
    CheckEquals(5, TB.Frequency);
    CheckEquals(2, TB.LineSize);
    CheckEquals(4, TB.PageSize);
    CheckTrue(TB.TickMarks = tmBoth);
    CheckTrue(TB.TickStyle = tsManual);
    CheckEquals(26, TB.ThumbLength);
    CheckFalse(TB.ShowSlider);
  finally
    TB.Free;
    S.Free;
  end;
end;

{ TProgressBarTests }

procedure TProgressBarTests.FillFollowsPositionGdiPlusAndGdi;
var
  P: TPPGProgressBar;
  Bmp: TBitmap;
  G: Integer;
begin
  for G := 0 to 1 do
  begin
    TPPGRendererRegistry.ForceGdiFallback := G = 1;
    P := NewProgress(200, 20);
    P.Position := 50;
    Bmp := RenderToBitmap(P);
    try
      CheckTrue(ColorDist(Bmp.Canvas.Pixels[50, 10], P.Appearance.Checked.Color) < 30,
        'gefuellt (G=' + IntToStr(G) + ')');
      CheckTrue(ColorDist(Bmp.Canvas.Pixels[150, 10], P.Appearance.Normal.Color) < 30,
        'leer (G=' + IntToStr(G) + ')');
    finally
      Bmp.Free;
    end;
    P.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TProgressBarTests.RightToLeftAndVerticalFillFromTheEnd;
var
  P: TPPGProgressBar;
  Bmp: TBitmap;
begin
  P := NewProgress(200, 20);
  P.Position := 25;
  P.BiDiMode := bdRightToLeft;
  Bmp := RenderToBitmap(P);
  try
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[180, 10], P.Appearance.Checked.Color) < 30, 'RTL: rechts gefuellt');
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[20, 10], P.Appearance.Normal.Color) < 30, 'RTL: links leer');
  finally
    Bmp.Free;
  end;
  P.BiDiMode := bdLeftToRight;
  P.Orientation := pbVertical;
  P.SetBounds(10, 10, 20, 200);
  Bmp := RenderToBitmap(P);
  try
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[10, 180], P.Appearance.Checked.Color) < 30, 'vertikal: unten gefuellt');
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[10, 20], P.Appearance.Normal.Color) < 30, 'vertikal: oben leer');
  finally
    Bmp.Free;
  end;
end;

procedure TProgressBarTests.TextOnFillUsesFillTextColor;
var
  P: TPPGProgressBar;
  Bmp: TBitmap;
  X, Y, Light: Integer;
  C: Cardinal;
begin
  // Regression: der zweifarbige Text war im GDI+-Canvas einfarbig dunkel,
  // weil GDI-Text die GDI+-Clipregion nicht beachtete
  P := NewProgress(200, 24);
  P.Caption := 'MMMMMMMMMMMM';
  P.Font.Style := [fsBold];
  P.ShowText := True;
  P.Position := 100; // ganzer Text auf der Fuellung
  Bmp := RenderToBitmap(P);
  try
    Light := 0;
    for X := 40 to 160 do
      for Y := 6 to 18 do
      begin
        C := ColorToRGB(Bmp.Canvas.Pixels[X, Y]);
        if (GetRValue(C) > 200) and (GetGValue(C) > 200) and (GetBValue(C) > 200) then
          Inc(Light);
      end;
    CheckTrue(Light > 20, Format('auf der Fuellung muss heller Text stehen (%d Pixel)', [Light]));
  finally
    Bmp.Free;
  end;
end;

procedure TProgressBarTests.GdiTextRespectsCanvasClip;
var
  Bmp: TBitmap;
  C: IPPGCanvas;
  G, X, Y, Dark: Integer;
begin
  for G := 0 to 1 do
  begin
    TPPGRendererRegistry.ForceGdiFallback := G = 1;
    Bmp := TBitmap.Create;
    try
      Bmp.PixelFormat := pf24bit;
      Bmp.SetSize(200, 30);
      Bmp.Canvas.Brush.Color := clWhite;
      Bmp.Canvas.FillRect(Rect(0, 0, 200, 30));
      Bmp.Canvas.Lock;
      try
        C := TPPGRendererRegistry.CreateCanvas(Bmp.Canvas.Handle);
        C.PushClipRoundRect(Rect(0, 0, 100, 30), 0);
        try
          C.DrawText(Rect(0, 0, 200, 30), 'MMMMMMMMMMMMMMMMMMMMMMMM', Bmp.Canvas.Font, clBlack,
            DT_LEFT or DT_VCENTER or DT_SINGLELINE);
        finally
          C.PopClip;
        end;
        C := nil;
      finally
        Bmp.Canvas.Unlock;
      end;
      Dark := 0;
      for X := 105 to 199 do
        for Y := 0 to 29 do
          if ColorToRGB(Bmp.Canvas.Pixels[X, Y]) <> clWhite then
            Inc(Dark);
      CheckEquals(0, Dark, 'Text ausserhalb des Clips (G=' + IntToStr(G) + ')');
    finally
      Bmp.Free;
    end;
  end;
end;

procedure TProgressBarTests.ErrorStateIsRed;
var
  P: TPPGProgressBar;
  Bmp: TBitmap;
  C: Cardinal;
begin
  P := NewProgress(200, 20);
  P.Position := 100;
  P.State := pbsError;
  Bmp := RenderToBitmap(P);
  try
    C := ColorToRGB(Bmp.Canvas.Pixels[100, 10]);
    CheckTrue((GetRValue(C) > 180) and (GetGValue(C) < 80) and (GetBValue(C) < 80),
      Format('Fehlerzustand muss rot sein (%.6x)', [C]));
  finally
    Bmp.Free;
  end;
end;

procedure TProgressBarTests.StepItAndStepBy;
var
  P: TPPGProgressBar;
begin
  P := NewProgress;
  P.StepIt;
  CheckEquals(10, P.Position);
  P.Step := 25;
  P.StepIt;
  CheckEquals(35, P.Position);
  P.StepBy(-40);
  CheckEquals(0, P.Position);
  P.StepBy(1000);
  CheckEquals(100, P.Position);
  CheckEquals(4, FChanges);
end;

procedure TProgressBarTests.MarqueeRunsOnlyWhileShowing;
var
  P: TPPGProgressBar;
begin
  P := NewProgress;
  P.Animation.Enabled := True;
  P.Animation.RespectSystemSettings := False;
  P.Style := pbstMarquee;
  CheckFalse(P.MarqueeRunning, 'Formular unsichtbar: keine Animation');
  FForm.Show;
  try
    CheckTrue(P.MarqueeRunning, 'sichtbar: Marquee laeuft');
    CheckTrue(PPGRunningAnimationCount > 0);
    P.Visible := False;
    CheckFalse(P.MarqueeRunning, 'Control versteckt: anhalten');
    P.Visible := True;
    CheckTrue(P.MarqueeRunning);
    P.Style := pbstNormal;
    CheckFalse(P.MarqueeRunning, 'Normal-Stil: anhalten');
    P.Style := pbstMarquee;
    CheckTrue(P.MarqueeRunning);
    P.Free; // laufende Schleife muss sauber abgemeldet werden
    CheckEquals(0, PPGRunningAnimationCount, 'Animation nicht abgemeldet');
    Application.ProcessMessages;
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TProgressBarTests.MarqueeIsStaticWithoutAnimation;
var
  P: TPPGProgressBar;
  Bmp: TBitmap;
begin
  P := NewProgress(200, 20);
  P.Style := pbstMarquee; // Animation.Enabled = False
  FForm.Show;
  try
    CheckFalse(P.MarqueeRunning, 'ohne Animation keine Schleife');
    Bmp := RenderToBitmap(P);
    try
      CheckTrue(ColorDist(Bmp.Canvas.Pixels[100, 10], P.Appearance.Checked.Color) < 30, 'Segment in der Mitte');
      CheckTrue(ColorDist(Bmp.Canvas.Pixels[20, 10], P.Appearance.Normal.Color) < 30, 'Rand frei');
    finally
      Bmp.Free;
    end;
    // Animation wieder an -> Schleife startet (Einstellungs-Aenderung kommt an)
    P.Animation.RespectSystemSettings := False;
    P.Animation.Enabled := True;
    CheckTrue(P.MarqueeRunning, 'Einschalten der Animation startet die Schleife');
  finally
    FForm.Hide;
  end;
end;

procedure TProgressBarTests.PositionAnimatesOnlyWhenVisible;
var
  P: TPPGProgressBar;
begin
  P := NewProgress;
  P.Animation.Enabled := True;
  P.Animation.RespectSystemSettings := False;
  P.Animation.Duration := 2000;
  P.Position := 80; // unsichtbar
  CheckEquals(80.0, TPBAccess(P).DisplayPosition, 0.001, 'unsichtbar: sofort');
  FForm.Show;
  try
    P.Position := 20;
    CheckEquals(20, P.Position, 'Position ist sofort gesetzt');
    CheckTrue(TPBAccess(P).DisplayPosition > 70, 'Anzeige gleitet');
    P.Free;
    CheckEquals(0, PPGRunningAnimationCount);
  finally
    FForm.Hide;
  end;
end;

procedure TProgressBarTests.AccessibilityRoleAndValue;
var
  P: TPPGProgressBar;
  Acc: IAccessible;
  W: WideString;
begin
  P := NewProgress;
  P.Position := 42;
  Acc := AccOf(P);
  CheckEquals(ROLE_SYSTEM_PROGRESSBAR, AccRole(Acc));
  CheckTrue((AccState(Acc) and STATE_SYSTEM_READONLY) <> 0);
  CheckTrue((AccState(Acc) and STATE_SYSTEM_FOCUSABLE) = 0);
  CheckEquals(S_OK, Acc.Get_accValue(CHILDID_SELF, W));
  CheckEquals(Format(SPPGPercentFormat, [42]), string(W));
  P.Style := pbstMarquee;
  CheckTrue((AccState(Acc) and STATE_SYSTEM_BUSY) <> 0, 'Marquee = beschaeftigt');
end;

{ TTrackBarTests }

procedure TTrackBarTests.KeyboardMovesByLineAndPage;
var
  T: TPPGTrackBar;
begin
  T := NewTrack;
  T.Position := 5;
  T.Perform(WM_KEYDOWN, VK_RIGHT, 0);
  CheckEquals(6, T.Position);
  T.Perform(WM_KEYDOWN, VK_LEFT, 0);
  CheckEquals(5, T.Position);
  T.Perform(WM_KEYDOWN, VK_DOWN, 0);
  CheckEquals(6, T.Position, 'runter erhoeht (wie TTrackBar)');
  T.Perform(WM_KEYDOWN, VK_UP, 0);
  CheckEquals(5, T.Position);
  T.Perform(WM_KEYDOWN, VK_NEXT, 0);
  CheckEquals(7, T.Position, 'Bild ab = PageSize');
  T.Perform(WM_KEYDOWN, VK_PRIOR, 0);
  CheckEquals(5, T.Position);
  T.Perform(WM_KEYDOWN, VK_END, 0);
  CheckEquals(10, T.Position);
  T.Perform(WM_KEYDOWN, VK_RIGHT, 0);
  CheckEquals(10, T.Position, 'am Ende geklemmt');
  T.Perform(WM_KEYDOWN, VK_HOME, 0);
  CheckEquals(0, T.Position);
  CheckEquals(9, FChanges, 'Startwert + 8 Tastendruecke, das geklemmte Rechts zaehlt nicht');
end;

procedure TTrackBarTests.RightToLeftMirrorsArrowKeys;
var
  T: TPPGTrackBar;
begin
  T := NewTrack;
  T.BiDiMode := bdRightToLeft;
  T.Position := 5;
  T.Perform(WM_KEYDOWN, VK_LEFT, 0);
  CheckEquals(6, T.Position, 'RTL: links = Richtung Max');
  T.Perform(WM_KEYDOWN, VK_RIGHT, 0);
  CheckEquals(5, T.Position);
end;

procedure TTrackBarTests.WantsArrowKeys;
var
  T: TPPGTrackBar;
begin
  T := NewTrack;
  CheckTrue((T.Perform(WM_GETDLGCODE, 0, 0) and DLGC_WANTARROWS) <> 0);
end;

procedure TTrackBarTests.ClickOnTrackJumpsAndDrags;
var
  T: TPPGTrackBar;
  G: TPPGSliderGeometry;
  X, Y: Integer;
begin
  T := NewTrack;
  G := TTBAccess(T).GetGeometry;
  Y := G.Center;
  // Klick bei 70 % der Strecke -> Wert 7
  X := G.TravelStart + Round((G.TravelEnd - G.TravelStart) * 0.7);
  T.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(X, Y));
  CheckEquals(7, T.Position, 'Sprung an die Klickposition');
  CheckTrue(T.Dragging);
  CheckTrue(T.VisualState = vsDown);
  X := G.TravelStart + Round((G.TravelEnd - G.TravelStart) * 0.2);
  T.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(X, Y));
  CheckEquals(2, T.Position, 'Ziehen');
  T.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(-500, Y));
  CheckEquals(0, T.Position, 'ausserhalb: am Anfang geklemmt');
  T.Perform(WM_LBUTTONUP, 0, MouseLParam(-500, Y));
  CheckFalse(T.Dragging);
  CheckTrue(T.VisualState <> vsDown);
  T.Perform(WM_MOUSEMOVE, 0, MakeLParam(X, Y));
  CheckEquals(0, T.Position, 'nach dem Loslassen kein Ziehen mehr');
  CheckEquals(3, FChanges);
end;

procedure TTrackBarTests.GrabbingThumbDoesNotJump;
var
  T: TPPGTrackBar;
  R: TRect;
begin
  T := NewTrack;
  T.Position := 4;
  FChanges := 0;
  R := TTBAccess(T).ThumbRect;
  // Griff etwas neben der Mitte packen: Wert bleibt
  T.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(R.Left + 4, (R.Top + R.Bottom) div 2));
  CheckEquals(4, T.Position);
  CheckTrue(T.Dragging);
  T.Perform(WM_LBUTTONUP, 0, MakeLParam(R.Left + 4, (R.Top + R.Bottom) div 2));
  CheckEquals(0, FChanges);
end;

procedure TTrackBarTests.MouseWheelUsesLineSize;
var
  T: TPPGTrackBar;
begin
  T := NewTrack;
  T.LineSize := 3;
  T.Position := 5;
  // Audit 7b: das Rad aendert den Wert nur mit Fokus
  FForm.Show;
  T.SetFocus;
  CheckTrue(TTBAccess(T).DoMouseWheelDown([], Point(0, 0)));
  CheckEquals(8, T.Position, 'Rad runter = groesser (wie TTrackBar)');
  TTBAccess(T).DoMouseWheelUp([], Point(0, 0));
  CheckEquals(5, T.Position);
end;

procedure TTrackBarTests.DisabledIgnoresInput;
var
  T: TPPGTrackBar;
  G: TPPGSliderGeometry;
begin
  T := NewTrack;
  T.Enabled := False;
  T.Perform(WM_KEYDOWN, VK_END, 0);
  G := TTBAccess(T).GetGeometry;
  T.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(G.TravelEnd, G.Center));
  T.Perform(WM_LBUTTONUP, 0, MakeLParam(G.TravelEnd, G.Center));
  TTBAccess(T).DoMouseWheelDown([], Point(0, 0));
  CheckEquals(0, T.Position);
  CheckEquals(0, FChanges);
end;

procedure TTrackBarTests.ExceptionInOnChangeKeepsPosition;
var
  T: TPPGTrackBar;
begin
  T := NewTrack;
  T.OnChange := RaisingChange;
  try
    T.Perform(WM_KEYDOWN, VK_RIGHT, 0);
    Fail('Exception aus OnChange muss propagieren');
  except
    on E: EAbort do
      ;
  end;
  CheckEquals(1, T.Position, 'Wert wurde vor dem Ereignis gesetzt');
end;

procedure TTrackBarTests.VerticalHasMinAtTopAndSwapsSize;
var
  T: TPPGTrackBar;
  R0, R1: TRect;
begin
  T := NewTrack(200, 40);
  T.Orientation := trVertical;
  CheckEquals(40, T.Width, 'Breite/Hoehe getauscht (wie TTrackBar)');
  CheckEquals(200, T.Height);
  R0 := TTBAccess(T).ThumbRect;
  T.Position := T.Max;
  R1 := TTBAccess(T).ThumbRect;
  CheckTrue(R0.Top < R1.Top, 'Min oben, Max unten');
  RenderToBitmap(T).Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TTrackBarTests.ThumbAndFillArePaintedAtPosition;
var
  T: TPPGTrackBar;
  G: TPPGSliderGeometry;
  R: TRect;
  Bmp: TBitmap;
  CX, CY, X: Integer;
begin
  T := NewTrack;
  T.Position := 5;
  G := TTBAccess(T).GetGeometry;
  R := TTBAccess(T).ThumbRect;
  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;
  Bmp := RenderToBitmap(T);
  try
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[CX, CY], T.Appearance.Checked.BorderColor) < 40,
      'innerer Punkt in Akzentfarbe');
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[R.Left + (R.Right - R.Left) div 5, CY],
      T.Appearance.Normal.Color) < 40, 'Griff in Normal-Farbe');
    X := (G.TravelStart + R.Left) div 2;
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[X, G.Center], T.Appearance.Checked.BorderColor) < 40,
      'Schiene links vom Griff gefuellt');
    X := (G.TravelEnd + R.Right) div 2;
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[X, G.Center], T.Appearance.Normal.BorderColor) < 40,
      'Schiene rechts vom Griff leer');
  finally
    Bmp.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TTrackBarTests.AutoSizeAdjustsThicknessOnly;
var
  T: TPPGTrackBar;
  H1: Integer;
begin
  T := NewTrack(300, 80);
  T.AutoSize := True;
  CheckEquals(300, T.Width, 'Laenge bleibt');
  CheckTrue(T.Height < 80, 'Dicke passt sich an');
  H1 := T.Height;
  T.TickStyle := tsNone;
  CheckTrue(T.Height < H1, 'ohne Ticks duenner');
  T.ThumbLength := 40;
  CheckTrue(T.Height >= 40, 'groesserer Griff braucht Platz');
end;

procedure TTrackBarTests.AccessibilityRoleAndValue;
var
  T: TPPGTrackBar;
  Acc: IAccessible;
  W: WideString;
begin
  T := NewTrack;
  T.Position := 3;
  Acc := AccOf(T);
  CheckEquals(ROLE_SYSTEM_SLIDER, AccRole(Acc));
  CheckTrue((AccState(Acc) and STATE_SYSTEM_FOCUSABLE) <> 0);
  CheckEquals(S_OK, Acc.Get_accValue(CHILDID_SELF, W));
  CheckEquals('3', string(W));
end;

{ TContainerTests }

procedure TContainerTests.AcceptsControlsAndClipsChildren;
var
  P: TPPGPanel;
  G: TPPGGroupBox;
begin
  P := NewPanel;
  G := NewGroup;
  CheckTrue(csAcceptsControls in P.ControlStyle);
  CheckTrue(csAcceptsControls in G.ControlStyle);
  CheckTrue((GetWindowLong(P.Handle, GWL_STYLE) and WS_CLIPCHILDREN) <> 0, 'Panel: WS_CLIPCHILDREN');
  CheckTrue((GetWindowLong(G.Handle, GWL_EXSTYLE) and WS_EX_CONTROLPARENT) <> 0,
    'GroupBox: Tab-Navigation in die Kinder');
  CheckFalse(P.TabStop);
end;

procedure TContainerTests.AlignedChildStaysInsideBorderAndRounding;
var
  P: TPPGPanel;
  C: TPanel;
  D: Integer;
begin
  P := NewPanel;
  P.Appearance.Rounding := 10;
  P.Appearance.BorderWidth := 1;
  C := TPanel.Create(FForm);
  C.Parent := P;
  C.Align := alClient;
  D := TPanelAccess(P).ContentInset;
  // Rechteck-Ecke ausserhalb der Rundung: Versatz >= r * (1 - 1/Wurzel 2)
  CheckTrue(D >= 1 + Ceil(10 * 0.293), Format('Abstand %d zu klein', [D]));
  CheckEquals(D, C.Left);
  CheckEquals(D, C.Top);
  CheckEquals(P.ClientWidth - 2 * D, C.Width);
  CheckEquals(P.ClientHeight - 2 * D, C.Height);
end;

procedure TContainerTests.PaddingIsAddedToInset;
var
  P: TPPGPanel;
  C: TPanel;
  D: Integer;
begin
  P := NewPanel;
  C := TPanel.Create(FForm);
  C.Parent := P;
  C.Align := alClient;
  D := TPanelAccess(P).ContentInset;
  P.Padding.Left := 7;
  CheckEquals(D + 7, C.Left);
end;

procedure TContainerTests.AppearanceChangeRealignsChildren;
var
  P: TPPGPanel;
  C: TPanel;
  L0: Integer;
begin
  P := NewPanel;
  C := TPanel.Create(FForm);
  C.Parent := P;
  C.Align := alClient;
  L0 := C.Left;
  P.Appearance.BorderWidth := 6;
  CheckTrue(C.Left >= L0 + 5, 'dickerer Rahmen muss Kinder verschieben');
end;

procedure TContainerTests.GroupBoxChildrenStartBelowCaption;
var
  G: TPPGGroupBox;
  C: TPanel;
  Plate: TRect;
  BodyTop, T0: Integer;
begin
  G := NewGroup('Optionen');
  C := TPanel.Create(FForm);
  C.Parent := G;
  C.Align := alClient;
  TGroupAccess(G).GetHeader(Plate, BodyTop);
  CheckFalse(IsRectEmpty(Plate), 'Plakette erwartet');
  CheckTrue(C.Top >= Plate.Bottom, 'Kind darf nicht unter der Beschriftung liegen');
  T0 := C.Top;
  G.Caption := '';
  CheckTrue(C.Top < T0, 'ohne Caption rueckt der Inhalt nach oben');
end;

procedure TContainerTests.GroupBoxFontChangeRealigns;
var
  G: TPPGGroupBox;
  C: TPanel;
  T0: Integer;
begin
  G := NewGroup('Gross');
  C := TPanel.Create(FForm);
  C.Parent := G;
  C.Align := alClient;
  T0 := C.Top;
  G.Font.Size := G.Font.Size * 3;
  CheckTrue(C.Top > T0 + 10, Format('Kind folgt der Schrift nicht: %d -> %d', [T0, C.Top]));
end;

procedure TContainerTests.NoHoverAnimationOnContainers;
var
  P: TPPGPanel;
  G: TPPGGroupBox;
begin
  P := NewPanel;
  G := NewGroup;
  TPanelAccess(P).Animation.RespectSystemSettings := False;
  TGroupAccess(G).Animation.RespectSystemSettings := False;
  P.Perform(CM_MOUSEENTER, 0, 0);
  G.Perform(CM_MOUSEENTER, 0, 0);
  CheckEquals(0, PPGRunningAnimationCount, 'Container reagieren nicht auf Hover');
  CheckTrue(P.VisualState = vsNormal);
end;

procedure TContainerTests.GroupBoxAcceleratorFocusesFirstChild;
var
  G: TPPGGroupBox;
  C: TPPGCheckBox;
begin
  FForm.Show;
  try
    G := NewGroup('&Optionen');
    C := TPPGCheckBox.Create(FForm);
    C.Parent := G;
    C.Caption := 'Eins';
    CheckEquals(1, G.Perform(CM_DIALOGCHAR, Ord('o'), 0));
    CheckTrue(C.Focused, 'wie TGroupBox: erstes Kind fokussieren');
    CheckFalse(C.Checked, 'nur fokussieren, nicht umschalten');
  finally
    FForm.Hide;
  end;
end;

procedure TContainerTests.GroupBoxTracksFocusInside;
var
  G: TPPGGroupBox;
  Inner, Outer: TPPGButton;
begin
  FForm.Show;
  try
    G := NewGroup;
    Inner := TPPGButton.Create(FForm);
    Inner.Parent := G;
    Outer := NewButton('Aussen');
    Outer.Top := 200;
    Inner.SetFocus;
    CheckTrue(G.FocusInside, 'Fokus im Kind');
    Outer.SetFocus;
    CheckFalse(G.FocusInside, 'Fokus ausserhalb');
    G.HighlightFocus := True;
    Inner.SetFocus;
    RenderToBitmap(G).Free;
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TContainerTests.ChildPaintsOnPanelBackground;
var
  P: TPPGPanel;
  B: TPPGButton;
  Bmp: TBitmap;
begin
  // Abgerundete Ecken des Buttons zeigen den PANEL-Hintergrund (WM_PRINTCLIENT
  // an das Panel), nicht die Formularfarbe
  if not StyleServices.Enabled then
  begin
    Status('Themes nicht aktiv - Eltern-Hintergrund wird nicht uebernommen');
    Exit;
  end;
  FForm.Color := clRed;
  P := NewPanel;
  P.Appearance.Normal.Color := clLime;
  B := TPPGButton.Create(FForm);
  B.Parent := P;
  B.SetBounds(20, 20, 120, 36);
  B.Animation.Enabled := False;
  Bmp := RenderToBitmap(B);
  try
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[0, 0], clLime) < 40,
      Format('Ecke zeigt %.6x statt Panel-Farbe', [ColorToRGB(Bmp.Canvas.Pixels[0, 0])]));
  finally
    Bmp.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TContainerTests.LoadsVclStyleDfms;
var
  P: TPPGPanel;
  G: TPPGGroupBox;
  T: TPPGTrackBar;
  PB: TPPGProgressBar;
begin
  // Typische Zeilen aus TPanel-/TGroupBox-/TTrackBar-/TProgressBar-DFMs:
  // nach Suchen/Ersetzen des Klassennamens muessen sie ladbar bleiben
  P := TPPGPanel.Create(FForm);
  LoadDfm(
    'object P: TPPGPanel'#13#10 +
    '  BevelOuter = bvNone'#13#10 +
    '  Caption = ''Kopf'''#13#10 +
    '  Alignment = taLeftJustify'#13#10 +
    '  VerticalAlignment = taAlignTop'#13#10 +
    '  ShowCaption = False'#13#10 +
    '  Padding.Left = 3'#13#10 +
    '  ParentBackground = False'#13#10 +
    'end', P);
  CheckEquals('Kopf', P.Caption);
  CheckTrue(P.Alignment = taLeftJustify);
  CheckFalse(P.ShowCaption);
  CheckEquals(3, P.Padding.Left);
  G := TPPGGroupBox.Create(FForm);
  LoadDfm(
    'object G: TPPGGroupBox'#13#10 +
    '  Caption = ''Optionen'''#13#10 +
    '  TabOrder = 1'#13#10 +
    'end', G);
  CheckEquals('Optionen', G.Caption);
  T := TPPGTrackBar.Create(FForm);
  LoadDfm(
    'object T: TPPGTrackBar'#13#10 +
    '  Max = 20'#13#10 +
    '  Orientation = trVertical'#13#10 +
    '  Frequency = 5'#13#10 +
    '  TickMarks = tmBoth'#13#10 +
    '  ThumbLength = 18'#13#10 +
    'end', T);
  CheckEquals(20, T.Max);
  CheckTrue(T.Orientation = trVertical);
  PB := TPPGProgressBar.Create(FForm);
  LoadDfm(
    'object PB: TPPGProgressBar'#13#10 +
    '  Smooth = True'#13#10 +
    '  Style = pbstMarquee'#13#10 +
    '  State = pbsError'#13#10 +
    '  MarqueeInterval = 30'#13#10 +
    'end', PB);
  CheckTrue(PB.Style = pbstMarquee);
  CheckEquals(30, PB.MarqueeInterval);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TContainerTests.AccessibilityExposesChildren;
var
  P: TPPGPanel;
  G: TPPGGroupBox;
  B: TPPGButton;
  Acc: IAccessible;
  Count: Integer;
  Children: array[0..3] of OleVariant;
  Obtained: Integer;
  Child: IAccessible;
  I: Integer;
  Found: Boolean;
  W: WideString;
  Info: string;
begin
  G := NewGroup('Gruppe');
  CheckEquals(ROLE_SYSTEM_GROUPING, AccRole(AccOf(G)));
  CheckEquals('Gruppe', AccName(AccOf(G)));
  P := NewPanel;
  P.Top := 160;
  CheckEquals(ROLE_SYSTEM_PANE, AccRole(AccOf(P)));
  B := TPPGButton.Create(FForm);
  B.Parent := P;
  B.Caption := 'Innen';
  B.HandleNeeded;
  // Regression: TPPGAccessible meldete fest 0 Kinder -> Controls auf einem
  // PPGlow-Container waren fuer MSAA-Screenreader unsichtbar
  Acc := AccOf(P);
  CheckEquals(S_OK, Acc.Get_accChildCount(Count));
  CheckTrue(Count >= 1, 'Kind-Fenster muss gemeldet werden');
  // S_FALSE = weniger Kinder als angefordert, ebenfalls Erfolg
  CheckTrue(Succeeded(PPG_AccessibleChildren(Acc, 0, Length(Children), @Children[0], Obtained)));
  Found := False;
  Info := Format('Obtained=%d:', [Obtained]);
  for I := 0 to Obtained - 1 do
  begin
    Info := Info + Format(' vt=%d', [VarType(Children[I])]);
    if VarType(Children[I]) = varDispatch then
      if Supports(IDispatch(Children[I]), IAccessible, Child) then
      begin
        W := '';
        Child.Get_accName(CHILDID_SELF, W);
        Info := Info + ' name=' + string(W);
        if string(W) = 'Innen' then
          Found := True;
      end;
  end;
  CheckTrue(Found, 'Button auf dem Panel nicht ueber AccessibleChildren erreichbar: ' + Info);
end;

{ TPhase3PaintTests }

procedure TPhase3PaintTests.AllControlsAllVariantsPaintWithoutErrors;
const
  Presets: array[0..1] of string = (PPGPresetClassic, PPGPresetModernFlat);
var
  G, P, E, V: Integer;
  PB: TPPGProgressBar;
  T: TPPGTrackBar;
  Pn: TPPGPanel;
  Gb: TPPGGroupBox;
begin
  FForm.Show;
  try
    for G := 0 to 1 do
    begin
      TPPGRendererRegistry.ForceGdiFallback := G = 1;
      for P := 0 to High(Presets) do
        for E := 0 to 1 do
          for V := 0 to 3 do
          begin
            PB := NewProgress;
            PB.Preset := Presets[P];
            PB.Position := 60;
            PB.ShowText := True;
            PB.Enabled := E = 0;
            case V of
              1: PB.Style := pbstMarquee;
              2: begin PB.Orientation := pbVertical; PB.SetBounds(0, 0, 20, 120); end;
              3: begin PB.State := pbsPaused; PB.BiDiMode := bdRightToLeft; end;
            end;
            RenderToBitmap(PB).Free;
            PB.Free;

            T := NewTrack;
            T.Preset := Presets[P];
            T.Position := 3;
            T.Enabled := E = 0;
            case V of
              1: T.TickMarks := tmBoth;
              2: T.Orientation := trVertical;
              3: begin T.BiDiMode := bdRightToLeft; T.ShowSlider := False; end;
            end;
            if T.Enabled then
              T.SetFocus;
            T.Perform(CM_MOUSEENTER, 0, 0);
            RenderToBitmap(T).Free;
            T.Free;

            Pn := NewPanel;
            Pn.Preset := Presets[P];
            Pn.Caption := 'Panel';
            Pn.Enabled := E = 0;
            Pn.WordWrap := V = 1;
            Pn.Alignment := TAlignment(V mod 3);
            RenderToBitmap(Pn).Free;
            Pn.Free;

            Gb := NewGroup('&Gruppe');
            Gb.Preset := Presets[P];
            Gb.Enabled := E = 0;
            if V = 3 then
              Gb.BiDiMode := bdRightToLeft;
            RenderToBitmap(Gb).Free;
            Gb.Free;
          end;
    end;
  finally
    TPPGRendererRegistry.ForceGdiFallback := False;
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPhase3PaintTests.ExtremeSizesPaintWithoutErrors;
var
  PB: TPPGProgressBar;
  T: TPPGTrackBar;
  Pn: TPPGPanel;
  Gb: TPPGGroupBox;
  S: Integer;
begin
  PB := NewProgress;
  T := NewTrack;
  Pn := NewPanel;
  Gb := NewGroup('Sehr lange Beschriftung, die nicht passt');
  PB.Position := 50;
  PB.ShowText := True;
  Pn.Appearance.Rounding := PPGMaxRounding;
  Gb.Appearance.BorderWidth := PPGMaxBorderWidth;
  T.ThumbLength := 100;
  for S := 1 to 3 do
  begin
    PB.SetBounds(0, 0, S * 3 - 2, S * 3 - 2);
    T.SetBounds(0, 0, S * 3 - 2, S * 3 - 2);
    Pn.SetBounds(0, 0, S * 3 - 2, S * 3 - 2);
    Gb.SetBounds(0, 0, S * 3 - 2, S * 3 - 2);
    RenderToBitmap(PB).Free;
    RenderToBitmap(T).Free;
    RenderToBitmap(Pn).Free;
    RenderToBitmap(Gb).Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPhase3PaintTests.NoHandleOrMemoryLeaks;

  procedure Cycle;
  var
    I: Integer;
    PB: TPPGProgressBar;
    T: TPPGTrackBar;
    Pn: TPPGPanel;
    Gb: TPPGGroupBox;
    B: TPPGButton;
  begin
    for I := 1 to 30 do
    begin
      PB := NewProgress;
      PB.Position := I;
      PB.ShowText := True;
      RenderToBitmap(PB).Free;
      PB.Free;
      T := NewTrack;
      T.Perform(WM_KEYDOWN, VK_RIGHT, 0);
      RenderToBitmap(T).Free;
      T.Free;
      Pn := NewPanel;
      B := TPPGButton.Create(FForm);
      B.Parent := Pn;
      RenderToBitmap(Pn).Free;
      RenderToBitmap(B).Free;
      AccOf(Pn);
      Pn.Free; // gibt auch den Button frei
      Gb := NewGroup('Leak');
      RenderToBitmap(Gb).Free;
      Gb.Free;
    end;
  end;

var
  Gdi0, User0: Cardinal;
  M0, M1: NativeUInt;
begin
  Cycle;
  Gdi0 := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
  User0 := GetGuiResources(GetCurrentProcess, GR_USEROBJECTS);
  M0 := AllocatedBytes;
  Cycle;
  Cycle;
  M1 := AllocatedBytes;
  CheckTrue(GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS) <= Gdi0 + 2, 'GDI-Handles wachsen');
  CheckTrue(GetGuiResources(GetCurrentProcess, GR_USEROBJECTS) <= User0 + 2, 'USER-Handles wachsen');
  CheckTrue(M1 <= M0 + 1024, Format('Speicher waechst: %d -> %d', [M0, M1]));
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterTest('Phase3', TRangeTests.Suite);
  RegisterTest('Phase3', TProgressBarTests.Suite);
  RegisterTest('Phase3', TTrackBarTests.Suite);
  RegisterTest('Phase3', TContainerTests.Suite);
  RegisterTest('Phase3', TPhase3PaintTests.Suite);

end.
