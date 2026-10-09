unit PPG.DB.Fields;

{ DB-Varianten der Eingabefelder aus Phase 12 (12g): TPPGDBMaskEdit,
  TPPGDBNumberEdit, TPPGDBColorPicker, TPPGDBCheckComboBox, TPPGDBTagEdit.

  Alle binden sich ueber IPPGFieldValue (PPG.Controls.Field) an das Feld -
  eine Anbindung (TPPGDBValueBinding) statt einer je Feldtyp:
  - Datensatz wechselt: Null -> FieldClear, sonst SetFieldValue (still, ohne
    OnChange). Text-Modus (Maske, Auswahl, Tags) ueber Field.Text, sonst
    Field.Value (Zahl, Farbe).
  - Anwender aendert: Datensatz in den Bearbeiten-Modus (EditByUser), dann
    Modified; geht das nicht, wird der Feldwert wieder angezeigt.
  - Schreiben (UpdateData, auch beim Post ueber einen Navigator): eine
    laufende Eingabe wird vorher uebernommen (Zahl rechnen, Tag anlegen).
  - Verlassen: UpdateRecord; ein Fehler steht am Feld (ValidationState),
    kein Dialog (PPGDBCommitField aus Phase 9).
  - TPPGDBMaskEdit uebernimmt Field.EditMask, wenn es keine eigene Maske hat.
  - TPPGDBNumberEdit: AllowNull ist Vorgabe (Null ist nicht 0).
  - Auswahl und Tags speichern als getrennten Text (Delimiter). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.Variants,
  Vcl.Controls, Data.DB, Vcl.DBCtrls,
  PPG.Types, PPG.Controls.Field, PPG.DB.Controls, PPG.MaskEdit, PPG.NumberEdit,
  PPG.ColorPicker, PPG.CheckComboBox, PPG.TagEdit;

type
  TPPGDBValueMode = (dvmVariant, dvmText);

  /// Verbindet ein Feld-Control mit IPPGFieldValue mit einem Datenbankfeld:
  /// die gemeinsame Bindung (TPPGDBBinding), Anzeigen und Schreiben ueber
  /// IPPGFieldValue.
  TPPGDBValueBinding = class(TPPGDBBinding)
  private
    FMode: TPPGDBValueMode;
    FOnFieldChanged: TNotifyEvent;
    function Value: IPPGFieldValue;
  protected
    procedure ShowValue; override;
    procedure WriteValue; override;
  public
    constructor Create(ACtrl: TPPGCustomField; AMode: TPPGDBValueMode);
    /// Nach dem Laden eines neuen Feldes (z.B. EditMask uebernehmen).
    property OnFieldChanged: TNotifyEvent read FOnFieldChanged write FOnFieldChanged;
  end;

  TPPGDBMaskEdit = class(TPPGMaskEdit)
  private
    FBinding: TPPGDBValueBinding;
    FMaskFromField: Boolean;
    function GetDataField: string;
    procedure SetDataField(const Value: string);
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetReadOnly(const Value: Boolean);
    procedure FieldChanged(Sender: TObject);
    procedure CMGetDataLink(var Message: TMessage); message CM_GETDATALINK;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Change; override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
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

  TPPGDBNumberEdit = class(TPPGNumberEdit)
  private
    FBinding: TPPGDBValueBinding;
    function GetDataField: string;
    procedure SetDataField(const Value: string);
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetReadOnly(const Value: Boolean);
    procedure BeforeUpdate(Sender: TObject);
    procedure CMGetDataLink(var Message: TMessage); message CM_GETDATALINK;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Change; override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ExecuteAction(Action: TBasicAction): Boolean; override;
    function UpdateAction(Action: TBasicAction): Boolean; override;
    property Field: TField read GetField;
  published
    property AllowNull default True;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property Value stored False;
  end;

  TPPGDBColorPicker = class(TPPGColorPicker)
  private
    FBinding: TPPGDBValueBinding;
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
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    function WantSpecialKey(Key: Word): Boolean; override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Change; override;
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
    property Selected stored False;
  end;

  TPPGDBCheckComboBox = class(TPPGCheckComboBox)
  private
    FBinding: TPPGDBValueBinding;
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
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    function WantSpecialKey(Key: Word): Boolean; override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Change; override;
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
    property CheckedText stored False;
  end;

  TPPGDBTagEdit = class(TPPGTagEdit)
  private
    FBinding: TPPGDBValueBinding;
    function GetDataField: string;
    procedure SetDataField(const Value: string);
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetReadOnly(const Value: Boolean);
    procedure BeforeUpdate(Sender: TObject);
    procedure CMGetDataLink(var Message: TMessage); message CM_GETDATALINK;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  protected
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    function WantSpecialKey(Key: Word): Boolean; override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoTagsChange; override;
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
    property Tags stored False;
  end;

implementation

uses
  // Feldregeln fuer TPPGValidator mitlinken (AutoFieldRules)
  PPG.DB.Validator;

{ TPPGDBValueBinding }

constructor TPPGDBValueBinding.Create(ACtrl: TPPGCustomField; AMode: TPPGDBValueMode);
begin
  inherited Create(ACtrl, True);
  FMode := AMode;
end;

function TPPGDBValueBinding.Value: IPPGFieldValue;
begin
  if not Supports(Control, IPPGFieldValue, Result) then
    Result := nil;
end;

procedure TPPGDBValueBinding.ShowValue;
var
  F: TField;
  V: IPPGFieldValue;
begin
  V := Value;
  if V = nil then
    Exit;
  F := Field;
  if Assigned(FOnFieldChanged) then
    FOnFieldChanged(Self);
  if (F = nil) or F.IsNull then
    V.FieldClear
  else if FMode = dvmText then
    V.SetFieldValue(F.Text)
  else
    V.SetFieldValue(F.Value);
end;

procedure TPPGDBValueBinding.WriteValue;
var
  V: IPPGFieldValue;
  X: Variant;
begin
  V := Value;
  if V = nil then
    Exit;
  if V.FieldIsNull then
    Field.Clear
  else
  begin
    X := V.GetFieldValue;
    if FMode = dvmText then
      Field.Text := VarToStr(X)
    else
      Field.Value := X;
  end;
end;

{ TPPGDBMaskEdit }

constructor TPPGDBMaskEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBinding := TPPGDBValueBinding.Create(Self, dvmText);
  FBinding.OnFieldChanged := FieldChanged;
  FBinding.UpdateEditable;
end;

destructor TPPGDBMaskEdit.Destroy;
begin
  FreeAndNil(FBinding);
  inherited Destroy;
end;

procedure TPPGDBMaskEdit.FieldChanged(Sender: TObject);
var
  F: TField;
begin
  // Maske des Felds, solange das Control keine eigene hat (nur zur Laufzeit,
  // sonst landete sie in der DFM)
  if csDesigning in ComponentState then
    Exit;
  F := FBinding.Link.Field;
  if (EditMask = '') or FMaskFromField then
  begin
    if (F <> nil) and (F.EditMask <> '') then
    begin
      EditMask := F.EditMask;
      FMaskFromField := True;
    end
    else if FMaskFromField then
    begin
      EditMask := '';
      FMaskFromField := False;
    end;
  end;
end;

procedure TPPGDBMaskEdit.Loaded;
begin
  inherited Loaded;
  FBinding.Reload;
end;

procedure TPPGDBMaskEdit.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FBinding <> nil) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TPPGDBMaskEdit.GetDataField: string;
begin
  Result := FBinding.Link.FieldName;
end;

procedure TPPGDBMaskEdit.SetDataField(const Value: string);
begin
  FBinding.Link.FieldName := Value;
end;

function TPPGDBMaskEdit.GetDataSource: TDataSource;
begin
  Result := FBinding.Link.DataSource;
end;

procedure TPPGDBMaskEdit.SetDataSource(Value: TDataSource);
begin
  PPGDBSetDataSource(Self, FBinding.Link, Value);
end;

function TPPGDBMaskEdit.GetField: TField;
begin
  Result := FBinding.Link.Field;
end;

function TPPGDBMaskEdit.GetReadOnly: Boolean;
begin
  Result := FBinding.Link.ReadOnly;
end;

procedure TPPGDBMaskEdit.SetReadOnly(const Value: Boolean);
begin
  FBinding.Link.ReadOnly := Value;
  FBinding.UpdateEditable;
end;

procedure TPPGDBMaskEdit.Change;
begin
  if FBinding.UserChange then
    inherited Change;
end;

procedure TPPGDBMaskEdit.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and FBinding.Link.Editing then
  begin
    FBinding.Link.Reset;
    SelectAll;
    Key := 0;
    Exit;
  end;
  inherited FieldKeyDown(Key, Shift);
end;

function TPPGDBMaskEdit.WantSpecialKey(Key: Word): Boolean;
begin
  Result := ((Key = VK_ESCAPE) and FBinding.Link.Editing) or inherited WantSpecialKey(Key);
end;

procedure TPPGDBMaskEdit.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FBinding.Link);
end;

function TPPGDBMaskEdit.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FBinding <> nil) and FBinding.ExecuteAction(Action));
end;

function TPPGDBMaskEdit.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FBinding <> nil) and FBinding.UpdateAction(Action));
end;

procedure TPPGDBMaskEdit.CMExit(var Message: TCMExit);
begin
  // Ungueltige Maske: nicht schreiben, Fehler bleibt am Feld (wie TDBEdit)
  if IsMasked and not ValidateInput then
  begin
    inherited;
    Exit;
  end;
  FBinding.Commit;
  inherited;
end;

{ TPPGDBNumberEdit }

constructor TPPGDBNumberEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AllowNull := True;
  FBinding := TPPGDBValueBinding.Create(Self, dvmVariant);
  FBinding.OnBeforeUpdate := BeforeUpdate;
  FBinding.UpdateEditable;
end;

destructor TPPGDBNumberEdit.Destroy;
begin
  FreeAndNil(FBinding);
  inherited Destroy;
end;

procedure TPPGDBNumberEdit.BeforeUpdate(Sender: TObject);
begin
  // Laufende Eingabe (z.B. "2*19,99") vor dem Schreiben uebernehmen
  if FieldFocused then
    Commit;
end;

procedure TPPGDBNumberEdit.Loaded;
begin
  inherited Loaded;
  FBinding.Reload;
end;

procedure TPPGDBNumberEdit.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FBinding <> nil) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TPPGDBNumberEdit.GetDataField: string;
begin
  Result := FBinding.Link.FieldName;
end;

procedure TPPGDBNumberEdit.SetDataField(const Value: string);
begin
  FBinding.Link.FieldName := Value;
end;

function TPPGDBNumberEdit.GetDataSource: TDataSource;
begin
  Result := FBinding.Link.DataSource;
end;

procedure TPPGDBNumberEdit.SetDataSource(Value: TDataSource);
begin
  PPGDBSetDataSource(Self, FBinding.Link, Value);
end;

function TPPGDBNumberEdit.GetField: TField;
begin
  Result := FBinding.Link.Field;
end;

function TPPGDBNumberEdit.GetReadOnly: Boolean;
begin
  Result := FBinding.Link.ReadOnly;
end;

procedure TPPGDBNumberEdit.SetReadOnly(const Value: Boolean);
begin
  FBinding.Link.ReadOnly := Value;
  FBinding.UpdateEditable;
end;

procedure TPPGDBNumberEdit.Change;
begin
  // Tippen und uebernommene Werte setzen den Datensatz in Bearbeitung
  if FBinding.UserChange then
    inherited Change;
end;

procedure TPPGDBNumberEdit.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and FBinding.Link.Editing and (Trim(Text) = EditText) then
  begin
    FBinding.Link.Reset;
    Key := 0;
    Exit;
  end;
  inherited FieldKeyDown(Key, Shift);
end;

procedure TPPGDBNumberEdit.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FBinding.Link);
end;

function TPPGDBNumberEdit.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FBinding <> nil) and FBinding.ExecuteAction(Action));
end;

function TPPGDBNumberEdit.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FBinding <> nil) and FBinding.UpdateAction(Action));
end;

procedure TPPGDBNumberEdit.CMExit(var Message: TCMExit);
begin
  FBinding.Commit;
  inherited;
end;

{ TPPGDBColorPicker }

constructor TPPGDBColorPicker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBinding := TPPGDBValueBinding.Create(Self, dvmVariant);
  FBinding.UpdateEditable;
end;

destructor TPPGDBColorPicker.Destroy;
begin
  FreeAndNil(FBinding);
  inherited Destroy;
end;

procedure TPPGDBColorPicker.Loaded;
begin
  inherited Loaded;
  FBinding.Reload;
end;

procedure TPPGDBColorPicker.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FBinding <> nil) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TPPGDBColorPicker.GetDataField: string;
begin
  Result := FBinding.Link.FieldName;
end;

procedure TPPGDBColorPicker.SetDataField(const Value: string);
begin
  FBinding.Link.FieldName := Value;
end;

function TPPGDBColorPicker.GetDataSource: TDataSource;
begin
  Result := FBinding.Link.DataSource;
end;

procedure TPPGDBColorPicker.SetDataSource(Value: TDataSource);
begin
  PPGDBSetDataSource(Self, FBinding.Link, Value);
end;

function TPPGDBColorPicker.GetField: TField;
begin
  Result := FBinding.Link.Field;
end;

function TPPGDBColorPicker.GetReadOnly: Boolean;
begin
  Result := FBinding.Link.ReadOnly;
end;

procedure TPPGDBColorPicker.SetReadOnly(const Value: Boolean);
begin
  FBinding.Link.ReadOnly := Value;
  FBinding.UpdateEditable;
end;

procedure TPPGDBColorPicker.Change;
begin
  if FBinding.UserChange then
    inherited Change;
end;

procedure TPPGDBColorPicker.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  // Audit 4b: Esc setzt die Bearbeitung zurueck (offenes Popup zuerst zu)
  if not DroppedDown and FBinding.HandleEscape(Key) then
    Exit;
  inherited FieldKeyDown(Key, Shift);
end;

function TPPGDBColorPicker.WantSpecialKey(Key: Word): Boolean;
begin
  Result := ((Key = VK_ESCAPE) and not DroppedDown and FBinding.WantsEscape) or
    inherited WantSpecialKey(Key);
end;

procedure TPPGDBColorPicker.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FBinding.Link);
end;

function TPPGDBColorPicker.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FBinding <> nil) and FBinding.ExecuteAction(Action));
end;

function TPPGDBColorPicker.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FBinding <> nil) and FBinding.UpdateAction(Action));
end;

procedure TPPGDBColorPicker.CMExit(var Message: TCMExit);
begin
  FBinding.Commit;
  inherited;
end;

{ TPPGDBCheckComboBox }

constructor TPPGDBCheckComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBinding := TPPGDBValueBinding.Create(Self, dvmText);
  FBinding.UpdateEditable;
end;

destructor TPPGDBCheckComboBox.Destroy;
begin
  FreeAndNil(FBinding);
  inherited Destroy;
end;

procedure TPPGDBCheckComboBox.Loaded;
begin
  inherited Loaded;
  FBinding.Reload;
end;

procedure TPPGDBCheckComboBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FBinding <> nil) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TPPGDBCheckComboBox.GetDataField: string;
begin
  Result := FBinding.Link.FieldName;
end;

procedure TPPGDBCheckComboBox.SetDataField(const Value: string);
begin
  FBinding.Link.FieldName := Value;
end;

function TPPGDBCheckComboBox.GetDataSource: TDataSource;
begin
  Result := FBinding.Link.DataSource;
end;

procedure TPPGDBCheckComboBox.SetDataSource(Value: TDataSource);
begin
  PPGDBSetDataSource(Self, FBinding.Link, Value);
end;

function TPPGDBCheckComboBox.GetField: TField;
begin
  Result := FBinding.Link.Field;
end;

function TPPGDBCheckComboBox.GetReadOnly: Boolean;
begin
  Result := FBinding.Link.ReadOnly;
end;

procedure TPPGDBCheckComboBox.SetReadOnly(const Value: Boolean);
begin
  FBinding.Link.ReadOnly := Value;
  FBinding.UpdateEditable;
end;

procedure TPPGDBCheckComboBox.Change;
begin
  if FBinding.UserChange then
    inherited Change;
end;

procedure TPPGDBCheckComboBox.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  // Audit 4b: Esc setzt die Bearbeitung zurueck (offenes Popup zuerst zu)
  if not DroppedDown and FBinding.HandleEscape(Key) then
    Exit;
  inherited FieldKeyDown(Key, Shift);
end;

function TPPGDBCheckComboBox.WantSpecialKey(Key: Word): Boolean;
begin
  Result := ((Key = VK_ESCAPE) and not DroppedDown and FBinding.WantsEscape) or
    inherited WantSpecialKey(Key);
end;

procedure TPPGDBCheckComboBox.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FBinding.Link);
end;

function TPPGDBCheckComboBox.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FBinding <> nil) and FBinding.ExecuteAction(Action));
end;

function TPPGDBCheckComboBox.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FBinding <> nil) and FBinding.UpdateAction(Action));
end;

procedure TPPGDBCheckComboBox.CMExit(var Message: TCMExit);
begin
  FBinding.Commit;
  inherited;
end;

{ TPPGDBTagEdit }

constructor TPPGDBTagEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBinding := TPPGDBValueBinding.Create(Self, dvmText);
  FBinding.OnBeforeUpdate := BeforeUpdate;
  FBinding.UpdateEditable;
end;

destructor TPPGDBTagEdit.Destroy;
begin
  FreeAndNil(FBinding);
  inherited Destroy;
end;

procedure TPPGDBTagEdit.BeforeUpdate(Sender: TObject);
begin
  // Getippter Rest wird vor dem Schreiben ein Tag
  if FieldFocused and (Trim(Text) <> '') then
    CommitText;
end;

procedure TPPGDBTagEdit.DoTagsChange;
begin
  if FBinding.UserChange then
    inherited DoTagsChange;
end;

procedure TPPGDBTagEdit.Loaded;
begin
  inherited Loaded;
  FBinding.Reload;
end;

procedure TPPGDBTagEdit.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FBinding <> nil) and (AComponent = DataSource) then
    DataSource := nil;
end;

function TPPGDBTagEdit.GetDataField: string;
begin
  Result := FBinding.Link.FieldName;
end;

procedure TPPGDBTagEdit.SetDataField(const Value: string);
begin
  FBinding.Link.FieldName := Value;
end;

function TPPGDBTagEdit.GetDataSource: TDataSource;
begin
  Result := FBinding.Link.DataSource;
end;

procedure TPPGDBTagEdit.SetDataSource(Value: TDataSource);
begin
  PPGDBSetDataSource(Self, FBinding.Link, Value);
end;

function TPPGDBTagEdit.GetField: TField;
begin
  Result := FBinding.Link.Field;
end;

function TPPGDBTagEdit.GetReadOnly: Boolean;
begin
  Result := FBinding.Link.ReadOnly;
end;

procedure TPPGDBTagEdit.SetReadOnly(const Value: Boolean);
begin
  FBinding.Link.ReadOnly := Value;
  FBinding.UpdateEditable;
end;

procedure TPPGDBTagEdit.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  // Audit 4b: Esc setzt die Bearbeitung zurueck (offenes Popup zuerst zu)
  if not DroppedDown and FBinding.HandleEscape(Key) then
    Exit;
  inherited FieldKeyDown(Key, Shift);
end;

function TPPGDBTagEdit.WantSpecialKey(Key: Word): Boolean;
begin
  Result := ((Key = VK_ESCAPE) and not DroppedDown and FBinding.WantsEscape) or
    inherited WantSpecialKey(Key);
end;

procedure TPPGDBTagEdit.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FBinding.Link);
end;

function TPPGDBTagEdit.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FBinding <> nil) and FBinding.ExecuteAction(Action));
end;

function TPPGDBTagEdit.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FBinding <> nil) and FBinding.UpdateAction(Action));
end;

procedure TPPGDBTagEdit.CMExit(var Message: TCMExit);
begin
  FBinding.Commit;
  inherited;
end;

end.
