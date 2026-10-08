# TPPGDarkColors

Typ in Unit `PPG.Appearance` - Basis `TPersistent`

Eigene Farben fuer den Dark Mode (sonst gelten dort die Preset-Farben).

Eigene Farben im Dark Mode, je Zustand als TPPGStateColors. Gesetzte Werte gelten nur im Dunkeln.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Normal` | [TPPGStateColors](TPPGStateColors.md) |  | Ruhezustand im Dunkeln. |
| `Hot` | [TPPGStateColors](TPPGStateColors.md) |  | Maus darüber im Dunkeln. |
| `Down` | [TPPGStateColors](TPPGStateColors.md) |  | Gedrückt im Dunkeln. |
| `Disabled` | [TPPGStateColors](TPPGStateColors.md) |  | Deaktiviert im Dunkeln. |
| `Checked` | [TPPGStateColors](TPPGStateColors.md) |  | „An"-Zustand (CheckBox, Radio, Schalter) im Dunkeln. |
| `Focused` | [TPPGStateColors](TPPGStateColors.md) |  | Fokus-Farben im Dunkeln. |
| `FocusColor` | `TColor` | `clDefault` | Fokusring im Dunkeln; clDefault = wie im Hellen bzw. Preset. |

## Verwendet in

[TPPGAppearance](TPPGAppearance.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
