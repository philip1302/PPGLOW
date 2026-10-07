unit PPG.Tests.Phase14b;

{ Tests fuer Phase 14b, Kern ohne Fenster: Gruppen-Layout und
  Schrumpf-Algorithmus des Ribbons (PPG.Ribbon.Layout), Vergabe und Abgleich
  der KeyTips (PPG.KeyTips). }

interface

uses
  TestFramework, System.SysUtils, System.Types, PPG.Ribbon.Layout, PPG.KeyTips;

type
  TRibbonLayoutTests = class(TTestCase)
  private
    function Cell(AKind: TPPGRibbonCellKind; AMax: TPPGRibbonSize; WL, WM, WS: Integer;
      AMin: TPPGRibbonSize = rsSmall): TPPGRibbonCell;
    function Metrics: TPPGRibbonMetrics;
  published
    procedure CellSizeFollowsStateWithinLimits;
    procedure LargeItemsAreColumnsSmallItemsStack;
    procedure BeginColumnAndSeparator;
    procedure SameRowPacksHorizontally;
    procedure NarrowContentIsCentered;
    procedure CollapsedGroupHasNoPlaces;
    procedure ReduceOrderAscendingThenRightToLeft;
    procedure ReduceShrinksLevelByLevel;
    procedure ReduceSkipsStepsWithoutGain;
    procedure ReduceStopsWhenEverythingCollapsed;
  end;

  TKeyTipTests = class(TTestCase)
  published
    procedure ExplicitTipsWin;
    procedure HotkeyThenWordStartsThenRest;
    procedure CollisionsGetTwoCharacterTips;
    procedure SingleTipIsNeverPrefix;
    procedure UmlautsAndReserved;
    procedure MatchCountsPrefixes;
  end;

implementation

{ TRibbonLayoutTests }

function TRibbonLayoutTests.Cell(AKind: TPPGRibbonCellKind; AMax: TPPGRibbonSize; WL, WM, WS: Integer;
  AMin: TPPGRibbonSize): TPPGRibbonCell;
begin
  Result.Kind := AKind;
  Result.MaxSize := AMax;
  Result.MinSize := AMin;
  Result.Width[rsLarge] := WL;
  Result.Width[rsMedium] := WM;
  Result.Width[rsSmall] := WS;
  Result.BeginColumn := False;
  Result.SameRow := False;
end;

function TRibbonLayoutTests.Metrics: TPPGRibbonMetrics;
begin
  Result.ContentTop := 10;
  Result.RowHeight := 20;
  Result.Rows := 3;
  Result.ColumnGap := 2;
  Result.Padding := 4;
end;

procedure TRibbonLayoutTests.CellSizeFollowsStateWithinLimits;
var
  C: TPPGRibbonCell;
begin
  C := Cell(rckButton, rsLarge, 40, 60, 24);
  CheckTrue(PPGRibbonCellSize(C, rgsLarge) = rsLarge);
  CheckTrue(PPGRibbonCellSize(C, rgsMedium) = rsMedium);
  CheckTrue(PPGRibbonCellSize(C, rgsSmall) = rsSmall);
  CheckTrue(PPGRibbonCellSize(C, rgsCollapsed) = rsSmall, 'wie klein');
  // nie groesser als gewuenscht
  C := Cell(rckButton, rsMedium, 40, 60, 24);
  CheckTrue(PPGRibbonCellSize(C, rgsLarge) = rsMedium);
  // nie kleiner als erlaubt
  C := Cell(rckButton, rsLarge, 40, 60, 24, rsMedium);
  CheckTrue(PPGRibbonCellSize(C, rgsSmall) = rsMedium);
  C := Cell(rckButton, rsLarge, 40, 60, 24, rsLarge);
  CheckTrue(PPGRibbonCellSize(C, rgsSmall) = rsLarge, 'bleibt gross');
  // Galerie folgt dem Zustand, Control bleibt
  C := Cell(rckGallery, rsLarge, 200, 110, 50);
  CheckTrue(PPGRibbonCellSize(C, rgsMedium) = rsMedium);
  CheckTrue(PPGRibbonCellSize(C, rgsSmall) = rsSmall);
  C := Cell(rckControl, rsMedium, 80, 80, 80);
  CheckTrue(PPGRibbonCellSize(C, rgsSmall) = rsMedium);
  CheckTrue(PPGRibbonCellIsColumn(Cell(rckGallery, rsLarge, 1, 1, 1), rsSmall));
  CheckFalse(PPGRibbonCellIsColumn(Cell(rckControl, rsMedium, 1, 1, 1), rsMedium));
  CheckTrue(PPGRibbonCellIsColumn(Cell(rckButton, rsLarge, 1, 1, 1), rsLarge));
  CheckFalse(PPGRibbonCellIsColumn(Cell(rckButton, rsLarge, 1, 1, 1), rsMedium));
end;

procedure TRibbonLayoutTests.LargeItemsAreColumnsSmallItemsStack;
var
  Cells: array of TPPGRibbonCell;
  P: TPPGRibbonPlaces;
  W: Integer;
begin
  SetLength(Cells, 5);
  Cells[0] := Cell(rckButton, rsLarge, 40, 70, 24);
  Cells[1] := Cell(rckButton, rsMedium, 0, 30, 24);
  Cells[2] := Cell(rckButton, rsMedium, 0, 50, 24);
  Cells[3] := Cell(rckButton, rsMedium, 0, 20, 24);
  Cells[4] := Cell(rckButton, rsMedium, 0, 10, 24);
  W := PPGRibbonLayoutGroup(Cells, rgsLarge, Metrics, 0, P);
  // gross: Spalte ueber die volle Hoehe
  CheckEquals(4, P[0].Bounds.Left);
  CheckEquals(10, P[0].Bounds.Top);
  CheckEquals(70, P[0].Bounds.Bottom, '3 Zeilen');
  CheckEquals(44, P[0].Bounds.Right);
  // Stapel 1: drei Zeilen, Spaltenbreite = breitestes Item (50)
  CheckEquals(46, P[1].Bounds.Left);
  CheckEquals(10, P[1].Bounds.Top);
  CheckEquals(30, P[2].Bounds.Top);
  CheckEquals(50, P[3].Bounds.Top);
  CheckEquals(76, P[1].Bounds.Right, 'eigene Breite');
  // viertes kleines Item: neue Spalte
  CheckEquals(46 + 50 + 2, P[4].Bounds.Left);
  CheckEquals(10, P[4].Bounds.Top);
  CheckEquals(98 + 10 + 4, W, 'Breite bis zum Innenabstand');
  // im Zustand "mittel" wird das grosse Item klein und stapelt sich mit
  W := PPGRibbonLayoutGroup(Cells, rgsMedium, Metrics, 0, P);
  CheckTrue(P[0].Size = rsMedium);
  CheckEquals(4, P[1].Bounds.Left, 'gleiche Spalte');
  CheckEquals(30, P[1].Bounds.Top);
  CheckEquals(4 + 70 + 2, P[3].Bounds.Left, 'Spalte 2');
  CheckEquals(4 + 70 + 2 + 20 + 4, W);
  // nur Symbol
  W := PPGRibbonLayoutGroup(Cells, rgsSmall, Metrics, 0, P);
  CheckTrue(P[2].Size = rsSmall);
  CheckEquals(4 + 24 + 2 + 24 + 4, W);
end;

procedure TRibbonLayoutTests.BeginColumnAndSeparator;
var
  Cells: array of TPPGRibbonCell;
  P: TPPGRibbonPlaces;
begin
  SetLength(Cells, 4);
  Cells[0] := Cell(rckButton, rsMedium, 0, 30, 24);
  Cells[1] := Cell(rckButton, rsMedium, 0, 30, 24);
  Cells[1].BeginColumn := True;
  Cells[2] := Cell(rckSeparator, rsMedium, 9, 9, 9);
  Cells[3] := Cell(rckControl, rsMedium, 80, 80, 80);
  PPGRibbonLayoutGroup(Cells, rgsLarge, Metrics, 0, P);
  CheckEquals(4, P[0].Bounds.Left);
  CheckEquals(36, P[1].Bounds.Left, 'neue Spalte erzwungen');
  CheckEquals(10, P[1].Bounds.Top);
  CheckEquals(68, P[2].Bounds.Left, 'Trenner als Spalte');
  CheckEquals(70, P[2].Bounds.Bottom);
  CheckEquals(79, P[3].Bounds.Left, 'Control stapelt sich');
  CheckEquals(30, P[3].Bounds.Bottom - P[3].Bounds.Top + 10, 'eine Zeile hoch');
end;

procedure TRibbonLayoutTests.SameRowPacksHorizontally;
var
  Cells: array of TPPGRibbonCell;
  P: TPPGRibbonPlaces;
  W: Integer;
begin
  // Control oben, darunter drei kleine Buttons in einer Zeile
  SetLength(Cells, 4);
  Cells[0] := Cell(rckControl, rsMedium, 100, 100, 100);
  Cells[1] := Cell(rckButton, rsSmall, 24, 24, 24);
  Cells[2] := Cell(rckButton, rsSmall, 24, 24, 24);
  Cells[2].SameRow := True;
  Cells[3] := Cell(rckButton, rsSmall, 24, 24, 24);
  Cells[3].SameRow := True;
  W := PPGRibbonLayoutGroup(Cells, rgsLarge, Metrics, 0, P);
  CheckEquals(30, P[1].Bounds.Top, 'zweite Zeile');
  CheckEquals(30, P[2].Bounds.Top, 'gleiche Zeile');
  CheckEquals(30, P[3].Bounds.Top);
  CheckEquals(P[1].Bounds.Right + 2, P[2].Bounds.Left, 'rechts daneben');
  CheckEquals(P[2].Bounds.Right + 2, P[3].Bounds.Left);
  CheckEquals(4 + 100 + 4, W, 'Spalte so breit wie das Control');
  // breiter als das Control: die Spalte waechst mit der Zeile
  Cells[0] := Cell(rckControl, rsMedium, 50, 50, 50);
  W := PPGRibbonLayoutGroup(Cells, rgsLarge, Metrics, 0, P);
  CheckEquals(4 + 3 * 24 + 2 * 2 + 4, W);
  // SameRow am Anfang eines Stapels wirkt nicht
  Cells[1].SameRow := True;
  Cells[1].BeginColumn := True;
  PPGRibbonLayoutGroup(Cells, rgsLarge, Metrics, 0, P);
  CheckEquals(10, P[1].Bounds.Top, 'neue Spalte, erste Zeile');
end;

procedure TRibbonLayoutTests.NarrowContentIsCentered;
var
  Cells: array of TPPGRibbonCell;
  P: TPPGRibbonPlaces;
  W: Integer;
begin
  SetLength(Cells, 1);
  Cells[0] := Cell(rckButton, rsLarge, 40, 40, 24);
  W := PPGRibbonLayoutGroup(Cells, rgsLarge, Metrics, 100, P);
  CheckEquals(100, W, 'Beschriftung breiter');
  CheckEquals(4 + (100 - 48) div 2, P[0].Bounds.Left);
  // leere Gruppe
  SetLength(Cells, 0);
  CheckEquals(60, PPGRibbonLayoutGroup(Cells, rgsLarge, Metrics, 60, P));
end;

procedure TRibbonLayoutTests.CollapsedGroupHasNoPlaces;
var
  Cells: array of TPPGRibbonCell;
  P: TPPGRibbonPlaces;
begin
  SetLength(Cells, 2);
  Cells[0] := Cell(rckButton, rsLarge, 40, 40, 24);
  Cells[1] := Cell(rckButton, rsMedium, 0, 40, 24);
  CheckEquals(55, PPGRibbonLayoutGroup(Cells, rgsCollapsed, Metrics, 55, P));
  CheckEquals(2, Length(P));
  CheckTrue(IsRectEmpty(P[0].Bounds));
  CheckTrue(IsRectEmpty(P[1].Bounds));
end;

procedure TRibbonLayoutTests.ReduceOrderAscendingThenRightToLeft;
var
  O: TArray<Integer>;
begin
  O := PPGRibbonReduceOrder([0, 0, 1, -1, 0]);
  CheckEquals(5, Length(O));
  CheckEquals(3, O[0], 'kleinster Wert zuerst');
  CheckEquals(4, O[1], 'Gleichstand: von rechts');
  CheckEquals(1, O[2]);
  CheckEquals(0, O[3]);
  CheckEquals(2, O[4], 'groesster Wert zuletzt');
end;

function GW(L, M, S, C: Integer): TPPGRibbonGroupWidths;
begin
  Result[rgsLarge] := L;
  Result[rgsMedium] := M;
  Result[rgsSmall] := S;
  Result[rgsCollapsed] := C;
end;

procedure TRibbonLayoutTests.ReduceShrinksLevelByLevel;
var
  W: array of TPPGRibbonGroupWidths;
  O: TArray<Integer>;
  S: TPPGRibbonGroupStates;
begin
  SetLength(W, 3);
  W[0] := GW(100, 80, 50, 40);
  W[1] := GW(100, 80, 50, 40);
  W[2] := GW(100, 80, 50, 40);
  O := PPGRibbonReduceOrder([0, 0, 0]);
  // passt: nichts schrumpft (Gap 1 zwischen den Gruppen)
  S := PPGRibbonReduce(W, O, 302, 1);
  CheckTrue((S[0] = rgsLarge) and (S[1] = rgsLarge) and (S[2] = rgsLarge));
  // 20 px zu wenig: nur die rechte Gruppe wird mittel
  S := PPGRibbonReduce(W, O, 282, 1);
  CheckTrue(S[2] = rgsMedium, 'rechts zuerst');
  CheckTrue((S[0] = rgsLarge) and (S[1] = rgsLarge));
  // erst alle auf mittel, bevor eine nur noch Symbole zeigt
  S := PPGRibbonReduce(W, O, 242, 1);
  CheckTrue((S[0] = rgsMedium) and (S[1] = rgsMedium) and (S[2] = rgsMedium));
  S := PPGRibbonReduce(W, O, 241, 1);
  CheckTrue(S[2] = rgsSmall, 'naechste Stufe rechts');
  CheckTrue((S[0] = rgsMedium) and (S[1] = rgsMedium));
  // ganz schmal: Dropdowns
  S := PPGRibbonReduce(W, O, 132, 1);
  CheckTrue(S[2] = rgsCollapsed);
  CheckTrue(S[1] = rgsCollapsed);
  CheckTrue(S[0] = rgsSmall, 'links reicht "nur Symbol"');
  CheckEquals(50 + 40 + 40 + 2, PPGRibbonTotalWidth(W, S, 1));
end;

procedure TRibbonLayoutTests.ReduceSkipsStepsWithoutGain;
var
  W: array of TPPGRibbonGroupWidths;
  S: TPPGRibbonGroupStates;
begin
  SetLength(W, 2);
  // Gruppe 1: "mittel" ist breiter als "gross" (lange Beschriftung einzeilig)
  W[0] := GW(100, 80, 50, 40);
  W[1] := GW(60, 90, 30, 40);
  S := PPGRibbonReduce(W, PPGRibbonReduceOrder([0, 0]), 150, 0);
  CheckTrue(S[1] = rgsLarge, 'mittel bringt nichts');
  CheckTrue(S[0] = rgsMedium);
  S := PPGRibbonReduce(W, PPGRibbonReduceOrder([0, 0]), 110, 0);
  CheckTrue(S[1] = rgsSmall, 'direkt auf nur Symbol');
  // Dropdown breiter als nur Symbol: bleibt nur Symbol
  S := PPGRibbonReduce(W, PPGRibbonReduceOrder([0, 0]), 10, 0);
  CheckTrue(S[1] = rgsSmall);
  CheckTrue(S[0] = rgsCollapsed);
end;

procedure TRibbonLayoutTests.ReduceStopsWhenEverythingCollapsed;
var
  W: array of TPPGRibbonGroupWidths;
  S: TPPGRibbonGroupStates;
  None: array of Integer;
begin
  SetLength(W, 2);
  W[0] := GW(100, 80, 50, 40);
  W[1] := GW(100, 80, 50, 40);
  S := PPGRibbonReduce(W, PPGRibbonReduceOrder([0, 0]), 0, 1);
  CheckTrue((S[0] = rgsCollapsed) and (S[1] = rgsCollapsed));
  // ohne Gruppen
  SetLength(W, 0);
  SetLength(None, 0);
  CheckEquals(0, Length(PPGRibbonReduce(W, PPGRibbonReduceOrder(None), 100, 1)));
end;

{ TKeyTipTests }

procedure TKeyTipTests.ExplicitTipsWin;
var
  T: TArray<string>;
begin
  T := PPGAssignKeyTips(['Start', 'Einfuegen', 'Seitenlayout'], ['', 'n', 'P']);
  CheckEquals('N', T[1], 'eigener KeyTip, gross');
  CheckEquals('P', T[2]);
  CheckEquals('S', T[0]);
end;

procedure TKeyTipTests.HotkeyThenWordStartsThenRest;
var
  T: TArray<string>;
begin
  T := PPGAssignKeyTips(['&Datei', 'Daten&blatt', 'Druck Vorschau', 'Dokument'], ['', '', '', '']);
  CheckEquals('D', T[0], '&D');
  CheckEquals('B', T[1], '&b');
  CheckEquals('V', T[2], 'Wortanfang V');
  CheckEquals('O', T[3], 'naechster freier Buchstabe');
end;

procedure TKeyTipTests.CollisionsGetTwoCharacterTips;
var
  T: TArray<string>;
  I, J: Integer;
begin
  T := PPGAssignKeyTips(['A', 'A', 'A'], ['', '', '']);
  CheckEquals('A', T[0]);
  CheckEquals(2, Length(T[1]));
  CheckEquals(2, Length(T[2]));
  CheckTrue(T[1] <> T[2], 'eindeutig');
  CheckFalse(T[1][1] = 'A', 'Praefix ist kein Einzelzeichen');
  CheckEquals(T[1][1], T[2][1], 'gleiches Praefix');
  // viele gleiche: alle eindeutig
  T := PPGAssignKeyTips(['X', 'X', 'X', 'X', 'X', 'X', 'X', 'X', 'X', 'X'],
    ['', '', '', '', '', '', '', '', '', '']);
  for I := 0 to High(T) do
    for J := I + 1 to High(T) do
      CheckTrue(T[I] <> T[J], T[I] + ' doppelt');
end;

procedure TKeyTipTests.SingleTipIsNeverPrefix;
var
  T: TArray<string>;
  I, J: Integer;
begin
  // eigener Zweier "FN" sperrt "F" als Einzelzeichen
  T := PPGAssignKeyTips(['Fett', 'Format'], ['', 'FN']);
  CheckEquals('FN', T[1]);
  CheckFalse(T[0] = 'F', 'F waere Praefix von FN');
  CheckEquals('E', T[0]);
  T := PPGAssignKeyTips(['Ab', 'Ab', 'Ba', 'Ba', 'Ca'], ['', '', '', '', '']);
  for I := 0 to High(T) do
    for J := 0 to High(T) do
      if (I <> J) and (Length(T[I]) = 1) then
        CheckFalse(Copy(T[J], 1, 1) = T[I], T[I] + ' ist Praefix von ' + T[J]);
end;

procedure TKeyTipTests.UmlautsAndReserved;
var
  T: TArray<string>;
begin
  CheckEquals(#$00DC, PPGKeyTipChar(#$00FC), 'ue -> UE');
  CheckEquals('', PPGKeyTipChar(' '));
  CheckEquals('', PPGKeyTipChar('-'));
  CheckEquals('7', PPGKeyTipChar('7'));
  T := PPGAssignKeyTips([#$00DC'berpr'#$00FC'fen'], ['']);
  CheckEquals(#$00DC, T[0]);
  T := PPGAssignKeyTips(['Start'], [''], 'S');
  CheckEquals('T', T[0], 'S ist reserviert');
end;

procedure TKeyTipTests.MatchCountsPrefixes;
var
  Exact: Integer;
begin
  CheckEquals(3, PPGMatchKeyTips(['ZA', 'ZB', 'ZC', 'A'], 'z', Exact));
  CheckEquals(-1, Exact);
  CheckEquals(1, PPGMatchKeyTips(['ZA', 'ZB', 'ZC', 'A'], 'zb', Exact));
  CheckEquals(1, Exact);
  CheckEquals(0, PPGMatchKeyTips(['ZA', 'A'], 'Q', Exact));
  CheckEquals(0, PPGMatchKeyTips(['ZA', 'A'], '', Exact));
end;

initialization
  RegisterTest('Phase14b', TRibbonLayoutTests.Suite);
  RegisterTest('Phase14b', TKeyTipTests.Suite);

end.
