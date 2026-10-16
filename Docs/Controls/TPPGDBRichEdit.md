# TPPGDBRichEdit

Palette **PPGlow DB** - Unit `PPG.DB.RichEdit` - Basis `TPPGRichEdit`

**Vorbild:** TDBRichEdit

## Wofür

Zeigt und bearbeitet formatierten Text (RTF) aus einem Memo- oder BLOB-Feld. Beim Datensatzwechsel lädt es den Inhalt neu, beim Verlassen des Controls schreibt es einen geänderten Text als RTF ins Feld zurück.

## Wann verwenden

- Für Formulare, die bisher `TDBRichEdit` benutzen (`DataSource`, `DataField`, `ReadOnly`, `AutoDisplay`).
- Für Notizen, Beschreibungen und Texte mit Formatierung, die in der Datenbank liegen. Für reinen Text ist `TPPGDBMemo` richtig.

## Unterschiede und Hinweise

- Das Feld sollte ein Memo- (`ftMemo`, `ftWideMemo`) oder BLOB-Feld sein. Steht darin kein RTF (Altbestand mit reinem Text), zeigt das Control den Text unformatiert; nach einer Änderung wird RTF gespeichert.
- Text- und Stringfelder sowie `PlainText = True` zeigen und schreiben reinen Text.
- Das Control ist schreibgeschützt, wenn die Datenmenge oder das Feld nicht änderbar ist; die Eigenschaft `ReadOnly` sperrt zusätzlich.
- `AutoDisplay = False` lädt BLOB-Felder erst bei Doppelklick oder Enter (`LoadMemo`), wie bei `TDBRichEdit`.
- Ablauf wie bei `TPPGDBMemo`: Der Datensatz geht beim ersten Tippen in den Bearbeiten-Modus, Esc setzt den Feldwert zurück, ein ungültiger Wert beim Verlassen setzt `ValidationState = pvsError`.
- `Lines` wird nicht in die DFM gespeichert.
- Farben und Formatierung wie bei `TPPGRichEdit`: Der Hintergrund folgt dem Theme, Text ohne eigene Farbe wird im Dark Mode hell gezeichnet; im Feld gespeichert wird immer der unveränderte RTF-Text.
- Eigene Unit `PPG.DB.RichEdit`, damit Anwendungen ohne RichEdit nichts davon linken.

## Beispiel

```pascal
DBRichEdit1.DataSource := DataSource1;
DBRichEdit1.DataField := 'Beschreibung';
```

## Verhalten (aus dem Quelltext)

TPPGDBRichEdit - TPPGRichEdit an einem Memo- oder BLOB-Feld (Ersatz fuer TDBRichEdit).

- Das Feld enthaelt RTF. Beim Datensatzwechsel wird der Inhalt mit Lines.LoadFromStream geladen, beim Verlassen des Controls (Datensatz bearbeitet) mit Lines.SaveToStream zurueckgeschrieben.
- Steht im Feld kein RTF (reiner Text aus einem aelteren Bestand), wird der Text unformatiert angezeigt; gespeichert wird danach RTF.
- Textfelder (ftString u. a.) und PlainText = True zeigen und schreiben reinen Text.
- ReadOnly folgt dem Feld (nicht aenderbar, Datenmenge nur lesend) und der Eigenschaft ReadOnly. Ablauf, Esc und Validierung wie TPPGDBMemo (gemeinsame Anbindung TPPGDBBinding in PPG.DB.Controls).
- Eigene Unit (nicht in PPG.DB.Controls), damit Anwendungen ohne Rich-Text nichts davon linken.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `ShowRequired` | `Boolean` | `False` | True: Ist das Datenfeld ein Pflichtfeld (TField.Required), zeigt das leere Feld ein Sternchen, bevor der Validator meldet. |
| `AutoDisplay` | `Boolean` | `True` | False: BLOB-Felder werden erst bei Doppelklick oder Enter geladen (spart Zeit beim Blättern; wie TDBRichEdit). |
| `DataField` | `string` |  | Memo- oder BLOB-Feld mit RTF-Text, das angezeigt und bearbeitet wird (Textfelder zeigen reinen Text). |
| `DataSource` | `TDataSource` |  | Datenquelle mit der Datenmenge, aus der DataField kommt. |
| `ReadOnly` | `Boolean` | `False` | True: Der Text kann gelesen, markiert und kopiert, aber nicht geändert werden. Die Optik bestimmt ReadOnlyStyle. |
| `Lines` | `TStrings` |  | Der Text als Zeilenliste (wie TRichEdit.Lines). LoadFromStream und SaveToStream lesen und schreiben RTF, mit PlainText = True reinen Text. In der DFM stehen die Zeilen als reiner Text. Nutzung: `RichEdit1.Lines.LoadFromFile('brief.rtf'); RichEdit1.Lines.SaveToStream(Stream);` |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `UseSystemContextMenu` | `Boolean` | `False` | True: Rechtsklick zeigt das native Windows-Menü des Edits statt des PPGlow-Menüs (Rückgängig, Ausschneiden, Kopieren, Einfügen, Löschen, Alles markieren; übersetzt und im Preset-Stil). |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Ergebnis einer Prüfung: pvsNone (neutral), pvsValid (grüner Rand), pvsWarning (gelb), pvsError (rot). Die Farben kommen aus den Signal-Tokens; ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if not IstMail(Edit1.Text) then begin Edit1.ValidationState := pvsError; Edit1.ValidationHint := 'Keine gültige Adresse'; end;` |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState; erscheint als Tooltip und wird vom Screenreader vorgelesen. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen (z. B. eingebettet in eigene Flächen). |
| `EnableURLs` | `Boolean` | `False` | True: Internetadressen im Text werden erkannt, als Link dargestellt und lösen OnLinkClick aus. |
| `HideScrollBars` | `Boolean` | `True` | True: Scrollleisten erscheinen nur, wenn der Text nicht mehr ins Feld passt. False: Sie bleiben bei Bedarf sichtbar (deaktiviert). |
| `HideSelection` | `Boolean` | `True` | True: Die Markierung wird ausgeblendet, wenn das Feld den Fokus verliert. |
| `MaxLength` | `Integer` | `0` | Höchstzahl der Zeichen; 0 = unbegrenzt. |
| `PlainText` | `Boolean` | `False` | True: Lines.LoadFromStream und SaveToStream lesen und schreiben reinen Text statt RTF. Vorgabe False (RTF). Nutzung: `RichEdit1.PlainText := True; RichEdit1.Lines.SaveToFile('notiz.txt');` |
| `ReadOnlyStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Eigene Optik bei ReadOnly: Fläche, Text- und Randfarbe (je auch für Dunkel). clDefault = wie im bearbeitbaren Zustand. Nutzung: `Edit1.ReadOnlyStyle.Color := $00F0F0F0; Edit1.ReadOnlyStyle.TextColor := clGrayText;` |
| `ScrollBars` | `TScrollStyle` | `ssNone` | Scrollleisten: ssNone, ssHorizontal, ssVertical oder ssBoth. Ohne Umbruch (WordWrap = False) ssBoth wählen. |
| `ShowURLHint` | `Boolean` | `False` | True: Beim Überfahren eines Links zeigt das Control die Adresse als Hint (mit EnableURLs). |
| `SpellChecking` | `Boolean` | `False` | True: Windows-Rechtschreibprüfung im Text (soweit das System sie anbietet). |
| `TabStop` | `Boolean` | `True` | True: Das Feld ist mit Tab erreichbar. |
| `WantReturns` | `Boolean` | `True` | True: Enter fügt einen Absatz ein; False: Enter löst den Standard-Button des Formulars aus. |
| `WantTabs` | `Boolean` | `False` | True: Tab fügt ein Tabulatorzeichen ein statt zum nächsten Control zu wechseln. |
| `WordWrap` | `Boolean` | `True` | True: Lange Zeilen brechen am rechten Rand um. False: Zeilen laufen nach rechts weiter und werden waagerecht gescrollt. |
| `Zoom` | `Integer` | `100` | Vergrößerung der Anzeige in Prozent (1 bis 6400, Vorgabe 100). Ändert nur die Darstellung, nicht die Schriftgröße im Text. Nutzung: `RichEdit1.Zoom := 150;` |
| `OnProtectChange` | `TRichEditProtectChange` |  | Der Anwender will geschützten Text ändern (SelAttributes.Protected). AllowChange := True erlaubt es. |
| `OnSaveClipboard` | `TRichEditSaveClipboard` |  | Beim Beenden wird der Zwischenablage-Inhalt des RichEdit gesichert. SaveClipboard := False verzichtet darauf. |

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
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Text wurde geändert (Tippen, Einfügen, Code). |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |
| `OnLinkClick` | `TPPGRichLinkClickEvent` `(Sender: TObject; const URL: string; Button: TMouseButton)` | Klick auf einen Link (mit EnableURLs). URL nennt die Adresse, Button die Maustaste. Nutzung: `ShellExecute(0, 'open', PChar(URL), nil, nil, SW_SHOWNORMAL);` |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnResizeRequest` | `TRichEditResizeEvent` | Der Inhalt braucht mehr Platz als das Control hat; Rect nennt die gewünschte Größe. |
| `OnSelectionChange` | `TNotifyEvent` `(Sender: TObject)` | Auswahl oder Cursorposition haben sich geändert. Dient dem Nachführen von Symbolleisten (Fett, Kursiv, Ausrichtung) aus SelAttributes und Paragraph. Nutzung: `btnBold.Down := fsBold in RichEdit1.SelAttributes.Style;` |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |

Tests: `PPG.Tests.Audit5d`; `PPG.Tests.RichEdit` (TDBRichEditTests); `PPG.Tests.Streaming` (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBRichEdit.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
