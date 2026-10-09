unit PPG.Tests.Audit45;

{ Tests fuer die Audit-Pakete 4 und 5 (Docs\Audit-Paket4-5-Plan.md).
  4a: festhaltende Tests fuer alle 11 DB-Controls vor dem Umbau auf die
  gemeinsame Bindung (Anzeigen, Anwender-Aenderung, nicht aenderbar, Esc,
  Verlassen, CM_GETDATALINK, freigegebene DataSource, Actions). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Variants, System.TypInfo, System.Generics.Collections, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.Graphics,
  Vcl.DBActns, Vcl.DBCtrls, Data.DB, Data.DBConsts, Datasnap.DBClient, MidasLib,
  PPG.Types, PPG.Controls.Field, PPG.DB.Controls, PPG.DB.Lookup, PPG.DB.Fields,
  PPG.DB.Navigator, PPG.DB.Kanban, PPG.DB.Grid, PPG.Exceptions, PPG.Tests.Controls;

type
  TDBBindSpec = record
    Name: string;
    FieldName: string;
    Make: TFunc<TControl>;
    Shown: TFunc<TControl, string>;
    UserEdit: TProc<TControl>;
    /// nil = das Control kennt heute kein Esc
    Escape: TProc<TControl>;
    Rec1, Rec2, Written: string;
    HasActions: Boolean;
  end;

  TDBBindingHoldTests = class(TControlTestCase)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    FOrte: TClientDataSet;
    FOrtSrc: TDataSource;
    procedure FillData;
    function Specs: TArray<TDBBindSpec>;
    function Spec(const AName: string): TDBBindSpec;
    procedure Bind(C: TControl; const AField: string);
    procedure CheckShowsAndFollows(const S: TDBBindSpec);
    procedure CheckUserEditPosts(const S: TDBBindSpec);
    procedure CheckReadOnlyFieldReverts(const S: TDBBindSpec);
    procedure CheckReadOnlyPropReverts(const S: TDBBindSpec);
    procedure CheckEscapeResets(const S: TDBBindSpec);
    procedure CheckExitWrites(const S: TDBBindSpec);
    procedure CheckLinkAndActions(const S: TDBBindSpec);
    procedure CheckSourceFreed(const S: TDBBindSpec);
    procedure RunAll(const AName: string);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure DBEdit;
    procedure DBMemo;
    procedure DBCheckBox;
    procedure DBComboBox;
    procedure DBDatePicker;
    procedure DBMaskEdit;
    procedure DBNumberEdit;
    procedure DBColorPicker;
    procedure DBCheckComboBox;
    procedure DBTagEdit;
    procedure DBRadioGroup;
    procedure DBLookupComboBox;
  end;

  /// Audit 09.10.2026, Paket 4b: Fehler und Luecken der DB-Controls.
  TDBFixTests = class(TControlTestCase)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
  protected
    procedure SetUp; override;
  published
    procedure EditTakesMaxLengthFromField;
    procedure DatePickerNullIsEmpty;
    procedure ComboLockedWhenFieldReadOnly;
    procedure LookupEditableAfterBinding;
    procedure DBKanbanPublishesMissingMembers;
    procedure ExportMaxRecordsChecked;
  end;

implementation

type
  TFieldCrack = class(TPPGCustomField);
  TWinCrack = class(TWinControl);
  TComboCrack = class(TPPGDBComboBox)
  public
    function ReadOnlyOfField: Boolean;
  end;
  TDateCrack = class(TPPGDBDatePicker);
  TRadioCrack = class(TPPGDBRadioGroup);

function TComboCrack.ReadOnlyOfField: Boolean;
begin
  Result := TFieldCrack(Self).ReadOnly;
end;

{ TDBBindingHoldTests }

procedure TDBBindingHoldTests.SetUp;
begin
  inherited SetUp;
  FData := TClientDataSet.Create(FForm);
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
  FOrte := TClientDataSet.Create(FForm);
  FOrtSrc := TDataSource.Create(FForm);
  FOrtSrc.DataSet := FOrte;
  FillData;
  FForm.Show;
end;

procedure TDBBindingHoldTests.TearDown;
begin
  FForm.Hide;
  FSource := nil;
  FData := nil;
  inherited TearDown;
end;

procedure TDBBindingHoldTests.FillData;
begin
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Name', ftString, 20);
  FData.FieldDefs.Add('Aktiv', ftBoolean);
  FData.FieldDefs.Add('Geboren', ftDate);
  FData.FieldDefs.Add('Notiz', ftMemo);
  FData.FieldDefs.Add('Preis', ftFloat);
  FData.FieldDefs.Add('OrtID', ftInteger);
  FData.FieldDefs.Add('Farbe', ftInteger);
  FData.FieldDefs.Add('Kat', ftString, 40);
  FData.FieldDefs.Add('Tags', ftString, 40);
  FData.CreateDataSet;
  FData.AppendRecord([1, 'Name1', True, EncodeDate(2000, 1, 2), 'Notiz 1', 1.5, 2,
    Integer(clRed), 'Rot;Blau', 'a;b']);
  FData.AppendRecord([2, 'Name2', False, EncodeDate(2000, 1, 3), 'Notiz 2', 3.0, 3,
    Integer(clBlue), 'Gruen', 'c']);
  FData.First;
  FOrte.FieldDefs.Add('ID', ftInteger);
  FOrte.FieldDefs.Add('Ort', ftString, 20);
  FOrte.CreateDataSet;
  FOrte.AppendRecord([1, 'Berlin']);
  FOrte.AppendRecord([2, 'Hamburg']);
  FOrte.AppendRecord([3, 'Koeln']);
end;

procedure TDBBindingHoldTests.Bind(C: TControl; const AField: string);
begin
  C.Parent := FForm;
  C.SetBounds(10, 10, 220, 32);
  SetObjectProp(C, 'DataSource', FSource);
  SetStrProp(C, 'DataField', AField);
end;

procedure FieldEsc(C: TControl);
var
  K: Word;
begin
  K := VK_ESCAPE;
  TFieldCrack(C).FieldKeyDown(K, []);
end;

procedure WinEsc(C: TControl);
var
  K: Word;
begin
  K := VK_ESCAPE;
  TWinCrack(C).KeyDown(K, []);
end;

function TDBBindingHoldTests.Specs: TArray<TDBBindSpec>;
var
  S: TDBBindSpec;
  L: TList<TDBBindSpec>;
  Self_: TDBBindingHoldTests;
begin
  Self_ := Self;
  L := TList<TDBBindSpec>.Create;
  try
    S := Default(TDBBindSpec);
    S.Name := 'Edit'; S.FieldName := 'Name';
    S.Make := function: TControl begin Result := TPPGDBEdit.Create(Self_.FForm) end;
    S.Shown := function(C: TControl): string begin Result := TPPGDBEdit(C).Text end;
    S.UserEdit := procedure(C: TControl) begin TPPGDBEdit(C).Text := 'Neu' end;
    S.Escape := FieldEsc;
    S.Rec1 := 'Name1'; S.Rec2 := 'Name2'; S.Written := 'Neu'; S.HasActions := True;
    L.Add(S);

    S := Default(TDBBindSpec);
    S.Name := 'Memo'; S.FieldName := 'Notiz';
    S.Make := function: TControl begin Result := TPPGDBMemo.Create(Self_.FForm) end;
    S.Shown := function(C: TControl): string begin Result := Trim(TPPGDBMemo(C).Text) end;
    S.UserEdit := procedure(C: TControl) begin TPPGDBMemo(C).Text := 'Neu' end;
    S.Escape := FieldEsc;
    S.Rec1 := 'Notiz 1'; S.Rec2 := 'Notiz 2'; S.Written := 'Neu'; S.HasActions := True;
    L.Add(S);

    S := Default(TDBBindSpec);
    S.Name := 'CheckBox'; S.FieldName := 'Aktiv';
    S.Make := function: TControl begin Result := TPPGDBCheckBox.Create(Self_.FForm) end;
    S.Shown := function(C: TControl): string begin Result := IntToStr(Ord(TPPGDBCheckBox(C).State)) end;
    S.UserEdit := procedure(C: TControl) begin TPPGDBCheckBox(C).Click end;
    S.Escape := WinEsc;
    S.Rec1 := IntToStr(Ord(cbChecked)); S.Rec2 := IntToStr(Ord(cbUnchecked));
    S.Written := STextFalse; S.HasActions := True;
    L.Add(S);

    S := Default(TDBBindSpec);
    S.Name := 'ComboBox'; S.FieldName := 'Name';
    S.Make := function: TControl
      var
        C: TPPGDBComboBox;
      begin
        C := TPPGDBComboBox.Create(Self_.FForm);
        C.Style := csDropDownList;
        C.Items.CommaText := 'Name1,Name2,Anders';
        Result := C;
      end;
    S.Shown := function(C: TControl): string begin Result := TPPGDBComboBox(C).Text end;
    S.UserEdit := procedure(C: TControl) begin TComboCrack(C).SelectIndex(2) end;
    S.Escape := FieldEsc;
    S.Rec1 := 'Name1'; S.Rec2 := 'Name2'; S.Written := 'Anders'; S.HasActions := True;
    L.Add(S);

    S := Default(TDBBindSpec);
    S.Name := 'DatePicker'; S.FieldName := 'Geboren';
    S.Make := function: TControl begin Result := TPPGDBDatePicker.Create(Self_.FForm) end;
    S.Shown := function(C: TControl): string begin Result := DateToStr(TPPGDBDatePicker(C).Date) end;
    S.UserEdit := procedure(C: TControl) begin TDateCrack(C).UserSetDate(EncodeDate(2024, 2, 29)) end;
    S.Escape := FieldEsc;
    S.Rec1 := DateToStr(EncodeDate(2000, 1, 2)); S.Rec2 := DateToStr(EncodeDate(2000, 1, 3));
    S.Written := DateToStr(EncodeDate(2024, 2, 29)); S.HasActions := True;
    L.Add(S);

    S := Default(TDBBindSpec);
    S.Name := 'MaskEdit'; S.FieldName := 'Name';
    S.Make := function: TControl begin Result := TPPGDBMaskEdit.Create(Self_.FForm) end;
    S.Shown := function(C: TControl): string begin Result := TPPGDBMaskEdit(C).Text end;
    S.UserEdit := procedure(C: TControl) begin TPPGDBMaskEdit(C).Text := 'Neu' end;
    S.Escape := FieldEsc;
    S.Rec1 := 'Name1'; S.Rec2 := 'Name2'; S.Written := 'Neu'; S.HasActions := True;
    L.Add(S);

    S := Default(TDBBindSpec);
    S.Name := 'NumberEdit'; S.FieldName := 'Preis';
    S.Make := function: TControl begin Result := TPPGDBNumberEdit.Create(Self_.FForm) end;
    S.Shown := function(C: TControl): string begin Result := FloatToStr(TPPGDBNumberEdit(C).Value) end;
    S.UserEdit := procedure(C: TControl)
      begin
        // Tippen wie der Anwender (Value im Code ist still)
        TPPGDBNumberEdit(C).SetFocus;
        TPPGDBNumberEdit(C).SelectAll;
        TPPGDBNumberEdit(C).SelText := '';
        TWinControl(C).Controls[0].Perform(WM_CHAR, Ord('7'), 0);
      end;
    S.Rec1 := FloatToStr(1.5); S.Rec2 := FloatToStr(3.0); S.Written := FloatToStr(7); S.HasActions := True;
    L.Add(S);

    S := Default(TDBBindSpec);
    S.Name := 'ColorPicker'; S.FieldName := 'Farbe';
    S.Make := function: TControl begin Result := TPPGDBColorPicker.Create(Self_.FForm) end;
    S.Shown := function(C: TControl): string begin Result := IntToStr(TPPGDBColorPicker(C).Selected) end;
    S.UserEdit := procedure(C: TControl) begin TPPGDBColorPicker(C).SelectColor(clGreen) end;
    S.Escape := FieldEsc;
    S.Rec1 := IntToStr(clRed); S.Rec2 := IntToStr(clBlue); S.Written := IntToStr(clGreen); S.HasActions := True;
    L.Add(S);

    S := Default(TDBBindSpec);
    S.Name := 'CheckComboBox'; S.FieldName := 'Kat';
    S.Make := function: TControl
      var
        C: TPPGDBCheckComboBox;
      begin
        C := TPPGDBCheckComboBox.Create(Self_.FForm);
        C.Items.CommaText := 'Rot,Gruen,Blau';
        Result := C;
      end;
    S.Shown := function(C: TControl): string begin Result := TPPGDBCheckComboBox(C).CheckedText end;
    S.UserEdit := procedure(C: TControl) begin TPPGDBCheckComboBox(C).ToggleItem(1) end;
    S.Escape := FieldEsc;
    S.Rec1 := 'Rot;Blau'; S.Rec2 := 'Gruen'; S.Written := 'Rot;Gruen;Blau'; S.HasActions := True;
    L.Add(S);

    S := Default(TDBBindSpec);
    S.Name := 'TagEdit'; S.FieldName := 'Tags';
    S.Make := function: TControl begin Result := TPPGDBTagEdit.Create(Self_.FForm) end;
    S.Shown := function(C: TControl): string begin Result := TPPGDBTagEdit(C).TagsText end;
    S.UserEdit := procedure(C: TControl) begin TPPGDBTagEdit(C).AddTag('z') end;
    S.Escape := FieldEsc;
    S.Rec1 := 'a;b'; S.Rec2 := 'c'; S.Written := 'a;b;z'; S.HasActions := True;
    L.Add(S);

    S := Default(TDBBindSpec);
    S.Name := 'RadioGroup'; S.FieldName := 'Name';
    S.Make := function: TControl
      var
        C: TPPGDBRadioGroup;
      begin
        C := TPPGDBRadioGroup.Create(Self_.FForm);
        C.Items.CommaText := 'Name1,Name2,Anders';
        Result := C;
      end;
    S.Shown := function(C: TControl): string
      begin
        if TPPGDBRadioGroup(C).ItemIndex >= 0 then
          Result := TPPGDBRadioGroup(C).Items[TPPGDBRadioGroup(C).ItemIndex]
        else
          Result := '';
      end;
    S.UserEdit := procedure(C: TControl) begin TRadioCrack(C).ActivateItem(2) end;
    S.Escape := WinEsc;
    S.Rec1 := 'Name1'; S.Rec2 := 'Name2'; S.Written := 'Anders'; S.HasActions := True;
    L.Add(S);

    S := Default(TDBBindSpec);
    S.Name := 'LookupComboBox'; S.FieldName := 'OrtID';
    S.Make := function: TControl
      var
        C: TPPGDBLookupComboBox;
      begin
        C := TPPGDBLookupComboBox.Create(Self_.FForm);
        C.ListSource := Self_.FOrtSrc;
        C.KeyField := 'ID';
        C.ListField := 'Ort';
        Result := C;
      end;
    S.Shown := function(C: TControl): string begin Result := TPPGDBLookupComboBox(C).Text end;
    S.UserEdit := procedure(C: TControl) begin TComboCrack(C).SelectIndex(0) end;
    S.Escape := FieldEsc;
    S.Rec1 := 'Hamburg'; S.Rec2 := 'Koeln'; S.Written := '1'; S.HasActions := True;
    L.Add(S);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TDBBindingHoldTests.Spec(const AName: string): TDBBindSpec;
var
  S: TDBBindSpec;
begin
  for S in Specs do
    if S.Name = AName then
      Exit(S);
  raise Exception.Create('Spec fehlt: ' + AName);
end;

procedure TDBBindingHoldTests.CheckShowsAndFollows(const S: TDBBindSpec);
var
  C: TControl;
begin
  FData.First;
  C := S.Make();
  Bind(C, S.FieldName);
  CheckEquals(S.Rec1, S.Shown(C), S.Name + ': Datensatz 1');
  FData.Next;
  CheckEquals(S.Rec2, S.Shown(C), S.Name + ': folgt dem Datensatz');
  CheckTrue(FData.State = dsBrowse, S.Name + ': Anzeigen bearbeitet nicht');
  C.Free;
end;

procedure TDBBindingHoldTests.CheckUserEditPosts(const S: TDBBindSpec);
var
  C: TControl;
  Old: Variant;
begin
  FData.First;
  Old := FData.FieldByName(S.FieldName).Value;
  C := S.Make();
  Bind(C, S.FieldName);
  S.UserEdit(C);
  CheckTrue(FData.State = dsEdit, S.Name + ': Bearbeiten-Modus');
  FData.Post;
  CheckEquals(S.Written, FData.FieldByName(S.FieldName).AsString, S.Name + ': geschrieben');
  C.Free;
  // Datensatz 1 fuer die folgenden Pruefungen wiederherstellen
  FData.Edit;
  FData.FieldByName(S.FieldName).Value := Old;
  FData.Post;
end;

procedure TDBBindingHoldTests.CheckReadOnlyFieldReverts(const S: TDBBindSpec);
var
  C: TControl;
begin
  FData.First;
  C := S.Make();
  Bind(C, S.FieldName);
  FData.FieldByName(S.FieldName).ReadOnly := True;
  try
    S.UserEdit(C);
    CheckTrue(FData.State = dsBrowse, S.Name + ': nicht aenderbar, kein Bearbeiten');
    CheckEquals(S.Rec1, S.Shown(C), S.Name + ': alter Wert wieder angezeigt');
  finally
    FData.FieldByName(S.FieldName).ReadOnly := False;
    C.Free;
  end;
end;

procedure TDBBindingHoldTests.CheckReadOnlyPropReverts(const S: TDBBindSpec);
var
  C: TControl;
begin
  FData.First;
  C := S.Make();
  Bind(C, S.FieldName);
  SetOrdProp(C, 'ReadOnly', Ord(True));
  CheckEquals(Ord(True), GetOrdProp(C, 'ReadOnly'), S.Name + ': ReadOnly lesbar');
  S.UserEdit(C);
  CheckTrue(FData.State = dsBrowse, S.Name + ': ReadOnly, kein Bearbeiten');
  CheckEquals(S.Rec1, S.Shown(C), S.Name + ': ReadOnly, alter Wert');
  SetOrdProp(C, 'ReadOnly', Ord(False));
  C.Free;
end;

procedure TDBBindingHoldTests.CheckEscapeResets(const S: TDBBindSpec);
var
  C: TControl;
begin
  if not Assigned(S.Escape) then
    Exit;
  FData.First;
  C := S.Make();
  Bind(C, S.FieldName);
  S.UserEdit(C);
  CheckTrue(FData.State = dsEdit);
  S.Escape(C);
  CheckEquals(S.Rec1, S.Shown(C), S.Name + ': Esc setzt zurueck');
  FData.Cancel;
  C.Free;
end;

procedure TDBBindingHoldTests.CheckExitWrites(const S: TDBBindSpec);
var
  C: TControl;
begin
  FData.First;
  C := S.Make();
  Bind(C, S.FieldName);
  S.UserEdit(C);
  TWinControl(C).Perform(CM_EXIT, 0, 0);
  CheckEquals(S.Written, FData.FieldByName(S.FieldName).AsString, S.Name + ': Verlassen schreibt');
  FData.Cancel;
  C.Free;
end;

procedure TDBBindingHoldTests.CheckLinkAndActions(const S: TDBBindSpec);
var
  C: TControl;
  L: TObject;
  A: TDataSetFirst;
begin
  FData.First;
  C := S.Make();
  Bind(C, S.FieldName);
  L := TObject(TWinControl(C).Perform(CM_GETDATALINK, 0, 0));
  CheckTrue(L is TFieldDataLink, S.Name + ': CM_GETDATALINK');
  CheckTrue(TFieldDataLink(L).DataSource = FSource);
  CheckEquals(S.FieldName, TFieldDataLink(L).FieldName);
  if S.HasActions then
  begin
    A := TDataSetFirst.Create(nil);
    try
      CheckTrue(C.UpdateAction(A), S.Name + ': UpdateAction an den Link');
    finally
      A.Free;
    end;
  end;
  C.Free;
end;

procedure TDBBindingHoldTests.CheckSourceFreed(const S: TDBBindSpec);
var
  C: TControl;
begin
  FData.First;
  C := S.Make();
  Bind(C, S.FieldName);
  FreeAndNil(FSource);
  CheckNull(GetObjectProp(C, 'DataSource'), S.Name + ': FreeNotification');
  C.Free;
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
end;

procedure TDBBindingHoldTests.RunAll(const AName: string);
var
  S: TDBBindSpec;
begin
  S := Spec(AName);
  CheckShowsAndFollows(S);
  CheckUserEditPosts(S);
  CheckReadOnlyFieldReverts(S);
  CheckReadOnlyPropReverts(S);
  CheckEscapeResets(S);
  CheckExitWrites(S);
  CheckLinkAndActions(S);
  CheckSourceFreed(S);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TDBBindingHoldTests.DBEdit; begin RunAll('Edit'); end;
procedure TDBBindingHoldTests.DBMemo; begin RunAll('Memo'); end;
procedure TDBBindingHoldTests.DBCheckBox; begin RunAll('CheckBox'); end;
procedure TDBBindingHoldTests.DBComboBox; begin RunAll('ComboBox'); end;
procedure TDBBindingHoldTests.DBDatePicker; begin RunAll('DatePicker'); end;
procedure TDBBindingHoldTests.DBMaskEdit; begin RunAll('MaskEdit'); end;
procedure TDBBindingHoldTests.DBNumberEdit; begin RunAll('NumberEdit'); end;
procedure TDBBindingHoldTests.DBColorPicker; begin RunAll('ColorPicker'); end;
procedure TDBBindingHoldTests.DBCheckComboBox; begin RunAll('CheckComboBox'); end;
procedure TDBBindingHoldTests.DBTagEdit; begin RunAll('TagEdit'); end;
procedure TDBBindingHoldTests.DBRadioGroup; begin RunAll('RadioGroup'); end;
procedure TDBBindingHoldTests.DBLookupComboBox; begin RunAll('LookupComboBox'); end;

{ TDBFixTests }

procedure TDBFixTests.SetUp;
begin
  inherited SetUp;
  FData := TClientDataSet.Create(FForm);
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Name', ftString, 12);
  FData.FieldDefs.Add('Geboren', ftDate);
  FData.FieldDefs.Add('OrtID', ftInteger);
  FData.CreateDataSet;
  FData.AppendRecord([1, 'Name1', EncodeDate(2000, 1, 2), 2]);
  FData.AppendRecord([2, 'Name2', Null, 3]);
  FData.First;
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
  FForm.Show;
end;

procedure TDBFixTests.EditTakesMaxLengthFromField;
var
  E: TPPGDBEdit;
begin
  E := TPPGDBEdit.Create(FForm);
  E.Parent := FForm;
  E.DataSource := FSource;
  E.DataField := 'Name';
  CheckEquals(12, E.MaxLength, 'Laenge des Textfelds');
  E.DataField := 'ID';
  CheckEquals(0, E.MaxLength, 'Zahlfeld: keine Grenze');
  E.MaxLength := 5;
  E.DataField := 'Name';
  CheckEquals(5, E.MaxLength, 'eigene Laenge hat Vorrang');
end;

procedure TDBFixTests.DatePickerNullIsEmpty;
var
  D: TPPGDBDatePicker;
begin
  D := TPPGDBDatePicker.Create(FForm);
  D.Parent := FForm;
  D.DataSource := FSource;
  D.DataField := 'Geboren';
  CheckEquals(EncodeDate(2000, 1, 2), D.Date);
  FData.Next;
  CheckEquals(0, D.DateTime, 'Null ohne Kaestchen: leer statt altem Datum');
  CheckEquals('', D.Text);
  FData.Edit;
  FData.FieldByName('Geboren').AsDateTime := EncodeDate(2001, 5, 6);
  FData.Post;
  D.Perform(CM_EXIT, 0, 0);
  FData.Edit;
  FData.FieldByName('Geboren').Clear;
  FData.Post;
  CheckEquals(0, D.DateTime);
  // Leeres Feld schreibt Null
  FData.Edit;
  D.Perform(CM_EXIT, 0, 0);
  CheckTrue(FData.FieldByName('Geboren').IsNull, 'leer bleibt Null');
  FData.Cancel;
end;

procedure TDBFixTests.ComboLockedWhenFieldReadOnly;
var
  C: TPPGDBComboBox;
  K: Word;
  Ch: Char;
begin
  C := TPPGDBComboBox.Create(FForm);
  C.Parent := FForm;
  C.Style := csDropDownList;
  C.Items.CommaText := 'Name1,Name2,Anders';
  C.DataSource := FSource;
  C.DataField := 'Name';
  FData.FieldByName('Name').ReadOnly := True;
  try
    FData.Next;
    FData.Prior;
    C.DropDown;
    CheckFalse(C.DroppedDown, 'nicht aenderbar: klappt nicht auf');
    K := VK_DOWN;
    TComboCrack(C).FieldKeyDown(K, []);
    CheckEquals(0, C.ItemIndex, 'Pfeil waehlt nicht');
    Ch := 'A';
    TComboCrack(C).FieldKeyPress(Ch);
    CheckEquals(0, C.ItemIndex, 'Tippsuche waehlt nicht');
    CheckTrue(FData.State = dsBrowse);
  finally
    FData.FieldByName('Name').ReadOnly := False;
  end;
  C.DropDown;
  CheckTrue(C.DroppedDown, 'aenderbar: klappt auf');
  C.CloseUp(False);
end;

procedure TDBFixTests.LookupEditableAfterBinding;
var
  Orte: TClientDataSet;
  OrtSrc: TDataSource;
  L: TPPGDBLookupComboBox;
begin
  Orte := TClientDataSet.Create(FForm);
  Orte.FieldDefs.Add('ID', ftInteger);
  Orte.FieldDefs.Add('Ort', ftString, 20);
  Orte.CreateDataSet;
  Orte.AppendRecord([2, 'Hamburg']);
  Orte.AppendRecord([3, 'Koeln']);
  OrtSrc := TDataSource.Create(FForm);
  OrtSrc.DataSet := Orte;
  L := TPPGDBLookupComboBox.Create(FForm);
  L.Parent := FForm;
  L.ListSource := OrtSrc;
  L.KeyField := 'ID';
  L.ListField := 'Ort';
  L.DataSource := FSource;
  L.DataField := 'OrtID';
  // Audit 4b: ReadOnly blieb bis zum ersten Bearbeiten True
  CheckFalse(TComboCrack(L).ReadOnlyOfField, 'aenderbar gleich nach dem Binden');
  CheckEquals('Hamburg', L.Text);
end;

procedure TDBFixTests.DBKanbanPublishesMissingMembers;
begin
  CheckTrue(IsPublishedProp(TPPGDBKanban, 'VirtualCardHeight'));
  CheckTrue(IsPublishedProp(TPPGDBKanban, 'OnKeyDown'));
  CheckTrue(IsPublishedProp(TPPGDBKanban, 'OnScroll'));
end;

procedure TDBFixTests.ExportMaxRecordsChecked;
var
  G: TPPGDBGrid;
  Raised: Boolean;
begin
  G := TPPGDBGrid.Create(FForm);
  Raised := False;
  try
    G.ExportMaxRecords := 0;
  except
    on EPPGPropertyError do
      Raised := True;
  end;
  CheckTrue(Raised, '0 Saetze ist kein gueltiger Wert');
  CheckEquals(100000, G.ExportMaxRecords, 'unveraendert');
  G.ExportMaxRecords := 50;
  CheckEquals(50, G.ExportMaxRecords);
end;

initialization
  RegisterTest('Audit45', TDBBindingHoldTests.Suite);
  RegisterTest('Audit45', TDBFixTests.Suite);

end.
