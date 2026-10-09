# Audit-Paket 7 – UI/UX-Konsistenz – Detailplan

*Stand 09.10.2026. **Vom User am 09.10.2026 zur Umsetzung freigegeben; die vier Entscheidungen am Ende wie empfohlen.** Grundlage: `Docs\Audit-Plan.md` (Paket 7) und der in Paket 5b verschobene Punkt „Badge/ProgressRing/Rating/Splitter lesen die übrigen Appearance-Werte“ (`Docs\Audit-Paket4-5-Plan.md`, Abweichungen). Alle Befunde wurden am 09.10.2026 gegen den aktuellen Code (nach Phase 20 und den Paketen 4/5) neu geprüft; Zeilennummern unten sind aktuell.*

## Context
Das Audit vom 08.10.2026 meldete für UI/UX rund 30 Befunde in sechs Gruppen (7a–7f). Die Nachprüfung zeigt:
- **Erledigt:** `DropWheel` (Listen-Popups scrollen per Rad), RadioGroup spiegelt Pfeile bei RTL, Ziehschwellen in ItemList/Grid/Planner nutzen `SM_CXDRAG`, ComboBox/SearchEdit/TimePicker/ColorPicker/CheckComboBox/ColumnComboBox/TagEdit laufen auf der gemeinsamen Aufklapp-Basis (Phase 20).
- **Teilweise:** Mausrad (Scroll-Basis richtig, Wert-Controls nicht), Popups folgen dem Formular (nur Klick außerhalb schließt), Standardaktion „Drücken“ (Container/Felder überschrieben, 20 Controls weiter falsch), deaktivierter Zustand (Planner nur Text, Kanban gar nicht), ItemList-Überspringen.
- **Offen:** alles Übrige, dazu Nebenfunde (Grid/ItemList verschlucken `OnKeyDown` für Navigationstasten und Buchstaben, TileView zeigt den Hint immer, NumberEdit beansprucht Enter ebenfalls immer).

Warum jetzt: Diese Punkte merkt ein Anwender sofort – Default-Button reagiert nicht, `OnKeyDown` kommt nicht, Rad dreht Werte unter dem Mauszeiger ohne Fokus, Screenreader sagen „Drücken“ bei einem Diagramm, Links im Dark Mode kaum lesbar.

## 7a Aufklappfelder

| # | Stelle | Fix | Aufwand |
|---|---|---|---|
| 1 | `PPG.DatePicker.pas:856–860/877–881` | F4 und Alt+Pfeil schließen mit `CloseUp(True)`; Alt+Pfeil runter **und** F4 klappen auf (wie die Basis `PPG.Controls.DropDown.pas:433–441`). | klein |
| 2 | `PPG.DatePicker.pas:919–922/889`, `PPG.TimePicker.pas:508–511/497`, `PPG.NumberEdit.pas:786` | Enter nur beanspruchen, wenn das Popup offen ist oder der Text vom formatierten Wert abweicht; sonst durchreichen → Default-Button reagiert. Gemeinsame Regel in der Feld-Basis (`WantsReturn`-Abfrage). | klein |
| 3 | `PPG.DatePicker.pas:39/55/276–303/1073` | **DatePicker auf `TPPGCustomDropDownField`:** `TPPGCalendarPopup` von `TPPGDropPopup` ableiten, Maus über die `Drop*`-Methoden an den Kalender; eigener Hook, `GOpenPicker`, `GMsgDateToggle` entfallen. DBDatePicker zieht mit. Festhaltende Tests vorab (Auf-/Zuklappen, Auswahl, Esc, Checkbox, DB-Null). | groß |
| 4 | `PPG.Controls.DropDown.pas:184–210/372–378` | Popups folgen dem Formular: in `DropDown` `PPGWatchControl` anmelden, bei `WM_WINDOWPOSCHANGED`/`WM_SIZE` `RepositionPopup`, bei `CM_SHOWINGCHANGED` schließen (Vorbild `PPG.TeachingTip.pas:1234/1266`). Gilt nach #3 auch für den DatePicker; Ribbon-Popups (`PPG.Ribbon.pas:110/137`) bekommen dasselbe über `TPPGPopupWindow`. | mittel |
| 5 | `PPG.Popup.pas:396–418/444–467` | Aufklapp-Animation ohne `SetWindowRgn` je Frame: Endgröße und Region einmal setzen, nur den Inhalt (Offset/Clip) animieren. | mittel |
| 6 | `PPG.Popup.pas:629/702` → `PPG.ItemPainter.pas:185` | `ItemHeight` zwischenspeichern (verworfen bei Font, PPI, Images, TwoLine) – kein DC je `ItemRect`/`ItemAtPos`. | klein |
| 7 | ComboBox `:63/876`, ItemList `:57/1670`, ColumnComboBox `:116/497/803`, TileView `:90/1840` | Gemeinsamer Record `TPPGTypeAhead` (Text, Tick, `Add(Key)`, Weiterblättern beim gleichen Buchstaben überall); ColumnComboBox greift nicht mehr auf private Felder zu. | mittel |

## 7b Mausrad

Gemeinsamer Helfer in `PPG.Controls.Base.pas`: `WheelSteps(var Rest; Delta; Lines): Integer` (sammelt Teil-Deltas hochauflösender Räder, Zeilen aus `SPI_GETWHEELSCROLLLINES`) und `WheelNeedsFocus` – Wert-Controls ändern ihren Wert **nur mit Fokus**, ohne Fokus geht das Rad an den Elternteil (scrollt die Seite).

| Stelle | Heute | Neu |
|---|---|---|
| `PPG.SpinEdit.pas:520` | ±1 je Nachricht, ohne Fokus | Helfer, nur mit Fokus |
| `PPG.NumberEdit.pas:883` | ±1 je Nachricht | Helfer (Delta) |
| `PPG.TimePicker.pas:513` | ±1 Segment je Nachricht | Helfer (Delta) |
| `PPG.Calendar.pas:1199` | eine Seite je Nachricht, ohne Fokus | Helfer, nur mit Fokus |
| `PPG.TrackBar.pas:756/766` | ohne Fokus | nur mit Fokus |
| `PPG.Popup.pas:941`, `PPG.RowPopup.pas:461` | fest 3 Zeilen | SPI-Zeilen + Delta |
| `PPG.Kanban.pas:3010` | fest 3 × 20 px, Rundungsverlust | SPI-Zeilen + Delta |
| `PPG.Planner.pas:4351` (Monat), `PPG.TileView.pas:1717` (Strg-Zoom) | je Nachricht | Helfer (Delta) |
| NavigationView `:1727`, Panel `:834`, Menus `:1736` | ohne SPI | SPI-Zeilen |

Der DatePicker bekommt Rad auf dem Segment unter dem Cursor (mit 7c #6). Aufwand: mittel.

## 7c Tastatur

| # | Stelle | Fix | Aufwand |
|---|---|---|---|
| 1 | `PPG.Controls.ItemList.pas:1546`, `PPG.TreeView.pas:2424`, `PPG.Grid.pas:5723`, `PPG.RadioButton.pas:~213` | `inherited KeyDown` zuerst, bei `Key = 0` abbrechen (Muster `PPG.TabControl.pas:960`). Heute kommt `OnKeyDown` bei Pfeilen, Leertaste, Strg+A, +/-/*, F2 und im Grid sogar bei C/V/A ohne Strg nie an. TreeView ruft inherited nur einmal (reicht an ItemList weiter). | klein |
| 2 | `PPG.RadioButton.pas:132/83` | Nur die markierte Option ist Tabstopp (`TabStop := Checked`, Geschwister aus; ohne Markierung bleibt die erste Tabstopp). | klein |
| 3 | `PPG.TabControl.pas:955` | Strg+F4 schließt den aktiven Reiter über `CloseTab` (mit `OnClosing`), wenn `ShowCloseButton`; gilt auch für PageControl (gemeinsame Basis). | klein |
| 4 | `PPG.Controls.ItemList.pas:~1625` | Überspringen nicht wählbarer Einträge: findet sich in Richtung nichts, Gegenrichtung suchen (Bild↑/↓ am Rand); `Dir` für Links/Pos1 richtig; ohne Fokus springt Ende ans Ende. | klein |
| 5 | `PPG.Grid.pas:5723/6203` | `ClearSelection` (Entf, nur editierbare Zellen über `CanEditCell`/`SetCellByUser`), `CutToClipboard` (Strg+X, Umschalt+Entf), Umschalt+Einfg = Einfügen, Strg+Einfg = Kopieren. Mit Undo-freundlichem Ereignis je Zelle wie beim Einfügen. | mittel |
| 6 | `PPG.DatePicker.pas:877/528` | `Kind = dtkTime`/Datum+Uhrzeit: Segment-Logik aus `PPG.TimePicker.pas:443/462` (`SegmentAtCaret`, `StepSegment`) als gemeinsamer Helfer; Pfeile ändern das Segment unter dem Cursor. | mittel |

## 7d Barrierefreiheit

| # | Stelle | Fix | Aufwand |
|---|---|---|---|
| 1 | `PPG.Controls.Field.pas:1614/1845–1880` | Validierungstext per `PPGAccSetWindowDescription` am **inneren** Edit (dort steht der Fokus), `EVENT_OBJECT_DESCRIPTIONCHANGE` dort; beim Wechsel auf `pvsError` `EVENT_SYSTEM_ALERT`. Nach `RecreateWnd` erneut setzen. Damit meldet auch der Validator Fehler am Feld. | klein |
| 2 | `PPG.Controls.Base.pas:1567/1602–1611`, `PPG.Controls.Scroll.pas:35` | Umkehren: Die Basis meldet **keine** Standardaktion und keine Button-Rolle mehr; „Drücken“ + `ROLE_SYSTEM_PUSHBUTTON` nur in den Button-Klassen (Button, SplitButton, ToggleButton, ToolBar-/Ribbon-Knöpfe als Kinder). Betroffene bekommen passende Rollen (Gauge/KpiTile/Sparkline/Chart `ROLE_SYSTEM_GRAPHIC`/`CHART`, Rating `SLIDER`, Splitter `SEPARATOR`, Calendar `TABLE`, NavigationView/ToolBar/MenuBar/StatusBar/Ribbon/Breadcrumb eigene Leisten-Rollen, LinkLabel `LINK` mit Aktion „Ausführen“). Test: für alle Paletten-Controls Rolle und Standardaktion per `IAccessible` prüfen. | mittel |

## 7e Farben

| # | Stelle | Fix | Aufwand |
|---|---|---|---|
| 1 | 6 Kopien (Calendar `:332`, Feedback `:383`, NavigationView `:479`, Notifications `:213`, Planner `:786`, StatusBar `:253`), 8 eigene Schwellen (Grid.Export `:371`, Xlsx `:666`, ItemPainter `:462`, PasswordEdit `:443`, Chart `:1725`, ProgressBar `:477`, Kanban `:2102`, RadioGroup `:1292`) | `PPGContrastTextColor(Fill; Light, Dark)` in `PPG.Tokens` über `PPGContrastRatio` (höherer Kontrast gewinnt). Alle 14 Stellen umstellen; Export (bisher 0,45) wird bewusst angeglichen. | klein–mittel |
| 2 | DatePicker `:1188`, Dialogs `:482`, Ribbon `:2757`, ProgressBar `:470` | `Tokens.OnAccent` bzw. `PPGContrastTextColor` statt `clWhite`. | klein |
| 3 | Hints `:405`, Labels `:352` | Neues Token `Link` (hell: Akzent, dunkel: aufgehellter Akzent mit ≥ 4,5:1 gegen `Background`); `clHotLight` nur bei Hochkontrast. LinkLabel nutzt es ebenfalls. | klein |
| 4 | `PPG.Labels.pas:303` | TPPGLabel nimmt die Tokens des Standard-Presets (wie `PresetTokens` in `PPG.Hints.pas:239`; Helfer gemeinsam), deaktiviert `TextDisabled` statt `clGrayText`. | klein |
| 5 | Planner `:2421`, Kanban (nichts) | Gemeinsamer Helfer `PPGDisabledColors` bzw. Abblend-Faktor in `PPG.Tokens`; Kanban blendet Karten, Akzente und Text ab, Planner auch Termin-Füllungen. | mittel |
| 6 | Grid.Data `:272`, Grid.Print `:139/320`, Grid.Export `:96/114` | `PPGPlainTableLook` in `PPG.Grid.Data` als einziger Satz; Linienfarbe vereinheitlicht ($A0A0A0 vs. #c8c8c8 → eine). | klein |
| 7 | 80 `PPGIsHighContrast`-Abfragen in 45 Units | **Hochkontrast als Token-Satz:** `PPGHighContrastTokens` aus den Systemfarben; `EffectiveTokens` liefert ihn bei aktivem HC (Rangfolge HC > VCL-Style > Dark > Appearance bleibt). Danach die eigenen Zweige abbauen, wo sie nur Systemfarben setzen; Sonderfälle (z. B. Muster statt Farbe im Chart) bleiben. Labels/Hints/Dialogs fragen `HighContrastSupport` einheitlich ab. Zur Prüfung `RtlGallery`-artiger HC-Bogen im Visual-Test (HC simuliert über Token-Satz). | groß |

## 7f Kleineres

| # | Stelle | Fix | Aufwand |
|---|---|---|---|
| 1 | ItemList (kein `CM_HINTSHOW`), Grid (dito) | Tooltip für abgeschnittene Texte nach dem Vorbild `PPG.TreeView.pas:2777–2808` (`ToolTips`, nur ohne eigenen `Hint`); in der ItemList-Basis, TreeView behält ihren Override; Grid je Zelle (`CursorRect` = Zelle, nicht bei Check/Progress-Zellen). | mittel |
| 2 | `PPG.TileView.pas:1733–1747` | Hint nur, wenn die Beschriftung wirklich abgeschnitten ist; eigener `Hint` hat Vorrang. | klein |
| 3 | `PPG.TagEdit.pas:908–920` | `CMMouseLeave` (und Wechsel ins innere Edit) setzt `FHotTag`/`FHotCross` zurück. | klein |
| 4 | `PPG.Kanban.pas:2909/2919` | Ziehschwelle per `PPGDragExceeded(DownPt, P)` (neu in Core, `SM_CXDRAG`/`SM_CYDRAG`, halbe Breite); ItemList, Grid und Planner nutzen ihn ebenfalls (heute uneinheitlich `>=`/`>`). | klein |
| 5 | `PPG.Hints.pas:371–411` | RTL: Bild rechts, Titel `DT_RIGHT or DT_RTLREADING`, Text rechtsbündig (wie InfoBar). Volles RTL-Absatzlayout im Markup nicht in diesem Paket. | klein–mittel |
| 6 | `PPG.RadioButton.pas:206–209` | Links/Rechts bei `UseRightToLeftAlignment` tauschen. | klein |

## 7g Appearance bei Badge, ProgressRing, Rating, Splitter (aus 5b)

Wichtig: `Normal.Color` ist in den Presets die Button-Fläche. Die Akzentrolle liegt deshalb auf **`Checked`** (Rückfall `FocusColor`), wie bei der ProgressBar (`PPG.ProgressBar.pas:409–470`). Vor dem Umbau wird geprüft, dass `Checked.Color` in allen Presets (ModernFlat, Fluent11, Classic, je hell/dunkel) dem Akzent entspricht – sonst würde sich die Standardoptik verschieben.

| Control | Heute | Neu |
|---|---|---|
| Badge (`PPG.Feedback.pas:426–485`) | nur `FocusColor` bei Accent, Pille fest | Fläche `Checked.Color`/`ColorTo` (Verlauf über `DrawSurface`), Text `Checked.TextColor`/`FontStyle` (sonst Kontrastfarbe), Rahmen `BorderColor`/`BorderWidth`, `Rounding` (gedeckelt auf Pille), deaktiviert `A.Disabled`. Severity-Farben bleiben Tokens. |
| ProgressRing (`:717–782`) | `FocusColor`, Spur aus Tokens | Bogen `Checked.Color`, Spur `Normal.BorderColor`, deaktiviert `Disabled.BorderColor`; `BorderWidth` als Vorgabe für `Thickness = 0`; optional Glow um den Bogen. |
| Rating (`PPG.Rating.pas:438–491`) | `FocusColor`, leere Sterne `TextSecondary`, Fokusrahmen fest 4 | gefüllt `StarColor` sonst `Checked.Color`, leer `Normal.BorderColor`, Hover-Vorschau `Hot.Color`, deaktiviert `Disabled.TextColor`, Fokusrahmen mit `Rounding` und `Focused.BorderColor`. `IsHot` wird gesetzt. |
| Splitter (`PPG.Splitter.pas:650–718`) | `FocusColor` aktiv, sonst Tokens | ruhend `Normal.BorderColor`, Hover `Hot.BorderColor`, Griffpunkte `Hot.TextColor`, Ziehen `Down.BorderColor`, Fokus `Focused.BorderColor`, Linienbreite aus `BorderWidth`. |

Dark/VCL-Style kommen über `EffectiveAppearance` automatisch mit; Hochkontrast bleibt (bzw. läuft über 7e #7). Die Referenzbilder `Badge_*`, `ProgressRing_*`, `Rating_*`, `Splitter_*` in `Tests\Visual\Baseline` werden gezielt gelöscht und neu erzeugt; die Galerie wird vorher/nachher angesehen.

## Tests
- Je Befund ein Regressionstest („Audit 09.10.2026, Paket 7“), der vorher rot ist; neue Suite `Tests\PPG.Tests.Audit7.pas`.
- 7a #3: festhaltende Tests für DatePicker/DBDatePicker vor dem Umbau, gegen den alten Code grün.
- 7b: Rad mit Teil-Deltas (40+40+40 = ein Schritt), ohne Fokus keine Wertänderung.
- 7c #1: für alle Paletten-Controls `OnKeyDown` bei Pfeilen/Leertaste/Buchstaben über `Perform`.
- 7d #2: Rolle und Standardaktion aller Paletten-Controls per `IAccessible`.
- 7e/7g: Visual-Tests (Galerie-Prüfungen „lesbar“, Kontrast der Links im Dark Mode ≥ 4,5:1), Referenzbilder nur für die bewusst geänderten Controls neu.

## Reihenfolge und Commits
7c #1–4 und 7a #1–2 (schnelle Gewinne) → 7d → 7e #1–6 → 7g → 7b → 7c #5–6 → 7f → 7a #3–7 → 7e #7. Je Gruppe ein Commit (7a #3 und 7e #7 eigene). Bericht am Ende; Zwischenstände in `NAECHSTE-SCHRITTE.md` und im Fortschritt von `Docs\Audit-Plan.md`.

## Verifikation
- `Build\check-rules.ps1`, `build.ps1` (alle Projekte, Win32 und Win64)
- `Tests\PPGlowTests.exe` und `/leaks`, Win32 und Win64
- Galerie `Tests\Visual\Gallery` vorher/nachher ansehen (RTL, DPI, Dark)
- `Demo\PPGlowDemo.exe /selftest datei.txt`
- Nichts installieren.

## Entscheidungen (User, 09.10.2026: alle vier wie empfohlen)
1. **DatePicker-Umbau auf die Aufklapp-Basis (7a #3, groß):** jetzt mit, oder nur die Tastatur-Fixes #1/#2 und der Umbau später?
2. **Hochkontrast als Token-Satz (7e #7, groß, 45 Units):** jetzt mit, oder nur der Helfer und die Vereinheitlichung bei Labels/Hints/Dialogs?
3. **Mausrad nur mit Fokus (7b):** Wert-Controls (SpinEdit, Calendar, TrackBar …) ändern den Wert nur noch mit Fokus, wie das Audit vorschlägt. Das weicht bei TTrackBar von der VCL ab (die reagiert auch ohne Fokus, wenn Windows „inaktive Fenster scrollen“ an hat).
4. **Akzentrolle aus `Checked` (7g):** Badge/ProgressRing/Rating nehmen den Akzent aus `Appearance.Checked` statt `FocusColor`, wie die ProgressBar.

Antworten: 1. ja (voller Umbau), 2. ja (ganzer Token-Satz), 3. ja, 4. ja (mit Ausnahme Classic, siehe Abweichungen).

## Umsetzung (09.10.2026)

Parallel in fünf Git-Worktrees (`PPGlow-a7a` … `a7e`, Zweige `claude/audit7-a` … `e`), IDE-Builds über eine gemeinsame Sperre nacheinander; danach in `claude/task-elizkl` zusammengeführt. Neue Testgruppen `Audit7A`–`Audit7D` (`Tests\PPG.Tests.Audit7*.pas`), der Testlauf kennt `/suite Name[,Name]`.

Commits: e5ce41f, e55ddc6, 43011d9 (7a), eb8b4c1 (7b), da2777a (7c #1–#5, 7a #7, 7f), 25e170c (7c #6), 52765fc, a6cb545 (7d), f8433b6 (7e #1–#6), a528acb (7f #5), 245486e (7g), 3d2062f (7e #7), dazu Testkorrekturen.

Ergebnis: **1635 Tests Win32 und Win64 grün** (vorher 1548), Leak-Lauf Win32/Win64 ohne Zuwachs, alle sechs Projekte (Win32) gebaut, Demo-Selbsttest 185/185, Regel-Prüfer ohne Verstoß, `make-docs` 0 fehlend. Referenzbilder neu nur für ProgressRing, Rating, Splitter (bewusste Optikänderung); neu in der Galerie `HighContrast.png`. Nichts installiert.

**7a:** `TPPGCustomField.InputPending` – Enter (und bei NumberEdit Esc) gehört dem Feld nur bei offenem Popup oder getipptem Text, sonst reagiert der Default-Button (DatePicker, TimePicker, NumberEdit). DatePicker erbt von `TPPGCustomDropDownField`, `TPPGCalendarPopup` von `TPPGDropPopup`; Maus-Hook, `GOpenPicker`, `GMsgDateToggle` entfallen, published-Schnittstelle unverändert. `TPPGPopupWindow.FollowSource` (`OnFollow`, `OnSourceHidden`, über `PPGWatchControl`): Popups wandern mit dem Formular, schließen beim Verstecken/Minimieren; Ribbon-Popups ebenso. Region einmal statt je Animationsbild, `ItemHeight`-Cache. `TPPGTypeAhead` und `PPGTypeAheadMs` in `PPG.Types` für ComboBox, ItemList, ColumnComboBox, TileView.

**7b:** `PPGWheelSteps`/`WheelSteps`, `PPGWheelScrollLines`, `WheelNeedsFocus` in `PPG.Controls.Base`; Teil-Deltas werden gesammelt, Zeilen aus `SPI_GETWHEELSCROLLLINES` (seitenweise = sichtbare Höhe), Wert-Controls ändern nur mit Fokus, `OnMouseWheel` kommt zuerst.

**7c:** `inherited KeyDown` zuerst über `NavigateKey` (ItemList, TreeView, Grid, DB-Grid, RadioButton) – `OnKeyDown` kommt bei allen Tasten genau einmal; RadioButton-Tabstopp nur an der markierten Option; Strg+F4 schließt Reiter; Überspringen am Rand; Grid `ClearSelection`/`CutToClipboard` (Entf, Strg+X, Umschalt+Entf, Umschalt/Strg+Einfg); DatePicker-Uhrzeit nach Segment (`PPGTimeSegmentAt`, `PPGStepTimeSegment`).

**7d:** Validierungstext als Beschreibung am inneren Edit, `EVENT_SYSTEM_ALERT` bei Fehler. Basis meldet `ROLE_SYSTEM_CLIENT` ohne Standardaktion; „Drücken“ nur bei Buttons sowie Badge/KpiTile mit `OnClick`; LinkLabel mit einem Link „Springen“.

**7e:** `PPGContrastTextColor`/`PPGReadableTextColor`, Token `Link` (≥ 4,5:1, auch in StyleManager/Theme-Datei), `PPGPresetTokens`, `PPGDisabledColor`/`PPGDisabledTokens` (Kanban und Planner blenden ab), `PPGPlainTableLook`. Hochkontrast: `PPGHighContrastTokens`/`PPGApplyHighContrastAppearance`, `Tokens` und `EffectiveAppearance` liefern sie bei `UseHighContrast`; 80 eigene `PPGIsHighContrast`-Abfragen in 45 Units → 0 (Sonderfälle über `UseHighContrast`/`UseOwnColors`); `HighContrastSupport` bei Label, HintManager, CustomHint, TaskDialog; Testhaken `PPGSetHighContrastReader`.

**7f:** Tooltips für abgeschnittene Texte (`ToolTips` in ItemList-Basis und Grid), TileView-Hint nur bei Abschnitt, TagEdit-Hover, `PPGDragExceeded` (halbe `SM_CXDRAG`), Hints und RadioButton bei RTL.

**7g:** `PPGCheckedIsAccent`/`PPGAccentColor` in `PPG.Appearance`; Badge, ProgressRing, Rating, Splitter lesen Zustandsfarben, Rahmen, Rundung, Linienbreite.

**Abweichungen:**
- 7g Classic: `Checked` ist dort der goldene Office-Verlauf. Checked trägt den Akzent deshalb nur, wenn `Normal` keinen Verlauf hat; sonst gilt `FocusColor` (Classic bleibt blau).
- 7g im Einzelnen: Badge-Radius = `Rounding` × 3, gedeckelt auf die Pille; deaktivierte Badge über `PPGDisabledColor`; ProgressRing ohne Glow, `BorderWidth` als Mindeststärke; Rating mischt leere Sterne bis 3:1 und die Hover-Vorschau zu 30 % mit `Hot.Color`.
- 7e #1: Weiß bleibt, solange es gerundet 4,5:1 erreicht (Weiß auf #0078D7 = 4,499:1); Export/Xlsx folgen der gemeinsamen Regel (Rot jetzt mit schwarzer Schrift).
- 7e #3: Link im hellen Modus nur so weit abgedunkelt wie für 4,5:1 nötig.
- 7d: kein neuer Text „Ausführen“, LinkLabel nutzt das vorhandene „Springen“; Kanban (PANE) und Ribbon (GROUPING) behalten ihre Rollen.
- 7a: Klick oder Enter auf den schon gewählten Tag schließt den Kalender (wie Windows); Ausblenden wird über `IsWindowVisible` erkannt, versteckte Panels innerhalb des Formulars nicht.
- 7c/7f: Ziehschwelle jetzt 2 px statt 4 px (wie DragDetect); RadioButtons schreiben `TabStop = False` für nicht markierte Optionen.
- 7e #7: Im Hochkontrast erscheinen Validierung und Signale in `clHighlight`, deaktivierte Einträge grau; Tooltips/MenuBar/Dialog-Fußzeile behalten `clInfoBk`/`clMenuBar`/`clBtnFace`. Nur mit simuliertem Hochkontrast geprüft, nicht in einem echten Kontrastdesign.

**Testkorrekturen:** `TNamingTests.CheckListBoxOnItemCheck` setzt den Zähler zurück (scheiterte im zweiten Durchlauf von `/leaks`); `TComboBoxTests.WheelScrollsOnlyOpenList` rechnet mit der Systemeinstellung; Zwischenablage-Tests des Grids wiederholen bei belegter Zwischenablage.

**Offen:** Sichtprüfung im echten Windows-Kontrastdesign und mit Narrator; `TRibbonTests.ManyItemsStayFast` bleibt unter paralleler Last wackelig (Paket 11).
