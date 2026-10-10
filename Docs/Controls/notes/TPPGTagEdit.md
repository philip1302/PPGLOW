**Vorbild:** Empfängerfeld von Outlook, WinUI TokenizingTextBox

## Wofür

Das TagEdit nimmt mehrere kurze Werte in einem Feld auf und zeigt jeden als Chip mit Kreuz: Empfänger einer E-Mail, Schlagworte eines Tickets, Fähigkeiten eines Mitarbeiters. Der Anwender tippt, bestätigt mit Enter oder `;` und wählt aus Vorschlägen. Im Code stehen die Werte als Liste (`Tags`) oder als ein Text für ein Datenbankfeld (`TagsText`).

## Wann verwenden

- Für mehrere frei eingegebene Werte, die einzeln entfernt werden sollen (Empfänger, Schlagworte). Für einen einzelnen Wert ist `TPPGEdit` oder `TPPGComboBox` einfacher.
- Statt `TPPGCheckComboBox`, wenn die Auswahl klein ist, die Liste aber lang oder offen: Das TagEdit zeigt nur das Gewählte, die CheckComboBox alle Einträge zum Ankreuzen. Bei wenigen festen Optionen ist die CheckComboBox oder eine `TPPGCheckListBox` übersichtlicher.
- Mit `AllowNew = False` als platzsparende Mehrfachauswahl aus einer festen Liste (Kategorien, Abteilungen), wenn der Anwender lieber tippt als blättert.
- Für Datenbankfelder mit mehreren Werten in einer Spalte die DB-Variante `TPPGDBTagEdit` nehmen (Wert = `TagsText`).

## Unterschiede und Hinweise

- Chips (Text mit ×) stehen vor dem Eingabebereich und brechen über mehrere Zeilen um. Mit `AutoSize` wächst die Höhe mit. Das Layout wird nur bei Änderung der Tags, der Breite oder der Schrift neu berechnet.
- Ein Tag entsteht:
  - mit Enter
  - mit einem Zeichen aus `InputDelimiters` (`;` `,`)
  - beim Verlassen (`AddOnExit`)
  - eingefügtes `a; b; c` ergibt drei Tags
- Rücktaste im leeren Feld markiert zuerst das letzte Tag und löscht es beim zweiten Druck (wie Outlook). Pfeil links/rechts wandert zwischen den Chips, Entf löscht das markierte.
- `Suggestions` erscheinen während des Tippens. Mit `AllowNew = False` sind nur Vorschläge erlaubt. Doppelte sind ausgeschlossen (`AllowDuplicates`, `CaseSensitive`); `MaxTags` begrenzt die Anzahl.
- `OnTagAdding` kann ablehnen oder den Text ändern (z. B. eine E-Mail prüfen). Dazu kommen `OnTagRemoved` und `OnTagClick`. Code (`Tags`, `TagsText`) löst nichts aus.
- Screenreader: Die Chips sind Kinder; die Standardaktion ist Entfernen.

## Beispiel

```pascal
PPGTagEdit1.Suggestions.CommaText := 'Delphi,VCL,Windows';
PPGTagEdit1.TagsText := 'Delphi;VCL';
```
