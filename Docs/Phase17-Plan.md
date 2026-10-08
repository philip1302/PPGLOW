# Phase 17 – Detailplan: Druck, PDF und HTML wie am Bildschirm

*Stand 08.10.2026. Teil von `Docs\Roadmap3.md`. **Entwurf, wartet auf OK.***

## Ausgangslage
- Der xlsx-Export übernimmt seit dem 08.10.2026 die Optik des Grids über `IPPGTableLook`.
- `TPPGGridPrinter` (Druck und PDF) zeichnet dagegen mit festen Farben (Kopf `$F0F0F0`, Linien `$A0A0A0`). Es fehlen Bänder, Gruppenzeilen, Summenzeile, Spalten- und Zebra-Stile sowie die Grid-Schrift für den Kopf. Verbundene Zellen fehlen ebenfalls (offen seit Phase 13).
- `PPGExportHtmlText` kennt nur bedingte Formate (Fläche, Text, fett). Kopf, Bänder, Linien, Gruppen, Summen und Zellarten fehlen.
- Planer- und Kanban-Druck zeichnen das echte Control mit kopierten Stilen und sind nicht betroffen. Sie werden nur gegengeprüft.

## Ziel
Ausdruck, PDF und HTML zeigen dasselbe wie das Grid in heller Darstellung, so wie der xlsx-Export.

## 17a – Gemeinsame Grundlage
- `IPPGTableLook` bekommt `ExportFooterText(ACol): string`, also den Text der Summenzeile wie im Grid (`FooterText`, DB-Grid: `FooterField`/`OnGetFooterText`). Damit können Druck und HTML die Summe ohne Formel ausgeben.
- Eine kleine Hilfsunit `PPG.Grid.Look` bündelt, was alle drei Ausgaben brauchen:
  - Zeilenfolge aus der Gliederung (Gruppenkopf/Datenzeile, Ebene)
  - Bänder je Ebene
  - aufgelöster Zellstil (Spalte → Zebra → bedingt → Ereignis)
  - Kästchen- und Sternetext
  - So rechnen xlsx, Druck und HTML nicht dreimal dasselbe (DRY).

## 17b – Druck und PDF (`TPPGGridPrinter`)
- Neue Property **`UseGridLook`** (Vorgabe True). Mit False bleibt es beim bisherigen Graustufen-Druck. `PrintColors = False` druckt wie bisher ohne Flächen.
- Kopf: Bandzeilen (verbunden über die Spalten), dann die Spaltenköpfe mit Grid-Schrift, Farben, `TitleStyle` und Kopfausrichtung. Bei `RepeatHeader` auf jeder Seite.
- Daten:
  - Spaltenstile, Zebra, bedingte Formate, Schriftstil je Zelle, Linienfarbe wie im Grid
  - Zellarten wie bisher über `IPPGCellKind.PaintCell`, aber mit den Grid-Farben (Akzent, Sterne)
- Gruppenzeilen (Fläche, Text, Einrückung je Ebene). Ein Gruppenkopf bleibt nie allein am Seitenende stehen.
- Verbundene Zellen (`ExportMerges`), offen seit Phase 13. Verbindungen, die über einen Seitenwechsel reichen, werden je Seite getrennt gezeichnet.
- Summenzeile am Ende der letzten Seite.
- Seitenaufteilung (`Layout`) zählt Gruppen-, Band- und Summenzeilen mit. Die Seitenzahl in der Vorschau stimmt dadurch.

## 17c – HTML (`PPGExportHtmlText`)
- Kopf mit Bändern (`colspan`), Spaltenköpfe, Gruppenzeilen (`colspan`, Einrückung), Summenzeile (`<tfoot>`)
- Inline-Stile aus `IPPGTableLook`: Schrift, Farben, Linien, Ausrichtung, Zebra, Spaltenstile, bedingte Formate
- Zellarten:
  - Kästchen ☑/☐, Sterne in Gold
  - Fortschritt und Datenbalken als CSS-Hintergrund (`linear-gradient`)
  - Farbzellen gefüllt, Links als `<a href>`
- Ohne `IPPGTableLook` bleibt die einfache Tabelle wie bisher.

## 17d – Prüfung
- Tests:
  - Druck über die Vorschau-Bitmap (Pixel: Kopf-, Gruppen-, Summen- und Zebrafarbe, rote Fläche bei bedingtem Format; Seitenzahl mit Gruppen)
  - HTML (Bänder `colspan`, `tfoot`, Kästchen, Datenbalken-Verlauf)
  - Gegenprobe `UseGridLook = False` wie bisher
- Demo:
  - Selbsttest-Szenario für Vorschau und HTML
  - Sichtprüfung PDF (über „Microsoft Print to PDF“, Seite als PNG über `Windows.Data.Pdf`) und HTML-Screenshot im Vergleich mit dem Grid-Screenshot
- Planer- und Kanban-Druck einmal ansehen (nur prüfen).
- Win32 und Win64, Leak-Lauf, Regel-Prüfer, Doku (Architektur, Grid-Hilfe, Property-Referenz für `UseGridLook`).

## Entscheidungen (Empfehlung zuerst)
1. **Summenzeile im Druck:** nur am Ende der letzten Seite *(Empfehlung)*, oder Zwischensummen je Seite?
2. **Gruppenkopf am Seitenende:** mit der ersten Datenzeile zusammenhalten *(Empfehlung)*.
3. **Verbundene Zellen im Druck** gleich mitbauen *(Empfehlung)*, oder später?
4. **Vorgabe `UseGridLook = True`** *(Empfehlung)*. Bestehende Ausdrucke werden dadurch farbig wie das Grid, mit `False` lässt sich das alte Verhalten wiederherstellen.
5. **Links im HTML** als echte `<a href>` *(Empfehlung)*, oder nur eingefärbt?
