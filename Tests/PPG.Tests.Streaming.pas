unit PPG.Tests.Streaming;

{ DFM-Pruefung ueber ALLE Paletten-Controls (Liste wie RegisterComponents in
  PPG.Reg und PPG.DB.Reg, 70 + 21 = 91 Klassen):
  - EveryPropertySurvivesDfm: jede einfache published Property wird geaendert;
    der Setter muss den Wert uebernehmen (Wert <> vorher), danach muss er die
    DFM-Rundreise ueberstehen. Als Ablehnung eines ungueltigen Werts gilt nur
    EPPGError (Basis von EPPGPropertyError); jede andere Exception, auch eine
    Zugriffsverletzung, ist ein Fehler.
  - NestedPropertiesSurviveDfm: Set-, Klassen- und Collection-Properties (Font,
    Appearance, Styles, Columns, Items ...) werden veraendert (einfache
    Unter-Properties, Sets umgeschaltet, Collections um einen Eintrag
    erweitert), das ganze Control geht durch die Rundreise, und alle
    Property-Werte unterhalb der Property muessen gleich sein.
  DB-Controls haengen an einer Attrappen-DataSource (TClientDataSet). }

interface

uses
  TestFramework, Winapi.Windows, System.Classes, System.SysUtils, System.TypInfo, System.Variants,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Exceptions,
  PPG.Button, PPG.CheckBox, PPG.RadioButton, PPG.ToggleSwitch, PPG.ProgressBar, PPG.TrackBar,
  PPG.Panel, PPG.GroupBox, PPG.RadioGroup, PPG.TileView, PPG.Edit, PPG.Memo, PPG.SpinEdit, PPG.ComboBox, PPG.TabControl,
  PPG.PageControl, PPG.ListBox, PPG.CheckListBox, PPG.TreeView, PPG.Grid,
  PPG.Labels, PPG.Shape, PPG.Image, PPG.Feedback, PPG.Expander, PPG.Splitter, PPG.Rating, PPG.SearchEdit,
  PPG.Calendar, PPG.DatePicker, PPG.TimePicker, PPG.NavigationView, PPG.Breadcrumb,
  PPG.ToolBar, PPG.StatusBar, PPG.Notifications, PPG.Sparkline, PPG.Gauge, PPG.Chart,
  PPG.Planner, PPG.Ribbon, PPG.Kanban, PPG.Menus, PPG.MenuBar, PPG.Hints, PPG.TeachingTip,
  PPG.Dialogs, PPG.Wizard, PPG.Validator, PPG.BusyOverlay, PPG.NumberEdit, PPG.MaskEdit,
  PPG.PasswordEdit, PPG.FileEdit, PPG.ColorPicker, PPG.CheckComboBox, PPG.ColumnComboBox,
  PPG.TagEdit, PPG.Grid.Print, PPG.Planner.Print, PPG.Kanban.Print, PPG.StyleManager,
  PPG.DB.Controls, PPG.DB.Lookup, PPG.DB.Grid, PPG.DB.Chart, PPG.DB.Planner, PPG.DB.Kanban,
  PPG.DB.Fields, PPG.DB.Navigator, PPG.RichEdit, PPG.DB.RichEdit,
  PPG.Types, PPG.Appearance, PPG.Animation, PPG.Tokens, PPG.Render.Intf, PPG.Render.Registry,
  PPG.Controls.Base, PPG.Tests.Controls;

type
  /// Gemeinsame Hilfen: Attrappen-DataSource, Komponente anlegen, Rundreise
  TStreamingTestCase = class(TControlTestCase)
  protected
    FData: TClientDataSet;
    FSource: TDataSource;
    function RoundTrip(C: TComponent): TComponent;
    function NewComponent(Cls: TComponentClass): TComponent;
    procedure SetUp; override;
  end;

  TDfmStreamingTests = class(TStreamingTestCase)
  private
    function CheckNested(Cls: TComponentClass; PInfo: PPropInfo; Errors, Unchanged: TStrings): Boolean;
  published
    procedure PaletteListIsComplete;
    procedure EveryPropertySurvivesDfm;
    procedure NestedPropertiesSurviveDfm;
    procedure RatingHalfValueSurvivesDfm;
    procedure StatusBarOwnFontSurvivesDfm;
  end;

  /// In der DFM stehen nur Abweichungen vom Preset (Preset, Appearance), und
  /// die Rundreise Speichern -> Laden ergibt dieselben Werte: fuer alle
  /// Klassen und Presets, geaenderte Werte, alte DFMs mit allen Werten,
  /// geerbte Formulare (Vorfahr), Marke eines StyleManagers und den
  /// StyleManager selbst.
  TPresetStreamingTests = class(TStreamingTestCase)
  private
    function DfmText(C: TComponent): string;
    function LoadText(Cls: TComponentClass; const Text: string): TComponent;
  published
    procedure DefaultsWriteNoPresetOrAppearance;
    procedure EveryPresetWritesOnlyPresetAndSurvives;
    procedure ChangedValuesAreStoredAndSurvive;
    procedure ValueResetToPresetIsNotStored;
    procedure OldDfmWithAllValuesLoadsUnchanged;
    procedure BrandingDoesNotChangeStreaming;
    procedure InheritedFormKeepsAncestorValues;
    procedure StyleManagerWritesOnlyDifferences;
  end;

  /// Vom StyleManager verwaltete Properties (PPGIsStyleManagedProperty):
  /// Regel fuer alle Klassen mit StyleManager (Controls: Preset, Appearance,
  /// Animation; Komponenten: Preset), Mehrfachauswahl wie im Objektinspektor,
  /// Streaming (mit Manager nicht in der DFM, ohne unveraendert), alte DFMs
  /// mit solchen Werten laden weiter, Laufzeitverhalten unveraendert.
  TStyleManagedPropertyTests = class(TStreamingTestCase)
  private
    function NonDefaultPreset: string;
  published
    procedure RuleCoversEveryClassWithStyleManager;
    procedure RuleForSelectionNeedsAllManaged;
    procedure ManagedPropertiesAreNotStoredWithStyleManager;
    procedure OldDfmWithManagedValuesLoadsAndDropsThem;
    procedure RuntimeBehaviourUnchanged;
  end;

implementation

const
  // Reihenfolge wie RegisterComponents in PPG.Reg (70) und PPG.DB.Reg (21)
  ControlClasses: array[0..90] of TComponentClass = (TPPGButton, TPPGCheckBox, TPPGRadioButton,
    TPPGToggleSwitch, TPPGProgressBar, TPPGTrackBar, TPPGPanel, TPPGScrollBox, TPPGGroupBox,
    TPPGRadioGroup, TPPGCheckGroup,
    TPPGEdit, TPPGMemo, TPPGSpinEdit, TPPGComboBox, TPPGTabControl, TPPGPageControl,
    TPPGListBox, TPPGCheckListBox, TPPGTreeView, TPPGGrid, TPPGTileView,
    TPPGLabel, TPPGLinkLabel, TPPGShape, TPPGBadge, TPPGProgressRing, TPPGInfoBar, TPPGExpander,
    TPPGSplitter, TPPGRating, TPPGSearchEdit, TPPGCalendar, TPPGDatePicker, TPPGTimePicker,
    TPPGNavigationView, TPPGBreadcrumb, TPPGToolBar, TPPGStatusBar, TPPGNotificationCenter,
    TPPGSparkline, TPPGGauge, TPPGKpiTile, TPPGChart, TPPGPlanner, TPPGRibbon, TPPGKanban,
    TPPGPopupMenu, TPPGMenuBar, TPPGHintManager, TPPGCustomHint, TPPGTeachingTip,
    TPPGTaskDialog, TPPGWizard, TPPGValidator, TPPGBusyOverlay,
    TPPGNumberEdit, TPPGMaskEdit, TPPGPasswordEdit, TPPGFileEdit, TPPGColorPicker,
    TPPGCheckComboBox, TPPGColumnComboBox, TPPGTagEdit, TPPGRichEdit,
    TPPGGridPrinter, TPPGPlannerPrinter, TPPGKanbanPrinter, TPPGStyleManager, TPPGImage,
    TPPGDBEdit, TPPGDBMemo, TPPGDBCheckBox, TPPGDBComboBox,
    TPPGDBLookupComboBox, TPPGDBDatePicker, TPPGDBGrid, TPPGDBChart, TPPGDBPlanner, TPPGDBKanban,
    TPPGDBMaskEdit, TPPGDBNumberEdit, TPPGDBColorPicker, TPPGDBCheckComboBox, TPPGDBTagEdit,
    TPPGDBNavigator, TPPGDBRadioGroup, TPPGDBText, TPPGDBToggleSwitch, TPPGDBRichEdit, TPPGDBImage);

  // Dokumentierte Ausnahmen (Property-Name, gilt fuer alle Klassen) mit Grund:
  SkipProps: array[0..25] of string = (
    // Name, Lage und Groesse: Sache des Formulars, nicht der Komponente
    'Name', 'Left', 'Top', 'Width', 'Height', 'Align', 'AutoSize',
    // Preset: nur bekannte Namen gueltig, eigene Tests (TStyleTests, Phase 9)
    'Preset',
    // Eltern-Properties: der geladene Wert haengt vom (hier fehlenden) Parent ab
    'TabOrder', 'Visible', 'ParentFont', 'ParentColor', 'ParentBackground',
    'ParentShowHint', 'ParentBiDiMode', 'ParentDoubleBuffered',
    // VCL-Grundklasse, nicht Gegenstand der Suite (Andocken, Hilfe, Tag)
    'HelpContext', 'DragKind', 'DragCursor', 'DockSite', 'Tag',
    // Bildnamen werden nur mit einer ImageList mit Namen gespeichert
    'ImageName', 'HotImageName', 'DisabledImageName', 'PressedImageName',
    'ImageNameDark');

  SimpleKinds: TTypeKinds = [tkInteger, tkInt64, tkChar, tkWChar, tkEnumeration, tkFloat,
    tkUString, tkLString, tkWString];

function IsSkipped(const PName: string): Boolean;
var
  K: Integer;
begin
  Result := False;
  for K := 0 to High(SkipProps) do
    if SameText(PName, SkipProps[K]) then
      Result := True;
end;

function IsFieldProp(const PName: string): Boolean;
begin
  Result := (Length(PName) > 5) and SameText(Copy(PName, Length(PName) - 4, 5), 'Field');
end;

{ Ein Feld der Attrappe mit passendem Typ, verschieden vom bisherigen Wert:
  Datums-Controls an Datumsfelder, Zahlen an Zahlen, Farben an Ganzzahlen. }
function FieldFor(Obj: TObject; const PropName, Current: string): string;
var
  A, B: string;
begin
  if (Pos('Date', Obj.ClassName) > 0) or (Pos('Start', PropName) > 0) or
    (Pos('End', PropName) > 0) or (Pos('Due', PropName) > 0) then
  begin
    A := 'Datum';
    B := 'Datum2';
  end
  else if (Pos('Number', Obj.ClassName) > 0) or SameText(PropName, 'XField') or
    SameText(PropName, 'YField') or (Pos('Value', PropName) > 0) or (Pos('Order', PropName) > 0) then
  begin
    A := 'Wert';
    B := 'Wert2';
  end
  else if (Pos('Color', Obj.ClassName) > 0) or (Pos('Color', PropName) > 0) or
    (Pos('Key', PropName) > 0) or (Pos('Progress', PropName) > 0) then
  begin
    A := 'Farbe';
    B := 'Farbe2';
  end
  else
  begin
    A := 'Name';
    B := 'Status';
  end;
  if SameText(Current, A) then
    Result := B
  else
    Result := A;
end;

{ Statisch "stored False": der Wert gehoert absichtlich nicht ins DFM
  (DB-Werte kommen aus dem Datenfeld, Passwort, Tagesdatum des Planers). }
function IsNeverStored(PInfo: PPropInfo): Boolean;
begin
  Result := NativeUInt(PInfo^.StoredProc) = 0;
end;

procedure FillList(C: TComponent; const PropName: string);
var
  Obj: TObject;
  I: Integer;
begin
  if GetPropInfo(C, PropName) = nil then
    Exit;
  Obj := GetObjectProp(C, PropName);
  if Obj is TStrings then
  begin
    TStrings(Obj).Clear;
    TStrings(Obj).Add('Xy');
    for I := 1 to 5 do
      TStrings(Obj).Add('Eintrag ' + IntToStr(I));
  end
  else if Obj is TCollection then
    for I := 1 to 6 do
      TCollection(Obj).Add;
end;

{ Abhaengige Properties brauchen einen passenden Zustand, sonst ist "nicht
  uebernommen" das fachlich richtige Verhalten:
  - ItemIndex/TabIndex/SelectedIndex/CheckedText: nur mit Eintraegen waehlbar;
  - Down: nur an einem Button mit GroupIndex (wie TSpeedButton);
  - ItemCount: nur virtuell (OwnerData, wie TListView). }
procedure Prepare(C: TComponent; const PName: string);
begin
  if SameText(PName, 'ItemIndex') or SameText(PName, 'TabIndex') or SameText(PName, 'SelectedIndex') or
    SameText(PName, 'CheckedText') then
  begin
    FillList(C, 'Items');
    FillList(C, 'Tabs');
  end
  else if SameText(PName, 'Down') and (GetPropInfo(C, 'GroupIndex') <> nil) then
    SetOrdProp(C, 'GroupIndex', 1)
  else if SameText(PName, 'ItemCount') and (GetPropInfo(C, 'OwnerData') <> nil) then
    SetOrdProp(C, 'OwnerData', 1);
end;

{ Setzt einen anderen gueltig aussehenden Wert. Exceptions laufen durch. }
procedure MutateSimple(Obj: TObject; PInfo: PPropInfo);
var
  TD: PTypeData;
  K: Int64;
  S: string;
  Ch: Integer;
begin
  // Properties mit Wertebereich bzw. Format: ein gueltiger, vom Vorgabewert
  // verschiedener Wert (sonst prueft der Test nur die Ablehnung)
  S := string(PInfo^.Name);
  if SameText(S, 'ValuesText') or SameText(S, 'SparklineText') then
  begin
    SetStrProp(Obj, PInfo, '3;1.5;4;1');
    Exit;
  end;
  if SameText(S, 'DayEndHour') then
  begin
    SetOrdProp(Obj, PInfo, 20);
    Exit;
  end;
  if SameText(S, 'SlotMinutes') then
  begin
    SetOrdProp(Obj, PInfo, 15);
    Exit;
  end;
  if SameText(S, 'TimeZone') then
  begin
    SetStrProp(Obj, PInfo, 'Europe/Berlin');
    Exit;
  end;
  case PInfo^.PropType^.Kind of
    tkEnumeration:
      begin
        TD := GetTypeData(PInfo^.PropType^);
        K := GetOrdProp(Obj, PInfo) + 1;
        if K > TD^.MaxValue then
          K := TD^.MinValue;
        SetOrdProp(Obj, PInfo, K);
      end;
    tkInteger:
      if PInfo^.PropType^ = TypeInfo(TColor) then
        SetOrdProp(Obj, PInfo, $123456)
      else
        SetOrdProp(Obj, PInfo, GetOrdProp(Obj, PInfo) + 3);
    tkInt64:
      SetInt64Prop(Obj, PInfo, GetInt64Prop(Obj, PInfo) + 3);
    tkChar, tkWChar:
      begin
        Ch := GetOrdProp(Obj, PInfo);
        if Ch = Ord('*') then
          Ch := Ord('#')
        else
          Ch := Ord('*');
        SetOrdProp(Obj, PInfo, Ch);
      end;
    tkFloat:
      SetFloatProp(Obj, PInfo, GetFloatProp(Obj, PInfo) + 2.5);
  else
    begin
      S := GetStrProp(Obj, PInfo);
      // Feldnamen an DB-Controls: ein Feld der Attrappe statt eines Phantasienamens
      if IsFieldProp(string(PInfo^.Name)) then
        S := FieldFor(Obj, string(PInfo^.Name), S)
      else
        S := S + 'Xy';
      SetStrProp(Obj, PInfo, S);
    end;
  end;
end;

{ Schaltet das erste Element des Sets um. }
procedure MutateSet(Obj: TObject; PInfo: PPropInfo);
var
  CompType: PTypeInfo;
  First, S, Inner: string;
  L: TStringList;
  I: Integer;
begin
  CompType := GetTypeData(PInfo^.PropType^)^.CompType^;
  if CompType^.Kind = tkEnumeration then
    First := GetEnumName(CompType, GetTypeData(CompType)^.MinValue)
  else
    First := IntToStr(GetTypeData(CompType)^.MinValue);
  S := GetSetProp(Obj, PInfo, False);
  L := TStringList.Create;
  try
    L.CommaText := S;
    I := L.IndexOf(First);
    if I >= 0 then
      L.Delete(I)
    else
      L.Add(First);
    Inner := L.CommaText;
  finally
    L.Free;
  end;
  SetSetProp(Obj, PInfo, Inner);
end;

{ Veraendert ein Unterobjekt: einfache Properties, Sets, Collections, Strings,
  verschachtelte Objekte. Ablehnungen (EPPGError) werden uebergangen; alle
  anderen Exceptions landen in Errors. }
procedure MutateObject(Obj: TObject; const Path: string; Depth: Integer; Errors: TStrings);
var
  Root, Node: TPPGTreeNode;
  N, P: Integer;
  Props: PPropList;
  PInfo: PPropInfo;
  PName: string;
  Sub: TObject;
  Item: TCollectionItem;
begin
  if (Obj = nil) or (Depth > 3) then
    Exit;
  if Obj is TCollection then
  begin
    try
      Item := TCollection(Obj).Add;
      MutateObject(Item, Path + '[neu]', Depth + 1, Errors);
    except
      on E: EPPGError do ;
      on E: Exception do
        Errors.Add(Format('%s.Add: %s: %s', [Path, E.ClassName, E.Message]));
    end;
    Exit;
  end;
  if Obj is TStrings then
  begin
    TStrings(Obj).Add('ZeileXy');
    Exit;
  end;
  if Obj is TPPGTreeNodes then
  begin
    // Knoten stehen ueber DefineProperties im DFM, nicht als published Properties
    Root := TPPGTreeNodes(Obj).Add(nil, 'Wurzel|mit Trenner');
    Root.Detail := 'Detail';
    Node := TPPGTreeNodes(Obj).AddChild(Root, 'Kind');
    Node.Badge := '3';
    Node.ImageIndex := 2;
    Node.SelectedIndex := 4;
    Node.CheckState := cbChecked;
    Node.Enabled := False;
    Root.Expanded := True;
    Exit;
  end;
  if Obj is TPicture then
  begin
    TPicture(Obj).Bitmap.SetSize(5, 3);
    TPicture(Obj).Bitmap.Canvas.Brush.Color := clRed;
    TPicture(Obj).Bitmap.Canvas.FillRect(Rect(0, 0, 5, 3));
    Exit;
  end;
  if Obj is TIcon then
  begin
    TIcon(Obj).Handle := CopyIcon(LoadIcon(0, IDI_WARNING));
    Exit;
  end;
  // GetPropList laesst Props bei 0 Properties unbelegt (out-Parameter)
  Props := nil;
  N := GetPropList(PTypeInfo(Obj.ClassInfo), Props);
  try
    for P := 0 to N - 1 do
    begin
      PInfo := Props[P];
      PName := string(PInfo^.Name);
      // VirtualCount > 0 schaltet das Speichern der eigenen Punkte einer Serie
      // absichtlich ab (Daten kommen aus OnGetPoint); eigener Test in Phase 10d
      if SameText(PName, 'VirtualCount') then
        Continue;
      if IsSkipped(PName) or (PInfo^.GetProc = nil) or IsNeverStored(PInfo) then
        Continue;
      try
        if PInfo^.PropType^.Kind = tkClass then
        begin
          Sub := GetObjectProp(Obj, PInfo);
          if (Sub is TComponent) and not (csSubComponent in TComponent(Sub).ComponentStyle) then
            Continue; // Verweis auf eine andere Komponente
          MutateObject(Sub, Path + '.' + PName, Depth + 1, Errors);
        end
        else if PInfo^.SetProc = nil then
          Continue
        else if PInfo^.PropType^.Kind = tkSet then
          MutateSet(Obj, PInfo)
        else if PInfo^.PropType^.Kind in SimpleKinds then
          MutateSimple(Obj, PInfo);
      except
        on E: EPPGError do ;
        on E: Exception do
          Errors.Add(Format('%s.%s: Setzen wirft %s: %s', [Path, PName, E.ClassName, E.Message]));
      end;
    end;
  finally
    FreeMem(Props);
  end;
end;

{ Schreibt alle Werte unterhalb von Obj als "Pfad=Wert" in Dump. }
procedure DumpObject(Obj: TObject; const Path: string; Depth: Integer; Dump: TStrings);
var
  Node: TPPGTreeNode;
  N, P, I: Integer;
  Props: PPropList;
  PInfo: PPropInfo;
  PName: string;
  Sub: TObject;
begin
  if Obj = nil then
  begin
    Dump.Add(Path + '=nil');
    Exit;
  end;
  if Depth > 4 then
    Exit;
  if Obj is TCollection then
  begin
    Dump.Add(Path + '.Count=' + IntToStr(TCollection(Obj).Count));
    for I := 0 to TCollection(Obj).Count - 1 do
      DumpObject(TCollection(Obj).Items[I], Path + '[' + IntToStr(I) + ']', Depth + 1, Dump);
    Exit;
  end;
  if Obj is TStrings then
  begin
    Dump.Add(Path + '.Text=' + TStrings(Obj).Text);
    Exit;
  end;
  if Obj is TPPGTreeNodes then
  begin
    Dump.Add(Path + '.Count=' + IntToStr(TPPGTreeNodes(Obj).Count));
    for I := 0 to TPPGTreeNodes(Obj).Count - 1 do
    begin
      Node := TPPGTreeNodes(Obj).Item[I];
      Dump.Add(Format('%s[%d]=%d|%s|%s|%s|%d|%d|%d|%s|%s', [Path, I, Node.Level, Node.Text,
        Node.Detail, Node.Badge, Node.ImageIndex, Node.SelectedIndex, Ord(Node.CheckState),
        BoolToStr(Node.Expanded, True), BoolToStr(Node.Enabled, True)]));
    end;
    Exit;
  end;
  if Obj is TPicture then
  begin
    // TPicture hat keine published Properties: der Inhalt zaehlt
    if TPicture(Obj).Graphic = nil then
      Dump.Add(Path + '=nil')
    else
      Dump.Add(Format('%s=%dx%d', [Path, TPicture(Obj).Width, TPicture(Obj).Height]));
    Exit;
  end;
  if Obj is TGraphic then
  begin
    Dump.Add(Format('%s=%s %dx%d', [Path, BoolToStr(TGraphic(Obj).Empty, True), TGraphic(Obj).Width,
      TGraphic(Obj).Height]));
    Exit;
  end;
  // GetPropList laesst Props bei 0 Properties unbelegt (out-Parameter)
  Props := nil;
  N := GetPropList(PTypeInfo(Obj.ClassInfo), Props);
  try
    for P := 0 to N - 1 do
    begin
      PInfo := Props[P];
      PName := string(PInfo^.Name);
      if IsSkipped(PName) or (PInfo^.GetProc = nil) or IsNeverStored(PInfo) then
        Continue;
      if PInfo^.PropType^.Kind = tkClass then
      begin
        Sub := GetObjectProp(Obj, PInfo);
        if (Sub is TComponent) and not (csSubComponent in TComponent(Sub).ComponentStyle) then
          Continue;
        DumpObject(Sub, Path + '.' + PName, Depth + 1, Dump);
      end
      else if PInfo^.SetProc = nil then
        Continue
      else if PInfo^.PropType^.Kind = tkSet then
        Dump.Add(Path + '.' + PName + '=' + GetSetProp(Obj, PInfo, True))
      else if PInfo^.PropType^.Kind in SimpleKinds then
        Dump.Add(Path + '.' + PName + '=' + VarToStr(GetPropValue(Obj, PName, True)));
    end;
  finally
    FreeMem(Props);
  end;
end;

{ TStreamingTestCase }

procedure TStreamingTestCase.SetUp;
begin
  inherited SetUp;
  FData := TClientDataSet.Create(FForm);
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Name', ftString, 40);
  FData.FieldDefs.Add('Status', ftString, 20);
  FData.FieldDefs.Add('Datum', ftDateTime);
  FData.FieldDefs.Add('Wert', ftFloat);
  FData.FieldDefs.Add('Datum2', ftDateTime);
  FData.FieldDefs.Add('Wert2', ftFloat);
  FData.FieldDefs.Add('Farbe', ftInteger);
  FData.FieldDefs.Add('Farbe2', ftInteger);
  FData.CreateDataSet;
  FData.AppendRecord([1, 'Anna', 'todo', EncodeDate(2026, 3, 2), 1.5, EncodeDate(2026, 4, 1), 7.25,
    clRed, clBlue]);
  FData.AppendRecord([2, 'Bernd', 'done', EncodeDate(2026, 3, 3), 2.5, EncodeDate(2026, 4, 2), 8.5,
    clGreen, clYellow]);
  FData.First;
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
end;

function TStreamingTestCase.NewComponent(Cls: TComponentClass): TComponent;
var
  PInfo: PPropInfo;
begin
  Result := Cls.Create(FForm);
  if Result is TControl then
    TControl(Result).Parent := FForm;
  PInfo := GetPropInfo(Result, 'DataSource');
  if (PInfo <> nil) and (PInfo^.PropType^.Kind = tkClass) then
    SetObjectProp(Result, PInfo, FSource);
end;

function TStreamingTestCase.RoundTrip(C: TComponent): TComponent;
var
  M: TMemoryStream;
begin
  M := TMemoryStream.Create;
  try
    M.WriteComponent(C);
    M.Position := 0;
    // wie beim Laden eines Formulars: Parent steht, bevor die Properties kommen
    Result := NewComponent(TComponentClass(C.ClassType));
    try
      M.ReadComponent(Result);
    except
      Result.Free;
      raise;
    end;
  finally
    M.Free;
  end;
end;

{ TDfmStreamingTests }

procedure TDfmStreamingTests.PaletteListIsComplete;
var
  I, J: Integer;
begin
  // 91 verschiedene Klassen; doppelt eingetragene wuerden eine fehlende verdecken
  CheckEquals(91, Length(ControlClasses));
  for I := 0 to High(ControlClasses) do
    for J := I + 1 to High(ControlClasses) do
      CheckFalse(ControlClasses[I] = ControlClasses[J], ControlClasses[I].ClassName + ' doppelt');
end;

procedure TDfmStreamingTests.EveryPropertySurvivesDfm;
var
  CI, P, N, Checked, Total: Integer;
  Props: PPropList;
  PInfo: PPropInfo;
  C, C2: TComponent;
  Before, Want, Got, PName: string;
  Errors, Rejected, NoProps, NotStored: TStringList;
begin
  Errors := TStringList.Create;
  Rejected := TStringList.Create;
  NoProps := TStringList.Create;
  NotStored := TStringList.Create;
  try
    Total := 0;
    for CI := 0 to High(ControlClasses) do
    begin
      RegisterClass(TPersistentClass(ControlClasses[CI]));
      Checked := 0;
      N := GetPropList(ControlClasses[CI].ClassInfo, SimpleKinds, nil);
      GetMem(Props, N * SizeOf(PPropInfo));
      try
        GetPropList(ControlClasses[CI].ClassInfo, SimpleKinds, Props);
        for P := 0 to N - 1 do
        begin
          PInfo := Props[P];
          PName := string(PInfo^.Name);
          if (PInfo^.SetProc = nil) or IsSkipped(PName) then
            Continue;
          C := NewComponent(ControlClasses[CI]);
          try
            Prepare(C, PName);
            Before := VarToStr(GetPropValue(C, PName, True));
            try
              MutateSimple(C, PInfo);
            except
              on E: EPPGError do
              begin
                // dokumentierte Ablehnung eines ungueltigen Werts
                Rejected.Add(C.ClassName + '.' + PName);
                Continue;
              end;
              on E: Exception do
              begin
                Errors.Add(Format('%s.%s: Setzen wirft %s: %s', [C.ClassName, PName, E.ClassName, E.Message]));
                Continue;
              end;
            end;
            Want := VarToStr(GetPropValue(C, PName, True));
            if IsNeverStored(PInfo) then
            begin
              // stored False: absichtlich nicht im DFM; an DB-Controls kommt der
              // Wert aus dem Datenfeld (eigene Tests in Phase 14/Audit11C)
              NotStored.Add(C.ClassName + '.' + PName);
              Continue;
            end;
            if Want = Before then
            begin
              Errors.Add(Format('%s.%s: Setter uebernimmt den Wert nicht (bleibt %s)',
                [C.ClassName, PName, Before]));
              Continue;
            end;
            Inc(Checked);
            try
              C2 := RoundTrip(C);
            except
              on E: Exception do
              begin
                Errors.Add(Format('%s.%s: Rundreise wirft %s: %s', [C.ClassName, PName, E.ClassName, E.Message]));
                Continue;
              end;
            end;
            try
              Got := VarToStr(GetPropValue(C2, PName, True));
              if Got <> Want then
                Errors.Add(Format('%s.%s: gesetzt %s, geladen %s', [C.ClassName, PName, Want, Got]));
            finally
              C2.Free;
            end;
          finally
            C.Free;
          end;
        end;
      finally
        FreeMem(Props);
      end;
      Inc(Total, Checked);
      if Checked = 0 then
        NoProps.Add(ControlClasses[CI].ClassName);
    end;
    if Rejected.Count > 0 then
      Status('abgelehnte Werte (EPPGError): ' + Rejected.CommaText);
    Status(Format('%d einfache Properties in %d Klassen geprueft', [Total, Length(ControlClasses)]));
    Status('stored False (nicht im DFM): ' + NotStored.CommaText);
    CheckEquals('', NoProps.CommaText, 'Controls ohne gepruefte Property');
    CheckEquals('', Errors.Text, Errors.Text);
  finally
    NotStored.Free;
    NoProps.Free;
    Rejected.Free;
    Errors.Free;
  end;
end;

{ Werte einer Property des Controls (Set oder Unterobjekt) als "Pfad=Wert". }
procedure DumpProperty(C: TObject; const Path: string; PInfo: PPropInfo; Dump: TStrings);
begin
  Dump.Clear;
  if PInfo^.PropType^.Kind = tkSet then
    Dump.Add(Path + '=' + GetSetProp(C, PInfo, True))
  else
    DumpObject(GetObjectProp(C, PInfo), Path, 1, Dump);
end;

function TDfmStreamingTests.CheckNested(Cls: TComponentClass; PInfo: PPropInfo;
  Errors, Unchanged: TStrings): Boolean;
var
  I: Integer;
  C, C2, Fresh: TComponent;
  Path: string;
  Sub: TObject;
  DumpC, DumpC2, DumpFresh: TStringList;
begin
  Result := False;
  Path := Cls.ClassName + '.' + string(PInfo^.Name);
  DumpC := TStringList.Create;
  DumpC2 := TStringList.Create;
  DumpFresh := TStringList.Create;
  C := NewComponent(Cls);
  try
    if PInfo^.PropType^.Kind = tkClass then
    begin
      Sub := GetObjectProp(C, PInfo);
      if (Sub = nil) or ((Sub is TComponent) and
        not (csSubComponent in TComponent(Sub).ComponentStyle)) then
        Exit; // Verweis auf eine andere Komponente, kein eigener Inhalt
    end;
    Fresh := NewComponent(Cls);
    try
      DumpProperty(Fresh, Path, PInfo, DumpFresh);
    finally
      Fresh.Free;
    end;
    if PInfo^.PropType^.Kind = tkSet then
    begin
      try
        MutateSet(C, PInfo);
      except
        on E: EPPGError do
          Exit; // dokumentierte Ablehnung
        on E: Exception do
        begin
          Errors.Add(Format('%s: Setzen wirft %s: %s', [Path, E.ClassName, E.Message]));
          Exit;
        end;
      end;
    end
    else
      MutateObject(GetObjectProp(C, PInfo), Path, 1, Errors);
    DumpProperty(C, Path, PInfo, DumpC);
    if DumpC.Text = DumpFresh.Text then
    begin
      Unchanged.Add(Path);
      Exit;
    end;
    Result := True;
    try
      C2 := RoundTrip(C);
    except
      on E: Exception do
      begin
        Errors.Add(Format('%s: Rundreise wirft %s: %s', [Path, E.ClassName, E.Message]));
        Exit;
      end;
    end;
    try
      DumpProperty(C2, Path, PInfo, DumpC2);
      for I := 0 to DumpC.Count - 1 do
        if DumpC2.IndexOf(DumpC[I]) < 0 then
          Errors.Add('gesetzt ' + DumpC[I] + ', nach dem Laden fehlt der Wert');
      if DumpC.Count <> DumpC2.Count then
        Errors.Add(Format('%s: %d Werte gesetzt, %d geladen', [Path, DumpC.Count, DumpC2.Count]));
    finally
      C2.Free;
    end;
  finally
    C.Free;
    DumpFresh.Free;
    DumpC2.Free;
    DumpC.Free;
  end;
end;

procedure TDfmStreamingTests.NestedPropertiesSurviveDfm;
var
  CI, P, N, Checked: Integer;
  Props: PPropList;
  PInfo: PPropInfo;
  PName: string;
  Errors, Unchanged: TStringList;
begin
  Errors := TStringList.Create;
  Unchanged := TStringList.Create;
  try
    Checked := 0;
    for CI := 0 to High(ControlClasses) do
    begin
      RegisterClass(TPersistentClass(ControlClasses[CI]));
      N := GetPropList(ControlClasses[CI].ClassInfo, [tkClass, tkSet], nil);
      GetMem(Props, N * SizeOf(PPropInfo));
      try
        GetPropList(ControlClasses[CI].ClassInfo, [tkClass, tkSet], Props);
        for P := 0 to N - 1 do
        begin
          PInfo := Props[P];
          PName := string(PInfo^.Name);
          if IsSkipped(PName) or (PInfo^.GetProc = nil) or IsNeverStored(PInfo) then
            Continue;
          if (PInfo^.PropType^.Kind = tkSet) and (PInfo^.SetProc = nil) then
            Continue;
          try
            if CheckNested(ControlClasses[CI], PInfo, Errors, Unchanged) then
              Inc(Checked);
          except
            // Fehlschlag einer Pruefung sofort melden; alle anderen Fehler
            // (auch Zugriffsverletzungen) sammeln und unten pruefen
            on ETestFailure do
              raise;
            on E: Exception do
              Errors.Add(Format('%s.%s: %s: %s', [ControlClasses[CI].ClassName, PName, E.ClassName,
                E.Message]));
          end;
        end;
      finally
        FreeMem(Props);
      end;
    end;
    Status(Format('%d Set-/Klassen-/Collection-Properties geprueft', [Checked]));
    CheckEquals('', Unchanged.CommaText, 'Aenderung ohne Wirkung (Setter nimmt nichts an)');
    CheckEquals('', Errors.Text, Errors.Text);
  finally
    Unchanged.Free;
    Errors.Free;
  end;
end;

procedure TDfmStreamingTests.RatingHalfValueSurvivesDfm;
var
  R, R2: TPPGRating;
begin
  // Value steht im DFM vor AllowHalf: darf beim Laden nicht gerundet werden
  R := TPPGRating.Create(FForm);
  R.Parent := FForm;
  R.AllowHalf := True;
  R.Max := 10;
  R.Value := 7.5;
  R2 := RoundTrip(R) as TPPGRating;
  try
    CheckEquals(7.5, R2.Value, 0);
    CheckEquals(10, R2.Max);
  finally
    R2.Free;
  end;
end;

procedure TDfmStreamingTests.StatusBarOwnFontSurvivesDfm;
var
  S, S2: TPPGStatusBar;
begin
  S := TPPGStatusBar.Create(FForm);
  S.Parent := FForm;
  CheckTrue(S.UseSystemFont);
  S.Font.Size := 16;
  CheckFalse(S.UseSystemFont, 'eigene Schrift schaltet die Systemschrift ab (wie TStatusBar)');
  S2 := RoundTrip(S) as TPPGStatusBar;
  try
    CheckEquals(16, S2.Font.Size);
    CheckFalse(S2.UseSystemFont);
  finally
    S2.Free;
  end;
  S.UseSystemFont := True;
  CheckEquals(Screen.MessageFont.Size, S.Font.Size, 'zurueck zur Systemschrift');
  CheckTrue(S.UseSystemFont);
  S2 := RoundTrip(S) as TPPGStatusBar;
  try
    CheckTrue(S2.UseSystemFont);
    CheckEquals(Screen.MessageFont.Size, S2.Font.Size);
  finally
    S2.Free;
  end;
end;

{ TPresetStreamingTests }

const
  StateNames: array[0..4] of string = ('Normal', 'Hot', 'Down', 'Disabled', 'Checked');
  StateProps: array[0..7] of string = ('Color', 'ColorTo', 'ColorMirror', 'ColorMirrorTo',
    'BorderColor', 'GlowColor', 'GlowAlpha', 'TextColor');

function AppearanceOf(C: TObject): TPPGAppearance;
var
  PInfo: PPropInfo;
begin
  Result := nil;
  PInfo := GetPropInfo(C, 'Appearance');
  if (PInfo <> nil) and (PInfo^.PropType^.Kind = tkClass) and
    (GetObjectProp(C, PInfo) is TPPGAppearance) then
    Result := TPPGAppearance(GetObjectProp(C, PInfo));
end;

function BinaryToText(M: TStream): string;
var
  T: TStringStream;
begin
  M.Position := 0;
  T := TStringStream.Create('', TEncoding.UTF8);
  try
    ObjectBinaryToText(M, T);
    Result := T.DataString;
  finally
    T.Free;
  end;
end;

{ Zeilen, die (ohne Einrueckung) mit Prefix beginnen }
function DfmLines(const Text, Prefix: string): TStringList;
var
  All: TStringList;
  I: Integer;
  L: string;
begin
  Result := TStringList.Create;
  All := TStringList.Create;
  try
    All.Text := Text;
    for I := 0 to All.Count - 1 do
    begin
      L := Trim(All[I]);
      if SameText(Copy(L, 1, Length(Prefix)), Prefix) then
        Result.Add(L);
    end;
  finally
    All.Free;
  end;
end;

function LineIndex(const Text, Prefix: string): Integer;
var
  All: TStringList;
  I: Integer;
begin
  Result := -1;
  All := TStringList.Create;
  try
    All.Text := Text;
    for I := 0 to All.Count - 1 do
      if SameText(Copy(Trim(All[I]), 1, Length(Prefix)), Prefix) then
        Exit(I);
  finally
    All.Free;
  end;
end;

function OtherColor(C: TColor): TColor;
begin
  if C = $00123456 then
    Result := $00654321
  else
    Result := $00123456;
end;

{ Alle Appearance-Werte so, wie fruehere Versionen sie geschrieben haben
  (jede Farbe, jede Glow-Staerke, Richtung und die Masse) }
procedure AddAllAppearanceLines(A: TPPGAppearance; Lines: TStrings);
var
  S, P: Integer;
  St: TObject;
begin
  for S := 0 to High(StateNames) do
  begin
    St := GetObjectProp(A, StateNames[S]);
    for P := 0 to High(StateProps) do
      Lines.Add(Format('  Appearance.%s.%s = %d', [StateNames[S], StateProps[P],
        GetOrdProp(St, StateProps[P])]));
    Lines.Add(Format('  Appearance.%s.GradientDirection = %s', [StateNames[S],
      GetEnumProp(St, 'GradientDirection')]));
  end;
  Lines.Add(Format('  Appearance.FocusColor = %d', [Integer(A.FocusColor)]));
  Lines.Add(Format('  Appearance.Rounding = %d', [A.Rounding]));
  Lines.Add(Format('  Appearance.BorderWidth = %d', [A.BorderWidth]));
  Lines.Add(Format('  Appearance.GlowSize = %d', [A.GlowSize]));
end;

function TPresetStreamingTests.DfmText(C: TComponent): string;
var
  M: TMemoryStream;
begin
  M := TMemoryStream.Create;
  try
    M.WriteComponent(C);
    Result := BinaryToText(M);
  finally
    M.Free;
  end;
end;

function TPresetStreamingTests.LoadText(Cls: TComponentClass; const Text: string): TComponent;
var
  T: TStringStream;
  M: TMemoryStream;
begin
  T := TStringStream.Create(Text, TEncoding.UTF8);
  M := TMemoryStream.Create;
  try
    ObjectTextToBinary(T, M);
    M.Position := 0;
    Result := NewComponent(Cls);
    try
      M.ReadComponent(Result);
    except
      Result.Free;
      raise;
    end;
  finally
    M.Free;
    T.Free;
  end;
end;

procedure TPresetStreamingTests.DefaultsWriteNoPresetOrAppearance;
var
  CI, Count: Integer;
  C: TComponent;
  Text: string;
  L, Errors: TStringList;
begin
  Errors := TStringList.Create;
  try
    Count := 0;
    for CI := 0 to High(ControlClasses) do
    begin
      RegisterClass(TPersistentClass(ControlClasses[CI]));
      C := NewComponent(ControlClasses[CI]);
      try
        if AppearanceOf(C) = nil then
          Continue;
        Inc(Count);
        Text := DfmText(C);
        if (C is TPPGButton) or (C is TPPGDBNavigator) then
          Status(Format('%s: %d DFM-Zeilen', [C.ClassName, Length(Text.Split([#10])) - 1]));
        L := DfmLines(Text, 'Appearance.');
        try
          if L.Count > 0 then
            Errors.Add(Format('%s: %d Appearance-Zeilen (%s)', [C.ClassName, L.Count, L[0]]));
        finally
          L.Free;
        end;
        if LineIndex(Text, 'Preset ') >= 0 then
          Errors.Add(C.ClassName + ': Standard-Preset gespeichert');
      finally
        C.Free;
      end;
    end;
    Status(Format('%d Klassen mit Appearance: ohne Preset- und Appearance-Zeilen', [Count]));
    CheckTrue(Count > 60, 'zu wenige Klassen mit Appearance');
    CheckEquals('', Errors.Text, Errors.Text);
  finally
    Errors.Free;
  end;
end;

procedure TPresetStreamingTests.EveryPresetWritesOnlyPresetAndSurvives;
var
  Names, Errors, L: TStringList;
  N, CI, Checked: Integer;
  C, C2: TComponent;
  Text: string;
begin
  Names := TStringList.Create;
  Errors := TStringList.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    CheckTrue(Names.Count >= 3, 'Presets Classic, ModernFlat, Fluent11');
    Checked := 0;
    for N := 0 to Names.Count - 1 do
      for CI := 0 to High(ControlClasses) do
      begin
        RegisterClass(TPersistentClass(ControlClasses[CI]));
        C := NewComponent(ControlClasses[CI]);
        try
          if AppearanceOf(C) = nil then
            Continue;
          SetStrProp(C, 'Preset', Names[N]);
          Text := DfmText(C);
          L := DfmLines(Text, 'Appearance.');
          try
            if L.Count > 0 then
              Errors.Add(Format('%s/%s: %d Appearance-Zeilen (%s)', [C.ClassName, Names[N],
                L.Count, L[0]]));
          finally
            L.Free;
          end;
          if not SameText(Names[N], TPPGRendererRegistry.DefaultName) and
            (Pos('Preset = ''' + Names[N] + '''', Text) = 0) then
            Errors.Add(Format('%s/%s: Preset fehlt in der DFM', [C.ClassName, Names[N]]));
          C2 := RoundTrip(C);
          try
            Inc(Checked);
            if GetStrProp(C2, 'Preset') <> Names[N] then
              Errors.Add(Format('%s/%s: geladen Preset %s', [C.ClassName, Names[N],
                GetStrProp(C2, 'Preset')]));
            if not AppearanceOf(C2).Equals(AppearanceOf(C)) then
              Errors.Add(Format('%s/%s: Appearance nach dem Laden anders', [C.ClassName, Names[N]]));
          finally
            C2.Free;
          end;
        finally
          C.Free;
        end;
      end;
    Status(Format('%d Rundreisen (Klasse x Preset)', [Checked]));
    CheckEquals('', Errors.Text, Errors.Text);
  finally
    Errors.Free;
    Names.Free;
  end;
end;

procedure TPresetStreamingTests.ChangedValuesAreStoredAndSurvive;
var
  Names, Errors, L, Want: TStringList;
  N, CI, I: Integer;
  C, C2: TComponent;
  A, D: TPPGAppearance;
  Text: string;
begin
  Names := TStringList.Create;
  Errors := TStringList.Create;
  Want := TStringList.Create;
  D := TPPGAppearance.Create(nil);
  try
    TPPGRendererRegistry.GetNames(Names);
    Want.Add('Appearance.Normal.Color');
    Want.Add('Appearance.Hot.GlowAlpha');
    Want.Add('Appearance.Checked.GradientDirection');
    Want.Add('Appearance.Rounding');
    Want.Add('Appearance.FocusColor');
    Want.Add('Appearance.Focused.Color');
    Want.Add('Appearance.Dark.Normal.TextColor');
    Want.Sort;
    for N := 0 to Names.Count - 1 do
    begin
      PPGApplyStreamDefaults(TPPGRendererRegistry.Get(Names[N]), D);
      for CI := 0 to High(ControlClasses) do
      begin
        RegisterClass(TPersistentClass(ControlClasses[CI]));
        C := NewComponent(ControlClasses[CI]);
        try
          A := AppearanceOf(C);
          if A = nil then
            Continue;
          SetStrProp(C, 'Preset', Names[N]);
          // Vom Anwender geaenderte Werte (je eine Art: Farbe, Glow, Richtung,
          // Mass, Fokusfarbe, eigene Fokus- und Dunkel-Farbe)
          A.Normal.Color := OtherColor(D.Normal.Color);
          A.Hot.GlowAlpha := (D.Hot.GlowAlpha + 1) mod 256;
          A.Checked.GradientDirection := gdHorizontal;
          A.Rounding := D.Rounding + 5;
          A.FocusColor := OtherColor(D.FocusColor);
          A.Focused.Color := clRed;
          A.Dark.Normal.TextColor := clYellow;
          Text := DfmText(C);
          L := DfmLines(Text, 'Appearance.');
          try
            for I := 0 to L.Count - 1 do
              L[I] := Trim(Copy(L[I], 1, Pos('=', L[I]) - 1));
            L.Sort;
            if L.Text <> Want.Text then
              Errors.Add(Format('%s/%s: gespeichert %s, erwartet %s', [C.ClassName, Names[N],
                L.CommaText, Want.CommaText]));
          finally
            L.Free;
          end;
          if not SameText(Names[N], TPPGRendererRegistry.DefaultName) and
            (LineIndex(Text, 'Preset ') > LineIndex(Text, 'Appearance.')) then
            Errors.Add(Format('%s/%s: Preset steht nach Appearance', [C.ClassName, Names[N]]));
          C2 := RoundTrip(C);
          try
            if not AppearanceOf(C2).Equals(A) then
              Errors.Add(Format('%s/%s: Appearance nach dem Laden anders', [C.ClassName, Names[N]]));
          finally
            C2.Free;
          end;
        finally
          C.Free;
        end;
      end;
    end;
    CheckEquals('', Errors.Text, Errors.Text);
  finally
    D.Free;
    Want.Free;
    Errors.Free;
    Names.Free;
  end;
end;

procedure TPresetStreamingTests.ValueResetToPresetIsNotStored;
var
  B, B2: TPPGButton;
  Text: string;
begin
  B := NewButton;
  B.Preset := 'Classic';
  // Vorgaben eines ANDEREN Presets (ModernFlat: Rundung 6, Glow 5) weichen
  // von Classic ab und muessen gespeichert werden
  B.Appearance.Rounding := 6;
  B.Appearance.GlowSize := 5;
  Text := DfmText(B);
  CheckTrue(Pos('Appearance.Rounding = 6', Text) > 0, Text);
  CheckTrue(Pos('Appearance.GlowSize = 5', Text) > 0, Text);
  B2 := RoundTrip(B) as TPPGButton;
  try
    CheckEquals(6, B2.Appearance.Rounding);
    CheckEquals(5, B2.Appearance.GlowSize);
    CheckTrue(B2.Appearance.Equals(B.Appearance));
  finally
    B2.Free;
  end;
  // Zurueck auf die Classic-Werte: nichts mehr gespeichert
  B.Appearance.Rounding := 3;
  B.Appearance.GlowSize := 0;
  Text := DfmText(B);
  CheckEquals(-1, LineIndex(Text, 'Appearance.'), Text);
  // ResetToPresetDefaults ebenso
  B.Appearance.Hot.Color := clLime;
  B.ResetToPresetDefaults;
  CheckEquals(-1, LineIndex(DfmText(B), 'Appearance.'));
end;

procedure TPresetStreamingTests.OldDfmWithAllValuesLoadsUnchanged;
var
  Ref, B: TPPGButton;
  Lines: TStringList;
  Header: string;

  procedure CheckLoad(const Variant, WantPreset: string);
  begin
    B := LoadText(TPPGButton, Lines.Text) as TPPGButton;
    try
      CheckEquals(WantPreset, B.Preset, Variant);
      CheckTrue(B.Appearance.Equals(Ref.Appearance), Variant + ': Appearance anders');
    finally
      B.Free;
    end;
  end;

begin
  Ref := NewButton;
  Header := 'object ' + Ref.ClassName;
  Lines := TStringList.Create;
  try
    // Wie fruehere Versionen: Preset und ALLE Werte, teils eigene, teils die
    // eines anderen Presets
    Ref.Preset := 'Classic';
    Ref.Appearance.Normal.Color := $00102030;
    Ref.Appearance.Hot.GradientDirection := gdHorizontal;
    Ref.Appearance.Down.TextColor := clRed;
    Ref.Appearance.Rounding := 6;
    Ref.Appearance.GlowSize := 5;
    Lines.Add(Header);
    Lines.Add('  Preset = ''Classic''');
    AddAllAppearanceLines(Ref.Appearance, Lines);
    Lines.Add('end');
    CheckLoad('Preset vor Appearance', 'Classic');
    // Andere Reihenfolge (Appearance vor Preset): die gelesenen Werte bleiben
    Lines.Clear;
    Lines.Add(Header);
    AddAllAppearanceLines(Ref.Appearance, Lines);
    Lines.Add('  Preset = ''Classic''');
    Lines.Add('end');
    CheckLoad('Appearance vor Preset', 'Classic');
    // Fluent11 mit allen Werten von ModernFlat in der DFM: die DFM gewinnt
    // gegen die Fluent-Vorgaben
    Ref.Preset := 'ModernFlat';
    Ref.ResetToPresetDefaults;
    Lines.Clear;
    Lines.Add(Header);
    Lines.Add('  Preset = ''Fluent11''');
    AddAllAppearanceLines(Ref.Appearance, Lines);
    Lines.Add('end');
    CheckLoad('Fluent11 mit ModernFlat-Werten', 'Fluent11');
    // Standard-Preset ausdruecklich und alle Werte
    Lines.Clear;
    Lines.Add(Header);
    Lines.Add('  Preset = ''ModernFlat''');
    AddAllAppearanceLines(Ref.Appearance, Lines);
    Lines.Add('end');
    CheckLoad('ModernFlat ausdruecklich', 'ModernFlat');
  finally
    Lines.Free;
  end;
end;

procedure TPresetStreamingTests.BrandingDoesNotChangeStreaming;
var
  SM, SM2: TPPGStyleManager;
  B, B2, Plain: TPPGButton;
begin
  SM := TPPGStyleManager.Create(nil);
  try
    SM.AccentColor := $00804020;
    // Unter der Marke angelegt: die Akzentfarben weichen vom reinen Preset ab
    B := NewButton;
    CheckTrue(LineIndex(DfmText(B), 'Appearance.') >= 0, 'Markenfarben muessen gespeichert werden');
  finally
    SM.Free;
  end;
  CheckFalse(TPPGTokenOverrides.Active, 'Marke nach Free des Managers entfernt');
  // Laden ohne Marke: dieselben Farben
  B2 := RoundTrip(B) as TPPGButton;
  try
    CheckTrue(B2.Appearance.Equals(B.Appearance), 'Markenfarben nach dem Laden');
  finally
    B2.Free;
  end;
  // Ohne Marke angelegt, mit aktiver Marke gespeichert und geladen: reines Preset
  Plain := NewButton;
  Plain.Preset := 'Fluent11';
  SM2 := TPPGStyleManager.Create(nil);
  try
    SM2.AccentColor := $00206040;
    CheckEquals(-1, LineIndex(DfmText(Plain), 'Appearance.'), 'reines Preset: nichts zu speichern');
    B2 := RoundTrip(Plain) as TPPGButton;
    try
      CheckTrue(B2.Appearance.Equals(Plain.Appearance), 'aktive Marke aendert das Laden nicht');
    finally
      B2.Free;
    end;
  finally
    SM2.Free;
  end;
  CheckFalse(TPPGTokenOverrides.Active);
end;

procedure TPresetStreamingTests.InheritedFormKeepsAncestorValues;
var
  A, D, C: TPPGButton;
  MA, MD: TMemoryStream;
  Text: string;

  function Load: TPPGButton;
  begin
    Result := NewButton;
    try
      // wie ein geerbtes Formular: erst die DFM des Vorfahren, dann die eigene,
      // Loaded einmal am Ende
      BeginGlobalLoading;
      try
        MA.Position := 0;
        MA.ReadComponent(Result);
        MD.Position := 0;
        MD.ReadComponent(Result);
        NotifyGlobalLoading;
      finally
        EndGlobalLoading;
      end;
    except
      Result.Free;
      raise;
    end;
  end;

begin
  MA := TMemoryStream.Create;
  MD := TMemoryStream.Create;
  try
    // 1) Vorfahr ModernFlat, Nachfahr Classic mit Rundung 6 (= Vorfahr, nicht Classic)
    A := NewButton;
    D := NewButton;
    D.Preset := 'Classic';
    D.Appearance.Rounding := 6;
    MA.WriteComponent(A);
    MD.WriteDescendent(D, A);
    Text := BinaryToText(MD);
    CheckTrue(Pos('Preset = ''Classic''', Text) > 0, Text);
    CheckEquals(-1, LineIndex(Text, 'Appearance.Rounding'), 'gleich dem Vorfahren: nicht gespeichert');
    C := Load;
    try
      CheckEquals('Classic', C.Preset);
      CheckTrue(C.Appearance.Equals(D.Appearance), 'Nachfahr 1 nach dem Laden');
    finally
      C.Free;
    end;
    // 2) Vorfahr Classic mit Rundung 9, Nachfahr Classic mit der Vorgabe 3
    MA.Clear;
    MD.Clear;
    A.Preset := 'Classic';
    A.Appearance.Rounding := 9;
    D.Appearance.Rounding := 3;
    MA.WriteComponent(A);
    MD.WriteDescendent(D, A);
    Text := BinaryToText(MD);
    CheckTrue(Pos('Appearance.Rounding = 3', Text) > 0, 'Abweichung vom Vorfahren gespeichert: ' + Text);
    C := Load;
    try
      CheckEquals(3, C.Appearance.Rounding);
      CheckTrue(C.Appearance.Equals(D.Appearance), 'Nachfahr 2 nach dem Laden');
    finally
      C.Free;
    end;
  finally
    MD.Free;
    MA.Free;
  end;
end;

procedure TPresetStreamingTests.StyleManagerWritesOnlyDifferences;
var
  SM, SM2: TPPGStyleManager;
  B: TPPGButton;
  Text: string;
  L: TStringList;
begin
  SM := TPPGStyleManager.Create(nil);
  try
    Text := DfmText(SM);
    CheckEquals(-1, LineIndex(Text, 'Appearance.'), Text);
    CheckEquals(-1, LineIndex(Text, 'Preset '), Text);
    SM.Preset := 'Fluent11';
    SM.Appearance.Rounding := 11;
    Text := DfmText(SM);
    L := DfmLines(Text, 'Appearance.');
    try
      CheckEquals(1, L.Count, Text);
      CheckEquals('Appearance.Rounding = 11', L[0]);
    finally
      L.Free;
    end;
    CheckTrue(LineIndex(Text, 'Preset ') >= 0, Text);
    SM2 := RoundTrip(SM) as TPPGStyleManager;
    try
      CheckEquals('Fluent11', SM2.Preset);
      CheckTrue(SM2.Appearance.Equals(SM.Appearance), 'StyleManager nach dem Laden');
    finally
      SM2.Free;
    end;
    // Am Manager: weder Preset noch Appearance im Control
    B := NewButton;
    B.StyleManager := SM;
    Text := DfmText(B);
    CheckEquals(-1, LineIndex(Text, 'Appearance.'), Text);
    CheckEquals(-1, LineIndex(Text, 'Preset '), Text);
    B.StyleManager := nil;
    // Marke: die davon abgeleiteten Farben des Managers bleiben gespeichert
    SM.AccentColor := $00406080;
    Text := DfmText(SM);
    CheckTrue(LineIndex(Text, 'Appearance.') >= 0, Text);
    SM2 := RoundTrip(SM) as TPPGStyleManager;
    try
      CheckTrue(SM2.Appearance.Equals(SM.Appearance), 'StyleManager mit Marke nach dem Laden');
    finally
      SM2.Free;
    end;
  finally
    SM.Free;
  end;
  CheckFalse(TPPGTokenOverrides.Active, 'Marke nach Free der Manager entfernt');
end;

{ TStyleManagedPropertyTests }

function TStyleManagedPropertyTests.NonDefaultPreset: string;
begin
  // Ein Preset, das NICHT das Standard-Preset ist (das wuerde nie gespeichert)
  if SameText(TPPGRendererRegistry.DefaultName, 'Classic') then
    Result := 'ModernFlat'
  else
    Result := 'Classic';
end;

function ComponentDfm(C: TComponent): string;
var
  M: TMemoryStream;
begin
  M := TMemoryStream.Create;
  try
    M.WriteComponent(C);
    Result := BinaryToText(M);
  finally
    M.Free;
  end;
end;

{ Erwartete verwaltete Properties: Controls alles, was ApplyStyleManager
  ueberschreibt; Komponenten nur das Preset (das NotificationCenter nutzt seine
  Animation selbst fuer das Einblenden, der Manager ersetzt sie nicht). }
function ExpectedManaged(C: TComponent): string;
begin
  if C is TPPGCustomControl then
    Result := 'Preset,Appearance,Animation'
  else
    Result := 'Preset';
end;

procedure TStyleManagedPropertyTests.RuleCoversEveryClassWithStyleManager;
const
  Probe: array[0..7] of string = ('Preset', 'Appearance', 'Animation', 'StyleManager',
    'Name', 'Font', 'Styles', '');
var
  SM: TPPGStyleManager;
  CI, PI, Hosts, Comps: Integer;
  C: TComponent;
  Host: IPPGStyleManagedHost;
  Expected: TStringList;
  Errors: TStringList;
  PInfo: PPropInfo;
begin
  SM := TPPGStyleManager.Create(FForm);
  Expected := TStringList.Create;
  Errors := TStringList.Create;
  try
    Hosts := 0;
    Comps := 0;
    for CI := 0 to High(ControlClasses) do
    begin
      C := NewComponent(ControlClasses[CI]);
      try
        PInfo := GetPropInfo(C, 'StyleManager');
        if not Supports(C, IPPGStyleManagedHost, Host) then
        begin
          if PInfo <> nil then
            Errors.Add(C.ClassName + ': published StyleManager ohne IPPGStyleManagedHost');
          CheckFalse(PPGHasStyleManager(C), C.ClassName);
          CheckFalse(PPGIsStyleManagedProperty(C, 'Preset'), C.ClassName);
          Continue;
        end;
        Host := nil;
        Inc(Hosts);
        if not (C is TPPGCustomControl) then
          Inc(Comps);
        if PInfo = nil then
        begin
          Errors.Add(C.ClassName + ': IPPGStyleManagedHost ohne published StyleManager');
          Continue;
        end;
        Expected.CommaText := ExpectedManaged(C);
        // Ohne Manager: nichts verwaltet
        CheckFalse(PPGHasStyleManager(C), C.ClassName + ' ohne Manager');
        for PI := 0 to High(Probe) do
          if PPGIsStyleManagedProperty(C, Probe[PI]) then
            Errors.Add(Format('%s ohne Manager: %s verwaltet', [C.ClassName, Probe[PI]]));
        SetObjectProp(C, 'StyleManager', SM);
        CheckTrue(PPGHasStyleManager(C), C.ClassName + ' mit Manager');
        for PI := 0 to High(Probe) do
          if PPGIsStyleManagedProperty(C, Probe[PI]) <> (Expected.IndexOf(Probe[PI]) >= 0) then
            Errors.Add(Format('%s mit Manager: %s erwartet %s', [C.ClassName, Probe[PI],
              BoolToStr(Expected.IndexOf(Probe[PI]) >= 0)]));
        // Gross/Klein egal (Namen aus dem Objektinspektor)
        CheckTrue(PPGIsStyleManagedProperty(C, 'preset'), C.ClassName + ' preset');
        // Preset ist ueberall published; Appearance/Animation veroeffentlichen
        // nicht alle Controls (z.B. GroupBox ohne Animation) - verwaltet sind
        // sie trotzdem, ApplyStyleManager ueberschreibt sie immer
        if GetPropInfo(C, 'Preset') = nil then
          Errors.Add(C.ClassName + ': Preset nicht published');
        SetObjectProp(C, 'StyleManager', nil);
        CheckFalse(PPGIsStyleManagedProperty(C, 'Preset'), C.ClassName + ' Manager wieder leer');
      finally
        C.Free;
      end;
    end;
    Status(Format('%d Klassen mit StyleManager, davon %d Komponenten ohne Fenster', [Hosts, Comps]));
    CheckEquals('', Errors.Text, Errors.Text);
    // Liste wie RegisterComponents: 7 Komponenten (PopupMenu, HintManager,
    // CustomHint, TeachingTip, TaskDialog, NotificationCenter, BusyOverlay)
    CheckEquals(7, Comps, 'Komponenten mit StyleManager');
    CheckTrue(Hosts > 70, 'zu wenige Klassen mit StyleManager');
    // Kein Host, kein Objekt
    CheckFalse(PPGIsStyleManagedProperty(nil, 'Preset'), 'nil');
    CheckFalse(PPGIsStyleManagedProperty(SM, 'Preset'), 'der Manager selbst');
    CheckFalse(PPGHasStyleManager(nil), 'nil');
  finally
    Errors.Free;
    Expected.Free;
  end;
end;

procedure TStyleManagedPropertyTests.RuleForSelectionNeedsAllManaged;
var
  SM: TPPGStyleManager;
  B1, B2: TPPGButton;
  PM: TPPGPopupMenu;
begin
  SM := TPPGStyleManager.Create(FForm);
  B1 := NewButton;
  B2 := NewButton;
  PM := TPPGPopupMenu.Create(FForm);
  CheckFalse(PPGIsStyleManagedPropertyForAll([], 'Preset'), 'leere Auswahl');
  CheckFalse(PPGIsStyleManagedPropertyForAll([B1, B2], 'Appearance'), 'keiner mit Manager');
  B1.StyleManager := SM;
  CheckTrue(PPGIsStyleManagedPropertyForAll([B1], 'Appearance'), 'einer mit Manager');
  CheckFalse(PPGIsStyleManagedPropertyForAll([B1, B2], 'Appearance'), 'gemischt: sichtbar lassen');
  B2.StyleManager := SM;
  CheckTrue(PPGIsStyleManagedPropertyForAll([B1, B2], 'Appearance'), 'alle mit Manager');
  CheckTrue(PPGIsStyleManagedPropertyForAll([B1, B2], 'Animation'), 'alle mit Manager');
  CheckFalse(PPGIsStyleManagedPropertyForAll([B1, B2], 'Caption'), 'nicht verwaltet');
  // Control und Menue: gemeinsam verwaltet ist nur das Preset
  PM.StyleManager := SM;
  CheckTrue(PPGIsStyleManagedPropertyForAll([B1, PM], 'Preset'), 'Control und Menue');
  CheckFalse(PPGIsStyleManagedPropertyForAll([B1, PM], 'Appearance'), 'Menue ohne Appearance');
  CheckFalse(PPGIsStyleManagedPropertyForAll([B1, nil], 'Preset'), 'nil in der Auswahl');
  // Manager freigeben: FreeNotification leert die Referenzen, nichts mehr verwaltet
  SM.Free;
  CheckFalse(PPGIsStyleManagedPropertyForAll([B1], 'Preset'), 'Manager freigegeben');
  CheckFalse(PPGIsStyleManagedProperty(PM, 'Preset'), 'Manager freigegeben (Menue)');
end;

procedure TStyleManagedPropertyTests.ManagedPropertiesAreNotStoredWithStyleManager;
var
  SM: TPPGStyleManager;
  CI, Checked: Integer;
  C: TComponent;
  P, Text: string;
  Errors: TStringList;
  A: TPPGAppearance;
  AnimInfo: PPropInfo;

  procedure Expect(Present: Boolean; const Prefix, Step: string);
  begin
    if (LineIndex(Text, Prefix) >= 0) <> Present then
      Errors.Add(Format('%s %s: "%s" erwartet %s', [C.ClassName, Step, Prefix,
        BoolToStr(Present)]));
  end;

begin
  P := NonDefaultPreset;
  SM := TPPGStyleManager.Create(FForm);
  SM.Name := 'SMStreamTest';
  SM.Preset := P;
  Errors := TStringList.Create;
  try
    Checked := 0;
    for CI := 0 to High(ControlClasses) do
    begin
      C := NewComponent(ControlClasses[CI]);
      try
        if not Supports(C, IPPGStyleManagedHost) or (GetPropInfo(C, 'StyleManager') = nil) then
          Continue;
        Inc(Checked);
        // 1) Ohne Manager: Preset, Appearance und Animation stehen in der DFM
        SetStrProp(C, 'Preset', P);
        AnimInfo := GetPropInfo(C, 'Animation');
        if AnimInfo <> nil then
          (GetObjectProp(C, AnimInfo) as TPPGAnimationSettings).Enabled := False;
        A := AppearanceOf(C);
        if A <> nil then
          A.Rounding := 17;
        Text := ComponentDfm(C);
        Expect(True, 'Preset ', 'ohne Manager');
        if AnimInfo <> nil then
          Expect(True, 'Animation.Enabled', 'ohne Manager');
        if A <> nil then
          Expect(True, 'Appearance.Rounding', 'ohne Manager');
        // 2) Mit Manager: verwaltete Properties fehlen, die uebrigen bleiben
        SetObjectProp(C, 'StyleManager', SM);
        Text := ComponentDfm(C);
        Expect(True, 'StyleManager ', 'mit Manager');
        Expect(False, 'Preset ', 'mit Manager');
        Expect(False, 'Appearance.', 'mit Manager');
        if C is TPPGCustomControl then
          Expect(False, 'Animation.', 'mit Manager')
        else if AnimInfo <> nil then
          Expect(True, 'Animation.Enabled', 'mit Manager (nicht verwaltet)');
        // 3) Manager wieder leer: Preset wird wieder gespeichert
        SetObjectProp(C, 'StyleManager', nil);
        Text := ComponentDfm(C);
        Expect(True, 'Preset ', 'Manager wieder leer');
        Expect(False, 'StyleManager ', 'Manager wieder leer');
      finally
        C.Free;
      end;
    end;
    Status(Format('%d Klassen mit StyleManager geprueft', [Checked]));
    CheckTrue(Checked > 70, 'zu wenige Klassen geprueft');
    CheckEquals('', Errors.Text, Errors.Text);
  finally
    Errors.Free;
  end;
end;

procedure TStyleManagedPropertyTests.OldDfmWithManagedValuesLoadsAndDropsThem;
const
  Dfm =
    'object PPGSmhRoot: TForm'#13#10 +
    '  object SM1: TPPGStyleManager'#13#10 +
    '    Preset = ''%0:s'''#13#10 +
    '  end'#13#10 +
    '  object B1: TPPGButton'#13#10 +
    '    Preset = ''%1:s'''#13#10 +
    '    StyleManager = SM1'#13#10 +
    '    Appearance.Rounding = 17'#13#10 +
    '    Animation.Enabled = False'#13#10 +
    '  end'#13#10 +
    '  object PM1: TPPGPopupMenu'#13#10 +
    '    StyleManager = SM1'#13#10 +
    '    Preset = ''%1:s'''#13#10 +
    '  end'#13#10 +
    '  object NC1: TPPGNotificationCenter'#13#10 +
    '    Preset = ''%1:s'''#13#10 +
    '    StyleManager = SM1'#13#10 +
    '    Animation.Enabled = False'#13#10 +
    '  end'#13#10 +
    'end'#13#10;
var
  Root: TForm;
  T: TStringStream;
  M: TMemoryStream;
  SMPreset, CompPreset, Text: string;
  SM: TPPGStyleManager;
  B: TPPGButton;
  PM: TPPGPopupMenu;
  NC: TPPGNotificationCenter;

  function Count(const Sub: string): Integer;
  var
    S: string;
    I: Integer;
  begin
    Result := 0;
    S := Text;
    I := Pos(Sub, S);
    while I > 0 do
    begin
      Inc(Result);
      S := Copy(S, I + Length(Sub), MaxInt);
      I := Pos(Sub, S);
    end;
  end;

  function SaveRoot: string;
  var
    MS: TMemoryStream;
  begin
    MS := TMemoryStream.Create;
    try
      MS.WriteComponent(Root);
      Result := BinaryToText(MS);
    finally
      MS.Free;
    end;
  end;

begin
  RegisterClasses([TPPGStyleManager, TPPGButton, TPPGPopupMenu, TPPGNotificationCenter]);
  SMPreset := NonDefaultPreset;
  if not SameText(TPPGRendererRegistry.DefaultName, 'ModernFlat') and
    not SameText(SMPreset, 'ModernFlat') then
    CompPreset := 'ModernFlat'
  else
    CompPreset := 'Fluent11';
  CheckFalse(SameText(SMPreset, CompPreset), 'zwei verschiedene Presets');
  CheckFalse(SameText(TPPGRendererRegistry.DefaultName, CompPreset), 'kein Standard-Preset');
  Root := TForm.CreateNew(nil);
  try
    T := TStringStream.Create(Format(Dfm, [SMPreset, CompPreset]), TEncoding.UTF8);
    M := TMemoryStream.Create;
    try
      ObjectTextToBinary(T, M);
      M.Position := 0;
      M.ReadComponent(Root);
    finally
      M.Free;
      T.Free;
    end;
    SM := Root.FindComponent('SM1') as TPPGStyleManager;
    B := Root.FindComponent('B1') as TPPGButton;
    PM := Root.FindComponent('PM1') as TPPGPopupMenu;
    NC := Root.FindComponent('NC1') as TPPGNotificationCenter;
    CheckNotNull(SM, 'SM1');
    CheckNotNull(B, 'B1');
    CheckNotNull(PM, 'PM1');
    CheckNotNull(NC, 'NC1');
    // Wie bisher: der Manager ueberschreibt die Werte aus der alten DFM
    CheckSame(SM, B.StyleManager, 'B1.StyleManager');
    CheckEquals(SMPreset, B.Preset, 'B1.Preset vom Manager');
    CheckTrue(B.Appearance.Equals(SM.Appearance), 'B1.Appearance vom Manager');
    CheckTrue(B.Animation.Enabled, 'B1.Animation vom Manager');
    // Komponenten behalten ihr gelesenes Preset (wirksam ist das des Managers)
    CheckSame(SM, PM.StyleManager, 'PM1.StyleManager');
    CheckEquals(CompPreset, PM.Preset, 'PM1.Preset gelesen');
    CheckSame(SM, NC.StyleManager, 'NC1.StyleManager');
    CheckFalse(NC.Animation.Enabled, 'NC1.Animation ist nicht verwaltet');
    // Speichern: die verwalteten Werte fallen heraus
    Text := SaveRoot;
    CheckEquals(3, Count('StyleManager = SM1'), Text);
    CheckEquals(0, Count('Appearance.Rounding = 17'), Text);
    CheckEquals(0, Count('''' + CompPreset + ''''), Text);
    CheckEquals(1, Count('''' + SMPreset + ''''), 'nur das Preset des Managers: ' + Text);
    CheckEquals(1, Count('Animation.Enabled = False'), 'nur NC1: ' + Text);
    // Manager entfernen: Werte bleiben, das Preset wird wieder gespeichert
    PM.StyleManager := nil;
    B.StyleManager := nil;
    CheckEquals(SMPreset, B.Preset, 'B1 behaelt das Preset des Managers');
    CheckTrue(B.Appearance.Equals(SM.Appearance), 'B1 behaelt die Appearance');
    Text := SaveRoot;
    CheckEquals(1, Count('StyleManager = SM1'), Text);
    CheckEquals(1, Count('''' + CompPreset + ''''), 'PM1.Preset wieder gespeichert: ' + Text);
    CheckEquals(2, Count('''' + SMPreset + ''''), 'B1.Preset wieder gespeichert: ' + Text);
  finally
    Root.Free;
  end;
end;

procedure TStyleManagedPropertyTests.RuntimeBehaviourUnchanged;
var
  SM: TPPGStyleManager;
  B: TPPGButton;
  PM: TPPGPopupMenu;
begin
  SM := TPPGStyleManager.Create(FForm);
  SM.Preset := NonDefaultPreset;
  SM.Appearance.Rounding := 13;
  B := NewButton;
  B.StyleManager := SM;
  CheckEquals(NonDefaultPreset, B.Preset);
  CheckEquals(13, B.Appearance.Rounding);
  // Eigene Werte zur Laufzeit bleiben moeglich (bis zur naechsten Aenderung am Manager)
  B.Appearance.Rounding := 5;
  CheckEquals(5, B.Appearance.Rounding, 'Laufzeit-Zuweisung trotz Manager');
  B.Animation.Enabled := False;
  CheckFalse(B.Animation.Enabled, 'Laufzeit-Zuweisung trotz Manager');
  SM.Appearance.Rounding := 7;
  CheckEquals(7, B.Appearance.Rounding, 'Manager ueberschreibt wie bisher');
  CheckTrue(B.Animation.Enabled, 'Manager ueberschreibt die Animation wie bisher');
  // Preset an der Komponente: gespeichert wird es nicht, gesetzt schon
  PM := TPPGPopupMenu.Create(FForm);
  PM.Preset := 'Classic';
  PM.StyleManager := SM;
  CheckEquals('Classic', PM.Preset, 'Feld bleibt');
  PM.StyleManager := nil;
  CheckEquals('Classic', PM.Preset, 'nach dem Leeren wieder wirksam');
end;

initialization
  RegisterTest('Streaming', TDfmStreamingTests.Suite);
  RegisterTest('Streaming', TPresetStreamingTests.Suite);
  RegisterTest('Streaming', TStyleManagedPropertyTests.Suite);

end.
