# TPPGImage

Palette **PPGlow** - Unit `PPG.Image` - Basis `TGraphicControl`

**Vorbild:** TImage

## Wofür

Zeigt ein Bild an: Logo, Symbol, Foto, Vorschau. Das Bild kommt aus `Picture` (BMP, PNG, JPEG, GIF, TIFF, ICO, WMF/EMF) oder aus einer Bildliste (`Images` mit `ImageIndex` bzw. `ImageName`).

## Wann verwenden

- Für Formulare, die bisher `TImage` benutzen: Der DFM-Tausch ist 1:1 (`Picture`, `Stretch`, `Proportional`, `Center`, `Transparent`, `AutoSize` und `IncrementalDisplay` heißen und streamen wie in der VCL; `DestRect` und `Canvas` gibt es auch).
- Wenn ein Bild im Dark Mode anders aussehen soll (`PictureDark` bzw. `ImageIndexDark`/`ImageNameDark`) oder ein Symbol aus einer `TImageCollection` über den Namen kommen soll.
- Wenn das Bild einen Rand in der Farbe des Themes braucht (`BorderStyle = bsSingle`).

## Unterschiede und Hinweise

- Grafisches Control (kein Fenster) wie `TImage`; die Platzierung (`Stretch`, `Proportional`, `Center`) rechnet genau wie `TImage.DestRect`.
- Bildliste: Das Bild wird in der Größe der Liste gezeichnet (die Liste skaliert sich selbst mit der DPI) und mit `Stretch`/`Proportional` eingepasst. Ein `ImageName` wird beim Laden in den Index aufgelöst; gespeichert wird nur der Name, nicht der Index.
- Dunkelmodus: Im Dark Mode der Suite ersetzt `PictureDark` bzw. das Listenbild `ImageIndexDark`/`ImageNameDark` das helle Bild. Ohne Eintrag bleibt das helle Bild. Im Hochkontrast gilt immer das helle Bild.
- `DpiScaling = True` vergrößert Bilder aus `Picture` mit der DPI des Controls (natürliche Größe und `AutoSize`). Vorgabe aus wie bei `TImage`.
- Deaktiviert (`Enabled = False`) zeigt das Bild grau und blasser, bei jeder Bildart und auch mit Alpha.
- Rand: `BorderStyle = bsSingle` zeichnet einen Rand in der Randfarbe des Themes (Dark Mode, Hochkontrast, deaktiviert); `AutoSize` rechnet ihn mit ein.
- PNG, JPEG, GIF und TIFF decodiert das `TWICImage` der VCL, deshalb braucht `PPGlowR` das Paket `vclimg` nicht. Wer ein `Picture` mit `TPngImage` oder `TJPEGImage` in der DFM hat, bindet die Unit `Vcl.Imaging.pngimage` bzw. `Vcl.Imaging.jpeg` wie bei `TImage` selbst ein.
- Nicht übernommen: animierte GIFs (es wird das erste Bild gezeigt). `IncrementalDisplay` ist nur für die Kompatibilität da und wirkt nicht.

## Beispiel

```pascal
Image1.Picture.LoadFromFile('logo.png');
Image1.Stretch := True;
Image1.Proportional := True;
Image1.Center := True;
Image1.PictureDark.LoadFromFile('logo-hell.png');  // im Dark Mode
Image1.BorderStyle := bsSingle;
```

## Verhalten (aus dem Quelltext)

TPPGImage - Bildanzeige (Ersatz fuer TImage), dazu die gemeinsame Zeichen-
und Quellenlogik (TPPGImageView), die auch TPPGDBImage nutzt.

Grafisches Control wie TImage (kein Fensterhandle) und DFM-kompatibel:
Picture, Stretch, Proportional, Center, Transparent, AutoSize und
IncrementalDisplay heissen und streamen wie in der VCL, damit ein Tausch im
Formular ohne Nacharbeit geht (Build\migrate.ps1).

Mehrwert gegenueber TImage:
- Bildlisten: Images/ImageIndex/ImageName wie bei den anderen Controls (TImageCollection/TVirtualImageList ab 10.4). Eine Bildliste skaliert sich selbst mit der DPI; das Bild wird in ihrer Groesse gezeichnet, mit Stretch und Proportional eingepasst.
- Dunkelmodus: PictureDark bzw. ImageIndexDark/ImageNameDark ersetzen das Bild im Dark Mode (ohne Eintrag bleibt das helle Bild).
- Rahmen: BorderStyle = bsSingle zeichnet einen Rand in der Randfarbe des Themes (Dark Mode, Hochkontrast, deaktiviert).
- Deaktiviert: Enabled = False zeigt das Bild grau und blasser.
- DpiScaling: Bilder aus Picture werden mit der DPI des Controls vergroessert (natuerliche Groesse, AutoSize); Vorgabe aus wie bei TImage.

Formate: BMP, ICO und WMF/EMF liest die VCL selbst, PNG, JPEG, GIF und TIFF
das TWICImage der VCL. Es wird kein Vcl.Imaging.* benutzt, damit PPGlowR
das Paket vclimg nicht braucht.

Zeichnen: Grafiken laufen ueber Canvas.StretchDraw wie bei TImage (PNG mit
Alpha, JPEG, GIF, TIFF ueber WIC, Icon, Metafile). Nur die deaktivierte Darstellung und
skalierte Bildlisten-Bilder werden vorher in ein Bild mit Alpha gerechnet
(zweimal auf Schwarz und Weiss gezeichnet), das geht mit jeder Grafikart.

Nicht uebernommen: animierte GIFs (das erste Bild wird gezeigt).

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Picture` | `TPicture` |  | Das angezeigte Bild (BMP, PNG, JPEG, GIF, TIFF, ICO, WMF/EMF), wie bei TImage. Nutzung: `Image1.Picture.LoadFromFile('logo.png');` Praxis: Das Standardbild. Mit `PictureDark` zusammen für Logos, die auf dunklem Grund anders aussehen müssen. |
| `PictureDark` | `TPicture` |  | Bild für den Dark Mode; leer = das helle Bild bleibt. Nutzung: `Image1.PictureDark.LoadFromFile('logo-hell.png');` Praxis: Ein dunkles Logo auf dunklem Grund verschwindet; hier steht die helle Fassung. Im Hochkontrast gilt immer `Picture`. |
| `Images` | `TCustomImageList` |  | Bildliste (z. B. TVirtualImageList), aus der das Bild kommt, wenn Picture leer ist. Praxis: Für Symbole aus einer zentralen `TImageCollection`: eine Liste, mehrere Images am Formular. |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Nummer des Bilds in Images; -1 = keins. Bei Listen mit Namen wird nur ImageName gespeichert. Nutzung: `Image1.ImageIndex := 3;` |
| `ImageName` | `TImageName` |  | Name des Bilds in Images (ab Delphi 10.4, Liste mit Namen). Unbekannte Namen zeigen kein Bild. Nutzung: `Image1.ImageName := 'Warnung';` Praxis: Robust gegen Umsortieren der Liste. |
| `ImageIndexDark` | `TPPGImageIndex` | `-1` | Nummer des Bilds in Images für den Dark Mode; -1 = das helle Bild bleibt. |
| `ImageNameDark` | `TImageName` |  | Name des Bilds in Images für den Dark Mode. Nutzung: `Image1.ImageNameDark := 'Warnung-hell';` |
| `Stretch` | `Boolean` | `False` | True: das Bild füllt das Control (mit Proportional im Seitenverhältnis), wie bei TImage. |
| `Proportional` | `Boolean` | `False` | True: das Bild wird im Seitenverhältnis eingepasst; ohne Stretch nur verkleinert, wenn es nicht passt. Praxis: Für Fotos in Feldern fester Größe: `Stretch` und `Proportional` zusammen. |
| `Center` | `Boolean` | `False` | True: das Bild liegt in der Mitte des Controls. |
| `Transparent` | `Boolean` | `False` | True: die Transparenzfarbe von Bitmaps wird nicht gezeichnet (PNG und GIF haben ihre eigene Transparenz). |
| `DpiScaling` | `Boolean` | `False` | True: Bilder aus Picture werden mit der DPI des Controls vergrößert (natürliche Größe, AutoSize). Bildlisten skalieren sich selbst. Praxis: Einschalten für Symbole, die bei 150 % Skalierung nicht winzig bleiben sollen; Fotos mit Stretch brauchen es nicht. |
| `BorderStyle` | `TBorderStyle` | `bsNone` | bsSingle: Rand in der Randfarbe des Themes (Dark Mode, Hochkontrast, deaktiviert). Nutzung: `Image1.BorderStyle := bsSingle;` |
| `IncrementalDisplay` | `Boolean` | `False` | Ohne Wirkung; nur für die Kompatibilität mit TImage da. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `AutoSize` | `Boolean` |  | True: das Control nimmt die Größe des Bilds an (mit Rahmen). |
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
| `OnProgress` | `TProgressEvent` | Fortschritt beim Laden des Bilds, wie bei TImage. |
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

Tests: `PPG.Tests.Image` (TImageTests); `PPG.Tests.Streaming` (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGImage.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
