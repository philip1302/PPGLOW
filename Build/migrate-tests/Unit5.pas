unit Unit5;

interface

uses
  Vcl.Forms, Vcl.Buttons, Vcl.ExtCtrls, Vcl.Menus, Vcl.StdCtrls;

type
  TForm5 = class(TForm)
    Panel1: TPanel;
    Edit1: TEdit;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    YesBtn: TBitBtn;
    NoBtn: TBitBtn;
    CloseBtn: TBitBtn;
    CustomBtn: TBitBtn;
    PopupMenu1: TPopupMenu;
    Item1: TMenuItem;
    Item2: TMenuItem;
    procedure Item1Click(Sender: TObject);
  end;

implementation

{$R *.dfm}

procedure TForm5.Item1Click(Sender: TObject);
begin
  if Sender is TBitBtn then
    Caption := (Sender as TBitBtn).Caption;
  TBitBtn(Sender).Caption := 'x'; // TBitBtn( im Kommentar zaehlt nicht
  with OkBtn do
    Caption := 'y';
  with Panel1, CloseBtn do
    Visible := True;
end;

end.
