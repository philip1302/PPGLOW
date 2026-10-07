**Vorbild:** TMS TAdvFileNameEdit / TAdvDirectoryEdit

## Unterschiede und Hinweise

- `Kind`: Datei öffnen, Datei speichern oder Ordner.
- Der Knopf im Feld (oder Alt+Pfeil runter, F4) öffnet ab Vista `TFileOpenDialog`/`TFileSaveDialog`. Davor gibt es `TOpenDialog`/`TSaveDialog`, für Ordner `SHBrowseForFolder`. `Filter` im VCL-Format wird in Dateitypen umgesetzt.
- Dateien aus dem Explorer lassen sich ablegen: Es zählt die erste Datei bzw. der erste Ordner, der zu `Kind` passt.
- Die Autovervollständigung von Pfaden kommt von Windows (`SHAutoComplete`).
- `MustExist`: Eine fehlende Datei bzw. ein fehlender Ordner steht beim Verlassen als Fehler am Feld. Ein leeres Feld ist gültig.
- `OnBeforeDialog` kann den Dialog abbrechen, `OnAfterDialog` den gewählten Namen ändern oder ablehnen.

## Beispiel

```pascal
PPGFileEdit1.Kind := fkOpenFile;
PPGFileEdit1.Filter := 'Dokumente|*.pdf;*.docx|Alle Dateien|*.*';
PPGFileEdit1.MustExist := True;
```
