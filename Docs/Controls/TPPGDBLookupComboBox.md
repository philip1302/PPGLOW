# TPPGDBLookupComboBox

Palette **PPGlow DB** - Unit `PPG.DB.Lookup` - Basis `TPPGDBComboBox`

**Vorbild:** TDBLookupComboBox

## Unterschiede und Hinweise

- `ListField` mit mehreren Feldern (`Ort;PLZ`): das erste ist der Text, die weiteren erscheinen als Detailzeile.
- Die Liste wird einmal vollständig gelesen (Lesezeichen bleibt); für sehr große Tabellen die Abfrage filtern.
- Nachschlagefelder (`FieldKind = fkLookup`) als `DataField` werden nicht unterstützt – `ListSource`/`KeyField`/`ListField` direkt setzen.

## Beispiel

```pascal
PPGDBLookupComboBox1.ListSource := OrteSource;
PPGDBLookupComboBox1.KeyField := 'ID';
PPGDBLookupComboBox1.ListField := 'Ort;PLZ';
PPGDBLookupComboBox1.DataSource := KundenSource;
PPGDBLookupComboBox1.DataField := 'OrtID';
```

## Verhalten (aus dem Quelltext)

TPPGDBLookupComboBox - Auswahl eines Schluessels aus einer zweiten
Datenmenge (Phase 9c), wie TDBLookupComboBox.

- ListSource/KeyField/ListField: die Liste kommt aus ListSource.DataSet; angezeigt wird das erste Feld aus ListField, weitere Felder (durch Semikolon getrennt) erscheinen als Detailzeile (ItemsEx).
- DataSource/DataField: das Schluesselfeld der Haupt-Datenmenge. Auswahl schreibt KeyField des gewaehlten Eintrags hinein.
- Die Liste wird beim Oeffnen bzw. Aendern der Listen-Datenmenge einmal vollstaendig gelesen (DisableControls, Lesezeichen wird wiederhergestellt). Fuer sehr grosse Nachschlage-Tabellen ist ein Filter in der Abfrage der bessere Weg.
- Immer csDropDownList: Tippen sucht wie bei der ComboBox (Tippsuche).
- Nachschlagefeld (TField.FieldKind = fkLookup) als DataField (Audit 4b): geschrieben wird sein Schluesselfeld, Liste, KeyField und ListField kommen aus dem Feld, solange sie nicht gesetzt sind. Mehrfachschluessel ('A;B') werden nicht unterstuetzt und als Warnung gemeldet.
- NullValueKey (wie TDBLookupComboBox): diese Taste leert den Wert.
- Aendert sich die Listen-Datenmenge, wird die Liste gebuendelt neu gelesen (eine gepostete Nachricht fuer mehrere Aenderungen) bzw. spaetestens, wenn sie gebraucht wird.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `KeyField` | `string` |  | Schlüsselfeld der Listen-Datenmenge (ListSource); sein Wert wird in DataField geschrieben. |
| `ListField` | `string` |  | Anzuzeigende Felder der Listen-Datenmenge; das erste ist der Eintrag, weitere (durch Semikolon getrennt) erscheinen als Detailzeile. Nutzung: `Lookup1.ListSource := dsKunden; Lookup1.KeyField := 'ID'; Lookup1.ListField := 'Name;Ort';` |
| `ListSource` | `TDataSource` |  | Datenquelle der Nachschlage-Tabelle. Ihre Datenmenge wird beim Öffnen einmal vollständig gelesen; für sehr große Tabellen vorher in der Abfrage filtern. |
| `NullValueKey` | `TShortCut` | `0` | Tastenkürzel, das den Wert leert und Null ins Feld schreibt (z. B. Entf oder Strg+Entf); 0 = keines. Wie TDBLookupComboBox.NullValueKey. Nutzung: `Lookup1.NullValueKey := ShortCut(VK_DELETE, [ssCtrl]);` |
| `Items` | `TStrings` |  | Die Einträge als einfache Textliste (wie TComboBox.Items). Sind ItemsEx-Einträge vorhanden, enthält Items deren Texte. |
| `ItemsEx` | [TPPGItems](types/TPPGItems.md) |  | Reiche Einträge mit Bild (aus Images), Detailzeile, Plakette und Markup. Sind welche vorhanden, sind sie die Einträge der Liste. Nutzung: `with ComboBox1.ItemsEx.Add('Berlin', 2) do Detail := '3,7 Mio. Einwohner';` |
| `Style` | `TComboBoxStyle` | `csDropDownList` | csDropDown: freie Eingabe im Feld plus Liste (mit AutoComplete und FilterMode); csDropDownList: nur Auswahl aus der Liste, Tippen springt per Anfangsbuchstaben. csSimple verhält sich wie csDropDown, csOwnerDraw* wie csDropDownList (Zeichnen über OnCustomDrawItem). |
| `ShowRequired` | `Boolean` | `False` | True: Ist das Datenfeld ein Pflichtfeld (TField.Required), zeigt das leere Feld hinter dem Platzhalter (TextHint) ein Sternchen, ohne TextHint nur das Sternchen. So ist die Pflicht sichtbar, bevor der Validator meldet. |
| `DataField` | `string` |  | Feld, das angezeigt und geschrieben wird. Bei TPPGDBComboBox der gewählte bzw. eingegebene Text; bei TPPGDBLookupComboBox das Schlüsselfeld der Haupt-Datenmenge (bekommt KeyField des gewählten Eintrags). |
| `DataSource` | `TDataSource` |  | Datenquelle mit der Datenmenge, aus der DataField kommt. |
| `ReadOnly` | `Boolean` | `False` | True: Der Text kann gelesen, markiert und kopiert, aber nicht geändert werden. Die Optik bestimmt ReadOnlyStyle. |
| `Text` | `string` |  | Der angezeigte bzw. eingegebene Text. Bei csDropDownList der Text des gewählten Eintrags. |
| `ItemIndex` | `Integer` | `-1` | Index des gewählten Eintrags; -1 = keiner. Setzen aus Code löst (wie bei TComboBox) kein Ereignis aus. Nutzung: `ComboBox1.ItemIndex := ComboBox1.Items.IndexOf('Berlin');` |
| `RoundedCorners` | `TPPGCorners` | `[pcTopLeft, pcTopRight, pcBottomRight, pcBottomLeft]` | Welche Ecken gerundet sind; die übrigen werden eckig. Für Button-Gruppen und Segment-Schalter: linker Button [pcTopLeft, pcBottomLeft], mittlere [], rechter [pcTopRight, pcBottomRight]. Menge aus: `pcTopLeft`, `pcTopRight`, `pcBottomRight`, `pcBottomLeft`. Nutzung: `PPGButton2.RoundedCorners := [];` |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). |
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
| `MaxLength` | `Integer` | `0` | Höchstzahl der Zeichen; 0 = unbegrenzt. |
| `Sorted` | `Boolean` | `False` | True: Die Einträge werden alphabetisch sortiert gehalten. |
| `TabStop` | `Boolean` | `True` | True: Das Feld ist mit Tab erreichbar. |

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

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Text wurde geändert (Tippen, Einfügen, Code). |
| `OnCustomDrawItem` | `TPPGCustomDrawItemEvent` `(Sender: TObject; Canvas: TCanvas; Index: Integer; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean)` | Vor dem Zeichnen jedes Eintrags der Aufklappliste: Style (Fill, TextColor, BorderColor, FontStyle) ändern oder mit DefaultDraw := False selbst auf Canvas zeichnen. Nutzung: `if Index = 0 then Style.FontStyle := [fsBold];` |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. |
| `OnCloseUp` | `TNotifyEvent` `(Sender: TObject)` | Die Aufklappliste wurde geschlossen (mit oder ohne Übernahme). |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. |
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
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBLookupComboBox.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
