unit PPG.Tests.Review;

{ Regressionstests zu den Funden der Ultra Review vom 07.10.2026
  (PRs 3 und 4: Core/Theme und Render). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.Types, System.Math, System.Variants,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics,
  PPG.ErrorHandler, PPG.Theme, PPG.StyleManager, PPG.Markup,
  PPG.Render.Intf, PPG.Render.Gdi,
  PPG.Chart.Scale, PPG.TimeZones, PPG.Planner.Recurrence, PPG.Planner.Model,
  PPG.Planner.ICal, PPG.UIA.Intf, PPG.UIA, PPG.ListBox, PPG.Tests.Phase9b;

type
  TReviewTests = class(TTestCase)
  private
    FLog: TStringList;
    FAppExceptions: Integer;
    procedure RecordAppException(Sender: TObject; E: Exception);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure ErrorLogNamesSenderAndMessageOnce;
    procedure ThemeChangeReachesClientsAfterFailingOne;
    procedure StyleManagerChangeReachesClientsAfterFailingOne;
    procedure MarkupLinkWithoutFragmentIsNotCounted;
    procedure MarkupLinkIndexesStayInReadingOrder;
    procedure GdiDashedLineBlendsOnceWithGaps;
    procedure FailingLoggerStaysInsideWarnings;
  end;

  // PR 5 (Fachlogik): Achsen, Planer, iCalendar, UIA
  TReviewPlannerTests = class(TTestCase)
  private
    FItems: TPPGAppointments;
    function Daily(Start: TDateTime; const Rule: string): TPPGAppointment;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure AxisScaleHandlesHugeValues;
    procedure AllDayExceptionExportsDateOnly;
    procedure DetachedOccurrenceNotExportedAsExDate;
    procedure UntilUtcAppliesInLocalMode;
    procedure ExceptionInSpringGapApplies;
    procedure AssignKeepsIdsAndParents;
    procedure YearlyByMonthDayCoversAllMonths;
    procedure ExpandWithoutCountMatchesFullCount;
  end;

  TReviewUiaTests = class(TUiaTestCase)
  published
    procedure RootWithoutFocusedChildLeavesFocusToHost;
  end;

implementation

type
  TListLogger = class(TInterfacedObject, IPPGLogger)
  private
    FList: TStrings;
  public
    constructor Create(AList: TStrings);
    procedure Log(Level: TPPGLogLevel; const Msg: string);
  end;

  TFailingLogger = class(TInterfacedObject, IPPGLogger)
  public
    procedure Log(Level: TPPGLogLevel; const Msg: string);
  end;

  // Meldet sich beim Theme an und zaehlt bzw. wirft beim Wechsel
  TThemeProbe = class(TControl)
  public
    Fail: Boolean;
    Calls: Integer;
    procedure WndProc(var Message: TMessage); override;
  end;

  TStyleProbe = class(TComponent, IPPGStyleClient)
  public
    Fail: Boolean;
    Calls: Integer;
    procedure StyleManagerChanged(Sender: TObject);
  end;

  TStyleManagerAccess = class(TPPGStyleManager);

constructor TListLogger.Create(AList: TStrings);
begin
  inherited Create;
  FList := AList;
end;

procedure TListLogger.Log(Level: TPPGLogLevel; const Msg: string);
begin
  FList.Add(Msg);
end;

procedure TFailingLogger.Log(Level: TPPGLogLevel; const Msg: string);
begin
  raise Exception.Create('Logger kaputt');
end;

procedure TThemeProbe.WndProc(var Message: TMessage);
begin
  if (PPGThemeChangedMessage <> 0) and (Message.Msg = PPGThemeChangedMessage) then
  begin
    Inc(Calls);
    if Fail then
      raise Exception.Create('Probe failed');
  end;
  inherited WndProc(Message);
end;

procedure TStyleProbe.StyleManagerChanged(Sender: TObject);
begin
  Inc(Calls);
  if Fail then
    raise Exception.Create('Probe failed');
end;

function CountOf(const Sub, S: string): Integer;
var
  P, Start: Integer;
begin
  Result := 0;
  Start := 1;
  repeat
    P := Pos(Sub, Copy(S, Start, MaxInt));
    if P > 0 then
    begin
      Inc(Result);
      Start := Start + P - 1 + Length(Sub);
    end;
  until P = 0;
end;

{ TReviewTests }

procedure TReviewTests.SetUp;
begin
  inherited;
  FLog := TStringList.Create;
  FAppExceptions := 0;
  Application.OnException := RecordAppException;
end;

procedure TReviewTests.TearDown;
begin
  TPPGErrorHandler.Logger := nil;
  Application.OnException := nil;
  FreeAndNil(FLog);
  inherited;
end;

procedure TReviewTests.RecordAppException(Sender: TObject; E: Exception);
begin
  Inc(FAppExceptions);
end;

procedure TReviewTests.ErrorLogNamesSenderAndMessageOnce;
var
  C: TComponent;
  E: Exception;
begin
  // Vorher: "Probe1: Painting of Probe1 failed: Boom (Exception: Boom)"
  TPPGErrorHandler.Logger := TListLogger.Create(FLog);
  C := TComponent.Create(nil);
  E := Exception.Create('Boom');
  try
    C.Name := 'Probe1';
    TPPGErrorHandler.ReportPaintError(C, E);
    TPPGErrorHandler.HandleCallbackError(C, E, 'Probe.Tick');
    CheckEquals(2, FLog.Count);
    CheckEquals(1, CountOf('Probe1', FLog[0]), 'Paint: Sender einmal - ' + FLog[0]);
    CheckEquals(1, CountOf('Boom', FLog[0]), 'Paint: Meldung einmal - ' + FLog[0]);
    CheckEquals(1, CountOf('Probe1', FLog[1]), 'Callback: Sender einmal - ' + FLog[1]);
    CheckEquals(1, CountOf('Boom', FLog[1]), 'Callback: Meldung einmal - ' + FLog[1]);
    CheckEquals(1, CountOf('Probe.Tick', FLog[1]), 'Callback: Kontext - ' + FLog[1]);
  finally
    E.Free;
    C.Free;
  end;
end;

procedure TReviewTests.FailingLoggerStaysInsideWarnings;
begin
  // Audit 08.10.2026: LogWarning/LogInfo werden in Fehlergrenzen (Paint, COM,
  // Drucken) gerufen; ein werfender Logger trug die Exception hinaus.
  TPPGErrorHandler.Logger := TFailingLogger.Create;
  TPPGErrorHandler.LogWarning(nil, 'Warnung');
  TPPGErrorHandler.LogInfo(nil, 'Info');
  CheckEquals(0, FAppExceptions, 'keine Anwendungs-Exception');
end;

procedure TReviewTests.ThemeChangeReachesClientsAfterFailingOne;
var
  Bad, Good: TThemeProbe;
  OldMode: TPPGThemeMode;
begin
  OldMode := TPPGTheme.Mode;
  Bad := TThemeProbe.Create(nil);
  Good := TThemeProbe.Create(nil);
  try
    Bad.Fail := True;
    TPPGTheme.AddClient(Bad);  // zuerst angemeldet, also zuerst benachrichtigt
    TPPGTheme.AddClient(Good);
    try
      if OldMode = tmDark then
        TPPGTheme.Mode := tmLight
      else
        TPPGTheme.Mode := tmDark;
      CheckEquals(1, Bad.Calls, 'fehlerhafter Client aufgerufen');
      CheckEquals(1, Good.Calls, 'folgender Client trotzdem benachrichtigt');
      CheckEquals(1, FAppExceptions, 'Fehler wie die VCL gemeldet');
    finally
      TPPGTheme.RemoveClient(Bad);
      TPPGTheme.RemoveClient(Good);
      TPPGTheme.Mode := OldMode;
    end;
  finally
    Good.Free;
    Bad.Free;
  end;
end;

procedure TReviewTests.StyleManagerChangeReachesClientsAfterFailingOne;
var
  M: TPPGStyleManager;
  Bad, Good: TStyleProbe;
begin
  M := TPPGStyleManager.Create(nil);
  Bad := TStyleProbe.Create(nil);
  Good := TStyleProbe.Create(nil);
  try
    Bad.Fail := True;
    M.AddClient(Bad);
    M.AddClient(Good);
    TStyleManagerAccess(M).Changed;
    CheckEquals(1, Bad.Calls, 'fehlerhafter Client aufgerufen');
    CheckEquals(1, Good.Calls, 'folgender Client trotzdem benachrichtigt');
    CheckEquals(1, FAppExceptions, 'Fehler wie die VCL gemeldet');
    M.RemoveClient(Bad);
    M.RemoveClient(Good);
  finally
    Good.Free;
    Bad.Free;
    M.Free;
  end;
end;

procedure TReviewTests.MarkupLinkWithoutFragmentIsNotCounted;
var
  L: TPPGMarkupLayout;
  F: TFont;
  R: TRect;
begin
  F := TFont.Create;
  L := TPPGMarkupLayout.Create;
  try
    // Bild ohne ImageList und reiner Umbruch erzeugen kein Fragment
    L.Layout('<a href="bild"><img=0></a>x<a href="umbruch"><br></a>y', F, nil, 0, False);
    CheckEquals(0, L.LinkCount, 'Links ohne Flaeche zaehlen nicht');
    CheckFalse(L.HasLinks);
    CheckEquals(-1, L.RunLinkIndex(0));
    R := L.LinkBounds(0);
    CheckTrue(IsRectEmpty(R), 'kein Link 0');
  finally
    L.Free;
    F.Free;
  end;
end;

procedure TReviewTests.MarkupLinkIndexesStayInReadingOrder;
var
  L: TPPGMarkupLayout;
  F: TFont;
  R: TRect;
  I: Integer;
begin
  F := TFont.Create;
  L := TPPGMarkupLayout.Create;
  try
    L.Layout('<a href="a">eins</a> <a href="bild"><img=0></a> <b><a href="c">zw</a></b>' +
      '<a href="c">ei</a> <a href="d">drei</a>', F, nil, 0, False);
    CheckEquals(3, L.LinkCount);
    CheckEquals('a', L.LinkTarget(0));
    CheckEquals('c', L.LinkTarget(1), 'unsichtbarer Link uebersprungen');
    CheckEquals('d', L.LinkTarget(2));
    CheckEquals('zwei', L.LinkText(1), 'zusammenhaengende Abschnitte = ein Link');
    for I := 0 to L.LinkCount - 1 do
    begin
      R := L.LinkBounds(I);
      CheckFalse(IsRectEmpty(R), Format('Link %d hat Flaeche', [I]));
      CheckEquals(I, L.LinkIndexAt((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2),
        Format('Link %d per Maus erreichbar', [I]));
    end;
  finally
    L.Free;
    F.Free;
  end;
end;

procedure TReviewTests.GdiDashedLineBlendsOnceWithGaps;
var
  Bmp: TBitmap;
  Cv: IPPGShapeCanvas;
  C: Cardinal;
  X, Dash, Gap: Integer;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf24bit;
    Bmp.SetSize(120, 20);
    Bmp.Canvas.Brush.Color := clWhite;
    Bmp.Canvas.FillRect(Rect(0, 0, 120, 20));
    Cv := TPPGGdiCanvas.Create(Bmp.Canvas.Handle);
    // Strich laeuft ueber die Ecke bei (56,10): beide Teilstuecke haben runde
    // Enden und ueberlappen dort. Vorher (eine Ebene je Strich) doppelt geblendet.
    Cv.DrawDashedPolyline([Point(10, 10), Point(56, 10), Point(56, 19)], 3, 8, 6, clBlack, 128);
    Cv := nil;
    Dash := 0;
    Gap := 0;
    for X := 10 to 54 do
    begin
      C := ColorToRGB(Bmp.Canvas.Pixels[X, 10]);
      if GetRValue(C) > 240 then
        Inc(Gap)
      else
      begin
        Inc(Dash);
        // Halbtransparent: grau, weder weiss noch schwarz
        CheckTrue((GetRValue(C) > 90) and (GetRValue(C) < 170),
          Format('Strichpixel %d halbtransparent (%d)', [X, GetRValue(C)]));
      end;
    end;
    CheckTrue(Dash > 10, Format('Striche gezeichnet (%d)', [Dash]));
    CheckTrue(Gap > 5, Format('Luecken bleiben frei (runde Enden verkuerzen sie) (%d)', [Gap]));
    for X := 55 to 57 do
    begin
      C := ColorToRGB(Bmp.Canvas.Pixels[X, 10]);
      CheckTrue(GetRValue(C) > 90, Format('Ecke %d nur einmal geblendet (%d)', [X, GetRValue(C)]));
    end;
  finally
    Bmp.Free;
  end;
end;

{ TReviewPlannerTests }

function DT(Y, M, D: Word; H: Word = 0; N: Word = 0): TDateTime;
begin
  Result := EncodeDate(Y, M, D) + EncodeTime(H, N, 0, 0);
end;

procedure TReviewPlannerTests.SetUp;
begin
  inherited SetUp;
  FItems := TPPGAppointments.Create(nil);
  FItems.SetDisplayZone(PPGFindTimeZone('Europe/Berlin'));
  CheckNotNull(FItems.DisplayZone, 'Europe/Berlin in der Registry');
end;

procedure TReviewPlannerTests.TearDown;
begin
  FreeAndNil(FItems);
  inherited TearDown;
end;

function TReviewPlannerTests.Daily(Start: TDateTime; const Rule: string): TPPGAppointment;
begin
  Result := FItems.AddAppointment(Start, Start + 1 / 24, 'Serie');
  Result.Recurrence := Rule;
end;

procedure TReviewPlannerTests.AxisScaleHandlesHugeValues;
var
  S: TPPGAxisScale;
begin
  // Lo/Step um 5e9 > 2^31 (Bereich gross genug, sonst gilt er als ein Wert): Floor/Ceil aus System.Math liefen ueber
  S := PPGNiceScale(5E12, 5E12 + 6000, 6, False);
  CheckTrue(S.Min <= 5E12, Format('Min %g', [S.Min]));
  CheckTrue(S.Max >= 5E12 + 6000, Format('Max %g', [S.Max]));
  CheckTrue(S.Max - S.Min < 20000, Format('Spanne %g', [S.Max - S.Min]));
  CheckTrue(PPGScaleTickCount(S) >= 2, 'Striche');
  CheckEquals(S.Min, PPGScaleTick(S, 0), 1E-3, 'erster Strich');
  CheckEquals(S.Min + S.Step, PPGScaleTick(S, 1), 1E-3, 'zweiter Strich');
end;

procedure TReviewPlannerTests.AllDayExceptionExportsDateOnly;
var
  A: TPPGAppointment;
  Text: string;
begin
  A := FItems.Add;
  A.AllDay := True;
  A.Start := DT(2026, 10, 5);
  A.Finish := DT(2026, 10, 6);
  A.Recurrence := 'FREQ=DAILY;COUNT=5';
  A.AddException(DT(2026, 10, 7));
  CheckEquals(4, Length(FItems.GetOccurrences(DT(2026, 10, 1), DT(2026, 11, 1))), 'Ausnahme greift');
  Text := PPGICalText(FItems);
  CheckTrue(Pos('EXDATE;VALUE=DATE:20261007'#13#10, Text) > 0, 'nur Datum: ' + Text);
end;

procedure TReviewPlannerTests.DetachedOccurrenceNotExportedAsExDate;
var
  O: TArray<TPPGOccurrence>;
  Text: string;
  Other: TPPGAppointments;
begin
  Daily(DT(2026, 10, 5, 9), 'FREQ=DAILY;COUNT=3');
  O := FItems.GetOccurrences(DT(2026, 10, 1), DT(2026, 11, 1));
  CheckEquals(3, Length(O));
  FItems.DetachOccurrence(O[1]).Subject := 'verschoben';
  Text := PPGICalText(FItems);
  CheckTrue(Pos('RECURRENCE-ID', Text) > 0, 'Einzeltermin mit RECURRENCE-ID');
  CheckEquals(0, Pos('EXDATE', Text), 'kein EXDATE fuer den Einzeltermin: ' + Text);
  // Rundweg: der Import traegt die Ausnahme selbst wieder ein
  Other := TPPGAppointments.Create(nil);
  try
    Other.SetDisplayZone(FItems.DisplayZone);
    CheckEquals(2, PPGLoadICalText(Other, Text));
    CheckEquals(3, Length(Other.GetOccurrences(DT(2026, 10, 1), DT(2026, 11, 1))),
      'Serie ohne das Vorkommen + Einzeltermin');
  finally
    Other.Free;
  end;
end;

procedure TReviewPlannerTests.UntilUtcAppliesInLocalMode;
begin
  // 08:00 UTC = 10:00 MESZ: das Vorkommen am 10.10. um 09:00 gehoert dazu
  FItems.TimeZoneMode := tzmLocal;
  Daily(DT(2026, 10, 8, 9), 'FREQ=DAILY;UNTIL=20261010T080000Z');
  CheckEquals(3, Length(FItems.GetOccurrences(DT(2026, 10, 1), DT(2026, 11, 1))));
end;

procedure TReviewPlannerTests.ExceptionInSpringGapApplies;
var
  O: TArray<TPPGOccurrence>;
begin
  // 29.03.2026: 02:30 gibt es nicht, die Serie zeigt es trotzdem (Wanduhr)
  Daily(DT(2026, 3, 28, 2, 30), 'FREQ=DAILY;COUNT=3');
  O := FItems.GetOccurrences(DT(2026, 3, 27), DT(2026, 4, 1));
  CheckEquals(3, Length(O));
  CheckEquals(DT(2026, 3, 29, 2, 30), O[1].Start, 1E-9, 'Vorkommen in der Luecke');
  O[1].Appointment.AddException(O[1].Start);
  O := FItems.GetOccurrences(DT(2026, 3, 27), DT(2026, 4, 1));
  CheckEquals(2, Length(O), 'Ausnahme in der Luecke greift');
  CheckEquals(DT(2026, 3, 30, 2, 30), O[1].Start, 1E-9);
end;

procedure TReviewPlannerTests.AssignKeepsIdsAndParents;
var
  O: TArray<TPPGOccurrence>;
  Child: TPPGAppointment;
  Other: TPPGAppointments;
begin
  FItems.Add; // Ids der Quelle nicht bei 1
  FItems.Add;
  Daily(DT(2026, 10, 5, 9), 'FREQ=DAILY;COUNT=3');
  O := FItems.GetOccurrences(DT(2026, 10, 1), DT(2026, 11, 1));
  Child := FItems.DetachOccurrence(O[1]);
  Other := TPPGAppointments.Create(nil);
  try
    Other.Add;
    Other.Add;
    Other.Add;
    Other.Add;
    Other.Add; // Ziel hat schon hoehere Ids vergeben
    Other.Assign(FItems);
    CheckEquals(FItems.Count, Other.Count);
    CheckEquals(Child.Id, Other[Other.Count - 1].Id, 'Id uebernommen');
    CheckSame(Other[2], Other.FindById(Other[Other.Count - 1].RecurrenceParent),
      'RecurrenceParent zeigt auf die kopierte Serie');
    CheckTrue(Other.Add.Id > Child.Id, 'neue Ids danach eindeutig');
  finally
    Other.Free;
  end;
end;

procedure TReviewPlannerTests.YearlyByMonthDayCoversAllMonths;
var
  A: TArray<TDateTime>;
  I: Integer;
begin
  A := TPPGRecurrence.Parse('FREQ=YEARLY;BYMONTHDAY=1;COUNT=12').Expand(DT(2026, 3, 1, 9),
    DT(2026, 3, 1), DT(2028, 1, 1), []);
  CheckEquals(12, Length(A));
  for I := 0 to High(A) do
    CheckEquals(IncMonth(DT(2026, 3, 1, 9), I), A[I], 1E-9,
      Format('Vorkommen %d am 1. des Monats', [I]));
end;

procedure TReviewPlannerTests.ExpandWithoutCountMatchesFullCount;

  procedure Same(const Rule: string; Start, AFrom, ATo: TDateTime);
  var
    R: TPPGRecurrence;
    Fast, Full: TArray<TDateTime>;
    I, K: Integer;
  begin
    R := TPPGRecurrence.Parse(Rule);
    Fast := R.Expand(Start, AFrom, ATo, []);
    // Mit COUNT (sehr gross) wird ab DTSTART gezaehlt, also ohne Sprung
    R := TPPGRecurrence.Parse(Rule + ';COUNT=1000000');
    Full := R.Expand(Start, AFrom, ATo, []);
    CheckTrue(Length(Full) > 0, Rule + ': Vorkommen im Zeitraum');
    CheckEquals(Length(Full), Length(Fast), Rule + ': Anzahl');
    K := System.Math.Min(Length(Full), Length(Fast));
    for I := 0 to K - 1 do
      CheckEquals(Full[I], Fast[I], 1E-9, Format('%s: Vorkommen %d', [Rule, I]));
  end;

begin
  Same('FREQ=DAILY;INTERVAL=3', DT(2006, 1, 1, 9), DT(2026, 10, 1), DT(2026, 11, 1));
  Same('FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE', DT(2020, 1, 6, 9), DT(2026, 10, 1), DT(2026, 11, 1));
  Same('FREQ=MONTHLY;INTERVAL=3;BYMONTHDAY=15', DT(2001, 1, 15, 9), DT(2026, 1, 1), DT(2027, 1, 1));
  Same('FREQ=MONTHLY;BYDAY=-1FR;BYSETPOS=1', DT(2001, 1, 26, 9), DT(2026, 1, 1), DT(2026, 6, 1));
  Same('FREQ=YEARLY;INTERVAL=2', DT(2000, 6, 10, 9), DT(2020, 1, 1), DT(2030, 1, 1));
end;

{ TReviewUiaTests }

procedure TReviewUiaTests.RootWithoutFocusedChildLeavesFocusToHost;
var
  L: TPPGListBox;
  V: OleVariant;
begin
  // Leere Liste, kein Element fokussiert: der Host-Provider des Fensters
  // muss antworten koennen, ein festes False ueberdeckt ihn
  L := TPPGListBox.Create(FForm);
  L.Parent := FForm;
  L.SetBounds(0, 0, 200, 150);
  MakeRoot(L);
  V := PropOf(FRoot as IRawElementProviderSimple, UIA_HasKeyboardFocusPropertyId);
  CheckTrue(VarIsEmpty(V), 'Wurzel liefert keinen eigenen Wert');
end;

initialization
  RegisterTest('Review', TReviewTests.Suite);
  RegisterTest('Review', TReviewPlannerTests.Suite);
  RegisterTest('Review', TReviewUiaTests.Suite);

end.
