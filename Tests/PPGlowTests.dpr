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
  PPG.Editors.Logic in '..\Source\Editors\PPG.Editors.Logic.pas',
  PPG.Editors.Forms in '..\Source\Editors\PPG.Editors.Forms.pas',
  PPG.DB.Controls in '..\Source\DB\PPG.DB.Controls.pas',
  PPG.DB.Lookup in '..\Source\DB\PPG.DB.Lookup.pas',
  PPG.DB.Grid in '..\Source\DB\PPG.DB.Grid.pas',
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
  PPG.Tests.Phase9d in 'PPG.Tests.Phase9d.pas';

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
