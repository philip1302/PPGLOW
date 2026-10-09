unit PPG.Validator;

{ Formularweite Eingabepruefung (Phase 19a).

  TPPGValidator (nicht sichtbar): Regeln je Control im Designer statt
  Pruefcode im Formular.
  - Regelarten: Pflicht, Laenge, Bereich (Zahl oder Datum), Muster (eigener
    regulaerer Ausdruck oder E-Mail, Telefon, PLZ, IBAN mit Pruefsumme),
    Vergleich mit einem anderen Control, eigene Regel per OnValidate.
  - Leere Werte prueft nur die Pflicht-Regel (und OnValidate); die uebrigen
    greifen erst, wenn etwas eingegeben ist.
  - Je Control gilt das erste Ergebnis: der erste Fehler, sonst die erste
    Warnung (Reihenfolge der Regeln).
  - Werte liest ein Adapter je Control-Klasse (PPGRegisterValidationAdapter,
    der zuletzt registrierte passende gewinnt). Eingebaut: PPGlow-Felder
    (IPPGFieldValue, DatePicker, SpinEdit, sonst Text), Auswahlgruppen,
    Kaestchen/Schalter und die VCL-Pendants (Edit, ComboBox, CheckBox,
    DateTimePicker).
  - Markiert wird ueber ValidationState/ValidationHint (Tooltip und
    Screenreader). Der Validator setzt nur zurueck, was er selbst gesetzt hat:
    hat jemand anderes (z.B. ein DB-Feld) den Zustand inzwischen geaendert,
    bleibt er stehen. Controls ohne ValidationState erscheinen nur in Results
    und OnShowError.
  - Automatisch pruefen (ValidateOn): beim Verlassen (CM_EXIT) bzw. bei jeder
    Aenderung. Ein Control mit Ergebnis prueft bei jeder Aenderung sofort neu,
    damit der Fehler verschwindet, sobald er behoben ist. Aenderungen melden
    die PPGlow-Controls per CM_PPGVALUECHANGED, VCL-Controls ueber ihre
    Benachrichtigungen (CN_COMMAND, CN_NOTIFY). Die Pruefung laeuft danach
    ueber eine gepostete Nachricht, nie mitten in OnChange.
  - Ausgeblendete und gesperrte Controls zaehlen nicht; Controls auf nicht
    aktiven Reitern schon (sie sind nur verdeckt, auch bei TabVisible = False),
    ebenso auf nicht aktiven Seiten des Assistenten (ausser PageVisible = False).
  - FocusFirstError: erster Fehler in Tab-Reihenfolge; aktiviert unterwegs
    Reiter, klappt Expander auf und scrollt ihn ins Bild. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.Variants,
  System.Generics.Collections, System.RegularExpressions, Vcl.Controls, Vcl.Forms,
  PPG.Types, PPG.Controls.Field, PPG.Feedback, PPG.Wizard;

type
  TPPGValidationRuleKind = (vrRequired, vrLength, vrRange, vrPattern, vrCompare, vrCustom);
  TPPGValidationPattern = (vpCustom, vpEmail, vpPhone, vpPostalCodeDE, vpIBAN);
  TPPGCompareOperator = (coEqual, coNotEqual, coLess, coLessOrEqual, coGreater, coGreaterOrEqual);
  /// Wann automatisch geprueft wird: nur auf Aufruf, beim Verlassen, bei jeder Aenderung.
  TPPGValidateOn = (voSubmit, voExit, voChange);

  TPPGValidator = class;

  /// Eine Regel fuer ein Control.
  TPPGValidationRule = class(TCollectionItem)
  private
    FControl: TControl;
    FKind: TPPGValidationRuleKind;
    FEnabled: Boolean;
    FSeverity: TPPGValidationState;
    FCaption: string;
    FMessage: string;
    FGroup: string;
    FMinLength: Integer;
    FMaxLength: Integer;
    FMinValue: string;
    FMaxValue: string;
    FPatternKind: TPPGValidationPattern;
    FPattern: string;
    FCompareControl: TControl;
    FCompareOperator: TPPGCompareOperator;
    FRegex: TRegEx;
    FRegexReady: Boolean;
    function Validator: TPPGValidator;
    procedure SetControl(const Value: TControl);
    procedure SetCompareControl(const Value: TControl);
    procedure SetKind(const Value: TPPGValidationRuleKind);
    procedure SetEnabled(const Value: Boolean);
    procedure SetSeverity(const Value: TPPGValidationState);
    procedure SetMinLength(const Value: Integer);
    procedure SetMaxLength(const Value: Integer);
    procedure SetMinValue(const Value: string);
    procedure SetMaxValue(const Value: string);
    procedure SetPatternKind(const Value: TPPGValidationPattern);
    procedure SetPattern(const Value: string);
    function CheckBound(const PropName, Value: string): Boolean;
    /// Beim DFM-Laden: melden statt werfen (Formular oeffnet sich trotzdem).
    function RejectValue(const PropName, Value: string): Boolean;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    /// Name des Felds in Meldungen: Caption, sonst Beschriftung (Label mit
    /// FocusControl), Platzhaltertext oder Name des Controls.
    function FieldCaption: string;
    /// Passt S zum Muster (PatternKind bzw. Pattern)? Leer passt immer.
    function MatchesPattern(const S: string): Boolean;
  published
    property Control: TControl read FControl write SetControl;
    property Kind: TPPGValidationRuleKind read FKind write SetKind default vrRequired;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    /// pvsError (Vorgabe) oder pvsWarning; Warnungen halten Validate nicht auf.
    property Severity: TPPGValidationState read FSeverity write SetSeverity default pvsError;
    /// Name des Felds in Meldungen ('' = automatisch).
    property Caption: string read FCaption write FCaption;
    /// Eigene Meldung ('' = Standardtext); {caption} wird durch den Feldnamen ersetzt.
    property Message: string read FMessage write FMessage;
    /// Nur pruefen, wenn ValidateGroup diese Gruppe nennt ('' = immer dabei).
    property Group: string read FGroup write FGroup;
    /// vrLength: Mindest- und Hoechstlaenge (0 = keine Grenze).
    property MinLength: Integer read FMinLength write SetMinLength default 0;
    property MaxLength: Integer read FMaxLength write SetMaxLength default 0;
    /// vrRange: Grenzen als Zahl ("12.5", Punkt als Dezimaltrenner) oder
    /// Datum ("2026-12-31"); leer = keine Grenze.
    property MinValue: string read FMinValue write SetMinValue;
    property MaxValue: string read FMaxValue write SetMaxValue;
    property PatternKind: TPPGValidationPattern read FPatternKind write SetPatternKind default vpCustom;
    /// vrPattern mit vpCustom: regulaerer Ausdruck fuer den ganzen Wert.
    property Pattern: string read FPattern write SetPattern;
    /// vrCompare: Vergleichs-Control und Operator (Wert dieses Controls OP Vergleichswert).
    property CompareControl: TControl read FCompareControl write SetCompareControl;
    property CompareOperator: TPPGCompareOperator read FCompareOperator write FCompareOperator default coEqual;
  end;

  TPPGValidationRules = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGValidationRule;
    procedure SetItem(Index: Integer; const Value: TPPGValidationRule);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPPGValidator);
    function Add: TPPGValidationRule;
    /// Kurzform: neue Regel fuer AControl.
    function AddRule(AControl: TControl; AKind: TPPGValidationRuleKind): TPPGValidationRule;
    property Items[Index: Integer]: TPPGValidationRule read GetItem write SetItem; default;
  end;

  /// Ergebnis fuer ein Control (Fehler oder Warnung).
  TPPGValidationResult = record
    Control: TControl;
    /// nil bei einer Regel aus dem Datenfeld (AutoFieldRules).
    Rule: TPPGValidationRule;
    Message: string;
    Severity: TPPGValidationState;
    /// Name des Felds wie in der Meldung.
    Caption: string;
  end;

  /// Liest Werte einer Control-Klasse und markiert sie (offen erweiterbar).
  TPPGValidationAdapter = class
  public
    class function Handles(AControl: TControl): Boolean; virtual; abstract;
    /// Null = leer; sonst string, Zahl, Datum (varDate) oder Boolean.
    class function GetValue(AControl: TControl): Variant; virtual; abstract;
    class function CanMark(AControl: TControl): Boolean; virtual;
    class function GetMark(AControl: TControl): TPPGValidationState; virtual;
    class procedure SetMark(AControl: TControl; State: TPPGValidationState;
      const Hint: string); virtual;
    /// Name fuer Meldungen ('' = Beschriftung per Label bzw. Name).
    class function Caption(AControl: TControl): string; virtual;
    /// Meldung der Pflicht-Regel (Kaestchen: "muss angekreuzt sein").
    class function RequiredText: PResStringRec; virtual;
  end;
  TPPGValidationAdapterClass = class of TPPGValidationAdapter;

  TPPGValidateRuleEvent = procedure(Sender: TObject; Rule: TPPGValidationRule;
    const Value: Variant; var Valid: Boolean; var Message: string) of object;
  TPPGShowErrorEvent = procedure(Sender: TObject; Control: TControl;
    const Message: string; Severity: TPPGValidationState) of object;

  /// Regeln, die ein Datenfeld selbst mitbringt (TField: Required, Size,
  /// MinValue/MaxValue). Liefert das DB-Paket (PPG.DB.Validator).
  TPPGFieldRuleInfo = record
    /// Datenmenge in Bearbeitung (dsEdit/dsInsert); sonst wird nicht geprueft.
    Editing: Boolean;
    Required: Boolean;
    /// Hoechstlaenge (0 = keine).
    MaxLength: Integer;
    HasMin: Boolean;
    HasMax: Boolean;
    MinValue: Double;
    MaxValue: Double;
    /// Name fuer Meldungen (DisplayLabel); '' = wie bei Regeln.
    Caption: string;
  end;
  TPPGFieldRuleProvider = function(AControl: TControl; out Info: TPPGFieldRuleInfo): Boolean;

  TPPGValidator = class(TComponent)
  private
    FRules: TPPGValidationRules;
    FActive: Boolean;
    FValidateOn: TPPGValidateOn;
    FShowValid: Boolean;
    FResults: TList<TPPGValidationResult>;
    FMarks: TDictionary<TControl, TPPGValidationState>;
    FTouched: TList<TControl>;
    FWatched: TList<TControl>;
    FPendingExit: TList<TControl>;
    FPendingChange: TList<TControl>;
    FWnd: HWND;
    FPosted: Boolean;
    FOnValidate: TPPGValidateRuleEvent;
    FOnValidated: TNotifyEvent;
    FOnShowError: TPPGShowErrorEvent;
    FAutoFieldRules: Boolean;
    FSummaryBar: TPPGCustomInfoBar;
    FSummaryShown: Boolean;
    FOldBarAction: TNotifyEvent;
    FBarHooked: Boolean;
    FCheckOnClose: Boolean;
    FForm: TCustomForm;
    FOldCloseQuery: TCloseQueryEvent;
    FFormHooked: Boolean;
    FSubmitControl: TControl;
    FWizard: TPPGWizard;
    FOldCanAdvance: TPPGWizardCanAdvanceEvent;
    FWizardHooked: Boolean;
    procedure SetRules(const Value: TPPGValidationRules);
    procedure SetSummaryBar(const Value: TPPGCustomInfoBar);
    procedure SetSubmitControl(const Value: TControl);
    procedure SetWizard(const Value: TPPGWizard);
    procedure SetAutoFieldRules(const Value: Boolean);
    procedure AttachHooks;
    procedure DetachBar;
    procedure DetachForm;
    procedure DetachWizard;
    procedure BarAction(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure WizardCanAdvance(Sender: TObject; Page: TPPGWizardPage; var Allow: Boolean);
    procedure UpdateSummary;
    procedure UpdateSubmit;
    function FieldInfo(AControl: TControl; out Info: TPPGFieldRuleInfo): Boolean;
    function CheckFieldRules(AControl: TControl; const Info: TPPGFieldRuleInfo;
      RequiredOnly: Boolean; out Msg: string): Boolean;
    procedure SetActive(const Value: Boolean);
    procedure SetShowValid(const Value: Boolean);
    function GetResult(Index: Integer): TPPGValidationResult;
    function GetResultCount: Integer;
    function IsRuntime: Boolean;
    procedure UpdateWatches;
    procedure ControlMessage(Control: TControl; var Message: TMessage);
    procedure Schedule(AControl: TControl; Exiting: Boolean);
    procedure WndProc(var Message: TMessage);
    procedure ProcessPending;
    function IndexOfResult(AControl: TControl): Integer;
    function CheckRule(Rule: TPPGValidationRule; out Msg: string): Boolean;
    function EvaluateControl(AControl: TControl; const AGroup: string; UseGroup: Boolean;
      out Res: TPPGValidationResult): Boolean;
    procedure ApplyResult(AControl: TControl; HasIssue: Boolean; const Res: TPPGValidationResult);
    procedure MarkControl(AControl: TControl; State: TPPGValidationState; const Hint: string);
    function ValidateList(List: TList<TControl>; const AGroup: string; UseGroup: Boolean): Boolean;
    procedure CollectControls(List: TList<TControl>; AContainer: TWinControl;
      const AGroup: string; UseGroup: Boolean);
    procedure AddDependents(List: TList<TControl>; AControl: TControl);
    procedure SortResults;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Loaded; override;
    procedure RulesChanged; virtual;
    procedure DoValidated; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Prueft alle Regeln; True = kein Fehler (Warnungen erlaubt).
    function Validate: Boolean;
    /// Nur Regeln ohne Gruppe und der Gruppe AGroup.
    function ValidateGroup(const AGroup: string): Boolean;
    /// Nur Controls in AParent (z.B. eine Seite des Assistenten).
    function ValidateChildren(AParent: TWinControl): Boolean;
    function ValidateControl(AControl: TControl): Boolean;
    /// Nimmt alle Ergebnisse und die eigenen Markierungen zurueck.
    procedure ClearResults;
    /// Fokus auf den ersten Fehler (Tab-Reihenfolge), Reiter/Expander/Scrollen
    /// unterwegs; False = kein Fehler.
    function FocusFirstError: Boolean;
    function ResultFor(AControl: TControl; out Res: TPPGValidationResult): Boolean;
    function ErrorCount: Integer;
    function WarningCount: Integer;
    /// Fehler und Warnungen in Tab-Reihenfolge.
    property Results[Index: Integer]: TPPGValidationResult read GetResult;
    property ResultCount: Integer read GetResultCount;
  published
    /// False: keine automatische Pruefung, Validate liefert immer True.
    property Active: Boolean read FActive write SetActive default True;
    property ValidateOn: TPPGValidateOn read FValidateOn write FValidateOn default voExit;
    /// Gepruefte Felder ohne Fehler gruen markieren (pvsValid).
    property ShowValid: Boolean read FShowValid write SetShowValid default False;
    property Rules: TPPGValidationRules read FRules write SetRules;
    /// Regeln der Art vrCustom: Valid und Message setzen.
    property OnValidate: TPPGValidateRuleEvent read FOnValidate write FOnValidate;
    /// Nach jeder Pruefung (auch der automatischen).
    property OnValidated: TNotifyEvent read FOnValidated write FOnValidated;
    /// Ergebnis eines Controls hat sich geaendert (Severity pvsNone = behoben).
    property OnShowError: TPPGShowErrorEvent read FOnShowError write FOnShowError;
    /// DB-Controls ohne eigene Regel nach ihrem TField pruefen (Required,
    /// Size, MinValue/MaxValue), solange die Datenmenge bearbeitet wird.
    property AutoFieldRules: Boolean read FAutoFieldRules write SetAutoFieldRules default True;
    /// Sammelanzeige nach dem ersten Validate: Zahl und Namen der Fehler,
    /// Knopf "Zum Fehler"; ohne Ergebnis zugeklappt (IsOpen).
    property SummaryBar: TPPGCustomInfoBar read FSummaryBar write SetSummaryBar;
    /// Schliessen des Formulars mit mrOk/mrYes nur bei gueltigen Eingaben
    /// (ein vorhandenes OnCloseQuery bleibt wirksam).
    property CheckOnClose: Boolean read FCheckOnClose write FCheckOnClose default True;
    /// Wird gesperrt, solange Pflichtfelder leer sind (z.B. der OK-Knopf).
    property SubmitControl: TControl read FSubmitControl write SetSubmitControl;
    /// "Weiter" im Assistenten erst, wenn die aktuelle Seite gueltig ist.
    property Wizard: TPPGWizard read FWizard write SetWizard;
  end;

/// Meldet die Quelle der Feldregeln an (nil = keine); PPG.DB.Validator.
procedure PPGSetFieldRuleProvider(Provider: TPPGFieldRuleProvider);

procedure PPGRegisterValidationAdapter(AClass: TPPGValidationAdapterClass);
procedure PPGUnregisterValidationAdapter(AClass: TPPGValidationAdapterClass);
/// Passender Adapter oder nil.
function PPGFindValidationAdapter(AControl: TControl): TPPGValidationAdapterClass;
/// Null, Leer, leerer/nur Leerzeichen-Text und False gelten als leer.
function PPGValidationValueIsEmpty(const Value: Variant): Boolean;
/// IBAN mit Laendercode und Pruefsumme (Leerzeichen erlaubt).
function PPGCheckIBAN(const S: string): Boolean;
/// Beschriftung eines Controls: Label mit FocusControl, '' wenn keins.
function PPGFindLabelCaption(AControl: TControl): string;

implementation

uses
  System.Math, System.TypInfo, System.RegularExpressionsCore, Winapi.CommCtrl,
  Vcl.StdCtrls, Vcl.ComCtrls,
  PPG.Exceptions, PPG.ErrorHandler, PPG.Lang, PPG.Consts, PPG.AppHooks, PPG.Accessibility,
  PPG.Controls.Check, PPG.RadioGroup, PPG.DatePicker, PPG.SpinEdit, PPG.PageControl,
  PPG.Expander, PPG.Panel;

const
  WM_PPGVALIDATE = WM_USER + $560;
  PatternEmail = '[^@\s]+@[^@\s.]+(\.[^@\s.]+)+';
  PatternPhone = '\+?[0-9][0-9 ()/\-]{4,}[0-9]';
  PatternPostalDE = '[0-9]{5}';

type
  TControlAccess = class(TControl);
  TFieldAccess = class(TPPGCustomField);
  TLabelAccess = class(TCustomLabel);
  TCheckBoxAccess = class(TCustomCheckBox);
  TDatePickerAccess = class(TPPGCustomDatePicker);
  TSpinEditAccess = class(TPPGCustomSpinEdit);
  TChoiceAccess = class(TPPGCustomChoiceGroup);
  TCheckControlAccess = class(TPPGCustomCheckControl);
  TExpanderAccess = class(TPPGCustomExpander);

var
  GAdapters: TList<TPPGValidationAdapterClass>;
  GInvariant: TFormatSettings;
  GFieldRuleProvider: TPPGFieldRuleProvider;

{ Hilfen }

/// Zahlen mit Punkt als Dezimaltrenner (MinValue/MaxValue)
function Invariant: TFormatSettings;
begin
  Result := GInvariant;
end;

/// "2026-12-31" (auch mit Uhrzeit "2026-12-31 14:30")
function TryParseIsoDate(const S: string; out D: TDateTime): Boolean;
var
  Y, M, Dd, H, N: Integer;
  T: string;
begin
  Result := False;
  T := Trim(S);
  if (Length(T) < 10) or (T[5] <> '-') or (T[8] <> '-') then
    Exit;
  if not TryStrToInt(Copy(T, 1, 4), Y) or not TryStrToInt(Copy(T, 6, 2), M) or
    not TryStrToInt(Copy(T, 9, 2), Dd) then
    Exit;
  if not TryEncodeDate(Y, M, Dd, D) then
    Exit;
  H := 0;
  N := 0;
  if Length(T) > 10 then
  begin
    if (Length(T) <> 16) or not CharInSet(T[11], [' ', 'T']) or (T[14] <> ':') or
      not TryStrToInt(Copy(T, 12, 2), H) or not TryStrToInt(Copy(T, 15, 2), N) or
      (H > 23) or (N > 59) then
      Exit;
    D := D + EncodeTime(H, N, 0, 0);
  end;
  Result := True;
end;

/// Grenze aus MinValue/MaxValue: Zahl (Punkt) oder ISO-Datum.
function TryParseBound(const S: string; out D: Double; out IsDate: Boolean): Boolean;
var
  Dt: TDateTime;
begin
  IsDate := False;
  if TryParseIsoDate(S, Dt) then
  begin
    D := Dt;
    IsDate := True;
    Exit(True);
  end;
  Result := TryStrToFloat(Trim(S), D, Invariant);
end;

/// Wert als Zahl: Zahl, Datum (als TDateTime) oder Text (Gebietsschema,
/// dann Punkt, dann Datum).
function TryValueToNumber(const V: Variant; out D: Double): Boolean;
var
  S: string;
  Dt: TDateTime;
begin
  Result := False;
  if VarIsNull(V) or VarIsEmpty(V) then
    Exit;
  case VarType(V) and varTypeMask of
    varDate:
      begin
        D := VarToDateTime(V);
        Exit(True);
      end;
    varBoolean:
      Exit;
  end;
  if VarIsNumeric(V) then
  begin
    D := V;
    Exit(True);
  end;
  S := Trim(VarToStr(V));
  if TryStrToFloat(S, D) or TryStrToFloat(S, D, Invariant) then
    Exit(True);
  if TryStrToDateTime(S, Dt) then
  begin
    D := Dt;
    Exit(True);
  end;
end;

function IsDateValue(const V: Variant): Boolean;
begin
  Result := (VarType(V) and varTypeMask) = varDate;
end;

function FormatBound(D: Double; IsDate: Boolean): string;
begin
  if IsDate then
  begin
    if Frac(D) = 0 then
      Result := DateToStr(D)
    else
      Result := DateTimeToStr(D);
  end
  else
    Result := FloatToStr(D);
end;

function PPGValidationValueIsEmpty(const Value: Variant): Boolean;
begin
  if VarIsNull(Value) or VarIsEmpty(Value) then
    Exit(True);
  if (VarType(Value) and varTypeMask) = varBoolean then
    Exit(not Boolean(Value));
  if VarIsStr(Value) then
    Exit(Trim(VarToStr(Value)) = '');
  Result := False;
end;

function PPGCheckIBAN(const S: string): Boolean;
var
  T: string;
  I, R, V: Integer;
  C: Char;
begin
  Result := False;
  T := UpperCase(StringReplace(S, ' ', '', [rfReplaceAll]));
  if (Length(T) < 15) or (Length(T) > 34) then
    Exit;
  if not CharInSet(T[1], ['A'..'Z']) or not CharInSet(T[2], ['A'..'Z']) or
    not CharInSet(T[3], ['0'..'9']) or not CharInSet(T[4], ['0'..'9']) then
    Exit;
  // Laendercode und Pruefziffern ans Ende, Buchstaben als 10..35, mod 97 = 1
  T := Copy(T, 5, MaxInt) + Copy(T, 1, 4);
  R := 0;
  for I := 1 to Length(T) do
  begin
    C := T[I];
    if CharInSet(C, ['0'..'9']) then
      R := (R * 10 + Ord(C) - Ord('0')) mod 97
    else if CharInSet(C, ['A'..'Z']) then
    begin
      V := Ord(C) - Ord('A') + 10;
      R := (R * 100 + V) mod 97;
    end
    else
      Exit;
  end;
  Result := R = 1;
end;

function PPGFindLabelCaption(AControl: TControl): string;
var
  I: Integer;
  C: TControl;
  Inner: TControl;
begin
  Result := '';
  if (AControl = nil) or (AControl.Parent = nil) then
    Exit;
  Inner := nil;
  if AControl is TPPGCustomField then
    Inner := TFieldAccess(AControl).Inner;
  for I := 0 to AControl.Parent.ControlCount - 1 do
  begin
    C := AControl.Parent.Controls[I];
    if (C is TCustomLabel) and ((TLabelAccess(C).FocusControl = AControl) or
      ((Inner <> nil) and (TLabelAccess(C).FocusControl = Inner))) then
    begin
      Result := Trim(PPGAccStripHotkey(TLabelAccess(C).Caption));
      // "Name:" -> "Name"
      while (Result <> '') and CharInSet(Result[Length(Result)], [':', '*']) do
        Result := Trim(Copy(Result, 1, Length(Result) - 1));
      if Result <> '' then
        Exit;
    end;
  end;
end;

procedure PPGSetFieldRuleProvider(Provider: TPPGFieldRuleProvider);
begin
  GFieldRuleProvider := Provider;
end;

{ Adapter-Registry }

procedure PPGRegisterValidationAdapter(AClass: TPPGValidationAdapterClass);
begin
  if AClass = nil then
    Exit;
  if GAdapters = nil then
    GAdapters := TList<TPPGValidationAdapterClass>.Create;
  GAdapters.Remove(AClass);
  GAdapters.Add(AClass);
end;

procedure PPGUnregisterValidationAdapter(AClass: TPPGValidationAdapterClass);
begin
  if GAdapters <> nil then
    GAdapters.Remove(AClass);
end;

function PPGFindValidationAdapter(AControl: TControl): TPPGValidationAdapterClass;
var
  I: Integer;
begin
  Result := nil;
  if (AControl = nil) or (GAdapters = nil) then
    Exit;
  for I := GAdapters.Count - 1 downto 0 do
    if GAdapters[I].Handles(AControl) then
      Exit(GAdapters[I]);
end;

/// Name eines Controls in Meldungen: Adapter (Label, Platzhalter, Caption),
/// sonst Label, sonst Name.
function ControlCaption(AControl: TControl): string;
var
  A: TPPGValidationAdapterClass;
begin
  Result := '';
  A := PPGFindValidationAdapter(AControl);
  if A <> nil then
    Result := A.Caption(AControl);
  if Result = '' then
    Result := PPGFindLabelCaption(AControl);
  if Result = '' then
    Result := AControl.Name;
end;

function AdapterFor(AControl: TControl): TPPGValidationAdapterClass;
begin
  Result := PPGFindValidationAdapter(AControl);
  if Result = nil then
    raise EPPGError.CreateFmt(PPGStr(@SPPGValUnsupported), [AControl.Name, AControl.ClassName]);
end;

{ TPPGValidationAdapter }

class function TPPGValidationAdapter.CanMark(AControl: TControl): Boolean;
begin
  Result := False;
end;

class function TPPGValidationAdapter.GetMark(AControl: TControl): TPPGValidationState;
begin
  Result := pvsNone;
end;

class procedure TPPGValidationAdapter.SetMark(AControl: TControl; State: TPPGValidationState;
  const Hint: string);
begin
end;

class function TPPGValidationAdapter.Caption(AControl: TControl): string;
begin
  Result := '';
end;

class function TPPGValidationAdapter.RequiredText: PResStringRec;
begin
  Result := @SPPGValRequired;
end;

type
  /// PPGlow-Felder (Edit, Memo, Zahl, Maske, Combo, Datum ...)
  TFieldAdapter = class(TPPGValidationAdapter)
  public
    class function Handles(AControl: TControl): Boolean; override;
    class function GetValue(AControl: TControl): Variant; override;
    class function CanMark(AControl: TControl): Boolean; override;
    class function GetMark(AControl: TControl): TPPGValidationState; override;
    class procedure SetMark(AControl: TControl; State: TPPGValidationState;
      const Hint: string); override;
    class function Caption(AControl: TControl): string; override;
  end;

  TChoiceAdapter = class(TPPGValidationAdapter)
  public
    class function Handles(AControl: TControl): Boolean; override;
    class function GetValue(AControl: TControl): Variant; override;
    class function CanMark(AControl: TControl): Boolean; override;
    class function GetMark(AControl: TControl): TPPGValidationState; override;
    class procedure SetMark(AControl: TControl; State: TPPGValidationState;
      const Hint: string); override;
    class function Caption(AControl: TControl): string; override;
    class function RequiredText: PResStringRec; override;
  end;

  /// Kaestchen, Schalter, Optionsfeld (PPGlow)
  TCheckAdapter = class(TPPGValidationAdapter)
  public
    class function Handles(AControl: TControl): Boolean; override;
    class function GetValue(AControl: TControl): Variant; override;
    class function Caption(AControl: TControl): string; override;
    class function RequiredText: PResStringRec; override;
  end;

  TVclEditAdapter = class(TPPGValidationAdapter)
  public
    class function Handles(AControl: TControl): Boolean; override;
    class function GetValue(AControl: TControl): Variant; override;
  end;

  TVclComboAdapter = class(TPPGValidationAdapter)
  public
    class function Handles(AControl: TControl): Boolean; override;
    class function GetValue(AControl: TControl): Variant; override;
  end;

  TVclCheckAdapter = class(TPPGValidationAdapter)
  public
    class function Handles(AControl: TControl): Boolean; override;
    class function GetValue(AControl: TControl): Variant; override;
    class function Caption(AControl: TControl): string; override;
    class function RequiredText: PResStringRec; override;
  end;

  TVclDateAdapter = class(TPPGValidationAdapter)
  public
    class function Handles(AControl: TControl): Boolean; override;
    class function GetValue(AControl: TControl): Variant; override;
  end;

{ TFieldAdapter }

class function TFieldAdapter.Handles(AControl: TControl): Boolean;
begin
  Result := AControl is TPPGCustomField;
end;

class function TFieldAdapter.GetValue(AControl: TControl): Variant;
var
  FV: IPPGFieldValue;
  D: TDatePickerAccess;
begin
  if AControl is TPPGCustomDatePicker then
  begin
    D := TDatePickerAccess(AControl);
    if D.ShowCheckbox and not D.Checked then
      Exit(Null);
    if D.Kind = dtkTime then
      Exit(VarFromDateTime(Frac(D.Time)));
    Exit(VarFromDateTime(D.Date));
  end;
  if Supports(AControl, IPPGFieldValue, FV) then
  begin
    if FV.FieldIsNull then
      Exit(Null);
    Exit(FV.GetFieldValue);
  end;
  if AControl is TPPGCustomSpinEdit then
  begin
    if Trim(TFieldAccess(AControl).Text) = '' then
      Exit(Null);
    Exit(TSpinEditAccess(AControl).Value);
  end;
  Result := TFieldAccess(AControl).Text;
end;

class function TFieldAdapter.CanMark(AControl: TControl): Boolean;
begin
  Result := True;
end;

class function TFieldAdapter.GetMark(AControl: TControl): TPPGValidationState;
begin
  Result := TFieldAccess(AControl).ValidationState;
end;

class procedure TFieldAdapter.SetMark(AControl: TControl; State: TPPGValidationState;
  const Hint: string);
begin
  // Zuerst der Text: der Setter des Zustands uebernimmt ihn als Hint
  TFieldAccess(AControl).ValidationHint := Hint;
  TFieldAccess(AControl).ValidationState := State;
end;

class function TFieldAdapter.Caption(AControl: TControl): string;
begin
  Result := PPGFindLabelCaption(AControl);
  if Result = '' then
    Result := Trim(TFieldAccess(AControl).TextHint);
end;

{ TChoiceAdapter }

class function TChoiceAdapter.Handles(AControl: TControl): Boolean;
begin
  Result := AControl is TPPGCustomChoiceGroup;
end;

class function TChoiceAdapter.GetValue(AControl: TControl): Variant;
var
  G: TChoiceAccess;
begin
  G := TChoiceAccess(AControl);
  if G.Multi then
    Exit(G.Value);
  if G.ItemIndex < 0 then
    Exit(Null);
  Result := G.Value;
end;

class function TChoiceAdapter.CanMark(AControl: TControl): Boolean;
begin
  Result := True;
end;

class function TChoiceAdapter.GetMark(AControl: TControl): TPPGValidationState;
begin
  Result := TChoiceAccess(AControl).ValidationState;
end;

class procedure TChoiceAdapter.SetMark(AControl: TControl; State: TPPGValidationState;
  const Hint: string);
begin
  TChoiceAccess(AControl).ValidationState := State;
end;

class function TChoiceAdapter.Caption(AControl: TControl): string;
begin
  Result := PPGFindLabelCaption(AControl);
  if Result = '' then
    Result := Trim(PPGAccStripHotkey(TControlAccess(AControl).Caption));
end;

class function TChoiceAdapter.RequiredText: PResStringRec;
begin
  Result := @SPPGValMustChoose;
end;

{ TCheckAdapter }

class function TCheckAdapter.Handles(AControl: TControl): Boolean;
begin
  Result := AControl is TPPGCustomCheckControl;
end;

class function TCheckAdapter.GetValue(AControl: TControl): Variant;
begin
  Result := TCheckControlAccess(AControl).Checked;
end;

class function TCheckAdapter.Caption(AControl: TControl): string;
begin
  Result := Trim(PPGAccStripHotkey(TControlAccess(AControl).Caption));
end;

class function TCheckAdapter.RequiredText: PResStringRec;
begin
  Result := @SPPGValMustCheck;
end;

{ VCL }

class function TVclEditAdapter.Handles(AControl: TControl): Boolean;
begin
  Result := AControl is TCustomEdit;
end;

class function TVclEditAdapter.GetValue(AControl: TControl): Variant;
begin
  Result := TControlAccess(AControl).Text;
end;

class function TVclComboAdapter.Handles(AControl: TControl): Boolean;
begin
  Result := AControl is TCustomComboBox;
end;

class function TVclComboAdapter.GetValue(AControl: TControl): Variant;
begin
  Result := TControlAccess(AControl).Text;
end;

class function TVclCheckAdapter.Handles(AControl: TControl): Boolean;
begin
  Result := AControl is TCustomCheckBox;
end;

class function TVclCheckAdapter.GetValue(AControl: TControl): Variant;
begin
  Result := TCheckBoxAccess(AControl).Checked;
end;

class function TVclCheckAdapter.Caption(AControl: TControl): string;
begin
  Result := Trim(PPGAccStripHotkey(TControlAccess(AControl).Caption));
end;

class function TVclCheckAdapter.RequiredText: PResStringRec;
begin
  Result := @SPPGValMustCheck;
end;

class function TVclDateAdapter.Handles(AControl: TControl): Boolean;
begin
  Result := AControl is TDateTimePicker;
end;

class function TVclDateAdapter.GetValue(AControl: TControl): Variant;
var
  P: TDateTimePicker;
begin
  P := TDateTimePicker(AControl);
  if P.ShowCheckbox and not P.Checked then
    Exit(Null);
  if P.Kind = dtkTime then
    Exit(VarFromDateTime(Frac(P.Time)));
  Result := VarFromDateTime(Int(P.Date));
end;

{ TPPGValidationRule }

constructor TPPGValidationRule.Create(Collection: TCollection);
begin
  FEnabled := True;
  FSeverity := pvsError;
  FKind := vrRequired;
  FCompareOperator := coEqual;
  inherited Create(Collection);
end;

function TPPGValidationRule.Validator: TPPGValidator;
begin
  if (Collection <> nil) and (Collection.Owner is TPPGValidator) then
    Result := TPPGValidator(Collection.Owner)
  else
    Result := nil;
end;

procedure TPPGValidationRule.Assign(Source: TPersistent);
var
  S: TPPGValidationRule;
begin
  if Source is TPPGValidationRule then
  begin
    S := TPPGValidationRule(Source);
    Control := S.Control;
    FKind := S.FKind;
    FEnabled := S.FEnabled;
    FSeverity := S.FSeverity;
    FCaption := S.FCaption;
    FMessage := S.FMessage;
    FGroup := S.FGroup;
    FMinLength := S.FMinLength;
    FMaxLength := S.FMaxLength;
    FMinValue := S.FMinValue;
    FMaxValue := S.FMaxValue;
    FPatternKind := S.FPatternKind;
    FPattern := S.FPattern;
    FRegexReady := False;
    CompareControl := S.CompareControl;
    FCompareOperator := S.FCompareOperator;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGValidationRule.GetDisplayName: string;
begin
  Result := GetEnumName(TypeInfo(TPPGValidationRuleKind), Ord(FKind));
  if FControl <> nil then
    Result := FControl.Name + ': ' + Result;
end;

procedure TPPGValidationRule.SetControl(const Value: TControl);
var
  V: TPPGValidator;
begin
  if FControl = Value then
    Exit;
  V := Validator;
  FControl := Value;
  if (Value <> nil) and (V <> nil) then
    Value.FreeNotification(V);
  Changed(False);
end;

procedure TPPGValidationRule.SetCompareControl(const Value: TControl);
var
  V: TPPGValidator;
begin
  if FCompareControl = Value then
    Exit;
  V := Validator;
  FCompareControl := Value;
  if (Value <> nil) and (V <> nil) then
    Value.FreeNotification(V);
  Changed(False);
end;

procedure TPPGValidationRule.SetKind(const Value: TPPGValidationRuleKind);
begin
  if FKind <> Value then
  begin
    FKind := Value;
    Changed(False);
  end;
end;

procedure TPPGValidationRule.SetEnabled(const Value: Boolean);
begin
  if FEnabled <> Value then
  begin
    FEnabled := Value;
    Changed(False);
  end;
end;

procedure TPPGValidationRule.SetSeverity(const Value: TPPGValidationState);
begin
  if not (Value in [pvsWarning, pvsError]) then
  begin
    RejectValue('Severity', GetEnumName(TypeInfo(TPPGValidationState), Ord(Value)));
    Exit;
  end;
  FSeverity := Value;
end;

procedure TPPGValidationRule.SetMinLength(const Value: Integer);
begin
  FMinLength := PPGCheckRange(Self, 'MinLength', Value, 0, MaxInt);
end;

procedure TPPGValidationRule.SetMaxLength(const Value: Integer);
begin
  FMaxLength := PPGCheckRange(Self, 'MaxLength', Value, 0, MaxInt);
end;

function TPPGValidationRule.RejectValue(const PropName, Value: string): Boolean;
begin
  Result := True;
  if not PPGIsLoading(Self) then
    raise EPPGPropertyError.CreateInvalid(Self, PropName, Value);
  TPPGErrorHandler.LogWarning(Self, Format(PPGStr(@SPPGInvalidPropertyValue),
    [Value, PPGDisplayName(Self), PropName]));
end;

function TPPGValidationRule.CheckBound(const PropName, Value: string): Boolean;
var
  D: Double;
  IsDate: Boolean;
begin
  Result := (Trim(Value) = '') or TryParseBound(Value, D, IsDate);
  if not Result then
    RejectValue(PropName, Value);
end;

procedure TPPGValidationRule.SetMinValue(const Value: string);
begin
  if CheckBound('MinValue', Value) then
    FMinValue := Value;
end;

procedure TPPGValidationRule.SetMaxValue(const Value: string);
begin
  if CheckBound('MaxValue', Value) then
    FMaxValue := Value;
end;

procedure TPPGValidationRule.SetPatternKind(const Value: TPPGValidationPattern);
begin
  FPatternKind := Value;
  FRegexReady := False;
end;

procedure TPPGValidationRule.SetPattern(const Value: string);
begin
  // Erst pruefen, dann zuweisen: ungueltiger Ausdruck wirft hier, nicht beim Pruefen
  if Value <> '' then
    try
      // TRegEx kompiliert erst beim ersten Treffer, daher IsMatch. Auch allein
      // gueltig: "(" waere in "^(?:" + "(" + ")$" sonst versteckt.
      TRegEx.Create(Value).IsMatch('');
      TRegEx.Create('^(?:' + Value + ')$').IsMatch('');
    except
      on ERegularExpressionError do
      begin
        // Laden: Muster verwerfen (sonst wirft spaeter jede Pruefung)
        RejectValue('Pattern', Value);
        Exit;
      end;
    end;
  FPattern := Value;
  FRegexReady := False;
end;

function TPPGValidationRule.MatchesPattern(const S: string): Boolean;
var
  P: string;
begin
  if S = '' then
    Exit(True);
  if FPatternKind = vpIBAN then
    Exit(PPGCheckIBAN(S));
  if not FRegexReady then
  begin
    case FPatternKind of
      vpEmail: P := PatternEmail;
      vpPhone: P := PatternPhone;
      vpPostalCodeDE: P := PatternPostalDE;
    else
      P := FPattern;
    end;
    if P = '' then
      Exit(True);
    FRegex := TRegEx.Create('^(?:' + P + ')$');
    FRegexReady := True;
  end;
  Result := FRegex.IsMatch(Trim(S));
end;

function TPPGValidationRule.FieldCaption: string;
begin
  Result := FCaption;
  if (Result = '') and (FControl <> nil) then
    Result := ControlCaption(FControl);
end;

{ TPPGValidationRules }

constructor TPPGValidationRules.Create(AOwner: TPPGValidator);
begin
  inherited Create(AOwner, TPPGValidationRule);
end;

function TPPGValidationRules.Add: TPPGValidationRule;
begin
  Result := TPPGValidationRule(inherited Add);
end;

function TPPGValidationRules.AddRule(AControl: TControl;
  AKind: TPPGValidationRuleKind): TPPGValidationRule;
begin
  BeginUpdate;
  try
    Result := Add;
    Result.Control := AControl;
    Result.Kind := AKind;
  finally
    EndUpdate;
  end;
end;

function TPPGValidationRules.GetItem(Index: Integer): TPPGValidationRule;
begin
  Result := TPPGValidationRule(inherited GetItem(Index));
end;

procedure TPPGValidationRules.SetItem(Index: Integer; const Value: TPPGValidationRule);
begin
  inherited SetItem(Index, Value);
end;

procedure TPPGValidationRules.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Owner is TPPGValidator then
    TPPGValidator(Owner).RulesChanged;
end;

{ TPPGValidator }

constructor TPPGValidator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActive := True;
  FValidateOn := voExit;
  FResults := TList<TPPGValidationResult>.Create;
  FMarks := TDictionary<TControl, TPPGValidationState>.Create;
  FTouched := TList<TControl>.Create;
  FWatched := TList<TControl>.Create;
  FPendingExit := TList<TControl>.Create;
  FPendingChange := TList<TControl>.Create;
  FRules := TPPGValidationRules.Create(Self);
  FAutoFieldRules := True;
  FCheckOnClose := True;
  // Zur Laufzeit erzeugt (nicht aus der DFM): gleich einhaengen
  if (AOwner <> nil) and not (csLoading in AOwner.ComponentState) and IsRuntime then
    AttachHooks;
end;

destructor TPPGValidator.Destroy;
var
  I: Integer;
begin
  DetachForm;
  DetachBar;
  DetachWizard;
  if FWatched <> nil then
    for I := 0 to FWatched.Count - 1 do
      if not (csDestroying in FWatched[I].ComponentState) then
        PPGUnwatchControl(FWatched[I], ControlMessage);
  if FWnd <> 0 then
    DeallocateHWnd(FWnd);
  FRules.Free;
  FPendingChange.Free;
  FPendingExit.Free;
  FWatched.Free;
  FTouched.Free;
  FMarks.Free;
  FResults.Free;
  inherited Destroy;
end;

function TPPGValidator.IsRuntime: Boolean;
begin
  Result := not (csDesigning in ComponentState) and not (csLoading in ComponentState) and
    not (csDestroying in ComponentState);
end;

procedure TPPGValidator.Loaded;
begin
  inherited Loaded;
  if not IsRuntime then
    Exit;
  AttachHooks;
  UpdateWatches;
  // Absende-Knopf erst, wenn FormCreate die Werte gesetzt hat
  if FSubmitControl <> nil then
    Schedule(nil, False);
end;

{ Einhaengen in Formular, Sammelleiste und Assistent }

function IsRelevant(C: TControl): Boolean; forward;

type
  TFormAccess = class(TCustomForm);
  TInfoBarAccess = class(TPPGCustomInfoBar);

function SameMethod(const A, B: TMethod): Boolean;
begin
  Result := (A.Code = B.Code) and (A.Data = B.Data);
end;

procedure TPPGValidator.AttachHooks;
var
  Q: TCloseQueryEvent;
  N: TNotifyEvent;
  W: TPPGWizardCanAdvanceEvent;
begin
  if not IsRuntime then
    Exit;
  if not FFormHooked and (Owner is TCustomForm) then
  begin
    FForm := TCustomForm(Owner);
    FOldCloseQuery := TFormAccess(FForm).OnCloseQuery;
    Q := FormCloseQuery;
    TFormAccess(FForm).OnCloseQuery := Q;
    FFormHooked := True;
  end;
  if not FBarHooked and (FSummaryBar <> nil) then
  begin
    FOldBarAction := TInfoBarAccess(FSummaryBar).OnActionClick;
    N := BarAction;
    TInfoBarAccess(FSummaryBar).OnActionClick := N;
    FBarHooked := True;
  end;
  if not FWizardHooked and (FWizard <> nil) then
  begin
    FOldCanAdvance := FWizard.OnCanAdvance;
    W := WizardCanAdvance;
    FWizard.OnCanAdvance := W;
    FWizardHooked := True;
  end;
end;

procedure TPPGValidator.DetachForm;
var
  Q: TCloseQueryEvent;
begin
  if not FFormHooked then
    Exit;
  FFormHooked := False;
  Q := FormCloseQuery;
  // Nur zuruecksetzen, wenn niemand nach uns eingehaengt hat
  if (FForm <> nil) and SameMethod(TMethod(TFormAccess(FForm).OnCloseQuery), TMethod(Q)) then
    TFormAccess(FForm).OnCloseQuery := FOldCloseQuery;
  FForm := nil;
  FOldCloseQuery := nil;
end;

procedure TPPGValidator.DetachBar;
var
  N: TNotifyEvent;
begin
  if not FBarHooked then
    Exit;
  FBarHooked := False;
  N := BarAction;
  if (FSummaryBar <> nil) and not (csDestroying in FSummaryBar.ComponentState) and
    SameMethod(TMethod(TInfoBarAccess(FSummaryBar).OnActionClick), TMethod(N)) then
    TInfoBarAccess(FSummaryBar).OnActionClick := FOldBarAction;
  FOldBarAction := nil;
end;

procedure TPPGValidator.DetachWizard;
var
  W: TPPGWizardCanAdvanceEvent;
begin
  if not FWizardHooked then
    Exit;
  FWizardHooked := False;
  W := WizardCanAdvance;
  if (FWizard <> nil) and not (csDestroying in FWizard.ComponentState) and
    SameMethod(TMethod(FWizard.OnCanAdvance), TMethod(W)) then
    FWizard.OnCanAdvance := FOldCanAdvance;
  FOldCanAdvance := nil;
end;

procedure TPPGValidator.SetSummaryBar(const Value: TPPGCustomInfoBar);
begin
  if FSummaryBar = Value then
    Exit;
  DetachBar;
  FSummaryBar := Value;
  if Value <> nil then
  begin
    Value.FreeNotification(Self);
    AttachHooks;
    UpdateSummary;
  end;
end;

procedure TPPGValidator.SetWizard(const Value: TPPGWizard);
begin
  if FWizard = Value then
    Exit;
  DetachWizard;
  FWizard := Value;
  if Value <> nil then
  begin
    Value.FreeNotification(Self);
    AttachHooks;
  end;
end;

procedure TPPGValidator.SetSubmitControl(const Value: TControl);
begin
  if FSubmitControl = Value then
    Exit;
  FSubmitControl := Value;
  if Value <> nil then
  begin
    Value.FreeNotification(Self);
    UpdateSubmit;
  end;
end;

procedure TPPGValidator.SetAutoFieldRules(const Value: Boolean);
begin
  if FAutoFieldRules = Value then
    Exit;
  FAutoFieldRules := Value;
  UpdateWatches;
end;

procedure TPPGValidator.BarAction(Sender: TObject);
begin
  FocusFirstError;
  if Assigned(FOldBarAction) then
    FOldBarAction(Sender);
end;

procedure TPPGValidator.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Assigned(FOldCloseQuery) then
    FOldCloseQuery(Sender, CanClose);
  if not CanClose or not FCheckOnClose or not FActive or (FForm = nil) then
    Exit;
  // Nur "OK"-Ergebnisse; Abbrechen und das Schliessfeld bleiben frei
  if (FForm.ModalResult <> mrOk) and (FForm.ModalResult <> mrYes) then
    Exit;
  if not Validate then
  begin
    CanClose := False;
    FocusFirstError;
  end;
end;

procedure TPPGValidator.WizardCanAdvance(Sender: TObject; Page: TPPGWizardPage;
  var Allow: Boolean);
begin
  if Assigned(FOldCanAdvance) then
    FOldCanAdvance(Sender, Page, Allow);
  if not Allow or not FActive or (Page = nil) then
    Exit;
  Allow := ValidateChildren(Page);
  if not Allow then
    FocusFirstError;
end;

procedure TPPGValidator.UpdateSummary;
var
  Errs, Warns, I, Shown: Integer;
  Title, Names: string;
  Bar: TInfoBarAccess;
begin
  if (FSummaryBar = nil) or not IsRuntime then
    Exit;
  Bar := TInfoBarAccess(FSummaryBar);
  Errs := ErrorCount;
  Warns := WarningCount;
  if not FSummaryShown or (Errs + Warns = 0) then
  begin
    Bar.Open := False;
    Exit;
  end;
  Title := '';
  if Errs = 1 then
    Title := PPGStr(@SPPGValOneError)
  else if Errs > 1 then
    Title := Format(PPGStr(@SPPGValErrors), [Errs]);
  if Warns > 0 then
  begin
    if Title <> '' then
      Title := Title + ', ';
    if Warns = 1 then
      Title := Title + PPGStr(@SPPGValOneWarning)
    else
      Title := Title + Format(PPGStr(@SPPGValWarnings), [Warns]);
  end;
  Names := '';
  Shown := 0;
  for I := 0 to FResults.Count - 1 do
  begin
    if Shown = 5 then
    begin
      Names := Format(PPGStr(@SPPGValAndMore), [Names, FResults.Count - Shown]);
      Break;
    end;
    if Names <> '' then
      Names := Names + ', ';
    Names := Names + FResults[I].Caption;
    Inc(Shown);
  end;
  if Errs > 0 then
  begin
    Bar.Severity := psError;
    Bar.ActionCaption := PPGStr(@SPPGValGoToError);
  end
  else
  begin
    Bar.Severity := psWarning;
    Bar.ActionCaption := '';
  end;
  Bar.Title := Title;
  Bar.Message := Names;
  Bar.Visible := True;
  Bar.Open := True;
end;

function TPPGValidator.FieldInfo(AControl: TControl; out Info: TPPGFieldRuleInfo): Boolean;
begin
  Result := FAutoFieldRules and Assigned(GFieldRuleProvider) and GFieldRuleProvider(AControl, Info);
end;

function TPPGValidator.CheckFieldRules(AControl: TControl; const Info: TPPGFieldRuleInfo;
  RequiredOnly: Boolean; out Msg: string): Boolean;
var
  A: TPPGValidationAdapterClass;
  V: Variant;
  Cap: string;
  D: Double;
begin
  Msg := '';
  Result := True;
  if not Info.Editing then
    Exit;
  A := AdapterFor(AControl);
  V := A.GetValue(AControl);
  Cap := Info.Caption;
  if Cap = '' then
    Cap := ControlCaption(AControl);
  if PPGValidationValueIsEmpty(V) then
  begin
    if Info.Required then
    begin
      Msg := Format(PPGStr(A.RequiredText), [Cap]);
      Result := False;
    end;
    Exit;
  end;
  if RequiredOnly then
    Exit;
  if (Info.MaxLength > 0) and (Length(VarToStr(V)) > Info.MaxLength) then
  begin
    Msg := Format(PPGStr(@SPPGValTooLong), [Cap, Info.MaxLength]);
    Exit(False);
  end;
  if (Info.HasMin or Info.HasMax) and TryValueToNumber(V, D) then
  begin
    if Info.HasMin and (CompareValue(D, Info.MinValue) < 0) then
    begin
      Msg := Format(PPGStr(@SPPGValBelowMin), [Cap, FloatToStr(Info.MinValue)]);
      Exit(False);
    end;
    if Info.HasMax and (CompareValue(D, Info.MaxValue) > 0) then
    begin
      Msg := Format(PPGStr(@SPPGValAboveMax), [Cap, FloatToStr(Info.MaxValue)]);
      Exit(False);
    end;
  end;
end;

procedure TPPGValidator.UpdateSubmit;
var
  List: TList<TControl>;
  I, J: Integer;
  Ok: Boolean;
  Msg: string;
  Info: TPPGFieldRuleInfo;
  R: TPPGValidationRule;
begin
  if (FSubmitControl = nil) or not IsRuntime then
    Exit;
  Ok := True;
  if FActive then
  begin
    List := TList<TControl>.Create;
    try
      CollectControls(List, nil, '', False);
      for I := 0 to List.Count - 1 do
      begin
        if not Ok then
          Break;
        if not IsRelevant(List[I]) then
          Continue;
        if FieldInfo(List[I], Info) and not CheckFieldRules(List[I], Info, True, Msg) then
          Ok := False;
        for J := 0 to FRules.Count - 1 do
        begin
          R := FRules[J];
          if Ok and R.Enabled and (R.Kind = vrRequired) and (R.Severity = pvsError) and
            (R.Control = List[I]) and not CheckRule(R, Msg) then
            Ok := False;
        end;
      end;
    finally
      List.Free;
    end;
  end;
  FSubmitControl.Enabled := Ok;
end;

procedure TPPGValidator.RulesChanged;
begin
  if (FRules <> nil) and (FRules.UpdateCount = 0) then
    UpdateWatches;
end;

procedure TPPGValidator.SetRules(const Value: TPPGValidationRules);
begin
  FRules.Assign(Value);
end;

procedure TPPGValidator.SetActive(const Value: Boolean);
begin
  if FActive = Value then
    Exit;
  FActive := Value;
  if not Value and IsRuntime then
    ClearResults;
end;

procedure TPPGValidator.SetShowValid(const Value: Boolean);
var
  I: Integer;
  Res: TPPGValidationResult;
begin
  if FShowValid = Value then
    Exit;
  FShowValid := Value;
  if not IsRuntime then
    Exit;
  // Bereits gepruefte Felder sofort anpassen
  Res.Rule := nil;
  Res.Message := '';
  Res.Severity := pvsNone;
  for I := 0 to FTouched.Count - 1 do
    if IndexOfResult(FTouched[I]) < 0 then
    begin
      Res.Control := FTouched[I];
      ApplyResult(FTouched[I], False, Res);
    end;
end;

procedure TPPGValidator.Notification(AComponent: TComponent; Operation: TOperation);
var
  I: Integer;
begin
  inherited Notification(AComponent, Operation);
  if Operation <> opRemove then
    Exit;
  if AComponent = FSummaryBar then
  begin
    FBarHooked := False;
    FSummaryBar := nil;
  end;
  if AComponent = FWizard then
  begin
    FWizardHooked := False;
    FWizard := nil;
  end;
  if AComponent = FSubmitControl then
    FSubmitControl := nil;
  if not (AComponent is TControl) then
    Exit;
  if FRules <> nil then
    for I := 0 to FRules.Count - 1 do
    begin
      if FRules[I].FControl = AComponent then
        FRules[I].FControl := nil;
      if FRules[I].FCompareControl = AComponent then
        FRules[I].FCompareControl := nil;
    end;
  if FResults <> nil then
    for I := FResults.Count - 1 downto 0 do
      if FResults[I].Control = AComponent then
        FResults.Delete(I);
  if FMarks <> nil then
    FMarks.Remove(TControl(AComponent));
  if FTouched <> nil then
    FTouched.Remove(TControl(AComponent));
  if FWatched <> nil then
    FWatched.Remove(TControl(AComponent));
  if FPendingExit <> nil then
    FPendingExit.Remove(TControl(AComponent));
  if FPendingChange <> nil then
    FPendingChange.Remove(TControl(AComponent));
end;

procedure TPPGValidator.UpdateWatches;
var
  Want: TList<TControl>;
  I: Integer;
  Info: TPPGFieldRuleInfo;
  procedure AddWant(C: TControl);
  begin
    if (C <> nil) and not Want.Contains(C) then
      Want.Add(C);
  end;
begin
  if not IsRuntime then
    Exit;
  Want := TList<TControl>.Create;
  try
    for I := 0 to FRules.Count - 1 do
    begin
      AddWant(FRules[I].Control);
      AddWant(FRules[I].CompareControl);
    end;
    // DB-Controls mit Regeln aus dem Datenfeld
    if FAutoFieldRules and Assigned(GFieldRuleProvider) and (Owner <> nil) then
      for I := 0 to Owner.ComponentCount - 1 do
        if (Owner.Components[I] is TControl) and
          FieldInfo(TControl(Owner.Components[I]), Info) then
          AddWant(TControl(Owner.Components[I]));
    for I := FWatched.Count - 1 downto 0 do
      if not Want.Contains(FWatched[I]) then
      begin
        PPGUnwatchControl(FWatched[I], ControlMessage);
        FWatched.Delete(I);
      end;
    for I := 0 to Want.Count - 1 do
      if not FWatched.Contains(Want[I]) then
      begin
        PPGWatchControl(Want[I], ControlMessage);
        FWatched.Add(Want[I]);
      end;
  finally
    Want.Free;
  end;
end;

procedure TPPGValidator.ControlMessage(Control: TControl; var Message: TMessage);
var
  Code: Integer;
begin
  if not FActive or not IsRuntime then
    Exit;
  case Message.Msg of
    CM_EXIT:
      if FValidateOn <> voSubmit then
        Schedule(Control, True);
    CM_PPGVALUECHANGED, CM_TEXTCHANGED:
      Schedule(Control, False);
    CN_COMMAND:
      begin
        // Nur VCL-Controls; PPGlow meldet sich per CM_PPGVALUECHANGED
        Code := HiWord(Message.WParam);
        if (Control is TCustomEdit) and (Code = EN_CHANGE) then
          Schedule(Control, False)
        else if (Control is TCustomComboBox) and
          ((Code = CBN_SELCHANGE) or (Code = CBN_EDITCHANGE)) then
          Schedule(Control, False)
        else if (Control is TCustomCheckBox) and (Code = BN_CLICKED) then
          Schedule(Control, False);
      end;
    CN_NOTIFY:
      if (Control is TDateTimePicker) and
        (PNMHdr(Message.LParam)^.code = DTN_DATETIMECHANGE) then
        Schedule(Control, False);
  end;
end;

procedure TPPGValidator.Schedule(AControl: TControl; Exiting: Boolean);
begin
  // AControl = nil: nur den Absende-Knopf neu bewerten
  if AControl = nil then
  else if Exiting then
  begin
    if not FPendingExit.Contains(AControl) then
      FPendingExit.Add(AControl);
  end
  else if not FPendingChange.Contains(AControl) then
    FPendingChange.Add(AControl);
  if FPosted then
    Exit;
  if FWnd = 0 then
    FWnd := AllocateHWnd(WndProc);
  FPosted := PostMessage(FWnd, WM_PPGVALIDATE, 0, 0);
end;

procedure TPPGValidator.WndProc(var Message: TMessage);
begin
  if Message.Msg = WM_PPGVALIDATE then
  begin
    FPosted := False;
    try
      ProcessPending;
    except
      // Grenze: gepostete Fensternachricht ruft Anwender-Code (Regeln,
      // Ereignisse) - Exception melden, das Hilfsfenster nicht verlassen
      on E: Exception do
        TPPGErrorHandler.HandleCallbackError(Self, E, 'PPG.Validator');
    end;
  end
  else
    Message.Result := DefWindowProc(FWnd, Message.Msg, Message.WParam, Message.LParam);
end;

procedure TPPGValidator.AddDependents(List: TList<TControl>; AControl: TControl);
var
  I: Integer;
  C: TControl;
begin
  // Vergleichsregeln, die AControl als Vergleichswert nutzen
  for I := 0 to FRules.Count - 1 do
    if FRules[I].Enabled and (FRules[I].Kind = vrCompare) and
      (FRules[I].CompareControl = AControl) then
    begin
      C := FRules[I].Control;
      if (C <> nil) and FTouched.Contains(C) and not List.Contains(C) then
        List.Add(C);
    end;
end;

procedure TPPGValidator.ProcessPending;
var
  List: TList<TControl>;
  I: Integer;
  C: TControl;
begin
  if not FActive or not IsRuntime then
  begin
    FPendingExit.Clear;
    FPendingChange.Clear;
    Exit;
  end;
  List := TList<TControl>.Create;
  try
    for I := 0 to FPendingExit.Count - 1 do
    begin
      C := FPendingExit[I];
      if not List.Contains(C) then
        List.Add(C);
      AddDependents(List, C);
    end;
    for I := 0 to FPendingChange.Count - 1 do
    begin
      C := FPendingChange[I];
      // Beim Tippen nur pruefen, wenn gewuenscht oder schon ein Ergebnis da ist
      if ((FValidateOn = voChange) or (IndexOfResult(C) >= 0)) and not List.Contains(C) then
        List.Add(C);
      AddDependents(List, C);
    end;
    FPendingExit.Clear;
    FPendingChange.Clear;
    // Nur Controls mit eigener Regel (Vergleichs-Controls ohne Regel nicht)
    for I := List.Count - 1 downto 0 do
      if not FWatched.Contains(List[I]) then
        List.Delete(I);
    if List.Count > 0 then
      ValidateList(List, '', False)
    else
      UpdateSubmit;
  finally
    List.Free;
  end;
end;

function TPPGValidator.IndexOfResult(AControl: TControl): Integer;
var
  I: Integer;
begin
  for I := 0 to FResults.Count - 1 do
    if FResults[I].Control = AControl then
      Exit(I);
  Result := -1;
end;

function TPPGValidator.GetResult(Index: Integer): TPPGValidationResult;
begin
  if (Index < 0) or (Index >= FResults.Count) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, FResults.Count - 1]);
  Result := FResults[Index];
end;

function TPPGValidator.GetResultCount: Integer;
begin
  Result := FResults.Count;
end;

function TPPGValidator.ResultFor(AControl: TControl; out Res: TPPGValidationResult): Boolean;
var
  I: Integer;
begin
  I := IndexOfResult(AControl);
  Result := I >= 0;
  if Result then
    Res := FResults[I];
end;

function TPPGValidator.ErrorCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FResults.Count - 1 do
    if FResults[I].Severity = pvsError then
      Inc(Result);
end;

function TPPGValidator.WarningCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FResults.Count - 1 do
    if FResults[I].Severity = pvsWarning then
      Inc(Result);
end;

/// Sichtbar und bedienbar? Inaktive Reiter zaehlen als sichtbar.
function IsRelevant(C: TControl): Boolean;
var
  P: TWinControl;
begin
  Result := False;
  if not C.Visible or not C.Enabled then
    Exit;
  P := C.Parent;
  while (P <> nil) and not (P is TCustomForm) do
  begin
    // Reiter sind nur verdeckt, auch ohne sichtbaren Kopf (TabVisible = False:
    // Seiten, die das Programm selbst umschaltet)
    if (P is TPPGTabSheet) or (P is TTabSheet) then
    begin
      if not P.Enabled then
        Exit;
    end
    else if P is TPPGWizardPage then
    begin
      if not TPPGWizardPage(P).PageVisible or not P.Enabled then
        Exit;
    end
    else if not P.Visible or not P.Enabled then
      Exit;
    P := P.Parent;
  end;
  Result := True;
end;

function TPPGValidator.CheckRule(Rule: TPPGValidationRule; out Msg: string): Boolean;
var
  A: TPPGValidationAdapterClass;
  V, V2: Variant;
  Cap, S: string;
  L: Integer;
  D, Bound, D2: Double;
  IsDate: Boolean;
  Cmp: Integer;
  Res: PResStringRec;

  function Fmt(R: PResStringRec; const Args: array of const): string;
  begin
    if Rule.Message <> '' then
      Result := StringReplace(Rule.Message, '{caption}', Cap, [rfReplaceAll, rfIgnoreCase])
    else
      Result := Format(PPGStr(R), Args);
  end;

begin
  Msg := '';
  Result := True;
  A := AdapterFor(Rule.Control);
  V := A.GetValue(Rule.Control);
  Cap := Rule.FieldCaption;
  if Rule.Kind = vrRequired then
  begin
    Result := not PPGValidationValueIsEmpty(V);
    if not Result then
      Msg := Fmt(A.RequiredText, [Cap]);
    Exit;
  end;
  if Rule.Kind = vrCustom then
  begin
    if Assigned(FOnValidate) then
      FOnValidate(Self, Rule, V, Result, Msg);
    // Meldung des Handlers vor Rule.Message vor dem Standardtext
    if not Result and (Msg = '') then
      Msg := Fmt(@SPPGValInvalid, [Cap]);
    Exit;
  end;
  // Die uebrigen Regeln greifen erst, wenn etwas eingegeben ist
  if PPGValidationValueIsEmpty(V) then
    Exit;
  case Rule.Kind of
    vrLength:
      begin
        L := Length(Trim(VarToStr(V)));
        if (Rule.MinLength > 0) and (L < Rule.MinLength) then
        begin
          Msg := Fmt(@SPPGValTooShort, [Cap, Rule.MinLength]);
          Exit(False);
        end;
        if (Rule.MaxLength > 0) and (L > Rule.MaxLength) then
        begin
          Msg := Fmt(@SPPGValTooLong, [Cap, Rule.MaxLength]);
          Exit(False);
        end;
      end;
    vrRange:
      begin
        if not TryValueToNumber(V, D) then
        begin
          Msg := Fmt(@SPPGValNotANumber, [Cap]);
          Exit(False);
        end;
        if (Trim(Rule.MinValue) <> '') and TryParseBound(Rule.MinValue, Bound, IsDate) and
          (CompareValue(D, Bound) < 0) then
        begin
          Msg := Fmt(@SPPGValBelowMin, [Cap, FormatBound(Bound, IsDate or IsDateValue(V))]);
          Exit(False);
        end;
        if (Trim(Rule.MaxValue) <> '') and TryParseBound(Rule.MaxValue, Bound, IsDate) and
          (CompareValue(D, Bound) > 0) then
        begin
          Msg := Fmt(@SPPGValAboveMax, [Cap, FormatBound(Bound, IsDate or IsDateValue(V))]);
          Exit(False);
        end;
      end;
    vrPattern:
      begin
        S := VarToStr(V);
        if not Rule.MatchesPattern(S) then
        begin
          case Rule.PatternKind of
            vpEmail: Res := @SPPGValEmail;
            vpPhone: Res := @SPPGValPhone;
            vpPostalCodeDE: Res := @SPPGValPostalCode;
            vpIBAN: Res := @SPPGValIBAN;
          else
            Res := @SPPGValPattern;
          end;
          Msg := Fmt(Res, [Cap]);
          Exit(False);
        end;
      end;
    vrCompare:
      begin
        if Rule.CompareControl = nil then
          Exit;
        V2 := AdapterFor(Rule.CompareControl).GetValue(Rule.CompareControl);
        // Leerer Vergleichswert: Sache seiner eigenen Pflicht-Regel
        if PPGValidationValueIsEmpty(V2) then
          Exit;
        if TryValueToNumber(V, D) and TryValueToNumber(V2, D2) and
          not (VarIsStr(V) and VarIsStr(V2) and (Rule.CompareOperator in [coEqual, coNotEqual])) then
          Cmp := CompareValue(D, D2)
        else
          Cmp := CompareStr(VarToStr(V), VarToStr(V2));
        case Rule.CompareOperator of
          coEqual: Result := Cmp = 0;
          coNotEqual: Result := Cmp <> 0;
          coLess: Result := Cmp < 0;
          coLessOrEqual: Result := Cmp <= 0;
          coGreater: Result := Cmp > 0;
        else
          Result := Cmp >= 0;
        end;
        if not Result then
        begin
          case Rule.CompareOperator of
            coEqual: Res := @SPPGValEqual;
            coNotEqual: Res := @SPPGValNotEqual;
            coLess: Res := @SPPGValLess;
            coLessOrEqual: Res := @SPPGValLessOrEqual;
            coGreater: Res := @SPPGValGreater;
          else
            Res := @SPPGValGreaterOrEqual;
          end;
          Msg := Fmt(Res, [Cap, ControlCaption(Rule.CompareControl)]);
        end;
      end;
  end;
end;

function TPPGValidator.EvaluateControl(AControl: TControl; const AGroup: string;
  UseGroup: Boolean; out Res: TPPGValidationResult): Boolean;
var
  I: Integer;
  R: TPPGValidationRule;
  Msg: string;
  Info: TPPGFieldRuleInfo;
begin
  Result := False;
  Res.Control := AControl;
  Res.Rule := nil;
  Res.Message := '';
  Res.Severity := pvsNone;
  Res.Caption := '';
  if not IsRelevant(AControl) then
    Exit;
  // Regeln aus dem Datenfeld zuerst (immer Fehler)
  if FieldInfo(AControl, Info) and not CheckFieldRules(AControl, Info, False, Msg) then
  begin
    Res.Message := Msg;
    Res.Severity := pvsError;
    Res.Caption := Info.Caption;
    if Res.Caption = '' then
      Res.Caption := ControlCaption(AControl);
    Exit(True);
  end;
  for I := 0 to FRules.Count - 1 do
  begin
    R := FRules[I];
    if not R.Enabled or (R.Control <> AControl) then
      Continue;
    if UseGroup and (R.Group <> '') and not SameText(R.Group, AGroup) then
      Continue;
    if not CheckRule(R, Msg) then
    begin
      if R.Severity = pvsError then
      begin
        Res.Rule := R;
        Res.Message := Msg;
        Res.Severity := pvsError;
        Res.Caption := R.FieldCaption;
        Exit(True);
      end;
      if not Result then
      begin
        Res.Rule := R;
        Res.Message := Msg;
        Res.Severity := pvsWarning;
        Res.Caption := R.FieldCaption;
        Result := True;
      end;
    end;
  end;
end;

procedure TPPGValidator.MarkControl(AControl: TControl; State: TPPGValidationState;
  const Hint: string);
var
  A: TPPGValidationAdapterClass;
  Cur, Ours: TPPGValidationState;
  Mine: Boolean;
begin
  A := PPGFindValidationAdapter(AControl);
  if (A = nil) or not A.CanMark(AControl) then
    Exit;
  Cur := A.GetMark(AControl);
  Mine := FMarks.TryGetValue(AControl, Ours) and (Ours = Cur);
  if not Mine then
    FMarks.Remove(AControl);
  if State = pvsNone then
  begin
    // Nur zuruecknehmen, was noch von uns stammt
    if Mine then
    begin
      A.SetMark(AControl, pvsNone, '');
      FMarks.Remove(AControl);
    end;
    Exit;
  end;
  // Fremden Zustand (z.B. Fehler eines DB-Felds) nicht ueberschreiben
  if not Mine and not (Cur in [pvsNone, pvsValid]) then
    Exit;
  A.SetMark(AControl, State, Hint);
  FMarks.AddOrSetValue(AControl, State);
end;

procedure TPPGValidator.ApplyResult(AControl: TControl; HasIssue: Boolean;
  const Res: TPPGValidationResult);
var
  I: Integer;
  Old: TPPGValidationResult;
  HadOld: Boolean;
begin
  Old.Control := nil;
  Old.Rule := nil;
  Old.Message := '';
  Old.Severity := pvsNone;
  I := IndexOfResult(AControl);
  HadOld := I >= 0;
  if HadOld then
  begin
    Old := FResults[I];
    FResults.Delete(I);
  end;
  if HasIssue then
  begin
    FResults.Add(Res);
    MarkControl(AControl, Res.Severity, Res.Message);
  end
  else if FShowValid and FTouched.Contains(AControl) then
    MarkControl(AControl, pvsValid, '')
  else
    MarkControl(AControl, pvsNone, '');
  if Assigned(FOnShowError) then
  begin
    if HasIssue and (not HadOld or (Old.Message <> Res.Message) or (Old.Severity <> Res.Severity)) then
      FOnShowError(Self, AControl, Res.Message, Res.Severity)
    else if not HasIssue and HadOld then
      FOnShowError(Self, AControl, '', pvsNone);
  end;
end;

/// Pfad der TabOrder vom Formular bis zum Control (fuer die Sortierung).
function TabPath(C: TControl): TArray<Integer>;
var
  L: TList<Integer>;
  P: TControl;
  I: Integer;
begin
  L := TList<Integer>.Create;
  try
    P := C;
    while (P <> nil) and not (P is TCustomForm) do
    begin
      if P is TWinControl then
        L.Insert(0, TWinControl(P).TabOrder)
      else
        L.Insert(0, 0);
      P := P.Parent;
    end;
    SetLength(Result, L.Count);
    for I := 0 to L.Count - 1 do
      Result[I] := L[I];
  finally
    L.Free;
  end;
end;

function CompareTabOrder(A, B: TControl): Integer;
var
  PA, PB: TArray<Integer>;
  I: Integer;
begin
  PA := TabPath(A);
  PB := TabPath(B);
  for I := 0 to Min(Length(PA), Length(PB)) - 1 do
    if PA[I] <> PB[I] then
      Exit(PA[I] - PB[I]);
  Result := Length(PA) - Length(PB);
  if Result = 0 then
  begin
    Result := A.Top - B.Top;
    if Result = 0 then
      Result := A.Left - B.Left;
  end;
end;

procedure TPPGValidator.SortResults;
var
  I, J: Integer;
  T: TPPGValidationResult;
begin
  // Einfuegesortierung: wenige Eintraege, stabil
  for I := 1 to FResults.Count - 1 do
  begin
    T := FResults[I];
    J := I - 1;
    while (J >= 0) and (CompareTabOrder(FResults[J].Control, T.Control) > 0) do
    begin
      FResults[J + 1] := FResults[J];
      Dec(J);
    end;
    FResults[J + 1] := T;
  end;
end;

function TPPGValidator.ValidateList(List: TList<TControl>; const AGroup: string;
  UseGroup: Boolean): Boolean;
var
  I: Integer;
  Res: TPPGValidationResult;
  Issue: Boolean;
begin
  Result := True;
  for I := 0 to List.Count - 1 do
  begin
    if not FTouched.Contains(List[I]) then
      FTouched.Add(List[I]);
    Issue := EvaluateControl(List[I], AGroup, UseGroup, Res);
    ApplyResult(List[I], Issue, Res);
    if Issue and (Res.Severity = pvsError) then
      Result := False;
  end;
  SortResults;
  UpdateSubmit;
  DoValidated;
end;

procedure TPPGValidator.CollectControls(List: TList<TControl>; AContainer: TWinControl;
  const AGroup: string; UseGroup: Boolean);
var
  I: Integer;
  C: TControl;
  Info: TPPGFieldRuleInfo;
begin
  for I := 0 to FRules.Count - 1 do
  begin
    C := FRules[I].Control;
    if (C = nil) or not FRules[I].Enabled or List.Contains(C) then
      Continue;
    if UseGroup and (FRules[I].Group <> '') and not SameText(FRules[I].Group, AGroup) then
      Continue;
    if (AContainer <> nil) and (C <> AContainer) and not AContainer.ContainsControl(C) then
      Continue;
    List.Add(C);
  end;
  // DB-Controls ohne eigene Regel (Regeln aus dem Datenfeld, keine Gruppe)
  if FAutoFieldRules and Assigned(GFieldRuleProvider) and (Owner <> nil) then
    for I := 0 to Owner.ComponentCount - 1 do
    begin
      if not (Owner.Components[I] is TControl) then
        Continue;
      C := TControl(Owner.Components[I]);
      if List.Contains(C) or not FieldInfo(C, Info) then
        Continue;
      if (AContainer <> nil) and (C <> AContainer) and not AContainer.ContainsControl(C) then
        Continue;
      List.Add(C);
    end;
end;

function TPPGValidator.Validate: Boolean;
var
  List: TList<TControl>;
begin
  FSummaryShown := True;
  if not FActive then
    Exit(True);
  List := TList<TControl>.Create;
  try
    CollectControls(List, nil, '', False);
    Result := ValidateList(List, '', False);
  finally
    List.Free;
  end;
end;

function TPPGValidator.ValidateGroup(const AGroup: string): Boolean;
var
  List: TList<TControl>;
begin
  FSummaryShown := True;
  if not FActive then
    Exit(True);
  List := TList<TControl>.Create;
  try
    CollectControls(List, nil, AGroup, True);
    Result := ValidateList(List, AGroup, True);
  finally
    List.Free;
  end;
end;

function TPPGValidator.ValidateChildren(AParent: TWinControl): Boolean;
var
  List: TList<TControl>;
begin
  FSummaryShown := True;
  if not FActive or (AParent = nil) then
    Exit(True);
  List := TList<TControl>.Create;
  try
    CollectControls(List, AParent, '', False);
    Result := ValidateList(List, '', False);
  finally
    List.Free;
  end;
end;

function TPPGValidator.ValidateControl(AControl: TControl): Boolean;
var
  List: TList<TControl>;
begin
  FSummaryShown := True;
  if not FActive or (AControl = nil) then
    Exit(True);
  List := TList<TControl>.Create;
  try
    List.Add(AControl);
    Result := ValidateList(List, '', False);
  finally
    List.Free;
  end;
end;

procedure TPPGValidator.ClearResults;
var
  Controls: TArray<TControl>;
  I: Integer;
  Res: TPPGValidationResult;
begin
  Controls := FMarks.Keys.ToArray;
  for I := 0 to Length(Controls) - 1 do
    MarkControl(Controls[I], pvsNone, '');
  FMarks.Clear;
  for I := FResults.Count - 1 downto 0 do
  begin
    Res := FResults[I];
    FResults.Delete(I);
    if Assigned(FOnShowError) then
      FOnShowError(Self, Res.Control, '', pvsNone);
  end;
  FTouched.Clear;
  FSummaryShown := False;
  UpdateSubmit;
  DoValidated;
end;

procedure TPPGValidator.DoValidated;
begin
  UpdateSummary;
  if Assigned(FOnValidated) then
    FOnValidated(Self);
end;

/// Reiter aktivieren, Expander aufklappen, ins Bild scrollen.
procedure RevealControl(C: TControl);
var
  Chain: TList<TWinControl>;
  P: TWinControl;
  I: Integer;
begin
  Chain := TList<TWinControl>.Create;
  try
    P := C.Parent;
    while (P <> nil) and not (P is TCustomForm) do
    begin
      Chain.Insert(0, P);
      P := P.Parent;
    end;
    // Von aussen nach innen: aeussere Reiter zuerst
    for I := 0 to Chain.Count - 1 do
    begin
      P := Chain[I];
      if (P is TPPGTabSheet) and (TPPGTabSheet(P).PageControl <> nil) then
        TPPGTabSheet(P).PageControl.ActivePage := TPPGTabSheet(P)
      else if (P is TTabSheet) and (TTabSheet(P).PageControl <> nil) then
        TTabSheet(P).PageControl.ActivePage := TTabSheet(P)
      else if (P is TPPGWizardPage) and (TPPGWizardPage(P).Wizard <> nil) then
        TPPGWizardPage(P).Wizard.ActivePage := TPPGWizardPage(P)
      else if P is TPPGCustomExpander then
        TExpanderAccess(P).Expanded := True;
    end;
    // Von innen nach aussen scrollen
    for I := Chain.Count - 1 downto 0 do
    begin
      P := Chain[I];
      if P is TPPGCustomPanel then
        TPPGCustomPanel(P).ScrollInView(C)
      else if P is TScrollingWinControl then
        TScrollingWinControl(P).ScrollInView(C);
    end;
  finally
    Chain.Free;
  end;
end;

function TPPGValidator.FocusFirstError: Boolean;
var
  I, Best: Integer;
  C: TControl;
  F: TCustomForm;
begin
  Best := -1;
  for I := 0 to FResults.Count - 1 do
    if FResults[I].Severity = pvsError then
    begin
      Best := I;
      Break;
    end;
  if Best < 0 then
    Exit(False);
  Result := True;
  C := FResults[Best].Control;
  RevealControl(C);
  F := GetParentForm(C);
  if (C is TWinControl) and (F <> nil) and F.Visible and F.Enabled and
    TWinControl(C).CanFocus then
    TWinControl(C).SetFocus;
end;

initialization
  GInvariant := TFormatSettings.Create('en-US');
  GInvariant.DecimalSeparator := '.';
  GInvariant.ThousandSeparator := ',';
  PPGRegisterValidationAdapter(TVclEditAdapter);
  PPGRegisterValidationAdapter(TVclComboAdapter);
  PPGRegisterValidationAdapter(TVclCheckAdapter);
  PPGRegisterValidationAdapter(TVclDateAdapter);
  PPGRegisterValidationAdapter(TCheckAdapter);
  PPGRegisterValidationAdapter(TChoiceAdapter);
  PPGRegisterValidationAdapter(TFieldAdapter);

finalization
  FreeAndNil(GAdapters);

end.
