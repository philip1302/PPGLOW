# TPPGStatusBar

Palette **PPGlow** - Unit `PPG.StatusBar` - Basis `TPPGCustomControl`

**Vorbild:** TStatusBar

## Unterschiede und Hinweise

- DFM wie `TStatusBar` (`Panels`, `SimplePanel`); zusätzlich Panel-Arten Fortschritt und Plakette.
- Eigene Schrift schaltet `UseSystemFont` ab (wie `TStatusBar`).

## Anpassung

- Je Feld `Color`, `TextColor`, `FontStyle`; `BarStyle` für die Leiste.

## Verhalten (aus dem Quelltext)

TPPGStatusBar - Statusleiste (Phase 7c).

- Panels wie TStatusBar (Text, Width, Alignment, Bevel, Style); Bevel <> pbNone zeichnet eine Trennlinie. Zusaetzlich Kind: Text (optional mit Markup, AllowMarkup), Fortschrittsbalken (Progress 0..100) oder Plakette (BadgeCount); Bild aus Images (ImageIndex). Das letzte Panel fuellt den Rest, wenn seine Breite nicht reicht.
- SimplePanel/SimpleText, AutoHint (Hinweise der Anwendung im ersten Panel bzw. SimpleText, ueber THintAction wie TStatusBar).
- SizeGrip: Griff unten rechts (RTL links); Ziehen veraendert die Groesse des Formulars, nur wenn es sizable und nicht maximiert ist.
- psOwnerDraw: OnDrawPanel mit Canvas (TCanvas ueber dem Zeichenpuffer).
- DFM-nah zu TStatusBar (Panels, SimplePanel, SimpleText, SizeGrip, AutoHint, UseSystemFont, OnDrawPanel).
- Screenreader: Statusleiste; Kinder sind die Panels (Text/Fortschritt).

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). |
| `Panels` | [TPPGStatusPanels](types/TPPGStatusPanels.md) |  | Felder der Leiste (Text, Fortschritt oder Plakette, mit Breite, Ausrichtung, Bild und Trennlinie). Das letzte Panel füllt den Rest. Nutzung: `with PPGStatusBar1.Panels.Add do begin Kind := spkProgress; Progress := 40; Width := 120; end;` |
| `SimplePanel` | `Boolean` | `False` | True: Statt der Panels zeigt die Leiste nur SimpleText über die ganze Breite. |
| `SimpleText` | `string` |  | Text bei SimplePanel = True (bzw. bei AutoHint ohne Panels). |
| `SizeGrip` | `Boolean` | `True` | True: Griff unten rechts (RTL links) zum Vergrößern des Formulars; wirkt nur bei veränderbarem, nicht maximiertem Formular. |
| `AutoHint` | `Boolean` | `False` | True: Hinweise der Anwendung (Langtext des Hints, Teil nach dem senkrechten Strich) erscheinen automatisch im ersten Panel bzw. in SimpleText; mit OnHint übernimmt die Anwendung die Anzeige. |
| `UseSystemFont` | `Boolean` | `True` | True: Die Leiste nutzt die Statusleisten-Schrift von Windows; wird False, sobald Font geändert wird. |
| `Style` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Aussehen der Leiste: Fläche, Text, Trennlinien (BorderColor) und Schrift; clDefault = vom Preset. |
| `AllowMarkup` | `Boolean` | `False` | True: Texte der Panels dürfen Mini-Markup enthalten (<b>, <i>, <color=...>). Nutzung: `PPGStatusBar1.Panels[0].Text := 'Status: <b>verbunden</b>';` |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` | `alBottom` | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. |
| `ParentFont` | `Boolean` | `False` | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. |
| `OnDrawPanel` | `TPPGDrawPanelEvent` `(StatusBar: TPPGStatusBar; Panel: TPPGStatusPanel; const Rect: TRect)` | Eigenes Zeichnen eines Panels mit Style = psOwnerDraw: Panel und Rect werden übergeben, gezeichnet wird auf StatusBar.Canvas. |
| `OnHint` | `TNotifyEvent` `(Sender: TObject)` | Mit AutoHint: Ein neuer Hinweis der Anwendung liegt vor (Application.Hint); die Anwendung zeigt ihn selbst an. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnResize` | `TNotifyEvent` `(Sender: TObject)` | Nach einer Größenänderung. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGStatusBar.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
