unit PPG.StatusBar;

{ TPPGStatusBar - Statusleiste (Phase 7c).

  - Panels wie TStatusBar (Text, Width, Alignment, Bevel, Style); Bevel <>
    pbNone zeichnet eine Trennlinie. Zusaetzlich Kind: Text (optional mit
    Markup, AllowMarkup), Fortschrittsbalken (Progress 0..100) oder Plakette
    (BadgeCount); Bild aus Images (ImageIndex). Das letzte Panel fuellt den
    Rest, wenn seine Breite nicht reicht.
  - SimplePanel/SimpleText, AutoHint (Hinweise der Anwendung im ersten Panel
    bzw. SimpleText, ueber THintAction wie TStatusBar).
  - SizeGrip: Griff unten rechts (RTL links); Ziehen veraendert die Groesse
    des Formulars, nur wenn es sizable und nicht maximiert ist.
  - psOwnerDraw: OnDrawPanel mit Canvas (TCanvas ueber dem Zeichenpuffer).
  - DFM-nah zu TStatusBar (Panels, SimplePanel, SimpleText, SizeGrip,
    AutoHint, UseSystemFont, OnDrawPanel).
  - Screenreader: Statusleiste; Kinder sind die Panels (Text/Fortschritt). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, {$IFDEF PPG_HAS_IMAGENAME}System.UITypes,{$ENDIF} System.Types, System.SysUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.ComCtrls, Vcl.Forms, Vcl.ActnList, Vcl.StdActns,
  PPG.Types, PPG.Render.Intf, PPG.Markup, PPG.Accessibility, PPG.Controls.Base,
  PPG.ElementStyle;

type
  TPPGStatusBar = class;

  TPPGStatusPanelKind = (spkText, spkProgress, spkBadge);

  TPPGStatusPanel = class(TCollectionItem)
  private
    FText: string;
    FWidth: Integer;
    FAlignment: TAlignment;
    FBevel: TStatusPanelBevel;
    FStyle: TStatusPanelStyle;
    FKind: TPPGStatusPanelKind;
    FProgress: Integer;
    FBadgeCount: Integer;
    FImageIndex: TPPGImageIndex;
    FHint: string;
    FColor: TColor;
    FTextColor: TColor;
    FFontStyle: TFontStyles;
    {$IFDEF PPG_HAS_IMAGENAME}
    FImageName: TImageName;
    {$ENDIF}
    procedure SetText(const Value: string);
    procedure SetColor(const Value: TColor);
    procedure SetTextColor(const Value: TColor);
    procedure SetFontStyle(const Value: TFontStyles);
    procedure SetWidth(const Value: Integer);
    procedure SetAlignment(const Value: TAlignment);
    procedure SetBevel(const Value: TStatusPanelBevel);
    procedure SetStyle(const Value: TStatusPanelStyle);
    procedure SetKind(const Value: TPPGStatusPanelKind);
    procedure SetProgress(const Value: Integer);
    procedure SetBadgeCount(const Value: Integer);
    procedure SetImageIndex(const Value: TPPGImageIndex);
    {$IFDEF PPG_HAS_IMAGENAME}
    procedure SetImageName(const Value: TImageName);
    {$ENDIF}
  protected
    function GetDisplayName: string; override;
  public
    {$IFDEF PPG_HAS_IMAGENAME}
    /// Bildindex aus ImageName neu bestimmen (ruft der Besitzer, wenn sich
    /// seine Images aendern).
    procedure ResolveImageName;
    {$ENDIF}
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
  published
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property Bevel: TStatusPanelBevel read FBevel write SetBevel default pbLowered;
    property Style: TStatusPanelStyle read FStyle write SetStyle default psText;
    property Text: string read FText write SetText;
    property Width: Integer read FWidth write SetWidth default 50;
    property Kind: TPPGStatusPanelKind read FKind write SetKind default spkText;
    property Progress: Integer read FProgress write SetProgress default 0;
    property BadgeCount: Integer read FBadgeCount write SetBadgeCount default 0;
    property ImageIndex: TPPGImageIndex read FImageIndex write SetImageIndex default -1;
    {$IFDEF PPG_HAS_IMAGENAME}
    /// Bild per Namen (TVirtualImageList, ab 10.4); robust gegen Umsortieren.
    property ImageName: TImageName read FImageName write SetImageName;
    {$ENDIF}
    property Hint: string read FHint write FHint;
    /// Flaeche, Text und zusaetzliche Schriftstile des Felds (clDefault = Leiste).
    property Color: TColor read FColor write SetColor default clDefault;
    property TextColor: TColor read FTextColor write SetTextColor default clDefault;
    property FontStyle: TFontStyles read FFontStyle write SetFontStyle default [];
  end;

  TPPGStatusPanels = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGStatusPanel;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPPGStatusBar);
    function Add: TPPGStatusPanel;
    property Items[Index: Integer]: TPPGStatusPanel read GetItem; default;
  end;

  TPPGDrawPanelEvent = procedure(StatusBar: TPPGStatusBar; Panel: TPPGStatusPanel;
    const Rect: TRect) of object;

  TPPGStatusBar = class(TPPGCustomControl, IPPGAccessibleChildren)
  private
    FPanels: TPPGStatusPanels;
    FBarStyle: TPPGElementStyle;
    FFonts: TPPGFontCache;
    FSimplePanel: Boolean;
    FSimpleText: string;
    FSizeGrip: Boolean;
    FAutoHint: Boolean;
    FUseSystemFont: Boolean;
    FSyncingFont: Boolean;
    FAllowMarkup: Boolean;
    FMarkup: TPPGMarkupLayout;
    FPanelCanvas: TCanvas;
    FInOwnerDraw: Boolean;
    FOnDrawPanel: TPPGDrawPanelEvent;
    FOnHint: TNotifyEvent;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure SetBarStyle(const Value: TPPGElementStyle);
    procedure BarStyleChanged(Sender: TObject);
    procedure SetPanels(const Value: TPPGStatusPanels);
    procedure SetSimplePanel(const Value: Boolean);
    procedure SetSimpleText(const Value: string);
    procedure SetSizeGrip(const Value: Boolean);
    procedure SetUseSystemFont(const Value: Boolean);
    procedure SetAllowMarkup(const Value: Boolean);
    function GetCanvas: TCanvas;
    function ParentForm: TCustomForm;
    function IsFontStored: Boolean;
    procedure SyncSystemFont;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMNCLButtonDown(var Message: TWMNCLButtonDown); message WM_NCLBUTTONDOWN;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMSysFontChanged(var Message: TMessage); message CM_SYSFONTCHANGED;
    procedure CMParentFontChanged(var Message: TCMParentFontChanged); message CM_PARENTFONTCHANGED;
  protected
    /// Bildnamen der Eintraege neu aufloesen (ImageName).
    procedure ImagesChanged; override;
    procedure Loaded; override;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    function CalcAutoSize(out AWidth, AHeight: Integer): Boolean; override;
    function AutoSizeWidth: Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure PanelsChanged; virtual;
    procedure DoDrawPanel(const ACanvas: IPPGCanvas; Panel: TPPGStatusPanel; const R: TRect); virtual;
    function AccRole: Integer; override;
    function AccName: string; override;
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
    function ExecuteAction(Action: TBasicAction): Boolean; override;
    /// Rechteck eines Panels (Client-Koordinaten).
    function PanelRect(Index: Integer): TRect;
    function PanelAt(X, Y: Integer): Integer;
    function SizeGripRect: TRect;
    /// True, wenn der Griff gerade wirkt (Formular sizable, nicht maximiert, Leiste unten).
    function SizeGripActive: Boolean;
    /// Nur waehrend OnDrawPanel gueltig.
    property Canvas: TCanvas read GetCanvas;
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property HighContrastSupport;
    property Images;
    property Panels: TPPGStatusPanels read FPanels write SetPanels;
    property SimplePanel: Boolean read FSimplePanel write SetSimplePanel default False;
    property SimpleText: string read FSimpleText write SetSimpleText;
    property SizeGrip: Boolean read FSizeGrip write SetSizeGrip default True;
    property AutoHint: Boolean read FAutoHint write FAutoHint default False;
    property UseSystemFont: Boolean read FUseSystemFont write SetUseSystemFont default True;
    /// Leiste: Flaeche, Text, Trennlinien (BorderColor) und Schrift (clDefault = Preset).
    property Style: TPPGElementStyle read FBarStyle write SetBarStyle;
    property AllowMarkup: Boolean read FAllowMarkup write SetAllowMarkup default False;
    property Align default alBottom;
    property Anchors;
    property AutoSize default True;
    property BiDiMode;
    property Color;
    property Constraints;
    property Enabled;
    property Font stored IsFontStored;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont default False;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
    property Touch;
    property OnGesture;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDrawPanel: TPPGDrawPanelEvent read FOnDrawPanel write FOnDrawPanel;
    property OnHint: TNotifyEvent read FOnHint write FOnHint;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseActivate;
    property StyleElements;
    property DragMode;
    property DragCursor;
    property OnDragDrop;
    property OnDragOver;
    property OnStartDrag;
    property OnEndDrag;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

implementation

uses
  Vcl.ImgList,
  System.Math, Winapi.oleacc,
  PPG.Consts, PPG.Appearance, PPG.DpiUtils, PPG.Tokens, PPG.ItemPainter, PPG.Render.Gdi;

const
  PanelPad = 8;
  GripSize = 16;

function ContrastOn(Fill: TColor): TColor;
begin
  if PPGRelativeLuminance(Fill) < 0.4 then
    Result := clWhite
  else
    Result := clBlack;
end;

{ TPPGStatusPanel }

{$IFDEF PPG_HAS_IMAGENAME}
procedure TPPGStatusPanel.ResolveImageName;
var
  Imgs: TCustomImageList;
begin
  Imgs := PPGImagesOf(Self);
  // Unbekannter Name: -1 (die Liste kann zur Laufzeit befuellt werden)
  if (FImageName <> '') and (Imgs <> nil) and Imgs.IsImageNameAvailable then
    ImageIndex := Imgs.GetIndexByName(FImageName);
end;

procedure TPPGStatusPanel.SetImageName(const Value: TImageName);
begin
  if FImageName = Value then
    Exit;
  FImageName := Value;
  ResolveImageName;
end;
{$ENDIF}


constructor TPPGStatusPanel.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FWidth := 50;
  FBevel := pbLowered;
  FImageIndex := -1;
  FColor := clDefault;
  FTextColor := clDefault;
end;

procedure TPPGStatusPanel.Assign(Source: TPersistent);
var
  S: TPPGStatusPanel;
begin
  if Source is TPPGStatusPanel then
  begin
    S := TPPGStatusPanel(Source);
    FText := S.FText;
    FWidth := S.FWidth;
    FAlignment := S.FAlignment;
    FBevel := S.FBevel;
    FStyle := S.FStyle;
    FKind := S.FKind;
    FProgress := S.FProgress;
    FBadgeCount := S.FBadgeCount;
    FImageIndex := S.FImageIndex;
    FHint := S.FHint;
    FColor := S.FColor;
    FTextColor := S.FTextColor;
    FFontStyle := S.FFontStyle;
    Changed(False);
  end
  else if Source is TStatusPanel then
  begin
    // Uebernahme aus einer TStatusBar
    FText := TStatusPanel(Source).Text;
    FWidth := TStatusPanel(Source).Width;
    FAlignment := TStatusPanel(Source).Alignment;
    FBevel := TStatusPanel(Source).Bevel;
    FStyle := TStatusPanel(Source).Style;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGStatusPanel.GetDisplayName: string;
begin
  if FText <> '' then
    Result := FText
  else
    Result := inherited GetDisplayName;
end;

procedure TPPGStatusPanel.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    Changed(False);
  end;
end;

procedure TPPGStatusPanel.SetWidth(const Value: Integer);
begin
  if FWidth <> Value then
  begin
    FWidth := PPGCheckRange(Self, 'Width', Value, 0, MaxInt);
    Changed(False);
  end;
end;

procedure TPPGStatusPanel.SetAlignment(const Value: TAlignment);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    Changed(False);
  end;
end;

procedure TPPGStatusPanel.SetBevel(const Value: TStatusPanelBevel);
begin
  if FBevel <> Value then
  begin
    FBevel := Value;
    Changed(False);
  end;
end;

procedure TPPGStatusPanel.SetStyle(const Value: TStatusPanelStyle);
begin
  if FStyle <> Value then
  begin
    FStyle := Value;
    Changed(False);
  end;
end;

procedure TPPGStatusPanel.SetKind(const Value: TPPGStatusPanelKind);
begin
  if FKind <> Value then
  begin
    FKind := Value;
    Changed(False);
  end;
end;

procedure TPPGStatusPanel.SetProgress(const Value: Integer);
begin
  if FProgress <> Value then
  begin
    FProgress := PPGCheckRange(Self, 'Progress', Value, 0, 100);
    Changed(False);
  end;
end;

procedure TPPGStatusPanel.SetBadgeCount(const Value: Integer);
begin
  if FBadgeCount <> Value then
  begin
    FBadgeCount := PPGCheckRange(Self, 'BadgeCount', Value, 0, MaxInt);
    Changed(False);
  end;
end;

procedure TPPGStatusPanel.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Changed(False);
  end;
end;

procedure TPPGStatusPanel.SetTextColor(const Value: TColor);
begin
  if FTextColor <> Value then
  begin
    FTextColor := Value;
    Changed(False);
  end;
end;

procedure TPPGStatusPanel.SetFontStyle(const Value: TFontStyles);
begin
  if FFontStyle <> Value then
  begin
    FFontStyle := Value;
    Changed(False);
  end;
end;

procedure TPPGStatusPanel.SetImageIndex(const Value: TPPGImageIndex);
begin
  if FImageIndex <> Value then
  begin
    FImageIndex := Value;
    Changed(False);
  end;
end;

{ TPPGStatusPanels }

constructor TPPGStatusPanels.Create(AOwner: TPPGStatusBar);
begin
  inherited Create(AOwner, TPPGStatusPanel);
end;

function TPPGStatusPanels.GetItem(Index: Integer): TPPGStatusPanel;
begin
  Result := TPPGStatusPanel(inherited Items[Index]);
end;

function TPPGStatusPanels.Add: TPPGStatusPanel;
begin
  Result := TPPGStatusPanel(inherited Add);
end;

procedure TPPGStatusPanels.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Owner is TPPGStatusBar then
    TPPGStatusBar(Owner).PanelsChanged;
end;

{ TPPGStatusBar }

procedure TPPGStatusBar.ImagesChanged;
{$IFDEF PPG_HAS_IMAGENAME}
var
  I: Integer;
{$ENDIF}
begin
  inherited ImagesChanged;
{$IFDEF PPG_HAS_IMAGENAME}
  for I := 0 to FPanels.Count - 1 do
    FPanels[I].ResolveImageName;
{$ENDIF}
end;


constructor TPPGStatusBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption];
  FPanels := TPPGStatusPanels.Create(Self);
  FMarkup := TPPGMarkupLayout.Create;
  FPanelCanvas := TCanvas.Create;
  FBarStyle := TPPGElementStyle.Create(Self);
  FBarStyle.OnChange := BarStyleChanged;
  FFonts := TPPGFontCache.Create;
  FSizeGrip := True;
  FUseSystemFont := True;
  ParentFont := False;
  TabStop := False;
  Align := alBottom;
  Width := 400;
  Height := 26;
  AutoSize := True;
  SyncSystemFont;
end;

destructor TPPGStatusBar.Destroy;
begin
  FreeAndNil(FPanelCanvas);
  FreeAndNil(FMarkup);
  FreeAndNil(FPanels);
  FreeAndNil(FFonts);
  FreeAndNil(FBarStyle);
  inherited Destroy;
end;

procedure TPPGStatusBar.SetBarStyle(const Value: TPPGElementStyle);
begin
  FBarStyle.Assign(Value);
end;

procedure TPPGStatusBar.BarStyleChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TPPGStatusBar.Loaded;
begin
  inherited Loaded;
  SyncSystemFont;
end;

procedure TPPGStatusBar.SyncSystemFont;
begin
  // Wie TStatusBar: Schrift des Systems (Statuszeilen-/Meldungsschrift)
  if FUseSystemFont and not (csLoading in ComponentState) then
  begin
    FSyncingFont := True;
    try
      Font.Assign(Screen.MessageFont);
    finally
      FSyncingFont := False;
    end;
  end;
end;

function TPPGStatusBar.IsFontStored: Boolean;
begin
  // Systemschrift wird beim Laden neu geholt, nicht gespeichert
  Result := not FUseSystemFont and not ParentFont;
end;

procedure TPPGStatusBar.SetUseSystemFont(const Value: Boolean);
begin
  if FUseSystemFont <> Value then
  begin
    FUseSystemFont := Value;
    if Value then
    begin
      ParentFont := False;
      SyncSystemFont;
    end;
  end;
end;

procedure TPPGStatusBar.CMFontChanged(var Message: TMessage);
begin
  inherited;
  // Eigene Schrift (Objektinspektor, Code, DFM) schaltet die Systemschrift ab
  if not FSyncingFont and not (csLoading in ComponentState) then
    FUseSystemFont := False;
  RequestAutoSize;
  Invalidate;
end;

procedure TPPGStatusBar.CMSysFontChanged(var Message: TMessage);
begin
  inherited;
  SyncSystemFont;
end;

procedure TPPGStatusBar.CMParentFontChanged(var Message: TCMParentFontChanged);
begin
  // Eigene Systemschrift: Schriftwechsel des Parents nicht uebernehmen
  if FUseSystemFont and not ParentFont then
    Exit;
  inherited;
end;

function TPPGStatusBar.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGStatusBar.IsDown: Boolean;
begin
  Result := False;
end;

procedure TPPGStatusBar.SetPanels(const Value: TPPGStatusPanels);
begin
  FPanels.Assign(Value);
end;

procedure TPPGStatusBar.SetSimplePanel(const Value: Boolean);
begin
  if FSimplePanel <> Value then
  begin
    FSimplePanel := Value;
    PanelsChanged;
  end;
end;

procedure TPPGStatusBar.SetSimpleText(const Value: string);
begin
  if FSimpleText <> Value then
  begin
    FSimpleText := Value;
    if FSimplePanel then
    begin
      Invalidate;
      NotifyAccessibility(EVENT_OBJECT_NAMECHANGE);
    end;
  end;
end;

procedure TPPGStatusBar.SetSizeGrip(const Value: Boolean);
begin
  if FSizeGrip <> Value then
  begin
    FSizeGrip := Value;
    Invalidate;
  end;
end;

procedure TPPGStatusBar.SetAllowMarkup(const Value: Boolean);
begin
  if FAllowMarkup <> Value then
  begin
    FAllowMarkup := Value;
    Invalidate;
  end;
end;

procedure TPPGStatusBar.PanelsChanged;
begin
  if csDestroying in ComponentState then
    Exit;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

function TPPGStatusBar.AutoSizeWidth: Boolean;
begin
  Result := False; // nur die Hoehe folgt der Schrift
end;

function TPPGStatusBar.CalcAutoSize(out AWidth, AHeight: Integer): Boolean;
begin
  AWidth := Width;
  AHeight := Max(PPGScale(22, ScalePPI), PPGMeasureTextNoCanvas('Wg', Font, 0, False).cy +
    2 * PPGScale(4, ScalePPI));
  Result := True;
end;

function TPPGStatusBar.ParentForm: TCustomForm;
begin
  Result := GetParentForm(Self);
end;

function TPPGStatusBar.SizeGripRect: TRect;
var
  G: Integer;
begin
  G := PPGScale(GripSize, ScalePPI);
  if UseRightToLeftAlignment then
    Result := Rect(0, Height - G, G, Height)
  else
    Result := Rect(Width - G, Height - G, Width, Height);
end;

function TPPGStatusBar.SizeGripActive: Boolean;
var
  F: TCustomForm;
  P: TPoint;
begin
  Result := False;
  if not FSizeGrip or (csDesigning in ComponentState) then
    Exit;
  F := ParentForm;
  if (F = nil) or not F.HandleAllocated or not HandleAllocated then
    Exit;
  if not (TForm(F).BorderStyle in [bsSizeable, bsSizeToolWin]) or (F.WindowState = wsMaximized) then
    Exit;
  // Nur, wenn die Leiste unten am Formular anliegt
  P := ClientToScreen(Point(0, Height));
  P := F.ScreenToClient(P);
  Result := Abs(P.Y - F.ClientHeight) <= 2;
end;

function TPPGStatusBar.PanelRect(Index: Integer): TRect;
var
  I, X, W, Right: Integer;
begin
  if FSimplePanel or (Index < 0) or (Index >= FPanels.Count) then
    Exit(Rect(0, 0, 0, 0));
  X := 0;
  Right := Width;
  for I := 0 to Index - 1 do
    Inc(X, PPGScale(FPanels[I].Width, ScalePPI));
  W := PPGScale(FPanels[Index].Width, ScalePPI);
  // Letztes Panel fuellt den Rest (wie TStatusBar)
  if (Index = FPanels.Count - 1) and (X + W < Right) then
    W := Right - X;
  Result := Rect(X, 0, Min(X + W, Right), Height);
  if UseRightToLeftAlignment then
    Result := Rect(Width - Result.Right, Result.Top, Width - Result.Left, Result.Bottom);
end;

procedure TPPGStatusBar.CMHintShow(var Message: TCMHintShow);
var
  I: Integer;
begin
  inherited;
  // Audit 5b: Hint eines Abschnitts als Tooltip (ShowHint muss an sein)
  I := PanelAt(Message.HintInfo.CursorPos.X, Message.HintInfo.CursorPos.Y);
  if (I >= 0) and (Panels[I].Hint <> '') then
  begin
    Message.HintInfo.HintStr := Panels[I].Hint;
    Message.HintInfo.CursorRect := PanelRect(I);
  end;
end;

function TPPGStatusBar.PanelAt(X, Y: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to FPanels.Count - 1 do
    if PtInRect(PanelRect(I), Point(X, Y)) then
      Exit(I);
  Result := -1;
end;

function TPPGStatusBar.GetCanvas: TCanvas;
begin
  if FInOwnerDraw then
    Result := FPanelCanvas
  else
    Result := nil;
end;

procedure TPPGStatusBar.DoDrawPanel(const ACanvas: IPPGCanvas; Panel: TPPGStatusPanel; const R: TRect);
var
  DC: HDC;
begin
  if not Assigned(FOnDrawPanel) then
    Exit;
  DC := ACanvas.BeginGdi;
  try
    FPanelCanvas.Handle := DC;
    try
      FPanelCanvas.Font := Font;
      FPanelCanvas.Brush.Style := bsClear;
      FInOwnerDraw := True;
      try
        FOnDrawPanel(Self, Panel, R);
      finally
        FInOwnerDraw := False;
      end;
    finally
      FPanelCanvas.Handle := 0;
    end;
  finally
    ACanvas.EndGdi(DC);
  end;
end;

procedure TPPGStatusBar.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  T: TPPGTokens;
  A: TPPGAppearance;
  IR: IPPGItemRenderer;
  PPI, I, X, Y, D, BarH: Integer;
  HC: Boolean;
  Fill, Border, TextCol, Accent, Track: TColor;
  R, TR, BR, G: TRect;
  P: TPPGStatusPanel;
  Flags: Cardinal;
  S: string;
  Sz: TSize;
  UseColors, Dk: Boolean;
  PText: TColor;
  PF: TFont;
begin
  PPI := ScalePPI;
  T := Tokens;
  A := EffectiveAppearance;
  HC := HighContrastSupport and PPGIsHighContrast;
  if HC then
  begin
    Fill := PPGColorToRGB(clBtnFace);
    Border := PPGColorToRGB(clBtnText);
    TextCol := PPGColorToRGB(clBtnText);
    Accent := PPGColorToRGB(clHighlight);
  end
  else
  begin
    Fill := PPGBlendColor(T.Background, T.Layer, 0.5);
    Border := T.Stroke;
    TextCol := T.TextSecondary;
    Accent := PPGColorToRGB(A.FocusColor);
    if UseVclStyle then
    begin
      Fill := PPGColorToRGB(A.Normal.Color);
      TextCol := PPGColorToRGB(A.Normal.TextColor);
    end;
  end;
  // Element-Stil der Leiste (Style) und Farben je Feld (nur ohne
  // Hochkontrast/VCL-Style)
  UseColors := not HC and not UseVclStyle;
  Dk := UseDarkMode;
  if UseColors then
  begin
    Fill := FBarStyle.FillFor(Dk, Fill);
    TextCol := FBarStyle.TextFor(Dk, TextCol);
    Border := FBarStyle.BorderFor(Dk, Border);
  end;
  FFonts.Clear;
  if not Enabled then
  begin
    TextCol := T.TextDisabled;
    Accent := PPGBlendColor(Accent, Fill, 0.6); // Fortschritt und Plakette zuruecknehmen
  end;
  Track := PPGBlendColor(Fill, TextCol, 0.2);
  ACanvas.FillRoundRect(ClientR, 0, Fill, 255);
  ACanvas.FillRoundRect(Rect(ClientR.Left, ClientR.Top, ClientR.Right, ClientR.Top + 1), 0, Border, 255);
  IR := PPGItemRendererOf(Renderer);
  if FSimplePanel then
  begin
    R := Rect(PPGScale(PanelPad, PPI), 1, Width - PPGScale(PanelPad, PPI), Height);
    if FAllowMarkup then
    begin
      FMarkup.Layout(FSimpleText, Font, Images, R.Right - R.Left, False);
      FMarkup.Draw(ACanvas, R.Left, (R.Top + R.Bottom - FMarkup.Size.cy) div 2, TextCol, Accent, Enabled);
    end
    else
      ACanvas.DrawText(R, FSimpleText, Font, TextCol,
        DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX));
  end
  else
    for I := 0 to FPanels.Count - 1 do
    begin
      P := FPanels[I];
      R := PanelRect(I);
      if IsRectEmpty(R) then
        Continue;
      PText := TextCol;
      if UseColors and (P.Color <> clDefault) and (P.Color <> clNone) then
        ACanvas.FillRoundRect(R, 0, PPGColorToRGB(P.Color), 255);
      if UseColors and Enabled and (P.TextColor <> clDefault) and (P.TextColor <> clNone) then
        PText := PPGColorToRGB(P.TextColor);
      PF := FFonts.ForStyle(FBarStyle, Font, P.FontStyle);
      // Trennlinie rechts (RTL links), nicht nach dem letzten Panel
      if (P.Bevel <> pbNone) and (I < FPanels.Count - 1) then
      begin
        if UseRightToLeftAlignment then
          X := R.Left
        else
          X := R.Right - 1;
        ACanvas.FillRoundRect(Rect(X, R.Top + PPGScale(5, PPI), X + 1, R.Bottom - PPGScale(4, PPI)), 0,
          Border, 255);
      end;
      TR := Rect(R.Left + PPGScale(PanelPad, PPI), R.Top + 1, R.Right - PPGScale(PanelPad, PPI), R.Bottom);
      if FSizeGrip and (I = FPanels.Count - 1) then
        if UseRightToLeftAlignment then
          Inc(TR.Left, PPGScale(GripSize, PPI))
        else
          Dec(TR.Right, PPGScale(GripSize, PPI));
      if P.Style = psOwnerDraw then
      begin
        DoDrawPanel(ACanvas, P, R);
        Continue;
      end;
      // Bild vor dem Inhalt
      if (Images <> nil) and (P.ImageIndex >= 0) and (P.ImageIndex < Images.Count) then
      begin
        Y := (TR.Top + TR.Bottom - Images.Height) div 2;
        if UseRightToLeftAlignment then
        begin
          ACanvas.DrawImage(Images, P.ImageIndex, TR.Right - Images.Width, Y, Enabled);
          Dec(TR.Right, Images.Width + PPGScale(4, PPI));
        end
        else
        begin
          ACanvas.DrawImage(Images, P.ImageIndex, TR.Left, Y, Enabled);
          Inc(TR.Left, Images.Width + PPGScale(4, PPI));
        end;
      end;
      case P.Kind of
        spkProgress:
          begin
            BarH := PPGScale(4, PPI);
            BR := Rect(TR.Left, (TR.Top + TR.Bottom - BarH) div 2, TR.Right, (TR.Top + TR.Bottom + BarH) div 2);
            ACanvas.FillRoundRect(BR, BarH div 2, Track, 255);
            D := Round((BR.Right - BR.Left) * P.Progress / 100);
            if D > 0 then
            begin
              if UseRightToLeftAlignment then
                BR.Left := BR.Right - D
              else
                BR.Right := BR.Left + D;
              ACanvas.FillRoundRect(BR, BarH div 2, Accent, 255);
            end;
          end;
        spkBadge:
          begin
            S := P.Text;
            if P.BadgeCount > 0 then
              S := IntToStr(P.BadgeCount);
            if S <> '' then
            begin
              Sz := IR.BadgeSize(ACanvas, S, Font, PPI);
              case P.Alignment of
                taRightJustify: X := TR.Right - Sz.cx;
                taCenter: X := (TR.Left + TR.Right - Sz.cx) div 2;
              else
                X := TR.Left;
              end;
              BR := Rect(X, (TR.Top + TR.Bottom - Sz.cy) div 2, X + Sz.cx, (TR.Top + TR.Bottom + Sz.cy) div 2);
              IR.DrawBadge(ACanvas, BR, S, Font, Accent, ContrastOn(Accent), PPI);
            end;
          end;
      else
        if FAllowMarkup then
        begin
          FMarkup.Layout(P.Text, PF, Images, TR.Right - TR.Left, False);
          case P.Alignment of
            taRightJustify: X := TR.Right - FMarkup.Size.cx;
            taCenter: X := (TR.Left + TR.Right - FMarkup.Size.cx) div 2;
          else
            X := TR.Left;
          end;
          ACanvas.PushClipRoundRect(TR, 0);
          try
            FMarkup.Draw(ACanvas, X, (TR.Top + TR.Bottom - FMarkup.Size.cy) div 2, PText, Accent, Enabled);
          finally
            ACanvas.PopClip;
          end;
        end
        else
        begin
          Flags := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX;
          case P.Alignment of
            taRightJustify: Flags := Flags or DT_RIGHT;
            taCenter: Flags := Flags or DT_CENTER;
          end;
          ACanvas.DrawText(TR, P.Text, PF, PText, DrawTextBiDiModeFlags(Flags));
        end;
      end;
    end;
  // Groessengriff: Punkte im Dreieck
  if FSizeGrip and SizeGripActive then
  begin
    G := SizeGripRect;
    D := Max(2, PPGScale(2, PPI));
    for I := 0 to 2 do
      for X := 0 to I do
      begin
        if UseRightToLeftAlignment then
          BR := Rect(G.Left + PPGScale(3, PPI) + X * 2 * D, G.Bottom - PPGScale(3, PPI) - (2 - I + X) * 2 * D - D,
            0, 0)
        else
          BR := Rect(G.Right - PPGScale(3, PPI) - X * 2 * D - D, G.Bottom - PPGScale(3, PPI) - (2 - I + X) * 2 * D - D,
            0, 0);
        BR.Right := BR.Left + D;
        BR.Bottom := BR.Top + D;
        ACanvas.FillRoundRect(BR, 0, TextCol, 160);
      end;
  end;
  FFonts.Clear; // keine Schrift-Handles ueber das Zeichnen hinaus
end;

procedure TPPGStatusBar.WMNCHitTest(var Message: TWMNCHitTest);
var
  P: TPoint;
begin
  inherited;
  if SizeGripActive then
  begin
    P := ScreenToClient(Point(Message.XPos, Message.YPos));
    if PtInRect(SizeGripRect, P) then
      if UseRightToLeftAlignment then
        Message.Result := HTBOTTOMLEFT
      else
        Message.Result := HTBOTTOMRIGHT;
  end;
end;

procedure TPPGStatusBar.WMNCLButtonDown(var Message: TWMNCLButtonDown);
var
  F: TCustomForm;
begin
  if (Message.HitTest = HTBOTTOMRIGHT) or (Message.HitTest = HTBOTTOMLEFT) then
  begin
    F := ParentForm;
    if (F <> nil) and F.HandleAllocated then
    begin
      // Groessenaenderung des Formulars statt der Leiste
      ReleaseCapture;
      if Message.HitTest = HTBOTTOMRIGHT then
        SendMessage(F.Handle, WM_SYSCOMMAND, SC_SIZE or WMSZ_BOTTOMRIGHT, 0)
      else
        SendMessage(F.Handle, WM_SYSCOMMAND, SC_SIZE or WMSZ_BOTTOMLEFT, 0);
      Exit;
    end;
  end;
  inherited;
end;

function TPPGStatusBar.ExecuteAction(Action: TBasicAction): Boolean;
begin
  // AutoHint wie TStatusBar: Hinweise der Anwendung anzeigen
  if FAutoHint and (Action is THintAction) and not Assigned(FOnHint) then
  begin
    if FSimplePanel or (FPanels.Count = 0) then
      SimpleText := THintAction(Action).Hint
    else
      FPanels[0].Text := THintAction(Action).Hint;
    Result := True;
  end
  else if FAutoHint and (Action is THintAction) then
  begin
    FOnHint(Self);
    Result := True;
  end
  else
    Result := inherited ExecuteAction(Action);
end;

{ ---- Barrierefreiheit ---- }

function TPPGStatusBar.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_STATUSBAR;
end;

function TPPGStatusBar.AccName: string;
begin
  if FSimplePanel then
    Result := PPGStripMarkup(FSimpleText)
  else
    Result := inherited AccName;
end;

function TPPGStatusBar.AccChildCount: Integer;
begin
  if FSimplePanel then
    Result := 0
  else
    Result := FPanels.Count;
end;

function TPPGStatusBar.AccChildName(Id: Integer): string;
var
  P: TPPGStatusPanel;
begin
  if (Id < 1) or (Id > AccChildCount) then
    Exit('');
  P := FPanels[Id - 1];
  case P.Kind of
    spkProgress: Result := IntToStr(P.Progress) + ' %';
    spkBadge:
      if P.BadgeCount > 0 then
        Result := IntToStr(P.BadgeCount)
      else
        Result := P.Text;
  else
    Result := PPGStripMarkup(P.Text);
  end;
  if (P.Hint <> '') and (P.Kind <> spkText) then
    Result := P.Hint + ': ' + Result;
end;

function TPPGStatusBar.AccChildRole(Id: Integer): Integer;
begin
  if (Id >= 1) and (Id <= AccChildCount) and (FPanels[Id - 1].Kind = spkProgress) then
    Result := ROLE_SYSTEM_PROGRESSBAR
  else
    Result := ROLE_SYSTEM_STATICTEXT;
end;

function TPPGStatusBar.AccChildState(Id: Integer): Integer;
begin
  Result := STATE_SYSTEM_READONLY;
end;

function TPPGStatusBar.AccChildRect(Id: Integer): TRect;
begin
  Result := PanelRect(Id - 1);
end;

function TPPGStatusBar.AccChildAt(X, Y: Integer): Integer;
begin
  Result := PanelAt(X, Y) + 1;
end;

function TPPGStatusBar.AccChildDefaultAction(Id: Integer): string;
begin
  Result := '';
end;

procedure TPPGStatusBar.AccChildDoDefault(Id: Integer);
begin
  // Panels haben keine Aktion
end;

function TPPGStatusBar.AccFocusedChild: Integer;
begin
  Result := 0;
end;

function TPPGStatusBar.AccSelectedChild: Integer;
begin
  Result := 0;
end;

end.
