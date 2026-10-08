# TPPGPlannerStyles

Typ in Unit `PPG.Planner` - Basis `TPPGStyleGroup`

Bereiche des Planers (nur gesetzte Werte zaehlen, clDefault = Preset).

Bereiche des Planers einzeln gestalten: Kopf, Zeitleiste, Arbeitszeit, Freizeit, Heute, Jetzt-Linie, Termine und Auswahl.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Background` | [TPPGElementStyle](TPPGElementStyle.md) |  | Hintergrund: Color = Fläche, TextColor = Text, BorderColor = Rasterlinien. |
| `Header` | [TPPGElementStyle](TPPGElementStyle.md) |  | Kopf mit Tagen und Ressourcen: Color, TextColor, Schrift. |
| `TimeRuler` | [TPPGElementStyle](TPPGElementStyle.md) |  | Zeitleiste mit den Uhrzeiten: TextColor und Schrift. |
| `NonWorkHours` | [TPPGElementStyle](TPPGElementStyle.md) |  | Zeit außerhalb der Arbeitszeit und freie Tage: Color = Hinterlegung. |
| `Today` | [TPPGElementStyle](TPPGElementStyle.md) |  | Heute: TextColor = Tageskopf, BorderColor = Markierung des Tages. |
| `NowLine` | [TPPGElementStyle](TPPGElementStyle.md) |  | Jetzt-Linie: Color. |
| `Appointment` | [TPPGElementStyle](TPPGElementStyle.md) |  | Termine: TextColor und Schrift (die Fläche kommt aus Kategorie, Ressource bzw. OnGetAppointmentColor). |
| `SelectedSlot` | [TPPGElementStyle](TPPGElementStyle.md) |  | Gewählte Zeitfelder: Color. |

## Verwendet in

[TPPGDBPlanner](../TPPGDBPlanner.md), [TPPGPlanner](../TPPGPlanner.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
