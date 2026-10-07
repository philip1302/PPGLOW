**Vorbild:** TSearchBox (Vcl.WinXCtrls), WinUI AutoSuggestBox

## Unterschiede und Hinweise

- Baut auf der ComboBox auf: Vorschläge in `ItemsEx`, Verzögerung `SearchDelay` über den Animator, `OnSearch`.
- `OnInvokeSearch` von `TSearchBox` heißt hier `OnSearch` (Migrationsskript benennt um).
