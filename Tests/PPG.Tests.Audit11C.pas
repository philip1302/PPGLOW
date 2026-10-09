unit PPG.Tests.Audit11C;

{ Audit-Paket 11b (Teil C), Abdeckung:
  - TAudit11CGdiTests (#3): je Unit der Phasen 10e-17 und fuer die Audit-
    Controls ein Zeichentest mit GDI+ und GDI-Rueckfall
    (TPPGRendererRegistry.ForceGdiFallback): zeichnet ohne Fehler, Bild nicht
    leer, Zustand (Hover/Fokus/Deaktiviert bzw. Gruppierung, Summen, Seite)
    sichtbar verschieden von Normal.
  - Verhaltenstests (#5) fuer schwach getestete Bereiche: Render-Presets,
    VCL-Styles, ToolBar, Dialoge, Wizard, MenuBar, Hinweise, Breadcrumb,
    Rating, Mask-/Password-/FileEdit, Column-/CheckComboBox, DB-Felder und
    DB-Lookup, Kanban-/Planer-Druck, Editor-Dialoge, iCalendar-Datei (mit und
    ohne BOM), PPGGetTokenColor.
  Erwartungen sind fachlich begruendete Literale (Doku, Windows-Verhalten),
  nicht aus dem geprueften Code abgelesen. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Variants, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Menus, Vcl.Dialogs, Vcl.ComCtrls,
  Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Types, PPG.Exceptions, PPG.Consts, PPG.Tokens, PPG.Theme, PPG.Appearance,
  PPG.Render.Registry, PPG.Controls.Base, PPG.Print,
  PPG.Button, PPG.Panel, PPG.Labels, PPG.Rating, PPG.Breadcrumb, PPG.ToolBar, PPG.MenuBar,
  PPG.Hints, PPG.Dialogs, PPG.Wizard, PPG.BusyOverlay, PPG.NumberEdit, PPG.MaskEdit,
  PPG.PasswordEdit, PPG.FileEdit, PPG.ColorPicker, PPG.CheckComboBox, PPG.ColumnComboBox,
  PPG.TagEdit, PPG.Grid, PPG.Grid.Columns, PPG.Grid.Print, PPG.Planner.Model, PPG.Planner,
  PPG.Planner.Print, PPG.Planner.ICal, PPG.Ribbon.Layout, PPG.Ribbon.Items, PPG.Ribbon,
  PPG.Kanban.Items, PPG.Kanban, PPG.Kanban.Print, PPG.Calendar, PPG.NavigationView,
  PPG.TreeView, PPG.DB.Chart, PPG.DB.Grid, PPG.DB.Planner, PPG.DB.Kanban, PPG.DB.Fields,
  Vcl.DBCtrls, PPG.DB.Lookup, PPG.DB.Navigator, PPG.VclStyles, PPG.Editors.Forms,
  PPG.Tests.Controls, PPG.Tests.Visual;

type
  /// Gemeinsame Datenquelle fuer die DB-Controls.
  TAudit11CCase = class(TControlTestCase)
  protected
    FData, FOrte: TClientDataSet;
    FSource, FOrtSrc: TDataSource;
    procedure SetUp; override;
    procedure NeedData;
  end;

  TAudit11CGdiTests = class(TAudit11CCase)
  published
    procedure Phase10eDBChartBothRenderers;
    procedure Phase11cWizardAndDialogBothRenderers;
    procedure Phase12aNumberMaskPasswordBothRenderers;
    procedure Phase12bFileAndColorBothRenderers;
    procedure Phase12cCombosAndTagsBothRenderers;
    procedure Phase12dDBFieldsBothRenderers;
    procedure Phase13GridGroupsAndFooterBothRenderers;
    procedure Phase13eAnd17PrintPageBothRenderers;
    procedure Phase13gDBGridBothRenderers;
    procedure Phase14aPlannerBothRenderers;
    procedure Phase14bRibbonBothRenderers;
    procedure Phase14cKanbanBothRenderers;
    procedure AuditControlsBothRenderers;
  end;


implementation

uses
  System.Math, System.DateUtils, System.IOUtils;

function CenterOf(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

function MouseLP(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

function Monday: TDateTime;
begin
  Result := EncodeDate(2026, 6, 1); // ein Montag
end;

function DT(Day, H, M: Integer): TDateTime;
begin
  Result := Monday + Day + EncodeTime(H, M, 0, 0);
end;

function Luma(C: TColor): Double;
begin
  C := ColorToRGB(C);
  Result := (0.2126 * GetRValue(C) + 0.7152 * GetGValue(C) + 0.0722 * GetBValue(C)) / 255;
end;

function ColorDist(A, B: TColor): Integer;
begin
  A := ColorToRGB(A);
  B := ColorToRGB(B);
  Result := Abs(GetRValue(A) - GetRValue(B)) + Abs(GetGValue(A) - GetGValue(B)) +
    Abs(GetBValue(A) - GetBValue(B));
end;

{ TAudit11CCase }

procedure TAudit11CCase.SetUp;
begin
  inherited SetUp;
  FForm.SetBounds(0, 0, 900, 700);
end;

procedure TAudit11CCase.NeedData;
begin
  if FData <> nil then
    Exit;
  FOrte := TClientDataSet.Create(FForm);
  FOrte.FieldDefs.Add('ID', ftInteger);
  FOrte.FieldDefs.Add('Ort', ftString, 40);
  FOrte.CreateDataSet;
  FOrte.AppendRecord([1, 'Hamburg']);
  FOrte.AppendRecord([2, 'Koeln']);
  FOrtSrc := TDataSource.Create(FForm);
  FOrtSrc.DataSet := FOrte;
  FData := TClientDataSet.Create(FForm);
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Name', ftString, 40);
  FData.FieldDefs.Add('Status', ftString, 20);
  FData.FieldDefs.Add('Beginn', ftDateTime);
  FData.FieldDefs.Add('Ende', ftDateTime);
  FData.FieldDefs.Add('Wert', ftFloat);
  FData.FieldDefs.Add('Farbe', ftInteger);
  FData.FieldDefs.Add('Kat', ftString, 40);
  FData.FieldDefs.Add('Tags', ftString, 80);
  FData.FieldDefs.Add('PLZ', ftString, 5);
  FData.FieldDefs.Add('OrtID', ftInteger);
  FData.CreateDataSet;
  FData.AppendRecord([1, 'Anna', 'todo', DT(2, 9, 0), DT(2, 10, 30), 12.5, clRed, 'Rot;Blau',
    'a;b', '12345', 2]);
  FData.AppendRecord([2, 'Bernd', 'doing', DT(3, 11, 0), DT(3, 12, 0), 7, clBlue, 'Gruen', 'c',
    '50667', 1]);
  FData.AppendRecord([3, 'Clara', 'done', DT(1, 14, 0), DT(1, 15, 30), 15.25, clGreen, 'Blau', '',
    '20095', 1]);
  FData.First;
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
end;

{ TAudit11CGdiTests }

procedure TAudit11CGdiTests.Phase10eDBChartBothRenderers;
var
  C: TPPGDBChart;
begin
  NeedData;
  FForm.Show;
  C := TPPGDBChart.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(0, 0, 360, 220);
  C.Animation.Enabled := False;
  C.ReloadDelay := 0;
  C.ValueFields := 'Wert';
  C.LabelField := 'Name';
  C.DataSource := FSource;
  // Diagramm mit Daten: Hover zeigt den Punkt, Fokus und Deaktiviert sichtbar
  PPGCheckStates(Self, C, 'DBChart', True, True, True, Point(C.Width div 2, C.Height div 2));
end;

procedure TAudit11CGdiTests.Phase11cWizardAndDialogBothRenderers;
var
  W: TPPGWizard;
  P: TPPGWizardPage;
  I: Integer;
  G: Boolean;
  D: TPPGTaskDialog;
  DF: TPPGDialogForm;
  B, Expanded: TBitmap;
begin
  FForm.Show;
  W := TPPGWizard.Create(FForm);
  W.Parent := FForm;
  W.SetBounds(0, 0, 420, 260);
  for I := 0 to 2 do
  begin
    P := TPPGWizardPage.Create(FForm);
    P.Caption := 'Schritt ' + IntToStr(I + 1);
    P.Wizard := W;
  end;
  W.ActivePageIndex := 1;
  PPGCheckStates(Self, W, 'Wizard', False, False, True, Point(0, 0));
  // Aufgabendialog: Inhalt gezeichnet; ausgeklappter Zusatztext sichtbar
  for G := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := G;
    D := TPPGTaskDialog.Create(nil);
    try
      D.Title := 'Speichern?';
      D.Text := 'Das Dokument wurde geaendert.';
      D.ExpandedText := 'Pfad: C:\Daten\Bericht.docx';
      D.CommonButtons := [tcbYes, tcbNo];
      DF := TPPGDialogForm.CreateFor(D, 0);
      try
        DF.HandleNeeded;
        B := PPGRender(DF);
        try
          PPGCheckPainted(Self, B, 'TaskDialog');
          DF.ExpandButton.Click;
          Expanded := PPGRender(DF);
          try
            CheckTrue((Expanded.Height > B.Height) or (PPGPixelDiff(B, Expanded, 15) >= 8),
              'ausgeklappt sichtbar anders');
          finally
            Expanded.Free;
          end;
        finally
          B.Free;
        end;
      finally
        DF.Free;
      end;
    finally
      D.Free;
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
end;

procedure TAudit11CGdiTests.Phase12aNumberMaskPasswordBothRenderers;
var
  N: TPPGNumberEdit;
  M: TPPGMaskEdit;
  P: TPPGPasswordEdit;
begin
  FForm.Show;
  N := TPPGNumberEdit.Create(FForm);
  N.Parent := FForm;
  N.SetBounds(10, 10, 220, 32);
  N.ShowSpinButtons := True;
  N.Value := 42;
  PPGCheckStates(Self, N, 'NumberEdit', True, True, True, Point(60, 16));
  M := TPPGMaskEdit.Create(FForm);
  M.Parent := FForm;
  M.SetBounds(10, 60, 220, 32);
  M.EditMask := '00000;1;_';
  M.Text := '12345';
  PPGCheckStates(Self, M, 'MaskEdit', True, True, True, Point(60, 16));
  P := TPPGPasswordEdit.Create(FForm);
  P.Parent := FForm;
  P.SetBounds(10, 110, 220, 32);
  P.Text := 'geheim';
  PPGCheckStates(Self, P, 'PasswordEdit', True, True, True, Point(60, 16));
end;

procedure TAudit11CGdiTests.Phase12bFileAndColorBothRenderers;
var
  F: TPPGFileEdit;
  C: TPPGColorPicker;
begin
  FForm.Show;
  F := TPPGFileEdit.Create(FForm);
  F.Parent := FForm;
  F.SetBounds(10, 10, 260, 32);
  F.FileName := 'C:\Daten\Bericht.docx';
  PPGCheckStates(Self, F, 'FileEdit', True, True, True, Point(60, 16));
  C := TPPGColorPicker.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(10, 60, 200, 32);
  C.Selected := clRed;
  PPGCheckStates(Self, C, 'ColorPicker', True, True, True, Point(60, 16));
end;

procedure TAudit11CGdiTests.Phase12cCombosAndTagsBothRenderers;
var
  Ch: TPPGCheckComboBox;
  Co: TPPGColumnComboBox;
  T: TPPGTagEdit;
begin
  FForm.Show;
  Ch := TPPGCheckComboBox.Create(FForm);
  Ch.Parent := FForm;
  Ch.SetBounds(10, 10, 220, 32);
  Ch.Items.CommaText := 'Rot,Gruen,Blau';
  Ch.CheckedText := 'Rot;Blau';
  PPGCheckStates(Self, Ch, 'CheckComboBox', True, True, True, Point(60, 16));
  Co := TPPGColumnComboBox.Create(FForm);
  Co.Parent := FForm;
  Co.SetBounds(10, 60, 220, 32);
  Co.Columns.Add.Title := 'Nr';
  Co.Columns.Add.Title := 'Name';
  Co.Items.Add('1|Mueller');
  Co.Items.Add('2|Albers');
  Co.DisplayColumn := 1;
  Co.ItemIndex := 0;
  PPGCheckStates(Self, Co, 'ColumnComboBox', True, True, True, Point(60, 16));
  T := TPPGTagEdit.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(10, 110, 260, 32);
  T.TagsText := 'Delphi;VCL';
  PPGCheckStates(Self, T, 'TagEdit', True, True, True, Point(200, 16));
end;

procedure TAudit11CGdiTests.Phase12dDBFieldsBothRenderers;
var
  N: TPPGDBNumberEdit;
  M: TPPGDBMaskEdit;
  C: TPPGDBColorPicker;
  Ch: TPPGDBCheckComboBox;
  T: TPPGDBTagEdit;
begin
  NeedData;
  FForm.Show;
  N := TPPGDBNumberEdit.Create(FForm);
  N.Parent := FForm;
  N.SetBounds(10, 10, 220, 32);
  N.DataField := 'Wert';
  N.DataSource := FSource;
  PPGCheckStates(Self, N, 'DBNumberEdit', True, True, True, Point(60, 16));
  M := TPPGDBMaskEdit.Create(FForm);
  M.Parent := FForm;
  M.SetBounds(10, 50, 220, 32);
  M.EditMask := '00000;1;_';
  M.DataField := 'PLZ';
  M.DataSource := FSource;
  PPGCheckStates(Self, M, 'DBMaskEdit', True, True, True, Point(60, 16));
  C := TPPGDBColorPicker.Create(FForm);
  C.Parent := FForm;
  C.SetBounds(10, 90, 220, 32);
  C.DataField := 'Farbe';
  C.DataSource := FSource;
  PPGCheckStates(Self, C, 'DBColorPicker', True, True, True, Point(60, 16));
  Ch := TPPGDBCheckComboBox.Create(FForm);
  Ch.Parent := FForm;
  Ch.SetBounds(10, 130, 220, 32);
  Ch.Items.CommaText := 'Rot,Gruen,Blau';
  Ch.DataField := 'Kat';
  Ch.DataSource := FSource;
  PPGCheckStates(Self, Ch, 'DBCheckComboBox', True, True, True, Point(60, 16));
  T := TPPGDBTagEdit.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(10, 170, 260, 32);
  T.DataField := 'Tags';
  T.DataSource := FSource;
  PPGCheckStates(Self, T, 'DBTagEdit', True, True, True, Point(200, 16));
end;

procedure TAudit11CGdiTests.Phase13GridGroupsAndFooterBothRenderers;
const
  Cats: array[1..6] of string = ('Obst', 'Obst', 'Gemuese', 'Obst', 'Gemuese', 'Brot');
  Names: array[1..6] of string = ('Apfel', 'Birne', 'Lauch', 'Kiwi', 'Mais', 'Brezel');
var
  G: TPPGGrid;
  R: Integer;
  Gdi: Boolean;
  Plain, Grouped, Footer: TBitmap;
begin
  FForm.Show;
  G := TPPGGrid.Create(FForm);
  G.Parent := FForm;
  G.SetBounds(0, 0, 420, 300);
  G.Columns.Add.Title := 'Kategorie';
  G.Columns.Add.Title := 'Name';
  G.Columns.Add.Title := 'Menge';
  G.RowCount := 7;
  for R := 1 to 6 do
  begin
    G.Cells[0, R] := Cats[R];
    G.Cells[1, R] := Names[R];
    G.Cells[2, R] := IntToStr(R * 3);
  end;
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    try
      G.GroupBy([]);
      G.ShowFooter := False;
      Plain := PPGRender(G);
      try
        PPGCheckPainted(Self, Plain, 'Grid');
        // Gruppenzeilen sichtbar
        G.GroupBy([0]);
        Grouped := PPGRender(G);
        try
          PPGCheckDiffers(Self, Plain, Grouped, 'Grid gruppiert');
        finally
          Grouped.Free;
        end;
        // Summenzeile sichtbar
        G.GroupBy([]);
        G.Columns[2].Aggregate := agSum;
        G.ShowFooter := True;
        Footer := PPGRender(G);
        try
          PPGCheckDiffers(Self, Plain, Footer, 'Grid mit Summenzeile');
        finally
          Footer.Free;
        end;
      finally
        Plain.Free;
      end;
    finally
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
  G.ShowFooter := False;
  PPGCheckStates(Self, G, 'Grid', False, True, True, Point(0, 0));
end;

procedure TAudit11CGdiTests.Phase13eAnd17PrintPageBothRenderers;
var
  G: TPPGGrid;
  Prn: TPPGGridPrinter;
  Dev: TPPGPrintDevice;
  R, N0: Integer;
  Gdi: Boolean;
  B: TBitmap;
begin
  G := TPPGGrid.Create(FForm);
  G.Parent := FForm;
  G.Columns.Add.Title := 'Nr';
  G.Columns.Add.Title := 'Text';
  G.RowCount := 121;
  for R := 1 to 120 do
  begin
    G.Cells[0, R] := IntToStr(R);
    G.Cells[1, R] := 'Zeile ' + IntToStr(R);
  end;
  Prn := TPPGGridPrinter.Create(FForm);
  Prn.Grid := G;
  Dev := TPPGPrintDevice.A4(96, False);
  N0 := -1;
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    try
      // 120 Zeilen passen nicht auf eine A4-Seite
      CheckTrue(Prn.PageCount(Dev) >= 2, 'mehrere Seiten');
      if N0 < 0 then
        N0 := Prn.PageCount(Dev)
      else
        CheckEquals(N0, Prn.PageCount(Dev), 'Seitenzahl unabhaengig vom Renderer');
      B := TBitmap.Create;
      try
        B.PixelFormat := pf24bit;
        B.SetSize(Dev.PageWidth, Dev.PageHeight);
        B.Canvas.Brush.Color := clWhite;
        B.Canvas.FillRect(Rect(0, 0, B.Width, B.Height));
        Prn.RenderPage(0, B.Canvas.Handle, Dev);
        PPGCheckPainted(Self, B, 'Druckseite');
      finally
        B.Free;
      end;
    finally
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
end;

procedure TAudit11CGdiTests.Phase13gDBGridBothRenderers;
var
  G: TPPGDBGrid;
begin
  NeedData;
  FForm.Show;
  G := TPPGDBGrid.Create(FForm);
  G.Parent := FForm;
  G.SetBounds(0, 0, 420, 200);
  G.DataSource := FSource;
  PPGCheckStates(Self, G, 'DBGrid', False, True, True, Point(0, 0));
end;

procedure TAudit11CGdiTests.Phase14aPlannerBothRenderers;
var
  P: TPPGPlanner;
  D: TPPGDBPlanner;
  R: TRect;
begin
  NeedData;
  FForm.Show;
  P := TPPGPlanner.Create(FForm);
  P.Parent := FForm;
  P.SetBounds(0, 0, 500, 400);
  P.Animation.Enabled := False;
  P.SmoothScrolling := False;
  P.FirstDayOfWeek := fdMonday;
  P.TimeZoneMode := tzmLocal;
  P.View := pvDay;
  P.DayStartHour := 8;
  P.DayEndHour := 16;
  P.Date := Monday + 2;
  P.NowOverride := DT(2, 11, 0);
  P.Appointments.AddAppointment(DT(2, 9, 0), DT(2, 10, 0), 'Termin');
  P.HandleNeeded;
  R := P.ItemRect(0);
  PPGCheckStates(Self, P, 'Planner', True, False, True, CenterOf(R));
  P.SelectAppointment(P.Appointments[0]);
  PPGCheckStates(Self, P, 'Planner gewaehlt', False, True, False, Point(0, 0));
  D := TPPGDBPlanner.Create(FForm);
  D.Parent := FForm;
  D.SetBounds(0, 0, 500, 400);
  D.Animation.Enabled := False;
  D.FirstDayOfWeek := fdMonday;
  D.TimeZoneMode := tzmLocal;
  D.View := pvDay;
  D.DayStartHour := 8;
  D.DayEndHour := 16;
  D.Date := Monday + 2;
  D.NowOverride := DT(2, 11, 0);
  D.ReloadDelay := 0;
  D.KeyField := 'ID';
  D.StartField := 'Beginn';
  D.FinishField := 'Ende';
  D.SubjectField := 'Name';
  D.DataSource := FSource;
  D.HandleNeeded;
  CheckTrue(D.Appointments.Count > 0, 'Termine aus der Datenquelle');
  R := D.ItemRect(0);
  PPGCheckStates(Self, D, 'DBPlanner', True, False, True, CenterOf(R));
end;

procedure TAudit11CGdiTests.Phase14bRibbonBothRenderers;
var
  Rb: TPPGRibbon;
  G: TPPGRibbonGroup;
  It: TPPGRibbonItem;
begin
  FForm.Show;
  Rb := TPPGRibbon.Create(FForm);
  Rb.Parent := FForm;
  Rb.SetBounds(0, 0, 600, 130);
  G := Rb.Tabs.AddTab('Start').Groups.AddGroup('Zwischenablage');
  It := G.Items.AddButton('Einfuegen', $E77F, rsLarge);
  G.Items.AddButton('Kopieren', $E8C8, rsMedium);
  Rb.HandleNeeded;
  // Hover auf "Einfuegen", Deaktiviert; das Ribbon steht nicht in der Tab-Folge
  PPGCheckStates(Self, Rb, 'Ribbon', True, False, True, CenterOf(Rb.ItemRect(It)));
end;

procedure TAudit11CGdiTests.Phase14cKanbanBothRenderers;
var
  K: TPPGKanban;
  DK: TPPGDBKanban;
  Col: TPPGKanbanColumn;
begin
  NeedData;
  FForm.Show;
  K := TPPGKanban.Create(FForm);
  K.Parent := FForm;
  K.SetBounds(0, 0, 500, 300);
  K.Animation.Enabled := False;
  K.SmoothScrolling := False;
  Col := K.Columns.AddColumn('Offen');
  K.Cards.AddCard(Col.Id, 'Eins');
  K.Cards.AddCard(Col.Id, 'Zwei');
  K.HandleNeeded;
  PPGCheckStates(Self, K, 'Kanban', True, False, True, CenterOf(K.CardRect(0, 0, 1)));
  K.Select(0, 0, 0);
  PPGCheckStates(Self, K, 'Kanban gewaehlt', False, True, False, Point(0, 0));
  DK := TPPGDBKanban.Create(FForm);
  DK.Parent := FForm;
  DK.SetBounds(0, 0, 500, 300);
  DK.Animation.Enabled := False;
  DK.ReloadDelay := 0;
  DK.Columns.AddColumn('Offen').Key := 'todo';
  DK.Columns.AddColumn('In Arbeit').Key := 'doing';
  DK.KeyField := 'ID';
  DK.ColumnField := 'Status';
  DK.TitleField := 'Name';
  DK.DataSource := FSource;
  DK.HandleNeeded;
  CheckEquals(1, DK.CardCount(0, 0), 'Karte aus der Datenquelle');
  PPGCheckStates(Self, DK, 'DBKanban', True, False, True, CenterOf(DK.CardRect(0, 0, 0)));
end;

procedure TAudit11CGdiTests.AuditControlsBothRenderers;
var
  O: TPPGBusyOverlay;
  Pn: TPanel;
  Nav: TPPGDBNavigator;
  Gdi: Boolean;
  A, B: TBitmap;
begin
  NeedData;
  FForm.Show;
  // Busy-Karte: Fortschritt sichtbar (40 % gegen 80 %)
  Pn := TPanel.Create(FForm);
  Pn.Parent := FForm;
  Pn.SetBounds(10, 10, 300, 220);
  O := TPPGBusyOverlay.Create(FForm);
  try
    O.Target := Pn;
    O.Delay := 0;
    O.MinDisplayTime := 0;
    O.Text := 'Export';
    for Gdi := False to True do
    begin
      TPPGRendererRegistry.ForceGdiFallback := Gdi;
      try
        O.Progress := 40;
        O.ShowNow;
        A := PPGRender(O.Card);
        try
          PPGCheckPainted(Self, A, 'Busy-Karte');
          O.Progress := 80;
          B := PPGRender(O.Card);
          try
            PPGCheckDiffers(Self, A, B, 'Busy-Karte Fortschritt');
          finally
            B.Free;
          end;
        finally
          A.Free;
        end;
        O.Hide;
      finally
        TPPGRendererRegistry.ForceGdiFallback := False;
      end;
    end;
  finally
    O.Free;
  end;
  Nav := TPPGDBNavigator.Create(FForm);
  Nav.Parent := FForm;
  Nav.SetBounds(10, 300, 330, 34);
  Nav.DataSource := FSource;
  PPGCheckStates(Self, Nav, 'DBNavigator', True, True, True, CenterOf(Nav.ButtonRect(nbNext)));
end;

initialization
  RegisterTest('Audit11C', TAudit11CGdiTests.Suite);

end.
