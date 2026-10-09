unit PPG.DB.Controls;

{ Datenbank-Controls (Phase 9c): TPPGDBEdit, TPPGDBMemo, TPPGDBCheckBox,
  TPPGDBComboBox, TPPGDBDatePicker.

  Eigenes Package (PPGlowDBR): Anwendungen ohne Datenbank linken kein Data.DB.
  Die Controls erben von den PPGlow-Controls und fuegen nur die Anbindung
  hinzu - keine zweite Zeichenlogik.

  Gemeinsame Anbindung (Audit 4a): TPPGDBBinding haelt den Link und erledigt,
  was alle DB-Controls gleich machen (auch PPG.DB.Fields, PPG.DB.Lookup und
  TPPGDBRadioGroup). Das Control liefert nur Anzeigen (OnShow) und Schreiben
  (OnWrite) und reicht DataField/DataSource/ReadOnly, CM_GETDATALINK,
  CM_EXIT, Esc und Actions weiter.

  Ablauf wie bei den VCL-DB-Controls:
  - Datensatz wechselt (DataChange): Wert aus dem Feld anzeigen (mit Fokus
    Field.Text, ohne Field.DisplayText).
  - Anwender aendert: zuerst den Datensatz in den Bearbeiten-Modus setzen
    (TPPGFieldDataLink.EditByUser), dann Modified. Waehrend EditByUser darf
    DataChange den neuen Wert nicht ueberschreiben (Sperre). Geht das nicht,
    wird der Feldwert wieder angezeigt.
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
  Vcl.StdCtrls, Vcl.ComCtrls, Data.DB, Vcl.DBCtrls,
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

  /// Gemeinsame Anbindung eines Controls an ein Datenbankfeld (Audit 4a).
  TPPGDBBinding = class
  private
    FCtrl: TWinControl;
    FLink: TPPGFieldDataLink;
    FSetting: Boolean;
    FAutoReadOnly: Boolean;
    FOnShow: TNotifyEvent;
    FOnWrite: TNotifyEvent;
    FOnEditable: TNotifyEvent;
    FOnBeforeUpdate: TNotifyEvent;
    procedure LinkDataChange(Sender: TObject);
    procedure LinkEditingChange(Sender: TObject);
    procedure LinkUpdateData(Sender: TObject);
    function GetDataField: string;
    procedure SetDataField(const Value: string);
    function GetDataSource: TDataSource;
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetReadOnly(const Value: Boolean);
  protected
    /// Feldwert anzeigen (Vorgabe: OnShow). Laeuft mit Setting = True.
    procedure ShowValue; virtual;
    /// Wert ins Feld schreiben (Vorgabe: OnWrite). Field ist nicht nil.
    procedure WriteValue; virtual;
  public
    /// AAutoReadOnly: ein Feld-Control (TPPGCustomField) folgt CanModify mit
    /// seinem ReadOnly, wenn OnEditable nicht gesetzt ist.
    constructor Create(ACtrl: TWinControl; AAutoReadOnly: Boolean = True);
    destructor Destroy; override;
    /// Feldwert neu anzeigen (wie ein Datensatzwechsel).
    procedure Reload;
    /// ReadOnly des Controls nach CanModify (bzw. OnEditable).
    procedure UpdateEditable;
    /// Bearbeiten-Modus durch den Anwender; False = nicht aenderbar (der
    /// Feldwert wird wieder angezeigt).
    function TryEdit: Boolean;
    /// Aus Change des Controls: True = Aenderung darf weiterlaufen.
    function UserChange: Boolean;
    /// Beim Verlassen ins Feld schreiben (Feld-Control: Fehler am Feld und
    /// stiller Abbruch; sonst Fokus behalten und weiterwerfen).
    procedure Commit;
    /// Esc waehrend der Bearbeitung: zuruecksetzen, Key := 0, True.
    function HandleEscape(var Key: Word): Boolean;
    /// True, solange Esc der Bearbeitung gehoert (nicht dem Cancel-Button).
    function WantsEscape: Boolean;
    function CanModify: Boolean;
    function ExecuteAction(Action: TBasicAction): Boolean;
    function UpdateAction(Action: TBasicAction): Boolean;
    procedure SetDataSource(Value: TDataSource);
    /// Aus Notification des Controls: freigegebene DataSource loesen.
    procedure Notify(AComponent: TComponent; Operation: TOperation);
    property Control: TWinControl read FCtrl;
    property Link: TPPGFieldDataLink read FLink;
    /// True, solange der Feldwert gesetzt wird (keine Anwender-Aenderung).
    property Setting: Boolean read FSetting write FSetting;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property Field: TField read GetField;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly;
    property OnShow: TNotifyEvent read FOnShow write FOnShow;
    property OnWrite: TNotifyEvent read FOnWrite write FOnWrite;
    property OnEditable: TNotifyEvent read FOnEditable write FOnEditable;
    /// Vor dem Schreiben (laufende Eingabe uebernehmen).
    property OnBeforeUpdate: TNotifyEvent read FOnBeforeUpdate write FOnBeforeUpdate;
  end;

  TPPGDBEdit = class(TPPGEdit)
  private
    FBinding: TPPGDBBinding;
    procedure ShowField(Sender: TObject);
    procedure WriteField(Sender: TObject);
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
    FBinding: TPPGDBBinding;
    FAutoDisplay: Boolean;
    FMemoLoaded: Boolean;
    procedure ShowField(Sender: TObject);
    procedure WriteField(Sender: TObject);
    procedure MemoEditable(Sender: TObject);
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
    FBinding: TPPGDBBinding;
    FValueChecked: string;
    FValueUnchecked: string;
    procedure ShowField(Sender: TObject);
    procedure WriteField(Sender: TObject);
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
    FBinding: TPPGDBBinding;
    procedure DoShowField(Sender: TObject);
    procedure DoWriteField(Sender: TObject);
    function GetDataField: string;
    procedure SetDataField(const Value: string);
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetReadOnly(const Value: Boolean);
    function GetSetting: Boolean;
    procedure SetSetting(const Value: Boolean);
    function GetDataLink: TPPGFieldDataLink;
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
    /// Feldwert anzeigen (Lookup: Schluessel suchen). Laeuft mit Setting = True.
    procedure ShowField; virtual;
    /// Wert ins Feld schreiben (Lookup: Schluessel).
    procedure WriteField; virtual;
    /// Feldwert neu anzeigen (wie ein Datensatzwechsel).
    procedure Reload;
    /// True, solange der Feldwert gesetzt wird (keine Anwender-Aenderung).
    property Setting: Boolean read GetSetting write SetSetting;
    property DataLink: TPPGFieldDataLink read GetDataLink;
    property Binding: TPPGDBBinding read FBinding;
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
    FBinding: TPPGDBBinding;
    procedure ShowField(Sender: TObject);
    procedure WriteField(Sender: TObject);
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
/// Klammer um das Lesen einer ganzen Datenmenge (DisableControls ...
/// EnableControls) durch ein PPGlow-Control. EnableControls meldet allen
/// Links deDataSetChange; PPGlow-Links ignorieren diese Meldung, solange
/// gelesen wird. Sonst laden sich zwei Controls an derselben Datenmenge
/// (Diagramm, Planer, Kanban, Nachschlageliste) endlos gegenseitig neu.
procedure PPGDBBeginRead;
procedure PPGDBEndRead;
function PPGDBReading: Boolean;

implementation

uses
  // Feldregeln fuer TPPGValidator mitlinken (AutoFieldRules)
  PPG.DB.Validator;

var
  GReadDepth: Integer;

type
  /// Zugriff auf die geschuetzten Validierungs-Properties der Feld-Basis.
  TFieldAccess = class(TPPGCustomField);

const
  DefValueChecked = 'True';
  DefValueUnchecked = 'False';

{ Hilfen }

procedure PPGDBBeginRead;
begin
  Inc(GReadDepth);
end;

procedure PPGDBEndRead;
begin
  if GReadDepth > 0 then
    Dec(GReadDepth);
end;

function PPGDBReading: Boolean;
begin
  Result := GReadDepth > 0;
end;

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

{ TPPGDBBinding }

constructor TPPGDBBinding.Create(ACtrl: TWinControl; AAutoReadOnly: Boolean);
begin
  inherited Create;
  FCtrl := ACtrl;
  FAutoReadOnly := AAutoReadOnly;
  FLink := TPPGFieldDataLink.Create;
  FLink.Control := ACtrl;
  FLink.OnDataChange := LinkDataChange;
  FLink.OnEditingChange := LinkEditingChange;
  FLink.OnUpdateData := LinkUpdateData;
  FLink.OnActiveChange := LinkDataChange;
end;

destructor TPPGDBBinding.Destroy;
begin
  FreeAndNil(FLink);
  inherited Destroy;
end;

procedure TPPGDBBinding.ShowValue;
begin
  if Assigned(FOnShow) then
    FOnShow(Self);
end;

procedure TPPGDBBinding.WriteValue;
begin
  if Assigned(FOnWrite) then
    FOnWrite(Self);
end;

procedure TPPGDBBinding.LinkDataChange(Sender: TObject);
begin
  if FLink.Locked then
    Exit;
  FSetting := True;
  try
    ShowValue;
  finally
    FSetting := False;
  end;
  // Neuer Datensatz: ein Fehler des vorigen gilt nicht mehr
  if (FCtrl is TPPGCustomField) and (TFieldAccess(FCtrl).ValidationState = pvsError) then
  begin
    TFieldAccess(FCtrl).ValidationState := pvsNone;
    TFieldAccess(FCtrl).ValidationHint := '';
  end;
  UpdateEditable;
end;

procedure TPPGDBBinding.LinkEditingChange(Sender: TObject);
begin
  UpdateEditable;
end;

procedure TPPGDBBinding.LinkUpdateData(Sender: TObject);
begin
  if Assigned(FOnBeforeUpdate) then
    FOnBeforeUpdate(Self);
  if FLink.Field <> nil then
    WriteValue;
end;

procedure TPPGDBBinding.Reload;
begin
  LinkDataChange(nil);
end;

procedure TPPGDBBinding.UpdateEditable;
begin
  if Assigned(FOnEditable) then
    FOnEditable(Self)
  else if FAutoReadOnly and (FCtrl is TPPGCustomField) then
    // Ohne aenderbares Feld schreibgeschuetzt (wie TDBEdit)
    TFieldAccess(FCtrl).ReadOnly := not FLink.CanModify;
end;

function TPPGDBBinding.TryEdit: Boolean;
begin
  Result := FLink.Editing or FLink.EditByUser;
  if not Result then
    Reload;
end;

function TPPGDBBinding.UserChange: Boolean;
begin
  Result := True;
  if FSetting or (csDesigning in FCtrl.ComponentState) then
    Exit;
  if not TryEdit then
    Exit(False);
  FLink.Modified;
end;

procedure TPPGDBBinding.Commit;
begin
  if FCtrl is TPPGCustomField then
    PPGDBCommitField(TPPGCustomField(FCtrl), FLink)
  else
    CommitOther(FCtrl, FLink);
end;

function TPPGDBBinding.HandleEscape(var Key: Word): Boolean;
begin
  Result := (Key = VK_ESCAPE) and FLink.Editing;
  if Result then
  begin
    FLink.Reset;
    Key := 0;
  end;
end;

function TPPGDBBinding.WantsEscape: Boolean;
begin
  Result := FLink.Editing;
end;

function TPPGDBBinding.CanModify: Boolean;
begin
  Result := FLink.CanModify;
end;

function TPPGDBBinding.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := FLink.ExecuteAction(Action);
end;

function TPPGDBBinding.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := FLink.UpdateAction(Action);
end;

procedure TPPGDBBinding.SetDataSource(Value: TDataSource);
begin
  PPGDBSetDataSource(FCtrl, FLink, Value);
end;

procedure TPPGDBBinding.Notify(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent <> nil) and (AComponent = FLink.DataSource) then
    SetDataSource(nil);
end;

function TPPGDBBinding.GetDataField: string;
begin
  Result := FLink.FieldName;
end;

procedure TPPGDBBinding.SetDataField(const Value: string);
begin
  FLink.FieldName := Value;
end;

function TPPGDBBinding.GetDataSource: TDataSource;
begin
  Result := FLink.DataSource;
end;

function TPPGDBBinding.GetField: TField;
begin
  Result := FLink.Field;
end;

function TPPGDBBinding.GetReadOnly: Boolean;
begin
  Result := FLink.ReadOnly;
end;

procedure TPPGDBBinding.SetReadOnly(const Value: Boolean);
begin
  FLink.ReadOnly := Value;
  UpdateEditable;
end;

{ TPPGDBEdit }

constructor TPPGDBEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBinding := TPPGDBBinding.Create(Self);
  FBinding.OnShow := ShowField;
  FBinding.OnWrite := WriteField;
  FBinding.UpdateEditable;
end;

destructor TPPGDBEdit.Destroy;
begin
  FreeAndNil(FBinding);
  inherited Destroy;
end;

procedure TPPGDBEdit.Loaded;
begin
  inherited Loaded;
  if csDesigning in ComponentState then
    FBinding.Reload;
end;

procedure TPPGDBEdit.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if FBinding <> nil then
    FBinding.Notify(AComponent, Operation);
end;

function TPPGDBEdit.GetDataField: string;
begin
  Result := FBinding.DataField;
end;

procedure TPPGDBEdit.SetDataField(const Value: string);
begin
  FBinding.DataField := Value;
end;

function TPPGDBEdit.GetDataSource: TDataSource;
begin
  Result := FBinding.DataSource;
end;

procedure TPPGDBEdit.SetDataSource(Value: TDataSource);
begin
  FBinding.DataSource := Value;
end;

function TPPGDBEdit.GetField: TField;
begin
  Result := FBinding.Field;
end;

function TPPGDBEdit.GetReadOnly: Boolean;
begin
  Result := FBinding.ReadOnly;
end;

procedure TPPGDBEdit.SetReadOnly(const Value: Boolean);
begin
  FBinding.ReadOnly := Value;
end;

procedure TPPGDBEdit.ShowField(Sender: TObject);
var
  F: TField;
begin
  F := FBinding.Field;
  if F <> nil then
  begin
    Alignment := F.Alignment;
    if FieldFocused and FBinding.CanModify then
      Text := F.Text
    else
      Text := F.DisplayText;
  end
  else if csDesigning in ComponentState then
    Text := Name
  else
    Text := '';
  Modified := False;
end;

procedure TPPGDBEdit.WriteField(Sender: TObject);
begin
  FBinding.Field.Text := Text;
end;

procedure TPPGDBEdit.Change;
begin
  if (FBinding = nil) or FBinding.UserChange then
    inherited Change;
end;

procedure TPPGDBEdit.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  if FBinding.HandleEscape(Key) then
  begin
    SelectAll;
    Exit;
  end;
  inherited FieldKeyDown(Key, Shift);
end;

procedure TPPGDBEdit.FieldKeyPress(var Key: Char);
begin
  if (Key >= #32) and (FBinding.Field <> nil) and not FBinding.Field.IsValidChar(Key) then
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
  Result := ((Key = VK_ESCAPE) and FBinding.WantsEscape) or inherited WantSpecialKey(Key);
end;

procedure TPPGDBEdit.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FBinding.Link);
end;

procedure TPPGDBEdit.CMEnter(var Message: TCMEnter);
begin
  inherited;
  // Mit Fokus Field.Text (Bearbeitungsformat) statt DisplayText
  if not Modified then
    FBinding.Reload;
end;

procedure TPPGDBEdit.CMExit(var Message: TCMExit);
begin
  FBinding.Commit;
  inherited;
  if not Modified then
    FBinding.Reload;
end;

function TPPGDBEdit.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FBinding <> nil) and FBinding.ExecuteAction(Action));
end;

function TPPGDBEdit.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FBinding <> nil) and FBinding.UpdateAction(Action));
end;

{ TPPGDBMemo }

constructor TPPGDBMemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoDisplay := True;
  FBinding := TPPGDBBinding.Create(Self);
  FBinding.OnShow := ShowField;
  FBinding.OnWrite := WriteField;
  FBinding.OnEditable := MemoEditable;
  FBinding.UpdateEditable;
end;

destructor TPPGDBMemo.Destroy;
begin
  FreeAndNil(FBinding);
  inherited Destroy;
end;

procedure TPPGDBMemo.Loaded;
begin
  inherited Loaded;
  if csDesigning in ComponentState then
    FBinding.Reload;
end;

procedure TPPGDBMemo.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if FBinding <> nil then
    FBinding.Notify(AComponent, Operation);
end;

function TPPGDBMemo.GetDataField: string;
begin
  Result := FBinding.DataField;
end;

procedure TPPGDBMemo.SetDataField(const Value: string);
begin
  FBinding.DataField := Value;
end;

function TPPGDBMemo.GetDataSource: TDataSource;
begin
  Result := FBinding.DataSource;
end;

procedure TPPGDBMemo.SetDataSource(Value: TDataSource);
begin
  FBinding.DataSource := Value;
end;

function TPPGDBMemo.GetField: TField;
begin
  Result := FBinding.Field;
end;

function TPPGDBMemo.GetReadOnly: Boolean;
begin
  Result := FBinding.ReadOnly;
end;

procedure TPPGDBMemo.SetReadOnly(const Value: Boolean);
begin
  FBinding.ReadOnly := Value;
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

procedure TPPGDBMemo.MemoEditable(Sender: TObject);
begin
  inherited ReadOnly := not FBinding.CanModify or not FMemoLoaded;
end;

procedure TPPGDBMemo.LoadMemo;
var
  F: TField;
begin
  if FMemoLoaded then
    Exit;
  F := FBinding.Field;
  if (F = nil) or not F.IsBlob then
    Exit;
  FBinding.Setting := True;
  try
    Text := F.AsString;
    Modified := False;
  finally
    FBinding.Setting := False;
  end;
  FMemoLoaded := True;
  FBinding.UpdateEditable;
end;

procedure TPPGDBMemo.ShowField(Sender: TObject);
var
  F: TField;
begin
  F := FBinding.Field;
  FMemoLoaded := False;
  if F <> nil then
  begin
    if F.IsBlob then
    begin
      if FAutoDisplay or (FBinding.Link.Editing and (FBinding.DataSource.State = dsInsert)) then
      begin
        Text := F.AsString;
        FMemoLoaded := True;
      end
      else
        Text := '(' + F.DisplayLabel + ')';
    end
    else
    begin
      if FieldFocused and FBinding.CanModify then
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
end;

procedure TPPGDBMemo.WriteField(Sender: TObject);
begin
  if FBinding.Field.IsBlob then
    FBinding.Field.AsString := Text
  else
    FBinding.Field.Text := Text;
end;

procedure TPPGDBMemo.Change;
begin
  if (FBinding = nil) or FBinding.UserChange then
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
  if FBinding.HandleEscape(Key) then
  begin
    SelectAll;
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
  Result := ((Key = VK_ESCAPE) and FBinding.WantsEscape) or inherited WantSpecialKey(Key);
end;

procedure TPPGDBMemo.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FBinding.Link);
end;

procedure TPPGDBMemo.CMExit(var Message: TCMExit);
begin
  FBinding.Commit;
  inherited;
end;

function TPPGDBMemo.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FBinding <> nil) and FBinding.ExecuteAction(Action));
end;

function TPPGDBMemo.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FBinding <> nil) and FBinding.UpdateAction(Action));
end;

{ TPPGDBCheckBox }

constructor TPPGDBCheckBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FValueChecked := DefValueChecked;
  FValueUnchecked := DefValueUnchecked;
  // Kein Feld-Control: ReadOnly des Kaestchens bleibt, Toggle prueft selbst
  FBinding := TPPGDBBinding.Create(Self, False);
  FBinding.OnShow := ShowField;
  FBinding.OnWrite := WriteField;
end;

destructor TPPGDBCheckBox.Destroy;
begin
  FreeAndNil(FBinding);
  inherited Destroy;
end;

procedure TPPGDBCheckBox.Loaded;
begin
  inherited Loaded;
  if csDesigning in ComponentState then
    FBinding.Reload;
end;

procedure TPPGDBCheckBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if FBinding <> nil then
    FBinding.Notify(AComponent, Operation);
end;

function TPPGDBCheckBox.GetDataField: string;
begin
  Result := FBinding.DataField;
end;

procedure TPPGDBCheckBox.SetDataField(const Value: string);
begin
  FBinding.DataField := Value;
end;

function TPPGDBCheckBox.GetDataSource: TDataSource;
begin
  Result := FBinding.DataSource;
end;

procedure TPPGDBCheckBox.SetDataSource(Value: TDataSource);
begin
  FBinding.DataSource := Value;
end;

function TPPGDBCheckBox.GetField: TField;
begin
  Result := FBinding.Field;
end;

function TPPGDBCheckBox.GetReadOnly: Boolean;
begin
  Result := FBinding.ReadOnly;
end;

procedure TPPGDBCheckBox.SetReadOnly(const Value: Boolean);
begin
  FBinding.ReadOnly := Value;
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
  if FBinding <> nil then
    FBinding.Reload;
end;

procedure TPPGDBCheckBox.SetValueUnchecked(const Value: string);
begin
  FValueUnchecked := Value;
  if FBinding <> nil then
    FBinding.Reload;
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
  F := FBinding.Field;
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

procedure TPPGDBCheckBox.ShowField(Sender: TObject);
begin
  State := FieldState;
end;

procedure TPPGDBCheckBox.WriteField(Sender: TObject);
var
  F: TField;
begin
  F := FBinding.Field;
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
  if (csDesigning in ComponentState) or not FBinding.TryEdit then
    Exit;
  inherited Toggle;
  FBinding.Link.Modified;
end;

procedure TPPGDBCheckBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if FBinding.HandleEscape(Key) then
    Exit;
  inherited KeyDown(Key, Shift);
end;

procedure TPPGDBCheckBox.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FBinding.Link);
end;

procedure TPPGDBCheckBox.CMExit(var Message: TCMExit);
begin
  FBinding.Commit;
  inherited;
end;

function TPPGDBCheckBox.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FBinding <> nil) and FBinding.ExecuteAction(Action));
end;

function TPPGDBCheckBox.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FBinding <> nil) and FBinding.UpdateAction(Action));
end;

{ TPPGDBComboBox }

constructor TPPGDBComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBinding := TPPGDBBinding.Create(Self);
  FBinding.OnShow := DoShowField;
  FBinding.OnWrite := DoWriteField;
  FBinding.UpdateEditable;
end;

destructor TPPGDBComboBox.Destroy;
begin
  FreeAndNil(FBinding);
  inherited Destroy;
end;

procedure TPPGDBComboBox.Loaded;
begin
  inherited Loaded;
  if csDesigning in ComponentState then
    FBinding.Reload;
end;

procedure TPPGDBComboBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if FBinding <> nil then
    FBinding.Notify(AComponent, Operation);
end;

function TPPGDBComboBox.GetDataField: string;
begin
  Result := FBinding.DataField;
end;

procedure TPPGDBComboBox.SetDataField(const Value: string);
begin
  FBinding.DataField := Value;
end;

function TPPGDBComboBox.GetDataSource: TDataSource;
begin
  Result := FBinding.DataSource;
end;

procedure TPPGDBComboBox.SetDataSource(Value: TDataSource);
begin
  FBinding.DataSource := Value;
end;

function TPPGDBComboBox.GetField: TField;
begin
  Result := FBinding.Field;
end;

function TPPGDBComboBox.GetReadOnly: Boolean;
begin
  Result := FBinding.ReadOnly;
end;

procedure TPPGDBComboBox.SetReadOnly(const Value: Boolean);
begin
  FBinding.ReadOnly := Value;
end;

function TPPGDBComboBox.GetSetting: Boolean;
begin
  Result := (FBinding <> nil) and FBinding.Setting;
end;

procedure TPPGDBComboBox.SetSetting(const Value: Boolean);
begin
  FBinding.Setting := Value;
end;

function TPPGDBComboBox.GetDataLink: TPPGFieldDataLink;
begin
  if FBinding = nil then
    Result := nil
  else
    Result := FBinding.Link;
end;

procedure TPPGDBComboBox.DoShowField(Sender: TObject);
begin
  ShowField;
end;

procedure TPPGDBComboBox.DoWriteField(Sender: TObject);
begin
  WriteField;
end;

procedure TPPGDBComboBox.Reload;
begin
  if FBinding <> nil then
    FBinding.Reload;
end;

procedure TPPGDBComboBox.ShowField;
var
  F: TField;
begin
  F := FBinding.Field;
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
end;

procedure TPPGDBComboBox.WriteField;
begin
  if Style = csDropDownList then
  begin
    if ItemIndex >= 0 then
      FBinding.Field.Text := Items[ItemIndex]
    else
      FBinding.Field.Clear;
  end
  else
    FBinding.Field.Text := Text;
end;

function TPPGDBComboBox.BeginUserChange: Boolean;
begin
  Result := FBinding.TryEdit;
end;

procedure TPPGDBComboBox.Change;
begin
  if (FBinding <> nil) and not FBinding.Setting and not IsQuiet and
    not (csDesigning in ComponentState) then
  begin
    if not BeginUserChange then
      Exit;
    FBinding.Link.Modified;
  end;
  inherited Change;
end;

procedure TPPGDBComboBox.DoSelect;
begin
  if (FBinding <> nil) and not FBinding.Setting and not (csDesigning in ComponentState) then
  begin
    if not BeginUserChange then
      Exit;
    FBinding.Link.Modified;
  end;
  inherited DoSelect;
end;

procedure TPPGDBComboBox.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  if not DroppedDown and FBinding.HandleEscape(Key) then
    Exit;
  inherited FieldKeyDown(Key, Shift);
end;

function TPPGDBComboBox.WantSpecialKey(Key: Word): Boolean;
begin
  Result := ((Key = VK_ESCAPE) and FBinding.WantsEscape) or inherited WantSpecialKey(Key);
end;

procedure TPPGDBComboBox.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FBinding.Link);
end;

procedure TPPGDBComboBox.CMExit(var Message: TCMExit);
begin
  FBinding.Commit;
  inherited;
end;

function TPPGDBComboBox.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FBinding <> nil) and FBinding.ExecuteAction(Action));
end;

function TPPGDBComboBox.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FBinding <> nil) and FBinding.UpdateAction(Action));
end;

{ TPPGDBDatePicker }

constructor TPPGDBDatePicker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Eingaben sperrt FieldKeyDown/FieldKeyPress (ReadOnly bleibt beim Anwender)
  FBinding := TPPGDBBinding.Create(Self, False);
  FBinding.OnShow := ShowField;
  FBinding.OnWrite := WriteField;
end;

destructor TPPGDBDatePicker.Destroy;
begin
  FreeAndNil(FBinding);
  inherited Destroy;
end;

procedure TPPGDBDatePicker.Loaded;
begin
  inherited Loaded;
  if csDesigning in ComponentState then
    FBinding.Reload;
end;

procedure TPPGDBDatePicker.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if FBinding <> nil then
    FBinding.Notify(AComponent, Operation);
end;

function TPPGDBDatePicker.GetDataField: string;
begin
  Result := FBinding.DataField;
end;

procedure TPPGDBDatePicker.SetDataField(const Value: string);
begin
  FBinding.DataField := Value;
end;

function TPPGDBDatePicker.GetDataSource: TDataSource;
begin
  Result := FBinding.DataSource;
end;

procedure TPPGDBDatePicker.SetDataSource(Value: TDataSource);
begin
  FBinding.DataSource := Value;
end;

function TPPGDBDatePicker.GetField: TField;
begin
  Result := FBinding.Field;
end;

function TPPGDBDatePicker.GetReadOnly: Boolean;
begin
  Result := FBinding.ReadOnly;
end;

procedure TPPGDBDatePicker.SetReadOnly(const Value: Boolean);
begin
  FBinding.ReadOnly := Value;
end;

procedure TPPGDBDatePicker.ShowField(Sender: TObject);
var
  F: TField;
begin
  F := FBinding.Field;
  if (F = nil) or F.IsNull then
  begin
    // Leerer Wert: nur mit Kontrollkaestchen darstellbar (wie TDateTimePicker)
    if ShowCheckbox then
      Checked := False;
  end
  else
  begin
    // Kind = dtkDate: nur das Datum; Uhrzeit bzw. Datum+Uhrzeit: der ganze Wert
    if Kind = dtkDate then
      Date := Int(F.AsDateTime)
    else
      DateTime := F.AsDateTime;
    Checked := True;
  end;
end;

procedure TPPGDBDatePicker.WriteField(Sender: TObject);
var
  F: TField;
  T: Double;
begin
  F := FBinding.Field;
  if ShowCheckbox and not Checked then
    F.Clear
  else
  begin
    if Kind <> dtkDate then
      F.AsDateTime := DateTime
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
end;

procedure TPPGDBDatePicker.UserChange;
begin
  if (FBinding = nil) or FBinding.UserChange then
    inherited UserChange;
end;

procedure TPPGDBDatePicker.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  // Nicht aenderbar: keine Eingabe (Pfeile aendern sonst das Datum)
  if not FBinding.CanModify and ((Key = VK_UP) or (Key = VK_DOWN) or (Key = VK_DELETE)) then
  begin
    Key := 0;
    Exit;
  end;
  inherited FieldKeyDown(Key, Shift);
end;

procedure TPPGDBDatePicker.FieldKeyPress(var Key: Char);
begin
  if (Key >= #32) and not FBinding.CanModify then
  begin
    MessageBeep(0);
    Key := #0;
    Exit;
  end;
  inherited FieldKeyPress(Key);
end;

procedure TPPGDBDatePicker.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FBinding.Link);
end;

procedure TPPGDBDatePicker.CMExit(var Message: TCMExit);
begin
  // Getippten Text zuerst uebernehmen (sonst erst beim Fokusverlust), dann
  // ins Feld schreiben
  if FieldFocused and FBinding.CanModify then
    CommitText(True);
  FBinding.Commit;
  inherited;
end;

function TPPGDBDatePicker.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FBinding <> nil) and FBinding.ExecuteAction(Action));
end;

function TPPGDBDatePicker.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FBinding <> nil) and FBinding.UpdateAction(Action));
end;

end.
