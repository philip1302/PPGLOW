# TPPGChartSeriesList

Typ in Unit `PPG.Chart.Series` - Basis `TOwnedCollection`

Die Datenreihen des Diagramms (Collection). Jede Reihe hat Art (Linie, Säule, Kreis …), Werte und Farbe.

Nutzung: `with PPGChart1.Series.Add do begin Title := 'Umsatz'; ValuesText := '12;15;9;20'; end;`

Collection: Die Eintraege sind vom Typ [TPPGChartSeries](TPPGChartSeries.md). Im Designer ueber den Collection-Editor (Doppelklick auf die Eigenschaft), im Code ueber `Add`, `Items[i]`, `Count`, `Delete`, `Clear`.

## Verwendet in

[TPPGChart](../TPPGChart.md), [TPPGDBChart](../TPPGDBChart.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
