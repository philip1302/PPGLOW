# TPPGDBGridEditFormOptions

Typ in Unit `PPG.DB.Grid` - Basis `TPersistent`

Einstellungen des Bearbeitungsformulars (TPPGCustomDBGrid.EditForm).

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `ColumnCount` | `Integer` | `2` | Spalten des Rasters im Bearbeitungsformular (1..8; Vorgabe 2). Je Spalte steht ein Feld als Beschriftung + Editor; die Felder fließen in der Reihenfolge der Spalten nach rechts und brechen um. Praxis: 2 für normale Fenster, 3 bis 4 für breite Grids mit vielen kurzen Feldern (Kennzeichen, Beträge, Datum); mehr als 4 wird schnell unübersichtlich. |
| `LabelWidth` | `Integer` | `120` | Breite der Beschriftung links vom Editor in logischen Pixeln (0..1000; Vorgabe 120). 0 = ohne Beschriftung; höchstens die halbe Breite eines Felds. Praxis: So breit wie die längste übliche Beschriftung; 0 nur, wenn die Felder ohnehin selbsterklärend sind (z. B. mit TextHint). |
| `ShowButtons` | `Boolean` | `True` | True: Schaltflächen Übernehmen und Abbrechen unten im Formular. False: nur Tastatur (Strg+Enter, Esc; Enter im letzten Feld übernimmt). Praxis: Eingeschaltet lassen; ohne Schaltflächen bleibt nur die Tastatur (Strg+Enter, Esc), das kennen Gelegenheitsnutzer nicht. |

## Verwendet in

[TPPGDBGrid](../TPPGDBGrid.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
