unit PPG.CustomDraw;

{ Einheitliches eigenes Zeichnen fuer Eintraege (Anpassbarkeit, Baustein 3).

  Muster fuer alle Controls mit Eintraegen (Liste, Baum, Combo-Liste, Reiter,
  Navigation, Menues, Kalendertage, Kanban-Karten, Planer-Termine):

    OnCustomDrawItem(Sender, Canvas, Index, Rect, State, var Style, var DefaultDraw)

  - Das Ereignis kommt VOR dem Zeichnen des Eintrags. Canvas zeichnet direkt
    in den Puffer des Controls (GDI); Rect ist die Flaeche des Eintrags.
  - Style aendert nur einzelne Werte der Standard-Darstellung (Flaeche,
    Textfarbe, zusaetzliche Schriftstile); clNone = Standard.
  - DefaultDraw := False: das Control zeichnet den Eintrag gar nicht, das
    Ereignis hat alles selbst gezeichnet (Fokusrahmen u.ae. ebenfalls).
  - Ausnahmen im Ereignis laufen wie bei OnDrawCell in die Fehlergrenze des
    Zeichnens (einmal gemeldet, nicht weitergeworfen). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.Types, Vcl.Graphics, PPG.Render.Intf;

type
  TPPGItemDrawStateFlag = (idsSelected, idsFocused, idsHot, idsDisabled, idsChecked,
    idsExpanded, idsToday, idsHeader);
  TPPGItemDrawState = set of TPPGItemDrawStateFlag;

  /// Abweichungen von der Standard-Darstellung eines Eintrags.
  TPPGDrawStyle = record
    Fill: TColor;          // Flaeche; clNone = Standard
    TextColor: TColor;     // clNone = Standard
    BorderColor: TColor;   // Rahmen/Akzent; clNone = Standard
    FontStyle: TFontStyles; // zusaetzliche Schriftstile
    procedure Reset;
    function IsDefault: Boolean;
  end;

  TPPGCustomDrawItemEvent = procedure(Sender: TObject; Canvas: TCanvas; Index: Integer;
    const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle;
    var DefaultDraw: Boolean) of object;

/// Ruft Event mit einem TCanvas auf dem GDI-DC des Puffers auf; Ergebnis =
/// DefaultDraw. ItemCanvas gehoert dem Aufrufer (ohne eigenes Handle).
function PPGRunCustomDraw(const ACanvas: IPPGCanvas; ItemCanvas: TCanvas; Font: TFont;
  Event: TPPGCustomDrawItemEvent; Sender: TObject; Index: Integer; const R: TRect;
  State: TPPGItemDrawState; var Style: TPPGDrawStyle): Boolean;

implementation

{ TPPGDrawStyle }

procedure TPPGDrawStyle.Reset;
begin
  Fill := clNone;
  TextColor := clNone;
  BorderColor := clNone;
  FontStyle := [];
end;

function TPPGDrawStyle.IsDefault: Boolean;
begin
  Result := (Fill = clNone) and (TextColor = clNone) and (BorderColor = clNone) and
    (FontStyle = []);
end;

function PPGRunCustomDraw(const ACanvas: IPPGCanvas; ItemCanvas: TCanvas; Font: TFont;
  Event: TPPGCustomDrawItemEvent; Sender: TObject; Index: Integer; const R: TRect;
  State: TPPGItemDrawState; var Style: TPPGDrawStyle): Boolean;
var
  DC: HDC;
begin
  Result := True;
  Style.Reset;
  if not Assigned(Event) or (ACanvas = nil) or (ItemCanvas = nil) then
    Exit;
  DC := ACanvas.BeginGdi;
  try
    ItemCanvas.Handle := DC;
    try
      if Font <> nil then
        ItemCanvas.Font := Font;
      ItemCanvas.Brush.Style := bsClear;
      Event(Sender, ItemCanvas, Index, R, State, Style, Result);
    finally
      ItemCanvas.Handle := 0;
    end;
  finally
    ACanvas.EndGdi(DC);
  end;
end;

end.
