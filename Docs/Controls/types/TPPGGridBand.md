# TPPGGridBand

Typ in Unit `PPG.Grid.Columns` - Basis `TCollectionItem`

Ein Band über den Spaltenköpfen: Titel; die Zuordnung der Spalten erfolgt über deren Band-Index.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Caption` | `string` |  | Überschrift des Bands über seinen Spalten. |
| `ParentBand` | `Integer` | `-1` | Übergeordnetes Band (Index in Grid.Bands) für mehrstufige Köpfe; -1 = oberste Ebene. |
| `Alignment` | `TAlignment` | `taCenter` | Ausrichtung der Band-Überschrift (links, zentriert, rechts). |

## Verwendet in

[TPPGGridBands](TPPGGridBands.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
