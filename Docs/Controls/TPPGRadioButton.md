# TPPGRadioButton

Palette **PPGlow** - Unit `PPG.RadioButton` - Basis `TPPGCustomRadioButton`

**Vorbild:** TRadioButton

## Unterschiede und Hinweise

- Gruppe = gleicher Parent (wie in der VCL).
- `Checked` im Code löst nur `OnChange` aus.

## Verhalten (aus dem Quelltext)

TPPGRadioButton - Optionsfeld. Innerhalb desselben Parents und derselben
GroupIndex ist immer hoechstens einer eingeschaltet.

Bedienung wie unter Windows:
- Klick/Leertaste schaltet ein (nie aus).
- Pfeiltasten wechseln innerhalb der Gruppe (nach TabOrder, mit Umlauf) und schalten den neuen RadioButton ein.

Stolperstein: Pfeiltasten verarbeitet sonst das Formular (Fokuswechsel).
Deshalb meldet WM_GETDLGCODE DLGC_WANTARROWS.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Alignment`, `GroupIndex`, `Checked`, `Spacing`, `WordWrap`, `ShowFocusRect`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Action`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `Caption`, `Color`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `Font`, `ParentBackground`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnChange`, `OnClick`, `OnContextPopup`, `OnDragDrop`, `OnDragOver`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGRadioButton.md`.
