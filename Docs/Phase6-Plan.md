# Phase 6 – Detailplan: Daten- und Listen-Controls

*Stand 04.10.2026. Teil der Roadmap (`Docs\Roadmap.md`). **Vom User freigegeben am 04.10.2026.***

**Entscheidungen des Users (04.10.2026):** 6a bis 6c **am Stück** (Bericht erst am Ende); reiche Einträge über `Items` **und** `ItemsEx`; die ComboBox-Liste wird **in 6a** umgestellt; Umsortieren per Ziehen kommt **in 6a**.

## Status: umgesetzt (04.10.2026)
- **6a:** `TPPGListBox`, `TPPGCheckListBox`, ComboBox mit `ItemsEx` (Bild, Detail, Plakette, Markup), Bild im Feld (`csDropDownList`) und `FilterMode` (Anfang/enthält).
- **6b:** `TPPGTreeView` mit Lazy Loading, Kästchen mit Weitergabe, Umbenennen, Knoten ziehen (davor/danach/hinein), Linien, Sortieren.
- **6c:** `TPPGGrid` mit Spalten-Editoren (Text, Auswahl, Zahl, Kästchen), Sortieren, Filterzeile, Spaltenbreite ziehen, TSV/CSV, virtuell 1 000 000 Zeilen.
- **Qualität:** 410 Tests grün (77 neu); Benchmark mit drei neuen Vorgaben eingehalten; Win32/Win64.
- **Abweichungen vom Plan:**
  - **Combo-Liste:** Sie ist nicht der Nachfahre der ListBox. Ein Popup-Fenster und ein Scroll-Control können keine gemeinsame Basis haben. Stattdessen zeichnen alle mit demselben `TPPGItemPainter` (Komposition), und die Popup-Liste bekam Item-Quelle und Filter-Abbildung. Die Maussteuerung der Combo und alle 4b-Tests blieben unverändert.
  - **Baum, Aufklapp-Animation:** Nur der Pfeil dreht sich animiert, die Zeilen erscheinen sofort.
  - **Baum, virtueller Modus:** Er ist Lazy Loading über `HasChildren` + `OnExpanding` wie bei `TTreeView`, kein eigenes `OnGetChildCount`.
  - **Grid, Zeilenhöhe:** Die Spaltenbreite ist ziehbar, die Zeilenhöhe nur per Code (`RowHeights`).
  - **Grid, Barrierefreiheit:** Kinder sind die Zeilen. Das volle Tabellenmuster kommt mit UIA (Phase 9).

Phase 6 baut auf dem Fundament aus Phase 5 auf (Scroll-Basis, Zeilen-Layout, Auswahl, Item-Quellen, Markup) und auf dem modernen Design aus Phase 8 (Tokens, Dark Mode, Kurven, Icons). Sie wird in **drei Teilschritten** geliefert. Die Teilschritte werden nacheinander, aber ohne Zwischenstopp umgesetzt (Entscheidung des Users):

| Teil | Inhalt | Größe |
|---|---|---|
| **6a** | `TPPGListBox`, `TPPGCheckListBox`, ComboBox-Ausbau (Liste wird eine ListBox im Popup) | mittel |
| **6b** | `TPPGTreeView` | groß |
| **6c** | `TPPGGrid` | sehr groß |

## Gemeinsame Grundlagen (in 6a, für 6b/6c wiederverwendet)

| Unit | Inhalt |
|---|---|
| `Render\PPG.Render.Intf` | Neues Interface `IPPGItemRenderer` (Standard in `TPPGRendererBase`, Presets überschreiben nur, was anders aussieht): `DrawItemBackground(R, Style, Selected, Focused, HotProgress, PPI)` (Fluent: abgesetzte Pille mit Akzentbalken; Classic: Glanz-Verlauf), `DrawGroupHeader`, `DrawBadge`, `DrawExpander` (Baum-Pfeil mit Drehung), `DrawTreeLines`, `DrawDropIndicator` (Linie beim Umsortieren). Die vorhandenen `DrawListItem`/`DrawScrollThumb` des Popups gehen darin auf |
| `Controls\PPG.Controls.ItemList` | `TPPGCustomItemList` (erbt von `TPPGCustomScrollControl`): Quelle (`IPPGItemSource`), `TPPGRowLayout`, `TPPGSelection`, Hover, Tastatur (Pfeile, Bild, Pos1/Ende, Strg+A, Leertaste), Tippsuche (wie Combo, ohne Timer), Sichtbar-Machen des Fokus, Zeilen zeichnen (Bild, Text oder Markup, Detailzeile, Badge, Gruppen-Header), Barrierefreiheit über `IPPGAccessibleChildren` und `IPPGAccessibleMultiSelection`. ListBox, CheckListBox und Combo-Liste sind dünne Nachfahren |
| Farben | Ausschließlich Tokens und `EffectiveAppearance`: Hintergrund `Layer`, Text `TextPrimary`/`TextSecondary`, Auswahl Akzent. Damit funktionieren Dark Mode, VCL-Style und Hochkontrast (`clHighlight`) von Anfang an |

## 6a – ListBox, CheckListBox, ComboBox-Ausbau

**`TPPGListBox`** (DFM-kompatibel zu `TListBox`):
- `Items: TStrings` (wie `TListBox`, also `Items.Strings` in der DFM), `ItemIndex`, `MultiSelect`, `ExtendedSelect`, `Selected[]`, `SelCount`, `Sorted`, `TopIndex`, `ItemHeight`, `Columns` wird nur gelesen (keine Mehrspaltigkeit), `Style` (`lbStandard`, `lbOwnerDrawFixed/Variable` mit `OnDrawItem`/`OnMeasureItem`, `lbVirtual` mit `Count` + `OnData`), `AutoComplete`, `OnClick`, `OnDblClick`, `OnDrawItem`.
- Zusätzlich: `ItemsEx: TPPGItems` (Text, Detail, Bild, Badge, Gruppe – im Designer pflegbar). Ist `ItemsEx` gefüllt, ist es die Quelle; sonst `Items`; im virtuellen Stil `OnGetItem`.
- Gruppen-Header (gleicher `Group`-Text nacheinander), Detailzeile, Badge, Bilder aus `Images` (auch `ImageName` ab 10.4), Markup (`AllowMarkup`).
- Umsortieren per Ziehen innerhalb der Liste (`AllowReorder`, Ereignis `OnReorder`) mit Einfügelinie und Auto-Scroll. Die VCL-Drag-Properties (`DragMode`, `OnDragOver`, `OnDragDrop`) bleiben für Drag zwischen Controls nutzbar. OLE-Drag kommt nicht in Phase 6.
- Ereignisse wie bei der VCL: Code setzt Werte ohne Ereignis, Anwender-Aktionen lösen `OnClick` aus.

**`TPPGCheckListBox`** (DFM-kompatibel zu `TCheckListBox`):
- `Checked[]`, `State[]`, `AllowGrayed`, `ItemEnabled[]`, `Header[]`, `OnClickCheck`; Kästchen über `IPPGIndicatorRenderer` (also im Stil des Presets, Fluent11 mit Fluent-Haken).
- `CheckAll(State, AllowGrayed, AllowDisabled)` wie bei der VCL; Leertaste schaltet alle markierten Einträge um.

**ComboBox-Ausbau:**
- Die Liste im Popup wird eine `TPPGCustomItemList`; `TPPGPopupList` entfällt bzw. wird deren dünner Nachfahre. Verhalten, Ereignisse und Tests von Phase 4b bleiben unverändert (Regressionstests laufen weiter).
- Neu: Bilder (`Images`/`ImageIndex` pro Eintrag über `ItemsEx`), Detailzeile, Gruppen, Markup, **Filtern beim Tippen** (`FilterMode = fmNone/fmPrefix/fmContains`, gefiltert wird über ein Index-Array, nie in den Daten).

## 6b – TreeView

**`TPPGTreeView`**:
- Datenmodell: `TPPGTreeNodes`/`TPPGTreeNode` (Text, Detail, Bild, Kästchen, Daten, Kinder), DFM-fähig über `Items` wie `TTreeView` (Lesen des binären `TTreeView`-Formats ist **nicht** Ziel; eigenes, lesbares Format). Für große Bäume ein **virtueller Modus**: `OnGetChildCount`/`OnGetNode`, Kinder werden erst beim Aufklappen erfragt (lazy).
- Intern eine flache Liste der sichtbaren Knoten (Index-Array), damit Zeichnen, Scrollen, Auswahl und Barrierefreiheit die Infrastruktur von 6a nutzen.
- Aufklappen/Zuklappen animiert (Expander dreht sich, nachfolgende Zeilen gleiten, `ekDecelerate`), Tastatur wie Windows (←/→ zu-/aufklappen bzw. zum Eltern-/ersten Kind, `*` alles aufklappen, `+`/`-`).
- Kästchen mit drei Zuständen und Weitergabe an Kinder/Eltern (`AutoCheck`), Inline-Umbenennen über ein natives Edit (`ReadOnly`, `OnEditing`/`OnEdited`, Enter/Esc, Scrollen schließt den Editor), Drag & Drop von Knoten (VCL-Drag) mit Einfügemarke (davor/danach/hinein).
- Linien optional (`ShowLines`, Fluent-Standard ohne Linien), `Indent`, `RowSelect`, `HideSelection`, `ShowRoot`.
- Barrierefreiheit: Rolle Gliederung/Gliederungselement, Ebene und Zustand aufgeklappt/zugeklappt.

## 6c – Grid

**`TPPGGrid`**:
- Ein einziges Fenster, Zellen gezeichnet (keine VCL-Kind-Controls). Virtuell: `RowCount`/`ColCount` + `OnGetCellText` bzw. eingebauter Zellspeicher (`Cells[]` wie `TStringGrid`, DFM-kompatible Grundproperties).
- Feste Kopfzeilen und -spalten (`FixedRows`/`FixedCols`), Spaltenbreite und Zeilenhöhe per Ziehen, Spalten-Collection (`Columns`: Titel, Breite, Ausrichtung, Editor-Art, Format).
- Sortieren per Klick auf den Kopf und Filterzeile – beides über ein **Index-Array**, nie auf den Daten.
- Auswahl: Zelle, Zeile, Bereich (Erweiterung von `TPPGSelection` um Rechtecke).
- Zelleditoren über die Feld-Basis: Edit, Combo, Spin, Check; Fokus, Enter/Esc/Tab, Scrollen bewegt den Editor mit bzw. schließt ihn (Muster aus der ComboBox).
- Kopieren/Einfügen als TSV über die Zwischenablage, Export CSV.
- Barrierefreiheit über MSAA soweit möglich (Zeilen als Kinder); das volle Tabellenmuster kommt mit UIA in Phase 9.

## Bewusste Entscheidungen (Vorschlag)
- Erst **6a vollständig**, dann Bericht und OK, dann 6b, dann 6c.
- **DFM-Kompatibilität** zu `TListBox`/`TCheckListBox`/`TStringGrid` bei den Grundproperties, damit Formulare per Suchen/Ersetzen migriert werden können. `TTreeView`-DFMs (Binärdaten der Knoten) werden nicht gelesen.
- Reiche Einträge über `ItemsEx` (Collection) **zusätzlich** zu `Items: TStrings` statt eines völlig neuen Modells.
- Keine OLE-Drag-Unterstützung in Phase 6 (VCL-Drag genügt für Drag innerhalb der Anwendung).
- Kein Mehrspalten-Modus der ListBox (`Columns`), dafür gibt es das Grid.
- Leistung: Liste und Baum mit 1 000 000 Einträgen bzw. 100 000 sichtbaren Knoten flüssig; Grid mit 1 000 000 × 20 Zellen (virtuell). Neue Vorgaben im Benchmark.

## Tests (`Tests\PPG.Tests.Phase6a/6b/6c.pas`)
- Lebenszyklus, DFM-Roundtrip (inkl. DFM einer echten `TListBox`/`TCheckListBox` mit Klassennamen ersetzt), Streaming von `ItemsEx`.
- Verhalten: Maus (Klick, Strg/Shift, Doppelklick, Ziehen zum Umsortieren), Tastatur, Tippsuche, Ereignisreihenfolge wie VCL, Code ohne Ereignisse.
- Quellen: Strings, Collection, virtuell; Einfügen/Löschen verschiebt Auswahl und Fokus.
- Zeichnen: Pixeltests in allen Presets, hell/dunkel, GDI+/GDI, Hochkontrast-Zweig; Gruppen, Badge, Markup, Bilder.
- Barrierefreiheit: Kinder, Name, Rolle, Zustand, Mehrfachauswahl, Fokus-Ereignisse.
- Combo: alle Tests aus 4b laufen unverändert weiter; neu Filtern und Bilder.
- Ressourcen: keine Handle- oder Speicherlecks; Benchmark-Vorgaben.

## Demo
- Neue Seite „Listen“ (ListBox mit Gruppen/Badges/Markup, CheckListBox, virtuelle Liste mit 1 000 000 Einträgen, Combo mit Bildern und Filter), später „Baum“ und „Grid“.
- Screenshot-Schalter `/page n` wie bisher.

## Fragen an den User
Beantwortet am 04.10.2026 (siehe „Entscheidungen des Users“ oben).
