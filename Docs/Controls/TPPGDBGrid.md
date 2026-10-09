# TPPGDBGrid

Palette **PPGlow DB** - Unit `PPG.DB.Grid` - Basis `TPPGCustomDBGrid`

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

## Verhalten (aus dem Quelltext)

TPPGDBGrid - Tabelle einer Datenmenge (Phase 9c), wie TDBGrid.

Aufbau:
- Erbt von TPPGCustomGrid (Zeichnen, Editoren, Tastatur, UIA bleiben).
- Zeilen sind der Puffer des TDataLink (BufferCount = sichtbare Zeilen), nie die ganze Tabelle. Die Kopfzeile zeigt die Titel, die feste Spalte links den Datensatzzeiger (Indikator).
- Die Texte des Puffers werden in den DataLink-Ereignissen gelesen und zwischengespeichert. Paint liest nur den Zwischenspeicher: kein Datensatzwechsel und keine Anwender-Ereignisse (OnGetText, OnCalcFields) waehrend des Zeichnens (Fallstrick aus der Roadmap).
- Die senkrechte Leiste zeigt die Lage in der Datenmenge: bei IsSequenced nach RecNo/RecordCount, sonst dreistufig (Anfang, Mitte, Ende) wie TDBGrid. Ziehen, Mausrad und Blaettern bewegen die Datenmenge.
- Spalten: ohne Columns alle sichtbaren Felder (Titel = DisplayLabel, Breite aus DisplayWidth); mit Columns (FieldName je Spalte) genau diese.
- Bearbeiten mit den Grid-Editoren; der Editor zeigt Field.Text, Schreiben setzt Field.Text (Boolean-Felder: Kaestchen-Spalte).
- Tastatur wie TDBGrid: Pfeile/Bild/Strg+Pos1/Ende bewegen die Datenmenge, Pfeil runter am Ende haengt an (dgEditing), Einfg fuegt ein, Strg+Entf loescht (mit Rueckfrage bei dgConfirmDelete), Esc bricht ab.
- Sortieren ist Sache der Datenmenge: Klick auf den Titel loest OnTitleClick aus (dgTitleClick).
- Spalten verschieben (dgColumnResize, wie TDBGrid), ausblenden, Layout speichern (Schluessel = Feldname) wie im Grid (Phase 13g); automatische Spalten behalten Position, Sichtbarkeit und Breite beim Neuaufbau.
- Summenzeile (ShowFooter) aus der Datenmenge: Column.FooterField (z.B. ein TAggregateField) oder OnGetFooterText. Das Grid liest dafuer nie die ganze Datenmenge (Paint-Regel aus Phase 9).
- Drucken und Export (IPPGTableSource): die Datenmenge wird einmal mit DisableControls und Lesezeichen durchlaufen (hoechstens ExportMaxRecords).
- Nicht unterstuetzt: Gruppieren (braeuchte die ganze Datenmenge im Speicher; GROUP BY in der Abfrage nutzen), dgMultiSelect, Unterspalten (ADT/Array-Felder).

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `Columns` | [TPPGGridColumns](types/TPPGGridColumns.md) |  | Spaltendefinitionen: Titel, Breite, Ausrichtung, Editor, Zellart, Summe, Gruppierung, Stile. Ohne Einträge gelten Standardspalten mit DefaultColWidth. Nutzung: Im Designer per Doppelklick; im Code `with Grid1.Columns.Add do begin Title := 'Preis'; Alignment := taRightJustify; Aggregate := agSum; end;` |
| `Bands` | [TPPGGridBands](types/TPPGGridBands.md) |  | Bänder: Überschriften über mehreren Spalten, auch mehrstufig (ParentBand). Welche Spalten darunter stehen, legt Column.Band fest. Nutzung: `Grid1.Bands.Add.Caption := 'Adresse'; Grid1.Columns[2].Band := 0; Grid1.Columns[3].Band := 0;` |
| `ConditionalFormats` | [TPPGGridConditionalFormats](types/TPPGGridConditionalFormats.md) |  | Bedingte Formate ohne Code: Regeln je Spalte (Wertbereich, gleich, enthält, oberste/unterste N, Farbskala, Datenbalken, Symbolsatz) mit Farben aus dem Theme. Nutzung: `with Grid1.ConditionalFormats.Add do begin Column := 3; Rule := crDataBar; Color := ccAccent; end;` |
| `ExportMaxRecords` | `Integer` | `100000` | Drucken und Export lesen höchstens so viele Datensätze (Schutz vor sehr großen Tabellen). Vorgabe 100000. |
| `ShowRequired` | `Boolean` | `False` | True: Spalten mit Pflichtfeldern (TField.Required) zeigen im Titel ein Sternchen. |
| `FixedColsRight` | `Integer` | `0` | Anzahl Spalten, die rechts fest stehen bleiben (0..100), z. B. eine Aktions- oder Summenspalte. |
| `HeaderMenu` | `Boolean` | `True` | True: Rechtsklick auf den Kopf öffnet ein Menü zum Sortieren, Ausblenden, Wählen der Spalten und Anpassen der Breite. Ergänzen lässt es sich in OnHeaderMenu. |
| `ShowFooter` | `Boolean` | `False` | True: Unten steht eine Summenzeile; was je Spalte berechnet wird, legt Column.Aggregate fest (gilt für die gefilterte Ansicht). |
| `DataSource` | `TDataSource` |  | Die Datenquelle, deren Datenmenge das Grid zeigt. Ohne Columns erscheinen alle sichtbaren Felder (Titel = DisplayLabel, Breite aus DisplayWidth). Nutzung: `PPGDBGrid1.DataSource := DataSource1;` |
| `Options` | `TDBGridOptions` | `[dgEditing, dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]` | Verhalten wie bei TDBGrid: dgEditing (bearbeiten), dgTitles (Titelzeile), dgIndicator (Datensatzzeiger links), dgColumnResize (Spaltenbreite und -position ändern), dgColLines/dgRowLines (Gitterlinien), dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete (Rückfrage bei Strg+Entf), dgCancelOnExit, dgTitleClick, dgTitleHotTrack. dgMultiSelect wird nicht unterstützt. |
| `ReadOnly` | `Boolean` | `False` | True: Keine Bearbeitung im Grid, auch wenn die Datenmenge änderbar ist. |
| `ScrollBarMode` | `TPPGScrollBarMode` | `sbmAuto` | Wann die Scrollleisten erscheinen: sbmAuto (bei Bedarf, als schmale Overlay-Leiste), sbmAlways (immer), sbmNever (nie; Scrollen nur per Rad, Tastatur oder Code). Werte: `sbmAuto`, `sbmAlways`, `sbmNever`. |
| `SmoothScrolling` | `Boolean` | `True` | True: Scrollen per Rad und Tastatur gleitet weich statt sprunghaft. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `Styles` | [TPPGGridStyles](types/TPPGGridStyles.md) |  | Bereiche des Grids einzeln gestalten: Header, Footer, Selection, SelectionInactive, AlternateRow (Zebra), HotRow, GridLine, FocusedCell, GroupRow, FilterRow. Nur gesetzte Werte zählen, der Rest kommt vom Preset. Nutzung: `Grid1.Styles.AlternateRow.Color := $00FAF5EE; Grid1.Styles.Header.FontStyle := [fsBold];` |
| `GridLineWidth` | `Integer` | `1` | Breite der Gitterlinien in logischen Pixeln (0..10; 0 = keine Linien). Farbe über Styles.GridLine.Color. |
| `DrawingStyle` | `TGridDrawingStyle` | `gdsThemed` | Wie TStringGrid: gdsGradient zeichnet den Kopf als Verlauf von GradientStartColor nach GradientEndColor (nur im Hellen); gdsClassic und gdsThemed nehmen den Kopf vom Preset bzw. aus Styles.Header. |
| `FixedColor` | `TColor` |  | Wie TStringGrid.FixedColor: Hintergrund des Kopfs. Ist ein Alias für Styles.Header.Color und wird nicht eigens gespeichert; clBtnFace bedeutet „vom Preset". Nutzung: `Grid1.FixedColor := $00F0E6DC;` |
| `GradientEndColor` | `TColor` | `clBtnFace` | Endfarbe des Kopf-Verlaufs bei DrawingStyle = gdsGradient. |
| `GradientStartColor` | `TColor` | `clWhite` | Anfangsfarbe des Kopf-Verlaufs bei DrawingStyle = gdsGradient. |
| `TitleFont` | `TFont` |  | Wie TDBGrid.TitleFont: Schrift der Titelzeile. Ist ein Alias für Styles.Header.Font und wird nicht eigens gespeichert. |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen. |
| `DefaultDrawing` | `Boolean` | `True` | False: Der Zelltext wird nicht gezeichnet (Hintergrund, Linien und Auswahl schon); den Inhalt zeichnet man in OnDrawCell selbst. |
| `ToolTips` | `Boolean` | `True` | Wie TTreeView.ToolTips: Ein abgeschnittener Zelltext (auch im Spaltenkopf) erscheint ganz als Hinweis, solange die Maus auf der Zelle steht. Nicht bei Zellarten wie Haken oder Fortschritt; nur ohne eigenen Hint; braucht ShowHint = True. |

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
| `OnCellClick` | `TPPGDBGridColumnEvent` `(Column: TPPGDBGridColumn)` | Klick mit der linken Maustaste auf eine Datenzelle; Column ist die angeklickte Spalte (Column.Field liefert das Feld). |
| `OnColumnMoved` | `TMovedEvent` `(Sender: TObject; FromIndex, ToIndex: Longint)` | Der Anwender hat eine Spalte verschoben; FromIndex und ToIndex sind Anzeige-Positionen. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnDrawCell` | `TDrawCellEvent` `(Sender: TObject; ACol, ARow: Longint; Rect: TRect; State: TGridDrawState)` | Nach dem Standardzeichnen einer Zelle zusätzlich auf Canvas zeichnen (Rect, State mit gdSelected, gdFocused, gdFixed). Mit DefaultDrawing = False zeichnet man so den ganzen Zellinhalt selbst. ACol und ARow sind Datenspalte und -zeile. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnGetCellStyle` | `TPPGGridCellStyleEvent` `(Sender: TObject; ACol, ARow: Integer; var Style: TPPGGridCellStyle)` | Darstellung je Zelle nach den bedingten Formaten: Style.Fill, TextColor, Bold, FontStyle, FontName, FontSize, Datenbalken (Bar, BarColor) und Symbol (Icon, IconColor) setzen. Nutzung: `if StrToFloatDef(Grid1.Cells[ACol, ARow], 0) < 0 then Style.TextColor := clRed;` |
| `OnGetFooterText` | `TPPGDBGridFooterEvent` `(Sender: TObject; Column: TPPGDBGridColumn; var Text: string)` | Text der Summenzeile (ShowFooter) für eine Spalte. Text ist mit dem Wert aus Column.FooterField vorbelegt und kann ersetzt werden; die ganze Datenmenge liest das Grid dafür nie. Nutzung: `if Column.FieldName = 'Betrag' then Text := FormatFloat('#,##0.00 €', SummeAusAbfrage);` |
| `OnHeaderMenu` | `TPPGGridHeaderMenuEvent` `(Sender: TObject; ACol: Integer; Menu: TPopupMenu)` | Das Kopfmenü öffnet sich gleich: Einträge in Menu ergänzen oder entfernen; ACol ist die Datenspalte. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnTitleClick` | `TPPGDBGridColumnEvent` `(Column: TPPGDBGridColumn)` | Klick auf einen Spaltentitel (mit dgTitleClick in Options). Sortieren ist Sache der Datenmenge, z. B. IndexFieldNames setzen. Nutzung: `FDQuery1.IndexFieldNames := Column.FieldName;` |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |
| `OnColEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Fokusspalte hat gewechselt (Maus, Tastatur oder Code); die neue Spalte ist schon aktiv (wie TDBGrid.OnColEnter). |
| `OnColExit` | `TNotifyEvent` `(Sender: TObject)` | Die Fokusspalte wird verlassen; die alte Spalte ist noch aktiv (wie TDBGrid.OnColExit). |
| `OnEditButtonClick` | `TNotifyEvent` `(Sender: TObject)` | Der „…“-Knopf im Editor einer Spalte mit ButtonStyle = cbsEllipsis wurde geklickt oder Strg+Enter gedrückt (wie TDBGrid.OnEditButtonClick). Typisch: Auswahldialog öffnen und den Wert ins Feld schreiben. Nutzung: `procedure TForm1.Grid1EditButtonClick(Sender: TObject); begin if KundeWaehlen(Nr) then Table1.FieldByName('KundeNr').AsInteger := Nr; end;` |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBGrid.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
