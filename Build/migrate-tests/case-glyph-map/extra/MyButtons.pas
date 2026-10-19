unit My.Buttons;

interface

uses
  PPG.Button, PPG.Edit;

type
  // eigene Ableitungen ausserhalb von Source
  TMyLinkButton = class(TPPGButton)
  published
    property Url: string;
  end;

  TMyPrintButton = class(TMyLinkButton)
  end;

  // veroeffentlicht Layout selbst: bleibt unveraendert
  TMyLayoutButton = class(TPPGButton)
  published
    property Layout: Integer;
  end;

  // kein Button: Glyph wird wie jede unbekannte Property entfernt
  TMyGlyphEdit = class(TPPGEdit)
  end;

implementation

end.
