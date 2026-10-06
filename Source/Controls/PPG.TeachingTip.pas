unit PPG.TeachingTip;

{ TeachingTip (Phase 11f): Sprechblase mit Pfeil, an ein Control geheftet
  (wie WinUI TeachingTip). Grundlage der gefuehrten Tour (Phase 16).

  - Inhalt: Symbol, Titel, Untertitel, Text mit Markup und Links, bis zu zwei
    Buttons (Aktion = Akzent, Schliessen) und ein Schliessen-Kreuz.
  - Anheften: Target (FreeNotification) und Placement (Auto: oben, unten,
    links, rechts - die erste Seite, auf die die Blase ganz passt). Bewegt
    sich das Ziel oder sein Formular, folgt die Blase (PPGWatchControl).
    Ist das Ziel unsichtbar oder das Formular minimiert, wird sie nur
    ausgeblendet und kommt danach wieder. Ohne Target: unten rechts im
    Formular, ohne Pfeil.
  - Modi: LightDismiss = Klick daneben oder Wechsel der Anwendung schliesst
    (der Klick geht trotzdem an sein Ziel); sonst nur Buttons oder Esc. Ein
    fester TeachingTip nimmt die Tastatur: Tab/Umschalt+Tab wechselt zwischen
    den Buttons, Enter/Leertaste loest aus (ueber PPG.AppHooks, das Fenster
    wird nie aktiviert - der Fokus bleibt im Formular).
  - Ereignisse nur bei Anwenderaktionen (Suite-Regel): OnActionClick,
    OnLinkClick, OnClosing (abbrechbar), OnClose. Show/Hide aus Code loesen
    keine Ereignisse aus. Der Aktions-Button schliesst nicht selbst (wie
    WinUI); die Anwendung entscheidet (z.B. Tour: naechster Schritt).
  - Ein Ereignis darf den TeachingTip freigeben: danach wird Self nicht mehr
    angefasst, das Fenster gibt sich bei Bedarf verzoegert frei (CM_RELEASE).
  - Screenreader: Rolle Dialog, Name = Titel, Buttons als Kinder;
    EVENT_SYSTEM_ALERT beim Zeigen.

  Nicht umgesetzt (bewusst): Bild oben (Hero), Links per Tab, Scrollen
  innerhalb verschobener ScrollBoxen ohne WM_WINDOWPOSCHANGED. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms,
  PPG.Types, PPG.Tokens, PPG.Render.Intf, PPG.StyleManager, PPG.Markup,
  PPG.Accessibility, PPG.Controls.Base, PPG.Popup, PPG.Popup.Placement;

type
  TPPGTipPlacementMode = (tpAuto, tpTop, tpBottom, tpLeft, tpRight);
  TPPGTipIcon = (tiNone, tiInfo, tiSuccess, tiWarning, tiError);
  /// Grund fuer das Schliessen. tcrProgrammatic nur fuer Hide aus Code
  /// (dann ohne Ereignisse).
  TPPGTipCloseReason = (tcrCloseButton, tcrLightDismiss, tcrEscape, tcrProgrammatic);
  TPPGTipPart = (tppNone, tppAction, tppClose, tppCross);

  TPPGTipClosingEvent = procedure(Sender: TObject; Reason: TPPGTipCloseReason;
    var Allow: Boolean) of object;
  TPPGTipCloseEvent = procedure(Sender: TObject; Reason: TPPGTipCloseReason) of object;
  TPPGTipLinkEvent = procedure(Sender: TObject; const Link: string) of object;

  TPPGTeachingTip = class;

  TPPGTeachingTipWindow = class(TPPGPopupWindow, IPPGAccessibleChildren)
  private
    FTip: TPPGTeachingTip;
    FLayout: TPPGMarkupLayout;
    FTitleFont: TFont;
    FSide: TPPGPopupSide;
    FHasTail: Boolean;
    FTailPos: Integer;
    FBody: TRect;            // Flaeche im Fenster (ohne Pfeil)
    FIconR: TRect;           // alle Teil-Rechtecke relativ zum Fenster
    FTitleR: TRect;
    FSubtitleR: TRect;
    FTextR: TRect;
    FParts: array[TPPGTipPart] of TRect;
    FHot: TPPGTipPart;
    FDown: TPPGTipPart;
    FFocus: TPPGTipPart;
    FKeyboardUsed: Boolean;
    FInHandler: Integer;
    FReleasePending: Boolean;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMRelease(var Message: TMessage); message CM_RELEASE;
    procedure WMTipActivate(var Message: TMessage); message WM_USER + $511;
    procedure WMTipReposition(var Message: TMessage); message WM_USER + $512;
    function TailLen: Integer;
    function TailHalf: Integer;
    function Pad: Integer;
    procedure TailPoints(out P: array of TPoint);
  protected
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function PopupRounding: Integer; override;
    procedure ApplyRegion; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function AccName: string; override;
    function AccRole: Integer; override;
    function AccDescription: string; override;
    { IPPGAccessibleChildren }
    function AccChildCount: Integer;
    function AccChildName(Id: Integer): string;
    function AccChildRole(Id: Integer): Integer;
    function AccChildState(Id: Integer): Integer;
    function AccChildRect(Id: Integer): TRect;
    function AccChildAt(X, Y: Integer): Integer;
    function AccChildDefaultAction(Id: Integer): string;
    procedure AccChildDoDefault(Id: Integer);
    function AccFocusedChild: Integer;
    function AccSelectedChild: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Misst den Inhalt fuer die PPI und liefert die Groesse der Flaeche.
    function MeasureBody(APPI: Integer): TSize;
    /// Ordnet die Teile in der Flaeche an (nach MeasureBody und Platzierung).
    procedure Arrange(const Placement: TPPGTipPlacement; HasTail: Boolean);
    function PartAt(X, Y: Integer): TPPGTipPart;
    function PartRect(Part: TPPGTipPart): TRect;
    function PartVisible(Part: TPPGTipPart): Boolean;
    /// Teile in Tab-Reihenfolge.
    function TabParts: TArray<TPPGTipPart>;
    property Side: TPPGPopupSide read FSide;
    property HasTail: Boolean read FHasTail;
    property TailPos: Integer read FTailPos;
    property Body: TRect read FBody;
    property Hot: TPPGTipPart read FHot;
    property FocusPart: TPPGTipPart read FFocus;
    property Tip: TPPGTeachingTip read FTip;
    property Preset;
    property StyleManager;
  end;

  TPPGTeachingTip = class(TComponent)
  private
    FTarget: TControl;
    FWatchedForm: TCustomForm;
    FTitle: string;
    FSubtitle: string;
    FText: string;
    FIcon: TPPGTipIcon;
    FActionButtonText: string;
    FCloseButtonText: string;
    FShowCloseButton: Boolean;
    FLightDismiss: Boolean;
    FPlacement: TPPGTipPlacementMode;
    FMaxWidth: Integer;
    FPreset: string;
    FStyleManager: TPPGStyleManager;
    FWindow: TPPGTeachingTipWindow;
    FOpen: Boolean;
    FHooked: Boolean;
    FPPI: Integer;
    FOnActionClick: TNotifyEvent;
    FOnLinkClick: TPPGTipLinkEvent;
    FOnClosing: TPPGTipClosingEvent;
    FOnClose: TPPGTipCloseEvent;
    procedure SetTarget(const Value: TControl);
    procedure SetStyleManager(const Value: TPPGStyleManager);
    procedure SetMaxWidth(const Value: Integer);
    procedure SetText(const Index: Integer; const Value: string);
    procedure SetIcon(const Value: TPPGTipIcon);
    procedure SetShowCloseButton(const Value: Boolean);
    procedure SetPlacement(const Value: TPPGTipPlacementMode);
    procedure Watch;
    procedure Unwatch;
    procedure WatchEvent(Control: TControl; var Message: TMessage);
    procedure AppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure AppDeactivate(Sender: TObject);
    procedure HideWindow;
    procedure ContentChanged;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    /// Anwender hat einen Teil ausgeloest (Maus, Tastatur, Screenreader).
    /// Loest Ereignisse aus; danach darf Self freigegeben sein.
    procedure ActivatePart(Part: TPPGTipPart);
    procedure DoLinkClick(const Link: string);
    /// Schliessen durch den Anwender: OnClosing (abbrechbar), dann OnClose.
    procedure RequestClose(Reason: TPPGTipCloseReason);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Zeigt den TeachingTip (ohne Ereignisse).
    procedure Show;
    /// Zeigt ihn an ATarget (setzt Target).
    procedure ShowFor(ATarget: TControl);
    /// Schliesst ohne Ereignisse.
    procedure Hide;
    /// Lage neu berechnen (folgt dem Ziel; normalerweise automatisch).
    procedure UpdatePosition;
    function IsOpen: Boolean;
    function EffectivePreset: string;
    /// Bildschirm-Rechteck des Ziels (bzw. des Formulars ohne Ziel).
    function AnchorRect: TRect;
    property Window: TPPGTeachingTipWindow read FWindow;
  published
    property Target: TControl read FTarget write SetTarget;
    property Title: string index 0 read FTitle write SetText;
    property Subtitle: string index 1 read FSubtitle write SetText;
    /// Text mit Markup (<b>, <i>, <a href=...>).
    property Text: string index 2 read FText write SetText;
    property ActionButtonText: string index 3 read FActionButtonText write SetText;
    property CloseButtonText: string index 4 read FCloseButtonText write SetText;
    property Icon: TPPGTipIcon read FIcon write SetIcon default tiNone;
    /// Kreuz oben rechts (nur ohne CloseButtonText, wie WinUI).
    property ShowCloseButton: Boolean read FShowCloseButton write SetShowCloseButton default True;
    property LightDismiss: Boolean read FLightDismiss write FLightDismiss default False;
    property Placement: TPPGTipPlacementMode read FPlacement write SetPlacement default tpAuto;
    /// Breite der Flaeche in logischen px.
    property MaxWidth: Integer read FMaxWidth write SetMaxWidth default 320;
    property Preset: string read FPreset write FPreset;
    property StyleManager: TPPGStyleManager read FStyleManager write SetStyleManager;
    property OnActionClick: TNotifyEvent read FOnActionClick write FOnActionClick;
    property OnLinkClick: TPPGTipLinkEvent read FOnLinkClick write FOnLinkClick;
    property OnClosing: TPPGTipClosingEvent read FOnClosing write FOnClosing;
    property OnClose: TPPGTipCloseEvent read FOnClose write FOnClose;
  end;

implementation

uses
  PPG.Lang,
  System.Math, Winapi.oleacc,
  PPG.Consts, PPG.Appearance, PPG.DpiUtils, PPG.Exceptions, PPG.ErrorHandler,
  Vcl.Menus, PPG.Render.Registry, PPG.Render.Gdi, PPG.IconFont, PPG.AppHooks, PPG.Hints;

const
  WM_TIPACTIVATE = WM_USER + $511;
  WM_TIPREPOSITION = WM_USER + $512;
  IconSize = 20;      // logische px
  ButtonH = 32;
  CrossSize = 32;

function MonitorPPI(const R: TRect): Integer;
{$IFDEF PPG_HAS_PPI}
var
  M: TMonitor;
{$ENDIF}
begin
  Result := Screen.PixelsPerInch;
{$IFDEF PPG_HAS_PPI}
  M := Screen.MonitorFromRect(R, mdNearest);
  if M <> nil then
    Result := M.PixelsPerInch;
{$ENDIF}
  if Result <= 0 then
    Result := 96;
end;

function StripAmp(const S: string): string;
begin
  Result := StripHotkey(S);
end;

{ TPPGTeachingTipWindow }

constructor TPPGTeachingTipWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLayout := TPPGMarkupLayout.Create;
  FTitleFont := TFont.Create;
  FHot := tppNone;
  FDown := tppNone;
  FFocus := tppNone;
end;

destructor TPPGTeachingTipWindow.Destroy;
begin
  FreeAndNil(FLayout);
  FreeAndNil(FTitleFont);
  inherited Destroy;
end;

function TPPGTeachingTipWindow.Pad: Integer;
begin
  Result := PPGScale(12, ScalePPI);
end;

function TPPGTeachingTipWindow.TailLen: Integer;
begin
  Result := PPGScale(8, ScalePPI);
end;

function TPPGTeachingTipWindow.TailHalf: Integer;
begin
  Result := PPGScale(8, ScalePPI);
end;

function TPPGTeachingTipWindow.PopupRounding: Integer;
begin
  Result := PPGScale(8, ScalePPI);
end;

function TPPGTeachingTipWindow.PartVisible(Part: TPPGTipPart): Boolean;
begin
  Result := False;
  if FTip = nil then
    Exit;
  case Part of
    tppAction: Result := FTip.ActionButtonText <> '';
    tppClose: Result := FTip.CloseButtonText <> '';
    tppCross: Result := FTip.ShowCloseButton and (FTip.CloseButtonText = '');
  end;
end;

function TPPGTeachingTipWindow.TabParts: TArray<TPPGTipPart>;
var
  P: TPPGTipPart;
  N: Integer;
begin
  SetLength(Result, 3);
  N := 0;
  for P := tppAction to tppCross do
    if PartVisible(P) then
    begin
      Result[N] := P;
      Inc(N);
    end;
  SetLength(Result, N);
end;

function TPPGTeachingTipWindow.MeasureBody(APPI: Integer): TSize;
var
  W, TextW, H, Y, Btn: Integer;
  S: TSize;
  BtnCount: Integer;
begin
  PopupPPI := APPI;
  // Schrift des Systems fuer Meldungen in der DPI des Zielmonitors
  Font.Assign(Screen.MessageFont);
  Font.Height := MulDiv(Screen.MessageFont.Height, APPI, Screen.PixelsPerInch);
  FTitleFont.Assign(Font);
  FTitleFont.Style := [fsBold];
  W := PPGScale(FTip.MaxWidth, APPI);
  TextW := W - 2 * Pad;
  if FTip.Icon <> tiNone then
    Dec(TextW, PPGScale(IconSize, APPI) + PPGScale(8, APPI));
  if PartVisible(tppCross) then
    Dec(TextW, PPGScale(CrossSize, APPI) - PPGScale(4, APPI));
  TextW := Max(TextW, PPGScale(60, APPI));
  Y := Pad;
  FTitleR := Rect(0, 0, 0, 0);
  FSubtitleR := Rect(0, 0, 0, 0);
  FTextR := Rect(0, 0, 0, 0);
  if FTip.Title <> '' then
  begin
    S := PPGMeasureTextNoCanvas(FTip.Title, FTitleFont, TextW, True);
    FTitleR := Rect(0, Y, S.cx, Y + S.cy);
    Inc(Y, S.cy);
  end;
  if FTip.Subtitle <> '' then
  begin
    S := PPGMeasureTextNoCanvas(FTip.Subtitle, Font, TextW, True);
    FSubtitleR := Rect(0, Y, S.cx, Y + S.cy);
    Inc(Y, S.cy);
  end;
  if FTip.Text <> '' then
  begin
    if Y > Pad then
      Inc(Y, PPGScale(6, APPI));
    FLayout.Layout(FTip.Text, Font, nil, TextW, True);
    FTextR := Rect(0, Y, FLayout.Size.cx, Y + FLayout.Size.cy);
    Inc(Y, FLayout.Size.cy);
  end;
  if FTip.Icon <> tiNone then
    Y := Max(Y, Pad + PPGScale(IconSize, APPI));
  if PartVisible(tppCross) then
    Y := Max(Y, PPGScale(CrossSize, APPI));
  BtnCount := 0;
  if PartVisible(tppAction) then
    Inc(BtnCount);
  if PartVisible(tppClose) then
    Inc(BtnCount);
  if BtnCount > 0 then
  begin
    Btn := PPGScale(ButtonH, APPI);
    Inc(Y, PPGScale(12, APPI) + Btn);
  end;
  H := Y + Pad;
  Result.cx := W;
  Result.cy := H;
end;

procedure TPPGTeachingTipWindow.Arrange(const Placement: TPPGTipPlacement; HasTail: Boolean);
var
  W, H, X0, Y0, TX, Btn, BW, Gap, I: Integer;
  PPI: Integer;
  P: TPPGTipPart;
  Visible: TArray<TPPGTipPart>;

  function Mirror(const R: TRect): TRect;
  begin
    // RTL: Teile innerhalb der Flaeche spiegeln
    Result := R;
    if FTip.Target <> nil then
      if not FTip.Target.UseRightToLeftAlignment then
        Exit;
    if (FTip.Target = nil) and (Application.BiDiMode <> bdRightToLeft) then
      Exit;
    Result.Left := FBody.Left + FBody.Right - R.Right;
    Result.Right := FBody.Left + FBody.Right - R.Left;
  end;

begin
  PPI := ScalePPI;
  FSide := Placement.Side;
  FHasTail := HasTail;
  FTailPos := Placement.TailPos;
  W := Placement.Bounds.Right - Placement.Bounds.Left;
  H := Placement.Bounds.Bottom - Placement.Bounds.Top;
  FBody := Rect(0, 0, W, H);
  if HasTail then
    case FSide of
      ppsBelow: FBody.Top := TailLen;
      ppsAbove: FBody.Bottom := H - TailLen;
      ppsRight: FBody.Left := TailLen;
      ppsLeft: FBody.Right := W - TailLen;
    end;
  X0 := FBody.Left + Pad;
  Y0 := FBody.Top;
  TX := X0;
  FIconR := Rect(0, 0, 0, 0);
  if FTip.Icon <> tiNone then
  begin
    FIconR := Rect(X0, Y0 + Pad, X0 + PPGScale(IconSize, PPI), Y0 + Pad + PPGScale(IconSize, PPI));
    TX := FIconR.Right + PPGScale(8, PPI);
  end;
  OffsetRect(FTitleR, TX - FTitleR.Left, Y0);
  OffsetRect(FSubtitleR, TX - FSubtitleR.Left, Y0);
  OffsetRect(FTextR, TX - FTextR.Left, Y0);
  for P := Low(TPPGTipPart) to High(TPPGTipPart) do
    FParts[P] := Rect(0, 0, 0, 0);
  if PartVisible(tppCross) then
    FParts[tppCross] := Rect(FBody.Right - PPGScale(CrossSize, PPI) - PPGScale(4, PPI),
      FBody.Top + PPGScale(4, PPI), FBody.Right - PPGScale(4, PPI),
      FBody.Top + PPGScale(4, PPI) + PPGScale(CrossSize, PPI));
  // Buttons unten, gleich breit; zwei teilen sich die Breite (wie WinUI)
  SetLength(Visible, 0);
  for P := tppAction to tppClose do
    if PartVisible(P) then
    begin
      SetLength(Visible, Length(Visible) + 1);
      Visible[High(Visible)] := P;
    end;
  if Length(Visible) > 0 then
  begin
    Btn := PPGScale(ButtonH, PPI);
    Gap := PPGScale(8, PPI);
    BW := (FBody.Right - FBody.Left - 2 * Pad - (Length(Visible) - 1) * Gap) div Length(Visible);
    for I := 0 to High(Visible) do
      FParts[Visible[I]] := Rect(X0 + I * (BW + Gap), FBody.Bottom - Pad - Btn,
        X0 + I * (BW + Gap) + BW, FBody.Bottom - Pad);
  end;
  FIconR := Mirror(FIconR);
  FTitleR := Mirror(FTitleR);
  FSubtitleR := Mirror(FSubtitleR);
  FTextR := Mirror(FTextR);
  for P := tppAction to tppCross do
    if not IsRectEmpty(FParts[P]) then
      FParts[P] := Mirror(FParts[P]);
end;

function TPPGTeachingTipWindow.PartRect(Part: TPPGTipPart): TRect;
begin
  Result := FParts[Part];
end;

function TPPGTeachingTipWindow.PartAt(X, Y: Integer): TPPGTipPart;
var
  P: TPPGTipPart;
begin
  Result := tppNone;
  for P := tppAction to tppCross do
    if PartVisible(P) and PtInRect(FParts[P], Point(X, Y)) then
      Exit(P);
end;

procedure TPPGTeachingTipWindow.TailPoints(out P: array of TPoint);
var
  B: TRect;
  H: Integer;
begin
  B := FBody;
  H := TailHalf;
  case FSide of
    ppsBelow: // Blase unter dem Ziel: Pfeil oben, zeigt nach oben
      begin
        P[0] := Point(FTailPos - H, B.Top);
        P[1] := Point(FTailPos, 0);
        P[2] := Point(FTailPos + H, B.Top);
      end;
    ppsAbove:
      begin
        P[0] := Point(FTailPos - H, B.Bottom - 1);
        P[1] := Point(FTailPos, Height - 1);
        P[2] := Point(FTailPos + H, B.Bottom - 1);
      end;
    ppsRight:
      begin
        P[0] := Point(B.Left, FTailPos - H);
        P[1] := Point(0, FTailPos);
        P[2] := Point(B.Left, FTailPos + H);
      end;
  else
    begin
      P[0] := Point(B.Right - 1, FTailPos - H);
      P[1] := Point(Width - 1, FTailPos);
      P[2] := Point(B.Right - 1, FTailPos + H);
    end;
  end;
end;

procedure TPPGTeachingTipWindow.ApplyRegion;
var
  Rgn, Tri: HRGN;
  P: array[0..2] of TPoint;
  R: Integer;
begin
  if not HandleAllocated then
    Exit;
  R := PopupRounding;
  Rgn := CreateRoundRectRgn(FBody.Left, FBody.Top, FBody.Right + 1, FBody.Bottom + 1, 2 * R, 2 * R);
  if Rgn = 0 then
    Exit;
  if FHasTail then
  begin
    TailPoints(P);
    // Spitze einen Pixel weiter, damit die Linie in der Region liegt
    case FSide of
      ppsAbove: Inc(P[1].Y);
      ppsLeft: Inc(P[1].X);
    end;
    Tri := CreatePolygonRgn(P, 3, WINDING);
    if Tri <> 0 then
    begin
      CombineRgn(Rgn, Rgn, Tri, RGN_OR);
      DeleteObject(Tri);
    end;
  end;
  if SetWindowRgn(Handle, Rgn, True) = 0 then
    DeleteObject(Rgn);
end;

procedure TPPGTeachingTipWindow.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  T: TPPGTokens;
  L, H, S: TPPGSurfaceStyle;
  HR: IPPGHintRenderer;
  P: array[0..2] of TPoint;
  PPI: Integer;
  Part: TPPGTipPart;
  R: TRect;
  G: TPPGIconGlyph;
  IconColor, LinkColor, Secondary: TColor;
  A: TPPGAppearance;
  HC: Boolean;
  Pts: array[0..1] of TPoint;
  Caption: string;
  NoTail: array of TPoint;
begin
  if FTip = nil then
    Exit;
  PPI := ScalePPI;
  T := Tokens;
  HC := HighContrastSupport and PPGIsHighContrast;
  GetPopupStyles(T.Layer, T.TextPrimary, L, H);
  L.Rounding := PopupRounding;
  if not Supports(Renderer, IPPGHintRenderer, HR) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName), IPPGHintRenderer, HR);
  // Ecken ausserhalb: Flaechenfarbe (Region schneidet ab)
  ACanvas.FillRoundRect(ClientR, 0, L.Color, 255);
  if FHasTail then
  begin
    TailPoints(P);
    HR.DrawTip(ACanvas, Rect(FBody.Left, FBody.Top, FBody.Right - 1, FBody.Bottom - 1), P, L, PPI);
  end
  else
    HR.DrawTip(ACanvas, Rect(FBody.Left, FBody.Top, FBody.Right - 1, FBody.Bottom - 1),
      NoTail, L, PPI);

  if HC then
  begin
    Secondary := L.TextColor;
    LinkColor := PPGColorToRGB(clHotLight);
  end
  else
  begin
    Secondary := PPGBlendColor(L.TextColor, L.Color, 0.25);
    LinkColor := T.Accent;
  end;

  // Symbol
  if FTip.Icon <> tiNone then
  begin
    case FTip.Icon of
      tiSuccess: begin G := igSuccess; IconColor := T.Success; end;
      tiWarning: begin G := igWarning; IconColor := T.Warning; end;
      tiError: begin G := igError; IconColor := T.Danger; end;
    else
      begin G := igInfo; IconColor := T.Accent; end;
    end;
    if HC then
      IconColor := L.TextColor;
    if not PPGDrawIcon(ACanvas, FIconR, G, IconColor, PPGScale(IconSize - 4, PPI)) then
    begin
      ACanvas.FillEllipse(FIconR, IconColor, 255);
      case FTip.Icon of
        tiSuccess: Caption := '+';
        tiWarning: Caption := '!';
        tiError: Caption := 'x';
      else
        Caption := 'i';
      end;
      ACanvas.DrawText(FIconR, Caption, Font, L.Color,
        DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
    end;
  end;
  // Texte
  if FTip.Title <> '' then
    ACanvas.DrawText(FTitleR, FTip.Title, FTitleFont, L.TextColor, DT_WORDBREAK or DT_NOPREFIX);
  if FTip.Subtitle <> '' then
    ACanvas.DrawText(FSubtitleR, FTip.Subtitle, Font, Secondary, DT_WORDBREAK or DT_NOPREFIX);
  if FTip.Text <> '' then
    FLayout.Draw(ACanvas, FTextR.Left, FTextR.Top, L.TextColor, LinkColor);

  // Buttons
  A := EffectiveAppearance;
  for Part := tppAction to tppClose do
  begin
    if not PartVisible(Part) then
      Continue;
    R := FParts[Part];
    if (FDown = Part) and (FHot = Part) then
      S := A.Resolve(vsDown, PPI, False)
    else if FHot = Part then
      S := A.Resolve(vsHot, PPI, False)
    else
      S := A.Resolve(vsNormal, PPI, False);
    S.GlowAlpha := 0;
    if S.Rounding > PPGScale(4, PPI) then
      S.Rounding := PPGScale(4, PPI);
    if (Part = tppAction) and not HC and not UseVclStyle then
    begin
      // Aktion = Akzent-Button
      if (FDown = Part) and (FHot = Part) then
        S.Color := T.AccentPressed
      else if FHot = Part then
        S.Color := T.AccentHover
      else
        S.Color := T.Accent;
      S.ColorTo := S.Color;
      S.ColorMirror := S.Color;
      S.ColorMirrorTo := S.Color;
      S.BorderColor := S.Color;
      S.TextColor := T.OnAccent;
    end;
    Renderer.DrawSurface(ACanvas, R, S);
    if Part = tppAction then
      Caption := FTip.ActionButtonText
    else
      Caption := FTip.CloseButtonText;
    ACanvas.DrawText(R, StripAmp(Caption), Font, S.TextColor,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
    if FKeyboardUsed and (FFocus = Part) then
    begin
      S.Focused := True;
      S.BorderColor := PPGColorToRGB(A.FocusColor);
      Renderer.DrawFocus(ACanvas, R, S);
    end;
  end;
  // Kreuz
  if PartVisible(tppCross) then
  begin
    R := FParts[tppCross];
    InflateRect(R, -PPGScale(6, PPI), -PPGScale(6, PPI));
    if FHot = tppCross then
      ACanvas.FillRoundRect(R, PPGScale(4, PPI), L.TextColor, 24);
    if not PPGDrawIcon(ACanvas, R, igClose, L.TextColor, PPGScale(10, PPI)) then
    begin
      Pts[0] := Point(R.Left + (R.Right - R.Left) div 3, R.Top + (R.Bottom - R.Top) div 3);
      Pts[1] := Point(R.Right - (R.Right - R.Left) div 3, R.Bottom - (R.Bottom - R.Top) div 3);
      ACanvas.DrawPolyline(Pts, PPGScale(1, PPI) + 1, L.TextColor, 255);
      Pts[0] := Point(R.Right - (R.Right - R.Left) div 3, R.Top + (R.Bottom - R.Top) div 3);
      Pts[1] := Point(R.Left + (R.Right - R.Left) div 3, R.Bottom - (R.Bottom - R.Top) div 3);
      ACanvas.DrawPolyline(Pts, PPGScale(1, PPI) + 1, L.TextColor, 255);
    end;
    if FKeyboardUsed and (FFocus = tppCross) then
      ACanvas.FrameRoundRect(R, PPGScale(4, PPI), PPGScale(2, PPI), A.FocusColor, 255);
  end;
end;

procedure TPPGTeachingTipWindow.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P: TPPGTipPart;
begin
  inherited MouseMove(Shift, X, Y);
  P := PartAt(X, Y);
  if (P = tppNone) and (FTip <> nil) and PtInRect(FTextR, Point(X, Y)) and
    (FLayout.LinkAt(X - FTextR.Left, Y - FTextR.Top) <> '') then
    Cursor := crHandPoint
  else
    Cursor := crDefault;
  if P <> FHot then
  begin
    FHot := P;
    Invalidate;
  end;
end;

procedure TPPGTeachingTipWindow.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHot <> tppNone then
  begin
    FHot := tppNone;
    Invalidate;
  end;
end;

procedure TPPGTeachingTipWindow.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = mbLeft then
  begin
    FDown := PartAt(X, Y);
    FKeyboardUsed := False;
    Invalidate;
  end;
end;

procedure TPPGTeachingTipWindow.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P: TPPGTipPart;
  Link: string;
  Tip: TPPGTeachingTip;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button <> mbLeft then
    Exit;
  P := PartAt(X, Y);
  Link := '';
  if (P = tppNone) and (FDown = tppNone) and PtInRect(FTextR, Point(X, Y)) then
    Link := FLayout.LinkAt(X - FTextR.Left, Y - FTextR.Top);
  if P <> FDown then
    P := tppNone;
  FDown := tppNone;
  Invalidate;
  Tip := FTip;
  if Tip = nil then
    Exit;
  // Das Ereignis darf den TeachingTip (und damit dieses Fenster) freigeben
  Inc(FInHandler);
  try
    if P <> tppNone then
      Tip.ActivatePart(P)
    else if Link <> '' then
      Tip.DoLinkClick(Link);
  finally
    Dec(FInHandler);
  end;
  if FReleasePending and (FInHandler = 0) then
    PostMessage(Handle, CM_RELEASE, 0, 0);
end;

procedure TPPGTeachingTipWindow.CMRelease(var Message: TMessage);
begin
  Free;
end;

procedure TPPGTeachingTipWindow.WMTipActivate(var Message: TMessage);
var
  Tip: TPPGTeachingTip;
begin
  Tip := FTip;
  if (Tip = nil) or not Tip.IsOpen then
    Exit;
  Inc(FInHandler);
  try
    Tip.ActivatePart(TPPGTipPart(Message.WParam));
  finally
    Dec(FInHandler);
  end;
  if FReleasePending and (FInHandler = 0) then
    PostMessage(Handle, CM_RELEASE, 0, 0);
end;

procedure TPPGTeachingTipWindow.WMTipReposition(var Message: TMessage);
begin
  if (FTip <> nil) and FTip.IsOpen then
    FTip.UpdatePosition;
end;

function TPPGTeachingTipWindow.AccName: string;
begin
  Result := '';
  if FTip <> nil then
  begin
    Result := FTip.Title;
    if Result = '' then
      Result := PPGStripMarkup(FTip.Text);
  end;
end;

function TPPGTeachingTipWindow.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_DIALOG;
end;

function TPPGTeachingTipWindow.AccDescription: string;
begin
  Result := '';
  if FTip = nil then
    Exit;
  Result := FTip.Subtitle;
  if FTip.Title <> '' then
  begin
    if Result <> '' then
      Result := Result + ' ';
    Result := Result + PPGStripMarkup(FTip.Text);
  end;
end;

function TPPGTeachingTipWindow.AccChildCount: Integer;
begin
  Result := Length(TabParts);
end;

function TPPGTeachingTipWindow.AccChildName(Id: Integer): string;
var
  L: TArray<TPPGTipPart>;
begin
  Result := '';
  L := TabParts;
  if (Id < 1) or (Id > Length(L)) or (FTip = nil) then
    Exit;
  case L[Id - 1] of
    tppAction: Result := StripAmp(FTip.ActionButtonText);
    tppClose: Result := StripAmp(FTip.CloseButtonText);
    tppCross: Result := PPGStr(@SPPGAccClose);
  end;
end;

function TPPGTeachingTipWindow.AccChildRole(Id: Integer): Integer;
begin
  Result := ROLE_SYSTEM_PUSHBUTTON;
end;

function TPPGTeachingTipWindow.AccChildState(Id: Integer): Integer;
var
  L: TArray<TPPGTipPart>;
begin
  Result := STATE_SYSTEM_FOCUSABLE;
  L := TabParts;
  if (Id >= 1) and (Id <= Length(L)) then
  begin
    if L[Id - 1] = FFocus then
      Result := Result or STATE_SYSTEM_FOCUSED;
    if L[Id - 1] = FHot then
      Result := Result or STATE_SYSTEM_HOTTRACKED;
  end;
end;

function TPPGTeachingTipWindow.AccChildRect(Id: Integer): TRect;
var
  L: TArray<TPPGTipPart>;
begin
  L := TabParts;
  if (Id < 1) or (Id > Length(L)) then
    Result := Rect(0, 0, 0, 0)
  else
    Result := FParts[L[Id - 1]];
end;

function TPPGTeachingTipWindow.AccChildAt(X, Y: Integer): Integer;
var
  L: TArray<TPPGTipPart>;
  P: TPPGTipPart;
  I: Integer;
begin
  Result := 0;
  P := PartAt(X, Y);
  L := TabParts;
  for I := 0 to High(L) do
    if L[I] = P then
      Exit(I + 1);
end;

function TPPGTeachingTipWindow.AccChildDefaultAction(Id: Integer): string;
begin
  Result := PPGStr(@SPPGAccPress);
end;

procedure TPPGTeachingTipWindow.AccChildDoDefault(Id: Integer);
var
  L: TArray<TPPGTipPart>;
begin
  // Nie im COM-Aufruf ausloesen
  L := TabParts;
  if (Id >= 1) and (Id <= Length(L)) and HandleAllocated then
    PostMessage(Handle, WM_TIPACTIVATE, Ord(L[Id - 1]), 0);
end;

function TPPGTeachingTipWindow.AccFocusedChild: Integer;
var
  L: TArray<TPPGTipPart>;
  I: Integer;
begin
  Result := 0;
  L := TabParts;
  for I := 0 to High(L) do
    if L[I] = FFocus then
      Exit(I + 1);
end;

function TPPGTeachingTipWindow.AccSelectedChild: Integer;
begin
  Result := 0;
end;

{ TPPGTeachingTip }

constructor TPPGTeachingTip.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FShowCloseButton := True;
  FPlacement := tpAuto;
  FMaxWidth := 320;
end;

destructor TPPGTeachingTip.Destroy;
begin
  HideWindow;
  Unwatch;
  if FWindow <> nil then
  begin
    FWindow.FTip := nil;
    if FWindow.FInHandler > 0 then
      // Wir werden aus einem Ereignis des Fensters heraus freigegeben: das
      // Fenster gibt sich selbst frei, sobald sein Handler zurueck ist
      FWindow.FReleasePending := True
    else
      FreeAndNil(FWindow);
    FWindow := nil;
  end;
  SetTarget(nil);
  SetStyleManager(nil);
  inherited Destroy;
end;

procedure TPPGTeachingTip.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation <> opRemove then
    Exit;
  if AComponent = FTarget then
  begin
    // Ziel verschwindet: still ausblenden (keine Anwenderaktion)
    HideWindow;
    Unwatch;
    FTarget := nil;
  end
  else if AComponent = FWatchedForm then
  begin
    HideWindow;
    Unwatch;
  end
  else if AComponent = FStyleManager then
    FStyleManager := nil
  else if AComponent = FWindow then
    FWindow := nil;
end;

procedure TPPGTeachingTip.SetTarget(const Value: TControl);
var
  WasOpen: Boolean;
begin
  if FTarget = Value then
    Exit;
  WasOpen := FOpen;
  if WasOpen then
    Unwatch;
  if FTarget <> nil then
    FTarget.RemoveFreeNotification(Self);
  FTarget := Value;
  if FTarget <> nil then
    FTarget.FreeNotification(Self);
  if WasOpen then
  begin
    Watch;
    UpdatePosition;
  end;
end;

procedure TPPGTeachingTip.SetStyleManager(const Value: TPPGStyleManager);
begin
  if FStyleManager = Value then
    Exit;
  if FStyleManager <> nil then
    FStyleManager.RemoveFreeNotification(Self);
  FStyleManager := Value;
  if FStyleManager <> nil then
    FStyleManager.FreeNotification(Self);
  ContentChanged;
end;

procedure TPPGTeachingTip.SetMaxWidth(const Value: Integer);
begin
  FMaxWidth := PPGCheckRange(Self, 'MaxWidth', Value, 120, 2000);
  ContentChanged;
end;

procedure TPPGTeachingTip.SetText(const Index: Integer; const Value: string);
begin
  case Index of
    0: FTitle := Value;
    1: FSubtitle := Value;
    2: FText := Value;
    3: FActionButtonText := Value;
    4: FCloseButtonText := Value;
  end;
  ContentChanged;
end;

procedure TPPGTeachingTip.SetIcon(const Value: TPPGTipIcon);
begin
  FIcon := Value;
  ContentChanged;
end;

procedure TPPGTeachingTip.SetShowCloseButton(const Value: Boolean);
begin
  FShowCloseButton := Value;
  ContentChanged;
end;

procedure TPPGTeachingTip.SetPlacement(const Value: TPPGTipPlacementMode);
begin
  FPlacement := Value;
  ContentChanged;
end;

procedure TPPGTeachingTip.ContentChanged;
begin
  if FOpen then
    UpdatePosition;
end;

function TPPGTeachingTip.EffectivePreset: string;
begin
  Result := PPGHintPreset(FStyleManager, FPreset);
end;

function TPPGTeachingTip.IsOpen: Boolean;
begin
  Result := FOpen;
end;

function TPPGTeachingTip.AnchorRect: TRect;
var
  F: TCustomForm;
  P: TPoint;
begin
  if FTarget <> nil then
  begin
    if FTarget.Parent <> nil then
    begin
      P := FTarget.Parent.ClientToScreen(FTarget.BoundsRect.TopLeft);
      Result := Rect(P.X, P.Y, P.X + FTarget.Width, P.Y + FTarget.Height);
    end
    else if (FTarget is TWinControl) and TWinControl(FTarget).HandleAllocated then
      GetWindowRect(TWinControl(FTarget).Handle, Result)
    else
      Result := FTarget.BoundsRect;
    Exit;
  end;
  F := nil;
  if Owner is TCustomForm then
    F := TCustomForm(Owner)
  else if Screen.ActiveCustomForm <> nil then
    F := Screen.ActiveCustomForm;
  if (F <> nil) and F.HandleAllocated then
  begin
    P := F.ClientToScreen(Point(0, 0));
    Result := Rect(P.X, P.Y, P.X + F.ClientWidth, P.Y + F.ClientHeight);
  end
  else
    Result := Screen.WorkAreaRect;
end;

procedure TPPGTeachingTip.Show;
begin
  if csDesigning in ComponentState then
    Exit;
  PPGCheckMainThread('TPPGTeachingTip.Show');
  if FWindow = nil then
  begin
    FWindow := TPPGTeachingTipWindow.Create(nil);
    FWindow.FTip := Self;
    FWindow.FreeNotification(Self);
  end;
  FWindow.Preset := EffectivePreset;
  FWindow.StyleManager := FStyleManager;
  FWindow.FFocus := tppNone;
  FWindow.FKeyboardUsed := False;
  if not FLightDismiss then
    if Length(FWindow.TabParts) > 0 then
      FWindow.FFocus := FWindow.TabParts[0];
  FOpen := True;
  Watch;
  UpdatePosition;
  if FWindow.HandleAllocated then
    FWindow.NotifyAccessibility(EVENT_SYSTEM_ALERT);
end;

procedure TPPGTeachingTip.ShowFor(ATarget: TControl);
begin
  Target := ATarget;
  Show;
end;

procedure TPPGTeachingTip.HideWindow;
begin
  if not FOpen then
    Exit;
  FOpen := False;
  if FHooked then
  begin
    PPGRemoveMessageHook(AppMessage);
    PPGRemoveDeactivateHook(AppDeactivate);
    FHooked := False;
  end;
  if (FWindow <> nil) and FWindow.IsOpen then
    FWindow.ClosePopup;
end;

procedure TPPGTeachingTip.Hide;
begin
  HideWindow;
  Unwatch;
end;

procedure TPPGTeachingTip.UpdatePosition;
var
  A, WA: TRect;
  S: TSize;
  Pl: TPPGTipPlacement;
  Pref: TPPGPopupSide;
  ShowIt: Boolean;
  OwnerWnd: HWND;
  PPI, Gap: Integer;
begin
  if not FOpen or (FWindow = nil) then
    Exit;
  // Ziel nicht sichtbar oder Formular minimiert: nur ausblenden
  ShowIt := True;
  if (FTarget <> nil) and not FTarget.Visible then
    ShowIt := False;
  if (FTarget is TWinControl) and not TWinControl(FTarget).Showing then
    ShowIt := False;
  if (FTarget <> nil) and not (FTarget is TWinControl) and
    ((FTarget.Parent = nil) or not FTarget.Parent.Showing) then
    ShowIt := False;
  if (FWatchedForm <> nil) and FWatchedForm.HandleAllocated and
    (IsIconic(FWatchedForm.Handle) or not IsWindowVisible(FWatchedForm.Handle)) then
    ShowIt := False;
  if not ShowIt then
  begin
    if FWindow.HandleAllocated then
      ShowWindow(FWindow.Handle, SW_HIDE);
    Exit;
  end;
  A := AnchorRect;
  PPI := MonitorPPI(A);
  FPPI := PPI;
  FWindow.Preset := EffectivePreset;
  S := FWindow.MeasureBody(PPI);
  WA := FWindow.MonitorWorkArea(A);
  if FTarget <> nil then
  begin
    Gap := PPGScale(4, PPI);
    InflateRect(A, Gap, Gap);
    case FPlacement of
      tpTop: Pref := ppsAbove;
      tpLeft: Pref := ppsLeft;
      tpRight: Pref := ppsRight;
    else
      Pref := ppsBelow;
    end;
    Pl := PPGPlaceTip(A, S.cx, S.cy, FWindow.TailLen,
      FWindow.PopupRounding + FWindow.TailHalf, Pref, FPlacement = tpAuto, WA);
    FWindow.Arrange(Pl, True);
  end
  else
  begin
    // Ohne Ziel: unten rechts im Formular, ohne Pfeil (WinUI)
    Gap := PPGScale(12, PPI);
    Pl.Side := ppsAbove;
    Pl.TailPos := 0;
    Pl.Bounds := Rect(A.Right - Gap - S.cx, A.Bottom - Gap - S.cy, A.Right - Gap, A.Bottom - Gap);
    if Pl.Bounds.Left < WA.Left then
      OffsetRect(Pl.Bounds, WA.Left - Pl.Bounds.Left, 0);
    if Pl.Bounds.Top < WA.Top then
      OffsetRect(Pl.Bounds, 0, WA.Top - Pl.Bounds.Top);
    FWindow.Arrange(Pl, False);
  end;
  FWindow.HandleNeeded;
  // Besitzer = Formular des Ziels: Blase liegt immer ueber ihm
  OwnerWnd := 0;
  if FWatchedForm <> nil then
    OwnerWnd := FWatchedForm.Handle
  else if (Self.Owner is TCustomForm) and TCustomForm(Self.Owner).HandleAllocated then
    OwnerWnd := TCustomForm(Self.Owner).Handle;
  if OwnerWnd <> 0 then
    SetWindowLongPtr(FWindow.Handle, GWLP_HWNDPARENT, LONG_PTR(OwnerWnd));
  FWindow.PopupAt(Pl.Bounds, Pl.Side, 0);
  FWindow.ApplyRegion;
  FWindow.Invalidate;
  if not FHooked then
  begin
    PPGAddMessageHook(AppMessage);
    PPGAddDeactivateHook(AppDeactivate);
    FHooked := True;
  end;
end;

procedure TPPGTeachingTip.Watch;
var
  F: TCustomForm;
begin
  Unwatch;
  if FTarget <> nil then
  begin
    PPGWatchControl(FTarget, WatchEvent);
    F := GetParentForm(FTarget);
  end
  else if Owner is TCustomForm then
    F := TCustomForm(Owner)
  else
    F := nil;
  if F <> nil then
  begin
    FWatchedForm := F;
    F.FreeNotification(Self);
    if F <> FTarget then
      PPGWatchControl(F, WatchEvent);
  end;
end;

procedure TPPGTeachingTip.Unwatch;
begin
  if FTarget <> nil then
    PPGUnwatchControl(FTarget, WatchEvent);
  if FWatchedForm <> nil then
  begin
    if FWatchedForm <> FTarget then
      PPGUnwatchControl(FWatchedForm, WatchEvent);
    if FWatchedForm <> Owner then
      FWatchedForm.RemoveFreeNotification(Self);
    FWatchedForm := nil;
  end;
end;

procedure TPPGTeachingTip.WatchEvent(Control: TControl; var Message: TMessage);
begin
  if not FOpen or (FWindow = nil) or not FWindow.HandleAllocated then
    Exit;
  case Message.Msg of
    WM_WINDOWPOSCHANGED, WM_SIZE, WM_SHOWWINDOW, CM_VISIBLECHANGED, CM_SHOWINGCHANGED:
      // Gesammelt und ausserhalb der Nachricht des Ziels neu platzieren
      PostMessage(FWindow.Handle, WM_TIPREPOSITION, 0, 0);
  end;
end;

procedure TPPGTeachingTip.AppMessage(var Msg: TMsg; var Handled: Boolean);
var
  Parts: TArray<TPPGTipPart>;
  I, Cur: Integer;
  Part: TPPGTipPart;
begin
  if not FOpen or (FWindow = nil) or not FWindow.HandleAllocated then
    Exit;
  case Msg.message of
    WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN,
    WM_NCLBUTTONDOWN, WM_NCRBUTTONDOWN, WM_NCMBUTTONDOWN:
      // Light-dismiss: Klick daneben schliesst, der Klick geht weiter
      if FLightDismiss and (Msg.hwnd <> FWindow.Handle) and
        not IsChild(FWindow.Handle, Msg.hwnd) then
        RequestClose(tcrLightDismiss);
    WM_KEYDOWN, WM_SYSKEYDOWN:
      begin
        if Msg.wParam = VK_ESCAPE then
        begin
          Handled := True;
          RequestClose(tcrEscape);
          Exit; // Self kann freigegeben sein
        end;
        if FLightDismiss or (Msg.message = WM_SYSKEYDOWN) then
          Exit;
        // Fester TeachingTip: Tastatur gehoert ihm
        Parts := FWindow.TabParts;
        case Msg.wParam of
          VK_TAB:
            if Length(Parts) > 0 then
            begin
              Handled := True;
              Cur := -1;
              for I := 0 to High(Parts) do
                if Parts[I] = FWindow.FFocus then
                  Cur := I;
              if GetKeyState(VK_SHIFT) < 0 then
                Dec(Cur)
              else
                Inc(Cur);
              if Cur < 0 then
                Cur := High(Parts);
              if Cur > High(Parts) then
                Cur := 0;
              FWindow.FFocus := Parts[Cur];
              FWindow.FKeyboardUsed := True;
              FWindow.Invalidate;
              FWindow.NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, Cur + 1);
            end;
          VK_RETURN, VK_SPACE:
            begin
              Part := FWindow.FFocus;
              if (Part = tppNone) and (Msg.wParam = VK_RETURN) and
                FWindow.PartVisible(tppAction) then
                Part := tppAction;
              if Part <> tppNone then
              begin
                Handled := True;
                ActivatePart(Part);
                Exit;
              end;
            end;
        end;
      end;
    WM_CHAR, WM_KEYUP:
      // Zugehoerige Zeichen der verbrauchten Tasten nicht ans Formular
      if not FLightDismiss and
        ((Msg.wParam = VK_TAB) or (Msg.wParam = VK_RETURN) or (Msg.wParam = VK_SPACE) or
         (Msg.wParam = VK_ESCAPE) or (Msg.wParam = 9) or (Msg.wParam = 13) or
         (Msg.wParam = 32) or (Msg.wParam = 27)) and (Length(FWindow.TabParts) > 0) then
        Handled := True;
  end;
end;

procedure TPPGTeachingTip.AppDeactivate(Sender: TObject);
begin
  if FOpen and FLightDismiss then
    RequestClose(tcrLightDismiss);
end;

procedure TPPGTeachingTip.ActivatePart(Part: TPPGTipPart);
begin
  if not FOpen then
    Exit;
  case Part of
    tppAction:
      if Assigned(FOnActionClick) then
        FOnActionClick(Self);
    tppClose, tppCross:
      RequestClose(tcrCloseButton);
  end;
end;

procedure TPPGTeachingTip.DoLinkClick(const Link: string);
begin
  if Assigned(FOnLinkClick) then
    FOnLinkClick(Self, Link);
end;

procedure TPPGTeachingTip.RequestClose(Reason: TPPGTipCloseReason);
var
  Allow: Boolean;
begin
  if not FOpen then
    Exit;
  Allow := True;
  if Assigned(FOnClosing) then
    FOnClosing(Self, Reason, Allow);
  if not Allow then
    Exit;
  Hide;
  if Assigned(FOnClose) then
    FOnClose(Self, Reason);
end;

end.
