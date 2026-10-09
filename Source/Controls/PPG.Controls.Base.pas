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
  PPG.Render.Intf, PPG.StyleManager, PPG.Accessibility, PPG.UIA, PPG.ElementStyle;

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
    FPressedImageIndex: TPPGImageIndex;
    FImageTint: TPPGImageTint;
    FImagePosition: TPPGImagePosition;
    FSpacing: Integer;
    FWordWrap: Boolean;
    FShowFocusRect: Boolean;
    FHighContrastSupport: Boolean;
    FRoundedCorners: TPPGCorners;
    FShadow: TPPGShadow;
    FMouseInside: Boolean;
    FMousePressed: Boolean;
    FWheelRest: Integer;   // Teil-Deltas des Mausrads (WheelSteps)
    FKeyPressed: Boolean;
    FHotAnim: TPPGAnimation;
    FDownAnim: TPPGAnimation;
    FUpdateCount: Integer;
    FInvalidatePending: Boolean;
    FPaintErrorReported: Boolean;
    FUIState: Cardinal; // Cache von WM_QUERYUISTATE (Paint darf keine Nachrichten senden)
    FAccessible: TPPGAccessible;
    FAccessibleRef: IInterface; // haelt das COM-Objekt am Leben
    FUiaRoot: TPPGUiaRoot;      // UI Automation (nur Controls mit IPPGUiaSource)
    FUiaRootRef: IInterface;
    FStyledAppearance: TPPGAppearance; // Cache: Appearance mit Farben des VCL-Styles bzw. Dark Mode
    FStyledKind: Byte; // Inhalt des Caches: 0 = leer, 1 = VCL-Style, 2 = Dark Mode, 3 = Hochkontrast
    {$IFDEF PPG_HAS_IMAGENAME}
    FImageName: TImageName;
    FHotImageName: TImageName;
    FDisabledImageName: TImageName;
    FPressedImageName: TImageName;
    procedure SetImageName(const Value: TImageName);
    procedure SetStateImageName(Index: Integer; const Value: TImageName);
    function GetStateImageName(Index: Integer): TImageName;
    function IsStateImageNameStored(Index: Integer): Boolean;
    {$ENDIF}
    procedure ResolveImageName;
    procedure ResolveStateImageNames;
    procedure InvalidateStyledAppearance;
    procedure ReleaseAccessible;
    procedure RefreshUIState;
    procedure SetAppearance(const Value: TPPGAppearance);
    procedure SetAnimation(const Value: TPPGAnimationSettings);
    procedure SetStyleManager(const Value: TPPGStyleManager);
    procedure SetRoundedCorners(const Value: TPPGCorners);
    procedure SetShadow(const Value: TPPGShadow);
    procedure ShadowChanged(Sender: TObject);
    procedure SetPreset(const Value: string);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetImageIndex(const Value: TPPGImageIndex);
    procedure SetHotImageIndex(const Value: TPPGImageIndex);
    procedure SetDisabledImageIndex(const Value: TPPGImageIndex);
    procedure SetPressedImageIndex(const Value: TPPGImageIndex);
    procedure SetImageTint(const Value: TPPGImageTint);
    function IsHotImageIndexStored: Boolean;
    function IsDisabledImageIndexStored: Boolean;
    function IsPressedImageIndexStored: Boolean;
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
    procedure WMLButtonDblClk(var Message: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;
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
    /// Images wurde gesetzt, freigegeben (dann schon nil) oder hat sich
    /// geaendert. Nachfahren, die die Liste oder daraus abgeleitete Daten
    /// zwischenspeichern (Reiterleiste, Markup-Layout), ziehen hier nach.
    procedure ImagesChanged; virtual;
    /// True, wenn das Control AComponent ausser ueber Images noch anders
    /// haelt (z.B. LargeImages). Dann bleibt die FreeNotification beim
    /// Wechsel von Images bestehen.
    function ReferencesComponent(AComponent: TComponent): Boolean; virtual;
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
    /// Hat das Control einen UIA-Provider (IPPGUiaSource), wird das Ereignis
    /// zusaetzlich als UIA-Ereignis gemeldet (Fokus, Auswahl, Zustand).
    procedure NotifyAccessibilityChild(Event: DWORD; ChildId: Integer);
    /// UIA-Ereignis fuer ein Element (nur mit Wurzel und zuhoerendem Client).
    procedure UiaNotify(const Id: TPPGUiaId; EventId: Integer);
    procedure UiaNotifyProperty(const Id: TPPGUiaId; PropertyId: Integer; const NewValue: OleVariant);
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
    /// Hochkontrast-Sonderfall fuer Kaestchen und Kreise in Listen und Gruppen:
    /// Flaeche Surface, Haken/Rand TextPrimary (deaktiviert TextDisabled),
    /// hervorgehoben (Hover/Fokus) Rand Accent, kein Glow - alles aus Tokens.
    procedure ApplyHighContrastIndicator(var S: TPPGSurfaceStyle; Usable, Emphasized: Boolean);
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
    /// Ausrichtung von Bild und Text im Inhalt (Standard: zentriert).
    function GetCaptionAlignment: TPPGHorzAlign; virtual;
    /// Zeichnet das Bild des aktuellen Zustands.
    procedure DrawStateImage(const ACanvas: IPPGCanvas; Index, X, Y: Integer;
      AEnabled: Boolean; const Style: TPPGSurfaceStyle); virtual;
    function GetTextFlags: Cardinal; virtual;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); virtual;
    /// Platz fuer den Schatten je Seite (px; 0 ohne Schatten bzw. im Hochkontrast).
    function ShadowInsets: TRect;
    /// Schatten unter Body zeichnen (eckige Ecken wie RoundedCorners).
    procedure PaintShadow(const ACanvas: IPPGCanvas; const Body: TRect; Radius: Integer);
    /// Ecken ohne Rundung (Gegenstueck zu RoundedCorners).
    function SquareCorners: TPPGCorners;
    /// Gerundete Ecken; die uebrigen werden eckig (Button-Gruppen).
    property RoundedCorners: TPPGCorners read FRoundedCorners write SetRoundedCorners
      default [pcTopLeft, pcTopRight, pcBottomRight, pcBottomLeft];
    /// Schatten unter der Flaeche (Elevation).
    property Shadow: TPPGShadow read FShadow write SetShadow;
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
    property HotImageIndex: TPPGImageIndex read FHotImageIndex write SetHotImageIndex
      stored IsHotImageIndexStored default -1;
    property DisabledImageIndex: TPPGImageIndex read FDisabledImageIndex write SetDisabledImageIndex
      stored IsDisabledImageIndexStored default -1;
    /// Bild beim Druecken bzw. eingerastet (-1 = wie in Ruhe bzw. Hover).
    property PressedImageIndex: TPPGImageIndex read FPressedImageIndex write SetPressedImageIndex
      stored IsPressedImageIndexStored default -1;
    {$IFDEF PPG_HAS_IMAGENAME}
    property HotImageName: TImageName index 1 read GetStateImageName write SetStateImageName
      stored IsStateImageNameStored;
    property DisabledImageName: TImageName index 2 read GetStateImageName write SetStateImageName
      stored IsStateImageNameStored;
    property PressedImageName: TImageName index 3 read GetStateImageName write SetStateImageName
      stored IsStateImageNameStored;
    {$ENDIF}
    /// itTextColor: Bild einfarbig in der Textfarbe des Zustands (einfarbige
    /// Symbole folgen Hover, Dunkel und Deaktiviert).
    property ImageTint: TPPGImageTint read FImageTint write SetImageTint default itNone;
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
    /// True, wenn Windows im Hochkontrastmodus laeuft und das Control ihm
    /// folgt (HighContrastSupport). Dann liefern Tokens und
    /// EffectiveAppearance die Systemfarben.
    function UseHighContrast: Boolean;
    /// True, wenn eigene Farben (Element-Stile, Item-Farben) gelten: weder
    /// Hochkontrast noch VCL-Style. Schriften gelten immer.
    function UseOwnColors: Boolean;
    /// Farbe von Links im Text: eigene FocusColor bzw. VCL-Style bleiben,
    /// sonst das Link-Token (4,5:1 zum Hintergrund; Hochkontrast clHotLight).
    function TextLinkColor: TColor;
    /// Die beim Zeichnen tatsaechlich verwendete Appearance. Rangfolge:
    /// Hochkontrast (Formen bleiben, Systemfarben) > VCL-Style (Formen aus
    /// dem Preset, Farben aus dem Style) > Dark Mode (Formen aus der
    /// Appearance, dunkle Farben des Presets) > Appearance.
    function EffectiveAppearance: TPPGAppearance;
    /// Design-Tokens des Presets (semantische Farben, Masse, Dauern), z.B.
    /// Signalfarben fuer Fehler/Warnung. Presets ohne eigene Tokens liefern die
    /// neutrale Windows-11-Palette. Im Hochkontrast (UseHighContrast) sind
    /// alle Farben Systemfarben (PPGApplyHighContrastColors).
    function Tokens: TPPGTokens;
    /// UIA-Wurzel, sobald ein UIA-Client gefragt hat (sonst nil). Nur fuer
    /// Controls mit IPPGUiaSource (Grid, TreeView, ListBox, CheckListBox).
    function UiaRoot: TPPGUiaRoot;
    /// Mausrad (Audit 7b): ganze Schritte aus WheelDelta, Lines je Raste.
    /// Teil-Deltas hochaufloesender Raeder und Touchpads werden gesammelt
    /// (3 x 40 = eine Raste), ein Richtungswechsel verwirft den Rest.
    /// Positiv = Rad nach vorn bzw. oben.
    function WheelSteps(WheelDelta: Integer; Lines: Integer = 1): Integer;
    /// True, wenn weder das Control noch ein Kind den Fokus hat. Wert-Controls
    /// aendern ihren Wert dann nicht: das Rad geht an den Elternteil (Seite
    /// scrollt), wie DoMouseWheel = False es weiterreicht.
    function WheelNeedsFocus: Boolean;
    property Renderer: IPPGRenderer read FRenderer;
    property VisualState: TPPGVisualState read GetVisualState;
  end;

/// Bilderliste (published "Images") des naechsten Besitzers: Collection-Owner
/// bzw. Parent (fuer ImageName an Eintraegen und Seiten).
function PPGImagesOf(Start: TPersistent): TCustomImageList;

/// Zeilen je Rastung aus der Systemeinstellung (SPI_GETWHEELSCROLLLINES,
/// Vorgabe 3); -1 = seitenweise (WHEEL_PAGESCROLL), 0 = Scrollen aus.
function PPGWheelScrollLines: Integer;
/// Sammelt Rad-Deltas in Rest und liefert ganze Schritte (Delta * Lines je
/// WHEEL_DELTA); ein Richtungswechsel verwirft den Rest.
function PPGWheelSteps(var Rest: Integer; Delta, Lines: Integer): Integer;

implementation

uses
  System.TypInfo,
  PPG.Lang,
  System.SysUtils, System.Math, Vcl.Forms, Vcl.Themes,
  PPG.Consts, PPG.Exceptions, PPG.ErrorHandler, PPG.DpiUtils,
  PPG.Render.Registry, PPG.Render.Gdi, PPG.Presets, PPG.VclStyles, PPG.Theme,
  PPG.UIA.Intf, Winapi.oleacc;

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
  FPressedImageIndex := -1;
  FImagePosition := ipLeft;
  FSpacing := 4;
  FShowFocusRect := True;
  FHighContrastSupport := True;
  FRoundedCorners := PPGAllCorners;
  FShadow := TPPGShadow.Create(Self);
  FShadow.OnChange := ShadowChanged;

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
  FreeAndNil(FShadow);
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
  ResolveStateImageNames;
end;

procedure TPPGCustomControl.ResolveStateImageNames;
begin
{$IFDEF PPG_HAS_IMAGENAME}
  if (csLoading in ComponentState) or not ImageNameAvailable then
    Exit;
  if FHotImageName <> '' then
    FHotImageIndex := FImages.GetIndexByName(FHotImageName);
  if FDisabledImageName <> '' then
    FDisabledImageIndex := FImages.GetIndexByName(FDisabledImageName);
  if FPressedImageName <> '' then
    FPressedImageIndex := FImages.GetIndexByName(FPressedImageName);
{$ENDIF}
end;

{$IFDEF PPG_HAS_IMAGENAME}
function TPPGCustomControl.GetStateImageName(Index: Integer): TImageName;
begin
  case Index of
    1: Result := FHotImageName;
    2: Result := FDisabledImageName;
  else
    Result := FPressedImageName;
  end;
end;

procedure TPPGCustomControl.SetStateImageName(Index: Integer; const Value: TImageName);
begin
  case Index of
    1: FHotImageName := Value;
    2: FDisabledImageName := Value;
  else
    FPressedImageName := Value;
  end;
  ResolveStateImageNames;
  Invalidate;
end;

function TPPGCustomControl.IsStateImageNameStored(Index: Integer): Boolean;
begin
  Result := ImageNameAvailable and (GetStateImageName(Index) <> '');
end;
{$ENDIF}

function TPPGCustomControl.IsHotImageIndexStored: Boolean;
begin
  // Mit Namen wird nur der Name gespeichert (robust gegen Umsortieren)
  Result := FHotImageIndex <> -1;
{$IFDEF PPG_HAS_IMAGENAME}
  Result := Result and not (ImageNameAvailable and (FHotImageName <> ''));
{$ENDIF}
end;

function TPPGCustomControl.IsDisabledImageIndexStored: Boolean;
begin
  Result := FDisabledImageIndex <> -1;
{$IFDEF PPG_HAS_IMAGENAME}
  Result := Result and not (ImageNameAvailable and (FDisabledImageName <> ''));
{$ENDIF}
end;

function TPPGCustomControl.IsPressedImageIndexStored: Boolean;
begin
  Result := FPressedImageIndex <> -1;
{$IFDEF PPG_HAS_IMAGENAME}
  Result := Result and not (ImageNameAvailable and (FPressedImageName <> ''));
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
    ImagesChanged;
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
    Format(PPGStr(@SPPGNotMainThread), [ClassName]));
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
    not UseHighContrast;
{$IFDEF PPG_HAS_STYLEELEMENTS}
  // seClient abgewaehlt -> Control behaelt bewusst seine eigenen Farben
  Result := Result and (seClient in StyleElements);
{$ENDIF}
end;

function TPPGCustomControl.UseHighContrast: Boolean;
begin
  Result := PPGUseHighContrast(FHighContrastSupport);
end;

function TPPGCustomControl.UseOwnColors: Boolean;
begin
  Result := not UseHighContrast and not UseVclStyle;
end;

function TPPGCustomControl.TextLinkColor: TColor;
var
  T: TPPGTokens;
  F: TColor;
begin
  T := Tokens;
  if UseHighContrast then
    Exit(T.Link);
  F := PPGColorToRGB(EffectiveAppearance.FocusColor);
  if UseVclStyle or (F <> T.Accent) then
    Result := F
  else
    Result := T.Link;
end;

function TPPGCustomControl.EffectiveAppearance: TPPGAppearance;
var
  Kind: Byte;
  TR: IPPGThemeRenderer;
begin
  if UseHighContrast then
    Kind := 3
  else if UseVclStyle then
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
      if Kind = 3 then
        PPGApplyHighContrastAppearance(FStyledAppearance) // Systemfarben
      else if Kind = 1 then
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
        // Eigene Dunkel-Farben (Appearance.Dark) nach den Preset-Farben
        PPGApplyDarkColors(FStyledAppearance, FAppearance.Dark);
      end;
      if Kind = 1 then
        FStyledAppearance.Focused.Clear; // VCL-Style: keine eigenen Fokusfarben
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

procedure TPPGCustomControl.ApplyHighContrastIndicator(var S: TPPGSurfaceStyle;
  Usable, Emphasized: Boolean);
var
  T: TPPGTokens;
begin
  T := Tokens;
  S.GlowAlpha := 0;
  S.Color := T.Surface;
  S.ColorTo := S.Color;
  S.ColorMirror := S.Color;
  S.ColorMirrorTo := S.Color;
  if Usable then
    S.TextColor := T.TextPrimary
  else
    S.TextColor := T.TextDisabled;
  if Usable and Emphasized then
    S.BorderColor := T.Accent
  else
    S.BorderColor := S.TextColor;
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
    TPPGErrorHandler.LogWarning(Self, Format(PPGStr(@SPPGUnknownPresetFallback),
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
  if UseHighContrast then
  begin
    // Masse und Dauern des Presets, Farben aus dem System
    if Supports(FRenderer, IPPGThemeRenderer, TR) then
      Result := TR.Tokens(False)
    else
      Result := PPGBaseTokens(False);
    PPGApplyHighContrastColors(Result);
  end
  else if Supports(FRenderer, IPPGThemeRenderer, TR) then
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
    // RemoveFreeNotification wirkt beidseitig: Haelt das Control dieselbe
    // Liste noch anders (z.B. LargeImages), muss die Benachrichtigung bleiben.
    if not ReferencesComponent(FImages) then
      FImages.RemoveFreeNotification(Self);
  end;
  FImages := Value;
  if FImages <> nil then
  begin
    FImages.RegisterChanges(FImageChangeLink);
    FImages.FreeNotification(Self);
  end;
  ResolveImageName;
  ImagesChanged;
  RequestAutoSize;
  Invalidate;
end;

procedure TPPGCustomControl.ImageListChange(Sender: TObject);
begin
  // Bilder koennen umsortiert worden sein -> Index ueber den Namen neu bestimmen
  ResolveImageName;
  ImagesChanged;
  RequestAutoSize;
  Invalidate;
end;

procedure TPPGCustomControl.ImagesChanged;
begin
  // Basis: nichts zwischengespeichert
end;

function TPPGCustomControl.ReferencesComponent(AComponent: TComponent): Boolean;
begin
  Result := False;
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
    {$IFDEF PPG_HAS_IMAGENAME}
    if ImageNameAvailable then
      FHotImageName := FImages.GetNameByIndex(V);
    {$ENDIF}
    Invalidate;
  end;
end;

procedure TPPGCustomControl.SetPressedImageIndex(const Value: TPPGImageIndex);
var
  V: TPPGImageIndex;
begin
  V := CheckImageIndex('PressedImageIndex', Value);
  if FPressedImageIndex <> V then
  begin
    FPressedImageIndex := V;
    {$IFDEF PPG_HAS_IMAGENAME}
    if ImageNameAvailable then
      FPressedImageName := FImages.GetNameByIndex(V);
    {$ENDIF}
    Invalidate;
  end;
end;

procedure TPPGCustomControl.SetImageTint(const Value: TPPGImageTint);
begin
  if FImageTint <> Value then
  begin
    FImageTint := Value;
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
    {$IFDEF PPG_HAS_IMAGENAME}
    if ImageNameAvailable then
      FDisabledImageName := FImages.GetNameByIndex(V);
    {$ENDIF}
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
  // u.a. Wechsel in/aus dem Hochkontrastmodus oder ein anderes
  // Kontrastdesign: Systemfarben in Appearance und Tokens neu holen
  ThemeChanged;
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

procedure TPPGCustomControl.WMLButtonDblClk(var Message: TWMLButtonDblClk);
begin
  // Audit 5d: TControl ruft DblClick nur mit csClickEvents auf. Controls, die
  // Klicks selbst melden (Listen, Grid, Kanban), aber Doppelklicks annehmen,
  // bekommen DblClick trotzdem (wie die VCL: vor dem MouseDown mit ssDouble).
  if (csDoubleClicks in ControlStyle) and not (csClickEvents in ControlStyle) then
    DblClick;
  inherited;
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
var
  Prov: IRawElementProviderSimple;
begin
  if FAccessible <> nil then
    FAccessible.Disconnect; // externe Referenzen antworten ab jetzt "nicht verbunden"
  FAccessible := nil;
  FAccessibleRef := nil;
  if FUiaRoot <> nil then
  begin
    // Clients koennen die Elemente noch halten: ab jetzt "nicht verfuegbar"
    Prov := FUiaRoot;
    FUiaRoot.Disconnect;
    PPGUiaDisconnectProvider(Prov);
    Prov := nil;
  end;
  FUiaRoot := nil;
  FUiaRootRef := nil;
end;

procedure TPPGCustomControl.WMGetObject(var Message: TMessage);
var
  Src: IPPGUiaSource;
begin
  // UI Automation: nativer Provider nur fuer Controls mit IPPGUiaSource
  // (Grid, Baum, Listen); alle anderen bleiben bei MSAA (Windows bruecktet).
  if (Longint(Message.LParam) = PPGUiaRootObjectId) and PPGUiaEnabled and HandleAllocated and
    not (csDestroying in ComponentState) and not (csDesigning in ComponentState) and
    Supports(Self, IPPGUiaSource, Src) and PPGUiaAvailable then
  begin
    if FUiaRoot = nil then
    begin
      FUiaRoot := TPPGUiaRoot.CreateRoot(Src, Handle, Name, ClassName);
      FUiaRootRef := FUiaRoot as IInterface;
    end;
    Message.Result := PPGUiaReturnRawElementProvider(Handle, Message.WParam, Message.LParam,
      FUiaRoot as IRawElementProviderSimple);
    Exit;
  end;
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
  if Message.Msg = PPGUiaActionMessage then
  begin
    // Aus einem UIA-Aufruf vorgemerkte Aktionen: Anwender-Code laeuft hier,
    // ausserhalb des COM-Aufrufs des Screenreaders
    if FUiaRoot <> nil then
      FUiaRoot.RunQueued;
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
var
  Src: IPPGUiaSource;
  Id: TPPGUiaId;
begin
  if HandleAllocated and not (csDesigning in ComponentState) then
    PPGAccNotifyChild(Handle, Event, ChildId);
  // Mit nativem UIA-Provider bruecktet Windows die WinEvents nicht mehr
  // zuverlaessig: dieselben Ereignisse deshalb auch als UIA-Ereignisse.
  if (FUiaRoot = nil) or not FUiaRoot.Connected or not PPGUiaClientsAreListening then
    Exit;
  Src := FUiaRoot.Source;
  Id := Src.UiaFromAccChild(ChildId);
  if PPGUiaIsRoot(Id) or not Src.UiaValid(Id) then
    Exit;
  case Event of
    EVENT_OBJECT_FOCUS:
      FUiaRoot.RaiseEvent(Id, UIA_AutomationFocusChangedEventId);
    EVENT_OBJECT_SELECTION:
      FUiaRoot.RaiseEvent(Id, UIA_SelectionItem_ElementSelectedEventId);
    EVENT_OBJECT_SELECTIONADD:
      FUiaRoot.RaiseEvent(Id, UIA_SelectionItem_ElementAddedToSelectionEventId);
    EVENT_OBJECT_SELECTIONREMOVE:
      FUiaRoot.RaiseEvent(Id, UIA_SelectionItem_ElementRemovedFromSelectionEventId);
    EVENT_OBJECT_STATECHANGE:
      begin
        if Src.UiaHasPattern(Id, UIA_TogglePatternId) then
          FUiaRoot.RaisePropertyChanged(Id, UIA_ToggleToggleStatePropertyId, Src.UiaToggleState(Id));
        if Src.UiaHasPattern(Id, UIA_ExpandCollapsePatternId) then
          FUiaRoot.RaisePropertyChanged(Id, UIA_ExpandCollapseExpandCollapseStatePropertyId,
            Src.UiaExpandState(Id));
      end;
  end;
end;

function TPPGCustomControl.UiaRoot: TPPGUiaRoot;
begin
  Result := FUiaRoot;
end;

procedure TPPGCustomControl.UiaNotify(const Id: TPPGUiaId; EventId: Integer);
begin
  if FUiaRoot <> nil then
    FUiaRoot.RaiseEvent(Id, EventId);
end;

procedure TPPGCustomControl.UiaNotifyProperty(const Id: TPPGUiaId; PropertyId: Integer;
  const NewValue: OleVariant);
begin
  if FUiaRoot <> nil then
    FUiaRoot.RaisePropertyChanged(Id, PropertyId, NewValue);
end;

function TPPGCustomControl.AccName: string;
begin
  Result := PPGAccStripHotkey(Caption);
end;

function TPPGCustomControl.AccRole: Integer;
begin
  // Audit 7d: neutral; Buttons und andere Rollen ueberschreiben das
  Result := ROLE_SYSTEM_CLIENT;
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
  // Audit 7d: keine Standardaktion; nur Buttons melden "Druecken"
  Result := '';
end;

procedure TPPGCustomControl.AccDoDefaultAction;
begin
  // Ohne Standardaktion (Rolle ohne Aktion) nichts ausloesen
  if AccDefaultAction = '' then
    Exit;
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
  SS: TPPGStateStyle;
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

  if UseHighContrast then
  begin
    // Hochkontrast: feste Zustaende ohne Ueberblendung und ohne Glow; die
    // Systemfarben kommen aus der Hochkontrast-Appearance (EffectiveAppearance)
    Result.GlowAlpha := 0;
    Result.Direction := gdVertical;
    if not Enabled then
      SS := EffectiveAppearance.Disabled
    else if IsDown then
      SS := EffectiveAppearance.Down
    else
      SS := EffectiveAppearance.Normal;
    Result.Color := PPGColorToRGB(SS.Color);
    Result.TextColor := PPGColorToRGB(SS.TextColor);
    Result.BorderColor := PPGColorToRGB(SS.BorderColor);
    if Enabled and not IsDown and (IsHot or Focus) then
      Result.BorderColor := PPGColorToRGB(EffectiveAppearance.FocusColor);
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
  SI: TRect;
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
  // Platz fuer den Schatten (je Seite das Groessere von Glow und Schatten)
  SI := ShadowInsets;
  Result.Left := Max(Result.Left, SI.Left);
  Result.Top := Max(Result.Top, SI.Top);
  Result.Right := Min(Result.Right, ClientWidth - SI.Right);
  Result.Bottom := Min(Result.Bottom, ClientHeight - SI.Bottom);
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

function TPPGCustomControl.GetCaptionAlignment: TPPGHorzAlign;
begin
  Result := haCenter;
end;

procedure TPPGCustomControl.DrawStateImage(const ACanvas: IPPGCanvas; Index, X, Y: Integer;
  AEnabled: Boolean; const Style: TPPGSurfaceStyle);
var
  DC: HDC;
begin
  if FImageTint = itNone then
  begin
    ACanvas.DrawImage(FImages, Index, X, Y, AEnabled);
    Exit;
  end;
  // Einfarbig in der Textfarbe des Zustands (deaktiviert: dessen Textfarbe)
  DC := ACanvas.BeginGdi;
  try
    PPGGdiDrawImageTinted(DC, FImages, Index, X, Y, Style.TextColor);
  finally
    ACanvas.EndGdi(DC);
  end;
end;

function TPPGCustomControl.GetCurrentImageIndex: Integer;
begin
  Result := FImageIndex;
  if not Enabled then
  begin
    if FDisabledImageIndex >= 0 then
      Result := FDisabledImageIndex;
  end
  else if IsDown and (FPressedImageIndex >= 0) then
    Result := FPressedImageIndex
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
  Square, Old: TPPGCorners;
begin
  Style := GetCurrentStyle;
  // Koerper-Rechteck immer aus dem Hot-Stil ermitteln (maximaler Glow-Platz)
  Body := LayoutBodyRect;
  // Eckige Ecken gelten fuer Flaeche und Fokus, nicht fuer den Inhalt
  Square := SquareCorners;
  Old := PPGSetSquareCorners(ACanvas, Square);
  try
    PaintShadow(ACanvas, Body, Style.Rounding);
    DoPaintBackground(ACanvas, Body, Style);
  finally
    PPGSetSquareCorners(ACanvas, Old);
  end;
  DoPaintContent(ACanvas, Body, Style);
  Old := PPGSetSquareCorners(ACanvas, Square);
  try
    DoPaintOverlay(ACanvas, Body, Style);
  finally
    PPGSetSquareCorners(ACanvas, Old);
  end;
end;

function TPPGCustomControl.SquareCorners: TPPGCorners;
begin
  Result := PPGAllCorners - FRoundedCorners;
end;

function TPPGCustomControl.ShadowInsets: TRect;
var
  E, O: Integer;
begin
  Result := Rect(0, 0, 0, 0);
  if (FShadow = nil) or not FShadow.IsVisible or UseHighContrast then
    Exit;
  E := PPGScale(FShadow.Size, ScalePPI);
  O := PPGScale(FShadow.OffsetY, ScalePPI);
  Result := Rect(E, Max(0, E - O), E, Max(0, E + O));
end;

procedure TPPGCustomControl.PaintShadow(const ACanvas: IPPGCanvas; const Body: TRect; Radius: Integer);
var
  E, I, A: Integer;
  R, SR: TRect;
  C: TColor;
begin
  if (FShadow = nil) or not FShadow.IsVisible or UseHighContrast or
    IsRectEmpty(Body) then
    Exit;
  E := PPGScale(FShadow.Size, ScalePPI);
  if E <= 0 then
    Exit;
  R := Body;
  OffsetRect(R, 0, PPGScale(FShadow.OffsetY, ScalePPI));
  C := PPGColorToRGB(FShadow.Color);
  // Gestapelte Flaechen: an der Kante volle Deckkraft, nach aussen linear weniger
  A := Max(1, FShadow.Opacity div E);
  for I := E downto 1 do
  begin
    SR := R;
    InflateRect(SR, I, I);
    ACanvas.FillRoundRect(SR, Radius + I, C, A);
  end;
end;

procedure TPPGCustomControl.SetRoundedCorners(const Value: TPPGCorners);
begin
  if FRoundedCorners <> Value then
  begin
    FRoundedCorners := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomControl.SetShadow(const Value: TPPGShadow);
begin
  FShadow.Assign(Value);
end;

procedure TPPGCustomControl.ShadowChanged(Sender: TObject);
begin
  // Der Schatten verkleinert die Flaeche: Inhalt (und Kinder) neu ausrichten
  if not (csLoading in ComponentState) and not (csDestroying in ComponentState) then
    Realign;
  Invalidate;
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
  F, Temp: TFont;
begin
  if IsRectEmpty(Content) then
    Exit;
  Text := Caption;
  ImgIndex := GetCurrentImageIndex;
  Temp := nil;
  try
    // Zusaetzliche Schriftstile des Zustands (Appearance.Hot.FontStyle ...)
    F := PPGStyledFont(Font, Style.FontStyle, Temp);
    FillChar(Input, SizeOf(Input), 0);
    Input.Bounds := Content;
    if ImgIndex >= 0 then
    begin
      Input.ImageSize.cx := FImages.Width;
      Input.ImageSize.cy := FImages.Height;
    end;
    if Text <> '' then
      Input.TextSize := ACanvas.MeasureText(Text, F, Content.Right - Content.Left, FWordWrap);
    Input.ImagePosition := FImagePosition;
    Input.Spacing := PPGScale(FSpacing, ScalePPI);
    Input.Alignment := GetCaptionAlignment;
    Input.RightToLeft := UseRightToLeftAlignment;
    Layout := TPPGLayoutEngine.Calculate(Input);

    if ImgIndex >= 0 then
    begin
      // Graues Bild nur, wenn kein eigenes DisabledImageIndex gesetzt ist
      ImgEnabled := Enabled or (FDisabledImageIndex >= 0);
      DrawStateImage(ACanvas, ImgIndex, Layout.ImageRect.Left, Layout.ImageRect.Top,
        ImgEnabled, Style);
    end;
    if Text <> '' then
      ACanvas.DrawText(Layout.TextRect, Text, F, Style.TextColor, GetTextFlags);
  finally
    Temp.Free;
  end;
end;

procedure TPPGCustomControl.DoPaintOverlay(const ACanvas: IPPGCanvas; const Body: TRect;
  const Style: TPPGSurfaceStyle);
begin
  if Style.Focused then
    FRenderer.DrawFocus(ACanvas, Body, Style);
end;

function PPGImagesOf(Start: TPersistent): TCustomImageList;
var
  P: TPersistent;
  O: TObject;
  Depth: Integer;
begin
  Result := nil;
  P := Start;
  for Depth := 1 to 16 do
  begin
    if P = nil then
      Exit;
    if (P is TComponent) and IsPublishedProp(P, 'Images') then
    begin
      O := GetObjectProp(P, 'Images');
      if O is TCustomImageList then
        Exit(TCustomImageList(O));
    end;
    if P is TCollectionItem then
      P := TCollectionItem(P).Collection
    else if P is TCollection then
      P := TCollection(P).Owner
    else if P is TControl then
      P := TControl(P).Parent
    else
      Exit;
  end;
end;

function PPGWheelScrollLines: Integer;
var
  L: UINT;
begin
  L := 3;
  if not SystemParametersInfo(SPI_GETWHEELSCROLLLINES, 0, @L, 0) then
    L := 3;
  if L = UINT($FFFFFFFF) then // WHEEL_PAGESCROLL
    Result := -1
  else if L > 1000 then
    Result := 1000
  else
    Result := Integer(L);
end;

function PPGWheelSteps(var Rest: Integer; Delta, Lines: Integer): Integer;
begin
  if ((Delta > 0) and (Rest < 0)) or ((Delta < 0) and (Rest > 0)) then
    Rest := 0;
  Inc(Rest, Delta * Lines);
  Result := Rest div WHEEL_DELTA; // schneidet zur Null hin ab: Rest behaelt das Vorzeichen
  Dec(Rest, Result * WHEEL_DELTA);
end;

function TPPGCustomControl.WheelSteps(WheelDelta: Integer; Lines: Integer): Integer;
begin
  Result := PPGWheelSteps(FWheelRest, WheelDelta, Lines);
end;

function TPPGCustomControl.WheelNeedsFocus: Boolean;
var
  F: HWND;
begin
  Result := True;
  if not HandleAllocated then
    Exit;
  F := GetFocus;
  Result := not ((F <> 0) and ((F = Handle) or IsChild(Handle, F)));
end;

initialization
  GMsgAccDefaultAction := RegisterWindowMessage('PPGlow.AccDefaultAction');

end.
