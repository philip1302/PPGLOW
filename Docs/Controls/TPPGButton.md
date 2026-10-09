# TPPGButton

Palette **PPGlow** - Unit `PPG.Button` - Basis `TPPGCustomButton`

**Vorbild:** TButton, TBitBtn, TSpeedButton, TMS TAdvGlowButton

## Unterschiede und Hinweise

- Ein Fenster-Control (auch als Ersatz für `TSpeedButton`): bekommt den Fokus, wenn `TabStop` gesetzt ist.
- Umschalt-Gruppen wie `TSpeedButton`: `GroupIndex` + `Down` + `AllowAllUp`.
- Split-Button: `Style = bsSplitButton` mit `DropDownMenu`; Klick auf den Pfeil öffnet das Menü ohne `OnClick`.
- Bilder kommen aus `Images`/`ImageIndex` (ab 10.4 auch `ImageName`), nicht aus `Glyph`.

## Anpassung

- `Alignment` und `Margin` (wie `TBitBtn`) für die Lage von Bild und Text.
- Bilder je Zustand: `HotImageIndex`, `DisabledImageIndex`, `PressedImageIndex` (bzw. `…ImageName` ab 10.4); `ImageTint = itTextColor` färbt einfarbige Symbole in der Textfarbe des Zustands.
- `RoundedCorners` (Segment-Buttons, Button-Gruppen) und `Shadow` (Elevation).
- Schriftstil je Zustand über `Appearance.Hot.FontStyle` usw.; `Appearance.Focused` und `Appearance.Dark` für Fokus- und Dunkel-Farben.

## Beispiel

```pascal
PPGButton1.Caption := '&Speichern';
PPGButton1.ModalResult := mrOk;
PPGButton1.Default := True;
```

## Verhalten (aus dem Quelltext)

TPPGButton - Glow-Button mit Bild, ModalResult, Default/Cancel,
Toggle-Gruppen (GroupIndex/Down), DropDownMenu und Action-Unterstuetzung.

Stolpersteine:
- CS_DBLCLKS wird entfernt: sonst wird bei schnellem Doppelklick der zweite Klick als DblClick geliefert und "verschluckt".
- Default/Cancel folgen exakt der Logik von TButton (CM_FOCUSCHANGED / CM_DIALOGKEY), damit gemischte Formulare konsistent reagieren.
- GroupIndex wird vor Down gestreamt (Deklarationsreihenfolge!).
- Gruppen-Benachrichtigung nutzt eine EIGENE registrierte Nachricht statt CM_BUTTONPRESSED: TSpeedButton castet LParam von CM_BUTTONPRESSED blind auf TSpeedButton und wuerde bei gleichem GroupIndex unseren Speicher als TSpeedButton lesen/schreiben.
- Split-Button: Das Menue oeffnet beim Druecken auf den Pfeil (wie Windows). csClicked wird dabei entfernt, damit beim Loslassen KEIN OnClick folgt.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Index des Bildes in Images; -1 = kein Bild. Nutzung: `PPGButton1.Images := ImageList1; PPGButton1.ImageIndex := 3;` |
| `ImageName` | `TImageName` |  | Name des Bildes in einer TVirtualImageList bzw. TImageCollection (ab Delphi 10.4). Robust gegen Umsortieren; ein unbekannter Name ergibt „kein Bild". |
| `HotImageIndex` | `TPPGImageIndex` | `-1` | Bild, solange die Maus über dem Control ist; -1 = wie ImageIndex. |
| `DisabledImageIndex` | `TPPGImageIndex` | `-1` | Bild im deaktivierten Zustand; -1 = ImageIndex grau dargestellt. |
| `PressedImageIndex` | `TPPGImageIndex` | `-1` | Bild beim Drücken bzw. im eingerasteten Zustand (Down); -1 = wie in Ruhe bzw. Hover. |
| `HotImageName` | `TImageName` |  | Wie HotImageIndex, aber per Name (TVirtualImageList, ab 10.4). |
| `DisabledImageName` | `TImageName` |  | Wie DisabledImageIndex, aber per Name (TVirtualImageList, ab 10.4). |
| `PressedImageName` | `TImageName` |  | Wie PressedImageIndex, aber per Name (TVirtualImageList, ab 10.4). |
| `ImageTint` | `TPPGImageTint` | `itNone` | itTextColor färbt das Bild einfarbig in der Textfarbe des aktuellen Zustands. Ideal für einfarbige Symbole (SVG, Icon-Fonts), die so Hover, Dark Mode und Deaktiviert automatisch folgen. Werte: `itNone`, `itTextColor`. Nutzung: `PPGButton1.ImageTint := itTextColor;` |
| `ImagePosition` | `TPPGImagePosition` | `ipLeft` | Lage des Bildes zum Text: links, rechts, oben oder unten. Werte: `ipLeft`, `ipRight`, `ipTop`, `ipBottom`. |
| `Spacing` | `Integer` | `4` | Abstand zwischen Bild und Text in logischen Pixeln (wird mit der DPI skaliert). |
| `Alignment` | `TAlignment` | `taCenter` | Lage von Bild und Text im Button: taCenter (wie TButton), taLeftJustify oder taRightJustify. Bei RTL wird links/rechts gespiegelt. Nutzung: `PPGButton1.Alignment := taLeftJustify;` für Menü-artige Buttons mit Symbol links. |
| `Margin` | `Integer` | `-1` | Fester Abstand von Bild und Text zum Rand in logischen Pixeln (wie TBitBtn.Margin), -1..1000. -1 = nach Alignment ohne festen Abstand; ein Wert ≥ 0 richtet bei Alignment = taCenter links aus. Nutzung: `PPGButton1.Margin := 12;` |
| `RoundedCorners` | `TPPGCorners` | `[pcTopLeft, pcTopRight, pcBottomRight, pcBottomLeft]` | Welche Ecken gerundet sind; die übrigen werden eckig. Für Button-Gruppen und Segment-Schalter: linker Button [pcTopLeft, pcBottomLeft], mittlere [], rechter [pcTopRight, pcBottomRight]. Menge aus: `pcTopLeft`, `pcTopRight`, `pcBottomRight`, `pcBottomLeft`. Nutzung: `PPGButton2.RoundedCorners := [];` |
| `Shadow` | [TPPGShadow](types/TPPGShadow.md) |  | Schatten unter der Fläche (Elevation): Größe, Versatz, Farbe, Deckkraft. Die Fläche wird um den Platz für den Schatten kleiner; im Hochkontrast entfällt er. Nutzung: `PPGButton1.Shadow.Size := 6; PPGButton1.Shadow.Opacity := 80;` |
| `WordWrap` | `Boolean` | `False` | True: Die Beschriftung bricht um; mit AutoSize wächst dann die Höhe statt der Breite. |
| `ShowFocusRect` | `Boolean` | `True` | True: Bei Tastaturfokus wird der Fokusrahmen bzw. -ring gezeichnet. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `ModalResult` | `TModalResult` | `0` | Ergebnis für modale Formulare: Ein Klick setzt ModalResult des Formulars und schließt es (z. B. mrOk, mrCancel). mrNone = kein Schließen. Nutzung: `btnOK.ModalResult := mrOk; if Form2.ShowModal = mrOk then ...` |
| `Default` | `Boolean` | `False` | True: Enter im Formular löst diesen Button aus (wie TButton.Default), solange kein anderer Button den Fokus hat. |
| `Cancel` | `Boolean` | `False` | True: Esc im Formular löst diesen Button aus (wie TButton.Cancel), meist zusammen mit ModalResult = mrCancel. |
| `Style` | `TPPGButtonStyle` | `pbsPushButton` | pbsPushButton = normaler Button; pbsSplitButton = Button mit abgetrenntem Pfeilteil: Körper löst OnClick aus, Pfeil öffnet DropDownMenu. Werte: `pbsPushButton`, `pbsSplitButton`. |
| `DropDownMenu` | `TPopupMenu` |  | Menü zum Button. Mit Style = pbsSplitButton öffnet der Pfeilteil (bzw. Alt+↓ oder F4) das Menü; bei einem normalen Button erscheint ein Pfeil, und das Menü öffnet nach OnClick. Nutzung: `PPGButton1.Style := pbsSplitButton; PPGButton1.DropDownMenu := PopupMenu1;` |
| `GroupIndex` | `Integer` | `0` | Gruppennummer für Toggle-Buttons: Buttons mit gleichem GroupIndex (> 0) im selben Parent verhalten sich wie Optionsfelder. 0 = kein Toggle. |
| `AllowAllUp` | `Boolean` | `False` | Bei Toggle-Gruppen (GroupIndex > 0): True erlaubt, dass auch der gedrückte Button per Klick wieder ausrastet, sodass keiner der Gruppe gedrückt ist. |
| `Down` | `Boolean` |  | Eingerastet (Toggle-Button). Wirkt mit GroupIndex > 0: In derselben Gruppe ist höchstens einer gedrückt; ohne Gruppe nur bei AllowAllUp schaltbar. Optik aus Appearance.Down bzw. PressedImageIndex. Nutzung: `btnFett.GroupIndex := 1; btnFett.AllowAllUp := True; btnFett.Down := True;` |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Action` | `TBasicAction` |  | Verknüpft das Control mit einer Action (TActionList/TActionManager). Beschriftung, Hint, Bild, Enabled, Checked und OnClick kommen dann aus der Action. Nutzung: `Button1.Action := actSpeichern;` |
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `AutoSize` | `Boolean` |  | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Caption` | `TCaption` |  | Beschriftung. Ein & vor einem Buchstaben macht ihn zur Zugriffstaste (Alt+Buchstabe). Nutzung: `Button1.Caption := '&Speichern';` |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |
| `DragKind` | `TDragKind` |  | dkDrag = Drag & Drop, dkDock = Andocken beim Ziehen. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `ParentBackground` | `Boolean` | `True` | True: Der Hintergrund des Parents scheint durch (transparente Wirkung). |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). |
| `TabStop` | `Boolean` | `True` | True: Das Control ist mit Tab erreichbar. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnDropDownClick` | `TNotifyEvent` `(Sender: TObject)` | Klick auf den Pfeilteil eines Split-Buttons (bzw. Alt+↓/F4), vor dem Öffnen von DropDownMenu. Hier kann das Menü noch angepasst oder eine eigene Auswahl gezeigt werden. |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
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
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGButton.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
