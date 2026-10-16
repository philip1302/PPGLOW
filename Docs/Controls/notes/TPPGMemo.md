**Vorbild:** TMemo

## Wofür

Das Memo nimmt mehrzeiligen Freitext auf: Bemerkungen, Beschreibungen, Notizen, E-Mail-Texte. Es zeigt auch längere Texte zum Lesen an, z. B. einen Verlauf oder ein Protokoll mit `ReadOnly`. Es hat dieselbe Optik wie `TPPGEdit` (Preset, Fokusrahmen, `TextHint`, `ValidationState`) und die Eigenschaften von `TMemo` (`Lines`, `ScrollBars`, `WordWrap`, `WantReturns`).

## Wann verwenden

- Für Texte, die mehr als eine Zeile brauchen oder Zeilenumbrüche enthalten dürfen. Für einzeilige Angaben (Name, Ort, Suchbegriff) ist `TPPGEdit` richtig.
- Für reinen Text ohne Formatierung. Fett, Farben oder Listen im Text brauchen ein `TPPGRichEdit`; zur reinen Anzeige formatierter Texte genügt `TPPGLabel` mit `AllowMarkup`.
- Als schreibgeschützte Anzeige (`ReadOnly`) für Verläufe und Protokolle, die man markieren und kopieren können soll. Für kurze, feste Hinweise ist `TPPGLabel` schlanker.
- Für einzelne Einträge, die der Anwender getrennt auswählen oder bearbeiten soll, besser `TPPGListBox` oder ein Grid statt Zeilen in einem Memo.
- An ein Datenfeld gebunden (Memo- oder Textspalte): `TPPGDBMemo`.

## Unterschiede und Hinweise

- Wie `TPPGEdit` mit `Lines`, `ScrollBars`, `WantReturns`, `WantTabs`, `WordWrap`; einen Löschen-Knopf (`ShowClearButton`) hat das Memo nicht.
- `Lines.Count` zählt wie bei `TMemo` die sichtbaren Zeilen: Bei `WordWrap = True` zählt eine umbrochene Zeile mehrfach. Für die logischen Zeilen den Text (`Text`) auswerten oder `WordWrap` ausschalten.
- `MaxLength` begrenzt nur die Eingabe des Anwenders; ein Zeilenumbruch zählt als zwei Zeichen. Text, der per Code gesetzt wird, kürzt das Memo nicht.
- `OnChange` kommt auch bei Text aus Code (`Lines.Text`, `Lines.Add`, `Text`).
