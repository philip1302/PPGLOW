unit PPG.ProgressBar;

{ TPPGProgressBar - Fortschrittsbalken in der Optik des Presets.

  - Spur = Appearance.Normal, Fuellung = Appearance.Checked ("an"-Farbe)
  - State pbsError/pbsPaused faerbt die Fuellung rot bzw. gelb (wie Windows)
  - Style pbstMarquee: unbestimmter Fortschritt, laeuft ueber den gemeinsamen
    Animator (kein eigener Timer) und nur, solange das Control sichtbar ist.
    Mit abgeschalteten Animationen (Systemeinstellung, Remote-Desktop) steht
    das Segment still in der Mitte.
  - Positionswechsel werden weich animiert (Animation-Einstellungen).
  - Migration: Typen und Property-Namen von TProgressBar (Vcl.ComCtrls), eine
    DFM laesst sich per Suchen/Ersetzen umstellen. Smooth wird nur zur
    Kompatibilitaet gelesen: PPGlow zeichnet immer einen durchgehenden Balken. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.ComCtrls,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Controls.Range;

type
  TPPGCustomProgressBar = class(TPPGCustomRangeControl)
  private
    FOrientation: TProgressBarOrientation;
    FStyle: TProgressBarStyle;
    FState: TProgressBarState;
    FBarColor: TColor;
    FBackgroundColor: TColor;
    FStep: Integer;
    FMarqueeInterval: Integer;
    FSmooth: Boolean;
    FShowText: Boolean;
    FPosAnim: TPPGAnimation;
    FAnimFrom: Double;
    FMarqueeAnim: TPPGAnimation;
    procedure SetBarColor(const Value: TColor);
    procedure SetBackgroundColor(const Value: TColor);
    procedure AnimStep(Sender: TObject);
    procedure SetOrientation(const Value: TProgressBarOrientation);
    procedure SetStyle(const Value: TProgressBarStyle);
    procedure SetState(const Value: TProgressBarState);
    procedure SetMarqueeInterval(const Value: Integer);
    procedure SetShowText(const Value: Boolean);
    procedure SetSmooth(const Value: Boolean);
    procedure UpdateMarquee;
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
  protected
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure Loaded; override;
    procedure PositionChanged(OldPosition: Integer); override;
    procedure UpdateVisualState(Animate: Boolean = True); override;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    /// Angezeigte Position (waehrend der Animation zwischen alt und neu).
    function DisplayPosition: Double;
    /// Spur und Fuellung fuer den aktuellen Zustand.
    function GetTrackStyle: TPPGSurfaceStyle;
    function GetFillStyle: TPPGSurfaceStyle;
    /// Fuellung innerhalb der Spur (Marquee: wanderndes Segment).
    function GetFillRect(const Track: TRect): TRect;
    function DisplayText: string;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    /// Smooth = False: Fuellung in Bloecken.
    procedure PaintBlocks(const ACanvas: IPPGCanvas; const Track, Fill: TRect;
      const TrackStyle, FillStyle: TPPGSurfaceStyle);
    function AccRole: Integer; override;
    function AccState: Integer; override;
    function AccValue: string; override;
    function AccDefaultAction: string; override;
    procedure AccDoDefaultAction; override;

    property Orientation: TProgressBarOrientation read FOrientation write SetOrientation default pbHorizontal;
    property Style: TProgressBarStyle read FStyle write SetStyle default pbstNormal;
    property State: TProgressBarState read FState write SetState default pbsNormal;
    /// Farbe des Balkens im Zustand pbsNormal (clDefault = Akzent des Presets; wie TProgressBar).
    property BarColor: TColor read FBarColor write SetBarColor default clDefault;
    /// Farbe der Spur (clDefault = Preset).
    property BackgroundColor: TColor read FBackgroundColor write SetBackgroundColor default clDefault;
    property Step: Integer read FStep write FStep default 10;
    /// Wie TProgressBar: ms je Animationsschritt; ein Durchlauf hat 150 Schritte.
    property MarqueeInterval: Integer read FMarqueeInterval write SetMarqueeInterval default 10;
    /// True: durchgehender Balken; False: Balken aus Bloecken (wie das klassische
    /// TProgressBar). Nicht bei Marquee.
    property Smooth: Boolean read FSmooth write SetSmooth default True;
    /// Zeigt Caption bzw. (ohne Caption) den Fortschritt in Prozent.
    property ShowText: Boolean read FShowText write SetShowText default False;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure StepIt;
    procedure StepBy(Delta: Integer);
    /// Fortschritt in Prozent (0..100, gerundet).
    function Percent: Integer;
    /// True, solange die Marquee-Animation laeuft.
    function MarqueeRunning: Boolean;
  end;

  TPPGProgressBar = class(TPPGCustomProgressBar)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Min default 0;
    property Max default 100;
    property Position default 0;
    property Step;
    property Orientation;
    property Style;
    property State;
    property MarqueeInterval;
    property Smooth;
    property ShowText;
    property HighContrastSupport;
    property OnChange;
    { VCL-Standard }
    property Align;
    property Anchors;
    property BiDiMode;
    property Caption;
    property Color;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property Hint;
    property ParentBackground default True;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop default False;
    property Visible;
    property Touch;
    property OnGesture;
    property OnClick;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseWheel;
    property OnMouseActivate;
    property OnEnter;
    property OnExit;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
    // Audit 5d Stufe 3: wie VCL
    property BarColor;
    property BackgroundColor;
  end;

implementation

uses
  PPG.Lang,
  System.SysUtils, System.Math, Winapi.oleacc, PPG.Consts, PPG.Appearance, PPG.DpiUtils, PPG.Tokens;

const
  MarqueeSteps = 150;        // Schritte je Durchlauf (MarqueeInterval * 150 ms)
  MarqueeSegment = 0.3;      // Segmentlaenge als Anteil der Spur
  PPGMaxMarqueeInterval = 1000;

{ TPPGCustomProgressBar }

constructor TPPGCustomProgressBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 150;
  Height := 16;
  TabStop := False;
  FStep := 10;
  FBarColor := clDefault;
  FBackgroundColor := clDefault;
  FMarqueeInterval := 10;
  FSmooth := True;
  FPosAnim := TPPGAnimation.Create(Self);
  FPosAnim.OnStep := AnimStep;
  FMarqueeAnim := TPPGAnimation.Create(Self);
  FMarqueeAnim.OnStep := AnimStep;
end;

destructor TPPGCustomProgressBar.Destroy;
begin
  if FPosAnim <> nil then
    FPosAnim.OnStep := nil;
  if FMarqueeAnim <> nil then
    FMarqueeAnim.OnStep := nil;
  FreeAndNil(FPosAnim);     // meldet sich selbst beim Animator ab
  FreeAndNil(FMarqueeAnim);
  inherited Destroy;
end;

procedure TPPGCustomProgressBar.AnimStep(Sender: TObject);
begin
  Invalidate;
end;

procedure TPPGCustomProgressBar.CreateWnd;
begin
  inherited CreateWnd;
  UpdateMarquee;
end;

procedure TPPGCustomProgressBar.DestroyWnd;
begin
  if FMarqueeAnim <> nil then
    FMarqueeAnim.Stop; // ohne Fenster nichts zu zeigen
  inherited DestroyWnd;
end;

procedure TPPGCustomProgressBar.Loaded;
begin
  inherited Loaded;
  UpdateMarquee;
end;

procedure TPPGCustomProgressBar.CMShowingChanged(var Message: TMessage);
begin
  inherited;
  UpdateMarquee; // unsichtbar -> keine Animation (CPU, Animator-Timer)
end;

procedure TPPGCustomProgressBar.UpdateVisualState(Animate: Boolean);
begin
  // Kein Hover-/Druckzustand; Aenderungen der Animation-Einstellungen
  // kommen hier an und schalten die Marquee-Animation um.
  UpdateMarquee;
  Invalidate;
end;

function TPPGCustomProgressBar.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGCustomProgressBar.IsDown: Boolean;
begin
  Result := False;
end;

procedure TPPGCustomProgressBar.UpdateMarquee;
var
  Run: Boolean;
begin
  if (FMarqueeAnim = nil) or (csDestroying in ComponentState) then
    Exit;
  Run := (FStyle = pbstMarquee) and HandleAllocated and Showing and
    not (csLoading in ComponentState) and not (csDesigning in ComponentState) and
    Animation.EffectiveEnabled;
  if Run then
    FMarqueeAnim.StartLoop(Cardinal(FMarqueeInterval) * MarqueeSteps)
  else if FMarqueeAnim.Running then
    FMarqueeAnim.Stop;
end;

function TPPGCustomProgressBar.MarqueeRunning: Boolean;
begin
  Result := (FMarqueeAnim <> nil) and FMarqueeAnim.Running;
end;

procedure TPPGCustomProgressBar.SetOrientation(const Value: TProgressBarOrientation);
begin
  if FOrientation <> Value then
  begin
    FOrientation := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomProgressBar.SetStyle(const Value: TProgressBarStyle);
begin
  if FStyle <> Value then
  begin
    FStyle := Value;
    UpdateMarquee;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
  end;
end;

procedure TPPGCustomProgressBar.SetState(const Value: TProgressBarState);
begin
  if FState <> Value then
  begin
    FState := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomProgressBar.SetMarqueeInterval(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'MarqueeInterval', Value, 1, PPGMaxMarqueeInterval);
  if FMarqueeInterval <> V then
  begin
    FMarqueeInterval := V;
    if MarqueeRunning then
      UpdateMarquee; // neue Periode
  end;
end;

procedure TPPGCustomProgressBar.SetShowText(const Value: Boolean);
begin
  if FShowText <> Value then
  begin
    FShowText := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomProgressBar.SetSmooth(const Value: Boolean);
begin
  if FSmooth <> Value then
  begin
    FSmooth := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomProgressBar.StepIt;
begin
  StepBy(FStep);
end;

procedure TPPGCustomProgressBar.StepBy(Delta: Integer);
begin
  SetPositionInternal(Int64(Position) + Delta);
end;

function TPPGCustomProgressBar.Percent: Integer;
begin
  Result := Round(FractionOf(Position) * 100);
end;

procedure TPPGCustomProgressBar.PositionChanged(OldPosition: Integer);
var
  From: Double;
begin
  // Weich gleiten, aber nur wenn man es sieht (wie bei den Auswahl-Controls)
  if (FPosAnim <> nil) and not (csLoading in ComponentState) and
    not (csDesigning in ComponentState) and Animation.EffectiveEnabled and
    HandleAllocated and IsWindowVisible(Handle) then
  begin
    if FPosAnim.Running then
      From := FAnimFrom + (OldPosition - FAnimFrom) * FPosAnim.Value
    else
      From := OldPosition;
    FAnimFrom := From;
    FPosAnim.Jump(0);
    FPosAnim.AnimateTo(1, Animation.Duration);
  end
  else if FPosAnim <> nil then
    FPosAnim.Jump(1);
  inherited PositionChanged(OldPosition);
end;

function TPPGCustomProgressBar.DisplayPosition: Double;
begin
  if (FPosAnim <> nil) and FPosAnim.Running then
    Result := FAnimFrom + (Position - FAnimFrom) * FPosAnim.Value
  else
    Result := Position;
end;

procedure TPPGCustomProgressBar.SetBarColor(const Value: TColor);
begin
  if FBarColor <> Value then
  begin
    FBarColor := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomProgressBar.SetBackgroundColor(const Value: TColor);
begin
  if FBackgroundColor <> Value then
  begin
    FBackgroundColor := Value;
    Invalidate;
  end;
end;

{ ---- Zeichnen ---- }

function TPPGCustomProgressBar.GetTrackStyle: TPPGSurfaceStyle;
begin
  if Enabled then
    Result := EffectiveAppearance.Resolve(vsNormal, ScalePPI, False)
  else
    Result := EffectiveAppearance.Resolve(vsDisabled, ScalePPI, False);
  Result.GlowAlpha := 0;
  if Enabled and PPGColorIsSet(FBackgroundColor) then
  begin
    Result.Color := PPGColorToRGB(FBackgroundColor);
    Result.ColorTo := Result.Color;
    Result.ColorMirror := Result.Color;
    Result.ColorMirrorTo := Result.Color;
  end;
  if UseHighContrast then
  begin
    // Sonderfall: Spur auf Fensterflaeche mit sichtbarem Rahmen (Tokens)
    Result.Color := Tokens.Surface;
    Result.BorderColor := Tokens.Stroke;
    Result.TextColor := Tokens.TextPrimary;
    Result.ColorTo := Result.Color;
    Result.ColorMirror := Result.Color;
    Result.ColorMirrorTo := Result.Color;
    if Result.BorderWidth < 1 then
      Result.BorderWidth := 1;
  end;
end;

procedure TintSurface(var S: TPPGSurfaceStyle; Base, Text: TColor);
begin
  // Glanz-Presets behalten ihren Verlauf (heller oben), flache bleiben flach
  if S.Color <> S.ColorTo then
  begin
    S.Color := PPGLighten(Base, 0.45);
    S.ColorTo := PPGLighten(Base, 0.15);
    S.ColorMirror := Base;
    S.ColorMirrorTo := PPGLighten(Base, 0.25);
  end
  else
  begin
    S.Color := Base;
    S.ColorTo := Base;
    S.ColorMirror := Base;
    S.ColorMirrorTo := Base;
  end;
  S.BorderColor := PPGDarken(Base, 0.2);
  S.GlowColor := Base;
  S.TextColor := Text;
end;

function TPPGCustomProgressBar.GetFillStyle: TPPGSurfaceStyle;
var
  A: TPPGAppearance;
  Bar: TColor;
begin
  A := EffectiveAppearance;
  Result := A.ResolveStyle(A.Checked, ScalePPI, False);
  if not Enabled then
    TintSurface(Result, PPGColorToRGB(A.Disabled.BorderColor),
      PPGColorToRGB(A.Disabled.TextColor))
  else
    case FState of
      pbsError: TintSurface(Result, PPGColorToRGB(Tokens.Danger),
        PPGContrastTextColor(Tokens.Danger, clWhite, $00202020));
      pbsPaused: TintSurface(Result, PPGColorToRGB(Tokens.Paused),
        PPGContrastTextColor(Tokens.Paused, clWhite, $00202020));
    else
      if PPGColorIsSet(FBarColor) then
      begin
        Bar := PPGColorToRGB(FBarColor);
        // Text auf dem Balken (ShowText) in der lesbareren Farbe
        TintSurface(Result, Bar, PPGContrastTextColor(Bar, clWhite, $00202020));
      end;
    end;
  if UseHighContrast then
  begin
    // Sonderfall: Balken einfarbig, auch bei Fehler/Pause (Tokens)
    if Enabled then
      Result.Color := Tokens.Accent
    else
      Result.Color := Tokens.TextDisabled;
    Result.ColorTo := Result.Color;
    Result.ColorMirror := Result.Color;
    Result.ColorMirrorTo := Result.Color;
    Result.BorderColor := Result.Color;
    Result.TextColor := Tokens.OnAccent;
    Result.GlowAlpha := 0;
  end;
end;

function TPPGCustomProgressBar.GetFillRect(const Track: TRect): TRect;
var
  Len, Seg, Start, Fill: Integer;
  Vertical, Reverse: Boolean;
begin
  Result := Track;
  Vertical := FOrientation = pbVertical;
  if Vertical then
    Len := Track.Bottom - Track.Top
  else
    Len := Track.Right - Track.Left;
  if Len <= 0 then
    Exit(Rect(0, 0, 0, 0));
  // Vertikal waechst der Balken von unten nach oben, bei RTL von rechts
  Reverse := Vertical or UseRightToLeftAlignment;

  if FStyle = pbstMarquee then
  begin
    Seg := Round(Len * MarqueeSegment);
    if MarqueeRunning then
      // wandert von "vor der Spur" bis "hinter der Spur"
      Start := Round(-Seg + FMarqueeAnim.Value * (Len + Seg))
    else
      Start := (Len - Seg) div 2; // ohne Animation: steht in der Mitte
    if Reverse then
      Start := Len - Start - Seg;
    if Vertical then
    begin
      Result.Top := Track.Top + Start;
      Result.Bottom := Result.Top + Seg;
    end
    else
    begin
      Result.Left := Track.Left + Start;
      Result.Right := Result.Left + Seg;
    end;
    Exit;
  end;

  Fill := Round(Len * FractionOf(DisplayPosition));
  if Fill <= 0 then
    Exit(Rect(0, 0, 0, 0));
  if Vertical then
    Result.Top := Track.Bottom - Fill
  else if Reverse then
    Result.Left := Track.Right - Fill
  else
    Result.Right := Track.Left + Fill;
end;

function TPPGCustomProgressBar.DisplayText: string;
begin
  if Caption <> '' then
    Result := Caption
  else if FStyle = pbstMarquee then
    Result := ''
  else
    Result := Format(PPGStr(@SPPGPercentFormat), [Percent]);
end;

procedure TPPGCustomProgressBar.PaintBlocks(const ACanvas: IPPGCanvas; const Track, Fill: TRect;
  const TrackStyle, FillStyle: TPPGSurfaceStyle);
var
  Empty, Seg: TRect;
  Thick, BlockW, Gap, P, Last: Integer;
  Vert: Boolean;
begin
  // Erst nur die Spur, dann die Fuellung blockweise ueber Ausschnitte: so passen
  // Form und Farben in jedem Preset
  Empty := Fill;
  Vert := FOrientation = pbVertical;
  if Vert then
    Empty.Top := Empty.Bottom
  else
    Empty.Right := Empty.Left;
  RangeRenderer.DrawProgress(ACanvas, Track, Empty, TrackStyle, FillStyle, ScalePPI);
  if Vert then
    Thick := Fill.Right - Fill.Left
  else
    Thick := Fill.Bottom - Fill.Top;
  BlockW := System.Math.Max(PPGScale(4, ScalePPI), Thick * 2 div 3);
  Gap := System.Math.Max(1, PPGScale(2, ScalePPI));
  if Vert then
  begin
    // von unten nach oben
    P := Fill.Bottom;
    Last := Fill.Top;
    while P > Last do
    begin
      Seg := Rect(Track.Left, System.Math.Max(Last, P - BlockW), Track.Right, P);
      ACanvas.PushClipRoundRect(Seg, 0);
      try
        RangeRenderer.DrawProgress(ACanvas, Track, Fill, TrackStyle, FillStyle, ScalePPI);
      finally
        ACanvas.PopClip;
      end;
      Dec(P, BlockW + Gap);
    end;
  end
  else if UseRightToLeftAlignment then
  begin
    P := Fill.Right;
    Last := Fill.Left;
    while P > Last do
    begin
      Seg := Rect(System.Math.Max(Last, P - BlockW), Track.Top, P, Track.Bottom);
      ACanvas.PushClipRoundRect(Seg, 0);
      try
        RangeRenderer.DrawProgress(ACanvas, Track, Fill, TrackStyle, FillStyle, ScalePPI);
      finally
        ACanvas.PopClip;
      end;
      Dec(P, BlockW + Gap);
    end;
  end
  else
  begin
    P := Fill.Left;
    Last := Fill.Right;
    while P < Last do
    begin
      Seg := Rect(P, Track.Top, System.Math.Min(Last, P + BlockW), Track.Bottom);
      ACanvas.PushClipRoundRect(Seg, 0);
      try
        RangeRenderer.DrawProgress(ACanvas, Track, Fill, TrackStyle, FillStyle, ScalePPI);
      finally
        ACanvas.PopClip;
      end;
      Inc(P, BlockW + Gap);
    end;
  end;
end;

procedure TPPGCustomProgressBar.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  Track, Fill, Rest: TRect;
  TrackStyle, FillStyle: TPPGSurfaceStyle;
  Text: string;
  Flags: Cardinal;
begin
  Track := ClientR;
  TrackStyle := GetTrackStyle;
  FillStyle := GetFillStyle;
  Fill := GetFillRect(Track);
  if FSmooth or (FStyle = pbstMarquee) or IsRectEmpty(Fill) then
    RangeRenderer.DrawProgress(ACanvas, Track, Fill, TrackStyle, FillStyle, ScalePPI)
  else
    PaintBlocks(ACanvas, Track, Fill, TrackStyle, FillStyle);

  if not FShowText or (FOrientation = pbVertical) then
    Exit;
  Text := DisplayText;
  if Text = '' then
    Exit;
  Flags := DrawTextBiDiModeFlags(DT_CENTER or DT_VCENTER or DT_SINGLELINE or
    DT_NOPREFIX or DT_END_ELLIPSIS);
  // Text zweifarbig: auf der Fuellung in deren Textfarbe, sonst in der der Spur
  IntersectRect(Fill, Fill, Track);
  if IsRectEmpty(Fill) then
    ACanvas.DrawText(Track, Text, Font, TrackStyle.TextColor, Flags)
  else
  begin
    ACanvas.PushClipRoundRect(Fill, 0);
    try
      ACanvas.DrawText(Track, Text, Font, FillStyle.TextColor, Flags);
    finally
      ACanvas.PopClip;
    end;
    // Rest = Spur ohne Fuellung (Fuellung haengt immer an einem Ende)
    Rest := Track;
    if Fill.Left > Track.Left then
      Rest.Right := Fill.Left
    else
      Rest.Left := Fill.Right;
    if not IsRectEmpty(Rest) then
    begin
      ACanvas.PushClipRoundRect(Rest, 0);
      try
        ACanvas.DrawText(Track, Text, Font, TrackStyle.TextColor, Flags);
      finally
        ACanvas.PopClip;
      end;
    end;
  end;
end;

{ ---- Barrierefreiheit ---- }

function TPPGCustomProgressBar.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_PROGRESSBAR;
end;

function TPPGCustomProgressBar.AccState: Integer;
begin
  Result := (inherited AccState) or STATE_SYSTEM_READONLY;
  if FStyle = pbstMarquee then
    Result := Result or STATE_SYSTEM_BUSY;
end;

function TPPGCustomProgressBar.AccValue: string;
begin
  if FStyle = pbstMarquee then
    Result := ''
  else
    Result := Format(PPGStr(@SPPGPercentFormat), [Percent]);
end;

function TPPGCustomProgressBar.AccDefaultAction: string;
begin
  Result := ''; // nicht bedienbar
end;

procedure TPPGCustomProgressBar.AccDoDefaultAction;
begin
  // bewusst nichts: ein Fortschrittsbalken hat keine Aktion
end;

end.
