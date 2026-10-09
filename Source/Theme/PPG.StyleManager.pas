unit PPG.StyleManager;

{ Zentrales Theme fuer beliebig viele PPGlow-Controls (Observer-Muster).

  Lebenszyklus-Regeln:
  - Clients werden als TComponent gehalten (NIE als Interface-Referenz:
    TComponent zaehlt keine Referenzen -> haengende Zeiger).
  - FreeNotification in beide Richtungen: wird ein Client oder der Manager
    freigegeben, raeumt Notification(opRemove) die Referenzen auf.
  - Benachrichtigt wird ueber ein kurzlebiges IPPGStyleClient (Supports),
    dadurch kennt diese Unit keine Control-Klassen (keine Zyklen).

  Marke / Firmen-Design (AccentColor, ThemeColors, ChartPalette):
  - Die Werte gelten anwendungsweit fuer ALLE PPGlow-Controls (wie ThemeMode,
    ueber TPPGTokenOverrides). Mehrere Manager: der zuletzt geaenderte bzw.
    geladene Manager mit eigenen Werten gilt.
  - Aendert sich AccentColor oder ThemeColors.Light (nicht beim Laden), werden
    die Farben der eigenen Appearance aus den Tokens neu abgeleitet
    (ApplyThemeColors); die Formen (Rundung, Glow ...) bleiben.
  - SaveToFile/LoadFromFile: Theme-Datei (INI) mit allen Einstellungen. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.Generics.Collections, Vcl.Graphics,
  PPG.Types, PPG.Tokens, PPG.Appearance, PPG.Animation, PPG.Theme;

type
  IPPGStyleClient = interface
    ['{C4E1A7B2-93D5-4F0A-8B6C-5A2E9D1F7C38}']
    procedure StyleManagerChanged(Sender: TObject);
  end;

  /// Ueberschreibungen der Farb-Tokens fuer einen Modus (Hell oder Dunkel).
  /// clDefault = Farbe des Presets.
  TPPGTokenColorSet = class(TPersistent)
  private
    FOwner: TPersistent;
    FColors: array[TPPGTokenColor] of TColor;
    FOnChange: TNotifyEvent;
    function GetColor(Index: Integer): TColor;
    procedure SetColor(Index: Integer; const Value: TColor);
    function GetColorKind(Kind: TPPGTokenColor): TColor;
    procedure SetColorKind(Kind: TPPGTokenColor; const Value: TColor);
  protected
    function GetOwner: TPersistent; override;
    procedure Changed;
  public
    constructor Create(AOwner: TPersistent);
    procedure Assign(Source: TPersistent); override;
    function Equals(Obj: TObject): Boolean; override;
    procedure Clear;
    function IsEmpty: Boolean;
    property Colors[Kind: TPPGTokenColor]: TColor read GetColorKind write SetColorKind;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Accent: TColor index Ord(tkAccent) read GetColor write SetColor default clDefault;
    property AccentHover: TColor index Ord(tkAccentHover) read GetColor write SetColor default clDefault;
    property AccentPressed: TColor index Ord(tkAccentPressed) read GetColor write SetColor default clDefault;
    property OnAccent: TColor index Ord(tkOnAccent) read GetColor write SetColor default clDefault;
    property Background: TColor index Ord(tkBackground) read GetColor write SetColor default clDefault;
    property Layer: TColor index Ord(tkLayer) read GetColor write SetColor default clDefault;
    property Surface: TColor index Ord(tkSurface) read GetColor write SetColor default clDefault;
    property SurfaceHover: TColor index Ord(tkSurfaceHover) read GetColor write SetColor default clDefault;
    property SurfacePressed: TColor index Ord(tkSurfacePressed) read GetColor write SetColor default clDefault;
    property SurfaceDisabled: TColor index Ord(tkSurfaceDisabled) read GetColor write SetColor default clDefault;
    property Stroke: TColor index Ord(tkStroke) read GetColor write SetColor default clDefault;
    property StrokeStrong: TColor index Ord(tkStrokeStrong) read GetColor write SetColor default clDefault;
    property StrokeDisabled: TColor index Ord(tkStrokeDisabled) read GetColor write SetColor default clDefault;
    property TextPrimary: TColor index Ord(tkTextPrimary) read GetColor write SetColor default clDefault;
    property TextSecondary: TColor index Ord(tkTextSecondary) read GetColor write SetColor default clDefault;
    property TextDisabled: TColor index Ord(tkTextDisabled) read GetColor write SetColor default clDefault;
    property Danger: TColor index Ord(tkDanger) read GetColor write SetColor default clDefault;
    property Warning: TColor index Ord(tkWarning) read GetColor write SetColor default clDefault;
    property Success: TColor index Ord(tkSuccess) read GetColor write SetColor default clDefault;
    property Paused: TColor index Ord(tkPaused) read GetColor write SetColor default clDefault;
    property Link: TColor index Ord(tkLink) read GetColor write SetColor default clDefault;
  end;

  /// Token-Ueberschreibungen fuer Hell und Dunkel.
  TPPGThemeColors = class(TPersistent)
  private
    FOwner: TPersistent;
    FLight: TPPGTokenColorSet;
    FDark: TPPGTokenColorSet;
    FOnChange: TNotifyEvent;
    procedure SetLight(const Value: TPPGTokenColorSet);
    procedure SetDark(const Value: TPPGTokenColorSet);
    procedure SetChanged(Sender: TObject);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TPersistent);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function IsEmpty: Boolean;
    /// Wird mit dem geaenderten Satz (Light oder Dark) aufgerufen.
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Light: TPPGTokenColorSet read FLight write SetLight;
    property Dark: TPPGTokenColorSet read FDark write SetDark;
  end;

  TPPGStyleManager = class(TComponent)
  private
    FPreset: string;
    FAppearance: TPPGAppearance;
    FAnimation: TPPGAnimationSettings;
    FClients: TList<TComponent>;
    FUpdateCount: Integer;
    FPendingChange: Boolean;
    FThemeMode: TPPGThemeMode;
    FStyleForms: Boolean;
    FAccentColor: TColor;
    FThemeColors: TPPGThemeColors;
    FChartPalette: TStrings;
    FSilent: Boolean; // Hilfsobjekt beim Laden: keine globalen Wirkungen
    procedure SetThemeMode(const Value: TPPGThemeMode);
    procedure SetStyleForms(const Value: Boolean);
    procedure SetPreset(const Value: string);
    procedure SetAppearance(const Value: TPPGAppearance);
    procedure SetAnimation(const Value: TPPGAnimationSettings);
    procedure SetAccentColor(const Value: TColor);
    procedure SetThemeColors(const Value: TPPGThemeColors);
    procedure SetChartPalette(const Value: TStrings);
    procedure SubObjectChanged(Sender: TObject);
    procedure ThemeColorsChanged(Sender: TObject);
    procedure ChartPaletteChanged(Sender: TObject);
    function HasBranding: Boolean;
    function ParseChartPalette: TArray<TColor>;
    /// Uebertraegt Akzent, Tokens und Palette in TPPGTokenOverrides und
    /// benachrichtigt alle Controls. LightChanged: eigene Appearance neu ableiten.
    procedure ApplyBranding(LightChanged: Boolean);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Loaded; override;
    procedure Changed; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddClient(Client: TComponent);
    procedure RemoveClient(Client: TComponent);
    function ClientCount: Integer;
    procedure BeginUpdate;
    procedure EndUpdate;
    /// Setzt die Appearance auf die Vorgaben des aktuellen Presets zurueck.
    procedure ResetToPresetDefaults;
    /// Theme-Datei (INI, Abschnitt [PPGlowTheme]) mit Preset, Modus, Marke,
    /// Appearance, Animation und Palette. Laden wirft EPPGStreamError bei
    /// ungueltigen Werten; der Manager bleibt dann unveraendert.
    procedure SaveToFile(const FileName: string);
    procedure LoadFromFile(const FileName: string);
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromStream(Stream: TStream);
  published
    property Preset: string read FPreset write SetPreset;
    property Appearance: TPPGAppearance read FAppearance write SetAppearance;
    property Animation: TPPGAnimationSettings read FAnimation write SetAnimation;
    /// Hell/Dunkel/System fuer ALLE PPGlow-Controls der Anwendung (TPPGTheme.Mode),
    /// auch im Designer. Mehrere Manager: der zuletzt gesetzte gilt.
    property ThemeMode: TPPGThemeMode read FThemeMode write SetThemeMode default tmLight;
    /// Formulare in den Farben des Modus, dunkle Titelleiste (TPPGTheme.StyleForms;
    /// nur zur Laufzeit).
    property StyleForms: Boolean read FStyleForms write SetStyleForms default False;
    /// Markenfarbe: Akzent fuer Fokus, Auswahl, Fortschritt, Schalter, Links
    /// und Diagramme in allen Presets und beiden Modi (Varianten mit
    /// Kontrastpruefung). clDefault = Akzent des Presets bzw. des Systems.
    property AccentColor: TColor read FAccentColor write SetAccentColor default clDefault;
    /// Einzelne Tokens je Modus (Flaechen, Text, Signalfarben). Gilt nach
    /// AccentColor, ueberschreibt sie also.
    property ThemeColors: TPPGThemeColors read FThemeColors write SetThemeColors;
    /// Diagramm- und Kategorienfarben in dieser Reihenfolge, eine Farbe je
    /// Zeile ("#RRGGBB" oder clName). Leer = Palette des Presets.
    property ChartPalette: TStrings read FChartPalette write SetChartPalette;
  end;

implementation

uses
  PPG.Lang,
  System.SysUtils, System.IniFiles, PPG.Consts, PPG.Exceptions, PPG.ErrorHandler,
  PPG.Render.Intf, PPG.Render.Registry, PPG.Presets, PPG.ThemeFile;

const
  ThemeSection = 'PPGlowTheme';

var
  // Manager, dessen Marke gerade in TPPGTokenOverrides steht
  GBrandingOwner: TPPGStyleManager = nil;

{ TPPGTokenColorSet }

constructor TPPGTokenColorSet.Create(AOwner: TPersistent);
begin
  inherited Create;
  FOwner := AOwner;
  Clear;
end;

function TPPGTokenColorSet.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TPPGTokenColorSet.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGTokenColorSet.Clear;
var
  K: TPPGTokenColor;
begin
  for K := Low(TPPGTokenColor) to High(TPPGTokenColor) do
    FColors[K] := clDefault;
end;

function TPPGTokenColorSet.IsEmpty: Boolean;
var
  K: TPPGTokenColor;
begin
  Result := True;
  for K := Low(TPPGTokenColor) to High(TPPGTokenColor) do
    if FColors[K] <> clDefault then
      Exit(False);
end;

procedure TPPGTokenColorSet.Assign(Source: TPersistent);
begin
  if Source is TPPGTokenColorSet then
  begin
    FColors := TPPGTokenColorSet(Source).FColors;
    Changed;
  end
  else
    inherited Assign(Source);
end;

function TPPGTokenColorSet.Equals(Obj: TObject): Boolean;
var
  K: TPPGTokenColor;
begin
  if Obj = Self then
    Exit(True);
  if not (Obj is TPPGTokenColorSet) then
    Exit(False);
  for K := Low(TPPGTokenColor) to High(TPPGTokenColor) do
    if FColors[K] <> TPPGTokenColorSet(Obj).FColors[K] then
      Exit(False);
  Result := True;
end;

function TPPGTokenColorSet.GetColor(Index: Integer): TColor;
begin
  Result := FColors[TPPGTokenColor(Index)];
end;

procedure TPPGTokenColorSet.SetColor(Index: Integer; const Value: TColor);
begin
  SetColorKind(TPPGTokenColor(Index), Value);
end;

function TPPGTokenColorSet.GetColorKind(Kind: TPPGTokenColor): TColor;
begin
  Result := FColors[Kind];
end;

procedure TPPGTokenColorSet.SetColorKind(Kind: TPPGTokenColor; const Value: TColor);
begin
  if FColors[Kind] <> Value then
  begin
    FColors[Kind] := Value;
    Changed;
  end;
end;

{ TPPGThemeColors }

constructor TPPGThemeColors.Create(AOwner: TPersistent);
begin
  inherited Create;
  FOwner := AOwner;
  FLight := TPPGTokenColorSet.Create(Self);
  FLight.OnChange := SetChanged;
  FDark := TPPGTokenColorSet.Create(Self);
  FDark.OnChange := SetChanged;
end;

destructor TPPGThemeColors.Destroy;
begin
  FOnChange := nil;
  FDark.Free;
  FLight.Free;
  inherited Destroy;
end;

function TPPGThemeColors.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TPPGThemeColors.SetChanged(Sender: TObject);
begin
  if Assigned(FOnChange) then
    FOnChange(Sender);
end;

procedure TPPGThemeColors.Assign(Source: TPersistent);
begin
  if Source is TPPGThemeColors then
  begin
    FLight.Assign(TPPGThemeColors(Source).FLight);
    FDark.Assign(TPPGThemeColors(Source).FDark);
  end
  else
    inherited Assign(Source);
end;

function TPPGThemeColors.IsEmpty: Boolean;
begin
  Result := FLight.IsEmpty and FDark.IsEmpty;
end;

procedure TPPGThemeColors.SetLight(const Value: TPPGTokenColorSet);
begin
  FLight.Assign(Value);
end;

procedure TPPGThemeColors.SetDark(const Value: TPPGTokenColorSet);
begin
  FDark.Assign(Value);
end;

{ TPPGStyleManager }

constructor TPPGStyleManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FClients := TList<TComponent>.Create;
  FAppearance := TPPGAppearance.Create(Self);
  FAppearance.OnChange := SubObjectChanged;
  FAnimation := TPPGAnimationSettings.Create(Self);
  FAnimation.OnChange := SubObjectChanged;
  FAccentColor := clDefault;
  FThemeColors := TPPGThemeColors.Create(Self);
  FThemeColors.OnChange := ThemeColorsChanged;
  FChartPalette := TStringList.Create;
  TStringList(FChartPalette).OnChange := ChartPaletteChanged;
  SetPreset(TPPGRendererRegistry.DefaultName);
end;

destructor TPPGStyleManager.Destroy;
begin
  if FAppearance <> nil then
    FAppearance.OnChange := nil;
  if FAnimation <> nil then
    FAnimation.OnChange := nil;
  if FThemeColors <> nil then
    FThemeColors.OnChange := nil;
  if FChartPalette <> nil then
  begin
    TStringList(FChartPalette).OnChange := nil;
  end;
  // Die Marke dieses Managers gilt nicht ueber sein Leben hinaus. Kein
  // TPPGTheme.Changed hier: beim Beenden sind Controls evtl. schon halb frei.
  if GBrandingOwner = Self then
  begin
    GBrandingOwner := nil;
    TPPGTokenOverrides.Clear;
  end;
  // WICHTIG: Free-Notifications NICHT vorher entfernen. TComponent.Destroy
  // benachrichtigt alle Clients (Notification opRemove), die daraufhin ihre
  // Referenz auf nil setzen. Wuerden wir sie hier abmelden, behielten die
  // Clients einen haengenden Zeiger (AV beim naechsten Zugriff).
  // Die Felder werden deshalb erst NACH inherited freigegeben (der Speicher
  // der Instanz selbst wird erst nach dem Destruktor freigegeben).
  inherited Destroy;
  FreeAndNil(FClients);
  FreeAndNil(FChartPalette);
  FreeAndNil(FThemeColors);
  FreeAndNil(FAnimation);
  FreeAndNil(FAppearance);
end;

procedure TPPGStyleManager.AddClient(Client: TComponent);
begin
  if (Client = nil) or (FClients = nil) then
    Exit;
  if Client = Self then
    raise EPPGConfigError.Create(PPGStr(@SPPGCircularStyleManager));
  if FClients.IndexOf(Client) < 0 then
  begin
    FClients.Add(Client);
    Client.FreeNotification(Self);
  end;
end;

procedure TPPGStyleManager.RemoveClient(Client: TComponent);
begin
  if (Client = nil) or (FClients = nil) then
    Exit;
  if FClients.Remove(Client) >= 0 then
    Client.RemoveFreeNotification(Self);
end;

function TPPGStyleManager.ClientCount: Integer;
begin
  if FClients = nil then
    Result := 0
  else
    Result := FClients.Count;
end;

procedure TPPGStyleManager.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FClients <> nil) then
    FClients.Remove(AComponent);
end;

procedure TPPGStyleManager.Loaded;
begin
  inherited Loaded;
  // Marke aus der DFM anwendungsweit setzen (die Farben der Appearance kommen
  // dabei aus der DFM, sie werden nicht neu abgeleitet)
  if HasBranding then
    ApplyBranding(False);
  // Unbekanntes Preset aus DFM wurde in SetPreset bereits auf den Default
  // umgebogen; jetzt alle Clients einmalig aktualisieren.
  Changed;
end;

procedure TPPGStyleManager.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TPPGStyleManager.EndUpdate;
begin
  Assert(FUpdateCount > 0, 'TPPGStyleManager.EndUpdate without BeginUpdate');
  if FUpdateCount > 0 then
    Dec(FUpdateCount);
  if (FUpdateCount = 0) and FPendingChange then
    Changed;
end;

procedure TPPGStyleManager.Changed;
var
  Snapshot: TArray<TComponent>;
  Client: IPPGStyleClient;
  I: Integer;
begin
  if (FUpdateCount > 0) or (csLoading in ComponentState) then
  begin
    FPendingChange := True;
    Exit;
  end;
  FPendingChange := False;
  if (FClients = nil) or (FClients.Count = 0) then
    Exit;
  // Kopie: ein Client darf sich im Handler abmelden
  Snapshot := FClients.ToArray;
  for I := 0 to High(Snapshot) do
    if (FClients.IndexOf(Snapshot[I]) >= 0) and
      Supports(Snapshot[I], IPPGStyleClient, Client) then
    begin
      // Jeder Client einzeln abgesichert: ein fehlerhafter Client darf die
      // Aenderung fuer die uebrigen nicht abbrechen.
      try
        try
          Client.StyleManagerChanged(Self);
        except
          on E: Exception do
            TPPGErrorHandler.HandleCallbackError(Self, E, 'StyleManager.Changed');
        end;
      finally
        Client := nil; // Interface nicht laenger als noetig halten
      end;
    end;
end;

procedure TPPGStyleManager.SubObjectChanged(Sender: TObject);
begin
  Changed;
end;

procedure TPPGStyleManager.ResetToPresetDefaults;
var
  R: IPPGRenderer;
begin
  R := TPPGRendererRegistry.Find(FPreset);
  if R <> nil then
    R.ApplyDefaults(FAppearance); // loest ueber OnChange Changed aus
end;

procedure TPPGStyleManager.SetThemeMode(const Value: TPPGThemeMode);
begin
  FThemeMode := Value;
  if FSilent then
    Exit;
  // Bewusst auch im Designer: so laesst sich der Dark Mode dort pruefen
  TPPGTheme.Mode := Value;
end;

procedure TPPGStyleManager.SetStyleForms(const Value: Boolean);
begin
  FStyleForms := Value;
  if FSilent then
    Exit;
  // Nie im Designer: Screen.Forms enthaelt dort die Fenster der IDE
  if not (csDesigning in ComponentState) then
    TPPGTheme.StyleForms := Value;
end;

procedure TPPGStyleManager.SetPreset(const Value: string);
var
  R: IPPGRenderer;
  NewName: string;
begin
  R := TPPGRendererRegistry.Find(Value);
  NewName := Value;
  if R = nil then
  begin
    if not PPGIsLoading(Self) then
      raise EPPGPropertyError.CreateInvalid(Self, 'Preset', Value);
    // DFM mit unbekanntem Preset (z.B. Plugin fehlt): trotzdem oeffnen
    NewName := TPPGRendererRegistry.DefaultName;
    TPPGErrorHandler.LogWarning(Self, Format(PPGStr(@SPPGUnknownPresetFallback),
      [Value, PPGDisplayName(Self), NewName]));
    R := TPPGRendererRegistry.Find(NewName);
  end;
  if SameText(FPreset, NewName) and (FPreset <> '') then
    Exit;
  FPreset := NewName;
  // Beim Laden kommen die Farben aus der DFM, nicht aus dem Preset
  if (R <> nil) and not (csLoading in ComponentState) then
    R.ApplyDefaults(FAppearance)
  else
    Changed;
end;

procedure TPPGStyleManager.SetAppearance(const Value: TPPGAppearance);
begin
  FAppearance.Assign(Value);
end;

procedure TPPGStyleManager.SetAnimation(const Value: TPPGAnimationSettings);
begin
  FAnimation.Assign(Value);
end;

{ ---- Marke ---- }

function TPPGStyleManager.HasBranding: Boolean;
begin
  Result := (FAccentColor <> clDefault) or not FThemeColors.IsEmpty or
    (FChartPalette.Count > 0);
end;

function TPPGStyleManager.ParseChartPalette: TArray<TColor>;
var
  I, N: Integer;
  C: TColor;
begin
  SetLength(Result, FChartPalette.Count);
  N := 0;
  for I := 0 to FChartPalette.Count - 1 do
  begin
    if Trim(FChartPalette[I]) = '' then
      Continue;
    if not PPGTryTextToColor(FChartPalette[I], C) then
    begin
      // Ungueltige Zeilen werden mit Warnung uebersprungen (die Liste ist
      // schon geaendert, wenn OnChange kommt; Werfen liesse sie halb gueltig)
      TPPGErrorHandler.LogWarning(Self, Format(PPGStr(@SPPGColorInvalid),
        [FChartPalette[I]]));
      Continue;
    end;
    Result[N] := C;
    Inc(N);
  end;
  SetLength(Result, N);
end;

procedure TPPGStyleManager.ApplyBranding(LightChanged: Boolean);
var
  K: TPPGTokenColor;
  R: IPPGRenderer;
  TR: IPPGThemeRenderer;
begin
  if FSilent then
    Exit;
  TPPGTokenOverrides.AccentBase := FAccentColor;
  for K := Low(TPPGTokenColor) to High(TPPGTokenColor) do
  begin
    TPPGTokenOverrides.Colors[False, K] := FThemeColors.Light.Colors[K];
    TPPGTokenOverrides.Colors[True, K] := FThemeColors.Dark.Colors[K];
  end;
  TPPGTokenOverrides.ChartPalette := ParseChartPalette;
  if HasBranding then
    GBrandingOwner := Self
  else if GBrandingOwner = Self then
    GBrandingOwner := nil;
  if LightChanged and not (csLoading in ComponentState) then
  begin
    // Eigene Appearance aus den neuen Tokens ableiten (benachrichtigt die
    // Clients ueber OnChange); Formen bleiben
    R := TPPGRendererRegistry.Find(FPreset);
    if Supports(R, IPPGThemeRenderer, TR) then
      TR.ApplyThemeColors(FAppearance, False);
  end;
  // Alle PPGlow-Controls (auch ohne Manager): Dark-Mode-Farben, Tokens
  if not (csLoading in ComponentState) then
    TPPGTheme.Changed;
end;

procedure TPPGStyleManager.SetAccentColor(const Value: TColor);
begin
  if FAccentColor = Value then
    Exit;
  FAccentColor := Value;
  if not (csLoading in ComponentState) then
    ApplyBranding(True);
end;

procedure TPPGStyleManager.SetThemeColors(const Value: TPPGThemeColors);
begin
  FThemeColors.Assign(Value);
end;

procedure TPPGStyleManager.ThemeColorsChanged(Sender: TObject);
begin
  if not (csLoading in ComponentState) then
    ApplyBranding(Sender = FThemeColors.Light);
end;

procedure TPPGStyleManager.SetChartPalette(const Value: TStrings);
begin
  FChartPalette.Assign(Value);
end;

procedure TPPGStyleManager.ChartPaletteChanged(Sender: TObject);
begin
  if not (csLoading in ComponentState) then
    ApplyBranding(False);
end;

{ ---- Theme-Datei ---- }

procedure TPPGStyleManager.SaveToStream(Stream: TStream);
var
  Ini: TMemIniFile;
  L: TStringList;
begin
  Ini := TMemIniFile.Create('');
  try
    Ini.WriteInteger(ThemeSection, 'Format', 1);
    PPGSaveObjectToIni(Self, Ini, ThemeSection, '');
    // Palette eine Farbe je Schluessel (lesbarer als CommaText)
    Ini.DeleteKey(ThemeSection, 'ChartPalette');
    Ini.WriteString(ThemeSection, 'ChartPalette', StringReplace(
      FChartPalette.Text, sLineBreak, ';', [rfReplaceAll]));
    L := TStringList.Create;
    try
      Ini.GetStrings(L);
      L.SaveToStream(Stream, TEncoding.UTF8);
    finally
      L.Free;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TPPGStyleManager.LoadFromStream(Stream: TStream);
var
  Ini: TMemIniFile;
  L: TStringList;
  Temp: TPPGStyleManager;
  Pal: string;
begin
  Ini := TMemIniFile.Create('');
  try
    L := TStringList.Create;
    try
      L.LoadFromStream(Stream, TEncoding.UTF8);
      Ini.SetStrings(L);
    finally
      L.Free;
    end;
    // Erst in ein Hilfsobjekt lesen: bei einem Fehler bleibt Self unveraendert
    Temp := TPPGStyleManager.Create(nil);
    try
      Temp.FSilent := True;
      Temp.BeginUpdate;
      Pal := Ini.ReadString(ThemeSection, 'ChartPalette', '');
      Ini.DeleteKey(ThemeSection, 'ChartPalette');
      PPGLoadObjectFromIni(Temp, Ini, ThemeSection, '');
      Temp.FChartPalette.Text := StringReplace(Pal, ';', sLineBreak, [rfReplaceAll]);
      Temp.ParseChartPalette; // prueft die Farben
      BeginUpdate;
      try
        SetPreset(Temp.Preset);
        FAppearance.Assign(Temp.FAppearance);
        FAnimation.Assign(Temp.FAnimation);
        // Marke direkt setzen, damit die geladene Appearance nicht neu
        // abgeleitet wird
        FAccentColor := Temp.FAccentColor;
        FThemeColors.OnChange := nil;
        try
          FThemeColors.Assign(Temp.FThemeColors);
        finally
          FThemeColors.OnChange := ThemeColorsChanged;
        end;
        TStringList(FChartPalette).OnChange := nil;
        try
          FChartPalette.Assign(Temp.FChartPalette);
        finally
          TStringList(FChartPalette).OnChange := ChartPaletteChanged;
        end;
        ApplyBranding(False);
        StyleForms := Temp.StyleForms;
        ThemeMode := Temp.ThemeMode;
      finally
        EndUpdate;
      end;
    finally
      Temp.Free;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TPPGStyleManager.SaveToFile(const FileName: string);
var
  S: TFileStream;
begin
  S := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(S);
  finally
    S.Free;
  end;
end;

procedure TPPGStyleManager.LoadFromFile(const FileName: string);
var
  S: TFileStream;
begin
  S := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    try
      LoadFromStream(S);
    except
      on E: EPPGStreamError do
        raise EPPGStreamError.CreateFmt(PPGStr(@SPPGThemeFileInvalid), [FileName, E.Message]);
    end;
  finally
    S.Free;
  end;
end;

end.
