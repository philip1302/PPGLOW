**Vorbild:** TCheckBox

## Wofür

Die CheckBox fragt eine Ja/Nein-Entscheidung ab, die erst mit dem Speichern oder Absenden gilt: „Newsletter abonnieren“, „AGB akzeptiert“, „Lieferadresse wie Rechnungsadresse“. Mehrere CheckBoxen stehen für unabhängige Optionen, von denen beliebig viele gelten dürfen. Mit `State = cbGrayed` zeigt sie zusätzlich „teilweise“, z. B. bei „Alle auswählen“ über einer Liste.

## Wann verwenden

- Für Optionen in Formularen und Dialogen, die mit OK bzw. Speichern übernommen werden. Für Einstellungen, die sofort wirken (an/aus wie in den Windows-Einstellungen), ist `TPPGToggleSwitch` klarer.
- Statt `TPPGRadioButton` bzw. `TPPGRadioGroup`, wenn die Optionen unabhängig sind. Muss genau eine von mehreren gelten, nehmen Sie Optionsfelder.
- Statt mehrerer einzelner CheckBoxen eine `TPPGCheckGroup` (feste Liste in einem Rahmen) oder `TPPGCheckListBox` (lange oder veränderliche Liste), wenn die Optionen aus Daten kommen.
- Statt `TPPGButton` mit `GroupIndex`/`Down`, wenn der Zustand eine Einstellung ist und kein Befehl in einer Symbolleiste.

## Unterschiede und Hinweise

- `Checked`/`State` im Code setzen löst nur `OnChange` aus, nicht `OnClick` (bewusst anders als die VCL).
- Der gemischte Zustand (`cbGrayed`) ist ein Akzent-Strich; Anwender erreichen ihn nur mit `AllowGrayed = True`.

## Beispiel

```pascal
PPGCheckBox1.AllowGrayed := True;
PPGCheckBox1.State := cbGrayed;  // OnChange, kein OnClick
```
