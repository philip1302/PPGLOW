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

---

## Umsetzung 14a (06.10.2026)

| Teil | Units | Ergebnis |
|---|---|---|
| Kern | `PPG.TimeZones` (Zonen aus der Registry, IANA-Namen, Umstellungstage), `PPG.Planner.Recurrence` (RRULE: DAILY/WEEKLY/MONTHLY/YEARLY, INTERVAL, COUNT, UNTIL, BYDAY mit Ordnungszahl, BYMONTHDAY, BYMONTH, BYSETPOS, WKST, `MonthEnd`), `PPG.Planner.Layout` (Spalten/Zeilen packen), `PPG.Planner.Model` (`TPPGAppointment`, `TPPGAppointments`, `IPPGAppointmentSource`), `PPG.Planner.ICal` (Import/Export) | Tests `PPG.Tests.Phase14a`: Berlin- und New-York-Umstellungstage, 16 RFC-Beispiele, Layout-Fälle, Modell in UTC, ics-Rundreise mit Faltung, TZID, DURATION, VALARM |
| Control | `PPG.Planner` (`TPPGPlanner`), Erweiterung `PPG.Calendar` (`IPPGCalendarLink`) | Tests `PPG.Tests.Phase14aPlanner` (26): Ansichten, Blättern, Überlappung, Band, Mitternacht, Treffer/RTL, Ziehen mit Raster, Veto, Kopie, Dauer, Herauslösen, Anlegen per Ziehen/Doppelklick/Tippen, Esc, Tastatur, Tab, Ressourcen, Zeitleiste, Monat „+N“, Agenda, Screenreader, Kalender, DFM, Zeichnen aller Ansichten (hell/dunkel/GDI), 50 000 Termine, Druck |
| DB | `PPG.DB.Planner` (`TPPGDBPlanner`, Paket `PPGlowDBR`) | Tests `PPG.Tests.Phase14aDB` (10) auf `TClientDataSet` |
| Druck | `PPG.Print` (gemeinsame Basis `TPPGCustomPrinter`, Vorschau, Seite einrichten – aus `PPG.Grid.Print` herausgelöst), `PPG.Planner.Print` (`TPPGPlannerPrinter`) | alle Phase-13e-Drucktests unverändert grün |

**Außerdem:** Palette (`TPPGPlanner`, `TPPGPlannerPrinter`, `TPPGDBPlanner`) mit Symbolen, Ressourcen-Editor, Feldauswahl im DB-Planer, Verben Vorschau/Seite einrichten am Planer-Drucker; 7 neue Texte (Deutsch); Hilfeseiten; Demo-Seite 15 „Planer“ (Team-Woche, Kalender, Ansichten, Druckvorschau, iCal-Export, Regel „nicht am Wochenende“ in `OnAppointmentChanging`).

**QS:** 1026 Tests grün Win32 und Win64, Leak-Lauf grün (+5680 Bytes wie vorher), Demo-Selbsttest 113/113. Benchmark: 50 000 Termine, 20 Wochen abfragen/anordnen/zeichnen 1,7 s inkl. Aufbau (Vorgabe 2,5 s); 500 Serien, 12 Monate 0,25 s.

**Abweichungen vom Plan:**
- **Raster = Wanduhr:** Am Umstellungstag hat jede Spalte 24 Felder (wie Outlook) statt „Raster aus den echten Stunden“. Ein Termin 02:00–04:00 belegt zwei Stunden, dauert aber eine. Die Umrechnung (Lücke/doppelte Stunde) ist in `PPG.TimeZones` festgelegt und getestet.
- **Vorkommen einer Serie** werden beim Ziehen, Ändern der Dauer und Löschen immer einzeln behandelt (Herauslösen bzw. Ausnahme); eine Abfrage „nur dieses / ganze Serie“ gibt es nicht. Ein geänderter Betreff gilt für die ganze Serie.
- **Ressourcen-Spalten:** Termine mit einer `ResourceId` ohne passende Ressource erscheinen bei `GroupByResource` nicht im Raster (Monat und Agenda zeigen sie).
- **Druck:** ein unsichtbarer Planer zeichnet in Druckerauflösung (gleicher Code wie am Bildschirm). Dafür ist `TPPGGdiCanvas.PushClipRoundRect` jetzt auch bei verschobenem Ursprung richtig (Clip-Regionen sind Gerätekoordinaten). Die Zeitleiste wird als Woche, die Agenda mit 7 Tagen je Seite gedruckt.
- **Zeitleiste** nutzt dasselbe `SlotMinutes` wie das Raster (Breite `SlotWidth`); die Demo schaltet für die Zeitleiste auf 60 Minuten.
- **Inline-Bearbeitung** nur für den Betreff (wie geplant); Ort und Text über `OnAppointmentOpen` im eigenen Formular.

---

## Umsetzung 14b (06./07.10.2026)

Gestartet mit „starte nächste Schritte 14b ohne Installation“.

| Teil | Units | Ergebnis |
|---|---|---|
| Kern | `PPG.Ribbon.Layout` (Gruppen-Layout: große Items als Spalte, kleine in Stapeln zu drei Zeilen, `SameRow`, `BeginColumn`; Schrumpf-Algorithmus `PPGRibbonReduce`), `PPG.KeyTips` (Vergabe und Abgleich der Plaketten) | Tests `PPG.Tests.Phase14b` (16): Größenregeln, Spalten/Stapel/Zeilen, Zentrieren, Reihenfolge, Schrumpfstufen, übersprungene Schritte, KeyTips (eigene, `&`, Wortanfänge, Zweier ohne Präfix-Konflikt, Umlaute) |
| Modell | `PPG.Ribbon.Items` (`TPPGRibbonTab`/`Group`/`Item`, Collections, `TPPGRibbonItemActionLink`, `IPPGRibbonHost`) | DFM verschachtelt, Actions wie Menü und ToolBar |
| Control | `PPG.Ribbon` (`TPPGRibbon`, Ansichten `TPPGRibbonView`, Popups für eingeklapptes Band und geschrumpfte Gruppe, Galerie-Popup, KeyTip-Overlay je Monitor) | Tests `PPG.Tests.Phase14bRibbon` (28): Höhe, Layout breit/schmal, `ReduceOrder`, eingebettetes Control, Klicks, Umschalt-Gruppen, Actions, Split-Button, Registerkarten, Einklappen mit Popup, Gruppen-Popup, Galerie (Leiste, Popup, Tastatur), Startknopf, KeyTips (drei Ebenen), Tastaturbedienung, Schnellzugriff, Kontextmenü, Kontext-Karten, Backstage, Screenreader, DFM, RTL, Sprachwechsel, Zeichnen (hell/dunkel/Classic/GDI/deaktiviert), Leistung |

**Außerdem:** Palette (`TPPGRibbon` mit Symbol), Komponenten-Editor („Edit tabs…“, „Edit groups of the active tab…“, „Edit Quick Access items…“, „New/Next/Previous Tab“, Doppelklick = Registerkarten), Klick auf Registerkarten im Designer, Units der Ereignistypen in der uses-Liste; 12 neue Texte (Deutsch); Hilfeseite; Demo-Seite 16 „Ribbon“ (kleine Textverarbeitung mit Standard-Actions, Schrift, Absatz, Formatvorlagen-Galerie, Kontext-Karte „Tabellentools“ mit Farbgalerie, Backstage, Schnellzugriff); Demo-Schalter `/ribboncapture keytips|keytips2|minimized|group|gallery datei.png`.

**QS:** 1070 Tests grün Win32 und Win64, Leak-Lauf grün (+5796 Bytes, vorher +5680), Demo-Selbsttest 130/130. Leistung: 10 Karten, 40 Gruppen mit je 10 Items, 200 × Breite ändern + auslegen + zeichnen ca. 2,4 s (12 ms je Bild).

**Abweichungen vom Plan:**
- **ComboBox als Item-Art** gibt es nicht eigens: Sie ist ein eingebettetes Control (`rikControl` mit einer `TPPGComboBox`), mit optionaler Beschriftung links. Das deckt jedes andere Control ebenso ab.
- **Zusätzlich `SameRow`:** mehrere kleine Items in einer Zeile (Fett/Kursiv/Unterstrichen wie in Office); im Plan nicht vorgesehen, für die Textverarbeitungs-Demo aber nötig.
- **Schrumpfen stufenweise über alle Gruppen** (erst alle „mittel“, dann „nur Symbol“, dann Dropdown) statt Gruppe für Gruppe bis zum Dropdown; Schritte ohne Gewinn werden übersprungen. Folge: Eine Gruppe aus kleinen Items bleibt „nur Symbol“, wenn das Dropdown breiter wäre.
- **Eingebettete Controls im Popup** (eingeklapptes Band, Gruppen-Popup) werden umgehängt und per `ShowWindow(SW_SHOWNA)` gezeigt, weil die VCL das per API gezeigte Popup für unsichtbar hält (wie der Kalender im DatePicker). Ein Klick in ein Eingabefeld im Popup kann das Popup aktivieren; die Titelleiste des Formulars wird dann kurz inaktiv.
- **Im Designer** werden Controls inaktiver Karten nicht über `Visible` verborgen (das landete in der DFM), sondern aus dem sichtbaren Bereich geschoben.
- **Tastaturbedienung** gilt für das Band selbst; in Popups gibt es KeyTips (Ebene 3) und in der offenen Galerie Pfeile/Enter/Esc, aber keinen Fokusrahmen.
- **Schnellzugriff** wird nicht selbst gespeichert; `OnQuickAccessChange` meldet Änderungen.
- **KeyTip eines Split-Buttons** öffnet sein Menü (wie Office), der Befehl selbst liegt dann im Menü.

**Offen:** Ribbon in der Titelleiste und MDI (bewusst nicht), Speichern/Laden des Schnellzugriffs als Text, Tastaturfokus in Popups, Galerie-Kategorien.

---

## Umsetzung 14c (07.10.2026)

Gestartet mit „mach 14 c“ (ohne Installation).

| Teil | Units | Ergebnis |
|---|---|---|
| Kern | `PPG.Kanban.Layout` (Stapel, erste Karte unter Y, Einfügeposition ohne die gezogene Karte, Zielindex, Initialen, Labels, WIP-Zustand, stabile Farbnummer) | Tests `PPG.Tests.Phase14c` (9) |
| Modell | `PPG.Kanban.Items` (`TPPGKanbanColumn`/`Lane`/`Card`, fortlaufende Ids, `IPPGKanbanHost`, `TPPGKanbanCardData`) | DFM-fähig |
| Control | `PPG.Kanban` (`TPPGKanban` auf `TPPGCustomScrollControl`) | Tests `PPG.Tests.Phase14cKanban` (18): Layout, Treffer, Auswahl, Ziehen in und zwischen Spalten, Veto, WIP-Sperre, Esc, Tastatur mit Ansage, Spalten-Bildlauf und Rad, virtuelle Spalte (100 000), Swimlanes, Einklappen, Screenreader, DFM, RTL, Zeichnen (hell/dunkel/Classic/GDI/deaktiviert, Ziehen, Swimlanes), 5000 Karten |
| DB | `PPG.DB.Kanban` (`TPPGDBKanban`, Paket `PPGlowDBR`) | Tests `PPG.Tests.Phase14cDB` (8) auf `TClientDataSet`: Laden sortiert, Schreiben von Spalte/Swimlane/Reihenfolge, Neuladen bei fremden Änderungen, Auswahl → Datensatz, ohne Schlüssel schreibgeschützt |

**Außerdem:** Palette (`TPPGKanban`, `TPPGDBKanban`) mit Symbolen, Komponenten-Editor „Edit columns…“, Feldauswahl im Objektinspektor (DB), Units der Ereignistypen in der uses-Liste; 7 neue Texte (Deutsch); Hilfeseiten; Demo-Seite 17 „Kanban“ (Aufgaben-Board, Swimlanes nach Person, WIP-Sperre, neue Karte).

**QS:** 1105 Tests grün Win32 und Win64, Leak-Lauf grün (Zuwachs −16 696 Bytes, also keiner), Demo-Selbsttest 141/141. Leistung: 5000 Karten, Layout + 100 × Spalte scrollen und zeichnen ca. 0,55 s.

**Abweichungen vom Plan:**
- **Karten liegen flach** in einer Collection (Spalte über `ColumnId`, Reihenfolge = Collection-Reihenfolge) statt je Spalte; so braucht die DB-Variante nur ein Sortierfeld, und Verschieben ist ein Wechsel der `ColumnId` plus `Index`.
- **Virtuelle Karten** über `Column.VirtualCount` statt einer eigenen Quelle; verschoben werden sie nur innerhalb virtueller Spalten, die Anwendung ändert ihre Daten in `OnCardMoved`.
- **Mit Swimlanes** scrollt das ganze Board (nicht jede Spalte für sich), weil die Zellen einer Zeile gleich hoch sein müssen.
- **Zusätzlich:** `WipMode = kwmBlock` (Sperre ohne eigenen Code), `Column.Key`/`Lane.Key` für Werte in der Datenbank, Swimlanes einklappbar.
- **Ansage für den Screenreader** über den Namen der fokussierten Karte (MSAA `NAMECHANGE` + `FOCUS`) statt einer UIA-Notification, die es in `PPG.UIA` noch nicht gibt.

**Offen:** Drucken des Boards, Filter nach Label/Person, Kartenvorlagen, Ziehen ganzer Spalten.
