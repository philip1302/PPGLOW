unit Unit3;

interface

uses
  Vcl.Forms, Vcl.ExtCtrls, Vcl.DBCtrls, Vcl.ComCtrls, Data.DB;

type
  TForm3 = class(TForm)
    Box1: TScrollBox;
    Kind1: TRadioGroup;
    Nav1: TDBNavigator;
    State1: TDBRadioGroup;
    List1: TListView;
    Track1: TTrackBar;
    procedure Kind1Click(Sender: TObject);
  end;

implementation

{$R *.dfm}

procedure TForm3.Kind1Click(Sender: TObject);
begin
end;

end.
