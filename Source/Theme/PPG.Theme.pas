unit PPG.Theme;

{ Dark Mode ohne VCL-Style (Phase 8.3): anwendungsweiter Modus Hell, Dunkel
  oder System.

  - Mode = tmSystem folgt der Windows-Einstellung "App-Modus"
    (HKCU\...\Themes\Personalize\AppsUseLightTheme) und reagiert auf
    WM_SETTINGCHANGE("ImmersiveColorSet") ueber ein unsichtbares Hilfsfenster.
  - Bei jedem Wechsel bekommen alle PPGlow-Controls die Nachricht
    PPGThemeChangedMessage (per Perform, auch ohne Fensterhandle). Controls
    melden sich dafuer selbst an und ab (AddClient/RemoveClient); diese Unit
    kennt keine Control-Klassen.
  - StyleForms = True faerbt die Formulare (Color, Font.Color) in den Farben
    des Modus und schaltet die Titelleiste dunkel
    (DWMWA_USE_IMMERSIVE_DARK_MODE). Formulare im Designer bleiben unberuehrt.
  - Die Unit setzt beim Laden TPPGRendererRegistry.OnFallbackChanged: nach
    einem Wechsel von ForceGdiFallback zeichnen sich alle Fenster neu
    (Render kennt Theme nicht, deshalb der Haken).

  Rangfolge der Farben in den Controls: Hochkontrast > VCL-Style >
  Dark Mode > Appearance. Die gespeicherte Appearance aendert sich nie.

  Lebenszyklus: Die Unit-Finalisierung laeuft VOR der Zerstoerung der
  Formulare. AddClient/RemoveClient sind deshalb auch danach noch sicher. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, Vcl.Controls, Vcl.Forms,
  PPG.Tokens;

type
  TPPGThemeMode = (tmLight, tmDark, tmSystem);

  /// Liest die Systemeinstellung (True = dunkel). Austauschbar fuer Tests.
  TPPGSystemDarkReader = function: Boolean;

  TPPGTheme = class
  private
    class var FMode: TPPGThemeMode;
    class var FStyleForms: Boolean;
    class var FSystemDark: Boolean;
    class var FSystemRead: Boolean;
    class var FSystemDarkReader: TPPGSystemDarkReader;
    class var FOnChange: TNotifyEvent;
    class procedure SetMode(const Value: TPPGThemeMode); static;
    class procedure SetStyleForms(const Value: Boolean); static;
    class procedure SetSystemDarkReader(const Value: TPPGSystemDarkReader); static;
    class function GetSystemDark: Boolean; static;
  public
    /// Effektiver Modus: True = dunkel.
    class function IsDark: Boolean; static;
    /// Neutrale Fenster-Tokens des aktuellen Modus (Formularfarben).
    class function FormTokens: TPPGTokens; static;
    /// Faerbt ein Formular in den Farben des Modus (auch ohne StyleForms
    /// nutzbar, z.B. fuer Formulare ohne PPGlow-Controls). Nie im Designer.
    class procedure ApplyToForm(Form: TCustomForm); static;
    /// Wird von PPGlow-Controls bei der Fenstererzeugung aufgerufen: faerbt
    /// das Formular bei StyleForms einmalig (bzw. nach neuem Fensterhandle).
    class procedure FormNeeded(Form: TCustomForm); static;
    /// Dunkle bzw. helle Titelleiste (ab Windows 10 1809; sonst wirkungslos).
    class procedure SetDarkTitleBar(Wnd: HWND; Dark: Boolean); static;
    /// Systemeinstellung neu lesen und bei Aenderung alle benachrichtigen.
    class procedure RefreshSystem; static;
    /// Alle Controls (und OnChange) benachrichtigen.
    class procedure Changed; static;
    class procedure AddClient(Client: TControl); static;
    class procedure RemoveClient(Client: TControl); static;
    class function ClientCount: Integer; static;
    /// Hilfsfenster fuer WM_SETTINGCHANGE (0, solange Mode <> tmSystem).
    class function WindowHandle: HWND; static;

    class property Mode: TPPGThemeMode read FMode write SetMode;
    class property StyleForms: Boolean read FStyleForms write SetStyleForms;
    /// Systemeinstellung (zwischengespeichert, aktualisiert per WM_SETTINGCHANGE).
    class property SystemDark: Boolean read GetSystemDark;
    /// nil = Registry. Tests setzen hier eine eigene Funktion.
    class property SystemDarkReader: TPPGSystemDarkReader read FSystemDarkReader
      write SetSystemDarkReader;
    /// Nach jedem Wechsel (nach den Controls), z.B. fuer eigene Fremd-Controls.
    class property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

/// Liest AppsUseLightTheme (fehlt der Wert: hell).
function PPGReadSystemDark: Boolean;

var
  /// Registrierte Nachricht an alle PPGlow-Controls nach einem Theme-Wechsel.
  PPGThemeChangedMessage: Cardinal = 0;

implementation

uses
  System.SysUtils, Vcl.Graphics, PPG.ErrorHandler, PPG.Render.Registry, PPG.Render.Fluent11;

const
  PersonalizeKey = 'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize';
  DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
  DWMWA_USE_IMMERSIVE_DARK_MODE_OLD = 19; // Windows 10 1809..1909

type
  TDwmSetWindowAttribute = function(Wnd: HWND; Attribute: DWORD; Value: Pointer;
    Size: DWORD): HRESULT; stdcall;

  TFormAccess = class(TCustomForm);

  /// Hilfsfenster (WM_SETTINGCHANGE) und Buchfuehrung der gefaerbten Formulare.
  TPPGThemeWatcher = class(TComponent)
  private
    FWnd: HWND;
    FForms: TList;   // TCustomForm
    FHandles: TList; // HWND zum Zeitpunkt des Faerbens (Titelleiste)
    FDarkState: TList; // Modus beim Faerben (Pointer(0/1))
    FOrigColor: TList; // Color und Font.Color vor dem ersten Faerben
    FOrigFont: TList;
    procedure WndProc(var Message: TMessage);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure NeedWindow;
    procedure FreeWindow;
    procedure Track(Form: TCustomForm; Dark: Boolean);
    function IsCurrent(Form: TCustomForm; Dark: Boolean): Boolean;
    /// Stellt die Originalfarben aller gefaerbten Formulare wieder her.
    procedure RestoreAll;
  end;

var
  GClients: TList = nil;
  GWatcher: TPPGThemeWatcher = nil;
  GFinalized: Boolean = False;
  GDwmLib: HMODULE = 0;
  GDwmSet: TDwmSetWindowAttribute = nil;
  GDwmLoaded: Boolean = False;

function Watcher: TPPGThemeWatcher;
begin
  if (GWatcher = nil) and not GFinalized then
    GWatcher := TPPGThemeWatcher.Create(nil);
  Result := GWatcher;
end;

function PPGReadSystemDark: Boolean;
var
  H: HKEY;
  T, L, V: DWORD;
begin
  Result := False;
  if RegOpenKeyEx(HKEY_CURRENT_USER, PersonalizeKey, 0, KEY_READ, H) <> ERROR_SUCCESS then
    Exit;
  try
    V := 1;
    L := SizeOf(V);
    T := 0;
    if (RegQueryValueEx(H, 'AppsUseLightTheme', nil, @T, @V, @L) = ERROR_SUCCESS) and
      (T = REG_DWORD) then
      Result := V = 0;
  finally
    RegCloseKey(H);
  end;
end;

{ TPPGThemeWatcher }

constructor TPPGThemeWatcher.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FForms := TList.Create;
  FHandles := TList.Create;
  FDarkState := TList.Create;
  FOrigColor := TList.Create;
  FOrigFont := TList.Create;
end;

destructor TPPGThemeWatcher.Destroy;
var
  I: Integer;
begin
  FreeWindow;
  if FForms <> nil then
    for I := FForms.Count - 1 downto 0 do
      TCustomForm(FForms[I]).RemoveFreeNotification(Self);
  FreeAndNil(FOrigFont);
  FreeAndNil(FOrigColor);
  FreeAndNil(FDarkState);
  FreeAndNil(FHandles);
  FreeAndNil(FForms);
  inherited Destroy;
end;

procedure TPPGThemeWatcher.NeedWindow;
begin
  if FWnd = 0 then
    FWnd := AllocateHWnd(WndProc);
end;

procedure TPPGThemeWatcher.FreeWindow;
begin
  if FWnd <> 0 then
  begin
    DeallocateHWnd(FWnd);
    FWnd := 0;
  end;
end;

procedure TPPGThemeWatcher.WndProc(var Message: TMessage);
begin
  if (Message.Msg = WM_SETTINGCHANGE) and (Message.LParam <> 0) and
    (StrIComp(PChar(Message.LParam), 'ImmersiveColorSet') = 0) then
  begin
    // Grenze: von Windows angestossen - eine Exception darf das Hilfsfenster
    // nicht verlassen (wie im Timer an Application.HandleException)
    try
      PPGRefreshSystemAccent;
      TPPGTheme.RefreshSystem;
    except
      on E: Exception do
        Application.HandleException(E);
    end;
  end;
  Message.Result := DefWindowProc(FWnd, Message.Msg, Message.WParam, Message.LParam);
end;

procedure TPPGThemeWatcher.Notification(AComponent: TComponent; Operation: TOperation);
var
  I: Integer;
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FForms <> nil) then
  begin
    I := FForms.IndexOf(AComponent);
    if I >= 0 then
    begin
      FForms.Delete(I);
      FHandles.Delete(I);
      FDarkState.Delete(I);
      FOrigColor.Delete(I);
      FOrigFont.Delete(I);
    end;
  end;
end;

procedure TPPGThemeWatcher.Track(Form: TCustomForm; Dark: Boolean);
var
  I: Integer;
  H: HWND;
begin
  H := 0;
  if Form.HandleAllocated then
    H := Form.Handle;
  I := FForms.IndexOf(Form);
  if I < 0 then
  begin
    FForms.Add(Form);
    FHandles.Add(Pointer(H));
    FDarkState.Add(Pointer(Ord(Dark)));
    FOrigColor.Add(Pointer(TFormAccess(Form).Color));
    FOrigFont.Add(Pointer(TFormAccess(Form).Font.Color));
    Form.FreeNotification(Self);
  end
  else
  begin
    FHandles[I] := Pointer(H);
    FDarkState[I] := Pointer(Ord(Dark));
  end;
end;

function TPPGThemeWatcher.IsCurrent(Form: TCustomForm; Dark: Boolean): Boolean;
var
  I: Integer;
begin
  I := FForms.IndexOf(Form);
  Result := (I >= 0) and (FDarkState[I] = Pointer(Ord(Dark))) and
    Form.HandleAllocated and (FHandles[I] = Pointer(Form.Handle));
end;

procedure TPPGThemeWatcher.RestoreAll;
var
  I: Integer;
  F: TCustomForm;
begin
  for I := FForms.Count - 1 downto 0 do
  begin
    F := TCustomForm(FForms[I]);
    if not (csDestroying in F.ComponentState) then
    begin
      TFormAccess(F).Color := TColor(FOrigColor[I]);
      TFormAccess(F).Font.Color := TColor(FOrigFont[I]);
      if F.HandleAllocated then
        TPPGTheme.SetDarkTitleBar(F.Handle, False);
    end;
    F.RemoveFreeNotification(Self);
  end;
  FForms.Clear;
  FHandles.Clear;
  FDarkState.Clear;
  FOrigColor.Clear;
  FOrigFont.Clear;
end;

{ Neuzeichnen nach einem Wechsel des GDI-Rueckfalls (Audit 11e) }

function RedrawThreadWindow(Wnd: HWND; Param: LPARAM): BOOL; stdcall;
begin
  RedrawWindow(Wnd, nil, 0, RDW_INVALIDATE or RDW_ERASE or RDW_FRAME or RDW_ALLCHILDREN);
  Result := True;
end;

/// Haken fuer TPPGRendererRegistry.OnFallbackChanged: alle Fenster des
/// Hauptthreads (Formulare, Popups, Hints, Toasts) samt Kindfenstern neu
/// zeichnen. Nur ungueltig machen; gezeichnet wird mit dem naechsten WM_PAINT.
procedure PPGRedrawAllWindows;
begin
  if GetCurrentThreadId <> MainThreadID then
    Exit;
  EnumThreadWindows(GetCurrentThreadId, @RedrawThreadWindow, 0);
end;

{ TPPGTheme }

class function TPPGTheme.GetSystemDark: Boolean;
begin
  if not FSystemRead then
  begin
    if Assigned(FSystemDarkReader) then
      FSystemDark := FSystemDarkReader()
    else
      FSystemDark := PPGReadSystemDark;
    FSystemRead := True;
  end;
  Result := FSystemDark;
end;

class function TPPGTheme.IsDark: Boolean;
begin
  case FMode of
    tmDark: Result := True;
    tmSystem: Result := GetSystemDark;
  else
    Result := False;
  end;
end;

class function TPPGTheme.FormTokens: TPPGTokens;
begin
  Result := PPGDefaultTokens(IsDark);
end;

class procedure TPPGTheme.SetMode(const Value: TPPGThemeMode);
begin
  if FMode = Value then
    Exit;
  FMode := Value;
  if Watcher <> nil then
    if FMode = tmSystem then
    begin
      FSystemRead := False; // beim Umschalten frisch lesen
      Watcher.NeedWindow;
    end
    else
      Watcher.FreeWindow;
  Changed;
end;

class procedure TPPGTheme.SetStyleForms(const Value: Boolean);
begin
  if FStyleForms = Value then
    Exit;
  FStyleForms := Value;
  // Ausschalten: Formulare bekommen ihre urspruenglichen Farben zurueck
  if not Value and (GWatcher <> nil) then
    GWatcher.RestoreAll;
  Changed;
end;

class procedure TPPGTheme.SetSystemDarkReader(const Value: TPPGSystemDarkReader);
begin
  FSystemDarkReader := Value;
  FSystemRead := False;
end;

class procedure TPPGTheme.RefreshSystem;
var
  Old: Boolean;
begin
  Old := IsDark;
  FSystemRead := False;
  // Auch ohne Wechsel des Modus benachrichtigen: der Systemakzent kann sich
  // geaendert haben (gleiche Nachricht "ImmersiveColorSet")
  if (FMode = tmSystem) or (Old <> IsDark) then
    Changed;
end;

class procedure TPPGTheme.SetDarkTitleBar(Wnd: HWND; Dark: Boolean);
var
  V: BOOL;
begin
  if (Wnd = 0) or not IsWindow(Wnd) then
    Exit;
  if not GDwmLoaded then
  begin
    GDwmLoaded := True;
    GDwmLib := LoadLibrary('dwmapi.dll');
    if GDwmLib <> 0 then
      @GDwmSet := GetProcAddress(GDwmLib, 'DwmSetWindowAttribute');
  end;
  if not Assigned(GDwmSet) then
    Exit;
  V := Dark;
  // Aeltere Windows-Versionen kennen das Attribut nicht: kein Fehlerfall,
  // die Titelleiste bleibt dann einfach hell
  if Failed(GDwmSet(Wnd, DWMWA_USE_IMMERSIVE_DARK_MODE, @V, SizeOf(V))) then
    GDwmSet(Wnd, DWMWA_USE_IMMERSIVE_DARK_MODE_OLD, @V, SizeOf(V));
  // Neu zeichnen lassen, sonst wechselt die Titelleiste erst beim naechsten
  // Aktivieren
  SetWindowPos(Wnd, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or
    SWP_NOACTIVATE or SWP_FRAMECHANGED);
end;

class procedure TPPGTheme.ApplyToForm(Form: TCustomForm);
var
  T: TPPGTokens;
  Dark: Boolean;
begin
  if (Form = nil) or (csDesigning in Form.ComponentState) or
    (csDestroying in Form.ComponentState) then
    Exit;
  Dark := IsDark;
  T := PPGDefaultTokens(Dark);
  // Zuerst merken (Originalfarben fuer RestoreAll), dann faerben
  if Watcher <> nil then
    Watcher.Track(Form, Dark);
  TFormAccess(Form).Color := T.Background;
  TFormAccess(Form).Font.Color := T.TextPrimary;
  if Form.HandleAllocated then
    SetDarkTitleBar(Form.Handle, Dark);
end;

class procedure TPPGTheme.FormNeeded(Form: TCustomForm);
begin
  if not FStyleForms or (Form = nil) or (Watcher = nil) then
    Exit;
  if not Watcher.IsCurrent(Form, IsDark) then
    ApplyToForm(Form);
end;

class procedure TPPGTheme.Changed;
var
  Copy: TList;
  I: Integer;
  Form: TCustomForm;
begin
  // Jeder Empfaenger einzeln abgesichert (wie TPPGAnimator.TimerTick):
  // ein fehlerhaftes Form/Control darf den Wechsel fuer die uebrigen nicht
  // abbrechen, sonst steht die Anwendung halb im alten, halb im neuen Theme.
  if FStyleForms then
    for I := 0 to Screen.FormCount - 1 do
    begin
      Form := Screen.Forms[I];
      try
        ApplyToForm(Form);
      except
        on E: Exception do
          TPPGErrorHandler.HandleCallbackError(Form, E, 'Theme.ApplyToForm');
      end;
    end;
  if GClients <> nil then
  begin
    // Kopie: ein Control darf im Handler andere Controls erzeugen/freigeben
    Copy := TList.Create;
    try
      Copy.Assign(GClients);
      for I := 0 to Copy.Count - 1 do
        if GClients.IndexOf(Copy[I]) >= 0 then
          try
            TControl(Copy[I]).Perform(PPGThemeChangedMessage, 0, 0);
          except
            on E: Exception do
              // Sender nur, solange das Control noch angemeldet ist
              if GClients.IndexOf(Copy[I]) >= 0 then
                TPPGErrorHandler.HandleCallbackError(TControl(Copy[I]), E, 'Theme.Changed')
              else
                TPPGErrorHandler.HandleCallbackError(nil, E, 'Theme.Changed');
          end;
    finally
      Copy.Free;
    end;
  end;
  if Assigned(FOnChange) then
    FOnChange(nil);
end;

class procedure TPPGTheme.AddClient(Client: TControl);
begin
  if (Client = nil) or GFinalized then
    Exit;
  if GClients = nil then
    GClients := TList.Create;
  GClients.Add(Client);
end;

class procedure TPPGTheme.RemoveClient(Client: TControl);
var
  I: Integer;
begin
  if GClients = nil then
    Exit;
  // Von hinten suchen: Komponenten werden meist in umgekehrter Reihenfolge
  // freigegeben (TComponent.DestroyComponents), das bleibt so O(1)
  for I := GClients.Count - 1 downto 0 do
    if GClients[I] = Client then
    begin
      GClients.Delete(I);
      Exit;
    end;
end;

class function TPPGTheme.ClientCount: Integer;
begin
  if GClients = nil then
    Result := 0
  else
    Result := GClients.Count;
end;

class function TPPGTheme.WindowHandle: HWND;
begin
  if GWatcher = nil then
    Result := 0
  else
    Result := GWatcher.FWnd;
end;

initialization
  PPGThemeChangedMessage := RegisterWindowMessage('PPGlow.ThemeChanged');
  // Render kennt Theme nicht: das Neuzeichnen nach ForceGdiFallback kommt von hier
  TPPGRendererRegistry.OnFallbackChanged := PPGRedrawAllWindows;

finalization
  // Die Registry lebt laenger (Unit wird spaeter finalisiert): Haken abmelden
  TPPGRendererRegistry.OnFallbackChanged := nil;
  GFinalized := True;
  FreeAndNil(GWatcher);
  FreeAndNil(GClients);
  if GDwmLib <> 0 then
    FreeLibrary(GDwmLib);

end.
