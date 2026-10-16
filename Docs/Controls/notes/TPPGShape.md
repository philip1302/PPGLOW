**Vorbild:** TShape

## Wofür

Eine einfache geometrische Form als Dekoration: Rahmen um eine Gruppe, farbiger Punkt als Statusanzeige, Trennfläche.

## Wann verwenden

- Für Formulare, die bisher `TShape` benutzen: Der DFM-Tausch ist 1:1 (`Shape`, `Brush`, `Pen` heißen und streamen wie in der VCL).
- Für eine Statusanzeige (Kreis grün/rot) mit weichen Kanten, auch bei hoher DPI.

## Unterschiede und Hinweise

- Grafisches Control (kein Fenster), Zeichnen über den Renderer der Suite: Fläche und Rand sind kantengeglättet (GDI+), ohne GDI+ wie bei `TShape`.
- Die Vorgabefarben (`Brush` weiß bzw. Fensterfarbe, `Pen` schwarz) folgen im Dark Mode und im Hochkontrast den Theme-Farben (wie `TPPGLabel`); eigene Farben bleiben. Im hellen Modus sieht die Form mit Vorgabefarben genau wie `TShape` aus. `ThemeColors = False` schaltet das ab.
- Gestrichelte Stifte, Schraffuren und Bitmap-Pinsel zeichnet die VCL wie bei `TShape` (ohne Kantenglättung).
- `stRoundRect`/`stRoundSquare`: Eckenrundung wie `TShape` (ein Achtel der kurzen Seite).

## Beispiel

```pascal
Shape1.Shape := stCircle;
Shape1.Brush.Color := clLime;   // eigene Farbe, bleibt auch im Dark Mode
Shape1.Pen.Style := psClear;
```
