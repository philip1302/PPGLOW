# TPPGComboBox

Palette **PPGlow** - Unit `PPG.ComboBox` - Basis `TPPGCustomComboBox`

**Vorbild:** TComboBox, TMS TAdvComboBox

## Unterschiede und Hinweise

- Ereignisse wie `TComboBox`: `OnClick`, dann `OnSelect`; nur ohne `OnSelect` kommt `OnChange`.
- Das Mausrad ändert die geschlossene Combo nicht.
- `ItemHeight` ist eine Mindesthöhe (alte DFMs speichern 13).
- Eigene Aufklappliste (`PPG.Popup`) mit `ItemsEx` (Bild, Detail, Plakette, Markup) und `FilterMode`; Filtern ersetzt AutoComplete, ohne Treffer schließt die Liste.
- Seit Phase 20e auf der gemeinsamen Aufklapp-Basis (`TPPGCustomDropDownField`) wie ColorPicker und CheckComboBox: gleiche Maus-, Tastatur- und Screenreader-Regeln. Anders als dort sperrt `ReadOnly` das Aufklappen nicht, und bei offener Liste gehen Zeichen weiter ins Edit.

## Anpassung

- `Styles` für die Aufklappliste (Zebra, Auswahl, Hover) und `OnCustomDrawItem`.
- `RoundedCorners` für zusammengesetzte Eingabegruppen.

## Verhalten (aus dem Quelltext)

TPPGComboBox - Auswahlfeld mit eigener Aufklappliste in der Optik des Presets.

- Basis TPPGCustomDropDownField (seit Phase 20e, wie ColorPicker und CheckComboBox): csDropDown nutzt das native Edit (frei editierbar, AutoComplete), csDropDownList blendet es aus - dann ist das Feld selbst Tabstopp und zeichnet den Eintrag.
- Die Liste ist ein TPPGPopupList (PPG.Popup): ohne Aktivierung, die Combo behaelt Fokus und Tastatur und haelt die Maus per SetCapture (alles in der Basis). Klick ausserhalb, Fokusverlust, Capture-Verlust und Esc schliessen ohne Uebernahme; Klick auf einen Eintrag und Enter uebernehmen.
- Anders als die Basis: Zeichen gehen auch bei offener Liste ins Edit (FieldKeyPress), Pos1/Ende im editierbaren Stil bewegen den Cursor, und ReadOnly verhindert das Aufklappen nicht (TComboBox kennt kein ReadOnly).
- Ereignisse wie TComboBox: Auswahl durch den Anwender loest OnClick und danach OnSelect aus - ist OnSelect nicht zugewiesen, stattdessen OnChange. Tippen im Edit loest OnChange aus. ItemIndex/Text im Code setzen loest (wie bei TComboBox) kein Ereignis aus.
- Tastatur: Alt+Unten/Alt+Oben/F4 klappen auf/zu; geschlossen waehlen Oben/Unten/Bild/(Pos1/Ende bei csDropDownList) direkt; offen bewegen sie die Hervorhebung, Enter uebernimmt, Esc verwirft. Tippsuche ueber die Anfangsbuchstaben bei csDropDownList.
- Migration: Property-Namen von TComboBox (Style, Items, ItemIndex, DropDownCount, Sorted, AutoComplete, ...). csSimple wird wie csDropDown, csOwnerDraw* wie csDropDownList behandelt (Owner-Draw gibt es nicht). ItemHeight ist eine Mindesthoehe der Zeilen (0 = aus der Schrift).

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `RoundedCorners` | `TPPGCorners` | `[pcTopLeft, pcTopRight, pcBottomRight, pcBottomLeft]` | Welche Ecken gerundet sind; die übrigen werden eckig. Für Button-Gruppen und Segment-Schalter: linker Button [pcTopLeft, pcBottomLeft], mittlere [], rechter [pcTopRight, pcBottomRight]. Menge aus: `pcTopLeft`, `pcTopRight`, `pcBottomRight`, `pcBottomLeft`. Nutzung: `PPGButton2.RoundedCorners := [];` |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). |
| `ItemsEx` | [TPPGItems](types/TPPGItems.md) |  | Reiche Einträge mit Bild (aus Images), Detailzeile, Plakette und Markup. Sind welche vorhanden, sind sie die Einträge der Liste. Nutzung: `with ComboBox1.ItemsEx.Add('Berlin', 2) do Detail := '3,7 Mio. Einwohner';` |
| `FilterMode` | `TPPGFilterMode` | `fmNone` | Filtern beim Tippen (nur Style = csDropDown): fmNone zeigt immer alle Einträge, fmPrefix nur die mit diesem Anfang, fmContains alle, die den Text irgendwo enthalten. Die Liste klappt dabei auf. Werte: `fmNone`, `fmPrefix`, `fmContains`. Nutzung: Für lange Listen: `ComboBox1.FilterMode := fmContains;` |
| `Styles` | [TPPGListStyles](types/TPPGListStyles.md) |  | Bereiche der Aufklappliste einzeln gestalten: Auswahl (aktueller Wert), Zebra-Zeilen, Hover, Gruppenkopf, Detailzeile. Nicht gesetzte Farben kommen aus dem Preset. Nutzung: `ComboBox1.Styles.AlternateRow.Color := $00FAF7F2;` |
| `ShowClearButton` | `Boolean` | `False` | True: Ein „×"-Knopf im Feld löscht den Text (nur sichtbar, wenn Text vorhanden und das Feld bearbeitbar ist). |
| `TextHint` | `string` |  | Platzhaltertext im leeren Feld (z. B. „Suchen …"). Nutzung: `Edit1.TextHint := 'E-Mail-Adresse';` |
| `UseSystemContextMenu` | `Boolean` | `False` | True: Rechtsklick zeigt das native Windows-Menü des Edits statt des PPGlow-Menüs (Rückgängig, Ausschneiden, Kopieren, Einfügen, Löschen, Alles markieren; übersetzt und im Preset-Stil). |
| `TextHintVisibleOnFocus` | `Boolean` | `False` | True: Der Platzhalter bleibt sichtbar, bis getippt wird; False: er verschwindet schon beim Fokus. |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Ergebnis einer Prüfung: pvsNone (neutral), pvsValid (grüner Rand), pvsWarning (gelb), pvsError (rot). Die Farben kommen aus den Signal-Tokens; ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if not IstMail(Edit1.Text) then begin Edit1.ValidationState := pvsError; Edit1.ValidationHint := 'Keine gültige Adresse'; end;` |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState; erscheint als Tooltip und wird vom Screenreader vorgelesen. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `AutoCloseUp` | `Boolean` | `False` | True: Springt die Tippsuche bei offener Liste auf einen Eintrag, wird er sofort übernommen und die Liste geschlossen. |
| `AutoComplete` | `Boolean` | `True` | True: Bei Style = csDropDown ergänzt das Feld den getippten Anfang zum ersten passenden Eintrag (der Rest ist markiert und wird beim Weitertippen ersetzt). |
| `AutoDropDown` | `Boolean` | `False` | True: Die Liste klappt beim Tippen automatisch auf. |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen (z. B. eingebettet in eigene Flächen). |
| `CharCase` | `TEditCharCase` | `ecNormal` | Erzwingt Groß- oder Kleinschreibung der Eingabe (ecNormal, ecUpperCase, ecLowerCase). |
| `DropDownCount` | `Integer` | `PPGDefaultDropDownCount` | Sichtbare Zeilen der Aufklappliste, danach wird gescrollt (mindestens 1). |
| `DropDownWidth` | `Integer` | `0` | Breite der Aufklappliste in logischen Pixeln; 0 = so breit wie das Feld. Nützlich für lange Einträge in schmalen Feldern. |
| `ItemHeight` | `Integer` | `0` | Mindesthöhe einer Listenzeile in logischen Pixeln (0..1000); 0 = aus der Schrift. Einträge mit Detailzeile werden entsprechend höher. |
| `Items` | `TStrings` |  | Die Einträge als einfache Textliste (wie TComboBox.Items). Sind ItemsEx-Einträge vorhanden, enthält Items deren Texte. |
| `ItemIndex` | `Integer` | `-1` | Index des gewählten Eintrags; -1 = keiner. Setzen aus Code löst (wie bei TComboBox) kein Ereignis aus. Nutzung: `ComboBox1.ItemIndex := ComboBox1.Items.IndexOf('Berlin');` |
| `MaxLength` | `Integer` | `0` | Höchstzahl der Zeichen; 0 = unbegrenzt. |
| `Sorted` | `Boolean` | `False` | True: Die Einträge werden alphabetisch sortiert gehalten. |
| `Style` | `TComboBoxStyle` | `csDropDown` | csDropDown: freie Eingabe im Feld plus Liste (mit AutoComplete und FilterMode); csDropDownList: nur Auswahl aus der Liste, Tippen springt per Anfangsbuchstaben. csSimple verhält sich wie csDropDown, csOwnerDraw* wie csDropDownList (Zeichnen über OnCustomDrawItem). |
| `TabStop` | `Boolean` | `True` | True: Das Feld ist mit Tab erreichbar. |
| `Text` | `string` |  | Der angezeigte bzw. eingegebene Text. Bei csDropDownList der Text des gewählten Eintrags. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). |
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
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Text wurde geändert (Tippen, Einfügen, Code). |
| `OnCustomDrawItem` | `TPPGCustomDrawItemEvent` `(Sender: TObject; Canvas: TCanvas; Index: Integer; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean)` | Vor dem Zeichnen jedes Eintrags der Aufklappliste: Style (Fill, TextColor, BorderColor, FontStyle) ändern oder mit DefaultDraw := False selbst auf Canvas zeichnen. Nutzung: `if Index = 0 then Style.FontStyle := [fsBold];` |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
| `OnCloseUp` | `TNotifyEvent` `(Sender: TObject)` | Die Aufklappliste wurde geschlossen (mit oder ohne Übernahme). |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnDropDown` | `TNotifyEvent` `(Sender: TObject)` | Die Liste klappt gleich auf; hier lassen sich Einträge noch nachladen. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnSelect` | `TNotifyEvent` `(Sender: TObject)` | Der Anwender hat einen Eintrag gewählt (Klick, Enter, Pfeiltasten im geschlossenen Feld). Kommt nach OnClick; ist OnSelect nicht zugewiesen, wird stattdessen OnChange ausgelöst. Nicht bei ItemIndex aus Code. |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGComboBox.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
