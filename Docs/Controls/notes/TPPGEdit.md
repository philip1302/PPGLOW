**Vorbild:** TEdit, TMS TAdvEdit

## Unterschiede und Hinweise

- Natives Edit (IME, Undo, Screenreader) ohne Rahmen im PPGlow-Rahmen.
- `TextHint` wird selbst gezeichnet; `TextHintVisibleOnFocus` ist standardmäßig `False`. TMS `EmptyText` wird zu `TextHint`.
- Zusätzlich: `ValidationState`/`ValidationHint`, `ShowClearButton`, `LeftButton`/`RightButton` (mit `DropDownMenu`).

## Anpassung

- `ReadOnlyStyle`: eigene Fläche, Text- und Randfarbe bei `ReadOnly` (alle Eingabefelder).
- `RoundedCorners`: einzelne Ecken eckig, z. B. Feld + Button als Gruppe.

## Beispiel

```pascal
PPGEdit1.TextHint := 'E-Mail-Adresse';
PPGEdit1.ShowClearButton := True;
PPGEdit1.ValidationState := pvsError;
PPGEdit1.ValidationHint := 'Bitte eine gültige Adresse eingeben';
```
