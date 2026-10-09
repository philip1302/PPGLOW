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
    dunkel; hoechstens 0,5 % der Pixel duerfen deutlich abweichen. Ein
    fehlendes Bild ist ein Fehlschlag; angelegt wird nur mit /baseline.
  - Audit 11b: alle 84 Paletten-Controls (Indizes 42..77 neu, eigene Fenster
    ueber RenderWindow, DB-Controls an einem TClientDataSet). Referenzbilder
    der neuen Controls am 10.10.2026 mit /baseline angelegt und angesehen. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Imaging.pngimage, Data.DB, Datasnap.DBClient, MidasLib,
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
    // Audit 11b: Datenquelle fuer die DB-Controls, Ziel fuer TeachingTip
    FData, FOrte: TClientDataSet;
    FSource, FOrtSrc: TDataSource;
    FTipTarget: TControl;
    function BuildNewControl(Index: Integer; P: TWinControl): TControl;
    function RenderWindow(Index: Integer; Variant: TVisualVariant; State: TVisualState;
      const Preset: string): TBitmap;
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
    /// Audit 7e #7: alle Controls im simulierten Hochkontrast (Galerie
    /// HighContrast.png; Systemfarben des Testrechners).
    procedure HighContrastGallery;
  end;

/// Anzahl Pixel, die sich deutlich (Summe RGB > Tol) unterscheiden.
function PPGPixelDiff(A, B: TBitmap; Tol: Integer = 40): Integer;
/// Pixel, die sich deutlich von der Farbe links oben (Hintergrund) abheben;
/// 0 = leeres Bild.
function PPGContentPixels(B: TBitmap): Integer;
/// Audit 11b: Pruefungen fuer Zeichentests. Nicht leer: mindestens 20 Pixel
/// heben sich vom Hintergrund ab.
procedure PPGCheckPainted(Test: TTestCase; B: TBitmap; const What: string);
/// Zustand sichtbar: mindestens 8 Pixel weichen deutlich ab (wie die Galerie).
procedure PPGCheckDiffers(Test: TTestCase; A, B: TBitmap; const What: string);
/// Zeichnet C (PaintTo), prueft "nicht leer" und gibt das Bild frei.
procedure PPGPaintCheck(Test: TTestCase; C: TWinControl; const What: string);
/// Wie TControlTestCase.RenderToBitmap.
function PPGRender(C: TWinControl): TBitmap;
/// Zustaende sichtbar anders als Normal (je True): Hover ueber Pt, Fokus,
/// Deaktiviert; mit GDI+ und GDI-Rueckfall. C muss auf einem sichtbaren
/// Formular liegen; danach ist C wieder aktiv, ohne Hover.
procedure PPGCheckStates(Test: TTestCase; C: TWinControl; const What: string;
  Hover, Focus, Disabled: Boolean; const Pt: TPoint);

implementation

uses
  System.Math, System.StrUtils, System.DateUtils, System.TypInfo, PPG.Consts, PPG.Theme, PPG.Tokens, PPG.DpiUtils,
  PPG.Controls.ItemList,
  PPG.Button, PPG.CheckBox, PPG.RadioButton, PPG.ToggleSwitch, PPG.ProgressBar,
  PPG.TrackBar, PPG.Panel, PPG.GroupBox, PPG.RadioGroup, PPG.TileView, PPG.Edit, PPG.Memo, PPG.SpinEdit, PPG.ComboBox,
  PPG.TabControl, PPG.PageControl, PPG.ListBox, PPG.CheckListBox, PPG.TreeView, PPG.Grid,
  PPG.Labels, PPG.Feedback, PPG.Expander, PPG.Splitter, PPG.Rating, PPG.SearchEdit,
  PPG.Calendar, PPG.DatePicker, PPG.TimePicker, PPG.NavigationView, PPG.Breadcrumb,
  PPG.ToolBar, PPG.StatusBar, PPG.Notifications,
  PPG.Sparkline, PPG.Gauge, PPG.Chart, PPG.Chart.Series,
  Vcl.Menus, Vcl.DBCtrls, Vcl.Dialogs, System.Rtti, PPG.Planner.Model, PPG.Planner, PPG.Ribbon.Layout,
  PPG.Ribbon.Items, PPG.Ribbon, PPG.Kanban.Items, PPG.Kanban, PPG.Popup.Placement, PPG.Menus,
  PPG.MenuBar, PPG.Hints, PPG.TeachingTip, PPG.Dialogs, PPG.Wizard, PPG.BusyOverlay,
  PPG.NumberEdit, PPG.MaskEdit, PPG.PasswordEdit, PPG.FileEdit, PPG.ColorPicker,
  PPG.CheckComboBox, PPG.ColumnComboBox, PPG.TagEdit, PPG.DB.Controls, PPG.DB.Lookup,
  PPG.DB.Grid, PPG.DB.Chart, PPG.DB.Planner, PPG.DB.Kanban, PPG.DB.Fields, PPG.DB.Navigator;

type
  TCCV = class(TPPGCustomControl);

const
  ControlCount = 79;
  ToastIndex = 41; // eigenes Fenster (Sonderweg in Render und den RTL-/DPI-Galerien)
  // Audit 11b: ab hier die bisher fehlenden Paletten-Controls und die DB-Controls
  FirstNewIndex = 42;
  MenuIndex = 46;      // Menuefenster von TPPGPopupMenu
  CustomHintIndex = 48;
  TipIndex = 49;
  DialogIndex = 50;
  BusyIndex = 52;
  ControlNames: array[0..ControlCount - 1] of string = ('Button', 'CheckBox', 'RadioButton',
    'ToggleSwitch', 'ProgressBar', 'TrackBar', 'Panel', 'GroupBox', 'Edit', 'Memo', 'SpinEdit',
    'ComboBox', 'TabControl', 'PageControl', 'ListBox', 'CheckListBox', 'TreeView', 'Grid',
    'Label', 'LinkLabel', 'Badge', 'ProgressRing', 'InfoBar', 'Expander', 'Splitter', 'Rating',
    'SearchEdit', 'Calendar', 'DatePicker', 'TimePicker', 'NavigationView', 'Breadcrumb',
    'ToolBar', 'StatusBar', 'Sparkline', 'Gauge', 'KpiTile', 'Chart',
    'RadioGroup', 'CheckGroup', 'TileView', 'Toast',
    // 42..60
    'ScrollBox', 'Planner', 'Ribbon', 'Kanban', 'PopupMenu', 'MenuBar', 'CustomHint',
    'TeachingTip', 'TaskDialog', 'Wizard', 'BusyOverlay', 'NumberEdit', 'MaskEdit',
    'PasswordEdit', 'FileEdit', 'ColorPicker', 'CheckComboBox', 'ColumnComboBox', 'TagEdit',
    // 61..77
    'DBEdit', 'DBMemo', 'DBCheckBox', 'DBComboBox', 'DBLookupComboBox', 'DBDatePicker',
    'DBGrid', 'DBChart', 'DBPlanner', 'DBKanban', 'DBMaskEdit', 'DBNumberEdit',
    'DBColorPicker', 'DBCheckComboBox', 'DBTagEdit', 'DBNavigator', 'DBRadioGroup',
    'StyleTitle');
  // Welche Zustaende sichtbar anders sein muessen. Eigene Fenster (Hinweis,
  // TeachingTip, Dialog, Busy-Karte) haben keinen Maus-/Fokus-/Deaktiviert-
  // Zustand; das Menuefenster zeigt den markierten Eintrag als Hover.
  HasHover: array[0..ControlCount - 1] of Boolean = (True, True, True, True, False, True,
    False, False, True, True, True, True, True, True, True, True, True, False, // Grid: kein Hover
    False, True, False, False, True, True, True, True, True, True, True, True, True, True,
    True, False, False, False, True, True, True, True, True, True,
    // ScrollBox, Planner, Ribbon, Kanban, PopupMenu, MenuBar, CustomHint, TeachingTip,
    // TaskDialog, Wizard, BusyOverlay, Number, Mask, Password, File, Color, CheckCombo,
    // ColumnCombo, TagEdit
    False, True, True, True, True, True, False, False, False, False, False, True, True, True,
    True, True, True, True, True,
    // DB: Edit, Memo, CheckBox, ComboBox, Lookup, DatePicker, Grid (kein Hover wie Grid),
    // Chart, Planner, Kanban, Mask, Number, Color, CheckCombo, TagEdit, Navigator, RadioGroup
    True, True, True, True, True, True, False, True, True, True, True, True, True, True, True,
    True, True,
    False);
  HasFocus: array[0..ControlCount - 1] of Boolean = (True, True, True, True, False, True,
    False, False, True, True, True, True, True, True, True, True, True, True,
    False, True, False, False, True, True, True, True, True, True, True, True, True, True,
    True, False, False, False, True, True, True, True, True, False,
    // ScrollBox und Wizard: Fokus liegt auf den Kind-Controls; MenuBar und Ribbon:
    // nicht in der Tab-Folge (TabStop False), Tastatur ueber Alt bzw. KeyTips;
    // Fenster ohne Fokus. Planner und Kanban: Fokus am gewaehlten Termin bzw.
    // an der gewaehlten Karte (Galerie waehlt den ersten).
    False, True, False, True, False, False, False, False, False, False, False, True, True, True,
    True, True, True, True, True,
    True, True, True, True, True, True, True, True, True, True, True, True, True, True, True,
    True, True,
    False);
  VariantNames: array[TVisualVariant] of string = ('ModernFlat hell', 'ModernFlat dunkel',
    'Classic', 'Fluent11 hell', 'Fluent11 dunkel', 'GDI');
  StateNames: array[TVisualState] of string = ('Normal', 'Hover', 'Gedrueckt', 'Fokus',
    'Deaktiviert');
  LastControl = ControlCount - 2; // StyleTitle ist nur Platzhalter
  // Deaktiviert muss sichtbar sein (nicht: Panel und ScrollBox ohne Text-Aenderung,
  // Splitter, eigene Fenster)
  HasDisabled: array[0..ControlCount - 1] of Boolean = (True, True, True, True, True, True,
    False, True, True, True, True, True, True, True, True, True, True, True,
    True, True, True, True, True, True, False, True, True, True, True, True, True, True,
    True, True, True, True, True, True, True, True, True, False,
    False, True, True, True, False, True, False, False, False, True, False, True, True, True,
    True, True, True, True, True,
    True, True, True, True, True, True, True, True, True, True, True, True, True, True, True,
    True, True,
    False);
  // RTL: hier ist "keine Aenderung" fachlich richtig (symmetrisch bzw. Text fuellt
  // das Control); bei allen anderen muss sich das Bild aendern.
  // - Button, Panel: zentrierte Beschriftung; Label, LinkLabel: AutoSize, der Text
  //   fuellt die Breite; Badge, ProgressRing, Splitter, Gauge: symmetrisch;
  //   Sparkline: die Zeitachse laeuft auch in RTL von links nach rechts (wie Excel).
  RtlUnchanged: array[0..8] of string = ('Button', 'Panel', 'Label', 'LinkLabel', 'Badge',
    'ProgressRing', 'Splitter', 'Sparkline', 'Gauge');
  // Hochkontrast mit den Systemfarben des Testrechners: Label (Fenstertext auf
  // Fensterfarbe), LinkLabel (HotLight) und Badge (Highlight) haben dieselben
  // Farben wie das Preset ModernFlat hell.
  HcUnchanged: array[0..2] of string = ('Label', 'LinkLabel', 'Badge');

function IsWindowIndex(Index: Integer): Boolean;
begin
  Result := (Index = ToastIndex) or (Index = MenuIndex) or (Index = CustomHintIndex) or
    (Index = TipIndex) or (Index = DialogIndex) or (Index = BusyIndex);
end;

function VisualMonday: TDateTime;
begin
  Result := EncodeDate(2026, 6, 1); // ein Montag
end;

function InList(const Name: string; const List: array of string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(List) do
    if SameText(Name, List[I]) then
      Result := True;
end;

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

function PPGContentPixels(B: TBitmap): Integer;
begin
  Result := ContentPixels(B);
end;

procedure PPGCheckPainted(Test: TTestCase; B: TBitmap; const What: string);
begin
  Test.CheckTrue((B <> nil) and (B.Width > 0) and (B.Height > 0) and (ContentPixels(B) >= 20),
    What + ': Bild leer');
end;

procedure PPGCheckDiffers(Test: TTestCase; A, B: TBitmap; const What: string);
var
  D: Integer;
begin
  D := PPGPixelDiff(A, B, 15);
  Test.CheckTrue(D >= 8, Format('%s: kein sichtbarer Unterschied (%d Pixel)', [What, D]));
end;

function StateLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

function PPGRender(C: TWinControl): TBitmap;
begin
  Result := TBitmap.Create;
  try
    Result.PixelFormat := pf24bit;
    Result.SetSize(C.Width, C.Height);
    Result.Canvas.Lock;
    try
      C.PaintTo(Result.Canvas.Handle, 0, 0);
    finally
      Result.Canvas.Unlock;
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure PPGPaintCheck(Test: TTestCase; C: TWinControl; const What: string);
var
  B: TBitmap;
begin
  B := PPGRender(C);
  try
    PPGCheckPainted(Test, B, What + ' ' + C.ClassName);
  finally
    B.Free;
  end;
end;

procedure LeaveAll(C: TControl);
var
  I: Integer;
begin
  // Wie die echte Maus beim Verlassen: auch Kind-Fenster (inneres Edit der
  // Felder) bekommen CM_MOUSELEAVE
  if C is TWinControl then
    for I := 0 to TWinControl(C).ControlCount - 1 do
      LeaveAll(TWinControl(C).Controls[I]);
  C.Perform(CM_MOUSELEAVE, 0, 0);
end;

procedure Unfocus(F: TCustomForm);
begin
  // Fokus sicher vom Control nehmen: ActiveControl := nil allein laesst ihn bei
  // einem nicht aktiven Formular im Fenster (z. B. inneres Edit)
  if F = nil then
    Exit;
  F.ActiveControl := nil;
  if F.HandleAllocated then
    Winapi.Windows.SetFocus(F.Handle);
end;

procedure PPGCheckStates(Test: TTestCase; C: TWinControl; const What: string;
  Hover, Focus, Disabled: Boolean; const Pt: TPoint);
var
  G: Boolean;
  N, S: TBitmap;
  F: TCustomForm;
  W: string;
begin
  // Zustandswechsel ohne Ueberblendung (sonst zeigt das erste Bild den Anfang)
  if (GetPropInfo(C, 'Animation') <> nil) and (GetObjectProp(C, 'Animation') <> nil) and
    (GetPropInfo(GetObjectProp(C, 'Animation'), 'Enabled') <> nil) then
    SetOrdProp(GetObjectProp(C, 'Animation'), 'Enabled', 0);
  F := GetParentForm(C);
  for G := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := G;
    try
      W := What + IfThen(G, ' (GDI)', ' (GDI+)');
      Unfocus(F);
      LeaveAll(C);
      N := PPGRender(C);
      try
        PPGCheckPainted(Test, N, W);
        if Hover then
        begin
          C.Perform(CM_MOUSEENTER, 0, 0);
          C.Perform(WM_MOUSEMOVE, 0, StateLParam(Pt.X, Pt.Y));
          S := PPGRender(C);
          try
            PPGCheckDiffers(Test, N, S, W + ' Hover');
          finally
            S.Free;
          end;
          LeaveAll(C);
        end;
        if Focus then
        begin
          Test.CheckTrue(C.CanFocus, W + ': nicht fokussierbar');
          C.SetFocus;
          C.Perform(WM_UPDATEUISTATE, MakeWParam(UIS_CLEAR, UISF_HIDEFOCUS or UISF_HIDEACCEL), 0);
          S := PPGRender(C);
          try
            PPGCheckDiffers(Test, N, S, W + ' Fokus');
          finally
            S.Free;
          end;
          Unfocus(F);
        end;
        if Disabled then
        begin
          C.Enabled := False;
          S := PPGRender(C);
          try
            PPGCheckDiffers(Test, N, S, W + ' Deaktiviert');
          finally
            S.Free;
            C.Enabled := True;
          end;
        end;
      finally
        N.Free;
      end;
    finally
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
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
  // Datenquelle der DB-Controls (fester Inhalt, erster Datensatz aktiv)
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
  FData.FieldDefs.Add('Aktiv', ftBoolean);
  FData.FieldDefs.Add('Kat', ftString, 40);
  FData.FieldDefs.Add('Tags', ftString, 80);
  FData.FieldDefs.Add('Notiz', ftString, 200);
  FData.FieldDefs.Add('PLZ', ftString, 5);
  FData.FieldDefs.Add('OrtID', ftInteger);
  FData.CreateDataSet;
  FData.AppendRecord([1, 'Anna', 'doing', VisualMonday + 2 + EncodeTime(9, 0, 0, 0),
    VisualMonday + 2 + EncodeTime(10, 30, 0, 0), 12.5, clRed, True, 'Rot;Blau', 'Delphi;VCL',
    'Erste Zeile', '12345', 2]);
  FData.AppendRecord([2, 'Bernd', 'todo', VisualMonday + 3 + EncodeTime(11, 0, 0, 0),
    VisualMonday + 3 + EncodeTime(12, 0, 0, 0), 7, clBlue, False, 'Gruen', 'Test',
    'Zweite Zeile', '50667', 1]);
  FData.AppendRecord([3, 'Clara', 'done', VisualMonday + 1 + EncodeTime(14, 0, 0, 0),
    VisualMonday + 1 + EncodeTime(15, 30, 0, 0), 15.25, clGreen, True, 'Blau', '',
    'Dritte Zeile', '20095', 1]);
  FData.First;
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
  // Fokus-Cues sichtbar (wie nach Tastaturbedienung)
  FForm.Perform(WM_UPDATEUISTATE, MakeWParam(UIS_CLEAR, UISF_HIDEFOCUS or UISF_HIDEACCEL), 0);
end;

procedure TVisualTests.TearDown;
begin
  PPGSetHighContrastReader(nil);
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
  Rg: TPPGGaugeRange;
  Ser: TPPGChartSeries;
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
    34:
      begin
        Result := TPPGSparkline.Create(FForm);
        TPPGSparkline(Result).ValuesText := '3;5;2;8;6;9;7;11';
        TPPGSparkline(Result).Kind := skArea;
        TPPGSparkline(Result).Markers := [smMin, smMax, smLast];
        Result.SetBounds(8, 8, 160, 40);
      end;
    35:
      begin
        Result := TPPGGauge.Create(FForm);
        TPPGGauge(Result).Caption := 'Auslastung';
        TPPGGauge(Result).Units := ' %';
        Rg := TPPGGauge(Result).Ranges.Add;
        Rg.StartValue := 0;
        Rg.EndValue := 60;
        Rg.Kind := grkSuccess;
        Rg := TPPGGauge(Result).Ranges.Add;
        Rg.StartValue := 60;
        Rg.EndValue := 85;
        Rg.Kind := grkWarning;
        Rg := TPPGGauge(Result).Ranges.Add;
        Rg.StartValue := 85;
        Rg.EndValue := 100;
        Rg.Kind := grkError;
        TPPGGauge(Result).ShowTarget := True;
        TPPGGauge(Result).TargetValue := 80;
        TPPGGauge(Result).Value := 68;
        Result.SetBounds(8, 8, 150, 150);
      end;
    36:
      begin
        Result := TPPGKpiTile.Create(FForm);
        TPPGKpiTile(Result).Title := 'Umsatz';
        TPPGKpiTile(Result).Value := 12480;
        TPPGKpiTile(Result).Units := 'EUR';
        TPPGKpiTile(Result).Change := 4.2;
        TPPGKpiTile(Result).SparklineText := '3;5;4;7;6;8;9';
        Result.SetBounds(8, 8, 200, 120);
      end;
    37:
      begin
        Result := TPPGChart.Create(FForm);
        TPPGChart(Result).Title := 'Umsatz';
        TPPGChart(Result).Categories.CommaText := 'Jan,Feb,Mrz,Apr,Mai,Jun';
        Ser := TPPGChart(Result).Series.Add;
        Ser.Title := 'Plan';
        Ser.Kind := cskColumn;
        Ser.SetValues([12, 14, 13, 17, 19, 21]);
        Ser := TPPGChart(Result).Series.Add;
        Ser.Title := 'Ist';
        Ser.Kind := cskLine;
        Ser.ShowMarkers := True;
        Ser.SetValues([11, 15, 12, 18, 17, 23]);
        Result.SetBounds(8, 8, 360, 220);
      end;
    38:
      begin
        Result := TPPGRadioGroup.Create(FForm);
        TPPGRadioGroup(Result).Caption := 'Versand';
        TPPGRadioGroup(Result).Items.CommaText := 'Standard,Express,Abholung';
        TPPGRadioGroup(Result).ItemIndex := 1;
        Result.SetBounds(8, 8, 170, 110);
      end;
    39:
      begin
        Result := TPPGCheckGroup.Create(FForm);
        TPPGCheckGroup(Result).ChoiceStyle := csCards;
        TPPGCheckGroup(Result).ShowFrame := False;
        TPPGCheckGroup(Result).Items.CommaText := 'Mail,Telefon';
        TPPGCheckGroup(Result).ItemsEx[0].Icon := $E715;
        TPPGCheckGroup(Result).ItemsEx[0].Description := 'Werktags';
        TPPGCheckGroup(Result).Checked[0] := True;
        Result.SetBounds(8, 8, 180, 140);
      end;
    40:
      begin
        Result := TPPGTileView.Create(FForm);
        TPPGTileView(Result).Items.Add('Bericht').Detail := 'PDF, 2 MB';
        TPPGTileView(Result).Items.Add('Tabelle').Detail := 'xlsx';
        TPPGTileView(Result).Items[1].Badge := 'Neu';
        TPPGTileView(Result).ItemIndex := 1;
        Result.SetBounds(8, 8, 300, 180);
      end;
  else
    Result := BuildNewControl(Index, P);
  end;
  if (Result <> nil) and (Result.Parent = nil) then
    Result.Parent := P;
  if Result is TPPGCustomControl then
    TCCV(Result).Animation.Enabled := False;
end;

function VisualDT(Day, H, M: Integer): TDateTime;
begin
  Result := VisualMonday + Day + EncodeTime(H, M, 0, 0);
end;

procedure SetHintField(Obj: TObject; const Field, Value: string);
var
  Ctx: TRttiContext;
  F: TRttiField;
begin
  // TCustomHintWindow haelt Titel und Text privat (wie Phase 11b)
  F := Ctx.GetType(TCustomHintWindow).GetField(Field);
  if F = nil then
    raise Exception.Create('Feld fehlt: ' + Field);
  F.SetValue(Obj, TValue.From<string>(Value));
end;

{ Audit 11b: die bisher fehlenden Paletten-Controls (42..60, ohne die eigenen
  Fenster) und die DB-Controls (61..77) an FData. }
function TVisualTests.BuildNewControl(Index: Integer; P: TWinControl): TControl;
const
  WizardTitles: array[0..2] of string = ('Willkommen', 'Optionen', 'Fertig');
  MenuTitles: array[0..2] of string = ('&Datei', '&Bearbeiten', '&Ansicht');
var
  Pl: TPPGPlanner;
  DPl: TPPGDBPlanner;
  Rb: TPPGRibbon;
  G: TPPGRibbonGroup;
  K: TPPGKanban;
  DK: TPPGDBKanban;
  Col: TPPGKanbanColumn;
  Mm: TMainMenu;
  It: TMenuItem;
  Wz: TPPGWizard;
  Pg: TPPGWizardPage;
  I: Integer;
  Lb: TPPGLabel;
  Bt: TPPGButton;
  Cc: TPPGColumnComboBox;
  Ch: TPPGCheckComboBox;
begin
  Result := nil;
  // Jedes DB-Control zeigt den ersten Datensatz (Kanban und Planer bewegen beim
  // Waehlen den Datensatzzeiger)
  FData.First;
  case Index of
    42:
      begin
        Result := TPPGScrollBox.Create(FForm);
        Result.Parent := P;
        Result.SetBounds(8, 8, 200, 110);
        Bt := TPPGButton.Create(FForm);
        Bt.Parent := TWinControl(Result);
        Bt.Caption := 'Inhalt';
        Bt.SetBounds(8, 8, 110, 30);
        Lb := TPPGLabel.Create(FForm);
        Lb.Parent := TWinControl(Result);
        Lb.Caption := 'Weiter unten';
        Lb.SetBounds(8, 260, 120, 20); // erzwingt die senkrechte Bildlaufleiste
      end;
    43:
      begin
        Pl := TPPGPlanner.Create(FForm);
        Result := Pl;
        Pl.Parent := P;
        Pl.SetBounds(8, 8, 380, 300);
        Pl.Animation.Enabled := False;
        Pl.SmoothScrolling := False;
        Pl.FirstDayOfWeek := fdMonday;
        Pl.TimeZoneMode := tzmLocal;
        Pl.View := pvDay;
        Pl.DayStartHour := 8;
        Pl.DayEndHour := 14;
        Pl.Date := VisualMonday + 2;
        Pl.NowOverride := VisualDT(2, 11, 15);
        Pl.Appointments.AddAppointment(VisualDT(2, 9, 0), VisualDT(2, 10, 30), 'Besprechung');
        Pl.Appointments.AddAppointment(VisualDT(2, 12, 0), VisualDT(2, 13, 0), 'Mittag').Category := 2;
        Pl.SelectAppointment(Pl.Appointments[0]);
      end;
    44:
      begin
        Rb := TPPGRibbon.Create(FForm);
        Result := Rb;
        Rb.Parent := P;
        Rb.SetBounds(8, 8, 380, 130);
        G := Rb.Tabs.AddTab('Start').Groups.AddGroup('Zwischenablage');
        G.Items.AddButton('Einfuegen', $E77F, rsLarge);
        G.Items.AddButton('Ausschneiden', $E8C6, rsMedium);
        G.Items.AddButton('Kopieren', $E8C8, rsMedium);
        G := Rb.Tabs[0].Groups.AddGroup('Absatz');
        G.Items.AddCheck('Fett', $E8DD, rsSmall).Down := True;
        G.Items.AddCheck('Kursiv', $E8DB, rsSmall);
        Rb.Tabs.AddTab('Einfuegen');
      end;
    45:
      begin
        K := TPPGKanban.Create(FForm);
        Result := K;
        K.Parent := P;
        K.SetBounds(8, 8, 380, 240);
        K.Animation.Enabled := False;
        K.SmoothScrolling := False;
        Col := K.Columns.AddColumn('Offen');
        K.Cards.AddCard(Col.Id, 'Angebot', 'Kunde A');
        K.Cards.AddCard(Col.Id, 'Rechnung');
        Col := K.Columns.AddColumn('Fertig');
        K.Cards.AddCard(Col.Id, 'Vertrag', 'unterschrieben');
        K.HandleNeeded;
        K.Select(0, 0, 0);
      end;
    47:
      begin
        Mm := TMainMenu.Create(FForm);
        for I := 0 to High(MenuTitles) do
        begin
          It := TMenuItem.Create(Mm);
          It.Caption := MenuTitles[I];
          Mm.Items.Add(It);
        end;
        Result := TPPGMenuBar.Create(FForm);
        Result.Parent := P;
        TPPGMenuBar(Result).Menu := Mm;
        Result.SetBounds(8, 8, 300, Result.Height);
      end;
    51:
      begin
        Wz := TPPGWizard.Create(FForm);
        Result := Wz;
        Wz.Parent := P;
        Wz.SetBounds(8, 8, 380, 240);
        for I := 0 to High(WizardTitles) do
        begin
          Pg := TPPGWizardPage.Create(FForm);
          Pg.Caption := WizardTitles[I];
          Pg.Wizard := Wz;
        end;
        Wz.ActivePageIndex := 1;
      end;
    53:
      begin
        Result := TPPGNumberEdit.Create(FForm);
        TPPGNumberEdit(Result).ShowSpinButtons := True;
        TPPGNumberEdit(Result).Value := 1234.5;
        Result.SetBounds(8, 8, 180, 28);
      end;
    54:
      begin
        Result := TPPGMaskEdit.Create(FForm);
        Result.Parent := P;
        TPPGMaskEdit(Result).EditMask := '00000;1;_';
        TPPGMaskEdit(Result).Text := '12345';
        Result.SetBounds(8, 8, 180, 28);
      end;
    55:
      begin
        Result := TPPGPasswordEdit.Create(FForm);
        TPPGPasswordEdit(Result).Text := 'geheim';
        Result.SetBounds(8, 8, 180, 28);
      end;
    56:
      begin
        Result := TPPGFileEdit.Create(FForm);
        TPPGFileEdit(Result).FileName := 'C:\Daten\Bericht.docx';
        Result.SetBounds(8, 8, 220, 28);
      end;
    57:
      begin
        Result := TPPGColorPicker.Create(FForm);
        TPPGColorPicker(Result).Selected := clRed;
        Result.SetBounds(8, 8, 180, 28);
      end;
    58:
      begin
        Ch := TPPGCheckComboBox.Create(FForm);
        Result := Ch;
        Ch.Items.CommaText := 'Rot,Gruen,Blau';
        Ch.Checked[0] := True;
        Ch.Checked[2] := True;
        Result.SetBounds(8, 8, 200, 28);
      end;
    59:
      begin
        Cc := TPPGColumnComboBox.Create(FForm);
        Result := Cc;
        Cc.Columns.Add.Title := 'Nr';
        Cc.Columns.Add.Title := 'Name';
        Cc.Items.Add('1|Mueller');
        Cc.Items.Add('2|Albers');
        Cc.DisplayColumn := 1;
        Cc.ItemIndex := 0;
        Result.SetBounds(8, 8, 200, 28);
      end;
    60:
      begin
        Result := TPPGTagEdit.Create(FForm);
        Result.Parent := P;
        TPPGTagEdit(Result).Tags.Add('Delphi');
        TPPGTagEdit(Result).Tags.Add('VCL');
        Result.SetBounds(8, 8, 240, 32);
      end;
    61:
      begin
        Result := TPPGDBEdit.Create(FForm);
        TPPGDBEdit(Result).DataField := 'Name';
        TPPGDBEdit(Result).DataSource := FSource;
        Result.SetBounds(8, 8, 180, 28);
      end;
    62:
      begin
        Result := TPPGDBMemo.Create(FForm);
        Result.Parent := P;
        TPPGDBMemo(Result).DataField := 'Notiz';
        TPPGDBMemo(Result).DataSource := FSource;
        Result.SetBounds(8, 8, 180, 60);
      end;
    63:
      begin
        Result := TPPGDBCheckBox.Create(FForm);
        TPPGDBCheckBox(Result).Caption := 'Aktiv';
        TPPGDBCheckBox(Result).DataField := 'Aktiv';
        TPPGDBCheckBox(Result).DataSource := FSource;
        Result.SetBounds(8, 8, 120, 24);
      end;
    64:
      begin
        Result := TPPGDBComboBox.Create(FForm);
        TPPGDBComboBox(Result).Items.CommaText := 'todo,doing,done';
        TPPGDBComboBox(Result).DataField := 'Status';
        TPPGDBComboBox(Result).DataSource := FSource;
        Result.SetBounds(8, 8, 180, 28);
      end;
    65:
      begin
        Result := TPPGDBLookupComboBox.Create(FForm);
        TPPGDBLookupComboBox(Result).ListSource := FOrtSrc;
        TPPGDBLookupComboBox(Result).KeyField := 'ID';
        TPPGDBLookupComboBox(Result).ListField := 'Ort';
        TPPGDBLookupComboBox(Result).DataField := 'OrtID';
        TPPGDBLookupComboBox(Result).DataSource := FSource;
        Result.SetBounds(8, 8, 180, 28);
      end;
    66:
      begin
        Result := TPPGDBDatePicker.Create(FForm);
        TPPGDBDatePicker(Result).DataField := 'Beginn';
        TPPGDBDatePicker(Result).DataSource := FSource;
        Result.SetBounds(8, 8, 180, 28);
      end;
    67:
      begin
        Result := TPPGDBGrid.Create(FForm);
        Result.Parent := P;
        TPPGDBGrid(Result).DataSource := FSource;
        Result.SetBounds(8, 8, 360, 150);
      end;
    68:
      begin
        Result := TPPGDBChart.Create(FForm);
        TPPGDBChart(Result).Animation.Enabled := False;
        TPPGDBChart(Result).ReloadDelay := 0;
        TPPGDBChart(Result).ValueFields := 'Wert';
        TPPGDBChart(Result).LabelField := 'Name';
        TPPGDBChart(Result).DataSource := FSource;
        Result.SetBounds(8, 8, 360, 220);
      end;
    69:
      begin
        DPl := TPPGDBPlanner.Create(FForm);
        Result := DPl;
        DPl.Parent := P;
        DPl.SetBounds(8, 8, 380, 300);
        DPl.Animation.Enabled := False;
        DPl.SmoothScrolling := False;
        DPl.FirstDayOfWeek := fdMonday;
        DPl.TimeZoneMode := tzmLocal;
        DPl.View := pvDay;
        DPl.DayStartHour := 8;
        DPl.DayEndHour := 14;
        DPl.Date := VisualMonday + 2;
        DPl.NowOverride := VisualDT(2, 11, 15);
        DPl.ReloadDelay := 0;
        DPl.KeyField := 'ID';
        DPl.StartField := 'Beginn';
        DPl.FinishField := 'Ende';
        DPl.SubjectField := 'Name';
        DPl.DataSource := FSource;
        DPl.HandleNeeded;
        if DPl.Appointments.Count > 0 then
          DPl.SelectAppointment(DPl.Appointments[0]);
      end;
    70:
      begin
        DK := TPPGDBKanban.Create(FForm);
        Result := DK;
        DK.Parent := P;
        DK.SetBounds(8, 8, 380, 240);
        DK.Animation.Enabled := False;
        DK.SmoothScrolling := False;
        DK.ReloadDelay := 0;
        DK.Columns.AddColumn('Offen').Key := 'todo';
        DK.Columns.AddColumn('In Arbeit').Key := 'doing';
        DK.Columns.AddColumn('Fertig').Key := 'done';
        DK.KeyField := 'ID';
        DK.ColumnField := 'Status';
        DK.TitleField := 'Name';
        DK.TextField := 'Notiz';
        DK.DataSource := FSource;
        DK.HandleNeeded;
        DK.Select(0, 0, 0);
      end;
    71:
      begin
        Result := TPPGDBMaskEdit.Create(FForm);
        Result.Parent := P;
        TPPGDBMaskEdit(Result).EditMask := '00000;1;_';
        TPPGDBMaskEdit(Result).DataField := 'PLZ';
        TPPGDBMaskEdit(Result).DataSource := FSource;
        Result.SetBounds(8, 8, 180, 28);
      end;
    72:
      begin
        Result := TPPGDBNumberEdit.Create(FForm);
        TPPGDBNumberEdit(Result).ShowSpinButtons := True;
        TPPGDBNumberEdit(Result).DataField := 'Wert';
        TPPGDBNumberEdit(Result).DataSource := FSource;
        Result.SetBounds(8, 8, 180, 28);
      end;
    73:
      begin
        Result := TPPGDBColorPicker.Create(FForm);
        TPPGDBColorPicker(Result).DataField := 'Farbe';
        TPPGDBColorPicker(Result).DataSource := FSource;
        Result.SetBounds(8, 8, 180, 28);
      end;
    74:
      begin
        Result := TPPGDBCheckComboBox.Create(FForm);
        TPPGDBCheckComboBox(Result).Items.CommaText := 'Rot,Gruen,Blau';
        TPPGDBCheckComboBox(Result).DataField := 'Kat';
        TPPGDBCheckComboBox(Result).DataSource := FSource;
        Result.SetBounds(8, 8, 200, 28);
      end;
    75:
      begin
        Result := TPPGDBTagEdit.Create(FForm);
        Result.Parent := P;
        TPPGDBTagEdit(Result).DataField := 'Tags';
        TPPGDBTagEdit(Result).DataSource := FSource;
        Result.SetBounds(8, 8, 240, 32);
      end;
    76:
      begin
        Result := TPPGDBNavigator.Create(FForm);
        TPPGDBNavigator(Result).DataSource := FSource;
        Result.SetBounds(8, 8, 330, 34);
      end;
    77:
      begin
        Result := TPPGDBRadioGroup.Create(FForm);
        TPPGDBRadioGroup(Result).Caption := 'Status';
        TPPGDBRadioGroup(Result).Items.CommaText := 'todo,doing,done';
        TPPGDBRadioGroup(Result).DataField := 'Status';
        TPPGDBRadioGroup(Result).DataSource := FSource;
        Result.SetBounds(8, 8, 170, 110);
      end;
  end;
end;

{ Eigene Fenster: Menuefenster, CustomHint, TeachingTip, Aufgabendialog,
  Busy-Karte. Zustaende gibt es dort nicht (ausser dem markierten
  Menueeintrag als Hover). }
function TVisualTests.RenderWindow(Index: Integer; Variant: TVisualVariant; State: TVisualState;
  const Preset: string): TBitmap;
const
  MenuTitles: array[0..3] of string = ('&Neu', '&Oeffnen', '-', '&Beenden');
var
  M: TPPGPopupMenu;
  It: TMenuItem;
  L: TPPGMenuLoop;
  CH: TPPGCustomHint;
  HW: TCustomHintWindow;
  Tip: TPPGTeachingTip;
  D: TPPGTaskDialog;
  DF: TPPGDialogForm;
  O: TPPGBusyOverlay;
  Pn: TPanel;
  I: Integer;
begin
  Result := nil;
  case Index of
    MenuIndex:
      begin
        M := TPPGPopupMenu.Create(FForm);
        L := TPPGMenuLoop.Create;
        try
          for I := 0 to High(MenuTitles) do
          begin
            It := TMenuItem.Create(M);
            It.Caption := MenuTitles[I];
            M.Items.Add(It);
          end;
          M.Items[1].Checked := True;
          L.Animate := False;
          L.Preset := Preset;
          L.OpenPopup(M.Items, Rect(100, 100, 100, 100), ppsBelow, False);
          if State = vsHoverV then
            L.HandleKey(VK_DOWN, []);
          Result := RenderToBitmap(L.Window(0));
          L.CloseAll;
        finally
          L.Free;
          M.Free;
        end;
      end;
    CustomHintIndex:
      begin
        CH := TPPGCustomHint.Create(nil);
        HW := TCustomHintWindow.Create(nil);
        try
          CH.Preset := Preset;
          HW.HintParent := CH;
          SetHintField(HW, 'FTitle', 'Speichern');
          SetHintField(HW, 'FDescription', 'Speichert das Dokument (Strg+S).');
          CH.SetHintSize(HW);
          HW.HandleNeeded;
          Result := RenderToBitmap(HW);
        finally
          HW.Free;
          CH.Free;
        end;
      end;
    TipIndex:
      begin
        if FTipTarget = nil then
        begin
          FTipTarget := NewButton('Ziel');
          FTipTarget.SetBounds(450, 300, 100, 32);
        end;
        Tip := TPPGTeachingTip.Create(FForm);
        try
          Tip.Preset := Preset;
          Tip.Title := 'Neu hier?';
          Tip.Text := 'Mit diesem Button speichern Sie.';
          Tip.ActionButtonText := 'Weiter';
          Tip.ShowFor(FTipTarget);
          Result := RenderToBitmap(Tip.Window);
        finally
          Tip.Free;
        end;
      end;
    DialogIndex:
      begin
        D := TPPGTaskDialog.Create(nil);
        try
          D.Preset := Preset;
          D.Caption := 'PPGlow';
          D.Title := 'Aenderungen speichern?';
          D.Text := 'Das Dokument wurde geaendert.';
          D.MainIcon := tdiWarning;
          D.CommonButtons := [tcbYes, tcbNo, tcbCancel];
          DF := TPPGDialogForm.CreateFor(D, 0);
          try
            DF.HandleNeeded;
            Result := RenderToBitmap(DF);
            // nur der Client-Bereich (ohne Rahmen des Formulars)
            Result.SetSize(DF.ClientWidth, DF.ClientHeight);
          finally
            DF.Free;
          end;
        finally
          D.Free;
        end;
      end;
    BusyIndex:
      begin
        Pn := TPanel.Create(FForm);
        O := TPPGBusyOverlay.Create(FForm);
        try
          Pn.Parent := FForm;
          Pn.SetBounds(10, 10, 300, 220);
          O.Preset := Preset;
          O.Target := Pn;
          O.Delay := 0;
          O.MinDisplayTime := 0;
          O.Text := 'Export laeuft';
          O.Progress := 40;
          O.ShowNow;
          Result := RenderToBitmap(O.Card);
          O.Hide;
        finally
          O.Free;
          Pn.Free;
        end;
      end;
  end;
end;

function TVisualTests.HotPoint(C: TControl; Index: Integer): TPoint;
var
  R: TRect;
begin
  Result := Point(C.Width div 2, C.Height div 2);
  R := Rect(0, 0, 0, 0);
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
    38, 39:
      begin
        R := TPPGCustomChoiceGroup(C).ItemRect(0);
        Result := Point(R.Left + 8, (R.Top + R.Bottom) div 2);
      end;
    40:
      begin
        R := TPPGTileView(C).ItemRect(0);
        Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
      end;
    // Audit 11b
    43, 69: R := TPPGCustomPlanner(C).ItemRect(0);       // erster Termin
    44: R := TPPGCustomRibbon(C).ItemRect(TPPGCustomRibbon(C).Tabs[0].Groups[0].Items[0]);
    45, 70: R := TPPGCustomKanban(C).CardRect(0, 0, 0);  // erste Karte
    47: R := TPPGMenuBar(C).ItemRect(1);
    76: R := TPPGDBNavigator(C).ButtonRect(nbNext);
    77:
      begin
        R := TPPGCustomChoiceGroup(C).ItemRect(0);
        Result := Point(R.Left + 8, (R.Top + R.Bottom) div 2);
      end;
  end;
  if (Index >= FirstNewIndex) and (Index <> 77) and not IsRectEmpty(R) then
    Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
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
  if Index = ToastIndex then
  begin
    // Toast: eigenes Fenster
    Center := TPPGNotificationCenter.Create(FForm);
    try
      Center.Animation.Enabled := False;
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
  if IsWindowIndex(Index) then
  begin
    Result := RenderWindow(Index, Variant, State, Presets[Variant]);
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
            // (ColorPicker/DBColorPicker: das Farbfeld zeigt den Wert, keine Akzentfarbe;
            // wie das Windows-Farbfeld bleibt es farbig)
            Sat := SaturatedPixels(Cells[V, vsNormalV]);
            if (Index <> 57) and (Index <> 73) and (Sat >= 30) and (MeanSaturation(Cells[V, vsDisabledV]) >
              0.75 * MeanSaturation(Cells[V, vsNormalV])) and
              (SaturatedPixels(Cells[V, vsDisabledV]) * 2 > Sat) then
              Errors.Add(Format('%s %s: Deaktiviert behaelt kraeftige Farben (Saettigung %.0f statt %.0f)',
                [Name, VariantNames[V], MeanSaturation(Cells[V, vsDisabledV]),
                MeanSaturation(Cells[V, vsNormalV])]));
            // ... aber als Form erkennbar bleiben
            // (NavigationView dunkel: graue Schrift auf dunkler Leiste, per Sichtpruefung lesbar;
            // Planner/DBPlanner: Terminflaechen werden grau, Raster und Text per Sichtpruefung
            // lesbar, Audit 11b)
            if (Index <> 30) and (Index <> 43) and (Index <> 69) and
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
        // ProgressBar, ProgressRing, Splitter, Sparkline: ohne Text
        if (Index <> 4) and (Index <> 21) and (Index <> 24) and (Index <> 34) and (LightD < 10) then
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
            // Referenzbilder stammen aus dem alten Code: anlegen nur mit
            // /baseline, sonst ist ein fehlendes Bild ein Fehlschlag
            if not PPGTestBaseline then
            begin
              Errors.Add(Format('%s %s: Referenzbild %s fehlt (anlegen nur mit /baseline)',
                [ControlNames[Index], VariantNames[V], ExtractFileName(F)]));
              Continue;
            end;
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
      if not IsWindowIndex(Index) then // eigenes Fenster, folgt dem Formular nicht
        Rows.Add(ControlNames[Index]);
    SetLength(Cells, Rows.Count * 2);
    try
      N := 0;
      for Index := 0 to LastControl do
      begin
        if IsWindowIndex(Index) then
          Continue;
        FRtl := False;
        Cells[N * 2] := Render(Index, vvFlatLight, vsNormalV, Ok);
        FRtl := True;
        Cells[N * 2 + 1] := Render(Index, vvFlatLight, vsNormalV, Ok);
        FRtl := False;
        if ContentPixels(Cells[N * 2 + 1]) < 20 then
          Errors.Add(ControlNames[Index] + ': RTL leer');
        // Audit 11b: Aenderung erwartet, ausser bei den begruendeten Ausnahmen
        if (PPGPixelDiff(Cells[N * 2], Cells[N * 2 + 1], 40) < 8) and
          not InList(ControlNames[Index], RtlUnchanged) then
          NotMirrored.Add(ControlNames[Index]);
        Inc(N);
      end;
      ResetVariant;
      SaveSheet(Dir + 'RTL.png', ['Links nach rechts', 'Rechts nach links'], Rows, Cells);
    finally
      for I := 0 to High(Cells) do
        Cells[I].Free;
    end;
    CheckEquals('', NotMirrored.CommaText, 'RTL unveraendert, erwartet gespiegelt (RTL.png)');
    CheckEquals('', Errors.Text, Errors.Text);
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    NotMirrored.Free;
    Errors.Free;
    Rows.Free;
  end;
end;

function VisualHighContrastOn: Boolean;
begin
  Result := True;
end;

procedure TVisualTests.HighContrastGallery;
var
  Index, N: Integer;
  Cells: array of TBitmap;
  Rows, Errors, Unchanged: TStringList;
  Ok: Boolean;
  Dir: string;
  I: Integer;
begin
  Dir := ExtractFilePath(ParamStr(0)) + 'Visual\Gallery\';
  ForceDirectories(Dir);
  Rows := TStringList.Create;
  Errors := TStringList.Create;
  Unchanged := TStringList.Create;
  try
    for Index := 0 to LastControl do
      if not IsWindowIndex(Index) then // eigenes Fenster
        Rows.Add(ControlNames[Index]);
    SetLength(Cells, Rows.Count * 3);
    try
      N := 0;
      for Index := 0 to LastControl do
      begin
        if IsWindowIndex(Index) then
          Continue;
        PPGSetHighContrastReader(nil);
        Cells[N * 3] := Render(Index, vvFlatLight, vsNormalV, Ok);
        PPGSetHighContrastReader(VisualHighContrastOn);
        try
          Cells[N * 3 + 1] := Render(Index, vvFlatLight, vsNormalV, Ok);
          Cells[N * 3 + 2] := Render(Index, vvFlatLight, vsDisabledV, Ok);
        finally
          PPGSetHighContrastReader(nil);
        end;
        if ContentPixels(Cells[N * 3 + 1]) < 20 then
          Errors.Add(ControlNames[Index] + ': Hochkontrast leer');
        if (PPGPixelDiff(Cells[N * 3], Cells[N * 3 + 1], 40) < 8) and
          not InList(ControlNames[Index], HcUnchanged) then
          Unchanged.Add(ControlNames[Index]);
        Inc(N);
      end;
      ResetVariant;
      SaveSheet(Dir + 'HighContrast.png', ['Normal', 'Hochkontrast', 'Hochkontrast deaktiviert'],
        Rows, Cells);
    finally
      for I := 0 to High(Cells) do
        Cells[I].Free;
    end;
    CheckEquals('', Unchanged.CommaText, 'Hochkontrast unveraendert, erwartet Systemfarben (HighContrast.png)');
    CheckEquals('', Errors.Text, Errors.Text);
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    Unchanged.Free;
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
      if not IsWindowIndex(Index) then
        Rows.Add(ControlNames[Index]);
    SetLength(Cells, Rows.Count * Length(Ppis));
    try
      N := 0;
      for Index := 0 to LastControl do
      begin
        if IsWindowIndex(Index) then
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
