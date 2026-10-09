unit PPG.NumberEdit;

{ TPPGNumberEdit - ein Feld fuer Ganzzahl, Kommazahl, Waehrung und Prozent
  (Phase 12b; Vorbild TMS TAdvEdit EditType, WinUI NumberBox).

  - Ohne Fokus zeigt das Feld formatiert ("1.234,50 EUR"), mit Fokus roh
    ("1234,5"). Gewechselt wird in FocusChanged (nie in Paint), die
    Einfuegemarke bleibt an derselben Ziffer.
  - Eingabe: Ziffern, Trenner, Minus; mit AllowExpressions auch + - * / und
    Klammern ("2*19,99"), ausgerechnet bei Enter und beim Verlassen. Der
    Punkt des Ziffernblocks wird zum Dezimaltrenner des Gebietsschemas.
    Eingefuegtes "1.234,50 EUR" oder "1,234.50" wird erkannt (PPG.NumberFormat).
  - Uebernommen wird bei Enter, beim Verlassen, mit Pfeilen, Spin-Buttons und
    Mausrad (nur mit Fokus). Ungueltige Eingabe: Enter zeigt den Fehler am Feld
    (ValidationState), Verlassen stellt den letzten gueltigen Wert wieder her.
    Esc verwirft die Eingabe.
  - nkCurrency rechnet in Currency (AsCurrency, keine Rundungsfehler bei Geld).
  - MinValue = MaxValue: keine Grenze (wie TSpinEdit); Werte werden still
    begrenzt.
  - OnChange kommt nur, wenn der Anwender den Wert aendert (nicht bei jedem
    Tastendruck und nicht aus Code). Value aus Code loest nichts aus.
  - AllowNull: leeres Feld = kein Wert (IsNull). IPPGFieldValue fuer
    DB-Felder und Grid. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.Variants, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Field, PPG.SpinEdit, PPG.NumberFormat;

type
  TPPGCustomNumberEdit = class(TPPGCustomField, IPPGFieldValue)
  private
    FKind: TPPGNumberKind;
    FValue: Double;
    FCurr: Currency;
    FIsNull: Boolean;
    FAllowNull: Boolean;
    FDecimals: Integer;
    FMinValue: Double;
    FMaxValue: Double;
    FIncrement: Double;
    FLargeIncrement: Double;
    FShowSpinButtons: Boolean;
    FThousandSeparator: Boolean;
    FCurrencyString: string;
    FAllowExpressions: Boolean;
    FEditing: Boolean;
    FOwnError: Boolean;
    FNumpadDecimal: Boolean;
    FUserChange: Boolean;
    FRepeater: TPPGSpinRepeater;
    procedure SetKind(const Value: TPPGNumberKind);
    function GetValue: Double;
    procedure SetValue(const Value: Double);
    function GetAsCurrency: Currency;
    procedure SetAsCurrency(const Value: Currency);
    /// Currency-Wert nur fuer nkCurrency, sonst 0 (Double kann den
    /// Currency-Bereich von +-9,2E14 sprengen).
    function CurrValue: Currency;
    function GetAsInteger: Int64;
    procedure SetAsInteger(const Value: Int64);
    procedure SetIsNull(const Value: Boolean);
    procedure SetAllowNull(const Value: Boolean);
    procedure SetDecimals(const Value: Integer);
    procedure SetMinValue(const Value: Double);
    procedure SetMaxValue(const Value: Double);
    procedure SetIncrement(const Value: Double);
    procedure SetLargeIncrement(const Value: Double);
    procedure SetShowSpinButtons(const Value: Boolean);
    procedure SetThousandSeparator(const Value: Boolean);
    procedure SetCurrencyString(const Value: string);
    function IsMinStored: Boolean;
    function IsMaxStored: Boolean;
    function IsIncrementStored: Boolean;
    function IsLargeIncrementStored: Boolean;
    function IsValueStored: Boolean;
    procedure ReadIsNull(Reader: TReader);
    procedure WriteIsNull(Writer: TWriter);
    procedure SpinSteps(Steps: Integer);
    procedure SpinBy(const Delta: Double);
    procedure SetError(const Hint: string);
    procedure ClearError;
    function EffectiveDecimals: Integer;
    /// Setzt den Wert (begrenzt, gerundet) und den Text; UserAction = OnChange.
    procedure StoreValue(NewValue: Double; NewCurr: Currency; NewNull: Boolean;
      UserAction: Boolean);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    procedure Loaded; override;
    procedure FocusChanged; override;
    procedure Change; override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure FieldKeyPress(var Key: Char); override;
    function WantSpecialKey(Key: Word): Boolean; override;
    procedure GetButtons(var Buttons: TPPGFieldButtons); override;
    function ButtonEnabled(Id: Integer): Boolean; override;
    procedure ButtonDown(Id: Integer); override;
    procedure ButtonUp(Id: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    function AccRole: Integer; override;
    function AccValue: string; override;
    /// Wert begrenzen (MinValue = MaxValue: keine Grenze).
    function Clamp(V: Double): Double;
    { IPPGFieldValue }
    function FieldIsNull: Boolean;
    procedure FieldClear;
    function GetFieldValue: Variant;
    procedure SetFieldValue(const Value: Variant);

    property Kind: TPPGNumberKind read FKind write SetKind default nkFloat;
    property Value: Double read GetValue write SetValue stored IsValueStored;
    property AllowNull: Boolean read FAllowNull write SetAllowNull default False;
    property Decimals: Integer read FDecimals write SetDecimals default 2;
    property Min: Double read FMinValue write SetMinValue stored IsMinStored;
    property Max: Double read FMaxValue write SetMaxValue stored IsMaxStored;
    property Increment: Double read FIncrement write SetIncrement stored IsIncrementStored;
    property LargeIncrement: Double read FLargeIncrement write SetLargeIncrement
      stored IsLargeIncrementStored;
    property ShowSpinButtons: Boolean read FShowSpinButtons write SetShowSpinButtons default False;
    property ShowThousandSeparator: Boolean read FThousandSeparator write SetThousandSeparator
      default True;
    /// '' = FormatSettings.CurrencyString.
    property CurrencyString: string read FCurrencyString write SetCurrencyString;
    property AllowExpressions: Boolean read FAllowExpressions write FAllowExpressions default True;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Eingabe jetzt uebernehmen (wie Enter). False = ungueltig.
    function Commit: Boolean;
    /// Wert um Steps * Increment aendern (wie die Spin-Buttons, mit OnChange).
    procedure Spin(Steps: Integer);
    /// Kein Wert (nur mit AllowNull); aus Code ohne OnChange.
    procedure Clear; override;
    /// Text im Anzeigeformat fuer den aktuellen Wert.
    function DisplayText: string;
    /// Text im Bearbeitungsformat.
    function EditText: string;
    property AsCurrency: Currency read GetAsCurrency write SetAsCurrency;
    property AsInteger: Int64 read GetAsInteger write SetAsInteger;
    property IsNull: Boolean read FIsNull write SetIsNull;
  end;

  TPPGNumberEdit = class(TPPGCustomNumberEdit)
  published
    property RoundedCorners;
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Kind;
    property Decimals;
    property Min;
    property Max;
    property Increment;
    property LargeIncrement;
    property ShowSpinButtons;
    property ShowThousandSeparator;
    property CurrencyString;
    property AllowExpressions;
    property AllowNull;
    property Value;
    property TextHint;
    property TextHintVisibleOnFocus;
    property UseSystemContextMenu;
    property ValidationState;
    property ValidationHint;
    property HighContrastSupport;
    property Align;
    property Alignment default taRightJustify;
    property Anchors;
    property AutoSize default True;
    property BiDiMode;
    property BorderStyle;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
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
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseWheel;
    property OnMouseActivate;
    property DragMode;
    property DragCursor;
    property OnDragDrop;
    property OnDragOver;
    property OnStartDrag;
    property OnEndDrag;
  end;

implementation

uses
  System.Math, Winapi.oleacc, PPG.Lang, PPG.Consts, PPG.Exceptions;

type
  TEditAccess = class(TCustomEdit);

/// Kaufmaennisch runden (halbe Stelle weg von Null). Round/RoundTo der RTL
/// runden zur geraden Ziffer (2,345 -> 2,34) - fuer Geld falsch.
function RoundHalfUp(V: Double; Decimals: Integer): Double;
begin
  Result := SimpleRoundTo(V, -Decimals);
end;

/// Passt V in den Currency-Bereich (und ist endlich)?
function InCurrRange(const V: Double): Boolean;
begin
  Result := PPGIsFinite(V) and (Abs(V) <= 922337203685477.0);
end;

/// Currency exakt auf Decimals (0..4) runden: Currency ist Int64 * 10^-4.
function RoundCurr(C: Currency; Decimals: Integer): Currency;
var
  Raw, F, Q: Int64;
  Neg: Boolean;
begin
  if Decimals >= 4 then
    Exit(C);
  if Decimals < 0 then
    Decimals := 0;
  Raw := PInt64(@C)^;
  F := 1;
  while Decimals < 4 do
  begin
    F := F * 10;
    Inc(Decimals);
  end;
  Neg := Raw < 0;
  if Neg then
    Raw := -Raw;
  Q := (Raw + F div 2) div F * F;
  if Neg then
    Q := -Q;
  PInt64(@Result)^ := Q;
end;

{ TPPGCustomNumberEdit }

constructor TPPGCustomNumberEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FKind := nkFloat;
  FDecimals := 2;
  FIncrement := 1;
  FLargeIncrement := 10;
  FThousandSeparator := True;
  FAllowExpressions := True;
  FRepeater := TPPGSpinRepeater.Create(Self, SpinSteps);
  Alignment := taRightJustify;
  SetTextSilent(DisplayText);
end;

destructor TPPGCustomNumberEdit.Destroy;
begin
  FreeAndNil(FRepeater);
  inherited Destroy;
end;

procedure TPPGCustomNumberEdit.Loaded;
begin
  inherited Loaded;
  // Grenzen sind erst jetzt vollstaendig gelesen
  StoreValue(FValue, FCurr, FIsNull, False);
end;

procedure TPPGCustomNumberEdit.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('IsNull', ReadIsNull, WriteIsNull, FIsNull);
end;

procedure TPPGCustomNumberEdit.ReadIsNull(Reader: TReader);
begin
  FIsNull := Reader.ReadBoolean;
end;

procedure TPPGCustomNumberEdit.WriteIsNull(Writer: TWriter);
begin
  Writer.WriteBoolean(FIsNull);
end;

function TPPGCustomNumberEdit.IsValueStored: Boolean;
begin
  Result := not FIsNull and (FValue <> 0);
end;

function TPPGCustomNumberEdit.IsMinStored: Boolean;
begin
  Result := FMinValue <> 0;
end;

function TPPGCustomNumberEdit.IsMaxStored: Boolean;
begin
  Result := FMaxValue <> 0;
end;

function TPPGCustomNumberEdit.IsIncrementStored: Boolean;
begin
  Result := FIncrement <> 1;
end;

function TPPGCustomNumberEdit.IsLargeIncrementStored: Boolean;
begin
  Result := FLargeIncrement <> 10;
end;

function TPPGCustomNumberEdit.EffectiveDecimals: Integer;
begin
  if FKind = nkInteger then
    Result := 0
  else
    Result := FDecimals;
end;

function TPPGCustomNumberEdit.Clamp(V: Double): Double;
begin
  Result := V;
  // Nur ein stimmiger Bereich begrenzt (gleich oder vertauscht = ohne Grenze);
  // so stoeren Zwischenstaende beim Setzen von MinValue/MaxValue nicht
  if FMinValue < FMaxValue then
  begin
    if Result < FMinValue then
      Result := FMinValue
    else if Result > FMaxValue then
      Result := FMaxValue;
  end;
end;

function TPPGCustomNumberEdit.DisplayText: string;
begin
  if FIsNull then
    Result := ''
  else
    Result := PPGFormatNumber(GetValue, FKind, EffectiveDecimals, FThousandSeparator,
      FCurrencyString, FormatSettings);
end;

function TPPGCustomNumberEdit.EditText: string;
begin
  if FIsNull then
    Result := ''
  else
    Result := PPGFormatEditNumber(GetValue, EffectiveDecimals, FormatSettings);
end;

procedure TPPGCustomNumberEdit.StoreValue(NewValue: Double; NewCurr: Currency;
  NewNull: Boolean; UserAction: Boolean);
var
  Old: Double;
  OldNull: Boolean;
  D: Integer;
begin
  Old := GetValue;
  OldNull := FIsNull;
  if NewNull and not FAllowNull and not (csLoading in ComponentState) then
  begin
    NewNull := False;
    NewValue := 0;
    NewCurr := 0;
  end;
  FIsNull := NewNull;
  if NewNull then
  begin
    FValue := 0;
    FCurr := 0;
  end
  else if not (csLoading in ComponentState) then
  begin
    D := EffectiveDecimals;
    if FKind = nkCurrency then
    begin
      // In Currency rechnen; Grenzen gelten auch hier
      FCurr := NewCurr;
      if FMinValue < FMaxValue then
      begin
        if FCurr < FMinValue then
          FCurr := FMinValue
        else if FCurr > FMaxValue then
          FCurr := FMaxValue;
      end;
      FCurr := RoundCurr(FCurr, D);
      FValue := FCurr;
    end
    else
    begin
      FValue := RoundHalfUp(Clamp(NewValue), System.Math.Min(D, 15));
      FCurr := 0;
    end;
  end
  else
  begin
    FValue := NewValue;
    FCurr := NewCurr;
  end;
  if FEditing then
    SetTextSilent(EditText)
  else
    SetTextSilent(DisplayText);
  Invalidate; // Spin-Buttons an den Grenzen
  if UserAction and ((OldNull <> FIsNull) or (Old <> GetValue)) then
  begin
    FUserChange := True;
    try
      Change;
    finally
      FUserChange := False;
    end;
  end;
end;

function TPPGCustomNumberEdit.GetValue: Double;
begin
  if FKind = nkCurrency then
    Result := FCurr
  else
    Result := FValue;
end;

procedure TPPGCustomNumberEdit.SetValue(const Value: Double);
begin
  // Audit 08.10.2026: NaN bzw. Werte ausserhalb des Currency-Bereichs warfen
  // EInvalidOp aus der RTL (auch bei nkFloat, weil immer nach Currency
  // gewandelt wurde)
  PPGCheckFinite(Self, 'Value', Value);
  // Aus Code: ohne OnChange
  ClearError;
  if FKind = nkCurrency then
  begin
    if not InCurrRange(Value) then
      raise EPPGPropertyError.CreateInvalid(Self, 'Value', FloatToStr(Value));
    StoreValue(Value, Value, False, False);
  end
  else
    StoreValue(Value, 0, False, False);
end;

function TPPGCustomNumberEdit.GetAsCurrency: Currency;
begin
  if FKind = nkCurrency then
    Result := FCurr
  else if InCurrRange(FValue) then
    Result := FValue
  else
    raise EPPGPropertyError.CreateInvalid(Self, 'AsCurrency', FloatToStr(FValue));
end;

function TPPGCustomNumberEdit.CurrValue: Currency;
begin
  if FKind = nkCurrency then
    Result := FCurr
  else
    Result := 0;
end;

procedure TPPGCustomNumberEdit.SetAsCurrency(const Value: Currency);
begin
  ClearError;
  StoreValue(Value, Value, False, False);
end;

function TPPGCustomNumberEdit.GetAsInteger: Int64;
begin
  Result := Trunc(RoundHalfUp(GetValue, 0));
end;

procedure TPPGCustomNumberEdit.SetAsInteger(const Value: Int64);
begin
  SetValue(Value);
end;

procedure TPPGCustomNumberEdit.SetIsNull(const Value: Boolean);
begin
  if Value then
    Clear
  else if FIsNull then
    SetValue(0);
end;

procedure TPPGCustomNumberEdit.Clear;
begin
  ClearError;
  StoreValue(0, 0, True, False);
end;

procedure TPPGCustomNumberEdit.SetAllowNull(const Value: Boolean);
begin
  FAllowNull := Value;
  if not FAllowNull and FIsNull and not (csLoading in ComponentState) then
    SetValue(0);
end;

procedure TPPGCustomNumberEdit.SetKind(const Value: TPPGNumberKind);
var
  V: Double;
begin
  if FKind = Value then
    Exit;
  V := GetValue;
  if (Value = nkCurrency) and not InCurrRange(V) then
    raise EPPGPropertyError.CreateInvalid(Self, 'Kind', FloatToStr(V));
  FKind := Value;
  if Value = nkCurrency then
    StoreValue(V, V, FIsNull, False)
  else
    StoreValue(V, 0, FIsNull, False);
end;

procedure TPPGCustomNumberEdit.SetDecimals(const Value: Integer);
begin
  FDecimals := PPGCheckRange(Self, 'Decimals', Value, 0, 10);
  StoreValue(GetValue, CurrValue, FIsNull, False);
end;

procedure TPPGCustomNumberEdit.SetMinValue(const Value: Double);
begin
  PPGCheckFinite(Self, 'MinValue', Value);
  FMinValue := Value;
  // Wie SpinEdit: nur bei stimmigem Bereich anpassen
  if FMinValue <= FMaxValue then
    StoreValue(GetValue, CurrValue, FIsNull, False);
end;

procedure TPPGCustomNumberEdit.SetMaxValue(const Value: Double);
begin
  PPGCheckFinite(Self, 'MaxValue', Value);
  FMaxValue := Value;
  if FMinValue <= FMaxValue then
    StoreValue(GetValue, CurrValue, FIsNull, False);
end;

procedure TPPGCustomNumberEdit.SetIncrement(const Value: Double);
begin
  // Zur Laufzeit Exception, beim DFM-Laden protokollieren und Wert behalten
  FIncrement := PPGCheckFloat(Self, 'Increment', Value, Value > 0, FIncrement);
end;

procedure TPPGCustomNumberEdit.SetLargeIncrement(const Value: Double);
begin
  FLargeIncrement := PPGCheckFloat(Self, 'LargeIncrement', Value, Value > 0, FLargeIncrement);
end;

procedure TPPGCustomNumberEdit.SetShowSpinButtons(const Value: Boolean);
begin
  if FShowSpinButtons <> Value then
  begin
    FShowSpinButtons := Value;
    UpdateLayout;
    Invalidate;
  end;
end;

procedure TPPGCustomNumberEdit.SetThousandSeparator(const Value: Boolean);
begin
  if FThousandSeparator = Value then
    Exit;
  FThousandSeparator := Value;
  StoreValue(GetValue, CurrValue, FIsNull, False);
end;

procedure TPPGCustomNumberEdit.SetCurrencyString(const Value: string);
begin
  if FCurrencyString = Value then
    Exit;
  FCurrencyString := Value;
  StoreValue(GetValue, CurrValue, FIsNull, False);
end;

procedure TPPGCustomNumberEdit.SetError(const Hint: string);
begin
  FOwnError := True;
  ValidationHint := Hint;
  ValidationState := pvsError;
end;

procedure TPPGCustomNumberEdit.ClearError;
begin
  if not FOwnError then
    Exit;
  FOwnError := False;
  ValidationState := pvsNone;
  ValidationHint := '';
end;

function TPPGCustomNumberEdit.Commit: Boolean;
var
  S: string;
  V: Double;
  C: Currency;
begin
  S := Trim(Text);
  if S = '' then
  begin
    Result := FAllowNull;
    if Result then
    begin
      ClearError;
      StoreValue(0, 0, True, True);
    end
    else
      SetError(PPGStr(@SPPGNumberRequired));
    Exit;
  end;
  // Waehrung ohne Rechnung: direkt in Currency lesen (exakt)
  if (FKind = nkCurrency) and not PPGIsExpression(S) then
  begin
    Result := PPGParseCurrency(S, FormatSettings, C);
    V := C;
  end
  else
  begin
    Result := (FAllowExpressions or not PPGIsExpression(S)) and
      PPGEvalNumber(S, FormatSettings, V) and PPGIsFinite(V);
    // Currency nur fuer nkCurrency bilden; "1000000000000000" ist als Zahl
    // gueltig, sprengt aber Currency (EInvalidOp beim Verlassen des Felds)
    if Result then
    begin
      if FKind = nkCurrency then
      begin
        Result := InCurrRange(V);
        if Result then
          C := RoundHalfUp(V, 4);
      end
      else
        C := 0;
    end;
  end;
  if not Result then
  begin
    SetError(PPGStr(@SPPGNumberInvalid));
    Exit;
  end;
  ClearError;
  StoreValue(V, C, False, True);
end;

procedure TPPGCustomNumberEdit.FocusChanged;
var
  OldText, NewText: string;
  P: Integer;
  WasAll: Boolean;
begin
  if not (csDestroying in ComponentState) and (Inner <> nil) then
  begin
    if FieldFocused and not FEditing then
    begin
      // Bearbeitungsformat; Marke bleibt an derselben Ziffer, eine
      // Gesamtauswahl (AutoSelect per Tab) bleibt erhalten
      FEditing := True;
      OldText := Text;
      P := SelStart;
      WasAll := (OldText <> '') and (SelLength >= Length(OldText));
      NewText := EditText;
      SetTextSilent(NewText);
      if WasAll then
        SelectAll
      else
        SelStart := PPGMapCaretByDigits(OldText, P, NewText, FormatSettings);
    end
    else if not FieldFocused and FEditing then
    begin
      // Verlassen: uebernehmen; ungueltig = letzter gueltiger Wert.
      // FEditing vorher zuruecksetzen: OnChange aus Commit sieht schon den
      // fertigen Zustand (Anzeigeformat), nicht mehr die Bearbeitung.
      FEditing := False;
      if not Commit then
      begin
        ClearError;
        StoreValue(GetValue, CurrValue, FIsNull, False);
      end;
      SetTextSilent(DisplayText);
    end;
  end;
  inherited FocusChanged;
end;

procedure TPPGCustomNumberEdit.Change;
begin
  // OnChange nur fuer Wertaenderungen des Anwenders, nicht je Tastendruck
  if FUserChange then
    inherited Change
  else if FOwnError and not ChangeLocked then
    ClearError; // neue Eingabe: Fehler zuruecksetzen, bis wieder geprueft wird
end;

procedure TPPGCustomNumberEdit.SpinSteps(Steps: Integer);
begin
  Spin(Steps);
end;

procedure TPPGCustomNumberEdit.Spin(Steps: Integer);
begin
  if Steps <> 0 then
    SpinBy(Steps * FIncrement);
end;

procedure TPPGCustomNumberEdit.SpinBy(const Delta: Double);
var
  Base: Double;
  BaseC: Currency;
  NewC: Currency;
begin
  if ReadOnly or not Enabled or (Delta = 0) then
    Exit;
  // Laufende Eingabe zuerst lesen (ungueltig: vom letzten Wert aus)
  if FEditing and (Trim(Text) <> EditText) then
    Commit;
  ClearError;
  Base := GetValue;
  BaseC := CurrValue;
  if FIsNull then
  begin
    Base := 0;
    BaseC := 0;
  end;
  NewC := 0;
  if FKind = nkCurrency then
  begin
    if not InCurrRange(BaseC + Delta) then
      Exit; // am Rand des Currency-Bereichs: kein Schritt
    NewC := BaseC + Delta;
  end;
  StoreValue(Base + Delta, NewC, False, True);
  if FEditing then
    SelectAll;
end;

procedure TPPGCustomNumberEdit.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  FNumpadDecimal := Key = VK_DECIMAL;
  case Key of
    VK_UP: Spin(1);
    VK_DOWN: Spin(-1);
    // Direkt um LargeIncrement (Round(Large / Increment) Schritte ergab bei
    // 0,4/1 keinen Schritt und bei 10/3 nur 9)
    VK_PRIOR: SpinBy(FLargeIncrement);
    VK_NEXT: SpinBy(-FLargeIncrement);
  else
    Exit;
  end;
  Key := 0;
end;

function TPPGCustomNumberEdit.WantSpecialKey(Key: Word): Boolean;
begin
  // Enter uebernimmt; Esc nur, wenn es etwas zu verwerfen gibt
  Result := inherited WantSpecialKey(Key);
  if Key = VK_RETURN then
    Result := FEditing
  else if Key = VK_ESCAPE then
    Result := FEditing and (Trim(Text) <> EditText);
end;

procedure TPPGCustomNumberEdit.FieldKeyPress(var Key: Char);
begin
  case Key of
    #13:
      begin
        if Commit then
          SelectAll;
        Key := #0;
        Exit;
      end;
    #27:
      begin
        // Esc: Eingabe verwerfen
        ClearError;
        SetTextSilent(EditText);
        SelectAll;
        Key := #0;
        Exit;
      end;
  end;
  if Key < #32 then
    Exit;
  // Ziffernblock-Punkt = Dezimaltrenner des Gebietsschemas
  if FNumpadDecimal and ((Key = '.') or (Key = ',')) then
  begin
    FNumpadDecimal := False;
    if FKind = nkInteger then
      Key := #0
    else
      Key := FormatSettings.DecimalSeparator;
    Exit;
  end;
  if CharInSet(Key, ['0'..'9', '-']) then
    Exit;
  if (FKind <> nkInteger) and ((Key = FormatSettings.DecimalSeparator) or (Key = '.') or
    (Key = ',')) then
    Exit;
  if FAllowExpressions and CharInSet(Key, ['+', '*', '/', '(', ')', ' ']) then
    Exit;
  if FAllowExpressions and (FKind = nkInteger) and ((Key = '.') or (Key = ',')) then
    Exit; // "10/4" ergibt Kommazahl, gerundet
  Key := #0;
  MessageBeep(0);
end;

procedure TPPGCustomNumberEdit.GetButtons(var Buttons: TPPGFieldButtons);
var
  N: Integer;
begin
  inherited GetButtons(Buttons);
  if not FShowSpinButtons then
    Exit;
  N := Length(Buttons);
  SetLength(Buttons, N + 2);
  Buttons[N].Id := PPGSpinButtonDown;
  Buttons[N].Glyph := fgSpinDown;
  Buttons[N].ImageIndex := -1;
  Buttons[N].LeftSide := False;
  Buttons[N + 1].Id := PPGSpinButtonUp;
  Buttons[N + 1].Glyph := fgSpinUp;
  Buttons[N + 1].ImageIndex := -1;
  Buttons[N + 1].LeftSide := False;
end;

function TPPGCustomNumberEdit.ButtonEnabled(Id: Integer): Boolean;
begin
  Result := inherited ButtonEnabled(Id) and not ReadOnly;
  if not Result or (FMinValue = FMaxValue) or FIsNull then
    Exit;
  if Id = PPGSpinButtonUp then
    Result := GetValue < FMaxValue
  else if Id = PPGSpinButtonDown then
    Result := GetValue > FMinValue;
end;

procedure TPPGCustomNumberEdit.ButtonDown(Id: Integer);
begin
  if Id = PPGSpinButtonUp then
    FRepeater.Start(Id, 1)
  else if Id = PPGSpinButtonDown then
    FRepeater.Start(Id, -1)
  else
    inherited ButtonDown(Id);
end;

procedure TPPGCustomNumberEdit.ButtonUp(Id: Integer);
begin
  FRepeater.Stop;
  inherited ButtonUp(Id);
end;

function TPPGCustomNumberEdit.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  // Mausrad nur mit Fokus: sonst aendert Scrollen durch ein Formular Werte
  if Result or not FieldFocused or ReadOnly or not Enabled or (WheelDelta = 0) then
    Exit;
  if WheelDelta > 0 then
    Spin(1)
  else
    Spin(-1);
  Result := True;
end;

function TPPGCustomNumberEdit.AccRole: Integer;
begin
  if FShowSpinButtons then
    Result := ROLE_SYSTEM_SPINBUTTON
  else
    Result := ROLE_SYSTEM_TEXT;
end;

function TPPGCustomNumberEdit.AccValue: string;
begin
  Result := DisplayText;
end;

{ IPPGFieldValue }

function TPPGCustomNumberEdit.FieldIsNull: Boolean;
begin
  Result := FIsNull;
end;

procedure TPPGCustomNumberEdit.FieldClear;
begin
  Clear;
end;

function TPPGCustomNumberEdit.GetFieldValue: Variant;
begin
  if FIsNull then
    Result := Null
  else if FKind = nkCurrency then
    Result := FCurr
  else if FKind = nkInteger then
    Result := Trunc(RoundHalfUp(FValue, 0))
  else
    Result := FValue;
end;

procedure TPPGCustomNumberEdit.SetFieldValue(const Value: Variant);
begin
  if VarIsNull(Value) or VarIsEmpty(Value) then
    Clear
  else if FKind = nkCurrency then
    SetAsCurrency(Value)
  else
    SetValue(Value);
end;

end.
