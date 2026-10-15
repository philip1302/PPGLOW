**Vorbild:** TDBGrid

## Wofür

Das DB-Grid zeigt die Datensätze einer Datenmenge (Abfrage, Tabelle, ClientDataSet) als Tabelle und bearbeitet sie direkt in der Zelle. Es ersetzt `TDBGrid` mit derselben Bedienung (Datensatzzeiger, Einfg, Strg+Entf, Esc) und bringt die Optik, Spalten-Stile, bedingten Formate, Druck und Excel-Export von `TPPGGrid` mit. Daten, Regeln, Sortierung und Summen bleiben in der Datenmenge.

## Wann verwenden

- Für Listen und Erfassungstabellen, deren Daten aus einer Datenbank kommen und dorthin zurückgeschrieben werden: Kundenliste, Bestellpositionen, Buchungen.
- Statt `TPPGGrid`, wenn die Datenmenge die Quelle ist. Das `TPPGGrid` hält die Daten selbst und kann zusätzlich filtern, gruppieren und Summen rechnen; dafür Daten aus Objektlisten oder kleinen Abfragen hineinladen.
- Statt einzelner DB-Felder (`TPPGDBEdit` usw.), wenn mehrere Datensätze gleichzeitig zu sehen sein sollen. Für einen einzelnen Datensatz mit vielen Feldern ist ein Formular übersichtlicher; Grid und Formular an derselben `DataSource` zeigen denselben Satz.
- Zusammen mit `TPPGDBNavigator` für Blättern, Suchen und Speichern über Knöpfe.

## Unterschiede und Hinweise

- Nur der Puffer sichtbarer Datensätze wird gelesen; Paint greift nie auf die Datenmenge zu.
- `Options` ist `TDBGridOptions` (DFM-kompatibel); `dgColumnResize` erlaubt auch das Verschieben der Spalten (wie `TDBGrid`). Nicht unterstützt: `dgMultiSelect`, Gruppieren (dafür `GROUP BY` in der Abfrage).
- Spalten: `FieldName`, `Title` (statt `Title.Caption` – das Migrationsskript setzt das um), `Width`, `Alignment`, `ReadOnly`, `EditorKind`, `PickList`, `ButtonStyle`, `Visible`, `DisplayIndex`, `FooterField`. Die von `TPPGGridColumn` geerbten `Aggregate`, `FooterFormat`, `GroupIndex` und `Sortable` wirken im DB-Grid nicht. Automatische Spalten behalten Position, Sichtbarkeit und Breite beim Neuaufbau. `SaveLayout`/`LoadLayout` merken sich die Spalten über den Feldnamen.
- Summenzeile (`ShowFooter`) aus der Datenmenge: `Column.FooterField` (z. B. ein `TAggregateField`) oder `OnGetFooterText`.
- Drucken (`TPPGGridPrinter`) und Export (`PPG.Grid.Export`) lesen die ganze Datenmenge einmal (`DisableControls`, Lesezeichen, höchstens `ExportMaxRecords`).
- `OnTitleClick(Column)`/`OnCellClick(Column)` ohne Sender wie `TDBGrid`; Sortieren ist Sache der Datenmenge (im Kopfmenü sind die Sortier-Einträge gesperrt).
- Eingaben prüft die Datenmenge (`TField.OnValidate`, `Required`): Eine Ausnahme beim Schreiben zeigt die Meldung, der Editor bleibt mit der Eingabe offen.
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
