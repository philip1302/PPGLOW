unit PPG.Expander;

{ TPPGExpander - Container mit Kopfzeile, auf- und zuklappbar (Phase 7a).

  - Kopfzeile: Titel (Caption), optional Detailtext darunter, Chevron rechts
    (zeigt zugeklappt nach unten, aufgeklappt nach oben, Drehung animiert).
  - Auf-/Zuklappen animiert die Hoehe zwischen Kopfzeile und ExpandedHeight
    (gemeinsamer Animator, ekDecelerate). Die Kinder bleiben erhalten; im
    zugeklappten Zustand sind sie per Tab nicht erreichbar.
  - Mehrere Expander mit Align = alTop untereinander ergeben ein
    Kategorie-Panel.
  - Code (Expanded := ...) loest keine Ereignisse aus; der Anwender (Klick,
    Enter/Leertaste, Pfeile, Screenreader-Aktion) loest OnExpanding (abbrechbar)
    und danach OnExpanded bzw. OnCollapsed aus. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Controls.Container;

type
  TPPGExpandingEvent = procedure(Sender: TObject; var AllowChange: Boolean) of object;

  TPPGCustomExpander = class(TPPGCustomContainer)
  private
    FExpanded: Boolean;
    FDetail: string;
    FExpandedHeight: Integer;
    FExpandAnim: TPPGAnimation;
    FInternalResize: Boolean;
    FHeaderHot: Boolean;
    FHeaderDown: Boolean;
    FOnExpanding: TPPGExpandingEvent;
    FOnExpanded: TNotifyEvent;
    FOnCollapsed: TNotifyEvent;
    procedure SetExpanded(const Value: Boolean);
    procedure SetDetail(const Value: string);
    procedure SetExpandedHeight(const Value: Integer);
    function GetExpandedHeight: Integer;
    procedure ExpandStep(Sender: TObject);
    procedure ApplyExpansion;
    procedure ChangeExpanded(Value: Boolean);
    function CanAnimate: Boolean;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  protected
    procedure WndProc(var Message: TMessage); override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function ChildOverlapsDecoration(const R: TRect): Boolean; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure DoAccelerator; override;
    function AccRole: Integer; override;
    function AccState: Integer; override;
    function AccDefaultAction: string; override;
    procedure AccDoDefaultAction; override;
    property Expanded: Boolean read FExpanded write SetExpanded default True;
    property Detail: string read FDetail write SetDetail;
    /// Hoehe im aufgeklappten Zustand (0 = aktuelle Hoehe).
    property ExpandedHeight: Integer read GetExpandedHeight write SetExpandedHeight default 0;
    property OnExpanding: TPPGExpandingEvent read FOnExpanding write FOnExpanding;
    property OnExpanded: TNotifyEvent read FOnExpanded write FOnExpanded;
    property OnCollapsed: TNotifyEvent read FOnCollapsed write FOnCollapsed;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure GetTabOrderList(List: TList); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    /// Hoehe der Kopfzeile (Pixel, skaliert).
    function HeaderHeight: Integer;
    function HeaderRect: TRect;
    /// Umschalten wie per Klick (mit Ereignissen). False = abgelehnt.
    function ToggleByUser: Boolean;
    /// Fortschritt des Aufklappens 0 (zu) .. 1 (auf).
    function ExpansionProgress: Single;
    property HeaderHot: Boolean read FHeaderHot;
  end;

  TPPGExpander = class(TPPGCustomExpander)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property HighContrastSupport;
    property Expanded;
    property Detail;
    property ExpandedHeight;
    { VCL-Standard }
    property Align;
    property Anchors;
    property BiDiMode;
    property Caption;
    property Color;
    property Constraints;
    property Enabled;
    property Font;
    property Padding;
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
    property TabStop default True;
    property Visible;
    property OnCollapsed;
    property OnContextPopup;
    property OnEnter;
    property OnExit;
    property OnExpanded;
    property OnExpanding;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
  end;

implementation

uses
  System.SysUtils, System.Math, Winapi.oleacc,
  PPG.Consts, PPG.Appearance, PPG.DpiUtils, PPG.Tokens, PPG.Render.Gdi;

const
  HeaderMin = 48;    // logische px Mindesthoehe der Kopfzeile
  HeaderPadH = 16;
  HeaderPadV = 8;
  ChevronBox = 32;
  ContentPad = 8;

var
  GMsgExpanderAction: Cardinal = 0;

{ TPPGCustomExpander }

constructor TPPGCustomExpander.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csClickEvents, csSetCaption];
  FExpanded := True;
  TabStop := True;
  Width := 300;
  Height := 160;
  FExpandAnim := TPPGAnimation.Create(Self);
  FExpandAnim.Jump(1);
  FExpandAnim.OnStep := ExpandStep;
  if GMsgExpanderAction = 0 then
    GMsgExpanderAction := RegisterWindowMessage('PPGlow.ExpanderAction');
end;

destructor TPPGCustomExpander.Destroy;
begin
  if FExpandAnim <> nil then
    FExpandAnim.OnStep := nil;
  FreeAndNil(FExpandAnim);
  inherited Destroy;
end;

function TPPGCustomExpander.HeaderHeight: Integer;
var
  PPI, H: Integer;
  S: TSize;
begin
  PPI := ScalePPI;
  S := PPGMeasureTextNoCanvas('Wg', Font, 0, False);
  H := S.cy;
  if FDetail <> '' then
    H := H + S.cy;
  H := H + 2 * PPGScale(HeaderPadV, PPI);
  Result := PPGScale(HeaderMin, PPI);
  if H > Result then
    Result := H;
end;

function TPPGCustomExpander.HeaderRect: TRect;
begin
  Result := Rect(0, 0, Width, Min(HeaderHeight, Height));
end;

function TPPGCustomExpander.ExpansionProgress: Single;
begin
  Result := FExpandAnim.Value;
end;

function TPPGCustomExpander.CanAnimate: Boolean;
begin
  Result := HandleAllocated and Showing and not (csLoading in ComponentState) and
    not (csDesigning in ComponentState) and Animation.EffectiveEnabled;
end;

procedure TPPGCustomExpander.ApplyExpansion;
var
  HH, H: Integer;
begin
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  HH := HeaderHeight;
  if FExpandedHeight < HH then
    H := HH
  else
    H := HH + Round((FExpandedHeight - HH) * FExpandAnim.Value);
  if H <> Height then
  begin
    FInternalResize := True;
    try
      Height := H;
    finally
      FInternalResize := False;
    end;
  end;
  Invalidate;
end;

procedure TPPGCustomExpander.ExpandStep(Sender: TObject);
begin
  ApplyExpansion;
end;

procedure TPPGCustomExpander.ChangeExpanded(Value: Boolean);
var
  Target: Single;
begin
  if FExpanded = Value then
    Exit;
  // Beim Zuklappen die aktuelle Hoehe merken (Anwender kann sie geaendert haben)
  if FExpanded and not FExpandAnim.Running and (Height > HeaderHeight) then
    FExpandedHeight := Height;
  FExpanded := Value;
  if not Value and HandleAllocated and ContainsControl(FindControl(GetFocus)) then
    SetFocus; // Fokus nicht in unsichtbaren Kindern lassen
  if Value then
    Target := 1
  else
    Target := 0;
  if CanAnimate then
    FExpandAnim.AnimateTo(Target, Cardinal(Animation.Duration) * 2, ekDecelerate)
  else
  begin
    FExpandAnim.Jump(Target);
    ApplyExpansion;
  end;
  NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
end;

procedure TPPGCustomExpander.SetExpanded(const Value: Boolean);
begin
  if csLoading in ComponentState then
  begin
    FExpanded := Value;
    if Value then
      FExpandAnim.Jump(1)
    else
      FExpandAnim.Jump(0);
    Exit;
  end;
  ChangeExpanded(Value);
end;

function TPPGCustomExpander.ToggleByUser: Boolean;
var
  Allow: Boolean;
begin
  Result := False;
  if not Enabled then
    Exit;
  Allow := True;
  if Assigned(FOnExpanding) then
    FOnExpanding(Self, Allow);
  if not Allow then
    Exit;
  ChangeExpanded(not FExpanded);
  Result := True;
  if FExpanded then
  begin
    if Assigned(FOnExpanded) then
      FOnExpanded(Self);
  end
  else if Assigned(FOnCollapsed) then
    FOnCollapsed(Self);
end;

procedure TPPGCustomExpander.SetDetail(const Value: string);
begin
  if FDetail <> Value then
  begin
    FDetail := Value;
    LayoutChanged;
    if not FExpanded then
      ApplyExpansion;
  end;
end;

procedure TPPGCustomExpander.SetExpandedHeight(const Value: Integer);
begin
  FExpandedHeight := PPGCheckRange(Self, 'ExpandedHeight', Value, 0, 100000);
  if (csLoading in ComponentState) then
    Exit;
  if FExpanded and not FExpandAnim.Running and (FExpandedHeight > 0) then
    ApplyExpansion;
end;

function TPPGCustomExpander.GetExpandedHeight: Integer;
begin
  if FExpandedHeight > 0 then
    Result := FExpandedHeight
  else if FExpanded then
    Result := Height
  else
    Result := 0;
end;

procedure TPPGCustomExpander.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  // Auch ohne Fensterhandle (dann kommt kein Resize): Groesse von aussen im
  // aufgeklappten Zustand = neue aufgeklappte Hoehe
  if (FExpandAnim <> nil) and not FInternalResize and FExpanded and not FExpandAnim.Running and
    not (csLoading in ComponentState) then
    FExpandedHeight := Height;
end;

procedure TPPGCustomExpander.Loaded;
begin
  inherited Loaded;
  if FExpandedHeight = 0 then
    FExpandedHeight := Height;
  ApplyExpansion;
end;

procedure TPPGCustomExpander.Resize;
begin
  inherited Resize;
  // Groessenaenderung von aussen (Designer, Anker, Code) im aufgeklappten
  // Zustand wird die neue aufgeklappte Hoehe
  if not FInternalResize and FExpanded and not FExpandAnim.Running and
    not (csLoading in ComponentState) then
    FExpandedHeight := Height;
end;

procedure TPPGCustomExpander.CMFontChanged(var Message: TMessage);
begin
  inherited;
  if not FExpanded then
    ApplyExpansion;
end;

procedure TPPGCustomExpander.CMTextChanged(var Message: TMessage);
begin
  inherited;
  NotifyAccessibility(EVENT_OBJECT_NAMECHANGE);
end;

procedure TPPGCustomExpander.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TPPGCustomExpander.AdjustClientRect(var Rect: TRect);
var
  Inset, Pad: Integer;
begin
  inherited AdjustClientRect(Rect);
  Inset := ContentInset;
  Pad := PPGScale(ContentPad, ScalePPI);
  // Kinder liegen unter der Kopfzeile; beim Zuklappen schneidet die Hoehe sie ab
  // (inherited hat Padding schon abgezogen; oben/unten gilt es zusaetzlich)
  Rect.Top := HeaderHeight + Pad + Padding.Top;
  Inc(Rect.Left, Inset + Pad);
  Dec(Rect.Right, Inset + Pad);
  // Unten an der aufgeklappten Hoehe ausrichten, damit Kinder beim
  // Animieren nicht mitwandern
  if (FExpandedHeight > 0) and (FInternalResize or FExpandAnim.Running or not FExpanded) then
    Rect.Bottom := FExpandedHeight - Inset - Pad - Padding.Bottom
  else
    Dec(Rect.Bottom, Inset + Pad);
  if Rect.Bottom < Rect.Top then
    Rect.Bottom := Rect.Top;
end;

procedure TPPGCustomExpander.GetTabOrderList(List: TList);
begin
  // Zugeklappt: Kinder nicht per Tab erreichbar
  if FExpanded then
    inherited GetTabOrderList(List);
end;

function TPPGCustomExpander.ChildOverlapsDecoration(const R: TRect): Boolean;
begin
  Result := R.Top < HeaderHeight;
end;

procedure TPPGCustomExpander.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  Style: TPPGSurfaceStyle;
  HR, TR, DR, CR: TRect;
  PPI, HH, CX, CY, Half, Quarter, W, Dir: Integer;
  TextCol, DetailCol, LineCol: TColor;
  S: TSize;
  Flags: Cardinal;
  Pts: array[0..2] of TPoint;
  P: Single;
  HC: Boolean;
begin
  PPI := ScalePPI;
  HC := HighContrastSupport and PPGIsHighContrast;
  Style := GetContainerStyle(False);
  ContainerRenderer.DrawContainer(ACanvas, ClientR, Style);
  HH := HeaderHeight;
  HR := Rect(ClientR.Left, ClientR.Top, ClientR.Right, Min(ClientR.Top + HH, ClientR.Bottom));
  TextCol := Style.TextColor;
  if HC then
    DetailCol := TextCol
  else if Enabled then
    DetailCol := PPGBlendColor(TextCol, Style.Color, 0.35)
  else
    DetailCol := TextCol;
  // Hover/Druck auf der Kopfzeile
  if Enabled and (FHeaderHot or FHeaderDown) then
  begin
    TR := HR;
    InflateRect(TR, -Style.BorderWidth - 1, -Style.BorderWidth - 1);
    if FHeaderDown then
      ACanvas.FillRoundRect(TR, Max(0, Style.Rounding - Style.BorderWidth), TextCol, 20)
    else
      ACanvas.FillRoundRect(TR, Max(0, Style.Rounding - Style.BorderWidth), TextCol, 12);
  end;
  // Trennlinie zwischen Kopf und Inhalt, sobald Inhalt sichtbar ist
  if ClientR.Bottom > HR.Bottom + 1 then
  begin
    LineCol := Style.BorderColor;
    if Style.BorderWidth = 0 then
      LineCol := PPGBlendColor(Style.Color, TextCol, 0.15);
    ACanvas.FillRoundRect(Rect(HR.Left + Style.BorderWidth, HR.Bottom - 1,
      HR.Right - Style.BorderWidth, HR.Bottom), 0, LineCol, 255);
  end;
  // Chevron
  if UseRightToLeftAlignment then
    CR := Rect(HR.Left + PPGScale(8, PPI), HR.Top, HR.Left + PPGScale(8 + ChevronBox, PPI), HR.Bottom)
  else
    CR := Rect(HR.Right - PPGScale(8 + ChevronBox, PPI), HR.Top, HR.Right - PPGScale(8, PPI), HR.Bottom);
  CX := (CR.Left + CR.Right) div 2;
  CY := (CR.Top + CR.Bottom) div 2;
  Half := PPGScale(5, PPI);
  Quarter := Round(Half * 0.55);
  // P = 0: Spitze unten, P = 1: Spitze oben (dazwischen flach)
  P := FExpandAnim.Value;
  Dir := Round(Quarter * (1 - 2 * P));
  Pts[0] := Point(CX - Half, CY - Dir);
  Pts[1] := Point(CX, CY + Dir);
  Pts[2] := Point(CX + Half, CY - Dir);
  W := Round(1.5 * PPI / 96);
  if W < 1 then
    W := 1;
  ACanvas.DrawPolyline(Pts, W, TextCol, 255);
  // Titel und Detail
  TR := HR;
  TR.Left := HR.Left + PPGScale(HeaderPadH, PPI);
  TR.Right := HR.Right - PPGScale(HeaderPadH, PPI);
  if UseRightToLeftAlignment then
    TR.Left := CR.Right + PPGScale(4, PPI)
  else
    TR.Right := CR.Left - PPGScale(4, PPI);
  Flags := DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOCLIP;
  if not AcceleratorCuesVisible then
    Flags := Flags or DT_HIDEPREFIX;
  if FDetail = '' then
    ACanvas.DrawText(TR, Caption, Font, TextCol, DrawTextBiDiModeFlags(Flags or DT_VCENTER))
  else
  begin
    S := PPGMeasureTextNoCanvas('Wg', Font, 0, False);
    DR := TR;
    TR.Top := (HR.Top + HR.Bottom) div 2 - S.cy;
    TR.Bottom := TR.Top + S.cy;
    DR.Top := TR.Bottom;
    DR.Bottom := DR.Top + S.cy;
    ACanvas.DrawText(TR, Caption, Font, TextCol, DrawTextBiDiModeFlags(Flags));
    ACanvas.DrawText(DR, FDetail, Font, DetailCol,
      DrawTextBiDiModeFlags(DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX));
  end;
  if FocusVisible and Focused then
  begin
    TR := HR;
    InflateRect(TR, -PPGScale(3, PPI), -PPGScale(3, PPI));
    ACanvas.FrameRoundRect(TR, Max(0, Style.Rounding - PPGScale(2, PPI)), PPGScale(2, PPI),
      PPGColorToRGB(EffectiveAppearance.FocusColor), 255);
  end;
end;

procedure TPPGCustomExpander.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and (Y < HeaderHeight) then
  begin
    FHeaderDown := True;
    if TabStop and CanFocus and IsWindowVisible(Handle) then
      SetFocus;
    Invalidate;
  end;
end;

procedure TPPGCustomExpander.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Hot: Boolean;
begin
  inherited MouseMove(Shift, X, Y);
  Hot := (Y >= 0) and (Y < HeaderHeight) and (X >= 0) and (X < Width);
  if Hot <> FHeaderHot then
  begin
    FHeaderHot := Hot;
    Invalidate;
  end;
end;

procedure TPPGCustomExpander.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  WasDown: Boolean;
begin
  WasDown := FHeaderDown;
  FHeaderDown := False;
  if WasDown then
    Invalidate;
  inherited MouseUp(Button, Shift, X, Y);
  if (Button = mbLeft) and WasDown and (Y >= 0) and (Y < HeaderHeight) and (X >= 0) and
    (X < Width) then
    ToggleByUser;
end;

procedure TPPGCustomExpander.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHeaderHot then
  begin
    FHeaderHot := False;
    Invalidate;
  end;
end;

procedure TPPGCustomExpander.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TPPGCustomExpander.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  case Key of
    VK_SPACE, VK_RETURN:
      begin
        ToggleByUser;
        Key := 0;
      end;
    VK_LEFT, VK_RIGHT:
      begin
        // Wie im Baum: Rechts klappt auf, Links zu (RTL gespiegelt)
        if (Key = VK_RIGHT) <> UseRightToLeftAlignment then
        begin
          if not FExpanded then
            ToggleByUser;
        end
        else if FExpanded then
          ToggleByUser;
        Key := 0;
      end;
  end;
end;

procedure TPPGCustomExpander.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TPPGCustomExpander.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

procedure TPPGCustomExpander.DoAccelerator;
begin
  // Accelerator schaltet um (wie ein Klick auf die Kopfzeile)
  if CanFocus then
    SetFocus;
  ToggleByUser;
end;

procedure TPPGCustomExpander.WndProc(var Message: TMessage);
begin
  if (GMsgExpanderAction <> 0) and (Message.Msg = GMsgExpanderAction) then
  begin
    ToggleByUser;
    Exit;
  end;
  inherited WndProc(Message);
end;

function TPPGCustomExpander.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_GROUPING;
end;

function TPPGCustomExpander.AccState: Integer;
begin
  Result := inherited AccState;
  if FExpanded then
    Result := Result or STATE_SYSTEM_EXPANDED
  else
    Result := Result or STATE_SYSTEM_COLLAPSED;
end;

function TPPGCustomExpander.AccDefaultAction: string;
begin
  if FExpanded then
    Result := SPPGAccCollapse
  else
    Result := SPPGAccExpand;
end;

procedure TPPGCustomExpander.AccDoDefaultAction;
begin
  if HandleAllocated then
    PostMessage(Handle, GMsgExpanderAction, 0, 0);
end;

end.
