# Phase 18 – Detailplan: VCL-Lücken für Umstellungen

*Stand 08.10.2026. Teil von `Docs\Roadmap3.md` (freigegeben: komplett mit ListView). **Entscheidungen nach Empfehlung (vom User vorab übernommen: „nimm die Empfehlungen“). Umsetzung erst nach OK zum Plan.***

## Ziel
Für die VCL-Controls, die in fast jedem Geschäftsformular stehen, gibt es bisher kein PPGlow-Gegenstück. Nach der Umstellung blieben sie Standard-VCL und fielen optisch heraus. Jedes neue Control soll:
- im DFM kompatibel zum VCL-Vorbild sein (gleiche Property-Namen, Vorgaben und Ereignisse), damit `migrate.ps1` nur den Klassennamen tauschen muss
- die bekannten Bausteine nutzen: Presets, Dark Mode, Element-Stile, Tokens, Zeichen-Ereignisse, MSAA/UIA, DPI, RTL, Übersetzung
- Palettensymbol, Hilfe-Notiz, Property-Referenz, Demo-Szenario, Streaming- und Sichttests bekommen

## Teilschritte

| Teil | Inhalt | Größe |
|---|---|---|
| 18a | `TPPGRadioGroup`, `TPPGCheckGroup` | klein |
| 18b | DB-Controls: `TPPGDBNavigator`, `TPPGDBText`, `TPPGDBRadioGroup`, `TPPGDBListBox`, `TPPGDBLookupListBox`, `TPPGDBSpinEdit`, `TPPGDBToggleSwitch` | mittel (viele kleine) |
| 18c | `TPPGScrollBox` | mittel |
| 18d | `TPPGListView` | groß |
| 18e | `migrate.ps1`, Demo, Doku, Abschlussprüfung | klein |

Reihenfolge a → b → c → d → e. Die kleinen Controls kommen zuerst, damit früh etwas Nutzbares da ist. Die ListView als größtes Risiko kommt am Ende, aber vor der Migration.

## 18a – RadioGroup und CheckGroup (`PPG.RadioGroup`)
- `TPPGRadioGroup` wie `TRadioGroup`:
  - Properties: `Items`, `ItemIndex`, `Columns`, `Caption`
  - Rahmen und Plakette wie `TPPGGroupBox` (gemeinsame Basis)
  - Ereignisse: `OnClick`; `OnChange` nur bei Anwenderaktion (PPGlow-Regel: Code setzt ohne Ereignis)
- **Selbst gezeichnete Einträge** in einem Fenster (wie die CheckListBox), statt je Eintrag ein `TPPGRadioButton`:
  - schneller, keine Fensterflut, einheitlich gezeichnet
  - Kreise kommen vom `IPPGIndicatorRenderer` des Presets
  - Tastatur wie VCL: Pfeile wechseln die Auswahl, Tab geht in die Gruppe
  - Accelerator `&` in den Einträgen
  - Screenreader-Kinder über `IPPGAccessibleChildren` (Rolle Optionsfeld)
- Zusätze: `ItemEnabled[i]`, `ItemHint[i]`, Element-Stile `Styles.Item`/`Styles.Selected`, `OnCustomDrawItem`
- `TPPGCheckGroup` (wie `TcxCheckGroup`/TMS `TAdvOfficeCheckGroup`):
  - `Checked[i]`, `State[i]` mit `AllowGrayed`
  - `OnItemClick`
  - Werte als Text (`Value` = Kommaliste, praktisch für DB und Einstellungen)

## 18b – DB-Controls (`PPG.DB.Controls`, `PPG.DB.Lookup`, Paket `PPGlowDBR`)
- **`TPPGDBNavigator`** wie `TDBNavigator`:
  - Properties: `VisibleButtons`, `Hints`, `ConfirmDelete`, `Flat`
  - Ereignisse: `BeforeAction`/`OnClick` mit `TNavigateBtn`
  - Ein Control mit selbst gezeichneten Knöpfen und Fluent-Symbolen, Zustände aus dem DataLink (Anfang/Ende, Bearbeiten)
  - Texte übersetzt, Tastatur innerhalb des Navigators, Screenreader-Kinder
- **`TPPGDBText`** wie `TDBText`, auf `TPPGLabel` (`DataSource`, `DataField`, `AutoSize`, `WordWrap`)
- **`TPPGDBRadioGroup`** wie `TDBRadioGroup` (`Values` neben `Items`, `ReadOnly`), auf 18a
- **`TPPGDBListBox`** wie `TDBListBox`; **`TPPGDBLookupListBox`** wie `TDBLookupListBox` (`ListSource`, `KeyField`, `ListField`), Logik wie die vorhandene Lookup-Combo
- **`TPPGDBSpinEdit`**, **`TPPGDBToggleSwitch`** (`ValueChecked`/`ValueUnchecked` wie `TDBCheckBox`)
- Gemeinsam: der vorhandene `TPPGFieldDataLink`, Fehler am Feld statt Dialog (Phase-9-Regel), Feldauswahl im Objektinspektor

## 18c – ScrollBox (`PPG.ScrollBox`)
- `TPPGScrollBox` wie `TScrollBox`:
  - Properties: `HorzScrollBar`/`VertScrollBar` (Range, Increment, Tracking, Visible), `AutoScroll`, `BorderStyle`
  - Methode `ScrollInView`; DFM wie `TScrollBox`
- **Echte Kind-Fenster scrollen** (anders als die bisherigen PPGlow-Scroll-Controls, die nur selbst gezeichneten Inhalt verschieben). Die Overlay-Scrollleisten der Phase-5-Basis bleiben in der Optik.
  - Verschieben per `ScrollWindowEx` mit `SW_SCROLLCHILDREN`, kein Flackern
  - Mausrad auch über Kind-Controls, die es nicht selbst brauchen (über den vorhandenen Nachrichten-Verteiler `PPG.AppHooks`)
  - Fokuswechsel per Tab bringt das Control ins Bild (wie VCL)
- Fläche wie `TPPGPanel` (Eltern-Hintergrund für Kinder, Dark Mode)
- Die Tour aus Phase 16 bekommt damit ihr `ScrollInView`.

## 18d – ListView (`PPG.ListView`)
**Eigenes Control auf der Listen-Basis** (`TPPGCustomItemList`, Item-Painter, Selection, Row-Layout), kein umgezeichnetes natives `TListView`. Nur so stimmen Presets, Dark Mode, Element-Stile und Barrierefreiheit wie bei den übrigen Listen.
- API und DFM wie `TListView`:
  - `ViewStyle` (`vsReport`, `vsList`, `vsSmallIcon`, `vsIcon`), `Items`/`TListItem`-ähnliches `TPPGListItem` (`Caption`, `SubItems`, `ImageIndex`, `Checked`, `Data`, `Selected`, `Focused`)
  - `Columns` (`Caption`, `Width`, `Alignment`, `AutoSize`), `LargeImages`/`SmallImages`
  - `MultiSelect`, `RowSelect`, `Checkboxes`, `GridLines`, `HideSelection`, `ReadOnly`, `SortType`/`AlphaSort`/`CustomSort`
  - Gruppen (`Groups`, `GroupView`)
- Virtuell wie `TListView`: `OwnerData` + `OnData`, `OnDataFind`, `Items.Count` setzbar (Ziel: 1 Mio. Einträge flüssig, Benchmark wie bei ListBox/Grid)
- Bedienung:
  - Kopf klicken (`OnColumnClick`), Spaltenbreite ziehen, Doppelklick auf die Kopfkante
  - Umbenennen per F2/Klick (`OnEditing`/`OnEdited`)
  - Ziehen aus der Liste (`DragMode`)
  - Tastatur und Tippsuche wie Windows
- Ereignisse wie VCL: `OnChange`, `OnSelectItem`, `OnItemChecked`, `OnCompare`, `OnCustomDrawItem`/`OnCustomDrawSubItem`
- Symbol- und Listenansicht: Raster mit Umbruch, Beschriftung mehrzeilig unter dem Symbol, Auswahlrahmen per Maus (Gummiband) in den Symbolansichten
- Barrierefreiheit: UIA-Provider wie bei ListBox/Grid (Liste bzw. Tabelle in `vsReport`)
- Bewusst nicht: Kacheln (`vsTile`), Arbeitsbereiche (`WorkAreas`), Hintergrundbild, natives Header-Control

## 18e – Migration, Demo, Doku, Prüfung
- `migrate.ps1`:
  - `TRadioGroup`→`TPPGRadioGroup`, `TScrollBox`→`TPPGScrollBox`, `TListView`→`TPPGListView`, `TDBNavigator`, `TDBText`, `TDBRadioGroup`, `TDBListBox`, `TDBLookupListBox`
  - DevExpress/TMS-Gegenstücke, soweit 1:1 (`TcxRadioGroup`, `TcxCheckGroup`, `TcxListView`, `TAdvListView`)
  - Event-Signaturen prüfen (`TLVSelectItemEvent` u. a.), Selbsttest-Fixtures ergänzen
- Demo: Formularseite (RadioGroup/CheckGroup), Datenbankseite (Navigator, DBText, DB-RadioGroup …), Seite Listen/Explorer (ListView in allen Ansichten, virtuell), ScrollBox als Karte mit vielen Feldern. Selbsttest-Szenarien.
- Tests:
  - je Control Lebenszyklus, Paint GDI+ und GDI, Verhalten, Streaming, Sichtgalerie, UIA
  - Regressionstest für jede gefundene Abweichung zur VCL (Gegenprobe mit dem VCL-Control)
- Abschluss: Win32/Win64, Leak-Lauf, Benchmark (ListView), Regel-Prüfer, Palettensymbole (`make-icons.ps1`), Property-Referenz, Hilfe-Notizen, `Docs\Migration.md`

## Entscheidungen (alle nach Empfehlung, vom User übernommen)
1. **RadioGroup-Einträge selbst gezeichnet** in einem Fenster (nicht je Eintrag ein RadioButton).
2. **ListView als eigenes Control** auf der Listen-Basis (kein umgezeichnetes natives `TListView`).
3. **ListView virtuell** über `OwnerData`/`OnData` wie die VCL.
4. **ListView ohne** Kacheln, `WorkAreas` und Hintergrundbild.
5. **ScrollBox scrollt echte Kind-Fenster** mit der PPGlow-Optik der Scrollleisten.
6. **DB-Navigator als ein Control** mit selbst gezeichneten Knöpfen (wie die ToolBar).
7. **Reihenfolge** 18a → 18e, Bericht nach 18e. Zwischenstände nach 18b und 18c in `NAECHSTE-SCHRITTE.md`.

## Risiken
- ListView: Umfang und die vielen VCL-Eigenheiten (Index-Semantik bei `OwnerData`, `Selected` vs. `ItemFocused`, Ereignisreihenfolge). Gegenmittel: Gegenprobe-Tests mit dem echten `TListView`.
- ScrollBox: Kind-Fenster beim Scrollen und bei DPI-Wechsel, VCL-Styles (`TScrollBox` hat eigene Style-Hooks).
- XE2: weiterhin nicht kompiliert (Absicherungsblock außerhalb der Phasen).
