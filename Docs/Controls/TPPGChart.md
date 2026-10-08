# TPPGChart

Palette **PPGlow** - Unit `PPG.Chart` - Basis `TPPGCustomChart`

**Vorbild:** TMS FNC Chart, TeeChart (Grundfunktionen)

## Unterschiede und Hinweise

- Bewusst kein TeeChart-Nachbau: kein 3D, keine Finanz-Charts, kein Zoom/Pan, keine logarithmische Achse, keine Splines.
- Serienarten: Linie, Stufe, Fläche, Säule, Balken, Kreis, Ring. Sind alle sichtbaren Serien Balken, liegt das Diagramm quer; ist die erste sichtbare Serie ein Kreis/Ring, zeigt es nur diese.
- `Stacking` (gestapelt, 100 %) gilt für Säulen, Balken und Flächen auf der Kategorieachse.
- Datenänderungen gleiten (bis 10 000 Punkte). Mehrere Änderungen in `BeginDataUpdate`/`EndDataUpdate` ergeben einen Übergang. `Append(Y, MaxCount)` für Live-Daten.
- Virtueller Modus: `Series.VirtualCount` + `OnGetPoint`.
- Der Tooltip ist Teil des Controls (kein eigenes Fenster) und erscheint deshalb auch in Screenshots. `SaveToBitmap`/`SaveToPng`/`CopyToClipboard` zeigen immer den Endzustand.
- Screenreader: Kinder sind die Datenpunkte (höchstens 500 je Serie).

## Anpassung

- `ChartStyles` (Titel, Achse, Gitter, Legende), `TitleFont`, `LegendFont`; Serienfarben ohne eigene Farbe aus `TPPGStyleManager.ChartPalette`.

## Beispiel

```pascal
var
  S: TPPGChartSeries;
begin
  PPGChart1.Categories.CommaText := 'Jan,Feb,Mrz';
  S := PPGChart1.Series.Add;
  S.Title := 'Umsatz';
  S.Kind := cskColumn;
  S.SetValues([12, 15, 11]);
  PPGChart1.ReferenceLines.Add.Value := 13;
end;
```

## Verhalten (aus dem Quelltext)

TPPGChart - Diagramm im Stil der Suite (Phase 10d).

- Serien (PPG.Chart.Series): Linie, Stufe, Flaeche, Saeule, Balken, Kreis, Ring. Linien, Flaechen und Saeulen lassen sich mischen; sind alle sichtbaren Serien Balken, liegt das Diagramm quer (Kategorien senkrecht). Ist die erste sichtbare Serie ein Kreis/Ring, zeigt das Diagramm nur sie.
- Achsen: X als Kategorie, Zahl oder Datum/Zeit; Y links und optional eine zweite Y-Achse rechts (Series.YAxis = casSecondary). Grenzen automatisch (PPG.Chart.Scale) oder fest; Referenzlinien (ReferenceLines).
- Stapeln (Stacking) fuer Saeulen, Balken und Flaechen auf der Kategorieachse, auch als 100 %.
- Legende oben, unten oder rechts; Klick blendet eine Serie aus/ein (animiert).
- Tooltip beim Ueberfahren: rastet auf den naechsten X-Wert ein (Linie ueber alle Serien) bzw. auf das Segment beim Kreis. Der Tooltip ist Teil des Controls (kein eigenes Fenster): er erscheint so auch beim Export und in Screenshots.
- Tastatur: Pfeile links/rechts laufen durch die Punkte, hoch/runter bzw. Bild wechseln die Serie, Pos1/Ende, Enter/Leertaste = OnPointClick, Esc blendet den Tooltip aus.
- Animation ueber den gemeinsamen Animator: Aufbau beim ersten Zeigen, weicher Uebergang bei Datenaenderungen (bis 10 000 Punkte), Ein-/ Ausblenden von Serien.
- Viele Punkte: Linien werden pro Pixelspalte auf Min/Max verdichtet.
- Export: SaveToBitmap, SaveToPng, CopyToClipboard (gleicher Zeichenweg).
- Screenreader: Rolle Diagramm, Kinder = Datenpunkte ("Serie, Kategorie: Wert"), hoechstens 500 je Serie.
- RTL: Y-Achse rechts, Legende von rechts; die X-Richtung bleibt (wie Excel).

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `HighContrastSupport`, `Title`, `Series`, `Categories`, `XAxis`, `YAxis`, `Y2Axis`, `ReferenceLines`, `Stacking`, `LegendPosition`, `ShowTooltips`, `LegendToggle`, `ChartStyles`, `Align`, `Anchors`, `BiDiMode`, `Constraints`, `Enabled`, `Font`, `Hint`, `ParentBiDiMode`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `TabOrder`, `TabStop`, `Visible`, `Touch`

## Ereignisse

`OnGesture`, `OnClick`, `OnDblClick`, `OnEnter`, `OnExit`, `OnGetPoint`, `OnMouseDown`, `OnMouseMove`, `OnMouseUp`, `OnPointClick`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGChart.md`.
