**Vorbild:** TDateTimePicker

## Unterschiede und Hinweise

- Eingabe beim kurzen Datum (`Kind = dtkDate`, `DateFormat = dfShort`, kein eigenes `Format`, ohne `ParseInput`) nur Ziffern und Datumstrenner; bei Uhrzeit, eigenem Format oder `ParseInput` ist die Eingabe frei. Prüfung beim Verlassen/Enter, Fehler als `ValidationState`, der Text bleibt zum Korrigieren stehen.
- `Kind` wirkt wie bei `TDateTimePicker`: `dtkDate` Datum mit Kalender, `dtkTime` Uhrzeit mit Auf/Ab-Knöpfen, `dtkDateTime` (ab Delphi 10.4) Datum und Uhrzeit. Oben/Unten, Auf/Ab und das Rad ändern in der Uhrzeit den Teil unter der Einfügemarke (Stunde, Minute, Sekunde, AM/PM), im Datum den Tag (Strg: Monat).
- `DateMode = dmUpDown` zeigt Auf/Ab-Knöpfe statt des Kalenders. `ParseInput` mit `OnUserInput` erlaubt eigene Auswertungen (z. B. „morgen“ oder „+3“).
- Leeres Datum nur mit `ShowCheckbox`.
- Eine reine Uhrzeit mit Liste der Zeiten bietet `TPPGTimePicker`.

## Anpassung

- `Styles` und `OnCustomDrawDay` gelten für den aufgeklappten Kalender.
