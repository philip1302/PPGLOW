# TPPGGroupBox

Palette **PPGlow** - Unit `PPG.GroupBox` - Basis `TPPGCustomGroupBox`

**Vorbild:** TGroupBox

## Unterschiede und Hinweise

- Die Beschriftung ist eine Plakette auf der Rahmenlinie statt einer Lücke im Rahmen.
- Container ohne `AutoSize`; Fokus-Glow, wenn ein Kind den Fokus hat.

## Verhalten (aus dem Quelltext)

TPPGGroupBox - Gruppierung mit Rahmen und Beschriftung.

Die Beschriftung sitzt als "Plakette" (Pille in der Flaechenfarbe) auf der
oberen Rahmenlinie. Dadurch braucht der Rahmen keine ausgesparte Luecke,
und die Optik passt zu den Glow-Presets. Liegt der Fokus auf einem Kind,
leuchtet die Plakette in der Fokusfarbe (HighlightFocus).

Migration von TGroupBox: Caption, Padding und die Standard-Properties
bleiben gueltig. Accelerator (&) fokussiert wie bei TGroupBox das erste Kind.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `HighlightFocus`, `CaptionStyle`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Anchors`, `BiDiMode`, `Caption`, `Color`, `Constraints`, `DockSite`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `Font`, `Padding`, `ParentBackground`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`, `Touch`

## Ereignisse

`OnGesture`, `OnAlignInsertBefore`, `OnAlignPosition`, `OnClick`, `OnContextPopup`, `OnDblClick`, `OnDockDrop`, `OnDockOver`, `OnDragDrop`, `OnDragOver`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnGetSiteInfo`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnResize`, `OnStartDock`, `OnStartDrag`, `OnUnDock`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGGroupBox.md`.
