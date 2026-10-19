**Vorbild:** TImage

## Wofür

Zeigt ein Bild an: Logo, Symbol, Foto, Vorschau. Das Bild kommt aus `Picture` (BMP, PNG, JPEG, GIF, TIFF, ICO, WMF/EMF) oder aus einer Bildliste (`Images` mit `ImageIndex` bzw. `ImageName`).

## Wann verwenden

- Für Formulare, die bisher `TImage` benutzen: Der DFM-Tausch ist 1:1 (`Picture`, `Stretch`, `Proportional`, `Center`, `Transparent`, `AutoSize` und `IncrementalDisplay` heißen und streamen wie in der VCL; `DestRect` und `Canvas` gibt es auch).
- Wenn ein Bild im Dark Mode anders aussehen soll (`PictureDark` bzw. `ImageIndexDark`/`ImageNameDark`) oder ein Symbol aus einer `TImageCollection` über den Namen kommen soll.
- Wenn das Bild einen Rand in der Farbe des Themes braucht (`BorderStyle = bsSingle`).

## Unterschiede und Hinweise

- Grafisches Control (kein Fenster) wie `TImage`; die Platzierung (`Stretch`, `Proportional`, `Center`) rechnet genau wie `TImage.DestRect`.
- Bildliste: Das Bild wird in der Größe der Liste gezeichnet (die Liste skaliert sich selbst mit der DPI) und mit `Stretch`/`Proportional` eingepasst. Ein `ImageName` wird beim Laden in den Index aufgelöst; gespeichert wird nur der Name, nicht der Index.
- Dunkelmodus: Im Dark Mode der Suite ersetzt `PictureDark` bzw. das Listenbild `ImageIndexDark`/`ImageNameDark` das helle Bild. Ohne Eintrag bleibt das helle Bild. Im Hochkontrast gilt immer das helle Bild.
- `DpiScaling = True` vergrößert Bilder aus `Picture` mit der DPI des Controls (natürliche Größe und `AutoSize`). Vorgabe aus wie bei `TImage`.
- Deaktiviert (`Enabled = False`) zeigt das Bild grau und blasser, bei jeder Bildart und auch mit Alpha.
- Rand: `BorderStyle = bsSingle` zeichnet einen Rand in der Randfarbe des Themes (Dark Mode, Hochkontrast, deaktiviert); `AutoSize` rechnet ihn mit ein.
- PNG, JPEG, GIF und TIFF decodiert das `TWICImage` der VCL, deshalb braucht `PPGlowR` das Paket `vclimg` nicht. Wer ein `Picture` mit `TPngImage` oder `TJPEGImage` in der DFM hat, bindet die Unit `Vcl.Imaging.pngimage` bzw. `Vcl.Imaging.jpeg` wie bei `TImage` selbst ein.
- Nicht übernommen: animierte GIFs (es wird das erste Bild gezeigt). `IncrementalDisplay` ist nur für die Kompatibilität da und wirkt nicht.

## Beispiel

```pascal
Image1.Picture.LoadFromFile('logo.png');
Image1.Stretch := True;
Image1.Proportional := True;
Image1.Center := True;
Image1.PictureDark.LoadFromFile('logo-hell.png');  // im Dark Mode
Image1.BorderStyle := bsSingle;
```
