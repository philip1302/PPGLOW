unit PPG.DB.RichEdit;

{ TPPGDBRichEdit - TPPGRichEdit an einem Memo- oder BLOB-Feld (Ersatz fuer TDBRichEdit).

  - Das Feld enthaelt RTF. Beim Datensatzwechsel wird der Inhalt mit
    Lines.LoadFromStream geladen, beim Verlassen des Controls (Datensatz
    bearbeitet) mit Lines.SaveToStream zurueckgeschrieben.
  - Steht im Feld kein RTF (reiner Text aus einem aelteren Bestand), wird der
    Text unformatiert angezeigt; gespeichert wird danach RTF.
  - Textfelder (ftString u. a.) und PlainText = True zeigen und schreiben
    reinen Text.
  - ReadOnly folgt dem Feld (nicht aenderbar, Datenmenge nur lesend) und der
    Eigenschaft ReadOnly. Ablauf, Esc und Validierung wie TPPGDBMemo
    (gemeinsame Anbindung TPPGDBBinding in PPG.DB.Controls).
  - Eigene Unit (nicht in PPG.DB.Controls), damit Anwendungen ohne
    Rich-Text nichts davon linken. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, Vcl.Controls,
  Data.DB, PPG.RichEdit, PPG.DB.Controls;

type
  TPPGDBRichEdit = class(TPPGRichEdit)
  private
    FBinding: TPPGDBBinding;
    FAutoDisplay: Boolean;
    FMemoLoaded: Boolean;
    function GetShowRequired: Boolean;
    procedure SetShowRequired(const Value: Boolean);
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
    function PlainLinesText: string;
    procedure LoadFromField(F: TField);
    procedure SaveToField(F: TField);
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
    /// Laedt ein BLOB-Feld, wenn AutoDisplay = False ist.
    procedure LoadMemo;
    function ExecuteAction(Action: TBasicAction): Boolean; override;
    function UpdateAction(Action: TBasicAction): Boolean; override;
    property Field: TField read GetField;
  published
    /// Pflichtfelder mit einem Sternchen kennzeichnen.
    property ShowRequired: Boolean read GetShowRequired write SetShowRequired default False;
    /// False: BLOB-Felder erst bei Doppelklick bzw. Enter laden (wie TDBRichEdit).
    property AutoDisplay: Boolean read FAutoDisplay write SetAutoDisplay default True;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property Lines stored False;
  end;

implementation

const
  RtfSignature = '{\rtf';
  UrtfSignature = '{\urtf';

/// True, wenn die Bytes mit {\rtf oder {\urtf beginnen.
function LooksLikeRtf(const Bytes: TBytes): Boolean;

  function StartsWith(const Sig: string): Boolean;
  var
    I: Integer;
  begin
    Result := Length(Bytes) >= Length(Sig);
    if Result then
      for I := 1 to Length(Sig) do
        if Bytes[I - 1] <> Ord(Sig[I]) then
          Exit(False);
  end;

begin
  Result := StartsWith(RtfSignature) or StartsWith(UrtfSignature);
end;

function AsciiBytes(const S: string): TBytes;
var
  I: Integer;
begin
  // RTF ist reiner ASCII-Text (Nicht-ASCII steht als \'xx bzw. \uN)
  SetLength(Result, Length(S));
  for I := 1 to Length(S) do
    if Ord(S[I]) < 256 then
      Result[I - 1] := Byte(Ord(S[I]))
    else
      Result[I - 1] := Ord('?');
end;

function BytesToAnsiString(const B: TBytes): string;
var
  I: Integer;
begin
  SetLength(Result, Length(B));
  for I := 0 to High(B) do
    Result[I + 1] := Char(B[I]);
end;

{ TPPGDBRichEdit }

constructor TPPGDBRichEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoDisplay := True;
  FBinding := TPPGDBBinding.Create(Self);
  FBinding.OnShow := ShowField;
  FBinding.OnWrite := WriteField;
  FBinding.OnEditable := MemoEditable;
  FBinding.UpdateEditable;
end;

destructor TPPGDBRichEdit.Destroy;
begin
  FreeAndNil(FBinding);
  inherited Destroy;
end;

procedure TPPGDBRichEdit.Loaded;
begin
  inherited Loaded;
  if csDesigning in ComponentState then
    FBinding.Reload;
end;

procedure TPPGDBRichEdit.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if FBinding <> nil then
    FBinding.Notify(AComponent, Operation);
end;

function TPPGDBRichEdit.GetShowRequired: Boolean;
begin
  Result := FBinding.ShowRequired;
end;

procedure TPPGDBRichEdit.SetShowRequired(const Value: Boolean);
begin
  FBinding.ShowRequired := Value;
end;

function TPPGDBRichEdit.GetDataField: string;
begin
  Result := FBinding.DataField;
end;

procedure TPPGDBRichEdit.SetDataField(const Value: string);
begin
  FBinding.DataField := Value;
end;

function TPPGDBRichEdit.GetDataSource: TDataSource;
begin
  Result := FBinding.DataSource;
end;

procedure TPPGDBRichEdit.SetDataSource(Value: TDataSource);
begin
  FBinding.DataSource := Value;
end;

function TPPGDBRichEdit.GetField: TField;
begin
  Result := FBinding.Field;
end;

function TPPGDBRichEdit.GetReadOnly: Boolean;
begin
  Result := FBinding.ReadOnly;
end;

procedure TPPGDBRichEdit.SetReadOnly(const Value: Boolean);
begin
  FBinding.ReadOnly := Value;
end;

procedure TPPGDBRichEdit.SetAutoDisplay(const Value: Boolean);
begin
  if FAutoDisplay <> Value then
  begin
    FAutoDisplay := Value;
    if Value then
      LoadMemo;
  end;
end;

procedure TPPGDBRichEdit.MemoEditable(Sender: TObject);
begin
  inherited ReadOnly := not FBinding.CanModify or not FMemoLoaded;
end;

function TPPGDBRichEdit.PlainLinesText: string;
begin
  // TStrings.Text haengt hinter die letzte Zeile einen Zeilenumbruch
  Result := Lines.Text;
  if Copy(Result, Length(Result) - Length(sLineBreak) + 1, Length(sLineBreak)) = sLineBreak then
    SetLength(Result, Length(Result) - Length(sLineBreak));
end;

procedure TPPGDBRichEdit.LoadFromField(F: TField);
var
  Stream: TMemoryStream;
  Bytes: TBytes;
begin
  if F.IsNull then
  begin
    Lines.Clear;
    Exit;
  end;
  if PlainText or not F.IsBlob then
  begin
    // reiner Text
    Lines.Text := F.AsString;
    Exit;
  end;
  Stream := TMemoryStream.Create;
  try
    if F.DataType = ftWideMemo then
    begin
      Bytes := AsciiBytes(F.AsString);
      if Length(Bytes) > 0 then
        Stream.WriteBuffer(Bytes[0], Length(Bytes));
    end
    else
      TBlobField(F).SaveToStream(Stream);
    SetLength(Bytes, Integer(Stream.Size));
    if Stream.Size > 0 then
      Move(Stream.Memory^, Bytes[0], Integer(Stream.Size));
    Stream.Position := 0;
    if LooksLikeRtf(Bytes) then
      Lines.LoadFromStream(Stream)
    else
      // Altbestand ohne RTF: unformatiert anzeigen
      Lines.Text := F.AsString;
  finally
    Stream.Free;
  end;
end;

procedure TPPGDBRichEdit.SaveToField(F: TField);
var
  Stream: TMemoryStream;
  Bytes: TBytes;
begin
  if PlainText or not F.IsBlob then
  begin
    if F.IsBlob then
      F.AsString := PlainLinesText
    else
      F.Text := PlainLinesText;
    Exit;
  end;
  Stream := TMemoryStream.Create;
  try
    Lines.SaveToStream(Stream);
    if F.DataType = ftWideMemo then
    begin
      SetLength(Bytes, Integer(Stream.Size));
      if Stream.Size > 0 then
        Move(Stream.Memory^, Bytes[0], Integer(Stream.Size));
      F.AsString := BytesToAnsiString(Bytes);
    end
    else
    begin
      Stream.Position := 0;
      TBlobField(F).LoadFromStream(Stream);
    end;
  finally
    Stream.Free;
  end;
end;

procedure TPPGDBRichEdit.LoadMemo;
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
    LoadFromField(F);
    Modified := False;
  finally
    FBinding.Setting := False;
  end;
  FMemoLoaded := True;
  FBinding.UpdateEditable;
end;

procedure TPPGDBRichEdit.ShowField(Sender: TObject);
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
        LoadFromField(F);
        FMemoLoaded := True;
      end
      else
        Lines.Text := '(' + F.DisplayLabel + ')';
    end
    else
    begin
      if FieldFocused and FBinding.CanModify then
        Lines.Text := F.Text
      else
        Lines.Text := F.DisplayText;
      FMemoLoaded := True;
    end;
  end
  else if csDesigning in ComponentState then
    Lines.Text := Name
  else
    Lines.Clear;
  Modified := False;
end;

procedure TPPGDBRichEdit.WriteField(Sender: TObject);
begin
  SaveToField(FBinding.Field);
end;

procedure TPPGDBRichEdit.Change;
begin
  if (FBinding = nil) or FBinding.UserChange then
    inherited Change;
end;

procedure TPPGDBRichEdit.DblClick;
begin
  if not FMemoLoaded then
    LoadMemo
  else
    inherited DblClick;
end;

procedure TPPGDBRichEdit.FieldKeyDown(var Key: Word; Shift: TShiftState);
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

function TPPGDBRichEdit.WantSpecialKey(Key: Word): Boolean;
begin
  Result := ((Key = VK_ESCAPE) and FBinding.WantsEscape) or inherited WantSpecialKey(Key);
end;

procedure TPPGDBRichEdit.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := LRESULT(FBinding.Link);
end;

procedure TPPGDBRichEdit.CMExit(var Message: TCMExit);
begin
  // Im Destruktor ist FBinding schon frei; der Fokusverlust beim
  // Zerstoeren des Fensters schickt trotzdem noch CM_EXIT
  if FBinding = nil then
  begin
    inherited;
    Exit;
  end;
  FBinding.Commit;
  inherited;
end;

function TPPGDBRichEdit.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or ((FBinding <> nil) and FBinding.ExecuteAction(Action));
end;

function TPPGDBRichEdit.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or ((FBinding <> nil) and FBinding.UpdateAction(Action));
end;

end.
