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
