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

Voraussetzungen: Die Formulare sind als **Text** gespeichert (in der IDE: Rechtsklick aufs Formular → „Text-DFM“), und die PPGlow-Packages sind installiert. Danach das Projekt öffnen, kompilieren und den Bericht durchgehen.

## Was das Skript macht

1. **Klassen** in der DFM (`object Button1: TButton` → `TPPGButton`) und in der Unit (`Button1: TButton;`) ersetzen.
2. **Units** der neuen Klassen in die `uses`-Liste des interface-Teils eintragen (die alten bleiben stehen).
3. **Properties umbenennen**, wo die Bedeutung gleich ist (Tabelle unten).
4. **Properties entfernen**, die die PPGlow-Klasse nicht hat. Welche es gibt, liest das Skript aus den PPGlow-Quelltexten (published-Abschnitte), damit es immer zum aktuellen Stand passt. Jede Entfernung steht im Bericht.
   Umbenannte Properties werden auch im Code der Unit angepasst, wenn der Komponentenname davorsteht (`Spin1.MinValue` → `Spin1.Min`). In `with`-Blöcken erkennt das Skript sie nicht; dort meldet der Compiler den alten Namen.
5. **Ereignis-Handler** anpassen, deren Parametertyp sich ändert (DB-Grid: `TColumn` → `TPPGDBGridColumn`).
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
| TSplitter | | TPPGSplitter | PPG.Splitter |
| TSearchBox | | TPPGSearchEdit | PPG.SearchEdit |
| TMonthCalendar | | TPPGCalendar | PPG.Calendar |
| TDateTimePicker | | TPPGDatePicker (bei `Kind = dtkTime`: TPPGTimePicker, von Hand) | PPG.DatePicker |
| TStatusBar | | TPPGStatusBar | PPG.StatusBar |
| TDBEdit | | TPPGDBEdit | PPG.DB.Controls |
| TDBMemo | | TPPGDBMemo | PPG.DB.Controls |
| TDBCheckBox | | TPPGDBCheckBox | PPG.DB.Controls |
| TDBComboBox | | TPPGDBComboBox | PPG.DB.Controls |
| TDBLookupComboBox | | TPPGDBLookupComboBox | PPG.DB.Lookup |
| TDBGrid | | TPPGDBGrid | PPG.DB.Grid |
| TRadioGroup | TcxRadioGroup (DevExpress) | TPPGRadioGroup | PPG.RadioGroup |
| | TcxCheckGroup (DevExpress) | TPPGCheckGroup | PPG.RadioGroup |
| TDBRadioGroup | | TPPGDBRadioGroup | PPG.DB.Navigator |
| TDBNavigator | | TPPGDBNavigator | PPG.DB.Navigator |
| TScrollBox | | TPPGScrollBox | PPG.Panel |

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
| TBitBtn | `Kind`, `Glyph`, `NumGlyphs`, `Layout` | entfernt (Bilder über `Images`/`ImageIndex`) |
| TSpeedButton | `Glyph`, `NumGlyphs`, `Flat`, `Layout` | entfernt |
| TButton | `Style = bsPushButton/bsSplitButton` | `Style = pbsPushButton/pbsSplitButton` |
| TButton | `Style = bsCommandLink` | entfernt (gemeldet) |
| TDBGrid | `Options`: `dgAlwaysShowEditor`, `dgAlwaysShowSelection`, `dgThumbTracking`, `dgMultiSelect` | bleiben stehen, wirken aber nicht (gemeldet) |
| TDBNavigator | `Kind` | entfernt (der Navigator ist immer waagerecht) |

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

- **Bilder:** `Glyph` gibt es nicht; eine ImageList (bzw. ab 10.4 `TVirtualImageList`) zuweisen und `ImageIndex`/`ImageName` setzen.
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
