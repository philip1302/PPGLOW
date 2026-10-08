unit PPG.Tests.Phase13d;

{ Tests fuer Phase 13d: Zellarten (IPPGCellKind), bedingte Formate und
  verbundene Zellen. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids, Vcl.ImgList,
  PPG.Types, PPG.Tokens, PPG.UIA, PPG.UIA.Intf, PPG.Render.Intf, PPG.Grid,
  PPG.Grid.Columns, PPG.Grid.CellKinds, PPG.Grid.Styles, PPG.Tests.Controls;

type
  TGridCellTests = class(TControlTestCase)
  private
    FLinks: TStringList;
    FButtons: Integer;
    FStyleCalls: Integer;
    FOldFS: TFormatSettings;
    procedure LinkClick(Sender: TObject; ACol, ARow: Integer; const Link: string);
    procedure ButtonClick(Sender: TObject; ACol, ARow: Integer);
    procedure GetStyle(Sender: TObject; ACol, ARow: Integer; var Style: TPPGGridCellStyle);
    function NewGrid: TPPGGrid;
    /// 1 feste Spalte + 4 Spalten, 6 Zeilen; Spalte 2 = Zahlen 10..50.
    function SampleGrid: TPPGGrid;
    procedure Click(G: TPPGGrid; const P: TPoint);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure RegistryAndKindOf;
    procedure CustomKindIsUsed;
    procedure CheckKindClickAndSpace;
    procedure RatingClickKeyAndAcc;
    procedure ProgressAcc;
    procedure ColumnRangeStaysOrdered;
    procedure LinkKind;
    procedure ButtonKind;
    procedure MarkupKindLink;
    procedure ColorParsing;
    procedure KindsPaint;
    procedure RangeEqualContains;
    procedure TopBottomFollowFilter;
    procedure TopWithThousandSeparators;
    procedure ScaleBarIcons;
    procedure CellStyleEventAndBold;
    procedure StylesPaintFill;
    procedure MergeValidation;
    procedure MergeFocusAndKeys;
    procedure MergePaintNoInnerLine;
    procedure MergesRestWhenSorted;
    procedure MergeEditorCoversArea;
    procedure DfmKeepsKindsAndFormats;
  end;

implementation

uses
  PPG.Grid.Paint, PPG.Lang, PPG.Consts, PPG.Appearance;

type
  TGridAccess = class(TPPGGrid);

  TCountingKind = class(TPPGCellKindBase)
  public
    Paints: Integer;
    procedure PaintCell(const Ctx: TPPGCellKindContext; const R: TRect; const Text: string); override;
    function CellAccText(const Ctx: TPPGCellKindContext; const Text: string): string; override;
  end;

procedure TCountingKind.PaintCell(const Ctx: TPPGCellKindContext; const R: TRect;
  const Text: string);
begin
  Inc(Paints);
end;

function TCountingKind.CellAccText(const Ctx: TPPGCellKindContext; const Text: string): string;
begin
  Result := 'eigen:' + Text;
end;

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := MakeLParam(Word(SmallInt(X)), Word(SmallInt(Y)));
end;

function CenterOf(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

{ TGridCellTests }

procedure TGridCellTests.SetUp;
begin
  inherited SetUp;
  FButtons := 0;
  FStyleCalls := 0;
  FLinks := TStringList.Create;
  FOldFS := FormatSettings;
  FormatSettings := TFormatSettings.Create('de-DE');
end;

procedure TGridCellTests.TearDown;
begin
  FreeAndNil(FLinks);
  FormatSettings := FOldFS;
  inherited TearDown;
end;

procedure TGridCellTests.LinkClick(Sender: TObject; ACol, ARow: Integer; const Link: string);
begin
  FLinks.Add(Format('%d,%d:%s', [ACol, ARow, Link]));
end;

procedure TGridCellTests.ButtonClick(Sender: TObject; ACol, ARow: Integer);
begin
  Inc(FButtons);
end;

procedure TGridCellTests.GetStyle(Sender: TObject; ACol, ARow: Integer;
  var Style: TPPGGridCellStyle);
begin
  Inc(FStyleCalls);
  if (ACol = 3) and (ARow = 1) then
  begin
    Style.TextColor := clRed;
    Style.Bold := True;
  end;
end;

function TGridCellTests.NewGrid: TPPGGrid;
begin
  Result := TPPGGrid.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 480, 260);
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.HandleNeeded;
end;

function TGridCellTests.SampleGrid: TPPGGrid;
var
  C, R: Integer;
begin
  Result := NewGrid;
  for C := 0 to 4 do
    Result.Columns.Add.Width := 80;
  Result.FixedCols := 1;
  Result.RowCount := 6;
  for R := 1 to 5 do
  begin
    Result.Cells[0, R] := IntToStr(R);
    Result.Cells[1, R] := 'Text ' + IntToStr(R);
    Result.Cells[2, R] := IntToStr(R * 10);
    Result.Cells[3, R] := 'Wert' + IntToStr(R);
  end;
  Result.OnLinkClick := LinkClick;
  Result.OnCellButtonClick := ButtonClick;
end;

procedure TGridCellTests.Click(G: TPPGGrid; const P: TPoint);
begin
  G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
  G.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y));
end;

procedure TGridCellTests.RegistryAndKindOf;
var
  G: TPPGGrid;
  K: TPPGGridCellKind;
begin
  CheckNull(PPGCellKind(ckText), 'Text braucht keine Zellart');
  for K := ckCheck to ckMarkup do
    CheckNotNull(PPGCellKind(K), 'Zellart registriert');
  CheckNull(PPGCellKind(ckCustom, 'gibtsnicht'));
  G := SampleGrid;
  CheckNull(TGridAccess(G).KindOf(1));
  G.Columns[1].CellKind := ckProgress;
  CheckTrue(TGridAccess(G).KindOf(1) = PPGCellKind(ckProgress));
  G.Columns[2].EditorKind := gekCheck;
  CheckTrue(TGridAccess(G).KindOf(2) = PPGCellKind(ckCheck), 'gekCheck = Kaestchen');
  G.Columns[3].CellKind := ckButton;
  CheckTrue(TGridAccess(G).CellEditorKind(3, 1) = gekNone, 'Button ohne Texteingabe');
end;

procedure TGridCellTests.CustomKindIsUsed;
var
  G: TPPGGrid;
  CK: TCountingKind;
  Ref: IPPGCellKind;
  Bmp: TBitmap;
begin
  CK := TCountingKind.Create;
  Ref := CK;
  PPGRegisterCellKindName('Zaehler', Ref);
  try
    G := SampleGrid;
    G.Columns[1].CellKind := ckCustom;
    G.Columns[1].CellKindName := 'zaehler'; // Gross/klein egal
    Bmp := RenderToBitmap(G);
    Bmp.Free;
    CheckTrue((CK.Paints >= 5) and (CK.Paints mod 5 = 0), 'je Datenzeile');
    CheckEquals('eigen:Text 1', TGridAccess(G).UiaValue(PPGUiaId(PPGUiaKindGridCell, 1, 1)));
  finally
    PPGRegisterCellKindName('Zaehler', nil);
  end;
  CheckNull(PPGCellKind(ckCustom, 'Zaehler'), 'abgemeldet');
end;

procedure TGridCellTests.CheckKindClickAndSpace;
var
  G: TPPGGrid;
  K: Word;
begin
  FForm.Show;
  try
    G := SampleGrid;
    G.Columns[4].CellKind := ckCheck;
    G.Cells[4, 1] := '0';
    Click(G, CenterOf(G.CellRect(4, 1)));
    CheckEquals('0', G.Cells[4, 1], 'ohne goEditing keine Aenderung');
    G.Options := G.Options + [goEditing];
    Click(G, CenterOf(G.CellRect(4, 1)));
    CheckEquals('1', G.Cells[4, 1], 'Klick auf das Kaestchen');
    Click(G, Point(G.CellRect(4, 1).Left + 3, CenterOf(G.CellRect(4, 1)).Y));
    CheckEquals('1', G.Cells[4, 1], 'Klick neben das Kaestchen: nur Fokus');
    K := VK_SPACE;
    TGridAccess(G).KeyDown(K, []);
    CheckEquals('0', G.Cells[4, 1], 'Leertaste');
    CheckEquals(0, K);
    G.Perform(WM_CHAR, Ord('x'), 0);
    CheckFalse(G.EditorMode, 'Tippen oeffnet keinen Editor');
  finally
    FForm.Hide;
  end;
end;

procedure TGridCellTests.RatingClickKeyAndAcc;
var
  G: TPPGGrid;
  R: TRect;
  Sz, PPI, Pad, Gap, X: Integer;
begin
  FForm.Show;
  try
    G := SampleGrid;
    G.Options := G.Options + [goEditing];
    G.Columns[2].CellKind := ckRating;
    G.Cells[2, 1] := '0';
    R := G.CellRect(2, 1);
    // Sterngroesse wie TPPGRatingCellKind: min(H - 6, (W - 2*Pad - 4*Gap) / 5)
    PPI := TGridAccess(G).ScalePPI;
    Pad := PPGScale(6, PPI);
    Gap := PPGScale(2, PPI);
    Sz := (R.Bottom - R.Top) - PPGScale(6, PPI);
    if Sz > ((R.Right - R.Left) - 2 * Pad - 4 * Gap) div 5 then
      Sz := ((R.Right - R.Left) - 2 * Pad - 4 * Gap) div 5;
    X := R.Left + Pad + 2 * (Sz + Gap) + Sz div 2;
    Click(G, Point(X, CenterOf(R).Y));
    CheckEquals('3', G.Cells[2, 1], 'dritter Stern');
    Click(G, Point(X, CenterOf(R).Y));
    CheckEquals('0', G.Cells[2, 1], 'nochmal: zurueck auf 0');
    G.Perform(WM_CHAR, Ord('4'), 0);
    CheckEquals('4', G.Cells[2, 1], 'Ziffer');
    CheckFalse(G.EditorMode, 'Ziffer oeffnet keinen Editor');
    G.Perform(WM_CHAR, Ord('9'), 0);
    CheckTrue(G.EditorMode or (G.Cells[2, 1] = '4'), '9 > 5 Sterne: kein Wert');
    G.HideEditor(False);
    CheckEquals('4/5', TGridAccess(G).UiaValue(PPGUiaId(PPGUiaKindGridCell, 1, 2)));
    G.Columns[2].MaxValue := 10;
    CheckEquals('4/10', TGridAccess(G).UiaValue(PPGUiaId(PPGUiaKindGridCell, 1, 2)));
  finally
    FForm.Hide;
  end;
end;

procedure TGridCellTests.ProgressAcc;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.Columns[2].CellKind := ckProgress;
  G.Cells[2, 1] := '50';
  CheckEquals(Format(PPGStr(@SPPGPercentFormat), [50]), TGridAccess(G).UiaValue(PPGUiaId(PPGUiaKindGridCell, 1, 2)));
  G.Columns[2].MaxValue := 200;
  CheckEquals(Format(PPGStr(@SPPGPercentFormat), [25]), TGridAccess(G).UiaValue(PPGUiaId(PPGUiaKindGridCell, 1, 2)));
  G.Cells[2, 1] := '999';
  CheckEquals(Format(PPGStr(@SPPGPercentFormat), [100]), TGridAccess(G).UiaValue(PPGUiaId(PPGUiaKindGridCell, 1, 2)),
    'begrenzt');
end;

procedure TGridCellTests.ColumnRangeStaysOrdered;
var
  G: TPPGGrid;
  C: TPPGGridColumn;
begin
  // Audit 08.10.2026: MinValue > MaxValue wurde still angenommen
  G := SampleGrid;
  C := G.Columns[2];
  C.MinValue := 10;
  CheckEquals(10, C.MaxValue, 'MaxValue folgt MinValue');
  C.MaxValue := 50;
  CheckEquals(10, C.MinValue);
  C.MaxValue := 5;
  CheckEquals(5, C.MinValue, 'MinValue folgt MaxValue');
  CheckTrue(C.MinValue <= C.MaxValue);
end;

procedure TGridCellTests.LinkKind;
var
  G: TPPGGrid;
  R: TRect;
  K: Word;
  Id: TPPGUiaId;
begin
  FForm.Show;
  try
    G := SampleGrid;
    G.Columns[1].CellKind := ckLink;
    R := G.CellRect(1, 2);
    Click(G, Point(R.Left + 10, CenterOf(R).Y));
    CheckEquals(1, FLinks.Count, 'Klick auf den Text');
    CheckEquals('1,2:Text 2', FLinks[0]);
    Click(G, Point(R.Right - 3, CenterOf(R).Y));
    CheckEquals(1, FLinks.Count, 'hinter dem Text: kein Link');
    K := VK_RETURN;
    TGridAccess(G).KeyDown(K, []);
    CheckEquals(2, FLinks.Count, 'Enter');
    CheckTrue(PPGCellKind(ckLink).CellCursor(TGridAccess(G).KindContext(1), R,
      Point(R.Left + 10, CenterOf(R).Y), 'Text 2') = crHandPoint);
    Id := PPGUiaId(PPGUiaKindGridCell, 3, 1);
    CheckEquals(UIA_HyperlinkControlTypeId, TGridAccess(G).UiaControlType(Id));
    CheckTrue(TGridAccess(G).UiaHasPattern(Id, UIA_InvokePatternId));
    TGridAccess(G).UiaExecute(Id, uaInvoke, '');
    CheckEquals('1,3:Text 3', FLinks[2]);
  finally
    FForm.Hide;
  end;
end;

procedure TGridCellTests.ButtonKind;
var
  G: TPPGGrid;
  K: Word;
  Id: TPPGUiaId;
begin
  FForm.Show;
  try
    G := SampleGrid;
    G.Options := G.Options + [goEditing];
    G.Columns[3].CellKind := ckButton;
    Click(G, CenterOf(G.CellRect(3, 1)));
    CheckEquals(1, FButtons);
    K := VK_SPACE;
    TGridAccess(G).KeyDown(K, []);
    CheckEquals(2, FButtons, 'Leertaste');
    G.Perform(WM_CHAR, Ord('a'), 0);
    CheckFalse(G.EditorMode, 'kein Editor');
    Id := PPGUiaId(PPGUiaKindGridCell, 1, 3);
    CheckEquals(UIA_ButtonControlTypeId, TGridAccess(G).UiaControlType(Id));
    TGridAccess(G).UiaExecute(Id, uaInvoke, '');
    CheckEquals(3, FButtons);
  finally
    FForm.Hide;
  end;
end;

procedure TGridCellTests.MarkupKindLink;
var
  G: TPPGGrid;
  K: IPPGCellKind;
  Ctx: TPPGCellKindContext;
  R: TRect;
  NewText: string;
  Act: TPPGCellAction;
begin
  G := SampleGrid;
  G.Columns[1].CellKind := ckMarkup;
  K := PPGCellKind(ckMarkup);
  Ctx := TGridAccess(G).KindContext(1);
  CheckEquals('fett und Link', K.CellAccText(Ctx, '<b>fett</b> und <a href="ziel">Link</a>'));
  R := Rect(0, 0, 400, 24);
  Act := K.CellClick(Ctx, R, Point(R.Left + PPGScale(6, Ctx.PPI) + 3, 12), '<a href="ziel">Link</a>', NewText);
  CheckTrue(Act = caLink, 'Link im Markup');
  CheckEquals('ziel', NewText);
  Act := K.CellClick(Ctx, R, Point(390, 12), '<a href="ziel">Link</a>', NewText);
  CheckTrue(Act = caNone);
end;

procedure TGridCellTests.ColorParsing;
var
  C: TColor;
begin
  CheckTrue(PPGCellColor('clRed', C));
  CheckEquals(clRed, C);
  CheckTrue(PPGCellColor('#FF8800', C));
  CheckEquals($0088FF, C, '#RRGGBB -> $BBGGRR');
  CheckTrue(PPGCellColor('$00FF0000', C));
  CheckEquals($00FF0000, C);
  CheckTrue(PPGCellColor('255', C));
  CheckEquals(255, C);
  CheckFalse(PPGCellColor('', C));
  CheckFalse(PPGCellColor('Blau', C));
  CheckFalse(PPGCellColor('#12', C));
end;

procedure TGridCellTests.KindsPaint;
var
  G: TPPGGrid;
  IL: TCustomImageList;
  B: TBitmap;
  Bmp: TBitmap;
  K: TPPGGridCellKind;
  I: Integer;
begin
  G := SampleGrid;
  IL := TCustomImageList.CreateSize(16, 16);
  try
    B := TBitmap.Create;
    try
      B.SetSize(16, 16);
      B.Canvas.Brush.Color := clRed;
      B.Canvas.FillRect(Rect(0, 0, 16, 16));
      IL.Add(B, nil);
    finally
      B.Free;
    end;
    TGridAccess(G).Images := IL;
    G.Columns.Add;
    G.Columns.Add;
    G.Columns.Add;
    G.Columns.Add;
    G.Columns.Add;
    G.Columns[1].CellKind := ckSparkline;
    G.Columns[2].CellKind := ckProgress;
    G.Columns[3].CellKind := ckColor;
    G.Columns[4].CellKind := ckImage;
    G.Columns[5].CellKind := ckRating;
    G.Columns[6].CellKind := ckMarkup;
    G.Columns[7].CellKind := ckButton;
    G.Columns[8].CellKind := ckLink;
    for I := 1 to 5 do
    begin
      G.Cells[1, I] := '3;5;2;8;' + IntToStr(I);
      G.Cells[3, I] := '#22AA44';
      G.Cells[4, I] := '0';
      G.Cells[5, I] := IntToStr(I);
      G.Cells[6, I] := '<b>B</b><i>i</i>';
      G.Cells[7, I] := 'OK';
      G.Cells[8, I] := 'Link';
    end;
    G.Cells[1, 5] := 'kaputt;x';
    G.Cells[4, 5] := '99'; // kein Bild
    for I := 0 to 1 do
    begin
      if I = 1 then
        G.BiDiMode := bdRightToLeft;
      Bmp := RenderToBitmap(G);
      Bmp.Free;
    end;
    CheckEquals(0, FErrors.Count, FErrors.Text);
    for K := ckCheck to ckMarkup do
      CheckNotNull(PPGCellKind(K));
    TGridAccess(G).Images := nil;
  finally
    IL.Free;
  end;
end;

procedure TGridCellTests.RangeEqualContains;
var
  G: TPPGGrid;
  F: TPPGGridConditionalFormat;
  A: TGridAccess;
  T: TPPGTokens;
begin
  G := SampleGrid;
  A := TGridAccess(G);
  A.PrepareKindContext(nil);
  T := G.Tokens;
  F := G.ConditionalFormats.Add;
  F.Column := 2;
  F.Rule := crRange;
  F.Value1 := '20';
  F.Value2 := '30';
  F.Color := ccDanger;
  CheckTrue(A.CellStyle(2, 1, '10').IsDefault, '10 ausserhalb');
  CheckTrue(A.CellStyle(2, 2, '20').Fill <> clNone, '20 im Bereich');
  CheckTrue(A.CellStyle(2, 3, '30').Fill <> clNone);
  CheckTrue(A.CellStyle(2, 4, '31').IsDefault);
  CheckTrue(A.CellStyle(1, 2, '20').IsDefault, 'andere Spalte');
  F.Value1 := '';
  CheckTrue(A.CellStyle(2, 1, '-5').Fill <> clNone, 'offene Untergrenze');
  F.Enabled := False;
  CheckTrue(A.CellStyle(2, 1, '-5').IsDefault, 'abgeschaltet');
  F := G.ConditionalFormats.Add;
  F.Rule := crContains;
  F.Value1 := 'wert3';
  F.Target := ctText;
  F.Color := ccSuccess;
  CheckEquals(T.Success, A.CellStyle(3, 3, 'Wert3').TextColor, 'Enthaelt, alle Spalten, Textfarbe');
  CheckTrue(A.CellStyle(3, 2, 'Wert2').IsDefault);
  F.Rule := crEqual;
  F.Value1 := '40';
  CheckEquals(T.Success, A.CellStyle(2, 4, '40,0').TextColor, 'Gleich als Zahl');
end;

procedure TGridCellTests.TopBottomFollowFilter;
var
  G: TPPGGrid;
  F: TPPGGridConditionalFormat;
  A: TGridAccess;
begin
  G := SampleGrid;
  A := TGridAccess(G);
  A.PrepareKindContext(nil);
  F := G.ConditionalFormats.Add;
  F.Column := 2;
  F.Rule := crTop;
  F.Value1 := '2';
  A.RecalcAggregates;
  CheckTrue(A.CellStyle(2, 5, '50').Fill <> clNone, 'Top 2: 50');
  CheckTrue(A.CellStyle(2, 4, '40').Fill <> clNone, 'Top 2: 40');
  CheckTrue(A.CellStyle(2, 3, '30').IsDefault);
  G.Filters[1] := 'Text 1';
  CheckTrue(A.CellStyle(2, 1, '10').Fill <> clNone, 'nach Filter: Top aus den sichtbaren Zeilen');
  G.ClearFilters;
  F.Rule := crBottom;
  F.Value1 := '40%';
  A.RecalcAggregates;
  CheckTrue(A.CellStyle(2, 2, '20').Fill <> clNone, 'Unten 40 % = 2 Werte');
  CheckTrue(A.CellStyle(2, 3, '30').IsDefault);
end;

procedure TGridCellTests.TopWithThousandSeparators;
var
  G: TPPGGrid;
  F: TPPGGridConditionalFormat;
  A: TGridAccess;
begin
  // Regression: Werte mit Tausendertrenner fehlten in der Statistik
  G := SampleGrid;
  A := TGridAccess(G);
  A.PrepareKindContext(nil);
  G.Cells[2, 1] := '1.500,00';
  G.Cells[2, 2] := '2.000,00';
  F := G.ConditionalFormats.Add;
  F.Column := 2;
  F.Rule := crTop;
  F.Value1 := '2';
  A.RecalcAggregates;
  CheckTrue(A.CellStyle(2, 2, '2.000,00').Fill <> clNone);
  CheckTrue(A.CellStyle(2, 1, '1.500,00').Fill <> clNone);
  CheckTrue(A.CellStyle(2, 5, '50').IsDefault, 'nur die zwei groessten');
end;

procedure TGridCellTests.ScaleBarIcons;
var
  G: TPPGGrid;
  F: TPPGGridConditionalFormat;
  A: TGridAccess;
  Lo, Hi: TPPGGridCellStyle;
begin
  G := SampleGrid;
  A := TGridAccess(G);
  A.PrepareKindContext(nil);
  F := G.ConditionalFormats.Add;
  F.Column := 2;
  F.Rule := crColorScale;
  F.Color := ccSuccess;
  F := G.ConditionalFormats.Add;
  F.Column := 2;
  F.Rule := crDataBar;
  F := G.ConditionalFormats.Add;
  F.Column := 2;
  F.Rule := crIconSet;
  F := G.ConditionalFormats.Add;
  F.Rule := crDataBar; // ohne Spalte: Statistik-Regel wirkt nicht
  A.RecalcAggregates;
  Lo := A.CellStyle(2, 1, '10');
  Hi := A.CellStyle(2, 5, '50');
  CheckTrue(Lo.Fill <> Hi.Fill, 'Farbskala');
  CheckEquals(0, Lo.Bar, 0.001, 'Datenbalken min');
  CheckEquals(1, Hi.Bar, 0.001, 'Datenbalken max');
  CheckEquals(0.5, A.CellStyle(2, 3, '30').Bar, 0.001);
  CheckEquals(0, Lo.Icon, 'Symbol runter');
  CheckEquals(1, A.CellStyle(2, 3, '30').Icon, 'gleich');
  CheckEquals(2, Hi.Icon, 'hoch');
  CheckTrue(A.CellStyle(1, 1, '10').IsDefault, 'Regel ohne Spalte nicht auf Spalte 1');
end;

procedure TGridCellTests.CellStyleEventAndBold;
var
  G: TPPGGrid;
  F: TPPGGridConditionalFormat;
  St: TPPGGridCellStyle;
  Bmp: TBitmap;
begin
  G := SampleGrid;
  G.OnGetCellStyle := GetStyle;
  TGridAccess(G).PrepareKindContext(nil);
  St := TGridAccess(G).CellStyle(3, 1, 'Wert1');
  CheckEquals(clRed, St.TextColor);
  CheckTrue(St.Bold);
  F := G.ConditionalFormats.Add;
  F.Rule := crEqual;
  F.Value1 := 'Wert2';
  F.Bold := True;
  CheckTrue(TGridAccess(G).CellStyle(3, 2, 'Wert2').Bold);
  FStyleCalls := 0;
  Bmp := RenderToBitmap(G);
  Bmp.Free;
  CheckTrue(FStyleCalls >= 4 * 5, 'Ereignis je Datenzelle');
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TGridCellTests.StylesPaintFill;
var
  G: TPPGGrid;
  F: TPPGGridConditionalFormat;
  Bmp: TBitmap;
  R: TRect;
  P: TPoint;
  C0, C1: TColor;
begin
  G := SampleGrid;
  G.Cells[2, 2] := '';
  Bmp := RenderToBitmap(G);
  try
    R := G.CellRect(2, 2);
    P := Point(R.Right - 6, R.Top + 4);
    C0 := Bmp.Canvas.Pixels[P.X, P.Y];
  finally
    Bmp.Free;
  end;
  F := G.ConditionalFormats.Add;
  F.Column := 2;
  F.Rule := crContains;
  F.Value1 := '';
  F.Rule := crEqual;
  F.Color := ccCustom;
  F.CustomColor := clRed;
  Bmp := RenderToBitmap(G);
  try
    C1 := Bmp.Canvas.Pixels[P.X, P.Y];
  finally
    Bmp.Free;
  end;
  CheckTrue(C0 <> C1, 'Flaeche der leeren Zelle (Gleich '''')');
end;

procedure TGridCellTests.MergeValidation;
var
  G: TPPGGrid;
  M: TPPGGridMerge;

  procedure Expect(ACol, ARow, ACS, ARS: Integer; const Msg: string);
  begin
    try
      G.MergeCells(ACol, ARow, ACS, ARS);
      Fail(Msg);
    except
      on E: Exception do
        if E is ETestFailure then
          raise;
    end;
  end;

begin
  G := SampleGrid;
  G.MergeCells(1, 1, 2, 2);
  CheckEquals(1, G.MergeCount);
  M := G.MergeInfo(0);
  CheckEquals(2, M.ColSpan);
  Expect(2, 2, 2, 1, 'Ueberlappung');
  Expect(4, 1, 2, 1, 'zu breit');
  Expect(1, 5, 1, 2, 'zu hoch');
  Expect(1, 4, 1, 1, '1x1 ist keine Verbindung');
  G.MergeCells(3, 1, 2, 1);
  CheckEquals(2, G.MergeCount);
  G.UnmergeCells(2, 2); // irgendeine Zelle der Verbindung
  CheckEquals(1, G.MergeCount);
  CheckEquals(3, G.MergeInfo(0).Col);
  G.ClearMerges;
  CheckEquals(0, G.MergeCount);
end;

procedure TGridCellTests.MergeFocusAndKeys;
var
  G: TPPGGrid;
  K: Word;
begin
  G := SampleGrid;
  G.MergeCells(2, 2, 2, 2); // Spalten 2-3, Zeilen 2-3
  G.Row := 3;
  G.Col := 3;
  CheckEquals(2, G.Col, 'Fokus springt auf den Ursprung');
  CheckEquals(2, G.Row);
  K := VK_RIGHT;
  TGridAccess(G).KeyDown(K, []);
  CheckEquals(4, G.Col, 'rechts ueber die Verbindung hinweg');
  K := VK_LEFT;
  TGridAccess(G).KeyDown(K, []);
  CheckEquals(2, G.Col, 'links in die Verbindung = Ursprung');
  K := VK_DOWN;
  TGridAccess(G).KeyDown(K, []);
  CheckEquals(4, G.Row, 'runter ueber die Verbindung hinweg');
end;

procedure TGridCellTests.MergePaintNoInnerLine;
var
  G: TPPGGrid;
  Bmp: TBitmap;
  R: TRect;
  Line, Inner, Bg: TColor;
  Y: Integer;
begin
  G := SampleGrid;
  G.Cells[2, 2] := '';
  G.Cells[3, 2] := '';
  G.Cells[2, 3] := '';
  G.Cells[3, 3] := '';
  R := G.CellRect(2, 2);
  Y := R.Bottom + 4; // in Zeile 3, damit kein Text stoert
  Bmp := RenderToBitmap(G);
  try
    Line := Bmp.Canvas.Pixels[R.Right - 1, Y];
    Bg := Bmp.Canvas.Pixels[R.Right - 10, Y];
  finally
    Bmp.Free;
  end;
  CheckTrue(Line <> Bg, 'ohne Verbindung: Gitterlinie');
  G.MergeCells(2, 2, 2, 2);
  Bmp := RenderToBitmap(G);
  try
    Inner := Bmp.Canvas.Pixels[R.Right - 1, Y];
    CheckEquals(Bg, Inner, 'keine Linie innerhalb der Verbindung');
    Inner := Bmp.Canvas.Pixels[R.Left + 10, R.Bottom - 1];
    CheckEquals(Bg, Inner, 'keine waagerechte Linie innerhalb');
  finally
    Bmp.Free;
  end;
end;

procedure TGridCellTests.MergesRestWhenSorted;
var
  G: TPPGGrid;
begin
  G := SampleGrid;
  G.MergeCells(2, 2, 2, 2);
  CheckTrue(TGridAccess(G).MergesActive);
  G.SortBy(2, False);
  CheckFalse(TGridAccess(G).MergesActive, 'sortiert: Verbindungen ruhen');
  G.Row := 3;
  G.Col := 3;
  CheckEquals(3, G.Col, 'kein Sprung zum Ursprung');
  G.SortBy(-1);
  CheckTrue(TGridAccess(G).MergesActive);
  G.Columns[3].Visible := False;
  G.Row := 2;
  G.Col := 2;
  CheckEquals(2, G.Col);
  CheckEquals(1, G.MergeCount, 'ausgeblendete Spalte: Verbindung bleibt gespeichert');
end;

procedure TGridCellTests.MergeEditorCoversArea;
var
  G: TPPGGrid;
  R: TRect;
begin
  FForm.Show;
  try
    G := SampleGrid;
    G.Options := G.Options + [goEditing];
    G.MergeCells(1, 1, 2, 1);
    G.Row := 1;
    G.Col := 1;
    G.SetFocus;
    G.ShowEditor;
    CheckTrue(G.EditorMode);
    R := G.CellRect(1, 1);
    CheckTrue(G.InplaceEditor.Width > (R.Right - R.Left) + 40, 'Editor ueber beide Spalten');
    G.HideEditor(False);
  finally
    FForm.Hide;
  end;
end;

procedure TGridCellTests.DfmKeepsKindsAndFormats;
var
  G, G2: TPPGGrid;
  M: TMemoryStream;
  F: TPPGGridConditionalFormat;
begin
  G := SampleGrid;
  G.Columns[1].CellKind := ckCustom;
  G.Columns[1].CellKindName := 'Eigen';
  G.Columns[2].CellKind := ckRating;
  F := G.ConditionalFormats.Add;
  F.Column := 2;
  F.Rule := crTop;
  F.Value1 := '10%';
  F.Color := ccCustom;
  F.CustomColor := clLime;
  F.Target := ctText;
  F.Bold := True;
  M := TMemoryStream.Create;
  try
    M.WriteComponent(G);
    M.Position := 0;
    G2 := TPPGGrid.Create(FForm);
    G2.Parent := FForm;
    M.ReadComponent(G2);
    CheckTrue(G2.Columns[1].CellKind = ckCustom);
    CheckEquals('Eigen', G2.Columns[1].CellKindName);
    CheckTrue(G2.Columns[2].CellKind = ckRating);
    CheckEquals(1, G2.ConditionalFormats.Count);
    F := G2.ConditionalFormats[0];
    CheckEquals(2, F.Column);
    CheckTrue(F.Rule = crTop);
    CheckEquals('10%', F.Value1);
    CheckTrue(F.Color = ccCustom);
    CheckEquals(clLime, F.CustomColor);
    CheckTrue(F.Target = ctText);
    CheckTrue(F.Bold);
  finally
    M.Free;
  end;
end;

initialization
  RegisterTest('Phase13d', TGridCellTests.Suite);

end.
