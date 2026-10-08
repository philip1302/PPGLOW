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

`Preset`, `Appearance`, `Animation`, `ThemeMode`, `StyleForms`, `AccentColor`, `ThemeColors`, `ChartPalette`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGStyleManager.md`.
