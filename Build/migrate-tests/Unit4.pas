unit Unit4;

interface

uses
  Vcl.Forms, Vcl.Grids, Vcl.ComCtrls, Vcl.Samples.Spin;

type
  TForm4 = class(TForm)
    Spin1: TSpinEdit;
    Grid1: TStringGrid;
    Track1: TTrackBar;
    procedure Grid1TopLeftChanged(Sender: TObject);
  private
    procedure Limit(Value: Integer);
  end;

implementation

{$R *.dfm}

procedure TForm4.Grid1TopLeftChanged(Sender: TObject);
begin
end;

procedure TForm4.Limit(Value: Integer);
begin
  Spin1.MaxValue := Value;
  if Spin1.minvalue > Value then
    Spin1.MinValue := 0;
  Track1.SliderVisible := Value > 0;
  Grid1.OnTopLeftChanged := nil;
end;

end.
