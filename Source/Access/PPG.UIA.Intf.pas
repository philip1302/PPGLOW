unit PPG.UIA.Intf;

{ UI Automation (UIA): eigene Deklarationen der benoetigten Provider-
  Interfaces und Konstanten (Phase 9b).

  Warum eigene Deklarationen: Die UIA-Units der RTL gibt es erst in neueren
  Delphi-Versionen und ihre Signaturen weichen ab (wie bei MSAA, siehe
  PPG.Accessibility). Mit festen eigenen Typen verhaelt sich PPGlow von XE2
  bis 13 gleich. Die GUIDs und die Reihenfolge der Methoden (vtable) stammen
  aus UIAutomationCore.h des Windows SDK und duerfen nicht veraendert werden.

  Die Funktionen von UIAutomationCore.dll werden DYNAMISCH geladen: Fehlt die
  DLL oder eine Funktion (aeltere Windows-Version), bleibt es bei MSAA. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.ActiveX;

const
  /// lParam von WM_GETOBJECT, mit dem UIA nach dem nativen Provider fragt.
  PPGUiaRootObjectId = -25;
  PPGUiaAppendRuntimeId = 3;

  // ProviderOptions
  ProviderOptions_ClientSideProvider = 1;
  ProviderOptions_ServerSideProvider = 2;
  ProviderOptions_NonClientAreaProvider = 4;
  ProviderOptions_OverrideProvider = 8;
  ProviderOptions_ProviderOwnsSetFocus = 16;
  ProviderOptions_UseComThreading = 32;

  // NavigateDirection
  NavigateDirection_Parent = 0;
  NavigateDirection_NextSibling = 1;
  NavigateDirection_PreviousSibling = 2;
  NavigateDirection_FirstChild = 3;
  NavigateDirection_LastChild = 4;

  // Muster (PATTERNID)
  UIA_InvokePatternId = 10000;
  UIA_SelectionPatternId = 10001;
  UIA_ValuePatternId = 10002;
  UIA_ExpandCollapsePatternId = 10005;
  UIA_GridPatternId = 10006;
  UIA_GridItemPatternId = 10007;
  UIA_SelectionItemPatternId = 10010;
  UIA_TablePatternId = 10012;
  UIA_TableItemPatternId = 10013;
  UIA_TogglePatternId = 10015;
  UIA_ScrollItemPatternId = 10017;

  // Eigenschaften (PROPERTYID)
  UIA_RuntimeIdPropertyId = 30000;
  UIA_BoundingRectanglePropertyId = 30001;
  UIA_ProcessIdPropertyId = 30002;
  UIA_ControlTypePropertyId = 30003;
  UIA_LocalizedControlTypePropertyId = 30004;
  UIA_NamePropertyId = 30005;
  UIA_AcceleratorKeyPropertyId = 30006;
  UIA_AccessKeyPropertyId = 30007;
  UIA_HasKeyboardFocusPropertyId = 30008;
  UIA_IsKeyboardFocusablePropertyId = 30009;
  UIA_IsEnabledPropertyId = 30010;
  UIA_AutomationIdPropertyId = 30011;
  UIA_ClassNamePropertyId = 30012;
  UIA_HelpTextPropertyId = 30013;
  UIA_IsControlElementPropertyId = 30016;
  UIA_IsContentElementPropertyId = 30017;
  UIA_NativeWindowHandlePropertyId = 30020;
  UIA_IsOffscreenPropertyId = 30022;
  UIA_FrameworkIdPropertyId = 30024;
  UIA_ItemStatusPropertyId = 30026;
  UIA_ValueValuePropertyId = 30045;
  UIA_ExpandCollapseExpandCollapseStatePropertyId = 30070;
  UIA_SelectionItemIsSelectedPropertyId = 30079;
  UIA_ToggleToggleStatePropertyId = 30086;
  UIA_PositionInSetPropertyId = 30152;
  UIA_SizeOfSetPropertyId = 30153;
  UIA_LevelPropertyId = 30154;

  // Control-Typen (CONTROLTYPEID)
  UIA_CheckBoxControlTypeId = 50002;
  UIA_EditControlTypeId = 50004;
  UIA_ListItemControlTypeId = 50007;
  UIA_ListControlTypeId = 50008;
  UIA_TextControlTypeId = 50020;
  UIA_TreeControlTypeId = 50023;
  UIA_TreeItemControlTypeId = 50024;
  UIA_CustomControlTypeId = 50025;
  UIA_GroupControlTypeId = 50026;
  UIA_DataGridControlTypeId = 50028;
  UIA_DataItemControlTypeId = 50029;
  UIA_HeaderControlTypeId = 50034;
  UIA_HeaderItemControlTypeId = 50035;

  // Ereignisse (EVENTID)
  UIA_StructureChangedEventId = 20002;
  UIA_AutomationPropertyChangedEventId = 20004;
  UIA_AutomationFocusChangedEventId = 20005;
  UIA_LayoutInvalidatedEventId = 20008;
  UIA_Invoke_InvokedEventId = 20009;
  UIA_SelectionItem_ElementAddedToSelectionEventId = 20010;
  UIA_SelectionItem_ElementRemovedFromSelectionEventId = 20011;
  UIA_SelectionItem_ElementSelectedEventId = 20012;
  UIA_Selection_InvalidatedEventId = 20013;

  // ExpandCollapseState
  ExpandCollapseState_Collapsed = 0;
  ExpandCollapseState_Expanded = 1;
  ExpandCollapseState_PartiallyExpanded = 2;
  ExpandCollapseState_LeafNode = 3;

  // ToggleState
  ToggleState_Off = 0;
  ToggleState_On = 1;
  ToggleState_Indeterminate = 2;

  // RowOrColumnMajor
  RowOrColumnMajor_RowMajor = 0;

  // Fehlercodes
  UIA_E_ELEMENTNOTENABLED = HResult($80040200);
  UIA_E_ELEMENTNOTAVAILABLE = HResult($80040201);
  UIA_E_INVALIDOPERATION = HResult($80131509);

type
  /// UiaRect: Bildschirmkoordinaten als Double.
  TPPGUiaRect = record
    Left: Double;
    Top: Double;
    Width: Double;
    Height: Double;
  end;

  IRawElementProviderFragmentRoot = interface;

  IRawElementProviderSimple = interface(IUnknown)
    ['{D6DD68D1-86FD-4332-8666-9ABEDEA2D24C}']
    function get_ProviderOptions(out pRetVal: Integer): HResult; stdcall;
    function GetPatternProvider(patternId: Integer; out pRetVal: IUnknown): HResult; stdcall;
    function GetPropertyValue(propertyId: Integer; out pRetVal: OleVariant): HResult; stdcall;
    function get_HostRawElementProvider(out pRetVal: IRawElementProviderSimple): HResult; stdcall;
  end;

  IRawElementProviderFragment = interface(IUnknown)
    ['{F7063DA8-8359-439C-9297-BBC5299A7D87}']
    function Navigate(direction: Integer; out pRetVal: IRawElementProviderFragment): HResult; stdcall;
    function GetRuntimeId(out pRetVal: PSafeArray): HResult; stdcall;
    function get_BoundingRectangle(out pRetVal: TPPGUiaRect): HResult; stdcall;
    function GetEmbeddedFragmentRoots(out pRetVal: PSafeArray): HResult; stdcall;
    function SetFocus: HResult; stdcall;
    function get_FragmentRoot(out pRetVal: IRawElementProviderFragmentRoot): HResult; stdcall;
  end;

  IRawElementProviderFragmentRoot = interface(IUnknown)
    ['{620CE2A5-AB8F-40A9-86CB-DE3C75599B58}']
    function ElementProviderFromPoint(x, y: Double; out pRetVal: IRawElementProviderFragment): HResult; stdcall;
    function GetFocus(out pRetVal: IRawElementProviderFragment): HResult; stdcall;
  end;

  IInvokeProvider = interface(IUnknown)
    ['{54FCB24B-E18E-47A2-B4D3-ECCBE77599A2}']
    function Invoke: HResult; stdcall;
  end;

  ISelectionProvider = interface(IUnknown)
    ['{FB8B03AF-3BDF-48D4-BD36-1A65793BE168}']
    function GetSelection(out pRetVal: PSafeArray): HResult; stdcall;
    function get_CanSelectMultiple(out pRetVal: BOOL): HResult; stdcall;
    function get_IsSelectionRequired(out pRetVal: BOOL): HResult; stdcall;
  end;

  ISelectionItemProvider = interface(IUnknown)
    ['{2ACAD808-B2D4-452D-A407-91FF1AD167B2}']
    function Select: HResult; stdcall;
    function AddToSelection: HResult; stdcall;
    function RemoveFromSelection: HResult; stdcall;
    function get_IsSelected(out pRetVal: BOOL): HResult; stdcall;
    function get_SelectionContainer(out pRetVal: IRawElementProviderSimple): HResult; stdcall;
  end;

  IValueProvider = interface(IUnknown)
    ['{C7935180-6FB3-4201-B174-7DF73ADBF64A}']
    function SetValue(val: PWideChar): HResult; stdcall;
    function get_Value(out pRetVal: WideString): HResult; stdcall;
    function get_IsReadOnly(out pRetVal: BOOL): HResult; stdcall;
  end;

  IExpandCollapseProvider = interface(IUnknown)
    ['{D847D3A5-CAB0-4A98-8C32-ECB45C59AD24}']
    function Expand: HResult; stdcall;
    function Collapse: HResult; stdcall;
    function get_ExpandCollapseState(out pRetVal: Integer): HResult; stdcall;
  end;

  IGridProvider = interface(IUnknown)
    ['{B17D6187-0907-464B-A168-0EF17A1572B1}']
    function GetItem(row, column: Integer; out pRetVal: IRawElementProviderSimple): HResult; stdcall;
    function get_RowCount(out pRetVal: Integer): HResult; stdcall;
    function get_ColumnCount(out pRetVal: Integer): HResult; stdcall;
  end;

  IGridItemProvider = interface(IUnknown)
    ['{D02541F1-FB81-4D64-AE32-F520F8A6DBD1}']
    function get_Row(out pRetVal: Integer): HResult; stdcall;
    function get_Column(out pRetVal: Integer): HResult; stdcall;
    function get_RowSpan(out pRetVal: Integer): HResult; stdcall;
    function get_ColumnSpan(out pRetVal: Integer): HResult; stdcall;
    function get_ContainingGrid(out pRetVal: IRawElementProviderSimple): HResult; stdcall;
  end;

  ITableProvider = interface(IUnknown)
    ['{9C860395-97B3-490A-B52A-858CC22AF166}']
    function GetRowHeaders(out pRetVal: PSafeArray): HResult; stdcall;
    function GetColumnHeaders(out pRetVal: PSafeArray): HResult; stdcall;
    function get_RowOrColumnMajor(out pRetVal: Integer): HResult; stdcall;
  end;

  ITableItemProvider = interface(IUnknown)
    ['{B9734FA6-771F-4D78-9C90-2517999349CD}']
    function GetRowHeaderItems(out pRetVal: PSafeArray): HResult; stdcall;
    function GetColumnHeaderItems(out pRetVal: PSafeArray): HResult; stdcall;
  end;

  IToggleProvider = interface(IUnknown)
    ['{56D00BD0-C4F4-433C-A836-1A52A57E0892}']
    function Toggle: HResult; stdcall;
    function get_ToggleState(out pRetVal: Integer): HResult; stdcall;
  end;

  IScrollItemProvider = interface(IUnknown)
    ['{2360C714-4BF1-4B26-BA65-9B21316127EB}']
    function ScrollIntoView: HResult; stdcall;
  end;

/// True, wenn UIAutomationCore.dll mit den benoetigten Funktionen da ist.
function PPGUiaAvailable: Boolean;
/// Antwort auf WM_GETOBJECT(UiaRootObjectId); 0 ohne UIA.
function PPGUiaReturnRawElementProvider(Wnd: HWND; wParam: WPARAM; lParam: LPARAM;
  const El: IRawElementProviderSimple): LRESULT;
/// Standard-Provider des Fensters (fuer HostRawElementProvider).
function PPGUiaHostProviderFromHwnd(Wnd: HWND; out Provider: IRawElementProviderSimple): HResult;
/// True, wenn ein UIA-Client zuhoert (sonst keine Ereignisse erzeugen).
function PPGUiaClientsAreListening: Boolean;
function PPGUiaRaiseAutomationEvent(const Provider: IRawElementProviderSimple; EventId: Integer): HResult;
function PPGUiaRaisePropertyChanged(const Provider: IRawElementProviderSimple;
  PropertyId: Integer; const OldValue, NewValue: OleVariant): HResult;
/// Trennt alle Clients vom Provider (ab Windows 8; sonst ohne Wirkung).
function PPGUiaDisconnectProvider(const Provider: IRawElementProviderSimple): HResult;

implementation

uses
  System.SysUtils;

type
  TUiaReturnRawElementProvider = function(hwnd: HWND; wParam: WPARAM; lParam: LPARAM;
    el: Pointer): LRESULT; stdcall;
  TUiaHostProviderFromHwnd = function(hwnd: HWND; out ppProvider: IRawElementProviderSimple): HResult; stdcall;
  TUiaClientsAreListening = function: BOOL; stdcall;
  TUiaRaiseAutomationEvent = function(pProvider: Pointer; id: Integer): HResult; stdcall;
  // VARIANT wird als WERT uebergeben (wie in der C-Deklaration)
  TUiaRaiseAutomationPropertyChangedEvent = function(pProvider: Pointer; id: Integer;
    oldValue, newValue: TVarData): HResult; stdcall;
  TUiaDisconnectProvider = function(pProvider: Pointer): HResult; stdcall;

var
  GLib: HMODULE = 0;
  GLoaded: Boolean = False;
  GReturnRaw: TUiaReturnRawElementProvider = nil;
  GHostFromHwnd: TUiaHostProviderFromHwnd = nil;
  GListening: TUiaClientsAreListening = nil;
  GRaiseEvent: TUiaRaiseAutomationEvent = nil;
  GRaiseProp: TUiaRaiseAutomationPropertyChangedEvent = nil;
  GDisconnect: TUiaDisconnectProvider = nil;

procedure LoadUia;
begin
  if GLoaded then
    Exit;
  GLoaded := True;
  GLib := LoadLibrary('UIAutomationCore.dll');
  if GLib = 0 then
    Exit;
  @GReturnRaw := GetProcAddress(GLib, 'UiaReturnRawElementProvider');
  @GHostFromHwnd := GetProcAddress(GLib, 'UiaHostProviderFromHwnd');
  @GListening := GetProcAddress(GLib, 'UiaClientsAreListening');
  @GRaiseEvent := GetProcAddress(GLib, 'UiaRaiseAutomationEvent');
  @GRaiseProp := GetProcAddress(GLib, 'UiaRaiseAutomationPropertyChangedEvent');
  @GDisconnect := GetProcAddress(GLib, 'UiaDisconnectProvider');
end;

function PPGUiaAvailable: Boolean;
begin
  LoadUia;
  Result := Assigned(GReturnRaw) and Assigned(GHostFromHwnd);
end;

function PPGUiaReturnRawElementProvider(Wnd: HWND; wParam: WPARAM; lParam: LPARAM;
  const El: IRawElementProviderSimple): LRESULT;
begin
  Result := 0;
  if PPGUiaAvailable then
    Result := GReturnRaw(Wnd, wParam, lParam, Pointer(El));
end;

function PPGUiaHostProviderFromHwnd(Wnd: HWND; out Provider: IRawElementProviderSimple): HResult;
begin
  Provider := nil;
  if PPGUiaAvailable then
    Result := GHostFromHwnd(Wnd, Provider)
  else
    Result := E_NOTIMPL;
end;

function PPGUiaClientsAreListening: Boolean;
begin
  LoadUia;
  Result := Assigned(GListening) and GListening();
end;

function PPGUiaRaiseAutomationEvent(const Provider: IRawElementProviderSimple; EventId: Integer): HResult;
begin
  LoadUia;
  if Assigned(GRaiseEvent) and (Provider <> nil) then
    Result := GRaiseEvent(Pointer(Provider), EventId)
  else
    Result := E_NOTIMPL;
end;

function PPGUiaRaisePropertyChanged(const Provider: IRawElementProviderSimple;
  PropertyId: Integer; const OldValue, NewValue: OleVariant): HResult;
begin
  LoadUia;
  if Assigned(GRaiseProp) and (Provider <> nil) then
    Result := GRaiseProp(Pointer(Provider), PropertyId, TVarData(OldValue), TVarData(NewValue))
  else
    Result := E_NOTIMPL;
end;

function PPGUiaDisconnectProvider(const Provider: IRawElementProviderSimple): HResult;
begin
  LoadUia;
  if Assigned(GDisconnect) and (Provider <> nil) then
    Result := GDisconnect(Pointer(Provider))
  else
    Result := E_NOTIMPL;
end;

initialization

finalization
  // Die DLL bleibt bis zum Prozessende geladen: Clients koennen Provider
  // noch halten, waehrend die Unit finalisiert wird.

end.
