# TPPGScrollBox

Palette **PPGlow** - Unit `PPG.Panel` - Basis `TPPGCustomPanel`

Wie TScrollBox: AutoScroll = True, ohne Beschriftung; BorderStyle bsNone zeichnet weder Rahmen noch Flaeche (Hintergrund des Parents).

**Vorbild:** TScrollBox (DFM gleich: `AutoScroll`, `HorzScrollBar`, `VertScrollBar`, `BorderStyle`)

## Unterschiede und Hinweise

- Ein `TPPGPanel` mit `AutoScroll = True` und ohne Beschriftung; alles, was `TPPGPanel` kann (Preset, Rundung, Schatten), gilt auch hier.
- Leisten in PPGlow-Optik mit weichem Scrollen; das Mausrad wirkt auch über Kind-Controls, die es nicht selbst nutzen.
- Tab zu einem verdeckten Kind holt es ins Bild (`ScrollInView`), auch wenn es in einem Unter-Panel liegt.
- `BorderStyle = bsSingle` zeichnet den dünnen Rahmen des Presets statt des 3D-Rahmens der VCL.

## Beispiel

```pascal
PPGScrollBox1.VertScrollBar.Increment := 24;
PPGScrollBox1.ScrollInView(PPGEdit7);
```

## Verhalten (aus dem Quelltext)

TPPGPanel - Container-Flaeche in der Optik des Presets (abgerundet,
Rahmen, im Classic-Preset mit dezentem Verlauf).

Migration von TPanel: Caption, Alignment, VerticalAlignment, ShowCaption,
Padding und die Bevel-Properties bleiben gueltig (Bevels zeichnet nur die
VCL selbst bei BevelKind <> bkNone). Color bestimmt nur den Hintergrund
hinter den abgerundeten Ecken (ParentBackground = False); die Flaeche kommt
aus Appearance.Normal.

Scrollen (Phase 18d): AutoScroll, HorzScrollBar und VertScrollBar wie
TScrollingWinControl. Gescrollt werden echte Kind-Fenster (Lage wird
verschoben, Neuzeichnen per WM_SETREDRAW gebuendelt), Rahmen und
Beschriftung des Panels bleiben stehen. Die Leisten liegen in einem
schmalen Streifen am Rand (Kind-Fenster lassen sich nicht ueberlagern) und
kommen vom Scroll-Renderer des Presets wie bei Liste und Grid. Mausrad (auch
ueber Kind-Controls, die es nicht nutzen: Windows reicht es weiter),
weiches Scrollen, Tab zu einem verdeckten Kind holt es ins Bild
(ScrollInView). TPPGScrollBox ist ein Panel mit AutoScroll = True und
BorderStyle wie TScrollBox.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `RoundedCorners` | `TPPGCorners` | `[pcTopLeft, pcTopRight, pcBottomRight, pcBottomLeft]` | Welche Ecken gerundet sind; die übrigen werden eckig. Für Button-Gruppen und Segment-Schalter: linker Button [pcTopLeft, pcBottomLeft], mittlere [], rechter [pcTopRight, pcBottomRight]. Menge aus: `pcTopLeft`, `pcTopRight`, `pcBottomRight`, `pcBottomLeft`. Nutzung: `PPGButton2.RoundedCorners := [];` |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `AutoScroll` | `Boolean` | `True` | Scrollleisten erscheinen, sobald Kind-Controls über den Rand hinausragen, wie bei TScrollBox. Das Mausrad scrollt auch über Kind-Controls, Tab zu einem verdeckten Feld holt es ins Bild. Nutzung: `Panel1.AutoScroll := True;` |
| `HorzScrollBar` | [TPPGPanelScrollBar](types/TPPGPanelScrollBar.md) |  | Waagerechte Scrollleiste: Sichtbarkeit, Range, Schrittweite, Position, weiches Scrollen. |
| `VertScrollBar` | [TPPGPanelScrollBar](types/TPPGPanelScrollBar.md) |  | Senkrechte Scrollleiste: Sichtbarkeit, Range, Schrittweite, Position, weiches Scrollen. Nutzung: `Box.VertScrollBar.Increment := 24;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle = dünner Rahmen wie TScrollBox (Vorgabe), bsNone = ohne Rahmen. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `BevelEdges` | `TBevelEdges` |  | Kanten, an denen der VCL-Rahmen (Bevel) gezeichnet wird. Nur wirksam mit BevelKind <> bkNone. |
| `BevelInner` | `TBevelCut` | `bvNone` | Innere VCL-Rahmenkante (bvNone, bvLowered, bvRaised, bvSpace). Meist bvNone lassen; die PPGlow-Optik kommt aus Appearance. |
| `BevelKind` | `TBevelKind` |  | Art des zusätzlichen VCL-Rahmens. Für die PPGlow-Optik bkNone lassen. |
| `BevelOuter` | `TBevelCut` | `bvRaised` | Äußere VCL-Rahmenkante. Für die PPGlow-Optik bvNone lassen. |
| `BevelWidth` | `TBevelWidth` |  | Breite der VCL-Rahmenkanten in Pixeln. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `BorderWidth` | `TBorderWidth` |  | Innerer Rand in Pixeln zwischen Kante und Inhalt bzw. Kind-Controls. |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `DockSite` | `Boolean` |  | True: Andere Controls können per Drag & Drop hier angedockt werden. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |
| `DragKind` | `TDragKind` |  | dkDrag = Drag & Drop, dkDock = Andocken beim Ziehen. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `Padding` | `TPadding` |  | Innenabstand: Kind-Controls mit Align halten diesen Abstand zum Rand. Nutzung: `Panel1.Padding.SetBounds(12, 12, 12, 12);` |
| `ParentBackground` | `Boolean` | `True` | True: Der Hintergrund des Parents scheint durch (transparente Wirkung). |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). |
| `TabStop` | `Boolean` | `False` | True: Das Control ist mit Tab erreichbar. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnAlignInsertBefore` | `TAlignInsertBeforeEvent` `(Sender: TWinControl; C1, C2: TControl): Boolean` | Bei Align = alCustom: entscheidet die Reihenfolge zweier Kind-Controls. |
| `OnAlignPosition` | `TAlignPositionEvent` `(Sender: TWinControl; Control: TControl; var NewLeft, NewTop, NewWidth, NewHeight: Integer; var AlignRect: TRect; AlignInfo: TAlignInfo)` | Bei Align = alCustom: liefert die Position eines Kind-Controls. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. |
| `OnDockDrop` | `TDockDropEvent` `(Sender: TObject; Source: TDragDockObject; X, Y: Integer)` | Ein Control wurde hier angedockt. |
| `OnDockOver` | `TDockOverEvent` `(Sender: TObject; Source: TDragDockObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Control wird über diesem Dock-Ziel gezogen; Accept steuert, ob es andocken darf. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnGetSiteInfo` | `TGetSiteInfoEvent` `(Sender: TObject; DockClient: TControl; var InfluenceRect: TRect; MousePos: TPoint; var CanDock: Boolean)` | Andocken: liefert das Zielrechteck für ein Control, das hier andocken will. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnResize` | `TNotifyEvent` `(Sender: TObject)` | Nach einer Größenänderung. |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnUnDock` | `TUnDockEvent` `(Sender: TObject; Client: TControl; NewTarget: TWinControl; var Allow: Boolean)` | Ein angedocktes Control wird gelöst; Allow steuert, ob das erlaubt ist. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGScrollBox.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
