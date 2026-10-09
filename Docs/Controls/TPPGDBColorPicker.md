# TPPGDBColorPicker

Palette **PPGlow DB** - Unit `PPG.DB.Fields` - Basis `TPPGColorPicker`

**Vorbild:** DB-Variante von `TPPGColorPicker` (wie `TDBEdit`)

## Unterschiede und Hinweise

- Bindet sich über `DataSource`/`DataField` an ein Feld. Die Anbindung ist für alle Phase-12-Felder dieselbe (`TPPGDBValueBinding`, Schnittstelle `IPPGFieldValue`).
- Null im Feld wird zum leeren Control, und ein leeres Control schreibt Null.
- Tippen bzw. Auswählen setzt den Datensatz in Bearbeitung. Ist das nicht möglich, kommt der Feldwert zurück.
- Beim Verlassen und bei einem Post (auch über einen Navigator) wird geschrieben. Eine laufende Eingabe wird vorher übernommen.
- Fehler stehen am Feld (`ValidationState`), es erscheint kein Dialog.
- Esc setzt die Bearbeitung zurück.

## Verhalten (aus dem Quelltext)

DB-Varianten der Eingabefelder aus Phase 12 (12g): TPPGDBMaskEdit,
TPPGDBNumberEdit, TPPGDBColorPicker, TPPGDBCheckComboBox, TPPGDBTagEdit.

Alle binden sich ueber IPPGFieldValue (PPG.Controls.Field) an das Feld -
eine Anbindung (TPPGDBValueBinding) statt einer je Feldtyp:
- Datensatz wechselt: Null -> FieldClear, sonst SetFieldValue (still, ohne OnChange). Text-Modus (Maske, Auswahl, Tags) ueber Field.Text, sonst Field.Value (Zahl, Farbe).
- Anwender aendert: Datensatz in den Bearbeiten-Modus (EditByUser), dann Modified; geht das nicht, wird der Feldwert wieder angezeigt.
- Schreiben (UpdateData, auch beim Post ueber einen Navigator): eine laufende Eingabe wird vorher uebernommen (Zahl rechnen, Tag anlegen).
- Verlassen: UpdateRecord; ein Fehler steht am Feld (ValidationState), kein Dialog (PPGDBCommitField aus Phase 9).
- TPPGDBMaskEdit uebernimmt Field.EditMask, wenn es keine eigene Maske hat.
- TPPGDBNumberEdit: AllowNull ist Vorgabe (Null ist nicht 0).
- Auswahl und Tags speichern als getrennten Text (Delimiter).

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `ShowRequired` | `Boolean` | `False` | True: Ist das Datenfeld ein Pflichtfeld (TField.Required), zeigt das leere Feld hinter dem Platzhalter (TextHint) ein Sternchen, ohne TextHint nur das Sternchen. So ist die Pflicht sichtbar, bevor der Validator meldet. |
| `DataField` | `string` |  | Ganzzahl-Feld mit der Farbe als TColor-Wert; Null bzw. leer = „Keine" (clNone). |
| `DataSource` | `TDataSource` |  | Datenquelle mit der Datenmenge, aus der DataField kommt. |
| `ReadOnly` | `Boolean` | `False` | True: Der Text kann gelesen, markiert und kopiert, aber nicht geändert werden. Die Optik bestimmt ReadOnlyStyle. |
| `Selected` | `TColor` | `clBlack` | Die gewählte Farbe. clNone = „Keine", clDefault = „Standard". Setzen aus Code löst kein OnChange aus. Nutzung: `Panel1.Color := PPGColorPicker1.Selected;` |
| `Style` | `TColorBoxStyle` | `[cbStandardColors, cbExtendedColors, cbCustomColor, cbPrettyNames]` | Abschnitte des Popups wie bei TColorBox: cbStandardColors (16 Grundfarben), cbExtendedColors (weitere Farben), cbSystemColors (clBtnFace usw.), cbIncludeNone („Keine"), cbIncludeDefault („Standard"), cbCustomColor (Schaltfläche „Weitere Farben …" mit HSV-Feld und Hex-Eingabe), cbPrettyNames (lesbare Namen). Nutzung: `PPGColorPicker1.Style := [cbStandardColors, cbIncludeNone, cbCustomColor];` |
| `ShowThemeColors` | `Boolean` | `True` | True: Das Popup zeigt oben die Designfarben des Presets (Akzent, Signalfarben, Diagrammpalette), damit gewählte Farben zum Theme passen. |
| `RecentColors` | `TStrings` |  | Zuletzt benutzte Farben als Hexwerte „#RRGGBB", die neueste zuerst. Wird beim Wählen automatisch fortgeschrieben und in der DFM gespeichert; kann zum Speichern in einer Einstellung gelesen und wieder gesetzt werden. Nutzung: `Ini.WriteString('Farben', 'Zuletzt', PPGColorPicker1.RecentColors.CommaText);` |
| `MaxRecent` | `Integer` | `8` | Wie viele zuletzt benutzte Farben gemerkt und als eigener Abschnitt gezeigt werden (0..32; 0 = kein Abschnitt). |
| `ShowHex` | `Boolean` | `False` | True: Das Feld zeigt den Hexwert („#1E90FF") statt des Farbnamens. |
| `NoneColorColor` | `TColor` | `clBlack` | Füllung des Farbfelds für „Keine“ (clNone) im Feld und im Popup, wie TColorBox.NoneColorColor. Die Vorgabe clBlack zeigt das Feld leer mit roter Diagonale (Preset-Optik); jede andere Farbe füllt es (die Diagonale bleibt). Nutzung: `ColorPicker1.NoneColorColor := clWhite;` |
| `DefaultColorColor` | `TColor` | `clBlack` | Farbe, mit der das Feld „Standard" (Selected = clDefault, mit cbIncludeDefault im Style) dargestellt wird. |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Ergebnis einer Prüfung: pvsNone (neutral), pvsValid (grüner Rand), pvsWarning (gelb), pvsError (rot). Die Farben kommen aus den Signal-Tokens; ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if not IstMail(Edit1.Text) then begin Edit1.ValidationState := pvsError; Edit1.ValidationHint := 'Keine gültige Adresse'; end;` |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState; erscheint als Tooltip und wird vom Screenreader vorgelesen. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen (z. B. eingebettet in eigene Flächen). |
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
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Text wurde geändert (Tippen, Einfügen, Code). |
| `OnCloseUp` | `TNotifyEvent` `(Sender: TObject)` | Die Aufklappliste wurde geschlossen (mit oder ohne Auswahl). |
| `OnDropDown` | `TNotifyEvent` `(Sender: TObject)` | Die Aufklappliste öffnet sich gleich; hier kann sie noch befüllt werden. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBColorPicker.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
