# PPGlow – Stand und nächste Schritte

*Übergabe für die nächste Claude-Sitzung. Stand: 07.10.2026. Phasen 5–13 und **Phase 14a–c (Terminplaner, Ribbon, Kanban)** sind abgeschlossen: 1105 Tests Win32 und Win64, Leak-Lauf grün (kein Zuwachs), Demo-Selbsttest 141/141. Phase 11–14c sind **noch nicht installiert**. 14d (Code-Editor) ist laut Entscheidung vom 05.10.2026 weggelassen; als Nächstes käme Phase 15 (Produkt) – vorher Bericht und OK.*

**08.10.2026: Anpassbarkeit umgesetzt** (alle Punkte aus `Docs\Anforderungen-Anpassbarkeit.md`): 1205 Tests Win32 und Win64, Leak-Lauf Win32/Win64 grün (kein Zuwachs), Demo-Selbsttest 150/150, neue Demo-Seite 18 „Anpassung“. Committet (14b06ec) und am 08.10.2026 installiert (Win32 + Win64). Danach Property-Referenz (`make-docs.ps1`, `Docs\Controls\props`, 13bf123) und bisher wirkungslose VCL-Properties umgesetzt: ListBox `Columns`/`IntegralHeight`/`ScrollWidth`/`TabWidth`, CheckListBox `Flat`/`HeaderColor`/`HeaderBackgroundColor`, TreeView `RowSelect = False`, ProgressBar `Smooth = False` (Vorgabe jetzt True), Tab-/PageControl `TabPosition` links/rechts und `ScrollOpposite`, ColorPicker `NoneColorColor`, DatePicker `Kind` (Uhrzeit, Datum+Uhrzeit), `DateMode = dmUpDown`, `ParseInput` + `OnUserInput` (Suite `TCustomVclPropTests`, 1218 Tests). Diese Änderungen sind noch nicht installiert.

**08.10.2026: Umstellung eines Kundenprojekts (VCL, TMS, DevExpress → PPGlow).** Plan und Ablauf: `Docs\Umstellung-Kundenprojekt-Plan.md`. Zuerst beim User Delphi-Version und Projektpfad erfragen.

## Worum es geht
Eigene VCL-Komponentensuite im Stil der TMS-GlowButtons: einheitliche Optik, gleiche Properties und Bedienlogik, **Enterprise-Qualität** (SOLID, sauberes Exception-Handling, keine Leaks, Tests). Zielversionen sind **Delphi XE2 bis Delphi 13**, Präfix `PPG` (Klassen `TPPG…`, Units `PPG.*`). Es gibt drei Presets: „Classic“ (glänzend, Office-Stil), „ModernFlat“ (flach mit Glow, Standard) und „Fluent11“ (Windows 11, Akzent aus dem System).

Ausführliche Doku: `Docs\Architektur.md` (Architektur, SOLID, Exception-Konzept, alle Stolpersteine) und `Docs\Coding-Rules.md` (verbindliche Regeln). **Vor jeder Änderung lesen.**

## Fertig
| Bereich | Inhalt |
|---|---|
| Kern | Appearance/StateStyle (inkl. `Checked`), Animation (ein gemeinsamer Timer), LayoutEngine, ErrorHandler, Exceptions, DPI (logische 96-DPI-Maße) |
| Rendering | `IPPGCanvas` (GDI+ mit eigenem Startup, GDI-Fallback jetzt mit Alpha per `AlphaBlend`), `IPPGRenderer` + `IPPGIndicatorRenderer` + `IPPGRangeRenderer` + `IPPGContainerRenderer` + `IPPGFieldRenderer` + `IPPGListRenderer` + `IPPGTabRenderer`, Registry, Presets Classic und ModernFlat |
| Controls | `TPPGButton` (Bild, ModalResult, Default/Cancel, Toggle-Gruppen, Split-Button, DropDownMenu, Action), `TPPGCheckBox`, `TPPGRadioButton`, `TPPGToggleSwitch`, `TPPGStyleManager` |
| Phase 3 (03.10.2026) | `TPPGProgressBar` (Marquee über den Animator, Error/Paused, Text, weiche Positionswechsel), `TPPGTrackBar` (Ziehen, Tastatur, Mausrad, Ticks, vertikal/RTL), `TPPGPanel`, `TPPGGroupBox` (Plakette auf der Rahmenlinie, Fokus-Glow). Basen: `PPG.Controls.Range`, `PPG.Controls.Container`. DFM-kompatibel zu den VCL-Pendants |
| Phase 4a (03.10.2026) | Basis `PPG.Controls.Field` (natives Edit/Memo ohne Rahmen im PPG-Rahmen, Fokuslinie, TextHint selbst gezeichnet, ValidationState, Buttons im Feld, Name für Screenreader per `IAccPropServices`). Darauf `TPPGEdit` (ShowClearButton, LeftButton/RightButton mit DropDownMenu), `TPPGMemo`, `TPPGSpinEdit` (Verhalten wie `TSpinEdit`, Wiederholung beim Halten über den Animator). DFM-kompatibel zu `TEdit`/`TMemo`/`TSpinEdit` |
| Phase 4b (03.10.2026) | `TPPGComboBox` (csDropDown mit AutoComplete, csDropDownList mit Tippsuche) mit eigenem Popup (`PPG.Popup`: Fenster ohne Aktivierung, Maus per `SetCapture` bei der Combo, oberhalb bei fehlendem Platz, Aufklapp-Animation, eigene Scrollleiste). Ereignisse wie `TComboBox` (`OnClick`, dann `OnSelect` bzw. `OnChange`). Barrierefreiheit mit virtuellen Kind-Elementen (`IPPGAccessibleChildren`) |
| Phase 4c (03.10.2026) | `TPPGTabControl`, `TPPGPageControl` + `TPPGTabSheet` (DFM-kompatibel zu `TPageControl`/`TTabSheet`), gemeinsame Basis `TPPGCustomTabs` und `TPPGTabStrip` (Überlauf mit Blätterpfeilen, gleitender Unterstrich, Schließen-Knöpfe, Strg+Tab nur im innersten Reiter-Control, Accelerator). Komponenteneditor „New Page“ usw. Die Demo ist jetzt selbst ein PageControl (`/page n`) |
| Lücken geschlossen | Barrierefreiheit (MSAA/IAccessible, jetzt inkl. Kind-Fenster über `IEnumVARIANT`), VCL-Styles (`EffectiveAppearance`, `StyleElements`), AutoSize, Split-Button, `ImageName` (ab 10.4), GDI-Text im GDI+-Canvas beachtet jetzt den Clip |
| Phase 5 (03.10.2026) | Fundament für Daten-Controls (ohne neue Paletten-Controls): `TPPGCustomScrollControl` (Overlay-Scrollleisten, weiches Scrollen, Rad mit Rest, Auto-Scroll), `TPPGRowLayout` (1M Zeilen), `TPPGSelection` (Windows-Listen-Semantik), `IPPGItemSource` (Collection/TStrings/virtuell), Mini-Markup `PPG.Markup`, Mehrfachauswahl für Screenreader. Benchmark `Tests\Bench`. Dabei: schneller Eltern-Hintergrund für Kinder auf PPGlow-Containern (14× schneller beim Zeichnen vieler Kinder). Details: `Docs\Phase5-Plan.md`, `Docs\Architektur.md` |
| Phase 6 (04.10.2026) | Daten-Controls: `TPPGListBox` (Items/ItemsEx/virtuell, Gruppen, Detail, Plakette, Markup, Umsortieren, Owner-Draw; DFM wie `TListBox`), `TPPGCheckListBox` (wie `TCheckListBox`, Überschriften), ComboBox mit `ItemsEx`, Bildern und `FilterMode`, `TPPGTreeView` (API wie `TTreeView`, Lazy Loading, Kästchen mit Weitergabe, Umbenennen, Knoten ziehen), `TPPGGrid` (wie `TStringGrid`, Spalten-Editoren, Sortieren, Filterzeile, TSV/CSV, virtuell 1M Zeilen). Gemeinsam: `TPPGItemPainter`, `IPPGItemRenderer`, `TPPGCustomItemList`. Details: `Docs\Phase6-Plan.md` und Abschnitt „Daten-Controls“ in `Docs\Architektur.md` |
| Phase 7 (04.10.2026) | 16 Controls für ganze Anwendungen: 7a `TPPGLabel`/`TPPGLinkLabel` (`PPG.Labels`), `TPPGBadge`/`TPPGProgressRing`/`TPPGInfoBar` (`PPG.Feedback`), `TPPGExpander`, `TPPGSplitter`, `TPPGRating`, `TPPGSearchEdit`; 7b `TPPGCalendar`, `TPPGDatePicker` (Kalender-Popup, DFM wie `TDateTimePicker`), `TPPGTimePicker`; 7c `TPPGNavigationView`, `TPPGBreadcrumb`, `TPPGToolBar` (Actions, Überlauf), `TPPGStatusBar` (DFM wie `TStatusBar`); 7d `TPPGNotificationCenter`/`TPPGToast` (`PPG.Notifications`). Die Demo hat jetzt die NavigationView als Hauptnavigation, eine StatusBar und drei neue Seiten. Details: `Docs\Phase7-Plan.md` und Abschnitt „Phase 7“ in `Docs\Architektur.md` |
| QS | **523 DUnit-Tests grün** (Phase 7 komplett plus zwei Prüfrunden am 04.10.2026). Neu: `Tests\PPG.Tests.Streaming.pas` schickt jede einfache Property aller 35 Paletten-Controls durch die DFM. **Sichttests** `Tests\PPG.Tests.Visual.pas`: alle Controls in 5 Zuständen × 6 Varianten. Jeder Lauf schreibt die Galerie nach `Tests\Visual\Gallery\*.png` (ansehen!) und prüft automatisch: nicht leer, Hover/Fokus/Deaktiviert sichtbar, Deaktiviert ohne kräftige Farben und erkennbar, Dunkel lesbar. Die Referenzbilder in `Tests\Visual\Baseline` gelten als Soll; bei gewollter Optikänderung den Ordner löschen, dann werden sie neu angelegt, Benchmark mit neuen Vorgaben für Calendar und NavigationView eingehalten, Runtime auch Win64; davor 410 (Phase 6), davor 333 (Phase 8), 313 (8.2) und 296; Benchmark hält alle Vorgaben ein (`build.ps1 -Projects Bench -Config Release`, dann `Tests\Bench\PPGlowBench.exe`). Davor: 247 DUnit-Tests grün (Konsole, Exit-Code = Fehlerzahl), Runtime auch für Win64 kompiliert. Demo mit Screenshot-Modus: zehn Seiten (`/page 0..9`, 4 = Listen, 5 = Baum, 6 = Grid, 7 = Kleine Controls, 8 = Datum + Zeit, 9 = Navigation; `/dropdownimages` öffnet die Bild-Combo; `/toastcapture datei.png` zeigt drei Toasts und speichert die Bildschirmecke), `/fieldfocus` zeigt die Fokuslinie, `/dropdown` eine offene ComboBox-Liste |
| Phase 9 (04.10.2026, gebaut und getestet) | Designer-Komfort (Palettensymbole, Appearance-Editor, Preset-Galerie, Item-Editoren, Verben), nativer UIA-Provider für Grid/TreeView/ListBox/CheckListBox, sieben DB-Controls in eigenen Paketen `PPGlowDBR`/`dclPPGlowDB`, Übersetzung zur Laufzeit (`PPG.Lang`, Deutsch), RTL- und DPI-Galerie, Regel-Prüfer, Leak-Lauf, Hilfe pro Control, Migrationsleitfaden und `migrate.ps1`, Demo als Katalog mit Suche und Datenbank-Seite. In einer Cloud-Sitzung ohne Delphi geschrieben, danach lokal gebaut und geprüft: **591 DUnit-Tests grün, `/leaks` grün (Zuwachs ~5 KB), Demo-Selbsttest 65/65.** Beim ersten Lauf gefunden: falsche GUID von `IGridProvider` (Grid-Muster kam bei Screenreadern nie an; jetzt prüft `InterfaceGuidsMatchWindows` alle UIA-GUIDs gegen die Windows-Registry), DB-Feld setzte im unsichtbaren Fenster den Fokus (EInvalidOperation statt stillem Abbruch), Testhilfen der UIA-Tests (eigene statt Control-Wurzel, Spalten-Reihenfolge im Grid), Zähler in sieben Testklassen ohne `SetUp` (DUnit verwendet Testobjekte im Leak-Lauf wieder). Plan, Umsetzung und Abweichungen: `Docs\Phase9-Plan.md` |
| Phase 10 (04.10.2026) | Datenvisualisierung: `TPPGSparkline` (`PPG.Sparkline`, auch als `PPGDrawSparkline` für Grid-Zellen), `TPPGGauge` und `TPPGKpiTile` (`PPG.Gauge`), `TPPGChart` (`PPG.Chart`, Datenmodell `PPG.Chart.Series`: Linie, Stufe, Fläche, Säule, Balken, Kreis, Ring, gestapelt/100 %, zweite Y-Achse, Datum-/Zahlachse, Referenzlinien, Legende, Tooltip, Tastatur, Screenreader-Kinder, Export PNG/Zwischenablage, Animationen), `TPPGDBChart` (`PPG.DB.Chart` im Paket `PPGlowDBR`). Fundament: `IPPGShapeCanvas`, `IPPGChartRenderer`, `PPG.Render.Shapes`, `PPG.Chart.Scale`, `PPG.Chart.Palette`. PNG-Export über den GDI+-Encoder (`PPGSaveBitmapAsPng`), damit `PPGlowR` kein `vclimg` braucht. Demo-Seite 13 „Diagramme“, DB-Chart auf Seite 12, Schalter `/chartpng seite key datei.png`. **678 Tests grün, `/leaks` grün, Selbsttest 79/79, Benchmark eingehalten, Runtime/DB-Runtime Win64.** Plan, Umsetzung, Abweichungen und gefundene Fehler: `Docs\Phase10-Plan.md` |
| Phase 11 (05.10.2026) | Menüs, Hints, Dialoge: `TPPGPopupMenu` und Menü-Engine (`PPG.Menus`), `TPPGMenuBar` (`PPG.MenuBar`), Bearbeiten-Menü aller Felder (`UseSystemContextMenu`), `TPPGHintManager`/`TPPGCustomHint` (`PPG.Hints`), `TPPGTeachingTip` (`PPG.TeachingTip`), `TPPGTaskDialog` + `PPGMessageDlg`/`PPGShowMessage`/`PPGInputQuery`/`PPGInputBox` (`PPG.Dialogs`), `TPPGWizard` (`PPG.Wizard`). Fundament: `PPG.Popup.Placement`, `PPG.AppHooks` (Nachrichten-Verteiler, `PPGWatchControl`), `IPPGMenuRenderer`/`IPPGHintRenderer`. Designer: Palette, Symbole, Seiten-Editor des Assistenten, „Dialog testen…“. Demo-Seite 14 „Menüs & Dialoge“, Hints der Demo über den Manager. Nebenbei behoben: Achsenschritte unter Win64 (Phase 10). **757 Tests grün (Win32 und Win64), `/leaks` grün, Selbsttest 88/88.** Plan, Umsetzung, Abweichungen und Offenes: `Docs\Phase11-Plan.md` |
| Phase 12 (05.10.2026) | Eingabe-Erweiterungen: `TPPGNumberEdit` (Zahl/Währung/Prozent, rechnet, kaufmännisch gerundet), `TPPGMaskEdit` (VCL-Maskenlogik, Fehler am Feld), `TPPGPasswordEdit` (Aufdecken, Feststelltaste, kein Kopieren), `TPPGFileEdit` (Dialoge, Ablegen, Autovervollständigung), `TPPGColorPicker` (Paletten, HSV, Hex), `TPPGCheckComboBox`, `TPPGColumnComboBox` (Spalten, Sortieren, virtuell), `TPPGTagEdit` (Chips, Vorschläge) und DB-Varianten in `PPG.DB.Fields` (Mask, Number, ColorPicker, CheckCombo, TagEdit). Fundament: `IPPGFieldInner`, `IPPGFieldValue`, `PPG.NumberFormat`, `PPG.ColorSpace`, Aufklapp-Basis `PPG.Controls.DropDown` + `PPG.RowPopup`. Nebenbei behoben: Felder mit AutoSize hielten die gesetzte Breite nicht. **837 Tests grün (Win32 und Win64), `/leaks` grün, Selbsttest 94/94.** Plan, Umsetzung, Abweichungen: `Docs\Phase12-Plan.md` |
| Anpassbarkeit (08.10.2026) | Drei Bausteine: **Element-Stile** (`PPG.ElementStyle`: `TPPGElementStyle`, `TPPGStyleGroup`, `TPPGFontCache`) in Grid/DB-Grid (10 Bereiche, Spalten-`Style`/`TitleStyle`/`TitleAlignment`, `FixedColor`, `GridLineWidth`, `DrawingStyle`), Listen, TreeView, Combo-Liste, Reitern, NavigationView, Menüs, Kalender, Planer (`Categories`), Kanban, Chart und kleinen Controls; **Tokens** (`TPPGStyleManager.AccentColor`, `ThemeColors`, `ChartPalette`, Theme-Datei `PPG.ThemeFile`); **Zeichen-Ereignisse** (`PPG.CustomDraw`, `OnCustomDrawItem` usw.). Dazu: `Appearance.Focused`/`.Dark`, `FontStyle` je Zustand, Farbe/Stil je Item/Knoten/Reiter/Eintrag, Button `Alignment`/`Margin`/`PressedImageIndex`/`…ImageName`/`ImageTint`, `RoundedCorners` (`IPPGCornerCanvas`), `Shadow`, `ReadOnlyStyle`, `Touch`/`OnGesture`, `SaveLayout`/`LoadLayout` (Kanban, Planer), `SaveQuickAccess`/`LoadQuickAccess` (Ribbon), `TPPGKanbanPrinter` (`PPG.Kanban.Print`), `migrate.ps1` für DB-Grid-Spalten. Tests: `Tests\PPG.Tests.Custom.pas`. Gefunden und behoben: `TPPGChartStyles` wurde nie freigegeben (Leck); neue Leck-Suche je Testklasse `/leaksuites`. |
| IDE | Packages installiert, **Stand Anpassbarkeit 08.10.2026** (alle Phasen bis 14c), inkl. DB-Pakete, Win32 + Win64. Neu installieren: IDE schließen, `install.ps1` (baut selbst). Mit `-LoadTest` löscht Norton 360 die BPLs |

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
Tests\PPGlowTests.exe                       # 0 = alles grün
Tests\PPGlowTests.exe /leaks                # zwei Läufe, Exit-Code <> 0 bei Speicherlecks
Tests\PPGlowTests.exe /leaksuites           # Leck-Suche: Zuwachs je Testklasse ("LEAKSUITE Klasse Bytes", ab 1 KB)
Demo\PPGlowDemo.exe /selftest C:\pfad\selftest.txt   # Szenarien aller Demo-Seiten
# Generatoren (Ergebnis wird eingecheckt):
powershell -ExecutionPolicy Bypass -File Build\make-icons.ps1 [-Preview Docs\palette-icons.png]   # Palettensymbole (.dcr)
powershell -ExecutionPolicy Bypass -File Build\make-lang.ps1            # Lang\PPGlow.de.txt -> PPG.Lang.De.pas (-Check prüft nur)
powershell -ExecutionPolicy Bypass -File Build\make-docs.ps1            # Docs\Controls\*.md, types\*.md und html: jede Property/jedes Ereignis mit Typ, Vorgabe, Wirkung, Nutzung
#   Texte in Docs\Controls\props\*.txt (Schluessel Klasse.Name); neue Properties dort beschreiben, "-Missing datei.txt" listet Luecken (Soll: 0)
powershell -ExecutionPolicy Bypass -File Build\migrate.ps1 -Path <Projekt> -Recurse -WhatIf   # VCL/TMS -> PPGlow
# Release + Installation (IDE geschlossen!):
powershell -ExecutionPolicy Bypass -File Build\build.ps1 -Only Delphi13 -Projects Runtime,Design -Platform Win32 -Config Release
powershell -ExecutionPolicy Bypass -File Build\build.ps1 -Only Delphi13 -Projects Runtime,Design -Platform Win64 -Config Release
powershell -ExecutionPolicy Bypass -File Build\install.ps1     # baut selbst (Release Win32/Win64), prüft Alter, Registry und Abhängigkeiten (nur lesend); -NoBuild, -NoDB, -Uninstall; -LoadTest löst Norton aus!
# Sichtprüfung (danach PNG ansehen):
Demo\PPGlowDemo.exe /screenshot C:\pfad\x.png [/hover] [/focus] [/gdi] [/style Windows10Dark]
```
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

## Roadmap
Die freigegebene Roadmap bis TMS-Niveau steht in `Docs\Roadmap.md`. Sie umfasst die Phasen 5–9: Daten-Fundament, Listen/Baum/Grid, Navigation/Datum/Rückmeldung, Fluent-Design mit Dark Mode sowie Designer/DB/UIA. Jede Phase bekommt vor dem Start einen eigenen Detailplan und endet mit Bericht und OK. Reihenfolge, **vom User am 03.10.2026 entschieden**: Phase 5 (**fertig**), dann **Phase 8 vorgezogen** (Detailplan: `Docs\Phase8-Plan.md`), danach Phase 6, 7 und 9.

**Phase 6 (Daten-Controls) ist abgeschlossen** (04.10.2026, 6a–6c am Stück wie vom User entschieden, 410 Tests grün, Win32/Win64, Benchmark eingehalten; Plan und Abweichungen in `Docs\Phase6-Plan.md`).

**Phase 7 (Navigation, Datum/Zeit, Rückmeldung) ist abgeschlossen** (04.10.2026, 7a–7d am Stück wie vom User entschieden, 513 Tests grün, Win32/Win64, Benchmark eingehalten; Plan, Umsetzung und Abweichungen in `Docs\Phase7-Plan.md`).

**Phase 9 (Designer-Komfort, UIA, DB, Übersetzung, Prüfung, Doku) ist abgeschlossen** (in einer Cloud-Sitzung ohne Delphi geschrieben, am 04.10.2026 lokal gebaut und geprüft; `Docs\Phase9-Plan.md`).

**Phase 12 ist abgeschlossen** (05.10.2026, gestartet mit „starte phase 12 ohne installation“; Bericht an den User und OK für Phase 13 stehen aus). Offen aus Phase 12: ComboBox auf die neue Aufklapp-Basis umstellen, Zellroutine des Grids (Phase 13) für die ColumnComboBox, übersetzte Farbnamen.

**Phase 13 ist abgeschlossen** (06.10.2026, gestartet mit „Yes Phase 13“; Bericht und OK für Phase 14 stehen aus). Umsetzung, Abweichungen und Benchmarks: `DocsPhase13-Plan.md` (Abschnitt Umsetzung) und `DocsArchitektur.md` (Phase 13). Grid in Schichten (`PPG.Grid.Columns/View/Data/Paint/Edit/CellKinds/Styles`), Druck (`PPG.Grid.Print`, `TPPGGridPrinter` auf der Palette), Export (`PPG.Xlsx`, `PPG.Grid.Export`). Regel: `VRow`/`VCol` = Anzeige, sonst Daten-Indizes; `Col` ist jetzt die Datenspalte. Offen: Gruppenzeilen/verbundene Zellen im Druck, Miniaturbilder in der Vorschau, Datumsformate beim xlsx-Import, Statistik-Formate im DB-Grid.

**Phase 14a ist abgeschlossen** (06.10.2026, gestartet mit „Nope mach weiter mit den Phasen“ bzw. „Weiter machen“; Bericht und OK für 14b stehen aus). Units: `PPG.TimeZones`, `PPG.Planner.Recurrence/Layout/Model/ICal` (Kern), `PPG.Planner` (`TPPGPlanner`), `PPG.Planner.Print` (`TPPGPlannerPrinter`), `PPG.DB.Planner` (`TPPGDBPlanner`), gemeinsamer Druck `PPG.Print` (aus `PPG.Grid.Print` herausgelöst). Demo-Seite 15 „Planer“. Umsetzung und Abweichungen: `DocsPhase14-Plan.md` (Umsetzung 14a), `DocsArchitektur.md` (Phase 14a). Offen: Abfrage „Vorkommen oder Serie“, Inline-Bearbeitung von Ort/Text, eigenes Zeitleisten-Raster.

**Phase 14b ist abgeschlossen** (06./07.10.2026, gestartet mit „starte nächste Schritte 14b ohne Installation“; Bericht und OK für 14c stehen aus). Units: `PPG.Ribbon.Layout`, `PPG.KeyTips` (Kern, reine Funktionen), `PPG.Ribbon.Items` (Modell), `PPG.Ribbon` (`TPPGRibbon`, Popups, KeyTip-Overlay). Tests `PPG.Tests.Phase14b` (16) und `PPG.Tests.Phase14bRibbon` (28). Demo-Seite 16 „Ribbon“, Schalter `/ribboncapture keytips|keytips2|minimized|group|gallery datei.png` (echte Bildschirmpixel: Demo-Fenster muss vorne liegen, sonst ist fremder Bildschirminhalt mit drauf). Umsetzung und Abweichungen: `Docs\Phase14-Plan.md` (Umsetzung 14b), `Docs\Architektur.md` (Phase 14b), Hilfe `Docs\Controls\notes\TPPGRibbon.md`. Gefundener Fehler beim Sichttest: Controls im Popup waren unsichtbar (VCL hält das per API gezeigte Popup für unsichtbar) → `ShowWindow(SW_SHOWNA)` wie beim DatePicker, Test prüft jetzt `IsWindowVisible`. Offen: Speichern des Schnellzugriffs, Tastaturfokus in Popups, Galerie-Kategorien.

**Phase 15 zurueckgestellt (07.10.2026):** Der User will PPGlow seinem Arbeitgeber vorfuehren und spaeter in dessen Produkten einsetzen. Lizenz/Rechte, Firmen-Delphi (Version, Edition), Code-Signatur und Versionsnummer klaert er zuerst mit dem Arbeitgeber; vorher wird Phase 15 nicht gebaut. Bereits entschieden: Inno Setup, offizielle Versionen XE2, 10.4, 11, 12, 13.

**Ultra Review (07.10.2026):** Quellcode von Core, Render, Theme und Access in drei Teilen geprueft (PRs #3-#5 gegen eine leere Basis, nur zur Review, nicht mergen; Teil Fachlogik lokal mit /code-review, weil das Cloud-Ergebnis verloren ging). Behoben mit Regressionstests in `TestsPPG.Tests.Review.pas`: unsichtbare Markup-Links, Theme-/StyleManager-Wechsel pro Empfaenger abgesichert, GDI-Strichlinien, doppeltes Fehlerlog, Achsen-Ueberlauf bei grossen Werten, iCal (EXDATE ganztaegig, kein EXDATE fuer herausgeloeste Vorkommen), UNTIL-Z bei tzmLocal, Ausnahme in der Sommerzeit-Luecke, Ids bei `Appointments.Assign`, YEARLY+BYMONTHDAY in allen Monaten, Expand springt ohne COUNT zum Zeitraum, UIA-Fokus der Wurzel. **1120 Tests gruen Win32/Win64, Leak-Lauf gruen, Selbsttest 141/141.** Controls, DB, Tests und Demo wurden nicht per Review geprueft (zu gross fuer Ultra Review).

**Phase 14c ist abgeschlossen** (07.10.2026, gestartet mit „mach 14 c“, ohne Installation; Bericht und OK für Phase 15 stehen aus). Units: `PPG.Kanban.Layout` (Kern), `PPG.Kanban.Items` (Modell), `PPG.Kanban` (`TPPGKanban`), `PPG.DB.Kanban` (`TPPGDBKanban`, Paket `PPGlowDBR`). Tests `PPG.Tests.Phase14c` (9), `PPG.Tests.Phase14cKanban` (18), `PPG.Tests.Phase14cDB` (8). Demo-Seite 17 „Kanban“. Umsetzung und Abweichungen: `Docs\Phase14-Plan.md` (Umsetzung 14c), `Docs\Architektur.md` (Phase 14c), Hilfe `Docs\Controls\notes\TPPGKanban.md`/`TPPGDBKanban.md`. Beim Sichttest gefunden: Swimlane-Köpfe wurden von den Spalten überdeckt, Kartenzahl im RTL-Kopf über dem Titel; Pfeiltasten nahm die Scroll-Basis (jetzt `KeyboardScrolling := False`). Offen: Drucken, Filter, Kartenvorlagen, Spalten ziehen.

**Phase 11 ist abgeschlossen** (05.10.2026, freigegeben mit allen Empfehlungen der Detailpläne). Die offenen Punkte (MDI-Menüs, Grid-Kontextmenü, `migrate.ps1` für Menüs/TaskDialog, WinEvent-Test) stehen in `Docs\Phase11-Plan.md`.

**Roadmap 2 (Phasen 11–16, Weg zum TMS-Niveau)** ist vom User freigegeben (05.10.2026, Empfehlungen übernommen; nur Phase 15 Frage 1 „verkaufen/verteilen“ ist offen) (05.10.2026, `Docs\Roadmap2.md` mit Detailplänen `Docs\Phase11-Plan.md` bis `Phase16-Plan.md`): 11 Menüs/Hints/Dialoge, 12 Eingabe-Erweiterungen, 13 Grid-Profi, 14 Großkomponenten (Planer, Ribbon, Kanban, Code-Editor nach Entscheidung), 15 Produkt, 16 Demo mit geführter Tour. Der Absicherungsblock (XE2-/10.x-Lauf, Praxistest, Win64-Testlauf) wurde vom User aus dem Plan genommen und bleibt unten unter Nächste Schritte. **Vor dem Start: Freigabe und die Entscheidungen am Ende jedes Detailplans.**

**Phase 10 (Datenvisualisierung) ist abgeschlossen** (04.10.2026, vom User ergänzt: voller Umfang Sparkline, Gauge/KPI-Kachel, Chart, DB-Chart, am Stück; 678 Tests grün; Plan, Umsetzung, Abweichungen in `Docs\Phase10-Plan.md`).

**Phase 8 (modernes Design) ist abgeschlossen** (04.10.2026, 333 Tests grün, Win32/Win64, Benchmark eingehalten). Bausteine von Phase 8:
- 8.1 Design-Tokens (`PPG.Tokens`) – **fertig** (03.10.2026, 304 Tests grün, Win32/Win64)
- 8.2 Preset `Fluent11` – **fertig** (04.10.2026, 313 Tests grün, Win32/Win64, Sichtprüfung GDI+ und GDI). Details: `Docs\Phase8-Plan.md`, Abschnitt „Preset Fluent11“ in `Docs\Architektur.md`. Demo: `/preset Fluent11`
- 8.3 Dark Mode ohne VCL-Style – **fertig** (`PPG.Theme`: Hell/Dunkel/System, `StyleForms` mit dunkler Titelleiste, `TPPGStyleManager.ThemeMode`). Demo: Umschalter „Theme“ und `/theme dark`
- 8.5 Bewegungskurven – **fertig** (`TPPGEasing`, `ekDecelerate` für Aufklappen, Unterstrich, Scrollen, Fokuslinie)
- 8.6 Fluent-Icons – **fertig** (`PPG.IconFont`, genutzt von Fluent11)
- 8.4 Mica – Prototyp ausgewertet, **nicht** in der Suite (GDI-Alpha-Problem; Ergebnis in `Docs\Architektur.md`). Demo: `/mica`

Rangfolge der Farben: Hochkontrast > VCL-Style > Dark Mode > Appearance.

## Nächste Schritte (Vorschlag, Reihenfolge mit dem User abstimmen)
**Prüfung Anpassbarkeit (07.10.2026):** Anforderungsliste und Auswertung aller Controls in `Docs\Anforderungen-Anpassbarkeit.md`. Ergebnis: Einfache Controls sind gut anpassbar. Komplexe Controls (Grid, Liste, Baum, Reiter, Planer, Kalender) haben keine Farben und Schriften je Bereich (Kopf, Auswahl, Zebra, Linien). Eine eigene Akzent- bzw. Markenfarbe und Tokens lassen sich nicht überschreiben. Vorschlag: drei Bausteine (Element-Stile, überschreibbare Tokens, einheitliche Zeichen-Ereignisse). **Am 08.10.2026 vollständig umgesetzt** (siehe „Fertig“).
0. **Phase 14c abschließen:** Bericht an den User, OK für Phase 15 (Produkt, `Docs\Phase15-Plan.md`, Frage 1 „verkaufen/verteilen“ noch offen) einholen. In der IDE für 14c (nach Installation): `TPPGKanban` und `TPPGDBKanban` auf der Palette, „Edit columns…“, Feldauswahl am DB-Board, DFM mit Karten speichern/laden; Demo-Seite 17 mit Maus (Ziehen, Einklappen, Rad), Tastatur (Pfeile, Strg+Pfeile) und Narrator (Ansage nach dem Verschieben).
   **Phase 14b:** In der IDE für 14b (nach Installation): `TPPGRibbon` auf der Palette mit Symbol, Komponenten-Editor (Edit tabs/groups/Quick Access, New/Next/Previous Tab), Klick auf Registerkarten im Designer, eine `TPPGComboBox` aufs Ribbon legen und einem Item als `Control` zuweisen, DFM speichern und laden; Demo-Seite 16 mit Maus (schmaler ziehen, Doppelklick auf Karte, Rechtsklick → Schnellzugriff), Tastatur (Alt, Buchstaben, Esc, Pfeile, Strg+F1) und Narrator.
   **Phase 14a:** In der IDE für 14a: Palette (`TPPGPlanner`, `TPPGPlannerPrinter`, `TPPGDBPlanner` mit Symbol), Ressourcen-Editor, Feldauswahl am DB-Planer, Verben Vorschau/Seite einrichten am Planer-Drucker; Demo-Seite 15 mit Maus, Tastatur und Narrator. Danach wie bisher für Phase 13: Installation (Phase 11 + 12 + 13 + 14a + 14b + 14c) erst nach Freigabe und mit geschlossener IDE. In der IDE für Phase 13: `TPPGGridPrinter` auf der Palette (Verben Vorschau/Seite einrichten), Grid-Spalteneditor mit den neuen Properties (Visible, DisplayIndex, Band, Aggregate, GroupIndex, CellKind, Format), Demo-Seite Tabelle per Maus (Kopf ziehen, Rechtsklick-Kopfmenü, Gruppenleiste, Doppelklick auf Kopfkante) und mit Narrator (Gruppenzeilen). Aus Phase 12: In der IDE dann: 13 neue Palettensymbole (8 PPGlow, 5 PPGlow DB), Spalten-Editor der ColumnComboBox, Demo-Karte „Spezialfelder“ (Seite Formular) und DB-Seite. Aus Phase 11: `install.ps1` erst laufen lassen, wenn der User die IDE geschlossen hat. Danach in der IDE: Palette (7 neue Symbole), Menü-Designer an `TPPGPopupMenu`, Seiten-Editor des Assistenten, „Dialog testen…“ am TaskDialog; Demo-Seite 14 mit Maus, Tastatur (Alt/F10, Umschalt+F10, Tab im TeachingTip) und Narrator.
   - Hinweis: Am 05.10.2026 hat die geöffnete IDE beim Speichern vielen Units eine UTF-8-BOM vorangestellt (Regel-Prüfer: ASCII). Entfernt mit `perl -0777 -pi -e 's/\A\xEF\xBB\xBF//'`; nur die BOM, sonst unverändert.
1. **Phase 10 in der IDE ansehen** (am 05.10.2026 installiert, alle 8 BPLs vorhanden, Norton ohne neue Funde):
   - Palette: TPPGSparkline, TPPGGauge, TPPGKpiTile, TPPGChart (PPGlow) und TPPGDBChart (PPGlow DB) mit Symbol.
   - Formulardesigner: Serien-Editor („Edit series...“, Doppelklick), Bereichs-Editor des Gauge, Feldlisten für `LabelField`/`XField`, `ValuesText` im Objektinspektor, DFM speichern und laden.
   - Demo-Seite 13 „Diagramme“ mit der Maus und der Tastatur ausprobieren, Live-Daten starten, Hochkontrast einschalten (im Test nicht abgedeckt), Narrator auf dem Chart (Datenpunkte als Kinder).
2. **Praxistest mit dem User:**
   - im Formulardesigner arbeiten (Ziehen, Properties, DFM speichern und laden), auch die Controls aus Phase 6, 7 und 10
   - Monitorwechsel mit unterschiedlicher DPI, Remote-Desktop
   - `migrate.ps1` an einem echten Projekt (Kopie!)
3. **Kompatibilität:** XE2- und 10.x-Lauf nach `Docs\Kompatibilitaet.md`.
4. **Offen aus Phase 9:** Benchmark DB-Grid mit 100 000 Datensätzen; DB-Controls in den Streaming-Test aufnehmen; weitere Sprachen (eine Datei `Lang\PPGlow.xx.txt` + `make-lang.ps1`).
5. **Mögliche Folgeschritte zu Phase 10:** Zoom/Pan, logarithmische Achse, Splines, Tooltip als Popup außerhalb des Controls, Feldzuordnung pro Serie im DB-Chart.
6. **Offen aus früheren Phasen (optional):** TrackBar-Auswahlbereich und manuelle Ticks, Panel-`AutoSize`, mehrzeilige/seitliche Reiter, Reiter umsortieren, `TPPGFloatSpinEdit`, HotImageName/DisabledImageName, weitere Presets.

## Vom User bestätigte Entscheidungen
- Mindestversion XE2. Beide Presets. Eigenes Präfix `PPG`.
- **Bewusst anders als die VCL:** `Checked` im Code setzen löst nur `OnChange` aus, nicht `OnClick`.
- Für Win32 ist DUnit statt DUnitX im Einsatz, weil DUnitX hier nur für Win64 installiert ist.
- Reihenfolge bisher: Phase 1 → 2 → Lücken 1/4/6 → Phase 3 → Phase 4 (4a, 4b, 4c). Designer-Komfort ist offen.
- Phase 4: Umfang Edit, SpinEdit, Memo, ComboBox mit **eigenem Popup**, PageControl/TabControl (vom User gewählt).
- Phase 4a (eigene Entscheidungen, vom User noch zu bestätigen): SpinEdit wirft bei `MinValue > MaxValue` **nicht** (wie `TSpinEdit`, sonst scheitert `MinValue := 10; MaxValue := 100`). Die Buttons im Edit haben keinen eigenen Hint und kein `ImageName`. `TextHintVisibleOnFocus` steht standardmäßig auf `False`.
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
  - DatePicker: Eingabe nur Ziffern und Datumstrenner (Kurzformat); `Kind`, `DateMode`, `ParseInput` werden nur gelesen/gespeichert. Leeres Datum nur mit `ShowCheckbox`.
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
