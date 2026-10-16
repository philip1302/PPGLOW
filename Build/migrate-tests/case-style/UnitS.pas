unit UnitS;

interface

uses
  Vcl.Forms, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Menus, Data.DB;

type
  TFormS = class(TForm)
    Panel1: TPanel;
    Edit1: TEdit;
    Button1: TButton;
    Menu1: TPopupMenu;
    Item1: TMenuItem;
    Src1: TDataSource;
  end;

implementation

{$R *.dfm}

end.
