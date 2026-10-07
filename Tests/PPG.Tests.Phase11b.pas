unit PPG.Tests.Phase11b;

{ Tests fuer Phase 11e/f: Hints (TPPGHintManager, TPPGHintWindow,
  TPPGCustomHint), Control-Beobachter und TeachingTip. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls,
  PPG.Types, PPG.Render.Registry, PPG.Controls.Base, PPG.Popup.Placement, PPG.AppHooks,
  PPG.Accessibility, PPG.Hints, PPG.TeachingTip, PPG.Button, PPG.Exceptions,
  PPG.Tests.Controls, PPG.Tests.Phase11a;

type
  THintTests = class(TControlTestCase)
  private
    FPrevClass: THintWindowClass;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TitleAndTextAreSplit;
    procedure TextIsEscapedWithoutMarkup;
    procedure ManagerAppliesAndRevertsClass;
    procedure SecondManagerTakesOver;
    procedure MaxWidthIsCheckedAndUsed;
    procedure ShowHintKeepsCustomText;
    procedure ColorsFollowThemeAndContrast;
    procedure CustomHintMeasuresAndPaints;
    procedure HintGallery;
  end;

  TWatchTests = class(TControlTestCase)
  private
    FCount: Integer;
    procedure Watch1(Control: TControl; var Message: TMessage);
    procedure Watch2(Control: TControl; var Message: TMessage);
  published
    procedure WatchSeesMovesAndUnhooks;
    procedure ForeignHookAfterUsKeepsChain;
  end;

  TTipPlacementTests = class(TTestCase)
  published
    procedure AutoPrefersAboveThenBelow;
    procedure SidesAndTailClamp;
  end;

  TTeachingTipTests = class(TMenuTestCase)
  private
    FTarget: TPPGButton;
    FTip: TPPGTeachingTip;
    FCancel: Boolean;
    FFreeOnAction: Boolean;
    procedure TipAction(Sender: TObject);
    procedure TipClosing(Sender: TObject; Reason: TPPGTipCloseReason; var Allow: Boolean);
    procedure TipClose(Sender: TObject; Reason: TPPGTipCloseReason);
    procedure TipLink(Sender: TObject; const Link: string);
    function NewTip: TPPGTeachingTip;
    procedure ClickPart(Part: TPPGTipPart);
    function WindowRect: TRect;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure ShowPlacesAtTargetWithTail;
    procedure FollowsTargetMoves;
    procedure HidesWithTargetAndComesBack;
    procedure CodeShowHideFireNoEvents;
    procedure CloseButtonFiresClosingAndClose;
    procedure ClosingCanBeCancelled;
    procedure ActionDoesNotCloseByItself;
    procedure LightDismissClosesOnOutsideClick;
    procedure FixedTipIgnoresOutsideClick;
    procedure EscapeCloses;
    procedure TabAndEnterInFixedTip;
    procedure EventMayFreeTheTip;
    procedure TargetFreedWhileOpen;
    procedure WithoutTargetBottomRightOfForm;
    procedure AccessibilityRoleAndChildren;
    procedure StreamingRoundTrip;
    procedure PaintsInAllPresets;
    procedure TeachingTipGallery;
  end;

implementation

uses
  System.Rtti, System.StrUtils, Winapi.oleacc, Vcl.Imaging.pngimage, PPG.Theme, PPG.Tokens, PPG.Consts,
  PPG.Lang;

type
  THintManagerAccess = class(TPPGHintManager);

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

procedure SaveGallery(Sheet: TBitmap; const Name: string);
var
  Png: TPngImage;
  Dir: string;
begin
  Dir := ExtractFilePath(ParamStr(0)) + 'Visual\Gallery\';
  ForceDirectories(Dir);
  Png := TPngImage.Create;
  try
    Png.Assign(Sheet);
    Png.SaveToFile(Dir + Name);
  finally
    Png.Free;
  end;
end;

{ THintTests }

procedure THintTests.SetUp;
begin
  inherited SetUp;
  FPrevClass := HintWindowClass;
end;

procedure THintTests.TearDown;
begin
  HintWindowClass := FPrevClass;
  TPPGTheme.Mode := tmLight;
  inherited TearDown;
end;

procedure THintTests.TitleAndTextAreSplit;
var
  M: TPPGHintManager;
  W: TPPGHintWindow;
  R: TRect;
begin
  M := TPPGHintManager.Create(nil);
  W := TPPGHintWindow.Create(nil);
  try
    R := W.CalcHintRect(0, 'Speichern|Speichert das Dokument', nil);
    CheckEquals('Speichern', W.HintTitle);
    CheckEquals('Speichert das Dokument', W.HintText);
    CheckTrue(R.Right > 0);
    CheckTrue(R.Bottom > 0);
    // Ohne langen Teil: nur Text
    W.CalcHintRect(0, 'Nur kurz', nil);
    CheckEquals('', W.HintTitle);
    CheckEquals('Nur kurz', W.HintText);
    // Gleicher kurzer und langer Teil: kein doppelter Text
    W.CalcHintRect(0, 'Gleich|Gleich', nil);
    CheckEquals('Gleich', W.HintTitle);
    CheckEquals('', W.HintText);
    // ShowTitle aus: nur der kurze Teil (wie die VCL)
    M.ShowTitle := False;
    W.CalcHintRect(0, 'Speichern|Speichert das Dokument', nil);
    CheckEquals('', W.HintTitle);
    CheckEquals('Speichern', W.HintText);
  finally
    W.Free;
    M.Free;
  end;
end;

procedure THintTests.TextIsEscapedWithoutMarkup;
var
  M: TPPGHintManager;
  W: TPPGHintWindow;
begin
  M := TPPGHintManager.Create(nil);
  W := TPPGHintWindow.Create(nil);
  try
    W.CalcHintRect(0, 'a<b>c&d', nil);
    CheckEquals('a&lt;b>c&amp;d', W.HintText, 'Sonderzeichen bleiben sichtbar');
    M.AllowMarkup := True;
    W.CalcHintRect(0, 'a<b>c</b>', nil);
    CheckEquals('a<b>c</b>', W.HintText);
  finally
    W.Free;
    M.Free;
  end;
end;

procedure THintTests.ManagerAppliesAndRevertsClass;
var
  M: TPPGHintManager;
begin
  CheckTrue(HintWindowClass <> TPPGHintWindow, 'Ausgangslage');
  M := TPPGHintManager.Create(nil);
  try
    CheckTrue(HintWindowClass = TPPGHintWindow);
    CheckTrue(M.Applied);
    CheckTrue(PPGActiveHintManager = M);
    M.Active := False;
    CheckTrue(HintWindowClass = FPrevClass, 'Active = False stellt zurueck');
    CheckFalse(M.Applied);
    CheckTrue(PPGActiveHintManager = nil);
    M.Active := True;
    CheckTrue(HintWindowClass = TPPGHintWindow);
  finally
    M.Free;
  end;
  CheckTrue(HintWindowClass = FPrevClass, 'Freigeben stellt zurueck');
  CheckTrue(PPGActiveHintManager = nil);
end;

procedure THintTests.SecondManagerTakesOver;
var
  M1, M2: TPPGHintManager;
begin
  M1 := TPPGHintManager.Create(nil);
  M2 := nil;
  try
    M2 := TPPGHintManager.Create(nil);
    CheckTrue(PPGActiveHintManager = M2);
    CheckFalse(M1.Applied);
    CheckTrue(M2.Applied);
    FreeAndNil(M2);
    CheckTrue(HintWindowClass = FPrevClass, 'zweiter stellt die Ursprungsklasse her');
  finally
    M2.Free;
    M1.Free;
  end;
  CheckTrue(HintWindowClass = FPrevClass);
end;

procedure THintTests.MaxWidthIsCheckedAndUsed;
var
  M: TPPGHintManager;
  W: TPPGHintWindow;
  R: TRect;
  Raised: Boolean;
begin
  M := TPPGHintManager.Create(nil);
  W := TPPGHintWindow.Create(nil);
  try
    Raised := False;
    try
      M.MaxWidth := 10;
    except
      on EPPGPropertyError do
        Raised := True;
    end;
    CheckTrue(Raised, 'MaxWidth < 80');
    CheckEquals(360, M.MaxWidth, 'Wert unveraendert');
    M.MaxWidth := 150;
    R := W.CalcHintRect(0, 'Titel|Ein normaler Satz mit kurzen Woertern, der bei dieser ' +
      'Breite mehrfach umbrechen muss.', nil);
    CheckTrue(R.Right <= MulDiv(150, W.PPI, 96) + 1, 'Breite begrenzt: ' + IntToStr(R.Right));
    CheckTrue(R.Bottom > MulDiv(40, W.PPI, 96), 'umgebrochen');
  finally
    W.Free;
    M.Free;
  end;
end;

procedure THintTests.ShowHintKeepsCustomText;
var
  M: TPPGHintManager;
  B: TPPGButton;
  Info: TPPGHintInfo;
  S: string;
  CanShow: Boolean;
begin
  M := TPPGHintManager.Create(nil);
  try
    B := NewButton('B');
    B.Hint := 'Titel|Langer Text';
    FillChar(Info, SizeOf(Info), 0);
    Info.HintControl := B;
    CanShow := True;
    S := 'Titel';
    THintManagerAccess(M).DoShowHint(S, CanShow, Info);
    CheckEquals('Titel|Langer Text', S, 'Standardtext wird ergaenzt');
    S := 'Eigener Text aus CM_HINTSHOW';
    THintManagerAccess(M).DoShowHint(S, CanShow, Info);
    CheckEquals('Eigener Text aus CM_HINTSHOW', S, 'eigener Text bleibt');
    M.ShowTitle := False;
    S := 'Titel';
    THintManagerAccess(M).DoShowHint(S, CanShow, Info);
    CheckEquals('Titel', S);
  finally
    M.Free;
  end;
end;

procedure THintTests.ColorsFollowThemeAndContrast;
var
  M: TPPGHintManager;
  W: TPPGHintWindow;
  Fill, Border, Text: TColor;
  Dark: Boolean;
  Names: TStringList;
  P: Integer;
begin
  M := TPPGHintManager.Create(nil);
  W := TPPGHintWindow.Create(nil);
  Names := TStringList.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    for P := 0 to Names.Count - 1 do
      for Dark := False to True do
      begin
        if Dark then
          TPPGTheme.Mode := tmDark
        else
          TPPGTheme.Mode := tmLight;
        M.Preset := Names[P];
        W.GetColors(Fill, Border, Text);
        CheckEquals(Integer(M.Tokens.Layer), Integer(Fill), Names[P]);
        CheckTrue(PPGContrastRatio(Fill, Text) >= 4.5,
          Format('%s dunkel=%s Kontrast %.2f', [Names[P], System.SysUtils.BoolToStr(Dark, True),
          PPGContrastRatio(Fill, Text)]));
      end;
    // Unbekanntes Preset: Standard
    M.Preset := 'GibtEsNicht';
    CheckEquals(TPPGRendererRegistry.DefaultName, M.EffectivePreset);
  finally
    Names.Free;
    W.Free;
    M.Free;
  end;
end;

procedure SetPrivateString(Obj: TObject; const Field, Value: string);
var
  Ctx: TRttiContext;
  F: TRttiField;
begin
  F := Ctx.GetType(TCustomHintWindow).GetField(Field);
  if F = nil then
    raise Exception.Create('Feld fehlt: ' + Field);
  F.SetValue(Obj, TValue.From<string>(Value));
end;

procedure THintTests.CustomHintMeasuresAndPaints;
var
  CH: TPPGCustomHint;
  HW: TCustomHintWindow;
  B: TBitmap;
  W1: Integer;
begin
  CH := TPPGCustomHint.Create(nil);
  HW := TCustomHintWindow.Create(nil);
  try
    CheckTrue(CH.Style = bhsStandard, 'Vorgabe ohne Ballon-Versatz');
    HW.HintParent := CH;
    SetPrivateString(HW, 'FTitle', 'Titel');
    SetPrivateString(HW, 'FDescription', 'Ein Text, der lang genug ist, um umzubrechen, ' +
      'wenn die Breite klein ist.');
    CH.SetHintSize(HW);
    CheckTrue(HW.Width > 0);
    CheckTrue(HW.Height > 0);
    W1 := HW.Width;
    CH.MaxWidth := 120;
    CH.SetHintSize(HW);
    CheckTrue(HW.Width < W1, 'MaxWidth wirkt');
    CheckTrue(HW.Width <= MulDiv(120, Screen.PixelsPerInch, 96) + 1);
    HW.HandleNeeded;
    B := TBitmap.Create;
    try
      B.SetSize(HW.Width, HW.Height);
      B.Canvas.Lock;
      try
        HW.PaintTo(B.Canvas.Handle, 0, 0);
      finally
        B.Canvas.Unlock;
      end;
    finally
      B.Free;
    end;
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    HW.Free;
    CH.Free;
  end;
end;

procedure THintTests.HintGallery;
var
  M: TPPGHintManager;
  W: TPPGHintWindow;
  Names: TStringList;
  Sheet, B: TBitmap;
  P, Row: Integer;
  Dark: Boolean;
  R: TRect;
begin
  M := TPPGHintManager.Create(nil);
  W := TPPGHintWindow.Create(nil);
  Names := TStringList.Create;
  Sheet := TBitmap.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    Sheet.PixelFormat := pf24bit;
    Sheet.SetSize(480, Names.Count * 2 * 110);
    Sheet.Canvas.Brush.Color := clWhite;
    Sheet.Canvas.FillRect(Rect(0, 0, Sheet.Width, Sheet.Height));
    M.AllowMarkup := True;
    Row := 0;
    for P := 0 to Names.Count - 1 do
      for Dark := False to True do
      begin
        if Dark then
          TPPGTheme.Mode := tmDark
        else
          TPPGTheme.Mode := tmLight;
        M.Preset := Names[P];
        R := W.CalcHintRect(0, 'Speichern (Strg+S)|Speichert das Dokument. <b>Fett</b> und ' +
          '<i>kursiv</i> gehen mit AllowMarkup.', nil);
        W.HandleNeeded;
        W.SetBounds(-2000, -2000, R.Right, R.Bottom);
        B := RenderToBitmap(W);
        try
          Sheet.Canvas.TextOut(4, Row * 110 + 4, Names[P] + IfThen(Dark, ' dunkel', ' hell'));
          Sheet.Canvas.Draw(10, Row * 110 + 22, B);
        finally
          B.Free;
        end;
        Inc(Row);
      end;
    SaveGallery(Sheet, 'Hint.png');
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    Sheet.Free;
    Names.Free;
    W.Free;
    M.Free;
  end;
end;

{ TWatchTests }

procedure TWatchTests.Watch1(Control: TControl; var Message: TMessage);
begin
  if Message.Msg = WM_WINDOWPOSCHANGED then
    Inc(FCount);
end;

procedure TWatchTests.Watch2(Control: TControl; var Message: TMessage);
begin
  if Message.Msg = WM_WINDOWPOSCHANGED then
    Inc(FCount, 100);
end;

procedure TWatchTests.WatchSeesMovesAndUnhooks;
var
  B: TPPGButton;
  L: TLabel;
  Orig: TWndMethod;
begin
  B := NewButton('B');
  Orig := B.WindowProc;
  PPGWatchControl(B, Watch1);
  PPGWatchControl(B, Watch2);
  PPGWatchControl(B, Watch1); // doppelt = einmal
  CheckEquals(2, PPGControlWatchCount(B));
  FCount := 0;
  B.Left := B.Left + 10;
  CheckEquals(101, FCount);
  PPGUnwatchControl(B, Watch2);
  FCount := 0;
  B.Top := B.Top + 10;
  CheckEquals(1, FCount);
  PPGUnwatchControl(B, Watch1);
  CheckEquals(0, PPGControlWatchCount(B));
  CheckTrue((TMethod(B.WindowProc).Code = TMethod(Orig).Code) and
    (TMethod(B.WindowProc).Data = TMethod(Orig).Data), 'ausgehaengt');
  // Grafisches Control (ohne Fenster) meldet Verschieben ebenfalls
  L := TLabel.Create(FForm);
  L.Parent := FForm;
  PPGWatchControl(L, Watch1);
  FCount := 0;
  L.Left := L.Left + 5;
  CheckEquals(1, FCount, 'TGraphicControl');
  PPGUnwatchControl(L, Watch1);
end;

type
  TForeignHook = class
    Old: TWndMethod;
    Calls: Integer;
    procedure Proc(var Message: TMessage);
  end;

procedure TForeignHook.Proc(var Message: TMessage);
begin
  Inc(Calls);
  Old(Message);
end;

procedure TWatchTests.ForeignHookAfterUsKeepsChain;
var
  B: TPPGButton;
  F: TForeignHook;
begin
  B := NewButton('B');
  F := TForeignHook.Create;
  try
    PPGWatchControl(B, Watch1);
    F.Old := B.WindowProc;
    B.WindowProc := F.Proc;
    // Abmelden darf die fremde Kette nicht brechen
    PPGUnwatchControl(B, Watch1);
    FCount := 0;
    F.Calls := 0;
    B.Left := B.Left + 3;
    CheckTrue(F.Calls > 0, 'fremder Haken laeuft');
    CheckEquals(0, FCount, 'abgemeldet');
    B.WindowProc := F.Old;
    B.Free; // Hilfsobjekt stirbt mit dem Control
  finally
    F.Free;
  end;
end;

{ TTipPlacementTests }

procedure TTipPlacementTests.AutoPrefersAboveThenBelow;
var
  P: TPPGTipPlacement;
  WA: TRect;
begin
  WA := Rect(0, 0, 1000, 800);
  // Platz oben: oben (wie WinUI), mittig zum Anker
  P := PPGPlaceTip(Rect(400, 400, 500, 430), 200, 100, 8, 16, ppsBelow, True, WA);
  CheckTrue(P.Side = ppsAbove);
  CheckEquals(400, P.Bounds.Bottom);
  CheckEquals(108, P.Bounds.Bottom - P.Bounds.Top, 'Hoehe inkl. Pfeil');
  CheckEquals(350, P.Bounds.Left, 'mittig');
  CheckEquals(100, P.TailPos, 'Pfeil in der Mitte');
  // Oben kein Platz: unten
  P := PPGPlaceTip(Rect(400, 20, 500, 50), 200, 100, 8, 16, ppsBelow, True, WA);
  CheckTrue(P.Side = ppsBelow);
  CheckEquals(50, P.Bounds.Top);
  // Weder oben noch unten: links
  P := PPGPlaceTip(Rect(600, 20, 700, 780), 200, 100, 8, 16, ppsBelow, True, WA);
  CheckTrue(P.Side = ppsLeft);
  CheckEquals(600, P.Bounds.Right);
end;

procedure TTipPlacementTests.SidesAndTailClamp;
var
  P: TPPGTipPlacement;
  WA: TRect;
begin
  WA := Rect(0, 0, 1000, 800);
  // Fest unten
  P := PPGPlaceTip(Rect(400, 400, 500, 430), 200, 100, 8, 16, ppsBelow, False, WA);
  CheckTrue(P.Side = ppsBelow);
  // Fest rechts, rechts kein Platz: links
  P := PPGPlaceTip(Rect(900, 400, 980, 430), 200, 100, 8, 16, ppsRight, False, WA);
  CheckTrue(P.Side = ppsLeft);
  CheckEquals(208, P.Bounds.Right - P.Bounds.Left);
  CheckEquals(50, P.TailPos, 'senkrecht mittig');
  // Anker am linken Rand: Blase geschoben, Pfeil zeigt weiter auf den Anker,
  // aber nicht in die Rundung
  P := PPGPlaceTip(Rect(0, 400, 10, 430), 200, 100, 8, 16, ppsBelow, False, WA);
  CheckEquals(0, P.Bounds.Left);
  CheckEquals(16, P.TailPos, 'Pfeil an der Rundung begrenzt');
end;

{ TTeachingTipTests }

procedure TTeachingTipTests.SetUp;
begin
  inherited SetUp;
  FForm.SetBounds(200, 200, 500, 400);
  FTarget := NewButton('Ziel');
  FTarget.SetBounds(150, 150, 100, 32);
  FFocus.SetBounds(10, 10, 80, 30);
  FForm.Show;
  FFocus.SetFocus;
  FCancel := False;
  FFreeOnAction := False;
end;

procedure TTeachingTipTests.TearDown;
begin
  FreeAndNil(FTip);
  TPPGTheme.Mode := tmLight;
  Pump;
  inherited TearDown;
end;

function TTeachingTipTests.NewTip: TPPGTeachingTip;
begin
  FTip := TPPGTeachingTip.Create(FForm);
  FTip.Title := 'Neu hier?';
  FTip.Subtitle := 'Kurze Einfuehrung';
  FTip.Text := 'Mit diesem Button <b>speichern</b> Sie. <a href="mehr">Mehr</a>';
  FTip.OnActionClick := TipAction;
  FTip.OnClosing := TipClosing;
  FTip.OnClose := TipClose;
  FTip.OnLinkClick := TipLink;
  Result := FTip;
end;

procedure TTeachingTipTests.TipAction(Sender: TObject);
begin
  FLog.Add('action');
  if FFreeOnAction then
  begin
    FTip := nil;
    Sender.Free;
  end;
end;

procedure TTeachingTipTests.TipClosing(Sender: TObject; Reason: TPPGTipCloseReason;
  var Allow: Boolean);
begin
  FLog.Add('closing:' + IntToStr(Ord(Reason)));
  if FCancel then
    Allow := False;
end;

procedure TTeachingTipTests.TipClose(Sender: TObject; Reason: TPPGTipCloseReason);
begin
  FLog.Add('close:' + IntToStr(Ord(Reason)));
end;

procedure TTeachingTipTests.TipLink(Sender: TObject; const Link: string);
begin
  FLog.Add('link:' + Link);
end;

procedure TTeachingTipTests.ClickPart(Part: TPPGTipPart);
var
  R: TRect;
  X, Y: Integer;
  W: TPPGTeachingTipWindow;
begin
  W := FTip.Window;
  R := W.PartRect(Part);
  Check(not IsRectEmpty(R), 'Teil sichtbar');
  X := (R.Left + R.Right) div 2;
  Y := (R.Top + R.Bottom) div 2;
  W.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(X, Y));
  W.Perform(WM_LBUTTONUP, 0, MouseLParam(X, Y));
end;

function TTeachingTipTests.WindowRect: TRect;
begin
  GetWindowRect(FTip.Window.Handle, Result);
end;

procedure TTeachingTipTests.ShowPlacesAtTargetWithTail;
var
  T, R: TRect;
  P: TPoint;
begin
  NewTip.Placement := tpBottom;
  FTip.ShowFor(FTarget);
  Pump;
  CheckTrue(FTip.IsOpen);
  CheckTrue(IsWindowVisible(FTip.Window.Handle));
  CheckTrue(FTip.Window.Side = ppsBelow);
  CheckTrue(FTip.Window.HasTail);
  P := FTarget.ClientToScreen(Point(0, 0));
  T := Rect(P.X, P.Y, P.X + FTarget.Width, P.Y + FTarget.Height);
  R := WindowRect;
  CheckTrue(R.Top >= T.Bottom, 'unter dem Ziel');
  CheckTrue(R.Top - T.Bottom <= 8, 'nah am Ziel');
  // Pfeil zeigt auf die Mitte des Ziels
  CheckTrue(Abs(R.Left + FTip.Window.TailPos - (T.Left + T.Right) div 2) <= 1, 'Pfeil mittig');
  // Fenster wird nie aktiviert: Fokus bleibt im Formular
  CheckTrue(FFocus.Focused, 'Fokus bleibt');
  CheckEquals(0, FLog.Count, 'keine Ereignisse');
end;

procedure TTeachingTipTests.FollowsTargetMoves;
var
  R1, R2: TRect;
begin
  NewTip.Placement := tpBottom;
  FTip.ShowFor(FTarget);
  Pump;
  R1 := WindowRect;
  FTarget.Left := FTarget.Left + 40;
  Pump;
  R2 := WindowRect;
  CheckEquals(R1.Left + 40, R2.Left, 'folgt dem Ziel');
  // Formular verschoben
  FForm.Top := FForm.Top + 30;
  Pump;
  R1 := WindowRect;
  CheckEquals(R2.Top + 30, R1.Top, 'folgt dem Formular');
end;

procedure TTeachingTipTests.HidesWithTargetAndComesBack;
begin
  NewTip.ShowFor(FTarget);
  Pump;
  FTarget.Visible := False;
  Pump;
  CheckFalse(IsWindowVisible(FTip.Window.Handle), 'Ziel unsichtbar: ausgeblendet');
  CheckTrue(FTip.IsOpen, 'bleibt offen');
  FTarget.Visible := True;
  Pump;
  CheckTrue(IsWindowVisible(FTip.Window.Handle), 'wieder da');
  CheckEquals(0, FLog.Count);
end;

procedure TTeachingTipTests.CodeShowHideFireNoEvents;
begin
  NewTip.ShowFor(FTarget);
  Pump;
  FTip.Hide;
  Pump;
  CheckFalse(FTip.IsOpen);
  CheckFalse(IsWindowVisible(FTip.Window.Handle));
  CheckEquals(0, FLog.Count, 'Code loest keine Ereignisse aus');
  CheckEquals(0, PPGControlWatchCount(FTarget), 'Beobachter abgemeldet');
end;

procedure TTeachingTipTests.CloseButtonFiresClosingAndClose;
begin
  NewTip.ShowFor(FTarget);
  Pump;
  CheckTrue(FTip.Window.PartVisible(tppCross));
  ClickPart(tppCross);
  CheckEquals('closing:0,close:0', FLog.CommaText);
  CheckFalse(FTip.IsOpen);
  // Mit Text-Button: kein Kreuz, Button schliesst
  FLog.Clear;
  FTip.CloseButtonText := 'Spaeter';
  FTip.Show;
  Pump;
  CheckFalse(FTip.Window.PartVisible(tppCross), 'Kreuz nur ohne CloseButtonText');
  ClickPart(tppClose);
  CheckEquals('closing:0,close:0', FLog.CommaText);
end;

procedure TTeachingTipTests.ClosingCanBeCancelled;
begin
  NewTip.ShowFor(FTarget);
  Pump;
  FCancel := True;
  ClickPart(tppCross);
  CheckEquals('closing:0', FLog.CommaText);
  CheckTrue(FTip.IsOpen, 'abgebrochen');
end;

procedure TTeachingTipTests.ActionDoesNotCloseByItself;
begin
  NewTip.ActionButtonText := '&Weiter';
  FTip.ShowFor(FTarget);
  Pump;
  ClickPart(tppAction);
  CheckEquals('action', FLog.CommaText);
  CheckTrue(FTip.IsOpen, 'wie WinUI: Anwendung entscheidet');
end;

procedure TTeachingTipTests.LightDismissClosesOnOutsideClick;
begin
  NewTip.LightDismiss := True;
  FTip.ShowFor(FTarget);
  Pump;
  PostMessage(FFocus.Handle, WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(5, 5));
  PostMessage(FFocus.Handle, WM_LBUTTONUP, 0, MouseLParam(5, 5));
  Pump;
  CheckEquals('closing:1,close:1', FLog.CommaText);
  CheckFalse(FTip.IsOpen);
end;

procedure TTeachingTipTests.FixedTipIgnoresOutsideClick;
begin
  NewTip.ShowFor(FTarget);
  Pump;
  PostMessage(FFocus.Handle, WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(5, 5));
  PostMessage(FFocus.Handle, WM_LBUTTONUP, 0, MouseLParam(5, 5));
  Pump;
  CheckEquals(0, FLog.Count);
  CheckTrue(FTip.IsOpen);
  // Anwendung verliert die Aktivierung: fester Tip bleibt
  if Assigned(Application.OnDeactivate) then
    Application.OnDeactivate(Application);
  CheckTrue(FTip.IsOpen);
end;

procedure TTeachingTipTests.EscapeCloses;
begin
  NewTip.LightDismiss := True;
  FTip.ShowFor(FTarget);
  Pump;
  PostKey(VK_ESCAPE);
  Pump;
  CheckEquals('closing:2,close:2', FLog.CommaText);
  CheckFalse(FTip.IsOpen);
end;

procedure TTeachingTipTests.TabAndEnterInFixedTip;
begin
  NewTip.ActionButtonText := 'Weiter';
  FTip.CloseButtonText := 'Spaeter';
  FTip.ShowFor(FTarget);
  Pump;
  CheckTrue(FTip.Window.FocusPart = tppAction, 'erster Button hat den Fokus');
  PostKey(VK_RETURN);
  Pump;
  CheckEquals('action', FLog.CommaText);
  PostKey(VK_TAB);
  Pump;
  CheckTrue(FTip.Window.FocusPart = tppClose, 'Tab wechselt');
  CheckTrue(FFocus.Focused, 'Tab bleibt im TeachingTip');
  PostKey(VK_TAB);
  Pump;
  CheckTrue(FTip.Window.FocusPart = tppAction, 'Umlauf');
  PostKey(VK_TAB);
  Pump;
  PostKey(VK_SPACE);
  Pump;
  CheckEquals('action,closing:0,close:0', FLog.CommaText);
end;

procedure TTeachingTipTests.EventMayFreeTheTip;
begin
  NewTip.ActionButtonText := 'Fertig';
  FTip.ShowFor(FTarget);
  Pump;
  FFreeOnAction := True;
  ClickPart(tppAction);
  CheckTrue(FTip = nil);
  Pump; // Fenster gibt sich verzoegert frei
  CheckEquals(0, PPGControlWatchCount(FTarget));
  CheckEquals(0, FErrors.Count, FErrors.Text);
  // Ueber die Tastatur ebenfalls
  NewTip.ActionButtonText := 'Fertig';
  FTip.ShowFor(FTarget);
  Pump;
  PostKey(VK_RETURN);
  Pump;
  CheckTrue(FTip = nil);
end;

procedure TTeachingTipTests.TargetFreedWhileOpen;
var
  H: HWND;
begin
  NewTip.ShowFor(FTarget);
  Pump;
  H := FTip.Window.Handle;
  FreeAndNil(FTarget);
  Pump;
  CheckTrue(FTip.Target = nil);
  CheckFalse(FTip.IsOpen);
  CheckFalse(IsWindowVisible(H));
  CheckEquals(0, FLog.Count, 'keine Anwenderaktion');
end;

procedure TTeachingTipTests.WithoutTargetBottomRightOfForm;
var
  R: TRect;
  P: TPoint;
begin
  NewTip.Show;
  Pump;
  CheckFalse(FTip.Window.HasTail);
  R := WindowRect;
  P := FForm.ClientToScreen(Point(FForm.ClientWidth, FForm.ClientHeight));
  CheckTrue(R.Right <= P.X);
  CheckTrue(R.Bottom <= P.Y);
  CheckTrue(P.X - R.Right <= 20, 'rechts unten');
end;

procedure TTeachingTipTests.AccessibilityRoleAndChildren;
var
  AC: IPPGAccessibleChildren;
begin
  NewTip.ActionButtonText := '&Weiter';
  FTip.CloseButtonText := 'Spaeter';
  FTip.ShowFor(FTarget);
  Pump;
  CheckTrue(Supports(FTip.Window, IPPGAccessibleChildren, AC));
  CheckEquals(2, AC.AccChildCount);
  CheckEquals('Weiter', AC.AccChildName(1));
  CheckEquals('Spaeter', AC.AccChildName(2));
  CheckEquals(ROLE_SYSTEM_PUSHBUTTON, AC.AccChildRole(1));
  CheckEquals(1, AC.AccFocusedChild);
  // Standardaktion per Screenreader: gepostet, nicht im COM-Aufruf
  AC.AccChildDoDefault(1);
  CheckEquals(0, FLog.Count, 'noch nicht');
  Pump;
  CheckEquals('action', FLog.CommaText);
  AC := nil;
end;

procedure TTeachingTipTests.StreamingRoundTrip;
var
  MS: TMemoryStream;
  T2: TPPGTeachingTip;
begin
  NewTip.ActionButtonText := 'Weiter';
  FTip.Icon := tiWarning;
  FTip.Placement := tpLeft;
  FTip.LightDismiss := True;
  FTip.MaxWidth := 280;
  FTip.ShowCloseButton := False;
  MS := TMemoryStream.Create;
  T2 := TPPGTeachingTip.Create(nil);
  try
    MS.WriteComponent(FTip);
    MS.Position := 0;
    MS.ReadComponent(T2);
    CheckEquals(FTip.Title, T2.Title);
    CheckEquals(FTip.Text, T2.Text);
    CheckEquals('Weiter', T2.ActionButtonText);
    CheckTrue(T2.Icon = tiWarning);
    CheckTrue(T2.Placement = tpLeft);
    CheckTrue(T2.LightDismiss);
    CheckEquals(280, T2.MaxWidth);
    CheckFalse(T2.ShowCloseButton);
  finally
    T2.Free;
    MS.Free;
  end;
end;

procedure TTeachingTipTests.PaintsInAllPresets;
var
  Names: TStringList;
  P: Integer;
  Dark, Gdi: Boolean;
  B: TBitmap;
  Pl: TPPGTipPlacementMode;
begin
  Names := TStringList.Create;
  try
    NewTip.ActionButtonText := 'Weiter';
    FTip.CloseButtonText := 'Spaeter';
    FTip.Icon := tiInfo;
    TPPGRendererRegistry.GetNames(Names);
    for P := 0 to Names.Count - 1 do
      for Dark := False to True do
        for Gdi := False to True do
          for Pl := tpTop to tpRight do
          begin
            if Dark then
              TPPGTheme.Mode := tmDark
            else
              TPPGTheme.Mode := tmLight;
            TPPGRendererRegistry.ForceGdiFallback := Gdi;
            FTip.Preset := Names[P];
            FTip.Placement := Pl;
            FTip.ShowFor(FTarget);
            B := RenderToBitmap(FTip.Window);
            B.Free;
          end;
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    Names.Free;
  end;
end;

procedure TTeachingTipTests.TeachingTipGallery;
const
  Places: array[0..3] of TPPGTipPlacementMode = (tpBottom, tpTop, tpRight, tpLeft);
var
  Names: TStringList;
  P, Row, I, X: Integer;
  Dark: Boolean;
  Sheet, B: TBitmap;
begin
  Names := TStringList.Create;
  Sheet := TBitmap.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    Sheet.PixelFormat := pf24bit;
    Sheet.SetSize(1500, Names.Count * 2 * 260);
    Sheet.Canvas.Brush.Color := clWhite;
    Sheet.Canvas.FillRect(Rect(0, 0, Sheet.Width, Sheet.Height));
    NewTip.MaxWidth := 300;
    Row := 0;
    for P := 0 to Names.Count - 1 do
      for Dark := False to True do
      begin
        if Dark then
          TPPGTheme.Mode := tmDark
        else
          TPPGTheme.Mode := tmLight;
        FTip.Preset := Names[P];
        Sheet.Canvas.TextOut(4, Row * 260 + 4, Names[P] + IfThen(Dark, ' dunkel', ' hell'));
        X := 10;
        for I := 0 to High(Places) do
        begin
          FTip.Placement := Places[I];
          FTip.Icon := TPPGTipIcon(I + 1);
          if I < 2 then
          begin
            FTip.ActionButtonText := 'Weiter';
            FTip.CloseButtonText := IfThen(I = 0, 'Spaeter', '');
          end
          else
          begin
            FTip.ActionButtonText := '';
            FTip.CloseButtonText := '';
          end;
          FTip.ShowFor(FTarget);
          B := RenderToBitmap(FTip.Window);
          try
            Sheet.Canvas.Draw(X, Row * 260 + 24, B);
            Inc(X, B.Width + 20);
          finally
            B.Free;
          end;
        end;
        Inc(Row);
      end;
    SaveGallery(Sheet, 'TeachingTip.png');
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    Sheet.Free;
    Names.Free;
  end;
end;

initialization
  RegisterTest('Phase11b', THintTests.Suite);
  RegisterTest('Phase11b', TWatchTests.Suite);
  RegisterTest('Phase11b', TTipPlacementTests.Suite);
  RegisterTest('Phase11b', TTeachingTipTests.Suite);

end.
