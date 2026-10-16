**Vorbild:** TDBRichEdit

## Wofür

Zeigt und bearbeitet formatierten Text (RTF) aus einem Memo- oder BLOB-Feld. Beim Datensatzwechsel lädt es den Inhalt neu, beim Verlassen des Controls schreibt es einen geänderten Text als RTF ins Feld zurück.

## Wann verwenden

- Für Formulare, die bisher `TDBRichEdit` benutzen (`DataSource`, `DataField`, `ReadOnly`, `AutoDisplay`).
- Für Notizen, Beschreibungen und Texte mit Formatierung, die in der Datenbank liegen. Für reinen Text ist `TPPGDBMemo` richtig.

## Unterschiede und Hinweise

- Das Feld sollte ein Memo- (`ftMemo`, `ftWideMemo`) oder BLOB-Feld sein. Steht darin kein RTF (Altbestand mit reinem Text), zeigt das Control den Text unformatiert; nach einer Änderung wird RTF gespeichert.
- Text- und Stringfelder sowie `PlainText = True` zeigen und schreiben reinen Text.
- Das Control ist schreibgeschützt, wenn die Datenmenge oder das Feld nicht änderbar ist; die Eigenschaft `ReadOnly` sperrt zusätzlich.
- `AutoDisplay = False` lädt BLOB-Felder erst bei Doppelklick oder Enter (`LoadMemo`), wie bei `TDBRichEdit`.
- Ablauf wie bei `TPPGDBMemo`: Der Datensatz geht beim ersten Tippen in den Bearbeiten-Modus, Esc setzt den Feldwert zurück, ein ungültiger Wert beim Verlassen setzt `ValidationState = pvsError`.
- `Lines` wird nicht in die DFM gespeichert.
- Farben und Formatierung wie bei `TPPGRichEdit`: Der Hintergrund folgt dem Theme, Text ohne eigene Farbe wird im Dark Mode hell gezeichnet; im Feld gespeichert wird immer der unveränderte RTF-Text.
- Eigene Unit `PPG.DB.RichEdit`, damit Anwendungen ohne RichEdit nichts davon linken.

## Beispiel

```pascal
DBRichEdit1.DataSource := DataSource1;
DBRichEdit1.DataField := 'Beschreibung';
```
