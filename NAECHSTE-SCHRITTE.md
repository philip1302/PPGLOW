# PPGlow – Stand und nächste Schritte

## Stand (10.10.2026)
- **Zuletzt fertig: Audit-Paket 11** (Tests, Build, Demo, Doku; Umsetzung und Abweichungen in `Docs\Audit-Paket11-Plan.md`, Abschnitt Umsetzung). Tests prüfen jetzt wirklich: zentrale Fehlerprüfung im TearDown, fehlende Referenzbilder sind Fehler (`/baseline`), übersprungene Tests sind rot (`/allowskip`), keine Zeitgrenzen in Unit-Tests (Benchmark `Bench11`), Regel TESTS im Regel-Prüfer. Dabei gefunden und behoben: 3 verdeckte Fehler (Kontextmenü per Shift+F10, Splitter, DB-Controls beim Zerstören), 2 Darstellungsfehler (Wizard deaktiviert, Kanban-Fokus), fehlender Fehlertext an Auswahlgruppen (`ValidationHint`).
- **Fertig:** Phasen 1–14c (ohne 14d), 17–20, Anpassbarkeit sowie die Audit-Pakete 1–8 und 11 (Plan und Fortschritt: `Docs\Audit-Plan.md`). 84 Paletten-Controls (67 PPGlow, 17 PPGlow DB), **1818 Tests Win32/Win64, 0 übersprungen**, Demo mit 20 Seiten (Selbsttest 205 Prüfungen). Phase 14d entfällt, Phase 15 ist zurückgestellt (Arbeitgeber), Phase 16 und 21 sind offen.
- **Branch:** Arbeitszweig `claude/task-elizkl` (GitHub `philip1302/ppglow`); Pakete werden parallel in Worktrees auf eigenen Zweigen gebaut und danach dorthin gemergt. Hängt eine alte Batch-IDE (`bds.exe -rPPGlowBuild`, nur per Neustart zu beenden), scheitert `git merge` an gesperrten Artefakten; dann über `git merge-tree --write-tree` + `commit-tree` zusammenführen.
- **Installiert:** Stand 08.10.2026 (Anpassbarkeit, alle Phasen bis 14c, inkl. DB-Pakete, Win32 und Win64). **Seit dem 08.10.2026 ist nichts installiert:** Die Property-Nacharbeiten vom 08.10., die Phasen 17–20 und die Audit-Pakete 1–8 fehlen in der IDE (Prüfliste unten).
- Der ganze Verlauf (alle datierten Einträge, Phasentabelle, frühere Roadmap-Stände) steht in `Docs\Verlauf.md`.

## Regeln für die Zusammenarbeit
- Je Schritt erst ein **Detailplan**, dann umsetzen, dann **Bericht** und **OK** des Users, bevor der nächste Schritt beginnt.
- **Nie installieren** (`install.ps1` nur nach ausdrücklicher Freigabe und mit geschlossener IDE). Die IDE des Users **nie ungefragt schließen** oder beenden; ist `Demo\PPGlowDemo.exe` gesperrt, die Exe umbenennen statt den Prozess zu beenden (umbenannte Kopien nicht committen).
- Tests, Benchmark und Demo **immer mit `/hidden`** starten (eigener Windows-Desktop, keine Fenster beim User).
- **Leitlinie Testintegrität** (User, 09.10.2026): „Tests nicht verändern, nur um sie zu bestehen, sondern nur, wenn sie fachlich bzw. technisch nicht korrekt prüfen.“ Ein roter Test wird nie passend gemacht; ändert sich ein Test, steht der fachliche Grund im Commit („Test geändert: …“) und im Bericht. Details: `Docs\Coding-Rules.md`, Abschnitt Testintegrität.
- Commits nur mit ausdrücklich genannten Dateien (`git add <dateien>`), nie `-A`. Pushen und Mergen nur auf Wunsch.
- Umbenennen ohne Aliase, solange die Suite in keinem echten Projekt läuft (`Docs\Coding-Rules.md`).

## Wichtige Befehle (Kurzfassung, vollständig unter „Befehle“)
```powershell
powershell -ExecutionPolicy Bypass -File Build\build.ps1 -Only Delphi13 -Projects Runtime,Design,DBRuntime,DBDesign,Tests,Demo
Tests\PPGlowTests.exe /hidden                                 # 0 = alles grün
Demo\PPGlowDemo.exe /selftest C:\pfad\selftest.txt /hidden    # Szenarien aller Seiten
powershell -ExecutionPolicy Bypass -File Build\make-docs.ps1 -Missing C:\pfad\fehlt.txt   # Soll: 0 fehlend
```

## Nächste Wahl (mit dem User abstimmen)
- Audit-Paket 9 (Architektur) oder 10 (XE2, `Docs\Kompatibilitaet.md`) aus `Docs\Audit-Plan.md`.
- Phase 16 (Demo-Tour, Kommando-Palette, `Docs\Phase16-Plan.md`).
- Phase 21 (LayoutControl, Inspector, FilterBuilder) erst nach einer Inventur eines echten Projekts; `Build\inventory.ps1` ist noch zu bauen (`Docs\Umstellung-Kundenprojekt-Plan.md`).
- Installation und IDE-Prüfung (unten), sobald der User sie freigibt.
- Phase 15 (Produkt) bleibt zurückgestellt, bis der User Lizenz, Firmen-Delphi und Signatur mit dem Arbeitgeber geklärt hat.

## Nach der nächsten Installation prüfen
Seit der Installation am 08.10.2026 neu bzw. noch nie in der IDE geprüft. In der IDE mit einem VCL-Formular im Designer (die Palette erscheint nur dann), danach die Demo per Maus, Tastatur und Narrator:
- **Allgemein (Audit 5, 7, 8):** Kategorie „PPGlow“ im Objektinspektor (Preset, StyleManager, Appearance, Animation, Styles); umbenannte Properties (Paket 5c, `Min`/`Max`/`Value`, `Styles`, `Severity`, `Open`) im Objektinspektor und beim Speichern/Laden einer DFM; `ImageName` an Einträgen (ToolBar, NavigationView, Ribbon, StatusBar, Reiter) mit `TVirtualImageList`; Designer bleibt bei vielen Controls flüssig (Teil-Neuzeichnen).
- **Palette:** 84 Controls mit Symbol, davon neu seit 08.10.: `TPPGRadioGroup`, `TPPGCheckGroup`, `TPPGTileView`, `TPPGScrollBox`, `TPPGValidator`, `TPPGBusyOverlay` (PPGlow) sowie `TPPGDBNavigator`, `TPPGDBRadioGroup` (PPGlow DB).
- **Phase 17:** `TPPGGridPrinter` mit `UseGridLook` (auch in „Seite einrichten“), Verben Vorschau/Seite einrichten; Vorschau eines Grids mit Bändern, Gruppenzeilen, Summenzeile und verbundenen Zellen; dieselben Verben an `TPPGPlannerPrinter` und `TPPGKanbanPrinter`.
- **Phase 18:** RadioGroup/CheckGroup aus einer `TRadioGroup`-DFM laden (`Items`, `Columns`, `ItemIndex`), Segmente und Kacheln im Designer; TileView mit Items-Editor; ScrollBox mit Kindern scrollen; DB-Navigator und DB-RadioGroup mit Feldauswahl (`DataField`, `SearchField`); `migrate.ps1` an einer Kopie mit diesen VCL-Controls.
- **Phase 19:** Validator: Doppelklick öffnet den Regel-Editor, Verb „Add required rules for all fields“ an einem Formular mit DB-Feldern; BusyOverlay auf ein Panel legen.
- **Phase 20:** Planer mit Serien (Abfrage „nur dieses Vorkommen / ganze Serie“, Termin-Dialog, Umschalt+F2), Kanban-Filter und Spalten ziehen, Ribbon-Tastatur in Gruppen- und Karten-Popups, Galerie-Kategorien, TrackBar mit `SelStart`/`SelEnd` und `RangeMode`.
- **Audit 4:** DB-Controls im Designer an eine Datenmenge binden (alle mit gemeinsamer Bindung), Feldlisten im Objektinspektor, DFM speichern und laden.
- **Audit 7:** Enter in Aufklappfeldern löst den Default-Button aus, Mausrad nur mit Fokus, Strg+F4 schließt Reiter, Narrator an Feldern mit Fehler (Validierung) und an Buttons.
- **Noch nie in der IDE angesehen, obwohl installiert (Phasen 10–14c):**
  - Phase 10: Palette Sparkline, Gauge, KpiTile, Chart, DBChart mit Symbol; Serien-Editor, Bereichs-Editor des Gauge, Feldlisten `LabelField`/`XField`, `ValuesText`; Demo-Seite 13 mit Maus, Tastatur, Hochkontrast und Narrator.
  - Phase 11: Palette (7 Symbole), Menü-Designer an `TPPGPopupMenu`, Seiten-Editor des Assistenten, „Dialog testen…“ am TaskDialog; Demo-Seite 14 mit Alt/F10, Umschalt+F10, Tab im TeachingTip und Narrator.
  - Phase 12: 13 Palettensymbole (8 PPGlow, 5 PPGlow DB), Spalten-Editor der ColumnComboBox, Demo-Karte „Spezialfelder“ (Seite Formular) und DB-Seite.
  - Phase 13: `TPPGGridPrinter` (Verben Vorschau/Seite einrichten), Spalteneditor mit Visible, DisplayIndex, Band, Aggregate, GroupIndex, CellKind, Format; Demo-Seite Tabelle per Maus (Kopf ziehen, Kopfmenü, Gruppenleiste, Doppelklick auf Kopfkante) und Narrator (Gruppenzeilen).
  - Phase 14a: Palette Planner, PlannerPrinter, DBPlanner; Ressourcen-Editor, Feldauswahl am DB-Planer; Demo-Seite 15 mit Maus, Tastatur und Narrator.
  - Phase 14b: `TPPGRibbon` mit Komponenten-Editor (Edit tabs/groups/Quick Access, New/Next/Previous Tab), Klick auf Registerkarten im Designer, eine `TPPGComboBox` als `Control` eines Items, DFM speichern und laden; Demo-Seite 16 (schmaler ziehen, Doppelklick auf Karte, Schnellzugriff, Alt, Buchstaben, Esc, Pfeile, Strg+F1, Narrator).
  - Phase 14c: `TPPGKanban` und `TPPGDBKanban` auf der Palette, „Edit columns…“, Feldauswahl am DB-Board, DFM mit Karten; Demo-Seite 17 mit Maus (Ziehen, Einklappen, Rad), Tastatur (Pfeile, Strg+Pfeile) und Narrator (Ansage nach dem Verschieben).
- Nach der Installation: Norton-Verlauf prüfen (löscht bei `-LoadTest` `install.ps1` und die BPLs); die geöffnete IDE hat schon einmal Units eine UTF-8-BOM vorangestellt (Regel-Prüfer: ASCII; nur die BOM entfernen).

## Offene Punkte (ohne festen Termin)
- **Praxistest mit dem User:** im Formulardesigner arbeiten (Ziehen, Properties, DFM speichern und laden), Monitorwechsel mit unterschiedlicher DPI, Remote-Desktop, `migrate.ps1` an einem echten Projekt (Kopie!).
- **Kompatibilität:** XE2- und 10.x-Lauf nach `Docs\Kompatibilitaet.md` (bisher nie kompiliert).
- **Aus Phase 9:** Benchmark DB-Grid mit 100 000 Datensätzen; weitere Sprachen (eine Datei `Lang\PPGlow.xx.txt` + `make-lang.ps1`). DB-Controls im Streaming-Test kommen mit Audit-Paket 11b.
- **Mögliche Folgeschritte zu Phase 10:** Zoom/Pan, logarithmische Achse, Splines, Tooltip als Popup außerhalb des Controls, Feldzuordnung pro Serie im DB-Chart.
- **Aus früheren Phasen (optional):** Panel-`AutoSize`, mehrzeilige/seitliche Reiter, Reiter umsortieren, HotImageName/DisabledImageName, weitere Presets. (Erledigt: TrackBar-Auswahlbereich in Phase 20d; `TPPGFloatSpinEdit` entfällt, `TPPGNumberEdit` deckt es ab.)
- **Aus Phase 17:** Gruppenfüße im Druck/HTML, Symbolsatz-Pfeile im Druck; Excel-Export in echtem Excel ansehen (Datenbalken, Fortschritt).

## Worum es geht
Eigene VCL-Komponentensuite im Stil der TMS-GlowButtons: einheitliche Optik, gleiche Properties und Bedienlogik, **Enterprise-Qualität** (SOLID, sauberes Exception-Handling, keine Leaks, Tests). Zielversionen sind **Delphi XE2 bis Delphi 13**, Präfix `PPG` (Klassen `TPPG…`, Units `PPG.*`). Es gibt drei Presets: „Classic“ (glänzend, Office-Stil), „ModernFlat“ (flach mit Glow, Standard) und „Fluent11“ (Windows 11, Akzent aus dem System).

Ausführliche Doku: `Docs\Architektur.md` (Architektur, SOLID, Exception-Konzept, alle Stolpersteine) und `Docs\Coding-Rules.md` (verbindliche Regeln). **Vor jeder Änderung lesen.**

## Umgebung (wichtig!)
- **RAD Studio 13 Community** (`Studio\37.0`). Es gibt **keinen Kommandozeilen-Compiler** (dcc32/msbuild verweigern).
  - Gebaut wird per IDE-Batch: `bds -rPPGlowBuild -b <projekt>`. Das kapselt `Build\build.ps1` und wertet die `.err`-Datei aus.
  - Das eigene Profil `-rPPGlowBuild` ist nötig, sonst hängt die IDE: Sie verweigert das Kompilieren des installierten Packages und zeigt einen unsichtbaren Dialog.
- Nach Builds stürzt oft der Code-Insight-Prozess `DelphiLSP.exe` ab (Ereignisprotokoll, evtl. „Runtime error“-Popups). Das kommt von der IDE, nicht von PPGlow.
- **Nur Delphi 13 vorhanden.** XE2 ist vorbereitet (`Packages\XE2\*.dpk`, LIBSUFFIX `'160'`), aber **nie kompiliert**. Prüfplan: `Docs\Kompatibilitaet.md`.
- Das Projekt liegt jetzt auch in **git** (GitHub `philip1302/ppglow`). Phase 9 entstand dort im Zweig `claude/task-elizkl` in einer Cloud-Sitzung **ohne Delphi**. Geprüft wurde nur mit einem Pascal-Parser (Free Pascal `fcl-passrc`, Syntax), dem Regel-Prüfer und den Selbsttests der Skripte. `.gitattributes` setzt für die Delphi-Dateien CRLF.
- Die IDE des Users **nicht** ungefragt schließen oder beenden. Für `install.ps1` muss die IDE geschlossen sein, also den User bitten.
- Shell-Fallen:
  - Backslashes in `perl -e`/`sed` werden verschluckt, dafür `\x5C` verwenden oder das Edit-Tool nehmen.
  - Neue Dateien vom Write-Tool haben LF-Zeilenenden, RAD Studio braucht CRLF: `perl -pi -e 's/\r?\n/\r\n/'`.
  - In Markdown-Dateien nie per Perl Unicode einsetzen, das zerstört die Umlaut-Kodierung.
  - **Git-Bash wandelt `/screenshot` usw. in Pfade um.** Demo und Tests mit `/`-Schaltern nur über PowerShell starten, sonst läuft die Demo normal weiter und wirkt wie hängend.
  - **Umgekehrt: Perl-/sed-Einzeiler mit Backslashes nie über PowerShell starten.** Die Backslashes gehen verloren (`s/\r?\n/\r\n/` wurde zu `s/r?n/rn/` und hat sechs Dateien zerstört). Vor Massenersetzungen committen oder Kopien anlegen.
- Bei Compilerfehlern bleibt die Batch-IDE im Fortschrittsdialog stehen. `build.ps1` klickt dort jetzt selbst auf „OK“, damit die `.err`-Datei entsteht.
- Die Community Edition zeigt beim Kompilieren **zufällig einen Lizenzhinweis** (`TCENotificationDialog`, „Die Nutzung der Community Edition unterliegt …“), der den Batch-Build anhält. Seit 04.10.2026 bestätigt `build.ps1` diesen Hinweis **nur in der eigenen Batch-IDE** (Profil `PPGlowBuild`) mit OK. Das hat der User ausdrücklich freigegeben.
- **Während eines Batch-Builds keine Projektdateien (`.dproj`/`.dpr`) ändern.** Die Batch-IDE speichert die `.dproj` beim Beenden und überschreibt dabei neue Einträge (ist am 04.10.2026 passiert).
- `Label` ist in Delphi ein reserviertes Wort, eine Unit `PPG.Label` geht deshalb nicht. Sie heißt `PPG.Labels`.
- Die Test-EXE läuft ohne aktive Themes (`StyleServices.Enabled = False`). Der Test `ChildPaintsOnPanelBackground` meldet deshalb nur einen Status, der Eltern-Hintergrund ist per Demo-Screenshot geprüft.

## Befehle
```powershell
cd C:\AI\Claude_Arbeitsplatz\PPGlow
powershell -ExecutionPolicy Bypass -File Build\check-rules.ps1   # Coding-Rules ohne Compiler (läuft auch in build.ps1)
powershell -ExecutionPolicy Bypass -File Build\build.ps1 -Only Delphi13 -Projects Runtime,Design,DBRuntime,DBDesign,Tests,Demo
# /hidden: auf eigenem Windows-Desktop "PPGlowTest" laufen - keine Fenster auf dem Bildschirm,
#   die Maus des Users stört nicht; Ausgabe und Exit-Code kommen an. Für automatische Läufe immer nutzen.
Tests\PPGlowTests.exe /hidden               # 0 = alles grün
Tests\PPGlowTests.exe /leaks /hidden        # zwei Läufe, Exit-Code <> 0 bei Speicherlecks
Tests\PPGlowTests.exe /suite Audit8A,TGridTests /hidden   # nur diese Gruppen/Testklassen
Tests\PPGlowTests.exe /leaksuites /hidden   # Leck-Suche: Zuwachs je Testklasse ("LEAKSUITE Klasse Bytes", ab 1 KB)
# /baseline (Referenzbilder bewusst neu anlegen) und /allowskip: siehe Docs\Coding-Rules.md, Abschnitt Testintegrität
Tests\Bench\PPGlowBench.exe /hidden         # Benchmark (vorher build.ps1 -Projects Bench -Config Release)
Demo\PPGlowDemo.exe /selftest C:\pfad\selftest.txt /hidden   # Szenarien aller Demo-Seiten
# Aufnahmen (/datepopup, /toastcapture, /ribboncapture, /busycapture, /screencapture) zeigen nur Fenster
#   der Demo (keine fremden Fenster, keine Bildschirmpixel) und gehen auch mit /hidden.
# Generatoren (Ergebnis wird eingecheckt):
powershell -ExecutionPolicy Bypass -File Build\make-icons.ps1 [-Preview Docs\palette-icons.png]   # Palettensymbole (.dcr)
powershell -ExecutionPolicy Bypass -File Build\make-lang.ps1            # Lang\PPGlow.de.txt -> PPG.Lang.De.pas (-Check prüft nur)
powershell -ExecutionPolicy Bypass -File Build\make-docs.ps1            # Docs\Controls\*.md, types\*.md und html: jede Property/jedes Ereignis mit Typ, Vorgabe, Wirkung, Nutzung
#   Texte in Docs\Controls\props\*.txt (Schluessel Klasse.Name); neue Properties dort beschreiben, "-Missing datei.txt" listet Luecken (Soll: 0)
powershell -ExecutionPolicy Bypass -File Build\migrate.ps1 -Path <Projekt> -Recurse -WhatIf   # VCL/TMS -> PPGlow
# Release + Installation (nur nach Freigabe durch den User, IDE geschlossen!):
powershell -ExecutionPolicy Bypass -File Build\build.ps1 -Only Delphi13 -Projects Runtime,Design -Platform Win32 -Config Release
powershell -ExecutionPolicy Bypass -File Build\build.ps1 -Only Delphi13 -Projects Runtime,Design -Platform Win64 -Config Release
powershell -ExecutionPolicy Bypass -File Build\install.ps1     # baut selbst (Release Win32/Win64), prüft Alter, Registry und Abhängigkeiten (nur lesend); -NoBuild, -NoDB, -Uninstall; -LoadTest löst Norton aus!
# Sichtprüfung (danach PNG ansehen):
Demo\PPGlowDemo.exe /screenshot C:\pfad\x.png [/page n] [/scroll y] [/hover] [/focus] [/gdi] [/style Windows10Dark] /hidden
Demo\PPGlowDemo.exe /datepopup C:\pfad\d.png /hidden          # weitere Aufnahmen: /toastcapture, /ribboncapture modus, /busycapture modus
```
Die Demo startet auf Deutsch; Englisch ist auf der Seite „Darstellung“ umschaltbar. Die Liste aller Paletten-Controls steht in `Demo\DemoMain.pas` (`PaletteControls`, zwischen `// PALETTE-BEGIN` und `// PALETTE-END`); der Selbsttest prüft, dass jedes davon im Katalog steht.
Eine neue Unit muss in **alle** Projektlisten eingetragen werden: `Packages\Delphi13\PPGlowR.dpk` und `.dproj` (`DCCReference`), `Packages\XE2\PPGlowR.dpk`, `Tests\PPGlowTests.dpr` und `Demo\PPGlowDemo.dpr` (jeweils auch die `.dproj`) sowie `Tests\Bench\PPGlowBench.dpr`. DB-Units (`Source\DB`) gehören in `PPGlowDBR`, Design-Units in `dclPPGlow` bzw. `dclPPGlowDB`. Der Regel-Prüfer (Regel PROJECT) meldet fehlende Einträge. Neue Komponenten kommen außerdem in `Source\Design\PPG.Reg.pas` (DB: `Source\DesignDB\PPG.DB.Reg.pas`), ihr Symbol in `Build\make-icons.ps1`. Neue sichtbare Texte kommen als `resourcestring` nach `PPG.Consts`, werden über `PPGStr(@…)` gelesen und in `Lang\PPGlow.de.txt` übersetzt (Regel LANG).

## Arbeitsweise, die sich bewährt hat
- Erst bauen, dann testen, dann einen Demo-Screenshot vergrößert ansehen. Pixeltests prüfen Farbe und Rahmen.
- Jeder gefundene Fehler bekommt einen Regressionstest.
- Tests dürfen nicht still überspringen, wenn die Voraussetzung eigentlich erfüllt ist.
- Gegenprobe mit Standard-VCL-Controls, bevor ein Fehler der Suite zugeschrieben wird.
- Aussagen in der Doku nur nach echter Prüfung.

## Wichtigste gelernte Fallen (Details in Architektur.md)
- **Paint sendet keine Nachrichten.** Die VCL ruft nach jeder Nachricht `FreeMemoryContexts` auf und macht damit Bitmap-DCs ungültig.
- `TControl.WMLButtonUp` ruft Click **vor** MouseUp auf. Deshalb wird der Zustand vorher zurückgesetzt.
- `TWinControl.AdjustSize` tut ohne Handle nichts; `SetBounds` mit gleichen Werten wird verworfen. Deshalb gibt es `RequestAutoSize`.
- `TSpeedButton` castet `CM_BUTTONPRESSED` blind auf sich selbst. Deshalb nutzt PPGlow eine eigene registrierte Nachricht.
- FreeNotification im Destruktor nicht vorzeitig entfernen.
- Ohne `Vcl.Styles` gilt jede `.vsf`-Datei als ungültig.
- `OBJID_CLIENT`/`NotifyWinEvent` mit festen eigenen Typen importieren, weil die Signaturen je Delphi-Version abweichen.

## Vom User bestätigte Entscheidungen
- Mindestversion XE2. Beide Presets. Eigenes Präfix `PPG`.
- **Bewusst anders als die VCL:** `Checked` im Code setzen löst nur `OnChange` aus, nicht `OnClick`.
- Für Win32 ist DUnit statt DUnitX im Einsatz, weil DUnitX hier nur für Win64 installiert ist.
- Umbenennen ohne Aliase, bis die Suite in einem echten Projekt läuft; danach per `DefineProperties` (Coding-Rules). Die Installationen in der eigenen IDE zählen dabei nicht.
- Audit-Paket 11 (09.10.2026, alle fünf wie empfohlen): übersprungene Tests sind ohne `/allowskip` rot; Zeit-Asserts nur im Benchmark; `NAECHSTE-SCHRITTE.md` gekürzt, Historie in `Docs\Verlauf.md`; die Demo startet auf Deutsch; echte Fehler, die schärfere Tests finden, werden klein im Paket behoben, größere als Liste an den User.
- Reihenfolge bisher: Phase 1 → 2 → Lücken 1/4/6 → Phase 3 → Phase 4 (4a, 4b, 4c). Designer-Komfort kam mit Phase 9.
- Phase 4: Umfang Edit, SpinEdit, Memo, ComboBox mit **eigenem Popup**, PageControl/TabControl (vom User gewählt).
- Phase 4a (eigene Entscheidungen, vom User noch zu bestätigen): SpinEdit wirft bei `MinValue > MaxValue` **nicht** (wie `TSpinEdit`, sonst scheitert `MinValue := 10; MaxValue := 100`; seit Audit 5c heißen die Properties `Min`/`Max`). Die Buttons im Edit haben keinen eigenen Hint und kein `ImageName`. `TextHintVisibleOnFocus` steht standardmäßig auf `False`.
- Phase 4b/4c (eigene Entscheidungen, vom User noch zu bestätigen):
  - Combo-Ereignisse genau wie `TComboBox`: `OnClick`, dann `OnSelect`; nur ohne `OnSelect` kommt `OnChange`.
  - Das Mausrad ändert die geschlossene Combo nicht.
  - `ItemHeight` ist eine Mindesthöhe.
  - Strg+Tab wirkt im innersten Reiter-Control (die VCL nimmt das äußerste).
  - Pfeiltasten auf den Reitern laufen nicht um.
  - Schließen einer Seite blendet standardmäßig nur den Reiter aus (`caHide`).
  - `tpLeft`/`tpRight` werden wie oben/unten gezeichnet.
- Phase 6 (eigene Entscheidungen, vom User noch zu bestätigen):
  - `ItemHeight` ist bei ListBox/CheckListBox/TreeView eine **Mindesthöhe** (wegen `ItemHeight = 13` in alten DFMs).
  - Mehrfachauswahl: `ItemIndex := X` setzt nur den Fokus (wie `TListBox`), nicht die Auswahl.
  - `TreeView.Selected := X` löst `OnChange` aus (wie `TTreeView`, anders als die übrigen PPGlow-Controls).
  - Baum: nur der Pfeil dreht sich animiert; Lazy Loading über `HasChildren` + `OnExpanding` statt eines eigenen virtuellen Modus; `TTreeView`-Knoten aus alten DFMs werden nicht gelesen.
  - Grid: `Row`/`Cells` in Datenzeilen, `Selection` in sichtbaren Zeilen; Enter im Editor übernimmt und bleibt in der Zelle (wie `TStringGrid`), Pfeil hoch/runter im Text-Editor übernimmt und wechselt die Zeile; Zeilenhöhe nicht ziehbar; `OnSelectCell` kommt wie bei `TStringGrid` auch bei `Row`/`Col` im Code; Kopfklick-Zyklus aufsteigend → absteigend → unsortiert.
  - Combo mit `FilterMode`: Filtern ersetzt AutoComplete; ohne Treffer schließt die Liste.
- Phase 7 (eigene Entscheidungen, vom User noch zu bestätigen):
  - Code setzt Werte ohne Ereignisse (Expander, Rating, Calendar, DatePicker, TimePicker, NavigationView.Selected, InfoBar.IsOpen); nur Anwenderaktionen lösen Ereignisse aus.
  - Splitter ist ein Fenster-Control (TabStop standardmäßig aus) mit `ResizeStyle = rsUpdate` als Vorgabe; in Ruhe unsichtbar, Linie und Griff erst bei Hover/Ziehen/Fokus.
  - SearchEdit und TimePicker bauen auf der ComboBox auf. Der TimePicker löst `OnChange` erst bei der Übernahme aus (Verlassen, Enter, Liste, Pfeile), nicht bei jedem Tastendruck.
  - DatePicker: Eingabe beim kurzen Datum nur Ziffern und Datumstrenner (bei Uhrzeit, eigenem Format oder `ParseInput` frei). `Kind`, `DateMode` und `ParseInput` wirken seit dem 08.10.2026 wie bei `TDateTimePicker` (vorher nur gelesen/gespeichert). Leeres Datum nur mit `ShowCheckbox`.
  - NavigationView: Elterneinträge klappen nur auf (werden nicht gewählt); kompakt öffnet ein Klick auf einen Elterneintrag die Leiste. `pdmAuto` beobachtet den Parent über ein kleines Hilfsobjekt in dessen `WindowProc`-Kette.
  - PageControl: Sind alle Reiter ausgeblendet, bleibt die aktive Seite aktiv und die Reiterleiste verschwindet (wie `TPageControl`, nötig für die NavigationView).
  - Breadcrumb und ToolBar zeigen den Überlauf als natives Kontextmenü (Screenreader-tauglich) statt eines eigenen Popups.
  - Toasts sind PPGlow-eigene Fenster (keine Windows-Benachrichtigungen); Neuester an der Ecke, höchstens 3 sichtbar, bei Vollbild/Präsentation warten sie.
- Phase 9 (vom User am 04.10.2026 entschieden): am Stück; DB-Controls in eigenen Paketen; UIA nur Grid/TreeView/ListBox; Übersetzung per Laufzeit-Tabelle; Palettensymbole automatisch; Migrationsskript dazu; „die bessere Architektur“ durfte ich wählen.
- Phase 10 (vom User am 04.10.2026 entschieden): Diagramme ergänzen, voller Umfang inkl. DB-Chart, am Stück.
- Roadmap 2 (vom User am 05.10.2026 freigegeben, „nimm überall die Empfehlungen“): VCL-Menümodell behalten, `TPPGMenuBar` als Control, Dialoge als eigene Formulare, Hints opt-in über `TPPGHintManager`; Phase 13: PDF über „Microsoft Print to PDF“, Grid zuerst umbauen, keine Gruppierung im DB-Grid; Phase 14: Reihenfolge a→b→c, ohne Code-Editor, Planer in UTC; Phase 15: Inno Setup, Versionen XE2/10.4/11/12/13; Phase 16: `TPPGTour` als Suite-Komponente, Englisch gepflegt, Auto-Weiter. Offen: Phase 15 Frage 1 (verkaufen/verteilen).
- Phase 11 (eigene Entscheidungen, vom User noch zu bestätigen): Abweichungen in `Docs\Phase11-Plan.md` (u. a. `TApplicationEvents` statt Hook, Klick neben Menü wird verbraucht, `TPPGTaskDialog` erbt von `TCustomTaskDialog`, Aktions-Button des TeachingTip schließt nicht selbst).
- Phase 10 (eigene Entscheidungen, vom User noch zu bestätigen):
  - Kein Zoom/Pan, keine logarithmische Achse, keine Splines.
  - Tooltip im Control statt als Popup-Fenster.
  - DB-Chart: Feldzuordnung auf Diagramm-Ebene (`ValueFields`).
  - Sparkline und Gauge (ReadOnly) ohne Tabstopp; Chart und KPI-Kachel mit.
  - Code setzt Werte ohne Ereignisse; die Sparkline hat deshalb kein `OnChange`.
  - Datenübergänge nur bei gleicher Punktzahl und bis 10 000 Punkte; Export immer im Endzustand.
- Phase 9 (eigene Entscheidungen, vom User noch zu bestätigen):
  - Keine LiveBindings.
  - Symbole aus Vektorformen (ohne Schrift, ohne `brcc32`).
  - Preset-Galerie ohne Undo-Gruppe.
  - DB-Grid-Ereignisse ohne `Sender` (passend zu `TDBGrid`). Sortieren übernimmt die Anwendung in `OnTitleClick`.
  - Ungültige DB-Werte als Fehlerzustand am Feld statt Dialog.
  - UIA ist global über `PPGUiaEnabled` abschaltbar; bei fehlender `UIAutomationCore.dll` bleibt MSAA.
  - `PPGSetLanguage('en')` gilt als Original.
  - Wochentage und Monate kommen weiter aus `FormatSettings`.
- Phase 8.3–8.6 (eigene Entscheidungen, vom User noch zu bestätigen):
  - Dark Mode ist anwendungsweit; Standard bleibt Hell. Selbst gesetzte Farben gelten im Dunkeln nicht (wie beim VCL-Style); abschaltbar pro Control über `seClient`.
  - `StyleForms` färbt Formulare mit den neutralen Windows-11-Farben (auch im hellen Modus #F3F3F3 statt `clBtnFace`) und stellt beim Ausschalten die Originalfarben wieder her.
  - `TPPGStyleManager.ThemeMode` wirkt auch im Designer (alle PPGlow-Controls der IDE); `StyleForms` nur zur Laufzeit.
  - ModernFlat dunkel: Rand `Stroke` etwas kräftiger ($5C5C5C). Leere Kästchen/Kreise auf dunklen Flächen bekommen mindestens 3:1 Randkontrast (alle Presets).
  - `ekDecelerate` = Ease-out-Quart (Annäherung an Fluent `cubic-bezier(0,0,0,1)`).
  - Fluent11-Aufklapp-Pfeil mit Symbolschrift dreht sich nicht, sondern wechselt ab halber Animation.
- Phase 8.2 (eigene Entscheidungen, vom User noch zu bestätigen):
  - Fluent11-Druckzustand: dunkler Text plus kräftigerer Rand statt blasserem Text (WinUI), damit eingerastete Toggle-Buttons lesbar und erkennbar bleiben. Ein eingerasteter Toggle in Akzentfarbe (wie WinUI) bräuchte eine Änderung am Button.
  - Der Systemakzent landet wie alle Preset-Farben in der DFM (Akzent des Entwicklungsrechners). Alternative wäre ein „Akzent folgt System“-Merker in der Appearance.
  - Der gemischte Zustand der CheckBox ist ein Akzent-Strich auf heller Fläche (WinUI: weißer Strich auf Akzent).
- Phase 3 (eigene Entscheidungen, vom User noch zu bestätigen): `Position` wird wie in der VCL still geklemmt, `Min > Max` wirft. Die GroupBox-Beschriftung ist eine Plakette statt einer Lücke im Rahmen. Container bieten kein `AutoSize`.
