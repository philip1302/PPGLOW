# TPPGGrid

Palette **PPGlow** - Unit `PPG.Grid` - Basis `TPPGCustomGrid`

**Vorbild:** TStringGrid, TMS TAdvStringGrid

## Unterschiede und Hinweise

- `Row`/`Cells[]` arbeiten mit Datenzeilen, `Selection` mit sichtbaren Zeilen (Sortierung/Filter).
- Enter im Editor übernimmt und bleibt in der Zelle (wie `TStringGrid`); Pfeil hoch/runter im Text-Editor übernimmt und wechselt die Zeile.
- `OnSelectCell` kommt wie bei `TStringGrid` auch bei `Row`/`Col` im Code.
- Kopfklick sortiert: aufsteigend → absteigend → unsortiert. Zeilenhöhe nur per Code (`RowHeights`).
- UI Automation: Tabellen-Muster mit Kopfzeilen, Wert, Kästchen-Spalten und Sortieren per Invoke.

## Verhalten (aus dem Quelltext)

TPPGGrid - Tabelle im Stil der Suite (Phase 6c).

- Ein einziges Fenster, alle Zellen gezeichnet (keine Kind-Controls ausser dem gerade aktiven Editor). Scrollen, Overlay-Leisten, Mausrad und Auto-Scroll kommen aus TPPGCustomScrollControl.
- Feste Kopfzeilen/-spalten (FixedRows/FixedCols) bleiben beim Scrollen stehen. Zeilenpositionen ueber TPPGRowLayout: 1 000 000 Zeilen in O(1).
- Daten: Cells[] (wie TStringGrid) oder virtuell ueber OnGetCellText.
- Sortieren (Klick auf den Kopf) und Filtern (Filterzeile) arbeiten auf einem Index-Array "sichtbare Zeile -> Datenzeile", nie auf den Daten. Row und Cells[] verwenden immer DATEN-Zeilen; Selection (TGridRect) ist in sichtbaren Zeilen (wie bei TStringGrid ohne Sortierung identisch).
- Spalten (Columns): Titel, Breite, Ausrichtung, Editor (Text, Auswahl, Zahl, Kaestchen), Auswahlliste, Schreibschutz.
- Editoren sind PPGlow-Felder (TPPGEdit/TPPGComboBox/TPPGSpinEdit) ueber der Zelle: Enter uebernimmt, Esc verwirft, Tab uebernimmt und geht weiter, Scrollen und Fokusverlust uebernehmen.
- Zwischenablage als TSV (Strg+C / Strg+V), Export als CSV.
- DFM-kompatibel zu TStringGrid in den Grundproperties (ColCount, RowCount, FixedCols/Rows, DefaultColWidth/RowHeight, Options, ColWidths/RowHeights). Breiten und Hoehen sind wie ueberall in PPGlow logische 96-DPI-Pixel.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Images`, `Columns`, `ShowFilterRow`, `SortOnHeaderClick`, `ScrollBarMode`, `SmoothScrolling`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Anchors`, `BiDiMode`, `BorderStyle`, `Color`, `ColCount`, `Constraints`, `DefaultColWidth`, `DefaultDrawing`, `DefaultRowHeight`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `FixedCols`, `FixedRows`, `Font`, `Options`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `RowCount`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnClick`, `OnCompareCells`, `OnContextPopup`, `OnDblClick`, `OnDragDrop`, `OnDragOver`, `OnDrawCell`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnFixedCellClick`, `OnGetCellText`, `OnGetEditText`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnScroll`, `OnSelectCell`, `OnSetEditText`, `OnSorted`, `OnStartDock`, `OnStartDrag`, `OnTopLeftChanged`, `OnValidateCell`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGGrid.md`.
