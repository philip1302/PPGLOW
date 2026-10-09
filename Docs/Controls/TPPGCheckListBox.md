# TPPGCheckListBox

Palette **PPGlow** - Unit `PPG.CheckListBox` - Basis `TPPGCustomCheckListBox`

**Vorbild:** TCheckListBox

## Unterschiede und Hinweise

- Kästchen im Preset-Stil; `Header[]` macht Zeilen zu Überschriften (ohne Kästchen, nicht wählbar).
- `Checked[]`/`State[]` im Code lösen kein Ereignis aus; der Anwender löst `OnClickCheck` aus.
- UI Automation: zusätzlich Toggle-Muster je Eintrag.

## Anpassung

- `Styles` und `OnCustomDrawItem` wie `TPPGListBox`.

## Verhalten (aus dem Quelltext)

TPPGCheckListBox - ListBox mit Kaestchen, DFM-kompatibel zu TCheckListBox.

Die Kaestchen zeichnet IPPGIndicatorRenderer des Presets (wie TPPGCheckBox).
Zustand pro Zeile: bei Items in der Huelle der Zeile (wandert beim
Sortieren/Verschieben mit), bei ItemsEx in TPPGItem.Checked, virtuell ueber
OnGetItem (Data.Checked) und OnSetChecked.

Bedienung wie TCheckListBox: Klick auf das Kaestchen oder Leertaste schaltet
um (aus -> an -> gemischt, wenn AllowGrayed), danach OnClickCheck. Setzen
im Code (Checked[], State[], CheckAll) loest kein Ereignis aus.
Header[] macht eine Zeile zur Ueberschrift (ohne Kaestchen, nicht waehlbar).

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). |
| `ItemsEx` | [TPPGItems](types/TPPGItems.md) |  | Einträge mit allen Angaben (Text, Detailzeile, Bild, Plakette, Gruppe, Farbe, Kästchen). Sobald ItemsEx Einträge hat, ist es die Quelle statt Items. Nutzung: `with List.ItemsEx.Add('Posteingang', 4) do begin Badge := '12'; Group := 'Favoriten'; end;` |
| `AllowMarkup` | `Boolean` | `False` | True: Texte der Einträge dürfen Mini-Markup enthalten (<b>, <i>, <u>, <color=...>). Nutzung: `List.AllowMarkup := True; List.ItemsEx.Add('<b>Wichtig</b> heute');` |
| `AllowReorder` | `Boolean` | `False` | True: Einträge lassen sich mit der Maus umsortieren (Ziehen) bzw. mit Strg+Pfeiltasten verschieben; danach kommt OnReorder. |
| `Styles` | [TPPGListStyles](types/TPPGListStyles.md) |  | Bereiche der Liste einzeln gestalten: Selection, SelectionInactive (Auswahl ohne Fokus), AlternateRow (Zebra), HotItem (Maus darüber), GroupHeader, Detail (zweite Zeile). Nicht gesetzte Farben kommen aus dem Preset. Nutzung: `List.Styles.AlternateRow.Color := $00FAF7F2;` |
| `ScrollBarMode` | `TPPGScrollBarMode` | `sbmAuto` | Wann die Scrollleisten erscheinen: sbmAuto (bei Bedarf, als schmale Overlay-Leiste), sbmAlways (immer), sbmNever (nie; Scrollen nur per Rad, Tastatur oder Code). Werte: `sbmAuto`, `sbmAlways`, `sbmNever`. |
| `SmoothScrolling` | `Boolean` | `True` | True: Scrollen per Rad und Tastatur gleitet weich statt sprunghaft. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `AllowGrayed` | `Boolean` | `False` | True: Ein Klick schaltet aus → an → gemischt (cbGrayed), z. B. für „teilweise". |
| `AutoComplete` | `Boolean` | `True` | True: Tippen springt zum ersten Eintrag mit diesen Anfangsbuchstaben (wie TListBox.AutoComplete). |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen. |
| `Columns` | `Integer` | `0` | Mehrspaltig wie TListBox.Columns: Die Einträge laufen von oben nach unten und dann in die nächste Spalte; so viele Spalten sind gleichzeitig sichtbar, weitere erreicht man waagerecht (Bildlauf, Pfeil links/rechts springt eine Spalte). 0 = einspaltig (0..1000). Mit Gruppen oder Detailzeilen bleibt die Liste einspaltig, Umsortieren per Ziehen ist dann aus. Nutzung: `ListBox1.Columns := 3;` |
| `Flat` | `Boolean` | `True` | True: Kästchen im Stil des Presets. False: natives Windows-Kästchen (mit aktivem VCL-Style dessen Kästchen, ohne Themes das klassische 3D-Kästchen). Im Hochkontrast immer Preset-Stil. |
| `HeaderColor` | `TColor` | `clInfoText` | Textfarbe der Überschriften (Header[]). Die Vorgabe clInfoText bedeutet „wie das Preset“; jede andere Farbe färbt die Überschriften, solange Styles.GroupHeader.TextColor nichts Eigenes setzt. Gilt im Hellen. Nutzung: `CheckListBox1.HeaderColor := clNavy;` |
| `HeaderBackgroundColor` | `TColor` | `clInfoBk` | Hintergrund der Überschriften (Header[]). Die Vorgabe clInfoBk bedeutet „wie das Preset“; jede andere Farbe füllt die Überschriftszeilen, solange Styles.GroupHeader.Color nichts Eigenes setzt. Gilt im Hellen. Nutzung: `CheckListBox1.HeaderBackgroundColor := $00F0E6DC;` |
| `IntegralHeight` | `Boolean` | `False` | True: Die Höhe wird auf ganze Zeilen abgerundet (mindestens eine), damit unten keine angeschnittene Zeile steht – beim Setzen der Höhe, nach Schriftwechsel und nach dem Laden. Nicht bei Align = alClient, alLeft oder alRight. |
| `ItemHeight` | `Integer` | `0` | Zeilenhöhe in logischen Pixeln; 0 = aus der Schrift berechnet (mit Detailzeile entsprechend höher). |
| `Items` | `TStrings` |  | Einträge als Textliste wie bei TListBox (Objects[] für eigene Daten). Quelle der Liste, solange ItemsEx leer ist und Style nicht virtuell ist. Nutzung: `List.Items.AddObject('Anna', Kunde);` |
| `MultiSelect` | `Boolean` | `False` | True: Mehrere Einträge sind gleichzeitig wählbar (Art über ExtendedSelect); abfragen über Selected[] und SelCount. |
| `ExtendedSelect` | `Boolean` | `True` | Nur mit MultiSelect: True = Mehrfachauswahl wie im Explorer (Umschalt für Bereiche, Strg für einzelne); False = jeder Klick schaltet einen Eintrag um. |
| `ScrollWidth` | `Integer` | `0` | Breite in logischen Pixeln für waagerechten Bildlauf (0..100000): Ist sie größer als die Liste, werden die Zeilen so breit und die Liste lässt sich waagerecht scrollen. 0 = kein waagerechter Bildlauf. Nutzung: Für lange Einträge: `ListBox1.ScrollWidth := 600;` |
| `ToolTips` | `Boolean` | `True` | Wie TTreeView.ToolTips: Ein abgeschnittener Eintrag erscheint ganz als Hinweis, wenn die Maus darauf steht. Nur ohne eigenen Hint; braucht ShowHint = True. |
| `Sorted` | `Boolean` | `False` | True: Items werden alphabetisch sortiert gehalten; neue Einträge landen an ihrer Sortierposition. |
| `Style` | `TListBoxStyle` | `lbStandard` | Datenquelle und Zeichnen wie TListBox: lbStandard, Owner-Draw (lbOwnerDrawFixed, lbOwnerDrawVariable) oder virtuell (lbVirtual, lbVirtualOwnerDraw: Count + OnGetItem bzw. OnData, Daten bleiben beim Anwender). |
| `TabWidth` | `Integer` | `0` | Tabulatorabstand in Dialogeinheiten (1/4 der mittleren Zeichenbreite, wie LB_SETTABSTOPS), 0..1000: Tabzeichen (#9) im Text springen zum nächsten Vielfachen. 0 = Tabs werden nicht aufgelöst. Nicht mit Markup und nicht bei Rechts-nach-links. Nutzung: `ListBox1.TabWidth := 64; ListBox1.Items.Add('Müller'#9'Berlin');` |
| `ItemIndex` | `Integer` | `-1` | Index des gewählten bzw. fokussierten Eintrags; -1 = keiner. Nutzung: `List.ItemIndex := List.Items.IndexOf('Berlin');` |

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
| `OnClickCheck` | `TNotifyEvent` `(Sender: TObject)` | Der Anwender hat ein Kästchen umgeschaltet (Klick, Leertaste, Screenreader). Setzen von Checked[] oder State[] im Code löst es nicht aus. Nutzung: `lblAnzahl.Caption := IntToStr(ZaehleHaken);` |
| `OnItemCheck` | `TPPGItemCheckEvent` `(Sender: TObject; Index: Integer)` | Der Anwender hat das Kästchen eines Eintrags umgeschaltet; Index ist der Eintrag. Wie OnClickCheck, aber mit Index (gleiche Signatur wie bei CheckComboBox). Nutzung: `procedure TForm1.List1ItemCheck(Sender: TObject; Index: Integer); begin Caption := List1.Items[Index]; end;` |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnData` | `TLBGetDataEvent` `(Control: TWinControl; Index: Integer; var Data: string)` | Virtueller Stil (lbVirtual) wie bei TListBox: liefert den Text der Zeile Index in den var-Parameter Data. Für mehr Angaben OnGetItem verwenden. Nutzung: `List.Style := lbVirtual; List.Count := 1000000;` und in OnData `Data := 'Zeile ' + IntToStr(Index);` |
| `OnDataFind` | `TLBFindDataEvent` `(Control: TWinControl; FindString: string): Integer` | Virtueller Stil: Tippsuche bzw. IndexOf fragen nach dem Index des Eintrags mit diesem Text; die Funktion liefert ihn als Ergebnis (-1 = nicht gefunden). |
| `OnDataObject` | `TLBGetDataObjectEvent` `(Control: TWinControl; Index: Integer; var DataObject: TObject)` | Virtueller Stil: liefert das Objekt (Objects[]) der Zeile Index. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnDrawItem` | `TDrawItemEvent` `(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState)` | Owner-Draw wie TListBox (Style = lbOwnerDrawFixed/Variable bzw. lbVirtualOwnerDraw): zeichnet den Eintrag auf Canvas; Hintergrund und Auswahl hat das Preset schon gezeichnet. Für Farbänderungen ohne eigenes Zeichnen ist OnCustomDrawItem einfacher. |
| `OnCustomDrawItem` | `TPPGCustomDrawItemEvent` `(Sender: TObject; Canvas: TCanvas; Index: Integer; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean)` | Vor dem Zeichnen jedes Eintrags: Style (Fill, TextColor, BorderColor, FontStyle) für diesen Eintrag ändern oder mit DefaultDraw := False selbst auf Canvas zeichnen. State enthält idsSelected, idsFocused, idsHot usw. Nutzung: `if Pos('!', List.ItemsEx[Index].Text) > 0 then Style.TextColor := clRed;` |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnGetItem` | `TPPGGetItemEvent` `(Sender: TObject; Index: Integer; var Data: TPPGItemData)` | Virtuell mit allen Angaben: füllt Data (Text, Detail, Bild, Plakette, Kästchen, Farben) für die Zeile Index. Anzahl über Count. Nutzung: `Data.Text := Mails[Index].Betreff; Data.Detail := Mails[Index].Absender;` |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |
| `OnMeasureItem` | `TMeasureItemEvent` `(Control: TWinControl; Index: Integer; var Height: Integer)` | Bei Style = lbOwnerDrawVariable: liefert die Höhe der Zeile Index in den var-Parameter Height. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnReorder` | `TPPGReorderEvent` `(Sender: TObject; FromIndex, ToIndex: Integer; var Allow: Boolean)` | Ein Eintrag wurde per Ziehen oder Tastatur verschoben (alter und neuer Index). |
| `OnScroll` | `TNotifyEvent` `(Sender: TObject)` | Die Scrollposition hat sich geändert (Rad, Leiste, Tastatur oder Code). Nutzung: Z. B. um eine Positionsanzeige zu aktualisieren: `lblZeile.Caption := IntToStr(Grid.TopRow);` |
| `OnSetChecked` | `TPPGSetCheckedEvent` `(Sender: TObject; Index: Integer; Value: TCheckBoxState)` | Virtueller Stil (Style = lbVirtual): Der Anwender hat das Kästchen der Zeile Index auf Value umgeschaltet; die Anwendung speichert den Zustand selbst (und liefert ihn in OnGetItem über Data.Checked zurück). |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGCheckListBox.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
