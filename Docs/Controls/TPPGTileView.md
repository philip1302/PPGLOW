# TPPGTileView

Palette **PPGlow** - Unit `PPG.TileView` - Basis `TPPGCustomTileView`

**Vorbild:** keins; ersetzt `TListView` in den Ansichten `vsIcon`/`vsSmallIcon` (für `vsReport` ist `TPPGGrid` gedacht)

## Unterschiede und Hinweise

- Ansichten über `TileStyle`: `tsIcons` (Explorer), `tsTiles` (Symbol links, Titel und Details), `tsCards` (Karten mit Vorschaubild aus `OnGetPicture` und Plakette).
- Einträge in `Items` (wie `TPPGListBox.ItemsEx`) oder virtuell: `OwnerData := True`, `ItemCount`, `OnGetItem`. Auch bei 100 000 Einträgen holt das Control nur die sichtbaren Kacheln.
- `FilterText` filtert und hebt den Begriff hervor; `OnFilterItem` für eigene Regeln. Indizes in Ereignissen und `Selected[]` sind immer Datenindizes, auch bei aktivem Filter.
- Gruppen (`Group` des Eintrags) mit klappbarem Kopf, `GroupCollapsed[...]` im Code.
- Bedienung: Pfeile in zwei Richtungen, Pos1/Ende, Bild auf/ab, Tippsuche, F2 benennt um (`OnRename`), Strg+Mausrad zoomt, Gummiband mit `MultiSelect`.
- Export und Druck: Die Kachelansicht ist eine Tabellenquelle (Text, Detail, Gruppe, Plakette); xlsx, CSV, HTML und `TPPGGridPrinter` funktionieren damit direkt.
- Die API ist bewusst nicht die der `TListView`; `migrate.ps1` stellt deshalb nicht automatisch um, sondern meldet die Stelle.

## Beispiel

```pascal
PPGTileView1.TileStyle := tsCards;
PPGTileView1.OwnerData := True;
PPGTileView1.ItemCount := Length(FProducts);  // Daten über OnGetItem
PPGTileView1.FilterText := PPGSearchEdit1.Text;
```

## Verhalten (aus dem Quelltext)

TPPGTileView - Kachel-, Karten- und Galerie-Ansicht (Phase 18b).

Mehrwert gegenueber TListView (vsIcon) und TMS: drei Ansichten mit
Kartenvorlage (Bild, Titel, Detail, Plakette), Suche mit Hervorhebung der
Treffer, Zoom (Strg+Rad), Gruppen mit Kopf (klappbar), virtuell fuer grosse
Mengen, Gummiband-Auswahl, Export und Druck ueber IPPGTableSource
(xlsx, HTML, PDF wie beim Grid).

Aufbau:
- Basis TPPGCustomScrollControl (Overlay-Leisten, weiches Scrollen, Auto-Scroll beim Ziehen). Daten ueber IPPGItemSource: Items (Collection TPPGItems) oder virtuell (ItemCount + OnGetItem).
- Layout: Rechtecke aller sichtbaren (gefilterten) Eintraege in Inhaltskoordinaten, nach Gruppen. Neu berechnet bei Groesse, Zoom, Filter, Ansicht und Datenaenderung; gezeichnet wird nur, was im Bild ist (binaere Suche ueber die Oberkante).
- Auswahl: TPPGSelection (Windows-Semantik) ueber den Positionen der Ansicht; Selected[] und ItemIndex sprechen in Daten-Indizes.
- Symbole: Images (ImageIndex), OnGetItemIcon (Zeichen der Symbolschrift) oder OnGetPicture (Vorschaubild, gehoert dem Aufrufer).
- Tastatur: Pfeile in zwei Dimensionen (naechster Eintrag in der Richtung), Pos1/Ende, Bild auf/ab, Umschalt/Strg wie Windows, Tippsuche, F2 benennt um, Enter = OnItemDblClick.
- Code setzt Auswahl und Filter ohne OnChange (PPGlow-Regel).

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `Items` | [TPPGItems](types/TPPGItems.md) |  | Einträge (Text, Detail, Gruppe, Bild, Plakette). Wird nicht benutzt, wenn OwnerData an ist. |
| `OwnerData` | `Boolean` | `False` | Virtueller Modus: ItemCount und OnGetItem statt Items. |
| `ItemCount` | `Integer` |  | Nur mit OwnerData: Zahl der Einträge; die Daten holt OnGetItem erst beim Zeichnen (auch 100 000 und mehr). Nutzung: `Tiles.OwnerData := True; Tiles.ItemCount := Length(Produkte);` |
| `TileStyle` | `TPPGTileStyle` | `tsTiles` | Ansicht: tsIcons = große Symbole mit Text darunter (Explorer), tsTiles = Symbol links mit Titel und Detailzeilen, tsCards = Karten mit Vorschaubild, Titel, Untertitel und Plakette. Werte: `tsIcons`, `tsTiles`, `tsCards`. |
| `Zoom` | `Integer` | `100` | Größe in Prozent (50 … 200); Strg+Mausrad ändert sie. |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). |
| `FilterText` | `string` |  | Suchbegriff: zeigt nur Einträge, deren Text oder Detail ihn enthält (ohne Groß-/Kleinschreibung), und hebt ihn hervor. Leer = alle. Nutzung: `Tiles.FilterText := SearchEdit1.Text;` |
| `GroupView` | `Boolean` | `True` | Einträge nach Item.Group gruppieren, mit Kopfzeile je Gruppe; ein Klick auf den Kopf klappt die Gruppe zu. |
| `Checkboxes` | `Boolean` | `False` | Kästchen in jeder Kachel zum Abhaken (Checked des Eintrags), unabhängig von der Auswahl. |
| `MultiSelect` | `Boolean` | `False` | Mehrfachauswahl wie im Explorer: Strg+Klick, Umschalt+Klick und Gummiband mit der Maus. |
| `ReadOnly` | `Boolean` | `False` | True: kein Umbenennen mit F2. |
| `EmptyText` | `string` |  | Text in der Mitte, wenn kein Eintrag da ist oder der Filter nichts findet; leer = „Keine Einträge“. |
| `ItemStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Aussehen der Kacheln: Fläche, Text, Rand und Schrift. |
| `SelectedStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Aussehen gewählter Kacheln; leer = Akzentfarbe des Presets. |
| `GroupStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Aussehen der Gruppenköpfe: Fläche, Text und Schrift. |
| `ScrollBarMode` | `TPPGScrollBarMode` | `sbmAuto` | Wann die Scrollleisten erscheinen: sbmAuto (bei Bedarf, als schmale Overlay-Leiste), sbmAlways (immer), sbmNever (nie; Scrollen nur per Rad, Tastatur oder Code). Werte: `sbmAuto`, `sbmAlways`, `sbmNever`. |
| `SmoothScrolling` | `Boolean` | `True` | True: Scrollen per Rad und Tastatur gleitet weich statt sprunghaft. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |
| `DragKind` | `TDragKind` |  | dkDrag = Drag & Drop, dkDock = Andocken beim Ziehen. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. |
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
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Auswahl oder aktueller Eintrag haben sich geändert. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnGetItem` | `TPPGGetItemEvent` `(Sender: TObject; Index: Integer; var Data: TPPGItemData)` | Mit OwnerData: liefert die Daten des Eintrags Index (Text, Detail, Bild …) in den übergebenen Eintrag. Nutzung: `Data.Text := Produkte[Index].Name; Data.Detail := FormatFloat('0.00 €', Produkte[Index].Preis);` |
| `OnGetItemIcon` | `TPPGTileIconEvent` `(Sender: TObject; Index: Integer; var CodePoint: Word)` | Symbol (Zeichen der Symbolschrift) je Eintrag, wenn kein Bild aus Images gezeigt wird. |
| `OnGetPicture` | `TPPGTilePictureEvent` `(Sender: TObject; Index: Integer; var Picture: TGraphic)` | Nur bei tsCards: Vorschaubild je Eintrag (z. B. Foto eines Produkts). Das Bild gehört dem Aufrufer, das Control kopiert es nicht; große Mengen am besten aus einem eigenen Cache liefern. |
| `OnFilterItem` | `TPPGTileFilterEvent` `(Sender: TObject; Index: Integer; const Data: TPPGItemData; var Accept: Boolean)` | Eigene Filterregel zusätzlich zu FilterText: Accept := False blendet den Eintrag aus. |
| `OnItemClick` | `TPPGTileItemEvent` `(Sender: TObject; Index: Integer)` | Klick auf eine Kachel; Index nennt den Eintrag (Datenindex, auch bei aktivem Filter). |
| `OnItemDblClick` | `TPPGTileItemEvent` `(Sender: TObject; Index: Integer)` | Doppelklick bzw. Enter auf einer Kachel, z. B. zum Öffnen. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnRename` | `TPPGTileRenameEvent` `(Sender: TObject; Index: Integer; var NewText: string; var Accept: Boolean)` | Nach dem Umbenennen mit F2 bzw. EditItem: Accept := False verwirft den neuen Text. |
| `OnScroll` | `TNotifyEvent` `(Sender: TObject)` | Die Scrollposition hat sich geändert (Rad, Leiste, Tastatur oder Code). Nutzung: Z. B. um eine Positionsanzeige zu aktualisieren: `lblZeile.Caption := IntToStr(Grid.TopRow);` |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGTileView.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
