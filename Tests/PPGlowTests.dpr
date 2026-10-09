program PPGlowTests;

{ Konsolen-Testlauf (DUnit, von XE2 bis Delphi 13 identisch verfuegbar).
  Exit-Code = Anzahl Fehler + Failures (0 = alles gruen) -> CI-tauglich.
  Parameter /gui startet den grafischen DUnit-Runner. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Vcl.Forms,
  TestFramework,
  TextTestRunner,
  GUITestRunner,
  PPG.Consts in '..\Source\Core\PPG.Consts.pas',
  PPG.Lang in '..\Source\Core\PPG.Lang.pas',
  PPG.Lang.De in '..\Source\Core\PPG.Lang.De.pas',
  PPG.Exceptions in '..\Source\Core\PPG.Exceptions.pas',
  PPG.ErrorHandler in '..\Source\Core\PPG.ErrorHandler.pas',
  PPG.Types in '..\Source\Core\PPG.Types.pas',
  PPG.Tokens in '..\Source\Core\PPG.Tokens.pas',
  PPG.ElementStyle in '..\Source\Core\PPG.ElementStyle.pas',
  PPG.Appearance in '..\Source\Core\PPG.Appearance.pas',
  PPG.Animation in '..\Source\Core\PPG.Animation.pas',
  PPG.Layout in '..\Source\Core\PPG.Layout.pas',
  PPG.DpiUtils in '..\Source\Core\PPG.DpiUtils.pas',
  PPG.Render.Intf in '..\Source\Render\PPG.Render.Intf.pas',
  PPG.Render.Gdi in '..\Source\Render\PPG.Render.Gdi.pas',
  PPG.Render.GdiPlus in '..\Source\Render\PPG.Render.GdiPlus.pas',
  PPG.Render.Registry in '..\Source\Render\PPG.Render.Registry.pas',
  PPG.Render.Classic in '..\Source\Render\PPG.Render.Classic.pas',
  PPG.Render.ModernFlat in '..\Source\Render\PPG.Render.ModernFlat.pas',
  PPG.IconFont in '..\Source\Render\PPG.IconFont.pas',
  PPG.Render.Fluent11 in '..\Source\Render\PPG.Render.Fluent11.pas',
  PPG.Presets in '..\Source\Theme\PPG.Presets.pas',
  PPG.StyleManager in '..\Source\Theme\PPG.StyleManager.pas',
  PPG.Theme in '..\Source\Theme\PPG.Theme.pas',
  PPG.VclStyles in '..\Source\Theme\PPG.VclStyles.pas',
  PPG.ThemeFile in '..\Source\Theme\PPG.ThemeFile.pas',
  PPG.Accessibility in '..\Source\Access\PPG.Accessibility.pas',
  PPG.UIA.Intf in '..\Source\Access\PPG.UIA.Intf.pas',
  PPG.UIA in '..\Source\Access\PPG.UIA.pas',
  PPG.Controls.Base in '..\Source\Controls\PPG.Controls.Base.pas',
  PPG.Button in '..\Source\Controls\PPG.Button.pas',
  PPG.Controls.Check in '..\Source\Controls\PPG.Controls.Check.pas',
  PPG.CheckBox in '..\Source\Controls\PPG.CheckBox.pas',
  PPG.RadioButton in '..\Source\Controls\PPG.RadioButton.pas',
  PPG.ToggleSwitch in '..\Source\Controls\PPG.ToggleSwitch.pas',
  PPG.Controls.Range in '..\Source\Controls\PPG.Controls.Range.pas',
  PPG.ProgressBar in '..\Source\Controls\PPG.ProgressBar.pas',
  PPG.TrackBar in '..\Source\Controls\PPG.TrackBar.pas',
  PPG.Controls.Container in '..\Source\Controls\PPG.Controls.Container.pas',
  PPG.Panel in '..\Source\Controls\PPG.Panel.pas',
  PPG.GroupBox in '..\Source\Controls\PPG.GroupBox.pas',
  PPG.RadioGroup in '..\Source\Controls\PPG.RadioGroup.pas',
  PPG.TileView in '..\Source\Controls\PPG.TileView.pas',
  PPG.Validator in '..\Source\Controls\PPG.Validator.pas',
  PPG.Overlay in '..\Source\Controls\PPG.Overlay.pas',
  PPG.BusyOverlay in '..\Source\Controls\PPG.BusyOverlay.pas',
  PPG.Controls.Field in '..\Source\Controls\PPG.Controls.Field.pas',
  PPG.Edit in '..\Source\Controls\PPG.Edit.pas',
  PPG.Memo in '..\Source\Controls\PPG.Memo.pas',
  PPG.SpinEdit in '..\Source\Controls\PPG.SpinEdit.pas',
  PPG.Popup in '..\Source\Controls\PPG.Popup.pas',
  PPG.ComboBox in '..\Source\Controls\PPG.ComboBox.pas',
  PPG.TabStrip in '..\Source\Controls\PPG.TabStrip.pas',
  PPG.TabControl in '..\Source\Controls\PPG.TabControl.pas',
  PPG.PageControl in '..\Source\Controls\PPG.PageControl.pas',
  PPG.Selection in '..\Source\Core\PPG.Selection.pas',
  PPG.Items in '..\Source\Core\PPG.Items.pas',
  PPG.Markup in '..\Source\Render\PPG.Markup.pas',
  PPG.RowLayout in '..\Source\Controls\PPG.RowLayout.pas',
  PPG.Controls.Scroll in '..\Source\Controls\PPG.Controls.Scroll.pas',
  PPG.ItemPainter in '..\Source\Controls\PPG.ItemPainter.pas',
  PPG.CustomDraw in '..\Source\Controls\PPG.CustomDraw.pas',
  PPG.Controls.ItemList in '..\Source\Controls\PPG.Controls.ItemList.pas',
  PPG.ListBox in '..\Source\Controls\PPG.ListBox.pas',
  PPG.CheckListBox in '..\Source\Controls\PPG.CheckListBox.pas',
  PPG.TreeView in '..\Source\Controls\PPG.TreeView.pas',
  PPG.Grid in '..\Source\Controls\PPG.Grid.pas',
  PPG.Labels in '..\Source\Controls\PPG.Labels.pas',
  PPG.Feedback in '..\Source\Controls\PPG.Feedback.pas',
  PPG.Expander in '..\Source\Controls\PPG.Expander.pas',
  PPG.Splitter in '..\Source\Controls\PPG.Splitter.pas',
  PPG.Rating in '..\Source\Controls\PPG.Rating.pas',
  PPG.SearchEdit in '..\Source\Controls\PPG.SearchEdit.pas',
  PPG.Calendar in '..\Source\Controls\PPG.Calendar.pas',
  PPG.DatePicker in '..\Source\Controls\PPG.DatePicker.pas',
  PPG.TimePicker in '..\Source\Controls\PPG.TimePicker.pas',
  PPG.NavigationView in '..\Source\Controls\PPG.NavigationView.pas',
  PPG.Breadcrumb in '..\Source\Controls\PPG.Breadcrumb.pas',
  PPG.ToolBar in '..\Source\Controls\PPG.ToolBar.pas',
  PPG.StatusBar in '..\Source\Controls\PPG.StatusBar.pas',
  PPG.Notifications in '..\Source\Controls\PPG.Notifications.pas',
  PPG.Planner.Print in '..\Source\Controls\PPG.Planner.Print.pas',
  PPG.Kanban.Print in '..\Source\Controls\PPG.Kanban.Print.pas',
  PPG.KeyTips in '..\Source\Core\PPG.KeyTips.pas',
  PPG.Ribbon.Layout in '..\Source\Core\PPG.Ribbon.Layout.pas',
  PPG.Ribbon.Items in '..\Source\Controls\PPG.Ribbon.Items.pas',
  PPG.Ribbon in '..\Source\Controls\PPG.Ribbon.pas',
  PPG.Kanban.Layout in '..\Source\Core\PPG.Kanban.Layout.pas',
  PPG.Kanban.Items in '..\Source\Controls\PPG.Kanban.Items.pas',
  PPG.Kanban in '..\Source\Controls\PPG.Kanban.pas',
  PPG.Print in '..\Source\Controls\PPG.Print.pas',
  PPG.Planner in '..\Source\Controls\PPG.Planner.pas',
  PPG.TimeZones in '..\Source\Core\PPG.TimeZones.pas',
  PPG.Planner.Recurrence in '..\Source\Core\PPG.Planner.Recurrence.pas',
  PPG.Planner.Layout in '..\Source\Core\PPG.Planner.Layout.pas',
  PPG.Planner.Model in '..\Source\Core\PPG.Planner.Model.pas',
  PPG.Planner.ICal in '..\Source\Core\PPG.Planner.ICal.pas',
  PPG.Grid.Look in '..\Source\Controls\PPG.Grid.Look.pas',
  PPG.Xlsx in '..\Source\Controls\PPG.Xlsx.pas',
  PPG.Grid.Export in '..\Source\Controls\PPG.Grid.Export.pas',
  PPG.Grid.Print in '..\Source\Controls\PPG.Grid.Print.pas',
  PPG.Grid.Styles in '..\Source\Controls\PPG.Grid.Styles.pas',
  PPG.Grid.CellKinds in '..\Source\Controls\PPG.Grid.CellKinds.pas',
  PPG.Grid.Edit in '..\Source\Controls\PPG.Grid.Edit.pas',
  PPG.Grid.Paint in '..\Source\Controls\PPG.Grid.Paint.pas',
  PPG.Grid.Data in '..\Source\Controls\PPG.Grid.Data.pas',
  PPG.Grid.View in '..\Source\Controls\PPG.Grid.View.pas',
  PPG.Grid.Columns in '..\Source\Controls\PPG.Grid.Columns.pas',
  PPG.TagEdit in '..\Source\Controls\PPG.TagEdit.pas',
  PPG.ColumnComboBox in '..\Source\Controls\PPG.ColumnComboBox.pas',
  PPG.RowPopup in '..\Source\Controls\PPG.RowPopup.pas',
  PPG.CheckComboBox in '..\Source\Controls\PPG.CheckComboBox.pas',
  PPG.ColorSpace in '..\Source\Core\PPG.ColorSpace.pas',
  PPG.Controls.DropDown in '..\Source\Controls\PPG.Controls.DropDown.pas',
  PPG.ColorPicker in '..\Source\Controls\PPG.ColorPicker.pas',
  PPG.FileEdit in '..\Source\Controls\PPG.FileEdit.pas',
  PPG.MaskEdit in '..\Source\Controls\PPG.MaskEdit.pas',
  PPG.PasswordEdit in '..\Source\Controls\PPG.PasswordEdit.pas',
  PPG.NumberFormat in '..\Source\Core\PPG.NumberFormat.pas',
  PPG.NumberEdit in '..\Source\Controls\PPG.NumberEdit.pas',
  PPG.Wizard in '..\Source\Controls\PPG.Wizard.pas',
  PPG.Dialogs in '..\Source\Controls\PPG.Dialogs.pas',
  PPG.TeachingTip in '..\Source\Controls\PPG.TeachingTip.pas',
  PPG.Hints in '..\Source\Controls\PPG.Hints.pas',
  PPG.MenuBar in '..\Source\Controls\PPG.MenuBar.pas',
  PPG.Popup.Placement in '..\Source\Core\PPG.Popup.Placement.pas',
  PPG.AppHooks in '..\Source\Controls\PPG.AppHooks.pas',
  PPG.Menus in '..\Source\Controls\PPG.Menus.pas',
  PPG.Chart.Series in '..\Source\Controls\PPG.Chart.Series.pas',
  PPG.Chart in '..\Source\Controls\PPG.Chart.pas',
  PPG.Chart.Scale in '..\Source\Core\PPG.Chart.Scale.pas',
  PPG.Chart.Palette in '..\Source\Core\PPG.Chart.Palette.pas',
  PPG.Render.Shapes in '..\Source\Render\PPG.Render.Shapes.pas',
  PPG.Sparkline in '..\Source\Controls\PPG.Sparkline.pas',
  PPG.Gauge in '..\Source\Controls\PPG.Gauge.pas',
  PPG.Editors.Logic in '..\Source\Editors\PPG.Editors.Logic.pas',
  PPG.Editors.Forms in '..\Source\Editors\PPG.Editors.Forms.pas',
  PPG.DB.Controls in '..\Source\DB\PPG.DB.Controls.pas',
  PPG.DB.Lookup in '..\Source\DB\PPG.DB.Lookup.pas',
  PPG.DB.Grid in '..\Source\DB\PPG.DB.Grid.pas',
  PPG.DB.Chart in '..\Source\DB\PPG.DB.Chart.pas',
  PPG.DB.Planner in '..\Source\DB\PPG.DB.Planner.pas',
  PPG.DB.Kanban in '..\Source\DB\PPG.DB.Kanban.pas',
  PPG.DB.Navigator in '..\Source\DB\PPG.DB.Navigator.pas',
  PPG.DB.Validator in '..\Source\DB\PPG.DB.Validator.pas',
  PPG.DB.Fields in '..\Source\DB\PPG.DB.Fields.pas',
  PPG.Tests.Core in 'PPG.Tests.Core.pas',
  PPG.Tests.Controls in 'PPG.Tests.Controls.pas',
  PPG.Tests.Check in 'PPG.Tests.Check.pas',
  PPG.Tests.Gaps in 'PPG.Tests.Gaps.pas',
  PPG.Tests.Phase3 in 'PPG.Tests.Phase3.pas',
  PPG.Tests.Phase4a in 'PPG.Tests.Phase4a.pas',
  PPG.Tests.Phase4b in 'PPG.Tests.Phase4b.pas',
  PPG.Tests.Phase4c in 'PPG.Tests.Phase4c.pas',
  PPG.Tests.Phase5 in 'PPG.Tests.Phase5.pas',
  PPG.Tests.Phase6a in 'PPG.Tests.Phase6a.pas',
  PPG.Tests.Phase6b in 'PPG.Tests.Phase6b.pas',
  PPG.Tests.Phase6c in 'PPG.Tests.Phase6c.pas',
  PPG.Tests.Phase8 in 'PPG.Tests.Phase8.pas',
  PPG.Tests.Phase7a in 'PPG.Tests.Phase7a.pas',
  PPG.Tests.Phase7b in 'PPG.Tests.Phase7b.pas',
  PPG.Tests.Phase7c in 'PPG.Tests.Phase7c.pas',
  PPG.Tests.Phase7d in 'PPG.Tests.Phase7d.pas',
  PPG.Tests.Streaming in 'PPG.Tests.Streaming.pas',
  PPG.Tests.Visual in 'PPG.Tests.Visual.pas',
  PPG.Tests.Phase9a in 'PPG.Tests.Phase9a.pas',
  PPG.Tests.Phase9b in 'PPG.Tests.Phase9b.pas',
  PPG.Tests.Phase9c in 'PPG.Tests.Phase9c.pas',
  PPG.Tests.Phase9d in 'PPG.Tests.Phase9d.pas',
  PPG.Tests.Phase10a in 'PPG.Tests.Phase10a.pas',
  PPG.Tests.Phase10b in 'PPG.Tests.Phase10b.pas',
  PPG.Tests.Phase10c in 'PPG.Tests.Phase10c.pas',
  PPG.Tests.Phase10d in 'PPG.Tests.Phase10d.pas',
  PPG.Tests.Phase10e in 'PPG.Tests.Phase10e.pas',
  PPG.Tests.Phase11a in 'PPG.Tests.Phase11a.pas',
  PPG.Tests.Phase11b in 'PPG.Tests.Phase11b.pas',
  PPG.Tests.Phase11c in 'PPG.Tests.Phase11c.pas',
  PPG.Tests.Phase12a in 'PPG.Tests.Phase12a.pas',
  PPG.Tests.Phase12b in 'PPG.Tests.Phase12b.pas',
  PPG.Tests.Phase12c in 'PPG.Tests.Phase12c.pas',
  PPG.Tests.Phase12d in 'PPG.Tests.Phase12d.pas',
  PPG.Tests.Phase13a in 'PPG.Tests.Phase13a.pas',
  PPG.Tests.Phase13b in 'PPG.Tests.Phase13b.pas',
  PPG.Tests.Phase13c in 'PPG.Tests.Phase13c.pas',
  PPG.Tests.Phase13d in 'PPG.Tests.Phase13d.pas',
  PPG.Tests.Phase13e in 'PPG.Tests.Phase13e.pas',
  PPG.Tests.Phase13f in 'PPG.Tests.Phase13f.pas',
  PPG.Tests.Phase17 in 'PPG.Tests.Phase17.pas',
  PPG.Tests.Phase18 in 'PPG.Tests.Phase18.pas',
  PPG.Tests.Phase19 in 'PPG.Tests.Phase19.pas',
  PPG.Tests.Phase13g in 'PPG.Tests.Phase13g.pas',
  PPG.Tests.Phase14a in 'PPG.Tests.Phase14a.pas',
  PPG.Tests.Phase14aPlanner in 'PPG.Tests.Phase14aPlanner.pas',
  PPG.Tests.Phase14aDB in 'PPG.Tests.Phase14aDB.pas',
  PPG.Tests.Phase14b in 'PPG.Tests.Phase14b.pas',
  PPG.Tests.Phase14bRibbon in 'PPG.Tests.Phase14bRibbon.pas',
  PPG.Tests.Phase14c in 'PPG.Tests.Phase14c.pas',
  PPG.Tests.Phase14cKanban in 'PPG.Tests.Phase14cKanban.pas',
  PPG.Tests.Phase14cDB in 'PPG.Tests.Phase14cDB.pas',
  PPG.Tests.Review in 'PPG.Tests.Review.pas',
  PPG.Tests.Custom in 'PPG.Tests.Custom.pas';

/// Belegter Speicher (Bytes) laut Speichermanager.
function AllocatedBytes: Int64;
var
  S: TMemoryManagerState;
  I: Integer;
begin
  GetMemoryManagerState(S);
  Result := S.TotalAllocatedMediumBlockSize + S.TotalAllocatedLargeBlockSize;
  for I := Low(S.SmallBlockTypeStates) to High(S.SmallBlockTypeStates) do
    Inc(Result, Int64(S.SmallBlockTypeStates[I].AllocatedBlockCount) *
      S.SmallBlockTypeStates[I].UseableBlockSize);
end;

/// Ein Durchlauf aller Tests; Ergebnis = Fehler + Failures.
function RunAll: Integer;
var
  R: TTestResult;
begin
  R := TextTestRunner.RunRegisteredTests(rxbContinue);
  try
    Result := R.ErrorCount + R.FailureCount;
  finally
    R.Free;
  end;
end;

/// Leck-Suche (/leaksuites): nach einem Lauf aller Tests (Caches fuellen)
/// jede Test-Klasse einzeln noch einmal; gemeldet wird jede Klasse, nach der
/// mehr als 1 KB mehr belegt ist ("LEAKSUITE Klasse Bytes").
procedure LeakSuites;
var
  Root, Grp, S: ITest;
  I, J: Integer;
  B, A: Int64;
  R: TTestResult;
begin
  RunAll;
  Root := RegisteredTests;
  for I := 0 to Root.Tests.Count - 1 do
  begin
    Grp := Root.Tests[I] as ITest;
    for J := 0 to Grp.Tests.Count - 1 do
    begin
      S := Grp.Tests[J] as ITest;
      Application.ProcessMessages;
      B := AllocatedBytes;
      R := TextTestRunner.RunTest(S, rxbContinue);
      R.Free;
      Application.ProcessMessages;
      A := AllocatedBytes;
      if A - B > 1024 then
        WriteLn(Format('LEAKSUITE %s.%s %d', [Grp.Name, S.Name, A - B]));
    end;
  end;
end;

const
  /// Erlaubter Zuwachs zwischen erstem und zweitem Lauf (Caches des
  /// Speichermanagers, Fenster-Klassen, Windows-Interna): 256 KB.
  LeakToleranceBytes = 256 * 1024;

var
  Errors: Integer;
  Before, After: Int64;
begin
  // Leak-Meldung beim Beenden (FastMM): nur im GUI-Modus, sonst blockiert
  // die MessageBox einen automatischen Lauf.
  Application.Initialize;
  if FindCmdLineSwitch('gui', ['/', '-'], True) then
  begin
    ReportMemoryLeaksOnShutdown := True;
    GUITestRunner.RunRegisteredTests;
    Exit;
  end;
  if FindCmdLineSwitch('leaksuites', ['/', '-'], True) then
  begin
    LeakSuites;
    Exit;
  end;
  if FindCmdLineSwitch('leaks', ['/', '-'], True) then
  begin
    // Leak-Lauf (Phase 9e): Der erste Lauf fuellt einmalige Caches (Registry,
    // Animator, Schriften). Waechst der Speicher danach von Lauf zu Lauf,
    // ist das ein echtes Leck. Exit-Code = Fehler + 1 bei Leck.
    Errors := RunAll;
    Application.ProcessMessages;
    Before := AllocatedBytes;
    Inc(Errors, RunAll);
    Application.ProcessMessages;
    After := AllocatedBytes;
    WriteLn(Format('Leak-Lauf: %d Bytes vor, %d Bytes nach dem zweiten Lauf (Zuwachs %d)',
      [Before, After, After - Before]));
    if After - Before > LeakToleranceBytes then
    begin
      WriteLn('LECK: Speicher waechst von Lauf zu Lauf');
      Inc(Errors);
    end;
    ExitCode := Errors;
    Exit;
  end;
  ExitCode := RunAll;
end.
