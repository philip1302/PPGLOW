unit DemoPages9;

{ Demo-Seite "Kanban" (Phase 14c): Aufgaben-Board mit WIP-Limits, Plaketten,
  Faelligkeit, Personen und Fortschritt; Swimlanes nach Person zuschaltbar,
  WIP-Limit wahlweise sperrend. Ziehen mit der Maus oder Strg+Pfeile.
  Phase 20b: Suche und Personenfilter (FilterText/FilterAssignee, Kopf zeigt
  "+n" ausgeblendete), Spalten am Kopf ziehen oder Strg+Umschalt+Pfeile. }

interface

uses
  System.SysUtils, System.Classes, System.Types, System.DateUtils, Vcl.Controls, Vcl.Graphics,
  Vcl.StdCtrls, PPG.Types, PPG.Panel, PPG.Labels, PPG.Button, PPG.ToggleSwitch,
  PPG.ComboBox, PPG.SearchEdit,
  PPG.Kanban.Layout, PPG.Kanban.Items, PPG.Kanban,
  DemoKit;

type
  TDemoKanbanPage = class(TDemoPage)
  private
    FBoard: TPPGKanban;
    FLanes: TPPGToggleSwitch;
    FBlock: TPPGToggleSwitch;
    FSearch: TPPGSearchEdit;
    FPerson: TPPGComboBox;
    FResult: TPPGLabel;
    FNewCount: Integer;
    procedure FillBoard;
    procedure LanesChange(Sender: TObject);
    procedure BlockChange(Sender: TObject);
    procedure NewCardClick(Sender: TObject);
    procedure Moving(Sender: TObject; const Move: TPPGKanbanMove; var Allow: Boolean);
    procedure Moved(Sender: TObject; const Move: TPPGKanbanMove);
    procedure CardOpen(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer; Card: TPPGKanbanCard);
    procedure ColumnCollapse(Sender: TObject; Column: TPPGKanbanColumn);
    procedure ColumnMoved(Sender: TObject; Column: TPPGKanbanColumn);
    procedure FilterChange(Sender: TObject);
    function HiddenTotal: Integer;
  protected
    procedure Build; override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

const
  FullW = 2 * 484 + CardGap;
  CardH = 640;

function IfThenStr(B: Boolean; const T, F: string): string;
begin
  if B then
    Result := T
  else
    Result := F;
end;

procedure TDemoKanbanPage.Build;
var
  Card: TPPGPanel;
  X: Integer;
begin
  NewPageHeader(Own, Sheet, 'Kanban', L('TPPGKanban: Spalten mit WIP-Limit, Karten mit Markup, Plaketten, ') +
    L('F{ae}lligkeit, Person und Fortschritt. Karten ziehen oder mit Strg+Pfeilen verschieben; ') +
    L('Spalten am Kopf ziehen (Strg+Umschalt+Pfeile) oder einklappen. Suche und Person filtern.'));
  Card := NewCard(Own, Sheet, PageX, PageContentTop, FullW, CardH, 'Aufgaben',
    L('Jede Spalte scrollt f{ue}r sich (Mausrad). "In Arbeit" erlaubt drei, "Review" zwei Karten; ') +
    L('dar{ue}ber f{ae}rbt sich die Spalte rot oder lehnt ab ("WIP-Limit sperrt").'));
  X := CardPad;
  FLanes := TPPGToggleSwitch.Create(Own);
  FLanes.Parent := Card;
  FLanes.SetBounds(X, Card.Tag, 210, CtlH);
  FLanes.Caption := 'Swimlanes nach Person';
  FLanes.OnChange := LanesChange;
  Inc(X, 226);
  FBlock := TPPGToggleSwitch.Create(Own);
  FBlock.Parent := Card;
  FBlock.SetBounds(X, Card.Tag, 180, CtlH);
  FBlock.Caption := 'WIP-Limit sperrt';
  FBlock.OnChange := BlockChange;
  Inc(X, 196);
  NewButton(Own, Card, X, Card.Tag, 140, 'Neue Karte', NewCardClick, True);
  Inc(X, 152);
  FSearch := TPPGSearchEdit.Create(Own);
  FSearch.Parent := Card;
  FSearch.SetBounds(X, Card.Tag, 200, CtlH);
  FSearch.TextHint := 'Karten suchen';
  FSearch.OnChange := FilterChange;
  Inc(X, 208);
  FPerson := TPPGComboBox.Create(Own);
  FPerson.Parent := Card;
  FPerson.Style := csDropDownList;
  FPerson.SetBounds(X, Card.Tag, FullW - CardPad - X, CtlH);
  FPerson.Items.CommaText := '"Alle Personen","Anna Berg","Ben Kraus","Clara Diaz"';
  FPerson.ItemIndex := 0;
  FPerson.OnChange := FilterChange;
  FBoard := TPPGKanban.Create(Own);
  FBoard.Parent := Card;
  FBoard.SetBounds(CardPad, Card.Tag + CtlH + 12, FullW - 2 * CardPad, CardH - (Card.Tag + CtlH + 12) - 52);
  FBoard.Anchors := [akLeft, akTop, akRight, akBottom];
  FBoard.ColumnWidth := 220;
  FBoard.OnCardMoving := Moving;
  FBoard.OnCardMoved := Moved;
  FBoard.OnCardOpen := CardOpen;
  FBoard.OnColumnCollapse := ColumnCollapse;
  FBoard.OnColumnMoved := ColumnMoved;
  FillBoard;
  FResult := NewResult(Own, Card, 'Letzte Aktion');
  Host.RegisterSpecial('kanban', FBoard);
end;

procedure TDemoKanbanPage.FillBoard;
var
  B, W, R, D: TPPGKanbanColumn;

  procedure Add(Col: TPPGKanbanColumn; const ATitle, AText, ALabels, AWho: string; ADue, AProgress: Integer;
    AColor: TColor = clNone);
  begin
    with FBoard.Cards.AddCard(Col.Id, L(ATitle), L(AText)) do
    begin
      Labels := ALabels;
      Assignee := AWho;
      if ADue <> 0 then
        Due := Date + ADue;
      Progress := AProgress;
      Color := AColor;
    end;
  end;

begin
  FBoard.Cards.BeginUpdate;
  try
    B := FBoard.Columns.AddColumn('Backlog');
    W := FBoard.Columns.AddColumn('In Arbeit', 3);
    W.Color := $0000A5FF;
    R := FBoard.Columns.AddColumn('Review', 2);
    R.Color := $00B05A8E;
    D := FBoard.Columns.AddColumn('Erledigt');
    D.Color := $0032A852;
    Add(B, 'Kanban-Seite in der Demo', 'Spalten, Swimlanes und <b>Ziehen</b> zeigen.', 'Demo', 'Anna Berg', 5, -1);
    Add(B, 'Druck des Boards', 'Eine Seite je Spalte, wie beim Planer.', 'Idee', '', 0, -1);
    Add(B, 'Export als CSV', '', 'Feature', 'Ben Kraus', 12, -1);
    Add(B, 'Kartenvorlagen', 'Neue Karte mit <i>Checkliste</i> anlegen.', 'Idee, UX', '', 0, -1);
    Add(B, 'Filter nach Label', '', 'Feature', 'Clara Diaz', 9, -1);
    Add(W, 'Ziehen mit Platzhalter', 'Die anderen Karten weichen <b>animiert</b> aus.', 'Feature, UI', 'Anna Berg',
      1, 60, $0000A5FF);
    Add(W, 'WIP-Limit pr{ue}fen', 'Warnfarbe oder Abbruch in <i>OnCardMoving</i>.', 'Feature', 'Ben Kraus', 2, 30);
    Add(W, 'Screenreader-Ansage', '"Verschoben nach Spalte X, Position Y".', 'A11y', 'Clara Diaz', -1, 80);
    Add(R, 'Virtuelle Spalten', '100 000 Karten, nur Sichtbares wird gezeichnet.', 'Leistung', 'Ben Kraus', 0, 100);
    Add(D, 'Modell und Layout', 'Reine Funktionen, ohne Fenster getestet.', 'Kern', 'Anna Berg', -3, 100);
    Add(D, 'DB-Variante', '<b>ColumnField</b> und <b>OrderField</b>.', 'DB', 'Clara Diaz', -2, 100);
    FBoard.Lanes.AddLane('Anna Berg').Visible := False;
    FBoard.Lanes.AddLane('Ben Kraus').Visible := False;
    FBoard.Lanes.AddLane('Clara Diaz').Visible := False;
    FBoard.Lanes.AddLane('Ohne Person').Visible := False;
  finally
    FBoard.Cards.EndUpdate;
  end;
end;

procedure TDemoKanbanPage.LanesChange(Sender: TObject);
var
  I, J, Lane: Integer;
begin
  // Swimlane je Person: LaneId aus dem Namen der Person
  for I := 0 to FBoard.Lanes.Count - 1 do
    FBoard.Lanes[I].Visible := FLanes.Checked;
  if FLanes.Checked then
  begin
    FBoard.Cards.BeginUpdate;
    try
      for I := 0 to FBoard.Cards.Count - 1 do
      begin
        Lane := FBoard.Lanes[FBoard.Lanes.Count - 1].Id;
        for J := 0 to FBoard.Lanes.Count - 2 do
          if FBoard.Lanes[J].Title = FBoard.Cards[I].Assignee then
            Lane := FBoard.Lanes[J].Id;
        FBoard.Cards[I].LaneId := Lane;
      end;
    finally
      FBoard.Cards.EndUpdate;
    end;
  end;
  SetResult(FResult, 'Swimlanes ' + IfThenStr(FLanes.Checked, 'an', 'aus'));
end;

procedure TDemoKanbanPage.BlockChange(Sender: TObject);
begin
  if FBlock.Checked then
    FBoard.WipMode := kwmBlock
  else
    FBoard.WipMode := kwmWarn;
  SetResult(FResult, 'WIP-Limit ' + IfThenStr(FBlock.Checked, 'sperrt', 'warnt nur'));
end;

procedure TDemoKanbanPage.NewCardClick(Sender: TObject);
var
  C: TPPGKanbanCard;
begin
  Inc(FNewCount);
  C := FBoard.Cards.AddCard(FBoard.Columns[0].Id, 'Neue Aufgabe ' + IntToStr(FNewCount), '');
  if FLanes.Checked then
    C.LaneId := FBoard.Lanes[FBoard.Lanes.Count - 1].Id;
  FBoard.SelectedCard := C;
  SetResult(FResult, 'Karte angelegt (Backlog)');
end;

procedure TDemoKanbanPage.Moving(Sender: TObject; const Move: TPPGKanbanMove; var Allow: Boolean);
begin
  if not Allow then
    SetResult(FResult, '"' + Move.ToColumn.Title + '" ist voll {-} abgelehnt');
end;

procedure TDemoKanbanPage.Moved(Sender: TObject; const Move: TPPGKanbanMove);
var
  S: string;
begin
  S := '"' + Move.Card.Title + '" {>} ' + Move.ToColumn.Title +
    ', Position ' + IntToStr(Move.ToIndex + 1);
  if Move.ByKeyboard then
    S := S + ' (Tastatur)';
  SetResult(FResult, S);
  Host.Log('Kanban', L(S));
end;

procedure TDemoKanbanPage.CardOpen(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer; Card: TPPGKanbanCard);
begin
  if Card <> nil then
    SetResult(FResult, 'Karte ge{oe}ffnet: ' + Card.Title);
end;

procedure TDemoKanbanPage.ColumnCollapse(Sender: TObject; Column: TPPGKanbanColumn);
begin
  SetResult(FResult, 'Spalte "' + Column.Title + '" ' + IfThenStr(Column.Collapsed, 'eingeklappt', 'aufgeklappt'));
end;

procedure TDemoKanbanPage.ColumnMoved(Sender: TObject; Column: TPPGKanbanColumn);
begin
  SetResult(FResult, 'Spalte "' + Column.Title + '" an Position ' + IntToStr(Column.Index + 1));
  Host.Log('Kanban', 'Spalte verschoben: ' + Column.Title);
end;

function TDemoKanbanPage.HiddenTotal: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FBoard.ColumnCount - 1 do
    Inc(Result, FBoard.ColumnHiddenCount(I));
end;

procedure TDemoKanbanPage.FilterChange(Sender: TObject);
begin
  FBoard.FilterText := FSearch.Text;
  if FPerson.ItemIndex > 0 then
    FBoard.FilterAssignee := FPerson.Text
  else
    FBoard.FilterAssignee := '';
  if FBoard.IsFiltered then
    SetResult(FResult, Format('Filter: %d Karten ausgeblendet', [HiddenTotal]))
  else
    SetResult(FResult, 'Filter aus');
end;

procedure TDemoKanbanPage.SelfTest(Check: TDemoCheck);
var
  N: Integer;
  Col: TPPGKanbanColumn;
begin
  FBoard.EnsureLayout;
  Check('Kanban: vier Spalten', FBoard.ColumnCount = 4);
  Check('Kanban: elf Karten', FBoard.Cards.Count = 11);
  Check('Kanban: In Arbeit 3 von 3', FBoard.WipState(1) = kwsFull);
  // Verschieben wie per Tastatur (Backlog -> Review)
  N := FBoard.CardCount(2, 0);
  Check('Kanban: verschoben', FBoard.MoveCard(0, 0, 0, 2, 0, 0, True));
  Check('Kanban: Review hat eine Karte mehr', FBoard.CardCount(2, 0) = N + 1);
  Check('Kanban: Ansage', Pos('Review', FBoard.Announcement) > 0);
  // Sperrmodus: Review ist mit 2 voll
  FBlock.Checked := True; // OnChange schaltet WipMode
  Check('Kanban: voll, abgelehnt', not FBoard.MoveCard(0, 0, 0, 2, 0, 0, True));
  FBlock.Checked := False;
  // zurueck
  FBoard.MoveCard(2, 0, 0, 0, 0, 0, True);
  // Swimlanes
  FLanes.Checked := True;
  Check('Kanban: vier Swimlanes', FBoard.LaneCount = 4);
  Check('Kanban: Anna hat Karten in Backlog', FBoard.CardCount(0, 0) >= 1);
  FLanes.Checked := False;
  Check('Kanban: ohne Swimlanes', FBoard.LaneCount = 1);
  // Neue Karte
  NewCardClick(nil);
  Check('Kanban: neue Karte gewaehlt', (FBoard.SelectedCard <> nil) and (FBoard.Cards.Count = 12));
  FBoard.Cards.Delete(FBoard.Cards.Count - 1);
  Dec(FNewCount);
  // Filter (Phase 20b)
  FSearch.Text := 'Druck';
  FilterChange(nil);
  Check('Kanban: Suche filtert', FBoard.IsFiltered and (HiddenTotal = 10));
  FSearch.Text := '';
  FPerson.ItemIndex := 2; // Ben Kraus
  FilterChange(nil);
  Check('Kanban: Personenfilter', HiddenTotal = 8);
  FPerson.ItemIndex := 0;
  FilterChange(nil);
  Check('Kanban: Filter aus', not FBoard.IsFiltered and (HiddenTotal = 0));
  // Spalten verschieben und zurueck
  Col := FBoard.Columns[3];
  Check('Kanban: Spalte verschoben', FBoard.MoveColumn(3, 0) and (FBoard.Columns[0] = Col));
  FBoard.MoveColumn(0, 4); // 4 = hinter die letzte Spalte (Einfuegen davor)
  Check('Kanban: Spalte zurueck', FBoard.Columns[3] = Col);
end;

end.
