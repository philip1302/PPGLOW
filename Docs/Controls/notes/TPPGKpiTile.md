**Vorbild:** Dashboard-Kacheln (Power BI „Card“, TMS FNC Tile)

## Unterschiede und Hinweise

- Wert über `Value` + `ValueFormat` oder frei über `ValueText`; `Units` wird mit Leerzeichen angehängt.
- Trendpfeil und Farbe aus `Change`: steigend = Erfolg, fallend = Fehler; `InvertTrend` dreht das um (z. B. Fehlerquote).
- Eingebettete Sparkline über `SparklineText` bzw. `SetSparkline`; sie entfällt, wenn die Kachel zu niedrig ist.
- Klick, Leertaste und Enter lösen `OnClick` aus. Mit `OnClick` meldet sich die Kachel beim Screenreader als Schaltfläche.

## Beispiel

```pascal
PPGKpiTile1.Title := 'Retourenquote';
PPGKpiTile1.ValueText := FormatFloat('0.0', Quote) + ' %';
PPGKpiTile1.Change := Quote - QuoteVormonat;
PPGKpiTile1.InvertTrend := True;
```
