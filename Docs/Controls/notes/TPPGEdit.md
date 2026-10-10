**Vorbild:** TEdit, TMS TAdvEdit

## Wofür

Das Feld nimmt eine Zeile Text auf: Name, E-Mail, Suchbegriff, Kundennummer. Es ersetzt `TEdit` und `TButtonedEdit` mit denselben Property-Namen und bringt Platzhalter (`TextHint`), Löschknopf, Knöpfe mit Symbol oder Menü im Feld und eine sichtbare Prüfung (`ValidationState`, `ValidationHint`) mit.

## Wann verwenden

- Für freien Text in einer Zeile. Für mehrere Zeilen (Bemerkung, Adresse am Stück) ist `TPPGMemo` richtig.
- Für Beträge, Mengen und Prozentwerte mit Komma, Grenzen und Formatierung `TPPGNumberEdit` bzw. `TPPGSpinEdit` nehmen. `NumbersOnly` reicht nur für Ziffernfolgen wie PLZ oder Kundennummer.
- Für Werte mit festem Muster (Telefon, IBAN, Datum als Text) ist `TPPGMaskEdit` besser, für Kennwörter mit Aufdecken-Knopf `TPPGPasswordEdit`.
- Für ein Suchfeld mit Vorschlagsliste, Suchverzögerung und Lupe gibt es `TPPGSearchEdit`, für Dateipfade mit Dialog `TPPGFileEdit`. Ein `TPPGEdit` mit `ShowClearButton` und `RightButton` genügt, wenn Sie das Verhalten selbst steuern wollen.
- Wenn der Wert aus einer festen Liste kommt, `TPPGComboBox` statt Freitext verwenden.

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
