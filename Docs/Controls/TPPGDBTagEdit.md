# TPPGDBTagEdit

Palette **PPGlow DB** - Unit `PPG.DB.Fields` - Basis `TPPGTagEdit`

**Vorbild:** DB-Variante von `TPPGTagEdit` (wie `TDBEdit`)

## Unterschiede und Hinweise

- Bindet sich über `DataSource`/`DataField` an ein Feld. Die Anbindung ist für alle Phase-12-Felder dieselbe (`TPPGDBValueBinding`, Schnittstelle `IPPGFieldValue`).
- Null im Feld wird zum leeren Control, und ein leeres Control schreibt Null.
- Tippen bzw. Auswählen setzt den Datensatz in Bearbeitung. Ist das nicht möglich, kommt der Feldwert zurück.
- Beim Verlassen und bei einem Post (auch über einen Navigator) wird geschrieben. Eine laufende Eingabe wird vorher übernommen.
- Fehler stehen am Feld (`ValidationState`), es erscheint kein Dialog.
- Esc setzt die Bearbeitung zurück.

## Verhalten (aus dem Quelltext)

DB-Varianten der Eingabefelder aus Phase 12 (12g): TPPGDBMaskEdit,
TPPGDBNumberEdit, TPPGDBColorPicker, TPPGDBCheckComboBox, TPPGDBTagEdit.

Alle binden sich ueber IPPGFieldValue (PPG.Controls.Field) an das Feld -
eine Anbindung (TPPGDBValueBinding) statt einer je Feldtyp:
- Datensatz wechselt: Null -> FieldClear, sonst SetFieldValue (still, ohne OnChange). Text-Modus (Maske, Auswahl, Tags) ueber Field.Text, sonst Field.Value (Zahl, Farbe).
- Anwender aendert: Datensatz in den Bearbeiten-Modus (EditByUser), dann Modified; geht das nicht, wird der Feldwert wieder angezeigt.
- Schreiben (UpdateData, auch beim Post ueber einen Navigator): eine laufende Eingabe wird vorher uebernommen (Zahl rechnen, Tag anlegen).
- Verlassen: UpdateRecord; ein Fehler steht am Feld (ValidationState), kein Dialog (PPGDBCommitField aus Phase 9).
- TPPGDBMaskEdit uebernimmt Field.EditMask, wenn es keine eigene Maske hat.
- TPPGDBNumberEdit: AllowNull ist Vorgabe (Null ist nicht 0).
- Auswahl und Tags speichern als getrennten Text (Delimiter).

## PPGlow-Eigenschaften

`DataField`, `DataSource`, `ReadOnly`, `Tags`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBTagEdit.md`.
