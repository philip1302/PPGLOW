**Vorbild:** TMS TAdvMultiColumnComboBox

## Unterschiede und Hinweise

- `Columns` enthält Titel, Breite in logischen Pixeln, Ausrichtung und Sichtbarkeit. Die Zeilen kommen aus `Items`, jede Zeile mit den Zellen getrennt durch `ColumnDelimiter` (`1001|Albers|Hamburg`).
- Virtuell: `VirtualRowCount` > 0 und `OnGetCellText` liefern die Zellen. Auch 100 000 Zeilen klappen ohne Kopie auf.
- Ein Klick auf die Kopfzeile sortiert die Ansicht, ein zweiter Klick kehrt die Richtung um. Die Daten bleiben unverändert.
- `KeyColumn`/`KeyValue` liefern den Schlüssel, `DisplayColumn` den Text im Feld. Die Tippsuche arbeitet in der Anzeigespalte, offen und geschlossen.
- Geschlossen blättern die Pfeile die Auswahl (wie eine DropDownList).
- Abweichung vom Plan: Die Zeilen liegen in `Items` mit Trennzeichen statt in `ItemsEx` mit `SubItems`, weil die Einträge der Suite keine Unterspalten haben.
- Die Zeile zeichnet das Control selbst, schlank. Die Zellroutine des Grids aus Phase 13 soll das übernehmen.

## Beispiel

```pascal
PPGColumnComboBox1.Columns.Add.Title := 'Nr';
PPGColumnComboBox1.Columns.Add.Title := 'Name';
PPGColumnComboBox1.Items.Add('1001|Albers GmbH');
PPGColumnComboBox1.DisplayColumn := 1;
PPGColumnComboBox1.KeyValue := '1001';
```
