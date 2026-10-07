**Vorbild:** TMS FNC Kanban Board mit Datenbank-Anbindung

## Unterschiede und Hinweise

- Feldzuordnung: `KeyField` (ganze Zahl, Pflicht zum Schreiben), `ColumnField` (Wert = `Column.Key`, sonst `Column.Id`), `OrderField` (Reihenfolge), `TitleField`; optional `LaneField` (Wert = `Lane.Key` bzw. `Id`), `TextField`, `LabelsField`, `AssigneeField`, `DueField`, `ProgressField`, `ColorField`.
- Spalten und Swimlanes legt man wie beim `TPPGKanban` an; die Karten kommen aus der Datenmenge (höchstens `MaxRecords`), sortiert nach `OrderField`. Datensätze mit unbekanntem Spaltenwert erscheinen nicht.
- Nach jedem Verschieben durch den Anwender schreibt das Board Spalte (und Swimlane) der Karte und nummeriert die Karten von Quell- und Zielzelle in Zehnerschritten neu (nur geänderte Datensätze).
- Ohne `KeyField` ist das Board schreibgeschützt (Verschieben wird abgelehnt).
- Änderungen von außen laden nach `ReloadDelay` neu; die Auswahl bleibt an der Karte. `SyncRecord`: die gewählte Karte wird zum aktuellen Datensatz.

## Beispiel

```pascal
PPGDBKanban1.Columns.AddColumn('Offen').Key := 'todo';
PPGDBKanban1.Columns.AddColumn('In Arbeit', 3).Key := 'doing';
PPGDBKanban1.Columns.AddColumn('Fertig').Key := 'done';
PPGDBKanban1.KeyField := 'ID';
PPGDBKanban1.ColumnField := 'Status';
PPGDBKanban1.OrderField := 'Reihe';
PPGDBKanban1.TitleField := 'Titel';
PPGDBKanban1.DataSource := DataSource1;
```
