program PPGlowBench;

{ Leistungsmessung der Suite (Phase 5). Konsole; Exit-Code = Anzahl
  ueberschrittener Zeitvorgaben. Bauen: build.ps1 -Projects Bench -Config Release }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  PPG.Consts in '..\..\Source\Core\PPG.Consts.pas',
  PPG.Lang in '..\..\Source\Core\PPG.Lang.pas',
  PPG.Lang.De in '..\..\Source\Core\PPG.Lang.De.pas',
  PPG.Exceptions in '..\..\Source\Core\PPG.Exceptions.pas',
  PPG.ErrorHandler in '..\..\Source\Core\PPG.ErrorHandler.pas',
  PPG.Types in '..\..\Source\Core\PPG.Types.pas',
  PPG.Tokens in '..\..\Source\Core\PPG.Tokens.pas',
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
  PPG.Markup in '..\..\Source\Render\PPG.Markup.pas',
  PPG.RowLayout in '..\..\Source\Controls\PPG.RowLayout.pas',
  PPG.Controls.Scroll in '..\..\Source\Controls\PPG.Controls.Scroll.pas',
  PPG.ItemPainter in '..\..\Source\Controls\PPG.ItemPainter.pas',
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
  PPG.Notifications in '..\..\Source\Controls\PPG.Notifications.pas';

{$R *.res}

type
  /// Scroll-Control mit 100 000 Zeilen (nur sichtbare Zeilen zeichnen).
  TBenchScroller = class(TPPGCustomScrollControl)
  protected
    procedure PaintViewport(const ACanvas: IPPGCanvas; const View: TRect); override;
  end;

  /// Ereignis-Handler der Daten-Controls (Ereignisse brauchen Methoden).
  TCalAccessB = class(TPPGCalendar);

  TBenchData = class
  public
    procedure ListData(Control: TWinControl; Index: Integer; var Data: string);
    procedure GridText(Sender: TObject; ACol, ARow: Integer; var Text: string);
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

procedure TBenchData.GridText(Sender: TObject; ACol, ARow: Integer; var Text: string);
begin
  Text := IntToStr(ARow * 31 + ACol);
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

begin
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

    // Phase 7: Calendar und NavigationView
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
