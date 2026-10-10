# TPPGTagEdit

Palette **PPGlow** - Unit `PPG.TagEdit` - Basis `TPPGCustomDropDownField`

**Vorbild:** Empfängerfeld von Outlook, WinUI TokenizingTextBox

## Wofür

Das TagEdit nimmt mehrere kurze Werte in einem Feld auf und zeigt jeden als Chip mit Kreuz: Empfänger einer E-Mail, Schlagworte eines Tickets, Fähigkeiten eines Mitarbeiters. Der Anwender tippt, bestätigt mit Enter oder `;` und wählt aus Vorschlägen. Im Code stehen die Werte als Liste (`Tags`) oder als ein Text für ein Datenbankfeld (`TagsText`).

## Wann verwenden

- Für mehrere frei eingegebene Werte, die einzeln entfernt werden sollen (Empfänger, Schlagworte). Für einen einzelnen Wert ist `TPPGEdit` oder `TPPGComboBox` einfacher.
- Statt `TPPGCheckComboBox`, wenn die Auswahl klein ist, die Liste aber lang oder offen: Das TagEdit zeigt nur das Gewählte, die CheckComboBox alle Einträge zum Ankreuzen. Bei wenigen festen Optionen ist die CheckComboBox oder eine `TPPGCheckListBox` übersichtlicher.
- Mit `AllowNew = False` als platzsparende Mehrfachauswahl aus einer festen Liste (Kategorien, Abteilungen), wenn der Anwender lieber tippt als blättert.
- Für Datenbankfelder mit mehreren Werten in einer Spalte die DB-Variante `TPPGDBTagEdit` nehmen (Wert = `TagsText`).

## Unterschiede und Hinweise

- Chips (Text mit ×) stehen vor dem Eingabebereich und brechen über mehrere Zeilen um. Mit `AutoSize` wächst die Höhe mit. Das Layout wird nur bei Änderung der Tags, der Breite oder der Schrift neu berechnet.
- Ein Tag entsteht:
  - mit Enter
  - mit einem Zeichen aus `InputDelimiters` (`;` `,`)
  - beim Verlassen (`AddOnExit`)
  - eingefügtes `a; b; c` ergibt drei Tags
- Rücktaste im leeren Feld markiert zuerst das letzte Tag und löscht es beim zweiten Druck (wie Outlook). Pfeil links/rechts wandert zwischen den Chips, Entf löscht das markierte.
- `Suggestions` erscheinen während des Tippens. Mit `AllowNew = False` sind nur Vorschläge erlaubt. Doppelte sind ausgeschlossen (`AllowDuplicates`, `CaseSensitive`); `MaxTags` begrenzt die Anzahl.
- `OnTagAdding` kann ablehnen oder den Text ändern (z. B. eine E-Mail prüfen). Dazu kommen `OnTagRemoved` und `OnTagClick`. Code (`Tags`, `TagsText`) löst nichts aus.
- Screenreader: Die Chips sind Kinder; die Standardaktion ist Entfernen.

## Beispiel

```pascal
PPGTagEdit1.Suggestions.CommaText := 'Delphi,VCL,Windows';
PPGTagEdit1.TagsText := 'Delphi;VCL';
```

## Verhalten (aus dem Quelltext)

TPPGTagEdit - Stichwoerter als Chips (Phase 12f, Vorbild Outlook-Empfaenger,
WinUI TokenizingTextBox).

- Chips (Text mit x) vor dem Eingabebereich, Umbruch ueber mehrere Zeilen; mit AutoSize waechst die Hoehe mit. Das Layout wird nur bei Aenderung der Tags, der Breite oder der Schrift berechnet (nicht je Tastendruck).
- Ein Tag entsteht mit Enter, mit einem der Delimiters (";" ",") oder beim Verlassen (AddOnExit). Eingefuegtes "a; b; c" ergibt drei Tags.
- Ruecktaste im leeren Feld markiert zuerst das letzte Tag und loescht es beim zweiten Druck (wie Outlook); Pfeil links/rechts wandert zwischen den Chips, Entf loescht das markierte.
- Vorschlaege (Suggestions) im Aufklapp-Fenster waehrend des Tippens; AllowNew = False erlaubt nur Vorschlaege. MaxTags, CaseSensitive, keine Doppelten.
- Ereignisse nur bei Anwenderaktionen: OnTagAdding (abbrechbar, Text aenderbar - z.B. E-Mail pruefen), OnTagRemoved, OnTagClick, OnChange. Tags aus Code (Tags.Add, TagsText) loesen nichts aus.
- Screenreader: Chips als Kinder, Standardaktion Entfernen.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Tags` | `TStrings` |  | Die aktuellen Tags, je Zeile eines. Änderungen aus Code lösen keine Ereignisse aus. Nutzung: `TagEdit1.Tags.Add('Wichtig');` Praxis: Die eingetragenen Werte lesen oder vorbelegen, z. B. die Empfänger einer E-Mail oder die Schlagworte eines Datensatzes. Beim Laden aus der Datenbank Tags bzw. TagsText setzen; das löst bewusst keine Ereignisse aus. |
| `Suggestions` | `TStrings` |  | Vorschläge, die beim Tippen im Aufklappfenster erscheinen. Nutzung: `TagEdit1.Suggestions.CommaText := 'Vertrieb,Einkauf,Technik';` Praxis: Mit den bekannten Werten füllen, z. B. Adressen aus dem Adressbuch oder die erlaubten Kategorien. Der Anwender tippt „ver“ und wählt „Vertrieb“, statt es auszuschreiben; bei langen Listen beim Öffnen des Formulars einmal laden. |
| `InputDelimiters` | `string` |  | Zeichen, die beim Tippen ein Tag abschließen (z. B. „;," ). Enter schließt immer ab; eingefügtes „a; b; c" ergibt drei Tags. Praxis: „;,“ lassen, wenn Anwender Adresslisten aus Outlook oder Excel einfügen. Für Schlagworte mit Komma im Text (z. B. „Müller, Hans“) nur „;“ eintragen, für reine Enter-Bestätigung leer lassen. |
| `Delimiter` | `Char` | `';'` | Trennzeichen der Tags in TagsText bzw. im DB-Feld. Vorgabe „;". Praxis: Trennzeichen für das Datenbankfeld bzw. TagsText; „;“ passt zu den meisten Adress- und Schlagwortlisten. Wählen Sie ein Zeichen, das in den Werten selbst nie vorkommt. |
| `AllowNew` | `Boolean` | `True` | False: Nur Einträge aus Suggestions sind erlaubt (Auswahlliste statt freier Eingabe). Praxis: False für feste Auswahllisten wie Kategorien, Abteilungen oder Status: Dann landen keine Tippfehler in der Datenbank. True für freie Schlagworte und E-Mail-Adressen. |
| `AllowDuplicates` | `Boolean` | `False` | True: Dasselbe Tag darf mehrfach vorkommen. Praxis: Fast immer False lassen: Zwei gleiche Empfänger oder Schlagworte sind ein Versehen. True nur, wenn die Wiederholung etwas bedeutet, z. B. Mengen als Einträge. |
| `CaseSensitive` | `Boolean` | `False` | True: Groß-/Kleinschreibung zählt beim Prüfen auf Doppelte und beim Abgleich mit Suggestions. Praxis: False lassen, damit „Vertrieb“ und „vertrieb“ als dasselbe Tag gelten. True nur bei Werten, bei denen die Schreibweise zählt, z. B. Artikelcodes. |
| `MaxTags` | `Integer` | `0` | Höchstzahl der Tags; 0 = ohne Grenze. Praxis: Begrenzt die Auswahl, wo das Fachliche eine Grenze hat, z. B. höchstens 5 Empfänger oder 3 Schwerpunkte je Mitarbeiter. 0 lassen, wenn es keine Grenze gibt. |
| `AddOnExit` | `Boolean` | `True` | True: Beim Verlassen des Felds wird angefangener Text zum Tag. Praxis: True lassen, damit eine angefangene Eingabe beim Klick auf „Speichern“ nicht verloren geht. False, wenn nur ausdrücklich bestätigte Einträge (Enter) zählen sollen. |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. Praxis: Legen Sie die Optik einmal für die ganze Anwendung fest, am besten über einen TPPGStyleManager. Dann sehen TagEdit, Edit und ComboBox im Formular gleich aus. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. Praxis: Einen TPPGStyleManager aufs Formular legen und allen Feldern zuweisen; dann wechseln Optik und Hell/Dunkel für alle Eingabefelder auf einmal. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` Praxis: Für einzelne Hervorhebungen, z. B. einen kräftigeren Fokusrand in Pflichtfeldern. Für eine einheitliche Optik besser Preset bzw. StyleManager. |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. Praxis: An lassen; Fokus- und Hover-Übergänge wirken ruhiger. RespectSystemSettings beachtet die Windows-Einstellung „Animationen anzeigen“. |
| `TextHint` | `string` |  | Platzhaltertext im leeren Feld (z. B. „Suchen …"). Nutzung: `Edit1.TextHint := 'E-Mail-Adresse';` Praxis: Sagt, was eingegeben wird, z. B. „Name oder E-Mail-Adresse“ oder „Schlagwort tippen …“. Er erscheint nur, solange noch kein Text getippt ist. |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Ergebnis einer Prüfung: pvsNone (neutral), pvsValid (grüner Rand), pvsWarning (gelb), pvsError (rot). Die Farben kommen aus den Signal-Tokens; ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if not IstMail(Edit1.Text) then begin Edit1.ValidationState := pvsError; Edit1.ValidationHint := 'Keine gültige Adresse'; end;` Praxis: pvsError, wenn ein Eintrag abgelehnt wurde oder ein Pflichtfeld leer ist; pvsNone, sobald alles stimmt. Den Grund schreiben Sie in ValidationHint. |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState; erscheint als Tooltip und wird vom Screenreader vorgelesen. Praxis: Erklärt den roten Rand in einem Satz, z. B. „Keine E-Mail-Adresse: max huber“. Er erscheint als Tooltip und wird vom Screenreader vorgelesen. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). Praxis: True lassen: Sehbehinderte Anwender mit Hochkontrast sehen Rand und Chips dann in klaren Systemfarben. |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen (z. B. eingebettet in eigene Flächen). Praxis: bsSingle für normale Formularfelder. bsNone, wenn das Feld in eine eigene Fläche eingebettet ist, z. B. als Empfängerzeile in einem Mail-Kopf ohne eigene Rahmen. |
| `ReadOnly` | `Boolean` | `False` | True: Der Text kann gelesen, markiert und kopiert, aber nicht geändert werden. Die Optik bestimmt ReadOnlyStyle. Praxis: Für Datensätze, die man sehen, aber nicht ändern darf, z. B. abgeschlossene Tickets oder fehlende Schreibrechte. Die Tags bleiben lesbar, Kreuz und Eingabe sind gesperrt. |
| `ReadOnlyStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Eigene Optik bei ReadOnly: Fläche, Text- und Randfarbe (je auch für Dunkel). clDefault = wie im bearbeitbaren Zustand. Nutzung: `Edit1.ReadOnlyStyle.Color := $00F0F0F0; Edit1.ReadOnlyStyle.TextColor := clGrayText;` Praxis: Wenn gesperrte Felder deutlich anders aussehen sollen als bearbeitbare, z. B. mit grauer Fläche. clDefault lassen, wenn die Optik des Presets reicht. |
| `TabStop` | `Boolean` | `True` | True: Das Feld ist mit Tab erreichbar. Praxis: True lassen, damit das Feld per Tab erreichbar ist; Tags werden dann komplett per Tastatur bearbeitet (Enter, Rücktaste, Pfeile). |
| `ShowClearButton` | `Boolean` | `False` | True: Ein „×"-Knopf im Feld löscht den Text (nur sichtbar, wenn Text vorhanden und das Feld bearbeitbar ist). Praxis: True bei Filterfeldern, damit der Anwender alle Tags auf einmal entfernen kann. In Datenformularen eher aus, dort entfernt man einzeln über das Kreuz am Chip. |
| `TextHintVisibleOnFocus` | `Boolean` | `False` | True: Der Platzhalter bleibt sichtbar, bis getippt wird; False: er verschwindet schon beim Fokus. Praxis: True, wenn der Platzhalter eine Anleitung enthält („Adresse eingeben und Enter drücken“), die man beim Hineinklicken noch lesen soll. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. Praxis: alTop für eine Empfänger- oder Schlagwortzeile über einem Textbereich; mit AutoSize wächst die Zeile bei vielen Tags nach unten mit. In Formularen sonst alNone. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` Praxis: In Formularen mit veränderbarer Größe [akLeft, akTop, akRight]: Das Feld wird breiter, und es passen mehr Tags in eine Zeile. |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). Praxis: True lassen: Bei vielen Tags wächst das Feld um weitere Zeilen, statt Tags abzuschneiden. Darunter liegende Controls dann mit Abstand oder per Align anordnen. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. Praxis: Nur für arabische oder hebräische Oberflächen ändern; die Chips laufen dann von rechts nach links. Am Formular setzen und über ParentBiDiMode folgen lassen. |
| `Color` | `TColor` | `clWindow` | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. Praxis: Selten nötig; die Feldfarbe kommt aus Appearance bzw. dem Preset. Color wirkt nur ohne Dark Mode, VCL-Style und Hochkontrast. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` Praxis: MinHeight hält eine einzeilige Mindesthöhe, MaxHeight verhindert, dass das Feld bei sehr vielen Tags mit AutoSize das ganze Formular füllt. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. Praxis: False, wenn die Eingabe gerade nicht zur Situation passt, z. B. Empfänger erst nach Wahl des Kunden. Für „ansehen, aber nicht ändern“ besser ReadOnly. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` Praxis: Am besten über ParentFont vom Formular übernehmen. Eine größere Schrift macht auch die Chips höher; das Feld wächst mit AutoSize mit. |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. Praxis: True lassen, damit das Feld der Leserichtung des Formulars folgt. |
| `ParentColor` | `Boolean` | `False` | True: Color wird vom Parent übernommen. Praxis: False lassen; ein Eingabefeld soll sich vom Hintergrund abheben. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. Praxis: True lassen, damit das Feld die Formularschrift trägt wie die übrigen Felder. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). Praxis: True lassen und ShowHint einmal am Formular einschalten. |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. Praxis: Für Zusatzbefehle per Rechtsklick, z. B. „Alle Empfänger kopieren“ oder „Aus Verteilerliste einfügen“. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. Praxis: Einmal am Formular einschalten statt an jedem Feld; dann bleibt ParentShowHint True. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. Praxis: Nur bei VCL-Styles wichtig: Ohne seClient behält das Feld seine eigenen Farben aus Appearance. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). Praxis: In Formularen in Lesereihenfolge vergeben, z. B. Kunde, Empfänger, Betreff. Achtung: Tab verlässt das Feld und macht mit AddOnExit angefangenen Text zum Tag. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. Praxis: Blenden Sie das Feld aus, wenn es für den Datensatz nicht gilt, z. B. „CC“ erst nach Klick auf „CC hinzufügen“. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. Praxis: Nur für Touch-Geräte: Gesten anhaken und in OnGesture auswerten. Für die normale Eingabe nicht nötig. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. Praxis: dmManual lassen, sonst startet jeder Klick in das Feld ein Ziehen. Zum Ablegen auf das Feld (OnDragDrop) ist dmAutomatic nicht nötig. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). Praxis: Nur bei DragMode = dmAutomatic sichtbar, z. B. crDrag, wenn Schlagworte auf ein anderes Feld gezogen werden. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. Praxis: Nicht nötig; PPGlow-Felder zeichnen immer flackerfrei. Steht nur da, damit alte Formulare ohne Fehler laden. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. Praxis: True lassen; bei PPGlow-Controls ohne sichtbare Wirkung. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` Praxis: Zusammen mit Align einschalten, damit das Feld nicht am Rand klebt; die Abstände stehen unter Margins. |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. Praxis: Position im Designer per Maus; im Code nur bei dynamisch erzeugten Feldern, z. B. TagEdit.SetBounds(16, 40, 410, 32). |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. Praxis: Wie Left: im Designer per Maus, im Code nur bei dynamisch erzeugten Feldern. Mit AutoSize unten genug Platz lassen. |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: So breit, dass die üblichen Tags in eine bis zwei Zeilen passen; für E-Mail-Adressen 350 bis 450 Pixel. Mit Anchors wächst es mit dem Formular. |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Mit AutoSize bestimmt die Zahl der Tag-Zeilen die Höhe. Ohne AutoSize so hoch setzen, dass die erwarteten Tags hineinpassen (eine Zeile etwa 32 Pixel). |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. Praxis: crDefault lassen; über dem Eingabebereich zeigt das Feld ohnehin den Textcursor. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` Praxis: Erklärt die Bedienung, z. B. „Adresse eingeben und mit Enter oder ; bestätigen“. Sichtbar mit ShowHint am Formular. |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. Praxis: htKeyword, wenn Sie Stichwörter pflegen, sonst htContext. Ohne Hilfedatei egal. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. Praxis: Wie HelpContext, aber über ein Stichwort (HelpType = htKeyword). |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). Praxis: Nur mit einer Hilfedatei sinnvoll: die Kontext-ID der Seite eintragen, die F1 im Feld öffnen soll, z. B. „Empfänger eintragen“. |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. Praxis: Abstand zu Nachbarn bei Align, z. B. Margins.Bottom = 8 unter einer Schlagwortzeile mit alTop. Wirkt nur mit AlignWithMargins. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. Praxis: Für Hinweise mit Titel und Symbol, z. B. „Mehrere Adressen mit ; trennen“: einen TBalloonHint oder TPPGCustomHint zuweisen. |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. Praxis: True lassen, damit ein am Formular gesetzter CustomHint auch hier gilt. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) Praxis: Sprechende Namen vergeben (tagEmpfaenger, tagSchlagworte) statt PPGTagEdit1; der Code in den Ereignissen wird dadurch lesbar. |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). Praxis: Freier Wert, z. B. die ID des Datensatzes, zu dem die Schlagworte gehören, wenn mehrere TagEdits einen gemeinsamen Handler nutzen. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnTagAdding` | `TPPGTagAddingEvent` `(Sender: TObject; var Tag: string; var Allow: Boolean)` | Bevor ein Tag durch den Anwender entsteht: Tag kann geändert (z. B. getrimmt) werden, Allow := False lehnt ab. Nutzung: `Allow := Pos('@', Tag) > 0; // nur E-Mail-Adressen` Praxis: Hier prüfen und vereinheitlichen Sie jeden neuen Eintrag: Tag := LowerCase(Tag) für E-Mail-Adressen, Allow := False bei ungültigen Werten. Abgelehnter Text bleibt im Feld stehen, damit der Anwender ihn korrigieren kann. |
| `OnTagRemoved` | `TPPGTagEvent` `(Sender: TObject; const Tag: string)` | Der Anwender hat ein Tag entfernt (Klick auf ×, Entf oder Rücktaste). Praxis: Um auf das Entfernen zu reagieren, z. B. abhängige Felder leeren oder in der Statuszeile „Anna Berger entfernt“ melden. |
| `OnTagClick` | `TPPGTagEvent` `(Sender: TObject; const Tag: string)` | Ein Tag (Chip) wurde angeklickt. Praxis: Um ein Tag als Verweis zu nutzen: nach dem Schlagwort filtern oder zum Empfänger die Kontaktkarte öffnen. |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` Praxis: Auf Touch-Geräten: Wischgesten auswerten (EventInfo.GestureID); für die normale Eingabe nicht nötig. |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Anwender hat Tags hinzugefügt oder entfernt (auch über den Löschknopf). Tippen ohne neues Tag und Änderungen aus Code (Tags, TagsText) lösen es nicht aus. Praxis: Feuert, wenn der Anwender Tags hinzufügt oder entfernt (nicht beim Tippen und nicht bei Änderungen aus Code). Der richtige Ort, um z. B. „Senden“ freizugeben oder einen Zähler zu aktualisieren. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. Praxis: Für Hilfetexte in der Statusleiste („Mehrere Adressen mit ; trennen“), sobald das Feld den Fokus bekommt. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. Praxis: Guter Ort für die Pflichtfeld-Prüfung: Tags.Count = 0 → ValidationState := pvsError. Angefangener Text ist dank AddOnExit zu diesem Zeitpunkt schon ein Tag. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` Praxis: Für zusätzliche Tasten, z. B. Strg+K öffnet das Adressbuch. Enter, Rücktaste, Entf und Pfeile erledigt das Feld schon selbst. |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. Praxis: Um Zeichen zu verwerfen, die in Tags nicht vorkommen dürfen, z. B. Key := #0 bei Leerzeichen in Artikelcodes. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. Praxis: Selten nötig; z. B. für eine eigene Live-Suche nach jedem Tastendruck. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. Praxis: Selten nötig; feuert beim Klick in das Feld. Für Klicks auf einen Chip nehmen Sie OnTagClick. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. Praxis: Selten nötig, z. B. um bei Doppelklick in das leere Feld ein Auswahlfenster (Adressbuch) zu öffnen. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. Praxis: Selten nötig; Klicks auf Chips und Kreuz behandelt das Feld selbst (OnTagClick, OnTagRemoved). |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. Praxis: Selten nötig; feuert bei jeder Mausbewegung. Hervorhebung der Chips und des Kreuzes macht das Feld selbst. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. Praxis: Gegenstück zu OnMouseDown; für Aktionen auf Chips besser OnTagClick nehmen. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. Praxis: Um beim Überfahren eine Erklärung in der Statuszeile zu zeigen; die Hover-Optik macht das Feld selbst. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. Praxis: Gegenstück zu OnMouseEnter: Erklärung wieder ausblenden. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. Praxis: Selten nötig; Handled := True verhindert, dass der Parent scrollt. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. Praxis: Nur in Spezialfällen (Werkzeugfenster) ändern; sonst nicht belegen. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. Praxis: Um das Kontextmenü vor dem Öffnen anzupassen, z. B. „Entfernen“ nur bei markiertem Tag freigeben, oder mit Handled := True zu unterdrücken. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. Praxis: Zum Ablegen auf das Feld, z. B. Kontakte aus einer Liste als Empfänger hinzufügen: hier TagEdit.Tags.Add oder AddTag mit dem gezogenen Wert. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. Praxis: Zusammen mit OnDragDrop: Accept := Source = lstKontakte erlaubt das Ablegen nur aus der passenden Liste. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. Praxis: Nur wenn das Feld selbst gezogen wird: ein eigenes DragObject setzen, z. B. mit allen Tags als Text. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). Praxis: Nur wenn das Feld selbst gezogen wird (DragMode); Target = nil heißt abgebrochen. |

Tests: `PPG.Tests.Audit11C` (TAudit11CGdiTests); `PPG.Tests.Audit45` (TNamingTests, TSetterFixTests, TStreamingFixTests); `PPG.Tests.Audit5d` (TStage3Tests, TVclPropsTests); `PPG.Tests.Audit7B` (TAudit7BTests); `PPG.Tests.Audit8D` (TAudit8DTests); `PPG.Tests.Phase12c` (TFieldsGalleryTests, TTagEditTests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGTagEdit.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
