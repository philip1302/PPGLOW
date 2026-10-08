# TPPGGridConditionalFormat

Typ in Unit `PPG.Grid.Styles` - Basis `TCollectionItem`

Eine Regel der bedingten Formatierung: Spalte, Regel, Vergleichswerte, Farbe, Ziel (Fläche oder Text) und Fett.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Column` | `Integer` | `-1` | Datenspalte der Regel; -1 = alle Spalten (nur für Regeln ohne Statistik, also nicht für Oben/Unten, Farbskala, Datenbalken, Symbolsatz). |
| `Rule` | `TPPGCondRule` | `crRange` | Art der Regel: crRange (Wert zwischen Value1 und Value2), crEqual (gleich Value1), crContains (Text enthält Value1), crTop/crBottom (oberste/unterste N bzw. N %), crColorScale (Farbverlauf nach Wert), crDataBar (Balken nach Wert), crIconSet (Pfeile hoch/gleich/runter). Werte: `crRange`, `crEqual`, `crContains`, `crTop`, `crBottom`, `crColorScale`, `crDataBar`, `crIconSet`. |
| `Value1` | `string` |  | Erster Vergleichswert: bei crRange „von" (leer = offen), bei crEqual/crContains der Wert, bei crTop/crBottom die Anzahl („10" oder „10%"). Nutzung: `Rule := crTop; Value1 := '10%';` |
| `Value2` | `string` |  | Zweiter Vergleichswert: bei crRange „bis" (leer = offen). |
| `Color` | `TPPGCondColor` | `ccWarning` | Farbe der Regel aus dem Theme: ccWarning, ccSuccess, ccDanger, ccAccent oder ccCustom (= CustomColor). Bei Farbskalen bestimmt ccSuccess/ccDanger die Richtung (niedrig rot, hoch grün bzw. umgekehrt). Werte: `ccWarning`, `ccSuccess`, `ccDanger`, `ccAccent`, `ccCustom`. |
| `CustomColor` | `TColor` | `clNone` | Eigene Farbe bei Color = ccCustom. |
| `Target` | `TPPGCondTarget` | `ctFill` | Was eingefärbt wird: ctFill (Zellfläche) oder ctText (Schrift). Werte: `ctFill`, `ctText`. |
| `Bold` | `Boolean` | `False` | True: Treffer werden zusätzlich fett dargestellt. |
| `Enabled` | `Boolean` | `True` | False: Die Regel ist vorübergehend abgeschaltet. |

## Verwendet in

[TPPGGridConditionalFormats](TPPGGridConditionalFormats.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
