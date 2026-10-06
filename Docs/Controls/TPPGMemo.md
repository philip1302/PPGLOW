# TPPGMemo

Palette **PPGlow** - Unit `PPG.Memo` - Basis `TPPGCustomMemo`

**Vorbild:** TMemo

## Unterschiede und Hinweise

- Wie `TPPGEdit` mit `Lines`, `ScrollBars`, `WantReturns`, `WantTabs`, `WordWrap`.

## Verhalten (aus dem Quelltext)

TPPGMemo - mehrzeiliges Eingabefeld in der Optik des Presets.

- Natives Memo ohne Rahmen im PPGlow-Rahmen (siehe PPG.Controls.Field)
- TextHint (auch fuer Memos, die ihn nativ nicht kennen), ValidationState
- Die Scrollbalken bleiben nativ; mit VCL-Style faerbt sie der Style-Hook. Eigene Scrollbalken waeren ein eigenes Control (bewusst nicht in Phase 4).
- Migration: Property-Namen von TMemo (Lines, ScrollBars, WordWrap, ...).

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `TextHint`, `UseSystemContextMenu`, `TextHintVisibleOnFocus`, `ValidationState`, `ValidationHint`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Alignment`, `Anchors`, `BiDiMode`, `BorderStyle`, `CharCase`, `Color`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `Font`, `HideSelection`, `Lines`, `MaxLength`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ReadOnly`, `ScrollBars`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`, `WantReturns`, `WantTabs`, `WordWrap`

## Ereignisse

`OnChange`, `OnClick`, `OnContextPopup`, `OnDblClick`, `OnDragDrop`, `OnDragOver`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnMouseWheel`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGMemo.md`.
