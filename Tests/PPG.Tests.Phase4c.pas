unit PPG.Tests.Phase4c;

{ Tests fuer Phase 4c: TPPGTabControl, TPPGPageControl/TPPGTabSheet,
  TPPGTabStrip, IPPGTabRenderer. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, Winapi.ActiveX, Winapi.oleacc,
  System.Classes, System.SysUtils, System.Types, System.Variants,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  PPG.Types, PPG.Consts, PPG.Render.Intf, PPG.Render.Registry,
  PPG.Button, PPG.Edit, PPG.TabStrip, PPG.TabControl, PPG.PageControl,
  PPG.Tests.Controls, PPG.Tests.Gaps, PPG.Tests.Phase4a;

type
  TTabsTestCase = class(TPhase4TestCase)
  protected
    FLog: TStringList;
    FAllowChange: Boolean;
    FCanClose: Boolean;
    FCloseAction: TCloseAction;
    // Schliessen-Ereignis entfernt den Reiter bzw. die Seite selbst
    FSelfDelete: Boolean;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure LogChange(Sender: TObject);
    procedure LogChanging(Sender: TObject; var AllowChange: Boolean);
    procedure LogShow(Sender: TObject);
    procedure LogHide(Sender: TObject);
    procedure TabCloseQuery(Sender: TObject; Index: Integer; var CanClose: Boolean);
    procedure TabClose(Sender: TObject; Index: Integer; var Action: TCloseAction);
    procedure PageCloseQuery(Sender: TObject; Page: TPPGTabSheet; var CanClose: Boolean);
    procedure PageClose(Sender: TObject; Page: TPPGTabSheet; var Action: TCloseAction);
    function NewTabControl(const Tabs: string): TPPGTabControl;
    function NewPageControl(Pages: Integer): TPPGPageControl;
    procedure ClickTab(C: TPPGCustomTabs; Index: Integer);
    /// Strg (und Umschalt) im Tastaturzustand des Threads setzen/loesen.
    procedure SetModifiers(Ctrl, Shift: Boolean);
    procedure PumpPosted(Wnd: HWND);
  end;

  TTabControlTests = class(TTabsTestCase)
  published
    procedure DefaultsMatchTTabControl;
    procedure TabsAndTabIndexWithoutEvents;
    procedure ClickSelectsAndChangingCanCancel;
    procedure KeyboardNavigation;
    procedure CtrlTabOnlyInnermost;
    procedure AcceleratorSelectsTab;
    procedure CloseButtonQueryAndClose;
    procedure OverflowShowsArrowsAndScrolls;
    procedure DisplayRectAndChildAlignment;
    procedure LoadsTTabControlDfm;
    procedure CloseHandlerDeletingTabIsSafe;
    procedure FreedImageListLeavesStrip;
  end;

  TPageControlTests = class(TTabsTestCase)
  published
    procedure SheetsAndActivePage;
    procedure ParentAssignmentRegistersPage;
    procedure ClickChangesPageWithEvents;
    procedure DeletingActivePageSelectsNeighbour;
    procedure TabVisibleHidesTab;
    procedure PageIndexReorders;
    procedure CtrlTabMovesFocusToNewPage;
    procedure CloseActions;
    procedure ShowControlActivatesPage;
    procedure DesignHitTestOnTabsOnly;
    procedure LoadsTPageControlDfmAndRoundTrips;
    procedure CloseHandlerFreeingPageIsSafe;
    procedure FreedImageListLeavesStrip;
  end;

  TTabsAccessibilityTests = class(TTabsTestCase)
  published
    procedure TabsAreVirtualChildren;
    procedure TabDefaultActionSelectsAsynchronously;
  end;

  TPhase4cPaintTests = class(TTabsTestCase)
  published
    procedure IndicatorUnderSelectedTab;
    procedure IndicatorSlidesToNewTab;
    procedure SelectedTabMergesWithPage;
    procedure AllVariantsPaintWithoutErrors;
    procedure NoHandleOrMemoryLeaks;
  end;

implementation

{$WARN SYMBOL_PLATFORM OFF}

type
  TTabsAccess = class(TPPGCustomTabs);

const
  GR_GDIOBJECTS = 0;
  GR_USEROBJECTS = 1;

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Cardinal(Word(SmallInt(X))) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

function CenterOf(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

function ColorDist(A, B: TColor): Integer;
var
  CA, CB: Cardinal;
begin
  CA := ColorToRGB(A);
  CB := ColorToRGB(B);
  Result := Abs(GetRValue(CA) - GetRValue(CB)) + Abs(GetGValue(CA) - GetGValue(CB)) +
    Abs(GetBValue(CA) - GetBValue(CB));
end;

function AllocatedBytes: NativeUInt;
var
  S: TMemoryManagerState;
  I: Integer;
begin
  GetMemoryManagerState(S);
  Result := S.TotalAllocatedMediumBlockSize + S.TotalAllocatedLargeBlockSize;
  for I := Low(S.SmallBlockTypeStates) to High(S.SmallBlockTypeStates) do
    Inc(Result, S.SmallBlockTypeStates[I].AllocatedBlockCount *
      S.SmallBlockTypeStates[I].UseableBlockSize);
end;

procedure LoadDfm(const Text: string; Instance: TComponent);
var
  Src: TStringStream;
  Bin: TMemoryStream;
begin
  Src := TStringStream.Create(Text);
  Bin := TMemoryStream.Create;
  try
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    Bin.ReadComponent(Instance);
  finally
    Bin.Free;
    Src.Free;
  end;
end;

function ComponentToText(C: TComponent): string;
var
  Bin: TMemoryStream;
  Txt: TStringStream;
begin
  Bin := TMemoryStream.Create;
  Txt := TStringStream.Create('');
  try
    Bin.WriteComponent(C);
    Bin.Position := 0;
    ObjectBinaryToText(Bin, Txt);
    Result := Txt.DataString;
  finally
    Txt.Free;
    Bin.Free;
  end;
end;

{ TTabsTestCase }

procedure TTabsTestCase.SetUp;
begin
  inherited;
  FLog := TStringList.Create;
  FAllowChange := True;
  FCanClose := True;
  FCloseAction := caHide;
  FSelfDelete := False;
end;

procedure TTabsTestCase.TearDown;
begin
  SetModifiers(False, False);
  inherited;
  FreeAndNil(FLog);
end;

procedure TTabsTestCase.LogChange(Sender: TObject);
begin
  Inc(FChanges);
  FLog.Add('Change');
end;

procedure TTabsTestCase.LogChanging(Sender: TObject; var AllowChange: Boolean);
begin
  FLog.Add('Changing');
  AllowChange := FAllowChange;
end;

procedure TTabsTestCase.LogShow(Sender: TObject);
begin
  FLog.Add('Show:' + TPPGTabSheet(Sender).Caption);
end;

procedure TTabsTestCase.LogHide(Sender: TObject);
begin
  FLog.Add('Hide:' + TPPGTabSheet(Sender).Caption);
end;

procedure TTabsTestCase.TabCloseQuery(Sender: TObject; Index: Integer; var CanClose: Boolean);
begin
  FLog.Add('Query:' + IntToStr(Index));
  CanClose := FCanClose;
end;

procedure TTabsTestCase.TabClose(Sender: TObject; Index: Integer; var Action: TCloseAction);
begin
  FLog.Add('Close:' + IntToStr(Index));
  Action := FCloseAction;
  if FSelfDelete then
    TPPGTabControl(Sender).Tabs.Delete(Index);
end;

procedure TTabsTestCase.PageCloseQuery(Sender: TObject; Page: TPPGTabSheet;
  var CanClose: Boolean);
begin
  FLog.Add('Query:' + Page.Caption);
  CanClose := FCanClose;
end;

procedure TTabsTestCase.PageClose(Sender: TObject; Page: TPPGTabSheet;
  var Action: TCloseAction);
begin
  FLog.Add('Close:' + Page.Caption);
  Action := FCloseAction;
  if FSelfDelete then
    Page.Free;
end;

function TTabsTestCase.NewTabControl(const Tabs: string): TPPGTabControl;
begin
  Result := TPPGTabControl.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 360, 200);
  Result.Preset := PPGPresetModernFlat;
  Result.Animation.Enabled := False;
  Result.Tabs.CommaText := Tabs;
  Result.OnChange := LogChange;
  Result.OnChanging := LogChanging;
  Result.HandleNeeded;
end;

function TTabsTestCase.NewPageControl(Pages: Integer): TPPGPageControl;
var
  I: Integer;
  S: TPPGTabSheet;
begin
  Result := TPPGPageControl.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 360, 200);
  Result.Preset := PPGPresetModernFlat;
  Result.Animation.Enabled := False;
  for I := 1 to Pages do
  begin
    S := TPPGTabSheet.Create(FForm);
    S.Caption := 'Seite' + IntToStr(I);
    S.PageControl := Result;
    S.OnShow := LogShow;
    S.OnHide := LogHide;
  end;
  Result.OnChange := LogChange;
  Result.OnChanging := LogChanging;
  Result.HandleNeeded;
end;

procedure TTabsTestCase.ClickTab(C: TPPGCustomTabs; Index: Integer);
begin
  ClickAt(C, CenterOf(C.TabRect(Index)).X, CenterOf(C.TabRect(Index)).Y);
end;

procedure TTabsTestCase.SetModifiers(Ctrl, Shift: Boolean);
var
  KS: TKeyboardState;
begin
  GetKeyboardState(KS);
  if Ctrl then
    KS[VK_CONTROL] := $80
  else
    KS[VK_CONTROL] := 0;
  if Shift then
    KS[VK_SHIFT] := $80
  else
    KS[VK_SHIFT] := 0;
  SetKeyboardState(KS);
end;

procedure TTabsTestCase.PumpPosted(Wnd: HWND);
var
  Msg: TMsg;
begin
  while PeekMessage(Msg, Wnd, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;

{ TTabControlTests }

procedure TTabControlTests.DefaultsMatchTTabControl;
var
  T: TPPGTabControl;
begin
  T := TPPGTabControl.Create(nil);
  try
    CheckEquals(289, T.Width);
    CheckEquals(193, T.Height);
    CheckEquals(-1, T.TabIndex);
    CheckTrue(T.TabPosition = tpTop);
    CheckTrue(T.HotTrack);
    CheckTrue(T.TabStop);
    CheckFalse(T.ShowCloseButton);
    CheckEquals(0, T.TabWidth);
    CheckEquals(0, T.TabHeight);
  finally
    T.Free;
  end;
end;

procedure TTabControlTests.TabsAndTabIndexWithoutEvents;
var
  T: TPPGTabControl;
begin
  T := NewTabControl('Eins,Zwei,Drei');
  CheckEquals(0, T.TabIndex, 'Reiter vorhanden: erster ist aktiv');
  CheckEquals(3, T.Strip.Count);
  T.TabIndex := 2;
  CheckEquals(2, T.TabIndex);
  CheckEquals(2, T.Strip.Selected);
  T.TabIndex := 7;
  CheckEquals(2, T.TabIndex, 'ungueltig: ignoriert (wie TTabControl)');
  T.Tabs.Delete(2);
  CheckEquals(1, T.TabIndex, 'Index auf den letzten Reiter begrenzt');
  T.Tabs.Clear;
  CheckEquals(-1, T.TabIndex);
  CheckEquals(0, FChanges, 'Code loest keine Ereignisse aus');
  CheckEquals('', FLog.CommaText);
end;

procedure TTabControlTests.ClickSelectsAndChangingCanCancel;
var
  T: TPPGTabControl;
begin
  FForm.Show;
  try
    T := NewTabControl('Eins,Zwei,Drei');
    ClickTab(T, 1);
    CheckEquals(1, T.TabIndex);
    CheckEquals('Changing,Change', FLog.CommaText);
    CheckTrue(T.Focused, 'Klick auf einen Reiter fokussiert');
    FLog.Clear;
    FAllowChange := False;
    ClickTab(T, 2);
    CheckEquals(1, T.TabIndex, 'OnChanging verhindert den Wechsel');
    CheckEquals('Changing', FLog.CommaText);
    FLog.Clear;
    FAllowChange := True;
    ClickTab(T, 1);
    CheckEquals('', FLog.CommaText, 'aktiver Reiter: keine Ereignisse');
    CheckEquals(1, T.IndexOfTabAt(CenterOf(T.TabRect(1)).X, CenterOf(T.TabRect(1)).Y));
    CheckEquals(-1, T.IndexOfTabAt(T.Width div 2, T.Height - 10), 'Seite ist kein Reiter');
  finally
    FForm.Hide;
  end;
end;

procedure TTabControlTests.KeyboardNavigation;
var
  T: TPPGTabControl;
begin
  FForm.Show;
  try
    T := NewTabControl('Eins,Zwei,Drei,Vier');
    T.SetFocus;
    CheckTrue(T.Perform(WM_GETDLGCODE, 0, 0) and DLGC_WANTARROWS <> 0);
    T.Perform(WM_KEYDOWN, VK_RIGHT, 0);
    CheckEquals(1, T.TabIndex);
    T.Perform(WM_KEYDOWN, VK_END, 0);
    CheckEquals(3, T.TabIndex);
    T.Perform(WM_KEYDOWN, VK_RIGHT, 0);
    CheckEquals(3, T.TabIndex, 'Pfeiltaste am Ende: bleibt (wie Windows)');
    T.Perform(WM_KEYDOWN, VK_LEFT, 0);
    CheckEquals(2, T.TabIndex);
    T.Perform(WM_KEYDOWN, VK_HOME, 0);
    CheckEquals(0, T.TabIndex);
    SetModifiers(True, False);
    CheckEquals(1, T.Perform(CM_DIALOGKEY, VK_TAB, 0), 'Strg+Tab verarbeitet');
    CheckEquals(1, T.TabIndex);
    SetModifiers(True, True);
    T.Perform(CM_DIALOGKEY, VK_TAB, 0);
    CheckEquals(0, T.TabIndex, 'Strg+Umschalt+Tab zurueck');
    SetModifiers(True, False);
    T.Perform(CM_DIALOGKEY, VK_NEXT, 0);
    CheckEquals(1, T.TabIndex, 'Strg+Bild ab');
    T.Perform(CM_DIALOGKEY, VK_PRIOR, 0);
    CheckEquals(0, T.TabIndex, 'Strg+Bild auf');
    SetModifiers(False, False);
    CheckEquals(0, T.Perform(CM_DIALOGKEY, VK_TAB, 0), 'Tab ohne Strg: Formular');
    CheckEquals(8, FChanges);
  finally
    SetModifiers(False, False);
    FForm.Hide;
  end;
end;

procedure TTabControlTests.CtrlTabOnlyInnermost;
var
  Outer: TPPGPageControl;
  Inner: TPPGTabControl;
  E: TPPGEdit;
begin
  FForm.Show;
  try
    Outer := NewPageControl(2);
    Inner := TPPGTabControl.Create(FForm);
    Inner.Parent := Outer.Pages[0];
    Inner.SetBounds(4, 4, 200, 120);
    Inner.Animation.Enabled := False;
    Inner.Tabs.CommaText := 'a,b,c';
    E := TPPGEdit.Create(FForm);
    E.Parent := Inner;
    E.SetBounds(10, 60, 100, 25);
    E.SetFocus;
    SetModifiers(True, False);
    // Das Formular verteilt CM_DIALOGKEY an alle Kinder (aeusseres zuerst)
    FForm.Perform(CM_DIALOGKEY, VK_TAB, 0);
    CheckEquals(1, Inner.TabIndex, 'inneres Reiter-Control wechselt');
    CheckEquals(0, Outer.ActivePageIndex, 'aeusseres bleibt');
  finally
    SetModifiers(False, False);
    FForm.Hide;
  end;
end;

procedure TTabControlTests.AcceleratorSelectsTab;
var
  T: TPPGTabControl;
begin
  FForm.Show;
  try
    T := NewTabControl('&Allgemein,&Details,&Extras');
    CheckEquals(1, T.Perform(CM_DIALOGCHAR, Ord('d'), 0));
    CheckEquals(1, T.TabIndex);
    CheckTrue(T.Focused);
    CheckEquals(0, T.Perform(CM_DIALOGCHAR, Ord('q'), 0), 'kein Treffer');
  finally
    FForm.Hide;
  end;
end;

procedure TTabControlTests.CloseButtonQueryAndClose;
var
  T: TPPGTabControl;
  R: TRect;
begin
  FForm.Show;
  try
    T := NewTabControl('Eins,Zwei,Drei');
    T.ShowCloseButton := True;
    T.OnClosing := TabCloseQuery;
    T.OnClose := TabClose;
    T.TabIndex := 1;
    R := T.Strip.CloseRectAt(1);
    CheckFalse(IsRectEmpty(R), 'Schliessen-Knopf vorhanden');
    FCanClose := False;
    ClickAt(T, CenterOf(R).X, CenterOf(R).Y);
    CheckEquals('Query:1', FLog.CommaText);
    CheckEquals(3, T.Tabs.Count, 'CanClose = False');
    FLog.Clear;
    FCanClose := True;
    FCloseAction := caFree;
    ClickAt(T, CenterOf(R).X, CenterOf(R).Y);
    CheckEquals('Query:1,Close:1,Change', FLog.CommaText);
    CheckEquals('Eins,Drei', T.Tabs.CommaText);
    CheckEquals(1, T.TabIndex, 'Nachbar (der folgende) wird aktiv');
  finally
    FForm.Hide;
  end;
end;

procedure TTabControlTests.CloseHandlerDeletingTabIsSafe;
var
  T: TPPGTabControl;
begin
  // Audit 08.10.2026: OnClose loeschte den Reiter selbst und liess caFree
  // stehen -> der Nachbar wurde mitgeloescht, beim letzten Reiter
  // EStringListError.
  T := NewTabControl('Eins,Zwei,Drei');
  T.OnClose := TabClose;
  T.TabIndex := 1;
  FSelfDelete := True;
  FCloseAction := caFree;
  TTabsAccess(T).CloseTab(1);
  CheckEquals('Eins,Drei', T.Tabs.CommaText, 'nur der eigene Reiter weg');
  TTabsAccess(T).CloseTab(1);
  CheckEquals('Eins', T.Tabs.CommaText, 'letzter Reiter ohne Exception');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TTabControlTests.FreedImageListLeavesStrip;
var
  T: TPPGTabControl;
  IL: TImageList;
begin
  // Audit 08.10.2026: Die Reiterleiste hielt nach der Freigabe der
  // ImageList noch den alten Zeiger und las ihn beim Zeichnen.
  T := NewTabControl('Eins,Zwei');
  IL := TImageList.Create(FForm);
  T.Images := IL;
  CheckSame(IL, T.Strip.Images);
  IL.Free;
  CheckNull(T.Images);
  CheckNull(T.Strip.Images, 'Leiste zeigt nicht mehr auf die freigegebene Liste');
  T.Repaint;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TTabControlTests.OverflowShowsArrowsAndScrolls;
var
  T: TPPGTabControl;
  I: Integer;
  P: TPoint;
begin
  FForm.Show;
  try
    T := NewTabControl('');
    T.Width := 220;
    for I := 1 to 10 do
      T.Tabs.Add('Reiter ' + IntToStr(I));
    CheckTrue(T.Strip.Overflow, 'zu viele Reiter');
    CheckFalse(IsRectEmpty(T.Strip.NextRect));
    CheckEquals(0, T.Strip.FirstVisible);
    P := CenterOf(T.Strip.NextRect);
    CheckEquals(-1, T.IndexOfTabAt(P.X, P.Y), 'Pfeil ist kein Reiter');
    ClickAt(T, P.X, P.Y);
    CheckEquals(1, T.Strip.FirstVisible, 'Pfeil blaettert');
    CheckTrue(IsRectEmpty(T.TabRect(0)), 'erster Reiter verdeckt');
    CheckEquals(0, T.TabIndex, 'Blaettern waehlt nicht');
    T.TabIndex := 9;
    CheckFalse(IsRectEmpty(T.TabRect(9)), 'gewaehlter Reiter wird sichtbar gemacht');
    CheckTrue(T.TabRect(9).Right <= T.Strip.PrevRect.Left, 'nicht unter den Pfeilen');
    T.TabIndex := 0;
    CheckEquals(0, T.Strip.FirstVisible);
  finally
    FForm.Hide;
  end;
end;

procedure TTabControlTests.DisplayRectAndChildAlignment;
var
  T: TPPGTabControl;
  P: TPanel;
  D: TRect;
begin
  T := NewTabControl('Eins,Zwei');
  P := TPanel.Create(FForm);
  P.Parent := T;
  P.Align := alClient;
  D := T.DisplayRect;
  CheckTrue(D.Top >= T.Strip.StripRect.Bottom, 'Innenbereich unter den Reitern');
  CheckEquals(D.Top, P.Top);
  CheckEquals(D.Left, P.Left);
  CheckEquals(D.Bottom - D.Top, P.Height);
  T.TabPosition := tpBottom;
  D := T.DisplayRect;
  CheckTrue(D.Bottom <= T.Strip.StripRect.Top, 'Reiter unten: Innenbereich darueber');
  CheckEquals(D.Bottom, P.Top + P.Height, 'Kind folgt');
end;

procedure TTabControlTests.LoadsTTabControlDfm;
const
  Dfm =
    'object Tabs1: TPPGTabControl'#13#10 +
    '  Left = 8'#13#10 +
    '  Top = 8'#13#10 +
    '  Width = 289'#13#10 +
    '  Height = 193'#13#10 +
    '  TabOrder = 0'#13#10 +
    '  TabPosition = tpBottom'#13#10 +
    '  Tabs.Strings = ('#13#10 +
    '    ''Eins'''#13#10 +
    '    ''Zwei'''#13#10 +
    '    ''Drei'')'#13#10 +
    '  TabIndex = 2'#13#10 +
    'end'#13#10;
var
  T, T2: TPPGTabControl;
  S: string;
begin
  T := TPPGTabControl.Create(FForm);
  T.Parent := FForm;
  LoadDfm(Dfm, T);
  CheckEquals(3, T.Tabs.Count);
  CheckEquals(2, T.TabIndex);
  CheckTrue(T.TabPosition = tpBottom);
  CheckEquals(2, T.Strip.Selected);
  S := ComponentToText(T);
  CheckTrue(Pos('TabIndex = 2', S) > 0, S);
  T2 := TPPGTabControl.Create(FForm);
  T2.Parent := FForm;
  LoadDfm(StringReplace(S, 'object Tabs1', 'object Tabs2', []), T2);
  CheckEquals(2, T2.TabIndex);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

{ TPageControlTests }

procedure TPageControlTests.SheetsAndActivePage;
var
  PC: TPPGPageControl;
begin
  PC := NewPageControl(3);
  CheckEquals(3, PC.PageCount);
  CheckSame(PC.Pages[0], PC.ActivePage, 'erste Seite wird aktiv');
  CheckTrue(PC.Pages[0].Visible);
  CheckFalse(PC.Pages[1].Visible);
  CheckEquals(1, PC.Pages[1].PageIndex);
  PC.ActivePage := PC.Pages[2];
  CheckTrue(PC.Pages[2].Visible);
  CheckFalse(PC.Pages[0].Visible, 'alte Seite versteckt');
  CheckEquals(2, PC.ActivePageIndex);
  CheckEquals(2, PC.Strip.Selected);
  PC.ActivePageIndex := 1;
  CheckSame(PC.Pages[1], PC.ActivePage);
  CheckEquals(0, FChanges, 'Code loest kein OnChange aus');
  CheckTrue(Pos('Changing', FLog.CommaText) = 0);
  // Seite fuellt den Innenbereich
  CheckEquals(PC.DisplayRect.Top, PC.Pages[1].Top);
  CheckEquals(PC.DisplayRect.Right - PC.DisplayRect.Left, PC.Pages[1].Width);
end;

procedure TPageControlTests.ParentAssignmentRegistersPage;
var
  PC: TPPGPageControl;
  S: TPPGTabSheet;
begin
  PC := NewPageControl(0);
  CheckEquals(0, PC.PageCount);
  CheckNull(PC.ActivePage);
  S := TPPGTabSheet.Create(FForm);
  S.Caption := 'Neu';
  S.Parent := PC;
  CheckEquals(1, PC.PageCount, 'Parent := PC macht die Seite zur Seite');
  CheckSame(S, PC.ActivePage);
  CheckSame(PC, S.PageControl);
  S.PageControl := nil;
  CheckEquals(0, PC.PageCount);
  CheckNull(PC.ActivePage);
  CheckEquals(0, PC.Strip.Count);
  S.Free;
end;

procedure TPageControlTests.ClickChangesPageWithEvents;
var
  PC: TPPGPageControl;
begin
  FForm.Show;
  try
    PC := NewPageControl(3);
    FLog.Clear;
    ClickTab(PC, 2);
    CheckSame(PC.Pages[2], PC.ActivePage);
    CheckEquals('Changing,Hide:Seite1,Show:Seite3,Change', FLog.CommaText);
    FLog.Clear;
    FAllowChange := False;
    ClickTab(PC, 0);
    CheckSame(PC.Pages[2], PC.ActivePage, 'OnChanging verhindert');
    PC.Pages[1].Enabled := False;
    FAllowChange := True;
    FLog.Clear;
    ClickTab(PC, 1);
    CheckSame(PC.Pages[2], PC.ActivePage, 'deaktivierte Seite nicht waehlbar');
    CheckEquals('', FLog.CommaText);
  finally
    FForm.Hide;
  end;
end;

procedure TPageControlTests.DeletingActivePageSelectsNeighbour;
var
  PC: TPPGPageControl;
begin
  PC := NewPageControl(4);
  PC.ActivePageIndex := 1;
  PC.ActivePage.Free;
  CheckEquals(3, PC.PageCount);
  CheckEquals('Seite3', PC.ActivePage.Caption, 'folgende Seite');
  CheckTrue(PC.ActivePage.Visible);
  PC.ActivePageIndex := 2;
  PC.ActivePage.Free;
  CheckEquals('Seite3', PC.ActivePage.Caption, 'letzte: vorige Seite');
  PC.Pages[0].Free;
  PC.Pages[0].Free;
  CheckEquals(0, PC.PageCount);
  CheckNull(PC.ActivePage);
  CheckEquals(0, PC.Strip.Count);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPageControlTests.TabVisibleHidesTab;
var
  PC: TPPGPageControl;
begin
  PC := NewPageControl(3);
  PC.Pages[1].TabVisible := False;
  CheckEquals(2, PC.Strip.Count, 'Reiter ausgeblendet');
  CheckTrue(IsRectEmpty(PC.TabRect(1)));
  CheckEquals(-1, PC.Pages[1].TabIndex);
  CheckEquals(1, PC.Pages[2].TabIndex, 'Position unter den sichtbaren Reitern');
  PC.ActivePageIndex := 2;
  PC.Pages[2].TabVisible := False;
  CheckEquals('Seite1', PC.ActivePage.Caption, 'ausgeblendete aktive Seite: Nachbar');
  PC.Pages[1].TabVisible := True;
  CheckEquals(2, PC.Strip.Count);
end;

procedure TPageControlTests.PageIndexReorders;
var
  PC: TPPGPageControl;
  S: TPPGTabSheet;
begin
  PC := NewPageControl(3);
  S := PC.Pages[2];
  S.PageIndex := 0;
  CheckSame(S, PC.Pages[0]);
  CheckEquals('Seite3', PC.Strip.Tab(0).Caption, 'Reiter folgt');
  CheckEquals('Seite1', PC.Pages[1].Caption);
  S.PageIndex := 99;
  CheckEquals(2, S.PageIndex, 'begrenzt');
end;

procedure TPageControlTests.CtrlTabMovesFocusToNewPage;
var
  PC: TPPGPageControl;
  E1, E2: TPPGEdit;
begin
  FForm.Show;
  try
    PC := NewPageControl(2);
    E1 := TPPGEdit.Create(FForm);
    E1.Parent := PC.Pages[0];
    E1.SetBounds(10, 10, 100, 25);
    E2 := TPPGEdit.Create(FForm);
    E2.Parent := PC.Pages[1];
    E2.SetBounds(10, 10, 100, 25);
    E1.SetFocus;
    SetModifiers(True, False);
    FForm.Perform(CM_DIALOGKEY, VK_TAB, 0);
    CheckSame(PC.Pages[1], PC.ActivePage, 'Strg+Tab im Formular wechselt die Seite');
    CheckTrue(E2.Focused, 'Fokus auf dem ersten Control der neuen Seite');
    CheckEquals(1, FChanges);
    SetModifiers(False, False);
    PC.SetFocus;
    PC.Perform(WM_KEYDOWN, VK_LEFT, 0);
    CheckSame(PC.Pages[0], PC.ActivePage, 'Pfeiltaste am fokussierten Control');
    CheckTrue(PC.Focused, 'Fokus bleibt auf den Reitern');
  finally
    SetModifiers(False, False);
    FForm.Hide;
  end;
end;

procedure TPageControlTests.CloseActions;
var
  PC: TPPGPageControl;
begin
  FForm.Show;
  try
    PC := NewPageControl(3);
    PC.ShowCloseButton := True;
    PC.OnClosing := PageCloseQuery;
    PC.OnClose := PageClose;
    FLog.Clear;
    FCanClose := False;
    TTabsAccess(PC).CloseTab(0);
    CheckEquals('Query:Seite1', FLog.CommaText);
    CheckTrue(PC.Pages[0].TabVisible);
    FCanClose := True;
    FCloseAction := caHide;
    TTabsAccess(PC).CloseTab(0);
    CheckFalse(PC.Pages[0].TabVisible, 'caHide blendet den Reiter aus');
    CheckEquals('Seite2', PC.ActivePage.Caption);
    FCloseAction := caFree;
    TTabsAccess(PC).CloseTab(1);
    CheckEquals(2, PC.PageCount, 'caFree gibt die Seite frei');
    FCloseAction := caNone;
    TTabsAccess(PC).CloseTab(1);
    CheckEquals(2, PC.PageCount);
    CheckTrue(PC.Pages[1].TabVisible, 'caNone tut nichts');
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPageControlTests.CloseHandlerFreeingPageIsSafe;
var
  PC: TPPGPageControl;
begin
  // Audit 08.10.2026: OnClose gab die Seite selbst frei -> Zugriff auf die
  // freigegebene Seite (caHide) bzw. doppelte Freigabe (caFree).
  PC := NewPageControl(3);
  PC.OnClose := PageClose;
  FSelfDelete := True;
  FCloseAction := caHide;
  TTabsAccess(PC).CloseTab(0);
  CheckEquals(2, PC.PageCount, 'caHide nach Free im Ereignis');
  FCloseAction := caFree;
  TTabsAccess(PC).CloseTab(0);
  CheckEquals(1, PC.PageCount, 'caFree nach Free im Ereignis');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPageControlTests.FreedImageListLeavesStrip;
var
  PC: TPPGPageControl;
  IL: TImageList;
begin
  // Audit 08.10.2026: wie beim TabControl
  PC := NewPageControl(2);
  IL := TImageList.Create(FForm);
  PC.Images := IL;
  CheckSame(IL, PC.Strip.Images);
  IL.Free;
  CheckNull(PC.Strip.Images);
  PC.Repaint;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPageControlTests.ShowControlActivatesPage;
var
  PC: TPPGPageControl;
  E: TPPGEdit;
begin
  PC := NewPageControl(3);
  E := TPPGEdit.Create(FForm);
  E.Parent := PC.Pages[2];
  E.Show; // wie der Designer beim Auswaehlen eines verdeckten Controls
  CheckSame(PC.Pages[2], PC.ActivePage);
end;

procedure TPageControlTests.DesignHitTestOnTabsOnly;
var
  PC: TPPGPageControl;
  P: TPoint;
begin
  PC := NewPageControl(2);
  P := CenterOf(PC.TabRect(1));
  CheckEquals(1, PC.Perform(CM_DESIGNHITTEST, 0, MouseLParam(P.X, P.Y)), 'Reiter');
  CheckEquals(0, PC.Perform(CM_DESIGNHITTEST, 0, MouseLParam(PC.Width div 2,
    PC.Height - 20)), 'Seite: der Designer waehlt aus');
end;

procedure TPageControlTests.LoadsTPageControlDfmAndRoundTrips;
const
  // Wie eine echte TPageControl-DFM (Klassennamen ersetzt)
  Dfm =
    'object PC: TPPGPageControl'#13#10 +
    '  Left = 8'#13#10 +
    '  Top = 8'#13#10 +
    '  Width = 300'#13#10 +
    '  Height = 200'#13#10 +
    '  ActivePage = TabSheet2'#13#10 +
    '  TabOrder = 0'#13#10 +
    '  object TabSheet1: TPPGTabSheet'#13#10 +
    '    Caption = ''Erste'''#13#10 +
    '  end'#13#10 +
    '  object TabSheet2: TPPGTabSheet'#13#10 +
    '    Caption = ''Zweite'''#13#10 +
    '    ImageIndex = 1'#13#10 +
    '    ExplicitLeft = 0'#13#10 +
    '    ExplicitTop = 0'#13#10 +
    '    object Edit1: TEdit'#13#10 +
    '      Left = 16'#13#10 +
    '      Top = 16'#13#10 +
    '      Width = 121'#13#10 +
    '      Height = 23'#13#10 +
    '      TabOrder = 0'#13#10 +
    '    end'#13#10 +
    '  end'#13#10 +
    '  object TabSheet3: TPPGTabSheet'#13#10 +
    '    Caption = ''Dritte'''#13#10 +
    '    TabVisible = False'#13#10 +
    '  end'#13#10 +
    'end'#13#10;
var
  PC, PC2: TPPGPageControl;
  S: string;
begin
  PC := TPPGPageControl.Create(FForm);
  PC.Parent := FForm;
  LoadDfm(Dfm, PC);
  CheckEquals(3, PC.PageCount);
  CheckEquals('Zweite', PC.ActivePage.Caption);
  CheckTrue(PC.ActivePage.Visible);
  CheckFalse(PC.Pages[0].Visible);
  CheckEquals(1, PC.Pages[1].ImageIndex);
  CheckEquals(1, PC.Pages[1].ControlCount, 'Edit auf der Seite');
  CheckFalse(PC.Pages[2].TabVisible);
  CheckEquals(2, PC.Strip.Count);
  CheckEquals(1, PC.Strip.Selected);
  S := ComponentToText(PC);
  CheckTrue(Pos('ActivePage = TabSheet2', S) > 0, S);
  CheckTrue((Pos('object TabSheet1', S) > 0) and
    (Pos('object TabSheet1', S) < Pos('object TabSheet2', S)), 'Seitenreihenfolge');
  CheckTrue(Pos('PageIndex', S) = 0, 'PageIndex wird nicht gespeichert');
  // Seiten stehen 4 Zeichen eingerueckt (das Edit darin 6)
  CheckTrue(Pos(#13#10'    Left =', S) = 0, 'Lage der Seiten wird nicht gespeichert');
  PC2 := TPPGPageControl.Create(FForm);
  PC2.Parent := FForm;
  LoadDfm(StringReplace(S, 'object PC:', 'object PC2:', []), PC2);
  CheckEquals(3, PC2.PageCount);
  CheckEquals('Zweite', PC2.ActivePage.Caption);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

{ TTabsAccessibilityTests }

procedure TTabsAccessibilityTests.TabsAreVirtualChildren;
var
  PC: TPPGPageControl;
  Acc: IAccessible;
  Count: Integer;
  V: OleVariant;
  W: WideString;
  L, T, Wd, H: Integer;
  P: TPoint;
begin
  FForm.Show;
  try
    PC := NewPageControl(3);
    PC.Pages[0].Caption := '&Allgemein';
    PC.ActivePageIndex := 1;
    Acc := AccOf(PC);
    CheckEquals(ROLE_SYSTEM_PAGETABLIST, AccRole(Acc));
    CheckEquals(S_OK, Acc.Get_accChildCount(Count));
    // Kind-Fenster (Seiten) zaehlt der Standard-Proxy, dazu die drei Reiter
    CheckTrue(Count >= 3, 'drei Reiter als Kinder');
    CheckEquals(S_OK, Acc.Get_accName(1, W));
    CheckEquals('Allgemein', string(W), 'ohne &');
    CheckEquals(S_OK, Acc.Get_accRole(2, V));
    CheckEquals(ROLE_SYSTEM_PAGETAB, Integer(V));
    CheckEquals(S_OK, Acc.Get_accState(2, V));
    CheckTrue(Integer(V) and STATE_SYSTEM_SELECTED <> 0, 'aktiver Reiter');
    Acc.Get_accState(1, V);
    CheckTrue(Integer(V) and STATE_SYSTEM_SELECTED = 0);
    CheckEquals(S_OK, Acc.Get_accSelection(V));
    CheckEquals(2, Integer(V));
    CheckEquals(S_OK, Acc.accLocation(L, T, Wd, H, 3));
    P := PC.ClientToScreen(PC.TabRect(2).TopLeft);
    CheckEquals(P.X, L);
    CheckEquals(P.Y, T);
    P := PC.ClientToScreen(CenterOf(PC.TabRect(2)));
    CheckEquals(S_OK, Acc.accHitTest(P.X, P.Y, V));
    CheckEquals(3, Integer(V));
    Acc := AccOf(PC.Pages[1]);
    CheckEquals(ROLE_SYSTEM_PROPERTYPAGE, AccRole(Acc));
  finally
    FForm.Hide;
  end;
end;

procedure TTabsAccessibilityTests.TabDefaultActionSelectsAsynchronously;
var
  T: TPPGTabControl;
  Acc: IAccessible;
  W: WideString;
begin
  FForm.Show;
  try
    T := NewTabControl('Eins,Zwei,Drei');
    Acc := AccOf(T);
    CheckEquals(S_OK, Acc.Get_accDefaultAction(3, W));
    CheckEquals(SPPGAccSelect, string(W));
    CheckEquals(S_OK, Acc.accDoDefaultAction(3));
    CheckEquals(0, T.TabIndex, 'nicht im COM-Aufruf');
    PumpPosted(T.Handle);
    CheckEquals(2, T.TabIndex);
    CheckEquals('Changing,Change', FLog.CommaText, 'wie ein Klick');
  finally
    FForm.Hide;
  end;
end;

{ TPhase4cPaintTests }

procedure TPhase4cPaintTests.IndicatorUnderSelectedTab;
var
  T: TPPGTabControl;
  Bmp: TBitmap;
  R: TRect;
  P: TPoint;
begin
  T := NewTabControl('Eins,Zwei,Drei');
  T.TabIndex := 1;
  R := T.Strip.IndicatorRect;
  CheckFalse(IsRectEmpty(R));
  CheckTrue((R.Left >= T.TabRect(1).Left) and (R.Right <= T.TabRect(1).Right),
    'Unterstrich unter dem gewaehlten Reiter');
  Bmp := RenderToBitmap(T);
  try
    P := CenterOf(R);
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[P.X, P.Y], T.Appearance.FocusColor) < 60,
      'Unterstrich in Akzentfarbe');
  finally
    Bmp.Free;
  end;
  // Classic: kein Unterstrich (Reiter haengt mit der Seite zusammen)
  T.Preset := PPGPresetClassic;
  Bmp := RenderToBitmap(T);
  try
    CheckTrue(ColorDist(Bmp.Canvas.Pixels[P.X, P.Y], T.Appearance.FocusColor) > 100);
  finally
    Bmp.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPhase4cPaintTests.IndicatorSlidesToNewTab;
var
  T: TPPGTabControl;
  A, B, M: TRect;
begin
  FForm.Show;
  try
    T := NewTabControl('Eins,Zwei,Drei');
    T.Animation.Enabled := True;
    T.Animation.Duration := 300;
    T.Animation.RespectSystemSettings := False;
    A := T.Strip.IndicatorRect;
    ClickTab(T, 2);
    CheckTrue(T.Strip.IndicatorMoving, 'Unterstrich gleitet');
    PumpTimers(100);
    M := T.Strip.IndicatorRect;
    CheckTrue(M.Left > A.Left, 'unterwegs');
    PumpTimers(400);
    CheckFalse(T.Strip.IndicatorMoving);
    B := T.Strip.IndicatorRect;
    CheckTrue(M.Left < B.Left, 'zwischen alter und neuer Lage');
    CheckTrue((B.Left >= T.TabRect(2).Left) and (B.Right <= T.TabRect(2).Right), 'am Ziel');
    T.Animation.Enabled := False;
    T.TabIndex := 0;
    CheckFalse(T.Strip.IndicatorMoving, 'ohne Animation sofort');
  finally
    FForm.Hide;
  end;
end;

procedure TPhase4cPaintTests.SelectedTabMergesWithPage;
const
  Presets: array[0..1] of string = (PPGPresetModernFlat, PPGPresetClassic);
var
  PC: TPPGPageControl;
  Bmp: TBitmap;
  I, Y: Integer;
  Sel, Other: TRect;
  Gdi: Boolean;
begin
  PC := NewPageControl(3);
  for Gdi := False to True do
    for I := 0 to High(Presets) do
    begin
      TPPGRendererRegistry.ForceGdiFallback := Gdi;
      PC.Preset := Presets[I];
      Bmp := RenderToBitmap(PC);
      try
        Sel := PC.TabRect(0);
        Other := PC.TabRect(1);
        Y := PC.Strip.StripRect.Bottom; // erste Zeile der Seite (ihr Rahmen)
        CheckTrue(ColorDist(Bmp.Canvas.Pixels[(Sel.Left + Sel.Right) div 2 - 8, Y],
          PC.PageColor) < 30, Presets[I] + ': unter dem gewaehlten Reiter kein Rahmen');
        CheckTrue(ColorDist(Bmp.Canvas.Pixels[(Other.Left + Other.Right) div 2, Y],
          PC.PageColor) > 30, Presets[I] + ': unter anderen Reitern der Seitenrahmen');
      finally
        Bmp.Free;
      end;
    end;
  TPPGRendererRegistry.ForceGdiFallback := False;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPhase4cPaintTests.AllVariantsPaintWithoutErrors;
const
  Presets: array[0..1] of string = (PPGPresetModernFlat, PPGPresetClassic);
var
  PC: TPPGPageControl;
  T: TPPGTabControl;
  Gdi: Boolean;
  I, J: Integer;
begin
  FForm.Show;
  try
    PC := NewPageControl(12);
    T := NewTabControl('a,b,c');
    T.Top := 220;
    for Gdi := False to True do
      for I := 0 to High(Presets) do
        for J := 0 to 5 do
        begin
          TPPGRendererRegistry.ForceGdiFallback := Gdi;
          PC.Preset := Presets[I];
          T.Preset := Presets[I];
          PC.TabPosition := TTabPosition(J mod 2);
          PC.ShowCloseButton := J >= 2;
          PC.BiDiMode := TBiDiMode(Ord(J = 3) * Ord(bdRightToLeft));
          PC.Enabled := J <> 4;
          PC.Width := 120 + J * 60; // mit Ueberlauf
          if PC.CanFocus then
            PC.SetFocus;
          RenderToBitmap(PC).Free;
          PC.Height := 10; // kleiner als die Reiter
          RenderToBitmap(PC).Free;
          PC.Height := 200;
          T.TabWidth := J * 20;
          T.TabHeight := J * 8;
          RenderToBitmap(T).Free;
          PC.Enabled := True;
        end;
  finally
    TPPGRendererRegistry.ForceGdiFallback := False;
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPhase4cPaintTests.NoHandleOrMemoryLeaks;

  procedure Cycle;
  var
    I: Integer;
    PC: TPPGPageControl;
    T: TPPGTabControl;
  begin
    for I := 1 to 10 do
    begin
      PC := NewPageControl(4);
      PC.OnChange := nil;
      PC.OnChanging := nil;
      PC.ShowCloseButton := True;
      ClickTab(PC, 2);
      RenderToBitmap(PC).Free;
      AccOf(PC);
      PC.Pages[1].Free;
      PC.Free; // gibt die restlichen Seiten frei
      T := NewTabControl('a,b,c,d');
      T.OnChange := nil;
      T.OnChanging := nil;
      ClickTab(T, 3);
      RenderToBitmap(T).Free;
      T.Free;
      FLog.Clear;
    end;
  end;

var
  Gdi0, User0: Cardinal;
  M0, M1: NativeUInt;
begin
  FForm.Show;
  try
    Cycle;
    Gdi0 := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
    User0 := GetGuiResources(GetCurrentProcess, GR_USEROBJECTS);
    M0 := AllocatedBytes;
    Cycle;
    Cycle;
    M1 := AllocatedBytes;
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS) <= Gdi0 + 2, 'GDI-Handles wachsen');
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_USEROBJECTS) <= User0 + 2, 'USER-Handles wachsen');
    CheckTrue(M1 <= M0 + 1024, Format('Speicher waechst: %d -> %d', [M0, M1]));
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterClass(TEdit); // fuer die TPageControl-DFM mit Edit
  RegisterTest('Phase4c', TTabControlTests.Suite);
  RegisterTest('Phase4c', TPageControlTests.Suite);
  RegisterTest('Phase4c', TTabsAccessibilityTests.Suite);
  RegisterTest('Phase4c', TPhase4cPaintTests.Suite);

end.
