# TPPGEditButton

Typ in Unit `PPG.Edit` - Basis `TPersistent`

Button links oder rechts im Feld (Bild aus Images des Felds).

Ein Knopf im Eingabefeld (links oder rechts): Symbol, Sichtbarkeit, Hint und optional ein Menü.

Nutzung: `Edit1.RightButton.Visible := True; Edit1.RightButton.DropDownMenu := PopupMenu1;`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `DropDownMenu` | `TPopupMenu` |  | Menü, das beim Klick auf den Knopf unter dem Feld aufklappt (z. B. Auswahl von Suchbereichen). |
| `Enabled` | `Boolean` | `True` | False: Der Knopf ist sichtbar, aber grau und nicht klickbar. |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Bild des Knopfes aus Images des Felds; -1 = kein Bild. |
| `Visible` | `Boolean` | `False` | True: Der Knopf wird im Feld angezeigt (Vorgabe False). |

## Verwendet in

[TPPGDBEdit](../TPPGDBEdit.md), [TPPGEdit](../TPPGEdit.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
