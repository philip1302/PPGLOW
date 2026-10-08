**Vorbild:** TMS FNC Chart, TeeChart (Grundfunktionen)

## Unterschiede und Hinweise

- Bewusst kein TeeChart-Nachbau: kein 3D, keine Finanz-Charts, kein Zoom/Pan, keine logarithmische Achse, keine Splines.
- Serienarten: Linie, Stufe, Fläche, Säule, Balken, Kreis, Ring. Sind alle sichtbaren Serien Balken, liegt das Diagramm quer; ist die erste sichtbare Serie ein Kreis/Ring, zeigt es nur diese.
- `Stacking` (gestapelt, 100 %) gilt für Säulen, Balken und Flächen auf der Kategorieachse.
- Datenänderungen gleiten (bis 10 000 Punkte). Mehrere Änderungen in `BeginDataUpdate`/`EndDataUpdate` ergeben einen Übergang. `Append(Y, MaxCount)` für Live-Daten.
- Virtueller Modus: `Series.VirtualCount` + `OnGetPoint`.
- Der Tooltip ist Teil des Controls (kein eigenes Fenster) und erscheint deshalb auch in Screenshots. `SaveToBitmap`/`SaveToPng`/`CopyToClipboard` zeigen immer den Endzustand.
- Screenreader: Kinder sind die Datenpunkte (höchstens 500 je Serie).

## Anpassung

- `ChartStyles` (Titel, Achse, Gitter, Legende), `TitleFont`, `LegendFont`; Serienfarben ohne eigene Farbe aus `TPPGStyleManager.ChartPalette`.

## Beispiel

```pascal
var
  S: TPPGChartSeries;
begin
  PPGChart1.Categories.CommaText := 'Jan,Feb,Mrz';
  S := PPGChart1.Series.Add;
  S.Title := 'Umsatz';
  S.Kind := cskColumn;
  S.SetValues([12, 15, 11]);
  PPGChart1.ReferenceLines.Add.Value := 13;
end;
```
