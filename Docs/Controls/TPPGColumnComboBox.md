# TPPGColumnComboBox

Palette **PPGlow** - Unit `PPG.ColumnComboBox` - Basis `TPPGCustomDropDownField`

**Vorbild:** TMS TAdvMultiColumnComboBox

## Unterschiede und Hinweise

- `Columns` enthält Titel, Breite in logischen Pixeln, Ausrichtung und Sichtbarkeit. Die Zeilen kommen aus `Items`, jede Zeile mit den Zellen getrennt durch `ColumnDelimiter` (`1001|Albers|Hamburg`).
- Virtuell: `VirtualRowCount` > 0 und `OnGetCellText` liefern die Zellen. Auch 100 000 Zeilen klappen ohne Kopie auf.
- Ein Klick auf die Kopfzeile sortiert die Ansicht, ein zweiter Klick kehrt die Richtung um. Die Daten bleiben unverändert.
- `KeyColumn`/`KeyValue` liefern den Schlüssel, `DisplayColumn` den Text im Feld. Die Tippsuche arbeitet in der Anzeigespalte, offen und geschlossen.
- Geschlossen blättern die Pfeile die Auswahl (wie eine DropDownList).
- Abweichung vom Plan: Die Zeilen liegen in `Items` mit Trennzeichen statt in `ItemsEx` mit `SubItems`, weil die Einträge der Suite keine Unterspalten haben.
- Die Zeile zeichnet das Control selbst, schlank. Die Zellroutine des Grids aus Phase 13 soll das übernehmen.

## Beispiel

```pascal
PPGColumnComboBox1.Columns.Add.Title := 'Nr';
PPGColumnComboBox1.Columns.Add.Title := 'Name';
PPGColumnComboBox1.Items.Add('1001|Albers GmbH');
PPGColumnComboBox1.DisplayColumn := 1;
PPGColumnComboBox1.KeyValue := '1001';
```

## Verhalten (aus dem Quelltext)

TPPGColumnComboBox - mehrspaltige Auswahl mit Kopfzeile (Phase 12e,
Vorbild TMS TAdvMultiColumnComboBox).

- Columns (Titel, Breite in logischen px, Ausrichtung) und Zeilen aus Items: jede Zeile enthaelt die Zellen getrennt durch ColumnDelimiter ("1001|Mueller|Berlin"). Virtuell: VirtualRowCount > 0 und OnGetCellText liefern die Zellen (z.B. 100 000 Zeilen ohne Kopie).
- Kopfzeile im Popup; Klick sortiert (aufsteigend/absteigend), die Reihenfolge der Daten bleibt unveraendert (nur die Ansicht).
- KeyColumn/KeyValue fuer den Schluessel (DB-Anbindung), DisplayColumn fuer den Text im Feld. Tippsuche in der Anzeigespalte (offen und geschlossen).
- Zeichnen: schlanke eigene Zeile; die Zellroutine des Grids (TPPGCellPainter, Phase 13) soll das spaeter uebernehmen.
- OnChange nur bei Auswahl durch den Anwender; ItemIndex/KeyValue aus Code ohne Ereignis.

## PPGlow-Eigenschaften

`Columns`, `Items`, `ColumnDelimiter`, `VirtualRowCount`, `KeyColumn`, `DisplayColumn`, `DropDownCount`, `DropDownWidth`, `Preset`, `StyleManager`, `Appearance`, `Animation`, `TextHint`, `ValidationState`, `ValidationHint`, `HighContrastSupport`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `BorderStyle`, `Color`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ReadOnly`, `ReadOnlyStyle`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`, `Touch`

## Ereignisse

`OnGetCellText`, `OnGesture`, `OnChange`, `OnCloseUp`, `OnDropDown`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGColumnComboBox.md`.
