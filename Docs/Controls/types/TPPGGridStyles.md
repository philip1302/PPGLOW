# TPPGGridStyles

Typ in Unit `PPG.Grid.Styles` - Basis `TPPGStyleGroup`

Bereiche des Grids (Anpassbarkeit). Nur gesetzte Werte ueberschreiben die vom Preset berechneten Farben (clDefault = Preset).

Zehn Bereiche des Grids einzeln gestalten: Kopf, Fußzeile, Auswahl, Auswahl ohne Fokus, Zebra-Zeile, Hover-Zeile, Gitterlinien, fokussierte Zelle, Gruppenzeile und Filterzeile. Nicht gesetzte Werte kommen aus dem Preset.

Nutzung: `PPGGrid1.Styles.Header.Color := clNavy; PPGGrid1.Styles.AlternateRow.Color := $00FAF5EE;`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Header` | [TPPGElementStyle](TPPGElementStyle.md) |  | Kopfzeilen, feste Spalten und Bänder: Color = Fläche, TextColor = Text, BorderColor = Linien im Kopf, Font/FontStyle = Schrift. Nutzung: `Grid1.Styles.Header.Color := clNavy; Grid1.Styles.Header.TextColor := clWhite;` |
| `Footer` | [TPPGElementStyle](TPPGElementStyle.md) |  | Summenzeile (ShowFooter) und Gruppenfuß; ohne eigene Werte wie Header. |
| `Selection` | [TPPGElementStyle](TPPGElementStyle.md) |  | Auswahl, solange das Grid den Fokus hat. Mit gesetzter Color wird sie deckend statt halbtransparent gezeichnet. |
| `SelectionInactive` | [TPPGElementStyle](TPPGElementStyle.md) |  | Auswahl, wenn das Grid den Fokus nicht hat. |
| `AlternateRow` | [TPPGElementStyle](TPPGElementStyle.md) |  | Zebra: jede zweite Datenzeile. Erst Color setzen schaltet es ein. |
| `HotRow` | [TPPGElementStyle](TPPGElementStyle.md) |  | Zeile unter der Maus. Erst Color setzen schaltet die Hervorhebung ein. |
| `GridLine` | [TPPGElementStyle](TPPGElementStyle.md) |  | Gitterlinien: Color = Linienfarbe (Breite über GridLineWidth). |
| `FocusedCell` | [TPPGElementStyle](TPPGElementStyle.md) |  | Die Zelle mit Tastaturfokus: BorderColor = Rahmen, Color = Fläche, TextColor = Text. |
| `GroupRow` | [TPPGElementStyle](TPPGElementStyle.md) |  | Gruppenkopf-Zeilen beim Gruppieren. |
| `FilterRow` | [TPPGElementStyle](TPPGElementStyle.md) |  | Die Filterzeile unter dem Kopf (ShowFilterRow). |

## Verwendet in

[TPPGDBGrid](../TPPGDBGrid.md), [TPPGGrid](../TPPGGrid.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
