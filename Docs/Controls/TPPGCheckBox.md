# TPPGCheckBox

Palette **PPGlow** - Unit `PPG.CheckBox` - Basis `TPPGCustomCheckBox`

**Vorbild:** TCheckBox

## Unterschiede und Hinweise

- `Checked`/`State` im Code setzen löst nur `OnChange` aus, nicht `OnClick` (bewusst anders als die VCL).
- Der gemischte Zustand (`cbGrayed`) ist ein Akzent-Strich; Anwender erreichen ihn nur mit `AllowGrayed = True`.

## Beispiel

```pascal
PPGCheckBox1.AllowGrayed := True;
PPGCheckBox1.State := cbGrayed;  // OnChange, kein OnClick
```

## Verhalten (aus dem Quelltext)

TPPGCheckBox - Kontrollkaestchen mit optionalem dritten Zustand
(AllowGrayed). Ereignis-Semantik siehe PPG.Controls.Check.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Alignment`, `AllowGrayed`, `State`, `Spacing`, `WordWrap`, `ShowFocusRect`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Action`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `Caption`, `Color`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `Font`, `ParentBackground`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnChange`, `OnClick`, `OnContextPopup`, `OnDragDrop`, `OnDragOver`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGCheckBox.md`.
