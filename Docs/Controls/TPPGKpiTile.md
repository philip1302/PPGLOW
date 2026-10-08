# TPPGKpiTile

Palette **PPGlow** - Unit `PPG.Gauge` - Basis `TPPGCustomKpiTile`

**Vorbild:** Dashboard-Kacheln (Power BI „Card“, TMS FNC Tile)

## Unterschiede und Hinweise

- Wert über `Value` + `ValueFormat` oder frei über `ValueText`; `Units` wird mit Leerzeichen angehängt.
- Trendpfeil und Farbe aus `Change`: steigend = Erfolg, fallend = Fehler; `InvertTrend` dreht das um (z. B. Fehlerquote).
- Eingebettete Sparkline über `SparklineText` bzw. `SetSparkline`; sie entfällt, wenn die Kachel zu niedrig ist.
- Klick, Leertaste und Enter lösen `OnClick` aus. Mit `OnClick` meldet sich die Kachel beim Screenreader als Schaltfläche.

## Beispiel

```pascal
PPGKpiTile1.Title := 'Retourenquote';
PPGKpiTile1.ValueText := FormatFloat('0.0', Quote) + ' %';
PPGKpiTile1.Change := Quote - QuoteVormonat;
PPGKpiTile1.InvertTrend := True;
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
| `Title` | `string` |  | Überschrift der Kachel (z. B. „Umsatz Oktober"). |
| `TitleStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Titel: TextColor und Schrift. |
| `Value` | `Double` |  | Die Kennzahl; angezeigt mit ValueFormat und Units, sofern ValueText leer ist. Nutzung: `Kpi.Value := 128450; Kpi.Units := '€';` |
| `ValueText` | `string` |  | Freier Text statt Value, z. B. „n/a" oder „3:45 h"; leer = Value formatiert anzeigen. |
| `ValueStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Wert: TextColor und Schrift. Ohne eigene Schrift wird fett und passend zur Kachelgröße gezeichnet. |
| `ValueFormat` | `string` |  | FormatFloat-Maske des Werts (Vorgabe "#,##0"). |
| `Units` | `string` |  | Einheit hinter dem Wert (z. B. „€" oder „Stk."). |
| `Change` | `Double` |  | Veränderung zum Vergleichszeitraum als Anteil (0,052 = +5,2 % mit der Vorgabe-Maske). Positiv zeigt einen grünen Pfeil nach oben, negativ einen roten nach unten (umgekehrt mit InvertTrend). Nutzung: `Kpi.Change := (Umsatz - UmsatzVorjahr) / UmsatzVorjahr;` |
| `ChangeFormat` | `string` |  | FormatFloat-Maske der Veränderung mit Abschnitten für positiv;negativ;null (Vorgabe "+0.0%;-0.0%;0.0%"; % multipliziert mit 100). |
| `ShowChange` | `Boolean` | `True` | True: Die Veränderungszeile mit Trendpfeil zeigen. |
| `InvertTrend` | `Boolean` | `False` | True: Sinkende Werte gelten als gut (grün), steigende als schlecht – z. B. für Fehlerquote oder Kosten. |
| `SparklineKind` | `TPPGSparklineKind` | `skArea` | Art des eingebetteten Verlaufs (Linie, Fläche, Säulen, Gewinn/Verlust); Vorgabe Fläche. Werte: `skLine`, `skArea`, `skColumn`, `skWinLoss`. |
| `ShowSparkline` | `Boolean` | `True` | True: Den kleinen Verlauf (SparklineText) unten in der Kachel zeigen. |
| `SparklineText` | `string` |  | Werte des eingebetteten Verlaufs als Text, getrennt durch Semikolon, Punkt als Dezimaltrenner; im Code auch über SetSparkline. Nutzung: `Kpi.SparklineText := '12;15;14;18;21';` |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
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
| `TabStop` | `Boolean` | `True` | True: Das Control ist mit Tab erreichbar. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGKpiTile.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
