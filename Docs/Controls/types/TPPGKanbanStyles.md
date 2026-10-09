# TPPGKanbanStyles

Typ in Unit `PPG.Kanban` - Basis `TPPGStyleGroup`

Bereiche des Boards (nur gesetzte Werte zaehlen, clDefault = Preset).

Bereiche des Boards einzeln gestalten: Spalte, Karte, Karte unter der Maus, gewählte Karte und Swimlane-Kopf.

Nutzung: `PPGKanban1.Styles.Card.Color := clWhite;`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Column` | [TPPGElementStyle](TPPGElementStyle.md) |  | Spalten: Color = Hintergrund, TextColor = Titel, Font bzw. FontStyle = Schrift des Titels. |
| `Card` | [TPPGElementStyle](TPPGElementStyle.md) |  | Karten: Color = Fläche, TextColor = Text, BorderColor = Rand, Font bzw. FontStyle = Schrift des Titels. |
| `HotCard` | [TPPGElementStyle](TPPGElementStyle.md) |  | Karte unter der Maus: Color = Fläche. |
| `SelectedCard` | [TPPGElementStyle](TPPGElementStyle.md) |  | Gewählte Karte: BorderColor = Rand der Auswahl. |
| `LaneHeader` | [TPPGElementStyle](TPPGElementStyle.md) |  | Köpfe der Swimlanes: TextColor und Schrift. |

## Verwendet in

[TPPGDBKanban](../TPPGDBKanban.md), [TPPGKanban](../TPPGKanban.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
