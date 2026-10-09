**Vorbild:** Empfängerfeld von Outlook, WinUI TokenizingTextBox

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
