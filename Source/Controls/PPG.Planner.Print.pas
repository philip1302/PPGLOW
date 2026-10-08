unit PPG.Planner.Print;

{ Drucken des Terminplaners (Phase 14a) ueber den gemeinsamen Druck-Weg
  (TPPGCustomPrinter: Vorschau, PDF, Seite einrichten).

  - Eine Seite je Zeitraum: Tag (DayCount Tage), Arbeitswoche, Woche,
    Monat oder Agenda (7 Tage je Seite); die Zeitleiste wird als Woche
    gedruckt. PrintFrom/PrintTo = 0: nur der Zeitraum um Planner.Date.
  - Gezeichnet wird mit demselben Code wie auf dem Bildschirm: ein
    unsichtbarer Planer in Druckeraufloesung (ScalePPI = Drucker-PPI) mit den
    Einstellungen und Terminen des Planers, helle Farben, ohne Auswahl und
    "Jetzt"-Linie. Das Raster wird so hoch, dass die Stunden auf die Seite
    passen (WorkHoursOnly: nur die Arbeitszeit). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.Types, Vcl.Graphics,
  PPG.Print, PPG.Planner.Model, PPG.Planner;

type
  TPPGPlannerPrinter = class(TPPGCustomPrinter)
  private
    FPlanner: TPPGCustomPlanner;
    FView: TPPGPlannerView;
    FPrintFrom: TDate;
    FPrintTo: TDate;
    FWorkHoursOnly: Boolean;
    procedure SetPlanner(const Value: TPPGCustomPlanner);
    function Base: TDate;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    function PageCount(const Device: TPPGPrintDevice): Integer; override;
    procedure RenderPage(PageIndex: Integer; DC: HDC; const Device: TPPGPrintDevice); override;
    function OptionCount: Integer; override;
    function OptionCaption(Index: Integer): string; override;
    function GetOption(Index: Integer): Boolean; override;
    procedure SetOption(Index: Integer; Value: Boolean); override;
    /// Erster Tag der Seite.
    function PageStart(PageIndex: Integer): TDate;
    /// Ueberschrift der Seite (Zeitraum).
    function PageTitle(PageIndex: Integer): string;
    /// Ansicht und Datum wie im Planer (eine Seite).
    procedure TakeFromPlanner;
  published
    property Planner: TPPGCustomPlanner read FPlanner write SetPlanner;
    property View: TPPGPlannerView read FView write FView default pvWeek;
    /// Zeitraum (0 = nur die Seite um Planner.Date).
    property PrintFrom: TDate read FPrintFrom write FPrintFrom;
    property PrintTo: TDate read FPrintTo write FPrintTo;
    property WorkHoursOnly: Boolean read FWorkHoursOnly write FWorkHoursOnly default True;
    property Title;
    property HeaderText;
    property FooterText;
    property Orientation;
    property Margins;
    property PrinterName;
  end;

implementation

uses
  System.Math, System.DateUtils, System.UITypes, Vcl.Controls, PPG.Lang, PPG.Consts, PPG.Calendar,
  PPG.Controls.Scroll, PPG.Render.Intf, PPG.Render.Gdi;

type
  /// Unsichtbarer Planer in Druckeraufloesung.
  TPrintPlanner = class(TPPGCustomPlanner)
  private
    FPPI: Integer;
  public
    function ScalePPI: Integer; override;
    procedure RenderTo(const ACanvas: IPPGCanvas; const R: TRect);
  end;

  /// Termine des eigentlichen Planers fuer den Druck-Planer.
  TPlannerSource = class(TInterfacedObject, IPPGAppointmentSource)
  private
    FPlanner: TPPGCustomPlanner;
  public
    constructor Create(APlanner: TPPGCustomPlanner);
    function GetOccurrences(AFrom, ATo: TDateTime): TArray<TPPGOccurrence>;
  end;

function TPrintPlanner.ScalePPI: Integer;
begin
  if FPPI > 0 then
    Result := FPPI
  else
    Result := inherited ScalePPI;
end;

procedure TPrintPlanner.RenderTo(const ACanvas: IPPGCanvas; const R: TRect);
begin
  PaintViewport(ACanvas, R);
end;

constructor TPlannerSource.Create(APlanner: TPPGCustomPlanner);
begin
  inherited Create;
  FPlanner := APlanner;
end;

function TPlannerSource.GetOccurrences(AFrom, ATo: TDateTime): TArray<TPPGOccurrence>;
begin
  Result := FPlanner.GetOccurrences(AFrom, ATo);
end;

function Acc(P: TPPGCustomPlanner): TPrintPlanner;
begin
  // Zugriff auf die geschuetzten Einstellungen (nur lesen)
  Result := TPrintPlanner(P);
end;

{ TPPGPlannerPrinter }

constructor TPPGPlannerPrinter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FView := pvWeek;
  FWorkHoursOnly := True;
end;

procedure TPPGPlannerPrinter.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FPlanner) then
    FPlanner := nil;
end;

procedure TPPGPlannerPrinter.SetPlanner(const Value: TPPGCustomPlanner);
begin
  if FPlanner <> Value then
  begin
    if FPlanner <> nil then
      FPlanner.RemoveFreeNotification(Self);
    FPlanner := Value;
    if FPlanner <> nil then
      FPlanner.FreeNotification(Self);
  end;
end;

procedure TPPGPlannerPrinter.TakeFromPlanner;
begin
  if FPlanner = nil then
    Exit;
  FView := Acc(FPlanner).View;
  FPrintFrom := 0;
  FPrintTo := 0;
end;

function TPPGPlannerPrinter.OptionCount: Integer;
begin
  Result := 1;
end;

function TPPGPlannerPrinter.OptionCaption(Index: Integer): string;
begin
  Result := PPGStr(@SPPGPlannerPrintWorkHours);
end;

function TPPGPlannerPrinter.GetOption(Index: Integer): Boolean;
begin
  Result := FWorkHoursOnly;
end;

procedure TPPGPlannerPrinter.SetOption(Index: Integer; Value: Boolean);
begin
  FWorkHoursOnly := Value;
end;

function TPPGPlannerPrinter.Base: TDate;
begin
  if FPrintFrom <> 0 then
    Result := Trunc(FPrintFrom)
  else if FPlanner <> nil then
    Result := Trunc(Acc(FPlanner).Date)
  else
    Result := Trunc(System.SysUtils.Date);
end;

function WeekStartOf(D: TDate; FirstDay: Integer): TDate;
begin
  Result := Trunc(D) - ((DayOfTheWeek(D) - FirstDay + 7) mod 7);
end;

function TPPGPlannerPrinter.PageStart(PageIndex: Integer): TDate;
var
  FirstDay: Integer;
begin
  if FPlanner <> nil then
    FirstDay := FPlanner.EffectiveFirstDay
  else
    FirstDay := 1;
  case FView of
    pvDay:
      if FPlanner <> nil then
        Result := Base + PageIndex * Acc(FPlanner).DayCount
      else
        Result := Base + PageIndex;
    pvMonth: Result := IncMonth(StartOfTheMonth(Base), PageIndex);
    pvAgenda: Result := Base + 7 * PageIndex;
  else
    Result := WeekStartOf(Base, FirstDay) + 7 * PageIndex;
  end;
end;

function TPPGPlannerPrinter.PageCount(const Device: TPPGPrintDevice): Integer;
begin
  if FPlanner = nil then
    Exit(0);
  Result := 1;
  if (FPrintFrom = 0) or (FPrintTo = 0) then
    Exit;
  while (Result < 1000) and (PageStart(Result) <= Trunc(FPrintTo)) do
    Inc(Result);
end;

function TPPGPlannerPrinter.PageTitle(PageIndex: Integer): string;
var
  S, E: TDate;
begin
  S := PageStart(PageIndex);
  case FView of
    pvDay:
      begin
        E := S;
        if FPlanner <> nil then
          E := S + Acc(FPlanner).DayCount - 1;
      end;
    pvMonth:
      Exit(FormatSettings.LongMonthNames[MonthOf(S)] + ' ' + IntToStr(YearOf(S)));
    pvWorkWeek:
      E := S + 4;
  else
    E := S + 6;
  end;
  if E = S then
    Result := FormatDateTime(FormatSettings.LongDateFormat, S)
  else
    Result := FormatDateTime(FormatSettings.LongDateFormat, S) + ' - ' +
      FormatDateTime(FormatSettings.LongDateFormat, E);
end;

procedure TPPGPlannerPrinter.RenderPage(PageIndex: Integer; DC: HDC; const Device: TPPGPrintDevice);
var
  Content, Body, R: TRect;
  F, FB: TFont;
  P: TPrintPlanner;
  Canvas: IPPGCanvas;
  TM: TTextMetric;
  Old: HGDIOBJ;
  S: string;
  W, H, Slots, Logical: Integer;
begin
  if (FPlanner = nil) or (PageIndex < 0) or (PageIndex >= PageCount(Device)) then
    Exit;
  F := TFont.Create;
  FB := TFont.Create;
  P := TPrintPlanner.Create(nil);
  SaveDC(DC);
  try
    F.Assign(Acc(FPlanner).Font);
    F.Height := -MulDiv(Acc(FPlanner).Font.Size, Device.PPI, 72);
    FB.Assign(F);
    FB.Style := FB.Style + [fsBold];
    Content := MarginRect(Device);
    Body := PaintHeaderFooter(DC, Content, PageIndex, PageCount(Device), F, FB);
    // Zeitraum als Ueberschrift
    FB.Height := F.Height * 3 div 2;
    Old := SelectObject(DC, FB.Handle);
    GetTextMetrics(DC, TM);
    SetBkMode(DC, TRANSPARENT);
    SetTextColor(DC, 0);
    S := PageTitle(PageIndex);
    R := Rect(Body.Left, Body.Top, Body.Right, Body.Top + TM.tmHeight * 3 div 2);
    Winapi.Windows.DrawText(DC, PChar(S), Length(S), R, DT_SINGLELINE or DT_TOP or DT_NOPREFIX or
      DT_END_ELLIPSIS);
    SelectObject(DC, Old);
    Body.Top := R.Bottom;
    W := Body.Right - Body.Left;
    H := Body.Bottom - Body.Top;
    if (W <= 0) or (H <= 0) then
      Exit;
    // Unsichtbarer Planer mit den Einstellungen des Planers
    P.FPPI := Device.PPI;
    P.SetBounds(0, 0, W, H);
    P.Source := TPlannerSource.Create(FPlanner);
    P.Resources.Assign(Acc(FPlanner).Resources);
    P.GroupByResource := Acc(FPlanner).GroupByResource;
    P.FirstDayOfWeek := Acc(FPlanner).FirstDayOfWeek;
    P.WorkDays := Acc(FPlanner).WorkDays;
    P.WorkStart := Acc(FPlanner).WorkStart;
    P.WorkEnd := Acc(FPlanner).WorkEnd;
    P.SlotMinutes := Acc(FPlanner).SlotMinutes;
    P.BiDiMode := Acc(FPlanner).BiDiMode;
    P.OnGetAppointmentColor := Acc(FPlanner).OnGetAppointmentColor;
    P.Categories := Acc(FPlanner).Categories;
    P.PlannerStyles := Acc(FPlanner).PlannerStyles;
    P.OnCustomDrawAppointment := Acc(FPlanner).OnCustomDrawAppointment;
    P.ShowNowLine := False;
    P.HighContrastSupport := False;
    P.ScrollBarMode := sbmNever;
    P.Preset := Acc(FPlanner).Preset;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    // Papier: helle Farben, weder Dark Mode noch VCL-Style
    P.StyleElements := P.StyleElements - [seClient];
    {$ENDIF}
    P.Font.Assign(F);
    if FWorkHoursOnly and (Acc(FPlanner).WorkEnd > Acc(FPlanner).WorkStart) then
    begin
      P.DayEndHour := Min(24, (Acc(FPlanner).WorkEnd + 59) div 60);
      P.DayStartHour := Max(0, Min(P.DayEndHour - 1, Acc(FPlanner).WorkStart div 60));
    end
    else
    begin
      P.DayEndHour := Acc(FPlanner).DayEndHour;
      P.DayStartHour := Acc(FPlanner).DayStartHour;
    end;
    case FView of
      pvTimeline: P.View := pvWeek;
      pvAgenda:
        begin
          P.View := pvAgenda;
          P.AgendaDays := 7;
        end;
    else
      P.View := FView;
    end;
    P.DayCount := Acc(FPlanner).DayCount;
    P.Date := PageStart(PageIndex);
    // Raster so hoch, dass die Stunden auf die Seite passen
    if P.View in [pvDay, pvWorkWeek, pvWeek] then
    begin
      P.EnsureLayout;
      Slots := (P.DayEndHour - P.DayStartHour) * 60 div P.SlotMinutes;
      if Slots > 0 then
      begin
        Logical := MulDiv((H - P.HeaderHeight) div Slots, 96, Device.PPI);
        P.SlotHeight := Max(8, Min(200, Logical));
      end;
    end;
    P.EnsureLayout;
    SetViewportOrgEx(DC, Body.Left, Body.Top, nil);
    IntersectClipRect(DC, 0, 0, W, H);
    Canvas := TPPGGdiCanvas.Create(DC);
    P.RenderTo(Canvas, Rect(0, 0, W, H));
    Canvas := nil;
  finally
    RestoreDC(DC, -1);
    P.Free;
    FB.Free;
    F.Free;
  end;
end;

end.
