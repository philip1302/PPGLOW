# TPPGDBToggleSwitch

Palette **PPGlow DB** - Unit `PPG.DB.Controls` - Basis `TPPGToggleSwitch`

Schalter an einem Ja/Nein-Feld (Boolean oder ValueChecked/ValueUnchecked wie TDBCheckBox). Schreibt beim Umschalten ins Feld.

**Vorbild:** TDBCheckBox (Schalter statt Kästchen)

## Wofür

Ein Ein/Aus-Schalter an einem Ja/Nein-Feld (Aktiv, Gesperrt, Newsletter).

## Wann verwenden

- Wenn ein `TPPGDBCheckBox` als Schalter aussehen soll.
- Für Boolean-Felder und für Text-/Zahlenfelder mit festen Werten (`ValueChecked`/`ValueUnchecked`).

## Unterschiede und Hinweise

- Boolean-Felder direkt; sonst `ValueChecked`/`ValueUnchecked` (mehrere Werte mit Semikolon, der erste wird geschrieben), Vorgabe `True`/`False`.
- Ein leeres Feld (Null) oder ein unbekannter Wert zeigt den Zwischenzustand (`State = cbGrayed`); der erste Klick schaltet ein.
- Beim Umschalten geht der Datensatz in den Bearbeiten-Modus; `ReadOnly` oder eine nicht änderbare Datenmenge verhindern das. Esc setzt den Feldwert zurück.
- `Checked` wird nicht gespeichert, der Zustand kommt aus dem Feld.

## Beispiel

```pascal
DBToggleSwitch1.DataSource := DataSource1;
DBToggleSwitch1.DataField := 'Status';
DBToggleSwitch1.ValueChecked := 'J';
DBToggleSwitch1.ValueUnchecked := 'N';
```

## Verhalten (aus dem Quelltext)

Datenbank-Controls (Phase 9c): TPPGDBEdit, TPPGDBMemo, TPPGDBCheckBox,
TPPGDBComboBox, TPPGDBDatePicker. Dazu (Inventur): TPPGDBText (Ersatz fuer
TDBText) und TPPGDBToggleSwitch (Schalter an einem Ja/Nein-Feld).

Eigenes Package (PPGlowDBR): Anwendungen ohne Datenbank linken kein Data.DB.
Die Controls erben von den PPGlow-Controls und fuegen nur die Anbindung
hinzu - keine zweite Zeichenlogik.

Gemeinsame Anbindung (Audit 4a): TPPGDBBinding haelt den Link und erledigt,
was alle DB-Controls gleich machen (auch PPG.DB.Fields, PPG.DB.Lookup und
TPPGDBRadioGroup). Das Control liefert nur Anzeigen (OnShow) und Schreiben
(OnWrite) und reicht DataField/DataSource/ReadOnly, CM_GETDATALINK,
CM_EXIT, Esc und Actions weiter.

Ablauf wie bei den VCL-DB-Controls:
- Datensatz wechselt (DataChange): Wert aus dem Feld anzeigen (mit Fokus Field.Text, ohne Field.DisplayText).
- Anwender aendert: zuerst den Datensatz in den Bearbeiten-Modus setzen (TPPGFieldDataLink.EditByUser), dann Modified. Waehrend EditByUser darf DataChange den neuen Wert nicht ueberschreiben (Sperre). Geht das nicht, wird der Feldwert wieder angezeigt.
- Verlassen (CM_EXIT): UpdateRecord schreibt ins Feld. Ein ungueltiger Wert setzt ValidationState = pvsError mit der Meldung als ValidationHint, behaelt den Fokus und bricht still ab (kein Dialog).
- Esc waehrend der Bearbeitung: Wert aus dem Feld zuruecksetzen.

Fallstrick (Roadmap): TDataLink-Ereignisse kommen auch, waehrend gezeichnet
wird (berechnete Felder). Die Handler setzen deshalb nur Werte; Zeichnen
passiert immer erst im naechsten Paint.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `DataField` | `string` |  | Name des Felds der Datenmenge, das angezeigt und bearbeitet wird (Boolean-Feld oder ein Feld mit ValueChecked/ValueUnchecked). |
| `DataSource` | `TDataSource` |  | Datenquelle mit der Datenmenge, aus der DataField kommt. |
| `ReadOnly` | `Boolean` | `False` | True: Der Wert wird angezeigt, kann aber nicht geändert werden. |
| `ValueChecked` | `string` |  | Wert(e) für „an“ bei Feldern, die kein Boolean sind; mehrere durch Semikolon getrennt, geschrieben wird der erste (wie TDBCheckBox). Vorgabe „True“. Nutzung: `DBToggleSwitch1.ValueChecked := 'J;Ja;1'; DBToggleSwitch1.ValueUnchecked := 'N;Nein;0';` |
| `ValueUnchecked` | `string` |  | Wert(e) für „aus“; mehrere durch Semikolon getrennt, geschrieben wird der erste. Vorgabe „False“. |
| `Checked` | `Boolean` | `False` | True = angehakt bzw. eingeschaltet. Setzen löst OnChange (und bei Klick OnClick) aus. Praxis: Beim Öffnen der Einstellungen aus der Konfiguration setzen (swAutoSave.Checked := Config.AutoSave) und in OnChange zurückschreiben. Setzen im Code löst OnChange aus, aber kein OnClick. |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. Praxis: Die Optik einmal für die ganze Anwendung festlegen, am besten über einen TPPGStyleManager. Fluent11 zeichnet den Schalter wie in den Windows-11-Einstellungen, ModernFlat flach mit Glow. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. Praxis: Einen TPPGStyleManager aufs Formular legen und allen Schaltern zuweisen; dann folgen sie gemeinsam Preset und Hell/Dunkel der Anwendung. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` Praxis: Appearance.Normal färbt den ausgeschalteten, Appearance.Checked den eingeschalteten Schalter. Für einen roten „Wartungsmodus“-Schalter nur Checked.Color und Checked.BorderColor ändern. |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. Praxis: An lassen: Der gleitende Knopf zeigt, dass sich etwas geändert hat. Beim Laden des Formulars und solange der Schalter unsichtbar ist, springt er ohne Animation in die neue Lage. |
| `Alignment` | `TLeftRight` | `taRightJustify` | Lage der Beschriftung zum Schalter: taRightJustify = Text rechts vom Schalter (Standard), taLeftJustify = Text links, Schalter am rechten Rand. Praxis: taLeftJustify für Einstellungsseiten wie in Windows: Text links, Schalter bündig am rechten Rand (Width bis zum Rand ziehen). taRightJustify für kurze Schalter in Formularen. |
| `Spacing` | `Integer` | `4` | Abstand zwischen Schalter und Beschriftung in logischen Pixeln (wird mit der DPI skaliert). Praxis: Die Vorgabe 4 passt meist. Etwas mehr (8), wenn Schalter und Text bei großer Schrift zu dicht wirken. |
| `WordWrap` | `Boolean` | `False` | True: Die Beschriftung bricht um; mit AutoSize wächst dann die Höhe statt der Breite. Praxis: Für Schalter mit erklärendem Text in schmalen Spalten („Bei neuen Aufträgen eine E-Mail an den Vertrieb senden“). Height dann von Hand oder mit AutoSize anpassen. |
| `ShowFocusRect` | `Boolean` | `True` | True: Bei Tastaturfokus wird der Fokusrahmen bzw. -ring gezeichnet. Praxis: True lassen, damit Tastaturbenutzer sehen, welcher Schalter mit der Leertaste umgeschaltet wird. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). Praxis: True lassen: Im Hochkontrastmodus zeichnet der Schalter mit Systemfarben, an und aus bleiben klar unterscheidbar. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Action` | `TBasicAction` |  | Verknüpft das Control mit einer Action (TActionList/TActionManager). Beschriftung, Hint, Bild, Enabled, Checked und OnClick kommen dann aus der Action. Nutzung: `Button1.Action := actSpeichern;` Praxis: Wenn derselbe Ein/Aus-Zustand auch im Menü steht (Ansicht > Nur offene Aufträge): eine Action mit AutoCheck anlegen und Schalter und Menüeintrag zuweisen; Checked bleibt dann überall gleich. |
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. Praxis: Auf Einstellungsseiten mit Align = alTop untereinander stapeln; zusammen mit Alignment = taLeftJustify stehen alle Schalter bündig am rechten Rand. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` Praxis: [akLeft, akTop, akRight] für Einstellungsseiten mit Text links und Schalter rechts: Beim Vergrößern des Fensters wandert der Schalter mit dem rechten Rand. |
| `AutoSize` | `Boolean` |  | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). Praxis: Einschalten, wenn die Beschriftung übersetzt wird: Die Breite passt sich dem Text an. Bei Text links und Schalter am rechten Rand ausgeschaltet lassen. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. Praxis: Nur für arabische oder hebräische Oberflächen ändern; Schalter und Text werden dann gespiegelt. Am Formular setzen und über ParentBiDiMode folgen lassen. |
| `Caption` | `TCaption` |  | Beschriftung. Ein & vor einem Buchstaben macht ihn zur Zugriffstaste (Alt+Buchstabe). Nutzung: `Button1.Caption := '&Speichern';` Praxis: Die Einstellung als Hauptwort oder kurze Aussage formulieren („Automatisch speichern“), nicht als Frage oder Befehl. Ein & vergibt die Zugriffstaste (Alt+A schaltet um). |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. Praxis: Selten nötig: Der Schalter zeichnet auf dem Hintergrund des Parents (ParentBackground). Color nur setzen, wenn er auf einer eigenen farbigen Fläche stehen soll. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` Praxis: MinWidth hält Schalter mit AutoSize in einer Liste gleich breit, MaxWidth verhindert, dass lange Übersetzungen die Seite sprengen. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). Praxis: Nur bei DragMode = dmAutomatic sichtbar; bei Schaltern praktisch nie gebraucht. |
| `DragKind` | `TDragKind` |  | dkDrag = Drag & Drop, dkDock = Andocken beim Ziehen. Praxis: dkDrag lassen. Schalter werden nicht gezogen oder angedockt. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. Praxis: dmManual lassen, sonst startet jeder Klick ein Ziehen statt umzuschalten. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. Praxis: Abhängige Einstellungen sperren, solange die übergeordnete aus ist: swSound.Enabled := swNotify.Checked. Der Wert bleibt erhalten und gilt wieder, sobald freigegeben wird. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` Praxis: Über ParentFont die Formularschrift nehmen. Für eine Haupteinstellung über einer Gruppe Font.Style = [fsBold]. |
| `ParentBackground` | `Boolean` | `True` | True: Der Hintergrund des Parents scheint durch (transparente Wirkung). Praxis: True lassen: Der Schalter steht dann sauber auf Panel, Karte oder Formular, ohne eigenen Kasten. |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. Praxis: True lassen, damit der Schalter der Leserichtung des Formulars folgt. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. Praxis: True lassen, damit der Hintergrund zur Fläche passt, auf der der Schalter liegt. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. Praxis: True lassen, damit alle Schalter die Formularschrift tragen. Ändern Sie Font, wird es automatisch False. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). Praxis: True lassen und ShowHint einmal am Formular einschalten. |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. Praxis: Für Zusatzbefehle per Rechtsklick, z. B. „Auf Standard zurücksetzen“ oder „Für alle Benutzer übernehmen“. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. Praxis: Einmal am Formular einschalten statt an jedem Schalter; dann bleibt ParentShowHint True. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. Praxis: Nur bei VCL-Styles wichtig: Ohne seClient behält der Schalter seine Farben aus Appearance statt der Style-Farben. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). Praxis: In Einstellungsseiten von oben nach unten vergeben, damit Tab die Schalter in Lesereihenfolge durchläuft. |
| `TabStop` | `Boolean` | `True` | True: Das Control ist mit Tab erreichbar. Praxis: True lassen: Schalter müssen per Tab erreichbar und mit der Leertaste umschaltbar sein (Barrierefreiheit). |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. Praxis: Einstellungen ausblenden, die der Anwender nicht ändern darf oder die es in seiner Lizenz nicht gibt. Was nur gerade nicht geht, mit Enabled sperren. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. Praxis: Nur für Touch-Geräte mit eigenen Gesten; Tippen schaltet den Schalter ohnehin um. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. Praxis: Nicht nötig, PPGlow-Controls zeichnen immer flackerfrei. Steht nur da, damit alte Formulare ohne Fehler laden. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. Praxis: True lassen; bei PPGlow-Controls ohne sichtbare Wirkung. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` Praxis: Bei gestapelten Schaltern (Align = alTop) einschalten, damit sie Luft zueinander und zum Rand haben. |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. Praxis: Im Designer per Maus; im Code nur bei dynamisch erzeugten Schaltern, z. B. Sw.SetBounds(16, Y, 400, 28). |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. Praxis: Wie Left: im Designer per Maus, im Code nur bei dynamisch erzeugten Schaltern; bei gestapelten Schaltern besser Align = alTop. |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: So breit, dass die Beschriftung ganz passt; bei Text links (taLeftJustify) bis zum rechten Rand der Seite, damit alle Schalter untereinander fluchten. |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Die Vorgabe 28 passt für eine Zeile Text. Mit WordWrap bei zweizeiligem Text etwa 44. |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. Praxis: crDefault lassen; Windows-Schalter zeigen den Pfeil. crHandPoint nur, wenn die Seite sonst mit Link-Optik arbeitet. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` Praxis: Erklärt die Folgen der Einstellung („Speichert alle 5 Minuten im Hintergrund“), wenn die Beschriftung dafür zu kurz ist. ShowHint am Formular einschalten. |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. Praxis: htKeyword, wenn Sie Stichwörter pflegen, sonst htContext. Ohne Hilfedatei egal. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. Praxis: Wie HelpContext, aber über ein Stichwort (HelpType = htKeyword). |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). Praxis: Nur mit Hilfedatei: Kontext-ID der Seite, die F1 bei fokussiertem Schalter öffnet, z. B. die Erklärung der Einstellung. |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. Praxis: Abstand zwischen gestapelten Schaltern bei Align = alTop, z. B. Margins.Top = 4. Wirkt nur mit AlignWithMargins. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. Praxis: Für ausführlichere Erklärungen mit Titel (z. B. was „Offline arbeiten“ genau bewirkt) einen TPPGCustomHint oder TBalloonHint zuweisen. |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. Praxis: True lassen, damit ein am Formular gesetzter CustomHint auch hier gilt. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) Praxis: Sprechend vergeben (swAutoSave, swNotify) statt PPGToggleSwitch1; dann liest sich swNotify.Checked im Code wie die Einstellung selbst. |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). Praxis: Für mehrere Schalter mit einem gemeinsamen OnChange: Tag = Nummer der Einstellung, im Handler über TPPGToggleSwitch(Sender).Tag auswerten. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Checked bzw. State hat sich geändert (Klick, Tastatur oder Code). Praxis: Hier die Einstellung übernehmen oder speichern und abhängige Controls freigeben. Feuert bei Klick, Leertaste und Checked := … im Code, nicht beim Laden des Formulars. |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` Praxis: Nur auf Touch-Geräten mit eigenen Gesten; zum Umschalten reicht Tippen. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. Praxis: Nur für Reaktionen, die ausschließlich bei Bedienung durch den Anwender passieren sollen, z. B. „Einstellung geändert“ protokollieren. Die eigentliche Logik gehört in OnChange. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. Praxis: Um das Kontextmenü vor dem Öffnen anzupassen, z. B. „Auf Standard zurücksetzen“ sperren, wenn der Schalter schon auf Standard steht. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. Praxis: Bei Schaltern kaum gebraucht; nur wenn etwas auf den Schalter gezogen werden darf. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. Praxis: Zusammen mit OnDragDrop: Accept := True erlaubt das Ablegen; bei Schaltern selten nötig. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. Praxis: Nur bei DragKind = dkDock; bei Schaltern praktisch nie gebraucht. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). Praxis: Nur wenn der Schalter selbst gezogen wird (DragMode); bei Schaltern selten. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. Praxis: Um beim Fokus eine ausführliche Erklärung der Einstellung in einem Hilfebereich oder der Statusleiste zu zeigen. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. Praxis: Gegenstück zu OnEnter: den Hilfetext wieder löschen. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` Praxis: Für Zusatztasten am fokussierten Schalter, z. B. Entf für „auf Standard zurücksetzen“. Die Leertaste schaltet der Schalter selbst um. |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. Praxis: Selten nötig; Zeichentasten schalten nicht um. Für Kürzel die Zugriffstaste (&) in Caption nehmen. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. Praxis: Selten nötig; Gegenstück zu OnKeyDown. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. Praxis: Selten nötig; das Umschalten selbst geschieht beim Loslassen und wird in OnChange gemeldet. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. Praxis: Um beim Überfahren eine Vorschau der Einstellung zu zeigen, z. B. wie die Liste mit Filter aussähe. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. Praxis: Gegenstück zu OnMouseEnter: die Vorschau wieder ausblenden. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. Praxis: Selten nötig; feuert bei jeder Mausbewegung. Die Hover-Optik zeichnet der Schalter selbst. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. Praxis: Selten nötig; für die Reaktion auf das Umschalten OnChange nehmen. |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. Praxis: Nur bei DragKind = dkDock; bei Schaltern praktisch nie gebraucht. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. Praxis: Nur wenn der Schalter selbst gezogen wird; hier ein eigenes DragObject setzen. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. Praxis: Selten nötig; Handled := True verhindert, dass der Parent scrollt, solange die Maus über dem Schalter steht. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. Praxis: Nur in Spezialfällen (Werkzeugfenster, die beim Klick nicht aktiv werden sollen); sonst nicht belegen. |

Tests: `PPG.Tests.Audit5d`; `PPG.Tests.Inventur` (TDBToggleSwitchTests); `PPG.Tests.Streaming` (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBToggleSwitch.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
