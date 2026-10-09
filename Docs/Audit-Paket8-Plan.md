# Audit-Paket 8 – Performance – Detailplan

*Stand 09.10.2026. **Vom User am 09.10.2026 zur Umsetzung freigegeben; die vier Entscheidungen am Ende wie empfohlen.** Grundlage: `Docs\Audit-Plan.md` (Paket 8). Alle Befunde wurden am 09.10.2026 nach Paket 7 gegen den aktuellen Code neu geprüft (drei Prüf-Agenten, nur gelesen); Zeilennummern unten sind aktuell.*

## Context
Das Audit vom 08.10.2026 meldete rund 60 Performance-Befunde. Die Nachprüfung zeigt:
- **Erledigt:** TagEdit-Layout im Paint, ItemHeight im Popup (Paket 7), `EnsureGeometry` im Grid-Paint (nur noch eine billige Prüfung).
- **Teilweise:** Leisten-Fade (invalidiert gezielt, aber Paint zeichnet trotzdem alles), `FRegistered` im Animator (vorhanden, aber nicht genutzt), Ribbon-Textbreiten (gecacht, Höhe nicht), Breadcrumb/TabStrip-Layout, Kanban-Höhen-Cache (wird bei jeder Änderung ganz geleert), RowHeights, GDI-Hintergrund im Grid, Selection-Schnellpfad, TeachingTip-Bündelung.
- **Offen:** alles Übrige.

Die drei wichtigsten Einsichten:
1. **Paint zeichnet immer alles.** Die Basis legt bei jedem `WM_PAINT` eine neue Bitmap in voller Größe an und zeichnet die ganze Fläche (`PPG.Controls.Base.pas:1912–1967`); es gibt im ganzen Source kein `GetClipBox`. Gezieltes `InvalidateRect` (8b) bringt deshalb erst nach dem Clip-Umbau etwas.
2. **Hover kostet überall ein volles Neuzeichnen**, in Daten-Controls sogar ~10-mal (Hot-Animation, die dort niemand liest).
3. **Quadratische Pfade** an heißen Stellen: MenuBar misst je Mausbewegung n·(n+1)/2 Texte mit je eigenem DC, TreeView-Geschwistersuche linear (Items[]-Schleife O(n²)), AlphaSort als Einfügesortierung, CheckAll mit ItemsEx O(n²), Grid-Sortierung parst je Vergleich.

**Nebenbei gefundener Fehler (Korrektheit, vor allem anderen):** `PPG.AppHooks.pas:221/239/254` – `TControlWatcher` gehört dem beobachteten Control. Wird das Control in `FOldProc(Message)` freigegeben (z. B. Formular mit `Release`, das TeachingTip/Tour beobachten), greift `WatchProc` danach auf den freigegebenen Watcher zu (`Copy(FEvents)`, `Dec(FDepth)`, `FFreePending`).

Ausgangsmessung (Benchmark Release, 09.10.2026): alle 28 Vorgaben eingehalten; knapp: Kanban 10 000 Karten filtern 1891/2000 ms, Markup 10 000 Texte 2141/2500 ms, Grid 1 Mio. scrollen 2531/3000 ms, Chart live 2407/3000 ms. Datei `bench-vorher.txt` wird ins Repo übernommen (`Tests\Bench\Messung-vor-Paket8.txt`).

## 8.0 Vorarbeiten
| # | Punkt | Aufwand |
|---|---|---|
| 1 | **AppHooks-Fehler** beheben: Destruktor merkt sich bei `FDepth > 0` das Ende über ein Flag außerhalb der Instanz (lokale Variable in `WatchProc`, deren Adresse der Watcher kennt); nach `FOldProc` sofort aussteigen. Regressionstest: beobachtetes Formular gibt sich in seinem eigenen `CM_RELEASE` frei. | klein |
| 2 | **Benchmark erweitern** (je mit Vorgabe): Grid sortieren 1 Mio. (Zahl- und Textspalte, Richtungswechsel), Grid filtern + mit aktivem Filter umsortieren, Grid-Hover 300 Mausbewegungen mit HotRow-Stil, Spaltenbreite 100× ändern mit Footer-Summe + Farbskala + gesetzter `RowHeights[0]`, 100 Einzeländerungen mit Footer, bedingte Formate (Oben-10 %, Farbskala) 1 Mio., Paint mit Zellarten; ListBox-Hover, TreeView 10 000 Wurzeln Items[]-Schleife + AlphaSort, CheckAll 10 000 mit ItemsEx; MenuBar 300 Mausbewegungen, Chart-Hover 300 Bewegungen, Planner-Zeitleiste scrollen, Ribbon Action-Update 1000× Enabled; **Leerlauf**: Timer-Wakeups/s mit sichtbarem Planner (Jetzt-Linie) bzw. Maus über Scroll-Control. Alle neuen Messungen zuerst gegen den alten Code laufen lassen (Vorher-Werte). | mittel |

## 8a Kern
| # | Stelle | Fix | Aufwand | Nutzen |
|---|---|---|---|---|
| 1 | `PPG.Controls.Base.pas:1912–1967`, `PPG.Controls.Scroll.pas:763–799` | **Clip-Box als Dirty-Rect:** `GetClipBox` in Paint, Feld `PaintClip`, `IntersectClipRect` auf dem Puffer; `PaintViewport` von Grid, ItemList, TileView, Kanban, Planner überspringt Zeilen/Karten außerhalb. **Rückpuffer je Control zwischenspeichern** (nur bei Größen-/PPI-Änderung neu; Regel „keine dauerhaften GDI-Handles pro Control“ wird dafür bewusst gelockert: ein Bitmap je sichtbarem Control, freigegeben bei `DestroyWnd`/unsichtbar – Coding-Rules anpassen). `DrawParentBackground` und GDI+-Clip-Übernahme beachten den Clip. | groß | hoch – Voraussetzung für 8b |
| 2 | `Base:1280–1322/1054` | `UsesHotAnimation` (virtuell, `TPPGCustomScrollControl` → False): kein 150-ms-Hot-Fade mit ~10 Voll-Neuzeichnungen in Daten-Controls; bestehende `IsHot = False`-Lösungen (NavigationView, Ribbon, ToolBar, Chart, MenuBar, StatusBar) darauf umstellen. | klein | mittel–hoch |
| 3 | `PPG.Animation.pas:114/366/414/454/464` | **Fälligkeitsmodus:** Schleifen mit langer Periode (Planner-Jetzt-Linie `StartLoop(60000)` Planner:4663, `HoldAnim` Scroll:675, Toast-Lebensdauer Notifications:568/884, `FPoll`) bekommen einen Fälligkeitszeitpunkt; der Animator stellt den Timer auf den frühesten fälligen Zeitpunkt, wenn keine Frame-Animation läuft → keine 67 Wakeups/s im Leerlauf. `FRegistered` statt `IndexOf` (Snapshot mit Generationszähler). | mittel | mittel (Leerlauf-CPU, Akku) |
| 4 | `PPG.Render.Gdi.pas:284–297` (~75 Aufrufer in 30 Units) | Gemeinsamer Mess-DC (lazy, Hauptthread, `finalization`) und Breiten-/Höhen-Cache je (Font, PPI, Text) nach dem Muster `TPPGCustomRibbon.TextWidth`. | klein (DC) / mittel (Cache) | mittel–hoch |
| 5 | `PPG.Render.GdiPlus.pas:534–618` | GDI+-Text/Bild im Block: `GdiBegin` verschachtelbar (Zähler, HDC wiederverwenden); ItemPainter, Kanban, TileView, Ribbon, Menus zeichnen je Eintrag in einem Block. Dazu Abkürzung `FillRoundRect` mit Radius ≤ 0 → `FillRectangle` ohne Pfad (`:259`). | mittel | mittel |
| 6 | `PPG.Render.Gdi.pas:92–197` | Cache getönter Icons (Schlüssel ImageList, Index, Farbe, Größe; geleert bei `ImageList.OnChange`/Theme). | mittel | mittel |
| 7 | `Base:2045–2068` | Schatten als Neun-Teile-Bitmap cachen (Size, Offset, Farbe, Deckkraft, Radius, PPI). | mittel | gering–mittel |

## 8b Gezielt neu zeichnen (nach 8a #1)
**Unnötige Invalidates ganz vermeiden** (wirkt schon vor 8a #1): Planner-Drag nur bei geändertem Ghost (`Planner:4154`), Menü-Scroll nur bei geändertem `FScrollY` und Schleife am Rand stoppen (`Menus:757`), NavigationView/ToolBar-`MouseUp` nur bei Änderung (`:1694`, `:1308`), Breadcrumb-`MouseUp`.

**`InvalidateRect` alt ∪ neu statt `Invalidate`:** Grid `SetHotRow` (`:4092`) und `MoveFocus` (`:5326`, ohne Scroll/Bereichsauswahl), ItemList-Hover (`:1294/1507`, damit ListBox/TreeView/CheckListBox), Kanban-Hover (`:2940/3003`) und -Drag (mitlaufende Karte; voll nur bei Zielwechsel), Planner-Hover (`:4247/4270`), Chart-Tooltip (`:2576`), Ribbon `SetHot` (`:3524`), NavigationView (`:1680/1709`), ToolBar (`FRects`, `:1292/1321`), TabControl/TabStrip (`:909/928`, Indikator-Animation), MenuBar `SetHot` (`:411`), StatusBar-Paneltext.

## 8c Grid (1 Mio. Zeilen)
| # | Stelle | Fix | Aufwand | Nutzen |
|---|---|---|---|---|
| 1 | `PPG.Grid.pas:1467–1492`, `PPG.Grid.View.pas:224–284` | **Sortierschlüssel vorberechnen** (IsNum, Double, Text) einmal je Zeile, Vergleich auf dem Array mit identischer Logik (stabil, gleiche Reihenfolge); mit `OnCompareCells` bleibt der alte Weg. | klein–mittel | sehr hoch (~10–30×) |
| 2 | `:986–1017`, `PPG.Grid.Columns.pas:330/437` | **Spaltenbreite ziehen ohne Aggregate:** `AggregatesChanged` nur bei echter Aggregat-/Format-Änderung (Signatur); doppeltes `InvalidateGeometry` weg. | klein | hoch (Ruckeln weg) |
| 3 | `:1456–1465` | Filtertexte einmal je Lauf in Großbuchstaben. | sehr klein | mittel |
| 4 | `PPG.Grid.Styles.pas:247–278` | `ComputeStats`: Min/Max in O(n), Oben/Unten-N per Quickselect, Kopie nur dafür. | klein | mittel |
| 5 | `:149/1299–1312/3856–3866`, `PPG.RowLayout.pas:101–116` | **RowHeights dünn** (nur abweichende Höhen), `EnsureGeometry` über k Einträge; Spalten- und Zeilengeometrie getrennt invalidieren. Streaming und Einfügen/Löschen ziehen mit. | mittel | hoch, sobald RowHeights benutzt werden |
| 6 | `:1331–1380/2968–3103` | **Aggregate inkrementell** bei Einzeländerung (Count/Sum mit Kahan-Summe; Min/Max nur aufbauend, sonst voll; Gruppe + Eltern; Custom, Gruppenspalte, CondStats → voll). | mittel | hoch beim Bearbeiten |
| 7 | `:1918/1494`, `View.pas:611` | Filterergebnis beim reinen Umsortieren wiederverwenden (Filter-Signatur + Datenversion; virtueller Modus: Versionszähler bzw. `Refresh`); Summen ohne Gruppen bleiben. | mittel | hoch beim Umsortieren |
| 8 | `:4415–4473/4606/4671` | Deckende Flächen per GDI im bestehenden Block, Zeilenspannen zusammenfassen, Auswahl vorgemischt. | mittel | mittel (Scroll/Hover) |
| 9 | `PPG.Grid.CellKinds.pas:152–197/418` | Zellarten-Texte über `FPainter.AddText`/`FlushTexts`; Messcache je Paint statt `GetDC(0)`. | mittel | mittel |
| 10 | `PPG.ElementStyle.pas:552–634`, Grid `:4990/5067` | Font-Cache über Paints behalten; leeren bei Font-, Stil-, DPI-, Theme-Änderung. Gleiches im Planner (`FFonts.Clear` `:2767/3252`). | klein | gering–mittel |
| 11 | `PPG.Grid.Data.pas:429–435` | Geometrisches Wachstum (Capacity) im Zellspeicher. Flaches Zellarray: **nicht** in diesem Paket. | sehr klein | gering |
| 12 | Grid-Paint | `GetCellText` je Zelle nur einmal je Paint (Zeilenpuffer), wichtig im virtuellen Modus. | mittel | mittel |

## 8d Listen und Baum
| # | Stelle | Fix | Aufwand | Nutzen |
|---|---|---|---|---|
| 1 | `PPG.CheckListBox.pas:384` | `CheckAll` mit `ItemsEx.BeginUpdate` (O(n²) → O(n)). | sehr klein | hoch |
| 2 | `PPG.Controls.ItemList.pas:553/501/587`, `PPG.ItemPainter.pas:183/471` | `MeasureItem` nutzt die einmal berechnete Standardhöhe; `TextLineHeight` je (Font, PPI) gecacht. | klein | hoch (Gruppenlisten bis 200 000 Messungen → 1) |
| 3 | `PPG.TreeView.pas:2615/2655` | `AlphaSort` als stabiler Merge-Sort mit vorberechneten Schlüsseln (ohne `PPGStripMarkup` je Vergleich). | klein | hoch |
| 4 | `PPG.TreeView.pas:686/901/915` | Geschwister-Index `FIndex` je Knoten (bei Insert/Delete/Move/Sort ab Position neu nummeriert): `Items[]`-Schleife O(n²) → O(n), `PaintLines` ohne lineare Suche. | mittel | hoch bei breiten Ebenen |
| 5 | `:2191/2166/2197` | AutoCheck: in der Update-Klammer nur Eltern merken, einmal bei `EndUpdate` rechnen. | klein | mittel |
| 6 | `:1707/1612` | Ohne Update-Klammer Zeilen lazy neu aufbauen (`FRowsDirty` + PostMessage); jeder Zugriff auf Zeilen (`RowOfNode`, `NodeOfRow`, Selected, Scroll) baut vorher synchron nach → Verhalten für Aufrufer gleich. | klein–mittel | mittel |
| 7 | `PPG.Markup.pas:442/520/548` | Markup-Fonts und DC je Instanz behalten, nur bei geänderter Grundschrift verwerfen. | klein | mittel–hoch (Listen mit Markup, Kanban, Hints, TileView) |
| 8 | `PPG.ListBox.pas:646/661` | `ScanItemsEx` inkrementell bei Einzeländerung. | klein | mittel |
| 9 | `PPG.Selection.pas:420/428/455` | `FSingle` im Einzelmodus (`ItemIndex` O(1)); Insert/Delete bei `SelCount = 0` nur Größe. | klein–mittel | mittel |
| 10 | `PPG.ComboBox.pas:683/660/558` | `ItemsEx.Add` nur anhängen (Notify mit Index). | klein–mittel | gering–mittel |

## 8e Chart, Kanban, Planner, Ribbon, Rest
| # | Stelle | Fix | Aufwand | Nutzen |
|---|---|---|---|---|
| 1 | `PPG.MenuBar.pas:378/401/580` | **ItemRects cachen** (ungültig bei Menü-, Font-, PPI-, Größen-, RTL-Änderung; MDI-Merge beachten). | mittel | **hoch** (O(n²) DC-Messungen je Mausbewegung) |
| 2 | `PPG.Chart.pas:921/1646/2348/891/2880` | **Layout cachen** zwischen Paint und HitTest (ungültig bei Daten, Größe, Font, PPI, Achsen, Legende, Sichtbarkeits-Animation); Barrierefreiheits-Kinder nicht O(N²). Frame-Bitmap: nicht in diesem Paket. | mittel | hoch (Hover) |
| 3 | `PPG.Planner.pas:3135/3158/3207` | Zeitleiste zeichnet nur den sichtbaren Bereich (bis 105 000 Füllungen je Frame). | klein | **hoch** (Scrollen) |
| 4 | `PPG.Planner.pas:1750/1919/1615` | Vorkommen einmal nach [Gruppe][Tag] verteilen, Ressource per Dictionary. | mittel | mittel (Layout) |
| 5 | `PPG.Kanban.pas:686/861/1688` | Höhen-Cache nur für die geänderte Karte leeren (Breite in den Schlüssel). | klein–mittel | mittel–hoch |
| 6 | `PPG.Kanban.pas:1900–2055` | Messwerte je Karte (Labels, Titel-Layout) mit dem Höhen-Cache halten. | mittel | mittel |
| 7 | `PPG.Ribbon.pas:1757`, `PPG.Ribbon.Items.pas:746/1058` | `TextHeight` cachen; `Enabled`/`Down` (Action-Update im Idle) ohne Neuaufbau des Layouts – eigener Pfad `StateChanged`. | mittel | mittel–hoch |
| 8 | `PPG.TabStrip.pas:435/968`, `PPG.PageControl.pas:542` | Reiterbreiten cachen, `MakeVisible` ohne Layout-Schleife, `BeginUpdate`/`EndUpdate` für Seiten (InsertPage/Remove/Move ohne N Neuaufbauten). | mittel | mittel |
| 9 | `PPG.Feedback.pas:1444/1065/1028` | InfoBar: volle Höhe einmal je (Breite, Text, Font, PPI, Stil), Frame = Anteil davon. | klein–mittel | mittel |
| 10 | `PPG.TeachingTip.pas:1267/783` | Reposition mit Pending-Flag, `ContentChanged` ebenfalls gebündelt. | klein | mittel |
| 11 | `PPG.Chart.Series.pas:548` | `ChartDataChanged` bündeln (Flag + PostMessage), `AddRange`. | klein–mittel | mittel |
| 12 | `PPG.AppHooks.pas:93/114/255` | Beobachterliste copy-on-write statt `Copy` je Nachricht (nach 8.0 #1). | klein | gering–mittel |
| 13 | `PPG.DB.Kanban.pas:521/535` | `RenumberCell` in einem Durchlauf (Dictionary Id→Soll), nur Abweichungen editieren. | klein–mittel | mittel |
| 14 | `PPG.TagEdit.pas:647` | Chipbreiten cachen. | klein | gering |

## Nicht in diesem Paket
Flaches Zellarray im Grid, Frame-Bitmap im Chart, globale Markup-Font-LRU, Umbau der Vergleichslogik des Grids (nicht transitiv, bleibt wie sie ist).

## Tests
- Je Punkt ein Test, der das **Verhalten** festhält (gleiche Sortierreihenfolge, gleiche Summen, gleiche Treffer, gleiche Zeilenhöhen), wo möglich vorher gegen den alten Code grün; neue Testgruppen `Audit8A`–`Audit8D`.
- Wo es messbar ist, ein Zähltest statt Zeit: Anzahl `PPGMeasureTextNoCanvas`-DCs, Anzahl Layouts je Mausbewegung, Anzahl Paints/Invalidierungen je Hover, Timer-Wakeups im Leerlauf (über vorhandene Testhaken bzw. einen Zähler hinter dem bestehenden Haken-Muster).
- Sichttests: Galerie und Referenzbilder müssen nach 8a #1 pixelgleich bleiben (Glow, Fokus, RTL, Dark, Hochkontrast); Demo per Hand ansehen.
- Benchmark: alle alten Vorgaben weiter eingehalten; neue Messungen mit Vorher/Nachher in `Tests\Bench\Messung-nach-Paket8.txt`; neue Vorgaben ≈ 2× Nachher-Wert.

## Reihenfolge und Commits
8.0 (AppHooks, Benchmark mit Vorher-Werten) → parallel in vier Worktrees: **A** 8a + 8b (Basis, Scroll, Animator, Render, Invalidierung), **B** 8c (Grid), **C** 8d (Listen, Baum, Markup, Selection, ComboBox), **D** 8e (Chart, Kanban, Planner, Ribbon, MenuBar, Tabs, InfoBar, TeachingTip, DB-Kanban) → zusammenführen → Benchmark-Nachher, Gesamtprüfung. Je Gruppe ein Commit. 8b-Stellen in Grid/Kanban/Planner/Ribbon macht der jeweilige Bereichs-Agent (B/D) nach dem Clip-Umbau von A; dafür wird A zuerst zusammengeführt.

## Verifikation
- `Build\check-rules.ps1`, `build.ps1` (alle sechs Projekte, Win32; Tests auch Win64)
- `Tests\PPGlowTests.exe` und `/leaks`, Win32 und Win64
- Benchmark `build.ps1 -Projects Bench -Config Release`, Vorher/Nachher
- Demo `/selftest`, Galerie ansehen
- Nichts installieren.

## Entscheidungen (User, 09.10.2026: alle vier wie empfohlen)
1. **Clip-Box mit zwischengespeichertem Rückpuffer (8a #1):** jetzt mit? Das ist der größte Hebel, aber auch der riskanteste Eingriff in die Basis und lockert die Regel „keine dauerhaften GDI-Handles pro Control“ (ein Puffer-Bitmap je sichtbarem Control). Empfehlung: **ja**.
2. **Grid RowHeights dünn + Aggregate inkrementell (8c #5/#6, mittleres Risiko):** jetzt mit? Empfehlung: **ja**, mit festhaltenden Tests zu Gruppen, Filter und Streaming.
3. **TreeView lazy Zeilenaufbau (8d #6):** ändert intern das Timing, nach außen gleich. Empfehlung: **ja**.
4. **Neue Benchmark-Vorgaben ≈ 2× Nachher-Wert** (strenger als heute, fängt künftige Rückschritte). Empfehlung: **ja**.
