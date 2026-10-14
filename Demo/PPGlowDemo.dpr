program PPGlowDemo;

{ Showcase. Parameter:
    /screenshot <datei.png>  Formular rendern, als PNG speichern, beenden
                             (fuer automatisierte Sichtpruefung)
    /hover                   Hover-Zustand der markierten Buttons der Seite zeigen
    /gdi                     GDI-Fallback erzwingen (ohne GDI+)
    /focus                   Fokus auf den ersten Button der Seite, Fokus-Cues sichtbar
    /fieldfocus              Fokus in das erste Formularfeld (Fokuslinie)
    /dropdown                ComboBox "Anrede" aufgeklappt (Popup wird mit eingezeichnet)
    /dropdownimages          ComboBox mit Bildern (Seite Listen) aufgeklappt
    /page <n>                Seite n zeigen: 0 Start, 1 Buttons, 2 Auswahl, 3 Formular,
                             4 Listen, 5 Explorer, 6 Tabelle, 7 Termine, 8 Layout,
                             9 Rueckmeldung, 10 Darstellung, 11 Ereignisse, 12 Datenbank
    /preset <Name>           Preset fuer alle Controls (Standard: Fluent11)
    /theme dark|light|system Dark Mode ohne VCL-Style
    /style <Name>            VCL-Style aktivieren (z.B. Windows10Dark)
    /datepopup <datei.png>   DatePicker aufklappen, Fenster speichern
    /toastcapture <datei.png> drei Toasts zeigen, Bildschirmecke speichern
                             (Aufnahmen zeigen nur Fenster der Demo, auch mit /hidden)
    /ribboncapture <modus> <datei.png>  Ribbon: keytips, keytips2, minimized, group, groupkeys, gallery
    /busycapture <modus> <datei.png>    Bestellung: busy (Warte-Overlay) oder errors (Validator)
    /mica [/screencapture <datei.png>]  Prototyp Mica-Hintergrund
    /show <Klasse>           Komponentenseite zeigen (z.B. TPPGButton)
    /tab <n>                 dort Reiter n: 0 Ausprobieren, 1.. Praxisbeispiele, zuletzt Ueberblick
    /bottomtab <n>           unten rechts: 0 Ereignisse, 1 Code (Pascal), 2 DFM
    /showcode                in den Praxisbeispielen den Code einblenden
    /select <Pfad>           Eigenschaft im Inspektor waehlen (z.B. Appearance.Normal.Color)
    /only <Klasse>           mit /selftest: nur die Komponentenseite dieser Klasse pruefen
    /selftest <datei.txt>    Szenarien aller Seiten pruefen, Exit-Code = Fehlerzahl
    /hidden                  auf eigenem Windows-Desktop laufen (keine Fenster auf dem Bildschirm) }

uses
  System.SysUtils,
  PPG.TestDesktop in '..\Tests\PPG.TestDesktop.pas',
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Forms,
  Vcl.Controls,
  MidasLib,
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
  PPG.Markup.Parser in '..\Source\Core\PPG.Markup.Parser.pas',
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
  PPG.Planner.Dialog in '..\Source\Controls\PPG.Planner.Dialog.pas',
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
  PPG.DB.Controls in '..\Source\DB\PPG.DB.Controls.pas',
  PPG.DB.Lookup in '..\Source\DB\PPG.DB.Lookup.pas',
  PPG.DB.Grid in '..\Source\DB\PPG.DB.Grid.pas',
  PPG.DB.Chart in '..\Source\DB\PPG.DB.Chart.pas',
  PPG.DB.Planner in '..\Source\DB\PPG.DB.Planner.pas',
  PPG.DB.Kanban in '..\Source\DB\PPG.DB.Kanban.pas',
  PPG.DB.Navigator in '..\Source\DB\PPG.DB.Navigator.pas',
  PPG.DB.Validator in '..\Source\DB\PPG.DB.Validator.pas',
  PPG.DB.Fields in '..\Source\DB\PPG.DB.Fields.pas',
  DemoKit in 'DemoKit.pas',
  DemoPages1 in 'DemoPages1.pas',
  DemoPages2 in 'DemoPages2.pas',
  DemoPages3 in 'DemoPages3.pas',
  DemoPages4 in 'DemoPages4.pas',
  DemoPages5 in 'DemoPages5.pas',
  DemoPages6 in 'DemoPages6.pas',
  DemoPages7 in 'DemoPages7.pas',
  DemoPages8 in 'DemoPages8.pas',
  DemoPages9 in 'DemoPages9.pas',
  DemoPages10 in 'DemoPages10.pas',
  DemoPages11 in 'DemoPages11.pas',
  DemoDocs in 'Showcase\DemoDocs.pas',
  DemoInspector in 'Showcase\DemoInspector.pas',
  DemoCodeGen in 'Showcase\DemoCodeGen.pas',
  DemoShowcase in 'Showcase\DemoShowcase.pas',
  ExButtonDialog in 'Showcase\ExButtonDialog.pas',
  ExButtonToolbar in 'Showcase\ExButtonToolbar.pas',
  DemoShowButton in 'Showcase\DemoShowButton.pas',
  ExCheckBoxOrder in 'Showcase\ExCheckBoxOrder.pas',
  ExCheckBoxRights in 'Showcase\ExCheckBoxRights.pas',
  ExCheckComboBoxFilter in 'Showcase\ExCheckComboBoxFilter.pas',
  ExCheckComboBoxSettings in 'Showcase\ExCheckComboBoxSettings.pas',
  ExCheckGroupNotify in 'Showcase\ExCheckGroupNotify.pas',
  ExCheckGroupRights in 'Showcase\ExCheckGroupRights.pas',
  ExColorPickerCategories in 'Showcase\ExColorPickerCategories.pas',
  ExColorPickerHighlight in 'Showcase\ExColorPickerHighlight.pas',
  ExComboBoxAddress in 'Showcase\ExComboBoxAddress.pas',
  ExComboBoxArticle in 'Showcase\ExComboBoxArticle.pas',
  ExEditCustomer in 'Showcase\ExEditCustomer.pas',
  ExEditSearch in 'Showcase\ExEditSearch.pas',
  ExFileEditBackup in 'Showcase\ExFileEditBackup.pas',
  ExFileEditImport in 'Showcase\ExFileEditImport.pas',
  ExMemoComment in 'Showcase\ExMemoComment.pas',
  ExMemoHistory in 'Showcase\ExMemoHistory.pas',
  ExNumberEditInvoice in 'Showcase\ExNumberEditInvoice.pas',
  ExNumberEditStock in 'Showcase\ExNumberEditStock.pas',
  ExPasswordEditChange in 'Showcase\ExPasswordEditChange.pas',
  ExPasswordEditLogin in 'Showcase\ExPasswordEditLogin.pas',
  ExRadioButtonExport in 'Showcase\ExRadioButtonExport.pas',
  ExRadioButtonShipping in 'Showcase\ExRadioButtonShipping.pas',
  ExRatingFeedback in 'Showcase\ExRatingFeedback.pas',
  ExRatingSupplier in 'Showcase\ExRatingSupplier.pas',
  ExRibbonInvoice in 'Showcase\ExRibbonInvoice.pas',
  ExRibbonReport in 'Showcase\ExRibbonReport.pas',
  ExSearchEditCustomer in 'Showcase\ExSearchEditCustomer.pas',
  ExSearchEditFilter in 'Showcase\ExSearchEditFilter.pas',
  ExSpinEditAutoSave in 'Showcase\ExSpinEditAutoSave.pas',
  ExSpinEditOrder in 'Showcase\ExSpinEditOrder.pas',
  ExToggleSwitchFilter in 'Showcase\ExToggleSwitchFilter.pas',
  ExToggleSwitchSettings in 'Showcase\ExToggleSwitchSettings.pas',
  ExToolBarActions in 'Showcase\ExToolBarActions.pas',
  ExToolBarList in 'Showcase\ExToolBarList.pas',
  ExTrackBarPriceFilter in 'Showcase\ExTrackBarPriceFilter.pas',
  ExTrackBarSettings in 'Showcase\ExTrackBarSettings.pas',
  DemoShowCheckBox in 'Showcase\DemoShowCheckBox.pas',
  DemoShowCheckComboBox in 'Showcase\DemoShowCheckComboBox.pas',
  DemoShowCheckGroup in 'Showcase\DemoShowCheckGroup.pas',
  DemoShowColorPicker in 'Showcase\DemoShowColorPicker.pas',
  DemoShowComboBox in 'Showcase\DemoShowComboBox.pas',
  DemoShowEdit in 'Showcase\DemoShowEdit.pas',
  DemoShowFileEdit in 'Showcase\DemoShowFileEdit.pas',
  DemoShowMemo in 'Showcase\DemoShowMemo.pas',
  DemoShowNumberEdit in 'Showcase\DemoShowNumberEdit.pas',
  DemoShowPasswordEdit in 'Showcase\DemoShowPasswordEdit.pas',
  DemoShowRadioButton in 'Showcase\DemoShowRadioButton.pas',
  DemoShowRating in 'Showcase\DemoShowRating.pas',
  DemoShowRibbon in 'Showcase\DemoShowRibbon.pas',
  DemoShowSearchEdit in 'Showcase\DemoShowSearchEdit.pas',
  DemoShowSpinEdit in 'Showcase\DemoShowSpinEdit.pas',
  DemoShowToggleSwitch in 'Showcase\DemoShowToggleSwitch.pas',
  DemoShowToolBar in 'Showcase\DemoShowToolBar.pas',
  DemoShowTrackBar in 'Showcase\DemoShowTrackBar.pas',
  ExTagEditRecipients in 'Showcase\ExTagEditRecipients.pas',
  ExTagEditTicket in 'Showcase\ExTagEditTicket.pas',
  DemoShowTagEdit in 'Showcase\DemoShowTagEdit.pas',
  ExRadioGroupShipping in 'Showcase\ExRadioGroupShipping.pas',
  ExRadioGroupSubscription in 'Showcase\ExRadioGroupSubscription.pas',
  DemoShowRadioGroup in 'Showcase\DemoShowRadioGroup.pas',
  ExMaskEditCustomer in 'Showcase\ExMaskEditCustomer.pas',
  ExMaskEditTimeEntry in 'Showcase\ExMaskEditTimeEntry.pas',
  DemoShowMaskEdit in 'Showcase\DemoShowMaskEdit.pas',
  ExGridExport in 'Showcase\ExGridExport.pas',
  ExGridStock in 'Showcase\ExGridStock.pas',
  DemoShowGrid in 'Showcase\DemoShowGrid.pas',
  DemoMain in 'DemoMain.pas';

{$R *.res}
// Texte und Beispielquellen der Komponentenseiten (Build\make-showcase.ps1)
{$R 'Showcase\ShowcaseData.res'}

var
  Form: TDemoForm;
  I: Integer;
  ShotFile: string;
  ShowCls: string;
  ShowTab, BottomTab: Integer;
  SelectPath: string;
  OnlyCls: string;
  Tick: Cardinal;
begin
  // /hidden: auf eigenem Windows-Desktop neu starten (keine Fenster auf dem Bildschirm)
  if PPGRunOnHiddenDesktop then
    Exit;
  {$WARN SYMBOL_PLATFORM OFF}
  ReportMemoryLeaksOnShutdown := DebugHook <> 0;
  {$WARN SYMBOL_PLATFORM ON}
  Application.Initialize;
  if FindCmdLineSwitch('gdi', ['/', '-'], True) then
    TPPGRendererRegistry.ForceGdiFallback := True;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDemoForm, Form);

  ShotFile := '';
  ShowCls := '';
  ShowTab := -1;
  BottomTab := -1;
  SelectPath := '';
  OnlyCls := '';
  for I := 1 to ParamCount - 1 do
  begin
    if SameText(ParamStr(I), '/screenshot') then
      ShotFile := ParamStr(I + 1);
    // /style Windows10Dark  -> VCL-Style aus dem Styles-Ordner aktivieren
    if SameText(ParamStr(I), '/style') then
      Form.ApplyVclStyle(ParamStr(I + 1));
    // /preset Fluent11  -> alle Controls in einem Preset zeigen
    if SameText(ParamStr(I), '/preset') then
      Form.ApplyPreset(ParamStr(I + 1));
    // /theme dark|light|system  -> Dark Mode ohne VCL-Style
    if SameText(ParamStr(I), '/theme') then
      Form.ApplyTheme(ParamStr(I + 1));
    if SameText(ParamStr(I), '/page') then
      Form.ShowPage(StrToIntDef(ParamStr(I + 1), 0));
    if SameText(ParamStr(I), '/show') then
      ShowCls := ParamStr(I + 1);
    if SameText(ParamStr(I), '/tab') then
      ShowTab := StrToIntDef(ParamStr(I + 1), 0);
    if SameText(ParamStr(I), '/bottomtab') then
      BottomTab := StrToIntDef(ParamStr(I + 1), 0);
    if SameText(ParamStr(I), '/select') then
      SelectPath := ParamStr(I + 1);
    if SameText(ParamStr(I), '/only') then
      OnlyCls := ParamStr(I + 1);
    // /scroll y  -> aktive Seite scrollen (nach /page)
    if SameText(ParamStr(I), '/scroll') then
      Form.ScrollActivePage(StrToIntDef(ParamStr(I + 1), 0));
    // /height n  -> Fensterhoehe (Screenshots von Karten weiter unten)
    if SameText(ParamStr(I), '/height') then
      Form.ClientHeight := StrToIntDef(ParamStr(I + 1), Form.ClientHeight);
  end;

  if ShowCls <> '' then
    Form.ShowShowcase(ShowCls, ShowTab, BottomTab, SelectPath,
      FindCmdLineSwitch('showcode', ['/', '-'], True));

  if ShotFile <> '' then
  begin
    Form.Show;
    Application.ProcessMessages;
    if FindCmdLineSwitch('hover', ['/', '-'], True) then
      Form.ShowHoverDemo;
    if FindCmdLineSwitch('focus', ['/', '-'], True) then
      Form.ShowFocusDemo;
    if FindCmdLineSwitch('fieldfocus', ['/', '-'], True) then
      Form.FocusDemoField;
    if FindCmdLineSwitch('dropdown', ['/', '-'], True) then
      Form.DropDownDemoCombo;
    if FindCmdLineSwitch('dropdownimages', ['/', '-'], True) then
      Form.DropDownImageCombo;
    Application.ProcessMessages;
    Form.SaveScreenshot(ShotFile);
    Exit;
  end;

  // /selftest datei.txt: alle Seiten-Szenarien pruefen, Exit-Code = Fehlerzahl
  for I := 1 to ParamCount - 1 do
    if SameText(ParamStr(I), '/selftest') then
    begin
      Form.Show;
      ExitCode := Form.RunSelfTest(ParamStr(I + 1), OnlyCls);
      Exit;
    end;

  // /datepopup datei.png: DatePicker aufklappen, Fenster speichern
  for I := 1 to ParamCount - 1 do
    if SameText(ParamStr(I), '/datepopup') then
    begin
      Form.Show;
      Form.SaveDatePopupCapture(ParamStr(I + 1));
      Exit;
    end;

  // /chartpng seite key datei.png: registriertes Diagramm ueber SaveToPng (Export)
  for I := 1 to ParamCount - 3 do
    if SameText(ParamStr(I), '/chartpng') then
    begin
      Form.Show;
      Form.ShowPage(StrToIntDef(ParamStr(I + 1), 0));
      Application.ProcessMessages;
      if not Form.SaveChartPng(ParamStr(I + 2), ParamStr(I + 3)) then
        ExitCode := 1;
      Exit;
    end;

  // /export seite key datei.(xlsx|html|png): registrierte Tabelle exportieren
  // (wie die Knoepfe Excel und HTML; png = erste Druckseite)
  for I := 1 to ParamCount - 3 do
    if SameText(ParamStr(I), '/export') then
    begin
      Form.Show;
      Form.ShowPage(StrToIntDef(ParamStr(I + 1), 0));
      Application.ProcessMessages;
      if not Form.SaveTableExport(ParamStr(I + 2), ParamStr(I + 3)) then
        ExitCode := 1;
      Exit;
    end;

  // /busycapture modus datei.png: Warte-Overlay bzw. Validator-Fehler, Bildschirmpixel
  for I := 1 to ParamCount - 2 do
    if SameText(ParamStr(I), '/busycapture') then
    begin
      Form.Show;
      Form.SaveBusyCapture(ParamStr(I + 1), ParamStr(I + 2));
      Exit;
    end;

  // /ribboncapture modus datei.png: Ribbon-Zustand (KeyTips, Popups), Bildschirmpixel
  for I := 1 to ParamCount - 2 do
    if SameText(ParamStr(I), '/ribboncapture') then
    begin
      Form.Show;
      Form.SaveRibbonCapture(ParamStr(I + 1), ParamStr(I + 2));
      Exit;
    end;

  // /toastcapture datei.png: drei Toasts zeigen, Bildschirmecke speichern
  for I := 1 to ParamCount - 1 do
    if SameText(ParamStr(I), '/toastcapture') then
    begin
      Form.Show;
      Form.SaveToastCapture(ParamStr(I + 1));
      Exit;
    end;

  // Prototyp 8.4: /mica [/screencapture datei.png] - echte Bildschirmpixel,
  // weil Mica nur im vom DWM zusammengesetzten Bild existiert
  if FindCmdLineSwitch('mica', ['/', '-'], True) then
  begin
    Form.Show;
    Form.EnableMica;
    ShotFile := '';
    for I := 1 to ParamCount - 1 do
      if SameText(ParamStr(I), '/screencapture') then
        ShotFile := ParamStr(I + 1);
    if ShotFile <> '' then
    begin
      SetForegroundWindow(Form.Handle);
      Tick := GetTickCount;
      while GetTickCount - Tick < 1500 do
      begin
        Application.ProcessMessages;
        Sleep(15);
      end;
      Form.SaveScreenCapture(ShotFile);
      Exit;
    end;
  end;
  Application.Run;
end.
