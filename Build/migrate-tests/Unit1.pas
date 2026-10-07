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
  end;

implementation

{$R *.dfm}

procedure TForm1.Grid1TitleClick(Column: TColumn);
begin
end;

end.
