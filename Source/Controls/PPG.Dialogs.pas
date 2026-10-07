unit PPG.Dialogs;

{ Dialoge im Stil der Suite (Phase 11g).

  TPPGTaskDialog erbt von Vcl.Dialogs.TCustomTaskDialog und ersetzt nur
  DoExecute: alle Properties, Collections (Buttons, RadioButtons) und
  Ereignisse sind die des Originals - DFMs und Code eines TTaskDialog laufen
  unveraendert (Klassenname tauschen). Statt TaskDialogIndirect baut er ein
  echtes Formular aus PPGlow-Controls (Label, Button, RadioButton, CheckBox,
  ProgressBar): eine Zeichenlogik, Presets, Dark Mode, Hochkontrast und
  Tastatur kommen aus den Controls.

  Verhalten wie das Windows-Original:
  - Ereignisse OnButtonClicked (CanClose), OnRadioButtonClicked,
    OnVerificationClicked, OnHyperlinkClicked, OnExpanded, OnTimer (200 ms,
    tfCallbackTimer), OnDialogCreated/Constructed/Destroyed. Nach Execute
    stehen ModalResult, Button, RadioButton, Expanded und
    tfVerificationFlagChecked wie beim Original.
  - Esc und Schliessen-Kreuz nur mit tfAllowDialogCancellation oder einem
    Abbrechen-Button (Ergebnis mrCancel, OnButtonClicked wird gefragt).
  - Strg+C kopiert Titel, Text und Buttons im Windows-Format, F1 = Hilfe.
  - Ton je Symbol (MessageBeep), Fenster ueber dem Elternformular bzw. mittig
    auf dessen Monitor (tfPositionRelativeToWindow), DPI des Zielmonitors.
  - Aenderungen aus Ereignissen (ProgressBar.Position, Buttons[i].Enabled,
    Text, Title) werden nach jedem Ereignis uebernommen - beim Original laufen
    sie ueber das Fensterhandle, das es hier nicht gibt.
  Zusaetzlich: Preset/StyleManager, AllowMarkup (Text mit <b>, <i>, ...) und
  ContentControl (eigenes Control im Dialog, wird danach zurueckgegeben).

  PPGMessageDlg/PPGMessageDlgPos/PPGShowMessage/PPGInputQuery/PPGInputBox:
  gleiche Signaturen wie die VCL-Funktionen, laufen ueber TPPGTaskDialog.
  Aufruf nur im Haupt-Thread (EPPGError statt Haenger). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.UITypes, Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  PPG.Types, PPG.Tokens, PPG.Render.Intf, PPG.StyleManager, PPG.Controls.Base,
  PPG.Button, PPG.Labels, PPG.CheckBox, PPG.RadioButton, PPG.ProgressBar, PPG.Edit;

type
  TPPGTaskDialog = class;
  TPPGDialogForm = class;

  /// Command-Link (tfUseCommandLinks): grosser Button mit Pfeil, Text und Hinweis.
  TPPGCommandLink = class(TPPGCustomButton)
  private
    FNote: string;
    FShield: Boolean;
    FNoteFont: TFont;
    FTitleFont: TFont;
    procedure SetNote(const Value: string);
    procedure PrepareFonts;
    function ArrowW: Integer;
  protected
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function AccDescription: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Hoehe fuer die Breite W (Text und Hinweis umbrochen).
    function HeightFor(W: Integer): Integer;
    property Note: string read FNote write SetNote;
    /// Schild-Symbol statt Pfeil (ElevationRequired).
    property Shield: Boolean read FShield write FShield;
    property Default;
    property Font;
    property Preset;
    property StyleManager;
  end;

  /// Symbol oben links (Info, Warnung, Fehler, Schild, Frage, eigenes).
  TPPGDialogIcon = class(TGraphicControl)
  private
    FKind: Integer;      // tdiNone.. bzw. PPGDlgIconQuestion
    FIcon: TIcon;
    FTokens: TPPGTokens;
  protected
    procedure Paint; override;
  public
    property Kind: Integer read FKind write FKind;
    property Icon: TIcon read FIcon write FIcon;
  end;

  /// Das Formular waehrend Execute (fuer Tests, Automatisierung, Screenshots).
  TPPGDialogForm = class(TForm)
  private
    FDialog: TPPGTaskDialog;
    FPPI: Integer;
    FContent: TPanel;
    FFooter: TPanel;
    FIcon: TPPGDialogIcon;
    FTitleLabel: TPPGLabel;
    FTextLabel: TControl;
    FExpandedLabel: TControl;
    FFooterIcon: TPPGDialogIcon;
    FFooterLabel: TControl;
    FProgress: TPPGProgressBar;
    FRadios: TList;
    FLinks: TList;
    FButtons: TList;          // TPPGButton, Tag = ModalResult
    FExpandButton: TPPGButton;
    FVerify: TPPGCheckBox;
    FTimer: TTimer;
    FTimerStart: Cardinal;
    FResult: TModalResult;
    FClosing: Boolean;
    FContentParent: TWinControl;
    FContentBounds: TRect;
    FContentVisible: Boolean;
    FTitleText: string;
    FBodyText: string;
    FProgressFlags: Boolean;
    FCentered: Boolean;
    function S(Value: Integer): Integer;
    function NewTextControl(AParent: TWinControl; const Text: string; Secondary: Boolean): TControl;
    procedure SetTextControl(C: TControl; const Text: string);
    function TextHeight(C: TControl; W: Integer): Integer;
    procedure BuildControls;
    procedure ButtonClick(Sender: TObject);
    procedure RadioClick(Sender: TObject);
    procedure VerifyClick(Sender: TObject);
    procedure ExpandClick(Sender: TObject);
    procedure LinkClick(Sender: TObject; const Link: string; LinkType: TSysLinkType);
    procedure TimerTick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
    procedure CenterOnParent;
    procedure WMDlgClose(var Message: TMessage); message WM_USER + $520;
    function ExpandCaption: string;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor CreateFor(ADialog: TPPGTaskDialog; AParentWnd: HWND); reintroduce;
    destructor Destroy; override;
    /// Ordnet alle Teile neu an (nach Ausklappen, geaenderten Texten).
    procedure Arrange;
    /// Uebernimmt Aenderungen aus Ereignissen (Fortschritt, Buttons, Texte).
    procedure SyncState;
    /// Wie ein Klick auf den Button mit diesem Ergebnis (Tests, Automatisierung).
    procedure ClickButton(AModalResult: TModalResult);
    /// Wie Esc bzw. das Schliessen-Kreuz.
    procedure Cancel;
    function ButtonByResult(AModalResult: TModalResult): TControl;
    function CanCancel: Boolean;
    /// Text fuer Strg+C (Windows-Format).
    function CopyText: string;
    function RadioCount: Integer;
    function Radio(Index: Integer): TPPGRadioButton;
    function ButtonCount: Integer;
    function ButtonAt(Index: Integer): TControl;
    property Dialog: TPPGTaskDialog read FDialog;
    property TitleLabel: TPPGLabel read FTitleLabel;
    property ProgressBar: TPPGProgressBar read FProgress;
    property VerificationBox: TPPGCheckBox read FVerify;
    property ExpandButton: TPPGButton read FExpandButton;
    property DialogIcon: TPPGDialogIcon read FIcon;
    property FooterPanel: TPanel read FFooter;
    property ContentPanel: TPanel read FContent;
  end;

  TPPGDialogShowEvent = procedure(Form: TPPGDialogForm) of object;

  TPPGTaskDialog = class(TCustomTaskDialog)
  private
    FPreset: string;
    FStyleManager: TPPGStyleManager;
    FAllowMarkup: Boolean;
    FContentControl: TControl;
    FForm: TPPGDialogForm;
    // nur fuer die Funktionen dieser Unit (MessageDlg, InputQuery)
    FEscResult: TModalResult;
    FHelpResult: TModalResult;
    FQuestionIcon: Boolean;
    FOnFormShow: TPPGDialogShowEvent;
    FValidate: TNotifyEvent;
    FPosX, FPosY: Integer;
    procedure SetStyleManager(const Value: TPPGStyleManager);
    procedure SetContentControl(const Value: TControl);
    procedure NoOp(Sender: TObject);
    procedure InternalButtonClicked(AModalResult: TModalResult; var CanClose: Boolean);
    procedure InternalRadioClicked(Item: TTaskDialogBaseButtonItem);
    procedure InternalVerificationClicked(Checked: Boolean);
    procedure InternalExpanded(AExpanded: Boolean; Notify: Boolean);
    procedure InternalHyperlink(const Link: string);
    procedure InternalTimer(TickCount: Cardinal; var Reset: Boolean);
    procedure InternalCreated;
    procedure InternalDestroyed;
  strict protected
    function DoExecute(ParentWnd: HWND): Boolean; override;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    function EffectivePreset: string;
    /// Das Formular waehrend Execute (sonst nil).
    property DialogForm: TPPGDialogForm read FForm;
  published
    property Buttons;
    property Caption;
    property CommonButtons;
    property CustomFooterIcon;
    property CustomMainIcon;
    property DefaultButton;
    property ExpandButtonCaption;
    property ExpandedText;
    property Flags;
    property FooterIcon;
    property FooterText;
    property HelpContext;
    property MainIcon;
    property ProgressBar;
    property RadioButtons;
    property Text;
    property Title;
    property VerificationText;
    property OnButtonClicked;
    property OnDialogConstructed;
    property OnDialogCreated;
    property OnDialogDestroyed;
    property OnExpanded;
    property OnHyperlinkClicked;
    property OnNavigated;
    property OnRadioButtonClicked;
    property OnTimer;
    property OnVerificationClicked;
    { PPGlow }
    property Preset: string read FPreset write FPreset;
    property StyleManager: TPPGStyleManager read FStyleManager write SetStyleManager;
    /// Text, Titel-Zusatz und Fusszeile mit Markup (<b>, <i>, <color=...>).
    property AllowMarkup: Boolean read FAllowMarkup write FAllowMarkup default False;
    /// Eigenes Control im Dialog unter dem Text (z.B. ein Panel mit Feldern).
    property ContentControl: TControl read FContentControl write SetContentControl;
  end;

  /// Pruefung fuer PPGInputQuery: False = Dialog bleibt offen, ErrorText
  /// erscheint unter den Feldern, FieldIndex bekommt den Fokus.
  TPPGInputValidate = reference to function(const Values: TArray<string>;
    var ErrorText: string; var FieldIndex: Integer): Boolean;

const
  /// Zusaetzliches Symbol (MessageDlg mtConfirmation).
  PPGDlgIconQuestion = 100;

function PPGMessageDlg(const Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons;
  HelpCtx: Longint): Integer; overload;
function PPGMessageDlg(const Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons;
  HelpCtx: Longint; DefaultButton: TMsgDlgBtn): Integer; overload;
/// X, Y = linke obere Ecke (Bildschirm); -1 = mittig.
function PPGMessageDlgPos(const Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons;
  HelpCtx: Longint; X, Y: Integer): Integer;
procedure PPGShowMessage(const Msg: string);
/// Prompt mit #31 am Anfang = Passwortfeld (wie die VCL).
function PPGInputQuery(const ACaption, APrompt: string; var Value: string;
  const Validate: TPPGInputValidate = nil): Boolean; overload;
function PPGInputQuery(const ACaption: string; const APrompts: array of string;
  var AValues: array of string; const Validate: TPPGInputValidate = nil): Boolean; overload;
function PPGInputBox(const ACaption, APrompt, ADefault: string): string;

var
  /// Wird gerufen, sobald ein Dialog sichtbar wird (Tests, Automatisierung,
  /// Screenshots). Nicht fuer Anwendungslogik - dafuer gibt es die Ereignisse.
  PPGOnDialogShow: TPPGDialogShowEvent = nil;

implementation

uses
  PPG.Lang,
  System.Math, Vcl.Clipbrd, Vcl.Themes, Vcl.Menus, Vcl.ComCtrls, Winapi.oleacc,
  PPG.Consts, PPG.Appearance, PPG.DpiUtils, PPG.Exceptions, PPG.ErrorHandler,
  PPG.Render.Registry, PPG.Render.Gdi, PPG.IconFont, PPG.Theme, PPG.Markup,
  PPG.Accessibility, PPG.VclStyles, PPG.Hints;

const
  // Reihenfolge der Standard-Buttons wie Windows (Retry vor Cancel)
  CommonOrder: array[0..5] of TTaskDialogCommonButton =
    (tcbOk, tcbYes, tcbNo, tcbRetry, tcbCancel, tcbClose);
  CommonResult: array[TTaskDialogCommonButton] of TModalResult =
    (mrOk, mrYes, mrNo, mrCancel, mrRetry, mrClose);

function CommonCaption(B: TTaskDialogCommonButton): string;
begin
  case B of
    tcbOk: Result := PPGStr(@SPPGDlgOK);
    tcbYes: Result := PPGStr(@SPPGDlgYes);
    tcbNo: Result := PPGStr(@SPPGDlgNo);
    tcbCancel: Result := PPGStr(@SPPGDlgCancel);
    tcbRetry: Result := PPGStr(@SPPGDlgRetry);
  else
    Result := PPGStr(@SPPGDlgClose);
  end;
end;

function EscapeText(const S: string): string;
begin
  Result := StringReplace(StringReplace(S, '&', '&amp;', [rfReplaceAll]), '<', '&lt;',
    [rfReplaceAll]);
end;

function IsHC: Boolean;
begin
  Result := PPGIsHighContrast;
end;

{ TPPGCommandLink }

constructor TPPGCommandLink.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNoteFont := TFont.Create;
  FTitleFont := TFont.Create;
end;

destructor TPPGCommandLink.Destroy;
begin
  FreeAndNil(FNoteFont);
  FreeAndNil(FTitleFont);
  inherited Destroy;
end;

procedure TPPGCommandLink.SetNote(const Value: string);
begin
  FNote := Value;
  Invalidate;
end;

function TPPGCommandLink.ArrowW: Integer;
begin
  Result := PPGScale(32, ScalePPI);
end;

procedure TPPGCommandLink.PrepareFonts;
begin
  FTitleFont.Assign(Font);
  FTitleFont.Height := MulDiv(Font.Height, 5, 4);
  FNoteFont.Assign(Font);
end;

function TPPGCommandLink.HeightFor(W: Integer): Integer;
var
  TW: Integer;
begin
  PrepareFonts;
  TW := Max(W - ArrowW - PPGScale(12, ScalePPI), PPGScale(40, ScalePPI));
  Result := PPGScale(10, ScalePPI) +
    PPGMeasureTextNoCanvas(StripHotkey(Caption), FTitleFont, TW, True).cy;
  if FNote <> '' then
    Inc(Result, PPGScale(2, ScalePPI) + PPGMeasureTextNoCanvas(FNote, FNoteFont, TW, True).cy);
  Inc(Result, PPGScale(10, ScalePPI));
end;

function TPPGCommandLink.AccDescription: string;
begin
  Result := FNote;
end;

procedure TPPGCommandLink.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  St: TPPGSurfaceStyle;
  T: TPPGTokens;
  PPI, Y, TX: Integer;
  R, AR: TRect;
  TextC, NoteC, ArrowC: TColor;
  Sz: TSize;
  HC: Boolean;
begin
  PPI := ScalePPI;
  T := Tokens;
  HC := HighContrastSupport and IsHC;
  PrepareFonts;
  St := GetCurrentStyle;
  St.GlowAlpha := 0;
  // Wie Windows: ohne Flaeche, bis die Maus darueber ist oder er gedrueckt wird
  ACanvas.FillRoundRect(ClientR, 0, PPGColorToRGB(GetBackgroundColor), 255);
  if (VisualState <> vsNormal) or Default then
    Renderer.DrawSurface(ACanvas, ClientR, St);
  if HC then
  begin
    TextC := PPGColorToRGB(clBtnText);
    NoteC := TextC;
    ArrowC := TextC;
  end
  else
  begin
    TextC := St.TextColor;
    if (VisualState = vsNormal) and not Default then
      TextC := T.TextPrimary;
    NoteC := T.TextSecondary;
    ArrowC := T.Accent;
  end;
  if not Enabled then
  begin
    TextC := T.TextDisabled;
    NoteC := TextC;
    ArrowC := TextC;
  end;
  AR := Rect(ClientR.Left, ClientR.Top + PPGScale(8, PPI), ClientR.Left + ArrowW,
    ClientR.Top + PPGScale(8, PPI) + PPGScale(20, PPI));
  if FShield then
  begin
    if not PPGDrawIconChar(ACanvas, AR, $EA18, ArrowC, PPGScale(16, PPI)) then
      ACanvas.DrawText(AR, '!', FTitleFont, ArrowC, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end
  else if not PPGDrawIconChar(ACanvas, AR, $E72A, ArrowC, PPGScale(16, PPI)) then
    ACanvas.DrawText(AR, '>', FTitleFont, ArrowC, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  TX := ClientR.Left + ArrowW;
  Y := ClientR.Top + PPGScale(10, PPI);
  R := Rect(TX, Y, ClientR.Right - PPGScale(12, PPI), ClientR.Bottom);
  Sz := PPGMeasureTextNoCanvas(StripHotkey(Caption), FTitleFont, R.Right - R.Left, True);
  ACanvas.DrawText(Rect(R.Left, Y, R.Right, Y + Sz.cy), Caption, FTitleFont, TextC,
    DT_WORDBREAK or DT_HIDEPREFIX);
  Inc(Y, Sz.cy + PPGScale(2, PPI));
  if FNote <> '' then
    ACanvas.DrawText(Rect(R.Left, Y, R.Right, ClientR.Bottom), FNote, FNoteFont, NoteC,
      DT_WORDBREAK or DT_NOPREFIX);
  if FocusVisible then
  begin
    St.Focused := True;
    St.BorderColor := PPGColorToRGB(EffectiveAppearance.FocusColor);
    Renderer.DrawFocus(ACanvas, ClientR, St);
  end;
end;

{ TPPGDialogIcon }

procedure TPPGDialogIcon.Paint;
var
  C: IPPGCanvas;
  R: TRect;
  Col: TColor;
  G: TPPGIconGlyph;
  Ch: Word;
  Fallback: string;
  Sz: Integer;
begin
  R := ClientRect;
  if (FIcon <> nil) and not FIcon.Empty then
  begin
    DrawIconEx(Canvas.Handle, 0, 0, FIcon.Handle, Width, Height, 0, 0, DI_NORMAL);
    Exit;
  end;
  if FKind = tdiNone then
    Exit;
  FTokens := PPGDefaultTokens(TPPGTheme.IsDark and not PPGVclStyleActive);
  Ch := 0;
  case FKind of
    tdiWarning: begin G := igWarning; Col := FTokens.Warning; Fallback := '!'; end;
    tdiError: begin G := igError; Col := FTokens.Danger; Fallback := 'x'; end;
    tdiShield: begin G := igInfo; Ch := $EA18; Col := FTokens.Accent; Fallback := '!'; end;
    PPGDlgIconQuestion: begin G := igInfo; Ch := $E9CE; Col := FTokens.Accent; Fallback := '?'; end;
  else
    begin G := igInfo; Col := FTokens.Accent; Fallback := 'i'; end;
  end;
  if IsHC then
    Col := PPGColorToRGB(clWindowText);
  Sz := Height * 7 div 8;
  C := TPPGRendererRegistry.CreateCanvas(Canvas.Handle);
  try
    if Ch <> 0 then
    begin
      if PPGDrawIconChar(C, R, Ch, Col, Sz) then
        Exit;
    end
    else if PPGDrawIcon(C, R, G, Col, Sz) then
      Exit;
    // Ohne Symbolschrift: Kreis mit Zeichen
    C.FillEllipse(R, Col, 255);
    Canvas.Font.Assign(Font);
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Height := -Height * 2 div 3;
    C.DrawText(R, Fallback, Canvas.Font, clWhite, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  finally
    C := nil;
  end;
end;

{ TPPGDialogForm }

constructor TPPGDialogForm.CreateFor(ADialog: TPPGTaskDialog; AParentWnd: HWND);
var
  P: TWinControl;
begin
  // Keine DFM: CreateNew
  inherited CreateNew(nil);
  FDialog := ADialog;
  FRadios := TList.Create;
  FLinks := TList.Create;
  FButtons := TList.Create;
  FPPI := Screen.PixelsPerInch;
  if FPPI <= 0 then
    FPPI := 96;
  // Elternformular: Dialog liegt immer darueber (auch auf anderem Monitor)
  P := FindControl(AParentWnd);
  if P is TCustomForm then
  begin
    PopupMode := pmExplicit;
    PopupParent := TCustomForm(P);
  end;
  Font.Assign(Screen.MessageFont);
  KeyPreview := True;
  OnKeyDown := FormKeyDown;
  OnCloseQuery := FormCloseQuery;
  OnShow := FormShow;
  if tfCanBeMinimized in FDialog.Flags then
  begin
    BorderStyle := bsSingle;
    BorderIcons := [biSystemMenu, biMinimize];
  end
  else
    BorderStyle := bsDialog;
  if (FDialog.Flags * [tfRtlLayout] <> []) then
    BiDiMode := bdRightToLeft;
  if FDialog.Caption <> '' then
    Caption := FDialog.Caption
  else
    Caption := Application.Title;
  TPPGTheme.ApplyToForm(Self);
  BuildControls;
  Arrange;
end;

destructor TPPGDialogForm.Destroy;
begin
  FreeAndNil(FTimer);
  FreeAndNil(FRadios);
  FreeAndNil(FLinks);
  FreeAndNil(FButtons);
  inherited Destroy;
end;

procedure TPPGDialogForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Ohne Elternformular: eigener Eintrag in der Taskleiste wie MessageBox
  if (PopupParent = nil) and not Application.MainFormOnTaskBar then
    Params.WndParent := Application.Handle;
end;

function TPPGDialogForm.S(Value: Integer): Integer;
begin
  Result := MulDiv(Value, FPPI, 96);
end;

function TPPGDialogForm.NewTextControl(AParent: TWinControl; const Text: string;
  Secondary: Boolean): TControl;
var
  L: TPPGLabel;
  LL: TPPGLinkLabel;
begin
  if (tfEnableHyperlinks in FDialog.Flags) and (Pos('<a', LowerCase(Text)) > 0) then
  begin
    LL := TPPGLinkLabel.Create(Self);
    LL.Parent := AParent;
    LL.AutoSize := False;
    LL.Preset := FDialog.EffectivePreset;
    LL.StyleManager := FDialog.StyleManager;
    LL.OnLinkClick := LinkClick;
    FLinks.Add(LL);
    Result := LL;
  end
  else
  begin
    L := TPPGLabel.Create(Self);
    L.Parent := AParent;
    L.AutoSize := False;
    L.WordWrap := True;
    L.ShowAccelChar := False;
    L.Transparent := True;
    L.Secondary := Secondary;
    L.AllowMarkup := True;
    Result := L;
  end;
  SetTextControl(Result, Text);
end;

procedure TPPGDialogForm.SetTextControl(C: TControl; const Text: string);
var
  T: string;
begin
  // Markup nur auf Wunsch (AllowMarkup) bzw. fuer Links; sonst bleibt "<" Text
  if FDialog.AllowMarkup or (C is TPPGLinkLabel) then
    T := Text
  else
    T := EscapeText(Text);
  if C is TPPGLinkLabel then
    TPPGLinkLabel(C).Caption := T
  else
    TPPGLabel(C).Caption := T;
end;

function TPPGDialogForm.TextHeight(C: TControl; W: Integer): Integer;
var
  L: TPPGMarkupLayout;
  F: TFont;
  T: string;
begin
  L := TPPGMarkupLayout.Create;
  try
    if C is TPPGLinkLabel then
    begin
      F := TPPGLinkLabel(C).Font;
      T := TPPGLinkLabel(C).Caption;
      L.Layout(T, F, nil, W - 2 * S(2), True);
      Result := L.Size.cy + 2 * S(1);
    end
    else
    begin
      F := TPPGLabel(C).Font;
      T := TPPGLabel(C).Caption;
      L.Layout(T, F, nil, W, True);
      Result := L.Size.cy;
    end;
  finally
    L.Free;
  end;
end;

procedure TPPGDialogForm.BuildControls;
var
  I: Integer;
  Item: TTaskDialogBaseButtonItem;
  B: TPPGButton;
  CL: TPPGCommandLink;
  RB: TPPGRadioButton;
  CB: TTaskDialogCommonButton;
  Def: TControl;
  DefResult: TModalResult;
  FooterColor: TColor;

  function AddButton(const ACaption: string; AResult: TModalResult; AEnabled: Boolean): TPPGButton;
  begin
    Result := TPPGButton.Create(Self);
    Result.Parent := FFooter;
    Result.Caption := ACaption;
    Result.Tag := AResult;
    Result.Enabled := AEnabled;
    Result.Preset := FDialog.EffectivePreset;
    Result.StyleManager := FDialog.StyleManager;
    Result.OnClick := ButtonClick;
    FButtons.Add(Result);
  end;

begin
  FContent := TPanel.Create(Self);
  FContent.Parent := Self;
  FContent.BevelOuter := bvNone;
  FContent.Caption := '';
  FContent.ParentBackground := False;
  FContent.ParentColor := True;
  FContent.Align := alClient;
  FFooter := TPanel.Create(Self);
  FFooter.Parent := Self;
  FFooter.BevelOuter := bvNone;
  FFooter.Caption := '';
  FFooter.ParentBackground := False;
  FooterColor := Color;
  if IsHC then
    FooterColor := clBtnFace
  else if not PPGVclStyleActive then
    FooterColor := PPGBlendColor(PPGColorToRGB(Color), PPGColorToRGB(Font.Color), 0.05);
  FFooter.Color := FooterColor;
  FFooter.Align := alBottom;

  // Symbol, Titel, Text
  FIcon := TPPGDialogIcon.Create(Self);
  FIcon.Parent := FContent;
  if FDialog.FQuestionIcon then
    FIcon.Kind := PPGDlgIconQuestion
  else
    FIcon.Kind := FDialog.MainIcon;
  if tfUseHiconMain in FDialog.Flags then
    FIcon.Icon := FDialog.CustomMainIcon;
  FTitleLabel := TPPGLabel.Create(Self);
  FTitleLabel.Parent := FContent;
  FTitleLabel.AutoSize := False;
  FTitleLabel.WordWrap := True;
  FTitleLabel.ShowAccelChar := False;
  FTitleLabel.Transparent := True;
  FTitleLabel.Font.Height := MulDiv(Font.Height, 4, 3);
  FTitleLabel.Font.Style := [fsBold];
  FTitleText := FDialog.Title;
  FTitleLabel.Caption := FTitleText;
  FBodyText := FDialog.Text;
  FTextLabel := NewTextControl(FContent, FBodyText, False);

  // Eigenes Control
  if FDialog.ContentControl <> nil then
  begin
    FContentParent := FDialog.ContentControl.Parent;
    FContentBounds := FDialog.ContentControl.BoundsRect;
    FContentVisible := FDialog.ContentControl.Visible;
    FDialog.ContentControl.Parent := FContent;
    FDialog.ContentControl.Visible := True;
  end;

  // Fortschritt
  FProgress := TPPGProgressBar.Create(Self);
  FProgress.Parent := FContent;
  FProgress.Preset := FDialog.EffectivePreset;
  FProgress.StyleManager := FDialog.StyleManager;
  FProgressFlags := FDialog.Flags * [tfShowProgressBar, tfShowMarqueeProgressBar] <> [];

  // Optionsfelder
  for I := 0 to FDialog.RadioButtons.Count - 1 do
  begin
    Item := FDialog.RadioButtons[I];
    RB := TPPGRadioButton.Create(Self);
    RB.Parent := FContent;
    RB.Caption := Item.Caption;
    RB.Tag := I;
    RB.Enabled := Item.Enabled;
    RB.Preset := FDialog.EffectivePreset;
    RB.StyleManager := FDialog.StyleManager;
    FRadios.Add(RB);
  end;
  if (FRadios.Count > 0) and not (tfNoDefaultRadioButton in FDialog.Flags) then
  begin
    I := 0;
    if FDialog.RadioButtons.DefaultButton <> nil then
      I := FDialog.RadioButtons.DefaultButton.Index;
    TPPGRadioButton(FRadios[I]).Checked := True; // Code: ohne Ereignis
    FDialog.InternalRadioClicked(FDialog.RadioButtons[I]);
  end;
  for I := 0 to FRadios.Count - 1 do
    TPPGRadioButton(FRadios[I]).OnClick := RadioClick;

  // Eigene Buttons: als Command-Links im Inhalt oder unten in der Leiste
  Def := nil;
  DefResult := CommonResult[FDialog.DefaultButton];
  if FDialog.Buttons.DefaultButton <> nil then
    DefResult := FDialog.Buttons.DefaultButton.ModalResult;
  for I := 0 to FDialog.Buttons.Count - 1 do
  begin
    Item := FDialog.Buttons[I];
    if tfUseCommandLinks in FDialog.Flags then
    begin
      CL := TPPGCommandLink.Create(Self);
      CL.Parent := FContent;
      CL.Caption := Item.Caption;
      CL.Note := TTaskDialogButtonItem(Item).CommandLinkHint;
      CL.Shield := TTaskDialogButtonItem(Item).ElevationRequired;
      CL.Tag := Item.ModalResult;
      CL.Enabled := Item.Enabled;
      CL.Preset := FDialog.EffectivePreset;
      CL.StyleManager := FDialog.StyleManager;
      CL.OnClick := ButtonClick;
      FButtons.Add(CL);
      if Item.ModalResult = DefResult then
        Def := CL;
    end
    else
    begin
      B := AddButton(Item.Caption, Item.ModalResult, Item.Enabled);
      if Item.ModalResult = DefResult then
        Def := B;
    end;
  end;
  for I := 0 to High(CommonOrder) do
  begin
    CB := CommonOrder[I];
    if CB in FDialog.CommonButtons then
    begin
      B := AddButton(CommonCaption(CB), CommonResult[CB], True);
      if (Def = nil) and (CommonResult[CB] = DefResult) then
        Def := B;
    end;
  end;
  // Ohne Buttons: OK wie das Original
  if FButtons.Count = 0 then
  begin
    B := AddButton(CommonCaption(tcbOk), mrOk, True);
    Def := B;
  end;
  if Def is TPPGButton then
    TPPGButton(Def).Default := True
  else if Def is TPPGCommandLink then
    TPPGCommandLink(Def).Default := True;
  if Def <> nil then
    ActiveControl := TWinControl(Def);

  // Ausklappen und Bestaetigung
  if FDialog.ExpandedText <> '' then
  begin
    FExpandButton := TPPGButton.Create(Self);
    FExpandButton.Parent := FFooter;
    FExpandButton.Preset := FDialog.EffectivePreset;
    FExpandButton.StyleManager := FDialog.StyleManager;
    FExpandButton.OnClick := ExpandClick;
    if tfExpandFooterArea in FDialog.Flags then
      FExpandedLabel := NewTextControl(FFooter, FDialog.ExpandedText, True)
    else
      FExpandedLabel := NewTextControl(FContent, FDialog.ExpandedText, False);
  end;
  if FDialog.VerificationText <> '' then
  begin
    FVerify := TPPGCheckBox.Create(Self);
    FVerify.Parent := FFooter;
    FVerify.Caption := FDialog.VerificationText;
    FVerify.Checked := tfVerificationFlagChecked in FDialog.Flags;
    FVerify.Preset := FDialog.EffectivePreset;
    FVerify.StyleManager := FDialog.StyleManager;
    FVerify.OnClick := VerifyClick;
  end;
  if FDialog.FooterText <> '' then
  begin
    FFooterIcon := TPPGDialogIcon.Create(Self);
    FFooterIcon.Parent := FFooter;
    FFooterIcon.Kind := FDialog.FooterIcon;
    if tfUseHiconFooter in FDialog.Flags then
      FFooterIcon.Icon := FDialog.CustomFooterIcon;
    FFooterLabel := NewTextControl(FFooter, FDialog.FooterText, True);
  end;
  // Zeitgeber
  if tfCallbackTimer in FDialog.Flags then
  begin
    FTimer := TTimer.Create(nil);
    FTimer.Enabled := False;
    FTimer.Interval := 200;
    FTimer.OnTimer := TimerTick;
  end;
  SyncState;
end;

function TPPGDialogForm.ExpandCaption: string;
begin
  if FDialog.ExpandButtonCaption <> '' then
    Result := FDialog.ExpandButtonCaption
  else if FDialog.Expanded then
    Result := PPGStr(@SPPGDlgHideDetails)
  else
    Result := PPGStr(@SPPGDlgShowDetails);
end;

procedure TPPGDialogForm.Arrange;
var
  Pad, X, Y, ColW, W, I, H, BW, BH, FooterH, Gap, BX, Need, IconSz: Integer;
  C: TControl;
  HasIcon: Boolean;
  CL: TPPGCommandLink;
  LongestLine: Integer;
  RowLeft: Integer;
begin
  Pad := S(20);
  Gap := S(10);
  BH := S(32);
  IconSz := S(32);
  HasIcon := (FIcon.Kind <> tdiNone) or ((FIcon.Icon <> nil) and not FIcon.Icon.Empty);
  // Breite: nach dem Text, wie tfSizeToContent zwischen 320 und 560
  LongestLine := PPGMeasureTextNoCanvas(StripHotkey(FDialog.Text), Font, 0, False).cx;
  W := EnsureRange(LongestLine, S(320), S(520));
  // Buttons brauchen evtl. mehr Platz
  Need := 0;
  for I := 0 to FButtons.Count - 1 do
    if TObject(FButtons[I]) is TPPGButton then
      Inc(Need, Max(S(88), PPGMeasureTextNoCanvas(StripHotkey(TPPGButton(FButtons[I]).Caption),
        Font, 0, False).cx + S(28)) + S(8));
  if FExpandButton <> nil then
    Inc(Need, PPGMeasureTextNoCanvas(ExpandCaption, Font, 0, False).cx + S(40));
  if HasIcon then
    ColW := Max(W, Need - IconSz - S(12))
  else
    ColW := Max(W, Need);
  if HasIcon then
    X := Pad + IconSz + S(12)
  else
    X := Pad;

  // Inhalt
  Y := Pad;
  FIcon.Visible := HasIcon;
  FIcon.SetBounds(Pad, Pad, IconSz, IconSz);
  FTitleLabel.Visible := FDialog.Title <> '';
  if FTitleLabel.Visible then
  begin
    H := TextHeight(FTitleLabel, ColW);
    FTitleLabel.SetBounds(X, Y, ColW, H);
    Inc(Y, H + S(8));
  end;
  FTextLabel.Visible := FDialog.Text <> '';
  if FTextLabel.Visible then
  begin
    H := TextHeight(FTextLabel, ColW);
    FTextLabel.SetBounds(X, Y, ColW, H);
    Inc(Y, H + Gap);
  end;
  if HasIcon and (Y < Pad + IconSz + Gap) then
    Y := Pad + IconSz + Gap;
  if FDialog.ContentControl <> nil then
  begin
    C := FDialog.ContentControl;
    C.SetBounds(X, Y, ColW, C.Height);
    Inc(Y, C.Height + Gap);
  end;
  FProgress.Visible := FDialog.Flags * [tfShowProgressBar, tfShowMarqueeProgressBar] <> [];
  if FProgress.Visible then
  begin
    FProgress.SetBounds(X, Y, ColW, S(8));
    Inc(Y, S(8) + Gap + S(4));
  end;
  for I := 0 to FRadios.Count - 1 do
  begin
    TPPGRadioButton(FRadios[I]).SetBounds(X, Y, ColW, S(24));
    Inc(Y, S(26));
  end;
  if FRadios.Count > 0 then
    Inc(Y, Gap - S(2));
  for I := 0 to FButtons.Count - 1 do
    if TObject(FButtons[I]) is TPPGCommandLink then
    begin
      CL := TPPGCommandLink(FButtons[I]);
      H := CL.HeightFor(ColW);
      CL.SetBounds(X - S(8), Y, ColW + S(8), H);
      Inc(Y, H + S(4));
    end;
  if (FExpandedLabel <> nil) and (FExpandedLabel.Parent = FContent) then
  begin
    FExpandedLabel.Visible := FDialog.Expanded;
    if FExpandedLabel.Visible then
    begin
      H := TextHeight(FExpandedLabel, ColW);
      FExpandedLabel.SetBounds(X, Y, ColW, H);
      Inc(Y, H + Gap);
    end;
  end;
  Inc(Y, Pad - Gap);

  // Fussleiste: links Ausklappen, rechts Buttons; darunter Bestaetigung, Fusszeile
  FooterH := S(12);
  BX := Pad + ColW + (X - Pad);
  for I := FButtons.Count - 1 downto 0 do
    if TObject(FButtons[I]) is TPPGButton then
    begin
      BW := Max(S(88), PPGMeasureTextNoCanvas(StripHotkey(TPPGButton(FButtons[I]).Caption),
        Font, 0, False).cx + S(28));
      Dec(BX, BW);
      TPPGButton(FButtons[I]).SetBounds(BX, FooterH, BW, BH);
      Dec(BX, S(8));
    end;
  RowLeft := Pad;
  if FExpandButton <> nil then
  begin
    FExpandButton.Caption := ExpandCaption;
    FExpandButton.SetBounds(RowLeft, FooterH,
      PPGMeasureTextNoCanvas(ExpandCaption, Font, 0, False).cx + S(32), BH);
  end;
  Inc(FooterH, BH + S(12));
  if FVerify <> nil then
  begin
    FVerify.SetBounds(Pad, FooterH - S(4), ColW + (X - Pad), S(24));
    Inc(FooterH, S(24));
  end;
  if (FExpandedLabel <> nil) and (FExpandedLabel.Parent = FFooter) then
  begin
    FExpandedLabel.Visible := FDialog.Expanded;
    if FExpandedLabel.Visible then
    begin
      H := TextHeight(FExpandedLabel, ColW + (X - Pad));
      FExpandedLabel.SetBounds(Pad, FooterH, ColW + (X - Pad), H);
      Inc(FooterH, H + S(8));
    end;
  end;
  if FFooterLabel <> nil then
  begin
    H := TextHeight(FFooterLabel, ColW + (X - Pad) - S(24));
    FFooterIcon.Visible := (FFooterIcon.Kind <> tdiNone) or
      ((FFooterIcon.Icon <> nil) and not FFooterIcon.Icon.Empty);
    FFooterIcon.SetBounds(Pad, FooterH + S(2), S(16), S(16));
    if FFooterIcon.Visible then
      FFooterLabel.SetBounds(Pad + S(24), FooterH, ColW + (X - Pad) - S(24), Max(H, S(16)))
    else
      FFooterLabel.SetBounds(Pad, FooterH, ColW + (X - Pad), H);
    Inc(FooterH, Max(H, S(16)) + S(12));
  end;
  FFooter.Height := FooterH;
  ClientWidth := X + ColW + Pad;
  ClientHeight := Y + FooterH;
end;

procedure TPPGDialogForm.SyncState;
var
  I: Integer;
  C: TControl;
  Item: TTaskDialogBaseButtonItem;
  NeedArrange: Boolean;
  PB: TTaskDialogProgressBar;
begin
  NeedArrange := False;
  // Buttons (Enabled aus der Collection)
  for I := 0 to FButtons.Count - 1 do
  begin
    C := TControl(FButtons[I]);
    Item := FDialog.Buttons.FindButton(C.Tag);
    if Item <> nil then
      C.Enabled := Item.Enabled;
  end;
  for I := 0 to FRadios.Count - 1 do
    if I < FDialog.RadioButtons.Count then
      TPPGRadioButton(FRadios[I]).Enabled := FDialog.RadioButtons[I].Enabled;
  // Fortschritt
  PB := FDialog.ProgressBar;
  if tfShowMarqueeProgressBar in FDialog.Flags then
    FProgress.Style := pbstMarquee
  else
    FProgress.Style := pbstNormal;
  FProgress.Min := PB.Min;
  FProgress.Max := Max(PB.Max, PB.Min + 1);
  FProgress.Position := EnsureRange(PB.Position, FProgress.Min, FProgress.Max);
  FProgress.State := PB.State;
  if (FDialog.Flags * [tfShowProgressBar, tfShowMarqueeProgressBar] <> []) <> FProgressFlags then
  begin
    FProgressFlags := not FProgressFlags;
    NeedArrange := True;
  end;
  // Texte
  if FDialog.Title <> FTitleText then
  begin
    FTitleText := FDialog.Title;
    FTitleLabel.Caption := FTitleText;
    NeedArrange := True;
  end;
  if FDialog.Text <> FBodyText then
  begin
    FBodyText := FDialog.Text;
    SetTextControl(FTextLabel, FBodyText);
    NeedArrange := True;
  end;
  if NeedArrange and HandleAllocated then
    Arrange;
end;

procedure TPPGDialogForm.CenterOnParent;
var
  PR, WA: TRect;
  M: TMonitor;
  P: TCustomForm;
  L, T: Integer;
begin
  P := PopupParent;
  if (P <> nil) and P.HandleAllocated and IsWindowVisible(P.Handle) and not IsIconic(P.Handle) then
  begin
    GetWindowRect(P.Handle, PR);
    M := Screen.MonitorFromWindow(P.Handle, mdNearest);
  end
  else
  begin
    M := Screen.MonitorFromPoint(Mouse.CursorPos, mdNearest);
    PR := M.WorkareaRect;
  end;
  WA := M.WorkareaRect;
  // Ohne tfPositionRelativeToWindow: mittig auf dem Monitor des Elternformulars
  if not (tfPositionRelativeToWindow in FDialog.Flags) and (P <> nil) then
    PR := WA;
  if (FDialog.FPosX >= 0) or (FDialog.FPosY >= 0) then
  begin
    L := Left;
    T := Top;
    if FDialog.FPosX >= 0 then
      L := FDialog.FPosX;
    if FDialog.FPosY >= 0 then
      T := FDialog.FPosY;
  end
  else
  begin
    L := (PR.Left + PR.Right - Width) div 2;
    T := (PR.Top + PR.Bottom - Height) div 2;
  end;
  L := EnsureRange(L, WA.Left, Max(WA.Left, WA.Right - Width));
  T := EnsureRange(T, WA.Top, Max(WA.Top, WA.Bottom - Height));
  SetBounds(L, T, Width, Height);
end;

procedure TPPGDialogForm.FormShow(Sender: TObject);
var
  Snd: Cardinal;
  Desc: string;
begin
  // Handle steht, die VCL hat ggf. fuer den Zielmonitor skaliert: neu ordnen
{$IFDEF PPG_HAS_PPI}
  FPPI := CurrentPPI;
{$ENDIF}
  Arrange;
  if not FCentered then
  begin
    CenterOnParent;
    FCentered := True;
  end;
  TPPGTheme.SetDarkTitleBar(Handle, TPPGTheme.IsDark and not PPGVclStyleActive and not IsHC);
  Desc := FDialog.Title;
  if FDialog.Text <> '' then
  begin
    if Desc <> '' then
      Desc := Desc + ' ';
    Desc := Desc + PPGStripMarkup(FDialog.Text);
  end;
  PPGAccSetWindowDescription(Handle, Desc);
  // Ton wie Windows
  Snd := $FFFFFFFF;
  if FDialog.FQuestionIcon then
    Snd := MB_ICONQUESTION
  else
    case FDialog.MainIcon of
      tdiWarning: Snd := MB_ICONEXCLAMATION;
      tdiError: Snd := MB_ICONHAND;
      tdiInformation: Snd := MB_ICONASTERISK;
    end;
  if Snd <> $FFFFFFFF then
    MessageBeep(Snd);
  if FTimer <> nil then
  begin
    FTimerStart := GetTickCount;
    FTimer.Enabled := True;
  end;
  FDialog.InternalCreated;
  if Assigned(FDialog.FOnFormShow) then
    FDialog.FOnFormShow(Self);
  if Assigned(PPGOnDialogShow) then
    PPGOnDialogShow(Self);
end;

procedure TPPGDialogForm.WMDlgClose(var Message: TMessage);
begin
  if FClosing then
    ModalResult := mrOk;
end;

procedure TPPGDialogForm.ButtonClick(Sender: TObject);
begin
  ClickButton(TControl(Sender).Tag);
end;

procedure TPPGDialogForm.ClickButton(AModalResult: TModalResult);
var
  CanClose: Boolean;
begin
  if FClosing then
    Exit;
  CanClose := True;
  FDialog.InternalButtonClicked(AModalResult, CanClose);
  if CanClose then
  begin
    FResult := AModalResult;
    FClosing := True;
    ModalResult := mrOk; // beendet ShowModal; das Ergebnis steht in FResult
    // Aus OnShow heraus setzt ShowModal ModalResult danach wieder auf 0:
    // zusaetzlich gepostet
    if HandleAllocated then
      PostMessage(Handle, WM_USER + $520, 0, 0);
  end
  else
    SyncState;
end;

function TPPGDialogForm.CanCancel: Boolean;
begin
  if FDialog.FEscResult <> 0 then
    Result := True
  else
    Result := (tfAllowDialogCancellation in FDialog.Flags) or (tcbCancel in FDialog.CommonButtons);
end;

procedure TPPGDialogForm.Cancel;
begin
  if not CanCancel then
    Exit;
  if FDialog.FEscResult <> 0 then
    ClickButton(FDialog.FEscResult)
  else
    ClickButton(mrCancel);
end;

procedure TPPGDialogForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FClosing then
    Exit;
  // Schliessen-Kreuz bzw. Alt+F4: wie Esc
  CanClose := False;
  if CanCancel then
    Cancel;
end;

procedure TPPGDialogForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE:
      begin
        Key := 0;
        Cancel;
      end;
    Ord('C'), VK_INSERT:
      if Shift = [ssCtrl] then
      begin
        // Wie Windows-Meldungen: ausser ein Eingabefeld hat Text markiert
        if (ActiveControl is TPPGCustomEdit) and (TPPGCustomEdit(ActiveControl).SelLength > 0) then
          Exit;
        Clipboard.AsText := CopyText;
        Key := 0;
      end;
    VK_F1:
      if FDialog.HelpContext <> 0 then
      begin
        Key := 0;
        Application.HelpContext(FDialog.HelpContext);
      end;
  end;
end;

procedure TPPGDialogForm.RadioClick(Sender: TObject);
var
  I: Integer;
begin
  I := TControl(Sender).Tag;
  if (I >= 0) and (I < FDialog.RadioButtons.Count) and TPPGRadioButton(Sender).Checked then
  begin
    FDialog.InternalRadioClicked(FDialog.RadioButtons[I]);
    SyncState;
  end;
end;

procedure TPPGDialogForm.VerifyClick(Sender: TObject);
begin
  FDialog.InternalVerificationClicked(FVerify.Checked);
  SyncState;
end;

procedure TPPGDialogForm.ExpandClick(Sender: TObject);
begin
  FDialog.InternalExpanded(not FDialog.Expanded, True);
  Arrange;
  SyncState;
end;

procedure TPPGDialogForm.LinkClick(Sender: TObject; const Link: string; LinkType: TSysLinkType);
begin
  FDialog.InternalHyperlink(Link);
  SyncState;
end;

procedure TPPGDialogForm.TimerTick(Sender: TObject);
var
  Reset: Boolean;
begin
  if FClosing then
    Exit;
  Reset := False;
  FDialog.InternalTimer(GetTickCount - FTimerStart, Reset);
  if Reset then
    FTimerStart := GetTickCount;
  if not FClosing then
    SyncState;
end;

function TPPGDialogForm.ButtonByResult(AModalResult: TModalResult): TControl;
var
  I: Integer;
begin
  for I := 0 to FButtons.Count - 1 do
    if TControl(FButtons[I]).Tag = AModalResult then
      Exit(TControl(FButtons[I]));
  Result := nil;
end;

function TPPGDialogForm.ButtonCount: Integer;
begin
  Result := FButtons.Count;
end;

function TPPGDialogForm.ButtonAt(Index: Integer): TControl;
begin
  Result := TControl(FButtons[Index]);
end;

function TPPGDialogForm.RadioCount: Integer;
begin
  Result := FRadios.Count;
end;

function TPPGDialogForm.Radio(Index: Integer): TPPGRadioButton;
begin
  Result := TPPGRadioButton(FRadios[Index]);
end;

function TPPGDialogForm.CopyText: string;
var
  SB: TStringBuilder;
  I: Integer;
  C: TControl;
  Btns: string;
begin
  // Format der Windows-Aufgabendialoge (Strg+C)
  SB := TStringBuilder.Create;
  try
    SB.Append('[Window Title]').Append(sLineBreak).Append(Caption).Append(sLineBreak);
    if FDialog.Title <> '' then
      SB.Append(sLineBreak).Append('[Main Instruction]').Append(sLineBreak)
        .Append(PPGStripMarkup(FDialog.Title)).Append(sLineBreak);
    if FDialog.Text <> '' then
      SB.Append(sLineBreak).Append('[Content]').Append(sLineBreak)
        .Append(PPGStripMarkup(FDialog.Text)).Append(sLineBreak);
    if FDialog.Expanded and (FDialog.ExpandedText <> '') then
      SB.Append(sLineBreak).Append('[Expanded Information]').Append(sLineBreak)
        .Append(PPGStripMarkup(FDialog.ExpandedText)).Append(sLineBreak);
    Btns := '';
    for I := 0 to FButtons.Count - 1 do
    begin
      C := TControl(FButtons[I]);
      if C is TPPGButton then
        Btns := Btns + '[' + StripHotkey(TPPGButton(C).Caption) + '] '
      else if C is TPPGCommandLink then
        Btns := Btns + '[' + StripHotkey(TPPGCommandLink(C).Caption) + '] ';
    end;
    if FVerify <> nil then
    begin
      SB.Append(sLineBreak);
      if FVerify.Checked then
        SB.Append('[x] ')
      else
        SB.Append('[ ] ');
      SB.Append(StripHotkey(FVerify.Caption)).Append(sLineBreak);
    end;
    SB.Append(sLineBreak).Append(TrimRight(Btns)).Append(sLineBreak);
    if FDialog.FooterText <> '' then
      SB.Append(sLineBreak).Append('[Footer]').Append(sLineBreak)
        .Append(PPGStripMarkup(FDialog.FooterText)).Append(sLineBreak);
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

{ TPPGTaskDialog }

constructor TPPGTaskDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPosX := -1;
  FPosY := -1;
end;

procedure TPPGTaskDialog.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FStyleManager then
      FStyleManager := nil
    else if AComponent = FContentControl then
      FContentControl := nil;
  end;
end;

procedure TPPGTaskDialog.SetStyleManager(const Value: TPPGStyleManager);
begin
  if FStyleManager = Value then
    Exit;
  if FStyleManager <> nil then
    FStyleManager.RemoveFreeNotification(Self);
  FStyleManager := Value;
  if FStyleManager <> nil then
    FStyleManager.FreeNotification(Self);
end;

procedure TPPGTaskDialog.SetContentControl(const Value: TControl);
begin
  if FContentControl = Value then
    Exit;
  if FContentControl <> nil then
    FContentControl.RemoveFreeNotification(Self);
  FContentControl := Value;
  if FContentControl <> nil then
    FContentControl.FreeNotification(Self);
end;

function TPPGTaskDialog.EffectivePreset: string;
begin
  Result := PPGHintPreset(FStyleManager, FPreset);
end;

procedure TPPGTaskDialog.NoOp(Sender: TObject);
begin
end;

procedure TPPGTaskDialog.InternalButtonClicked(AModalResult: TModalResult; var CanClose: Boolean);
begin
  Button := TTaskDialogButtonItem(Buttons.FindButton(AModalResult));
  if (FHelpResult <> 0) and (AModalResult = FHelpResult) then
  begin
    // Hilfe-Button (MessageDlg mbHelp): schliesst nicht
    CanClose := False;
    if HelpContext <> 0 then
      Application.HelpContext(HelpContext);
    Exit;
  end;
  if Assigned(FValidate) and (AModalResult = mrOk) then
  begin
    FValidate(Self);
    if ModalResult = mrNone then
    begin
      CanClose := False;
      Exit;
    end;
  end;
  DoOnButtonClicked(AModalResult, CanClose);
end;

procedure TPPGTaskDialog.InternalRadioClicked(Item: TTaskDialogBaseButtonItem);
var
  Old: TNotifyEvent;
begin
  // Der Vorfahr setzt RadioButton nur, wenn ein Ereignis zugewiesen ist
  Old := OnRadioButtonClicked;
  if not Assigned(Old) then
  begin
    OnRadioButtonClicked := NoOp;
    try
      DoOnRadioButtonClicked(Item.ModalResult);
    finally
      OnRadioButtonClicked := nil;
    end;
  end
  else if (FForm <> nil) and FForm.Visible then
    DoOnRadioButtonClicked(Item.ModalResult)
  else
  begin
    // Vorauswahl beim Aufbau: ohne Ereignis
    OnRadioButtonClicked := NoOp;
    try
      DoOnRadioButtonClicked(Item.ModalResult);
    finally
      OnRadioButtonClicked := Old;
    end;
  end;
end;

procedure TPPGTaskDialog.InternalVerificationClicked(Checked: Boolean);
begin
  if Checked then
    Flags := Flags + [tfVerificationFlagChecked]
  else
    Flags := Flags - [tfVerificationFlagChecked];
  DoOnVerificationClicked(Checked);
end;

procedure TPPGTaskDialog.InternalExpanded(AExpanded: Boolean; Notify: Boolean);
var
  Old: TNotifyEvent;
begin
  Old := OnExpanded;
  if not Notify or not Assigned(Old) then
  begin
    OnExpanded := NoOp;
    try
      DoOnExpandButtonClicked(AExpanded);
    finally
      OnExpanded := Old;
    end;
  end
  else
    DoOnExpandButtonClicked(AExpanded);
end;

procedure TPPGTaskDialog.InternalHyperlink(const Link: string);
begin
  DoOnHyperlinkClicked(Link);
end;

procedure TPPGTaskDialog.InternalTimer(TickCount: Cardinal; var Reset: Boolean);
begin
  DoOnTimer(TickCount, Reset);
end;

procedure TPPGTaskDialog.InternalCreated;
begin
  DoOnDialogCreated;
  DoOnDialogContructed;
end;

procedure TPPGTaskDialog.InternalDestroyed;
begin
  DoOnDialogDestroyed;
end;

function TPPGTaskDialog.DoExecute(ParentWnd: HWND): Boolean;
var
  F: TPPGDialogForm;
  CC: TControl;
begin
  PPGCheckMainThread(ClassName + '.Execute');
  // Ausgangszustand wie das Original
  Button := nil;
  InternalExpanded(tfExpandedByDefault in Flags, False);
  F := TPPGDialogForm.CreateFor(Self, ParentWnd);
  FForm := F;
  try
    F.ShowModal;
    ModalResult := F.FResult;
    Button := TTaskDialogButtonItem(Buttons.FindButton(ModalResult));
    Result := True;
  finally
    FForm := nil;
    if F.FTimer <> nil then
      F.FTimer.Enabled := False;
    // Eigenes Control zurueckgeben
    CC := FContentControl;
    if (CC <> nil) and (CC.Parent = F.FContent) then
    begin
      CC.Visible := F.FContentVisible;
      CC.Parent := F.FContentParent;
      CC.BoundsRect := F.FContentBounds;
    end;
    try
      InternalDestroyed;
    finally
      F.Free;
    end;
  end;
end;

{ Funktionen }

function MsgButtonCaption(B: TMsgDlgBtn): string;
begin
  case B of
    TMsgDlgBtn.mbYes: Result := PPGStr(@SPPGDlgYes);
    TMsgDlgBtn.mbNo: Result := PPGStr(@SPPGDlgNo);
    TMsgDlgBtn.mbOK: Result := PPGStr(@SPPGDlgOK);
    TMsgDlgBtn.mbCancel: Result := PPGStr(@SPPGDlgCancel);
    TMsgDlgBtn.mbAbort: Result := PPGStr(@SPPGDlgAbort);
    TMsgDlgBtn.mbRetry: Result := PPGStr(@SPPGDlgRetry);
    TMsgDlgBtn.mbIgnore: Result := PPGStr(@SPPGDlgIgnore);
    TMsgDlgBtn.mbAll: Result := PPGStr(@SPPGDlgAll);
    TMsgDlgBtn.mbNoToAll: Result := PPGStr(@SPPGDlgNoToAll);
    TMsgDlgBtn.mbYesToAll: Result := PPGStr(@SPPGDlgYesToAll);
    TMsgDlgBtn.mbHelp: Result := PPGStr(@SPPGDlgHelp);
  else
    Result := PPGStr(@SPPGDlgClose);
  end;
end;

function MsgButtonResult(B: TMsgDlgBtn): TModalResult;
begin
  case B of
    TMsgDlgBtn.mbYes: Result := mrYes;
    TMsgDlgBtn.mbNo: Result := mrNo;
    TMsgDlgBtn.mbOK: Result := mrOk;
    TMsgDlgBtn.mbCancel: Result := mrCancel;
    TMsgDlgBtn.mbAbort: Result := mrAbort;
    TMsgDlgBtn.mbRetry: Result := mrRetry;
    TMsgDlgBtn.mbIgnore: Result := mrIgnore;
    TMsgDlgBtn.mbAll: Result := mrAll;
    TMsgDlgBtn.mbNoToAll: Result := mrNoToAll;
    TMsgDlgBtn.mbYesToAll: Result := mrYesToAll;
    TMsgDlgBtn.mbHelp: Result := mrHelp;
  else
    Result := mrClose;
  end;
end;

function DoMessageDlg(const Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons;
  HelpCtx: Longint; DefaultButton: TMsgDlgBtn; HasDefault: Boolean; X, Y: Integer): Integer;
var
  D: TPPGTaskDialog;
  B: TMsgDlgBtn;
  Item: TTaskDialogButtonItem;
  Def: TMsgDlgBtn;
  CancelBtn: TMsgDlgBtn;
begin
  D := TPPGTaskDialog.Create(nil);
  try
    D.CommonButtons := [];
    D.Flags := [];
    D.HelpContext := HelpCtx;
    D.Text := Msg;
    D.FPosX := X;
    D.FPosY := Y;
    case DlgType of
      TMsgDlgType.mtWarning:
        begin
          D.MainIcon := tdiWarning;
          D.Caption := PPGStr(@SPPGDlgWarning);
        end;
      TMsgDlgType.mtError:
        begin
          D.MainIcon := tdiError;
          D.Caption := PPGStr(@SPPGDlgError);
        end;
      TMsgDlgType.mtInformation:
        begin
          D.MainIcon := tdiInformation;
          D.Caption := PPGStr(@SPPGDlgInformation);
        end;
      TMsgDlgType.mtConfirmation:
        begin
          D.MainIcon := tdiNone;
          D.FQuestionIcon := True;
          D.Caption := PPGStr(@SPPGDlgConfirm);
        end;
    else
      begin
        D.MainIcon := tdiNone;
        D.Caption := Application.Title;
      end;
    end;
    if Buttons = [] then
      Buttons := [TMsgDlgBtn.mbOK];
    // Standard und Abbrechen wie VCL-MessageDlg
    if HasDefault and (DefaultButton in Buttons) then
      Def := DefaultButton
    else if TMsgDlgBtn.mbOK in Buttons then
      Def := TMsgDlgBtn.mbOK
    else if TMsgDlgBtn.mbYes in Buttons then
      Def := TMsgDlgBtn.mbYes
    else
    begin
      Def := TMsgDlgBtn.mbRetry;
      for B := Low(TMsgDlgBtn) to High(TMsgDlgBtn) do
        if B in Buttons then
        begin
          Def := B;
          Break;
        end;
    end;
    if TMsgDlgBtn.mbCancel in Buttons then
      CancelBtn := TMsgDlgBtn.mbCancel
    else if TMsgDlgBtn.mbNo in Buttons then
      CancelBtn := TMsgDlgBtn.mbNo
    else
      CancelBtn := TMsgDlgBtn.mbOK;
    if CancelBtn in Buttons then
      D.FEscResult := MsgButtonResult(CancelBtn);
    for B := Low(TMsgDlgBtn) to High(TMsgDlgBtn) do
      if B in Buttons then
      begin
        Item := TTaskDialogButtonItem(D.Buttons.Add);
        Item.Caption := MsgButtonCaption(B);
        Item.ModalResult := MsgButtonResult(B);
        if B = Def then
          Item.Default := True;
        if B = TMsgDlgBtn.mbHelp then
          D.FHelpResult := mrHelp;
      end;
    D.Execute;
    Result := D.ModalResult;
  finally
    D.Free;
  end;
end;

function PPGMessageDlg(const Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons;
  HelpCtx: Longint): Integer;
begin
  Result := DoMessageDlg(Msg, DlgType, Buttons, HelpCtx, TMsgDlgBtn.mbOK, False, -1, -1);
end;

function PPGMessageDlg(const Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons;
  HelpCtx: Longint; DefaultButton: TMsgDlgBtn): Integer;
begin
  Result := DoMessageDlg(Msg, DlgType, Buttons, HelpCtx, DefaultButton, True, -1, -1);
end;

function PPGMessageDlgPos(const Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons;
  HelpCtx: Longint; X, Y: Integer): Integer;
begin
  Result := DoMessageDlg(Msg, DlgType, Buttons, HelpCtx, TMsgDlgBtn.mbOK, False, X, Y);
end;

procedure PPGShowMessage(const Msg: string);
begin
  DoMessageDlg(Msg, TMsgDlgType.mtCustom, [TMsgDlgBtn.mbOK], 0, TMsgDlgBtn.mbOK, False, -1, -1);
end;

type
  /// Felder und Pruefung eines Eingabedialogs.
  TInputHelper = class
    Panel: TPanel;
    Edits: array of TPPGEdit;
    Error: TPPGLabel;
    Validate: TPPGInputValidate;
    procedure DoValidate(Sender: TObject);
    procedure FormShow(Form: TPPGDialogForm);
  end;

procedure TInputHelper.DoValidate(Sender: TObject);
var
  V: TArray<string>;
  I, Field: Integer;
  Err: string;
  D: TPPGTaskDialog;
begin
  D := TPPGTaskDialog(Sender);
  D.ModalResult := mrOk;
  if not Assigned(Validate) then
    Exit;
  SetLength(V, Length(Edits));
  for I := 0 to High(Edits) do
    V[I] := Edits[I].Text;
  Err := '';
  Field := 0;
  if not Validate(V, Err, Field) then
  begin
    D.ModalResult := mrNone;
    Error.Caption := Err;
    Error.Visible := Err <> '';
    if (Field >= 0) and (Field <= High(Edits)) and Edits[Field].CanFocus then
      Edits[Field].SetFocus;
  end;
end;

procedure TInputHelper.FormShow(Form: TPPGDialogForm);
begin
  if (Length(Edits) > 0) and Edits[0].CanFocus then
    Form.ActiveControl := Edits[0];
end;

function PPGInputQuery(const ACaption: string; const APrompts: array of string;
  var AValues: array of string; const Validate: TPPGInputValidate): Boolean;
var
  D: TPPGTaskDialog;
  H: TInputHelper;
  I, Y, PPI, W: Integer;
  L: TPPGLabel;
  E: TPPGEdit;
  P: string;
begin
  PPGCheckMainThread('PPGInputQuery');
  if Length(APrompts) <> Length(AValues) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGInvalidArgument), [Length(AValues), 'AValues']);
  PPI := Screen.PixelsPerInch;
  W := MulDiv(320, PPI, 96);
  D := TPPGTaskDialog.Create(nil);
  H := TInputHelper.Create;
  try
    D.Caption := ACaption;
    D.MainIcon := tdiNone;
    D.CommonButtons := [tcbOk, tcbCancel];
    D.DefaultButton := tcbOk;
    D.Flags := [tfAllowDialogCancellation];
    H.Validate := Validate;
    H.Panel := TPanel.Create(nil);
    H.Panel.BevelOuter := bvNone;
    H.Panel.Caption := '';
    H.Panel.ParentBackground := True;
    H.Panel.ParentColor := True;
    H.Panel.Width := W;
    SetLength(H.Edits, Length(APrompts));
    Y := 0;
    for I := 0 to High(APrompts) do
    begin
      P := APrompts[I];
      L := TPPGLabel.Create(H.Panel);
      L.Parent := H.Panel;
      L.Transparent := True;
      E := TPPGEdit.Create(H.Panel);
      E.Parent := H.Panel;
      if (P <> '') and (P[1] = #31) then
      begin
        Delete(P, 1, 1);
        E.PasswordChar := #$25CF;
      end;
      L.Caption := P;
      L.FocusControl := E;
      L.SetBounds(0, Y, W, MulDiv(18, PPI, 96));
      Inc(Y, MulDiv(20, PPI, 96));
      E.SetBounds(0, Y, W, MulDiv(32, PPI, 96));
      E.Anchors := [akLeft, akTop, akRight];
      E.Text := AValues[I];
      Inc(Y, MulDiv(40, PPI, 96));
      H.Edits[I] := E;
    end;
    H.Error := TPPGLabel.Create(H.Panel);
    H.Error.Parent := H.Panel;
    H.Error.Transparent := True;
    H.Error.WordWrap := True;
    H.Error.Font.Color := PPGDefaultTokens(TPPGTheme.IsDark).Danger;
    H.Error.SetBounds(0, Y, W, MulDiv(36, PPI, 96));
    H.Error.Visible := False;
    Inc(Y, MulDiv(36, PPI, 96));
    H.Panel.Height := Y;
    D.ContentControl := H.Panel;
    D.FValidate := H.DoValidate;
    D.FOnFormShow := H.FormShow;
    D.Execute;
    Result := D.ModalResult = mrOk;
    if Result then
      for I := 0 to High(H.Edits) do
        AValues[I] := H.Edits[I].Text;
  finally
    D.Free;
    H.Panel.Free;
    H.Free;
  end;
end;

function PPGInputQuery(const ACaption, APrompt: string; var Value: string;
  const Validate: TPPGInputValidate): Boolean;
var
  Values: array[0..0] of string;
begin
  Values[0] := Value;
  Result := PPGInputQuery(ACaption, [APrompt], Values, Validate);
  if Result then
    Value := Values[0];
end;

function PPGInputBox(const ACaption, APrompt, ADefault: string): string;
begin
  Result := ADefault;
  PPGInputQuery(ACaption, APrompt, Result);
end;

end.
