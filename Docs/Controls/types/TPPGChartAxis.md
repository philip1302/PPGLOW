# TPPGChartAxis

Typ in Unit `PPG.Chart.Series` - Basis `TPersistent`

Eine Achse des Diagramms (X, Y oder zweite Y-Achse): Bereich, Teilung, Format der Beschriftung und Sichtbarkeit.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Visible` | `Boolean` | `True` | False: Achse samt Beschriftung ausblenden; die Skalierung gilt weiter. |
| `Title` | `string` |  | Achsentitel neben bzw. unter der Achse (leer = keiner). Nutzung: `Chart.YAxis.Title := 'Umsatz in T€';` |
| `AutoMin` | `Boolean` | `True` | True: Die Untergrenze wird aus den Daten berechnet (runde Werte, bei Säulen ab 0). False: Es gilt Min. Nutzung: `Chart.YAxis.AutoMin := False; Chart.YAxis.Min := 0;` |
| `AutoMax` | `Boolean` | `True` | True: Die Obergrenze wird aus den Daten berechnet. False: Es gilt Max. Nutzung: `Chart.YAxis.AutoMax := False; Chart.YAxis.Max := 100;` z. B. für Prozentwerte. |
| `Min` | `Double` |  | Feste Untergrenze; wirkt nur mit AutoMin = False. |
| `Max` | `Double` |  | Feste Obergrenze; wirkt nur mit AutoMax = False. |
| `Format` | `string` |  | FormatFloat-Maske der Achsenbeschriftung; leer = passende Nachkommastellen aus der Schrittweite. Bei einer Datumsachse eine FormatDateTime-Maske. Nutzung: `Chart.YAxis.Format := '#,##0 €';` oder `Chart.XAxis.Format := 'dd.mm.';` |
| `ShowGrid` | `Boolean` |  | Gitterlinien an den Teilstrichen dieser Achse. Vorgabe: an bei der Y-Achse, aus bei X- und zweiter Y-Achse. Farbe über ChartStyles.Grid. |
| `Kind` | `TPPGChartXKind` | `cxkCategory` | Nur für die X-Achse: Art der Werte. Kategorien verteilen die Punkte gleichmäßig (X = Index, Text aus Categories), Zahlen und Datum/Zeit setzen die Punkte nach ihrem X-Wert (Series.AddXY). Werte: `cxkCategory`, `cxkNumeric`, `cxkDateTime`. Nutzung: `Chart.XAxis.Kind := cxkDateTime; Chart.Series[0].AddXY(Date, 42);` |

## Verwendet in

[TPPGChart](../TPPGChart.md), [TPPGDBChart](../TPPGDBChart.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
