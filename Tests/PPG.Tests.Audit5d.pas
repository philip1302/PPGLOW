unit PPG.Tests.Audit5d;

{ Audit-Paket 5d (Docs\Audit-Paket4-5-Plan.md): die VCL-Properties und
  -Ereignisse, die TControl/TWinControl schon haben, sind bei allen sichtbaren
  Paletten-Controls veroeffentlicht und werden ausgeloest. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.TypInfo, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.ActnList,
  PPG.Feedback, PPG.Breadcrumb, PPG.Button, PPG.Calendar, PPG.Chart, PPG.CheckBox,
  PPG.CheckComboBox, PPG.RadioGroup, PPG.CheckListBox, PPG.ColorPicker, PPG.ColumnComboBox,
  PPG.ComboBox, PPG.DatePicker, PPG.Edit, PPG.Expander, PPG.FileEdit, PPG.Gauge, PPG.Grid,
  PPG.GroupBox, PPG.Kanban, PPG.Labels, PPG.ListBox, PPG.MaskEdit, PPG.Memo, PPG.MenuBar,
  PPG.NavigationView, PPG.NumberEdit, PPG.PageControl, PPG.Panel, PPG.PasswordEdit,
  PPG.Planner, PPG.ProgressBar, PPG.RadioButton, PPG.Rating, PPG.Ribbon, PPG.SearchEdit,
  PPG.Sparkline, PPG.SpinEdit, PPG.Splitter, PPG.StatusBar, PPG.TabControl, PPG.TagEdit,
  PPG.TileView, PPG.TimePicker, PPG.ToggleSwitch, PPG.ToolBar, PPG.TrackBar, PPG.TreeView,
  PPG.Wizard, PPG.DB.Chart, PPG.DB.Controls, PPG.DB.Fields, PPG.DB.Grid, PPG.DB.Kanban,
  PPG.DB.Lookup, PPG.DB.Navigator, PPG.DB.Planner,
  PPG.Controls.Field, PPG.Controls.Scroll, PPG.Grid.Edit, PPG.Render.Intf, System.UITypes,
  Data.DB, Datasnap.DBClient, Vcl.DBCtrls, Vcl.DBGrids, Vcl.StdCtrls, Vcl.ComCtrls, PPG.Tests.Controls;

type
  TVclPropsTests = class(TControlTestCase)
  private
    FFired: TStringList;
    procedure Note(const Event: string);
    procedure EvClick(Sender: TObject);
    procedure EvDblClick(Sender: TObject);
    procedure EvMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure EvMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure EvMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure EvMouseEnter(Sender: TObject);
    procedure EvMouseLeave(Sender: TObject);
    procedure EvMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint; var Handled: Boolean);
    procedure EvContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure EvKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EvKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EvKeyPress(Sender: TObject; var Key: Char);
    procedure EvEnter(Sender: TObject);
    procedure EvExit(Sender: TObject);
    procedure EvExecute(Sender: TObject);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Stage1Published;
    procedure Stage1EventsFire;
    procedure PickersClickOnUserSelection;
    procedure Stage2Published;
    procedure Stage2ActionExecutesOnClick;
  end;

  /// Stufe 3: kleine, control-spezifische Properties wie in der VCL.
  TStage3Tests = class(TControlTestCase)
  private
    FCount: Integer;
    FLog: string;
    procedure Counted(Sender: TObject);
    procedure ColEntered(Sender: TObject);
    procedure ColExited(Sender: TObject);
    procedure GetImage(Sender: TObject; TabIndex: Integer; var ImageIndex: Integer);
  published
    procedure Published;
    procedure TrackBarOnTracking;
    procedure ProgressBarColors;
    procedure PanelBorderStyle;
    procedure ComboAutoDropDownWidth;
    procedure PageControlImageAndHighlight;
    procedure GridScrollBars;
    procedure GridColEnterExit;
    procedure GridEllipsisEditor;
    procedure LookupVclProperties;
    procedure SearchEditAutoSelect;
    procedure TagEditClearRemovesTags;
  end;

const
  /// Alle sichtbaren Controls der Paletten (PPG.Reg, PPG.DB.Reg).
  VisualClasses: array[0..71] of TControlClass = (
    TPPGBadge, TPPGBreadcrumb, TPPGButton, TPPGCalendar, TPPGChart, TPPGCheckBox,
    TPPGCheckComboBox, TPPGCheckGroup, TPPGCheckListBox, TPPGColorPicker, TPPGColumnComboBox,
    TPPGComboBox, TPPGDatePicker, TPPGEdit, TPPGExpander, TPPGFileEdit, TPPGGauge, TPPGGrid,
    TPPGGroupBox, TPPGInfoBar, TPPGKanban, TPPGKpiTile, TPPGLabel, TPPGLinkLabel, TPPGListBox,
    TPPGMaskEdit, TPPGMemo, TPPGMenuBar, TPPGNavigationView, TPPGNumberEdit, TPPGPageControl,
    TPPGPanel, TPPGPasswordEdit, TPPGPlanner, TPPGProgressBar, TPPGProgressRing,
    TPPGRadioButton, TPPGRadioGroup, TPPGRating, TPPGRibbon, TPPGScrollBox, TPPGSearchEdit,
    TPPGSparkline, TPPGSpinEdit, TPPGSplitter, TPPGStatusBar, TPPGTabControl, TPPGTagEdit,
    TPPGTileView, TPPGTimePicker, TPPGToggleSwitch, TPPGToolBar, TPPGTrackBar, TPPGTreeView,
    TPPGWizard, TPPGDBChart, TPPGDBCheckBox, TPPGDBCheckComboBox, TPPGDBColorPicker,
    TPPGDBComboBox, TPPGDBDatePicker, TPPGDBEdit, TPPGDBGrid, TPPGDBKanban,
    TPPGDBLookupComboBox, TPPGDBMaskEdit, TPPGDBMemo, TPPGDBNavigator, TPPGDBNumberEdit,
    TPPGDBPlanner, TPPGDBRadioGroup, TPPGDBTagEdit);

implementation

const
  AllProps: array[0..18] of string = ('OnClick', 'OnMouseDown', 'OnMouseMove',
    'OnMouseUp', 'OnMouseEnter', 'OnMouseLeave', 'OnMouseWheel', 'OnMouseActivate',
    'OnContextPopup', 'PopupMenu', 'StyleElements', 'DragMode', 'DragCursor', 'OnDragDrop',
    'OnDragOver', 'OnStartDrag', 'OnEndDrag', 'Color', 'ParentColor');
  FocusProps: array[0..1] of string = ('OnEnter', 'OnExit');
  KeyProps: array[0..2] of string = ('OnKeyDown', 'OnKeyPress', 'OnKeyUp');

type
  TCtrlAccess = class(TControl);
  TWinAccess = class(TWinControl);

/// Nicht fokussierbar: keine Fokus- und Tasten-Ereignisse (wie TLabel, TStatusBar).
function NoFocus(C: TClass): Boolean;
begin
  Result := C.InheritsFrom(TGraphicControl) or (C = TPPGBadge) or (C = TPPGGauge) or
    (C = TPPGProgressRing) or (C = TPPGSparkline) or (C = TPPGStatusBar) or (C = TPPGMenuBar);
end;

/// Container und Anzeigen: OnEnter/OnExit, aber keine Tasten (wie TPanel, TProgressBar).
function NoKeys(C: TClass): Boolean;
begin
  Result := NoFocus(C) or (C = TPPGPanel) or (C = TPPGScrollBox) or (C = TPPGGroupBox) or
    (C = TPPGWizard) or (C = TPPGProgressBar);
end;


/// OnClick meldet den Auswahlwechsel (wie TListBox, TComboBox), nicht jeden Klick.
function SelectionClick(C: TClass): Boolean;
begin
  Result := C.InheritsFrom(TPPGCustomListBox) or C.InheritsFrom(TPPGCustomCheckListBox) or
    C.InheritsFrom(TPPGCustomTreeView) or C.InheritsFrom(TPPGCustomGrid) or
    C.InheritsFrom(TPPGCustomChoiceGroup) or C.InheritsFrom(TPPGCheckComboBox) or
    C.InheritsFrom(TPPGColorPicker) or C.InheritsFrom(TPPGColumnComboBox) or
    // eigenes OnClick(Sender, Button) wie TDBNavigator
    C.InheritsFrom(TPPGCustomDBNavigator);
end;
{ TVclPropsTests }

procedure TVclPropsTests.SetUp;
begin
  inherited;
  FFired := TStringList.Create;
  FFired.Sorted := True;
  FFired.Duplicates := dupIgnore;
end;

procedure TVclPropsTests.TearDown;
begin
  FFired.Free;
  inherited;
end;

procedure TVclPropsTests.Note(const Event: string);
begin
  FFired.Add(Event);
end;

procedure TVclPropsTests.EvClick(Sender: TObject);
begin
  Note('OnClick');
end;

procedure TVclPropsTests.EvDblClick(Sender: TObject);
begin
  Note('OnDblClick');
end;

procedure TVclPropsTests.EvMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  Note('OnMouseDown');
end;

procedure TVclPropsTests.EvMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  Note('OnMouseUp');
end;

procedure TVclPropsTests.EvMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  Note('OnMouseMove');
end;

procedure TVclPropsTests.EvMouseEnter(Sender: TObject);
begin
  Note('OnMouseEnter');
end;

procedure TVclPropsTests.EvMouseLeave(Sender: TObject);
begin
  Note('OnMouseLeave');
end;

procedure TVclPropsTests.EvMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint; var Handled: Boolean);
begin
  Note('OnMouseWheel');
  Handled := True;
end;

procedure TVclPropsTests.EvContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
  Note('OnContextPopup');
  Handled := True;
end;

procedure TVclPropsTests.EvKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  Note('OnKeyDown');
end;

procedure TVclPropsTests.EvKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  Note('OnKeyUp');
end;

procedure TVclPropsTests.EvKeyPress(Sender: TObject; var Key: Char);
begin
  Note('OnKeyPress');
end;

procedure TVclPropsTests.EvEnter(Sender: TObject);
begin
  Note('OnEnter');
end;

procedure TVclPropsTests.EvExit(Sender: TObject);
begin
  Note('OnExit');
end;

procedure TVclPropsTests.EvExecute(Sender: TObject);
begin
  Note('Execute');
end;

procedure TVclPropsTests.Stage1Published;
var
  C: TControlClass;
  Missing, Line: string;
  P: string;
begin
  Missing := '';
  for C in VisualClasses do
  begin
    Line := '';
    for P in AllProps do
      if GetPropInfo(C, P) = nil then
        Line := Line + ' ' + P;
    if not NoFocus(C) then
      for P in FocusProps do
        if GetPropInfo(C, P) = nil then
          Line := Line + ' ' + P;
    if not NoKeys(C) then
      for P in KeyProps do
        if GetPropInfo(C, P) = nil then
          Line := Line + ' ' + P;
    if Line <> '' then
      Missing := Missing + #13#10 + C.ClassName + ':' + Line;
  end;
  CheckEquals('', Missing, 'nicht veroeffentlicht');
end;

procedure TVclPropsTests.Stage1EventsFire;
var
  CC: TControlClass;
  C: TControl;
  W: TWinAccess;
  Other: TPPGEdit;
  Missing, Line, E: string;
  Pt, Scr: TPoint;
  LP: LPARAM;
  Expected: TArray<string>;
begin
  FForm.SetBounds(0, 0, 900, 700);
  FForm.Show;
  Other := TPPGEdit.Create(FForm);
  Other.Parent := FForm;
  Other.SetBounds(600, 600, 100, 24);
  Missing := '';
  for CC in VisualClasses do
  begin
    FFired.Clear;
    C := CC.Create(FForm);
    try
      C.Parent := FForm;
      C.SetBounds(10, 10, 300, 200);
      if C is TWinControl then
        TWinControl(C).HandleNeeded;
      with TCtrlAccess(C) do
      begin
        OnClick := EvClick;
        OnDblClick := EvDblClick;
        OnMouseDown := EvMouseDown;
        OnMouseUp := EvMouseUp;
        OnMouseMove := EvMouseMove;
        OnMouseEnter := EvMouseEnter;
        OnMouseLeave := EvMouseLeave;
        OnMouseWheel := EvMouseWheel;
        OnContextPopup := EvContextPopup;
      end;
      Application.ProcessMessages;
      // Auf eine Stelle ohne Bedienelement (rechts unten) klicken
      Pt := Point(C.Width - 4, C.Height - 4);
      if C is TPPGCustomField then
        Pt.X := 4; // Felder: nicht auf die Knoepfe rechts (FileEdit oeffnet einen Dialog)
      LP := MakeLParam(Word(Pt.X), Word(Pt.Y));
      Scr := C.ClientToScreen(Pt);
      Expected := ['OnMouseDown', 'OnMouseUp', 'OnMouseMove', 'OnMouseEnter', 'OnMouseLeave',
        'OnMouseWheel', 'OnContextPopup'];
      if not SelectionClick(CC) then
        Expected := Expected + ['OnClick'];
      // Doppelklicks nimmt nur an, wer csDoubleClicks hat (sonst zaehlen schnelle
      // Klicks einzeln, wie bei TButton); nur dann gibt es OnDblClick
      if csDoubleClicks in C.ControlStyle then
      begin
        if GetPropInfo(CC, 'OnDblClick') = nil then
          Missing := Missing + #13#10 + CC.ClassName + ': OnDblClick nicht veroeffentlicht';
        // TPPGDBMemo laedt beim ersten Doppelklick das Memo (wie TDBMemo)
        // Aufklappfelder ohne Edit: der Klick klappt auf, der zweite gehoert der Liste
        if not CC.InheritsFrom(TPPGDBMemo) and not SelectionClick(CC) then
          Expected := Expected + ['OnDblClick'];
      end
      else if GetPropInfo(CC, 'OnDblClick') <> nil then
        Missing := Missing + #13#10 + CC.ClassName + ': OnDblClick ohne csDoubleClicks';
      C.Perform(CM_MOUSEENTER, 0, 0);
      C.Perform(WM_MOUSEMOVE, 0, LP);
      C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, LP);
      C.Perform(WM_LBUTTONUP, 0, LP);
      C.Perform(WM_LBUTTONDBLCLK, MK_LBUTTON, LP);
      C.Perform(WM_LBUTTONUP, 0, LP);
      if GetCapture <> 0 then
        ReleaseCapture;
      C.Perform(WM_MOUSEWHEEL, MakeWParam(0, Word(SmallInt(-WHEEL_DELTA))),
        MakeLParam(Word(Scr.X), Word(Scr.Y)));
      if C is TWinControl then
        C.Perform(WM_CONTEXTMENU, WPARAM(TWinControl(C).Handle), MakeLParam(Word(Scr.X), Word(Scr.Y)))
      else
        C.Perform(WM_CONTEXTMENU, WPARAM(FForm.Handle), MakeLParam(Word(Scr.X), Word(Scr.Y)));
      C.Perform(CM_MOUSELEAVE, 0, 0);
      if not NoKeys(CC) then
      begin
        W := TWinAccess(C);
        W.OnKeyDown := EvKeyDown;
        W.OnKeyUp := EvKeyUp;
        W.OnKeyPress := EvKeyPress;
        W.OnEnter := EvEnter;
        W.OnExit := EvExit;
        Expected := Expected + ['OnKeyDown', 'OnKeyUp', 'OnKeyPress', 'OnEnter', 'OnExit'];
        W.Perform(WM_KEYDOWN, VK_F13, 0);
        W.Perform(WM_CHAR, Ord('x'), 0);
        W.Perform(WM_KEYUP, VK_F13, 0);
        Other.SetFocus;
        if W.CanFocus then
          W.SetFocus;
        Other.SetFocus;
      end;
      Line := '';
      for E in Expected do
        if FFired.IndexOf(E) < 0 then
          Line := Line + ' ' + E;
      if Line <> '' then
        Missing := Missing + #13#10 + CC.ClassName + ':' + Line;
    finally
      if GetCapture <> 0 then
        ReleaseCapture;
      C.Free;
    end;
    Application.ProcessMessages;
  end;
  CheckEquals('', Missing, 'Ereignisse nicht ausgeloest');
end;

procedure TVclPropsTests.PickersClickOnUserSelection;
var
  CP: TPPGColorPicker;
  CO: TPPGColumnComboBox;
  CC: TPPGCheckComboBox;
begin
  // OnClick meldet die Auswahl durch den Anwender (wie TColorBox, TComboBox)
  CP := TPPGColorPicker.Create(FForm);
  CP.Parent := FForm;
  CP.OnClick := EvClick;
  CP.Selected := clRed;
  CheckEquals(-1, FFired.IndexOf('OnClick'), 'Code loest kein OnClick aus');
  CP.SelectColor(clBlue);
  CheckTrue(FFired.IndexOf('OnClick') >= 0, 'ColorPicker');
  FFired.Clear;
  CO := TPPGColumnComboBox.Create(FForm);
  CO.Parent := FForm;
  CO.Items.Add('1|A');
  CO.Items.Add('2|B');
  CO.OnClick := EvClick;
  CO.SelectRow(1);
  CheckTrue(FFired.IndexOf('OnClick') >= 0, 'ColumnComboBox');
  FFired.Clear;
  CC := TPPGCheckComboBox.Create(FForm);
  CC.Parent := FForm;
  CC.Items.Add('A');
  CC.OnClick := EvClick;
  CC.ToggleItem(0);
  CheckTrue(FFired.IndexOf('OnClick') >= 0, 'CheckComboBox');
end;

const
  /// Anklickbare Controls mit Beschriftung, die eine Action annehmen (Stufe 2).
  ActionClasses: array[0..4] of TControlClass = (TPPGLabel, TPPGLinkLabel, TPPGBadge,
    TPPGPanel, TPPGGroupBox);

procedure TVclPropsTests.Stage2Published;
var
  C: TControlClass;
  Missing, Line: string;
begin
  Missing := '';
  for C in VisualClasses do
  begin
    Line := '';
    if C.InheritsFrom(TWinControl) then
    begin
      if GetPropInfo(C, 'DoubleBuffered') = nil then
        Line := Line + ' DoubleBuffered';
      if GetPropInfo(C, 'ParentDoubleBuffered') = nil then
        Line := Line + ' ParentDoubleBuffered';
    end;
    if Line <> '' then
      Missing := Missing + #13#10 + C.ClassName + ':' + Line;
  end;
  for C in ActionClasses do
    if GetPropInfo(C, 'Action') = nil then
      Missing := Missing + #13#10 + C.ClassName + ': Action';
  CheckEquals('', Missing, 'nicht veroeffentlicht');
end;

procedure TVclPropsTests.Stage2ActionExecutesOnClick;
var
  CC: TControlClass;
  C: TControl;
  A: TAction;
  Missing: string;
  LP: LPARAM;
begin
  FForm.Show;
  Missing := '';
  for CC in ActionClasses do
  begin
    FFired.Clear;
    A := TAction.Create(FForm);
    C := CC.Create(FForm);
    try
      A.Caption := 'Aktion';
      A.OnExecute := EvExecute;
      C.Parent := FForm;
      C.SetBounds(10, 10, 200, 60);
      TCtrlAccess(C).Action := A;
      CheckEquals('Aktion', TCtrlAccess(C).Caption, CC.ClassName + ': Caption aus der Action');
      LP := MakeLParam(Word(C.Width - 4), Word(C.Height - 4));
      C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, LP);
      C.Perform(WM_LBUTTONUP, 0, LP);
      if GetCapture <> 0 then
        ReleaseCapture;
      if FFired.IndexOf('Execute') < 0 then
        Missing := Missing + ' ' + CC.ClassName;
    finally
      C.Free;
      A.Free;
    end;
  end;
  CheckEquals('', Missing, 'Action nicht ausgefuehrt');
end;

{ TStage3Tests }

type
  TProgressCrack = class(TPPGProgressBar);
  TComboCrack = class(TPPGComboBox);
  TGridCrack = class(TPPGGrid);
  TGridEditCrack = class(TPPGGridEdit);
  TTagCrack = class(TPPGTagEdit);
  TLookupCrack = class(TPPGDBLookupComboBox);
  TDBGridCrack = class(TPPGDBGrid);

procedure TStage3Tests.Counted(Sender: TObject);
begin
  Inc(FCount);
end;

procedure TStage3Tests.ColEntered(Sender: TObject);
begin
  FLog := FLog + 'e' + IntToStr(TPPGGrid(Sender).Col);
end;

procedure TStage3Tests.ColExited(Sender: TObject);
begin
  FLog := FLog + 'x' + IntToStr(TPPGGrid(Sender).Col);
end;

procedure TStage3Tests.GetImage(Sender: TObject; TabIndex: Integer; var ImageIndex: Integer);
begin
  Inc(FCount);
  if TabIndex = 1 then
    ImageIndex := 5;
end;

procedure TStage3Tests.Published;
const
  Props: array[0..20] of string = (
    'TPPGNumberEdit.ShowClearButton', 'TPPGPasswordEdit.ShowClearButton',
    'TPPGTagEdit.ShowClearButton', 'TPPGTagEdit.TextHintVisibleOnFocus',
    'TPPGSpinEdit.TextHintVisibleOnFocus', 'TPPGDatePicker.TextHintVisibleOnFocus',
    'TPPGTimePicker.TextHintVisibleOnFocus', 'TPPGRibbon.TabStop', 'TPPGStatusBar.Action',
    'TPPGPanel.OnCanResize', 'TPPGPanel.BorderStyle', 'TPPGSearchEdit.ReadOnly',
    'TPPGSearchEdit.Alignment', 'TPPGTrackBar.OnTracking', 'TPPGProgressBar.BarColor',
    'TPPGProgressBar.BackgroundColor', 'TPPGComboBox.AutoDropDownWidth',
    'TPPGPageControl.OnGetImageIndex', 'TPPGGrid.ScrollBars', 'TPPGDBGrid.OnEditButtonClick',
    'TPPGDBLookupComboBox.ListFieldIndex');
  Classes: array[0..13] of TClass = (TPPGNumberEdit, TPPGPasswordEdit, TPPGTagEdit,
    TPPGSpinEdit, TPPGDatePicker, TPPGTimePicker, TPPGRibbon, TPPGStatusBar, TPPGPanel,
    TPPGSearchEdit, TPPGTrackBar, TPPGProgressBar, TPPGComboBox, TPPGPageControl);
var
  S, Missing: string;
  P: Integer;
  C: TClass;
  Found: Boolean;
begin
  Missing := '';
  for S in Props do
  begin
    P := Pos('.', S);
    Found := False;
    for C in Classes do
      if C.ClassName = Copy(S, 1, P - 1) then
        Found := GetPropInfo(C, Copy(S, P + 1, MaxInt)) <> nil;
    if Copy(S, 1, P - 1) = 'TPPGGrid' then
      Found := GetPropInfo(TPPGGrid, 'ScrollBars') <> nil;
    if Copy(S, 1, P - 1) = 'TPPGDBGrid' then
      Found := (GetPropInfo(TPPGDBGrid, 'OnEditButtonClick') <> nil) and
        (GetPropInfo(TPPGDBGrid, 'OnColEnter') <> nil) and (GetPropInfo(TPPGDBGrid, 'OnColExit') <> nil);
    if Copy(S, 1, P - 1) = 'TPPGDBLookupComboBox' then
      Found := (GetPropInfo(TPPGDBLookupComboBox, 'ListFieldIndex') <> nil) and
        (GetPropInfo(TPPGDBLookupComboBox, 'DropDownRows') <> nil) and
        (GetPropInfo(TPPGDBLookupComboBox, 'DropDownAlign') <> nil);
    if not Found then
      Missing := Missing + ' ' + S;
  end;
  CheckTrue(GetPropInfo(TPPGTabSheet, 'Highlighted') <> nil, 'TabSheet.Highlighted');
  CheckTrue(GetPropInfo(TPPGDBGridColumn, 'ButtonStyle') <> nil, 'DBGridColumn.ButtonStyle');
  CheckEquals('', Missing, 'nicht veroeffentlicht');
end;

procedure TStage3Tests.TrackBarOnTracking;
var
  T: TPPGTrackBar;
  Y: Integer;
begin
  FForm.Show;
  T := TPPGTrackBar.Create(FForm);
  T.Parent := FForm;
  T.SetBounds(10, 10, 300, 40);
  T.Max := 100;
  T.OnTracking := Counted;
  Y := T.Height div 2;
  T.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(10, Y));
  FCount := 0;
  T.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(150, Y));
  T.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(250, Y));
  T.Perform(WM_LBUTTONUP, 0, MakeLParam(250, Y));
  if GetCapture <> 0 then
    ReleaseCapture;
  CheckEquals(2, FCount, 'je Wertaenderung beim Ziehen');
  T.Position := 10;
  CheckEquals(2, FCount, 'nicht beim Setzen im Code');
end;

procedure TStage3Tests.ProgressBarColors;
var
  P: TPPGProgressBar;
begin
  P := TPPGProgressBar.Create(FForm);
  P.Parent := FForm;
  CheckEquals(Integer(clDefault), Integer(P.BarColor));
  P.BarColor := clGreen;
  P.BackgroundColor := clYellow;
  CheckEquals(ColorToRGB(clGreen), TProgressCrack(P).GetFillStyle.ColorMirror, 'Balken');
  CheckEquals(ColorToRGB(clYellow), TProgressCrack(P).GetTrackStyle.Color, 'Spur');
  P.State := pbsError;
  CheckTrue(TProgressCrack(P).GetFillStyle.ColorMirror <> ColorToRGB(clGreen),
    'Fehlerzustand behaelt die Signalfarbe');
end;

procedure TStage3Tests.PanelBorderStyle;
var
  P: TPPGPanel;
begin
  P := TPPGPanel.Create(FForm);
  P.Parent := FForm;
  P.HandleNeeded;
  CheckEquals(0, GetWindowLong(P.Handle, GWL_EXSTYLE) and WS_EX_CLIENTEDGE, 'Vorgabe bsNone');
  P.BorderStyle := bsSingle;
  P.HandleNeeded;
  CheckTrue(GetWindowLong(P.Handle, GWL_EXSTYLE) and WS_EX_CLIENTEDGE <> 0, 'bsSingle mit Ctl3D');
end;

procedure TStage3Tests.ComboAutoDropDownWidth;
var
  C: TPPGComboBox;
begin
  C := TPPGComboBox.Create(FForm);
  C.Parent := FForm;
  C.Width := 80;
  C.Items.Add('kurz');
  C.Items.Add('ein sehr langer Eintrag, der nicht in das schmale Feld passt');
  C.HandleNeeded;
  CheckTrue(TComboCrack(C).AutoListWidth > C.Width, 'breitester Eintrag');
end;

procedure TStage3Tests.PageControlImageAndHighlight;
var
  PC: TPPGPageControl;
  S1, S2: TPPGTabSheet;
begin
  PC := TPPGPageControl.Create(FForm);
  PC.Parent := FForm;
  S1 := TPPGTabSheet.Create(FForm);
  S1.PageControl := PC;
  S2 := TPPGTabSheet.Create(FForm);
  S2.PageControl := PC;
  S2.ImageIndex := 2;
  FCount := 0;
  PC.OnGetImageIndex := GetImage;
  S2.Highlighted := True;
  CheckTrue(FCount > 0, 'OnGetImageIndex gefragt');
  CheckEquals(5, PC.Strip.Tab(1).ImageIndex, 'Bild aus dem Ereignis');
  CheckEquals(-1, PC.Strip.Tab(0).ImageIndex);
  CheckTrue(PC.Strip.Tab(1).Highlighted, 'hervorgehoben');
  CheckFalse(PC.Strip.Tab(0).Highlighted);
end;

procedure TStage3Tests.GridScrollBars;
var
  G: TPPGGrid;
begin
  FForm.Show;
  G := TPPGGrid.Create(FForm);
  G.Parent := FForm;
  G.SetBounds(0, 0, 120, 100);
  G.ColCount := 20;
  G.RowCount := 200;
  Application.ProcessMessages;
  CheckTrue(G.ScrollBarVisible(saVert) and G.ScrollBarVisible(saHorz), 'ssBoth');
  G.ScrollBars := System.UITypes.TScrollStyle.ssVertical;
  CheckTrue(G.ScrollBarVisible(saVert));
  CheckFalse(G.ScrollBarVisible(saHorz), 'keine waagerechte');
  G.ScrollBars := System.UITypes.TScrollStyle.ssNone;
  CheckFalse(G.ScrollBarVisible(saVert), 'keine');
end;

procedure TStage3Tests.GridColEnterExit;
var
  G: TPPGGrid;
begin
  FForm.Show;
  G := TPPGGrid.Create(FForm);
  G.Parent := FForm;
  G.SetBounds(0, 0, 300, 200);
  G.ColCount := 4;
  G.RowCount := 5;
  G.SetFocus;
  FLog := '';
  TGridCrack(G).OnColExit := ColExited;
  TGridCrack(G).OnColEnter := ColEntered;
  G.Perform(WM_KEYDOWN, VK_RIGHT, 0);
  CheckEquals('x1e2', FLog, 'erst verlassen, dann betreten');
  FLog := '';
  G.Perform(WM_KEYDOWN, VK_DOWN, 0);
  CheckEquals('', FLog, 'Zeilenwechsel ist kein Spaltenwechsel');
end;

procedure TStage3Tests.GridEllipsisEditor;
var
  Col: TPPGDBGridColumn;
  E: TPPGGridEdit;
  B: TPPGFieldButtons;
  I: Integer;
  Has: Boolean;
begin
  Col := TPPGDBGridColumn.Create(nil);
  E := TPPGGridEdit.Create(FForm);
  try
    E.Parent := FForm;
    CheckFalse(Col.ShowsEllipsis, 'Vorgabe cbsAuto');
    Col.ButtonStyle := cbsEllipsis;
    CheckTrue(Col.ShowsEllipsis);
    (E as IPPGGridCellEditor).CellEditorBegin('Wert', Col);
    CheckTrue(E.Ellipsis, 'Editor zeigt den Knopf');
    TGridEditCrack(E).GetButtons(B);
    Has := False;
    for I := 0 to High(B) do
      if B[I].Glyph = fgEllipsis then
      begin
        Has := True;
        FCount := 0;
        E.OnEllipsisClick := Counted;
        TGridEditCrack(E).ButtonClick(B[I].Id);
        CheckEquals(1, FCount, 'Klick meldet sich');
      end;
    CheckTrue(Has, '"..."-Knopf in GetButtons');
    (E as IPPGGridCellEditor).CellEditorBegin('Wert', nil);
    CheckFalse(E.Ellipsis, 'andere Spalte: kein Knopf');
  finally
    E.Free;
    Col.Free;
  end;
end;

procedure TStage3Tests.LookupVclProperties;
var
  DS: TClientDataSet;
  Src: TDataSource;
  L: TPPGDBLookupComboBox;
begin
  DS := TClientDataSet.Create(FForm);
  DS.FieldDefs.Add('Nr', ftInteger);
  DS.FieldDefs.Add('Name', ftString, 20);
  DS.CreateDataSet;
  DS.AppendRecord([1, 'Albers']);
  DS.AppendRecord([2, 'Berg']);
  Src := TDataSource.Create(FForm);
  Src.DataSet := DS;
  L := TPPGDBLookupComboBox.Create(FForm);
  L.Parent := FForm;
  L.ListSource := Src;
  L.KeyField := 'Nr';
  L.ListField := 'Nr;Name';
  L.ListFieldIndex := 1;
  CheckTrue(L.KeyCount = 2);
  CheckEquals('Albers', L.ItemsEx[0].Text, 'ListFieldIndex waehlt das angezeigte Feld');
  CheckEquals('1', L.ItemsEx[0].Detail, 'die uebrigen Felder als Detail');
  L.DropDownRows := 12;
  CheckEquals(12, L.DropDownCount, 'DropDownRows = DropDownCount');
  L.DropDownAlign := daRight;
  CheckTrue(TLookupCrack(L).PopupAlign = taRightJustify);
  CheckTrue(L.DropDownAlign = daRight);
end;

procedure TStage3Tests.SearchEditAutoSelect;
var
  S: TPPGSearchEdit;
begin
  S := TPPGSearchEdit.Create(FForm);
  S.Parent := FForm;
  CheckTrue(S.AutoSelect, 'Vorgabe wie TSearchBox');
  S.AutoSelect := False;
  CheckFalse(S.AutoSelect);
  S.ReadOnly := True;
  CheckTrue(S.ReadOnly);
end;

procedure TStage3Tests.TagEditClearRemovesTags;
var
  T: TPPGTagEdit;
begin
  FForm.Show;
  T := TPPGTagEdit.Create(FForm);
  T.Parent := FForm;
  T.Tags.CommaText := 'a,b,c';
  T.ShowClearButton := True;
  T.SetFocus;
  CheckTrue(TTagCrack(T).ButtonVisible(PPGFieldButtonClear), 'Knopf auch ohne getippten Text');
  FCount := 0;
  T.OnChange := Counted;
  T.Clear;
  CheckEquals(0, T.Tags.Count, 'alle Tags weg');
  CheckTrue(FCount >= 1, 'OnChange');
  CheckFalse(TTagCrack(T).ButtonVisible(PPGFieldButtonClear), 'leer: kein Knopf');
end;

initialization
  RegisterTest('Audit45', TVclPropsTests.Suite);
  RegisterTest('Audit45', TStage3Tests.Suite);

end.
