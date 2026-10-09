unit PPG.Controls.Field;

{ TPPGCustomField - gemeinsame Basis der Eingabefelder (Edit, Memo, SpinEdit).

  Grundsatz: Die Texteingabe ist ein NATIVES Edit bzw. Memo ohne Rahmen
  ("Inner"). PPGlow zeichnet nur den Rahmen aussen herum, Buttons im Feld und
  den TextHint. IME, Undo, Kontextmenue, Zwischenablage und Screenreader
  funktionieren dadurch wie bei TEdit.

  - Fokus: Das Feld selbst ist kein Tabstopp. SetFocus und WM_SETFOCUS geben
    den Fokus an das innere Edit weiter. OnEnter/OnExit des Felds kommen von
    der VCL (CM_ENTER/CM_EXIT laufen ueber alle Eltern).
  - TabStop des Felds ist TabStop des inneren Edits.
  - Ereignisse des inneren Edits (Tasten, Maus, OnChange) kommen an den
    Ereignissen des Felds an; Mauskoordinaten in Feld-Koordinaten.
  - Hover gilt fuer Rahmen UND inneres Edit; der Fokus wird als Akzentlinie
    (ModernFlat) bzw. Rahmen (Classic) animiert eingeblendet.
  - Farben: Feld und inneres Edit haben dieselbe Flaechenfarbe (Color bzw.
    VCL-Style bzw. Hochkontrast). Mit VCL-Style faerbt der Style-Hook der VCL
    das innere Edit in denselben Style-Farben.
  - TextHint zeichnet das Feld selbst nach dem WM_PAINT des inneren Edits:
    EM_SETCUEBANNER braucht aktive Themes, und Memos kennen ihn nicht.
  - Barrierefreiheit: Das innere Edit bleibt das fokussierte Element. Seinen
    Namen (Label mit FocusControl, sonst TextHint, sonst Hint) setzt das Feld
    per IAccPropServices.

  Erweiterung (Phase 12a):
  - IPPGFieldInner: jedes innere Edit (auch fremde Nachfahren wie ein
    TCustomMaskEdit) bekommt Textfarbe und dunkle Scrollleisten ueber diese
    Schnittstelle; die Farblogik selbst steht nur in PPGFieldCtlColor (DRY).
  - IPPGFieldValue: Felder mit typisiertem Wert (Zahl, Farbe, Auswahl) bieten
    IsNull, Clear und den Wert als Variant an. DB-Felder und Grid-Editoren
    binden sich nur an diese Schnittstelle.
  - SetTextSilent: Text aus Code ohne OnChange (Anzeige- und
    Bearbeitungsformat, Werte aus Code; Suite-Regel). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.Forms, Vcl.Menus,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Controls.Base, PPG.ElementStyle;

type
  /// Validierungszustand eines Felds (faerbt Rahmen und Fokuslinie).
  TPPGValidationState = (pvsNone, pvsValid, pvsWarning, pvsError);

  /// Inneres Edit eines Felds: Farben setzt das Feld (Phase 12a).
  IPPGFieldInner = interface
    ['{6B1F3C2A-8D47-4E95-A2C1-7F0D9E4B3A68}']
    /// clNone = Font.Color des inneren Edits.
    procedure SetFieldTextColor(Color: TColor);
    procedure SetFieldDarkScrollBars(Value: Boolean);
  end;

  /// Feld mit typisiertem Wert (Phase 12a). Unassigned/Null = kein Wert.
  IPPGFieldValue = interface
    ['{C4A85E19-3F62-4B07-9D1E-52A8B6F0C743}']
    function FieldIsNull: Boolean;
    procedure FieldClear;
    function GetFieldValue: Variant;
    /// Aus Code: ohne OnChange.
    procedure SetFieldValue(const Value: Variant);
  end;

  /// Natives einzeiliges Edit im Inneren eines Felds (ohne Rahmen).
  TPPGFieldEdit = class(TCustomEdit, IPPGFieldInner)
  private
    FTextColor: TColor;
    procedure SetTextColor(const Value: TColor);
    { IPPGFieldInner }
    procedure SetFieldTextColor(Color: TColor);
    procedure SetFieldDarkScrollBars(Value: Boolean);
    procedure CNCtlColorEdit(var Message: TWMCtlColorEdit); message CN_CTLCOLOREDIT;
    procedure CNCtlColorStatic(var Message: TWMCtlColorStatic); message CN_CTLCOLORSTATIC;
  public
    constructor Create(AOwner: TComponent); override;
    /// Textfarbe statt Font.Color (clNone = Font.Color). Das Feld setzt sie
    /// (z.B. hell im Dark Mode), ohne die gespeicherte Schrift zu aendern.
    property TextColor: TColor read FTextColor write SetTextColor;
  end;

  /// Natives Memo im Inneren eines Felds (ohne Rahmen).
  TPPGFieldMemo = class(TCustomMemo, IPPGFieldInner)
  private
    FTextColor: TColor;
    FDarkScrollBars: Boolean;
    procedure SetTextColor(const Value: TColor);
    { IPPGFieldInner }
    procedure SetFieldTextColor(Color: TColor);
    procedure SetFieldDarkScrollBars(Value: Boolean);
    procedure SetDarkScrollBars(const Value: Boolean);
    procedure ApplyScrollTheme;
    procedure CNCtlColorEdit(var Message: TWMCtlColorEdit); message CN_CTLCOLOREDIT;
    procedure CNCtlColorStatic(var Message: TWMCtlColorStatic); message CN_CTLCOLORSTATIC;
  protected
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    property TextColor: TColor read FTextColor write SetTextColor;
    /// Native Scrollleisten im dunklen Windows-Design ("DarkMode_Explorer").
    property DarkScrollBars: Boolean read FDarkScrollBars write SetDarkScrollBars;
  end;

  /// Button innerhalb des Felds. Rect berechnet das Feld beim Layout.
  TPPGFieldButton = record
    Id: Integer;
    Glyph: TPPGFieldGlyph;
    ImageIndex: Integer;   // >= 0: Bild aus Images statt Symbol
    LeftSide: Boolean;
    Rect: TRect;
  end;
  TPPGFieldButtons = array of TPPGFieldButton;

  TPPGCustomField = class(TPPGCustomControl)
  private
    FInner: TCustomEdit;
    FInnerOldProc: TWndMethod;
    FInnerHot: Boolean;
    FHasText: Boolean;
    FFocusAnim: TPPGAnimation;
    FTextHint: string;
    FRequiredMark: Boolean;
    FTextHintVisibleOnFocus: Boolean;
    FValidationState: TPPGValidationState;
    FValidationHint: string;
    FShowClearButton: Boolean;
    FBorderStyle: TBorderStyle;
    FButtons: TPPGFieldButtons;
    FHotButton: Integer;
    FPressedButton: Integer;
    FHintColor: TColor;
    FTabStop: Boolean;
    FEditMenu: TPopupMenu;
    FUseSystemContextMenu: Boolean;
    FChangeLock: Integer;
    FOnChange: TNotifyEvent;
    FReadOnlyStyle: TPPGElementStyle;
    procedure SetReadOnlyStyle(const Value: TPPGElementStyle);
    procedure ReadOnlyStyleChanged(Sender: TObject);
    function UseReadOnlyColors: Boolean;
    procedure EditMenuClick(Sender: TObject);
    procedure ShowEditMenu(X, Y: Integer);
    procedure InnerWndProc(var Message: TMessage);
    procedure InnerChange(Sender: TObject);
    procedure InnerClick(Sender: TObject);
    procedure InnerDblClick(Sender: TObject);
    procedure InnerKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure InnerKeyPress(Sender: TObject; var Key: Char);
    procedure InnerKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure InnerMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure InnerMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure InnerMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure InnerMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint; var Handled: Boolean);
    procedure FocusAnimStep(Sender: TObject);
    procedure PaintTextHint(DC: HDC);
    procedure UpdateInnerHint;
    function GetText: string;
    procedure SetText(const Value: string);
    function GetTabStop: Boolean;
    procedure SetTabStop(const Value: Boolean);
    function GetMaxLength: Integer;
    procedure SetMaxLength(const Value: Integer);
    function GetReadOnly: Boolean;
    procedure SetReadOnly(const Value: Boolean);
    function GetCharCase: TEditCharCase;
    procedure SetCharCase(const Value: TEditCharCase);
    function GetHideSelection: Boolean;
    procedure SetHideSelection(const Value: Boolean);
    function GetAlignment: TAlignment;
    procedure SetAlignment(const Value: TAlignment);
    function GetModified: Boolean;
    procedure SetModified(const Value: Boolean);
    function GetSelStart: Integer;
    procedure SetSelStart(const Value: Integer);
    function GetSelLength: Integer;
    procedure SetSelLength(const Value: Integer);
    function GetSelText: string;
    procedure SetSelText(const Value: string);
    procedure SetTextHint(const Value: string);
    procedure SetTextHintVisibleOnFocus(const Value: Boolean);
    procedure SetValidationState(const Value: TPPGValidationState);
    procedure SetValidationHint(const Value: string);
    procedure SetShowClearButton(const Value: Boolean);
    procedure SetBorderStyle(const Value: TBorderStyle);
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMColorChanged(var Message: TMessage); message CM_COLORCHANGED;
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
    procedure CMSysColorChange(var Message: TMessage); message CM_SYSCOLORCHANGE;
    procedure CMBiDiModeChanged(var Message: TMessage); message CM_BIDIMODECHANGED;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
    procedure WMLButtonUp(var Message: TWMLButtonUp); message WM_LBUTTONUP;
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
    procedure CMWantSpecialKey(var Message: TCMWantSpecialKey); message CM_WANTSPECIALKEY;
  protected
    /// Erzeugt das innere Edit (Memo: TPPGFieldMemo).
    function CreateInner: TCustomEdit; virtual;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure AppearanceUpdated; override;
    function GetBackgroundColor: TColor; override;
    function CalcAutoSize(out AWidth, AHeight: Integer): Boolean; override;
    function IsHot: Boolean; override;
    /// Felder folgen mit AutoSize nur in der Hoehe (wie TEdit).
    function AutoSizeWidth: Boolean; override;
    function IsDown: Boolean; override;
    procedure UpdateVisualState(Animate: Boolean = True); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    /// Zusaetzlicher Inhalt nach Rahmen und Buttons (z.B. Text einer DropDownList).
    procedure DoPaintField(const ACanvas: IPPGCanvas; const Style: TPPGSurfaceStyle); virtual;

    { Barrierefreiheit }
    function AccName: string; override;
    function AccRole: Integer; override;
    function AccState: Integer; override;
    function AccDescription: string; override;
    function AccKeyboardShortcut: string; override;
    function AccDefaultAction: string; override;
    procedure AccDoDefaultAction; override;

    { Verhalten fuer abgeleitete Felder }
    /// OnChange (nicht beim Laden).
    procedure Change; virtual;
    /// Tasten nach dem OnKeyDown des Anwenders (Key <> 0), z.B. Pfeiltasten im SpinEdit.
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); virtual;
    /// Zeichen nach dem OnKeyPress des Anwenders (Key <> #0), z.B. Ziffernfilter.
    procedure FieldKeyPress(var Key: Char); virtual;
    /// Fokus des Felds (inneres Edit) hat sich geaendert.
    procedure FocusChanged; virtual;
    /// Buttons des Felds; rechte Buttons von aussen nach innen, linke ebenso.
    procedure GetButtons(var Buttons: TPPGFieldButtons); virtual;
    function ButtonVisible(Id: Integer): Boolean; virtual;
    function ButtonEnabled(Id: Integer): Boolean; virtual;
    /// Linke Maustaste auf einem Button gedrueckt bzw. losgelassen.
    procedure ButtonDown(Id: Integer); virtual;
    procedure ButtonUp(Id: Integer); virtual;
    /// Klick (Druecken und Loslassen ueber demselben Button).
    procedure ButtonClick(Id: Integer); virtual;
    /// Index des Buttons unter dem Punkt (nur sichtbare und aktive), sonst -1.
    function ButtonAt(X, Y: Integer): Integer;
    function ButtonRect(Id: Integer): TRect;
    /// Bricht einen gedrueckten Button ab (ohne Klick), z.B. wenn ein Popup
    /// die Maus uebernommen hat.
    procedure CancelButtonPress;
    /// Inneres Edit ein-/ausblenden. Ohne sichtbares Edit ist das Feld selbst
    /// Tabstopp und Fokusziel (z.B. ComboBox csDropDownList).
    procedure SetInnerVisible(Value: Boolean);
    function InnerVisible: Boolean;
    /// True = Taste (Enter, Esc, ...) gehoert dem Feld, nicht dem Formular
    /// (Default-/Cancel-Button). Gilt fuer Feld und inneres Edit.
    function WantSpecialKey(Key: Word): Boolean; virtual;
    /// Text aus Code ohne OnChange (z.B. Wechsel zwischen Anzeige- und
    /// Bearbeitungsformat, Value aus Code).
    procedure SetTextSilent(const Value: string);
    /// True waehrend SetTextSilent.
    function ChangeLocked: Boolean;
    /// Berechnet Button-Rechtecke und die Lage des inneren Edits neu.
    procedure UpdateLayout;
    /// Lage des inneren Edits anpassen (R = Textbereich neben den Buttons),
    /// z.B. hinter Chips (TagEdit).
    procedure AdjustInnerBounds(var R: TRect); virtual;
    /// Farben des Felds und des inneren Edits neu setzen.
    procedure UpdateColors;
    /// Flaechen- und Textfarbe des Felds (Hochkontrast > VCL-Style > Color).
    procedure GetFieldColors(out Fill, Text: TColor); virtual;
    function GetFieldStyle: TPPGSurfaceStyle; virtual;
    function FieldRenderer: IPPGFieldRenderer;
    /// True, wenn das innere Edit (bzw. das Feld selbst) den Fokus hat.
    function FieldFocused: Boolean;
    function FocusProgress: Single;
    function IsMultiLine: Boolean;
    function TextHintShowing: Boolean;
    /// Angezeigter Platzhalter: TextHint, mit RequiredMark ein Sternchen dazu.
    function DisplayTextHint: string;
    procedure SetRequiredMark(const Value: Boolean);
    /// Hoehe einer Textzeile in der aktuellen Schrift.
    function LineHeight: Integer;
    procedure InvalidateInner;

    property Inner: TCustomEdit read FInner;
    /// Pflichtfeld kennzeichnen: Sternchen im Platzhalter (DB-Felder: ShowRequired).
    property RequiredMark: Boolean read FRequiredMark write SetRequiredMark;
    property HasText: Boolean read FHasText;
    property HotButton: Integer read FHotButton;
    property PressedButton: Integer read FPressedButton;
    /// Farbe des TextHint (aus Feld- und Textfarbe gemischt).
    property HintColor: TColor read FHintColor;

    { In den Endklassen published }
    property Alignment: TAlignment read GetAlignment write SetAlignment default taLeftJustify;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
    property CharCase: TEditCharCase read GetCharCase write SetCharCase default ecNormal;
    property HideSelection: Boolean read GetHideSelection write SetHideSelection default True;
    property MaxLength: Integer read GetMaxLength write SetMaxLength default 0;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    /// Optik bei ReadOnly (Flaeche, Text, Rand; clDefault = wie bearbeitbar).
    property ReadOnlyStyle: TPPGElementStyle read FReadOnlyStyle write SetReadOnlyStyle;
    property ShowClearButton: Boolean read FShowClearButton write SetShowClearButton default False;
    property TabStop: Boolean read GetTabStop write SetTabStop default True;
    /// True = natives Windows-Kontextmenue des Edits statt des Suite-Menues.
    property UseSystemContextMenu: Boolean read FUseSystemContextMenu
      write FUseSystemContextMenu default False;
    property TextHint: string read FTextHint write SetTextHint;
    property TextHintVisibleOnFocus: Boolean read FTextHintVisibleOnFocus
      write SetTextHintVisibleOnFocus default False;
    property ValidationState: TPPGValidationState read FValidationState
      write SetValidationState default pvsNone;
    /// Hinweistext zum Validierungszustand (Tooltip und Screenreader).
    property ValidationHint: string read FValidationHint write SetValidationHint;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetFocus; override;
    /// Das innere Edit gehoert dem Feld und wird nie gespeichert.
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    function Focused: Boolean; override;
    procedure Clear; virtual;
    procedure SelectAll;
    procedure ClearSelection;
    procedure CopyToClipboard;
    procedure CutToClipboard;
    procedure PasteFromClipboard;
    procedure Undo;
    function CanUndo: Boolean;
    /// Kontextmenue der Bearbeitung mit aktuellem Zustand (ohne es zu zeigen).
    function BuildEditMenu: TPopupMenu;
    property Modified: Boolean read GetModified write SetModified;
    property SelStart: Integer read GetSelStart write SetSelStart;
    property SelLength: Integer read GetSelLength write SetSelLength;
    property SelText: string read GetSelText write SetSelText;
    property Text: string read GetText write SetText;
  end;

/// Textfarbe eines inneren Edits in CN_CTLCOLOREDIT/STATIC (clNone = keine).
procedure PPGFieldCtlColor(DC: HDC; Color: TColor);

const
  /// Button-Id des Loesch-Buttons (ShowClearButton).
  PPGFieldButtonClear = 1;

implementation

uses
  System.SysUtils, System.Math, Winapi.oleacc, Winapi.UxTheme, Vcl.Themes, PPG.Tokens,
  PPG.Appearance, PPG.DpiUtils, PPG.VclStyles, PPG.Accessibility,
  PPG.Render.Registry, PPG.Render.Gdi, PPG.Lang, PPG.Consts, PPG.Menus;

type
  TEditAccess = class(TCustomEdit);
  TLabelAccess = class(TCustomLabel);
  TControlAccess = class(TControl);

function Ed(C: TCustomEdit): TEditAccess; inline;
begin
  Result := TEditAccess(C);
end;

const
  FieldPadY = 3;    // logische px zwischen Rahmen und Text (oben/unten)
  FieldPadX = 4;    // logische px zwischen Rahmen und Text (links/rechts)
  ButtonGap = 2;    // logische px zwischen Buttons und zum Rahmen
  MaxButtonWidth = 26;

{ TPPGFieldEdit / TPPGFieldMemo }

procedure PPGFieldCtlColor(DC: HDC; Color: TColor);
begin
  if Color <> clNone then
    Winapi.Windows.SetTextColor(DC, ColorToRGB(Color));
end;

constructor TPPGFieldEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTextColor := clNone;
end;

procedure TPPGFieldEdit.SetTextColor(const Value: TColor);
begin
  if FTextColor <> Value then
  begin
    FTextColor := Value;
    if HandleAllocated then
      Invalidate;
  end;
end;

procedure TPPGFieldEdit.SetFieldTextColor(Color: TColor);
begin
  SetTextColor(Color);
end;

procedure TPPGFieldEdit.SetFieldDarkScrollBars(Value: Boolean);
begin
  // einzeilig: keine Scrollleisten
end;

procedure TPPGFieldEdit.CNCtlColorEdit(var Message: TWMCtlColorEdit);
begin
  inherited;
  PPGFieldCtlColor(Message.ChildDC, FTextColor);
end;

procedure TPPGFieldEdit.CNCtlColorStatic(var Message: TWMCtlColorStatic);
begin
  inherited;
  PPGFieldCtlColor(Message.ChildDC, FTextColor);
end;

constructor TPPGFieldMemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTextColor := clNone;
end;

procedure TPPGFieldMemo.SetTextColor(const Value: TColor);
begin
  if FTextColor <> Value then
  begin
    FTextColor := Value;
    if HandleAllocated then
      Invalidate;
  end;
end;

procedure TPPGFieldMemo.SetDarkScrollBars(const Value: Boolean);
begin
  if FDarkScrollBars <> Value then
  begin
    FDarkScrollBars := Value;
    ApplyScrollTheme;
  end;
end;

procedure TPPGFieldMemo.SetFieldTextColor(Color: TColor);
begin
  SetTextColor(Color);
end;

procedure TPPGFieldMemo.SetFieldDarkScrollBars(Value: Boolean);
begin
  SetDarkScrollBars(Value);
end;

procedure TPPGFieldMemo.ApplyScrollTheme;
begin
  if not HandleAllocated then
    Exit;
  // Rein kosmetisch: auf Windows-Versionen ohne dunkles Design bleibt die
  // Scrollleiste hell (Rueckgabewert bewusst nicht ausgewertet)
  if FDarkScrollBars then
    SetWindowTheme(Handle, 'DarkMode_Explorer', nil)
  else
    SetWindowTheme(Handle, nil, nil);
  SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or
    SWP_NOACTIVATE or SWP_FRAMECHANGED);
end;

procedure TPPGFieldMemo.CreateWnd;
begin
  inherited CreateWnd;
  if FDarkScrollBars then
    ApplyScrollTheme;
end;

procedure TPPGFieldMemo.CNCtlColorEdit(var Message: TWMCtlColorEdit);
begin
  inherited;
  PPGFieldCtlColor(Message.ChildDC, FTextColor);
end;

procedure TPPGFieldMemo.CNCtlColorStatic(var Message: TWMCtlColorStatic);
begin
  inherited;
  PPGFieldCtlColor(Message.ChildDC, FTextColor);
end;

{ TPPGCustomField }

constructor TPPGCustomField.Create(AOwner: TComponent);
var
  E: TEditAccess;
begin
  inherited Create(AOwner);
  FReadOnlyStyle := TPPGElementStyle.Create(Self);
  FReadOnlyStyle.OnChange := ReadOnlyStyleChanged;
  // Keine Caption (Text gehoert dem inneren Edit), keine Kinder im Designer
  ControlStyle := ControlStyle - [csSetCaption, csAcceptsControls];
  TWinControl(Self).TabStop := False;
  FHotButton := -1;
  FPressedButton := -1;
  FBorderStyle := bsSingle;
  FTabStop := True;
  ParentColor := False;
  Color := clWindow;
  Width := 121;
  Height := 25;

  FFocusAnim := TPPGAnimation.Create(Self);
  FFocusAnim.OnStep := FocusAnimStep;

  FInner := CreateInner;
  E := TEditAccess(FInner);
  E.Parent := Self;
  E.BorderStyle := bsNone;
  E.AutoSize := False;
  E.ParentColor := False;
  E.ParentFont := True;
  E.ParentShowHint := True;
  // Audit 5d: DoubleBuffered des Felds nicht an das TEdit weitergeben
  // (doppelt gepuffertes TEdit zeichnet unter Themes fehlerhaft)
  E.ParentDoubleBuffered := False;
  E.TabStop := True;
  FInnerOldProc := E.WindowProc;
  E.WindowProc := InnerWndProc;
  E.OnChange := InnerChange;
  E.OnClick := InnerClick;
  E.OnDblClick := InnerDblClick;
  E.OnKeyDown := InnerKeyDown;
  E.OnKeyPress := InnerKeyPress;
  E.OnKeyUp := InnerKeyUp;
  E.OnMouseDown := InnerMouseDown;
  E.OnMouseMove := InnerMouseMove;
  E.OnMouseUp := InnerMouseUp;
  E.OnMouseWheel := InnerMouseWheel;

  AutoSize := True;
  UpdateColors;
  UpdateLayout;
end;

destructor TPPGCustomField.Destroy;
var
  E: TEditAccess;
begin
  // Zuerst das innere Edit abkoppeln: seine Nachrichten duerfen nicht mehr
  // in ein halb zerstoertes Feld laufen (nil-sicher, s. Coding-Rules).
  if FInner <> nil then
  begin
    E := TEditAccess(FInner);
    if Assigned(FInnerOldProc) then
      E.WindowProc := FInnerOldProc;
    E.OnChange := nil;
    E.OnClick := nil;
    E.OnDblClick := nil;
    E.OnKeyDown := nil;
    E.OnKeyPress := nil;
    E.OnKeyUp := nil;
    E.OnMouseDown := nil;
    E.OnMouseMove := nil;
    E.OnMouseUp := nil;
    E.OnMouseWheel := nil;
    if E.HandleAllocated then
      PPGAccSetWindowName(E.Handle, '');
    FreeAndNil(FInner);
  end;
  FreeAndNil(FEditMenu);
  FreeAndNil(FReadOnlyStyle);
  if FFocusAnim <> nil then
    FFocusAnim.OnStep := nil;
  FreeAndNil(FFocusAnim);
  inherited Destroy;
end;

function TPPGCustomField.CreateInner: TCustomEdit;
begin
  Result := TPPGFieldEdit.Create(Self);
end;

procedure TPPGCustomField.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Rahmen nie ueber das innere Edit malen
  Params.Style := Params.Style or WS_CLIPCHILDREN;
end;

procedure TPPGCustomField.Loaded;
begin
  inherited Loaded;
  FHasText := Ed(FInner).GetTextLen > 0;
  UpdateColors;
  UpdateLayout;
end;

procedure TPPGCustomField.Resize;
begin
  inherited Resize;
  UpdateLayout;
end;

procedure TPPGCustomField.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  I: Integer;
  C: TControl;
begin
  // Wie TWinControl, aber ohne das innere Edit (sonst landet es in der DFM,
  // wenn das Feld selbst Root ist, z.B. beim Kopieren im Designer)
  for I := 0 to ControlCount - 1 do
  begin
    C := Controls[I];
    if (C <> FInner) and (C.Owner = Root) then
      Proc(C);
  end;
end;

procedure TPPGCustomField.AppearanceUpdated;
begin
  inherited AppearanceUpdated;
  UpdateColors;
  UpdateLayout; // Rahmenbreite/Rundung bestimmen den Innenbereich
end;

function TPPGCustomField.GetBackgroundColor: TColor;
begin
  // Die Ecken ausserhalb der Rundung gehoeren dem Parent, nicht der
  // (Feld-)Farbe Color
  if Parent <> nil then
    Result := TControlAccess(Parent).Color
  else
    Result := Color;
end;

{ ---- Inneres Edit ---- }

procedure TPPGCustomField.InnerWndProc(var Message: TMessage);
begin
  case Message.Msg of
    CM_MOUSEENTER:
      if Message.LParam = 0 then
      begin
        FInnerHot := True;
        UpdateVisualState;
      end;
    CM_MOUSELEAVE:
      if Message.LParam = 0 then
      begin
        FInnerHot := False;
        UpdateVisualState;
      end;
    WM_SETFOCUS:
      // Name VOR der Fokusmeldung setzen, damit der Screenreader ihn vorliest
      PPGAccSetWindowName(Ed(FInner).Handle, AccName);
    WM_CONTEXTMENU:
      if (PopupMenu <> nil) and PopupMenu.AutoPopup then
      begin
        // PopupMenu des Felds statt des nativen Edit-Menues
        Message.Result := Perform(WM_CONTEXTMENU, Message.WParam, Message.LParam);
        if Message.Result <> 0 then
          Exit;
      end
      else if not FUseSystemContextMenu and not (csDesigning in ComponentState) then
      begin
        // Bearbeiten-Menue im Stil der Suite statt des nativen Edit-Menues
        ShowEditMenu(SmallInt(LoWord(Message.LParam)), SmallInt(HiWord(Message.LParam)));
        Message.Result := 1;
        Exit;
      end;
    CM_WANTSPECIALKEY:
      if WantSpecialKey(TCMWantSpecialKey(Message).CharCode) then
      begin
        Message.Result := 1;
        Exit;
      end;
    WM_DESTROY:
      PPGAccSetWindowName(Ed(FInner).Handle, '');
  end;

  FInnerOldProc(Message);

  case Message.Msg of
    WM_SETFOCUS, WM_KILLFOCUS:
      FocusChanged;
    WM_PAINT:
      PaintTextHint(HDC(Message.WParam));
  end;
end;

procedure TPPGCustomField.PaintTextHint(DC: HDC);
var
  R: TRect;
  OwnDC: Boolean;
  OldFont: HGDIOBJ;
  Flags: Cardinal;
  S: string;
  Wnd: HWND;
begin
  if (FInner = nil) or not Ed(FInner).HandleAllocated or not TextHintShowing then
    Exit;
  Wnd := Ed(FInner).Handle;
  OwnDC := DC = 0;
  if OwnDC then
    DC := GetDC(Wnd);
  if DC = 0 then
    Exit;
  try
    // Gleiche Stelle wie der Text des Edits (Formatierungsrechteck)
    SendMessage(Wnd, EM_GETRECT, 0, LPARAM(@R));
    S := DisplayTextHint;
    if IsMultiLine then
      Flags := DT_NOPREFIX or DT_WORDBREAK or DT_EDITCONTROL
    else
      Flags := DT_NOPREFIX or DT_SINGLELINE or DT_END_ELLIPSIS;
    case Ed(FInner).Alignment of
      taRightJustify: Flags := Flags or DT_RIGHT;
      taCenter: Flags := Flags or DT_CENTER;
    end;
    Flags := Ed(FInner).DrawTextBiDiModeFlags(Flags);
    // Caret verbergen: er wird per XOR gezeichnet und wuerde sonst Reste lassen
    HideCaret(Wnd);
    try
      OldFont := SelectObject(DC, Ed(FInner).Font.Handle);
      try
        SetBkMode(DC, TRANSPARENT);
        SetTextColor(DC, ColorToRGB(FHintColor));
        Winapi.Windows.DrawText(DC, PChar(S), Length(S), R, Flags);
      finally
        SelectObject(DC, OldFont);
      end;
    finally
      ShowCaret(Wnd);
    end;
  finally
    if OwnDC then
      ReleaseDC(Wnd, DC);
  end;
end;

function TPPGCustomField.TextHintShowing: Boolean;
begin
  Result := (DisplayTextHint <> '') and not FHasText and
    (FTextHintVisibleOnFocus or not FieldFocused);
end;

function TPPGCustomField.DisplayTextHint: string;
begin
  Result := FTextHint;
  if FRequiredMark then
  begin
    if Result = '' then
      Result := '*'
    else
      Result := Result + ' *';
  end;
end;

procedure TPPGCustomField.SetRequiredMark(const Value: Boolean);
begin
  if FRequiredMark <> Value then
  begin
    FRequiredMark := Value;
    InvalidateInner;
    Invalidate;
  end;
end;

procedure TPPGCustomField.InvalidateInner;
begin
  if (FInner <> nil) and Ed(FInner).HandleAllocated then
    InvalidateRect(Ed(FInner).Handle, nil, True);
end;

procedure TPPGCustomField.InnerChange(Sender: TObject);
var
  HadText: Boolean;
begin
  HadText := FHasText;
  FHasText := Ed(FInner).GetTextLen > 0;
  if HadText <> FHasText then
  begin
    InvalidateInner; // TextHint ein-/ausblenden
    Invalidate;      // Loesch-Button
  end;
  if not (csLoading in ComponentState) and (FChangeLock = 0) then
    Change;
end;

procedure TPPGCustomField.Change;
begin
  NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
  Perform(CM_PPGVALUECHANGED, 0, 0);
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGCustomField.InnerClick(Sender: TObject);
begin
  Click;
end;

procedure TPPGCustomField.InnerDblClick(Sender: TObject);
begin
  DblClick;
end;

procedure TPPGCustomField.InnerKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Assigned(OnKeyDown) then
    OnKeyDown(Self, Key, Shift);
  if Key <> 0 then
    FieldKeyDown(Key, Shift);
end;

procedure TPPGCustomField.InnerKeyPress(Sender: TObject; var Key: Char);
begin
  if Assigned(OnKeyPress) then
    OnKeyPress(Self, Key);
  if Key <> #0 then
    FieldKeyPress(Key);
end;

procedure TPPGCustomField.InnerKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Assigned(OnKeyUp) then
    OnKeyUp(Self, Key, Shift);
end;

procedure TPPGCustomField.InnerMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(OnMouseDown) then
    OnMouseDown(Self, Button, Shift, X + Ed(FInner).Left, Y + Ed(FInner).Top);
end;

procedure TPPGCustomField.InnerMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(OnMouseMove) then
    OnMouseMove(Self, Shift, X + Ed(FInner).Left, Y + Ed(FInner).Top);
end;

procedure TPPGCustomField.InnerMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(OnMouseUp) then
    OnMouseUp(Self, Button, Shift, X + Ed(FInner).Left, Y + Ed(FInner).Top);
end;

procedure TPPGCustomField.InnerMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  Handled := DoMouseWheel(Shift, WheelDelta, MousePos);
end;

procedure TPPGCustomField.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
end;

procedure TPPGCustomField.FieldKeyPress(var Key: Char);
begin
end;

{ ---- Fokus ---- }

procedure TPPGCustomField.SetFocus;
begin
  if (FInner <> nil) and Ed(FInner).CanFocus then
    Ed(FInner).SetFocus
  else
    inherited SetFocus;
end;

function TPPGCustomField.Focused: Boolean;
begin
  Result := inherited Focused or ((FInner <> nil) and Ed(FInner).Focused);
end;

function TPPGCustomField.FieldFocused: Boolean;
var
  F: HWND;
begin
  // Ohne Nachrichten (wird auch beim Zeichnen gefragt)
  F := GetFocus;
  Result := (F <> 0) and ((HandleAllocated and (F = Handle)) or
    ((FInner <> nil) and Ed(FInner).HandleAllocated and (F = Ed(FInner).Handle)));
end;

function TPPGCustomField.FocusProgress: Single;
begin
  if FFocusAnim = nil then
    Result := 0
  else
    Result := FFocusAnim.Value;
end;

procedure TPPGCustomField.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  // z.B. ActiveControl des Formulars zeigt auf das Feld
  if (FInner <> nil) and Ed(FInner).Visible and Ed(FInner).Enabled and Ed(FInner).HandleAllocated then
    Winapi.Windows.SetFocus(Ed(FInner).Handle)
  else
    FocusChanged;
end;

procedure TPPGCustomField.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  FocusChanged;
end;

procedure TPPGCustomField.FocusChanged;
var
  Target: Single;
begin
  if (FFocusAnim = nil) or (csDestroying in ComponentState) then
    Exit;
  if FieldFocused then
    Target := 1
  else
    Target := 0;
  if not (csDesigning in ComponentState) and Animation.EffectiveEnabled and
    HandleAllocated and IsWindowVisible(Handle) then
    FFocusAnim.AnimateTo(Target, Animation.Duration, ekDecelerate)
  else
    FFocusAnim.Jump(Target);
  if DisplayTextHint <> '' then
    InvalidateInner;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
end;

procedure TPPGCustomField.FocusAnimStep(Sender: TObject);
begin
  Invalidate;
end;

{ ---- Zustand ---- }

function TPPGCustomField.IsHot: Boolean;
begin
  Result := inherited IsHot or FInnerHot;
end;

function TPPGCustomField.IsDown: Boolean;
begin
  Result := False; // ein Feld wird nicht "gedrueckt"
end;

procedure TPPGCustomField.UpdateVisualState(Animate: Boolean);
begin
  inherited UpdateVisualState(Animate);
  // Fokusanimation folgt den Animation-Einstellungen
  if (FFocusAnim <> nil) and not FFocusAnim.Running then
    if FieldFocused then
      FFocusAnim.Jump(1)
    else
      FFocusAnim.Jump(0);
end;

procedure TPPGCustomField.CMEnabledChanged(var Message: TMessage);
begin
  if not Enabled then
  begin
    FHotButton := -1;
    FPressedButton := -1;
  end;
  if FInner <> nil then
    Ed(FInner).Enabled := Enabled;
  inherited;
  UpdateColors;
end;

procedure TPPGCustomField.CMFontChanged(var Message: TMessage);
begin
  inherited;
  UpdateLayout;
end;

procedure TPPGCustomField.CMColorChanged(var Message: TMessage);
begin
  inherited;
  UpdateColors;
  Invalidate;
end;

procedure TPPGCustomField.CMStyleChanged(var Message: TMessage);
begin
  inherited;
  UpdateColors;
end;

procedure TPPGCustomField.CMSysColorChange(var Message: TMessage);
begin
  inherited;
  UpdateColors; // u.a. Hochkontrast ein/aus
end;

procedure TPPGCustomField.CMBiDiModeChanged(var Message: TMessage);
begin
  inherited;
  UpdateLayout;
end;

procedure TPPGCustomField.CMMouseLeave(var Message: TMessage);
begin
  if FHotButton >= 0 then
  begin
    FHotButton := -1;
    Invalidate;
  end;
  inherited;
end;

procedure TPPGCustomField.WMCaptureChanged(var Message: TMessage);
var
  Id: Integer;
begin
  inherited;
  // Capture verloren (Dialog, Alt+Tab): Button nicht gedrueckt haengen lassen
  if (FPressedButton >= 0) and (HWND(Message.LParam) <> Handle) then
  begin
    Id := FButtons[FPressedButton].Id;
    FPressedButton := -1;
    Invalidate;
    ButtonUp(Id);
  end;
end;

procedure TPPGCustomField.WMSetCursor(var Message: TWMSetCursor);
var
  P: TPoint;
begin
  // Ueber dem Rahmen Text-Cursor wie beim Edit, ueber Buttons der Pfeil
  if (Message.HitTest = HTCLIENT) and (Cursor = crDefault) and
    not (csDesigning in ComponentState) and GetCursorPos(P) then
  begin
    P := ScreenToClient(P);
    if (ButtonAt(P.X, P.Y) >= 0) or not InnerVisible then
      Winapi.Windows.SetCursor(Screen.Cursors[crArrow])
    else
      Winapi.Windows.SetCursor(Screen.Cursors[crIBeam]);
    Message.Result := 1;
  end
  else
    inherited;
end;

{ ---- Maus auf dem Rahmen und den Buttons ---- }

procedure TPPGCustomField.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  if (Button = mbLeft) and Enabled then
  begin
    I := ButtonAt(X, Y);
    // Klick auf den Rahmen setzt den Fokus in das Edit (wie bei TEdit)
    if not FieldFocused and HandleAllocated and IsWindowVisible(Handle) and
      IsWindowEnabled(GetAncestor(Handle, GA_ROOT)) then
    begin
      if (FInner <> nil) and Ed(FInner).CanFocus then
        Ed(FInner).SetFocus
      else if not InnerVisible and CanFocus then
        inherited SetFocus; // Feld ohne Edit (ComboBox-Liste)
    end;
    if I >= 0 then
    begin
      FPressedButton := I;
      Invalidate;
      ButtonDown(FButtons[I].Id);
    end;
  end;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TPPGCustomField.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  I := ButtonAt(X, Y);
  if I <> FHotButton then
  begin
    FHotButton := I;
    Invalidate;
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TPPGCustomField.WMLButtonUp(var Message: TWMLButtonUp);
var
  Pressed, Id: Integer;
begin
  // VOR inherited: das Freigeben der Maus (MouseCapture := False) loest
  // WM_CAPTURECHANGED aus, das einen noch gedrueckten Button abbrechen wuerde.
  // Zustand ausserdem vor dem Anwender-Code zuruecksetzen.
  Pressed := FPressedButton;
  Id := 0;
  FPressedButton := -1;
  if Pressed >= 0 then
  begin
    Invalidate;
    Id := FButtons[Pressed].Id;
    ButtonUp(Id);
  end;
  inherited;
  if (Pressed >= 0) and (Pressed <= High(FButtons)) and
    (ButtonAt(Message.XPos, Message.YPos) = Pressed) then
    ButtonClick(Id);
end;

procedure TPPGCustomField.KeyDown(var Key: Word; Shift: TShiftState);
begin
  // Kein "Leertaste = Klick" der Basis: ein Feld ist kein Button
  if Assigned(OnKeyDown) then
    OnKeyDown(Self, Key, Shift);
end;

procedure TPPGCustomField.KeyUp(var Key: Word; Shift: TShiftState);
begin
  if Assigned(OnKeyUp) then
    OnKeyUp(Self, Key, Shift);
end;

{ ---- Buttons ---- }

procedure TPPGCustomField.GetButtons(var Buttons: TPPGFieldButtons);
begin
end;

function TPPGCustomField.ButtonVisible(Id: Integer): Boolean;
begin
  if Id = PPGFieldButtonClear then
    // Nur bei Text und wenn der Anwender gerade mit dem Feld arbeitet (Fluent)
    Result := FHasText and Enabled and not GetReadOnly and (IsHot or FieldFocused)
  else
    Result := True;
end;

function TPPGCustomField.ButtonEnabled(Id: Integer): Boolean;
begin
  Result := Enabled;
end;

procedure TPPGCustomField.ButtonDown(Id: Integer);
begin
end;

procedure TPPGCustomField.ButtonUp(Id: Integer);
begin
end;

procedure TPPGCustomField.ButtonClick(Id: Integer);
begin
  if Id = PPGFieldButtonClear then
  begin
    Clear;
    if Ed(FInner).CanFocus and not FieldFocused then
      Ed(FInner).SetFocus;
  end;
end;

procedure TPPGCustomField.CancelButtonPress;
var
  Id: Integer;
begin
  if (FPressedButton < 0) or (FPressedButton > High(FButtons)) then
  begin
    FPressedButton := -1;
    Exit;
  end;
  Id := FButtons[FPressedButton].Id;
  FPressedButton := -1;
  Invalidate;
  ButtonUp(Id);
end;

function TPPGCustomField.ButtonAt(X, Y: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FButtons) do
    if PtInRect(FButtons[I].Rect, Point(X, Y)) and ButtonVisible(FButtons[I].Id) and
      ButtonEnabled(FButtons[I].Id) then
      Exit(I);
end;

function TPPGCustomField.ButtonRect(Id: Integer): TRect;
var
  I: Integer;
begin
  for I := 0 to High(FButtons) do
    if FButtons[I].Id = Id then
      Exit(FButtons[I].Rect);
  Result := Rect(0, 0, 0, 0);
end;

{ ---- Layout ---- }

function TPPGCustomField.IsMultiLine: Boolean;
begin
  Result := FInner is TCustomMemo;
end;

function TPPGCustomField.LineHeight: Integer;
begin
  Result := PPGMeasureTextNoCanvas('Wg', Font, 0, False).cy;
  if Result < 1 then
    Result := 1;
end;

procedure TPPGCustomField.UpdateLayout;
var
  PPI, BW, R, PadX, Gap, BtnH, BtnW, XL, XR, I, N, TextL, TextR, LineH, InnerH, Y: Integer;
  Inner: TRect;
  S: TPPGSurfaceStyle;
  Client, Content: TRect;
  B: TPPGFieldButtons;
  Mirror: Boolean;
begin
  if (FInner = nil) or (csDestroying in ComponentState) then
    Exit;
  PPI := ScalePPI;
  S := EffectiveAppearance.Resolve(vsNormal, PPI, False);
  BW := S.BorderWidth;
  if FBorderStyle = bsNone then
    BW := 0;
  // NICHT ClientRect: TWinControl.GetClientRect erzeugt das Fensterhandle,
  // und das Layout laeuft schon im Konstruktor (noch ohne Parent).
  // Das Feld hat keinen Nicht-Client-Bereich, also gilt Width x Height.
  Client := Rect(0, 0, Width, Height);
  Content := Client;
  InflateRect(Content, -BW, -BW);
  R := PPGCapRounding(Client, S.Rounding);
  // Text nicht in die Rundung legen (wie Container: gut 0,3 r)
  PadX := PPGScale(FieldPadX, PPI) + (R * 3 + 9) div 10;
  Gap := PPGScale(ButtonGap, PPI);

  // Buttons: quadratisch in der Hoehe einer Zeile plus Luft, hoechstens
  // MaxButtonWidth breit; bei Mehrzeilern oben ausgerichtet
  LineH := LineHeight;
  if IsMultiLine then
    BtnH := LineH + 2 * PPGScale(FieldPadY, PPI)
  else
    BtnH := (Content.Bottom - Content.Top) - 2 * Gap;
  if BtnH < 0 then
    BtnH := 0;
  BtnW := BtnH;
  if BtnW > PPGScale(MaxButtonWidth, PPI) then
    BtnW := PPGScale(MaxButtonWidth, PPI);

  SetLength(B, 0);
  GetButtons(B);
  if FShowClearButton then
  begin
    N := Length(B);
    SetLength(B, N + 1);
    B[N].Id := PPGFieldButtonClear;
    B[N].Glyph := fgClear;
    B[N].ImageIndex := -1;
    B[N].LeftSide := False; // innerster rechter Button
  end;

  XL := Content.Left + Gap;
  XR := Content.Right - Gap;
  for I := 0 to High(B) do
  begin
    if IsMultiLine then
      Y := Content.Top + Gap
    else
      Y := Content.Top + ((Content.Bottom - Content.Top) - BtnH) div 2;
    if B[I].LeftSide then
    begin
      B[I].Rect := Rect(XL, Y, XL + BtnW, Y + BtnH);
      Inc(XL, BtnW + Gap);
    end
    else
    begin
      B[I].Rect := Rect(XR - BtnW, Y, XR, Y + BtnH);
      Dec(XR, BtnW + Gap);
    end;
  end;

  if XL > Content.Left + Gap then
    TextL := XL
  else
    TextL := Content.Left + PadX;
  if XR < Content.Right - Gap then
    TextR := XR
  else
    TextR := Content.Right - PadX;

  // RTL: Buttons und Textbereich spiegeln (linke Buttons stehen dann rechts)
  Mirror := UseRightToLeftAlignment;
  if Mirror then
  begin
    for I := 0 to High(B) do
      B[I].Rect := Rect(Width - B[I].Rect.Right, B[I].Rect.Top,
        Width - B[I].Rect.Left, B[I].Rect.Bottom);
    N := TextL;
    TextL := Width - TextR;
    TextR := Width - N;
  end;
  FButtons := B;
  if FHotButton > High(FButtons) then
    FHotButton := -1;
  if FPressedButton > High(FButtons) then
    FPressedButton := -1;

  if TextR < TextL then
    TextR := TextL;
  if IsMultiLine then
  begin
    Y := Content.Top + PPGScale(FieldPadY, PPI);
    InnerH := (Content.Bottom - PPGScale(FieldPadY, PPI)) - Y;
  end
  else
  begin
    // Einzeiliges EDIT zentriert nicht vertikal -> selbst mittig setzen
    InnerH := LineH + 2;
    if InnerH > Content.Bottom - Content.Top then
      InnerH := Content.Bottom - Content.Top;
    Y := Content.Top + ((Content.Bottom - Content.Top) - InnerH + 1) div 2;
  end;
  if InnerH < 0 then
    InnerH := 0;
  Inner := Rect(TextL, Y, TextR, Y + InnerH);
  AdjustInnerBounds(Inner);
  Ed(FInner).SetBounds(Inner.Left, Inner.Top, Inner.Right - Inner.Left, Inner.Bottom - Inner.Top);
  Invalidate;
end;

procedure TPPGCustomField.AdjustInnerBounds(var R: TRect);
begin
end;

function TPPGCustomField.AutoSizeWidth: Boolean;
begin
  Result := False;
end;

function TPPGCustomField.CalcAutoSize(out AWidth, AHeight: Integer): Boolean;
var
  PPI, BW: Integer;
begin
  // Wie TEdit: nur die Hoehe folgt der Schrift; Mehrzeiler nie
  Result := not IsMultiLine;
  if not Result then
    Exit;
  PPI := ScalePPI;
  BW := EffectiveAppearance.Resolve(vsNormal, PPI, False).BorderWidth;
  if FBorderStyle = bsNone then
    BW := 0;
  AWidth := Width;
  AHeight := LineHeight + 2 + 2 * (BW + PPGScale(FieldPadY, PPI));
end;

{ ---- Farben und Zeichnen ---- }

procedure TPPGCustomField.GetFieldColors(out Fill, Text: TColor);
var
  A: TPPGAppearance;
  T: TPPGTokens;
begin
  if HighContrastSupport and PPGIsHighContrast then
  begin
    Fill := PPGColorToRGB(clWindow);
    if Enabled then
      Text := PPGColorToRGB(clWindowText)
    else
      Text := PPGColorToRGB(clGrayText);
  end
  else if UseVclStyle then
    PPGVclStyleEditColors(Enabled, Fill, Text)
  else if UseDarkMode then
  begin
    // Color/Font.Color sind fuer Hell gedacht (clWindow bleibt im Dark Mode
    // weiss) - wie beim VCL-Style gelten die Farben des Presets
    T := Tokens;
    if Enabled then
    begin
      Fill := T.Surface;
      Text := T.TextPrimary;
    end
    else
    begin
      Fill := T.SurfaceDisabled;
      Text := T.TextDisabled;
    end;
  end
  else if Enabled then
  begin
    Fill := PPGColorToRGB(Color);
    Text := PPGColorToRGB(Font.Color);
  end
  else
  begin
    A := EffectiveAppearance;
    Fill := PPGColorToRGB(A.Disabled.Color);
    Text := PPGColorToRGB(A.Disabled.TextColor);
  end;
  if UseReadOnlyColors then
  begin
    Fill := PPGColorToRGB(FReadOnlyStyle.FillFor(UseDarkMode, Fill));
    Text := PPGColorToRGB(FReadOnlyStyle.TextFor(UseDarkMode, Text));
  end;
end;

function TPPGCustomField.UseReadOnlyColors: Boolean;
begin
  Result := (FReadOnlyStyle <> nil) and (FInner <> nil) and Enabled and GetReadOnly and
    not (HighContrastSupport and PPGIsHighContrast) and not UseVclStyle;
end;

procedure TPPGCustomField.SetReadOnlyStyle(const Value: TPPGElementStyle);
begin
  FReadOnlyStyle.Assign(Value);
end;

procedure TPPGCustomField.ReadOnlyStyleChanged(Sender: TObject);
begin
  UpdateColors;
end;

procedure TPPGCustomField.UpdateColors;
var
  Inner: IPPGFieldInner;
  Fill, Text: TColor;
begin
  if (FInner = nil) or (csDestroying in ComponentState) then
    Exit;
  GetFieldColors(Fill, Text);
  Ed(FInner).Color := Fill;
  FHintColor := PPGBlendColor(Text, Fill, 0.5);
  // Textfarbe des inneren Edits ohne die (gespeicherte) Schrift zu aendern;
  // mit VCL-Style faerbt der Style-Hook
  if UseVclStyle then
    Text := clNone;
  if Supports(FInner, IPPGFieldInner, Inner) then
  begin
    Inner.SetFieldTextColor(Text);
    Inner.SetFieldDarkScrollBars(UseDarkMode);
  end;
{$IFDEF PPG_HAS_STYLEELEMENTS}
  // Mit VCL-Style faerbt der Style-Hook das innere Edit (gleiche Style-Farben
  // wie das Feld); ohne Style gelten Color und Font des Felds
  if UseVclStyle then
    Ed(FInner).StyleElements := [seFont, seClient]
  else
    Ed(FInner).StyleElements := [];
{$ENDIF}
  InvalidateInner;
  Invalidate;
end;

function TPPGCustomField.GetFieldStyle: TPPGSurfaceStyle;
var
  A: TPPGAppearance;
  PPI: Integer;
  Fill, Text, Accent, Signal: TColor;
begin
  A := EffectiveAppearance;
  PPI := ScalePPI;
  if Enabled then
    Result := PPGBlendSurface(A.Resolve(vsNormal, PPI, False),
      A.Resolve(vsHot, PPI, False), HotProgress)
  else
    Result := A.Resolve(vsDisabled, PPI, False);
  GetFieldColors(Fill, Text);
  // Presets ohne eigene Hover-Randfarbe (Fluent11): Rand beim Hover kraeftiger,
  // sonst ist der Hover bei Feldern unsichtbar (Flaeche = Feldfarbe)
  if Enabled and (HotProgress > 0) and
    (A.Resolve(vsNormal, PPI, False).BorderColor = A.Resolve(vsHot, PPI, False).BorderColor) then
    Result.BorderColor := PPGBlendColor(Result.BorderColor, Text, 0.35 * HotProgress);
  Accent := PPGColorToRGB(A.FocusColor);

  case FValidationState of
    pvsValid: Signal := Tokens.Success;
    pvsWarning: Signal := Tokens.Warning;
    pvsError: Signal := Tokens.Danger;
  else
    Signal := clNone;
  end;
  if (Signal <> clNone) and Enabled then
  begin
    Result.BorderColor := Signal;
    Accent := Signal;
  end;

  if HighContrastSupport and PPGIsHighContrast then
  begin
    if Enabled and (IsHot or FieldFocused) then
      Result.BorderColor := PPGColorToRGB(clHighlight)
    else
      Result.BorderColor := PPGColorToRGB(clWindowText);
    Accent := PPGColorToRGB(clHighlight);
    if Result.BorderWidth < 1 then
      Result.BorderWidth := 1;
  end;

  Result.Color := Fill;
  Result.ColorTo := Fill;
  Result.ColorMirror := Fill;
  Result.ColorMirrorTo := Fill;
  Result.TextColor := Text;
  Result.GlowColor := Accent;
  Result.GlowAlpha := 0;
  Result.Focused := FieldFocused;
  if UseReadOnlyColors and FReadOnlyStyle.HasBorder(UseDarkMode) and (Signal = clNone) then
    Result.BorderColor := PPGColorToRGB(FReadOnlyStyle.BorderFor(UseDarkMode, Result.BorderColor));
  if FBorderStyle = bsNone then
    Result.BorderWidth := 0;
end;

function TPPGCustomField.FieldRenderer: IPPGFieldRenderer;
begin
  if not Supports(Renderer, IPPGFieldRenderer, Result) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
      IPPGFieldRenderer, Result);
end;

procedure TPPGCustomField.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  Style, BtnStyle: TPPGSurfaceStyle;
  FR: IPPGFieldRenderer;
  Old: TPPGCorners;
  I, PPI, X, Y: Integer;
  B: TPPGFieldButton;
  Hot, Pressed: Boolean;
begin
  PPI := ScalePPI;
  Style := GetFieldStyle;
  FR := FieldRenderer;
  Old := PPGSetSquareCorners(ACanvas, SquareCorners);
  try
    FR.DrawField(ACanvas, ClientR, Style, FocusProgress, PPI);
  finally
    PPGSetSquareCorners(ACanvas, Old);
  end;

  for I := 0 to High(FButtons) do
  begin
    B := FButtons[I];
    if not ButtonVisible(B.Id) then
      Continue;
    BtnStyle := Style;
    if not ButtonEnabled(B.Id) then
      BtnStyle.TextColor := PPGBlendColor(Style.TextColor, Style.Color, 0.6);
    Hot := (I = FHotButton) and ButtonEnabled(B.Id);
    Pressed := (I = FPressedButton) and (I = FHotButton);
    if (B.ImageIndex >= 0) and (Images <> nil) and (B.ImageIndex < Images.Count) then
    begin
      FR.DrawFieldButton(ACanvas, B.Rect, BtnStyle, fgNone, Hot, Pressed, PPI);
      X := (B.Rect.Left + B.Rect.Right - Images.Width) div 2;
      Y := (B.Rect.Top + B.Rect.Bottom - Images.Height) div 2;
      ACanvas.DrawImage(Images, B.ImageIndex, X, Y, Enabled and ButtonEnabled(B.Id));
    end
    else
      FR.DrawFieldButton(ACanvas, B.Rect, BtnStyle, B.Glyph, Hot, Pressed, PPI);
  end;
  DoPaintField(ACanvas, Style);
end;

procedure TPPGCustomField.DoPaintField(const ACanvas: IPPGCanvas;
  const Style: TPPGSurfaceStyle);
begin
end;

{ ---- Barrierefreiheit ---- }

function TPPGCustomField.AccName: string;
var
  I: Integer;
  C: TControl;
begin
  Result := '';
  // 1. Beschriftung, die per FocusControl auf das Feld zeigt
  if Parent <> nil then
    for I := 0 to Parent.ControlCount - 1 do
    begin
      C := Parent.Controls[I];
      if (C is TCustomLabel) and ((TLabelAccess(C).FocusControl = Self) or
        ((FInner <> nil) and (TLabelAccess(C).FocusControl = FInner))) then
      begin
        Result := PPGAccStripHotkey(TLabelAccess(C).Caption);
        if Result <> '' then
          Exit;
      end;
    end;
  // 2. Platzhaltertext, 3. Hint
  Result := FTextHint;
  if Result = '' then
    Result := GetShortHint(Hint);
end;

function TPPGCustomField.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_GROUPING;
end;

function TPPGCustomField.AccState: Integer;
begin
  Result := inherited AccState;
  if Enabled and TabStop then
    Result := Result or STATE_SYSTEM_FOCUSABLE;
  if GetReadOnly then
    Result := Result or STATE_SYSTEM_READONLY;
end;

function TPPGCustomField.AccDescription: string;
begin
  if (FValidationState <> pvsNone) and (FValidationHint <> '') then
    Result := FValidationHint
  else
    Result := inherited AccDescription;
end;

function TPPGCustomField.AccKeyboardShortcut: string;
begin
  Result := '';
end;

function TPPGCustomField.AccDefaultAction: string;
begin
  Result := '';
end;

procedure TPPGCustomField.AccDoDefaultAction;
begin
  // Ein Eingabefeld hat keine Standardaktion
end;

{ ---- Properties ---- }

function TPPGCustomField.GetText: string;
begin
  Result := Ed(FInner).Text;
end;

procedure TPPGCustomField.SetTextSilent(const Value: string);
begin
  Inc(FChangeLock);
  try
    SetText(Value);
  finally
    Dec(FChangeLock);
  end;
end;

function TPPGCustomField.ChangeLocked: Boolean;
begin
  Result := FChangeLock > 0;
end;

procedure TPPGCustomField.SetText(const Value: string);
begin
  Ed(FInner).Text := Value;
  // Ohne Fenster kommt kein EN_CHANGE -> Zustand selbst nachfuehren
  if FHasText <> (Value <> '') then
  begin
    FHasText := Value <> '';
    InvalidateInner;
    Invalidate;
  end;
end;

function TPPGCustomField.GetTabStop: Boolean;
begin
  Result := FTabStop;
end;

procedure TPPGCustomField.SetTabStop(const Value: Boolean);
begin
  FTabStop := Value;
  // Tabstopp ist das innere Edit - oder das Feld selbst, wenn das Edit
  // ausgeblendet ist
  if InnerVisible then
  begin
    Ed(FInner).TabStop := Value;
    TWinControl(Self).TabStop := False;
  end
  else
  begin
    if FInner <> nil then
      Ed(FInner).TabStop := False;
    TWinControl(Self).TabStop := Value;
  end;
end;

function TPPGCustomField.InnerVisible: Boolean;
begin
  Result := (FInner <> nil) and Ed(FInner).Visible;
end;

procedure TPPGCustomField.SetInnerVisible(Value: Boolean);
var
  HadFocus: Boolean;
begin
  if (FInner = nil) or (Ed(FInner).Visible = Value) then
    Exit;
  HadFocus := Ed(FInner).Focused;
  Ed(FInner).Visible := Value;
  SetTabStop(FTabStop);
  // Fokus nicht ins Leere fallen lassen
  if HadFocus and not Value and CanFocus then
    inherited SetFocus;
  Invalidate;
end;

function TPPGCustomField.WantSpecialKey(Key: Word): Boolean;
begin
  Result := False;
end;

procedure TPPGCustomField.CMWantSpecialKey(var Message: TCMWantSpecialKey);
begin
  if WantSpecialKey(Message.CharCode) then
    Message.Result := 1
  else
    inherited;
end;

function TPPGCustomField.GetMaxLength: Integer;
begin
  Result := Ed(FInner).MaxLength;
end;

procedure TPPGCustomField.SetMaxLength(const Value: Integer);
begin
  Ed(FInner).MaxLength := PPGCheckRange(Self, 'MaxLength', Value, 0, MaxInt);
end;

function TPPGCustomField.GetReadOnly: Boolean;
begin
  Result := Ed(FInner).ReadOnly;
end;

procedure TPPGCustomField.SetReadOnly(const Value: Boolean);
begin
  if Ed(FInner).ReadOnly <> Value then
  begin
    Ed(FInner).ReadOnly := Value;
    if not FReadOnlyStyle.IsEmpty then
      UpdateColors;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_STATECHANGE);
  end;
end;

function TPPGCustomField.GetCharCase: TEditCharCase;
begin
  Result := Ed(FInner).CharCase;
end;

procedure TPPGCustomField.SetCharCase(const Value: TEditCharCase);
begin
  Ed(FInner).CharCase := Value;
end;

function TPPGCustomField.GetHideSelection: Boolean;
begin
  Result := TEditAccess(FInner).HideSelection;
end;

procedure TPPGCustomField.SetHideSelection(const Value: Boolean);
begin
  TEditAccess(FInner).HideSelection := Value;
end;

function TPPGCustomField.GetAlignment: TAlignment;
begin
  Result := Ed(FInner).Alignment;
end;

procedure TPPGCustomField.SetAlignment(const Value: TAlignment);
begin
  Ed(FInner).Alignment := Value;
  InvalidateInner;
end;

function TPPGCustomField.GetModified: Boolean;
begin
  Result := Ed(FInner).Modified;
end;

procedure TPPGCustomField.SetModified(const Value: Boolean);
begin
  Ed(FInner).Modified := Value;
end;

function TPPGCustomField.GetSelStart: Integer;
begin
  Result := Ed(FInner).SelStart;
end;

procedure TPPGCustomField.SetSelStart(const Value: Integer);
begin
  Ed(FInner).SelStart := Value;
end;

function TPPGCustomField.GetSelLength: Integer;
begin
  Result := Ed(FInner).SelLength;
end;

procedure TPPGCustomField.SetSelLength(const Value: Integer);
begin
  Ed(FInner).SelLength := Value;
end;

function TPPGCustomField.GetSelText: string;
begin
  Result := Ed(FInner).SelText;
end;

procedure TPPGCustomField.SetSelText(const Value: string);
begin
  Ed(FInner).SelText := Value;
end;

procedure TPPGCustomField.SetTextHint(const Value: string);
begin
  if FTextHint <> Value then
  begin
    FTextHint := Value;
    InvalidateInner;
    if (FInner <> nil) and Ed(FInner).HandleAllocated then
      PPGAccSetWindowName(Ed(FInner).Handle, AccName);
  end;
end;

procedure TPPGCustomField.SetTextHintVisibleOnFocus(const Value: Boolean);
begin
  if FTextHintVisibleOnFocus <> Value then
  begin
    FTextHintVisibleOnFocus := Value;
    InvalidateInner;
  end;
end;

procedure TPPGCustomField.SetValidationState(const Value: TPPGValidationState);
begin
  if FValidationState <> Value then
  begin
    FValidationState := Value;
    UpdateInnerHint;
    Invalidate;
    NotifyAccessibility(EVENT_OBJECT_DESCRIPTIONCHANGE);
  end;
end;

procedure TPPGCustomField.SetValidationHint(const Value: string);
begin
  if FValidationHint <> Value then
  begin
    FValidationHint := Value;
    UpdateInnerHint;
    NotifyAccessibility(EVENT_OBJECT_DESCRIPTIONCHANGE);
  end;
end;

procedure TPPGCustomField.UpdateInnerHint;
begin
  // Die VCL zeigt den Hint des Controls unter der Maus (inneres Edit); ohne
  // eigenen Hint nimmt sie den des Felds
  if (FValidationState <> pvsNone) and (FValidationHint <> '') then
  begin
    Ed(FInner).Hint := FValidationHint;
    Ed(FInner).ShowHint := True;
  end
  else
  begin
    Ed(FInner).Hint := '';
    Ed(FInner).ParentShowHint := True;
  end;
end;

procedure TPPGCustomField.SetShowClearButton(const Value: Boolean);
begin
  if FShowClearButton <> Value then
  begin
    FShowClearButton := Value;
    UpdateLayout;
  end;
end;

procedure TPPGCustomField.SetBorderStyle(const Value: TBorderStyle);
begin
  if FBorderStyle <> Value then
  begin
    FBorderStyle := Value;
    RequestAutoSize;
    UpdateLayout;
  end;
end;

{ ---- Methoden wie TCustomEdit ---- }

procedure TPPGCustomField.Clear;
begin
  Ed(FInner).Clear;
  if FHasText then
  begin
    FHasText := False;
    InvalidateInner;
    Invalidate;
  end;
end;

procedure TPPGCustomField.SelectAll;
begin
  Ed(FInner).SelectAll;
end;

procedure TPPGCustomField.ClearSelection;
begin
  Ed(FInner).ClearSelection;
end;

procedure TPPGCustomField.CopyToClipboard;
begin
  Ed(FInner).CopyToClipboard;
end;

procedure TPPGCustomField.CutToClipboard;
begin
  Ed(FInner).CutToClipboard;
end;

procedure TPPGCustomField.PasteFromClipboard;
begin
  Ed(FInner).PasteFromClipboard;
end;

procedure TPPGCustomField.Undo;
begin
  Ed(FInner).Undo;
end;

function TPPGCustomField.CanUndo: Boolean;
begin
  Result := Ed(FInner).CanUndo;
end;


{ ---- Bearbeiten-Menue (Phase 11d) ---- }

const
  EmUndo = 1;
  EmCut = 2;
  EmCopy = 3;
  EmPaste = 4;
  EmDelete = 5;
  EmSelectAll = 6;

function TPPGCustomField.BuildEditMenu: TPopupMenu;
var
  ReadOnlyNow, HasSel, Secret: Boolean;

  procedure AddItem(const Caption: string; Tag: Integer; Key: Word; Enabled: Boolean);
  var
    M: TMenuItem;
  begin
    M := TMenuItem.Create(FEditMenu);
    M.Caption := Caption;
    M.Tag := Tag;
    if Key <> 0 then
    begin
      if Key = VK_DELETE then
        M.ShortCut := ShortCut(Key, [])
      else
        M.ShortCut := ShortCut(Key, [ssCtrl]);
    end;
    M.Enabled := Enabled;
    M.OnClick := EditMenuClick;
    FEditMenu.Items.Add(M);
  end;

  procedure AddLine;
  var
    M: TMenuItem;
  begin
    M := TMenuItem.Create(FEditMenu);
    M.Caption := cLineCaption;
    FEditMenu.Items.Add(M);
  end;

begin
  if FEditMenu = nil then
    FEditMenu := TPPGPopupMenu.Create(nil);
  FEditMenu.Items.Clear;
  FEditMenu.BiDiMode := BiDiMode;
  ReadOnlyNow := ReadOnly or not Enabled;
  HasSel := SelLength > 0;
  // Verdeckte Eingabe (Passwort): nichts in die Zwischenablage
  Secret := Ed(FInner).PasswordChar <> #0;
  AddItem(PPGStr(@SPPGEditUndo), EmUndo, Ord('Z'), CanUndo and not ReadOnlyNow);
  AddLine;
  AddItem(PPGStr(@SPPGEditCut), EmCut, Ord('X'), HasSel and not ReadOnlyNow and not Secret);
  AddItem(PPGStr(@SPPGEditCopy), EmCopy, Ord('C'), HasSel and not Secret);
  AddItem(PPGStr(@SPPGEditPaste), EmPaste, Ord('V'), not ReadOnlyNow and
    (IsClipboardFormatAvailable(CF_UNICODETEXT) or IsClipboardFormatAvailable(CF_TEXT)));
  AddItem(PPGStr(@SPPGEditDelete), EmDelete, VK_DELETE, HasSel and not ReadOnlyNow);
  AddLine;
  AddItem(PPGStr(@SPPGEditSelectAll), EmSelectAll, Ord('A'),
    (Ed(FInner).GetTextLen > 0) and (SelLength < Ed(FInner).GetTextLen));
  Result := FEditMenu;
end;

procedure TPPGCustomField.ShowEditMenu(X, Y: Integer);
var
  M: TPopupMenu;
  P: TPoint;
  Keyboard: Boolean;
begin
  M := BuildEditMenu;
  M.PopupComponent := Self;
  // Shift+F10/Kontextmenue-Taste: (-1, -1) - dann am Feld, mit Mnemonics
  Keyboard := (X = -1) and (Y = -1);
  if Keyboard then
    P := ClientToScreen(Point(0, Height))
  else
    P := Point(X, Y);
  TPPGPopupMenu(M).PopupAtRect(Rect(P.X, P.Y, P.X, P.Y), Keyboard);
end;

procedure TPPGCustomField.EditMenuClick(Sender: TObject);
begin
  case TMenuItem(Sender).Tag of
    EmUndo: Undo;
    EmCut: CutToClipboard;
    EmCopy: CopyToClipboard;
    EmPaste: PasteFromClipboard;
    EmDelete: ClearSelection;
    EmSelectAll: SelectAll;
  end;
end;

end.
