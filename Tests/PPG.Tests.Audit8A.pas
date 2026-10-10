unit PPG.Tests.Audit8A;

{ Audit-Paket 8A (Docs\Audit-Paket8-Plan.md): Regressionstests.

  - Teil-Neuzeichnen (8a #1): nach InvalidateRect eines Teilbereichs bleibt
    der Rest des Fensters unveraendert, der Bereich ist pixelgleich zu einem
    Voll-Paint (Fenster-DC mit zwischengespeichertem Puffer und Speicher-DC).
  - Hover (8a #2, 8b): das Fenster zeigt nach jeder Mausbewegung denselben
    Stand wie ein Voll-Paint, und neu gezeichnet wird nur der Bereich der
    alten und neuen Zeile.
  - Animator (8a #3), Messen (8a #4), GDI+-Bloecke (8a #5), Icon- und
  Schatten-Cache (8a #6/#7). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.ImgList, Vcl.StdCtrls,
  PPG.Types, PPG.Items, PPG.AppHooks, PPG.Render.Intf, PPG.Controls.Base, PPG.ListBox,
  PPG.NavigationView, PPG.ToolBar, PPG.TileView, PPG.TreeView, PPG.Button, PPG.StatusBar,
  PPG.Animation, PPG.Planner, PPG.Notifications, PPG.Feedback, PPG.Tests.Controls;

type
  /// ListBox, die Paints und die Clip-Box jedes Paints mitschreibt.
  TClipRecListBox = class(TPPGListBox)
  protected
    procedure Paint; override;
  public
    Paints: Integer;
    LastClip: TRect;
  end;

  /// Hilfen fuer Teil-Neuzeichnen-Tests (auch Audit 8E in Audit8B/Audit8D):
  /// Fensterinhalt festhalten, mit Magenta ueberschreiben, vergleichen.
  TAudit8PartialTestCase = class(TControlTestCase)
  protected
    function Snapshot(C: TWinControl): TBitmap;
    procedure Scribble(C: TWinControl);
    function DiffIn(A, B: TBitmap; const R: TRect; Outside: Boolean): Integer;
    function MagentaOutside(B: TBitmap; const R: TRect): Integer;
    /// Nach InvalidateRect(R) ist R pixelgleich zum Voll-Paint, der Rest unveraendert.
    procedure CheckPartial(C: TWinControl; const R: TRect; const Msg: string);
    /// Das Fenster zeigt nach der letzten Aktion denselben Stand wie ein Voll-Paint.
    procedure CheckWindowMatches(C: TWinControl; const Msg: string);
  end;

  TAudit8APaintTests = class(TAudit8PartialTestCase)
  private
    function NewList(Count: Integer): TClipRecListBox;
    procedure TileItem(Sender: TObject; Index: Integer; var Data: TPPGItemData);
  protected
    procedure SetUp; override;
  published
    /// 8a #1: Teilbereich im Fenster-DC (zwischengespeicherter Puffer).
    procedure PartialRepaintListBox;
    procedure PartialRepaintListBoxRtl;
    procedure PartialRepaintTreeView;
    procedure PartialRepaintTileView;
    procedure PartialRepaintNavigationView;
    procedure PartialRepaintButtonWithFocus;
    /// 8a #1: PaintTo in einen Speicher-DC mit Clip (Drucken, Screenshots).
    procedure PaintToWithClipKeepsOutside;
    /// 8b: Hover in Liste, NavigationView und ToolBar zeigt den Voll-Paint-Stand.
    procedure HoverListBoxMatchesFullPaint;
    procedure HoverNavigationViewMatchesFullPaint;
    procedure HoverToolBarMatchesFullPaint;
  end;

  /// 8a #2 / 8b: Zaehltests - Hover invalidiert nur alte und neue Zeile bzw.
  /// den Knopf, Betreten eines Daten-Controls zeichnet nicht neu.
  TAudit8ARepaintCountTests = class(TControlTestCase)
  private
    function UpdateBox(C: TWinControl): TRect;
    function NewList(Count: Integer): TClipRecListBox;
  protected
    procedure SetUp; override;
  published
    procedure ListBoxEnterDoesNotRepaint;
    procedure ButtonEnterStillRepaints;
    procedure ListBoxHoverInvalidatesOnlyRows;
    procedure ListBoxHoverPaintsOnlyRows;
    procedure NavigationViewHoverInvalidatesOnlyRows;
    procedure ToolBarHoverInvalidatesOnlyButtons;
    procedure StatusBarPanelTextInvalidatesOnlyPanel;
  end;

  /// 8a #3: Faelligkeitsmodus des Animators (Wakeups gezaehlt).
  TAudit8AAnimatorTests = class(TTestCase)
  private
    FSteps: Integer;
    FVictim: TPPGAnimation;
    procedure CountStep(Sender: TObject);
    procedure FreeVictimStep(Sender: TObject);
    procedure Pump(Ms: Cardinal);
    function CountTimers(Ms: Cardinal): Integer;
  published
    procedure LongLoopSleepsBetweenSteps;
    procedure FrameAnimationRestoresFrameRate;
    procedure DueModeEndsOnTime;
    procedure StopKeepsCurrentValue;
    procedure FreeingOtherAnimationDuringTickIsSafe;
    procedure PlannerNowLineIdleWakeups;
    procedure ScrollHoldIdleWakeups;
    procedure ToastLifetimeEndsWithoutFrames;
  end;

  /// 8a #4: gemeinsamer Mess-DC und Cache.
  TAudit8AMeasureTests = class(TTestCase)
  private
    function Direct(const Text: string; Font: TFont; MaxWidth: Integer;
      WordWrap: Boolean): TSize;
  published
    procedure MatchesDirectMeasure;
    procedure FontChangeIsSeen;
    procedure SharedDCIsReused;
  end;

  /// 8a #5-#7: GDI+-Bloecke, Rechteck ohne Pfad, Icon- und Schatten-Cache.
  TAudit8ARenderTests = class(TControlTestCase)
  private
    function MakeImages(Square: Boolean): TImageList;
    function NewBitmap(W, H: Integer): TBitmap;
    procedure DrawSequence(B: TBitmap; Batch: Boolean);
  published
    procedure BatchMatchesUnbatched;
    procedure NestedGdiReusesDC;
    procedure FillRoundRectWithoutRadiusIsExact;
    procedure TintCacheFollowsImageChange;
    procedure TintCacheSurvivesListReuse;
    procedure CachedShadowMatchesDirect;
  end;

  /// Audit 11e: ForceGdiFallback mit Setter; eine Aenderung zeichnet ueber
  /// den Haken aus PPG.Theme alle Fenster neu (Demo braucht keinen Workaround).
  TAudit11DRenderModeTests = class(TControlTestCase)
  private
    procedure ShowAndValidate(C: TWinControl);
  published
    procedure ThemeInstallsRedrawHook;
    procedure SetterCallsHookOnlyOnChange;
    procedure FallbackSwitchInvalidatesWindows;
    procedure SameValueKeepsWindowsValid;
  end;

  /// 8.0 #1: Control wird waehrend einer beobachteten Nachricht freigegeben.
  TAppHooksLifetimeTests = class(TTestCase)
  private
    FWatched: TForm;
    FCallsAfterFree: Integer;
    FFreed: Boolean;
    procedure CountingEvent(Control: TControl; var Message: TMessage);
    procedure FreeingEvent(Control: TControl; var Message: TMessage);
  protected
    procedure SetUp; override;
  published
    procedure ObserverFreesControlStopsChain;
    procedure ReleaseOfWatchedFormIsSafe;
  end;

implementation

uses
  Winapi.GDIPAPI, Winapi.GDIPOBJ, PPG.Render.Gdi, PPG.Render.GdiPlus, PPG.Tests.Visual,
  PPG.Render.Registry;

const
  WM_AUDIT8_FREE = WM_USER + 801;
  Magenta = $00FF00FF;

type
  // Meldet seine Freigabe (gehoert dem beobachteten Formular)
  TFreeSpy = class(TComponent)
  public
    Freed: PBoolean;
    destructor Destroy; override;
  end;

destructor TFreeSpy.Destroy;
begin
  if Freed <> nil then
    Freed^ := True;
  inherited Destroy;
end;

{ TClipRecListBox }

procedure TClipRecListBox.Paint;
begin
  Inc(Paints);
  if GetClipBox(Canvas.Handle, LastClip) = ERROR then
    LastClip := ClientRect;
  inherited Paint;
end;

{ TAudit8APaintTests }

procedure TAudit8APaintTests.SetUp;
begin
  inherited;
  FForm.SetBounds(0, 0, 500, 420);
  FForm.Show;
end;

function TAudit8PartialTestCase.Snapshot(C: TWinControl): TBitmap;
var
  DC: HDC;
begin
  Result := TBitmap.Create;
  try
    Result.PixelFormat := pf24bit;
    Result.SetSize(C.Width, C.Height);
    DC := GetDC(C.Handle);
    try
      BitBlt(Result.Canvas.Handle, 0, 0, C.Width, C.Height, DC, 0, 0, SRCCOPY);
    finally
      ReleaseDC(C.Handle, DC);
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TAudit8PartialTestCase.Scribble(C: TWinControl);
var
  DC: HDC;
  Brush: HBRUSH;
  R: TRect;
begin
  // Fensterinhalt mit Magenta ueberschreiben: was danach nicht neu gezeichnet
  // wird, bleibt magenta
  DC := GetDC(C.Handle);
  try
    Brush := CreateSolidBrush(Magenta);
    try
      R := Rect(0, 0, C.Width, C.Height);
      FillRect(DC, R, Brush);
    finally
      DeleteObject(Brush);
    end;
  finally
    ReleaseDC(C.Handle, DC);
  end;
end;

function TAudit8PartialTestCase.DiffIn(A, B: TBitmap; const R: TRect; Outside: Boolean): Integer;
var
  X, Y: Integer;
  PA, PB: PByteArray;
  Inside: Boolean;
begin
  Result := 0;
  for Y := 0 to A.Height - 1 do
  begin
    PA := A.ScanLine[Y];
    PB := B.ScanLine[Y];
    for X := 0 to A.Width - 1 do
    begin
      Inside := (X >= R.Left) and (X < R.Right) and (Y >= R.Top) and (Y < R.Bottom);
      if Inside = Outside then
        Continue;
      if (PA[X * 3] <> PB[X * 3]) or (PA[X * 3 + 1] <> PB[X * 3 + 1]) or
        (PA[X * 3 + 2] <> PB[X * 3 + 2]) then
        Inc(Result);
    end;
  end;
end;

function TAudit8PartialTestCase.MagentaOutside(B: TBitmap; const R: TRect): Integer;
var
  X, Y: Integer;
  P: PByteArray;
begin
  // Anzahl Pixel ausserhalb von R, die NICHT mehr magenta sind
  Result := 0;
  for Y := 0 to B.Height - 1 do
  begin
    P := B.ScanLine[Y];
    for X := 0 to B.Width - 1 do
    begin
      if (X >= R.Left) and (X < R.Right) and (Y >= R.Top) and (Y < R.Bottom) then
        Continue;
      if (P[X * 3] <> $FF) or (P[X * 3 + 1] <> 0) or (P[X * 3 + 2] <> $FF) then
        Inc(Result);
    end;
  end;
end;

function TAudit8APaintTests.NewList(Count: Integer): TClipRecListBox;
var
  I: Integer;
begin
  Result := TClipRecListBox.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 300, 360);
  Result.Animation.Enabled := False;
  Result.Items.BeginUpdate;
  try
    for I := 0 to Count - 1 do
      Result.Items.Add('Eintrag ' + IntToStr(I));
  finally
    Result.Items.EndUpdate;
  end;
  Result.HandleNeeded;
  Result.Update;
end;

procedure TAudit8PartialTestCase.CheckWindowMatches(C: TWinControl; const Msg: string);
var
  Ref, Snap: TBitmap;
begin
  // Erst das Fenster festhalten (nur die Invalidierung der Aktion), dann
  // den Voll-Paint als Referenz
  C.Update;
  Snap := Snapshot(C);
  try
    Ref := RenderToBitmap(C);
    try
      CheckEquals(0, PPGPixelDiff(Snap, Ref, 0), Msg + ': Fenster weicht vom Voll-Paint ab');
    finally
      Ref.Free;
    end;
  finally
    Snap.Free;
  end;
  C.Update; // was PaintTo nachtraeglich invalidiert hat, vor der naechsten Aktion
end;

procedure TAudit8PartialTestCase.CheckPartial(C: TWinControl; const R: TRect; const Msg: string);
var
  Ref, Snap: TBitmap;
begin
  C.Invalidate;
  C.Update;
  Ref := RenderToBitmap(C);
  try
    C.Update; // was PaintTo nachtraeglich invalidiert hat (z.B. Baum-Layout)
    // Fensterweg und PaintTo zeichnen gleich
    Snap := Snapshot(C);
    try
      CheckEquals(0, PPGPixelDiff(Snap, Ref, 0), Msg + ': Voll-Paint im Fenster <> PaintTo');
    finally
      Snap.Free;
    end;
    Scribble(C);
    InvalidateRect(C.Handle, @R, False);
    C.Update;
    Snap := Snapshot(C);
    try
      CheckEquals(0, DiffIn(Snap, Ref, R, False), Msg + ': Teilbereich nicht pixelgleich');
      CheckEquals(0, MagentaOutside(Snap, R), Msg + ': ausserhalb des Bereichs gezeichnet');
    finally
      Snap.Free;
    end;
  finally
    Ref.Free;
  end;
end;

procedure TAudit8APaintTests.PartialRepaintListBox;
var
  L: TClipRecListBox;
begin
  L := NewList(100);
  L.ItemIndex := 3;
  L.SetFocus;
  // Bereiche quer durch Zeilen, Fokus und Auswahl
  CheckPartial(L, Rect(20, 37, 180, 95), 'Mitte');
  CheckPartial(L, Rect(0, 0, 300, 15), 'Rand oben');
  CheckPartial(L, Rect(250, 100, 300, 360), 'rechts mit Leiste');
end;

procedure TAudit8APaintTests.PartialRepaintListBoxRtl;
var
  L: TClipRecListBox;
begin
  L := NewList(100);
  L.BiDiMode := bdRightToLeft;
  L.ItemIndex := 2;
  CheckPartial(L, Rect(0, 30, 120, 90), 'RTL links');
  CheckPartial(L, Rect(200, 50, 300, 70), 'RTL rechts');
end;

procedure TAudit8APaintTests.PartialRepaintTreeView;
var
  T: TPPGTreeView;
  N: TPPGTreeNode;
  I, J: Integer;
begin
  T := TPPGTreeView.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(10, 10, 300, 360);
  T.Animation.Enabled := False;
  T.Items.BeginUpdate;
  try
    for I := 0 to 9 do
    begin
      N := T.Items.Add(nil, 'Knoten ' + IntToStr(I));
      for J := 0 to 4 do
        T.Items.AddChild(N, 'Kind ' + IntToStr(J));
      N.Expanded := True;
    end;
  finally
    T.Items.EndUpdate;
  end;
  T.HandleNeeded;
  CheckPartial(T, Rect(5, 45, 200, 130), 'Baum');
end;

procedure TAudit8APaintTests.TileItem(Sender: TObject; Index: Integer; var Data: TPPGItemData);
begin
  Data.Text := 'Kachel ' + IntToStr(Index);
  Data.Detail := 'Detail ' + IntToStr(Index mod 7);
end;

procedure TAudit8APaintTests.PartialRepaintTileView;
var
  V: TPPGTileView;
begin
  V := TPPGTileView.Create(FForm);
  V.Parent := FForm;
  V.SetBounds(10, 10, 460, 360);
  V.Animation.Enabled := False;
  V.GroupView := False;
  V.OnGetItem := TileItem;
  V.OwnerData := True;
  V.ItemCount := 200;
  V.HandleNeeded;
  // quer durch Kacheln (halbe Kachel, Zwischenraum)
  CheckPartial(V, Rect(70, 60, 250, 140), 'Kacheln');
  CheckPartial(V, Rect(0, 300, 460, 360), 'Kacheln unten');
end;

procedure TAudit8APaintTests.PartialRepaintNavigationView;
var
  N: TPPGNavigationView;
  I: Integer;
begin
  N := TPPGNavigationView.Create(FForm);
  N.Parent := FForm;
  N.Animation.Enabled := False;
  N.Height := 380;
  for I := 0 to 30 do
    N.Items.AddItem('Eintrag ' + IntToStr(I), PPGNavIconDocument, I);
  N.HandleNeeded;
  CheckPartial(N, Rect(0, 70, 150, 160), 'Navigation');
end;

procedure TAudit8APaintTests.PartialRepaintButtonWithFocus;
var
  B: TPPGButton;
begin
  B := NewButton('Fokus');
  B.SetBounds(20, 20, 160, 50);
  B.SetFocus;
  // Ecke mit Glow/Fokusrahmen
  CheckPartial(B, Rect(0, 0, 40, 25), 'Button Ecke');
  CheckPartial(B, Rect(60, 10, 100, 40), 'Button Text');
end;

procedure TAudit8APaintTests.PaintToWithClipKeepsOutside;
var
  L: TClipRecListBox;
  Ref, B: TBitmap;
  R: TRect;
  Brush: HBRUSH;
  Saved: Integer;
begin
  L := NewList(50);
  L.ItemIndex := 1;
  Ref := RenderToBitmap(L);
  B := TBitmap.Create;
  try
    B.PixelFormat := pf24bit;
    B.SetSize(L.Width, L.Height);
    Brush := CreateSolidBrush(Magenta);
    try
      FillRect(B.Canvas.Handle, Rect(0, 0, L.Width, L.Height), Brush);
    finally
      DeleteObject(Brush);
    end;
    R := Rect(30, 25, 200, 70);
    B.Canvas.Lock;
    try
      Saved := SaveDC(B.Canvas.Handle);
      try
        IntersectClipRect(B.Canvas.Handle, R.Left, R.Top, R.Right, R.Bottom);
        L.PaintTo(B.Canvas.Handle, 0, 0);
      finally
        RestoreDC(B.Canvas.Handle, Saved);
      end;
    finally
      B.Canvas.Unlock;
    end;
    CheckEquals(0, DiffIn(B, Ref, R, False), 'Bereich wie Voll-Paint');
    CheckEquals(0, MagentaOutside(B, R), 'ausserhalb unveraendert');
  finally
    B.Free;
    Ref.Free;
  end;
end;

procedure TAudit8APaintTests.HoverListBoxMatchesFullPaint;
var
  L: TClipRecListBox;
  I: Integer;
begin
  L := NewList(100);
  L.ItemIndex := 4;
  for I := 0 to 7 do
  begin
    L.Perform(WM_MOUSEMOVE, 0, MakeLParam(50, 5 + I * 23));
    CheckWindowMatches(L, 'Hover ' + IntToStr(I));
  end;
  L.Perform(CM_MOUSELEAVE, 0, 0);
  CheckWindowMatches(L, 'Maus raus');
end;

procedure TAudit8APaintTests.HoverNavigationViewMatchesFullPaint;
var
  N: TPPGNavigationView;
  I: Integer;
begin
  N := TPPGNavigationView.Create(FForm);
  N.Parent := FForm;
  N.Animation.Enabled := False;
  N.Height := 380;
  for I := 0 to 30 do
    N.Items.AddItem('Eintrag ' + IntToStr(I), PPGNavIconDocument, I);
  N.HandleNeeded;
  N.Update;
  for I := 0 to 7 do
  begin
    N.Perform(WM_MOUSEMOVE, 0, MakeLParam(30, 20 + I * 31));
    CheckWindowMatches(N, 'Hover ' + IntToStr(I));
  end;
  N.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(30, 120));
  CheckWindowMatches(N, 'gedrueckt');
  N.Perform(WM_LBUTTONUP, 0, MakeLParam(30, 120));
  CheckWindowMatches(N, 'losgelassen');
  N.Perform(CM_MOUSELEAVE, 0, 0);
  CheckWindowMatches(N, 'Maus raus');
end;

procedure TAudit8APaintTests.HoverToolBarMatchesFullPaint;
var
  T: TPPGToolBar;
  I: Integer;
begin
  T := TPPGToolBar.Create(FForm);
  T.Parent := FForm;
  T.Width := 480;
  for I := 0 to 9 do
    T.Items.AddButton('Knopf ' + IntToStr(I));
  T.HandleNeeded;
  T.Update;
  for I := 0 to 9 do
  begin
    T.Perform(WM_MOUSEMOVE, 0, MakeLParam(10 + I * 45, T.Height div 2));
    CheckWindowMatches(T, 'Hover ' + IntToStr(I));
  end;
  T.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(100, T.Height div 2));
  CheckWindowMatches(T, 'gedrueckt');
  T.Perform(WM_LBUTTONUP, 0, MakeLParam(100, T.Height div 2));
  CheckWindowMatches(T, 'losgelassen');
  T.Perform(CM_MOUSELEAVE, 0, 0);
  CheckWindowMatches(T, 'Maus raus');
end;

{ TAudit8ARepaintCountTests }

procedure TAudit8ARepaintCountTests.SetUp;
begin
  inherited;
  FForm.SetBounds(0, 0, 500, 420);
  FForm.Show;
end;

function TAudit8ARepaintCountTests.UpdateBox(C: TWinControl): TRect;
begin
  if not GetUpdateRect(C.Handle, Result, False) then
    Result := Rect(0, 0, 0, 0);
end;

function TAudit8ARepaintCountTests.NewList(Count: Integer): TClipRecListBox;
var
  I: Integer;
begin
  Result := TClipRecListBox.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 300, 360);
  Result.Animation.Enabled := False;
  for I := 0 to Count - 1 do
    Result.Items.Add('Eintrag ' + IntToStr(I));
  Result.HandleNeeded;
  Result.Update;
end;

procedure TAudit8ARepaintCountTests.ListBoxEnterDoesNotRepaint;
var
  L: TClipRecListBox;
begin
  L := NewList(20);
  L.Animation.Enabled := True;
  L.Update;
  L.Perform(CM_MOUSEENTER, 0, 0);
  CheckTrue(IsRectEmpty(UpdateBox(L)), 'Betreten: kein Neuzeichnen (keine Hot-Animation)');
  L.Perform(CM_MOUSELEAVE, 0, 0);
  CheckTrue(IsRectEmpty(UpdateBox(L)), 'Verlassen ohne Hover-Zeile: kein Neuzeichnen');
end;

procedure TAudit8ARepaintCountTests.ButtonEnterStillRepaints;
var
  B: TPPGButton;
begin
  B := NewButton('Hover');
  B.Update;
  B.Perform(CM_MOUSEENTER, 0, 0);
  CheckFalse(IsRectEmpty(UpdateBox(B)), 'Buttons zeigen Hover weiterhin');
end;

procedure TAudit8ARepaintCountTests.ListBoxHoverInvalidatesOnlyRows;
var
  L: TClipRecListBox;
  R2, R3, Box: TRect;
begin
  L := NewList(50);
  R2 := L.ItemRect(2);
  R3 := L.ItemRect(3);
  // Erste Bewegung blendet die Leisten ein (zeichnet die Leiste neu)
  L.Perform(WM_MOUSEMOVE, 0, MakeLParam(50, 2));
  L.Update;
  L.Perform(WM_MOUSEMOVE, 0, MakeLParam(50, (R2.Top + R2.Bottom) div 2));
  Box := UpdateBox(L);
  CheckTrue((Box.Top >= 0) and (Box.Bottom <= R2.Bottom + 5),
    Format('nur Zeilen 0 und 2: %d..%d', [Box.Top, Box.Bottom]));
  L.Update;
  L.Perform(WM_MOUSEMOVE, 0, MakeLParam(50, (R3.Top + R3.Bottom) div 2));
  Box := UpdateBox(L);
  CheckTrue((Box.Top >= R2.Top - 5) and (Box.Bottom <= R3.Bottom + 5),
    Format('nur Zeilen 2 und 3: %d..%d', [Box.Top, Box.Bottom]));
end;

procedure TAudit8ARepaintCountTests.ListBoxHoverPaintsOnlyRows;
var
  L: TClipRecListBox;
  R5: TRect;
begin
  L := NewList(50);
  R5 := L.ItemRect(5);
  L.Perform(WM_MOUSEMOVE, 0, MakeLParam(50, (R5.Top + R5.Bottom) div 2 - (R5.Bottom - R5.Top)));
  L.Update; // Leisten eingeblendet, Zeile 4 hervorgehoben
  L.Paints := 0;
  L.Perform(WM_MOUSEMOVE, 0, MakeLParam(50, (R5.Top + R5.Bottom) div 2));
  L.Update;
  CheckEquals(1, L.Paints, 'ein Paint');
  CheckTrue(L.LastClip.Bottom - L.LastClip.Top <= 2 * (R5.Bottom - R5.Top) + 10,
    Format('Clip nur Zeilen 4 und 5: %d', [L.LastClip.Bottom - L.LastClip.Top]));
end;

procedure TAudit8ARepaintCountTests.NavigationViewHoverInvalidatesOnlyRows;
var
  N: TPPGNavigationView;
  I: Integer;
  R4, Box: TRect;
begin
  N := TPPGNavigationView.Create(FForm);
  N.Parent := FForm;
  N.Animation.Enabled := False;
  N.Height := 380;
  for I := 0 to 20 do
    N.Items.AddItem('Eintrag ' + IntToStr(I), PPGNavIconDocument, I);
  N.HandleNeeded;
  N.Update;
  R4 := N.RowRect(4);
  N.Perform(WM_MOUSEMOVE, 0, MakeLParam(30, (R4.Top + R4.Bottom) div 2));
  Box := UpdateBox(N);
  CheckFalse(IsRectEmpty(Box), 'Hover zeichnet die Zeile');
  CheckTrue(Box.Bottom - Box.Top <= R4.Bottom - R4.Top,
    Format('nur die Zeile: %d', [Box.Bottom - Box.Top]));
  N.Update;
  N.Perform(CM_MOUSELEAVE, 0, 0);
  Box := UpdateBox(N);
  CheckTrue((Box.Top >= R4.Top) and (Box.Bottom <= R4.Bottom), 'Verlassen: nur die Zeile');
end;

procedure TAudit8ARepaintCountTests.ToolBarHoverInvalidatesOnlyButtons;
var
  T: TPPGToolBar;
  I: Integer;
  R1, Box: TRect;
begin
  T := TPPGToolBar.Create(FForm);
  T.Parent := FForm;
  T.Width := 480;
  for I := 0 to 7 do
    T.Items.AddButton('Knopf ' + IntToStr(I));
  T.HandleNeeded;
  T.Update;
  R1 := T.ItemRect(1);
  T.Perform(WM_MOUSEMOVE, 0, MakeLParam((R1.Left + R1.Right) div 2, (R1.Top + R1.Bottom) div 2));
  Box := UpdateBox(T);
  CheckFalse(IsRectEmpty(Box), 'Hover zeichnet den Knopf');
  CheckTrue(Box.Right - Box.Left <= (R1.Right - R1.Left) + 6,
    Format('nur der Knopf: %d', [Box.Right - Box.Left]));
end;

procedure TAudit8ARepaintCountTests.StatusBarPanelTextInvalidatesOnlyPanel;
var
  S: TPPGStatusBar;
  I: Integer;
  Box: TRect;
begin
  S := TPPGStatusBar.Create(FForm);
  S.Parent := FForm;
  for I := 0 to 2 do
    S.Panels.Add.Width := 120;
  S.HandleNeeded;
  S.Update;
  S.Panels[1].Text := 'Neu';
  Box := UpdateBox(S);
  CheckTrue(EqualRect(Box, S.PanelRect(1)), 'nur der Abschnitt');
  S.Update;
  S.Panels[1].Width := 150;
  Box := UpdateBox(S);
  CheckEquals(S.ClientWidth, Box.Right - Box.Left, 'Breite: ganze Leiste');
end;

{ TAudit8AAnimatorTests }

procedure TAudit8AAnimatorTests.CountStep(Sender: TObject);
begin
  Inc(FSteps);
end;

procedure TAudit8AAnimatorTests.FreeVictimStep(Sender: TObject);
begin
  FreeAndNil(FVictim);
end;

procedure TAudit8AAnimatorTests.Pump(Ms: Cardinal);
var
  T0: Cardinal;
  Dummy: THandle;
begin
  Dummy := 0;
  T0 := GetTickCount;
  while GetTickCount - T0 < Ms do
  begin
    MsgWaitForMultipleObjects(0, Dummy, False, 10, QS_ALLINPUT);
    Application.ProcessMessages;
  end;
end;

function TAudit8AAnimatorTests.CountTimers(Ms: Cardinal): Integer;
var
  Msg: TMsg;
  T0: Cardinal;
  Dummy: THandle;
begin
  Result := 0;
  Dummy := 0;
  T0 := GetTickCount;
  while GetTickCount - T0 < Ms do
  begin
    MsgWaitForMultipleObjects(0, Dummy, False, 20, QS_ALLINPUT);
    while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
    begin
      if Msg.message = WM_TIMER then
        Inc(Result);
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end;
  end;
end;

procedure TAudit8AAnimatorTests.LongLoopSleepsBetweenSteps;
var
  A: TPPGAnimation;
begin
  A := TPPGAnimation.Create(nil);
  try
    A.OnStep := CountStep;
    A.StartLoop(60000, 1000);
    CheckEquals(1000, Integer(A.StepInterval));
    if PPGRunningAnimationCount = 1 then
      CheckTrue(PPGAnimatorInterval >= 900, Format('Timer schlaeft: %d ms', [PPGAnimatorInterval]));
    FSteps := 0;
    Pump(1350);
    CheckTrue((FSteps >= 1) and (FSteps <= 2), Format('ein Schritt je Sekunde: %d', [FSteps]));
  finally
    A.Free;
  end;
end;

procedure TAudit8AAnimatorTests.FrameAnimationRestoresFrameRate;
var
  A, B: TPPGAnimation;
begin
  A := TPPGAnimation.Create(nil);
  B := TPPGAnimation.Create(nil);
  try
    A.StartLoop(60000, 1000);
    B.AnimateTo(1, 150);
    CheckEquals(15, Integer(PPGAnimatorInterval), 'Frame-Takt, solange B laeuft');
    Pump(400);
    CheckFalse(B.Running, 'B fertig');
    CheckEquals(1, B.Value, 0.0001);
    if PPGRunningAnimationCount = 1 then
      CheckTrue(PPGAnimatorInterval >= 300, Format('danach wieder lang: %d ms', [PPGAnimatorInterval]));
  finally
    B.Free;
    A.Free;
  end;
end;

procedure TAudit8AAnimatorTests.DueModeEndsOnTime;
var
  A: TPPGAnimation;
  T0, Ms: Cardinal;
begin
  A := TPPGAnimation.Create(nil);
  try
    A.StepInterval := 60000;
    A.OnStep := CountStep;
    FSteps := 0;
    T0 := GetTickCount;
    A.AnimateTo(1, 300, ekLinear);
    while A.Running and (GetTickCount - T0 < 2000) do
      Pump(10);
    Ms := GetTickCount - T0;
    CheckFalse(A.Running, 'beendet');
    // Audit 11a #7: nur noch "nicht vor Ablauf der Dauer" (fachlich, unter
    // Last unveraendert); die obere Grenze (vorher 700 ms) misst der
    // Benchmark (Bench11)
    CheckTrue(Ms >= 280, Format('Ende erst nach der Dauer (300 ms), war %d ms', [Ms]));
    CheckEquals(1, A.Value, 0.0001);
    CheckEquals(1, FSteps, 'nur der letzte Schritt');
  finally
    A.Free;
  end;
end;

procedure TAudit8AAnimatorTests.StopKeepsCurrentValue;
var
  A: TPPGAnimation;
begin
  A := TPPGAnimation.Create(nil);
  try
    A.StepInterval := 60000;
    A.AnimateTo(1, 1000, ekLinear);
    Pump(500);
    A.Stop;
    CheckTrue((A.Value > 0.3) and (A.Value < 0.8), Format('Wert beim Anhalten: %.2f', [A.Value]));
  finally
    A.Free;
  end;
end;

procedure TAudit8AAnimatorTests.FreeingOtherAnimationDuringTickIsSafe;
var
  A: TPPGAnimation;
begin
  A := TPPGAnimation.Create(nil);
  FVictim := TPPGAnimation.Create(nil);
  try
    A.OnStep := FreeVictimStep;
    FVictim.OnStep := CountStep;
    A.StartLoop(1000);
    FVictim.StartLoop(1000);
    FSteps := 0;
    Pump(100);
    CheckNull(FVictim, 'freigegeben');
    CheckEquals(0, FSteps, 'freigegebene Animation nicht mehr getickt');
  finally
    FreeAndNil(FVictim);
    A.Free;
  end;
end;

procedure TAudit8AAnimatorTests.PlannerNowLineIdleWakeups;
var
  F: TForm;
  P: TPPGPlanner;
  N: Integer;
begin
  F := TForm.CreateNew(nil);
  try
    F.SetBounds(0, 0, 800, 600);
    F.Show;
    P := TPPGPlanner.Create(F);
    P.Parent := F;
    P.Align := alClient;
    P.View := pvWeek;
    P.Date := Date;
    P.ShowNowLine := True;
    P.Update;
    Pump(1800); // Aufbau-Animationen und Ausblenden der Leisten abwarten
    N := CountTimers(1000);
    CheckTrue(N <= 4, Format('Leerlauf mit Jetzt-Linie: %d Wakeups/s (%d Animationen, Takt %d ms)', [N, PPGRunningAnimationCount, PPGAnimatorInterval]));
  finally
    F.Free;
  end;
end;

procedure TAudit8AAnimatorTests.ScrollHoldIdleWakeups;
var
  F: TForm;
  L: TPPGListBox;
  I, N: Integer;
begin
  F := TForm.CreateNew(nil);
  try
    F.SetBounds(0, 0, 400, 400);
    F.Show;
    L := TPPGListBox.Create(F);
    L.Parent := F;
    L.Align := alClient;
    for I := 0 to 199 do
      L.Items.Add('Eintrag ' + IntToStr(I));
    L.Update;
    L.Perform(CM_MOUSEENTER, 0, 0);
    L.Perform(WM_MOUSEMOVE, 0, MakeLParam(50, 50));
    // Leisten einblenden (100 ms); danach haelt die Ruhe-Schleife sie
    // sichtbar und prueft nur alle 200 ms (vor dem Ausblenden nach 1,2 s)
    Pump(200);
    N := CountTimers(800);
    CheckTrue(N <= 6, Format('Maus ueber der Liste: %d Wakeups/s (%d Animationen, Takt %d ms)', [N, PPGRunningAnimationCount, PPGAnimatorInterval]));
  finally
    F.Free;
  end;
end;

procedure TAudit8AAnimatorTests.ToastLifetimeEndsWithoutFrames;
var
  F: TForm;
  C: TPPGNotificationCenter;
  T: TPPGToast;
  T0, Ticks0, Ms: Cardinal;
begin
  // Lebensdauer im Faelligkeitsmodus: Ende nach Duration, ohne Frame-Ticks.
  // Hover-Pausieren ausgeschlossen: Verlassen explizit melden (der echte
  // Mauszeiger koennte ueber der Toast-Ecke stehen)
  F := TForm.CreateNew(nil);
  try
    C := TPPGNotificationCenter.Create(F);
    C.Animation.Enabled := False;
    C.RespectQuietHours := False;
    Ticks0 := PPGAnimatorTicks;
    T0 := GetTickCount;
    T := C.Show('Kurz', 'Lebensdauer', psInformational, 400);
    T.Perform(CM_MOUSELEAVE, 0, 0);
    CheckEquals(1, C.VisibleCount);
    while (C.VisibleCount > 0) and (GetTickCount - T0 < 3000) do
      Pump(10);
    Ms := GetTickCount - T0;
    CheckEquals(0, C.VisibleCount, 'nach Duration geschlossen');
    // Audit 11a #7: nur noch "nicht vor Ablauf der Dauer"; die obere Grenze
    // (vorher 1000 ms) misst der Benchmark (Bench11)
    CheckTrue(Ms >= 370, Format('Ende erst nach der Dauer (400 ms), war %d ms', [Ms]));
    CheckTrue(PPGAnimatorTicks - Ticks0 <= 3,
      Format('Timer-Ticks bis zum Ende: %d', [PPGAnimatorTicks - Ticks0]));
  finally
    F.Free;
  end;
end;

{ TAudit8AMeasureTests }

function TAudit8AMeasureTests.Direct(const Text: string; Font: TFont; MaxWidth: Integer;
  WordWrap: Boolean): TSize;
var
  DC: HDC;
begin
  DC := CreateCompatibleDC(0);
  try
    Result := PPGGdiMeasureText(DC, Text, Font, MaxWidth, WordWrap);
  finally
    DeleteDC(DC);
  end;
end;

procedure TAudit8AMeasureTests.MatchesDirectMeasure;
const
  Texts: array[0..5] of string = ('', 'Wg', 'Hallo Welt', 'Ein etwas laengerer Text, der umbricht',
    'Zeile 1'#13#10'Zeile 2', '&Datei');
var
  F: TFont;
  I, J, W: Integer;
  A, B, C: TSize;
begin
  F := TFont.Create;
  try
    for J := 0 to 3 do
    begin
      case J of
        0:
          begin
            F.Name := 'Segoe UI';
            F.Size := 9;
            F.Style := [];
          end;
        1:
          begin
            F.Name := 'Segoe UI';
            F.Size := 14;
            F.Style := [fsBold];
          end;
        2:
          begin
            F.Name := 'Courier New';
            F.Size := 10;
            F.Style := [fsItalic];
          end;
      else
        begin
          F.Name := 'Tahoma';
          F.Height := -20;
          F.Style := [fsUnderline];
        end;
      end;
      for I := 0 to High(Texts) do
        for W := 0 to 1 do
        begin
          A := Direct(Texts[I], F, W * 100, W = 1);
          B := PPGMeasureTextNoCanvas(Texts[I], F, W * 100, W = 1);
          C := PPGMeasureTextNoCanvas(Texts[I], F, W * 100, W = 1);
          CheckEquals(A.cx, B.cx, Format('Breite %d/%d/%d', [J, I, W]));
          CheckEquals(A.cy, B.cy, Format('Hoehe %d/%d/%d', [J, I, W]));
          CheckEquals(B.cx, C.cx, 'Cache: Breite');
          CheckEquals(B.cy, C.cy, 'Cache: Hoehe');
        end;
    end;
  finally
    F.Free;
  end;
end;

procedure TAudit8AMeasureTests.FontChangeIsSeen;
var
  F: TFont;
  S1, S2: TSize;
begin
  F := TFont.Create;
  try
    F.Name := 'Segoe UI';
    F.Size := 9;
    S1 := PPGMeasureTextNoCanvas('Messen', F, 0, False);
    F.Size := 18;
    S2 := PPGMeasureTextNoCanvas('Messen', F, 0, False);
    CheckTrue(S2.cx > S1.cx, 'groessere Schrift');
    CheckEquals(Direct('Messen', F, 0, False).cx, S2.cx);
    F.Style := [fsBold];
    CheckEquals(Direct('Messen', F, 0, False).cx, PPGMeasureTextNoCanvas('Messen', F, 0, False).cx);
    F.Name := 'Courier New';
    CheckEquals(Direct('Messen', F, 0, False).cx, PPGMeasureTextNoCanvas('Messen', F, 0, False).cx);
  finally
    F.Free;
  end;
end;

procedure TAudit8AMeasureTests.SharedDCIsReused;
var
  F: TFont;
  N0, I: Integer;
begin
  F := TFont.Create;
  try
    N0 := PPGMeasureDCCount;
    for I := 0 to 499 do
      PPGMeasureTextNoCanvas('Text ' + IntToStr(I), F, 0, False);
    CheckTrue(PPGMeasureDCCount - N0 <= 1, Format('DCs: %d', [PPGMeasureDCCount - N0]));
  finally
    F.Free;
  end;
end;

{ TAudit8ARenderTests }

function TAudit8ARenderTests.NewBitmap(W, H: Integer): TBitmap;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(W, H);
  Result.Canvas.Brush.Color := clWhite;
  Result.Canvas.FillRect(Rect(0, 0, W, H));
end;

function TAudit8ARenderTests.MakeImages(Square: Boolean): TImageList;
var
  B, M: TBitmap;
begin
  // Ein 16x16-Bild mit Maske: Kreis bzw. volles Quadrat
  Result := TImageList.Create(nil);
  Result.Width := 16;
  Result.Height := 16;
  B := TBitmap.Create;
  M := TBitmap.Create;
  try
    B.SetSize(16, 16);
    B.Canvas.Brush.Color := clWhite;
    B.Canvas.FillRect(Rect(0, 0, 16, 16));
    B.Canvas.Brush.Color := clBlack;
    M.Monochrome := True;
    M.SetSize(16, 16);
    M.Canvas.Brush.Color := clWhite;
    M.Canvas.FillRect(Rect(0, 0, 16, 16));
    M.Canvas.Brush.Color := clBlack;
    if Square then
    begin
      B.Canvas.FillRect(Rect(0, 0, 16, 16));
      M.Canvas.FillRect(Rect(0, 0, 16, 16));
    end
    else
    begin
      B.Canvas.Ellipse(1, 1, 15, 15);
      M.Canvas.Ellipse(1, 1, 15, 15);
    end;
    Result.Add(B, M);
  finally
    M.Free;
    B.Free;
  end;
end;

procedure TAudit8ARenderTests.DrawSequence(B: TBitmap; Batch: Boolean);
var
  C: IPPGCanvas;
  F: TFont;
  DC: HDC;
  Brush: HBRUSH;
  S: TSize;
begin
  F := TFont.Create;
  try
    F.Name := 'Segoe UI';
    F.Size := 10;
    B.Canvas.Lock;
    try
      C := TPPGGdiPlusCanvas.Create(B.Canvas.Handle);
      if Batch then
        PPGBeginBatch(C);
      try
        C.FillRoundRect(Rect(5, 5, 120, 40), 6, clSilver, 255);
        C.DrawText(Rect(10, 8, 200, 30), 'Hallo', F, clBlack, DT_SINGLELINE);
        C.DrawText(Rect(10, 30, 200, 50), 'Welt', F, clNavy, DT_SINGLELINE);
        S := C.MeasureText('Messen', F, 0, False);
        C.PushClipRoundRect(Rect(0, 0, 90, 70), 8);
        try
          C.DrawText(Rect(60, 50, 260, 70), 'geschnitten lang lang', F, clMaroon, DT_SINGLELINE);
          C.FillRoundRect(Rect(70, 20, 140, 60), 0, clRed, 128);
          C.DrawText(Rect(40, 10 + S.cy, 260, 70), 'im Clip', F, clGreen, DT_SINGLELINE);
        finally
          C.PopClip;
        end;
        DC := C.BeginGdi;
        try
          Brush := CreateSolidBrush(clBlue);
          try
            FillRect(DC, Rect(150, 5, 170, 25), Brush);
          finally
            DeleteObject(Brush);
          end;
        finally
          C.EndGdi(DC);
        end;
        C.DrawFocusRect(Rect(175, 5, 230, 30));
        C.FillEllipse(Rect(180, 40, 210, 70), clTeal, 200);
        C.DrawText(Rect(150, 45, 260, 70), 'Ende', F, clBlack, DT_SINGLELINE);
      finally
        if Batch then
          PPGEndBatch(C);
      end;
      C := nil;
    finally
      B.Canvas.Unlock;
    end;
  finally
    F.Free;
  end;
end;

procedure TAudit8ARenderTests.BatchMatchesUnbatched;
var
  A, B: TBitmap;
begin
  A := NewBitmap(260, 80);
  B := NewBitmap(260, 80);
  try
    DrawSequence(A, False);
    DrawSequence(B, True);
    CheckEquals(0, PPGPixelDiff(A, B, 0), 'Block zeichnet gleich');
  finally
    B.Free;
    A.Free;
  end;
end;

procedure TAudit8ARenderTests.NestedGdiReusesDC;
var
  Bmp: TBitmap;
  C: IPPGCanvas;
  D1, D2: HDC;
  F: TFont;
begin
  Bmp := NewBitmap(100, 40);
  F := TFont.Create;
  try
    Bmp.Canvas.Lock;
    try
      C := TPPGGdiPlusCanvas.Create(Bmp.Canvas.Handle);
      PPGBeginBatch(C);
      try
        D1 := C.BeginGdi;
        try
          D2 := C.BeginGdi;
          try
            CheckTrue(D1 = D2, 'verschachtelt: derselbe DC');
          finally
            C.EndGdi(D2);
          end;
        finally
          C.EndGdi(D1);
        end;
        C.DrawText(Rect(0, 0, 100, 20), 'Text', F, clBlack, DT_SINGLELINE);
        // GDI+ im Block gibt den DC vorher zurueck (sonst ObjectBusy)
        C.FillRoundRect(Rect(10, 20, 50, 35), 4, clRed, 255);
        C.DrawText(Rect(60, 20, 100, 40), 'Text', F, clBlack, DT_SINGLELINE);
      finally
        PPGEndBatch(C);
      end;
      C := nil;
    finally
      Bmp.Canvas.Unlock;
    end;
    CheckEquals(Integer(clRed), Integer(Bmp.Canvas.Pixels[30, 27]), 'Flaeche im Block gezeichnet');
  finally
    F.Free;
    Bmp.Free;
  end;
end;

procedure TAudit8ARenderTests.FillRoundRectWithoutRadiusIsExact;
var
  A, B: TBitmap;
  C: IPPGCanvas;
  G: TGPGraphics;
  P: TGPGraphicsPath;
  Br: TGPSolidBrush;
  Alpha: Integer;
begin
  for Alpha := 0 to 1 do
  begin
    A := NewBitmap(60, 40);
    B := NewBitmap(60, 40);
    try
      C := TPPGGdiPlusCanvas.Create(A.Canvas.Handle);
      C.FillRoundRect(Rect(10, 10, 50, 30), 0, clRed, 128 + 127 * Alpha);
      C := nil;
      // Referenz: wie bisher ueber einen Rechteck-Pfad
      G := TGPGraphics.Create(B.Canvas.Handle);
      try
        G.SetSmoothingMode(SmoothingModeAntiAlias);
        G.SetPixelOffsetMode(PixelOffsetModeHalf);
        P := TGPGraphicsPath.Create;
        Br := TGPSolidBrush.Create(MakeColor(128 + 127 * Alpha, 255, 0, 0));
        try
          P.AddRectangle(MakeRect(10.0, 10.0, 40.0, 20.0));
          G.FillPath(Br, P);
        finally
          Br.Free;
          P.Free;
        end;
      finally
        G.Free;
      end;
      CheckEquals(0, PPGPixelDiff(A, B, 0), 'gleiche Pixel wie der Pfad');
      if Alpha = 1 then
      begin
        CheckEquals(Integer(clRed), Integer(A.Canvas.Pixels[10, 10]), 'Ecke innen');
        CheckEquals(Integer(clRed), Integer(A.Canvas.Pixels[49, 29]), 'Ecke innen unten');
        CheckEquals(Integer(clWhite), Integer(A.Canvas.Pixels[50, 30]), 'aussen');
      end;
    finally
      B.Free;
      A.Free;
    end;
  end;
end;

procedure TAudit8ARenderTests.TintCacheFollowsImageChange;
var
  IL, Sq: TImageList;
  B: TBitmap;
  Img, Msk: TBitmap;
begin
  IL := MakeImages(False);
  Sq := MakeImages(True);
  try
    B := NewBitmap(20, 20);
    try
      PPGGdiDrawImageTinted(B.Canvas.Handle, IL, 0, 2, 2, clBlue);
      CheckEquals(Integer(clWhite), Integer(B.Canvas.Pixels[2, 2]), 'Kreis: Ecke frei');
    finally
      B.Free;
    end;
    // Bild ersetzen (OnChange der Liste): danach das neue Bild
    Img := TBitmap.Create;
    Msk := TBitmap.Create;
    try
      Sq.GetBitmap(0, Img);
      Msk.Monochrome := True;
      Msk.SetSize(16, 16);
      Msk.Canvas.Brush.Color := clBlack;
      Msk.Canvas.FillRect(Rect(0, 0, 16, 16));
      IL.Replace(0, Img, Msk);
    finally
      Msk.Free;
      Img.Free;
    end;
    B := NewBitmap(20, 20);
    try
      PPGGdiDrawImageTinted(B.Canvas.Handle, IL, 0, 2, 2, clBlue);
      CheckEquals(Integer(clBlue), Integer(B.Canvas.Pixels[2, 2]), 'Quadrat: Ecke eingefaerbt');
    finally
      B.Free;
    end;
  finally
    Sq.Free;
    IL.Free;
  end;
end;

procedure TAudit8ARenderTests.TintCacheSurvivesListReuse;
var
  IL: TImageList;
  B: TBitmap;
  I: Integer;
begin
  // Freigegebene Liste, neue Liste (evtl. an derselben Adresse): kein altes Bild
  for I := 0 to 3 do
  begin
    IL := MakeImages(Odd(I));
    try
      B := NewBitmap(20, 20);
      try
        PPGGdiDrawImageTinted(B.Canvas.Handle, IL, 0, 2, 2, clBlue);
        if Odd(I) then
          CheckEquals(Integer(clBlue), Integer(B.Canvas.Pixels[2, 2]), 'Quadrat ' + IntToStr(I))
        else
          CheckEquals(Integer(clWhite), Integer(B.Canvas.Pixels[2, 2]), 'Kreis ' + IntToStr(I));
      finally
        B.Free;
      end;
    finally
      IL.Free;
    end;
  end;
end;

procedure TAudit8ARenderTests.CachedShadowMatchesDirect;
var
  Btn: TPPGButton;
  A, B: TBitmap;
  Pass: Integer;
begin
  Btn := NewButton('Schatten');
  Btn.SetBounds(10, 10, 180, 70);
  Btn.Shadow.Size := 8;
  Btn.Shadow.OffsetY := 3;
  Btn.Shadow.Opacity := 80;
  for Pass := 0 to 1 do
  begin
    if Pass = 1 then
      Btn.RoundedCorners := [pcTopLeft, pcBottomRight]; // eckige Ecken in der Vorlage
    PPGShadowCacheEnabled := False;
    try
      B := RenderToBitmap(Btn);
    finally
      PPGShadowCacheEnabled := True;
    end;
    try
      A := RenderToBitmap(Btn);
      try
        CheckEquals(0, PPGPixelDiff(A, B, 12), 'Vorlage wie direkt gezeichnet, Durchgang ' +
          IntToStr(Pass));
      finally
        A.Free;
      end;
    finally
      B.Free;
    end;
  end;
end;

{ TAudit11DRenderModeTests }

var
  GHookCalls: Integer;

procedure CountHookCall;
begin
  Inc(GHookCalls);
end;

procedure TAudit11DRenderModeTests.ShowAndValidate(C: TWinControl);
begin
  FForm.Show;
  FForm.Update;
  Application.ProcessMessages;
  // Alles gezeichnet: kein Fenster hat noch einen ungueltigen Bereich
  RedrawWindow(FForm.Handle, nil, 0, RDW_VALIDATE or RDW_ALLCHILDREN or RDW_NOERASE or
    RDW_NOFRAME);
  CheckFalse(GetUpdateRect(C.Handle, nil, False), 'Vorbedingung: Control gueltig');
  CheckFalse(GetUpdateRect(FForm.Handle, nil, False), 'Vorbedingung: Formular gueltig');
end;

procedure TAudit11DRenderModeTests.ThemeInstallsRedrawHook;
begin
  // PPG.Theme (im Testprojekt gelinkt) setzt den Haken beim Laden
  CheckTrue(Assigned(TPPGRendererRegistry.OnFallbackChanged),
    'PPG.Theme muss OnFallbackChanged setzen');
end;

procedure TAudit11DRenderModeTests.SetterCallsHookOnlyOnChange;
var
  Old: TPPGFallbackChangedProc;
begin
  Old := TPPGRendererRegistry.OnFallbackChanged;
  GHookCalls := 0;
  TPPGRendererRegistry.OnFallbackChanged := CountHookCall;
  try
    TPPGRendererRegistry.ForceGdiFallback := False;
    CheckEquals(0, GHookCalls, 'gleicher Wert: kein Aufruf');
    TPPGRendererRegistry.ForceGdiFallback := True;
    CheckEquals(1, GHookCalls, 'Wechsel auf GDI: ein Aufruf');
    CheckTrue(TPPGRendererRegistry.ForceGdiFallback, 'Wert uebernommen');
    TPPGRendererRegistry.ForceGdiFallback := True;
    CheckEquals(1, GHookCalls, 'erneut True: kein Aufruf');
    TPPGRendererRegistry.ForceGdiFallback := False;
    CheckEquals(2, GHookCalls, 'zurueck auf GDI+: ein Aufruf');
    CheckFalse(TPPGRendererRegistry.ForceGdiFallback, 'Wert zurueck');
  finally
    TPPGRendererRegistry.OnFallbackChanged := Old;
    TPPGRendererRegistry.ForceGdiFallback := False;
  end;
end;

procedure TAudit11DRenderModeTests.FallbackSwitchInvalidatesWindows;
var
  B: TPPGButton;
  Other: TForm;
begin
  B := NewButton('GDI');
  Other := TForm.CreateNew(nil);
  try
    Other.SetBounds(420, 0, 200, 120);
    Other.Show;
    Other.Update;
    ShowAndValidate(B);
    RedrawWindow(Other.Handle, nil, 0, RDW_VALIDATE or RDW_ALLCHILDREN or RDW_NOERASE or
      RDW_NOFRAME);
    TPPGRendererRegistry.ForceGdiFallback := True;
    // Ohne Zutun der Anwendung: Control, Formular und das zweite Formular
    CheckTrue(GetUpdateRect(B.Handle, nil, False), 'Control wird neu gezeichnet');
    CheckTrue(GetUpdateRect(FForm.Handle, nil, False), 'Formular wird neu gezeichnet');
    CheckTrue(GetUpdateRect(Other.Handle, nil, False), 'zweites Formular wird neu gezeichnet');
    // Der Paint danach laeuft mit dem GDI-Canvas und ohne Fehler
    FForm.Update;
    CheckEquals(0, FErrors.Count, 'Paint ohne Fehler: ' + FErrors.Text);
    ShowAndValidate(B);
    TPPGRendererRegistry.ForceGdiFallback := False;
    CheckTrue(GetUpdateRect(B.Handle, nil, False), 'zurueck: Control wird neu gezeichnet');
  finally
    Other.Free;
  end;
end;

procedure TAudit11DRenderModeTests.SameValueKeepsWindowsValid;
var
  B: TPPGButton;
begin
  B := NewButton('GDI+');
  ShowAndValidate(B);
  TPPGRendererRegistry.ForceGdiFallback := TPPGRendererRegistry.ForceGdiFallback;
  CheckFalse(GetUpdateRect(B.Handle, nil, False), 'gleicher Wert: kein Neuzeichnen');
end;

{ TAppHooksLifetimeTests }

procedure TAppHooksLifetimeTests.SetUp;
begin
  inherited;
  FWatched := nil;
  FCallsAfterFree := 0;
  FFreed := False;
end;

procedure TAppHooksLifetimeTests.CountingEvent(Control: TControl; var Message: TMessage);
begin
  if FFreed then
    Inc(FCallsAfterFree);
end;

procedure TAppHooksLifetimeTests.FreeingEvent(Control: TControl; var Message: TMessage);
begin
  if (Message.Msg = WM_AUDIT8_FREE) and not FFreed then
  begin
    FFreed := True;
    FreeAndNil(FWatched);
  end;
end;

procedure TAppHooksLifetimeTests.ObserverFreesControlStopsChain;
begin
  FWatched := TForm.CreateNew(nil);
  // Zuletzt angemeldet = zuerst gerufen: FreeingEvent laeuft vor CountingEvent
  PPGWatchControl(FWatched, CountingEvent);
  PPGWatchControl(FWatched, FreeingEvent);
  FWatched.Perform(WM_AUDIT8_FREE, 0, 0);
  CheckTrue(FFreed, 'Control freigegeben');
  CheckEquals(0, FCallsAfterFree,
    'nach dem Freigeben darf kein weiterer Beobachter gerufen werden');
end;

procedure TAppHooksLifetimeTests.ReleaseOfWatchedFormIsSafe;
var
  F: TForm;
  Spy: TFreeSpy;
  Freed: Boolean;
begin
  F := TForm.CreateNew(nil);
  PPGWatchControl(F, CountingEvent);
  CheckEquals(1, PPGControlWatchCount(F), 'Beobachter angemeldet');
  Freed := False;
  Spy := TFreeSpy.Create(F);
  Spy.Freed := @Freed;
  F.Release;
  // CM_RELEASE gibt das Formular in seiner eigenen (beobachteten) WndProc
  // frei; danach darf WatchProc den Beobachter nicht mehr anfassen.
  Application.ProcessMessages;
  // Audit 11a #4: vorher CheckTrue(True) - jetzt pruefen, dass CM_RELEASE
  // das Formular samt Beobachter wirklich freigegeben hat (ohne AV)
  CheckTrue(Freed, 'Formular per CM_RELEASE freigegeben');
end;

initialization
  RegisterTest('Audit8A', TAudit8APaintTests.Suite);
  RegisterTest('Audit8A', TAudit8ARepaintCountTests.Suite);
  RegisterTest('Audit8A', TAudit8AAnimatorTests.Suite);
  RegisterTest('Audit8A', TAudit8AMeasureTests.Suite);
  RegisterTest('Audit8A', TAudit8ARenderTests.Suite);
  RegisterTest('Audit8A', TAppHooksLifetimeTests.Suite);
  RegisterTest('Audit11D', TAudit11DRenderModeTests.Suite);

end.
