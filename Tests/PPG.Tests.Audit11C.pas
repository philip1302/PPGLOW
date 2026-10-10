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

  TAudit11CBehaviourTests = class(TAudit11CCase)
  private
    FClicks: TStringList;
    FDialogAction: Integer;
    procedure LogClick(Sender: TObject);
    procedure DialogHook(Form: TPPGDialogForm);
    function ClickEditorButton(D: TForm; const ACaption: string): Boolean;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // Render-Presets (Doku: Classic = Glanzverlauf, ModernFlat = flach mit Glow)
    procedure ClassicPresetHasGlossGradient;
    procedure ModernFlatIsFlatAndGlowsOnHover;
    // VCL-Styles: ohne aktiven Style bleibt alles beim Preset
    procedure VclStyleColorsWithoutStyleChangeNothing;
    procedure VclStyleOffUsesOwnAppearance;
    // ToolBar
    procedure ToolBarHiddenItemTakesNoSpace;
    // Dialoge
    procedure MessageDlgReturnsClickedButton;
    procedure TaskDialogReportsVerificationAndRadio;
    // Wizard
    procedure WizardNextOnLastStepFinishes;
    procedure WizardCancelFiresEventAndKeepsPage;
    // MenuBar
    procedure MenuBarSkipsHiddenItems;
    // Hinweise
    procedure HintMaxWidthRejectsInvalidValues;
    // Breadcrumb
    procedure BreadcrumbSetPathDropsEmptySegments;
    // Rating
    procedure RatingDigitKeysClampToMax;
    procedure RatingArrowsFollowReadingDirection;
    // Mask-/Password-/FileEdit
    procedure MaskEditRejectsLettersInDigitMask;
    procedure PasswordEditRevealShowsText;
    procedure FileEditKeepsFileName;
    // Column-/CheckComboBox
    procedure CheckComboCheckedTextIgnoresUnknownItems;
    procedure ColumnComboShowsDisplayColumn;
    // DB-Felder und Lookup
    procedure DBNumberEditFollowsRecord;
    procedure DBLookupShowsListTextOfKey;
    // Druck
    procedure PlannerPrintOnePagePerWeek;
    procedure KanbanPrintPagesAndContent;
    // Editor-Dialoge (Logik)
    procedure NavItemsDialogMovesAndIndents;
    procedure TreeItemsDialogDeletesAndIndents;
    // iCalendar
    procedure LoadICalFileWithAndWithoutBom;
    // Tokens
    procedure TokenColorCoversAllKinds;
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
  // DUnit verwendet die Testinstanz in jedem Lauf wieder (/leaks); die
  // Datenquellen gehoerten dem alten Formular
  FData := nil;
  FOrte := nil;
  FSource := nil;
  FOrtSrc := nil;
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

{ TAudit11CBehaviourTests }

procedure TAudit11CBehaviourTests.SetUp;
begin
  inherited SetUp;
  FClicks := TStringList.Create;
end;

procedure TAudit11CBehaviourTests.TearDown;
begin
  PPGOnDialogShow := nil;
  try
    inherited TearDown;
  finally
    FreeAndNil(FClicks);
  end;
end;

procedure TAudit11CBehaviourTests.LogClick(Sender: TObject);
begin
  if Sender is TComponent then
    FClicks.Add(TComponent(Sender).Name)
  else
    FClicks.Add('?');
end;

procedure TAudit11CBehaviourTests.DialogHook(Form: TPPGDialogForm);
begin
  case FDialogAction of
    1: Form.ClickButton(mrNo);
    2:
      begin
        // Verifikation anhaken, zweite Option waehlen, OK
        // wie der Anwender: anklicken (Code-Zuweisungen loesen bewusst nichts aus)
        Form.VerificationBox.Click;
        Form.Radio(1).Checked := True;
        Form.Radio(1).Click;
        Form.ClickButton(mrOk);
      end;
  else
    Form.Cancel;
  end;
end;

function TAudit11CBehaviourTests.ClickEditorButton(D: TForm; const ACaption: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to D.ComponentCount - 1 do
    if (D.Components[I] is TButton) and SameText(TButton(D.Components[I]).Caption, ACaption) then
    begin
      TButton(D.Components[I]).Click;
      Result := True;
      Exit;
    end;
end;

procedure TAudit11CBehaviourTests.ClassicPresetHasGlossGradient;
var
  B: TPPGButton;
  Bmp: TBitmap;
  Top, Bottom: TColor;
begin
  // Doku (Architektur): Classic = Glanz-Verlauf, Glanzkante bei 40 % der Hoehe
  B := NewButton('');
  B.SetBounds(10, 10, 120, 40);
  B.Preset := PPGPresetClassic;
  Bmp := RenderToBitmap(B);
  try
    Top := Bmp.Canvas.Pixels[60, 10];    // obere Haelfte des Glanzes
    Bottom := Bmp.Canvas.Pixels[60, 30]; // unter der Glanzkante
    CheckTrue(ColorDist(Top, Bottom) >= 10,
      Format('Classic: oben und unten gleiche Farbe (%.6x / %.6x)', [Top, Bottom]));
  finally
    Bmp.Free;
  end;
end;

procedure TAudit11CBehaviourTests.ModernFlatIsFlatAndGlowsOnHover;
var
  B: TPPGButton;
  N, H: TBitmap;
  X, Y, Changed: Integer;
begin
  // Doku: ModernFlat = einfarbige Flaeche; Hover zeigt einen aeusseren Glow
  FForm.Show;
  B := NewButton('');
  B.SetBounds(10, 10, 120, 40);
  B.Preset := PPGPresetModernFlat;
  N := RenderToBitmap(B);
  try
    CheckTrue(ColorDist(N.Canvas.Pixels[60, 12], N.Canvas.Pixels[60, 28]) <= 6,
      'ModernFlat: Flaeche einfarbig');
    B.Perform(CM_MOUSEENTER, 0, 0);
    B.Perform(WM_MOUSEMOVE, 0, MouseLP(60, 20));
    H := RenderToBitmap(B);
    try
      // Glow liegt ausserhalb des Koerpers: im Randstreifen (2 px) aendert sich etwas
      Changed := 0;
      for X := 0 to B.Width - 1 do
        for Y := 0 to 1 do
          if ColorDist(N.Canvas.Pixels[X, Y], H.Canvas.Pixels[X, Y]) > 10 then
            Inc(Changed);
      CheckTrue(Changed > 0, 'Hover: kein Glow am Rand');
    finally
      H.Free;
    end;
  finally
    N.Free;
  end;
end;

procedure TAudit11CBehaviourTests.VclStyleColorsWithoutStyleChangeNothing;
var
  A, Before: TPPGAppearance;
begin
  // Ohne aktiven VCL-Style uebernimmt PPGApplyVclStyleColors nichts (Doku der Unit)
  CheckFalse(PPGVclStyleActive, 'Testlauf ohne VCL-Style');
  A := TPPGAppearance.Create(nil);
  Before := TPPGAppearance.Create(nil);
  try
    A.Normal.Color := $00123456;
    A.Hot.Color := $00234567;
    A.Rounding := 7;
    A.GlowSize := 4;
    Before.Assign(A);
    PPGApplyVclStyleColors(A);
    CheckEquals(Integer($00123456), Integer(A.Normal.Color));
    CheckEquals(Integer($00234567), Integer(A.Hot.Color));
    CheckEquals(7, A.Rounding);
    CheckEquals(4, A.GlowSize);
    PPGApplyVclStyleColors(nil); // nil ist erlaubt
  finally
    Before.Free;
    A.Free;
  end;
end;

procedure TAudit11CBehaviourTests.VclStyleOffUsesOwnAppearance;
var
  B: TPPGButton;
begin
  // Ohne aktiven VCL-Style zeichnet ein Control mit seiner eigenen Appearance
  // (keine gestylte Kopie); StyleElements aendern daran nichts
  B := NewButton('A');
  CheckFalse(B.UseVclStyle, 'kein Style aktiv');
  CheckTrue(B.EffectiveAppearance = B.Appearance, 'eigene Appearance');
  B.StyleElements := [seFont, seClient, seBorder];
  CheckFalse(B.UseVclStyle);
  CheckTrue(B.EffectiveAppearance = B.Appearance);
end;

procedure TAudit11CBehaviourTests.ToolBarHiddenItemTakesNoSpace;
var
  T: TPPGToolBar;
  Left2: Integer;
begin
  T := TPPGToolBar.Create(FForm);
  T.Parent := FForm;
  T.Width := 600;
  T.Items.AddButton('Neu', $E710, nil);
  T.Items.AddButton('Oeffnen', $E8E5, nil);
  T.Items.AddButton('Speichern', $E74E, nil);
  T.HandleNeeded;
  Left2 := T.ItemRect(2).Left;
  T.Items[1].Visible := False;
  CheckTrue(IsRectEmpty(T.ItemRect(1)), 'ausgeblendeter Button hat keine Flaeche');
  CheckTrue(T.ItemRect(2).Left < Left2, 'folgender Button rueckt nach');
  CheckEquals(T.ItemRect(1).Left, T.ItemRect(1).Right);
  T.Items[1].Visible := True;
  CheckEquals(Left2, T.ItemRect(2).Left, 'wieder eingeblendet: alte Lage');
end;

procedure TAudit11CBehaviourTests.MessageDlgReturnsClickedButton;
begin
  FDialogAction := 1;
  PPGOnDialogShow := DialogHook;
  CheckEquals(mrNo, PPGMessageDlg('Weiter?', mtConfirmation, [mbYes, mbNo], 0),
    'Ergebnis = angeklickter Button');
  FDialogAction := 0;
  // Esc bei Ja/Nein/Abbrechen = Abbrechen (wie MessageDlg der VCL)
  CheckEquals(mrCancel, PPGMessageDlg('Speichern?', mtConfirmation, [mbYes, mbNo, mbCancel], 0));
end;

procedure TAudit11CBehaviourTests.TaskDialogReportsVerificationAndRadio;
var
  D: TPPGTaskDialog;
begin
  D := TPPGTaskDialog.Create(FForm);
  D.Title := 'Exportieren';
  D.Text := 'Welche Dateien?';
  D.VerificationText := 'Nicht mehr fragen';
  D.RadioButtons.Add.Caption := 'Alle';
  D.RadioButtons.Add.Caption := 'Nur diese';
  D.CommonButtons := [tcbOk, tcbCancel];
  FDialogAction := 2;
  PPGOnDialogShow := DialogHook;
  CheckTrue(D.Execute, 'Execute');
  CheckEquals(mrOk, D.ModalResult);
  CheckTrue(tfVerificationFlagChecked in D.Flags, 'Haken der Verifikation zurueckgemeldet');
  CheckNotNull(D.RadioButton, 'gewaehlte Option');
  CheckEquals(1, D.RadioButton.Index, 'zweite Option');
end;

procedure TAudit11CBehaviourTests.WizardNextOnLastStepFinishes;
var
  W: TPPGWizard;
  P: TPPGWizardPage;
  I: Integer;
begin
  W := TPPGWizard.Create(FForm);
  W.Parent := FForm;
  W.SetBounds(0, 0, 400, 300);
  for I := 0 to 2 do
  begin
    P := TPPGWizardPage.Create(FForm);
    P.Name := 'Seite' + IntToStr(I);
    P.Caption := 'Seite ' + IntToStr(I);
    P.Wizard := W;
  end;
  W.Name := 'Wiz';
  W.OnFinish := LogClick;
  W.ActivePageIndex := 0;
  CheckFalse(W.Back, 'erster Schritt: Zurueck geht nicht');
  CheckTrue(W.Next);
  CheckTrue(W.Next);
  CheckTrue(W.IsLastStep, 'dritter von drei Schritten');
  CheckEquals(0, FClicks.Count, 'noch nicht fertig');
  W.Next; // auf dem letzten Schritt = Fertigstellen
  CheckEquals('Wiz', FClicks.CommaText, 'OnFinish genau einmal');
  CheckEquals(2, W.ActivePageIndex, 'bleibt auf dem letzten Schritt');
end;

procedure TAudit11CBehaviourTests.WizardCancelFiresEventAndKeepsPage;
var
  W: TPPGWizard;
  P: TPPGWizardPage;
  I: Integer;
begin
  W := TPPGWizard.Create(FForm);
  W.Parent := FForm;
  W.Name := 'Wiz';
  for I := 0 to 1 do
  begin
    P := TPPGWizardPage.Create(FForm);
    P.Wizard := W;
  end;
  W.OnCancel := LogClick;
  W.ActivePageIndex := 1;
  W.Cancel;
  CheckEquals('Wiz', FClicks.CommaText, 'OnCancel');
  CheckEquals(1, W.ActivePageIndex, 'Seite bleibt');
end;

procedure TAudit11CBehaviourTests.MenuBarSkipsHiddenItems;
var
  Bar: TPPGMenuBar;
  M: TMainMenu;
  I: Integer;
  It: TMenuItem;
const
  Titles: array[0..3] of string = ('&Datei', '&Bearbeiten', '&Ansicht', '&Hilfe');
begin
  M := TMainMenu.Create(FForm);
  for I := 0 to High(Titles) do
  begin
    It := TMenuItem.Create(M);
    It.Caption := Titles[I];
    M.Items.Add(It);
  end;
  Bar := TPPGMenuBar.Create(FForm);
  Bar.Parent := FForm;
  Bar.Width := 600;
  Bar.Menu := M;
  Bar.HandleNeeded;
  CheckEquals(4, Bar.ItemCount);
  M.Items[1].Visible := False;
  CheckEquals(3, Bar.ItemCount, 'ausgeblendet zaehlt nicht');
  CheckTrue(Bar.Item(1) = M.Items[2], 'zweiter sichtbarer Eintrag ist "Ansicht"');
  CheckEquals(1, Bar.ItemAtPos(CenterOf(Bar.ItemRect(1)).X, CenterOf(Bar.ItemRect(1)).Y),
    'Trefferpruefung passt zur Lage');
  CheckTrue(Bar.ItemRect(1).Left >= Bar.ItemRect(0).Right, 'nebeneinander, ohne Ueberlappung');
end;

procedure TAudit11CBehaviourTests.HintMaxWidthRejectsInvalidValues;
var
  H: TPPGCustomHint;
  M: TPPGHintManager;
  Raised: Boolean;
begin
  H := TPPGCustomHint.Create(FForm);
  H.MaxWidth := 300;
  Raised := False;
  try
    H.MaxWidth := 10; // kleiner als jede sinnvolle Hinweisbreite
  except
    on EPPGPropertyError do
      Raised := True;
  end;
  CheckTrue(Raised, 'CustomHint: 10 px abgelehnt');
  CheckEquals(300, H.MaxWidth, 'Wert bleibt');
  M := TPPGHintManager.Create(nil);
  try
    M.MaxWidth := 400;
    Raised := False;
    try
      M.MaxWidth := 100000;
    except
      on EPPGPropertyError do
        Raised := True;
    end;
    CheckTrue(Raised, 'HintManager: 100000 px abgelehnt');
    CheckEquals(400, M.MaxWidth);
  finally
    M.Free;
  end;
end;

procedure TAudit11CBehaviourTests.BreadcrumbSetPathDropsEmptySegments;
var
  B: TPPGBreadcrumb;
begin
  B := TPPGBreadcrumb.Create(FForm);
  B.Parent := FForm;
  B.SetPath('\\server\freigabe\Projekte\');
  CheckEquals('server,freigabe,Projekte', B.Items.CommaText,
    'UNC-Praefix und abschliessender Trenner ergeben keine leeren Segmente');
  B.SetPath('home/anna/bilder', '/');
  CheckEquals('home,anna,bilder', B.Items.CommaText, 'eigener Trenner');
  B.SetPath('');
  CheckEquals(0, B.Items.Count, 'leerer Pfad');
end;

procedure TAudit11CBehaviourTests.RatingDigitKeysClampToMax;
var
  R: TPPGRating;
  Ch: Char;
begin
  FForm.Show;
  R := TPPGRating.Create(FForm);
  R.Parent := FForm;
  R.Max := 5;
  R.SetFocus;
  Ch := '3';
  R.Perform(WM_CHAR, Ord(Ch), 0);
  CheckEquals(3, R.Value, 0, 'Ziffer setzt den Wert');
  Ch := '9';
  R.Perform(WM_CHAR, Ord(Ch), 0);
  CheckEquals(5, R.Value, 0, 'groesser als Max: auf Max begrenzt');
  R.Perform(WM_KEYDOWN, VK_HOME, 0);
  CheckEquals(0, R.Value, 0, 'Pos1 = 0');
  R.Perform(WM_KEYDOWN, VK_END, 0);
  CheckEquals(5, R.Value, 0, 'Ende = Max');
end;

procedure TAudit11CBehaviourTests.RatingArrowsFollowReadingDirection;
var
  R: TPPGRating;
begin
  FForm.Show;
  R := TPPGRating.Create(FForm);
  R.Parent := FForm;
  R.Value := 2;
  R.SetFocus;
  R.Perform(WM_KEYDOWN, VK_RIGHT, 0);
  CheckEquals(3, R.Value, 0, 'links nach rechts: Rechts = mehr');
  R.BiDiMode := bdRightToLeft;
  R.Perform(WM_KEYDOWN, VK_RIGHT, 0);
  CheckEquals(2, R.Value, 0, 'rechts nach links: Rechts = weniger');
  R.Perform(WM_KEYDOWN, VK_LEFT, 0);
  CheckEquals(3, R.Value, 0, 'rechts nach links: Links = mehr');
end;

procedure TAudit11CBehaviourTests.MaskEditRejectsLettersInDigitMask;
var
  M: TPPGMaskEdit;
  E: TWinControl;
  I: Integer;
begin
  FForm.Show;
  M := TPPGMaskEdit.Create(FForm);
  M.Parent := FForm;
  M.EditMask := '00000;0;_';
  M.SetFocus;
  E := nil;
  for I := 0 to M.ControlCount - 1 do
    if M.Controls[I] is TWinControl then
      E := TWinControl(M.Controls[I]);
  CheckNotNull(E, 'inneres Edit');
  E.Perform(WM_CHAR, Ord('1'), 0);
  E.Perform(WM_CHAR, Ord('x'), 0); // Buchstabe in Ziffernmaske: abgelehnt
  E.Perform(WM_CHAR, Ord('2'), 0);
  CheckEquals(0, Pos('x', M.EditText), 'Buchstabe abgelehnt');
  CheckEquals('12', Copy(M.EditText, 1, 2), 'Ziffern an den Stellen 1 und 2');
end;

procedure TAudit11CBehaviourTests.PasswordEditRevealShowsText;
var
  P: TPPGPasswordEdit;
begin
  P := TPPGPasswordEdit.Create(FForm);
  P.Parent := FForm;
  P.Text := 'geheim';
  CheckFalse(P.Revealed, 'Vorgabe: verborgen');
  CheckTrue(P.PasswordChar <> #0, 'Maskenzeichen gesetzt');
  P.Revealed := True;
  CheckTrue(P.Revealed);
  CheckEquals('geheim', P.Text, 'Text bleibt beim Aufdecken');
  P.Revealed := False;
  CheckEquals('geheim', P.Text, 'Text bleibt beim Verbergen');
end;

procedure TAudit11CBehaviourTests.FileEditKeepsFileName;
var
  F: TPPGFileEdit;
begin
  F := TPPGFileEdit.Create(FForm);
  F.Parent := FForm;
  F.FileName := 'C:\Daten\Bericht.docx';
  CheckEquals('C:\Daten\Bericht.docx', F.FileName);
  CheckEquals('C:\Daten\Bericht.docx', F.Text, 'angezeigt wird der Pfad');
  F.FileName := '';
  CheckEquals('', F.Text, 'leer');
end;

procedure TAudit11CBehaviourTests.CheckComboCheckedTextIgnoresUnknownItems;
var
  C: TPPGCheckComboBox;
begin
  C := TPPGCheckComboBox.Create(FForm);
  C.Parent := FForm;
  C.Items.CommaText := 'Rot,Gruen,Blau';
  C.CheckedText := 'Blau;Lila;Rot';
  CheckTrue(C.Checked[0], 'Rot');
  CheckFalse(C.Checked[1], 'Gruen');
  CheckTrue(C.Checked[2], 'Blau');
  CheckEquals('Rot;Blau', C.CheckedText, 'Reihenfolge der Liste, unbekannte Eintraege entfallen');
  C.ToggleItem(1);
  CheckEquals('Rot;Gruen;Blau', C.CheckedText);
end;

procedure TAudit11CBehaviourTests.ColumnComboShowsDisplayColumn;
var
  C: TPPGColumnComboBox;
begin
  C := TPPGColumnComboBox.Create(FForm);
  C.Parent := FForm;
  C.Columns.Add.Title := 'Nr';
  C.Columns.Add.Title := 'Name';
  C.Items.Add('1001|Albers');
  C.Items.Add('1002|Mueller');
  C.DisplayColumn := 1;
  C.ItemIndex := 1;
  CheckEquals('Mueller', C.DisplayText, 'Anzeige aus der Anzeigespalte');
  CheckEquals('1002', C.KeyValue, 'Schluessel aus der Schluesselspalte');
  C.DisplayColumn := 0;
  CheckEquals('1002', C.DisplayText, 'andere Anzeigespalte');
  C.ItemIndex := -1;
  CheckEquals('', C.DisplayText, 'nichts gewaehlt');
  CheckEquals('', C.KeyValue);
end;

procedure TAudit11CBehaviourTests.DBNumberEditFollowsRecord;
var
  N: TPPGDBNumberEdit;
begin
  NeedData;
  N := TPPGDBNumberEdit.Create(FForm);
  N.Parent := FForm;
  N.DataField := 'Wert';
  N.DataSource := FSource;
  FData.First;
  CheckEquals(12.5, N.Value, 0, 'erster Datensatz');
  FData.Next;
  CheckEquals(7, N.Value, 0, 'zweiter Datensatz');
  FData.Edit;
  FData.FieldByName('Wert').AsFloat := 99.25;
  CheckEquals(99.25, N.Value, 0, 'Aenderung am Feld sofort sichtbar');
  FData.Cancel;
  CheckEquals(7, N.Value, 0, 'Abbrechen stellt den Wert wieder her');
end;

procedure TAudit11CBehaviourTests.DBLookupShowsListTextOfKey;
var
  L: TPPGDBLookupComboBox;
begin
  NeedData;
  L := TPPGDBLookupComboBox.Create(FForm);
  L.Parent := FForm;
  L.ListSource := FOrtSrc;
  L.KeyField := 'ID';
  L.ListField := 'Ort';
  L.DataField := 'OrtID';
  L.DataSource := FSource;
  FData.First;
  CheckEquals('Koeln', L.Text, 'OrtID 2 = Koeln');
  CheckEquals(2, Integer(L.KeyValue));
  FData.Next;
  CheckEquals('Hamburg', L.Text, 'OrtID 1 = Hamburg');
  // Neuer Eintrag in der Liste wird angeboten
  FOrte.AppendRecord([3, 'Bremen']);
  CheckEquals(3, L.KeyCount, 'Liste folgt der Datenmenge');
  CheckEquals(2, L.IndexOfKey(3), 'Bremen an dritter Stelle');
end;

procedure TAudit11CBehaviourTests.PlannerPrintOnePagePerWeek;
var
  P: TPPGPlanner;
  Prn: TPPGPlannerPrinter;
  Dev: TPPGPrintDevice;
  B: TBitmap;
begin
  P := TPPGPlanner.Create(FForm);
  P.Parent := FForm;
  P.FirstDayOfWeek := fdMonday;
  P.TimeZoneMode := tzmLocal;
  P.Date := Monday;
  P.Appointments.AddAppointment(DT(1, 9, 0), DT(1, 10, 0), 'Termin');
  Prn := TPPGPlannerPrinter.Create(FForm);
  Prn.Planner := P;
  Prn.View := pvWeek;
  Prn.PrintFrom := Monday;
  Prn.PrintTo := Monday + 20; // drei Kalenderwochen
  Dev := TPPGPrintDevice.A4(96, True);
  CheckEquals(3, Prn.PageCount(Dev), 'Wochenansicht: eine Seite je Woche');
  CheckEquals(Monday + 7, Prn.PageStart(1), 0, 'zweite Seite beginnt am naechsten Montag');
  B := TBitmap.Create;
  try
    B.PixelFormat := pf24bit;
    B.SetSize(Dev.PageWidth, Dev.PageHeight);
    B.Canvas.Brush.Color := clWhite;
    B.Canvas.FillRect(Rect(0, 0, B.Width, B.Height));
    Prn.RenderPage(0, B.Canvas.Handle, Dev);
    PPGCheckPainted(Self, B, 'Planer-Druckseite');
  finally
    B.Free;
  end;
end;

procedure TAudit11CBehaviourTests.KanbanPrintPagesAndContent;
var
  K: TPPGKanban;
  Prn: TPPGKanbanPrinter;
  Dev: TPPGPrintDevice;
  B1, B2: TBitmap;
  I, Few: Integer;
begin
  K := TPPGKanban.Create(FForm);
  K.Parent := FForm;
  K.SetBounds(0, 0, 600, 400);
  K.Columns.AddColumn('Offen');
  K.Columns.AddColumn('Fertig');
  for I := 1 to 3 do
    K.Cards.AddCard(K.Columns[0].Id, 'Karte ' + IntToStr(I));
  Prn := TPPGKanbanPrinter.Create(FForm);
  Prn.Kanban := K;
  Dev := TPPGPrintDevice.A4(96, False);
  Few := Prn.PageCount(Dev);
  CheckEquals(1, Few, 'drei Karten passen auf eine Seite');
  for I := 4 to 150 do
    K.Cards.AddCard(K.Columns[0].Id, 'Karte ' + IntToStr(I));
  CheckTrue(Prn.PageCount(Dev) >= 2, '150 Karten in einer Spalte brauchen mehrere Seiten');
  B1 := TBitmap.Create;
  B2 := TBitmap.Create;
  try
    B1.PixelFormat := pf24bit;
    B1.SetSize(Dev.PageWidth, Dev.PageHeight);
    B1.Canvas.Brush.Color := clWhite;
    B1.Canvas.FillRect(Rect(0, 0, B1.Width, B1.Height));
    B2.Assign(B1);
    Prn.RenderPage(0, B1.Canvas.Handle, Dev);
    Prn.RenderPage(1, B2.Canvas.Handle, Dev);
    PPGCheckPainted(Self, B1, 'Kanban Seite 1');
    PPGCheckPainted(Self, B2, 'Kanban Seite 2');
    PPGCheckDiffers(Self, B1, B2, 'Seite 2 zeigt andere Karten');
  finally
    B1.Free;
    B2.Free;
  end;
end;

procedure TAudit11CBehaviourTests.NavItemsDialogMovesAndIndents;
var
  Nav: TPPGNavigationView;
  D: TPPGNavItemsDialog;
begin
  Nav := TPPGNavigationView.Create(FForm);
  Nav.Parent := FForm;
  Nav.Items.AddItem('A');
  Nav.Items.AddItem('B');
  Nav.Items.AddItem('C');
  D := TPPGNavItemsDialog.CreateFor(nil, Nav);
  try
    D.SelectItem(D.View.Items[1]);
    CheckTrue(ClickEditorButton(D, 'Up'), 'Button "Up"');
    CheckEquals('B', D.View.Items[0].Caption, 'B nach oben');
    CheckEquals('A', D.View.Items[1].Caption);
    D.SelectItem(D.View.Items[2]);
    CheckTrue(ClickEditorButton(D, 'Indent'), 'Button "Indent"');
    CheckEquals(2, D.View.Items.Count, 'C ist jetzt Kind');
    CheckEquals('C', D.View.Items[1].Items[0].Caption, 'Kind des vorigen Eintrags A');
    CheckTrue(ClickEditorButton(D, 'Outdent'), 'Button "Outdent"');
    CheckEquals(3, D.View.Items.Count, 'wieder oberste Ebene');
    CheckEquals('C', D.View.Items[2].Caption);
    CheckTrue(ClickEditorButton(D, 'Delete'), 'Button "Delete"');
    CheckEquals(2, D.View.Items.Count, 'geloescht');
    CheckEquals(3, Nav.Items.Count, 'Ziel unveraendert (Dialog arbeitet auf einer Kopie)');
  finally
    D.Free;
  end;
end;

procedure TAudit11CBehaviourTests.TreeItemsDialogDeletesAndIndents;
var
  T: TPPGTreeView;
  D: TPPGTreeItemsDialog;
begin
  T := TPPGTreeView.Create(FForm);
  T.Parent := FForm;
  T.Items.Add(nil, 'Eins');
  T.Items.Add(nil, 'Zwei');
  D := TPPGTreeItemsDialog.CreateFor(nil, T);
  try
    CheckEquals(2, D.Tree.Items.Count);
    D.Tree.Selected := D.Tree.Items[1];
    CheckTrue(ClickEditorButton(D, 'Indent'), 'Button "Indent"');
    CheckEquals(1, D.Tree.Items[1].Level, 'Zwei ist Kind von Eins');
    CheckTrue(D.Tree.Items[1].Parent = D.Tree.Items[0]);
    D.Tree.Selected := D.Tree.Items[1];
    CheckTrue(ClickEditorButton(D, 'Delete'), 'Button "Delete"');
    CheckEquals(1, D.Tree.Items.Count, 'geloescht');
    CheckEquals(2, T.Items.Count, 'Ziel unveraendert');
  finally
    D.Free;
  end;
end;

procedure TAudit11CBehaviourTests.LoadICalFileWithAndWithoutBom;
const
  Ics = 'BEGIN:VCALENDAR'#13#10'VERSION:2.0'#13#10'BEGIN:VEVENT'#13#10 +
    'UID:a1@test'#13#10'DTSTART:20260602T090000'#13#10'DTEND:20260602T100000'#13#10 +
    'SUMMARY:Besprechung M'#$00FC'ller'#13#10'END:VEVENT'#13#10'END:VCALENDAR'#13#10;
var
  Items: TPPGAppointments;
  F: string;
  Bytes, Bom: TBytes;
  S: TFileStream;
  WithBom: Boolean;
begin
  F := TPath.Combine(TPath.GetTempPath, 'ppg-audit11c.ics');
  Bytes := TEncoding.UTF8.GetBytes(Ics);
  Bom := TEncoding.UTF8.GetPreamble;
  for WithBom := False to True do
  begin
    S := TFileStream.Create(F, fmCreate);
    try
      if WithBom then
        S.WriteBuffer(Bom[0], Length(Bom));
      S.WriteBuffer(Bytes[0], Length(Bytes));
    finally
      S.Free;
    end;
    Items := TPPGAppointments.Create(nil);
    try
      CheckEquals(1, PPGLoadICal(Items, F), 'ein Termin');
      CheckEquals('Besprechung M'#$00FC'ller', Items[0].Subject,
        'Umlaut aus UTF-8, BOM = ' + IntToStr(Ord(WithBom)));
      CheckEquals(EncodeDate(2026, 6, 2) + EncodeTime(9, 0, 0, 0), Items[0].Start, 1 / 86400,
        'Beginn');
    finally
      Items.Free;
      System.SysUtils.DeleteFile(F);
    end;
  end;
end;

procedure TAudit11CBehaviourTests.TokenColorCoversAllKinds;
const
  // Jede Art liefert genau ihr Feld (Literal je Feld)
  Expected: array[TPPGTokenColor] of TColor = ($010101, $020202, $030303, $040404,
    $050505, $060606, $070707, $080808, $090909, $0A0A0A, $0B0B0B, $0C0C0C, $0D0D0D,
    $0E0E0E, $0F0F0F, $101010, $111111, $121212, $131313, $141414, $151515);
var
  T: TPPGTokens;
  K: TPPGTokenColor;
begin
  T := PPGDefaultTokens(False);
  T.Accent := $010101;
  T.AccentHover := $020202;
  T.AccentPressed := $030303;
  T.OnAccent := $040404;
  T.Background := $050505;
  T.Layer := $060606;
  T.Surface := $070707;
  T.SurfaceHover := $080808;
  T.SurfacePressed := $090909;
  T.SurfaceDisabled := $0A0A0A;
  T.Stroke := $0B0B0B;
  T.StrokeStrong := $0C0C0C;
  T.StrokeDisabled := $0D0D0D;
  T.TextPrimary := $0E0E0E;
  T.TextSecondary := $0F0F0F;
  T.TextDisabled := $101010;
  T.Danger := $111111;
  T.Warning := $121212;
  T.Success := $131313;
  T.Paused := $141414;
  T.Link := $151515;
  for K := Low(TPPGTokenColor) to High(TPPGTokenColor) do
    CheckEquals(Integer(Expected[K]), Integer(PPGGetTokenColor(T, K)),
      'Art ' + IntToStr(Ord(K)));
end;

initialization
  RegisterTest('Audit11C', TAudit11CGdiTests.Suite);
  RegisterTest('Audit11C', TAudit11CBehaviourTests.Suite);

end.
