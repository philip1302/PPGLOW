# TPPGKanbanLane

Typ in Unit `PPG.Kanban.Items` - Basis `TCollectionItem`

Eine Swimlane: Titel, Sichtbarkeit, eingeklappt und eine feste Id für die Zuordnung der Karten.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Id` | `Integer` |  | Eindeutige Nummer der Swimlane; Karten verweisen über LaneId darauf. |
| `Title` | `string` |  | Titel im Kopf der Swimlane. |
| `Collapsed` | `Boolean` | `False` | True: Die Swimlane ist eingeklappt (nur der Kopf ist sichtbar). |
| `Visible` | `Boolean` | `True` | False: Die Swimlane wird ausgeblendet. Sind alle ausgeblendet, zeigt das Board keine Swimlanes. |
| `Key` | `string` |  | Wert im Swimlane-Feld der Datenbank (DB-Kanban, LaneField); leer = die Id als Text. |
| `Tag` | `NativeInt` | `0` | Freier Ganzzahlwert der Anwendung. |

## Verwendet in

[TPPGKanbanLanes](TPPGKanbanLanes.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
