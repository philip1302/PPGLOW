# TPPGEditButton

Typ in Unit `PPG.Edit` - Basis `TPersistent`

Button links oder rechts im Feld (Bild aus Images des Felds).

Ein Knopf im Eingabefeld (links oder rechts): Symbol, Sichtbarkeit, Hint und optional ein Menü.

Nutzung: `Edit1.RightButton.Visible := True; Edit1.RightButton.DropDownMenu := PopupMenu1;`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `DropDownMenu` | `TPopupMenu` |  | Menü, das beim Klick auf den Knopf unter dem Feld aufklappt (z. B. Auswahl von Suchbereichen). Praxis: Für Varianten zum Feld, z. B. „Suchen in: Name / Ort“ oder zuletzt verwendete Werte. Ohne Bild zeigt der Knopf dann einen Pfeil. |
| `Enabled` | `Boolean` | `True` | False: Der Knopf ist sichtbar, aber grau und nicht klickbar. Praxis: Den Knopf sperren, solange seine Aktion nicht geht, z. B. „E-Mail schreiben“ nur bei gültiger Adresse. |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Bild des Knopfes aus Images des Felds; -1 = kein Bild. Praxis: Symbol aus Images des Felds, das die Aktion zeigt (Brief, Lupe, Person). -1 lassen, wenn der Knopf nur ein Menü öffnet; dann erscheint ein Pfeil. |
| `Visible` | `Boolean` | `False` | True: Der Knopf wird im Feld angezeigt (Vorgabe False). Praxis: Einschalten, um den Knopf zu zeigen; per Code ausblenden, wenn die Aktion für den Datensatz nicht gilt. |

## Verwendet in

[TPPGDBEdit](../TPPGDBEdit.md), [TPPGEdit](../TPPGEdit.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
