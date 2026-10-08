**Vorbild:** WinUI NavigationView, TMS AdvNavBar

## Unterschiede und Hinweise

- `Selected` im Code löst kein Ereignis aus; Elterneinträge klappen nur auf (werden nicht gewählt).
- `pdmAuto` beobachtet die Breite des Parents; kompakt öffnet ein Klick auf einen Elterneintrag die Leiste.
- Mit `PageControl` verbunden zeigt die Auswahl die Seite `Item.PageIndex` (Verb „Connect to ...“).
- Einträge im Designer über „Edit items...“ (Baum-Editor mit Einrücken/Ausrücken).

## Anpassung

- Je Eintrag `Color`, `TextColor`, `FontStyle`; `NavStyles` und `OnCustomDrawItem`; `ImageTint` für einfarbige Symbole.
