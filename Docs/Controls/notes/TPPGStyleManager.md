**Vorbild:** TMS TAdvFormStyler

## Unterschiede und Hinweise

- Ein Preset und eine Appearance für alle verbundenen Controls; `ThemeMode` (Hell/Dunkel/System) wirkt auch im Designer.
- `StyleForms` färbt Formulare mit den neutralen Windows-11-Farben (nur zur Laufzeit).
- Verb „Apply preset to form...“ setzt das Preset aller Controls des Formulars.

## Anpassung

- `AccentColor`: Markenfarbe für alle Presets (Fokus, Auswahl, Fortschritt, Schalter, Links); der Kontrast wird geprüft.
- `ThemeColors.Light`/`ThemeColors.Dark`: einzelne Tokens überschreiben (Flächen, Text, Rand, Signalfarben). `ChartPalette`: eigene Serienfarben (eine Farbe je Zeile).
- `SaveToFile`/`LoadFromFile` (INI `[PPGlowTheme]`): Firmen-Design weitergeben. Eine fehlerhafte Datei lässt den Manager unverändert.

## Verwaltete Properties der Clients

- Solange an einer Komponente `StyleManager` gesetzt ist, verwaltet der Manager ihre Optik-Properties: bei allen Controls `Preset`, `Appearance` und `Animation` (genau das, was der Manager beim Zuweisen und bei jeder Änderung überschreibt), bei `TPPGPopupMenu`, `TPPGHintManager`, `TPPGCustomHint`, `TPPGTeachingTip`, `TPPGTaskDialog`, `TPPGNotificationCenter` und `TPPGBusyOverlay` das `Preset`. Die `Animation` des NotificationCenters (Ein- und Ausblenden der Toasts) bleibt eigene Einstellung.
- Objektinspektor: Diese Properties sind ausgeblendet, solange der Manager gesetzt ist; nach dem Leeren erscheinen sie sofort wieder. Bei Mehrfachauswahl werden sie nur ausgeblendet, wenn alle markierten Komponenten einen Manager haben.
- DFM: Mit Manager werden sie nicht gespeichert. Ältere DFMs, die solche Werte noch enthalten, laden wie bisher (der Manager überschreibt sie); beim nächsten Speichern fallen sie heraus. Ohne Manager ändert sich am Speichern nichts.
- Zur Laufzeit bleibt alles wie bisher: Zuweisungen im Code sind möglich, der Manager überschreibt sie bei seiner nächsten Änderung.
- Die Regel steht an einer Stelle: `PPGIsStyleManagedProperty(Komponente, 'Appearance')` (Unit `PPG.StyleManager`); Designer und Streaming fragen nur sie.
