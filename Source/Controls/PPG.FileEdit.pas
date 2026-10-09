unit PPG.FileEdit;

{ TPPGFileEdit - Feld fuer eine Datei oder einen Ordner (Phase 12c).

  - Kind: Datei oeffnen, Datei speichern oder Ordner. Der Knopf im Feld
    oeffnet ab Vista TFileOpenDialog/TFileSaveDialog (Ordner ueber
    fdoPickFolders), davor TOpenDialog/TSaveDialog bzw. SHBrowseForFolder
    (Laufzeitpruefung, XE2 auf XP).
  - Ablegen aus dem Explorer (DragAcceptFiles/WM_DROPFILES): die erste Datei
    bzw. der erste Ordner passend zu Kind.
  - Autovervollstaendigung von Pfaden ueber SHAutoComplete auf dem inneren
    Edit (dynamisch geladen; ohne Shell-Funktion einfach ohne).
  - MustExist: fehlende Datei bzw. fehlender Ordner beim Verlassen als
    ValidationState (kein Dialog). Leeres Feld ist gueltig.
  - Ereignisse: OnBeforeDialog (abbrechbar, Dialog vorbereiten),
    OnAfterDialog (Name pruefen/aendern), OnChange wie beim Edit. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.Variants, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.Dialogs,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Field;

type
  TPPGFileEditKind = (fkOpenFile, fkSaveFile, fkFolder);

  TPPGFileBeforeDialogEvent = procedure(Sender: TObject; var Allow: Boolean) of object;
  TPPGFileAfterDialogEvent = procedure(Sender: TObject; var FileName: string;
    var Accept: Boolean) of object;

  TPPGCustomFileEdit = class(TPPGCustomField, IPPGFieldValue)
  private
    FKind: TPPGFileEditKind;
    FFilter: string;
    FFilterIndex: Integer;
    FInitialDir: string;
    FDefaultExt: string;
    FDialogTitle: string;
    FMustExist: Boolean;
    FAcceptDrop: Boolean;
    FAutoComplete: Boolean;
    FAutoCompleteWnd: HWND;
    FOwnError: Boolean;
    FOnBeforeDialog: TPPGFileBeforeDialogEvent;
    FOnAfterDialog: TPPGFileAfterDialogEvent;
    procedure SetFilterIndex(const Value: Integer);
    procedure SetKind(const Value: TPPGFileEditKind);
    procedure SetAcceptDrop(const Value: Boolean);
    procedure SetMustExist(const Value: Boolean);
    function GetFileName: string;
    procedure SetFileName(const Value: string);
    procedure WMDropFiles(var Message: TWMDropFiles); message WM_DROPFILES;
    procedure ApplyAutoComplete;
    function StartDir: string;
    function RunVistaDialog(var AFileName: string): Boolean;
    function RunClassicDialog(var AFileName: string): Boolean;
    procedure SetError(const Hint: string);
    procedure ClearError;
  protected
    procedure CreateWnd; override;
    procedure GetButtons(var Buttons: TPPGFieldButtons); override;
    procedure ButtonClick(Id: Integer); override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure FocusChanged; override;
    procedure Change; override;
    /// Dateiauswahl zeigen (Tests ueberschreiben das). True = gewaehlt.
    function ExecuteDialog(var AFileName: string): Boolean; virtual;
    /// Pfad passend zu Kind? (Ablegen)
    function AcceptsPath(const Path: string): Boolean;
    { IPPGFieldValue }
    function FieldIsNull: Boolean;
    procedure FieldClear;
    function GetFieldValue: Variant;
    procedure SetFieldValue(const Value: Variant);

    property Kind: TPPGFileEditKind read FKind write SetKind default fkOpenFile;
    property Filter: string read FFilter write FFilter;
    property FilterIndex: Integer read FFilterIndex write SetFilterIndex default 1;
    property InitialDir: string read FInitialDir write FInitialDir;
    property DefaultExt: string read FDefaultExt write FDefaultExt;
    property DialogTitle: string read FDialogTitle write FDialogTitle;
    property MustExist: Boolean read FMustExist write SetMustExist default False;
    property AcceptDrop: Boolean read FAcceptDrop write SetAcceptDrop default True;
    property AutoComplete: Boolean read FAutoComplete write FAutoComplete default True;
    property OnBeforeDialog: TPPGFileBeforeDialogEvent read FOnBeforeDialog write FOnBeforeDialog;
    property OnAfterDialog: TPPGFileAfterDialogEvent read FOnAfterDialog write FOnAfterDialog;
  public
    constructor Create(AOwner: TComponent); override;
    /// Knopf "Durchsuchen" (mit Ereignissen, wie ein Klick).
    function Browse: Boolean;
    /// Prueft MustExist jetzt. False = Datei/Ordner fehlt.
    function ValidatePath: Boolean;
    /// Anwender legt Pfade ab (wie WM_DROPFILES). True = einer passte.
    function DropPaths(const Paths: array of string): Boolean;
    property FileName: string read GetFileName write SetFileName;
  end;

  TPPGFileEdit = class(TPPGCustomFileEdit)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Kind;
    property Filter;
    property FilterIndex;
    property InitialDir;
    property DefaultExt;
    property DialogTitle;
    property MustExist;
    property AcceptDrop;
    property AutoComplete;
    property ShowClearButton;
    property TextHint;
    property TextHintVisibleOnFocus;
    property UseSystemContextMenu;
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
    property Text;
    property Visible;
    property Touch;
    property OnGesture;
    property OnAfterDialog;
    property OnBeforeDialog;
    property OnChange;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
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
  end;

const
  PPGFileButtonBrowse = 30;

implementation

uses
  Winapi.ShellAPI, Winapi.ShlObj, Winapi.ActiveX, Vcl.Forms, PPG.Lang, PPG.Consts;

const
  SHACF_FILESYSTEM = $00000001;
  SHACF_FILESYS_DIRS = $00000020;

type
  TSHAutoComplete = function(hwndEdit: HWND; dwFlags: DWORD): HResult; stdcall;

var
  GAutoComplete: TSHAutoComplete = nil;
  GAutoCompleteLoaded: Boolean = False;

function AutoCompleteProc: TSHAutoComplete;
var
  Lib: HMODULE;
begin
  if not GAutoCompleteLoaded then
  begin
    GAutoCompleteLoaded := True;
    Lib := GetModuleHandle('shlwapi.dll');
    if Lib = 0 then
      Lib := LoadLibrary('shlwapi.dll');
    if Lib <> 0 then
      @GAutoComplete := GetProcAddress(Lib, 'SHAutoComplete');
  end;
  Result := GAutoComplete;
end;

/// Ordnerwahl vor Vista (SHBrowseForFolder), ohne Vcl.FileCtrl (Paket vclx).
function BrowseFolderXP(const Title: string; var Folder: string): Boolean;
var
  BI: TBrowseInfo;
  List: PItemIDList;
  Buf: array[0..MAX_PATH] of Char;
begin
  Result := False;
  FillChar(BI, SizeOf(BI), 0);
  if Screen.ActiveCustomForm <> nil then
    BI.hwndOwner := Screen.ActiveCustomForm.Handle;
  BI.lpszTitle := PChar(Title);
  BI.ulFlags := BIF_RETURNONLYFSDIRS or BIF_NEWDIALOGSTYLE;
  List := SHBrowseForFolder(BI);
  if List = nil then
    Exit;
  try
    if SHGetPathFromIDList(List, Buf) then
    begin
      Folder := Buf;
      Result := True;
    end;
  finally
    CoTaskMemFree(List);
  end;
end;

{ TPPGCustomFileEdit }

procedure TPPGCustomFileEdit.SetFilterIndex(const Value: Integer);
begin
  // 1-basiert wie TOpenDialog; 0 = eigener Filter
  FFilterIndex := PPGCheckRange(Self, 'FilterIndex', Value, 0, MaxInt);
end;

constructor TPPGCustomFileEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFilterIndex := 1;
  FAcceptDrop := True;
  FAutoComplete := True;
end;

procedure TPPGCustomFileEdit.CreateWnd;
begin
  inherited CreateWnd;
  // Ablegen: das Feld nimmt Dateien an; Windows sucht vom inneren Edit aus
  // das naechste Elternfenster mit WS_EX_ACCEPTFILES
  if not (csDesigning in ComponentState) then
    DragAcceptFiles(Handle, FAcceptDrop);
end;

procedure TPPGCustomFileEdit.SetAcceptDrop(const Value: Boolean);
begin
  FAcceptDrop := Value;
  if HandleAllocated and not (csDesigning in ComponentState) then
    DragAcceptFiles(Handle, FAcceptDrop);
end;

procedure TPPGCustomFileEdit.SetKind(const Value: TPPGFileEditKind);
begin
  if FKind = Value then
    Exit;
  FKind := Value;
  FAutoCompleteWnd := 0; // neu anmelden (Ordner/Dateien)
  Invalidate;
end;

procedure TPPGCustomFileEdit.SetMustExist(const Value: Boolean);
begin
  FMustExist := Value;
  if not FMustExist then
    ClearError;
end;

function TPPGCustomFileEdit.GetFileName: string;
begin
  Result := Text;
end;

procedure TPPGCustomFileEdit.SetFileName(const Value: string);
begin
  // Aus Code: ohne OnChange
  SetTextSilent(Value);
  ClearError;
end;

procedure TPPGCustomFileEdit.ApplyAutoComplete;
var
  P: TSHAutoComplete;
  Flags: DWORD;
begin
  if not FAutoComplete or (csDesigning in ComponentState) or not Inner.HandleAllocated or
    (FAutoCompleteWnd = Inner.Handle) then
    Exit;
  P := AutoCompleteProc();
  if not Assigned(P) then
    Exit;
  if FKind = fkFolder then
    Flags := SHACF_FILESYS_DIRS
  else
    Flags := SHACF_FILESYSTEM;
  // Ohne COM (z.B. Konsolenprogramm) schlaegt es fehl: dann ohne
  if Succeeded(P(Inner.Handle, Flags)) then
    FAutoCompleteWnd := Inner.Handle;
end;

procedure TPPGCustomFileEdit.GetButtons(var Buttons: TPPGFieldButtons);
var
  N: Integer;
begin
  inherited GetButtons(Buttons);
  N := Length(Buttons);
  SetLength(Buttons, N + 1);
  Buttons[N].Id := PPGFileButtonBrowse;
  Buttons[N].Glyph := fgBrowse;
  Buttons[N].ImageIndex := -1;
  Buttons[N].LeftSide := False;
end;

procedure TPPGCustomFileEdit.ButtonClick(Id: Integer);
begin
  if Id = PPGFileButtonBrowse then
    Browse
  else
    inherited ButtonClick(Id);
end;

procedure TPPGCustomFileEdit.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  // Alt+Pfeil runter oder F4 oeffnet die Auswahl (wie bei Auswahlfeldern)
  if ((Key = VK_DOWN) and (ssAlt in Shift)) or ((Key = VK_F4) and (Shift = [])) then
  begin
    Key := 0;
    Browse;
  end;
end;

function TPPGCustomFileEdit.StartDir: string;
var
  S: string;
begin
  S := Trim(Text);
  Result := FInitialDir;
  if S = '' then
    Exit;
  if FKind = fkFolder then
  begin
    if DirectoryExists(S) then
      Result := S;
  end
  else if DirectoryExists(ExtractFileDir(S)) then
    Result := ExtractFileDir(S);
end;

function TPPGCustomFileEdit.RunVistaDialog(var AFileName: string): Boolean;
var
  D: TCustomFileDialog;
  I: Integer;
  Parts: TArray<string>;
  FT: TFileTypeItem;
begin
  if FKind = fkSaveFile then
    D := TFileSaveDialog.Create(nil)
  else
    D := TFileOpenDialog.Create(nil);
  try
    D.Title := FDialogTitle;
    D.DefaultFolder := StartDir;
    D.DefaultExtension := FDefaultExt;
    if (Trim(AFileName) <> '') and (FKind <> fkFolder) then
      D.FileName := ExtractFileName(AFileName);
    if FKind = fkFolder then
      D.Options := D.Options + [fdoPickFolders, fdoPathMustExist]
    else if FKind = fkOpenFile then
      D.Options := D.Options + [fdoFileMustExist, fdoPathMustExist]
    else
      D.Options := D.Options + [fdoOverWritePrompt, fdoPathMustExist];
    // VCL-Filter "Text|*.txt|Alle|*.*" in Dateitypen umsetzen
    if (FKind <> fkFolder) and (FFilter <> '') then
    begin
      Parts := PPGSplitString(FFilter, '|', False);
      I := 0;
      while I + 1 <= High(Parts) do
      begin
        FT := D.FileTypes.Add;
        FT.DisplayName := Parts[I];
        FT.FileMask := Parts[I + 1];
        Inc(I, 2);
      end;
      D.FileTypeIndex := FFilterIndex;
    end;
    Result := D.Execute;
    if Result then
    begin
      AFileName := D.FileName;
      if FKind <> fkFolder then
        FFilterIndex := D.FileTypeIndex;
    end;
  finally
    D.Free;
  end;
end;

function TPPGCustomFileEdit.RunClassicDialog(var AFileName: string): Boolean;
var
  D: TOpenDialog;
begin
  if FKind = fkFolder then
  begin
    Result := BrowseFolderXP(FDialogTitle, AFileName);
    Exit;
  end;
  if FKind = fkSaveFile then
    D := TSaveDialog.Create(nil)
  else
    D := TOpenDialog.Create(nil);
  try
    D.Title := FDialogTitle;
    D.InitialDir := StartDir;
    D.DefaultExt := FDefaultExt;
    D.Filter := FFilter;
    D.FilterIndex := FFilterIndex;
    D.FileName := ExtractFileName(AFileName);
    if FKind = fkOpenFile then
      D.Options := D.Options + [ofFileMustExist, ofPathMustExist]
    else
      D.Options := D.Options + [ofOverwritePrompt, ofPathMustExist];
    Result := D.Execute;
    if Result then
    begin
      AFileName := D.FileName;
      FFilterIndex := D.FilterIndex;
    end;
  finally
    D.Free;
  end;
end;

function TPPGCustomFileEdit.ExecuteDialog(var AFileName: string): Boolean;
begin
  // Ab Vista der neue Dialog, sonst (XP) der alte
  if Win32MajorVersion >= 6 then
    Result := RunVistaDialog(AFileName)
  else
    Result := RunClassicDialog(AFileName);
end;

function TPPGCustomFileEdit.Browse: Boolean;
var
  Allow, Accept: Boolean;
  S: string;
begin
  Result := False;
  if ReadOnly or not Enabled then
    Exit;
  Allow := True;
  if Assigned(FOnBeforeDialog) then
    FOnBeforeDialog(Self, Allow);
  if not Allow then
    Exit;
  S := Text;
  if not ExecuteDialog(S) then
    Exit;
  Accept := True;
  if Assigned(FOnAfterDialog) then
    FOnAfterDialog(Self, S, Accept);
  if not Accept then
    Exit;
  // Anwenderaktion: OnChange ueber das innere Edit
  Text := S;
  ClearError;
  Result := True;
  if CanFocus then
    SetFocus;
  SelStart := Length(S);
end;

function TPPGCustomFileEdit.AcceptsPath(const Path: string): Boolean;
begin
  if FKind = fkFolder then
    Result := DirectoryExists(Path)
  else
    Result := not DirectoryExists(Path);
end;

function TPPGCustomFileEdit.DropPaths(const Paths: array of string): Boolean;
var
  I: Integer;
begin
  Result := False;
  if ReadOnly or not Enabled then
    Exit;
  for I := 0 to High(Paths) do
    if AcceptsPath(Paths[I]) then
    begin
      Text := Paths[I];
      ValidatePath;
      Exit(True);
    end;
  MessageBeep(MB_ICONWARNING);
end;

procedure TPPGCustomFileEdit.WMDropFiles(var Message: TWMDropFiles);
var
  N, I, Len: Integer;
  Paths: TArray<string>;
  Buf: string;
begin
  try
    N := DragQueryFile(Message.Drop, $FFFFFFFF, nil, 0);
    SetLength(Paths, N);
    for I := 0 to N - 1 do
    begin
      Len := DragQueryFile(Message.Drop, I, nil, 0);
      SetLength(Buf, Len);
      DragQueryFile(Message.Drop, I, PChar(Buf), Len + 1);
      Paths[I] := Buf;
    end;
    DropPaths(Paths);
  finally
    DragFinish(Message.Drop);
  end;
  Message.Result := 0;
end;

procedure TPPGCustomFileEdit.FocusChanged;
begin
  if FieldFocused then
    ApplyAutoComplete
  else if not (csDestroying in ComponentState) then
    ValidatePath;
  inherited FocusChanged;
end;

procedure TPPGCustomFileEdit.Change;
begin
  inherited Change;
  if FOwnError and not ChangeLocked then
    ClearError;
end;

procedure TPPGCustomFileEdit.SetError(const Hint: string);
begin
  FOwnError := True;
  ValidationHint := Hint;
  ValidationState := pvsError;
end;

procedure TPPGCustomFileEdit.ClearError;
begin
  if not FOwnError then
    Exit;
  FOwnError := False;
  ValidationState := pvsNone;
  ValidationHint := '';
end;

function TPPGCustomFileEdit.ValidatePath: Boolean;
var
  S: string;
begin
  Result := True;
  S := Trim(Text);
  if not FMustExist or (S = '') then
  begin
    ClearError;
    Exit;
  end;
  case FKind of
    fkOpenFile: Result := FileExists(S);
    fkFolder: Result := DirectoryExists(S);
  else
    Result := (ExtractFileDir(S) = '') or DirectoryExists(ExtractFileDir(S));
  end;
  if Result then
    ClearError
  else if FKind = fkOpenFile then
    SetError(PPGStr(@SPPGFileNotFound))
  else
    SetError(PPGStr(@SPPGFolderNotFound));
end;

function TPPGCustomFileEdit.FieldIsNull: Boolean;
begin
  Result := Trim(Text) = '';
end;

procedure TPPGCustomFileEdit.FieldClear;
begin
  SetFileName('');
end;

function TPPGCustomFileEdit.GetFieldValue: Variant;
begin
  if FieldIsNull then
    Result := Null
  else
    Result := Text;
end;

procedure TPPGCustomFileEdit.SetFieldValue(const Value: Variant);
begin
  if VarIsNull(Value) or VarIsEmpty(Value) then
    FieldClear
  else
    SetFileName(VarToStr(Value));
end;

end.
