# TPPGBadge

Palette **PPGlow** - Unit `PPG.Feedback` - Basis `TPPGCustomBadge`

**Vorbild:** WinUI InfoBadge

## Unterschiede und Hinweise

- Zahl (mit `MaxValue` → „99+“), Punkt oder kurzer Text; keine Symbol-Variante.

## Verhalten (aus dem Quelltext)

Rueckmelde-Controls (Phase 7a): TPPGBadge, TPPGProgressRing, TPPGInfoBar.

- TPPGBadge: Punkt, Zahl (99+) oder kurzer Text auf Akzent- bzw. Signalfarbe (Tokens; Dark Mode automatisch). Zeichnet ueber IPPGItemRenderer.DrawBadge wie die Plaketten in Listen.
- TPPGProgressRing: bestimmt (Bogen 0-100 %) oder unbestimmt (rotierender Bogen mit wechselnder Laenge). Die Endlosschleife laeuft ueber den gemeinsamen Animator und nur, solange das Control sichtbar ist; ohne Animationen steht ein Viertelbogen.
- TPPGInfoBar: Hinweisleiste Info/Erfolg/Warnung/Fehler mit Symbol, Titel, Text (Markup), optionalem Aktions-Button und Schliessen-Knopf. Button und Knopf sind gezeichnet (keine Kind-Fenster); Tastatur: Pfeile wechseln, Enter/Leertaste loest aus, Esc schliesst. Screenreader: Rolle Alarm, Meldung beim Oeffnen.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `Kind` | `TPPGBadgeKind` | `bkNumber` | Inhalt der Plakette: bkNumber zeigt Value (über MaxValue als „99+"), bkDot nur einen Punkt, bkText den Text aus Caption. Werte: `bkNumber`, `bkDot`, `bkText`. Nutzung: `Badge1.Kind := bkText; Badge1.Caption := 'Neu';` |
| `Value` | `Integer` | `0` | Angezeigte Zahl bei Kind = bkNumber. Nutzung: `Badge1.Value := UngeleseneMails;` |
| `MaxValue` | `Integer` | `99` | Größte angezeigte Zahl; größere Werte erscheinen als „MaxValue+" (z. B. „99+"). 0 = ohne Grenze. |
| `Severity` | `TPPGBadgeSeverity` | `bsvAccent` | Farbe der Plakette aus den Theme-Tokens: Akzent, Erfolg (grün), Warnung (gelb), Fehler (rot) oder neutral (dezentes Grau). Folgt automatisch Dark Mode und Markenfarbe. Werte: `bsvAccent`, `bsvSuccess`, `bsvWarning`, `bsvError`, `bsvNeutral`. Nutzung: `Badge1.Severity := bsvError;` für ungelesene Fehlermeldungen. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Caption` | `TCaption` |  | Beschriftung. Ein & vor einem Buchstaben macht ihn zur Zugriffstaste (Alt+Buchstabe). Nutzung: `Button1.Caption := '&Speichern';` |
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGBadge.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
