# TPPGDBTagEdit

Palette **PPGlow DB** - Unit `PPG.DB.Fields` - Basis `TPPGTagEdit`

**Vorbild:** DB-Variante von `TPPGTagEdit` (wie `TDBEdit`)

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
| `DataField` | `string` |  | Textfeld, in dem die Tags getrennt durch Delimiter stehen. |
| `DataSource` | `TDataSource` |  | Datenquelle mit der Datenmenge, aus der DataField kommt. |
| `ReadOnly` | `Boolean` | `False` | True: Der Text kann gelesen, markiert und kopiert, aber nicht geändert werden. Die Optik bestimmt ReadOnlyStyle. |
| `Tags` | `TStrings` |  | Die aktuellen Tags, je Zeile eines. Änderungen aus Code lösen keine Ereignisse aus. Nutzung: `TagEdit1.Tags.Add('Wichtig');` |
| `Suggestions` | `TStrings` |  | Vorschläge, die beim Tippen im Aufklappfenster erscheinen. Nutzung: `TagEdit1.Suggestions.CommaText := 'Vertrieb,Einkauf,Technik';` |
| `Delimiters` | `string` |  | Zeichen, die beim Tippen ein Tag abschließen (z. B. „;," ). Enter schließt immer ab; eingefügtes „a; b; c" ergibt drei Tags. |
| `Delimiter` | `Char` | `';'` | Trennzeichen der Tags in TagsText bzw. im DB-Feld. Vorgabe „;". |
| `AllowNew` | `Boolean` | `True` | False: Nur Einträge aus Suggestions sind erlaubt (Auswahlliste statt freier Eingabe). |
| `AllowDuplicates` | `Boolean` | `False` | True: Dasselbe Tag darf mehrfach vorkommen. |
| `CaseSensitive` | `Boolean` | `False` | True: Groß-/Kleinschreibung zählt beim Prüfen auf Doppelte und beim Abgleich mit Suggestions. |
| `MaxTags` | `Integer` | `0` | Höchstzahl der Tags; 0 = ohne Grenze. |
| `AddOnExit` | `Boolean` | `True` | True: Beim Verlassen des Felds wird angefangener Text zum Tag. |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `TextHint` | `string` |  | Platzhaltertext im leeren Feld (z. B. „Suchen …"). Nutzung: `Edit1.TextHint := 'E-Mail-Adresse';` |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Ergebnis einer Prüfung: pvsNone (neutral), pvsValid (grüner Rand), pvsWarning (gelb), pvsError (rot). Die Farben kommen aus den Signal-Tokens; ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if not IstMail(Edit1.Text) then begin Edit1.ValidationState := pvsError; Edit1.ValidationHint := 'Keine gültige Adresse'; end;` |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState; erscheint als Tooltip und wird vom Screenreader vorgelesen. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen (z. B. eingebettet in eigene Flächen). |
| `ReadOnlyStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Eigene Optik bei ReadOnly: Fläche, Text- und Randfarbe (je auch für Dunkel). clDefault = wie im bearbeitbaren Zustand. Nutzung: `Edit1.ReadOnlyStyle.Color := $00F0F0F0; Edit1.ReadOnlyStyle.TextColor := clGrayText;` |
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
| `OnTagAdding` | `TPPGTagAddingEvent` `(Sender: TObject; var Tag: string; var Allow: Boolean)` | Bevor ein Tag durch den Anwender entsteht: Tag kann geändert (z. B. getrimmt) werden, Allow := False lehnt ab. Nutzung: `Allow := Pos('@', Tag) > 0; // nur E-Mail-Adressen` |
| `OnTagRemoved` | `TPPGTagEvent` `(Sender: TObject; const Tag: string)` | Der Anwender hat ein Tag entfernt (Klick auf ×, Entf oder Rücktaste). |
| `OnTagClick` | `TPPGTagEvent` `(Sender: TObject; const Tag: string)` | Ein Tag (Chip) wurde angeklickt. |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Text wurde geändert (Tippen, Einfügen, Code). |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBTagEdit.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
