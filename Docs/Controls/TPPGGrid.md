# TPPGGrid

Palette **PPGlow** - Unit `PPG.Grid` - Basis `TPPGCustomGrid`

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
```

## Verhalten (aus dem Quelltext)

TPPGGrid - Tabelle im Stil der Suite (Phase 6c).

- Ein einziges Fenster, alle Zellen gezeichnet (keine Kind-Controls ausser dem gerade aktiven Editor). Scrollen, Overlay-Leisten, Mausrad und Auto-Scroll kommen aus TPPGCustomScrollControl.
- Feste Kopfzeilen/-spalten (FixedRows/FixedCols) bleiben beim Scrollen stehen. Zeilenpositionen ueber TPPGRowLayout: 1 000 000 Zeilen in O(1).
- Daten: Cells[] (wie TStringGrid) oder virtuell ueber OnGetCellText.
- Sortieren (Klick auf den Kopf) und Filtern (Filterzeile) arbeiten auf einem Index-Array "sichtbare Zeile -> Datenzeile", nie auf den Daten. Row und Cells[] verwenden immer DATEN-Zeilen; Selection (TGridRect) ist in sichtbaren Zeilen (wie bei TStringGrid ohne Sortierung identisch).
- Spalten (Columns): Titel, Breite, Ausrichtung, Editor (Text, Auswahl, Zahl, Kaestchen), Auswahlliste, Schreibschutz.
- Spalten in der Anzeige (Phase 13b): verschieben (Ziehen am Kopf, goColMoving), ausblenden (Visible, Kopfmenue), Breite per Doppelklick, rechts fixieren (FixedColsRight), Baender (Bands) und Layout speichern.
- Gruppieren und Summen (Phase 13c): Column.GroupIndex bzw. GroupBy, Gruppen- leiste (ShowGroupPanel, Kopf hineinziehen), Gruppenzeilen mit Pfeil und Markup-Text (OnGetGroupText), Summenzeile (ShowFooter) und Gruppenfuss (GroupFooter) ueber Column.Aggregate. Summen gelten fuer die Ansicht (gefiltert), werden beim Aendern von Ansicht oder Daten neu berechnet und zwischengespeichert - nie beim Zeichnen.
- Zellen (Phase 13d): verbundene Zellen (MergeCells; nur ohne Sortierung, Filter und Gruppierung - dann ruhen sie), bedingte Formate (ConditionalFormats, OnGetCellStyle) und Zellarten je Spalte (Column.CellKind ueber IPPGCellKind: Kaestchen, Fortschritt, Sparkline, Bewertung, Bild, Link, Button, Farbfeld, Markup). Intern sind Spalten-Indizes von Geometrie, Fokus und Auswahl ANZEIGE- Spalten (wie sichtbare Zeilen); Cells[], Col, Columns[] und Ereignisse verwenden DATEN-Spalten. DataCol/VisualCol rechnen um.
- Editoren sind PPGlow-Felder (TPPGEdit/TPPGComboBox/TPPGSpinEdit) ueber der Zelle: Enter uebernimmt, Esc verwirft, Tab uebernimmt und geht weiter, Scrollen und Fokusverlust uebernehmen.
- Zwischenablage als TSV (Strg+C / Strg+V), Export als CSV.
- DFM-kompatibel zu TStringGrid in den Grundproperties (ColCount, RowCount, FixedCols/Rows, DefaultColWidth/RowHeight, Options, ColWidths/RowHeights). Breiten und Hoehen sind wie ueberall in PPGlow logische 96-DPI-Pixel.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). |
| `Bands` | [TPPGGridBands](types/TPPGGridBands.md) |  | Bänder: Überschriften über mehreren Spalten, auch mehrstufig (ParentBand). Welche Spalten darunter stehen, legt Column.Band fest. Nutzung: `Grid1.Bands.Add.Caption := 'Adresse'; Grid1.Columns[2].Band := 0; Grid1.Columns[3].Band := 0;` |
| `Columns` | [TPPGGridColumns](types/TPPGGridColumns.md) |  | Spaltendefinitionen: Titel, Breite, Ausrichtung, Editor, Zellart, Summe, Gruppierung, Stile. Ohne Einträge gelten Standardspalten mit DefaultColWidth. Nutzung: Im Designer per Doppelklick; im Code `with Grid1.Columns.Add do begin Title := 'Preis'; Alignment := taRightJustify; Aggregate := agSum; end;` |
| `ShowFilterRow` | `Boolean` | `False` | True: Unter dem Kopf erscheint eine Eingabezeile; Text je Spalte filtert die Zeilen (Teiltext, ohne Groß-/Kleinschreibung). Wirkt auf die Ansicht, die Daten bleiben unverändert. |
| `FixedColsRight` | `Integer` | `0` | Anzahl Spalten, die rechts fest stehen bleiben (0..100), z. B. eine Aktions- oder Summenspalte. |
| `HeaderMenu` | `Boolean` | `True` | True: Rechtsklick auf den Kopf öffnet ein Menü zum Sortieren, Ausblenden, Wählen der Spalten und Anpassen der Breite. Ergänzen lässt es sich in OnHeaderMenu. |
| `ShowFooter` | `Boolean` | `False` | True: Unten steht eine Summenzeile; was je Spalte berechnet wird, legt Column.Aggregate fest (gilt für die gefilterte Ansicht). |
| `GroupFooter` | `Boolean` | `False` | True: Unter jeder Gruppe steht eine Fußzeile mit den Summen (Column.Aggregate). |
| `ShowGroupPanel` | `Boolean` | `False` | True: Über dem Grid erscheint eine Leiste; einen Spaltenkopf hineinziehen gruppiert nach dieser Spalte (mehrstufig möglich). |
| `ConditionalFormats` | [TPPGGridConditionalFormats](types/TPPGGridConditionalFormats.md) |  | Bedingte Formate ohne Code: Regeln je Spalte (Wertbereich, gleich, enthält, oberste/unterste N, Farbskala, Datenbalken, Symbolsatz) mit Farben aus dem Theme. Nutzung: `with Grid1.ConditionalFormats.Add do begin Column := 3; Rule := crDataBar; Color := ccAccent; end;` |
| `SortOnHeaderClick` | `Boolean` | `True` | True: Klick auf einen Spaltenkopf sortiert die Ansicht nach dieser Spalte, erneuter Klick kehrt die Richtung um (nur Spalten mit Sortable = True). |
| `ScrollBarMode` | `TPPGScrollBarMode` | `sbmAuto` | Wann die Scrollleisten erscheinen: sbmAuto (bei Bedarf, als schmale Overlay-Leiste), sbmAlways (immer), sbmNever (nie; Scrollen nur per Rad, Tastatur oder Code). Werte: `sbmAuto`, `sbmAlways`, `sbmNever`. |
| `SmoothScrolling` | `Boolean` | `True` | True: Scrollen per Rad und Tastatur gleitet weich statt sprunghaft. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `Styles` | [TPPGGridStyles](types/TPPGGridStyles.md) |  | Bereiche des Grids einzeln gestalten: Header, Footer, Selection, SelectionInactive, AlternateRow (Zebra), HotRow, GridLine, FocusedCell, GroupRow, FilterRow. Nur gesetzte Werte zählen, der Rest kommt vom Preset. Nutzung: `Grid1.Styles.AlternateRow.Color := $00FAF5EE; Grid1.Styles.Header.FontStyle := [fsBold];` |
| `GridLineWidth` | `Integer` | `1` | Breite der Gitterlinien in logischen Pixeln (0..10; 0 = keine Linien). Farbe über Styles.GridLine.Color. |
| `DrawingStyle` | `TGridDrawingStyle` | `gdsThemed` | Wie TStringGrid: gdsGradient zeichnet den Kopf als Verlauf von GradientStartColor nach GradientEndColor (nur im Hellen); gdsClassic und gdsThemed nehmen den Kopf vom Preset bzw. aus Styles.Header. |
| `FixedColor` | `TColor` |  | Wie TStringGrid.FixedColor: Hintergrund des Kopfs. Ist ein Alias für Styles.Header.Color und wird nicht eigens gespeichert; clBtnFace bedeutet „vom Preset". Nutzung: `Grid1.FixedColor := $00F0E6DC;` |
| `GradientEndColor` | `TColor` | `clBtnFace` | Endfarbe des Kopf-Verlaufs bei DrawingStyle = gdsGradient. |
| `GradientStartColor` | `TColor` | `clWhite` | Anfangsfarbe des Kopf-Verlaufs bei DrawingStyle = gdsGradient. |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen. |
| `ColCount` | `Integer` | `5` | Anzahl der Spalten einschließlich fester Spalten (1..100000), wie TStringGrid. |
| `DefaultColWidth` | `Integer` | `64` | Breite der Spalten ohne eigene Breite in logischen Pixeln (1..10000). |
| `DefaultDrawing` | `Boolean` | `True` | False: Der Zelltext wird nicht gezeichnet (Hintergrund, Linien und Auswahl schon); den Inhalt zeichnet man in OnDrawCell selbst. |
| `DefaultRowHeight` | `Integer` | `24` | Höhe der Zeilen ohne eigene Höhe in logischen Pixeln (1..10000). |
| `FixedCols` | `Integer` | `1` | Anzahl fester Spalten links, die beim waagerechten Scrollen stehen bleiben (0..ColCount-1). |
| `RowCount` | `Integer` | `5` | Anzahl der Zeilen einschließlich fester Zeilen (1 bis etwa 1 Milliarde); auch große Zahlen sind schnell (virtuell mit OnGetCellText). |
| `FixedRows` | `Integer` | `1` | Anzahl fester Kopfzeilen oben (0..RowCount-1). |
| `Options` | `TGridOptions` | `[goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect]` | Verhalten wie bei TStringGrid: goEditing (bearbeiten), goRowSelect (ganze Zeile wählen), goRangeSelect (Bereich wählen), goColSizing/goRowSizing (Breite/Höhe ziehen), goColMoving (Spalten verschieben), goTabs (Tab wechselt Zelle), goVertLine/goHorzLine und goFixedVertLine/goFixedHorzLine (Gitterlinien), goAlwaysShowEditor, goThumbTracking. Nutzung: `Grid1.Options := Grid1.Options + [goEditing, goColSizing];` |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Color` | `TColor` | `clWindow` | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |
| `DragKind` | `TDragKind` |  | dkDrag = Drag & Drop, dkDock = Andocken beim Ziehen. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
| `ParentColor` | `Boolean` | `False` | True: Color wird vom Parent übernommen. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). |
| `TabStop` | `Boolean` | `True` | True: Das Control ist mit Tab erreichbar. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
| `OnCompareCells` | `TPPGCompareCellsEvent` `(Sender: TObject; ACol, ARow1, ARow2: Integer; var Compare: Integer)` | Eigener Vergleich beim Sortieren: Compare < 0, = 0 oder > 0 setzen (Zeile ARow1 vor, gleich oder nach ARow2). Ohne Ereignis vergleicht das Grid Zahlen numerisch, sonst als Text. Nutzung: `Compare := CompareDate(StrToDate(Cells[ACol, ARow1]), StrToDate(Cells[ACol, ARow2]));` |
| `OnCellButtonClick` | `TPPGGridCellEvent` `(Sender: TObject; ACol, ARow: Integer)` | Eine Schaltfläche in einer Zelle mit CellKind = ckButton wurde geklickt (ACol, ARow = Datenspalte und -zeile). Nutzung: `if ACol = 4 then LoescheZeile(ARow);` |
| `OnColumnMoved` | `TMovedEvent` `(Sender: TObject; FromIndex, ToIndex: Longint)` | Der Anwender hat eine Spalte verschoben; FromIndex und ToIndex sind Anzeige-Positionen. |
| `OnCustomAggregate` | `TPPGGridCustomAggregateEvent` `(Sender: TObject; ACol, Group: Integer; var Value: string)` | Wert für Spalten mit Aggregate = agCustom: Value für Spalte ACol in Gruppe Group setzen (Group = -1 = Summenzeile). Die Zeilen der Gruppe liefert GroupDataRows(Group). |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnDrawCell` | `TDrawCellEvent` `(Sender: TObject; ACol, ARow: Longint; Rect: TRect; State: TGridDrawState)` | Nach dem Standardzeichnen einer Zelle zusätzlich auf Canvas zeichnen (Rect, State mit gdSelected, gdFocused, gdFixed). Mit DefaultDrawing = False zeichnet man so den ganzen Zellinhalt selbst. ACol und ARow sind Datenspalte und -zeile. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnFixedCellClick` | `TFixedCellClickEvent` `(Sender: TObject; ACol, ARow: Longint)` | Klick auf eine feste Zelle (Kopf oder feste Spalte). |
| `OnGetCellText` | `TPPGGetCellTextEvent` `(Sender: TObject; ACol, ARow: Integer; var Text: string)` | Virtuelle Daten: liefert den Text einer Zelle, ohne dass er in Cells[] steht (z. B. für eine Million Zeilen aus einer eigenen Liste). Nutzung: `Text := FDaten[ARow - 1].Name;` |
| `OnGetEditText` | `TGetEditEvent` `(Sender: TObject; ACol, ARow: Longint; var Value: string)` | Wie TStringGrid: Text, mit dem der Editor einer Zelle startet (z. B. ein Rohwert statt der formatierten Anzeige). |
| `OnGetGroupText` | `TPPGGridGroupTextEvent` `(Sender: TObject; Group: Integer; var Text: string)` | Text einer Gruppenzeile (Markup erlaubt); Group ist der Index für GroupInfo. Nutzung: `Text := Format('<b>%s</b> (%d)', [GroupInfo(Group).Key, GroupInfo(Group).Count]);` |
| `OnGetCellStyle` | `TPPGGridCellStyleEvent` `(Sender: TObject; ACol, ARow: Integer; var Style: TPPGGridCellStyle)` | Darstellung je Zelle nach den bedingten Formaten: Style.Fill, TextColor, Bold, FontStyle, FontName, FontSize, Datenbalken (Bar, BarColor) und Symbol (Icon, IconColor) setzen. Nutzung: `if StrToFloatDef(Grid1.Cells[ACol, ARow], 0) < 0 then Style.TextColor := clRed;` |
| `OnHeaderMenu` | `TPPGGridHeaderMenuEvent` `(Sender: TObject; ACol: Integer; Menu: TPopupMenu)` | Das Kopfmenü öffnet sich gleich: Einträge in Menu ergänzen oder entfernen; ACol ist die Datenspalte. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |
| `OnLinkClick` | `TPPGGridLinkEvent` `(Sender: TObject; ACol, ARow: Integer; const Link: string)` | Eine Link-Zelle (CellKind = ckLink) oder ein Link im Markup wurde angeklickt; Link ist das Ziel bzw. der Zelltext. Nutzung: `ShellExecute(0, 'open', PChar(Link), nil, nil, SW_SHOWNORMAL);` |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnScroll` | `TNotifyEvent` `(Sender: TObject)` | Die Scrollposition hat sich geändert (Rad, Leiste, Tastatur oder Code). Nutzung: Z. B. um eine Positionsanzeige zu aktualisieren: `lblZeile.Caption := IntToStr(Grid.TopRow);` |
| `OnSelectCell` | `TSelectCellEvent` `(Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean)` | Vor dem Wechsel der Fokuszelle; CanSelect := False verhindert ihn. |
| `OnSetEditText` | `TSetEditEvent` `(Sender: TObject; ACol, ARow: Longint; const Value: string)` | Wie TStringGrid: der Editor hat einen neuen Wert in die Zelle geschrieben. |
| `OnSorted` | `TNotifyEvent` `(Sender: TObject)` | Die Ansicht wurde neu sortiert (Klick auf den Kopf oder Code). |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnTopLeftChange` | `TNotifyEvent` `(Sender: TObject)` | Die oberste sichtbare Zeile oder die linke sichtbare Spalte hat sich durch Scrollen geändert. |
| `OnValidateCell` | `TPPGValidateCellEvent` `(Sender: TObject; ACol, ARow: Integer; var Value: string; var Accept: Boolean)` | Vor dem Übernehmen eines bearbeiteten Werts: Value prüfen oder korrigieren; Accept := False lehnt ab (der Editor bleibt offen). Nutzung: `Accept := TryStrToFloat(Value, X); if not Accept then ShowMessage('Bitte eine Zahl eingeben');` |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGGrid.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
