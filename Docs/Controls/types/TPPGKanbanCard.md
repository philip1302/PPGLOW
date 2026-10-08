# TPPGKanbanCard

Typ in Unit `PPG.Kanban.Items` - Basis `TCollectionItem`

Eine Karte: Titel, Text, Labels, Person, Fälligkeit, Fortschritt, Farbe sowie Spalte und Swimlane.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Id` | `Integer` |  | Eindeutige Nummer der Karte; wird fortlaufend vergeben. |
| `Title` | `string` |  | Titel der Karte (fett, erste Zeile). |
| `Text` | `string` |  | Kartentext mit Markup (<b>, <i>, <color=...>), höchstens Board.MaxTextLines Zeilen. |
| `ColumnId` | `Integer` | `0` | Id der Spalte, in der die Karte liegt. |
| `LaneId` | `Integer` | `0` | Id der Swimlane der Karte (nur mit Lanes). |
| `Labels` | `string` |  | Plaketten, durch Komma getrennt („Bug, UI"); jede wird als farbige Marke gezeigt. |
| `Assignee` | `string` |  | Name der zuständigen Person; die Karte zeigt die Initialen in einem runden Symbol. |
| `Due` | `TDateTime` |  | Fälligkeitsdatum; 0 = keins. Überfällige Karten werden hervorgehoben. |
| `Progress` | `Integer` | `-1` | Fortschritt in Prozent (0 bis 100) als Balken auf der Karte; -1 = keine Anzeige. |
| `Color` | `TColor` | `clNone` | Farbe des Streifens am Kartenrand; clNone = kein Streifen. |
| `Tag` | `NativeInt` | `0` | Freier Ganzzahlwert der Anwendung. |

## Verwendet in

[TPPGKanbanCards](TPPGKanbanCards.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
