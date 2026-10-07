# TPPGTeachingTip

Palette **PPGlow** - Unit `PPG.TeachingTip` - Basis `TComponent`

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

## Verhalten (aus dem Quelltext)

TeachingTip (Phase 11f): Sprechblase mit Pfeil, an ein Control geheftet
(wie WinUI TeachingTip). Grundlage der gefuehrten Tour (Phase 16).

- Inhalt: Symbol, Titel, Untertitel, Text mit Markup und Links, bis zu zwei Buttons (Aktion = Akzent, Schliessen) und ein Schliessen-Kreuz.
- Anheften: Target (FreeNotification) und Placement (Auto: oben, unten, links, rechts - die erste Seite, auf die die Blase ganz passt). Bewegt sich das Ziel oder sein Formular, folgt die Blase (PPGWatchControl). Ist das Ziel unsichtbar oder das Formular minimiert, wird sie nur ausgeblendet und kommt danach wieder. Ohne Target: unten rechts im Formular, ohne Pfeil.
- Modi: LightDismiss = Klick daneben oder Wechsel der Anwendung schliesst (der Klick geht trotzdem an sein Ziel); sonst nur Buttons oder Esc. Ein fester TeachingTip nimmt die Tastatur: Tab/Umschalt+Tab wechselt zwischen den Buttons, Enter/Leertaste loest aus (ueber PPG.AppHooks, das Fenster wird nie aktiviert - der Fokus bleibt im Formular).
- Ereignisse nur bei Anwenderaktionen (Suite-Regel): OnActionClick, OnLinkClick, OnClosing (abbrechbar), OnClose. Show/Hide aus Code loesen keine Ereignisse aus. Der Aktions-Button schliesst nicht selbst (wie WinUI); die Anwendung entscheidet (z.B. Tour: naechster Schritt).
- Ein Ereignis darf den TeachingTip freigeben: danach wird Self nicht mehr angefasst, das Fenster gibt sich bei Bedarf verzoegert frei (CM_RELEASE).
- Screenreader: Rolle Dialog, Name = Titel, Buttons als Kinder; EVENT_SYSTEM_ALERT beim Zeigen.

Nicht umgesetzt (bewusst): Bild oben (Hero), Links per Tab, Scrollen
innerhalb verschobener ScrollBoxen ohne WM_WINDOWPOSCHANGED.

## PPGlow-Eigenschaften

`Target`, `Title`, `Subtitle`, `Text`, `ActionButtonText`, `CloseButtonText`, `Icon`, `ShowCloseButton`, `LightDismiss`, `Placement`, `MaxWidth`, `Preset`, `StyleManager`

## Ereignisse

`OnActionClick`, `OnLinkClick`, `OnClosing`, `OnClose`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGTeachingTip.md`.
