# TPPGGridColumns

Typ in Unit `PPG.Grid.Columns` - Basis `TOwnedCollection`

Die Spalten des Grids bzw. DB-Grids (Collection). Ohne Spalten zeigt das Grid ColCount Spalten ohne eigene Einstellungen.

Nutzung: `with PPGGrid1.Columns.Add do begin Title := 'Menge'; Width := 80; Alignment := taRightJustify; end;`

Collection: Die Eintraege sind vom Typ [TPPGGridColumn](TPPGGridColumn.md). Im Designer ueber den Collection-Editor (Doppelklick auf die Eigenschaft), im Code ueber `Add`, `Items[i]`, `Count`, `Delete`, `Clear`.

## Verwendet in

[TPPGDBGrid](../TPPGDBGrid.md), [TPPGGrid](../TPPGGrid.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
