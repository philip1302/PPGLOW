# TPPGChart

Palette **PPGlow** - Unit `PPG.Chart` - Basis `TPPGCustomChart`

**Vorbild:** TMS FNC Chart, TeeChart (Grundfunktionen)

## Unterschiede und Hinweise

- Bewusst kein TeeChart-Nachbau: kein 3D, keine Finanz-Charts, kein Zoom/Pan, keine logarithmische Achse, keine Splines.
- Serienarten: Linie, Stufe, Fläche, Säule, Balken, Kreis, Ring. Sind alle sichtbaren Serien Balken, liegt das Diagramm quer; ist die erste sichtbare Serie ein Kreis/Ring, zeigt es nur diese.
- `Stacking` (gestapelt, 100 %) gilt für Säulen, Balken und Flächen auf der Kategorieachse.
- Datenänderungen gleiten (bis 10 000 Punkte). Mehrere Änderungen in `BeginDataUpdate`/`EndDataUpdate` ergeben einen Übergang. `Append(Y, MaxCount)` für Live-Daten.
- Virtueller Modus: `Series.VirtualCount` + `OnGetPoint`.
- Der Tooltip ist Teil des Controls (kein eigenes Fenster) und erscheint deshalb auch in Screenshots. `SaveToBitmap`/`SaveToPng`/`CopyToClipboard` zeigen immer den Endzustand.
- Screenreader: Kinder sind die Datenpunkte (höchstens 500 je Serie).

## Anpassung

- `ChartStyles` (Titel, Achse, Gitter, Legende), `TitleFont`, `LegendFont`; Serienfarben ohne eigene Farbe aus `TPPGStyleManager.ChartPalette`.

## Beispiel

```pascal
var
  S: TPPGChartSeries;
begin
  PPGChart1.Categories.CommaText := 'Jan,Feb,Mrz';
  S := PPGChart1.Series.Add;
  S.Title := 'Umsatz';
  S.Kind := cskColumn;
  S.SetValues([12, 15, 11]);
  PPGChart1.ReferenceLines.Add.Value := 13;
end;
```

## Verhalten (aus dem Quelltext)

TPPGChart - Diagramm im Stil der Suite (Phase 10d).

- Serien (PPG.Chart.Series): Linie, Stufe, Flaeche, Saeule, Balken, Kreis, Ring. Linien, Flaechen und Saeulen lassen sich mischen; sind alle sichtbaren Serien Balken, liegt das Diagramm quer (Kategorien senkrecht). Ist die erste sichtbare Serie ein Kreis/Ring, zeigt das Diagramm nur sie.
- Achsen: X als Kategorie, Zahl oder Datum/Zeit; Y links und optional eine zweite Y-Achse rechts (Series.YAxis = casSecondary). Grenzen automatisch (PPG.Chart.Scale) oder fest; Referenzlinien (ReferenceLines).
- Stapeln (Stacking) fuer Saeulen, Balken und Flaechen auf der Kategorieachse, auch als 100 %.
- Legende oben, unten oder rechts; Klick blendet eine Serie aus/ein (animiert).
- Tooltip beim Ueberfahren: rastet auf den naechsten X-Wert ein (Linie ueber alle Serien) bzw. auf das Segment beim Kreis. Der Tooltip ist Teil des Controls (kein eigenes Fenster): er erscheint so auch beim Export und in Screenshots.
- Tastatur: Pfeile links/rechts laufen durch die Punkte, hoch/runter bzw. Bild wechseln die Serie, Pos1/Ende, Enter/Leertaste = OnPointClick, Esc blendet den Tooltip aus.
- Animation ueber den gemeinsamen Animator: Aufbau beim ersten Zeigen, weicher Uebergang bei Datenaenderungen (bis 10 000 Punkte), Ein-/ Ausblenden von Serien.
- Viele Punkte: Linien werden pro Pixelspalte auf Min/Max verdichtet.
- Export: SaveToBitmap, SaveToPng, CopyToClipboard (gleicher Zeichenweg).
- Screenreader: Rolle Diagramm, Kinder = Datenpunkte ("Serie, Kategorie: Wert"), hoechstens 500 je Serie.
- RTL: Y-Achse rechts, Legende von rechts; die X-Richtung bleibt (wie Excel).

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `Title` | `string` |  | Überschrift über dem Diagramm (leer = keine). Gestaltung über Styles.Title. |
| `Series` | [TPPGChartSeriesList](types/TPPGChartSeriesList.md) |  | Die Datenreihen (Collection von TPPGChartSeries) mit Art, Farbe, Achse und Werten. Nutzung: `with Chart.Series.Add do begin Title := 'Umsatz'; Kind := cskColumn; SetValues([12, 18, 9]); end;` |
| `Categories` | `TStrings` |  | Beschriftungen der Kategorieachse, eine Zeile je Punktindex. Ohne Eintrag gilt der Text des Punktes bzw. 1, 2, 3 … Nutzung: `Chart.Categories.CommaText := 'Jan,Feb,Mrz,Apr';` |
| `XAxis` | [TPPGChartAxis](types/TPPGChartAxis.md) |  | Waagerechte Achse: Art (Kategorie, Zahl, Datum), Grenzen, Format, Titel, Gitter. Bei Balkendiagrammen liegt sie senkrecht. |
| `YAxis` | [TPPGChartAxis](types/TPPGChartAxis.md) |  | Linke Werteachse: Grenzen (automatisch oder fest), Format, Titel, Gitter. |
| `Y2Axis` | [TPPGChartAxis](types/TPPGChartAxis.md) |  | Zweite Y-Achse rechts; sichtbar nur, wenn mindestens eine Serie YAxis = casSecondary hat. |
| `ReferenceLines` | [TPPGChartReferenceLines](types/TPPGChartReferenceLines.md) |  | Waagerechte oder senkrechte Hilfslinien mit Beschriftung, z. B. Ziel, Grenzwert oder Stichtag. |
| `Stacking` | `TPPGChartStacking` | `cstNone` | Stapeln von Säulen, Balken und Flächen auf der Kategorieachse: nicht gestapelt, gestapelt (Summen) oder 100 % (Anteile je Kategorie). Werte: `cstNone`, `cstStacked`, `cstPercent`. Nutzung: `Chart.Stacking := cstStacked;` |
| `LegendPosition` | `TPPGChartLegendPosition` | `clpBottom` | Lage der Legende (oben, unten, rechts) oder keine. Bei Kreis und Ring zeigt die Legende die Kategorien. Werte: `clpNone`, `clpTop`, `clpBottom`, `clpRight`. |
| `ShowTooltips` | `Boolean` | `True` | True: Beim Überfahren erscheint ein Tooltip mit den Werten (rastet auf den nächsten X-Wert über alle Serien bzw. auf das Kreissegment ein). Er ist Teil des Bildes und erscheint auch im Export. |
| `LegendToggle` | `Boolean` | `True` | True: Ein Klick auf einen Legendeneintrag blendet die Serie aus bzw. wieder ein. |
| `Styles` | [TPPGChartStyles](types/TPPGChartStyles.md) |  | Bereiche einzeln gestalten: Titel, Achsen, Gitter, Legende. Nicht gesetzte Farben kommen aus dem Preset. |

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
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnGetPoint` | `TPPGChartGetPointEvent` `(Sender: TObject; SeriesIndex, Index: Integer; var Point: TPPGChartPoint)` | Liefert im virtuellen Modus (Series.VirtualCount > 0) den Punkt Index der Serie SeriesIndex. Point füllen: X, Y, optional Text und Color (clDefault = Serienfarbe). Wird beim Zeichnen nur für benötigte Punkte gerufen; schnell halten, nichts zeichnen. Nutzung: `Point.X := Index; Point.Y := FDaten[Index];` |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnPointClick` | `TPPGChartPointEvent` `(Sender: TObject; SeriesIndex, PointIndex: Integer)` | Ein Datenpunkt wurde angeklickt oder per Enter/Leertaste ausgelöst. SeriesIndex und PointIndex nennen den Punkt (bei Kreis/Ring das Segment). Nutzung: `ShowMessage(Chart.Categories[PointIndex]);` Beim DB-Chart springt die Datenmenge zusätzlich zum Datensatz (JumpToRecord). |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGChart.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
