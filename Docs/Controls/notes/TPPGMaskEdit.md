**Vorbild:** `TMaskEdit`

## Wofür

Das Maskenfeld nimmt Werte mit festem Aufbau entgegen: PLZ, Datum, Uhrzeit, Kunden- oder Artikelnummer, IBAN. Die `EditMask` gibt Stelle für Stelle vor, was erlaubt ist, zeigt feste Zeichen (Punkte, Bindestriche) gleich mit und lässt den Anwender nur die freien Stellen füllen. Eine unvollständige Eingabe färbt das Feld rot, statt wie `TMaskEdit` einen Fehlerdialog zu öffnen.

## Wann verwenden

- Für kurze Werte mit immer gleichem Aufbau, bei denen die Maske Tippfehler verhindert und das Format erklärt (PLZ, Uhrzeit, Nummernkreise).
- Statt `TPPGEdit`, wenn feste Zeichen automatisch eingefügt werden sollen. Für freien Text oder Werte unterschiedlicher Länge (Name, E-Mail) ist `TPPGEdit` richtig, Prüfungen dort über `ValidationState` bzw. `TPPGValidator`.
- Statt `TPPGNumberEdit` nur bei Nummern, mit denen nicht gerechnet wird. Beträge, Mengen und Prozentwerte gehören ins `TPPGNumberEdit` (Tausenderpunkte, Min/Max, Rad).
- Für Datum und Uhrzeit nur, wenn schnelles Tippen wichtiger ist als Auswahl. `TPPGDatePicker` und `TPPGTimePicker` bieten Kalender bzw. Auswahl und prüfen, ob das Datum existiert; die Maske prüft nur Ziffern.
- Für PINs mit fester Länge mit `PasswordChar`. Kennwörter gehören ins `TPPGPasswordEdit`.

## Unterschiede und Hinweise

- Das innere Edit ist ein Nachfahre von `TCustomMaskEdit`. `EditMask`, `EditText`, `IsMasked` und die Prüfung stammen unverändert aus der VCL. DFMs eines `TMaskEdit` laden nach dem Tausch des Klassennamens.
- Ungültige Eingabe beim Verlassen öffnet keinen Fehlerdialog (`EDBEditError`). Stattdessen gilt `ValidationState = pvsError` mit Hinweis, `OnValidationError` meldet den Fall, und der Fokus wird nicht festgehalten. Ein ganz leeres Feld gilt als gültig.
- `ValidateInput` prüft jederzeit; `InvalidPos` nennt die erste falsche Stelle.
- IME und Masken vertragen sich schlecht (asiatische Eingabe), wie bei der VCL.
- `TPPGDBMaskEdit` übernimmt `Field.EditMask`, wenn es selbst keine Maske hat. Eine ungültige Eingabe wird dort nicht ins Feld geschrieben.

## Beispiel

```pascal
PPGMaskEdit1.EditMask := '!(999) 000-0000;1;_';
if not PPGMaskEdit1.ValidateInput then
  PPGMaskEdit1.SetFocus;
```
