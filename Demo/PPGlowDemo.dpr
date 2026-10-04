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
                             9 Rueckmeldung, 10 Darstellung, 11 Ereignisse
    /preset <Name>           Preset fuer alle Controls (Standard: Fluent11)
    /theme dark|light|system Dark Mode ohne VCL-Style
    /style <Name>            VCL-Style aktivieren (z.B. Windows10Dark)
    /datepopup <datei.png>   DatePicker aufklappen, Bildschirmpixel speichern
    /toastcapture <datei.png> drei Toasts zeigen, Bildschirmecke speichern
    /mica [/screencapture <datei.png>]  Prototyp Mica-Hintergrund
    /selftest <datei.txt>    Szenarien aller Seiten pruefen, Exit-Code = Fehlerzahl }

uses
  System.SysUtils,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Forms,
  Vcl.Controls,
  PPG.Consts in '..\Source\Core\PPG.Consts.pas',
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
  DemoKit in 'DemoKit.pas',
  DemoPages1 in 'DemoPages1.pas',
  DemoPages2 in 'DemoPages2.pas',
  DemoPages3 in 'DemoPages3.pas',
  DemoMain in 'DemoMain.pas';

{$R *.res}

var
  Form: TDemoForm;
  I: Integer;
  ShotFile: string;
  Tick: Cardinal;
begin
  {$WARN SYMBOL_PLATFORM OFF}
  ReportMemoryLeaksOnShutdown := DebugHook <> 0;
  {$WARN SYMBOL_PLATFORM ON}
  Application.Initialize;
  if FindCmdLineSwitch('gdi', ['/', '-'], True) then
    TPPGRendererRegistry.ForceGdiFallback := True;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDemoForm, Form);

  ShotFile := '';
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
  end;

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
      ExitCode := Form.RunSelfTest(ParamStr(I + 1));
      Exit;
    end;

  // /datepopup datei.png: DatePicker aufklappen, Bildschirmpixel speichern
  for I := 1 to ParamCount - 1 do
    if SameText(ParamStr(I), '/datepopup') then
    begin
      Form.Show;
      Form.SaveDatePopupCapture(ParamStr(I + 1));
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
