# Phase 13 – Detailplan: Grid-Profi

*Stand 05.10.2026. Teil von `Docs\Roadmap2.md`. **Vom User freigegeben am 05.10.2026 (Empfehlungen übernommen).** Setzt Phase 11 (Menüs) voraus; nutzt Phase 12 (`IPPGFieldValue`) für Zell-Editoren.*

## Warum
Das Grid ist TMS' wichtigstes Produkt (TAdvStringGrid). Anwender erwarten von einem Profi-Grid:
- Gruppieren, Summen, verbundene Zellen und bedingte Formate
- Spalten verschieben, ausblenden und fixieren
- Drucken mit Vorschau sowie Export nach Excel und PDF, **ohne installiertes Office** (C6)

`TPPGGrid` kann heute Sortieren, Filterzeile, Spalten-Editoren, TSV/CSV und 1 000 000 Zeilen virtuell. Die Unit hat aber schon 3 500 Zeilen. Deshalb beginnt die Phase mit einem Umbau.

## Teilschritte

| Teil | Inhalt | Größe |
|---|---|---|
| 13a | Umbau in Schichten ohne neue Funktion (alle 6c-/9c-Tests und Benchmarks müssen unverändert grün bleiben) | groß |
| 13b | Spalten: verschieben, ausblenden, Spaltenauswahl, Breite per Doppelklick, rechts fixieren, mehrzeilige Köpfe (Bänder), Kopfmenü | mittel |
| 13c | Ansicht: Gruppieren (auch mehrstufig), Gruppenkopf mit Zusammenfassung, Summenzeile (Summe, Mittel, Min, Max, Anzahl) | groß |
| 13d | Zellen: verbundene Zellen, bedingte Formate, Zellarten (Fortschritt, Sparkline, Bewertung, Bild, Link, Button, Kästchen, Farbe) | groß |
| 13e | Drucken: `TPPGGridPrinter`, Seiteneinrichtung, Vorschau-Dialog | groß |
| 13f | Export: xlsx (eigener Writer, ohne Excel), PDF (über den Windows-PDF-Drucker), HTML; xlsx-Import | groß |
| 13g | DB-Grid: Summenzeile aus der Datenmenge, Spalten verschieben/ausblenden, Drucken und Export über dieselben Schichten | mittel |

## 13a – Umbau in Schichten

| Unit (neu) | Verantwortung | heute in |
|---|---|---|
| `PPG.Grid.Columns` | `TPPGGridColumn`/`Columns`, Bänder, Sichtbarkeit, Reihenfolge (Anzeigeindex ↔ Datenindex) | `PPG.Grid` |
| `PPG.Grid.View` | Ansicht als Kette: Filter → Sortieren → Gruppieren → sichtbare Zeilen. Jede Stufe ist ein eigenes Objekt hinter `IPPGGridViewStage` (Strategy, OCP). Liefert „sichtbare Zeile → Datenzeile oder Gruppenkopf“ | `PPG.Grid` (Index-Array) |
| `PPG.Grid.Paint` | `TPPGCellPainter`: Hintergrund, Text, Zellart, Auswahl, Fokus; nutzt `IPPGGridCellRenderer` (neu, ISP) | `PPG.Grid` |
| `PPG.Grid.Edit` | Zell-Editoren über `IPPGFieldValue` (Phase 12); neue Editoren registrierbar statt `case EditorKind` | `PPG.Grid` |
| `PPG.Grid.Data` | `IPPGTableSource`: Zeilen, Spalten, Text, Wert (Variant), Format. Umgesetzt vom Grid, DB-Grid und virtuellen Quellen | – |
| `PPG.Grid` | nur noch Control: Eingabe, Scrollen, Layout, Verknüpfung der Schichten | – |

**Regeln:**
- Druck und Export (13e/13f) sehen nur `IPPGTableSource` und `TPPGCellPainter`, nie das Control (DIP). Dadurch drucken Grid, DB-Grid und Anwender-Datenquellen gleich.
- Öffentliche Schnittstelle von `TPPGGrid` und `TPPGDBGrid` bleibt gleich: DFM und Hooks aus Phase 9 (`CreateColumns`, `ColumnOf`, `RowScrollY` …).
- Messlatte: die vorhandenen Benchmarks (Grid 1 000 000 × 20: 300 × scrollen ≤ 3000 ms) dürfen nicht langsamer werden.

## 13b – Spalten
- **Verschieben** per Ziehen am Kopf mit Einfügemarke (`DrawDropIndicator`); `OnColumnMoved`; `Columns[i].Index` bleibt der Datenindex, `DisplayIndex` ist neu (wie .NET; hält DFMs stabil).
- **Ausblenden:** `Visible` pro Spalte; Spaltenauswahl im Kopfmenü (`TPPGPopupMenu` aus Phase 11) mit Kästchen.
- **Breite automatisch** per Doppelklick auf die Kante. Gemessen wird bei mehr als 1 000 Zeilen nur eine Stichprobe (Lehre aus Phase 10: nie alle Zeilen messen).
- **Fixieren rechts** (`FixedColsRight`), z. B. für eine Aktionsspalte.
- **Bänder:** Kopf über mehreren Spalten (`Bands`), auch mehrere Ebenen.
- **Kopfmenü:** Sortieren auf-/absteigend, Gruppieren nach dieser Spalte, Spalte ausblenden, Spaltenauswahl, Breite anpassen. Abschaltbar und erweiterbar über `OnHeaderMenu`.
- **Zustand speichern/laden** (`SaveLayout`/`LoadLayout` als JSON- oder INI-Text): Reihenfolge, Breiten, Sichtbarkeit, Sortierung, Gruppierung. Anwender erwarten, dass das Grid sich „merkt“, wie sie es eingerichtet haben.

## 13c – Gruppieren und Summen
- **Gruppieren:**
  - `GroupBy` (Liste von Spalten) bzw. Ziehen eines Kopfes in die Gruppenleiste über dem Grid (`ShowGroupPanel`).
  - Gruppenkopf-Zeilen mit Pfeil (`DrawExpander`), Text mit Markup über `OnGetGroupText`.
  - Anzahl und optionale Zusammenfassungen; Auf- und Zuklappen einzeln oder alle.
- **Summenzeile:** `Footer` mit `Aggregate` je Spalte (`agSum`, `agAvg`, `agMin`, `agMax`, `agCount`, `agCustom` über Ereignis) und `FooterFormat`. Auch pro Gruppe (`GroupFooter`).
- **Rechnen über die Ansicht:** Aggregate gelten für die gefilterten Zeilen (wie Excel-Teilergebnis). Sie werden beim Ändern der Ansicht oder der Daten neu berechnet und zwischengespeichert, nicht in Paint.
- **Leistung:** Gruppieren und Aggregieren von 1 000 000 Zeilen in höchstens 1500 ms (Benchmark); Auf- und Zuklappen nur über die Zeilen-Positionen (`TPPGRowLayout`), ohne neu zu gruppieren.

## 13d – Zellen
- **Verbundene Zellen:** `MergeCells(Col, Row, ColSpan, RowSpan)`.
  - Zeichnen ab der Ursprungszelle, auch wenn sie oberhalb des sichtbaren Bereichs liegt.
  - Auswahl und Fokus springen auf die Ursprungszelle.
  - Bei aktiver Sortierung oder Gruppierung werden Verbindungen aufgehoben (dokumentiert, wie bei TMS).
- **Bedingte Formate** (`ConditionalFormats`, Collection):
  - Regeln Wertbereich, Gleich, Enthält, Oben/Unten-N, Farbskala, Datenbalken, Symbolsatz
  - Farben aus den Tokens (Erfolg, Warnung, Fehler), damit Dark Mode stimmt (C2)
  - Für Sonderfälle zusätzlich `OnGetCellStyle`
- **Zellarten** pro Spalte (`CellKind`): Text, Kästchen, Fortschritt, Sparkline (Werte aus Text `3;5;2`, gezeichnet mit `PPGDrawSparkline`), Bewertung, Bild aus ImageList, Link (`OnLinkClick`), Button (`OnCellButtonClick`), Farbfeld, Markup.
  - Jede Zellart ist eine Klasse hinter `IPPGCellKind` (Zeichnen, Treffer, Tastatur, Screenreader-Text) und registrierbar (OCP).

## 13e – Drucken
- **`TPPGGridPrinter`** (eigene Unit `PPG.Grid.Print`, eigene Komponente für den Formular-Designer):
  - Quelle `IPPGTableSource` plus Spalten/Bänder/Formate (über ein schmales Interface vom Grid)
  - Seite: Ausrichtung, Ränder, Kopf- und Fußzeile mit Platzhaltern (`[Seite]`, `[Seiten]`, `[Datum]`, `[Titel]`)
  - Kopfzeilen auf jeder Seite wiederholen, auf Seitenbreite anpassen, Spalten auf mehrere Seiten verteilen
  - Gitterlinien und Farben ein/aus (Tinte sparen)
- **Zeichnen auf dem Drucker** über `IPPGCanvas` mit der PPI des Druckers (alle Maße sind logisch in 96 DPI: `PPGScale` funktioniert unverändert).
  - Auf dem Drucker wird der **GDI-Canvas** benutzt (kein GDI+): GDI+ auf Drucker-DCs rastert Alpha-Flächen zu großen Bitmaps.
- **Vorschau-Dialog:** eigenes Formular aus PPGlow-Controls mit Seitenleiste, Zoom, Seite einrichten, Drucken. Die Seiten werden bei Bedarf gezeichnet (Metafile je Seite, nur sichtbare).
- **Virtuelle Daten:** Zeilen werden seitenweise über `IPPGTableSource` geholt, nicht alles vorab.

## 13f – Export und Import
- **xlsx ohne Excel** (`PPG.Xlsx`, `TPPGXlsxWriter`): OpenXML über `System.Zip` (ab XE2 vorhanden, C7).
  - Shared Strings, Zahlen und Datumswerte als echte Werte (nicht als Text), Zahlenformate aus `Columns.Format`
  - fette Kopfzeile, Spaltenbreiten, fixierte Kopfzeilen (Freeze Panes), Autofilter, verbundene Zellen
  - Gruppen als Gliederung (`outlineLevel`), Summenzeile als Formel (`SUBTOTAL`)
  - Streaming-Schreiben (Zeile für Zeile in den Zip-Stream) für 1 000 000 Zeilen ohne alles im Speicher
- **xlsx-Import** (`TPPGXlsxReader`): erste Tabelle, Werte und Text, ohne Formeln/Formate. Häufiger Wunsch: „Excel-Datei ins Grid laden“.
- **PDF (Vorschlag):** über den Drucker „Microsoft Print to PDF“ (ab Windows 10 vorhanden) mit `DOCINFO.lpszOutput` = Zieldatei, also ohne Dialog. Es ist derselbe Weg wie beim Drucken: kein eigener PDF-Writer und keine Schrift-Einbettung. Fehlt der Drucker, gibt es eine klare Fehlermeldung.
  - Alternative wäre ein eigener PDF-Writer mit TrueType-Teilmengen für Unicode, das ist eine eigene große Aufgabe. → Entscheidung des Users.
- **HTML** (Tabelle mit Inline-Stilen) und das vorhandene CSV/TSV laufen über dieselbe Quelle.

## 13g – DB-Grid
- **Summenzeile:** standardmäßig über die Datenmenge (`TAggregateField` bei ClientDataSet/FDMemTable) oder ein Ereignis. Das Grid liest nie die ganze Datenmenge (Paint-Regel aus Phase 9).
- Spalten verschieben/ausblenden/Layout speichern wie 13b.
- **Drucken und Export** über eine `IPPGTableSource`-Umsetzung, die die Datenmenge mit `DisableControls` und Lesezeichen durchläuft (Muster aus `PPG.DB.Chart`), mit `MaxRecords`.
- Gruppieren im DB-Grid: **nicht** in dieser Phase (bräuchte die ganze Datenmenge im Speicher; Anwender sollen `GROUP BY` in der Abfrage nutzen). Dokumentiert.

## Fallstricke
| Bereich | Fallstrick | Gegenmittel |
|---|---|---|
| Umbau | Unbemerkte Verhaltensänderung | Umbau ohne neue Funktion als eigener Schritt, alle Tests grün vor 13b; Benchmarks vergleichen |
| View | Zeilen- und Datenindex verwechselt (heute schon: `Row` = Datenzeile, `Selection` = sichtbare Zeile) | Typen trennen: `TPPGDataRow`/`TPPGViewRow` als eigene Records statt `Integer`, Umrechnung nur über `PPG.Grid.View` |
| Gruppen | Auswahl und Fokus auf einer Gruppenkopf-Zeile | Gruppenköpfe sind nicht editierbar, Pfeil-Tasten überspringen oder klappen auf (Leertaste) |
| Merge | Scrollen in die Mitte einer verbundenen Zelle | Ursprungszelle immer mitzeichnen (Clip auf den sichtbaren Bereich) |
| Druck | Schriften auf dem Drucker zu groß/klein | Schrift über `Font.Height` mit Drucker-PPI neu setzen, nie `Font.Size` mit `PixelsPerInch` der Anzeige mischen |
| Druck | Lange Texte in schmalen Spalten | gleiche Ellipse wie auf dem Bildschirm, optional Umbruch (`WordWrap` pro Spalte) |
| xlsx | Datum als Zahl ab 1900 mit Excel-Fehler 29.02.1900 | Umrechnung mit Korrektur (Excel-Serial = `TDateTime` + 1 ab März 1900) |
| xlsx | Ungültige XML-Zeichen (Steuerzeichen) im Text | ersetzen; Attribute und Text korrekt escapen |
| xlsx | Excel verlangt `[Content_Types].xml` und Beziehungen exakt | Vorlage aus der Spezifikation, Test öffnet die Datei mit einem eigenen Leser und prüft das Schema-Minimum; zusätzlich Sichtprüfung in Excel/LibreOffice durch den User |
| PDF | „Microsoft Print to PDF“ fehlt oder heißt lokalisiert anders | Suche über den Treiber-/Portnamen (`PORTPROMPT:` bzw. Treiber „Microsoft Print To PDF“), nicht über den Anzeigenamen |
| Leistung | Bedingte Formate je Zelle und Paint | Regeln vorab je Spalte kompilieren (Typ, Schwellen), in Paint nur Vergleich |

## Anforderungen (Zuordnung zu Roadmap2)
- C1: `TStringGrid`/`TDBGrid`-DFM bleibt.
- C5: Benchmarks für Gruppieren, Export 1 Mio. Zeilen, Drucken 1000 Seiten Vorschau-Aufbau.
- C6: xlsx und PDF ohne Office.
- C7: `System.Zip` statt Fremdbibliothek.
- C9: Datums- und Zahlformate.
- C11: Druck und Export auch für DB-Grid.

## Tests (`Tests\PPG.Tests.Phase13a`–`g`)
- **13a:** alle bisherigen Grid-Tests unverändert; neue Unit-Tests der View-Kette (Filter/Sort/Group einzeln und kombiniert).
- **Spalten:** Verschieben per Maus und Code, `SaveLayout`/`LoadLayout`-Rundreise, Bänder im DFM.
- **Gruppen und Summen:** Aggregate gegen Referenzrechnung, gefilterte Teilergebnisse, Auf/Zu ohne Neuberechnung.
- **Merge:** Zeichnen bei Teil-Sichtbarkeit (Pixeltest), Fokussprung.
- **Formate:** jede Regel, Dark Mode.
- **Druck:**
  - Seitenaufteilung (Zeilen/Spalten) als reine Rechnung
  - Ausgabe in ein Metafile, Text und Seitenzahlen per `EnumEnhMetaFile` gefunden
- **xlsx:**
  - Eigenen Export mit eigenem Leser zurücklesen (Werte, Typen, Datum, Merge)
  - Schema-Minimum prüfen (Pflichtdateien und Beziehungen)
  - 1 000 000 Zeilen Speicherverbrauch unter einer Grenze
- **PDF:** nur, wenn der Drucker existiert (sonst Status statt Skip-in-Grün, Coding-Rules); Datei beginnt mit `%PDF`.
- Galerie, Streaming, Leak-Lauf, Benchmarks.

## Demo
Seite „Tabelle“ neu: Umsatzliste mit Gruppen, Summen, Formaten, Sparkline-Spalte, Kopfmenü, Drucken/Vorschau, Excel- und PDF-Export. DB-Seite: Summenzeile und Export.

## Entscheidungen für den User
1. Umbau zuerst ohne neue Funktion (empfohlen).
2. PDF über „Microsoft Print to PDF“ (empfohlen, klein) oder eigener PDF-Writer (groß, unabhängig vom Drucker).
3. Gruppieren im DB-Grid weglassen (empfohlen) oder mit vollständigem Laden der Datenmenge anbieten.

## Umsetzung (06.10.2026)

| Teil | Units | Ergebnis |
|---|---|---|
| 13a | `PPG.Grid.Columns`, `PPG.Grid.View` (Stufenkette hinter `IPPGGridViewStage`), `PPG.Grid.Data` (`IPPGTableSource`, `TPPGCellStore`), `PPG.Grid.Paint` (`TPPGCellPainter`, `IPPGGridCellRenderer`), `PPG.Grid.Edit` (Editor-Registry, `IPPGGridCellEditor`, Rückfall `IPPGFieldValue`) | Tests `PPG.Tests.Phase13a`; alle 6c-/9c-Tests unverändert grün; Grid-Benchmark unverändert |
| 13b | Spalten in der Anzeige (`DataCol`/`VisualCol`), `MoveColumn`, `Visible`, `DisplayIndex`, `AutoSizeColumn`, `FixedColsRight`, `Bands`, Kopfmenü (`CreateHeaderMenu`, `OnHeaderMenu`), `SaveLayout`/`LoadLayout` | Tests `PPG.Tests.Phase13b` |
| 13c | Gruppenstufe in `PPG.Grid.View`, `GroupBy`/`Column.GroupIndex`, Gruppenleiste, Gruppenzeilen mit Markup, `ShowFooter`/`GroupFooter`, `Column.Aggregate`/`FooterFormat`, `TPPGAggregateAcc` | Tests `PPG.Tests.Phase13c`; Benchmark 1 000 000 Zeilen gruppieren + Summen: 328 ms (Vorgabe 1500) |
| 13d | `PPG.Grid.CellKinds` (`IPPGCellKind`, 9 Zellarten, Registry), `PPG.Grid.Styles` (bedingte Formate), `MergeCells` | Tests `PPG.Tests.Phase13d` |
| 13e | `PPG.Grid.Print` (`TPPGGridPrinter`, Vorschau, Seite einrichten) | Tests `PPG.Tests.Phase13e`; Benchmark 1 000 000 Zeilen aufteilen + 3 Vorschauseiten: 15 ms |
| 13f | `PPG.Xlsx` (Writer/Reader), `PPG.Grid.Export` (xlsx, HTML, CSV, PDF, `PPGLoadXlsx`) | Tests `PPG.Tests.Phase13f` (inkl. echter PDF über „Microsoft Print to PDF“); Benchmark xlsx 1 000 000 × 5: 2,8 s |
| 13g | DB-Grid: Spalten verschieben/ausblenden/Layout, Summenzeile aus der Datenmenge, Druck/Export über Schnappschuss | Tests `PPG.Tests.Phase13g` |

**Außerdem:**
- Designer: `TPPGGridPrinter` auf der Palette PPGlow mit Symbol und den Verben „Print preview...“ und „Page setup...“.
- 37 neue Texte mit deutscher Übersetzung (Kopfmenü, Gruppen, Druck, Export).
- Demo: Seite „Tabelle“ mit Gruppenleiste, Bändern, Summenzeile und Gruppenfuß, bedingten Formaten, Zellarten Bewertung und Lager (Fortschritt), Spalten verschieben, Vorschau sowie Excel-/PDF-/HTML-Export. Seite „Datenbank“: Summenzeile aus einem `TAggregateField`, Anzahl über `OnGetFooterText`, Excel-Export der ganzen Datenmenge.

**QS:**
- 956 Tests grün (vorher 837); Leak-Lauf und Win64 siehe NAECHSTE-SCHRITTE.
- Demo-Selbsttest 102/102.
- Alle Benchmarks innerhalb der Vorgaben; Grid 1 000 000 × 20 scrollen weiter ≈ 2,2–2,3 s.

**Abweichungen vom Plan:**
- **Auf- und Zuklappen** ändert nicht die Zeilenhöhen in `TPPGRowLayout`, sondern baut nur die flache Liste der Ansicht neu auf (O(n), ohne Vergleich und ohne Neugruppieren). Zeilen mit Höhe 0 hätten Tastatur, Auswahl und UI Automation verkompliziert.
- **Gruppieren** ordnet über Hash (Schlüssel → Gruppe) und Counting Sort statt über Vergleiche; nur die Gruppen-Vertreter werden verglichen. Die Reihenfolge innerhalb einer Gruppe ist die der Sortierung.
- **Index-Typen:** statt eigener Records `TPPGDataRow`/`TPPGViewRow` gilt eine feste Regel: Methoden mit `VRow`/`VCol` arbeiten in der Anzeige, alles andere mit Daten-Indizes; umgerechnet wird nur über `DataRow`/`VisualRow` bzw. `DataCol`/`VisualCol`. UIA-Elemente tragen die Datenspalte (bleiben beim Verschieben gleich).
- **Excel-Datum:** Ab dem 01.03.1900 ist die Excel-Zahl gleich `TDateTime` (nicht „+ 1“); davor eins kleiner wegen Excels 29.02.1900.
- **xlsx-Import** liest Werte und Text, Datumswerte kommen als Zahl (Formate werden nicht ausgewertet).
- **Verbundene Zellen** ruhen außer bei Sortierung, Filter und Gruppierung auch, wenn eine Spalte der Verbindung verschoben oder ausgeblendet ist oder die Verbindung über die Grenze fester/scrollbarer Bereiche geht.
- **Bedingte Formate mit Statistik** (Oben/Unten-N, Farbskala, Datenbalken, Symbolsatz) brauchen eine feste Spalte; im DB-Grid werden sie nicht berechnet (die Statistik bräuchte die ganze Datenmenge).
- **Druck:** Gruppenzeilen und verbundene Zellen werden nicht gedruckt (die Tabelle enthält die Datenzeilen der Ansicht in Gruppenreihenfolge). Die Vorschau hat eine Seitenliste statt Miniaturbildern.
- **Gruppieren, Verschieben und Ausblenden** brauchen `Columns` (Spalten-Objekte); ein Grid nur mit `ColCount` bleibt wie bisher.
- **DB-Grid:** Boolean-Felder werden jetzt auch in eigenen `Columns` ohne `EditorKind` als Kästchen gezeigt.
