# TPPGItem

Typ in Unit `PPG.Items` - Basis `TCollectionItem`

Ein Eintrag: Text, Detailzeile, Plakette, Gruppe, Bild, Kästchen-Zustand, Enabled sowie eigene Farbe, Textfarbe und Schriftstil.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Text` | `string` |  | Haupttext des Eintrags; mit AllowMarkup der Liste auch mit <b>, <i>, <color=...>. |
| `Detail` | `string` |  | Zweite, kleinere Zeile unter dem Text (Optik über Styles.Detail); leer = einzeilig. |
| `Badge` | `string` |  | Kurzer Text in einer Plakette rechts im Eintrag (z. B. Anzahl ungelesener Nachrichten); leer = keine Plakette. |
| `Group` | `string` |  | Gruppenname: Aufeinanderfolgende Einträge mit derselben Gruppe erhalten eine gemeinsame Überschrift (Optik über Styles.GroupHeader). |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Bild aus Images der Liste; -1 = kein Bild. |
| `Checked` | `TCheckBoxState` | `cbUnchecked` | Zustand des Kästchens (CheckListBox): cbUnchecked, cbChecked oder cbGrayed. |
| `Enabled` | `Boolean` | `True` | False: Der Eintrag ist grau und nicht wählbar. |
| `Tag` | `NativeInt` | `0` | Freier Ganzzahlwert, z. B. eine Datensatz-ID. |
| `Color` | `TColor` | `clDefault` | Eigene Fläche dieses Eintrags; clDefault = wie die Liste. Gilt hell und dunkel; Auswahl und Hover liegen darüber. |
| `TextColor` | `TColor` | `clDefault` | Eigene Textfarbe dieses Eintrags; clDefault = wie die Liste. |
| `FontStyle` | `TFontStyles` | `[]` | Zusätzliche Schriftstile für diesen Eintrag, z. B. [fsBold] für ungelesene Einträge. |

## Verwendet in

[TPPGItems](TPPGItems.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
