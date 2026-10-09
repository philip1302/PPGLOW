# Phase 18 – Detailplan: Controls mit echtem Mehrwert

*Stand 08.10.2026. Teil von `Docs\Roadmap3.md`. **Neu gefasst nach der Kritik des Users („was bringt uns das an Mehrwert, klonen wir hier einfach nur VCL-Komponenten?“), freigegeben mit „Nach Mehrwert umbauen“.** Der frühere Plan (reine VCL-Nachbauten) steht in der git-Historie (8fdce8e).*

## Context
Der Detailplan `Docs\Phase18-Plan.md` (Commit 8fdce8e) baut vor allem VCL-Controls nach (RadioGroup, ListView, DBText, DBListBox, …). Der User fragt zu Recht nach dem Mehrwert. Reine Nachbauten helfen nur bei Umstellungen, sie können nichts, was die VCL nicht kann. Er hat entschieden: **Phase 18 wird nach Mehrwert umgebaut.**

**Regel:** Ein neues Control kommt nur, wenn es mindestens zwei Dinge kann, die VCL und TMS nicht können. Es bleibt im DFM so kompatibel zum VCL-Vorbild, dass `migrate.ps1` es trotzdem einsetzen kann. Reine Nachbauten (DBText, DBListBox, DBLookupListBox, DBSpinEdit, DBToggleSwitch, eine 1:1-ListView) werden zurückgestellt, bis eine Inventur eines echten Projekts (`inventory.ps1`) sie verlangt.

## Neuer Umfang

| Teil | Inhalt | Mehrwert gegenüber VCL/TMS |
|---|---|---|
| 18a | `TPPGRadioGroup`/`TPPGCheckGroup` mit `ChoiceStyle` | Segment-Umschalter, Auswahl-Kacheln mit Symbol und Beschreibung, Spalten passen sich der Breite an |
| 18b | `TPPGTileView` (Kachel-/Karten-/Galerie-Ansicht) | Explorer-/Galerie-Ansicht mit Kartenvorlage, Suche/Filter mit Hervorhebung, Zoom, virtuell, Export/Druck geschenkt |
| 18c | `TPPGDBNavigator` | Zähler „12 von 340“, Suchfeld, Schnellfilter, Überlauf bei wenig Platz |
| 18d | `TPPGPanel.AutoScroll` + `TPPGScrollBox` (dünne Ableitung) | weiches Scrollen, Overlay-Leisten, Rad über Kind-Controls, `ScrollInView` für die Tour |
| 18e | Migration, Demo, Doku, Prüfung | – |

`TPPGDBRadioGroup` kommt mit, weil er auf 18a fast nichts kostet.

## 18a – Auswahlgruppe (`PPG.RadioGroup`)
- DFM wie `TRadioGroup` (`Items`, `ItemIndex`, `Columns`, `Caption`, `OnClick`), damit die Migration 1:1 bleibt.
- **`ChoiceStyle`:**
  - `csList`: Kreise wie VCL, aber selbst gezeichnet
  - `csSegmented`: Umschalter in einer Zeile, gleitender Akzent-Indikator über den vorhandenen Animator und `TPPGEasing`
  - `csCards`: Kacheln mit Symbol, Titel und Beschreibung, gewählte Kachel mit Akzentrahmen
- **`ItemsEx`** (Collection): `Caption`, `Description`, `ImageIndex`/`ImageName`, `Enabled`, `Hint`, `Value`. `Items` bleibt als einfache Sicht.
- **`Columns = 0`:** Spalten passen sich der Breite an (Umbruch wie bei Kacheln).
- `ValidationState` wie die Felder (Pflichtauswahl rot markieren), Vorbereitung für den Validator aus Phase 19.
- `TPPGCheckGroup`: dieselbe Basis mit Mehrfachauswahl, `Checked[i]`, `AllowGrayed`, `Value` als Kommaliste.
- Wiederverwenden:
  - Rahmen und Plakette aus `TPPGGroupBox`/`TPPGCustomContainer` (`Source\Controls\PPG.Controls.Container.pas`)
  - Kreise und Kästchen über `IPPGIndicatorRenderer`, Text mit `PPG.Markup`
  - Element-Stile (`PPG.ElementStyle`), Screenreader-Kinder (`IPPGAccessibleChildren`)
  - Tastatur wie VCL (Pfeile innerhalb der Gruppe)

## 18b – Kachelansicht `TPPGTileView` (`PPG.TileView`)
Statt die `TListView` zu klonen: Deren Detailansicht kann das Grid schon besser. Neu ist eine Ansicht, die es in VCL und TMS so nicht gibt.
- **Ansichten** (`TileStyle`):
  - `tsIcons`: große Symbole mit Beschriftung darunter (Explorer)
  - `tsTiles`: Symbol links, Titel und zwei Detailzeilen
  - `tsCards`: Karte mit Vorschaubild, Titel, Untertitel, Plakette und Badge
- **Daten:** `Items` (Collection) oder virtuell über `IPPGItemSource` (`OnGetItem`) für große Mengen, Gruppen mit Kopf (klappbar)
- **Suche/Filter:** `FilterText` filtert und hebt Treffer im Text per Markup hervor, `OnFilterItem` für eigene Regeln
- **Bedienung:**
  - Zoom mit Strg+Rad
  - Mehrfachauswahl (Windows-Semantik aus `TPPGSelection`), Gummiband-Auswahl
  - Tastatur in zwei Dimensionen, Tippsuche, F2 benennt um
  - Ziehen
- **Bilder:** `Images`/`ImageName` oder `OnGetPicture` (Vorschaubild je Eintrag, zwischengespeichert)
- **Ausgabe:** `IPPGTableSource` mit Titel und Detailfeldern. Damit gehen xlsx, HTML und Druck sofort über die Phase-17-Bausteine.
- Wiederverwenden:
  - `TPPGCustomItemList`/`TPPGCustomScrollControl` (Overlay-Scroll, weiches Scrollen)
  - `TPPGItemPainter`/`IPPGItemRenderer`, `TPPGSelection`, `IPPGItemSource`, `PPG.Markup`, Badge-Zeichnung aus `PPG.Feedback`
  - UIA-Muster der ListBox
- **Migration:** `TListView` mit `vsIcon`/`vsSmallIcon` → `TPPGTileView` nur mit Meldung (die API unterscheidet sich). `vsReport` → Hinweis auf `TPPGGrid`. Keine automatische 1:1-Umstellung.

## 18c – `TPPGDBNavigator` (`PPG.DB.Navigator`, Paket `PPGlowDBR`)
- DFM wie `TDBNavigator` (`DataSource`, `VisibleButtons`, `Hints`, `ConfirmDelete`, `Flat`, `BeforeAction`, `OnClick` mit `TNavigateBtn`)
- **Mehrwert:**
  - `ShowCounter`: „Datensatz 12 von 340“ bzw. „neu“, auch für Screenreader
  - `ShowSearch`: Suchfeld mit `SearchField`, `Locate` mit Teiltreffer, Enter springt zum nächsten Treffer
  - `ShowFilter`: Schnellfilter auf das Suchfeld (`DataSet.Filter`/`OnFilterRecord`) mit Zurücksetzen
  - Überlaufmenü bei wenig Platz
  - Tastenkürzel (Strg+Pos1/Ende, Einfg, Strg+Entf)
- Wiederverwenden: Knopf-Zeichnung und Überlauf wie `TPPGToolBar`, Suchfeld aus `TPPGSearchEdit`, `TDataLink`-Muster aus `PPG.DB.Controls`, Fluent-Symbole (`PPG.IconFont`)

## 18d – Scrollen in Containern
- `TPPGPanel.AutoScroll` und `HorzScrollBar`/`VertScrollBar` wie `TScrollingWinControl`:
  - echte Kind-Fenster per `ScrollWindowEx(SW_SCROLLCHILDREN)`
  - Overlay-Leisten in PPGlow-Optik, weiches Scrollen, Mausrad über Kind-Controls (Verteiler `PPG.AppHooks`)
  - `ScrollInView`
- `TPPGScrollBox = class(TPPGPanel)` mit `AutoScroll = True` und ohne Rahmen als Vorgabe, DFM wie `TScrollBox`
- Risiko: DPI-Wechsel und VCL-Styles. Prüfung mit Demo-Karte mit vielen Feldern.

## 18e – Migration, Demo, Doku, Prüfung
- **`migrate.ps1`:**
  - `TRadioGroup`/`TcxRadioGroup`→`TPPGRadioGroup`, `TcxCheckGroup`→`TPPGCheckGroup`, `TDBRadioGroup`→`TPPGDBRadioGroup`, `TDBNavigator`→`TPPGDBNavigator`, `TScrollBox`→`TPPGScrollBox`
  - `TListView`: nur melden. Selbsttest-Fixtures ergänzen.
- **Demo:**
  - Formularseite: Auswahlgruppen in allen drei Stilen
  - Neue Seite „Kacheln“ (Dateien/Produkte mit Suche, Zoom, virtuell 100 000)
  - Datenbankseite: Navigator mit Zähler/Suche/Filter
  - ScrollBox-Karte; Selbsttest-Szenarien
- **Tests:**
  - je Control Lebenszyklus, Paint GDI+/GDI, Verhalten, Streaming, Sichtgalerie, UIA
  - Gegenprobe mit `TRadioGroup`/`TDBNavigator` (gleiche DFM lädt, gleiche Ereignisse)
- **Doku:**
  - `Docs\Phase18-Plan.md` durch diesen Plan ersetzen
  - `Docs\Roadmap3.md` anpassen (Phase 18 „mit Mehrwert“, zurückgestellte Nachbauten)
  - Hilfe-Notizen, Property-Referenz, `make-icons.ps1`, `Docs\Migration.md`, `NAECHSTE-SCHRITTE.md`
- Neue Units in alle Projektlisten eintragen (Regel PROJECT), Texte nach `PPG.Consts` und `Lang\PPGlow.de.txt` (Regel LANG).

## Reihenfolge
18a → 18b → 18c → 18d → 18e, Bericht nach 18e. Zwischenstände in `NAECHSTE-SCHRITTE.md`.

## Verifikation
- `Build\check-rules.ps1`, `build.ps1 -Projects Runtime,Design,DBRuntime,DBDesign,Tests,Demo` (Win32 und Win64)
- `Tests\PPGlowTests.exe` (0 = grün), `/leaks`, Benchmark für `TPPGTileView` (100 000 virtuell, Scrollen und Filtern)
- `Demo\PPGlowDemo.exe /selftest datei.txt` sowie Screenshots der neuen Seiten (vergrößert ansehen), Narrator-Stichprobe
- `migrate.ps1 -SelfTest` mit den neuen Fixtures

## Umsetzung (09.10.2026)
Freigegeben mit „Nach Mehrwert umbauen“ und „weiter“. Umgesetzt in der Reihenfolge 18a → 18e, je Teil ein Commit.

- **18a** (`PPG.RadioGroup`): `TPPGCustomChoiceGroup` auf der GroupBox-Basis, `TPPGRadioGroup` und `TPPGCheckGroup`. `ChoiceStyle` `csList`/`csSegmented`/`csCards`, `ItemsEx` (`TPPGChoiceItem`: `Caption`, `Description`, `ImageIndex`, `Icon`, `Enabled`, `Hint`, `Value`, `State`), `Items` als Sicht darauf, `Columns = 0` nach Breite, `ShowFrame`, `ValidationState`, `ItemStyle`/`SelectedStyle`, `AllowGrayed`, `Value` (CheckGroup: Kommaliste). Liste spaltenweise wie die VCL, Segmente und Kacheln zeilenweise.
- **18b** (`PPG.TileView`): `TPPGTileView` mit `tsIcons`/`tsTiles`/`tsCards`, `Zoom` 50–200 (Strg+Rad), `FilterText` mit Hervorhebung, `OnFilterItem`, Gruppen mit klappbarem Kopf, virtuell (`OwnerData`, `ItemCount`, `OnGetItem`), Mehrfachauswahl mit Gummiband, Kästchen, F2/`EditItem`, Tippsuche, `OnGetItemIcon`/`OnGetPicture`, `IPPGTableSource` (xlsx, CSV, HTML, Druck). Auswahl und Ereignisse arbeiten mit Datenindizes, auch bei aktivem Filter.
- **18c** (`PPG.DB.Navigator`, Paket PPGlowDBR): `TPPGDBNavigator` (DFM wie `TDBNavigator`), Zähler, Suchfeld (`FindText`), Schnellfilter (`SetQuickFilter`, verkettet ein vorhandenes `OnFilterRecord`), Überlaufmenü, Tastenkürzel. `nbApplyUpdates`/`nbCancelUpdates` über `IDataSetCommandSupport`. Dazu `TPPGDBRadioGroup` (`Values`, `ReadOnly`).
- **18d** (`PPG.Panel`): `TPPGPanel.AutoScroll`, `HorzScrollBar`/`VertScrollBar` (`TPPGPanelScrollBar`: `Visible`, `Range`, `Increment`, `Position`, `Tracking`, `Smooth`), `ScrollTo`, `ScrollInView`, `ContentSize`. `TPPGScrollBox` (AutoScroll an, ohne Beschriftung, `BorderStyle`). Jede Demo-Seite liegt jetzt in einer `TPPGScrollBox` (Schalter `/scroll`).
- **18e:**
  - `migrate.ps1`: `TRadioGroup`/`TcxRadioGroup`, `TcxCheckGroup`, `TDBRadioGroup`, `TDBNavigator` (`Kind` entfällt), `TScrollBox`; `TListView` wird nur gemeldet. Neues Fixture `Build\migrate-tests\Unit3`, Selbsttest 6/6.
  - Doku: Hilfe-Notizen der sechs neuen Controls, Property-Referenz `Docs\Controls\props\70-auswahl-kacheln.txt` (ohne Beschreibung: 0), `Docs\Migration.md`, Architektur. `docs-parser.ps1` erkennt jetzt Felder `array of record` (vorher endete die Klasse dort, Properties fehlten).
  - Benchmark: Kachelansicht virtuell 100 000, 300 × scrollen und zeichnen 1,3 s, 20 × filtern 1,1 s (Vorgabe je 3 s).
- **Prüfung:** 61 neue Tests (`Tests\PPG.Tests.Phase18.pas`), insgesamt 1360 Tests Win32 und Win64, Leak-Lauf Win32 und Win64 grün (kein Zuwachs), Demo-Selbsttest 163/163, Benchmark eingehalten, Regel-Prüfer ohne Verstöße.

**Abweichungen:**
- Auswahlgruppe: kein `ImageName` je Eintrag, dafür `Icon` (Zeichen der Symbolschrift) neben `ImageIndex`.
- Kachelansicht: kein eigenes Umsortieren per Ziehen, nur `DragMode` der VCL.
- Scrollen: statt `ScrollWindowEx` werden die Kind-Fenster verschoben (Neuzeichnen per `WM_SETREDRAW` gebündelt). Die Leisten liegen in einem schmalen Streifen am Rand, weil sich echte Kind-Fenster nicht überlagern lassen. Das Mausrad über Kind-Controls kommt über die Weitergabe von Windows an, nicht über `PPG.AppHooks`.
- Keine Narrator-Stichprobe; die Screenreader-Kinder sind per Test geprüft (`AccessibleChildren`, `AccessibleButtons`).

**Offen:** `ImageName` für Auswahl-Einträge, Umsortieren per Ziehen in der Kachelansicht, XE2-Lauf. Unter XE2 gibt es `nbApplyUpdates`/`nbCancelUpdates` und `IDataSetCommandSupport` noch nicht; der Navigator lässt sie dort über den neuen Schalter `PPG_HAS_DATASETCOMMANDS` (`PPG.inc`, ab XE3) weg. Nicht kompiliert, weil hier nur Delphi 13 vorhanden ist.
