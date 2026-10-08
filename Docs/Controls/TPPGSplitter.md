# TPPGSplitter

Palette **PPGlow** - Unit `PPG.Splitter` - Basis `TPPGCustomSplitter`

**Vorbild:** TSplitter

## Unterschiede und Hinweise

- Fenster-Control (TabStop standardmäßig aus) mit `ResizeStyle = rsUpdate` als Vorgabe; in Ruhe unsichtbar, Linie und Griff erst bei Hover/Ziehen/Fokus.
- Pfeiltasten verschieben, wenn der Splitter den Fokus hat.

## Verhalten (aus dem Quelltext)

TPPGSplitter - Ziehgriff zwischen ausgerichteten Controls (Phase 7a).

Verhalten wie TSplitter (DFM-kompatibel: Align, MinSize, AutoSnap,
ResizeStyle, OnCanResize, OnMoved): veraendert die Groesse des Controls,
das auf derselben Seite direkt angrenzt. Zusaetzlich:
- Optik im Preset-Stil: Linie und Griffpunkte erscheinen beim Hover, beim Ziehen in der Fokusfarbe; Dark Mode/Hochkontrast ueber die Tokens.
- Fenster-Control: mit TabStop per Tastatur erreichbar; Pfeile verschieben (Strg = 1 px, sonst 10 logische px), Pos1/Ende = Minimum/Maximum.
- ResizeStyle rsUpdate (Standard) zieht live; rsLine/rsPattern zeigen eine invertierte Linie auf dem Parent, rsNone aendert erst beim Loslassen.
- Esc bricht das Ziehen ab (alte Groesse).

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `MinSize` | `Integer` | `30` | Mindestgröße des angrenzenden Controls in Pixeln (0..100000); kleiner nur per AutoSnap auf 0. |
| `AutoSnap` | `Boolean` | `True` | True: Wird das angrenzende Control kleiner als die Hälfte von MinSize gezogen, klappt es ganz zu (Größe 0), wie bei TSplitter. |
| `Beveled` | `Boolean` | `False` | True: Die Trennlinie ist auch in Ruhe sichtbar; sonst erscheinen Linie und Griffpunkte erst beim Hover (wie TSplitter.Beveled). |
| `ResizeStyle` | `TResizeStyle` | `rsUpdate` | Rückmeldung beim Ziehen: rsUpdate (Standard) ändert live, rsLine/rsPattern zeigen eine Linie auf dem Parent und ändern beim Loslassen, rsNone ändert erst beim Loslassen ohne Linie. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` | `alLeft` | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). |
| `TabStop` | `Boolean` | `False` | True: Das Control ist mit Tab erreichbar. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |
| `Width` | `Integer` | `6` | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnCanResize` | `TCanResizeEvent` `(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean)` | Vor jeder Größenänderung beim Ziehen bzw. per Tastatur; NewSize kann angepasst werden, Accept := False verhindert die Änderung. Nutzung: `if NewSize > 400 then NewSize := 400;` |
| `OnMoved` | `TNotifyEvent` `(Sender: TObject)` | Das Ziehen (oder ein Tastendruck) ist abgeschlossen und die neue Größe gesetzt. Nutzung: Z. B. die Breite für den nächsten Start speichern. |
| `OnPaint` | `TNotifyEvent` `(Sender: TObject)` | Wie TSplitter: wird nach dem eigenen Zeichnen aufgerufen; über Canvas kann zusätzlich gezeichnet werden (nur innerhalb des Ereignisses gültig). |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGSplitter.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
