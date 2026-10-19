# TPPGRadioButton

Palette **PPGlow** - Unit `PPG.RadioButton` - Basis `TPPGCustomRadioButton`

**Vorbild:** TRadioButton

## Wofür

Der RadioButton bietet eine Wahl aus wenigen, sich gegenseitig ausschließenden Möglichkeiten: Versandart, Exportformat, Zahlungsweise. Alle Optionen sind gleichzeitig sichtbar, genau eine ist gewählt. Gruppen bilden sich über den gemeinsamen Parent und `GroupIndex`, die Bedienung mit Tab und Pfeiltasten entspricht Windows.

## Wann verwenden

- Für zwei bis etwa sechs Optionen, die der Anwender vergleichen soll. Bei mehr Optionen oder wenig Platz ist `TPPGComboBox` besser.
- Statt `TPPGRadioGroup`, wenn die Optionen frei angeordnet werden oder eigene Zusätze brauchen (eigenes `Enabled`, `Hint`, ein Eingabefeld direkt neben einer Option). Für eine einfache Liste von Optionen in einem Rahmen ist die RadioGroup mit `Items` und `ItemIndex` kürzer.
- Nicht für Ein/Aus: Ein einzelner Zustand gehört in `TPPGCheckBox` (Einstellung, die mit OK gilt) oder `TPPGToggleSwitch` (wirkt sofort). Ein einzelner RadioButton lässt sich nicht wieder ausschalten.
- Nicht für Befehle: Was sofort etwas tut, ist ein `TPPGButton`; als Umschalter in einer Leiste ein Button mit `GroupIndex`.

## Unterschiede und Hinweise

- Gruppe = gleicher Parent und gleicher `GroupIndex` (die VCL kennt nur den Parent). Mit `GroupIndex` lassen sich mehrere Gruppen in einem Container trennen.
- Klick, Leertaste, Pfeiltaste und Zugriffstaste schalten nur ein, nie aus. Die Pfeiltasten wechseln innerhalb der Gruppe nach `TabOrder` (mit Umlauf) und wählen die neue Option.
- Nur die gewählte Option der Gruppe (ohne Auswahl die erste nach `TabOrder`) ist Tabstopp; `TabStop` verwaltet die Gruppe selbst.
- `Checked` im Code schaltet die anderen der Gruppe aus und löst nur `OnChange` aus, `OnClick` nicht. `OnChange` kommt auch für die Option, die ausgeschaltet wird.

## Verhalten (aus dem Quelltext)

TPPGRadioButton - Optionsfeld. Innerhalb desselben Parents und derselben
GroupIndex ist immer hoechstens einer eingeschaltet.

Bedienung wie unter Windows:
- Klick/Leertaste schaltet ein (nie aus).
- Pfeiltasten wechseln innerhalb der Gruppe (nach TabOrder, mit Umlauf) und schalten den neuen RadioButton ein.

Stolperstein: Pfeiltasten verarbeitet sonst das Formular (Fokuswechsel).
Deshalb meldet WM_GETDLGCODE DLGC_WANTARROWS.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Das Standard-Preset wird nicht in der DFM gespeichert. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. Praxis: Die Optik einmal für die ganze Anwendung festlegen, am besten über einen TPPGStyleManager; dann sehen Optionen, Häkchen und Buttons gleich aus. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Im Objektinspektor sind diese drei Properties dann ausgeblendet (bei Mehrfachauswahl nur, wenn alle markierten Controls einen Manager haben) und werden nicht in die DFM geschrieben; nach dem Leeren erscheinen sie sofort wieder. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. Praxis: Einen TPPGStyleManager aufs Formular legen und allen Optionen zuweisen; so wechselt die ganze Seite Preset und Farben auf einmal. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. In der DFM stehen nur die Werte, die vom Preset abweichen; der Rest kommt beim Laden aus dem Preset. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` Praxis: Meist unverändert lassen. Checked färbt den gewählten Kreis, FocusColor den Fokusring; für Akzentfarben einmal im StyleManager statt an jeder Option. |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. Praxis: An lassen; der Kreis füllt sich dann weich. RespectSystemSettings = True schaltet die Animation aus, wenn der Anwender das in Windows so eingestellt hat. |
| `Alignment` | `TLeftRight` | `taRightJustify` | Lage der Beschriftung zum Kästchen: taRightJustify = Text rechts (Standard), taLeftJustify = Text links. Praxis: taRightJustify (Text rechts vom Kreis) ist unter Windows üblich. taLeftJustify nur in Tabellen-Layouts, in denen die Kreise rechtsbündig in einer Spalte stehen sollen. |
| `GroupIndex` | `Integer` | `0` | Gruppennummer: Innerhalb desselben Parents und GroupIndex ist höchstens ein RadioButton eingeschaltet. So lassen sich mehrere Gruppen in einem Container ohne GroupBox trennen. Nutzung: `rbA.GroupIndex := 1; rbB.GroupIndex := 1; rbX.GroupIndex := 2;` Praxis: Mehrere Gruppen im selben Container trennen, ohne extra GroupBox: Format = 1, Umfang = 2. Optionen in verschiedenen Containern sind ohnehin getrennt; dort 0 lassen. |
| `Checked` | `Boolean` | `False` | True = angehakt bzw. eingeschaltet. Setzen löst OnChange (und bei Klick OnClick) aus. Praxis: Beim Öffnen genau eine Option vorwählen, meist die übliche oder die gespeicherte Einstellung. Im Code Checked := True setzen; die anderen der Gruppe schalten sich selbst aus, OnChange feuert, OnClick nicht. |
| `Spacing` | `Integer` | `4` | Abstand zwischen Bild und Text in logischen Pixeln (wird mit der DPI skaliert). Praxis: Abstand Kreis–Text; die Vorgabe 4 passt meist. Bei größerer Schrift etwas mehr, damit der Text nicht am Kreis klebt. |
| `WordWrap` | `Boolean` | `False` | True: Die Beschriftung bricht um; mit AutoSize wächst dann die Höhe statt der Breite. Praxis: Für Optionen mit erklärendem Text in schmalen Spalten einschalten; Height erhöhen oder AutoSize einschalten, damit die zweite Zeile sichtbar ist. |
| `ShowFocusRect` | `Boolean` | `True` | True: Bei Tastaturfokus wird der Fokusrahmen bzw. -ring gezeichnet. Praxis: True lassen, damit Tastaturbenutzer sehen, welche Option den Fokus hat; mit den Pfeiltasten wandert er durch die Gruppe. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). Praxis: True lassen: Sehbehinderte Anwender mit Hochkontrast sehen dann Kreis und Markierung in klaren Systemfarben. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Action` | `TBasicAction` |  | Verknüpft das Control mit einer Action (TActionList/TActionManager). Beschriftung, Hint, Bild, Enabled, Checked und OnClick kommen dann aus der Action. Nutzung: `Button1.Action := actSpeichern;` Praxis: Selten nötig. Sinnvoll, wenn dieselbe Wahl auch im Menü steht, z. B. „Ansicht: Liste / Kacheln": je Option eine Action mit gleichem GroupIndex, dann folgen Menü und RadioButton demselben Checked. |
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. Praxis: Für Optionen, die untereinander in einer GroupBox stehen: Align = alTop stapelt sie ohne Pixelrechnen, mit AlignWithMargins bekommen sie Luft. Freie Optionen in Formularen bleiben alNone. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` Praxis: [akLeft, akTop, akRight] bei langen Beschriftungen in Dialogen mit veränderbarer Größe, damit der Text beim Verbreitern Platz bekommt. |
| `AutoSize` | `Boolean` |  | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). Praxis: Bei übersetzten Oberflächen einschalten: Die Option wird so breit wie ihr Text und schneidet nichts ab. Mit WordWrap wächst stattdessen die Höhe. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. Praxis: Nur für arabische oder hebräische Oberflächen ändern; der Kreis wandert dann nach rechts, die Pfeiltasten links/rechts tauschen. Am Formular setzen und über ParentBiDiMode vererben. |
| `Caption` | `TCaption` |  | Beschriftung. Ein & vor einem Buchstaben macht ihn zur Zugriffstaste (Alt+Buchstabe). Nutzung: `Button1.Caption := '&Speichern';` Praxis: Die Option kurz und eindeutig benennen („Standard (3-5 Werktage)", „Abholung im Lager"); ein & vergibt die Zugriffstaste (Alt+S wählt die Option direkt). Alle Optionen einer Gruppe gleich formulieren. |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. Praxis: Selten nötig: Mit ParentBackground = True scheint der Hintergrund des Containers durch. Color nur setzen, wenn die Option auf einer farbigen Fläche liegt und ParentBackground aus ist. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` Praxis: MaxWidth begrenzt Optionen mit AutoSize, damit lange Übersetzungen das Layout nicht sprengen; zusammen mit WordWrap bricht der Text dann um. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). Praxis: Nur bei DragMode = dmAutomatic sichtbar; bei Optionsfeldern praktisch nie gebraucht. |
| `DragKind` | `TDragKind` |  | dkDrag = Drag & Drop, dkDock = Andocken beim Ziehen. Praxis: dkDrag lassen; Optionsfelder werden in der Praxis weder gezogen noch angedockt. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. Praxis: dmManual lassen, sonst startet jeder Klick auf die Option ein Ziehen statt sie zu wählen. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. Praxis: Optionen sperren, die gerade nicht möglich sind (Express bei Sperrgut), statt sie auszublenden: Der Anwender sieht, dass es sie gibt. War die gesperrte Option gewählt, im Code auf eine erlaubte ausweichen. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` Praxis: ParentFont lassen, damit Optionen die Formularschrift tragen. Eine empfohlene Option lieber mit dem Zusatz „(empfohlen)" kennzeichnen als mit anderer Schrift. |
| `ParentBackground` | `Boolean` | `True` | True: Der Hintergrund des Parents scheint durch (transparente Wirkung). Praxis: True lassen: Dann sieht man hinter der Option die Fläche der GroupBox oder Karte, auf der sie liegt. |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. Praxis: True lassen, damit die Option der Leserichtung des Formulars folgt. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. Praxis: True, wenn die Option die Farbe des Containers übernehmen soll; meist zusammen mit ParentBackground. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. Praxis: True lassen, damit alle Optionen die Formularschrift tragen. Ändern Sie Font, wird es automatisch False. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). Praxis: True lassen und ShowHint einmal am Formular einschalten, dann zeigen alle Optionen ihre Hints. |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. Praxis: Selten bei Optionen; z. B. „Als Standard merken" per Rechtsklick, um die gewählte Option für das nächste Mal zu speichern. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. Praxis: Einmal am Formular einschalten statt an jeder Option; dann bleibt ParentShowHint True. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. Praxis: Nur bei VCL-Styles wichtig: Nehmen Sie seClient heraus, wenn die Option ihre PPGlow-Farben behalten soll. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). Praxis: Die Optionen einer Gruppe in Lesereihenfolge nummerieren: Die Pfeiltasten wechseln in dieser Reihenfolge, und ohne Auswahl ist die erste der Tabstopp. |
| `TabStop` | `Boolean` | `True` | True: Das Control ist mit Tab erreichbar. Praxis: Verwaltet die Gruppe selbst: Nur die gewählte Option (ohne Auswahl die erste) ist mit Tab erreichbar, innerhalb der Gruppe geht es mit den Pfeiltasten weiter. Nicht von Hand setzen. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. Praxis: Optionen ausblenden, die es für diesen Anwender nie gibt (fehlende Lizenz). Was nur gerade nicht geht, besser mit Enabled = False sperren. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. Praxis: Nur für Touch-Geräte: Gesten anhaken und in OnGesture auswerten. Für das Antippen einer Option nicht nötig. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. Praxis: Bei PPGlow-Controls nicht nötig, sie zeichnen immer flackerfrei. Steht nur da, damit alte Formulare ohne Fehler laden. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. Praxis: True lassen; bei PPGlow-Controls ohne sichtbare Wirkung. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` Praxis: Zusammen mit Align = alTop einschalten, damit gestapelte Optionen nicht aneinanderkleben; Margins.Top = 4 reicht meist. |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. Praxis: Alle Optionen einer Gruppe auf gleiche linke Kante setzen, damit die Kreise eine Linie bilden. Im Code nur bei dynamisch erzeugten Optionen nötig. |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. Praxis: Optionen einer Gruppe mit gleichem Abstand untereinander setzen (z. B. alle 28 Pixel); bequemer ist Align = alTop. |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: So breit, dass die längste Beschriftung der Gruppe passt; alle Optionen einer Gruppe gleich breit wirken ruhiger. Mit AutoSize bestimmt der Text die Breite. |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: 24 Pixel reicht für eine Zeile; mit WordWrap entsprechend höher oder AutoSize einschalten. Bei Touch-Oberflächen 32 Pixel für bequemes Tippen. |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. Praxis: crDefault lassen; Optionsfelder zeigen unter Windows den normalen Pfeil. crHandPoint nur in web-artigen Oberflächen. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` Praxis: Für Folgen, die nicht in die Beschriftung passen, z. B. „Lieferung am nächsten Werktag bei Bestellung bis 14 Uhr". ShowHint am Formular einschalten. |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. Praxis: htKeyword, wenn Sie Stichwörter pflegen, sonst htContext mit Kontext-IDs. Ohne Hilfedatei egal. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. Praxis: Wie HelpContext, aber über ein Stichwort (HelpType = htKeyword); praktisch bei HTML-Hilfen mit Stichwortverzeichnis. |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). Praxis: Nur mit einer Hilfedatei sinnvoll: die Kontext-ID der Seite eintragen, die F1 bei fokussierter Option öffnen soll. |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. Praxis: Abstand zwischen gestapelten Optionen bei Align = alTop, z. B. Margins.Top = 4. Wirkt nur mit AlignWithMargins. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. Praxis: Für eine ausführliche Erklärung einer Option (z. B. was „Sperrgut" bedeutet) einen TPPGCustomHint mit Titel zuweisen; für die ganze Anwendung ist TPPGHintManager bequemer. |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. Praxis: True lassen, damit ein am Formular gesetzter CustomHint auch hier gilt. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) Praxis: Sprechende Namen nach der Option vergeben (rbVersandExpress, rbFormatPdf) statt PPGRadioButton1: Abfragen wie if rbVersandExpress.Checked lesen sich dann von selbst. |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). Praxis: Ein Wert je Option für einen gemeinsamen Handler, z. B. der Preis in Cent oder der Enum-Wert (Ord(fmPdf)); im Handler TPPGRadioButton(Sender).Tag lesen. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Checked bzw. State hat sich geändert (Klick, Tastatur oder Code). Praxis: Für alles, was der Auswahl folgen muss (Preis, Zusammenfassung, Felder sperren), egal ob Klick, Pfeiltaste oder Checked im Code. Feuert auch für die Option, die ausgeschaltet wird, deshalb den Gesamtzustand lesen statt nur den Sender. |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` Praxis: Auf Touch-Geräten: Wischgesten auswerten (EventInfo.GestureID). Für das Antippen einer Option nicht nötig. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. Praxis: Für Reaktionen nur auf Bedienung durch den Anwender (Klick, Leertaste, Pfeiltaste, Alt+Zugriffstaste). Ein gemeinsamer Handler für alle Optionen der Gruppe, die Option über Sender oder Tag unterscheiden. Checked im Code löst ihn nicht aus. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. Praxis: Um das Kontextmenü vor dem Öffnen anzupassen (Einträge sperren) oder mit Handled := True ganz zu unterdrücken. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. Praxis: Bei Optionsfeldern selten; z. B. eine Datei auf „Als Vorlage verwenden" ziehen und die Option dabei wählen. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. Praxis: Zusammen mit OnDragDrop: Accept := True nur für passende Quellen. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. Praxis: Nur bei DragKind = dkDock; bei Optionsfeldern praktisch nie gebraucht. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). Praxis: Nur wenn die Option selbst gezogen wird (DragMode); bei Optionsfeldern praktisch nie gebraucht. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. Praxis: Für eine Erklärung der Option in der Statusleiste oder einem Hilfefeld, sobald sie per Tab oder Pfeiltaste den Fokus bekommt. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. Praxis: Selten nötig; z. B. um die Erklärung aus OnEnter wieder zu löschen. Prüfungen gehören in OnChange. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` Praxis: Feuert vor dem Wechsel mit den Pfeiltasten: Key := 0 verhindert ihn, z. B. solange eine Rückfrage offen ist. Leertaste und Pfeile erledigt die Option sonst selbst. |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. Praxis: Selten für Optionen; für Tastenkürzel besser die Zugriffstaste (&) in Caption nehmen. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. Praxis: Selten für Optionen; z. B. um nach dem Loslassen einer Pfeiltaste eine teure Vorschau einmal statt bei jedem Wechsel zu rechnen. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. Praxis: Selten für Optionen; die Reaktion auf die Wahl gehört in OnClick bzw. OnChange. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. Praxis: Um beim Überfahren eine Vorschau der Option zu zeigen, z. B. das Layout „Kacheln" schon andeuten, bevor der Anwender klickt. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. Praxis: Gegenstück zu OnMouseEnter: die Vorschau wieder auf die gewählte Option zurückstellen. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. Praxis: Selten für Optionen; feuert bei jeder Mausbewegung. Für Hover-Effekte reicht Appearance. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. Praxis: Selten für Optionen; die Reaktion auf die Wahl gehört in OnClick bzw. OnChange. |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. Praxis: Nur bei DragKind = dkDock; bei Optionsfeldern praktisch nie gebraucht. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. Praxis: Nur wenn die Option selbst gezogen wird (DragMode = dmAutomatic); bei Optionsfeldern praktisch nie gebraucht. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. Praxis: Selten für Optionen; das Mausrad sollte den umgebenden Bereich scrollen, nicht die Auswahl ändern. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. Praxis: Nur in Spezialfällen (Werkzeugfenster, die beim Klick nicht aktiv werden sollen) ändern; sonst nicht belegen. |

Tests: `PPG.Tests.Audit5d`; `PPG.Tests.Audit7B` (TAudit7BTests); `PPG.Tests.Check` (TCheckPaintTests, TRadioButtonTests); `PPG.Tests.Gaps` (TAccessibilityTests); `PPG.Tests.Phase8` (TFluent11Tests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGRadioButton.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
