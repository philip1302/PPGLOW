**Vorbild:** TDBChart (TeeChart)

## Unterschiede und Hinweise

- Felder auf Diagramm-Ebene: `ValueFields` (`"Umsatz;Kosten"`, je Feld eine Serie in der Reihenfolge von `Series`), `LabelField`, `XField`. Fehlende Serien werden angelegt und nach `DisplayLabel` benannt.
- Anbinden, Öffnen und Schließen laden sofort; Datenänderungen laden nach `ReloadDelay` ms (viele Änderungen = ein Laden).
- Während `Edit`/`Insert` wird nicht gelesen (sonst würde die Eingabe gespeichert); das Laden folgt nach `Post`/`Cancel`.
- `MaxRecords` begrenzt das Lesen; eindirektionale Datenmengen werden nicht gelesen.
- `ShowCurrentRecord` markiert den aktuellen Datensatz, `JumpToRecord` springt beim Klick auf einen Punkt (über `RecNo`).

## Beispiel

```pascal
PPGDBChart1.DataSource := DataSource1;
PPGDBChart1.LabelField := 'Monat';
PPGDBChart1.ValueFields := 'Umsatz;Kosten';
```
