unit PPG.Controls.Check;

{ TPPGCustomCheckControl - gemeinsame Basis fuer CheckBox, RadioButton und
  ToggleSwitch: Zustand (an/aus/unbestimmt), animierte Umschaltung, Layout
  Indikator + Beschriftung, Action-Anbindung.

  Ereignis-Semantik (bewusst anders als die VCL-TCheckBox):
  - OnChange : bei JEDER Zustandsaenderung (Benutzer oder Code), nicht beim Laden
  - OnClick  : NUR bei Bedienung durch den Benutzer (Maus, Leertaste,
               Accelerator) bzw. bei explizitem Aufruf von Click.
  Grund: In der VCL loest "CheckBox.Checked := True" im Code OnClick aus -
  eine bekannte Fehlerquelle (Rekursion, ungewollte Seiteneffekte beim
  Initialisieren eines Formulars).

  Zustand wird IMMER vor dem Anwender-Code gesetzt: wirft OnChange/OnClick,
  bleibt das Control konsistent. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.ActnList, Vcl.StdCtrls,
  PPG.Types, PPG.Appearance, PPG.Animation, PPG.Render.Intf, PPG.Controls.Base;

type
  TPPGCustomCheckControl = class;

  TPPGCheckActionLink = class(TWinControlActionLink)
  protected
    FClient: TPPGCustomCheckControl;
    procedure AssignClient(AClient: TObject); override;
    function IsCheckedLinked: Boolean; override;
    procedure SetChecked(Value: Boolean); override;
  end;

  TPPGCustomCheckControl = class(TPPGCustomControl)
  private
    FState: TPPGCheckState;
    FAllowGrayed: Boolean;
    FAlignment: TLeftRight;
    FCheckAnim: TPPGAnimation;
    FOnChange: TNotifyEvent;
    procedure CheckAnimStep(Sender: TObject);
    function GetChecked: Boolean;
    procedure SetChecked(const Value: Boolean);
    procedure SetState(const Value: TPPGCheckState);
    procedure SetAlignment(const Value: TLeftRight);
    function StateTarget(Value: TPPGCheckState): Single;
    function IsCheckedStored: Boolean;
  protected
    procedure Loaded; override;
    procedure DoAccelerator; override;
    function GetActionLinkClass: TControlActionLinkClass; override;
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean); override;

    { Zustand }
    /// Benutzer-Umschaltung (Klick/Leertaste). CheckBox: aus->an(->unbestimmt);
    /// RadioButton ueberschreibt (nur einschalten).
    procedure Toggle; virtual;
    /// Zentrale Zustandsaenderung. Animate=False springt sofort.
    procedure SetStateInternal(Value: TPPGCheckState; Animate: Boolean);
    /// Hook nach jeder Zustandsaenderung (RadioButton: Gruppe exklusiv halten).
    procedure StateChanged; virtual;
    procedure DoChange; virtual;
    function CheckProgress: Single;

    { Barrierefreiheit }
    function AccRole: Integer; override;
    function AccState: Integer; override;
    function AccDefaultAction: string; override;

    { Zeichnen }
    /// Groesse des Indikators in logischen 96-DPI-Pixeln.
    function CalcAutoSize(out AWidth, AHeight: Integer): Boolean; override;
    function GetIndicatorSize: TSize; virtual;
    function GetIndicatorStyle: TPPGSurfaceStyle; virtual;
    function GetIndicatorRenderer: IPPGIndicatorRenderer;
    procedure DrawIndicator(const ACanvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; const IR: IPPGIndicatorRenderer); virtual; abstract;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;

    property State: TPPGCheckState read FState write SetState default cbUnchecked;
    property Checked: Boolean read GetChecked write SetChecked stored IsCheckedStored default False;
    property AllowGrayed: Boolean read FAllowGrayed write FAllowGrayed default False;
    property Alignment: TLeftRight read FAlignment write SetAlignment default taRightJustify;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Simuliert einen Benutzerklick: umschalten (OnChange), dann OnClick/Action.
    procedure Click; override;
  end;

implementation

uses
  PPG.Lang,
  System.SysUtils, Winapi.oleacc, PPG.Consts, PPG.DpiUtils, PPG.Render.Registry,
  PPG.Render.Gdi, PPG.VclStyles;

const
  IndicatorMargin = 4; // logische px Platz fuer Glow um den Indikator

{ TPPGCheckActionLink }

procedure TPPGCheckActionLink.AssignClient(AClient: TObject);
begin
  inherited AssignClient(AClient);
  FClient := AClient as TPPGCustomCheckControl;
end;

function TPPGCheckActionLink.IsCheckedLinked: Boolean;
begin
  Result := inherited IsCheckedLinked and
    (FClient.Checked = (Action as TCustomAction).Checked);
end;

procedure TPPGCheckActionLink.SetChecked(Value: Boolean);
begin
  if IsCheckedLinked then
    FClient.Checked := Value;
end;

{ TPPGCustomCheckControl }

constructor TPPGCustomCheckControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csDoubleClicks];
  TabStop := True;
  Width := 140;
  Height := 24;
  FAlignment := taRightJustify;
  FCheckAnim := TPPGAnimation.Create(Self);
  FCheckAnim.OnStep := CheckAnimStep;
end;

destructor TPPGCustomCheckControl.Destroy;
begin
  if FCheckAnim <> nil then
    FCheckAnim.OnStep := nil;
  FreeAndNil(FCheckAnim);
  inherited Destroy;
end;

procedure TPPGCustomCheckControl.Loaded;
begin
  inherited Loaded;
  if FCheckAnim <> nil then
    FCheckAnim.Jump(StateTarget(FState));
end;

procedure TPPGCustomCheckControl.CheckAnimStep(Sender: TObject);
begin
  Invalidate;
end;

function TPPGCustomCheckControl.CheckProgress: Single;
begin
  if FCheckAnim = nil then
    Result := 0
  else
    Result := FCheckAnim.Value;
end;

function TPPGCustomCheckControl.StateTarget(Value: TPPGCheckState): Single;
begin
  if Value = cbChecked then
    Result := 1
  else
    Result := 0;
end;

function TPPGCustomCheckControl.GetChecked: Boolean;
begin
  Result := FState = cbChecked;
end;

procedure TPPGCustomCheckControl.SetChecked(const Value: Boolean);
begin
  if Value then
    SetStateInternal(cbChecked, True)
  else
    SetStateInternal(cbUnchecked, True);
end;

procedure TPPGCustomCheckControl.SetState(const Value: TPPGCheckState);
begin
  SetStateInternal(Value, True);
end;

function TPPGCustomCheckControl.IsCheckedStored: Boolean;
begin
  Result := Checked and ((ActionLink = nil) or
    not TPPGCheckActionLink(ActionLink).IsCheckedLinked);
end;

procedure TPPGCustomCheckControl.SetStateInternal(Value: TPPGCheckState; Animate: Boolean);
var
  Duration: Cardinal;
begin
  if FState = Value then
    Exit;
  FState := Value;
  // Nur animieren, wenn man es auch sieht: beim Aufbau eines Formulars
  // (Control noch unsichtbar) wuerde sonst jedes Control "einblenden".
  if Animate and not (csLoading in ComponentState) and
    not (csDesigning in ComponentState) and Animation.EffectiveEnabled and
    HandleAllocated and IsWindowVisible(Handle) then
    Duration := Animation.Duration
  else
    Duration := 0;
  if FCheckAnim <> nil then
    FCheckAnim.AnimateTo(StateTarget(Value), Duration);
  StateChanged;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
  if not (csLoading in ComponentState) then
    DoChange;
end;

procedure TPPGCustomCheckControl.StateChanged;
begin
end;

procedure TPPGCustomCheckControl.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGCustomCheckControl.Toggle;
begin
  case FState of
    cbUnchecked:
      if FAllowGrayed then
        SetStateInternal(cbGrayed, True)
      else
        SetStateInternal(cbChecked, True);
    cbChecked:
      SetStateInternal(cbUnchecked, True);
    cbGrayed:
      SetStateInternal(cbChecked, True);
  end;
end;

procedure TPPGCustomCheckControl.Click;
begin
  // Erst umschalten (inkl. OnChange), dann OnClick bzw. Action.Execute
  Toggle;
  inherited Click;
end;

procedure TPPGCustomCheckControl.DoAccelerator;
begin
  if TabStop and CanFocus and not Focused and HandleAllocated and
    IsWindowVisible(Handle) then
    SetFocus;
  Click;
end;

procedure TPPGCustomCheckControl.SetAlignment(const Value: TLeftRight);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    Invalidate;
  end;
end;

function TPPGCustomCheckControl.GetActionLinkClass: TControlActionLinkClass;
begin
  Result := TPPGCheckActionLink;
end;

procedure TPPGCustomCheckControl.ActionChange(Sender: TObject; CheckDefaults: Boolean);
begin
  inherited ActionChange(Sender, CheckDefaults);
  if Sender is TCustomAction then
    if not CheckDefaults or not Checked then
      Checked := TCustomAction(Sender).Checked;
end;

{ ---- Barrierefreiheit ---- }

function TPPGCustomCheckControl.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_CHECKBUTTON;
end;

function TPPGCustomCheckControl.AccState: Integer;
begin
  // "gedrueckt" ist bei Auswahl-Controls kein sinnvoller Zustand
  Result := inherited AccState and not STATE_SYSTEM_PRESSED;
  case FState of
    cbChecked: Result := Result or STATE_SYSTEM_CHECKED;
    cbGrayed: Result := Result or STATE_SYSTEM_MIXED;
  end;
end;

function TPPGCustomCheckControl.AccDefaultAction: string;
begin
  if Checked then
    Result := PPGStr(@SPPGAccUncheck)
  else
    Result := PPGStr(@SPPGAccCheck);
end;

{ ---- Zeichnen ---- }

function TPPGCustomCheckControl.CalcAutoSize(out AWidth, AHeight: Integer): Boolean;
var
  PPI, Margin, Gap, MaxTextW: Integer;
  Ind, TS: TSize;
begin
  PPI := ScalePPI;
  Ind := GetIndicatorSize;
  Ind.cx := PPGScale(Ind.cx, PPI);
  Ind.cy := PPGScale(Ind.cy, PPI);
  Margin := PPGScale(IndicatorMargin, PPI);
  Gap := PPGScale(Spacing, PPI);
  TS.cx := 0;
  TS.cy := 0;
  if Caption <> '' then
  begin
    MaxTextW := 0;
    if WordWrap then
    begin
      MaxTextW := Width - (2 * Margin + Ind.cx + Gap);
      if MaxTextW < 1 then
        MaxTextW := 1;
    end;
    TS := PPGMeasureTextNoCanvas(Caption, Font, MaxTextW, WordWrap);
  end;
  if WordWrap then
    AWidth := Width
  else if TS.cx > 0 then
    AWidth := 2 * Margin + Ind.cx + Gap + TS.cx + PPGScale(2, PPI)
  else
    AWidth := 2 * Margin + Ind.cx;
  AHeight := Ind.cy + 2 * Margin;
  if TS.cy + PPGScale(4, PPI) > AHeight then
    AHeight := TS.cy + PPGScale(4, PPI);
  Result := True;
end;

function TPPGCustomCheckControl.GetIndicatorSize: TSize;
begin
  Result.cx := 16;
  Result.cy := 16;
end;

function TPPGCustomCheckControl.GetIndicatorRenderer: IPPGIndicatorRenderer;
begin
  // Presets ohne eigene Indikator-Darstellung -> Standard-Preset verwenden
  if not Supports(Renderer, IPPGIndicatorRenderer, Result) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
      IPPGIndicatorRenderer, Result);
end;

function TPPGCustomCheckControl.GetIndicatorStyle: TPPGSurfaceStyle;
var
  PPI: Integer;
  U, H, C: TPPGSurfaceStyle;
  Focus: Boolean;
begin
  PPI := ScalePPI;
  Focus := FocusVisible;
  if not Enabled then
  begin
    Result := EffectiveAppearance.Resolve(vsDisabled, PPI, False);
    if FState <> cbUnchecked then
      Result.TextColor := PPGColorToRGB(EffectiveAppearance.Disabled.TextColor);
  end
  else
  begin
    // "Aus"-Stil: Normal -> Hot -> Down
    H := EffectiveAppearance.Resolve(vsHot, PPI, False);
    U := PPGBlendSurface(EffectiveAppearance.Resolve(vsNormal, PPI, False), H, HotProgress);
    U := PPGBlendSurface(U, EffectiveAppearance.Resolve(vsDown, PPI, False), DownProgress);
    // "An"-Stil, beim Hover mit Glow
    C := EffectiveAppearance.ResolveStyle(EffectiveAppearance.Checked, PPI, False);
    if Round(H.GlowAlpha * HotProgress) > C.GlowAlpha then
    begin
      C.GlowAlpha := Round(H.GlowAlpha * HotProgress);
      C.GlowColor := H.GlowColor;
    end;
    // Presets ohne Glow und ohne eigene Hover-Randfarbe (Fluent11): Hover sonst
    // unsichtbar - Rand kraeftiger, angehakte Flaeche etwas heller
    if (H.GlowAlpha = 0) and (HotProgress > 0) then
    begin
      if U.BorderColor = EffectiveAppearance.Resolve(vsNormal, PPI, False).BorderColor then
        U.BorderColor := PPGBlendColor(U.BorderColor, U.TextColor, 0.35 * HotProgress);
      U.Color := PPGBlendColor(U.Color, U.TextColor, 0.07 * HotProgress);
      U.ColorTo := U.Color;
      U.ColorMirror := U.Color;
      U.ColorMirrorTo := U.Color;
      C.Color := PPGBlendColor(C.Color, H.Color, 0.18 * HotProgress);
      C.ColorTo := C.Color;
      C.ColorMirror := C.Color;
      C.ColorMirrorTo := C.Color;
    end;
    if FState = cbGrayed then
    begin
      Result := U;
      Result.TextColor := C.BorderColor; // kraeftige "An"-Farbe (Fuellung kann sehr hell sein)
    end
    else
      Result := PPGBlendSurface(U, C, CheckProgress);
  end;
  if Focus then
  begin
    Result.Focused := True;
    Result.BorderColor := PPGColorToRGB(EffectiveAppearance.FocusColor);
  end;

  if HighContrastSupport and PPGIsHighContrast then
  begin
    Result.GlowAlpha := 0;
    Result.Color := PPGColorToRGB(clWindow);
    Result.ColorTo := Result.Color;
    Result.ColorMirror := Result.Color;
    Result.ColorMirrorTo := Result.Color;
    if not Enabled then
    begin
      Result.BorderColor := PPGColorToRGB(clGrayText);
      Result.TextColor := PPGColorToRGB(clGrayText);
    end
    else
    begin
      Result.TextColor := PPGColorToRGB(clWindowText);
      if Focus or (HotProgress > 0.5) then
        Result.BorderColor := PPGColorToRGB(clHighlight)
      else
        Result.BorderColor := PPGColorToRGB(clWindowText);
    end;
  end;
end;

procedure TPPGCustomCheckControl.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  PPI, Margin, Gap, TextLeft, TextRight, H: Integer;
  Ind: TSize;
  IndRect, TextRect: TRect;
  Style: TPPGSurfaceStyle;
  CaptionLeft: Boolean;
  Text: string;
  TextColor: TColor;
  Flags: Cardinal;
  TextSize: TSize;
begin
  PPI := ScalePPI;
  Ind := GetIndicatorSize;
  Ind.cx := PPGScale(Ind.cx, PPI);
  Ind.cy := PPGScale(Ind.cy, PPI);
  Margin := PPGScale(IndicatorMargin, PPI);
  Gap := PPGScale(Spacing, PPI);
  H := ClientR.Bottom - ClientR.Top;

  // Beschriftung links, wenn Alignment=taLeftJustify; bei RTL gespiegelt
  CaptionLeft := (FAlignment = taLeftJustify) xor UseRightToLeftAlignment;
  IndRect.Top := ClientR.Top + (H - Ind.cy) div 2;
  IndRect.Bottom := IndRect.Top + Ind.cy;
  if CaptionLeft then
  begin
    IndRect.Right := ClientR.Right - Margin;
    IndRect.Left := IndRect.Right - Ind.cx;
    TextLeft := ClientR.Left;
    TextRight := IndRect.Left - Margin - Gap;
  end
  else
  begin
    IndRect.Left := ClientR.Left + Margin;
    IndRect.Right := IndRect.Left + Ind.cx;
    TextLeft := IndRect.Right + Margin + Gap;
    TextRight := ClientR.Right;
  end;

  Style := GetIndicatorStyle;
  if Style.GlowSize > Margin then
    Style.GlowSize := Margin;
  DrawIndicator(ACanvas, IndRect, Style, GetIndicatorRenderer);

  Text := Caption;
  if (Text = '') or (TextRight <= TextLeft) then
    Exit;
  if UseVclStyle then
    TextColor := PPGVclStyleCheckTextColor(Enabled) // Text steht auf dem Formular, nicht auf dem Button
  else if Enabled then
    TextColor := EffectiveAppearance.Normal.TextColor // im Dark Mode hell
  else
    TextColor := EffectiveAppearance.Disabled.TextColor;
  if HighContrastSupport and PPGIsHighContrast then
    if Enabled then
      TextColor := clWindowText
    else
      TextColor := clGrayText;

  Flags := DT_LEFT or DT_NOCLIP or DT_END_ELLIPSIS;
  if WordWrap then
    Flags := Flags or DT_WORDBREAK
  else
    Flags := Flags or DT_SINGLELINE or DT_VCENTER;
  if not AcceleratorCuesVisible then
    Flags := Flags or DT_HIDEPREFIX;
  Flags := DrawTextBiDiModeFlags(Flags);

  TextRect := Rect(TextLeft, ClientR.Top, TextRight, ClientR.Bottom);
  if WordWrap then
  begin
    // Mehrzeilig vertikal zentrieren (DT_VCENTER wirkt nur einzeilig)
    TextSize := ACanvas.MeasureText(Text, Font, TextRight - TextLeft, True);
    if TextSize.cy < H then
    begin
      TextRect.Top := ClientR.Top + (H - TextSize.cy) div 2;
      TextRect.Bottom := TextRect.Top + TextSize.cy;
    end;
  end;
  ACanvas.DrawText(TextRect, Text, Font, PPGColorToRGB(TextColor), Flags);
end;

end.
