# TPPGCheckBox

Palette **PPGlow** - Unit `PPG.CheckBox` - Basis `TPPGCustomCheckBox`

**Vorbild:** TCheckBox

## Wofür

Die CheckBox fragt eine Ja/Nein-Entscheidung ab, die erst mit dem Speichern oder Absenden gilt: „Newsletter abonnieren“, „AGB akzeptiert“, „Lieferadresse wie Rechnungsadresse“. Mehrere CheckBoxen stehen für unabhängige Optionen, von denen beliebig viele gelten dürfen. Mit `State = cbGrayed` zeigt sie zusätzlich „teilweise“, z. B. bei „Alle auswählen“ über einer Liste.

## Wann verwenden

- Für Optionen in Formularen und Dialogen, die mit OK bzw. Speichern übernommen werden. Für Einstellungen, die sofort wirken (an/aus wie in den Windows-Einstellungen), ist `TPPGToggleSwitch` klarer.
- Statt `TPPGRadioButton` bzw. `TPPGRadioGroup`, wenn die Optionen unabhängig sind. Muss genau eine von mehreren gelten, nehmen Sie Optionsfelder.
- Statt mehrerer einzelner CheckBoxen eine `TPPGCheckGroup` (feste Liste in einem Rahmen) oder `TPPGCheckListBox` (lange oder veränderliche Liste), wenn die Optionen aus Daten kommen.
- Statt `TPPGButton` mit `GroupIndex`/`Down`, wenn der Zustand eine Einstellung ist und kein Befehl in einer Symbolleiste.

## Unterschiede und Hinweise

- `Checked`/`State` im Code setzen löst nur `OnChange` aus, nicht `OnClick` (bewusst anders als die VCL).
- Der gemischte Zustand (`cbGrayed`) ist ein Akzent-Strich; Anwender erreichen ihn nur mit `AllowGrayed = True`.

## Beispiel

```pascal
PPGCheckBox1.AllowGrayed := True;
PPGCheckBox1.State := cbGrayed;  // OnChange, kein OnClick
```

## Verhalten (aus dem Quelltext)

TPPGCheckBox - Kontrollkaestchen mit optionalem dritten Zustand
(AllowGrayed). Ereignis-Semantik siehe PPG.Controls.Check.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Das Standard-Preset wird nicht in der DFM gespeichert. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. Praxis: Die Optik einmal für die ganze Anwendung festlegen, am besten über einen TPPGStyleManager. Dann sehen CheckBoxen, Optionsfelder und Schalter in einem Formular gleich aus. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. Praxis: Einen TPPGStyleManager aufs Formular legen und allen CheckBoxen zuweisen. Ein Befehl wechselt dann die Optik aller Kästchen, auch Hell/Dunkel. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. In der DFM stehen nur die Werte, die vom Preset abweichen; der Rest kommt beim Laden aus dem Preset. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` Praxis: Appearance.Checked färbt das angehakte Kästchen (Fläche und Haken). Für eine eigene Markenfarbe besser das Preset bzw. den StyleManager anpassen statt jede CheckBox einzeln. |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. Praxis: An lassen: Der Haken blendet weich ein. RespectSystemSettings = True schaltet das ab, wenn der Anwender in Windows Animationen abgeschaltet hat. |
| `Alignment` | `TLeftRight` | `taRightJustify` | Lage der Beschriftung zum Kästchen: taRightJustify = Text rechts (Standard), taLeftJustify = Text links. Praxis: taRightJustify (Text rechts vom Kästchen) ist der Normalfall in Formularen. taLeftJustify passt, wenn Beschriftungen in einer Spalte links stehen und die Kästchen rechts bündig untereinander sollen. |
| `AllowGrayed` | `Boolean` | `False` | True: Ein Klick schaltet zusätzlich durch den unbestimmten Zustand (cbGrayed), z. B. für „teilweise ausgewählt". Praxis: Nur einschalten, wenn der Anwender „unbestimmt" bewusst wählen soll, z. B. „Wert nicht ändern" bei Massenbearbeitung. Für „Alle auswählen" über einer Liste False lassen und cbGrayed im Code setzen. |
| `State` | `TPPGCheckState` | `cbUnchecked` | Zustand: cbUnchecked, cbChecked oder cbGrayed (unbestimmt). Per Klick erreicht der Anwender cbGrayed nur mit AllowGrayed; im Code geht cbGrayed immer, z. B. für „teilweise ausgewählt". Praxis: Zustand lesen oder setzen, wenn es drei Zustände gibt, z. B. cbGrayed für „teilweise ausgewählt". Für einfaches Ja/Nein reicht zur Laufzeit Checked. Setzen im Code löst nur OnChange aus. |
| `Spacing` | `Integer` | `4` | Abstand zwischen Bild und Text in logischen Pixeln (wird mit der DPI skaliert). Praxis: Abstand Kästchen–Text; die Vorgabe 4 passt meist. Größer nur, wenn mehrere CheckBoxen mit Optionsfeldern in einer Spalte optisch fluchten sollen. |
| `WordWrap` | `Boolean` | `False` | True: Die Beschriftung bricht um; mit AutoSize wächst dann die Höhe statt der Breite. Praxis: Für lange Beschriftungen wie „Ich habe die AGB gelesen und akzeptiere sie": umbrechen statt abschneiden. Höhe für zwei Zeilen geben oder AutoSize einschalten. |
| `ShowFocusRect` | `Boolean` | `True` | True: Bei Tastaturfokus wird der Fokusrahmen bzw. -ring gezeichnet. Praxis: True lassen, damit Tastaturbenutzer sehen, welches Kästchen die Leertaste umschaltet (Barrierefreiheit). |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). Praxis: True lassen: Im Windows-Hochkontrast sieht man Kästchen und Haken dann in klaren Systemfarben. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Action` | `TBasicAction` |  | Verknüpft das Control mit einer Action (TActionList/TActionManager). Beschriftung, Hint, Bild, Enabled, Checked und OnClick kommen dann aus der Action. Nutzung: `Button1.Action := actSpeichern;` Praxis: Für Einstellungen, die auch im Menü stehen (z. B. „Statusleiste anzeigen"): eine Action mit AutoCheck anlegen und CheckBox und Menüeintrag zuweisen. Checked bleibt dann überall gleich. |
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. Praxis: Für Optionslisten, die mit dem Fenster wachsen: CheckBoxen in einem Panel mit Align = alTop untereinander stapeln. Freie CheckBoxen in Formularen bleiben alNone. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` Praxis: [akLeft, akTop, akRight] bei CheckBoxen mit langem Text in Dialogen mit veränderbarer Größe: Die Breite wächst mit, WordWrap bricht dann seltener um. |
| `AutoSize` | `Boolean` |  | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). Praxis: Bei übersetzten Oberflächen einschalten: Die CheckBox wird so breit wie ihr Text, und Klicks auf den Text treffen immer. Mit WordWrap wächst die Höhe. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. Praxis: Nur für arabische oder hebräische Oberflächen ändern; dann steht das Kästchen rechts. Am Formular setzen und über ParentBiDiMode folgen lassen. |
| `Caption` | `TCaption` |  | Beschriftung. Ein & vor einem Buchstaben macht ihn zur Zugriffstaste (Alt+Buchstabe). Nutzung: `Button1.Caption := '&Speichern';` Praxis: Positiv und als Aussage formulieren („Rechnung per E-Mail senden", nicht „Keine Papierrechnung"). Ein & vergibt die Zugriffstaste, Alt+Buchstabe schaltet dann um. |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. Praxis: Bei der CheckBox selten nötig; mit ParentBackground = True scheint der Hintergrund des Panels durch. Die Farben des Kästchens stehen in Appearance. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` Praxis: Mit AutoSize oder Anchors: MaxWidth begrenzt sehr lange Beschriftungen, MinHeight hält die Klickfläche bei kleiner Schrift groß genug. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). Praxis: Nur bei DragMode = dmAutomatic sichtbar, z. B. beim Umsortieren von Optionen in einem Einstellungs-Editor. |
| `DragKind` | `TDragKind` |  | dkDrag = Drag & Drop, dkDock = Andocken beim Ziehen. Praxis: dkDrag lassen; Andocken (dkDock) ist für CheckBoxen praktisch nie sinnvoll. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. Praxis: dmManual lassen, sonst startet jeder Klick ein Ziehen statt das Kästchen umzuschalten. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. Praxis: Sperren Sie Optionen, die gerade nicht gelten, statt sie zu verstecken, z. B. „Anhang mitsenden" ohne Anhang. Der Zustand bleibt dabei sichtbar. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` Praxis: Font.Style = [fsBold] für eine übergeordnete CheckBox wie „Alle auswählen". Sonst ParentFont lassen, damit alle Optionen die Formularschrift tragen. |
| `ParentBackground` | `Boolean` | `True` | True: Der Hintergrund des Parents scheint durch (transparente Wirkung). Praxis: True lassen: Dann liegt die CheckBox ohne Kasten auf Karten, Panels und Gruppen und übernimmt deren Hintergrund. |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. Praxis: True lassen, damit die CheckBox der Leserichtung des Formulars folgt. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. Praxis: True, wenn der Hintergrund die Farbe des Parents haben soll; meist zusammen mit ParentBackground. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. Praxis: True lassen, damit alle Optionen die Formularschrift tragen. Ändern Sie Font, wird es automatisch False. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). Praxis: True lassen und ShowHint einmal am Formular einschalten, dann zeigen alle Optionen ihre Hints. |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. Praxis: Für Zusatzbefehle per Rechtsklick, z. B. „Auf Vorgabe zurücksetzen" oder „Was bedeutet das?" bei Einstellungen. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. Praxis: Einmal am Formular einschalten statt an jeder CheckBox; dann bleibt ParentShowHint True. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. Praxis: Nur bei VCL-Styles wichtig: Nehmen Sie seClient heraus, wenn die CheckBox ihre eigenen Farben aus Appearance behalten soll. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). Praxis: In der Reihenfolge der Optionen von oben nach unten vergeben, damit Tab der Leserichtung folgt. |
| `TabStop` | `Boolean` | `True` | True: Das Control ist mit Tab erreichbar. Praxis: True lassen, damit jede Option per Tab erreichbar ist und mit der Leertaste umgeschaltet werden kann. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. Praxis: Blenden Sie Optionen aus, die für den Anwender nie gelten (fehlende Lizenz, fehlendes Recht). Was nur gerade nicht geht, besser mit Enabled = False sperren. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. Praxis: Nur für Touch-Geräte mit eigenen Gesten; zum Umschalten genügt das Antippen. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. Praxis: Bei PPGlow-Controls nicht nötig, sie zeichnen immer flackerfrei. Steht nur da, damit alte Formulare ohne Fehler laden. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. Praxis: True lassen; bei PPGlow-Controls ohne sichtbare Wirkung. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` Praxis: Zusammen mit Align einschalten, damit gestapelte CheckBoxen etwas Luft haben. Die Abstände stellen Sie unter Margins ein (typisch 2 bis 4 oben und unten). |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. Praxis: Position im Designer per Maus; untergeordnete Optionen etwa 24 Pixel weiter rechts einrücken als die übergeordnete CheckBox. |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. Praxis: Wie Left: im Designer per Maus. Gleicher Abstand zwischen den Zeilen (z. B. 30 Pixel) wirkt ruhig. |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: So breit, dass der ganze Text passt, denn auch ein Klick auf den Text schaltet um. Mit AutoSize bestimmt der Text die Breite. |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: 24 Pixel reicht für eine Zeile; bei WordWrap mit zwei Zeilen etwa 44. Mit AutoSize bestimmt der Text die Höhe. |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. Praxis: crDefault lassen; Windows-CheckBoxen zeigen den Pfeil. crHandPoint nur, wenn die CheckBox wie ein Link in Fließtext steht. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` Praxis: Für Optionen, deren Folgen nicht offensichtlich sind: „Höchstens einmal im Monat, jederzeit abbestellbar". Der Hint erscheint nur mit ShowHint. |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. Praxis: htKeyword, wenn Sie Stichwörter pflegen, sonst htContext mit Kontext-IDs. Ohne Hilfedatei egal. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. Praxis: Wie HelpContext, aber über ein Stichwort (HelpType = htKeyword); praktisch bei HTML-Hilfen mit Stichwortverzeichnis. |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). Praxis: Nur mit einer Hilfedatei sinnvoll: die Kontext-ID der Seite eintragen, die F1 bei fokussierter CheckBox öffnet, z. B. die Erklärung einer Datenschutz-Option. |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. Praxis: Abstand zwischen gestapelten CheckBoxen bei Align = alTop, z. B. Margins.Top = 4. Wirkt nur mit AlignWithMargins. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. Praxis: Für Hinweise mit Titel und Symbol, z. B. bei Einstellungen mit Folgen („Daten nach 30 Tagen löschen"): einen TPPGCustomHint oder TBalloonHint zuweisen. |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. Praxis: True lassen, damit ein am Formular gesetzter CustomHint auch hier gilt. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) Praxis: Sprechende Namen vergeben (chkNewsletter, chkAgb) statt PPGCheckBox1: if chkAgb.Checked liest sich im Code von selbst. |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). Praxis: Für gleichartige Optionen mit einem gemeinsamen OnChange: Tag = Bit oder Modulnummer, auszuwerten über TPPGCheckBox(Sender).Tag. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Checked bzw. State hat sich geändert (Klick, Tastatur oder Code). Praxis: Hier gehört die Reaktion auf den Zustand hin, z. B. ein Feld freigeben oder den OK-Button schalten. Feuert auch beim Setzen im Code, deshalb bleibt die Oberfläche immer passend. |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` Praxis: Auf Touch-Geräten selten gebraucht; das Antippen schaltet das Kästchen schon um. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. Praxis: Für Reaktionen, die nur bei Bedienung durch den Anwender laufen sollen, z. B. „Alle auswählen" schaltet alle Einträge. Setzen von Checked im Code löst es nicht aus, so entsteht keine Rekursion. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. Praxis: Um das Kontextmenü vor dem Öffnen anzupassen, z. B. „Auf Vorgabe zurücksetzen" nur bei geänderter Option freigeben. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. Praxis: Selten für CheckBoxen; z. B. in einem Editor, in dem Optionen per Ziehen umsortiert werden. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. Praxis: Zusammen mit OnDragDrop: Accept := Source is TPPGCheckBox erlaubt nur das Umsortieren anderer Optionen. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. Praxis: Nur bei DragKind = dkDock; für CheckBoxen praktisch nie nötig. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). Praxis: Nach dem Ziehen einer CheckBox: Target = nil heißt abgebrochen, sonst die neue Reihenfolge speichern. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. Praxis: Für einen erklärenden Text in der Statusleiste oder einem Hilfebereich, sobald die Option per Tab den Fokus bekommt. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. Praxis: Selten nötig; z. B. den Hilfetext aus OnEnter wieder löschen. Zustandsprüfungen gehören in OnChange. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` Praxis: Für zusätzliche Tasten an der fokussierten CheckBox, z. B. Entf setzt auf die Vorgabe zurück. Die Leertaste schaltet schon selbst um. |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. Praxis: Selten nötig; Zeichentasten schalten nicht um. Für Kürzel die Zugriffstaste (&) in Caption nehmen. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. Praxis: Selten nötig; Gegenstück zu OnKeyDown, wenn eine Aktion erst beim Loslassen enden soll. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. Praxis: Selten nötig; das Umschalten erledigt der Klick. Für die Reaktion OnChange bzw. OnClick nehmen. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. Praxis: Um beim Überfahren eine Erklärung der Option zu zeigen, z. B. in einem Hilfebereich neben einer Einstellungsliste. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. Praxis: Gegenstück zu OnMouseEnter: die Erklärung wieder ausblenden. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. Praxis: Selten nötig; feuert bei jeder Mausbewegung. Für Hover-Effekte reicht Appearance.Hot. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. Praxis: Selten nötig; die Aktion zum Umschalten gehört in OnChange bzw. OnClick. |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. Praxis: Nur bei DragKind = dkDock; für CheckBoxen praktisch nie nötig. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. Praxis: Beim Ziehen einer Option (DragMode = dmAutomatic) ein eigenes DragObject setzen, z. B. mit Vorschau. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. Praxis: Selten für CheckBoxen; Handled := True nur, wenn das Rad über der Option nicht die Seite scrollen soll. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. Praxis: Nur in Spezialfällen (Werkzeugfenster, die beim Klick nicht aktiv werden sollen) belegen. |

Tests: `PPG.Tests.Audit5d`; `PPG.Tests.Check` (TCheckBoxTests, TCheckPaintTests); `PPG.Tests.Custom` (TCustomAppearanceTests); `PPG.Tests.DBGridEditForm` (TDBGridEditFormTests); `PPG.Tests.Gaps` (TAccessibilityTests, TButtonFeatureTests, TVclStyleTests); `PPG.Tests.Phase18` (TPanelScrollTests); `PPG.Tests.Phase19` (TValidatorTests); `PPG.Tests.Phase3` (TContainerTests); `PPG.Tests.Phase5` (TParentBackgroundTests); `PPG.Tests.Phase8` (TFluent11Tests, TThemeTests); `PPG.Tests.Phase9a` (TPresetTargetTests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGCheckBox.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
