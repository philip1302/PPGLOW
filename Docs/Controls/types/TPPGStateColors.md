# TPPGStateColors

Typ in Unit `PPG.Appearance` - Basis `TPersistent`

Einzelne Farb-Ueberschreibungen fuer einen Zustand (Fokus, Dunkel). clDefault = nicht ueberschreiben. Color ohne ColorTo/Mirror faerbt die ganze Flaeche einfarbig.

Optionale Farben eines Zustands: nur Werte ≠ clDefault überschreiben, alle anderen kommen aus dem Preset bzw. dem Zustand.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Color` | `TColor` | `clDefault` | Füllfarbe; clDefault = nicht überschreiben. |
| `ColorTo` | `TColor` | `clDefault` | Ende des Verlaufs; clDefault = nicht überschreiben. |
| `ColorMirror` | `TColor` | `clDefault` | Zweite Verlaufshälfte (Classic); clDefault = nicht überschreiben. |
| `ColorMirrorTo` | `TColor` | `clDefault` | Ende der zweiten Verlaufshälfte; clDefault = nicht überschreiben. |
| `BorderColor` | `TColor` | `clDefault` | Randfarbe; clDefault = nicht überschreiben. |
| `GlowColor` | `TColor` | `clDefault` | Glow-Farbe; clDefault = nicht überschreiben. |
| `TextColor` | `TColor` | `clDefault` | Textfarbe; clDefault = nicht überschreiben. |
| `FontStyle` | `TFontStyles` | `[]` | Zusätzliche Schriftstile. |

## Verwendet in

[TPPGAppearance](TPPGAppearance.md), [TPPGDarkColors](TPPGDarkColors.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
