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
    FFontStyle: TFontStyles;
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
    procedure SetFontStyle(const Value: TFontStyles);
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
    /// Zusaetzliche Schriftstile in diesem Zustand (z.B. fett bei Hover oder
    /// eingerastet); [] = Schrift des Controls.
    property FontStyle: TFontStyles read FFontStyle write SetFontStyle default [];
  end;

  /// Einzelne Farb-Ueberschreibungen fuer einen Zustand (Fokus, Dunkel).
  /// clDefault = nicht ueberschreiben. Color ohne ColorTo/Mirror faerbt die
  /// ganze Flaeche einfarbig.
  TPPGStateColors = class(TPersistent)
  private
    FOwner: TPersistent;
    FColors: array[0..6] of TColor;
    FFontStyle: TFontStyles;
    FOnChange: TNotifyEvent;
    function GetColor(Index: Integer): TColor;
    procedure SetColor(Index: Integer; const Value: TColor);
    procedure SetFontStyle(const Value: TFontStyles);
  protected
    procedure Changed;
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TPersistent);
    procedure Assign(Source: TPersistent); override;
    function Equals(Obj: TObject): Boolean; override;
    procedure Clear;
    function IsEmpty: Boolean;
    /// Uebertraegt die gesetzten Werte in einen Zustandsstil.
    procedure ApplyTo(S: TPPGStateStyle);
    /// Uebertraegt die gesetzten Werte in einen aufgeloesten Stil.
    procedure ApplyToSurface(var S: TPPGSurfaceStyle);
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Color: TColor index 0 read GetColor write SetColor default clDefault;
    property ColorTo: TColor index 1 read GetColor write SetColor default clDefault;
    property ColorMirror: TColor index 2 read GetColor write SetColor default clDefault;
    property ColorMirrorTo: TColor index 3 read GetColor write SetColor default clDefault;
    property BorderColor: TColor index 4 read GetColor write SetColor default clDefault;
    property GlowColor: TColor index 5 read GetColor write SetColor default clDefault;
    property TextColor: TColor index 6 read GetColor write SetColor default clDefault;
    /// Zusaetzliche Schriftstile.
    property FontStyle: TFontStyles read FFontStyle write SetFontStyle default [];
  end;

  /// Eigene Farben fuer den Dark Mode (sonst gelten dort die Preset-Farben).
  TPPGDarkColors = class(TPersistent)
  private
    FOwner: TPersistent;
    FStates: array[0..5] of TPPGStateColors;
    FFocusColor: TColor;
    FOnChange: TNotifyEvent;
    function GetState(Index: Integer): TPPGStateColors;
    procedure SetState(Index: Integer; const Value: TPPGStateColors);
    procedure SetFocusColor(const Value: TColor);
    procedure SubChanged(Sender: TObject);
  protected
    procedure Changed;
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TPersistent);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function Equals(Obj: TObject): Boolean; override;
    function IsEmpty: Boolean;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Normal: TPPGStateColors index 0 read GetState write SetState;
    property Hot: TPPGStateColors index 1 read GetState write SetState;
    property Down: TPPGStateColors index 2 read GetState write SetState;
    property Disabled: TPPGStateColors index 3 read GetState write SetState;
    property Checked: TPPGStateColors index 4 read GetState write SetState;
    property Focused: TPPGStateColors index 5 read GetState write SetState;
    property FocusColor: TColor read FFocusColor write SetFocusColor default clDefault;
  end;

  TPPGAppearance = class(TPersistent)
  private
    FOwner: TPersistent;
    FNormal: TPPGStateStyle;
    FHot: TPPGStateStyle;
    FDown: TPPGStateStyle;
    FDisabled: TPPGStateStyle;
    FChecked: TPPGStateStyle;
    FFocused: TPPGStateColors;
    FDark: TPPGDarkColors;
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
    procedure SetFocused(const Value: TPPGStateColors);
    procedure SetDark(const Value: TPPGDarkColors);
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
    /// Eigene Farben im Fokus (nach der Fokusfarbe); clDefault = keine.
    property Focused: TPPGStateColors read FFocused write SetFocused;
    /// Eigene Farben im Dark Mode (sonst gelten dort die Preset-Farben).
    property Dark: TPPGDarkColors read FDark write SetDark;
  end;

/// Skaliert einen logischen 96-DPI-Wert auf die angegebene PPI.
function PPGScale(Value, PPI: Integer): Integer;
/// Uebertraegt die eigenen Dunkel-Farben (Appearance.Dark) in eine bereits
/// dunkel eingefaerbte Appearance (Zustaende, Fokus, Fokusfarbe).
procedure PPGApplyDarkColors(Target: TPPGAppearance; Dark: TPPGDarkColors);

/// Akzentrolle der Anzeige-Controls (Badge, ProgressRing, Rating; wie die
/// ProgressBar): True, wenn Appearance.Checked sie traegt. Bei Glanz-Presets
/// (Normal mit Verlauf, Classic) ist Checked der goldene An-Zustand der
/// Office-Optik; dort und ohne gesetzte Checked.Color gilt FocusColor.
function PPGCheckedIsAccent(A: TPPGAppearance): Boolean;
/// Akzentfarbe: Checked.Color bzw. (siehe PPGCheckedIsAccent) FocusColor, als RGB.
function PPGAccentColor(A: TPPGAppearance): TColor;

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

function PPGCheckedIsAccent(A: TPPGAppearance): Boolean;
begin
  Result := (A <> nil) and PPGColorIsSet(A.Checked.Color) and
    (A.Normal.Color = A.Normal.ColorTo);
end;

function PPGAccentColor(A: TPPGAppearance): TColor;
begin
  if PPGCheckedIsAccent(A) then
    Result := PPGColorToRGB(A.Checked.Color)
  else if A <> nil then
    Result := PPGColorToRGB(A.FocusColor)
  else
    Result := PPGColorToRGB(clHighlight);
end;

procedure PPGApplyDarkColors(Target: TPPGAppearance; Dark: TPPGDarkColors);
begin
  if (Target = nil) or (Dark = nil) then
    Exit;
  Target.BeginUpdate;
  try
    Dark.Normal.ApplyTo(Target.Normal);
    Dark.Hot.ApplyTo(Target.Hot);
    Dark.Down.ApplyTo(Target.Down);
    Dark.Disabled.ApplyTo(Target.Disabled);
    Dark.Checked.ApplyTo(Target.Checked);
    // Helle Fokusfarben gelten im Dunkeln nicht, nur die dunklen
    Target.Focused.Assign(Dark.Focused);
    if Dark.FocusColor <> clDefault then
      Target.FocusColor := Dark.FocusColor;
  finally
    Target.EndUpdate;
  end;
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
  FFontStyle := [];
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
    FFontStyle := S.FFontStyle;
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
    (FDirection = S.FDirection) and (FFontStyle = S.FFontStyle);
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

procedure TPPGStateStyle.SetFontStyle(const Value: TFontStyles);
begin
  if FFontStyle <> Value then
  begin
    FFontStyle := Value;
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

{ TPPGStateColors }

constructor TPPGStateColors.Create(AOwner: TPersistent);
begin
  inherited Create;
  FOwner := AOwner;
  Clear;
end;

function TPPGStateColors.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TPPGStateColors.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGStateColors.Clear;
var
  I: Integer;
begin
  for I := Low(FColors) to High(FColors) do
    FColors[I] := clDefault;
  FFontStyle := [];
end;

function TPPGStateColors.IsEmpty: Boolean;
var
  I: Integer;
begin
  Result := FFontStyle = [];
  if Result then
    for I := Low(FColors) to High(FColors) do
      if FColors[I] <> clDefault then
        Exit(False);
end;

procedure TPPGStateColors.Assign(Source: TPersistent);
begin
  if Source is TPPGStateColors then
  begin
    FColors := TPPGStateColors(Source).FColors;
    FFontStyle := TPPGStateColors(Source).FFontStyle;
    Changed;
  end
  else
    inherited Assign(Source);
end;

function TPPGStateColors.Equals(Obj: TObject): Boolean;
var
  I: Integer;
begin
  if Obj = Self then
    Exit(True);
  if not (Obj is TPPGStateColors) then
    Exit(False);
  for I := Low(FColors) to High(FColors) do
    if FColors[I] <> TPPGStateColors(Obj).FColors[I] then
      Exit(False);
  Result := FFontStyle = TPPGStateColors(Obj).FFontStyle;
end;

function TPPGStateColors.GetColor(Index: Integer): TColor;
begin
  Result := FColors[Index];
end;

procedure TPPGStateColors.SetColor(Index: Integer; const Value: TColor);
begin
  if FColors[Index] <> Value then
  begin
    FColors[Index] := Value;
    Changed;
  end;
end;

procedure TPPGStateColors.SetFontStyle(const Value: TFontStyles);
begin
  if FFontStyle <> Value then
  begin
    FFontStyle := Value;
    Changed;
  end;
end;

procedure TPPGStateColors.ApplyTo(S: TPPGStateStyle);
var
  C0, C1, C2, C3: TColor;
begin
  if IsEmpty then
    Exit;
  // Color ohne die uebrigen Flaechenfarben = einfarbig
  C0 := S.Color;
  C1 := S.ColorTo;
  C2 := S.ColorMirror;
  C3 := S.ColorMirrorTo;
  if FColors[0] <> clDefault then
  begin
    C0 := FColors[0];
    C1 := FColors[0];
    C2 := FColors[0];
    C3 := FColors[0];
  end;
  if FColors[1] <> clDefault then
    C1 := FColors[1];
  if FColors[2] <> clDefault then
    C2 := FColors[2];
  if FColors[3] <> clDefault then
    C3 := FColors[3];
  S.Color := C0;
  S.ColorTo := C1;
  S.ColorMirror := C2;
  S.ColorMirrorTo := C3;
  if FColors[4] <> clDefault then
    S.BorderColor := FColors[4];
  if FColors[5] <> clDefault then
    S.GlowColor := FColors[5];
  if FColors[6] <> clDefault then
    S.TextColor := FColors[6];
  S.FontStyle := S.FontStyle + FFontStyle;
end;

procedure TPPGStateColors.ApplyToSurface(var S: TPPGSurfaceStyle);
begin
  if IsEmpty then
    Exit;
  if FColors[0] <> clDefault then
  begin
    S.Color := PPGColorToRGB(FColors[0]);
    S.ColorTo := S.Color;
    S.ColorMirror := S.Color;
    S.ColorMirrorTo := S.Color;
  end;
  if FColors[1] <> clDefault then
    S.ColorTo := PPGColorToRGB(FColors[1]);
  if FColors[2] <> clDefault then
    S.ColorMirror := PPGColorToRGB(FColors[2]);
  if FColors[3] <> clDefault then
    S.ColorMirrorTo := PPGColorToRGB(FColors[3]);
  if FColors[4] <> clDefault then
    S.BorderColor := PPGColorToRGB(FColors[4]);
  if FColors[5] <> clDefault then
    S.GlowColor := PPGColorToRGB(FColors[5]);
  if FColors[6] <> clDefault then
    S.TextColor := PPGColorToRGB(FColors[6]);
  S.FontStyle := S.FontStyle + FFontStyle;
end;

{ TPPGDarkColors }

constructor TPPGDarkColors.Create(AOwner: TPersistent);
var
  I: Integer;
begin
  inherited Create;
  FOwner := AOwner;
  FFocusColor := clDefault;
  for I := Low(FStates) to High(FStates) do
  begin
    FStates[I] := TPPGStateColors.Create(Self);
    FStates[I].OnChange := SubChanged;
  end;
end;

destructor TPPGDarkColors.Destroy;
var
  I: Integer;
begin
  FOnChange := nil;
  for I := High(FStates) downto Low(FStates) do
    FStates[I].Free;
  inherited Destroy;
end;

function TPPGDarkColors.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TPPGDarkColors.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGDarkColors.SubChanged(Sender: TObject);
begin
  Changed;
end;

procedure TPPGDarkColors.Assign(Source: TPersistent);
var
  I: Integer;
begin
  if Source is TPPGDarkColors then
  begin
    for I := Low(FStates) to High(FStates) do
    begin
      FStates[I].FColors := TPPGDarkColors(Source).FStates[I].FColors;
      FStates[I].FFontStyle := TPPGDarkColors(Source).FStates[I].FFontStyle;
    end;
    FFocusColor := TPPGDarkColors(Source).FFocusColor;
    Changed;
  end
  else
    inherited Assign(Source);
end;

function TPPGDarkColors.Equals(Obj: TObject): Boolean;
var
  I: Integer;
begin
  if Obj = Self then
    Exit(True);
  if not (Obj is TPPGDarkColors) then
    Exit(False);
  for I := Low(FStates) to High(FStates) do
    if not FStates[I].Equals(TPPGDarkColors(Obj).FStates[I]) then
      Exit(False);
  Result := FFocusColor = TPPGDarkColors(Obj).FFocusColor;
end;

function TPPGDarkColors.IsEmpty: Boolean;
var
  I: Integer;
begin
  Result := FFocusColor = clDefault;
  if Result then
    for I := Low(FStates) to High(FStates) do
      if not FStates[I].IsEmpty then
        Exit(False);
end;

function TPPGDarkColors.GetState(Index: Integer): TPPGStateColors;
begin
  Result := FStates[Index];
end;

procedure TPPGDarkColors.SetState(Index: Integer; const Value: TPPGStateColors);
begin
  FStates[Index].Assign(Value);
end;

procedure TPPGDarkColors.SetFocusColor(const Value: TColor);
begin
  if FFocusColor <> Value then
  begin
    FFocusColor := Value;
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
  FFocused := TPPGStateColors.Create(Self);
  FFocused.OnChange := StateChanged;
  FDark := TPPGDarkColors.Create(Self);
  FDark.OnChange := StateChanged;
  FFocusColor := clHighlight;
  FRounding := 4;
  FBorderWidth := 1;
  FGlowSize := 4;
end;

destructor TPPGAppearance.Destroy;
begin
  // nil-sicher: Destroy laeuft auch nach einer Exception im Konstruktor
  FOnChange := nil;
  FDark.Free;
  FFocused.Free;
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
      FFocused.Assign(S.FFocused);
      FDark.Assign(S.FDark);
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
    FFocused.Equals(S.FFocused) and FDark.Equals(S.FDark) and
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
  Result.FontStyle := S.FontStyle;
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
    // Eigene Fokusfarben (Flaeche, Text, Rand) nach der Fokusfarbe
    FFocused.ApplyToSurface(Result);
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

procedure TPPGAppearance.SetFocused(const Value: TPPGStateColors);
begin
  FFocused.Assign(Value);
end;

procedure TPPGAppearance.SetDark(const Value: TPPGDarkColors);
begin
  FDark.Assign(Value);
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
