# Wirkungstest TPPGGrid (14.10.2026)

Vom User am 14.10.2026 beauftragt, nachdem im Inspektor `Styles.HotRow.BorderColor` und `Font.Color` ohne Wirkung blieben: „mach diesen test erstmal nur für tppggrid“.

## Verfahren

```
Demo\PPGlowDemo.exe /effects C:\pfad\effects.txt /only TPPGGrid /hidden
```

- Für jede bearbeitbare Eigenschaft der Komponentenseite (auch in Unterobjekten und Collection-Einträgen) setzt der Test einen anderen Wert. Die Werte sind dieselben wie im Rundlauf des Selbsttests. Bei Auswahllisten probiert er bis zu 8 andere Einträge.
- Er zeichnet das Grid vorher und nachher (`PaintTo`) und vergleicht die Pixel. Danach stellt er den alten Wert sowie Lage und Größe wieder her.
- Vier Zustände, eine Eigenschaft zählt als wirksam, wenn sie in einem davon das Bild ändert:
  0. Gruppiert nach Status, mit Filterzeile, Summenzeile, Gruppenfuß, Gruppenleiste, bedingtem Format und Auswahl, ohne Fokus.
  1. Wie 0, dazu Fokus und Maus über einer Zeile (HotRow).
  2. Wie 1, im Dark Mode.
  3. Wie 0, im Dark Mode (Auswahl ohne Fokus).
- Grenze: Der Test erkennt nur, *dass* sich etwas ändert, nicht ob es das Richtige ist. Beispiel: `Font.Size` zählt als wirksam, vergrößert aber nur die Schrift in der Gruppenleiste. Die Zellen bleiben gleich (per Bild geprüft).
- Bilder vorher/nachher für einzelne Pfade: Umgebungsvariable `PPG_EFFECTS_DUMP=Pfad1;Pfad2`, die BMPs landen neben der Exe.

## Ergebnis

643 Eigenschaften: 264 mit sichtbarer Wirkung, 378 ohne, 1 nicht prüfbar (`Touch.GestureManager`, keine Auswahl).

### A. Echte Befunde (im Inspektor angeboten, wirken aber nicht)

1. **`TPPGElementStyle` je Bereich** (W = wirkt, – = ohne Wirkung):

   | Bereich | Color | TextColor | BorderColor | Font (Name/Size/Style) | Font.Color | FontStyle |
   |---|---|---|---|---|---|---|
   | Styles.Header | W | W | W | W | – | W |
   | Styles.FocusedCell | W | W | W | – | – | W |
   | Styles.Selection | W | W | – | – | – | W |
   | Styles.SelectionInactive | W | W | – | – | – | W |
   | Styles.HotRow | W | W | – | – | – | W |
   | Styles.AlternateRow | W | – | – | – | – | – |
   | Styles.Footer | W | W | – | W | – | W |
   | Styles.GroupRow | W | W | – | W | – | W |
   | Styles.FilterRow | W | – | – | W | – | W |
   | Styles.GridLine | W | (sinnlos) | – | (sinnlos) | (sinnlos) | (sinnlos) |
   | Columns[i].Style (Datenspalten) | W | W | – | W | – | W |
   | Columns[i].TitleStyle | W | W | – | W | – | W |

   Die Dark-Varianten verhalten sich wie die hellen. `Font.Color` wirkt nirgends, die Schriftfarbe kommt immer aus `TextColor`. `Font.Orientation`, `Pitch` und `Quality` wirken nirgends.
2. **`Appearance`:** 105 von 111 Feldern ohne Wirkung. Es wirken nur `Normal.BorderColor`, `BorderWidth`, `Rounding` und `FocusColor` (jeweils auch Dark). Die Sätze `Hot`, `Down`, `Disabled`, `Checked` und `Focused` sind am Grid vollständig ohne Wirkung, ebenso die Füll- und Glow-Farben, `TextColor`, `GradientDirection` und `FontStyle` von `Normal`.
3. **`Font.Size`, `Font.Name`, `Font.Style` des Grids** ändern die Zellschrift nicht, nur die Gruppenleiste. `Font.Color` wirkt.
4. **Feste Spalte `Columns[0]`** (FixedCols = 1): `Style` (alle Felder), `Visible`, `CellKind`, `Format` und `Band` ohne Wirkung.
5. `Columns[1]`/`Columns[2]` (im Band „Anschrift“): `DisplayIndex := 0` ohne Wirkung. Vermutlich verhindert das Band oder die feste Spalte das Verschieben; noch zu prüfen.

### B. Ohne Bildwirkung, fachlich in Ordnung (Verhalten, nicht Aussehen)

`Tag`, `Cursor`, `Hint`, `ShowHint`, `ParentShowHint`, `CustomHint`, `ParentCustomHint`, `HelpType`, `HelpKeyword`, `HelpContext`, `AlignWithMargins`, `Margins.*`, `Anchors`, `Constraints.MinHeight/MinWidth`, `Drag*`, `PopupMenu`, `HeaderMenu`, `SortOnHeaderClick`, `SmoothScrolling`, `ToolTips`, `TabOrder`, `TabStop`, `Touch.*`, `DoubleBuffered`, `ParentDoubleBuffered`, `ParentBiDiMode`, `ParentFont`, `Animation.*`, sowie an Spalten `EditorKind`, `PickList`, `ReadOnly`, `MinValue`, `MaxValue`, `Sortable`.

### C. Wirken nur unter Bedingungen, die der Test nicht herstellt

- `FixedColsRight`: nur beim waagerechten Scrollen.
- `GradientStartColor`/`GradientEndColor`: nur mit `DrawingStyle = gdsGradient`, laut Doku so gewollt.
- `ConditionalFormats[0].CustomColor`: nur mit `Color = ccCustom`.
- `DefaultColWidth`: nur ohne eigene Spaltenbreiten.
- `Images`: nur mit Bild-Zellen.
- `HighContrastSupport`: nur im Hochkontrast.
- `Aggregate = agCustom`: nur mit `OnCustomAggregate`.
- `Visible`: `PaintTo` zeichnet auch unsichtbare Controls, das kann der Test nicht sehen.

### D. Testwerte ohne Aussage

`CellKindName := 'x'` (kein solcher Zelltyp), `ConditionalFormats[0].Value1/Value2 := '…x'` (keine Zahl), `Format := 'x'` an Textspalten, `Bands[0].ParentBand := 0` (Verweis auf sich selbst).
