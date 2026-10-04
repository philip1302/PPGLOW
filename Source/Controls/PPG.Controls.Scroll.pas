unit PPG.Controls.Scroll;

{ TPPGCustomScrollControl - Basis aller scrollenden Controls (ListBox, Baum,
  Grid, ...). Der Inhalt wird gezeichnet, nicht aus Kind-Controls gebaut.

  - Inhaltsgroesse (SetContentSize) und Lage (ScrollX/ScrollY) in Pixeln.
    Nachfahren zeichnen in PaintViewport und verschieben dabei um ScrollX/Y.
  - Eigene Overlay-Scrollleisten (Fluent): ruhend schmal, beim Ueberfahren
    breit mit Spur, im Auto-Modus nach kurzer Ruhe ausgeblendet. Daumen
    ziehen, Klick in die Spur blaettert. Keine nativen WS_VSCROLL-Leisten
    (die faerbt der VCL-Style anders, und sie lassen sich nicht ueberlagern).
  - ScrollBarMode: sbmAuto (Overlay, folgt der Windows-Einstellung
    "Bildlaufleisten immer anzeigen" - dann wie sbmAlways), sbmAlways (breit,
    Inhalt wird um die Leistenbreite schmaler), sbmNever.
  - Weiches Scrollen ueber den gemeinsamen Animator. Mausrad mit Rest:
    hochaufloesende Touchpad-Deltas (< 120) scrollen anteilig und ohne
    Animation. Umschalt+Rad und WM_MOUSEHWHEEL scrollen waagerecht.
  - Auto-Scroll, wenn beim Ziehen die Maus den sichtbaren Bereich verlaesst.
  - RTL: senkrechte Leiste links.
  - Paint sendet keine Nachrichten (Systemwerte werden ausserhalb gelesen). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Controls.Base;

type
  TPPGScrollBarMode = (sbmAuto, sbmAlways, sbmNever);
  TPPGScrollAxis = (saHorz, saVert);

  TPPGCustomScrollControl = class(TPPGCustomControl)
  private
    FContent: array[TPPGScrollAxis] of Integer;
    FPos: array[TPPGScrollAxis] of Integer;
    FStart: array[TPPGScrollAxis] of Integer;
    FTarget: array[TPPGScrollAxis] of Integer;
    FWheelRest: array[TPPGScrollAxis] of Integer;
    FExpandAnim: array[TPPGScrollAxis] of TPPGAnimation;
    FScrollAnim: TPPGAnimation;
    FFadeAnim: TPPGAnimation;
    FHoldAnim: TPPGAnimation;
    FAutoAnim: TPPGAnimation;
    FLastActivity: Cardinal;
    FAutoPoint: TPoint;
    FAutoTick: Cardinal;
    FAutoScrolling: Boolean;
    FHotAxis: Integer;   // -1 = keine Leiste unter der Maus
    FHotThumb: Boolean;
    FDragAxis: Integer;  // -1 = kein Daumen gezogen
    FDragOffset: Integer;
    FBarMouse: Boolean;  // laufende Mausaktion gehoert einer Leiste
    FScrollBarMode: TPPGScrollBarMode;
    FSystemAlways: Boolean;
    FSmoothScrolling: Boolean;
    FKeyboardScrolling: Boolean;
    FOnScroll: TNotifyEvent;
    procedure ScrollAnimStep(Sender: TObject);
    procedure BarAnimStep(Sender: TObject);
    procedure HoldStep(Sender: TObject);
    procedure AutoStep(Sender: TObject);
    procedure SetScrollBarMode(const Value: TPPGScrollBarMode);
    function GetScrollX: Integer;
    function GetScrollY: Integer;
    function GetContentWidth: Integer;
    function GetContentHeight: Integer;
    procedure SetScrollX(const Value: Integer);
    procedure SetScrollY(const Value: Integer);
    procedure SetPosition(X, Y: Integer);
    procedure ReadSystemSettings;
    procedure Activity;
    procedure SetHotAxis(Axis: Integer; OnThumb: Boolean);
    function AxisAt(X, Y: Integer): Integer;
    function BarThickness: Integer;
    procedure NeedBars(out NeedH, NeedV: Boolean);
    function WheelScroll(Axis: TPPGScrollAxis; Delta, Lines, Step: Integer): Boolean;
    procedure WMMouseHWheel(var Message: TMessage); message WM_MOUSEHWHEEL;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMWinIniChange(var Message: TMessage); message CM_WININICHANGE;
  protected
    procedure Resize; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    function IsDown: Boolean; override;
    function AccRole: Integer; override;

    { Erweiterungspunkte }
    /// Inhalt zeichnen; View = sichtbarer Bereich (Client-Koordinaten, bereits
    /// als Clip gesetzt). Inhaltskoordinate (cx, cy) liegt bei
    /// (View.Left + cx - ScrollX, View.Top + cy - ScrollY).
    procedure PaintViewport(const ACanvas: IPPGCanvas; const View: TRect); virtual;
    /// Maus im Inhalt (nicht auf einer Leiste). Koordinaten = Client.
    procedure ContentMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;
    procedure ContentMouseMove(Shift: TShiftState; X, Y: Integer); virtual;
    procedure ContentMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;
    /// Schrittweite fuer Mausrad/Pfeiltasten (Standard: 20 logische px).
    function LineHeight: Integer; virtual;
    function LineWidth: Integer; virtual;
    /// Nach jeder Aenderung der Lage (OnScroll).
    procedure Scrolled; virtual;
    /// Waehrend Auto-Scroll nach jedem Schritt (z.B. Auswahl nachziehen).
    procedure DoAutoScroll(const P: TPoint); virtual;
    /// Abstand von Inhalt und Leisten zum Control-Rand (z.B. fuer einen
    /// Rahmen), Standard 0. Aendert er sich, UpdateScrollGeometry aufrufen.
    function FrameInset: Integer; virtual;
    procedure UpdateScrollGeometry;
    /// Farben der Leisten (Color = Hintergrund, TextColor = Daumen).
    function GetScrollStyle: TPPGSurfaceStyle; virtual;
    /// Im Dark Mode die Flaechenfarbe Layer statt Color (clWindow bleibt hell).
    function GetBackgroundColor: TColor; override;
    /// Waehrend eines Ziehens im Inhalt aufrufen: verlaesst die Maus den
    /// sichtbaren Bereich, scrollt das Control fortlaufend (je weiter, desto
    /// schneller). StopAutoScroll beendet das (auch bei Capture-Verlust).
    procedure AutoScrollAt(X, Y: Integer);
    procedure StopAutoScroll;
    /// Pfeile/Bild/Pos1/Ende scrollen die Ansicht (wenn KeyboardScrolling).
    function ScrollKey(Key: Word; Shift: TShiftState): Boolean;
    property KeyboardScrolling: Boolean read FKeyboardScrolling write FKeyboardScrolling;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetContentSize(AWidth, AHeight: Integer);
    /// Ziel-Lage setzen (begrenzt). Animate: weich ueber den Animator.
    procedure ScrollTo(X, Y: Integer; Animate: Boolean = False);
    /// Relativ verschieben; bei laufender Animation ab deren Ziel.
    procedure ScrollBy(DX, DY: Integer; Animate: Boolean = False);
    /// Bereich (Inhaltskoordinaten) in den sichtbaren Bereich holen.
    procedure MakeVisible(const R: TRect; Animate: Boolean = False);
    /// Sichtbarer Bereich fuer den Inhalt (Client-Koordinaten).
    function ViewRect: TRect;
    function MaxScroll(Axis: TPPGScrollAxis): Integer;
    /// Leiste wird gebraucht (Inhalt groesser als die Ansicht) und angezeigt.
    function ScrollBarVisible(Axis: TPPGScrollAxis): Boolean;
    /// Ganze Leiste bzw. Daumen in Client-Koordinaten (leer = keine Leiste).
    function ScrollBarRect(Axis: TPPGScrollAxis): TRect;
    function ThumbRect(Axis: TPPGScrollAxis): TRect;
    /// 0..1: Deckkraft (Ein-/Ausblenden) und Breite (schmal/breit).
    function ScrollBarOpacity: Single;
    function ScrollBarExpand(Axis: TPPGScrollAxis): Single;
    function Scrolling: Boolean;
    property ContentWidth: Integer read GetContentWidth;
    property ContentHeight: Integer read GetContentHeight;
    property ScrollX: Integer read GetScrollX write SetScrollX;
    property ScrollY: Integer read GetScrollY write SetScrollY;
    property ScrollBarMode: TPPGScrollBarMode read FScrollBarMode write SetScrollBarMode default sbmAuto;
    property SmoothScrolling: Boolean read FSmoothScrolling write FSmoothScrolling default True;
    property OnScroll: TNotifyEvent read FOnScroll write FOnScroll;
  end;

implementation

uses
  System.SysUtils, System.Win.Registry, Winapi.oleacc,
  PPG.Appearance, PPG.DpiUtils, PPG.Render.Registry;

const
  BarSize = 12;        // logische px: Breite der Leiste (breit)
  MinThumb = 24;       // logische px: Mindestlaenge des Daumens
  LineStep = 20;       // logische px: Zeilenschritt (Standard)
  ScrollMs = 150;      // weiches Scrollen
  ExpandMs = 150;
  CollapseMs = 250;
  FadeInMs = 100;
  FadeOutMs = 300;
  HideDelayMs = 1200;  // Ruhezeit bis zum Ausblenden (Auto)
  WheelUnit = 120;     // WHEEL_DELTA

function SystemDynamicScrollbars: Boolean;
var
  R: TRegistry;
begin
  // Windows 10/11: "Bildlaufleisten in Windows automatisch ausblenden"
  // (DynamicScrollbars = 0: immer anzeigen). Fehlt der Wert: dynamisch.
  Result := True;
  R := TRegistry.Create(KEY_READ);
  try
    R.RootKey := HKEY_CURRENT_USER;
    if R.OpenKeyReadOnly('Control Panel\Accessibility') and
      R.ValueExists('DynamicScrollbars') then
      Result := R.ReadInteger('DynamicScrollbars') <> 0;
  except
    Result := True; // Registry gesperrt: Standard
  end;
  R.Free;
end;

{ TPPGCustomScrollControl }

constructor TPPGCustomScrollControl.Create(AOwner: TComponent);
var
  A: TPPGScrollAxis;
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption] + [csOpaque];
  Width := 185;
  Height := 105;
  TabStop := True;
  FHotAxis := -1;
  FDragAxis := -1;
  FSmoothScrolling := True;
  FKeyboardScrolling := True;
  FScrollAnim := TPPGAnimation.Create(Self);
  FScrollAnim.OnStep := ScrollAnimStep;
  FFadeAnim := TPPGAnimation.Create(Self);
  FFadeAnim.OnStep := BarAnimStep;
  FHoldAnim := TPPGAnimation.Create(Self);
  FHoldAnim.OnStep := HoldStep;
  FAutoAnim := TPPGAnimation.Create(Self);
  FAutoAnim.OnStep := AutoStep;
  for A := Low(TPPGScrollAxis) to High(TPPGScrollAxis) do
  begin
    FExpandAnim[A] := TPPGAnimation.Create(Self);
    FExpandAnim[A].OnStep := BarAnimStep;
  end;
  ReadSystemSettings;
end;

destructor TPPGCustomScrollControl.Destroy;
var
  A: TPPGScrollAxis;
begin
  // Alle Animationen melden sich beim Freigeben selbst ab
  for A := Low(TPPGScrollAxis) to High(TPPGScrollAxis) do
  begin
    if FExpandAnim[A] <> nil then
      FExpandAnim[A].OnStep := nil;
    FreeAndNil(FExpandAnim[A]);
  end;
  if FAutoAnim <> nil then
    FAutoAnim.OnStep := nil;
  if FHoldAnim <> nil then
    FHoldAnim.OnStep := nil;
  if FFadeAnim <> nil then
    FFadeAnim.OnStep := nil;
  if FScrollAnim <> nil then
    FScrollAnim.OnStep := nil;
  FreeAndNil(FAutoAnim);
  FreeAndNil(FHoldAnim);
  FreeAndNil(FFadeAnim);
  FreeAndNil(FScrollAnim);
  inherited Destroy;
end;

procedure TPPGCustomScrollControl.ReadSystemSettings;
begin
  FSystemAlways := not SystemDynamicScrollbars;
end;

procedure TPPGCustomScrollControl.CMWinIniChange(var Message: TMessage);
begin
  inherited;
  ReadSystemSettings;
  Invalidate;
end;

function TPPGCustomScrollControl.IsDown: Boolean;
begin
  Result := False; // eine Flaeche wird nicht "gedrueckt"
end;

function TPPGCustomScrollControl.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_PANE;
end;

{ ---- Geometrie ---- }

function TPPGCustomScrollControl.BarThickness: Integer;
begin
  Result := PPGScale(BarSize, ScalePPI);
end;

procedure TPPGCustomScrollControl.NeedBars(out NeedH, NeedV: Boolean);
var
  B, I: Integer;
begin
  // Width/Height statt ClientRect: kein Fensterhandle erzwingen
  if FScrollBarMode = sbmNever then
  begin
    NeedH := False;
    NeedV := False;
    Exit;
  end;
  I := FrameInset;
  NeedV := FContent[saVert] > Height - 2 * I;
  NeedH := FContent[saHorz] > Width - 2 * I;
  if (FScrollBarMode = sbmAlways) or FSystemAlways then
  begin
    // Feste Leisten nehmen Platz weg: gegenseitige Abhaengigkeit aufloesen
    B := BarThickness;
    NeedV := FContent[saVert] > Height - 2 * I - Ord(NeedH) * B;
    NeedH := FContent[saHorz] > Width - 2 * I - Ord(NeedV) * B;
    NeedV := FContent[saVert] > Height - 2 * I - Ord(NeedH) * B;
  end;
end;

function TPPGCustomScrollControl.ViewRect: TRect;
var
  NeedH, NeedV: Boolean;
  B, I: Integer;
begin
  I := FrameInset;
  Result := Rect(I, I, Width - I, Height - I);
  if (FScrollBarMode = sbmAlways) or (FSystemAlways and (FScrollBarMode = sbmAuto)) then
  begin
    NeedBars(NeedH, NeedV);
    B := BarThickness;
    if NeedV then
      if UseRightToLeftAlignment then
        Inc(Result.Left, B)
      else
        Dec(Result.Right, B);
    if NeedH then
      Dec(Result.Bottom, B);
  end;
  if Result.Right < Result.Left then
    Result.Right := Result.Left;
  if Result.Bottom < Result.Top then
    Result.Bottom := Result.Top;
end;

function TPPGCustomScrollControl.MaxScroll(Axis: TPPGScrollAxis): Integer;
var
  V: TRect;
begin
  V := ViewRect;
  if Axis = saVert then
    Result := FContent[saVert] - (V.Bottom - V.Top)
  else
    Result := FContent[saHorz] - (V.Right - V.Left);
  if Result < 0 then
    Result := 0;
end;

function TPPGCustomScrollControl.ScrollBarVisible(Axis: TPPGScrollAxis): Boolean;
var
  NeedH, NeedV: Boolean;
begin
  NeedBars(NeedH, NeedV);
  if Axis = saVert then
    Result := NeedV
  else
    Result := NeedH;
end;

function TPPGCustomScrollControl.ScrollBarRect(Axis: TPPGScrollAxis): TRect;
var
  NeedH, NeedV: Boolean;
  B, I: Integer;
begin
  Result := Rect(0, 0, 0, 0);
  NeedBars(NeedH, NeedV);
  B := BarThickness;
  I := FrameInset;
  if Axis = saVert then
  begin
    if not NeedV then
      Exit;
    Result := Rect(Width - I - B, I, Width - I, Height - I - Ord(NeedH) * B);
    if UseRightToLeftAlignment then
      Result := Rect(I, Result.Top, I + B, Result.Bottom);
  end
  else
  begin
    if not NeedH then
      Exit;
    Result := Rect(I, Height - I - B, Width - I - Ord(NeedV) * B, Height - I);
    if UseRightToLeftAlignment and NeedV then
      Result := Rect(I + B, Result.Top, Width - I, Result.Bottom);
  end;
end;

function TPPGCustomScrollControl.FrameInset: Integer;
begin
  Result := 0;
end;

procedure TPPGCustomScrollControl.UpdateScrollGeometry;
begin
  // Ansicht kann sich geaendert haben: Lage begrenzen, neu zeichnen
  ScrollTo(FPos[saHorz], FPos[saVert]);
  Invalidate;
end;

function TPPGCustomScrollControl.ThumbRect(Axis: TPPGScrollAxis): TRect;
var
  T: TRect;
  TrackLen, ThumbLen, MaxS, Off, ViewLen: Integer;
  V: TRect;
begin
  T := ScrollBarRect(Axis);
  if IsRectEmpty(T) then
    Exit(T);
  V := ViewRect;
  if Axis = saVert then
  begin
    TrackLen := T.Bottom - T.Top;
    ViewLen := V.Bottom - V.Top;
  end
  else
  begin
    TrackLen := T.Right - T.Left;
    ViewLen := V.Right - V.Left;
  end;
  if FContent[Axis] > 0 then
    ThumbLen := MulDiv(TrackLen, ViewLen, FContent[Axis])
  else
    ThumbLen := TrackLen;
  if ThumbLen < PPGScale(MinThumb, ScalePPI) then
    ThumbLen := PPGScale(MinThumb, ScalePPI);
  if ThumbLen > TrackLen then
    ThumbLen := TrackLen;
  MaxS := MaxScroll(Axis);
  if MaxS > 0 then
    Off := MulDiv(TrackLen - ThumbLen, FPos[Axis], MaxS)
  else
    Off := 0;
  if Axis = saVert then
    Result := Rect(T.Left, T.Top + Off, T.Right, T.Top + Off + ThumbLen)
  else if UseRightToLeftAlignment then
    // RTL: Anfang rechts
    Result := Rect(T.Right - Off - ThumbLen, T.Top, T.Right - Off, T.Bottom)
  else
    Result := Rect(T.Left + Off, T.Top, T.Left + Off + ThumbLen, T.Bottom);
end;

function TPPGCustomScrollControl.AxisAt(X, Y: Integer): Integer;
var
  P: TPoint;
begin
  P := Point(X, Y);
  if PtInRect(ScrollBarRect(saVert), P) then
    Result := Ord(saVert)
  else if PtInRect(ScrollBarRect(saHorz), P) then
    Result := Ord(saHorz)
  else
    Result := -1;
end;

{ ---- Lage ---- }

function TPPGCustomScrollControl.GetScrollX: Integer;
begin
  Result := FPos[saHorz];
end;

function TPPGCustomScrollControl.GetScrollY: Integer;
begin
  Result := FPos[saVert];
end;

function TPPGCustomScrollControl.GetContentWidth: Integer;
begin
  Result := FContent[saHorz];
end;

function TPPGCustomScrollControl.GetContentHeight: Integer;
begin
  Result := FContent[saVert];
end;

procedure TPPGCustomScrollControl.SetScrollX(const Value: Integer);
begin
  ScrollTo(Value, FPos[saVert]);
end;

procedure TPPGCustomScrollControl.SetScrollY(const Value: Integer);
begin
  ScrollTo(FPos[saHorz], Value);
end;

procedure TPPGCustomScrollControl.SetContentSize(AWidth, AHeight: Integer);
begin
  if AWidth < 0 then
    AWidth := 0;
  if AHeight < 0 then
    AHeight := 0;
  if (FContent[saHorz] = AWidth) and (FContent[saVert] = AHeight) then
    Exit;
  FContent[saHorz] := AWidth;
  FContent[saVert] := AHeight;
  // Lage auf den neuen Bereich begrenzen (ohne Animation)
  FScrollAnim.Stop;
  ScrollTo(FPos[saHorz], FPos[saVert]);
  Invalidate;
end;

procedure TPPGCustomScrollControl.SetPosition(X, Y: Integer);
begin
  if X > MaxScroll(saHorz) then
    X := MaxScroll(saHorz);
  if Y > MaxScroll(saVert) then
    Y := MaxScroll(saVert);
  if X < 0 then
    X := 0;
  if Y < 0 then
    Y := 0;
  if (X = FPos[saHorz]) and (Y = FPos[saVert]) then
    Exit;
  FPos[saHorz] := X;
  FPos[saVert] := Y;
  Invalidate;
  Activity;
  Scrolled;
end;

procedure TPPGCustomScrollControl.ScrollTo(X, Y: Integer; Animate: Boolean);
begin
  if X > MaxScroll(saHorz) then
    X := MaxScroll(saHorz);
  if Y > MaxScroll(saVert) then
    Y := MaxScroll(saVert);
  if X < 0 then
    X := 0;
  if Y < 0 then
    Y := 0;
  FTarget[saHorz] := X;
  FTarget[saVert] := Y;
  if Animate and FSmoothScrolling and Animation.EffectiveEnabled and HandleAllocated and
    IsWindowVisible(Handle) and not (csDesigning in ComponentState) and
    ((X <> FPos[saHorz]) or (Y <> FPos[saVert])) then
  begin
    FStart[saHorz] := FPos[saHorz];
    FStart[saVert] := FPos[saVert];
    FScrollAnim.Jump(0);
    FScrollAnim.AnimateTo(1, ScrollMs, ekDecelerate);
  end
  else
  begin
    FScrollAnim.Stop;
    SetPosition(X, Y);
  end;
end;

procedure TPPGCustomScrollControl.ScrollBy(DX, DY: Integer; Animate: Boolean);
begin
  // Mehrere Radschritte hintereinander: ab dem Ziel weiterrechnen
  if FScrollAnim.Running then
    ScrollTo(FTarget[saHorz] + DX, FTarget[saVert] + DY, Animate)
  else
    ScrollTo(FPos[saHorz] + DX, FPos[saVert] + DY, Animate);
end;

function TPPGCustomScrollControl.Scrolling: Boolean;
begin
  Result := FScrollAnim.Running;
end;

procedure TPPGCustomScrollControl.ScrollAnimStep(Sender: TObject);
var
  T: Single;
begin
  T := FScrollAnim.Value;
  SetPosition(FStart[saHorz] + Round((FTarget[saHorz] - FStart[saHorz]) * T),
    FStart[saVert] + Round((FTarget[saVert] - FStart[saVert]) * T));
end;

procedure TPPGCustomScrollControl.MakeVisible(const R: TRect; Animate: Boolean);
var
  V: TRect;
  X, Y, VW, VH: Integer;
begin
  V := ViewRect;
  VW := V.Right - V.Left;
  VH := V.Bottom - V.Top;
  if FScrollAnim.Running then
  begin
    X := FTarget[saHorz];
    Y := FTarget[saVert];
  end
  else
  begin
    X := FPos[saHorz];
    Y := FPos[saVert];
  end;
  if R.Top < Y then
    Y := R.Top
  else if R.Bottom > Y + VH then
    Y := R.Bottom - VH;
  if R.Left < X then
    X := R.Left
  else if R.Right > X + VW then
    X := R.Right - VW;
  ScrollTo(X, Y, Animate);
end;

procedure TPPGCustomScrollControl.Resize;
begin
  inherited Resize;
  ScrollTo(FPos[saHorz], FPos[saVert]);
end;

procedure TPPGCustomScrollControl.Scrolled;
begin
  if Assigned(FOnScroll) then
    FOnScroll(Self);
end;

{ ---- Ein-/Ausblenden und Breite der Leisten ---- }

procedure TPPGCustomScrollControl.SetScrollBarMode(const Value: TPPGScrollBarMode);
begin
  if FScrollBarMode <> Value then
  begin
    FScrollBarMode := Value;
    ScrollTo(FPos[saHorz], FPos[saVert]); // Ansicht kann schmaler werden
    Invalidate;
  end;
end;

function TPPGCustomScrollControl.ScrollBarOpacity: Single;
begin
  if FScrollBarMode = sbmNever then
    Result := 0
  else if (FScrollBarMode = sbmAlways) or FSystemAlways or
    (csDesigning in ComponentState) then
    Result := 1
  else
    Result := FFadeAnim.Value;
end;

function TPPGCustomScrollControl.ScrollBarExpand(Axis: TPPGScrollAxis): Single;
begin
  if (FScrollBarMode = sbmAlways) or FSystemAlways then
    Result := 1
  else
    Result := FExpandAnim[Axis].Value;
end;

procedure TPPGCustomScrollControl.Activity;
begin
  if FScrollBarMode <> sbmAuto then
    Exit;
  FLastActivity := GetTickCount;
  if Animation.EffectiveEnabled and HandleAllocated and IsWindowVisible(Handle) then
    FFadeAnim.AnimateTo(1, FadeInMs)
  else
    FFadeAnim.Jump(1);
  if not FHoldAnim.Running and not (csDesigning in ComponentState) then
    FHoldAnim.StartLoop(1000);
end;

procedure TPPGCustomScrollControl.HoldStep(Sender: TObject);
begin
  // Solange die Maus ueber dem Control ist oder gezogen wird: sichtbar halten
  if MouseInside or (FDragAxis >= 0) or FAutoScrolling then
    FLastActivity := GetTickCount;
  if GetTickCount - FLastActivity < HideDelayMs then
    Exit;
  FHoldAnim.Stop;
  if Animation.EffectiveEnabled then
    FFadeAnim.AnimateTo(0, FadeOutMs)
  else
    FFadeAnim.Jump(0);
end;

procedure TPPGCustomScrollControl.BarAnimStep(Sender: TObject);
var
  R: TRect;
begin
  // Nur die Leisten neu zeichnen
  if not HandleAllocated then
    Exit;
  R := ScrollBarRect(saVert);
  if not IsRectEmpty(R) then
    InvalidateRect(Handle, @R, False);
  R := ScrollBarRect(saHorz);
  if not IsRectEmpty(R) then
    InvalidateRect(Handle, @R, False);
end;

procedure TPPGCustomScrollControl.SetHotAxis(Axis: Integer; OnThumb: Boolean);
var
  A: TPPGScrollAxis;
  Dur: Cardinal;
begin
  if (Axis = FHotAxis) and (OnThumb = FHotThumb) then
    Exit;
  FHotAxis := Axis;
  FHotThumb := OnThumb;
  for A := Low(TPPGScrollAxis) to High(TPPGScrollAxis) do
  begin
    if (Ord(A) = Axis) or (Ord(A) = FDragAxis) then
      Dur := ExpandMs
    else
      Dur := CollapseMs;
    if not Animation.EffectiveEnabled then
      Dur := 0;
    if (Ord(A) = Axis) or (Ord(A) = FDragAxis) then
      FExpandAnim[A].AnimateTo(1, Dur)
    else
      FExpandAnim[A].AnimateTo(0, Dur);
  end;
  BarAnimStep(Self);
end;

{ ---- Zeichnen ---- }

function TPPGCustomScrollControl.GetBackgroundColor: TColor;
begin
  if UseDarkMode then
    Result := Tokens.Layer
  else
    Result := inherited GetBackgroundColor;
end;

function TPPGCustomScrollControl.GetScrollStyle: TPPGSurfaceStyle;
var
  A: TPPGAppearance;
begin
  A := EffectiveAppearance;
  Result := A.Resolve(vsNormal, ScalePPI, False);
  Result.Color := PPGColorToRGB(GetBackgroundColor);
  Result.TextColor := PPGColorToRGB(A.Normal.TextColor);
  if HighContrastSupport and PPGIsHighContrast then
  begin
    Result.Color := PPGColorToRGB(clWindow);
    Result.TextColor := PPGColorToRGB(clWindowText);
  end;
end;

procedure TPPGCustomScrollControl.PaintViewport(const ACanvas: IPPGCanvas; const View: TRect);
begin
end;

procedure TPPGCustomScrollControl.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  View, Track, Thumb: TRect;
  SR: IPPGScrollRenderer;
  Style: TPPGSurfaceStyle;
  Op: Single;
  A: TPPGScrollAxis;
begin
  View := ViewRect;
  if not IsRectEmpty(View) then
  begin
    ACanvas.PushClipRoundRect(View, 0);
    try
      PaintViewport(ACanvas, View);
    finally
      ACanvas.PopClip;
    end;
  end;
  Op := ScrollBarOpacity;
  if Op <= 0 then
    Exit;
  if not Supports(Renderer, IPPGScrollRenderer, SR) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
      IPPGScrollRenderer, SR);
  Style := GetScrollStyle;
  // Ein-/Ausblenden: Daumenfarbe zum Hintergrund hin mischen
  Style.TextColor := PPGBlendColor(Style.Color, Style.TextColor, Op);
  for A := Low(TPPGScrollAxis) to High(TPPGScrollAxis) do
  begin
    Track := ScrollBarRect(A);
    if IsRectEmpty(Track) then
      Continue;
    Thumb := ThumbRect(A);
    SR.DrawScrollBar(ACanvas, Track, Thumb, Style, A = saVert, ScrollBarExpand(A),
      (FHotAxis = Ord(A)) and FHotThumb, FDragAxis = Ord(A), ScalePPI);
  end;
end;

{ ---- Maus ---- }

procedure TPPGCustomScrollControl.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  Axis: Integer;
  A: TPPGScrollAxis;
  Th: TRect;
  V: TRect;
  Page: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y); // OnMouseDown
  Axis := AxisAt(X, Y);
  FBarMouse := Axis >= 0;
  if not FBarMouse then
  begin
    ContentMouseDown(Button, Shift, X, Y);
    Exit;
  end;
  if Button <> mbLeft then
    Exit;
  A := TPPGScrollAxis(Axis);
  Th := ThumbRect(A);
  Activity;
  if PtInRect(Th, Point(X, Y)) then
  begin
    FDragAxis := Axis;
    if A = saVert then
      FDragOffset := Y - Th.Top
    else if UseRightToLeftAlignment then
      FDragOffset := Th.Right - X
    else
      FDragOffset := X - Th.Left;
    SetHotAxis(Axis, True);
    Invalidate;
  end
  else
  begin
    // Spur: eine Seite in Richtung des Klicks (weich)
    V := ViewRect;
    if A = saVert then
    begin
      Page := (V.Bottom - V.Top) * 9 div 10;
      if Y < Th.Top then
        ScrollBy(0, -Page, True)
      else
        ScrollBy(0, Page, True);
    end
    else
    begin
      Page := (V.Right - V.Left) * 9 div 10;
      if (X < Th.Left) <> UseRightToLeftAlignment then
        ScrollBy(-Page, 0, True)
      else
        ScrollBy(Page, 0, True);
    end;
  end;
end;

procedure TPPGCustomScrollControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  A: TPPGScrollAxis;
  T: TRect;
  Th: TRect;
  TrackLen, ThumbLen, P, Range: Integer;
  Axis: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  if FScrollBarMode = sbmAuto then
    Activity;
  if FDragAxis >= 0 then
  begin
    A := TPPGScrollAxis(FDragAxis);
    T := ScrollBarRect(A);
    Th := ThumbRect(A);
    if A = saVert then
      ThumbLen := Th.Bottom - Th.Top
    else
      ThumbLen := Th.Right - Th.Left;
    if A = saVert then
    begin
      TrackLen := T.Bottom - T.Top;
      P := Y - FDragOffset - T.Top;
    end
    else
    begin
      TrackLen := T.Right - T.Left;
      if UseRightToLeftAlignment then
        P := T.Right - (X + FDragOffset)
      else
        P := X - FDragOffset - T.Left;
    end;
    Range := TrackLen - ThumbLen;
    if Range > 0 then
    begin
      if A = saVert then
        ScrollTo(FPos[saHorz], MulDiv(P, MaxScroll(A), Range))
      else
        ScrollTo(MulDiv(P, MaxScroll(A), Range), FPos[saVert]);
    end;
    Exit;
  end;
  Axis := AxisAt(X, Y);
  if Axis >= 0 then
    SetHotAxis(Axis, PtInRect(ThumbRect(TPPGScrollAxis(Axis)), Point(X, Y)))
  else
    SetHotAxis(-1, False);
  if not FBarMouse then
    ContentMouseMove(Shift, X, Y);
end;

procedure TPPGCustomScrollControl.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  WasBar: Boolean;
begin
  WasBar := FBarMouse;
  FBarMouse := False;
  if FDragAxis >= 0 then
  begin
    FDragAxis := -1;
    SetHotAxis(AxisAt(X, Y), False);
    Invalidate;
  end;
  StopAutoScroll;
  inherited MouseUp(Button, Shift, X, Y);
  if not WasBar then
    ContentMouseUp(Button, Shift, X, Y);
end;

procedure TPPGCustomScrollControl.WMCaptureChanged(var Message: TMessage);
begin
  inherited;
  // Maus verloren (Dialog, Alt+Tab): Ziehen beenden
  if (HWND(Message.LParam) <> Handle) then
  begin
    StopAutoScroll;
    if FDragAxis >= 0 then
    begin
      FDragAxis := -1;
      Invalidate;
    end;
    FBarMouse := False;
  end;
end;

procedure TPPGCustomScrollControl.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FDragAxis < 0 then
    SetHotAxis(-1, False);
end;

procedure TPPGCustomScrollControl.ContentMouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
end;

procedure TPPGCustomScrollControl.ContentMouseMove(Shift: TShiftState; X, Y: Integer);
begin
end;

procedure TPPGCustomScrollControl.ContentMouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
end;

{ ---- Mausrad ---- }

function TPPGCustomScrollControl.LineHeight: Integer;
begin
  Result := PPGScale(LineStep, ScalePPI);
end;

function TPPGCustomScrollControl.LineWidth: Integer;
begin
  Result := PPGScale(LineStep, ScalePPI);
end;

function TPPGCustomScrollControl.WheelScroll(Axis: TPPGScrollAxis;
  Delta, Lines, Step: Integer): Boolean;
var
  Px, Page: Integer;
  V: TRect;
  Smooth: Boolean;
begin
  Result := False;
  if MaxScroll(Axis) = 0 then
    Exit;
  V := ViewRect;
  if Axis = saVert then
    Page := V.Bottom - V.Top
  else
    Page := V.Right - V.Left;
  // WHEEL_PAGESCROLL (UINT_MAX) als Zeilenzahl: seitenweise
  if (Lines < 0) or (Lines > 1000) then
    Inc(FWheelRest[Axis], Delta * Page)
  else
    Inc(FWheelRest[Axis], Delta * Lines * Step);
  Px := FWheelRest[Axis] div WheelUnit;
  Dec(FWheelRest[Axis], Px * WheelUnit);
  // Am Rand: nicht verbrauchen (Eltern koennen scrollen), Rest verwerfen
  if ((Px > 0) and (FPos[Axis] = 0) and not FScrollAnim.Running) or
    ((Px < 0) and (FPos[Axis] = MaxScroll(Axis)) and not FScrollAnim.Running) then
  begin
    FWheelRest[Axis] := 0;
    Exit;
  end;
  Result := True;
  if Px = 0 then
    Exit; // Touchpad: Teilschritt gesammelt
  // Grobe Radschritte weich, feine (Touchpad) sofort - das ist schon fluessig
  Smooth := Abs(Delta) >= WheelUnit;
  if Axis = saVert then
    ScrollBy(0, -Px, Smooth)
  else
    ScrollBy(-Px, 0, Smooth);
end;

function TPPGCustomScrollControl.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
var
  Lines: UINT;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if Result or (WheelDelta = 0) then
    Exit;
  Lines := 3;
  SystemParametersInfo(SPI_GETWHEELSCROLLLINES, 0, @Lines, 0);
  // Umschalt+Rad oder nur waagerechter Ueberlauf: waagerecht
  if (ssShift in Shift) or ((MaxScroll(saVert) = 0) and (MaxScroll(saHorz) > 0)) then
    Result := WheelScroll(saHorz, WheelDelta, Integer(Lines), LineWidth)
  else
    Result := WheelScroll(saVert, WheelDelta, Integer(Lines), LineHeight);
end;

procedure TPPGCustomScrollControl.WMMouseHWheel(var Message: TMessage);
var
  Delta: Integer;
  Chars: UINT;
begin
  // Kipprad/Touchpad waagerecht: positiv = nach rechts
  Delta := SmallInt(HiWord(Cardinal(Message.WParam)));
  Chars := 3;
  SystemParametersInfo(SPI_GETWHEELSCROLLCHARS, 0, @Chars, 0);
  if WheelScroll(saHorz, -Delta, Integer(Chars), LineWidth) then
    Message.Result := 0
  else
    inherited;
end;

{ ---- Tastatur ---- }

procedure TPPGCustomScrollControl.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

function TPPGCustomScrollControl.ScrollKey(Key: Word; Shift: TShiftState): Boolean;
var
  V: TRect;
  PageV: Integer;
begin
  V := ViewRect;
  PageV := (V.Bottom - V.Top) * 9 div 10;
  Result := True;
  case Key of
    VK_UP: ScrollBy(0, -LineHeight, True);
    VK_DOWN: ScrollBy(0, LineHeight, True);
    VK_LEFT:
      if UseRightToLeftAlignment then
        ScrollBy(LineWidth, 0, True)
      else
        ScrollBy(-LineWidth, 0, True);
    VK_RIGHT:
      if UseRightToLeftAlignment then
        ScrollBy(-LineWidth, 0, True)
      else
        ScrollBy(LineWidth, 0, True);
    VK_PRIOR: ScrollBy(0, -PageV, True);
    VK_NEXT: ScrollBy(0, PageV, True);
    VK_HOME:
      if ssCtrl in Shift then
        ScrollTo(0, 0, True)
      else
        ScrollTo(0, FPos[saVert], True);
    VK_END:
      if ssCtrl in Shift then
        ScrollTo(FPos[saHorz], MaxScroll(saVert), True)
      else
        ScrollTo(MaxScroll(saHorz), FPos[saVert], True);
  else
    Result := False;
  end;
end;

procedure TPPGCustomScrollControl.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if (Key <> 0) and FKeyboardScrolling and ScrollKey(Key, Shift) then
    Key := 0;
end;

{ ---- Auto-Scroll beim Ziehen ---- }

procedure TPPGCustomScrollControl.AutoScrollAt(X, Y: Integer);
var
  V: TRect;
  Edge: Integer;
begin
  FAutoPoint := Point(X, Y);
  V := ViewRect;
  Edge := PPGScale(8, ScalePPI);
  InflateRect(V, -Edge, -Edge);
  if PtInRect(V, FAutoPoint) then
  begin
    StopAutoScroll;
    Exit;
  end;
  if not FAutoScrolling then
  begin
    FAutoScrolling := True;
    FAutoTick := GetTickCount;
    FAutoAnim.StartLoop(1000);
  end;
end;

procedure TPPGCustomScrollControl.StopAutoScroll;
begin
  if not FAutoScrolling then
    Exit;
  FAutoScrolling := False;
  FAutoAnim.Stop;
end;

procedure TPPGCustomScrollControl.AutoStep(Sender: TObject);
var
  V: TRect;
  Now, Dt: Cardinal;
  DX, DY, Edge: Integer;

  function Speed(Dist: Integer): Integer;
  begin
    // px pro Sekunde: je weiter draussen, desto schneller (begrenzt)
    Result := 60 + Dist * 12;
    if Result > 3000 then
      Result := 3000;
  end;

begin
  if not FAutoScrolling then
  begin
    FAutoAnim.Stop;
    Exit;
  end;
  Now := GetTickCount;
  Dt := Now - FAutoTick;
  if Dt = 0 then
    Exit;
  FAutoTick := Now;
  V := ViewRect;
  Edge := PPGScale(8, ScalePPI);
  DX := 0;
  DY := 0;
  if FAutoPoint.Y < V.Top + Edge then
    DY := -Integer(Cardinal(Speed(V.Top + Edge - FAutoPoint.Y)) * Dt div 1000)
  else if FAutoPoint.Y > V.Bottom - Edge then
    DY := Integer(Cardinal(Speed(FAutoPoint.Y - V.Bottom + Edge)) * Dt div 1000);
  if FAutoPoint.X < V.Left + Edge then
    DX := -Integer(Cardinal(Speed(V.Left + Edge - FAutoPoint.X)) * Dt div 1000)
  else if FAutoPoint.X > V.Right - Edge then
    DX := Integer(Cardinal(Speed(FAutoPoint.X - V.Right + Edge)) * Dt div 1000);
  if (DX <> 0) or (DY <> 0) then
  begin
    ScrollBy(DX, DY);
    DoAutoScroll(FAutoPoint);
  end;
end;

procedure TPPGCustomScrollControl.DoAutoScroll(const P: TPoint);
begin
end;

end.
