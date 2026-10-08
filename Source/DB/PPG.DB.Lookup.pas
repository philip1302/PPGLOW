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
  - Nicht unterstuetzt: Nachschlagefelder (TField.FieldKind = fkLookup) als
    DataField - dafuer ListSource/KeyField/ListField direkt setzen. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.SysUtils, System.Variants, Vcl.StdCtrls, Data.DB,
  PPG.Items, PPG.DB.Controls;

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
    FKeys: array of Variant;
    FBuilding: Boolean;
    function GetListSource: TDataSource;
    procedure SetListSource(Value: TDataSource);
    procedure SetKeyField(const Value: string);
    procedure SetListField(const Value: string);
    function GetKeyValue: Variant;
    procedure SetKeyValue(const Value: Variant);
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DataChange(Sender: TObject); override;
    procedure UpdateData(Sender: TObject); override;
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
    property ListSource: TDataSource read GetListSource write SetListSource;
    property Items stored False;
    property ItemsEx stored False;
    property Style default csDropDownList;
  end;

implementation

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
    FOwner.BuildList;
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
  if FListLink <> nil then
    FListLink.FOwner := nil;
  FreeAndNil(FListLink);
  inherited Destroy;
end;

procedure TPPGDBLookupComboBox.Loaded;
begin
  inherited Loaded;
  BuildList;
end;

procedure TPPGDBLookupComboBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FListLink <> nil) and (AComponent = ListSource) then
    ListSource := nil;
end;

function TPPGDBLookupComboBox.GetListSource: TDataSource;
begin
  Result := FListLink.DataSource;
end;

procedure TPPGDBLookupComboBox.SetListSource(Value: TDataSource);
begin
  PPGDBSetDataSource(Self, FListLink, Value);
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

function TPPGDBLookupComboBox.KeyCount: Integer;
begin
  Result := Length(FKeys);
end;

function TPPGDBLookupComboBox.IndexOfKey(const Key: Variant): Integer;
var
  I: Integer;
begin
  Result := -1;
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
  Item: TPPGItem;
begin
  if FBuilding or (csLoading in ComponentState) or (FListLink = nil) then
    Exit;
  // Offene Bearbeitung der Listenmenge: First wuerde sie still speichern.
  // Die alte Liste bleibt; nach Post/Cancel kommt DataSetChanged.
  if FListLink.Active and (FListLink.DataSet.State in dsEditModes) then
    Exit;
  FBuilding := True;
  try
    SetLength(FKeys, 0);
    ItemsEx.Clear;
    Items.Clear;
    if not FListLink.Active or (FKeyField = '') or (FListField = '') then
      Exit;
    DS := FListLink.DataSet;
    KeyF := DS.FindField(FKeyField);
    if KeyF = nil then
      Exit;
    Fields := TList.Create;
    Names := TStringList.Create;
    try
      Names.Delimiter := ';';
      Names.StrictDelimiter := True;
      Names.DelimitedText := FListField;
      for I := 0 to Names.Count - 1 do
        if DS.FindField(Trim(Names[I])) <> nil then
          Fields.Add(DS.FindField(Trim(Names[I])));
      if Fields.Count = 0 then
        Exit;
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
            for It := 1 to Fields.Count - 1 do
            begin
              if Detail <> '' then
                Detail := Detail + ' - ';
              Detail := Detail + TField(Fields[It]).DisplayText;
            end;
            Item := ItemsEx.Add;
            Item.Text := TField(Fields[0]).DisplayText;
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
  DataChange(Self);
end;

procedure TPPGDBLookupComboBox.DataChange(Sender: TObject);
var
  F: TField;
begin
  if (DataLink = nil) or DataLink.Locked or FBuilding then
    Exit;
  F := DataLink.Field;
  Setting := True;
  try
    if F = nil then
      ItemIndex := -1
    else
      ItemIndex := IndexOfKey(F.Value);
  finally
    Setting := False;
  end;
end;

procedure TPPGDBLookupComboBox.UpdateData(Sender: TObject);
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

end.
