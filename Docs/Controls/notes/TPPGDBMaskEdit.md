**Vorbild:** DB-Variante von `TPPGMaskEdit` (wie `TDBEdit`)

## Unterschiede und Hinweise

- Bindet sich über `DataSource`/`DataField` an ein Feld. Die Anbindung ist für alle Phase-12-Felder dieselbe (`TPPGDBValueBinding`, Schnittstelle `IPPGFieldValue`).
- Null im Feld wird zum leeren Control, und ein leeres Control schreibt Null.
- Tippen bzw. Auswählen setzt den Datensatz in Bearbeitung. Ist das nicht möglich, kommt der Feldwert zurück.
- Beim Verlassen und bei einem Post (auch über einen Navigator) wird geschrieben. Eine laufende Eingabe wird vorher übernommen.
- Fehler stehen am Feld (`ValidationState`), es erscheint kein Dialog.
- Esc setzt die Bearbeitung zurück.
