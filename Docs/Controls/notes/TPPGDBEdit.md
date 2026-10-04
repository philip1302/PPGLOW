**Vorbild:** TDBEdit

## Unterschiede und Hinweise

- Ungültige Eingabe (z. B. Text in einem Zahlenfeld) zeigt `ValidationState = pvsError` mit der Meldung als Hinweis, behält den Fokus und bricht still ab – kein Dialog.
- Ohne änderbares Feld (Datenmenge/Feld nur lesbar) bleibt das Edit schreibgeschützt.
- Keine Eingabemaske: `EditMask` des Felds wirkt nur über `Field.IsValidChar`.

## Beispiel

```pascal
PPGDBEdit1.DataSource := DataSource1;
PPGDBEdit1.DataField := 'Name';
```
