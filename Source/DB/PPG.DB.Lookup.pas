unit PPG.DB.Lookup;

{ TPPGDBLookupComboBox - Auswahl eines Schluessels aus einer zweiten
  Datenmenge (Phase 9c), wie TDBLookupComboBox.

  - ListSource/KeyField/ListField: die Liste kommt aus ListSource.DataSet;
    angezeigt wird das erste Feld aus ListField, weitere Felder (durch
    Semikolon getrennt) erscheinen als Detailzeile (ItemsEx).
  - DataSource/DataField: das Schluesselfeld der Haupt-Datenmenge. Auswahl
    schreibt KeyField des gewaehlten Eintrags hinein.
  - Die Liste wird beim Oeffnen bzw. Aendern der Listen-Datenmenge einmal
    vollstaendig gelesen (DisableControls, Lesezeichen wird wiederhergestellt).
    Fuer sehr grosse Nachschlage-Tabellen ist ein Filter in der Abfrage der
    bessere Weg.
  - Immer csDropDownList: Tippen sucht wie bei der ComboBox (Tippsuche).
  - Nachschlagefeld (TField.FieldKind = fkLookup) als DataField (Audit 4b):
    geschrieben wird sein Schluesselfeld, Liste, KeyField und ListField
    kommen aus dem Feld, solange sie nicht gesetzt sind. Mehrfachschluessel
    ('A;B') werden nicht unterstuetzt und als Warnung gemeldet.
  - NullValueKey (wie TDBLookupComboBox): diese Taste leert den Wert.
  - Aendert sich die Listen-Datenmenge, wird die Liste gebuendelt neu gelesen
    (eine gepostete Nachricht fuer mehrere Aenderungen) bzw. spaetestens,
    wenn sie gebraucht wird. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.Variants,
  Vcl.StdCtrls, Vcl.Menus, Data.DB, PPG.Items, PPG.DB.Controls, Vcl.DBCtrls;

type
  TPPGDBLookupComboBox = class;

  /// Verbindung zur Listen-Datenmenge.
  TPPGLookupListLink = class(TDataLink)
  private
    FOwner: TPPGDBLookupComboBox;
  protected
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure LayoutChanged; override;
  public
    constructor Create(AOwner: TPPGDBLookupComboBox);
  end;

  TPPGDBLookupComboBox = class(TPPGDBComboBox)
  private
    FListLink: TPPGLookupListLink;
    FKeyField: string;
    FListField: string;
    FListFieldIndex: Integer;
    FKeys: array of Variant;
    FBuilding: Boolean;
    FDataFieldName: string;
    FLookupField: TField;
    FOwnListSource: TDataSource;
    FResolving: Boolean;
    FListDirty: Boolean;
    FRebuildPosted: Boolean;
    FNullValueKey: TShortCut;
    procedure ResolveDataField;
    function EffectiveKeyField: string;
    function EffectiveListField: string;
    function IsListSourceStored: Boolean;
    procedure EnsureList;
    function GetListSource: TDataSource;
    procedure SetListSource(Value: TDataSource);
    procedure SetKeyField(const Value: string);
    procedure SetListField(const Value: string);
    procedure SetListFieldIndex(const Value: Integer);
    function GetDropDownRows: Integer;
    procedure SetDropDownRows(const Value: Integer);
    function GetDropDownAlign: TDropDownAlign;
    procedure SetDropDownAlign(const Value: TDropDownAlign);
    function GetKeyValue: Variant;
    procedure SetKeyValue(const Value: Variant);
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure WndProc(var Message: TMessage); override;
    function GetDataField: string; override;
    procedure SetDataField(const Value: string); override;
    procedure SetDataSource(Value: TDataSource); override;
    procedure ShowField; override;
    procedure WriteField; override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoDropDown; override;
    /// Listen-Datenmenge geaendert: gebuendelt neu lesen.
    procedure ListChanged;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Liste neu aus der Listen-Datenmenge lesen.
    procedure BuildList;
    /// Index des Eintrags mit diesem Schluessel, -1 = keiner.
    function IndexOfKey(const Key: Variant): Integer;
    /// Anzahl der Listeneintraege.
    function KeyCount: Integer;
    /// Schluessel des gewaehlten Eintrags (Null = keiner). Setzen waehlt den
    /// Eintrag aus (ohne Ereignis und ohne das Feld zu aendern).
    property KeyValue: Variant read GetKeyValue write SetKeyValue;
  published
    property KeyField: string read FKeyField write SetKeyField;
    property ListField: string read FListField write SetListField;
    /// Welches Feld aus ListField im Feld steht (0 = das erste); die uebrigen
    /// bilden die Detailzeile (wie TDBLookupComboBox.ListFieldIndex).
    property ListFieldIndex: Integer read FListFieldIndex write SetListFieldIndex default 0;
    /// Wie TDBLookupComboBox: gleichbedeutend mit DropDownCount (nicht eigens gespeichert).
    property DropDownRows: Integer read GetDropDownRows write SetDropDownRows stored False;
    /// Lage einer Liste, die breiter als das Feld ist.
    property DropDownAlign: TDropDownAlign read GetDropDownAlign write SetDropDownAlign default daLeft;
    property ListSource: TDataSource read GetListSource write SetListSource stored IsListSourceStored;
    /// Taste, die den Wert leert (z.B. Entf oder Strg+Entf), 0 = keine.
    property NullValueKey: TShortCut read FNullValueKey write FNullValueKey default 0;
    property Items stored False;
    property ItemsEx stored False;
    property Style default csDropDownList;
  end;

implementation

uses
  // Feldregeln fuer TPPGValidator mitlinken (AutoFieldRules)
  PPG.DB.Validator, PPG.ErrorHandler, PPG.Lang, PPG.Consts, PPG.Types;

var
  GMsgRebuild: Cardinal = 0;

{ TPPGLookupListLink }

constructor TPPGLookupListLink.Create(AOwner: TPPGDBLookupComboBox);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TPPGLookupListLink.ActiveChanged;
begin
  if FOwner <> nil then
    FOwner.BuildList;
end;

procedure TPPGLookupListLink.DataSetChanged;
begin
  if (FOwner <> nil) and not PPGDBReading then
    FOwner.ListChanged;
end;

procedure TPPGLookupListLink.LayoutChanged;
begin
  if FOwner <> nil then
    FOwner.BuildList;
end;

{ TPPGDBLookupComboBox }

constructor TPPGDBLookupComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Style := csDropDownList;
  FListLink := TPPGLookupListLink.Create(Self);
end;

destructor TPPGDBLookupComboBox.Destroy;
begin
  FLookupField := nil;
  if FListLink <> nil then
    FListLink.FOwner := nil;
  FreeAndNil(FListLink);
  inherited Destroy;
end;

procedure TPPGDBLookupComboBox.Loaded;
begin
  inherited Loaded;
  ResolveDataField;
  BuildList;
end;

procedure TPPGDBLookupComboBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation <> opRemove then
    Exit;
  if (FListLink <> nil) and (AComponent = ListSource) then
    ListSource := nil;
  if (FLookupField <> nil) and ((AComponent = FLookupField) or
    (AComponent = FLookupField.LookupDataSet)) then
  begin
    FLookupField := nil;
    if FOwnListSource <> nil then
      FOwnListSource.DataSet := nil;
  end;
end;

procedure TPPGDBLookupComboBox.WndProc(var Message: TMessage);
begin
  if (GMsgRebuild <> 0) and (Message.Msg = GMsgRebuild) then
  begin
    FRebuildPosted := False;
    if FListDirty then
      BuildList;
    Exit;
  end;
  inherited WndProc(Message);
end;

function TPPGDBLookupComboBox.GetDataField: string;
begin
  Result := FDataFieldName;
end;

procedure TPPGDBLookupComboBox.SetDataField(const Value: string);
begin
  FDataFieldName := Value;
  ResolveDataField;
end;

procedure TPPGDBLookupComboBox.SetDataSource(Value: TDataSource);
begin
  inherited SetDataSource(Value);
  ResolveDataField;
end;

procedure TPPGDBLookupComboBox.ResolveDataField;
var
  DS: TDataSet;
  F: TField;
  Name: string;
begin
  if FResolving then
    Exit;
  FResolving := True;
  try
    Name := FDataFieldName;
    FLookupField := nil;
    DS := nil;
    if GetDataSource <> nil then
      DS := GetDataSource.DataSet;
    if (DS <> nil) and (Name <> '') then
    begin
      F := DS.FindField(Name);
      if (F <> nil) and (F.FieldKind = fkLookup) then
      begin
        if Pos(';', F.KeyFields) > 0 then
          TPPGErrorHandler.LogWarning(Self, Format(PPGStr(@SPPGDBLookupMultiKey), [F.FieldName]))
        else
        begin
          // Geschrieben wird das Schluesselfeld; die Liste kommt aus dem Feld
          FLookupField := F;
          F.FreeNotification(Self);
          Name := F.KeyFields;
          if (FListLink.DataSource = nil) or (FListLink.DataSource = FOwnListSource) then
          begin
            if FOwnListSource = nil then
              FOwnListSource := TDataSource.Create(Self);
            FOwnListSource.DataSet := F.LookupDataSet;
            if F.LookupDataSet <> nil then
              F.LookupDataSet.FreeNotification(Self);
            FListLink.DataSource := FOwnListSource;
          end;
        end;
      end;
    end;
    if not SameText(inherited GetDataField, Name) then
      inherited SetDataField(Name);
  finally
    FResolving := False;
  end;
  BuildList;
end;

function TPPGDBLookupComboBox.EffectiveKeyField: string;
begin
  Result := FKeyField;
  if (Result = '') and (FLookupField <> nil) then
    Result := FLookupField.LookupKeyFields;
end;

function TPPGDBLookupComboBox.EffectiveListField: string;
begin
  Result := FListField;
  if (Result = '') and (FLookupField <> nil) then
    Result := FLookupField.LookupResultField;
end;

function TPPGDBLookupComboBox.IsListSourceStored: Boolean;
begin
  Result := (FListLink.DataSource <> nil) and (FListLink.DataSource <> FOwnListSource);
end;

procedure TPPGDBLookupComboBox.ListChanged;
begin
  FListDirty := True;
  if HandleAllocated and (GMsgRebuild <> 0) then
  begin
    if not FRebuildPosted then
    begin
      FRebuildPosted := True;
      PostMessage(Handle, GMsgRebuild, 0, 0);
    end;
  end
  else
    BuildList;
end;

procedure TPPGDBLookupComboBox.EnsureList;
begin
  if FListDirty then
    BuildList;
end;

procedure TPPGDBLookupComboBox.DoDropDown;
begin
  EnsureList;
  inherited DoDropDown;
end;

procedure TPPGDBLookupComboBox.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  // NullValueKey leert den Wert (wie TDBLookupComboBox)
  if (FNullValueKey <> 0) and (ShortCut(Key, Shift) = FNullValueKey) and not DroppedDown and
    (ItemIndex >= 0) and Binding.CanModify then
  begin
    Key := 0;
    if not BeginUserChange then
      Exit;
    Setting := True;
    try
      ItemIndex := -1;
    finally
      Setting := False;
    end;
    DataLink.Modified;
    Exit;
  end;
  inherited FieldKeyDown(Key, Shift);
end;

function TPPGDBLookupComboBox.GetListSource: TDataSource;
begin
  Result := FListLink.DataSource;
end;

procedure TPPGDBLookupComboBox.SetListSource(Value: TDataSource);
begin
  PPGDBSetDataSource(Self, FListLink, Value);
  if (Value = nil) and (FLookupField <> nil) then
    ResolveDataField; // zurueck zur Liste des Nachschlagefelds
end;

procedure TPPGDBLookupComboBox.SetKeyField(const Value: string);
begin
  if FKeyField <> Value then
  begin
    FKeyField := Value;
    BuildList;
  end;
end;

procedure TPPGDBLookupComboBox.SetListField(const Value: string);
begin
  if FListField <> Value then
  begin
    FListField := Value;
    BuildList;
  end;
end;

procedure TPPGDBLookupComboBox.SetListFieldIndex(const Value: Integer);
begin
  if FListFieldIndex <> Value then
  begin
    FListFieldIndex := PPGCheckRange(Self, 'ListFieldIndex', Value, 0, MaxInt);
    BuildList;
  end;
end;

function TPPGDBLookupComboBox.GetDropDownRows: Integer;
begin
  Result := DropDownCount;
end;

procedure TPPGDBLookupComboBox.SetDropDownRows(const Value: Integer);
begin
  DropDownCount := Value;
end;

function TPPGDBLookupComboBox.GetDropDownAlign: TDropDownAlign;
begin
  case PopupAlign of
    taRightJustify: Result := daRight;
    taCenter: Result := daCenter;
  else
    Result := daLeft;
  end;
end;

procedure TPPGDBLookupComboBox.SetDropDownAlign(const Value: TDropDownAlign);
begin
  case Value of
    daRight: PopupAlign := taRightJustify;
    daCenter: PopupAlign := taCenter;
  else
    PopupAlign := taLeftJustify;
  end;
end;

function TPPGDBLookupComboBox.KeyCount: Integer;
begin
  EnsureList;
  Result := Length(FKeys);
end;

function TPPGDBLookupComboBox.IndexOfKey(const Key: Variant): Integer;
var
  I: Integer;
begin
  Result := -1;
  EnsureList;
  if VarIsNull(Key) or VarIsEmpty(Key) then
    Exit;
  for I := 0 to High(FKeys) do
    if not VarIsNull(FKeys[I]) and (VarCompareValue(FKeys[I], Key) = vrEqual) then
      Exit(I);
end;

procedure TPPGDBLookupComboBox.BuildList;
var
  DS: TDataSet;
  KeyF: TField;
  Fields: TList;
  Names: TStringList;
  B: TBookmark;
  I, N: Integer;
  Detail: string;
  It: Integer;
  Main: Integer;
  Item: TPPGItem;
begin
  if FBuilding or (csLoading in ComponentState) or (FListLink = nil) then
    Exit;
  // Offene Bearbeitung der Listenmenge: First wuerde sie still speichern.
  // Die alte Liste bleibt; nach Post/Cancel kommt DataSetChanged.
  if FListLink.Active and (FListLink.DataSet.State in dsEditModes) then
    Exit;
  FBuilding := True;
  FListDirty := False;
  try
    SetLength(FKeys, 0);
    ItemsEx.Clear;
    Items.Clear;
    if not FListLink.Active or (EffectiveKeyField = '') or (EffectiveListField = '') then
      Exit;
    DS := FListLink.DataSet;
    if Pos(';', EffectiveKeyField) > 0 then
    begin
      // Vorher blieb die Liste still leer
      TPPGErrorHandler.LogWarning(Self, Format(PPGStr(@SPPGDBLookupMultiKey), [EffectiveKeyField]));
      Exit;
    end;
    KeyF := DS.FindField(EffectiveKeyField);
    if KeyF = nil then
      Exit;
    Fields := TList.Create;
    Names := TStringList.Create;
    try
      Names.Delimiter := ';';
      Names.StrictDelimiter := True;
      Names.DelimitedText := EffectiveListField;
      for I := 0 to Names.Count - 1 do
        if DS.FindField(Trim(Names[I])) <> nil then
          Fields.Add(DS.FindField(Trim(Names[I])));
      if Fields.Count = 0 then
        Exit;
      // ListFieldIndex ausserhalb der Felder: das erste (wie die VCL)
      Main := FListFieldIndex;
      if Main >= Fields.Count then
        Main := 0;
      PPGDBBeginRead;
      DS.DisableControls;
      try
        B := DS.Bookmark;
        try
          DS.First;
          N := 0;
          while not DS.Eof do
          begin
            SetLength(FKeys, N + 1);
            FKeys[N] := KeyF.Value;
            Detail := '';
            for It := 0 to Fields.Count - 1 do
              if It <> Main then
              begin
                if Detail <> '' then
                  Detail := Detail + ' - ';
                Detail := Detail + TField(Fields[It]).DisplayText;
              end;
            Item := ItemsEx.Add;
            Item.Text := TField(Fields[Main]).DisplayText;
            Item.Detail := Detail;
            Inc(N);
            DS.Next;
          end;
        finally
          if DS.BookmarkValid(B) then
            DS.Bookmark := B;
        end;
      finally
        DS.EnableControls;
        PPGDBEndRead;
      end;
    finally
      Names.Free;
      Fields.Free;
    end;
  finally
    FBuilding := False;
  end;
  Reload;
end;

procedure TPPGDBLookupComboBox.ShowField;
var
  F: TField;
begin
  if FBuilding then
    Exit;
  F := DataLink.Field;
  if F = nil then
    ItemIndex := -1
  else
    ItemIndex := IndexOfKey(F.Value);
end;

procedure TPPGDBLookupComboBox.WriteField;
begin
  if (ItemIndex >= 0) and (ItemIndex < Length(FKeys)) then
    DataLink.Field.Value := FKeys[ItemIndex]
  else
    DataLink.Field.Clear;
end;

function TPPGDBLookupComboBox.GetKeyValue: Variant;
begin
  if (ItemIndex >= 0) and (ItemIndex < Length(FKeys)) then
    Result := FKeys[ItemIndex]
  else
    Result := Null;
end;

procedure TPPGDBLookupComboBox.SetKeyValue(const Value: Variant);
begin
  Setting := True;
  try
    ItemIndex := IndexOfKey(Value);
  finally
    Setting := False;
  end;
end;

initialization
  GMsgRebuild := RegisterWindowMessage('PPGlow.LookupRebuild');

end.
