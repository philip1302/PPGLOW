unit PPG.Tests.Streaming;

{ DFM-Pruefung ueber ALLE Paletten-Controls (Liste wie RegisterComponents in
  PPG.Reg und PPG.DB.Reg, 67 + 17 = 84 Klassen):
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
  PPG.Labels, PPG.Feedback, PPG.Expander, PPG.Splitter, PPG.Rating, PPG.SearchEdit,
  PPG.Calendar, PPG.DatePicker, PPG.TimePicker, PPG.NavigationView, PPG.Breadcrumb,
  PPG.ToolBar, PPG.StatusBar, PPG.Notifications, PPG.Sparkline, PPG.Gauge, PPG.Chart,
  PPG.Planner, PPG.Ribbon, PPG.Kanban, PPG.Menus, PPG.MenuBar, PPG.Hints, PPG.TeachingTip,
  PPG.Dialogs, PPG.Wizard, PPG.Validator, PPG.BusyOverlay, PPG.NumberEdit, PPG.MaskEdit,
  PPG.PasswordEdit, PPG.FileEdit, PPG.ColorPicker, PPG.CheckComboBox, PPG.ColumnComboBox,
  PPG.TagEdit, PPG.Grid.Print, PPG.Planner.Print, PPG.Kanban.Print, PPG.StyleManager,
  PPG.DB.Controls, PPG.DB.Lookup, PPG.DB.Grid, PPG.DB.Chart, PPG.DB.Planner, PPG.DB.Kanban,
  PPG.DB.Fields, PPG.DB.Navigator,
  PPG.Tests.Controls;

type
  TDfmStreamingTests = class(TControlTestCase)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    function RoundTrip(C: TComponent): TComponent;
    function NewComponent(Cls: TComponentClass): TComponent;
    function CheckNested(Cls: TComponentClass; PInfo: PPropInfo; Errors, Unchanged: TStrings): Boolean;
  protected
    procedure SetUp; override;
  published
    procedure PaletteListIsComplete;
    procedure EveryPropertySurvivesDfm;
    procedure NestedPropertiesSurviveDfm;
    procedure RatingHalfValueSurvivesDfm;
    procedure StatusBarOwnFontSurvivesDfm;
  end;

implementation

const
  // Reihenfolge wie RegisterComponents in PPG.Reg (67) und PPG.DB.Reg (17)
  ControlClasses: array[0..83] of TComponentClass = (TPPGButton, TPPGCheckBox, TPPGRadioButton,
    TPPGToggleSwitch, TPPGProgressBar, TPPGTrackBar, TPPGPanel, TPPGScrollBox, TPPGGroupBox,
    TPPGRadioGroup, TPPGCheckGroup,
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
    TPPGGridPrinter, TPPGPlannerPrinter, TPPGKanbanPrinter, TPPGStyleManager,
    TPPGDBEdit, TPPGDBMemo, TPPGDBCheckBox, TPPGDBComboBox,
    TPPGDBLookupComboBox, TPPGDBDatePicker, TPPGDBGrid, TPPGDBChart, TPPGDBPlanner, TPPGDBKanban,
    TPPGDBMaskEdit, TPPGDBNumberEdit, TPPGDBColorPicker, TPPGDBCheckComboBox, TPPGDBTagEdit,
    TPPGDBNavigator, TPPGDBRadioGroup);

  // Dokumentierte Ausnahmen (Property-Name, gilt fuer alle Klassen) mit Grund:
  SkipProps: array[0..24] of string = (
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
    'ImageName', 'HotImageName', 'DisabledImageName', 'PressedImageName');

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

{ TDfmStreamingTests }

procedure TDfmStreamingTests.SetUp;
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

function TDfmStreamingTests.NewComponent(Cls: TComponentClass): TComponent;
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

function TDfmStreamingTests.RoundTrip(C: TComponent): TComponent;
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

procedure TDfmStreamingTests.PaletteListIsComplete;
var
  I, J: Integer;
begin
  // 84 verschiedene Klassen; doppelt eingetragene wuerden eine fehlende verdecken
  CheckEquals(84, Length(ControlClasses));
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

initialization
  RegisterTest('Streaming', TDfmStreamingTests.Suite);

end.
