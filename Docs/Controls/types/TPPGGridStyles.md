# TPPGGridStyles

Typ in Unit `PPG.Grid.Styles` - Basis `TPPGStyleGroup`

Bereiche des Grids (Anpassbarkeit). Nur gesetzte Werte ueberschreiben die vom Preset berechneten Farben (clDefault = Preset).

Zehn Bereiche des Grids einzeln gestalten: Kopf, Fußzeile, Auswahl, Auswahl ohne Fokus, Zebra-Zeile, Hover-Zeile, Gitterlinien, fokussierte Zelle, Gruppenzeile und Filterzeile. Nicht gesetzte Werte kommen aus dem Preset.

Nutzung: `PPGGrid1.Styles.Header.Color := clNavy; PPGGrid1.Styles.AlternateRow.Color := $00FAF5EE;`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Header` | [TPPGElementStyle](TPPGElementStyle.md) |  | Kopfzeilen, feste Spalten und Bänder: Color = Fläche, TextColor = Text, BorderColor = Linien im Kopf, Font/FontStyle = Schrift. Nutzung: `Grid1.Styles.Header.Color := clNavy; Grid1.Styles.Header.TextColor := clWhite;` Praxis: Kopf in der Hausfarbe oder fett (FontStyle = [fsBold]); bei eigener Color auch DarkColor setzen. |
| `Footer` | [TPPGElementStyle](TPPGElementStyle.md) |  | Summenzeile (ShowFooter) und Gruppenfuß; ohne eigene Werte wie Header. Praxis: Die Summenzeile absetzen, z. B. FontStyle = [fsBold]; ohne eigene Werte sieht sie aus wie der Kopf. |
| `Selection` | [TPPGElementStyle](TPPGElementStyle.md) |  | Auswahl, solange das Grid den Fokus hat. Mit gesetzter Color wird sie deckend statt halbtransparent gezeichnet. Praxis: Eigene Auswahlfarbe nur, wenn die Akzentfarbe des Presets nicht passt; mit Color wird die Auswahl deckend. |
| `SelectionInactive` | [TPPGElementStyle](TPPGElementStyle.md) |  | Auswahl, wenn das Grid den Fokus nicht hat. Praxis: Auswahl ohne Fokus sichtbar halten, z. B. hellgrau, damit man beim Arbeiten in den Detailfeldern sieht, welcher Datensatz gewählt ist. |
| `AlternateRow` | [TPPGElementStyle](TPPGElementStyle.md) |  | Zebra: jede zweite Datenzeile. Erst Color setzen schaltet es ein. Praxis: Zebra-Zeilen für breite Listen, damit das Auge in der Zeile bleibt: Color auf einen sehr hellen Ton setzen und DarkColor auf einen leicht helleren dunklen Ton. |
| `HotRow` | [TPPGElementStyle](TPPGElementStyle.md) |  | Zeile unter der Maus. Erst Color setzen schaltet die Hervorhebung ein. Praxis: Zeile unter der Maus hervorheben, hilfreich bei breiten Listen; Color setzen schaltet es ein. |
| `GridLine` | [TPPGElementStyle](TPPGElementStyle.md) |  | Gitterlinien: Color = Linienfarbe (Breite über GridLineWidth). Praxis: Linien heller machen, wenn die Tabelle unruhig wirkt; zusammen mit GridLineWidth. |
| `FocusedCell` | [TPPGElementStyle](TPPGElementStyle.md) |  | Die Zelle mit Tastaturfokus: BorderColor = Rahmen, Color = Fläche, TextColor = Text. Praxis: Einen kräftigeren Rahmen (BorderColor) für die Fokuszelle in Erfassungsmasken, in denen viel per Tastatur gearbeitet wird. |
| `GroupRow` | [TPPGElementStyle](TPPGElementStyle.md) |  | Gruppenkopf-Zeilen beim Gruppieren. Praxis: Gruppenköpfe deutlicher absetzen, z. B. mit getönter Fläche und fetter Schrift, damit Gruppen beim Scrollen erkennbar bleiben. |
| `FilterRow` | [TPPGElementStyle](TPPGElementStyle.md) |  | Die Filterzeile unter dem Kopf (ShowFilterRow). Praxis: Die Filterzeile dezent absetzen, z. B. mit leicht getönter Fläche, damit sie nicht wie eine Datenzeile wirkt. |

## Verwendet in

[TPPGDBGrid](../TPPGDBGrid.md), [TPPGGrid](../TPPGGrid.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
