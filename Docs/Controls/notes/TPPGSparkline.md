**Vorbild:** Excel-Sparklines, TMS FNC Chart (Sparkline)

## Unterschiede und Hinweise

- Kein Fokus, kein Hover, keine Ereignisse außer Maus/Klick. Werte im Code (`SetValues`, `AddValue`) oder im DFM über `ValuesText` (`"3;5;2.5"`, Punkt als Dezimaltrenner).
- `MaxCount` > 0 macht aus `AddValue` ein Lauffenster.
- Ohne eigenen Bereich (`UseRange = False`) stehen Säulen und Flächen auf der Nulllinie.
- Sehr viele Werte werden pro Pixelspalte auf Min/Max verdichtet.
- `PPGDrawSparkline`/`PPGDrawSparklineOnCanvas` zeichnen dieselbe Darstellung ohne Control (Grid-Zellen, eigene Kacheln).

## Beispiel

```pascal
procedure TForm1.PPGGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  O: TPPGSparklineOptions;
begin
  if (ACol = 3) and (ARow > 0) then
  begin
    O := PPGDefaultSparklineOptions(PPGDefaultTokens(False), clWindow, Screen.PixelsPerInch);
    InflateRect(Rect, -4, -3);
    PPGDrawSparklineOnCanvas(PPGGrid1.Canvas, Rect, FVerlauf[ARow], O);
  end;
end;
```
