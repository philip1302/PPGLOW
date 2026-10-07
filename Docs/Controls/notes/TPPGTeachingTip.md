**Vorbild:** WinUI TeachingTip

## Unterschiede und Hinweise

- Sprechblase mit Pfeil an `Target`. `Placement = tpAuto` versucht oben, unten, links, rechts und nimmt die erste Seite, auf die die Blase ganz passt. Ohne `Target` erscheint sie unten rechts im Formular, ohne Pfeil.
- Folgt dem Ziel, wenn es oder sein Formular sich bewegt. Ist das Ziel unsichtbar oder das Formular minimiert, wird sie nur ausgeblendet und kommt danach wieder.
- Das Fenster wird nie aktiviert: Der Fokus bleibt im Formular. Ein fester Tipp (`LightDismiss = False`) nimmt trotzdem die Tastatur: Tab wechselt zwischen den Buttons, Enter/Leertaste löst aus, Esc schließt.
- `LightDismiss = True`: Ein Klick daneben oder der Wechsel in eine andere Anwendung schließt; der Klick geht trotzdem an sein Ziel.
- Ereignisse nur bei Anwenderaktionen: `OnActionClick`, `OnLinkClick`, `OnClosing` (abbrechbar), `OnClose` mit Grund. `Show`/`Hide` aus Code lösen keine aus.
- Der Aktions-Button schließt nicht selbst (wie WinUI); die Anwendung entscheidet, z. B. nächster Schritt einer Tour. Ein Ereignis darf den Tipp freigeben.
- Das Kreuz oben rechts erscheint nur ohne `CloseButtonText`.
- Nicht enthalten: Bild oben (Hero), Links per Tab.
- Screenreader: Rolle Dialog, `EVENT_SYSTEM_ALERT` beim Zeigen, Buttons als Kinder.

## Beispiel

```pascal
PPGTeachingTip1.Title := 'Neu: Teilen';
PPGTeachingTip1.Text := 'Mit <b>Teilen</b> schicken Sie einen Link.';
PPGTeachingTip1.ActionButtonText := '&Weiter';
PPGTeachingTip1.ShowFor(ShareButton);
```
