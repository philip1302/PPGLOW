# TPPGItems

Typ in Unit `PPG.Items` - Basis `TOwnedCollection`

Einträge mit Text, Bild, Gruppe, Detailzeile, Plakette und eigener Farbe (ListBox, CheckListBox, ComboBox). Die einfache Liste Items (TStrings) zeigt auf dieselben Einträge.

Nutzung: `with PPGListBox1.ItemsEx.Add('Posteingang', 4) do begin Badge := '12'; Group := 'Favoriten'; end;`

Collection: Die Eintraege sind vom Typ [TPPGItem](TPPGItem.md). Im Designer ueber den Collection-Editor (Doppelklick auf die Eigenschaft), im Code ueber `Add`, `Items[i]`, `Count`, `Delete`, `Clear`.

## Verwendet in

[TPPGCheckListBox](../TPPGCheckListBox.md), [TPPGComboBox](../TPPGComboBox.md), [TPPGDBComboBox](../TPPGDBComboBox.md), [TPPGDBLookupComboBox](../TPPGDBLookupComboBox.md), [TPPGListBox](../TPPGListBox.md), [TPPGSearchEdit](../TPPGSearchEdit.md), [TPPGTileView](../TPPGTileView.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
