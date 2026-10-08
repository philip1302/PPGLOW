# TPPGChartReferenceLine

Typ in Unit `PPG.Chart.Series` - Basis `TCollectionItem`

Eine Referenzlinie: Wert, Achse, Farbe, Strichart und Beschriftung.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Value` | `Double` |  | Position der Linie als Achsenwert (bei Datumsachse ein TDateTime). Nutzung: `with Chart.ReferenceLines.Add as TPPGChartReferenceLine do begin Value := 80; Caption := 'Ziel'; end;` |
| `Axis` | `TPPGChartLineAxis` | `claY` | An welcher Achse die Linie steht: Y (waagerecht, linke Achse), Y2 (waagerecht, rechte Achse) oder X (senkrecht, z. B. ein Stichtag). Werte: `claY`, `claY2`, `claX`. |
| `Caption` | `string` |  | Beschriftung an der Linie (z. B. „Ziel" oder „Durchschnitt"). |
| `Color` | `TColor` | `clDefault` | Linienfarbe; clDefault = Sekundärtextfarbe des Presets. |
| `Dashed` | `Boolean` | `True` | True: gestrichelte Linie; False: durchgezogen. |

## Verwendet in

[TPPGChartReferenceLines](TPPGChartReferenceLines.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
