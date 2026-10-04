# Phase 8 – Detailplan: Modernes Design (Fluent / Windows 11)

*Stand 03.10.2026. Vom User vorgezogen (vor Phase 6), damit ListBox, TreeView und Grid gleich im neuen Design entstehen. Teil der Roadmap (`Docs\Roadmap.md`).*

## Status
- **8.1 Tokens: fertig (03.10.2026).**
  - `PPG.Tokens`, `IPPGThemeRenderer`, Tokens Hell/Dunkel für ModernFlat und Classic.
  - Signalfarben in Feld und ProgressBar kommen aus den Tokens.
  - WCAG-Kontrasttest für alle Presets; 304 Tests grün.
  - Die Hell-Farben sind unverändert.
- **8.2 `Fluent11`: fertig (04.10.2026).**
  - `PPG.Render.Fluent11`: kein Glow, Rand mit dunklerer Unterkante, Doppel-Fokusring außerhalb des Körpers (Abstand = `GlowSize`, Standard 3 px), kräftiger Rand an Kästchen/Kreis/Schalter.
  - Akzent aus `AccentPalette` (Hell = AccentDark1, Dunkel = AccentLight2), sonst DWM-`AccentColor`, sonst Windows-Blau; Kontrast wird erzwungen (Hell 4,5:1 zu Weiß, Dunkel 7:1 zu Schwarz). `TPPGFluent11Renderer.AccentOverride` setzt eine feste Markenfarbe.
  - Abweichung von WinUI: Der Druck-Zustand behält den dunklen Text und bekommt einen kräftigeren Rand, weil er auch der eingerastete Toggle-Button ist.
  - Demo-Schalter `/preset Name`. 313 Tests grün, Win32/Win64.
- **8.3 Dark Mode: fertig (04.10.2026).** `PPG.Theme` (`TPPGTheme.Mode` Hell/Dunkel/System, Hilfsfenster für `WM_SETTINGCHANGE`, `StyleForms` mit dunkler Titelleiste und Wiederherstellung der Originalfarben), `UseDarkMode`/`EffectiveAppearance` in der Basis, Felder mit Token-Farben und eigener Textfarbe des inneren Edits, dunkle Memo-Scrollleisten, `TPPGStyleManager.ThemeMode`/`StyleForms`. Leere Kästchen/Kreise bekommen auf dunklen Flächen mindestens 3:1 Randkontrast.
- **8.5 Bewegungskurven: fertig (04.10.2026).** `TPPGEasing` (ekSmooth, ekDecelerate, ekLinear), `PPGEase`, `AnimateTo(…, Easing)`. Aufklappen, Unterstrich, Scrollen und Fokuslinie nutzen ekDecelerate.
- **8.6 Fluent-Icons: fertig (04.10.2026).** `PPG.IconFont` (Segoe Fluent Icons, sonst Segoe MDL2 Assets, sonst Linien). Fluent11 nutzt sie für Haken, Chevrons, Löschen, Schließen und Blätterpfeile.
- **8.4 Mica: Prototyp ausgewertet (04.10.2026), kommt nicht in die Suite.** Ergebnis siehe Abschnitt „Mica-Prototyp“ in `Docs\Architektur.md`.
- **Phase 8 ist damit abgeschlossen.** 333 Tests grün, Win32/Win64, Benchmark eingehalten.

## Ziel
- Ein Windows-11-Preset `Fluent11`.
- Dark Mode **ohne** VCL-Style, umschaltbar Hell/Dunkel/System.
- Zentrale Design-Tokens als Quelle aller Preset-Farben.
- Einheitliche Bewegungskurven.
- Fluent-Icons.

Bestehende DFMs bleiben unverändert gültig: Das Standard-Preset bleibt `ModernFlat`, und die gespeicherte `Appearance` ändert sich durch den Dark Mode nicht.

## Bausteine

| Schritt | Unit | Inhalt |
|---|---|---|
| 8.1 Tokens | `Core\PPG.Tokens` | `TPPGTokens` (Record) mit semantischen Farben: Accent, AccentHover, AccentPressed, OnAccent, Surface, SurfaceHover, SurfacePressed, SurfaceDisabled, Layer (Container/Seite), Background (Fenster), Stroke, StrokeStrong, TextPrimary, TextSecondary, TextDisabled, Danger, Warning, Success. Dazu Maße (RadiusSmall/Medium/Large, StrokeWidth) und Bewegung (DurationFast/Normal/Slow). Jedes Preset liefert Tokens für Hell und Dunkel (`IPPGThemeRenderer.Tokens(Dark)`) und leitet daraus seine Appearance ab (`ApplyThemeColors(Appearance, Dark)`) |
| 8.2 Preset `Fluent11` | `Render\PPG.Render.Fluent11` | Radius 4/8, 1-px-Rand mit dunklerer Unterkante (Elevation), Fokus als Doppelring (außen dunkel, innen hell, wie Windows 11), Akzent aus dem System (`HKCU\Software\Microsoft\Windows\DWM\AccentColor`, sonst Standard-Blau), Hover/Pressed als feine Flächenwechsel ohne Glow |
| 8.3 Dark Mode | `Theme\PPG.Theme` (`TPPGTheme`) | `Mode` = tmLight/tmDark/tmSystem. „System“ folgt `AppsUseLightTheme` und reagiert auf `WM_SETTINGCHANGE` („ImmersiveColorSet“) über ein unsichtbares Hilfsfenster. Beim Wechsel werden alle PPGlow-Controls benachrichtigt (`ThemeChanged`). Optional `StyleForms`: Formularfarbe, Schriftfarbe und dunkle Titelleiste (`DWMWA_USE_IMMERSIVE_DARK_MODE`). `TPPGStyleManager.ThemeMode` setzt den Modus auch im Designer |
| Rangfolge | `PPG.Controls.Base` | **Hochkontrast > VCL-Style > Dark Mode > Appearance**. `EffectiveAppearance` liefert im Dark Mode eine Kopie mit den Farben des Presets im dunklen Modus, Formen bleiben (wie beim VCL-Style). Felder, Listen, Seiten und Scrollleisten holen Flächen- und Textfarben aus den Tokens statt aus `clWindow`/`clWindowText` (die bleiben im Dark Mode hell) |
| 8.5 Bewegung | `Core\PPG.Animation` | Kurven `ekSmooth` (bisher), `ekDecelerate` (Fluent: schnell starten, weich enden), `ekLinear`; `AnimateTo(..., Easing)`. Aufklappen, Unterstrich, Scrollen und Fokuslinie nutzen `ekDecelerate`. `RespectSystemSettings` gilt weiter |
| 8.6 Icons | `Render\PPG.IconFont` | Glyphen aus „Segoe Fluent Icons“ (Windows 11), sonst „Segoe MDL2 Assets“ (Windows 10), sonst die bisherigen Polylinien. Genutzt von `Fluent11` für Pfeile, Löschen und Blättern |
| 8.4 Mica (Prototyp) | Demo | Untersuchen, ob `DWMWA_SYSTEMBACKDROP_TYPE` mit PPGlow-Flächen nutzbar ist. Bekannter Fallstrick: GDI-Text auf transparentem Grund wird schwarz. Ergebnis wird dokumentiert, in die Suite kommt es erst nach einem tragfähigen Prototyp |

## Bewusste Entscheidungen
- `Appearance` bleibt die Anpassungsschicht pro Control (DFM-kompatibel). Die Tokens sind die Quelle der Preset-Vorgaben und aller Farben, die bisher hart verdrahtet waren (Systemfarben). Ein kompletter Umbau aller 21 Controls auf „nur Tokens“ würde DFMs brechen.
- Selbst gesetzte Farben gelten im Dark Mode nicht; es gelten die Preset-Farben (wie bei VCL-Styles). Wer das pro Control nicht will, entfernt `seClient` aus `StyleElements` (ab XE3), wie beim VCL-Style.
- Der Dark Mode ist anwendungsweit (`TPPGTheme`), nicht pro Formular.

## Tests (`Tests\PPG.Tests.Phase8.pas`)
- Tokens: Hell und Dunkel je Preset unterschiedlich; Kontrast Text/Fläche ≥ 4,5:1.
- Dark Mode: Farben dunkel, `Appearance` unverändert und nicht gespeichert; Umschalten erreicht alle Controls (auch innere Edits und offene Popups); System-Modus über eine Test-Schnittstelle.
- `Fluent11`: registriert; Doppel-Fokusring als Pixeltest; Akzent aus der Systemfarbe.
- Kurven: Anfang und Ende 0/1, `ekDecelerate` liegt über `ekSmooth`.
- Icon-Fallback ohne Icon-Schrift.
- `StyleForms`: Formularfarbe; die Titelleiste läuft ohne Fehler.
- Alle Controls in allen Presets, Hell/Dunkel, mit und ohne GDI zeichnen ohne Fehler.

## Demo
- Umschalter Hell/Dunkel/System.
- `Fluent11` in den Preset-Listen.
- Schalter `/theme dark` und `/preset Fluent11` für Screenshots.
