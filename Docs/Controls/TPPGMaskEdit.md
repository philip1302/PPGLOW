# TPPGMaskEdit

Palette **PPGlow** - Unit `PPG.MaskEdit` - Basis `TPPGCustomMaskEdit`

**Vorbild:** `TMaskEdit`

## Unterschiede und Hinweise

- Das innere Edit ist ein Nachfahre von `TCustomMaskEdit`. `EditMask`, `EditText`, `IsMasked` und die Prüfung stammen unverändert aus der VCL. DFMs eines `TMaskEdit` laden nach dem Tausch des Klassennamens.
- Ungültige Eingabe beim Verlassen öffnet keinen Fehlerdialog (`EDBEditError`). Stattdessen gilt `ValidationState = pvsError` mit Hinweis, `OnValidationError` meldet den Fall, und der Fokus wird nicht festgehalten. Ein ganz leeres Feld gilt als gültig.
- `ValidateInput` prüft jederzeit; `InvalidPos` nennt die erste falsche Stelle.
- IME und Masken vertragen sich schlecht (asiatische Eingabe), wie bei der VCL.
- `TPPGDBMaskEdit` übernimmt `Field.EditMask`, wenn es selbst keine Maske hat. Eine ungültige Eingabe wird dort nicht ins Feld geschrieben.

## Beispiel

```pascal
PPGMaskEdit1.EditMask := '!(999) 000-0000;1;_';
if not PPGMaskEdit1.ValidateInput then
  PPGMaskEdit1.SetFocus;
```

## Verhalten (aus dem Quelltext)

TPPGMaskEdit - Eingabe mit Maske (Phase 12b, Vorbild TMaskEdit).

- Das innere Edit ist ein Nachfahre von TCustomMaskEdit: die gesamte Maskenlogik der VCL (EditMask, EditText, IsMasked, Validate) wird wiederverwendet, nichts davon nachgebaut. DFM wie TMaskEdit.
- Ungueltige Eingabe beim Verlassen: kein Exception-Dialog, sondern ValidationState = pvsError mit Hinweis (wie die DB-Felder aus Phase 9); der Fokus wird nicht festgehalten. Ein ganz leeres Feld gilt als gueltig.
- IME und Masken vertragen sich schlecht (asiatische Eingabe); das gilt wie bei der VCL auch hier.
- IPPGFieldValue: Wert = Text, leer = Null (fuer DB-Felder und Grid).

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `TextHint`, `TextHintVisibleOnFocus`, `UseSystemContextMenu`, `ValidationState`, `ValidationHint`, `HighContrastSupport`, `ShowClearButton`

## Eigenschaften wie in der VCL

`Align`, `Alignment`, `Anchors`, `AutoSelect`, `AutoSize`, `BiDiMode`, `BorderStyle`, `CharCase`, `Color`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `EditMask`, `Enabled`, `Font`, `HideSelection`, `MaxLength`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PasswordChar`, `PopupMenu`, `ReadOnly`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Text`, `Visible`

## Ereignisse

`OnChange`, `OnClick`, `OnContextPopup`, `OnDblClick`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnValidationError`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGMaskEdit.md`.
