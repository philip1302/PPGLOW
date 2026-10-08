**Vorbild:** TMS TAdvFormStyler

## Unterschiede und Hinweise

- Ein Preset und eine Appearance für alle verbundenen Controls; `ThemeMode` (Hell/Dunkel/System) wirkt auch im Designer.
- `StyleForms` färbt Formulare mit den neutralen Windows-11-Farben (nur zur Laufzeit).
- Verb „Apply preset to form...“ setzt das Preset aller Controls des Formulars.

## Anpassung

- `AccentColor`: Markenfarbe für alle Presets (Fokus, Auswahl, Fortschritt, Schalter, Links); der Kontrast wird geprüft.
- `ThemeColors.Light`/`ThemeColors.Dark`: einzelne Tokens überschreiben (Flächen, Text, Rand, Signalfarben). `ChartPalette`: eigene Serienfarben (eine Farbe je Zeile).
- `SaveToFile`/`LoadFromFile` (INI `[PPGlowTheme]`): Firmen-Design weitergeben. Eine fehlerhafte Datei lässt den Manager unverändert.
