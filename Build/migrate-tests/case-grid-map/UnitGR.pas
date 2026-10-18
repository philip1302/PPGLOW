unit UnitGR;

interface

uses
  Vcl.Forms, Vcl.DBGrids, Old.Grid;

type
  TFormGR = class(TForm)
    Grid1: TOldGrid;
    Grid2: TOldExtGrid;
    procedure Grid1CellClick(Column: TColumn);
    procedure Grid1DrawColumnCell(
      Sender:     TObject;
      const Rect: TRect;
      DataCol:    Integer;
      Column:     TColumn;
      State:      TGridDrawState);
    procedure Grid1TitleRightClick(Column: TColumn);
    procedure Grid1ColumnResized(
      Grid:           TOldGridBase;
      ACol, NewWidth: Integer);
    procedure Other(Column: TColumn);
  end;

implementation

{$R *.dfm}

procedure TFormGR.Grid1CellClick(Column: TColumn);
begin
end;

procedure TFormGR.Grid1DrawColumnCell(
  Sender:     TObject;
  const Rect: TRect;
  DataCol:    Integer;
  Column:     TColumn;
  State:      TGridDrawState);
begin
end;

procedure TFormGR.Grid1TitleRightClick(Column: TColumn);
begin
end;

procedure TFormGR.Grid1ColumnResized(
  Grid:           TOldGridBase;
  ACol, NewWidth: Integer);
begin
end;

procedure TFormGR.Other(Column: TColumn);
begin
end;

end.
