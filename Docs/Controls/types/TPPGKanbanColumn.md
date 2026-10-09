# TPPGKanbanColumn

Typ in Unit `PPG.Kanban.Items` - Basis `TCollectionItem`

Eine Spalte: Titel, WIP-Limit, Farbe, Breite, eingeklappt und eine feste Id für die Zuordnung der Karten.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Id` | `Integer` |  | Eindeutige Nummer der Spalte; Karten verweisen über ColumnId darauf. |
| `Title` | `string` |  | Titel im Spaltenkopf. |
| `Color` | `TColor` | `clDefault` | Farbe der Kopfleiste der Spalte; clNone = Akzent des Presets. |
| `WipLimit` | `Integer` | `0` | Höchstzahl der Karten (0 bis 9999; 0 = ohne Limit). Darüber wird die Spalte als Warnung gefärbt bzw. bei WipMode = kwmBlock gesperrt. |
| `Collapsed` | `Boolean` | `False` | True: Die Spalte ist eingeklappt (schmaler Streifen mit senkrechtem Titel). Der Anwender schaltet über den Pfeil im Kopf um. |
| `Width` | `Integer` | `0` | Eigene Breite der Spalte in logischen Pixeln (80 bis 2000); 0 = Board.ColumnWidth. |
| `Visible` | `Boolean` | `True` | False: Die Spalte wird ausgeblendet. |
| `VirtualCount` | `Integer` | `0` | > 0: virtuelle Spalte mit so vielen Karten; der Inhalt kommt über OnGetCard, gezeichnet wird nur Sichtbares. Für sehr viele Karten. Nutzung: `Kanban1.Columns[0].VirtualCount := 100000;` |
| `Key` | `string` |  | Wert im Spaltenfeld der Datenbank (DB-Kanban, ColumnField); leer = die Id als Text. |
| `Tag` | `NativeInt` | `0` | Freier Ganzzahlwert der Anwendung. |

## Verwendet in

[TPPGKanbanColumns](TPPGKanbanColumns.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
