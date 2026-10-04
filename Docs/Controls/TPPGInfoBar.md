# TPPGInfoBar

Palette **PPGlow** - Unit `PPG.Feedback` - Basis `TPPGCustomInfoBar`

**Vorbild:** WinUI InfoBar

## Unterschiede und Hinweise

- `IsOpen` im Code löst kein Ereignis aus; Öffnen/Schließen animiert über die Höhe.
- Meldet sich beim Zeigen bei Screenreadern (`EVENT_SYSTEM_ALERT`).

## Verhalten (aus dem Quelltext)

Rueckmelde-Controls (Phase 7a): TPPGBadge, TPPGProgressRing, TPPGInfoBar.

- TPPGBadge: Punkt, Zahl (99+) oder kurzer Text auf Akzent- bzw. Signalfarbe (Tokens; Dark Mode automatisch). Zeichnet ueber IPPGItemRenderer.DrawBadge wie die Plaketten in Listen.
- TPPGProgressRing: bestimmt (Bogen 0-100 %) oder unbestimmt (rotierender Bogen mit wechselnder Laenge). Die Endlosschleife laeuft ueber den gemeinsamen Animator und nur, solange das Control sichtbar ist; ohne Animationen steht ein Viertelbogen.
- TPPGInfoBar: Hinweisleiste Info/Erfolg/Warnung/Fehler mit Symbol, Titel, Text (Markup), optionalem Aktions-Button und Schliessen-Knopf. Button und Knopf sind gezeichnet (keine Kind-Fenster); Tastatur: Pfeile wechseln, Enter/Leertaste loest aus, Esc schliesst. Screenreader: Rolle Alarm, Meldung beim Oeffnen.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `HighContrastSupport`, `Severity`, `Title`, `Message`, `IsOpen`, `IsClosable`, `ActionCaption`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnActionClick`, `OnClose`, `OnClosing`, `OnEnter`, `OnExit`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGInfoBar.md`.
