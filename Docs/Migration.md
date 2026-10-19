# Migration: VCL bzw. TMS → PPGlow

*Stand 04.10.2026 (Phase 9f). Werkzeug: `Build\migrate.ps1`.*

## Kurz

```powershell
# Vorschau (schreibt nichts):
powershell -ExecutionPolicy Bypass -File Build\migrate.ps1 -Path C:\Projekte\MeineApp -Recurse -WhatIf
# Umstellen (mit Sicherung *.bak und Bericht migrate-report.txt):
powershell -ExecutionPolicy Bypass -File Build\migrate.ps1 -Path C:\Projekte\MeineApp -Recurse
# Nur bestimmte Klassen:
powershell -ExecutionPolicy Bypass -File Build\migrate.ps1 -Path .\Main.dfm -Only TButton,TEdit
```

Weitere Parameter:

| Parameter | Wirkung |
|---|---|
| `-Map <datei.psd1>` | Zusätzliche Zuordnungen aus einer PowerShell-Datendatei: `@{ ClassMap = @{ 'TAlt' = @('TNeu','Unit') }; Renames = @{ 'TAlt' = @{ 'AltProp' = 'NeuProp' } }; ReportOnly = @{ 'TX' = 'Hinweis' }; InheritsVcl = @('TNeu') }`. Wird in die eingebauten Tabellen gemischt, die Map gewinnt. `InheritsVcl` (optional): Klassen, deren Properties nicht gefiltert werden (Ableitung einer VCL-Klasse). `GlyphClasses` / `GridClasses` (optional): alte Klassen, die wie TBitBtn (Glyph) bzw. TDBGrid (Spalten, Handler) behandelt werden, auch wenn die Zielklasse in keiner Quelle steht (siehe „Eigene Ableitungen“). `HandlerTypes` (optional): `@{ 'TAltTyp' = 'TNeuTyp' }` ersetzt Parametertypen in den Ereignis-Handlern migrierter Objekte. |
| `-ExtraSource <Ordner[]>` | Weitere Quellordner, deren published-Properties gelesen werden (eigene Ableitungen außerhalb von `Source`). Ist die neue Klasse nirgends zu finden, werden ihre Properties nicht gefiltert (Hinweis im Bericht). |
| `-StyleManager <Name>` | Schreibt bei jedem migrierten Objekt, dessen neue Klasse `StyleManager` veröffentlicht, `StyleManager = <Name>` (sofern nicht schon vorhanden). `DM.PPGStyle` verweist auf ein Datenmodul; dessen Unit muss in der `uses`-Liste stehen. |
| `-GlyphDir <Ordner>` | Sichert `Glyph` von TBitBtn/TSpeedButton und von Klassen, die auf eine Ableitung von `TPPGButton` abgebildet werden, als PNG (siehe „Was von Hand bleibt“ und „Eigene Ableitungen“). |
| `-Project <datei.dpr>` | Migriert nur Formulare, deren Unit in der `uses`-Liste der `.dpr` steht; andere werden mit „Unit gehört nicht zum Projekt – übersprungen“ gemeldet und nicht angefasst. |

Voraussetzungen: Die Formulare sind als **Text** gespeichert (in der IDE: Rechtsklick aufs Formular → „Text-DFM“), und die PPGlow-Packages sind installiert. Danach das Projekt öffnen, kompilieren und den Bericht durchgehen.

## Was das Skript macht

1. **Klassen** in der DFM (`object Button1: TButton` → `TPPGButton`) und in der Unit (`Button1: TButton;`) ersetzen.
2. **Units** der neuen Klassen in die `uses`-Liste des interface-Teils eintragen (die alten bleiben stehen).
3. **Properties umbenennen**, wo die Bedeutung gleich ist (Tabelle unten).
4. **Properties entfernen**, die die PPGlow-Klasse nicht hat. Welche es gibt, liest das Skript aus den PPGlow-Quelltexten (published-Abschnitte), damit es immer zum aktuellen Stand passt. Jede Entfernung steht im Bericht.
   Umbenannte Properties werden auch im Code der Unit angepasst, wenn der Komponentenname davorsteht (`Spin1.MinValue` → `Spin1.Min`). In `with`-Blöcken erkennt das Skript sie nicht; dort meldet der Compiler den alten Namen.
5. **Ereignis-Handler** anpassen, deren Parametertyp sich ändert (DB-Grid: `TColumn` → `TPPGDBGridColumn` in jedem Ereignis des Grids, in Deklaration und Implementierung; weitere Typen über `HandlerTypes` der Map).
6. **Abweichende Vorgaben** ausdrücklich schreiben: Wo PPGlow eine andere Vorgabe hat als die VCL, fehlt der Wert in der alten DFM (die IDE speichert Vorgaben nicht). Das Skript trägt dann den VCL-Wert ein, damit sich das Verhalten nicht still ändert (Tabelle unten).
7. **Sicherung** jeder geänderten Datei als `*.bak`; eine vorhandene `*.bak` wird nie überschrieben (ein zweiter Lauf behält das Original). Bericht `migrate-report.txt` im Zielordner.
8. **Kodierung** bleibt erhalten: ANSI-Dateien (cp1252, Umlaute) bleiben ANSI, UTF-8 bleibt UTF-8, ein vorhandenes BOM bleibt.

Der Selbsttest `Build\migrate.ps1 -SelfTest` prüft das Skript an `Build\migrate-tests`.

## Ersetzungstabelle

| Alt (VCL) | Alt (TMS) | PPGlow | Unit |
|---|---|---|---|
| TButton, TBitBtn, TSpeedButton | TAdvGlowButton | TPPGButton | PPG.Button |
| TCheckBox | TAdvOfficeCheckBox | TPPGCheckBox | PPG.CheckBox |
| TRadioButton | TAdvOfficeRadioButton | TPPGRadioButton | PPG.RadioButton |
| TToggleSwitch | | TPPGToggleSwitch | PPG.ToggleSwitch |
| TProgressBar | | TPPGProgressBar | PPG.ProgressBar |
| TTrackBar | | TPPGTrackBar | PPG.TrackBar |
| TPanel | | TPPGPanel | PPG.Panel |
| TGroupBox | | TPPGGroupBox | PPG.GroupBox |
| TEdit | TAdvEdit | TPPGEdit | PPG.Edit |
| TMemo | | TPPGMemo | PPG.Memo |
| TSpinEdit | | TPPGSpinEdit | PPG.SpinEdit |
| TComboBox | TAdvComboBox | TPPGComboBox | PPG.ComboBox |
| TTabControl | | TPPGTabControl | PPG.TabControl |
| TPageControl, TTabSheet | TAdvPageControl | TPPGPageControl, TPPGTabSheet | PPG.PageControl |
| TListBox | | TPPGListBox | PPG.ListBox |
| TCheckListBox | | TPPGCheckListBox | PPG.CheckListBox |
| TTreeView | | TPPGTreeView | PPG.TreeView |
| TStringGrid | TAdvStringGrid | TPPGGrid | PPG.Grid |
| TLabel | | TPPGLabel | PPG.Labels |
| TLinkLabel | | TPPGLinkLabel | PPG.Labels |
| TShape | | TPPGShape | PPG.Shape |
| TSplitter | | TPPGSplitter | PPG.Splitter |
| TSearchBox | | TPPGSearchEdit | PPG.SearchEdit |
| TMonthCalendar | | TPPGCalendar | PPG.Calendar |
| TDateTimePicker | | TPPGDatePicker (bei `Kind = dtkTime`: TPPGTimePicker, von Hand) | PPG.DatePicker |
| TStatusBar | | TPPGStatusBar | PPG.StatusBar |
| TDBEdit | | TPPGDBEdit | PPG.DB.Controls |
| TDBMemo | | TPPGDBMemo | PPG.DB.Controls |
| TDBCheckBox | | TPPGDBCheckBox | PPG.DB.Controls |
| TDBText | | TPPGDBText | PPG.DB.Controls |
| TDBComboBox | | TPPGDBComboBox | PPG.DB.Controls |
| TDBLookupComboBox | | TPPGDBLookupComboBox | PPG.DB.Lookup |
| TDBGrid | | TPPGDBGrid | PPG.DB.Grid |
| TRadioGroup | TcxRadioGroup (DevExpress) | TPPGRadioGroup | PPG.RadioGroup |
| | TcxCheckGroup (DevExpress) | TPPGCheckGroup | PPG.RadioGroup |
| TDBRadioGroup | | TPPGDBRadioGroup | PPG.DB.Navigator |
| TDBNavigator | | TPPGDBNavigator | PPG.DB.Navigator |
| TScrollBox | | TPPGScrollBox | PPG.Panel |
| TPopupMenu | | TPPGPopupMenu | PPG.Menus |
| TRichEdit | | TPPGRichEdit | PPG.RichEdit |
| TDBRichEdit | | TPPGDBRichEdit | PPG.DB.RichEdit |
| TImage | | TPPGImage | PPG.Image |
| TDBImage | | TPPGDBImage | PPG.DB.Controls |
| | TcxButton (DevExpress) | TPPGButton | PPG.Button |
| | TcxCheckBox (DevExpress), TJvCheckBox (JVCL) | TPPGCheckBox | PPG.CheckBox |
| | TcxDBLookupComboBox (DevExpress) | TPPGDBLookupComboBox | PPG.DB.Lookup |
| | TdxDBToggleSwitch (DevExpress) | TPPGDBToggleSwitch | PPG.DB.Controls |
| | TcxPageControl, TcxTabSheet (DevExpress) | TPPGPageControl, TPPGTabSheet | PPG.PageControl |
| | TcxCheckComboBox (DevExpress) | TPPGCheckComboBox | PPG.CheckComboBox |
| | TJvDirectoryEdit, TJvFilenameEdit (JVCL) | TPPGFileEdit (`Kind = fkFolder` bzw. `fkOpenFile`/`fkSaveFile`) | PPG.FileEdit |
| | TJvComboBox (JVCL) | TPPGComboBox | PPG.ComboBox |

`TPPGDBToggleSwitch` (Schalter an einem Ja/Nein-Feld) hat kein VCL-Gegenstück; es ersetzt von Hand ein `TDBCheckBox` (gleiche Properties `DataSource`, `DataField`, `ValueChecked`, `ValueUnchecked`, `ReadOnly`).

Nur gemeldet, nicht umgestellt: `TListView` (Symbol-/Kachelansicht → `TPPGTileView`, Detailansicht `vsReport` → `TPPGGrid`, beides von Hand).

## Umbenennungen und Sonderfälle

| Klasse | Alt | Neu |
|---|---|---|
| TAdvEdit, TAdvComboBox | `EmptyText` | `TextHint` |
| TToggleSwitch | `State = tssOn/tssOff` | `Checked = True/False` |
| TSearchBox | `OnInvokeSearch` | `OnSearch` |
| TSpinEdit | `MinValue`, `MaxValue` | `Min`, `Max` (auch im Code: `Spin1.MinValue` → `Spin1.Min`) |
| TTrackBar | `SliderVisible` | `ShowSlider` (auch im Code) |
| TStringGrid, TAdvStringGrid | `OnTopLeftChanged` | `OnTopLeftChange` (auch Zuweisungen im Code; der Handler-Name bleibt) |
| TDBGrid-Spalten | `Title.Caption` | `Title` |
| TDBGrid-Spalten | `Title.Alignment` | `TitleAlignment` (`gtaLeft`/`gtaCenter`/`gtaRight`) |
| TDBGrid-Spalten | `Title.Font.*`, `Title.Color` | `TitleStyle.Font.*` (mit `TitleStyle.ParentFont = False`), `TitleStyle.Color` |
| TDBGrid-Spalten | `Font.*`, `Color` | `Style.Font.*` (mit `Style.ParentFont = False`), `Style.Color` |
| TDBGrid-Spalten | `Expanded` … | entfernt |
| TDBGrid-Spalten | `ButtonStyle` | bleibt (`cbsEllipsis`: „…“-Knopf, `OnEditButtonClick`) |
| TDBGrid | `TitleFont`, `FixedColor` | bleiben (gleichnamig bei `TPPGDBGrid`) |
| TBitBtn | `Kind` | übersetzt: `bkOK` → `ModalResult = 1` + `Default = True`, `bkCancel` → `2` + `Cancel = True`, `bkYes` → `6` + `Default = True`, `bkNo` → `7`, `bkAbort` → `3`, `bkRetry` → `4`, `bkIgnore` → `5`, `bkAll` → `8` (nur, was nicht ausdrücklich in der DFM steht; je Übersetzung eine Zeile im Bericht). `bkClose`, `bkHelp`: entfernt und gemeldet (von Hand), `bkCustom`: nichts |
| TBitBtn | `Glyph`, `NumGlyphs` | entfernt; `Glyph` mit `-GlyphDir` als PNG gesichert (siehe unten) |
| TBitBtn, TSpeedButton | `Layout` | `ImagePosition` (`blGlyphLeft`/`Right`/`Top`/`Bottom` → `ipLeft`/`ipRight`/`ipTop`/`ipBottom`) |
| TSpeedButton | `Glyph`, `NumGlyphs`, `Flat` | entfernt; `Glyph` mit `-GlyphDir` als PNG gesichert |
| alle Controls | `DesignSize` | bleibt (jedes `TWinControl` liest es; wichtig für `Anchors`) |
| TPanel, TScrollBox, TGroupBox, TMonthCalendar | `AutoSize` | bleibt (die PPGlow-Klassen veröffentlichen `AutoSize`) |
| TPopupMenu | alle | `TPPGPopupMenu` erbt von `TPopupMenu`: Properties (Items, Images, ...) werden nicht gefiltert; `TMenuItem`-Einträge bleiben unverändert |
| TButton | `Style = bsPushButton/bsSplitButton` | `Style = pbsPushButton/pbsSplitButton` |
| TButton | `Style = bsCommandLink` | entfernt (gemeldet) |
| TDBGrid | `Options`: `dgAlwaysShowEditor`, `dgAlwaysShowSelection`, `dgThumbTracking` | bleiben stehen, wirken aber nicht (gemeldet) |
| TDBGrid | `Options`: `dgMultiSelect` | bleibt und wirkt (`SelectedRows` wie in der VCL; im Code `TBookmarkList` durch `TPPGBookmarkList` ersetzen) |
| TDBGrid | `OnDrawColumnCell`, `DefaultDrawing` | bleiben und wirken; im Handler wird `Column: TColumn` zu `TPPGDBGridColumn`, `DefaultDrawColumnCell` und `Column.Field` gibt es gleichnamig |
| TDBNavigator | `Kind` | entfernt (der Navigator ist immer waagerecht) |

## DevExpress- und JVCL-Controls (cx/dx/Jv)

Einfache Controls dieser Bibliotheken ordnet das Skript wie die VCL-Klassen zu (Tabelle oben). Die Properties werden übersetzt, nicht nur gefiltert:

| Klasse | Alt | Neu |
|---|---|---|
| TcxButton | `OptionsImage.Glyph.Data`, `OptionsImage.NumGlyphs` | wie bei TBitBtn: entfernt, mit `-GlyphDir` erstes Teilbild als PNG gesichert (DevExpress-Bilddaten ohne Längenvorspann, 32-Bit-BMP/PNG mit Alpha bleibt erhalten) |
| TcxButton | `OptionsImage.ImageIndex`, `.Images`, `.Margin`, `.Spacing`, `.Layout` | `ImageIndex`, `Images`, `Margin`, `Spacing`, `ImagePosition` (`blGlyphLeft` … → `ipLeft` …) |
| TcxButton | `LookAndFeel.*`, `SpeedButtonOptions.*`, `OptionsImage.Glyph.SourceDPI` | entfallen ohne Meldung (Aussehen); `Style.*` entfernt und gemeldet; `Kind`/`DropDownMenu`: gemeldet (`DropDownMenu` + `Style = pbsSplitButton` von Hand) |
| TcxCheckBox | `State = cbsChecked/cbsUnchecked/cbsGrayed` | `State = cbChecked/cbUnchecked/cbGrayed` |
| TcxCheckBox | `Properties.OnChange`, `Properties.OnEditValueChanged`, `Properties.AllowGrayed`, `Properties.MultiLine` | `OnChange`, `OnChange`, `AllowGrayed`, `WordWrap` |
| TJvCheckBox | `Checked = True` | `State = cbChecked` (steht `State` schon in der DFM, entfällt `Checked`); `LinkedControls = <>` entfällt, nicht leer: gemeldet |
| TcxDBLookupComboBox | `DataBinding.DataField`, `DataBinding.DataSource` | `DataField`, `DataSource` |
| TcxDBLookupComboBox | `Properties.KeyFieldNames`, `.ListSource`, `.ListFieldIndex`, `.DropDownRows`, `.NullValueKey`, `.ReadOnly`, `.OnChange`/`.OnEditValueChanged`/`.OnCloseUp` | `KeyField`, `ListSource`, `ListFieldIndex`, `DropDownRows`, `NullValueKey`, `ReadOnly`, `OnChange`/`OnChange`/`OnCloseUp` |
| TcxDBLookupComboBox | `Properties.ListColumns` (Collection) oder `.ListFieldNames` | `ListField = 'Feld1;Feld2'` (erstes Feld im Feld, weitere als Detailzeile; Spaltenbreiten/Titel entfallen, gemeldet) |
| TcxDBLookupComboBox | `Properties.DropDownListStyle`, `.ImmediatePost`, `.DropDownAutoSize`, `Style.*` | entfernt und gemeldet (`TPPGDBLookupComboBox` ist immer eine Auswahlliste mit Tippsuche, `lsEditList` entfällt) |
| TdxDBToggleSwitch | `DataBinding.*`, `Properties.ValueChecked`/`ValueUnchecked`/`ReadOnly`/`OnChange` | `DataField`, `DataSource`, `ValueChecked`, `ValueUnchecked`, `ReadOnly`, `OnChange` |
| TdxDBToggleSwitch | `Properties.DisplayChecked/-Unchecked`, `StateIndicator.*`, `ImmediatePost` | entfernt und gemeldet (Texte je Zustand gibt es nicht: Caption/Label daneben) |
| TcxPageControl | `Properties.ActivePage`, `.MultiLine`, `.TabPosition`, `.Images`, `.HotTrack`, `.TabHeight`, `.TabWidth`, `.RaggedRight`, `.OnChange`, `.OnPageChanging` | `ActivePage`, `MultiLine`, `TabPosition`, `Images`, `HotTrack`, `TabHeight`, `TabWidth`, `RaggedRight`, `OnChange`, `OnChanging` |
| TcxPageControl | `LookAndFeel.*`, `ClientRect*`, `Properties.TabSlants.*`, leeres `Properties.CustomButtons.Buttons` | entfallen ohne Meldung |
| TcxCheckComboBox | `Properties.Items` (Collection mit `Description`) | `Items.Strings` (Einträge ohne `Description`, `ShortDescription`, `Tag`: gemeldet); `Properties.Delimiter`/`ReadOnly`/`DropDownRows`/`OnChange`/`OnCloseUp` → `Delimiter`/`ReadOnly`/`DropDownCount`/`OnChange`/`OnCloseUp` |
| TJvDirectoryEdit | – | `Kind = fkFolder` dazugeschrieben; `AcceptFiles` → `AcceptDrop`; `Flat`, `ParentFlat`, `DisabledColor`, `DialogKind`, `ButtonWidth` entfallen ohne Meldung |
| TJvFilenameEdit | `DialogKind = dkOpen/dkSave` | `Kind = fkOpenFile/fkSaveFile` (fehlt `DialogKind`: `Kind = fkOpenFile` dazugeschrieben); `Filter`, `DefaultExt`, `DialogTitle`, `InitialDir` bleiben; `AddQuotes` entfernt und gemeldet |
| TJvDirectoryEdit, TJvFilenameEdit | `OnBeforeDialog`, `OnAfterDialog` | bleiben stehen, aber **andere Signatur** (`Allow`, `FileName`/`Accept`): im Bericht gemeldet, Handler von Hand anpassen |
| TJvComboBox | `Flat`, `ParentFlat` | entfallen ohne Meldung |

Nicht umgestellt, nur gemeldet: `TcxNavigator` (hängt über `Control` an ein cxGrid; `TPPGDBNavigator` an eine `TDataSource`: mit dem Grid zusammen von Hand). Im Code der `.pas` meldet das Skript außerdem DevExpress-API an umgestellten Komponenten (`Name.Properties`, `.EditValue`, `.DataBinding`, `.Style` …), weil es sie bei den PPGlow-Pendants nicht gibt.

Eigene Zuordnungen in der `-Map` können dieselben Tabellen ergänzen: `ValueMap`, `Inject` (Eigenschaft dazuschreiben), `Ignore` (ohne Meldung entfernen), `Drop` (entfernen und melden), `PropNotes` (Hinweis im Bericht), je Klasse → Property → Wert bzw. Klasse → Muster.

## Eigene Ableitungen (-Map mit -ExtraSource)

Bildet die Map eine fremde Klasse auf eine eigene PPGlow-Ableitung ab, behandelt das Skript sie wie das VCL-Vorbild, sobald es die Vererbung kennt. Die Vererbung liest es aus `Source` und den `-ExtraSource`-Ordnern (`TMyLinkButton = class(TPPGButton)`, auch über mehrere Stufen):

| Zielklasse erbt von | Behandlung wie | Was passiert |
|---|---|---|
| `TPPGCustomButton` (z. B. `TPPGButton`) | TBitBtn/TSpeedButton | `Glyph` → PNG (mit `-GlyphDir`) bzw. entfernt, `NumGlyphs` entfällt, `Layout` → `ImagePosition`; veröffentlicht die Zielklasse `NumGlyphs`, `Layout` oder `Glyph` selbst, bleiben diese stehen |
| `TPPGDBGrid` | TDBGrid | Spalten (`Title.Caption` → `Title`, `Title.Font.*` → `TitleStyle.*`, `Expanded` entfernt …), wirkungslose `Options` gemeldet, `TColumn` → `TPPGDBGridColumn` in allen Grid-Handlern, `PPG.DB.Grid` in die `uses` |

Steht die Zielklasse in keiner Quelle, hilft die Map: `GlyphClasses = @('TMyOldButton')` bzw. `GridClasses = @('TMyOldGrid')` nennt die **alten** Klassen ausdrücklich. Ohne beides bleibt `Glyph.Data` einer unbekannten Zielklasse stehen (Hinweis im Bericht), weil ihre Properties nicht gefiltert werden. Eigene Parametertypen in Handlern (z. B. ein Grid-Ereignis mit `Grid: TMyOldGridBase`) ersetzt `HandlerTypes = @{ 'TMyOldGridBase' = 'TPPGDBGrid' }`. Renames der Map gehen der Glyph-Behandlung vor. Mit `-GlyphDir` nennt die letzte Berichtszeile die Zahl der gesicherten PNGs.

```powershell
@{
  ClassMap     = @{ 'TMyOldLinkButton' = @('TMyLinkButton', 'My.Buttons'); 'TMyOldGrid' = @('TMyGrid', 'My.Grid') }
  GlyphClasses = @()   # nur fuer Zielklassen ohne Quelle
  HandlerTypes = @{ 'TMyOldGridBase' = 'TPPGDBGrid' }
}
```

## Abweichende Vorgaben

PPGlow behält seine eigenen Vorgaben (Entscheidung 08.10.2026). Fehlt eine dieser Properties in der alten DFM, schreibt das Skript den VCL-Wert hinein:

| Klasse (alt) | Property | VCL-Vorgabe (wird geschrieben) | PPGlow-Vorgabe |
|---|---|---|---|
| TTreeView | `ShowLines` | `True` | `False` |
| TTreeView | `RowSelect` | `False` | `True` |
| TTreeView | `HideSelection` | `True` | `False` |
| TTabControl, TPageControl | `HotTrack` | `False` | `True` |
| TProgressBar | `Smooth` | `False` | `True` |
| TRadioButton, TLinkLabel, TMonthCalendar | `TabStop` | `False` | `True` |
| TSplitter | `ResizeStyle` | `rsPattern` | `rsUpdate` |
| TTabSheet | `ImageIndex` | `0` | `-1` |

Die Splitter-Breite (VCL 3, PPGlow 6) bleibt, weil die IDE `Width` immer speichert.

## Was von Hand bleibt

- **Bilder:** `Glyph` gibt es nicht; eine ImageList (bzw. ab 10.4 `TVirtualImageList`) zuweisen und `ImageIndex`/`ImageName` setzen. Mit `-GlyphDir <Ordner>` sichert das Skript die Glyphs (auch eigener `TPPGButton`-Ableitungen, siehe oben) vorher als `<Form>_<Komponente>.png` (nur das erste Teilbild, Pixel unten links = transparent, wie in der VCL); die PNGs in eine `TImageCollection` aufnehmen und am Button `Images`/`ImageName` setzen. Ohne `-GlyphDir` wird der Glyph entfernt (der Bericht sagt es).
- **Code-Stellen:** Der Bericht nennt mit Zeilennummer `as`/`is TAlteKlasse`, harte Casts `TAlteKlasse(...)` und `with <Komponente> do` in der Unit (nichts wird geändert).
- **`bkClose`/`bkHelp`:** Schließen bzw. Hilfe-Aufruf im `OnClick` von Hand.
- **TTreeView-Knoten:** sind in der DFM binär gespeichert und gehen verloren; im Designer über „Edit nodes...“ neu anlegen (oder im Code füllen).
- **TToolBar/TToolButton:** andere Struktur (Einträge statt Kind-Buttons) – `TPPGToolBar` von Hand aufbauen.
- **TListView:** API zu verschieden für eine automatische Umstellung. Symbol- und Kachelansichten werden zu `TPPGTileView` (Einträge über `Items` oder virtuell über `OnGetItem`), Detailansichten zu `TPPGGrid`.
- **TMS-Erscheinungsbild:** Die `Appearance`-Werte von TMS passen nicht zu PPGlow und werden entfernt; das Preset (Standard ModernFlat) bestimmt die Optik. Ein `TPPGStyleManager` auf dem Formular stellt alle Controls auf einmal um („Apply preset to form...“).
- **TTrackBar:** Der Auswahlbereich (`SelStart`, `SelEnd`, `ShowSelRange`) wird seit Phase 20d übernommen. `PositionToolTip` entfernt das Skript (im Bericht), manuelle Ticks per `SetTick` meldet der Compiler.
- **TAdvStringGrid:** Nur die Grundfunktionen (Zellen, feste Zeilen/Spalten, Sortieren, Filter, Editoren) sind abgedeckt; TMS-spezifische Properties werden entfernt.
- **Code:** Aufrufe, die es nur bei der alten Klasse gibt (z. B. `TBitBtn.Glyph.LoadFromFile`), meldet der Compiler.

## Verhalten, das sich bewusst unterscheidet

- `Checked`/`State`/`Value` im **Code** setzen löst bei PPGlow nur `OnChange` aus, kein `OnClick` (Ausnahme wie VCL: `TPPGTreeView.Selected` löst `OnChange` aus).
- `ItemHeight` ist bei Combo, Liste und Baum eine **Mindesthöhe** (alte DFMs speichern 13).
- Grid: `Row`/`Cells[]` meinen Datenzeilen, `Selection` sichtbare Zeilen (Sortierung, Filter).
- DB-Controls: ungültige Werte erscheinen als Fehlerzustand am Feld statt als Dialog.
- `TPPGDBNavigator` zeigt als Vorgabe den Zähler „Datensatz 12 von 340“ (`ShowCounter = True`); wird es eng, wandern Knöpfe ins Überlaufmenü. Wer den alten Platz braucht, setzt `ShowCounter = False`.
- `TPPGRadioGroup` löst `OnClick` nur bei einer Auswahl durch den Benutzer aus, nicht beim Setzen von `ItemIndex` im Code (wie bei den übrigen PPGlow-Controls).

Die vollständige Liste je Control steht in der Hilfe: `Docs\Controls\README.md`.

## Inventur (inventory.ps1)

`Build\inventory.ps1` zaehlt vor und nach der Migration die Komponentenklassen eines Projekts. Es liest die uses-Liste der .dpr, nimmt alle Formulare, Frames und Datenmodule mit DFM (binaere DFMs werden gemeldet und uebersprungen) und ordnet jede Klasse einer Rubrik zu: PPGlow, migrierbar (steht in der `$ClassMap` von `migrate.ps1`), bleibt (KeepList) oder offen.

```powershell
.\Build\inventory.ps1 -Project C:\Pfad\App.dpr -OutFile Inventur.md
.\Build\inventory.ps1 -Project C:\Pfad\App.dpr -Format csv -KeepList TDBText,TMenuItem
```

Parameter: `-Format text|csv|md` (Standard md), `-KeepList` (Klassenliste oder .psd1/Textdatei mit Klassen, die bewusst bleiben duerfen), `-Root` (PPGlow-Repo). Die Ausgabe enthaelt die Uebersicht je Formular, die Summe je Klasse und die Formulare, die schon vollstaendig PPGlow sind.
