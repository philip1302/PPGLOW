**Vorbild:** TToolBar

## Unterschiede und Hinweise

- Einträge (`Items`) statt Kind-Buttons; daher kein automatischer Umstieg von `TToolBar`/`TToolButton`.
- Überlauf als natives Kontextmenü; Actions über `Items[].Action`.

## Anpassung

- Je Item `Color`, `TextColor`, `FontStyle`; `ImageTint` für einfarbige Symbole.
