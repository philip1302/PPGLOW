**Vorbild:** TMS TAdvFileNameEdit / TAdvDirectoryEdit

## Wofür

Das Dateifeld nimmt einen Pfad auf: eine Datei zum Öffnen, ein Speicherziel oder einen Ordner. Der Anwender tippt den Pfad (mit Autovervollständigung), wählt ihn über den Knopf im Feld oder zieht ihn aus dem Explorer hinein. Es ersetzt die übliche Kombination aus `TEdit`, „…“-Button und `TOpenDialog` in einem Control.

## Wann verwenden

- Für Pfade in Import-, Export- und Einstellungsdialogen: Quelldatei, Speicherziel, Arbeits- oder Sicherungsordner.
- Statt `TPPGEdit` mit eigenem Durchsuchen-Button: Dialog, Filter, Ablegen und Existenzprüfung (`MustExist`) sind schon eingebaut.
- Statt eines einzelnen `TOpenDialog` hinter einem Button, wenn der Pfad sichtbar bleiben und gespeichert werden soll. Für einen einmaligen Befehl „Datei öffnen …“ reicht der Dialog allein.
- Nicht für mehrere Dateien auf einmal: Das Feld hält genau einen Pfad. Für Listen von Anhängen eine Liste mit eigenem Hinzufügen-Button nehmen.

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
