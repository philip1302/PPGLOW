# TPPGThemeColors

Typ in Unit `PPG.StyleManager` - Basis `TPersistent`

Token-Ueberschreibungen fuer Hell und Dunkel.

Token-Farben des Themes überschreiben, getrennt für Hell (Light) und Dunkel (Dark). Nur gesetzte Werte (≠ clDefault) gelten, für alle Presets.

Nutzung: `PPGStyleManager1.ThemeColors.Light.Danger := $002020C0;`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Light` | [TPPGTokenColorSet](TPPGTokenColorSet.md) |  | Token-Farben, die nur im hellen Modus gelten (clDefault = vom Preset). |
| `Dark` | [TPPGTokenColorSet](TPPGTokenColorSet.md) |  | Token-Farben, die nur im Dark Mode gelten (clDefault = vom Preset). Nutzung: `PPGStyleManager1.ThemeColors.Dark.Surface := $00202020;` |

## Verwendet in

[TPPGStyleManager](../TPPGStyleManager.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
