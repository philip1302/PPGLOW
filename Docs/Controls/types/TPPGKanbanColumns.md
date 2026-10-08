# TPPGKanbanColumns

Typ in Unit `PPG.Kanban.Items` - Basis `TOwnedCollection`

Die Spalten des Boards (Collection) mit WIP-Limit, Farbe, Breite und Einklapp-Zustand.

Nutzung: `PPGKanban1.Columns.AddColumn('In Arbeit', 3);` (3 = WIP-Limit)

Collection: Die Eintraege sind vom Typ [TPPGKanbanColumn](TPPGKanbanColumn.md). Im Designer ueber den Collection-Editor (Doppelklick auf die Eigenschaft), im Code ueber `Add`, `Items[i]`, `Count`, `Delete`, `Clear`.

## Verwendet in

[TPPGDBKanban](../TPPGDBKanban.md), [TPPGKanban](../TPPGKanban.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
