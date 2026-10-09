# TPPGElementStyle

Typ in Unit `PPG.ElementStyle` - Basis `TPersistent`

Aussehen eines Bereichs (z. B. Kopfzeile, Auswahl, Zebra-Zeile). clDefault heißt „vom Preset berechnet": Ein leerer Stil ändert nichts und wird nicht in der DFM gespeichert. Farben gelten nicht im Hochkontrast und nicht mit VCL-Style, Schriften immer.

Nutzung: `Grid.Styles.Header.Color := clNavy; Grid.Styles.Header.TextColor := clWhite; Grid.Styles.Header.FontStyle := [fsBold];`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Color` | `TColor` | `clDefault` | Flächenfarbe des Bereichs im Hellen; clDefault = vom Preset. |
| `TextColor` | `TColor` | `clDefault` | Textfarbe im Hellen; clDefault = vom Preset. |
| `BorderColor` | `TColor` | `clDefault` | Rand- bzw. Linienfarbe im Hellen; clDefault = vom Preset. |
| `DarkColor` | `TColor` | `clDefault` | Flächenfarbe im Dark Mode; clDefault = vom Preset (eigene helle Farben gelten im Dunkeln nicht). |
| `DarkTextColor` | `TColor` | `clDefault` | Textfarbe im Dark Mode; clDefault = vom Preset. |
| `DarkBorderColor` | `TColor` | `clDefault` | Rand- bzw. Linienfarbe im Dark Mode; clDefault = vom Preset. |
| `ParentFont` | `Boolean` | `True` | True: Schrift des Controls; wird False, sobald Font geändert wird. |
| `Font` | `TFont` |  | Eigene Schrift des Bereichs (wirkt nur mit ParentFont = False). Nutzung: `Grid.Styles.Footer.Font.Size := 8;` |
| `FontStyle` | `TFontStyles` | `[]` | Zusätzliche Schriftstile auf die Schrift des Controls bzw. auf Font (z. B. [fsBold] für eine fette Kopfzeile ohne eigene Schrift). |

## Verwendet in

[TPPGCheckComboBox](../TPPGCheckComboBox.md), [TPPGCheckGroup](../TPPGCheckGroup.md), [TPPGColumnComboBox](../TPPGColumnComboBox.md), [TPPGDBCheckComboBox](../TPPGDBCheckComboBox.md), [TPPGDBEdit](../TPPGDBEdit.md), [TPPGDBMaskEdit](../TPPGDBMaskEdit.md), [TPPGDBMemo](../TPPGDBMemo.md), [TPPGDBNumberEdit](../TPPGDBNumberEdit.md), [TPPGDBRadioGroup](../TPPGDBRadioGroup.md), [TPPGDBTagEdit](../TPPGDBTagEdit.md), [TPPGEdit](../TPPGEdit.md), [TPPGExpander](../TPPGExpander.md), [TPPGFileEdit](../TPPGFileEdit.md), [TPPGGauge](../TPPGGauge.md), [TPPGGroupBox](../TPPGGroupBox.md), [TPPGInfoBar](../TPPGInfoBar.md), [TPPGKpiTile](../TPPGKpiTile.md), [TPPGMaskEdit](../TPPGMaskEdit.md), [TPPGMemo](../TPPGMemo.md), [TPPGNumberEdit](../TPPGNumberEdit.md), [TPPGPasswordEdit](../TPPGPasswordEdit.md), [TPPGRadioGroup](../TPPGRadioGroup.md), [TPPGSpinEdit](../TPPGSpinEdit.md), [TPPGStatusBar](../TPPGStatusBar.md), [TPPGTagEdit](../TPPGTagEdit.md), [TPPGTileView](../TPPGTileView.md), [TPPGCalendarStyles](TPPGCalendarStyles.md), [TPPGChartStyles](TPPGChartStyles.md), [TPPGGridColumn](TPPGGridColumn.md), [TPPGGridStyles](TPPGGridStyles.md), [TPPGKanbanStyles](TPPGKanbanStyles.md), [TPPGListStyles](TPPGListStyles.md), [TPPGMenuStyles](TPPGMenuStyles.md), [TPPGNavStyles](TPPGNavStyles.md), [TPPGPlannerStyles](TPPGPlannerStyles.md), [TPPGTabStyles](TPPGTabStyles.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
