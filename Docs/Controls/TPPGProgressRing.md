# TPPGProgressRing

Palette **PPGlow** - Unit `PPG.Feedback` - Basis `TPPGCustomProgressRing`

**Vorbild:** WinUI ProgressRing

## Unterschiede und Hinweise

- Bestimmt (0–100) oder unbestimmt (`Indeterminate`); läuft nur, wenn sichtbar.

## Verhalten (aus dem Quelltext)

Rueckmelde-Controls (Phase 7a): TPPGBadge, TPPGProgressRing, TPPGInfoBar.

- TPPGBadge: Punkt, Zahl (99+) oder kurzer Text auf Akzent- bzw. Signalfarbe (Tokens; Dark Mode automatisch). Zeichnet ueber IPPGItemRenderer.DrawBadge wie die Plaketten in Listen.
- TPPGProgressRing: bestimmt (Bogen 0-100 %) oder unbestimmt (rotierender Bogen mit wechselnder Laenge). Die Endlosschleife laeuft ueber den gemeinsamen Animator und nur, solange das Control sichtbar ist; ohne Animationen steht ein Viertelbogen.
- TPPGInfoBar: Hinweisleiste Info/Erfolg/Warnung/Fehler mit Symbol, Titel, Text (Markup), optionalem Aktions-Button und Schliessen-Knopf. Button und Knopf sind gezeichnet (keine Kind-Fenster); Tastatur: Pfeile wechseln, Enter/Leertaste loest aus, Esc schliesst. Screenreader: Rolle Alarm, Meldung beim Oeffnen.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `HighContrastSupport`, `Indeterminate`, `Value`, `Thickness`, `ShowTrack`, `Align`, `Anchors`, `Enabled`, `ParentShowHint`, `ShowHint`, `Visible`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGProgressRing.md`.
