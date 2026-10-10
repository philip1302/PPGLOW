# TPPGDarkColors

Typ in Unit `PPG.Appearance` - Basis `TPersistent`

Eigene Farben fuer den Dark Mode (sonst gelten dort die Preset-Farben).

Eigene Farben im Dark Mode, je Zustand als TPPGStateColors. Gesetzte Werte gelten nur im Dunkeln.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Normal` | [TPPGStateColors](TPPGStateColors.md) |  | Ruhezustand im Dunkeln. Praxis: Ruhe-Optik im Dark Mode für selbst eingefärbte Buttons, z. B. ein dunkleres Rot für „Löschen". |
| `Hot` | [TPPGStateColors](TPPGStateColors.md) |  | Maus darüber im Dunkeln. Praxis: Hover-Optik im Dark Mode; meist etwas heller als Dark.Normal. |
| `Down` | [TPPGStateColors](TPPGStateColors.md) |  | Gedrückt im Dunkeln. Praxis: Gedrückt-Optik im Dark Mode. |
| `Disabled` | [TPPGStateColors](TPPGStateColors.md) |  | Deaktiviert im Dunkeln. Praxis: Gesperrt-Optik im Dark Mode. |
| `Checked` | [TPPGStateColors](TPPGStateColors.md) |  | „An"-Zustand (CheckBox, Radio, Schalter) im Dunkeln. Praxis: Eingerastet-Optik im Dark Mode. |
| `Focused` | [TPPGStateColors](TPPGStateColors.md) |  | Fokus-Farben im Dunkeln. Praxis: Fokus-Optik im Dark Mode. |
| `FocusColor` | `TColor` | `clDefault` | Fokusring im Dunkeln; clDefault = wie im Hellen bzw. Preset. Praxis: Farbe des Fokusrings im Dark Mode; hell wählen, damit er auf dunklem Grund sichtbar ist. |

## Verwendet in

[TPPGAppearance](TPPGAppearance.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
