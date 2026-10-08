# TPPGSplitter

Palette **PPGlow** - Unit `PPG.Splitter` - Basis `TPPGCustomSplitter`

**Vorbild:** TSplitter

## Unterschiede und Hinweise

- Fenster-Control (TabStop standardmäßig aus) mit `ResizeStyle = rsUpdate` als Vorgabe; in Ruhe unsichtbar, Linie und Griff erst bei Hover/Ziehen/Fokus.
- Pfeiltasten verschieben, wenn der Splitter den Fokus hat.

## Verhalten (aus dem Quelltext)

TPPGSplitter - Ziehgriff zwischen ausgerichteten Controls (Phase 7a).

Verhalten wie TSplitter (DFM-kompatibel: Align, MinSize, AutoSnap,
ResizeStyle, OnCanResize, OnMoved): veraendert die Groesse des Controls,
das auf derselben Seite direkt angrenzt. Zusaetzlich:
- Optik im Preset-Stil: Linie und Griffpunkte erscheinen beim Hover, beim Ziehen in der Fokusfarbe; Dark Mode/Hochkontrast ueber die Tokens.
- Fenster-Control: mit TabStop per Tastatur erreichbar; Pfeile verschieben (Strg = 1 px, sonst 10 logische px), Pos1/Ende = Minimum/Maximum.
- ResizeStyle rsUpdate (Standard) zieht live; rsLine/rsPattern zeigen eine invertierte Linie auf dem Parent, rsNone aendert erst beim Loslassen.
- Esc bricht das Ziehen ab (alte Groesse).

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `HighContrastSupport`, `MinSize`, `AutoSnap`, `Beveled`, `ResizeStyle`, `Align`, `Color`, `Constraints`, `Enabled`, `ParentColor`, `ParentShowHint`, `ShowHint`, `TabOrder`, `TabStop`, `Visible`, `Touch`, `Width`

## Ereignisse

`OnGesture`, `OnCanResize`, `OnMoved`, `OnPaint`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGSplitter.md`.
