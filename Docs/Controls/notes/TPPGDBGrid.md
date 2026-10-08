**Vorbild:** TDBGrid

## Unterschiede und Hinweise

- Nur der Puffer sichtbarer Datensätze wird gelesen; Paint greift nie auf die Datenmenge zu.
- `Options` ist `TDBGridOptions` (DFM-kompatibel); `dgColumnResize` erlaubt auch das Verschieben der Spalten (wie `TDBGrid`). Nicht unterstützt: `dgMultiSelect`, Gruppieren (dafür `GROUP BY` in der Abfrage).
- Spalten: `FieldName`, `Title` (statt `Title.Caption` – das Migrationsskript setzt das um), `Width`, `Alignment`, `ReadOnly`, `EditorKind`, `PickList`, `Visible`, `DisplayIndex`, `FooterField`. Automatische Spalten behalten Position, Sichtbarkeit und Breite beim Neuaufbau. `SaveLayout`/`LoadLayout` merken sich die Spalten über den Feldnamen.
- Summenzeile (`ShowFooter`) aus der Datenmenge: `Column.FooterField` (z. B. ein `TAggregateField`) oder `OnGetFooterText`.
- Drucken (`TPPGGridPrinter`) und Export (`PPG.Grid.Export`) lesen die ganze Datenmenge einmal (`DisableControls`, Lesezeichen, höchstens `ExportMaxRecords`).
- `OnTitleClick(Column)`/`OnCellClick(Column)` ohne Sender wie `TDBGrid`; Sortieren ist Sache der Datenmenge.
- Im Designer: „Edit columns...“ und „Add all fields“.

## Anpassung

- Dieselben `Styles`, Spalten-`Style`/`TitleStyle`/`TitleAlignment` und `GridLineWidth` wie `TPPGGrid`.
- `TitleFont` (wie `TDBGrid`) ist `Styles.Header.Font`; `migrate.ps1` überträgt `Title.Font`, `Title.Color`, `Title.Alignment`, `Font` und `Color` der Spalten.

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
