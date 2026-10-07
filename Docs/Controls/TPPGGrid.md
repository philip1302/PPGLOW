# TPPGGrid

Palette **PPGlow** - Unit `PPG.Grid` - Basis `TPPGCustomGrid`

**Vorbild:** TStringGrid, TMS TAdvStringGrid, DevExpress Grid (Gruppenleiste)

## Unterschiede und Hinweise

- `Row`/`Col`/`Cells[]` arbeiten mit Daten-Indizes, `Selection`/`FocusRow`/`FocusCol`/`CellRect` mit der Anzeige (Sortierung, Filter, verschobene Spalten). Umrechnen mit `DataRow`/`VisualRow`, `DataCol`/`VisualCol`.
- Enter im Editor übernimmt und bleibt in der Zelle (wie `TStringGrid`); Pfeil hoch/runter im Text-Editor übernimmt und wechselt die Zeile.
- Kopfklick sortiert: aufsteigend → absteigend → unsortiert. Rechtsklick auf den Kopf: Kopfmenü (Sortieren, Gruppieren, Ausblenden, Spaltenauswahl, optimale Breite), erweiterbar über `OnHeaderMenu`.
- Spalten (`Columns`): verschieben per Ziehen (`goColMoving`), `Visible`, `DisplayIndex`, Doppelklick auf die Kopfkante passt die Breite an, `FixedColsRight`, `Bands` (auch mehrstufig).
- Gruppieren: `GroupBy`/`Column.GroupIndex` oder Kopf in die Gruppenleiste ziehen (`ShowGroupPanel`). Gruppenzeilen mit Pfeil (Klick, Doppelklick, Pfeiltasten, Enter/Leertaste), Text über `OnGetGroupText` (Markup).
- Summen: `ShowFooter`, `GroupFooter`, `Column.Aggregate`/`FooterFormat`, `agCustom` über `OnCustomAggregate`. Summen gelten für die gefilterte Ansicht.
- Zellen: `Column.CellKind` (Kästchen, Fortschritt, Sparkline, Bewertung, Bild, Link, Button, Farbfeld, Markup; eigene über `PPGRegisterCellKindName`), `ConditionalFormats`, `OnGetCellStyle`, `MergeCells`.
- Layout merken: `SaveLayout`/`LoadLayout` (Reihenfolge, Breiten, Sichtbarkeit, Sortierung, Gruppen).
- Drucken mit `TPPGGridPrinter`; Export über `PPG.Grid.Export` (xlsx, PDF, HTML, CSV), Import `PPGLoadXlsx`.
- UI Automation: Tabellen-Muster mit Kopfzeilen, Gruppenzeilen (Auf-/Zuklappen), Kästchen, Links und Buttons (Invoke).

## Beispiel

```pascal
Grid1.Columns[2].Aggregate := agSum;
Grid1.ShowFooter := True;
Grid1.GroupBy([1]);                       // nach Kategorie gruppieren
PPGExportXlsx(Grid1 as IPPGTableSource, 'Liste.xlsx');
```

## Verhalten (aus dem Quelltext)

TPPGGrid - Tabelle im Stil der Suite (Phase 6c).

- Ein einziges Fenster, alle Zellen gezeichnet (keine Kind-Controls ausser dem gerade aktiven Editor). Scrollen, Overlay-Leisten, Mausrad und Auto-Scroll kommen aus TPPGCustomScrollControl.
- Feste Kopfzeilen/-spalten (FixedRows/FixedCols) bleiben beim Scrollen stehen. Zeilenpositionen ueber TPPGRowLayout: 1 000 000 Zeilen in O(1).
- Daten: Cells[] (wie TStringGrid) oder virtuell ueber OnGetCellText.
- Sortieren (Klick auf den Kopf) und Filtern (Filterzeile) arbeiten auf einem Index-Array "sichtbare Zeile -> Datenzeile", nie auf den Daten. Row und Cells[] verwenden immer DATEN-Zeilen; Selection (TGridRect) ist in sichtbaren Zeilen (wie bei TStringGrid ohne Sortierung identisch).
- Spalten (Columns): Titel, Breite, Ausrichtung, Editor (Text, Auswahl, Zahl, Kaestchen), Auswahlliste, Schreibschutz.
- Spalten in der Anzeige (Phase 13b): verschieben (Ziehen am Kopf, goColMoving), ausblenden (Visible, Kopfmenue), Breite per Doppelklick, rechts fixieren (FixedColsRight), Baender (Bands) und Layout speichern.
- Gruppieren und Summen (Phase 13c): Column.GroupIndex bzw. GroupBy, Gruppen- leiste (ShowGroupPanel, Kopf hineinziehen), Gruppenzeilen mit Pfeil und Markup-Text (OnGetGroupText), Summenzeile (ShowFooter) und Gruppenfuss (GroupFooter) ueber Column.Aggregate. Summen gelten fuer die Ansicht (gefiltert), werden beim Aendern von Ansicht oder Daten neu berechnet und zwischengespeichert - nie beim Zeichnen.
- Zellen (Phase 13d): verbundene Zellen (MergeCells; nur ohne Sortierung, Filter und Gruppierung - dann ruhen sie), bedingte Formate (ConditionalFormats, OnGetCellStyle) und Zellarten je Spalte (Column.CellKind ueber IPPGCellKind: Kaestchen, Fortschritt, Sparkline, Bewertung, Bild, Link, Button, Farbfeld, Markup). Intern sind Spalten-Indizes von Geometrie, Fokus und Auswahl ANZEIGE- Spalten (wie sichtbare Zeilen); Cells[], Col, Columns[] und Ereignisse verwenden DATEN-Spalten. DataCol/VisualCol rechnen um.
- Editoren sind PPGlow-Felder (TPPGEdit/TPPGComboBox/TPPGSpinEdit) ueber der Zelle: Enter uebernimmt, Esc verwirft, Tab uebernimmt und geht weiter, Scrollen und Fokusverlust uebernehmen.
- Zwischenablage als TSV (Strg+C / Strg+V), Export als CSV.
- DFM-kompatibel zu TStringGrid in den Grundproperties (ColCount, RowCount, FixedCols/Rows, DefaultColWidth/RowHeight, Options, ColWidths/RowHeights). Breiten und Hoehen sind wie ueberall in PPGlow logische 96-DPI-Pixel.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Images`, `Bands`, `Columns`, `ShowFilterRow`, `FixedColsRight`, `HeaderMenu`, `ShowFooter`, `GroupFooter`, `ShowGroupPanel`, `ConditionalFormats`, `SortOnHeaderClick`, `ScrollBarMode`, `SmoothScrolling`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Anchors`, `BiDiMode`, `BorderStyle`, `Color`, `ColCount`, `Constraints`, `DefaultColWidth`, `DefaultDrawing`, `DefaultRowHeight`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `FixedCols`, `FixedRows`, `Font`, `Options`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `RowCount`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnClick`, `OnCompareCells`, `OnCellButtonClick`, `OnColumnMoved`, `OnCustomAggregate`, `OnContextPopup`, `OnDblClick`, `OnDragDrop`, `OnDragOver`, `OnDrawCell`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnFixedCellClick`, `OnGetCellText`, `OnGetEditText`, `OnGetGroupText`, `OnGetCellStyle`, `OnHeaderMenu`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnLinkClick`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnScroll`, `OnSelectCell`, `OnSetEditText`, `OnSorted`, `OnStartDock`, `OnStartDrag`, `OnTopLeftChanged`, `OnValidateCell`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGGrid.md`.
