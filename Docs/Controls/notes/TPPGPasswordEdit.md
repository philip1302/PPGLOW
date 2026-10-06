**Vorbild:** WinUI PasswordBox

## Unterschiede und Hinweise

- Die Zeichen sind verdeckt (`PasswordChar`, Vorgabe ●).
- Das Auge im Feld deckt auf:
  - `rmPeek`: nur solange gedrückt
  - `rmToggle`: Umschalten
  - `rmHidden`: ohne Auge
- `Revealed` aus Code löst kein Ereignis aus. `OnRevealChange` kommt nur bei Anwenderaktionen.
- Bei aktiver Feststelltaste erscheint eine Plakette im Feld, solange es den Fokus hat (`CapsLockWarning`). Screenreader hören den Hinweis in der Beschreibung.
- Solange das Passwort verdeckt ist, sind Kopieren und Ausschneiden gesperrt (`WM_COPY`/`WM_CUT`, Strg+C, Strg+Einfg).
- Nach dem Aufdecken wird der Rückgängig-Puffer des Edits geleert, damit kein Klartext darin liegt. `Clear` überschreibt den Text im Speicher.
- Screenreader: Zustand „geschützt“ (`STATE_SYSTEM_PROTECTED`), kein Wert.

## Beispiel

```pascal
PPGPasswordEdit1.RevealMode := rmToggle;
if Length(PPGPasswordEdit1.Text) < 8 then
  PPGPasswordEdit1.ValidationState := pvsError;
```
