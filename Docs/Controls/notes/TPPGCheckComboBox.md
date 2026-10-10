**Vorbild:** TMS TCheckListEdit

## Wofür

Die CheckComboBox lässt den Anwender mehrere Werte aus einer Liste wählen und braucht dabei nur den Platz eines Eingabefelds. Typisch sind Filter („Status: Aktiv, Interessent“), Wochentage, Abteilungen oder Kategorien. Die Auswahl steht als ein Text in `CheckedText` und lässt sich so direkt speichern, laden oder an ein Datenbankfeld binden.

## Wann verwenden

- Für Mehrfachauswahl mit wenig Platz, z. B. in Filterleisten über Listen und Grids. Bei genau einem Wert ist `TPPGComboBox` richtig.
- Statt `TPPGCheckListBox`, wenn die Auswahl nur gelegentlich geändert wird und die Liste nicht dauerhaft sichtbar sein muss. Soll man alle Haken auf einen Blick sehen, ist die CheckListBox klarer.
- Statt `TPPGCheckGroup` bzw. mehrerer `TPPGCheckBox`, wenn es mehr als etwa fünf Werte sind oder die Werte aus Daten kommen. Wenige feste Optionen sind als Kästchen direkt im Formular schneller bedient.
- Für frei getippte Schlagwörter, die nicht aus einer festen Liste stammen, ist `TPPGTagEdit` besser geeignet.
- Mit Datenbank: `TPPGDBCheckComboBox` (gleiche Bedienung, Auswahl im Feld als `CheckedText`).

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
- „Alle auswählen“ löst ein `OnChange` aus, aber kein `OnItemCheck` je Eintrag.

## Beispiel

```pascal
PPGCheckComboBox1.Items.CommaText := 'Kunde,Lieferant,Partner';
PPGCheckComboBox1.CheckedText := 'Kunde;Partner';
```
