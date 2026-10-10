# Demo: Komponentenseiten (Showcase)

*Stand 10.10.2026. Vom User am 10.10.2026 so beauftragt: „Für jedes Control eine eigene Seite, sortiert nach Funktionen … Komponente plus Objektinspektor, alle Properties veränderbar … zwei Praxisbeispiele mit Code … jede Property erklärt mit Anwendungsbeispiel und Bedienungsanleitung in der Praxis.“ Umgesetzt ist bisher nur `TPPGButton`; die übrigen Komponenten folgen einzeln nach OK.*

## Aufbau für den Anwender

- **Navigation:** links „Komponenten“ mit 13 Funktionsgruppen (Buttons & Aktionen, Eingabe, Auswahl, Listen & Bäume, Tabelle, Datum & Planung, Navigation & Layout, Menüs & Dialoge, Rückmeldung, Diagramme, Datenbank, Druck & Export, Darstellung & Stil). Jede Gruppe klappt auf: „Übersicht“ (Karten aller Komponenten der Gruppe, fertige mit „Seite öffnen“) und je fertige Komponente eine Unterseite.
- Die **bisherigen 20 Themen-Seiten** stehen unter „Szenarien → Bisherige Demo-Seiten“, Darstellung und Ereignisse unten. Ihre Nummern für `/page` sind unverändert; sie entfallen, wenn alle Komponenten eine eigene Seite haben.
- **Komponentenseite:**
  - Kopf: Klasse, Unit, Gruppe, Einzeiler und „Wofür“ aus der Notiz.
  - Reiter **Ausprobieren**:
    - Links die Bühne: die Komponente frisch wie aus der Palette, Name `PPGButton1`.
    - Rechts der **Objektinspektor**: alle Eigenschaften nach Kategorien, Unterobjekte zum Aufklappen, Suche, Zurücksetzen je Zeile und „Alles zurücksetzen“. Geänderte Werte stehen fett.
    - Unten links die **Erklärung** der gewählten Zeile: Typ, aktueller Wert, Vorgabe, Wirkung, Werte, Beispiel und „So setzen Sie es in der Praxis ein“. Ungültige Werte zeigen die Meldung der Komponente.
    - Unten rechts **Ereignisse** (Protokoll beim Bedienen; Klick auf einen Eintrag wählt das Ereignis im Inspektor), **Code (Pascal)** (nur Abweichungen von einer neuen Komponente, Preset zuerst) und **DFM** (wie die IDE speichert).
  - Reiter **Praxis: …**: zwei kleine Alltagsbeispiele. „Code anzeigen“ blendet den Quelltext ein, der das Beispiel baut.
  - Reiter **Überblick**: die Notiz der Klasse (Wann verwenden, Unterschiede, Anpassung, Beispiel).

## Technik

| Datei | Aufgabe |
|---|---|
| `Demo\Showcase\DemoShowcase.pas` | Liste `ShowcaseEntries` (alle 84 Paletten-Komponenten: `Cls`, `Group`, `Summary`; fertig ist eine Seite, sobald eine Unit sie mit `RegisterShowcasePage` anmeldet), Gruppen, `TDemoGroupPage`, `TDemoComponentPage` (Bühne, Inspektor, Erklärung, Protokoll, Code, Beispiele, Überblick), `RegisterShowcasePage` |
| `Demo\Showcase\DemoInspector.pas` | Inspektor: Modell per TypInfo (`TDemoPropModel`, Knoten mit Pfad; dieselben Knoten wirken auf eine zweite Instanz) und Ansicht mit PPGlow-Editoren je Typ |
| `Demo\Showcase\DemoCodeGen.pas` | Pascal aus den Abweichungen zur Vorgabe-Instanz, DFM über `TWriter` + `ObjectBinaryToText` |
| `Demo\Showcase\DemoDocs.pas` | Texte aus der Ressource: Auflösung wie `make-docs.ps1` (Klassenkette, `VCL.Name`, `Name`; Wirkung und Praxis getrennt), Notiz-Abschnitte, Beispielcode zwischen `// EXAMPLE-BEGIN` und `// EXAMPLE-END` |
| `Demo\Showcase\DemoShow<Name>.pas` | Seite einer Komponente: `SubjectClass`, `BuildExamples`, eigene Selbsttests; meldet sich im `initialization` an |
| `Demo\Showcase\Ex<Komponente><Thema>.pas` | Praxisbeispiel, bewusst ohne Demo-Bausteine geschrieben (der Code wird angezeigt) |
| `Demo\Showcase\ShowcaseData.res` | erzeugt von `Build\make-showcase.ps1` (läuft in `build.ps1` vor dem Demo-Build): PROPS, NOTES, EX_<UNIT> |

- **Ereignisse** werden generisch per RTTI an kleine Adapter gehängt (je Ereignis eine Instanz, bekannte VCL-Signaturen). Unbekannte Signaturen bleiben unprotokolliert.
- **Vorgabe-Instanz:** eine zweite, unsichtbare Komponente derselben Klasse. Sie ist Grundlage für „geändert“, „zurücksetzen“ und die Code-Erzeugung. Für den Code wird sie kurz auf Preset und StyleManager des Ziels gestellt, damit Preset-Farben nicht als eigene Änderungen erscheinen.
- **Texte:** `Docs\Controls\props\*.txt` mit der neuen Zeilenart `! Praxis` bzw. dem Eintrag `Klasse.Name ! Text` (nur Praxis, Wirkung vom allgemeineren Schlüssel). Praxis-Texte des Buttons und der gemeinsamen Typen stehen in `props\90-praxis.txt`, die jeder weiteren Komponente in einer eigenen Datei `props\95-praxis-<Klasse>.txt` (keine gemeinsame Datei, damit parallel gearbeitet werden kann).
  - `make-docs.ps1` gibt sie als „Praxis:“ aus.
  - `make-docs.ps1 -Missing` meldet für Komponenten mit angemeldeter Seite jede Eigenschaft ohne Praxis-Text, auch in Unterobjekt-Typen und Collection-Einträgen.
- `docs-parser.ps1` führt jetzt auch die von der VCL selbst published Eigenschaften (`Left`, `Top`, `Width`, `Height`, `Hint`, `Cursor`, `Margins` …, `Name`, `Tag`) auf.
- **Schalter** (über PowerShell starten, Git-Bash wandelt `/`-Schalter um):

  ```
  /show TPPGButton [/tab n] [/bottomtab n] [/select Appearance.Normal.Color] [/showcode]
  ```

  Mit `/screenshot datei.png /hidden` für die Sichtprüfung.

## Neue Komponentenseite anlegen (Ablauf)

1. Texte prüfen:
   - `make-docs.ps1 -Missing` muss 0 melden.
   - Praxis-Texte als `TPPGX.Name ! …` in `props\95-praxis-TPPGX.txt` ergänzen. Für Typen, Collection-Einträge und VCL-Unterobjekte, die noch keinen Praxis-Text haben, allgemein formulieren (sie gelten für alle Controls); vorher prüfen, ob es den Schlüssel schon gibt.
   - In der Notiz `Docs\Controls\notes\TPPGX.md` die Abschnitte `## Wofür` und `## Wann verwenden` ergänzen.
2. Zwei Beispiele `Demo\Showcase\ExX<Thema>.pas` mit den EXAMPLE-Marken schreiben, einfach und ohne Demo-Bausteine.
3. Seite `Demo\Showcase\DemoShowX.pas` schreiben:
   - `SubjectClass` und `BuildExamples` (`AddExample(Titel, Unit, Beschreibung)`).
   - Bei Bedarf `SetupSubject`, `AddCandidates` und `EventOccurred`.
   - `SelfTest` mit den Szenarien der Beispiele.
   - Im `initialization`-Teil: `RegisterShowcasePage`.
4. Nichts in `DemoShowcase.pas` ändern: Die Anmeldung per `RegisterShowcasePage` macht die Seite fertig. Eigene Kategorien im Inspektor über `CategoryFor`, fachlich begründete Ausnahmen im Rundlauf über `SkipInRoundTrip`, eigene Ereignis-Signaturen in `SetupSubject` mit `LogEvent`.
5. Units in `PPGlowDemo.dpr` und `.dproj` eintragen (nicht während eines Batch-Builds); LF→CRLF.
6. Bauen und prüfen:
   - `build.ps1 -Projects Demo` erzeugt die Ressource neu.
   - Danach `/selftest` laufen lassen. Die allgemeinen Prüfungen der Komponentenseite laufen automatisch: jede Eigenschaft mit Wirkung und Praxis, jede Zeile setzen und zurücksetzen, Code und DFM, Beispielcode vorhanden.
   - Zum Schluss Screenshots ansehen.

## Inspektor: Listen und Collections

- `TStrings` (Items, Lines): Wert „(n Zeilen) erste Zeile“, Knopf „Bearbeiten …“ öffnet einen Dialog; im Code `X.Items.Text := 'a' + sLineBreak + 'b'`.
- `TCollection` (Panels, Tabs …): Knöpfe + und − (Eintrag anhängen bzw. letzten entfernen); jeder Eintrag klappt mit seinen Eigenschaften auf (`Panels[0].Text`). Im Code `X.Panels.Add;` und `X.Panels[0].Text := …`. Einträge zählen gegenüber einer neuen Komponente als geändert; der Selbsttest setzt ihre Werte, setzt sie aber nicht zurück.

## Offen bzw. bewusst so

- Nicht-visuelle Komponenten: Die Seite trägt das schon (die Bühne zeigt dann ein kleines Wirt-Szenario aus `SetupSubject`/`BuildExamples`). Ausprobiert wird das mit der ersten solchen Komponente.
- Englisch: Die Demo-Texte sind deutsch. `props.en` bzw. englische Notizen folgen erst bei Bedarf.
- Die Navigation scrollt bei 13 Gruppen per Mausrad; „Bisherige Demo-Seiten“ liegt bei kleiner Fensterhöhe unterhalb des sichtbaren Bereichs.
- Der Inspektor ist ein Demo-Baustein, keine Suite-Komponente; ein `TPPGInspector` bleibt Phase 21 vorbehalten.

## Parallele Läufe (vom User am 10.10.2026 beauftragt: alle Komponenten, je Komponente ein eigener Agent, in 4 Läufen)

**Lauf 1 (10.10.2026, fertig):** ToolBar, Ribbon, Edit, Memo, SpinEdit, NumberEdit, MaskEdit, PasswordEdit, FileEdit, SearchEdit, TagEdit, ColorPicker, CheckBox, RadioButton, ToggleSwitch, RadioGroup, CheckGroup, TrackBar, Rating, ComboBox, CheckComboBox. Dazu kam vorher der Button. Ergebnis: Demo-Selbsttest 792/792, 1818 Tests grün. Die Berichte der Agenten (gefundene Fehler in Suite, Doku und Gerüst) stehen in `Docs\Showcase-Lauf1-Berichte.md`.

**Lauf 2:** ColumnComboBox, ListBox, CheckListBox, TreeView, TileView, Grid, Calendar, DatePicker, TimePicker, Planner, Kanban, Panel, ScrollBox, GroupBox, Expander, Splitter, PageControl, TabControl, NavigationView, Breadcrumb, StatusBar.

**Lauf 3:** Wizard, MenuBar, PopupMenu, TaskDialog, HintManager, CustomHint, TeachingTip, Label, LinkLabel, Badge, ProgressBar, ProgressRing, InfoBar, NotificationCenter, BusyOverlay, Validator, Chart, Sparkline, Gauge, KpiTile.

**Lauf 4:** die 17 DB-Controls, GridPrinter, PlannerPrinter, KanbanPrinter, StyleManager. Nicht-visuelle Komponenten zeigen auf der Bühne ein kleines Szenario. Die DB-Controls brauchen eine Datenmenge (TClientDataSet wie auf der Datenbank-Seite).

**Ablauf eines Laufs** (Werkzeuge in `Build\showcase-agents`):
1. Je Komponente ein Worktree: `git worktree add ..\PPGlow-sc-<Name> -b sc/<Name>` ab dem aktuellen Stand.
2. Je Komponente ein Agent mit der Anweisung `agent-prompt.md`. Die Platzhalter `{CLS}`, `{SHORT}`, `{GROUP}`, `{WT}` und `{TOOLS}` (= `C:\AI\Claude_Arbeitsplatz\PPGlow\Build\showcase-agents`) gibt man im Auftrag an. Es laufen höchstens 20 Agenten gleichzeitig, der 21. startet, sobald einer fertig ist.
3. Builds laufen über `build-lock.ps1`, Demo-Läufe über `run-lock.ps1`. Beide arbeiten nacheinander per Mutex, sonst stören sich die Batch-IDEs und die Demos. `run-lock.ps1` nimmt die Argumente als Liste oder als Text „a,b,c“; immer `/hidden` mitgeben.
4. Die Agenten committen nur ihre Seite, Beispiele, `props\95-praxis-<Klasse>.txt` und die Notiz, nicht dpr/dproj, .res oder die erzeugte Doku.
5. Integration im Hauptbaum:
   - Zweige `sc/*` mit `git merge --no-ff --no-autostash` zusammenführen.
   - Im Ordner `Docs\Controls\props` `perl ..\..\..\Build\showcase-agents\dedupe.pl` ausführen: gemeinsame Typ-Schlüssel nach `91-praxis-typen.txt`.
   - Im Ordner `Demo` `perl ..\Build\showcase-agents\addunits.pl` ausführen: Units in dpr/dproj eintragen.
   - Danach `make-docs.ps1 -Missing` (0), Build Demo + Tests, voller `/selftest`, `PPGlowTests.exe /hidden`, Commit und Worktrees entfernen.
6. Gerüst-Fehler aus den Berichten im Hauptbaum beheben, nicht in den Agenten-Zweigen.
