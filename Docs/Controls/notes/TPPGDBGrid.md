**Vorbild:** TDBGrid

## Wofür

Das DB-Grid zeigt die Datensätze einer Datenmenge (Abfrage, Tabelle, ClientDataSet) als Tabelle und bearbeitet sie direkt in der Zelle. Es ersetzt `TDBGrid` mit derselben Bedienung (Datensatzzeiger, Einfg, Strg+Entf, Esc) und bringt die Optik, Spalten-Stile, bedingten Formate, Druck und Excel-Export von `TPPGGrid` mit. Daten, Regeln, Sortierung und Summen bleiben in der Datenmenge.

## Wann verwenden

- Für Listen und Erfassungstabellen, deren Daten aus einer Datenbank kommen und dorthin zurückgeschrieben werden: Kundenliste, Bestellpositionen, Buchungen.
- Statt `TPPGGrid`, wenn die Datenmenge die Quelle ist. Das `TPPGGrid` hält die Daten selbst und kann zusätzlich in der Ansicht filtern und sortieren; dafür Daten aus Objektlisten oder kleinen Abfragen hineinladen. Gruppieren kann auch das DB-Grid (siehe unten).
- Statt einzelner DB-Felder (`TPPGDBEdit` usw.), wenn mehrere Datensätze gleichzeitig zu sehen sein sollen. Für einen einzelnen Datensatz mit vielen Feldern ist ein Formular übersichtlicher; Grid und Formular an derselben `DataSource` zeigen denselben Satz.
- Zusammen mit `TPPGDBNavigator` für Blättern, Suchen und Speichern über Knöpfe.

## Unterschiede und Hinweise

- Nur der Puffer sichtbarer Datensätze wird gelesen (außer beim Gruppieren, siehe unten); Paint greift nie auf die Datenmenge zu.
- `Options` ist `TDBGridOptions` (DFM-kompatibel); `dgColumnResize` erlaubt auch das Verschieben der Spalten (wie `TDBGrid`).
- Mehrfachauswahl mit `dgMultiSelect` wie bei `TDBGrid`: `SelectedRows` (`TPPGBookmarkList`) mit `Count`, `Items[]`, `CurrentRowSelected`, `Clear`, `SelectAll`, `Delete`, `Find`, `IndexOf` und `Refresh`. Strg+Klick schaltet um, Umschalt+Klick wählt den Bereich vom Anker, Umschalt+Pfeil erweitert, Strg+A wählt alles, Strg+Leertaste schaltet um, Strg+Entf löscht die Auswahl (Rückfrage bei `dgConfirmDelete`). Klick oder Pfeil ohne Taste heben die Auswahl auf. Gewählte Zeilen erscheinen in der Auswahlfarbe (`Styles.Selection`), im Indikator mit Haken. `OnSelectionChanged` meldet Änderungen. Schließen der Datenmenge oder eine andere `DataSource` leeren die Auswahl. Nach einem Wechsel von Index oder Sortierung `SelectedRows.Refresh` aufrufen; ein `TClientDataSet` liefert dann neue Lesezeichen.
- Spalten: `FieldName`, `Title` (statt `Title.Caption` – das Migrationsskript setzt das um), `Width`, `Alignment`, `ReadOnly`, `EditorKind`, `PickList`, `ButtonStyle`, `Visible`, `DisplayIndex`, `FooterField`, `ValueChecked`/`ValueUnchecked`, `ListSource`/`KeyField`/`ListField`; zur Laufzeit `Column.Field` wie bei `TColumn`. `GroupIndex` gruppiert (siehe unten), `Aggregate`/`FooterFormat` rechnen nur in der gruppierten Ansicht; `Sortable` wirkt im DB-Grid nicht. Automatische Spalten behalten Position, Sichtbarkeit und Breite beim Neuaufbau. `SaveLayout`/`LoadLayout` merken sich die Spalten über den Feldnamen.
- Kästchen-Spalten: Boolean-Felder erscheinen als Kästchen im Theme (auch in eigenen Spalten ohne `EditorKind`). Text- und Zahlfelder werden mit `EditorKind = gekCheck` oder `CellKind = ckCheck` zum Kästchen; `ValueChecked`/`ValueUnchecked` legen die Werte fest wie bei `TDBCheckBox` (mehrere mit Semikolon, geschrieben wird der erste, Groß-/Kleinschreibung egal). Ohne Werte gelten `1`/`True`/`Ja` als an, alles andere als aus; geschrieben wird `1`/`0`. Null und ein unbekannter Wert erscheinen grau (unbestimmt). Klick auf das Kästchen und Leertaste schalten um, nur mit `dgEditing` und ohne `ReadOnly` (Grid, Spalte, Feld).
- Nachschlagen: Nachschlagefelder (`FieldKind = fkLookup`) zeigen den Text aus `LookupDataSet` und werden über eine Auswahlliste bearbeitet; geschrieben wird das Schlüsselfeld. Ohne Nachschlagefeld löst eine Spalte mit `ListSource`, `KeyField` und `ListField` (wie `TDBLookupComboBox`) den Schlüssel aus `FieldName` als Text auf. Bearbeitbar nur mit offener Liste und einem Schlüsselfeld; unbekannte Texte ändern nichts. Mehrere Listenfelder (`ListField = 'Nummer;Name'`) zeigen in Zelle und Formular eine mehrspaltige Auswahl (`TPPGColumnComboBox`); `ListFieldIndex` wählt das Feld für die Zelle. Aufgelöste Texte merkt sich die Spalte, bis sich die Liste ändert.
- Owner-Draw wie `TDBGrid`: `OnDrawColumnCell(Sender, Rect, DataCol, Column, State)` und `DefaultDrawColumnCell`. Während des Ereignisses steht die Datenmenge auf dem gezeichneten Satz (`Column.Field` liefert dessen Werte; die Datenmenge nicht bewegen). `Canvas` ist vorbereitet: Schrift der Spalte, `Font.Color` und `Brush.Color` in den Farben der Zelle (Theme, Dunkelmodus, Auswahl und Mehrfachauswahl mit `gdSelected`). `DefaultDrawColumnCell` zeichnet Text bzw. Kästchen; eine geänderte `Brush.Color` füllt vorher die Zelle. `DefaultDrawing = False` lässt Texte und Kästchen weg (Flächen, Stile und Auswahl zeichnet das Grid weiter).
- Kartenansicht (`ViewStyle = dgvCards`, wie die Karten-Ansichten großer Grid-Suiten): je Datensatz eine Karte mit den sichtbaren Spalten als Zeilen „Beschriftung: Wert“. Es gelten dieselben `Columns` (Titel bzw. `DisplayLabel`, Reihenfolge, `Visible`, Kästchen, Nachschlagetexte, `ConditionalFormats`, Spalten-`Style`). `CardWidth`, `CardSpacing` und `CardLabelWidth` in logischen Pixeln (DPI-skaliert); die Höhe ergibt sich aus der Zahl der sichtbaren Felder. Die Karten fließen nebeneinander, brechen um und werden senkrecht pixelgenau gescrollt (auch Karten, die höher sind als die Ansicht). Die aktuelle Karte ist der aktuelle Datensatz (Rahmen in der Akzentfarbe), das Fokusfeld ist markiert. Klick wählt Datensatz und Feld, Pfeile links/rechts gehen eine Karte weiter, hoch/runter eine Kartenzeile, Bild auf/ab eine Seite, Pos1/Ende zum ersten bzw. letzten Datensatz; Tab wechselt das Feld. F2, Enter, Tippen oder Doppelklick öffnen den Editor des Felds in der Karte (Pfeil hoch/runter im Editor wechselt das Feld). Mehrfachauswahl (`dgMultiSelect`) wie in der Tabelle; gewählte Karten erscheinen in der Auswahlfarbe. Farben, Dunkelmodus und Hochkontrast kommen aus dem Theme und `Styles`; `OnDrawColumnCell` bekommt das Wertfeld als `Rect`. Geladen sind nur die Kartenzeilen um den aktuellen Datensatz (Puffer); bei Datenmengen mit `RecNo` (`IsSequenced`) stehen die Karten nach Satznummer, Scrollen zieht den Datensatz mit, wenn seine Karte das Bild verlässt. Grenzen: Datenmengen ohne `RecNo` zeigen nur die geladenen Karten (Blättern per Tastatur/Navigator; die Karten fließen dann ab dem Pufferanfang). Titelzeile, Indikator, Bänder und Summenzeile entfallen in der Kartenansicht; Spaltenbreiten wirken nicht. Drucken und Export bleiben Tabellen.
- Bearbeitungsformular in der Zeile (`EditMode = dgeForm`, wie das Inplace-Edit-Formular großer Grid-Suiten): Enter, F2, Doppelklick, Tippen oder `ShowEditForm` klappen unter der aktuellen Zeile einen Bereich auf; die folgenden Zeilen rücken nach unten, das Formular reicht über die ganze Breite (scrollt nicht mit den Spalten). Es zeigt die Felder der Spalten in der Reihenfolge der Anzeige (`Column.EditFormVisible`: wie `Visible`, immer oder nie) als Beschriftung + Editor in `EditForm.ColumnCount` Spalten (`Column.EditFormColSpan` für breite Felder, `EditForm.LabelWidth` in logischen Pixeln) und die Schaltflächen Übernehmen/Abbrechen (`EditForm.ShowButtons`). Die Editoren sind die des Grids: Text, Auswahlliste (`PickList`), Zahl, Nachschlage-Spalten und -Felder mit Liste, Kästchen (Null = grau); nicht bearbeitbare Felder erscheinen nur zum Lesen. Tab/Umschalt+Tab wechseln zwischen Feldern und Schaltflächen, Enter geht zum nächsten Feld (danach Übernehmen), Strg+Enter übernimmt, Esc verwirft. Übernehmen schreibt die geänderten Felder und bucht (`Post`); ein Fehler (ungültiger Wert, Pflichtfeld, `BeforePost`) wird gemeldet, das Formular bleibt offen und der Fokus steht auf dem Feld. Einfg legt einen neuen Datensatz im Formular an (unverändert übernommen verschwindet er wieder). Bucht jemand anders (Navigator), gehen die Eingaben des Formulars mit; wechselt der Datensatz, schließt das Formular; `Cancel` von außen liest die Werte neu. `OnEditFormShow`/`OnEditFormClose` melden Öffnen und Schließen, `EditFormActive`, `EditFormEditor(Spalte)` und `HideEditForm(Accept)` steuern es aus dem Code. Ist das Grid niedriger als das Formular, scrollt das Formular selbst. Memofelder erscheinen mehrzeilig (`TPPGMemo`, Höhe `Column.EditFormRows` Rasterzeilen; Enter ist dort ein Zeilenumbruch, Strg+Enter übernimmt), Datumsfelder mit Kalender (`TPPGDatePicker`; ohne Pflichtfeld mit Kästchen für „leer“, eine Uhrzeit im Feld bleibt erhalten); `Column.EditFormEditor` legt den Editor fest. `Column.EditFormGroup` teilt das Formular in Abschnitte mit Überschrift (Felder mit derselben Angabe nacheinander). Grenzen: nur in der Tabelle (die Kartenansicht bearbeitet in der Zelle); die Zellen der Tabelle sind in diesem Modus schreibgeschützt; Spaltenänderungen bei offenem Formular lesen die Werte neu aus dem Datensatz.
- Reihenfolge je Datenzelle: bedingte Formate und `OnGetCellStyle` (Fläche, Textfarbe, Balken, Symbol) → Auswahl/Mehrfachauswahl → Text bzw. Kästchen (nur mit `DefaultDrawing`) → Fokusrahmen → `OnDrawCell` → `OnDrawColumnCell`.
- Summenzeile (`ShowFooter`) aus der Datenmenge: `Column.FooterField` (z. B. ein `TAggregateField`) oder `OnGetFooterText`.
- Gruppieren wie im `TPPGGrid`: `Column.GroupIndex` (0 = oberste Ebene), Spaltenkopf in die Gruppenleiste ziehen (`ShowGroupPanel`), Kopfmenü oder `GroupBy`/`Ungroup`. Nur dann liest das Grid die ganze Datenmenge einmal (`DisableControls`, Position bleibt) und hält je Satz Texte, Werte und Lesezeichen im Speicher; ohne Gruppenspalte bleibt alles beim Puffer. Gruppenzeilen „Feld: Wert (Anzahl)“ (`OnGetGroupText`), Gruppen nach Wert geordnet (Zahl/Datum nach Wert), innerhalb der Gruppe in der Reihenfolge der Datenmenge. Zuklappen per Klick auf den Pfeil, Doppelklick, Pfeil links/rechts, +/-, Enter, Leertaste, `ExpandGroup`, `FullExpand`/`FullCollapse`; anfangs ist alles aufgeklappt, zugeklappte Gruppen bleiben beim Neulesen (nach Gruppenwert) zu. `Column.Aggregate` mit `ShowFooter` und `GroupFooter` rechnet das Grid über alle Sätze. Fokus auf einer Datenzeile stellt die Datenmenge per Lesezeichen auf den Satz. Gruppenkopf- und Gruppenfußzeilen bewegen sie nicht (wie im cxGrid; Tastatur, Maus, Code, auf- wie zugeklappt): die Datenmenge bleibt auf dem zuletzt fokussierten Satz, erst eine Datenzeile zieht nach. Eine offene Bearbeitung bzw. ein neuer Satz wird beim Wechsel auf eine Gruppenzeile gebucht wie beim Zeilenwechsel; `IsActiveRecordRow` ist dort False, `ActiveGroupValues` gilt dem Satz der Datenmenge, Tippen öffnet im Formular-Modus kein Formular, `LocateRecord` auf den Satz der Datenmenge holt den Fokus von der Gruppenzeile zurück; Satzwechsel von außen (Navigator, `Next`, `Locate`) fokussieren die Zeile und klappen ihre Gruppen auf. Pfeile, Bild auf/ab und Strg+Pos1/Ende laufen in der Reihenfolge der Ansicht, Umschalt+Pfeil und Umschalt+Klick wählen Bereiche in dieser Reihenfolge; Bearbeiten, Einfg, Strg+Entf, Esc, Filterzeile, Suchfeld und Tippsuche (auch in zugeklappten Gruppen), Druck und Export (mit Gruppen-Gliederung) arbeiten weiter. Neu gelesen wird nach jeder Änderung von außen (`DataSetChanged`: Refresh, Filter, Löschen, `First`/`Last`, `EnableControls`, `Locate` der Anwendung); `Post`/`Cancel` einer Bearbeitung liest nur den Satz und gruppiert ihn bei geändertem Gruppenwert um. Code: `GroupedView`, `ActiveDataRow` (Zeile des aktuellen Satzes, z. B. `Row := ActiveDataRow`), `ActiveGroupValues` (Gruppenwerte des aktuellen Satzes), `LocateRecord` (wie `Locate`, aber ohne Neulesen), `RefreshGroups`, `IsDataRow(FocusRow)`, `DataRowGroup`, `GroupReadCount`. Grenzen: Speicher und Lesezeit wachsen mit der Datenmenge (kein `ExportMaxRecords`); Pfeil runter am Ende hängt keinen Satz an; ein neuer Satz steht bis zum Buchen am Ende in der Gruppe seiner Anfangswerte; `OnDrawColumnCell` kommt nur für Sätze im Puffer der Datenmenge; `RowValue` liefert für andere als den aktuellen Satz die Felder der Spalten (alle Felder nur, wenn `OnGetCellStyle` oder `OnSelectCell` beim Lesen zugewiesen waren); die Kartenansicht gruppiert nicht; `OnGetCellStyle` bekommt beim Druck gruppiert die Zeile des Grids statt der Satznummer.
- Drucken (`TPPGGridPrinter`) und Export (`PPG.Grid.Export`) lesen die ganze Datenmenge einmal (`DisableControls`, Lesezeichen, höchstens `ExportMaxRecords`).
- Filterzeile (`ShowFilterRow`) mit denselben Operatoren wie `TPPGGrid`: Das Grid filtert die Datenmenge über `OnFilterRecord` (Zahl und Datum nach Feldtyp, Kästchen mit `1`/`0`, Nachschlagespalten über den angezeigten Text). Ein eigener `OnFilterRecord` der Anwendung läuft zuerst und bleibt in Kraft, `Filter`/`Filtered` ebenso; ein `Filter`-Text bei `Filtered = False` wird solange ausgesetzt. Filter löschen, eine andere `DataSource` oder das Freigeben des Grids stellen die Datenmenge wieder her. `FilterImmediate`, `ShowFilterBar`, `FilterDescription`, `OnFilterChanged` wie bei `TPPGGrid`. Grenze: keine zweite Komponente, die zur Laufzeit `OnFilterRecord` derselben Datenmenge umhängt.
- Suchen: `FindPanel`, `FindText`, `FindNext`/`FindPrevious` durchlaufen die Datenmenge ab dem aktuellen Satz (im Kreis, `DisableControls`; ohne Treffer bleibt der Satz). `IncrementalSearch` sucht in der Fokusspalte (Text beginnt mit der Eingabe); mit `dgeForm` hat die Tippsuche Vorrang vor dem Öffnen des Formulars.
- Werte in `OnGetCellStyle`: `RowValue('Feld')` liefert den Wert des Satzes der gerade dargestellten Zeile – am Bildschirm aus dem Puffer, beim Druck und Export aus dem gelesenen Satz, außerhalb des Ereignisses vom aktuellen Satz; ein unbekanntes Feld löst `EPPGError` aus. In `OnSelectCell` liefert `RowValue` die Zielzeile.
- Mehrfachauswahl-Helfer: `SelectedCount`, `ForEachSelected(procedure(DataSet: TDataSet) ...)` (steht je Satz auf dem Datensatz, danach wieder auf dem vorigen; Ergebnis = Anzahl) und `SelectedValues('Feld')` (Array). `OnCanSelectRecord(Sender, var Allow)` lehnt einzelne Sätze ab (Klick, Bereich, Strg+A, `SelectedRows`).
- Ereignisse: `OnFocusedRecordChanged` (anderer aktueller Satz; nicht beim Ändern von Werten), `OnSelectCell` (Veto vor dem Satzwechsel), `OnSorted`.
- Sortierpfeil: Mit `SortOnHeaderClick = True` setzt ein Kopfklick nur `SortColumn`/`SortAscending` (Pfeil) und meldet `OnSorted`; sortieren muss die Datenmenge (z. B. `IndexFieldNames` in `OnTitleClick`). `SaveLayout`/`LoadLayout` speichern Breite, Reihenfolge, Sichtbarkeit und den Pfeil über den Feldnamen; die Reihenfolge der Sätze ändern sie nicht.
- `OnTitleClick(Column)`/`OnCellClick(Column)` ohne Sender wie `TDBGrid`; Sortieren ist Sache der Datenmenge (im Kopfmenü sind die Sortier-Einträge gesperrt; Pfeil siehe `SortOnHeaderClick`).
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

// Filterzeile, Filterleiste, Suchfeld; der Filter der Anwendung bleibt erhalten
PPGDBGrid1.ShowFilterRow := True;
PPGDBGrid1.ShowFilterBar := True;
PPGDBGrid1.FindPanel := fpmManual;
PPGDBGrid1.Filters[PPGDBGrid1.FixedCols + 2] := '01.01.2026..31.03.2026';

// Alle gewählten Sätze verarbeiten
Anzahl := PPGDBGrid1.ForEachSelected(
  procedure(DataSet: TDataSet)
  begin
    Summe := Summe + DataSet.FieldByName('Betrag').AsCurrency;
  end);

// Text grau, wenn der Satz gesperrt ist (auch im Druck und Export)
procedure TForm1.PPGDBGrid1GetCellStyle(Sender: TObject; ACol, ARow: Integer;
  var Style: TPPGGridCellStyle);
begin
  if PPGDBGrid1.RowValue('Gesperrt') = True then
    Style.TextColor := clGrayText;
end;

// Formular mit Abschnitt und mehrzeiliger Bemerkung
TPPGDBGridColumn(PPGDBGrid1.Columns[3]).EditFormGroup := 'Anschrift';
TPPGDBGridColumn(PPGDBGrid1.Columns[4]).EditFormGroup := 'Anschrift';
TPPGDBGridColumn(PPGDBGrid1.Columns[5]).EditFormRows := 4;

// Zeilen einfärben wie bei TDBGrid
procedure TForm1.PPGDBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TPPGDBGridColumn; State: TGridDrawState);
begin
  if not (gdSelected in State) and (ClientDataSet1.FieldByName('Offen').AsCurrency > 0) then
    PPGDBGrid1.Canvas.Brush.Color := $00D0D0FF;
  PPGDBGrid1.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;
```
