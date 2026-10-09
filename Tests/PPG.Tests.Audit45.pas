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
  PPG.DB.Navigator, PPG.DB.Kanban, PPG.DB.Grid, PPG.DB.Chart, PPG.Exceptions, PPG.ErrorHandler,
  PPG.NumberFormat, PPG.Grid, Vcl.Menus, Vcl.ExtCtrls, PPG.CheckComboBox, PPG.TagEdit, PPG.Grid.Print,
  PPG.PasswordEdit, PPG.Expander, PPG.ComboBox, PPG.TrackBar, PPG.ProgressBar, PPG.Hints,
  PPG.ToolBar, PPG.Ribbon, PPG.Notifications, PPG.Menus, PPG.StatusBar, PPG.NavigationView,
  PPG.FileEdit, PPG.Feedback, PPG.Kanban, PPG.Kanban.Items, PPG.Labels, PPG.PageControl,
  PPG.ColumnComboBox, PPG.Panel, PPG.Tests.Controls;

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

  /// Audit 09.10.2026, Paket 4b/4c: Nachschlagen, Zahlen, Grid, Diagramm.
  TDBFix2Tests = class(TControlTestCase)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    FOrte: TClientDataSet;
    FWarnings: TStringList;
    procedure Build(WithLookupField: Boolean);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure NumberEditKindFromField;
    procedure LookupFieldAsDataField;
    procedure LookupMultiKeyWarns;
    procedure LookupNullValueKey;
    procedure LookupListFollowsChanges;
    procedure GridLookupColumnPicksKey;
    procedure GridEditsOnFirstKey;
    procedure GridPersistentColumnTakesFieldAlignment;
    procedure ChartSkipsNullAndJumpsByBookmark;
    procedure ChartDoesNotStoreBoundData;
    procedure ShowRequiredMarksFieldAndTitle;
  end;

  /// Audit 09.10.2026, Paket 5a: Streaming.
  TStreamingFixTests = class(TControlTestCase)
  private
    function DfmOf(C: TComponent): string;
  published
    procedure EmptyDelimitersAreStored;
    procedure PrintFooterDefaultNotStored;
    procedure PasswordTextNotStored;
    procedure ExpandedHeightOnlyWhenNeeded;
    procedure ComboItemsNotTwiceWithItemsEx;
    procedure MinZeroNotStored;
    procedure HintManagerWaitsForLoaded;
    procedure GroupIndexReadBeforeDown;
    procedure RibbonBackstageHiddenAfterLoad;
    procedure PresetCheckedOnComponents;
  end;

  /// Audit 09.10.2026, Paket 5b: Setter und Zustand.
  TSetterFixTests = class(TControlTestCase)
  private
    FSelChanges: Integer;
    procedure SelChange(Sender: TObject);
    procedure CheckRejects(const What: string; Proc: TProc);
  published
    procedure SilentClampsNowRejected;
    procedure KanbanSelectedCardScrollsWithoutEvent;
    procedure InfoBarVisibleIsOpen;
    procedure LinkLabelKeepsOwnCursor;
    procedure NavItemPageIndexShowsPage;
    procedure DesignerStartSelection;
    procedure PanelBevelDefaultsLikeTPanel;
  end;

implementation

type
  TFieldCrack = class(TPPGCustomField);
  TPPGEditCrack = class(TPPGCustomField)
  public
    function HintShown: string;
  end;
  TWinCrack = class(TWinControl);
  TComboCrack = class(TPPGDBComboBox)
  public
    function ReadOnlyOfField: Boolean;
  end;
  TDateCrack = class(TPPGDBDatePicker);
  TRadioCrack = class(TPPGDBRadioGroup);
  TGridCrack = class(TPPGDBGrid);
  TChartCrack = class(TPPGDBChart);

  TCaptureLogger = class(TInterfacedObject, IPPGLogger)
  private
    FList: TStringList;
  public
    procedure Log(Level: TPPGLogLevel; const Msg: string);
  end;

procedure TCaptureLogger.Log(Level: TPPGLogLevel; const Msg: string);
begin
  FList.Add(Msg);
end;

function TComboCrack.ReadOnlyOfField: Boolean;
begin
  Result := TFieldCrack(Self).ReadOnly;
end;

function TPPGEditCrack.HintShown: string;
begin
  Result := DisplayTextHint;
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

{ TDBFix2Tests }

procedure TDBFix2Tests.SetUp;
begin
  inherited SetUp;
  FWarnings := TStringList.Create;
  FOrte := TClientDataSet.Create(FForm);
  FOrte.FieldDefs.Add('ID', ftInteger);
  FOrte.FieldDefs.Add('Ort', ftString, 20);
  FOrte.CreateDataSet;
  FOrte.AppendRecord([1, 'Berlin']);
  FOrte.AppendRecord([2, 'Hamburg']);
  FOrte.AppendRecord([3, 'Koeln']);
  FOrte.First;
  FData := TClientDataSet.Create(FForm);
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
  FForm.Show;
end;

procedure TDBFix2Tests.TearDown;
begin
  FreeAndNil(FWarnings);
  inherited TearDown;
end;

procedure TDBFix2Tests.Build(WithLookupField: Boolean);
var
  F: TField;
begin
  // Persistente Felder (fuer das Nachschlagefeld noetig)
  F := TIntegerField.Create(FData);
  F.FieldName := 'ID';
  F.DataSet := FData;
  F := TStringField.Create(FData);
  F.FieldName := 'Name';
  F.Size := 20;
  F.DataSet := FData;
  F := TIntegerField.Create(FData);
  F.FieldName := 'OrtID';
  F.DataSet := FData;
  F := TBCDField.Create(FData);
  F.FieldName := 'Betrag';
  TBCDField(F).Size := 2;
  TBCDField(F).Precision := 12;
  F.DataSet := FData;
  F := TFloatField.Create(FData);
  F.FieldName := 'Preis';
  F.DataSet := FData;
  if WithLookupField then
  begin
    F := TStringField.Create(FData);
    F.FieldName := 'OrtName';
    F.Size := 20;
    F.FieldKind := fkLookup;
    F.KeyFields := 'OrtID';
    F.LookupDataSet := FOrte;
    F.LookupKeyFields := 'ID';
    F.LookupResultField := 'Ort';
    F.DataSet := FData;
  end;
  FData.CreateDataSet;
  FData.AppendRecord([1, 'Eins', 2, 12.34, 1.5]);
  FData.AppendRecord([2, 'Zwei', Null, Null, Null]);
  FData.AppendRecord([3, 'Drei', 3, 7.5, 4.5]);
  FData.First;
end;

procedure TDBFix2Tests.NumberEditKindFromField;
var
  E: TPPGDBNumberEdit;
begin
  Build(False);
  E := TPPGDBNumberEdit.Create(FForm);
  E.Parent := FForm;
  E.DataSource := FSource;
  E.DataField := 'ID';
  CheckTrue(E.NumberKind = nkInteger, 'Ganzzahlfeld');
  CheckEquals(0, E.Decimals);
  CheckEquals('1', E.Text, 'kein ",00"');
  E.DataField := 'Betrag';
  CheckTrue(E.NumberKind = nkCurrency, 'BCD mit 2 Stellen: exakt ueber Currency');
  CheckEquals(2, E.Decimals);
  CheckTrue(E.AsCurrency = 12.34);
  E.DataField := 'Preis';
  CheckTrue(E.NumberKind = nkFloat, 'Gleitkomma: Vorgaben');
  CheckEquals(2, E.Decimals);
  // Eigene Art hat Vorrang
  E.NumberKind := nkPercent;
  E.DataField := 'ID';
  CheckTrue(E.NumberKind = nkPercent);
end;

procedure TDBFix2Tests.LookupFieldAsDataField;
var
  L: TPPGDBLookupComboBox;
begin
  Build(True);
  L := TPPGDBLookupComboBox.Create(FForm);
  L.Parent := FForm;
  L.DataSource := FSource;
  L.DataField := 'OrtName';
  CheckEquals('OrtName', L.DataField, 'DataField bleibt der Name des Nachschlagefelds');
  CheckEquals(3, L.KeyCount, 'Liste aus LookupDataSet');
  CheckEquals('Hamburg', L.Text);
  TComboCrack(L).SelectIndex(2);
  CheckTrue(FData.State = dsEdit);
  FData.Post;
  CheckEquals(3, FData.FieldByName('OrtID').AsInteger, 'Schluesselfeld geschrieben');
  CheckEquals('Koeln', FData.FieldByName('OrtName').AsString);
end;

procedure TDBFix2Tests.LookupMultiKeyWarns;
var
  L: TPPGDBLookupComboBox;
  Log: TCaptureLogger;
  Old: IPPGLogger;
  OrtSrc: TDataSource;
begin
  Build(False);
  OrtSrc := TDataSource.Create(FForm);
  OrtSrc.DataSet := FOrte;
  Log := TCaptureLogger.Create;
  Log.FList := FWarnings;
  Old := TPPGErrorHandler.Logger;
  TPPGErrorHandler.Logger := Log;
  try
    L := TPPGDBLookupComboBox.Create(FForm);
    L.Parent := FForm;
    L.ListSource := OrtSrc;
    L.ListField := 'Ort';
    L.KeyField := 'ID;Ort';
    L.DataSource := FSource;
    L.DataField := 'OrtID';
    CheckEquals(0, L.KeyCount);
  finally
    TPPGErrorHandler.Logger := Old;
  end;
  CheckTrue(Pos('ID;Ort', FWarnings.Text) > 0, 'Mehrfachschluessel gemeldet statt still leer');
end;

procedure TDBFix2Tests.LookupNullValueKey;
var
  L: TPPGDBLookupComboBox;
  OrtSrc: TDataSource;
  K: Word;
begin
  Build(False);
  OrtSrc := TDataSource.Create(FForm);
  OrtSrc.DataSet := FOrte;
  L := TPPGDBLookupComboBox.Create(FForm);
  L.Parent := FForm;
  L.ListSource := OrtSrc;
  L.KeyField := 'ID';
  L.ListField := 'Ort';
  L.DataSource := FSource;
  L.DataField := 'OrtID';
  L.NullValueKey := ShortCut(VK_DELETE, []);
  CheckEquals(1, L.ItemIndex);
  K := VK_DELETE;
  TComboCrack(L).FieldKeyDown(K, []);
  CheckEquals(0, K);
  CheckEquals(-1, L.ItemIndex);
  CheckTrue(FData.State = dsEdit);
  FData.Post;
  CheckTrue(FData.FieldByName('OrtID').IsNull, 'NullValueKey leert das Feld');
end;

procedure TDBFix2Tests.LookupListFollowsChanges;
var
  L: TPPGDBLookupComboBox;
  OrtSrc: TDataSource;
begin
  Build(False);
  OrtSrc := TDataSource.Create(FForm);
  OrtSrc.DataSet := FOrte;
  L := TPPGDBLookupComboBox.Create(FForm);
  L.Parent := FForm;
  L.ListSource := OrtSrc;
  L.KeyField := 'ID';
  L.ListField := 'Ort';
  L.DataSource := FSource;
  L.DataField := 'OrtID';
  FOrte.AppendRecord([4, 'Muenchen']);
  FOrte.AppendRecord([5, 'Bremen']);
  // Neu gelesen wird gebuendelt, spaetestens beim Zugriff
  CheckEquals(5, L.KeyCount);
  Application.ProcessMessages;
  CheckEquals(5, L.KeyCount);
  CheckEquals(4, L.IndexOfKey(5));
end;

procedure TDBFix2Tests.GridLookupColumnPicksKey;
var
  G: TPPGDBGrid;
  C: Integer;
begin
  Build(True);
  G := TPPGDBGrid.Create(FForm);
  G.Parent := FForm;
  G.SetBounds(0, 0, 500, 160);
  G.Animation.Enabled := False;
  G.DataSource := FSource;
  C := TGridCrack(G).FixedCols + FData.FieldByName('OrtName').Index;
  CheckTrue(TGridCrack(G).CanEditCell(C, TGridCrack(G).VisualRow(1)),
    'Nachschlagefeld aenderbar ueber das Schluesselfeld');
  CheckTrue(TGridCrack(G).CellEditorKind(C, 1) = gekCombo, 'Auswahlliste statt Freitext');
  TGridCrack(G).SetCellByUser(C, 1, 'Xyz');
  CheckTrue(FData.State = dsBrowse, 'unbekannter Text aendert nichts');
  CheckEquals(2, FData.FieldByName('OrtID').AsInteger);
  TGridCrack(G).SetCellByUser(C, 1, 'Berlin');
  CheckTrue(FData.State = dsEdit);
  CheckEquals(1, FData.FieldByName('OrtID').AsInteger, 'Schluessel aus der Nachschlage-Datenmenge');
  FData.Cancel;
end;

procedure TDBFix2Tests.GridEditsOnFirstKey;
var
  G: TPPGDBGrid;
begin
  Build(False);
  G := TPPGDBGrid.Create(FForm);
  G.Parent := FForm;
  G.SetBounds(0, 0, 500, 160);
  G.Animation.Enabled := False;
  G.DataSource := FSource;
  G.SetFocus;
  G.Col := TGridCrack(G).FixedCols + FData.FieldByName('Name').Index;
  G.Row := 1;
  G.EditorMode := True;
  CheckTrue(G.EditorMode, 'Editor offen');
  CheckTrue(FData.State = dsBrowse, 'Oeffnen allein bearbeitet nicht');
  TPPGEditCrack(G.InplaceEditor).Text := 'Neu';
  CheckTrue(FData.State = dsEdit, 'Bearbeiten-Modus beim ersten Tastendruck (wie TDBGrid)');
  G.EditorMode := False;
  FData.Cancel;
end;

procedure TDBFix2Tests.GridPersistentColumnTakesFieldAlignment;
var
  G: TPPGDBGrid;
  C: TPPGDBGridColumn;
begin
  Build(False);
  G := TPPGDBGrid.Create(FForm);
  G.Parent := FForm;
  C := TPPGDBGridColumn(G.Columns.Add);
  C.FieldName := 'Preis';
  C := TPPGDBGridColumn(G.Columns.Add);
  C.FieldName := 'ID';
  C.Alignment := taCenter;
  G.DataSource := FSource;
  CheckTrue(TPPGDBGridColumn(G.Columns[0]).Alignment = FData.FieldByName('Preis').Alignment,
    'ohne eigenen Wert: Ausrichtung des Felds');
  CheckTrue(TPPGDBGridColumn(G.Columns[1]).Alignment = taCenter, 'eigener Wert bleibt');
end;

procedure TDBFix2Tests.ChartSkipsNullAndJumpsByBookmark;
var
  C: TPPGDBChart;
begin
  Build(False);
  C := TPPGDBChart.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(0, 0, 300, 200);
  C.Animation.Enabled := False;
  C.ReloadDelay := 0;
  C.ValueFields := 'Preis';
  C.DataSource := FSource;
  CheckEquals(2, C.Series[0].Count, 'Null: kein Punkt');
  TChartCrack(C).DoPointClick(0, 1);
  CheckEquals(3, FData.FieldByName('ID').AsInteger, 'Punkt 2 gehoert zu Datensatz 3');
  CheckEquals(1, TChartCrack(C).MarkedIndex, 'Markierung ueber Lesezeichen');
  FData.Prior;
  CheckEquals(-1, TChartCrack(C).MarkedIndex, 'Datensatz ohne Punkt');
end;

procedure TDBFix2Tests.ChartDoesNotStoreBoundData;
var
  C: TPPGDBChart;
  M: TMemoryStream;
  S: TStringStream;
begin
  Build(False);
  C := TPPGDBChart.Create(FForm);
  C.Parent := FForm;
  C.ReloadDelay := 0;
  C.ValueFields := 'Preis';
  C.DataSource := FSource;
  CheckEquals(2, C.Series[0].Count);
  M := TMemoryStream.Create;
  S := TStringStream.Create('');
  try
    M.WriteComponent(C);
    M.Position := 0;
    ObjectBinaryToText(M, S);
    CheckEquals(0, Pos('ValuesText', S.DataString), 'Werte der Datenmenge nicht in der DFM');
    CheckEquals(0, Pos('Title', S.DataString), 'Titel aus DisplayLabel nicht in der DFM');
  finally
    S.Free;
    M.Free;
  end;
end;

procedure TDBFix2Tests.ShowRequiredMarksFieldAndTitle;
var
  E: TPPGDBEdit;
  G: TPPGDBGrid;
  C: Integer;
begin
  Build(False);
  FData.FieldByName('Name').Required := True;
  E := TPPGDBEdit.Create(FForm);
  E.Parent := FForm;
  E.DataSource := FSource;
  E.DataField := 'Name';
  CheckEquals('', TPPGEditCrack(E).HintShown, 'Vorgabe aus');
  E.ShowRequired := True;
  CheckEquals('*', TPPGEditCrack(E).HintShown, 'Pflichtfeld: Sternchen');
  E.TextHint := 'Name';
  CheckEquals('Name *', TPPGEditCrack(E).HintShown);
  CheckEquals('Name', E.TextHint, 'TextHint selbst bleibt unveraendert');
  E.DataField := 'ID';
  CheckEquals('Name', TPPGEditCrack(E).HintShown, 'kein Pflichtfeld');
  G := TPPGDBGrid.Create(FForm);
  G.Parent := FForm;
  G.ShowRequired := True;
  G.DataSource := FSource;
  C := TGridCrack(G).FixedCols + FData.FieldByName('Name').Index;
  CheckEquals('Name *', TGridCrack(G).GetCellText(C, 0), 'Spaltentitel');
end;

{ TStreamingFixTests }

type
  /// Wurzel fuer Text-DFMs im Test (TForm ohne Ressource).
  TPPGTestRoot = class(TForm);

procedure ReadRoot(Root: TComponent; const Dfm: string);
var
  Src: TStringStream;
  Bin: TMemoryStream;
begin
  Src := TStringStream.Create(Dfm);
  Bin := TMemoryStream.Create;
  try
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    Bin.ReadComponent(Root);
  finally
    Bin.Free;
    Src.Free;
  end;
end;

function TStreamingFixTests.DfmOf(C: TComponent): string;
var
  M: TMemoryStream;
  S: TStringStream;
begin
  M := TMemoryStream.Create;
  S := TStringStream.Create('');
  try
    M.WriteComponent(C);
    M.Position := 0;
    ObjectBinaryToText(M, S);
    Result := S.DataString;
  finally
    S.Free;
    M.Free;
  end;
end;

procedure TStreamingFixTests.EmptyDelimitersAreStored;
var
  C, C2: TPPGCheckComboBox;
  T, T2: TPPGTagEdit;
  M: TMemoryStream;
begin
  C := TPPGCheckComboBox.Create(FForm);
  C.DisplayDelimiter := '';
  T := TPPGTagEdit.Create(FForm);
  T.Delimiters := '';
  M := TMemoryStream.Create;
  try
    M.WriteComponent(C);
    M.Position := 0;
    C2 := TPPGCheckComboBox.Create(nil);
    try
      M.ReadComponent(C2);
      CheckEquals('', C2.DisplayDelimiter, 'leer bleibt leer');
    finally
      C2.Free;
    end;
    M.Clear;
    M.WriteComponent(T);
    M.Position := 0;
    T2 := TPPGTagEdit.Create(nil);
    try
      M.ReadComponent(T2);
      CheckEquals('', T2.Delimiters);
    finally
      T2.Free;
    end;
  finally
    M.Free;
  end;
  CheckEquals(0, Pos('DisplayDelimiter', DfmOf(TPPGCheckComboBox.Create(FForm))), 'Vorgabe nicht gespeichert');
end;

procedure TStreamingFixTests.PrintFooterDefaultNotStored;
var
  P: TPPGGridPrinter;
begin
  P := TPPGGridPrinter.Create(FForm);
  CheckEquals(0, Pos('FooterText', DfmOf(P)), 'uebersetzte Vorgabe nicht in der DFM');
  P.FooterText := '';
  CheckTrue(Pos('FooterText', DfmOf(P)) > 0, 'bewusst leer wird gespeichert');
end;

procedure TStreamingFixTests.PasswordTextNotStored;
var
  P: TPPGPasswordEdit;
begin
  P := TPPGPasswordEdit.Create(FForm);
  P.Text := 'Geheim123';
  CheckEquals(0, Pos('Geheim123', DfmOf(P)), 'kein Klartext in der DFM');
end;

procedure TStreamingFixTests.ExpandedHeightOnlyWhenNeeded;
var
  E: TPPGExpander;
begin
  E := TPPGExpander.Create(FForm);
  E.Parent := FForm;
  E.Height := 200;
  CheckEquals(0, Pos('ExpandedHeight', DfmOf(E)), 'aufgeklappt: steht in Height');
  E.Expanded := False;
  CheckTrue(Pos('ExpandedHeight', DfmOf(E)) > 0, 'zugeklappt: wird gebraucht');
end;

procedure TStreamingFixTests.ComboItemsNotTwiceWithItemsEx;
var
  C: TPPGComboBox;
begin
  C := TPPGComboBox.Create(FForm);
  C.ItemsEx.Add('Eins');
  C.ItemsEx.Add('Zwei');
  CheckEquals(0, Pos('Items.Strings', DfmOf(C)), 'Texte nur in ItemsEx');
  C.ItemsEx.Clear;
  C.Items.Add('Drei');
  CheckTrue(Pos('Items.Strings', DfmOf(C)) > 0);
end;

procedure TStreamingFixTests.MinZeroNotStored;
begin
  CheckEquals(0, Pos(#13#10'  Min = ', DfmOf(TPPGTrackBar.Create(FForm))), 'TrackBar');
  CheckEquals(0, Pos(#13#10'  Min = ', DfmOf(TPPGProgressBar.Create(FForm))), 'ProgressBar');
end;

procedure TStreamingFixTests.HintManagerWaitsForLoaded;
const
  Dfm =
    'object Root: TPPGTestRoot'#13#10 +
    '  object H: TPPGHintManager'#13#10 +
    '    Active = False'#13#10 +
    '  end'#13#10 +
    'end';
var
  Root: TPPGTestRoot;
  Before: THintWindowClass;
begin
  Before := HintWindowClass;
  Root := TPPGTestRoot.CreateNew(nil);
  try
    // Der Besitzer laedt gerade: der Konstruktor wendet nicht an, erst
    // Loaded (mit dem gelesenen Active = False: gar nicht)
    ReadRoot(Root, Dfm);
    CheckFalse(TPPGHintManager(Root.FindComponent('H')).Active);
    CheckTrue(HintWindowClass = Before, 'Hint-Klasse unveraendert');
  finally
    Root.Free;
  end;
end;

procedure TStreamingFixTests.GroupIndexReadBeforeDown;
const
  Dfm =
    'object Bar: TPPGToolBar'#13#10 +
    '  Items = <'#13#10 +
    '    item'#13#10 +
    '      Style = tisCheck'#13#10 +
    '      GroupIndex = 1'#13#10 +
    '      Down = True'#13#10 +
    '    end'#13#10 +
    '    item'#13#10 +
    '      Style = tisCheck'#13#10 +
    '      GroupIndex = 1'#13#10 +
    '      Down = True'#13#10 +
    '    end>'#13#10 +
    'end';
var
  Src: TStringStream;
  Bin: TMemoryStream;
  B: TPPGToolBar;
  I, N: Integer;
begin
  B := TPPGToolBar.Create(FForm);
  B.Items.Add.Style := tisCheck;
  B.Items[0].GroupIndex := 1;
  B.Items[0].Down := True;
  CheckTrue(Pos('GroupIndex = ', DfmOf(B)) < Pos(' Down = ', DfmOf(B)), 'GroupIndex steht vor Down');
  Src := TStringStream.Create(Dfm);
  Bin := TMemoryStream.Create;
  try
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    B := TPPGToolBar.Create(FForm);
    Bin.ReadComponent(B);
    N := 0;
    for I := 0 to B.Items.Count - 1 do
      if B.Items[I].Down then
        Inc(N);
    CheckEquals(1, N, 'nur ein gedruecktes Item je Gruppe');
  finally
    Bin.Free;
    Src.Free;
  end;
end;

procedure TStreamingFixTests.RibbonBackstageHiddenAfterLoad;
const
  Dfm =
    'object Root: TPPGTestRoot'#13#10 +
    '  object P: TPanel'#13#10 +
    '  end'#13#10 +
    '  object R: TPPGRibbon'#13#10 +
    '    Backstage = P'#13#10 +
    '  end'#13#10 +
    'end';
var
  Root: TPPGTestRoot;
begin
  Root := TPPGTestRoot.CreateNew(nil);
  try
    ReadRoot(Root, Dfm);
    CheckFalse(TPanel(Root.FindComponent('P')).Visible, 'Backstage aus der DFM zur Laufzeit verborgen');
  finally
    Root.Free;
  end;
end;

procedure TStreamingFixTests.PresetCheckedOnComponents;
var
  N: TPPGNotificationCenter;
  M: TPPGPopupMenu;
  Raised: Boolean;
begin
  N := TPPGNotificationCenter.Create(FForm);
  N.Preset := 'Fluent11';
  CheckEquals('Fluent11', N.Preset);
  N.Preset := '';
  Raised := False;
  try
    N.Preset := 'GibtsNicht';
  except
    on EPPGPropertyError do
      Raised := True;
  end;
  CheckTrue(Raised, 'unbekanntes Preset abgelehnt');
  CheckEquals('', N.Preset, 'unveraendert');
  M := TPPGPopupMenu.Create(FForm);
  Raised := False;
  try
    M.Preset := 'GibtsNicht';
  except
    on EPPGPropertyError do
      Raised := True;
  end;
  CheckTrue(Raised);
end;

{ TSetterFixTests }

type
  TLinkCrack = class(TPPGLinkLabel);

procedure TSetterFixTests.SelChange(Sender: TObject);
begin
  Inc(FSelChanges);
end;

procedure TSetterFixTests.CheckRejects(const What: string; Proc: TProc);
var
  Raised: Boolean;
begin
  Raised := False;
  try
    Proc();
  except
    on EPPGPropertyError do
      Raised := True;
  end;
  CheckTrue(Raised, What + ': abgelehnt statt still begrenzt');
end;

procedure TSetterFixTests.SilentClampsNowRejected;
var
  S: TPPGStatusBar;
  N: TPPGNavigationView;
  E: TPPGFileEdit;
  C: TPPGCheckComboBox;
  T: TPPGTagEdit;
  R: TPPGProgressRing;
begin
  S := TPPGStatusBar.Create(FForm);
  S.Panels.Add;
  CheckRejects('StatusPanel.Progress', procedure begin S.Panels[0].Progress := 140 end);
  CheckRejects('StatusPanel.Width', procedure begin S.Panels[0].Width := -1 end);
  CheckRejects('StatusPanel.BadgeCount', procedure begin S.Panels[0].BadgeCount := -1 end);
  N := TPPGNavigationView.Create(FForm);
  N.Items.AddItem('A');
  CheckRejects('NavItem.BadgeCount', procedure begin N.Items[0].BadgeCount := -2 end);
  CheckRejects('CompactModeThresholdWidth', procedure begin N.CompactModeThresholdWidth := -1 end);
  E := TPPGFileEdit.Create(FForm);
  CheckRejects('FilterIndex', procedure begin E.FilterIndex := -1 end);
  C := TPPGCheckComboBox.Create(FForm);
  CheckRejects('FilterThreshold', procedure begin C.FilterThreshold := -5 end);
  T := TPPGTagEdit.Create(FForm);
  CheckRejects('TagEdit.Delimiter', procedure begin T.Delimiter := #0 end);
  CheckEquals(';', string(T.Delimiter), 'unveraendert');
  R := TPPGProgressRing.Create(FForm);
  CheckRejects('ProgressRing.Value', procedure begin R.Value := -1 end);
end;

procedure TSetterFixTests.KanbanSelectedCardScrollsWithoutEvent;
var
  K: TPPGKanban;
  Col: TPPGKanbanColumn;
  I: Integer;
  Last: TPPGKanbanCard;
begin
  K := TPPGKanban.Create(FForm);
  K.Parent := FForm;
  K.SetBounds(0, 0, 400, 200);
  K.Animation.Enabled := False;
  Col := K.Columns.AddColumn('Viele');
  for I := 1 to 40 do
    Last := K.Cards.AddCard(Col.Id, 'Karte ' + IntToStr(I), '');
  K.OnSelectionChange := SelChange;
  FSelChanges := 0;
  K.SelectedCard := Last;
  CheckTrue(K.SelectedCard = Last);
  CheckEquals(0, FSelChanges, 'Code setzt ohne Ereignis');
  CheckTrue(K.ColumnScroll(0) > 0, 'zur Karte gescrollt');
end;

procedure TSetterFixTests.InfoBarVisibleIsOpen;
var
  B: TPPGInfoBar;
begin
  B := TPPGInfoBar.Create(FForm);
  B.Parent := FForm;
  B.Animation.Enabled := False;
  CheckTrue(B.IsOpen);
  B.Visible := False;
  CheckFalse(B.IsOpen, 'Visible = False schliesst');
  B.Visible := True;
  CheckTrue(B.IsOpen, 'Visible = True oeffnet');
  B.IsOpen := False;
  CheckFalse(B.Visible);
end;

procedure TSetterFixTests.LinkLabelKeepsOwnCursor;
var
  L: TPPGLinkLabel;
  R: TRect;
begin
  L := TPPGLinkLabel.Create(FForm);
  L.Parent := FForm;
  L.SetBounds(10, 10, 300, 24);
  L.Caption := '<a href="x">Link</a> und Text';
  L.Cursor := crHelp;
  FForm.Show;
  R := TLinkCrack(L).LinkRect(0);
  TLinkCrack(L).MouseMove([], (R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
  CheckEquals(0, L.HotLink, 'ueber dem Link');
  CheckEquals(Ord(crHelp), Ord(L.Cursor), 'eigener Cursor bleibt');
  TLinkCrack(L).MouseMove([], R.Right + 150, (R.Top + R.Bottom) div 2);
  CheckEquals(Ord(crHelp), Ord(L.Cursor));
end;

procedure TSetterFixTests.NavItemPageIndexShowsPage;
var
  N: TPPGNavigationView;
  P: TPPGPageControl;
  I: Integer;
begin
  P := TPPGPageControl.Create(FForm);
  P.Parent := FForm;
  for I := 0 to 2 do
    TPPGTabSheet.Create(FForm).PageControl := P;
  N := TPPGNavigationView.Create(FForm);
  N.Parent := FForm;
  N.PageControl := P;
  N.Items.AddItem('A', 0, 0);
  N.Selected := N.Items[0];
  CheckEquals(0, P.ActivePageIndex);
  N.Items[0].PageIndex := 2;
  CheckEquals(2, P.ActivePageIndex, 'gewaehlter Eintrag zeigt die neue Seite');
end;

procedure TSetterFixTests.DesignerStartSelection;
begin
  CheckTrue(IsPublishedProp(TPPGColumnComboBox, 'ItemIndex'), 'Startauswahl im Designer');
end;

procedure TSetterFixTests.PanelBevelDefaultsLikeTPanel;
var
  P: TPPGPanel;
  M: TMemoryStream;
  S: TStringStream;
begin
  P := TPPGPanel.Create(FForm);
  CheckTrue(P.BevelOuter = bvRaised, 'wie TPanel');
  CheckTrue(P.BevelInner = bvNone);
  M := TMemoryStream.Create;
  S := TStringStream.Create('');
  try
    M.WriteComponent(P);
    M.Position := 0;
    ObjectBinaryToText(M, S);
    CheckEquals(0, Pos('Bevel', S.DataString), 'Vorgaben nicht in der DFM');
  finally
    S.Free;
    M.Free;
  end;
end;

initialization
  RegisterTest('Audit45', TDBBindingHoldTests.Suite);
  RegisterTest('Audit45', TDBFixTests.Suite);
  RegisterTest('Audit45', TDBFix2Tests.Suite);
  RegisterTest('Audit45', TStreamingFixTests.Suite);
  RegisterTest('Audit45', TSetterFixTests.Suite);
  RegisterClasses([TPPGHintManager, TPanel, TPPGRibbon, TPPGTestRoot]);

end.
