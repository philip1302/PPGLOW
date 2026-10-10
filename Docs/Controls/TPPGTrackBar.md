# TPPGTrackBar

Palette **PPGlow** - Unit `PPG.TrackBar` - Basis `TPPGCustomTrackBar`

**Vorbild:** TTrackBar

## Wofür

Der Schieberegler wählt einen Zahlenwert aus einem festen Bereich, wenn die ungefähre Lage wichtiger ist als die exakte Zahl: Zoom, Lautstärke, Intervall, Schwellwert. Er ersetzt `TTrackBar` mit gleichen Eigenschaftsnamen, zeigt auf Wunsch einen empfohlenen Bereich (`SelStart`/`SelEnd`) und wird mit `RangeMode` zum Bereichsregler „von – bis“ mit zwei Griffen.

## Wann verwenden

- Für Werte, die man durch Ausprobieren einstellt und deren Wirkung sofort sichtbar ist (Zoom, Helligkeit). Muss ein exakter Wert eingetippt werden (Menge, Betrag), ist `TPPGNumberEdit` oder `TPPGSpinEdit` klarer; beides lässt sich auch kombinieren.
- Für einen Bereich „von – bis“ (Preisfilter, Zeitraum) mit `RangeMode` statt zweier getrennter Regler oder Felder.
- Nicht für Fortschritt oder reine Anzeigen: Dafür sind `TPPGProgressBar` bzw. `TPPGGauge` da (`ShowSlider = False` nur als Ausnahme).
- Für wenige benannte Stufen (Klein/Mittel/Groß) ist eine `TPPGRadioGroup` (auch als Segment) verständlicher als Zahlenstufen.

## Unterschiede und Hinweise

- `Position` wird still begrenzt; `Min > Max` wirft.
- Auswahlbereich wie `TTrackBar`: `SelStart`/`SelEnd` (mit `SelEnd` > `SelStart`) markieren einen Bereich auf der Schiene, `ShowSelRange` blendet ihn aus.
- **Bereichsregler:** `RangeMode` zeigt zwei Griffe, `Position` ist der Anfang, `PositionEnd` das Ende; sie überholen sich nicht (setzt der Code den Anfang hinter das Ende, wandert das Ende mit). Klick auf die Schiene bewegt den näheren Griff, Tab wechselt den Griff (`ActiveThumb`), danach verlässt Tab das Control. Screenreader: zwei Kinder „Von“/„Bis“.
- Noch nicht vorhanden: manuelle Ticks (`SetTick`) und `PositionToolTip`.

## Verhalten (aus dem Quelltext)

TPPGTrackBar - Schieberegler mit Glow-Griff.

Bedienung:
- Maus: Klick auf die Schiene setzt den Wert direkt dorthin und startet das Ziehen (wie Fluent/Windows 11); Klick auf den Griff zieht ohne Sprung.
- Tastatur wie TTrackBar: Pfeile = LineSize, Bild auf/ab = PageSize, Pos1/Ende = Min/Max. Bei RTL sind Links/Rechts gespiegelt.
- Mausrad: eine Raste = LineSize (nach unten = groesser, wie TTrackBar).
- Vertikal steht Min oben (wie TTrackBar).

Geometrie (alles in einer Funktion, damit Zeichnen und Hit-Test nie
auseinanderlaufen): siehe GetGeometry.

Auswahlbereich (Phase 20d): SelStart/SelEnd/ShowSelRange wie TTrackBar -
ein hervorgehobener Bereich auf der Schiene mit Marken an den Enden.

Bereichsregler (RangeMode): zwei Griffe, Position = Anfang, PositionEnd =
Ende; sie ueberholen sich nicht. Klick auf die Schiene bewegt den naeheren
Griff, Tab wechselt den Griff (danach verlaesst Tab das Control).
Screenreader: zwei Kinder "Von"/"Bis" mit ihrem Wert.

Migration: Typen und Property-Namen von TTrackBar (Vcl.ComCtrls).
Nicht unterstuetzt: PositionToolTip, manuelle Ticks per SetTick
(tsManual zeigt nur Anfang und Ende).

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. Praxis: Einmal für die ganze Anwendung über einen TPPGStyleManager festlegen; Fluent11 zeigt den runden Windows-11-Griff, Classic einen plastischen Griff. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. Praxis: Den TPPGStyleManager des Formulars zuweisen, dann passt der Regler sich mit allen anderen Controls an Optik und Hell/Dunkel an. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` Praxis: Für einen Regler mit eigener Akzentfarbe (z. B. Rot für „Risiko") die Zustände Normal und Hot einfärben; einheitliche Farben besser über das Preset. |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. Praxis: An lassen: Der Griff gleitet bei Klick auf die Schiene und bei Tastatur sanft zum neuen Wert. RespectSystemSettings beachtet die Windows-Einstellung. |
| `Min` | `Integer` | `0` | Kleinster Wert. Muss ≤ Max sein (sonst EPPGPropertyError). Praxis: Untere Grenze des Werts, z. B. 50 für einen Zoom ab 50 %. Bei neuen Grenzen im Code zuerst Max, dann Min setzen, sonst meldet Min > Max einen Fehler. |
| `Max` | `Integer` | `10` | Größter Wert. Muss ≥ Min sein (sonst EPPGPropertyError); beim Laden der DFM wird erst danach geprüft. Praxis: Obere Grenze, z. B. 100 für Lautstärke oder 60 für ein Intervall in Minuten. Wenige, klar unterscheidbare Stufen (unter etwa 100) lassen sich mit der Maus noch genau treffen. |
| `Position` | `Integer` | `0` | Aktueller Wert zwischen Min und Max. Werte außerhalb werden auf den Bereich geklemmt (kein Fehler), daher ist `Position := Position + 10` sicher. Änderungen werden weich animiert. Nutzung: `TrackBar1.Min := 0; TrackBar1.Max := 100; TrackBar1.Position := 50;` Praxis: Den gespeicherten Wert beim Öffnen der Einstellungen hier eintragen und beim Speichern wieder lesen. Werte außerhalb von Min..Max werden still begrenzt, Sie müssen also nicht vorher prüfen. |
| `Orientation` | `TTrackBarOrientation` | `trHorizontal` | Waagerecht (trHorizontal) oder senkrecht (trVertical, Min oben wie TTrackBar). Praxis: trVertical für Pegel und Mischpulte oder schmale Seitenleisten; waagerecht ist in Formularen und Einstellungen üblicher. Beim Umschalten tauscht der Regler Breite und Höhe. |
| `Frequency` | `Integer` | `1` | Abstand der Teilstriche in Werten (≥ 1), wie TTrackBar. Praxis: So wählen, dass 5 bis 10 Teilstriche entstehen, z. B. 10 bei 0..100. Teilstriche helfen beim Schätzen, zu viele wirken unruhig. |
| `LineSize` | `Integer` | `1` | Schrittweite für Pfeiltasten und eine Mausrad-Raste (≥ 1). Praxis: Feine Schrittweite für Pfeiltasten und Mausrad, z. B. 5 bei einem Zoom. Für Tastaturbenutzer wichtig: Mit 1 bei großem Bereich dauert das Einstellen lange. |
| `PageSize` | `Integer` | `2` | Schrittweite für Bild auf/ab (≥ 1). Praxis: Grobe Schrittweite für Bild auf/ab, typisch ein Teilstrich (gleich Frequency), damit der Wert von Strich zu Strich springt. |
| `TickMarks` | `TTickMark` | `tmBottomRight` | Lage der Teilstriche: tmBottomRight, tmTopLeft oder tmBoth. Praxis: tmBottomRight ist üblich; tmBoth für freistehende Regler, deren Skala man von beiden Seiten ablesen soll; tmTopLeft, wenn darunter eine Beschriftung steht. |
| `TickStyle` | `TTickStyle` | `tsAuto` | tsAuto = Teilstriche im Abstand Frequency, tsNone = keine, tsManual = nur Anfang und Ende (manuelle Ticks per SetTick werden nicht unterstützt). Praxis: tsNone für stufenlos wirkende Regler (Helligkeit, Lautstärke), tsAuto, wenn der Anwender bestimmte Werte gezielt treffen soll. |
| `ThumbLength` | `Integer` | `20` | Durchmesser des Griffs in logischen 96-DPI-Pixeln (8..100), wie TTrackBar. Praxis: 20 passt für Maus; für Touch-Oberflächen 28 bis 32, damit der Griff mit dem Finger gut zu treffen ist. |
| `ShowSlider` | `Boolean` | `True` | False: Der Griff wird nicht gezeichnet (reine Anzeige wie ein Füllbalken). Praxis: False nur für reine Anzeigen, die der Anwender nicht ziehen soll, z. B. einen Pegel. Für einen Fortschritt ist TPPGProgressBar die bessere Wahl. |
| `SelStart` | `Integer` | `0` | Anfang des hervorgehobenen Bereichs auf der Schiene (wie TTrackBar), z. B. ein empfohlener Bereich; ändert Position nicht. Nutzung: `TrackBar1.SelStart := 40; TrackBar1.SelEnd := 80;` Praxis: Anfang eines empfohlenen oder zulässigen Bereichs auf der Schiene, z. B. 90 für „empfohlen 90 bis 125 %". Der Anwender kann trotzdem jeden Wert wählen. |
| `SelEnd` | `Integer` | `0` | Ende des hervorgehobenen Bereichs auf der Schiene (wie TTrackBar); gezeichnet, wenn SelEnd > SelStart. Praxis: Ende des markierten Bereichs; der Bereich erscheint nur, wenn SelEnd größer als SelStart ist. Gleiche Werte (Vorgabe 0/0) heißen: kein Bereich. |
| `ShowSelRange` | `Boolean` | `True` | False: Der Bereich aus SelStart/SelEnd wird nicht gezeichnet (wie TTrackBar). Praxis: Auf False setzen, um den markierten Bereich vorübergehend auszublenden, ohne SelStart/SelEnd zu verlieren, z. B. wenn keine Empfehlung gilt. |
| `RangeMode` | `Boolean` | `False` | True: Bereichsregler mit zwei Griffen (Position = Anfang, PositionEnd = Ende), z. B. für einen Preisfilter. Klick bewegt den näheren Griff, Tab wechselt den Griff. Nutzung: `TrackBar1.RangeMode := True; TrackBar1.Position := 50; TrackBar1.PositionEnd := 250;` Praxis: Für Filter „von – bis" mit einem einzigen Regler: Preisspanne, Altersgruppe, Zeitraum in Tagen. Für einen einzelnen Wert ausgeschaltet lassen. |
| `PositionEnd` | `Integer` | `0` | Ende des Bereichs im RangeMode (zweiter Griff); bleibt immer zwischen Position und Max. Setzt der Code Position dahinter, wandert PositionEnd mit. Praxis: Im RangeMode das obere Ende des Bereichs, z. B. „Preis bis". Setzen Sie es nach Max, damit es nicht auf das alte Max begrenzt wird. |
| `ShowFocusRect` | `Boolean` | `True` | True: Bei Tastaturfokus wird der Fokusrahmen bzw. -ring gezeichnet. Praxis: True lassen: Ein Regler wird oft mit Pfeiltasten bedient, der Fokusring zeigt, welcher Regler gerade reagiert. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). Praxis: True lassen, damit Schiene, Griff und Bereich im Windows-Hochkontrastmodus in klaren Systemfarben erscheinen. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. Praxis: Für Regler, die eine ganze Leiste füllen sollen, z. B. alTop in einem Einstellungs-Panel oder alClient in einer Zoom-Leiste der Statuszeile. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` Praxis: [akLeft, akTop, akRight] in Dialogen mit veränderbarer Größe: Der Regler wird mit dem Fenster breiter, die Schritte bleiben gleich. |
| `AutoSize` | `Boolean` |  | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). Praxis: Einschalten, damit die Höhe genau zu Griff und Teilstrichen passt; die Länge bestimmen weiter Sie. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. Praxis: Bei Rechts-nach-links-Oberflächen am Formular setzen: Der Regler beginnt dann rechts, und die Pfeiltasten sind gespiegelt. |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. Praxis: Selten nötig; der Hintergrund kommt vom Parent (ParentBackground). Die Farben von Schiene und Griff stehen in Appearance. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` Praxis: MinWidth, z. B. 120, verhindert bei Align oder Anchors einen so kurzen Regler, dass sich Werte nicht mehr treffen lassen. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). Praxis: Nur bei DragMode = dmAutomatic sichtbar; bei Reglern selten, weil Ziehen dort den Wert ändert. |
| `DragKind` | `TDragKind` |  | dkDrag = Drag & Drop, dkDock = Andocken beim Ziehen. Praxis: dkDrag lassen; dkDock nur in Werkzeugfenstern mit andockbaren Bedienelementen. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. Praxis: dmManual lassen: Mit dmAutomatic würde Ziehen das Control verschieben statt den Wert zu ändern. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. Praxis: Sperren, solange die Einstellung nicht gilt, z. B. das Sicherungsintervall, wenn „Automatisch sichern" aus ist. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` Praxis: Erklärt Bedeutung und Einheit, z. B. „Lautstärke in Prozent" oder „Empfohlen: 90 bis 125 %". Den aktuellen Wert zeigen Sie besser in einem Label daneben. |
| `ParentBackground` | `Boolean` | `True` | True: Der Hintergrund des Parents scheint durch (transparente Wirkung). Praxis: True lassen: Der Regler liegt dann nahtlos auf Panel oder Karte. |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. Praxis: True lassen, damit der Regler der Leserichtung des Formulars folgt. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. Praxis: True, wenn der Hintergrund die Farbe des Parents haben soll; meist zusammen mit ParentBackground. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). Praxis: True lassen und ShowHint einmal am Formular einschalten. |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. Praxis: Für „Auf Standard zurücksetzen" per Rechtsklick; spart einen eigenen Button neben jedem Regler. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. Praxis: Einschalten, wenn der Hint Einheit oder Empfehlung erklärt; sonst am Formular steuern. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. Praxis: Nur bei VCL-Styles: seClient herausnehmen, wenn der Regler seine Akzentfarbe aus Appearance behalten soll. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). Praxis: In Einstellungsseiten von oben nach unten vergeben, damit Tab die Regler in Lesereihenfolge erreicht. |
| `TabStop` | `Boolean` | `True` | True: Das Control ist mit Tab erreichbar. Praxis: True lassen: Regler sollen mit Tab und Pfeiltasten bedienbar sein (Barrierefreiheit). |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. Praxis: Ausblenden, wenn die Einstellung nicht zur Situation passt; was nur gerade nicht gilt, besser mit Enabled = False sperren. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. Praxis: Auf Touch-Geräten meist nicht nötig, Ziehen mit dem Finger funktioniert ohne Gesten. Gesten nur für Zusatzfunktionen anhaken. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. Praxis: Nicht nötig, PPGlow-Controls zeichnen flackerfrei. Steht nur für die Kompatibilität mit alten Formularen da. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. Praxis: True lassen; bei PPGlow-Controls ohne sichtbare Wirkung. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` Praxis: Zusammen mit Align einschalten, damit der Griff am Rand nicht abgeschnitten wirkt; Abstände unter Margins. |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. Praxis: Im Designer per Maus; im Code nur bei dynamisch erzeugten Reglern, z. B. SetBounds(16, Y, 400, 40). |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. Praxis: Wie Left: im Designer per Maus, im Code nur bei dynamisch erzeugten Reglern. |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Länge der Schiene: mindestens etwa 3 Pixel je Wert, damit jeder Wert mit der Maus erreichbar bleibt (0..100 also ab etwa 300 Pixel). |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: 40 Pixel für waagerechte Regler mit Teilstrichen; bei tmBoth oder großem ThumbLength etwas mehr oder AutoSize einschalten. |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. Praxis: crHandPoint signalisiert „ziehbar"; meist reicht der Standardpfeil, der Hover-Effekt am Griff zeigt das schon. |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. Praxis: htKeyword bei Stichwort-Hilfen, sonst htContext. Ohne Hilfedatei ohne Bedeutung. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. Praxis: Wie HelpContext, aber als Stichwort (HelpType = htKeyword), z. B. „Zoom". |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). Praxis: Nur mit Hilfedatei: Kontext-ID der Seite, die F1 für diese Einstellung öffnet. |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. Praxis: Abstand zu Nachbarn bei Align, z. B. Margins.Left = 8 zwischen Beschriftung und Regler; wirkt nur mit AlignWithMargins. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. Praxis: Für einen Hinweis mit Titel, z. B. „Zoom – empfohlen 90 bis 125 %", einen TPPGCustomHint oder TBalloonHint zuweisen. |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. Praxis: True lassen, damit ein am Formular gesetzter CustomHint auch hier gilt. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) Praxis: Sprechend benennen (tbZoom, tbLautstaerke), dann liest sich der OnChange-Code von selbst. |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). Praxis: Bei mehreren gleichartigen Reglern mit einem gemeinsamen OnChange, z. B. Tag = Kanalnummer eines Mischpults. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Position hat sich geändert (Anwender oder Code, nicht beim Laden); der neue Wert ist bereits gesetzt. Praxis: Hier übernehmen Sie den Wert: Label aktualisieren, Einstellung anwenden. Teure Arbeiten (Abfrage, Neuberechnung) nur, wenn nicht Dragging, und nach dem Loslassen in OnMouseUp. |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` Praxis: Auf Touch-Geräten für Zusatzgesten, z. B. Doppeltippen setzt auf den Standardwert zurück. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. Praxis: Um das Kontextmenü vor dem Öffnen anzupassen, z. B. „Auf Standard zurücksetzen" sperren, wenn der Wert schon der Standard ist. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. Praxis: Bei Reglern selten; z. B. einen Wert aus einer Liste auf den Regler ziehen und übernehmen. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. Praxis: Zusammen mit OnDragDrop: Accept nur für passende Quellen setzen. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. Praxis: Nur bei DragKind = dkDock: die neue Lage des Reglers speichern. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). Praxis: Nach dem Ziehen des Controls (nicht des Griffs); Target = nil heißt abgebrochen. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. Praxis: Für eine Erklärung in der Statusleiste („Pfeiltasten ändern in 5er-Schritten"), sobald der Regler den Fokus bekommt. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. Praxis: Guter Ort, um einen geänderten Wert endgültig zu speichern, wenn der Anwender das Feld verlässt. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` Praxis: Für zusätzliche Tasten, z. B. Entf oder 0 setzt auf den Standardwert. Pfeile, Bild auf/ab, Pos1 und Ende erledigt der Regler selbst. |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. Praxis: Selten; Zeichentasten ändern den Wert nicht. Für Direkteingabe besser ein TPPGNumberEdit oder TPPGSpinEdit neben den Regler legen. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. Praxis: Um nach Tastaturbedienung einmalig zu speichern, statt bei jedem Schritt in OnChange. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. Praxis: Selten nötig; der Klick auf die Schiene setzt den Wert schon selbst. Z. B. um beim Ziehen eine Vorschau einzublenden. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. Praxis: Um beim Überfahren eine Erklärung oder die Skala einzublenden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. Praxis: Gegenstück zu OnMouseEnter: Erklärung oder Skala wieder ausblenden. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. Praxis: Selten; z. B. um den Wert unter dem Mauszeiger als Tooltip vorab anzuzeigen. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. Praxis: Ende des Ziehens: hier die teure Arbeit einmal ausführen (Liste filtern, Bild neu berechnen), die während des Ziehens ausgelassen wurde. |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. Praxis: Nur bei DragKind = dkDock: eigenes Dock-Objekt setzen. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. Praxis: Nur bei DragMode = dmAutomatic: eigenes DragObject setzen; bei Reglern selten. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. Praxis: Beim Regler selten nötig; für Wertänderungen OnChange nehmen, denn Tastatur und Mausrad lösen kein OnClick aus. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. Praxis: Um das Mausrad anders zu nutzen, z. B. mit Strg feiner zu stellen; Handled := True verhindert den Standardschritt. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. Praxis: Nur in Spezialfällen (Werkzeugfenster, die beim Klick nicht aktiv werden sollen); sonst nicht belegen. |
| `OnTracking` | `TNotifyEvent` `(Sender: TObject)` | Während der Anwender den Griff zieht, bei jeder Wertänderung (vor dem Loslassen); OnChange kommt zusätzlich. Wie TTrackBar.OnTracking. Praxis: Während des Ziehens für leichte Rückmeldung nutzen, z. B. den Wert in einem Label anzeigen. Die eigentliche Arbeit gehört in OnChange bzw. nach dem Loslassen. |

Tests: `PPG.Tests.Audit45` (TNamingTests, TStreamingFixTests); `PPG.Tests.Audit5d` (TStage3Tests); `PPG.Tests.Audit7A` (TWheelTests); `PPG.Tests.Phase20` (TTrackRangeTests); `PPG.Tests.Phase3` (TContainerTests, TPhase3PaintTests, TRangeTests, TTrackBarTests); `PPG.Tests.Phase8` (TFluent11Tests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGTrackBar.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
