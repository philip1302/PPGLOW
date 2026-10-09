unit PPG.Reg;

{ Design-Time-Registrierung. Diese Unit gehoert AUSSCHLIESSLICH in das
  Design-Package dclPPGlow (DesignIntf darf nie in Anwendungen gelinkt werden).

  Regel: Property- und Komponenten-Editoren fangen alle Exceptions ab und
  zeigen sie an - die IDE darf durch eine Komponente nie instabil werden.

  Phase 9a: Palettensymbole (PPGlow.dcr, erzeugt von Build\make-icons.ps1),
  Verben je Control (Appearance-Editor, Preset-Galerie, Collection-Editoren,
  Eintraege von NavigationView und TreeView) und ein Selection-Editor, der
  die Units fuer die Typen in Ereignis-Signaturen in die uses-Liste
  eintraegt. Die Dialoge selbst liegen in PPG.Editors.Forms (ohne
  DesignIntf, deshalb testbar). }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.Types, Vcl.Graphics, DesignIntf, DesignEditors, VCLEditors,
  PPG.PageControl, PPG.Wizard;

type
  /// ImageIndex von Eintraegen (ToolBar, NavigationView, Ribbon, StatusBar,
  /// Seiten): Auswahl mit Vorschau aus den Images des Besitzers.
  TPPGItemImageIndexProperty = class(TIntegerProperty, ICustomPropertyListDrawing)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure ListMeasureWidth(const Value: string; ACanvas: TCanvas; var AWidth: Integer);
    procedure ListMeasureHeight(const Value: string; ACanvas: TCanvas; var AHeight: Integer);
    procedure ListDrawValue(const Value: string; ACanvas: TCanvas; const ARect: TRect;
      ASelected: Boolean);
  end;

  {$IFDEF PPG_HAS_IMAGENAME}
  /// ImageName von Eintraegen: Namen aus den Images des Besitzers.
  TPPGItemImageNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;
  {$ENDIF}

  /// Auswahlliste der registrierten Presets im Object Inspector.
  TPPGPresetProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
  end;

  TPPGBaseVerb = (bvReset, bvAppearance, bvGallery);

  /// Gemeinsame Verben fuer Controls, StyleManager und NotificationCenter:
  /// "Preset-Farben wiederherstellen", "Appearance bearbeiten..." (nur
  /// Controls) und "Preset auf das Formular anwenden...". Abgeleitete Editoren
  /// stellen ihre eigenen Verben VOR die gemeinsamen (OwnVerbCount).
  TPPGComponentEditor = class(TDefaultEditor)
  private
    function BaseVerb(Index: Integer; out Verb: TPPGBaseVerb): Boolean;
    function BaseVerbCount: Integer;
    procedure ExecuteBaseVerb(Verb: TPPGBaseVerb);
  protected
    function OwnVerbCount: Integer; virtual;
    function OwnVerb(Index: Integer): string; virtual;
    procedure ExecuteOwnVerb(Index: Integer); virtual;
    /// Meldet eine Exception als Dialog (Editor-Grenze).
    procedure ShowError(E: TObject);
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

  /// PageControl und TabSheet: Seiten anlegen, wechseln, loeschen.
  TPPGPageControlEditor = class(TPPGComponentEditor)
  private
    function PageControl: TPPGPageControl;
  protected
    function OwnVerbCount: Integer; override;
    function OwnVerb(Index: Integer): string; override;
    procedure ExecuteOwnVerb(Index: Integer); override;
  end;

  /// Assistent und seine Seiten: Seiten anlegen, wechseln, loeschen.
  TPPGWizardEditor = class(TPPGComponentEditor)
  private
    function Wizard: TPPGWizard;
  protected
    function OwnVerbCount: Integer; override;
    function OwnVerb(Index: Integer): string; override;
    procedure ExecuteOwnVerb(Index: Integer); override;
  end;

  /// TaskDialog: im Designer anzeigen.
  TPPGTaskDialogEditor = class(TDefaultEditor)
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
    procedure Edit; override;
  end;

  /// Validator: Regeln bearbeiten, Pflicht-Regeln fuer alle Felder anlegen.
  TPPGValidatorEditor = class(TDefaultEditor)
  private
    procedure AddRequiredRules;
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
    procedure Edit; override;
  end;

  /// Grid- und Planer-Drucker: Seitenansicht und Seite einrichten im Designer.
  TPPGGridPrinterEditor = class(TDefaultEditor)
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
    procedure Edit; override;
  end;

  /// Ribbon: Registerkarten, Gruppen der aktiven Karte und Schnellzugriff
  /// bearbeiten, Karte anlegen, zwischen den Karten wechseln.
  TPPGRibbonEditor = class(TPPGComponentEditor)
  protected
    function OwnVerbCount: Integer; override;
    function OwnVerb(Index: Integer): string; override;
    procedure ExecuteOwnVerb(Index: Integer); override;
  public
    procedure Edit; override;
  end;

  /// Controls mit einer Collection (ItemsEx, Columns, Panels, Items):
  /// Verb oeffnet den Collection-Editor der IDE.
  TPPGCollectionEditor = class(TPPGComponentEditor)
  private
    function CollectionProp(out PropName, Verb: string; out OpenOnDblClick: Boolean): Boolean;
    procedure EditCollection;
  protected
    function OwnVerbCount: Integer; override;
    function OwnVerb(Index: Integer): string; override;
    procedure ExecuteOwnVerb(Index: Integer); override;
  public
    procedure Edit; override;
  end;

  /// NavigationView: Eintraege bearbeiten, mit einem PageControl verbinden.
  TPPGNavigationViewEditor = class(TPPGComponentEditor)
  private
    FPages: TList;
    procedure CollectPages;
  protected
    function OwnVerbCount: Integer; override;
    function OwnVerb(Index: Integer): string; override;
    procedure ExecuteOwnVerb(Index: Integer); override;
  public
    destructor Destroy; override;
    procedure Edit; override;
  end;

  /// TreeView: Knoten bearbeiten (wie der Items-Editor von TTreeView).
  TPPGTreeViewEditor = class(TPPGComponentEditor)
  protected
    function OwnVerbCount: Integer; override;
    function OwnVerb(Index: Integer): string; override;
    procedure ExecuteOwnVerb(Index: Integer); override;
  public
    procedure Edit; override;
  end;

  /// NotificationCenter: Test-Toast im Designer.
  TPPGNotificationCenterEditor = class(TPPGComponentEditor)
  protected
    function OwnVerbCount: Integer; override;
    function OwnVerb(Index: Integer): string; override;
    procedure ExecuteOwnVerb(Index: Integer); override;
  end;

  /// Traegt die Units der Typen aus Ereignis-Signaturen in die uses-Liste
  /// ein, damit erzeugte Ereignis-Handler sofort kompilieren.
  TPPGSelectionEditor = class(TSelectionEditor)
  public
    procedure RequiresUnits(Proc: TGetStrProc); override;
  end;

procedure Register;

implementation

{$R PPGlow.dcr}

uses
  System.SysUtils, System.TypInfo, System.UITypes, Vcl.Controls, Vcl.Dialogs, ColnEdit,
  PPG.Consts, PPG.Render.Registry, PPG.Presets, PPG.StyleManager,
  PPG.Controls.Base, PPG.Button, PPG.CheckBox, PPG.RadioButton, PPG.ToggleSwitch,
  PPG.ProgressBar, PPG.TrackBar, PPG.Panel, PPG.GroupBox, PPG.RadioGroup, PPG.Edit, PPG.Memo, PPG.SpinEdit, PPG.ComboBox,
  PPG.TabControl, PPG.Controls.ItemList, PPG.ListBox, PPG.CheckListBox, PPG.TreeView, PPG.TileView, PPG.Grid, PPG.Grid.Print,
  PPG.Labels, PPG.Feedback, PPG.Expander, PPG.Splitter, PPG.Rating, PPG.SearchEdit,
  PPG.Calendar, PPG.DatePicker, PPG.TimePicker,
  PPG.NavigationView, PPG.Breadcrumb, PPG.ToolBar, PPG.StatusBar, PPG.Notifications,
  PPG.Sparkline, PPG.Gauge, PPG.Chart,
  PPG.Menus, PPG.MenuBar, PPG.Hints, PPG.TeachingTip, PPG.Dialogs,
  PPG.NumberEdit, PPG.MaskEdit, PPG.PasswordEdit, PPG.FileEdit, PPG.ColorPicker,
  PPG.CheckComboBox, PPG.ColumnComboBox, PPG.TagEdit, PPG.Validator, PPG.Controls.Field, PPG.BusyOverlay,
  PPG.Print, PPG.Planner, PPG.Planner.Print, PPG.Kanban.Print, PPG.Ribbon.Items, PPG.Ribbon, PPG.Kanban,
  PPG.Editors.Logic, PPG.Editors.Forms, Vcl.ImgList, System.Math, PPG.Types;

const
  /// Kategorie im Objektinspektor fuer die Optik der Suite.
  PPGCategoryName = 'PPGlow';

resourcestring
  SVerbResetPreset = 'Reset to preset defaults';
  SVerbAppearance = 'Edit appearance...';
  SVerbGallery = 'Apply preset to form...';
  SVerbNewPage = 'Ne&w Page';
  SVerbTestDialog = '&Test dialog...';
  SVerbNextPage = 'Ne&xt Page';
  SVerbPrevPage = '&Previous Page';
  SVerbDeletePage = '&Delete Page';
  SVerbItemsEx = 'Edit rich items (ItemsEx)...';
  SVerbColumns = 'Edit columns...';
  SVerbPrintPreview = 'Print &preview...';
  SVerbPageSetup = 'Page &setup...';
  SVerbPanels = 'Edit panels...';
  SVerbToolItems = 'Edit buttons...';
  SVerbSeries = 'Edit series...';
  SVerbRanges = 'Edit ranges...';
  SVerbResources = 'Edit resources...';
  SVerbComboColumns = 'Edit columns...';
  SVerbNavItems = 'Edit items...';
  SVerbConnectPage = 'Connect to %s';
  SVerbDisconnectPage = 'Disconnect page control';
  SVerbTreeNodes = 'Edit nodes...';
  SVerbTestToast = 'Show test toast';
  SVerbRibbonTabs = 'Edit tabs...';
  SVerbRibbonGroups = 'Edit groups of the active tab...';
  SVerbRibbonQuick = 'Edit Quick Access items...';
  SVerbRibbonNewTab = 'Ne&w Tab';
  SVerbRibbonNextTab = 'Ne&xt Tab';
  SVerbRibbonPrevTab = '&Previous Tab';
  SVerbKanbanColumns = 'Edit columns...';
  SVerbValidatorRules = 'Edit rules...';
  SVerbValidatorRequired = 'Add required rules for all fields';
  STestToastTitle = 'PPGlow';
  STestToastText = 'This is how notifications look with the current settings.';
  SGalleryDone = '%d components changed to "%s".';

const
  /// Hoechstens so viele PageControls als eigene Verben (Uebersicht im Menue)
  MaxPageVerbs = 10;

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

procedure TPPGComponentEditor.ShowError(E: TObject);
begin
  if E is Exception then
    MessageDlg(Exception(E).Message, mtError, [mbOK], 0);
end;

function TPPGComponentEditor.OwnVerbCount: Integer;
begin
  Result := 0;
end;

function TPPGComponentEditor.OwnVerb(Index: Integer): string;
begin
  Result := '';
end;

procedure TPPGComponentEditor.ExecuteOwnVerb(Index: Integer);
begin
end;

function TPPGComponentEditor.BaseVerbCount: Integer;
var
  V: TPPGBaseVerb;
begin
  Result := 0;
  while BaseVerb(Result, V) do
    Inc(Result);
end;

function TPPGComponentEditor.BaseVerb(Index: Integer; out Verb: TPPGBaseVerb): Boolean;
var
  Verbs: array[0..2] of TPPGBaseVerb;
  N: Integer;
begin
  N := 0;
  if (Component is TPPGCustomControl) or (Component is TPPGStyleManager) then
  begin
    Verbs[N] := bvReset;
    Inc(N);
  end;
  if Component is TPPGCustomControl then
  begin
    Verbs[N] := bvAppearance;
    Inc(N);
  end;
  Verbs[N] := bvGallery;
  Inc(N);
  Result := (Index >= 0) and (Index < N);
  if Result then
    Verb := Verbs[Index]
  else
    Verb := bvReset;
end;

function TPPGComponentEditor.GetVerbCount: Integer;
begin
  Result := OwnVerbCount + BaseVerbCount;
end;

function TPPGComponentEditor.GetVerb(Index: Integer): string;
var
  V: TPPGBaseVerb;
begin
  if Index < OwnVerbCount then
    Exit(OwnVerb(Index));
  Result := '';
  if BaseVerb(Index - OwnVerbCount, V) then
    case V of
      bvReset: Result := SVerbResetPreset;
      bvAppearance: Result := SVerbAppearance;
      bvGallery: Result := SVerbGallery;
    end;
end;

procedure TPPGComponentEditor.ExecuteVerb(Index: Integer);
var
  V: TPPGBaseVerb;
begin
  try
    if Index < OwnVerbCount then
      ExecuteOwnVerb(Index)
    else if BaseVerb(Index - OwnVerbCount, V) then
      ExecuteBaseVerb(V);
  except
    ShowError(ExceptObject);
  end;
end;

procedure TPPGComponentEditor.ExecuteBaseVerb(Verb: TPPGBaseVerb);
var
  AppDlg: TPPGAppearanceDialog;
  Gallery: TPPGPresetGalleryDialog;
  N: Integer;
begin
  case Verb of
    bvReset:
      begin
        if Component is TPPGCustomControl then
          TPPGCustomControl(Component).ResetToPresetDefaults
        else if Component is TPPGStyleManager then
          TPPGStyleManager(Component).ResetToPresetDefaults;
        Designer.Modified;
      end;
    bvAppearance:
      begin
        AppDlg := TPPGAppearanceDialog.CreateFor(nil, TPPGCustomControl(Component));
        try
          if (AppDlg.ShowModal = mrOk) and AppDlg.Session.Modified then
          begin
            AppDlg.Session.Apply;
            Designer.Modified;
          end;
        finally
          AppDlg.Free;
        end;
      end;
    bvGallery:
      begin
        Gallery := TPPGPresetGalleryDialog.CreateFor(nil, Designer.GetRoot);
        try
          if (Gallery.ShowModal = mrOk) and (Gallery.SelectedPreset <> '') then
          begin
            N := TPPGPresetTargets.Apply(Designer.GetRoot, Gallery.SelectedPreset);
            if N > 0 then
              Designer.Modified;
            MessageDlg(Format(SGalleryDone, [N, Gallery.SelectedPreset]), mtInformation, [mbOK], 0);
          end;
        finally
          Gallery.Free;
        end;
      end;
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

function TPPGPageControlEditor.OwnVerbCount: Integer;
begin
  Result := 4;
end;

function TPPGPageControlEditor.OwnVerb(Index: Integer): string;
begin
  case Index of
    0: Result := SVerbNewPage;
    1: Result := SVerbNextPage;
    2: Result := SVerbPrevPage;
  else
    Result := SVerbDeletePage;
  end;
end;

procedure TPPGPageControlEditor.ExecuteOwnVerb(Index: Integer);
var
  PC: TPPGPageControl;
  Page: TPPGTabSheet;
begin
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
end;

{ TPPGWizardEditor }

function TPPGWizardEditor.Wizard: TPPGWizard;
begin
  if Component is TPPGWizard then
    Result := TPPGWizard(Component)
  else if Component is TPPGWizardPage then
    Result := TPPGWizardPage(Component).Wizard
  else
    Result := nil;
end;

function TPPGWizardEditor.OwnVerbCount: Integer;
begin
  Result := 4;
end;

function TPPGWizardEditor.OwnVerb(Index: Integer): string;
begin
  case Index of
    0: Result := SVerbNewPage;
    1: Result := SVerbNextPage;
    2: Result := SVerbPrevPage;
  else
    Result := SVerbDeletePage;
  end;
end;

procedure TPPGWizardEditor.ExecuteOwnVerb(Index: Integer);
var
  W: TPPGWizard;
  Page, P: TPPGWizardPage;
begin
  W := Wizard;
  if W = nil then
    Exit;
  case Index of
    0:
      begin
        Page := TPPGWizardPage.Create(Designer.GetRoot);
        try
          Page.Name := Designer.UniqueName(TPPGWizardPage.ClassName);
          Page.Caption := Page.Name;
          Page.Wizard := W;
        except
          Page.Free;
          raise;
        end;
        W.ActivePage := Page;
        Designer.SelectComponent(Page);
      end;
    1, 2:
      begin
        // Im Designer auch uebersprungene Seiten erreichbar
        P := nil;
        if (W.ActivePageIndex >= 0) and (W.PageCount > 0) then
          if Index = 1 then
            P := W.Pages[(W.ActivePageIndex + 1) mod W.PageCount]
          else
            P := W.Pages[(W.ActivePageIndex - 1 + W.PageCount) mod W.PageCount];
        W.ActivePage := P;
      end;
    3:
      if W.ActivePage <> nil then
      begin
        Page := W.ActivePage;
        Designer.SelectComponent(W);
        Page.Free;
      end;
  end;
  Designer.Modified;
end;

{ TPPGTaskDialogEditor }

function TPPGTaskDialogEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TPPGTaskDialogEditor.GetVerb(Index: Integer): string;
begin
  Result := SVerbTestDialog;
end;

procedure TPPGTaskDialogEditor.ExecuteVerb(Index: Integer);
begin
  TPPGTaskDialog(Component).Execute;
end;

procedure TPPGTaskDialogEditor.Edit;
begin
  ExecuteVerb(0);
end;

{ TPPGGridPrinterEditor }

function TPPGGridPrinterEditor.GetVerbCount: Integer;
begin
  Result := 2;
end;

function TPPGGridPrinterEditor.GetVerb(Index: Integer): string;
begin
  if Index = 0 then
    Result := SVerbPrintPreview
  else
    Result := SVerbPageSetup;
end;

procedure TPPGGridPrinterEditor.ExecuteVerb(Index: Integer);
begin
  if Index = 0 then
    TPPGCustomPrinter(Component).Preview
  else if TPPGCustomPrinter(Component).PageSetup then
    Designer.Modified;
end;

procedure TPPGGridPrinterEditor.Edit;
begin
  ExecuteVerb(0);
end;

{ TPPGValidatorEditor }

function TPPGValidatorEditor.GetVerbCount: Integer;
begin
  Result := 2;
end;

function TPPGValidatorEditor.GetVerb(Index: Integer): string;
begin
  if Index = 0 then
    Result := SVerbValidatorRules
  else
    Result := SVerbValidatorRequired;
end;

procedure TPPGValidatorEditor.ExecuteVerb(Index: Integer);
begin
  if Index = 0 then
    ShowCollectionEditor(Designer, Component, TPPGValidator(Component).Rules, 'Rules')
  else
    AddRequiredRules;
end;

procedure TPPGValidatorEditor.Edit;
begin
  ExecuteVerb(0);
end;

procedure TPPGValidatorEditor.AddRequiredRules;
var
  V: TPPGValidator;
  Root: TComponent;
  I, J: Integer;
  C: TControl;
  Has: Boolean;
begin
  // Eingabefelder und Auswahlgruppen ohne Regel; Kaestchen bewusst nicht
  // (ein Pflicht-Haken ist die Ausnahme, z.B. AGB)
  V := TPPGValidator(Component);
  Root := Designer.Root;
  V.Rules.BeginUpdate;
  try
    for I := 0 to Root.ComponentCount - 1 do
    begin
      if not (Root.Components[I] is TControl) then
        Continue;
      C := TControl(Root.Components[I]);
      if not ((C is TPPGCustomField) or (C is TPPGCustomChoiceGroup)) then
        Continue;
      Has := False;
      for J := 0 to V.Rules.Count - 1 do
        if V.Rules[J].Control = C then
          Has := True;
      if not Has then
        V.Rules.AddRule(C, vrRequired);
    end;
  finally
    V.Rules.EndUpdate;
  end;
  Designer.Modified;
end;

{ TPPGCollectionEditor }

function TPPGCollectionEditor.CollectionProp(out PropName, Verb: string;
  out OpenOnDblClick: Boolean): Boolean;
begin
  Result := True;
  OpenOnDblClick := True;
  if Component is TPPGGrid then
  begin
    PropName := 'Columns';
    Verb := SVerbColumns;
  end
  else if Component is TPPGStatusBar then
  begin
    PropName := 'Panels';
    Verb := SVerbPanels;
  end
  else if Component is TPPGToolBar then
  begin
    PropName := 'Items';
    Verb := SVerbToolItems;
  end
  else if Component is TPPGCustomChart then
  begin
    PropName := 'Series';
    Verb := SVerbSeries;
  end
  else if Component is TPPGGauge then
  begin
    PropName := 'Ranges';
    Verb := SVerbRanges;
  end
  else if Component is TPPGCustomKanban then
  begin
    PropName := 'Columns';
    Verb := SVerbKanbanColumns;
    OpenOnDblClick := False; // Doppelklick oeffnet eine Karte (OnCardOpen)
  end
  else if Component is TPPGCustomPlanner then
  begin
    PropName := 'Resources';
    Verb := SVerbResources;
    OpenOnDblClick := False; // Doppelklick: Termin anlegen gibt es nur zur Laufzeit
  end
  else if Component is TPPGColumnComboBox then
  begin
    PropName := 'Columns';
    Verb := SVerbComboColumns;
  end
  else if IsPublishedProp(Component, 'ItemsEx') then
  begin
    // ListBox, CheckListBox, ComboBox, SearchEdit: Doppelklick bleibt OnClick
    PropName := 'ItemsEx';
    Verb := SVerbItemsEx;
    OpenOnDblClick := False;
  end
  else
  begin
    Result := False;
    PropName := '';
    Verb := '';
    OpenOnDblClick := False;
  end;
end;

procedure TPPGCollectionEditor.EditCollection;
var
  PropName, Verb: string;
  Dbl: Boolean;
  Obj: TObject;
begin
  if not CollectionProp(PropName, Verb, Dbl) then
    Exit;
  Obj := GetObjectProp(Component, PropName);
  if Obj is TCollection then
    ShowCollectionEditor(Designer, Component, TCollection(Obj), PropName);
end;

function TPPGCollectionEditor.OwnVerbCount: Integer;
var
  PropName, Verb: string;
  Dbl: Boolean;
begin
  if CollectionProp(PropName, Verb, Dbl) then
    Result := 1
  else
    Result := 0;
end;

function TPPGCollectionEditor.OwnVerb(Index: Integer): string;
var
  PropName: string;
  Dbl: Boolean;
begin
  CollectionProp(PropName, Result, Dbl);
end;

procedure TPPGCollectionEditor.ExecuteOwnVerb(Index: Integer);
begin
  EditCollection;
end;

procedure TPPGCollectionEditor.Edit;
var
  PropName, Verb: string;
  Dbl: Boolean;
begin
  if CollectionProp(PropName, Verb, Dbl) and Dbl then
  begin
    try
      EditCollection;
    except
      ShowError(ExceptObject);
    end;
  end
  else
    inherited Edit;
end;

{ TPPGNavigationViewEditor }

destructor TPPGNavigationViewEditor.Destroy;
begin
  FreeAndNil(FPages);
  inherited Destroy;
end;

procedure TPPGNavigationViewEditor.CollectPages;
var
  Root: TComponent;
  I: Integer;
begin
  if FPages = nil then
    FPages := TList.Create;
  FPages.Clear;
  Root := Designer.GetRoot;
  if Root = nil then
    Exit;
  for I := 0 to Root.ComponentCount - 1 do
    if (Root.Components[I] is TPPGPageControl) and (FPages.Count < MaxPageVerbs) then
      FPages.Add(Root.Components[I]);
end;

function TPPGNavigationViewEditor.OwnVerbCount: Integer;
begin
  // Eintraege, je PageControl "Verbinden mit ...", ggf. "Trennen"
  CollectPages;
  Result := 1 + FPages.Count;
  if TPPGNavigationView(Component).PageControl <> nil then
    Inc(Result);
end;

function TPPGNavigationViewEditor.OwnVerb(Index: Integer): string;
begin
  if FPages = nil then
    CollectPages;
  if Index = 0 then
    Result := SVerbNavItems
  else if Index - 1 < FPages.Count then
    Result := Format(SVerbConnectPage, [TComponent(FPages[Index - 1]).Name])
  else
    Result := SVerbDisconnectPage;
end;

procedure TPPGNavigationViewEditor.ExecuteOwnVerb(Index: Integer);
var
  Nav: TPPGNavigationView;
  Dlg: TPPGNavItemsDialog;
begin
  Nav := TPPGNavigationView(Component);
  if FPages = nil then
    CollectPages;
  if Index = 0 then
  begin
    Dlg := TPPGNavItemsDialog.CreateFor(nil, Nav);
    try
      if Dlg.ShowModal = mrOk then
      begin
        Nav.Items.Assign(Dlg.View.Items);
        Designer.Modified;
      end;
    finally
      Dlg.Free;
    end;
  end
  else if Index - 1 < FPages.Count then
  begin
    Nav.PageControl := TPPGPageControl(FPages[Index - 1]);
    Designer.Modified;
  end
  else
  begin
    Nav.PageControl := nil;
    Designer.Modified;
  end;
end;

procedure TPPGNavigationViewEditor.Edit;
begin
  ExecuteVerb(0);
end;

{ TPPGTreeViewEditor }

function TPPGTreeViewEditor.OwnVerbCount: Integer;
begin
  Result := 1;
end;

function TPPGTreeViewEditor.OwnVerb(Index: Integer): string;
begin
  Result := SVerbTreeNodes;
end;

procedure TPPGTreeViewEditor.ExecuteOwnVerb(Index: Integer);
var
  Tree: TPPGTreeView;
  Dlg: TPPGTreeItemsDialog;
begin
  Tree := TPPGTreeView(Component);
  Dlg := TPPGTreeItemsDialog.CreateFor(nil, Tree);
  try
    if Dlg.ShowModal = mrOk then
    begin
      Tree.Items.Assign(Dlg.Tree.Items);
      Designer.Modified;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TPPGTreeViewEditor.Edit;
begin
  ExecuteVerb(0);
end;

{ TPPGNotificationCenterEditor }

function TPPGNotificationCenterEditor.OwnVerbCount: Integer;
begin
  Result := 1;
end;

function TPPGNotificationCenterEditor.OwnVerb(Index: Integer): string;
begin
  Result := SVerbTestToast;
end;

procedure TPPGNotificationCenterEditor.ExecuteOwnVerb(Index: Integer);
begin
  TPPGNotificationCenter(Component).Show(STestToastTitle, STestToastText, psInformational);
end;

{ TPPGRibbonEditor }

function TPPGRibbonEditor.OwnVerbCount: Integer;
begin
  Result := 6;
end;

function TPPGRibbonEditor.OwnVerb(Index: Integer): string;
begin
  case Index of
    0: Result := SVerbRibbonTabs;
    1: Result := SVerbRibbonGroups;
    2: Result := SVerbRibbonQuick;
    3: Result := SVerbRibbonNewTab;
    4: Result := SVerbRibbonNextTab;
  else
    Result := SVerbRibbonPrevTab;
  end;
end;

procedure TPPGRibbonEditor.ExecuteOwnVerb(Index: Integer);
var
  R: TPPGRibbon;
  T: TPPGRibbonTab;
  I, K, N, Dir: Integer;
begin
  if not (Component is TPPGRibbon) then
    Exit;
  R := TPPGRibbon(Component);
  case Index of
    0: ShowCollectionEditor(Designer, R, R.Tabs, 'Tabs');
    1:
      if R.ActiveTab <> nil then
        ShowCollectionEditor(Designer, R, R.ActiveTab.Groups, 'Groups');
    2: ShowCollectionEditor(Designer, R, R.QuickAccess, 'QuickAccess');
    3:
      begin
        T := R.Tabs.AddTab('Tab' + IntToStr(R.Tabs.Count + 1));
        T.Groups.AddGroup('Group1');
        R.TabIndex := T.Index;
        Designer.Modified;
      end;
    4, 5:
      begin
        // Nur sichtbare Karten; eine Kontext-Karte zum Bearbeiten im
        // Objektinspektor auf Visible = True stellen
        N := R.Tabs.Count;
        if N = 0 then
          Exit;
        if Index = 4 then
          Dir := 1
        else
          Dir := -1;
        I := R.TabIndex;
        if I < 0 then
          I := 0;
        for K := 1 to N do
        begin
          I := (I + Dir + N) mod N;
          if R.Tabs[I].Visible then
          begin
            R.TabIndex := I;
            Designer.Modified;
            Break;
          end;
        end;
      end;
  end;
end;

procedure TPPGRibbonEditor.Edit;
begin
  try
    ExecuteOwnVerb(0);
  except
    on E: Exception do
      ShowError(E);
  end;
end;

{ TPPGSelectionEditor }

procedure TPPGSelectionEditor.RequiresUnits(Proc: TGetStrProc);
var
  I: Integer;
  C: TComponent;
  NeedItems, NeedGrids, NeedComCtrls, NeedExtCtrls, NeedFeedback, NeedChart, NeedPlanner,
    NeedRibbon, NeedKanban: Boolean;
begin
  inherited RequiresUnits(Proc);
  NeedItems := False;
  NeedGrids := False;
  NeedComCtrls := False;
  NeedExtCtrls := False;
  NeedFeedback := False;
  NeedChart := False;
  NeedPlanner := False;
  NeedRibbon := False;
  NeedKanban := False;
  for I := 0 to Designer.GetRoot.ComponentCount - 1 do
  begin
    C := Designer.GetRoot.Components[I];
    if (C is TPPGCustomItemList) or (C is TPPGCustomComboBox) then
      NeedItems := True;
    if C is TPPGCustomGrid then
      NeedGrids := True;
    if (C is TPPGCustomTreeView) or (C is TPPGCustomTabs) then
      NeedComCtrls := True;
    if C is TPPGLinkLabel then
      NeedExtCtrls := True;
    if (C is TPPGNotificationCenter) or (C is TPPGInfoBar) then
      NeedFeedback := True;
    if C is TPPGCustomChart then
      NeedChart := True;
    if C is TPPGCustomPlanner then
      NeedPlanner := True;
    if C is TPPGCustomRibbon then
      NeedRibbon := True;
    if C is TPPGCustomKanban then
      NeedKanban := True;
  end;
  // Typen der Ereignis-Signaturen (z.B. TPPGCheckState, TPPGItemData,
  // TGridDrawState, TNodeAttachMode, TSysLinkType, TPPGSeverity)
  Proc('PPG.Types');
  if NeedItems then
    Proc('PPG.Items');
  if NeedGrids then
  begin
    // TGridDrawState, TPPGGridCellStyle (OnGetCellStyle), TPopupMenu (OnHeaderMenu)
    Proc('Vcl.Grids');
    Proc('PPG.Grid.Styles');
    Proc('Vcl.Menus');
  end;
  if NeedComCtrls then
    Proc('Vcl.ComCtrls');
  if NeedExtCtrls then
    Proc('Vcl.ExtCtrls');
  if NeedFeedback then
    Proc('PPG.Feedback');
  // OnGetPoint: TPPGChartPoint
  if NeedChart then
    Proc('PPG.Chart.Series');
  // Planer-Ereignisse: TPPGAppointment, TPPGAppointmentChangeKind
  if NeedPlanner then
    Proc('PPG.Planner.Model');
  // Ribbon-Ereignisse: TPPGRibbonItem, TPPGRibbonGroup, TPPGRibbonTab, TPPGItemData
  if NeedRibbon then
  begin
    Proc('PPG.Ribbon.Items');
    Proc('PPG.Items');
  end;
  // Kanban-Ereignisse: TPPGKanbanColumn, TPPGKanbanCard, TPPGKanbanCardData
  if NeedKanban then
    Proc('PPG.Kanban.Items');
end;

{ TPPGItemImageIndexProperty }

function ItemImages(P: TPersistent): TCustomImageList;
begin
  Result := PPGImagesOf(P);
end;

function TPPGItemImageIndexProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paRevertable];
end;

procedure TPPGItemImageIndexProperty.GetValues(Proc: TGetStrProc);
var
  Imgs: TCustomImageList;
  I: Integer;
begin
  Proc('-1');
  Imgs := ItemImages(GetComponent(0));
  if Imgs <> nil then
    for I := 0 to Imgs.Count - 1 do
      Proc(IntToStr(I));
end;

procedure TPPGItemImageIndexProperty.ListMeasureWidth(const Value: string; ACanvas: TCanvas;
  var AWidth: Integer);
var
  Imgs: TCustomImageList;
begin
  Imgs := ItemImages(GetComponent(0));
  if Imgs <> nil then
    AWidth := AWidth + Imgs.Width + 6;
end;

procedure TPPGItemImageIndexProperty.ListMeasureHeight(const Value: string; ACanvas: TCanvas;
  var AHeight: Integer);
var
  Imgs: TCustomImageList;
begin
  Imgs := ItemImages(GetComponent(0));
  if Imgs <> nil then
    AHeight := Max(AHeight, Imgs.Height + 2);
end;

procedure TPPGItemImageIndexProperty.ListDrawValue(const Value: string; ACanvas: TCanvas;
  const ARect: TRect; ASelected: Boolean);
var
  Imgs: TCustomImageList;
  X, Idx: Integer;
begin
  Imgs := ItemImages(GetComponent(0));
  ACanvas.FillRect(ARect);
  X := ARect.Left + 2;
  Idx := StrToIntDef(Value, -1);
  if Imgs <> nil then
  begin
    if (Idx >= 0) and (Idx < Imgs.Count) then
      Imgs.Draw(ACanvas, X, ARect.Top + (ARect.Bottom - ARect.Top - Imgs.Height) div 2, Idx);
    Inc(X, Imgs.Width + 4);
  end;
  ACanvas.TextOut(X, ARect.Top + (ARect.Bottom - ARect.Top - ACanvas.TextHeight(Value)) div 2, Value);
end;

{$IFDEF PPG_HAS_IMAGENAME}
{ TPPGItemImageNameProperty }

function TPPGItemImageNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList, paRevertable];
end;

procedure TPPGItemImageNameProperty.GetValues(Proc: TGetStrProc);
var
  Imgs: TCustomImageList;
  I: Integer;
begin
  Imgs := ItemImages(GetComponent(0));
  if (Imgs <> nil) and Imgs.IsImageNameAvailable then
    for I := 0 to Imgs.Count - 1 do
      Proc(Imgs.GetNameByIndex(I));
end;
{$ENDIF}


procedure Register;
begin
  RegisterComponents(PPGPaletteName, [TPPGButton, TPPGCheckBox, TPPGRadioButton,
    TPPGToggleSwitch, TPPGProgressBar, TPPGTrackBar, TPPGPanel, TPPGScrollBox, TPPGGroupBox, TPPGRadioGroup,
    TPPGCheckGroup,
    TPPGEdit, TPPGMemo, TPPGSpinEdit, TPPGComboBox, TPPGTabControl, TPPGPageControl,
    TPPGListBox, TPPGCheckListBox, TPPGTreeView, TPPGGrid, TPPGTileView,
    TPPGLabel, TPPGLinkLabel, TPPGBadge, TPPGProgressRing, TPPGInfoBar, TPPGExpander,
    TPPGSplitter, TPPGRating, TPPGSearchEdit, TPPGCalendar, TPPGDatePicker, TPPGTimePicker,
    TPPGNavigationView, TPPGBreadcrumb, TPPGToolBar, TPPGStatusBar, TPPGNotificationCenter,
    TPPGSparkline, TPPGGauge, TPPGKpiTile, TPPGChart, TPPGPlanner, TPPGRibbon, TPPGKanban,
    TPPGPopupMenu, TPPGMenuBar, TPPGHintManager, TPPGCustomHint, TPPGTeachingTip,
    TPPGTaskDialog, TPPGWizard, TPPGValidator, TPPGBusyOverlay,
    TPPGNumberEdit, TPPGMaskEdit, TPPGPasswordEdit, TPPGFileEdit, TPPGColorPicker,
    TPPGCheckComboBox, TPPGColumnComboBox, TPPGTagEdit,
    TPPGGridPrinter, TPPGPlannerPrinter, TPPGKanbanPrinter, TPPGStyleManager]);
  // Seiten entstehen ueber den Komponenteneditor, nicht ueber die Palette
  RegisterClass(TPPGTabSheet);
  RegisterNoIcon([TPPGTabSheet]);
  RegisterClass(TPPGWizardPage);
  RegisterNoIcon([TPPGWizardPage]);
  RegisterPropertyEditor(TypeInfo(string), TPPGCustomControl, 'Preset', TPPGPresetProperty);
  // Audit 5b: Optik der Suite in einer eigenen Kategorie
  RegisterPropertiesInCategory(PPGCategoryName, TPPGCustomControl, ['Preset', 'StyleManager',
    'Appearance', 'Animation', 'RoundedCorners', 'Shadow', 'HighContrastSupport', 'ReadOnlyStyle',
    'Styles', 'Style']);
  RegisterPropertiesInCategory(PPGCategoryName, TComponent, ['Preset', 'StyleManager']);
  // Bildindex/-name an Eintraegen und Seiten (Images des Besitzers)
  RegisterPropertyEditor(TypeInfo(TPPGImageIndex), TPPGToolItem, 'ImageIndex', TPPGItemImageIndexProperty);
  RegisterPropertyEditor(TypeInfo(TPPGImageIndex), TPPGNavItem, 'ImageIndex', TPPGItemImageIndexProperty);
  RegisterPropertyEditor(TypeInfo(TPPGImageIndex), TPPGRibbonItem, 'ImageIndex', TPPGItemImageIndexProperty);
  RegisterPropertyEditor(TypeInfo(TPPGImageIndex), TPPGStatusPanel, 'ImageIndex', TPPGItemImageIndexProperty);
  RegisterPropertyEditor(TypeInfo(TPPGImageIndex), TPPGTabSheet, 'ImageIndex', TPPGItemImageIndexProperty);
  {$IFDEF PPG_HAS_IMAGENAME}
  RegisterPropertyEditor(TypeInfo(TImageName), TPPGToolItem, 'ImageName', TPPGItemImageNameProperty);
  RegisterPropertyEditor(TypeInfo(TImageName), TPPGNavItem, 'ImageName', TPPGItemImageNameProperty);
  RegisterPropertyEditor(TypeInfo(TImageName), TPPGRibbonItem, 'ImageName', TPPGItemImageNameProperty);
  RegisterPropertyEditor(TypeInfo(TImageName), TPPGStatusPanel, 'ImageName', TPPGItemImageNameProperty);
  RegisterPropertyEditor(TypeInfo(TImageName), TPPGTabSheet, 'ImageName', TPPGItemImageNameProperty);
  {$ENDIF}
  RegisterPropertyEditor(TypeInfo(string), TPPGStyleManager, 'Preset', TPPGPresetProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGNotificationCenter, 'Preset', TPPGPresetProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGPopupMenu, 'Preset', TPPGPresetProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGHintManager, 'Preset', TPPGPresetProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGCustomHint, 'Preset', TPPGPresetProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGTeachingTip, 'Preset', TPPGPresetProperty);
  RegisterPropertyEditor(TypeInfo(string), TPPGTaskDialog, 'Preset', TPPGPresetProperty);
  // Spezifischere Klassen nach den allgemeinen registrieren (die IDE nimmt
  // den Editor der naechstliegenden Klasse)
  RegisterComponentEditor(TPPGCustomControl, TPPGComponentEditor);
  RegisterComponentEditor(TPPGStyleManager, TPPGComponentEditor);
  RegisterComponentEditor(TPPGPageControl, TPPGPageControlEditor);
  RegisterComponentEditor(TPPGTabSheet, TPPGPageControlEditor);
  RegisterComponentEditor(TPPGWizard, TPPGWizardEditor);
  RegisterComponentEditor(TPPGWizardPage, TPPGWizardEditor);
  RegisterComponentEditor(TPPGTaskDialog, TPPGTaskDialogEditor);
  RegisterComponentEditor(TPPGGridPrinter, TPPGGridPrinterEditor);
  RegisterComponentEditor(TPPGValidator, TPPGValidatorEditor);
  RegisterComponentEditor(TPPGPlannerPrinter, TPPGGridPrinterEditor);
  RegisterComponentEditor(TPPGKanbanPrinter, TPPGGridPrinterEditor);
  RegisterComponentEditor(TPPGListBox, TPPGCollectionEditor);
  RegisterComponentEditor(TPPGCheckListBox, TPPGCollectionEditor);
  RegisterComponentEditor(TPPGComboBox, TPPGCollectionEditor);
  RegisterComponentEditor(TPPGSearchEdit, TPPGCollectionEditor);
  RegisterComponentEditor(TPPGGrid, TPPGCollectionEditor);
  RegisterComponentEditor(TPPGStatusBar, TPPGCollectionEditor);
  RegisterComponentEditor(TPPGToolBar, TPPGCollectionEditor);
  RegisterComponentEditor(TPPGChart, TPPGCollectionEditor);
  RegisterComponentEditor(TPPGPlanner, TPPGCollectionEditor);
  RegisterComponentEditor(TPPGGauge, TPPGCollectionEditor);
  RegisterComponentEditor(TPPGColumnComboBox, TPPGCollectionEditor);
  RegisterComponentEditor(TPPGNavigationView, TPPGNavigationViewEditor);
  RegisterComponentEditor(TPPGRibbon, TPPGRibbonEditor);
  RegisterComponentEditor(TPPGKanban, TPPGCollectionEditor);
  RegisterComponentEditor(TPPGTreeView, TPPGTreeViewEditor);
  RegisterComponentEditor(TPPGNotificationCenter, TPPGNotificationCenterEditor);
  RegisterSelectionEditor(TPPGCustomControl, TPPGSelectionEditor);
  RegisterSelectionEditor(TPPGNotificationCenter, TPPGSelectionEditor);
end;

end.
