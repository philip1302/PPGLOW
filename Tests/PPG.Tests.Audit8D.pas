unit PPG.Tests.Audit8D;

{ Audit-Paket 8D (Docs\Audit-Paket8-Plan.md): Regressionstests.

  Die festhaltenden Tests vergleichen ein "benutztes" Control (Caches aus
  frueheren Abfragen, danach geaendert) mit einem frisch aufgebauten Control
  gleicher Einstellung bzw. mit einer Messung nach der alten Formel. Sie
  liefen vor den Optimierungen gegen den alten Code gruen. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Math, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Menus, Vcl.ComCtrls,
  Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Types, PPG.Appearance, PPG.Render.Gdi, PPG.AppHooks, PPG.MenuBar, PPG.Chart.Series,
  PPG.Chart, PPG.Kanban.Items, PPG.Kanban, PPG.DB.Kanban, PPG.Planner.Model, PPG.Planner,
  PPG.Ribbon.Layout, PPG.Ribbon.Items, PPG.Ribbon, PPG.TabStrip, PPG.TabControl, PPG.PageControl, PPG.Feedback,
  PPG.TeachingTip, PPG.TagEdit, PPG.Exceptions, PPG.Tests.Controls, PPG.CustomDraw,
  PPG.Tests.Audit8A;

type
  TAudit8DTests = class(TControlTestCase)
  private
    FHookLog: TStringList;
    procedure HookA(var Msg: TMsg; var Handled: Boolean);
    procedure HookB(var Msg: TMsg; var Handled: Boolean);
    procedure HookC(var Msg: TMsg; var Handled: Boolean);
    procedure WatchA(Control: TControl; var Message: TMessage);
    procedure WatchB(Control: TControl; var Message: TMessage);
    function NewMenu(Count: Integer): TMainMenu;
    procedure CheckMenuBarRects(Bar: TPPGMenuBar; const Context: string);
    procedure ConfigureChart(C: TPPGChart; Step: Integer);
    function ChartSignature(C: TPPGChart): string;
    function NewKanban(Cards: Integer): TPPGKanban;
    procedure CheckSameKanban(A, B: TPPGKanban; const Context: string);
    function NewPlanner: TPPGPlanner;
    function PieceDigest(P: TPPGPlanner): string;
    function NewRibbon(DisabledItem, DownItem: Boolean): TPPGRibbon;
    procedure CheckSameBitmap(A, B: TBitmap; const Context: string);
    function BitmapsEqual(A, B: TBitmap): Boolean;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure MenuBarRectsFollowChanges;
    procedure ChartHitTestMatchesFreshChart;
    procedure ChartHotFollowsHitTest;
    procedure KanbanHeightsMatchFreshBoard;
    procedure PlannerGroupedLayoutIsUnchanged;
    procedure PlannerTimelineLayoutIsUnchanged;
    procedure PlannerTimelinePaintMatchesFresh;
    procedure RibbonEnabledDownMatchFreshRibbon;
    procedure PageControlUpdateBracketKeepsOrder;
    procedure TabStripMakeVisibleIsMinimal;
    procedure InfoBarHeightMatchesFresh;
    procedure TeachingTipFollowsContentChange;
    procedure TagEditChipsFollowFont;
    procedure AppHooksChangesDuringDispatch;
  end;

  /// Zaehltests: wie oft gerechnet bzw. gemessen wird (nach den Optimierungen).
  TAudit8DCountTests = class(TControlTestCase)
  private
    function UpdateRectOf(C: TWinControl): TRect;
    /// Liegt der Punkt im ausstehenden Neuzeichnen-Bereich? (Rollleisten der
    /// Scroll-Controls duerfen dabei auftauchen.)
    function UpdatePending(C: TWinControl; X, Y: Integer): Boolean;
  published
    procedure MenuBarMeasuresOncePerChange;
    procedure MenuBarHoverRepaintsItemsOnly;
    procedure ChartHoverComputesNoLayout;
    procedure ChartTooltipMoveRepaintsTooltipOnly;
    procedure ChartAddXYTakesNoSnapshot;
    procedure ChartAddRangeEqualsAddXY;
    procedure ChartPiePointPosUsesSums;
    procedure PlannerHoverRepaintsItemOnly;
    procedure PlannerDragRepaintsOnlyOnGhostChange;
    procedure KanbanChangeMeasuresOneCard;
    procedure KanbanHoverRepaintsCardOnly;
    procedure RibbonEnabledKeepsLayout;
    procedure PageControlBracketBuildsOnce;
    procedure TabStripHoverRepaintsTabOnly;
  end;

  TAudit8DDBTests = class(TControlTestCase)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    FPosts: Integer;
    procedure CountPost(DataSet: TDataSet);
    procedure AddRow(AId: Integer; const AStatus: string; AOrder: Integer; const ATitle: string);
    function OrderOf(AId: Integer): Integer;
  protected
    procedure SetUp; override;
  published
    procedure SortedDataSetRenumbersInOrder;
  end;

  /// Audit 8E: Kanban und Planer zeichnen nur Karten bzw. Termine und Zeilen
  /// im neu zu zeichnenden Bereich (pixelgleich zum Voll-Paint).
  TAudit8EBoardTests = class(TAudit8PartialTestCase)
  private
    FDrawn: Integer;
    procedure CountCard(Sender: TObject; Canvas: TCanvas; const Card: TPPGKanbanCardData;
      const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
      var DefaultDraw: Boolean);
    procedure CountAppointment(Sender: TObject; Canvas: TCanvas; Appointment: TPPGAppointment;
      const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
      var DefaultDraw: Boolean);
    function NewBoard(Cards: Integer; Lanes: Boolean): TPPGKanban;
    function NewPlanner(AView: TPPGPlannerView): TPPGPlanner;
  protected
    procedure SetUp; override;
  published
    procedure KanbanPartialRepaint;
    procedure KanbanPartialRepaintLanes;
    procedure KanbanHoverMatchesFullPaint;
    procedure KanbanPartialPaintDrawsOnlyCardsInClip;
    procedure PlannerPartialRepaintViews;
    procedure PlannerHoverMatchesFullPaint;
    procedure PlannerPartialPaintDrawsOnlyItemsInClip;
  end;

implementation

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := MakeLParam(Word(SmallInt(X)), Word(SmallInt(Y)));
end;

function RectText(const R: TRect): string;
begin
  Result := Format('(%d,%d,%d,%d)', [R.Left, R.Top, R.Right, R.Bottom]);
end;

function Digest(const S: string): Int64;
var
  I: Integer;
begin
  Result := 17;
  for I := 1 to Length(S) do
    Result := (Result * 131 + Ord(S[I])) mod 1000000007;
end;

function BitmapDigest(B: TBitmap): Int64;
var
  X, Y: Integer;
  P: PByte;
begin
  B.PixelFormat := pf24bit;
  Result := 17;
  for Y := 0 to B.Height - 1 do
  begin
    P := B.ScanLine[Y];
    for X := 0 to B.Width * 3 - 1 do
    begin
      Result := (Result * 131 + P^) mod 1000000007;
      Inc(P);
    end;
  end;
end;

{ TAudit8DTests }

procedure TAudit8DTests.SetUp;
begin
  inherited SetUp;
  FHookLog := TStringList.Create;
end;

procedure TAudit8DTests.TearDown;
begin
  FreeAndNil(FHookLog);
  inherited TearDown;
end;

function TAudit8DTests.BitmapsEqual(A, B: TBitmap): Boolean;
var
  Y: Integer;
begin
  Result := (A.Width = B.Width) and (A.Height = B.Height);
  if not Result then
    Exit;
  A.PixelFormat := pf24bit;
  B.PixelFormat := pf24bit;
  for Y := 0 to A.Height - 1 do
    if not CompareMem(A.ScanLine[Y], B.ScanLine[Y], A.Width * 3) then
      Exit(False);
end;

procedure TAudit8DTests.CheckSameBitmap(A, B: TBitmap; const Context: string);
begin
  CheckTrue(BitmapsEqual(A, B), Context + ': Bilder verschieden');
end;

{ ---- MenuBar ---- }

function TAudit8DTests.NewMenu(Count: Integer): TMainMenu;
var
  I: Integer;
  It: TMenuItem;
begin
  Result := TMainMenu.Create(FForm);
  for I := 0 to Count - 1 do
  begin
    It := TMenuItem.Create(Result);
    It.Caption := '&Menue ' + IntToStr(I) + StringOfChar('x', I mod 4);
    It.Add(TMenuItem.Create(Result));
    It.Items[0].Caption := 'Eintrag';
    Result.Items.Add(It);
  end;
end;

procedure TAudit8DTests.CheckMenuBarRects(Bar: TPPGMenuBar; const Context: string);
var
  I, X, W, PPI, Pad: Integer;
  R, Exp: TRect;
  P: TPoint;
begin
  // Alte Formel: Eintraege nebeneinander, je Text + 2 x Rand
  PPI := Bar.ScalePPI;
  Pad := PPGScale(10, PPI);
  X := PPGScale(4, PPI);
  for I := 0 to Bar.ItemCount - 1 do
  begin
    W := PPGMeasureTextNoCanvas(Bar.Item(I).Caption, Bar.Font, 0, False).cx + 2 * Pad;
    Exp := Rect(X, PPGScale(4, PPI), X + W, Bar.ClientHeight - PPGScale(4, PPI));
    if Bar.UseRightToLeftAlignment then
      Exp := Rect(Bar.ClientWidth - Exp.Right, Exp.Top, Bar.ClientWidth - Exp.Left, Exp.Bottom);
    Inc(X, W);
    R := Bar.ItemRect(I);
    CheckEquals(RectText(Exp), RectText(R), Context + ': ItemRect ' + IntToStr(I));
    P := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
    CheckEquals(I, Bar.ItemAtPos(P.X, P.Y), Context + ': ItemAtPos ' + IntToStr(I));
  end;
  CheckEquals(-1, Bar.ItemAtPos(-5, 2), Context + ': ausserhalb');
end;

procedure TAudit8DTests.MenuBarRectsFollowChanges;
var
  Bar: TPPGMenuBar;
  M: TMainMenu;
  It: TMenuItem;
  I: Integer;
begin
  FForm.Width := 900;
  M := NewMenu(10);
  Bar := TPPGMenuBar.Create(FForm);
  Bar.Parent := FForm;
  Bar.Menu := M;
  Bar.HandleNeeded;
  CheckMenuBarRects(Bar, 'Start');
  // Mausbewegungen fuellen einen etwaigen Zwischenspeicher
  for I := 0 to 40 do
    Bar.Perform(WM_MOUSEMOVE, 0, MouseLParam(I * 20, Bar.Height div 2));
  M.Items[2].Caption := '&Ein viel laengerer Titel';
  CheckMenuBarRects(Bar, 'Titel geaendert');
  M.Items[4].Visible := False;
  CheckMenuBarRects(Bar, 'ausgeblendet');
  It := TMenuItem.Create(M);
  It.Caption := '&Neu';
  M.Items.Insert(1, It);
  CheckMenuBarRects(Bar, 'eingefuegt');
  M.Items[0].Free;
  CheckMenuBarRects(Bar, 'entfernt');
  Bar.Font.Size := Bar.Font.Size + 4;
  CheckMenuBarRects(Bar, 'Schrift');
  Bar.BiDiMode := bdRightToLeft;
  CheckMenuBarRects(Bar, 'RTL');
  FForm.Width := 700;
  CheckMenuBarRects(Bar, 'RTL schmaler');
  Bar.BiDiMode := bdLeftToRight;
  CheckMenuBarRects(Bar, 'LTR');
  Bar.Menu := NewMenu(3);
  CheckMenuBarRects(Bar, 'anderes Menue');
  Bar.Free;
end;

{ ---- Chart ---- }

procedure TAudit8DTests.ConfigureChart(C: TPPGChart; Step: Integer);
var
  S: TPPGChartSeries;
begin
  if Step < 0 then
  begin
    // Grundaufbau
    C.Parent := FForm;
    C.Animation.Enabled := False;
    C.SetBounds(0, 0, 600, 320);
    S := C.Series.Add;
    S.Title := 'Umsatz';
    S.Kind := cskColumn;
    S.SetValues([3, 5, 2, 8, 6, 4, 7]);
    S := C.Series.Add;
    S.Title := 'Kosten';
    S.Kind := cskLine;
    S.SetValues([2, 4, 3, 5, 4, 3, 6]);
    Exit;
  end;
  case Step of
    0: C.Series[0].Add(9);
    1: C.SetBounds(0, 0, 520, 360);
    2: C.Font.Size := C.Font.Size + 3;
    3: C.LegendPosition := clpRight;
    4: C.Series[1].Visible := False;
    5:
      begin
        C.YAxis.AutoMax := False;
        C.YAxis.Max := 20;
      end;
    6: C.Title := 'Quartal';
    7: C.BiDiMode := bdRightToLeft;
    8: C.Stacking := cstStacked;
    9: C.Categories.Text := 'Jan'#13#10'Feb'#13#10'Maerz';
    10: C.Series[0].Y[2] := 15;
    11: C.Series[1].Visible := True;
    12: C.LegendPosition := clpTop;
    13: C.YAxis.Format := '0.000';
  end;
end;

function TAudit8DTests.ChartSignature(C: TPPGChart): string;
var
  X, Y: Integer;
  H: TPPGChartHit;
  P: TPoint;
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    Y := 2;
    while Y < C.ClientHeight do
    begin
      X := 2;
      while X < C.ClientWidth do
      begin
        H := C.HitTest(X, Y);
        SB.Append(Ord(H.Kind)).Append(',').Append(H.Series).Append(',').Append(H.Index).Append(';');
        Inc(X, 9);
      end;
      Inc(Y, 9);
    end;
    if C.PointPos(0, 1, P) then
      SB.Append(P.X).Append('/').Append(P.Y);
    SB.Append(RectText(C.Layout.PlotR));
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TAudit8DTests.ChartHitTestMatchesFreshChart;
var
  Used, Fresh: TPPGChart;
  Step, K, I: Integer;
  BU, BF: TBitmap;
begin
  Used := TPPGChart.Create(FForm);
  ConfigureChart(Used, -1);
  for Step := 0 to 13 do
  begin
    // Benutzen: zeichnen, Maus bewegen (fuellt einen etwaigen Cache)
    BU := RenderToBitmap(Used);
    BU.Free;
    for I := 0 to 10 do
      Used.Perform(WM_MOUSEMOVE, 0, MouseLParam(30 + I * 50, 40 + I * 20));
    ConfigureChart(Used, Step);
    Fresh := TPPGChart.Create(FForm);
    try
      ConfigureChart(Fresh, -1);
      for K := 0 to Step do
        ConfigureChart(Fresh, K);
      CheckEquals(ChartSignature(Fresh), ChartSignature(Used), 'Schritt ' + IntToStr(Step));
      // Ohne Maus (kein Tooltip) zeichnen beide gleich
      Used.Perform(CM_MOUSELEAVE, 0, 0);
      BU := RenderToBitmap(Used);
      BF := RenderToBitmap(Fresh);
      try
        CheckSameBitmap(BF, BU, 'Bild Schritt ' + IntToStr(Step));
      finally
        BU.Free;
        BF.Free;
      end;
    finally
      Fresh.Free;
    end;
  end;
end;

procedure TAudit8DTests.ChartHotFollowsHitTest;
var
  C: TPPGChart;
  I, X, Y: Integer;
  H: TPPGChartHit;
begin
  C := TPPGChart.Create(FForm);
  ConfigureChart(C, -1);
  for I := 0 to 30 do
  begin
    X := 20 + I * 18;
    Y := 30 + (I * 37) mod 250;
    C.Perform(WM_MOUSEMOVE, 0, MouseLParam(X, Y));
    H := C.HitTest(X, Y);
    CheckEquals(Ord(H.Kind), Ord(C.Hot.Kind), 'Art ' + IntToStr(I));
    CheckEquals(H.Series, C.Hot.Series, 'Serie ' + IntToStr(I));
    CheckEquals(H.Index, C.Hot.Index, 'Index ' + IntToStr(I));
    if I = 15 then
    begin
      // Daten aendern: Hit-Test sieht sofort die neuen Daten
      C.Series[0].Add(30);
      C.Series[1].Add(1);
    end;
  end;
end;

{ ---- Kanban ---- }

function TAudit8DTests.NewKanban(Cards: Integer): TPPGKanban;
var
  I: Integer;
  Col: array[0..2] of TPPGKanbanColumn;
begin
  Result := TPPGKanban.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 900, 600);
  Result.Animation.Enabled := False;
  for I := 0 to 2 do
    Col[I] := Result.Columns.AddColumn('Spalte ' + IntToStr(I));
  Result.Cards.BeginUpdate;
  try
    for I := 0 to Cards - 1 do
      with Result.Cards.AddCard(Col[I mod 3].Id, 'Aufgabe ' + IntToStr(I), 'Text <b>' + IntToStr(I) + '</b>') do
      begin
        if I mod 2 = 0 then
          Labels := 'Bug, UI';
        if I mod 3 = 0 then
          Assignee := 'Anna Berg';
        if I mod 4 = 0 then
          Progress := 40;
      end;
  finally
    Result.Cards.EndUpdate;
  end;
end;

procedure TAudit8DTests.CheckSameKanban(A, B: TPPGKanban; const Context: string);
var
  C, I: Integer;
  BA, BB: TBitmap;
begin
  CheckEquals(B.ColumnCount, A.ColumnCount, Context + ': Spalten');
  for C := 0 to B.ColumnCount - 1 do
  begin
    CheckEquals(B.CardCount(C, 0), A.CardCount(C, 0), Context + ': Karten ' + IntToStr(C));
    for I := 0 to B.CardCount(C, 0) - 1 do
      CheckEquals(RectText(B.CardRect(C, 0, I)), RectText(A.CardRect(C, 0, I)),
        Context + Format(': Karte %d/%d', [C, I]));
  end;
  BA := RenderToBitmap(A);
  BB := RenderToBitmap(B);
  try
    CheckSameBitmap(BB, BA, Context);
  finally
    BA.Free;
    BB.Free;
  end;
end;

procedure TAudit8DTests.KanbanHeightsMatchFreshBoard;
const
  Long = 'Ein deutlich laengerer Titel, der auf jeden Fall in die zweite Zeile umbricht';
var
  Used, Fresh: TPPGKanban;
  Step, K: Integer;
  B: TBitmap;

  procedure Apply(Kb: TPPGKanban; S: Integer);
  begin
    case S of
      0: Kb.Cards[4].Title := Long;
      1: Kb.Cards[7].Labels := '';
      2: Kb.Cards[1].Text := 'Erste Zeile<br>Zweite Zeile<br>Dritte Zeile';
      3: Kb.FilterText := '1';
      4: Kb.ColumnWidth := 220;
      5: Kb.FilterText := '';
      6: Kb.Cards[2].Assignee := '';
      7: Kb.Font.Size := Kb.Font.Size + 2;
      8: Kb.MaxTextLines := 1;
      9: Kb.Cards[4].Title := 'kurz';
      10: Kb.Cards[5].Progress := -1;
      11: Kb.Cards[3].Color := clRed;
      12: Kb.Cards.Delete(6);
      13: Kb.Cards.AddCard(Kb.Columns[1].Id, Long, 'neu');
    end;
  end;

begin
  Used := NewKanban(30);
  for Step := 0 to 13 do
  begin
    B := RenderToBitmap(Used);
    B.Free;
    Apply(Used, Step);
    Fresh := NewKanban(30);
    try
      for K := 0 to Step do
        Apply(Fresh, K);
      CheckSameKanban(Used, Fresh, 'Schritt ' + IntToStr(Step));
    finally
      Fresh.Free;
    end;
  end;
end;

{ ---- Planner ---- }

function TAudit8DTests.NewPlanner: TPPGPlanner;
var
  I: Integer;
  A: TPPGAppointment;
  D: TDateTime;
begin
  Result := TPPGPlanner.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 1000, 640);
  Result.ShowNowLine := False;
  Result.Animation.Enabled := False;
  Result.Resources.AddResource(1, 'Anna');
  Result.Resources.AddResource(2, 'Ben');
  Result.Resources.AddResource(3, 'Cleo');
  Result.Resources.AddResource(2, 'Doppelt');
  Result.Resources.AddResource(5, 'Emil');
  D := EncodeDate(2025, 3, 3);
  Result.Appointments.BeginUpdate;
  try
    for I := 0 to 239 do
    begin
      A := Result.Appointments.AddAppointment(D + (I mod 9) + (7 + (I * 5) mod 11) / 24 + (I mod 4) / 96,
        D + (I mod 9) + (8 + (I * 5) mod 11) / 24 + (I mod 3) / 48, 'Termin ' + IntToStr(I));
      // 4 = unbekannte Ressource, 0 = keine
      A.ResourceId := I mod 6;
      if I mod 17 = 0 then
        A.AllDay := True;
      if I mod 23 = 0 then
        A.FinishTime := A.StartTime + 2.5;
    end;
  finally
    Result.Appointments.EndUpdate;
  end;
  Result.Date := D + 2;
end;

function TAudit8DTests.PieceDigest(P: TPPGPlanner): string;
var
  I: Integer;
  Pc: TPPGPlannerPiece;
  S: string;
begin
  S := '';
  for I := 0 to P.PieceCount - 1 do
  begin
    Pc := P.Piece(I);
    S := S + Format('%d:%d:%d:%d:%d%s;', [Pc.Item, Ord(Pc.Area), Ord(Pc.Band), Ord(Pc.ContBefore),
      Ord(Pc.ContAfter), RectText(Pc.R)]);
  end;
  Result := Format('%d/%d', [P.PieceCount, Digest(S)]);
end;

procedure TAudit8DTests.PlannerGroupedLayoutIsUnchanged;
var
  P: TPPGPlanner;
  S: string;
begin
  P := NewPlanner;
  P.View := pvWeek;
  P.EnsureLayout;
  S := PieceDigest(P);
  P.View := pvWorkWeek;
  P.EnsureLayout;
  S := S + '|' + PieceDigest(P);
  P.GroupByResource := False;
  P.EnsureLayout;
  S := S + '|' + PieceDigest(P);
  P.View := pvMonth;
  P.EnsureLayout;
  S := S + '|' + PieceDigest(P);
  if P.ScalePPI <> 96 then
  begin
    Status('PPI <> 96: Vergleich mit dem Referenzwert uebersprungen (' + S + ')');
    Exit;
  end;
  // Referenz: alter Code (vor Audit 8D), 96 PPI
  CheckEquals('121/710716172|81/348966264|135/753421768|11/471133041', S, 'Anordnung Woche/Arbeitswoche/ohne Gruppen/Monat');
end;

procedure TAudit8DTests.PlannerTimelineLayoutIsUnchanged;
var
  P: TPPGPlanner;
  S: string;
begin
  P := NewPlanner;
  P.View := pvTimeline;
  P.TimelineDays := 14;
  P.EnsureLayout;
  S := PieceDigest(P);
  if P.ScalePPI <> 96 then
  begin
    Status('PPI <> 96: Vergleich mit dem Referenzwert uebersprungen (' + S + ')');
    Exit;
  end;
  CheckEquals('174/691175223', S, 'Anordnung Zeitleiste');
end;

procedure TAudit8DTests.PlannerTimelinePaintMatchesFresh;
var
  P: TPPGPlanner;
  B: TBitmap;
  I: Integer;
  S: string;
begin
  P := NewPlanner;
  P.View := pvTimeline;
  P.TimelineDays := 60;
  P.SlotMinutes := 60;
  S := '';
  for I := 0 to 4 do
  begin
    P.ScrollTo(I * 1733, I * 23);
    B := RenderToBitmap(P);
    try
      S := S + IntToStr(BitmapDigest(B)) + ';';
    finally
      B.Free;
    end;
  end;
  if P.ScalePPI <> 96 then
  begin
    Status('PPI <> 96: Vergleich mit dem Referenzwert uebersprungen (' + S + ')');
    Exit;
  end;
  CheckEquals('615531511;924146489;125693176;400710589;716246505;', S, 'Bilder der Zeitleiste');
end;

{ ---- Ribbon ---- }

function TAudit8DTests.NewRibbon(DisabledItem, DownItem: Boolean): TPPGRibbon;
var
  G: TPPGRibbonGroup;
  It: TPPGRibbonItem;
begin
  Result := TPPGRibbon.Create(FForm);
  Result.Parent := FForm;
  Result.Width := 900;
  G := Result.Tabs.AddTab('Start').Groups.AddGroup('Zwischenablage');
  G.Items.AddButton('Einfuegen', $E77F, rsLarge);
  It := G.Items.AddButton('Ausschneiden', $E8C6, rsMedium);
  It.Enabled := not DisabledItem;
  G.Items.AddButton('Kopieren', $E8C8, rsMedium);
  G := Result.Tabs[0].Groups.AddGroup('Absatz');
  It := G.Items.AddCheck('Fett', $E8DD, rsSmall);
  It.Down := DownItem;
  G.Items.AddCheck('Kursiv', $E8DB, rsSmall);
end;

procedure TAudit8DTests.RibbonEnabledDownMatchFreshRibbon;
var
  Used, Fresh: TPPGRibbon;
  B0, BU, BF: TBitmap;
begin
  Used := NewRibbon(False, False);
  B0 := RenderToBitmap(Used);
  try
    Used.Tabs[0].Groups[0].Items[1].Enabled := False;
    Used.Tabs[0].Groups[1].Items[0].Down := True;
    BU := RenderToBitmap(Used);
    Fresh := NewRibbon(True, True);
    BF := RenderToBitmap(Fresh);
    try
      CheckFalse(BitmapsEqual(B0, BU), 'Aenderung sichtbar');
      CheckSameBitmap(BF, BU, 'wie frisch aufgebaut');
    finally
      BU.Free;
      BF.Free;
      Fresh.Free;
    end;
    // Zurueck: wieder wie am Anfang
    Used.Tabs[0].Groups[0].Items[1].Enabled := True;
    Used.Tabs[0].Groups[1].Items[0].Down := False;
    BU := RenderToBitmap(Used);
    try
      CheckSameBitmap(B0, BU, 'zurueck');
    finally
      BU.Free;
    end;
  finally
    B0.Free;
  end;
end;

{ ---- PageControl / TabStrip ---- }

procedure TAudit8DTests.PageControlUpdateBracketKeepsOrder;
var
  A, B: TPPGPageControl;
  S: TPPGTabSheet;
  I: Integer;
  First: TPPGTabSheet;

  procedure Fill(PC: TPPGPageControl; Bracket: Boolean);
  var
    K: Integer;
    T: TPPGTabSheet;
  begin
    if Bracket then
      PC.BeginUpdate;
    try
      for K := 0 to 29 do
      begin
        T := TPPGTabSheet.Create(PC);
        T.Caption := 'Seite ' + IntToStr(K) + StringOfChar('w', K mod 5);
        T.PageControl := PC;
        if K = 3 then
          T.TabVisible := False;
      end;
      PC.Pages[10].PageIndex := 2;
      PC.Pages[29].Free;
    finally
      if Bracket then
        PC.EndUpdate;
    end;
  end;

begin
  FForm.Width := 800;
  A := TPPGPageControl.Create(FForm);
  A.Parent := FForm;
  A.SetBounds(0, 0, 700, 250);
  B := TPPGPageControl.Create(FForm);
  B.Parent := FForm;
  B.SetBounds(0, 0, 700, 250);
  Fill(A, True);
  Fill(B, False);
  CheckEquals(B.PageCount, A.PageCount, 'Anzahl');
  for I := 0 to B.PageCount - 1 do
    CheckEquals(B.Pages[I].Caption, A.Pages[I].Caption, 'Reihenfolge ' + IntToStr(I));
  First := B.ActivePage;
  CheckTrue(First <> nil, 'aktive Seite');
  CheckEquals(First.Caption, A.ActivePage.Caption, 'aktive Seite gleich');
  for I := 0 to B.PageCount - 1 do
    CheckEquals(RectText(B.TabRect(I)), RectText(A.TabRect(I)), 'Reiter ' + IntToStr(I));
  A.ActivePageIndex := A.PageCount - 1;
  B.ActivePageIndex := B.PageCount - 1;
  for I := 0 to B.PageCount - 1 do
    CheckEquals(RectText(B.TabRect(I)), RectText(A.TabRect(I)), 'Reiter nach Wahl ' + IntToStr(I));
  // Klammer mit Entfernen der aktiven Seite
  A.BeginUpdate;
  try
    S := A.ActivePage;
    S.Free;
  finally
    A.EndUpdate;
  end;
  CheckTrue(A.ActivePage <> nil, 'Nachbarseite aktiv');
  CheckEquals(B.Pages[B.PageCount - 2].Caption, A.ActivePage.Caption, 'Nachbar');
end;

procedure TAudit8DTests.TabStripMakeVisibleIsMinimal;
var
  T: TPPGTabControl;
  I, Pos, First, Pass: Integer;
  R: TRect;
  S: string;
begin
  S := '';
  T := TPPGTabControl.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(0, 0, 380, 120);
  for I := 0 to 39 do
    T.Tabs.Add('Reiter ' + IntToStr(I) + StringOfChar('m', I mod 6));
  CheckTrue(T.Strip.Overflow, 'Ueberlauf');
  for Pass := 0 to 1 do
  begin
    if Pass = 1 then
      T.TabPosition := tpLeft;
    for Pos := 0 to 39 do
    begin
      T.TabIndex := (Pos * 17) mod 40;
      I := T.Strip.PosOf(T.TabIndex);
      R := T.Strip.TabRectAt(I);
      CheckFalse(IsRectEmpty(R), 'sichtbar ' + IntToStr(Pos));
      First := T.Strip.FirstVisible;
      CheckTrue(First <= I, 'erster sichtbarer davor');
      if Pass = 0 then
        CheckTrue(R.Right <= T.Strip.PrevRect.Left, 'nicht unter den Pfeilen ' + IntToStr(Pos));
      S := S + IntToStr(First) + ',';
    end;
  end;
  if T.ScalePPI <> 96 then
  begin
    Status('PPI <> 96: Vergleich mit dem Referenzwert uebersprungen (' + S + ')');
    Exit;
  end;
  // Referenz: erste sichtbare Reiter mit dem alten MakeVisible (96 PPI)
  CheckEquals('0,16,32,11,26,5,20,37,16,31,10,25,4,19,36,15,30,9,24,3,18,35,14,29,8,23,2,17,34,13,' +
    '28,7,22,1,16,34,12,28,6,22,0,16,33,11,27,5,21,38,16,32,10,26,4,20,37,15,31,9,25,3,19,36,14,' +
    '30,8,24,2,18,35,13,29,7,23,1,17,34,12,28,6,22,', S, 'erste sichtbare Reiter');
end;

{ ---- InfoBar / TeachingTip / TagEdit ---- }

procedure TAudit8DTests.InfoBarHeightMatchesFresh;
var
  Used, Fresh: TPPGInfoBar;
  Step, K: Integer;

  procedure Apply(B: TPPGInfoBar; S: Integer);
  begin
    case S of
      0: B.Message := 'Kurz';
      1: B.Message := StringOfChar('a', 20) + ' ' + StringOfChar('b', 300) + ' Ende <b>fett</b>';
      2: B.Width := 300;
      3: B.Font.Size := B.Font.Size + 3;
      4: B.Title := 'Ein Titel';
      5: B.ActionCaption := 'Aktion';
      6: B.ShowCloseButton := False;
      7: B.Width := 640;
      8: B.Style.Font.Size := 16;
    end;
  end;

  function NewBar: TPPGInfoBar;
  begin
    Result := TPPGInfoBar.Create(FForm);
    Result.Parent := FForm;
    Result.Animation.Enabled := False;
    Result.Width := 500;
    Result.Message := 'Start';
  end;

begin
  Used := NewBar;
  for Step := 0 to 8 do
  begin
    Apply(Used, Step);
    Fresh := NewBar;
    try
      for K := 0 to Step do
        Apply(Fresh, K);
      CheckEquals(Fresh.Height, Used.Height, 'Hoehe Schritt ' + IntToStr(Step));
    finally
      Fresh.Free;
    end;
  end;
end;

procedure TAudit8DTests.TeachingTipFollowsContentChange;
var
  Target: TPPGTagEdit;
  Tip: TPPGTeachingTip;
  R1, R2, R3: TRect;
  I: Integer;
begin
  FForm.Show;
  try
    Target := TPPGTagEdit.Create(FForm);
    Target.Parent := FForm;
    Target.SetBounds(40, 40, 200, 30);
    Tip := TPPGTeachingTip.Create(FForm);
    Tip.Title := 'Titel';
    Tip.Text := 'Kurz';
    Tip.ShowFor(Target);
    for I := 0 to 20 do
      Application.ProcessMessages;
    GetWindowRect(Tip.Window.Handle, R1);
    Tip.Text := 'Ein deutlich laengerer Text, der mehrere Zeilen braucht und das Fenster ' +
      'hoeher macht als vorher. Noch ein Satz, damit es sicher umbricht.';
    for I := 0 to 20 do
      Application.ProcessMessages;
    GetWindowRect(Tip.Window.Handle, R2);
    CheckTrue(R2.Bottom - R2.Top > R1.Bottom - R1.Top, 'hoeher nach Textaenderung');
    Tip.Hide;
    Tip.ShowFor(Target);
    for I := 0 to 20 do
      Application.ProcessMessages;
    GetWindowRect(Tip.Window.Handle, R3);
    CheckEquals(RectText(R3), RectText(R2), 'wie frisch gezeigt');
    Tip.Hide;
  finally
    FForm.Hide;
  end;
end;

procedure TAudit8DTests.TagEditChipsFollowFont;
var
  A, B: TPPGTagEdit;
  I: Integer;

  function NewEdit: TPPGTagEdit;
  begin
    Result := TPPGTagEdit.Create(FForm);
    Result.Parent := FForm;
    Result.SetBounds(0, 0, 360, 30);
    Result.Tags.Add('Delphi');
    Result.Tags.Add('VCL');
    Result.Tags.Add('Ein langer Eintrag');
    Result.Tags.Add('XE2');
  end;

begin
  A := NewEdit;
  for I := 0 to A.Tags.Count - 1 do
    A.ChipRect(I);
  A.Font.Size := A.Font.Size + 4;
  A.Tags.Add('Neu');
  B := NewEdit;
  B.Font.Size := B.Font.Size + 4;
  B.Tags.Add('Neu');
  CheckEquals(B.Height, A.Height, 'Hoehe');
  for I := 0 to B.Tags.Count - 1 do
    CheckEquals(RectText(B.ChipRect(I)), RectText(A.ChipRect(I)), 'Chip ' + IntToStr(I));
end;

{ ---- AppHooks ---- }

procedure TAudit8DTests.HookA(var Msg: TMsg; var Handled: Boolean);
begin
  if Msg.message = WM_USER + 802 then
    FHookLog.Add('A');
end;

procedure TAudit8DTests.HookB(var Msg: TMsg; var Handled: Boolean);
begin
  if Msg.message <> WM_USER + 802 then
    Exit;
  FHookLog.Add('B');
  // Waehrend der Verteilung: A abmelden, C anmelden
  PPGRemoveMessageHook(HookA);
  PPGAddMessageHook(HookC);
end;

procedure TAudit8DTests.HookC(var Msg: TMsg; var Handled: Boolean);
begin
  if Msg.message = WM_USER + 802 then
    FHookLog.Add('C');
end;

procedure TAudit8DTests.WatchA(Control: TControl; var Message: TMessage);
begin
  if Message.Msg = WM_USER + 803 then
    FHookLog.Add('wA');
end;

procedure TAudit8DTests.WatchB(Control: TControl; var Message: TMessage);
begin
  if Message.Msg <> WM_USER + 803 then
    Exit;
  FHookLog.Add('wB');
  PPGUnwatchControl(Control, WatchA);
end;

procedure TAudit8DTests.AppHooksChangesDuringDispatch;
var
  N, I: Integer;
  Ctl: TPPGTagEdit;
begin
  N := PPGMessageHookCount;
  PPGAddMessageHook(HookA);
  PPGAddMessageHook(HookB); // zuletzt angemeldet = zuerst gerufen
  try
    PostMessage(FForm.Handle, WM_USER + 802, 0, 0);
    for I := 0 to 5 do
      Application.ProcessMessages;
    // Die Runde laeuft mit dem Stand zu ihrem Beginn: A noch, C noch nicht
    CheckEquals('B,A', FHookLog.CommaText, 'erste Runde');
    CheckEquals(N + 2, PPGMessageHookCount, 'A ab, C an');
    FHookLog.Clear;
    PostMessage(FForm.Handle, WM_USER + 802, 0, 0);
    for I := 0 to 5 do
      Application.ProcessMessages;
    CheckEquals('C,B', FHookLog.CommaText, 'zweite Runde');
  finally
    PPGRemoveMessageHook(HookA);
    PPGRemoveMessageHook(HookB);
    PPGRemoveMessageHook(HookC);
  end;
  CheckEquals(N, PPGMessageHookCount, 'alle ab');
  // Beobachter: Abmelden waehrend der Meldung
  FHookLog.Clear;
  Ctl := TPPGTagEdit.Create(FForm);
  Ctl.Parent := FForm;
  PPGWatchControl(Ctl, WatchA);
  PPGWatchControl(Ctl, WatchB);
  Ctl.Perform(WM_USER + 803, 0, 0);
  CheckEquals('wB,wA', FHookLog.CommaText, 'Beobachter erste Runde');
  CheckEquals(1, PPGControlWatchCount(Ctl), 'A abgemeldet');
  FHookLog.Clear;
  Ctl.Perform(WM_USER + 803, 0, 0);
  CheckEquals('wB', FHookLog.CommaText, 'Beobachter zweite Runde');
  PPGUnwatchControl(Ctl, WatchB);
  CheckEquals(0, PPGControlWatchCount(Ctl), 'alle Beobachter ab');
  Ctl.Free;
end;

{ TAudit8DCountTests }

type
  TMenuBarAccess = class(TPPGMenuBar);

procedure TAudit8DCountTests.MenuBarMeasuresOncePerChange;
var
  Bar: TPPGMenuBar;
  M: TMainMenu;
  It: TMenuItem;
  I, N: Integer;
begin
  FForm.Width := 900;
  M := TMainMenu.Create(FForm);
  for I := 0 to 9 do
  begin
    It := TMenuItem.Create(M);
    It.Caption := 'Menue ' + IntToStr(I);
    M.Items.Add(It);
  end;
  Bar := TPPGMenuBar.Create(FForm);
  Bar.Parent := FForm;
  Bar.Menu := M;
  Bar.HandleNeeded;
  Bar.ItemAtPos(0, 0);
  N := TMenuBarAccess(Bar).FItemLayoutCount;
  for I := 0 to 49 do
    Bar.Perform(WM_MOUSEMOVE, 0, MouseLParam(I * 15, Bar.Height div 2));
  CheckEquals(N, TMenuBarAccess(Bar).FItemLayoutCount, 'Mausbewegungen messen nicht neu');
  M.Items[3].Caption := 'Anders';
  Bar.ItemAtPos(0, 0);
  CheckEquals(N + 1, TMenuBarAccess(Bar).FItemLayoutCount, 'Textaenderung misst einmal neu');
  Bar.Perform(WM_MOUSEMOVE, 0, MouseLParam(300, 5));
  CheckEquals(N + 1, TMenuBarAccess(Bar).FItemLayoutCount, 'danach wieder aus dem Speicher');
end;

function TAudit8DCountTests.UpdateRectOf(C: TWinControl): TRect;
begin
  if not GetUpdateRect(C.Handle, Result, False) then
    Result := Rect(0, 0, 0, 0);
end;

function TAudit8DCountTests.UpdatePending(C: TWinControl; X, Y: Integer): Boolean;
var
  Rgn: HRGN;
begin
  Rgn := CreateRectRgn(0, 0, 0, 0);
  try
    Result := (GetUpdateRgn(C.Handle, Rgn, False) > NULLREGION) and PtInRegion(Rgn, X, Y);
  finally
    DeleteObject(Rgn);
  end;
end;

procedure TAudit8DCountTests.MenuBarHoverRepaintsItemsOnly;
var
  Bar: TPPGMenuBar;
  M: TMainMenu;
  It: TMenuItem;
  I: Integer;
  R, U, E: TRect;
begin
  FForm.Width := 900;
  FForm.Show;
  try
    M := TMainMenu.Create(FForm);
    for I := 0 to 5 do
    begin
      It := TMenuItem.Create(M);
      It.Caption := 'Menue ' + IntToStr(I);
      It.Add(TMenuItem.Create(M));
      M.Items.Add(It);
    end;
    Bar := TPPGMenuBar.Create(FForm);
    Bar.Parent := FForm;
    Bar.Menu := M;
    // Erste Bewegung: die Basis zeichnet beim Eintritt der Maus alles neu
    R := Bar.ItemRect(0);
    Bar.Perform(WM_MOUSEMOVE, 0, MouseLParam(R.Left + 2, (R.Top + R.Bottom) div 2));
    Bar.Update;
    ValidateRect(Bar.Handle, nil);
    R := Bar.ItemRect(2);
    Bar.Perform(WM_MOUSEMOVE, 0, MouseLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
    CheckEquals(2, Bar.Hot);
    U := UpdateRectOf(Bar);
    CheckFalse(IsRectEmpty(U), 'Eintrag wird neu gezeichnet');
    IntersectRect(E, U, Bar.ItemRect(4));
    CheckTrue(IsRectEmpty(E), 'andere Eintraege bleiben');
  finally
    FForm.Hide;
  end;
end;

type
  TChartAccess = class(TPPGChart);

procedure TAudit8DCountTests.ChartHoverComputesNoLayout;
var
  C: TPPGChart;
  B: TBitmap;
  I, N: Integer;
begin
  C := TPPGChart.Create(FForm);
  C.Parent := FForm;
  C.Animation.Enabled := False;
  C.SetBounds(0, 0, 600, 320);
  C.Series.Add.SetValues([3, 5, 2, 8, 6, 4, 7]);
  // Erste Bewegung: die Basis zeichnet beim Eintritt der Maus alles neu
  C.Perform(WM_MOUSEMOVE, 0, MouseLParam(30, 50));
  B := RenderToBitmap(C);
  B.Free;
  N := TChartAccess(C).FLayoutCount;
  for I := 0 to 29 do
    C.Perform(WM_MOUSEMOVE, 0, MouseLParam(40 + I * 15, 60 + I * 5));
  CheckEquals(N, TChartAccess(C).FLayoutCount, 'Mausbewegungen nutzen das Layout des Bildes');
  C.Series[0].Add(9);
  C.HitTest(100, 100);
  C.HitTest(120, 100);
  CheckEquals(N + 1, TChartAccess(C).FLayoutCount, 'Datenaenderung: einmal neu');
  C.Width := C.Width - 10;
  C.HitTest(100, 100);
  CheckEquals(N + 2, TChartAccess(C).FLayoutCount, 'Groessenaenderung: einmal neu');
end;

procedure TAudit8DCountTests.ChartTooltipMoveRepaintsTooltipOnly;
var
  C: TPPGChart;
  U, P: TRect;
  H: TPPGChartHit;
  X, Y: Integer;
begin
  FForm.SetBounds(0, 0, 700, 400);
  FForm.Show;
  try
    C := TPPGChart.Create(FForm);
    C.Parent := FForm;
    C.Animation.Enabled := False;
    C.SetBounds(0, 0, 600, 320);
    C.Series.Add.SetValues([3, 5, 2, 8, 6, 4, 7]);
    P := C.Layout.PlotR;
    // Mitte der dritten Kategorie
    X := P.Left + (P.Right - P.Left) * 5 div 14;
    Y := (P.Top + P.Bottom) div 2;
    C.Perform(WM_MOUSEMOVE, 0, MouseLParam(X, Y));
    H := C.Hot;
    CheckEquals(Ord(chkPlot), Ord(H.Kind));
    C.Update; // zeichnet den Tooltip
    ValidateRect(C.Handle, nil);
    C.Perform(WM_MOUSEMOVE, 0, MouseLParam(X + 2, Y + 3));
    CheckEquals(H.Index, C.Hot.Index, 'gleicher Treffer');
    U := UpdateRectOf(C);
    CheckFalse(IsRectEmpty(U), 'Tooltip neu');
    CheckTrue((U.Right - U.Left) * (U.Bottom - U.Top) < C.Width * C.Height div 2,
      'nur der Tooltip, nicht das ganze Diagramm');
  finally
    FForm.Hide;
  end;
end;

procedure TAudit8DCountTests.ChartAddXYTakesNoSnapshot;
var
  C: TPPGChart;
  S: TPPGChartSeries;
  I: Integer;
begin
  FForm.Show;
  try
    C := TPPGChart.Create(FForm);
    C.Parent := FForm;
    C.SetBounds(0, 0, 600, 320);
    C.Animation.Enabled := True;
    if not C.Animation.EffectiveEnabled then
    begin
      Status('Systemanimationen aus');
      Exit;
    end;
    S := C.Series.Add;
    S.SetValues([1, 2, 3]);
    C.HandleNeeded;
    for I := 0 to 99 do
      S.AddXY(I + 3, I);
    CheckEquals(0, Length(S.OldY), 'keine Kopie der alten Werte');
    CheckEquals(1, C.ChangeProgress, 1E-6, 'kein Uebergang bei neuer Anzahl');
    // Gleiche Anzahl: weiterhin weicher Uebergang
    S.Y[0] := 50;
    CheckTrue(C.ChangeProgress < 1, 'Uebergang bei gleicher Anzahl');
    // In einer Klammer gleicht sich die Anzahl aus: Uebergang wie bisher
    C.Animation.Enabled := False;
    C.Animation.Enabled := True;
    C.BeginDataUpdate;
    try
      S.AddXY(500, 1);
      S.Delete(S.Count - 1);
    finally
      C.EndDataUpdate;
    end;
    CheckTrue(C.ChangeProgress < 1, 'Uebergang nach ausgeglichener Klammer');
  finally
    FForm.Hide;
  end;
end;

procedure TAudit8DCountTests.ChartAddRangeEqualsAddXY;
var
  C: TPPGChart;
  A, B: TPPGChartSeries;
  I: Integer;
  Raised: Boolean;
begin
  C := TPPGChart.Create(FForm);
  C.Parent := FForm;
  A := C.Series.Add;
  B := C.Series.Add;
  A.AddRange([1.5, 2.5, -3]);
  for I := 0 to 2 do
    B.Add(A.YAt(I));
  CheckEquals(3, A.Count);
  for I := 0 to 2 do
  begin
    CheckEquals(B.XAt(I), A.XAt(I), 1E-12, 'X ' + IntToStr(I));
    CheckEquals(B.YAt(I), A.YAt(I), 1E-12, 'Y ' + IntToStr(I));
  end;
  A.AddRange([10, 20], [7, 8]);
  CheckEquals(5, A.Count);
  CheckEquals(20, A.XAt(4), 1E-12);
  CheckEquals(8, A.YAt(4), 1E-12);
  Raised := False;
  try
    A.AddRange([1, 2], [3]);
  except
    on EPPGPropertyError do
      Raised := True;
  end;
  CheckTrue(Raised, 'ungleiche Laengen');
  CheckEquals(5, A.Count, 'unveraendert');
  Raised := False;
  try
    A.AddRange([1, NaN]);
  except
    on EPPGPropertyError do
      Raised := True;
  end;
  CheckTrue(Raised, 'NaN');
  CheckEquals(5, A.Count, 'unveraendert nach NaN');
end;

procedure TAudit8DCountTests.ChartPiePointPosUsesSums;
var
  C: TPPGChart;
  S: TPPGChartSeries;
  L: TPPGChartLayout;
  I, K: Integer;
  Total, Start, A: Double;
  P, E: TPoint;
begin
  C := TPPGChart.Create(FForm);
  C.Parent := FForm;
  C.Animation.Enabled := False;
  C.SetBounds(0, 0, 500, 400);
  S := C.Series.Add;
  S.Kind := cskDonut;
  for I := 0 to 199 do
    S.Add(1 + (I * 7) mod 13);
  L := C.Layout;
  Total := 0;
  for I := 0 to S.Count - 1 do
    Total := Total + Abs(S.YAt(I));
  Start := 0;
  for I := 0 to S.Count - 1 do
  begin
    // Formel wie gezeichnet
    A := (360 * (Start + Abs(S.YAt(I)) / 2) / Total - 90) * Pi / 180;
    K := (L.PieRadius + L.PieInner) div 2;
    E := Point(L.PieCenter.X + Round(K * Cos(A)), L.PieCenter.Y + Round(K * Sin(A)));
    CheckTrue(C.PointPos(0, I, P), 'Punkt ' + IntToStr(I));
    CheckEquals(E.X, P.X, 'X ' + IntToStr(I));
    CheckEquals(E.Y, P.Y, 'Y ' + IntToStr(I));
    Start := Start + Abs(S.YAt(I));
  end;
  // Nach einer Aenderung gelten die neuen Werte
  S.Y[0] := 100;
  CheckTrue(C.PointPos(0, 1, P));
  A := (360 * (100 + Abs(S.YAt(1)) / 2) / (Total - 1 + 100) - 90) * Pi / 180;
  K := (C.Layout.PieRadius + C.Layout.PieInner) div 2;
  CheckEquals(C.Layout.PieCenter.X + Round(K * Cos(A)), P.X, 'nach Aenderung');
end;

procedure TAudit8DCountTests.PlannerHoverRepaintsItemOnly;
var
  P: TPPGPlanner;
  A: TPPGAppointment;
  R, U: TRect;
begin
  FForm.SetBounds(0, 0, 1000, 700);
  FForm.Show;
  try
    P := TPPGPlanner.Create(FForm);
    P.Parent := FForm;
    P.SetBounds(0, 0, 900, 600);
    P.ShowNowLine := False;
    P.View := pvWeek;
    P.Date := EncodeDate(2025, 3, 5);
    A := P.Appointments.AddAppointment(EncodeDate(2025, 3, 5) + 9 / 24, EncodeDate(2025, 3, 5) + 11 / 24,
      'Termin');
    CheckTrue(A <> nil);
    P.ScrollTo(0, 0);
    P.EnsureLayout;
    P.Update;
    R := P.ItemRect(0);
    CheckFalse(IsRectEmpty(R), 'Termin sichtbar');
    // Erste Bewegung: die Basis zeichnet beim Eintritt der Maus alles neu
    P.Perform(WM_MOUSEMOVE, 0, MouseLParam(P.Width - 30, P.Height - 30));
    P.Update;
    ValidateRect(P.Handle, nil);
    P.Perform(WM_MOUSEMOVE, 0, MouseLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
    U := UpdateRectOf(P);
    CheckFalse(IsRectEmpty(U), 'Termin neu gezeichnet');
    CheckTrue(UpdatePending(P, (R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2), 'Termin neu');
    CheckFalse(UpdatePending(P, P.Width div 6, (R.Top + R.Bottom) div 2), 'anderer Tag bleibt');
    CheckFalse(UpdatePending(P, (R.Left + R.Right) div 2, R.Bottom + 60), 'spaetere Zeit bleibt');
  finally
    FForm.Hide;
  end;
end;

procedure TAudit8DCountTests.PlannerDragRepaintsOnlyOnGhostChange;
var
  P: TPPGPlanner;
  R, U: TRect;
  X, Y: Integer;
begin
  FForm.SetBounds(0, 0, 1000, 700);
  FForm.Show;
  try
    P := TPPGPlanner.Create(FForm);
    P.Parent := FForm;
    P.SetBounds(0, 0, 900, 600);
    P.ShowNowLine := False;
    P.View := pvWeek;
    P.Date := EncodeDate(2025, 3, 5);
    P.Appointments.AddAppointment(EncodeDate(2025, 3, 5) + 9 / 24, EncodeDate(2025, 3, 5) + 11 / 24, 'Termin');
    P.ScrollTo(0, 0);
    P.EnsureLayout;
    R := P.ItemRect(0);
    X := (R.Left + R.Right) div 2;
    Y := R.Top + 20;
    P.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(X, Y));
    P.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(X, Y + 40));
    P.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(X, Y + 41));
    P.Update;
    ValidateRect(P.Handle, nil);
    // Gleiche Stelle: der Schatten bleibt, kein Neuzeichnen
    P.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(X, Y + 41));
    U := UpdateRectOf(P);
    CheckTrue(IsRectEmpty(U), 'kein Neuzeichnen ohne Aenderung');
    // Deutlich weiter: neu
    P.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(X, Y + 120));
    U := UpdateRectOf(P);
    CheckFalse(IsRectEmpty(U), 'Neuzeichnen bei neuem Schatten');
    P.Perform(WM_LBUTTONUP, 0, MouseLParam(X, Y + 120));
  finally
    FForm.Hide;
  end;
end;

type
  TKanbanAccess8D = class(TPPGKanban);
  TRibbonAccess8D = class(TPPGRibbon);
  TPageControlAccess8D = class(TPPGPageControl);

procedure TAudit8DCountTests.KanbanChangeMeasuresOneCard;
var
  K: TPPGKanban;
  B: TBitmap;
  I, N: Integer;
  Col: array[0..2] of TPPGKanbanColumn;
begin
  K := TPPGKanban.Create(FForm);
  K.Parent := FForm;
  K.SetBounds(0, 0, 900, 600);
  for I := 0 to 2 do
    Col[I] := K.Columns.AddColumn('Spalte ' + IntToStr(I));
  for I := 0 to 59 do
    K.Cards.AddCard(Col[I mod 3].Id, 'Aufgabe ' + IntToStr(I), 'Text');
  B := RenderToBitmap(K);
  B.Free;
  N := TKanbanAccess8D(K).FMeasureCount;
  CheckEquals(60, N, 'jede Karte einmal');
  K.Cards[7].Title := 'Ein anderer Titel';
  K.EnsureLayout;
  CheckEquals(N + 1, TKanbanAccess8D(K).FMeasureCount, 'nur die geaenderte Karte');
  K.FilterText := '1';
  K.EnsureLayout;
  K.FilterText := '';
  K.EnsureLayout;
  CheckEquals(N + 1, TKanbanAccess8D(K).FMeasureCount, 'Filter misst nicht neu');
  K.Cards[3].Index := 40;
  K.EnsureLayout;
  CheckEquals(N + 1, TKanbanAccess8D(K).FMeasureCount, 'Umsortieren misst nicht neu');
  K.ColumnWidth := K.ColumnWidth + 20;
  K.EnsureLayout;
  CheckEquals(N + 61, TKanbanAccess8D(K).FMeasureCount, 'neue Breite: alle neu');
  K.Font.Size := K.Font.Size + 1;
  K.EnsureLayout;
  CheckEquals(N + 121, TKanbanAccess8D(K).FMeasureCount, 'neue Schrift: alle neu');
end;

procedure TAudit8DCountTests.KanbanHoverRepaintsCardOnly;
var
  K: TPPGKanban;
  I: Integer;
  R, U: TRect;
  Col: TPPGKanbanColumn;
begin
  FForm.SetBounds(0, 0, 1000, 700);
  FForm.Show;
  try
    K := TPPGKanban.Create(FForm);
    K.Parent := FForm;
    K.SetBounds(0, 0, 900, 600);
    Col := K.Columns.AddColumn('Offen');
    K.Columns.AddColumn('Fertig');
    for I := 0 to 5 do
      K.Cards.AddCard(Col.Id, 'Aufgabe ' + IntToStr(I), '');
    // Erste Bewegung: die Basis zeichnet beim Eintritt der Maus alles neu
    K.Perform(WM_MOUSEMOVE, 0, MouseLParam(K.Width - 20, K.Height - 20));
    K.Update;
    ValidateRect(K.Handle, nil);
    R := K.CardRect(0, 0, 2);
    K.Perform(WM_MOUSEMOVE, 0, MouseLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
    U := UpdateRectOf(K);
    CheckFalse(IsRectEmpty(U), 'Karte neu');
    CheckTrue(UpdatePending(K, (R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2), 'Karte neu');
    R := K.CardRect(0, 0, 5);
    CheckFalse(UpdatePending(K, (R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2), 'andere Karte bleibt');
    R := K.ColumnRect(1);
    CheckFalse(UpdatePending(K, (R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2), 'andere Spalte bleibt');
  finally
    FForm.Hide;
  end;
end;

procedure TAudit8DCountTests.RibbonEnabledKeepsLayout;
var
  R: TPPGRibbon;
  G: TPPGRibbonGroup;
  It: TPPGRibbonItem;
  B: TBitmap;
  I, N: Integer;
begin
  R := TPPGRibbon.Create(FForm);
  R.Parent := FForm;
  R.Width := 900;
  G := R.Tabs.AddTab('Start').Groups.AddGroup('Gruppe');
  It := G.Items.AddButton('Befehl', $E77F, rsLarge);
  G.Items.AddCheck('Fett', $E8DD, rsSmall);
  B := RenderToBitmap(R);
  B.Free;
  N := TRibbonAccess8D(R).FLayoutCount;
  for I := 0 to 19 do
  begin
    It.Enabled := Odd(I);
    G.Items[1].Down := not Odd(I);
    B := RenderToBitmap(R);
    B.Free;
  end;
  CheckEquals(N, TRibbonAccess8D(R).FLayoutCount, 'Enabled/Down ohne neues Layout');
  It.Caption := 'Anderer Befehl';
  B := RenderToBitmap(R);
  B.Free;
  CheckEquals(N + 1, TRibbonAccess8D(R).FLayoutCount, 'Text: neues Layout');
end;

procedure TAudit8DCountTests.PageControlBracketBuildsOnce;
var
  PC: TPPGPageControl;
  S: TPPGTabSheet;
  I, N: Integer;
begin
  PC := TPPGPageControl.Create(FForm);
  PC.Parent := FForm;
  PC.SetBounds(0, 0, 380, 200);
  N := TPageControlAccess8D(PC).FTabsBuildCount;
  PC.BeginUpdate;
  try
    for I := 0 to 49 do
    begin
      S := TPPGTabSheet.Create(PC);
      S.Caption := 'Seite ' + IntToStr(I);
      S.PageControl := PC;
    end;
    PC.Pages[5].PageIndex := 40;
    PC.ActivePageIndex := 45;
    CheckEquals(N, TPageControlAccess8D(PC).FTabsBuildCount, 'kein Neuaufbau in der Klammer');
    CheckEquals('Seite 45', PC.ActivePage.Caption, 'ActivePage sofort');
  finally
    PC.EndUpdate;
  end;
  CheckEquals(N + 1, TPageControlAccess8D(PC).FTabsBuildCount, 'ein Neuaufbau');
  CheckEquals(PC.ActivePageIndex, PC.Strip.Tab(PC.Strip.Selected).Index, 'Leiste waehlt die Seite');
  CheckFalse(IsRectEmpty(PC.TabRect(PC.ActivePageIndex)), 'aktiver Reiter sichtbar');
end;

procedure TAudit8DCountTests.TabStripHoverRepaintsTabOnly;
var
  T: TPPGTabControl;
  I: Integer;
  R, U: TRect;
begin
  FForm.SetBounds(0, 0, 900, 400);
  FForm.Show;
  try
    T := TPPGTabControl.Create(FForm);
    T.Parent := FForm;
    T.SetBounds(0, 0, 800, 200);
    for I := 0 to 5 do
      T.Tabs.Add('Reiter ' + IntToStr(I));
    T.Perform(WM_MOUSEMOVE, 0, MouseLParam(T.Width - 10, T.Height - 10));
    T.Update;
    ValidateRect(T.Handle, nil);
    R := T.TabRect(3);
    T.Perform(WM_MOUSEMOVE, 0, MouseLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
    U := UpdateRectOf(T);
    CheckFalse(IsRectEmpty(U), 'Reiter neu');
    CheckTrue(U.Right - U.Left < T.Width div 3, 'nur der Reiter');
  finally
    FForm.Hide;
  end;
end;

{ TAudit8DDBTests }

procedure TAudit8DDBTests.SetUp;
begin
  inherited SetUp;
  FForm.SetBounds(0, 0, 1100, 700);
  FData := TClientDataSet.Create(FForm);
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Status', ftString, 20);
  FData.FieldDefs.Add('Reihe', ftInteger);
  FData.FieldDefs.Add('Titel', ftString, 80);
  FData.CreateDataSet;
  FData.IndexFieldNames := 'Reihe';
  FData.AfterPost := CountPost;
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
end;

procedure TAudit8DDBTests.CountPost(DataSet: TDataSet);
begin
  Inc(FPosts);
end;

procedure TAudit8DDBTests.AddRow(AId: Integer; const AStatus: string; AOrder: Integer;
  const ATitle: string);
begin
  FData.Append;
  FData.FieldByName('ID').AsInteger := AId;
  FData.FieldByName('Status').AsString := AStatus;
  FData.FieldByName('Reihe').AsInteger := AOrder;
  FData.FieldByName('Titel').AsString := ATitle;
  FData.Post;
end;

function TAudit8DDBTests.OrderOf(AId: Integer): Integer;
begin
  CheckTrue(FData.Locate('ID', AId, []));
  Result := FData.FieldByName('Reihe').AsInteger;
end;

procedure TAudit8DDBTests.SortedDataSetRenumbersInOrder;
var
  K: TPPGDBKanban;
  I: Integer;
  S: string;
begin
  // Datenmenge nach dem Sortierfeld indiziert: Post verschiebt den Satz
  for I := 1 to 8 do
    AddRow(I, 'todo', I * 10, Chr(Ord('A') + I - 1));
  AddRow(9, 'doing', 10, 'X');
  AddRow(10, 'doing', 20, 'Y');
  K := TPPGDBKanban.Create(FForm);
  K.Parent := FForm;
  K.SetBounds(0, 0, 1080, 640);
  K.Animation.Enabled := False;
  K.ReloadDelay := 0;
  K.Columns.AddColumn('Offen').Key := 'todo';
  K.Columns.AddColumn('In Arbeit').Key := 'doing';
  K.KeyField := 'ID';
  K.ColumnField := 'Status';
  K.OrderField := 'Reihe';
  K.TitleField := 'Titel';
  K.DataSource := FSource;
  K.HandleNeeded;
  FPosts := 0;
  // Letzte Karte nach vorn: alle Saetze der Spalte bekommen neue Nummern
  CheckTrue(K.MoveCard(0, 0, 7, 0, 0, 0));
  S := '';
  for I := 0 to K.CardCount(0, 0) - 1 do
    S := S + K.CardData(0, 0, I).Title;
  CheckEquals('HABCDEFG', S, 'Anzeige');
  CheckEquals(10, OrderOf(8));
  for I := 1 to 7 do
    CheckEquals((I + 1) * 10, OrderOf(I), 'Reihe ' + IntToStr(I));
  CheckEquals(9, FPosts, 'jede Karte einmal geschrieben, die gezogene zweimal');
  // Karte in die andere Spalte: beide Zellen neu nummeriert, nur Abweichungen
  FPosts := 0;
  CheckTrue(K.MoveCard(0, 0, 0, 1, 0, 1));
  CheckEquals(10, OrderOf(9));
  CheckEquals(20, OrderOf(8));
  CheckEquals(30, OrderOf(10));
  for I := 1 to 7 do
    CheckEquals(I * 10, OrderOf(I), 'Reihe nach Wechsel ' + IntToStr(I));
  // Ziel: 8 (Spalte+Reihe) + 10 (neu 30); Quelle: alle 7 rutschen auf
  CheckEquals(10, FPosts, 'nur Abweichungen geschrieben');
  K.Free;
end;

{ TAudit8EBoardTests }

procedure TAudit8EBoardTests.SetUp;
begin
  inherited;
  FForm.SetBounds(0, 0, 960, 680);
  FForm.Show;
end;

procedure TAudit8EBoardTests.CountCard(Sender: TObject; Canvas: TCanvas;
  const Card: TPPGKanbanCardData; const ARect: TRect; State: TPPGItemDrawState;
  var Style: TPPGDrawStyle; var DefaultDraw: Boolean);
begin
  Inc(FDrawn);
end;

procedure TAudit8EBoardTests.CountAppointment(Sender: TObject; Canvas: TCanvas;
  Appointment: TPPGAppointment; const ARect: TRect; State: TPPGItemDrawState;
  var Style: TPPGDrawStyle; var DefaultDraw: Boolean);
begin
  Inc(FDrawn);
end;

function TAudit8EBoardTests.NewBoard(Cards: Integer; Lanes: Boolean): TPPGKanban;
var
  I: Integer;
  Col: array[0..2] of TPPGKanbanColumn;
  Card: TPPGKanbanCard;
begin
  Result := TPPGKanban.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 900, 600);
  Result.Animation.Enabled := False;
  for I := 0 to 2 do
    Col[I] := Result.Columns.AddColumn('Spalte ' + IntToStr(I));
  Col[1].WipLimit := 3;
  if Lanes then
  begin
    Result.Lanes.AddLane('Anna');
    Result.Lanes.AddLane('Ben');
  end;
  Result.Cards.BeginUpdate;
  try
    for I := 0 to Cards - 1 do
    begin
      Card := Result.Cards.AddCard(Col[I mod 3].Id, 'Aufgabe ' + IntToStr(I),
        'Text <b>' + IntToStr(I) + '</b>');
      if I mod 2 = 0 then
        Card.Labels := 'Bug, UI';
      if I mod 3 = 0 then
        Card.Assignee := 'Anna Berg';
      if I mod 4 = 0 then
        Card.Progress := 40;
      if I mod 5 = 0 then
        Card.Color := clRed;
      if I mod 7 = 0 then
        Card.Due := EncodeDate(2030, 1, 1 + I mod 20);
      if Lanes then
        Card.LaneId := 1 + I mod 2;
    end;
  finally
    Result.Cards.EndUpdate;
  end;
  Result.HandleNeeded;
  Result.Update;
end;

procedure TAudit8EBoardTests.KanbanPartialRepaint;
var
  K: TPPGKanban;
  R: TRect;
begin
  K := NewBoard(40, False);
  K.Select(0, 0, 2);
  K.SetFocus;
  K.Update;
  // quer durch Karten zweier Spalten, halbe Karte, Luecke
  R := K.CardRect(0, 0, 2);
  CheckPartial(K, Rect(R.Left + 20, R.Top + 7, R.Right + 90, R.Bottom + 13), 'Karten');
  // Fokusrahmen am Rand der Karte
  CheckPartial(K, Rect(R.Left - 3, R.Top - 3, R.Left + 6, R.Bottom + 3), 'Fokusrand');
  // Kopf mit Anzahl/Limit und Einklappen
  CheckPartial(K, Rect(0, 0, 900, 40), 'Koepfe');
  // unten: Spaltenkoerper und Leisten
  CheckPartial(K, Rect(200, 480, 900, 600), 'unten');
  // gescrollte Spalte (erste Karte halb verdeckt)
  K.ScrollColumn(0, 37);
  K.Update;
  CheckPartial(K, Rect(0, 60, 300, 140), 'Spalte gescrollt');
end;

procedure TAudit8EBoardTests.KanbanPartialRepaintLanes;
var
  K: TPPGKanban;
  R: TRect;
begin
  K := NewBoard(30, True);
  K.Update;
  R := K.LaneHeaderRect(1);
  CheckPartial(K, Rect(0, R.Top - 10, 900, R.Bottom + 10), 'Swimlane-Kopf');
  R := K.CardRect(1, 1, 0);
  CheckPartial(K, Rect(R.Left - 5, R.Top - 5, R.Right + 5, R.Top + 30), 'Karte in Swimlane');
  K.ScrollTo(0, 60);
  K.Update;
  CheckPartial(K, Rect(0, 30, 900, 120), 'gescrollt');
end;

procedure TAudit8EBoardTests.KanbanHoverMatchesFullPaint;
var
  K: TPPGKanban;
  I: Integer;
  R: TRect;
begin
  K := NewBoard(30, False);
  K.Select(1, 0, 1);
  K.Update;
  for I := 0 to 5 do
  begin
    R := K.CardRect(I mod 3, 0, I div 3);
    K.Perform(WM_MOUSEMOVE, 0, MouseLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
    CheckWindowMatches(K, 'Karte ' + IntToStr(I));
  end;
  // Einklapp-Knopf und Spaltenkopf
  R := K.HeaderRect(2);
  K.Perform(WM_MOUSEMOVE, 0, MouseLParam(R.Right - 15, (R.Top + R.Bottom) div 2));
  CheckWindowMatches(K, 'Einklappen');
  K.Perform(CM_MOUSELEAVE, 0, 0);
  CheckWindowMatches(K, 'Maus raus');
end;

procedure TAudit8EBoardTests.KanbanPartialPaintDrawsOnlyCardsInClip;
var
  K: TPPGKanban;
  R: TRect;
  Full: Integer;
begin
  K := NewBoard(60, False);
  K.OnCustomDrawCard := CountCard;
  FDrawn := 0;
  K.Invalidate;
  K.Update;
  Full := FDrawn;
  CheckTrue(Full >= 9, Format('Voll-Paint: alle sichtbaren Karten (%d)', [Full]));
  R := K.CardRect(1, 0, 2);
  FDrawn := 0;
  InvalidateRect(K.Handle, @R, False);
  K.Update;
  CheckEquals(1, FDrawn, Format('nur die Karte im Bereich (Voll-Paint %d)', [Full]));
  // Spalte ausserhalb: keine Karte
  R := Rect(0, 0, 4, 4);
  FDrawn := 0;
  InvalidateRect(K.Handle, @R, False);
  K.Update;
  CheckEquals(0, FDrawn, 'Ecke ohne Karte');
end;

function TAudit8EBoardTests.NewPlanner(AView: TPPGPlannerView): TPPGPlanner;
var
  I: Integer;
  A: TPPGAppointment;
  D: TDateTime;
begin
  Result := TPPGPlanner.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 900, 600);
  Result.ShowNowLine := False;
  Result.Animation.Enabled := False;
  Result.Resources.AddResource(1, 'Anna');
  Result.Resources.AddResource(2, 'Ben');
  Result.Resources.AddResource(3, 'Cleo');
  D := EncodeDate(2025, 3, 3);
  Result.Appointments.BeginUpdate;
  try
    for I := 0 to 89 do
    begin
      A := Result.Appointments.AddAppointment(D + (I mod 9) + (7 + (I * 5) mod 11) / 24 + (I mod 4) / 96,
        D + (I mod 9) + (8 + (I * 5) mod 11) / 24 + (I mod 3) / 48, 'Termin ' + IntToStr(I));
      A.ResourceId := 1 + I mod 3;
      if I mod 4 = 0 then
        A.Location := 'Raum ' + IntToStr(I);
      if I mod 17 = 0 then
        A.AllDay := True;
      if I mod 23 = 0 then
        A.FinishTime := A.StartTime + 2.5;
    end;
  finally
    Result.Appointments.EndUpdate;
  end;
  Result.View := AView;
  if AView = pvTimeline then
    Result.TimelineDays := 14;
  Result.Date := D + 2;
  Result.HandleNeeded;
  Result.EnsureLayout;
  Result.Update;
end;

procedure TAudit8EBoardTests.PlannerPartialRepaintViews;
const
  Views: array[0..5] of TPPGPlannerView = (pvDay, pvWorkWeek, pvWeek, pvMonth, pvTimeline, pvAgenda);
var
  P: TPPGPlanner;
  V: Integer;
  R: TRect;
  Ctx: string;
begin
  for V := 0 to High(Views) do
  begin
    P := NewPlanner(Views[V]);
    try
      Ctx := 'Ansicht ' + IntToStr(V);
      if Views[V] = pvWeek then
        P.GroupByResource := True;
      if Views[V] = pvTimeline then
        P.ScrollTo(130, 0);
      if Views[V] in [pvDay, pvWorkWeek, pvWeek] then
        P.ScrollTo(0, 7 * 40);
      P.SelectAppointment(P.Appointments[4]);
      P.SetFocus;
      P.Update;
      // Termin (mit Rand), Band quer, Kopf, linker Rand, Ausschnitt unten
      R := P.ItemRect(0);
      if not IsRectEmpty(R) then
        CheckPartial(P, Rect(R.Left - 3, R.Top - 3, R.Right - 10, R.Top + 12), Ctx + ' Termin');
      CheckPartial(P, Rect(0, 150, 900, 175), Ctx + ' Band');
      CheckPartial(P, Rect(0, 0, 900, 45), Ctx + ' Kopf');
      CheckPartial(P, Rect(0, 60, 90, 400), Ctx + ' links');
      CheckPartial(P, Rect(310, 230, 620, 420), Ctx + ' Mitte');
      CheckPartial(P, Rect(500, 500, 900, 600), Ctx + ' unten');
    finally
      P.Free;
    end;
  end;
end;

procedure TAudit8EBoardTests.PlannerHoverMatchesFullPaint;
var
  P: TPPGPlanner;
  I: Integer;
  R: TRect;
begin
  P := NewPlanner(pvWeek);
  P.SelectAppointment(P.Appointments[2]);
  P.Update;
  for I := 0 to 7 do
  begin
    R := P.ItemRect(I * 3);
    if IsRectEmpty(R) then
      Continue;
    P.Perform(WM_MOUSEMOVE, 0, MouseLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
    CheckWindowMatches(P, 'Termin ' + IntToStr(I));
  end;
  P.Perform(CM_MOUSELEAVE, 0, 0);
  CheckWindowMatches(P, 'Maus raus');
end;

procedure TAudit8EBoardTests.PlannerPartialPaintDrawsOnlyItemsInClip;
var
  P: TPPGPlanner;
  R: TRect;
  Full: Integer;
begin
  P := NewPlanner(pvWeek);
  P.OnCustomDrawAppointment := CountAppointment;
  FDrawn := 0;
  P.Invalidate;
  P.Update;
  Full := FDrawn;
  CheckTrue(Full >= 10, Format('Voll-Paint: alle sichtbaren Termine (%d)', [Full]));
  R := P.ItemRect(0);
  CheckFalse(IsRectEmpty(R), 'Termin sichtbar');
  R.Right := R.Left + 4;
  R.Bottom := R.Top + 4;
  FDrawn := 0;
  InvalidateRect(P.Handle, @R, False);
  P.Update;
  CheckTrue((FDrawn >= 1) and (FDrawn <= 3), Format('nur Termine im Bereich: %d von %d', [FDrawn, Full]));
end;

initialization
  RegisterTest('Audit8D', TAudit8DTests.Suite);
  RegisterTest('Audit8D', TAudit8DCountTests.Suite);
  RegisterTest('Audit8D', TAudit8DDBTests.Suite);
  RegisterTest('Audit8E', TAudit8EBoardTests.Suite);

end.
