# TPPGStateStyle

Typ in Unit `PPG.Appearance` - Basis `TPersistent`

Farben eines Zustands: Fläche als Verlauf (Color → ColorTo, bei Classic zweiteilig mit ColorMirror → ColorMirrorTo), Rand, Glow und Text.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Color` | `TColor` |  | Füllfarbe (Beginn des Verlaufs). |
| `ColorTo` | `TColor` |  | Ende des Verlaufs; gleich Color = einfarbig. |
| `ColorMirror` | `TColor` |  | Beginn der zweiten Verlaufshälfte (Glanzkante im Preset Classic). |
| `ColorMirrorTo` | `TColor` |  | Ende der zweiten Verlaufshälfte. |
| `BorderColor` | `TColor` |  | Randfarbe. |
| `GlowColor` | `TColor` |  | Farbe des Glows (ModernFlat: äußerer Schein, Classic: Lichtschein von unten). |
| `GlowAlpha` | `Byte` |  | Stärke des Glows, 0 (aus) bis 255. |
| `TextColor` | `TColor` |  | Textfarbe (auch Farbe von ImageTint und des Hakens bei Checked). |
| `GradientDirection` | `TPPGGradientDirection` |  | Richtung des Verlaufs: gdVertical (oben → unten) oder gdHorizontal (links → rechts). Werte: `gdVertical`, `gdHorizontal`. |
| `FontStyle` | `TFontStyles` | `[]` | Zusätzliche Schriftstile in diesem Zustand, z. B. [fsBold] im eingerasteten Zustand oder [fsUnderline] bei Hover. [] = Schrift des Controls. |

## Verwendet in

[TPPGAppearance](TPPGAppearance.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
