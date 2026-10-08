# TPPGGridColumn

Typ in Unit `PPG.Grid.Columns` - Basis `TCollectionItem`

Eine Spalte: Titel, Breite, Ausrichtung, Editor, Format, Sortierung, Summe, Gruppierung, Zellart sowie eigene Stile für Zellen und Kopf.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Title` | `string` |  | Überschrift der Spalte im Kopf. |
| `Width` | `Integer` | `0` | Breite in logischen Pixeln (0..10000); 0 = DefaultColWidth. Wird beim Ziehen der Spaltengrenze aktualisiert. |
| `Alignment` | `TAlignment` | `taLeftJustify` | Ausrichtung des Zellinhalts (links, zentriert, rechts); Zahlen meist rechtsbündig. |
| `EditorKind` | `TPPGGridEditorKind` | `gekText` | Editor beim Bearbeiten: gekText (Textfeld), gekNone (nicht bearbeitbar), gekCombo (Auswahl aus PickList), gekSpin (Zahl mit MinValue/MaxValue), gekCheck (Kästchen). Werte: `gekText`, `gekNone`, `gekCombo`, `gekSpin`, `gekCheck`. |
| `PickList` | `TStrings` |  | Auswahlwerte für den Editor gekCombo, je Zeile einer. Nutzung: `Grid1.Columns[1].EditorKind := gekCombo; Grid1.Columns[1].PickList.CommaText := 'offen,erledigt';` |
| `ReadOnly` | `Boolean` | `False` | True: Zellen dieser Spalte sind nicht bearbeitbar. |
| `MinValue` | `Integer` | `0` | Untergrenze für gekSpin und ckProgress. |
| `MaxValue` | `Integer` | `0` | Obergrenze für gekSpin und ckProgress bzw. Sternzahl bei ckRating (0 = Vorgabe). |
| `Sortable` | `Boolean` | `True` | False: Klick auf den Kopf sortiert nicht nach dieser Spalte. |
| `Visible` | `Boolean` | `True` | False: Die Spalte ist ausgeblendet (über das Kopfmenü wieder einblendbar); Daten und Index bleiben erhalten. |
| `DisplayIndex` | `Integer` | `-1` | Position in der Anzeige unter den beweglichen Spalten (-1 = wie Index). Das Grid schreibt sie beim Verschieben für alle Spalten neu; der Index der Spalte (Datenspalte) bleibt gleich. |
| `Band` | `Integer` | `-1` | Band (Index in Grid.Bands), unter dem diese Spalte steht; -1 = keins. |
| `Aggregate` | `TPPGGridAggregate` | `agNone` | Zusammenfassung in Summenzeile (ShowFooter) und Gruppenfuß (GroupFooter): agSum (Summe), agAvg (Mittelwert), agMin, agMax, agCount (Anzahl), agCustom (Wert aus OnCustomAggregate), agNone. Werte: `agNone`, `agSum`, `agAvg`, `agMin`, `agMax`, `agCount`, `agCustom`. |
| `FooterFormat` | `string` |  | FormatFloat-Muster für die Summen dieser Spalte (leer = „#,##0.##"); agCount wird immer ganzzahlig angezeigt. Nutzung: `Grid1.Columns[3].FooterFormat := '#,##0.00 €';` |
| `GroupIndex` | `Integer` | `-1` | Ebene beim Gruppieren nach dieser Spalte (0 = oberste); -1 = nicht gruppiert. Wird auch durch Ziehen in die Gruppenleiste gesetzt. |
| `CellKind` | `TPPGGridCellKind` | `ckText` | Darstellung der Zellen: ckText, ckCheck (Kästchen), ckProgress (Balken zwischen MinValue und MaxValue, sonst 0..100), ckSparkline (Werte „1;4;2"), ckRating (Sterne, Anzahl = MaxValue, sonst 5), ckImage (Bildindex), ckLink, ckButton (OnCellButtonClick), ckColor (Farbfeld), ckMarkup, ckCustom (eigene Zellart über CellKindName). Werte: `ckText`, `ckCheck`, `ckProgress`, `ckSparkline`, `ckRating`, `ckImage`, `ckLink`, `ckButton`, `ckColor`, `ckMarkup`, `ckCustom`. Nutzung: `Grid1.Columns[2].CellKind := ckProgress;` |
| `CellKindName` | `string` |  | Name einer selbst registrierten Zellart (nur mit CellKind = ckCustom). |
| `Format` | `string` |  | Zahlen- bzw. Datumsformat für den Excel-Export in Excel-Syntax (z. B. „#,##0.00" oder „dd.mm.yyyy"); leer = Standard. |
| `Style` | [TPPGElementStyle](TPPGElementStyle.md) |  | Aussehen der Zellen dieser Spalte: Fläche, Text, Schrift (je auch für Dunkel). clDefault = wie im Grid. Nutzung: `Grid1.Columns[0].Style.FontStyle := [fsBold];` |
| `TitleStyle` | [TPPGElementStyle](TPPGElementStyle.md) |  | Aussehen des Spaltenkopfs: Fläche, Text, Schrift. clDefault = wie Grid.Styles.Header. |
| `TitleAlignment` | `TPPGGridTitleAlignment` | `gtaColumn` | Ausrichtung des Spaltentitels: gtaColumn = wie Alignment der Spalte, sonst links, zentriert oder rechts. Werte: `gtaColumn`, `gtaLeft`, `gtaCenter`, `gtaRight`. |

## Verwendet in

[TPPGGridColumns](TPPGGridColumns.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
