# TPPGNumberEdit

Palette **PPGlow** - Unit `PPG.NumberEdit` - Basis `TPPGCustomNumberEdit`

**Vorbild:** TMS TAdvEdit (`EditType`), WinUI NumberBox

## Unterschiede und Hinweise

- Ein Feld für Ganzzahl, Kommazahl, Währung und Prozent (`Kind`). Es ersetzt das früher geplante `TPPGFloatSpinEdit`; `TPPGSpinEdit` bleibt für die Kompatibilität mit `TSpinEdit`.
- Ohne Fokus zeigt es das Anzeigeformat (`1.234,50 €`), mit Fokus das Bearbeitungsformat (`1234,5`). Die Einfügemarke bleibt dabei an derselben Ziffer.
- Eingabe:
  - Erlaubt sind Ziffern, Trenner und Minus. Mit `AllowExpressions` darf man auch rechnen (`2*19,99`, Klammern, Punkt vor Strich).
  - Der Punkt des Ziffernblocks wird zum Dezimaltrenner des Gebietsschemas.
  - Eingefügtes `1.234,50 €`, `1,234.50`, `CHF 1'234.50` oder `(12,50)` wird erkannt.
- Übernommen wird bei Enter, beim Verlassen, mit Pfeil/Bild auf/ab, Spin-Buttons und dem Mausrad (nur mit Fokus).
  - Ungültige Eingabe bei Enter: Fehler am Feld.
  - Ungültige Eingabe beim Verlassen: Der letzte gültige Wert kommt zurück.
  - Esc verwirft die Eingabe.
- `nkCurrency` rechnet in `Currency` (`AsCurrency`) und rundet kaufmännisch: 2,345 → 2,35. `Round` der RTL würde dagegen zur geraden Ziffer runden.
- `Min = Max` bedeutet ohne Grenze (wie `TSpinEdit`); Werte werden still begrenzt.
- `OnChange` kommt nur, wenn der Anwender den Wert ändert, also nicht je Tastendruck und nicht aus Code.
- `AllowNull`: Ein leeres Feld bedeutet „kein Wert“ (`IsNull`). In `TPPGDBNumberEdit` ist das die Vorgabe.
- Prozent: `Value` ist die angezeigte Zahl (12,5 für 12,5 %), nicht der Anteil (0,125).

## Beispiel

```pascal
PPGNumberEdit1.Kind := nkCurrency;
PPGNumberEdit1.Min := 0;
PPGNumberEdit1.Max := 100000;
PPGNumberEdit1.AsCurrency := 19.99;
```

## Verhalten (aus dem Quelltext)

TPPGNumberEdit - ein Feld fuer Ganzzahl, Kommazahl, Waehrung und Prozent
(Phase 12b; Vorbild TMS TAdvEdit EditType, WinUI NumberBox).

- Ohne Fokus zeigt das Feld formatiert ("1.234,50 EUR"), mit Fokus roh ("1234,5"). Gewechselt wird in FocusChanged (nie in Paint), die Einfuegemarke bleibt an derselben Ziffer.
- Eingabe: Ziffern, Trenner, Minus; mit AllowExpressions auch + - * / und Klammern ("2*19,99"), ausgerechnet bei Enter und beim Verlassen. Der Punkt des Ziffernblocks wird zum Dezimaltrenner des Gebietsschemas. Eingefuegtes "1.234,50 EUR" oder "1,234.50" wird erkannt (PPG.NumberFormat).
- Uebernommen wird bei Enter, beim Verlassen, mit Pfeilen, Spin-Buttons und Mausrad (nur mit Fokus). Ungueltige Eingabe: Enter zeigt den Fehler am Feld (ValidationState), Verlassen stellt den letzten gueltigen Wert wieder her. Esc verwirft die Eingabe.
- nkCurrency rechnet in Currency (AsCurrency, keine Rundungsfehler bei Geld).
- MinValue = MaxValue: keine Grenze (wie TSpinEdit); Werte werden still begrenzt.
- OnChange kommt nur, wenn der Anwender den Wert aendert (nicht bei jedem Tastendruck und nicht aus Code). Value aus Code loest nichts aus.
- AllowNull: leeres Feld = kein Wert (IsNull). IPPGFieldValue fuer DB-Felder und Grid.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `RoundedCorners` | `TPPGCorners` | `[pcTopLeft, pcTopRight, pcBottomRight, pcBottomLeft]` | Welche Ecken gerundet sind; die übrigen werden eckig. Für Button-Gruppen und Segment-Schalter: linker Button [pcTopLeft, pcBottomLeft], mittlere [], rechter [pcTopRight, pcBottomRight]. Menge aus: `pcTopLeft`, `pcTopRight`, `pcBottomRight`, `pcBottomLeft`. Nutzung: `PPGButton2.RoundedCorners := [];` |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `Kind` | `TPPGNumberKind` | `nkFloat` | Art der Zahl: nkInteger (Ganzzahl), nkFloat (Kommazahl), nkCurrency (Geldbetrag, intern Currency ohne Rundungsfehler, mit Währungszeichen), nkPercent (Prozent; Value 12,5 wird als „12,5 %" angezeigt). Werte: `nkInteger`, `nkFloat`, `nkCurrency`, `nkPercent`. |
| `Decimals` | `Integer` | `2` | Nachkommastellen in der Anzeige und beim Runden (0..10; kaufmännisch gerundet). Bei nkInteger ohne Wirkung. |
| `Min` | `Double` |  | Kleinster erlaubter Wert; kleinere werden still begrenzt. Min = Max bedeutet keine Grenze. Nutzung: `NumberEdit1.Min := 0; NumberEdit1.Max := 100;` |
| `Max` | `Double` |  | Größter erlaubter Wert; größere werden still begrenzt. Min = Max bedeutet keine Grenze (wie TSpinEdit). |
| `Increment` | `Double` |  | Schrittweite für Pfeil auf/ab, Mausrad und Spin-Buttons. |
| `LargeIncrement` | `Double` |  | Schrittweite für Bild auf/ab. |
| `ShowSpinButtons` | `Boolean` | `False` | True: Rechts im Feld erscheinen Auf/Ab-Schaltflächen (Schritt = Increment). |
| `ShowThousandSeparator` | `Boolean` | `True` | True: Ohne Fokus wird mit Tausendertrennzeichen angezeigt („1.234,50"). |
| `CurrencyString` | `string` |  | Währungszeichen bei Kind = nkCurrency; leer = Zeichen aus den Ländereinstellungen (z. B. „€"). Nutzung: `NumberEdit1.CurrencyString := 'CHF';` |
| `AllowExpressions` | `Boolean` | `True` | True: Die Eingabe darf rechnen („2*19,99", „(100-15)/2"); ausgerechnet wird bei Enter und beim Verlassen. |
| `AllowNull` | `Boolean` | `False` | True: Ein leeres Feld bedeutet „kein Wert" (IsNull, bei DB-Feldern Null); False: leer wird zu 0. |
| `Value` | `Double` |  | Der Zahlenwert. Ohne Fokus formatiert angezeigt, mit Fokus roh. Setzen aus Code löst kein OnChange aus; OnChange kommt nur bei Änderungen durch den Anwender. Nutzung: `Gesamt := NumberEdit1.Value * 1.19;` |
| `TextHint` | `string` |  | Platzhaltertext im leeren Feld (z. B. „Suchen …"). Nutzung: `Edit1.TextHint := 'E-Mail-Adresse';` |
| `TextHintVisibleOnFocus` | `Boolean` | `False` | True: Der Platzhalter bleibt sichtbar, bis getippt wird; False: er verschwindet schon beim Fokus. |
| `UseSystemContextMenu` | `Boolean` | `False` | True: Rechtsklick zeigt das native Windows-Menü des Edits statt des PPGlow-Menüs (Rückgängig, Ausschneiden, Kopieren, Einfügen, Löschen, Alles markieren; übersetzt und im Preset-Stil). |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Ergebnis einer Prüfung: pvsNone (neutral), pvsValid (grüner Rand), pvsWarning (gelb), pvsError (rot). Die Farben kommen aus den Signal-Tokens; ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if not IstMail(Edit1.Text) then begin Edit1.ValidationState := pvsError; Edit1.ValidationHint := 'Keine gültige Adresse'; end;` |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState; erscheint als Tooltip und wird vom Screenreader vorgelesen. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `Alignment` | `TAlignment` | `taRightJustify` | Ausrichtung des Textes im Feld (links, rechts, zentriert). |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen (z. B. eingebettet in eigene Flächen). |
| `ReadOnly` | `Boolean` | `False` | True: Der Text kann gelesen, markiert und kopiert, aber nicht geändert werden. Die Optik bestimmt ReadOnlyStyle. |
| `ReadOnlyStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Eigene Optik bei ReadOnly: Fläche, Text- und Randfarbe (je auch für Dunkel). clDefault = wie im bearbeitbaren Zustand. Nutzung: `Edit1.ReadOnlyStyle.Color := $00F0F0F0; Edit1.ReadOnlyStyle.TextColor := clGrayText;` |
| `TabStop` | `Boolean` | `True` | True: Das Feld ist mit Tab erreichbar. |
| `ShowClearButton` | `Boolean` | `False` | True: Ein „×"-Knopf im Feld löscht den Text (nur sichtbar, wenn Text vorhanden und das Feld bearbeitbar ist). |

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
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. |
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
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |

Tests: `PPG.Tests.Audit45` (TNamingTests); `PPG.Tests.Audit5d` (TStage3Tests); `PPG.Tests.Audit7A` (TDropDownFieldTests, TWheelTests); `PPG.Tests.Phase12a` (TFieldBaseTests, TNumberEditTests, TPasswordEditTests); `PPG.Tests.Phase12c` (TFieldsGalleryTests); `PPG.Tests.Phase13a` (TGridPaintEditTests); `PPG.Tests.Phase19` (TValidatorTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGNumberEdit.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
