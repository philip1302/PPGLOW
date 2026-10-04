**Vorbild:** TDBLookupComboBox

## Unterschiede und Hinweise

- `ListField` mit mehreren Feldern (`Ort;PLZ`): das erste ist der Text, die weiteren erscheinen als Detailzeile.
- Die Liste wird einmal vollständig gelesen (Lesezeichen bleibt); für sehr große Tabellen die Abfrage filtern.
- Nachschlagefelder (`FieldKind = fkLookup`) als `DataField` werden nicht unterstützt – `ListSource`/`KeyField`/`ListField` direkt setzen.

## Beispiel

```pascal
PPGDBLookupComboBox1.ListSource := OrteSource;
PPGDBLookupComboBox1.KeyField := 'ID';
PPGDBLookupComboBox1.ListField := 'Ort;PLZ';
PPGDBLookupComboBox1.DataSource := KundenSource;
PPGDBLookupComboBox1.DataField := 'OrtID';
```
