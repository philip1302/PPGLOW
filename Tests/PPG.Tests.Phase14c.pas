unit PPG.Tests.Phase14c;

{ Tests fuer Phase 14c, Kern ohne Fenster: Stapel, Einfuegeposition,
  Zielindex und Hilfen der Karten (PPG.Kanban.Layout). }

interface

uses
  TestFramework, System.SysUtils, PPG.Kanban.Layout;

type
  TKanbanLayoutTests = class(TTestCase)
  published
    procedure StackPlacesCardsWithGap;
    procedure FirstBelowFindsCard;
    procedure DropIndexUsesCardCenters;
    procedure DropIndexSkipsDraggedCard;
    procedure MoveIndexClampsToCell;
    procedure InitialsFromNames;
    procedure LabelsSplitAndTrim;
    procedure WipStates;
    procedure HashIndexIsStable;
  end;

implementation

procedure TKanbanLayoutTests.StackPlacesCardsWithGap;
var
  T: TArray<Integer>;
  E: TArray<Integer>;
begin
  CheckEquals(110, PPGKanbanStack([30, 40, 20], 10, 5, T));
  CheckEquals(3, Length(T));
  CheckEquals(10, T[0]);
  CheckEquals(45, T[1]);
  CheckEquals(90, T[2]);
  SetLength(E, 0);
  CheckEquals(7, PPGKanbanStack(E, 7, 5, T), 'ohne Karten');
  CheckEquals(0, Length(T));
end;

procedure TKanbanLayoutTests.FirstBelowFindsCard;
begin
  CheckEquals(0, PPGKanbanFirstBelow([0, 35, 80], [30, 40, 20], -5));
  CheckEquals(0, PPGKanbanFirstBelow([0, 35, 80], [30, 40, 20], 29));
  CheckEquals(1, PPGKanbanFirstBelow([0, 35, 80], [30, 40, 20], 31), 'in der Luecke: naechste');
  CheckEquals(2, PPGKanbanFirstBelow([0, 35, 80], [30, 40, 20], 80));
  CheckEquals(3, PPGKanbanFirstBelow([0, 35, 80], [30, 40, 20], 200), 'darunter: Count');
end;

procedure TKanbanLayoutTests.DropIndexUsesCardCenters;
var
  E: TArray<Integer>;
begin
  SetLength(E, 0);
  // Mitten bei 15, 55, 90
  CheckEquals(0, PPGKanbanDropIndex([0, 35, 80], [30, 40, 20], 10, -1));
  CheckEquals(1, PPGKanbanDropIndex([0, 35, 80], [30, 40, 20], 20, -1));
  CheckEquals(2, PPGKanbanDropIndex([0, 35, 80], [30, 40, 20], 60, -1));
  CheckEquals(3, PPGKanbanDropIndex([0, 35, 80], [30, 40, 20], 95, -1));
  CheckEquals(0, PPGKanbanDropIndex(E, E, 50, -1), 'leere Zelle');
end;

procedure TKanbanLayoutTests.DropIndexSkipsDraggedCard;
begin
  // Karte 1 wird gezogen: sie zaehlt nicht
  CheckEquals(1, PPGKanbanDropIndex([0, 35, 80], [30, 40, 20], 60, 1));
  CheckEquals(2, PPGKanbanDropIndex([0, 35, 80], [30, 40, 20], 95, 1));
  CheckEquals(0, PPGKanbanDropIndex([0, 35, 80], [30, 40, 20], 20, 0), 'ueber sich selbst');
end;

procedure TKanbanLayoutTests.MoveIndexClampsToCell;
begin
  CheckEquals(3, PPGKanbanMoveIndex(2, 5, 4), 'gleiche Zelle: hoechstens Count-1');
  CheckEquals(1, PPGKanbanMoveIndex(2, 1, 4));
  CheckEquals(4, PPGKanbanMoveIndex(-1, 9, 4), 'fremde Zelle: hoechstens Count');
  CheckEquals(0, PPGKanbanMoveIndex(-1, -2, 3));
end;

procedure TKanbanLayoutTests.InitialsFromNames;
begin
  CheckEquals('AB', PPGKanbanInitials('Anna Berg'));
  CheckEquals('AN', PPGKanbanInitials('anna'));
  CheckEquals('MM', PPGKanbanInitials('Max von Mustermann'));
  CheckEquals('JP', PPGKanbanInitials('jean-luc picard'));
  CheckEquals('', PPGKanbanInitials(''));
  CheckEquals('', PPGKanbanInitials('   '));
end;

procedure TKanbanLayoutTests.LabelsSplitAndTrim;
var
  L: TArray<string>;
begin
  L := PPGKanbanSplitLabels('Bug, UI; Wichtig');
  CheckEquals(3, Length(L));
  CheckEquals('Bug', L[0]);
  CheckEquals('UI', L[1]);
  CheckEquals('Wichtig', L[2]);
  CheckEquals(0, Length(PPGKanbanSplitLabels(' , ;')));
  CheckEquals(0, Length(PPGKanbanSplitLabels('')));
end;

procedure TKanbanLayoutTests.WipStates;
begin
  CheckTrue(PPGKanbanWipState(3, 0) = kwsNone);
  CheckTrue(PPGKanbanWipState(2, 3) = kwsOk);
  CheckTrue(PPGKanbanWipState(3, 3) = kwsFull);
  CheckTrue(PPGKanbanWipState(4, 3) = kwsOver);
end;

procedure TKanbanLayoutTests.HashIndexIsStable;
var
  I: Integer;
begin
  CheckEquals(PPGKanbanHashIndex('bug', 8), PPGKanbanHashIndex('BUG', 8), 'ohne Gross-/Kleinschreibung');
  // Audit 11a #4: vorher mit sich selbst verglichen. Stabil heisst: dieselbe
  // Farbe in jeder Version und auf Win32/Win64. Erwartung nach FNV-1a (32 Bit,
  // Grossbuchstaben) unabhaengig vom Code nachgerechnet (Perl, Math::BigInt):
  // FNV1a('FRONTEND') = 1231609661, mod 8 = 5; FNV1a('BUG') = 4169862805,
  // mod 8 = 5. Der Code ist seit 1f3422ec (07.10.2026) unveraendert.
  CheckEquals(5, PPGKanbanHashIndex('Frontend', 8), 'Frontend');
  CheckEquals(5, PPGKanbanHashIndex('bug', 8), 'bug');
  for I := 1 to 50 do
    CheckTrue((PPGKanbanHashIndex('Label' + IntToStr(I), 8) >= 0) and
      (PPGKanbanHashIndex('Label' + IntToStr(I), 8) < 8));
  CheckEquals(0, PPGKanbanHashIndex('x', 0));
end;

initialization
  RegisterTest('Phase14c', TKanbanLayoutTests.Suite);

end.
