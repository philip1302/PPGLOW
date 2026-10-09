# TPPGStyleManager

Palette **PPGlow** - Unit `PPG.StyleManager` - Basis `TComponent`

**Vorbild:** TMS TAdvFormStyler

## Unterschiede und Hinweise

- Ein Preset und eine Appearance für alle verbundenen Controls; `ThemeMode` (Hell/Dunkel/System) wirkt auch im Designer.
- `StyleForms` färbt Formulare mit den neutralen Windows-11-Farben (nur zur Laufzeit).
- Verb „Apply preset to form...“ setzt das Preset aller Controls des Formulars.

## Anpassung

- `AccentColor`: Markenfarbe für alle Presets (Fokus, Auswahl, Fortschritt, Schalter, Links); der Kontrast wird geprüft.
- `ThemeColors.Light`/`ThemeColors.Dark`: einzelne Tokens überschreiben (Flächen, Text, Rand, Signalfarben). `ChartPalette`: eigene Serienfarben (eine Farbe je Zeile).
- `SaveToFile`/`LoadFromFile` (INI `[PPGlowTheme]`): Firmen-Design weitergeben. Eine fehlerhafte Datei lässt den Manager unverändert.

## Verhalten (aus dem Quelltext)

Zentrales Theme fuer beliebig viele PPGlow-Controls (Observer-Muster).

Lebenszyklus-Regeln:
- Clients werden als TComponent gehalten (NIE als Interface-Referenz: TComponent zaehlt keine Referenzen -> haengende Zeiger).
- FreeNotification in beide Richtungen: wird ein Client oder der Manager freigegeben, raeumt Notification(opRemove) die Referenzen auf.
- Benachrichtigt wird ueber ein kurzlebiges IPPGStyleClient (Supports), dadurch kennt diese Unit keine Control-Klassen (keine Zyklen).

Marke / Firmen-Design (AccentColor, ThemeColors, ChartPalette):
- Die Werte gelten anwendungsweit fuer ALLE PPGlow-Controls (wie ThemeMode, ueber TPPGTokenOverrides). Mehrere Manager: der zuletzt geaenderte bzw. geladene Manager mit eigenen Werten gilt.
- Aendert sich AccentColor oder ThemeColors.Light (nicht beim Laden), werden die Farben der eigenen Appearance aus den Tokens neu abgeleitet (ApplyThemeColors); die Formen (Rundung, Glow ...) bleiben.
- SaveToFile/LoadFromFile: Theme-Datei (INI) mit allen Einstellungen.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage aller verbundenen Controls (Classic, ModernFlat, Fluent11). |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Gemeinsame Appearance aller verbundenen Controls; wird beim Preset-Wechsel und bei geänderten Theme-Farben neu abgeleitet. |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Animationseinstellungen für alle verbundenen Controls (an/aus, Dauer, Systemeinstellung beachten). |
| `ThemeMode` | `TPPGThemeMode` | `tmLight` | Hell (tmLight), Dunkel (tmDark) oder wie Windows (tmSystem) für alle PPGlow-Controls der Anwendung, auch im Designer. Bei mehreren Managern gilt der zuletzt gesetzte. Werte: `tmLight`, `tmDark`, `tmSystem`. |
| `StyleForms` | `Boolean` | `False` | True: Formulare werden zur Laufzeit in den neutralen Farben des Modus gefärbt, im Dunkeln mit dunkler Titelleiste. |
| `AccentColor` | `TColor` | `clDefault` | Markenfarbe der Anwendung: Akzent für Fokus, Auswahl, Fortschritt, Schalter, Links und Diagramme in allen Presets und in Hell und Dunkel (Hover-/Gedrückt-Varianten werden mit Kontrastprüfung abgeleitet). clDefault = Akzent des Presets bzw. des Systems (Fluent11). Nutzung: `PPGStyleManager1.AccentColor := $00B05A8E;` |
| `ThemeColors` | [TPPGThemeColors](types/TPPGThemeColors.md) |  | Einzelne Theme-Farben (Tokens) getrennt für Hell (Light) und Dunkel (Dark) überschreiben: Akzent, Flächen, Text, Rand, Signalfarben. Nur gesetzte Werte gelten; sie gehen AccentColor vor. Speichern/Laden mit SaveToFile/LoadFromFile. Nutzung: `PPGStyleManager1.ThemeColors.Light.Danger := $002020C0;` |
| `ChartPalette` | `TStrings` |  | Diagramm- und Kategorienfarben in dieser Reihenfolge, eine Farbe je Zeile („#RRGGBB" oder Farbname wie clNavy). Leer = Palette des Presets. Im Dunkeln werden zu dunkle Farben aufgehellt. Nutzung: `PPGStyleManager1.ChartPalette.Text := '#0F6CBD'#13#10'#C239B3'#13#10'clGreen';` |

Tests: `PPG.Tests.Controls` (TLifecycleTests, TResourceTests, TStyleTests); `PPG.Tests.Custom` (TCustomThemeTests); `PPG.Tests.Phase8` (TThemeTests); `PPG.Tests.Phase9a` (TPresetTargetTests); `PPG.Tests.Review` (TReviewTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGStyleManager.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
