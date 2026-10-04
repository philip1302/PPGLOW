unit PPG.Accessibility;

{ Barrierefreiheit (MSAA/IAccessible) fuer alle PPGlow-Controls.

  Owner-Draw-Controls sind fuer Screenreader (Narrator, NVDA, JAWS) sonst
  nur "ein Fenster ohne Namen". Jedes Control beantwortet deshalb
  WM_GETOBJECT(OBJID_CLIENT) mit einem TPPGAccessible. Windows bruecktet
  MSAA automatisch nach UI Automation - das funktioniert von XE2 bis 13.

  Aufteilung:
  - Name, Rolle, Zustand, Beschreibung, Tastenkuerzel, Standardaktion
    liefert das Control ueber IPPGAccessibleHost.
  - Position, Eltern, Kind-Fenster, Navigation, Hit-Test, Fokus liefert der
    Windows-Standard-Proxy (CreateStdAccessibleObject) - der ist dafuer korrekt.

  Robustheit:
  - Diese Methoden werden ueber COM von FREMDEN Prozessen aufgerufen.
    Eine Delphi-Exception darf NIE die COM-Grenze ueberschreiten -> jede
    Methode faengt alles ab und liefert E_FAIL (Fehler wird protokolliert).
  - Screenreader koennen das Objekt laenger halten als das Control lebt.
    Das Control ruft beim Zerstoeren/Neuerzeugen des Fensters Disconnect
    auf; danach antworten alle Methoden mit CO_E_OBJNOTCONNECTED.
  - accDoDefaultAction fuehrt Anwender-Code NICHT innerhalb des COM-Aufrufs
    aus, sondern postet eine Nachricht (keine Reentranz im Screenreader). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.ActiveX, Winapi.oleacc, System.Classes, System.Variants;

type
  IPPGAccessibleHost = interface
    ['{9C4B2E71-0A3D-4F86-B5E1-7D2C8A6F3B94}']
    function AccName: string;
    function AccRole: Integer;
    function AccState: Integer;
    function AccDescription: string;
    function AccValue: string;
    function AccKeyboardShortcut: string;
    function AccDefaultAction: string;
    procedure AccDoDefaultAction;
  end;

  /// Optional zusaetzlich zu IPPGAccessibleHost: virtuelle Kind-Elemente ohne
  /// eigenes Fenster (Listeneintraege, Reiter). Ids laufen von 1 bis
  /// AccChildCount; 0 ist das Control selbst.
  IPPGAccessibleChildren = interface
    ['{5B0E7A3C-9D21-4F68-8C4A-E2F17B6D0A93}']
    function AccChildCount: Integer;
    function AccChildName(Id: Integer): string;
    function AccChildRole(Id: Integer): Integer;
    function AccChildState(Id: Integer): Integer;
    /// Lage in Client-Koordinaten des Controls (leer = nicht sichtbar).
    function AccChildRect(Id: Integer): TRect;
    /// Kind unter dem Punkt (Client-Koordinaten), 0 = keins.
    function AccChildAt(X, Y: Integer): Integer;
    function AccChildDefaultAction(Id: Integer): string;
    /// Fuehrt die Standardaktion aus - nur per PostMessage, nie im COM-Aufruf.
    procedure AccChildDoDefault(Id: Integer);
    /// Kind mit dem Fokus bzw. das gewaehlte Kind, 0 = keins.
    function AccFocusedChild: Integer;
    function AccSelectedChild: Integer;
  end;

  /// Optional zusaetzlich zu IPPGAccessibleChildren: Mehrfachauswahl
  /// (ListBox, Baum, Grid). accSelection liefert dann alle gewaehlten Kinder,
  /// accSelect wird an das Control weitergereicht.
  IPPGAccessibleMultiSelection = interface
    ['{A1C6E3D8-5B72-4F90-8D14-3E9F7A2B6C05}']
    /// Ids (1..AccChildCount) aller gewaehlten Kinder, aufsteigend.
    function AccSelectedChildren: TArray<Integer>;
    /// SELFLAG_* auf ein Kind anwenden (nur per PostMessage ausfuehren, wenn
    /// Anwender-Code laeuft); False = nicht unterstuetzt.
    function AccChildSelect(Id: Integer; Flags: Integer): Boolean;
  end;

  /// IEnumVARIANT mit festen Parametertypen (die Deklaration in Winapi.ActiveX
  /// unterscheidet sich je Delphi-Version). Gleiche GUID wie IEnumVARIANT.
  IPPGEnumVariant = interface(IUnknown)
    ['{00020404-0000-0000-C000-000000000046}']
    function Next(celt: Cardinal; rgvar: Pointer; pceltFetched: PCardinal): HResult; stdcall;
    function Skip(celt: Cardinal): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out Enum: IPPGEnumVariant): HResult; stdcall;
  end;

  TPPGAccessible = class(TInterfacedObject, IDispatch, IAccessible, IPPGEnumVariant)
  private
    // Kein Referenzzaehler-Effekt (TComponent zaehlt nicht) - wird ueber
    // Disconnect vor dem Zerstoeren des Controls auf nil gesetzt.
    FHost: IPPGAccessibleHost;
    FKids: IPPGAccessibleChildren; // nil = keine virtuellen Kinder
    FMulti: IPPGAccessibleMultiSelection; // nil = Einfachauswahl
    FWnd: HWND;
    FStd: IAccessible;
    FStdEnum: IPPGEnumVariant; // Kind-Fenster als Objekte (AccessibleChildren)
    FStdEnumDone: Boolean;     // Kind-Fenster aufgezaehlt, weiter mit virtuellen
    FEnumPos: Integer;         // zuletzt gelieferte virtuelle Id
    function StdEnum: IPPGEnumVariant;
    function Connected(out Res: HResult): Boolean;
    function IsSelf(const varChild: OleVariant): Boolean;
    /// True fuer eine gueltige virtuelle Kind-Id (1..AccChildCount).
    function IsVirtual(const varChild: OleVariant; out Id: Integer): Boolean;
    function KidCount: Integer;
    function Fail(const Method: string; E: TObject): HResult;
  public
    constructor Create(const AHost: IPPGAccessibleHost; AWnd: HWND);
    destructor Destroy; override;
    procedure Disconnect;
    { IDispatch - nicht unterstuetzt (Screenreader nutzen die vtable) }
    function GetTypeInfoCount(out Count: Integer): HResult; stdcall;
    function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer;
      NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
    function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
      Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
    { IAccessible }
    function Get_accParent(out ppdispParent: IDispatch): HResult; stdcall;
    function Get_accChildCount(out pcountChildren: Integer): HResult; stdcall;
    function Get_accChild(varChild: OleVariant; out ppdispChild: IDispatch): HResult; stdcall;
    function Get_accName(varChild: OleVariant; out pszName: WideString): HResult; stdcall;
    function Get_accValue(varChild: OleVariant; out pszValue: WideString): HResult; stdcall;
    function Get_accDescription(varChild: OleVariant; out pszDescription: WideString): HResult; stdcall;
    function Get_accRole(varChild: OleVariant; out pvarRole: OleVariant): HResult; stdcall;
    function Get_accState(varChild: OleVariant; out pvarState: OleVariant): HResult; stdcall;
    function Get_accHelp(varChild: OleVariant; out pszHelp: WideString): HResult; stdcall;
    function Get_accHelpTopic(out pszHelpFile: WideString; varChild: OleVariant;
      out pidTopic: Integer): HResult; stdcall;
    function Get_accKeyboardShortcut(varChild: OleVariant; out pszKeyboardShortcut: WideString): HResult; stdcall;
    function Get_accFocus(out pvarChild: OleVariant): HResult; stdcall;
    function Get_accSelection(out pvarChildren: OleVariant): HResult; stdcall;
    function Get_accDefaultAction(varChild: OleVariant; out pszDefaultAction: WideString): HResult; stdcall;
    function accSelect(flagsSelect: Integer; varChild: OleVariant): HResult; stdcall;
    function accLocation(out pxLeft: Integer; out pyTop: Integer; out pcxWidth: Integer;
      out pcyHeight: Integer; varChild: OleVariant): HResult; stdcall;
    function accNavigate(navDir: Integer; varStart: OleVariant; out pvarEndUpAt: OleVariant): HResult; stdcall;
    function accHitTest(xLeft: Integer; yTop: Integer; out pvarChild: OleVariant): HResult; stdcall;
    function accDoDefaultAction(varChild: OleVariant): HResult; stdcall;
    function Set_accName(varChild: OleVariant; const pszName: WideString): HResult; stdcall;
    function Set_accValue(varChild: OleVariant; const pszValue: WideString): HResult; stdcall;
    { IEnumVARIANT - vom Standard-Proxy (liefert Kind-Fenster als IDispatch) }
    function Next(celt: Cardinal; rgvar: Pointer; pceltFetched: PCardinal): HResult; stdcall;
    function Skip(celt: Cardinal): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out Enum: IPPGEnumVariant): HResult; stdcall;
  end;

const
  /// OBJID_CLIENT als vorzeichenbehafteter 32-Bit-Wert (Winapi deklariert
  /// $FFFFFFFC als DWORD - ein Cast davon ist kein gueltiger Konstantenausdruck).
  PPGObjIdClient = -4;

/// "Alt+X" fuer eine Beschriftung mit "&X", sonst ''.
function PPGAccShortcutFromCaption(const Caption: string): string;
/// Beschriftung ohne Accelerator-Markierung ("&Speichern" -> "Speichern").
function PPGAccStripHotkey(const Caption: string): string;
/// Meldet eine Aenderung an Screenreader (EVENT_OBJECT_STATECHANGE usw.).
procedure PPGAccNotify(Wnd: HWND; Event: DWORD);
/// Wie PPGAccNotify, aber fuer ein virtuelles Kind-Element (ChildId > 0).
procedure PPGAccNotifyChild(Wnd: HWND; Event: DWORD; ChildId: Integer);
/// Setzt den Namen eines FREMDEN Fensters (z.B. des nativen Edits in einem
/// PPGlow-Feld) per IAccPropServices; Name = '' entfernt ihn wieder.
/// Ohne COM oder bei Fehlern passiert nichts (Barrierefreiheit ist Zusatz).
procedure PPGAccSetWindowName(Wnd: HWND; const Name: string);

implementation

uses
  System.SysUtils, System.Types, PPG.ErrorHandler;

const
  CO_E_OBJNOTCONNECTED = HResult($800401FD);

// Eigener Import mit "out IAccessible": korrekte Referenzzaehlung, unabhaengig
// von der (je Delphi-Version unterschiedlichen) Deklaration in Winapi.oleacc.
// Ebenso NotifyWinEvent: Parametertypen unterscheiden sich je Delphi-Version
// (Cardinal vs. Longint) - mit festen Typen keine Bereichsfehler.
procedure PPG_NotifyWinEvent(Event: DWORD; Wnd: HWND; idObject, idChild: Longint); stdcall;
  external user32 name 'NotifyWinEvent';

function PPG_CreateStdAccessibleObject(hwnd: HWND; idObject: Longint;
  const riid: TGUID; out ppvObject: IAccessible): HResult; stdcall;
  external 'oleacc.dll' name 'CreateStdAccessibleObject';

function PPGAccStripHotkey(const Caption: string): string;
var
  I: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(Caption) do
  begin
    if Caption[I] = '&' then
    begin
      Inc(I);
      if I > Length(Caption) then
        Break;
    end;
    Result := Result + Caption[I];
    Inc(I);
  end;
end;

function PPGAccShortcutFromCaption(const Caption: string): string;
var
  I: Integer;
begin
  Result := '';
  I := 1;
  while I < Length(Caption) do
  begin
    if Caption[I] = '&' then
    begin
      if Caption[I + 1] <> '&' then
        Exit('Alt+' + AnsiUpperCase(Caption[I + 1]));
      Inc(I); // "&&" = literales &
    end;
    Inc(I);
  end;
end;

procedure PPGAccNotify(Wnd: HWND; Event: DWORD);
begin
  if Wnd <> 0 then
    PPG_NotifyWinEvent(Event, Wnd, PPGObjIdClient, CHILDID_SELF);
end;

procedure PPGAccNotifyChild(Wnd: HWND; Event: DWORD; ChildId: Integer);
begin
  if Wnd <> 0 then
    PPG_NotifyWinEvent(Event, Wnd, PPGObjIdClient, ChildId);
end;

type
  /// IAccPropServices (oleacc). Nur die benoetigten Methoden mit Parametern;
  /// die uebrigen sind Platzhalter fuer die richtige vtable-Reihenfolge und
  /// werden nie aufgerufen.
  IPPGAccPropServices = interface(IUnknown)
    ['{6E26E776-04F0-495D-80E4-3330352E3169}']
    function SetPropValue: HResult; stdcall;
    function SetPropServer: HResult; stdcall;
    function ClearProps: HResult; stdcall;
    function SetHwndProp: HResult; stdcall;
    // MSAAPROPID wird als WERT uebergeben (Win32: 16 Byte auf dem Stack)
    function SetHwndPropStr(Wnd: HWND; idObject, idChild: DWORD; idProp: TGUID;
      Str: PWideChar): HResult; stdcall;
    function SetHwndPropServer: HResult; stdcall;
    function ClearHwndProps(Wnd: HWND; idObject, idChild: DWORD; paProps: PGUID;
      cProps: Integer): HResult; stdcall;
  end;

const
  CLSID_PPGAccPropServices: TGUID = '{B5F8350B-0548-48B1-A6EE-88BD00B4A5E7}';
  PROPID_PPG_ACC_NAME: TGUID = '{608D3DF8-8128-4AA7-A428-F55E49267291}';

procedure PPGAccSetWindowName(Wnd: HWND; const Name: string);
var
  Svc: IPPGAccPropServices;
  Prop: TGUID;
  W: WideString;
begin
  if Wnd = 0 then
    Exit;
  if Failed(CoCreateInstance(CLSID_PPGAccPropServices, nil, CLSCTX_INPROC_SERVER,
    IPPGAccPropServices, Svc)) or (Svc = nil) then
    Exit; // z.B. COM nicht initialisiert: das Feld funktioniert trotzdem
  Prop := PROPID_PPG_ACC_NAME;
  if Name = '' then
    Svc.ClearHwndProps(Wnd, DWORD(PPGObjIdClient), CHILDID_SELF, @Prop, 1)
  else
  begin
    W := Name;
    Svc.SetHwndPropStr(Wnd, DWORD(PPGObjIdClient), CHILDID_SELF, Prop, PWideChar(W));
  end;
end;

{ TPPGAccessible }

constructor TPPGAccessible.Create(const AHost: IPPGAccessibleHost; AWnd: HWND);
begin
  inherited Create;
  FHost := AHost;
  FWnd := AWnd;
  if not Supports(AHost, IPPGAccessibleChildren, FKids) then
    FKids := nil;
  if (FKids = nil) or not Supports(AHost, IPPGAccessibleMultiSelection, FMulti) then
    FMulti := nil;
  if Failed(PPG_CreateStdAccessibleObject(AWnd, PPGObjIdClient, IID_IAccessible, FStd)) then
    FStd := nil;
end;

destructor TPPGAccessible.Destroy;
begin
  FStdEnum := nil;
  FStd := nil;
  FMulti := nil;
  FKids := nil;
  FHost := nil;
  inherited Destroy;
end;

procedure TPPGAccessible.Disconnect;
begin
  FMulti := nil;
  FKids := nil;
  FHost := nil;
  FStdEnum := nil;
  FStd := nil;
end;

function TPPGAccessible.Connected(out Res: HResult): Boolean;
begin
  Result := FHost <> nil;
  if Result then
    Res := S_OK
  else
    Res := CO_E_OBJNOTCONNECTED;
end;

function TPPGAccessible.IsSelf(const varChild: OleVariant): Boolean;
begin
  Result := VarIsOrdinal(varChild) and (Integer(varChild) = CHILDID_SELF);
end;

function TPPGAccessible.KidCount: Integer;
begin
  if FKids = nil then
    Result := 0
  else
    Result := FKids.AccChildCount;
end;

function TPPGAccessible.IsVirtual(const varChild: OleVariant; out Id: Integer): Boolean;
begin
  Id := 0;
  Result := (FKids <> nil) and VarIsOrdinal(varChild);
  if Result then
  begin
    Id := Integer(varChild);
    Result := (Id > 0) and (Id <= KidCount);
  end;
end;

/// Schreibt eine Kind-Id als VT_I4 in einen (uninitialisierten) VARIANT.
procedure PutChildId(P: Pointer; Id: Integer);
begin
  FillChar(P^, SizeOf(TVarData), 0);
  TVarData(P^).VType := varInteger;
  TVarData(P^).VInteger := Id;
end;


type
  /// Aufzaehlung fester Kind-Ids (accSelection bei Mehrfachauswahl).
  TPPGIdEnum = class(TInterfacedObject, IPPGEnumVariant)
  private
    FIds: TArray<Integer>;
    FPos: Integer;
  public
    constructor Create(const AIds: TArray<Integer>; APos: Integer = 0);
    function Next(celt: Cardinal; rgvar: Pointer; pceltFetched: PCardinal): HResult; stdcall;
    function Skip(celt: Cardinal): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out Enum: IPPGEnumVariant): HResult; stdcall;
  end;

constructor TPPGIdEnum.Create(const AIds: TArray<Integer>; APos: Integer);
begin
  inherited Create;
  FIds := Copy(AIds);
  FPos := APos;
end;

function TPPGIdEnum.Next(celt: Cardinal; rgvar: Pointer; pceltFetched: PCardinal): HResult;
var
  Got: Cardinal;
begin
  Got := 0;
  while (Got < celt) and (FPos < Length(FIds)) do
  begin
    PutChildId(PByte(rgvar) + Got * SizeOf(TVarData), FIds[FPos]);
    Inc(FPos);
    Inc(Got);
  end;
  if pceltFetched <> nil then
    pceltFetched^ := Got;
  if Got = celt then
    Result := S_OK
  else
    Result := S_FALSE;
end;

function TPPGIdEnum.Skip(celt: Cardinal): HResult;
begin
  Inc(FPos, celt);
  if FPos > Length(FIds) then
  begin
    FPos := Length(FIds);
    Result := S_FALSE;
  end
  else
    Result := S_OK;
end;

function TPPGIdEnum.Reset: HResult;
begin
  FPos := 0;
  Result := S_OK;
end;

function TPPGIdEnum.Clone(out Enum: IPPGEnumVariant): HResult;
begin
  Enum := TPPGIdEnum.Create(FIds, FPos);
  Result := S_OK;
end;

function TPPGAccessible.Fail(const Method: string; E: TObject): HResult;
begin
  // COM-Grenze: niemals weiterwerfen, nur protokollieren
  if E is Exception then
    TPPGErrorHandler.LogWarning(Self, 'IAccessible.' + Method + ': ' + Exception(E).Message);
  Result := E_FAIL;
end;

{ IDispatch }

function TPPGAccessible.GetTypeInfoCount(out Count: Integer): HResult;
begin
  Count := 0;
  Result := S_OK;
end;

function TPPGAccessible.GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult;
begin
  Pointer(TypeInfo) := nil;
  Result := E_NOTIMPL;
end;

function TPPGAccessible.GetIDsOfNames(const IID: TGUID; Names: Pointer;
  NameCount, LocaleID: Integer; DispIDs: Pointer): HResult;
begin
  Result := E_NOTIMPL;
end;

function TPPGAccessible.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
  Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult;
begin
  Result := E_NOTIMPL;
end;

{ IAccessible - vom Standard-Proxy }

function TPPGAccessible.Get_accParent(out ppdispParent: IDispatch): HResult;
begin
  ppdispParent := nil;
  if not Connected(Result) then
    Exit;
  try
    if FStd <> nil then
      Result := FStd.Get_accParent(ppdispParent)
    else
      Result := S_FALSE;
  except
    Result := Fail('accParent', ExceptObject);
  end;
end;

function TPPGAccessible.Get_accChildCount(out pcountChildren: Integer): HResult;
begin
  // Kind-Elemente sind ausschliesslich Kind-FENSTER (z.B. Controls auf einem
  // TPPGPanel) - die kennt der Standard-Proxy. Ohne Kindfenster liefert er 0.
  pcountChildren := 0;
  if not Connected(Result) then
    Exit;
  try
    if FStd <> nil then
      Result := FStd.Get_accChildCount(pcountChildren);
    // Dazu die virtuellen Kinder (Listeneintraege, Reiter)
    Inc(pcountChildren, KidCount);
  except
    Result := Fail('accChildCount', ExceptObject);
  end;
end;

function TPPGAccessible.Get_accChild(varChild: OleVariant; out ppdispChild: IDispatch): HResult;
var
  Id: Integer;
begin
  ppdispChild := nil;
  if not Connected(Result) then
    Exit;
  try
    if IsVirtual(varChild, Id) then
      Result := S_FALSE // einfaches Element: Fragen gehen an dieses Objekt
    else if FStd <> nil then
      Result := FStd.Get_accChild(varChild, ppdispChild)
    else
      Result := E_INVALIDARG;
  except
    Result := Fail('accChild', ExceptObject);
  end;
end;

function TPPGAccessible.Get_accHelp(varChild: OleVariant; out pszHelp: WideString): HResult;
begin
  pszHelp := '';
  if Connected(Result) then
    Result := S_FALSE;
end;

function TPPGAccessible.Get_accHelpTopic(out pszHelpFile: WideString; varChild: OleVariant;
  out pidTopic: Integer): HResult;
begin
  pszHelpFile := '';
  pidTopic := 0;
  if Connected(Result) then
    Result := S_FALSE;
end;

function TPPGAccessible.Get_accFocus(out pvarChild: OleVariant): HResult;
var
  Id: Integer;
begin
  pvarChild := Unassigned;
  if not Connected(Result) then
    Exit;
  try
    if FKids <> nil then
      Id := FKids.AccFocusedChild
    else
      Id := 0;
    if (Id > 0) and (Id <= KidCount) then
    begin
      pvarChild := Id;
      Result := S_OK;
    end
    else if FStd <> nil then
      Result := FStd.Get_accFocus(pvarChild)
    else
      Result := S_FALSE;
  except
    Result := Fail('accFocus', ExceptObject);
  end;
end;

function TPPGAccessible.Get_accSelection(out pvarChildren: OleVariant): HResult;
var
  Id: Integer;
  Ids: TArray<Integer>;
begin
  pvarChildren := Unassigned;
  if not Connected(Result) then
    Exit;
  try
    if FMulti <> nil then
    begin
      // Mehrfachauswahl: keins = S_FALSE, eins = VT_I4, mehrere = Enumerator
      Ids := FMulti.AccSelectedChildren;
      case Length(Ids) of
        0: Result := S_FALSE;
        1:
          begin
            pvarChildren := Ids[0];
            Result := S_OK;
          end;
      else
        pvarChildren := IUnknown(TPPGIdEnum.Create(Ids) as IPPGEnumVariant);
        Result := S_OK;
      end;
      Exit;
    end;
    if FKids <> nil then
      Id := FKids.AccSelectedChild
    else
      Id := 0;
    if (Id > 0) and (Id <= KidCount) then
    begin
      pvarChildren := Id;
      Result := S_OK;
    end
    else
      Result := S_FALSE;
  except
    Result := Fail('accSelection', ExceptObject);
  end;
end;

function TPPGAccessible.accSelect(flagsSelect: Integer; varChild: OleVariant): HResult;
var
  Id: Integer;
begin
  if not Connected(Result) then
    Exit;
  try
    if IsVirtual(varChild, Id) then
    begin
      if (FMulti <> nil) and FMulti.AccChildSelect(Id, flagsSelect) then
        Result := S_OK
      else
        Result := DISP_E_MEMBERNOTFOUND;
    end
    else if FStd <> nil then
      Result := FStd.accSelect(flagsSelect, varChild)
    else
      Result := DISP_E_MEMBERNOTFOUND;
  except
    Result := Fail('accSelect', ExceptObject);
  end;
end;

function TPPGAccessible.accLocation(out pxLeft: Integer; out pyTop: Integer;
  out pcxWidth: Integer; out pcyHeight: Integer; varChild: OleVariant): HResult;
var
  Id: Integer;
  R: TRect;
  P: TPoint;
begin
  pxLeft := 0;
  pyTop := 0;
  pcxWidth := 0;
  pcyHeight := 0;
  if not Connected(Result) then
    Exit;
  try
    if IsVirtual(varChild, Id) then
    begin
      R := FKids.AccChildRect(Id);
      if IsRectEmpty(R) then
        Exit(S_FALSE);
      P := R.TopLeft;
      Winapi.Windows.ClientToScreen(FWnd, P);
      pxLeft := P.X;
      pyTop := P.Y;
      pcxWidth := R.Right - R.Left;
      pcyHeight := R.Bottom - R.Top;
      Result := S_OK;
    end
    else if FStd <> nil then
      Result := FStd.accLocation(pxLeft, pyTop, pcxWidth, pcyHeight, varChild)
    else
      Result := S_FALSE;
  except
    Result := Fail('accLocation', ExceptObject);
  end;
end;

function TPPGAccessible.accNavigate(navDir: Integer; varStart: OleVariant;
  out pvarEndUpAt: OleVariant): HResult;
var
  Id, N: Integer;
begin
  pvarEndUpAt := Unassigned;
  if not Connected(Result) then
    Exit;
  try
    N := KidCount;
    if IsVirtual(varStart, Id) then
    begin
      // Geschwister unter den virtuellen Kindern (Reihenfolge = Id)
      case navDir of
        NAVDIR_NEXT, NAVDIR_DOWN, NAVDIR_RIGHT: Inc(Id);
        NAVDIR_PREVIOUS, NAVDIR_UP, NAVDIR_LEFT: Dec(Id);
      else
        Id := 0;
      end;
      if (Id >= 1) and (Id <= N) then
      begin
        pvarEndUpAt := Id;
        Result := S_OK;
      end
      else
        Result := S_FALSE;
    end
    else if (N > 0) and IsSelf(varStart) and
      ((navDir = NAVDIR_FIRSTCHILD) or (navDir = NAVDIR_LASTCHILD)) then
    begin
      if navDir = NAVDIR_FIRSTCHILD then
        pvarEndUpAt := 1
      else
        pvarEndUpAt := N;
      Result := S_OK;
    end
    else if FStd <> nil then
      Result := FStd.accNavigate(navDir, varStart, pvarEndUpAt)
    else
      Result := S_FALSE;
  except
    Result := Fail('accNavigate', ExceptObject);
  end;
end;

function TPPGAccessible.accHitTest(xLeft: Integer; yTop: Integer;
  out pvarChild: OleVariant): HResult;
var
  Id: Integer;
  P: TPoint;
begin
  pvarChild := Unassigned;
  if not Connected(Result) then
    Exit;
  try
    Id := 0;
    if FKids <> nil then
    begin
      P := Point(xLeft, yTop);
      Winapi.Windows.ScreenToClient(FWnd, P);
      Id := FKids.AccChildAt(P.X, P.Y);
    end;
    if (Id > 0) and (Id <= KidCount) then
    begin
      pvarChild := Id;
      Result := S_OK;
    end
    else if FStd <> nil then
      Result := FStd.accHitTest(xLeft, yTop, pvarChild)
    else
      Result := S_FALSE;
  except
    Result := Fail('accHitTest', ExceptObject);
  end;
end;

{ IAccessible - vom Control }

function TPPGAccessible.Get_accName(varChild: OleVariant; out pszName: WideString): HResult;
var
  Id: Integer;
begin
  pszName := '';
  if not Connected(Result) then
    Exit;
  try
    if IsVirtual(varChild, Id) then
      pszName := FKids.AccChildName(Id)
    else if IsSelf(varChild) then
      pszName := FHost.AccName
    else
      Exit(E_INVALIDARG);
    Result := S_OK;
  except
    Result := Fail('accName', ExceptObject);
  end;
end;

function TPPGAccessible.Get_accValue(varChild: OleVariant; out pszValue: WideString): HResult;
var
  Id: Integer;
begin
  pszValue := '';
  if not Connected(Result) then
    Exit;
  if IsVirtual(varChild, Id) then
    Exit(S_FALSE); // Eintraege/Reiter haben keinen Wert
  if not IsSelf(varChild) then
    Exit(E_INVALIDARG);
  try
    pszValue := FHost.AccValue;
    if pszValue = '' then
      Result := S_FALSE
    else
      Result := S_OK;
  except
    Result := Fail('accValue', ExceptObject);
  end;
end;

function TPPGAccessible.Get_accDescription(varChild: OleVariant;
  out pszDescription: WideString): HResult;
var
  Id: Integer;
begin
  pszDescription := '';
  if not Connected(Result) then
    Exit;
  if IsVirtual(varChild, Id) then
    Exit(S_FALSE);
  if not IsSelf(varChild) then
    Exit(E_INVALIDARG);
  try
    pszDescription := FHost.AccDescription;
    if pszDescription = '' then
      Result := S_FALSE
    else
      Result := S_OK;
  except
    Result := Fail('accDescription', ExceptObject);
  end;
end;

function TPPGAccessible.Get_accRole(varChild: OleVariant; out pvarRole: OleVariant): HResult;
var
  Id: Integer;
begin
  pvarRole := Unassigned;
  if not Connected(Result) then
    Exit;
  try
    if IsVirtual(varChild, Id) then
      pvarRole := FKids.AccChildRole(Id)
    else if IsSelf(varChild) then
      pvarRole := FHost.AccRole
    else
      Exit(E_INVALIDARG);
    Result := S_OK;
  except
    Result := Fail('accRole', ExceptObject);
  end;
end;

function TPPGAccessible.Get_accState(varChild: OleVariant; out pvarState: OleVariant): HResult;
var
  Id: Integer;
begin
  pvarState := Unassigned;
  if not Connected(Result) then
    Exit;
  try
    if IsVirtual(varChild, Id) then
      pvarState := FKids.AccChildState(Id)
    else if IsSelf(varChild) then
      pvarState := FHost.AccState
    else
      Exit(E_INVALIDARG);
    Result := S_OK;
  except
    Result := Fail('accState', ExceptObject);
  end;
end;

function TPPGAccessible.Get_accKeyboardShortcut(varChild: OleVariant;
  out pszKeyboardShortcut: WideString): HResult;
var
  Id: Integer;
begin
  pszKeyboardShortcut := '';
  if not Connected(Result) then
    Exit;
  if IsVirtual(varChild, Id) then
    Exit(S_FALSE);
  if not IsSelf(varChild) then
    Exit(E_INVALIDARG);
  try
    pszKeyboardShortcut := FHost.AccKeyboardShortcut;
    if pszKeyboardShortcut = '' then
      Result := S_FALSE
    else
      Result := S_OK;
  except
    Result := Fail('accKeyboardShortcut', ExceptObject);
  end;
end;

function TPPGAccessible.Get_accDefaultAction(varChild: OleVariant;
  out pszDefaultAction: WideString): HResult;
var
  Id: Integer;
begin
  pszDefaultAction := '';
  if not Connected(Result) then
    Exit;
  try
    if IsVirtual(varChild, Id) then
      pszDefaultAction := FKids.AccChildDefaultAction(Id)
    else if IsSelf(varChild) then
      pszDefaultAction := FHost.AccDefaultAction
    else
      Exit(E_INVALIDARG);
    if pszDefaultAction = '' then
      Result := S_FALSE
    else
      Result := S_OK;
  except
    Result := Fail('accDefaultAction', ExceptObject);
  end;
end;

function TPPGAccessible.accDoDefaultAction(varChild: OleVariant): HResult;
var
  Id: Integer;
begin
  if not Connected(Result) then
    Exit;
  try
    // Beide posten nur eine Nachricht (keine Reentranz im Screenreader)
    if IsVirtual(varChild, Id) then
      FKids.AccChildDoDefault(Id)
    else if IsSelf(varChild) then
      FHost.AccDoDefaultAction
    else
      Exit(E_INVALIDARG);
    Result := S_OK;
  except
    Result := Fail('accDoDefaultAction', ExceptObject);
  end;
end;

function TPPGAccessible.Set_accName(varChild: OleVariant; const pszName: WideString): HResult;
begin
  Result := DISP_E_MEMBERNOTFOUND;
end;

function TPPGAccessible.Set_accValue(varChild: OleVariant; const pszValue: WideString): HResult;
begin
  Result := DISP_E_MEMBERNOTFOUND;
end;

{ IEnumVARIANT - AccessibleChildren fragt zuerst danach. Ohne Enumerator
  liefert es nur Kind-IDs, und Kind-Fenster (Controls auf einem TPPGPanel)
  waeren fuer MSAA-Clients keine erreichbaren Objekte. Der Standard-Proxy
  zaehlt die Kind-Fenster korrekt auf, deshalb wird an ihn weitergereicht. }

function TPPGAccessible.StdEnum: IPPGEnumVariant;
begin
  if (FStdEnum = nil) and (FStd <> nil) then
    if not Supports(FStd, IPPGEnumVariant, FStdEnum) then
      FStdEnum := nil;
  Result := FStdEnum;
end;

function TPPGAccessible.Next(celt: Cardinal; rgvar: Pointer; pceltFetched: PCardinal): HResult;
var
  E: IPPGEnumVariant;
  Got, N: Cardinal;
begin
  if pceltFetched <> nil then
    pceltFetched^ := 0;
  if not Connected(Result) then
    Exit;
  try
    E := StdEnum;
    if FKids = nil then
    begin
      if E <> nil then
        Result := E.Next(celt, rgvar, pceltFetched)
      else if celt = 0 then
        Result := S_OK
      else
        Result := S_FALSE; // keine Kinder
      Exit;
    end;
    // Erst die Kind-Fenster (Standard-Proxy), dann die virtuellen Kinder
    Got := 0;
    if (E <> nil) and not FStdEnumDone and (celt > 0) then
    begin
      N := 0;
      if E.Next(celt, rgvar, @N) <> S_OK then
        FStdEnumDone := True;
      Got := N;
    end;
    while (Got < celt) and (FEnumPos < KidCount) do
    begin
      Inc(FEnumPos);
      PutChildId(PByte(rgvar) + Got * SizeOf(TVarData), FEnumPos);
      Inc(Got);
    end;
    if pceltFetched <> nil then
      pceltFetched^ := Got;
    if Got = celt then
      Result := S_OK
    else
      Result := S_FALSE;
  except
    Result := Fail('EnumVARIANT.Next', ExceptObject);
  end;
end;

function TPPGAccessible.Skip(celt: Cardinal): HResult;
var
  E: IPPGEnumVariant;
  Buf: array of OleVariant;
  Got: Cardinal;
begin
  if not Connected(Result) then
    Exit;
  try
    if FKids <> nil then
    begin
      // Gemischte Aufzaehlung: Ueberspringen = Lesen und Verwerfen
      if celt = 0 then
        Exit(S_OK);
      SetLength(Buf, celt);
      Got := 0;
      Result := Next(celt, @Buf[0], @Got);
      Exit;
    end;
    E := StdEnum;
    if E <> nil then
      Result := E.Skip(celt)
    else if celt = 0 then
      Result := S_OK
    else
      Result := S_FALSE;
  except
    Result := Fail('EnumVARIANT.Skip', ExceptObject);
  end;
end;

function TPPGAccessible.Reset: HResult;
var
  E: IPPGEnumVariant;
begin
  if not Connected(Result) then
    Exit;
  try
    FStdEnumDone := False;
    FEnumPos := 0;
    E := StdEnum;
    if E <> nil then
      Result := E.Reset;
  except
    Result := Fail('EnumVARIANT.Reset', ExceptObject);
  end;
end;

function TPPGAccessible.Clone(out Enum: IPPGEnumVariant): HResult;
var
  E: IPPGEnumVariant;
begin
  Enum := nil;
  if not Connected(Result) then
    Exit;
  try
    E := StdEnum;
    if (E <> nil) and (FKids = nil) then
      Result := E.Clone(Enum)
    else
      Result := E_NOTIMPL;
  except
    Result := Fail('EnumVARIANT.Clone', ExceptObject);
  end;
end;

end.
