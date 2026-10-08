# TPPGGridConditionalFormats

Typ in Unit `PPG.Grid.Styles` - Basis `TOwnedCollection`

Bedingte Formatierung ohne Code: Regeln färben Zellen abhängig vom Wert (Bereich, gleich, enthält, Top/Bottom) oder zeigen Farbskala, Datenbalken und Symbole.

Nutzung: `with PPGGrid1.ConditionalFormats.Add do begin Column := 1; Rule := crContains; Value1 := 'Fehler'; Color := ccDanger; Target := ctText; end;`

Collection: Die Eintraege sind vom Typ [TPPGGridConditionalFormat](TPPGGridConditionalFormat.md). Im Designer ueber den Collection-Editor (Doppelklick auf die Eigenschaft), im Code ueber `Add`, `Items[i]`, `Count`, `Delete`, `Clear`.

## Verwendet in

[TPPGDBGrid](../TPPGDBGrid.md), [TPPGGrid](../TPPGGrid.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
