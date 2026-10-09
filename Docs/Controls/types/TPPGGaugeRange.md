# TPPGGaugeRange

Typ in Unit `PPG.Gauge` - Basis `TCollectionItem`

Ein farbiger Bereich auf dem Bogen: Anfangs- und Endwert, Signalfarbe (Kind) oder eigene Farbe (Color).

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `StartValue` | `Double` |  | Beginn des Abschnitts als Skalenwert. |
| `EndValue` | `Double` |  | Ende des Abschnitts als Skalenwert. |
| `Kind` | `TPPGGaugeRangeKind` | `grkSuccess` | Farbe des Abschnitts aus den Tokens: Erfolg (grün), Warnung (gelb), Gefahr (rot), Akzent, neutral, oder eigene Farbe (grkCustom mit Color). Die Token-Farben passen sich Preset und Dark Mode an. Werte: `grkSuccess`, `grkWarning`, `grkError`, `grkAccent`, `grkNeutral`, `grkCustom`. |
| `Color` | `TColor` | `clDefault` | Eigene Farbe des Abschnitts; wirkt nur mit Kind = grkCustom (clDefault = nicht gesetzt). |

## Verwendet in

[TPPGGaugeRanges](TPPGGaugeRanges.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
