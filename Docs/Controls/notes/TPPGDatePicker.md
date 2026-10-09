**Vorbild:** TDateTimePicker (Kind = dtkDate)

## Unterschiede und Hinweise

- Eingabe nur Ziffern und Datumstrenner (Kurzformat); Prüfung beim Verlassen/Enter, Fehler als `ValidationState`.
- `Kind`, `DateMode`, `ParseInput` werden nur gelesen/gespeichert. Leeres Datum nur mit `ShowCheckbox`.
- Für `Kind = dtkTime` gibt es `TPPGTimePicker`.

## Anpassung

- `Styles` und `OnCustomDrawDay` gelten für den aufgeklappten Kalender.
