unit PPG.Tests.Controls;

{ Integrations-Tests mit echten Fenstern (unsichtbares Formular):
  Lebenszyklus, Streaming, Zeichnen, Fehlergrenzen, Zustandsmaschine,
  Leaks und GDI-/USER-Handles. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.ImgList, Vcl.Menus,
  PPG.Types, PPG.Appearance, PPG.Exceptions, PPG.ErrorHandler, PPG.Consts,
  PPG.Render.Intf, PPG.Render.Registry, PPG.StyleManager, PPG.Controls.Base,
  PPG.Button, PPG.Animation;

type
  TControlTestCase = class(TTestCase)
  protected
    FForm: TForm;
    FErrors: TStringList;
    FAppExceptions: Integer;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure RecordError(Sender: TObject; E: Exception; const Context: string);
    procedure RecordAppException(Sender: TObject; E: Exception);
    function NewButton(const ACaption: string = ''): TPPGButton;
    function RenderToBitmap(C: TWinControl): TBitmap;
  end;

  TLifecycleTests = class(TControlTestCase)
  published
    procedure CreateAndFreeWithoutParent;
    procedure ImageListFreedBeforeButton;
    procedure StyleManagerFreedBeforeButton;
    procedure ButtonFreedBeforeStyleManager;
    procedure PopupMenuFreedBeforeButton;
    procedure FreeWhileAnimationRunning;
  end;

  TStyleTests = class(TControlTestCase)
  published
    procedure DefaultPresetIsApplied;
    procedure UnknownPresetAtRuntimeRaisesAndKeepsState;
    procedure PresetSwitchAppliesDefaults;
    procedure StyleManagerPropagatesToAllClients;
    procedure StyleManagerMakesAppearanceNotStored;
  end;

  TStreamingTests = class(TControlTestCase)
  private
    function LoadFromText(const DfmText: string): TPPGButton;
  published
    procedure RoundTripKeepsAllProperties;
    procedure UnknownPresetInDfmFallsBackToDefault;
    procedure OutOfRangeValueInDfmIsClamped;
    procedure GroupedDownSurvivesLoading;
  end;

  TPaintTests = class(TControlTestCase)
  published
    procedure PaintsPresetColorWithGdiPlus;
    procedure PaintsPresetColorWithGdiFallback;
    procedure PaintsExtremeSizesWithoutError;
    procedure RendererExceptionIsContainedAndReportedOnce;
    procedure PaintToBitmapWithCaptionAndFocusCues;
    procedure FocusBorderIsContinuous;
  end;

  TBehaviourTests = class(TControlTestCase)
  private
    FClicks: Integer;
    procedure CountClick(Sender: TObject);
    procedure RaisingClick(Sender: TObject);
  published
    procedure MouseClickFiresOnce;
    procedure ReleaseOutsideDoesNotClick;
    procedure ExceptionInOnClickLeavesNoPressedState;
    procedure SpaceKeyClicks;
    procedure AcceleratorClicks;
    procedure DisabledButtonIgnoresInput;
    procedure ModalResultIsSetOnForm;
    procedure GroupIsExclusive;
    procedure LastDownStaysWithoutAllowAllUp;
    procedure InvalidImageIndexRaises;
  end;

  TResourceTests = class(TControlTestCase)
  published
    procedure NoGdiOrUserHandleLeaks;
    procedure NoMemoryLeaks;
  end;

implementation

{$WARN SYMBOL_PLATFORM OFF}

type
  TButtonAccess = class(TPPGButton);

const
  GR_GDIOBJECTS = 0;
  GR_USEROBJECTS = 1;

type
  TRaisingRenderer = class(TPPGRendererBase)
  public
    function Name: string; override;
    procedure ApplyDefaults(Appearance: TPPGAppearance); override;
    procedure DrawSurface(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle); override;
  end;

function TRaisingRenderer.Name: string;
begin
  Result := 'Raising';
end;

procedure TRaisingRenderer.ApplyDefaults(Appearance: TPPGAppearance);
begin
end;

procedure TRaisingRenderer.DrawSurface(const Canvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle);
begin
  raise EPPGRenderError.Create('Simulated renderer failure');
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

function ColorDistance(A, B: TColor): Integer;
var
  CA, CB: Cardinal;
begin
  CA := ColorToRGB(A);
  CB := ColorToRGB(B);
  Result := Abs(GetRValue(CA) - GetRValue(CB)) + Abs(GetGValue(CA) - GetGValue(CB)) +
    Abs(GetBValue(CA) - GetBValue(CB));
end;

{ TControlTestCase }

procedure TControlTestCase.SetUp;
begin
  inherited;
  FErrors := TStringList.Create;
  FAppExceptions := 0;
  TPPGErrorHandler.OnError := RecordError;
  Application.OnException := RecordAppException;
  FForm := TForm.CreateNew(nil);
  FForm.SetBounds(0, 0, 400, 300);
  FForm.HandleNeeded;
end;

procedure TControlTestCase.TearDown;
begin
  FreeAndNil(FForm);
  TPPGErrorHandler.OnError := nil;
  Application.OnException := nil;
  TPPGRendererRegistry.ForceGdiFallback := False;
  FreeAndNil(FErrors);
  inherited;
end;

procedure TControlTestCase.RecordError(Sender: TObject; E: Exception; const Context: string);
begin
  FErrors.Add(Context);
end;

procedure TControlTestCase.RecordAppException(Sender: TObject; E: Exception);
begin
  Inc(FAppExceptions);
end;

function TControlTestCase.NewButton(const ACaption: string): TPPGButton;
begin
  Result := TPPGButton.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 120, 36);
  Result.Caption := ACaption;
  Result.Animation.Enabled := False; // deterministische Tests
  Result.HandleNeeded;
end;

function TControlTestCase.RenderToBitmap(C: TWinControl): TBitmap;
begin
  Result := TBitmap.Create;
  try
    Result.PixelFormat := pf24bit;
    Result.SetSize(C.Width, C.Height);
    // Lock: sonst gibt die VCL den Bitmap-DC frei, sobald waehrend PaintTo
    // Nachrichten verarbeitet werden (z.B. Neuaufbau des Fensters nach BiDiMode).
    Result.Canvas.Lock;
    try
      C.PaintTo(Result.Canvas.Handle, 0, 0);
    finally
      Result.Canvas.Unlock;
    end;
  except
    Result.Free;
    raise;
  end;
end;

{ TLifecycleTests }

procedure TLifecycleTests.CreateAndFreeWithoutParent;
var
  B: TPPGButton;
begin
  B := TPPGButton.Create(nil);
  try
    B.Caption := 'x';
    B.Appearance.Rounding := 3;
  finally
    B.Free;
  end;
  CheckEquals(0, FErrors.Count);
end;

procedure TLifecycleTests.ImageListFreedBeforeButton;
var
  B: TPPGButton;
  IL: TImageList;
  Bmp: TBitmap;
begin
  B := NewButton('img');
  IL := TImageList.Create(nil);
  IL.Width := 16;
  IL.Height := 16;
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(16, 16);
    IL.Add(Bmp, nil);
  finally
    Bmp.Free;
  end;
  B.Images := IL;
  B.ImageIndex := 0;
  IL.Free; // Images MUSS per Notification auf nil gehen
  CheckTrue(B.Images = nil, 'Images nicht zurueckgesetzt');
  RenderToBitmap(B).Free; // darf nicht crashen
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TLifecycleTests.StyleManagerFreedBeforeButton;
var
  B: TPPGButton;
  M: TPPGStyleManager;
begin
  B := NewButton;
  M := TPPGStyleManager.Create(nil);
  B.StyleManager := M;
  CheckEquals(1, M.ClientCount);
  M.Free;
  CheckTrue(B.StyleManager = nil, 'StyleManager nicht zurueckgesetzt');
  CheckTrue(B.IsStyleStored, 'ohne Manager muss die Optik wieder gespeichert werden');
  RenderToBitmap(B).Free;
end;

procedure TLifecycleTests.ButtonFreedBeforeStyleManager;
var
  B: TPPGButton;
  M: TPPGStyleManager;
begin
  M := TPPGStyleManager.Create(nil);
  try
    B := NewButton;
    B.StyleManager := M;
    CheckEquals(1, M.ClientCount);
    B.Free;
    CheckEquals(0, M.ClientCount, 'Client nicht abgemeldet');
    M.Preset := PPGPresetClassic; // darf keinen freigegebenen Client mehr ansprechen
  finally
    M.Free;
  end;
end;

procedure TLifecycleTests.PopupMenuFreedBeforeButton;
var
  B: TPPGButton;
  P: TPopupMenu;
begin
  B := NewButton;
  P := TPopupMenu.Create(nil);
  B.DropDownMenu := P;
  P.Free;
  CheckTrue(B.DropDownMenu = nil);
end;

procedure TLifecycleTests.FreeWhileAnimationRunning;
var
  B: TPPGButton;
begin
  B := NewButton;
  B.Animation.Enabled := True;
  B.Animation.RespectSystemSettings := False;
  B.Animation.Duration := 2000;
  B.Perform(CM_MOUSEENTER, 0, 0);
  CheckTrue(PPGRunningAnimationCount > 0, 'Animation sollte laufen');
  B.Free;
  CheckEquals(0, PPGRunningAnimationCount, 'Animation nicht abgemeldet');
  Application.ProcessMessages; // Timer-Tick darf nicht auf freigegebenes Objekt zugreifen
end;

{ TStyleTests }

procedure TStyleTests.DefaultPresetIsApplied;
var
  B: TPPGButton;
begin
  B := NewButton;
  CheckEquals(TPPGRendererRegistry.DefaultName, B.Preset);
  CheckTrue(B.Renderer <> nil);
end;

procedure TStyleTests.UnknownPresetAtRuntimeRaisesAndKeepsState;
var
  B: TPPGButton;
  Before: TPPGAppearance;
begin
  B := NewButton;
  Before := TPPGAppearance.Create(nil);
  try
    Before.Assign(B.Appearance);
    try
      B.Preset := 'DoesNotExist';
      Fail('EPPGPropertyError erwartet');
    except
      on E: EPPGPropertyError do
        CheckEquals('Preset', E.PropertyName);
    end;
    CheckEquals(TPPGRendererRegistry.DefaultName, B.Preset);
    CheckTrue(Before.Equals(B.Appearance), 'Appearance darf sich nicht aendern');
  finally
    Before.Free;
  end;
end;

procedure TStyleTests.PresetSwitchAppliesDefaults;
var
  B: TPPGButton;
  Expected: TPPGAppearance;
begin
  B := NewButton;
  B.Preset := PPGPresetClassic;
  Expected := TPPGAppearance.Create(nil);
  try
    TPPGRendererRegistry.Get(PPGPresetClassic).ApplyDefaults(Expected);
    CheckTrue(Expected.Equals(B.Appearance));
  finally
    Expected.Free;
  end;
end;

procedure TStyleTests.StyleManagerPropagatesToAllClients;
var
  B1, B2: TPPGButton;
  M: TPPGStyleManager;
begin
  M := TPPGStyleManager.Create(FForm);
  B1 := NewButton;
  B2 := NewButton;
  B1.StyleManager := M;
  B2.StyleManager := M;
  M.Preset := PPGPresetClassic;
  CheckEquals(PPGPresetClassic, B1.Preset);
  CheckEquals(PPGPresetClassic, B2.Preset);
  M.Appearance.Rounding := 11;
  CheckEquals(11, B1.Appearance.Rounding);
  CheckEquals(11, B2.Appearance.Rounding);
end;

procedure TStyleTests.StyleManagerMakesAppearanceNotStored;
var
  B: TPPGButton;
  M: TPPGStyleManager;
begin
  M := TPPGStyleManager.Create(FForm);
  B := NewButton;
  CheckTrue(B.IsStyleStored);
  B.StyleManager := M;
  CheckFalse(B.IsStyleStored);
  CheckFalse(B.IsPresetStored);
end;

{ TStreamingTests }

function TStreamingTests.LoadFromText(const DfmText: string): TPPGButton;
var
  Src: TStringStream;
  BinStream: TMemoryStream;
begin
  Src := TStringStream.Create(DfmText);
  BinStream := TMemoryStream.Create;
  try
    ObjectTextToBinary(Src, BinStream);
    BinStream.Position := 0;
    Result := TPPGButton.Create(FForm);
    try
      BinStream.ReadComponent(Result);
      Result.Parent := FForm;
    except
      Result.Free;
      raise;
    end;
  finally
    BinStream.Free;
    Src.Free;
  end;
end;

procedure TStreamingTests.RoundTripKeepsAllProperties;
var
  A, B: TPPGButton;
  S: TMemoryStream;
begin
  A := NewButton('&Save');
  A.Preset := PPGPresetClassic;
  A.Appearance.Hot.GlowAlpha := 123;
  A.Appearance.Rounding := 7;
  A.Spacing := 9;
  A.ImagePosition := ipTop;
  A.WordWrap := True;
  A.ModalResult := mrOk;
  A.Animation.Duration := 300;
  S := TMemoryStream.Create;
  try
    S.WriteComponent(A);
    S.Position := 0;
    B := TPPGButton.Create(FForm);
    S.ReadComponent(B);
    CheckEquals(A.Caption, B.Caption);
    CheckEquals(PPGPresetClassic, B.Preset);
    CheckTrue(A.Appearance.Equals(B.Appearance), 'Appearance unterschiedlich');
    CheckEquals(9, B.Spacing);
    CheckTrue(B.ImagePosition = ipTop);
    CheckTrue(B.WordWrap);
    CheckEquals(mrOk, B.ModalResult);
    CheckEquals(300, B.Animation.Duration);
  finally
    S.Free;
  end;
end;

procedure TStreamingTests.UnknownPresetInDfmFallsBackToDefault;
var
  B: TPPGButton;
begin
  B := LoadFromText(
    'object B1: TPPGButton'#13#10 +
    '  Preset = ''PluginThatIsMissing'''#13#10 +
    'end');
  CheckEquals(TPPGRendererRegistry.DefaultName, B.Preset);
  CheckTrue(B.Renderer <> nil);
end;

procedure TStreamingTests.OutOfRangeValueInDfmIsClamped;
var
  B: TPPGButton;
begin
  B := LoadFromText(
    'object B2: TPPGButton'#13#10 +
    '  Appearance.Rounding = 9999'#13#10 +
    '  Spacing = -5'#13#10 +
    'end');
  CheckEquals(PPGMaxRounding, B.Appearance.Rounding);
  CheckEquals(0, B.Spacing);
end;

procedure TStreamingTests.GroupedDownSurvivesLoading;
var
  B: TPPGButton;
begin
  // Down VOR GroupIndex in der DFM (z.B. von Hand bearbeitet) darf nicht verloren gehen
  B := LoadFromText(
    'object B3: TPPGButton'#13#10 +
    '  Down = True'#13#10 +
    '  GroupIndex = 1'#13#10 +
    'end');
  CheckTrue(B.Down);
  CheckEquals(1, B.GroupIndex);
end;

{ TPaintTests }

procedure TPaintTests.PaintsPresetColorWithGdiPlus;
var
  B: TPPGButton;
  Bmp: TBitmap;
begin
  TPPGRendererRegistry.ForceGdiFallback := False;
  B := NewButton;
  Bmp := RenderToBitmap(B);
  try
    // Mitte links im Koerper: Normal-Farbe des Presets
    CheckTrue(ColorDistance(Bmp.Canvas.Pixels[20, B.Height div 2],
      B.Appearance.Normal.Color) <= 6, 'Koerperfarbe falsch (GDI+)');
  finally
    Bmp.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPaintTests.PaintsPresetColorWithGdiFallback;
var
  B: TPPGButton;
  Bmp: TBitmap;
begin
  TPPGRendererRegistry.ForceGdiFallback := True;
  B := NewButton;
  Bmp := RenderToBitmap(B);
  try
    CheckTrue(ColorDistance(Bmp.Canvas.Pixels[20, B.Height div 2],
      B.Appearance.Normal.Color) <= 6, 'Koerperfarbe falsch (GDI)');
  finally
    Bmp.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPaintTests.PaintsExtremeSizesWithoutError;
var
  B: TPPGButton;
begin
  B := NewButton('High DPI');
  B.Preset := PPGPresetClassic;
  B.Appearance.Rounding := PPGMaxRounding;
  B.Appearance.GlowSize := PPGMaxGlowSize;
  B.SetBounds(0, 0, 8, 8); // extrem klein + maximale Werte
  RenderToBitmap(B).Free;
  B.SetBounds(0, 0, 1, 1);
  RenderToBitmap(B).Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPaintTests.RendererExceptionIsContainedAndReportedOnce;
var
  B: TPPGButton;
begin
  TPPGRendererRegistry.RegisterRenderer('Raising', TRaisingRenderer);
  try
    B := NewButton('boom');
    B.Preset := 'Raising';
    // Paint darf NIE eine Exception nach aussen geben
    RenderToBitmap(B).Free;
    RenderToBitmap(B).Free;
    RenderToBitmap(B).Free;
    CheckEquals(1, FErrors.Count, 'Fehler muss genau einmal gemeldet werden');
    B.Free;
  finally
    TPPGRendererRegistry.UnregisterRenderer('Raising');
  end;
end;

procedure TPaintTests.PaintToBitmapWithCaptionAndFocusCues;
var
  B: TPPGButton;
  Bmp: TBitmap;
begin
  // Regression: Paint darf keine Nachrichten senden, sonst gibt die VCL
  // (FreeMemoryContexts) den DC der Ziel-Bitmap frei -> BitBlt "ungueltiges Handle".
  B := NewButton('&Text mit Accelerator');
  B.WordWrap := True;
  Bmp := RenderToBitmap(B);
  try
    CheckEquals(0, FErrors.Count, FErrors.Text);
    CheckTrue(ColorDistance(Bmp.Canvas.Pixels[8, B.Height div 2],
      B.Appearance.Normal.Color) <= 6, 'Fallback statt Preset gezeichnet');
  finally
    Bmp.Free;
  end;
end;

procedure TPaintTests.FocusBorderIsContinuous;

  procedure CheckPreset(const APreset: string);
  var
    B: TPPGButton;
    Bmp: TBitmap;
    X, Y, First: Integer;
    Accent: TColor;
  begin
    B := NewButton('');
    B.Preset := APreset;
    B.SetFocus;
    FForm.Perform(WM_UPDATEUISTATE, MakeWParam(UIS_CLEAR, UISF_HIDEFOCUS), 0);
    B.Perform(WM_UPDATEUISTATE, MakeWParam(UIS_CLEAR, UISF_HIDEFOCUS), 0);
    Accent := B.Appearance.FocusColor;
    Bmp := RenderToBitmap(B);
    try
      Y := B.Height div 2;
      First := -1;
      for X := 0 to 20 do
        if ColorDistance(Bmp.Canvas.Pixels[X, Y], Accent) < 60 then
        begin
          First := X;
          Break;
        end;
      CheckTrue(First >= 0, APreset + ': kein Fokusrand gefunden');
      // Rand muss mindestens 2 px durchgehend in Fokusfarbe sein (keine helle Luecke)
      CheckTrue(ColorDistance(Bmp.Canvas.Pixels[First + 1, Y], Accent) < 60,
        Format('%s: Luecke im Fokusrand bei x=%d', [APreset, First + 1]));
    finally
      Bmp.Free;
    end;
    B.Free;
  end;

begin
  FForm.Show;
  try
    CheckPreset(PPGPresetModernFlat);
    CheckPreset(PPGPresetClassic);
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

{ TBehaviourTests }

procedure TBehaviourTests.CountClick(Sender: TObject);
begin
  Inc(FClicks);
end;

procedure TBehaviourTests.RaisingClick(Sender: TObject);
begin
  raise EAbort.Create('user code failed');
end;

procedure TBehaviourTests.MouseClickFiresOnce;
var
  B: TPPGButton;
begin
  B := NewButton;
  B.OnClick := CountClick;
  B.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(10, 10));
  CheckTrue(B.VisualState = vsDown);
  B.Perform(WM_LBUTTONUP, 0, MakeLParam(10, 10));
  CheckEquals(1, FClicks);
  CheckTrue(B.VisualState <> vsDown);
end;

procedure TBehaviourTests.ReleaseOutsideDoesNotClick;
var
  B: TPPGButton;
begin
  B := NewButton;
  B.OnClick := CountClick;
  B.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(10, 10));
  B.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(500, 500));
  CheckTrue(B.VisualState = vsHot, 'ausserhalb: nicht mehr gedrueckt');
  B.Perform(WM_LBUTTONUP, 0, MakeLParam(500, 500));
  CheckEquals(0, FClicks);
end;

procedure TBehaviourTests.ExceptionInOnClickLeavesNoPressedState;
var
  B: TPPGButton;
begin
  B := NewButton;
  B.OnClick := RaisingClick;
  B.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(10, 10));
  try
    B.Perform(WM_LBUTTONUP, 0, MakeLParam(10, 10));
    Fail('Exception aus OnClick muss propagieren');
  except
    on E: EAbort do
      ;
  end;
  CheckFalse(TButtonAccess(B).MousePressed, 'Button haengt im gedrueckten Zustand');
  CheckTrue(B.VisualState <> vsDown);
end;

procedure TBehaviourTests.SpaceKeyClicks;
var
  B: TPPGButton;
begin
  B := NewButton;
  B.OnClick := CountClick;
  B.Perform(WM_KEYDOWN, VK_SPACE, 0);
  CheckTrue(B.VisualState = vsDown);
  B.Perform(WM_KEYUP, VK_SPACE, 0);
  CheckEquals(1, FClicks);
  CheckTrue(B.VisualState <> vsDown);
end;

procedure TBehaviourTests.AcceleratorClicks;
var
  B: TPPGButton;
begin
  FForm.Show; // CanFocus verlangt ein sichtbares Formular
  try
    B := NewButton('&Speichern');
    B.OnClick := CountClick;
    CheckEquals(1, B.Perform(CM_DIALOGCHAR, Ord('s'), 0));
    CheckEquals(1, FClicks);
    CheckEquals(0, B.Perform(CM_DIALOGCHAR, Ord('x'), 0));
    CheckEquals(1, FClicks);
  finally
    FForm.Hide;
  end;
end;

procedure TBehaviourTests.DisabledButtonIgnoresInput;
var
  B: TPPGButton;
begin
  B := NewButton;
  B.OnClick := CountClick;
  B.Enabled := False;
  CheckTrue(B.VisualState = vsDisabled);
  B.Perform(WM_KEYDOWN, VK_SPACE, 0);
  B.Perform(WM_KEYUP, VK_SPACE, 0);
  CheckEquals(0, FClicks);
end;

procedure TBehaviourTests.ModalResultIsSetOnForm;
var
  B: TPPGButton;
begin
  B := NewButton;
  B.ModalResult := mrCancel;
  B.Click;
  CheckEquals(mrCancel, FForm.ModalResult);
  FForm.ModalResult := mrNone;
end;

procedure TBehaviourTests.GroupIsExclusive;
var
  B1, B2: TPPGButton;
begin
  B1 := NewButton;
  B2 := NewButton;
  B1.GroupIndex := 1;
  B2.GroupIndex := 1;
  B1.Down := True;
  CheckTrue(B1.Down);
  B2.Click;
  CheckTrue(B2.Down);
  CheckFalse(B1.Down, 'Gruppe nicht exklusiv');
end;

procedure TBehaviourTests.LastDownStaysWithoutAllowAllUp;
var
  B: TPPGButton;
begin
  B := NewButton;
  B.GroupIndex := 2;
  B.Down := True;
  B.Click;
  CheckTrue(B.Down, 'ohne AllowAllUp bleibt der letzte Button gedrueckt');
  B.AllowAllUp := True;
  B.Click;
  CheckFalse(B.Down);
end;

procedure TBehaviourTests.InvalidImageIndexRaises;
var
  B: TPPGButton;
begin
  B := NewButton;
  try
    B.ImageIndex := -7;
    Fail('EPPGPropertyError erwartet');
  except
    on E: EPPGPropertyError do
      CheckEquals('ImageIndex', E.PropertyName);
  end;
  CheckEquals(-1, B.ImageIndex);
end;

{ TResourceTests }

procedure TResourceTests.NoGdiOrUserHandleLeaks;

  procedure Cycle;
  var
    I: Integer;
    B: TPPGButton;
    Bmp: TBitmap;
  begin
    for I := 1 to 100 do
    begin
      B := NewButton('Leak ' + IntToStr(I));
      B.Preset := PPGPresetClassic;
      Bmp := RenderToBitmap(B);
      Bmp.Free;
      B.Perform(CM_MOUSEENTER, 0, 0);
      B.Perform(CM_MOUSELEAVE, 0, 0);
      B.Free;
    end;
  end;

var
  Gdi0, User0, Gdi1, User1: Cardinal;
begin
  Cycle; // Warmlauf: VCL-/GDI+-Caches fuellen
  Gdi0 := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
  User0 := GetGuiResources(GetCurrentProcess, GR_USEROBJECTS);
  Cycle;
  Gdi1 := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
  User1 := GetGuiResources(GetCurrentProcess, GR_USEROBJECTS);
  CheckTrue(Gdi1 <= Gdi0 + 2, Format('GDI-Handles: %d -> %d', [Gdi0, Gdi1]));
  CheckTrue(User1 <= User0 + 2, Format('USER-Handles: %d -> %d', [User0, User1]));
end;

procedure TResourceTests.NoMemoryLeaks;

  procedure Cycle;
  var
    I: Integer;
    B: TPPGButton;
    M: TPPGStyleManager;
  begin
    M := TPPGStyleManager.Create(nil);
    try
      for I := 1 to 50 do
      begin
        B := NewButton('Mem');
        B.StyleManager := M;
        RenderToBitmap(B).Free;
        B.Free;
      end;
    finally
      M.Free;
    end;
  end;

var
  M0, M1: NativeUInt;
begin
  Cycle;
  M0 := AllocatedBytes;
  Cycle;
  Cycle;
  M1 := AllocatedBytes;
  CheckTrue(M1 <= M0 + 1024, Format('Speicher waechst: %d -> %d Bytes', [M0, M1]));
end;

initialization
  RegisterTest('Controls', TLifecycleTests.Suite);
  RegisterTest('Controls', TStyleTests.Suite);
  RegisterTest('Controls', TStreamingTests.Suite);
  RegisterTest('Controls', TPaintTests.Suite);
  RegisterTest('Controls', TBehaviourTests.Suite);
  RegisterTest('Controls', TResourceTests.Suite);

end.
