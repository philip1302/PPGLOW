# TPPGEdit

Palette **PPGlow** - Unit `PPG.Edit` - Basis `TPPGCustomEdit`

**Vorbild:** TEdit, TMS TAdvEdit

## Unterschiede und Hinweise

- Natives Edit (IME, Undo, Screenreader) ohne Rahmen im PPGlow-Rahmen.
- `TextHint` wird selbst gezeichnet; `TextHintVisibleOnFocus` ist standardmäßig `False`. TMS `EmptyText` wird zu `TextHint`.
- Zusätzlich: `ValidationState`/`ValidationHint`, `ShowClearButton`, `LeftButton`/`RightButton` (mit `DropDownMenu`).

## Beispiel

```pascal
PPGEdit1.TextHint := 'E-Mail-Adresse';
PPGEdit1.ShowClearButton := True;
PPGEdit1.ValidationState := pvsError;
PPGEdit1.ValidationHint := 'Bitte eine gültige Adresse eingeben';
```

## Verhalten (aus dem Quelltext)

TPPGEdit - einzeiliges Eingabefeld in der Optik des Presets.

- Natives Edit ohne Rahmen im PPGlow-Rahmen (siehe PPG.Controls.Field)
- TextHint auch ohne Themes, ValidationState (Rahmen/Fokuslinie in Signalfarbe, ValidationHint als Tooltip und fuer Screenreader)
- ShowClearButton: Loesch-Button erscheint bei Text und Hover/Fokus
- LeftButton/RightButton: Bild-Buttons im Feld (wie TButtonedEdit), optional mit DropDownMenu
- Migration: Property-Namen von TEdit, eine DFM laesst sich per Suchen/Ersetzen (TEdit -> TPPGEdit) umstellen.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Images`, `LeftButton`, `RightButton`, `ShowClearButton`, `TextHint`, `TextHintVisibleOnFocus`, `ValidationState`, `ValidationHint`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Alignment`, `Anchors`, `AutoSelect`, `AutoSize`, `BiDiMode`, `BorderStyle`, `CharCase`, `Color`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `Font`, `HideSelection`, `MaxLength`, `NumbersOnly`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PasswordChar`, `PopupMenu`, `ReadOnly`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Text`, `Visible`

## Ereignisse

`OnChange`, `OnClick`, `OnContextPopup`, `OnDblClick`, `OnDragDrop`, `OnDragOver`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnLeftButtonClick`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnMouseWheel`, `OnRightButtonClick`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGEdit.md`.
