# TPPGTreeView

Palette **PPGlow** - Unit `PPG.TreeView` - Basis `TPPGCustomTreeView`

**Vorbild:** TTreeView

## Unterschiede und Hinweise

- `ItemHeight` ist eine Mindesthöhe.
- `Selected := X` löst wie `TTreeView` `OnChange` aus (anders als die übrigen PPGlow-Controls).
- Lazy Loading über `HasChildren` + `OnExpanding`; nur der Pfeil dreht sich animiert.
- Knoten aus `TTreeView`-DFMs (binär) werden nicht gelesen; Knoten im Designer über „Edit nodes...“ anlegen.
- UI Automation: Hierarchie, Auf-/Zuklappen, Ebene und Position im Satz.

## Anpassung

- `Styles` wie die Listen; je Knoten `Color`, `TextColor`, `FontStyle` (zur Laufzeit).
- `OnCustomDrawNode`; wie `TTreeView`: `HotTrack` und `ToolTips` (abgeschnittene Knoten, braucht `ShowHint`).

## Beispiel

```pascal
N := PPGTreeView1.Items.AddChild(nil, 'Dokumente');
N.HasChildren := True;  // Kinder erst in OnExpanding
```

## Verhalten (aus dem Quelltext)

TPPGTreeView - Baum im Stil der Suite (Phase 6b).

Aufbau: Die sichtbaren Knoten bilden eine flache Zeilenliste; sie ist die
IPPGItemSource der Listen-Basis. Zeichnen, Scrollen, Auswahl, Tippsuche
und Barrierefreiheit kommen damit aus TPPGCustomItemList; der Baum fuegt
Einzug, Auf-/Zuklapp-Pfeil, Linien, Kaestchen und das Umbenennen hinzu.

- Knoten: TPPGTreeNode/TPPGTreeNodes mit einer API wie TTreeNode/TTreeNodes (Add, AddChild, Insert, MoveTo, Expand, Collapse, GetNext, ...).
- Lazy Loading wie bei TTreeView: HasChildren := True zeigt den Pfeil ohne Kinder; OnExpanding fuellt die Kinder beim ersten Aufklappen.
- Kaestchen (CheckBoxes) mit drei Zustaenden; AutoCheck gibt den Zustand an Kinder weiter und berechnet die Eltern (alle an / alle aus / gemischt).
- Umbenennen (ReadOnly = False) mit F2 bzw. EditText ueber ein natives Edit: Enter uebernimmt, Esc verwirft, Fokusverlust und Scrollen uebernehmen.
- Knoten ziehen (AllowReorder): oberes/unteres Viertel = davor/danach, Mitte = hinein; OnNodeDrop kann ablehnen.
- Ereignisse: OnChange auch bei Selected im Code (wie TTreeView); Aufklappen ruft OnExpanding auch aus dem Code (noetig fuer Lazy Loading).
- Streaming: Items als lesbare Zeilenliste ("Items.Nodes"); binaere TTreeView-Knoten aus alten DFMs werden nicht gelesen.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). |
| `AllowMarkup` | `Boolean` | `False` | True: Texte der Einträge dürfen Mini-Markup enthalten (<b>, <i>, <u>, <color=...>). Nutzung: `List.AllowMarkup := True; List.ItemsEx.Add('<b>Wichtig</b> heute');` |
| `AllowReorder` | `Boolean` | `False` | True: Einträge lassen sich mit der Maus umsortieren (Ziehen) bzw. mit Strg+Pfeiltasten verschieben; danach kommt OnReorder. |
| `Styles` | [TPPGListStyles](types/TPPGListStyles.md) |  | Bereiche der Liste einzeln gestalten: Selection, SelectionInactive (Auswahl ohne Fokus), AlternateRow (Zebra), HotItem (Maus darüber), GroupHeader, Detail (zweite Zeile). Nicht gesetzte Farben kommen aus dem Preset. Nutzung: `List.Styles.AlternateRow.Color := $00FAF7F2;` |
| `ScrollBarMode` | `TPPGScrollBarMode` | `sbmAuto` | Wann die Scrollleisten erscheinen: sbmAuto (bei Bedarf, als schmale Overlay-Leiste), sbmAlways (immer), sbmNever (nie; Scrollen nur per Rad, Tastatur oder Code). Werte: `sbmAuto`, `sbmAlways`, `sbmNever`. |
| `SmoothScrolling` | `Boolean` | `True` | True: Scrollen per Rad und Tastatur gleitet weich statt sprunghaft. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `AutoCheck` | `Boolean` | `True` | Nur mit CheckBoxes: Umschalten eines Knotens gibt den Zustand an alle Kinder weiter und berechnet die Eltern (alle an, alle aus oder gemischt). |
| `AutoExpand` | `Boolean` | `False` | True: Ein Knoten klappt beim Wählen per Maus oder Tastatur automatisch auf. |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen. |
| `CheckBoxes` | `Boolean` | `False` | True: Jeder Knoten zeigt ein Kästchen mit drei Zuständen (Node.CheckState); Änderungen meldet OnChecked. |
| `HideSelection` | `Boolean` | `False` | True: Die Auswahl wird ohne Fokus nicht hervorgehoben. |
| `HotTrack` | `Boolean` | `False` | Wie TTreeView: Der Knoten unter der Maus wird unterstrichen. |
| `Indent` | `Integer` | `19` | Einzug je Ebene in logischen Pixeln (0..200, Vorgabe 19). |
| `ItemHeight` | `Integer` | `0` | Zeilenhöhe in logischen Pixeln; 0 = aus der Schrift berechnet (mit Detailzeile entsprechend höher). |
| `Items` | `TPPGTreeNodes` |  | Die Knoten (API wie TTreeNodes: Add, AddChild, Insert, Delete, Clear, BeginUpdate/EndUpdate). In der DFM als lesbare Zeilenliste gespeichert. Nutzung: `N := Tree.Items.Add(nil, 'Projekte'); Tree.Items.AddChild(N, 'PPGlow');` |
| `MultiSelect` | `Boolean` | `False` | True: Mehrere Knoten sind gleichzeitig wählbar (Strg/Umschalt+Klick). |
| `ReadOnly` | `Boolean` | `False` | True: Knoten können nicht umbenannt werden (F2 und Klick auf den gewählten Knoten bleiben wirkungslos). |
| `RowSelect` | `Boolean` | `True` | Nur zur DFM-Kompatibilität mit TTreeView: Der Baum hebt immer die ganze Zeile hervor (Fluent-Standard). |
| `ShowButtons` | `Boolean` | `True` | True: Knoten mit Kindern zeigen den Auf-/Zuklapp-Pfeil. |
| `ShowLines` | `Boolean` | `False` | True: Verbindungslinien zwischen Eltern- und Kindknoten werden gezeichnet. |
| `ShowRoot` | `Boolean` | `True` | True: Auch die Knoten der obersten Ebene haben Einzug, Pfeil und Linien. |
| `ToolTips` | `Boolean` | `True` | Wie TTreeView: Abgeschnittene Knotentexte erscheinen als Hinweis, wenn die Maus darauf steht (braucht ShowHint = True). |

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

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnChange` | `TPPGTVChangedEvent` `(Sender: TObject; Node: TPPGTreeNode)` | Der gewählte Knoten hat sich geändert (auch bei Selected im Code, wie TTreeView). |
| `OnChanging` | `TPPGTVChangingEvent` `(Sender: TObject; Node: TPPGTreeNode; var AllowChange: Boolean)` | Bevor die Auswahl wechselt; AllowChange := False verhindert den Wechsel zu Node. |
| `OnChecked` | `TPPGTVChangedEvent` `(Sender: TObject; Node: TPPGTreeNode)` | Das Kästchen eines Knotens wurde umgeschaltet (Node = der umgeschaltete Knoten). |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. |
| `OnCollapsed` | `TPPGTVExpandedEvent` `(Sender: TObject; Node: TPPGTreeNode)` | Ein Knoten wurde zugeklappt. |
| `OnCollapsing` | `TPPGTVCollapsingEvent` `(Sender: TObject; Node: TPPGTreeNode; var AllowCollapse: Boolean)` | Bevor ein Knoten zuklappt; AllowCollapse := False verhindert es. |
| `OnCompare` | `TPPGTVCompareEvent` `(Sender: TObject; Node1, Node2: TPPGTreeNode; var Compare: Integer)` | Eigene Sortierung für AlphaSort: Compare < 0, wenn Node1 vor Node2 gehört, > 0 danach, 0 bei Gleichheit. Nutzung: `Compare := CompareDate(TDatei(Node1.Data).Datum, TDatei(Node2.Data).Datum);` |
| `OnCustomDrawNode` | `TPPGTVCustomDrawEvent` `(Sender: TObject; Canvas: TCanvas; Node: TPPGTreeNode; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean)` | Vor dem Zeichnen jedes Knotens: Style (Fill, TextColor, BorderColor, FontStyle) ändern oder mit DefaultDraw := False den Text selbst zeichnen. Pfeil, Linien und Kästchen zeichnet der Baum immer. Nutzung: `if Node.Level = 0 then Style.FontStyle := [fsBold];` |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. |
| `OnDeletion` | `TPPGTVExpandedEvent` `(Sender: TObject; Node: TPPGTreeNode)` | Ein Knoten wird gelöscht; guter Ort, um Node.Data freizugeben. Nutzung: `TObject(Node.Data).Free;` |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnEdited` | `TPPGTVEditedEvent` `(Sender: TObject; Node: TPPGTreeNode; var S: string)` | Umbenennen beendet: S enthält den neuen Text und kann noch geändert werden (z. B. getrimmt). |
| `OnEditing` | `TPPGTVEditingEvent` `(Sender: TObject; Node: TPPGTreeNode; var AllowEdit: Boolean)` | Bevor das Umbenennen (F2 bzw. EditText) beginnt; AllowEdit := False verhindert es für diesen Knoten. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnExpanded` | `TPPGTVExpandedEvent` `(Sender: TObject; Node: TPPGTreeNode)` | Ein Knoten wurde aufgeklappt. |
| `OnExpanding` | `TPPGTVExpandingEvent` `(Sender: TObject; Node: TPPGTreeNode; var AllowExpansion: Boolean)` | Bevor ein Knoten aufklappt (auch aus dem Code); AllowExpansion := False verhindert es. Ort für Lazy Loading: Knoten mit HasChildren = True hier mit Kindern füllen. Nutzung: `if Node.Count = 0 then LadeUnterordner(Node);` |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnNodeDrop` | `TPPGTVNodeDropEvent` `(Sender: TObject; Node, Target: TPPGTreeNode; Mode: TNodeAttachMode; var Allow: Boolean)` | Ein gezogener Knoten soll abgelegt werden (AllowReorder): Target und Mode nennen Ziel und Art (davor, danach, als Kind); Allow := False lehnt ab. |
| `OnScroll` | `TNotifyEvent` `(Sender: TObject)` | Die Scrollposition hat sich geändert (Rad, Leiste, Tastatur oder Code). Nutzung: Z. B. um eine Positionsanzeige zu aktualisieren: `lblZeile.Caption := IntToStr(Grid.TopRow);` |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGTreeView.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
