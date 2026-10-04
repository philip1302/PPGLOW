unit PPG.StyleManager;

{ Zentrales Theme fuer beliebig viele PPGlow-Controls (Observer-Muster).

  Lebenszyklus-Regeln:
  - Clients werden als TComponent gehalten (NIE als Interface-Referenz:
    TComponent zaehlt keine Referenzen -> haengende Zeiger).
  - FreeNotification in beide Richtungen: wird ein Client oder der Manager
    freigegeben, raeumt Notification(opRemove) die Referenzen auf.
  - Benachrichtigt wird ueber ein kurzlebiges IPPGStyleClient (Supports),
    dadurch kennt diese Unit keine Control-Klassen (keine Zyklen). }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.Generics.Collections,
  PPG.Types, PPG.Appearance, PPG.Animation, PPG.Theme;

type
  IPPGStyleClient = interface
    ['{C4E1A7B2-93D5-4F0A-8B6C-5A2E9D1F7C38}']
    procedure StyleManagerChanged(Sender: TObject);
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
    procedure SetThemeMode(const Value: TPPGThemeMode);
    procedure SetStyleForms(const Value: Boolean);
    procedure SetPreset(const Value: string);
    procedure SetAppearance(const Value: TPPGAppearance);
    procedure SetAnimation(const Value: TPPGAnimationSettings);
    procedure SubObjectChanged(Sender: TObject);
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
  end;

implementation

uses
  PPG.Lang,
  System.SysUtils, PPG.Consts, PPG.Exceptions, PPG.ErrorHandler,
  PPG.Render.Intf, PPG.Render.Registry, PPG.Presets;

constructor TPPGStyleManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FClients := TList<TComponent>.Create;
  FAppearance := TPPGAppearance.Create(Self);
  FAppearance.OnChange := SubObjectChanged;
  FAnimation := TPPGAnimationSettings.Create(Self);
  FAnimation.OnChange := SubObjectChanged;
  SetPreset(TPPGRendererRegistry.DefaultName);
end;

destructor TPPGStyleManager.Destroy;
begin
  if FAppearance <> nil then
    FAppearance.OnChange := nil;
  if FAnimation <> nil then
    FAnimation.OnChange := nil;
  // WICHTIG: Free-Notifications NICHT vorher entfernen. TComponent.Destroy
  // benachrichtigt alle Clients (Notification opRemove), die daraufhin ihre
  // Referenz auf nil setzen. Wuerden wir sie hier abmelden, behielten die
  // Clients einen haengenden Zeiger (AV beim naechsten Zugriff).
  // Die Felder werden deshalb erst NACH inherited freigegeben (der Speicher
  // der Instanz selbst wird erst nach dem Destruktor freigegeben).
  inherited Destroy;
  FreeAndNil(FClients);
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
      Client.StyleManagerChanged(Self);
      Client := nil; // Interface nicht laenger als noetig halten
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
  // Bewusst auch im Designer: so laesst sich der Dark Mode dort pruefen
  TPPGTheme.Mode := Value;
end;

procedure TPPGStyleManager.SetStyleForms(const Value: Boolean);
begin
  FStyleForms := Value;
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

end.
