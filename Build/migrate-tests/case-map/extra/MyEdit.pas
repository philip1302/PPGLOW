unit My.Edit;

interface

uses
  PPG.Edit;

type
  // eigene Ableitung ausserhalb von Source
  TMyEdit = class(TPPGEdit)
  published
    property Special: string;
    property Flag;
  end;

implementation

end.
