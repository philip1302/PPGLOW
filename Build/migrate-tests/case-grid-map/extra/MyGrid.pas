unit My.Grid;

interface

uses
  PPG.DB.Grid;

type
  TMyGridResizeEvent = procedure(Grid: TPPGDBGrid; ACol, NewWidth: Integer) of object;

  // eigene Ableitung ausserhalb von Source
  TMyGrid = class(TPPGDBGrid)
  published
    property SortOnTitleClick: Boolean;
    property OnTitleRightClick: TPPGDBGridColumnEvent;
    property OnColumnResized: TMyGridResizeEvent;
  end;

implementation

end.
