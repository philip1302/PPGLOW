# TPPGGridColumn

Typ in Unit `PPG.Grid.Columns` - Basis `TCollectionItem`

Eine Spalte: Titel, Breite, Ausrichtung, Editor, Format, Sortierung, Summe, Gruppierung, Zellart sowie eigene Stile für Zellen und Kopf.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Title` | `string` |  | Überschrift der Spalte im Kopf. Praxis: Kurz und eindeutig, mit Einheit, wenn nötig („Betrag €“, „Menge Stk.“). Der Titel erscheint auch im Kopfmenü, im Druck und im Export. |
| `Width` | `Integer` | `0` | Breite in logischen Pixeln (0..10000); 0 = DefaultColWidth. Wird beim Ziehen der Spaltengrenze aktualisiert. Praxis: Nach dem längsten typischen Inhalt wählen; 0 nimmt DefaultColWidth. Mit goColSizing kann der Anwender nachjustieren, ein Doppelklick auf die Kopfkante passt die Breite an. |
| `Alignment` | `TAlignment` | `taLeftJustify` | Ausrichtung des Zellinhalts (links, zentriert, rechts); Zahlen meist rechtsbündig. Praxis: Zahlen und Beträge rechtsbündig (taRightJustify), damit Stellen untereinander stehen; Text links, kurze Kennzeichen zentriert. |
| `EditorKind` | `TPPGGridEditorKind` | `gekText` | Editor beim Bearbeiten: gekText (Textfeld), gekNone (nicht bearbeitbar), gekCombo (Auswahl aus PickList), gekSpin (Zahl mit MinValue/MaxValue), gekCheck (Kästchen). Werte: `gekText`, `gekNone`, `gekCombo`, `gekSpin`, `gekCheck`. Praxis: gekCombo für feste Werte (Status, Einheit), gekSpin für ganze Zahlen mit Grenzen, gekCheck für Ja/Nein, gekNone für berechnete Spalten. Wirkt nur mit goEditing. |
| `PickList` | `TStrings` |  | Auswahlwerte für den Editor gekCombo, je Zeile einer. Nutzung: `Grid1.Columns[1].EditorKind := gekCombo; Grid1.Columns[1].PickList.CommaText := 'offen,erledigt';` Praxis: Die erlaubten Werte für gekCombo, eine je Zeile („offen“, „bezahlt“, „storniert“). So bleiben Filter und Gruppen sauber, weil niemand Varianten tippt. |
| `ReadOnly` | `Boolean` | `False` | True: Zellen dieser Spalte sind nicht bearbeitbar. Praxis: Für Schlüssel und berechnete Werte (Nummer, Gesamtpreis), damit sie im bearbeitbaren Grid nicht versehentlich überschrieben werden. |
| `MinValue` | `Integer` | `0` | Untergrenze für gekSpin und ckProgress. Praxis: Untergrenze für das Zahlenfeld (gekSpin), meist 0, damit keine negativen Mengen entstehen. |
| `MaxValue` | `Integer` | `0` | Obergrenze für gekSpin und ckProgress bzw. Sternzahl bei ckRating (0 = Vorgabe). Praxis: Obergrenze für das Zahlenfeld (gekSpin), z. B. 999 Stück, oder 100 % bei ckProgress, 5 Sterne bei ckRating. |
| `Sortable` | `Boolean` | `True` | False: Klick auf den Kopf sortiert nicht nach dieser Spalte. Praxis: Auf False für Spalten, deren Sortierung keinen Sinn ergibt, z. B. Buttons, Bilder oder Bemerkungen. |
| `Visible` | `Boolean` | `True` | False: Die Spalte ist ausgeblendet (über das Kopfmenü wieder einblendbar); Daten und Index bleiben erhalten. Praxis: Spalten mit internen Werten (ID, Kundennummer) ausblenden: Sie bleiben für den Code lesbar, erscheinen aber weder auf dem Bildschirm noch im Export. |
| `DisplayIndex` | `Integer` | `-1` | Position in der Anzeige unter den beweglichen Spalten (-1 = wie Index). Das Grid schreibt sie beim Verschieben für alle Spalten neu; der Index der Spalte (Datenspalte) bleibt gleich. Praxis: Im Code eine feste Startreihenfolge vorgeben; zur Laufzeit schreibt das Grid den Wert selbst, wenn der Anwender Spalten verschiebt. Am einfachsten über SaveLayout/LoadLayout speichern. |
| `Band` | `Integer` | `-1` | Band (Index in Grid.Bands), unter dem diese Spalte steht; -1 = keins. Praxis: Spalten unter ein gemeinsames Band stellen (Index in Bands), z. B. Straße, PLZ und Ort unter „Anschrift“. Die Spalten eines Bands nebeneinander anordnen. |
| `Aggregate` | `TPPGGridAggregate` | `agNone` | Zusammenfassung in Summenzeile (ShowFooter) und Gruppenfuß (GroupFooter): agSum (Summe), agAvg (Mittelwert), agMin, agMax, agCount (Anzahl), agCustom (Wert aus OnCustomAggregate), agNone. Werte: `agNone`, `agSum`, `agAvg`, `agMin`, `agMax`, `agCount`, `agCustom`. Praxis: agSum für Beträge und Mengen, agCount für die Anzahl, agAvg für Durchschnittspreise. Sichtbar mit ShowFooter bzw. GroupFooter, auch im Excel-Export als Formel. |
| `FooterFormat` | `string` |  | FormatFloat-Muster für die Summen dieser Spalte (leer = „#,##0.##"); agCount wird immer ganzzahlig angezeigt. Nutzung: `Grid1.Columns[3].FooterFormat := '#,##0.00 €';` Praxis: Format der Summe passend zur Spalte, z. B. „#,##0.00“ für Beträge oder „#,##0“ für Stückzahlen. |
| `GroupIndex` | `Integer` | `-1` | Ebene beim Gruppieren nach dieser Spalte (0 = oberste); -1 = nicht gruppiert. Wird auch durch Ziehen in die Gruppenleiste gesetzt. Praxis: Im Code eine feste Gruppierung vorgeben, z. B. 0 für Kunde und 1 für Monat. Für die Wahl durch den Anwender ShowGroupPanel einschalten. |
| `CellKind` | `TPPGGridCellKind` | `ckText` | Darstellung der Zellen: ckText, ckCheck (Kästchen), ckProgress (Balken zwischen MinValue und MaxValue, sonst 0..100), ckSparkline (Werte „1;4;2"), ckRating (Sterne, Anzahl = MaxValue, sonst 5), ckImage (Bildindex), ckLink, ckButton (OnCellButtonClick), ckColor (Farbfeld), ckMarkup, ckCustom (eigene Zellart über CellKindName). Werte: `ckText`, `ckCheck`, `ckProgress`, `ckSparkline`, `ckRating`, `ckImage`, `ckLink`, `ckButton`, `ckColor`, `ckMarkup`, `ckCustom`. Nutzung: `Grid1.Columns[2].CellKind := ckProgress;` Praxis: ckCheck für Ja/Nein, ckProgress für Fertigstellung, ckRating für Bewertungen, ckLink für Webseiten, ckButton für Aktionen je Zeile. Der Zelltext bleibt der Wert (z. B. „1“, „75“). |
| `CellKindName` | `string` |  | Name einer selbst registrierten Zellart (nur mit CellKind = ckCustom). Praxis: Nur für eigene, mit PPGRegisterCellKindName registrierte Zellarten, z. B. eine Ampel; dazu CellKind = ckCustom. |
| `Format` | `string` |  | Zahlen- bzw. Datumsformat für den Excel-Export in Excel-Syntax (z. B. „#,##0.00" oder „dd.mm.yyyy"); leer = Standard. Praxis: Für den Excel-Export: „#,##0.00“ für Beträge, „dd.mm.yyyy“ für Datum. Dann rechnet und sortiert Excel mit echten Zahlen statt mit Text. |
| `Style` | [TPPGElementStyle](TPPGElementStyle.md) |  | Aussehen der Zellen dieser Spalte: Fläche, Text, Schrift (je auch für Dunkel). clDefault = wie im Grid. Nutzung: `Grid1.Columns[0].Style.FontStyle := [fsBold];` Praxis: Eine Spalte hervorheben, z. B. die Summenspalte fett oder eine schreibgeschützte Spalte mit grauer Fläche; bei eigener Color auch DarkColor setzen. |
| `TitleStyle` | [TPPGElementStyle](TPPGElementStyle.md) |  | Aussehen des Spaltenkopfs: Fläche, Text, Schrift. clDefault = wie Grid.Styles.Header. Praxis: Einen einzelnen Spaltenkopf hervorheben, z. B. die Pflichtspalte fett oder farbig. Für alle Köpfe Grid.Styles.Header nehmen. |
| `TitleAlignment` | `TPPGGridTitleAlignment` | `gtaColumn` | Ausrichtung des Spaltentitels: gtaColumn = wie Alignment der Spalte, sonst links, zentriert oder rechts. Werte: `gtaColumn`, `gtaLeft`, `gtaCenter`, `gtaRight`. Praxis: gtaColumn lassen, dann steht der Titel über rechtsbündigen Zahlen ebenfalls rechts. gtaCenter für schmale Spalten wie Kästchen. |

## Verwendet in

[TPPGGridColumns](TPPGGridColumns.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
