# TPPGTrackBar

Palette **PPGlow** - Unit `PPG.TrackBar` - Basis `TPPGCustomTrackBar`

**Vorbild:** TTrackBar

## Unterschiede und Hinweise

- `Position` wird still begrenzt; `Min > Max` wirft.
- Noch nicht vorhanden: Auswahlbereich (`SelStart`/`SelEnd`) und manuelle Ticks (`SetTick`).

## Verhalten (aus dem Quelltext)

TPPGTrackBar - Schieberegler mit Glow-Griff.

Bedienung:
- Maus: Klick auf die Schiene setzt den Wert direkt dorthin und startet das Ziehen (wie Fluent/Windows 11); Klick auf den Griff zieht ohne Sprung.
- Tastatur wie TTrackBar: Pfeile = LineSize, Bild auf/ab = PageSize, Pos1/Ende = Min/Max. Bei RTL sind Links/Rechts gespiegelt.
- Mausrad: eine Raste = LineSize (nach unten = groesser, wie TTrackBar).
- Vertikal steht Min oben (wie TTrackBar).

Geometrie (alles in einer Funktion, damit Zeichnen und Hit-Test nie
auseinanderlaufen): siehe GetGeometry.

Migration: Typen und Property-Namen von TTrackBar (Vcl.ComCtrls).
Nicht unterstuetzt: Auswahlbereich (SelStart/SelEnd), PositionToolTip,
manuelle Ticks per SetTick (tsManual zeigt nur Anfang und Ende).

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Min`, `Max`, `Position`, `Orientation`, `Frequency`, `LineSize`, `PageSize`, `TickMarks`, `TickStyle`, `ThumbLength`, `SliderVisible`, `ShowFocusRect`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Anchors`, `AutoSize`, `BiDiMode`, `Color`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `Hint`, `ParentBackground`, `ParentBiDiMode`, `ParentColor`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`, `Touch`

## Ereignisse

`OnChange`, `OnGesture`, `OnContextPopup`, `OnDragDrop`, `OnDragOver`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGTrackBar.md`.
