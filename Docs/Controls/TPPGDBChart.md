# TPPGDBChart

Palette **PPGlow DB** - Unit `PPG.DB.Chart` - Basis `TPPGCustomDBChart`

**Vorbild:** TDBChart (TeeChart)

## Unterschiede und Hinweise

- Felder auf Diagramm-Ebene: `ValueFields` (`"Umsatz;Kosten"`, je Feld eine Serie in der Reihenfolge von `Series`), `LabelField`, `XField`. Fehlende Serien werden angelegt und nach `DisplayLabel` benannt.
- Anbinden, Öffnen und Schließen laden sofort; Datenänderungen laden nach `ReloadDelay` ms (viele Änderungen = ein Laden).
- Während `Edit`/`Insert` wird nicht gelesen (sonst würde die Eingabe gespeichert); das Laden folgt nach `Post`/`Cancel`.
- `MaxRecords` begrenzt das Lesen; eindirektionale Datenmengen werden nicht gelesen.
- `ShowCurrentRecord` markiert den aktuellen Datensatz, `JumpToRecord` springt beim Klick auf einen Punkt (über `RecNo`).

## Beispiel

```pascal
PPGDBChart1.DataSource := DataSource1;
PPGDBChart1.LabelField := 'Monat';
PPGDBChart1.ValueFields := 'Umsatz;Kosten';
```

## Verhalten (aus dem Quelltext)

TPPGDBChart - Diagramm aus einer Datenmenge (Phase 10e, Paket PPGlowDBR).

- DataSource, ValueFields ("Umsatz;Kosten": je Feld eine Serie, in der Reihenfolge der Series; fehlende Serien werden angelegt und nach Field.DisplayLabel benannt), LabelField (Kategorie-Text) und XField (X-Wert fuer Zahl-/Datumsachse).
- Gelesen wird die ganze Datenmenge (hoechstens MaxRecords) mit DisableControls und Lesezeichen; der aktuelle Datensatz bleibt stehen.
- Anbinden, Oeffnen und Schliessen laden sofort. Datenaenderungen laden verzoegert neu (ReloadDelay ueber den gemeinsamen Animator, nie im Paint): viele Aenderungen hintereinander = ein Laden. Die Ereignisse des eigenen Lesens werden ignoriert.
- ShowCurrentRecord markiert den aktuellen Datensatz (MarkedIndex); Klick auf einen Punkt springt zum Datensatz (JumpToRecord).
- Eindirektionale Datenmengen werden nicht gelesen (kein Zurueckspringen).
- Waehrend Edit/Insert wird nicht gelesen (First wuerde die Eingabe des Anwenders speichern); das Laden folgt nach Post bzw. Cancel.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `DataSource` | `TDataSource` |  | Datenquelle; die ganze Datenmenge wird gelesen (höchstens MaxRecords Datensätze), der aktuelle Datensatz bleibt stehen. Eindirektionale Datenmengen werden nicht gelesen. |
| `ValueFields` | `string` |  | Wertfelder, getrennt durch Semikolon; je Feld eine Serie in der Reihenfolge von Series. Fehlende Serien werden angelegt und nach Field.DisplayLabel benannt. Nutzung: `DBChart.ValueFields := 'Umsatz;Kosten';` |
| `LabelField` | `string` |  | Feld für die Kategorie-Beschriftung (X-Achse bzw. Kreissegmente). Nutzung: `DBChart.LabelField := 'Monat';` |
| `XField` | `string` |  | Feld mit dem X-Wert für eine Zahl- oder Datumsachse (XAxis.Kind = cxkNumeric bzw. cxkDateTime); leer = Kategorieachse mit LabelField. Nutzung: `DBChart.XField := 'Datum'; DBChart.XAxis.Kind := cxkDateTime;` |
| `MaxRecords` | `Integer` | `10000` | Höchstzahl der gelesenen Datensätze (ab 1, Vorgabe 10 000); schützt vor sehr großen Tabellen. |
| `ReloadDelay` | `Integer` | `100` | Wartezeit in Millisekunden vor dem Neuladen nach Datenänderungen (0..10 000; 0 = sofort). Viele Änderungen hintereinander ergeben ein einziges Laden. Während Edit/Insert wird nicht gelesen. |
| `ShowCurrentRecord` | `Boolean` | `True` | True: Der aktuelle Datensatz wird im Diagramm markiert und folgt dem Datensatzzeiger. |
| `JumpToRecord` | `Boolean` | `True` | True: Ein Klick auf einen Punkt macht dessen Datensatz zum aktuellen (z. B. für ein Detailformular). |
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
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnPointClick` | `TPPGChartPointEvent` `(Sender: TObject; SeriesIndex, PointIndex: Integer)` | Ein Datenpunkt wurde angeklickt oder per Enter/Leertaste ausgelöst. SeriesIndex und PointIndex nennen den Punkt (bei Kreis/Ring das Segment). Nutzung: `ShowMessage(Chart.Categories[PointIndex]);` Beim DB-Chart springt die Datenmenge zusätzlich zum Datensatz (JumpToRecord). |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBChart.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
