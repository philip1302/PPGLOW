# Phase 10 – Detailplan: Datenvisualisierung

*Stand 04.10.2026. Erweiterung der Roadmap (`Docs\Roadmap.md`). **Vom User freigegeben am 04.10.2026. Umgesetzt am 04.10.2026 (10a–10e, 678 Tests grün) – siehe „Umsetzung“ am Ende.***

**Entscheidungen des Users (04.10.2026):** voller Umfang – Sparkline, Gauge/KPI-Kachel, Chart **und** DB-Chart; Umsetzung am Stück wie Phase 7.

## Warum
PPGlow hat bisher kein Control, das Datenreihen darstellt. Die Suche nach chart/graph/sparkline/gauge in Source und Docs ergab keinen Treffer. ProgressBar, ProgressRing, Rating und TrackBar zeigen nur einen Einzelwert. TeeChart liegt RAD Studio zwar bei, folgt aber weder den Presets noch Dark Mode, Tokens oder Hochkontrast und passt deshalb optisch nicht zur Suite. TMS (das Vorbild) hat mit FNC Chart eigene Diagramme. Der User hat am 04.10.2026 den vollen Umfang gewählt: **Sparkline + Gauge/KPI + Chart + DB-Chart**.

Ausdrücklich **nicht** Ziel: ein Nachbau von TeeChart (kein 3D, keine Finanz-Charts, kein Druckmodul, kein Migrationspfad TeeChart → PPGlow).

## Vorgehen
1. `Docs\Phase10-Plan.md` aus diesem Plan anlegen (gleiche Gliederung wie `Docs\Phase7-Plan.md`), Phase 10 in `Docs\Roadmap.md` und `NAECHSTE-SCHRITTE.md` eintragen.
2. Umsetzung 10a → 10e am Stück, Bericht am Ende (wie Phase 7). Am Ende jeder Teilphase bauen und testen.

## 10a – Zeichen-Fundament (klein, Voraussetzung)
- **`IPPGShapeCanvas`** in `Source\Render\PPG.Render.Intf.pas` als eigenes Interface (Interface Segregation, `IPPGCanvas` bleibt unverändert): `FillPolygon(Points, Color, Alpha)` (Flächen, Kreissegmente) und `DrawDashedPolyline` (Hilfslinien, Zielwert). Implementiert in `PPG.Render.GdiPlus.pas` (GdipFillPolygon) und `PPG.Render.Gdi.pas` (Polygon + AlphaBlend-Puffer wie bei den vorhandenen Alpha-Füllungen). Abfrage per `Supports`.
- **Bögen:** `PPGArcPoints` aus `PPG.Feedback.pas` wiederverwenden. Für Kreis/Donut/Gauge wird daraus ein Polygon gebaut.
- **`PPG.Chart.Scale`** (Kern, ohne VCL): Achsenwerte nach dem Nice-Numbers-Verfahren (1/2/5 × 10^n), Datums-Achse (Stunde/Tag/Woche/Monat/Jahr), Formatierung über `FormatSettings`.
- **`PPG.Chart.Palette`**: 8 Serienfarben je Hell/Dunkel. Farbe 1 = Token `Accent`, Hochkontrast = Systemfarben. Test: jede Farbe ≥ 3:1 gegen `Layer` (`PPGContrastRatio` aus `PPG.Tokens`).
- **`IPPGChartRenderer`** mit Standard-Umsetzung in der Renderer-Basis: Balken, Plotfläche, Gitter, Markierungspunkt, Tooltip-Fläche. Classic darf Balken glänzend zeichnen, ohne dass ein Control sich ändert. Muster: `IPPGRangeRenderer`.

## 10b – `TPPGSparkline` (`PPG.Sparkline`)
- Arten: Linie, Fläche, Säulen, Gewinn/Verlust. `Values` (Double-Array plus `ValuesText` als DFM-Property, z. B. `"3;5;2;8"`), `AddValue` mit `MaxCount` (Lauffenster).
- Markierung von Min, Max und letztem Wert, optionale Referenzlinie, eigener oder gemeinsamer Wertebereich.
- Freie Funktion `PPGDrawSparkline(Canvas, Rect, Values, Options, Tokens)` für Grid-Zellen (`OnDrawCell` von `TPPGGrid`) und für die KPI-Kachel.
- Screenreader: Name + „Min x, Max y, letzter z“.

## 10c – `TPPGGauge` und `TPPGKpiTile` (`PPG.Gauge`)
- **Gauge:** Bogen (Start-/Sweep-Winkel, z. B. 270°) oder halbrund. Min/Max/Value, farbige Bereiche (`Ranges`-Collection, Signalfarben aus Tokens), Zielmarke, Wert-Text mit Format, weicher Wertwechsel über den Animator (`ekDecelerate`). Optional per Tastatur bedienbar (`ReadOnly` als Vorgabe), Screenreader-Rolle Fortschritt oder Schieberegler.
- **KpiTile:** Titel, Wert, Einheit, Veränderung mit Trendpfeil (grün/rot/neutral, `InvertTrend` für „weniger ist besser“) und eingebetteter Sparkline über `PPGDrawSparkline`. Klick bzw. Enter → `OnClick`. Fläche wie eine Karte (`IPPGContainerRenderer`).

## 10d – `TPPGChart` (`PPG.Chart`, `PPG.Chart.Series`)
- **Daten:** `Series`-Collection (`TPPGChartSeries`: Title, Kind, Color = clDefault → Palette, Visible, Points). Punkte mit X (Double/Datum) oder Kategorie, Y und Label. API: `Series[i].Add(Y, Label)`, `AddXY`, `Clear`, `BeginUpdate`/`EndUpdate`. Zusätzlich ein virtueller Modus über `OnGetPoint` (wie `IPPGItemSource` beim Grid).
- **Arten:** Linie (mit/ohne Punkte), Stufe, Fläche (auch gestapelt), Säule/Balken (gruppiert, gestapelt, 100 %), Kreis/Donut. Linien- und Säulenserien lassen sich mischen.
- **Achsen:** X numerisch, Kategorie oder Datum; Y links, optional zweite Y-Achse rechts. Automatische oder feste Grenzen, Titel, Gitterlinien, Wertformat, Zielwert-/Referenzlinien (`Annotations`).
- **Legende:** oben, unten, rechts oder aus. Klick blendet eine Serie aus bzw. ein (animiert).
- **Interaktion:** Tooltip über `TPPGPopupWindow` (`PPG.Popup`). Er rastet auf den nächsten X-Wert ein (Fadenkreuz, alle Serien) bzw. auf das Segment beim Kreis. Hervorhebung beim Überfahren. Tastatur: Pfeile laufen durch die Punkte, Bild auf/ab wechselt die Serie. `OnPointClick(Series, Index)`.
- **Animation:** Aufbau beim ersten Zeigen und weicher Übergang bei Datenänderung, über den gemeinsamen Animator. Bei ausgeschalteten Animationen steht das Bild sofort.
- **Leistung:** Liniendaten werden pro Pixelspalte auf Min/Max verdichtet. Ziel: 100 000 Punkte zeichnen in ≤ 50 ms (Benchmark).
- **Export:** `SaveToBitmap`, `SaveToPng`, `CopyToClipboard`. Gezeichnet wird über denselben `DoPaint`-Pfad.
- **Barrierefreiheit:** virtuelle Kind-Elemente je Serie/Punkt über `IPPGAccessibleChildren` (wie bei der ComboBox), Name „Serie, Kategorie: Wert“. Eine leere Anzeige liefert den Text `SPPGChartNoData`.
- **RTL:** Y-Achse und Legende gespiegelt, Zeitachse bleibt links → rechts (wie Excel).

## 10e – `TPPGDBChart` (`Source\DB\PPG.DB.Chart.pas`, Paket `PPGlowDBR`)
- `DataSource` und pro Serie `XField`/`LabelField`/`ValueField`. Gelesen wird mit `DisableControls` + Lesezeichen, `MaxRecords` (Vorgabe 10 000).
- Neu geladen wird nach Datensatz-Änderungen verzögert über den Animator, nicht in Paint (Fallstrick aus `PPG.DB.Controls.pas`: Ereignisse während des Zeichnens).
- Optional „aktueller Datensatz“ hervorheben; Klick auf einen Punkt springt zum Datensatz.
- Hilfen `PPGDBSetDataSource` wiederverwenden; Registrierung in `Source\DesignDB\PPG.DB.Reg.pas`.

## Querschnitt (für jede neue Unit, siehe `NAECHSTE-SCHRITTE.md` Zeile 68)
- Eintragen in `PPGlowR.dpk/.dproj` (Delphi13 + XE2), `Tests\PPGlowTests.dpr/.dproj`, `Demo\PPGlowDemo.dpr/.dproj`, `Tests\Bench\PPGlowBench.dpr`. DB-Unit nur in `PPGlowDBR`.
- `Source\Design\PPG.Reg.pas` (Palette „PPGlow Charts“ oder bestehende Seite), Series-Collection-Editor (`TPPGCollectionEditor`), Symbole in `Build\make-icons.ps1`.
- Texte als `resourcestring` in `PPG.Consts`, Übersetzung in `Lang\PPGlow.de.txt`, danach `make-lang.ps1`.
- Coding-Rules: XE2-tauglich (keine Inline-Variablen), nur ASCII, CRLF (neue Dateien mit `perl -pi` über das **Bash**-Tool), Exceptions aus `PPG.Exceptions`, `PPGCheckRange`.
- Hilfeseiten über `make-docs.ps1`; Demo-Seite „Diagramme“ (Dashboard mit KPI-Kacheln, Gauge, Linien-/Säulen-/Donut-Chart, Live-Daten über den Animator); DB-Demoseite um einen DBChart erweitern.

## Bewusste Entscheidungen (Vorschlag, vom User zu bestätigen)
- Kein Zoom/Pan, keine logarithmische Achse, keine Splines in dieser Phase (mögliche Folgeschritte).
- Code setzt Werte ohne Ereignisse, nur Anwenderaktionen lösen Ereignisse aus (wie in Phase 7).
- Sparkline und Gauge ohne Fokus (`TabStop = False`); Chart und KpiTile mit Fokus.

## Verifikation
- `Build\check-rules.ps1`, danach `Build\build.ps1 -Only Delphi13 -Projects Runtime,Design,DBRuntime,DBDesign,Tests,Demo`, Runtime auch Win64.
- Neue Suiten `Tests\PPG.Tests.Phase10a`–`10e`:
  - Achsen-Algorithmus (Grenzfälle: alle Werte gleich, negativ, 0, sehr groß, Datum über Jahreswechsel)
  - Palette-Kontrast
  - Lebenszyklus, DFM-Roundtrip, ungültige Werte
  - Paint mit GDI+ und GDI, hell, dunkel und Hochkontrast
  - Tooltip/Hit-Test, Tastatur, Barrierefreiheit
  - DBChart mit `TClientDataSet`/`TFDMemTable`
- `Tests\PPG.Tests.Streaming.pas` und `Tests\PPG.Tests.Visual.pas` um die neuen Controls erweitern; Galerie-PNGs ansehen.
- `Tests\PPGlowTests.exe` (0 Fehler), `/leaks` grün.
- Benchmark: 100 000 Punkte, Live-Aktualisierung mit 60 Hz.
- Demo: `/page` der neuen Seite als `/screenshot` hell, dunkel, Fluent11 und `/gdi`, vergrößert ansehen; `/selftest` erweitern.
- Danach: IDE schließen lassen (User fragen), `install.ps1`, Palette und Collection-Editor im Formulardesigner prüfen.

## Umsetzung (04.10.2026)

| Teil | Units | Ergebnis |
|---|---|---|
| 10a | `PPG.Render.Shapes`, `IPPGShapeCanvas`/`IPPGChartRenderer` in `PPG.Render.Intf` (GDI+, GDI, Renderer-Basis, Classic), `PPG.Chart.Scale`, `PPG.Chart.Palette` | Tests `PPG.Tests.Phase10a` |
| 10b | `PPG.Sparkline` | Tests `PPG.Tests.Phase10b` |
| 10c | `PPG.Gauge` (`TPPGGauge`, `TPPGKpiTile`) | Tests `PPG.Tests.Phase10c` |
| 10d | `PPG.Chart.Series`, `PPG.Chart` | Tests `PPG.Tests.Phase10d` (inkl. Zeichnen aller Presets/Varianten, Leaks) |
| 10e | `PPG.DB.Chart` (Paket `PPGlowDBR`) | Tests `PPG.Tests.Phase10e` |

**Außerdem:**
- Designer: Palettensymbole, Serien- und Bereichs-Editor, Feldlisten für `LabelField`/`XField`.
- Hilfeseiten (`Docs\Controls\notes`), deutsche Texte, Galerie- und Streaming-Tests um die vier Controls erweitert.
- Demo: Seite 13 „Diagramme“ (KPI-Kacheln, Umsatz-Chart mit Umschalter, Gauge, Ring, Live-Daten); die Datenbank-Seite bekam ein DB-Chart; neuer Schalter `/chartpng seite key datei.png`.

**QS:**
- 678 Tests grün (vorher 591), `/leaks` grün (Zuwachs 5,7 KB), Demo-Selbsttest 79/79, Runtime und DB-Runtime auch Win64.
- Benchmark: Chart mit 100 000 Punkten 20 × zeichnen 281 ms (Vorgabe 1000 ms, Plan-Ziel ≤ 50 ms je Bild), Live 600 × anhängen + zeichnen 2485 ms (Vorgabe 3000 ms).

**Abweichungen vom Plan:**
- Tooltip als Teil des Controls statt über `TPPGPopupWindow`: Er erscheint im Export und in Screenshots, braucht keine Fensteraktivierung und ist testbar. Nachteil: Er bleibt innerhalb des Controls.
- DB-Chart: Feldzuordnung auf Diagramm-Ebene (`ValueFields`, `LabelField`, `XField`) statt pro Serie.
- Statt `Series.BeginUpdate` bündeln `Chart.BeginDataUpdate`/`EndDataUpdate` Änderungen.
- Die Sparkline hat kein `OnChange`: Sie ändert sich nur durch Code, und Code löst keine Ereignisse aus.
- Hochkontrast ist nur im Code abgedeckt (Systemfarben); einen Testschalter dafür gibt es in der Suite nicht.

**Beim Prüfen gefunden und behoben (jeweils mit Regressionstest):**
- Abschalten von `Animation` während des Aufbaus ließ die Daten auf der Nulllinie stehen (Chart, Gauge).
- Export während einer Animation zeigte ein Zwischenbild (halber Ring).
- DB-Chart blieb nach dem Anbinden bis zum Ablauf von `ReloadDelay` leer.
- DB-Chart hätte während `Edit` per `First` die Eingabe gespeichert.
- 100 000 Kategorien: über 2 000 Achsenbeschriftungen je Bild (Abstand auf 1 px gerundet); 100 000 Punkte brauchten deshalb 270 ms statt 15 ms je Bild.
- Y-Achse oft doppelt so hoch wie die Daten (0–100 für 74): Bereich wurde vor der Schrittweite gerundet.
