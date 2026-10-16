# Prüfplan XE2, 10.x und Delphi 11

*Stand 15.10.2026 (Phasen bis 20, Audit-Pakete 1–8, Umstellung auf Delphi 11). Hier steht nur Delphi 13 Community zur Verfügung. **PPGlow wurde noch nie mit XE2, einer 10.x-Version oder Delphi 11 vollständig kompiliert.** Von Delphi 11 gibt es nur einen ersten Test-Build mit dem Fehler `ROLE_SYSTEM_SPLITBUTTON` (behoben, siehe unten). Alles unten ist ein Prüfplan für den ersten Lauf auf einem Rechner mit den älteren Versionen, keine Zusage. Die XE2-Regeln (`Docs\Coding-Rules.md`, Abschnitt Kompatibilität) prüft bisher nur der Regel-Prüfer ohne Compiler.*

## Ehrlicher Stand

- **Geprüft:** nur Delphi 13 (Win32 und Win64), Bauweg `bds -b` (IDE-Batch), weil die Community Edition keinen Kommandozeilen-Compiler hat.
- **Ungetestet:** der Weg über `msbuild` (Editionen ab Professional) und jeder Lauf mit XE2, 10.x oder Delphi 11. `build.ps1` ruft `msbuild` auf, sobald `dcc32` auf der Kommandozeile arbeitet; das ist hier nie gelaufen.
- **XE2 hat keine `.dproj`:** `Packages\XE2` enthält nur `.dpk`-Dateien. Ohne `.dproj` reicht `build.ps1` die `.dpk` direkt weiter. Mit `bds -b` legt die IDE die `.dproj` beim ersten Öffnen an; `msbuild` kann eine `.dpk` dagegen nicht bauen. Der XE2-Bauweg muss deshalb beim ersten Lauf erst hergestellt werden (Pakete einmal in der XE2-IDE öffnen und speichern oder `.dproj` für XE2 anlegen; offen als B8 im Audit, Paket 10).
- **Tests und Demo nur Delphi 13:** `Tests\PPGlowTests.dproj`, `Tests\Bench\PPGlowBench.dproj` und `Demo\PPGlowDemo.dproj` sind Delphi-13-Projekte (`ProjectVersion` 20.3). XE2, 10.x und Delphi 11 brauchen eigene Projektdateien aus den `.dpr`. Für Delphi 11 deshalb vorerst nur die Pakete bauen: `build.ps1 -Only Delphi11 -Projects Runtime,Design,DBRuntime,DBDesign` (ohne `-Projects` würde `build.ps1` auch Tests und Demo mit den Delphi-13-Projektdateien versuchen). Die Demo nutzt außerdem den Styles-Ordner von Delphi 13.
- **Schalter:** Alles Versionsabhängige läuft über die `PPG_HAS_*`-Schalter in `Source\PPG.inc` (Tabelle unten). Ob jeder Zweig ohne Schalter kompiliert, ist ungeprüft.

## Ablauf

1. `powershell -ExecutionPolicy Bypass -File Build\check-rules.ps1`. Das läuft ohne Delphi und prüft unter anderem, ob jede Unit in den XE2-Paketen steht.
2. Bauweg herstellen (siehe oben), dann `Build\build.ps1 -Only XE2` bzw. `-Only Delphi11`. `build.ps1` kennt XE2 (`9.0`), Delphi 11 (`22.0`) und Delphi 13 (`37.0`). Für eine 10.x-Version kommen eine Zeile in `$Versions` (`build.ps1`) sowie Ordner und Suffix in `$Folders`/`$Suffixes` (`install.ps1`) dazu, dazu ein Paketordner wie `Packages\Delphi11` mit passendem `LIBSUFFIX`.
3. Für jede Zeile unten: Läuft der Compiler durch und verhält sich die Funktion wie beschrieben? Dann abhaken.
4. Für Tests und Demo eigene Projektdateien der Version aus `Tests\PPGlowTests.dpr` bzw. `Demo\PPGlowDemo.dpr` anlegen, `Tests\PPGlowTests.exe /hidden` bauen und laufen lassen, danach mit `/leaks /hidden` noch einmal.
5. Pakete in die IDE laden und die Komponenten-Editoren öffnen. Die IDE vorher schließen: `install.ps1` registriert die Pakete.

## Compiler-Schalter (`Source\PPG.inc`)

| Schalter | ab | Stellen | Was ohne ihn passiert | Prüfen |
|---|---|---|---|---|
| `PPG_HAS_STYLEELEMENTS` | XE3 (24.0) | 32 Stellen, je eine pro Control (published `StyleElements`), dazu 2× in `PPG.Controls.Base`, 3× in `PPG.Labels`, 1× in `PPG.Shape`, 1× in `PPG.RichEdit`, 2× in `PPG.Image`/`PPG.DB.Controls` (Bild) sowie `PPG.Popup`, `PPG.DB.Grid` und `PPG.Editors.Forms` | Die Property fehlt, und die Controls folgen dem VCL-Style immer ganz | Unter XE2 kompiliert; DFMs aus neueren Versionen mit `StyleElements` melden beim Laden „Property existiert nicht“ (erwartet) |
| `PPG_HAS_SYSTEM_ACTIONS` | XE3 | `PPG.ToolBar` (uses) | Die Actions kommen aus `Vcl.ActnList` | ToolBar mit Action unter XE2 |
| `PPG_HAS_DATASETCOMMANDS` | XE3 | `PPG.DB.Navigator` (5 Stellen) | XE2 kennt `nbApplyUpdates`/`nbCancelUpdates` und `IDataSetCommandSupport` nicht; der DB-Navigator hat diese Knöpfe dann nicht | DB-Navigator unter XE2 kompilieren; eine DFM aus einer neueren Version mit diesen Knöpfen in `VisibleButtons` laden |
| `PPG_HAS_PPI` | 10.3 (33.0) | `PPG.DpiUtils` | Skalierung über `Screen.PixelsPerInch` (system-DPI) | Verhalten auf 150 % unter 10.2: Controls skalieren einmal beim Start |
| `PPG_HAS_IMAGECOLLECTION` | 10.3 (33.0) | wird derzeit an keiner Stelle abgefragt (vorbereitet für `TImageCollection`) | – | Nichts zu prüfen, solange keine Stelle ihn nutzt |
| `PPG_HAS_UITYPES_IMAGEINDEX` | 10.4 (34.0) | `PPG.Types` (2×) | `TImageIndex` aus `Vcl.ImgList` | Kompiliert ohne Deprecated-Warnung |
| `PPG_HAS_IMAGENAME` | 10.4 | `PPG.Controls.Base` (8×), `PPG.Button` | Kein `ImageName`, nur `ImageIndex` | Button mit `TVirtualImageList` ab 10.4; unter 10.3 fehlt die Property |
| `PPG_HAS_OLEACC_SPLITBUTTON` | 13 (37.0) | `PPG.Accessibility` (Ersatzkonstante); genutzt in `PPG.Button`, `PPG.Ribbon`, Tests `PPG.Tests.Gaps`/`Phase14bRibbon` | `PPG.Accessibility` deklariert `ROLE_SYSTEM_SPLITBUTTON = $3E` selbst (fehlt in `Winapi.oleacc` von Delphi 11) | Delphi 11: kompiliert; Delphi 13: kompiliert weiter ohne Doppelung. Delphi 12 ungeprüft, aber unkritisch (siehe unten) |
| `PPG_HINTINFO_IN_CONTROLS` | 13 (37.0) | `PPG.Hints` (Alias `TPPGHintInfo`) | `THintInfo` kommt aus `Vcl.Forms` (dort ab 13 veraltet) | `TPPGHintManager.DoShowHint` kompiliert ohne Deprecated-Warnung |
| `PPG_HAS_UIA` | 13 (37.0) | wird bewusst **nicht** abgefragt | – | Der eigene UIA-Provider (`PPG.UIA*`) läuft ab XE2, siehe unten |

In den Tests prüft `PPG.Tests.Gaps` drei Stellen direkt mit `CompilerVersion >= 34.0` (ImageCollection/VirtualImageList). In `PPG.Tests.Visual` überspringt die DPI-Galerie sich unter 10.3, weil es dort kein `ScaleForPPI` gibt.

## Umstellung auf Delphi 11 Alexandria (15.10.2026)

Delphi 11 = BDS 22.0, `CompilerVersion` 35.0, `LIBSUFFIX` 280. Geprüft wurde nur durch Lesen (kein Delphi 11 hier): Suche nach Sprachmitteln und Symbolen, die es erst ab Delphi 12/13 gibt, über alle 149 Units in `Source` (Abgleich aller nicht selbst deklarierten Bezeichner, Konstanten, `override`-Methoden und Member-Zugriffe; dazu jede Unit vollständig gelesen). Gefunden wurde für Delphi 11 nur `ROLE_SYSTEM_SPLITBUTTON`. Weitere Fehler beim ersten echten Build sind trotzdem möglich (Liste „Unsicher“ unten).

### Änderungen mit Versionsrisiko

| Bereich | Änderung | Risiko | Prüfen |
|---|---|---|---|
| `Source\PPG.inc` | Neuer Schalter `PPG_HAS_OLEACC_SPLITBUTTON` ab 37.0 | Belegt ist die Konstante nur für Delphi 13. Hat Delphi 12 sie schon, verdeckt die eigene Konstante sie nur (gleicher Wert, kein Fehler) | Delphi 11 und 13 kompilieren `PPG.Button`, `PPG.Ribbon` |
| `PPG.Accessibility` | `ROLE_SYSTEM_SPLITBUTTON = $3E` (Wert aus `oleacc.h`), nur ohne den Schalter | Units, die die Rolle brauchen, müssen `PPG.Accessibility` in den `uses` haben | Narrator meldet Split-Button und Ribbon-Split-Item als „Unterteilte Schaltfläche“ |
| `PPG.Button` | `PPG.Accessibility` in der implementation-`uses` | Keine Namensgleichheit mit `Winapi.oleacc` außer der Konstante | Kompiliert unter 11 und 13 |
| `Tests\PPG.Tests.Gaps` | `PPG.Accessibility` in den `uses` (nur Sichtbarkeit der Konstante, Prüfungen unverändert) | – | Suite Gaps unter Delphi 11, sobald es Testprojekte dafür gibt |
| `Packages\Delphi11` | Vier Pakete als `.dpk` aus `Packages\XE2` mit `LIBSUFFIX '280'`, dazu `.dproj` aus `Packages\Delphi13` (neue GUID, `ProjectVersion` 19.3, `DllSuffix` 280) | Die `.dproj` sind von Hand abgeleitet, nie von einer Delphi-11-IDE gespeichert. Die IDE schlägt beim Öffnen evtl. eine Aktualisierung vor (unkritisch). Ausgabe nach `Lib\22.0\<Plattform>\<Konfiguration>` | `build.ps1 -Only Delphi11 -Projects Runtime,Design,DBRuntime,DBDesign` für Win32 und Win64; Dateinamen `PPGlowR280.bpl` usw. |
| `Build\build.ps1` | `'22.0' = 'Delphi11'` | – | Ausgabe „[Delphi11] …“ |
| `Build\install.ps1` | Standard `-Version 22.0`; BPL-Suffix aus Tabelle (160/280/370) statt aus der BDS-Nummer | Die alte Formel hätte für Delphi 11 `PPGlowR220.bpl` gesucht | `install.ps1` (ohne Parameter) mit geschlossener IDE, danach Palette prüfen |
| `Build\check-rules.ps1` | Regel PROJECT prüft auch die Delphi-11-Listen; REQUIRES vergleicht XE2 mit Delphi11 und Delphi13 | – | Volllauf und `-SelfTest` liefen hier mit PowerShell 7 ohne Verstoß |
| `Build\showcase-agents\build-lock.ps1` | `-Only` wählbar, Vorgabe Delphi13 | – | – |
| `.gitignore`, Index | 1449 eingecheckte `.dcu` (Delphi 13) aus dem Index entfernt, `*.dcu` ignoriert | Nach dem Pull verschwinden die `.dcu` aus `Source`, `Lib\37.0` und `Tests`; der nächste Build erzeugt sie neu | Erster Build nach dem Pull |

**XE2-Funde bei derselben Durchsicht** (Delphi 11 nicht betroffen, mit behoben): 20 published `property StyleElements;` standen ohne `PPG_HAS_STYLEELEMENTS` (Breadcrumb, Calendar, Chart, Feedback 2×, Gauge 2×, Kanban, MenuBar, NavigationView, Planner, Rating, Ribbon, Sparkline, Splitter, StatusBar, ToolBar, DB.Chart, DB.Kanban, DB.Planner). In `PPG.DB.Navigator` hatte `BtnIcons: array[TNavigateBtn]` zwölf Einträge, XE2 kennt nur zehn Knöpfe; die letzten zwei stehen jetzt unter `PPG_HAS_DATASETCOMMANDS`.

### Unsicher (beim ersten Delphi-11-Build zuerst ansehen)

- **Prüfung ohne Compiler und ohne RTL-Quellen von Delphi 11:** Die Einschätzung, welche Symbole Delphi 11 hat, beruht auf Wissen über die RTL/VCL-Geschichte, nicht auf den Quelltexten von Delphi 11. Am ehesten fehlen könnten noch einzelne WinAPI-Konstanten. Mittlere Sicherheit bei `STATE_SYSTEM_MIXED` (`Winapi.oleacc`/`Winapi.Windows`; falls E2003: Ersatz wie bei `ROLE_SYSTEM_SPLITBUTTON`, Wert `$20`), `WM_MOUSEHWHEEL` und `SPI_GETWHEELSCROLLCHARS` (`PPG.Controls.Scroll`).
- **Signaturen überschriebener VCL-Methoden** (`THintWindow.NCPaint`/`CalcHintRect`, `TCustomHint.PaintHint`, `TCustomTaskDialog.DoExecute`, `TCustomLabel.DoDrawText`, `TStringList.InsertItem`, ActionLinks) wurden als unverändert seit vor Delphi 11 eingeschätzt.
- **`.dproj` von Hand** (siehe Tabelle). Falls die Delphi-11-IDE sie ablehnt: `.dpk` in der IDE öffnen, speichern lassen und die neue `.dproj` einchecken (Unit-Liste muss gleich bleiben, sonst meldet der Regel-Prüfer PROJECT).
- **Tests und Demo** haben keine Delphi-11-Projektdateien (siehe „Ehrlicher Stand“); die Unit `PPG.Tests.Gaps` und die Demo-Styles sind für Delphi 11 nicht geprüft.
- **Weitere Binärdateien im Index:** `.bpl`/`.dcp` unter `Lib\37.0`, `Demo\PPGlowDemo.exe`, `Tests\PPGlowTests.exe`, `Tests\Bench\PPGlowBench.exe` und eine `.rsm` sind weiter eingecheckt (nur `.dcu` war beauftragt).

## Neue Stellen aus Phase 9 mit Versionsrisiko

| Bereich | Risiko | Prüfen unter XE2 |
|---|---|---|
| `PPG.UIA.Intf` | Eigene Interfaces mit `safecall`, `PSafeArray`, `OleVariant` | Kompiliert. `PPGlowTests` Suite **Phase9b** (Client-Test über `IUIAutomation`): Grid-Zellen, Baumknoten und Listeneinträge sind erreichbar. Danach Narrator auf Win 10/11 |
| `PPG.UIA` | `UIAutomationCore.dll` wird dynamisch geladen; unter Windows 7 ohne Update fehlen Funktionen | Unter Win 7 muss MSAA weiterlaufen, ohne Fehlermeldung |
| `PPG.Lang` | `TObjectDictionary<string, …>` mit `doOwnsValues` | Suite **Phase9d** |
| `PPG.Tests.Phase9d` | Typisierte Konstante `array of PResStringRec` mit `@resourcestring` | Kompiliert. Falls nicht: die Liste in eine Funktion verlegen, die das Array füllt |
| `PPG.DB.*` | `TFieldDataLink` aus `Vcl.DBCtrls`, `TDBGridOptions` aus `Vcl.DBGrids`, `dsOpening` | Suite **Phase9c**. `MidasLib` gibt es ab XE2 |
| `PPG.Reg` | `ShowCollectionEditor` (Unit `ColnEdit`) | Bei den Collection-Editoren („Columns…“, „Items…“) öffnet sich der Standard-Editor |
| `PPG.Editors.Forms` | Dialoge mit `CreateNew`; `StyleElements` nur ab XE3 | Darstellungs-Dialog und Preset-Galerie in der IDE öffnen |
| `PPGlow.dcr`, `PPGlowDB.dcr` | Bitmaps in 16/24/32 px mit Alphakanal; ältere IDEs werten nicht alle Größen bzw. das Alpha aus | Palette: Symbole sichtbar, Hintergrund nicht schwarz |

## Neue Stellen aus Phase 11 mit Versionsrisiko

| Bereich | Risiko | Prüfen unter XE2 |
|---|---|---|
| `PPG.Dialogs` | `TPPGTaskDialog` erbt von `TCustomTaskDialog` und überschreibt `DoExecute` (strict protected, dynamic). Spätere Flags wie `tfSizeToContent` werden nicht verwendet | Suite **Phase11c**; DFM eines `TTaskDialog` mit `TPPGTaskDialog` laden |
| `PPG.Dialogs` | `TPPGInputValidate` ist ein anonymer Methodentyp mit `TArray<string>` | `PPGInputQuery` mit Prüffunktion |
| `PPG.Dialogs` | `TMsgDlgType`/`TMsgDlgBtn` werden qualifiziert (`TMsgDlgBtn.mbYes`) verwendet; `mrClose`, `mrAll` usw. aus `System.UITypes` | Kompiliert |
| `PPG.Dialogs` | `CurrentPPI` des Formulars erst ab 10.3 (`PPG_HAS_PPI`) | Dialog auf einem Monitor mit 150 % |
| `PPG.Hints` | `TCustomHint` mit `PaintHint`/`SetHintSize`; `CurrentPPI` von `TCustomHint` gibt es erst später und wird nicht verwendet | `TPPGCustomHint` an einem Edit |
| `PPG.AppHooks` | `TApplicationEvents` verteilt an mehrere Empfänger (ab XE2) | Menüs, TeachingTip und Menüleiste gleichzeitig |
| `PPG.Wizard`, `PPG.TeachingTip` | `Exit(Wert)` und `TArray<…>` | Kompiliert |

## Neue Stellen aus Phase 12 mit Versionsrisiko

| Bereich | Risiko | Prüfen unter XE2 |
|---|---|---|
| `PPG.MaskEdit` | Inneres Edit von `TCustomMaskEdit`; `ValidateEdit` ist dort public und virtuell, `FormatMaskText`/`MaskGetMaskBlank` aus `System.MaskUtils` | Suite **Phase12a** |
| `PPG.NumberFormat` | `TFormatSettings.Create('de-DE')` in den Tests; Records mit Methoden (`TExprParser`) | Suite **Phase12a** (Parser-Tabelle) |
| `PPG.FileEdit` | `TFileOpenDialog` ab Vista, Rückfall `TOpenDialog`/`SHBrowseForFolder` (Laufzeitprüfung `Win32MajorVersion`); `SHAutoComplete` dynamisch | Auf XP ohne Vista-Dialog |
| `PPG.ColorPicker` | `TColorBoxStyle` aus `Vcl.ExtCtrls`; `ScanLine` mit `PRGBTriple` | Galerie `ColorPicker.png` |
| `PPG.ColumnComboBox` | `TArray.Sort` mit anonymem Vergleicher (`TComparer.Construct`) | Sortieren per Kopfzeile |
| `PPG.DB.Fields` | `TFieldDataLink`, `Field.Value` als Variant (Currency) | Suite **Phase12d** |

## Neue Stellen aus Phase 13 mit Versionsrisiko

| Bereich | Risiko | Prüfen unter XE2 |
|---|---|---|
| `PPG.Xlsx` | `System.Zip` (`TZipFile.Add` mit `TBytes`/Dateiname, `Read`), `System.IOUtils` (`TPath.GetTempFileName`) | Suite **Phase13f** |
| `PPG.Grid.View`, `PPG.Grid.CellKinds` | `TDictionary<string, …>`, Generics in Records/Arrays | Suiten **Phase13a/c/d** |
| `PPG.Grid.Styles` | `TArray.Sort<Double>` | Suite **Phase13d** |
| `PPG.Grid.Print` | Drucker-DC über `OpenPrinter`/`DocumentProperties`/`CreateDC` (statt des veralteten `TPrinter.GetPrinter`), `TMetafileCanvas`, `PlayEnhMetaFile` | Suite **Phase13e**, Vorschau von Hand |
| `PPG.Grid.Export` | `EnumPrinters` Level 2 (`PPrinterInfo2`), „Microsoft Print to PDF“ erst ab Windows 10 | Suite **Phase13f** (ohne PDF-Drucker: Fehlermeldung wird geprüft) |

**Verhaltensänderungen in Phase 13** (bestehender Code):
- `Grid.Col` ist die **Datenspalte** (bisher identisch mit der Anzeige). Neu: `FocusCol`, `VisibleColCount`, `DataCol`/`VisualCol`. `CellRect`, `MouseCoord`, `MakeCellVisible` und `Selection` arbeiten mit Anzeige-Spalten. Ohne verschobene/ausgeblendete Spalten ändert sich nichts.
- Rechtsklick auf den Spaltenkopf öffnet das Kopfmenü statt `PopupMenu` (abschaltbar: `HeaderMenu := False`). Umschalt+F10 ohne `PopupMenu` öffnet es für die Fokusspalte.
- `IPPGTableSource` des Grids liefert nur die angezeigten Spalten in Anzeige-Reihenfolge und nur Datenzeilen (ohne Gruppenzeilen).
- `ToCSV`/`SelectionAsText` folgen der Anzeige-Reihenfolge und lassen ausgeblendete Spalten weg.
- Kästchen-Spalten setzen ihren Wert jetzt über `OnValidateCell` (wie der Editor).
- DB-Grid: mit `dgColumnResize` lassen sich Spalten verschieben (wie `TDBGrid`); Boolean-Felder sind auch in eigenen `Columns` Kästchen.

## Neue Stellen aus Phase 14a mit Versionsrisiko

| Bereich | Risiko | Prüfen unter XE2 |
|---|---|---|
| `PPG.TimeZones` | Registry-Wert `TZI` (Aufbau `REG_TZI_FORMAT`), `GetTimeZoneInformation` | Suite **Phase14a** (TTimeZoneTests) |
| `PPG.Planner.Model`, `PPG.Planner` | `TTimeZone.Local` (System.DateUtils, ab XE), `TArray.Sort<TPPGOccurrence>` mit anonymem Vergleicher, `TDictionary` | Suiten **Phase14a** |
| `PPG.Planner.ICal` | `TEncoding.UTF8.GetBytes` (Faltung nach 75 Bytes) | Suite **Phase14a** (ICalFolding) |
| `PPG.Planner.Print` | `StyleElements` nur unter `PPG_HAS_STYLEELEMENTS` (XE2: Druckfarben folgen ggf. dem Dark Mode der Anwendung) | Druckvorschau von Hand |
| `PPG.Print` | aus `PPG.Grid.Print` herausgelöst; alte Namen dort als Typ-Aliase | Suite **Phase13e** |

**Verhaltensänderungen in Phase 14a** (bestehender Code):
- `TPPGGdiCanvas.PushClipRoundRect` berücksichtigt einen verschobenen Ursprung (`SetViewportOrgEx`/`SetWindowOrgEx`). Ohne verschobenen Ursprung ändert sich nichts.
- `TPPGGridPrinter` erbt von `TPPGCustomPrinter` (`PPG.Print`); `TPPGPageSetupForm` zeigt die Optionen des jeweiligen Druckers.

## Bekannte Grenzen (kein Fehler)

- Die Demo (`Demo\PPGlowDemo`) verwendet den Styles-Ordner von Delphi 13 und ist nur dafür gedacht. Für Phase 14b bis 20 und die Audit-Pakete gibt es noch keine eigenen Tabellen mit Versionsrisiken; sie folgen beim ersten echten XE2-Lauf.
- Unter XE2 gibt es keine Per-Monitor-DPI. Die DPI-Galerie in den Sichttests meldet dort „Test entfällt“.
- Bis 10.2 gibt es kein `CurrentPPI`; die Controls skalieren über `PPG.DpiUtils` mit der System-DPI.
