# PPGlow Roadmap 2: von der Komponentensuite zum TMS-Niveau (Phasen 11–16)

*Stand 05.10.2026. **Vom User freigegeben am 05.10.2026; überall gelten die Empfehlungen der Detailpläne.** Vorgänger: `Docs\Roadmap.md` (Phasen 5–10, abgeschlossen).*

## Ausgangslage
- **Vorhanden:** etwa 45 Komponenten (inkl. DB- und Diagramm-Controls), drei Presets, Dark Mode, Tokens, Animator, MSAA und UIA, DPI, Übersetzung, Designer-Editoren, 678 Tests.
- **Abstand zu TMS:**
  - Bausteine, die in **jeder** Anwendung vorkommen: Menüs, Hints, Dialoge.
  - Spezialeingaben (Maske, Zahl, Farbe, Tags).
  - **Profi-Funktionen im Grid** (Druck, Excel, Gruppieren).
  - Einige **Großkomponenten** (Planer, Ribbon, Kanban).
  - Die **Produkt-Seite**: Installer, Versionen, F1-Hilfe, Beispiele.
- **Nicht Teil dieser Roadmap** (vom User am 05.10.2026 herausgenommen): der Absicherungsblock aus XE2-/10.x-Lauf, Praxistest und Win64-Testlauf. Er bleibt in `NAECHSTE-SCHRITTE.md` offen.

## Phasen

| Phase | Inhalt | Größe | Detailplan |
|---|---|---|---|
| 11 | Menüs (Popup, Menüleiste, Kontextmenü der Felder), Hints, TeachingTip, Dialoge (TaskDialog, MessageDlg, InputQuery), Assistent | groß | `Docs\Phase11-Plan.md` |
| 12 | Eingabe-Erweiterungen: Maske, Zahl/Währung, Passwort, Datei/Ordner, Farbe, Mehrfachauswahl-Combo, mehrspaltige Combo, Tags; DB-Varianten | groß | `Docs\Phase12-Plan.md` |
| 13 | Grid-Profi: Umbau in Schichten, Spalten verschieben/ausblenden/fixieren, Gruppieren, Summen, verbundene Zellen, bedingte Formate, Zellarten, Druck mit Vorschau, Excel (xlsx) und PDF | sehr groß | `Docs\Phase13-Plan.md` |
| 14 | Großkomponenten, jede einzeln freizugeben: 14a Terminplaner, 14b Ribbon, 14c Kanban, 14d Code-Editor (nur nach Entscheidung) | sehr groß | `Docs\Phase14-Plan.md` |
| 15 | Produkt: Versionen, Paketvorlagen je Delphi-Version, Installer, F1-Hilfe, Beispielprojekte, Einstieg, Changelog | mittel | `Docs\Phase15-Plan.md` |
| 16 | Demo neu: geführte Tour durch alle Controls (`TPPGTour` als wiederverwendbare Suite-Komponente) | groß | `Docs\Phase16-Plan.md` |

**Reihenfolge (Vorschlag):** 11 → 12 → 13 → 14a → 14b → 14c → 15 → 16. Die Demo kommt bewusst zuletzt, damit die Tour alle Controls abdeckt.
- 11 ist die Grundlage: Menüs und TeachingTip werden in 12 (Kontextmenüs), 13 (Spaltenmenü, Druckvorschau), 14 und 16 (Tour) gebraucht.
- 15 vor 16, damit die Tour auf die F1-Hilfe und die Beispielprojekte verweisen kann.

## Anforderungen, die Delphi-Entwickler an eine Suite dieser Art stellen
Erfahrungswerte aus Foren, Produktvergleichen und Supportanfragen zu VCL-Suiten, keine eigene Umfrage. Jeder Detailplan ordnet seine Punkte diesen Anforderungen zu.

| Nr | Anforderung | Was das für PPGlow heißt |
|---|---|---|
| C1 | **Umstieg ohne Neuschreiben** | DFM-Kompatibilität zu den VCL-Vorbildern, `migrate.ps1` um jede neue Zuordnung erweitern, gleiche Ereignis-Semantik |
| C2 | **Dark Mode und Styles überall** | Gerade Menüs, Hints und Dialoge verraten heute „fremde“ Windows-Optik. Alles folgt Preset, Dark Mode, VCL-Style und Hochkontrast |
| C3 | **Per-Monitor-DPI** | Popups, Hints und Dialoge mit der DPI des Monitors, auf dem sie erscheinen, nicht des Formulars |
| C4 | **Vollständige Tastatur und Screenreader** | Menüs mit Mnemonics und Pfeilen, Dialoge mit Esc/Enter/Alt-Buchstaben, Narrator/NVDA-Ereignisse wie bei Windows-Controls |
| C5 | **Große Datenmengen** | Virtualisierung beibehalten, Benchmark-Vorgaben je neuer Funktion |
| C6 | **Drucken und Export ohne Office** | xlsx ohne installiertes Excel, PDF ohne Zusatzbibliothek |
| C7 | **Wenig Abhängigkeiten** | keine neuen Pakete in `requires` (siehe Entscheidung `vclimg` → GDI+), keine DLLs außer Windows |
| C8 | **Quellcode, XE2 bis 13, Win32/Win64** | Coding-Rules unverändert, jede neue Unit in den XE2-Paketen |
| C9 | **Lokalisierung inkl. RTL** | Texte über `PPGStr`, Spiegelung getestet, Datums-/Zahlformate aus `FormatSettings` |
| C10 | **Remote-Desktop/Citrix** | keine Animationen in Remote-Sitzungen (`PPGIsRemoteSession`), keine Layered-Window-Effekte ohne Rückfall |
| C11 | **Gute Doku und Beispiele** | Hilfe pro Control, F1 aus der IDE, Beispielprojekte, die mitgebaut werden |
| C12 | **Stabilität** | keine Exceptions aus Paint, Zustand vor Ereignissen setzen, Leak-Lauf grün |

## Verbindliche Architektur für alle Phasen (Ergänzung zu Roadmap 1)
Die Regeln aus `Docs\Roadmap.md` und `Docs\Coding-Rules.md` gelten weiter. Neu oder geschärft:
1. **Modell und Ansicht trennen (SRP).** Datenmodelle stehen in eigenen Units ohne Zeichencode, nach dem Muster `PPG.Chart.Series` und `PPG.Chart.Scale`:
   - Menüs: die VCL-`TMenuItem`-Struktur bleibt das Modell.
   - Grid: Spalten- und Ansichtspipeline.
   - Planer: Termine und Wiederholungsregeln.
   - Tour: Schritte.
2. **Vorhandenes Modell der VCL wiederverwenden, wo es DFM-Kompatibilität bringt.** Dazu gehören `TMenuItem`/`TPopupMenu`, `TCustomMaskEdit` und `TTaskDialog`-Properties. Ersetzt wird nur die Darstellung (OCP: erweitern statt nachbauen).
3. **Neue Optik = neues Renderer-Interface** mit Standard in `TPPGRendererBase` (ISP). Geplant sind `IPPGMenuRenderer`, `IPPGHintRenderer`, `IPPGDialogRenderer`, `IPPGGridCellRenderer` und `IPPGPlannerRenderer`.
4. **Ein Popup-Subsystem.** Menüs, Hints und TeachingTips bauen auf `TPPGPopupWindow` auf; Platzierung, Monitor, Spiegelung und Schließen gibt es nur an einer Stelle. Dafür bekommt `PPG.Popup` eine Platzierungs-Unit (`PPG.Popup.Placement`).
5. **Große Units aufteilen, bevor sie wachsen.** `PPG.Grid` (3 500 Zeilen) wird in Phase 13 zuerst in Schichten zerlegt, dann erweitert.
6. **Dateiformate und Druck als eigene Klassen** (`TPPGXlsxWriter`, `TPPGGridPrinter`), nie im Control. Das Control liefert nur eine Datenquelle (DIP: `IPPGTableSource`).
7. **Jede neue Komponente hat dieselben Tests und Zeugnisse wie bisher:**
   - DFM-Roundtrip, Streaming-Test, Galerie, Leak-Lauf, Barrierefreiheit, Benchmark wo nötig
   - **zusätzlich einen Tour-Schritt** (ab Phase 16 prüft der Selbsttest das)

## Ablauf je Phase
Wie bisher: Detailplan → Freigabe durch den User → Umsetzung am Stück oder in Teilschritten → Bericht mit Abweichungen, gefundenen Fehlern und Messwerten → OK.
