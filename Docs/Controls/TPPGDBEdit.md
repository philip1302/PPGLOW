# TPPGDBEdit

Palette **PPGlow DB** - Unit `PPG.DB.Controls` - Basis `TPPGEdit`

**Vorbild:** TDBEdit

## Unterschiede und Hinweise

- Ungültige Eingabe (z. B. Text in einem Zahlenfeld) zeigt `ValidationState = pvsError` mit der Meldung als Hinweis, behält den Fokus und bricht still ab – kein Dialog.
- Ohne änderbares Feld (Datenmenge/Feld nur lesbar) bleibt das Edit schreibgeschützt.
- Keine Eingabemaske: `EditMask` des Felds wirkt nur über `Field.IsValidChar`.

## Beispiel

```pascal
PPGDBEdit1.DataSource := DataSource1;
PPGDBEdit1.DataField := 'Name';
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
| `ShowRequired` | `Boolean` | `False` | True: Ist das Datenfeld ein Pflichtfeld (TField.Required), zeigt das leere Feld hinter dem Platzhalter (TextHint) ein Sternchen, ohne TextHint nur das Sternchen. So ist die Pflicht sichtbar, bevor der Validator meldet. |
| `DataField` | `string` |  | Feld, das angezeigt und bearbeitet wird. Mit Fokus erscheint Field.Text, ohne Fokus Field.DisplayText; beim Verlassen wird geschrieben (Fehler erscheinen als ValidationState statt Dialog). Nutzung: `DBEdit1.DataSource := DataSource1; DBEdit1.DataField := 'Name';` |
| `DataSource` | `TDataSource` |  | Datenquelle mit der Datenmenge, aus der DataField kommt. |
| `ReadOnly` | `Boolean` | `False` | True: Der Text kann gelesen, markiert und kopiert, aber nicht geändert werden. Die Optik bestimmt ReadOnlyStyle. Praxis: Für Werte, die man sehen und kopieren, aber nicht ändern soll: Kundennummer, Anlagedatum, berechnete Werte. Anders als Enabled = False bleibt der Text gut lesbar und markierbar. |
| `Text` | `string` |  | Der Inhalt des Felds. Setzen aus Code löst OnChange aus (wie bei TEdit). Nutzung: `Edit1.Text := '';` Praxis: Der Wert des Felds: beim Öffnen aus dem Datensatz setzen, beim Speichern auslesen (meist mit Trim). Setzen löst OnChange aus, also Prüfungen dort nicht doppelt anstoßen. |
| `RoundedCorners` | `TPPGCorners` | `[pcTopLeft, pcTopRight, pcBottomRight, pcBottomLeft]` | Welche Ecken gerundet sind; die übrigen werden eckig. Für Button-Gruppen und Segment-Schalter: linker Button [pcTopLeft, pcBottomLeft], mittlere [], rechter [pcTopRight, pcBottomRight]. Menge aus: `pcTopLeft`, `pcTopRight`, `pcBottomRight`, `pcBottomLeft`. Nutzung: `PPGButton2.RoundedCorners := [];` Praxis: Für Feld-plus-Button-Gruppen: Feld rechts eckig ([pcTopLeft, pcBottomLeft]), der Button daneben links eckig. Einzelne Felder behalten alle vier Ecken. |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Das Standard-Preset wird nicht in der DFM gespeichert. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. Praxis: Einmal für die ganze Anwendung festlegen, am besten über einen TPPGStyleManager. Ein Feld mit eigenem Preset wirkt im Formular wie ein Fremdkörper. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. Praxis: Einen TPPGStyleManager aufs Formular oder Datenmodul legen und allen Feldern zuweisen. Dann wechselt ein Befehl Optik und Hell/Dunkel für alle. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. In der DFM stehen nur die Werte, die vom Preset abweichen; der Rest kommt beim Laden aus dem Preset. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` Praxis: Nur für Ausnahmen, z. B. ein hervorgehobenes Suchfeld mit Akzentrand (Normal.BorderColor). Für Pflicht- oder Fehlerfelder nehmen Sie ValidationState statt eigener Farben. |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. Praxis: An lassen; der Fokus- und Hover-Übergang wirkt ruhiger. RespectSystemSettings beachtet die Windows-Einstellung „Animationen anzeigen“. |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). Praxis: Bildliste für die Knöpfe im Feld (LeftButton, RightButton). Eine Liste für das ganze Formular anlegen; bei hoher DPI eine TVirtualImageList. |
| `LeftButton` | [TPPGEditButton](types/TPPGEditButton.md) |  | Bild-Schaltfläche links im Feld (wie TButtonedEdit): Visible, ImageIndex (aus Images), Enabled, DropDownMenu. Klick löst OnLeftButtonClick aus und öffnet ggf. das Menü. Nutzung: `Edit1.Images := ImageList1; Edit1.LeftButton.ImageIndex := 0; Edit1.LeftButton.Visible := True;` Praxis: Für ein Symbol vor dem Text, das den Zweck zeigt oder eine Auswahl öffnet, z. B. Person-Symbol mit Menü „Suchen in: Name / Ort“. |
| `RightButton` | [TPPGEditButton](types/TPPGEditButton.md) |  | Bild-Schaltfläche rechts im Feld: Visible, ImageIndex (aus Images), Enabled, DropDownMenu. Klick löst OnRightButtonClick aus und öffnet ggf. das Menü. Nutzung: `Edit1.RightButton.ImageIndex := 1; Edit1.RightButton.Visible := True; Edit1.RightButton.DropDownMenu := PopupMenu1;` Praxis: Für eine Aktion zum Wert, z. B. „E-Mail schreiben“ hinter der Adresse oder „…“ für einen Auswahldialog. Sperren Sie ihn über RightButton.Enabled, solange der Wert ungültig ist. |
| `ShowClearButton` | `Boolean` | `False` | True: Ein „×"-Knopf im Feld löscht den Text (nur sichtbar, wenn Text vorhanden und das Feld bearbeitbar ist). Praxis: Für Such- und Filterfelder einschalten: Ein Klick auf „×“ leert das Feld und löst OnChange aus, die Liste zeigt wieder alles. In normalen Formularfeldern eher aus. |
| `TextHint` | `string` |  | Platzhaltertext im leeren Feld (z. B. „Suchen …"). Nutzung: `Edit1.TextHint := 'E-Mail-Adresse';` Praxis: Zeigt im leeren Feld, was hinein gehört („Kunde suchen …“, „name@firma.de“). Ersetzt keine Beschriftung, denn er verschwindet beim Tippen. |
| `UseSystemContextMenu` | `Boolean` | `False` | True: Rechtsklick zeigt das native Windows-Menü des Edits statt des PPGlow-Menüs (Rückgängig, Ausschneiden, Kopieren, Einfügen, Löschen, Alles markieren; übersetzt und im Preset-Stil). Praxis: True, wenn das Feld genau das Windows-Menü zeigen soll (z. B. für Eingabehilfen oder Unicode-Steuerzeichen). Sonst False lassen, dann passt das Menü zur PPGlow-Optik. |
| `TextHintVisibleOnFocus` | `Boolean` | `False` | True: Der Platzhalter bleibt sichtbar, bis getippt wird; False: er verschwindet schon beim Fokus. Praxis: True für Felder, die oft per Tab erreicht werden: Der Hinweis auf das Format bleibt sichtbar, bis der Anwender tippt. |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Ergebnis einer Prüfung: pvsNone (neutral), pvsValid (grüner Rand), pvsWarning (gelb), pvsError (rot). Die Farben kommen aus den Signal-Tokens; ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if not IstMail(Edit1.Text) then begin Edit1.ValidationState := pvsError; Edit1.ValidationHint := 'Keine gültige Adresse'; end;` Praxis: In OnChange oder OnExit nach der Prüfung setzen: pvsError bei ungültiger E-Mail, pvsWarning bei unvollständiger PLZ, pvsValid wenn alles stimmt, pvsNone im leeren Feld. |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState; erscheint als Tooltip und wird vom Screenreader vorgelesen. Praxis: Immer zusammen mit ValidationState setzen und konkret formulieren, was fehlt („PLZ hat 5 Ziffern“). Der Text erscheint als Tooltip und wird vom Screenreader vorgelesen. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). Praxis: True lassen: Anwender mit Hochkontrast sehen klare Systemfarben. Abschalten nur für reine Vorschau-Felder. |
| `Alignment` | `TAlignment` | `taLeftJustify` | Ausrichtung des Textes im Feld (links, rechts, zentriert). Praxis: taRightJustify für Beträge und Mengen, damit Zahlen untereinander fluchten. Namen, Adressen und Suchbegriffe bleiben linksbündig. |
| `AutoSelect` | `Boolean` | `True` | True: Beim Fokus per Tab wird der ganze Text markiert. Praxis: True lassen: Wer per Tab ins Feld springt, überschreibt den alten Wert direkt. Abschalten bei langen Texten, die man eher ergänzt als ersetzt (z. B. Bemerkung). |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen (z. B. eingebettet in eigene Flächen). Praxis: bsNone für Felder, die in eine eigene Fläche eingebettet sind, z. B. eine Suchzeile in einer Kopfleiste. In Formularen bsSingle lassen, damit der Anwender das Feld als Eingabe erkennt. |
| `CharCase` | `TEditCharCase` | `ecNormal` | Erzwingt Groß- oder Kleinschreibung der Eingabe (ecNormal, ecUpperCase, ecLowerCase). Praxis: ecUpperCase für Kürzel, Kennzeichen oder Artikelnummern, die immer in Großbuchstaben gespeichert werden; dann muss der Anwender nicht auf die Schreibweise achten. |
| `HideSelection` | `Boolean` | `True` | True: Die Markierung wird ausgeblendet, wenn das Feld den Fokus verliert. Praxis: False für Felder, deren Markierung auch ohne Fokus sichtbar bleiben soll, z. B. ein Suchen/Ersetzen-Dialog, der den Treffer im Feld zeigt. |
| `MaxLength` | `Integer` | `0` | Höchstzahl der Zeichen; 0 = unbegrenzt. Praxis: Immer auf die Länge der Datenbankspalte setzen (z. B. 40 für den Namen, 5 für die PLZ). Dann schneidet beim Speichern nichts ab und der Anwender merkt die Grenze beim Tippen. |
| `NumbersOnly` | `Boolean` | `False` | True: Nur Ziffern können eingegeben werden (wie TEdit.NumbersOnly). Für Zahlen mit Komma und Grenzen besser TPPGNumberEdit. Praxis: Für reine Ziffernfolgen ohne Rechenwert: PLZ, Kunden- oder Telefonnummernteile. Für Beträge mit Komma und Grenzen nehmen Sie TPPGNumberEdit. |
| `PasswordChar` | `Char` | `#0` | Zeichen, das statt der Eingabe angezeigt wird (z. B. „●"); #0 = Klartext. Für Kennwörter mit Aufdecken-Knopf besser TPPGPasswordEdit. Praxis: Für ein einfaches PIN- oder Kennwortfeld z. B. „●“ setzen. Soll der Anwender das Kennwort aufdecken können, nehmen Sie TPPGPasswordEdit. |
| `ReadOnlyStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Eigene Optik bei ReadOnly: Fläche, Text- und Randfarbe (je auch für Dunkel). clDefault = wie im bearbeitbaren Zustand. Nutzung: `Edit1.ReadOnlyStyle.Color := $00F0F0F0; Edit1.ReadOnlyStyle.TextColor := clGrayText;` Praxis: Damit schreibgeschützte Felder auf einen Blick anders aussehen, z. B. Color hellgrau und TextColor clGrayText. Für alle Felder einheitlich, sonst wirkt das Formular unruhig. |
| `TabStop` | `Boolean` | `True` | True: Das Feld ist mit Tab erreichbar. Praxis: True lassen; Eingabefelder müssen per Tab erreichbar sein. False höchstens für ReadOnly-Anzeigefelder, die man beim Erfassen überspringen soll. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. Praxis: Für Suchfelder über einer Liste: Align = alTop, dann läuft das Feld immer über die volle Breite. In Formularen mit Beschriftung links bleibt es alNone. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` Praxis: In Dialogen mit veränderbarer Größe [akLeft, akTop, akRight] setzen: Das Feld wird beim Vergrößern breiter, die Beschriftung links bleibt stehen. |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). Praxis: True lassen, dann passt die Höhe immer zur Schrift, auch bei hoher DPI. Abschalten nur, wenn alle Felder eines Formulars exakt eine feste Höhe haben sollen. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. Praxis: Nur für arabische oder hebräische Oberflächen ändern; am Formular setzen und über ParentBiDiMode vererben. Text und Knöpfe im Feld werden dann gespiegelt. |
| `Color` | `TColor` | `clWindow` | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. Praxis: Selten nötig: Die Feldfarbe kommt aus Appearance und dem Preset. Für gesperrte Felder lieber ReadOnlyStyle nehmen, damit es auch im Dark Mode stimmt. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` Praxis: MinWidth z. B. 120 für Felder mit Anchors, damit das Feld beim Verkleinern des Fensters nicht unbrauchbar schmal wird. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). Praxis: Nur mit DragMode = dmAutomatic sichtbar; bei Eingabefeldern fast nie gebraucht. |
| `DragKind` | `TDragKind` |  | dkDrag = Drag & Drop, dkDock = Andocken beim Ziehen. Praxis: dkDrag lassen; dkDock ist für Werkzeugleisten gedacht, nicht für Eingabefelder. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. Praxis: dmManual lassen, sonst kann man im Feld keinen Text mehr mit der Maus markieren. Zum Ablegen in das Feld reichen OnDragOver und OnDragDrop. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. Praxis: Sperren Sie Felder, die gerade keine Bedeutung haben, z. B. „Firmenname“, solange „Privatkunde“ gewählt ist. Für Werte, die man lesen und kopieren soll, besser ReadOnly. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` Praxis: Am Formular einstellen und über ParentFont erben. Für ein großes Suchfeld oben auf einer Seite Font.Size = 12 setzen. |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. Praxis: True lassen, damit das Feld der Leserichtung des Formulars folgt. |
| `ParentColor` | `Boolean` | `False` | True: Color wird vom Parent übernommen. Praxis: False lassen: Eingabefelder sollen sich vom Hintergrund abheben. True nur bei BorderStyle = bsNone in einer eigenen Fläche. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. Praxis: True lassen, damit alle Felder die Formularschrift tragen. Ändern Sie Font, wird es automatisch False. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). Praxis: True lassen und ShowHint einmal am Formular einschalten; dann zeigen alle Felder ihre Hints und ValidationHints. |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. Praxis: Für fachliche Zusatzbefehle per Rechtsklick, z. B. „Aus Adressbuch übernehmen“. Ohne eigenes Menü zeigt das Feld das übliche Bearbeiten-Menü. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. Praxis: Einmal am Formular einschalten statt an jedem Feld; dann bleibt ParentShowHint True. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. Praxis: Nur bei VCL-Styles wichtig: seClient herausnehmen, wenn das Feld seine Farben aus Appearance behalten soll. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). Praxis: In Formularen von oben nach unten vergeben, in der Reihenfolge, in der der Anwender die Daten vor sich hat (Name, Straße, PLZ, Ort). |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. Praxis: Blenden Sie Felder aus, die für den Fall nicht gelten (z. B. „USt-IdNr.“ nur bei Firmenkunden). Beschriftung dazu mit ausblenden. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. Praxis: Nur für Touch-Geräte: Gesten anhaken und in OnGesture auswerten. Für normale Eingabe nicht nötig. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. Praxis: Nicht nötig, PPGlow-Felder zeichnen flackerfrei. Steht nur da, damit alte Formulare ohne Fehler laden. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. Praxis: True lassen; bei PPGlow-Feldern ohne sichtbare Wirkung. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` Praxis: Zusammen mit Align einschalten, damit ein angedocktes Suchfeld nicht am Rand klebt; die Abstände stehen in Margins (typisch 8). |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. Praxis: Im Designer per Maus; im Code nur bei dynamisch erzeugten Feldern, z. B. Edit.SetBounds(110, 16, 320, 32) rechts neben einer Beschriftung. |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. Praxis: Wie Left: im Designer per Maus, im Code bei dynamisch erzeugten Formularen in festen Zeilenabständen (z. B. 40 Pixel). |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Nach der erwarteten Länge wählen: PLZ etwa 80, Name und E-Mail 250 bis 320 Pixel. Gleich breite Felder untereinander wirken ruhiger. |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Bei AutoSize = True ergibt sie sich aus der Schrift (etwa 32 Pixel bei Segoe UI 10). Von Hand nur ändern, wenn AutoSize aus ist. |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. Praxis: crDefault lassen: Über dem Text zeigt Windows ohnehin den Textcursor. Andere Werte verwirren eher. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` Praxis: Erklärt das erwartete Format, z. B. „Kundennummer, 6 Ziffern“. Für Prüfergebnisse nehmen Sie ValidationHint; der Hint bleibt die allgemeine Erklärung. |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. Praxis: htKeyword, wenn Sie Stichwörter pflegen, sonst htContext. Ohne Hilfedatei egal. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. Praxis: Wie HelpContext, aber über ein Stichwort (HelpType = htKeyword), praktisch bei HTML-Hilfen. |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). Praxis: Nur mit Hilfedatei: die Kontext-ID der Seite, die F1 im Feld öffnen soll, z. B. die Erklärung zum Feld „Steuernummer“. |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. Praxis: Abstand bei Align, z. B. Margins.SetBounds(8, 8, 8, 4) für ein Suchfeld über einer Liste. Wirkt nur mit AlignWithMargins. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. Praxis: Für längere Erklärungen mit Titel, z. B. zum Format einer IBAN: einen TPPGCustomHint oder TBalloonHint aufs Formular legen und hier zuweisen. |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. Praxis: True lassen, damit ein am Formular gesetzter CustomHint auch hier gilt. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) Praxis: Sprechende Namen vergeben (edtName, edtEmail, edtSuche) statt PPGEdit1, damit der Code beim Lesen und Speichern verständlich bleibt. |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). Praxis: Für gleichartige Felder mit einem gemeinsamen OnChange: Tag = Spaltennummer oder Feld-ID, dann weiß der Handler, welcher Wert sich geändert hat. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` Praxis: Auf Touch-Geräten, z. B. Wischen nach links leert ein Suchfeld. Für normale Eingabe nicht nötig. |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Text wurde geändert (Tippen, Einfügen, Code). Praxis: Für alles, was sofort auf die Eingabe reagiert: Liste filtern, Eingabe prüfen (ValidationState), Speichern-Button freigeben. Feuert auch beim Setzen von Text im Code. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. Praxis: Selten gebraucht; der Klick setzt nur die Schreibmarke. Für Aktionen zum Wert nehmen Sie LeftButton oder RightButton. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. Praxis: Um das Kontextmenü vor dem Öffnen anzupassen (z. B. „Einfügen“ sperren) oder mit Handled := True zu unterdrücken. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. Praxis: Für eine Abkürzung: Doppelklick in ein Kundennummer-Feld öffnet den Kunden. Normalerweise markiert der Doppelklick nur ein Wort. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. Praxis: Zum Ablegen in das Feld, z. B. einen Kunden aus einer Liste auf das Feld „Ansprechpartner“ ziehen und den Namen übernehmen. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. Praxis: Zusammen mit OnDragDrop: Accept := Source is TPPGListBox erlaubt das Ablegen nur aus passenden Listen. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. Praxis: Bei Eingabefeldern praktisch nie gebraucht (nur mit DragKind = dkDock). |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). Praxis: Nur wenn das Feld selbst gezogen wird (DragMode = dmAutomatic); bei Eingabefeldern selten. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. Praxis: Um beim Betreten einen Hilfetext in der Statusleiste zu zeigen („Format: name@firma.de“) oder eine passende Vorauswahl zu laden. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. Praxis: Guter Ort für Prüfungen, die erst nach der vollständigen Eingabe Sinn ergeben, z. B. die PLZ-Länge oder eine Dublettenprüfung der Kundennummer. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` Praxis: Für Tasten mit Bedeutung im Feld: Enter übernimmt den ersten Suchtreffer, Pfeil runter springt in die Ergebnisliste. Key := 0 verhindert die Standardwirkung. |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. Praxis: Um einzelne Zeichen umzuwandeln oder zu verwerfen, z. B. Komma durch Punkt ersetzen (Key := '.'). Für reine Ziffern reicht NumbersOnly. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. Praxis: Selten; z. B. eine Suche erst starten, wenn eine Taste losgelassen wurde. Meist ist OnChange der bessere Ort. |
| `OnLeftButtonClick` | `TNotifyEvent` `(Sender: TObject)` | Die linke Schaltfläche (LeftButton) wurde geklickt. Praxis: Aktion des linken Knopfs, z. B. eine Auswahl öffnen. Hat der Knopf ein DropDownMenu, öffnet sich das Menü nach dem Ereignis von selbst. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. Praxis: Selten bei Eingabefeldern; die Maus setzt die Schreibmarke. Für Aktionen besser die Knöpfe im Feld. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. Praxis: Um beim Überfahren eine Erklärung zum Feld in der Statusleiste zu zeigen. Die Hover-Optik macht das Feld selbst. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. Praxis: Gegenstück zu OnMouseEnter: die Erklärung wieder ausblenden. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. Praxis: Selten; feuert bei jeder Bewegung. Für Hinweise reicht Hint. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. Praxis: Selten bei Eingabefeldern; z. B. nach dem Markieren mit der Maus die Markierung auswerten (SelText). |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. Praxis: Z. B. in einem Feld für eine laufende Nummer mit dem Rad hoch- und runterzählen. Für echte Zahlenfelder nehmen Sie TPPGSpinEdit. |
| `OnRightButtonClick` | `TNotifyEvent` `(Sender: TObject)` | Die rechte Schaltfläche (RightButton) wurde geklickt, z. B. um einen Suchdialog zu öffnen. Praxis: Aktion des rechten Knopfs, z. B. E-Mail-Programm öffnen, Suchdialog zeigen oder den Wert nachschlagen. Hat der Knopf ein DropDownMenu, öffnet es sich danach von selbst. |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. Praxis: Bei Eingabefeldern praktisch nie gebraucht (nur mit DragKind = dkDock). |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. Praxis: Nur wenn das Feld selbst gezogen wird (DragMode = dmAutomatic); hier ein eigenes DragObject setzen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. Praxis: Nur in Spezialfällen (Werkzeugfenster, die beim Klick nicht aktiv werden sollen); sonst nicht belegen. |

Tests: `PPG.Tests.Audit45` (TDBBindingHoldTests, TDBFix2Tests, TDBFixTests); `PPG.Tests.Audit5d`; `PPG.Tests.Phase19` (TValidatorComfortTests); `PPG.Tests.Phase9c` (TDBEditTests, TDBGridTests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBEdit.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
