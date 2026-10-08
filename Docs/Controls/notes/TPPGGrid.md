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
```
