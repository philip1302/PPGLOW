# TPPGGauge

Palette **PPGlow** - Unit `PPG.Gauge` - Basis `TPPGCustomGauge`

**Vorbild:** TMS FNC Widget Gauge, WinUI RadialGauge

## Unterschiede und Hinweise

- `Min`/`Max`/`Value` sind `Double`. `Min >= Max` wirft zur Laufzeit; beim Laden aus dem DFM wird `Max` korrigiert. `Value` wird still auf den Bereich begrenzt.
- `StartAngle`/`SweepAngle` in Grad, 0 = oben, im Uhrzeigersinn (Vorgabe 270°, halbrund: -90/180).
- `Ranges` färbt die Spur; mit `ValueColorFromRange` nimmt der Wertbogen die Farbe seines Abschnitts an.
- Wertwechsel gleiten über den gemeinsamen Animator; ein Abschalten von `Animation` beendet einen laufenden Wechsel sofort.
- `ReadOnly = True` (Vorgabe): Anzeige ohne Tabstopp. Sonst Schieberegler (Ziehen, Pfeile, Bild, Pos1/Ende); `OnChange` nur bei Anwender-Änderungen.

## Beispiel

```pascal
PPGGauge1.Ranges.Add.EndValue := 60;          // grün (grcSuccess)
with PPGGauge1.Ranges.Add do
begin
  StartValue := 85;
  EndValue := 100;
  Kind := grkError;
end;
PPGGauge1.Value := Auslastung;
```

## Verhalten (aus dem Quelltext)

Dashboard-Bausteine (Phase 10c): TPPGGauge und TPPGKpiTile.

TPPGGauge - Bogenanzeige fuer einen Wert:
- Min/Max/Value (Double), Bogen ueber StartAngle/SweepAngle (0 Grad = oben, im Uhrzeigersinn; Vorgabe 270 Grad, halbrund = -90/180).
- Ranges: farbige Abschnitte der Spur (Signalfarben aus den Tokens). Mit ValueColorFromRange nimmt der Wertbogen die Farbe seines Abschnitts an.
- Zielmarke (ShowTarget/TargetValue), Werttext mit ValueFormat und Units, Beschriftung (Caption) darunter.
- Wertwechsel gleitet ueber den gemeinsamen Animator (ekDecelerate), der Text zaehlt dabei mit. Code setzt Werte ohne OnChange.
- ReadOnly (Vorgabe): reine Anzeige ohne Fokus. Sonst Schieberegler: Ziehen auf dem Bogen, Pfeile/Bild/Pos1/Ende; OnChange nur bei Anwender- Aenderungen.
- Screenreader: Rolle Fortschritt (ReadOnly) bzw. Schieberegler.

TPPGKpiTile - Kennzahl-Kachel:
- Title, Wert (Value/ValueFormat oder freier ValueText) mit Units, Veraenderung (Change/ChangeFormat) mit Trendpfeil: gruen = gut, rot = schlecht (InvertTrend: weniger ist besser).
- Eingebettete Sparkline (SparklineText/SetSparkline) ueber PPGDrawSparkline.
- Flaeche wie ein Container (IPPGContainerRenderer), Hover; Klick, Enter und Leertaste loesen OnClick aus.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `Min` | `Double` |  | Untergrenze der Skala. Muss kleiner als Max sein, sonst EPPGPropertyError; Value wird in den Bereich geklemmt. |
| `Max` | `Double` |  | Obergrenze der Skala. Muss größer als Min sein, sonst EPPGPropertyError; Value wird in den Bereich geklemmt. |
| `Value` | `Double` |  | Angezeigter Wert, geklemmt auf Min..Max. Ein neuer Wert gleitet animiert dorthin, der Text zählt mit. Setzen im Code löst kein OnChange aus. Nutzung: `Gauge.Value := Auslastung;` |
| `StartAngle` | `Integer` | `-135` | Beginn des Bogens in Grad (-360..360); 0 = oben, positiv im Uhrzeigersinn. Vorgabe -135 (mit SweepAngle 270 ein nach unten offener Bogen). Nutzung: Halbrund: `Gauge.StartAngle := -90; Gauge.SweepAngle := 180;` |
| `SweepAngle` | `Integer` | `270` | Länge des Bogens in Grad (10..360; 360 = Vollkreis). |
| `Thickness` | `Integer` | `0` | Strichstärke des Bogens in logischen Pixeln (0..200; 0 = aus der Größe des Controls berechnet). |
| `Ranges` | [TPPGGaugeRanges](types/TPPGGaugeRanges.md) |  | Farbige Abschnitte der Spur (z. B. grün/gelb/rot), je mit Start- und Endwert und Farbe. Mit ValueColorFromRange übernimmt der Wertbogen die Farbe seines Abschnitts. Nutzung: `with Gauge.Ranges.Add do begin StartValue := 80; EndValue := 100; Kind := grkError; end;` |
| `ValueColorFromRange` | `Boolean` | `True` | True: Der Wertbogen nimmt die Farbe des Abschnitts (Ranges) an, in dem der Wert liegt. Gilt nur, solange ValueColor = clDefault. |
| `ShowTarget` | `Boolean` | `False` | True: Eine Zielmarke bei TargetValue auf dem Bogen zeigen. |
| `TargetValue` | `Double` |  | Wert der Zielmarke (sichtbar mit ShowTarget). |
| `ShowValue` | `Boolean` | `True` | True: Werttext (mit ValueFormat und Units) in der Mitte zeigen. |
| `ValueFormat` | `string` |  | FormatFloat-Maske des Werttexts (Vorgabe "0"). Nutzung: `Gauge.ValueFormat := '0.0';` |
| `Units` | `string` |  | Einheit hinter dem Werttext (z. B. „%" oder „km/h"). |
| `ValueColor` | `TColor` | `clDefault` | Feste Farbe des Wertbogens; clDefault = Akzentfarbe bzw. Farbe des Abschnitts (ValueColorFromRange). |
| `ValueStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Werttext: TextColor und Schrift. Ohne eigene Schrift wird fett und passend zur Bogengröße gezeichnet. |
| `ReadOnly` | `Boolean` | `True` | True (Vorgabe): reine Anzeige ohne Fokus. False: Der Bogen wird zum Schieberegler (Ziehen, Pfeile, Bild, Pos1/Ende) und meldet Änderungen über OnChange. |
| `Increment` | `Double` |  | Schrittweite für Pfeiltasten, wenn die Anzeige bedienbar ist (ReadOnly = False); Bild auf/ab ändert um das Zehnfache. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Caption` | `TCaption` |  | Beschriftung. Ein & vor einem Buchstaben macht ihn zur Zugriffstaste (Alt+Buchstabe). Nutzung: `Button1.Caption := '&Speichern';` |
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). |
| `TabStop` | `Boolean` | `False` | True: Das Control ist mit Tab erreichbar. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Anwender hat den Wert geändert (Ziehen auf dem Bogen oder Tastatur, nur mit ReadOnly = False). Setzen von Value im Code löst es nicht aus. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
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

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGGauge.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
