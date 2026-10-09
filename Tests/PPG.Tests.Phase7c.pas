unit PPG.Tests.Phase7c;

{$WARN SYMBOL_PLATFORM OFF}

{ Tests fuer Phase 7c: TPPGNavigationView, TPPGBreadcrumb, TPPGToolBar,
  TPPGStatusBar. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, {$IF CompilerVersion >= 24.0}System.Actions,{$IFEND} Vcl.ActnList, Vcl.StdActns, Vcl.Controls, Vcl.Forms,
  Vcl.Graphics, Vcl.ComCtrls,
  PPG.Types, PPG.Consts, PPG.Render.Intf, PPG.Render.Registry, PPG.Controls.Base,
  PPG.NavigationView, PPG.Breadcrumb, PPG.ToolBar, PPG.StatusBar, PPG.PageControl,
  PPG.Accessibility, PPG.Tests.Controls, PPG.Tests.Phase4b;

type
  TPhase7cTestCase = class(TComboTestCase)
  protected
    FEvents: TStringList;
    FDrawn: Integer;
    FCanvasOk: Boolean;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure LogSelection(Sender: TObject);
    procedure LogInvoked(Sender: TObject; Item: TPPGNavItem);
    procedure LogCrumb(Sender: TObject; Index: Integer);
    procedure LogTool(Sender: TObject; Item: TPPGToolItem);
    procedure LogToolClick(Sender: TObject);
    procedure LogExecute(Sender: TObject);
    procedure ToolFreesSelf(Sender: TObject);
    procedure DrawPanel(StatusBar: TPPGStatusBar; Panel: TPPGStatusPanel; const Rect: TRect);
    function NewNav: TPPGNavigationView;
    procedure Click7c(C: TWinControl; const R: TRect);
    procedure Key7c(C: TWinControl; VK: Word; Shift: TShiftState = []);
    function RoundTrip7c(C: TComponent): TComponent;
  end;

  TNavigationViewTests = class(TPhase7cTestCase)
  published
    procedure RowsFollowExpansionAndFooter;
    procedure ClickSelectsAndFiresEvents;
    procedure ParentItemTogglesInsteadOfSelecting;
    procedure CodeSelectionExpandsParents;
    procedure CompactModeHidesChildrenAndText;
    procedure IndicatorFollowsSelection;
    procedure PageControlFollowsSelection;
    procedure KeyboardNavigation;
    procedure AutoModeCompactsWhenNarrow;
    procedure DeleteSelectedItemIsSafe;
    procedure RoundTripKeepsNestedItems;
    procedure Accessibility;
    procedure PostedActionIgnoresChangedRows;
  end;

  TBreadcrumbTests = class(TPhase7cTestCase)
  private
    procedure NavigateCrumb(Sender: TObject; Index: Integer);
  published
    procedure PathAndClick;
    procedure TruncateOnClick;
    procedure TruncateKeepsPathSetByHandler;
    procedure OverflowWhenNarrow;
    procedure KeyboardAndAccessibility;
  end;

  TToolBarTests = class(TPhase7cTestCase)
  published
    procedure ClickButtonAndCheckGroup;
    procedure ActionLinksProperties;
    procedure OverflowWhenNarrow;
    procedure KeyboardAndAccessibility;
    procedure RoundTripKeepsItems;
    procedure HandlerRemovesOwnButton;
  end;

  TStatusBarTests = class(TPhase7cTestCase)
  published
    procedure LoadsTStatusBarDfm;
    procedure LastPanelFillsRest;
    procedure AutoHintShowsHint;
    procedure OwnerDrawGetsCanvas;
    procedure SizeGripOnlyWhenSizable;
    procedure PanelKindsForScreenReader;
  end;

  TPhase7cPaintTests = class(TPhase7cTestCase)
  published
    procedure PaintAllPresetsAndModes;
    procedure NoHandleOrMemoryLeaks;
  end;

implementation

uses
  Winapi.oleacc, PPG.Theme;

type
  TWinAccess7c = class(TWinControl);
  TNavAccess = class(TPPGNavigationView);
  TCrumbAccess = class(TPPGBreadcrumb);
  TToolAccess = class(TPPGToolBar);
  TStatusAccess = class(TPPGStatusBar);
  TCC7c = class(TPPGCustomControl);

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
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

function LoadDfm7c(const Text: string): TComponent;
var
  Src, Bin: TMemoryStream;
  B: TBytes;
begin
  Src := TMemoryStream.Create;
  Bin := TMemoryStream.Create;
  try
    B := TEncoding.UTF8.GetBytes(Text);
    if Length(B) > 0 then
      Src.WriteBuffer(B[0], Length(B));
    Src.Position := 0;
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    Result := Bin.ReadComponent(nil);
  finally
    Bin.Free;
    Src.Free;
  end;
end;

{ TPhase7cTestCase }

procedure TPhase7cTestCase.SetUp;
begin
  inherited SetUp;
  FEvents := TStringList.Create;
  FDrawn := 0;
  FCanvasOk := False;
end;

procedure TPhase7cTestCase.TearDown;
begin
  FreeAndNil(FEvents);
  inherited TearDown;
end;

procedure TPhase7cTestCase.LogSelection(Sender: TObject);
begin
  if TPPGNavigationView(Sender).Selected <> nil then
    FEvents.Add('sel:' + TPPGNavigationView(Sender).Selected.Caption)
  else
    FEvents.Add('sel:nil');
end;

procedure TPhase7cTestCase.LogInvoked(Sender: TObject; Item: TPPGNavItem);
begin
  FEvents.Add('inv:' + Item.Caption);
end;

procedure TPhase7cTestCase.LogCrumb(Sender: TObject; Index: Integer);
begin
  FEvents.Add('crumb:' + IntToStr(Index));
end;

procedure TPhase7cTestCase.ToolFreesSelf(Sender: TObject);
begin
  FEvents.Add('free:' + TPPGToolItem(Sender).Caption);
  TPPGToolItem(Sender).Free;
end;

procedure TPhase7cTestCase.LogTool(Sender: TObject; Item: TPPGToolItem);
begin
  FEvents.Add('tool:' + Item.Caption);
end;

procedure TPhase7cTestCase.LogToolClick(Sender: TObject);
begin
  FEvents.Add('click');
end;

procedure TPhase7cTestCase.LogExecute(Sender: TObject);
begin
  FEvents.Add('exec');
end;

procedure TPhase7cTestCase.DrawPanel(StatusBar: TPPGStatusBar; Panel: TPPGStatusPanel;
  const Rect: TRect);
begin
  Inc(FDrawn);
  FCanvasOk := (StatusBar.Canvas <> nil) and (StatusBar.Canvas.Handle <> 0);
  StatusBar.Canvas.TextOut(Rect.Left + 2, Rect.Top + 2, 'X');
end;

function TPhase7cTestCase.NewNav: TPPGNavigationView;
var
  Docs: TPPGNavItem;
begin
  Result := TPPGNavigationView.Create(FForm);
  Result.Parent := FForm;
  Result.Animation.Enabled := False;
  Result.Height := 400;
  Result.Items.AddItem('Start', PPGNavIconHome, 0);
  Result.Items.AddItem('Post', PPGNavIconMail, 1).BadgeCount := 3;
  Result.Items.AddHeader('Bereiche');
  Docs := Result.Items.AddItem('Dokumente', PPGNavIconDocument);
  Docs.Items.AddItem('Briefe', 0, 2);
  Docs.Items.AddItem('Rechnungen');
  Result.Items.AddSeparator;
  Result.Items.AddItem('Einstellungen', PPGNavIconSettings).Footer := True;
  Result.OnSelectionChange := LogSelection;
  Result.OnItemInvoked := LogInvoked;
  Result.HandleNeeded;
end;

procedure TPhase7cTestCase.Click7c(C: TWinControl; const R: TRect);
var
  X, Y: Integer;
begin
  X := (R.Left + R.Right) div 2;
  Y := (R.Top + R.Bottom) div 2;
  C.Perform(WM_MOUSEMOVE, 0, MouseLParam(X, Y));
  C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(X, Y));
  C.Perform(WM_LBUTTONUP, 0, MouseLParam(X, Y));
end;

procedure TPhase7cTestCase.Key7c(C: TWinControl; VK: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := VK;
  TWinAccess7c(C).KeyDown(K, Shift);
end;

function TPhase7cTestCase.RoundTrip7c(C: TComponent): TComponent;
var
  M: TMemoryStream;
begin
  M := TMemoryStream.Create;
  try
    M.WriteComponent(C);
    M.Position := 0;
    Result := M.ReadComponent(nil);
  finally
    M.Free;
  end;
end;

{ TNavigationViewTests }

procedure TNavigationViewTests.RowsFollowExpansionAndFooter;
var
  N: TPPGNavigationView;
begin
  N := NewNav;
  CheckEquals(6, N.VisibleRowCount, 'Start, Post, Kopf, Dokumente, Trenner + Fuss');
  CheckEquals('Einstellungen', N.VisibleRow(5).Caption);
  CheckTrue(N.RowRect(5).Bottom >= N.Height - 8, 'Fussbereich unten');
  N.FindItem('Dokumente').Expanded := True;
  CheckEquals(8, N.VisibleRowCount);
  CheckEquals('Briefe', N.VisibleRow(4).Caption);
  CheckEquals(1, N.VisibleRow(4).Level);
  N.FindItem('Post').Visible := False;
  CheckEquals(7, N.VisibleRowCount);
  CheckTrue(N.FindItem('Rechnungen') <> nil, 'FindItem sucht in Untereintraegen');
end;

procedure TNavigationViewTests.ClickSelectsAndFiresEvents;
var
  N: TPPGNavigationView;
begin
  FForm.Show;
  try
    N := NewNav;
    Click7c(N, N.RowRect(1));
    CheckTrue(N.Selected = N.FindItem('Post'));
    CheckEquals('inv:Post,sel:Post', FEvents.CommaText);
    FEvents.Clear;
    Click7c(N, N.RowRect(1));
    CheckEquals('inv:Post', FEvents.CommaText, 'gleiche Auswahl: nur Invoked');
    FEvents.Clear;
    Click7c(N, N.RowRect(2));
    CheckEquals(0, FEvents.Count, 'Ueberschrift ist nicht klickbar');
    N.FindItem('Start').Enabled := False;
    Click7c(N, N.RowRect(0));
    CheckEquals(0, FEvents.Count, 'deaktiviert');
    Click7c(N, N.RowRect(5));
    CheckTrue(N.Selected = N.FindItem('Einstellungen'), 'Fusseintrag');
  finally
    FForm.Hide;
  end;
end;

procedure TNavigationViewTests.ParentItemTogglesInsteadOfSelecting;
var
  N: TPPGNavigationView;
begin
  FForm.Show;
  try
    N := NewNav;
    Click7c(N, N.RowRect(3));
    CheckTrue(N.FindItem('Dokumente').Expanded);
    CheckTrue(N.Selected = nil, 'Elterneintrag waehlt nicht');
    CheckEquals('inv:Dokumente', FEvents.CommaText);
    Click7c(N, N.RowRect(4));
    CheckTrue(N.Selected = N.FindItem('Briefe'));
    Click7c(N, N.RowRect(3));
    CheckFalse(N.FindItem('Dokumente').Expanded, 'zuklappen');
    CheckTrue(N.Selected = N.FindItem('Briefe'), 'Auswahl bleibt');
  finally
    FForm.Hide;
  end;
end;

procedure TNavigationViewTests.CodeSelectionExpandsParents;
var
  N: TPPGNavigationView;
begin
  N := NewNav;
  N.Selected := N.FindItem('Rechnungen');
  CheckTrue(N.FindItem('Dokumente').Expanded, 'Vorfahr aufgeklappt');
  CheckTrue(N.RowOfItem(N.Selected) >= 0);
  CheckEquals(0, FEvents.Count, 'Code ohne Ereignisse');
  N.Selected := nil;
  CheckTrue(N.Selected = nil);
end;

procedure TNavigationViewTests.CompactModeHidesChildrenAndText;
var
  N: TPPGNavigationView;
begin
  N := NewNav;
  N.Selected := N.FindItem('Briefe');
  N.IsPaneOpen := False;
  CheckEquals(48, N.Width, 'kompakte Breite');
  CheckEquals(5, N.VisibleRowCount, 'ohne Ueberschrift und Untereintraege');
  CheckEquals(-1, N.RowOfItem(N.FindItem('Briefe')));
  N.IsPaneOpen := True;
  CheckEquals(280, N.Width);
  CheckEquals(8, N.VisibleRowCount);
  N.DisplayMode := pdmLeftCompact;
  CheckFalse(N.IsPaneOpen);
  CheckEquals(48, N.Width);
end;

procedure TNavigationViewTests.IndicatorFollowsSelection;
var
  N: TPPGNavigationView;
  R: TRect;
begin
  N := NewNav;
  N.Selected := N.FindItem('Post');
  R := N.RowRect(1);
  CheckEquals((R.Top + R.Bottom) div 2, N.IndicatorPos);
  N.Selected := N.FindItem('Rechnungen');
  N.IsPaneOpen := False;
  // Verborgener Eintrag: Indikator am sichtbaren Vorfahren
  R := N.RowRect(N.RowOfItem(N.FindItem('Dokumente')));
  CheckEquals((R.Top + R.Bottom) div 2, N.IndicatorPos);
end;

procedure TNavigationViewTests.PageControlFollowsSelection;
var
  N: TPPGNavigationView;
  P: TPPGPageControl;
  I: Integer;
  S: TPPGTabSheet;
begin
  FForm.Show;
  try
    P := TPPGPageControl.Create(FForm);
    P.Parent := FForm;
    P.Align := alClient;
    for I := 0 to 2 do
    begin
      S := TPPGTabSheet.Create(FForm);
      S.PageControl := P;
      S.Caption := 'S' + IntToStr(I);
    end;
    N := NewNav;
    N.PageControl := P;
    Click7c(N, N.RowRect(1));
    CheckEquals(1, P.ActivePageIndex);
    N.Selected := N.FindItem('Briefe');
    CheckEquals(2, P.ActivePageIndex, 'auch bei Auswahl im Code');
    P.Free;
    CheckTrue(N.PageControl = nil, 'FreeNotification');
    Click7c(N, N.RowRect(0));
  finally
    FForm.Hide;
  end;
end;

procedure TNavigationViewTests.KeyboardNavigation;
var
  N: TPPGNavigationView;
begin
  N := NewNav;
  N.Selected := N.FindItem('Start');
  FEvents.Clear;
  Key7c(N, VK_DOWN);
  CheckTrue(N.FocusItem = N.FindItem('Post'));
  Key7c(N, VK_DOWN);
  CheckTrue(N.FocusItem = N.FindItem('Dokumente'), 'Ueberschrift uebersprungen');
  Key7c(N, VK_RIGHT);
  CheckTrue(N.FindItem('Dokumente').Expanded);
  Key7c(N, VK_DOWN);
  CheckTrue(N.FocusItem = N.FindItem('Briefe'));
  Key7c(N, VK_LEFT);
  CheckTrue(N.FocusItem = N.FindItem('Dokumente'), 'Links: zum Elterneintrag');
  Key7c(N, VK_END);
  CheckTrue(N.FocusItem = N.FindItem('Einstellungen'));
  Key7c(N, VK_RETURN);
  CheckTrue(N.Selected = N.FindItem('Einstellungen'));
  CheckEquals('inv:Dokumente,inv:Einstellungen,sel:Einstellungen', FEvents.CommaText);
end;

procedure TNavigationViewTests.AutoModeCompactsWhenNarrow;
var
  N: TPPGNavigationView;
begin
  FForm.ClientWidth := 900;
  N := NewNav;
  N.DisplayMode := pdmAuto;
  CheckEquals(280, N.Width, 'breit genug');
  FForm.ClientWidth := 500;
  CheckEquals(48, N.Width, 'zu schmal: kompakt');
  FForm.ClientWidth := 900;
  CheckEquals(280, N.Width);
end;

procedure TNavigationViewTests.DeleteSelectedItemIsSafe;
var
  N: TPPGNavigationView;
begin
  N := NewNav;
  N.Selected := N.FindItem('Briefe');
  N.FindItem('Dokumente').Free;
  CheckTrue(N.Selected = nil, 'Auswahl im geloeschten Zweig');
  CheckEquals(5, N.VisibleRowCount, 'Start, Post, Kopf, Trenner, Fuss');
  RenderToBitmap(N).Free;
  N.Items.Clear;
  CheckEquals(0, N.VisibleRowCount);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TNavigationViewTests.RoundTripKeepsNestedItems;
var
  N, N2: TPPGNavigationView;
begin
  N := NewNav;
  N.PaneTitle := 'Demo';
  N.OpenPaneLength := 300;
  N2 := RoundTrip7c(N) as TPPGNavigationView;
  try
    CheckEquals(6, N2.Items.Count);
    CheckEquals(2, N2.FindItem('Dokumente').Items.Count);
    CheckEquals(2, N2.FindItem('Briefe').PageIndex);
    CheckEquals(3, N2.FindItem('Post').BadgeCount);
    CheckTrue(N2.FindItem('Einstellungen').Footer);
    CheckTrue(N2.Items[2].Kind = nikHeader);
    CheckEquals(PPGNavIconHome, N2.Items[0].IconChar);
    CheckEquals('Demo', N2.PaneTitle);
    CheckEquals(300, N2.OpenPaneLength);
  finally
    N2.Free;
  end;
end;

procedure TNavigationViewTests.Accessibility;
var
  N: TPPGNavigationView;
  A: IPPGAccessibleChildren;
begin
  N := NewNav;
  CheckTrue(Supports(N, IPPGAccessibleChildren, A));
  CheckEquals(7, A.AccChildCount, '6 Zeilen + Menue-Knopf');
  CheckEquals('Post (3)', A.AccChildName(2));
  CheckEquals(ROLE_SYSTEM_OUTLINEITEM, A.AccChildRole(1));
  CheckEquals(ROLE_SYSTEM_STATICTEXT, A.AccChildRole(3));
  CheckEquals(ROLE_SYSTEM_SEPARATOR, A.AccChildRole(5));
  CheckEquals(ROLE_SYSTEM_PUSHBUTTON, A.AccChildRole(7));
  CheckEquals(SPPGNavMenu, A.AccChildName(7));
  CheckTrue(A.AccChildState(4) and STATE_SYSTEM_COLLAPSED <> 0);
  CheckEquals(SPPGAccExpand, A.AccChildDefaultAction(4));
  N.Selected := N.FindItem('Post');
  CheckEquals(2, A.AccSelectedChild);
  CheckEquals(ROLE_SYSTEM_OUTLINE, TNavAccess(N).AccRole);
end;

procedure TNavigationViewTests.PostedActionIgnoresChangedRows;
var
  N: TPPGNavigationView;
  A: IPPGAccessibleChildren;
begin
  // Audit 08.10.2026: Gepostet wurde nur die Zeile; aenderten sich die
  // Zeilen bis zur Verarbeitung, wurde ein anderes Item ausgeloest.
  N := NewNav;
  CheckTrue(Supports(N, IPPGAccessibleChildren, A));
  FEvents.Clear;
  A.AccChildDoDefault(2); // Post
  N.FindItem('Start').Free; // Zeile 2 ist jetzt der Kopf "Bereiche"
  Application.ProcessMessages;
  CheckEquals(-1, FEvents.IndexOf('inv:Post'), FEvents.Text);
  CheckEquals(-1, FEvents.IndexOf('inv:Bereiche'), FEvents.Text);
  // Unveraendert: wirkt wie bisher
  A.AccChildDoDefault(1); // jetzt Post
  Application.ProcessMessages;
  CheckTrue(FEvents.IndexOf('inv:Post') >= 0, FEvents.Text);
  A := nil;
end;

{ TBreadcrumbTests }

function NewCrumb(F: TForm; T: TPhase7cTestCase): TPPGBreadcrumb;
begin
  Result := TPPGBreadcrumb.Create(F);
  Result.Parent := F;
  Result.SetBounds(10, 10, 500, 30);
  Result.SetPath('C:\Daten\Bilder\2026');
  Result.OnItemClick := T.LogCrumb;
  Result.HandleNeeded;
end;

procedure TBreadcrumbTests.PathAndClick;
var
  B: TPPGBreadcrumb;
begin
  FForm.Show;
  try
    B := NewCrumb(FForm, Self);
    CheckEquals(4, B.Items.Count);
    CheckEquals('Daten', B.Items[1]);
    CheckEquals(0, B.FirstVisible, 'passt');
    Click7c(B, B.PartRect(1));
    CheckEquals('crumb:1', FEvents.CommaText);
    CheckEquals(4, B.Items.Count, 'ohne TruncateOnClick bleibt der Pfad');
    Click7c(B, B.PartRect(3));
    CheckEquals('crumb:1,crumb:3', FEvents.CommaText, 'letztes Segment klickbar');
  finally
    FForm.Hide;
  end;
end;

procedure TBreadcrumbTests.TruncateOnClick;
var
  B: TPPGBreadcrumb;
begin
  B := NewCrumb(FForm, Self);
  B.TruncateOnClick := True;
  Key7c(B, VK_HOME);
  Key7c(B, VK_RIGHT);
  Key7c(B, VK_RETURN);
  CheckEquals('crumb:1', FEvents.CommaText);
  CheckEquals(2, B.Items.Count, 'folgende Segmente entfernt');
  CheckEquals('Daten', B.Items[1]);
end;

procedure TBreadcrumbTests.NavigateCrumb(Sender: TObject; Index: Integer);
begin
  FEvents.Add('crumb:' + IntToStr(Index));
  TPPGBreadcrumb(Sender).SetPath('X:\A\B\C\D');
end;

procedure TBreadcrumbTests.TruncateKeepsPathSetByHandler;
var
  B: TPPGBreadcrumb;
begin
  // Audit 08.10.2026: Setzte der Handler einen neuen Pfad, wurde dieser
  // anschliessend mit dem alten Index gekuerzt.
  B := NewCrumb(FForm, Self);
  B.TruncateOnClick := True;
  B.OnItemClick := NavigateCrumb;
  Key7c(B, VK_HOME);
  Key7c(B, VK_RIGHT);
  Key7c(B, VK_RETURN);
  CheckEquals('crumb:1', FEvents.CommaText);
  CheckEquals(5, B.Items.Count, 'neuer Pfad bleibt vollstaendig');
  CheckEquals('X:', B.Items[0]);
  CheckEquals('D', B.Items[4]);
end;

procedure TBreadcrumbTests.OverflowWhenNarrow;
var
  B: TPPGBreadcrumb;
begin
  B := NewCrumb(FForm, Self);
  B.SetPath('Wurzel\Ein sehr langer Ordnername\Noch ein langer Ordner\Unterordner\Ziel');
  B.Width := 200;
  CheckTrue(B.FirstVisible > 0, 'vordere Segmente im Menue');
  CheckFalse(IsRectEmpty(B.PartRect(-2)), 'Ueberlauf-Knopf');
  CheckTrue(IsRectEmpty(B.PartRect(0)), 'erstes Segment verborgen');
  CheckFalse(IsRectEmpty(B.PartRect(4)), 'letztes bleibt');
  CheckTrue(B.PartRect(4).Right <= B.Width);
  B.Width := 2000;
  CheckEquals(0, B.FirstVisible);
end;

procedure TBreadcrumbTests.KeyboardAndAccessibility;
var
  B: TPPGBreadcrumb;
  A: IPPGAccessibleChildren;
begin
  B := NewCrumb(FForm, Self);
  TCrumbAccess(B).DoEnter;
  CheckEquals(3, B.FocusPart, 'Fokus auf dem aktuellen Ort');
  Key7c(B, VK_LEFT);
  CheckEquals(2, B.FocusPart);
  CheckTrue(Supports(B, IPPGAccessibleChildren, A));
  CheckEquals(4, A.AccChildCount);
  CheckEquals('Bilder', A.AccChildName(3));
  CheckEquals(ROLE_SYSTEM_LINK, A.AccChildRole(1));
  CheckTrue(A.AccChildState(4) and STATE_SYSTEM_SELECTED <> 0, 'aktueller Ort');
  B.Width := 120;
  CheckTrue(B.FirstVisible > 0);
  CheckEquals(ROLE_SYSTEM_BUTTONMENU, A.AccChildRole(1));
  CheckEquals(SPPGMoreOptions, A.AccChildName(1));
end;

{ TToolBarTests }

function NewTool(F: TForm; T: TPhase7cTestCase): TPPGToolBar;
begin
  Result := TPPGToolBar.Create(F);
  Result.Parent := F;
  Result.Width := 600;
  Result.Items.AddButton('Neu', $E710, T.LogToolClick);
  Result.Items.AddCheck('Liste', $EA37, 1).Down := True;
  Result.Items.AddCheck('Kacheln', $ECA5, 1);
  Result.Items.AddSeparator;
  Result.Items.AddCheck('Fett', $E8DD);
  Result.OnItemClick := T.LogTool;
  Result.HandleNeeded;
end;

procedure TToolBarTests.ClickButtonAndCheckGroup;
var
  T: TPPGToolBar;
begin
  FForm.Show;
  try
    T := NewTool(FForm, Self);
    Click7c(T, T.ItemRect(0));
    CheckEquals('click,tool:Neu', FEvents.CommaText, 'OnClick vor OnItemClick');
    FEvents.Clear;
    Click7c(T, T.ItemRect(2));
    CheckTrue(T.Items[2].Down);
    CheckFalse(T.Items[1].Down, 'Gruppe schliesst sich aus');
    Click7c(T, T.ItemRect(2));
    CheckTrue(T.Items[2].Down, 'eingerasteter Gruppen-Button bleibt');
    Click7c(T, T.ItemRect(4));
    CheckTrue(T.Items[4].Down);
    Click7c(T, T.ItemRect(4));
    CheckFalse(T.Items[4].Down, 'ohne Gruppe schaltet um');
    FEvents.Clear;
    Click7c(T, T.ItemRect(3));
    CheckEquals(0, FEvents.Count, 'Trenner');
    T.Items[0].Enabled := False;
    Click7c(T, T.ItemRect(0));
    CheckEquals(0, FEvents.Count, 'deaktiviert');
    T.Items[1].Down := True;
    CheckEquals(0, FEvents.Count, 'Code ohne Ereignis');
  finally
    FForm.Hide;
  end;
end;

procedure TToolBarTests.ActionLinksProperties;
var
  T: TPPGToolBar;
  AL: TActionList;
  A: TAction;
  It: TPPGToolItem;
begin
  AL := TActionList.Create(FForm);
  A := TAction.Create(FForm);
  A.ActionList := AL;
  A.Caption := 'Speichern';
  A.Hint := 'Datei speichern';
  A.OnExecute := LogExecute;
  T := NewTool(FForm, Self);
  It := T.Items.Add;
  It.Action := A;
  CheckEquals('Speichern', It.Caption);
  CheckEquals('Datei speichern', It.Hint);
  A.Enabled := False;
  CheckFalse(It.Enabled, 'Action steuert Enabled');
  A.Caption := 'Sichern';
  CheckEquals('Sichern', It.Caption);
  A.Enabled := True;
  T.ClickItem(It);
  CheckEquals('exec,tool:Sichern', FEvents.CommaText);
  A.Visible := False;
  CheckFalse(It.Visible);
  A.Free;
  CheckTrue(It.Action = nil, 'Action freigegeben');
end;

procedure TToolBarTests.OverflowWhenNarrow;
var
  T: TPPGToolBar;
begin
  T := NewTool(FForm, Self);
  CheckFalse(T.HasOverflow);
  T.Align := alNone; // sonst folgt die Breite dem Formular
  T.Width := 150;
  CheckTrue(T.HasOverflow);
  CheckFalse(IsRectEmpty(T.OverflowRect));
  CheckTrue(T.IsInOverflow(4), 'letzter im Menue');
  CheckFalse(T.IsInOverflow(0), 'erster sichtbar');
  CheckTrue(T.OverflowRect.Right <= T.Width);
  T.ShowCaptions := False;
  T.Width := 600;
  CheckFalse(T.HasOverflow);
  CheckTrue(T.ItemRect(0).Right - T.ItemRect(0).Left <= 40, 'nur Symbol');
end;

procedure TToolBarTests.KeyboardAndAccessibility;
var
  T: TPPGToolBar;
  A: IPPGAccessibleChildren;
begin
  T := NewTool(FForm, Self);
  TToolAccess(T).DoEnter;
  CheckEquals(0, T.FocusPart);
  Key7c(T, VK_RIGHT);
  CheckEquals(1, T.FocusPart);
  Key7c(T, VK_END);
  CheckEquals(4, T.FocusPart);
  Key7c(T, VK_LEFT);
  CheckEquals(2, T.FocusPart, 'Trenner uebersprungen');
  Key7c(T, VK_SPACE);
  CheckTrue(T.Items[2].Down);
  CheckTrue(Supports(T, IPPGAccessibleChildren, A));
  CheckEquals(5, A.AccChildCount);
  CheckEquals(ROLE_SYSTEM_PUSHBUTTON, A.AccChildRole(1));
  CheckEquals(ROLE_SYSTEM_CHECKBUTTON, A.AccChildRole(2));
  CheckEquals(ROLE_SYSTEM_SEPARATOR, A.AccChildRole(4));
  CheckTrue(A.AccChildState(3) and STATE_SYSTEM_CHECKED <> 0);
  CheckEquals(SPPGAccToggle, A.AccChildDefaultAction(2));
  CheckEquals(ROLE_SYSTEM_TOOLBAR, TToolAccess(T).AccRole);
end;

procedure TToolBarTests.HandlerRemovesOwnButton;
var
  T: TPPGToolBar;
begin
  // Audit 08.10.2026: OnItemClick bekam einen im OnClick freigegebenen
  // Button; Hover/gedrueckt blieben nach dem Loeschen an der alten Position.
  FForm.Show;
  try
    T := NewTool(FForm, Self);
    T.Items[0].OnClick := ToolFreesSelf;
    FEvents.Clear;
    Click7c(T, T.ItemRect(0));
    CheckEquals('free:Neu', FEvents.CommaText, 'kein OnItemClick mit freigegebenem Item');
    CheckEquals(4, T.Items.Count);
    CheckEquals(-1, T.HotPart, 'Hover nach dem Loeschen zurueckgesetzt');
    RenderToBitmap(T).Free;
  finally
    FForm.Hide;
  end;
end;

procedure TToolBarTests.RoundTripKeepsItems;
var
  T, T2: TPPGToolBar;
begin
  T := NewTool(FForm, Self);
  T.Items[0].Hint := 'Neues Dokument';
  T.ShowCaptions := False;
  T2 := RoundTrip7c(T) as TPPGToolBar;
  try
    CheckEquals(5, T2.Items.Count);
    CheckTrue(T2.Items[1].Style = tisCheck);
    CheckEquals(1, T2.Items[1].GroupIndex);
    CheckTrue(T2.Items[1].Down);
    CheckTrue(T2.Items[3].Style = tisSeparator);
    CheckEquals('Neues Dokument', T2.Items[0].Hint);
    CheckEquals($E710, T2.Items[0].IconChar);
    CheckFalse(T2.ShowCaptions);
  finally
    T2.Free;
  end;
end;

{ TStatusBarTests }

procedure TStatusBarTests.LoadsTStatusBarDfm;
var
  S: TPPGStatusBar;
begin
  S := LoadDfm7c(
    'object StatusBar1: TPPGStatusBar'#13#10 +
    '  Left = 0'#13#10 +
    '  Top = 280'#13#10 +
    '  Width = 400'#13#10 +
    '  Height = 19'#13#10 +
    '  Panels = <'#13#10 +
    '    item'#13#10 +
    '      Text = ''Bereit'''#13#10 +
    '      Width = 120'#13#10 +
    '    end'#13#10 +
    '    item'#13#10 +
    '      Alignment = taCenter'#13#10 +
    '      Bevel = pbNone'#13#10 +
    '      Style = psOwnerDraw'#13#10 +
    '      Width = 50'#13#10 +
    '    end>'#13#10 +
    '  SimplePanel = False'#13#10 +
    '  SizeGrip = False'#13#10 +
    '  AutoHint = True'#13#10 +
    'end') as TPPGStatusBar;
  try
    CheckEquals(2, S.Panels.Count);
    CheckEquals('Bereit', S.Panels[0].Text);
    CheckEquals(120, S.Panels[0].Width);
    CheckTrue(S.Panels[1].Style = psOwnerDraw);
    CheckTrue(S.Panels[1].Bevel = pbNone);
    CheckTrue(S.Panels[1].Alignment = taCenter);
    CheckFalse(S.SizeGrip);
    CheckTrue(S.AutoHint);
    CheckTrue(S.Align = alBottom);
  finally
    S.Free;
  end;
end;

procedure TStatusBarTests.LastPanelFillsRest;
var
  S: TPPGStatusBar;
  R: TRect;
begin
  S := TPPGStatusBar.Create(FForm);
  S.Parent := FForm;
  S.Width := 400;
  S.Panels.Add.Width := 100;
  S.Panels.Add.Width := 60;
  R := S.PanelRect(1);
  CheckEquals(100, R.Left);
  CheckEquals(S.Width, R.Right, 'letztes Panel bis zum Rand');
  CheckEquals(1, S.PanelAt(300, 5));
  S.SimplePanel := True;
  CheckTrue(IsRectEmpty(S.PanelRect(0)));
  CheckEquals(0, TStatusAccess(S).AccChildCount);
end;

procedure TStatusBarTests.AutoHintShowsHint;
var
  S: TPPGStatusBar;
  H: THintAction;
begin
  S := TPPGStatusBar.Create(FForm);
  S.Parent := FForm;
  S.Panels.Add;
  S.AutoHint := True;
  H := THintAction.Create(nil);
  try
    H.Hint := 'Speichert die Datei';
    CheckTrue(S.ExecuteAction(H));
    CheckEquals('Speichert die Datei', S.Panels[0].Text);
    S.SimplePanel := True;
    H.Hint := 'Einfach';
    S.ExecuteAction(H);
    CheckEquals('Einfach', S.SimpleText);
    S.AutoHint := False;
    H.Hint := 'Nein';
    CheckFalse(S.ExecuteAction(H));
  finally
    H.Free;
  end;
end;

procedure TStatusBarTests.OwnerDrawGetsCanvas;
var
  S: TPPGStatusBar;
begin
  S := TPPGStatusBar.Create(FForm);
  S.Parent := FForm;
  S.Panels.Add.Style := psOwnerDraw;
  S.OnDrawPanel := DrawPanel;
  CheckTrue(S.Canvas = nil, 'nur waehrend OnDrawPanel');
  FForm.Show;
  try
    RenderToBitmap(S).Free;
  finally
    FForm.Hide;
  end;
  CheckEquals(1, FDrawn);
  CheckTrue(FCanvasOk);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TStatusBarTests.SizeGripOnlyWhenSizable;
var
  S: TPPGStatusBar;
  R: TRect;
  P: TPoint;
begin
  FForm.Show;
  try
    FForm.BorderStyle := bsSizeable;
    S := TPPGStatusBar.Create(FForm);
    S.Parent := FForm;
    S.HandleNeeded;
    CheckTrue(S.SizeGripActive);
    R := S.SizeGripRect;
    P := S.ClientToScreen(Point(R.Right - 3, R.Bottom - 3));
    CheckEquals(HTBOTTOMRIGHT, S.Perform(WM_NCHITTEST, 0, MakeLParam(Word(P.X), Word(P.Y))));
    S.Align := alTop;
    CheckFalse(S.SizeGripActive, 'nicht unten');
    S.Align := alBottom;
    FForm.BorderStyle := bsDialog;
    CheckFalse(S.SizeGripActive, 'Formular nicht sizable');
  finally
    FForm.Hide;
    FForm.BorderStyle := bsSizeable;
  end;
end;

procedure TStatusBarTests.PanelKindsForScreenReader;
var
  S: TPPGStatusBar;
  A: IPPGAccessibleChildren;
  P: TPPGStatusPanel;
begin
  S := TPPGStatusBar.Create(FForm);
  S.Parent := FForm;
  S.AllowMarkup := True;
  S.Panels.Add.Text := '<b>Zeile</b> 12';
  P := S.Panels.Add;
  P.Kind := spkProgress;
  P.Progress := 100; // Audit 5b: ueber 100 wird abgelehnt (Test in Audit45)
  P.Hint := 'Export';
  P := S.Panels.Add;
  P.Kind := spkBadge;
  P.BadgeCount := 5;
  CheckEquals(100, S.Panels[1].Progress);
  CheckTrue(Supports(S, IPPGAccessibleChildren, A));
  CheckEquals(3, A.AccChildCount);
  CheckEquals('Zeile 12', A.AccChildName(1), 'ohne Markup');
  CheckEquals('Export: 100 %', A.AccChildName(2));
  CheckEquals(ROLE_SYSTEM_PROGRESSBAR, A.AccChildRole(2));
  CheckEquals('5', A.AccChildName(3));
  CheckEquals(ROLE_SYSTEM_STATUSBAR, TStatusAccess(S).AccRole);
end;

{ TPhase7cPaintTests }

procedure TPhase7cPaintTests.PaintAllPresetsAndModes;
var
  Names: TStringList;
  P, I: Integer;
  Dark, Gdi: Boolean;
  L: array of TWinControl;
  S: TPPGStatusBar;
  B: TPPGBreadcrumb;
begin
  Names := TStringList.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    FForm.Show;
    try
      for P := 0 to Names.Count - 1 do
        for Dark := False to True do
          for Gdi := False to True do
          begin
            if Dark then
              TPPGTheme.Mode := tmDark
            else
              TPPGTheme.Mode := tmLight;
            TPPGRendererRegistry.ForceGdiFallback := Gdi;
            SetLength(L, 5);
            L[0] := NewNav;
            TPPGNavigationView(L[0]).Selected := TPPGNavigationView(L[0]).FindItem('Briefe');
            L[1] := NewNav;
            TPPGNavigationView(L[1]).IsPaneOpen := False;
            B := NewCrumb(FForm, Self);
            B.Width := 120;
            L[2] := B;
            L[3] := NewTool(FForm, Self);
            S := TPPGStatusBar.Create(FForm);
            S.Parent := FForm;
            S.Panels.Add.Text := 'Bereit';
            S.Panels.Add.Kind := spkProgress;
            S.Panels[1].Progress := 40;
            S.Panels.Add.Kind := spkBadge;
            S.Panels[2].BadgeCount := 2;
            L[4] := S;
            for I := 0 to High(L) do
            begin
              TCC7c(L[I]).Preset := Names[P];
              RenderToBitmap(L[I]).Free;
            end;
            for I := 0 to High(L) do
              L[I].Free;
          end;
    finally
      FForm.Hide;
      TPPGTheme.Mode := tmLight;
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  finally
    Names.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPhase7cPaintTests.NoHandleOrMemoryLeaks;

  procedure Cycle;
  var
    I: Integer;
    C: TWinControl;
  begin
    for I := 1 to 5 do
    begin
      C := NewNav;
      TPPGNavigationView(C).Selected := TPPGNavigationView(C).FindItem('Briefe');
      RenderToBitmap(C).Free;
      C.Free;
      C := NewCrumb(FForm, Self);
      RenderToBitmap(C).Free;
      C.Free;
      C := NewTool(FForm, Self);
      RenderToBitmap(C).Free;
      C.Free;
      C := TPPGStatusBar.Create(FForm);
      C.Parent := FForm;
      TPPGStatusBar(C).Panels.Add.Text := 'x';
      RenderToBitmap(C).Free;
      C.Free;
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
    CheckTrue(M1 <= M0 + 4096, Format('Speicher waechst: %d -> %d', [M0, M1]));
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterClasses([TPPGNavigationView, TPPGBreadcrumb, TPPGToolBar, TPPGStatusBar]);
  RegisterTest('Phase7c', TNavigationViewTests.Suite);
  RegisterTest('Phase7c', TBreadcrumbTests.Suite);
  RegisterTest('Phase7c', TToolBarTests.Suite);
  RegisterTest('Phase7c', TStatusBarTests.Suite);
  RegisterTest('Phase7c', TPhase7cPaintTests.Suite);

end.
