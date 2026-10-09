# TPPGTagEdit

Palette **PPGlow** - Unit `PPG.TagEdit` - Basis `TPPGCustomDropDownField`

**Vorbild:** Empfängerfeld von Outlook, WinUI TokenizingTextBox

## Unterschiede und Hinweise

- Chips (Text mit ×) stehen vor dem Eingabebereich und brechen über mehrere Zeilen um. Mit `AutoSize` wächst die Höhe mit. Das Layout wird nur bei Änderung der Tags, der Breite oder der Schrift neu berechnet.
- Ein Tag entsteht:
  - mit Enter
  - mit einem Zeichen aus `InputDelimiters` (`;` `,`)
  - beim Verlassen (`AddOnExit`)
  - eingefügtes `a; b; c` ergibt drei Tags
- Rücktaste im leeren Feld markiert zuerst das letzte Tag und löscht es beim zweiten Druck (wie Outlook). Pfeil links/rechts wandert zwischen den Chips, Entf löscht das markierte.
- `Suggestions` erscheinen während des Tippens. Mit `AllowNew = False` sind nur Vorschläge erlaubt. Doppelte sind ausgeschlossen (`AllowDuplicates`, `CaseSensitive`); `MaxTags` begrenzt die Anzahl.
- `OnTagAdding` kann ablehnen oder den Text ändern (z. B. eine E-Mail prüfen). Dazu kommen `OnTagRemoved` und `OnTagClick`. Code (`Tags`, `TagsText`) löst nichts aus.
- Screenreader: Die Chips sind Kinder; die Standardaktion ist Entfernen.

## Beispiel

```pascal
PPGTagEdit1.Suggestions.CommaText := 'Delphi,VCL,Windows';
PPGTagEdit1.TagsText := 'Delphi;VCL';
```

## Verhalten (aus dem Quelltext)

TPPGTagEdit - Stichwoerter als Chips (Phase 12f, Vorbild Outlook-Empfaenger,
WinUI TokenizingTextBox).

- Chips (Text mit x) vor dem Eingabebereich, Umbruch ueber mehrere Zeilen; mit AutoSize waechst die Hoehe mit. Das Layout wird nur bei Aenderung der Tags, der Breite oder der Schrift berechnet (nicht je Tastendruck).
- Ein Tag entsteht mit Enter, mit einem der Delimiters (";" ",") oder beim Verlassen (AddOnExit). Eingefuegtes "a; b; c" ergibt drei Tags.
- Ruecktaste im leeren Feld markiert zuerst das letzte Tag und loescht es beim zweiten Druck (wie Outlook); Pfeil links/rechts wandert zwischen den Chips, Entf loescht das markierte.
- Vorschlaege (Suggestions) im Aufklapp-Fenster waehrend des Tippens; AllowNew = False erlaubt nur Vorschlaege. MaxTags, CaseSensitive, keine Doppelten.
- Ereignisse nur bei Anwenderaktionen: OnTagAdding (abbrechbar, Text aenderbar - z.B. E-Mail pruefen), OnTagRemoved, OnTagClick, OnChange. Tags aus Code (Tags.Add, TagsText) loesen nichts aus.
- Screenreader: Chips als Kinder, Standardaktion Entfernen.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Tags` | `TStrings` |  | Die aktuellen Tags, je Zeile eines. Änderungen aus Code lösen keine Ereignisse aus. Nutzung: `TagEdit1.Tags.Add('Wichtig');` |
| `Suggestions` | `TStrings` |  | Vorschläge, die beim Tippen im Aufklappfenster erscheinen. Nutzung: `TagEdit1.Suggestions.CommaText := 'Vertrieb,Einkauf,Technik';` |
| `InputDelimiters` | `string` |  | Zeichen, die beim Tippen ein Tag abschließen (z. B. „;," ). Enter schließt immer ab; eingefügtes „a; b; c" ergibt drei Tags. |
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
| `ReadOnly` | `Boolean` | `False` | True: Der Text kann gelesen, markiert und kopiert, aber nicht geändert werden. Die Optik bestimmt ReadOnlyStyle. |
| `ReadOnlyStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Eigene Optik bei ReadOnly: Fläche, Text- und Randfarbe (je auch für Dunkel). clDefault = wie im bearbeitbaren Zustand. Nutzung: `Edit1.ReadOnlyStyle.Color := $00F0F0F0; Edit1.ReadOnlyStyle.TextColor := clGrayText;` |
| `TabStop` | `Boolean` | `True` | True: Das Feld ist mit Tab erreichbar. |
| `ShowClearButton` | `Boolean` | `False` | True: Ein „×"-Knopf im Feld löscht den Text (nur sichtbar, wenn Text vorhanden und das Feld bearbeitbar ist). |
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

Tests: `PPG.Tests.Audit45` (TNamingTests, TSetterFixTests, TStreamingFixTests); `PPG.Tests.Audit5d` (TStage3Tests, TVclPropsTests); `PPG.Tests.Audit7B` (TAudit7BTests); `PPG.Tests.Audit8D` (TAudit8DTests); `PPG.Tests.Phase12c` (TFieldsGalleryTests, TTagEditTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGTagEdit.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
