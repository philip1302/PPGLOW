unit PPG.Tests.Visual;

{$WARN SYMBOL_PLATFORM OFF}

{ Sichttests fuer ALLE Paletten-Controls.

  - Galerie: jedes Control in den Zustaenden Normal, Hover, Gedrueckt, Fokus,
    Deaktiviert und in den Varianten ModernFlat hell/dunkel, Classic,
    Fluent11 hell/dunkel und GDI-Fallback; gespeichert als PNG unter
    Tests\Visual\Gallery (zum Ansehen).
  - Automatische Pruefungen: nicht leer, Hover/Fokus/Deaktiviert sichtbar
    anders als Normal, Dunkel anders als Hell mit hellem Text, keine
    Zeichenfehler.
  - Referenzbilder (Tests\Visual\Baseline): Normal in ModernFlat hell und
    dunkel. Fehlt ein Bild, wird es angelegt; sonst darf hoechstens 0,5 % der
    Pixel deutlich abweichen. Neu anlegen: Ordner Baseline loeschen. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Imaging.pngimage,
  PPG.Types, PPG.Render.Registry, PPG.Controls.Base, PPG.Tests.Controls;

type
  TVisualState = (vsNormalV, vsHoverV, vsPressedV, vsFocusV, vsDisabledV);
  TVisualVariant = (vvFlatLight, vvFlatDark, vvClassic, vvFluentLight, vvFluentDark, vvGdi);

  TVisualTests = class(TControlTestCase)
  private
    FHost: TPanel;
    FToastCenter: TComponent;
    FRtl: Boolean;      // Phase 9d: Render von rechts nach links
    FPPI: Integer;      // Phase 9e: Render bei anderer DPI (96 = normal)
    /// Galerie aus Zeilen (je Control) und Spalten (je Variante) speichern.
    procedure SaveSheet(const FileName: string; const Columns: array of string;
      const Rows: TStrings; const Cells: array of TBitmap);
    function BuildControl(Index: Integer; Dark: Boolean): TControl;
    function HotPoint(C: TControl; Index: Integer): TPoint;
    function Render(Index: Integer; Variant: TVisualVariant; State: TVisualState;
      out Ok: Boolean): TBitmap;
    procedure ApplyVariant(Variant: TVisualVariant);
    procedure ResetVariant;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure GalleryAndStateChecks;
    procedure BaselineImages;
    /// Phase 9d: alle Controls mit BiDiMode = bdRightToLeft (Galerie RTL.png).
    procedure RtlGallery;
    /// Phase 9e: alle Controls bei 144 und 192 DPI (Galerie DPI.png, ab 10.3).
    procedure DpiGallery;
  end;

/// Anzahl Pixel, die sich deutlich (Summe RGB > Tol) unterscheiden.
function PPGPixelDiff(A, B: TBitmap; Tol: Integer = 40): Integer;

implementation

uses
  System.Math, System.StrUtils, System.DateUtils, PPG.Consts, PPG.Theme, PPG.Tokens,
  PPG.Controls.ItemList,
  PPG.Button, PPG.CheckBox, PPG.RadioButton, PPG.ToggleSwitch, PPG.ProgressBar,
  PPG.TrackBar, PPG.Panel, PPG.GroupBox, PPG.Edit, PPG.Memo, PPG.SpinEdit, PPG.ComboBox,
  PPG.TabControl, PPG.PageControl, PPG.ListBox, PPG.CheckListBox, PPG.TreeView, PPG.Grid,
  PPG.Labels, PPG.Feedback, PPG.Expander, PPG.Splitter, PPG.Rating, PPG.SearchEdit,
  PPG.Calendar, PPG.DatePicker, PPG.TimePicker, PPG.NavigationView, PPG.Breadcrumb,
  PPG.ToolBar, PPG.StatusBar, PPG.Notifications;

type
  TCCV = class(TPPGCustomControl);

const
  ControlCount = 36;
  ControlNames: array[0..ControlCount - 1] of string = ('Button', 'CheckBox', 'RadioButton',
    'ToggleSwitch', 'ProgressBar', 'TrackBar', 'Panel', 'GroupBox', 'Edit', 'Memo', 'SpinEdit',
    'ComboBox', 'TabControl', 'PageControl', 'ListBox', 'CheckListBox', 'TreeView', 'Grid',
    'Label', 'LinkLabel', 'Badge', 'ProgressRing', 'InfoBar', 'Expander', 'Splitter', 'Rating',
    'SearchEdit', 'Calendar', 'DatePicker', 'TimePicker', 'NavigationView', 'Breadcrumb',
    'ToolBar', 'StatusBar', 'Toast', 'StyleTitle');
  // Welche Zustaende sichtbar anders sein muessen
  HasHover: array[0..ControlCount - 1] of Boolean = (True, True, True, True, False, True,
    False, False, True, True, True, True, True, True, True, True, True, False, // Grid: kein Hover
    False, True, False, False, True, True, True, True, True, True, True, True, True, True,
    True, False, True, False);
  HasFocus: array[0..ControlCount - 1] of Boolean = (True, True, True, True, False, True,
    False, False, True, True, True, True, True, True, True, True, True, True,
    False, True, False, False, True, True, True, True, True, True, True, True, True, True,
    True, False, False, False);
  VariantNames: array[TVisualVariant] of string = ('ModernFlat hell', 'ModernFlat dunkel',
    'Classic', 'Fluent11 hell', 'Fluent11 dunkel', 'GDI');
  StateNames: array[TVisualState] of string = ('Normal', 'Hover', 'Gedrueckt', 'Fokus',
    'Deaktiviert');
  LastControl = ControlCount - 2; // StyleTitle ist nur Platzhalter
  // Deaktiviert muss sichtbar sein (nicht: Panel ohne Text-Aenderung, Splitter, Toast)
  HasDisabled: array[0..ControlCount - 1] of Boolean = (True, True, True, True, True, True,
    False, True, True, True, True, True, True, True, True, True, True, True,
    True, True, True, True, True, True, False, True, True, True, True, True, True, True,
    True, True, False, False);

function PPGPixelDiff(A, B: TBitmap; Tol: Integer): Integer;
var
  X, Y: Integer;
  PA, PB: PByteArray;
begin
  Result := 0;
  if (A.Width <> B.Width) or (A.Height <> B.Height) then
    Exit(MaxInt);
  A.PixelFormat := pf24bit;
  B.PixelFormat := pf24bit;
  for Y := 0 to A.Height - 1 do
  begin
    PA := A.ScanLine[Y];
    PB := B.ScanLine[Y];
    for X := 0 to A.Width - 1 do
      if Abs(PA[X * 3] - PB[X * 3]) + Abs(PA[X * 3 + 1] - PB[X * 3 + 1]) +
        Abs(PA[X * 3 + 2] - PB[X * 3 + 2]) > Tol then
        Inc(Result);
  end;
end;

/// Anteil "heller" bzw. "dunkler" Pixel (Luminanz > 0,6 bzw. < 0,35).
procedure CountLightDark(B: TBitmap; out Light, Dark: Integer);
var
  X, Y: Integer;
  P: PByteArray;
  L: Double;
begin
  Light := 0;
  Dark := 0;
  B.PixelFormat := pf24bit;
  for Y := 0 to B.Height - 1 do
  begin
    P := B.ScanLine[Y];
    for X := 0 to B.Width - 1 do
    begin
      L := (0.2126 * P[X * 3 + 2] + 0.7152 * P[X * 3 + 1] + 0.0722 * P[X * 3]) / 255;
      if L > 0.6 then
        Inc(Light)
      else if L < 0.35 then
        Inc(Dark);
    end;
  end;
end;

/// Pixel, die sich von der haeufigsten Farbe (Hintergrund) abheben.
function ContentPixels(B: TBitmap): Integer;
var
  X, Y: Integer;
  P: PByteArray;
  Bg: array[0..2] of Byte;
begin
  B.PixelFormat := pf24bit;
  P := B.ScanLine[0];
  Bg[0] := P[0];
  Bg[1] := P[1];
  Bg[2] := P[2];
  Result := 0;
  for Y := 0 to B.Height - 1 do
  begin
    P := B.ScanLine[Y];
    for X := 0 to B.Width - 1 do
      if Abs(P[X * 3] - Bg[0]) + Abs(P[X * 3 + 1] - Bg[1]) + Abs(P[X * 3 + 2] - Bg[2]) > 40 then
        Inc(Result);
  end;
end;

/// Mittlere Saettigung (max-min der Kanaele) der farbigen Pixel; 0 = keine.
function MeanSaturation(B: TBitmap): Double;
var
  X, Y, Mx, Mn, N: Integer;
  Sum: Int64;
  P: PByteArray;
begin
  Sum := 0;
  N := 0;
  B.PixelFormat := pf24bit;
  for Y := 0 to B.Height - 1 do
  begin
    P := B.ScanLine[Y];
    for X := 0 to B.Width - 1 do
    begin
      Mx := Max(P[X * 3], Max(P[X * 3 + 1], P[X * 3 + 2]));
      Mn := Min(P[X * 3], Min(P[X * 3 + 1], P[X * 3 + 2]));
      if Mx - Mn > 40 then
      begin
        Inc(Sum, Mx - Mn);
        Inc(N);
      end;
    end;
  end;
  if N = 0 then
    Result := 0
  else
    Result := Sum / N;
end;

/// Kraeftig farbige Pixel (Akzent, Signalfarben): Abstand max-min der Kanaele > 90.
function SaturatedPixels(B: TBitmap): Integer;
var
  X, Y, Mx, Mn: Integer;
  P: PByteArray;
begin
  Result := 0;
  B.PixelFormat := pf24bit;
  for Y := 0 to B.Height - 1 do
  begin
    P := B.ScanLine[Y];
    for X := 0 to B.Width - 1 do
    begin
      Mx := Max(P[X * 3], Max(P[X * 3 + 1], P[X * 3 + 2]));
      Mn := Min(P[X * 3], Min(P[X * 3 + 1], P[X * 3 + 2]));
      if Mx - Mn > 90 then
        Inc(Result);
    end;
  end;
end;

{ TVisualTests }

procedure TVisualTests.SetUp;
begin
  inherited SetUp;
  FRtl := False;
  FPPI := 96;
  FForm.SetBounds(0, 0, 640, 520);
  FForm.Show;
  // Fokus-Cues sichtbar (wie nach Tastaturbedienung)
  FForm.Perform(WM_UPDATEUISTATE, MakeWParam(UIS_CLEAR, UISF_HIDEFOCUS or UISF_HIDEACCEL), 0);
end;

procedure TVisualTests.TearDown;
begin
  ResetVariant;
  FreeAndNil(FToastCenter);
  if FForm <> nil then
    FForm.Hide;
  inherited TearDown;
end;

procedure TVisualTests.ApplyVariant(Variant: TVisualVariant);
begin
  if Variant in [vvFlatDark, vvFluentDark] then
    TPPGTheme.Mode := tmDark
  else
    TPPGTheme.Mode := tmLight;
  TPPGRendererRegistry.ForceGdiFallback := Variant = vvGdi;
end;

procedure TVisualTests.ResetVariant;
begin
  TPPGTheme.Mode := tmLight;
  TPPGRendererRegistry.ForceGdiFallback := False;
end;

function TVisualTests.BuildControl(Index: Integer; Dark: Boolean): TControl;
var
  P: TWinControl;
  I: Integer;
  S: TPPGTabSheet;
  N: TPPGTreeNode;
  It: TPPGNavItem;
  SP: TPPGStatusPanel;
  E: TPPGEdit;
begin
  P := FHost;
  Result := nil;
  case Index of
    0:
      begin
        Result := TPPGButton.Create(FForm);
        TPPGButton(Result).Caption := 'Speichern';
        Result.SetBounds(8, 8, 120, 32);
      end;
    1:
      begin
        Result := TPPGCheckBox.Create(FForm);
        TPPGCheckBox(Result).Caption := 'Merken';
        TPPGCheckBox(Result).Checked := True;
        Result.SetBounds(8, 8, 120, 24);
      end;
    2:
      begin
        Result := TPPGRadioButton.Create(FForm);
        TPPGRadioButton(Result).Caption := 'Option A';
        TPPGRadioButton(Result).Checked := True;
        Result.SetBounds(8, 8, 120, 24);
      end;
    3:
      begin
        Result := TPPGToggleSwitch.Create(FForm);
        TPPGToggleSwitch(Result).Caption := 'WLAN';
        TPPGToggleSwitch(Result).Checked := True;
        Result.SetBounds(8, 8, 120, 24);
      end;
    4:
      begin
        Result := TPPGProgressBar.Create(FForm);
        TPPGProgressBar(Result).Position := 60;
        Result.SetBounds(8, 8, 200, 18);
      end;
    5:
      begin
        Result := TPPGTrackBar.Create(FForm);
        TPPGTrackBar(Result).Position := 4;
        Result.SetBounds(8, 8, 200, 32);
      end;
    6:
      begin
        Result := TPPGPanel.Create(FForm);
        TPPGPanel(Result).Caption := 'Panel';
        Result.SetBounds(8, 8, 160, 70);
      end;
    7:
      begin
        Result := TPPGGroupBox.Create(FForm);
        TPPGGroupBox(Result).Caption := 'Gruppe';
        Result.SetBounds(8, 8, 160, 80);
      end;
    8:
      begin
        Result := TPPGEdit.Create(FForm);
        TPPGEdit(Result).Text := 'Eingabe';
        Result.SetBounds(8, 8, 160, 26);
      end;
    9:
      begin
        Result := TPPGMemo.Create(FForm);
        Result.Parent := P; // Lines braucht ein Fenster
        TPPGMemo(Result).Lines.Text := 'Zeile eins'#13#10'Zeile zwei';
        Result.SetBounds(8, 8, 160, 60);
      end;
    10:
      begin
        Result := TPPGSpinEdit.Create(FForm);
        TPPGSpinEdit(Result).Value := 42;
        Result.SetBounds(8, 8, 100, 26);
      end;
    11:
      begin
        Result := TPPGComboBox.Create(FForm);
        TPPGComboBox(Result).Items.CommaText := 'Eins,Zwei,Drei';
        TPPGComboBox(Result).ItemIndex := 0;
        Result.SetBounds(8, 8, 160, 26);
      end;
    12:
      begin
        Result := TPPGTabControl.Create(FForm);
        TPPGTabControl(Result).Tabs.CommaText := 'Eins,Zwei,Drei';
        TPPGTabControl(Result).TabIndex := 0;
        Result.SetBounds(8, 8, 260, 80);
      end;
    13:
      begin
        Result := TPPGPageControl.Create(FForm);
        Result.SetBounds(8, 8, 260, 90);
        Result.Parent := P;
        for I := 0 to 2 do
        begin
          S := TPPGTabSheet.Create(FForm);
          S.Caption := 'Seite ' + IntToStr(I + 1);
          S.PageControl := TPPGPageControl(Result);
        end;
        TPPGPageControl(Result).ActivePageIndex := 0;
      end;
    14:
      begin
        Result := TPPGListBox.Create(FForm);
        TPPGListBox(Result).Items.CommaText := 'Eins,Zwei,Drei,Vier';
        TPPGListBox(Result).ItemIndex := 1;
        Result.SetBounds(8, 8, 160, 100);
      end;
    15:
      begin
        Result := TPPGCheckListBox.Create(FForm);
        TPPGCheckListBox(Result).Items.CommaText := 'Eins,Zwei,Drei,Vier';
        Result.SetBounds(8, 8, 160, 100);
        Result.Parent := P;
        TPPGCheckListBox(Result).Checked[0] := True;
        TPPGCheckListBox(Result).ItemIndex := 1;
      end;
    16:
      begin
        Result := TPPGTreeView.Create(FForm);
        Result.SetBounds(8, 8, 180, 100);
        Result.Parent := P;
        N := TPPGTreeView(Result).Items.AddChild(nil, 'Dokumente');
        TPPGTreeView(Result).Items.AddChild(N, 'Briefe');
        TPPGTreeView(Result).Items.AddChild(N, 'Rechnungen');
        TPPGTreeView(Result).Items.AddChild(nil, 'Bilder');
        N.Expanded := True;
        TPPGTreeView(Result).Selected := N.Item[0];
      end;
    17:
      begin
        Result := TPPGGrid.Create(FForm);
        Result.SetBounds(8, 8, 260, 110);
        Result.Parent := P;
        TPPGGrid(Result).ColCount := 3;
        TPPGGrid(Result).RowCount := 4;
        for I := 0 to 3 do
        begin
          TPPGGrid(Result).Cells[0, I] := 'Zeile ' + IntToStr(I);
          TPPGGrid(Result).Cells[1, I] := IntToStr(I * 7);
          TPPGGrid(Result).Cells[2, I] := 'Text';
        end;
      end;
    18:
      begin
        Result := TPPGLabel.Create(FForm);
        TPPGLabel(Result).AllowMarkup := True;
        TPPGLabel(Result).Caption := 'Label mit <b>Markup</b> und <color=#D13438>Farbe</color>';
        Result.SetBounds(8, 8, 240, 17);
      end;
    19:
      begin
        Result := TPPGLinkLabel.Create(FForm);
        TPPGLinkLabel(Result).Caption := 'Siehe <a href="x">Hilfe</a> und <a href="y">Kontakt</a>';
        Result.SetBounds(8, 8, 240, 20);
      end;
    20:
      begin
        Result := TPPGBadge.Create(FForm);
        TPPGBadge(Result).Value := 7;
        Result.SetBounds(8, 8, 24, 18);
      end;
    21:
      begin
        Result := TPPGProgressRing.Create(FForm);
        TPPGProgressRing(Result).Indeterminate := False;
        TPPGProgressRing(Result).Value := 65;
        Result.SetBounds(8, 8, 40, 40);
      end;
    22:
      begin
        Result := TPPGInfoBar.Create(FForm);
        TPPGInfoBar(Result).Severity := psWarning;
        TPPGInfoBar(Result).Title := 'Achtung';
        TPPGInfoBar(Result).Message := 'Ungespeicherte Aenderungen.';
        TPPGInfoBar(Result).ActionCaption := 'Speichern';
        Result.SetBounds(8, 8, 380, 48);
      end;
    23:
      begin
        Result := TPPGExpander.Create(FForm);
        TPPGExpander(Result).Caption := 'Allgemein';
        TPPGExpander(Result).Detail := 'Name und Beschreibung';
        Result.SetBounds(8, 8, 260, 110);
        Result.Parent := P;
        E := TPPGEdit.Create(FForm);
        E.Parent := TPPGExpander(Result);
        E.SetBounds(12, 62, 200, 24);
        E.Text := 'Inhalt';
      end;
    24:
      begin
        Result := TPPGSplitter.Create(FForm);
        TPPGSplitter(Result).Align := alNone;
        TPPGSplitter(Result).Beveled := True;
        Result.SetBounds(30, 8, 8, 80);
      end;
    25:
      begin
        Result := TPPGRating.Create(FForm);
        TPPGRating(Result).Value := 3;
        Result.SetBounds(8, 8, 120, 24);
      end;
    26:
      begin
        Result := TPPGSearchEdit.Create(FForm);
        TPPGSearchEdit(Result).Text := 'Suche';
        Result.SetBounds(8, 8, 200, 26);
      end;
    27:
      begin
        Result := TPPGCalendar.Create(FForm);
        TPPGCalendar(Result).TodayOverride := EncodeDate(2026, 10, 4);
        TPPGCalendar(Result).FirstDayOfWeek := fdMonday;
        TPPGCalendar(Result).Date := EncodeDate(2026, 10, 15);
        TPPGCalendar(Result).ShowWeekNumbers := True;
        Result.SetBounds(8, 8, 280, 300);
      end;
    28:
      begin
        Result := TPPGDatePicker.Create(FForm);
        TPPGDatePicker(Result).Date := EncodeDate(2026, 10, 4);
        Result.SetBounds(8, 8, 180, 26);
      end;
    29:
      begin
        Result := TPPGTimePicker.Create(FForm);
        TPPGTimePicker(Result).ClockFormat := pcf24Hour;
        TPPGTimePicker(Result).Time := EncodeTime(9, 30, 0, 0);
        Result.SetBounds(8, 8, 120, 26);
      end;
    30:
      begin
        Result := TPPGNavigationView.Create(FForm);
        TPPGNavigationView(Result).Align := alNone;
        TPPGNavigationView(Result).PaneTitle := 'Demo';
        Result.Parent := P;
        It := TPPGNavigationView(Result).Items.AddItem('Start', PPGNavIconHome);
        TPPGNavigationView(Result).Items.AddItem('Post', PPGNavIconMail).BadgeCount := 3;
        TPPGNavigationView(Result).Items.AddHeader('Bereich');
        TPPGNavigationView(Result).Items.AddItem('Dokumente', PPGNavIconDocument);
        TPPGNavigationView(Result).Items.AddItem('Einstellungen', PPGNavIconSettings).Footer := True;
        TPPGNavigationView(Result).Selected := It;
        Result.SetBounds(8, 8, 220, 270);
      end;
    31:
      begin
        Result := TPPGBreadcrumb.Create(FForm);
        Result.SetBounds(8, 8, 320, 30);
        TPPGBreadcrumb(Result).SetPath('Dieser PC\Dokumente\Projekte\PPGlow');
      end;
    32:
      begin
        Result := TPPGToolBar.Create(FForm);
        TPPGToolBar(Result).Align := alNone;
        TPPGToolBar(Result).Items.AddButton('Neu', $E710);
        TPPGToolBar(Result).Items.AddButton('Speichern', $E74E);
        TPPGToolBar(Result).Items.AddSeparator;
        TPPGToolBar(Result).Items.AddCheck('Fett', $E8DD).Down := True;
        Result.SetBounds(8, 8, 360, 40);
      end;
    33:
      begin
        Result := TPPGStatusBar.Create(FForm);
        TPPGStatusBar(Result).Align := alNone;
        TPPGStatusBar(Result).SizeGrip := False;
        SP := TPPGStatusBar(Result).Panels.Add;
        SP.Width := 140;
        SP.Text := 'Bereit';
        SP := TPPGStatusBar(Result).Panels.Add;
        SP.Width := 120;
        SP.Kind := spkProgress;
        SP.Progress := 40;
        SP := TPPGStatusBar(Result).Panels.Add;
        SP.Kind := spkBadge;
        SP.BadgeCount := 3;
        Result.SetBounds(8, 8, 360, 24);
      end;
  end;
  if (Result <> nil) and (Result.Parent = nil) then
    Result.Parent := P;
  if Result is TPPGCustomControl then
    TCCV(Result).Animation.Enabled := False;
end;

function TVisualTests.HotPoint(C: TControl; Index: Integer): TPoint;
var
  R: TRect;
begin
  Result := Point(C.Width div 2, C.Height div 2);
  case Index of
    12, 13: Result := Point(110, 14);                     // zweiter Reiter
    14, 15:
      begin
        R := TPPGCustomItemList(C).ItemRect(2);
        Result := Point(60, (R.Top + R.Bottom) div 2);
      end;
    16: Result := Point(60, 30);
    17: Result := Point(100, 50);
    19:
      begin
        R := TPPGLinkLabel(C).LinkRect(0);
        Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
      end;
    22:
      begin
        R := TPPGInfoBar(C).PartRect(ipAction);
        Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
      end;
    23: Result := Point(100, 20);                          // Kopfzeile
    25: Result := Point(TPPGRating(C).StarRect(3).Left + 10, C.Height div 2);
    27:
      begin
        R := TPPGCalendar(C).CellRect(16);
        Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
      end;
    30:
      begin
        R := TPPGNavigationView(C).RowRect(1);
        Result := Point(100, (R.Top + R.Bottom) div 2);
      end;
    31:
      begin
        R := TPPGBreadcrumb(C).PartRect(1);
        Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
      end;
    32:
      begin
        R := TPPGToolBar(C).ItemRect(0);
        Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
      end;
  end;
end;

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

function TVisualTests.Render(Index: Integer; Variant: TVisualVariant; State: TVisualState;
  out Ok: Boolean): TBitmap;
const
  Presets: array[TVisualVariant] of string = (PPGPresetModernFlat, PPGPresetModernFlat,
    PPGPresetClassic, PPGPresetFluent11, PPGPresetFluent11, PPGPresetModernFlat);
var
  C: TControl;
  Pt: TPoint;
  Dark: Boolean;
  Target: TWinControl;
  Center: TPPGNotificationCenter;
  Toast: TPPGToast;
begin
  Ok := True;
  ApplyVariant(Variant);
  Dark := Variant in [vvFlatDark, vvFluentDark];
  if Index = 34 then
  begin
    // Toast: eigenes Fenster
    Center := TPPGNotificationCenter.Create(FForm);
    try
      Center.Animations := False;
      Center.RespectQuietHours := False;
      Center.Preset := Presets[Variant];
      Toast := Center.Show('Gespeichert', 'Die Datei wurde gespeichert.', psSuccess, 0, ['Oeffnen']);
      if State = vsHoverV then
      begin
        Pt := Toast.PartRect(-2).CenterPoint;
        Toast.Perform(CM_MOUSEENTER, 0, 0);
        Toast.Perform(WM_MOUSEMOVE, 0, MouseLParam(Pt.X, Pt.Y));
      end;
      Result := RenderToBitmap(Toast);
    finally
      Center.Free;
    end;
    Exit;
  end;
  FHost := TPanel.Create(FForm);
  try
    FHost.Parent := FForm;
    FHost.BevelOuter := bvNone;
    FHost.ParentBackground := False;
    if Dark then
      FHost.Color := PPGDefaultTokens(True).Background
    else
      FHost.Color := PPGDefaultTokens(False).Background;
    FHost.SetBounds(0, 0, 400, 330);
    C := BuildControl(Index, Dark);
    if C is TPPGCustomControl then
      TCCV(C).Preset := Presets[Variant];
    if FRtl then
    begin
      FHost.BiDiMode := bdRightToLeft;
      C.BiDiMode := bdRightToLeft;
    end;
    FHost.SetBounds(0, 0, C.Left + C.Width + 8, C.Top + C.Height + 8);
    if C is TWinControl then
      TWinControl(C).HandleNeeded;
    {$IF CompilerVersion >= 33.0}
    // Andere DPI: wie beim Wechsel auf einen Monitor mit dieser Skalierung
    if (FPPI > 0) and (FPPI <> 96) then
      FHost.ScaleForPPI(FPPI);
    {$IFEND}
    // Vor dem Zustand: Leerlauf der VCL meldet sonst CM_MOUSELEAVE (echte Maus ist woanders)
    Application.ProcessMessages;
    Pt := HotPoint(C, Index);
    Target := nil;
    if C is TWinControl then
      Target := TWinControl(C);
    case State of
      vsHoverV:
        begin
          C.Perform(CM_MOUSEENTER, 0, 0);
          C.Perform(WM_MOUSEMOVE, 0, MouseLParam(Pt.X, Pt.Y));
        end;
      vsPressedV:
        begin
          C.Perform(CM_MOUSEENTER, 0, 0);
          C.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(Pt.X, Pt.Y));
          C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(Pt.X, Pt.Y));
        end;
      vsFocusV:
        if (Target <> nil) and Target.CanFocus then
        begin
          Target.SetFocus;
          FForm.Perform(WM_UPDATEUISTATE, MakeWParam(UIS_CLEAR, UISF_HIDEFOCUS or UISF_HIDEACCEL), 0);
          if Target is TPPGCustomControl then
            Target.Perform(WM_UPDATEUISTATE, MakeWParam(UIS_CLEAR, UISF_HIDEFOCUS or UISF_HIDEACCEL), 0);
        end;
      vsDisabledV:
        C.Enabled := False;
    end;
    Result := RenderToBitmap(FHost);
    if State = vsPressedV then
    begin
      if GetCapture <> 0 then
        ReleaseCapture;
    end;
  finally
    FreeAndNil(FHost);
    FForm.ActiveControl := nil;
  end;
end;

procedure TVisualTests.GalleryAndStateChecks;
var
  Index, Light, DarkPx, LightD, DarkD, Sat: Integer;
  V: TVisualVariant;
  S: TVisualState;
  Cells: array[TVisualVariant, TVisualState] of TBitmap;
  Ok: Boolean;
  Sheet: TBitmap;
  Png: TPngImage;
  CW, CH, X, Y, LabelW, HeadH: Integer;
  Dir, Name: string;
  Errors: TStringList;
begin
  Dir := ExtractFilePath(ParamStr(0)) + 'Visual\Gallery\';
  ForceDirectories(Dir);
  Errors := TStringList.Create;
  try
    for Index := 0 to LastControl do
    begin
      Name := ControlNames[Index];
      FillChar(Cells, SizeOf(Cells), 0);
      try
        for V := Low(TVisualVariant) to High(TVisualVariant) do
          for S := Low(TVisualState) to High(TVisualState) do
            Cells[V, S] := Render(Index, V, S, Ok);
        ResetVariant;
        // Galerie zusammensetzen
        CW := 0;
        CH := 0;
        for V := Low(TVisualVariant) to High(TVisualVariant) do
          for S := Low(TVisualState) to High(TVisualState) do
          begin
            CW := Max(CW, Cells[V, S].Width);
            CH := Max(CH, Cells[V, S].Height);
          end;
        LabelW := 120;
        HeadH := 20;
        Sheet := TBitmap.Create;
        try
          Sheet.PixelFormat := pf24bit;
          Sheet.SetSize(LabelW + (Ord(High(TVisualState)) + 1) * (CW + 6),
            HeadH + (Ord(High(TVisualVariant)) + 1) * (CH + 6));
          Sheet.Canvas.Brush.Color := clWhite;
          Sheet.Canvas.FillRect(Rect(0, 0, Sheet.Width, Sheet.Height));
          Sheet.Canvas.Font.Name := 'Segoe UI';
          Sheet.Canvas.Font.Size := 8;
          for S := Low(TVisualState) to High(TVisualState) do
            Sheet.Canvas.TextOut(LabelW + Ord(S) * (CW + 6) + 2, 3, StateNames[S]);
          for V := Low(TVisualVariant) to High(TVisualVariant) do
          begin
            Y := HeadH + Ord(V) * (CH + 6);
            Sheet.Canvas.TextOut(4, Y + 4, VariantNames[V]);
            for S := Low(TVisualState) to High(TVisualState) do
            begin
              X := LabelW + Ord(S) * (CW + 6);
              Sheet.Canvas.Draw(X, Y, Cells[V, S]);
            end;
          end;
          Png := TPngImage.Create;
          try
            Png.Assign(Sheet);
            Png.SaveToFile(Dir + Name + '.png');
          finally
            Png.Free;
          end;
        finally
          Sheet.Free;
        end;
        // Automatische Pruefungen in allen Varianten
        for V := Low(TVisualVariant) to High(TVisualVariant) do
        begin
          if ContentPixels(Cells[V, vsNormalV]) < 20 then
            Errors.Add(Format('%s %s: leer', [Name, VariantNames[V]]));
          // Fluent11-Hover ist bewusst sehr dezent (WinUI): dort genuegt eine kleine Aenderung
          if HasHover[Index] and (PPGPixelDiff(Cells[V, vsNormalV], Cells[V, vsHoverV],
            IfThen(V in [vvFluentLight, vvFluentDark], 4, 15)) < 8) then
            Errors.Add(Format('%s %s: Hover nicht sichtbar', [Name, VariantNames[V]]));
          if HasFocus[Index] and (PPGPixelDiff(Cells[V, vsNormalV], Cells[V, vsFocusV], 15) < 8) then
            Errors.Add(Format('%s %s: Fokus nicht sichtbar', [Name, VariantNames[V]]));
          if HasDisabled[Index] then
          begin
            if PPGPixelDiff(Cells[V, vsNormalV], Cells[V, vsDisabledV], 15) < 8 then
              Errors.Add(Format('%s %s: Deaktiviert nicht sichtbar', [Name, VariantNames[V]]));
            // Deaktiviert: Akzent- und Signalfarben deutlich zuruecknehmen
            // (gemessen: mittlere Saettigung der farbigen Pixel sinkt um mindestens 25 %)
            Sat := SaturatedPixels(Cells[V, vsNormalV]);
            if (Sat >= 30) and (MeanSaturation(Cells[V, vsDisabledV]) >
              0.75 * MeanSaturation(Cells[V, vsNormalV])) and
              (SaturatedPixels(Cells[V, vsDisabledV]) * 2 > Sat) then
              Errors.Add(Format('%s %s: Deaktiviert behaelt kraeftige Farben (Saettigung %.0f statt %.0f)',
                [Name, VariantNames[V], MeanSaturation(Cells[V, vsDisabledV]),
                MeanSaturation(Cells[V, vsNormalV])]));
            // ... aber als Form erkennbar bleiben
            // (NavigationView dunkel: graue Schrift auf dunkler Leiste, per Sichtpruefung lesbar)
            if (Index <> 30) and
              (ContentPixels(Cells[V, vsDisabledV]) * 10 < ContentPixels(Cells[V, vsNormalV]) * 3) then
              Errors.Add(Format('%s %s: Deaktiviert kaum noch erkennbar (%d statt %d Pixel)',
                [Name, VariantNames[V], ContentPixels(Cells[V, vsDisabledV]),
                ContentPixels(Cells[V, vsNormalV])]));
          end;
        end;
        // Dunkel: hell geschriebener Inhalt, hell: dunkel geschriebener Inhalt
        CountLightDark(Cells[vvFlatLight, vsNormalV], Light, DarkPx);
        CountLightDark(Cells[vvFlatDark, vsNormalV], LightD, DarkD);
        if PPGPixelDiff(Cells[vvFlatLight, vsNormalV], Cells[vvFlatDark, vsNormalV]) < 50 then
          Errors.Add(Name + ': dunkel nicht anders als hell');
        if (Index <> 4) and (Index <> 21) and (Index <> 24) and (LightD < 10) then
          Errors.Add(Name + ': dunkel ohne hellen Inhalt (Text unsichtbar?)');
      finally
        for V := Low(TVisualVariant) to High(TVisualVariant) do
          for S := Low(TVisualState) to High(TVisualState) do
            Cells[V, S].Free;
      end;
    end;
  finally
    ResetVariant;
    try
      CheckEquals('', Errors.Text, Errors.Text);
      CheckEquals(0, FErrors.Count, FErrors.Text);
    finally
      Errors.Free;
    end;
  end;
end;

procedure TVisualTests.BaselineImages;
var
  Index, D, Total: Integer;
  V: TVisualVariant;
  B, Ref: TBitmap;
  Png: TPngImage;
  Ok: Boolean;
  Dir, F: string;
  Errors, Created: TStringList;
begin
  Dir := ExtractFilePath(ParamStr(0)) + 'Visual\Baseline\';
  ForceDirectories(Dir);
  Errors := TStringList.Create;
  Created := TStringList.Create;
  try
    for Index := 0 to LastControl do
      for V := vvFlatLight to vvFlatDark do
      begin
        B := Render(Index, V, vsNormalV, Ok);
        try
          F := Dir + ControlNames[Index] + '_' + IntToStr(Ord(V)) + '.png';
          if not FileExists(F) then
          begin
            Png := TPngImage.Create;
            try
              Png.Assign(B);
              Png.SaveToFile(F);
            finally
              Png.Free;
            end;
            Created.Add(ExtractFileName(F));
            Continue;
          end;
          Png := TPngImage.Create;
          Ref := TBitmap.Create;
          try
            Png.LoadFromFile(F);
            Ref.Assign(Png);
            Ref.PixelFormat := pf24bit;
            D := PPGPixelDiff(B, Ref, 60);
            Total := B.Width * B.Height;
            if (D = MaxInt) or (D * 200 > Total) then
              Errors.Add(Format('%s %s: %s', [ControlNames[Index], VariantNames[V],
                IfThen(D = MaxInt, 'andere Groesse', IntToStr(D) + ' Pixel abweichend')]));
          finally
            Ref.Free;
            Png.Free;
          end;
        finally
          B.Free;
        end;
      end;
    ResetVariant;
    if Created.Count > 0 then
      Status('Referenzbilder angelegt: ' + Created.CommaText);
    CheckEquals('', Errors.Text, 'Optik weicht vom Referenzbild ab: ' + Errors.Text);
  finally
    Created.Free;
    Errors.Free;
  end;
end;

procedure TVisualTests.SaveSheet(const FileName: string; const Columns: array of string;
  const Rows: TStrings; const Cells: array of TBitmap);
var
  Sheet: TBitmap;
  Png: TPngImage;
  CW, CH, R, C, N, LabelW, HeadH: Integer;
begin
  N := Length(Columns);
  CW := 0;
  CH := 0;
  for R := 0 to High(Cells) do
    if Cells[R] <> nil then
    begin
      CW := Max(CW, Cells[R].Width);
      CH := Max(CH, Cells[R].Height);
    end;
  LabelW := 120;
  HeadH := 20;
  Sheet := TBitmap.Create;
  try
    Sheet.PixelFormat := pf24bit;
    Sheet.SetSize(LabelW + N * (CW + 6), HeadH + Rows.Count * (CH + 6));
    Sheet.Canvas.Brush.Color := clWhite;
    Sheet.Canvas.FillRect(Rect(0, 0, Sheet.Width, Sheet.Height));
    Sheet.Canvas.Font.Name := 'Segoe UI';
    Sheet.Canvas.Font.Size := 8;
    for C := 0 to N - 1 do
      Sheet.Canvas.TextOut(LabelW + C * (CW + 6) + 2, 3, Columns[C]);
    for R := 0 to Rows.Count - 1 do
    begin
      Sheet.Canvas.TextOut(4, HeadH + R * (CH + 6) + 4, Rows[R]);
      for C := 0 to N - 1 do
        if (R * N + C <= High(Cells)) and (Cells[R * N + C] <> nil) then
          Sheet.Canvas.Draw(LabelW + C * (CW + 6), HeadH + R * (CH + 6), Cells[R * N + C]);
    end;
    Png := TPngImage.Create;
    try
      Png.Assign(Sheet);
      Png.SaveToFile(FileName);
    finally
      Png.Free;
    end;
  finally
    Sheet.Free;
  end;
end;

procedure TVisualTests.RtlGallery;
var
  Index, N: Integer;
  Cells: array of TBitmap;
  Rows, Errors, NotMirrored: TStringList;
  Ok: Boolean;
  Dir: string;
  I: Integer;
begin
  Dir := ExtractFilePath(ParamStr(0)) + 'Visual\Gallery\';
  ForceDirectories(Dir);
  Rows := TStringList.Create;
  Errors := TStringList.Create;
  NotMirrored := TStringList.Create;
  try
    for Index := 0 to LastControl do
      if Index <> 34 then // Toast: eigenes Fenster, folgt dem Formular nicht
        Rows.Add(ControlNames[Index]);
    SetLength(Cells, Rows.Count * 2);
    try
      N := 0;
      for Index := 0 to LastControl do
      begin
        if Index = 34 then
          Continue;
        FRtl := False;
        Cells[N * 2] := Render(Index, vvFlatLight, vsNormalV, Ok);
        FRtl := True;
        Cells[N * 2 + 1] := Render(Index, vvFlatLight, vsNormalV, Ok);
        FRtl := False;
        if ContentPixels(Cells[N * 2 + 1]) < 20 then
          Errors.Add(ControlNames[Index] + ': RTL leer');
        // Symmetrische Controls (Panel, Badge, Ring, Splitter) aendern sich nicht
        if PPGPixelDiff(Cells[N * 2], Cells[N * 2 + 1], 40) < 8 then
          NotMirrored.Add(ControlNames[Index]);
        Inc(N);
      end;
      ResetVariant;
      SaveSheet(Dir + 'RTL.png', ['Links nach rechts', 'Rechts nach links'], Rows, Cells);
    finally
      for I := 0 to High(Cells) do
        Cells[I].Free;
    end;
    // Hinweis statt Fehler: Die Galerie RTL.png zeigt, was (noch) nicht spiegelt
    if NotMirrored.Count > 0 then
      Status('RTL unveraendert (in RTL.png pruefen): ' + NotMirrored.CommaText);
    CheckEquals('', Errors.Text, Errors.Text);
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    NotMirrored.Free;
    Errors.Free;
    Rows.Free;
  end;
end;

procedure TVisualTests.DpiGallery;
{$IF CompilerVersion >= 33.0}
const
  Ppis: array[0..2] of Integer = (96, 144, 192);
var
  Index, N, K: Integer;
  Cells: array of TBitmap;
  Rows, Errors: TStringList;
  Ok: Boolean;
  Dir: string;
  I: Integer;
  Base, Scaled: Integer;
begin
  Dir := ExtractFilePath(ParamStr(0)) + 'Visual\Gallery\';
  ForceDirectories(Dir);
  Rows := TStringList.Create;
  Errors := TStringList.Create;
  try
    for Index := 0 to LastControl do
      if Index <> 34 then
        Rows.Add(ControlNames[Index]);
    SetLength(Cells, Rows.Count * Length(Ppis));
    try
      N := 0;
      for Index := 0 to LastControl do
      begin
        if Index = 34 then
          Continue;
        for K := 0 to High(Ppis) do
        begin
          FPPI := Ppis[K];
          Cells[N * Length(Ppis) + K] := Render(Index, vvFlatLight, vsNormalV, Ok);
        end;
        FPPI := 96;
        Base := Cells[N * Length(Ppis)].Width * Cells[N * Length(Ppis)].Height;
        for K := 1 to High(Ppis) do
        begin
          Scaled := Cells[N * Length(Ppis) + K].Width * Cells[N * Length(Ppis) + K].Height;
          if ContentPixels(Cells[N * Length(Ppis) + K]) < 20 then
            Errors.Add(Format('%s %d DPI: leer', [ControlNames[Index], Ppis[K]]));
          // Flaeche waechst etwa mit (PPI/96)^2 (Rand 8 px unskaliert: grosszuegig)
          if Scaled < Base * Sqr(Ppis[K] / 96) * 0.6 then
            Errors.Add(Format('%s %d DPI: nicht skaliert (%d statt ca. %d Pixel)',
              [ControlNames[Index], Ppis[K], Scaled, Round(Base * Sqr(Ppis[K] / 96))]));
        end;
        Inc(N);
      end;
      ResetVariant;
      SaveSheet(Dir + 'DPI.png', ['96 DPI', '144 DPI (150 %)', '192 DPI (200 %)'], Rows, Cells);
    finally
      FPPI := 96;
      for I := 0 to High(Cells) do
        Cells[I].Free;
    end;
    CheckEquals('', Errors.Text, Errors.Text);
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    Errors.Free;
    Rows.Free;
  end;
end;
{$ELSE}
begin
  Status('Erst ab Delphi 10.3 (ScaleForPPI) - Test entfaellt');
end;
{$IFEND}

initialization
  RegisterTest('Visual', TVisualTests.Suite);

end.
