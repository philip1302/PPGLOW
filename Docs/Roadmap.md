# PPGlow Roadmap: auf TMS-Niveau (Phasen 5–9, vom User freigegeben am 03.10.2026)

**Status:** Phase 5, 8 (vorgezogen), 6 und 7 sind fertig (`Docs\Phase5-Plan.md`, `Docs\Phase8-Plan.md`, `Docs\Phase6-Plan.md`, `Docs\Phase7-Plan.md`). Es folgt Phase 9.

## Context
- **Stand:** Phase 4 ist fertig.
  - 21 Controls: Buttons, Auswahl-Controls, Bereiche, Container, Eingabe, ComboBox, Reiter.
  - 247 Tests, zwei Presets, VCL-Styles, MSAA, DPI.
- **Ziel des Users:** Die Suite soll auf das Niveau von TMS VCL UI Pack kommen. Dafür braucht es:
  1. **die Controls, mit denen TMS-Kunden ganze Anwendungen bauen**, also Daten-Controls (Liste, Baum, Grid), Navigation, Datum/Zeit und Benachrichtigungen;
  2. eine **Infrastruktur, die das trägt**: Virtualisierung, eigene Scrollleisten, Item-Modell, Datenbindung und Design-Tokens;
  3. ein **modernes Erscheinungsbild**: Windows-11/Fluent-Preset, Dark Mode ohne VCL-Style, Mica-artige Flächen, Motion.
- **Grundsätze bleiben:**
  - Paint sendet keine Nachrichten; ein gemeinsamer Animator; native Texteingabe.
  - ASCII, CRLF, XE2-fähig.
  - Nach jeder Phase: Bericht und OK des Users.

## Was TMS ausmacht (Bewertung)
| TMS-Stärke | Beispiel | Stand PPGlow | Lücke |
|---|---|---|---|
| Sehr breites Sortiment | ca. 600 Controls | 21 | Fokus auf die etwa 25, die 90 % der Formulare abdecken |
| Daten-Controls | TAdvStringGrid, TAdvTreeView, TAdvListBox | keine | größte Lücke |
| Einheitliches Styling | TAdvFormStyler, Office-/Windows-Styles | Presets und StyleManager | Design-Tokens, Win11-Preset, Dark |
| Reiche Items | HTML-Text, Bilder, Badges | nur Text | Mini-Markup statt HTML |
| Designer-Komfort | Item-Editoren, Style-Galerie | Komponenteneditor (Seiten) | Collection-Editoren, Vorschau, Palettensymbole |
| Datenbindung | DB-aware Varianten | keine | `TPPGDBxxx` für Edit, Combo, Grid |
| Qualität | gemischt | Tests, MSAA, DPI | unser Vorsprung: beibehalten |

---

## Phase 5: Fundament für Daten-Controls (vor allen Listen)
Ohne diese Schicht wird jedes Listen-Control ein Einzelstück. Deshalb kommt sie zuerst.

1. **`PPG.Controls.Scroll`: `TPPGCustomScrollControl`**
   - Eigene Overlay-Scrollleisten im Fluent-Stil: ruhend schmal, beim Hover breit, blenden aus.
   - Gezeichnet über einen neuen `IPPGScrollRenderer`; den Daumen gibt es schon als `DrawScrollThumb`.
   - Pixelgenaues weiches Scrollen über den Animator, Mausrad mit `WHEEL_DELTA`-Rest, Touchpad (hochauflösende Deltas), Shift+Rad horizontal.
   - Auto-Scroll beim Ziehen, Tastatur (Bild, Pos1/Ende).
   - **Fallstrick:** keine `WS_VSCROLL`-Bars mischen; die native Scrollleiste färbt der VCL-Style anders. Alles selbst zeichnen und die Barrierefreiheit über `ROLE_SYSTEM_SCROLLBAR`-Kinder bereitstellen.
2. **Item-Modell `PPG.Items`**
   - `TPPGItem`/`TPPGItems` als `TCollection` mit Text, Detail, ImageIndex/ImageName, Badge, Checked, Enabled, Tag, Data und Gruppe.
   - Für große Datenmengen statt der Collection ein virtueller Modus: `OnGetItemCount`, `OnGetItemText`, `OnGetItemImage`.
   - **Best Practice:** Beide Modi hinter einem Interface `IPPGItemSource`, damit das Control die Quelle nicht kennt (DIP).
3. **Virtualisierung**
   - Gezeichnet werden nur sichtbare Zeilen. Feste Zeilenhöhe bedeutet O(1)-Positionierung, variable Höhe einen Präfixsummen-Cache.
   - Ziel: 1 000 000 Einträge ohne Verzögerung (Leistungstest).
4. **Mini-Markup `PPG.Markup`** (statt TMS-HTML)
   - Unterstützt: `<b> <i> <u> <s> <color=..> <img=n> <a href=..>`, Zeilenumbruch.
   - Parser mit Cache pro Text; Messen und Zeichnen über `IPPGCanvas`; Hit-Test für Links.
   - **Fallstrick:** keine HTML-Engine nachbauen. Schmaler, getesteter Funktionsumfang; ungültiges Markup wird als Text gezeichnet und wirft nie.
5. **Gemeinsame Auswahl-Logik `TPPGSelection`**
   - Einfach, mehrfach mit Strg/Shift, Anker, Fokus-Element ungleich Auswahl.
   - Wird von ListBox, TreeView und Grid geteilt.
6. **Barrierefreiheit:** `IPPGAccessibleChildren` um Wert und Mehrfachauswahl erweitern (`STATE_SYSTEM_MULTISELECTABLE`, `EXTSELECTABLE`).
7. **Leistung:** Benchmark-Projekt `Tests\Bench` mit 1000 Buttons, 100k-Liste und Resize-Sturm. Ergebnisse kommen in die Doku.

## Phase 6: Daten- und Listen-Controls
| Control | Vorbild | Kern-Features |
|---|---|---|
| `TPPGListBox` | TListBox, TAdvSmoothListBox | Items oder virtuell, Mehrfachauswahl, Gruppen-Header, Detailzeile, Bild, Badge, Markup, Suche beim Tippen, Drag zum Umsortieren, DFM wie TListBox (`Items.Strings`) |
| `TPPGCheckListBox` | TCheckListBox | Kästchen über `IPPGIndicatorRenderer`, „alle wählen“ |
| `TPPGTreeView` | TTreeView, TAdvTreeView | Knoten virtuell (`OnGetChildCount`, lazy), Aufklapp-Animation, Kästchen (tri-state), Inline-Umbenennen über das native Edit, Drag & Drop, Linien optional (Fluent ohne Linien) |
| `TPPGGrid` (Phase 6b, eigener Schritt) | TStringGrid, TAdvStringGrid | virtuell, feste Kopfzeile und -spalte, Sortieren, Filterzeile, Spaltenbreite ziehen, Zelleditoren über die Feld-Basis (Edit, Combo, Spin, Check), Kopieren/Einfügen (TSV), Export CSV |
| ComboBox-Ausbau | TAdvComboBox | Bilder/Markup in der Liste, Filtern beim Tippen, Gruppen; die Liste wird zu `TPPGListBox` im `TPPGPopupWindow` |

- **Fallstricke:**
  - Inline-Editoren gehören dem Control. Fokus, Esc/Enter und Scrollen während des Editierens müssen sauber laufen; das Muster aus `PPG.ComboBox` (`WantSpecialKey`, Capture) wiederverwenden.
  - Das Grid wird nie über die VCL-Kind-Controls aufgebaut: ein einziges Fenster, Zellen gezeichnet.
  - Sortierung und Filter arbeiten auf einem Index-Array, nie auf den Daten.

## Phase 7: Navigation, Datum/Zeit, Rückmeldung
| Gruppe | Controls |
|---|---|
| Navigation | `TPPGNavigationView`: Seitenleiste wie WinUI und TMS AdvNavBar, einklappbar mit Hamburger, Icons, Badges, nutzt TabStrip-Logik. `TPPGBreadcrumb`. `TPPGToolBar` mit Overflow-Menü. `TPPGStatusBar` mit Panels und Markup |
| Datum/Zeit | `TPPGCalendar` (Monat/Jahr/Dekade mit animiertem Zoom, Wochennummern ISO 8601, Bereichsauswahl, gesperrte Tage). `TPPGDatePicker`/`TPPGTimePicker` (Feld-Basis mit Popup aus `PPG.Popup`, Locale über `FormatSettings`, Eingabe mit Maske) |
| Rückmeldung | `TPPGToast`/`TPPGNotificationCenter` (gestapelt, Auto-Ausblenden, Aktionen), `TPPGBadge`, `TPPGProgressRing` (unbestimmt), `TPPGInfoBar` (Info/Warnung/Fehler mit Schließen) |
| Kleinere | `TPPGLabel`/`TPPGLinkLabel` (Markup, Ellipse, Fokus für Links), `TPPGSearchEdit` (Feld-Basis mit Lupe, Verzögerung, Vorschlagsliste), `TPPGRating`, `TPPGExpander`/`TPPGCategoryPanel` (animiertes Auf- und Zuklappen), `TPPGSplitter` |

- **Fallstricke:**
  - Datum: Die Kalenderwoche ist je Locale anders (`FormatSettings`, nicht `DayOfWeek`); Kalender ab Delphi XE2 testen; Zeitzonen nur als Anzeige.
  - Toasts: eigene Top-Level-Fenster ohne Aktivierung (wie das Popup), Mehrfach-Monitor, nie über Vollbild-Anwendungen.

## Phase 8: Modernes Design (Fluent / Windows 11)
1. **Design-Tokens:** `TPPGAppearance` bekommt semantische Farben.
   - Farben: Accent, AccentHover, Surface, SurfaceAlt, Stroke, TextPrimary, TextSecondary, Danger, Warning, Success.
   - Dazu Radius S/M/L, Abstände und Motion-Dauern.
   - Alle Controls lesen ausschließlich Tokens. Das ist die Grundlage für jedes weitere Preset.
2. **Preset `Fluent11`:**
   - Windows-11-Look: 4/8 px Radius, 1 px Stroke mit Elevation-Kante, Akzentfarbe aus dem System (`DwmGetColorizationColor` bzw. `UISettings`), Segoe UI Variable, falls vorhanden.
   - Fokus nach Windows 11: doppelter Ring, außen schwarz, innen weiß.
3. **Dark Mode ohne VCL-Style:** `TPPGStyleManager.ThemeMode` = tmLight/tmDark/tmSystem.
   - Folgt `AppsUseLightTheme` aus der Registry, reagiert auf `WM_SETTINGCHANGE`/`ImmersiveColorSet`.
   - Titelleiste dunkel über `DWMWA_USE_IMMERSIVE_DARK_MODE`.
4. **Flächen:** `TPPGForm`-Helfer (optional) für Mica/Acrylic über `DWMWA_SYSTEMBACKDROP_TYPE` ab Windows 11 22H2, sonst einfarbiger Fallback.
   - **Fallstrick:** Mica verlangt transparente Client-Flächen. Alle Controls brauchen ParentBackground-Korrektheit, und der GDI-Text braucht Alpha (DrawText auf Mica wird sonst schwarz). Deshalb ist das ein späterer Schritt mit eigenem Prototyp.
5. **Motion-Katalog:**
   - Einheitliche Easing-Kurven (Fluent: Decelerate 0,0,0,1) und Dauern (Fast 83 ms, Normal 167 ms, Slow 250 ms) im Animator.
   - `RespectSystemSettings` gilt überall, „Animationen reduzieren“ wird respektiert.
6. **Icons:** Segoe Fluent Icons bzw. Segoe MDL2 als eingebaute Glyphenquelle (`TPPGIconFont`), skaliert ohne ImageList; Fallback bei fehlender Schrift auf die vorhandenen Polylinien-Glyphen.

## Phase 9: Profi-Qualität und Vertrieb
- **Designer:**
  - Palettensymbole (`.dcr`, 16/24/32 px).
  - Collection-Editoren für Items und Spalten.
  - Appearance-Editor mit Live-Vorschau.
  - Galerie „Preset anwenden“ für alle Controls des Formulars.
  - Smart-Tags (Verben) je Control.
- **Datenbindung:** `TPPGDBEdit`, `TPPGDBComboBox`, `TPPGDBLookupComboBox`, `TPPGDBGrid` über `TDataLink`.
  - **Fallstrick:** `TFieldDataLink`-Ereignisse kommen auch während `Paint`. Darin nur Zustand cachen, nie zeichnen.
  - Optional LiveBindings.
- **UI Automation** nativ ab 10.x (`IRawElementProviderSimple`) für Grid und Tree, weil MSAA dort an Grenzen stößt (Tabellenmuster, Zeilen und Spalten).
- **Lokalisierung:** alle Texte in resourcestrings (ist so), Beispiel-Übersetzung de/en, RTL-Tests.
- **Kompatibilität:** echter XE2- und 10.x-Build, CI-Skript (`build.ps1 -All`), Testlauf unter 100/150/200 % DPI.
- **Doku und Demo:** Demo als Katalog mit Suche (nutzt NavigationView), Hilfe pro Control (Markdown → HTML), Migrationsleitfaden „TMS/VCL → PPGlow“ mit DFM-Ersetzungstabelle.

---

## Architektur: Best Practices (für alle Phasen verbindlich)
| Regel | Warum |
|---|---|
| Controls zeichnen nur über Renderer-Interfaces, neue Optik = neues Interface mit Default in `TPPGRendererBase` | Presets bleiben austauschbar (OCP), Interface Segregation |
| Daten über `IPPGItemSource`, Auswahl über `TPPGSelection`, Scrollen über `TPPGCustomScrollControl` | einmal gelöst, überall gleich getestet |
| Popups ausschließlich über `TPPGPopupWindow` | Fokus, Capture und Multi-Monitor nur an einer Stelle |
| Paint ohne Nachrichten, Layout außerhalb von Paint cachen | `FreeMemoryContexts`-Falle, Geschwindigkeit |
| Kein Timer pro Control, nur der Animator | Handle-Verbrauch, Testbarkeit |
| Native Texteingabe (Edit) wiederverwenden, nie eigene Caret-Logik | IME, Undo, Screenreader |
| Jede Komponente: DFM-Roundtrip-Test, Pixeltest beide Presets plus GDI, Leak-Test, Barrierefreiheits-Test | Qualitätsvorsprung gegenüber TMS halten |
| Code setzt Werte ohne Ereignisse, Anwender-Aktion mit Ereignissen (VCL-Semantik) | Migrationssicherheit |

## Fallstricke (bekannt und für die neuen Phasen erwartet)
- **Bereits gelernt (Architektur.md):**
  - `ClientRect` erzeugt Handles.
  - Capture-Freigabe in `WMLButtonUp`.
  - `LoWord` bei negativen Koordinaten.
  - `CM_CONTROLLISTCHANGE` kommt zu früh.
  - GDI ohne Alpha.
  - Protected-Zugriff auf fremde Instanzen.
  - PowerShell verliert Backslashes in Perl-Einzeilern.
- **Neu zu erwarten:**
  - Weiches Scrollen mit `ScrollWindowEx` und Overlays: lieber komplett neu zeichnen (Puffer ist ohnehin da).
  - Variable Zeilenhöhen und DPI-Wechsel: Höhen-Cache bei `CM_FONTCHANGED`/DPI verwerfen.
  - Drag & Drop: OLE-Drag (`IDropTarget`) erst später; zuerst VCL-Drag.
  - Grid und Zelleditoren: Das Scrollen während des Editierens muss den Editor mitbewegen oder schließen.
  - Toast-Fenster: `WS_EX_NOACTIVATE`, Vollbild-Erkennung (`SHQueryUserNotificationState`).
  - Dark Mode: Systemfarben (`clWindow` usw.) sind im Dark Mode weiter hell. Nur Tokens nutzen, nie `clXxx` direkt.
  - Mica: GDI-Text auf Glas wird schwarz. GDI+-Text oder DirectWrite nötig, also zuerst ein Prototyp.
  - Große Datenmengen: `TStrings` als Speicher ist zu langsam; virtueller Modus ist Pflicht.

## Reihenfolge und Umfang (Vorschlag)
| Phase | Inhalt | Grobe Größe |
|---|---|---|
| 5 | Scroll-Basis, Item-Modell, Virtualisierung, Markup, Auswahl, Benchmark | groß, ohne sichtbare neue Controls |
| 6a | ListBox, CheckListBox, ComboBox-Ausbau | mittel |
| 6b | TreeView | groß |
| 6c | Grid | sehr groß |
| 7 | Navigation, Datum/Zeit, Rückmeldung, kleinere Controls | groß, gut teilbar |
| 8 | Tokens, Fluent11, Dark Mode, Motion, Icons (Mica als Prototyp) | mittel bis groß |
| 9 | Designer, DB, UIA, Kompatibilität, Doku | fortlaufend |

- **Alternative Reihenfolge:** Phase 8 (Tokens und Dark Mode) vor Phase 6. Vorteil: Alle neuen Controls entstehen gleich token-basiert, und das Nachrüsten von 21 Controls passiert nur einmal. **Empfehlung: 8.1–8.3 (Tokens, Fluent11, Dark) direkt nach Phase 5.**
- Jede Phase bekommt vor dem Start einen eigenen Detailplan (wie Phase 4) und endet mit Bericht und OK.

## Verifikation (je Phase)
```powershell
powershell -ExecutionPolicy Bypass -File Build\build.ps1 -Only Delphi13 -Projects Runtime,Design,Tests,Demo
powershell -ExecutionPolicy Bypass -File Build\build.ps1 -Only Delphi13 -Projects Runtime -Platform Win64
Tests\PPGlowTests.exe                                   # Exit 0
Demo\PPGlowDemo.exe /screenshot <scratch>\pN.png /page n [/gdi] [/style Windows10Dark]
Tests\Bench\PPGlowBench.exe                             # ab Phase 5: Zeiten gegen Vorgabe
```
- Ergänzend manuell durch den User nach `install.ps1` (IDE geschlossen):
  - Designer
  - Narrator
  - zweiter Monitor mit anderer DPI
  - Dark Mode umschalten
