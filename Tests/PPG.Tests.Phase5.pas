unit PPG.Tests.Phase5;

{ Tests fuer Phase 5: Fundament der Daten-Controls (Zeilen-Layout, Auswahl,
  Item-Quellen, Markup, Scroll-Control, Mehrfachauswahl fuer Screenreader). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, Winapi.ActiveX, Winapi.oleacc,
  System.Classes, System.SysUtils, System.Types, System.Variants,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls,
  PPG.Types, PPG.Consts, PPG.Exceptions, PPG.Render.Intf, PPG.Render.Registry,
  PPG.Render.Gdi, PPG.Accessibility, PPG.Controls.Base,
  PPG.RowLayout, PPG.Selection, PPG.Items, PPG.Markup, PPG.Controls.Scroll,
  PPG.Controls.Container, PPG.Panel, PPG.GroupBox, PPG.CheckBox, PPG.PageControl,
  PPG.Tests.Controls, PPG.Tests.Gaps, PPG.Tests.Phase4a;

type
  /// Testinhalt: Zeilen in abwechselnden Farben.
  TTestScroller = class(TPPGCustomScrollControl)
  protected
    procedure PaintViewport(const ACanvas: IPPGCanvas; const View: TRect); override;
    procedure ContentMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoAutoScroll(const P: TPoint); override;
    function LineHeight: Integer; override;
  public
    RowH: Integer;
    Downs: Integer;
    AutoScrolls: Integer;
    Scrolls: Integer;
    procedure CountScroll(Sender: TObject);
  end;

  TItemsHost = class(TComponent)
  private
    FItems: TPPGItems;
    procedure SetItems(const Value: TPPGItems);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Items: TPPGItems read FItems write SetItems;
  end;

  /// Control mit Mehrfachauswahl fuer die Barrierefreiheit.
  TMultiAccControl = class(TPPGCustomControl, IPPGAccessibleChildren,
    IPPGAccessibleMultiSelection)
  public
    Selected: TArray<Integer>;
    LastSelectId, LastSelectFlags: Integer;
    function AccChildCount: Integer;
    function AccChildName(Id: Integer): string;
    function AccChildRole(Id: Integer): Integer;
    function AccChildState(Id: Integer): Integer;
    function AccChildRect(Id: Integer): TRect;
    function AccChildAt(X, Y: Integer): Integer;
    function AccChildDefaultAction(Id: Integer): string;
    procedure AccChildDoDefault(Id: Integer);
    function AccFocusedChild: Integer;
    function AccSelectedChild: Integer;
    function AccSelectedChildren: TArray<Integer>;
    function AccChildSelect(Id: Integer; Flags: Integer): Boolean;
  end;

  TRowLayoutTests = class(TTestCase)
  published
    procedure FixedHeights;
    procedure VariableHeights;
    procedure InsertDeleteShiftHeights;
    procedure InvalidValuesRaise;
    procedure MillionRowsAreFast;
  end;

  TSelectionTests = class(TTestCase)
  private
    FEvents: Integer;
    procedure CountEvent(Sender: TObject);
    function Sel(S: TPPGSelection): string;
  published
    procedure SingleMode;
    procedure ExtendedMouse;
    procedure ExtendedKeyboard;
    procedure MultiModeToggles;
    procedure OneChangeEventPerAction;
    procedure InsertDeleteShiftSelection;
    procedure ShrinkingCountDropsSelection;
    procedure ModeSwitchToSingle;
    procedure MillionItemsAreFast;
  end;

  TItemSourceTests = class(TTestCase)
  private
    FLastIndex: Integer;
    FChanges: Integer;
    FOldChanges: Integer;
    procedure SourceChanged(Sender: TObject; Index: Integer);
    procedure OldChange(Sender: TObject);
    procedure GetVirtual(Sender: TObject; Index: Integer; var Data: TPPGItemData);
    procedure SetVirtualChecked(Sender: TObject; Index: Integer; Value: TCheckBoxState);
  published
    procedure CollectionSourceReflectsItems;
    procedure StringsSourceKeepsOldHandler;
    procedure VirtualSourceAsksOnDemand;
    procedure ItemsStreamRoundTrip;
  end;

  TMarkupTests = class(TTestCase)
  published
    procedure PlainTextFastPath;
    procedure ParsesStyles;
    procedure ColorsNestAndRestore;
    procedure LinksImagesBreaks;
    procedure EscapesAndUnknownTagsStayText;
    procedure NeverRaisesOnGarbage;
    procedure StripMarkup;
    procedure LayoutWraps;
    procedure LinkHitTest;
    procedure DrawsColoredText;
  end;

  TScrollControlTests = class(TPhase4TestCase)
  private
    function NewScroller(Rows: Integer = 100; RowH: Integer = 20): TTestScroller;
  published
    procedure BarsOnlyWhenNeeded;
    procedure ScrollToClampsAndNotifies;
    procedure WheelScrollsLinesAndKeepsRest;
    procedure HorizontalWheel;
    procedure ThumbDragScrollsProportionally;
    procedure TrackClickPages;
    procedure SmoothScrollReachesTarget;
    procedure AutoModeFadesAndExpands;
    procedure RtlPutsVerticalBarLeft;
    procedure MakeVisibleScrollsMinimal;
    procedure KeyboardScrolls;
    procedure AutoScrollWhileDragging;
    procedure ContentMouseOnlyOutsideBars;
    procedure PaintsThumbBothPresetsAndGdi;
    procedure NoHandleOrMemoryLeaks;
  end;

  TParentBackgroundTests = class(TPhase4TestCase)
  published
    procedure ChildInsidePanelUsesSurfaceColor;
    procedure ClassicGradientFollowsPosition;
    procedure FallbackOnBorderAndCaption;
    procedure GroupBoxAndPageAreFastToo;
  end;

  TMultiSelectAccessibilityTests = class(TPhase4TestCase)
  published
    procedure SelectionListsAllSelectedChildren;
    procedure AccSelectIsForwarded;
  end;

implementation

{$WARN SYMBOL_PLATFORM OFF}

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

function WheelLines: Integer;
var
  L: UINT;
begin
  L := 3;
  SystemParametersInfo(SPI_GETWHEELSCROLLLINES, 0, @L, 0);
  Result := Integer(L);
end;

{ TTestScroller }

procedure TTestScroller.PaintViewport(const ACanvas: IPPGCanvas; const View: TRect);
var
  I, First, Y: Integer;
  R: TRect;
  C: TColor;
begin
  if RowH <= 0 then
    Exit;
  First := ScrollY div RowH;
  Y := View.Top + First * RowH - ScrollY;
  I := First;
  while Y < View.Bottom do
  begin
    R := Rect(View.Left, Y, View.Right, Y + RowH);
    if Odd(I) then
      C := $00F0F0F0
    else
      C := clWhite;
    ACanvas.FillRoundRect(R, 0, C, 255);
    Inc(Y, RowH);
    Inc(I);
  end;
end;

procedure TTestScroller.ContentMouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  Inc(Downs);
end;

procedure TTestScroller.DoAutoScroll(const P: TPoint);
begin
  Inc(AutoScrolls);
end;

function TTestScroller.LineHeight: Integer;
begin
  Result := RowH;
end;

procedure TTestScroller.CountScroll(Sender: TObject);
begin
  Inc(Scrolls);
end;

{ TItemsHost }

constructor TItemsHost.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TPPGItems.Create(Self);
end;

destructor TItemsHost.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TItemsHost.SetItems(const Value: TPPGItems);
begin
  FItems.Assign(Value);
end;

{ TMultiAccControl }

function TMultiAccControl.AccChildCount: Integer;
begin
  Result := 5;
end;

function TMultiAccControl.AccChildName(Id: Integer): string;
begin
  Result := 'Eintrag ' + IntToStr(Id);
end;

function TMultiAccControl.AccChildRole(Id: Integer): Integer;
begin
  Result := ROLE_SYSTEM_LISTITEM;
end;

function TMultiAccControl.AccChildState(Id: Integer): Integer;
begin
  Result := STATE_SYSTEM_SELECTABLE;
end;

function TMultiAccControl.AccChildRect(Id: Integer): TRect;
begin
  Result := Rect(0, (Id - 1) * 10, 50, Id * 10);
end;

function TMultiAccControl.AccChildAt(X, Y: Integer): Integer;
begin
  Result := 0;
end;

function TMultiAccControl.AccChildDefaultAction(Id: Integer): string;
begin
  Result := '';
end;

procedure TMultiAccControl.AccChildDoDefault(Id: Integer);
begin
end;

function TMultiAccControl.AccFocusedChild: Integer;
begin
  Result := 0;
end;

function TMultiAccControl.AccSelectedChild: Integer;
begin
  Result := 0;
end;

function TMultiAccControl.AccSelectedChildren: TArray<Integer>;
begin
  Result := Copy(Selected);
end;

function TMultiAccControl.AccChildSelect(Id: Integer; Flags: Integer): Boolean;
begin
  LastSelectId := Id;
  LastSelectFlags := Flags;
  Result := True;
end;

{ TRowLayoutTests }

procedure TRowLayoutTests.FixedHeights;
var
  L: TPPGRowLayout;
begin
  L := TPPGRowLayout.Create;
  try
    L.DefaultHeight := 20;
    L.Count := 10;
    CheckFalse(L.Variable);
    CheckEquals(60, L.RowTop(3));
    CheckEquals(2, L.RowAt(59));
    CheckEquals(3, L.RowAt(60));
    CheckEquals(9, L.RowAt(199));
    CheckEquals(-1, L.RowAt(200), 'hinter dem Ende');
    CheckEquals(-1, L.RowAt(-1));
    CheckEquals(200, L.TotalHeight);
    L.DefaultHeight := 30;
    CheckEquals(300, L.TotalHeight, 'Standardhoehe geaendert');
  finally
    L.Free;
  end;
end;

procedure TRowLayoutTests.VariableHeights;
var
  L: TPPGRowLayout;
begin
  L := TPPGRowLayout.Create;
  try
    L.DefaultHeight := 20;
    L.Count := 10;
    L.SetRowHeight(2, 50);
    CheckTrue(L.Variable);
    CheckEquals(50, L.RowHeight(2));
    CheckEquals(20, L.RowHeight(3));
    CheckEquals(90, L.RowTop(3));
    CheckEquals(2, L.RowAt(40));
    CheckEquals(2, L.RowAt(89));
    CheckEquals(3, L.RowAt(90));
    CheckEquals(230, L.TotalHeight);
    L.DefaultHeight := 10;
    CheckEquals(140, L.TotalHeight, 'Cache nach DefaultHeight neu');
    L.SetRowHeight(2, 0);
    CheckEquals(100, L.TotalHeight, '0 = Standardhoehe');
    L.SetRowHeight(5, 25);
    L.ClearHeights;
    CheckFalse(L.Variable);
    CheckEquals(100, L.TotalHeight);
  finally
    L.Free;
  end;
end;

procedure TRowLayoutTests.InsertDeleteShiftHeights;
var
  L: TPPGRowLayout;
begin
  L := TPPGRowLayout.Create;
  try
    L.DefaultHeight := 20;
    L.Count := 5;
    L.SetRowHeight(1, 40);
    L.RowsInserted(0, 2);
    CheckEquals(7, L.Count);
    CheckEquals(40, L.RowHeight(3), 'Hoehe wandert mit');
    CheckEquals(20, L.RowHeight(0));
    L.RowsDeleted(0, 1);
    CheckEquals(40, L.RowHeight(2));
    CheckEquals(6 * 20 + 20, L.TotalHeight);
    L.RowsDeleted(2, 100);
    CheckEquals(2, L.Count, 'Loeschen ueber das Ende begrenzt');
  finally
    L.Free;
  end;
end;

procedure TRowLayoutTests.InvalidValuesRaise;
var
  L: TPPGRowLayout;
begin
  L := TPPGRowLayout.Create;
  try
    L.Count := 3;
    try
      L.Count := -1;
      Fail('Count < 0');
    except
      on E: EPPGPropertyError do ;
    end;
    try
      L.DefaultHeight := 0;
      Fail('DefaultHeight < 1');
    except
      on E: EPPGPropertyError do ;
    end;
    try
      L.SetRowHeight(3, 10);
      Fail('Index ausserhalb');
    except
      on E: EPPGPropertyError do ;
    end;
    CheckEquals(3, L.Count, 'unveraendert');
  finally
    L.Free;
  end;
end;

procedure TRowLayoutTests.MillionRowsAreFast;
var
  L: TPPGRowLayout;
  I, R: Integer;
  T0: Cardinal;
begin
  L := TPPGRowLayout.Create;
  try
    L.DefaultHeight := 20;
    L.Count := 1000000;
    T0 := GetTickCount;
    for I := 0 to 99999 do
    begin
      R := L.RowAt(Int64(I) * 197);
      if R <> I * 197 div 20 then
        Fail('RowAt fest');
    end;
    CheckTrue(GetTickCount - T0 < 100, 'fest: 100 000 RowAt');
    for I := 0 to 999 do
      L.SetRowHeight(I * 1000, 40);
    T0 := GetTickCount;
    CheckEquals(Int64(1000000) * 20 + 1000 * 20, L.TotalHeight64);
    for I := 0 to 99999 do
      L.RowAt(Int64(I) * 197);
    CheckTrue(GetTickCount - T0 < 300, Format('variabel: %d ms', [GetTickCount - T0]));
    CheckEquals(1000, L.RowAt(L.RowTop(1000) + 39), 'hohe Zeile');
    CheckEquals(1001, L.RowAt(L.RowTop(1000) + 40));
  finally
    L.Free;
  end;
end;

{ TSelectionTests }

procedure TSelectionTests.CountEvent(Sender: TObject);
begin
  Inc(FEvents);
end;

function TSelectionTests.Sel(S: TPPGSelection): string;
var
  I: Integer;
begin
  Result := '';
  I := S.NextSelected(0);
  while I >= 0 do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + IntToStr(I);
    I := S.NextSelected(I + 1);
  end;
end;

procedure TSelectionTests.SingleMode;
var
  S: TPPGSelection;
begin
  S := TPPGSelection.Create;
  try
    S.Count := 10;
    S.Click(3, []);
    CheckEquals('3', Sel(S));
    CheckEquals(3, S.ItemIndex);
    S.Click(5, [ssShift, ssCtrl]);
    CheckEquals('5', Sel(S), 'Single: Umschalttasten wirken nicht');
    S.MoveTo(7, [ssShift]);
    CheckEquals('7', Sel(S));
    S.SelectAll;
    CheckEquals(1, S.SelCount, 'SelectAll gibt es nur bei Mehrfachauswahl');
    S.MoveTo(99, []);
    CheckEquals(9, S.Focus, 'begrenzt');
  finally
    S.Free;
  end;
end;

procedure TSelectionTests.ExtendedMouse;
var
  S: TPPGSelection;
begin
  S := TPPGSelection.Create;
  try
    S.Mode := smExtended;
    S.Count := 20;
    S.Click(2, []);
    S.Click(5, [ssShift]);
    CheckEquals('2,3,4,5', Sel(S), 'Umschalt: Bereich vom Anker');
    S.Click(8, [ssCtrl]);
    CheckEquals('2,3,4,5,8', Sel(S), 'Strg: hinzufuegen');
    CheckEquals(8, S.Anchor);
    S.Click(10, [ssShift, ssCtrl]);
    CheckEquals('2,3,4,5,8,9,10', Sel(S), 'Strg+Umschalt: Bereich dazu');
    S.Click(3, [ssCtrl]);
    CheckEquals('2,4,5,8,9,10', Sel(S), 'Strg: umschalten');
    S.Click(4, [ssShift]);
    CheckEquals('3,4', Sel(S), 'Umschalt ohne Strg: nur der Bereich');
    S.Click(6, []);
    CheckEquals('6', Sel(S));
    CheckEquals(6, S.Focus);
  finally
    S.Free;
  end;
end;

procedure TSelectionTests.ExtendedKeyboard;
var
  S: TPPGSelection;
begin
  S := TPPGSelection.Create;
  try
    S.Mode := smExtended;
    S.Count := 20;
    S.MoveTo(4, []);
    S.MoveTo(6, [ssShift]);
    CheckEquals('4,5,6', Sel(S));
    S.MoveTo(9, [ssCtrl]);
    CheckEquals('4,5,6', Sel(S), 'Strg+Pfeil: nur der Fokus wandert');
    CheckEquals(9, S.Focus);
    S.ToggleFocused;
    CheckEquals('4,5,6,9', Sel(S), 'Strg+Leertaste');
    S.MoveTo(11, [ssShift, ssCtrl]);
    CheckEquals('4,5,6,9,10,11', Sel(S), 'Bereich vom neuen Anker dazu');
    S.SelectAll;
    CheckEquals(20, S.SelCount);
    S.Clear;
    CheckEquals(0, S.SelCount);
  finally
    S.Free;
  end;
end;

procedure TSelectionTests.MultiModeToggles;
var
  S: TPPGSelection;
begin
  S := TPPGSelection.Create;
  try
    S.Mode := smMulti;
    S.Count := 5;
    S.Click(1, []);
    S.Click(3, []);
    CheckEquals('1,3', Sel(S));
    S.Click(1, []);
    CheckEquals('3', Sel(S), 'Klick schaltet um');
    S.MoveTo(4, []);
    CheckEquals('3', Sel(S), 'Pfeil bewegt nur den Fokus');
    S.ToggleFocused;
    CheckEquals('3,4', Sel(S), 'Leertaste');
  finally
    S.Free;
  end;
end;

procedure TSelectionTests.OneChangeEventPerAction;
var
  S: TPPGSelection;
begin
  S := TPPGSelection.Create;
  try
    S.Mode := smExtended;
    S.Count := 1000;
    S.OnChange := CountEvent;
    S.SelectRange(0, 999, False);
    CheckEquals(1, FEvents, 'ein Ereignis fuer 1000 Eintraege');
    S.Clear;
    CheckEquals(2, FEvents);
    S.Clear;
    CheckEquals(2, FEvents, 'nichts geaendert: kein Ereignis');
    S.BeginUpdate;
    S.Click(1, []);
    S.Click(5, [ssShift]);
    S.EndUpdate;
    CheckEquals(3, FEvents, 'gebuendelt');
  finally
    S.Free;
  end;
end;

procedure TSelectionTests.InsertDeleteShiftSelection;
var
  S: TPPGSelection;
begin
  S := TPPGSelection.Create;
  try
    S.Mode := smExtended;
    S.Count := 10;
    S.Click(2, []);
    S.Click(5, [ssCtrl]);
    S.ItemsInserted(3, 2);
    CheckEquals(12, S.Count);
    CheckEquals('2,7', Sel(S), 'hinter der Einfuegestelle verschoben');
    CheckEquals(7, S.Focus);
    S.ItemsDeleted(0, 3);
    CheckEquals('4', Sel(S), 'geloeschte Auswahl faellt weg');
    CheckEquals(1, S.SelCount);
    CheckEquals(4, S.Focus);
    S.ItemsDeleted(4, 1);
    CheckEquals(4, S.Focus, 'Fokus auf den Nachfolger');
    CheckEquals(0, S.SelCount);
    S.ItemsDeleted(4, 100);
    CheckEquals(4, S.Count);
    CheckEquals(3, S.Focus, 'Fokus auf den letzten');
  finally
    S.Free;
  end;
end;

procedure TSelectionTests.ShrinkingCountDropsSelection;
var
  S: TPPGSelection;
begin
  S := TPPGSelection.Create;
  try
    S.Mode := smExtended;
    S.Count := 10;
    S.SelectRange(7, 9, False);
    S.Click(8, [ssCtrl]);
    S.Count := 5;
    CheckEquals(0, S.SelCount);
    CheckTrue(S.Focus <= 4);
    S.Count := 8;
    CheckFalse(S.Selected[7], 'neue Eintraege nicht gewaehlt');
  finally
    S.Free;
  end;
end;

procedure TSelectionTests.ModeSwitchToSingle;
var
  S: TPPGSelection;
begin
  S := TPPGSelection.Create;
  try
    S.Mode := smExtended;
    S.Count := 10;
    S.Click(2, []);
    S.Click(6, [ssShift]);
    S.Mode := smSingle;
    CheckEquals('6', Sel(S), 'nur der Fokus bleibt');
  finally
    S.Free;
  end;
end;

procedure TSelectionTests.MillionItemsAreFast;
var
  S: TPPGSelection;
  T0: Cardinal;
begin
  S := TPPGSelection.Create;
  try
    S.Mode := smExtended;
    S.Count := 1000000;
    T0 := GetTickCount;
    S.SelectAll;
    S.Click(500000, [ssCtrl]);
    S.Clear;
    S.SelectRange(10, 900000, False);
    S.ItemsDeleted(0, 5);
    CheckTrue(GetTickCount - T0 < 500, Format('%d ms', [GetTickCount - T0]));
    CheckEquals(900000 - 10 + 1, S.SelCount);
  finally
    S.Free;
  end;
end;

{ TItemSourceTests }

procedure TItemSourceTests.SourceChanged(Sender: TObject; Index: Integer);
begin
  Inc(FChanges);
  FLastIndex := Index;
end;

procedure TItemSourceTests.OldChange(Sender: TObject);
begin
  Inc(FOldChanges);
end;

procedure TItemSourceTests.GetVirtual(Sender: TObject; Index: Integer; var Data: TPPGItemData);
begin
  Data.Text := 'Zeile ' + IntToStr(Index);
  Data.ImageIndex := Index mod 3;
end;

procedure TItemSourceTests.SetVirtualChecked(Sender: TObject; Index: Integer;
  Value: TCheckBoxState);
begin
  FLastIndex := Index;
end;

procedure TItemSourceTests.CollectionSourceReflectsItems;
var
  H: TItemsHost;
  Src: IPPGItemSource;
  D: TPPGItemData;
  It: TPPGItem;
begin
  H := TItemsHost.Create(nil);
  try
    Src := TPPGCollectionSource.Create(H.Items);
    Src.OnChanged := SourceChanged;
    It := H.Items.Add('Eins', 2);
    CheckEquals(1, Src.Count);
    CheckEquals(-1, FLastIndex, 'Hinzufuegen = Struktur');
    FChanges := 0;
    It.Detail := 'Mehr';
    CheckEquals(1, FChanges);
    CheckEquals(0, FLastIndex, 'Eintrag geaendert');
    It.Group := 'G';
    CheckEquals(-1, FLastIndex, 'Gruppe = Struktur');
    PPGInitItemData(D);
    Src.GetItem(0, D);
    CheckEquals('Eins', D.Text);
    CheckEquals('Mehr', D.Detail);
    CheckEquals(2, D.ImageIndex);
    CheckEquals('G', D.Group);
    CheckTrue(Src.SetChecked(0, cbChecked));
    CheckTrue(It.Checked = cbChecked);
    CheckEquals(0, H.Items.IndexOfText('eins'));
    Src := nil; // Quelle weg: Collection meldet sich nicht mehr dort
    It.Text := 'Zwei';
  finally
    H.Free;
  end;
end;

procedure TItemSourceTests.StringsSourceKeepsOldHandler;
var
  L: TStringList;
  Src: IPPGItemSource;
  D: TPPGItemData;
  O: TObject;
begin
  L := TStringList.Create;
  O := TObject.Create;
  try
    L.OnChange := OldChange;
    Src := TPPGStringsSource.Create(L);
    Src.OnChanged := SourceChanged;
    L.AddObject('a', O);
    CheckEquals(1, FChanges);
    CheckEquals(1, FOldChanges, 'alter OnChange-Handler laeuft weiter');
    PPGInitItemData(D);
    Src.GetItem(0, D);
    CheckEquals('a', D.Text);
    CheckSame(O, TObject(D.Data));
    CheckFalse(Src.SetChecked(0, cbChecked), 'TStrings kennt keine Haekchen');
    Src := nil;
    CheckTrue(Assigned(L.OnChange), 'alter Handler wiederhergestellt');
    L.Add('b');
    CheckEquals(2, FOldChanges);
    CheckEquals(1, FChanges);
  finally
    O.Free;
    L.Free;
  end;
end;

procedure TItemSourceTests.VirtualSourceAsksOnDemand;
var
  V: TPPGVirtualSource;
  Src: IPPGItemSource;
  D: TPPGItemData;
begin
  V := TPPGVirtualSource.Create;
  Src := V;
  Src.OnChanged := SourceChanged;
  V.ItemCount := 1000000;
  CheckEquals(1000000, Src.Count);
  CheckEquals(-1, FLastIndex);
  V.OnGetItem := GetVirtual;
  PPGInitItemData(D);
  Src.GetItem(999999, D);
  CheckEquals('Zeile 999999', D.Text);
  CheckFalse(Src.SetChecked(3, cbChecked), 'ohne OnSetChecked');
  V.OnSetChecked := SetVirtualChecked;
  FChanges := 0;
  CheckTrue(Src.SetChecked(3, cbChecked));
  CheckEquals(3, FLastIndex);
  CheckEquals(1, FChanges, 'Eintrag neu zeichnen');
  try
    V.ItemCount := -1;
    Fail('negativ');
  except
    on E: EPPGPropertyError do ;
  end;
end;

procedure TItemSourceTests.ItemsStreamRoundTrip;
var
  H, H2: TItemsHost;
  Bin: TMemoryStream;
  Txt: TStringStream;
  S: string;
begin
  H := TItemsHost.Create(nil);
  H2 := TItemsHost.Create(nil);
  Bin := TMemoryStream.Create;
  Txt := TStringStream.Create('');
  try
    H.Items.Add('Eins');
    with H.Items.Add('Zwei', 3) do
    begin
      Checked := cbGrayed;
      Enabled := False;
      Badge := '5';
    end;
    Bin.WriteComponent(H);
    Bin.Position := 0;
    ObjectBinaryToText(Bin, Txt);
    S := Txt.DataString;
    CheckTrue(Pos('Text = ''Eins''', S) > 0, S);
    CheckTrue(Pos('Checked = cbGrayed', S) > 0, S);
    CheckTrue(Pos('ImageIndex = 3', S) > 0, S);
    CheckEquals(Pos('ImageIndex', S), Pos('ImageIndex = 3', S),
      'ImageIndex = -1 (Standard) wird nicht gespeichert');
    Bin.Position := 0;
    Bin.ReadComponent(H2);
    CheckEquals(2, H2.Items.Count);
    CheckEquals('Zwei', H2.Items[1].Text);
    CheckEquals(3, H2.Items[1].ImageIndex);
    CheckEquals(-1, H2.Items[0].ImageIndex);
    CheckFalse(H2.Items[1].Enabled);
    CheckEquals('5', H2.Items[1].Badge);
  finally
    Txt.Free;
    Bin.Free;
    H2.Free;
    H.Free;
  end;
end;

{ TMarkupTests }

procedure TMarkupTests.PlainTextFastPath;
var
  R: TPPGMarkupRuns;
begin
  CheckTrue(PPGIsPlainText('Hallo Welt'));
  CheckFalse(PPGIsPlainText('a<b>'));
  CheckFalse(PPGIsPlainText('a &amp; b'));
  R := PPGParseMarkup('Hallo');
  CheckEquals(1, Length(R));
  CheckEquals('Hallo', R[0].Text);
  CheckTrue(R[0].Style = []);
  CheckEquals(Integer(clNone), Integer(R[0].Color));
end;

procedure TMarkupTests.ParsesStyles;
var
  R: TPPGMarkupRuns;
begin
  R := PPGParseMarkup('<b>fett</b> normal <i>k<u>ku</u></i><s>x</s>');
  CheckEquals(5, Length(R));
  CheckEquals('fett', R[0].Text);
  CheckTrue(R[0].Style = [fsBold]);
  CheckEquals(' normal ', R[1].Text);
  CheckTrue(R[1].Style = []);
  CheckTrue(R[2].Style = [fsItalic]);
  CheckEquals('ku', R[3].Text);
  CheckTrue(R[3].Style = [fsItalic, fsUnderline]);
  CheckTrue(R[4].Style = [fsStrikeOut]);
  R := PPGParseMarkup('<B>gross</B>');
  CheckTrue(R[0].Style = [fsBold], 'Tags ohne Gross-/Kleinschreibung');
  R := PPGParseMarkup('<b><b>a</b>b</b>c');
  CheckTrue(R[1].Style = [fsBold], 'verschachtelt');
  CheckTrue(R[2].Style = [], 'nach dem zweiten </b>');
end;

procedure TMarkupTests.ColorsNestAndRestore;
var
  R: TPPGMarkupRuns;
begin
  R := PPGParseMarkup('<color=#FF0000>r<color=clBlue>b</color>r2</color>n<color=kaputt>k</color>');
  CheckEquals(5, Length(R));
  CheckEquals(Integer(clRed), Integer(R[0].Color), '#RRGGBB');
  CheckEquals(Integer(clBlue), Integer(R[1].Color), 'Farbname');
  CheckEquals(Integer(clRed), Integer(R[2].Color), 'vorige Farbe');
  CheckEquals(Integer(clNone), Integer(R[3].Color));
  CheckEquals('k', R[4].Text, 'ungueltige Farbe: Text bleibt');
  CheckEquals(Integer(clNone), Integer(R[4].Color));
end;

procedure TMarkupTests.LinksImagesBreaks;
var
  R: TPPGMarkupRuns;
begin
  R := PPGParseMarkup('a<br>b<img=2><a href="http://x/y">L</a>'#13#10'z');
  CheckEquals(7, Length(R));
  CheckTrue(R[1].Kind = mrkBreak);
  CheckTrue(R[3].Kind = mrkImage);
  CheckEquals(2, R[3].ImageIndex);
  CheckEquals('L', R[4].Text);
  CheckEquals('http://x/y', R[4].Link);
  CheckTrue(R[5].Kind = mrkBreak, 'CRLF = ein Umbruch');
  CheckEquals('z', R[6].Text);
  CheckEquals('', R[6].Link, 'Link endet mit </a>');
end;

procedure TMarkupTests.EscapesAndUnknownTagsStayText;
begin
  CheckEquals('<b> & "', PPGStripMarkup('&lt;b&gt; &amp; &quot;'));
  CheckEquals('<x>y</x>', PPGStripMarkup('<x>y</x>'), 'unbekannte Tags bleiben Text');
  CheckEquals('a <b', PPGStripMarkup('a <b'), 'offenes Tag bleibt Text');
  CheckEquals('a & b', PPGStripMarkup('a & b'));
  CheckEquals('&foo;', PPGStripMarkup('&foo;'));
  CheckEquals('<img=x>', PPGStripMarkup('<img=x>'), 'ungueltiges Bild');
  CheckEquals('fett', PPGStripMarkup('<b>fett'), 'nicht geschlossen gilt bis zum Ende');
end;

procedure TMarkupTests.NeverRaisesOnGarbage;
const
  Alphabet = '<>&=/"''#;bicolrsuahefimg01 ';
var
  I, J, N: Integer;
  S: string;
begin
  RandSeed := 4711;
  for I := 1 to 3000 do
  begin
    N := Random(40);
    SetLength(S, N);
    for J := 1 to N do
      S[J] := Alphabet[1 + Random(Length(Alphabet))];
    PPGParseMarkup(S);
    PPGStripMarkup(S);
  end;
  Check(True);
end;

procedure TMarkupTests.StripMarkup;
begin
  CheckEquals('Hallo Welt', PPGStripMarkup('<b>Hallo</b> <i>Welt</i>'));
  CheckEquals('a' + sLineBreak + 'b', PPGStripMarkup('a<br>b'));
  CheckEquals('Link', PPGStripMarkup('<a href=x>Link</a><img=1>'));
end;

procedure TMarkupTests.LayoutWraps;
var
  L: TPPGMarkupLayout;
  F: TFont;
  W: Integer;
begin
  F := TFont.Create;
  L := TPPGMarkupLayout.Create;
  try
    F.Name := 'Segoe UI';
    F.Size := 9;
    W := PPGMeasureTextNoCanvas('eins zwei', F, 0, False).cx + 2;
    L.Layout('eins zwei drei vier', F, nil, W, True);
    CheckEquals(2, L.LineCount, 'Umbruch nach "zwei"');
    CheckTrue(L.Size.cx <= W + 6, 'Breite eingehalten');
    L.Layout('eins zwei drei vier', F, nil, W, False);
    CheckEquals(1, L.LineCount, 'ohne WordWrap');
    L.Layout('eins<br>zwei', F, nil, 0, False);
    CheckEquals(2, L.LineCount, '<br>');
    CheckTrue(L.Size.cy >= 2 * PPGMeasureTextNoCanvas('Wg', F, 0, False).cy);
    L.Layout('', F, nil, 0, False);
    CheckEquals(1, L.LineCount, 'leer: eine leere Zeile');
    L.Layout('ueberlangeswortohneleerzeichen', F, nil, 10, True);
    CheckEquals(1, L.LineCount, 'zu langes Wort wird nicht zerhackt');
  finally
    L.Free;
    F.Free;
  end;
end;

procedure TMarkupTests.LinkHitTest;
var
  L: TPPGMarkupLayout;
  F: TFont;
  X: Integer;
begin
  F := TFont.Create;
  L := TPPGMarkupLayout.Create;
  try
    L.Layout('Text <a href="ziel">Link</a> mehr', F, nil, 0, False);
    CheckTrue(L.HasLinks);
    X := PPGMeasureTextNoCanvas('Text ', F, 0, False).cx + 3;
    CheckEquals('ziel', L.LinkAt(X, L.Size.cy div 2));
    CheckEquals('', L.LinkAt(1, L.Size.cy div 2));
    CheckEquals('', L.LinkAt(X, L.Size.cy + 5), 'unterhalb');
    L.Layout('ohne', F, nil, 0, False);
    CheckFalse(L.HasLinks);
  finally
    L.Free;
    F.Free;
  end;
end;

procedure TMarkupTests.DrawsColoredText;
var
  L: TPPGMarkupLayout;
  F: TFont;
  Bmp: TBitmap;
  Cv: IPPGCanvas;
  X, Y, Reds: Integer;
  C: Cardinal;
begin
  F := TFont.Create;
  L := TPPGMarkupLayout.Create;
  Bmp := TBitmap.Create;
  try
    F.Size := 14;
    F.Name := 'Segoe UI';
    Bmp.PixelFormat := pf24bit;
    Bmp.SetSize(200, 40);
    Bmp.Canvas.Brush.Color := clWhite;
    Bmp.Canvas.FillRect(Rect(0, 0, 200, 40));
    L.Layout('<b><color=#FF0000>XXXX</color></b>', F, nil, 0, False);
    Cv := TPPGGdiCanvas.Create(Bmp.Canvas.Handle);
    L.Draw(Cv, 2, 2, clBlack, clBlue);
    Cv := nil;
    Reds := 0;
    for Y := 0 to 39 do
      for X := 0 to 199 do
      begin
        C := ColorToRGB(Bmp.Canvas.Pixels[X, Y]);
        if (GetRValue(C) > 180) and (GetGValue(C) < 80) and (GetBValue(C) < 80) then
          Inc(Reds);
      end;
    CheckTrue(Reds > 20, Format('roter Text gezeichnet (%d Pixel)', [Reds]));
  finally
    Bmp.Free;
    L.Free;
    F.Free;
  end;
end;

{ TScrollControlTests }

function TScrollControlTests.NewScroller(Rows, RowH: Integer): TTestScroller;
begin
  Result := TTestScroller.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 200, 150);
  Result.Preset := PPGPresetModernFlat;
  Result.Animation.Enabled := False;
  Result.RowH := RowH;
  Result.SetContentSize(180, Rows * RowH);
  Result.OnScroll := Result.CountScroll;
  Result.HandleNeeded;
end;

procedure TScrollControlTests.BarsOnlyWhenNeeded;
var
  S: TTestScroller;
  B: Integer;
begin
  S := NewScroller(5);
  CheckTrue(IsRectEmpty(S.ScrollBarRect(saVert)), 'Inhalt passt: keine Leiste');
  S.SetContentSize(180, 2000);
  CheckFalse(IsRectEmpty(S.ScrollBarRect(saVert)));
  CheckTrue(IsRectEmpty(S.ScrollBarRect(saHorz)));
  CheckEquals(S.Width, S.ScrollBarRect(saVert).Right, 'rechts');
  S.SetContentSize(500, 2000);
  CheckFalse(IsRectEmpty(S.ScrollBarRect(saHorz)));
  CheckTrue(S.ScrollBarRect(saVert).Bottom <= S.ScrollBarRect(saHorz).Top,
    'Leisten ueberschneiden sich nicht');
  S.ScrollBarMode := sbmNever;
  CheckTrue(IsRectEmpty(S.ScrollBarRect(saVert)));
  CheckEquals(0.0, S.ScrollBarOpacity, 0.001);
  CheckEquals(S.Width, S.ViewRect.Right);
  S.ScrollBarMode := sbmAlways;
  B := S.ScrollBarRect(saVert).Right - S.ScrollBarRect(saVert).Left;
  CheckEquals(S.Width - B, S.ViewRect.Right, 'feste Leiste nimmt Platz weg');
  CheckEquals(S.Height - B, S.ViewRect.Bottom);
  CheckEquals(1.0, S.ScrollBarOpacity, 0.001);
  CheckEquals(1.0, S.ScrollBarExpand(saVert), 0.001, 'immer breit');
end;

procedure TScrollControlTests.ScrollToClampsAndNotifies;
var
  S: TTestScroller;
begin
  S := NewScroller(100);
  S.ScrollTo(0, 99999);
  CheckEquals(2000 - S.Height, S.ScrollY, 'auf MaxScroll begrenzt');
  CheckEquals(S.MaxScroll(saVert), S.ScrollY);
  CheckEquals(1, S.Scrolls);
  S.ScrollY := -5;
  CheckEquals(0, S.ScrollY);
  CheckEquals(2, S.Scrolls);
  S.ScrollY := 0;
  CheckEquals(2, S.Scrolls, 'keine Aenderung: kein OnScroll');
  S.ScrollY := 1500;
  S.Height := 700;
  CheckEquals(2000 - 700, S.ScrollY, 'groessere Ansicht begrenzt');
  S.SetContentSize(180, 100);
  CheckEquals(0, S.ScrollY, 'kleinerer Inhalt begrenzt');
end;

procedure TScrollControlTests.WheelScrollsLinesAndKeepsRest;
var
  S: TTestScroller;
  I: Integer;
begin
  S := NewScroller(100, 20);
  CheckFalse(TTestScroller(S).DoMouseWheel([], WHEEL_DELTA, Point(0, 0)),
    'oben: nach oben nichts zu tun');
  CheckTrue(S.DoMouseWheel([], -WHEEL_DELTA, Point(0, 0)));
  CheckEquals(WheelLines * 20, S.ScrollY, 'Zeilen laut Systemeinstellung');
  S.ScrollY := 0;
  // Touchpad: vier Viertelschritte = ein Radschritt
  for I := 1 to 4 do
    CheckTrue(S.DoMouseWheel([], -WHEEL_DELTA div 4, Point(0, 0)));
  CheckEquals(WheelLines * 20, S.ScrollY, 'Teilschritte summieren sich');
  S.ScrollY := S.MaxScroll(saVert);
  CheckFalse(S.DoMouseWheel([], -WHEEL_DELTA, Point(0, 0)), 'unten: nicht verbraucht');
end;

procedure TScrollControlTests.HorizontalWheel;
var
  S: TTestScroller;
  X: Integer;
begin
  S := NewScroller(100, 20);
  S.SetContentSize(1000, 2000);
  CheckTrue(S.DoMouseWheel([ssShift], -WHEEL_DELTA, Point(0, 0)));
  CheckTrue(S.ScrollX > 0, 'Umschalt+Rad waagerecht');
  CheckEquals(0, S.ScrollY);
  X := S.ScrollX;
  S.Perform(WM_MOUSEHWHEEL, WPARAM(Cardinal(WHEEL_DELTA) shl 16), 0);
  CheckTrue(S.ScrollX > X, 'Kipprad nach rechts');
  S.SetContentSize(1000, 100); // nur waagerecht scrollbar
  S.ScrollX := 0;
  CheckTrue(S.DoMouseWheel([], -WHEEL_DELTA, Point(0, 0)));
  CheckTrue(S.ScrollX > 0, 'nur waagerechter Ueberlauf: Rad scrollt waagerecht');
end;

procedure TScrollControlTests.ThumbDragScrollsProportionally;
var
  S: TTestScroller;
  Th, Tr: TRect;
  P: TPoint;
  Range: Integer;
begin
  FForm.Show;
  try
    S := NewScroller(200, 20);
    Th := S.ThumbRect(saVert);
    Tr := S.ScrollBarRect(saVert);
    P := CenterOf(Th);
    Range := (Tr.Bottom - Tr.Top) - (Th.Bottom - Th.Top);
    S.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
    S.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P.X, P.Y + Range div 2));
    CheckTrue(Abs(S.ScrollY - S.MaxScroll(saVert) div 2) <= S.MaxScroll(saVert) div 50,
      Format('halbe Strecke: %d von %d', [S.ScrollY, S.MaxScroll(saVert)]));
    S.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(P.X, P.Y + Range * 3));
    CheckEquals(S.MaxScroll(saVert), S.ScrollY, 'begrenzt');
    S.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y + Range * 3));
    CheckEquals(0, S.Downs, 'kein Inhalts-Klick');
  finally
    FForm.Hide;
  end;
end;

procedure TScrollControlTests.TrackClickPages;
var
  S: TTestScroller;
  Th: TRect;
  Page: Integer;
begin
  S := NewScroller(200, 20);
  Th := S.ThumbRect(saVert);
  Page := (S.ViewRect.Bottom - S.ViewRect.Top) * 9 div 10;
  ClickAt(S, CenterOf(Th).X, Th.Bottom + 10);
  CheckEquals(Page, S.ScrollY, 'eine Seite weiter');
  Th := S.ThumbRect(saVert);
  ClickAt(S, CenterOf(Th).X, Th.Top - 2);
  CheckEquals(0, S.ScrollY, 'und zurueck');
end;

procedure TScrollControlTests.SmoothScrollReachesTarget;
var
  S: TTestScroller;
begin
  FForm.Show;
  try
    S := NewScroller(200, 20);
    S.Animation.Enabled := True;
    S.Animation.RespectSystemSettings := False;
    S.ScrollTo(0, 500, True);
    CheckTrue(S.Scrolling, 'weich');
    CheckTrue(S.ScrollY < 500);
    S.ScrollBy(0, 100, True);
    PumpTimers(400);
    CheckFalse(S.Scrolling);
    CheckEquals(600, S.ScrollY, 'Ziel aus beiden Schritten');
    S.SmoothScrolling := False;
    S.ScrollTo(0, 0, True);
    CheckEquals(0, S.ScrollY, 'SmoothScrolling aus: sofort');
  finally
    FForm.Hide;
  end;
end;

procedure TScrollControlTests.AutoModeFadesAndExpands;
var
  S: TTestScroller;
  P: TPoint;
begin
  FForm.Show;
  try
    S := NewScroller(200, 20);
    S.Animation.Enabled := True;
    S.Animation.RespectSystemSettings := False;
    if S.ScrollBarOpacity = 1 then
    begin
      // Windows-Einstellung "Bildlaufleisten immer anzeigen" ist aktiv:
      // dann sind die Leisten immer sichtbar und breit (wie sbmAlways)
      CheckEquals(1.0, S.ScrollBarExpand(saVert), 0.001);
      CheckTrue(S.ViewRect.Right < S.Width, 'Leiste nimmt Platz weg');
      Exit;
    end;
    CheckEquals(0.0, S.ScrollBarOpacity, 0.001, 'ruhend ausgeblendet');
    S.ScrollBy(0, 40);
    PumpTimers(200);
    CheckEquals(1.0, S.ScrollBarOpacity, 0.001, 'beim Scrollen eingeblendet');
    CheckEquals(0.0, S.ScrollBarExpand(saVert), 0.001, 'schmal');
    P := CenterOf(S.ScrollBarRect(saVert));
    S.Perform(WM_MOUSEMOVE, 0, MouseLParam(P.X, P.Y));
    PumpTimers(250);
    CheckEquals(1.0, S.ScrollBarExpand(saVert), 0.001, 'ueber der Leiste breit');
    S.Perform(WM_MOUSEMOVE, 0, MouseLParam(20, 20));
    PumpTimers(350);
    CheckEquals(0.0, S.ScrollBarExpand(saVert), 0.001, 'wieder schmal');
    S.Perform(CM_MOUSELEAVE, 0, 0);
    PumpTimers(1900);
    CheckEquals(0.0, S.ScrollBarOpacity, 0.001, 'nach der Ruhezeit ausgeblendet');
  finally
    FForm.Hide;
  end;
end;

procedure TScrollControlTests.RtlPutsVerticalBarLeft;
var
  S: TTestScroller;
begin
  S := NewScroller(200, 20);
  S.BiDiMode := bdRightToLeft;
  CheckEquals(0, S.ScrollBarRect(saVert).Left, 'RTL: links');
  S.ScrollBarMode := sbmAlways;
  CheckTrue(S.ViewRect.Left > 0, 'Ansicht rechts daneben');
end;

procedure TScrollControlTests.MakeVisibleScrollsMinimal;
var
  S: TTestScroller;
  VH: Integer;
begin
  S := NewScroller(200, 20);
  VH := S.ViewRect.Bottom - S.ViewRect.Top;
  S.MakeVisible(Rect(0, 1000, 10, 1020));
  CheckEquals(1020 - VH, S.ScrollY, 'unten an den Rand');
  S.MakeVisible(Rect(0, 1000, 10, 1020));
  CheckEquals(1020 - VH, S.ScrollY, 'schon sichtbar: bleibt');
  S.MakeVisible(Rect(0, 100, 10, 120));
  CheckEquals(100, S.ScrollY, 'oben an den Rand');
end;

procedure TScrollControlTests.KeyboardScrolls;
var
  S: TTestScroller;
  Page: Integer;
begin
  S := NewScroller(200, 20);
  CheckTrue(S.Perform(WM_GETDLGCODE, 0, 0) and DLGC_WANTARROWS <> 0);
  S.Perform(WM_KEYDOWN, VK_DOWN, 0);
  CheckEquals(20, S.ScrollY, 'Zeile');
  Page := (S.ViewRect.Bottom - S.ViewRect.Top) * 9 div 10;
  S.Perform(WM_KEYDOWN, VK_NEXT, 0);
  CheckEquals(20 + Page, S.ScrollY, 'Seite');
  S.Perform(WM_KEYDOWN, VK_UP, 0);
  CheckEquals(Page, S.ScrollY);
end;

procedure TScrollControlTests.AutoScrollWhileDragging;
var
  S: TTestScroller;
  Y: Integer;
begin
  FForm.Show;
  try
    S := NewScroller(200, 20);
    S.AutoScrollAt(50, S.Height + 40);
    PumpTimers(250);
    CheckTrue(S.ScrollY > 0, 'scrollt nach unten');
    CheckTrue(S.AutoScrolls > 0, 'DoAutoScroll gerufen');
    S.AutoScrollAt(50, 50); // wieder innen: Stopp
    Y := S.ScrollY;
    PumpTimers(150);
    CheckEquals(Y, S.ScrollY, 'innen kein Auto-Scroll');
    S.AutoScrollAt(50, -60);
    PumpTimers(150);
    CheckTrue(S.ScrollY < Y, 'nach oben');
    S.StopAutoScroll;
    Y := S.ScrollY;
    PumpTimers(100);
    CheckEquals(Y, S.ScrollY);
  finally
    FForm.Hide;
  end;
end;

procedure TScrollControlTests.ContentMouseOnlyOutsideBars;
var
  S: TTestScroller;
  P: TPoint;
begin
  S := NewScroller(200, 20);
  S.ScrollBarMode := sbmAlways;
  ClickAt(S, 20, 20);
  CheckEquals(1, S.Downs);
  P := CenterOf(S.ScrollBarRect(saVert));
  ClickAt(S, P.X, P.Y);
  CheckEquals(1, S.Downs, 'Leiste: kein Inhalts-Klick');
end;

procedure TScrollControlTests.PaintsThumbBothPresetsAndGdi;
const
  Presets: array[0..1] of string = (PPGPresetModernFlat, PPGPresetClassic);
var
  S: TTestScroller;
  Bmp: TBitmap;
  Gdi: Boolean;
  I: Integer;
  P: TPoint;
begin
  S := NewScroller(200, 20);
  S.ScrollBarMode := sbmAlways;
  S.ScrollY := 600;
  for Gdi := False to True do
    for I := 0 to High(Presets) do
    begin
      TPPGRendererRegistry.ForceGdiFallback := Gdi;
      S.Preset := Presets[I];
      Bmp := RenderToBitmap(S);
      try
        P := CenterOf(S.ThumbRect(saVert));
        CheckTrue(ColorDist(Bmp.Canvas.Pixels[P.X, P.Y], S.Color) > 60,
          Presets[I] + ': Daumen sichtbar');
        P := Point(CenterOf(S.ThumbRect(saVert)).X, S.ThumbRect(saVert).Top - 6);
        CheckTrue(ColorDist(Bmp.Canvas.Pixels[P.X, P.Y], S.Color) < 60,
          Presets[I] + ': Spur nur dezent');
        CheckEquals(ColorToRGB(clWhite), Bmp.Canvas.Pixels[10, 10],
          'Inhalt verschoben gezeichnet');
      finally
        Bmp.Free;
      end;
    end;
  TPPGRendererRegistry.ForceGdiFallback := False;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TScrollControlTests.NoHandleOrMemoryLeaks;

  procedure Cycle;
  var
    I: Integer;
    S: TTestScroller;
  begin
    for I := 1 to 20 do
    begin
      S := NewScroller(1000, 20);
      S.ScrollBy(0, 500);
      S.DoMouseWheel([], -WHEEL_DELTA, Point(0, 0));
      S.AutoScrollAt(10, 400);
      RenderToBitmap(S).Free;
      S.Free; // mit laufendem Auto-Scroll und Hold-Animation
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
    PumpTimers(50); // keine Animation darf auf freigegebene Controls zugreifen
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

{ TParentBackgroundTests }

type
  TContainerAccess = class(TPPGCustomContainer);

procedure TParentBackgroundTests.ChildInsidePanelUsesSurfaceColor;
var
  P: TPPGPanel;
  C: TPPGCheckBox;
  T, B: TColor;
  Bmp: TBitmap;
begin
  P := TPPGPanel.Create(FForm);
  P.Parent := FForm;
  P.Preset := PPGPresetModernFlat;
  P.Caption := '';
  P.SetBounds(10, 10, 300, 200);
  C := TPPGCheckBox.Create(FForm);
  C.Parent := P;
  C.Preset := PPGPresetModernFlat;
  C.Caption := 'X';
  C.SetBounds(20, 20, 150, 24);
  CheckTrue(TContainerAccess(P).GetChildBackground(C, T, B), 'schneller Weg');
  CheckEquals(Integer(PPGColorToRGB(P.Appearance.Normal.Color)), Integer(T));
  CheckEquals(Integer(T), Integer(B), 'einfarbig');
  Bmp := RenderToBitmap(C);
  try
    CheckEquals(Integer(ColorToRGB(T)), Integer(Bmp.Canvas.Pixels[C.Width - 3, 2]),
      'Kind zeigt die Panel-Flaeche');
  finally
    Bmp.Free;
  end;
end;

procedure TParentBackgroundTests.ClassicGradientFollowsPosition;
var
  P: TPPGPanel;
  C1, C2: TPPGCheckBox;
  T1, B1, T2, B2: TColor;
begin
  P := TPPGPanel.Create(FForm);
  P.Parent := FForm;
  P.Preset := PPGPresetClassic;
  P.Caption := '';
  P.SetBounds(10, 10, 300, 300);
  C1 := TPPGCheckBox.Create(FForm);
  C1.Parent := P;
  C1.SetBounds(20, 10, 150, 24);
  C2 := TPPGCheckBox.Create(FForm);
  C2.Parent := P;
  C2.SetBounds(20, 260, 150, 24);
  CheckTrue(TContainerAccess(P).GetChildBackground(C1, T1, B1));
  CheckTrue(TContainerAccess(P).GetChildBackground(C2, T2, B2));
  CheckTrue(T1 <> B2, 'Verlauf: oben anders als unten');
  CheckTrue(ColorDist(T1, P.Appearance.Normal.Color) < ColorDist(T1,
    P.Appearance.Normal.ColorMirrorTo), 'oben nahe der Anfangsfarbe');
  CheckTrue(ColorDist(B2, P.Appearance.Normal.ColorMirrorTo) < ColorDist(B2,
    P.Appearance.Normal.Color), 'unten nahe der Endfarbe');
end;

procedure TParentBackgroundTests.FallbackOnBorderAndCaption;
var
  P: TPPGPanel;
  C: TPPGCheckBox;
  T, B: TColor;
begin
  P := TPPGPanel.Create(FForm);
  P.Parent := FForm;
  P.SetBounds(10, 10, 300, 200);
  P.Caption := 'Mitte';
  C := TPPGCheckBox.Create(FForm);
  C.Parent := P;
  C.SetBounds(0, 0, 100, 24);
  CheckFalse(TContainerAccess(P).GetChildBackground(C, T, B), 'ueber Rahmen/Rundung');
  C.SetBounds(100, 88, 100, 24);
  CheckFalse(TContainerAccess(P).GetChildBackground(C, T, B), 'ueber der Beschriftung');
  P.ShowCaption := False;
  CheckTrue(TContainerAccess(P).GetChildBackground(C, T, B), 'Beschriftung aus');
  P.ShowCaption := True;
  C.SetBounds(20, 20, 100, 24);
  CheckTrue(TContainerAccess(P).GetChildBackground(C, T, B), 'neben der Beschriftung');
end;

procedure TParentBackgroundTests.GroupBoxAndPageAreFastToo;
var
  G: TPPGGroupBox;
  PC: TPPGPageControl;
  S: TPPGTabSheet;
  C: TPPGCheckBox;
  T, B: TColor;
begin
  G := TPPGGroupBox.Create(FForm);
  G.Parent := FForm;
  G.SetBounds(10, 10, 300, 200);
  G.Caption := 'Gruppe';
  C := TPPGCheckBox.Create(FForm);
  C.Parent := G;
  C.SetBounds(20, 40, 100, 24);
  CheckTrue(TContainerAccess(G).GetChildBackground(C, T, B), 'GroupBox');
  PC := TPPGPageControl.Create(FForm);
  PC.Parent := FForm;
  PC.SetBounds(10, 220, 300, 200);
  S := TPPGTabSheet.Create(FForm);
  S.PageControl := PC;
  C := TPPGCheckBox.Create(FForm);
  C.Parent := S;
  C.SetBounds(0, 0, 100, 24);
  CheckTrue(TContainerAccess(S).GetChildBackground(C, T, B), 'TabSheet: auch am Rand');
  CheckEquals(Integer(PC.PageColor), Integer(T));
end;

{ TMultiSelectAccessibilityTests }

procedure TMultiSelectAccessibilityTests.SelectionListsAllSelectedChildren;
var
  C: TMultiAccControl;
  Acc: IAccessible;
  V: OleVariant;
  E: IPPGEnumVariant;
  Buf: array[0..4] of OleVariant;
  Got: Cardinal;
begin
  C := TMultiAccControl.Create(FForm);
  C.Parent := FForm;
  C.HandleNeeded;
  Acc := AccOf(C);
  SetLength(C.Selected, 0);
  CheckEquals(S_FALSE, Acc.Get_accSelection(V), 'keine Auswahl');
  C.Selected := TArray<Integer>.Create(3);
  CheckEquals(S_OK, Acc.Get_accSelection(V));
  CheckEquals(3, Integer(V), 'eine Auswahl: VT_I4');
  C.Selected := TArray<Integer>.Create(2, 4, 5);
  CheckEquals(S_OK, Acc.Get_accSelection(V));
  CheckEquals(varUnknown, VarType(V), 'mehrere: Enumerator');
  CheckTrue(Supports(IUnknown(V), IPPGEnumVariant, E));
  Got := 0;
  CheckEquals(S_FALSE, E.Next(5, @Buf[0], @Got));
  CheckEquals(3, Integer(Got));
  CheckEquals(2, Integer(Buf[0]));
  CheckEquals(4, Integer(Buf[1]));
  CheckEquals(5, Integer(Buf[2]));
end;

procedure TMultiSelectAccessibilityTests.AccSelectIsForwarded;
var
  C: TMultiAccControl;
  Acc: IAccessible;
begin
  C := TMultiAccControl.Create(FForm);
  C.Parent := FForm;
  C.HandleNeeded;
  Acc := AccOf(C);
  CheckEquals(S_OK, Acc.accSelect(SELFLAG_ADDSELECTION, 4));
  CheckEquals(4, C.LastSelectId);
  CheckEquals(SELFLAG_ADDSELECTION, C.LastSelectFlags);
end;

initialization
  RegisterTest('Phase5', TRowLayoutTests.Suite);
  RegisterTest('Phase5', TSelectionTests.Suite);
  RegisterTest('Phase5', TItemSourceTests.Suite);
  RegisterTest('Phase5', TMarkupTests.Suite);
  RegisterTest('Phase5', TScrollControlTests.Suite);
  RegisterTest('Phase5', TParentBackgroundTests.Suite);
  RegisterTest('Phase5', TMultiSelectAccessibilityTests.Suite);

end.
