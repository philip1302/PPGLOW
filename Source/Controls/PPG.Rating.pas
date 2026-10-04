unit PPG.Rating;

{ TPPGRating - Sternebewertung (Phase 7a).

  - MaxValue Sterne (Icon-Schrift, sonst gezeichnetes Polygon), Value 0..MaxValue,
    halbe Sterne mit AllowHalf.
  - Hover zeigt eine Vorschau; Klick setzt den Wert. Klick auf den aktuellen
    Wert loescht ihn (AllowClear).
  - Tastatur: Links/Rechts (bzw. Hoch/Runter) +/- 1 (halbe: 0,5), Pos1 = 0,
    Ende = MaxValue, Ziffern 0..9 setzen direkt. RTL gespiegelt.
  - ReadOnly zeigt nur an (keine Vorschau, keine Eingabe, bleibt fokussierbar).
  - Code (Value := ...) loest kein OnChange aus; der Anwender schon.
  - Screenreader: Rolle Schieberegler, Wert "3,5 / 5". }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Base;

type
  TPPGCustomRating = class(TPPGCustomControl)
  private
    FValue: Double;
    FMaxValue: Integer;
    FAllowHalf: Boolean;
    FAllowClear: Boolean;
    FReadOnly: Boolean;
    FStarSize: Integer;
    FStarSpacing: Integer;
    FStarColor: TColor;
    FHoverValue: Double; // < 0 = keine Vorschau
    FOnChange: TNotifyEvent;
    procedure SetValue(const Value: Double);
    procedure SetMaxValue(const Value: Integer);
    procedure SetAllowHalf(const Value: Boolean);
    procedure SetReadOnly(const Value: Boolean);
    procedure SetStarSize(const Value: Integer);
    procedure SetStarSpacing(const Value: Integer);
    procedure SetStarColor(const Value: TColor);
    function NormalizeValue(V: Double): Double;
    procedure DrawStar(const ACanvas: IPPGCanvas; const R: TRect; Fill: Double;
      FillColor, EmptyColor: TColor);
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure Loaded; override;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    function CalcAutoSize(out AWidth, AHeight: Integer): Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    /// Wert durch den Anwender setzen (OnChange, Screenreader).
    procedure UserSetValue(V: Double);
    function AccRole: Integer; override;
    function AccState: Integer; override;
    function AccValue: string; override;
    property Value: Double read FValue write SetValue;
    property MaxValue: Integer read FMaxValue write SetMaxValue default 5;
    property AllowHalf: Boolean read FAllowHalf write SetAllowHalf default False;
    property AllowClear: Boolean read FAllowClear write FAllowClear default True;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    /// Sterngroesse in logischen px.
    property StarSize: Integer read FStarSize write SetStarSize default 20;
    property StarSpacing: Integer read FStarSpacing write SetStarSpacing default 4;
    /// Farbe der gefuellten Sterne (clDefault = Akzentfarbe).
    property StarColor: TColor read FStarColor write SetStarColor default clDefault;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  public
    constructor Create(AOwner: TComponent); override;
    /// Stern-Rechteck (0-basiert).
    function StarRect(Index: Integer): TRect;
    /// Wert, den ein Klick an X setzen wuerde.
    function ValueAt(X: Integer): Double;
    property HoverValue: Double read FHoverValue;
  end;

  TPPGRating = class(TPPGCustomRating)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property HighContrastSupport;
    property Value;
    property MaxValue;
    property AllowHalf;
    property AllowClear;
    property ReadOnly;
    property StarSize;
    property StarSpacing;
    property StarColor;
    property Align;
    property Anchors;
    property AutoSize default True;
    property BiDiMode;
    property Constraints;
    property Enabled;
    property ParentBiDiMode;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property OnChange;
    property OnEnter;
    property OnExit;
  end;

implementation

uses
  System.SysUtils, System.Math, Winapi.oleacc,
  PPG.Appearance, PPG.DpiUtils, PPG.Tokens, PPG.IconFont;

{ TPPGCustomRating }

constructor TPPGCustomRating.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption, csClickEvents, csDoubleClicks];
  FMaxValue := 5;
  FAllowClear := True;
  FStarSize := 20;
  FStarSpacing := 4;
  FStarColor := clDefault;
  FHoverValue := -1;
  TabStop := True;
  Width := 120;
  Height := 24;
  AutoSize := True;
end;

function TPPGCustomRating.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGCustomRating.IsDown: Boolean;
begin
  Result := False;
end;

function TPPGCustomRating.NormalizeValue(V: Double): Double;
begin
  if FAllowHalf then
    Result := Round(V * 2) / 2
  else
    Result := Round(V);
  if Result < 0 then
    Result := 0;
  if Result > FMaxValue then
    Result := FMaxValue;
end;

procedure TPPGCustomRating.SetValue(const Value: Double);
var
  V: Double;
begin
  // Beim Laden roh merken: AllowHalf/MaxValue kommen evtl. erst danach (Loaded rundet)
  if csLoading in ComponentState then
  begin
    FValue := Value;
    Exit;
  end;
  V := NormalizeValue(Value);
  if V <> FValue then
  begin
    FValue := V;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
  end;
end;

procedure TPPGCustomRating.Loaded;
begin
  inherited Loaded;
  FValue := NormalizeValue(FValue);
end;

procedure TPPGCustomRating.UserSetValue(V: Double);
var
  Old: Double;
begin
  Old := FValue;
  SetValue(V);
  if (FValue <> Old) and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGCustomRating.SetMaxValue(const Value: Integer);
begin
  FMaxValue := PPGCheckRange(Self, 'MaxValue', Value, 1, 50);
  if (FValue > FMaxValue) and not (csLoading in ComponentState) then
    FValue := FMaxValue;
  RequestAutoSize;
  Invalidate;
end;

procedure TPPGCustomRating.SetAllowHalf(const Value: Boolean);
begin
  if FAllowHalf <> Value then
  begin
    FAllowHalf := Value;
    if not (csLoading in ComponentState) then
      FValue := NormalizeValue(FValue);
    Invalidate;
  end;
end;

procedure TPPGCustomRating.SetReadOnly(const Value: Boolean);
begin
  if FReadOnly <> Value then
  begin
    FReadOnly := Value;
    FHoverValue := -1;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
  end;
end;

procedure TPPGCustomRating.SetStarSize(const Value: Integer);
begin
  FStarSize := PPGCheckRange(Self, 'StarSize', Value, 8, 128);
  RequestAutoSize;
  Invalidate;
end;

procedure TPPGCustomRating.SetStarSpacing(const Value: Integer);
begin
  FStarSpacing := PPGCheckRange(Self, 'StarSpacing', Value, 0, 64);
  RequestAutoSize;
  Invalidate;
end;

procedure TPPGCustomRating.SetStarColor(const Value: TColor);
begin
  if FStarColor <> Value then
  begin
    FStarColor := Value;
    Invalidate;
  end;
end;

function TPPGCustomRating.CalcAutoSize(out AWidth, AHeight: Integer): Boolean;
var
  PPI: Integer;
begin
  PPI := ScalePPI;
  // 2 px Rand je Seite fuer die Fokusmarkierung
  AWidth := FMaxValue * PPGScale(FStarSize, PPI) + (FMaxValue - 1) * PPGScale(FStarSpacing, PPI) +
    2 * PPGScale(2, PPI);
  AHeight := PPGScale(FStarSize, PPI) + 2 * PPGScale(2, PPI);
  Result := True;
end;

function TPPGCustomRating.StarRect(Index: Integer): TRect;
var
  PPI, S, Gap, X, Y: Integer;
begin
  PPI := ScalePPI;
  S := PPGScale(FStarSize, PPI);
  Gap := PPGScale(FStarSpacing, PPI);
  X := PPGScale(2, PPI) + Index * (S + Gap);
  Y := (Height - S) div 2;
  Result := Rect(X, Y, X + S, Y + S);
  if UseRightToLeftAlignment then
    Result := Rect(Width - Result.Right, Result.Top, Width - Result.Left, Result.Bottom);
end;

function TPPGCustomRating.ValueAt(X: Integer): Double;
var
  I: Integer;
  R: TRect;
  Frac: Double;
begin
  for I := 0 to FMaxValue - 1 do
  begin
    R := StarRect(I);
    // Zwischenraum zaehlt zum vorherigen Stern
    if UseRightToLeftAlignment then
    begin
      if X < R.Left - PPGScale(FStarSpacing, ScalePPI) then
        Continue;
      Frac := (R.Right - X) / (R.Right - R.Left);
    end
    else
    begin
      if X >= R.Right + PPGScale(FStarSpacing, ScalePPI) then
        Continue;
      Frac := (X - R.Left) / (R.Right - R.Left);
    end;
    if FAllowHalf and (Frac < 0.5) then
      Exit(I + 0.5);
    Exit(I + 1);
  end;
  Result := FMaxValue;
end;

procedure TPPGCustomRating.DrawStar(const ACanvas: IPPGCanvas; const R: TRect; Fill: Double;
  FillColor, EmptyColor: TColor);
var
  Pts: array[0..10] of TPoint;
  I, CX, CY, RO, RI: Integer;
  A: Double;
  DC: HDC;
  Brush, OldBrush: HBRUSH;
  Pen, OldPen: HPEN;
  Half: TRect;
  UseFont: Boolean;
begin
  UseFont := PPGIconFontName <> '';
  if not UseFont then
  begin
    CX := (R.Left + R.Right) div 2;
    CY := (R.Top + R.Bottom) div 2 + (R.Bottom - R.Top) div 20;
    RO := (R.Right - R.Left) div 2;
    RI := Round(RO * 0.45);
    for I := 0 to 9 do
    begin
      A := (I * 36 - 90) * Pi / 180;
      if Odd(I) then
        Pts[I] := Point(CX + Round(RI * Cos(A)), CY + Round(RI * Sin(A)))
      else
        Pts[I] := Point(CX + Round(RO * Cos(A)), CY + Round(RO * Sin(A)));
    end;
    Pts[10] := Pts[0];
  end;
  // Leerer Stern (Umriss)
  if Fill < 1 then
  begin
    if UseFont then
      PPGDrawIcon(ACanvas, R, igStar, EmptyColor, R.Bottom - R.Top)
    else
      ACanvas.DrawPolyline(Pts, Max(1, (R.Right - R.Left) div 16), EmptyColor, 255);
  end;
  if Fill <= 0 then
    Exit;
  Half := R;
  if Fill < 1 then
  begin
    if UseRightToLeftAlignment then
      Half.Left := R.Right - (R.Right - R.Left) div 2
    else
      Half.Right := R.Left + (R.Right - R.Left) div 2;
    ACanvas.PushClipRoundRect(Half, 0);
  end;
  try
    if UseFont then
      PPGDrawIcon(ACanvas, R, igStarFilled, FillColor, R.Bottom - R.Top)
    else
    begin
      DC := ACanvas.BeginGdi;
      try
        if Fill < 1 then
          IntersectClipRect(DC, Half.Left, Half.Top, Half.Right, Half.Bottom);
        Brush := CreateSolidBrush(ColorToRGB(FillColor));
        Pen := CreatePen(PS_SOLID, 1, ColorToRGB(FillColor));
        OldBrush := SelectObject(DC, Brush);
        OldPen := SelectObject(DC, Pen);
        Polygon(DC, Pts, 10);
        SelectObject(DC, OldPen);
        SelectObject(DC, OldBrush);
        DeleteObject(Pen);
        DeleteObject(Brush);
        if Fill < 1 then
          SelectClipRgn(DC, 0);
      finally
        ACanvas.EndGdi(DC);
      end;
    end;
  finally
    if Fill < 1 then
      ACanvas.PopClip;
  end;
end;

procedure TPPGCustomRating.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  I, PPI: Integer;
  Shown, F: Double;
  FillCol, EmptyCol, HoverCol: TColor;
  R: TRect;
  HC: Boolean;
begin
  PPI := ScalePPI;
  HC := HighContrastSupport and PPGIsHighContrast;
  if HC then
  begin
    FillCol := PPGColorToRGB(clHighlight);
    EmptyCol := PPGColorToRGB(clWindowText);
  end
  else
  begin
    if FStarColor = clDefault then
      FillCol := PPGColorToRGB(EffectiveAppearance.FocusColor)
    else
      FillCol := PPGColorToRGB(FStarColor);
    EmptyCol := Tokens.TextSecondary;
  end;
  if not Enabled then
  begin
    FillCol := PPGBlendColor(FillCol, PPGColorToRGB(GetBackgroundColor), 0.55);
    EmptyCol := PPGBlendColor(EmptyCol, PPGColorToRGB(GetBackgroundColor), 0.55);
  end;
  HoverCol := FillCol;
  Shown := FValue;
  if FHoverValue >= 0 then
  begin
    Shown := FHoverValue;
    // Vorschau etwas heller als der feste Wert
    if not HC then
      HoverCol := PPGBlendColor(FillCol, PPGColorToRGB(GetBackgroundColor), 0.3);
  end;
  for I := 0 to FMaxValue - 1 do
  begin
    F := Shown - I;
    if F > 1 then
      F := 1;
    R := StarRect(I);
    if FHoverValue >= 0 then
      DrawStar(ACanvas, R, F, HoverCol, EmptyCol)
    else
      DrawStar(ACanvas, R, F, FillCol, EmptyCol);
  end;
  if FocusVisible and Focused then
  begin
    R := ClientR;
    ACanvas.FrameRoundRect(R, PPGScale(4, PPI), PPGScale(2, PPI),
      PPGColorToRGB(EffectiveAppearance.FocusColor), 255);
  end;
end;

procedure TPPGCustomRating.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  H: Double;
begin
  inherited MouseMove(Shift, X, Y);
  if FReadOnly or not Enabled then
    Exit;
  H := ValueAt(X);
  if H <> FHoverValue then
  begin
    FHoverValue := H;
    Invalidate;
  end;
end;

procedure TPPGCustomRating.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHoverValue >= 0 then
  begin
    FHoverValue := -1;
    Invalidate;
  end;
end;

procedure TPPGCustomRating.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  V: Double;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if (Button <> mbLeft) or FReadOnly or not Enabled then
    Exit;
  if not PtInRect(ClientRect, Point(X, Y)) then
    Exit;
  V := ValueAt(X);
  if FAllowClear and (V = FValue) then
    V := 0;
  FHoverValue := -1; // nach dem Klick den festen Wert zeigen
  UserSetValue(V);
  Invalidate;
end;

procedure TPPGCustomRating.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TPPGCustomRating.KeyDown(var Key: Word; Shift: TShiftState);
var
  Step: Double;
  K: Word;
begin
  inherited KeyDown(Key, Shift);
  if FReadOnly or not Enabled then
    Exit;
  if FAllowHalf then
    Step := 0.5
  else
    Step := 1;
  K := Key;
  if UseRightToLeftAlignment then
  begin
    if K = VK_LEFT then
      K := VK_RIGHT
    else if K = VK_RIGHT then
      K := VK_LEFT;
  end;
  case K of
    VK_RIGHT, VK_UP:
      begin
        UserSetValue(FValue + Step);
        Key := 0;
      end;
    VK_LEFT, VK_DOWN:
      begin
        UserSetValue(FValue - Step);
        Key := 0;
      end;
    VK_HOME:
      begin
        UserSetValue(0);
        Key := 0;
      end;
    VK_END:
      begin
        UserSetValue(FMaxValue);
        Key := 0;
      end;
  end;
end;

procedure TPPGCustomRating.KeyPress(var Key: Char);
begin
  inherited KeyPress(Key);
  if FReadOnly or not Enabled then
    Exit;
  if (Key >= '0') and (Key <= '9') then
  begin
    UserSetValue(Ord(Key) - Ord('0'));
    Key := #0;
  end;
end;

procedure TPPGCustomRating.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TPPGCustomRating.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

function TPPGCustomRating.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_SLIDER;
end;

function TPPGCustomRating.AccState: Integer;
begin
  Result := inherited AccState;
  if FReadOnly then
    Result := Result or STATE_SYSTEM_READONLY;
end;

function TPPGCustomRating.AccValue: string;
begin
  Result := FloatToStr(FValue) + ' / ' + IntToStr(FMaxValue);
end;

end.
