**Vorbild:** TMS TCheckListEdit

## Unterschiede und Hinweise

- Mehrfachauswahl im Aufklappfeld. Das Popup bleibt beim Anhaken offen; Enter oder ein Klick daneben schließt es.
- Haken wirken sofort (`OnItemCheck`, `OnChange`). Esc schließt nur und nimmt nichts zurück.
- Anzeige im Feld (`DisplayMode`):
  - `cdmCompact`: „A, B, +2“ (`MaxDisplayItems`)
  - `cdmList`: alle Namen
  - `cdmCount`: „3 ausgewählt“
- `ShowSelectAll` zeigt „Alle auswählen“ als erste Zeile. Ab `FilterThreshold` Einträgen filtern getippte Zeichen die Liste; die Leertaste hakt dabei weiter an.
- `CheckedText` liefert die gewählten Einträge, getrennt durch `Delimiter`. So stehen sie im DFM und in `TPPGDBCheckComboBox`.
- Code (`Checked[]`, `CheckAll`, `CheckedText`) löst keine Ereignisse aus.

## Beispiel

```pascal
PPGCheckComboBox1.Items.CommaText := 'Kunde,Lieferant,Partner';
PPGCheckComboBox1.CheckedText := 'Kunde;Partner';
```
