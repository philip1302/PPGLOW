unit PPG.Controls.Base;

{ TPPGCustomControl - gemeinsame Basis ALLER PPGlow-Controls.

  Verantwortung (nur Zustand, Input, Lebenszyklus - Zeichnen macht der Renderer):
  - Zustandsmaschine Normal/Hot/Down/Disabled + Fokus, animiert
  - Maus (inkl. Capture-Verlust), Fokus, Enabled, Fokus-Cues
  - Paint-Pipeline mit Offscreen-Puffer und Fehlergrenze
  - Referenzen auf StyleManager/ImageList mit FreeNotification
  - DPI: logische Masse, Skalierung beim Zeichnen (PPG.DpiUtils)

  Stolpersteine, die hier bewusst behandelt werden:
  - TControl.WMLButtonUp ruft Click VOR MouseUp auf. Der Pressed-Zustand wird
    deshalb schon in WM_LBUTTONUP zurueckgesetzt. Sonst bliebe der Button
    waehrend eines modalen Dialogs in OnClick "gedrueckt", bzw. haengt nach
    einer Exception in OnClick.
  - Exceptions im Paint werden nie weitergeworfen (WM_PAINT-Endlosschleife),
    sondern einmalig gemeldet; es wird ein einfacher Notfall-Zustand gezeichnet.
  - Paint sendet KEINE Fensternachrichten (auch kein SendMessage an sich
    selbst): Die VCL ruft nach jeder Nachricht FreeMemoryContexts auf und
    gibt dabei den DC einer Ziel-TBitmap frei -> PaintTo/Drucken/Screenshots
    scheitern mit "ungueltiges Handle". UI-Zustand wird deshalb gecacht.
  - Offscreen-Puffer wird pro Paint angelegt und sofort freigegeben:
    keine dauerhaften GDI-Handles pro Control (wichtig bei 1000+ Controls). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  {$IFDEF PPG_HAS_IMAGENAME}System.UITypes,{$ENDIF}
  Vcl.Controls, Vcl.Graphics, Vcl.ImgList,
  PPG.Types, PPG.Appearance, PPG.Animation, PPG.Layout, PPG.Tokens,
  PPG.Render.Intf, PPG.StyleManager, PPG.Accessibility;

type
  TPPGCustomControl = class(TCustomControl, IPPGStyleClient, IPPGAccessibleHost)
  private
    FAppearance: TPPGAppearance;
    FAnimation: TPPGAnimationSettings;
    FStyleManager: TPPGStyleManager;
    FPreset: string;
    FRenderer: IPPGRenderer;
    FImages: TCustomImageList;
    FImageChangeLink: TChangeLink;
    FImageIndex: TPPGImageIndex;
    FHotImageIndex: TPPGImageIndex;
    FDisabledImageIndex: TPPGImageIndex;
    FImagePosition: TPPGImagePosition;
    FSpacing: Integer;
    FWordWrap: Boolean;
    FShowFocusRect: Boolean;
    FHighContrastSupport: Boolean;
    FMouseInside: Boolean;
    FMousePressed: Boolean;
    FKeyPressed: Boolean;
    FHotAnim: TPPGAnimation;
    FDownAnim: TPPGAnimation;
    FUpdateCount: Integer;
    FInvalidatePending: Boolean;
    FPaintErrorReported: Boolean;
    FUIState: Cardinal; // Cache von WM_QUERYUISTATE (Paint darf keine Nachrichten senden)
    FAccessible: TPPGAccessible;
    FAccessibleRef: IInterface; // haelt das COM-Objekt am Leben
    FStyledAppearance: TPPGAppearance; // Cache: Appearance mit Farben des VCL-Styles bzw. Dark Mode
    FStyledKind: Byte; // Inhalt des Caches: 0 = leer, 1 = VCL-Style, 2 = Dark Mode
    {$IFDEF PPG_HAS_IMAGENAME}
    FImageName: TImageName;
    procedure SetImageName(const Value: TImageName);
    {$ENDIF}
    procedure ResolveImageName;
    procedure InvalidateStyledAppearance;
    procedure ReleaseAccessible;
    procedure RefreshUIState;
    procedure SetAppearance(const Value: TPPGAppearance);
    procedure SetAnimation(const Value: TPPGAnimationSettings);
    procedure SetStyleManager(const Value: TPPGStyleManager);
    procedure SetPreset(const Value: string);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetImageIndex(const Value: TPPGImageIndex);
    procedure SetHotImageIndex(const Value: TPPGImageIndex);
    procedure SetDisabledImageIndex(const Value: TPPGImageIndex);
    procedure SetImagePosition(const Value: TPPGImagePosition);
    procedure SetSpacing(const Value: Integer);
    procedure SetWordWrap(const Value: Boolean);
    procedure SetShowFocusRect(const Value: Boolean);
    procedure SetHighContrastSupport(const Value: Boolean);
    procedure AppearanceChanged(Sender: TObject);
    procedure AnimationSettingsChanged(Sender: TObject);
    procedure AnimationStep(Sender: TObject);
    procedure ImageListChange(Sender: TObject);
    procedure ApplyStyleManager;
    function CheckImageIndex(const PropName: string; Value: TPPGImageIndex): TPPGImageIndex;
    procedure PaintFallback(ACanvas: TCanvas);
    procedure FillBackground(DC: HDC; const R: TRect);
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMSysColorChange(var Message: TMessage); message CM_SYSCOLORCHANGE;
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
    procedure CMBiDiModeChanged(var Message: TMessage); message CM_BIDIMODECHANGED;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMLButtonUp(var Message: TWMLButtonUp); message WM_LBUTTONUP;
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
    procedure WMUpdateUIState(var Message: TMessage); message WM_UPDATEUISTATE;
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
    procedure WMGetObject(var Message: TMessage); message WM_GETOBJECT;
  public
    /// Streaming: Optik wird nur ohne StyleManager lokal gespeichert.
    /// (Vor den Properties deklariert - Delphi verlangt das fuer "stored".)
    function IsPresetStored: Boolean;
    function IsStyleStored: Boolean;
    /// True, wenn die ImageList Bilder per Name verwaltet (TVirtualImageList, ab 10.4).
    function ImageNameAvailable: Boolean;
    function IsImageIndexStoredByName: Boolean;
    function IsImageNameStored: Boolean;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure WndProc(var Message: TMessage); override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    /// Auch ohne Fensterhandle wirksam (TWinControl.AdjustSize ist es nicht).
    procedure AdjustSize; override;
    /// Bevorzugte Groesse fuer AutoSize. False = keine Aenderung.
    function CalcAutoSize(out AWidth, AHeight: Integer): Boolean; virtual;
    /// Zusaetzliche Breite fuer AutoSize (z.B. Pfeilbereich des Split-Buttons).
    function AutoSizeExtraWidth: Integer; virtual;
    /// False = AutoSize bestimmt nur die Hoehe; die Breite gehoert dem Anwender
    /// (z.B. InfoBar, ToolBar, StatusBar).
    function AutoSizeWidth: Boolean; virtual;
    /// Loest bei AutoSize=True eine Neuberechnung der Groesse aus.
    procedure RequestAutoSize;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    /// Accelerator (&-Taste) gedrueckt. Standard: Click. Auswahl-Controls
    /// setzen zusaetzlich den Fokus.
    procedure DoAccelerator; virtual;
    /// Fortschritt der Hover-/Druck-Animation (0..1) fuer eigene Stil-Berechnungen.
    function HotProgress: Single;
    function DownProgress: Single;
    function AcceleratorCuesVisible: Boolean;

    { Barrierefreiheit (IPPGAccessibleHost) - abgeleitete Controls ueberschreiben
      Rolle, Zustand und Standardaktion. }
    function AccName: string; virtual;
    function AccRole: Integer; virtual;
    function AccState: Integer; virtual;
    function AccDescription: string; virtual;
    function AccValue: string; virtual;
    function AccKeyboardShortcut: string; virtual;
    function AccDefaultAction: string; virtual;
    procedure AccDoDefaultAction; virtual;
    /// Meldet eine Aenderung an Screenreader (z.B. EVENT_OBJECT_STATECHANGE).
    procedure NotifyAccessibility(Event: DWORD);
    /// Wie NotifyAccessibility, fuer ein virtuelles Kind (IPPGAccessibleChildren).
    procedure NotifyAccessibilityChild(Event: DWORD; ChildId: Integer);
    procedure Paint; override;

    { Zustand }
    function IsDown: Boolean; virtual;
    function IsHot: Boolean; virtual;
    function GetVisualState: TPPGVisualState; virtual;
    function FocusVisible: Boolean; virtual;
    procedure SetKeyPressed(Value: Boolean);
    procedure UpdateVisualState(Animate: Boolean = True); virtual;
    procedure ResetInteractionState;
    /// Hook nach jeder Aenderung der Appearance (z.B. Container: Kinder neu ausrichten).
    procedure AppearanceUpdated; virtual;
    /// Hell/Dunkel gewechselt (TPPGTheme). Standard: Farben neu aufbauen,
    /// AppearanceUpdated, neu zeichnen.
    procedure ThemeChanged; virtual;
    /// Farbe hinter dem Koerper (abgerundete Ecken). Standard: Color.
    function GetBackgroundColor: TColor; virtual;
    /// Schneller Eltern-Hintergrund: liefert ein Container die Farbe(n) seiner
    /// Flaeche unter Child (oben/unten, linearer Verlauf), fuellt das Kind
    /// selbst, statt den ganzen Container per DrawParentBackground zeichnen zu
    /// lassen. False = nicht einfach (dann der langsame, exakte Weg).
    function GetChildBackground(Child: TControl; out ColorTop, ColorBottom: TColor): Boolean; virtual;

    { Zeichnen - Erweiterungspunkte fuer abgeleitete Controls (Open/Closed) }
    function GetCurrentStyle: TPPGSurfaceStyle; virtual;
    function GetBodyRect(const Style: TPPGSurfaceStyle): TRect; virtual;
    /// Koerper-Rechteck wie beim Zeichnen (fuer Hit-Tests, z.B. Split-Button).
    function LayoutBodyRect: TRect;
    function GetContentRect(const Body: TRect; const Style: TPPGSurfaceStyle): TRect; virtual;
    function GetCurrentImageIndex: Integer; virtual;
    function GetTextFlags: Cardinal; virtual;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); virtual;
    procedure DoPaintBackground(const ACanvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle); virtual;
    procedure DoPaintContent(const ACanvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle); virtual;
    procedure DoPaintOverlay(const ACanvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle); virtual;
    procedure DoPaintCaption(const ACanvas: IPPGCanvas; const Content: TRect;
      const Style: TPPGSurfaceStyle); virtual;

    { IPPGStyleClient }
    procedure StyleManagerChanged(Sender: TObject);

    property MouseInside: Boolean read FMouseInside;
    property MousePressed: Boolean read FMousePressed;
    property KeyPressed: Boolean read FKeyPressed;

    { Gemeinsame Properties - in den Endklassen published }
    property Preset: string read FPreset write SetPreset stored IsPresetStored;
    property StyleManager: TPPGStyleManager read FStyleManager write SetStyleManager;
    property Appearance: TPPGAppearance read FAppearance write SetAppearance stored IsStyleStored;
    property Animation: TPPGAnimationSettings read FAnimation write SetAnimation stored IsStyleStored;
    property Images: TCustomImageList read FImages write SetImages;
    property ImageIndex: TPPGImageIndex read FImageIndex write SetImageIndex
      stored IsImageIndexStoredByName default -1;
    {$IFDEF PPG_HAS_IMAGENAME}
    property ImageName: TImageName read FImageName write SetImageName stored IsImageNameStored;
    {$ENDIF}
    property HotImageIndex: TPPGImageIndex read FHotImageIndex write SetHotImageIndex default -1;
    property DisabledImageIndex: TPPGImageIndex read FDisabledImageIndex write SetDisabledImageIndex default -1;
    property ImagePosition: TPPGImagePosition read FImagePosition write SetImagePosition default ipLeft;
    property Spacing: Integer read FSpacing write SetSpacing default 4;
    property WordWrap: Boolean read FWordWrap write SetWordWrap default False;
    property ShowFocusRect: Boolean read FShowFocusRect write SetShowFocusRect default True;
    property HighContrastSupport: Boolean read FHighContrastSupport write SetHighContrastSupport default True;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Invalidate; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    /// Setzt Appearance auf die Vorgaben des aktuellen Presets zurueck.
    procedure ResetToPresetDefaults;
    /// Aktuelle PPI fuer die Skalierung (CurrentPPI ab 10.3, sonst System-DPI).
    function ScalePPI: Integer; virtual;
    /// True, wenn ein VCL-Style aktiv ist und das Control ihm folgen soll
    /// (ab XE3 steuerbar ueber StyleElements/seClient).
    function UseVclStyle: Boolean;
    /// True, wenn der Dark Mode (TPPGTheme) fuer dieses Control gilt: dunkler
    /// Modus, kein VCL-Style, kein Hochkontrast (ab XE3 zusaetzlich seClient).
    function UseDarkMode: Boolean;
    /// Die beim Zeichnen tatsaechlich verwendete Appearance. Rangfolge:
    /// VCL-Style (Formen aus dem Preset, Farben aus dem Style) > Dark Mode
    /// (Formen aus der Appearance, dunkle Farben des Presets) > Appearance.
    /// Hochkontrast ersetzen die Controls selbst beim Zeichnen.
    function EffectiveAppearance: TPPGAppearance;
    /// Design-Tokens des Presets (semantische Farben, Masse, Dauern), z.B.
    /// Signalfarben fuer Fehler/Warnung. Presets ohne eigene Tokens liefern die
    /// neutrale Windows-11-Palette.
    function Tokens: TPPGTokens;
    property Renderer: IPPGRenderer read FRenderer;
    property VisualState: TPPGVisualState read GetVisualState;
  end;

implementation

uses
  System.SysUtils, Vcl.Forms, Vcl.Themes,
  PPG.Consts, PPG.Exceptions, PPG.ErrorHandler, PPG.DpiUtils,
  PPG.Render.Registry, PPG.Render.Gdi, PPG.Presets, PPG.VclStyles, PPG.Theme,
  Winapi.oleacc;

var
  GMsgAccDefaultAction: Cardinal = 0;

const
  PPGMaxSpacing = 100;
  ContentPadding = 4; // logische px zwischen Rahmen und Inhalt

{ TPPGCustomControl }

constructor TPPGCustomControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csCaptureMouse, csClickEvents, csSetCaption, csReplicatable,
    csParentBackground, csDoubleClicks];
  Width := 100;
  Height := 32;
  FImageIndex := -1;
  FHotImageIndex := -1;
  FDisabledImageIndex := -1;
  FImagePosition := ipLeft;
  FSpacing := 4;
  FShowFocusRect := True;
  FHighContrastSupport := True;

  FAppearance := TPPGAppearance.Create(Self);
  FAppearance.OnChange := AppearanceChanged;
  FAnimation := TPPGAnimationSettings.Create(Self);
  FAnimation.OnChange := AnimationSettingsChanged;
  FHotAnim := TPPGAnimation.Create(Self);
  FHotAnim.OnStep := AnimationStep;
  FDownAnim := TPPGAnimation.Create(Self);
  FDownAnim.OnStep := AnimationStep;
  FImageChangeLink := TChangeLink.Create;
  FImageChangeLink.OnChange := ImageListChange;

  SetPreset(TPPGRendererRegistry.DefaultName);
  TPPGTheme.AddClient(Self);
end;

destructor TPPGCustomControl.Destroy;
begin
  // Reihenfolge: zuerst Abmeldungen (andere Objekte zeigen auf uns),
  // dann eigene Objekte. Alles nil-sicher, da Destroy auch nach einer
  // Exception im Konstruktor laeuft.
  TPPGTheme.RemoveClient(Self); // sicher, auch nach der Unit-Finalisierung
  ReleaseAccessible; // Screenreader koennen das Objekt noch halten
  if FStyleManager <> nil then
    FStyleManager.RemoveClient(Self);
  FStyleManager := nil;
  if FHotAnim <> nil then
    FHotAnim.OnStep := nil;
  if FDownAnim <> nil then
    FDownAnim.OnStep := nil;
  FreeAndNil(FHotAnim);   // meldet sich selbst beim Animator ab
  FreeAndNil(FDownAnim);
  FreeAndNil(FImageChangeLink); // meldet sich bei der ImageList ab
  if FAppearance <> nil then
    FAppearance.OnChange := nil;
  if FAnimation <> nil then
    FAnimation.OnChange := nil;
  FreeAndNil(FStyledAppearance);
  FreeAndNil(FAnimation);
  FreeAndNil(FAppearance);
  FRenderer := nil;
  inherited Destroy;
end;

procedure TPPGCustomControl.CreateWnd;
begin
  inherited CreateWnd;
  RefreshUIState;
  // StyleForms: das Formular einmalig (bzw. nach neuem Fensterhandle) faerben
  TPPGTheme.FormNeeded(GetParentForm(Self));
end;

procedure TPPGCustomControl.RefreshUIState;
begin
  FUIState := PPGQueryUIState(Self);
end;

procedure TPPGCustomControl.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Neu zeichnen bei Groessenaenderung (abgerundete Ecken, Zentrierung)
  Params.WindowClass.style := Params.WindowClass.style or CS_HREDRAW or CS_VREDRAW;
end;

procedure TPPGCustomControl.Loaded;
begin
  inherited Loaded;
  if FRenderer = nil then
    SetPreset(TPPGRendererRegistry.DefaultName);
  if FStyleManager <> nil then
    ApplyStyleManager;
  // Images ist erst jetzt verbunden (Fixup nach dem Lesen der Properties)
  ResolveImageName;
  UpdateVisualState(False);
  RequestAutoSize;
  Invalidate;
end;

{ ---- Bildnamen (TVirtualImageList/TImageCollection, ab 10.4) ---- }

function TPPGCustomControl.ImageNameAvailable: Boolean;
begin
{$IFDEF PPG_HAS_IMAGENAME}
  Result := (FImages <> nil) and FImages.IsImageNameAvailable;
{$ELSE}
  Result := False;
{$ENDIF}
end;

function TPPGCustomControl.IsImageIndexStoredByName: Boolean;
begin
  // Mit Namen wird nur ImageName gespeichert (robust gegen Umsortieren)
  Result := (FImageIndex <> -1) and not ImageNameAvailable;
end;

function TPPGCustomControl.IsImageNameStored: Boolean;
begin
{$IFDEF PPG_HAS_IMAGENAME}
  Result := ImageNameAvailable and (FImageName <> '');
{$ELSE}
  Result := False;
{$ENDIF}
end;

procedure TPPGCustomControl.ResolveImageName;
begin
{$IFDEF PPG_HAS_IMAGENAME}
  if (csLoading in ComponentState) or not ImageNameAvailable or (FImageName = '') then
    Exit;
  // Unbekannter Name -> -1 (kein Bild), keine Exception: die ImageList kann
  // zur Laufzeit befuellt werden
  FImageIndex := FImages.GetIndexByName(FImageName);
{$ENDIF}
end;

{$IFDEF PPG_HAS_IMAGENAME}
procedure TPPGCustomControl.SetImageName(const Value: TImageName);
begin
  if FImageName = Value then
    Exit;
  FImageName := Value;
  ResolveImageName;
  RequestAutoSize;
  Invalidate;
end;
{$ENDIF}

{ ---- AutoSize ---- }

procedure TPPGCustomControl.AdjustSize;
begin
  // Wird u.a. von TControl.SetAutoSize aufgerufen
  RequestAutoSize;
  inherited AdjustSize;
end;

procedure TPPGCustomControl.RequestAutoSize;
var
  W, H: Integer;
begin
  // Groesse selbst berechnen und direkt setzen. Weder AdjustSize noch
  // SetBounds(Left, Top, Width, Height) reichen bei TWinControl:
  // - AdjustSize tut ohne Fensterhandle nichts,
  // - SetBounds mit unveraenderten Werten wird vorab verworfen.
  if not AutoSize or (csLoading in ComponentState) or
    (csDestroying in ComponentState) then
    Exit;
  W := Width;
  H := Height;
  if CanAutoSize(W, H) and ((W <> Width) or (H <> Height)) then
    SetBounds(Left, Top, W, H);
end;

function TPPGCustomControl.AutoSizeExtraWidth: Integer;
begin
  Result := 0;
end;

function TPPGCustomControl.AutoSizeWidth: Boolean;
begin
  Result := True;
end;

function TPPGCustomControl.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
var
  W, H: Integer;
begin
  Result := True;
  if (csLoading in ComponentState) or not CalcAutoSize(W, H) then
    Exit;
  // Ausgerichtete Kanten gehoeren dem Parent
  if AutoSizeWidth and not (Align in [alTop, alBottom, alClient]) then
    NewWidth := W;
  if not (Align in [alLeft, alRight, alClient]) then
    NewHeight := H;
end;

function TPPGCustomControl.CalcAutoSize(out AWidth, AHeight: Integer): Boolean;
var
  PPI, Inset, BW, Pad, HPad, Gap, MaxTextW, ContentW, ContentH: Integer;
  MaxStyle: TPPGSurfaceStyle;
  Img, TS: TSize;
  Text: string;
begin
  PPI := ScalePPI;
  MaxStyle := EffectiveAppearance.Resolve(vsHot, PPI, False);
  Inset := 0;
  if FRenderer <> nil then
    Inset := FRenderer.BodyInset(MaxStyle);
  BW := MaxStyle.BorderWidth;
  Pad := PPGScale(ContentPadding, PPI);
  HPad := PPGScale(8, PPI); // Buttons wirken mit etwas Luft links/rechts besser

  Img.cx := 0;
  Img.cy := 0;
  if (FImages <> nil) and (FImageIndex >= 0) and (FImageIndex < FImages.Count) then
  begin
    Img.cx := FImages.Width;
    Img.cy := FImages.Height;
  end;

  Text := Caption;
  TS.cx := 0;
  TS.cy := 0;
  if Text <> '' then
  begin
    MaxTextW := 0;
    if FWordWrap then
    begin
      // Umbruch: Breite bleibt, nur die Hoehe passt sich an
      MaxTextW := Width - 2 * (Inset + BW + Pad + HPad) - AutoSizeExtraWidth;
      if FImagePosition in [ipLeft, ipRight] then
        Dec(MaxTextW, Img.cx + PPGScale(FSpacing, PPI));
      if MaxTextW < 1 then
        MaxTextW := 1;
    end;
    TS := PPGMeasureTextNoCanvas(Text, Font, MaxTextW, FWordWrap);
  end;

  if (Img.cx > 0) and (TS.cx > 0) then
    Gap := PPGScale(FSpacing, PPI)
  else
    Gap := 0;
  if FImagePosition in [ipLeft, ipRight] then
  begin
    ContentW := Img.cx + Gap + TS.cx;
    ContentH := Img.cy;
    if TS.cy > ContentH then
      ContentH := TS.cy;
  end
  else
  begin
    ContentW := Img.cx;
    if TS.cx > ContentW then
      ContentW := TS.cx;
    ContentH := Img.cy + Gap + TS.cy;
  end;
  if ContentH < PPGScale(16, PPI) then
    ContentH := PPGScale(16, PPI);

  if FWordWrap then
    AWidth := Width
  else
    AWidth := ContentW + 2 * (Inset + BW + Pad + HPad) + AutoSizeExtraWidth;
  AHeight := ContentH + 2 * (Inset + BW + Pad);
  Result := True;
end;

procedure TPPGCustomControl.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation <> opRemove then
    Exit;
  if AComponent = FImages then
  begin
    FImages := nil;
    Invalidate;
  end;
  if AComponent = FStyleManager then
  begin
    // Manager wird zerstoert: aktuelle Optik bleibt erhalten und wird ab
    // jetzt wieder lokal gespeichert.
    FStyleManager := nil;
    Invalidate;
  end;
end;

{ ---- Update-Steuerung ---- }

procedure TPPGCustomControl.Invalidate;
begin
  Assert(GetCurrentThreadId = MainThreadID,
    Format(SPPGNotMainThread, [ClassName]));
  if FUpdateCount > 0 then
  begin
    FInvalidatePending := True;
    Exit;
  end;
  inherited Invalidate;
end;

procedure TPPGCustomControl.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TPPGCustomControl.EndUpdate;
begin
  Assert(FUpdateCount > 0, 'EndUpdate without BeginUpdate');
  if FUpdateCount > 0 then
    Dec(FUpdateCount);
  if (FUpdateCount = 0) and FInvalidatePending then
  begin
    FInvalidatePending := False;
    Invalidate;
  end;
end;

function TPPGCustomControl.ScalePPI: Integer;
begin
  Result := PPGControlPPI(Self);
end;

function TPPGCustomControl.UseVclStyle: Boolean;
begin
  Result := PPGVclStyleActive;
{$IFDEF PPG_HAS_STYLEELEMENTS}
  // seClient abgewaehlt -> Control behaelt bewusst seine eigenen Farben
  Result := Result and (seClient in StyleElements);
{$ENDIF}
end;

function TPPGCustomControl.UseDarkMode: Boolean;
begin
  Result := TPPGTheme.IsDark and not UseVclStyle and
    not (FHighContrastSupport and PPGIsHighContrast);
{$IFDEF PPG_HAS_STYLEELEMENTS}
  // seClient abgewaehlt -> Control behaelt bewusst seine eigenen Farben
  Result := Result and (seClient in StyleElements);
{$ENDIF}
end;

function TPPGCustomControl.EffectiveAppearance: TPPGAppearance;
var
  Kind: Byte;
  TR: IPPGThemeRenderer;
begin
  if UseVclStyle then
    Kind := 1
  else if UseDarkMode then
    Kind := 2
  else
    Exit(FAppearance);
  if (FStyledAppearance <> nil) and (FStyledKind <> Kind) then
    InvalidateStyledAppearance;
  if FStyledAppearance = nil then
  begin
    FStyledAppearance := TPPGAppearance.Create(nil);
    try
      FStyledAppearance.Assign(FAppearance);  // Formen aus Appearance/Preset
      if Kind = 1 then
        PPGApplyVclStyleColors(FStyledAppearance) // Farben aus dem Style
      else
      begin
        // Dunkle Farben des Presets; fremde Renderer ohne Tokens nehmen die
        // des Standard-Presets
        if not Supports(FRenderer, IPPGThemeRenderer, TR) then
          Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
            IPPGThemeRenderer, TR);
        if TR <> nil then
          TR.ApplyThemeColors(FStyledAppearance, True);
      end;
    except
      FreeAndNil(FStyledAppearance);
      raise;
    end;
    FStyledKind := Kind;
  end;
  Result := FStyledAppearance;
end;

procedure TPPGCustomControl.InvalidateStyledAppearance;
begin
  // Bei Style-/Theme-Wechsel oder geaenderter Appearance neu aufbauen
  FreeAndNil(FStyledAppearance);
  FStyledKind := 0;
end;

procedure TPPGCustomControl.ThemeChanged;
begin
  InvalidateStyledAppearance;
  AppearanceUpdated;
  Invalidate;
end;

{ ---- Style / Preset ---- }

function TPPGCustomControl.IsPresetStored: Boolean;
begin
  Result := FStyleManager = nil;
end;

function TPPGCustomControl.IsStyleStored: Boolean;
begin
  // Mit StyleManager kommt die Optik vom Manager -> nicht doppelt speichern
  Result := FStyleManager = nil;
end;

procedure TPPGCustomControl.SetPreset(const Value: string);
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
    NewName := TPPGRendererRegistry.DefaultName;
    TPPGErrorHandler.LogWarning(Self, Format(SPPGUnknownPresetFallback,
      [Value, PPGDisplayName(Self), NewName]));
    R := TPPGRendererRegistry.Get(NewName);
  end;
  if (FRenderer <> nil) and SameText(FPreset, NewName) then
    Exit;
  FPreset := NewName;
  FRenderer := R;
  // Beim Laden kommen die Farben aus der DFM (Appearance wird nach Preset
  // gestreamt), sonst aus dem Preset.
  if not (csLoading in ComponentState) then
    FRenderer.ApplyDefaults(FAppearance);
  Invalidate;
end;

procedure TPPGCustomControl.ResetToPresetDefaults;
begin
  if FRenderer <> nil then
    FRenderer.ApplyDefaults(FAppearance);
end;

procedure TPPGCustomControl.SetStyleManager(const Value: TPPGStyleManager);
begin
  if FStyleManager = Value then
    Exit;
  if FStyleManager <> nil then
    FStyleManager.RemoveClient(Self);
  FStyleManager := Value;
  if FStyleManager <> nil then
  begin
    FStyleManager.AddClient(Self); // inkl. FreeNotification (beidseitig)
    ApplyStyleManager;
  end;
end;

procedure TPPGCustomControl.StyleManagerChanged(Sender: TObject);
begin
  if Sender = FStyleManager then
    ApplyStyleManager;
end;

procedure TPPGCustomControl.ApplyStyleManager;
var
  R: IPPGRenderer;
begin
  if (FStyleManager = nil) or (csLoading in ComponentState) then
    Exit;
  R := TPPGRendererRegistry.Find(FStyleManager.Preset);
  if R <> nil then
  begin
    FRenderer := R;
    FPreset := FStyleManager.Preset;
  end;
  FAppearance.BeginUpdate;
  try
    FAppearance.Assign(FStyleManager.Appearance);
  finally
    FAppearance.EndUpdate;
  end;
  FAnimation.Assign(FStyleManager.Animation);
  Invalidate;
end;

procedure TPPGCustomControl.SetAppearance(const Value: TPPGAppearance);
begin
  FAppearance.Assign(Value);
end;

procedure TPPGCustomControl.SetAnimation(const Value: TPPGAnimationSettings);
begin
  FAnimation.Assign(Value);
end;

procedure TPPGCustomControl.AppearanceChanged(Sender: TObject);
begin
  InvalidateStyledAppearance;
  RequestAutoSize; // Rahmen/Glow-Groesse beeinflussen die Wunschgroesse
  Invalidate;
  AppearanceUpdated;
end;

procedure TPPGCustomControl.AppearanceUpdated;
begin
end;

function TPPGCustomControl.Tokens: TPPGTokens;
var
  TR: IPPGThemeRenderer;
begin
  if Supports(FRenderer, IPPGThemeRenderer, TR) then
    Result := TR.Tokens(UseDarkMode)
  else
    Result := PPGDefaultTokens(UseDarkMode);
end;

function TPPGCustomControl.GetChildBackground(Child: TControl; out ColorTop,
  ColorBottom: TColor): Boolean;
begin
  ColorTop := clNone;
  ColorBottom := clNone;
  Result := False;
end;

function TPPGCustomControl.GetBackgroundColor: TColor;
begin
  Result := Color;
end;

procedure TPPGCustomControl.AnimationSettingsChanged(Sender: TObject);
begin
  // Ohne Animation in den Endzustand springen; abgeleitete Controls starten
  // bzw. stoppen hier ihre Daueranimationen (z.B. Marquee)
  UpdateVisualState(False);
end;

procedure TPPGCustomControl.AnimationStep(Sender: TObject);
begin
  Invalidate;
end;

{ ---- Bilder ---- }

procedure TPPGCustomControl.SetImages(const Value: TCustomImageList);
begin
  if FImages = Value then
    Exit;
  if FImages <> nil then
  begin
    FImages.UnRegisterChanges(FImageChangeLink);
    FImages.RemoveFreeNotification(Self);
  end;
  FImages := Value;
  if FImages <> nil then
  begin
    FImages.RegisterChanges(FImageChangeLink);
    FImages.FreeNotification(Self);
  end;
  ResolveImageName;
  RequestAutoSize;
  Invalidate;
end;

procedure TPPGCustomControl.ImageListChange(Sender: TObject);
begin
  // Bilder koennen umsortiert worden sein -> Index ueber den Namen neu bestimmen
  ResolveImageName;
  RequestAutoSize;
  Invalidate;
end;

function TPPGCustomControl.CheckImageIndex(const PropName: string;
  Value: TPPGImageIndex): TPPGImageIndex;
begin
  Result := PPGCheckRange(Self, PropName, Value, -1, MaxInt);
end;

procedure TPPGCustomControl.SetImageIndex(const Value: TPPGImageIndex);
var
  V: TPPGImageIndex;
begin
  V := CheckImageIndex('ImageIndex', Value);
  if FImageIndex <> V then
  begin
    FImageIndex := V;
    {$IFDEF PPG_HAS_IMAGENAME}
    if ImageNameAvailable then
      FImageName := FImages.GetNameByIndex(V);
    {$ENDIF}
    RequestAutoSize;
    Invalidate;
  end;
end;

procedure TPPGCustomControl.SetHotImageIndex(const Value: TPPGImageIndex);
var
  V: TPPGImageIndex;
begin
  V := CheckImageIndex('HotImageIndex', Value);
  if FHotImageIndex <> V then
  begin
    FHotImageIndex := V;
    Invalidate;
  end;
end;

procedure TPPGCustomControl.SetDisabledImageIndex(const Value: TPPGImageIndex);
var
  V: TPPGImageIndex;
begin
  V := CheckImageIndex('DisabledImageIndex', Value);
  if FDisabledImageIndex <> V then
  begin
    FDisabledImageIndex := V;
    Invalidate;
  end;
end;

procedure TPPGCustomControl.SetImagePosition(const Value: TPPGImagePosition);
begin
  if FImagePosition <> Value then
  begin
    FImagePosition := Value;
    RequestAutoSize;
    Invalidate;
  end;
end;

procedure TPPGCustomControl.SetSpacing(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'Spacing', Value, 0, PPGMaxSpacing);
  if FSpacing <> V then
  begin
    FSpacing := V;
    RequestAutoSize;
    Invalidate;
  end;
end;

procedure TPPGCustomControl.SetWordWrap(const Value: Boolean);
begin
  if FWordWrap <> Value then
  begin
    FWordWrap := Value;
    RequestAutoSize;
    Invalidate;
  end;
end;

procedure TPPGCustomControl.SetShowFocusRect(const Value: Boolean);
begin
  if FShowFocusRect <> Value then
  begin
    FShowFocusRect := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomControl.SetHighContrastSupport(const Value: Boolean);
begin
  if FHighContrastSupport <> Value then
  begin
    FHighContrastSupport := Value;
    Invalidate;
  end;
end;

{ ---- Zustand ---- }

function TPPGCustomControl.IsDown: Boolean;
begin
  Result := (FMousePressed and FMouseInside) or FKeyPressed;
end;

function TPPGCustomControl.IsHot: Boolean;
begin
  Result := FMouseInside or FMousePressed;
end;

function TPPGCustomControl.GetVisualState: TPPGVisualState;
begin
  if not Enabled then
    Result := vsDisabled
  else if IsDown then
    Result := vsDown
  else if IsHot then
    Result := vsHot
  else
    Result := vsNormal;
end;

function TPPGCustomControl.FocusVisible: Boolean;
begin
  Result := FShowFocusRect and Focused and PPGFocusCuesVisible(FUIState);
end;

procedure TPPGCustomControl.SetKeyPressed(Value: Boolean);
begin
  if FKeyPressed <> Value then
  begin
    FKeyPressed := Value;
    UpdateVisualState;
  end;
end;

procedure TPPGCustomControl.ResetInteractionState;
begin
  FMousePressed := False;
  FKeyPressed := False;
  UpdateVisualState(False);
end;

procedure TPPGCustomControl.UpdateVisualState(Animate: Boolean);
var
  HotTarget, DownTarget: Single;
  Duration: Cardinal;
begin
  if (FHotAnim = nil) or (FDownAnim = nil) then
    Exit; // waehrend Konstruktion/Zerstoerung
  HotTarget := 0;
  DownTarget := 0;
  if Enabled then
  begin
    if IsHot then
      HotTarget := 1;
    if IsDown then
      DownTarget := 1;
  end;
  if Animate and not (csDesigning in ComponentState) and FAnimation.EffectiveEnabled then
    Duration := FAnimation.Duration
  else
    Duration := 0;
  FHotAnim.AnimateTo(HotTarget, Duration);
  // Druecken reagiert schneller als Hover (direktes haptisches Feedback)
  FDownAnim.AnimateTo(DownTarget, Duration div 2);
  Invalidate;
end;

{ ---- Nachrichten ---- }

procedure TPPGCustomControl.CMMouseEnter(var Message: TMessage);
begin
  // Zustand zuerst setzen: eine Exception im OnMouseEnter des Anwenders
  // darf den internen Zustand nicht inkonsistent lassen.
  FMouseInside := True;
  UpdateVisualState;
  inherited;
end;

procedure TPPGCustomControl.CMMouseLeave(var Message: TMessage);
begin
  FMouseInside := False;
  UpdateVisualState;
  inherited;
end;

procedure TPPGCustomControl.CMEnabledChanged(var Message: TMessage);
begin
  if not Enabled then
  begin
    FMousePressed := False;
    FKeyPressed := False;
  end;
  UpdateVisualState(False);
  inherited;
  NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
end;

procedure TPPGCustomControl.CMTextChanged(var Message: TMessage);
begin
  inherited;
  RequestAutoSize;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_NAMECHANGE);
end;

procedure TPPGCustomControl.CMFontChanged(var Message: TMessage);
begin
  inherited;
  RequestAutoSize;
  Invalidate;
end;

procedure TPPGCustomControl.CMSysColorChange(var Message: TMessage);
begin
  inherited;
  Invalidate; // u.a. Wechsel in/aus dem Hochkontrastmodus
end;

procedure TPPGCustomControl.CMStyleChanged(var Message: TMessage);
begin
  inherited;
  InvalidateStyledAppearance;
  Invalidate; // VCL-Style gewechselt
end;

procedure TPPGCustomControl.CMBiDiModeChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TPPGCustomControl.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  // Hintergrund zeichnet Paint komplett selbst -> kein Flackern
  Message.Result := 1;
end;

procedure TPPGCustomControl.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  RefreshUIState;
  Invalidate;
end;

procedure TPPGCustomControl.WMKillFocus(var Message: TWMKillFocus);
begin
  FKeyPressed := False;
  UpdateVisualState(False);
  inherited;
end;

procedure TPPGCustomControl.WMLButtonUp(var Message: TWMLButtonUp);
begin
  // VOR inherited: TControl.WMLButtonUp loest Click vor MouseUp aus.
  FMousePressed := False;
  FMouseInside := PtInRect(ClientRect, SmallPointToPoint(Message.Pos));
  UpdateVisualState(False);
  inherited;
end;

procedure TPPGCustomControl.WMCaptureChanged(var Message: TMessage);
begin
  inherited;
  // Capture verloren (z.B. Dialog in OnMouseDown, Alt+Tab): nicht "haengen"
  if FMousePressed and (HWND(Message.LParam) <> Handle) then
  begin
    FMousePressed := False;
    UpdateVisualState(False);
  end;
end;

procedure TPPGCustomControl.WMUpdateUIState(var Message: TMessage);
begin
  inherited;
  RefreshUIState;
  Invalidate; // Fokus-/Accelerator-Cues ein- oder ausgeblendet
end;

procedure TPPGCustomControl.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  if (Button = mbLeft) and Enabled then
  begin
    // CanFocus allein reicht nicht: SetFocus wirft EInvalidOperation, wenn
    // ein Vorfahr unsichtbar/deaktiviert ist (z.B. Klick per Automation auf
    // ein verstecktes Formular). Fenster-Zustand daher zusaetzlich per API pruefen.
    if TabStop and not Focused and CanFocus and HandleAllocated and
      IsWindowVisible(Handle) and IsWindowEnabled(GetAncestor(Handle, GA_ROOT)) then
      SetFocus;
    FMousePressed := True;
    FMouseInside := PtInRect(ClientRect, Point(X, Y));
    UpdateVisualState(False);
  end;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TPPGCustomControl.KeyDown(var Key: Word; Shift: TShiftState);
begin
  // Leertaste: wie Windows-Buttons erst beim Loslassen ausloesen
  if (Key = VK_SPACE) and (Shift = []) and Enabled then
    SetKeyPressed(True);
  inherited KeyDown(Key, Shift);
end;

procedure TPPGCustomControl.KeyUp(var Key: Word; Shift: TShiftState);
var
  WasPressed: Boolean;
begin
  WasPressed := FKeyPressed and (Key = VK_SPACE);
  if WasPressed then
    SetKeyPressed(False); // Zustand VOR dem Anwender-Code zuruecksetzen
  inherited KeyUp(Key, Shift);
  if WasPressed and Enabled then
    Click;
end;

procedure TPPGCustomControl.CMDialogChar(var Message: TCMDialogChar);
begin
  if Enabled and IsAccel(Message.CharCode, Caption) and CanFocus then
  begin
    DoAccelerator;
    Message.Result := 1;
  end
  else
    inherited;
end;

procedure TPPGCustomControl.DoAccelerator;
begin
  Click;
end;

function TPPGCustomControl.HotProgress: Single;
begin
  if FHotAnim = nil then
    Result := 0
  else
    Result := FHotAnim.Value;
end;

function TPPGCustomControl.DownProgress: Single;
begin
  if FDownAnim = nil then
    Result := 0
  else
    Result := FDownAnim.Value;
end;

function TPPGCustomControl.AcceleratorCuesVisible: Boolean;
begin
  Result := PPGAcceleratorCuesVisible(FUIState);
end;

{ ---- Barrierefreiheit ---- }

procedure TPPGCustomControl.ReleaseAccessible;
begin
  if FAccessible <> nil then
    FAccessible.Disconnect; // externe Referenzen antworten ab jetzt "nicht verbunden"
  FAccessible := nil;
  FAccessibleRef := nil;
end;

procedure TPPGCustomControl.WMGetObject(var Message: TMessage);
begin
  // OBJID_CLIENT kommt als 32-Bit-Wert (auf Win64 nicht vorzeichenerweitert)
  if (Longint(Message.LParam) = PPGObjIdClient) and HandleAllocated and
    not (csDestroying in ComponentState) then
  begin
    if FAccessible = nil then
    begin
      FAccessible := TPPGAccessible.Create(Self, Handle);
      FAccessibleRef := FAccessible as IInterface;
    end;
    Message.Result := LresultFromObject(IID_IAccessible, Message.WParam,
      FAccessible as IAccessible);
  end
  else
    inherited;
end;

procedure TPPGCustomControl.DestroyWnd;
begin
  // Das Accessible-Objekt gehoert zum Fenster-Handle: bei RecreateWnd neu anlegen
  ReleaseAccessible;
  inherited DestroyWnd;
end;

procedure TPPGCustomControl.WndProc(var Message: TMessage);
begin
  if (GMsgAccDefaultAction <> 0) and (Message.Msg = GMsgAccDefaultAction) then
  begin
    // Aus accDoDefaultAction gepostet: hier laeuft Anwender-Code ausserhalb
    // des COM-Aufrufs des Screenreaders.
    if Enabled and Visible then
      Click;
    Exit;
  end;
  if (PPGThemeChangedMessage <> 0) and (Message.Msg = PPGThemeChangedMessage) then
  begin
    ThemeChanged;
    Exit;
  end;
  inherited WndProc(Message);
end;

procedure TPPGCustomControl.NotifyAccessibility(Event: DWORD);
begin
  if HandleAllocated and not (csDesigning in ComponentState) then
    PPGAccNotify(Handle, Event);
end;

procedure TPPGCustomControl.NotifyAccessibilityChild(Event: DWORD; ChildId: Integer);
begin
  if HandleAllocated and not (csDesigning in ComponentState) then
    PPGAccNotifyChild(Handle, Event, ChildId);
end;

function TPPGCustomControl.AccName: string;
begin
  Result := PPGAccStripHotkey(Caption);
end;

function TPPGCustomControl.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_PUSHBUTTON;
end;

function TPPGCustomControl.AccState: Integer;
begin
  Result := 0;
  if not Visible then
    Result := Result or STATE_SYSTEM_INVISIBLE;
  if not Enabled then
    Result := Result or STATE_SYSTEM_UNAVAILABLE
  else if TabStop then
    Result := Result or STATE_SYSTEM_FOCUSABLE;
  if Focused then
    Result := Result or STATE_SYSTEM_FOCUSED;
  if Enabled and IsHot then
    Result := Result or STATE_SYSTEM_HOTTRACKED;
  if Enabled and IsDown then
    Result := Result or STATE_SYSTEM_PRESSED;
end;

function TPPGCustomControl.AccDescription: string;
begin
  Result := GetShortHint(Hint);
end;

function TPPGCustomControl.AccValue: string;
begin
  Result := '';
end;

function TPPGCustomControl.AccKeyboardShortcut: string;
begin
  Result := PPGAccShortcutFromCaption(Caption);
end;

function TPPGCustomControl.AccDefaultAction: string;
begin
  Result := SPPGAccPress;
end;

procedure TPPGCustomControl.AccDoDefaultAction;
begin
  if HandleAllocated and (GMsgAccDefaultAction <> 0) then
    PostMessage(Handle, GMsgAccDefaultAction, 0, 0);
end;

procedure TPPGCustomControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Inside: Boolean;
begin
  Inside := PtInRect(ClientRect, Point(X, Y));
  if Inside <> FMouseInside then
  begin
    FMouseInside := Inside;
    UpdateVisualState;
  end;
  inherited MouseMove(Shift, X, Y);
end;

{ ---- Zeichnen ---- }

function TPPGCustomControl.GetCurrentStyle: TPPGSurfaceStyle;
var
  PPI: Integer;
  Focus: Boolean;
  N, H, D: TPPGSurfaceStyle;
begin
  PPI := ScalePPI;
  Focus := FocusVisible;
  if not Enabled then
    Result := EffectiveAppearance.Resolve(vsDisabled, PPI, False)
  else
  begin
    N := EffectiveAppearance.Resolve(vsNormal, PPI, Focus);
    H := EffectiveAppearance.Resolve(vsHot, PPI, Focus);
    D := EffectiveAppearance.Resolve(vsDown, PPI, Focus);
    Result := PPGBlendSurface(N, H, FHotAnim.Value);
    Result := PPGBlendSurface(Result, D, FDownAnim.Value);
  end;

  if FHighContrastSupport and PPGIsHighContrast then
  begin
    // Hochkontrast: ausschliesslich Systemfarben, kein Glow
    Result.GlowAlpha := 0;
    Result.Direction := gdVertical;
    if not Enabled then
    begin
      Result.Color := PPGColorToRGB(clBtnFace);
      Result.TextColor := PPGColorToRGB(clGrayText);
      Result.BorderColor := PPGColorToRGB(clGrayText);
    end
    else if IsDown then
    begin
      Result.Color := PPGColorToRGB(clHighlight);
      Result.TextColor := PPGColorToRGB(clHighlightText);
      Result.BorderColor := PPGColorToRGB(clHighlightText);
    end
    else
    begin
      Result.Color := PPGColorToRGB(clBtnFace);
      Result.TextColor := PPGColorToRGB(clBtnText);
      if IsHot or Focus then
        Result.BorderColor := PPGColorToRGB(clHighlight)
      else
        Result.BorderColor := PPGColorToRGB(clBtnText);
    end;
    Result.ColorTo := Result.Color;
    Result.ColorMirror := Result.Color;
    Result.ColorMirrorTo := Result.Color;
    if Result.BorderWidth < 1 then
      Result.BorderWidth := 1;
  end;
end;

function TPPGCustomControl.GetBodyRect(const Style: TPPGSurfaceStyle): TRect;
var
  Inset: Integer;
begin
  Result := ClientRect;
  // Inset aus dem MAXIMALEN Glow (Appearance), nicht aus dem aktuellen
  // Zustand - sonst "springt" der Koerper bei Hover.
  Inset := 0;
  if FRenderer <> nil then
    Inset := FRenderer.BodyInset(Style);
  if Inset > (Result.Right - Result.Left) div 4 then
    Inset := (Result.Right - Result.Left) div 4;
  if Inset > (Result.Bottom - Result.Top) div 4 then
    Inset := (Result.Bottom - Result.Top) div 4;
  InflateRect(Result, -Inset, -Inset);
end;

function TPPGCustomControl.GetContentRect(const Body: TRect;
  const Style: TPPGSurfaceStyle): TRect;
var
  D: Integer;
begin
  Result := Body;
  D := Style.BorderWidth + PPGScale(ContentPadding, ScalePPI);
  InflateRect(Result, -D, -D);
end;

function TPPGCustomControl.GetCurrentImageIndex: Integer;
begin
  Result := FImageIndex;
  if not Enabled then
  begin
    if FDisabledImageIndex >= 0 then
      Result := FDisabledImageIndex;
  end
  else if IsHot and (FHotImageIndex >= 0) then
    Result := FHotImageIndex;
  if (FImages = nil) or (Result >= FImages.Count) then
    Result := -1;
end;

function TPPGCustomControl.GetTextFlags: Cardinal;
begin
  Result := DT_CENTER or DT_VCENTER or DT_NOCLIP or DT_END_ELLIPSIS;
  if FWordWrap then
    Result := (Result or DT_WORDBREAK) and not DT_VCENTER
  else
    Result := Result or DT_SINGLELINE;
  if not PPGAcceleratorCuesVisible(FUIState) then
    Result := Result or DT_HIDEPREFIX;
  Result := DrawTextBiDiModeFlags(Result);
end;

procedure TPPGCustomControl.FillBackground(DC: HDC; const R: TRect);
var
  Brush: HBRUSH;
  CTop, CBottom: TColor;
  V: array[0..1] of TTriVertex;
  GR: TGradientRect;
begin
  // PPGlow-Container als Parent: Flaechenfarbe direkt fuellen. Sonst laesst
  // DrawParentBackground fuer JEDES Kind den ganzen Container zeichnen
  // (300 Kinder = 300 volle Container-Paints, Benchmark "Panel mit 300 Kindern").
  if ParentBackground and (Parent is TPPGCustomControl) and
    TPPGCustomControl(Parent).GetChildBackground(Self, CTop, CBottom) then
  begin
    CTop := ColorToRGB(CTop);
    CBottom := ColorToRGB(CBottom);
    if CTop <> CBottom then
    begin
      V[0].x := R.Left;
      V[0].y := R.Top;
      V[0].Red := GetRValue(CTop) shl 8;
      V[0].Green := GetGValue(CTop) shl 8;
      V[0].Blue := GetBValue(CTop) shl 8;
      V[0].Alpha := 0;
      V[1].x := R.Right;
      V[1].y := R.Bottom;
      V[1].Red := GetRValue(CBottom) shl 8;
      V[1].Green := GetGValue(CBottom) shl 8;
      V[1].Blue := GetBValue(CBottom) shl 8;
      V[1].Alpha := 0;
      GR.UpperLeft := 0;
      GR.LowerRight := 1;
      if GradientFill(DC, @V[0], 2, @GR, 1, GRADIENT_FILL_RECT_V) then
        Exit;
    end;
    Brush := CreateSolidBrush(CTop);
    if Brush <> 0 then
    try
      Winapi.Windows.FillRect(DC, R, Brush);
    finally
      DeleteObject(Brush);
    end;
    Exit;
  end;
  Brush := CreateSolidBrush(ColorToRGB(GetBackgroundColor));
  if Brush <> 0 then
  try
    Winapi.Windows.FillRect(DC, R, Brush);
  finally
    DeleteObject(Brush);
  end;
  // Transparente Ecken: Hintergrund des Parents (inkl. VCL-Styles) uebernehmen
  if ParentBackground and (Parent <> nil) and HandleAllocated and StyleServices.Enabled then
    StyleServices.DrawParentBackground(Handle, DC, nil, False);
end;

procedure TPPGCustomControl.Paint;
var
  R: TRect;
  W, H: Integer;
  MemDC: HDC;
  Bmp, OldBmp: HBITMAP;
  PPGCanvas: IPPGCanvas;
begin
  R := ClientRect;
  W := R.Right - R.Left;
  H := R.Bottom - R.Top;
  if (W <= 0) or (H <= 0) then
    Exit;
  try
    MemDC := CreateCompatibleDC(Canvas.Handle);
    if MemDC = 0 then
      PPGRaiseLastOSError('CreateCompatibleDC');
    try
      Bmp := CreateCompatibleBitmap(Canvas.Handle, W, H);
      if Bmp = 0 then
        PPGRaiseLastOSError('CreateCompatibleBitmap');
      try
        OldBmp := SelectObject(MemDC, Bmp);
        try
          FillBackground(MemDC, R);
          PPGCanvas := TPPGRendererRegistry.CreateCanvas(MemDC);
          try
            DoPaint(PPGCanvas, R);
          finally
            PPGCanvas := nil; // GDI+ flushen, bevor kopiert wird
          end;
          if not BitBlt(Canvas.Handle, 0, 0, W, H, MemDC, 0, 0, SRCCOPY) then
            PPGRaiseLastOSError('BitBlt');
        finally
          SelectObject(MemDC, OldBmp);
        end;
      finally
        DeleteObject(Bmp);
      end;
    finally
      DeleteDC(MemDC);
    end;
    FPaintErrorReported := False;
  except
    on E: Exception do
    begin
      // FEHLERGRENZE: nie weiterwerfen (WM_PAINT-Schleife), einmal melden
      if not FPaintErrorReported then
      begin
        FPaintErrorReported := True;
        TPPGErrorHandler.ReportPaintError(Self, E);
      end;
      PaintFallback(Canvas);
    end;
  end;
end;

procedure TPPGCustomControl.PaintFallback(ACanvas: TCanvas);
var
  R: TRect;
  S: string;
begin
  try
    R := ClientRect;
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := clBtnFace;
    ACanvas.Pen.Color := clBtnShadow;
    ACanvas.Pen.Width := 1;
    ACanvas.Rectangle(R);
    ACanvas.Font := Font;
    ACanvas.Font.Color := clBtnText;
    ACanvas.Brush.Style := bsClear;
    S := Caption;
    ACanvas.TextRect(R, S, [tfCenter, tfVerticalCenter, tfSingleLine, tfEndEllipsis]);
  except
    on E: Exception do
      // Letzte Linie: selbst der Notfall-Zustand scheitert (z.B. kein GDI-
      // Handle mehr frei). Nur protokollieren - Weiterwerfen wuerde die
      // Anwendung in eine Paint-Schleife treiben.
      TPPGErrorHandler.LogWarning(Self, 'PaintFallback: ' + E.Message);
  end;
end;

function TPPGCustomControl.LayoutBodyRect: TRect;
begin
  // Immer aus dem Hot-Stil (maximaler Glow-Platz) - identisch zu DoPaint
  Result := GetBodyRect(EffectiveAppearance.Resolve(vsHot, ScalePPI, False));
end;

procedure TPPGCustomControl.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  Style: TPPGSurfaceStyle;
  Body: TRect;
begin
  Style := GetCurrentStyle;
  // Koerper-Rechteck immer aus dem Hot-Stil ermitteln (maximaler Glow-Platz)
  Body := LayoutBodyRect;
  DoPaintBackground(ACanvas, Body, Style);
  DoPaintContent(ACanvas, Body, Style);
  DoPaintOverlay(ACanvas, Body, Style);
end;

procedure TPPGCustomControl.DoPaintBackground(const ACanvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle);
begin
  FRenderer.DrawSurface(ACanvas, Body, Style);
end;

procedure TPPGCustomControl.DoPaintContent(const ACanvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle);
begin
  DoPaintCaption(ACanvas, GetContentRect(Body, Style), Style);
end;

procedure TPPGCustomControl.DoPaintCaption(const ACanvas: IPPGCanvas; const Content: TRect;
  const Style: TPPGSurfaceStyle);
var
  Input: TPPGLayoutInput;
  Layout: TPPGLayoutResult;
  ImgIndex: Integer;
  Text: string;
  ImgEnabled: Boolean;
begin
  if IsRectEmpty(Content) then
    Exit;
  Text := Caption;
  ImgIndex := GetCurrentImageIndex;

  FillChar(Input, SizeOf(Input), 0);
  Input.Bounds := Content;
  if ImgIndex >= 0 then
  begin
    Input.ImageSize.cx := FImages.Width;
    Input.ImageSize.cy := FImages.Height;
  end;
  if Text <> '' then
    Input.TextSize := ACanvas.MeasureText(Text, Font, Content.Right - Content.Left, FWordWrap);
  Input.ImagePosition := FImagePosition;
  Input.Spacing := PPGScale(FSpacing, ScalePPI);
  Input.Alignment := haCenter;
  Input.RightToLeft := UseRightToLeftAlignment;
  Layout := TPPGLayoutEngine.Calculate(Input);

  if ImgIndex >= 0 then
  begin
    // Graues Bild nur, wenn kein eigenes DisabledImageIndex gesetzt ist
    ImgEnabled := Enabled or (FDisabledImageIndex >= 0);
    ACanvas.DrawImage(FImages, ImgIndex, Layout.ImageRect.Left, Layout.ImageRect.Top, ImgEnabled);
  end;
  if Text <> '' then
    ACanvas.DrawText(Layout.TextRect, Text, Font, Style.TextColor, GetTextFlags);
end;

procedure TPPGCustomControl.DoPaintOverlay(const ACanvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle);
begin
  if Style.Focused then
    FRenderer.DrawFocus(ACanvas, Body, Style);
end;

initialization
  GMsgAccDefaultAction := RegisterWindowMessage('PPGlow.AccDefaultAction');

end.
