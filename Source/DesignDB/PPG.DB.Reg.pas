unit PPG.DB.Reg;

{ Design-Time-Registrierung der DB-Controls (Phase 9c). Gehoert
  AUSSCHLIESSLICH in das Design-Package dclPPGlowDB.

  - Palettenseite "PPGlow DB" mit Symbolen aus PPGlowDB.dcr.
  - Auswahllisten fuer DataField, KeyField, ListField und Column.FieldName
    (Felder der jeweiligen Datenmenge, auch bei geschlossener Datenmenge
    ueber die FieldDefs).
  - DB-Grid: Spalten-Editor und "Alle Felder als Spalten".
  - DB-Chart: Auswahl fuer LabelField/XField, Serien-Editor.
  - DB-Planer: Auswahl fuer alle Feld-Properties, Ressourcen-Editor.
  Die gemeinsamen Verben (Preset, Appearance, Galerie) kommen von
  TPPGComponentEditor aus dclPPGlow. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, DesignIntf, DesignEditors, PPG.Reg;

type
  /// Felder der Datenmenge aus der DataSource-Property der Komponente.
  TPPGDataFieldProperty = class(TStringProperty)
  protected
    /// Name der Property, die die DataSource liefert.
    function DataSourcePropName: string; virtual;
    function DataSourceOf(Instance: TPersistent): TObject; virtual;
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  /// KeyField/ListField der Lookup-Combo: Felder von ListSource.
  TPPGListFieldProperty = class(TPPGDataFieldProperty)
  protected
    function DataSourcePropName: string; override;
  end;

  /// FieldName einer DB-Grid-Spalte: Felder der DataSource des Grids.
  TPPGColumnFieldProperty = class(TPPGDataFieldProperty)
  protected
    function DataSourceOf(Instance: TPersistent): TObject; override;
  end;

  TPPGDBGridEditor = class(TPPGComponentEditor)
  protected
    function OwnVerbCount: Integer; override;
    function OwnVerb(Index: Integer): string; override;
    procedure ExecuteOwnVerb(Index: Integer); override;
  public
    procedure Edit; override;
  end;

procedure Register;

implementation

{$R PPGlowDB.dcr}

uses
  System.SysUtils, System.TypInfo, System.UITypes, Vcl.Controls, Vcl.Dialogs, Data.DB, ColnEdit,
  PPG.Grid, PPG.DB.Controls, PPG.DB.Lookup, PPG.DB.Grid, PPG.DB.Chart, PPG.DB.Fields,
  PPG.DB.Planner, PPG.DB.Kanban;

resourcestring
  SPPGDBPalette = 'PPGlow DB';
  SVerbDBColumns = 'Edit columns...';
  SVerbAddAllFields = 'Add all fields';
  SAddAllFieldsReplace = 'Replace the existing %d columns?';

{ TPPGDataFieldProperty }

function TPPGDataFieldProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList, paMultiSelect];
end;

function TPPGDataFieldProperty.DataSourcePropName: string;
begin
  Result := 'DataSource';
end;

function TPPGDataFieldProperty.DataSourceOf(Instance: TPersistent): TObject;
begin
  Result := nil;
  if IsPublishedProp(Instance, DataSourcePropName) then
    Result := GetObjectProp(Instance, DataSourcePropName);
end;

procedure TPPGDataFieldProperty.GetValues(Proc: TGetStrProc);
var
  DS: TObject;
  Names: TStringList;
  I: Integer;
begin
  Names := TStringList.Create;
  try
    try
      DS := DataSourceOf(GetComponent(0));
      if (DS is TDataSource) and (TDataSource(DS).DataSet <> nil) then
        TDataSource(DS).DataSet.GetFieldNames(Names);
    except
      // Editor-Grenze: eine Datenmenge, die sich nicht oeffnen laesst,
      // liefert nur keine Liste (die IDE bleibt stabil)
      on E: Exception do
        Names.Clear;
    end;
    for I := 0 to Names.Count - 1 do
      Proc(Names[I]);
  finally
    Names.Free;
  end;
end;

{ TPPGListFieldProperty }

function TPPGListFieldProperty.DataSourcePropName: string;
begin
  Result := 'ListSource';
end;

{ TPPGColumnFieldProperty }

function TPPGColumnFieldProperty.DataSourceOf(Instance: TPersistent): TObject;
var
  Owner: TPersistent;
begin
  Result := nil;
  if (Instance is TCollectionItem) and (TCollectionItem(Instance).Collection <> nil) then
  begin
    Owner := TCollectionItem(Instance).Collection.Owner;
    if Owner is TPPGCustomDBGrid then
      Result := TPPGCustomDBGrid(Owner).DataSource;
  end;
end;

{ TPPGDBGridEditor }

function TPPGDBGridEditor.OwnVerbCount: Integer;
begin
  Result := 2;
end;

function TPPGDBGridEditor.OwnVerb(Index: Integer): string;
begin
  if Index = 0 then
    Result := SVerbDBColumns
  else
    Result := SVerbAddAllFields;
end;

procedure TPPGDBGridEditor.ExecuteOwnVerb(Index: Integer);
var
  Grid: TPPGDBGrid;
  DS: TDataSource;
  Names: TStringList;
  I: Integer;
  C: TPPGDBGridColumn;
begin
  Grid := TPPGDBGrid(Component);
  if Index = 0 then
  begin
    ShowCollectionEditor(Designer, Grid, Grid.Columns, 'Columns');
    Exit;
  end;
  DS := Grid.DataSource;
  if (DS = nil) or (DS.DataSet = nil) then
    Exit;
  if (Grid.Columns.Count > 0) and
    (MessageDlg(Format(SAddAllFieldsReplace, [Grid.Columns.Count]), mtConfirmation,
      [mbYes, mbNo], 0) <> mrYes) then
    Exit;
  Names := TStringList.Create;
  try
    DS.DataSet.GetFieldNames(Names);
    Grid.Columns.BeginUpdate;
    try
      Grid.Columns.Clear;
      for I := 0 to Names.Count - 1 do
      begin
        C := TPPGDBGridColumn(Grid.Columns.Add);
        C.FieldName := Names[I];
      end;
    finally
      Grid.Columns.EndUpdate;
    end;
  finally
    Names.Free;
  end;
  Designer.Modified;
end;

procedure TPPGDBGridEditor.Edit;
begin
  ExecuteVerb(0);
end;

procedure Register;
const
  PlannerFields: array[0..11] of string = ('KeyField', 'StartField', 'FinishField',
    'SubjectField', 'LocationField', 'BodyField', 'AllDayField', 'CategoryField',
    'ResourceField', 'RecurrenceField', 'ExDatesField', 'ParentField');
  KanbanFields: array[0..10] of string = ('KeyField', 'ColumnField', 'LaneField', 'OrderField',
    'TitleField', 'TextField', 'LabelsField', 'AssigneeField', 'DueField', 'ProgressField', 'ColorField');
var
  I: Integer;
begin
  RegisterComponents(SPPGDBPalette, [TPPGDBEdit, TPPGDBMemo, TPPGDBCheckBox, TPPGDBComboBox,
    TPPGDBLookupComboBox, TPPGDBDatePicker, TPPGDBGrid, TPPGDBChart, TPPGDBPlanner, TPPGDBKanban,
    TPPGDBMaskEdit, TPPGDBNumberEdit, TPPGDBColorPicker, TPPGDBCheckComboBox, TPPGDBTagEdit]);
  RegisterPropertyEditor(TypeInfo(string), TPPGDBEdit, 'DataField', TPPGDataFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGDBMemo, 'DataField', TPPGDataFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGDBCheckBox, 'DataField', TPPGDataFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGDBComboBox, 'DataField', TPPGDataFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGDBDatePicker, 'DataField', TPPGDataFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGDBMaskEdit, 'DataField', TPPGDataFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGDBNumberEdit, 'DataField', TPPGDataFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGDBColorPicker, 'DataField', TPPGDataFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGDBCheckComboBox, 'DataField', TPPGDataFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGDBTagEdit, 'DataField', TPPGDataFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGDBLookupComboBox, 'KeyField', TPPGListFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGDBLookupComboBox, 'ListField', TPPGListFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGDBGridColumn, 'FieldName', TPPGColumnFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGDBChart, 'LabelField', TPPGDataFieldProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGDBChart, 'XField', TPPGDataFieldProperty);
  RegisterComponentEditor(TPPGDBGrid, TPPGDBGridEditor);
  for I := Low(PlannerFields) to High(PlannerFields) do
    RegisterPropertyEditor(TypeInfo(string), TPPGDBPlanner, PlannerFields[I], TPPGDataFieldProperty);
  RegisterComponentEditor(TPPGDBChart, TPPGCollectionEditor);
  RegisterComponentEditor(TPPGDBPlanner, TPPGCollectionEditor);
  for I := Low(KanbanFields) to High(KanbanFields) do
    RegisterPropertyEditor(TypeInfo(string), TPPGDBKanban, KanbanFields[I], TPPGDataFieldProperty);
  RegisterComponentEditor(TPPGDBKanban, TPPGCollectionEditor);
  RegisterComponentEditor(TPPGDBComboBox, TPPGCollectionEditor);
  RegisterComponentEditor(TPPGDBLookupComboBox, TPPGComponentEditor);
end;

end.
