# TPPGListStyles

Typ in Unit `PPG.ItemPainter` - Basis `TPPGStyleGroup`

Bereiche einer Liste (ListBox, CheckListBox, TreeView, Combo-Liste). Nur gesetzte Werte ueberschreiben das Preset (clDefault = Preset).

Bereiche einer Liste einzeln gestalten: Auswahl, Auswahl ohne Fokus, Zebra-Zeile, Eintrag unter der Maus, Gruppenkopf und Detailzeile.

Nutzung: `PPGListBox1.Styles.Selection.Color := $00F5E6D2;`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Selection` | [TPPGElementStyle](TPPGElementStyle.md) |  | Gewählte Einträge bei Fokus: Color = deckende Fläche, BorderColor = Akzentbalken links, TextColor und Schrift. Nutzung: `List.Styles.Selection.Color := $00F5E6D2; List.Styles.Selection.TextColor := clBlack;` |
| `SelectionInactive` | [TPPGElementStyle](TPPGElementStyle.md) |  | Gewählte Einträge, wenn die Liste keinen Fokus hat (meist gedämpfter als Selection). |
| `AlternateRow` | [TPPGElementStyle](TPPGElementStyle.md) |  | Zebra-Zeilen: jede zweite Zeile erhält diese Fläche. Erst ein gesetztes Color schaltet das Zebra ein. Nutzung: `List.Styles.AlternateRow.Color := $00FAF7F2;` |
| `HotItem` | [TPPGElementStyle](TPPGElementStyle.md) |  | Eintrag unter der Maus: Fläche und Textfarbe. |
| `GroupHeader` | [TPPGElementStyle](TPPGElementStyle.md) |  | Gruppenüberschriften (TPPGItem.Group bzw. Header[] der CheckListBox): Fläche, Text und Schrift. |
| `Detail` | [TPPGElementStyle](TPPGElementStyle.md) |  | Detailzeile (zweite Zeile) der Einträge: TextColor und Schrift. |

## Verwendet in

[TPPGCheckListBox](../TPPGCheckListBox.md), [TPPGComboBox](../TPPGComboBox.md), [TPPGDBComboBox](../TPPGDBComboBox.md), [TPPGDBLookupComboBox](../TPPGDBLookupComboBox.md), [TPPGListBox](../TPPGListBox.md), [TPPGTreeView](../TPPGTreeView.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
