# TPPGGaugeRanges

Typ in Unit `PPG.Gauge` - Basis `TOwnedCollection`

Farbige Bereiche auf dem Bogen der Anzeige (z. B. grün/gelb/rot).

Nutzung: `with PPGGauge1.Ranges.Add do begin StartValue := 80; EndValue := 100; Kind := grkError; end;`

Collection: Die Eintraege sind vom Typ [TPPGGaugeRange](TPPGGaugeRange.md). Im Designer ueber den Collection-Editor (Doppelklick auf die Eigenschaft), im Code ueber `Add`, `Items[i]`, `Count`, `Delete`, `Clear`.

## Verwendet in

[TPPGGauge](../TPPGGauge.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
