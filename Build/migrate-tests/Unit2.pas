unit Unit2;

// Formular für die Übersicht (ANSI)

interface

uses
  Vcl.Forms, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.DBGrids;

type
  TForm2 = class(TForm)
    Tree1: TTreeView;
    Pages1: TPageControl;
    Sheet1: TTabSheet;
    Split1: TButton;
    Link1: TButton;
    Bar1: TProgressBar;
    Grid1: TDBGrid;
  end;

implementation

{$R *.dfm}

end.
