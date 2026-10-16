# TPPGShape

Palette **PPGlow** - Unit `PPG.Shape` - Basis `TGraphicControl`

**Vorbild:** TShape

## Wofür

Eine einfache geometrische Form als Dekoration: Rahmen um eine Gruppe, farbiger Punkt als Statusanzeige, Trennfläche.

## Wann verwenden

- Für Formulare, die bisher `TShape` benutzen: Der DFM-Tausch ist 1:1 (`Shape`, `Brush`, `Pen` heißen und streamen wie in der VCL).
- Für eine Statusanzeige (Kreis grün/rot) mit weichen Kanten, auch bei hoher DPI.

## Unterschiede und Hinweise

- Grafisches Control (kein Fenster), Zeichnen über den Renderer der Suite: Fläche und Rand sind kantengeglättet (GDI+), ohne GDI+ wie bei `TShape`.
- Die Vorgabefarben (`Brush` weiß bzw. Fensterfarbe, `Pen` schwarz) folgen im Dark Mode und im Hochkontrast den Theme-Farben (wie `TPPGLabel`); eigene Farben bleiben. Im hellen Modus sieht die Form mit Vorgabefarben genau wie `TShape` aus. `ThemeColors = False` schaltet das ab.
- Gestrichelte Stifte, Schraffuren und Bitmap-Pinsel zeichnet die VCL wie bei `TShape` (ohne Kantenglättung).
- `stRoundRect`/`stRoundSquare`: Eckenrundung wie `TShape` (ein Achtel der kurzen Seite).

## Beispiel

```pascal
Shape1.Shape := stCircle;
Shape1.Brush.Color := clLime;   // eigene Farbe, bleibt auch im Dark Mode
Shape1.Pen.Style := psClear;
```

## Verhalten (aus dem Quelltext)

TPPGShape - Formen (Rechteck, Quadrat, abgerundet, Ellipse, Kreis).

Grafisches Control wie TShape (kein Fensterhandle) und DFM-kompatibel:
Shape, Brush und Pen heissen und streamen wie in der VCL, damit ein Tausch
im Formular ohne Nacharbeit geht (Build\migrate.ps1).

Mehrwert gegenueber TShape:
- Antialiasing: Fuellung und Rand laufen ueber den Renderer der Suite (GDI+, sonst GDI-Fallback). Ohne GDI+ sieht die Form wie bei TShape aus.
- Theme: Die Vorgabefarben (Brush weiss bzw. Fensterfarbe, Pen schwarz) folgen im Dark Mode und im Hochkontrast den Farben der Suite (TPPGTheme, wie TPPGLabel). Eigene Farben bleiben unveraendert. ThemeColors = False schaltet das ab.
- Im Hellen sieht eine Form mit Vorgabefarben genau wie TShape aus.

Stifte und Pinsel, die der Renderer nicht kann (gestrichelte Stifte,
Schraffuren, Bitmap-Pinsel), zeichnet die VCL wie bei TShape.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Brush` | `TBrush` |  | Füllung (Farbe und Stil, wie TShape). Die Vorgabefarbe (weiß) folgt im Dark Mode dem Theme, eine eigene Farbe bleibt. Nutzung: `Shape1.Brush.Color := clYellow;` Praxis: Für eine Fläche ohne Füllung `Brush.Style := bsClear`; Schraffuren (`bsCross` u. a.) zeichnet die VCL ohne Kantenglättung. |
| `Pen` | `TPen` |  | Rand (Farbe, Breite und Stil, wie TShape). Die Vorgabefarbe (schwarz) folgt im Dark Mode dem Theme, eine eigene Farbe bleibt. Nutzung: `Shape1.Pen.Width := 2; Shape1.Pen.Color := clRed;` Praxis: Für eine Form ohne Rand `Pen.Style := psClear`; gestrichelte Ränder (`psDash` u. a.) zeichnet die VCL ohne Kantenglättung. |
| `Shape` | `TShapeType` | `stRectangle` | Form: Rechteck, Quadrat, abgerundetes Rechteck/Quadrat, Ellipse oder Kreis. Quadrat und Kreis zentrieren sich im Control. Nutzung: `Shape1.Shape := stCircle;` Praxis: Ein Statuspunkt ist ein kleiner Kreis (`Width = Height = 14`), dessen `Brush.Color` Sie je nach Zustand setzen. |
| `ThemeColors` | `Boolean` | `True` | True: Die Vorgabefarben von Brush und Pen folgen Dark Mode und Hochkontrast (wie TPPGLabel). False: immer die eingestellten Farben, wie TShape. Nutzung: `Shape1.ThemeColors := False;` Praxis: Abschalten, wenn die Form im Dark Mode weiß bleiben soll (z. B. als Papiervorschau). |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |
| `DragKind` | `TDragKind` |  | dkDrag = Drag & Drop, dkDock = Andocken beim Ziehen. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
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
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |

Tests: `PPG.Tests.Inventur` (TShapeTests); `PPG.Tests.Streaming` (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGShape.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
