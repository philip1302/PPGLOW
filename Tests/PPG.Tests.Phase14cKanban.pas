unit PPG.Tests.Phase14cKanban;

{$WARN SYMBOL_PLATFORM OFF}

{ Tests fuer Phase 14c: das Control TPPGKanban (Layout, Treffer, Auswahl,
  Ziehen mit Maus und Tastatur, WIP-Abbruch, Spalten-Bildlauf, virtuelle
  Spalten, Swimlanes, Einklappen, Screenreader, Streaming, Zeichnen). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Imaging.pngimage,
  PPG.Types, PPG.Accessibility, PPG.Render.Registry, PPG.Theme, PPG.Controls.Base,
  PPG.Kanban.Layout, PPG.Kanban.Items, PPG.Kanban, PPG.Tests.Controls;

type
  TKanbanTests = class(TControlTestCase)
  private
    FLog: TStringList;
    FVeto: Boolean;
    function NewBoard: TPPGKanban;
    procedure Drag(K: TPPGKanban; const A, B: TPoint);
    procedure Key(K: TPPGKanban; AKey: Word; Shift: TShiftState = []);
    procedure Moving(Sender: TObject; const Move: TPPGKanbanMove; var Allow: Boolean);
    procedure Moved(Sender: TObject; const Move: TPPGKanbanMove);
    procedure CardClick(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer; Card: TPPGKanbanCard);
    procedure CardOpen(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer; Card: TPPGKanbanCard);
    procedure SelChange(Sender: TObject);
    procedure ColCollapse(Sender: TObject; Column: TPPGKanbanColumn);
    procedure GetCard(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer; var Data: TPPGKanbanCardData);
    function Titles(K: TPPGKanban; C: Integer; L: Integer = 0): string;
    function HasLog(const Prefix: string): Boolean;
    procedure Shot(K: TPPGKanban; const Name: string);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure CreateFreeAndDefaults;
    procedure LayoutColumnsAndCards;
    procedure HitTestParts;
    procedure ClickSelectsAndEnterOpens;
    procedure DragWithinColumn;
    procedure DragToOtherColumn;
    procedure DragVetoAndWipBlock;
    procedure EscapeCancelsDrag;
    procedure ModelChangeDuringDragAndAssignIds;
    procedure KeyboardMovesAndAnnounces;
    procedure ColumnScrollsOnItsOwn;
    procedure VirtualColumn;
    procedure SwimlanesCellsAndMoves;
    procedure CollapseColumns;
    procedure AccessibleChildren;
    procedure StreamingRoundTrip;
    procedure RightToLeftMirrors;
    procedure PaintsAllStates;
    procedure ManyCardsStayFast;
  end;

implementation

uses
  Winapi.oleacc, System.Math, PPG.Tests.Visual, PPG.Exceptions, PPG.Lang, PPG.Consts;

type
  TKanbanAccess = class(TPPGKanban);

function Center(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

{ TKanbanTests }

procedure TKanbanTests.SetUp;
begin
  inherited SetUp;
  FLog := TStringList.Create;
  FVeto := False;
  FForm.SetBounds(0, 0, 1100, 700);
end;

procedure TKanbanTests.TearDown;
begin
  FreeAndNil(FLog);
  inherited TearDown;
end;

function TKanbanTests.NewBoard: TPPGKanban;
var
  I: Integer;
  C: TPPGKanbanColumn;
begin
  Result := TPPGKanban.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 1080, 640);
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.Font.Name := 'Segoe UI';
  Result.Font.Height := -12;
  Result.OnCardMoving := Moving;
  Result.OnCardMoved := Moved;
  Result.OnCardClick := CardClick;
  Result.OnCardOpen := CardOpen;
  Result.OnChange := SelChange;
  Result.OnColumnCollapse := ColCollapse;
  Result.OnGetCard := GetCard;
  Result.Columns.AddColumn('Backlog');
  C := Result.Columns.AddColumn('In Arbeit', 2);
  C.Color := $0000A5FF;
  Result.Columns.AddColumn('Review');
  Result.Columns.AddColumn('Erledigt');
  for I := 1 to 5 do
    Result.Cards.AddCard(1, 'A' + IntToStr(I));
  Result.Cards.AddCard(2, 'B1').Assignee := 'Anna Berg';
  Result.Cards.AddCard(2, 'B2').Labels := 'Bug, UI';
  Result.Cards.AddCard(4, 'D1').Progress := 100;
  Result.HandleNeeded;
end;

procedure TKanbanTests.Drag(K: TPPGKanban; const A, B: TPoint);
begin
  K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(A.X, A.Y));
  K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(A.X + 10, A.Y + 10));
  K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam((A.X + B.X) div 2, (A.Y + B.Y) div 2));
  K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(B.X, B.Y));
  K.Perform(WM_LBUTTONUP, 0, MakeLParam(B.X, B.Y));
end;

procedure TKanbanTests.Key(K: TPPGKanban; AKey: Word; Shift: TShiftState);
var
  W: Word;
begin
  W := AKey;
  TKanbanAccess(K).KeyDown(W, Shift);
end;

procedure TKanbanTests.Moving(Sender: TObject; const Move: TPPGKanbanMove; var Allow: Boolean);
begin
  FLog.Add(Format('moving:%s>%s:%d>%d', [Move.FromColumn.Title, Move.ToColumn.Title, Move.FromIndex, Move.ToIndex]));
  if FVeto then
    Allow := False;
end;

procedure TKanbanTests.Moved(Sender: TObject; const Move: TPPGKanbanMove);
begin
  FLog.Add(Format('moved:%s>%s:%d>%d', [Move.FromColumn.Title, Move.ToColumn.Title, Move.FromIndex, Move.ToIndex]));
end;

procedure TKanbanTests.CardClick(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer; Card: TPPGKanbanCard);
begin
  FLog.Add('click:' + Card.Title);
end;

procedure TKanbanTests.CardOpen(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer; Card: TPPGKanbanCard);
begin
  if Card <> nil then
    FLog.Add('open:' + Card.Title)
  else
    FLog.Add('open:' + IntToStr(Index));
end;

procedure TKanbanTests.SelChange(Sender: TObject);
begin
  FLog.Add('sel');
end;

procedure TKanbanTests.ColCollapse(Sender: TObject; Column: TPPGKanbanColumn);
begin
  FLog.Add('collapse:' + Column.Title + ':' + System.SysUtils.BoolToStr(Column.Collapsed, True));
end;

procedure TKanbanTests.GetCard(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer;
  var Data: TPPGKanbanCardData);
begin
  Data.Title := 'V' + IntToStr(Index);
end;

function TKanbanTests.HasLog(const Prefix: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to FLog.Count - 1 do
    if Copy(FLog[I], 1, Length(Prefix)) = Prefix then
      Exit(True);
  Result := False;
end;

function TKanbanTests.Titles(K: TPPGKanban; C, L: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to K.CardCount(C, L) - 1 do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + K.CardData(C, L, I).Title;
  end;
end;

procedure TKanbanTests.Shot(K: TPPGKanban; const Name: string);
var
  B: TBitmap;
  Png: TPngImage;
  Dir: string;
begin
  B := RenderToBitmap(K);
  try
    CheckEquals(0, FErrors.Count, 'Fehler beim Zeichnen: ' + FErrors.Text);
    PPGCheckPainted(Self, B, 'Kanban ' + Name); // Audit 11b
    Dir := GetEnvironmentVariable('PPG_SHOTS');
    if Dir <> '' then
    begin
      Png := TPngImage.Create;
      try
        Png.Assign(B);
        Png.SaveToFile(IncludeTrailingPathDelimiter(Dir) + 'kanban-' + Name + '.png');
      finally
        Png.Free;
      end;
    end;
  finally
    B.Free;
  end;
end;

procedure TKanbanTests.CreateFreeAndDefaults;
var
  K: TPPGKanban;
begin
  K := TPPGKanban.Create(nil);
  try
    CheckEquals(272, K.ColumnWidth);
    CheckEquals(8, K.CardGap);
    CheckEquals(3, K.MaxTextLines);
    CheckTrue(K.AllowDrag);
    CheckFalse(K.ReadOnly);
    CheckTrue(K.WipMode = kwmWarn);
    CheckTrue(K.TabStop);
    K.Columns.AddColumn('X');
    CheckEquals(1, K.ColumnCount, 'Layout ohne Parent');
  finally
    K.Free;
  end;
  K := NewBoard;
  CheckEquals(1, K.Columns[0].Id);
  CheckEquals(4, K.Columns[3].Id);
  CheckTrue(K.Cards[0].Id <> K.Cards[1].Id, 'Ids eindeutig');
  try
    K.ColumnWidth := 50;
    Fail('ColumnWidth 50');
  except
    on E: EPPGPropertyError do
      CheckEquals(272, K.ColumnWidth);
  end;
  try
    K.Columns[1].WipLimit := -1;
    Fail('WipLimit -1');
  except
    on E: EPPGPropertyError do
      CheckEquals(2, K.Columns[1].WipLimit);
  end;
  try
    K.Cards[0].Progress := 101;
    Fail('Progress 101');
  except
    on E: EPPGPropertyError do
      CheckEquals(-1, K.Cards[0].Progress);
  end;
end;

procedure TKanbanTests.LayoutColumnsAndCards;
var
  K: TPPGKanban;
  R0, R1: TRect;
  H1, H2: Integer;
begin
  K := NewBoard;
  CheckEquals(4, K.ColumnCount);
  CheckEquals(1, K.LaneCount, 'ohne Swimlanes eine Zelle je Spalte');
  CheckTrue(K.ColumnRect(1).Left > K.ColumnRect(0).Right, 'nebeneinander mit Abstand');
  CheckEquals(5, K.CardCount(0, 0));
  CheckEquals(2, K.CardCount(1, 0));
  CheckEquals(0, K.CardCount(2, 0));
  CheckEquals('A1,A2,A3,A4,A5', Titles(K, 0));
  R0 := K.CardRect(0, 0, 0);
  R1 := K.CardRect(0, 0, 1);
  CheckTrue(R1.Top >= R0.Bottom + 8, 'Abstand CardGap');
  CheckTrue(R0.Left > K.ColumnRect(0).Left);
  CheckTrue(R0.Right < K.ColumnRect(0).Right);
  CheckTrue(R0.Top >= K.HeaderRect(0).Bottom, 'unter dem Kopf');
  // mehr Inhalt = hoehere Karte
  H1 := R0.Bottom - R0.Top;
  K.Cards[0].Text := 'Ein <b>langer</b> Text, der ueber mehrere Zeilen laufen muss, weil die Karte nicht breit genug ist.';
  K.Cards[0].Due := EncodeDate(2026, 10, 9);
  R0 := K.CardRect(0, 0, 0);
  H2 := R0.Bottom - R0.Top;
  CheckTrue(H2 > H1 + 20, Format('hoeher: %d -> %d', [H1, H2]));
  // MaxTextLines begrenzt den Text
  K.Cards[0].Text := K.Cards[0].Text + K.Cards[0].Text + K.Cards[0].Text + K.Cards[0].Text;
  K.MaxTextLines := 2;
  R0 := K.CardRect(0, 0, 0);
  CheckTrue(R0.Bottom - R0.Top < H2 + 10, 'hoechstens zwei Zeilen');
  // Karte ohne bekannte Spalte erscheint nicht
  K.Cards.AddCard(99, 'X');
  CheckEquals(5, K.CardCount(0, 0));
  // WIP
  CheckTrue(K.WipState(1) = kwsFull);
  CheckTrue(K.WipState(0) = kwsNone);
end;

procedure TKanbanTests.HitTestParts;
var
  K: TPPGKanban;
  H: TPPGKanbanHit;
  R: TRect;
begin
  K := NewBoard;
  H := K.HitTest(Center(K.CardRect(0, 0, 2)).X, Center(K.CardRect(0, 0, 2)).Y);
  CheckTrue(H.Part = kpCard);
  CheckEquals(0, H.Col);
  CheckEquals(2, H.Index);
  R := K.HeaderRect(1);
  H := K.HitTest(R.Left + 20, Center(R).Y);
  CheckTrue(H.Part = kpHeader);
  CheckEquals(1, H.Col);
  H := K.HitTest(R.Right - 10, Center(R).Y);
  CheckTrue(H.Part = kpCollapse, 'Einklapp-Knopf rechts');
  R := K.ColumnRect(2);
  H := K.HitTest(Center(R).X, R.Bottom - 40);
  CheckTrue(H.Part = kpCell, 'leere Spalte');
  CheckEquals(2, H.Col);
  H := K.HitTest(K.ColumnRect(0).Right + 5, 300);
  CheckTrue(H.Part = kpNone, 'Luecke zwischen Spalten');
end;

procedure TKanbanTests.ClickSelectsAndEnterOpens;
var
  K: TPPGKanban;
begin
  K := NewBoard;
  K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Center(K.CardRect(1, 0, 1)).X, Center(K.CardRect(1, 0, 1)).Y));
  K.Perform(WM_LBUTTONUP, 0, MakeLParam(Center(K.CardRect(1, 0, 1)).X, Center(K.CardRect(1, 0, 1)).Y));
  CheckEquals('B2', K.SelectedCard.Title);
  CheckEquals('sel', FLog[0]);
  CheckEquals('click:B2', FLog[1]);
  CheckEquals(0, K.Cards[6].ColumnId - 2, 'Klick verschiebt nichts');
  FLog.Clear;
  Key(K, VK_RETURN);
  CheckEquals('open:B2', FLog[0]);
  // Code: ohne Ereignis
  FLog.Clear;
  K.SelectedCard := K.Cards[0];
  CheckEquals('A1', K.SelectedCard.Title);
  CheckEquals(0, FLog.Count);
end;

procedure TKanbanTests.DragWithinColumn;
var
  K: TPPGKanban;
  A, B: TPoint;
begin
  K := NewBoard;
  A := Center(K.CardRect(0, 0, 0));
  B := Point(A.X, K.CardRect(0, 0, 2).Bottom + 2);
  Drag(K, A, B);
  CheckEquals('A2,A3,A1,A4,A5', Titles(K, 0));
  CheckEquals('moving:Backlog>Backlog:0>2', FLog[FLog.Count - 2]);
  CheckEquals('moved:Backlog>Backlog:0>2', FLog[FLog.Count - 1]);
  CheckEquals('A1', K.SelectedCard.Title, 'Auswahl folgt');
  CheckFalse(K.CardDragging);
  // Collection-Reihenfolge entspricht der Spalte
  CheckEquals('A2', K.Cards[0].Title);
  CheckEquals('A1', K.Cards[2].Title);
  // nach oben
  FLog.Clear;
  A := Center(K.CardRect(0, 0, 4));
  B := Point(A.X, K.CardRect(0, 0, 0).Top + 2);
  Drag(K, A, B);
  CheckEquals('A5,A2,A3,A1,A4', Titles(K, 0));
  // Loslassen am Ausgangsort: kein Ereignis
  FLog.Clear;
  A := Center(K.CardRect(0, 0, 1));
  Drag(K, A, Point(A.X + 3, A.Y + 3));
  CheckFalse(HasLog('mov'), 'zurueck an den Ausgangsort: nichts');
end;

procedure TKanbanTests.DragToOtherColumn;
var
  K: TPPGKanban;
  A, B: TPoint;
  C: TPPGKanbanCard;
begin
  K := NewBoard;
  C := K.CardAt(0, 0, 1);
  A := Center(K.CardRect(0, 0, 1));
  B := Point(Center(K.ColumnRect(2)).X, K.HeaderRect(2).Bottom + 30);
  Drag(K, A, B);
  CheckEquals(3, C.ColumnId, 'in Review');
  CheckEquals('A2', Titles(K, 2));
  CheckEquals('A1,A3,A4,A5', Titles(K, 0));
  CheckEquals('moved:Backlog>Review:1>0', FLog[FLog.Count - 1]);
  // zwischen zwei Karten einer anderen Spalte
  A := Center(K.CardRect(3, 0, 0));
  B := Point(Center(K.ColumnRect(1)).X, Center(K.CardRect(1, 0, 0)).Y + 4);
  Drag(K, A, B);
  CheckEquals('B1,D1,B2', Titles(K, 1));
  CheckEquals(0, K.CardCount(3, 0));
end;

procedure TKanbanTests.DragVetoAndWipBlock;
var
  K: TPPGKanban;
  A, B: TPoint;
begin
  K := NewBoard;
  FVeto := True;
  A := Center(K.CardRect(0, 0, 0));
  Drag(K, A, Point(Center(K.ColumnRect(2)).X, K.HeaderRect(2).Bottom + 30));
  CheckEquals(5, K.CardCount(0, 0), 'abgelehnt');
  CheckEquals(0, K.CardCount(2, 0));
  CheckTrue(HasLog('moving'));
  CheckFalse(HasLog('moved'));
  FVeto := False;
  // WIP-Limit sperrt (In Arbeit hat 2 von 2)
  K.WipMode := kwmBlock;
  FLog.Clear;
  B := Point(Center(K.ColumnRect(1)).X, K.CardRect(1, 0, 1).Bottom + 10);
  Drag(K, A, B);
  CheckEquals(2, K.CardCount(1, 0), 'Limit');
  CheckTrue(Pos('In Arbeit', K.Announcement) > 0, K.Announcement);
  // innerhalb der vollen Spalte bleibt Umsortieren erlaubt
  Drag(K, Center(K.CardRect(1, 0, 0)), Point(Center(K.CardRect(1, 0, 0)).X, K.CardRect(1, 0, 1).Bottom + 2));
  CheckEquals('B2,B1', Titles(K, 1));
  // Warnmodus: erlaubt, Spalte ist dann ueber dem Limit
  K.WipMode := kwmWarn;
  Drag(K, A, B);
  CheckEquals(3, K.CardCount(1, 0));
  CheckTrue(K.WipState(1) = kwsOver);
  K.Repaint;
  CheckEquals(0, FErrors.Count);
end;

procedure TKanbanTests.ModelChangeDuringDragAndAssignIds;
var
  K, K2: TPPGKanban;
  A, B, A2: TPoint;
  C, C3: TPPGKanbanCard;
begin
  // Audit 08.10.2026: Eine Modellaenderung (z. B. DB-Reload) waehrend des
  // Ziehens liess die Quelle als alten Index stehen -> falsche Karte
  // verschoben. Cards := X nummerierte die Ids neu.
  K := NewBoard;
  C := K.CardAt(0, 0, 1);
  CheckEquals('A2', C.Title);
  A := Center(K.CardRect(0, 0, 1));
  B := Point(Center(K.ColumnRect(2)).X, K.HeaderRect(2).Bottom + 30);
  K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(A.X, A.Y));
  K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(A.X + 10, A.Y + 10));
  CheckTrue(K.CardDragging, 'Ziehen laeuft');
  K.CardAt(0, 0, 0).Free; // A1 weg: A2 rutscht auf Index 0
  CheckTrue(K.CardDragging, 'Ziehen laeuft weiter');
  K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(B.X, B.Y));
  K.Perform(WM_LBUTTONUP, 0, MakeLParam(B.X, B.Y));
  CheckEquals(3, C.ColumnId, 'A2 (nicht A3) in Review');
  CheckEquals('A3,A4,A5', Titles(K, 0));
  // Gezogene Karte verschwindet: Ziehen endet ohne Verschieben
  C3 := K.CardAt(0, 0, 0);
  A2 := Center(K.CardRect(0, 0, 0));
  K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(A2.X, A2.Y));
  K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(A2.X + 10, A2.Y + 10));
  CheckTrue(K.CardDragging);
  C3.Free;
  CheckFalse(K.CardDragging, 'Ziehen abgebrochen');
  K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(B.X, B.Y));
  K.Perform(WM_LBUTTONUP, 0, MakeLParam(B.X, B.Y));
  CheckEquals('A4,A5', Titles(K, 0));
  CheckEquals('A2', Titles(K, 2));
  // Assign behaelt die Ids
  K2 := NewBoard;
  K2.Cards := K.Cards;
  CheckEquals(K.Cards.Count, K2.Cards.Count);
  CheckEquals(K.Cards[0].Id, K2.Cards[0].Id, 'Id kopiert');
  CheckTrue(K2.Cards[0].Id <> 1, 'nicht neu nummeriert');
  CheckEquals(0, FErrors.Count);
end;

procedure TKanbanTests.EscapeCancelsDrag;
var
  K: TPPGKanban;
  A: TPoint;
begin
  K := NewBoard;
  A := Center(K.CardRect(0, 0, 0));
  K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(A.X, A.Y));
  K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(A.X + 30, A.Y + 120));
  CheckTrue(K.CardDragging);
  CheckTrue(K.DropTarget.Part <> kpNone);
  Key(K, VK_ESCAPE);
  CheckFalse(K.CardDragging);
  K.Perform(WM_LBUTTONUP, 0, MakeLParam(A.X + 30, A.Y + 120));
  CheckEquals('A1,A2,A3,A4,A5', Titles(K, 0));
  CheckFalse(HasLog('mov'), 'kein Verschieben');
end;

procedure TKanbanTests.KeyboardMovesAndAnnounces;
var
  K: TPPGKanban;
  Acc: IPPGAccessibleChildren;
begin
  K := NewBoard;
  Key(K, VK_DOWN);
  CheckEquals('A1', K.SelectedCard.Title, 'erste Karte');
  Key(K, VK_DOWN);
  CheckEquals('A2', K.SelectedCard.Title);
  Key(K, VK_RIGHT);
  CheckEquals('B2', K.SelectedCard.Title, 'gleiche Hoehe in der naechsten Spalte');
  Key(K, VK_RIGHT);
  CheckEquals('D1', K.SelectedCard.Title, 'leere Spalte uebersprungen');
  Key(K, VK_LEFT);
  Key(K, VK_UP);
  CheckEquals('B1', K.SelectedCard.Title);
  // Strg+Pfeile verschieben
  FLog.Clear;
  Key(K, VK_DOWN, [ssCtrl]);
  CheckEquals('B2,B1', Titles(K, 1));
  CheckEquals('B1', K.SelectedCard.Title);
  CheckEquals('moved:In Arbeit>In Arbeit:0>1', FLog[FLog.Count - 1]);
  Key(K, VK_RIGHT, [ssCtrl]);
  CheckEquals('B1', Titles(K, 2), 'in die leere Spalte');
  CheckEquals(Format(PPGStr(@SPPGKanbanMoved), ['Review', 1, 1]), K.Announcement);
  CheckTrue(Supports(K, IPPGAccessibleChildren, Acc));
  CheckTrue(Pos(K.Announcement, Acc.AccChildName(Acc.AccSelectedChild)) = 1, 'Screenreader hoert die Meldung');
  Key(K, VK_LEFT, [ssCtrl]);
  Key(K, VK_LEFT, [ssCtrl]);
  CheckEquals('B1,A1,A2,A3,A4,A5', Titles(K, 0), 'Position bleibt (Index 0)');
  // Home/End
  Key(K, VK_END);
  CheckEquals('A5', K.SelectedCard.Title);
  Key(K, VK_HOME);
  CheckEquals('B1', K.SelectedCard.Title);
end;

procedure TKanbanTests.ColumnScrollsOnItsOwn;
var
  K: TPPGKanban;
  I, Y0: Integer;
  P: TPoint;
begin
  K := NewBoard;
  for I := 6 to 40 do
    K.Cards.AddCard(1, 'A' + IntToStr(I));
  CheckEquals(0, K.ColumnScroll(0));
  Y0 := K.CardRect(0, 0, 0).Top;
  K.ScrollColumn(0, 100);
  CheckEquals(100, K.ColumnScroll(0));
  CheckEquals(Y0 - 100, K.CardRect(0, 0, 0).Top, 'nur diese Spalte');
  CheckEquals(0, K.ColumnScroll(1));
  // Rad ueber der Spalte
  P := K.ClientToScreen(Center(K.ColumnRect(0)));
  TKanbanAccess(K).DoMouseWheel([], -120, P);
  CheckTrue(K.ColumnScroll(0) > 100, 'Rad scrollt die Spalte');
  // letzte Karte holen
  K.MakeCardVisible(0, 0, 39);
  CheckTrue(K.CardRect(0, 0, 39).Bottom <= K.ColumnRect(0).Bottom);
  // Daumen ist treffbar
  CheckTrue(K.HitTest(K.ColumnRect(0).Right - 4, K.ColumnRect(0).Bottom - 20).Part in [kpThumb, kpCard, kpCell]);
  // Tastatur: Ende holt die Karte in den sichtbaren Bereich
  K.ScrollColumn(0, -100000);
  K.Select(0, 0, 0);
  Key(K, VK_END);
  CheckEquals('A40', K.SelectedCard.Title);
  CheckTrue(K.ColumnScroll(0) > 0);
end;

procedure TKanbanTests.VirtualColumn;
var
  K: TPPGKanban;
  V: TPPGKanbanColumn;
  R: TRect;
  H: TPPGKanbanHit;
  T0: Cardinal;
  A: TPoint;
begin
  K := NewBoard;
  V := K.Columns.AddColumn('Archiv');
  V.VirtualCount := 100000;
  CheckEquals(100000, K.CardCount(4, 0));
  CheckNull(K.CardAt(4, 0, 5), 'keine Collection-Karte');
  CheckEquals('V5', K.CardData(4, 0, 5).Title);
  R := K.CardRect(4, 0, 1);
  CheckTrue(R.Top > K.CardRect(4, 0, 0).Bottom, 'feste Hoehe untereinander');
  // weit unten: Lage in O(1)
  K.ScrollColumn(4, 50000 * (R.Top - K.CardRect(4, 0, 0).Top));
  T0 := GetTickCount;
  K.ScrollBy(10000, 0);
  K.Repaint;
  H := K.HitTest(Center(K.ColumnRect(4)).X, K.ColumnRect(4).Top + 200);
  CheckTrue(H.Part = kpCard);
  CheckTrue(H.Index > 49000, IntToStr(H.Index));
  CheckTrue(GetTickCount - T0 < 1000);
  // Ziehen in der virtuellen Spalte meldet nur (die Anwendung verschiebt)
  FLog.Clear;
  A := Center(K.CardRect(4, 0, H.Index));
  Drag(K, A, Point(A.X, A.Y + 3 * (R.Bottom - R.Top + 8)));
  CheckEquals(Format('moved:Archiv>Archiv:%d>%d', [H.Index, H.Index + 2]), FLog[FLog.Count - 1]);
  // in eine normale Spalte nicht
  CheckFalse(K.MoveCard(4, 0, 0, 0, 0, 0));
  CheckFalse(K.MoveCard(0, 0, 0, 4, 0, 0));
end;

procedure TKanbanTests.SwimlanesCellsAndMoves;
var
  K: TPPGKanban;
  R: TRect;
begin
  K := NewBoard;
  K.Lanes.AddLane('Anna');
  K.Lanes.AddLane('Ben');
  K.Cards[0].LaneId := 1;
  K.Cards[1].LaneId := 2;
  K.Cards[2].LaneId := 2;
  CheckEquals(2, K.LaneCount);
  // Karten ohne Swimlane landen in der ersten
  CheckEquals('A1,A4,A5', Titles(K, 0, 0));
  CheckEquals('A2,A3', Titles(K, 0, 1));
  R := K.LaneHeaderRect(1);
  CheckFalse(IsRectEmpty(R));
  CheckTrue(R.Top >= K.CardRect(0, 0, 2).Bottom, 'zweite Swimlane darunter');
  CheckTrue(K.CardRect(0, 1, 0).Top > R.Bottom - 1);
  // Strg+Unten am Ende der Zelle: in die naechste Swimlane
  K.Select(0, 0, 2);
  Key(K, VK_DOWN, [ssCtrl]);
  CheckEquals('A5,A2,A3', Titles(K, 0, 1));
  CheckEquals(2, K.Cards.FindById(5).LaneId);
  // Ziehen in eine andere Swimlane und Spalte
  Drag(K, Center(K.CardRect(0, 0, 0)), Point(Center(K.ColumnRect(2)).X, K.CardRect(0, 1, 0).Top + 4));
  CheckEquals('A1', Titles(K, 2, 1));
  CheckEquals(2, K.Cards.FindById(1).LaneId);
  // Swimlane einklappen
  K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Center(K.LaneHeaderRect(1)).X, Center(K.LaneHeaderRect(1)).Y));
  K.Perform(WM_LBUTTONUP, 0, MakeLParam(Center(K.LaneHeaderRect(1)).X, Center(K.LaneHeaderRect(1)).Y));
  CheckTrue(K.Lanes[1].Collapsed);
  CheckTrue(IsRectEmpty(K.CardRect(0, 1, 0)), 'Karten verborgen');
  K.Repaint;
  CheckEquals(0, FErrors.Count);
end;

procedure TKanbanTests.CollapseColumns;
var
  K: TPPGKanban;
  W: Integer;
  R: TRect;
begin
  K := NewBoard;
  W := K.ColumnRect(2).Right - K.ColumnRect(2).Left;
  R := K.HeaderRect(2);
  K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(R.Right - 10, Center(R).Y));
  K.Perform(WM_LBUTTONUP, 0, MakeLParam(R.Right - 10, Center(R).Y));
  CheckTrue(K.Columns[2].Collapsed);
  CheckEquals('collapse:Review:True', FLog[FLog.Count - 1]);
  CheckTrue(K.ColumnRect(2).Right - K.ColumnRect(2).Left < W div 3, 'schmal');
  // Ablegen auf der eingeklappten Spalte: ans Ende
  Drag(K, Center(K.CardRect(0, 0, 0)), Center(K.ColumnRect(2)));
  CheckEquals('A1', Titles(K, 2));
  CheckTrue(IsRectEmpty(K.CardRect(2, 0, 0)), 'eingeklappt unsichtbar');
  // Klick klappt wieder auf
  R := K.ColumnRect(2);
  K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Center(R).X, Center(R).Y));
  K.Perform(WM_LBUTTONUP, 0, MakeLParam(Center(R).X, Center(R).Y));
  CheckFalse(K.Columns[2].Collapsed);
  // Code: ohne Ereignis
  FLog.Clear;
  K.Columns[3].Collapsed := True;
  CheckEquals(0, FLog.Count);
end;

procedure TKanbanTests.AccessibleChildren;
var
  K: TPPGKanban;
  Acc: IPPGAccessibleChildren;
  Id: Integer;
begin
  K := NewBoard;
  CheckTrue(Supports(K, IPPGAccessibleChildren, Acc));
  CheckEquals(4 + 8, Acc.AccChildCount, 'Koepfe und Karten');
  CheckEquals(ROLE_SYSTEM_COLUMNHEADER, Acc.AccChildRole(1));
  CheckTrue(Pos('Backlog', Acc.AccChildName(1)) > 0);
  CheckEquals(ROLE_SYSTEM_LISTITEM, Acc.AccChildRole(2));
  CheckEquals(Format(PPGStr(@SPPGKanbanAccCard), ['A1', 'Backlog', 1, 5]), Acc.AccChildName(2));
  Id := Acc.AccChildAt(Center(K.CardRect(1, 0, 0)).X, Center(K.CardRect(1, 0, 0)).Y);
  CheckTrue(Pos('B1', Acc.AccChildName(Id)) = 1);
  CheckTrue(Pos('Anna Berg', Acc.AccChildName(Id)) > 0, 'Person');
  CheckTrue(Pos('2', Acc.AccChildName(Id - 1)) > 0, 'Kopf der Spalte mit Limit');
  CheckTrue(Acc.AccChildState(Id) and STATE_SYSTEM_MOVEABLE <> 0);
  Acc.AccChildDoDefault(Id);
  CheckNull(K.SelectedCard, 'gepostet');
  Application.ProcessMessages;
  CheckEquals('B1', K.SelectedCard.Title);
  CheckEquals(Id, Acc.AccSelectedChild);
end;

procedure TKanbanTests.StreamingRoundTrip;
var
  K, Q: TPPGKanban;
  M: TMemoryStream;
begin
  K := NewBoard;
  K.Lanes.AddLane('Team').Key := 'team';
  K.Columns[1].Key := 'doing';
  K.Columns[2].Collapsed := True;
  K.Cards[5].Due := EncodeDate(2026, 10, 12);
  K.Cards[5].Text := '<b>wichtig</b>';
  K.Cards[5].Color := clRed;
  K.ColumnWidth := 300;
  K.WipMode := kwmBlock;
  M := TMemoryStream.Create;
  try
    M.WriteComponent(K);
    M.Position := 0;
    Q := TPPGKanban(M.ReadComponent(nil));
    try
      CheckEquals(4, Q.Columns.Count);
      CheckEquals('In Arbeit', Q.Columns[1].Title);
      CheckEquals(2, Q.Columns[1].WipLimit);
      CheckEquals('doing', Q.Columns[1].Key);
      CheckEquals($0000A5FF, Q.Columns[1].Color);
      CheckTrue(Q.Columns[2].Collapsed);
      CheckEquals(1, Q.Lanes.Count);
      CheckEquals('team', Q.Lanes[0].Key);
      CheckEquals(8, Q.Cards.Count);
      CheckEquals(K.Cards[5].Id, Q.Cards[5].Id);
      CheckEquals('Anna Berg', Q.Cards[5].Assignee);
      CheckEquals('<b>wichtig</b>', Q.Cards[5].Text);
      CheckEquals(EncodeDate(2026, 10, 12), Q.Cards[5].Due, 1E-9);
      CheckEquals(clRed, Q.Cards[5].Color);
      CheckEquals('Bug, UI', Q.Cards[6].Labels);
      CheckEquals(100, Q.Cards[7].Progress);
      CheckEquals(300, Q.ColumnWidth);
      CheckTrue(Q.WipMode = kwmBlock);
      CheckEquals(K.Cards[7].Id + 1, Q.Cards.Add.Id, 'Ids laufen weiter');
      CheckEquals(5, Q.Columns.Add.Id);
    finally
      Q.Free;
    end;
  finally
    M.Free;
  end;
end;

procedure TKanbanTests.RightToLeftMirrors;
var
  K: TPPGKanban;
begin
  K := NewBoard;
  K.BiDiMode := bdRightToLeft;
  CheckTrue(K.ColumnRect(0).Left > K.ColumnRect(1).Right, 'erste Spalte rechts');
  CheckTrue(K.HitTest(Center(K.CardRect(0, 0, 1)).X, Center(K.CardRect(0, 0, 1)).Y).Index = 1);
  Drag(K, Center(K.CardRect(0, 0, 0)), Point(Center(K.ColumnRect(2)).X, K.HeaderRect(2).Bottom + 30));
  CheckEquals('A1', Titles(K, 2));
  Key(K, VK_LEFT);
  CheckEquals('D1', K.SelectedCard.Title, 'links = naechste Spalte bei RTL');
  Shot(K, 'rtl');
end;

{ Audit 11b: Pixel, die sich innerhalb von R zwischen A und B deutlich
  unterscheiden (Summe RGB > 40). }
function RegionDiff(A, B: TBitmap; const R: TRect): Integer;
var
  X, Y: Integer;
  PA, PB: PByteArray;
begin
  Result := 0;
  A.PixelFormat := pf24bit;
  B.PixelFormat := pf24bit;
  for Y := Max(R.Top, 0) to Min(R.Bottom, Min(A.Height, B.Height)) - 1 do
  begin
    PA := A.ScanLine[Y];
    PB := B.ScanLine[Y];
    for X := Max(R.Left, 0) to Min(R.Right, Min(A.Width, B.Width)) - 1 do
      if Abs(PA[X * 3] - PB[X * 3]) + Abs(PA[X * 3 + 1] - PB[X * 3 + 1]) +
        Abs(PA[X * 3 + 2] - PB[X * 3 + 2]) > 40 then
        Inc(Result);
  end;
end;

{ Luminanz 0..1 eines Pixels }
function PixelLuma(B: TBitmap; X, Y: Integer): Double;
var
  P: PByteArray;
begin
  B.PixelFormat := pf24bit;
  P := B.ScanLine[Y];
  Result := (0.2126 * P[X * 3 + 2] + 0.7152 * P[X * 3 + 1] + 0.0722 * P[X * 3]) / 255;
end;

procedure TKanbanTests.PaintsAllStates;
var
  K: TPPGKanban;
  Light, Drag, Dark, Normal, Disabled: TBitmap;
  Col1, Empty0: TRect;
begin
  Light := nil;
  Drag := nil;
  Dark := nil;
  Normal := nil;
  Disabled := nil;
  try
    K := NewBoard;
    K.Cards[0].Text := 'Mit <b>Markup</b> und <i>mehr</i> Text, damit die Karte waechst.';
    K.Cards[0].Labels := 'Feature, Frontend';
    K.Cards[0].Due := Date - 1;
    K.Cards[0].Assignee := 'Ben Kraus';
    K.Cards[0].Progress := 40;
    K.Cards[1].Color := $0050A0E0;
    K.Cards.AddCard(2, 'B3');
    K.Select(0, 0, 0);
    K.Perform(WM_MOUSEMOVE, 0, MakeLParam(Center(K.CardRect(0, 0, 1)).X, Center(K.CardRect(0, 0, 1)).Y));
    Shot(K, 'light');
    Light := RenderToBitmap(K);
    PPGCheckPainted(Self, Light, 'hell');
    // waehrend des Ziehens (Platzhalter und Karte an der Maus)
    K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Center(K.CardRect(0, 0, 2)).X, Center(K.CardRect(0, 0, 2)).Y));
    K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(Center(K.ColumnRect(1)).X, K.CardRect(1, 0, 1).Top + 4));
    Shot(K, 'drag');
    Drag := RenderToBitmap(K);
    // Pixelprobe: in der Zielspalte erscheint der Platzhalter (und die Karte an der Maus)
    Col1 := K.ColumnRect(1);
    CheckTrue(RegionDiff(Light, Drag, Col1) >= 200,
      Format('Ziehen: Zielspalte unveraendert (%d Pixel)', [RegionDiff(Light, Drag, Col1)]));
    Key(K, VK_ESCAPE);
    K.Perform(WM_LBUTTONUP, 0, 0);
    K.Columns[2].Collapsed := True;
    K.Lanes.AddLane('Anna');
    K.Lanes.AddLane('Ben');
    K.Cards[3].LaneId := 2;
    Shot(K, 'lanes');
    K.Lanes.Clear;
    K.Preset := 'Classic';
    Shot(K, 'classic');
    K.Preset := 'Fluent11';
    FreeAndNil(Light);
    Light := RenderToBitmap(K);
    TPPGTheme.Mode := tmDark;
    try
      Shot(K, 'dark');
      Dark := RenderToBitmap(K);
    finally
      TPPGTheme.Mode := tmLight;
    end;
    // Dunkel anders als hell; Probe unten in der ersten Spalte (leere Spaltenflaeche):
    // dunkel dunkler Grund, hell heller Grund
    PPGCheckDiffers(Self, Light, Dark, 'Dunkel gegen hell');
    Empty0 := K.ColumnRect(0);
    CheckTrue(PixelLuma(Dark, Center(Empty0).X, Empty0.Bottom - 6) < 0.35, 'dunkel: Spaltengrund dunkel');
    CheckTrue(PixelLuma(Light, Center(Empty0).X, Empty0.Bottom - 6) > 0.6, 'hell: Spaltengrund hell');
    TPPGRendererRegistry.ForceGdiFallback := True;
    Shot(K, 'gdi');
    Normal := RenderToBitmap(K);
    PPGCheckPainted(Self, Normal, 'GDI');
    TPPGRendererRegistry.ForceGdiFallback := False;
    FreeAndNil(Normal);
    Normal := RenderToBitmap(K);
    K.Enabled := False;
    Shot(K, 'disabled');
    Disabled := RenderToBitmap(K);
    PPGCheckDiffers(Self, Normal, Disabled, 'Deaktiviert');
  finally
    Light.Free;
    Drag.Free;
    Dark.Free;
    Normal.Free;
    Disabled.Free;
  end;
end;

procedure TKanbanTests.ManyCardsStayFast;
var
  K: TPPGKanban;
  I: Integer;
  T0: Cardinal;
begin
  K := NewBoard;
  K.Cards.BeginUpdate;
  try
    for I := 1 to 5000 do
      with K.Cards.AddCard(1 + I mod 4, 'Aufgabe ' + IntToStr(I), 'Beschreibung <b>' + IntToStr(I) + '</b>') do
      begin
        Labels := 'L' + IntToStr(I mod 7);
        Assignee := 'Person ' + IntToStr(I mod 5);
      end;
  finally
    K.Cards.EndUpdate;
  end;
  T0 := GetTickCount;
  K.EnsureLayout;
  CheckTrue(K.CardCount(0, 0) > 1000);
  for I := 0 to 99 do
  begin
    K.ScrollColumn(0, 400);
    K.Repaint;
  end;
  T0 := GetTickCount - T0;
  CheckTrue(T0 < 5000, Format('5000 Karten: Layout + 100 x scrollen und zeichnen %d ms', [T0]));
  Status(Format('Kanban 5000 Karten: Layout + 100 x scrollen und zeichnen %d ms', [T0]));
end;

initialization
  RegisterClass(TPPGKanban);
  RegisterTest('Phase14c', TKanbanTests.Suite);

end.
