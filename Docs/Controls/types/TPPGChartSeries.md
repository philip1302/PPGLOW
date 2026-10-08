# TPPGChartSeries

Typ in Unit `PPG.Chart.Series` - Basis `TCollectionItem`

Eine Datenreihe: Art der Darstellung, Werte, Farbe, Achse, Beschriftung und Stapelung.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Title` | `string` |  | Name der Serie in Legende, Tooltip und für den Screenreader. |
| `Kind` | `TPPGChartSeriesKind` | `cskLine` | Darstellung der Serie. Linien, Stufen, Flächen und Säulen lassen sich mischen; sind alle sichtbaren Serien Balken, liegt das Diagramm quer. Ist die erste sichtbare Serie Kreis oder Ring, zeigt das Diagramm nur diese Serie. Werte: `cskLine`, `cskStepLine`, `cskArea`, `cskColumn`, `cskBar`, `cskPie`, `cskDonut`. Nutzung: `Chart.Series[0].Kind := cskColumn; Chart.Series[1].Kind := cskLine;` |
| `Color` | `TColor` | `clDefault` | Farbe der Serie; clDefault = nächste Farbe der Palette (Akzent zuerst, eigene Palette über TPPGStyleManager.ChartPalette). Einzelne Punkte können eigene Farben haben (Parameter Color von Add). |
| `Visible` | `Boolean` | `True` | False: Serie ausblenden (gleitend, wenn animiert). Dasselbe bewirkt ein Klick auf den Legendeneintrag (LegendToggle). |
| `YAxis` | `TPPGChartAxisSide` | `casPrimary` | An welcher Y-Achse die Serie skaliert wird: casPrimary = links (YAxis), casSecondary = rechts (Y2Axis). Für zwei Größen mit verschiedenen Einheiten. Werte: `casPrimary`, `casSecondary`. Nutzung: `Chart.Series[1].YAxis := casSecondary; Chart.Y2Axis.Title := 'Anzahl';` |
| `LineWidth` | `Integer` | `2` | Strichstärke von Linie, Stufe und Flächenrand in logischen Pixeln (1..20). |
| `ShowMarkers` | `Boolean` | `False` | True: Punkte auf der Linie als Kreise markieren (sinnvoll bei wenigen Werten). |
| `ValueFormat` | `string` |  | FormatFloat-Maske der Werte im Tooltip; leer = Format der zugehörigen Y-Achse. Nutzung: `Chart.Series[0].ValueFormat := '#,##0.00 €';` |
| `VirtualCount` | `Integer` | `0` | > 0: Die Serie hat so viele Punkte, geliefert werden sie bei Bedarf über OnGetPoint des Diagramms; eigene Punkte werden ignoriert. Für sehr große oder berechnete Datenmengen. Nutzung: `Chart.Series[0].VirtualCount := 100000;` und OnGetPoint behandeln. |
| `ValuesText` | `string` |  | Y-Werte als Text, getrennt durch Semikolon, Punkt als Dezimaltrenner ("3;5;2.5"); X ist dann der Index. So stehen Werte im DFM; im Code bequemer mit SetValues, Add oder AddXY. Nutzung: Im Objektinspektor `12;18;9.5;22` eintragen; im Code `Chart.Series[0].SetValues([12, 18, 9.5, 22]);` |

## Verwendet in

[TPPGChartSeriesList](TPPGChartSeriesList.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
