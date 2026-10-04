unit PPG.Appearance;

{ Stil-Daten der Controls (reine Daten, keine Zeichenlogik).

  - TPPGStateStyle : Farben fuer genau einen Zustand
  - TPPGAppearance : alle Zustaende + Masse (in 96-DPI-Einheiten)

  Streaming-Regeln:
  - Setter von Sub-Objekten rufen Assign auf (nie Pointer ueberschreiben).
  - GetOwner ist implementiert, damit Object Inspector und Meldungen den
    vollen Pfad kennen ("Button1.Appearance.Hot").
  - Masse werden logisch (96 DPI) gespeichert und erst beim Zeichnen skaliert.
    Dadurch gibt es keine Doppelskalierung bei Per-Monitor-DPI-Wechseln. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, Vcl.Graphics, PPG.Types;

const
  PPGMaxRounding = 200;
  PPGMaxBorderWidth = 20;
  PPGMaxGlowSize = 30;

type
  TPPGStateStyle = class(TPersistent)
  private
    FOwner: TPersistent;
    FColor: TColor;
    FColorTo: TColor;
    FColorMirror: TColor;
    FColorMirrorTo: TColor;
    FBorderColor: TColor;
    FGlowColor: TColor;
    FTextColor: TColor;
    FGlowAlpha: Byte;
    FDirection: TPPGGradientDirection;
    FOnChange: TNotifyEvent;
    procedure SetColor(const Value: TColor);
    procedure SetColorTo(const Value: TColor);
    procedure SetColorMirror(const Value: TColor);
    procedure SetColorMirrorTo(const Value: TColor);
    procedure SetBorderColor(const Value: TColor);
    procedure SetGlowColor(const Value: TColor);
    procedure SetTextColor(const Value: TColor);
    procedure SetGlowAlpha(const Value: Byte);
    procedure SetDirection(const Value: TPPGGradientDirection);
  protected
    procedure Changed; virtual;
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TPersistent);
    procedure Assign(Source: TPersistent); override;
    function Equals(Obj: TObject): Boolean; override;
    procedure SetAll(AColor, AColorTo, AMirror, AMirrorTo, ABorder, AGlow, AText: TColor;
      AGlowAlpha: Byte);
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Color: TColor read FColor write SetColor;
    property ColorTo: TColor read FColorTo write SetColorTo;
    property ColorMirror: TColor read FColorMirror write SetColorMirror;
    property ColorMirrorTo: TColor read FColorMirrorTo write SetColorMirrorTo;
    property BorderColor: TColor read FBorderColor write SetBorderColor;
    property GlowColor: TColor read FGlowColor write SetGlowColor;
    property GlowAlpha: Byte read FGlowAlpha write SetGlowAlpha;
    property TextColor: TColor read FTextColor write SetTextColor;
    property GradientDirection: TPPGGradientDirection read FDirection write SetDirection;
  end;

  TPPGAppearance = class(TPersistent)
  private
    FOwner: TPersistent;
    FNormal: TPPGStateStyle;
    FHot: TPPGStateStyle;
    FDown: TPPGStateStyle;
    FDisabled: TPPGStateStyle;
    FChecked: TPPGStateStyle;
    FFocusColor: TColor;
    FRounding: Integer;
    FBorderWidth: Integer;
    FGlowSize: Integer;
    FUpdateCount: Integer;
    FChangedDuringUpdate: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetNormal(const Value: TPPGStateStyle);
    procedure SetHot(const Value: TPPGStateStyle);
    procedure SetDown(const Value: TPPGStateStyle);
    procedure SetDisabled(const Value: TPPGStateStyle);
    procedure SetChecked(const Value: TPPGStateStyle);
    procedure SetFocusColor(const Value: TColor);
    procedure SetRounding(const Value: Integer);
    procedure SetBorderWidth(const Value: Integer);
    procedure SetGlowSize(const Value: Integer);
    procedure StateChanged(Sender: TObject);
  protected
    procedure Changed; virtual;
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TPersistent);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function Equals(Obj: TObject): Boolean; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    function StateStyle(State: TPPGVisualState): TPPGStateStyle;
    /// Erzeugt den aufgeloesten Stil fuer einen Zustand; Masse werden mit
    /// PPI/96 skaliert.
    function Resolve(State: TPPGVisualState; PPI: Integer; AFocused: Boolean): TPPGSurfaceStyle;
    /// Wie Resolve, aber fuer einen beliebigen Zustandsstil (z.B. Checked).
    function ResolveStyle(S: TPPGStateStyle; PPI: Integer; AFocused: Boolean): TPPGSurfaceStyle;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Normal: TPPGStateStyle read FNormal write SetNormal;
    property Hot: TPPGStateStyle read FHot write SetHot;
    property Down: TPPGStateStyle read FDown write SetDown;
    property Disabled: TPPGStateStyle read FDisabled write SetDisabled;
    /// "An"-Zustand von CheckBox, RadioButton und ToggleSwitch:
    /// Color* = Fuellung, TextColor = Haken/Punkt/Schalterknopf.
    property Checked: TPPGStateStyle read FChecked write SetChecked;
    property FocusColor: TColor read FFocusColor write SetFocusColor;
    property Rounding: Integer read FRounding write SetRounding;
    property BorderWidth: Integer read FBorderWidth write SetBorderWidth;
    property GlowSize: Integer read FGlowSize write SetGlowSize;
  end;

/// Skaliert einen logischen 96-DPI-Wert auf die angegebene PPI.
function PPGScale(Value, PPI: Integer): Integer;

implementation

uses
  Winapi.Windows;

function PPGScale(Value, PPI: Integer): Integer;
begin
  if (PPI <= 0) or (PPI = 96) then
    Result := Value
  else
    Result := MulDiv(Value, PPI, 96);
end;

{ TPPGStateStyle }

constructor TPPGStateStyle.Create(AOwner: TPersistent);
begin
  inherited Create;
  FOwner := AOwner;
  FColor := clBtnFace;
  FColorTo := clBtnFace;
  FColorMirror := clBtnFace;
  FColorMirrorTo := clBtnFace;
  FBorderColor := clBtnShadow;
  FGlowColor := clHighlight;
  FTextColor := clBtnText;
  FGlowAlpha := 0;
  FDirection := gdVertical;
end;

function TPPGStateStyle.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TPPGStateStyle.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGStateStyle.Assign(Source: TPersistent);
var
  S: TPPGStateStyle;
begin
  if Source is TPPGStateStyle then
  begin
    S := TPPGStateStyle(Source);
    FColor := S.FColor;
    FColorTo := S.FColorTo;
    FColorMirror := S.FColorMirror;
    FColorMirrorTo := S.FColorMirrorTo;
    FBorderColor := S.FBorderColor;
    FGlowColor := S.FGlowColor;
    FTextColor := S.FTextColor;
    FGlowAlpha := S.FGlowAlpha;
    FDirection := S.FDirection;
    Changed;
  end
  else
    inherited Assign(Source); // wirft EConvertError fuer unbekannte Typen
end;

function TPPGStateStyle.Equals(Obj: TObject): Boolean;
var
  S: TPPGStateStyle;
begin
  if Obj = Self then
    Exit(True);
  if not (Obj is TPPGStateStyle) then
    Exit(False);
  S := TPPGStateStyle(Obj);
  Result := (FColor = S.FColor) and (FColorTo = S.FColorTo) and
    (FColorMirror = S.FColorMirror) and (FColorMirrorTo = S.FColorMirrorTo) and
    (FBorderColor = S.FBorderColor) and (FGlowColor = S.FGlowColor) and
    (FTextColor = S.FTextColor) and (FGlowAlpha = S.FGlowAlpha) and
    (FDirection = S.FDirection);
end;

procedure TPPGStateStyle.SetAll(AColor, AColorTo, AMirror, AMirrorTo, ABorder,
  AGlow, AText: TColor; AGlowAlpha: Byte);
begin
  FColor := AColor;
  FColorTo := AColorTo;
  FColorMirror := AMirror;
  FColorMirrorTo := AMirrorTo;
  FBorderColor := ABorder;
  FGlowColor := AGlow;
  FTextColor := AText;
  FGlowAlpha := AGlowAlpha;
  Changed;
end;

procedure TPPGStateStyle.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Changed;
  end;
end;

procedure TPPGStateStyle.SetColorTo(const Value: TColor);
begin
  if FColorTo <> Value then
  begin
    FColorTo := Value;
    Changed;
  end;
end;

procedure TPPGStateStyle.SetColorMirror(const Value: TColor);
begin
  if FColorMirror <> Value then
  begin
    FColorMirror := Value;
    Changed;
  end;
end;

procedure TPPGStateStyle.SetColorMirrorTo(const Value: TColor);
begin
  if FColorMirrorTo <> Value then
  begin
    FColorMirrorTo := Value;
    Changed;
  end;
end;

procedure TPPGStateStyle.SetBorderColor(const Value: TColor);
begin
  if FBorderColor <> Value then
  begin
    FBorderColor := Value;
    Changed;
  end;
end;

procedure TPPGStateStyle.SetGlowColor(const Value: TColor);
begin
  if FGlowColor <> Value then
  begin
    FGlowColor := Value;
    Changed;
  end;
end;

procedure TPPGStateStyle.SetGlowAlpha(const Value: Byte);
begin
  if FGlowAlpha <> Value then
  begin
    FGlowAlpha := Value;
    Changed;
  end;
end;

procedure TPPGStateStyle.SetTextColor(const Value: TColor);
begin
  if FTextColor <> Value then
  begin
    FTextColor := Value;
    Changed;
  end;
end;

procedure TPPGStateStyle.SetDirection(const Value: TPPGGradientDirection);
begin
  if FDirection <> Value then
  begin
    FDirection := Value;
    Changed;
  end;
end;

{ TPPGAppearance }

constructor TPPGAppearance.Create(AOwner: TPersistent);
begin
  inherited Create;
  FOwner := AOwner;
  FNormal := TPPGStateStyle.Create(Self);
  FNormal.OnChange := StateChanged;
  FHot := TPPGStateStyle.Create(Self);
  FHot.OnChange := StateChanged;
  FDown := TPPGStateStyle.Create(Self);
  FDown.OnChange := StateChanged;
  FDisabled := TPPGStateStyle.Create(Self);
  FDisabled.OnChange := StateChanged;
  FChecked := TPPGStateStyle.Create(Self);
  FChecked.OnChange := StateChanged;
  FFocusColor := clHighlight;
  FRounding := 4;
  FBorderWidth := 1;
  FGlowSize := 4;
end;

destructor TPPGAppearance.Destroy;
begin
  // nil-sicher: Destroy laeuft auch nach einer Exception im Konstruktor
  FOnChange := nil;
  FChecked.Free;
  FDisabled.Free;
  FDown.Free;
  FHot.Free;
  FNormal.Free;
  inherited Destroy;
end;

function TPPGAppearance.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TPPGAppearance.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TPPGAppearance.EndUpdate;
begin
  Assert(FUpdateCount > 0, 'TPPGAppearance.EndUpdate without BeginUpdate');
  if FUpdateCount > 0 then
    Dec(FUpdateCount);
  if (FUpdateCount = 0) and FChangedDuringUpdate then
  begin
    FChangedDuringUpdate := False;
    Changed;
  end;
end;

procedure TPPGAppearance.Changed;
begin
  if FUpdateCount > 0 then
  begin
    FChangedDuringUpdate := True;
    Exit;
  end;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGAppearance.StateChanged(Sender: TObject);
begin
  Changed;
end;

procedure TPPGAppearance.Assign(Source: TPersistent);
var
  S: TPPGAppearance;
begin
  if Source is TPPGAppearance then
  begin
    S := TPPGAppearance(Source);
    BeginUpdate;
    try
      FNormal.Assign(S.FNormal);
      FHot.Assign(S.FHot);
      FDown.Assign(S.FDown);
      FDisabled.Assign(S.FDisabled);
      FChecked.Assign(S.FChecked);
      FFocusColor := S.FFocusColor;
      FRounding := S.FRounding;
      FBorderWidth := S.FBorderWidth;
      FGlowSize := S.FGlowSize;
      Changed;
    finally
      EndUpdate;
    end;
  end
  else
    inherited Assign(Source);
end;

function TPPGAppearance.Equals(Obj: TObject): Boolean;
var
  S: TPPGAppearance;
begin
  if Obj = Self then
    Exit(True);
  if not (Obj is TPPGAppearance) then
    Exit(False);
  S := TPPGAppearance(Obj);
  Result := FNormal.Equals(S.FNormal) and FHot.Equals(S.FHot) and
    FDown.Equals(S.FDown) and FDisabled.Equals(S.FDisabled) and FChecked.Equals(S.FChecked) and
    (FFocusColor = S.FFocusColor) and (FRounding = S.FRounding) and
    (FBorderWidth = S.FBorderWidth) and (FGlowSize = S.FGlowSize);
end;

function TPPGAppearance.StateStyle(State: TPPGVisualState): TPPGStateStyle;
begin
  case State of
    vsHot: Result := FHot;
    vsDown: Result := FDown;
    vsDisabled: Result := FDisabled;
  else
    Result := FNormal;
  end;
end;

function TPPGAppearance.Resolve(State: TPPGVisualState; PPI: Integer;
  AFocused: Boolean): TPPGSurfaceStyle;
begin
  Result := ResolveStyle(StateStyle(State), PPI, AFocused);
end;

function TPPGAppearance.ResolveStyle(S: TPPGStateStyle; PPI: Integer;
  AFocused: Boolean): TPPGSurfaceStyle;
begin
  Result.Color := PPGColorToRGB(S.Color);
  Result.ColorTo := PPGColorToRGB(S.ColorTo);
  Result.ColorMirror := PPGColorToRGB(S.ColorMirror);
  Result.ColorMirrorTo := PPGColorToRGB(S.ColorMirrorTo);
  Result.BorderColor := PPGColorToRGB(S.BorderColor);
  Result.GlowColor := PPGColorToRGB(S.GlowColor);
  Result.TextColor := PPGColorToRGB(S.TextColor);
  Result.GlowAlpha := S.GlowAlpha;
  Result.Direction := S.GradientDirection;
  Result.Rounding := PPGScale(FRounding, PPI);
  Result.BorderWidth := PPGScale(FBorderWidth, PPI);
  if (FBorderWidth > 0) and (Result.BorderWidth < 1) then
    Result.BorderWidth := 1;
  Result.GlowSize := PPGScale(FGlowSize, PPI);
  Result.Focused := AFocused;
  if AFocused then
  begin
    // Fokus-Hervorhebung: Rahmen in Fokusfarbe, Glow mindestens dezent sichtbar
    Result.BorderColor := PPGColorToRGB(FFocusColor);
    if Result.GlowAlpha < 96 then
      Result.GlowAlpha := 96;
    Result.GlowColor := PPGColorToRGB(FFocusColor);
  end;
end;

procedure TPPGAppearance.SetNormal(const Value: TPPGStateStyle);
begin
  FNormal.Assign(Value);
end;

procedure TPPGAppearance.SetHot(const Value: TPPGStateStyle);
begin
  FHot.Assign(Value);
end;

procedure TPPGAppearance.SetDown(const Value: TPPGStateStyle);
begin
  FDown.Assign(Value);
end;

procedure TPPGAppearance.SetDisabled(const Value: TPPGStateStyle);
begin
  FDisabled.Assign(Value);
end;

procedure TPPGAppearance.SetChecked(const Value: TPPGStateStyle);
begin
  FChecked.Assign(Value);
end;

procedure TPPGAppearance.SetFocusColor(const Value: TColor);
begin
  if FFocusColor <> Value then
  begin
    FFocusColor := Value;
    Changed;
  end;
end;

procedure TPPGAppearance.SetRounding(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'Rounding', Value, 0, PPGMaxRounding);
  if FRounding <> V then
  begin
    FRounding := V;
    Changed;
  end;
end;

procedure TPPGAppearance.SetBorderWidth(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'BorderWidth', Value, 0, PPGMaxBorderWidth);
  if FBorderWidth <> V then
  begin
    FBorderWidth := V;
    Changed;
  end;
end;

procedure TPPGAppearance.SetGlowSize(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'GlowSize', Value, 0, PPGMaxGlowSize);
  if FGlowSize <> V then
  begin
    FGlowSize := V;
    Changed;
  end;
end;

end.
