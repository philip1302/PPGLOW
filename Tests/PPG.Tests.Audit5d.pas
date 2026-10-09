unit PPG.Tests.Audit5d;

{ Audit-Paket 5d (Docs\Audit-Paket4-5-Plan.md): die VCL-Properties und
  -Ereignisse, die TControl/TWinControl schon haben, sind bei allen sichtbaren
  Paletten-Controls veroeffentlicht und werden ausgeloest. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.TypInfo, Vcl.Controls, Vcl.Forms, Vcl.Graphics,
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
  PPG.Controls.Field, PPG.Tests.Controls;

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
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Stage1Published;
    procedure Stage1EventsFire;
    procedure PickersClickOnUserSelection;
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

initialization
  RegisterTest('Audit45', TVclPropsTests.Suite);

end.
