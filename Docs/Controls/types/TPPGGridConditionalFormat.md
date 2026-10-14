# TPPGGridConditionalFormat

Typ in Unit `PPG.Grid.Styles` - Basis `TCollectionItem`

Eine Regel der bedingten Formatierung: Spalte, Regel, Vergleichswerte, Farbe, Ziel (Fläche oder Text) und Fett.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Column` | `Integer` | `-1` | Datenspalte der Regel; -1 = alle Spalten (nur für Regeln ohne Statistik, also nicht für Oben/Unten, Farbskala, Datenbalken, Symbolsatz). Praxis: Die Datenspalte der Regel, z. B. die Bestandsspalte. -1 nur für einfache Regeln über alle Spalten, etwa „enthält Fehler“. |
| `Rule` | `TPPGCondRule` | `crRange` | Art der Regel: crRange (Wert zwischen Value1 und Value2), crEqual (gleich Value1), crContains (Text enthält Value1), crTop/crBottom (oberste/unterste N bzw. N %), crColorScale (Farbverlauf nach Wert), crDataBar (Balken nach Wert), crIconSet (Pfeile hoch/gleich/runter). Werte: `crRange`, `crEqual`, `crContains`, `crTop`, `crBottom`, `crColorScale`, `crDataBar`, `crIconSet`. Praxis: crRange für Schwellen (Bestand 0 bis 9), crEqual für Status, crContains für Stichworte, crTop für die besten N, crDataBar und crColorScale für Vergleiche auf einen Blick. |
| `Value1` | `string` |  | Erster Vergleichswert: bei crRange „von" (leer = offen), bei crEqual/crContains der Wert, bei crTop/crBottom die Anzahl („10" oder „10%"). Nutzung: `Rule := crTop; Value1 := '10%';` Praxis: Untergrenze bzw. Vergleichswert, z. B. „0“ bei Bestand 0 bis 9, „offen“ bei crEqual oder „10“ bzw. „10%“ bei crTop. |
| `Value2` | `string` |  | Zweiter Vergleichswert: bei crRange „bis" (leer = offen). Praxis: Obergrenze bei crRange, z. B. „9“ für „weniger als 10 Stück“; leer lassen für „ab Value1“. |
| `Color` | `TPPGCondColor` | `ccWarning` | Farbe der Regel aus dem Theme: ccWarning, ccSuccess, ccDanger, ccAccent oder ccCustom (= CustomColor). Bei Farbskalen bestimmt ccSuccess/ccDanger die Richtung (niedrig rot, hoch grün bzw. umgekehrt). Werte: `ccWarning`, `ccSuccess`, `ccDanger`, `ccAccent`, `ccCustom`. Praxis: ccDanger für Probleme (überfällig, zu wenig Bestand), ccWarning für Hinweise, ccSuccess für Erreichtes. Theme-Farben passen in Hell und Dunkel; ccCustom nur für Hausfarben. |
| `CustomColor` | `TColor` | `clDefault` | Eigene Farbe bei Color = ccCustom. Praxis: Eigene Farbe bei Color = ccCustom, z. B. die Firmenfarbe für den eigenen Standort; auf Lesbarkeit im Dark Mode achten. |
| `Target` | `TPPGCondTarget` | `ctFill` | Was eingefärbt wird: ctFill (Zellfläche) oder ctText (Schrift). Werte: `ctFill`, `ctText`. Praxis: ctFill (Fläche) fällt am stärksten auf; ctText für dezentere Hinweise, z. B. negative Beträge in Rot. |
| `Bold` | `Boolean` | `False` | True: Treffer werden zusätzlich fett dargestellt. Praxis: Zusätzlich zur Farbe einschalten, damit der Treffer auch ohne Farbwahrnehmung (Farbenblindheit, Schwarzweißdruck) auffällt. |
| `Enabled` | `Boolean` | `True` | False: Die Regel ist vorübergehend abgeschaltet. Praxis: Regeln vorübergehend abschalten, z. B. per Schalter „Hervorhebungen anzeigen“, ohne sie zu löschen. |

## Verwendet in

[TPPGGridConditionalFormats](TPPGGridConditionalFormats.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
