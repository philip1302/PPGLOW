# TPPGToolBar

Palette **PPGlow** - Unit `PPG.ToolBar` - Basis `TPPGCustomControl`

**Vorbild:** TToolBar

## Wofür

Die ToolBar ist die Befehlsleiste über einer Liste, einem Editor oder einem Formular: Neu, Bearbeiten, Drucken, Filter. Die Befehle sind Einträge (`Items`), keine eigenen Controls: Buttons, Umschalt-Buttons (auch in Gruppen) und Trenner, mit Symbol aus der Symbolschrift oder einer Bildliste. Was nicht in die Breite passt, landet automatisch im „…“-Menü am Ende.

## Wann verwenden

- Für eine Reihe von Befehlen, die zu einem Inhalt gehören (Liste, Editor, Detailansicht). Für wenige, frei platzierte Befehle, z. B. OK/Abbrechen in Dialogen, ist `TPPGButton` passender.
- Statt `TPPGRibbon`, wenn die Befehle in eine Zeile passen. Ein Menüband mit Registerkarten, Gruppen und KeyTips lohnt sich erst bei sehr vielen Befehlen.
- Statt `TPPGMenuBar`, wenn die Befehle direkt sichtbar und mit einem Klick erreichbar sein sollen; die Menüleiste ordnet sie in aufklappenden Menüs.
- Für Ein/Aus-Zustände direkt am Befehl (Filter „Nur aktive“, Fett, Ansicht Liste/Kacheln) mit `Style = tisCheck`. Eine gespeicherte Einstellung in einem Formular ist mit `TPPGToggleSwitch` oder `TPPGCheckBox` klarer.
- Für Befehle mit Varianten (Exportieren als PDF/Excel) gibt es keine Dropdown-Einträge; dafür einen `TPPGButton` mit `Style = pbsSplitButton` neben die Leiste stellen.

## Unterschiede und Hinweise

- Einträge (`Items`) statt Kind-Buttons; daher kein automatischer Umstieg von `TToolBar`/`TToolButton`.
- Überlauf als Menü im Stil der Suite (`TPPGPopupMenu`, mit Haken für Umschalt-Buttons); Actions über `Items[].Action`.

## Anpassung

- Je Item `Color`, `TextColor`, `FontStyle`; `ImageTint` für einfarbige Symbole.

## Verhalten (aus dem Quelltext)

TPPGToolBar - Befehlsleiste (Phase 7c, wie WinUI CommandBar).

- Items: Buttons, Umschalt-Buttons (tisCheck, mit GroupIndex wie Radiobuttons) und Trenner; Symbol aus Images oder der Symbolschrift (IconChar), Text wahlweise daneben (ShowCaptions).
- Optik aus dem Preset: Hover/gedrueckt/eingerastet ueber den Renderer wie TPPGButton, in Ruhe flach.
- Ueberlauf: Was nicht in die Breite passt, landet in einem "..."-Menue am Ende (Menue im Stil der Suite mit Haken fuer Umschalt-Buttons, Phase 11).
- Actions: Item.Action verbindet Caption, Hint, Enabled, Checked, Visible, ImageIndex und OnExecute; die Leiste aktualisiert die Actions im Leerlauf (InitiateAction) wie die VCL-Controls.
- Tastatur: Links/Rechts, Pos1/Ende, Enter/Leertaste.
- Code (Down := ...) loest kein Ereignis aus; ein Klick loest Item.OnClick (bzw. Action.Execute) und danach OnItemClick aus.
- Screenreader: Symbolleiste; Kinder Buttons/Umschalt-Buttons/Trenner und der Ueberlauf-Knopf.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Das Standard-Preset wird nicht in der DFM gespeichert. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. Praxis: Wie bei allen Controls einmal für die Anwendung festlegen, am besten über den StyleManager. Fluent11 wirkt mit der flachen Leiste wie die Befehlsleiste im Windows-11-Explorer. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. Praxis: Denselben TPPGStyleManager wie die übrigen Controls zuweisen; dann wechseln Leiste, Liste und Felder gemeinsam die Optik, auch Hell/Dunkel. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. In der DFM stehen nur die Werte, die vom Preset abweichen; der Rest kommt beim Laden aus dem Preset. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` Praxis: Bestimmt die Hover-, Druck- und Eingerastet-Optik der Befehle; in Ruhe bleibt die Leiste flach. Meist reicht Preset bzw. StyleManager; Appearance nur für eine eigene Markenfarbe ändern. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). Praxis: True lassen: Im Hochkontrastmodus erscheinen Befehle und Trenner in Systemfarben, Sehbehinderte finden sie so sicher. |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). Praxis: Eine Bildliste für alle Befehle zuweisen (bei hoher DPI eine TVirtualImageList); jedes Item wählt sein Bild über ImageIndex. Ohne Bildliste reichen Symbole aus der Symbolschrift (IconChar). |
| `Items` | [TPPGToolItems](types/TPPGToolItems.md) |  | Befehle der Leiste: Buttons, Umschalt-Buttons und Trenner; was nicht in die Breite passt, landet im „…"-Menü am Ende. Nutzung: Im Designer per Collection-Editor; im Code `PPGToolBar1.Items.AddButton('Neu', $E710, NeuClick);` Praxis: Hier stehen die Befehle. Im Designer über den Collection-Editor, im Code mit Items.AddButton, AddCheck und AddSeparator; häufige Befehle nach vorne, seltene nach hinten, weil die hinteren zuerst ins „…"-Menü wandern. |
| `ShowCaptions` | `Boolean` | `True` | True: Text neben dem Symbol; False: nur Symbole (Text dann als Tooltip). Praxis: True für Leisten mit wenigen, seltenen Befehlen (Text hilft beim Finden); False für Leisten mit bekannten Symbolen oder wenig Platz. Ohne Text zeigt der Tooltip die Caption. |
| `ImageTint` | `TPPGImageTint` | `itNone` | itTextColor färbt das Bild einfarbig in der Textfarbe des aktuellen Zustands. Ideal für einfarbige Symbole (SVG, Icon-Fonts), die so Hover, Dark Mode und Deaktiviert automatisch folgen. Werte: `itNone`, `itTextColor`. Nutzung: `PPGButton1.ImageTint := itTextColor;` Praxis: itTextColor bei einfarbigen Symbolen aus Images: Sie folgen dann Hover, Dark Mode und Sperren automatisch, ohne zweite Bildliste. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` | `alTop` | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. Praxis: alTop lassen: Die Leiste sitzt dann wie gewohnt oben über Liste oder Editor und läuft beim Vergrößern des Fensters mit. alNone nur, wenn die Leiste frei in einer Karte oder einem Dialog steht (dann Left, Top und Width setzen). |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` Praxis: Nur bei Align = alNone wichtig: [akLeft, akTop, akRight] lässt eine frei platzierte Leiste mit dem Fenster breiter werden, damit weniger Befehle im „…"-Menü landen. |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). Praxis: True lassen: Die Höhe folgt der Schrift, die Leiste wird bei größerer Schrift oder hoher DPI nicht abgeschnitten. Die Breite bestimmen Align bzw. Width. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. Praxis: Nur für arabische oder hebräische Oberflächen: Die Befehle laufen dann von rechts nach links, das „…"-Menü steht links. |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. Praxis: Hintergrund der Leiste. Meist über ParentColor die Farbe der Karte oder des Fensters übernehmen; eine eigene Farbe nur, wenn die Leiste sich als Band abheben soll. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` Praxis: Bei frei platzierter Leiste MinWidth setzen, damit wenigstens die wichtigsten Befehle sichtbar bleiben, auch wenn das Fenster schmal wird. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. Praxis: Sperrt alle Befehle auf einmal, z. B. solange ein Speichervorgang läuft. Einzelne Befehle sperren Sie über Items[].Enabled oder deren Action. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` Praxis: Schrift der Beschriftungen; meist über ParentFont vom Formular. Eine größere Schrift macht die Leiste mit AutoSize automatisch höher, z. B. für Touch-Bildschirme. |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. Praxis: True lassen, damit die Leiste der Leserichtung des Formulars folgt. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. Praxis: True, wenn die Leiste dieselbe Farbe wie die Fläche darunter haben soll (übliche flache Optik). |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. Praxis: True lassen, damit die Leiste die Formularschrift trägt. Ändern Sie Font, wird es automatisch False. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). Praxis: True lassen und ShowHint am Formular einschalten; dann zeigen die Befehle ihre Tooltips. |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. Praxis: Für ein Kontextmenü der Leiste, z. B. „Beschriftungen anzeigen" zum Umschalten von ShowCaptions. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. Praxis: Einschalten (oder über ParentShowHint vom Formular), sonst sieht der Anwender bei ShowCaptions = False nicht, was ein Symbol tut. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). Praxis: Die Leiste kommt in der Tab-Reihenfolge meist vor dem Inhalt, den sie bedient (Leiste, dann Liste). |
| `TabStop` | `Boolean` | `True` | True: Das Control ist mit Tab erreichbar. Praxis: True lassen: Tastaturbenutzer erreichen die Leiste mit Tab und wählen die Befehle mit den Pfeiltasten. False nur, wenn alle Befehle auch per Tastenkürzel gehen. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. Praxis: Ganze Leiste ausblenden, z. B. in einer reinen Leseansicht; mit Align = alTop rückt der Inhalt darunter dann nach oben. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. Praxis: Nur für Touch-Geräte: Gesten anhaken und in OnGesture auswerten. Für normales Tippen auf Befehle nicht nötig. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. Praxis: Nur bei VCL-Styles wichtig: ohne seClient behält die Leiste ihre Farben aus dem Preset. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. Praxis: dmManual lassen, sonst startet jeder Klick auf einen Befehl ein Ziehen. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). Praxis: Nur bei DragMode = dmAutomatic sichtbar, z. B. wenn der Anwender die ganze Leiste auf eine andere Fläche ziehen darf. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. Praxis: Nicht nötig, die Leiste zeichnet immer flackerfrei. Steht nur da, damit alte Formulare ohne Fehler laden. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. Praxis: True lassen; bei PPGlow-Controls ohne sichtbare Wirkung. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` Praxis: Einschalten, wenn die Leiste nicht bündig am Rand der Karte kleben soll; die Abstände kommen dann aus Margins. |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. Praxis: Nur bei Align = alNone von Bedeutung; im Code z. B. ToolBar.SetBounds(16, 16, 418, 40). |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. Praxis: Wie Left: nur bei Align = alNone von Bedeutung. |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Mit Align = alTop folgt die Breite dem Fenster. Bei alNone bestimmt Width, wie viele Befehle sichtbar sind; der Rest steht im „…"-Menü. |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Mit AutoSize = True bestimmt die Schrift die Höhe (40 Pixel bei Segoe UI 9). Nur ohne AutoSize von Hand setzen, z. B. um mehrere Leisten exakt gleich hoch zu halten. |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. Praxis: crDefault lassen; Symbolleisten zeigen in Windows den normalen Pfeil, die Hover-Fläche zeigt schon, was klickbar ist. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` Praxis: Hint der Leiste selbst wird kaum gebraucht; die Tooltips der Befehle stehen in Items[].Hint (ohne Hint und mit ShowCaptions = False zeigt die Leiste die Caption). |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. Praxis: htKeyword, wenn Ihre Hilfe mit Stichwörtern arbeitet, sonst htContext. Ohne Hilfedatei egal. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. Praxis: Wie HelpContext, aber über ein Stichwort (HelpType = htKeyword), z. B. „Symbolleiste". |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). Praxis: Kontext-ID der Hilfeseite, die F1 öffnet, solange die Leiste den Fokus hat, z. B. die Seite „Befehle der Kundenliste". |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. Praxis: Abstände zur Umgebung bei Align, z. B. Margins.Left = 8, damit die Leiste mit dem Inhalt darunter fluchtet. Wirkt nur mit AlignWithMargins. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. Praxis: Für Tooltips mit Titel und Symbol einen TPPGCustomHint zuweisen; die Texte kommen weiter aus Items[].Hint. |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. Praxis: True lassen, damit ein am Formular gesetzter CustomHint auch für die Tooltips der Befehle gilt. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) Praxis: Sprechend benennen, z. B. tbKunden oder tbEditor, damit im Code klar ist, zu welcher Liste die Leiste gehört. |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). Praxis: Freier Wert, z. B. um mehrere gleich gebaute Leisten in einem gemeinsamen OnItemClick zu unterscheiden. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` Praxis: Auf Touch-Geräten z. B. Wischen nach links auf der Leiste für „Zurück" auswerten (EventInfo.GestureID). |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. Praxis: Z. B. einen Hinweis in der Statusleiste zeigen („Pfeiltasten wählen den Befehl, Enter führt ihn aus"). |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. Praxis: Gegenstück zu OnEnter: den Hinweis in der Statusleiste wieder löschen. |
| `OnItemClick` | `TPPGToolItemEvent` `(Sender: TObject; Item: TPPGToolItem)` | Ein Item wurde ausgelöst (nach Item.OnClick bzw. Action.Execute); Item ist der Befehl. Praxis: Ein Handler für alle Befehle: Item.Tag als Befehls-ID nutzen und per case verteilen. Läuft nach Items[].OnClick bzw. der Action, eignet sich also auch zum Protokollieren oder für einen Zähler „zuletzt benutzt". |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. Praxis: Selten gebraucht: feuert bei jedem Klick auf die Leiste, auch neben die Befehle. Für Befehle Items[].OnClick oder OnItemClick nehmen. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. Praxis: Selten gebraucht; die Befehle lösen beim Loslassen aus. Mit PartAt(X, Y) erfahren Sie, welcher Befehl unter der Maus liegt. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. Praxis: Mit PartAt(X, Y) den Befehl unter der Maus bestimmen, z. B. um seinen Langtext in der Statusleiste zu zeigen. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. Praxis: Selten gebraucht; die eigentliche Aktion gehört in OnItemClick bzw. Items[].OnClick. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. Praxis: Z. B. eine Hilfezeile einblenden, sobald die Maus über die Leiste kommt. Die Hover-Optik je Befehl zeichnet die Leiste selbst. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. Praxis: Gegenstück zu OnMouseEnter: die Hilfezeile wieder ausblenden. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. Praxis: Selten gebraucht; Handled := True verhindert, dass das Fenster darunter scrollt. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. Praxis: Nur in Werkzeugfenstern ändern, die beim Klick auf die Leiste nicht aktiv werden sollen; sonst nicht belegen. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. Praxis: Um ein Kontextmenü der Leiste anzupassen, z. B. „Leiste anpassen …" nur für Administratoren freigeben. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. Praxis: Wenn etwas auf die Leiste gezogen werden darf, z. B. eine Datei auf die Leiste eines Dokumentenfensters: hier das Ablegen verarbeiten. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. Praxis: Zusammen mit OnDragDrop: Accept nur für passende Quellen auf True setzen. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. Praxis: Beim Ziehen der Leiste (DragMode = dmAutomatic) ein eigenes DragObject setzen. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). Praxis: Nach dem Ziehen der Leiste selbst (DragMode = dmAutomatic): Target = nil heißt abgebrochen. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` Praxis: Für zusätzliche Tasten, solange die Leiste den Fokus hat. Links/Rechts, Pos1/Ende, Enter und Leertaste erledigt die Leiste selbst. |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. Praxis: Selten gebraucht; Zeichentasten lösen keine Befehle aus. Tastenkürzel für Befehle besser über Actions (ShortCut) vergeben. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. Praxis: Selten gebraucht, z. B. um eine Vorschau zu beenden, wenn eine Taste losgelassen wird. |

Tests: `PPG.Tests.Audit11C` (TAudit11CBehaviourTests); `PPG.Tests.Audit45` (TEffectFixTests, TNamingTests, TStreamingFixTests); `PPG.Tests.Audit5d`; `PPG.Tests.Audit8A` (TAudit8APaintTests, TAudit8ARepaintCountTests); `PPG.Tests.Custom` (TCustomBarTests); `PPG.Tests.Phase7c` (TBreadcrumbTests, TPhase7cPaintTests, TToolBarTests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGToolBar.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
