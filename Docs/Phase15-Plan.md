# Phase 15 – Detailplan: Produkt (Versionen, Installer, F1-Hilfe, Beispiele)

*Stand 05.10.2026. Teil von `Docs\Roadmap2.md`. **Vom User freigegeben am 05.10.2026 (Empfehlungen übernommen).***

## Warum
TMS ist auch ein *Produkt*: Installer für alle Delphi-Versionen, Versionsnummern, Release Notes, F1-Hilfe aus der IDE und Beispielprojekte. PPGlow lässt sich heute nur auf dem Entwicklungsrechner über `install.ps1` und nur für Delphi 13 installieren.

## Teilschritte

| Teil | Inhalt | Größe |
|---|---|---|
| 15a | Versionen: `PPG.Version`, SemVer, Changelog, Git-Tags, Versionsanzeige im Designer | klein |
| 15b | Pakete je Delphi-Version aus einer Vorlage erzeugen (`make-packages.ps1`) | mittel |
| 15c | Installer für Anwender (Erkennung der Delphi-Versionen, Bauen, Registrieren, Deinstallieren) | groß |
| 15d | F1-Hilfe in der IDE und Hilfe-Website aus den vorhandenen Seiten | mittel |
| 15e | Beispielprojekte und Einstieg („Getting Started“), mitgebaut von `build.ps1` | mittel |

## 15a – Versionen
- `PPG.Version`: Konstanten `PPGVersionMajor/Minor/Patch` und `PPGVersionText`; eine einzige Quelle, aus der Pakete (`{$DESCRIPTION}`), Installer und Hilfe lesen (DRY).
- `CHANGELOG.md` nach „Keep a Changelog“; jede Phase fügt einen Abschnitt hinzu (aus dem Umsetzungsbericht).
- Git-Tags `v1.0.0` …; `make-release.ps1` prüft, dass Tag, `PPG.Version` und Changelog zusammenpassen.
- Komponenten-Editor: Verb „Über PPGlow…“ mit Version und Link zur Hilfe.
- Regeln für den Ausbau: published Properties und Default-Werte bleiben stabil (Coding-Rules); was entfällt, bleibt per `DefineProperties` lesbar. Ein Major-Wechsel ist nur nötig, wenn DFMs brechen.

## 15b – Pakete je Delphi-Version
Heute gibt es zwei Paketsätze: `Packages\Delphi13` und `Packages\XE2` (dieser ohne `.dproj`). Neue Units müssen von Hand in alle Listen.
- **Vorlage** `Packages\Template\*.dpk.in` plus Tabelle der Versionen (BDS-Nummer, Compiler, `LIBSUFFIX`, Plattformen).
- `make-packages.ps1` erzeugt daraus `Packages\D<Version>\*.dpk/.dproj`. Die Unit-Listen kommen aus **einer** Datei (`Packages\units.txt`); Tests- und Demo-Projekte werden mit aktualisiert (DRY, ersetzt das manuelle `reg.sh` aus Phase 10).
- `LIBSUFFIX`: ab 10.4 `$(Auto)`, davor feste Nummer (z. B. `160` für XE2, `270` für 10.4 …).
- Der Regel-Prüfer (Regel PROJECT) prüft danach gegen `units.txt` statt gegen jede Liste einzeln.

## 15c – Installer für Anwender
- **Werkzeug: Inno Setup** (frei, Skript im Repository, übliche Wahl bei Delphi-Komponenten).
- **Ablauf:**
  - Installierte Delphi-Versionen aus `HKCU\Software\Embarcadero\BDS\<n>.0` erkennen (XE2 auch `HKCU\Software\Embarcadero\BDS\9.0`).
  - Auswahl der Versionen und Plattformen anbieten.
  - Pakete bauen und registrieren (`Known Packages`, Bibliothekspfade je Plattform, Suchpfade für die Quellen).
  - Hilfe registrieren (15d).
- **Bauen beim Anwender:**
  - Professional und höher haben `dcc32`/`dcc64`/`msbuild`; das ist der Normalfall.
  - Die **Community Edition hat keinen Kommandozeilen-Compiler**. Dafür gibt es denselben Weg wie heute (`bds -b` mit eigenem Profil, Lizenzhinweis-Dialog). Alternativ liefert der Installer vorkompilierte BPL/DCP/DCU für genau diese Version mit.
- **Deinstallation:** entfernt Registry-Einträge, BPLs und Pfade wieder; nichts außerhalb der eigenen Einträge.
- **Sicherheit:**
  - Vor Änderungen die Registry-Werte sichern (wie `install.ps1`).
  - Kein Kind-PowerShell mit `-EncodedCommand`/`LoadLibrary` (Norton-Lehre vom 04.10.2026, `-LoadTest`).
  - Installer und BPLs signieren, wenn ein Zertifikat vorhanden ist (sonst warnen Virenscanner eher).
- Die IDE muss geschlossen sein; der Installer prüft laufende `bds.exe` und fordert zum Schließen auf.

## 15d – F1-Hilfe
- **Website/HTML:** `make-docs.ps1` erzeugt schon HTML je Control. Dazu kommen Seiten je Property und Ereignis (aus den `///`-Kommentaren), Suche (statischer Index als JS), Startseite, Einstieg und Migration.
- **F1 in der IDE:** Ein Design-Paket registriert einen Hilfe-Betrachter über `Vcl.HelpIntfs` (`ICustomHelpViewer` + `RegisterViewer`). Bei Schlüsselwörtern `TPPG…` bzw. `TPPG….Property` öffnet er die lokale HTML-Seite im Browser.
  - Kein CHM: Der HTML Help Workshop (`hhc.exe`) ist auf den meisten Rechnern nicht vorhanden, und CHM-Dateien aus dem Netz blockiert Windows.
- **Fallstrick:** Die IDE fragt Betrachter je nach Version unterschiedlich ab, manche Versionen nur für `F1` im Editor, nicht im Objektinspektor. Prüfen je Version und in `Docs\Kompatibilitaet.md` festhalten.

## 15e – Beispiele und Einstieg
- **`Samples\`** mit kleinen, vollständigen Anwendungen:
  1. Kundenverwaltung (Formulare, DB-Controls, Dialoge, Menüs)
  2. Dashboard (KPI, Charts, Live-Daten)
  3. Explorer (TreeView, ListBox, Breadcrumb, Kontextmenüs)
  4. Planer und Kanban (ab Phase 14)
  5. Migration vorher/nachher (VCL-Formular und dasselbe Formular nach `migrate.ps1`)
- `build.ps1 -Projects Samples` baut alle Beispiele mit; ein Beispiel, das nicht baut, bricht den Build (C11).
- **`Docs\Einstieg.md`:** Installation, erstes Formular, Presets und Dark Mode, StyleManager, Übersetzung, Migration, Hilfe.

## Fallstricke
| Fallstrick | Gegenmittel |
|---|---|
| Unterschiedliche `LIBSUFFIX`-Konventionen alter und neuer Versionen | Tabelle in 15b, Test des Installers auf mindestens zwei Versionen |
| Bibliothekspfade je Plattform (Win32/Win64) und Debug/Release | Installer schreibt `Release`-Pfade in den Bibliothekspfad, `Source` in den Suchpfad für das Debuggen |
| Pakete einer alten PPGlow-Version noch geladen | Installer erkennt und entfernt alte `Known Packages`-Einträge mit gleichem Namen |
| Virenscanner (Norton auf dem Entwicklungsrechner) | keine verdächtigen Muster im Installer, signieren, Hinweis in der Doku |

## Anforderungen (Zuordnung zu Roadmap2)
C8 (alle Versionen), C11 (Doku, F1, Beispiele), C12 (saubere Installation/Deinstallation), C7 (keine Laufzeitabhängigkeiten).

## Tests
- `make-packages.ps1 -Check`: Vorlage und erzeugte Pakete stimmen überein (im Regel-Prüfer).
- Installer im Testmodus (`/DRYRUN`): schreibt geplante Registry-Änderungen in eine Datei statt in die Registry; Vergleich mit einer Erwartung.
- Hilfe: jede Palettenklasse hat eine Seite, jeder Link funktioniert (`make-docs.ps1 -CheckLinks`).
- Beispiele bauen in `build.ps1`.

## Entscheidungen für den User
1. Soll PPGlow weitergegeben bzw. verkauft werden, oder bleibt es eine eigene Suite? Davon hängen Lizenz, Signatur und vorkompilierte Pakete ab.
2. Inno Setup als Installer (empfohlen)?
3. Welche Delphi-Versionen offiziell (Vorschlag: XE2, 10.4, 11, 12, 13)?
