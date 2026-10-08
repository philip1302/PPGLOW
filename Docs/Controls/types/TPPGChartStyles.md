# TPPGChartStyles

Typ in Unit `PPG.Chart` - Basis `TPPGStyleGroup`

Bereiche des Diagramms (nur gesetzte Werte zaehlen, clDefault = Preset).

Bereiche des Diagramms einzeln gestalten: Titel, Achsen, Gitterlinien und Legende (Farben und Schriften).

Nutzung: `PPGChart1.ChartStyles.Title.Font.Size := 14;`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Title` | [TPPGElementStyle](TPPGElementStyle.md) |  | Diagrammtitel: TextColor und Schrift. Ohne eigene Schrift wird die Schrift des Controls 1,25-fach und fett verwendet. Nutzung: `Chart.ChartStyles.Title.ParentFont := False; Chart.ChartStyles.Title.Font.Size := 14;` |
| `Axis` | [TPPGElementStyle](TPPGElementStyle.md) |  | Achsenbeschriftung und Achsentitel: TextColor und Schrift. |
| `Grid` | [TPPGElementStyle](TPPGElementStyle.md) |  | Gitterlinien: Farbe über Color (bzw. DarkColor). Nutzung: `Chart.ChartStyles.Grid.Color := $00E8E8E8;` |
| `Legend` | [TPPGElementStyle](TPPGElementStyle.md) |  | Legende: TextColor und Schrift. |

## Verwendet in

[TPPGChart](../TPPGChart.md), [TPPGDBChart](../TPPGDBChart.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
