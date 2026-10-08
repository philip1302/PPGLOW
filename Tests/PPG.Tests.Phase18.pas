unit PPG.Tests.Phase18;

{ Tests fuer Phase 18: Controls mit Mehrwert.
  18a: TPPGRadioGroup/TPPGCheckGroup (ChoiceStyle, ItemsEx, Columns = 0,
  ValidationState, Tastatur, Maus, Barrierefreiheit, DFM wie TRadioGroup). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Graphics, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  PPG.Types, PPG.Controls.Field, PPG.RadioGroup, PPG.Tests.Controls;

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

implementation

uses
  Winapi.oleacc, PPG.Exceptions, PPG.Accessibility, PPG.Render.Registry, PPG.Tokens;

type
  TGroupAccess = class(TPPGCustomChoiceGroup);

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
        B := RenderToBitmap(G);
        B.Free;
        B := RenderToBitmap(C);
        B.Free;
        G.Enabled := False;
        B := RenderToBitmap(G);
        B.Free;
      end;
    finally
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  end;
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

initialization
  RegisterTest('Phase18', TChoiceGroupTests.Suite);

end.
