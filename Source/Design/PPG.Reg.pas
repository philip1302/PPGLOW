unit PPG.Reg;

{ Design-Time-Registrierung. Diese Unit gehoert AUSSCHLIESSLICH in das
  Design-Package dclPPGlow (DesignIntf darf nie in Anwendungen gelinkt werden).

  Regel: Property-Editoren fangen alle Exceptions ab und zeigen sie an - die
  IDE darf durch eine Komponente nie instabil werden. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, DesignIntf, DesignEditors, PPG.PageControl;

type
  /// Auswahlliste der registrierten Presets im Object Inspector.
  TPPGPresetProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
  end;

  /// Kontextmenue "Preset-Farben wiederherstellen" fuer Controls und Manager.
  TPPGComponentEditor = class(TDefaultEditor)
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

  /// PageControl und TabSheet: Seiten anlegen, wechseln, loeschen
  /// (plus "Preset-Farben wiederherstellen").
  TPPGPageControlEditor = class(TPPGComponentEditor)
  private
    function PageControl: TPPGPageControl;
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

procedure Register;

implementation

uses
  System.SysUtils, Vcl.Dialogs,
  PPG.Consts, PPG.Render.Registry, PPG.Presets, PPG.StyleManager,
  PPG.Controls.Base, PPG.Button, PPG.CheckBox, PPG.RadioButton, PPG.ToggleSwitch,
  PPG.ProgressBar, PPG.TrackBar, PPG.Panel, PPG.GroupBox, PPG.Edit, PPG.Memo, PPG.SpinEdit, PPG.ComboBox,
  PPG.TabControl, PPG.ListBox, PPG.CheckListBox, PPG.TreeView, PPG.Grid,
  PPG.Labels, PPG.Feedback, PPG.Expander, PPG.Splitter, PPG.Rating, PPG.SearchEdit,
  PPG.Calendar, PPG.DatePicker, PPG.TimePicker,
  PPG.NavigationView, PPG.Breadcrumb, PPG.ToolBar, PPG.StatusBar, PPG.Notifications;

resourcestring
  SVerbResetPreset = 'Reset to preset defaults';
  SVerbNewPage = 'Ne&w Page';
  SVerbNextPage = 'Ne&xt Page';
  SVerbPrevPage = '&Previous Page';
  SVerbDeletePage = '&Delete Page';

{ TPPGPresetProperty }

function TPPGPresetProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList, paMultiSelect, paRevertable];
end;

procedure TPPGPresetProperty.GetValues(Proc: TGetStrProc);
var
  Names: TStringList;
  I: Integer;
begin
  Names := TStringList.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    for I := 0 to Names.Count - 1 do
      Proc(Names[I]);
  finally
    Names.Free;
  end;
end;

procedure TPPGPresetProperty.SetValue(const Value: string);
begin
  try
    inherited SetValue(Value);
  except
    on E: Exception do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

{ TPPGComponentEditor }

function TPPGComponentEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TPPGComponentEditor.GetVerb(Index: Integer): string;
begin
  Result := SVerbResetPreset;
end;

procedure TPPGComponentEditor.ExecuteVerb(Index: Integer);
begin
  try
    if Component is TPPGCustomControl then
      TPPGCustomControl(Component).ResetToPresetDefaults
    else if Component is TPPGStyleManager then
      TPPGStyleManager(Component).ResetToPresetDefaults;
    Designer.Modified;
  except
    on E: Exception do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

{ TPPGPageControlEditor }

function TPPGPageControlEditor.PageControl: TPPGPageControl;
begin
  if Component is TPPGPageControl then
    Result := TPPGPageControl(Component)
  else if Component is TPPGTabSheet then
    Result := TPPGTabSheet(Component).PageControl
  else
    Result := nil;
end;

function TPPGPageControlEditor.GetVerbCount: Integer;
begin
  Result := 4 + inherited GetVerbCount;
end;

function TPPGPageControlEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := SVerbNewPage;
    1: Result := SVerbNextPage;
    2: Result := SVerbPrevPage;
    3: Result := SVerbDeletePage;
  else
    Result := inherited GetVerb(Index - 4);
  end;
end;

procedure TPPGPageControlEditor.ExecuteVerb(Index: Integer);
var
  PC: TPPGPageControl;
  Page: TPPGTabSheet;
begin
  if Index >= 4 then
  begin
    inherited ExecuteVerb(Index - 4);
    Exit;
  end;
  try
    PC := PageControl;
    if PC = nil then
      Exit;
    case Index of
      0:
        begin
          // Wie der VCL-Editor von TPageControl: Owner = Formular, eindeutiger Name
          Page := TPPGTabSheet.Create(Designer.GetRoot);
          try
            Page.Name := Designer.UniqueName(TPPGTabSheet.ClassName);
            Page.PageControl := PC;
          except
            Page.Free;
            raise;
          end;
          PC.ActivePage := Page;
          Designer.SelectComponent(Page);
        end;
      1, 2:
        PC.ActivePage := PC.FindNextPage(PC.ActivePage, Index = 1, False);
      3:
        if PC.ActivePage <> nil then
        begin
          Page := PC.ActivePage;
          Designer.SelectComponent(PC);
          Page.Free;
        end;
    end;
    Designer.Modified;
  except
    on E: Exception do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure Register;
begin
  RegisterComponents(PPGPaletteName, [TPPGButton, TPPGCheckBox, TPPGRadioButton,
    TPPGToggleSwitch, TPPGProgressBar, TPPGTrackBar, TPPGPanel, TPPGGroupBox,
    TPPGEdit, TPPGMemo, TPPGSpinEdit, TPPGComboBox, TPPGTabControl, TPPGPageControl,
    TPPGListBox, TPPGCheckListBox, TPPGTreeView, TPPGGrid,
    TPPGLabel, TPPGLinkLabel, TPPGBadge, TPPGProgressRing, TPPGInfoBar, TPPGExpander,
    TPPGSplitter, TPPGRating, TPPGSearchEdit, TPPGCalendar, TPPGDatePicker, TPPGTimePicker,
    TPPGNavigationView, TPPGBreadcrumb, TPPGToolBar, TPPGStatusBar, TPPGNotificationCenter,
    TPPGStyleManager]);
  // Seiten entstehen ueber den Komponenteneditor, nicht ueber die Palette
  RegisterClass(TPPGTabSheet);
  RegisterNoIcon([TPPGTabSheet]);
  RegisterPropertyEditor(TypeInfo(string), TPPGCustomControl, 'Preset', TPPGPresetProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGStyleManager, 'Preset', TPPGPresetProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGNotificationCenter, 'Preset', TPPGPresetProperty);
  RegisterComponentEditor(TPPGCustomControl, TPPGComponentEditor);
  RegisterComponentEditor(TPPGStyleManager, TPPGComponentEditor);
  RegisterComponentEditor(TPPGPageControl, TPPGPageControlEditor);
  RegisterComponentEditor(TPPGTabSheet, TPPGPageControlEditor);
end;

end.
