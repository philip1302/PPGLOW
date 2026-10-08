# TPPGToggleSwitch

Palette **PPGlow** - Unit `PPG.ToggleSwitch` - Basis `TPPGCustomToggleSwitch`

**Vorbild:** TToggleSwitch (Vcl.WinXCtrls)

## Unterschiede und Hinweise

- Statt `State = tssOn/tssOff` gibt es `Checked` (das Migrationsskript setzt das um).
- `AccValue` liefert „On“/„Off“ für Screenreader (übersetzt mit `PPG.Lang`).

## Verhalten (aus dem Quelltext)

TPPGToggleSwitch - Ein/Aus-Schalter mit gleitendem Knopf (animiert ueber
dieselbe Zustandslogik wie CheckBox/RadioButton).

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Alignment`, `Checked`, `Spacing`, `WordWrap`, `ShowFocusRect`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Action`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `Caption`, `Color`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `Font`, `ParentBackground`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`, `Touch`

## Ereignisse

`OnChange`, `OnGesture`, `OnClick`, `OnContextPopup`, `OnDragDrop`, `OnDragOver`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGToggleSwitch.md`.
