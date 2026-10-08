**Vorbild:** TComboBox, TMS TAdvComboBox

## Unterschiede und Hinweise

- Ereignisse wie `TComboBox`: `OnClick`, dann `OnSelect`; nur ohne `OnSelect` kommt `OnChange`.
- Das Mausrad ändert die geschlossene Combo nicht.
- `ItemHeight` ist eine Mindesthöhe (alte DFMs speichern 13).
- Eigene Aufklappliste (`PPG.Popup`) mit `ItemsEx` (Bild, Detail, Plakette, Markup) und `FilterMode`; Filtern ersetzt AutoComplete, ohne Treffer schließt die Liste.

## Anpassung

- `ListStyles` für die Aufklappliste (Zebra, Auswahl, Hover) und `OnCustomDrawItem`.
- `RoundedCorners` für zusammengesetzte Eingabegruppen.
