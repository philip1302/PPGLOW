# TPPGDatePicker

Palette **PPGlow** - Unit `PPG.DatePicker` - Basis `TPPGCustomDatePicker`

**Vorbild:** TDateTimePicker (Kind = dtkDate)

## Unterschiede und Hinweise

- Eingabe nur Ziffern und Datumstrenner (Kurzformat); Prüfung beim Verlassen/Enter, Fehler als `ValidationState`.
- `Kind`, `DateMode`, `ParseInput` werden nur gelesen/gespeichert. Leeres Datum nur mit `ShowCheckbox`.
- Für `Kind = dtkTime` gibt es `TPPGTimePicker`.

## Anpassung

- `Styles` und `OnCustomDrawDay` gelten für den aufgeklappten Kalender.

## Verhalten (aus dem Quelltext)

TPPGDatePicker - Datumsfeld mit Kalender-Popup (Phase 7b).

- Basis TPPGCustomField: natives Edit fuer die Eingabe, Kalender-Button rechts, optional ein Kontrollkaestchen links (ShowCheckbox/Checked wie TDateTimePicker: ohne Haken gilt "kein Datum").
- Eingabe: Ziffern und Datumstrenner; Oben/Unten aendern den Tag (Strg: Monat). Beim Verlassen bzw. Enter wird geprueft: gueltig = uebernehmen (OnChange), ungueltig = ValidationState pvsError, der Text bleibt zum Korrigieren stehen. Grenzen MinDate/MaxDate.
- Popup: TPPGCalendar in einem Popup ohne Aktivierung. Das Feld behaelt den Fokus und leitet Pfeile, Bild, Pos1/Ende und Enter an den Kalender weiter. Klick ausserhalb (Maus-Hook des Threads, solange offen), Esc und Fokusverlust schliessen; Klick auf einen Tag uebernimmt.
- DFM-nah zu TDateTimePicker: Date, Time, MinDate, MaxDate, ShowCheckbox, Checked, DateFormat, Format, CalAlignment, Kind, DateMode, ParseInput.
- Kind: dtkDate (Datum mit Kalender), dtkTime (Uhrzeit, Auf/Ab-Knoepfe, Oben/Unten = Minute, Strg = Stunde), dtkDateTime (Datum und Uhrzeit).
- DateMode = dmUpDown: Auf/Ab-Knoepfe statt Kalender (Tag, Strg = Monat).
- ParseInput + OnUserInput: eigene Auswertung der Eingabe (wie TDateTimePicker.OnUserInput), z. B. "morgen" oder "+3".
- Code (Date := ...) loest kein OnChange aus.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `TextHint` | `string` |  | Platzhaltertext im leeren Feld (z. B. „Suchen …"). Nutzung: `Edit1.TextHint := 'E-Mail-Adresse';` |
| `UseSystemContextMenu` | `Boolean` | `False` | True: Rechtsklick zeigt das native Windows-Menü des Edits statt des PPGlow-Menüs (Rückgängig, Ausschneiden, Kopieren, Einfügen, Löschen, Alles markieren; übersetzt und im Preset-Stil). |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Ergebnis einer Prüfung: pvsNone (neutral), pvsValid (grüner Rand), pvsWarning (gelb), pvsError (rot). Die Farben kommen aus den Signal-Tokens; ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if not IstMail(Edit1.Text) then begin Edit1.ValidationState := pvsError; Edit1.ValidationHint := 'Keine gültige Adresse'; end;` |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState; erscheint als Tooltip und wird vom Screenreader vorgelesen. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen (z. B. eingebettet in eigene Flächen). |
| `CalAlignment` | `TDTCalAlignment` | `dtaLeft` | Ausrichtung des aufklappenden Kalenders am Feld: dtaLeft = linke Kante, dtaRight = rechte Kante (bei RTL gespiegelt). |
| `Checked` | `Boolean` | `True` | Nur mit ShowCheckbox: True = ein Datum ist gesetzt, False = „kein Datum". |
| `Date` | `TDate` |  | Das gewählte Datum (ohne Uhrzeit). Setzen aus Code löst kein OnChange aus; Werte außerhalb MinDate/MaxDate werden begrenzt. Nutzung: `DatePicker1.Date := IncDay(Date, 7);` |
| `DateFormat` | `TDTDateFormat` | `dfShort` | dfShort (kurzes Datum, z. B. 08.10.2026) oder dfLong (langes Datum mit Wochentag) nach den Ländereinstellungen, wenn Format leer ist. |
| `DateMode` | `TDTDateMode` | `dmComboBox` | dmComboBox: Kalender zum Aufklappen. dmUpDown: Auf/Ab-Knöpfe statt Kalender (Tag, mit Strg Monat), kein Aufklappen. |
| `Format` | `string` |  | Eigenes Anzeigeformat nach FormatDateTime (z. B. „dd.mm.yyyy" oder „ddd, d. mmmm"); leer = DateFormat. |
| `Kind` | `TDateTimeKind` | `dtkDate` | dtkDate: Datum mit Kalender. dtkTime: Uhrzeit (LongTimeFormat bzw. Format), Auf/Ab-Knöpfe statt Kalender, Oben/Unten = Minute, Strg = Stunde; der Datumsteil bleibt erhalten. dtkDateTime (ab Delphi 10.4): Datum und Uhrzeit. Der DB-DatePicker überträgt bei Uhrzeit den ganzen Wert. Nutzung: `DatePicker1.Kind := dtkTime; DatePicker1.Time := EncodeTime(9, 30, 0, 0);` |
| `MaxDate` | `TDate` |  | Spätestes wählbares Datum; 0 = keine Grenze. Spätere Tage sind im Kalender gesperrt, Eingaben werden begrenzt. |
| `MinDate` | `TDate` |  | Frühestes wählbares Datum; 0 = keine Grenze. Nutzung: `DatePicker1.MinDate := Date;` (nur heute und später) |
| `ParseInput` | `Boolean` | `False` | True: Beim Übernehmen der Eingabe wird zuerst OnUserInput gefragt (eigene Auswertung, z. B. „morgen“ oder „+3“). DateAndTime kommt mit dem gelesenen bzw. bisherigen Wert; AllowChange := False lehnt ab (ValidationState = pvsError). Ohne Ereignis gilt die normale Prüfung. Nutzung: `DatePicker1.ParseInput := True; DatePicker1.OnUserInput := Eingabe;` |
| `ShowCheckbox` | `Boolean` | `False` | True: Links im Feld erscheint ein Kontrollkästchen; ohne Haken (Checked = False) gilt „kein Datum". |
| `Styles` | [TPPGCalendarStyles](types/TPPGCalendarStyles.md) |  | Bereiche des aufklappenden Kalenders einzeln gestalten (Kopf, Wochentage, Wochenende, Heute, Auswahl, andere Monate, Wochennummern). Nutzung: `DatePicker1.Styles.Weekend.TextColor := clRed;` |
| `TabStop` | `Boolean` | `True` | True: Das Feld ist mit Tab erreichbar. |
| `Time` | `TTime` |  | Uhrzeitanteil des Werts (wie TDateTimePicker.Time); die Anzeige zeigt nur das Datum. |
| `TextHintVisibleOnFocus` | `Boolean` | `False` | True: Der Platzhalter bleibt sichtbar, bis getippt wird; False: er verschwindet schon beim Fokus. |

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
| `OnCustomDrawDay` | `TPPGCalendarDrawDayEvent` `(Sender: TObject; Canvas: TCanvas; ADate: TDate; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean)` | Vor dem Zeichnen jedes Tages im aufklappenden Kalender: Style für ADate ändern (z. B. Feiertage fett und rot) oder mit DefaultDraw := False selbst zeichnen. Nutzung: `if IstFeiertag(ADate) then begin Style.TextColor := clRed; Style.FontStyle := [fsBold]; end;` |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Text wurde geändert (Tippen, Einfügen, Code). |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
| `OnCloseUp` | `TNotifyEvent` `(Sender: TObject)` | Der Kalender wurde geschlossen (mit oder ohne Übernahme). |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDropDown` | `TNotifyEvent` `(Sender: TObject)` | Der Kalender klappt gleich auf. |
| `OnUserInput` | `TDTParseInputEvent` `(Sender: TObject; const UserString: string; var DateAndTime: TDateTime; var AllowChange: Boolean)` | Nur mit ParseInput = True: Die Eingabe wird übernommen (Enter, Fokusverlust). UserString ist der eingegebene Text, DateAndTime kommt mit dem gelesenen bzw. bisherigen Wert und kann ersetzt werden; AllowChange := False lehnt ab (Feld wird rot markiert). Nutzung: `if SameText(UserString, 'morgen') then DateAndTime := Date + 1 else if UserString = '' then AllowChange := False;` |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDatePicker.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
