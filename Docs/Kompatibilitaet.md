# Prüfplan XE2 und 10.x

*Stand 04.10.2026 (Phase 9e). Hier steht nur Delphi 13 zur Verfügung; alles unten ist für den ersten Lauf auf einem Rechner mit den älteren Versionen gedacht.*

## Ablauf

1. `powershell -ExecutionPolicy Bypass -File Build\check-rules.ps1`. Das läuft ohne Delphi und prüft unter anderem, ob jede Unit in den XE2-Paketen steht.
2. `Build\build.ps1 -Only XE2`. `build.ps1` kennt bisher XE2 (`9.0`) und Delphi 13 (`37.0`). Für eine 10.x-Version kommt eine Zeile in `$Versions` dazu, zum Beispiel `'21.0' = 'XE2'`; die XE2-Pakete passen dort ebenfalls, nur `LIBSUFFIX` muss angepasst werden.
3. Für jede Zeile unten: Läuft der Compiler durch und verhält sich die Funktion wie beschrieben? Dann abhaken.
4. `Tests\PPGlowTests.exe` (Konsole) bauen und laufen lassen, danach mit `/leaks` noch einmal.
5. Pakete in die IDE laden und die Komponenten-Editoren öffnen. Die IDE vorher schließen: `install.ps1` registriert die Pakete.

`Packages\XE2` enthält nur `.dpk`-Dateien. Ohne `.dproj` gibt `build.ps1` die Quelle (`.dpk`/`.dpr`) direkt weiter; beim ersten Öffnen legt die IDE die `.dproj` an.

## Compiler-Schalter (`Source\PPG.inc`)

| Schalter | ab | Stellen | Was ohne ihn passiert | Prüfen |
|---|---|---|---|---|
| `PPG_HAS_STYLEELEMENTS` | XE3 (24.0) | 32 Stellen, je eine pro Control (published `StyleElements`), dazu 2× in `PPG.Controls.Base`, 3× in `PPG.Labels` sowie `PPG.Popup`, `PPG.DB.Grid` und `PPG.Editors.Forms` | Die Property fehlt, und die Controls folgen dem VCL-Style immer ganz | Unter XE2 kompiliert; DFMs aus neueren Versionen mit `StyleElements` melden beim Laden „Property existiert nicht“ (erwartet) |
| `PPG_HAS_SYSTEM_ACTIONS` | XE3 | `PPG.ToolBar` (uses) | Die Actions kommen aus `Vcl.ActnList` | ToolBar mit Action unter XE2 |
| `PPG_HAS_PPI` | 10.3 (33.0) | `PPG.DpiUtils` | Skalierung über `Screen.PixelsPerInch` (system-DPI) | Verhalten auf 150 % unter 10.2: Controls skalieren einmal beim Start |
| `PPG_HAS_UITYPES_IMAGEINDEX` | 10.4 (34.0) | `PPG.Types` (2×) | `TImageIndex` aus `Vcl.ImgList` | Kompiliert ohne Deprecated-Warnung |
| `PPG_HAS_IMAGENAME` | 10.4 | `PPG.Controls.Base` (8×), `PPG.Button` | Kein `ImageName`, nur `ImageIndex` | Button mit `TVirtualImageList` ab 10.4; unter 10.3 fehlt die Property |
| `PPG_HINTINFO_IN_CONTROLS` | 13 (37.0) | `PPG.Hints` (Alias `TPPGHintInfo`) | `THintInfo` kommt aus `Vcl.Forms` (dort ab 13 veraltet) | `TPPGHintManager.DoShowHint` kompiliert ohne Deprecated-Warnung |
| `PPG_HAS_UIA` | 13 (37.0) | wird bewusst **nicht** abgefragt | – | Der eigene UIA-Provider (`PPG.UIA*`) läuft ab XE2, siehe unten |

In den Tests prüft `PPG.Tests.Gaps` drei Stellen direkt mit `CompilerVersion >= 34.0` (ImageCollection/VirtualImageList). In `PPG.Tests.Visual` überspringt die DPI-Galerie sich unter 10.3, weil es dort kein `ScaleForPPI` gibt.

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

- Die Demo (`Demo\PPGlowDemo`) verwendet den Styles-Ordner von Delphi 13 und ist nur dafür gedacht.
- Unter XE2 gibt es keine Per-Monitor-DPI. Die DPI-Galerie in den Sichttests meldet dort „Test entfällt“.
- Bis 10.2 gibt es kein `CurrentPPI`; die Controls skalieren über `PPG.DpiUtils` mit der System-DPI.
