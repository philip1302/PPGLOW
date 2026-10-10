# TPPGStateStyle

Typ in Unit `PPG.Appearance` - Basis `TPersistent`

Farben eines Zustands: Fläche als Verlauf (Color → ColorTo, bei Classic zweiteilig mit ColorMirror → ColorMirrorTo), Rand, Glow und Text.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Color` | `TColor` |  | Füllfarbe (Beginn des Verlaufs). Praxis: Hauptfarbe der Fläche im jeweiligen Zustand. Für eine einfarbige Fläche Color, ColorTo, ColorMirror und ColorMirrorTo gleich setzen. |
| `ColorTo` | `TColor` |  | Ende des Verlaufs; gleich Color = einfarbig. Praxis: Zweite Farbe des Verlaufs der oberen Hälfte. Gleich Color für eine flache Fläche. |
| `ColorMirror` | `TColor` |  | Beginn der zweiten Verlaufshälfte (Glanzkante im Preset Classic). Praxis: Startfarbe der unteren Hälfte (Glanzeffekt im Classic-Stil). Gleich Color für flache Optik. |
| `ColorMirrorTo` | `TColor` |  | Ende der zweiten Verlaufshälfte. Praxis: Endfarbe der unteren Hälfte. Gleich Color für flache Optik. |
| `BorderColor` | `TColor` |  | Randfarbe. Praxis: Randfarbe. Etwas dunkler als die Fläche wirkt plastisch; gleich der Fläche wirkt flach. |
| `GlowColor` | `TColor` |  | Farbe des Glows (ModernFlat: äußerer Schein, Classic: Lichtschein von unten). Praxis: Farbe des Leuchtrands (sichtbar mit GlowSize > 0), meist die Akzentfarbe. |
| `GlowAlpha` | `Byte` |  | Stärke des Glows, 0 (aus) bis 255. Praxis: Deckkraft des Leuchtrands, 0 bis 255. 60 bis 120 wirkt dezent, 255 sehr kräftig. |
| `TextColor` | `TColor` |  | Textfarbe (auch Farbe von ImageTint und des Hakens bei Checked). Praxis: Schriftfarbe im Zustand. Auf dunklen Flächen Weiß, auf hellen Schwarz; auf ausreichenden Kontrast achten (mindestens 4,5:1). |
| `GradientDirection` | `TPPGGradientDirection` |  | Richtung des Verlaufs: gdVertical (oben → unten) oder gdHorizontal (links → rechts). Werte: `gdVertical`, `gdHorizontal`. Praxis: gdVertical für klassische Buttons (Licht von oben), gdHorizontal für breite Leisten-Buttons. |
| `FontStyle` | `TFontStyles` | `[]` | Zusätzliche Schriftstile in diesem Zustand, z. B. [fsBold] im eingerasteten Zustand oder [fsUnderline] bei Hover. [] = Schrift des Controls. Praxis: Z. B. [fsBold] im Zustand Checked, damit der aktive Umschalter auch ohne Farbe erkennbar ist. |

## Verwendet in

[TPPGAppearance](TPPGAppearance.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
