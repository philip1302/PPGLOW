**Vorbild:** TStringGrid, TMS TAdvStringGrid, DevExpress Grid (Gruppenleiste)

## Wofür

Das Grid zeigt Datensätze als Tabelle: Aufträge, Artikel, Buchungen, Positionen. Der Anwender filtert, sortiert, gruppiert und blendet Spalten selbst ein und aus, sieht Summen und kann Zellen direkt bearbeiten. Was er sieht, lässt sich ohne weiteren Code drucken und als Excel-, PDF-, HTML- oder CSV-Datei exportieren.

## Wann verwenden

- Für Listen mit mehreren Spalten, die man vergleichen, sortieren oder summieren will. Für eine einspaltige Auswahl genügt `TPPGListBox`, für Einträge mit Symbol und Zusatztext `TPPGTileView`.
- Statt `TStringGrid` in neuen Formularen: gleiche Grundeigenschaften (`Cells`, `ColCount`, `RowCount`, `Options`), dazu Spalten, Filter, Summen, Gruppen und Export.
- Für Daten aus einer Datenmenge (`TDataSet`) `TPPGDBGrid` nehmen; es hat dieselben Spalten- und Exportfunktionen. `TPPGGrid` passt zu Daten in eigenen Listen und Objekten, auch virtuell über `OnGetCellText`.
- Für hierarchische Daten (Ordner, Stücklisten) ist `TPPGTreeView` klarer; das Grid gruppiert nur nach Spaltenwerten.
- Für die Auswahl eines Datensatzes in einem Eingabefeld ist `TPPGColumnComboBox` platzsparender.

## Unterschiede und Hinweise

- `Row`/`Col`/`Cells[]` arbeiten mit Daten-Indizes, `Selection`/`FocusRow`/`FocusCol`/`CellRect` mit der Anzeige (Sortierung, Filter, verschobene Spalten). Umrechnen mit `DataRow`/`VisualRow`, `DataCol`/`VisualCol`.
- Enter im Editor übernimmt und bleibt in der Zelle (wie `TStringGrid`); Pfeil hoch/runter im Text-Editor übernimmt und wechselt die Zeile.
- Kopfklick sortiert: aufsteigend → absteigend → unsortiert. Rechtsklick auf den Kopf: Kopfmenü (Sortieren, Gruppieren, Ausblenden, Spaltenauswahl, optimale Breite), erweiterbar über `OnHeaderMenu`.
- Spalten (`Columns`): verschieben per Ziehen (`goColMoving`), `Visible`, `DisplayIndex`, Doppelklick auf die Kopfkante passt die Breite an, `FixedColsRight`, `Bands` (auch mehrstufig).
- Gruppieren: `GroupBy`/`Column.GroupIndex` oder Kopf in die Gruppenleiste ziehen (`ShowGroupPanel`). Gruppenzeilen mit Pfeil (Klick, Doppelklick, Pfeiltasten, Enter/Leertaste), Text über `OnGetGroupText` (Markup).
- Summen: `ShowFooter`, `GroupFooter`, `Column.Aggregate`/`FooterFormat`, `agCustom` über `OnCustomAggregate`. Summen gelten für die gefilterte Ansicht.
- Zellen: `Column.CellKind` (Kästchen, Fortschritt, Sparkline, Bewertung, Bild, Link, Button, Farbfeld, Markup; eigene über `PPGRegisterCellKindName`), `ConditionalFormats`, `OnGetCellStyle`, `MergeCells`.
- Filtern (`ShowFilterRow`, `Filters[]`, `SetFilterCondition`): ohne Operator Teiltext (Zahl/Datum: gleich), sonst `=x`, `<>x`, `<x`, `<=x`, `>x`, `>=x`, `a..b`, `abc*`, `*abc`, `*abc*`, `=` (leer), `<>` (nicht leer); Zahlen und Datum (Format der Ländereinstellung) werden als Wert verglichen, Text ohne Groß-/Kleinschreibung. `FilterImmediate` filtert beim Tippen, `ShowFilterBar` zeigt unten den Filter als Text (`FilterDescription`) mit „Filter löschen“, `OnFilterChanged` meldet jede Änderung. Parser für eigene Filter: `PPGFilterParse`/`PPGFilterText` (`PPG.Grid.View`).
- Suchen: `FindPanel` (`fpmManual`: Strg+F; `fpmAlways`) blendet über der Tabelle ein Suchfeld mit Zurück/Weiter ein; Treffer in allen sichtbaren Textspalten sind markiert, Enter/F3 und Umschalt+Enter/Umschalt+F3 springen (im Kreis), Esc leert bzw. schließt. Aus dem Code: `FindText`, `FindNext`, `FindPrevious`, `ShowFind`, `HideFind`. `IncrementalSearch`: Tippen in einer nicht bearbeitbaren Zelle springt zur nächsten Zeile, deren Text in der Fokusspalte so beginnt (`IncrementalSearchText`).
- `OnGetCellStyle` gilt auch für Druck und Export; abgeleitete Grids überschreiben `DoGetCellStyle(ACol, ARow, Purpose, Style)` (Purpose: Bildschirm, Druck, Export).
- Layout merken: `SaveLayout`/`LoadLayout` (Reihenfolge, Breiten, Sichtbarkeit, Sortierung, Gruppen); die Filtertexte gehören nicht zum Layout.
- Drucken mit `TPPGGridPrinter`; Export über `PPG.Grid.Export` (xlsx, PDF, HTML, CSV), Import `PPGLoadXlsx`.
- Der xlsx-Export übernimmt die Optik des Grids in heller Darstellung: Schrift, Kopf- und Summenfarben, Bänder, Gitterlinien, Ausrichtung, Zeilenhöhe, Spalten- und Zebra-Stile, bedingte Formate, Kästchen (☑/☐ als 1/0), Sterne, Farb- und Linkzellen. Datenbalken, Fortschritt und Symbolsätze werden Excel-Regeln und rechnen beim Bearbeiten mit. Nur Werte: `TPPGXlsxWriter.Styled := False`.
- UI Automation: Tabellen-Muster mit Kopfzeilen, Gruppenzeilen (Auf-/Zuklappen), Kästchen, Links und Buttons (Invoke).

## Anpassung

- `Styles` mit zehn Bereichen (`Header`, `Footer`, `Selection`, `SelectionInactive`, `AlternateRow`, `HotRow`, `GridLine`, `FocusedCell`, `GroupRow`, `FilterRow`); jeder Bereich hat `Color`, `TextColor`, `BorderColor`, Dunkel-Varianten und auf Wunsch eine eigene `Font`. `clDefault` = vom Preset.
- Zebra-Zeilen: `Styles.AlternateRow.Color`. Gitterlinien: `Styles.GridLine.Color` und `GridLineWidth`.
- Spalten: `Style`, `TitleStyle`, `TitleAlignment`. `OnGetCellStyle` kann zusätzlich `FontStyle`, `FontName` und `FontSize` setzen.
- Wie `TStringGrid`: `FixedColor` (Alias für `Styles.Header.Color`), `DrawingStyle`, `GradientStartColor`/`GradientEndColor`.

## Beispiel

```pascal
Grid1.Columns[2].Aggregate := agSum;
Grid1.ShowFooter := True;
Grid1.GroupBy([1]);                       // nach Kategorie gruppieren
PPGExportXlsx(Grid1 as IPPGTableSource, 'Liste.xlsx');

// Filterzeile mit Operatoren, Filterleiste und Suchfeld (Strg+F)
Grid1.ShowFilterRow := True;
Grid1.FilterImmediate := True;
Grid1.ShowFilterBar := True;
Grid1.Filters[2] := '>=100';               // Betrag ab 100
Grid1.SetFilterCondition(1, pfoBeginsWith, 'Mül');
Grid1.FindPanel := fpmManual;
```
