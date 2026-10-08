unit PPG.MaskEdit;

{ TPPGMaskEdit - Eingabe mit Maske (Phase 12b, Vorbild TMaskEdit).

  - Das innere Edit ist ein Nachfahre von TCustomMaskEdit: die gesamte
    Maskenlogik der VCL (EditMask, EditText, IsMasked, Validate) wird
    wiederverwendet, nichts davon nachgebaut. DFM wie TMaskEdit.
  - Ungueltige Eingabe beim Verlassen: kein Exception-Dialog, sondern
    ValidationState = pvsError mit Hinweis (wie die DB-Felder aus Phase 9);
    der Fokus wird nicht festgehalten. Ein ganz leeres Feld gilt als gueltig.
  - IME und Masken vertragen sich schlecht (asiatische Eingabe); das gilt wie
    bei der VCL auch hier.
  - IPPGFieldValue: Wert = Text, leer = Null (fuer DB-Felder und Grid). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.Variants, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.Mask,
  PPG.Types, PPG.Controls.Field;

type
  TPPGCustomMaskEdit = class;

  /// Inneres Edit mit VCL-Maskenlogik.
  TPPGFieldMaskEdit = class(TCustomMaskEdit, IPPGFieldInner)
  private
    FField: TPPGCustomMaskEdit;
    FTextColor: TColor;
    procedure CNCtlColorEdit(var Message: TWMCtlColorEdit); message CN_CTLCOLOREDIT;
    procedure CNCtlColorStatic(var Message: TWMCtlColorStatic); message CN_CTLCOLORSTATIC;
    { IPPGFieldInner }
    procedure SetFieldTextColor(Color: TColor);
    procedure SetFieldDarkScrollBars(Value: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    procedure ValidateEdit; override;
  end;

  TPPGCustomMaskEdit = class(TPPGCustomField, IPPGFieldValue)
  private
    FOwnError: Boolean;
    FInvalidPos: Integer;
    FOnValidationError: TNotifyEvent;
    function MaskInner: TPPGFieldMaskEdit;
    function GetEditMask: string;
    procedure SetEditMask(const Value: string);
    function GetEditText: string;
    procedure SetEditText(const Value: string);
    function GetIsMasked: Boolean;
    function GetAutoSelect: Boolean;
    procedure SetAutoSelect(const Value: Boolean);
    function GetPasswordChar: Char;
    procedure SetPasswordChar(const Value: Char);
    procedure ReportInvalid(Pos: Integer);
    procedure ReportValid;
  protected
    function CreateInner: TCustomEdit; override;
    procedure Change; override;
    function AccValue: string; override;
    { IPPGFieldValue }
    function FieldIsNull: Boolean;
    procedure FieldClear;
    function GetFieldValue: Variant;
    procedure SetFieldValue(const Value: Variant);

    property AutoSelect: Boolean read GetAutoSelect write SetAutoSelect default True;
    property EditMask: string read GetEditMask write SetEditMask;
    property PasswordChar: Char read GetPasswordChar write SetPasswordChar default #0;
    /// Ungueltige Eingabe beim Verlassen (statt EDBEditError der VCL).
    property OnValidationError: TNotifyEvent read FOnValidationError write FOnValidationError;
  public
    /// Prueft die Eingabe jetzt (wie beim Verlassen). False = ungueltig.
    function ValidateInput: Boolean;
    /// True, wenn keine Zeichen eingegeben sind (nur Maske).
    function IsEmpty: Boolean;
    property EditText: string read GetEditText write SetEditText;
    property IsMasked: Boolean read GetIsMasked;
    /// Stelle des ersten ungueltigen Zeichens nach der letzten Pruefung (-1 = keine).
    property InvalidPos: Integer read FInvalidPos;
  end;

  TPPGMaskEdit = class(TPPGCustomMaskEdit)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property TextHint;
    property TextHintVisibleOnFocus;
    property UseSystemContextMenu;
    property ValidationState;
    property ValidationHint;
    property HighContrastSupport;
    property ShowClearButton;
    { wie TMaskEdit }
    property Align;
    property Alignment;
    property Anchors;
    property AutoSelect;
    property AutoSize default True;
    property BiDiMode;
    property BorderStyle;
    property CharCase;
    property Color default clWindow;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property EditMask;
    property Enabled;
    property Font;
    property HideSelection;
    property MaxLength;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PasswordChar;
    property PopupMenu;
    property ReadOnly;
    property ReadOnlyStyle;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop;
    property Text;
    property Visible;
    property Touch;
    property OnGesture;
    property OnChange;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnValidationError;
  end;

implementation

uses
  System.MaskUtils, PPG.Lang, PPG.Consts;

type
  TMaskAccess = class(TCustomMaskEdit);

{ TPPGFieldMaskEdit }

constructor TPPGFieldMaskEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTextColor := clNone;
  if AOwner is TPPGCustomMaskEdit then
    FField := TPPGCustomMaskEdit(AOwner);
end;

procedure TPPGFieldMaskEdit.SetFieldTextColor(Color: TColor);
begin
  if FTextColor <> Color then
  begin
    FTextColor := Color;
    if HandleAllocated then
      Invalidate;
  end;
end;

procedure TPPGFieldMaskEdit.SetFieldDarkScrollBars(Value: Boolean);
begin
  // einzeilig: keine Scrollleisten
end;

procedure TPPGFieldMaskEdit.CNCtlColorEdit(var Message: TWMCtlColorEdit);
begin
  inherited;
  PPGFieldCtlColor(Message.ChildDC, FTextColor);
end;

procedure TPPGFieldMaskEdit.CNCtlColorStatic(var Message: TWMCtlColorStatic);
begin
  inherited;
  PPGFieldCtlColor(Message.ChildDC, FTextColor);
end;

procedure TPPGFieldMaskEdit.ValidateEdit;
var
  Pos: Integer;
begin
  // Wie die VCL, aber ohne Exception und ohne den Fokus festzuhalten
  if not IsMasked or not Modified then
    Exit;
  if (FField <> nil) and FField.IsEmpty then
  begin
    FField.ReportValid;
    Exit;
  end;
  Pos := 0;
  if Validate(EditText, Pos) then
  begin
    if FField <> nil then
      FField.ReportValid;
  end
  else if FField <> nil then
    FField.ReportInvalid(Pos);
end;

{ TPPGCustomMaskEdit }

function TPPGCustomMaskEdit.CreateInner: TCustomEdit;
begin
  FInvalidPos := -1;
  Result := TPPGFieldMaskEdit.Create(Self);
end;

function TPPGCustomMaskEdit.MaskInner: TPPGFieldMaskEdit;
begin
  Result := TPPGFieldMaskEdit(Inner);
end;

function TPPGCustomMaskEdit.GetEditMask: string;
begin
  Result := TMaskAccess(Inner).EditMask;
end;

procedure TPPGCustomMaskEdit.SetEditMask(const Value: string);
begin
  TMaskAccess(Inner).EditMask := Value;
end;

function TPPGCustomMaskEdit.GetEditText: string;
begin
  Result := MaskInner.EditText;
end;

procedure TPPGCustomMaskEdit.SetEditText(const Value: string);
begin
  MaskInner.EditText := Value;
end;

function TPPGCustomMaskEdit.GetIsMasked: Boolean;
begin
  Result := MaskInner.IsMasked;
end;

function TPPGCustomMaskEdit.GetAutoSelect: Boolean;
begin
  Result := TMaskAccess(Inner).AutoSelect;
end;

procedure TPPGCustomMaskEdit.SetAutoSelect(const Value: Boolean);
begin
  TMaskAccess(Inner).AutoSelect := Value;
end;

function TPPGCustomMaskEdit.GetPasswordChar: Char;
begin
  Result := TMaskAccess(Inner).PasswordChar;
end;

procedure TPPGCustomMaskEdit.SetPasswordChar(const Value: Char);
begin
  TMaskAccess(Inner).PasswordChar := Value;
end;

function TPPGCustomMaskEdit.IsEmpty: Boolean;
var
  Empty, Cur: string;
  Blank: Char;
  I: Integer;
begin
  if not IsMasked then
    Exit(Text = '');
  // Eingabestellen sind die, an denen das leere Maskenbild ein Leerzeichen
  // bzw. das Leerzeichen der Maske hat; dort darf nichts eingegeben sein
  Blank := MaskGetMaskBlank(EditMask);
  Empty := FormatMaskText(EditMask, '');
  Cur := EditText;
  Result := True;
  for I := 1 to Length(Cur) do
  begin
    if (I <= Length(Empty)) and (Empty[I] <> ' ') and (Empty[I] <> Blank) then
      Continue; // Literal der Maske
    if (Cur[I] <> ' ') and (Cur[I] <> Blank) then
      Exit(False);
  end;
end;

function TPPGCustomMaskEdit.ValidateInput: Boolean;
var
  Pos: Integer;
begin
  Result := True;
  if not IsMasked or IsEmpty then
  begin
    ReportValid;
    Exit;
  end;
  Pos := 0;
  Result := TMaskAccess(Inner).Validate(EditText, Pos);
  if Result then
    ReportValid
  else
    ReportInvalid(Pos);
end;

procedure TPPGCustomMaskEdit.ReportInvalid(Pos: Integer);
begin
  FInvalidPos := Pos;
  FOwnError := True;
  ValidationHint := PPGStr(@SPPGMaskInvalid);
  ValidationState := pvsError;
  if Assigned(FOnValidationError) then
    FOnValidationError(Self);
end;

procedure TPPGCustomMaskEdit.ReportValid;
begin
  FInvalidPos := -1;
  if not FOwnError then
    Exit;
  FOwnError := False;
  ValidationState := pvsNone;
  ValidationHint := '';
end;

procedure TPPGCustomMaskEdit.Change;
begin
  inherited Change;
  // Neue Eingabe: den Fehler erst beim naechsten Pruefen wieder zeigen
  if FOwnError and not ChangeLocked then
    ReportValid;
end;

function TPPGCustomMaskEdit.AccValue: string;
begin
  if PasswordChar <> #0 then
    Result := ''
  else
    Result := Text;
end;

function TPPGCustomMaskEdit.FieldIsNull: Boolean;
begin
  Result := IsEmpty;
end;

procedure TPPGCustomMaskEdit.FieldClear;
begin
  SetTextSilent('');
  ReportValid;
end;

function TPPGCustomMaskEdit.GetFieldValue: Variant;
begin
  if IsEmpty then
    Result := Null
  else
    Result := Text;
end;

procedure TPPGCustomMaskEdit.SetFieldValue(const Value: Variant);
begin
  if VarIsNull(Value) or VarIsEmpty(Value) then
    FieldClear
  else
  begin
    SetTextSilent(VarToStr(Value));
    ReportValid;
  end;
end;

end.
