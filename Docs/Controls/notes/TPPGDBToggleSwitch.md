**Vorbild:** TDBCheckBox (Schalter statt Kästchen)

## Wofür

Ein Ein/Aus-Schalter an einem Ja/Nein-Feld (Aktiv, Gesperrt, Newsletter).

## Wann verwenden

- Wenn ein `TPPGDBCheckBox` als Schalter aussehen soll.
- Für Boolean-Felder und für Text-/Zahlenfelder mit festen Werten (`ValueChecked`/`ValueUnchecked`).

## Unterschiede und Hinweise

- Boolean-Felder direkt; sonst `ValueChecked`/`ValueUnchecked` (mehrere Werte mit Semikolon, der erste wird geschrieben), Vorgabe `True`/`False`.
- Ein leeres Feld (Null) oder ein unbekannter Wert zeigt den Zwischenzustand (`State = cbGrayed`); der erste Klick schaltet ein.
- Beim Umschalten geht der Datensatz in den Bearbeiten-Modus; `ReadOnly` oder eine nicht änderbare Datenmenge verhindern das. Esc setzt den Feldwert zurück.
- `Checked` wird nicht gespeichert, der Zustand kommt aus dem Feld.

## Beispiel

```pascal
DBToggleSwitch1.DataSource := DataSource1;
DBToggleSwitch1.DataField := 'Status';
DBToggleSwitch1.ValueChecked := 'J';
DBToggleSwitch1.ValueUnchecked := 'N';
```
