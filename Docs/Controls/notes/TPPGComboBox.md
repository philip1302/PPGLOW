**Vorbild:** TComboBox, TMS TAdvComboBox

## Unterschiede und Hinweise

- Ereignisse wie `TComboBox`: `OnClick`, dann `OnSelect`; nur ohne `OnSelect` kommt `OnChange`.
- Das Mausrad ändert die geschlossene Combo nicht.
- `ItemHeight` ist eine Mindesthöhe (alte DFMs speichern 13).
- Eigene Aufklappliste (`PPG.Popup`) mit `ItemsEx` (Bild, Detail, Plakette, Markup) und `FilterMode`; Filtern ersetzt AutoComplete, ohne Treffer schließt die Liste.
- Seit Phase 20e auf der gemeinsamen Aufklapp-Basis (`TPPGCustomDropDownField`) wie ColorPicker und CheckComboBox: gleiche Maus-, Tastatur- und Screenreader-Regeln. Anders als dort sperrt `ReadOnly` das Aufklappen nicht, und bei offener Liste gehen Zeichen weiter ins Edit.

## Anpassung

- `Styles` für die Aufklappliste (Zebra, Auswahl, Hover) und `OnCustomDrawItem`.
- `RoundedCorners` für zusammengesetzte Eingabegruppen.
