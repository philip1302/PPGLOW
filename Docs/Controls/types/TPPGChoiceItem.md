# TPPGChoiceItem

Typ in Unit `PPG.RadioGroup` - Basis `TCollectionItem`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Caption` | `string` |  | Beschriftung des Eintrags. |
| `Description` | `string` |  | Zweite Zeile unter dem Titel (Kacheln) bzw. gedämpfter Zusatz in der Liste. |
| `Icon` | `Word` | `0` | Zeichen der Symbolschrift (Segoe Fluent Icons bzw. MDL2), z. B. $E80F; 0 = kein Symbol. Wird nur gezeigt, wenn ImageIndex -1 ist. |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Bild aus Images der Gruppe; hat Vorrang vor Icon. -1 = kein Bild. |
| `Enabled` | `Boolean` | `True` | False: Eintrag grau und nicht wählbar; die übrigen bleiben bedienbar. |
| `Hint` | `string` |  | Hinweis, wenn die Maus über diesem Eintrag steht (ShowHint der Gruppe muss an sein). |
| `Value` | `string` |  | Wert für Programm und Datenbank; leer = Caption. Bei der CheckGroup ergibt Value der Gruppe die Kommaliste der angehakten Werte. |
| `State` | `TCheckBoxState` | `cbUnchecked` | Nur CheckGroup: Zustand des Kästchens (cbUnchecked, cbChecked, cbGrayed mit AllowGrayed). |

## Verwendet in

[TPPGChoiceItems](TPPGChoiceItems.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
