# TPPGPlannerResource

Typ in Unit `PPG.Planner` - Basis `TCollectionItem`

Eine Ressource: Name, Farbe und Id, auf die Termine verweisen.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Id` | `Integer` |  | Nummer der Ressource; entspricht TPPGAppointment.ResourceId. |
| `Caption` | `string` |  | Name der Ressource (Person, Raum, Gerät) im Spaltenkopf bzw. in der Zeile der Zeitleiste. |
| `Color` | `TColor` | `clDefault` | Farbe der Termine dieser Ressource ohne Kategorie; clDefault = Akzent. |

## Verwendet in

[TPPGPlannerResources](TPPGPlannerResources.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
