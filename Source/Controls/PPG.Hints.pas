unit PPG.Hints;

{ Hints im Stil der Suite (Phase 11e).

  TPPGHintManager (nicht sichtbare Komponente, Opt-in):
  - setzt zur Laufzeit Vcl.Forms.HintWindowClass := TPPGHintWindow und stellt
    beim Freigeben die vorige Klasse wieder her. Zur Entwurfszeit nie (sonst
    bekaeme die IDE selbst diese Hints).
  - Die VCL legt ihr Hint-Fenster erst beim ersten Hint an; nach dem Wechsel
    wird es ueber Application.ShowHint := False/True neu erzeugt.
  - Hint-Text "Titel|Text" wie bei der VCL: zeigt die VCL sonst nur den kurzen
    Teil, zeigt der Manager (ShowTitle) Titel fett und Text darunter. Ein
    Control, das den Text in CM_HINTSHOW selbst setzt, behaelt ihn.
  - Optional Markup (<b>, <i>, <color=...>) ueber PPG.Markup.

  TPPGHintWindow (THintWindow):
  - zeichnet ueber IPPGHintRenderer mit den Farben des Presets (Hell/Dunkel,
    Hochkontrast: clInfoBk/clInfoText).
  - Groesse und Schrift fuer die DPI des Monitors unter dem Mauszeiger.
  - Schatten ueber CS_DROPSHADOW (vom THintWindow), kein Layered-Alpha.
  - Screenreader: Rolle Tooltip und Name = Text (IAccPropServices),
    EVENT_OBJECT_SHOW beim Zeigen.

  TPPGCustomHint (TCustomHint):
  - fuer die CustomHint-Property einzelner Controls (wie TBalloonHint):
    Title, Description, Images/ImageIndex; zeichnet wie TPPGHintWindow.

  Gemeinsam: TPPGHintContent misst und zeichnet den Inhalt (DRY). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.AppEvnts, Vcl.ImgList,
  PPG.Types, PPG.Tokens, PPG.Render.Intf, PPG.StyleManager, PPG.Markup;

type
  /// THintInfo je nach Delphi-Version (PPG.inc)
  {$IFDEF PPG_HINTINFO_IN_CONTROLS}
  TPPGHintInfo = Vcl.Controls.THintInfo;
  {$ELSE}
  TPPGHintInfo = Vcl.Forms.THintInfo;
  {$ENDIF}

  /// Inhalt eines Hints: Titel fett, Text (Markup) darunter, Bild links.
  TPPGHintContent = class
  private
    FPPI: Integer;
    FTitle: string;
    FText: string;
    FTitleSize: TSize;
    FLayout: TPPGMarkupLayout;
    FTitleFont: TFont;
    FTextFont: TFont;
    FImages: TCustomImageList;
    FImageIndex: Integer;
    function Pad: Integer;
    function Gap: Integer;
    function HasImage: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    /// Text ohne Markup wird maskiert (< und & bleiben sichtbar).
    procedure Prepare(APPI: Integer; const ATitle, AText: string; Markup: Boolean;
      AImages: TCustomImageList = nil; AImageIndex: Integer = -1);
    /// Gesamtgroesse inkl. Rand; MaxWidth in physischen px fuer den Text.
    function Measure(MaxWidth: Integer): TSize;
    procedure Paint(Canvas: TCanvas; const R: TRect; const Preset: string);
    property PPI: Integer read FPPI;
    property Title: string read FTitle;
    property Text: string read FText;
  end;

  TPPGHintManager = class;

  TPPGHintWindow = class(THintWindow)
  private
    FContent: TPPGHintContent;
    FPaintErrorReported: Boolean;
    procedure Parse(const AHint: string);
    function GetPPI: Integer;
    function GetHintText: string;
    function GetHintTitle: string;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure NCPaint(DC: HDC); override;
    procedure Paint; override;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CalcHintRect(MaxWidth: Integer; const AHint: string; AData: Pointer): TRect; override;
    procedure ActivateHint(Rect: TRect; const AHint: string); override;
    /// Farben, wie sie gezeichnet werden (Tests).
    procedure GetColors(out Fill, Border, Text: TColor);
    property HintTitle: string read GetHintTitle;
    property HintText: string read GetHintText;
    property PPI: Integer read GetPPI;
  end;

  TPPGHintManager = class(TComponent)
  private
    FActive: Boolean;
    FPreset: string;
    FStyleManager: TPPGStyleManager;
    FShowTitle: Boolean;
    FAllowMarkup: Boolean;
    FMaxWidth: Integer;
    FEvents: TApplicationEvents;
    FPrevClass: THintWindowClass;
    FApplied: Boolean;
    procedure SetActive(const Value: Boolean);
    procedure SetStyleManager(const Value: TPPGStyleManager);
    procedure SetMaxWidth(const Value: Integer);
    procedure Apply;
    procedure Revert;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    /// Application.OnShowHint: "Titel|Text" vollstaendig weitergeben.
    procedure DoShowHint(var HintStr: string; var CanShow: Boolean;
      var HintInfo: TPPGHintInfo); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Name des Presets, nach dem gezeichnet wird.
    function EffectivePreset: string;
    function Tokens: TPPGTokens;
    /// True, solange dieser Manager die Hints der Anwendung stellt.
    property Applied: Boolean read FApplied;
  published
    property Active: Boolean read FActive write SetActive default True;
    /// Preset der Hints ('' = Standard bzw. StyleManager).
    property Preset: string read FPreset write FPreset;
    property StyleManager: TPPGStyleManager read FStyleManager write SetStyleManager;
    /// "Titel|Text": Titel fett, Text darunter (sonst nur der kurze Teil).
    property ShowTitle: Boolean read FShowTitle write FShowTitle default True;
    property AllowMarkup: Boolean read FAllowMarkup write FAllowMarkup default False;
    /// Groesste Breite in logischen px.
    property MaxWidth: Integer read FMaxWidth write SetMaxWidth default 360;
  end;

  /// Fuer die CustomHint-Property einzelner Controls (wie TBalloonHint).
  TPPGCustomHint = class(TCustomHint)
  private
    FContent: TPPGHintContent;
    FPaintErrorReported: Boolean;
    FPreset: string;
    FStyleManager: TPPGStyleManager;
    FAllowMarkup: Boolean;
    FMaxWidth: Integer;
    procedure SetStyleManager(const Value: TPPGStyleManager);
    procedure SetMaxWidth(const Value: Integer);
    function PrepareFor(HintWindow: TCustomHintWindow; APPI: Integer): TSize;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PaintHint(HintWindow: TCustomHintWindow); override;
    procedure SetHintSize(HintWindow: TCustomHintWindow); override;
    function EffectivePreset: string;
  published
    property Preset: string read FPreset write FPreset;
    property StyleManager: TPPGStyleManager read FStyleManager write SetStyleManager;
    property AllowMarkup: Boolean read FAllowMarkup write FAllowMarkup default False;
    property MaxWidth: Integer read FMaxWidth write SetMaxWidth default 360;
    property Style default bhsStandard;
  end;

/// Der Manager, der gerade die Hints stellt (nil = keiner).
function PPGActiveHintManager: TPPGHintManager;
/// Farben eines Hints fuer ein Preset (Hochkontrast und VCL-Style beachtet).
procedure PPGHintColors(const Preset: string; out Fill, Border, Text: TColor);
/// Preset-Name pruefen: leer oder unbekannt = Standard.
function PPGHintPreset(StyleManager: TPPGStyleManager; const Preset: string): string;

implementation

uses
  System.Math, System.UITypes, Winapi.oleacc, Vcl.Themes,
  PPG.Appearance, PPG.DpiUtils, PPG.Theme, PPG.Accessibility, PPG.Exceptions,
  PPG.Render.Registry, PPG.Render.Gdi, PPG.ErrorHandler;

type
  TCustomHintWindowAccess = class(TCustomHintWindow);

var
  GManager: TPPGHintManager = nil;

function PPGActiveHintManager: TPPGHintManager;
begin
  Result := GManager;
end;

function PPIAtPoint(const P: TPoint): Integer;
{$IFDEF PPG_HAS_PPI}
var
  M: TMonitor;
{$ENDIF}
begin
  // Vor 10.3 gibt es keine DPI je Monitor: System-DPI
  Result := Screen.PixelsPerInch;
{$IFDEF PPG_HAS_PPI}
  M := Screen.MonitorFromPoint(P, mdNearest);
  if M <> nil then
    Result := M.PixelsPerInch;
{$ENDIF}
  if Result <= 0 then
    Result := 96;
end;

function CursorPPI: Integer;
var
  P: TPoint;
begin
  if not GetCursorPos(P) then
    P := Point(0, 0);
  Result := PPIAtPoint(P);
end;

function PPGHintPreset(StyleManager: TPPGStyleManager; const Preset: string): string;
begin
  if StyleManager <> nil then
    Result := StyleManager.Preset
  else
    Result := Preset;
  if (Result = '') or not TPPGRendererRegistry.IsRegistered(Result) then
    Result := TPPGRendererRegistry.DefaultName;
end;

function PresetTokens(const Preset: string): TPPGTokens;
var
  TR: IPPGThemeRenderer;
begin
  if Supports(TPPGRendererRegistry.Get(Preset), IPPGThemeRenderer, TR) then
    Result := TR.Tokens(TPPGTheme.IsDark)
  else
    Result := PPGDefaultTokens(TPPGTheme.IsDark);
end;

procedure PPGHintColors(const Preset: string; out Fill, Border, Text: TColor);
var
  T: TPPGTokens;
begin
  if PPGIsHighContrast then
  begin
    Fill := PPGColorToRGB(clInfoBk);
    Text := PPGColorToRGB(clInfoText);
    Border := Text;
    Exit;
  end;
  if not StyleServices.IsSystemStyle then
  begin
    // Aktiver VCL-Style: dessen Hint-Farben
    Fill := StyleServices.GetSystemColor(clInfoBk);
    Text := StyleServices.GetSystemColor(clInfoText);
    Border := PPGBlendColor(Fill, Text, 0.3);
    Exit;
  end;
  T := PresetTokens(PPGHintPreset(nil, Preset));
  Fill := T.Layer;
  Text := T.TextPrimary;
  Border := T.StrokeStrong;
end;

function EscapeMarkup(const S: string): string;
begin
  Result := StringReplace(StringReplace(S, '&', '&amp;', [rfReplaceAll]), '<', '&lt;',
    [rfReplaceAll]);
end;

{ TPPGHintContent }

constructor TPPGHintContent.Create;
begin
  inherited Create;
  FLayout := TPPGMarkupLayout.Create;
  FTitleFont := TFont.Create;
  FTextFont := TFont.Create;
  FPPI := 96;
  FImageIndex := -1;
end;

destructor TPPGHintContent.Destroy;
begin
  FreeAndNil(FLayout);
  FreeAndNil(FTitleFont);
  FreeAndNil(FTextFont);
  inherited Destroy;
end;

function TPPGHintContent.Pad: Integer;
begin
  Result := MulDiv(8, FPPI, 96);
end;

function TPPGHintContent.Gap: Integer;
begin
  Result := MulDiv(3, FPPI, 96);
end;

function TPPGHintContent.HasImage: Boolean;
begin
  Result := (FImages <> nil) and (FImageIndex >= 0) and (FImageIndex < FImages.Count);
end;

procedure TPPGHintContent.Prepare(APPI: Integer; const ATitle, AText: string;
  Markup: Boolean; AImages: TCustomImageList; AImageIndex: Integer);
begin
  if APPI <= 0 then
    APPI := 96;
  FPPI := APPI;
  // Systemschrift fuer Hints in der DPI des Zielmonitors
  FTextFont.Assign(Screen.HintFont);
  FTextFont.Height := MulDiv(Screen.HintFont.Height, FPPI, Screen.PixelsPerInch);
  FTitleFont.Assign(FTextFont);
  FTitleFont.Style := FTitleFont.Style + [fsBold];
  FTitle := ATitle;
  if Markup then
    FText := AText
  else
    FText := EscapeMarkup(AText);
  FImages := AImages;
  FImageIndex := AImageIndex;
end;

function TPPGHintContent.Measure(MaxWidth: Integer): TSize;
var
  W, H, IW: Integer;
begin
  IW := 0;
  if HasImage then
  begin
    IW := FImages.Width + Pad;
    Dec(MaxWidth, IW);
  end;
  MaxWidth := Max(MaxWidth, MulDiv(40, FPPI, 96));
  W := 0;
  H := 0;
  FTitleSize.cx := 0;
  FTitleSize.cy := 0;
  if FTitle <> '' then
  begin
    FTitleSize := PPGMeasureTextNoCanvas(FTitle, FTitleFont, MaxWidth, True);
    W := FTitleSize.cx;
    H := FTitleSize.cy;
  end;
  if FText <> '' then
  begin
    FLayout.Layout(FText, FTextFont, nil, MaxWidth, True);
    W := Max(W, FLayout.Size.cx);
    if H > 0 then
      Inc(H, Gap);
    Inc(H, FLayout.Size.cy);
  end;
  if HasImage then
    H := Max(H, FImages.Height);
  Result.cx := W + IW + 2 * Pad;
  Result.cy := H + 2 * Pad - MulDiv(1, FPPI, 96);
end;

procedure TPPGHintContent.Paint(Canvas: TCanvas; const R: TRect; const Preset: string);
var
  C: IPPGCanvas;
  HR: IPPGHintRenderer;
  Style: TPPGSurfaceStyle;
  Fill, Border, TextColor: TColor;
  X, Y: Integer;
begin
  PPGHintColors(Preset, Fill, Border, TextColor);
  FillChar(Style, SizeOf(Style), 0);
  Style.Color := Fill;
  Style.BorderColor := Border;
  Style.BorderWidth := Max(MulDiv(1, FPPI, 96), 1);
  Style.Rounding := MulDiv(4, FPPI, 96);
  if not Supports(TPPGRendererRegistry.Get(PPGHintPreset(nil, Preset)), IPPGHintRenderer, HR) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName), IPPGHintRenderer, HR);
  // Ecken ausserhalb der Rundung: Hintergrund des Fensters
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Fill;
  Canvas.FillRect(R);
  X := R.Left + Pad;
  if HasImage then
    Inc(X, FImages.Width + Pad);
  C := TPPGRendererRegistry.CreateCanvas(Canvas.Handle);
  try
    HR.DrawHint(C, R, Style, FPPI);
    Y := R.Top + Pad - MulDiv(1, FPPI, 96) div 2;
    if FTitle <> '' then
    begin
      C.DrawText(Rect(X, Y, R.Right - Pad, Y + FTitleSize.cy), FTitle, FTitleFont, TextColor,
        DT_WORDBREAK or DT_NOPREFIX);
      Inc(Y, FTitleSize.cy + Gap);
    end;
    if FText <> '' then
      FLayout.Draw(C, X, Y, TextColor, PPGColorToRGB(clHotLight));
  finally
    C := nil;
  end;
  if HasImage then
    FImages.Draw(Canvas, R.Left + Pad, R.Top + Pad, FImageIndex);
end;

{ TPPGHintWindow }

constructor TPPGHintWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FContent := TPPGHintContent.Create;
end;

destructor TPPGHintWindow.Destroy;
begin
  FreeAndNil(FContent);
  inherited Destroy;
end;

procedure TPPGHintWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Rahmen zeichnet der Renderer (abgerundet), nicht Windows
  Params.Style := Params.Style and not WS_BORDER;
end;

procedure TPPGHintWindow.NCPaint(DC: HDC);
begin
  // kein Nicht-Client-Rahmen
end;

procedure TPPGHintWindow.WMNCHitTest(var Message: TWMNCHitTest);
begin
  Message.Result := HTTRANSPARENT;
end;

function TPPGHintWindow.GetPPI: Integer;
begin
  Result := FContent.PPI;
end;

function TPPGHintWindow.GetHintText: string;
begin
  Result := FContent.Text;
end;

function TPPGHintWindow.GetHintTitle: string;
begin
  Result := FContent.Title;
end;

procedure TPPGHintWindow.Parse(const AHint: string);
var
  M: TPPGHintManager;
  T, S: string;
begin
  M := GManager;
  if (M <> nil) and M.ShowTitle and (Pos('|', AHint) > 0) then
  begin
    T := GetShortHint(AHint);
    S := GetLongHint(AHint);
    if S = T then
      S := '';
  end
  else
  begin
    T := '';
    S := GetShortHint(AHint);
  end;
  FContent.Prepare(CursorPPI, T, S, (M <> nil) and M.AllowMarkup);
end;

function TPPGHintWindow.CalcHintRect(MaxWidth: Integer; const AHint: string;
  AData: Pointer): TRect;
var
  MW: Integer;
  S: TSize;
begin
  Parse(AHint);
  if GManager <> nil then
    MW := MulDiv(GManager.MaxWidth, PPI, 96)
  else
    MW := MulDiv(360, PPI, 96);
  if (MaxWidth > 0) and (MaxWidth < MW) then
    MW := MaxWidth;
  S := FContent.Measure(MW - 2 * MulDiv(8, PPI, 96));
  Result := Rect(0, 0, S.cx, S.cy);
end;

procedure TPPGHintWindow.ActivateHint(Rect: TRect; const AHint: string);
begin
  inherited ActivateHint(Rect, AHint);
  if HandleAllocated then
  begin
    PPGAccSetWindowRole(Handle, ROLE_SYSTEM_TOOLTIP);
    if HintTitle <> '' then
      PPGAccSetWindowName(Handle, HintTitle + ' ' + GetLongHint(AHint))
    else
      PPGAccSetWindowName(Handle, GetShortHint(AHint));
    PPGAccNotify(Handle, EVENT_OBJECT_SHOW);
  end;
end;

procedure TPPGHintWindow.GetColors(out Fill, Border, Text: TColor);
begin
  if GManager <> nil then
    PPGHintColors(GManager.EffectivePreset, Fill, Border, Text)
  else
    PPGHintColors('', Fill, Border, Text);
end;

procedure TPPGHintWindow.Paint;
begin
  try
    if GManager <> nil then
      FContent.Paint(Canvas, ClientRect, GManager.EffectivePreset)
    else
      FContent.Paint(Canvas, ClientRect, '');
    FPaintErrorReported := False;
  except
    // Grenze: Paint wirft nie (WM_PAINT-Schleife); einmal melden, Text
    // trotzdem lesbar
    on E: Exception do
    begin
      if not FPaintErrorReported then
      begin
        FPaintErrorReported := True;
        TPPGErrorHandler.ReportPaintError(Self, E);
      end;
      Canvas.Brush.Color := clInfoBk;
      Canvas.FillRect(ClientRect);
      Canvas.Font.Color := clInfoText;
      Canvas.TextOut(4, 2, Caption);
    end;
  end;
end;

{ TPPGHintManager }

constructor TPPGHintManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActive := True;
  FShowTitle := True;
  FMaxWidth := 360;
  if not (csDesigning in ComponentState) then
  begin
    FEvents := TApplicationEvents.Create(Self);
    FEvents.OnShowHint := DoShowHint;
  end;
  if not (csLoading in ComponentState) then
    Apply;
end;

destructor TPPGHintManager.Destroy;
begin
  Revert;
  FStyleManager := nil;
  inherited Destroy;
end;

procedure TPPGHintManager.Loaded;
begin
  inherited Loaded;
  Apply;
end;

procedure TPPGHintManager.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FStyleManager) then
    FStyleManager := nil;
end;

procedure RecreateApplicationHint;
var
  Old: Boolean;
begin
  // Die VCL erzeugt ihr Hint-Fenster mit HintWindowClass erst neu, wenn
  // ShowHint aus- und wieder eingeschaltet wird
  Old := Application.ShowHint;
  Application.ShowHint := False;
  Application.ShowHint := Old;
end;

procedure TPPGHintManager.Apply;
begin
  if (csDesigning in ComponentState) or (csLoading in ComponentState) or not FActive then
    Exit;
  if (GManager <> nil) and (GManager <> Self) then
    GManager.Revert;
  if HintWindowClass <> TPPGHintWindow then
    FPrevClass := HintWindowClass
  else if FPrevClass = nil then
    FPrevClass := THintWindow;
  HintWindowClass := TPPGHintWindow;
  GManager := Self;
  FApplied := True;
  RecreateApplicationHint;
end;

procedure TPPGHintManager.Revert;
begin
  if not FApplied then
    Exit;
  FApplied := False;
  if GManager = Self then
    GManager := nil;
  if HintWindowClass = TPPGHintWindow then
  begin
    if FPrevClass <> nil then
      HintWindowClass := FPrevClass
    else
      HintWindowClass := THintWindow;
    if not Application.Terminated then
      RecreateApplicationHint;
  end;
end;

procedure TPPGHintManager.SetActive(const Value: Boolean);
begin
  if FActive = Value then
    Exit;
  FActive := Value;
  if FActive then
    Apply
  else
    Revert;
end;

procedure TPPGHintManager.SetStyleManager(const Value: TPPGStyleManager);
begin
  if FStyleManager = Value then
    Exit;
  if FStyleManager <> nil then
    FStyleManager.RemoveFreeNotification(Self);
  FStyleManager := Value;
  if FStyleManager <> nil then
    FStyleManager.FreeNotification(Self);
end;

procedure TPPGHintManager.SetMaxWidth(const Value: Integer);
begin
  FMaxWidth := PPGCheckRange(Self, 'MaxWidth', Value, 80, 2000);
end;

function TPPGHintManager.EffectivePreset: string;
begin
  Result := PPGHintPreset(FStyleManager, FPreset);
end;

function TPPGHintManager.Tokens: TPPGTokens;
begin
  Result := PresetTokens(EffectivePreset);
end;

procedure TPPGHintManager.DoShowHint(var HintStr: string; var CanShow: Boolean;
  var HintInfo: TPPGHintInfo);
var
  Full: string;
begin
  if not FApplied or not FShowTitle or (HintInfo.HintControl = nil) then
    Exit;
  Full := HintInfo.HintControl.Hint;
  // Nur den unveraenderten Standardtext ersetzen: ein Control, das den Text
  // in CM_HINTSHOW selbst gesetzt hat, behaelt seinen
  if (Pos('|', Full) > 0) and (HintStr = GetShortHint(Full)) then
    HintStr := Full;
end;

{ TPPGCustomHint }

constructor TPPGCustomHint.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FContent := TPPGHintContent.Create;
  FMaxWidth := 360;
  Style := bhsStandard;
end;

destructor TPPGCustomHint.Destroy;
begin
  FStyleManager := nil;
  FreeAndNil(FContent);
  inherited Destroy;
end;

procedure TPPGCustomHint.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FStyleManager) then
    FStyleManager := nil;
end;

procedure TPPGCustomHint.SetStyleManager(const Value: TPPGStyleManager);
begin
  if FStyleManager = Value then
    Exit;
  if FStyleManager <> nil then
    FStyleManager.RemoveFreeNotification(Self);
  FStyleManager := Value;
  if FStyleManager <> nil then
    FStyleManager.FreeNotification(Self);
end;

procedure TPPGCustomHint.SetMaxWidth(const Value: Integer);
begin
  FMaxWidth := PPGCheckRange(Self, 'MaxWidth', Value, 80, 2000);
end;

function TPPGCustomHint.EffectivePreset: string;
begin
  Result := PPGHintPreset(FStyleManager, FPreset);
end;

function TPPGCustomHint.PrepareFor(HintWindow: TCustomHintWindow; APPI: Integer): TSize;
begin
  // Ein TPPGCustomHint kann mehrere Fenster gleichzeitig haben (Ein-/Ausblenden
  // im VCL-Thread): Inhalt immer aus dem Fenster neu aufbauen
  FContent.Prepare(APPI, HintWindow.Title, HintWindow.Description, FAllowMarkup, Images,
    HintWindow.ImageIndex);
  Result := FContent.Measure(MulDiv(FMaxWidth - 16, APPI, 96));
end;

procedure TPPGCustomHint.SetHintSize(HintWindow: TCustomHintWindow);
var
  S: TSize;
begin
  // Das Fenster steht noch nicht: DPI des Monitors unter dem Mauszeiger
  S := PrepareFor(HintWindow, CursorPPI);
  HintWindow.Width := S.cx;
  HintWindow.Height := S.cy;
end;

procedure TPPGCustomHint.PaintHint(HintWindow: TCustomHintWindow);
var
  R: TRect;
begin
  try
    GetWindowRect(HintWindow.Handle, R);
    PrepareFor(HintWindow, PPIAtPoint(R.TopLeft));
    FContent.Paint(TCustomHintWindowAccess(HintWindow).Canvas, HintWindow.ClientRect, EffectivePreset);
    FPaintErrorReported := False;
  except
    // Grenze wie im Paint der Controls: kein Dialog (HandleCallbackError
    // oeffnete einen je WM_PAINT), einmal melden, Notfall-Zustand zeichnen
    on E: Exception do
    begin
      if not FPaintErrorReported then
      begin
        FPaintErrorReported := True;
        TPPGErrorHandler.ReportPaintError(Self, E);
      end;
      TCustomHintWindowAccess(HintWindow).Canvas.Brush.Color := clInfoBk;
      TCustomHintWindowAccess(HintWindow).Canvas.FillRect(HintWindow.ClientRect);
      TCustomHintWindowAccess(HintWindow).Canvas.Font.Color := clInfoText;
      TCustomHintWindowAccess(HintWindow).Canvas.TextOut(4, 2, TCustomHintWindowAccess(HintWindow).Caption);
    end;
  end;
end;

initialization

finalization
  GManager := nil;

end.
