unit PPG.UIA;

{ Nativer UI-Automation-Provider fuer Grid, TreeView und Listen (Phase 9b).

  Warum: MSAA kennt keine Tabellen und keine Hierarchie. Mit UIA sagt ein
  Screenreader "Zeile 5, Spalte Preis" bzw. "Ebene 2, aufgeklappt".

  Aufbau:
  - Ein Control liefert seine Daten ueber IPPGUiaSource (DIP, wie
    IPPGAccessibleChildren). Elemente sind Kennungen (TPPGUiaId: Art, A, B),
    keine Zeiger: Ist das Ziel weg, meldet die Quelle "ungueltig" und das
    Element antwortet UIA_E_ELEMENTNOTAVAILABLE.
  - TPPGUiaElement ist EIN COM-Objekt fuer alle Elemente und Muster. Welche
    Muster ein Element hat, entscheidet die Quelle (UiaHasPattern).
  - TPPGUiaRoot ist das Element des Controls selbst (Fragment-Wurzel). Es
    gehoert dem Control (TPPGCustomControl) und wird beim Zerstoeren des
    Fensters getrennt (Disconnect).

  Regeln (wie bei MSAA):
  - ProviderOptions = ServerSideProvider + UseComThreading: UIA ruft dann im
    Haupt-Thread (STA) auf, die VCL-Regel "nur Main-Thread" bleibt gueltig.
  - Keine Exception verlaesst eine COM-Methode (E_FAIL + Protokoll).
  - Aktionen von aussen (Select, Toggle, Expand, SetValue, Invoke, ...)
    laufen NIE im COM-Aufruf: sie kommen in eine Warteschlange, die Wurzel
    postet eine Nachricht, und das Control fuehrt sie danach aus. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.ActiveX, System.Classes, System.Types, System.SysUtils,
  System.Variants, System.Generics.Collections, PPG.UIA.Intf;

type
  /// Kennung eines Elements. Kind = 0 ist das Control selbst (Wurzel); die
  /// uebrigen Arten und die Bedeutung von A/B legt die Quelle fest.
  TPPGUiaId = record
    Kind: Integer;
    A: Integer;
    B: Integer;
  end;
  TPPGUiaIds = TArray<TPPGUiaId>;

  TPPGUiaAction = (uaSelect, uaAddToSelection, uaRemoveFromSelection, uaInvoke,
    uaExpand, uaCollapse, uaToggle, uaSetValue, uaScrollIntoView, uaSetFocus);

  /// Datenquelle eines Controls fuer UIA. Alle Methoden laufen im Haupt-Thread
  /// und duerfen nur lesen - ausser UiaExecute (aus der geposteten Nachricht).
  IPPGUiaSource = interface
    ['{3E7C1B52-8D4A-4F09-A6E2-5C91D0B7F384}']
    { Struktur }
    function UiaValid(const Id: TPPGUiaId): Boolean;
    function UiaParent(const Id: TPPGUiaId): TPPGUiaId;
    function UiaChildCount(const Id: TPPGUiaId): Integer;
    function UiaChild(const Id: TPPGUiaId; Index: Integer): TPPGUiaId;
    function UiaIndexInParent(const Id: TPPGUiaId): Integer;
    /// Element unter dem Punkt (Client-Koordinaten); Kind = 0: keins.
    function UiaElementAt(X, Y: Integer): TPPGUiaId;
    /// Element mit dem Tastaturfokus; Kind = 0, wenn das Control keinen hat.
    function UiaFocused: TPPGUiaId;
    /// Element zu einer MSAA-Kind-Id (fuer Ereignisse); Kind = 0: keins.
    function UiaFromAccChild(ChildId: Integer): TPPGUiaId;
    { Eigenschaften }
    function UiaControlType(const Id: TPPGUiaId): Integer;
    function UiaName(const Id: TPPGUiaId): string;
    /// Lage in Client-Koordinaten; leer = nicht sichtbar.
    function UiaRect(const Id: TPPGUiaId): TRect;
    function UiaEnabled(const Id: TPPGUiaId): Boolean;
    function UiaFocusable(const Id: TPPGUiaId): Boolean;
    /// Weitere Eigenschaften (Level, PositionInSet, ...). False = keine.
    function UiaProperty(const Id: TPPGUiaId; PropertyId: Integer; out Value: OleVariant): Boolean;
    function UiaHasPattern(const Id: TPPGUiaId; PatternId: Integer): Boolean;
    { Zustand der Muster }
    function UiaCanSelectMultiple: Boolean;
    function UiaSelection: TPPGUiaIds;
    function UiaIsSelected(const Id: TPPGUiaId): Boolean;
    procedure UiaGridSize(out Rows, Cols: Integer);
    /// Zelle an Position (0-basiert); Kind = 0: keine.
    function UiaGridItem(Row, Col: Integer): TPPGUiaId;
    procedure UiaGridPos(const Id: TPPGUiaId; out Row, Col: Integer);
    function UiaHeaders(Columns: Boolean): TPPGUiaIds;
    function UiaItemHeaders(const Id: TPPGUiaId; Columns: Boolean): TPPGUiaIds;
    function UiaValue(const Id: TPPGUiaId): string;
    function UiaReadOnly(const Id: TPPGUiaId): Boolean;
    function UiaExpandState(const Id: TPPGUiaId): Integer;
    function UiaToggleState(const Id: TPPGUiaId): Integer;
    { Aktion - nur aus der geposteten Nachricht, nie im COM-Aufruf }
    procedure UiaExecute(const Id: TPPGUiaId; Action: TPPGUiaAction; const Value: string);
  end;

  TPPGUiaRoot = class;

  /// Ein Element (oder die Wurzel). Implementiert alle unterstuetzten Muster;
  /// GetPatternProvider gibt sich nur fuer die Muster heraus, die die Quelle
  /// fuer dieses Element meldet.
  TPPGUiaElement = class(TInterfacedObject, IRawElementProviderSimple,
    IRawElementProviderFragment, IInvokeProvider, ISelectionProvider,
    ISelectionItemProvider, IValueProvider, IExpandCollapseProvider, IGridProvider,
    IGridItemProvider, ITableProvider, ITableItemProvider, IToggleProvider,
    IScrollItemProvider)
  private
    FRoot: TPPGUiaRoot;
    FRootRef: IInterface; // haelt die Wurzel am Leben (nicht bei der Wurzel selbst)
    FId: TPPGUiaId;
    function Check(out Res: HResult): Boolean;
    function Fail(const Method: string; E: TObject): HResult;
    function Enqueue(Action: TPPGUiaAction; const Value: string = ''): HResult;
  protected
    function IsRoot: Boolean;
  public
    constructor Create(ARoot: TPPGUiaRoot; const AId: TPPGUiaId);
    property Id: TPPGUiaId read FId;
    { IRawElementProviderSimple }
    function get_ProviderOptions(out pRetVal: Integer): HResult; stdcall;
    function GetPatternProvider(patternId: Integer; out pRetVal: IUnknown): HResult; stdcall;
    function GetPropertyValue(propertyId: Integer; out pRetVal: OleVariant): HResult; stdcall;
    function get_HostRawElementProvider(out pRetVal: IRawElementProviderSimple): HResult; stdcall;
    { IRawElementProviderFragment }
    function Navigate(direction: Integer; out pRetVal: IRawElementProviderFragment): HResult; stdcall;
    function GetRuntimeId(out pRetVal: PSafeArray): HResult; stdcall;
    function get_BoundingRectangle(out pRetVal: TPPGUiaRect): HResult; stdcall;
    function GetEmbeddedFragmentRoots(out pRetVal: PSafeArray): HResult; stdcall;
    function SetFocus: HResult; stdcall;
    function get_FragmentRoot(out pRetVal: IRawElementProviderFragmentRoot): HResult; stdcall;
    { IInvokeProvider }
    function Invoke: HResult; stdcall;
    { ISelectionProvider }
    function GetSelection(out pRetVal: PSafeArray): HResult; stdcall;
    function get_CanSelectMultiple(out pRetVal: BOOL): HResult; stdcall;
    function get_IsSelectionRequired(out pRetVal: BOOL): HResult; stdcall;
    { ISelectionItemProvider }
    function Select: HResult; stdcall;
    function AddToSelection: HResult; stdcall;
    function RemoveFromSelection: HResult; stdcall;
    function get_IsSelected(out pRetVal: BOOL): HResult; stdcall;
    function get_SelectionContainer(out pRetVal: IRawElementProviderSimple): HResult; stdcall;
    { IValueProvider }
    function SetValue(val: PWideChar): HResult; stdcall;
    function get_Value(out pRetVal: WideString): HResult; stdcall;
    function get_IsReadOnly(out pRetVal: BOOL): HResult; stdcall;
    { IExpandCollapseProvider }
    function Expand: HResult; stdcall;
    function Collapse: HResult; stdcall;
    function get_ExpandCollapseState(out pRetVal: Integer): HResult; stdcall;
    { IGridProvider }
    function GetItem(row, column: Integer; out pRetVal: IRawElementProviderSimple): HResult; stdcall;
    function get_RowCount(out pRetVal: Integer): HResult; stdcall;
    function get_ColumnCount(out pRetVal: Integer): HResult; stdcall;
    { IGridItemProvider }
    function get_Row(out pRetVal: Integer): HResult; stdcall;
    function get_Column(out pRetVal: Integer): HResult; stdcall;
    function get_RowSpan(out pRetVal: Integer): HResult; stdcall;
    function get_ColumnSpan(out pRetVal: Integer): HResult; stdcall;
    function get_ContainingGrid(out pRetVal: IRawElementProviderSimple): HResult; stdcall;
    { ITableProvider }
    function GetRowHeaders(out pRetVal: PSafeArray): HResult; stdcall;
    function GetColumnHeaders(out pRetVal: PSafeArray): HResult; stdcall;
    function get_RowOrColumnMajor(out pRetVal: Integer): HResult; stdcall;
    { ITableItemProvider }
    function GetRowHeaderItems(out pRetVal: PSafeArray): HResult; stdcall;
    function GetColumnHeaderItems(out pRetVal: PSafeArray): HResult; stdcall;
    { IToggleProvider }
    function Toggle: HResult; stdcall;
    function get_ToggleState(out pRetVal: Integer): HResult; stdcall;
    { IScrollItemProvider }
    function ScrollIntoView: HResult; stdcall;
  end;

  TPPGUiaQueued = record
    Id: TPPGUiaId;
    Action: TPPGUiaAction;
    Value: string;
  end;

  /// Wurzel (das Control selbst). Haelt die Quelle (ohne Referenzzaehlung),
  /// das Fenster und die Warteschlange der Aktionen.
  TPPGUiaRoot = class(TPPGUiaElement, IRawElementProviderFragmentRoot)
  private
    FSource: IPPGUiaSource;
    FWnd: HWND;
    FName: string;
    FClassName: string;
    FQueue: TList<TPPGUiaQueued>;
    FPosted: Boolean;
  public
    /// AName = AutomationId (Komponentenname), AClassName = Klassenname.
    constructor CreateRoot(const ASource: IPPGUiaSource; AWnd: HWND;
      const AName, AClassName: string);
    destructor Destroy; override;
    /// Trennt die Quelle: alle Elemente antworten ab jetzt "nicht verfuegbar".
    procedure Disconnect;
    function Connected: Boolean;
    /// COM-Objekt fuer eine Kennung (Kind = 0: die Wurzel selbst).
    function ElementFor(const AId: TPPGUiaId): IRawElementProviderSimple;
    /// Aktion vormerken und das Fenster per PostMessage wecken.
    procedure Enqueue(const AId: TPPGUiaId; Action: TPPGUiaAction; const Value: string);
    /// Vorgemerkte Aktionen ausfuehren (aus der geposteten Nachricht).
    procedure RunQueued;
    /// Ereignis an UIA-Clients (nur wenn jemand zuhoert).
    procedure RaiseEvent(const AId: TPPGUiaId; EventId: Integer);
    procedure RaisePropertyChanged(const AId: TPPGUiaId; PropertyId: Integer;
      const NewValue: OleVariant);
    function QueuedCount: Integer;
    property Source: IPPGUiaSource read FSource;
    property Wnd: HWND read FWnd;
    { IRawElementProviderFragmentRoot }
    function ElementProviderFromPoint(x, y: Double; out pRetVal: IRawElementProviderFragment): HResult; stdcall;
    function GetFocus(out pRetVal: IRawElementProviderFragment): HResult; stdcall;
  end;

/// Kennung bauen bzw. vergleichen.
function PPGUiaId(AKind: Integer; AA: Integer = 0; AB: Integer = 0): TPPGUiaId;
function PPGUiaSame(const X, Y: TPPGUiaId): Boolean;
function PPGUiaIsRoot(const Id: TPPGUiaId): Boolean;

/// Registrierte Nachricht, mit der die Wurzel ihr Fenster weckt.
function PPGUiaActionMessage: Cardinal;

var
  /// Schalter fuer die ganze Anwendung: False = kein nativer UIA-Provider,
  /// alle Controls bleiben bei MSAA (Notbremse, falls ein Screenreader mit
  /// dem Provider Probleme hat). Vor dem ersten WM_GETOBJECT setzen.
  PPGUiaEnabled: Boolean = True;

implementation

uses
  PPG.ErrorHandler;

var
  GMsgUiaAction: Cardinal = 0;

function PPGUiaActionMessage: Cardinal;
begin
  if GMsgUiaAction = 0 then
    GMsgUiaAction := RegisterWindowMessage('PPGlow.UiaAction');
  Result := GMsgUiaAction;
end;

function PPGUiaId(AKind, AA, AB: Integer): TPPGUiaId;
begin
  Result.Kind := AKind;
  Result.A := AA;
  Result.B := AB;
end;

function PPGUiaSame(const X, Y: TPPGUiaId): Boolean;
begin
  Result := (X.Kind = Y.Kind) and (X.A = Y.A) and (X.B = Y.B);
end;

function PPGUiaIsRoot(const Id: TPPGUiaId): Boolean;
begin
  Result := Id.Kind = 0;
end;

function IntSafeArray(const V: array of Integer): PSafeArray;
var
  I, Idx, X: Integer;
begin
  Result := SafeArrayCreateVector(VT_I4, 0, Length(V));
  if Result = nil then
    Exit;
  for I := 0 to High(V) do
  begin
    Idx := I;
    X := V[I];
    SafeArrayPutElement(Result, Idx, X);
  end;
end;

/// SAFEARRAY von IRawElementProviderSimple (VT_UNKNOWN). Fuer VT_UNKNOWN
/// erwartet SafeArrayPutElement den Zeiger selbst (keine weitere Indirektion).
function ElementSafeArray(Root: TPPGUiaRoot; const Ids: TPPGUiaIds): PSafeArray;
var
  I, Idx: Integer;
  El: IRawElementProviderSimple;
  Unk: IUnknown;
begin
  Result := SafeArrayCreateVector(VT_UNKNOWN, 0, Length(Ids));
  if Result = nil then
    Exit;
  for I := 0 to High(Ids) do
  begin
    Idx := I;
    El := Root.ElementFor(Ids[I]);
    Unk := El;
    SafeArrayPutElement(Result, Idx, Pointer(Unk)^);
  end;
end;

{ TPPGUiaElement }

constructor TPPGUiaElement.Create(ARoot: TPPGUiaRoot; const AId: TPPGUiaId);
begin
  inherited Create;
  FRoot := ARoot;
  FId := AId;
  if (ARoot <> nil) and (ARoot <> Self) then
    FRootRef := ARoot as IInterface;
end;

function TPPGUiaElement.IsRoot: Boolean;
begin
  Result := FRoot = Self;
end;

function TPPGUiaElement.Check(out Res: HResult): Boolean;
begin
  Result := (FRoot <> nil) and FRoot.Connected and
    (IsRoot or FRoot.Source.UiaValid(FId));
  if Result then
    Res := S_OK
  else
    Res := UIA_E_ELEMENTNOTAVAILABLE;
end;

function TPPGUiaElement.Fail(const Method: string; E: TObject): HResult;
begin
  // COM-Grenze: niemals weiterwerfen, nur protokollieren
  if E is Exception then
    TPPGErrorHandler.LogWarning(Self, 'UIA.' + Method + ': ' + Exception(E).Message);
  Result := E_FAIL;
end;

function TPPGUiaElement.Enqueue(Action: TPPGUiaAction; const Value: string): HResult;
begin
  if not Check(Result) then
    Exit;
  try
    if not FRoot.Source.UiaEnabled(FId) then
      Exit(UIA_E_ELEMENTNOTENABLED);
    FRoot.Enqueue(FId, Action, Value);
    Result := S_OK;
  except
    Result := Fail('Enqueue', ExceptObject);
  end;
end;

function TPPGUiaElement.get_ProviderOptions(out pRetVal: Integer): HResult;
begin
  pRetVal := ProviderOptions_ServerSideProvider or ProviderOptions_UseComThreading;
  Result := S_OK;
end;

function TPPGUiaElement.GetPatternProvider(patternId: Integer; out pRetVal: IUnknown): HResult;
begin
  pRetVal := nil;
  if not Check(Result) then
    Exit;
  try
    if FRoot.Source.UiaHasPattern(FId, patternId) then
      pRetVal := Self as IRawElementProviderSimple;
    Result := S_OK;
  except
    Result := Fail('GetPatternProvider', ExceptObject);
  end;
end;

function TPPGUiaElement.GetPropertyValue(propertyId: Integer; out pRetVal: OleVariant): HResult;
var
  Src: IPPGUiaSource;
  R: TRect;
  F: TPPGUiaId;
begin
  pRetVal := Unassigned;
  if not Check(Result) then
    Exit;
  try
    Src := FRoot.Source;
    // Zuerst die Quelle: sie kann jede Eigenschaft ueberschreiben
    if Src.UiaProperty(FId, propertyId, pRetVal) then
      Exit(S_OK);
    case propertyId of
      UIA_ControlTypePropertyId: pRetVal := Src.UiaControlType(FId);
      UIA_NamePropertyId: pRetVal := Src.UiaName(FId);
      UIA_IsEnabledPropertyId: pRetVal := Src.UiaEnabled(FId);
      UIA_IsKeyboardFocusablePropertyId: pRetVal := Src.UiaFocusable(FId);
      UIA_HasKeyboardFocusPropertyId:
        begin
          F := Src.UiaFocused;
          pRetVal := (not IsRoot) and PPGUiaSame(F, FId);
        end;
      UIA_IsOffscreenPropertyId:
        if not IsRoot then
        begin
          R := Src.UiaRect(FId);
          pRetVal := IsRectEmpty(R);
        end;
      UIA_AutomationIdPropertyId:
        if IsRoot and (FRoot.FName <> '') then
          pRetVal := FRoot.FName;
      UIA_ClassNamePropertyId:
        if IsRoot then
          pRetVal := FRoot.FClassName;
      UIA_FrameworkIdPropertyId: pRetVal := 'Win32';
      UIA_IsControlElementPropertyId, UIA_IsContentElementPropertyId: pRetVal := True;
      UIA_ProcessIdPropertyId: pRetVal := Integer(GetCurrentProcessId);
    end;
    Result := S_OK;
  except
    Result := Fail('GetPropertyValue', ExceptObject);
  end;
end;

function TPPGUiaElement.get_HostRawElementProvider(out pRetVal: IRawElementProviderSimple): HResult;
begin
  pRetVal := nil;
  if not Check(Result) then
    Exit;
  try
    // Nur die Wurzel haengt am Fenster; UIA ergaenzt Lage, Fokus usw.
    if IsRoot then
      Result := PPGUiaHostProviderFromHwnd(FRoot.Wnd, pRetVal)
    else
      Result := S_OK;
    if Failed(Result) then
    begin
      pRetVal := nil;
      Result := S_OK;
    end;
  except
    Result := Fail('HostRawElementProvider', ExceptObject);
  end;
end;

function TPPGUiaElement.Navigate(direction: Integer; out pRetVal: IRawElementProviderFragment): HResult;
var
  Src: IPPGUiaSource;
  P, T: TPPGUiaId;
  Idx, N: Integer;
  Found: Boolean;
begin
  pRetVal := nil;
  if not Check(Result) then
    Exit;
  try
    Src := FRoot.Source;
    Found := False;
    case direction of
      NavigateDirection_Parent:
        if not IsRoot then
        begin
          T := Src.UiaParent(FId);
          Found := True;
        end;
      NavigateDirection_NextSibling, NavigateDirection_PreviousSibling:
        if not IsRoot then
        begin
          P := Src.UiaParent(FId);
          Idx := Src.UiaIndexInParent(FId);
          if direction = NavigateDirection_NextSibling then
            Inc(Idx)
          else
            Dec(Idx);
          if (Idx >= 0) and (Idx < Src.UiaChildCount(P)) then
          begin
            T := Src.UiaChild(P, Idx);
            Found := True;
          end;
        end;
      NavigateDirection_FirstChild, NavigateDirection_LastChild:
        begin
          N := Src.UiaChildCount(FId);
          if N > 0 then
          begin
            if direction = NavigateDirection_FirstChild then
              T := Src.UiaChild(FId, 0)
            else
              T := Src.UiaChild(FId, N - 1);
            Found := True;
          end;
        end;
    end;
    if Found then
      pRetVal := FRoot.ElementFor(T) as IRawElementProviderFragment;
    Result := S_OK;
  except
    Result := Fail('Navigate', ExceptObject);
  end;
end;

function TPPGUiaElement.GetRuntimeId(out pRetVal: PSafeArray): HResult;
begin
  pRetVal := nil;
  if not Check(Result) then
    Exit;
  try
    // Die Wurzel haengt am Fenster: UIA bildet ihre Id aus dem HWND
    if not IsRoot then
      pRetVal := IntSafeArray([PPGUiaAppendRuntimeId, FId.Kind, FId.A, FId.B]);
    Result := S_OK;
  except
    Result := Fail('GetRuntimeId', ExceptObject);
  end;
end;

function TPPGUiaElement.get_BoundingRectangle(out pRetVal: TPPGUiaRect): HResult;
var
  R: TRect;
  P: TPoint;
begin
  FillChar(pRetVal, SizeOf(pRetVal), 0);
  if not Check(Result) then
    Exit;
  try
    if not IsRoot then
    begin
      R := FRoot.Source.UiaRect(FId);
      if not IsRectEmpty(R) then
      begin
        P := R.TopLeft;
        Winapi.Windows.ClientToScreen(FRoot.Wnd, P);
        pRetVal.Left := P.X;
        pRetVal.Top := P.Y;
        pRetVal.Width := R.Right - R.Left;
        pRetVal.Height := R.Bottom - R.Top;
      end;
    end;
    Result := S_OK;
  except
    Result := Fail('BoundingRectangle', ExceptObject);
  end;
end;

function TPPGUiaElement.GetEmbeddedFragmentRoots(out pRetVal: PSafeArray): HResult;
begin
  pRetVal := nil;
  Result := S_OK;
end;

function TPPGUiaElement.SetFocus: HResult;
begin
  Result := Enqueue(uaSetFocus);
end;

function TPPGUiaElement.get_FragmentRoot(out pRetVal: IRawElementProviderFragmentRoot): HResult;
begin
  pRetVal := nil;
  if not Check(Result) then
    Exit;
  pRetVal := FRoot as IRawElementProviderFragmentRoot;
end;

function TPPGUiaElement.Invoke: HResult;
begin
  Result := Enqueue(uaInvoke);
end;

function TPPGUiaElement.GetSelection(out pRetVal: PSafeArray): HResult;
begin
  pRetVal := nil;
  if not Check(Result) then
    Exit;
  try
    pRetVal := ElementSafeArray(FRoot, FRoot.Source.UiaSelection);
    Result := S_OK;
  except
    Result := Fail('GetSelection', ExceptObject);
  end;
end;

function TPPGUiaElement.get_CanSelectMultiple(out pRetVal: BOOL): HResult;
begin
  pRetVal := False;
  if not Check(Result) then
    Exit;
  try
    pRetVal := FRoot.Source.UiaCanSelectMultiple;
  except
    Result := Fail('CanSelectMultiple', ExceptObject);
  end;
end;

function TPPGUiaElement.get_IsSelectionRequired(out pRetVal: BOOL): HResult;
begin
  pRetVal := False;
  Check(Result);
end;

function TPPGUiaElement.Select: HResult;
begin
  Result := Enqueue(uaSelect);
end;

function TPPGUiaElement.AddToSelection: HResult;
begin
  if not Check(Result) then
    Exit;
  // Einfachauswahl: Hinzufuegen nur, wenn noch nichts gewaehlt ist
  try
    if not FRoot.Source.UiaCanSelectMultiple and (Length(FRoot.Source.UiaSelection) > 0) and
      not FRoot.Source.UiaIsSelected(FId) then
      Exit(UIA_E_INVALIDOPERATION);
  except
    Exit(Fail('AddToSelection', ExceptObject));
  end;
  Result := Enqueue(uaAddToSelection);
end;

function TPPGUiaElement.RemoveFromSelection: HResult;
begin
  Result := Enqueue(uaRemoveFromSelection);
end;

function TPPGUiaElement.get_IsSelected(out pRetVal: BOOL): HResult;
begin
  pRetVal := False;
  if not Check(Result) then
    Exit;
  try
    pRetVal := FRoot.Source.UiaIsSelected(FId);
  except
    Result := Fail('IsSelected', ExceptObject);
  end;
end;

function TPPGUiaElement.get_SelectionContainer(out pRetVal: IRawElementProviderSimple): HResult;
begin
  pRetVal := nil;
  if not Check(Result) then
    Exit;
  pRetVal := FRoot as IRawElementProviderSimple;
end;

function TPPGUiaElement.SetValue(val: PWideChar): HResult;
var
  S: string;
begin
  if not Check(Result) then
    Exit;
  try
    if FRoot.Source.UiaReadOnly(FId) then
      Exit(UIA_E_INVALIDOPERATION);
  except
    Exit(Fail('SetValue', ExceptObject));
  end;
  if val = nil then
    S := ''
  else
    S := string(WideString(val));
  Result := Enqueue(uaSetValue, S);
end;

function TPPGUiaElement.get_Value(out pRetVal: WideString): HResult;
begin
  pRetVal := '';
  if not Check(Result) then
    Exit;
  try
    pRetVal := FRoot.Source.UiaValue(FId);
  except
    Result := Fail('Value', ExceptObject);
  end;
end;

function TPPGUiaElement.get_IsReadOnly(out pRetVal: BOOL): HResult;
begin
  pRetVal := True;
  if not Check(Result) then
    Exit;
  try
    pRetVal := FRoot.Source.UiaReadOnly(FId);
  except
    Result := Fail('IsReadOnly', ExceptObject);
  end;
end;

function TPPGUiaElement.Expand: HResult;
begin
  if not Check(Result) then
    Exit;
  try
    if FRoot.Source.UiaExpandState(FId) = ExpandCollapseState_LeafNode then
      Exit(UIA_E_INVALIDOPERATION);
  except
    Exit(Fail('Expand', ExceptObject));
  end;
  Result := Enqueue(uaExpand);
end;

function TPPGUiaElement.Collapse: HResult;
begin
  if not Check(Result) then
    Exit;
  try
    if FRoot.Source.UiaExpandState(FId) = ExpandCollapseState_LeafNode then
      Exit(UIA_E_INVALIDOPERATION);
  except
    Exit(Fail('Collapse', ExceptObject));
  end;
  Result := Enqueue(uaCollapse);
end;

function TPPGUiaElement.get_ExpandCollapseState(out pRetVal: Integer): HResult;
begin
  pRetVal := ExpandCollapseState_LeafNode;
  if not Check(Result) then
    Exit;
  try
    pRetVal := FRoot.Source.UiaExpandState(FId);
  except
    Result := Fail('ExpandCollapseState', ExceptObject);
  end;
end;

function TPPGUiaElement.GetItem(row, column: Integer; out pRetVal: IRawElementProviderSimple): HResult;
var
  Rows, Cols: Integer;
  T: TPPGUiaId;
begin
  pRetVal := nil;
  if not Check(Result) then
    Exit;
  try
    FRoot.Source.UiaGridSize(Rows, Cols);
    if (row < 0) or (row >= Rows) or (column < 0) or (column >= Cols) then
      Exit(E_INVALIDARG);
    T := FRoot.Source.UiaGridItem(row, column);
    if PPGUiaIsRoot(T) then
      Exit(E_INVALIDARG);
    pRetVal := FRoot.ElementFor(T);
    Result := S_OK;
  except
    Result := Fail('GetItem', ExceptObject);
  end;
end;

function TPPGUiaElement.get_RowCount(out pRetVal: Integer): HResult;
var
  Cols: Integer;
begin
  pRetVal := 0;
  if not Check(Result) then
    Exit;
  try
    FRoot.Source.UiaGridSize(pRetVal, Cols);
  except
    Result := Fail('RowCount', ExceptObject);
  end;
end;

function TPPGUiaElement.get_ColumnCount(out pRetVal: Integer): HResult;
var
  Rows: Integer;
begin
  pRetVal := 0;
  if not Check(Result) then
    Exit;
  try
    FRoot.Source.UiaGridSize(Rows, pRetVal);
  except
    Result := Fail('ColumnCount', ExceptObject);
  end;
end;

function TPPGUiaElement.get_Row(out pRetVal: Integer): HResult;
var
  C: Integer;
begin
  pRetVal := 0;
  if not Check(Result) then
    Exit;
  try
    FRoot.Source.UiaGridPos(FId, pRetVal, C);
  except
    Result := Fail('Row', ExceptObject);
  end;
end;

function TPPGUiaElement.get_Column(out pRetVal: Integer): HResult;
var
  R: Integer;
begin
  pRetVal := 0;
  if not Check(Result) then
    Exit;
  try
    FRoot.Source.UiaGridPos(FId, R, pRetVal);
  except
    Result := Fail('Column', ExceptObject);
  end;
end;

function TPPGUiaElement.get_RowSpan(out pRetVal: Integer): HResult;
begin
  pRetVal := 1;
  Check(Result);
end;

function TPPGUiaElement.get_ColumnSpan(out pRetVal: Integer): HResult;
begin
  pRetVal := 1;
  Check(Result);
end;

function TPPGUiaElement.get_ContainingGrid(out pRetVal: IRawElementProviderSimple): HResult;
begin
  pRetVal := nil;
  if not Check(Result) then
    Exit;
  pRetVal := FRoot as IRawElementProviderSimple;
end;

function TPPGUiaElement.GetRowHeaders(out pRetVal: PSafeArray): HResult;
begin
  pRetVal := nil;
  if not Check(Result) then
    Exit;
  try
    pRetVal := ElementSafeArray(FRoot, FRoot.Source.UiaHeaders(False));
  except
    Result := Fail('RowHeaders', ExceptObject);
  end;
end;

function TPPGUiaElement.GetColumnHeaders(out pRetVal: PSafeArray): HResult;
begin
  pRetVal := nil;
  if not Check(Result) then
    Exit;
  try
    pRetVal := ElementSafeArray(FRoot, FRoot.Source.UiaHeaders(True));
  except
    Result := Fail('ColumnHeaders', ExceptObject);
  end;
end;

function TPPGUiaElement.get_RowOrColumnMajor(out pRetVal: Integer): HResult;
begin
  pRetVal := RowOrColumnMajor_RowMajor;
  Check(Result);
end;

function TPPGUiaElement.GetRowHeaderItems(out pRetVal: PSafeArray): HResult;
begin
  pRetVal := nil;
  if not Check(Result) then
    Exit;
  try
    pRetVal := ElementSafeArray(FRoot, FRoot.Source.UiaItemHeaders(FId, False));
  except
    Result := Fail('RowHeaderItems', ExceptObject);
  end;
end;

function TPPGUiaElement.GetColumnHeaderItems(out pRetVal: PSafeArray): HResult;
begin
  pRetVal := nil;
  if not Check(Result) then
    Exit;
  try
    pRetVal := ElementSafeArray(FRoot, FRoot.Source.UiaItemHeaders(FId, True));
  except
    Result := Fail('ColumnHeaderItems', ExceptObject);
  end;
end;

function TPPGUiaElement.Toggle: HResult;
begin
  Result := Enqueue(uaToggle);
end;

function TPPGUiaElement.get_ToggleState(out pRetVal: Integer): HResult;
begin
  pRetVal := ToggleState_Off;
  if not Check(Result) then
    Exit;
  try
    pRetVal := FRoot.Source.UiaToggleState(FId);
  except
    Result := Fail('ToggleState', ExceptObject);
  end;
end;

function TPPGUiaElement.ScrollIntoView: HResult;
begin
  Result := Enqueue(uaScrollIntoView);
end;

{ TPPGUiaRoot }

constructor TPPGUiaRoot.CreateRoot(const ASource: IPPGUiaSource; AWnd: HWND;
  const AName, AClassName: string);
begin
  inherited Create(Self, PPGUiaId(0));
  FSource := ASource;
  FWnd := AWnd;
  FName := AName;
  FClassName := AClassName;
  FQueue := TList<TPPGUiaQueued>.Create;
  PPGUiaActionMessage;
end;

destructor TPPGUiaRoot.Destroy;
begin
  FSource := nil;
  FreeAndNil(FQueue);
  inherited Destroy;
end;

procedure TPPGUiaRoot.Disconnect;
begin
  FSource := nil;
  FWnd := 0;
  if FQueue <> nil then
    FQueue.Clear;
end;

function TPPGUiaRoot.Connected: Boolean;
begin
  Result := (FSource <> nil) and (FWnd <> 0);
end;

function TPPGUiaRoot.ElementFor(const AId: TPPGUiaId): IRawElementProviderSimple;
begin
  if PPGUiaIsRoot(AId) then
    Result := Self
  else
    Result := TPPGUiaElement.Create(Self, AId);
end;

procedure TPPGUiaRoot.Enqueue(const AId: TPPGUiaId; Action: TPPGUiaAction; const Value: string);
var
  Q: TPPGUiaQueued;
begin
  Q.Id := AId;
  Q.Action := Action;
  Q.Value := Value;
  FQueue.Add(Q);
  if not FPosted and (FWnd <> 0) then
  begin
    FPosted := True;
    PostMessage(FWnd, PPGUiaActionMessage, 0, 0);
  end;
end;

function TPPGUiaRoot.QueuedCount: Integer;
begin
  if FQueue = nil then
    Result := 0
  else
    Result := FQueue.Count;
end;

procedure TPPGUiaRoot.RunQueued;
var
  Items: TArray<TPPGUiaQueued>;
  I: Integer;
begin
  FPosted := False;
  if not Connected or (FQueue.Count = 0) then
    Exit;
  // Kopie: Anwender-Code kann neue Aktionen ausloesen oder das Control freigeben
  Items := FQueue.ToArray;
  FQueue.Clear;
  for I := 0 to High(Items) do
  begin
    if not Connected then
      Break;
    if PPGUiaIsRoot(Items[I].Id) or FSource.UiaValid(Items[I].Id) then
      FSource.UiaExecute(Items[I].Id, Items[I].Action, Items[I].Value);
  end;
end;

procedure TPPGUiaRoot.RaiseEvent(const AId: TPPGUiaId; EventId: Integer);
begin
  if Connected and PPGUiaClientsAreListening then
    PPGUiaRaiseAutomationEvent(ElementFor(AId), EventId);
end;

procedure TPPGUiaRoot.RaisePropertyChanged(const AId: TPPGUiaId; PropertyId: Integer;
  const NewValue: OleVariant);
begin
  if Connected and PPGUiaClientsAreListening then
    PPGUiaRaisePropertyChanged(ElementFor(AId), PropertyId, Unassigned, NewValue);
end;

function TPPGUiaRoot.ElementProviderFromPoint(x, y: Double;
  out pRetVal: IRawElementProviderFragment): HResult;
var
  P: TPoint;
  T: TPPGUiaId;
begin
  pRetVal := nil;
  if not Check(Result) then
    Exit;
  try
    P := Point(Round(x), Round(y));
    Winapi.Windows.ScreenToClient(FWnd, P);
    T := FSource.UiaElementAt(P.X, P.Y);
    if not PPGUiaIsRoot(T) then
      pRetVal := ElementFor(T) as IRawElementProviderFragment;
    Result := S_OK;
  except
    Result := Fail('ElementProviderFromPoint', ExceptObject);
  end;
end;

function TPPGUiaRoot.GetFocus(out pRetVal: IRawElementProviderFragment): HResult;
var
  T: TPPGUiaId;
begin
  pRetVal := nil;
  if not Check(Result) then
    Exit;
  try
    T := FSource.UiaFocused;
    if not PPGUiaIsRoot(T) then
      pRetVal := ElementFor(T) as IRawElementProviderFragment;
    Result := S_OK;
  except
    Result := Fail('GetFocus', ExceptObject);
  end;
end;

end.
