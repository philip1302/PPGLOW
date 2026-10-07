unit PPG.DB.Controls;

{ Datenbank-Controls (Phase 9c): TPPGDBEdit, TPPGDBMemo, TPPGDBCheckBox,
  TPPGDBComboBox, TPPGDBDatePicker.

  Eigenes Package (PPGlowDBR): Anwendungen ohne Datenbank linken kein Data.DB.
  Die Controls erben von den PPGlow-Controls und fuegen nur die Anbindung
  hinzu (TFieldDataLink) - keine zweite Zeichenlogik.

  Ablauf wie bei den VCL-DB-Controls:
  - Datensatz wechselt (DataChange): Wert aus dem Feld anzeigen (mit Fokus
    Field.Text, ohne Field.DisplayText).
  - Anwender aendert: zuerst den Datensatz in den Bearbeiten-Modus setzen
    (TPPGFieldDataLink.EditByUser), dann Modified. Waehrend EditByUser darf
    DataChange den neuen Wert nicht ueberschreiben (Sperre).
  - Verlassen (CM_EXIT): UpdateRecord schreibt ins Feld. Ein ungueltiger Wert
    setzt ValidationState = pvsError mit der Meldung als ValidationHint,
    behaelt den Fokus und bricht still ab (kein Dialog).
  - Esc waehrend der Bearbeitung: Wert aus dem Feld zuruecksetzen.

  Fallstrick (Roadmap): TDataLink-Ereignisse kommen auch, waehrend gezeichnet
  wird (berechnete Felder). Die Handler setzen deshalb nur Werte; Zeichnen
  passiert immer erst im naechsten Paint. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, Vcl.Controls,
  Vcl.StdCtrls, Data.DB, Vcl.DBCtrls,
  PPG.Types, PPG.Controls.Field, PPG.Edit, PPG.Memo, PPG.CheckBox, PPG.ComboBox,
  PPG.DatePicker;

type
  /// TFieldDataLink mit Sperre gegen das Ueberschreiben waehrend der
  /// Anwender-Aenderung (siehe Kopfkommentar).
  TPPGFieldDataLink = class(TFieldDataLink)
  private
    FLock: Integer;
  public
    /// Datensatz in den Bearbeiten-Modus setzen, ohne dass DataChange den
    /// eben eingegebenen Wert ueberschreibt. False = nicht moeglich.
    function EditByUser: Boolean;
    /// True, solange EditByUser laeuft (DataChange ignorieren).
    function Locked: Boolean;
  end;

  TPPGDBEdit = class(TPPGEdit)
  private
    FDataLink: TPPGFieldDataLink;
    FSetting: Boolean;
    procedure DataChange(Sender: TObject);
    procedure EditingChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    procedure ActiveChange(Sender: TObject);
    procedure UpdateEditable;
    function GetDataField: string;
    procedure SetDataField(const Value: string);
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetReadOnly(const Value: Boolean);
    procedure CMGetDataLink(var Message: TMessage); message CM_GETDATALINK;
    procedure CMEnter(var Message: TCMEnter); message CM_ENTER;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Change; override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure FieldKeyPress(var Key: Char); override;
    function WantSpecialKey(Key: Word): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ExecuteAction(Action: TBasicAction): Boolean; override;
    function UpdateAction(Action: TBasicAction): Boolean; override;
    property Field: TField read GetField;
  published
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property Text stored False;
  end;

  TPPGDBMemo = class(TPPGMemo)
  private
    FDataLink: TPPGFieldDataLink;
    FSetting: Boolean;
    FAutoDisplay: Boolean;
    FMemoLoaded: Boolean;
    procedure DataChange(Sender: TObject);
    procedure EditingChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    procedure ActiveChange(Sender: TObject);
    procedure UpdateEditable;
    procedure SetAutoDisplay(const Value: Boolean);
    function GetDataField: string;
    procedure SetDataField(const Value: string);
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetReadOnly(const Value: Boolean);
    procedure CMGetDataLink(var Message: TMessage); message CM_GETDATALINK;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Change; override;
    procedure DblClick; override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    function WantSpecialKey(Key: Word): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Laedt ein BLOB-Memo, wenn AutoDisplay = False ist.
    procedure LoadMemo;
    function ExecuteAction(Action: TBasicAction): Boolean; override;
    function UpdateAction(Action: TBasicAction): Boolean; override;
    property Field: TField read GetField;
  published
    /// False: BLOB-Memos erst bei Doppelklick bzw. Enter laden (wie TDBMemo).
    property AutoDisplay: Boolean read FAutoDisplay write SetAutoDisplay default True;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property Lines stored False;
  end;

  TPPGDBCheckBox = class(TPPGCheckBox)
  private
    FDataLink: TPPGFieldDataLink;
    FValueChecked: string;
    FValueUnchecked: string;
    FSetting: Boolean;
    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    function FieldState: TCheckBoxState;
    function GetDataField: string;
    procedure SetDataField(const Value: string);
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetReadOnly(const Value: Boolean);
    function IsValueCheckedStored: Boolean;
    function IsValueUncheckedStored: Boolean;
    procedure SetValueChecked(const Value: string);
    procedure SetValueUnchecked(const Value: string);
    procedure CMGetDataLink(var Message: TMessage); message CM_GETDATALINK;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Toggle; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ExecuteAction(Action: TBasicAction): Boolean; override;
    function UpdateAction(Action: TBasicAction): Boolean; override;
    property Field: TField read GetField;
  published
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    /// Wert(e) fuer "an" bzw. "aus" bei Nicht-Boolean-Feldern; mehrere durch
    /// Semikolon getrennt (der erste wird geschrieben), wie TDBCheckBox.
    property ValueChecked: string read FValueChecked write SetValueChecked stored IsValueCheckedStored;
    property ValueUnchecked: string read FValueUnchecked write SetValueUnchecked stored IsValueUncheckedStored;
    property State stored False;
  end;

  TPPGDBComboBox = class(TPPGComboBox)
  private
    FDataLink: TPPGFieldDataLink;
    FSetting: Boolean;
    procedure EditingChange(Sender: TObject);
    procedure UpdateEditable;
    function GetDataField: string;
    procedure SetDataField(const Value: string);
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetReadOnly(const Value: Boolean);
    procedure CMGetDataLink(var Message: TMessage); message CM_GETDATALINK;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Change; override;
    procedure DoSelect; override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    function WantSpecialKey(Key: Word): Boolean; override;
    /// Wert in den Bearbeiten-Modus bringen; False = nicht aenderbar.
    function BeginUserChange: Boolean;
    /// Datensatz gewechselt: Wert anzeigen (Lookup: Schluessel suchen).
    procedure DataChange(Sender: TObject); virtual;
    /// Wert ins Feld schreiben (Lookup: Schluessel).
    procedure UpdateData(Sender: TObject); virtual;
    /// True, solange DataChange den Wert setzt (keine Anwender-Aenderung).
    property Setting: Boolean read FSetting write FSetting;
    property DataLink: TPPGFieldDataLink read FDataLink;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ExecuteAction(Action: TBasicAction): Boolean; override;
    function UpdateAction(Action: TBasicAction): Boolean; override;
    property Field: TField read GetField;
  published
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property Text stored False;
    property ItemIndex stored False;
  end;

  TPPGDBDatePicker = class(TPPGDatePicker)
  private
    FDataLink: TPPGFieldDataLink;
    FSetting: Boolean;
    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    function GetDataField: string;
    procedure SetDataField(const Value: string);
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetReadOnly(const Value: Boolean);
    procedure CMGetDataLink(var Message: TMessage); message CM_GETDATALINK;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure UserChange; override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure FieldKeyPress(var Key: Char); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ExecuteAction(Action: TBasicAction): Boolean; override;
    function UpdateAction(Action: TBasicAction): Boolean; override;
    property Field: TField read GetField;
  published
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property Date stored False;
    property Time stored False;
    property Checked stored False;
  end;

/// DataSource eines Links setzen (mit FreeNotification wie die VCL-Controls).
procedure PPGDBSetDataSource(Owner: TComponent; Link: TDataLink; Value: TDataSource);
/// Schreibt den Wert ins Feld (UpdateRecord). Bei einem Fehler: Feld als
/// ungueltig markieren, Fokus behalten und still abbrechen (EAbort).
procedure PPGDBCommitField(Ctrl: TPPGCustomField; Link: TFieldDataLink);

implementation

type
  /// Zugriff auf die geschuetzten Validierungs-Properties der Feld-Basis.
  TFieldAccess = class(TPPGCustomField);

const
  DefValueChecked = 'True';
  DefValueUnchecked = 'False';

{ Hilfen }

procedure PPGDBSetDataSource(Owner: TComponent; Link: TDataLink; Value: TDataSource);
begin
  if not (Link.DataSourceFixed and (csLoading in Owner.ComponentState)) then
    Link.DataSource := Value;
  if Value <> nil then
    Value.FreeNotification(Owner);
end;

procedure PPGDBCommitField(Ctrl: TPPGCustomField; Link: TFieldDataLink);
var
  F: TFieldAccess;
begin
  F := TFieldAccess(Ctrl);
  try
    Link.UpdateRecord;
  except
    on E: Exception do
    begin
      F.ValidationHint := E.Message;
      F.ValidationState := pvsError;
      F.SelectAll;
      // Unsichtbares Fenster (Formular schliesst/ist verborgen): kein Fokus,
      // sonst ersetzt EInvalidOperation den stillen Abbruch
      if F.CanFocus and F.HandleAllocated and IsWindowVisible(F.Handle) then
        F.SetFocus;
      // Still abbrechen: der Fokuswechsel unterbleibt, der Zustand zeigt den
      // Fehler (EAbort ist kein Fehler, sondern der VCL-Weg fuer "abbrechen")
      Abort;
    end;
  end;
  if F.ValidationState = pvsError then
  begin
    F.ValidationState := pvsNone;
    F.ValidationHint := '';
  end;
end;

/// Meldet einen Fehler beim Schreiben eines Nicht-Feld-Controls (CheckBox):
/// Fokus behalten und weiterwerfen (wie TDBCheckBox).
procedure CommitOther(Ctrl: TWinControl; Link: TFieldDataLink);
begin
  try
    Link.UpdateRecord;
  except
    if Ctrl.CanFocus and Ctrl.HandleAllocated and IsWindowVisible(Ctrl.Handle) then
      Ctrl.SetFocus;
    raise;
  end;
end;

{ TPPGFieldDataLink }

function TPPGFieldDataLink.EditByUser: Boolean;
begin
  Inc(FLock);
  try
    Result := Edit;
  finally
    Dec(FLock);
  end;
end;

function TPPGFieldDataLink.Locked: Boolean;
begin
  Result := FLock > 0;
end;

{ TPPGDBEdit }

constructor TPPGDBEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDataLink := TPPGFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnEditingChange := EditingChange;
  FDataLink.OnUpdateData := UpdateData;
  FDataLink.OnActiveChange := ActiveChange;
  UpdateEditable;
end;

destructor TPPGDBEdit.Destroy;
begin
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

procedure TPPGDBEdit.Loaded;
begin
  inherited Loaded;
  if csDesigning in ComponentState then
    DataChange(Self);
end;

procedure TPPGDBEdit.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FDataLink <> nil) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TPPGDBEdit.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TPPGDBEdit.SetDataField(const Value: string);
begin
  FDataLink.FieldName := Value;
end;

function TPPGDBEdit.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TPPGDBEdit.SetDataSource(Value: TDataSource);
begin
  PPGDBSetDataSource(Self, FDataLink, Value);
end;

function TPPGDBEdit.GetField: TField;
begin
  Result := FDataLink.Field;
end;

function TPPGDBEdit.GetReadOnly: Boolean;
begin
  Result := FDataLink.ReadOnly;
end;

procedure TPPGDBEdit.SetReadOnly(const Value: Boolean);
begin
  FDataLink.ReadOnly := Value;
  UpdateEditable;
end;

procedure TPPGDBEdit.UpdateEditable;
begin
  // Ohne aenderbares Feld bleibt das Edit schreibgeschuetzt (wie TDBEdit)
  inherited ReadOnly := not FDataLink.CanModify;
end;

procedure TPPGDBEdit.DataChange(Sender: TObject);
var
  F: TField;
begin
  if FDataLink.Locked then
    Exit;
  F := FDataLink.Field;
  FSetting := True;
  try
    if F <> nil then
    begin
      Alignment := F.Alignment;
      if FieldFocused and FDataLink.CanModify then
        Text := F.Text
      else
        Text := F.DisplayText;
    end
    else if csDesigning in ComponentState then
      Text := Name
    else
      Text := '';
    Modified := False;
  finally
    FSetting := False;
  end;
  if ValidationState = pvsError then
  begin
    ValidationState := pvsNone;
    ValidationHint := '';
  end;
  UpdateEditable;
end;

procedure TPPGDBEdit.EditingChange(Sender: TObject);
begin
  UpdateEditable;
end;

procedure TPPGDBEdit.ActiveChange(Sender: TObject);
begin
  DataChange(Sender);
end;

procedure TPPGDBEdit.UpdateData(Sender: TObject);
begin
  FDataLink.Field.Text := Text;
end;

procedure TPPGDBEdit.Change;
begin
  if not FSetting and not (csDesigning in ComponentState) then
  begin
    if not FDataLink.Editing and not FDataLink.EditByUser then
    begin
      // Nicht aenderbar: alten Wert wieder anzeigen
      DataChange(Self);
      Exit;
    end;
    FDataLink.Modified;
  end;
  inherited Change;
end;

procedure TPPGDBEdit.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and FDataLink.Editing then
  begin
    FDataLink.Reset;
    SelectAll;
    Key := 0;
    Exit;
  end;
  inherited FieldKeyDown(Key, Shift);
end;

procedure TPPGDBEdit.FieldKeyPress(var Key: Char);
begin
  if (Key >= #32) and (FDataLink.Field <> nil) and not FDataLink.Field.IsValidChar(Key) then
  begin
    MessageBeep(0);
    Key := #0;
    Exit;
  end;
  inherited FieldKeyPress(Key);
end;

function TPPGDBEdit.WantSpecialKey(Key: Word): Boolean;
begin
  // Esc setzt die Bearbeitung zurueck, statt den Dialog zu schliessen
  Result := ((Key = VK_ESCAPE) and FDataLink.Editing) or inherited WantSpecialKey(Key);
end;

procedure TPPGDBEdit.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FDataLink);
end;

procedure TPPGDBEdit.CMEnter(var Message: TCMEnter);
begin
  inherited;
  // Mit Fokus Field.Text (Bearbeitungsformat) statt DisplayText
  if not Modified then
    DataChange(Self);
end;

procedure TPPGDBEdit.CMExit(var Message: TCMExit);
begin
  PPGDBCommitField(Self, FDataLink);
  inherited;
  if not Modified then
    DataChange(Self);
end;

function TPPGDBEdit.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FDataLink <> nil) and FDataLink.ExecuteAction(Action));
end;

function TPPGDBEdit.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FDataLink <> nil) and FDataLink.UpdateAction(Action));
end;

{ TPPGDBMemo }

constructor TPPGDBMemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoDisplay := True;
  FDataLink := TPPGFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnEditingChange := EditingChange;
  FDataLink.OnUpdateData := UpdateData;
  FDataLink.OnActiveChange := ActiveChange;
  UpdateEditable;
end;

destructor TPPGDBMemo.Destroy;
begin
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

procedure TPPGDBMemo.Loaded;
begin
  inherited Loaded;
  if csDesigning in ComponentState then
    DataChange(Self);
end;

procedure TPPGDBMemo.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FDataLink <> nil) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TPPGDBMemo.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TPPGDBMemo.SetDataField(const Value: string);
begin
  FDataLink.FieldName := Value;
end;

function TPPGDBMemo.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TPPGDBMemo.SetDataSource(Value: TDataSource);
begin
  PPGDBSetDataSource(Self, FDataLink, Value);
end;

function TPPGDBMemo.GetField: TField;
begin
  Result := FDataLink.Field;
end;

function TPPGDBMemo.GetReadOnly: Boolean;
begin
  Result := FDataLink.ReadOnly;
end;

procedure TPPGDBMemo.SetReadOnly(const Value: Boolean);
begin
  FDataLink.ReadOnly := Value;
  UpdateEditable;
end;

procedure TPPGDBMemo.SetAutoDisplay(const Value: Boolean);
begin
  if FAutoDisplay <> Value then
  begin
    FAutoDisplay := Value;
    if Value then
      LoadMemo;
  end;
end;

procedure TPPGDBMemo.UpdateEditable;
begin
  inherited ReadOnly := not FDataLink.CanModify or not FMemoLoaded;
end;

procedure TPPGDBMemo.LoadMemo;
var
  F: TField;
begin
  if FMemoLoaded then
    Exit;
  F := FDataLink.Field;
  if (F = nil) or not F.IsBlob then
    Exit;
  FSetting := True;
  try
    Text := F.AsString;
    Modified := False;
  finally
    FSetting := False;
  end;
  FMemoLoaded := True;
  UpdateEditable;
end;

procedure TPPGDBMemo.DataChange(Sender: TObject);
var
  F: TField;
begin
  if FDataLink.Locked then
    Exit;
  F := FDataLink.Field;
  FMemoLoaded := False;
  FSetting := True;
  try
    if F <> nil then
    begin
      if F.IsBlob then
      begin
        if FAutoDisplay or (FDataLink.Editing and (DataSource.State = dsInsert)) then
        begin
          Text := F.AsString;
          FMemoLoaded := True;
        end
        else
          Text := '(' + F.DisplayLabel + ')';
      end
      else
      begin
        if FieldFocused and FDataLink.CanModify then
          Text := F.Text
        else
          Text := F.DisplayText;
        FMemoLoaded := True;
      end;
    end
    else if csDesigning in ComponentState then
      Text := Name
    else
      Text := '';
    Modified := False;
  finally
    FSetting := False;
  end;
  if ValidationState = pvsError then
  begin
    ValidationState := pvsNone;
    ValidationHint := '';
  end;
  UpdateEditable;
end;

procedure TPPGDBMemo.EditingChange(Sender: TObject);
begin
  UpdateEditable;
end;

procedure TPPGDBMemo.ActiveChange(Sender: TObject);
begin
  DataChange(Sender);
end;

procedure TPPGDBMemo.UpdateData(Sender: TObject);
begin
  if FDataLink.Field.IsBlob then
    FDataLink.Field.AsString := Text
  else
    FDataLink.Field.Text := Text;
end;

procedure TPPGDBMemo.Change;
begin
  if not FSetting and not (csDesigning in ComponentState) then
  begin
    if not FDataLink.Editing and not FDataLink.EditByUser then
    begin
      DataChange(Self);
      Exit;
    end;
    FDataLink.Modified;
  end;
  inherited Change;
end;

procedure TPPGDBMemo.DblClick;
begin
  if not FMemoLoaded then
    LoadMemo
  else
    inherited DblClick;
end;

procedure TPPGDBMemo.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and FDataLink.Editing then
  begin
    FDataLink.Reset;
    SelectAll;
    Key := 0;
    Exit;
  end;
  if (Key = VK_RETURN) and not FMemoLoaded then
  begin
    LoadMemo;
    Key := 0;
    Exit;
  end;
  inherited FieldKeyDown(Key, Shift);
end;

function TPPGDBMemo.WantSpecialKey(Key: Word): Boolean;
begin
  Result := ((Key = VK_ESCAPE) and FDataLink.Editing) or inherited WantSpecialKey(Key);
end;

procedure TPPGDBMemo.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FDataLink);
end;

procedure TPPGDBMemo.CMExit(var Message: TCMExit);
begin
  PPGDBCommitField(Self, FDataLink);
  inherited;
end;

function TPPGDBMemo.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FDataLink <> nil) and FDataLink.ExecuteAction(Action));
end;

function TPPGDBMemo.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FDataLink <> nil) and FDataLink.UpdateAction(Action));
end;

{ TPPGDBCheckBox }

constructor TPPGDBCheckBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FValueChecked := DefValueChecked;
  FValueUnchecked := DefValueUnchecked;
  FDataLink := TPPGFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnUpdateData := UpdateData;
  FDataLink.OnActiveChange := DataChange;
end;

destructor TPPGDBCheckBox.Destroy;
begin
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

procedure TPPGDBCheckBox.Loaded;
begin
  inherited Loaded;
  if csDesigning in ComponentState then
    DataChange(Self);
end;

procedure TPPGDBCheckBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FDataLink <> nil) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TPPGDBCheckBox.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TPPGDBCheckBox.SetDataField(const Value: string);
begin
  FDataLink.FieldName := Value;
end;

function TPPGDBCheckBox.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TPPGDBCheckBox.SetDataSource(Value: TDataSource);
begin
  PPGDBSetDataSource(Self, FDataLink, Value);
end;

function TPPGDBCheckBox.GetField: TField;
begin
  Result := FDataLink.Field;
end;

function TPPGDBCheckBox.GetReadOnly: Boolean;
begin
  Result := FDataLink.ReadOnly;
end;

procedure TPPGDBCheckBox.SetReadOnly(const Value: Boolean);
begin
  FDataLink.ReadOnly := Value;
end;

function TPPGDBCheckBox.IsValueCheckedStored: Boolean;
begin
  Result := not SameText(FValueChecked, DefValueChecked);
end;

function TPPGDBCheckBox.IsValueUncheckedStored: Boolean;
begin
  Result := not SameText(FValueUnchecked, DefValueUnchecked);
end;

procedure TPPGDBCheckBox.SetValueChecked(const Value: string);
begin
  FValueChecked := Value;
  DataChange(Self);
end;

procedure TPPGDBCheckBox.SetValueUnchecked(const Value: string);
begin
  FValueUnchecked := Value;
  DataChange(Self);
end;

/// True, wenn S einem der durch Semikolon getrennten Werte entspricht.
function MatchesValue(const S, Values: string): Boolean;
var
  P, Start: Integer;
begin
  Result := False;
  Start := 1;
  for P := 1 to Length(Values) + 1 do
    if (P > Length(Values)) or (Values[P] = ';') then
    begin
      if SameText(S, Trim(Copy(Values, Start, P - Start))) then
        Exit(True);
      Start := P + 1;
    end;
end;

function FirstValue(const Values: string): string;
var
  P: Integer;
begin
  P := Pos(';', Values);
  if P = 0 then
    Result := Values
  else
    Result := Copy(Values, 1, P - 1);
end;

function TPPGDBCheckBox.FieldState: TCheckBoxState;
var
  F: TField;
  S: string;
begin
  Result := cbGrayed;
  F := FDataLink.Field;
  if (F = nil) or F.IsNull then
    Exit;
  if F.DataType = ftBoolean then
  begin
    if F.AsBoolean then
      Result := cbChecked
    else
      Result := cbUnchecked;
    Exit;
  end;
  S := F.Text;
  if MatchesValue(S, FValueChecked) then
    Result := cbChecked
  else if MatchesValue(S, FValueUnchecked) then
    Result := cbUnchecked;
end;

procedure TPPGDBCheckBox.DataChange(Sender: TObject);
begin
  if (FDataLink = nil) or FDataLink.Locked then
    Exit;
  FSetting := True;
  try
    State := FieldState;
  finally
    FSetting := False;
  end;
end;

procedure TPPGDBCheckBox.UpdateData(Sender: TObject);
var
  F: TField;
begin
  F := FDataLink.Field;
  if State = cbGrayed then
    F.Clear
  else if F.DataType = ftBoolean then
    F.AsBoolean := State = cbChecked
  else if State = cbChecked then
    F.Text := FirstValue(FValueChecked)
  else
    F.Text := FirstValue(FValueUnchecked);
end;

procedure TPPGDBCheckBox.Toggle;
begin
  // Nur mit aenderbarem Feld; erst Bearbeiten-Modus, dann umschalten
  if (csDesigning in ComponentState) or not FDataLink.EditByUser then
    Exit;
  inherited Toggle;
  FDataLink.Modified;
end;

procedure TPPGDBCheckBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and FDataLink.Editing then
  begin
    FDataLink.Reset;
    Key := 0;
    Exit;
  end;
  inherited KeyDown(Key, Shift);
end;

procedure TPPGDBCheckBox.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FDataLink);
end;

procedure TPPGDBCheckBox.CMExit(var Message: TCMExit);
begin
  CommitOther(Self, FDataLink);
  inherited;
end;

function TPPGDBCheckBox.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FDataLink <> nil) and FDataLink.ExecuteAction(Action));
end;

function TPPGDBCheckBox.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FDataLink <> nil) and FDataLink.UpdateAction(Action));
end;

{ TPPGDBComboBox }

constructor TPPGDBComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDataLink := TPPGFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnEditingChange := EditingChange;
  FDataLink.OnUpdateData := UpdateData;
  FDataLink.OnActiveChange := DataChange;
  UpdateEditable;
end;

destructor TPPGDBComboBox.Destroy;
begin
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

procedure TPPGDBComboBox.Loaded;
begin
  inherited Loaded;
  if csDesigning in ComponentState then
    DataChange(Self);
end;

procedure TPPGDBComboBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FDataLink <> nil) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TPPGDBComboBox.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TPPGDBComboBox.SetDataField(const Value: string);
begin
  FDataLink.FieldName := Value;
end;

function TPPGDBComboBox.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TPPGDBComboBox.SetDataSource(Value: TDataSource);
begin
  PPGDBSetDataSource(Self, FDataLink, Value);
end;

function TPPGDBComboBox.GetField: TField;
begin
  Result := FDataLink.Field;
end;

function TPPGDBComboBox.GetReadOnly: Boolean;
begin
  Result := FDataLink.ReadOnly;
end;

procedure TPPGDBComboBox.SetReadOnly(const Value: Boolean);
begin
  FDataLink.ReadOnly := Value;
  UpdateEditable;
end;

procedure TPPGDBComboBox.UpdateEditable;
begin
  inherited ReadOnly := not FDataLink.CanModify;
end;

procedure TPPGDBComboBox.DataChange(Sender: TObject);
var
  F: TField;
begin
  if (FDataLink = nil) or FDataLink.Locked then
    Exit;
  F := FDataLink.Field;
  FSetting := True;
  try
    if F = nil then
    begin
      if csDesigning in ComponentState then
        Text := Name
      else
        Text := '';
    end
    else if Style = csDropDownList then
      ItemIndex := Items.IndexOf(F.Text)
    else
      Text := F.Text;
  finally
    FSetting := False;
  end;
  UpdateEditable;
end;

procedure TPPGDBComboBox.EditingChange(Sender: TObject);
begin
  UpdateEditable;
end;

procedure TPPGDBComboBox.UpdateData(Sender: TObject);
begin
  if Style = csDropDownList then
  begin
    if ItemIndex >= 0 then
      FDataLink.Field.Text := Items[ItemIndex]
    else
      FDataLink.Field.Clear;
  end
  else
    FDataLink.Field.Text := Text;
end;

function TPPGDBComboBox.BeginUserChange: Boolean;
begin
  Result := FDataLink.Editing or FDataLink.EditByUser;
  if not Result then
    DataChange(Self);
end;

procedure TPPGDBComboBox.Change;
begin
  if not FSetting and not IsQuiet and not (csDesigning in ComponentState) then
  begin
    if not BeginUserChange then
      Exit;
    FDataLink.Modified;
  end;
  inherited Change;
end;

procedure TPPGDBComboBox.DoSelect;
begin
  if not FSetting and not (csDesigning in ComponentState) then
  begin
    if not BeginUserChange then
      Exit;
    FDataLink.Modified;
  end;
  inherited DoSelect;
end;

procedure TPPGDBComboBox.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and not DroppedDown and FDataLink.Editing then
  begin
    FDataLink.Reset;
    Key := 0;
    Exit;
  end;
  inherited FieldKeyDown(Key, Shift);
end;

function TPPGDBComboBox.WantSpecialKey(Key: Word): Boolean;
begin
  Result := ((Key = VK_ESCAPE) and FDataLink.Editing) or inherited WantSpecialKey(Key);
end;

procedure TPPGDBComboBox.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FDataLink);
end;

procedure TPPGDBComboBox.CMExit(var Message: TCMExit);
begin
  PPGDBCommitField(Self, FDataLink);
  inherited;
end;

function TPPGDBComboBox.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FDataLink <> nil) and FDataLink.ExecuteAction(Action));
end;

function TPPGDBComboBox.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FDataLink <> nil) and FDataLink.UpdateAction(Action));
end;

{ TPPGDBDatePicker }

constructor TPPGDBDatePicker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDataLink := TPPGFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnUpdateData := UpdateData;
  FDataLink.OnActiveChange := DataChange;
end;

destructor TPPGDBDatePicker.Destroy;
begin
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

procedure TPPGDBDatePicker.Loaded;
begin
  inherited Loaded;
  if csDesigning in ComponentState then
    DataChange(Self);
end;

procedure TPPGDBDatePicker.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FDataLink <> nil) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TPPGDBDatePicker.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TPPGDBDatePicker.SetDataField(const Value: string);
begin
  FDataLink.FieldName := Value;
end;

function TPPGDBDatePicker.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TPPGDBDatePicker.SetDataSource(Value: TDataSource);
begin
  PPGDBSetDataSource(Self, FDataLink, Value);
end;

function TPPGDBDatePicker.GetField: TField;
begin
  Result := FDataLink.Field;
end;

function TPPGDBDatePicker.GetReadOnly: Boolean;
begin
  Result := FDataLink.ReadOnly;
end;

procedure TPPGDBDatePicker.SetReadOnly(const Value: Boolean);
begin
  FDataLink.ReadOnly := Value;
end;

procedure TPPGDBDatePicker.DataChange(Sender: TObject);
var
  F: TField;
begin
  if (FDataLink = nil) or FDataLink.Locked then
    Exit;
  F := FDataLink.Field;
  FSetting := True;
  try
    if (F = nil) or F.IsNull then
    begin
      // Leerer Wert: nur mit Kontrollkaestchen darstellbar (wie TDateTimePicker)
      if ShowCheckbox then
        Checked := False;
    end
    else
    begin
      Date := Int(F.AsDateTime);
      Checked := True;
    end;
  finally
    FSetting := False;
  end;
  if ValidationState = pvsError then
  begin
    ValidationState := pvsNone;
    ValidationHint := '';
  end;
end;

procedure TPPGDBDatePicker.UpdateData(Sender: TObject);
var
  F: TField;
  T: Double;
begin
  F := FDataLink.Field;
  if ShowCheckbox and not Checked then
    F.Clear
  else
  begin
    // Uhrzeit eines DateTime-Felds bleibt erhalten
    if F.IsNull then
      T := 0
    else
      T := Frac(F.AsDateTime);
    F.AsDateTime := Int(Date) + T;
  end;
end;

procedure TPPGDBDatePicker.UserChange;
begin
  if not FSetting and not (csDesigning in ComponentState) then
  begin
    if not FDataLink.Editing and not FDataLink.EditByUser then
    begin
      DataChange(Self);
      Exit;
    end;
    FDataLink.Modified;
  end;
  inherited UserChange;
end;

procedure TPPGDBDatePicker.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  // Nicht aenderbar: keine Eingabe (Pfeile aendern sonst das Datum)
  if not FDataLink.CanModify and ((Key = VK_UP) or (Key = VK_DOWN) or (Key = VK_DELETE)) then
  begin
    Key := 0;
    Exit;
  end;
  inherited FieldKeyDown(Key, Shift);
end;

procedure TPPGDBDatePicker.FieldKeyPress(var Key: Char);
begin
  if (Key >= #32) and not FDataLink.CanModify then
  begin
    MessageBeep(0);
    Key := #0;
    Exit;
  end;
  inherited FieldKeyPress(Key);
end;

procedure TPPGDBDatePicker.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FDataLink);
end;

procedure TPPGDBDatePicker.CMExit(var Message: TCMExit);
begin
  // Getippten Text zuerst uebernehmen (sonst erst beim Fokusverlust), dann
  // ins Feld schreiben
  if FieldFocused and FDataLink.CanModify then
    CommitText(True);
  PPGDBCommitField(Self, FDataLink);
  inherited;
end;

function TPPGDBDatePicker.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FDataLink <> nil) and FDataLink.ExecuteAction(Action));
end;

function TPPGDBDatePicker.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FDataLink <> nil) and FDataLink.UpdateAction(Action));
end;

end.
