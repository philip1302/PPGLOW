# Phase 14 – Detailplan: Großkomponenten

*Stand 05.10.2026. Teil von `Docs\Roadmap2.md`. **Vom User freigegeben am 05.10.2026 (Empfehlungen übernommen).** **Jeder Teil wird einzeln freigegeben und umgesetzt.** Setzt Phase 11 (Menüs, Hints, TeachingTip) und 13 (Drucken) voraus.*

## Übersicht

| Teil | Komponente | Vorbild | Größe | Empfehlung |
|---|---|---|---|---|
| 14a | `TPPGPlanner` + `TPPGDBPlanner` | TMS Planner, Outlook-Kalender | sehr groß | zuerst: TMS' Aushängeschild, oft angefragt |
| 14b | `TPPGRibbon` | TMS AdvToolBar/Office Ribbon, Windows-Ribbon | groß | danach |
| 14c | `TPPGKanban` | Trello, TMS FNC Kanban Board | mittel | danach |
| 14d | `TPPGCodeEdit` | TMS AdvMemo, SynEdit | groß | **nur nach Entscheidung** (Konflikt mit einer Architekturregel, siehe unten) |

---

## 14a – Terminplaner

**Modell (eigene Units, ohne Zeichencode, SRP):**
- **`PPG.Planner.Model`:**
  - `TPPGAppointment`: `Start`, `Finish`, `AllDay`, `Subject`, `Location`, `Body` mit Markup, `Category` (Farbe aus Tokens/Palette), `ResourceId`, `Recurrence`, `Tag`, `ReadOnly`
  - Collection plus virtuelle Quelle `IPPGAppointmentSource.GetRange(From, To)`; große Kalender laden nur den sichtbaren Zeitraum (C5)
- **`PPG.Planner.Recurrence`:** Wiederholung nach RFC 5545 (iCalendar RRULE).
  - `FREQ` = DAILY/WEEKLY/MONTHLY/YEARLY, dazu `INTERVAL`, `COUNT`, `UNTIL`, `BYDAY` (mit Ordnungszahl, z. B. 2. Dienstag), `BYMONTHDAY`, `BYMONTH`, `WKST`
  - Ausnahmen (`EXDATE`) und geänderte Einzeltermine (`RECURRENCE-ID`)
  - Aufgelöst wird nur für den angefragten Zeitraum.
- **`PPG.Planner.Layout`:** Überlappungen in Spalten packen (Gruppen sich überschneidender Termine, gierige Spaltenvergabe, Breite teilen). Ganztägige und mehrtägige Termine in einem eigenen Band.
- **`PPG.Planner.ICal`:** Import und Export von `.ics` (VEVENT mit den Feldern oben; Zeitzonen über `TZID` mit Windows-Zeitzonen).

**Ansichten (Control `TPPGPlanner`):**
- Tag, Arbeitswoche, Woche, Monat, Zeitleiste (horizontal, für Ressourcen) und Agenda (Liste).
- **Ressourcen** als Spalten (Personen, Räume).
- **Arbeitszeit** hervorgehoben, Raster 5/10/15/30/60 min, „Jetzt“-Linie (aktualisiert über den Animator, kein Timer).
- **Bedienung:**
  - Ziehen und Größe ändern mit Einrasten am Raster.
  - Ziehen zwischen Tagen und Ressourcen; Strg+Ziehen kopiert.
  - Anlegen per Ziehen auf freier Fläche oder Doppelklick (`OnCreateAppointment`, abbrechbar); Inline-Bearbeitung des Betreffs.
  - Ereignisse `OnAppointmentChanging` (abbrechbar, z. B. Konfliktprüfung) und `OnAppointmentChanged`.
- **Tastatur:** Pfeile wandern durch Zeitfelder und Termine, Enter öffnet, Entf löscht (mit `OnDeleting`), Bild auf/ab blättert den Zeitraum.
- **Screenreader:** Rolle Tabelle (Zeitfelder) mit Terminen als Kinder, Name „Betreff, Beginn–Ende, Ort“.
- **Navigation:** verbunden mit `TPPGCalendar` über `Calendar`-Property: Auswahl im Kalender ändert den Zeitraum, Termine erscheinen fett im Kalender.
- **Drucken** über den Druck-Weg aus Phase 13 (`IPPGPrintable`: Seiten Tag/Woche/Monat).
- **`TPPGDBPlanner`:** Feldzuordnung (`StartField`, `FinishField`, `SubjectField`, `RecurrenceField` als RRULE-Text …), Laden nur des sichtbaren Zeitraums über `OnGetRange` (Filter/Parameter der Abfrage), Schreiben bei Ziehen/Ändern.

**Fallstricke:**
| Fallstrick | Gegenmittel |
|---|---|
| Sommerzeit: Tage mit 23 bzw. 25 Stunden; Termin um 02:30 am Umstellungstag existiert nicht bzw. doppelt | Termine intern in UTC (Option `TimeZoneMode`), Anzeige lokal; Raster eines Tages aus den echten Stunden; Tests für die Umstellungstage in Europa/Berlin und USA |
| Wiederholung „31. jedes Monats“, „29. Februar“ | nach RFC 5545 auslassen (nicht auf den Monatsletzten verschieben); Option `MonthEndBehavior` für Anwender, die Verschieben wollen |
| Mitternacht übergreifende Termine in der Tagesansicht | auf beide Tage teilen, mit Fortsetzungsmarke |
| Erster Wochentag und Kalenderwoche | Logik aus `TPPGCalendar` wiederverwenden (ISO 8601, Locale) |
| Viele Termine (z. B. 50 000 im Jahr) | Bereichsabfrage, Layout nur für sichtbare Tage, Benchmark |
| Ziehen über den Rand | Auto-Scroll aus `TPPGCustomScrollControl` |

---

## 14b – Ribbon

**Aufbau:**
- `TPPGRibbon` (Align alTop) mit `Tabs` → `Groups` → `Items`. Items sind Button (groß/klein), Split-Button, Toggle, ComboBox, Galerie und eingebettetes Control.
- **Actions** als Quelle (`TAction`), damit Menü, ToolBar und Ribbon dieselben Befehle teilen (C1).
- Anwendungsmenü/„Datei“-Bereich (Backstage als Seiten-Control) und Schnellzugriffsleiste (über oder unter dem Ribbon, anpassbar über Kontextmenü).
- Kontext-Registerkarten (`Visible` je nach Auswahl, farbig hervorgehoben).

**Anpassen an die Breite:** Gruppen schrumpfen in einer festen Reihenfolge (`ReduceOrder`): groß → klein → nur Symbol → Gruppe als Dropdown. Das ist ein reiner Algorithmus in `PPG.Ribbon.Layout` und testbar ohne Fenster.

**KeyTips:** Alt zeigt Buchstaben-Plaketten über Registerkarten und Befehlen (zwei Ebenen), Esc geht eine Ebene zurück. Anwender von Office erwarten das (C4). Umsetzung über `PPG.AppHooks` aus Phase 11.

**Einklappen:** Doppelklick auf eine Registerkarte oder Strg+F1; eingeklappt öffnet ein Klick die Karte als Popup (`TPPGPopupWindow`).

**Fallstricke:**
| Fallstrick | Gegenmittel |
|---|---|
| Ribbon in die Titelleiste integrieren (Office-Optik) | **nicht** in dieser Phase: Nicht-Client-Zeichnen bricht mit VCL-Styles, DPI und Snap-Layouts. Ribbon liegt unter der normalen Titelleiste |
| Galerie mit vielen Einträgen | virtuell, Zeichnen über `TPPGItemPainter` |
| KeyTips über Controls in anderen Fenstern (Popups) | KeyTips zeichnet ein eigenes Overlay-Fenster je Monitor, nicht die Controls |
| MDI-Zusammenführung | nicht unterstützt (dokumentiert); TMS kann es, Bedarf ist selten |

---

## 14c – Kanban
- `TPPGKanban` mit `Columns` (Titel, Farbe, WIP-Limit mit Warnfarbe) und `Cards`: Titel, Text mit Markup, Plaketten, Fälligkeit, Avatar-Kürzel, Fortschritt, `Tag`.
- Virtuelle Karten über `OnGetCard` bei großen Spalten; Spalten scrollen einzeln.
- **Ziehen** von Karten zwischen und innerhalb von Spalten: Platzhalter, Animation der verdrängten Karten (Animator), Auto-Scroll. Ereignisse `OnCardMoving` (abbrechbar, z. B. WIP-Limit) und `OnCardMoved`.
- **Tastatur:** Pfeile zwischen Karten, Strg+Pfeile verschieben die Karte (Barrierefreiheit statt nur Maus, C4); Screenreader meldet „verschoben nach Spalte X, Position Y“.
- Spalten einklappbar, Swimlanes (Zeilen) optional.
- `TPPGDBKanban` mit `ColumnField` und `OrderField`.

**Fallstrick:** Ziehen per OLE (zwischen Anwendungen) ist nicht nötig; VCL-Drag reicht wie bei ListBox und TreeView (Roadmap 1).

---

## 14d – Code-Editor (Entscheidung nötig)
**Konflikt mit einer Architekturregel:** „Native Texteingabe wiederverwenden, nie eigene Caret-Logik“ (wegen IME, Undo, Screenreader). Ein Editor mit Syntaxfarben ist mit dem nativen Edit nicht machbar.

| Weg | Vorteil | Nachteil |
|---|---|---|
| A: RichEdit (`TRichEdit`/`RICHEDIT50W`) mit Einfärben per `EM_SETCHARFORMAT` | native Eingabe, IME, Undo, Screenreader bleiben | langsam ab einigen tausend Zeilen, Einfärben stört Undo, keine Zeilennummern/Faltung ohne Tricks |
| B: Scintilla-DLL einbetten | bewährt, schnell, Faltung, Zeilennummern, Barrierefreiheit vorhanden | externe DLL (C7), Lizenz prüfen (Scintilla-Lizenz ist frei und erlaubt Weitergabe), XE2-Anbindung selbst schreiben |
| C: eigener Editor | volle Kontrolle | sehr groß, Regelbruch, IME/Screenreader selbst bauen |
| D: weglassen | – | Lücke zu TMS (AdvMemo) bleibt |

Empfehlung: **D**, außer der User braucht ihn konkret. Dann **A** für kleine Texte (Skripte, SQL bis ca. 2 000 Zeilen) oder **B** für einen vollwertigen Editor.

---

## Gemeinsame Anforderungen (Zuordnung zu Roadmap2)
- C1: Actions im Ribbon, iCalendar im Planer.
- C2: Kategorien-, Spalten- und Kartenfarben aus Tokens.
- C4: Tastatur und Screenreader auch für Ziehen-Operationen.
- C5: Bereichsabfragen und virtuelle Karten.
- C9: Datum, Zeit und Wochenbeginn nach Gebietsschema, RTL.
- C11: DB-Varianten.

## Tests (je Teil eigene Suite)
- **Planer:**
  - Wiederholung gegen eine Tabelle von RFC-Beispielen
  - Sommerzeit-Tage, Layout-Packen (Überlappungsfälle)
  - Ziehen/Größe mit Einrasten, ics-Rundreise, DB-Bereichsladen, 50 000 Termine Benchmark
- **Ribbon:** Schrumpf-Algorithmus (reine Funktion), KeyTips-Ebenen, Actions-Zustand, DFM.
- **Kanban:** Ziehen mit Maus und Tastatur, WIP-Abbruch, virtuelle Spalten.
- Alle: Galerie, Streaming, Leak-Lauf.

## Demo
Je Teil eine Seite: Planer (Team-Woche mit Ressourcen), Ribbon (als Kopf einer kleinen Textverarbeitung), Kanban (Aufgaben).

## Entscheidungen für den User
1. Reihenfolge 14a → 14b → 14c (empfohlen)?
2. 14d: Weg A, B, C oder weglassen (empfohlen: weglassen, solange kein konkreter Bedarf)?
3. Planer: Termine intern in UTC (empfohlen) oder lokal?
