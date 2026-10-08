# TPPGMenuStyles

Typ in Unit `PPG.Menus` - Basis `TPPGStyleGroup`

Bereiche der Menues (nur gesetzte Werte zaehlen, clDefault = Preset).

Bereiche der Menüs einzeln gestalten: Menüfläche, Eintrag unter der Maus, Trennlinie und Tastenkürzel.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Menu` | [TPPGElementStyle](TPPGElementStyle.md) |  | Das ganze Menü: Fläche (Color), Text (TextColor), Rand (BorderColor) und Schrift. |
| `HotItem` | [TPPGElementStyle](TPPGElementStyle.md) |  | Eintrag unter der Maus bzw. per Tastatur markiert: Fläche (Color) und Text (TextColor). |
| `Separator` | [TPPGElementStyle](TPPGElementStyle.md) |  | Trennlinien zwischen Eintragsgruppen (Color). |
| `Shortcut` | [TPPGElementStyle](TPPGElementStyle.md) |  | Tastenkürzel rechts im Eintrag (z. B. „Strg+S"): Textfarbe und Schrift. |

## Verwendet in

[TPPGMenuBar](../TPPGMenuBar.md), [TPPGPopupMenu](../TPPGPopupMenu.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
