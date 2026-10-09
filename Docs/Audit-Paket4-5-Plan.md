# Audit-Pakete 4 und 5 – Detailplan

*Stand 09.10.2026. **Vom User am 09.10.2026 freigegeben (Entscheidungen unten).** Grundlage: `Docs\Audit-Plan.md` (Pakete 4, 5 und 9a). Alle Befunde wurden am 09.10.2026 gegen den aktuellen Code (nach Phase 20) neu geprüft; Zeilennummern unten sind aktuell.*

## Context
Das Audit vom 08.10.2026 hat für die DB-Controls (Paket 4) und für Properties, Objektinspektor und Benennung (Paket 5) zusammen rund 140 Befunde gemeldet. Die Nachprüfung zeigt:
- **Paket 4:** von 18 Befunden 14 offen, 4 teilweise erledigt (Esc → `Reset` gibt es inzwischen in 6 von 10 Controls, `First` postet keine offene Bearbeitung mehr, `ReadOnly` gibt es über die Aufklapp-Basis, Pflichtfelder prüft der Validator aus Phase 19).
- **Paket 5a/5b:** von 39 Zeilen 2 erledigt (Gauge/KpiTile-Formate, Planer-Setter), 5 teilweise, 32 offen.
- **5c:** rund 33 echte Umbenennungen, dazu Aufzählungswerte und Vorgaben; die alten Namen kommen etwa 700-mal vor (420 Source, 130 Tests, 30 Demo, 110 Doku).
- **5d:** rund 450–650 fehlende `property X;`-Zeilen in etwa 45 Controls; alles ist in `TControl`/`TWinControl` schon da, es muss nur veröffentlicht werden.

Warum jetzt: Diese Befunde treffen genau die Umstellung eines echten Projekts. DB-Felder ohne `MaxLength`, Lookup ohne Mehrfachschlüssel, fehlende `OnClick`/`OnKeyDown` und Properties, die nichts bewirken, fallen beim Kunden sofort auf.

## Paket 4 – DB-Controls

### 4a Gemeinsame DB-Bindung (aus 9a, vor den Fixes)
Heute wiederholen 11 DB-Controls je 13–18 fast gleiche Methoden (Create/Destroy/Loaded/Notification, DataField/DataSource/Field/ReadOnly, `CM_GETDATALINK`, `CM_EXIT`, Execute-/UpdateAction, UpdateEditable, EditingChange, Esc). `TPPGDBValueBinding` (`PPG.DB.Fields.pas:35`) nutzen nur die 5 Felder aus Phase 12; die 5 Controls in `PPG.DB.Controls.pas` und `TPPGDBRadioGroup` (`PPG.DB.Navigator.pas`) haben eigene Kopien.
- `TPPGDBValueBinding` übernimmt alle gemeinsamen Teile, auch `ExecuteAction`/`UpdateAction`, `CMExit` (Commit), Esc (`Reset`), `UpdateEditable` und die Benachrichtigung bei freigegebener DataSource.
- Die 11 Controls behalten ihre published-Schnittstelle (DFM unverändert) und reichen nur noch weiter. Erwartung: rund 600 Zeilen weniger.
- Absicherung wie bei 20e: zuerst festhaltende Tests je Control (Lesen, Schreiben, Esc, ReadOnly, Exit, DataSource frei), gegen den alten Code grün, dann der Umbau.

### 4b Fehler und Lücken
| # | Stelle | Fix |
|---|---|---|
| 1 | `PPG.DB.Controls.pas:450` DBEdit | `MaxLength := Field.Size` (Text-Felder) und `EditMask := Field.EditMask` beim Binden; eigene Werte des Anwenders haben Vorrang. |
| 2 | `PPG.DB.Fields.pas:469`, `PPG.NumberEdit.pas:904` DBNumberEdit | `NumberKind`/`Decimals` aus Feldtyp und `Precision`/`Size` (wenn nicht ausdrücklich gesetzt); BCD/FMTBCD über `AsBCD`/`AsCurrency`, `ftLargeint` über `AsLargeInt`. |
| 3 | `PPG.DB.Lookup.pas:200` | Mehrfachschlüssel `'A;B'` über `FieldValues[]`/VarArray; `NullValueKey` (wie TDBLookupComboBox); `fkLookup`-Feld als DataField → Schlüsselfelder des Lookup-Felds verwenden. |
| 4 | `PPG.DB.Grid.pas:1249` | Lookup-Felder: Auswahlliste aus `LookupDataSet` als Editor; unbekannter Text wird abgelehnt (Fehlerzustand), nie still Null. |
| 5 | `PPG.DB.Grid.pas:1263` | `FDataLink.Edit` beim ersten Tastendruck im Editor (wie TDBGrid). |
| 6 | `PPG.DB.Controls.pas:1272` DBDatePicker | Null ohne `ShowCheckbox`: leeres Feld (TextHint) statt altem Datum. |
| 7 | `PPG.DB.Fields.pas` | `ExecuteAction`/`UpdateAction` (über 4a). |
| 8 | `PPG.DB.Lookup.pas:268` | `UpdateEditable` in DataChange/ActiveChange (über 4a). |
| 9 | `PPG.DB.Controls.pas:1139` DBComboBox/Lookup | `CanDropDown` = `CanModify`, Tippsuche und Pfeile gesperrt, wenn nicht änderbar (kein Zurückspringen). Die normale ComboBox bleibt wie in 20e entschieden. |
| 10 | `PPG.DB.Lookup.pas:100` | Liste nur neu lesen, wenn sich die Listenmenge ändert (`deDataSetChange`/Aktivierung), nicht bei jedem Scrollen; Lesen in `PPGDBBeginRead`. |
| 11 | DatePicker, ColorPicker, CheckCombo, TagEdit | Esc → `Reset` (über 4a). |
| 12 | `PPG.DB.Grid.pas:596` | Persistente Spalten übernehmen `Field.Alignment`, solange die Spalte nichts setzt. Pflichtfelder: optionale Markierung `ShowRequired` an DB-Feldern (Sternchen im TextHint-Bereich bzw. Spaltenkopf), Vorgabe aus. |
| 13 | `PPG.DB.Chart.pas:393/429` | Null = Lücke in der Linie (braucht NaN-Lücken im Chart, offener Rest aus Paket 2); Sprung zum Datensatz über Bookmarks statt `RecNo`. |
| 14 | `PPG.DB.Kanban.pas:97` | `VirtualCardHeight`, `OnKeyDown`, `OnScroll` veröffentlichen. |
| 15 | `PPG.DB.Grid.pas:186/835` | `ExportMaxRecords` mit `PPGCheckRange`; `GroupIndex` der DB-Spalten nicht veröffentlichen (wirkt nicht). |

### 4c Designer
- `PPG.DB.Chart.pas:367`, `PPG.Chart.Series.pas:144/669`: Gebundene Serien speichern weder Werte noch Titel in die DFM (`stored`-Funktion fragt den Besitzer).
- `PPG.Reg.pas:984`: `RequiresUnits` für Grid/DBGrid ergänzt `PPG.Grid.Styles` und `Vcl.Menus`.
- `PPG.DB.Reg.pas:214`: Feldauswahl für `TPPGDBChart.ValueFields` (Liste mit `;`) und `TPPGDBGridColumn.FooterField`; `FooterField` bekommt einen Setter mit `Changed`.

## Paket 5 – Properties, Objektinspektor, Benennung

### 5a Streaming (alle offen außer Gauge)
- Leerer Text wird nicht gespeichert: `CheckComboBox.DisplayDelimiter` (`:128`), `TagEdit.Delimiters` (`:155`) → `stored`-Funktion gegen die Vorgabe.
- `Print.FooterText` (`PPG.Print.pas:114`): übersetzte Vorgabe nicht in die DFM (`stored`-Funktion wie bei Gauge, Merker „bewusst leer“).
- `PasswordEdit.Text` (`:125`): `stored False` (kein Klartext in der DFM).
- `Expander.ExpandedHeight` (`:77`): `stored`-Funktion statt `default 0`.
- `ComboBox.Items` (`:211`): `stored not UseItemsEx`.
- `Min` (`PPG.Controls.Range.pas:57`): `default 0` in ProgressBar und TrackBar.
- `HintManager` (`PPG.Hints.pas:552`): `Apply` erst in `Loaded` bzw. bei Laufzeit-Erzeugung nach `AfterConstruction`.
- `Down` vor `GroupIndex` (`Ribbon.Items:161`, `ToolBar:111`): `GroupIndex`-Setter und Abgleich in `Loaded` (nur ein gedrückter Knopf je Gruppe).
- Ribbon-Backstage aus der DFM in `Loaded` verstecken (`PPG.Ribbon.pas:1420`).
- `Preset` an Nicht-Controls (Notifications, Hints, TeachingTip, Dialogs, Menus): gemeinsamer geprüfter Setter wie `TPPGCustomControl.SetPreset`.
- `TPPGCheckBox.Checked` bleibt public (gespeichert wird `State`, wie gewollt) – kein Fix.

### 5b Wirkung und Setter
- **Ohne Wirkung → umsetzen:** LinkLabel `OnClick` (feuert bei Klick auf das Label, `OnLinkClick` bleibt für Links), `CustomHint.Style` (Standard/Balloon wie VCL), `WizardPage.Description` (Unterzeile im Kopf), `MenuBar.MenuStyles` auch für die Leiste, `StatusPanel.Hint` als Tooltip (`CM_HINTSHOW`), Badge/ProgressRing/Rating/Splitter lesen die übrigen Appearance-Werte wie InfoBar.
- **Ohne Wirkung → klarstellen:** `ChartAxis.Kind` bei Y-Achsen wird im Setter abgelehnt (Warnung) und ist dokumentiert; `TaskDialog.OnNavigated` feuert beim Wechsel der Seite (falls die eigene Ausführung Seiten kennt), sonst aus dem published-Abschnitt.
- **Setter ohne Neuzeichnen:** ColumnComboBox (`Columns`, `ColumnDelimiter`, `KeyColumn`, `DisplayColumn`), Druck-Optionen in `PPG.Print`/`PPG.Grid.Print` (PageCount neu), ColorPicker (`ShowThemeColors`, `DefaultColorColor`), `Grid.DefaultDrawing`, `Notifications.Position`, `NavItem.PageIndex`.
- **Setter ohne Gleichheitsprüfung:** die 20 Setter aus der Nachprüfung (Badge, ProgressRing, Rating, Gauge, Sparkline, ChartSeries, DBChart, ColorPicker, CheckComboBox, NumberEdit).
- **Still geklemmt → `PPGCheckRange`:** ProgressRing.Value, NavItem.BadgeCount, StatusPanel Width/Progress/BadgeCount, FileEdit.FilterIndex, CheckComboBox.FilterThreshold, TagEdit.Delimiter (`#0` abgelehnt).
- **Zustand:** Kanban `SelectedCard` über `SetFocusHit` (Scroll, DB-Abgleich, ohne Ereignis); InfoBar `Visible`/`IsOpen` gleich halten (`CM_VISIBLECHANGED`); SpinEdit `ReadOnly` → `UpdateColors`; LinkLabel lässt den Cursor des Anwenders stehen (`WM_SETCURSOR` statt `Cursor :=`); `CompactModeThresholdWidth` mit Setter und Neu-Layout.
- **Designer:** `ColumnComboBox.ItemIndex` veröffentlichen; NavigationView bekommt `SelectedIndex` (published, Startauswahl im Designer).
- **Objektinspektor:** Kategorien („PPGlow“ für Optik, dazu Verhalten/Daten), `GetDisplayName` für `TPPGGaugeRange` und `TPPGChartReferenceLine`, ImageIndex-Editor für Collection-Items (NavItem, ToolItem, RibbonItem, StatusPanel), `ImageName` (ab 10.4) für ToolItem, NavItem, TabSheet, RibbonItem, StatusPanel.
- `Panel.BevelInner`/`BevelOuter` mit TPanel-Vorgaben (`bvNone`/`bvRaised`); bei runden Ecken wird der 3D-Rahmen nicht gezeichnet.

### 5c Einheitliche Benennung (ganze Audit-Tabelle, ohne Aliase)
Die Suite ist in keinem Projekt im Einsatz (Entscheidung 2): umbenannt wird **ohne Aliase**, alte Namen verschwinden. VCL-Namen bleiben nur, wo die Audit-Tabelle es vorsieht (`Position` bei ProgressBar/TrackBar, `ToolTips` beim TreeView, `ShowCaption` beim Panel, `ShowCaptions` bei der ToolBar, `OnDrawItem`/`OnDrawCell`/`OnDrawTab`/`OnDrawPanel` als VCL-Kompatibilität, `OnClickCheck` an der CheckListBox, `TabVisible`).

| Konzept | Heute | Neu |
|---|---|---|
| Stil-Gruppe | `ListStyles`, `CalendarStyles` (Calendar, DatePicker), `ChartStyles`, `KanbanStyles`, `PlannerStyles`, `NavStyles`, `TabStyles`, `MenuStyles` (MenuBar, PopupMenu), `BarStyle` (InfoBar, StatusBar) | `Styles` (`BarStyle` → `Style`, eine Fläche) |
| Sichtbarkeit | TrackBar `SliderVisible`; Tab-/PageControl `ShowCloseButtons` | `ShowSlider`; `ShowCloseButton` |
| Wertebereich | NumberEdit und SpinEdit `MinValue`/`MaxValue`; Rating `MaxValue`; ProgressRing nur `Value` | `Min`/`Max`/`Value`; Rating `Max`; ProgressRing bekommt `Min`/`Max` |
| Art | NumberEdit `NumberKind`, KpiTile `SparklineKind` | `Kind` |
| Animation | NotificationCenter `Animations: Boolean` | `Animation: TPPGAnimationSettings` wie alle |
| Farben | Badge `BadgeColor`, GaugeRange `RangeColor` + `CustomColor`; „nicht gesetzt“ mal `clNone` | Badge `Kind` (`TPPGBadgeKind`: `bkAccent`, `bkSuccess`, `bkWarning`, `bkError`, `bkNeutral`), GaugeRange `Kind` (`TPPGGaugeRangeKind`, gleiche Reihenfolge, `grcDanger` → `grkError`, dazu `grkCustom`) + `Color`; „nicht gesetzt“ überall `clDefault` (Gauge, Grid-Zellstil, Kanban-Karte/-Spalte, Ribbon `ContextColor`) |
| Trenner | TagEdit `Delimiters` (Eingabetasten), ColumnComboBox `ColumnDelimiter` | `InputDelimiters`, `Delimiter` (Wert-Trenner überall `Delimiter`, Anzeige `DisplayDelimiter`) |
| Offen-Zustand | InfoBar `IsOpen`/`IsClosable` | `Open`/`ShowCloseButton` |
| Auswahlwechsel | Kanban, Planer, NavigationView `OnSelectionChange`; Ribbon `OnTabChange`/`OnTabChanging`; Wizard `OnPageChanged` | `OnChange` (Hauptauswahl), Ribbon `OnChange`/`OnChanging` |
| Zeitform | Planer `OnAppointmentChanged`, Grid `OnTopLeftChanged` | `OnAppointmentChange`, `OnTopLeftChange` |
| Eintrag-Klick | NavigationView `OnItemInvoked` | `OnItemClick` |
| Eigenes Zeichnen | Ribbon `OnDrawGalleryItem` | `OnCustomDrawGalleryItem` |
| Schließ-Abfrage | Tab-/PageControl `OnCloseQuery` | `OnClosing` |
| Haken | TreeView `OnChecked`; CheckListBox ohne `OnItemCheck` | `OnItemCheck` (CheckListBox zusätzlich zu `OnClickCheck`) |
| Aufzählungswerte | TeachingTip `tpAuto`, `tpTop`, `tpBottom`, `tpLeft`, `tpRight` | `ttpAuto` … `ttpRight` |

Gleiche Vorgaben für gleiche Konzepte als Konstanten in `PPG.Types`: `DropDownCount` 8 (Bereich 1..100), `AutoComplete` True (auch SearchEdit), `ShowHint` False wie VCL (NavigationView, ToolBar, Ribbon), Kanban-Spaltenbreite eine Konstante.

**Nachziehen:** Tests, Demo, Doku (Notizen, Property-Referenz, Architektur, Migration), `make-icons`/`PPG.Reg` falls Namen dort stehen. **`migrate.ps1`:** VCL/TMS → PPGlow mit den neuen Zielnamen (`TSpinEdit.MinValue`/`MaxValue` → `Min`/`Max`, `TStringGrid.OnTopLeftChanged` → `OnTopLeftChange`, TMS-Namen entsprechend), auch Ereigniszuweisungen in der `.pas`; Fixtures dazu.

### 5d Fehlende VCL-Properties und -Ereignisse
- **Stufe 1 (alle sichtbaren Controls):** `OnClick`, `OnDblClick`, `OnMouseDown/Move/Up`, `OnMouseEnter/Leave`, `OnMouseWheel`, `OnKeyDown/Press/Up`, `OnEnter/OnExit` (fokussierbare), `OnContextPopup`, `PopupMenu`, `OnMouseActivate`, `StyleElements`, `Color` (wo gezeichnet), Drag-Ereignisse (`DragMode`/`DragCursor`/`OnDragDrop`/`OnDragOver`/`OnStartDrag`/`OnEndDrag`; beim Kanban nur, wenn es nicht mit dem Karten-Ziehen kollidiert).
- **Stufe 2:** `DoubleBuffered`/`ParentDoubleBuffered` (erst prüfen, ob es bei den selbst zeichnenden Controls etwas bewirkt; sonst veröffentlicht ohne Wirkung und dokumentiert, damit migrierte DFMs laden), `Action` nur bei anklickbaren Controls mit Beschriftung (Label, LinkLabel, Badge, Panel, GroupBox, ToolBar-/Ribbon-Items haben sie schon).
- **Stufe 3 (kleine, control-spezifische):** TrackBar `Font`/`OnTracking`, ProgressBar `BarColor`/`BackgroundColor`, Panel `BorderStyle`/`OnCanResize`, ComboBox `AutoDropDownWidth`, Tab-/PageControl `OnGetImageIndex`, TabSheet `Highlighted`, Grid `ScrollBars`, DBGrid `OnColEnter`/`OnColExit`/`OnEditButtonClick`, DBLookupComboBox `DropDownRows`/`DropDownAlign`/`ListFieldIndex`, SearchEdit `ReadOnly`/`Alignment`/`AutoSelect`, Ribbon `TabStop`/`OnEnter`/`OnExit`, StatusBar `Action`; aus dem Audit (5c, „uneinheitlich angeboten“) `ShowClearButton` für Spin/Number/Date/Tag/Password und `TextHintVisibleOnFocus` für Spin/Date/Time/Tag, wo die Feld-Basis es schon kann.
- **Nicht in diesem Paket (größere Funktionen, eigene Liste):** TreeView `StateImages`/`SortType`/`RightClickSelect`/`OnGetImageIndex`, Calendar `MultiSelect`/`OnGetMonthBoldInfo`, ComboBox `OnDrawItem`/`OnMeasureItem`, Grid `OnGetEditMask`/`OnRowMoved`, DBGrid `OnDrawColumnCell`, IME-Properties, `PositionToolTip`.
- Streaming-Test (`Tests\PPG.Tests.Streaming.pas`) schickt die neuen Properties automatisch durch die DFM; die Ausnahmeliste wird angepasst.

## Tests
- Je Befund ein Regressionstest („Audit 09.10.2026“), der vorher rot ist.
- 4a: festhaltende Tests je DB-Control vor dem Umbau.
- 5c: Der Streaming-Test schickt die neuen Namen durch die DFM; ein Test prüft per RTTI, dass keiner der alten Namen mehr veröffentlicht ist.
- 5d: ein Test je Stufe, der für alle Paletten-Controls prüft, dass die Ereignisse published sind und ausgelöst werden (Klick, Taste, Rad über `Perform`).

## Reihenfolge und Commits
4a → 4b → 4c → 5a → 5b → 5c → 5d, je Teil ein Commit (5c und 5d bei Bedarf in zwei). Bericht nach 5d. Zwischenstände in `NAECHSTE-SCHRITTE.md` und im Fortschritt von `Docs\Audit-Plan.md`.

## Verifikation
- `Build\check-rules.ps1`, `build.ps1` (alle Projekte, Win32 und Win64)
- `Tests\PPGlowTests.exe` und `/leaks`, Win32 und Win64
- `Demo\PPGlowDemo.exe /selftest datei.txt`; die Demo nutzt die neuen Namen
- `migrate.ps1 -SelfTest` mit Fixtures für die neuen Zielnamen (VCL/TMS → PPGlow)
- `make-docs.ps1 -Missing` (ohne Beschreibung: 0), Property-Referenz mit neuen Namen

## Entscheidungen (User, 09.10.2026)
1. **Gemeinsame DB-Bindung (4a) vor den Fixes:** ja.
2. **Alte Namen:** keine Aliase. „Die Komponenten sind bisher in keinem einzigen Projekt im Einsatz, also sollten wir die einfach umbenennen können ohne Aliase und ohne dass etwas bricht. Nachdem das erste Mal die Suite irgendwo installiert wurde, darf nicht mehr umbenannt werden.“
3. **Umfang 5c:** die ganze Audit-Tabelle (auch Aufzählungswerte und Farb-Aufzählungen).
4. **Umfang 5d:** Stufen 1–3; die größeren Funktionen kommen auf eine eigene Liste.

## Umsetzung (09.10.2026)

Commits auf `claude/task-elizkl`: 7b0b99a (Festhalte-Tests), ab05269 (4a), d9cfed2 und 89c5dae (4b/4c), e8ce0d2 (5a), 93eb8f7, 8186dfb und 097583a (5b), a24b46f (5c), 79695bc, 4883d55 und ba1754b (5d Stufe 1–3).

Ergebnis: 1544 Tests Win32 und Win64 grün (vorher 1466), Leak-Lauf Win32/Win64 grün, alle sechs Projekte gebaut, Demo-Selbsttest 185/185, `migrate.ps1 -SelfTest` 8/8 (neue Fixture `Unit4`), `make-docs.ps1 -Missing` 0, Regel-Prüfer ohne Verstoß. Nichts installiert.

**Paket 4:** `TPPGDBBinding` in `PPG.DB.Controls` trägt Anzeigen, Schreiben, Bearbeitbarkeit, Esc, Actions und `CM_GETDATALINK` für alle Feld-Controls; `TPPGDBValueBinding` (`PPG.DB.Fields`) für die `IPPGFieldValue`-Controls. Dazu die Fehler aus 4b (MaxLength aus dem Feld, Null im DatePicker, Esc überall, Lookup-Felder als DataField, Nachschlage-Editor im DB-Grid, Bearbeiten ab dem ersten Tastendruck, Ausrichtung der Spalten, `ShowRequired`, Chart ohne Null-Punkte, Lesezeichen) und die Designer-Punkte aus 4c.

**Paket 5:** Streaming-Marker für leere Strings, `stored`-Funktionen, Setter mit Gleichheitsprüfung und `PPGCheckRange`, `ImageName` an Einträgen, Kategorie „PPGlow“ im Objektinspektor; einheitliche Namen ohne Aliase (Regeln in `Docs\Architektur.md`, Abschnitt „Namensregeln“); VCL-Properties und -Ereignisse bei allen 72 sichtbaren Controls (Test `PPG.Tests.Audit5d`).

**Nebenbei gefundener Fehler (5d):** `TControl` ruft `DblClick` nur mit `csClickEvents` auf. ListBox, CheckListBox, TreeView, Grid, DB-Grid, Kanban und Ribbon nehmen diesen Stil heraus. Deshalb kam ein echter Doppelklick dort nie an (TreeView klappte nicht auf, Kanban `OnCardOpen` per Doppelklick fehlte). Die Basis ruft `DblClick` jetzt selbst auf, wenn `csDoubleClicks` gesetzt ist.

**Abweichungen vom Plan:**
- 4a: Die gemeinsame Bindung spart kaum Zeilen (netto etwa +40 statt der erhofften rund 600 weniger). Die Sonderregeln der Controls (Lookup, Memo-Laden, Radio-Werte, Tag-Liste) brauchen eigene Überschreibungen; gewonnen ist das einheitliche Verhalten.
- 4b: Das Chart überspringt Null-Werte, statt eine Lücke in der Linie zu zeichnen. Lookup mit mehreren Schlüssel- bzw. DataField-Feldern wird nicht unterstützt, sondern gemeldet (`SPPGDBLookupMultiKey`). Large-Int-Werte über 2^53 sind im NumberEdit ungenau (Double).
- 5b: Badge, ProgressRing, Rating und Splitter lesen weiterhin nicht alle Appearance-Werte. Das würde die Referenzbilder ändern und kommt mit Paket 7 (UI/UX). Die NC-Bevel bei abgerundeten Panels werden nicht unterdrückt. SearchEdit `AutoComplete` bleibt `False`.
- 5d Stufe 1: `OnDblClick` gibt es nur bei Controls, die Doppelklicks annehmen. Button, CheckBox, RadioButton, ToggleSwitch, TrackBar, ProgressBar, Gauge, KpiTile, MenuBar, Breadcrumb, Calendar, NavigationView, Rating, Splitter, ToolBar und DB-Navigator haben es wie TButton nicht, damit schnelle Klicks einzeln zählen (beim Calendar ist das eine Abweichung von TMonthCalendar). Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfelder melden mit `OnClick` die Auswahl, wie in der VCL; ColorPicker, ColumnComboBox und CheckComboBox tun das jetzt auch. Ribbon fragt `OnContextPopup` vor dem eigenen Menü; TimePicker gibt `OnMouseWheel` vor dem eigenen Blättern.
- 5d Stufe 2: `DoubleBuffered` ist ohne eigene Wirkung veröffentlicht (die Controls puffern immer); das innere Edit der Felder übernimmt es nicht.
- 5d Stufe 3: TrackBar `Font` entfällt (TTrackBar hat keins, die Leiste zeichnet keinen Text). `ShowClearButton` gibt es für NumberEdit, PasswordEdit und TagEdit (leert alle Tags), nicht für SpinEdit und DatePicker: beide haben keinen leeren Wert, der Knopf würde nur den Text leeren, der beim Verlassen zurückspringt. TabSheet `Highlighted` zeichnet den Reiter wie unter der Maus.

**Noch offen (eigene Liste, wie entschieden):** TreeView `StateImages`/`SortType`/`RightClickSelect`/`OnGetImageIndex`, Calendar `MultiSelect`/`OnGetMonthBoldInfo`, ComboBox `OnDrawItem`/`OnMeasureItem`, Grid `OnGetEditMask`/`OnRowMoved`, DB-Grid `OnDrawColumnCell`, IME-Properties, TrackBar `PositionToolTip`.
