# TPPGPlannerCategories

Typ in Unit `PPG.Planner` - Basis `TOwnedCollection`

Kategorien des Planers wie in Outlook: Name und Farbe. Ein Termin verweist über Category (Index) auf eine Kategorie; deren Farbe ersetzt die Palettenfarbe.

Nutzung: `with PPGPlanner1.Categories.Add do begin Caption := 'Kunde'; Color := $0050B000; end;`

Collection: Die Eintraege sind vom Typ [TPPGPlannerCategory](TPPGPlannerCategory.md). Im Designer ueber den Collection-Editor (Doppelklick auf die Eigenschaft), im Code ueber `Add`, `Items[i]`, `Count`, `Delete`, `Clear`.

## Verwendet in

[TPPGDBPlanner](../TPPGDBPlanner.md), [TPPGPlanner](../TPPGPlanner.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
