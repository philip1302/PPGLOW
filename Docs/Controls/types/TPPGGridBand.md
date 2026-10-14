# TPPGGridBand

Typ in Unit `PPG.Grid.Columns` - Basis `TCollectionItem`

Ein Band über den Spaltenköpfen: Titel; die Zuordnung der Spalten erfolgt über deren Band-Index.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Caption` | `string` |  | Überschrift des Bands über seinen Spalten. Praxis: Kurzer Oberbegriff über den Spalten: „Anschrift“, „Kontakt“, „Q1 2026“. |
| `ParentBand` | `Integer` | `-1` | Übergeordnetes Band (Index in Grid.Bands) für mehrstufige Köpfe; -1 = oberste Ebene. Praxis: Für zweistufige Köpfe: „2026“ als oberes Band, darunter „Q1“ bis „Q4“ mit ParentBand = 0. Mehr als zwei Ebenen werden schnell unübersichtlich. |
| `Alignment` | `TAlignment` | `taCenter` | Ausrichtung der Band-Überschrift (links, zentriert, rechts). Praxis: Zentriert lassen, das liest sich über mehreren Spalten am besten; links nur bei sehr breiten Bändern. |

## Verwendet in

[TPPGGridBands](TPPGGridBands.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
