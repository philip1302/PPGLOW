**Vorbild:** keins; ersetzt den Prüfcode in Formularen (`if Edit1.Text = '' then ShowMessage(...)`)

## Unterschiede und Hinweise

- Regeln im Designer: Pflicht, Länge, Bereich (Zahl oder Datum), Format (E-Mail, Telefon, PLZ, IBAN mit Prüfsumme, eigener regulärer Ausdruck), Vergleich mit einem anderen Feld, eigene Regel per `OnValidate`.
- Fehler stehen direkt am Feld (`ValidationState`/`ValidationHint`, auch für Screenreader). Der Validator nimmt nur zurück, was er selbst gesetzt hat; Fehler eines DB-Felds bleiben stehen.
- Geprüft wird beim Verlassen eines Felds (`ValidateOn`); nach einem Fehler prüft das Feld beim Tippen sofort neu. `Validate` prüft alles, `ValidateGroup`/`ValidateChildren` nur einen Teil.
- `FocusFirstError` springt zum ersten Fehler in Tab-Reihenfolge und aktiviert dafür Reiter und Assistent-Seiten, klappt Expander auf und scrollt.
- `SummaryBar` (InfoBar) zeigt „2 Fehler: Name, E-Mail“ mit „Zum Fehler“; `CheckOnClose` hält ein Formular mit OK offen, solange etwas fehlt; `SubmitControl` sperrt den OK-Knopf bis alle Pflichtfelder gefüllt sind; `Wizard` lässt „Weiter“ erst bei gültiger Seite zu.
- `AutoFieldRules`: DB-Controls ohne eigene Regel werden nach ihrem `TField` geprüft (Required, Size, MinValue/MaxValue), solange die Datenmenge bearbeitet wird. Das gilt für alle DB-Controls desselben Besitzers.
- Fremde Controls ohne `ValidationState` (VCL, TMS) werden geprüft, aber nicht markiert: Sie erscheinen in `Results`, der Sammelleiste und `OnShowError`.
- Ausgeblendete und gesperrte Controls zählen nicht; Controls auf nicht aktiven Reitern schon.

## Beispiel

```pascal
PPGValidator1.Rules.AddRule(EditName, vrRequired);
R := PPGValidator1.Rules.AddRule(EditMail, vrPattern);
R.PatternKind := vpEmail;
if not PPGValidator1.Validate then
  PPGValidator1.FocusFirstError;
```
