# TPPGDBDatePicker

Palette **PPGlow DB** - Unit `PPG.DB.Controls` - Basis `TPPGDatePicker`

**Vorbild:** TDateTimePicker an einem Datumsfeld

## Unterschiede und Hinweise

- Null: nur mit `ShowCheckbox` darstellbar (Kästchen aus). Die Uhrzeit eines DateTime-Felds bleibt beim Schreiben erhalten.

## Verhalten (aus dem Quelltext)

Datenbank-Controls (Phase 9c): TPPGDBEdit, TPPGDBMemo, TPPGDBCheckBox,
TPPGDBComboBox, TPPGDBDatePicker.

Eigenes Package (PPGlowDBR): Anwendungen ohne Datenbank linken kein Data.DB.
Die Controls erben von den PPGlow-Controls und fuegen nur die Anbindung
hinzu (TFieldDataLink) - keine zweite Zeichenlogik.

Ablauf wie bei den VCL-DB-Controls:
- Datensatz wechselt (DataChange): Wert aus dem Feld anzeigen (mit Fokus Field.Text, ohne Field.DisplayText).
- Anwender aendert: zuerst den Datensatz in den Bearbeiten-Modus setzen (TPPGFieldDataLink.EditByUser), dann Modified. Waehrend EditByUser darf DataChange den neuen Wert nicht ueberschreiben (Sperre).
- Verlassen (CM_EXIT): UpdateRecord schreibt ins Feld. Ein ungueltiger Wert setzt ValidationState = pvsError mit der Meldung als ValidationHint, behaelt den Fokus und bricht still ab (kein Dialog).
- Esc waehrend der Bearbeitung: Wert aus dem Feld zuruecksetzen.

Fallstrick (Roadmap): TDataLink-Ereignisse kommen auch, waehrend gezeichnet
wird (berechnete Felder). Die Handler setzen deshalb nur Werte; Zeichnen
passiert immer erst im naechsten Paint.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `DataField` | `string` |  | Datums- bzw. Datum-Zeit-Feld, das angezeigt und bearbeitet wird; leeres Feld = Null. |
| `DataSource` | `TDataSource` |  | Datenquelle mit der Datenmenge, aus der DataField kommt. |
| `ReadOnly` | `Boolean` | `False` | True: Der Text kann gelesen, markiert und kopiert, aber nicht geändert werden. Die Optik bestimmt ReadOnlyStyle. |
| `Date` | `TDate` |  | Das gewählte Datum (ohne Uhrzeit). Setzen aus Code löst kein OnChange aus; Werte außerhalb MinDate/MaxDate werden begrenzt. Nutzung: `DatePicker1.Date := IncDay(Date, 7);` |
| `Time` | `TTime` |  | Uhrzeitanteil des Werts (wie TDateTimePicker.Time); die Anzeige zeigt nur das Datum. |
| `Checked` | `Boolean` | `True` | Nur mit ShowCheckbox: True = ein Datum ist gesetzt, False = „kein Datum". |
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
| `DateFormat` | `TDTDateFormat` | `dfShort` | dfShort (kurzes Datum, z. B. 08.10.2026) oder dfLong (langes Datum mit Wochentag) nach den Ländereinstellungen, wenn Format leer ist. |
| `DateMode` | `TDTDateMode` | `dmComboBox` | Wie TDateTimePicker; wird gelesen und gespeichert, ändert aber nichts (immer Feld mit Kalender-Popup). |
| `Format` | `string` |  | Eigenes Anzeigeformat nach FormatDateTime (z. B. „dd.mm.yyyy" oder „ddd, d. mmmm"); leer = DateFormat. |
| `Kind` | `TDateTimeKind` | `dtkDate` | Wie TDateTimePicker; wird gelesen und gespeichert, ändert aber nichts. Für Uhrzeiten TPPGTimePicker verwenden. |
| `MaxDate` | `TDate` |  | Spätestes wählbares Datum; 0 = keine Grenze. Spätere Tage sind im Kalender gesperrt, Eingaben werden begrenzt. |
| `MinDate` | `TDate` |  | Frühestes wählbares Datum; 0 = keine Grenze. Nutzung: `DatePicker1.MinDate := Date;` (nur heute und später) |
| `ParseInput` | `Boolean` | `False` | Wie TDateTimePicker; wird gelesen und gespeichert, ändert aber nichts (Eingaben werden immer geprüft). |
| `ShowCheckbox` | `Boolean` | `False` | True: Links im Feld erscheint ein Kontrollkästchen; ohne Haken (Checked = False) gilt „kein Datum". |
| `CalendarStyles` | [TPPGCalendarStyles](types/TPPGCalendarStyles.md) |  | Bereiche des aufklappenden Kalenders einzeln gestalten (Kopf, Wochentage, Wochenende, Heute, Auswahl, andere Monate, Wochennummern). Nutzung: `DatePicker1.CalendarStyles.Weekend.TextColor := clRed;` |
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

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnCustomDrawDay` | `TPPGCalendarDrawDayEvent` `(Sender: TObject; Canvas: TCanvas; ADate: TDate; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean)` | Vor dem Zeichnen jedes Tages im aufklappenden Kalender: Style für ADate ändern (z. B. Feiertage fett und rot) oder mit DefaultDraw := False selbst zeichnen. Nutzung: `if IstFeiertag(ADate) then begin Style.TextColor := clRed; Style.FontStyle := [fsBold]; end;` |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Text wurde geändert (Tippen, Einfügen, Code). |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. |
| `OnCloseUp` | `TNotifyEvent` `(Sender: TObject)` | Der Kalender wurde geschlossen (mit oder ohne Übernahme). |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDropDown` | `TNotifyEvent` `(Sender: TObject)` | Der Kalender klappt gleich auf. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBDatePicker.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
