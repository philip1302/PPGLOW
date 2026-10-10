**Vorbild:** TToggleSwitch (Vcl.WinXCtrls)

## Wofür

Der Schalter stellt eine Einstellung sofort an oder aus, wie in den Windows-Einstellungen: Benachrichtigungen, Autospeichern, Offline-Modus. Er zeigt den Zustand mit einem gleitenden Knopf und meldet jede Änderung über `OnChange`. Bedienung per Maus, Leertaste oder Zugriffstaste; Screenreader hören „Ein“ bzw. „Aus“.

## Wann verwenden

- Für Einstellungen, die sofort wirken und keinen „OK“-Knopf brauchen (Benachrichtigungen an, Filter „Nur offene“). In Dialogen mit OK/Abbrechen, deren Werte erst beim Bestätigen gelten, ist `TPPGCheckBox` üblicher.
- Statt `TPPGCheckBox`, wenn es genau zwei Zustände gibt. Für „teilweise ausgewählt“ (`AllowGrayed`) oder Zustimmungen („AGB gelesen“) bleibt die CheckBox richtig.
- Statt zweier `TPPGRadioButton` (Ein/Aus), wenn die Frage mit Ja/Nein beantwortet ist. Bei drei oder mehr Möglichkeiten `TPPGRadioGroup` nehmen (auch als Segment-Leiste).
- Nicht für Befehle, die etwas auslösen (Speichern, Senden): dafür `TPPGButton`; ein Umschalter in einer Symbolleiste ist `TPPGButton` mit `GroupIndex`.

## Unterschiede und Hinweise

- Statt `State = tssOn/tssOff` gibt es `Checked` (das Migrationsskript setzt das um).
- `StateCaptions`, `ShowStateCaption`, `SwitchWidth`, `ThumbColor`, `FrameColor` und `ReadOnly` gibt es nicht; das Migrationsskript entfernt sie mit Meldung. Den Text schreiben Sie in `Caption`, die Farben stehen in `Appearance` (`Normal` = aus, `Checked` = an).
- `OnChange` meldet jede Änderung (Klick, Tastatur, Code), `OnClick` nur die Bedienung durch den Anwender bzw. den Aufruf von `Click`. `Checked := True` im Code löst also kein `OnClick` aus.
- `AccValue` liefert „On“/„Off“ für Screenreader (übersetzt mit `PPG.Lang`).
