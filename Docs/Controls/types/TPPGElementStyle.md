# TPPGElementStyle

Typ in Unit `PPG.ElementStyle` - Basis `TPersistent`

Aussehen eines Bereichs (z. B. Kopfzeile, Auswahl, Zebra-Zeile). clDefault heißt „vom Preset berechnet": Ein leerer Stil ändert nichts und wird nicht in der DFM gespeichert. Farben gelten nicht im Hochkontrast und nicht mit VCL-Style, Schriften immer.

Nutzung: `Grid.Styles.Header.Color := clNavy; Grid.Styles.Header.TextColor := clWhite; Grid.Styles.Header.FontStyle := [fsBold];`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Color` | `TColor` | `clDefault` | Flächenfarbe des Bereichs im Hellen; clDefault = vom Preset. Praxis: Eigene Flächenfarbe für den Bereich, z. B. ein helles Grau für gesperrte (ReadOnly) Felder. clDefault lassen, wenn das Preset passt. |
| `TextColor` | `TColor` | `clDefault` | Textfarbe im Hellen; clDefault = vom Preset. Praxis: Eigene Textfarbe, z. B. clGrayText für schreibgeschützte Felder; auf ausreichenden Kontrast achten. |
| `BorderColor` | `TColor` | `clDefault` | Rand- bzw. Linienfarbe im Hellen; clDefault = vom Preset. Praxis: Eigene Randfarbe, z. B. ein blasser Rand, damit ein gesperrtes Feld zurücktritt. |
| `DarkColor` | `TColor` | `clDefault` | Flächenfarbe im Dark Mode; clDefault = vom Preset (eigene helle Farben gelten im Dunkeln nicht). Praxis: Gegenstück zu Color für den Dark Mode. Setzen, sobald Sie Color selbst gesetzt haben, sonst bleibt die Fläche im Dunkeln hell. |
| `DarkTextColor` | `TColor` | `clDefault` | Textfarbe im Dark Mode; clDefault = vom Preset. Praxis: Gegenstück zu TextColor für den Dark Mode; hell wählen, damit der Text auf dunklem Grund lesbar ist. |
| `DarkBorderColor` | `TColor` | `clDefault` | Rand- bzw. Linienfarbe im Dark Mode; clDefault = vom Preset. Praxis: Gegenstück zu BorderColor für den Dark Mode. |
| `ParentFont` | `Boolean` | `True` | True: Schrift des Controls; wird False, sobald Font geändert wird. Praxis: True lassen, damit der Bereich die Schrift des Controls nutzt. Eine eigene Schrift (Font) setzt es automatisch auf False. |
| `Font` | `TFont` |  | Eigene Schrift des Bereichs (wirkt nur mit ParentFont = False). Nutzung: `Grid.Styles.Footer.Font.Size := 8;` Praxis: Nur für eine abweichende Schrift des Bereichs, z. B. kursiv für schreibgeschützte Werte. Für fett reicht FontStyle. |
| `FontStyle` | `TFontStyles` | `[]` | Zusätzliche Schriftstile auf die Schrift des Controls bzw. auf Font (z. B. [fsBold] für eine fette Kopfzeile ohne eigene Schrift). Praxis: Einfacher als eine eigene Font: [fsBold] für eine hervorgehobene Kopfzeile oder [fsItalic] für gesperrte Werte. |

## Verwendet in

[TPPGCheckComboBox](../TPPGCheckComboBox.md), [TPPGCheckGroup](../TPPGCheckGroup.md), [TPPGColumnComboBox](../TPPGColumnComboBox.md), [TPPGDBCheckComboBox](../TPPGDBCheckComboBox.md), [TPPGDBEdit](../TPPGDBEdit.md), [TPPGDBMaskEdit](../TPPGDBMaskEdit.md), [TPPGDBMemo](../TPPGDBMemo.md), [TPPGDBNumberEdit](../TPPGDBNumberEdit.md), [TPPGDBRadioGroup](../TPPGDBRadioGroup.md), [TPPGDBRichEdit](../TPPGDBRichEdit.md), [TPPGDBTagEdit](../TPPGDBTagEdit.md), [TPPGEdit](../TPPGEdit.md), [TPPGExpander](../TPPGExpander.md), [TPPGFileEdit](../TPPGFileEdit.md), [TPPGGauge](../TPPGGauge.md), [TPPGGroupBox](../TPPGGroupBox.md), [TPPGInfoBar](../TPPGInfoBar.md), [TPPGKpiTile](../TPPGKpiTile.md), [TPPGMaskEdit](../TPPGMaskEdit.md), [TPPGMemo](../TPPGMemo.md), [TPPGNumberEdit](../TPPGNumberEdit.md), [TPPGPasswordEdit](../TPPGPasswordEdit.md), [TPPGRadioGroup](../TPPGRadioGroup.md), [TPPGRichEdit](../TPPGRichEdit.md), [TPPGSpinEdit](../TPPGSpinEdit.md), [TPPGStatusBar](../TPPGStatusBar.md), [TPPGTagEdit](../TPPGTagEdit.md), [TPPGTileView](../TPPGTileView.md), [TPPGCalendarStyles](TPPGCalendarStyles.md), [TPPGChartStyles](TPPGChartStyles.md), [TPPGGridColumn](TPPGGridColumn.md), [TPPGGridStyles](TPPGGridStyles.md), [TPPGKanbanStyles](TPPGKanbanStyles.md), [TPPGListStyles](TPPGListStyles.md), [TPPGMenuStyles](TPPGMenuStyles.md), [TPPGNavStyles](TPPGNavStyles.md), [TPPGPlannerStyles](TPPGPlannerStyles.md), [TPPGTabStyles](TPPGTabStyles.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
