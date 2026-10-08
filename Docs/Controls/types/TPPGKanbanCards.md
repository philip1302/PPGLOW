# TPPGKanbanCards

Typ in Unit `PPG.Kanban.Items` - Basis `TOwnedCollection`

Die Karten des Boards (Collection). Jede Karte gehört über ColumnId und LaneId zu einer Spalte bzw. Swimlane; die Reihenfolge in der Collection ist die Reihenfolge im Board.

Nutzung: `PPGKanban1.Cards.AddCard(PPGKanban1.Columns[0].Id, 'Neue Aufgabe');`

Collection: Die Eintraege sind vom Typ [TPPGKanbanCard](TPPGKanbanCard.md). Im Designer ueber den Collection-Editor (Doppelklick auf die Eigenschaft), im Code ueber `Add`, `Items[i]`, `Count`, `Delete`, `Clear`.

## Verwendet in

[TPPGKanban](../TPPGKanban.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
