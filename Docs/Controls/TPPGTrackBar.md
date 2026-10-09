# TPPGTrackBar

Palette **PPGlow** - Unit `PPG.TrackBar` - Basis `TPPGCustomTrackBar`

**Vorbild:** TTrackBar

## Unterschiede und Hinweise

- `Position` wird still begrenzt; `Min > Max` wirft.
- Auswahlbereich wie `TTrackBar`: `SelStart`/`SelEnd` (mit `SelEnd` > `SelStart`) markieren einen Bereich auf der Schiene, `ShowSelRange` blendet ihn aus.
- **Bereichsregler:** `RangeMode` zeigt zwei Griffe, `Position` ist der Anfang, `PositionEnd` das Ende; sie überholen sich nicht (setzt der Code den Anfang hinter das Ende, wandert das Ende mit). Klick auf die Schiene bewegt den näheren Griff, Tab wechselt den Griff (`ActiveThumb`), danach verlässt Tab das Control. Screenreader: zwei Kinder „Von“/„Bis“.
- Noch nicht vorhanden: manuelle Ticks (`SetTick`) und `PositionToolTip`.

## Verhalten (aus dem Quelltext)

TPPGTrackBar - Schieberegler mit Glow-Griff.

Bedienung:
- Maus: Klick auf die Schiene setzt den Wert direkt dorthin und startet das Ziehen (wie Fluent/Windows 11); Klick auf den Griff zieht ohne Sprung.
- Tastatur wie TTrackBar: Pfeile = LineSize, Bild auf/ab = PageSize, Pos1/Ende = Min/Max. Bei RTL sind Links/Rechts gespiegelt.
- Mausrad: eine Raste = LineSize (nach unten = groesser, wie TTrackBar).
- Vertikal steht Min oben (wie TTrackBar).

Geometrie (alles in einer Funktion, damit Zeichnen und Hit-Test nie
auseinanderlaufen): siehe GetGeometry.

Auswahlbereich (Phase 20d): SelStart/SelEnd/ShowSelRange wie TTrackBar -
ein hervorgehobener Bereich auf der Schiene mit Marken an den Enden.

Bereichsregler (RangeMode): zwei Griffe, Position = Anfang, PositionEnd =
Ende; sie ueberholen sich nicht. Klick auf die Schiene bewegt den naeheren
Griff, Tab wechselt den Griff (danach verlaesst Tab das Control).
Screenreader: zwei Kinder "Von"/"Bis" mit ihrem Wert.

Migration: Typen und Property-Namen von TTrackBar (Vcl.ComCtrls).
Nicht unterstuetzt: PositionToolTip, manuelle Ticks per SetTick
(tsManual zeigt nur Anfang und Ende).

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `Min` | `Integer` |  | Kleinster Wert. Muss ≤ Max sein (sonst EPPGPropertyError). |
| `Max` | `Integer` | `10` | Größter Wert. Muss ≥ Min sein (sonst EPPGPropertyError); beim Laden der DFM wird erst danach geprüft. |
| `Position` | `Integer` | `0` | Aktueller Wert zwischen Min und Max. Werte außerhalb werden auf den Bereich geklemmt (kein Fehler), daher ist `Position := Position + 10` sicher. Änderungen werden weich animiert. Nutzung: `TrackBar1.Min := 0; TrackBar1.Max := 100; TrackBar1.Position := 50;` |
| `Orientation` | `TTrackBarOrientation` | `trHorizontal` | Waagerecht (trHorizontal) oder senkrecht (trVertical, Min oben wie TTrackBar). |
| `Frequency` | `Integer` | `1` | Abstand der Teilstriche in Werten (≥ 1), wie TTrackBar. |
| `LineSize` | `Integer` | `1` | Schrittweite für Pfeiltasten und eine Mausrad-Raste (≥ 1). |
| `PageSize` | `Integer` | `2` | Schrittweite für Bild auf/ab (≥ 1). |
| `TickMarks` | `TTickMark` | `tmBottomRight` | Lage der Teilstriche: tmBottomRight, tmTopLeft oder tmBoth. |
| `TickStyle` | `TTickStyle` | `tsAuto` | tsAuto = Teilstriche im Abstand Frequency, tsNone = keine, tsManual = nur Anfang und Ende (manuelle Ticks per SetTick werden nicht unterstützt). |
| `ThumbLength` | `Integer` | `20` | Durchmesser des Griffs in logischen 96-DPI-Pixeln (8..100), wie TTrackBar. |
| `SliderVisible` | `Boolean` | `True` | False: Der Griff wird nicht gezeichnet (reine Anzeige wie ein Füllbalken). |
| `SelStart` | `Integer` | `0` | Anfang des hervorgehobenen Bereichs auf der Schiene (wie TTrackBar), z. B. ein empfohlener Bereich; ändert Position nicht. Nutzung: `TrackBar1.SelStart := 40; TrackBar1.SelEnd := 80;` |
| `SelEnd` | `Integer` | `0` | Ende des hervorgehobenen Bereichs auf der Schiene (wie TTrackBar); gezeichnet, wenn SelEnd > SelStart. |
| `ShowSelRange` | `Boolean` | `True` | False: Der Bereich aus SelStart/SelEnd wird nicht gezeichnet (wie TTrackBar). |
| `RangeMode` | `Boolean` | `False` | True: Bereichsregler mit zwei Griffen (Position = Anfang, PositionEnd = Ende), z. B. für einen Preisfilter. Klick bewegt den näheren Griff, Tab wechselt den Griff. Nutzung: `TrackBar1.RangeMode := True; TrackBar1.Position := 50; TrackBar1.PositionEnd := 250;` |
| `PositionEnd` | `Integer` | `0` | Ende des Bereichs im RangeMode (zweiter Griff); bleibt immer zwischen Position und Max. Setzt der Code Position dahinter, wandert PositionEnd mit. |
| `ShowFocusRect` | `Boolean` | `True` | True: Bei Tastaturfokus wird der Fokusrahmen bzw. -ring gezeichnet. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `AutoSize` | `Boolean` |  | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |
| `DragKind` | `TDragKind` |  | dkDrag = Drag & Drop, dkDock = Andocken beim Ziehen. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` |
| `ParentBackground` | `Boolean` | `True` | True: Der Hintergrund des Parents scheint durch (transparente Wirkung). |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). |
| `TabStop` | `Boolean` | `True` | True: Das Control ist mit Tab erreichbar. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Position hat sich geändert (Anwender oder Code, nicht beim Laden); der neue Wert ist bereits gesetzt. |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
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
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGTrackBar.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
