# TPPGSpinEdit

Palette **PPGlow** - Unit `PPG.SpinEdit` - Basis `TPPGCustomSpinEdit`

**Vorbild:** TSpinEdit (Vcl.Samples.Spin)

## Unterschiede und Hinweise

- `MinValue > MaxValue` wirft **nicht** (wie `TSpinEdit`), sonst scheitert `MinValue := 10; MaxValue := 100`.
- Wiederholung beim Halten der Buttons über den Animator.

## Verhalten (aus dem Quelltext)

TPPGSpinEdit - Zahlenfeld mit Auf-/Ab-Buttons in der Optik des Presets.

- Verhalten wie Vcl.Samples.Spin.TSpinEdit (gleiche Property-Namen, DFM per Suchen/Ersetzen umstellbar): * MinValue = MaxValue bedeutet "keine Grenze", sonst wird Value auf den Bereich begrenzt (still, wie TSpinEdit; auch MinValue > MaxValue wirft nicht, damit "MinValue := 10; MaxValue := 100" in jeder Reihenfolge geht) * Ungueltige Eingabe wird beim Verlassen und mit Enter auf Value gesetzt * EditorEnabled = False: nur ueber Buttons, Tasten und Mausrad aenderbar
- Buttons im Feld; gedrueckt halten wiederholt (400 ms, dann alle 50 ms). Der Takt kommt vom gemeinsamen Animator (kein eigener Timer).
- Pfeiltasten (+/- Increment), Bild auf/ab (+/- 10 * Increment), Mausrad.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `TextHint`, `ValidationState`, `ValidationHint`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Alignment`, `Anchors`, `AutoSelect`, `AutoSize`, `BiDiMode`, `BorderStyle`, `Color`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `EditorEnabled`, `Enabled`, `Font`, `Increment`, `MaxLength`, `MaxValue`, `MinValue`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ReadOnly`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Value`, `Visible`

## Ereignisse

`OnChange`, `OnClick`, `OnContextPopup`, `OnDblClick`, `OnDragDrop`, `OnDragOver`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnMouseWheel`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGSpinEdit.md`.
