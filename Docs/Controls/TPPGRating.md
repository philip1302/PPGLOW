# TPPGRating

Palette **PPGlow** - Unit `PPG.Rating` - Basis `TPPGCustomRating`

**Vorbild:** TMS Rating

## Wofür

Die Bewertung zeigt und erfasst einen Wert als Sterne: Zufriedenheit nach einem Support-Ticket, Einstufung eines Lieferanten, Durchschnitt aus vielen Produktbewertungen. Der Anwender klickt einen Stern, benutzt die Pfeiltasten oder tippt eine Ziffer. Mit `ReadOnly` und `AllowHalf` dient dasselbe Control als reine Anzeige mit halben Sternen.

## Wann verwenden

- Für subjektive Einstufungen auf einer kleinen, festen Skala (meist 1 bis 5), die man auf einen Blick lesen soll. Für genaue Zahlenwerte ist `TPPGSpinEdit` besser, für stufenlose Werte und Bereiche `TPPGTrackBar`.
- Statt einer `TPPGRadioGroup` mit „1" bis „5", wenn die Skala selbsterklärend ist. Haben die Stufen eigene Bedeutungen („Kritisch", „Hoch", „Normal"), sind benannte Optionen oder eine `TPPGComboBox` klarer.
- Als Anzeige (`ReadOnly = True`, `AllowHalf = True`) für Durchschnittswerte in Formularen und Karten. In einer Tabelle nimmt man statt vieler Controls die Zellart `ckRating` von `TPPGGrid`.

## Unterschiede und Hinweise

- `Value` im Code löst kein Ereignis aus; nur Klick und Tastatur melden `OnChange`. Nach dem Laden eines Werts die eigene Auswertung deshalb selbst aufrufen.
- `Value` wird sofort auf ganze bzw. mit `AllowHalf` auf halbe Sterne gerundet und auf 0..`Max` begrenzt. Nur beim Laden aus der DFM wird erst in `Loaded` gerundet, weil `AllowHalf` und `Max` dort erst später gelesen werden können.
- `AllowClear` (Vorgabe True): Ein Klick auf den aktuellen Wert setzt ihn auf 0. 0 bedeutet „nicht bewertet".
- Tastatur: Pfeiltasten ±1 (mit `AllowHalf` ±0,5), Pos1 = 0, Ende = `Max`, Ziffern setzen den Wert direkt. Das Mausrad ändert den Wert nicht.
- `ReadOnly` zeigt nur an, bleibt aber in voller Farbe und fokussierbar (Screenreader lesen „3,5 / 5"); `Enabled = False` graut die Sterne aus.

## Anpassung

- Größe über `StarSize` und `StarSpacing`; mit `AutoSize` folgt das Control der Sternzahl `Max`.
- `StarColor` für die gefüllten Sterne (Vorgabe: Akzentfarbe des Presets), leere Sterne aus `Appearance.Normal.BorderColor` mit mindestens 3:1 Kontrast zum Hintergrund.

## Beispiel

```pascal
rtgService.Max := 5;
rtgService.StarSize := 28;
rtgService.OnChange := ServiceRatingChange;   // nur bei Eingabe des Anwenders
rtgService.Value := Ticket.Rating;            // ohne OnChange
ShowVerdict(rtgService.Value);
```

## Verhalten (aus dem Quelltext)

TPPGRating - Sternebewertung (Phase 7a).

- MaxValue Sterne (Icon-Schrift, sonst gezeichnetes Polygon), Value 0..MaxValue, halbe Sterne mit AllowHalf.
- Hover zeigt eine Vorschau; Klick setzt den Wert. Klick auf den aktuellen Wert loescht ihn (AllowClear).
- Tastatur: Links/Rechts (bzw. Hoch/Runter) +/- 1 (halbe: 0,5), Pos1 = 0, Ende = MaxValue, Ziffern 0..9 setzen direkt. RTL gespiegelt.
- ReadOnly zeigt nur an (keine Vorschau, keine Eingabe, bleibt fokussierbar).
- Code (Value := ...) loest kein OnChange aus; der Anwender schon.
- Screenreader: Rolle Schieberegler, Wert "3,5 / 5".

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Das Standard-Preset wird nicht in der DFM gespeichert. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. Praxis: Einmal für die ganze Anwendung festlegen, am besten über einen TPPGStyleManager. Das Preset bestimmt Fokusring, Rundung und Akzentfarbe der Sterne; die Sterne selbst sehen in allen Presets gleich aus. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Im Objektinspektor sind diese drei Properties dann ausgeblendet (bei Mehrfachauswahl nur, wenn alle markierten Controls einen Manager haben) und werden nicht in die DFM geschrieben; nach dem Leeren erscheinen sie sofort wieder. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. Praxis: Wie bei allen PPGlow-Controls den TPPGStyleManager des Formulars zuweisen. Dann folgen die Sterne (Akzentfarbe, Hell/Dunkel) automatisch der Optik der übrigen Felder. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. In der DFM stehen nur die Werte, die vom Preset abweichen; der Rest kommt beim Laden aus dem Preset. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` Praxis: Selten nötig: Die leeren Sterne nehmen Normal.BorderColor, die gesperrten Disabled.TextColor, der Fokusring Focused bzw. FocusColor. Für eine eigene Sternfarbe ist StarColor einfacher. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). Praxis: True lassen: Im Hochkontrastmodus zeichnet die Bewertung mit Systemfarben und bleibt auch für sehbehinderte Anwender lesbar. |
| `Value` | `Double` |  | Bewertung von 0 bis Max, mit AllowHalf auch halbe Werte (z. B. 3,5). Nutzung: `Rating1.Value := 4;` Praxis: Den gespeicherten Wert beim Öffnen eines Datensatzes setzen (Rating1.Value := Kunde.Zufriedenheit) und beim Speichern zurücklesen. 0 bedeutet „noch nicht bewertet"; prüfen Sie das vor dem Absenden. |
| `Max` | `Integer` | `5` | Anzahl der Sterne (1..50). Praxis: 5 Sterne sind die gewohnte Skala für Zufriedenheit und Produktbewertungen. 3 für grobe Einstufungen (z. B. Priorität niedrig/mittel/hoch), 10 nur für feine Fachbewertungen. |
| `AllowHalf` | `Boolean` | `False` | True: Halbe Sterne möglich (Klick auf die linke Sternhälfte, Tastatur in 0,5-Schritten). Praxis: Für Anzeigen von Durchschnittswerten einschalten (4,5 Sterne aus vielen Bewertungen). Für die eigene Eingabe des Anwenders meist aus lassen; ganze Sterne sind schneller und eindeutiger. |
| `AllowClear` | `Boolean` | `True` | True: Ein Klick auf den aktuellen Wert setzt ihn auf 0 zurück. Praxis: True lassen, wenn „keine Bewertung" erlaubt ist: Ein zweiter Klick auf den gewählten Stern nimmt sie zurück. False, wenn ein einmal vergebener Wert nur noch geändert, aber nicht gelöscht werden darf. |
| `ReadOnly` | `Boolean` | `False` | True: nur Anzeige (keine Vorschau, keine Eingabe); bleibt fokussierbar für Screenreader. Praxis: Für reine Anzeigen (Durchschnitt, Bewertung eines Kollegen, bereits abgeschickte Bewertung). Anders als Enabled = False bleiben die Sterne in voller Farbe und für Screenreader erreichbar. |
| `StarSize` | `Integer` | `20` | Größe eines Sterns in logischen Pixeln (8..128). Praxis: 16 bis 20 für Bewertungen in Listen und Formularzeilen, 28 bis 32 für die zentrale Frage eines Feedback-Dialogs oder für Touch-Bedienung. |
| `StarSpacing` | `Integer` | `4` | Abstand zwischen den Sternen in logischen Pixeln (0..64). Praxis: Die Vorgabe 4 passt meist. Bei großen Sternen für Touch etwas mehr (8), damit man nicht den Nachbarstern trifft; 0 für sehr kompakte Anzeigen in Tabellen. |
| `StarColor` | `TColor` | `clDefault` | Farbe der gefüllten Sterne; clDefault = Akzentfarbe. Nutzung: `Rating1.StarColor := $0000C0FF;` für klassisches Gold. Praxis: clDefault übernimmt die Akzentfarbe der Anwendung. Für die vertraute Gold-Optik von Produktbewertungen $0000C0FF setzen; im Dark Mode vorher die Lesbarkeit prüfen. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. Praxis: Meist alNone: Die Bewertung steht als Feld in einer Formularzeile. alLeft nur, wenn sie in einem Panel neben einer Beschriftung sitzt. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` Praxis: Standard [akLeft, akTop] lassen; die Sterne haben eine feste Breite und wachsen nicht mit. [akRight, akTop] nur, wenn die Bewertung rechtsbündig in einer Kopfzeile stehen soll. |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). Praxis: True lassen: Breite und Höhe ergeben sich aus Max, StarSize und StarSpacing. Ausschalten nur, wenn die Sterne in einer festen, höheren Zeile senkrecht mittig stehen sollen. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. Praxis: Nur für arabische oder hebräische Oberflächen: Die Sterne füllen sich dann von rechts, und die Pfeiltasten sind gespiegelt. Am Formular setzen und über ParentBiDiMode übernehmen. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` Praxis: Kaum nötig, weil AutoSize die Größe festlegt. MinHeight hilft, wenn die Bewertung in einer Zeile mit 32 Pixel hohen Eingabefeldern gleich hoch stehen soll (dann AutoSize aus). |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. Praxis: Sperren, solange eine Bewertung noch nicht möglich ist (z. B. vor Abschluss des Tickets). Zum bloßen Anzeigen eines Werts besser ReadOnly, da gesperrte Sterne grau werden. |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. Praxis: True lassen, damit die Bewertung der Leserichtung des Formulars folgt. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). Praxis: True lassen und ShowHint einmal am Formular einschalten, dann zeigt auch die Bewertung ihren Hint. |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. Praxis: Für Zusatzbefehle per Rechtsklick, z. B. „Bewertung entfernen" oder „Alle Kriterien auf 3 setzen" in einem Bewertungsbogen. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. Praxis: Einmal am Formular einschalten statt an jeder Bewertung; dann bleibt ParentShowHint True. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). Praxis: In Bewertungsbögen in Lesereihenfolge vergeben, damit man mit Tab von Kriterium zu Kriterium springt und die Sterne mit Pfeiltasten oder Ziffern setzt. |
| `TabStop` | `Boolean` | `True` | True: Das Control ist mit Tab erreichbar. Praxis: True lassen: Mit Tab erreichbar, dann setzen Pfeiltasten, Pos1/Ende und Ziffern den Wert ohne Maus. Auch bei ReadOnly sinnvoll, weil Screenreader den Wert dann vorlesen. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. Praxis: Ausblenden, wenn eine Bewertung im aktuellen Zusammenhang nicht vorgesehen ist (z. B. intern erledigte Tickets ohne Kundenfeedback). |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. Praxis: Nur für Touch-Geräte mit eigenen Gesten nötig; ein Tipp auf einen Stern funktioniert auch ohne Einstellung. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. Praxis: Nur bei VCL-Styles wichtig: seClient herausnehmen, wenn die Sterne ihre eigene Farbe (StarColor) behalten sollen. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. Praxis: dmManual lassen, sonst startet jeder Klick auf einen Stern ein Ziehen statt einer Bewertung. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). Praxis: Nur bei DragMode = dmAutomatic sichtbar; für Bewertungen praktisch nie gebraucht. |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. Praxis: Bei der Bewertung selten nötig; sie ist der Hintergrund hinter den Sternen. Meist ParentColor = True, damit die Sterne auf der Farbe der Karte oder des Panels liegen. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. Praxis: True lassen, damit der Hintergrund hinter den Sternen zur Karte oder zum Panel passt. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. Praxis: Bei PPGlow-Controls nicht nötig, sie zeichnen immer flackerfrei. Steht nur da, damit alte Formulare ohne Fehler laden. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. Praxis: True lassen; bei PPGlow-Controls ohne sichtbare Wirkung. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` Praxis: Zusammen mit Align einschalten, damit die Sterne nicht am Rand des Panels kleben; die Abstände kommen aus Margins. |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. Praxis: Im Designer per Maus; im Code bei dynamisch gebauten Formularzeilen, z. B. bündig mit den Eingabefeldern darüber. |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. Praxis: Wie Left: im Designer per Maus, im Code bei dynamisch gebauten Bewertungszeilen. |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Ergibt sich mit AutoSize aus Max, StarSize und StarSpacing. Breite nicht von Hand setzen, sondern über diese drei Werte steuern. |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Ergibt sich mit AutoSize aus StarSize (plus 4 Pixel für den Fokusring). Statt die Höhe zu setzen, StarSize ändern. |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. Praxis: crHandPoint zeigt, dass man auf die Sterne klicken kann. Bei ReadOnly crDefault lassen, damit niemand einen Klick erwartet. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` Praxis: Erklären Sie die Skala: „1 = mangelhaft, 5 = sehr gut. Erneut klicken entfernt die Bewertung". Mit ShowHint am Formular anzeigen. |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. Praxis: htKeyword, wenn Sie Stichwörter pflegen, sonst htContext. Ohne Hilfedatei egal. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. Praxis: Wie HelpContext, aber über ein Stichwort (HelpType = htKeyword), z. B. „Lieferantenbewertung". |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). Praxis: Nur mit Hilfedatei sinnvoll: die Seite, die F1 bei fokussierter Bewertung öffnet, z. B. die Erklärung der Bewertungsskala. |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. Praxis: Abstand zu Nachbarn bei Align; wirkt nur mit AlignWithMargins. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. Praxis: Für einen Hinweis mit Titel, z. B. „Bewertung: 1 = schlecht, 5 = sehr gut": einen TPPGCustomHint aufs Formular legen und hier zuweisen. |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. Praxis: True lassen, damit ein am Formular gesetzter CustomHint auch hier gilt. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) Praxis: Sprechende Namen vergeben (rtgZufriedenheit, rtgLieferzeit) statt PPGRating1, vor allem wenn mehrere Bewertungen auf einem Formular stehen. |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). Praxis: Bei mehreren Bewertungen mit einem gemeinsamen OnChange die Nummer des Kriteriums ablegen (Tag = 0, 1, 2) und im Handler über TPPGRating(Sender).Tag auswerten. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` Praxis: Auf Touch-Geräten: Wischgesten auswerten, z. B. nach links wischen = eine Bewertung zurück (EventInfo.GestureID). |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Anwender hat den Wert geändert (Klick, Tastatur). Setzen von Value im Code löst es nicht aus. Praxis: Hier reagieren Sie auf die Bewertung des Anwenders: Text „Gut"/„Sehr gut" anzeigen, Absenden freigeben, Durchschnitt neu berechnen. Value im Code löst es nicht aus; rufen Sie die Auswertung nach dem Laden selbst auf. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. Praxis: Um beim Betreten per Tab einen Hilfetext anzuzeigen, z. B. „Pfeiltasten oder Ziffern 1 bis 5" in der Statusleiste. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. Praxis: Guter Ort für eine Pflichtprüfung: Ist Value = 0, das Kriterium rot markieren oder einen Hinweis zeigen. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. Praxis: Selten gebraucht; feuert bei jedem Mausklick, auch wenn sich der Wert nicht ändert, aber nicht bei Tastatureingabe. Für Wertänderungen OnChange nehmen. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. Praxis: Selten gebraucht; der Wert wird erst beim Loslassen gesetzt. Für die Auswertung OnChange nehmen. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. Praxis: Für eine Textvorschau zur Sternvorschau, z. B. „Sehr gut" schon beim Überfahren: HoverValue der Bewertung lesen (-1 = keine Vorschau). |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. Praxis: Selten gebraucht; wenn sich der Wert ändert, meldet das OnChange zuverlässiger (auch per Tastatur). |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. Praxis: Um beim Überfahren eine Erklärung der Skala einzublenden. Die Sternvorschau beim Überfahren macht die Bewertung selbst. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. Praxis: Gegenstück zu OnMouseEnter: die Erklärung wieder ausblenden. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. Praxis: Die Bewertung reagiert nicht selbst auf das Mausrad. Wer das möchte, setzt hier Value schrittweise und ruft danach die eigene Auswertung auf. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. Praxis: Nur in Spezialfällen (Werkzeugfenster, die beim Klick nicht aktiv werden sollen); sonst nicht belegen. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. Praxis: Um das Kontextmenü vor dem Öffnen anzupassen, z. B. „Bewertung entfernen" nur anbieten, wenn Value > 0 ist. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. Praxis: Für Bewertungen praktisch nie gebraucht; nur wenn ein gezogenes Element (z. B. ein Listeneintrag) hier abgelegt werden darf. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. Praxis: Zusammen mit OnDragDrop: Accept := True nur für passende Quellen. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. Praxis: Nur bei DragMode = dmAutomatic; für Bewertungen kaum sinnvoll. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). Praxis: Nur bei DragMode = dmAutomatic; für Bewertungen kaum sinnvoll. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` Praxis: Für zusätzliche Tasten, z. B. Entf setzt die Bewertung auf 0. Pfeiltasten, Pos1 und Ende erledigt die Bewertung schon selbst. |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. Praxis: Selten nötig; die Ziffern 0 bis 9 setzen den Wert bereits direkt. Mit Key := #0 könnten Sie diese Direkteingabe unterdrücken. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. Praxis: Selten gebraucht; z. B. um nach dem Loslassen einer Pfeiltaste eine teure Neuberechnung zu starten. |

Tests: `PPG.Tests.Audit11C` (TAudit11CBehaviourTests); `PPG.Tests.Audit45` (TNamingTests); `PPG.Tests.Audit5d`; `PPG.Tests.Audit7C` (TAudit7CTests); `PPG.Tests.Phase7a` (TPhase7aPaintTests, TRatingTests, TSplitterTests); `PPG.Tests.Streaming` (TDfmStreamingTests); `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGRating.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
