# TPPGDBLookupComboBox

Palette **PPGlow DB** - Unit `PPG.DB.Lookup` - Basis `TPPGDBComboBox`

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

## Verhalten (aus dem Quelltext)

TPPGDBLookupComboBox - Auswahl eines Schluessels aus einer zweiten
Datenmenge (Phase 9c), wie TDBLookupComboBox.

- ListSource/KeyField/ListField: die Liste kommt aus ListSource.DataSet; angezeigt wird das erste Feld aus ListField, weitere Felder (durch Semikolon getrennt) erscheinen als Detailzeile (ItemsEx).
- DataSource/DataField: das Schluesselfeld der Haupt-Datenmenge. Auswahl schreibt KeyField des gewaehlten Eintrags hinein.
- Die Liste wird beim Oeffnen bzw. Aendern der Listen-Datenmenge einmal vollstaendig gelesen (DisableControls, Lesezeichen wird wiederhergestellt). Fuer sehr grosse Nachschlage-Tabellen ist ein Filter in der Abfrage der bessere Weg.
- Immer csDropDownList: Tippen sucht wie bei der ComboBox (Tippsuche).
- Nicht unterstuetzt: Nachschlagefelder (TField.FieldKind = fkLookup) als DataField - dafuer ListSource/KeyField/ListField direkt setzen.

## PPGlow-Eigenschaften

`KeyField`, `ListField`, `ListSource`, `Items`, `ItemsEx`, `Style`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBLookupComboBox.md`.
