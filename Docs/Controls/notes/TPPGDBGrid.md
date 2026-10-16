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
- `Options` ist `TDBGridOptions` (DFM-kompatibel); `dgColumnResize` erlaubt auch das Verschieben der Spalten (wie `TDBGrid`). Nicht unterstützt: Gruppieren (dafür `GROUP BY` in der Abfrage).
- Mehrfachauswahl mit `dgMultiSelect` wie bei `TDBGrid`: `SelectedRows` (`TPPGBookmarkList`) mit `Count`, `Items[]`, `CurrentRowSelected`, `Clear`, `SelectAll`, `Delete`, `Find`, `IndexOf` und `Refresh`. Strg+Klick schaltet um, Umschalt+Klick wählt den Bereich vom Anker, Umschalt+Pfeil erweitert, Strg+A wählt alles, Strg+Leertaste schaltet um, Strg+Entf löscht die Auswahl (Rückfrage bei `dgConfirmDelete`). Klick oder Pfeil ohne Taste heben die Auswahl auf. Gewählte Zeilen erscheinen in der Auswahlfarbe (`Styles.Selection`), im Indikator mit Haken. `OnSelectionChanged` meldet Änderungen. Schließen der Datenmenge oder eine andere `DataSource` leeren die Auswahl. Nach einem Wechsel von Index oder Sortierung `SelectedRows.Refresh` aufrufen; ein `TClientDataSet` liefert dann neue Lesezeichen.
- Spalten: `FieldName`, `Title` (statt `Title.Caption` – das Migrationsskript setzt das um), `Width`, `Alignment`, `ReadOnly`, `EditorKind`, `PickList`, `ButtonStyle`, `Visible`, `DisplayIndex`, `FooterField`, `ValueChecked`/`ValueUnchecked`, `ListSource`/`KeyField`/`ListField`; zur Laufzeit `Column.Field` wie bei `TColumn`. Die von `TPPGGridColumn` geerbten `Aggregate`, `FooterFormat`, `GroupIndex` und `Sortable` wirken im DB-Grid nicht. Automatische Spalten behalten Position, Sichtbarkeit und Breite beim Neuaufbau. `SaveLayout`/`LoadLayout` merken sich die Spalten über den Feldnamen.
- Kästchen-Spalten: Boolean-Felder erscheinen als Kästchen im Theme (auch in eigenen Spalten ohne `EditorKind`). Text- und Zahlfelder werden mit `EditorKind = gekCheck` oder `CellKind = ckCheck` zum Kästchen; `ValueChecked`/`ValueUnchecked` legen die Werte fest wie bei `TDBCheckBox` (mehrere mit Semikolon, geschrieben wird der erste, Groß-/Kleinschreibung egal). Ohne Werte gelten `1`/`True`/`Ja` als an, alles andere als aus; geschrieben wird `1`/`0`. Null und ein unbekannter Wert erscheinen grau (unbestimmt). Klick auf das Kästchen und Leertaste schalten um, nur mit `dgEditing` und ohne `ReadOnly` (Grid, Spalte, Feld).
- Nachschlagen: Nachschlagefelder (`FieldKind = fkLookup`) zeigen den Text aus `LookupDataSet` und werden über eine Auswahlliste bearbeitet; geschrieben wird das Schlüsselfeld. Ohne Nachschlagefeld löst eine Spalte mit `ListSource`, `KeyField` und `ListField` (wie `TDBLookupComboBox`) den Schlüssel aus `FieldName` als Text auf. Bearbeitbar nur mit offener Liste und einem Schlüsselfeld; unbekannte Texte ändern nichts. Aufgelöste Texte merkt sich die Spalte, bis sich die Liste ändert.
- Owner-Draw wie `TDBGrid`: `OnDrawColumnCell(Sender, Rect, DataCol, Column, State)` und `DefaultDrawColumnCell`. Während des Ereignisses steht die Datenmenge auf dem gezeichneten Satz (`Column.Field` liefert dessen Werte; die Datenmenge nicht bewegen). `Canvas` ist vorbereitet: Schrift der Spalte, `Font.Color` und `Brush.Color` in den Farben der Zelle (Theme, Dunkelmodus, Auswahl und Mehrfachauswahl mit `gdSelected`). `DefaultDrawColumnCell` zeichnet Text bzw. Kästchen; eine geänderte `Brush.Color` füllt vorher die Zelle. `DefaultDrawing = False` lässt Texte und Kästchen weg (Flächen, Stile und Auswahl zeichnet das Grid weiter).
- Kartenansicht (`ViewStyle = dgvCards`, wie die Karten-Ansichten großer Grid-Suiten): je Datensatz eine Karte mit den sichtbaren Spalten als Zeilen „Beschriftung: Wert“. Es gelten dieselben `Columns` (Titel bzw. `DisplayLabel`, Reihenfolge, `Visible`, Kästchen, Nachschlagetexte, `ConditionalFormats`, Spalten-`Style`). `CardWidth`, `CardSpacing` und `CardLabelWidth` in logischen Pixeln (DPI-skaliert); die Höhe ergibt sich aus der Zahl der sichtbaren Felder. Die Karten fließen nebeneinander, brechen um und werden senkrecht pixelgenau gescrollt (auch Karten, die höher sind als die Ansicht). Die aktuelle Karte ist der aktuelle Datensatz (Rahmen in der Akzentfarbe), das Fokusfeld ist markiert. Klick wählt Datensatz und Feld, Pfeile links/rechts gehen eine Karte weiter, hoch/runter eine Kartenzeile, Bild auf/ab eine Seite, Pos1/Ende zum ersten bzw. letzten Datensatz; Tab wechselt das Feld. F2, Enter, Tippen oder Doppelklick öffnen den Editor des Felds in der Karte (Pfeil hoch/runter im Editor wechselt das Feld). Mehrfachauswahl (`dgMultiSelect`) wie in der Tabelle; gewählte Karten erscheinen in der Auswahlfarbe. Farben, Dunkelmodus und Hochkontrast kommen aus dem Theme und `Styles`; `OnDrawColumnCell` bekommt das Wertfeld als `Rect`. Geladen sind nur die Kartenzeilen um den aktuellen Datensatz (Puffer); bei Datenmengen mit `RecNo` (`IsSequenced`) stehen die Karten nach Satznummer, Scrollen zieht den Datensatz mit, wenn seine Karte das Bild verlässt. Grenzen: Datenmengen ohne `RecNo` zeigen nur die geladenen Karten (Blättern per Tastatur/Navigator; die Karten fließen dann ab dem Pufferanfang). Titelzeile, Indikator, Bänder und Summenzeile entfallen in der Kartenansicht; Spaltenbreiten wirken nicht. Drucken und Export bleiben Tabellen.
- Bearbeitungsformular in der Zeile (`EditMode = dgeForm`, wie das Inplace-Edit-Formular großer Grid-Suiten): Enter, F2, Doppelklick, Tippen oder `ShowEditForm` klappen unter der aktuellen Zeile einen Bereich auf; die folgenden Zeilen rücken nach unten, das Formular reicht über die ganze Breite (scrollt nicht mit den Spalten). Es zeigt die Felder der Spalten in der Reihenfolge der Anzeige (`Column.EditFormVisible`: wie `Visible`, immer oder nie) als Beschriftung + Editor in `EditForm.ColumnCount` Spalten (`Column.EditFormColSpan` für breite Felder, `EditForm.LabelWidth` in logischen Pixeln) und die Schaltflächen Übernehmen/Abbrechen (`EditForm.ShowButtons`). Die Editoren sind die des Grids: Text, Auswahlliste (`PickList`), Zahl, Nachschlage-Spalten und -Felder mit Liste, Kästchen (Null = grau); nicht bearbeitbare Felder erscheinen nur zum Lesen. Tab/Umschalt+Tab wechseln zwischen Feldern und Schaltflächen, Enter geht zum nächsten Feld (danach Übernehmen), Strg+Enter übernimmt, Esc verwirft. Übernehmen schreibt die geänderten Felder und bucht (`Post`); ein Fehler (ungültiger Wert, Pflichtfeld, `BeforePost`) wird gemeldet, das Formular bleibt offen und der Fokus steht auf dem Feld. Einfg legt einen neuen Datensatz im Formular an (unverändert übernommen verschwindet er wieder). Bucht jemand anders (Navigator), gehen die Eingaben des Formulars mit; wechselt der Datensatz, schließt das Formular; `Cancel` von außen liest die Werte neu. `OnEditFormShow`/`OnEditFormClose` melden Öffnen und Schließen, `EditFormActive`, `EditFormEditor(Spalte)` und `HideEditForm(Accept)` steuern es aus dem Code. Ist das Grid niedriger als das Formular, scrollt das Formular selbst. Grenzen: nur in der Tabelle (die Kartenansicht bearbeitet in der Zelle); die Zellen der Tabelle sind in diesem Modus schreibgeschützt; Mehrzeilige Editoren (Memo) gibt es nicht – Memofelder erscheinen als einzeiliges Textfeld; Spaltenänderungen bei offenem Formular lesen die Werte neu aus dem Datensatz.
- Reihenfolge je Datenzelle: bedingte Formate und `OnGetCellStyle` (Fläche, Textfarbe, Balken, Symbol) → Auswahl/Mehrfachauswahl → Text bzw. Kästchen (nur mit `DefaultDrawing`) → Fokusrahmen → `OnDrawCell` → `OnDrawColumnCell`.
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

// Mehrfachauswahl: alle gewählten Datensätze durchlaufen (wie TDBGrid)
PPGDBGrid1.Options := PPGDBGrid1.Options + [dgMultiSelect];
for I := 0 to PPGDBGrid1.SelectedRows.Count - 1 do
begin
  ClientDataSet1.Bookmark := PPGDBGrid1.SelectedRows[I];
  Summe := Summe + ClientDataSet1.FieldByName('Betrag').AsCurrency;
end;

// Kästchen für ein Textfeld mit J/N
with TPPGDBGridColumn(PPGDBGrid1.Columns.Add) do
begin
  FieldName := 'Aktiv';
  EditorKind := gekCheck;
  ValueChecked := 'J';
  ValueUnchecked := 'N';
end;

// Schlüssel als Text aus einer zweiten Datenmenge
with TPPGDBGridColumn(PPGDBGrid1.Columns.Add) do
begin
  FieldName := 'KundeID';
  ListSource := dsKunden;
  KeyField := 'ID';
  ListField := 'Name';
end;

// Kartenansicht: je Datensatz eine Karte, 320 Pixel breit
PPGDBGrid1.ViewStyle := dgvCards;
PPGDBGrid1.CardWidth := 320;
PPGDBGrid1.CardLabelWidth := 130;

// Bearbeitungsformular in der Zeile: drei Spalten, Bemerkung über die ganze Breite
PPGDBGrid1.EditMode := dgeForm;
PPGDBGrid1.EditForm.ColumnCount := 3;
TPPGDBGridColumn(PPGDBGrid1.Columns[5]).Visible := False;      // nicht in der Tabelle
TPPGDBGridColumn(PPGDBGrid1.Columns[5]).EditFormVisible := efvShow;
TPPGDBGridColumn(PPGDBGrid1.Columns[5]).EditFormColSpan := 3;

// Zeilen einfärben wie bei TDBGrid
procedure TForm1.PPGDBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TPPGDBGridColumn; State: TGridDrawState);
begin
  if not (gdSelected in State) and (ClientDataSet1.FieldByName('Offen').AsCurrency > 0) then
    PPGDBGrid1.Canvas.Brush.Color := $00D0D0FF;
  PPGDBGrid1.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;
```
