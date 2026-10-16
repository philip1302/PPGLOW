**Vorbild:** TDBText

## Wofür

Zeigt den Wert eines Datenfelds als Beschriftung an, schreibgeschützt und dem Datensatz folgend (Namen, Summen, Status in einer Kopfzeile).

## Wann verwenden

- Für Formulare, die bisher `TDBText` benutzen: Der DFM-Tausch ist 1:1 (`DataSource`, `DataField`, `Alignment`, `Layout`, `WordWrap`, `Transparent`, `Font` …).
- Wenn der Text bei leerem Feld einen Platzhalter zeigen soll (`NullText`) oder Zahlen/Datum ohne Feld-`DisplayFormat` formatiert werden sollen (`DisplayFormat`).

## Unterschiede und Hinweise

- Erbt von `TPPGLabel`: Textfarbe folgt dem Dark Mode, `Secondary` und `AllowMarkup` stehen zur Verfügung.
- Angezeigt wird `Field.DisplayText` (also auch `OnGetText` und `DisplayFormat` des Feldes); ist `DisplayFormat` am Control gesetzt, gilt es für Zahlen- und Datumsfelder (`FormatFloat` bzw. `FormatDateTime`).
- `Caption` wird nicht gespeichert. Wie bei `TDBText` ist `AutoSize` aus und `ShowAccelChar` aus.
- Ohne Datenquelle oder bei geschlossener Datenmenge bleibt der Text leer (im Designer steht der Name des Controls da).

## Beispiel

```pascal
DBText1.DataSource := DataSource1;
DBText1.DataField := 'Umsatz';
DBText1.DisplayFormat := '#,##0.00';
DBText1.NullText := '-';
```
