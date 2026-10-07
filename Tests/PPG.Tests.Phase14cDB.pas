unit PPG.Tests.Phase14cDB;

{ Tests fuer Phase 14c: TPPGDBKanban (PPG.DB.Kanban) auf einem TClientDataSet. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Variants, Vcl.Controls, Vcl.Forms,
  Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Kanban.Items, PPG.Kanban, PPG.DB.Kanban, PPG.Tests.Controls;

type
  TDBKanbanTests = class(TControlTestCase)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    procedure AddRow(AId: Integer; const AStatus: string; AOrder: Integer; const ATitle: string;
      const ALane: string = '');
    function NewBoard: TPPGDBKanban;
    function Titles(K: TPPGCustomKanban; C: Integer; L: Integer = 0): string;
    function OrderOf(AId: Integer): Integer;
    function StatusOf(AId: Integer): string;
  protected
    procedure SetUp; override;
  published
    procedure LoadsRecordsSortedByOrder;
    procedure MoveWritesColumnAndOrder;
    procedure ReorderRenumbersCell;
    procedure LanesFromField;
    procedure ExternalChangeReloads;
    procedure SelectionMovesRecord;
    procedure WithoutKeyIsReadOnly;
    procedure ClosedDataSetClears;
  end;

implementation

function Center(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

procedure TDBKanbanTests.SetUp;
begin
  inherited SetUp;
  FForm.SetBounds(0, 0, 1100, 700);
  FData := TClientDataSet.Create(FForm);
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Status', ftString, 20);
  FData.FieldDefs.Add('Reihe', ftInteger);
  FData.FieldDefs.Add('Titel', ftString, 80);
  FData.FieldDefs.Add('Text', ftString, 200);
  FData.FieldDefs.Add('Person', ftString, 40);
  FData.FieldDefs.Add('Faellig', ftDate);
  FData.FieldDefs.Add('Team', ftString, 20);
  FData.CreateDataSet;
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
end;

procedure TDBKanbanTests.AddRow(AId: Integer; const AStatus: string; AOrder: Integer; const ATitle,
  ALane: string);
begin
  FData.Append;
  FData.FieldByName('ID').AsInteger := AId;
  FData.FieldByName('Status').AsString := AStatus;
  FData.FieldByName('Reihe').AsInteger := AOrder;
  FData.FieldByName('Titel').AsString := ATitle;
  if ALane <> '' then
    FData.FieldByName('Team').AsString := ALane;
  FData.Post;
end;

function TDBKanbanTests.NewBoard: TPPGDBKanban;
begin
  Result := TPPGDBKanban.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 1080, 640);
  Result.Animation.Enabled := False;
  Result.ReloadDelay := 0;
  Result.Columns.AddColumn('Offen').Key := 'todo';
  Result.Columns.AddColumn('In Arbeit').Key := 'doing';
  Result.Columns.AddColumn('Fertig').Key := 'done';
  Result.KeyField := 'ID';
  Result.ColumnField := 'Status';
  Result.OrderField := 'Reihe';
  Result.TitleField := 'Titel';
  Result.TextField := 'Text';
  Result.AssigneeField := 'Person';
  Result.DueField := 'Faellig';
  Result.DataSource := FSource;
  Result.HandleNeeded;
end;

function TDBKanbanTests.Titles(K: TPPGCustomKanban; C, L: Integer): string;
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

function TDBKanbanTests.OrderOf(AId: Integer): Integer;
begin
  CheckTrue(FData.Locate('ID', AId, []));
  Result := FData.FieldByName('Reihe').AsInteger;
end;

function TDBKanbanTests.StatusOf(AId: Integer): string;
begin
  CheckTrue(FData.Locate('ID', AId, []));
  Result := FData.FieldByName('Status').AsString;
end;

procedure TDBKanbanTests.LoadsRecordsSortedByOrder;
var
  K: TPPGDBKanban;
begin
  AddRow(1, 'todo', 30, 'C');
  AddRow(2, 'todo', 10, 'A');
  AddRow(3, 'doing', 10, 'X');
  AddRow(4, 'todo', 20, 'B');
  AddRow(5, 'unbekannt', 10, 'Z');
  K := NewBoard;
  CheckEquals(5, K.LoadedCount);
  CheckEquals('A,B,C', Titles(K, 0), 'nach Reihe sortiert');
  CheckEquals('X', Titles(K, 1));
  CheckEquals(0, K.CardCount(2, 0));
  CheckEquals(5, K.Cards.Count, 'Karte ohne Spalte bleibt im Modell');
  CheckEquals(2, K.CardAt(0, 0, 0).Id, 'Id = Schluessel');
end;

procedure TDBKanbanTests.MoveWritesColumnAndOrder;
var
  K: TPPGDBKanban;
begin
  AddRow(1, 'todo', 10, 'A');
  AddRow(2, 'todo', 20, 'B');
  AddRow(3, 'doing', 10, 'X');
  K := NewBoard;
  CheckTrue(K.MoveCard(0, 0, 0, 1, 0, 1));
  CheckEquals('doing', StatusOf(1));
  CheckEquals('X,A', Titles(K, 1));
  CheckEquals(10, OrderOf(3));
  CheckEquals(20, OrderOf(1));
  CheckEquals(10, OrderOf(2), 'Quelle neu nummeriert');
  // nach Neuladen gleiche Reihenfolge
  K.Reload;
  CheckEquals('X,A', Titles(K, 1));
  CheckEquals('B', Titles(K, 0));
  // Ziehen mit der Maus
  K.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Center(K.CardRect(0, 0, 0)).X, Center(K.CardRect(0, 0, 0)).Y));
  K.Perform(WM_MOUSEMOVE, MK_LBUTTON, MakeLParam(Center(K.ColumnRect(2)).X, K.HeaderRect(2).Bottom + 30));
  K.Perform(WM_LBUTTONUP, 0, MakeLParam(Center(K.ColumnRect(2)).X, K.HeaderRect(2).Bottom + 30));
  CheckEquals('done', StatusOf(2));
end;

procedure TDBKanbanTests.ReorderRenumbersCell;
var
  K: TPPGDBKanban;
begin
  AddRow(1, 'todo', 1, 'A');
  AddRow(2, 'todo', 2, 'B');
  AddRow(3, 'todo', 3, 'C');
  K := NewBoard;
  CheckTrue(K.MoveCard(0, 0, 2, 0, 0, 0));
  CheckEquals('C,A,B', Titles(K, 0));
  CheckEquals(10, OrderOf(3));
  CheckEquals(20, OrderOf(1));
  CheckEquals(30, OrderOf(2));
  CheckEquals('todo', StatusOf(3));
end;

procedure TDBKanbanTests.LanesFromField;
var
  K: TPPGDBKanban;
begin
  AddRow(1, 'todo', 10, 'A', 'web');
  AddRow(2, 'todo', 20, 'B', 'app');
  AddRow(3, 'doing', 10, 'X', 'app');
  K := NewBoard;
  K.Lanes.AddLane('Web').Key := 'web';
  K.Lanes.AddLane('App').Key := 'app';
  K.LaneField := 'Team';
  CheckEquals('A', Titles(K, 0, 0));
  CheckEquals('B', Titles(K, 0, 1));
  CheckTrue(K.MoveCard(0, 1, 0, 1, 0, 0));
  CheckEquals('web', (FData.Lookup('ID', 2, 'Team')));
  CheckEquals('doing', StatusOf(2));
end;

procedure TDBKanbanTests.ExternalChangeReloads;
var
  K: TPPGDBKanban;
begin
  AddRow(1, 'todo', 10, 'A');
  K := NewBoard;
  K.Select(0, 0, 0);
  AddRow(2, 'todo', 5, 'Neu');
  CheckEquals('Neu,A', Titles(K, 0));
  CheckEquals('A', K.SelectedCard.Title, 'Auswahl bleibt an der Karte');
  FData.Locate('ID', 1, []);
  FData.Edit;
  FData.FieldByName('Status').AsString := 'done';
  FData.Post;
  CheckEquals('A', Titles(K, 2));
  FData.Locate('ID', 2, []);
  FData.Delete;
  CheckEquals(0, K.CardCount(0, 0));
  CheckEquals(1, K.Cards.Count);
end;

procedure TDBKanbanTests.SelectionMovesRecord;
var
  K: TPPGDBKanban;
begin
  AddRow(1, 'todo', 10, 'A');
  AddRow(2, 'doing', 10, 'B');
  FData.First;
  K := NewBoard;
  K.Select(1, 0, 0);
  CheckEquals(2, FData.FieldByName('ID').AsInteger, 'Datensatz folgt der Auswahl');
  K.SyncRecord := False;
  K.Select(0, 0, 0);
  CheckEquals(2, FData.FieldByName('ID').AsInteger);
end;

procedure TDBKanbanTests.WithoutKeyIsReadOnly;
var
  K: TPPGDBKanban;
begin
  AddRow(1, 'todo', 10, 'A');
  K := NewBoard;
  K.KeyField := '';
  CheckEquals(1, K.CardCount(0, 0));
  CheckFalse(K.MoveCard(0, 0, 0, 1, 0, 0), 'ohne Schluessel nicht schreibbar');
  CheckEquals('todo', StatusOf(1));
  CheckEquals(1, K.CardCount(0, 0));
end;

procedure TDBKanbanTests.ClosedDataSetClears;
var
  K: TPPGDBKanban;
begin
  AddRow(1, 'todo', 10, 'A');
  K := NewBoard;
  CheckEquals(1, K.Cards.Count);
  FData.Close;
  CheckEquals(0, K.Cards.Count);
  CheckEquals(0, K.CardCount(0, 0));
end;

initialization
  RegisterTest('Phase14c', TDBKanbanTests.Suite);

end.
