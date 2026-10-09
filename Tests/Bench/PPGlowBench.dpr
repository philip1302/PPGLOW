program PPGlowBench;

{ Leistungsmessung der Suite (Phase 5). Konsole; Exit-Code = Anzahl
  ueberschrittener Zeitvorgaben. Bauen: build.ps1 -Projects Bench -Config Release }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  PPG.TestDesktop in '..\PPG.TestDesktop.pas',
  System.IOUtils,
  System.Variants,
  System.Classes,
  System.Types,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Menus,
  PPG.Consts in '..\..\Source\Core\PPG.Consts.pas',
  PPG.Lang in '..\..\Source\Core\PPG.Lang.pas',
  PPG.Lang.De in '..\..\Source\Core\PPG.Lang.De.pas',
  PPG.Exceptions in '..\..\Source\Core\PPG.Exceptions.pas',
  PPG.ErrorHandler in '..\..\Source\Core\PPG.ErrorHandler.pas',
  PPG.Types in '..\..\Source\Core\PPG.Types.pas',
  PPG.Tokens in '..\..\Source\Core\PPG.Tokens.pas',
  PPG.ElementStyle in '..\..\Source\Core\PPG.ElementStyle.pas',
  PPG.Appearance in '..\..\Source\Core\PPG.Appearance.pas',
  PPG.Animation in '..\..\Source\Core\PPG.Animation.pas',
  PPG.Layout in '..\..\Source\Core\PPG.Layout.pas',
  PPG.DpiUtils in '..\..\Source\Core\PPG.DpiUtils.pas',
  PPG.Render.Intf in '..\..\Source\Render\PPG.Render.Intf.pas',
  PPG.Render.Gdi in '..\..\Source\Render\PPG.Render.Gdi.pas',
  PPG.Render.GdiPlus in '..\..\Source\Render\PPG.Render.GdiPlus.pas',
  PPG.Render.Registry in '..\..\Source\Render\PPG.Render.Registry.pas',
  PPG.Render.Classic in '..\..\Source\Render\PPG.Render.Classic.pas',
  PPG.Render.ModernFlat in '..\..\Source\Render\PPG.Render.ModernFlat.pas',
  PPG.IconFont in '..\..\Source\Render\PPG.IconFont.pas',
  PPG.Render.Fluent11 in '..\..\Source\Render\PPG.Render.Fluent11.pas',
  PPG.Presets in '..\..\Source\Theme\PPG.Presets.pas',
  PPG.StyleManager in '..\..\Source\Theme\PPG.StyleManager.pas',
  PPG.Theme in '..\..\Source\Theme\PPG.Theme.pas',
  PPG.VclStyles in '..\..\Source\Theme\PPG.VclStyles.pas',
  PPG.ThemeFile in '..\..\Source\Theme\PPG.ThemeFile.pas',
  PPG.Accessibility in '..\..\Source\Access\PPG.Accessibility.pas',
  PPG.UIA.Intf in '..\..\Source\Access\PPG.UIA.Intf.pas',
  PPG.UIA in '..\..\Source\Access\PPG.UIA.pas',
  PPG.Controls.Base in '..\..\Source\Controls\PPG.Controls.Base.pas',
  PPG.Button in '..\..\Source\Controls\PPG.Button.pas',
  PPG.Controls.Check in '..\..\Source\Controls\PPG.Controls.Check.pas',
  PPG.CheckBox in '..\..\Source\Controls\PPG.CheckBox.pas',
  PPG.RadioButton in '..\..\Source\Controls\PPG.RadioButton.pas',
  PPG.ToggleSwitch in '..\..\Source\Controls\PPG.ToggleSwitch.pas',
  PPG.Controls.Range in '..\..\Source\Controls\PPG.Controls.Range.pas',
  PPG.ProgressBar in '..\..\Source\Controls\PPG.ProgressBar.pas',
  PPG.TrackBar in '..\..\Source\Controls\PPG.TrackBar.pas',
  PPG.Controls.Container in '..\..\Source\Controls\PPG.Controls.Container.pas',
  PPG.Panel in '..\..\Source\Controls\PPG.Panel.pas',
  PPG.GroupBox in '..\..\Source\Controls\PPG.GroupBox.pas',
  PPG.RadioGroup in '..\..\Source\Controls\PPG.RadioGroup.pas',
  PPG.TileView in '..\..\Source\Controls\PPG.TileView.pas',
  PPG.Validator in '..\..\Source\Controls\PPG.Validator.pas',
  PPG.Overlay in '..\..\Source\Controls\PPG.Overlay.pas',
  PPG.BusyOverlay in '..\..\Source\Controls\PPG.BusyOverlay.pas',
  PPG.Controls.Field in '..\..\Source\Controls\PPG.Controls.Field.pas',
  PPG.Edit in '..\..\Source\Controls\PPG.Edit.pas',
  PPG.Memo in '..\..\Source\Controls\PPG.Memo.pas',
  PPG.SpinEdit in '..\..\Source\Controls\PPG.SpinEdit.pas',
  PPG.Popup in '..\..\Source\Controls\PPG.Popup.pas',
  PPG.ComboBox in '..\..\Source\Controls\PPG.ComboBox.pas',
  PPG.TabStrip in '..\..\Source\Controls\PPG.TabStrip.pas',
  PPG.TabControl in '..\..\Source\Controls\PPG.TabControl.pas',
  PPG.PageControl in '..\..\Source\Controls\PPG.PageControl.pas',
  PPG.Selection in '..\..\Source\Core\PPG.Selection.pas',
  PPG.Items in '..\..\Source\Core\PPG.Items.pas',
  PPG.Markup.Parser in '..\..\Source\Core\PPG.Markup.Parser.pas',
  PPG.Markup in '..\..\Source\Render\PPG.Markup.pas',
  PPG.RowLayout in '..\..\Source\Controls\PPG.RowLayout.pas',
  PPG.Controls.Scroll in '..\..\Source\Controls\PPG.Controls.Scroll.pas',
  PPG.ItemPainter in '..\..\Source\Controls\PPG.ItemPainter.pas',
  PPG.CustomDraw in '..\..\Source\Controls\PPG.CustomDraw.pas',
  PPG.Controls.ItemList in '..\..\Source\Controls\PPG.Controls.ItemList.pas',
  PPG.ListBox in '..\..\Source\Controls\PPG.ListBox.pas',
  PPG.CheckListBox in '..\..\Source\Controls\PPG.CheckListBox.pas',
  PPG.TreeView in '..\..\Source\Controls\PPG.TreeView.pas',
  PPG.Grid in '..\..\Source\Controls\PPG.Grid.pas',
  PPG.Labels in '..\..\Source\Controls\PPG.Labels.pas',
  PPG.Feedback in '..\..\Source\Controls\PPG.Feedback.pas',
  PPG.Expander in '..\..\Source\Controls\PPG.Expander.pas',
  PPG.Splitter in '..\..\Source\Controls\PPG.Splitter.pas',
  PPG.Rating in '..\..\Source\Controls\PPG.Rating.pas',
  PPG.SearchEdit in '..\..\Source\Controls\PPG.SearchEdit.pas',
  PPG.Calendar in '..\..\Source\Controls\PPG.Calendar.pas',
  PPG.DatePicker in '..\..\Source\Controls\PPG.DatePicker.pas',
  PPG.TimePicker in '..\..\Source\Controls\PPG.TimePicker.pas',
  PPG.NavigationView in '..\..\Source\Controls\PPG.NavigationView.pas',
  PPG.Breadcrumb in '..\..\Source\Controls\PPG.Breadcrumb.pas',
  PPG.ToolBar in '..\..\Source\Controls\PPG.ToolBar.pas',
  PPG.StatusBar in '..\..\Source\Controls\PPG.StatusBar.pas',
  PPG.Notifications in '..\..\Source\Controls\PPG.Notifications.pas',
  PPG.Planner.Print in '..\..\Source\Controls\PPG.Planner.Print.pas',
  PPG.Kanban.Print in '..\..\Source\Controls\PPG.Kanban.Print.pas',
  PPG.KeyTips in '..\..\Source\Core\PPG.KeyTips.pas',
  PPG.Ribbon.Layout in '..\..\Source\Core\PPG.Ribbon.Layout.pas',
  PPG.Ribbon.Items in '..\..\Source\Controls\PPG.Ribbon.Items.pas',
  PPG.Ribbon in '..\..\Source\Controls\PPG.Ribbon.pas',
  PPG.Kanban.Layout in '..\..\Source\Core\PPG.Kanban.Layout.pas',
  PPG.Kanban.Items in '..\..\Source\Controls\PPG.Kanban.Items.pas',
  PPG.Kanban in '..\..\Source\Controls\PPG.Kanban.pas',
  PPG.Print in '..\..\Source\Controls\PPG.Print.pas',
  PPG.Planner in '..\..\Source\Controls\PPG.Planner.pas',
  PPG.Planner.Dialog in '..\..\Source\Controls\PPG.Planner.Dialog.pas',
  PPG.TimeZones in '..\..\Source\Core\PPG.TimeZones.pas',
  PPG.Planner.Recurrence in '..\..\Source\Core\PPG.Planner.Recurrence.pas',
  PPG.Planner.Layout in '..\..\Source\Core\PPG.Planner.Layout.pas',
  PPG.Planner.Model in '..\..\Source\Core\PPG.Planner.Model.pas',
  PPG.Planner.ICal in '..\..\Source\Core\PPG.Planner.ICal.pas',
  PPG.Grid.Look in '..\..\Source\Controls\PPG.Grid.Look.pas',
  PPG.Xlsx in '..\..\Source\Controls\PPG.Xlsx.pas',
  PPG.Grid.Export in '..\..\Source\Controls\PPG.Grid.Export.pas',
  PPG.Grid.Print in '..\..\Source\Controls\PPG.Grid.Print.pas',
  PPG.Grid.Styles in '..\..\Source\Controls\PPG.Grid.Styles.pas',
  PPG.Grid.CellKinds in '..\..\Source\Controls\PPG.Grid.CellKinds.pas',
  PPG.Grid.Edit in '..\..\Source\Controls\PPG.Grid.Edit.pas',
  PPG.Grid.Paint in '..\..\Source\Controls\PPG.Grid.Paint.pas',
  PPG.Grid.Data in '..\..\Source\Controls\PPG.Grid.Data.pas',
  PPG.Grid.View in '..\..\Source\Controls\PPG.Grid.View.pas',
  PPG.Grid.Columns in '..\..\Source\Controls\PPG.Grid.Columns.pas',
  PPG.TagEdit in '..\..\Source\Controls\PPG.TagEdit.pas',
  PPG.ColumnComboBox in '..\..\Source\Controls\PPG.ColumnComboBox.pas',
  PPG.RowPopup in '..\..\Source\Controls\PPG.RowPopup.pas',
  PPG.CheckComboBox in '..\..\Source\Controls\PPG.CheckComboBox.pas',
  PPG.ColorSpace in '..\..\Source\Core\PPG.ColorSpace.pas',
  PPG.Controls.DropDown in '..\..\Source\Controls\PPG.Controls.DropDown.pas',
  PPG.ColorPicker in '..\..\Source\Controls\PPG.ColorPicker.pas',
  PPG.FileEdit in '..\..\Source\Controls\PPG.FileEdit.pas',
  PPG.MaskEdit in '..\..\Source\Controls\PPG.MaskEdit.pas',
  PPG.PasswordEdit in '..\..\Source\Controls\PPG.PasswordEdit.pas',
  PPG.NumberFormat in '..\..\Source\Core\PPG.NumberFormat.pas',
  PPG.NumberEdit in '..\..\Source\Controls\PPG.NumberEdit.pas',
  PPG.Wizard in '..\..\Source\Controls\PPG.Wizard.pas',
  PPG.Dialogs in '..\..\Source\Controls\PPG.Dialogs.pas',
  PPG.TeachingTip in '..\..\Source\Controls\PPG.TeachingTip.pas',
  PPG.Hints in '..\..\Source\Controls\PPG.Hints.pas',
  PPG.MenuBar in '..\..\Source\Controls\PPG.MenuBar.pas',
  PPG.Popup.Placement in '..\..\Source\Core\PPG.Popup.Placement.pas',
  PPG.AppHooks in '..\..\Source\Controls\PPG.AppHooks.pas',
  PPG.Menus in '..\..\Source\Controls\PPG.Menus.pas',
  PPG.Chart.Series in '..\..\Source\Controls\PPG.Chart.Series.pas',
  PPG.Chart in '..\..\Source\Controls\PPG.Chart.pas',
  PPG.Chart.Scale in '..\..\Source\Core\PPG.Chart.Scale.pas',
  PPG.Chart.Palette in '..\..\Source\Core\PPG.Chart.Palette.pas',
  PPG.Render.Shapes in '..\..\Source\Render\PPG.Render.Shapes.pas',
  PPG.Sparkline in '..\..\Source\Controls\PPG.Sparkline.pas',
  PPG.Gauge in '..\..\Source\Controls\PPG.Gauge.pas';

{$R *.res}

type
  /// Scroll-Control mit 100 000 Zeilen (nur sichtbare Zeilen zeichnen).
  TBenchScroller = class(TPPGCustomScrollControl)
  protected
    procedure PaintViewport(const ACanvas: IPPGCanvas; const View: TRect); override;
  end;

  /// Ereignis-Handler der Daten-Controls (Ereignisse brauchen Methoden).
  TCalAccessB = class(TPPGCalendar);
  /// Audit 8D: Hoehe der InfoBar wie in der Oeffnen-Animation anfordern.
  TInfoBarAccessB = class(TPPGInfoBar);
  /// Audit 11a: KeyDown (geschuetzt) fuer die Tastatur im Benchmark.
  TWinControlAccessB = class(TWinControl);

  /// Virtuelle Tabelle fuer Export und Druck (1 000 000 Zeilen)
  TBenchTable = class(TInterfacedObject, IPPGTableSource)
  public
    function TableColCount: Integer;
    function TableRowCount: Integer;
    function TableColumn(ACol: Integer): TPPGTableColumnInfo;
    function TableCellText(ACol, ARow: Integer): string;
    function TableCellValue(ACol, ARow: Integer): Variant;
  end;

  TBenchData = class
  public
    procedure ListData(Control: TWinControl; Index: Integer; var Data: string);
    procedure GridText(Sender: TObject; ACol, ARow: Integer; var Text: string);
    procedure GroupText(Sender: TObject; ACol, ARow: Integer; var Text: string);
    procedure TileItem(Sender: TObject; Index: Integer; var Data: TPPGItemData);
    procedure KanbanCard(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer;
      var Data: TPPGKanbanCardData);
    procedure ComboCell(Sender: TObject; Row, Column: Integer; var Text: string);
  end;

  TBenchProc = reference to procedure;

var
  Exceeded: Integer = 0;
  Form: TForm;
  VclMs: Cardinal;

procedure TBenchScroller.PaintViewport(const ACanvas: IPPGCanvas; const View: TRect);
var
  I, Y: Integer;
begin
  I := ScrollY div 20;
  Y := View.Top + I * 20 - ScrollY;
  while Y < View.Bottom do
  begin
    ACanvas.DrawText(Rect(View.Left + 4, Y, View.Right, Y + 20), 'Zeile ' + IntToStr(I),
      Font, clBlack, DT_SINGLELINE or DT_VCENTER);
    Inc(Y, 20);
    Inc(I);
  end;
end;

procedure TBenchData.ListData(Control: TWinControl; Index: Integer; var Data: string);
begin
  Data := 'Eintrag ' + IntToStr(Index);
end;

function TBenchTable.TableColCount: Integer;
begin
  Result := 5;
end;

function TBenchTable.TableRowCount: Integer;
begin
  Result := 1000000;
end;

function TBenchTable.TableColumn(ACol: Integer): TPPGTableColumnInfo;
begin
  Result.Title := 'Spalte ' + IntToStr(ACol);
  Result.Width := 90;
  Result.Alignment := taLeftJustify;
  Result.Format := '';
end;

function TBenchTable.TableCellText(ACol, ARow: Integer): string;
begin
  if Odd(ACol) then
    Result := 'Text ' + IntToStr(ARow mod 1000)
  else
    Result := IntToStr(ARow * 7 + ACol);
end;

function TBenchTable.TableCellValue(ACol, ARow: Integer): Variant;
begin
  if Odd(ACol) then
    Result := TableCellText(ACol, ARow)
  else
    Result := ARow * 7 + ACol;
end;

procedure TBenchData.GridText(Sender: TObject; ACol, ARow: Integer; var Text: string);
begin
  Text := IntToStr(ARow * 31 + ACol);
end;

procedure TBenchData.GroupText(Sender: TObject; ACol, ARow: Integer; var Text: string);
begin
  // Spalte 1: 100 Gruppen, Spalte 2: Zahlen fuer die Summe
  case ACol of
    1: Text := 'Gruppe ' + IntToStr(ARow mod 100);
    2: Text := IntToStr(ARow mod 1000);
  else
    Text := IntToStr(ARow);
  end;
end;

procedure TBenchData.TileItem(Sender: TObject; Index: Integer; var Data: TPPGItemData);
begin
  Data.Text := 'Produkt ' + IntToStr(Index);
  Data.Detail := 'Lager ' + IntToStr(Index mod 17);
  Data.Group := 'Gruppe ' + IntToStr(Index div 1000);
end;

function Measure(const Name: string; BudgetMs: Cardinal; const Proc: TBenchProc): Cardinal;
var
  T0, Ms: Cardinal;
  Verdict: string;
begin
  T0 := GetTickCount;
  Proc();
  Ms := GetTickCount - T0;
  Result := Ms;
  if Ms > BudgetMs then
  begin
    Inc(Exceeded);
    Verdict := 'ZU LANGSAM';
  end
  else
    Verdict := 'ok';
  if BudgetMs = High(Cardinal) then
    Writeln(Format('%-52s %6d ms  (Referenz)', [Name, Ms]))
  else
    Writeln(Format('%-52s %6d ms  (Vorgabe %5d ms)  %s', [Name, Ms, BudgetMs, Verdict]));
end;

procedure PaintToBitmap(C: TWinControl);
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(C.Width, C.Height);
    Bmp.Canvas.Lock;
    try
      C.PaintTo(Bmp.Canvas.Handle, 0, 0);
    finally
      Bmp.Canvas.Unlock;
    end;
  finally
    Bmp.Free;
  end;
end;

/// Audit 8A: Timer-Wakeups je Sekunde im Leerlauf (WM_TIMER aus einer eigenen
/// Nachrichtenschleife gezaehlt, nicht ueber die Zeit).
function Bench8AWakeups(Ms: Cardinal): Integer;
var
  Msg: TMsg;
  T0: Cardinal;
  Dummy: THandle;
  N: Integer;
begin
  N := 0;
  Dummy := 0;
  T0 := GetTickCount;
  while GetTickCount - T0 < Ms do
  begin
    MsgWaitForMultipleObjects(0, Dummy, False, 20, QS_ALLINPUT);
    while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
    begin
      if Msg.message = WM_TIMER then
        Inc(N);
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end;
  end;
  Result := N * 1000 div Integer(Ms);
end;

/// Audit 8A: Zaehlwert mit Vorgabe ausgeben (wie Measure, Einheit /s).
procedure Bench8ACount(const Name: string; Value, Budget: Integer);
var
  Verdict: string;
begin
  if Value > Budget then
  begin
    Inc(Exceeded);
    Verdict := 'ZU VIELE';
  end
  else
    Verdict := 'ok';
  Writeln(Format('%-52s %6d /s  (Vorgabe %5d /s)  %s', [Name, Value, Budget, Verdict]));
end;

/// Audit-Paket 8A (DocsAudit-Paket8-Plan.md): eigene Messungen dieses Teils.
procedure Bench8A;
var
  Planner: TPPGPlanner;
  Scroller: TBenchScroller;
begin
  Measure('8A ListBox 10 000: 300 Mausbewegungen + Neuzeichnen', 1300,
    procedure
    var
      L: TPPGListBox;
      D: TBenchData;
      I: Integer;
    begin
      D := TBenchData.Create;
      L := TPPGListBox.Create(Form);
      try
        L.Parent := Form;
        L.SetBounds(0, 0, 400, 600);
        L.Style := lbVirtual;
        L.OnData := D.ListData;
        L.Count := 10000;
        L.Update;
        for I := 0 to 299 do
        begin
          L.Perform(WM_MOUSEMOVE, 0, MakeLParam(100, 5 + (I * 37) mod 590));
          L.Update;
        end;
      finally
        L.Free;
        D.Free;
      end;
    end);

  Measure('8A ListBox 1 000 000: 300 x eine Zeile neu zeichnen', 800,
    procedure
    var
      L: TPPGListBox;
      D: TBenchData;
      I: Integer;
      R: TRect;
    begin
      D := TBenchData.Create;
      L := TPPGListBox.Create(Form);
      try
        L.Parent := Form;
        L.SetBounds(0, 0, 400, 600);
        L.Style := lbVirtual;
        L.OnData := D.ListData;
        L.Count := 1000000;
        L.Update;
        for I := 0 to 299 do
        begin
          R := Rect(0, (I mod 29) * 20, 400, (I mod 29) * 20 + 20);
          InvalidateRect(L.Handle, @R, False);
          L.Update;
        end;
      finally
        L.Free;
        D.Free;
      end;
    end);

  Measure('8A NavigationView 1000: 300 Mausbewegungen + Neuzeichnen', 1100,
    procedure
    var
      N: TPPGNavigationView;
      I: Integer;
    begin
      N := TPPGNavigationView.Create(Form);
      try
        N.Parent := Form;
        N.Animation.Enabled := False;
        N.Height := 800;
        N.BeginItemsUpdate;
        try
          for I := 0 to 999 do
            N.Items.AddItem('Eintrag ' + IntToStr(I), PPGNavIconDocument, I);
        finally
          N.EndItemsUpdate;
        end;
        N.Update;
        for I := 0 to 299 do
        begin
          N.Perform(WM_MOUSEMOVE, 0, MakeLParam(40, 60 + (I * 37) mod 700));
          N.Update;
        end;
      finally
        N.Free;
      end;
    end);

  Measure('8A ToolBar 40 Buttons: 300 Mausbewegungen + Neuzeichnen', 900,
    procedure
    var
      T: TPPGToolBar;
      I: Integer;
    begin
      T := TPPGToolBar.Create(Form);
      try
        T.Parent := Form;
        T.Width := 1150;
        for I := 0 to 39 do
          T.Items.AddButton('B' + IntToStr(I));
        T.Update;
        for I := 0 to 299 do
        begin
          T.Perform(WM_MOUSEMOVE, 0, MakeLParam(5 + (I * 37) mod 1100, T.Height div 2));
          T.Update;
        end;
      finally
        T.Free;
      end;
    end);

  Measure('8A PPGMeasureTextNoCanvas 100 000 x', 200,
    procedure
    var
      I: Integer;
    begin
      for I := 0 to 99999 do
        PPGMeasureTextNoCanvas('Eintrag ' + IntToStr(I mod 100), Form.Font, 0, False);
    end);

  // Leerlauf: Wakeups/s (gezaehlt) ohne Animation, mit Jetzt-Linie, mit Maus
  // ueber einem Scroll-Control (Leisten sichtbar halten)
  Bench8ACount('8A Leerlauf ohne Animation: Wakeups', Bench8AWakeups(2000), 5);
  Planner := TPPGPlanner.Create(Form);
  try
    Planner.Parent := Form;
    Planner.SetBounds(0, 0, 800, 600);
    Planner.View := pvWeek;
    Planner.Date := Date;
    Planner.ShowNowLine := True;
    Planner.Update;
    Bench8AWakeups(1800); // Aufbau und Ausblenden der Leisten abwarten
    Bench8ACount('8A Leerlauf Planer mit Jetzt-Linie: Wakeups', Bench8AWakeups(2000), 5);
  finally
    Planner.Free;
  end;
  Scroller := TBenchScroller.Create(Form);
  try
    Scroller.Parent := Form;
    Scroller.SetBounds(0, 0, 400, 600);
    Scroller.SetContentSize(400, 100000 * 20);
    Scroller.Update;
    Scroller.Perform(CM_MOUSEENTER, 0, 0);
    Scroller.Perform(WM_MOUSEMOVE, 0, MakeLParam(100, 100));
    Bench8AWakeups(200); // Leisten einblenden
    // Die echte Maus steht nicht ueber dem Control: nach 1,2 s blendet es aus,
    // gemessen wird die Sekunde davor
    Bench8ACount('8A Leerlauf Maus ueber Scroll-Control: Wakeups', Bench8AWakeups(1000), 15);
  finally
    Scroller.Free;
  end;
end;

/// Audit-Paket 8B (DocsAudit-Paket8-Plan.md): eigene Messungen dieses Teils.
procedure Bench8B;
var
  G: TPPGGrid;
  Rule: TPPGGridConditionalFormat;
begin
  // Ein Grid mit 1 000 000 Zeilen x 5 Spalten aus Cells[] fuer alle Messungen
  G := TPPGGrid.Create(Form);
  try
    G.Parent := Form;
    G.SetBounds(0, 0, 800, 600);
    G.SmoothScrolling := False;
    G.Columns.Add.Title := '#';
    G.Columns.Add.Title := 'Zahl';
    G.Columns.Add.Title := 'Text';
    G.Columns.Add.Title := 'Menge';
    G.Columns.Add.Title := 'Klasse';
    Measure('8B Grid: 1 000 000 x 5 per Cells[] fuellen', 27000,
      procedure
      var
        R: Integer;
      begin
        G.RowCount := 1000001;
        for R := 1 to 1000000 do
        begin
          G.Cells[0, R] := IntToStr(R);
          G.Cells[1, R] := IntToStr((Int64(R) * 7919) mod 1000003);
          G.Cells[2, R] := 'Text ' + IntToStr((Int64(R) * 104729) mod 999983);
          G.Cells[3, R] := IntToStr(R mod 100);
          G.Cells[4, R] := IntToStr(R mod 7);
        end;
      end);
    Measure('8B Grid 1 Mio.: sortieren Zahl auf + ab, Text auf', 3500,
      procedure
      begin
        G.SortBy(1, True);
        G.SortBy(1, False);
        G.SortBy(2, True);
        if G.Cells[1, G.DataRow(1)] = '' then
          raise Exception.Create('Sortieren falsch');
      end);
    Measure('8B Grid 1 Mio.: filtern + 3 x umsortieren mit Filter', 700,
      procedure
      begin
        G.SortBy(-1);
        G.Filters[3] := '5';
        G.SortBy(1, True);
        G.SortBy(1, False);
        G.SortBy(2, True);
        if G.DataRow(1) < 1 then
          raise Exception.Create('Filtern falsch');
      end);
    G.ClearFilters;
    G.SortBy(-1);
    Measure('8B Grid 1 Mio.: bedingte Formate (Oben-10 %, Farbskala)', 600,
      procedure
      begin
        Rule := G.ConditionalFormats.Add;
        Rule.Column := 1;
        Rule.Rule := crTop;
        Rule.Value1 := '10%';
        Rule := G.ConditionalFormats.Add;
        Rule.Column := 4;
        Rule.Rule := crColorScale;
        G.RecalcAggregates;
      end);
    G.Columns[3].Aggregate := agSum;
    G.ShowFooter := True;
    G.RowHeights[0] := 30;
    G.RecalcAggregates;
    Measure('8B Grid 1 Mio.: Spaltenbreite 100 x (Summe, Farbskala, RowHeights)', 1500,
      procedure
      var
        I: Integer;
      begin
        for I := 0 to 99 do
        begin
          G.ColWidths[2] := 60 + I;
          Application.ProcessMessages;
        end;
      end);
    Measure('8B Grid 1 Mio.: 100 Einzelaenderungen mit Summe', 1400,
      procedure
      var
        I: Integer;
      begin
        for I := 1 to 100 do
        begin
          G.Cells[3, I * 9973] := IntToStr(I);
          Application.ProcessMessages;
        end;
        if G.FooterText(3) = '' then
          raise Exception.Create('Summe fehlt');
      end);
    Measure('8B Grid 1 Mio.: Hover 300 x mit HotRow-Stil + zeichnen', 3000,
      procedure
      var
        I: Integer;
      begin
        G.Styles.HotRow.Color := $00C0FFFF;
        for I := 0 to 299 do
        begin
          G.Perform(WM_MOUSEMOVE, 0, MakeLParam(200, 40 + (I mod 20) * 24));
          PaintToBitmap(G);
        end;
      end);
    // Audit 8E: im Fenster zeichnet der Hover nur die alte und neue Zeile
    Measure('8E Grid 1 Mio.: Hover 300 x im Fenster (Teil-Neuzeichnen)', 800,
      procedure
      var
        I: Integer;
      begin
        G.Invalidate;
        UpdateWindow(G.Handle);
        for I := 0 to 299 do
        begin
          G.Perform(WM_MOUSEMOVE, 0, MakeLParam(200, 40 + (I mod 20) * 24));
          UpdateWindow(G.Handle);
        end;
      end);
    Measure('8B Grid 1 Mio.: 100 x zeichnen mit Zellarten (Fortschritt, Link)', 1200,
      procedure
      var
        I: Integer;
      begin
        G.Columns[3].CellKind := ckProgress;
        G.Columns[2].CellKind := ckLink;
        for I := 0 to 99 do
        begin
          G.ScrollTo(0, I * 5000);
          PaintToBitmap(G);
        end;
      end);
  finally
    G.Free;
  end;
end;

/// Audit-Paket 8C (DocsAudit-Paket8-Plan.md): eigene Messungen dieses Teils.
procedure Bench8C;
var
  TV: TPPGTreeView;
  CLB: TPPGCheckListBox;
  LB: TPPGListBox;
  CB: TPPGComboBox;
  I: Integer;
begin
  // Baum mit 10 000 Wurzeln (Markup in jedem dritten Text)
  TV := TPPGTreeView.Create(Form);
  try
    TV.Parent := Form;
    TV.SetBounds(0, 0, 300, 600);
    TV.Items.BeginUpdate;
    try
      for I := 0 to 9999 do
        if I mod 3 = 0 then
          TV.Items.Add(nil, '<b>Knoten ' + IntToStr((I * 7919) mod 10000) + '</b>')
        else
          TV.Items.Add(nil, 'Knoten ' + IntToStr((I * 7919) mod 10000));
    finally
      TV.Items.EndUpdate;
    end;
    Measure('TreeView 10 000 Wurzeln: Items[]-Schleife', 100,
      procedure
      var
        J, N: Integer;
      begin
        N := 0;
        for J := 0 to TV.Items.Count - 1 do
          if TV.Items[J] <> nil then
            Inc(N);
        if N <> 10000 then
          Writeln('  Fehler: Anzahl ', N);
      end);
    Measure('TreeView 10 000 Wurzeln: AlphaSort', 100,
      procedure
      begin
        TV.AlphaSort(True);
      end);
  finally
    TV.Free;
  end;

  TV := TPPGTreeView.Create(Form);
  try
    TV.Parent := Form;
    TV.SetBounds(0, 0, 300, 600);
    Measure('TreeView 10 000 Wurzeln ohne BeginUpdate', 100,
      procedure
      var
        J: Integer;
      begin
        for J := 0 to 9999 do
          TV.Items.Add(nil, 'Knoten ' + IntToStr(J));
        if TV.RowCount <> 10000 then
          Writeln('  Fehler: Zeilen ', TV.RowCount);
        PaintToBitmap(TV);
      end);
  finally
    TV.Free;
  end;

  TV := TPPGTreeView.Create(Form);
  try
    TV.Parent := Form;
    TV.SetBounds(0, 0, 300, 600);
    TV.CheckBoxes := True;
    Measure('TreeView AutoCheck: 10 000 Kinder in BeginUpdate', 100,
      procedure
      var
        J: Integer;
        P: TPPGTreeNode;
      begin
        TV.Items.BeginUpdate;
        try
          P := TV.Items.Add(nil, 'Eltern');
          for J := 0 to 9999 do
            TV.Items.AddChild(P, 'Kind ' + IntToStr(J));
          P.Item[0].Checked := True;
        finally
          TV.Items.EndUpdate;
        end;
        if P.CheckState <> cbGrayed then
          Writeln('  Fehler: Elternzustand');
      end);
  finally
    TV.Free;
  end;

  CLB := TPPGCheckListBox.Create(Form);
  try
    CLB.Parent := Form;
    CLB.SetBounds(0, 0, 300, 600);
    CLB.ItemsEx.BeginUpdate;
    try
      for I := 0 to 9999 do
        CLB.ItemsEx.Add('Eintrag ' + IntToStr(I));
    finally
      CLB.ItemsEx.EndUpdate;
    end;
    Measure('CheckListBox 10 000 (ItemsEx): CheckAll an + aus', 100,
      procedure
      begin
        CLB.CheckAll(cbChecked);
        CLB.CheckAll(cbUnchecked);
      end);
  finally
    CLB.Free;
  end;

  LB := TPPGListBox.Create(Form);
  try
    LB.Parent := Form;
    LB.SetBounds(0, 0, 300, 600);
    LB.ItemsEx.BeginUpdate;
    try
      for I := 0 to 99999 do
        LB.ItemsEx.Add('Eintrag ' + IntToStr(I)).Group := 'Gruppe ' + IntToStr(I div 1000);
    finally
      LB.ItemsEx.EndUpdate;
    end;
    Measure('ListBox 100 000 mit Gruppen: 5 x Layout + zeichnen', 100,
      procedure
      var
        J: Integer;
      begin
        for J := 1 to 5 do
        begin
          // Neue Schrift erzwingt ein neues Layout
          LB.Font.Height := -12 - (J mod 2);
          LB.ItemRect(0);
          PaintToBitmap(LB);
        end;
      end);
  finally
    LB.Free;
  end;

  Measure('Markup-Layout 20 000 x (gleiche Grundschrift)', 1300,
    procedure
    var
      J: Integer;
      ML: TPPGMarkupLayout;
    begin
      ML := TPPGMarkupLayout.Create;
      try
        for J := 0 to 19999 do
          ML.Layout('Text <b>fett</b> und <i>kursiv</i> ' + IntToStr(J mod 50), Form.Font,
            nil, 0, False);
      finally
        ML.Free;
      end;
    end);

  CB := TPPGComboBox.Create(Form);
  try
    CB.Parent := Form;
    Measure('ComboBox 10 000 x ItemsEx.Add (unsortiert)', 100,
      procedure
      var
        J: Integer;
      begin
        for J := 0 to 9999 do
          CB.ItemsEx.Add('Eintrag ' + IntToStr(J));
      end);
  finally
    CB.Free;
  end;

  CB := TPPGComboBox.Create(Form);
  try
    CB.Parent := Form;
    CB.Sorted := True;
    Measure('ComboBox 2 000 x ItemsEx.Add (sortiert)', 100,
      procedure
      var
        J: Integer;
      begin
        for J := 0 to 1999 do
          CB.ItemsEx.Add('Eintrag ' + IntToStr((J * 7919) mod 2000));
      end);
  finally
    CB.Free;
  end;

  Measure('Auswahl 100 000: 10 000 x ItemIndex (Single)', 100,
    procedure
    var
      J, N: Integer;
      S: TPPGSelection;
    begin
      S := TPPGSelection.Create;
      try
        S.Count := 100000;
        S.Selected[99999] := True;
        N := 0;
        for J := 1 to 10000 do
          Inc(N, S.ItemIndex);
        if N <> 999990000 then
          Writeln('  Fehler: ItemIndex');
      finally
        S.Free;
      end;
    end);

  Measure('Auswahl 100 000: 10 000 x vorne einfuegen + loeschen', 100,
    procedure
    var
      J: Integer;
      S: TPPGSelection;
    begin
      S := TPPGSelection.Create;
      try
        S.Count := 100000;
        for J := 1 to 5000 do
          S.ItemsInserted(0, 1);
        for J := 1 to 5000 do
          S.ItemsDeleted(0, 1);
        S.Selected[50000] := True;
        for J := 1 to 5000 do
          S.ItemsInserted(0, 1);
        if S.ItemIndex <> 55000 then
          Writeln('  Fehler: ItemIndex nach Einfuegen');
      finally
        S.Free;
      end;
    end);
end;

/// Audit-Paket 8D (DocsAudit-Paket8-Plan.md): eigene Messungen dieses Teils.
/// Audit 8E: Hover im Fenster (nur die betroffenen Karten bzw. Termine neu
/// zeichnen), ohne den Aufbau der Daten.
procedure Bench8EHover;
var
  K: TPPGKanban;
  C: array[0..3] of TPPGKanbanColumn;
  P: TPPGPlanner;
  A: TPPGAppointment;
  I: Integer;
begin
  K := TPPGKanban.Create(Form);
  try
    K.Parent := Form;
    K.SetBounds(0, 0, 1000, 700);
    for I := 0 to 3 do
      C[I] := K.Columns.AddColumn('Spalte ' + IntToStr(I));
    K.Cards.BeginUpdate;
    try
      for I := 0 to 9999 do
        with K.Cards.AddCard(C[I mod 4].Id, 'Aufgabe ' + IntToStr(I), 'Text <b>' + IntToStr(I mod 97) + '</b>') do
        begin
          Labels := 'L' + IntToStr(I mod 7);
          if I mod 3 = 0 then
            Assignee := 'Anna Berg';
        end;
    finally
      K.Cards.EndUpdate;
    end;
    K.Update;
    Measure('8E Kanban 10 000 Karten: 300 Mausbewegungen im Fenster (ohne Aufbau)', 450,
      procedure
      var
        J: Integer;
      begin
        for J := 0 to 299 do
        begin
          K.Perform(WM_MOUSEMOVE, 0, MakeLParam(Word(30 + (J * 17) mod 900), Word(80 + (J * 29) mod 560)));
          UpdateWindow(K.Handle);
        end;
      end);
  finally
    K.Free;
  end;
  P := TPPGPlanner.Create(Form);
  try
    P.Parent := Form;
    P.SetBounds(0, 0, 1000, 700);
    P.ShowNowLine := False;
    P.View := pvWeek;
    P.GroupByResource := False;
    P.Appointments.BeginUpdate;
    try
      for I := 0 to 1999 do
      begin
        A := P.Appointments.AddAppointment(EncodeDate(2026, 3, 2) + (I mod 7) + (8 + I mod 9) / 24,
          EncodeDate(2026, 3, 2) + (I mod 7) + (9 + I mod 9) / 24, 'Termin ' + IntToStr(I));
        if I mod 5 = 0 then
          A.Location := 'Raum ' + IntToStr(I mod 13);
      end;
    finally
      P.Appointments.EndUpdate;
    end;
    P.Date := EncodeDate(2026, 3, 4);
    P.ScrollTo(0, 8 * 40);
    P.Update;
    Measure('8E Planer Woche 2000 Termine: 300 Mausbewegungen im Fenster', 300,
      procedure
      var
        J: Integer;
      begin
        for J := 0 to 299 do
        begin
          P.Perform(WM_MOUSEMOVE, 0, MakeLParam(Word(80 + (J * 37) mod 900), Word(60 + (J * 23) mod 600)));
          UpdateWindow(P.Handle);
        end;
      end);
  finally
    P.Free;
  end;
end;

procedure Bench8D;
begin
  Measure('MenuBar 10 Menues: 300 Mausbewegungen + zeichnen', 400,
    procedure
    var
      M: TMainMenu;
      Bar: TPPGMenuBar;
      It: TMenuItem;
      I: Integer;
    begin
      M := TMainMenu.Create(Form);
      Bar := TPPGMenuBar.Create(Form);
      try
        for I := 0 to 9 do
        begin
          It := TMenuItem.Create(M);
          It.Caption := '&Menue ' + IntToStr(I);
          It.Add(TMenuItem.Create(M));
          It.Items[0].Caption := 'Eintrag';
          M.Items.Add(It);
        end;
        Bar.Parent := Form;
        Bar.Menu := M;
        Bar.HandleNeeded;
        for I := 0 to 299 do
        begin
          Bar.Perform(WM_MOUSEMOVE, 0, MakeLParam(Word((I * 7) mod 900), Word(Bar.Height div 2)));
          PaintToBitmap(Bar);
        end;
      finally
        Bar.Free;
        M.Free;
      end;
    end);

  Measure('Chart 100 000 Punkte: 300 Mausbewegungen (Hover)', 100,
    procedure
    var
      C: TPPGChart;
      V: TArray<Double>;
      I: Integer;
    begin
      C := TPPGChart.Create(Form);
      try
        C.Parent := Form;
        C.Animation.Enabled := False;
        C.SetBounds(0, 0, 800, 400);
        SetLength(V, 100000);
        for I := 0 to High(V) do
          V[I] := Sin(I / 700) * 100 + (I mod 17);
        C.Series.Add.SetValues(V);
        PaintToBitmap(C);
        for I := 0 to 299 do
          C.Perform(WM_MOUSEMOVE, 0, MakeLParam(Word(60 + (I * 13) mod 700), Word(100 + I mod 150)));
        PaintToBitmap(C);
      finally
        C.Free;
      end;
    end);

  Measure('Chart: 10 000 x AddXY (sichtbar)', 100,
    procedure
    var
      C: TPPGChart;
      S: TPPGChartSeries;
      I: Integer;
    begin
      C := TPPGChart.Create(Form);
      try
        C.Parent := Form;
        C.SetBounds(0, 0, 800, 400);
        C.HandleNeeded;
        S := C.Series.Add;
        S.AddXY(0, 0);
        PaintToBitmap(C);
        for I := 1 to 10000 do
          S.AddXY(I, Sin(I / 50) * 20);
        PaintToBitmap(C);
      finally
        C.Free;
      end;
    end);

  Measure('Planer Zeitleiste 366 Tage, 60 Ressourcen: 300 x scrollen', 2500,
    procedure
    var
      P: TPPGPlanner;
      A: TPPGAppointment;
      I: Integer;
    begin
      P := TPPGPlanner.Create(Form);
      try
        P.Parent := Form;
        P.SetBounds(0, 0, 1000, 700);
        P.ShowNowLine := False;
        P.View := pvTimeline;
        P.TimelineDays := 366;
        for I := 1 to 60 do
          P.Resources.AddResource(I, 'Raum ' + IntToStr(I));
        P.Appointments.BeginUpdate;
        try
          for I := 0 to 2999 do
          begin
            A := P.Appointments.AddAppointment(EncodeDate(2026, 1, 1) + (I mod 366) + (8 + I mod 9) / 24,
              EncodeDate(2026, 1, 1) + (I mod 366) + (10 + I mod 9) / 24, 'Termin ' + IntToStr(I));
            A.ResourceId := 1 + I mod 60;
          end;
        finally
          P.Appointments.EndUpdate;
        end;
        P.Date := EncodeDate(2026, 1, 1);
        PaintToBitmap(P);
        for I := 0 to 299 do
        begin
          P.ScrollTo((I * 997) mod 300000, (I * 37) mod 1500);
          PaintToBitmap(P);
        end;
      finally
        P.Free;
      end;
    end);

  Measure('Planer Woche, 40 Ressourcen gruppiert: 50 x anordnen', 3000,
    procedure
    var
      P: TPPGPlanner;
      A: TPPGAppointment;
      I: Integer;
    begin
      P := TPPGPlanner.Create(Form);
      try
        P.Parent := Form;
        P.SetBounds(0, 0, 1000, 700);
        P.ShowNowLine := False;
        P.View := pvWeek;
        for I := 1 to 40 do
          P.Resources.AddResource(I, 'Raum ' + IntToStr(I));
        P.Appointments.BeginUpdate;
        try
          for I := 0 to 3999 do
          begin
            A := P.Appointments.AddAppointment(EncodeDate(2026, 3, 2) + (I mod 7) + (8 + I mod 9) / 24,
              EncodeDate(2026, 3, 2) + (I mod 7) + (9 + I mod 9) / 24, 'Termin ' + IntToStr(I));
            A.ResourceId := 1 + I mod 40;
          end;
        finally
          P.Appointments.EndUpdate;
        end;
        P.Date := EncodeDate(2026, 3, 4);
        for I := 0 to 49 do
        begin
          P.InvalidateLayout;
          P.EnsureLayout;
        end;
      finally
        P.Free;
      end;
    end);

  Measure('Kanban 10 000 Karten: 300 Mausbewegungen (Hover)', 3500,
    procedure
    var
      K: TPPGKanban;
      C: array[0..3] of TPPGKanbanColumn;
      I: Integer;
    begin
      K := TPPGKanban.Create(Form);
      try
        K.Parent := Form;
        K.SetBounds(0, 0, 1000, 700);
        for I := 0 to 3 do
          C[I] := K.Columns.AddColumn('Spalte ' + IntToStr(I));
        K.Cards.BeginUpdate;
        try
          for I := 0 to 9999 do
            K.Cards.AddCard(C[I mod 4].Id, 'Aufgabe ' + IntToStr(I), 'Text ' + IntToStr(I mod 97));
        finally
          K.Cards.EndUpdate;
        end;
        PaintToBitmap(K);
        for I := 0 to 299 do
        begin
          K.Perform(WM_MOUSEMOVE, 0, MakeLParam(Word(30 + (I * 17) mod 900), Word(80 + (I * 29) mod 560)));
          UpdateWindow(K.Handle);
        end;
      finally
        K.Free;
      end;
    end);

  // Audit 8E: Hover ohne Aufbau gemessen (Board und Planer vorher angelegt)
  Bench8EHover;

  Measure('Kanban 10 000 Karten: 100 x eine Karte aendern + zeichnen', 4500,
    procedure
    var
      K: TPPGKanban;
      C: array[0..3] of TPPGKanbanColumn;
      I: Integer;
    begin
      K := TPPGKanban.Create(Form);
      try
        K.Parent := Form;
        K.SetBounds(0, 0, 1000, 700);
        for I := 0 to 3 do
          C[I] := K.Columns.AddColumn('Spalte ' + IntToStr(I));
        K.Cards.BeginUpdate;
        try
          for I := 0 to 9999 do
            with K.Cards.AddCard(C[I mod 4].Id, 'Aufgabe ' + IntToStr(I), 'Text ' + IntToStr(I mod 97)) do
              Labels := 'L' + IntToStr(I mod 7);
        finally
          K.Cards.EndUpdate;
        end;
        PaintToBitmap(K);
        for I := 0 to 99 do
        begin
          K.Cards[(I * 101) mod 10000].Title := 'Geaendert ' + IntToStr(I);
          PaintToBitmap(K);
        end;
      finally
        K.Free;
      end;
    end);

  Measure('Ribbon: 1000 x Enabled umschalten (100 x zeichnen)', 250,
    procedure
    var
      R: TPPGRibbon;
      G: TPPGRibbonGroup;
      Items: array[0..9] of TPPGRibbonItem;
      I, J: Integer;
    begin
      R := TPPGRibbon.Create(Form);
      try
        R.Parent := Form;
        R.Width := 1100;
        for I := 0 to 2 do
        begin
          G := R.Tabs.AddTab('Register ' + IntToStr(I)).Groups.AddGroup('Gruppe');
          for J := 0 to 9 do
            if I = 0 then
              Items[J] := G.Items.AddButton('Befehl ' + IntToStr(J), $E77F, rsMedium)
            else
              G.Items.AddButton('Befehl ' + IntToStr(J), $E77F, rsMedium);
        end;
        PaintToBitmap(R);
        for I := 0 to 99 do
        begin
          for J := 0 to 9 do
            Items[J].Enabled := Odd(I + J);
          PaintToBitmap(R);
        end;
      finally
        R.Free;
      end;
    end);

  Measure('PageControl: 200 Seiten einfuegen (BeginUpdate)', 100,
    procedure
    var
      PC: TPPGPageControl;
      S: TPPGTabSheet;
      I: Integer;
    begin
      PC := TPPGPageControl.Create(Form);
      try
        PC.Parent := Form;
        PC.SetBounds(0, 0, 800, 500);
        PC.BeginUpdate;
        try
          for I := 0 to 199 do
          begin
            S := TPPGTabSheet.Create(PC);
            S.Caption := 'Seite ' + IntToStr(I);
            S.PageControl := PC;
          end;
        finally
          PC.EndUpdate;
        end;
        PC.ActivePageIndex := 199;
        PaintToBitmap(PC);
      finally
        PC.Free;
      end;
    end);

  Measure('InfoBar: 1000 x Hoehe (Oeffnen-Animation)', 50,
    procedure
    var
      B: TPPGInfoBar;
      I: Integer;
    begin
      B := TPPGInfoBar.Create(Form);
      try
        B.Parent := Form;
        B.Width := 600;
        B.Title := 'Hinweis';
        B.Message := 'Die Datei wurde <b>gespeichert</b>. Eine Sicherung liegt im Ordner ' +
          '<a href="x">Sicherungen</a>; sie wird nach <i>30 Tagen</i> geloescht. ' +
          'Weitere Informationen finden Sie in der Hilfe.';
        for I := 0 to 999 do
          TInfoBarAccessB(B).RequestAutoSize;
      finally
        B.Free;
      end;
    end);
end;

/// Audit 11a #7: Nachrichten verarbeiten, bis Done True liefert oder TimeoutMs
/// vergangen sind (Animator-Timer und gepostete Nachrichten).
procedure Pump11(TimeoutMs: Cardinal; const Done: TFunc<Boolean>);
var
  T0: Cardinal;
  Dummy: THandle;
begin
  Dummy := 0;
  T0 := GetTickCount;
  while not Done() and (GetTickCount - T0 < TimeoutMs) do
  begin
    MsgWaitForMultipleObjects(0, Dummy, False, 10, QS_ALLINPUT);
    Application.ProcessMessages;
  end;
end;

procedure TBenchData.KanbanCard(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer;
  var Data: TPPGKanbanCardData);
begin
  Data.Title := 'V' + IntToStr(Index);
end;

procedure TBenchData.ComboCell(Sender: TObject; Row, Column: Integer; var Text: string);
begin
  if Column = 0 then
    Text := IntToStr(100000 + Row)
  else
    Text := 'Kunde ' + IntToStr(Row);
end;

/// Audit-Paket 11a #7 (Docs\Audit-Paket11-Plan.md): die Zeitgrenzen, die bis
/// dahin in Unit-Tests standen (GetTickCount gegen eine Grenze, unter Last
/// unzuverlaessig). Gleiches Szenario wie im Test, Vorgabe = alte Grenze; der
/// Unit-Test prueft nur noch das Ergebnis.
procedure Bench11;
var
  D: TBenchData;
  Tiles: TPPGTileView;
  XlsxSrc: TPPGStringTableSource;
  XlsxTable: IPPGTableSource;
  Appts: TPPGAppointments;
  A: TPPGAppointment;
  Planner: TPPGPlanner;
  Kanban: TPPGKanban;
  Ribbon: TPPGRibbon;
  Tab: TPPGRibbonTab;
  Grp: TPPGRibbonGroup;
  I, T, G: Integer;
begin
  D := TBenchData.Create;
  try
    // Phase5 TRowLayoutTests.MillionRowsAreFast
    Measure('11a Zeilen-Layout 1 Mio. fest: 100 000 x RowAt', 100,
      procedure
      var
        L: TPPGRowLayout;
        I: Integer;
      begin
        L := TPPGRowLayout.Create;
        try
          L.DefaultHeight := 20;
          L.Count := 1000000;
          for I := 0 to 99999 do
            L.RowAt(Int64(I) * 197);
        finally
          L.Free;
        end;
      end);
    Measure('11a Zeilen-Layout 1 Mio. variabel: 100 000 x RowAt', 300,
      procedure
      var
        L: TPPGRowLayout;
        I: Integer;
        H: Int64;
      begin
        L := TPPGRowLayout.Create;
        try
          L.DefaultHeight := 20;
          L.Count := 1000000;
          for I := 0 to 999 do
            L.SetRowHeight(I * 1000, 40);
          H := L.TotalHeight64;
          if H = 0 then
            Exit;
          for I := 0 to 99999 do
            L.RowAt(Int64(I) * 197);
        finally
          L.Free;
        end;
      end);

    // Phase5 TSelectionTests.MillionItemsAreFast
    Measure('11a Auswahl 1 Mio.: SelectAll, Strg+Klick, Bereich, Loeschen', 500,
      procedure
      var
        S: TPPGSelection;
      begin
        S := TPPGSelection.Create;
        try
          S.Mode := smExtended;
          S.Count := 1000000;
          S.SelectAll;
          S.Click(500000, [ssCtrl]);
          S.Clear;
          S.SelectRange(10, 900000, False);
          S.ItemsDeleted(0, 5);
        finally
          S.Free;
        end;
      end);

    // Phase6a TListBoxTests.VirtualMillionItems
    Measure('11a ListBox virtuell 1 Mio.: Count, letzter Eintrag, zeichnen', 1000,
      procedure
      var
        L: TPPGListBox;
      begin
        L := TPPGListBox.Create(Form);
        try
          L.Parent := Form;
          L.SetBounds(0, 0, 300, 400);
          L.Style := lbVirtual;
          L.OnData := D.ListData;
          L.Count := 1000000;
          L.ItemIndex := 999999;
          PaintToBitmap(L);
        finally
          L.Free;
        end;
      end);

    // Phase6b TTreeTests.HundredThousandNodes
    Measure('11a TreeView 100 000 Knoten: aufbauen, aufklappen, Auswahl, zeichnen', 2000,
      procedure
      var
        T: TPPGTreeView;
        R: TPPGTreeNode;
        I, J: Integer;
      begin
        T := TPPGTreeView.Create(Form);
        try
          T.Parent := Form;
          T.SetBounds(0, 0, 300, 400);
          T.Items.BeginUpdate;
          try
            for I := 0 to 99 do
            begin
              R := T.Items.Add(nil, 'Gruppe ' + IntToStr(I));
              for J := 0 to 999 do
                T.Items.AddChild(R, 'Knoten ' + IntToStr(J));
            end;
          finally
            T.Items.EndUpdate;
          end;
          T.FullExpand;
          T.Selected := T.Items[T.Items.Count - 1];
          PaintToBitmap(T);
        finally
          T.Free;
        end;
      end);

    // Phase6c TGridTests.VirtualMillionRows
    Measure('11a Grid virtuell 1 Mio. x 20: Fokus ans Ende + zeichnen', 1000,
      procedure
      var
        G: TPPGGrid;
      begin
        G := TPPGGrid.Create(Form);
        try
          G.Parent := Form;
          G.SetBounds(0, 0, 600, 400);
          G.OnGetCellText := D.GridText;
          G.ColCount := 20;
          G.RowCount := 1000001;
          G.Row := 1000000;
          G.Col := 19;
          PaintToBitmap(G);
        finally
          G.Free;
        end;
      end);

    // Phase10b TSparklineTests.ManyValuesAreCondensed
    Measure('11a Sparkline 100 000 Werte zeichnen', 1000,
      procedure
      var
        S: TPPGSparkline;
        V: TArray<Double>;
        I: Integer;
      begin
        S := TPPGSparkline.Create(Form);
        try
          S.Parent := Form;
          S.SetBounds(10, 10, 120, 40);
          SetLength(V, 100000);
          for I := 0 to High(V) do
            V[I] := Sin(I / 500) * 10 + Random(3);
          S.SetValues(V);
          PaintToBitmap(S);
        finally
          S.Free;
        end;
      end);

    // Phase10d TChartBehaviourTests.ManyPointsAreFast
    Measure('11a Chart 100 000 Punkte: einmal zeichnen', 500,
      procedure
      var
        C: TPPGChart;
        V: TArray<Double>;
        I: Integer;
      begin
        C := TPPGChart.Create(Form);
        try
          C.Parent := Form;
          C.SetBounds(0, 0, 600, 320);
          C.Animation.Enabled := False;
          SetLength(V, 100000);
          for I := 0 to High(V) do
            V[I] := Sin(I / 1000) * 100 + Random(10);
          C.Series.Add.SetValues(V);
          PaintToBitmap(C);
        finally
          C.Free;
        end;
      end);
    Measure('11a Chart 100 000 Punkte: 200 x Append im Lauffenster', 2000,
      procedure
      var
        C: TPPGChart;
        S: TPPGChartSeries;
        V: TArray<Double>;
        I: Integer;
      begin
        C := TPPGChart.Create(Form);
        try
          C.Parent := Form;
          C.SetBounds(0, 0, 600, 320);
          C.Animation.Enabled := False;
          SetLength(V, 100000);
          for I := 0 to High(V) do
            V[I] := Sin(I / 1000) * 100 + Random(10);
          S := C.Series.Add;
          S.SetValues(V);
          for I := 1 to 200 do
            S.Append(I, 100000);
        finally
          C.Free;
        end;
      end);

    // Phase12c TColumnComboTests.VirtualRowsAreFast
    Measure('11a ColumnComboBox 100 000 virtuell: aufklappen + Ende', 1000,
      procedure
      var
        C: TPPGColumnComboBox;
        K: Word;
      begin
        C := TPPGColumnComboBox.Create(Form);
        try
          C.Parent := Form;
          C.SetBounds(10, 10, 260, 32);
          C.Animation.Enabled := False;
          C.Columns.Add.Title := 'Nr';
          C.Columns.Add.Title := 'Name';
          C.OnGetCellText := D.ComboCell;
          C.VirtualRowCount := 100000;
          C.SetFocus;
          C.DropDown;
          K := VK_END;
          TWinControlAccessB(C).KeyDown(K, []);
          C.CloseUp(False);
        finally
          C.Free;
        end;
      end);

    // Phase12c TTagEditTests.ManyTagsLayoutFast
    Measure('11a TagEdit 500 Tags: anlegen + zeichnen', 1500,
      procedure
      var
        T: TPPGTagEdit;
        I: Integer;
      begin
        T := TPPGTagEdit.Create(Form);
        try
          T.Parent := Form;
          T.SetBounds(10, 10, 500, 32);
          T.Tags.BeginUpdate;
          try
            for I := 1 to 500 do
              T.Tags.Add('Tag' + IntToStr(I));
          finally
            T.Tags.EndUpdate;
          end;
          PaintToBitmap(T);
        finally
          T.Free;
        end;
      end);

    // Phase13b TGridColumnTests.AutoSizeSamplesManyRows
    Measure('11a Grid 1 Mio. Zeilen: AutoSizeColumn (Stichprobe)', 2000,
      procedure
      var
        G: TPPGGrid;
        R, C: Integer;
      begin
        G := TPPGGrid.Create(Form);
        try
          G.Parent := Form;
          G.SetBounds(0, 0, 600, 400);
          G.ColCount := 4;
          G.RowCount := 6;
          for R := 1 to 5 do
            for C := 0 to 3 do
              G.Cells[C, R] := Chr(Ord('A') + C) + IntToStr(R * 37);
          G.RowCount := 1000001;
          G.AutoSizeColumn(1);
        finally
          G.Free;
        end;
      end);

    // Phase13f TExportTests.ManyRows (gemessen wie im Test: nur der Export)
    XlsxSrc := TPPGStringTableSource.Create(['Nr', 'Text', 'Wert']);
    XlsxTable := XlsxSrc;
    for I := 1 to 20000 do
      XlsxSrc.AddRow([IntToStr(I), 'Text ' + IntToStr(I mod 100), FloatToStr(I / 4)]);
    Measure('11a xlsx: 20 000 Zeilen x 3 exportieren (Datei)', 10000,
      procedure
      var
        F: string;
      begin
        F := TPath.Combine(TPath.GetTempPath, 'ppg_bench11.xlsx');
        try
          PPGExportXlsx(XlsxTable, F);
        finally
          System.SysUtils.DeleteFile(F);
        end;
      end);
    XlsxTable := nil;

    // Phase14a TModelTests.RangeQuery: 50 000 Termine; gemessen: Abfrage einer Woche
    Appts := TPPGAppointments.Create(nil);
    try
      Appts.BeginUpdate;
      try
        for I := 0 to 49999 do
        begin
          A := Appts.Add;
          A.StartTime := EncodeDate(2026, 1, 1) + (I mod 365) + (I mod 9) / 24;
          A.FinishTime := A.StartTime + 1 / 24;
        end;
      finally
        Appts.EndUpdate;
      end;
      Measure('11a Termine 50 000: eine Woche abfragen', 1000,
        procedure
        begin
          Appts.GetOccurrences(EncodeDate(2026, 3, 2), EncodeDate(2026, 3, 9));
        end);
    finally
      Appts.Free;
    end;

    // Phase14aPlanner TPlannerTests.ManyAppointmentsStayFast; gemessen wie im
    // Test erst nach dem Anlegen: anordnen + zeichnen
    Planner := TPPGPlanner.Create(Form);
    try
      Planner.Parent := Form;
      Planner.SetBounds(0, 0, 860, 640);
      Planner.Animation.Enabled := False;
      Planner.SmoothScrolling := False;
      Planner.Date := EncodeDate(2026, 6, 3);
      Planner.Appointments.BeginUpdate;
      try
        for I := 0 to 49999 do
        begin
          A := Planner.Appointments.Add;
          A.StartTime := EncodeDate(2026, 1, 1) + (I mod 365) + (8 + I mod 10) / 24;
          A.FinishTime := A.StartTime + 1 / 24;
          A.Subject := 'T' + IntToStr(I);
        end;
      finally
        Planner.Appointments.EndUpdate;
      end;
      Measure('11a Planer 50 000 Termine: Woche anordnen + zeichnen', 1500,
        procedure
        begin
          Planner.InvalidateLayout;
          Planner.EnsureLayout;
          PaintToBitmap(Planner);
        end);
    finally
      Planner.Free;
    end;

    // Phase14cKanban TKanbanTests.VirtualColumn
    Measure('11a Kanban virtuelle Spalte 100 000: scrollen, zeichnen, HitTest', 1000,
      procedure
      var
        K: TPPGKanban;
        R0, R1: TRect;
      begin
        K := TPPGKanban.Create(Form);
        try
          K.Parent := Form;
          K.SetBounds(0, 0, 1080, 640);
          K.Animation.Enabled := False;
          K.SmoothScrolling := False;
          K.OnGetCard := D.KanbanCard;
          K.Columns.AddColumn('Archiv').VirtualCount := 100000;
          K.HandleNeeded;
          R0 := K.CardRect(0, 0, 0);
          R1 := K.CardRect(0, 0, 1);
          K.ScrollColumn(0, 50000 * (R1.Top - R0.Top));
          K.ScrollBy(10000, 0);
          PaintToBitmap(K);
          K.HitTest(K.ColumnRect(0).Left + 20, K.ColumnRect(0).Top + 200);
        finally
          K.Free;
        end;
      end);

    // Phase14cKanban TKanbanTests.ManyCardsStayFast; gemessen wie im Test:
    // Layout + 100 x scrollen und zeichnen (ohne das Anlegen der Karten)
    Kanban := TPPGKanban.Create(Form);
    try
      Kanban.Parent := Form;
      Kanban.SetBounds(0, 0, 1080, 640);
      Kanban.Animation.Enabled := False;
      Kanban.SmoothScrolling := False;
      for I := 1 to 4 do
        Kanban.Columns.AddColumn('Spalte ' + IntToStr(I));
      Kanban.Cards.BeginUpdate;
      try
        for I := 1 to 5000 do
          with Kanban.Cards.AddCard(1 + I mod 4, 'Aufgabe ' + IntToStr(I), 'Beschreibung <b>' + IntToStr(I) + '</b>') do
          begin
            Labels := 'L' + IntToStr(I mod 7);
            Assignee := 'Person ' + IntToStr(I mod 5);
          end;
      finally
        Kanban.Cards.EndUpdate;
      end;
      Measure('11a Kanban 5000 Karten: Layout + 100 x scrollen und zeichnen', 5000,
        procedure
        var
          J: Integer;
        begin
          Kanban.EnsureLayout;
          for J := 0 to 99 do
          begin
            Kanban.ScrollColumn(0, 400);
            PaintToBitmap(Kanban);
          end;
        end);
    finally
      Kanban.Free;
    end;

    // Phase14bRibbon TRibbonTests.ManyItemsStayFast; gemessen wie im Test:
    // 200 x Breite + Zeichnen (ohne den Aufbau)
    Ribbon := TPPGRibbon.Create(Form);
    try
      Ribbon.Parent := Form;
      Ribbon.Animation.Enabled := False;
      Ribbon.Align := alNone;
      for T := 0 to 9 do
      begin
        Tab := Ribbon.Tabs.AddTab('Karte ' + IntToStr(T));
        for G := 0 to 9 do
        begin
          Grp := Tab.Groups.AddGroup('Gruppe ' + IntToStr(G));
          for I := 0 to 9 do
            Grp.Items.AddButton('Befehl ' + IntToStr(G) + '.' + IntToStr(I), $E700 + I, TPPGRibbonSize(I mod 3));
        end;
      end;
      for G := 0 to 29 do
      begin
        Grp := Ribbon.Tabs[0].Groups.AddGroup('Viel ' + IntToStr(G));
        for I := 0 to 9 do
          Grp.Items.AddButton('Befehl ' + IntToStr(I), $E700 + I, TPPGRibbonSize(I mod 3));
      end;
      Measure('11a Ribbon 130 Gruppen: 200 x Breite + Zeichnen', 4000,
        procedure
        var
          J: Integer;
        begin
          for J := 0 to 199 do
          begin
            Ribbon.Width := 300 + (J * 7) mod 1300;
            Ribbon.UpdateLayout;
            PaintToBitmap(Ribbon);
          end;
        end);
    finally
      Ribbon.Free;
    end;

    // Phase18 TTileViewTests.VirtualHundredThousand
    Measure('11a TileView virtuell 100 000: Layout', 3000,
      procedure
      var
        V: TPPGTileView;
      begin
        V := TPPGTileView.Create(Form);
        try
          V.Parent := Form;
          V.SetBounds(0, 0, 600, 400);
          V.OnGetItem := D.TileItem;
          V.OwnerData := True;
          V.ItemCount := 100000;
          if V.VisibleCount <> 100000 then
            Exit;
        finally
          V.Free;
        end;
      end);
    // Gemessen wird wie im Test nur das Zeichnen (Layout steht schon)
    Tiles := TPPGTileView.Create(Form);
    try
      Tiles.Parent := Form;
      Tiles.SetBounds(0, 0, 600, 400);
      Tiles.OnGetItem := D.TileItem;
      Tiles.OwnerData := True;
      Tiles.ItemCount := 100000;
      if Tiles.VisibleCount = 100000 then
        Tiles.ScrollTo(0, MaxInt);
      Measure('11a TileView virtuell 100 000: am Ende zeichnen (nur sichtbar)', 500,
        procedure
        begin
          PaintToBitmap(Tiles);
        end);
    finally
      Tiles.Free;
    end;

    // Phase19 TBusyOverlayTests.FreeWhileAsyncRunningWaits (gemessen: Free)
    Measure('11a BusyOverlay: Free bricht laufende Arbeit ab', 2000,
      procedure
      var
        O: TPPGBusyOverlay;
        P: TPanel;
      begin
        P := TPanel.Create(Form);
        try
          P.Parent := Form;
          P.SetBounds(0, 0, 300, 200);
          O := TPPGBusyOverlay.Create(Form);
          O.Target := P;
          O.RunAsync(
            procedure(const C: IPPGBusyContext)
            var
              T0: Cardinal;
            begin
              T0 := GetTickCount;
              while not C.Cancelled and (GetTickCount - T0 < 5000) do
                Sleep(10);
            end, nil);
          O.Free;
        finally
          P.Free;
        end;
      end);

    // Audit8B TAudit8BTests.RowHeightsMillionRows
    Measure('11a Grid 1 Mio. Zeilen: 3 x RowHeights + 50 x ColWidths', 2000,
      procedure
      var
        G: TPPGGrid;
        V: Integer;
      begin
        G := TPPGGrid.Create(Form);
        try
          G.Parent := Form;
          G.SetBounds(0, 0, 600, 400);
          G.ColCount := 3;
          G.OnGetCellText := D.GridText;
          G.RowCount := 1000001;
          G.RowHeights[0] := 30;
          G.RowHeights[3] := 10;
          G.RowHeights[999999] := 40;
          for V := 0 to 49 do
            G.ColWidths[1] := 60 + V;
        finally
          G.Free;
        end;
      end);

    // Audit8A TAudit8AAnimatorTests.DueModeEndsOnTime (Ende nach 300 ms)
    Measure('11a Animation Faelligkeitsmodus 300 ms: Ende', 700,
      procedure
      var
        A: TPPGAnimation;
      begin
        A := TPPGAnimation.Create(nil);
        try
          A.StepInterval := 60000;
          A.AnimateTo(1, 300, ekLinear);
          Pump11(2000,
            function: Boolean
            begin
              Result := not A.Running;
            end);
        finally
          A.Free;
        end;
      end);

    // Audit8A TAudit8AAnimatorTests.ToastLifetimeEndsWithoutFrames (400 ms)
    Measure('11a Toast mit Lebensdauer 400 ms: Ende', 1000,
      procedure
      var
        F: TForm;
        C: TPPGNotificationCenter;
        T: TPPGToast;
      begin
        F := TForm.CreateNew(nil);
        try
          C := TPPGNotificationCenter.Create(F);
          C.Animation.Enabled := False;
          C.RespectQuietHours := False;
          T := C.Show('Kurz', 'Lebensdauer', psInformational, 400);
          T.Perform(CM_MOUSELEAVE, 0, 0);
          Pump11(3000,
            function: Boolean
            begin
              Result := C.VisibleCount = 0;
            end);
        finally
          F.Free;
        end;
      end);
  finally
    D.Free;
  end;
end;


begin
  // /hidden: auf eigenem Windows-Desktop neu starten (keine Fenster auf dem Bildschirm)
  if PPGRunOnHiddenDesktop then
    Exit;
  Application.Initialize;
  Form := TForm.CreateNew(nil);
  try
    // Sichtbar (ausserhalb des Bildschirms): unsichtbare Fenster richten
    // Kinder anders bzw. gar nicht neu aus - das wuerde die Messung schoenen
    Form.SetBounds(-3000, 0, 1200, 900);
    Form.Show;
    Writeln('PPGlow-Benchmark (Zeiten in ms, Exit-Code = Anzahl ueberschrittener Vorgaben)');
    Writeln;

    Measure('1000 Buttons erzeugen, zeichnen, freigeben', 4000,
      procedure
      var
        I: Integer;
        B: TPPGButton;
        L: TList;
      begin
        L := TList.Create;
        try
          for I := 0 to 999 do
          begin
            B := TPPGButton.Create(Form);
            B.Parent := Form;
            B.SetBounds((I mod 10) * 110, (I div 10) * 8, 100, 30);
            B.Caption := 'Button ' + IntToStr(I);
            L.Add(B);
          end;
          for I := 0 to L.Count - 1 do
            PaintToBitmap(TPPGButton(L[I]));
          for I := 0 to L.Count - 1 do
            TPPGButton(L[I]).Free;
        finally
          L.Free;
        end;
      end);

    Measure('Zeilen-Layout 1 000 000 fest: 1 000 000 x RowAt', 150,
      procedure
      var
        L: TPPGRowLayout;
        I: Integer;
      begin
        L := TPPGRowLayout.Create;
        try
          L.Count := 1000000;
          for I := 0 to 999999 do
            L.RowAt(Int64(I) * 20 + 7);
        finally
          L.Free;
        end;
      end);

    Measure('Zeilen-Layout 1 000 000 variabel: Cache + 1M RowAt', 1000,
      procedure
      var
        L: TPPGRowLayout;
        I: Integer;
      begin
        L := TPPGRowLayout.Create;
        try
          L.Count := 1000000;
          for I := 0 to 9999 do
            L.SetRowHeight(I * 100, 35);
          for I := 0 to 999999 do
            L.RowAt(Int64(I) * 20);
        finally
          L.Free;
        end;
      end);

    Measure('Auswahl 1 000 000: SelectAll, Bereich, Loeschen', 500,
      procedure
      var
        S: TPPGSelection;
      begin
        S := TPPGSelection.Create;
        try
          S.Mode := smExtended;
          S.Count := 1000000;
          S.SelectAll;
          S.Clear;
          S.SelectRange(1000, 900000, False);
          S.ItemsDeleted(10, 1000);
          S.ItemsInserted(10, 1000);
        finally
          S.Free;
        end;
      end);

    Measure('Markup 10 000 Texte parsen + Layout', 2500,
      procedure
      var
        L: TPPGMarkupLayout;
        I: Integer;
      begin
        L := TPPGMarkupLayout.Create;
        try
          for I := 0 to 9999 do
            L.Layout(Format('<b>Eintrag %d</b> mit <color=#C00000>Farbe</color> und ' +
              '<a href="x">Link</a> sowie etwas laengerem Text zum Umbrechen', [I]),
              Form.Font, nil, 200, True);
        finally
          L.Free;
        end;
      end);

    Measure('Scroll-Control 100 000 Zeilen: 300 x scrollen + zeichnen', 3000,
      procedure
      var
        S: TBenchScroller;
        I: Integer;
      begin
        S := TBenchScroller.Create(Form);
        try
          S.Parent := Form;
          S.SetBounds(0, 0, 400, 600);
          S.SetContentSize(380, 100000 * 20);
          for I := 0 to 299 do
          begin
            S.ScrollY := I * 6667;
            PaintToBitmap(S);
          end;
        finally
          S.Free;
        end;
      end);

    // Ausrichten kostet vor allem Windows (SetWindowPos je Kind-Fenster):
    // Vorgabe relativ zur Standard-VCL (hoechstens 30 % langsamer)
    VclMs := Measure('Referenz VCL: Resize TPanel + 300 TCheckBox', High(Cardinal),
      procedure
      var
        P: Vcl.ExtCtrls.TPanel;
        I: Integer;
        C: Vcl.StdCtrls.TCheckBox;
      begin
        P := Vcl.ExtCtrls.TPanel.Create(Form);
        try
          P.Parent := Form;
          P.SetBounds(0, 0, 800, 600);
          for I := 0 to 299 do
          begin
            C := Vcl.StdCtrls.TCheckBox.Create(P);
            C.Parent := P;
            C.SetBounds(4, 4 + I * 2, 120, 22);
            if I mod 3 = 0 then
              C.Align := alTop;
          end;
          for I := 0 to 199 do
            P.SetBounds(0, 0, 600 + I mod 50 * 4, 500 + I mod 30 * 4);
        finally
          P.Free;
        end;
      end);

    Measure('Resize-Sturm: 200 x TPPGPanel + 300 TPPGCheckBox', VclMs * 13 div 10 + 100,
      procedure
      var
        P: TPPGPanel;
        I: Integer;
        C: TPPGCheckBox;
      begin
        P := TPPGPanel.Create(Form);
        try
          P.Parent := Form;
          P.SetBounds(0, 0, 800, 600);
          for I := 0 to 299 do
          begin
            C := TPPGCheckBox.Create(P);
            C.Parent := P;
            C.SetBounds(4, 4 + I * 2, 120, 22);
            if I mod 3 = 0 then
              C.Align := alTop;
          end;
          for I := 0 to 199 do
            P.SetBounds(0, 0, 600 + I mod 50 * 4, 500 + I mod 30 * 4);
        finally
          P.Free;
        end;
      end);

    Measure('Panel mit 300 Kindern zeichnen (10 x PaintTo)', 3000,
      procedure
      var
        P: TPPGPanel;
        I: Integer;
        C: TPPGCheckBox;
      begin
        P := TPPGPanel.Create(Form);
        try
          P.Parent := Form;
          P.SetBounds(0, 0, 800, 600);
          for I := 0 to 299 do
          begin
            C := TPPGCheckBox.Create(P);
            C.Parent := P;
            C.SetBounds(4 + (I mod 5) * 150, 4 + (I div 5) * 9, 140, 22);
          end;
          for I := 0 to 9 do
            PaintToBitmap(P);
        finally
          P.Free;
        end;
      end);

    { Phase 6: Daten-Controls }
    Measure('ListBox virtuell 1 000 000: 300 x scrollen + zeichnen', 3000,
      procedure
      var
        L: TPPGListBox;
        D: TBenchData;
        I: Integer;
      begin
        D := TBenchData.Create;
        L := TPPGListBox.Create(Form);
        try
          L.Parent := Form;
          L.SetBounds(0, 0, 400, 600);
          L.SmoothScrolling := False;
          L.Style := lbVirtual;
          L.OnData := D.ListData;
          L.Count := 1000000;
          L.MultiSelect := True;
          L.SelectAll;
          for I := 0 to 299 do
          begin
            L.TopIndex := I * 3333;
            PaintToBitmap(L);
          end;
        finally
          L.Free;
          D.Free;
        end;
      end);

    Measure('TreeView 100 000 Knoten: aufbauen, aufklappen, zeichnen', 2000,
      procedure
      var
        T: TPPGTreeView;
        R: TPPGTreeNode;
        I, J: Integer;
      begin
        T := TPPGTreeView.Create(Form);
        try
          T.Parent := Form;
          T.SetBounds(0, 0, 400, 600);
          T.SmoothScrolling := False;
          T.Items.BeginUpdate;
          try
            for I := 0 to 99 do
            begin
              R := T.Items.Add(nil, 'Gruppe ' + IntToStr(I));
              for J := 0 to 999 do
                T.Items.AddChild(R, 'Knoten ' + IntToStr(J));
            end;
          finally
            T.Items.EndUpdate;
          end;
          T.FullExpand;
          for I := 0 to 49 do
          begin
            T.TopIndex := I * 2000;
            PaintToBitmap(T);
          end;
        finally
          T.Free;
        end;
      end);

    Measure('Grid 1 000 000 x 20 virtuell: 300 x scrollen + zeichnen', 3000,
      procedure
      var
        G: TPPGGrid;
        D: TBenchData;
        I: Integer;
      begin
        D := TBenchData.Create;
        G := TPPGGrid.Create(Form);
        try
          G.Parent := Form;
          G.SetBounds(0, 0, 800, 600);
          G.SmoothScrolling := False;
          G.OnGetCellText := D.GridText;
          G.ColCount := 20;
          G.RowCount := 1000001;
          for I := 0 to 299 do
          begin
            G.ScrollTo((I mod 10) * 60, I * 80000);
            PaintToBitmap(G);
          end;
        finally
          G.Free;
          D.Free;
        end;
      end);

    Measure('Grid 1 000 000 Zeilen: gruppieren (100 Gruppen) + Summen + zeichnen', 1500,
      procedure
      var
        G: TPPGGrid;
        D: TBenchData;
      begin
        D := TBenchData.Create;
        G := TPPGGrid.Create(Form);
        try
          G.Parent := Form;
          G.SetBounds(0, 0, 800, 600);
          G.SmoothScrolling := False;
          G.OnGetCellText := D.GroupText;
          G.Columns.Add.Title := '#';
          G.Columns.Add.Title := 'Gruppe';
          G.Columns.Add.Aggregate := agSum;
          G.FixedCols := 1;
          G.ShowFooter := True;
          G.GroupFooter := True;
          G.RowCount := 1000001;
          G.GroupBy([1]);
          if (G.GroupCount <> 100) or (G.FooterText(2) = '') then
            raise Exception.Create('Gruppieren falsch');
          PaintToBitmap(G);
        finally
          G.Free;
          D.Free;
        end;
      end);

    // Phase 7: Calendar und NavigationView
    Measure('xlsx: 1 000 000 Zeilen x 5 exportieren (Datei)', 6000,
      procedure
      var
        T: IPPGTableSource;
        F: string;
      begin
        T := TBenchTable.Create;
        F := TPath.Combine(TPath.GetTempPath, 'PPGlowBench.xlsx');
        PPGExportXlsx(T, F);
        System.SysUtils.DeleteFile(F);
      end);

    Measure('Druck: 1 000 000 Zeilen aufteilen + 3 Seiten in der Vorschau', 1000,
      procedure
      var
        P: TPPGGridPrinter;
        V: TPPGPrintPreviewView;
        D: TPPGPrintDevice;
        I: Integer;
      begin
        P := TPPGGridPrinter.Create(nil);
        V := TPPGPrintPreviewView.Create(Form);
        try
          V.Parent := Form;
          V.SetBounds(0, 0, 800, 600);
          P.SetSource(TBenchTable.Create);
          D := TPPGPrintDevice.A4(600, False);
          if P.PageCount(D) < 1000 then
            raise Exception.Create('zu wenige Seiten');
          V.Setup(P, D);
          for I := 0 to 2 do
            V.PageMetafile(I * 1000);
        finally
          V.Free;
          P.Free;
        end;
      end);

    Measure('Calendar: 1000 Monate blaettern + zeichnen', 2500,
      procedure
      var
        C: TPPGCalendar;
        I: Integer;
      begin
        C := TPPGCalendar.Create(Form);
        try
          C.Parent := Form;
          C.SetBounds(0, 0, 300, 330);
          C.Animation.Enabled := False;
          C.ShowWeekNumbers := True;
          C.SelectionMode := dsmRange;
          C.SelectRange(EncodeDate(2026, 1, 5), EncodeDate(2026, 1, 20));
          for I := 0 to 999 do
          begin
            C.NextPage;
            PaintToBitmap(C);
          end;
        finally
          C.Free;
        end;
      end);

    Measure('Calendar: 20 000 Tage per Tastatur', 1000,
      procedure
      var
        C: TPPGCalendar;
        I: Integer;
        K: Word;
      begin
        C := TPPGCalendar.Create(Form);
        try
          C.Parent := Form;
          C.Animation.Enabled := False;
          C.HandleNeeded;
          for I := 0 to 19999 do
          begin
            K := VK_RIGHT;
            TCalAccessB(C).KeyDown(K, []);
          end;
        finally
          C.Free;
        end;
      end);

    Measure('NavigationView 1000 Eintraege: 300 x scrollen + zeichnen', 2500,
      procedure
      var
        N: TPPGNavigationView;
        G, I: Integer;
        P: TPPGNavItem;
      begin
        N := TPPGNavigationView.Create(Form);
        try
          N.Parent := Form;
          N.Animation.Enabled := False;
          N.Height := 800;
          N.BeginItemsUpdate;
          try
            for G := 0 to 99 do
            begin
              P := N.Items.AddItem('Gruppe ' + IntToStr(G), PPGNavIconFolder);
              P.Expanded := True;
              for I := 0 to 8 do
                P.Items.AddItem('Eintrag ' + IntToStr(G * 10 + I), PPGNavIconDocument, I);
            end;
          finally
            N.EndItemsUpdate;
          end;
          for I := 0 to 299 do
          begin
            N.Perform(WM_MOUSEWHEEL, MakeWParam(0, Word(-120)), 0);
            PaintToBitmap(N);
          end;
        finally
          N.Free;
        end;
      end);

    Measure('NavigationView 1000 Eintraege: 1000 x Auswahl + zeichnen', 3000,
      procedure
      var
        N: TPPGNavigationView;
        I: Integer;
        P: TPPGNavItem;
      begin
        N := TPPGNavigationView.Create(Form);
        try
          N.Parent := Form;
          N.Animation.Enabled := False;
          N.Height := 800;
          N.BeginItemsUpdate;
          try
            for I := 0 to 999 do
              N.Items.AddItem('Eintrag ' + IntToStr(I), PPGNavIconDocument, I);
          finally
            N.EndItemsUpdate;
          end;
          for I := 0 to 999 do
          begin
            P := N.Items[(I * 37) mod 1000];
            N.Selected := P;
            PaintToBitmap(N);
          end;
        finally
          N.Free;
        end;
      end);

    // Phase 10: Diagramme (Ziel aus dem Plan: 100 000 Punkte <= 50 ms je Bild)
    Measure('Chart 100 000 Punkte: 20 x zeichnen', 1000,
      procedure
      var
        C: TPPGChart;
        V: TArray<Double>;
        I: Integer;
      begin
        C := TPPGChart.Create(Form);
        try
          C.Parent := Form;
          C.Animation.Enabled := False;
          C.SetBounds(0, 0, 800, 400);
          SetLength(V, 100000);
          for I := 0 to High(V) do
            V[I] := Sin(I / 700) * 100 + (I mod 17);
          C.Series.Add.SetValues(V);
          for I := 1 to 20 do
            PaintToBitmap(C);
        finally
          C.Free;
        end;
      end);

    Measure('Chart live: 600 x Wert anhaengen (1000 Punkte) + zeichnen', 3000,
      procedure
      var
        C: TPPGChart;
        S: TPPGChartSeries;
        I: Integer;
      begin
        C := TPPGChart.Create(Form);
        try
          C.Parent := Form;
          C.Animation.Enabled := False;
          C.SetBounds(0, 0, 800, 400);
          S := C.Series.Add;
          S.Kind := cskArea;
          for I := 0 to 999 do
            S.Append(Sin(I / 30) * 50, 1000);
          for I := 0 to 599 do
          begin
            S.Append(Sin(I / 30) * 50, 1000);
            PaintToBitmap(C);
          end;
        finally
          C.Free;
        end;
      end);

    // Phase 14a: Planer (Ziel aus dem Plan: 50 000 Termine im Jahr)
    Measure('Planer 50 000 Termine: 20 Wochen abfragen, anordnen, zeichnen', 2500,
      procedure
      var
        P: TPPGPlanner;
        A: TPPGAppointment;
        I: Integer;
      begin
        P := TPPGPlanner.Create(Form);
        try
          P.Parent := Form;
          P.SetBounds(0, 0, 1000, 700);
          P.ShowNowLine := False;
          P.Appointments.BeginUpdate;
          try
            for I := 0 to 49999 do
            begin
              A := P.Appointments.Add;
              A.StartTime := EncodeDate(2026, 1, 1) + (I mod 365) + (8 + I mod 10) / 24;
              A.FinishTime := A.StartTime + (1 + I mod 3) / 48;
              A.Subject := 'Termin ' + IntToStr(I);
            end;
          finally
            P.Appointments.EndUpdate;
          end;
          P.Date := EncodeDate(2026, 3, 2);
          for I := 1 to 20 do
          begin
            P.NextPage;
            PaintToBitmap(P);
          end;
        finally
          P.Free;
        end;
      end);

    Measure('Planer: 500 Serien, 12 Monate in der Monatsansicht', 2500,
      procedure
      var
        P: TPPGPlanner;
        A: TPPGAppointment;
        I: Integer;
      begin
        P := TPPGPlanner.Create(Form);
        try
          P.Parent := Form;
          P.SetBounds(0, 0, 1000, 700);
          P.View := pvMonth;
          P.Appointments.BeginUpdate;
          try
            for I := 0 to 499 do
            begin
              A := P.Appointments.AddAppointment(EncodeDate(2026, 1, 1) + I mod 28 + (8 + I mod 9) / 24,
                EncodeDate(2026, 1, 1) + I mod 28 + (9 + I mod 9) / 24, 'Serie ' + IntToStr(I));
              case I mod 3 of
                0: A.Recurrence := 'FREQ=DAILY;INTERVAL=3';
                1: A.Recurrence := 'FREQ=WEEKLY;BYDAY=MO,WE,FR';
              else
                A.Recurrence := 'FREQ=MONTHLY;BYDAY=2TU';
              end;
            end;
          finally
            P.Appointments.EndUpdate;
          end;
          P.Date := EncodeDate(2026, 1, 15);
          for I := 1 to 12 do
          begin
            P.NextPage;
            PaintToBitmap(P);
          end;
        finally
          P.Free;
        end;
      end);

    { Phase 20: ganze Serien verschieben, Kanban filtern }
    Measure('Planer: 500 Serien, 50 x ganze Serie verschieben + zeichnen', 2500,
      procedure
      var
        P: TPPGPlanner;
        A: TPPGAppointment;
        Occ: TPPGOccurrence;
        I: Integer;
      begin
        P := TPPGPlanner.Create(Form);
        try
          P.Parent := Form;
          P.SetBounds(0, 0, 1000, 700);
          P.ShowNowLine := False;
          P.SeriesEditMode := semSeries;
          P.Appointments.BeginUpdate;
          try
            for I := 0 to 499 do
            begin
              A := P.Appointments.AddAppointment(EncodeDate(2026, 1, 5) + I mod 5 + (8 + I mod 9) / 24,
                EncodeDate(2026, 1, 5) + I mod 5 + (8.5 + I mod 9) / 24, 'Serie ' + IntToStr(I));
              A.Recurrence := 'FREQ=WEEKLY;BYDAY=MO,WE,FR';
            end;
          finally
            P.Appointments.EndUpdate;
          end;
          P.Date := EncodeDate(2026, 3, 2);
          for I := 1 to 50 do
          begin
            if P.ItemCount = 0 then
              Break;
            Occ := P.Item(I mod P.ItemCount);
            P.ChangeAppointment(Occ, ackMove, Occ.Start + 1 / 96, Occ.Finish + 1 / 96,
              Occ.Appointment.ResourceId);
            PaintToBitmap(P);
          end;
        finally
          P.Free;
        end;
      end);

    Measure('Kanban 10 000 Karten aufbauen', High(Cardinal),
      procedure
      var
        K: TPPGKanban;
        C: array[0..3] of TPPGKanbanColumn;
        I: Integer;
      begin
        K := TPPGKanban.Create(Form);
        try
          K.Parent := Form;
          K.SetBounds(0, 0, 1000, 700);
          for I := 0 to 3 do
            C[I] := K.Columns.AddColumn('Spalte ' + IntToStr(I));
          K.Cards.BeginUpdate;
          try
            for I := 0 to 9999 do
              with K.Cards.AddCard(C[I mod 4].Id, 'Aufgabe ' + IntToStr(I), 'Text ' + IntToStr(I mod 97)) do
              begin
                Labels := 'L' + IntToStr(I mod 7);
                Assignee := 'Person ' + IntToStr(I mod 5);
              end;
          finally
            K.Cards.EndUpdate;
          end;
          PaintToBitmap(K);
          // Nur das Filtern messen, nicht den Aufbau
          Measure('Kanban 10 000 Karten: 20 x filtern + zeichnen', 2000,
            procedure
            var
              J: Integer;
            begin
              for J := 0 to 19 do
              begin
                K.FilterText := IntToStr(J + 10);
                if Odd(J) then
                  K.FilterAssignee := 'Person 2'
                else
                  K.FilterAssignee := '';
                PaintToBitmap(K);
              end;
              K.FilterText := '';
              K.FilterAssignee := '';
              PaintToBitmap(K);
            end);
        finally
          K.Free;
        end;
      end);

    { Phase 18: Kachelansicht }
    Measure('TileView virtuell 100 000: 300 x scrollen + zeichnen', 3000,
      procedure
      var
        V: TPPGTileView;
        D: TBenchData;
        I: Integer;
      begin
        D := TBenchData.Create;
        V := TPPGTileView.Create(Form);
        try
          V.Parent := Form;
          V.SetBounds(0, 0, 800, 600);
          V.SmoothScrolling := False;
          V.GroupView := False;
          V.OnGetItem := D.TileItem;
          V.OwnerData := True;
          V.ItemCount := 100000;
          for I := 0 to 299 do
          begin
            V.MakeItemVisible(I * 333);
            PaintToBitmap(V);
          end;
        finally
          V.Free;
          D.Free;
        end;
      end);

    Measure('TileView virtuell 100 000: 20 x filtern + zeichnen', 3000,
      procedure
      var
        V: TPPGTileView;
        D: TBenchData;
        I: Integer;
      begin
        D := TBenchData.Create;
        V := TPPGTileView.Create(Form);
        try
          V.Parent := Form;
          V.SetBounds(0, 0, 800, 600);
          V.OnGetItem := D.TileItem;
          V.OwnerData := True;
          V.ItemCount := 100000;
          for I := 0 to 19 do
          begin
            V.FilterText := IntToStr(I + 10);
            PaintToBitmap(V);
          end;
          V.FilterText := '';
          PaintToBitmap(V);
        finally
          V.Free;
          D.Free;
        end;
      end);

    { Phase 19: Validator }
    Measure('Validator: 500 Felder + 1000 Regeln aufbauen', High(Cardinal),
      procedure
      var
        V: TPPGValidator;
        E: TPPGEdit;
        P: TPPGPanel;
        I: Integer;
        R: TPPGValidationRule;
      begin
        P := TPPGPanel.Create(Form);
        V := TPPGValidator.Create(Form);
        try
          P.Parent := Form;
          P.SetBounds(0, 0, 800, 600);
          V.CheckOnClose := False;
          V.Rules.BeginUpdate;
          try
            for I := 0 to 499 do
            begin
              E := TPPGEdit.Create(P);
              E.Parent := P;
              E.SetBounds((I mod 5) * 150, (I div 5) * 6, 140, 24);
              V.Rules.AddRule(E, vrRequired);
              R := V.Rules.AddRule(E, vrPattern);
              R.PatternKind := vpEmail;
            end;
          finally
            V.Rules.EndUpdate;
          end;
          // Nur Validate messen, nicht den Aufbau
          Measure('Validator: Validate mit 500 Fehlern (sortiert, markiert)', 50,
            procedure
            begin
              V.Validate;
            end);
          Measure('Validator: Validate, alles gueltig', 50,
            procedure
            var
              J: Integer;
            begin
              for J := 0 to P.ControlCount - 1 do
                TPPGEdit(P.Controls[J]).Text := 'a@b.de';
              V.Validate;
            end);
        finally
          V.Free;
          P.Free;
        end;
      end);

    Writeln;
    Writeln('Audit-Paket 8');
    Bench8A;
    Bench8B;
    Bench8C;
    Bench8D;

    Writeln;
    Writeln('Audit-Paket 11 (Zeitgrenzen aus den Unit-Tests)');
    Bench11;

    Writeln;
    if Exceeded = 0 then
      Writeln('Alle Vorgaben eingehalten.')
    else
      Writeln(Format('%d Vorgabe(n) ueberschritten.', [Exceeded]));
  finally
    Form.Free;
  end;
  ExitCode := Exceeded;
end.
