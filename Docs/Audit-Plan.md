# Audit 08.10.2026 – Befunde und Plan zur Behebung

*Gesamtprüfung des Repos durch neun parallele Prüf-Agenten (nur gelesen): Speicher/Lebensdauer, Exceptions/Robustheit, Properties/Streaming, UI/UX, Performance, Architektur/Codequalität, Kompatibilität XE2–13/Win64, DB-Controls/Designer, Tests/Build/Repo/Demo/Doku. Ausgenommen waren die Dateien, an denen gerade gearbeitet wurde (Phase 18: `PPG.RadioGroup.pas`, `PPG.Tests.Phase18.pas`, `Docs/Phase18-Plan.md`, `NAECHSTE-SCHRITTE.md`, Demo-EXE). Jeder Befund wurde vom jeweiligen Agenten an der genannten Stelle im Code nachgelesen; Zeilennummern beziehen sich auf den Stand von Commit 8fdce8e und können durch Phase 18 verrutschen.*

## Gesamtbild

Solide: Win64 (NativeInt/LRESULT, `SetWindowLongPtr`), GDI/GDI+-Ressourcen (eigenes try/finally je Handle), Übersetzungsdisziplin (`PPGStr`, ~170 resourcestrings), Absicherung der Sprachmittel für XE2, Registrierung und Symbole aller 76 Paletten-Controls, DataLink-/FreeNotification-Grundlagen, DPI über `PPGScale`, abschaltbare Animationen, Paket-Gleichheit XE2/Delphi 13, `check-rules.ps1` ohne Verstöße.

Die Befunde ballen sich in drei Mustern:
1. **Veraltete Referenzen nach Anwender-Ereignissen** – ein Handler löscht oder ändert das eigene Element, danach Zugriffsverletzung oder falsches Element.
2. **Mehrfach umgesetzte Logik, die auseinanderläuft** – Dropdown (3×), DB-Bindung (10×), Mausrad, Kontrastfarbe, Hochkontrast, Tippsuche.
3. **Ganzes Control statt Ausschnitt zeichnen, Messen ohne Cache** – `Paint` ignoriert die Update-Region, fast nur `Invalidate`, `PPGMeasureTextNoCanvas` erzeugt je Aufruf einen DC.

## Entscheidungen (User, 08.10.2026)

| # | Frage | Entscheidung |
|---|---|---|
| 1 | Repo-Bereinigung (Artefakte aus dem Index, History verkleinern) | **Nicht jetzt.** Paket 0 bleibt zurückgestellt. |
| 2 | Einheitliche Benennung über alle Komponenten | **Ja.** Umsetzung in Paket 5c; alte Namen bleiben per `DefineProperties` lesbar, damit bestehende DFMs laden (Vorschlag, beim Start von 5c bestätigen). |
| 3 | Abweichende VCL-Defaults | **PPG-Defaults behalten**, `migrate.ps1` schreibt die VCL-Werte ausdrücklich (Paket 6). |
| 4 | Reihenfolge zu Phase 18 | **Wie vorgeschlagen:** Pakete 1, 2, 3, 6 sofort (berühren kaum Phase-18-Dateien), 7, 8, 9 nach Phase 18. |

## Reihenfolge

| Schritt | Paket | Umfang | Wann |
|---|---|---|---|
| 1 | 1 Abstürze und Datenverlust | mittel | sofort |
| 2 | 2 Fehlergrenzen, Zahlen, Lebensdauer | mittel | sofort |
| 3 | 3 Dateiformate und Export | mittel | sofort |
| 4 | 6 Migration | klein | **vor der Umstellung des Kundenprojekts** |
| 5 | 4 DB-Controls (zusammen mit 9a) | mittel | danach |
| 6 | 5 Properties, Objektinspektor, Benennung | groß | danach |
| – | 11 Tests, Build, Demo, Doku | mittel | parallel zu jedem Paket |
| 7 | 7 UI/UX-Konsistenz | groß | nach Phase 18 |
| 8 | 8 Performance | groß | nach Phase 18 |
| – | 10 XE2 | klein | jederzeit, prüfbar erst mit XE2 |
| 9 | 9 Architektur-Refactoring | sehr groß | langfristig, schrittweise |
| – | 0 Repo-Hygiene | klein | zurückgestellt (Entscheidung 1) |

**Ablauf je Paket:** Regressionstest zuerst (zeigt den Fehler), dann Fix, dann Build Win32 + Win64, `/leaks`, Demo-Selbsttest, ein Commit pro Paket (bei großen Paketen pro Unterpunkt). Dateien, an denen Phase 18 gerade arbeitet (`PPG.Reg.pas`, `.dpk`, neue Units), nur nach Absprache anfassen.

---

## Paket 1 – Abstürze und Datenverlust

### 1a Einzelfehler

| Stelle | Problem | Fix |
|---|---|---|
| `PPG.Planner.pas:3514-3515` | **Kritisch:** `DeleteSelected` liest `Occ.Appointment.ResourceId` nach `DoDeleteAppointment(A)` (= `A.Free`). Jedes Entf auf einem einfachen Termin. | `ResourceId` vorher sichern. |
| `PPG.Planner.pas:3313`, `:3610-3627` | `FEditAppt`/`FSelAppt` bleiben nach Reload/Löschen stehen; `EndEditSubject` greift auf freigegebenen Termin zu (DB-Planner `Reload` gibt Termine frei, `PPG.DB.Planner.pas:397/497`). | In `AppointmentsChanged` bzw. bei `cnDeleting` Editor abbrechen, Zeiger auf nil. |
| `PPG.DB.Planner.pas:563` (mit `:444`) | Neue Termine bekommen Id aus `FNextId` (zählt nur geladene Sätze); `LocateKey`+`Edit` überschreibt einen fremden Satz. | Neue Termine per `Append`, Schlüssel vergibt die Datenbank. |
| `PPG.DB.Planner.pas:561-562`, `:574-576` | `if DS.State in dsEditModes then DS.Post` speichert fremde offene Eingaben; nach Fehler `Cancel; raise` ohne Reload → Oberfläche und DB laufen auseinander. | Bei fremdem Edit-Zustand abbrechen; nach Fehler neu laden. |
| `PPG.DB.Kanban.pas:516-541`, `:494-498` | `CardMoved`: `Edit`/`Post` ohne try/except; `LocateKey` ohne `dsEditModes`-Prüfung postet fremde Eingaben. | Zustand prüfen, bei Exception `Cancel` + `Reload`. |
| `PPG.DB.Kanban.pas:377/454`, `PPG.DB.Planner.pas:447` | Null-/Doppel-Schlüssel: `AsInteger` → 0, Sätze fallen zusammen; `Card.Index := I` läuft über `Cards.Count`. | Null-Schlüssel überspringen, Rows entdoppeln, Index begrenzen. |
| `PPG.DB.Grid.pas:785`, `:1223` | Offener Editor bleibt beim Datensatzwechsel stehen; Eingabe landet im neuen Satz oder geht verloren. | In `DataChanged` Editor verwerfen/neu laden, wenn ActiveRecord/Bookmark wechselt. |
| `PPG.DB.Grid.pas:924-927` | `EnsureSnapshot` (Druck/Export) ruft `DS.First` im Edit-Zustand → postet still oder `EDatabaseError`. | Bei `dsEditModes` mit PPG-Exception ablehnen. |
| `PPG.DB.Grid.pas:660` (mit `PPG.Grid.pas:1108`) | `dgTitles` einschalten bei leerer Datenmenge: `FixedRows := 1` vor `RowCount`-Wachstum → `EPPGPropertyError`, `FDBOptions` schon gesetzt. | Vorher `RowCount := Max(RowCount, FixedRows + 1)`. |
| `PPG.Grid.pas:5952-5969`, `PPG.DB.Grid.pas:1237` | Editor wird vor `SetCellByUser` geschlossen; wirft das Schreiben („abc“ in Integer), ist die Eingabe weg. | Erst schreiben, dann ausblenden; bei Exception Editor wieder zeigen. |
| `PPG.Grid.pas:5944-5949` | Nach abgelehnter Validierung bleibt der Editor offen; `SortBy`/`GroupBy`/`LoadLayout`/`MoveColumn` bauen trotzdem um → Wert landet in anderer Zeile (`FEditV` ist Ansichtszeile). | Umbauende Aufrufer abbrechen solange `EditorMode`, oder Editor auf Datenzeile/-spalte merken. |
| `PPG.Grid.pas:2537` | `LoadLayout` prüft `MinColWidth..10000`, `SetColWidths` erlaubt 0 → Exception mitten im Laden, Rest fehlt. | Beim Laden klemmen (wie Kanban/Planner). |
| `PPG.Grid.pas:727/735` | `FixedRows` wird vor `RowCount` gestreamt → DFM mit RowCount=20, FixedRows=6 lädt mit 4. | `RowCount` vor `FixedRows` publishen oder beim Laden ungeprüft übernehmen und in `Loaded` klemmen. |
| `PPG.ComboBox.pas:531/606/618` | `Sorted` mit `ItemsEx`: Indizes von Items und ItemsEx laufen auseinander; `FItems[Index] :=` auf sortierte Liste wirft `EStringListError`. | Sortierung auf ItemsEx anwenden, FItems immer über `SyncItemsFromEx`. |
| `PPG.CheckComboBox.pas:436-446` | Haken hängen am Index; nach Insert/Delete/Sort an falschen Einträgen, `CheckedText` und DB-Wert verfälscht. | Haken je Eintrag (z. B. Objects) oder per Text sichern und neu zuordnen. |
| `PPG.CheckComboBox.pas:245/258` | Items ändern sich bei offenem Popup → `PaintRow` wirft (`EStringListError`). | Map neu bauen oder Popup schließen; Grenzen prüfen. |
| `PPG.Planner.pas:822/108` | `TPPGPlannerResource.Id` ohne Vergabe, `default 0` → alle Ressourcen aus dem Collection-Editor haben Id 0. | Fortlaufende Id wie bei Kanban-Spalten. |
| `PPG.Kanban.Items.pas:599` | `TPPGKanbanCard.Assign` kopiert `FId` nicht; `Cards := X` nummeriert neu, Druck liefert andere Ids. | Ids nachziehen wie `TPPGAppointments.Assign`. |
| `PPG.TabControl.pas:487`, `PPG.TabStrip.pas:190/1103-1117` | `FStrip.Images` ist Kopie ohne FreeNotification; nach Freigabe der ImageList liest Paint freigegebenen Speicher (Tab- und PageControl). | `ImagesChanged`-Hook in der Basis (siehe 1b), Strip nachziehen. |
| `PPG.Labels.pas:370-380/542`, `PPG.Markup.pas:518/550-556/667` | LinkLabel: Markup-Layout hält `FImages`; Freigabe der Liste setzt `FLayoutValid` nicht zurück. | `FLayoutValid := False` im Hook. |
| `PPG.DB.Chart.pas:172-176/403`, `PPG.DB.Planner.pas:222-226/493`, `PPG.DB.Kanban.pas:187/435` | Jedes `deDataSetChange` (auch aus fremdem `EnableControls`) lädt komplett neu; zwei solche Controls an einer DataSource laden sich gegenseitig endlos. | Nur bei echten Änderungen laden (globaler Lesezähler aller PPG-Links bzw. Vergleich RecordCount/State/Bookmark). |

### 1b Basis-Hook für Images
`TPPGCustomControl` bekommt ein virtuelles `ImagesChanged`, aufgerufen aus `SetImages`, `Notification(opRemove)` und `ImageListChange`. TabControl/PageControl und LinkLabel überschreiben es.

### 1c Musterfix „Referenz nach Anwender-Ereignis prüfen“

| Stelle | Fehlerfall | Fix |
|---|---|---|
| `PPG.PageControl.pas:714-716` | OnClose ruft `Page.Free` → AV bzw. doppeltes Free mit caFree. | Nur weiter, wenn `FPages.IndexOf(P) >= 0`. |
| `PPG.TabControl.pas:1271` | OnClose löscht selbst + caFree → Nachbar wird mitgelöscht, beim letzten `EStringListError`. | Nach Events `Index < FTabs.Count` erneut prüfen. |
| `PPG.MenuBar.pas:411-415` | OnClick baut Menü um (MDI-Merge) → AV in `ItemRect`/`OpenPopup`. | `(Index < ItemCount) and (Item(Index) = It)` prüfen. |
| `PPG.ToolBar.pas:967`, `PPG.Ribbon.pas:3346/3408` | Handler löscht eigenes Item → OnItemClick/`ShowItemMenu` mit freigegebenem Item. | Vor Folge-Event Mitgliedschaft in der Collection prüfen. |
| `PPG.Ribbon.pas:3727` (mit `:1591-1607`, `:894ff`) | Galerie offen, Item wird gelöscht → AV in Paint/Maus des Popups. | In `LayoutChanged`/`RibbonModelChanged` `CloseGalleryPopup`. |
| `PPG.Breadcrumb.pas:489` | Handler setzt neuen Pfad, danach wird er auf alten Index gekürzt. | Vor dem Event kürzen. |
| `PPG.Controls.ItemList.pas:401-415` (mit `:1240/1354`), `PPG.CheckListBox.pas:549` | OnClick/OnClickCheck ruft `Items.Clear`, Anwender zieht weiter → `FItems.Move` wirft. | In ItemsDeleted/Reset `CancelDrag`, `FDownIndex := -1`; in `DoDropAt` Grenzen prüfen. |
| `PPG.Kanban.pas:537-549/2251` | Reload während Drag → falsche Karte verschoben und in DB geschrieben. | Bei `FDragging` `EndDrag(False)` oder Karte per Id merken. |
| `PPG.Menus.pas:1737-1744/1827-1832` | Menü wird während `RunModal` freigegeben → `FLoop := nil` und `DoClose` auf freigegebenem Self. | Destroy-Flag/lokaler Zeiger, nach `RunModal` sofort aussteigen. |
| `PPG.TreeView.pas:1261-1273/1289-1300` | `OnDeletion` sieht bereits freigegebene Kinder in `FChildren`/`FRoots`, `FCacheNode` veraltet. | Kind vor Free aus Liste entfernen, `FCacheNode := nil` vor Callbacks. |
| `PPG.Popup.pas:1057`, `PPG.NavigationView.pas:2081/2201`, `PPG.TagEdit.pas:982` | Accessibility-Aktion postet Index; Liste ändert sich bis zur Verarbeitung → falscher Eintrag. | Identität posten bzw. vor Ausführung prüfen. |
| `PPG.ToolBar.pas:756`, `PPG.ComboBox.pas:536` | `ItemsChanged` setzt `FDownPart`/`FHotPart` nicht zurück; ComboBox baut bei aktivem Filter die Popup-Map nicht neu. | Zurücksetzen bzw. neu bauen. |

Dazu: Regel in `Docs/Coding-Rules.md` („nach jedem Anwender-Event Index/Objekt neu validieren“) und ein Testmuster „Handler löscht das eigene Element“ je betroffenem Control.

---

## Paket 2 – Fehlergrenzen, Zahlen, Lebensdauer

### 2a NaN/Inf und Wertebereich (zentrale Hilfe `PPGCheckFinite`)
- `PPG.Chart.pas:1329-1335/1346/1377/2480/2531` – NaN übersteht die Klemmung, `Round(NaN)` wirft auch in MouseMove → HitTest → PointPos; Kreis mit `Total = NaN`. Nicht endliche Punkte überspringen.
- `PPG.Sparkline.pas:268/286-301/527/538` – NaN/Inf macht Lo/Hi zu NaN, `PPGDrawSparkline` (auch Grid-Zellen) wirft. Ablehnen oder überspringen.
- `PPG.Gauge.pas:569-576/595/608/703` – `Value := NaN` bzw. `SetMin(NaN)` akzeptiert. In Settern prüfen.
- `PPG.Rating.pas:157-159` – `Value := 1e20` → `EInvalidOp`.
- `PPG.Chart.Scale.pas:274-337` – Datumsskala klemmt nicht auf 1..9999 → `EConvertError` (z. B. Unix-Zeitstempel).
- `PPG.NumberEdit.pas:436/444/598` – Double wird auch bei `nkFloat`/`nkInteger` nach `Currency` gewandelt → `EInvalidOp` ab ±9,2e14 oder bei NaN. `Currency` nur bei `nkCurrency`, vorher prüfen.
- `PPG.NumberEdit.pas:635-641/691-692/501-514` – OnChange feuert bei `FEditing = True`; Bild auf/ab rechnet `Round(LargeIncrement/Increment)`; Min > Max ungeprüft.

### 2b Fehlergrenzen
- `PPG.ErrorHandler.pas` (`LogWarning`/`LogInfo`, ~Z. 150) – ungeschützt, werden aber in Fehlergrenzen aufgerufen (`PPG.Accessibility.pas:477`, `PPG.UIA.pas` Fail, `PPG.Controls.Base.pas:1856`). Gleiche try/except-Grenze wie `NotifyError`.
- `PPG.Hints.pas:731-738` – `TPPGCustomHint.PaintHint` ruft `HandleCallbackError` im Paint → Dialog bei jedem WM_PAINT; `:511-525` verwirft Exceptions ganz. Wie Basis: einmal `ReportPaintError`, Notfall-Zustand zeichnen.
- `PPG.MenuBar.pas:886-890`, `PPG.Menus.pas:1208-1209/1374` – `AccChildDoDefault` führt Anwender-Code synchron im COM-Aufruf aus. Per PostMessage verlegen; in `OpenSubmenu` nach `It.Click` `if not FActive then Exit`.
- Ungefilterte `except`: `PPG.Controls.Scroll.pas:191`, `PPG.DB.Grid.pas:894-897`, `PPG.Markup.pas:370`, `PPG.Print.pas:469`. Konkrete Klassen filtern oder per `LogWarning` protokollieren.
- `PPG.Reg.pas:535/560-566` – `ExecuteVerb` von TaskDialog- und GridPrinter-Editor ohne Exception-Grenze.

### 2c Beim DFM-Laden klemmen statt werfen (`PPGCheckRange`)
`PPG.NumberEdit.pas:517-527` (Increment/LargeIncrement), `PPG.Gauge.pas:763`, `PPG.PasswordEdit.pas:209` (`PasswordChar = #0`), CheckComboBox `Delimiter = #0`, `PPG.Print.pas:43-56/275` (`TPPGPrintMargins` braucht `GetOwner`, sonst erkennt `PPGIsLoading` das Laden nicht).

### 2d Bereichsprüfungen Min ≤ Max (gegenseitig prüfen, in `Loaded` klemmen)
`PPG.DatePicker.pas:642-650`, `PPG.Calendar.pas:741-751` (Date wird nicht geklemmt), `PPG.Chart.Series.pas:851-867` (Achse), `PPG.Sparkline.pas:637-653`, `PPG.Planner.pas:1129/1135` (WorkStart/End), `PPG.Planner.Print.pas:53` (PrintFrom/To), `PPG.Grid.Columns.pas:95-100` (MinValue/MaxValue).

### 2e Lebensdauer und Ressourcen
| Stelle | Problem | Fix |
|---|---|---|
| `PPG.Notifications.pas:693-695/963-1002` | Ausgeblendete Toasts nur per PostMessage zur Freigabe vorgemerkt; `DeallocateHWnd` verwirft sie → Leak. | Ausstehende per `PeekMessage(PM_REMOVE)` abholen oder Pending-Liste; Zustand vor `FOnClose` setzen. |
| `PPG.Print.pas:638-654` | `PageMetafile`: wirft `RenderPage`, ist das Metafile verloren (je Vorschau-Paint). | try/except bis `FCache.Add`. |
| `PPG.Splitter.pas:148-155/390-399` | `HideLine` im Destroy nutzt `Parent.Handle`, Parent ist dann nil → AV, DC bleibt. | Fensterhandle beim `GetDCEx` merken. |
| `PPG.Splitter.pas:163` | Ziel-Control wird während des Ziehens freigegeben → `HideLine` fehlt. | In Notification `HideLine`. |
| `PPG.Grid.Print.pas:232-236` | `FSource` (Grid als Interface) ohne FreeNotification. | Bei Komponente FreeNotification setzen. |
| `PPG.AppHooks.pas:114-118`, `PPG.Menus.pas:317-321` | Singletons werden nach Finalisierung neu angelegt. | `GFinalized`-Sperre wie `PPG.Animation`. |
| `PPG.Button.pas:632-640`, `PPG.Controls.Base.pas:955-968` + `PPG.Ribbon.pas:1331-1343`, `PPG.TeachingTip.pas:1243-1254` | `RemoveFreeNotification` auf Komponenten, die noch anders referenziert werden (PopupMenu, LargeImages, Target) → hängende Zeiger. | Nur entfernen, wenn keine zweite Referenz (wie `PPG.Edit.pas:238`). |
| `PPG.Items.pas:479-494` | `TPPGStringsSource` hält rohen `TStrings`-Zeiger und greift im Destroy darauf zu. | `Detach` anbieten, Lebensdauer dokumentieren. |
| `PPG.ColorPicker.pas:563-595` | `FSVBitmap`/`FHueBitmap` halten GDI-Handles dauerhaft (Regelverstoß). | Beim Schließen des Popups freigeben. |
| `PPG.Dialogs.pas:821` | Eigenes `TTimer` (Regel: nur Animator). | Auf `TPPGAnimation.StartLoop`. |
| `PPG.Rating.pas:367-374` | `CreateSolidBrush`/`CreatePen` ohne eigenes try/finally. | Je Handle try/finally. |
| `PPG.Xlsx.pas:266-270` | `TXmlOut.Destroy` ruft `Flush` (kann werfen, überdeckt erste Exception). | Flush explizit vor Free. |
| `PPG.Wizard.pas:1022` | `Back` ohne aktive Seite springt auf die letzte Seite. | `FActivePage = nil` prüfen. |

---

## Paket 3 – Dateiformate und Export

| Stelle | Problem | Fix |
|---|---|---|
| `PPG.Xlsx.pas:104-110` | `PPGExcelSerial`: reine Uhrzeit 0,5 wird −0,5 → Excel `#####`; Gegenstück `PPGFromExcelSerial` macht 31.12.1899. | `0 <= D < 1` unverändert. |
| `PPG.Xlsx.pas:553-559` | NaN/Inf als `<v>NAN</v>` → „unlesbarer Inhalt“. | Leere Zelle oder Text. |
| `PPG.Xlsx.pas:1300-1395` | Reader: Zellen ohne `r`-Attribut verworfen; Inline-Strings mit mehreren `<r>` behalten nur den letzten Lauf. | Position mitzählen, Läufe anhängen. |
| `PPG.Xlsx.pas:813` | `SUBTOTAL(…,A2:A1)` ohne Datenzeilen schließt Kopf ein. | Ohne Datenzeilen keine Formel. |
| `PPG.Grid.Export.pas:439-450` | CSV ohne BOM (Umlaute in Excel kaputt); Zellen mit `= + - @` werden als Formel ausgeführt. | BOM schreiben, solche Felder mit `'` maskieren. |
| `PPG.Grid.pas:6096` / `PPG.Grid.Export.pas:456` | CSV doppelt umgesetzt (`ToCSV` ohne Kopf). | `ToCSV` delegiert an `PPGExportCsvText`. |
| `PPG.Grid.Export.pas:66` | `HtmlEscape` ohne Steuerzeichen-Filter, doppelt zu `PPGXmlEscape`. | `PPGXmlEscape` verwenden. |
| `PPG.NumberFormat.pas:108-115`, `PPG.Grid.Data.pas:329`, `PPG.Grid.Styles.pas:189` | `PPGParseNumber` überspringt Buchstaben, `-` irgendwo macht negativ: „A-100“ → −100, „1e3“ → 13. Verfälscht Summen, Farbskala, Oben-N. | Strikter Parser für Statistik, Buchstaben nur als Präfix/Suffix. |
| `PPG.Grid.pas:1266/1308/2948-2956` | `ComputeCondStats` nur mit Summenspalten und nicht bei `CanGroup = False` → Formate veraltet, im DB-Grid nie wirksam. | Bei `NeedsStats` immer rechnen. |
| `PPG.Planner.ICal.pas:420-455` | DESCRIPTION unmaskiert in Markup-`Body`; VEVENT ohne `END` bleibt als leerer Termin. | `<`/`&` maskieren, offenen Termin verwerfen. |
| `PPG.DB.Grid.pas:950-953` | Export liest LargeInt/FMTBcd über `AsFloat`. | `AsLargeInt`/`AsBCD`. |
| `PPG.Grid.pas:5613/6760`, `PPG.Grid.Paint.pas:259` | Wahr-Wert `'Ja'` fest (und dreifach). | Nur `IsCheckedText`, Wahr-Werte konfigurierbar/übersetzbar. |
| `PPG.Kanban.pas:1657` | `FormatDateTime('dd.mm.', …)` fest. | Aus `FormatSettings` ableiten. |
| `PPG.TimePicker.pas:181/232` | Format `'hh:nn'` fest; `.` → `:` auch im AM/PM-Text („a.m.“ nie parsebar). | `ShortTimeFormat` nutzen, AM/PM vor Ziffernfilter entfernen. |

---

## Paket 6 – Migration (vor dem Kundenprojekt)

Entscheidung 3: PPG-Defaults bleiben, `migrate.ps1` gleicht aus.

- **Encoding:** `Build/migrate.ps1:185/329` lesen, `:409-410` schreiben ohne Encoding → ANSI-Umlaute werden U+FFFD. Encoding erkennen (BOM/ANSI) und beibehalten.
- **Sicherung:** `:404` überschreibt die `.bak` beim zweiten Lauf mit dem migrierten Stand. `.bak` nur anlegen, wenn nicht vorhanden.
- **VCL-Werte ausdrücklich schreiben**, wenn die DFM sie weglässt (VCL-Default ≠ PPG-Default):
  - TreeView: `ShowLines = True`, `RowSelect = False`, `HideSelection = True` (`PPG.TreeView.pas:352/360/361`)
  - Tab-/PageControl: `HotTrack = False` (`PPG.TabControl.pas:156`)
  - ProgressBar: `Smooth = False` (`PPG.ProgressBar.pas:81`)
  - `TabStop = False` bei RadioButton (`PPG.RadioButton.pas:83`), LinkLabel (`PPG.Labels.pas:183`), Calendar (`PPG.Calendar.pas:256`)
  - Splitter: `ResizeStyle = rsPattern`, `Width = 3` (`PPG.Splitter.pas:80/143`)
  - TabSheet: `ImageIndex = 0` (`PPG.PageControl.pas:74`)
- **Werte umsetzen:** Button `Style = bsSplitButton/bsPushButton` → `pbs…`; `bsCommandLink` melden (`PPG.Button.pas:33/100`).
- **Melden statt still verwerfen:** wirkungslose DBGrid-Optionen (`dgAlwaysShowEditor`, `dgAlwaysShowSelection`, `dgThumbTracking`, `dgMultiSelect`, `PPG.DB.Grid.pas:146-148/460-482`), entfernte `DoubleBuffered`/`OnMouseActivate`-Zeilen.
- **Umbenennungen aus Paket 5c** mit in die Abbildungstabelle aufnehmen.
- `Docs/Migration.md`: Tabelle aller Default-Abweichungen und Abbildungen.
- Tests in `Build/migrate-tests` für jeden Punkt (inkl. ANSI-Datei und zweiter Lauf).

---

## Paket 4 – DB-Controls

Am besten zusammen mit 9a (gemeinsame DB-Bindung), sonst ist jeder Fix 10-fach zu machen.

| Stelle | Problem | Fix |
|---|---|---|
| `PPG.DB.Controls.pas:419-450` | `TPPGDBEdit` übernimmt `MaxLength := Field.Size` und `Field.EditMask` nicht. | In DataChange/ActiveChange setzen. |
| `PPG.DB.Fields.pas:265/305`, `PPG.NumberEdit.pas:851-858/399` | DBNumberEdit: Art und Nachkommastellen nicht vom Feld; BCD gerundet, Integer als „5,00“, LargeInt > 2^53 ungenau. | Aus Feldtyp/Precision ableiten, über `AsLargeInt`/`AsBCD` schreiben. |
| `PPG.DB.Lookup.pas:206` | Mehrfachschlüssel (`'A;B'`) nicht unterstützt (Liste still leer), kein `NullValueKey`, fkLookup als DataField nicht abgefangen. | `FieldValues[]`/VarArray oder Fehlermeldung; NullValueKey. |
| `PPG.DB.Grid.pas:1218-1237` | Lookup-Felder als Freitext; unbekannter Text setzt KeyFields still auf Null. | Auswahl aus LookupDataSet oder Spalte schreibgeschützt. |
| `PPG.DB.Grid.pas:1232` | dsEdit erst beim Übernehmen des Editors (TDBGrid: erster Tastendruck). | `FDataLink.Edit` beim ersten Ändern. |
| `PPG.DB.Controls.pas:1250-1255/1305` | DBDatePicker ohne ShowCheckbox zeigt bei Null/leer das alte Datum. | Leerer/Platzhalter-Zustand. |
| `PPG.DB.Fields.pas:65-206` | Mask/Number/ColorPicker/CheckCombo/TagEdit ohne `ExecuteAction`/`UpdateAction`. | An `FLink` weiterreichen. |
| `PPG.DB.Lookup.pas:260-276` | `UpdateEditable` (privat) wird in DataChange nicht gerufen; ReadOnly bleibt anfangs True. | Protected machen, aufrufen. |
| `PPG.DB.Controls.pas:1115-1135` | TPPGComboBox kennt kein ReadOnly; DB-Combo/Lookup springen zurück. | Dropdown und Tippsuche bei `not CanModify` sperren. |
| `PPG.DB.Lookup.pas:97-101/220-249` | Listenmenge wird bei jedem DataSetChanged komplett gelesen, `First` postet offene Bearbeitung. | Wie 1a nur bei echten Änderungen, Edit-Zustand prüfen. |
| `PPG.DB.Controls.pas:1174-1348`, `PPG.DB.Fields.pas` | Esc ruft kein `Link.Reset`. | Wie DBEdit. |
| `PPG.DB.Grid.pas:593-601` vs `:628-630` | Persistente Spalten ohne `Field.Alignment`; keine Required-Markierung in keinem DB-Control. | Feldwerte nutzen, solange Spalte nichts setzt; optionaler Required-Hinweis. |
| `PPG.DB.Chart.pas:394-395/434` | Null als 0-Punkt; `RecNo :=` springt bei nicht sequenzierten Mengen nicht. | Lücke zeichnen, Bookmarks. |
| `PPG.DB.Kanban.pas:97ff` | Fehlen gegenüber TPPGKanban: `VirtualCardHeight`, `OnKeyDown`, `OnScroll`. | Ergänzen. |
| `PPG.DB.Grid.pas:183/821` | `ExportMaxRecords` ohne Prüfung; geerbtes `GroupIndex` wirkt nicht. | Prüfen; ausblenden. |

**Designer:**
- `PPG.DB.Chart.pas:215-218/289-291/365-395`, `PPG.Chart.Series.pas:655-658` – DBChart schreibt Designzeit-Daten (bis MaxRecords je Serie) als `ValuesText`/`Title` in die DFM. Bei gebundenen Serien `stored False`.
- `PPG.Reg.pas:950-954` – `RequiresUnits` für Grid/DBGrid fügt nur `Vcl.Grids` ein; `PPG.Grid.Styles` (OnGetCellStyle) und `Vcl.Menus` (OnHeaderMenu) fehlen → Handler kompiliert nicht.
- `PPG.DB.Reg.pas:213-237` – Feldauswahl für `TPPGDBChart.ValueFields` (`;`-Liste) und `TPPGDBGridColumn.FooterField` fehlt; FooterField-Setter ohne `Changed`.

---

## Paket 5 – Properties, Objektinspektor, Benennung

### 5a Streaming
- String-Startwert ≠ '' ohne `stored` (leer wird nicht gespeichert): `PPG.CheckComboBox.pas:120/413` (DisplayDelimiter), `PPG.TagEdit.pas:152/289` (Delimiters).
- Übersetzte Vorgabetexte landen in IDE-Sprache in jeder DFM, Laufzeit-Übersetzung greift nie: `PPG.Print.pas:109/357` (FooterText), `PPG.Gauge.pas:157/795` (ValueFormat), `:279/283` (KpiTile ValueFormat/ChangeFormat). `stored` gegen Vorgabetext plus Merker „bewusst leer“.
- `PPG.PasswordEdit.pas:115` – `Text` im Klartext in der DFM → `stored False`.
- `PPG.Expander.pas:354` – `ExpandedHeight default 0` greift nie (Getter liefert Height) → `stored`-Funktion.
- `PPG.ComboBox.pas:166/215` – `Items` doppelt gestreamt bei ItemsEx → `stored not UseItemsEx`.
- `PPG.Controls.Range.pas:57` – `Min` ohne `default 0` (in ProgressBar/TrackBar redeklarieren).
- `PPG.CheckBox.pas:23` – `Checked` nur public → mit `stored False` publishen; `PPG.DB.Controls.pas:174` `TPPGDBCheckBox.Checked stored False`.
- `PPG.Hints.pas:543` – HintManager ruft `Apply` im Konstruktor vor dem Lesen von `Active` → Hint-Fenster zweimal.
- `PPG.Ribbon.Items.pas:161/163`, `PPG.ToolBar.pas:113` – `Down` vor `GroupIndex` gestreamt, `GroupIndex` ohne Setter → zwei gedrückte Buttons einer Gruppe.
- `PPG.Ribbon.pas:1313/1131` – Backstage aus DFM wird beim Start nicht versteckt (im Code schon) → in `Loaded`.
- Published `Preset` ohne Prüfung bei Nicht-Controls: `PPG.Notifications.pas:163`, `PPG.Hints.pas:135/164`, `PPG.TeachingTip.pas:205`, `PPG.Dialogs.pas:233`, `PPG.Menus.pas:222/261` → gemeinsamer Setter wie `TPPGCustomControl.SetPreset`.

### 5b Wirkung und Setter
- **Ohne Wirkung:** `PPG.Labels.pas:187/350` LinkLabel `OnClick` (csClickEvents entfernt); `PPG.Hints.pas:168` `CustomHint.Style`; `PPG.Chart.Series.pas:208` `Kind` bei Y-Achsen; `PPG.Dialogs.pas:228` `TaskDialog.OnNavigated`; `PPG.Wizard.pas:64/266` `WizardPage.Description` (nie gezeichnet); `PPG.MenuBar.pas:90/166` `MenuStyles` wirkt nicht auf die Leiste; `PPG.StatusBar.pas:76` `StatusPanel.Hint` nie als Tooltip; `PPG.Feedback.pas:66/129`, `PPG.Rating.pas:90`, `PPG.Splitter.pas:103` volle Appearance, gelesen wird nur `FocusColor`.
- **Setter ohne Changed/Invalidate:** `PPG.ColumnComboBox.pas:45-49/155/158-159/245` (Spalten, ColumnDelimiter, KeyColumn, DisplayColumn), `PPG.Grid.Print.pas:117-123` + `PPG.Print.pas:107-108` (Drucker-Optionen, PageCount veraltet), `PPG.ColorPicker.pas:175`, `PPG.Grid.pas:540` (DefaultDrawing), `PPG.Notifications.pas:157` (Position), `PPG.NavigationView.pas:105` (PageIndex).
- **Setter ohne Gleichheitsprüfung:** `PPG.Planner.pas:1103/1182/1190` (DayCount/TimelineDays/AgendaDays lösen DB-Reload aus), Badge.MaxValue, ProgressRing.Thickness, Rating MaxValue/StarSize/StarSpacing, Gauge Start-/SweepAngle/Thickness, Sparkline LineWidth/MaxCount, ChartSeries.LineWidth, DBChart.MaxRecords, ColorPicker Style/ShowHex, CheckComboBox DisplayMode/MaxDisplayItems, NumberEdit ShowThousandSeparator/CurrencyString.
- **Still geklemmt statt `PPGCheckRange`:** `PPG.Feedback.pas:566`, `PPG.NavigationView.pas:614`, `PPG.StatusBar.pas:290/337/344`, FilterIndex, FilterThreshold, TagEdit.Delimiter.
- **Zustand:** `PPG.Kanban.pas:640` `SetSelectedCard` setzt FFocus direkt (kein Event, kein Scroll, DB-Kanban synchronisiert nicht) → `SetFocusHit(…, True)`; `PPG.Feedback.pas:1192/1218` InfoBar Visible/IsOpen laufen auseinander → `CM_VISIBLECHANGED`; `PPG.SpinEdit.pas:372-386` ReadOnly ohne `UpdateColors`, ReadOnlyStyle bei `EditorEnabled=False`; `PPG.Labels.pas:573/575/599` LinkLabel überschreibt `Cursor` → `WM_SETCURSOR`; `PPG.NavigationView.pas:304` CompactModeThresholdWidth ohne Setter.
- **Designer-Startauswahl:** `PPG.ColumnComboBox.pas:146-147` `ItemIndex` publishen; `PPG.NavigationView.pas:288` `SelectedIndex` publishen.
- **Objektinspektor:** `PPG.Reg.pas` registriert keine Kategorien → Kategorie „PPGlow“ (Optik) und Verhalten/Daten; `GetDisplayName` für `TPPGGaugeRange` (`PPG.Gauge.pas:40`) und `TPPGChartReferenceLine` (`PPG.Chart.Series.pas:205`); ImageIndex-/ImageName-Editor für Collection-Items (NavItem, ToolItem, RibbonItem, StatusPanel); `ImageName` fehlt bei ToolItem, NavItem, TabSheet.
- `PPG.Panel.pas:56-60` – BevelInner/BevelOuter mit TWinControl- statt TPanel-Defaults, 3D-Rahmen um rundes Panel.

### 5c Einheitliche Benennung (Entscheidung 2)
Alte Namen bleiben per `DefineProperties` lesbar (beim Start bestätigen), `migrate.ps1` und `Docs/Migration.md` bekommen die Abbildung, die Property-Referenz wird neu erzeugt.

| Konzept | Heute | Einheitlich |
|---|---|---|
| Stil-Gruppe | `Styles`, `ListStyles` (gleicher Typ!), `CalendarStyles`, `ChartStyles`, `KanbanStyles`, `PlannerStyles`, `NavStyles`, `TabStyles`, `MenuStyles`, `BarStyle` | `Styles` |
| Sichtbarkeit | `SliderVisible`, `ToolTips` vs `ShowTooltips`, `ShowCaption` vs `ShowCaptions`, `ShowCloseButton` vs `ShowCloseButtons` | `ShowX` (VCL-Namen nur, wo das Pendant sie vorgibt: `TabVisible`, `ToolTips` beim TreeView) |
| Wertebereich | `Min/Max/Position` vs `MinValue/MaxValue/Value`, ProgressRing ohne Min/Max | Wert-Controls `Min/Max/Value`; ProgressBar/TrackBar behalten `Position` (VCL); ProgressRing bekommt Min/Max |
| Art | `NumberKind`, `SparklineKind` | `Kind` |
| Animation | `Animation: TPPGAnimationSettings` vs `Animations: Boolean` | `Animation` |
| Farben | `BadgeColor`/`RangeColor` (Aufzählung), „nicht gesetzt“ mal `clDefault`, mal `clNone` | Aufzählungen `…Kind`/`Severity`, freie Farbe `AccentColor`, „nicht gesetzt“ = `clDefault` |
| Trenner | `Delimiter`/`DisplayDelimiter`/`Delimiters`/`ColumnDelimiter` | `Delimiter` (Eingabe), `DisplayDelimiter` (Anzeige) |
| Offen-Zustand | `IsOpen`/`IsClosable` vs `Expanded` | `Open`, `ShowCloseButton` |
| Auswahlwechsel | `OnChange`, `OnSelectionChange`, `OnTabChange`, `OnPageChanged` | `OnChange` (Hauptauswahl), `OnXChange` (Nebenzustände) |
| Zeitform | `OnAppointmentChanged`, `OnPageChanged`, `OnTopLeftChanged` | Präsens `OnXChange`, Vorab `OnXChanging` |
| Eintrag-Klick | `OnItemInvoked` vs `OnItemClick` | `OnItemClick` |
| Eigenes Zeichnen | `OnCustomDrawX` vs `OnDrawItem/Tab/Cell/Panel/GalleryItem` | `OnCustomDrawX`; `OnDrawX` nur als VCL-Kompatibilität |
| Schließ-Abfrage | `OnClosing` vs `OnCloseQuery` | `OnClosing` |
| Haken | `OnClickCheck`, `OnItemCheck`, `OnChecked` | `OnItemCheck` (`OnClickCheck` als VCL-Alias) |
| Aufzählungswerte | TeachingTip `tpTop…` kollidiert mit `Vcl.ComCtrls.TTabPosition` | `ttp…` |

Gleiche Defaults für gleiche Konzepte: DropDownCount (8 vs 10, Bereich 1..MaxInt vs 1..100), AutoComplete (SearchEdit False), ShowHint (NavigationView/ToolBar/Ribbon True), Kanban-Spaltenbreite 80 vs 120 → gemeinsame Konstanten in `PPG.Types`.

Uneinheitlich angeboten: RoundedCorners (nur Button/Edit/Spin/Number/Combo/Panel), Shadow (nur Button/Panel), ShowClearButton (fehlt Spin/Number/Date/Tag/Password), TextHintVisibleOnFocus (fehlt Spin/Date/Time/Tag); fehlende `TPPGCustom…`-Zwischenklassen bei ColorPicker, CheckCombo, ColumnCombo, TagEdit.

### 5d Fehlende VCL-Properties und -Events
Überall: `DoubleBuffered`/`ParentDoubleBuffered`, `OnMouseActivate`; `OnMouseWheel` außer Edit/Memo/Spin; `Action` außer Button/Check-Controls. Reihenfolge: 1. `OnMouse*`/`OnKey*`/`OnContextPopup`/`OnClick`, 2. `DoubleBuffered`/`OnMouseActivate`/`Action`, 3. control-spezifisch:

| Control | Fehlend |
|---|---|
| ProgressBar | OnEnter/Exit, OnKey*, BarColor/BackgroundColor |
| TrackBar | Font/ParentFont, OnClick, SelStart/SelEnd/ShowSelRange, PositionToolTip, OnTracking |
| Panel / GroupBox | OnKey*, BorderStyle, AutoSize, OnCanResize; GroupBox RoundedCorners/Shadow |
| Edit, Memo, Mask | ImeMode/ImeName, Bevel*; Mask Drag-Events |
| ComboBox | OnDrawItem/OnMeasureItem, AutoDropDownWidth, ImeMode |
| Tab-/PageControl, TabSheet | Color/ParentColor, OnClick/OnDblClick, OnKey*, OnGetImageIndex; TabSheet ImageName, Highlighted |
| TreeView | StateImages, SortType, RightClickSelect, OnGetImageIndex/OnGetSelectedIndex, OnCustomDrawItem, OnCancelEdit, AutoComplete |
| Grid / DBGrid | ScrollBars, OnGetEditMask, OnRowMoved; DBGrid OnDrawColumnCell, OnEditButtonClick, OnColEnter/Exit, OnClick |
| DBLookupComboBox | DropDownRows, DropDownAlign, ListFieldIndex, NullValueKey |
| LinkLabel, Badge, ProgressRing, InfoBar, Splitter, Rating | Maus-/Kontext-Events, PopupMenu, Color, StyleElements, Drag*, je nach Control Font/Constraints/BiDiMode |
| SearchEdit | ReadOnly, Alignment, AutoSelect, HideSelection, OnClick, OnMouse* |
| Calendar | MultiSelect, OnClick/OnDblClick, OnKey*, OnMouse*, OnGetMonthBoldInfo |
| Date-/TimePicker, Password, File, Color, CheckCombo, ColumnCombo, TagEdit | OnClick, OnDblClick, OnContextPopup, OnMouse*, Drag*; UseSystemContextMenu |
| NavigationView, ToolBar, Breadcrumb, StatusBar, MenuBar | OnClick, OnKey*, OnMouse*, OnContextPopup, StyleElements, Drag*; StatusBar Action/TabStop; MenuBar ShowHint/PopupMenu/Fokus-Events |
| Sparkline, Gauge, KpiTile, Chart, Planner, Kanban, Ribbon | Color, StyleElements, OnContextPopup, OnMouseEnter/Leave, OnKey*, OnClick/OnDblClick; Ribbon TabStop/OnEnter/OnExit |

---

## Paket 7 – UI/UX-Konsistenz (nach Phase 18)

**7a Dropdown zusammenführen:** ComboBox (`PPG.ComboBox.pas` DropDown 892, CloseUp 943, WndProc 1012, HandleDroppedMouse 1036) und DatePicker (`PPG.DatePicker.pas:976/1026/1088`, Maus-Hook 260-285/1020) auf `TPPGCustomDropDownField` (`PPG.Controls.DropDown.pas`). Behebt:
- `PPG.DatePicker.pas:797-815`: F4/Alt+Pfeil hoch schließen mit `CloseUp(False)` (Auswahl verloren), Alt+Pfeil hoch geschlossen ohne Wirkung.
- `PPG.DatePicker.pas:866-869`, `PPG.TimePicker.pas:481`: Enter immer beansprucht → Default-Button reagiert nicht. Regel wie `PPG.NumberEdit.pas:699-706`.
- Popups folgen dem Formular nicht (WM_WINDOWPOSCHANGED des Besitzers wie `PPG.TeachingTip.pas:1262`).
- `PPG.Popup.pas:380-382/409/431`: Aufklapp-Animation mit `SetWindowPos`+`SetWindowRgn` je Frame (Flackern), `ItemRect` erzeugt DCs (`:593-603`).
- Gemeinsame Tippsuche `TPPGTypeAhead` (heute `PPG.ComboBox.pas:813`, `PPG.Controls.ItemList.pas:1638`, `PPG.ColumnComboBox.pas:472/758`, Zugriff auf privates `FSearchTick`).
- `PPG.Controls.DropDown.pas:143`: `DropWheel` leer.

**7b Mausrad-Helfer in der Basis** (Delta sammeln, nur mit Fokus, `SPI_GETWHEELSCROLLLINES`): `PPG.SpinEdit.pas:~512`, `PPG.NumberEdit.pas:800`, `PPG.Calendar.pas:1129`, `PPG.TimePicker.pas:484`, `PPG.ComboBox.pas:1109`, `PPG.RowPopup.pas:461`, `PPG.TrackBar.pas:524/534`.

**7c Tastatur:**
- `PPG.RadioButton.pas:83` – nur die markierte Option ist Tabstopp (wie VCL `SetChecked`).
- `PPG.TabControl.pas:930-967` – Strg+F4 schließt Reiter (mit `OnCloseQuery`).
- `PPG.Controls.ItemList.pas:1507-1597`, `PPG.TreeView.pas:2393-2421`, `PPG.Grid.pas:5620-5760` – `inherited KeyDown` zuerst, bei `Key = 0` abbrechen.
- `PPG.Controls.ItemList.pas:1574-1588` – Überspringen nicht wählbarer Einträge läuft am Rand aus der Liste; Ende ohne Fokus springt an den Anfang.
- `PPG.Grid.pas:5620-5760` – Entf leert Zelle, Strg+X.
- `PPG.DatePicker.pas:819-834` – `dtkTime` bekommt die Segment-Logik des TimePickers.

**7d Barrierefreiheit:**
- `PPG.Controls.Field.pas:1813-1847` – ValidationHint am inneren Edit melden (`PPGAccSetWindowDescription`), bei `pvsError` `EVENT_SYSTEM_ALERT`.
- `PPG.Controls.Base.pas:1563-1572` – Standardaktion „Drücken“ nur bei Button-artigen Controls (betrifft Gauge, KpiTile, Rating, Sparkline, Splitter, Calendar, Chart, Grid, Listen, Kanban, Planner, NavigationView, Tabs, ToolBar, StatusBar, MenuBar, Ribbon, Breadcrumb, LinkLabel, Wizard).

**7e Farben:**
- `PPGContrastTextColor(Fill)` in `PPG.Tokens` statt sechs Schwellen (`PPG.Calendar.pas:305`, `PPG.Feedback.pas:302`, `PPG.ItemPainter.pas:462`, `PPG.Grid.Export.pas:373`, `PPG.Kanban.pas:1686`, `PPG.Chart.pas:1696`).
- `TPPGTokens.HighContrast` statt ~25 eigener Zweige (z. B. `PPG.Grid.pas:4079-4085`, `PPG.Calendar.pas:1332-1338`, `PPG.Kanban.pas:1509/1734`, `PPG.Feedback.pas:924`).
- Linkfarbe aus Tokens: `PPG.Hints.pas:397`, `PPG.Labels.pas:330` (`clHotLight` im Dark Mode ~2,5:1).
- `OnAccent` statt `clWhite`: `PPG.DatePicker.pas:1134-1135`, `PPG.Dialogs.pas:476`.
- Gemeinsamer Helfer für den deaktivierten Zustand; Kanban und Planner blenden ab.
- `PPG.Labels.pas:~276-290` – TPPGLabel nimmt Tokens des Presets statt `PPGDefaultTokens`.
- `PPG.Grid.Data.pas:276-290`, `PPG.Grid.Print.pas:136-137`, `PPG.Grid.Export.pas:116` – schlichte Tabellenoptik als gemeinsamer Satz `PPGPlainTableLook`.

**7f Kleineres:** Tooltip für abgeschnittene Texte in ItemList und Grid (Mechanismus aus `PPG.TreeView.pas:2767`); `PPG.TagEdit.pas:820-833` `CM_MOUSELEAVE`; `PPG.Kanban.pas:2463` Ziehschwelle `SM_CXDRAG`; `PPG.Hints.pas:380-399` RTL; `PPG.RadioButton.pas:206-224` Pfeile bei RTL spiegeln.

---

## Paket 8 – Performance (nach Phase 18)

Vorher/nachher mit erweitertem Benchmark messen (Hover, Sortieren, Filtern, Leerlauf-CPU).

**8a Kern:**
- `PPG.Controls.Base.pas:1782-1835` – Clip-Box als Dirty-Rect an `DoPaint`/`PaintViewport`, außerhalb liegende Zeilen überspringen (Voraussetzung für alles Weitere).
- `PPG.Controls.Scroll.pas:667-680` – Leisten-Fade zeichnet je Frame den ganzen Viewport.
- `PPG.Controls.Base.pas:1159-1183/948` – virtuelles `UsesHotAnimation` (False in Daten-Controls).
- `PPG.Animation.pas:309-330/436-473` – Modus „fällig ab“ statt 15-ms-Tick für Planner-Jetzt-Linie (`PPG.Planner.pas:4294`), `HoldAnim` (`PPG.Controls.Scroll.pas:650/653`), Toasts (`PPG.Notifications.pas:839-846/877`); `:452` `IndexOf` → `FRegistered`.
- `PPG.Render.Gdi.pas:284` – gemeinsamer Mess-DC, Cache je (Font, PPI).
- `PPG.Render.GdiPlus.pas:534-578` – Text/Bild im Block (Muster `TPPGCellPainter`).
- `PPG.Render.Gdi.pas:92-205` – getönte Icons cachen (Aufrufer Base:1693, NavigationView:804, ToolBar:679).
- `PPG.Controls.Base.pas:1915-1937` – Schatten-Bitmap cachen.

**8b Gezieltes `InvalidateRect`:** Grid `SetHotRow`/`MoveFocus` (`:4012-4021/5230/5271/5277`), ItemList Hover (`:1257`), TreeView (`:2002/2197`), CheckListBox (`:300`), Chart Tooltip (`:2582`), Kanban/Planner Drag (`PPG.Kanban.pas:2178`, `PPG.Planner.pas:3790`, nur bei geändertem Ziel), Ribbon `SetHot` (`:3112-3125`), NavigationView `:1549`, ToolBar `:1196`, TabControl `:888`, StatusBar `:406`, Menü-Scroll (`PPG.Menus.pas:717-744`).

**8c Grid (1 Mio. Zeilen):** Sortierschlüssel vorberechnen (`PPG.Grid.pas:1397`); Filtertext vorab in Großbuchstaben, Filterergebnis beim Umsortieren wiederverwenden (`:1385-1394`); `RowHeights` lazy (`:1229-1243/3772-3783`); Spaltenbreite ziehen ohne Aggregat-Neuberechnung (`:5462` → `PPG.Grid.Columns.pas:403` → `:924-955`); `ComputeStats` Min/Max in O(n) (`PPG.Grid.Styles.pas:257`); Aggregate inkrementell (`:2895-3020`); Flächen per GDI `FillRect` (`:4382/4516`); Font-Cache über Paints behalten (`:4900/4977`, `PPG.ElementStyle.pas:589`); Zellarten im Block, Messwerte cachen (`PPG.Grid.CellKinds.pas:161/418/622-626/794`, `PPG.Grid.pas:4204-4245`); `EnsureGeometry` aus dem Paint (`:3792`); geometrisches Wachstum (`PPG.Grid.Data.pas:416`, `PPG.DB.Grid.pas:931`).

**8d Listen und Baum:** Geschwister-Index (`PPG.TreeView.pas:905/919`); `NodeAttached` lazy per PostMessage (`:1707/1286`); `AlphaSort` Merge-Sort mit Schlüsseln (`:2617-2635`); Zeilenhöhe cachen (`PPG.ItemPainter.pas:474`); Markup-Fonts wiederverwenden, LRU (`PPG.Markup.pas:452/516/542`); `CheckAll` mit `ItemsEx.BeginUpdate` (`PPG.CheckListBox.pas:379`), `ScanItemsEx` inkrementell (`PPG.Items.pas:395`, `PPG.ListBox.pas:662`); Selection-Schnellpfad bei `SelCount = 0`, Single-Index als Feld (`PPG.Selection.pas:423/436-470`, `PPG.Controls.ItemList.pas:392-407`); `ComboBox.ItemsEx.Add` nur anhängen (`PPG.ComboBox.pas:548/616`).

**8e Chart, Kanban, Planner, Ribbon, Rest:** Chart Layout und Frames cachen (`PPG.Chart.pas:899/1926-1975/2326/2464`); Kanban Messwerte je Karte, Höhen-Cache nur geänderte Karte (`:546/869/1577-1657`); Planner Zeitleiste nur sichtbarer Bereich, Vorkommen nach Gruppe/Tag einsortieren (`:1689/1727/3054-3134`); Ribbon/MenuBar/Breadcrumb/Tabs Maße cachen, Zustandsänderung nur `InvalidateRect` (`PPG.Ribbon.pas:1406`, `PPG.Ribbon.Items.pas:655/693/1006`, `PPG.MenuBar.pas:346/369`, `PPG.Breadcrumb.pas:260/289`); InfoBar AutoSize je Animationsframe (`PPG.Feedback.pas:1226`); TeachingTip Reposition bündeln (`:1257`); AppHooks `Copy` je Nachricht (`PPG.AppHooks.pas:89`); TagEdit Layout im Paint (`:846`); `Chart.Series.AddXY` (`:529`), TreeView AutoCheck (`:2180`), `PageControl.InsertPage` (`:459`) ohne Update-Klammer; `DB.Kanban.RenumberCell` ein `Locate` je Karte (`:478`).

---

## Paket 10 – XE2

| Prio | Stelle | Problem | Fix |
|---|---|---|---|
| 1 | `PPG.NavigationView.pas:146/763/771` | **Sicherer Fehler:** `TCollectionNotification`/`cnExtracting`/`cnDeleting` aus Generics verdeckt den Classes-Typ (in XE2 verschieden). | `System.Classes.` qualifizieren. |
| 2 | `PPG.ColorSpace.pas:54/68/75` | `FMod` in XE2 wahrscheinlich nicht vorhanden. | Eigene Funktion `X - Int(X/Y)*Y`. |
| 3 | `PPG.Print.pas:317/321/328` | `DocumentProperties` mit `nil`/`PDeviceMode` – XE2 hat vermutlich nur den `var TDeviceMode`-Overload. | Eigener Import. |
| 4 | `Build/build.ps1:157-163/190-197` | Ohne `.dproj` geht die `.dpk` an msbuild → XE2-Build startet nicht. | Direkt `dcc32` mit `-LE/-LN`. |
| 5 | `Build/install.ps1:47` | Suffix aus Version (`9.0` → `90`), XE2 braucht `'160'`. | Suffix-Tabelle; Versionen 21.0/22.0/23.0 ergänzen (`build.ps1:33`, `install.ps1:56`). |
| 6 | `PPG.Controls.Scroll.pas:80/1018` | `WM_MOUSEHWHEEL`, `SPI_GETWHEELSCROLLCHARS` (unsicher). | Lokale Konstanten `$020E`, `$006C`. |
| 7 | 13 Units mit `System.UITypes` im implementation-uses, `PPG.Planner.ICal.pas:486` `TPair.Create` | Unsicher; beim ersten XE2-Lauf beobachten. | Bei E2037 UITypes ins Interface vor Vcl-Units. |
| 8 | `PPG.Xlsx.pas:1053-1101/1243/1281` | `TZipFile` der XE2 hatte Fehler (unsicher). | Suite Phase13f unter XE2, fremde xlsx einlesen. |

`check-rules.ps1` bekommt eine Verbotsliste (`FMod`, unqualifiziertes `TCollectionNotification`/`cn*`, `DocumentProperties(…nil…)`). `Docs/Kompatibilitaet.md` anpassen (msbuild-Weg zu optimistisch beschrieben).

---

## Paket 11 – Tests, Build, Demo, Doku (laufend)

**Tests:**
- `PPG.Tests.Phase10d.pas:963-968` – `CheckTrue` in `try…except on E: Exception` verschluckt `ETestFailure`, Test kann nie fehlschlagen.
- `Phase13a.pas:338`, `Phase13d.pas:647`, `Phase13e.pas:351` – akzeptieren jede Exception → `CheckTrue(E is EPPGError, E.ClassName)`.
- 18 Zeitlimits mit `GetTickCount` (u. a. `Phase5.pas:464/471`, `Phase10b.pas:311`, `Phase12c.pas:422/674`, `Phase13b.pas:350`, `Phase14a.pas:509`, `Phase14aPlanner.pas:884`, `Phase14cKanban.pas:556`; `Sleep(1100)` in `Phase4b.pas:607/611`, `Phase6a.pas:496`) → in den Benchmark oder großzügig mit Schalter.
- Stilles Überspringen (`Phase10c.pas:311`, `Phase10d.pas:366/807/849`, `Gaps.pas:353`, `Visual.pas:1051`, `Phase3.pas:1148`, fehlendes Referenzbild gilt als bestanden `Visual.pas:917-929`) → nur mit `/allowskip`.
- `PPG.Tests.Streaming.pas:3/35` – behauptet „alle“, prüft 39 von 61 (+15 DB) → Liste aus `PPG.Reg` ableiten.
- Paint-Tests GDI+/GDI-Fallback für Phase 11c, 12a–d, 13a–g, 10e, 17 (Visual-Galerie deckt nur 38 ältere Controls ab, `Visual.pas:79`).
- `PPG.Tests.Controls.pas:166` – `TearDown` setzt Theme und Sprache zentral zurück.
- `Phase13e.pas:245` (`DateToStr(Date)` um Mitternacht), `Phase10c.pas:505` (System-Locale) → feste `TFormatSettings`.
- `Phase14cKanban.pas:721` – nur Smoke-Test → Pixelproben je Zustand.
- Index „Control → Testunit“; falsche Kopfkommentare (`Phase12b.pas:3`, `Phase12c.pas:3`); doppelte Klassennamen (`TLayoutTests`, `TStreamingTests`).
- Schwach abgedeckt: Render.Classic/ModernFlat, VclStyles, ToolBar, Dialogs, Wizard, MenuBar, Hints/CustomHint, Breadcrumb, Rating, Mask/Password/FileEdit, ColumnCombo/CheckCombo, DB.Controls (Memo/Combo/DatePicker je 1 Test), DB.Lookup (1), DB.Fields, Kanban.Print/Planner.Print, Editors.Forms. Ungetestet: `PPGExportCsv`, `PPGLoadICal`, `PPGGetTokenColor`.

**Build-Skripte:**
- `build.ps1:153-157` – Timeout/Absturz mit `.err` ohne Abschlussmarke gilt als Erfolg → nur ausdrückliches „Erfolg/Success“ zählt.
- `build.ps1:188` – Tippfehler in `-Projects` startet `bds` auf den Ordner (600 s) → `ValidateSet`.
- `build.ps1:55/163` – native `2>&1` unter `Stop` → lokal `Continue`.
- `install.ps1:280` – Win64-Fehler bricht alles ab → try/catch, `$BuildFailed`.
- `install.ps1:256-270` vs `:296-303` – `-Uninstall` ändert die Registry vor der Sicherung.
- `install.ps1:302/238/242` – Exit-Code von `reg export` ignoriert, PATH nicht gesichert und bei Uninstall nicht zurückgenommen.
- `install.ps1:65` – Pfad fest → `BDSCOMMONDIR` aus der Registry.

**check-rules.ps1 nachrüsten:** `Data.DB` außerhalb `Source\DB`, `DesignIntf` im Runtime-Code, voll qualifizierte Units, `TImageIndex`, Systemfarben außerhalb des Hochkontrast-Zweigs, `TTimer`/`SetTimer` außerhalb des Animators, `except` ohne Filter, Schichten (Core → Controls/Render, Theme → Render-Presets), hart codierte Texte, requires-Gleichheit XE2/Delphi 13, XE2-Verbotsliste (Paket 10) – jeweils mit Negativbeispiel in `check-rules-tests`.

**Demo:**
- `DemoMain.pas:171` – Katalogsuche ohne 17 Controls (NumberEdit, MaskEdit, PasswordEdit, FileEdit, ColorPicker, CheckComboBox, ColumnComboBox, TagEdit, GroupBox, GridPrinter, KanbanPrinter, CustomHint, DBMask/DBNumber/DBColorPicker/DBCheckCombo/DBTagEdit) → ergänzen, Selbsttest „jedes Paletten-Control im Katalog“.
- Gar nicht in der Demo: GroupBox, CustomHint, KanbanPrinter, DBMaskEdit, DBColorPicker, DBCheckComboBox.
- `DemoPages3.pas:949` – Workaround nach `ForceGdiFallback` → `PPG.Render.Registry.pas:160` bekommt einen Setter, der alle Controls neu zeichnet.
- `DemoMain.pas:596-611`, `DemoPages6.pas:565` – Preset per Schleife statt `TPPGStyleManager`.

**Doku** (`NAECHSTE-SCHRITTE.md` erst nach der Phase-18-Sitzung):
- `NAECHSTE-SCHRITTE.md:3` Kopf veraltet (1105 Tests, nicht installiert) vs `:5/:7/:38`; `:32` „523 Tests, alle 35 Controls“; `:100-101` nur Roadmap 1; `:141` „Phase 14c abschließen“; kaputte Pfade `:111/:113/:119`; `:184` DatePicker-Properties angeblich nur gespeichert.
- `Docs/Controls/notes/TPPGDatePicker.md:6`, `Docs/Controls/TPPGDatePicker.md:10` – gleiche überholte Aussage → korrigieren, `make-docs.ps1` neu laufen lassen.
- `Docs/Architektur.md:33` (13 statt 19 Demo-Seiten), `:748` (BPL-Ladetest nur mit `-LoadTest`).
- `Docs/Roadmap3.md:3` vs `:29` (ListView), `:52-56` offene Entscheidungen, Phase 17 nicht als fertig markiert.
- `Docs/Coding-Rules.md` Zeile 17 vs 28 (`PPGStr` vs `CreateRes`) → Zeile 28 korrigieren; `PPG.Editors.Logic.pas:296` auf `PPGStr`. Regeln „Referenz nach Event“ (Paket 1c) und Ausnahmen für catch-all ergänzen.

---

## Paket 9 – Architektur-Refactoring (langfristig)

**9a DB:** Alle DB-Controls über `TPPGDBValueBinding` bzw. `TPPGDBFieldBinding` (heute ~15 identische Methoden in 5 Klassen in `PPG.DB.Controls.pas` und 5 in `PPG.DB.Fields.pas`, ~1200 Zeilen; `TFieldAccess` doppelt Controls:268/Fields:211). Gemeinsamer `TPPGDBReloadLink` mit echtem `TPPGDebouncer` im Animator statt `FReloadAnim.AnimateTo` (DB.Chart:192-308, DB.Kanban:201ff, DB.Planner:~251ff).

**9b Gemeinsame Bausteine:**
- `TPPGCustomPageHost` (PageControl:520-579 = Wizard:540-590)
- ActionLink-Basis (`PPG.Ribbon.Items.pas:43/419-447/884/905` = `PPG.ToolBar.pas:36/322-350/550/571`)
- `TPPGStyleManagerLink` (Dialogs:1356, Hints:623/687, Menus:1753, Notifications:706, TeachingTip:988)
- `PostAction(Id, Param)` + `DoPostedAction` statt 26 `RegisterWindowMessage` in 22 Units
- `TPPGLayoutWriter`/`Reader` mit Versionskopf (Grid:2409/2473, Kanban:1407/1417, Planner:1354, Ribbon:3919)
- ImageTint nur in der Basis (NavigationView:162/308/795-816, ToolBar:142/221/670-691)
- `ResolveListStyles` (ItemList:909-924 = Popup:897-914), ComboBox auf `TPPGRowPopup`
- `TPPGItemPainter` mit horizontalem Modus und „Icon oben“ (Menus PaintItem, NavigationView, ToolBar, StatusBar, Breadcrumb, TabStrip)
- `TPPGSurfaceStyle.SetSolid` (38 vierfache Farbzuweisungen in 21 Units)
- Grid-Druck nutzt `PaintHeaderFooter` (`PPG.Grid.Print.pas:799-806/870-876`)
- `PPGStarPoints` nach `PPG.Render.Shapes` (Rating:325-335, Grid.CellKinds:514)

**9c Schichten:**
- `PPGSystemAccent`/`PPGRefreshSystemAccent` aus `PPG.Render.Fluent11` nach Theme/Core (`PPG.Theme.pas:93/215`).
- Markup-Parser nach Core (`PPG.Planner.ICal.pas:33`).
- Zyklus `PPG.Render.Registry` ↔ `PPG.Render.Shapes` auflösen (`PPGChartRendererOf` nach Registry).
- `TPPGRendererBase` von der Registry trennen und aufteilen (`PPG.Render.Registry.pas:19-141`).
- Renderer-Interfaces für Planner, Kanban, Calendar, ToolBar, Breadcrumb, Notifications, Dialogs, Wizard.
- Nicht-visuelle Grid-Units (Data, Columns, View, Styles, Look, Xlsx, RowLayout) nach Core/Model.
- `PPG.Print.Preview`/`PPG.Print.Setup` aus `PPG.Print.pas` abspalten.

**9d Gott-Klassen und -Methoden:**
- `TPPGCustomGrid` (268 Methoden, 43 Acc/Uia) → Barrierefreiheits-Adapter, Layout-Persistenz, Hit-Test, Painter.
- `TPPGCustomChart.DoPaint` (880 Zeilen) je Diagrammtyp; `TPPGXlsxWriter.SaveToStream` (635) je Part; `TPPGCustomGrid.PaintRegion` (622) je Bereich; weitere > 200 Zeilen: Chart.Layout, Calendar.DoPaint, GridPrinter.RenderPage, TabStrip.Paint, NavigationView.DoPaint, Recurrence.Expand, Planner.PaintPieces, PPGExportHtmlText, PPGParseMarkup, Kanban.PaintCard/PaintColumn, Menus.PaintItem.
- Layout aus Paint: Breadcrumb:341, ItemList:990/1121, Kanban:1942, Labels:528, Planner:2387, Ribbon:3080, ToolBar:1051; `PPG.Controls.Field.pas:703` `EM_GETRECT` im Paint.
- Cracker-Klassen (`TCtrlAccess` 4×, `TFieldAccess` 3×, `TCalendarAccess` 2×, `TGridAccess`, `TEditAccess` 6×) → schmale Interfaces.
- Testhaken (`PPGRunningAnimationCount`, `PPGMessageHookCount`, `PPGControlWatchCount`, `PPGActiveMenuLoop`, `PPGFlushMenuExecute`, `PPGTranslationCount`, `PPGGridEditorClass`) hinter `PPG_TESTHOOKS`.
- `PPG.Ribbon.pas:72-81` public Felder von `TPPGRibbonView`, Interna im interface → `PPG.Ribbon.Internal`.
- `PPG.Theme.pas:110-114` fünf parallele `TList` mit Pointer-Casts → `TList<TFormRecord>`; TreeView 16×, Dialogs 3×.
- `PPG.UIA.Intf.pas` – Interfaces ohne PPG-Präfix (Kollision mit `Winapi.UIAutomationCore`); `PPG.TeachingTip.pas:551/602` lokale Variable `Caption` verdeckt Property; `PPGIsHighContrast` aus `PPG.DpiUtils` nach Theme/Tokens.
- Magische Zahlen: Obergrenzen 1000/2000/10000/100000 und Geometrie-Literale (ColorPicker 60×, NavigationView 55×, Chart 38× `PPGScale(n)`) → benannte Konstanten.

---

## Paket 0 – Repo-Hygiene (zurückgestellt, Entscheidung 1)

Zur Erinnerung, falls später gewünscht: ~1.330 Artefakte (~150 MB: 1.276 `.dcu`, 16 `.dcp`, 16 `.bpl`, 3 `.exe`, `.err`, `.res`, `.dproj.local`, `.drc`, `.rsm`) aus dem Index; `.gitignore` ergänzen; 28 `Build/registry-backup/*.reg` und `Lib/37.0/Win64/Debug/PPGlowR370.rsm` sind trotz Ignore-Regel eingecheckt; Demo-`.dproj` ohne `DCC_DcuOutput` (DCUs neben den Quellen, Win32/Win64 überschreiben sich); alte `Tests/PPG.Tests.Controls.dcu`/`Core.dcu`; `Tests/audit.txt` mit alten „FEHLER“-Zeilen; `Tests/Visual/Gallery/` ignorieren (Baseline behalten); leerer Ordner `Lib\Delphi13`; `.gitattributes` um `*.txt text eol=crlf`, `*.reg binary`. History-Verkleinerung nur mit `git filter-repo` und Force-Push.

## Fortschritt

| Paket | Stand |
|---|---|
| 1 Abstürze und Datenverlust | **erledigt** (08.10.2026, Zweig `claude/audit-fixes`) |
| 2 Fehlergrenzen, Zahlen, Lebensdauer | **erledigt** (08.10.2026); offen: NumberEdit Min > Max wirft nicht (vertauscht = ohne Grenze), NaN als Lücke im Chart erst mit Paket 4 |
| 3 Dateiformate und Export | **weitgehend erledigt** (08.10.2026); offen: Kanban `'dd.mm.'`, TimePicker-Anzeigeformat aus `ShortTimeFormat`, Datumszellen im xlsx-Reader |
| 6 Migration | **erledigt** (08.10.2026); Umbenennungen aus 5c kommen mit Paket 5 dazu |
| 4 DB-Controls | offen |
| 5 Properties, Objektinspektor, Benennung | offen |
| 11 Tests, Build, Demo, Doku | offen |
| 7 UI/UX-Konsistenz | offen (nach Phase 18) |
| 8 Performance | offen (nach Phase 18) |
| 10 XE2 | offen |
| 9 Architektur | offen (langfristig) |
| 0 Repo-Hygiene | zurückgestellt |

## Umsetzung 08.10.2026 (Pakete 1, 2, 3, 6)

Im eigenen Worktree `PPGlow-audit` (Zweig `claude/audit-fixes`, ab 1042491), weil die Phase-18-Sitzung parallel im Haupt-Arbeitsbaum arbeitet. Jeder Fix hat einen Regressionstest ("Audit 08.10.2026" im Test).

Ergebnis: 1320 Tests Win32 und Win64 gruen, Leak-Lauf Win32/Win64 ohne Zuwachs, Runtime-, Design- und DB-Pakete sowie Demo gebaut, Demo-Selbsttest 154/154, `migrate.ps1 -SelfTest` 4/4, Regel-Pruefer ohne Verstoss. `TRibbonTests.ManyItemsStayFast` (Zeitlimit 4 s) schwankt um die Grenze, auch ohne die Aenderungen (Paket 11).

Neu bzw. geaendert (Auswahl):
- `IPPGAppointmentsHost.AppointmentRemoving` (neue GUID): der Planer loest Editor, Auswahl und Ziehen, bevor ein Termin frei wird.
- `TPPGCustomControl.ImagesChanged` / `ReferencesComponent` (Bilderliste freigegeben bzw. doppelt referenziert).
- `PPGDBBeginRead`/`PPGDBEndRead`/`PPGDBReading` in `PPG.DB.Controls`: Klammer um das Lesen ganzer Datenmengen; PPGlow-Links ignorieren das `EnableControls` eines anderen PPGlow-Controls.
- DB-Planer schreibt per `Edit` nur Saetze, die er geladen hat (`FDbKeys`), sonst `Append` mit freiem Schluessel; fremde offene Bearbeitung -> `EPPGError` mit `SPPGDBEditPending` (neuer Text) statt stillem Post (auch DB-Kanban, DB-Grid-Schnappschuss).
- `PPGIsFinite`/`PPGCheckFinite`/`PPGCheckFloat` in `PPG.Types`.
- `PPGParseNumber`: Buchstaben nur vor/hinter der Zahl, Minus nur davor oder am Ende.
- `migrate.ps1`: Kodierung bleibt, `.bak` nie ueberschrieben, abweichende VCL-Vorgaben werden geschrieben, `TButton.Style` abgebildet, wirkungslose DBGrid-Optionen gemeldet.
