**Vorbild:** WinUI PasswordBox

## Wofür

Das Kennwortfeld nimmt Kennwörter, PINs und andere Geheimnisse entgegen. Die Zeichen sind verdeckt; ein Auge im Feld deckt sie bei Bedarf auf, und bei aktiver Feststelltaste erscheint ein Hinweis. Kopieren, Ausschneiden und der Rückgängig-Puffer geben den Klartext nicht heraus, und der Text wird nie in der DFM gespeichert.

## Wann verwenden

- Für alles, was niemand mitlesen soll: Anmeldung, Kennwort ändern, PIN, API-Schlüssel oder Zugangsdaten zu einem Server.
- Statt `TPPGEdit` mit `PasswordChar`: Das Kennwortfeld bringt Auge, Feststelltasten-Hinweis, Kopiersperre und Screenreader-Schutz („geschützt", kein Wert) schon mit.
- Nicht für Daten, die nur formatiert sein müssen (IBAN, Telefonnummer); dafür ist `TPPGMaskEdit` gedacht.
- Für Zahlen-PINs mit fester Stellenzahl reicht das Kennwortfeld mit `MaxLength`; ein eigenes PIN-Control gibt es nicht.

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
