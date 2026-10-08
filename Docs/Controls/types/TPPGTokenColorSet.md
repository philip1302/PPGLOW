# TPPGTokenColorSet

Typ in Unit `PPG.StyleManager` - Basis `TPersistent`

Ueberschreibungen der Farb-Tokens fuer einen Modus (Hell oder Dunkel). clDefault = Farbe des Presets.

Ein Satz Token-Farben für Hell oder Dunkel. Jede gesetzte Farbe (≠ clDefault) ersetzt die des Presets in allen Controls; die Akzent-Varianten leitet AccentColor am StyleManager bereits automatisch ab.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Accent` | `TColor` | `clDefault` | Hauptakzent: Fokus, Auswahl, Fortschritt, eingeschaltete Schalter, Links. |
| `AccentHover` | `TColor` | `clDefault` | Akzent unter der Maus (z. B. Akzent-Button bei Hover). |
| `AccentPressed` | `TColor` | `clDefault` | Akzent beim Drücken. |
| `OnAccent` | `TColor` | `clDefault` | Text- und Symbolfarbe auf Akzentflächen (muss genug Kontrast zum Akzent haben). |
| `Background` | `TColor` | `clDefault` | Fensterhintergrund. |
| `Layer` | `TColor` | `clDefault` | Flächen von Containern, Seiten und Listen. |
| `Surface` | `TColor` | `clDefault` | Fläche eines Bedienelements in Ruhe (Button, Feld). |
| `SurfaceHover` | `TColor` | `clDefault` | Fläche unter der Maus. |
| `SurfacePressed` | `TColor` | `clDefault` | Fläche beim Drücken. |
| `SurfaceDisabled` | `TColor` | `clDefault` | Fläche im deaktivierten Zustand. |
| `Stroke` | `TColor` | `clDefault` | Normaler Rand. |
| `StrokeStrong` | `TColor` | `clDefault` | Kräftiger Rand: Unterkante, Trennlinien, Elevation. |
| `StrokeDisabled` | `TColor` | `clDefault` | Rand im deaktivierten Zustand. |
| `TextPrimary` | `TColor` | `clDefault` | Haupttextfarbe. |
| `TextSecondary` | `TColor` | `clDefault` | Nebentexte: Detailzeilen, Hinweise, Achsenbeschriftung. |
| `TextDisabled` | `TColor` | `clDefault` | Text im deaktivierten Zustand. |
| `Danger` | `TColor` | `clDefault` | Signalfarbe Fehler (Validierung, InfoBar, Toast, WIP-Überschreitung). |
| `Warning` | `TColor` | `clDefault` | Signalfarbe Warnung. |
| `Success` | `TColor` | `clDefault` | Signalfarbe Erfolg. |
| `Paused` | `TColor` | `clDefault` | Farbe angehaltener Fortschritt (ProgressBar im Zustand Paused). |

## Verwendet in

[TPPGThemeColors](TPPGThemeColors.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
