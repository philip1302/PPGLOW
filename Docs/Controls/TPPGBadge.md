# TPPGBadge

Palette **PPGlow** - Unit `PPG.Feedback` - Basis `TPPGCustomBadge`

**Vorbild:** WinUI InfoBadge

## Unterschiede und Hinweise

- Zahl (mit `MaxValue` → „99+“), Punkt oder kurzer Text; keine Symbol-Variante.

## Verhalten (aus dem Quelltext)

Rueckmelde-Controls (Phase 7a): TPPGBadge, TPPGProgressRing, TPPGInfoBar.

- TPPGBadge: Punkt, Zahl (99+) oder kurzer Text auf Akzent- bzw. Signalfarbe (Tokens; Dark Mode automatisch). Zeichnet ueber IPPGItemRenderer.DrawBadge wie die Plaketten in Listen.
- TPPGProgressRing: bestimmt (Bogen 0-100 %) oder unbestimmt (rotierender Bogen mit wechselnder Laenge). Die Endlosschleife laeuft ueber den gemeinsamen Animator und nur, solange das Control sichtbar ist; ohne Animationen steht ein Viertelbogen.
- TPPGInfoBar: Hinweisleiste Info/Erfolg/Warnung/Fehler mit Symbol, Titel, Text (Markup), optionalem Aktions-Button und Schliessen-Knopf. Button und Knopf sind gezeichnet (keine Kind-Fenster); Tastatur: Pfeile wechseln, Enter/Leertaste loest aus, Esc schliesst. Screenreader: Rolle Alarm, Meldung beim Oeffnen.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `HighContrastSupport`, `Kind`, `Value`, `MaxValue`, `BadgeColor`, `Caption`, `Align`, `Anchors`, `AutoSize`, `Enabled`, `Font`, `ParentFont`, `ParentShowHint`, `ShowHint`, `Visible`

## Ereignisse

`OnClick`, `OnMouseDown`, `OnMouseUp`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGBadge.md`.
