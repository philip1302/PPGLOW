**Vorbild:** TDBImage

## Wofür

Zeigt ein Bild aus einem BLOB-Feld an (Foto, Logo, Unterschrift) und schreibt es zurück, wenn der Anwender es ersetzt.

## Wann verwenden

- Für Formulare, die bisher `TDBImage` benutzen: Der DFM-Tausch ist 1:1 (`DataSource`, `DataField`, `AutoDisplay`, `BorderStyle`, `Stretch`, `Proportional`, `Center`, `QuickDraw`, `ReadOnly` …).
- Wenn ein leeres Feld ein Platzhalterbild zeigen soll (`Images` mit `ImageIndex` bzw. `ImageName`) oder die Bytes im Feld in einem bestimmten Format liegen sollen (`StoreFormat`).

## Unterschiede und Hinweise

- Das Grafikformat wird an den ersten Bytes erkannt: BMP, PNG, JPEG, GIF, TIFF, ICO und WMF/EMF. `ImageFormat` zeigt das Ergebnis (`ifNone` = leer, `ifUnknown` = Daten nicht erkannt; dann bleibt die Fläche leer). Ältere Feldformate mit eigenem Kopf (BDE/Paradox-Grafikfelder) gehören nicht dazu.
- Bedienung wie `TDBImage`: Strg+C / Strg+Einfg kopiert, Strg+V / Umschalt+Einfg fügt ein, Strg+X / Umschalt+Entf schneidet aus, Enter lädt bei `AutoDisplay = False`, Esc setzt den Wert zurück.
- Änderungen (Einfügen, `LoadFromFile`, `Picture`) setzen den Datensatz in den Bearbeiten-Modus und werden beim Speichern des Datensatzes ins Feld geschrieben. Mit `ReadOnly` oder einem nicht änderbaren Feld bleibt das alte Bild.
- `StoreFormat = sfKeep` schreibt das Bild in seinem eigenen Format (ein eingefügtes Bitmap als BMP). `sfPng`, `sfJpeg`, `sfGif` und `sfBitmap` wandeln beim Schreiben um.
- `LoadFromFile`, `LoadFromStream` (unbekanntes Format: `EPPGError`, das alte Bild bleibt), `SaveToFile`, `SaveToStream` und `Clear` sind zusätzlich da.
- Rahmen und Farben folgen dem Theme (Dark Mode, Hochkontrast); `BorderStyle = bsSingle` (Vorgabe wie `TDBImage`) zeichnet einen Rand in der Randfarbe des Themes.
- `QuickDraw` ist nur für die Kompatibilität da und wirkt nicht (WIC dekodiert JPEG immer schnell).

## Beispiel

```pascal
DBImage1.DataSource := DataSource1;
DBImage1.DataField := 'Foto';
DBImage1.Stretch := True;
DBImage1.Proportional := True;
DBImage1.StoreFormat := sfPng;      // neue Bilder als PNG ins Feld
DBImage1.LoadFromFile('neu.jpg');   // Datensatz geht in den Bearbeiten-Modus
```
