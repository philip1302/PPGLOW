unit Unit1;

interface

uses
  Winapi.Windows, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.Buttons,
  Vcl.DBGrids, Data.DB;

type
  TForm1 = class(TForm)
    Button1: TButton;
    BitBtn1: TBitBtn;
    Edit1: TAdvEdit;
    Switch1: TToggleSwitch;
    StatusBar1: TStatusBar;
    Grid1: TDBGrid;
    Memo1: TMemo;
    DataSource1: TDataSource;
    procedure Grid1TitleClick(Column: TColumn);
    procedure Grid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer;
      Column: TColumn; State: TGridDrawState);
  end;

implementation

{$R *.dfm}

procedure TForm1.Grid1TitleClick(Column: TColumn);
begin
end;

procedure TForm1.Grid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer;
  Column: TColumn; State: TGridDrawState);
begin
  Grid1.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;

end.
