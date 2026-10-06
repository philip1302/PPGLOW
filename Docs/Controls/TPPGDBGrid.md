# TPPGDBGrid

Palette **PPGlow DB** - Unit `PPG.DB.Grid` - Basis `TPPGCustomDBGrid`

**Vorbild:** TDBGrid

## Unterschiede und Hinweise

- Nur der Puffer sichtbarer Datensätze wird gelesen; Paint greift nie auf die Datenmenge zu.
- `Options` ist `TDBGridOptions` (DFM-kompatibel); `dgColumnResize` erlaubt auch das Verschieben der Spalten (wie `TDBGrid`). Nicht unterstützt: `dgMultiSelect`, Gruppieren (dafür `GROUP BY` in der Abfrage).
- Spalten: `FieldName`, `Title` (statt `Title.Caption` – das Migrationsskript setzt das um), `Width`, `Alignment`, `ReadOnly`, `EditorKind`, `PickList`, `Visible`, `DisplayIndex`, `FooterField`. Automatische Spalten behalten Position, Sichtbarkeit und Breite beim Neuaufbau. `SaveLayout`/`LoadLayout` merken sich die Spalten über den Feldnamen.
- Summenzeile (`ShowFooter`) aus der Datenmenge: `Column.FooterField` (z. B. ein `TAggregateField`) oder `OnGetFooterText`.
- Drucken (`TPPGGridPrinter`) und Export (`PPG.Grid.Export`) lesen die ganze Datenmenge einmal (`DisableControls`, Lesezeichen, höchstens `ExportMaxRecords`).
- `OnTitleClick(Column)`/`OnCellClick(Column)` ohne Sender wie `TDBGrid`; Sortieren ist Sache der Datenmenge.
- Im Designer: „Edit columns...“ und „Add all fields“.

## Beispiel

```pascal
procedure TForm1.PPGDBGrid1TitleClick(Column: TPPGDBGridColumn);
begin
  ClientDataSet1.IndexFieldNames := Column.FieldName;
end;

// Summenzeile aus einem TAggregateField 'Gesamt' (SUM(Betrag))
TPPGDBGridColumn(PPGDBGrid1.Columns[2]).FooterField := 'Gesamt';
PPGDBGrid1.ShowFooter := True;
```

## Verhalten (aus dem Quelltext)

TPPGDBGrid - Tabelle einer Datenmenge (Phase 9c), wie TDBGrid.

Aufbau:
- Erbt von TPPGCustomGrid (Zeichnen, Editoren, Tastatur, UIA bleiben).
- Zeilen sind der Puffer des TDataLink (BufferCount = sichtbare Zeilen), nie die ganze Tabelle. Die Kopfzeile zeigt die Titel, die feste Spalte links den Datensatzzeiger (Indikator).
- Die Texte des Puffers werden in den DataLink-Ereignissen gelesen und zwischengespeichert. Paint liest nur den Zwischenspeicher: kein Datensatzwechsel und keine Anwender-Ereignisse (OnGetText, OnCalcFields) waehrend des Zeichnens (Fallstrick aus der Roadmap).
- Die senkrechte Leiste zeigt die Lage in der Datenmenge: bei IsSequenced nach RecNo/RecordCount, sonst dreistufig (Anfang, Mitte, Ende) wie TDBGrid. Ziehen, Mausrad und Blaettern bewegen die Datenmenge.
- Spalten: ohne Columns alle sichtbaren Felder (Titel = DisplayLabel, Breite aus DisplayWidth); mit Columns (FieldName je Spalte) genau diese.
- Bearbeiten mit den Grid-Editoren; der Editor zeigt Field.Text, Schreiben setzt Field.Text (Boolean-Felder: Kaestchen-Spalte).
- Tastatur wie TDBGrid: Pfeile/Bild/Strg+Pos1/Ende bewegen die Datenmenge, Pfeil runter am Ende haengt an (dgEditing), Einfg fuegt ein, Strg+Entf loescht (mit Rueckfrage bei dgConfirmDelete), Esc bricht ab.
- Sortieren ist Sache der Datenmenge: Klick auf den Titel loest OnTitleClick aus (dgTitleClick).
- Spalten verschieben (dgColumnResize, wie TDBGrid), ausblenden, Layout speichern (Schluessel = Feldname) wie im Grid (Phase 13g); automatische Spalten behalten Position, Sichtbarkeit und Breite beim Neuaufbau.
- Summenzeile (ShowFooter) aus der Datenmenge: Column.FooterField (z.B. ein TAggregateField) oder OnGetFooterText. Das Grid liest dafuer nie die ganze Datenmenge (Paint-Regel aus Phase 9).
- Drucken und Export (IPPGTableSource): die Datenmenge wird einmal mit DisableControls und Lesezeichen durchlaufen (hoechstens ExportMaxRecords).
- Nicht unterstuetzt: Gruppieren (braeuchte die ganze Datenmenge im Speicher; GROUP BY in der Abfrage nutzen), dgMultiSelect, Unterspalten (ADT/Array-Felder).

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Columns`, `Bands`, `ConditionalFormats`, `ExportMaxRecords`, `FixedColsRight`, `HeaderMenu`, `ShowFooter`, `DataSource`, `Options`, `ReadOnly`, `ScrollBarMode`, `SmoothScrolling`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Anchors`, `BiDiMode`, `BorderStyle`, `Color`, `Constraints`, `DefaultDrawing`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnCellClick`, `OnColumnMoved`, `OnContextPopup`, `OnDblClick`, `OnDragDrop`, `OnDragOver`, `OnDrawCell`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnGetCellStyle`, `OnGetFooterText`, `OnHeaderMenu`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnStartDock`, `OnStartDrag`, `OnTitleClick`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBGrid.md`.
