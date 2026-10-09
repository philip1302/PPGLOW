unit PPG.PasswordEdit;

{ TPPGPasswordEdit - Kennwortfeld (Phase 12b, Vorbild WinUI PasswordBox).

  - Zeichen verdeckt (PasswordChar, Vorgabe Punkt U+25CF).
  - Auge im Feld: RevealMode rmPeek zeigt nur, solange es gedrueckt ist;
    rmToggle schaltet um; rmHidden ohne Auge. Revealed aus Code.
  - Hinweis bei aktiver Feststelltaste (Plakette im Feld, solange es den
    Fokus hat; CapsLockWarning).
  - Kein Kopieren und Ausschneiden, solange verdeckt (WM_COPY/WM_CUT werden
    abgefangen, auch Strg+C/Strg+Einfg). Nach dem Aufdecken wird der
    Rueckgaengig-Puffer des Edits geleert (EM_EMPTYUNDOBUFFER), damit dort kein
    Klartext liegt. Clear ueberschreibt den Text im Speicher.
  - Screenreader: Rolle Text mit STATE_SYSTEM_PROTECTED, kein Wert. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Field;

type
  TPPGRevealMode = (rmPeek, rmToggle, rmHidden);

  TPPGCustomPasswordEdit = class;

  /// Inneres Edit: blockiert Kopieren, solange verdeckt.
  TPPGPasswordInner = class(TPPGFieldEdit)
  private
    FField: TPPGCustomPasswordEdit;
    procedure WMCopy(var Message: TMessage); message WM_COPY;
    procedure WMCut(var Message: TMessage); message WM_CUT;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TPPGCustomPasswordEdit = class(TPPGCustomField)
  private
    FMaskChar: Char;
    FRevealed: Boolean;
    FRevealMode: TPPGRevealMode;
    FCapsLockWarning: Boolean;
    FCapsOn: Boolean;
    FOnRevealChange: TNotifyEvent;
    procedure SetMaskChar(const Value: Char);
    procedure SetRevealed(const Value: Boolean);
    procedure SetRevealMode(const Value: TPPGRevealMode);
    procedure SetCapsLockWarning(const Value: Boolean);
    procedure ApplyMask;
    procedure WMCapsCheck(var Message: TMessage); message WM_USER + $530;
  protected
    function CreateInner: TCustomEdit; override;
    procedure GetButtons(var Buttons: TPPGFieldButtons); override;
    function ButtonVisible(Id: Integer): Boolean; override;
    function ButtonEnabled(Id: Integer): Boolean; override;
    procedure ButtonDown(Id: Integer); override;
    procedure ButtonUp(Id: Integer); override;
    procedure ButtonClick(Id: Integer); override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure FocusChanged; override;
    /// Zustand der Feststelltaste (Tests ueberschreiben das).
    function IsCapsLockOn: Boolean; virtual;
    procedure CheckCapsLock;
    procedure DoPaintField(const ACanvas: IPPGCanvas; const Style: TPPGSurfaceStyle); override;
    function AccState: Integer; override;
    function AccDescription: string; override;
    function AccValue: string; override;
    /// Anwender deckt auf/zu (Auge): OnRevealChange.
    procedure UserReveal(Value: Boolean);

    property PasswordChar: Char read FMaskChar write SetMaskChar default #$25CF;
    property RevealMode: TPPGRevealMode read FRevealMode write SetRevealMode default rmPeek;
    property CapsLockWarning: Boolean read FCapsLockWarning write SetCapsLockWarning default True;
    property OnRevealChange: TNotifyEvent read FOnRevealChange write FOnRevealChange;
  public
    constructor Create(AOwner: TComponent); override;
    /// Ueberschreibt den Text im Speicher und leert das Feld.
    procedure Clear; override;
    /// True = Klartext sichtbar (aus Code ohne Ereignis).
    property Revealed: Boolean read FRevealed write SetRevealed;
    /// True, solange der Hinweis zur Feststelltaste sichtbar ist.
    function CapsLockHintVisible: Boolean;
  end;

  TPPGPasswordEdit = class(TPPGCustomPasswordEdit)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property PasswordChar;
    property RevealMode;
    property CapsLockWarning;
    property TextHint;
    property TextHintVisibleOnFocus;
    property ValidationState;
    property ValidationHint;
    property HighContrastSupport;
    property Align;
    property Anchors;
    property AutoSize default True;
    property BiDiMode;
    property BorderStyle;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
    property MaxLength;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property ReadOnlyStyle;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop;
    /// Nie in der DFM (Klartext).
    property Text stored False;
    property Visible;
    property Touch;
    property OnGesture;
    property OnChange;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnRevealChange;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseActivate;
    property OnContextPopup;
    property DragMode;
    property DragCursor;
    property OnDragDrop;
    property OnDragOver;
    property OnStartDrag;
    property OnEndDrag;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
    // Audit 5d Stufe 3: wie VCL
    property ShowClearButton;
  end;

const
  PPGPasswordButtonReveal = 20;
  PPGPasswordButtonCaps = 21;

implementation

uses
  System.Math, Winapi.oleacc, PPG.Appearance, PPG.Tokens, PPG.DpiUtils, PPG.Exceptions,
  PPG.Lang, PPG.Consts, PPG.ErrorHandler;

const
  WM_CAPSCHECK = WM_USER + $530;

type
  TEditAccess = class(TCustomEdit);

{ TPPGPasswordInner }

constructor TPPGPasswordInner.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if AOwner is TPPGCustomPasswordEdit then
    FField := TPPGCustomPasswordEdit(AOwner);
end;

procedure TPPGPasswordInner.WMCopy(var Message: TMessage);
begin
  if (FField <> nil) and not FField.Revealed then
    Message.Result := 0
  else
    inherited;
end;

procedure TPPGPasswordInner.WMCut(var Message: TMessage);
begin
  if (FField <> nil) and not FField.Revealed then
    Message.Result := 0
  else
    inherited;
end;

{ TPPGCustomPasswordEdit }

constructor TPPGCustomPasswordEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMaskChar := #$25CF;
  FRevealMode := rmPeek;
  FCapsLockWarning := True;
  ApplyMask;
end;

function TPPGCustomPasswordEdit.CreateInner: TCustomEdit;
begin
  Result := TPPGPasswordInner.Create(Self);
end;

procedure TPPGCustomPasswordEdit.ApplyMask;
var
  WasRevealed: Boolean;
begin
  WasRevealed := TEditAccess(Inner).PasswordChar = #0;
  if FRevealed then
    TEditAccess(Inner).PasswordChar := #0
  else
    TEditAccess(Inner).PasswordChar := FMaskChar;
  // Nach dem Aufdecken keinen Klartext im Rueckgaengig-Puffer lassen
  if WasRevealed and not FRevealed and Inner.HandleAllocated then
    SendMessage(Inner.Handle, EM_EMPTYUNDOBUFFER, 0, 0);
end;

procedure TPPGCustomPasswordEdit.SetMaskChar(const Value: Char);
begin
  if Value = #0 then
  begin
    // Beim DFM-Laden nicht werfen (Formular liesse sich nicht oeffnen):
    // protokollieren und das bisherige Zeichen behalten
    if PPGIsLoading(Self) then
    begin
      TPPGErrorHandler.LogWarning(Self, Format(PPGStr(@SPPGInvalidPropertyValue),
        ['#0', PPGDisplayName(Self), 'PasswordChar']));
      Exit;
    end;
    raise EPPGPropertyError.CreateInvalid(Self, 'PasswordChar', '#0');
  end;
  FMaskChar := Value;
  ApplyMask;
end;

procedure TPPGCustomPasswordEdit.SetRevealed(const Value: Boolean);
begin
  if FRevealed = Value then
    Exit;
  FRevealed := Value;
  ApplyMask;
  Invalidate;
end;

procedure TPPGCustomPasswordEdit.UserReveal(Value: Boolean);
begin
  if FRevealed = Value then
    Exit;
  SetRevealed(Value);
  if Assigned(FOnRevealChange) then
    FOnRevealChange(Self);
end;

procedure TPPGCustomPasswordEdit.SetRevealMode(const Value: TPPGRevealMode);
begin
  if FRevealMode = Value then
    Exit;
  FRevealMode := Value;
  if FRevealMode = rmHidden then
    SetRevealed(False);
  UpdateLayout;
  Invalidate;
end;

procedure TPPGCustomPasswordEdit.SetCapsLockWarning(const Value: Boolean);
begin
  FCapsLockWarning := Value;
  CheckCapsLock;
end;

procedure TPPGCustomPasswordEdit.Clear;
var
  S: string;
begin
  // Text im Speicher ueberschreiben, bevor er freigegeben wird
  S := Text;
  if S <> '' then
  begin
    UniqueString(S);
    FillChar(PChar(S)^, Length(S) * SizeOf(Char), 0);
  end;
  inherited Clear;
  if Inner.HandleAllocated then
    SendMessage(Inner.Handle, EM_EMPTYUNDOBUFFER, 0, 0);
end;

function TPPGCustomPasswordEdit.CapsLockHintVisible: Boolean;
begin
  Result := FCapsLockWarning and FCapsOn and FieldFocused;
end;

function TPPGCustomPasswordEdit.IsCapsLockOn: Boolean;
begin
  Result := (GetKeyState(VK_CAPITAL) and 1) <> 0;
end;

procedure TPPGCustomPasswordEdit.CheckCapsLock;
var
  On: Boolean;
begin
  On := IsCapsLockOn;
  if On <> FCapsOn then
  begin
    FCapsOn := On;
    UpdateLayout;
    Invalidate;
  end;
end;

procedure TPPGCustomPasswordEdit.WMCapsCheck(var Message: TMessage);
begin
  CheckCapsLock;
end;

procedure TPPGCustomPasswordEdit.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_CAPITAL then
  begin
    // Der Umschaltzustand steht erst nach der Taste fest
    if HandleAllocated then
      PostMessage(Handle, WM_CAPSCHECK, 0, 0);
    Exit;
  end;
  // Strg+C / Strg+Einfg: kein Kopieren, solange verdeckt (WM_COPY faengt den Rest)
  if not FRevealed and (ssCtrl in Shift) and ((Key = Ord('C')) or (Key = Ord('X')) or
    (Key = VK_INSERT)) then
    Key := 0;
end;

procedure TPPGCustomPasswordEdit.FocusChanged;
begin
  CheckCapsLock;
  if not FieldFocused and (FRevealMode = rmPeek) and FRevealed then
    UserReveal(False);
  UpdateLayout;
  inherited FocusChanged;
end;

{ ---- Buttons ---- }

procedure TPPGCustomPasswordEdit.GetButtons(var Buttons: TPPGFieldButtons);
var
  N: Integer;
begin
  inherited GetButtons(Buttons);
  N := Length(Buttons);
  SetLength(Buttons, N + 2);
  // Rechts von aussen nach innen: [Text][Feststelltaste][Auge]
  Buttons[N].Id := PPGPasswordButtonReveal;
  Buttons[N].Glyph := fgReveal;
  Buttons[N].ImageIndex := -1;
  Buttons[N].LeftSide := False;
  Buttons[N + 1].Id := PPGPasswordButtonCaps;
  Buttons[N + 1].Glyph := fgNone;
  Buttons[N + 1].ImageIndex := -1;
  Buttons[N + 1].LeftSide := False;
end;

function TPPGCustomPasswordEdit.ButtonVisible(Id: Integer): Boolean;
begin
  case Id of
    PPGPasswordButtonReveal: Result := (FRevealMode <> rmHidden) and not ReadOnly;
    PPGPasswordButtonCaps: Result := CapsLockHintVisible;
  else
    Result := inherited ButtonVisible(Id);
  end;
end;

function TPPGCustomPasswordEdit.ButtonEnabled(Id: Integer): Boolean;
begin
  if Id = PPGPasswordButtonCaps then
    Result := False // nur Anzeige
  else if Id = PPGPasswordButtonReveal then
    Result := Enabled and HasText
  else
    Result := inherited ButtonEnabled(Id);
end;

procedure TPPGCustomPasswordEdit.ButtonDown(Id: Integer);
begin
  if (Id = PPGPasswordButtonReveal) and (FRevealMode = rmPeek) then
    UserReveal(True)
  else
    inherited ButtonDown(Id);
end;

procedure TPPGCustomPasswordEdit.ButtonUp(Id: Integer);
begin
  if (Id = PPGPasswordButtonReveal) and (FRevealMode = rmPeek) then
    UserReveal(False)
  else
    inherited ButtonUp(Id);
end;

procedure TPPGCustomPasswordEdit.ButtonClick(Id: Integer);
begin
  if (Id = PPGPasswordButtonReveal) and (FRevealMode = rmToggle) then
    UserReveal(not FRevealed)
  else
    inherited ButtonClick(Id);
end;

procedure TPPGCustomPasswordEdit.DoPaintField(const ACanvas: IPPGCanvas;
  const Style: TPPGSurfaceStyle);
var
  R: TRect;
  PPI: Integer;
  T: TPPGTokens;
  Fill, Txt: TColor;
begin
  inherited DoPaintField(ACanvas, Style);
  if not CapsLockHintVisible then
    Exit;
  // Plakette "Feststelltaste" (Pfeil nach oben mit Strich)
  R := ButtonRect(PPGPasswordButtonCaps);
  if IsRectEmpty(R) then
    Exit;
  PPI := ScalePPI;
  T := Tokens;
  InflateRect(R, -PPGScale(3, PPI), -PPGScale(5, PPI));
  // Hochkontrast: Warning = clHighlight, Text darauf clHighlightText
  Fill := T.Warning;
  if UseHighContrast then
    Txt := T.OnAccent
  else
    Txt := PPGContrastTextColor(Fill);
  ACanvas.FillRoundRect(R, PPGScale(3, PPI), Fill, 255);
  ACanvas.DrawText(R, #$21EA, Font, Txt, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
end;

function TPPGCustomPasswordEdit.AccState: Integer;
begin
  Result := inherited AccState or STATE_SYSTEM_PROTECTED;
end;

function TPPGCustomPasswordEdit.AccDescription: string;
begin
  Result := inherited AccDescription;
  if CapsLockHintVisible then
  begin
    if Result <> '' then
      Result := Result + '. ';
    Result := Result + PPGStr(@SPPGCapsLockOn);
  end;
end;

function TPPGCustomPasswordEdit.AccValue: string;
begin
  // Nie den Klartext an Screenreader geben
  Result := '';
end;

end.
