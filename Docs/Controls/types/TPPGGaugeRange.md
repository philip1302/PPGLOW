# TPPGGaugeRange

Typ in Unit `PPG.Gauge` - Basis `TCollectionItem`

Ein farbiger Bereich auf dem Bogen: Anfangs- und Endwert, Signalfarbe (RangeColor) oder eigene Farbe (CustomColor).

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `StartValue` | `Double` |  | Beginn des Abschnitts als Skalenwert. |
| `EndValue` | `Double` |  | Ende des Abschnitts als Skalenwert. |
| `RangeColor` | `TPPGGaugeRangeColor` | `grcSuccess` | Farbe des Abschnitts aus den Tokens: Erfolg (grün), Warnung (gelb), Gefahr (rot), Akzent, neutral, oder eigene Farbe (CustomColor). Die Token-Farben passen sich Preset und Dark Mode an. Werte: `grcSuccess`, `grcWarning`, `grcDanger`, `grcAccent`, `grcNeutral`, `grcCustom`. |
| `CustomColor` | `TColor` | `clNone` | Eigene Farbe des Abschnitts; wirkt nur mit RangeColor = grcCustom. |

## Verwendet in

[TPPGGaugeRanges](TPPGGaugeRanges.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
