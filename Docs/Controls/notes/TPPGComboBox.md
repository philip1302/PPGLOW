**Vorbild:** TComboBox, TMS TAdvComboBox

## Wofür

Die ComboBox lässt den Anwender einen Wert aus einer Liste wählen, ohne dass die Liste dauerhaft Platz braucht: Anrede, Land, Zahlungsart, Artikel. Mit `Style = csDropDownList` sind nur Einträge der Liste gültig; mit `csDropDown` darf er auch eigenen Text eingeben, die Liste macht dann Vorschläge. Reiche Einträge (`ItemsEx` mit Detailzeile, Plakette, Bild) und `FilterMode` machen sie auch für lange Listen wie Artikel- oder Kundenstämme brauchbar.

## Wann verwenden

- Für eine Wahl aus fünf und mehr Werten, oder wenn der Platz knapp ist. Bei zwei bis vier Werten, die man auf einen Blick sehen soll, ist `TPPGRadioGroup` (auch als Segment) klarer.
- Für Ja/Nein-Einstellungen nicht: Dafür sind `TPPGCheckBox` und `TPPGToggleSwitch` da.
- Für mehrere gleichzeitig gewählte Werte `TPPGCheckComboBox`, für Einträge mit mehreren Spalten (Nummer, Name, Ort) `TPPGColumnComboBox`.
- Statt `TPPGSearchEdit`, wenn der Wert aus einer festen Liste kommen soll. Das Suchfeld ist für freie Suchbegriffe mit Vorschlägen gedacht.
- Statt `TPPGListBox`, wenn nur ein Wert gewählt wird und die Liste nicht ständig sichtbar sein muss.
- Am Datenfeld `TPPGDBComboBox` bzw. für Nachschlagefelder mit Schlüssel `TPPGDBLookupComboBox`.

## Unterschiede und Hinweise

- Ereignisse wie `TComboBox`: `OnClick`, dann `OnSelect`; nur ohne `OnSelect` kommt `OnChange`. Tippen löst `OnChange` aus; `ItemIndex` und `Text` im Code setzen löst kein Ereignis aus.
- Das Mausrad ändert die geschlossene Combo nicht.
- `ItemHeight` ist eine Mindesthöhe (alte DFMs speichern 13).
- Eigene Aufklappliste (`PPG.Popup`) mit `ItemsEx` (Bild, Detail, Plakette, Markup) und `FilterMode`; Filtern ersetzt AutoComplete, ohne Treffer schließt die Liste. `Group` der `ItemsEx`-Einträge zeigt die Combo nicht an (keine Gruppenköpfe in der Aufklappliste).
- Seit Phase 20e auf der gemeinsamen Aufklapp-Basis (`TPPGCustomDropDownField`) wie ColorPicker und CheckComboBox: gleiche Maus-, Tastatur- und Screenreader-Regeln. Anders als dort gibt es (wie bei `TComboBox`) kein `ReadOnly` im Objektinspektor, und bei offener Liste gehen Zeichen weiter ins Edit.

## Anpassung

- `Styles` für die Aufklappliste (Zebra, Auswahl, Hover, Detailzeile) und `OnCustomDrawItem`.
- `RoundedCorners` für zusammengesetzte Eingabegruppen.

## Beispiel

```pascal
cbLand.Style := csDropDownList;
cbLand.Sorted := True;
cbLand.Items.Text := 'Deutschland' + sLineBreak + 'Schweiz' + sLineBreak + 'Frankreich';
cbLand.ItemIndex := cbLand.Items.IndexOf('Deutschland');
cbLand.OnSelect := LandSelect;
```
