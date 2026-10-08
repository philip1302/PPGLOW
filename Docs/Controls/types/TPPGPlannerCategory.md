# TPPGPlannerCategory

Typ in Unit `PPG.Planner` - Basis `TCollectionItem`

Kategorie (wie Outlook): Name und Farbe; Appointment.Category = Index.

Eine Kategorie: Name und Farbe.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Caption` | `string` |  | Name der Kategorie (z. B. „Kunde", „Privat"). |
| `Color` | `TColor` | `clDefault` | Farbe der Termine dieser Kategorie; clDefault = Farbe aus der Diagrammpalette (je nach Index). |

## Verwendet in

[TPPGPlannerCategories](TPPGPlannerCategories.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
