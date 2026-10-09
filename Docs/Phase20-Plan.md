# Phase 20 – Detailplan: Fertigstellen bestehender Controls

*Stand 09.10.2026. Grundlage: `Docs\Roadmap3.md`, Phase 20, und die offenen Punkte der Phasen 13/14. **Vom User am 09.10.2026 freigegeben („Ja Phase 20“, alle vier Entscheidungen wie empfohlen).***

## Context
Planer, Kanban, Ribbon, ComboBox und TrackBar sind fertig und getestet, haben aber Lücken, auf die man im Alltag stößt:
- **Planer:** Ändert man ein Vorkommen einer Serie, wird es immer herausgelöst. Outlook fragt „Nur dieses Vorkommen oder die ganze Serie?“. Es gibt keinen Termin-Dialog; jede Anwendung baut ihn selbst.
- **Kanban:** Es fehlt ein Filter („nur meine Karten“, „nur Label Fehler“), Spalten lassen sich nicht umsortieren.
- **Ribbon:** Aufgeklappte Gruppen und Galerien sind nur mit der Maus bedienbar. Galerien haben keine Kategorien.
- **TrackBar:** `SelStart`/`SelEnd` der VCL fehlen (die Migration entfernt sie heute), einen Bereich mit zwei Reglern gibt es nicht.
- **ComboBox:** eigene Aufklapp-Umsetzung statt der gemeinsamen Basis aus Phase 12 (doppelter Code, Unterschiede im Verhalten).

Regel wie in Phase 18/19: nur, was im Alltag fehlt oder Code spart, keine Nachbauten um ihrer selbst willen.

| Teil | Inhalt | Nutzen |
|---|---|---|
| 20a | Planer: Serienabfrage, Ort direkt bearbeiten, Termin-Dialog | wie Outlook; spart in jeder Anwendung den eigenen Dialog |
| 20b | Kanban: Filter, Spalten ziehen | große Boards bleiben bedienbar |
| 20c | Ribbon: Tastatur in Popups, Galerie-Kategorien | Barrierefreiheit, Ordnung in großen Galerien |
| 20d | TrackBar: Auswahlbereich und Bereichsregler | DFM-kompatibel zur VCL, Preis-/Zeitfilter ohne zweites Control |
| 20e | ComboBox auf die Aufklapp-Basis | ein Verhalten für alle Aufklappfelder, weniger Code |
| 20f | Demo, Tests, Doku, Prüfung | – |

## 20a – Planer
- **Serienabfrage:** neue Eigenschaft `SeriesEditMode` mit drei Werten:
  - `semAsk` (Vorgabe): Abfrage über `PPGTaskDialog` mit den Antworten „Nur dieses Vorkommen“, „Ganze Serie“ und „Abbrechen“
  - `semOccurrence`: das bisherige Verhalten, das Vorkommen wird herausgelöst
  - `semSeries`: ändert immer die ganze Serie

  Gilt für Verschieben, Dauer, Betreff, Löschen und den Dialog. Mit `OnSeriesEdit(Occ, Kind, var Choice)` ersetzt eine Anwendung die Abfrage durch eine eigene. Beim Verschieben der ganzen Serie wandert die Uhrzeit aller Vorkommen mit; Ausnahmen bleiben bestehen.
- **Direkt bearbeiten:** `BeginEditLocation` (Umschalt+F2) neben `BeginEditSubject`, im Raster in der zweiten Zeile des Termins.
- **Termin-Dialog `PPGEditAppointment`** (`PPG.Planner.Dialog`) für die Standardaktion:
  - Felder: Betreff, Ort, Beginn/Ende mit Datum und Uhrzeit, ganztägig, Kategorie, Ressource, Notiz
  - Serie: keine, täglich, wöchentlich mit Wochentagen, monatlich, jährlich; Ende nie, nach N Terminen oder am Datum
  - Aufgebaut aus den Controls der Suite, geprüft mit `TPPGValidator`; die Serie wird als RRULE geschrieben (Parser aus Phase 14a)
  - `OnAppointmentOpen` bleibt Vorrang: Wer es belegt, bekommt den Dialog nicht; `DefaultEditor = False` schaltet ihn ab.

## 20b – Kanban
- **Filter:**
  - `FilterText`: Titel, Text, Labels, Person; Treffer werden hervorgehoben wie in der Kachelansicht
  - `FilterLabels`/`FilterAssignee` (Mengen) und `OnFilterCard` für eigene Regeln
  - Ausgeblendete Karten zählen nicht im Spaltenkopf. Das WIP-Limit zählt sie mit, angezeigt als „3 (+2 ausgeblendet)“.
  - Ziehen geht im Filter weiter; die Position wird auf die ungefilterte Liste umgerechnet.
- **Spalten ziehen:** Kopf greifen und verschieben, mit Platzhalter und Animation wie bei Karten. Tastatur: Strg+Umschalt+Links/Rechts. Neue Ereignisse `OnColumnMoving` (abbrechbar) und `OnColumnMoved`; die DB-Variante schreibt die Reihenfolge in `ColumnOrderField`, falls gesetzt.
- `SaveLayout`/`LoadLayout` merken Reihenfolge und Filter.

## 20c – Ribbon
- **Tastatur in Popups:** Wer eine eingeklappte Gruppe oder das eingeklappte Band per Tastatur (KeyTip, Enter) öffnet, ist mit dem Fokus im Popup. Pfeile, Tab, Enter und Leertaste wirken dort, Esc führt zurück zum Auslöser. Bei Galerien bewegen die Pfeile in zwei Richtungen, Bild auf/ab blättert. Der Screenreader sieht das Popup als Menü bzw. Liste mit Position im Satz.
- **Galerie-Kategorien:** Einträge bekommen eine `Category` (bzw. `OnGetGalleryItem` liefert `Data.Group`). Das Popup zeigt Überschriften wie die Gruppen der Kachelansicht; in der eingeklappten Galerie im Band bleibt die Reihenfolge.

## 20d – TrackBar
- `SelStart`/`SelEnd` und `ShowSelRange` wie bei `TTrackBar`: ein hervorgehobener Bereich auf der Spur, DFM-kompatibel. `migrate.ps1` entfernt sie nicht mehr.
- **Bereichsregler:** Mit `RangeMode = True` gibt es zwei Regler (`Position` und `PositionEnd`), die sich nicht überholen.
  - Tastatur: Tab wechselt den Regler.
  - Screenreader: zwei Kinder mit eigenem Wert.
  - Neues Ereignis `OnRangeChange`.

## 20e – ComboBox auf die Aufklapp-Basis
- `TPPGCustomComboBox` nutzt `PPG.Controls.DropDown` (Capture, Schließen, Tastatur, Barrierefreiheit) und für die Liste die Zeilenliste aus `PPG.RowPopup` bzw. `TPPGPopupList` als `TPPGDropPopup`.
- Verhalten bleibt wie heute (Ereignisreihenfolge `OnClick` → `OnSelect`/`OnChange`, AutoComplete, Tippsuche, `FilterMode`, Bilder, `ItemsEx`). Davon erben `TPPGTimePicker` und `TPPGSearchEdit`.
- Absicherung: Alle bestehenden ComboBox-Tests müssen unverändert grün bleiben. Vorher kommen Tests dazu, die das heutige Verhalten festhalten (Reihenfolge der Ereignisse, Tastatur bei offener Liste, Esc/Enter gegenüber Default-/Cancel-Button).

## 20f – Demo, Tests, Doku, Prüfung
- **Demo:**
  - Planer-Seite: Serienabfrage und Termin-Dialog
  - Kanban-Seite: Suchfeld und Filter „Person“, Spalten ziehen
  - Ribbon: Galerie mit Kategorien
  - Seite „Auswahl & Regler“: Preisfilter mit Bereichsregler
  - Selbsttest-Szenarien und Aufnahmen
- **Tests:** je Punkt Verhalten, Tastatur, Streaming, Paint (GDI+/GDI), Screenreader, Leak; für 20e die festhaltenden Tests.
- **Doku:** Hilfe-Notizen, Property-Referenz (ohne Beschreibung: 0), `Docs\Migration.md` (TrackBar `SelStart`/`SelEnd`), Architektur, Roadmap3, `NAECHSTE-SCHRITTE.md`; Texte nach `PPG.Consts`/`Lang\PPGlow.de.txt`, neue Units in alle Projektlisten.

## Nicht in Phase 20
- **`TPPGFloatSpinEdit`:** entfällt. `TPPGNumberEdit` mit `ShowSpinButtons`, `Increment` und `Decimals` deckt das ab; `migrate.ps1` kann eine Gleitkomma-SpinEdit von TMS dorthin abbilden, wenn eine Inventur sie findet.

## Entscheidungen (mit Empfehlung)
1. **Termin-Dialog** (20a) mit in Phase 20? *Empfehlung:* ja. Er ist der größte Nutzen der Phase; ohne ihn baut jede Anwendung ihren eigenen.
2. **ComboBox-Umbau** (20e) jetzt? *Empfehlung:* ja, aber als letzter Teil und nur mit den festhaltenden Tests vorweg. Wird er riskant, wird er zurückgestellt und berichtet.
3. **Bereichsregler** (20d) zusätzlich zu `SelStart`/`SelEnd`? *Empfehlung:* ja, der Mehraufwand ist klein.
4. **Vorgabe der Serienabfrage:** *Empfehlung:* `semAsk` (wie Outlook). Wer das alte Verhalten braucht, setzt `semOccurrence`.

## Reihenfolge
20a → 20b → 20c → 20d → 20e → 20f, Bericht nach 20f. Zwischenstände in `NAECHSTE-SCHRITTE.md`.

## Umsetzung (09.10.2026)
Umgesetzt in der Reihenfolge 20a → 20f, je Teil ein Commit (20e in zwei: erst die festhaltenden Tests, dann der Umbau).

- **20a** (`PPG.Planner`, `PPG.Planner.Model`, neu `PPG.Planner.Dialog`): `SeriesEditMode` (`semAsk` Vorgabe), `OnSeriesEdit`, Abfrage als `TPPGTaskDialog` mit Befehlslinks für Verschieben, Dauer, Betreff, Ort, Löschen und Dialog. `TPPGAppointment.ShiftSeries` verschiebt Beginn, Ausnahmen und bei Tageswechsel `BYDAY`/`BYMONTHDAY`. Löschen der ganzen Serie nimmt herausgelöste Einzeltermine mit. `BeginEditLocation` (Umschalt+F2), `ackLocation`/`ackDialog`. Termin-Dialog mit Validator, `DefaultEditor`, `EditAppointment`, `PPGAppointmentDialogHook`; nicht abbildbare Regeln bleiben unverändert stehen. 17 Tests.
- **20b** (`PPG.Kanban`): `FilterText`, `FilterLabels`, `FilterAssignee`, `OnFilterCard`, `IsFiltered`, `ColumnTotalCount`/`ColumnHiddenCount`; Spalten ziehen, Strg+Umschalt+Links/Rechts, `MoveColumn`, `OnColumnMoving`/`OnColumnMoved`, Ansage; `SaveLayout` Version 2. 10 Tests.
- **20c** (`PPG.Ribbon`): Tastatur in Gruppen- und Karten-Popups (`NavView`, Esc eine Ebene zurück, Pfeil nach Mausöffnung führt hinein), Galerie-Kategorien mit Zeilen (`TPPGGalleryRow`), `PaintGalleryTile`. 7 Tests.
- **20d** (`PPG.TrackBar`): `SelStart`/`SelEnd`/`ShowSelRange`, `RangeMode` mit `PositionEnd`/`ActiveThumb`, Tab zwischen den Griffen, Screenreader-Kinder „Von“/„Bis“. 7 Tests.
- **20e** (`PPG.Popup`, `PPG.Controls.DropDown`, `PPG.ComboBox`): erst 5 festhaltende Tests gegen den alten Code (Zeichen bei offener Liste, Pos1/Ende, Tasten bei geschlossener Liste, Pfeil und Ereignisse, Maus außerhalb), dann der Umbau. `TPPGDropPopup` liegt jetzt in `PPG.Popup`, `TPPGPopupList` erbt davon; die Basis bekam `CanDropDown`, `PopupOpened`/`PopupClosed`, `RepositionPopup` und `FreePopup`. Die ComboBox verliert rund 290 Zeilen eigene Popup-, Capture-, Tastatur- und Screenreader-Logik. Alle Combo-, SearchEdit-, TimePicker- und DB-Combo-Tests blieben unverändert grün.
- **20f:**
  - Demo: Planer mit Auswahl „Serie: nachfragen / nur Vorkommen / ganze Serie“ und Termin-Dialog per Doppelklick; Kanban mit Suchfeld und Personenfilter; Ribbon-Formatvorlagen nach Kategorien, neuer Capture-Modus `/ribboncapture groupkeys`; „Auswahl & Regler“ mit empfohlenem Bereich und Preisfilter (zwei Griffe). 14 neue Selbsttest-Prüfungen, darunter der Termin-Dialog über den Haken.
  - `migrate.ps1`: Fixture mit `TTrackBar` samt `SelStart`/`SelEnd` (bleiben erhalten).
  - Benchmark: „500 Serien, 50 × ganze Serie verschieben“ 672 ms (Vorgabe 2500), „Kanban 10 000 Karten, 20 × filtern“ rund 1860 ms (Vorgabe 2000; Aufbau getrennt gemessen, Referenz). Zwei kleine Optimierungen im Textfilter (Großschreibung einmal je Änderung, Markup ohne Anhängen je Zeichen) brachten nichts Messbares: Die Zeit steckt im Neu-Anordnen und Zeichnen der Spalten, nicht im Vergleich.
  - Doku: Hilfe-Notizen (Planer, Kanban, Ribbon, ComboBox, TrackBar), Property-Referenz (ohne Beschreibung: 0), Architektur (Abschnitt Phase 20, TrackBar-Migration, Aufklapp-Basis), Migration, Roadmap3.
- **Prüfung:** 1466 Tests Win32 und Win64, Leak-Lauf Win32/Win64 grün (kein Zuwachs), Demo-Selbsttest 185/185, `migrate.ps1 -SelfTest` grün, Benchmark eingehalten, Regel-Prüfer ohne Verstöße. Aufnahmen der Seiten Planer, Kanban, Ribbon, „Auswahl & Regler“ sowie `/ribboncapture gallery` und `groupkeys` angesehen. Dabei gefunden und behoben: zu lange Seitentexte (abgeschnitten) und die Ergebniszeile, die auf „Auswahl & Regler“ in die Regler rutschte.

**Abweichungen:**
- 20b: Ausgeblendete Karten stehen als „+n“ im Spaltenkopf statt „3 (+2 ausgeblendet)“; das passt in schmale Köpfe. Spalten ziehen zeigt eine Einfügemarke statt eines animierten Platzhalters. Ein `ColumnOrderField` für die DB-Variante gibt es nicht: Die Spalten legt die Anwendung an, ihre Reihenfolge merkt `SaveLayout`.
- 20c: Keine eigene Property `Category` an den Galerie-Einträgen. Die Kategorie kommt aus „Kategorie|Text“ in `GalleryItems` oder aus `Data.Group` in `OnGetGalleryItem`, so bleibt die DFM unverändert.
- 20d: Kein eigenes `OnRangeChange`; `OnChange` meldet beide Werte (wie `Position`).
- 20e: Als Popup dient `TPPGPopupList` (nicht `TPPGRowPopup`), weil Filter, `ItemsEx` und Screenreader-Kinder dort schon fertig waren. `ReadOnly` sperrt das Aufklappen der ComboBox weiterhin nicht (bisheriges Verhalten; `TComboBox` kennt kein `ReadOnly`).

**Offen:**
- Nichts installiert.
- Kein XE2-Lauf.
- Kanban mit 10 000 Karten: rund 90 ms je Filterschritt. Reicht beim Tippen, schneller ginge es nur mit einem Layout, das nur geänderte Spalten neu anordnet.

## Verifikation
- `Build\check-rules.ps1`, `build.ps1` (alle Projekte, Win32 und Win64)
- `Tests\PPGlowTests.exe` (0 = grün) und `/leaks`, Win32 und Win64; Benchmark (Kanban mit Filter, Planer mit Serien)
- `Demo\PPGlowDemo.exe /selftest datei.txt`, Aufnahmen der neuen Zustände vergrößert ansehen
- `migrate.ps1 -SelfTest` (TrackBar `SelStart`/`SelEnd`)
