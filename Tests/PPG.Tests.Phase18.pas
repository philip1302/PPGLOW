unit PPG.Tests.Phase18;

{ Tests fuer Phase 18: Controls mit Mehrwert.
  18a: TPPGRadioGroup/TPPGCheckGroup (ChoiceStyle, ItemsEx, Columns = 0,
  ValidationState, Tastatur, Maus, Barrierefreiheit, DFM wie TRadioGroup). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Graphics, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  PPG.Types, PPG.Controls.Field, PPG.RadioGroup, PPG.Items, PPG.Controls.Scroll, PPG.TileView,
  PPG.Grid.Data, PPG.Grid.Export, Data.DB, Datasnap.DBClient, MidasLib, Vcl.DBCtrls,
  PPG.DB.Navigator, PPG.Panel, PPG.Edit, PPG.Tests.Controls;

type
  TChoiceGroupTests = class(TControlTestCase)
  private
    FClicks, FChanges: Integer;
    FLog: string;
    procedure GroupClick(Sender: TObject);
    procedure GroupChange(Sender: TObject);
    procedure ItemClick(Sender: TObject; Index: Integer);
    function NewRadio(const Items: array of string): TPPGRadioGroup;
    function NewCheck(const Items: array of string): TPPGCheckGroup;
    procedure ClickItem(G: TPPGCustomChoiceGroup; Index: Integer);
    procedure Key(G: TWinControl; AKey: Word);
  protected
    procedure SetUp; override;
  published
    procedure LoadsTRadioGroupDfm;
    procedure ItemsIsViewOnItemsEx;
    procedure StreamsOnlyWhatIsNeeded;
    procedure CodeSetsWithoutEvents;
    procedure MouseSelectsAndFiresClickThenChange;
    procedure MouseReleasedElsewhereDoesNothing;
    procedure DisabledItemsAreSkipped;
    procedure KeyboardRadioFollowsFocus;
    procedure KeyboardCheckGroupSpaceToggles;
    procedure AcceleratorSelectsItem;
    procedure ListIsColumnMajorLikeVcl;
    procedure AutoColumnsFollowWidth;
    procedure CardsAndSegmentsAreRowMajor;
    procedure InvalidValuesRaiseAndKeepState;
    procedure ValueRoundTrip;
    procedure GrayedCycleOnlyWithAllowGrayed;
    procedure AccessibleChildren;
    procedure PaintsAllStylesGdiPlusAndGdi;
    procedure SegmentShowsAccentOnSelection;
    procedure ValidationErrorFrameIsDanger;
    procedure RightToLeftMirrorsColumns;
  end;

  TTileViewTests = class(TControlTestCase)
  private
    FChanges, FClicks: Integer;
    FLastClick: Integer;
    procedure ViewChange(Sender: TObject);
    procedure ViewItemClick(Sender: TObject; Index: Integer);
    procedure GetVirtual(Sender: TObject; Index: Integer; var Data: TPPGItemData);
    procedure GetIcon(Sender: TObject; Index: Integer; var CodePoint: Word);
    function NewView(Count: Integer; Groups: Boolean = False): TPPGTileView;
    procedure ClickAt(V: TPPGTileView; X, Y: Integer; Keys: Integer = 0);
    procedure ClickItem(V: TPPGTileView; Index: Integer; Keys: Integer = 0);
  protected
    procedure SetUp; override;
  published
    procedure GridLayoutFillsRows;
    procedure StylesChangeTileSize;
    procedure FilterHidesAndCountsMatches;
    procedure GroupsCollapse;
    procedure VirtualHundredThousand;
    procedure CodeSelectsWithoutEvents;
    procedure ClickSelectsAndFiresEvents;
    procedure MultiSelectCtrlShiftAndSelectAll;
    procedure KeyboardMovesInTwoDimensions;
    procedure RubberBandSelects;
    procedure CtrlWheelZooms;
    procedure CheckboxClickToggles;
    procedure RenameWithF2;
    procedure TypeAheadFindsItem;
    procedure ExportsAsTable;
    procedure AccessibleChildren;
    procedure PaintsAllStylesGdiPlusAndGdi;
    procedure StreamsItemsAndStyle;
  end;

  TDBNavigatorTests = class(TControlTestCase)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    FNav: TPPGDBNavigator;
    FLog: string;
    procedure NavBefore(Sender: TObject; Button: TNavigateBtn);
    procedure NavClick(Sender: TObject; Button: TNavigateBtn);
    procedure OwnFilter(DataSet: TDataSet; var Accept: Boolean);
    function VisibleRecords: Integer;
    procedure ClickButton(Btn: TNavigateBtn);
  protected
    procedure SetUp; override;
  published
    procedure ButtonStatesFollowDataSet;
    procedure CounterShowsPosition;
    procedure ClickRunsActionWithEvents;
    procedure SearchFindsAndWraps;
    procedure QuickFilterChainsAndRestores;
    procedure OverflowWhenNarrow;
    procedure KeyboardShortcuts;
    procedure AccessibleButtons;
    procedure StreamsLikeTDBNavigator;
    procedure PaintsWithoutErrors;
    procedure RadioGroupReadsAndWritesField;
  end;

  TPanelScrollTests = class(TControlTestCase)
  private
    function NewPanel(AutoScroll: Boolean): TPPGPanel;
    function AddChild(P: TWinControl; X, Y: Integer): TPPGEdit;
  published
    procedure NoScrollingByDefault;
    procedure AutoScrollShowsBarForChildBelow;
    procedure ScrollToMovesChildrenAndClamps;
    procedure ScrollInViewAndFocus;
    procedure WheelScrolls;
    procedure FixedRangeWithoutAutoScroll;
    procedure AlignedChildScrollsAlong;
    procedure DragThumbScrolls;
    procedure ScrollBoxLoadsTScrollBoxDfm;
    procedure InvalidValuesRaise;
    procedure PaintsWithBars;
  end;

implementation

uses
  PPG.Tests.Visual,
  Vcl.Imaging.pngimage, PPG.Lang, PPG.Consts, Winapi.oleacc, PPG.Exceptions, PPG.Accessibility, PPG.Render.Registry, PPG.Tokens;

type
  TGroupAccess = class(TPPGCustomChoiceGroup);
  TNavAccess = class(TPPGCustomDBNavigator);
  TPanelAccess = class(TPPGCustomPanel);

/// Bild zur Sichtpruefung nach Tests\Visual\Gallery (wie die Sichttests).
procedure SaveGalleryPng(B: TBitmap; const FileName: string);
var
  Png: TPngImage;
  Dir: string;
begin
  Dir := ExtractFilePath(ParamStr(0)) + 'Visual\Gallery\';
  ForceDirectories(Dir);
  Png := TPngImage.Create;
  try
    Png.Assign(B);
    Png.SaveToFile(Dir + FileName);
  finally
    Png.Free;
  end;
end;

{ TChoiceGroupTests }

procedure TChoiceGroupTests.SetUp;
begin
  inherited SetUp;
  FClicks := 0;
  FChanges := 0;
  FLog := '';
end;

procedure TChoiceGroupTests.GroupClick(Sender: TObject);
begin
  Inc(FClicks);
  FLog := FLog + 'C';
end;

procedure TChoiceGroupTests.GroupChange(Sender: TObject);
begin
  Inc(FChanges);
  FLog := FLog + 'H';
end;

procedure TChoiceGroupTests.ItemClick(Sender: TObject; Index: Integer);
begin
  FLog := FLog + 'I' + IntToStr(Index);
end;

function TChoiceGroupTests.NewRadio(const Items: array of string): TPPGRadioGroup;
var
  S: string;
begin
  Result := TPPGRadioGroup.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 300, 160);
  Result.Caption := 'Farbe';
  for S in Items do
    Result.Items.Add(S);
  Result.OnClick := GroupClick;
  Result.OnChange := GroupChange;
end;

function TChoiceGroupTests.NewCheck(const Items: array of string): TPPGCheckGroup;
var
  S: string;
begin
  Result := TPPGCheckGroup.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 300, 160);
  for S in Items do
    Result.Items.Add(S);
  Result.OnClick := GroupClick;
  Result.OnChange := GroupChange;
  Result.OnItemClick := ItemClick;
end;

procedure TChoiceGroupTests.ClickItem(G: TPPGCustomChoiceGroup; Index: Integer);
var
  R: TRect;
  P: LPARAM;
begin
  R := G.ItemRect(Index);
  P := MakeLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
  G.Perform(WM_MOUSEMOVE, 0, P);
  G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, P);
  G.Perform(WM_LBUTTONUP, 0, P);
end;

procedure TChoiceGroupTests.Key(G: TWinControl; AKey: Word);
begin
  G.Perform(WM_KEYDOWN, AKey, 0);
end;

procedure TChoiceGroupTests.LoadsTRadioGroupDfm;
const
  Dfm =
    'object RadioGroup1: TPPGRadioGroup'#13#10 +
    '  Left = 8'#13#10 +
    '  Top = 8'#13#10 +
    '  Width = 200'#13#10 +
    '  Height = 105'#13#10 +
    '  Caption = ''Zahlung'''#13#10 +
    '  Columns = 2'#13#10 +
    '  ItemIndex = 1'#13#10 +
    '  Items.Strings = ('#13#10 +
    '    ''Bar'''#13#10 +
    '    ''&Karte'''#13#10 +
    '    ''Rechnung'')'#13#10 +
    '  TabOrder = 0'#13#10 +
    'end';
var
  Src: TStringStream;
  Bin: TMemoryStream;
  G: TPPGRadioGroup;
begin
  // ItemIndex steht in VCL-DFMs vor Items: beim Laden darf das nicht scheitern
  Src := TStringStream.Create(Dfm);
  Bin := TMemoryStream.Create;
  try
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    G := TPPGRadioGroup.Create(FForm);
    Bin.ReadComponent(G);
    G.Parent := FForm;
    CheckEquals(3, G.Items.Count);
    CheckEquals('&Karte', G.Items[1]);
    CheckEquals(1, G.ItemIndex);
    CheckEquals(2, G.Columns);
    CheckEquals('Zahlung', G.Caption);
    CheckEquals(3, G.ItemsEx.Count, 'ItemsEx folgt Items');
  finally
    Bin.Free;
    Src.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TChoiceGroupTests.ItemsIsViewOnItemsEx;
var
  G: TPPGRadioGroup;
  O: TObject;
begin
  G := NewRadio(['A', 'B']);
  G.Items.Insert(1, 'X');
  CheckEquals('X', G.ItemsEx[1].Caption);
  G.ItemsEx[2].Caption := 'Bneu';
  CheckEquals('Bneu', G.Items[2]);
  O := TObject.Create;
  try
    G.Items.Objects[0] := O;
    CheckSame(O, G.ItemsEx[0].Data);
  finally
    O.Free;
  end;
  G.ItemIndex := 2;
  G.Items.Delete(2);
  CheckEquals(-1, G.ItemIndex, 'geloeschter gewaehlter Eintrag');
  G.Items.Clear;
  CheckEquals(0, G.Count);
end;

procedure TChoiceGroupTests.StreamsOnlyWhatIsNeeded;
var
  G, G2: TPPGRadioGroup;
  M: TMemoryStream;
  Txt: TStringStream;
  S: string;

  function AsText(C: TComponent): string;
  begin
    M.Clear;
    M.WriteComponent(C);
    M.Position := 0;
    Txt.Size := 0;
    ObjectBinaryToText(M, Txt);
    Result := Txt.DataString;
  end;

begin
  G := NewRadio(['Eins', 'Zwei']);
  M := TMemoryStream.Create;
  Txt := TStringStream.Create('');
  try
    S := AsText(G);
    CheckTrue(Pos('Items.Strings', S) > 0, 'einfache Eintraege wie TRadioGroup');
    CheckEquals(0, Pos('ItemsEx', S));
    G.ItemsEx[1].Description := 'Zweite Wahl';
    G.ItemsEx[1].Icon := $E80F;
    G.ItemsEx[0].Enabled := False;
    G.ChoiceStyle := csCards;
    G.Columns := 0;
    S := AsText(G);
    CheckTrue(Pos('ItemsEx', S) > 0, 'mit Extras: ItemsEx');
    CheckEquals(0, Pos('Items.Strings', S), 'nicht doppelt');
    M.Position := 0;
    G2 := TPPGRadioGroup.Create(FForm);
    M.ReadComponent(G2);
    CheckEquals(2, G2.Count);
    CheckEquals('Zweite Wahl', G2.ItemsEx[1].Description);
    CheckEquals($E80F, G2.ItemsEx[1].Icon);
    CheckFalse(G2.ItemsEx[0].Enabled);
    CheckTrue(G2.ChoiceStyle = csCards);
    CheckEquals(0, G2.Columns);
  finally
    Txt.Free;
    M.Free;
  end;
end;

procedure TChoiceGroupTests.CodeSetsWithoutEvents;
var
  G: TPPGRadioGroup;
  C: TPPGCheckGroup;
begin
  G := NewRadio(['A', 'B', 'C']);
  G.ItemIndex := 2;
  CheckEquals(2, G.ItemIndex);
  CheckTrue(G.Checked[2]);
  G.Checked[0] := True;
  CheckEquals(0, G.ItemIndex);
  CheckEquals(0, FClicks + FChanges, 'Code setzt ohne Ereignis');
  C := NewCheck(['A', 'B']);
  C.Checked[1] := True;
  CheckTrue(C.Checked[1]);
  CheckEquals('', FLog, 'Code setzt ohne Ereignis');
end;

procedure TChoiceGroupTests.MouseSelectsAndFiresClickThenChange;
var
  G: TPPGRadioGroup;
  C: TPPGCheckGroup;
begin
  G := NewRadio(['A', 'B', 'C']);
  ClickItem(G, 1);
  CheckEquals(1, G.ItemIndex);
  CheckEquals('CH', FLog, 'erst OnClick, dann OnChange');
  ClickItem(G, 1);
  CheckEquals('CH', FLog, 'erneut derselbe Eintrag: kein Ereignis');
  G.Free;
  FLog := '';
  C := NewCheck(['A', 'B']);
  ClickItem(C, 0);
  CheckTrue(C.Checked[0]);
  CheckEquals('I0CH', FLog);
  ClickItem(C, 0);
  CheckFalse(C.Checked[0], 'zweiter Klick nimmt das Haekchen');
end;

procedure TChoiceGroupTests.MouseReleasedElsewhereDoesNothing;
var
  G: TPPGRadioGroup;
  R0, R2: TRect;
begin
  G := NewRadio(['A', 'B', 'C']);
  R0 := G.ItemRect(0);
  R2 := G.ItemRect(2);
  G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(R0.Left + 4, (R0.Top + R0.Bottom) div 2));
  G.Perform(WM_LBUTTONUP, 0, MakeLParam(R2.Left + 4, (R2.Top + R2.Bottom) div 2));
  CheckEquals(-1, G.ItemIndex, 'wie ein Button: nur auf demselben Eintrag');
  CheckEquals(0, FClicks);
end;

procedure TChoiceGroupTests.DisabledItemsAreSkipped;
var
  G: TPPGRadioGroup;
begin
  G := NewRadio(['A', 'B', 'C']);
  G.ItemEnabled[1] := False;
  ClickItem(G, 1);
  CheckEquals(-1, G.ItemIndex, 'gesperrter Eintrag laesst sich nicht klicken');
  G.ItemIndex := 0;
  G.FocusIndex := 0;
  Key(G, VK_DOWN);
  CheckEquals(2, G.ItemIndex, 'Pfeil ueberspringt den gesperrten Eintrag');
end;

procedure TChoiceGroupTests.KeyboardRadioFollowsFocus;
var
  G: TPPGRadioGroup;
begin
  G := NewRadio(['A', 'B', 'C', 'D']);
  FForm.Show;
  G.SetFocus;
  CheckEquals(0, G.FocusIndex, 'Fokus auf dem ersten Eintrag');
  Key(G, VK_DOWN);
  CheckEquals(1, G.ItemIndex, 'Auswahl folgt dem Fokus');
  Key(G, VK_END);
  CheckEquals(3, G.ItemIndex);
  Key(G, VK_HOME);
  CheckEquals(0, G.ItemIndex);
  Key(G, VK_UP);
  CheckEquals(0, G.ItemIndex, 'am Anfang bleibt es stehen');
  CheckEquals(3, FChanges);
  CheckTrue(G.Perform(WM_GETDLGCODE, 0, 0) and DLGC_WANTARROWS <> 0);
end;

procedure TChoiceGroupTests.KeyboardCheckGroupSpaceToggles;
var
  C: TPPGCheckGroup;
begin
  C := NewCheck(['A', 'B', 'C']);
  FForm.Show;
  C.SetFocus;
  Key(C, VK_DOWN);
  CheckEquals(1, C.FocusIndex);
  CheckFalse(C.Checked[1], 'Pfeil bewegt nur den Fokus');
  Key(C, VK_SPACE);
  CheckTrue(C.Checked[1], 'Leertaste kreuzt an');
  CheckEquals('I1CH', FLog);
end;

procedure TChoiceGroupTests.AcceleratorSelectsItem;
var
  G: TPPGRadioGroup;
begin
  G := NewRadio(['&Rot', '&Gruen']);
  FForm.Show;
  G.Perform(CM_DIALOGCHAR, Ord('g'), 0);
  CheckEquals(1, G.ItemIndex);
  CheckEquals(1, FChanges);
end;

procedure TChoiceGroupTests.ListIsColumnMajorLikeVcl;
var
  G: TPPGRadioGroup;
  R0, R1, R2: TRect;
begin
  G := NewRadio(['A', 'B', 'C', 'D']);
  G.Columns := 2;
  R0 := G.ItemRect(0);
  R1 := G.ItemRect(1);
  R2 := G.ItemRect(2);
  CheckEquals(R0.Left, R1.Left, 'zweiter Eintrag unter dem ersten');
  CheckTrue(R1.Top > R0.Top);
  CheckTrue(R2.Left > R0.Left, 'dritter Eintrag in der zweiten Spalte');
  CheckEquals(R0.Top, R2.Top);
  CheckTrue(PtInRect(G.ClientRect, Point(R1.Left, R1.Bottom - 1)), 'innerhalb des Controls');
  CheckEquals(1, G.ItemAt(R1.Left + 2, R1.Top + 2));
  CheckEquals(-1, G.ItemAt(-5, -5));
end;

procedure TChoiceGroupTests.AutoColumnsFollowWidth;
var
  G: TPPGRadioGroup;
begin
  G := NewRadio(['Ja', 'Nein', 'Vielleicht', 'Egal']);
  G.Columns := 0;
  G.Width := 600;
  CheckEquals(G.ItemRect(0).Top, G.ItemRect(3).Top, 'breit: alle nebeneinander');
  G.Width := 120;
  CheckEquals(G.ItemRect(0).Left, G.ItemRect(3).Left, 'schmal: untereinander');
  G.Width := 250;
  CheckEquals(G.ItemRect(0).Top, G.ItemRect(1).Top, 'nach Breite zeilenweise: Nachbar rechts');
  CheckTrue(G.ItemRect(1).Left > G.ItemRect(0).Left);
end;

procedure TChoiceGroupTests.CardsAndSegmentsAreRowMajor;
var
  G: TPPGRadioGroup;
begin
  G := NewRadio(['Tag', 'Woche', 'Monat']);
  G.ChoiceStyle := csSegmented;
  G.ShowFrame := False;
  CheckEquals(G.ItemRect(0).Top, G.ItemRect(2).Top, 'Segmente in einer Zeile');
  CheckEquals(G.ItemRect(0).Right, G.ItemRect(1).Left, 'lueckenlos');
  CheckEquals(G.ClientWidth, G.ItemRect(2).Right, 'bis zum rechten Rand');
  G.ChoiceStyle := csCards;
  G.Columns := 2;
  G.Height := 300;
  CheckEquals(G.ItemRect(0).Top, G.ItemRect(1).Top, 'Kacheln zeilenweise');
  CheckTrue(G.ItemRect(2).Top > G.ItemRect(0).Bottom);
end;

procedure TChoiceGroupTests.InvalidValuesRaiseAndKeepState;
var
  G: TPPGRadioGroup;
  C: TPPGCheckGroup;
begin
  G := NewRadio(['A', 'B']);
  G.ItemIndex := 1;
  try
    G.ItemIndex := 5;
    Fail('ItemIndex ausserhalb muss werfen');
  except
    on EPPGError do
  end;
  CheckEquals(1, G.ItemIndex, 'unveraendert');
  try
    G.Columns := 17;
    Fail('Columns ausserhalb muss werfen');
  except
    on EPPGError do
  end;
  CheckEquals(1, G.Columns);
  try
    G.Checked[9] := True;
    Fail('Index ausserhalb muss werfen');
  except
    on EPPGError do
  end;
  C := NewCheck(['A']);
  try
    C.ItemState[0] := cbGrayed;
    Fail('grau nur mit AllowGrayed');
  except
    on EPPGError do
  end;
  CheckFalse(C.Checked[0]);
end;

procedure TChoiceGroupTests.ValueRoundTrip;
var
  G: TPPGRadioGroup;
  C: TPPGCheckGroup;
begin
  G := NewRadio(['Bar', 'Karte']);
  G.ItemsEx[1].Value := 'card';
  G.Value := 'card';
  CheckEquals(1, G.ItemIndex);
  CheckEquals('card', G.Value);
  G.Value := 'bar';
  CheckEquals(0, G.ItemIndex, 'ohne Value zaehlt die Beschriftung');
  G.Value := 'gibt es nicht';
  CheckEquals(-1, G.ItemIndex);
  C := NewCheck(['Mo', 'Di', 'Mi']);
  C.Value := 'Mo,Mi';
  CheckTrue(C.Checked[0] and not C.Checked[1] and C.Checked[2]);
  CheckEquals('Mo,Mi', C.Value);
end;

procedure TChoiceGroupTests.GrayedCycleOnlyWithAllowGrayed;
var
  C: TPPGCheckGroup;
begin
  C := NewCheck(['A']);
  C.AllowGrayed := True;
  ClickItem(C, 0);
  ClickItem(C, 0);
  CheckTrue(C.ItemState[0] = cbGrayed, 'an -> grau');
  ClickItem(C, 0);
  CheckTrue(C.ItemState[0] = cbUnchecked);
  C.ItemState[0] := cbGrayed;
  C.AllowGrayed := False;
  CheckTrue(C.ItemState[0] = cbUnchecked, 'ohne AllowGrayed kein Grau');
end;

procedure TChoiceGroupTests.AccessibleChildren;
var
  G: TPPGRadioGroup;
  A: IPPGAccessibleChildren;
begin
  G := NewRadio(['A', 'B']);
  G.ItemsEx[1].Description := 'zweite';
  G.ItemIndex := 1;
  CheckTrue(Supports(G, IPPGAccessibleChildren, A));
  CheckEquals(2, A.AccChildCount);
  CheckEquals('B, zweite', A.AccChildName(2));
  CheckEquals(ROLE_SYSTEM_RADIOBUTTON, A.AccChildRole(1));
  CheckTrue(A.AccChildState(2) and STATE_SYSTEM_CHECKED <> 0);
  CheckEquals(2, A.AccSelectedChild);
  G.ItemEnabled[0] := False;
  CheckEquals(STATE_SYSTEM_UNAVAILABLE, A.AccChildState(1));
  CheckEquals(1, A.AccChildAt(G.ItemRect(0).Left + 2, G.ItemRect(0).Top + 2));
  CheckEquals('B', TGroupAccess(G).AccValue);
end;

procedure TChoiceGroupTests.PaintsAllStylesGdiPlusAndGdi;
var
  G: TPPGRadioGroup;
  C: TPPGCheckGroup;
  St: TPPGChoiceStyle;
  Gdi: Boolean;
  B: TBitmap;
begin
  G := NewRadio(['Eins', 'Zwei', 'Drei']);
  G.ItemsEx[0].Icon := $E80F;
  G.ItemsEx[1].Description := 'Mit einer laengeren Beschreibung, die umbricht';
  G.ItemIndex := 1;
  C := NewCheck(['A', 'B']);
  C.Top := 200;
  C.AllowGrayed := True;
  C.ItemState[1] := cbGrayed;
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    try
      for St := Low(TPPGChoiceStyle) to High(TPPGChoiceStyle) do
      begin
        G.ChoiceStyle := St;
        C.ChoiceStyle := St;
        G.Enabled := True;
        PPGPaintCheck(Self, G, 'G');
        PPGPaintCheck(Self, C, 'C');
        G.Enabled := False;
        PPGPaintCheck(Self, G, 'G');
      end;
    finally
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
  // Audit 11b: Zustaende sichtbar (GDI+ und GDI): Hover auf dem ersten Eintrag,
  // Fokus, Deaktiviert
  FForm.Show;
  G.ChoiceStyle := Low(TPPGChoiceStyle);
  C.ChoiceStyle := Low(TPPGChoiceStyle);
  G.Enabled := True;
  PPGCheckStates(Self, G, 'RadioGroup', True, True, True,
    Point(G.ItemRect(0).Left + 8, (G.ItemRect(0).Top + G.ItemRect(0).Bottom) div 2));
  PPGCheckStates(Self, C, 'CheckGroup', True, True, True,
    Point(C.ItemRect(0).Left + 8, (C.ItemRect(0).Top + C.ItemRect(0).Bottom) div 2));
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TChoiceGroupTests.SegmentShowsAccentOnSelection;
var
  G: TPPGRadioGroup;
  B: TBitmap;
  R: TRect;
  Px, Other: TColor;
begin
  G := NewRadio(['Tag', 'Woche', 'Monat']);
  G.ChoiceStyle := csSegmented;
  G.ShowFrame := False;
  G.Height := 40;
  G.ItemIndex := 2;
  B := RenderToBitmap(G);
  try
    // Ecke des gewaehlten Segments (neben dem Text) in Akzentfarbe
    R := G.ItemRect(2);
    Px := B.Canvas.Pixels[R.Left + 8, (R.Top + R.Bottom) div 2];
    R := G.ItemRect(0);
    Other := B.Canvas.Pixels[R.Left + 8, (R.Top + R.Bottom) div 2];
    CheckTrue(Px <> Other, 'gewaehltes Segment hebt sich ab');
    CheckTrue(PPGContrastRatio(Px, Other) > 1.5, 'deutlich');
  finally
    B.Free;
  end;
end;

procedure TChoiceGroupTests.ValidationErrorFrameIsDanger;
var
  G: TPPGRadioGroup;
  B: TBitmap;
  Found: Boolean;
  Y: Integer;
  Danger: TColor;
begin
  G := NewRadio(['A', 'B']);
  G.Caption := '';
  G.ValidationState := pvsError;
  Danger := G.Tokens.Danger;
  B := RenderToBitmap(G);
  try
    Found := False;
    for Y := 0 to G.Height - 1 do
      if PPGContrastRatio(B.Canvas.Pixels[1, Y], Danger) < 1.3 then
        Found := True;
    CheckTrue(Found, 'linke Rahmenkante in Fehlerfarbe');
  finally
    B.Free;
  end;
end;

procedure TChoiceGroupTests.RightToLeftMirrorsColumns;
var
  G: TPPGRadioGroup;
begin
  G := NewRadio(['A', 'B', 'C', 'D']);
  G.Columns := 2;
  G.BiDiMode := bdRightToLeft;
  CheckTrue(G.ItemRect(0).Left > G.ItemRect(2).Left, 'erste Spalte rechts');
end;

{ TTileViewTests }

procedure TTileViewTests.SetUp;
begin
  inherited SetUp;
  FChanges := 0;
  FClicks := 0;
  FLastClick := -1;
end;

procedure TTileViewTests.ViewChange(Sender: TObject);
begin
  Inc(FChanges);
end;

procedure TTileViewTests.ViewItemClick(Sender: TObject; Index: Integer);
begin
  Inc(FClicks);
  FLastClick := Index;
end;

procedure TTileViewTests.GetVirtual(Sender: TObject; Index: Integer; var Data: TPPGItemData);
begin
  Data.Text := 'Datei ' + IntToStr(Index);
  Data.Detail := IntToStr(Index * 3) + ' KB';
end;

procedure TTileViewTests.GetIcon(Sender: TObject; Index: Integer; var CodePoint: Word);
begin
  CodePoint := $E8A5;
end;

function TTileViewTests.NewView(Count: Integer; Groups: Boolean): TPPGTileView;
var
  I: Integer;
  It: TPPGItem;
begin
  Result := TPPGTileView.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 600, 400);
  Result.ScrollBarMode := sbmNever;
  for I := 0 to Count - 1 do
  begin
    It := Result.Items.Add('Eintrag ' + IntToStr(I));
    It.Detail := 'Detail ' + IntToStr(I);
    if Groups then
      if I mod 2 = 0 then
        It.Group := 'Gerade'
      else
        It.Group := 'Ungerade';
  end;
  Result.OnChange := ViewChange;
  Result.OnItemClick := ViewItemClick;
  Result.OnGetItemIcon := GetIcon;
end;

procedure TTileViewTests.ClickAt(V: TPPGTileView; X, Y: Integer; Keys: Integer);
begin
  V.Perform(WM_MOUSEMOVE, Keys, MakeLParam(X, Y));
  V.Perform(WM_LBUTTONDOWN, MK_LBUTTON or Keys, MakeLParam(X, Y));
  V.Perform(WM_LBUTTONUP, Keys, MakeLParam(X, Y));
end;

procedure TTileViewTests.ClickItem(V: TPPGTileView; Index: Integer; Keys: Integer);
var
  R: TRect;
begin
  R := V.ItemRect(Index);
  ClickAt(V, (R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2, Keys);
end;

procedure TTileViewTests.GridLayoutFillsRows;
var
  V: TPPGTileView;
begin
  V := NewView(5);
  V.TileStyle := tsTiles;
  // 600 px: zwei Kacheln (280 + Abstand) je Zeile, die die Breite fuellen
  CheckEquals(V.ItemRect(0).Top, V.ItemRect(1).Top, 'Nachbar rechts');
  CheckTrue(V.ItemRect(1).Left > V.ItemRect(0).Right);
  CheckTrue(V.ItemRect(2).Top > V.ItemRect(0).Bottom, 'dritte Kachel in der naechsten Zeile');
  CheckEquals(V.ItemRect(0).Left, V.ItemRect(2).Left);
  CheckTrue(V.ItemRect(1).Right > 560, 'Kacheln fuellen die Breite');
  CheckEquals(3, V.ItemAt((V.ItemRect(3).Left + V.ItemRect(3).Right) div 2, V.ItemRect(3).Top + 4));
  CheckEquals(-1, V.ItemAt(V.ItemRect(4).Right + 20, V.ItemRect(4).Top + 4), 'Luecke rechts');
  V.BiDiMode := bdRightToLeft;
  CheckTrue(V.ItemRect(0).Left > V.ItemRect(1).Left, 'RTL: erste Kachel rechts');
end;

procedure TTileViewTests.StylesChangeTileSize;
var
  V: TPPGTileView;
  H: array[TPPGTileStyle] of Integer;
  S: TPPGTileStyle;
begin
  V := NewView(3);
  for S := Low(TPPGTileStyle) to High(TPPGTileStyle) do
  begin
    V.TileStyle := S;
    H[S] := V.ItemRect(0).Bottom - V.ItemRect(0).Top;
  end;
  CheckTrue(H[tsCards] > H[tsIcons], 'Karten hoeher als Symbole');
  CheckTrue(H[tsIcons] > H[tsTiles], 'Symbole hoeher als Kacheln');
  V.TileStyle := tsIcons;
  CheckTrue(V.ItemRect(4 - 2).Top = V.ItemRect(0).Top, 'Symbole: mehrere je Zeile');
  V.Zoom := 200;
  CheckEquals(H[tsIcons] * 2, V.ItemRect(0).Bottom - V.ItemRect(0).Top, 1, 'Zoom 200 %');
  try
    V.Zoom := 300;
    Fail('Zoom ausserhalb muss werfen');
  except
    on EPPGError do
  end;
  CheckEquals(200, V.Zoom, 'unveraendert');
end;

procedure TTileViewTests.FilterHidesAndCountsMatches;
var
  V: TPPGTileView;
  B: TBitmap;
begin
  V := NewView(12);
  V.FilterText := 'eintrag 1';
  CheckEquals(3, V.VisibleCount, 'Eintrag 1, 10, 11');
  CheckTrue(IsRectEmpty(V.ItemRect(2)), 'ausgefiltert');
  CheckFalse(IsRectEmpty(V.ItemRect(10)));
  V.FilterText := 'detail 7';
  CheckEquals(1, V.VisibleCount, 'auch im Detail gesucht');
  B := RenderToBitmap(V);
  B.Free;
  // Auswahl haengt am Eintrag, nicht an der Position (Regression)
  V.FilterText := 'eintrag 1';
  V.ItemIndex := 11;
  V.FilterText := 'eintrag 11';
  CheckTrue(V.Selected[11], 'Auswahl bleibt am Eintrag');
  CheckEquals(11, V.ItemIndex);
  V.FilterText := 'detail 7';
  CheckEquals(0, V.SelCount, 'ausgefiltert: nicht mehr gewaehlt');
  V.FilterText := 'gibt es nicht';
  CheckEquals(0, V.VisibleCount);
  B := RenderToBitmap(V);
  B.Free;
  V.FilterText := '';
  CheckEquals(12, V.VisibleCount);
  CheckEquals(0, FChanges, 'Filter im Code ohne OnChange');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TTileViewTests.GroupsCollapse;
var
  V: TPPGTileView;
begin
  V := NewView(6, True);
  CheckTrue(V.ItemRect(1).Top > V.ItemRect(4).Top, 'gruppiert: erst alle geraden');
  V.GroupCollapsed['Gerade'] := True;
  CheckEquals(3, V.VisibleCount);
  CheckTrue(IsRectEmpty(V.ItemRect(0)));
  CheckTrue(V.GroupCollapsed['gerade'], 'ohne Gross/klein');
  V.GroupCollapsed['Gerade'] := False;
  CheckEquals(6, V.VisibleCount);
  V.GroupView := False;
  CheckTrue(V.ItemRect(1).Top < V.ItemRect(4).Top, 'ohne Gruppen in Reihenfolge');
end;

procedure TTileViewTests.VirtualHundredThousand;
var
  V: TPPGTileView;
  T0: Cardinal;
  B: TBitmap;
begin
  V := NewView(0);
  V.OnGetItem := GetVirtual;
  V.OwnerData := True;
  T0 := GetTickCount;
  V.ItemCount := 100000;
  CheckEquals(100000, V.VisibleCount);
  CheckTrue(GetTickCount - T0 < 3000, 'Layout von 100 000 Eintraegen');
  V.ScrollTo(0, MaxInt);
  T0 := GetTickCount;
  B := RenderToBitmap(V);
  B.Free;
  CheckTrue(GetTickCount - T0 < 500, 'Zeichnen nur des sichtbaren Teils');
  V.ItemIndex := 99999;
  CheckEquals(99999, V.ItemIndex);
  V.FilterText := 'Datei 9999';
  CheckEquals(11, V.VisibleCount, '9999 und 99990..99999');
  V.ItemCount := 10;
  CheckEquals(0, V.VisibleCount, 'Filter trifft keinen der 10');
end;

procedure TTileViewTests.CodeSelectsWithoutEvents;
var
  V: TPPGTileView;
begin
  V := NewView(5);
  V.ItemIndex := 3;
  CheckEquals(3, V.ItemIndex);
  CheckTrue(V.Selected[3]);
  CheckEquals(1, V.SelCount);
  V.Selected[1] := True;
  CheckFalse(V.Selected[3], 'ohne MultiSelect nur einer');
  CheckEquals(0, FChanges);
  try
    V.ItemIndex := 9;
    Fail('ItemIndex ausserhalb muss werfen');
  except
    on EPPGError do
  end;
  V.ItemIndex := -1;
  CheckEquals(0, V.SelCount);
end;

procedure TTileViewTests.ClickSelectsAndFiresEvents;
var
  V: TPPGTileView;
begin
  V := NewView(5);
  ClickItem(V, 2);
  CheckEquals(2, V.ItemIndex);
  CheckEquals(1, FChanges);
  CheckEquals(2, FLastClick);
  ClickAt(V, V.ItemRect(4).Right + 30, V.ItemRect(4).Top + 5);
  CheckEquals(-1, V.ItemIndex, 'Klick ins Leere hebt die Auswahl auf');
end;

procedure TTileViewTests.MultiSelectCtrlShiftAndSelectAll;
var
  V: TPPGTileView;
begin
  V := NewView(6);
  V.MultiSelect := True;
  ClickItem(V, 1);
  ClickItem(V, 4, MK_CONTROL);
  CheckEquals(2, V.SelCount, 'Strg fuegt hinzu');
  ClickItem(V, 1);
  ClickItem(V, 3, MK_SHIFT);
  CheckTrue(V.Selected[1] and V.Selected[2] and V.Selected[3] and not V.Selected[4], 'Umschalt: Bereich');
  V.Perform(WM_KEYDOWN, Ord('A'), 0);
  CheckEquals(3, V.SelCount, 'A ohne Strg waehlt nicht alles');
  V.SelectAll;
  CheckEquals(6, V.SelCount);
end;

procedure TTileViewTests.KeyboardMovesInTwoDimensions;
var
  V: TPPGTileView;
begin
  V := NewView(7);
  V.ItemIndex := 0;
  V.Perform(WM_KEYDOWN, VK_RIGHT, 0);
  CheckEquals(1, V.ItemIndex, 'rechts');
  V.Perform(WM_KEYDOWN, VK_DOWN, 0);
  CheckEquals(3, V.ItemIndex, 'runter: gleiche Spalte');
  V.Perform(WM_KEYDOWN, VK_UP, 0);
  CheckEquals(1, V.ItemIndex);
  V.Perform(WM_KEYDOWN, VK_END, 0);
  CheckEquals(6, V.ItemIndex);
  V.Perform(WM_KEYDOWN, VK_DOWN, 0);
  CheckEquals(6, V.ItemIndex, 'am Ende bleibt es stehen');
  V.Perform(WM_KEYDOWN, VK_HOME, 0);
  CheckEquals(0, V.ItemIndex);
  CheckTrue(FChanges >= 5, 'Anwender-Aktion meldet OnChange');
end;

procedure TTileViewTests.RubberBandSelects;
var
  V: TPPGTileView;
  P0, P1: TPoint;
begin
  V := NewView(3);
  V.MultiSelect := True;
  // Leere Flaeche rechts neben der dritten Kachel bis zur ersten ziehen
  P0 := Point(V.ItemRect(1).Left + 20, V.ItemRect(2).Top + 10);
  P1 := Point(V.ItemRect(0).Left + 10, V.ItemRect(0).Top + 10);
  CheckEquals(-1, V.ItemAt(P0.X, P0.Y), 'Start im Leeren');
  V.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(P0.X, P0.Y));
  V.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(P1.X, P1.Y));
  V.Perform(WM_LBUTTONUP, 0, MakeLParam(P1.X, P1.Y));
  CheckEquals(3, V.SelCount, 'alle drei im Rahmen');
end;

procedure TTileViewTests.CtrlWheelZooms;
var
  V: TPPGTileView;
begin
  V := NewView(3);
  V.Perform(WM_MOUSEWHEEL, MakeWParam(MK_CONTROL, 120), MakeLParam(10, 10));
  CheckEquals(110, V.Zoom);
  V.Perform(WM_MOUSEWHEEL, MakeWParam(MK_CONTROL, Word(-120)), MakeLParam(10, 10));
  CheckEquals(100, V.Zoom);
end;

procedure TTileViewTests.CheckboxClickToggles;
var
  V: TPPGTileView;
  R: TRect;
begin
  V := NewView(3);
  V.Checkboxes := True;
  R := V.ItemRect(1);
  ClickAt(V, R.Left + 12, R.Top + 12);
  CheckTrue(V.Items[1].Checked = cbChecked, 'Klick aufs Kaestchen');
  CheckEquals(-1, V.ItemIndex, 'Kaestchen waehlt nicht');
  V.ItemIndex := 1;
  V.Perform(WM_KEYDOWN, VK_SPACE, 0);
  CheckTrue(V.Items[1].Checked = cbUnchecked, 'Leertaste');
end;

procedure TTileViewTests.RenameWithF2;
var
  V: TPPGTileView;
  E: TWinControl;
  I: Integer;
begin
  V := NewView(3);
  FForm.Show;
  V.SetFocus;
  V.ItemIndex := 1;
  V.Perform(WM_KEYDOWN, VK_F2, 0);
  E := nil;
  for I := 0 to V.ControlCount - 1 do
    if V.Controls[I] is TEdit then
      E := TEdit(V.Controls[I]);
  CheckNotNull(E, 'Editor sichtbar');
  CheckEquals('Eintrag 1', TEdit(E).Text);
  TEdit(E).Text := 'Neu';
  E.Perform(WM_KEYDOWN, VK_RETURN, 0);
  CheckEquals('Neu', V.Items[1].Text);
  CheckFalse(E.Visible);
end;

procedure TTileViewTests.TypeAheadFindsItem;
var
  V: TPPGTileView;
begin
  V := NewView(0);
  V.Items.Add('Apfel');
  V.Items.Add('Birne');
  V.Items.Add('Banane');
  V.Perform(WM_CHAR, Ord('b'), 0);
  CheckEquals(1, V.ItemIndex);
  V.Perform(WM_CHAR, Ord('a'), 0);
  CheckEquals(2, V.ItemIndex, 'ba -> Banane');
end;

procedure TTileViewTests.ExportsAsTable;
var
  V: TPPGTileView;
  T: IPPGTableSource;
  H: string;
begin
  V := NewView(4, True);
  V.Items[0].Badge := 'Neu';
  V.FilterText := 'eintrag';
  CheckTrue(Supports(V, IPPGTableSource, T));
  CheckEquals(4, T.TableRowCount);
  CheckEquals(4, T.TableColCount);
  CheckEquals('Eintrag 0', T.TableCellText(0, 0), 'Ansichts-Reihenfolge');
  CheckEquals('Eintrag 2', T.TableCellText(0, 1), 'gruppiert: zweite gerade');
  CheckEquals('Neu', T.TableCellText(2, 0));
  CheckEquals('Gerade', T.TableCellText(3, 0));
  H := PPGExportHtmlText(T);
  CheckTrue(Pos('Eintrag 3', H) > 0);
end;

procedure TTileViewTests.AccessibleChildren;
var
  V: TPPGTileView;
  A: IPPGAccessibleChildren;
begin
  V := NewView(3);
  V.Items[2].Badge := '5';
  V.ItemIndex := 2;
  CheckTrue(Supports(V, IPPGAccessibleChildren, A));
  CheckEquals(3, A.AccChildCount);
  CheckEquals('Eintrag 2, Detail 2, 5', A.AccChildName(3));
  CheckEquals(ROLE_SYSTEM_LISTITEM, A.AccChildRole(1));
  CheckTrue(A.AccChildState(3) and STATE_SYSTEM_SELECTED <> 0);
  CheckEquals(3, A.AccSelectedChild);
  CheckEquals(2, A.AccChildAt(V.ItemRect(1).Left + 3, V.ItemRect(1).Top + 3));
end;

procedure TTileViewTests.PaintsAllStylesGdiPlusAndGdi;
var
  Filtered: TBitmap;
  V: TPPGTileView;
  S: TPPGTileStyle;
  Gdi: Boolean;
  B: TBitmap;
begin
  V := NewView(8, True);
  V.Items[1].Badge := '3';
  V.Items[2].Enabled := False;
  V.Checkboxes := True;
  V.MultiSelect := True;
  V.Selected[0] := True;
  V.Selected[3] := True;
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    try
      for S := Low(TPPGTileStyle) to High(TPPGTileStyle) do
      begin
        V.TileStyle := S;
        V.FilterText := '';
        PPGPaintCheck(Self, V, 'V');
        V.FilterText := 'trag 1';
        B := RenderToBitmap(V);
        PPGCheckPainted(Self, B, 'TileView Suche'); // Audit 11b
        // Sichtpruefung: je Ansicht mit Suchtreffern in die Galerie
        if not Gdi then
          SaveGalleryPng(B, 'TileView_' + IntToStr(Ord(S)) + '_Suche.png');
        B.Free;
      end;
      V.Enabled := False;
      PPGPaintCheck(Self, V, 'V');
      V.Enabled := True;
    finally
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
  // Audit 11b: Suchtreffer sichtbar (Filter aendert das Bild), Zustaende sichtbar
  FForm.Show;
  V.TileStyle := Low(TPPGTileStyle);
  V.FilterText := '';
  B := RenderToBitmap(V);
  try
    V.FilterText := 'trag 1';
    Filtered := RenderToBitmap(V);
    try
      PPGCheckDiffers(Self, B, Filtered, 'TileView Filter');
    finally
      Filtered.Free;
    end;
  finally
    B.Free;
  end;
  V.FilterText := '';
  PPGCheckStates(Self, V, 'TileView', True, True, True,
    Point((V.ItemRect(1).Left + V.ItemRect(1).Right) div 2, (V.ItemRect(1).Top + V.ItemRect(1).Bottom) div 2));
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TTileViewTests.StreamsItemsAndStyle;
var
  V, V2: TPPGTileView;
  M: TMemoryStream;
begin
  V := NewView(2);
  V.Items[1].Badge := 'B';
  V.Items[1].Group := 'G';
  V.TileStyle := tsCards;
  V.Zoom := 120;
  V.MultiSelect := True;
  V.EmptyText := 'leer';
  M := TMemoryStream.Create;
  try
    M.WriteComponent(V);
    M.Position := 0;
    V2 := TPPGTileView.Create(FForm);
    M.ReadComponent(V2);
    CheckEquals(2, V2.Items.Count);
    CheckEquals('B', V2.Items[1].Badge);
    CheckEquals('G', V2.Items[1].Group);
    CheckTrue(V2.TileStyle = tsCards);
    CheckEquals(120, V2.Zoom);
    CheckTrue(V2.MultiSelect);
    CheckEquals('leer', V2.EmptyText);
  finally
    M.Free;
  end;
end;

{ TDBNavigatorTests }

procedure TDBNavigatorTests.SetUp;
const
  Names: array[0..4] of string = ('Anna', 'Bernd', 'Carla', 'Bertram', 'Doris');
  States: array[0..4] of string = ('A', 'B', 'C', 'B', 'A');
var
  I: Integer;
begin
  inherited SetUp;
  FLog := '';
  FData := TClientDataSet.Create(FForm);
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Name', ftString, 20);
  FData.FieldDefs.Add('Status', ftString, 1);
  FData.CreateDataSet;
  for I := 0 to 4 do
    FData.AppendRecord([I + 1, Names[I], States[I]]);
  FData.First;
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
  FNav := TPPGDBNavigator.Create(FForm);
  FNav.Parent := FForm;
  FNav.SetBounds(0, 0, 700, 36);
  FNav.DataSource := FSource;
  FNav.ConfirmDelete := False;
  FNav.BeforeAction := NavBefore;
  FNav.OnClick := NavClick;
end;

procedure TDBNavigatorTests.NavBefore(Sender: TObject; Button: TNavigateBtn);
begin
  FLog := FLog + 'B' + IntToStr(Ord(Button));
end;

procedure TDBNavigatorTests.NavClick(Sender: TObject; Button: TNavigateBtn);
begin
  FLog := FLog + 'C' + IntToStr(Ord(Button));
end;

procedure TDBNavigatorTests.OwnFilter(DataSet: TDataSet; var Accept: Boolean);
begin
  Accept := DataSet.FieldByName('Status').AsString <> 'C';
end;

function TDBNavigatorTests.VisibleRecords: Integer;
begin
  Result := 0;
  FData.First;
  while not FData.Eof do
  begin
    Inc(Result);
    FData.Next;
  end;
  FData.First;
end;

procedure TDBNavigatorTests.ClickButton(Btn: TNavigateBtn);
var
  R: TRect;
  P: LPARAM;
begin
  R := FNav.ButtonRect(Btn);
  CheckFalse(IsRectEmpty(R), 'Knopf sichtbar');
  P := MakeLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
  FNav.Perform(WM_MOUSEMOVE, 0, P);
  FNav.Perform(WM_LBUTTONDOWN, MK_LBUTTON, P);
  FNav.Perform(WM_LBUTTONUP, 0, P);
end;

procedure TDBNavigatorTests.ButtonStatesFollowDataSet;
begin
  CheckFalse(FNav.ButtonEnabled(nbFirst), 'am Anfang: Erster aus');
  CheckFalse(FNav.ButtonEnabled(nbPrior));
  CheckTrue(FNav.ButtonEnabled(nbNext));
  CheckFalse(FNav.ButtonEnabled(nbPost), 'ohne Bearbeitung kein Speichern');
  FData.Last;
  CheckFalse(FNav.ButtonEnabled(nbNext), 'am Ende: Naechster aus');
  CheckTrue(FNav.ButtonEnabled(nbFirst));
  FData.Edit;
  CheckTrue(FNav.ButtonEnabled(nbPost));
  CheckTrue(FNav.ButtonEnabled(nbCancel));
  CheckFalse(FNav.ButtonEnabled(nbFirst), 'beim Bearbeiten keine Navigation');
  CheckFalse(FNav.ButtonEnabled(nbDelete));
  FData.Cancel;
  FNav.DataSource := nil;
  CheckFalse(FNav.ButtonEnabled(nbNext), 'ohne Datenmenge alles aus');
end;

procedure TDBNavigatorTests.CounterShowsPosition;
begin
  CheckEquals(Format(PPGStr(@SPPGNavCounter), [1, 5]), FNav.CounterText);
  FData.Next;
  CheckEquals(Format(PPGStr(@SPPGNavCounter), [2, 5]), FNav.CounterText);
  FData.Insert;
  CheckEquals(PPGStr(@SPPGNavNewRecord), FNav.CounterText);
  FData.Cancel;
  FData.EmptyDataSet;
  CheckEquals(PPGStr(@SPPGNavNoRecords), FNav.CounterText);
  CheckEquals(PPGStr(@SPPGNavNoRecords), TNavAccess(FNav).AccValue, 'auch fuer Screenreader');
end;

procedure TDBNavigatorTests.ClickRunsActionWithEvents;
begin
  ClickButton(nbNext);
  CheckEquals(2, FData.RecNo);
  CheckEquals('B' + IntToStr(Ord(nbNext)) + 'C' + IntToStr(Ord(nbNext)), FLog,
    'BeforeAction, dann OnClick');
  ClickButton(nbLast);
  CheckEquals(5, FData.RecNo);
  FLog := '';
  FNav.BtnClick(nbNext);
  CheckEquals('', FLog, 'gesperrter Knopf: keine Aktion, kein Ereignis');
  FNav.BtnClick(nbDelete);
  CheckEquals(4, FData.RecordCount, 'loeschen ohne Rueckfrage');
end;

procedure TDBNavigatorTests.SearchFindsAndWraps;
begin
  FNav.ShowSearch := True;
  FNav.SearchField := 'Name';
  CheckNotNull(FNav.SearchEdit);
  CheckTrue(FNav.FindText('ber', True));
  CheckEquals('Bernd', FData.FieldByName('Name').AsString);
  CheckTrue(FNav.FindText('ber', False), 'naechster Treffer');
  CheckEquals('Bertram', FData.FieldByName('Name').AsString);
  CheckTrue(FNav.FindText('ber', False), 'von vorn');
  CheckEquals('Bernd', FData.FieldByName('Name').AsString);
  CheckFalse(FNav.FindText('xyz', True));
  CheckEquals('Bernd', FData.FieldByName('Name').AsString, 'ohne Treffer bleibt der Satz');
  FNav.SearchField := '';
  CheckTrue(FNav.FindText('dor', True), 'alle Textfelder');
  CheckEquals(5, FData.RecNo);
end;

procedure TDBNavigatorTests.QuickFilterChainsAndRestores;
var
  Old, Mine: TFilterRecordEvent;
begin
  Mine := OwnFilter;
  FData.OnFilterRecord := OwnFilter;
  FData.Filtered := True;
  CheckEquals(4, VisibleRecords, 'eigener Filter: ohne C');
  FNav.ShowSearch := True;
  FNav.ShowFilter := True;
  FNav.SearchField := 'Name';
  FNav.SearchEdit.Text := 'b';
  FNav.SetQuickFilter(True);
  CheckTrue(FNav.QuickFilterActive);
  CheckEquals(2, VisibleRecords, 'Bernd, Bertram (eigener Filter laeuft mit)');
  FNav.SetQuickFilter(False);
  Old := FData.OnFilterRecord;
  CheckTrue(TMethod(Old).Code = TMethod(Mine).Code, 'Handler zurueck');
  CheckTrue(FData.Filtered, 'Filtered zurueck');
  CheckEquals(4, VisibleRecords);
end;

procedure TDBNavigatorTests.OverflowWhenNarrow;
begin
  CheckFalse(IsRectEmpty(FNav.ButtonRect(nbRefresh)), 'breit: alle Knoepfe');
  FNav.Width := 160;
  CheckFalse(IsRectEmpty(FNav.ButtonRect(nbFirst)));
  CheckTrue(IsRectEmpty(FNav.ButtonRect(nbRefresh)), 'schmal: hinten im Ueberlauf');
  FNav.VisibleButtons := [nbPrior, nbNext];
  FNav.Width := 400;
  CheckTrue(IsRectEmpty(FNav.ButtonRect(nbFirst)), 'ausgeblendet');
  CheckFalse(IsRectEmpty(FNav.ButtonRect(nbNext)));
end;

procedure TDBNavigatorTests.KeyboardShortcuts;
begin
  FNav.Perform(WM_KEYDOWN, VK_NEXT, 0);
  CheckEquals(2, FData.RecNo, 'Bild ab = naechster Satz');
  FNav.Perform(WM_KEYDOWN, VK_INSERT, 0);
  CheckTrue(FData.State = dsInsert, 'Einfg');
  FNav.Perform(WM_KEYDOWN, VK_ESCAPE, 0);
  CheckTrue(FData.State = dsBrowse, 'Esc bricht ab');
  FNav.Perform(WM_KEYDOWN, VK_F2, 0);
  CheckTrue(FData.State = dsEdit, 'F2 bearbeitet');
  FData.Cancel;
end;

procedure TDBNavigatorTests.AccessibleButtons;
var
  A: IPPGAccessibleChildren;
begin
  CheckTrue(Supports(FNav, IPPGAccessibleChildren, A));
  CheckEquals(10, A.AccChildCount, 'Standard-Knoepfe');
  CheckEquals(PPGStr(@SPPGNavFirst), A.AccChildName(1));
  CheckEquals(STATE_SYSTEM_UNAVAILABLE, A.AccChildState(1), 'Erster am Anfang gesperrt');
  CheckEquals(ROLE_SYSTEM_PUSHBUTTON, A.AccChildRole(3));
  FNav.Hints.Text := 'Zum Anfang';
  CheckEquals('Zum Anfang', A.AccChildName(1), 'eigene Hints wie TDBNavigator');
end;

procedure TDBNavigatorTests.StreamsLikeTDBNavigator;
var
  M: TMemoryStream;
  N2: TPPGDBNavigator;
begin
  FNav.VisibleButtons := [nbFirst, nbLast];
  FNav.ShowSearch := True;
  FNav.ShowFilter := True;
  FNav.ShowCounter := False;
  FNav.SearchField := 'Name';
  FNav.Flat := True;
  M := TMemoryStream.Create;
  try
    M.WriteComponent(FNav);
    M.Position := 0;
    N2 := TPPGDBNavigator.Create(FForm);
    M.ReadComponent(N2);
    CheckTrue(N2.VisibleButtons = [nbFirst, nbLast]);
    CheckTrue(N2.ShowSearch and N2.ShowFilter and not N2.ShowCounter and N2.Flat);
    CheckFalse(N2.ConfirmDelete);
    CheckEquals('Name', N2.SearchField);
  finally
    M.Free;
  end;
end;

procedure TDBNavigatorTests.PaintsWithoutErrors;
var
  Edit: TBitmap;
  B: TBitmap;
  Gdi: Boolean;
begin
  FNav.ShowSearch := True;
  FNav.ShowFilter := True;
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    try
      PPGPaintCheck(Self, FNav, 'FNav');
      FData.Edit;
      PPGPaintCheck(Self, FNav, 'FNav');
      FData.Cancel;
      FNav.Enabled := False;
      PPGPaintCheck(Self, FNav, 'FNav');
      FNav.Enabled := True;
    finally
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
  // Audit 11b: Bearbeiten-Zustand und Deaktiviert sichtbar (GDI+ und GDI)
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    try
      B := RenderToBitmap(FNav);
      try
        PPGCheckPainted(Self, B, 'Navigator');
        FData.Edit;
        Edit := RenderToBitmap(FNav);
        try
          PPGCheckDiffers(Self, B, Edit, 'Navigator im Bearbeiten (Speichern/Abbrechen aktiv)');
        finally
          Edit.Free;
          FData.Cancel;
        end;
        FNav.Enabled := False;
        Edit := RenderToBitmap(FNav);
        try
          PPGCheckDiffers(Self, B, Edit, 'Navigator deaktiviert');
        finally
          Edit.Free;
          FNav.Enabled := True;
        end;
      finally
        B.Free;
      end;
    finally
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TDBNavigatorTests.RadioGroupReadsAndWritesField;
var
  G: TPPGDBRadioGroup;
  R: TRect;
  P: LPARAM;
begin
  G := TPPGDBRadioGroup.Create(FForm);
  G.Parent := FForm;
  G.SetBounds(0, 50, 300, 120);
  G.Items.CommaText := 'Aktiv,Beendet,Club';
  G.Values.CommaText := 'A,B,C';
  G.DataSource := FSource;
  G.DataField := 'Status';
  CheckEquals(0, G.ItemIndex, 'Anna: A');
  FData.Next;
  CheckEquals(1, G.ItemIndex, 'Bernd: B');
  // Anwender waehlt "Club": Satz geht in Bearbeitung, Wert landet im Feld
  R := G.ItemRect(2);
  P := MakeLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
  G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, P);
  G.Perform(WM_LBUTTONUP, 0, P);
  CheckTrue(FData.State = dsEdit);
  FData.Post;
  CheckEquals('C', FData.FieldByName('Status').AsString);
  G.ReadOnly := True;
  G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(5, 5));
  R := G.ItemRect(0);
  P := MakeLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
  G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, P);
  G.Perform(WM_LBUTTONUP, 0, P);
  CheckEquals(2, G.ItemIndex, 'ReadOnly: keine Aenderung');
  CheckTrue(FData.State = dsBrowse);
  FData.Edit;
  FData.FieldByName('Status').Clear;
  CheckEquals(-1, G.ItemIndex, 'Null: nichts gewaehlt');
  FData.Cancel;
end;

{ TPanelScrollTests }

function TPanelScrollTests.NewPanel(AutoScroll: Boolean): TPPGPanel;
begin
  Result := TPPGPanel.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 220, 160);
  Result.Caption := '';
  Result.Animation.Enabled := False;
  Result.AutoScroll := AutoScroll;
  Result.VertScrollBar.Smooth := False;
  Result.HorzScrollBar.Smooth := False;
end;

function TPanelScrollTests.AddChild(P: TWinControl; X, Y: Integer): TPPGEdit;
begin
  Result := TPPGEdit.Create(FForm);
  Result.Parent := P;
  Result.SetBounds(X, Y, 120, 28);
end;

procedure TPanelScrollTests.NoScrollingByDefault;
var
  P: TPPGPanel;
  E: TPPGEdit;
begin
  P := NewPanel(False);
  E := AddChild(P, 10, 400);
  CheckFalse(P.VertScrollBar.IsScrollBarVisible, 'ohne AutoScroll keine Leiste');
  CheckEquals(0, P.ContentSize.cy);
  P.ScrollTo(0, 100);
  CheckEquals(400, E.Top, 'nichts verschoben');
end;

procedure TPanelScrollTests.AutoScrollShowsBarForChildBelow;
var
  P: TPPGPanel;
begin
  P := NewPanel(True);
  AddChild(P, 10, 400);
  CheckTrue(P.VertScrollBar.IsScrollBarVisible, 'Kind unterhalb: senkrechte Leiste');
  CheckFalse(P.HorzScrollBar.IsScrollBarVisible, 'passt in die Breite');
  CheckTrue(P.ContentSize.cy >= 420, 'Inhalt bis zur Unterkante des Kinds (abzueglich Rand)');
end;

procedure TPanelScrollTests.ScrollToMovesChildrenAndClamps;
var
  P: TPPGPanel;
  E: TPPGEdit;
  Top0: Integer;
begin
  P := NewPanel(True);
  E := AddChild(P, 10, 400);
  Top0 := E.Top;
  P.ScrollTo(0, 100);
  CheckEquals(100, P.ScrollPos.Y);
  CheckEquals(Top0 - 100, E.Top, 'Kind wandert mit');
  P.ScrollTo(0, 100000);
  CheckTrue(P.ScrollPos.Y < 1000, 'begrenzt');
  CheckTrue(E.Top + E.Height <= P.ClientHeight, 'am Ende ist das Kind sichtbar');
  P.VertScrollBar.Position := 0;
  CheckEquals(Top0, E.Top, 'Position wie TControlScrollBar');
end;

procedure TPanelScrollTests.ScrollInViewAndFocus;
var
  P: TPPGPanel;
  E1, E2: TPPGEdit;
begin
  P := NewPanel(True);
  E1 := AddChild(P, 10, 10);
  E2 := AddChild(P, 10, 500);
  P.ScrollInView(E2);
  CheckTrue((E2.Top >= 0) and (E2.Top + E2.Height <= P.ClientHeight), 'ScrollInView');
  P.ScrollTo(0, 0);
  FForm.Show;
  E1.SetFocus;
  E2.SetFocus;
  CheckTrue((E2.Top >= 0) and (E2.Top + E2.Height <= P.ClientHeight), 'Fokus holt das ganze Feld ins Bild (nicht nur das innere Edit)');
end;

procedure TPanelScrollTests.WheelScrolls;
var
  P: TPPGPanel;
begin
  P := NewPanel(True);
  AddChild(P, 10, 600);
  P.Perform(WM_MOUSEWHEEL, MakeWParam(0, Word(-120)), MakeLParam(5, 5));
  CheckTrue(P.ScrollPos.Y > 0, 'Rad nach unten');
  P.Perform(WM_MOUSEWHEEL, MakeWParam(0, 120), MakeLParam(5, 5));
  CheckEquals(0, P.ScrollPos.Y);
end;

procedure TPanelScrollTests.FixedRangeWithoutAutoScroll;
var
  P: TPPGPanel;
begin
  P := NewPanel(False);
  P.VertScrollBar.Range := 1000;
  CheckTrue(P.VertScrollBar.IsScrollBarVisible, 'feste Range wie die VCL');
  P.ScrollTo(0, 300);
  CheckEquals(300, P.ScrollPos.Y);
  P.VertScrollBar.Visible := False;
  CheckFalse(P.VertScrollBar.IsScrollBarVisible);
end;

procedure TPanelScrollTests.AlignedChildScrollsAlong;
var
  P: TPPGPanel;
  Head: TPPGPanel;
  E: TPPGEdit;
  Top0: Integer;
begin
  P := NewPanel(True);
  Head := TPPGPanel.Create(FForm);
  Head.Parent := P;
  Head.Align := alTop;
  Head.Height := 40;
  E := AddChild(P, 10, 500);
  // Ausgerichtete Kinder ordnet die VCL erst mit Fensterhandle an
  FForm.Show;
  P.ScrollTo(0, 0); // Show fokussiert das Edit unten und scrollt dorthin
  Top0 := Head.Top;
  P.ScrollTo(0, 80);
  CheckEquals(Top0 - 80, Head.Top, 'ausgerichtetes Kind scrollt mit (wie TScrollBox)');
  CheckTrue(E.Top < 500);
end;

procedure TPanelScrollTests.DragThumbScrolls;
var
  P: TPPGPanel;
  R: TRect;
begin
  P := NewPanel(True);
  AddChild(P, 10, 900);
  R := TPanelAccess(P).BarThumb(True);
  CheckFalse(IsRectEmpty(R), 'Daumen');
  P.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam((R.Left + R.Right) div 2, R.Top + 2));
  P.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam((R.Left + R.Right) div 2, R.Top + 60));
  P.Perform(WM_LBUTTONUP, 0, MakeLParam((R.Left + R.Right) div 2, R.Top + 60));
  CheckTrue(P.ScrollPos.Y > 0, 'Ziehen scrollt');
end;

procedure TPanelScrollTests.ScrollBoxLoadsTScrollBoxDfm;
const
  Dfm =
    'object Box: TPPGScrollBox'#13#10 +
    '  Left = 0'#13#10 +
    '  Top = 0'#13#10 +
    '  Width = 200'#13#10 +
    '  Height = 120'#13#10 +
    '  BorderStyle = bsNone'#13#10 +
    '  HorzScrollBar.Visible = False'#13#10 +
    '  VertScrollBar.Increment = 20'#13#10 +
    '  VertScrollBar.Tracking = True'#13#10 +
    '  TabOrder = 0'#13#10 +
    'end';
var
  Src: TStringStream;
  Bin: TMemoryStream;
  B: TPPGScrollBox;
  Bmp: TBitmap;
begin
  Src := TStringStream.Create(Dfm);
  Bin := TMemoryStream.Create;
  try
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    B := TPPGScrollBox.Create(FForm);
    Bin.ReadComponent(B);
    B.Parent := FForm;
    CheckTrue(B.AutoScroll, 'Vorgabe wie TScrollBox');
    CheckTrue(B.BorderStyle = bsNone);
    CheckFalse(B.HorzScrollBar.Visible);
    CheckEquals(20, B.VertScrollBar.Increment);
    CheckTrue(B.VertScrollBar.Tracking);
    AddChild(B, 0, 300);
    CheckTrue(B.VertScrollBar.IsScrollBarVisible);
    Bmp := RenderToBitmap(B);
    Bmp.Free;
  finally
    Bin.Free;
    Src.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPanelScrollTests.InvalidValuesRaise;
var
  P: TPPGPanel;
begin
  P := NewPanel(True);
  try
    P.VertScrollBar.Increment := 0;
    Fail('Increment 0 muss werfen');
  except
    on EPPGError do
  end;
  CheckEquals(8, P.VertScrollBar.Increment, 'unveraendert');
  try
    P.VertScrollBar.Range := -1;
    Fail('Range negativ muss werfen');
  except
    on EPPGError do
  end;
end;

procedure TPanelScrollTests.PaintsWithBars;
var
  P: TPPGPanel;
  B: TBitmap;
  Gdi: Boolean;
begin
  P := NewPanel(True);
  AddChild(P, 400, 400);
  CheckTrue(P.HorzScrollBar.IsScrollBarVisible and P.VertScrollBar.IsScrollBarVisible);
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    try
      B := RenderToBitmap(P);
      B.Free;
      P.BiDiMode := bdRightToLeft;
      B := RenderToBitmap(P);
      B.Free;
      P.BiDiMode := bdLeftToRight;
    finally
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterTest('Phase18', TChoiceGroupTests.Suite);
  RegisterTest('Phase18', TTileViewTests.Suite);
  RegisterTest('Phase18', TDBNavigatorTests.Suite);
  RegisterTest('Phase18', TPanelScrollTests.Suite);

end.
