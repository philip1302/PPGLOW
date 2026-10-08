# TPPGComboColumn

Typ in Unit `PPG.ColumnComboBox` - Basis `TCollectionItem`

Eine Spalte der Aufklappliste: Titel, Breite, Ausrichtung und Sichtbarkeit.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Title` | `string` |  | Überschrift der Spalte in der Kopfzeile der Aufklappliste. |
| `Width` | `Integer` | `100` | Breite der Spalte in logischen Pixeln (wird mit der DPI skaliert). |
| `Alignment` | `TAlignment` | `taLeftJustify` | Ausrichtung der Zellen und des Titels dieser Spalte. |
| `Visible` | `Boolean` | `True` | False: Die Spalte wird nicht angezeigt (ihre Daten bleiben verfügbar, z. B. als versteckter Schlüssel). |

## Verwendet in

[TPPGComboColumns](TPPGComboColumns.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
