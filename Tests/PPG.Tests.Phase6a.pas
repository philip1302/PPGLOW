unit PPG.Tests.Phase6a;

{$WARN SYMBOL_PLATFORM OFF}

{ Tests fuer Phase 6a: TPPGListBox, TPPGCheckListBox, ComboBox-Ausbau
  (reiche Eintraege, Filtern beim Tippen). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Vcl.ImgList,
  PPG.Types, PPG.Consts, PPG.Items, PPG.Render.Intf, PPG.Render.Registry,
  PPG.Controls.Base, PPG.Controls.ItemList, PPG.ListBox, PPG.CheckListBox,
  PPG.ComboBox, PPG.Exceptions, PPG.Accessibility, PPG.Tests.Controls, PPG.Tests.Phase4b;

type
  TListTestCase = class(TControlTestCase)
  protected
    FClicks: Integer;
    FChecks: Integer;
    FReorders: Integer;
    FAllowReorder: Boolean;
    FDraws: Integer;
    FDrawCanvasOk: Boolean;
    // 1 = Items.Clear, 2 = ersten Eintrag loeschen (im OnClick/OnClickCheck)
    FMutateOnClick: Integer;
    FMutateOnCheck: Integer;
    procedure Mutate(Sender: TObject; Mode: Integer);
    procedure SetUp; override;
    procedure CountClick(Sender: TObject);
    procedure CountCheck(Sender: TObject);
    procedure DoReorder(Sender: TObject; FromIndex, ToIndex: Integer; var Allow: Boolean);
    procedure VirtualData(Control: TWinControl; Index: Integer; var Data: string);
    procedure DrawItem(Control: TWinControl; Index: Integer; Rect: TRect;
      State: TOwnerDrawState);
    function NewList(const CommaItems: string = ''): TPPGListBox;
    function NewCheckList(const CommaItems: string = ''): TPPGCheckListBox;
    procedure ClickAt(C: TWinControl; X, Y: Integer; Shift: TShiftState = []);
    procedure ClickItem(L: TPPGCustomItemList; Index: Integer; Shift: TShiftState = []);
    procedure Key(C: TWinControl; VK: Word; Shift: TShiftState = []);
  end;

  TListBoxTests = class(TListTestCase)
  published
    procedure DefaultsMatchTListBox;
    procedure InsertDeleteMovesSelection;
    procedure ObjectsSurviveSortAndMove;
    procedure LoadsTListBoxDfm;
    procedure RoundTripKeepsItemsAndSelection;
    procedure ClickSelectsAndFiresOnClick;
    procedure CodeSetsWithoutEvents;
    procedure ExtendedSelectWithShiftAndCtrl;
    procedure SimpleMultiSelectToggles;
    procedure KeyboardNavigation;
    procedure TypeAheadFindsItem;
    procedure ReorderByDragging;
    procedure ReorderCanBeRefused;
    procedure ReorderAfterItemsChangeInClick;
    procedure VirtualMillionItems;
    procedure ItemsExGroupsAndDetail;
    procedure OwnerDrawGetsCanvas;
    procedure DeleteSelectedAndClear;
    procedure Accessibility;
    procedure PaintAllPresetsAndModes;
    procedure NoHandleOrMemoryLeaks;
  end;

  TCheckListBoxTests = class(TListTestCase)
  published
    procedure ClickOnBoxToggles;
    procedure SpaceTogglesWithGrayedCycle;
    procedure CodeSetsWithoutOnClickCheck;
    procedure HeaderIsNotSelectable;
    procedure CheckAllRespectsDisabled;
    procedure StateMovesWithItems;
    procedure ClickCheckClearingItems;
    procedure ItemsExStates;
    procedure LoadsTCheckListBoxDfm;
    procedure AccessibilityRoles;
  end;

  TComboExTests = class(TComboTestCase)
  published
    procedure ItemsExFillItems;
    procedure ItemsExImagesRaiseRowHeight;
    procedure FilterByPrefix;
    procedure FilterContains;
    procedure FilterWithoutMatchClosesList;
    procedure FilterClearedOnDropDown;
    procedure SortedItemsExKeepsIndices;
    procedure FilterFollowsItemChanges;
  end;

implementation

uses
  Winapi.oleacc, PPG.Theme, PPG.Selection;

type
  TItemListAccess = class(TPPGCustomItemList);
  TComboAccess6 = class(TPPGComboBox);

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
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

function LoadDfm(const Text: string): TComponent;
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

{ TListTestCase }

procedure TListTestCase.SetUp;
begin
  inherited SetUp;
  // DUnit verwendet die Testobjekte wieder (Leak-Lauf: zwei Laeufe)
  FClicks := 0;
  FChecks := 0;
  FReorders := 0;
  FAllowReorder := False;
  FDraws := 0;
  FDrawCanvasOk := False;
  FMutateOnClick := 0;
  FMutateOnCheck := 0;
end;

procedure TListTestCase.Mutate(Sender: TObject; Mode: Integer);
var
  S: TStrings;
begin
  if Sender is TPPGCheckListBox then
    S := TPPGCheckListBox(Sender).Items
  else
    S := TPPGListBox(Sender).Items;
  case Mode of
    1: S.Clear;
    2: S.Delete(0);
  end;
end;

procedure TListTestCase.CountClick(Sender: TObject);
begin
  Inc(FClicks);
  Mutate(Sender, FMutateOnClick);
end;

procedure TListTestCase.CountCheck(Sender: TObject);
begin
  Inc(FChecks);
  Mutate(Sender, FMutateOnCheck);
end;

procedure TListTestCase.DoReorder(Sender: TObject; FromIndex, ToIndex: Integer;
  var Allow: Boolean);
begin
  Inc(FReorders);
  Allow := FAllowReorder;
end;

procedure TListTestCase.VirtualData(Control: TWinControl; Index: Integer; var Data: string);
begin
  Data := 'V' + IntToStr(Index);
end;

procedure TListTestCase.DrawItem(Control: TWinControl; Index: Integer; Rect: TRect;
  State: TOwnerDrawState);
var
  C: TCanvas;
begin
  Inc(FDraws);
  C := TPPGListBox(Control).Canvas;
  FDrawCanvasOk := (C <> nil) and (C.Handle <> 0);
  C.TextOut(Rect.Left + 2, Rect.Top + 2, TPPGListBox(Control).Items[Index]);
end;

function TListTestCase.NewList(const CommaItems: string): TPPGListBox;
begin
  Result := TPPGListBox.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 200, 160);
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  if CommaItems <> '' then
    Result.Items.CommaText := CommaItems;
  Result.OnClick := CountClick;
  Result.HandleNeeded;
end;

function TListTestCase.NewCheckList(const CommaItems: string): TPPGCheckListBox;
begin
  Result := TPPGCheckListBox.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 200, 160);
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  if CommaItems <> '' then
    Result.Items.CommaText := CommaItems;
  Result.OnClick := CountClick;
  Result.OnClickCheck := CountCheck;
  Result.HandleNeeded;
end;

procedure TListTestCase.ClickAt(C: TWinControl; X, Y: Integer; Shift: TShiftState);
var
  Keys: WPARAM;
begin
  Keys := MK_LBUTTON;
  if ssShift in Shift then
    Keys := Keys or MK_SHIFT;
  if ssCtrl in Shift then
    Keys := Keys or MK_CONTROL;
  C.Perform(WM_MOUSEMOVE, 0, MouseLParam(X, Y));
  C.Perform(WM_LBUTTONDOWN, Keys, MouseLParam(X, Y));
  C.Perform(WM_LBUTTONUP, Keys and not MK_LBUTTON, MouseLParam(X, Y));
end;

procedure TListTestCase.ClickItem(L: TPPGCustomItemList; Index: Integer; Shift: TShiftState);
var
  P: TPoint;
begin
  P := CenterOf(L.ItemRect(Index));
  // Strg/Umschalt liest die VCL ueber GetKeyState - im Test per KeyDataToShiftState
  // nicht steuerbar; deshalb die Auswahl-Logik direkt mit Shift ansprechen
  if Shift <> [] then
  begin
    L.Selection.Click(Index, Shift);
    Exit;
  end;
  ClickAt(L, P.X, P.Y);
end;

procedure TListTestCase.Key(C: TWinControl; VK: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := VK;
  TItemListAccess(C).KeyDown(K, Shift);
end;

{ TListBoxTests }

procedure TListBoxTests.DefaultsMatchTListBox;
var
  L: TPPGListBox;
begin
  L := NewList;
  CheckEquals(-1, L.ItemIndex);
  CheckEquals(0, L.Count);
  CheckTrue(L.Style = lbStandard);
  CheckFalse(L.MultiSelect);
  CheckTrue(L.ExtendedSelect);
  CheckFalse(L.Sorted);
  CheckTrue(L.AutoComplete);
  CheckTrue(L.TabStop);
  CheckEquals(-1, L.SelCount, 'SelCount ohne MultiSelect = -1 wie TListBox');
  CheckEquals(Integer(clWindow), Integer(L.Color));
  L.Items.Add('A');
  CheckEquals(1, L.Count);
end;

procedure TListBoxTests.InsertDeleteMovesSelection;
var
  L: TPPGListBox;
begin
  L := NewList('A,B,C,D,E');
  L.ItemIndex := 2;
  L.Items.Insert(0, 'X');
  CheckEquals(3, L.ItemIndex, 'Einfuegen davor schiebt die Auswahl');
  CheckEquals('C', L.Items[L.ItemIndex]);
  L.Items.Delete(0);
  CheckEquals(2, L.ItemIndex);
  L.Items.Delete(2);
  CheckFalse(L.Selected[2], 'geloeschter Eintrag war gewaehlt');
  L.MultiSelect := True;
  L.Selected[0] := True;
  L.Selected[3] := True;
  L.Items.Insert(1, 'Y');
  CheckTrue(L.Selected[0]);
  CheckTrue(L.Selected[4], 'Mehrfachauswahl wandert mit');
  CheckFalse(L.Selected[1]);
end;

procedure TListBoxTests.ObjectsSurviveSortAndMove;
var
  L: TPPGListBox;
  O1, O2: TObject;
begin
  O1 := TObject.Create;
  O2 := TObject.Create;
  try
    L := NewList;
    L.Items.AddObject('Zebra', O1);
    L.Items.AddObject('Affe', O2);
    CheckTrue(L.Items.Objects[0] = O1);
    CheckEquals(1, L.Items.IndexOfObject(O2));
    L.Items.Move(0, 1);
    CheckEquals('Zebra', L.Items[1]);
    CheckTrue(L.Items.Objects[1] = O1, 'Objekt wandert beim Verschieben mit');
    L.Sorted := True;
    CheckEquals('Affe', L.Items[0]);
    CheckTrue(L.Items.Objects[0] = O2, 'Objekt wandert beim Sortieren mit');
    try
      L.Items.Move(0, 1);
      Fail('Verschieben in sortierter Liste muss werfen');
    except
      on E: EPPGError do
        CheckEquals(2, L.Count, 'nichts verloren');
    end;
  finally
    O2.Free;
    O1.Free;
  end;
end;

procedure TListBoxTests.LoadsTListBoxDfm;
var
  L: TPPGListBox;
begin
  // DFM einer TListBox mit ersetztem Klassennamen (inkl. ItemHeight = 13)
  L := LoadDfm(
    'object ListBox1: TPPGListBox'#13#10 +
    '  Left = 8'#13#10 +
    '  Top = 8'#13#10 +
    '  Width = 121'#13#10 +
    '  Height = 97'#13#10 +
    '  ItemHeight = 13'#13#10 +
    '  Items.Strings = ('#13#10 +
    '    ''Eins'''#13#10 +
    '    ''Zwei'''#13#10 +
    '    ''Drei'')'#13#10 +
    '  MultiSelect = True'#13#10 +
    '  Columns = 0'#13#10 +
    '  IntegralHeight = False'#13#10 +
    '  TabOrder = 0'#13#10 +
    'end') as TPPGListBox;
  try
    CheckEquals(3, L.Count);
    CheckEquals('Zwei', L.Items[1]);
    CheckTrue(L.MultiSelect);
    CheckEquals(13, L.ItemHeight);
    L.Parent := FForm;
    CheckTrue(L.ItemRect(0).Bottom - L.ItemRect(0).Top > 13,
      'ItemHeight ist eine Mindesthoehe (Zeile nicht zu eng)');
  finally
    L.Free;
  end;
end;

procedure TListBoxTests.RoundTripKeepsItemsAndSelection;
var
  L, L2: TPPGListBox;
  S: TMemoryStream;
begin
  L := NewList('A,B,C');
  L.ItemsEx.Add('Reich', 2).Detail := 'Detail';
  L.ItemsEx.Clear;
  L.ItemIndex := 1;
  L.AllowReorder := True;
  S := TMemoryStream.Create;
  try
    S.WriteComponent(L);
    S.Position := 0;
    L2 := TPPGListBox.Create(nil);
    try
      S.ReadComponent(L2);
      L2.Parent := FForm;
      CheckEquals(3, L2.Count);
      CheckEquals(1, L2.ItemIndex, 'ItemIndex nach Items angewendet');
      CheckTrue(L2.AllowReorder);
    finally
      L2.Free;
    end;
  finally
    S.Free;
  end;
end;

procedure TListBoxTests.ClickSelectsAndFiresOnClick;
var
  L: TPPGListBox;
begin
  FForm.Show;
  try
    L := NewList('A,B,C,D');
    ClickItem(L, 2);
    CheckEquals(2, L.ItemIndex);
    CheckEquals(1, FClicks, 'OnClick bei Anwender-Auswahl');
    CheckTrue(L.Focused, 'Klick fokussiert');
  finally
    FForm.Hide;
  end;
end;

procedure TListBoxTests.CodeSetsWithoutEvents;
var
  L: TPPGListBox;
begin
  L := NewList('A,B,C,D');
  L.ItemIndex := 3;
  L.Items.Add('E');
  L.Items.Delete(0);
  CheckEquals(0, FClicks, 'Code loest kein OnClick aus');
  L.ItemIndex := 99;
  CheckEquals(-1, L.ItemIndex, 'ungueltiger Index = keine Auswahl');
end;

procedure TListBoxTests.ExtendedSelectWithShiftAndCtrl;
var
  L: TPPGListBox;
begin
  L := NewList('A,B,C,D,E');
  L.MultiSelect := True;
  ClickItem(L, 1);
  ClickItem(L, 3, [ssShift]);
  CheckEquals(3, L.SelCount, 'Umschalt: Bereich');
  ClickItem(L, 2, [ssCtrl]);
  CheckEquals(2, L.SelCount, 'Strg: umschalten');
  CheckFalse(L.Selected[2]);
  L.SelectAll;
  CheckEquals(5, L.SelCount);
  L.ClearSelection;
  CheckEquals(0, L.SelCount);
end;

procedure TListBoxTests.SimpleMultiSelectToggles;
var
  L: TPPGListBox;
begin
  L := NewList('A,B,C');
  L.MultiSelect := True;
  L.ExtendedSelect := False;
  ClickItem(L, 0);
  ClickItem(L, 2);
  CheckEquals(2, L.SelCount, 'Klick schaltet um (LBS_MULTIPLESEL)');
  ClickItem(L, 0);
  CheckEquals(1, L.SelCount);
end;

procedure TListBoxTests.KeyboardNavigation;
var
  L: TPPGListBox;
  I: Integer;
begin
  L := NewList;
  for I := 0 to 49 do
    L.Items.Add('Eintrag ' + IntToStr(I));
  L.ItemIndex := 0;
  Key(L, VK_DOWN);
  CheckEquals(1, L.ItemIndex);
  CheckEquals(1, FClicks, 'Tastatur loest OnClick aus');
  Key(L, VK_END);
  CheckEquals(49, L.ItemIndex);
  CheckFalse(IsRectEmpty(L.ItemRect(49)), 'Ende wird sichtbar');
  Key(L, VK_HOME);
  CheckEquals(0, L.ItemIndex);
  Key(L, VK_NEXT);
  CheckTrue(L.ItemIndex > 1, 'Bild ab blaettert');
  Key(L, VK_UP);
  Key(L, VK_PRIOR);
  CheckEquals(0, L.ItemIndex);
end;

procedure TListBoxTests.TypeAheadFindsItem;
var
  L: TPPGListBox;
  K: Char;
begin
  L := NewList('Belgien,Daenemark,Deutschland,Estland');
  K := 'd';
  TItemListAccess(L).KeyPress(K);
  CheckEquals(1, L.ItemIndex, 'erster Treffer');
  K := 'e';
  TItemListAccess(L).KeyPress(K);
  CheckEquals(2, L.ItemIndex, '"de" -> Deutschland');
  L.AutoComplete := False;
  Sleep(1100);
  K := 'e';
  TItemListAccess(L).KeyPress(K);
  CheckEquals(2, L.ItemIndex, 'AutoComplete aus: keine Suche');
end;

procedure TListBoxTests.ReorderByDragging;
var
  L: TPPGListBox;
  P0, P2: TPoint;
  R: TRect;
begin
  FForm.Show;
  try
    L := NewList('A,B,C,D');
    L.AllowReorder := True;
    L.OnReorder := DoReorder;
    FAllowReorder := True;
    P0 := CenterOf(L.ItemRect(0));
    R := L.ItemRect(2);
    P2 := Point(P0.X, R.Bottom - 2); // untere Haelfte von C: danach einfuegen
    L.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P0.X, P0.Y));
    L.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P0.X, P0.Y + 20));
    L.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P2.X, P2.Y));
    CheckEquals(3, L.DropRow, 'Einfuegemarke nach C');
    L.Perform(WM_LBUTTONUP, 0, MouseLParam(P2.X, P2.Y));
    CheckEquals(1, FReorders);
    CheckEquals('B,C,A,D', L.Items.CommaText);
    CheckEquals(2, L.ItemIndex, 'verschobener Eintrag bleibt gewaehlt');
    CheckEquals(-1, L.DropRow);
  finally
    FForm.Hide;
  end;
end;

procedure TListBoxTests.ReorderCanBeRefused;
var
  L: TPPGListBox;
  P0, P2: TPoint;
begin
  FForm.Show;
  try
    L := NewList('A,B,C,D');
    L.AllowReorder := True;
    L.OnReorder := DoReorder;
    FAllowReorder := False;
    P0 := CenterOf(L.ItemRect(0));
    P2 := CenterOf(L.ItemRect(3));
    L.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P0.X, P0.Y));
    L.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P2.X, P2.Y));
    L.Perform(WM_LBUTTONUP, 0, MouseLParam(P2.X, P2.Y));
    CheckEquals(1, FReorders);
    CheckEquals('A,B,C,D', L.Items.CommaText, 'abgelehnt: unveraendert');
  finally
    FForm.Hide;
  end;
end;

procedure TListBoxTests.ReorderAfterItemsChangeInClick;
var
  L: TPPGListBox;
  P0, P2: TPoint;
  R: TRect;
begin
  // Audit 08.10.2026: OnClick aendert die Eintraege, der Anwender zieht
  // weiter. Vorher zeigte der gemerkte Index ins Leere (FItems.Move warf).
  FForm.Show;
  try
    L := NewList('A,B,C,D');
    L.AllowReorder := True;
    L.OnReorder := DoReorder;
    FAllowReorder := True;
    FMutateOnClick := 1;
    P0 := CenterOf(L.ItemRect(1));
    L.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P0.X, P0.Y));
    CheckEquals(0, L.Items.Count, 'OnClick hat geleert');
    L.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P0.X, P0.Y + 30));
    L.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P0.X, P0.Y + 60));
    L.Perform(WM_LBUTTONUP, 0, MouseLParam(P0.X, P0.Y + 60));
    CheckEquals(0, FReorders, 'kein Verschieben ohne Eintrag');
    CheckEquals(-1, L.DropRow);
    // Loeschen vor dem gezogenen Eintrag: der Index wandert mit
    L.Items.CommaText := 'A,B,C,D';
    FMutateOnClick := 2;
    P0 := CenterOf(L.ItemRect(2));
    L.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P0.X, P0.Y));
    FMutateOnClick := 0;
    CheckEquals('B,C,D', L.Items.CommaText);
    R := L.ItemRect(2);
    P2 := Point(P0.X, R.Bottom - 2); // untere Haelfte von D
    L.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P0.X, P0.Y + 20));
    L.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P2.X, P2.Y));
    L.Perform(WM_LBUTTONUP, 0, MouseLParam(P2.X, P2.Y));
    CheckEquals('B,D,C', L.Items.CommaText, 'C (jetzt Index 1) ans Ende');
  finally
    FForm.Hide;
  end;
end;

procedure TListBoxTests.VirtualMillionItems;
var
  L: TPPGListBox;
  T: Cardinal;
  Bmp: TBitmap;
begin
  FForm.Show;
  try
    L := NewList;
    L.Style := lbVirtual;
    L.OnData := VirtualData;
    T := GetTickCount;
    L.Count := 1000000;
    L.ItemIndex := 999999;
    Bmp := RenderToBitmap(L);
    Bmp.Free;
    CheckTrue(GetTickCount - T < 1000, 'eine Million Eintraege ohne Verzoegerung');
    CheckEquals(1000000, L.Count);
    CheckFalse(IsRectEmpty(L.ItemRect(999999)), 'letzter Eintrag sichtbar');
    CheckEquals(999999, L.ItemAtPos(CenterOf(L.ItemRect(999999)), True));
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    FForm.Hide;
  end;
end;

procedure TListBoxTests.ItemsExGroupsAndDetail;
var
  L: TPPGListBox;
  It: TPPGItem;
  HPlain, HDetail: Integer;
  R: TRect;
begin
  L := NewList('A,B');
  HPlain := L.ItemRect(0).Bottom - L.ItemRect(0).Top;
  It := L.ItemsEx.Add('Eins');
  It.Group := 'G1';
  It.Detail := 'Detailzeile';
  It := L.ItemsEx.Add('Zwei');
  It.Group := 'G1';
  It := L.ItemsEx.Add('Drei');
  It.Group := 'G2';
  CheckEquals(3, L.Count, 'ItemsEx ist die Quelle');
  CheckTrue(L.ItemStartsGroup(0));
  CheckFalse(L.ItemStartsGroup(1));
  CheckTrue(L.ItemStartsGroup(2));
  HDetail := L.ItemRect(1).Bottom - L.ItemRect(1).Top;
  CheckTrue(HDetail > HPlain, 'zweizeilige Eintraege');
  R := L.ItemRect(0);
  CheckEquals(-1, L.ItemAtPos(Point(R.Left + 20, R.Top - 3), True), 'Klick auf die Ueberschrift ist kein Eintrag');
  L.ItemsEx.Clear;
  CheckEquals(2, L.Count, 'ohne ItemsEx wieder Items');
end;

procedure TListBoxTests.OwnerDrawGetsCanvas;
var
  L: TPPGListBox;
  Bmp: TBitmap;
begin
  L := NewList('A,B,C');
  L.Style := lbOwnerDrawFixed;
  L.OnDrawItem := DrawItem;
  Bmp := RenderToBitmap(L);
  Bmp.Free;
  CheckEquals(3, FDraws, 'OnDrawItem je sichtbarem Eintrag');
  CheckTrue(FDrawCanvasOk, 'Canvas mit Handle waehrend OnDrawItem');
  CheckTrue(L.Canvas <> nil);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TListBoxTests.DeleteSelectedAndClear;
var
  L: TPPGListBox;
begin
  L := NewList('A,B,C,D');
  L.MultiSelect := True;
  L.Selected[1] := True;
  L.Selected[3] := True;
  L.DeleteSelected;
  CheckEquals('A,C', L.Items.CommaText);
  CheckEquals(0, L.SelCount);
  L.Clear;
  CheckEquals(0, L.Count);
end;

procedure TListBoxTests.Accessibility;
var
  L: TPPGListBox;
  A: IPPGAccessibleChildren;
  M: IPPGAccessibleMultiSelection;
  Sel: TArray<Integer>;
begin
  L := NewList('Eins,Zwei,Drei');
  CheckTrue(Supports(L, IPPGAccessibleChildren, A));
  CheckTrue(Supports(L, IPPGAccessibleMultiSelection, M));
  CheckEquals(3, A.AccChildCount);
  CheckEquals('Zwei', A.AccChildName(2));
  CheckEquals(ROLE_SYSTEM_LISTITEM, A.AccChildRole(2));
  L.ItemIndex := 1;
  CheckTrue(A.AccChildState(2) and STATE_SYSTEM_SELECTED <> 0);
  CheckEquals(2, A.AccSelectedChild);
  L.MultiSelect := True;
  L.ClearSelection;
  L.Selected[0] := True;
  L.Selected[2] := True;
  Sel := M.AccSelectedChildren;
  CheckEquals(2, Length(Sel));
  CheckEquals(1, Sel[0]);
  CheckEquals(3, Sel[1]);
  CheckTrue(TItemListAccess(L).AccState and STATE_SYSTEM_EXTSELECTABLE <> 0);
end;

procedure TListBoxTests.PaintAllPresetsAndModes;
var
  Names: TStringList;
  P: Integer;
  Dark, Gdi: Boolean;
  L: TPPGListBox;
  Bmp: TBitmap;
  R: TRect;
  Bg, SelPx: TColor;
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
            L := NewList('Eins,Zwei,Drei,Vier');
            L.Preset := Names[P];
            L.ItemIndex := 1;
            Bmp := RenderToBitmap(L);
            try
              R := L.ItemRect(1);
              Bg := Bmp.Canvas.Pixels[R.Right - 3, L.ItemRect(3).Bottom + 4];
              SelPx := Bmp.Canvas.Pixels[R.Right - 20, (R.Top + R.Bottom) div 2];
              CheckTrue(ColorDist(Bg, SelPx) > 6, Format('%s dunkel=%s gdi=%s: Auswahl sichtbar',
                [Names[P], System.SysUtils.BoolToStr(Dark, True), System.SysUtils.BoolToStr(Gdi, True)]));
            finally
              Bmp.Free;
            end;
            L.Free;
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

procedure TListBoxTests.NoHandleOrMemoryLeaks;

  procedure Cycle;
  var
    I: Integer;
    L: TPPGListBox;
    C: TPPGCheckListBox;
  begin
    for I := 1 to 10 do
    begin
      L := NewList('A,B,C,D,E,F,G,H');
      L.ItemsEx.Add('X', 0).Group := 'G';
      L.MultiSelect := True;
      L.SelectAll;
      RenderToBitmap(L).Free;
      L.Free;
      C := NewCheckList('A,B,C');
      C.Checked[1] := True;
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
    CheckTrue(M1 <= M0 + 2048, Format('Speicher waechst: %d -> %d', [M0, M1]));
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

{ TCheckListBoxTests }

procedure TCheckListBoxTests.ClickOnBoxToggles;
var
  C: TPPGCheckListBox;
  R: TRect;
begin
  FForm.Show;
  try
    C := NewCheckList('A,B,C');
    R := C.ItemRect(1);
    // Kaestchen am Zeilenanfang
    ClickAt(C, R.Left + 12 + 8, (R.Top + R.Bottom) div 2);
    CheckTrue(C.Checked[1], 'Klick auf das Kaestchen');
    CheckEquals(1, FChecks, 'OnClickCheck');
    CheckEquals(1, C.ItemIndex, 'Eintrag wird auch gewaehlt');
    ClickAt(C, R.Right - 10, (R.Top + R.Bottom) div 2);
    CheckTrue(C.Checked[1], 'Klick auf den Text schaltet nicht um');
    CheckEquals(1, FChecks);
  finally
    FForm.Hide;
  end;
end;

procedure TCheckListBoxTests.ClickCheckClearingItems;
var
  C: TPPGCheckListBox;
  R: TRect;
begin
  // Audit 08.10.2026: OnClickCheck leert die Liste; danach arbeitete die
  // Maus-Behandlung mit dem alten Index weiter (Auswahl, Ziehen).
  FForm.Show;
  try
    C := NewCheckList('A,B,C');
    FMutateOnCheck := 1;
    R := C.ItemRect(2);
    ClickAt(C, R.Left + 12 + 8, (R.Top + R.Bottom) div 2);
    CheckEquals(1, FChecks);
    CheckEquals(0, C.Items.Count);
    CheckEquals(-1, C.ItemIndex, 'kein Eintrag gewaehlt');
  finally
    FForm.Hide;
  end;
end;

procedure TCheckListBoxTests.SpaceTogglesWithGrayedCycle;
var
  C: TPPGCheckListBox;
begin
  C := NewCheckList('A,B');
  C.AllowGrayed := True;
  C.ItemIndex := 0;
  Key(C, VK_SPACE);
  CheckTrue(C.State[0] = cbChecked);
  Key(C, VK_SPACE);
  CheckTrue(C.State[0] = cbGrayed, 'mit AllowGrayed: gemischt');
  Key(C, VK_SPACE);
  CheckTrue(C.State[0] = cbUnchecked);
  CheckEquals(3, FChecks);
end;

procedure TCheckListBoxTests.CodeSetsWithoutOnClickCheck;
var
  C: TPPGCheckListBox;
begin
  C := NewCheckList('A,B,C');
  C.Checked[0] := True;
  C.State[1] := cbGrayed;
  C.CheckAll(cbChecked);
  CheckEquals(0, FChecks, 'Code loest kein OnClickCheck aus');
  CheckTrue(C.Checked[2]);
end;

procedure TCheckListBoxTests.HeaderIsNotSelectable;
var
  C: TPPGCheckListBox;
begin
  C := NewCheckList('Kopf,A,B');
  C.Header[0] := True;
  CheckTrue(C.Header[0]);
  C.ItemIndex := 1;
  Key(C, VK_UP);
  CheckEquals(1, C.ItemIndex, 'Pfeil hoch ueberspringt die Ueberschrift');
  ClickItem(C, 0);
  CheckEquals(1, C.ItemIndex, 'Klick auf die Ueberschrift waehlt nicht');
  CheckEquals(0, FChecks);
end;

procedure TCheckListBoxTests.CheckAllRespectsDisabled;
var
  C: TPPGCheckListBox;
begin
  C := NewCheckList('A,B,C');
  C.ItemEnabled[1] := False;
  C.CheckAll(cbChecked, True, False);
  CheckTrue(C.Checked[0]);
  CheckFalse(C.Checked[1], 'deaktivierter Eintrag bleibt');
  CheckTrue(C.Checked[2]);
  C.ItemIndex := 1;
  Key(C, VK_SPACE);
  CheckFalse(C.Checked[1], 'deaktiviert: Leertaste wirkt nicht');
end;

procedure TCheckListBoxTests.StateMovesWithItems;
var
  C: TPPGCheckListBox;
begin
  C := NewCheckList('C,A,B');
  C.Checked[0] := True; // "C"
  C.Items.Move(0, 2);
  CheckTrue(C.Checked[2], 'Zustand wandert beim Verschieben mit');
  CheckFalse(C.Checked[0]);
  C.Sorted := True;
  CheckEquals('C', C.Items[2]);
  CheckTrue(C.Checked[2], 'Zustand wandert beim Sortieren mit');
  C.Items.Add('0'); // sortiert: landet vorn
  CheckTrue(C.Checked[3], 'und beim Einfuegen');
end;

procedure TCheckListBoxTests.ItemsExStates;
var
  C: TPPGCheckListBox;
begin
  C := NewCheckList;
  C.ItemsEx.Add('Eins');
  C.ItemsEx.Add('Zwei').Checked := cbChecked;
  CheckTrue(C.Checked[1]);
  C.Checked[0] := True;
  CheckTrue(C.ItemsEx[0].Checked = cbChecked, 'in TPPGItem gespeichert');
end;

procedure TCheckListBoxTests.LoadsTCheckListBoxDfm;
var
  C: TPPGCheckListBox;
begin
  C := LoadDfm(
    'object CheckListBox1: TPPGCheckListBox'#13#10 +
    '  Left = 8'#13#10 +
    '  Top = 8'#13#10 +
    '  Width = 121'#13#10 +
    '  Height = 97'#13#10 +
    '  AllowGrayed = True'#13#10 +
    '  Flat = False'#13#10 +
    '  ItemHeight = 13'#13#10 +
    '  Items.Strings = ('#13#10 +
    '    ''Eins'''#13#10 +
    '    ''Zwei'')'#13#10 +
    '  TabOrder = 0'#13#10 +
    'end') as TPPGCheckListBox;
  try
    CheckEquals(2, C.Count);
    CheckTrue(C.AllowGrayed);
    CheckFalse(C.Flat);
  finally
    C.Free;
  end;
end;

procedure TCheckListBoxTests.AccessibilityRoles;
var
  C: TPPGCheckListBox;
  A: IPPGAccessibleChildren;
begin
  C := NewCheckList('Kopf,A');
  C.Header[0] := True;
  C.Checked[1] := True;
  CheckTrue(Supports(C, IPPGAccessibleChildren, A));
  CheckEquals(ROLE_SYSTEM_STATICTEXT, A.AccChildRole(1));
  CheckEquals(ROLE_SYSTEM_CHECKBUTTON, A.AccChildRole(2));
  CheckTrue(A.AccChildState(2) and STATE_SYSTEM_CHECKED <> 0);
  CheckEquals(SPPGAccUncheck, A.AccChildDefaultAction(2));
end;

{ TComboExTests }

procedure TComboExTests.ItemsExFillItems;
var
  C: TPPGComboBox;
begin
  C := NewCombo(csDropDownList);
  C.ItemsEx.Add('<b>Fett</b>');
  C.ItemsEx.Add('Normal').Detail := 'Detail';
  CheckEquals(2, C.Items.Count);
  CheckEquals('Fett', C.Items[0], 'Items enthaelt den Text ohne Markup');
  C.ItemIndex := 0;
  CheckEquals('Fett', C.Text);
  C.ItemsEx[1].Text := 'Anders';
  CheckEquals('Anders', C.Items[1]);
end;

procedure TComboExTests.ItemsExImagesRaiseRowHeight;
var
  C: TPPGComboBox;
  Img: TImageList;
  HPlain: Integer;
begin
  FForm.Show;
  try
    C := NewCombo(csDropDownList);
    C.Items.CommaText := 'A,B';
    C.DropDown;
    HPlain := C.PopupList.ItemHeight;
    C.CloseUp(False);
    Img := TImageList.Create(FForm);
    Img.Width := 40;
    Img.Height := 40;
    TComboAccess6(C).Images := Img;
    C.ItemsEx.Add('Bild', 0);
    C.DropDown;
    CheckTrue(C.PopupList.Source <> nil, 'reiche Eintraege in der Liste');
    CheckTrue(C.PopupList.ItemHeight >= 40, 'Zeile so hoch wie das Bild');
    CheckTrue(C.PopupList.ItemHeight > HPlain);
    C.CloseUp(False);
  finally
    FForm.Hide;
  end;
end;

procedure TComboExTests.FilterByPrefix;
var
  C: TPPGComboBox;
begin
  FForm.Show;
  try
    C := NewCombo(csDropDown);
    C.Items.CommaText := 'Belgien,Daenemark,Deutschland,Estland';
    C.FilterMode := fmPrefix;
    C.SetFocus;
    TypeChar(C, 'D');
    CheckTrue(C.DroppedDown, 'Tippen oeffnet die Liste');
    CheckTrue(C.PopupList.Filtered);
    CheckEquals(2, C.PopupList.RowCount, 'nur Treffer');
    CheckEquals(1, C.PopupList.Highlight, 'erster Treffer hervorgehoben');
    CheckEquals('D', C.Text, 'kein AutoComplete beim Filtern');
    TypeChar(C, 'e');
    CheckEquals(1, C.PopupList.RowCount);
    CheckEquals(2, C.PopupList.ItemOfRow(0));
    TComboAccess6(C).Inner.Perform(WM_KEYDOWN, VK_RETURN, 0);
    CheckFalse(C.DroppedDown);
    CheckEquals(2, C.ItemIndex);
    CheckEquals('Deutschland', C.Text);
  finally
    FForm.Hide;
  end;
end;

procedure TComboExTests.SortedItemsExKeepsIndices;
var
  C: TPPGComboBox;
  I: Integer;
begin
  // Audit 08.10.2026: Sorted sortierte nur Items; ItemsEx blieb unsortiert
  // (Bilder an falschen Zeilen), Aendern eines Eintrags warf EStringListError.
  C := NewCombo(csDropDownList);
  C.Sorted := True;
  C.ItemsEx.Add('Zeta', 1);
  C.ItemsEx.Add('<b>Alpha</b>', 2);
  C.ItemsEx.Add('Mitte', 3);
  CheckEquals('Alpha,Mitte,Zeta', C.Items.CommaText);
  for I := 0 to C.Items.Count - 1 do
    CheckEquals(C.Items[I], StringReplace(StringReplace(C.ItemsEx[I].Text, '<b>', '', []),
      '</b>', '', []), 'gleiche Reihenfolge ' + IntToStr(I));
  CheckEquals(2, C.ItemsEx[0].ImageIndex, 'Bild bleibt beim Eintrag');
  C.ItemIndex := 1; // Mitte
  C.ItemsEx[0].Text := 'Zulu';
  CheckEquals('Mitte,Zeta,Zulu', C.Items.CommaText);
  CheckEquals('Zulu', C.ItemsEx[2].Text);
  CheckEquals(2, C.ItemsEx[2].ImageIndex);
  CheckEquals(0, C.ItemIndex, 'Auswahl folgt dem Eintrag');
  C.Sorted := False;
  C.ItemsEx.Add('Anfang');
  CheckEquals('Mitte,Zeta,Zulu,Anfang', C.Items.CommaText, 'unsortiert: angehaengt');
end;

procedure TComboExTests.FilterFollowsItemChanges;
var
  C: TPPGComboBox;
begin
  // Audit 08.10.2026: Die Filter-Zuordnung der offenen Liste blieb nach
  // einer Aenderung der Eintraege stehen und zeigte auf falsche Eintraege.
  FForm.Show;
  try
    C := NewCombo(csDropDown);
    C.Items.CommaText := 'Belgien,Daenemark,Deutschland,Estland';
    C.FilterMode := fmPrefix;
    C.SetFocus;
    TypeChar(C, 'D');
    CheckTrue(C.PopupList.Filtered);
    CheckEquals(2, C.PopupList.RowCount);
    C.Items.Delete(0);
    CheckEquals(2, C.PopupList.RowCount, 'weiter beide D-Laender');
    CheckEquals(0, C.PopupList.ItemOfRow(0), 'Daenemark jetzt Index 0');
    CheckEquals(1, C.PopupList.ItemOfRow(1));
    C.Items.Clear;
    CheckFalse(C.DroppedDown, 'keine Treffer mehr: zu');
  finally
    FForm.Hide;
  end;
end;

procedure TComboExTests.FilterContains;
var
  C: TPPGComboBox;
begin
  FForm.Show;
  try
    C := NewCombo(csDropDown);
    C.Items.CommaText := 'Belgien,Daenemark,Deutschland,Estland';
    C.FilterMode := fmContains;
    C.SetFocus;
    TypeChar(C, 'l');
    TypeChar(C, 'a');
    CheckEquals(2, C.PopupList.RowCount, '"la" in Deutschland und Estland');
    CheckEquals(2, C.PopupList.ItemOfRow(0));
    CheckEquals(3, C.PopupList.ItemOfRow(1));
    C.CloseUp(False);
  finally
    FForm.Hide;
  end;
end;

procedure TComboExTests.FilterWithoutMatchClosesList;
var
  C: TPPGComboBox;
begin
  FForm.Show;
  try
    C := NewCombo(csDropDown);
    C.Items.CommaText := 'Belgien,Daenemark';
    C.FilterMode := fmPrefix;
    C.SetFocus;
    TypeChar(C, 'B');
    CheckTrue(C.DroppedDown);
    TypeChar(C, 'x');
    CheckFalse(C.DroppedDown, 'kein Treffer: Liste zu');
    CheckEquals('Bx', C.Text, 'Text bleibt');
  finally
    FForm.Hide;
  end;
end;

procedure TComboExTests.FilterClearedOnDropDown;
var
  C: TPPGComboBox;
begin
  FForm.Show;
  try
    C := NewCombo(csDropDown);
    C.Items.CommaText := 'Belgien,Daenemark,Deutschland';
    C.FilterMode := fmPrefix;
    C.SetFocus;
    TypeChar(C, 'D');
    CheckEquals(2, C.PopupList.RowCount);
    C.CloseUp(False);
    C.DropDown;
    CheckFalse(C.PopupList.Filtered, 'Aufklappen per Pfeil zeigt alle');
    CheckEquals(3, C.PopupList.RowCount);
    C.CloseUp(False);
  finally
    FForm.Hide;
  end;
end;

initialization
  RegisterClass(TPPGListBox);
  RegisterClass(TPPGCheckListBox);
  RegisterTest('Phase6a', TListBoxTests.Suite);
  RegisterTest('Phase6a', TCheckListBoxTests.Suite);
  RegisterTest('Phase6a', TComboExTests.Suite);

end.
