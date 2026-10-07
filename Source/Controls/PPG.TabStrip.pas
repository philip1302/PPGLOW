unit PPG.TabStrip;

{ TPPGTabStrip - Reiterleiste fuer TabControl und PageControl (Komposition,
  kein Control: das besitzende Control fuettert die Reiter, ruft Layout auf
  und zeichnet ueber Paint).

  - Geometrie: Breite aus Text, Bild und Schliessen-Knopf (oder fest per
    TabWidth), Hoehe aus der Schrift (oder TabHeight); RTL wird gespiegelt.
  - Ueberlauf: reichen die Reiter nicht, erscheinen rechts zwei Blaetterpfeile
    (keine mehrzeiligen Reiter).
  - Hit-Test fuer Reiter, Schliessen-Knopf und Pfeile, Hover-Zustand.
  - Unterstrich (Indikator) gleitet beim Wechsel ueber den gemeinsamen
    Animator von der alten zur neuen Position.
  - Zeichnet nur ueber IPPGTabRenderer; Paint sendet keine Nachrichten. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.Types, Vcl.Graphics, Vcl.ImgList,
  PPG.Types, PPG.Animation, PPG.Render.Intf;

type
  TPPGTabInfo = record
    Caption: string;
    ImageIndex: Integer;
    Enabled: Boolean;
    Index: Integer; // Index beim Besitzer (Tabs-Eintrag bzw. Seite)
  end;

  TPPGTabHit = (thNone, thTab, thClose, thPrev, thNext);

  /// Farben und Zustaende zum Zeichnen (berechnet das besitzende Control).
  TPPGTabPaintInfo = record
    Strip: TPPGSurfaceStyle;     // Leiste (Color = clNone: nichts zeichnen)
    Tab: TPPGSurfaceStyle;       // nicht gewaehlter Reiter
    HotTab: TPPGSurfaceStyle;    // Reiter unter der Maus
    Selected: TPPGSurfaceStyle;  // gewaehlter Reiter (Seitenfarben)
    Accent: TColor;              // Unterstrich
    DisabledText: TColor;
    Overlap: Integer;            // Rahmenbreite der Seite (gewaehlter Reiter ragt hinein)
    HotTrack: Boolean;
    Focused: Boolean;            // Fokusrahmen um den gewaehlten Reiter
    ShowAccel: Boolean;          // &-Unterstriche sichtbar
    Enabled: Boolean;
  end;

  TPPGTabStrip = class
  private
    FTabs: array of TPPGTabInfo;
    FRects: array of TRect;
    FCloseRects: array of TRect;
    FStrip: TRect;
    FTabArea: TRect;
    FPrevRect: TRect;
    FNextRect: TRect;
    FOverflow: Boolean;
    FFirst: Integer;
    FMaxFirst: Integer;
    FSelected: Integer;
    FHot: Integer;
    FHotClose: Integer;
    FHotArrow: TPPGTabHit;
    FFont: TFont;
    FImages: TCustomImageList;
    FPPI: Integer;
    FTabWidth: Integer;
    FTabHeight: Integer;
    FShowClose: Boolean;
    FBottom: Boolean;
    FRightToLeft: Boolean;
    FIndicatorAnim: TPPGAnimation;
    FIndicatorFrom: TRect;
    FOnChange: TNotifyEvent;
    procedure AnimStep(Sender: TObject);
    procedure Changed;
    function Scale(Value: Integer): Integer;
    function TabWidthAt(Pos: Integer): Integer;
    function IndicatorFor(Pos: Integer): TRect;
    function Mirror(const R: TRect): TRect;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Add(const Caption: string; ImageIndex: Integer; Enabled: Boolean;
      OwnerIndex: Integer);
    function Count: Integer;
    function Tab(Pos: Integer): TPPGTabInfo;
    /// Position eines Besitzer-Index in der Leiste, -1 = nicht vorhanden.
    function PosOf(OwnerIndex: Integer): Integer;
    /// Hoehe der Leiste in px (Reiter + Abstand zum Rand).
    function StripHeight: Integer;
    /// Berechnet alle Rechtecke (Client-Koordinaten des Besitzers).
    procedure Layout(const StripRect: TRect);
    function HitTest(X, Y: Integer; out OwnerIndex: Integer): TPPGTabHit;
    /// Rechteck eines Reiters (Position), leer = nicht sichtbar.
    function TabRectAt(Pos: Integer): TRect;
    function CloseRectAt(Pos: Integer): TRect;
    /// Waehlt einen Reiter (Besitzer-Index); Animate laesst den Unterstrich gleiten.
    procedure Select(OwnerIndex: Integer; Animate: Boolean; DurationMs: Cardinal);
    procedure MakeVisible(Pos: Integer);
    function CanScroll(Delta: Integer): Boolean;
    procedure Scroll(Delta: Integer);
    /// Hover aktualisieren; True, wenn sich etwas geaendert hat.
    function UpdateHot(X, Y: Integer): Boolean;
    function ClearHot: Boolean;
    /// Aktuelle Lage des Unterstrichs (waehrend der Animation interpoliert).
    function IndicatorRect: TRect;
    function IndicatorMoving: Boolean;
    procedure Paint(const Canvas: IPPGCanvas; const Renderer: IPPGTabRenderer;
      const Info: TPPGTabPaintInfo);
    property Font: TFont read FFont write FFont;
    property Images: TCustomImageList read FImages write FImages;
    property PPI: Integer read FPPI write FPPI;
    property TabWidth: Integer read FTabWidth write FTabWidth;
    property TabHeight: Integer read FTabHeight write FTabHeight;
    property ShowClose: Boolean read FShowClose write FShowClose;
    property Bottom: Boolean read FBottom write FBottom;
    property RightToLeft: Boolean read FRightToLeft write FRightToLeft;
    property Overflow: Boolean read FOverflow;
    property FirstVisible: Integer read FFirst;
    property Selected: Integer read FSelected;
    property HotTab: Integer read FHot;
    property HotClose: Integer read FHotClose;
    property PrevRect: TRect read FPrevRect;
    property NextRect: TRect read FNextRect;
    property StripRect: TRect read FStrip;
    /// Neu zeichnen (Animation, Hover).
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

uses
  System.SysUtils, PPG.Appearance, PPG.Accessibility, PPG.Render.Gdi;

const
  TabPadX = 12;     // logische px links/rechts im Reiter
  TabPadY = 7;      // logische px ueber/unter dem Text
  StripPad = 4;     // logische px Abstand der Reiter zum aeusseren Rand
  TabGap = 2;       // logische px zwischen Reitern
  CloseSize = 16;   // logische px Schliessen-Knopf
  ImageGap = 6;     // logische px zwischen Bild und Text
  IndicatorH = 3;   // logische px Hoehe des Unterstrichs
  IndicatorInset = 10;

function LerpRect(const A, B: TRect; T: Single): TRect;
begin
  Result.Left := A.Left + Round((B.Left - A.Left) * T);
  Result.Top := A.Top + Round((B.Top - A.Top) * T);
  Result.Right := A.Right + Round((B.Right - A.Right) * T);
  Result.Bottom := A.Bottom + Round((B.Bottom - A.Bottom) * T);
end;

{ TPPGTabStrip }

constructor TPPGTabStrip.Create;
begin
  inherited Create;
  FSelected := -1;
  FHot := -1;
  FHotClose := -1;
  FPPI := 96;
  FIndicatorAnim := TPPGAnimation.Create(Self);
  FIndicatorAnim.OnStep := AnimStep;
  FIndicatorAnim.Jump(1);
end;

destructor TPPGTabStrip.Destroy;
begin
  if FIndicatorAnim <> nil then
    FIndicatorAnim.OnStep := nil;
  FreeAndNil(FIndicatorAnim); // meldet sich selbst beim Animator ab
  inherited Destroy;
end;

procedure TPPGTabStrip.AnimStep(Sender: TObject);
begin
  Changed;
end;

procedure TPPGTabStrip.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TPPGTabStrip.Scale(Value: Integer): Integer;
begin
  Result := PPGScale(Value, FPPI);
end;

procedure TPPGTabStrip.Clear;
begin
  SetLength(FTabs, 0);
  SetLength(FRects, 0);
  SetLength(FCloseRects, 0);
  FSelected := -1;
  FHot := -1;
  FHotClose := -1;
end;

procedure TPPGTabStrip.Add(const Caption: string; ImageIndex: Integer; Enabled: Boolean;
  OwnerIndex: Integer);
var
  N: Integer;
begin
  N := Length(FTabs);
  SetLength(FTabs, N + 1);
  FTabs[N].Caption := Caption;
  FTabs[N].ImageIndex := ImageIndex;
  FTabs[N].Enabled := Enabled;
  FTabs[N].Index := OwnerIndex;
end;

function TPPGTabStrip.Count: Integer;
begin
  Result := Length(FTabs);
end;

function TPPGTabStrip.Tab(Pos: Integer): TPPGTabInfo;
begin
  Result := FTabs[Pos];
end;

function TPPGTabStrip.PosOf(OwnerIndex: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FTabs) do
    if FTabs[I].Index = OwnerIndex then
      Exit(I);
end;

function TPPGTabStrip.StripHeight: Integer;
var
  H: Integer;
begin
  if FTabHeight > 0 then
    H := Scale(FTabHeight)
  else
  begin
    if FFont <> nil then
      H := PPGMeasureTextNoCanvas('Wg', FFont, 0, False).cy
    else
      H := Scale(15);
    H := H + 2 * Scale(TabPadY);
    if (FImages <> nil) and (FImages.Height + 2 * Scale(4) > H) then
      H := FImages.Height + 2 * Scale(4);
  end;
  Result := H + Scale(StripPad);
end;

function TPPGTabStrip.TabWidthAt(Pos: Integer): Integer;
var
  S: string;
begin
  if FTabWidth > 0 then
    Exit(Scale(FTabWidth));
  S := PPGAccStripHotkey(FTabs[Pos].Caption);
  if (S <> '') and (FFont <> nil) then
    Result := PPGMeasureTextNoCanvas(S, FFont, 0, False).cx
  else
    Result := 0;
  Inc(Result, 2 * Scale(TabPadX));
  if (FImages <> nil) and (FTabs[Pos].ImageIndex >= 0) then
    Inc(Result, FImages.Width + Scale(ImageGap));
  if FShowClose then
    Inc(Result, Scale(CloseSize) + Scale(4));
  if Result < Scale(40) then
    Result := Scale(40);
end;

function TPPGTabStrip.Mirror(const R: TRect): TRect;
begin
  if IsRectEmpty(R) then
    Exit(R);
  Result := Rect(FStrip.Left + FStrip.Right - R.Right, R.Top,
    FStrip.Left + FStrip.Right - R.Left, R.Bottom);
end;

procedure TPPGTabStrip.Layout(const StripRect: TRect);
var
  N, I, X, Y0, TabH, Left0, Right0, Total, ArrowW, Avail, Sum, CS: Integer;
  W: array of Integer;
  R: TRect;
begin
  FStrip := StripRect;
  N := Length(FTabs);
  SetLength(FRects, N);
  SetLength(FCloseRects, N);
  SetLength(W, N);
  TabH := StripHeight - Scale(StripPad);
  if FBottom then
    Y0 := StripRect.Top
  else
    Y0 := StripRect.Bottom - TabH;
  Total := 0;
  for I := 0 to N - 1 do
  begin
    W[I] := TabWidthAt(I);
    Inc(Total, W[I]);
    if I > 0 then
      Inc(Total, Scale(TabGap));
  end;
  Left0 := StripRect.Left + Scale(StripPad);
  Right0 := StripRect.Right - Scale(StripPad);
  FPrevRect := Rect(0, 0, 0, 0);
  FNextRect := Rect(0, 0, 0, 0);
  FOverflow := Total > Right0 - Left0;
  if FOverflow then
  begin
    ArrowW := TabH * 4 div 5;
    FNextRect := Rect(Right0 - ArrowW, Y0, Right0, Y0 + TabH);
    FPrevRect := Rect(FNextRect.Left - ArrowW, Y0, FNextRect.Left, Y0 + TabH);
    Right0 := FPrevRect.Left - Scale(TabGap);
    // Groesster sinnvoller erster Reiter: ab dort passt der Rest
    Avail := Right0 - Left0;
    FMaxFirst := N - 1;
    Sum := 0;
    for I := N - 1 downto 0 do
    begin
      Inc(Sum, W[I]);
      if I < N - 1 then
        Inc(Sum, Scale(TabGap));
      if Sum > Avail then
        Break;
      FMaxFirst := I;
    end;
  end
  else
    FMaxFirst := 0;
  if FFirst > FMaxFirst then
    FFirst := FMaxFirst;
  if FFirst < 0 then
    FFirst := 0;
  FTabArea := Rect(Left0, StripRect.Top, Right0, StripRect.Bottom);

  CS := Scale(CloseSize);
  X := Left0;
  for I := 0 to N - 1 do
  begin
    FRects[I] := Rect(0, 0, 0, 0);
    FCloseRects[I] := Rect(0, 0, 0, 0);
    if I < FFirst then
      Continue;
    R := Rect(X, Y0, X + W[I], Y0 + TabH);
    Inc(X, W[I] + Scale(TabGap));
    if R.Left >= Right0 then
      Continue;
    if FShowClose then
      FCloseRects[I] := Rect(R.Right - Scale(TabPadX) div 2 - CS,
        (R.Top + R.Bottom - CS) div 2, R.Right - Scale(TabPadX) div 2,
        (R.Top + R.Bottom + CS) div 2);
    if R.Right > Right0 then
    begin
      R.Right := Right0; // angeschnitten (Text mit Ellipse)
      if FCloseRects[I].Right > Right0 then
        FCloseRects[I] := Rect(0, 0, 0, 0);
    end;
    FRects[I] := R;
  end;

  if FRightToLeft then
  begin
    for I := 0 to N - 1 do
    begin
      FRects[I] := Mirror(FRects[I]);
      FCloseRects[I] := Mirror(FCloseRects[I]);
    end;
    // Pfeile mitspiegeln: "zurueck" zeigt weiter zum ersten Reiter (rechts)
    FPrevRect := Mirror(FPrevRect);
    FNextRect := Mirror(FNextRect);
    FTabArea := Mirror(FTabArea);
  end;
  if FHot > N - 1 then
    FHot := -1;
  if FHotClose > N - 1 then
    FHotClose := -1;
  if FSelected > N - 1 then
    FSelected := -1;
end;

function TPPGTabStrip.TabRectAt(Pos: Integer): TRect;
begin
  if (Pos < 0) or (Pos > High(FRects)) then
    Result := Rect(0, 0, 0, 0)
  else
    Result := FRects[Pos];
end;

function TPPGTabStrip.CloseRectAt(Pos: Integer): TRect;
begin
  if (Pos < 0) or (Pos > High(FCloseRects)) then
    Result := Rect(0, 0, 0, 0)
  else
    Result := FCloseRects[Pos];
end;

function TPPGTabStrip.HitTest(X, Y: Integer; out OwnerIndex: Integer): TPPGTabHit;
var
  I: Integer;
  P: TPoint;
begin
  OwnerIndex := -1;
  Result := thNone;
  P := Point(X, Y);
  if FOverflow then
  begin
    if PtInRect(FPrevRect, P) then
      Exit(thPrev);
    if PtInRect(FNextRect, P) then
      Exit(thNext);
  end;
  for I := 0 to High(FRects) do
    if not IsRectEmpty(FRects[I]) and PtInRect(FRects[I], P) then
    begin
      OwnerIndex := FTabs[I].Index;
      if not IsRectEmpty(FCloseRects[I]) and PtInRect(FCloseRects[I], P) then
        Result := thClose
      else
        Result := thTab;
      Exit;
    end;
end;

function TPPGTabStrip.UpdateHot(X, Y: Integer): Boolean;
var
  Hit: TPPGTabHit;
  Idx, Pos, Close: Integer;
  Arrow: TPPGTabHit;
begin
  Hit := HitTest(X, Y, Idx);
  Pos := -1;
  Close := -1;
  Arrow := thNone;
  case Hit of
    thTab:
      Pos := PosOf(Idx);
    thClose:
      begin
        Pos := PosOf(Idx);
        Close := Pos;
      end;
    thPrev, thNext:
      Arrow := Hit;
  end;
  Result := (Pos <> FHot) or (Close <> FHotClose) or (Arrow <> FHotArrow);
  FHot := Pos;
  FHotClose := Close;
  FHotArrow := Arrow;
end;

function TPPGTabStrip.ClearHot: Boolean;
begin
  Result := (FHot >= 0) or (FHotClose >= 0) or (FHotArrow <> thNone);
  FHot := -1;
  FHotClose := -1;
  FHotArrow := thNone;
end;

function TPPGTabStrip.IndicatorFor(Pos: Integer): TRect;
var
  R: TRect;
  Inset, H: Integer;
begin
  R := TabRectAt(Pos);
  if IsRectEmpty(R) then
    Exit(Rect(0, 0, 0, 0));
  Inset := Scale(IndicatorInset);
  if (R.Right - R.Left) - 2 * Inset < Scale(12) then
    Inset := ((R.Right - R.Left) - Scale(12)) div 2;
  if Inset < 0 then
    Inset := 0;
  H := Scale(IndicatorH);
  if FBottom then
    Result := Rect(R.Left + Inset, R.Top, R.Right - Inset, R.Top + H)
  else
    Result := Rect(R.Left + Inset, R.Bottom - H, R.Right - Inset, R.Bottom);
end;

function TPPGTabStrip.IndicatorRect: TRect;
var
  Target: TRect;
begin
  Target := IndicatorFor(FSelected);
  if FIndicatorAnim.Running and not IsRectEmpty(FIndicatorFrom) and
    not IsRectEmpty(Target) then
    Result := LerpRect(FIndicatorFrom, Target, FIndicatorAnim.Value)
  else
    Result := Target;
end;

function TPPGTabStrip.IndicatorMoving: Boolean;
begin
  Result := FIndicatorAnim.Running;
end;

procedure TPPGTabStrip.Select(OwnerIndex: Integer; Animate: Boolean; DurationMs: Cardinal);
var
  NewPos: Integer;
begin
  NewPos := PosOf(OwnerIndex);
  if Animate and (DurationMs > 0) and (FSelected >= 0) and (NewPos >= 0) and
    (NewPos <> FSelected) then
  begin
    FIndicatorFrom := IndicatorRect;
    FSelected := NewPos;
    MakeVisible(NewPos);
    FIndicatorAnim.Jump(0);
    FIndicatorAnim.AnimateTo(1, DurationMs, ekDecelerate);
  end
  else
  begin
    FSelected := NewPos;
    MakeVisible(NewPos);
    FIndicatorAnim.Jump(1);
  end;
end;

procedure TPPGTabStrip.MakeVisible(Pos: Integer);
var
  Guard: Integer;
  R: TRect;
begin
  if (Pos < 0) or (Pos >= Length(FTabs)) or not FOverflow then
    Exit;
  if Pos < FFirst then
  begin
    FFirst := Pos;
    Layout(FStrip);
    Exit;
  end;
  // Nach rechts weiterblaettern, bis der Reiter ganz sichtbar ist
  Guard := Length(FTabs);
  R := TabRectAt(Pos);
  while (Guard > 0) and (FFirst < Pos) and (FFirst < FMaxFirst) and
    (IsRectEmpty(R) or (R.Right - R.Left < TabWidthAt(Pos))) do
  begin
    Inc(FFirst);
    Layout(FStrip);
    R := TabRectAt(Pos);
    Dec(Guard);
  end;
end;

function TPPGTabStrip.CanScroll(Delta: Integer): Boolean;
begin
  if not FOverflow then
    Result := False
  else if Delta < 0 then
    Result := FFirst > 0
  else
    Result := FFirst < FMaxFirst;
end;

procedure TPPGTabStrip.Scroll(Delta: Integer);
begin
  if not CanScroll(Delta) then
    Exit;
  Inc(FFirst, Delta);
  Layout(FStrip);
  Changed;
end;

procedure TPPGTabStrip.Paint(const Canvas: IPPGCanvas; const Renderer: IPPGTabRenderer;
  const Info: TPPGTabPaintInfo);

  procedure PaintContent(Pos: Integer; const R: TRect; Color: TColor; IsSelected: Boolean);
  var
    C: TRect;
    T: TPPGTabInfo;
    Flags: Cardinal;
    X, Y: Integer;
    ImgEnabled: Boolean;
  begin
    T := FTabs[Pos];
    C := R;
    InflateRect(C, -Scale(TabPadX), 0);
    if FShowClose and not IsRectEmpty(FCloseRects[Pos]) then
    begin
      Renderer.DrawTabClose(Canvas, FCloseRects[Pos], Color, Pos = FHotClose, FPPI);
      if FRightToLeft then
        C.Left := FCloseRects[Pos].Right + Scale(4)
      else
        C.Right := FCloseRects[Pos].Left - Scale(4);
    end;
    if (FImages <> nil) and (T.ImageIndex >= 0) and (T.ImageIndex < FImages.Count) then
    begin
      Y := (R.Top + R.Bottom - FImages.Height) div 2;
      if FRightToLeft then
      begin
        X := C.Right - FImages.Width;
        C.Right := X - Scale(ImageGap);
      end
      else
      begin
        X := C.Left;
        C.Left := X + FImages.Width + Scale(ImageGap);
      end;
      ImgEnabled := Info.Enabled and T.Enabled;
      Canvas.DrawImage(FImages, T.ImageIndex, X, Y, ImgEnabled);
    end;
    if C.Right <= C.Left then
      Exit;
    Flags := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
    if FTabWidth > 0 then
      Flags := Flags or DT_CENTER;
    if FRightToLeft then
      Flags := Flags or DT_RIGHT or DT_RTLREADING;
    if not Info.ShowAccel then
      Flags := Flags or DT_HIDEPREFIX;
    Canvas.DrawText(C, T.Caption, FFont, Color, Flags);
    if IsSelected and Info.Focused then
    begin
      C := R;
      InflateRect(C, -Scale(4), -Scale(4));
      Canvas.DrawFocusRect(C);
    end;
  end;

var
  I: Integer;
  R, Area: TRect;
  Hot: Boolean;
  Color: TColor;
begin
  if Renderer = nil then
    Exit;
  Renderer.DrawTabStrip(Canvas, FStrip, Info.Strip, FBottom, FPPI);
  // Reiter nur im Reiterbereich (nicht unter den Pfeilen); der gewaehlte
  // darf um Overlap in die Seite ragen
  Area := FTabArea;
  if FBottom then
    Dec(Area.Top, Info.Overlap)
  else
    Inc(Area.Bottom, Info.Overlap);
  Canvas.PushClipRoundRect(Area, 0);
  try
    for I := 0 to High(FRects) do
    begin
      R := FRects[I];
      if IsRectEmpty(R) or (I = FSelected) then
        Continue;
      Hot := Info.HotTrack and Info.Enabled and FTabs[I].Enabled and (I = FHot);
      if Hot then
        Renderer.DrawTab(Canvas, R, Info.HotTab, False, 1, FBottom, FPPI)
      else
        Renderer.DrawTab(Canvas, R, Info.Tab, False, 0, FBottom, FPPI);
      if not (Info.Enabled and FTabs[I].Enabled) then
        Color := Info.DisabledText
      else if Hot then
        Color := Info.HotTab.TextColor
      else
        Color := Info.Tab.TextColor;
      PaintContent(I, R, Color, False);
    end;
    if (FSelected >= 0) and not IsRectEmpty(TabRectAt(FSelected)) then
    begin
      R := FRects[FSelected];
      if FBottom then
        Dec(R.Top, Info.Overlap)
      else
        Inc(R.Bottom, Info.Overlap);
      Renderer.DrawTab(Canvas, R, Info.Selected, True, 0, FBottom, FPPI);
      if Info.Enabled and FTabs[FSelected].Enabled then
        Color := Info.Selected.TextColor
      else
        Color := Info.DisabledText;
      PaintContent(FSelected, FRects[FSelected], Color, True);
    end;
    R := IndicatorRect;
    if not IsRectEmpty(R) and Info.Enabled then
      Renderer.DrawTabIndicator(Canvas, R, Info.Accent, FBottom, FPPI);
  finally
    Canvas.PopClip;
  end;
  if FOverflow then
  begin
    Renderer.DrawTabScrollArrow(Canvas, FPrevRect, Info.Tab.TextColor, FRightToLeft,
      FHotArrow = thPrev, Info.Enabled and CanScroll(-1), FPPI);
    Renderer.DrawTabScrollArrow(Canvas, FNextRect, Info.Tab.TextColor, not FRightToLeft,
      FHotArrow = thNext, Info.Enabled and CanScroll(1), FPPI);
  end;
end;

end.
