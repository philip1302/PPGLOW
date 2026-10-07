# TPPGProgressBar

Palette **PPGlow** - Unit `PPG.ProgressBar` - Basis `TPPGCustomProgressBar`

**Vorbild:** TProgressBar

## Unterschiede und Hinweise

- `Position` wird wie in der VCL still auf `Min..Max` begrenzt; `Min > Max` wirft `EPPGPropertyError`.
- Marquee (unbestimmt) über den gemeinsamen Animator, Zustände Error/Paused, Text im Balken.

## Verhalten (aus dem Quelltext)

TPPGProgressBar - Fortschrittsbalken in der Optik des Presets.

- Spur = Appearance.Normal, Fuellung = Appearance.Checked ("an"-Farbe)
- State pbsError/pbsPaused faerbt die Fuellung rot bzw. gelb (wie Windows)
- Style pbstMarquee: unbestimmter Fortschritt, laeuft ueber den gemeinsamen Animator (kein eigener Timer) und nur, solange das Control sichtbar ist. Mit abgeschalteten Animationen (Systemeinstellung, Remote-Desktop) steht das Segment still in der Mitte.
- Positionswechsel werden weich animiert (Animation-Einstellungen).
- Migration: Typen und Property-Namen von TProgressBar (Vcl.ComCtrls), eine DFM laesst sich per Suchen/Ersetzen umstellen. Smooth wird nur zur Kompatibilitaet gelesen: PPGlow zeichnet immer einen durchgehenden Balken.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Min`, `Max`, `Position`, `Step`, `Orientation`, `Style`, `State`, `MarqueeInterval`, `Smooth`, `ShowText`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Anchors`, `BiDiMode`, `Caption`, `Color`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `Font`, `Hint`, `ParentBackground`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnChange`, `OnClick`, `OnContextPopup`, `OnDragDrop`, `OnDragOver`, `OnEndDock`, `OnEndDrag`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGProgressBar.md`.
