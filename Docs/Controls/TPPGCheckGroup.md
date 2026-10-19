# TPPGCheckGroup

Palette **PPGlow** - Unit `PPG.RadioGroup` - Basis `TPPGCustomChoiceGroup`

**Vorbild:** TcxCheckGroup (DevExpress); in der VCL gibt es keine Entsprechung

## Wofür

Die CheckGroup ist eine Gruppe von Kästchen mit Rahmen und Überschrift, von denen der Anwender beliebig viele ankreuzt: Liefertage, Benachrichtigungswege, Rechte je Modul. Sie ersetzt eine Handvoll einzelner `TCheckBox` in einer `TGroupBox` durch ein Control, dessen `Value` die Auswahl als Kommaliste liefert und auch wieder lädt. Neben der klassischen Liste kann sie Segmente (Filterleiste) und Kacheln mit Symbol und Beschreibung zeigen.

## Wann verwenden

- Für eine feste, kurze Liste (etwa 2 bis 10 Einträge), aus der mehrere gewählt werden dürfen. Darf nur genau einer gewählt werden, ist `TPPGRadioGroup` richtig.
- Statt mehrerer `TPPGCheckBox`, wenn die Optionen zusammengehören und gemeinsam gespeichert werden (`Value`). Eine einzelne Ja/Nein-Einstellung bleibt eine `TPPGCheckBox` oder ein `TPPGToggleSwitch`.
- Statt `TPPGCheckListBox`, wenn alle Einträge ohne Scrollen sichtbar sein sollen. Lange oder zur Laufzeit wachsende Listen (Filialen, Artikelgruppen) gehören in die CheckListBox, im knappen Platz in die `TPPGCheckComboBox`.
- Mit `ChoiceStyle = csSegmented` und `ShowFrame = False` als Mehrfach-Filter über Listen (Status „Offen / In Arbeit / Erledigt“); mit `csCards` für wenige wichtige Optionen, die eine Erklärung brauchen.
- Mit `AllowGrayed`, wenn ein dritter Zustand fachlich gebraucht wird, z. B. „nur lesen“ zwischen „bearbeiten“ und „kein Zugriff“.

## Unterschiede und Hinweise

- Dieselbe Basis wie `TPPGRadioGroup` (`ChoiceStyle`, `Columns = 0`, `ItemsEx`), aber mit Mehrfachauswahl.
- `Checked[i]` liest und setzt ein Kästchen, `ItemsEx[i].State` auch den grauen Zustand (`AllowGrayed`).
- `Value` ist die Kommaliste der angehakten Werte (`ItemsEx[i].Value`, leer = Beschriftung) und lässt sich auch setzen, z. B. aus einem Datenbankfeld.
- Bei `csSegmented` hebt der Akzent die angehakten Einträge hervor, bei `csCards` zusätzlich ein Kästchen in der Ecke der Kachel.

## Beispiel

```pascal
PPGCheckGroup1.Items.CommaText := 'Mo,Di,Mi,Do,Fr';
PPGCheckGroup1.Value := 'Mo,Mi';
ShowMessage(PPGCheckGroup1.Value);
```

## Verhalten (aus dem Quelltext)

TPPGRadioGroup und TPPGCheckGroup - Auswahlgruppen (Phase 18a).

Mehrwert gegenueber TRadioGroup/TcxRadioGroup:
- ChoiceStyle: csList (Kreise bzw. Kaestchen wie die VCL), csSegmented (Umschalter in einer Zeile mit gleitendem Akzent) und csCards (Kacheln mit Symbol, Titel und Beschreibung).
- ItemsEx: je Eintrag Beschreibung, Symbol (Zeichen der Symbolschrift oder ImageIndex), Enabled, Hint und Value. Items bleibt als einfache Sicht (TStrings) und laedt alte DFMs von TRadioGroup unveraendert.
- Columns = 0 passt die Spalten der Breite an.
- ValidationState und ValidationHint wie bei den Feldern (Pflichtauswahl rot markieren, Text als Tooltip und Screenreader-Beschreibung; der Validator und TPPGDBRadioGroup setzen beides).

Aufbau:
- Basis TPPGCustomGroupBox (Rahmen und Plakette); ein Fenster, Eintraege selbst gezeichnet (keine Fensterflut). ShowFrame = False ohne Rahmen.
- Gespeichert wird ItemsEx nur, wenn ein Eintrag mehr als die Beschriftung hat, sonst Items.Strings (wie TRadioGroup).
- csList ordnet wie TRadioGroup spaltenweise (erst nach unten), die Zeilen teilen sich die Hoehe. Kacheln, Segmente und Columns = 0 ordnen zeilenweise.
- Ereignisse: Anwender waehlt -> OnClick, dann OnChange. Code setzt ItemIndex bzw. Checked[] ohne Ereignis (PPGlow-Regel, wie CheckBox).
- Tastatur: Pfeile wechseln (RadioGroup: Auswahl folgt), Leertaste kreuzt an (CheckGroup), Pos1/Ende, Accelerator & in den Eintraegen.
- Screenreader: jeder Eintrag ist ein Kind (Optionsfeld bzw. Kontrollkaestchen).

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Das Standard-Preset wird nicht in der DFM gespeichert. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. Praxis: Einmal für die ganze Anwendung über einen TPPGStyleManager festlegen. Fluent11 zeigt die Kästchen wie Windows 11, ModernFlat passt zu flachen Business-Oberflächen, Classic zu älteren Office-artigen Programmen. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Im Objektinspektor sind diese drei Properties dann ausgeblendet (bei Mehrfachauswahl nur, wenn alle markierten Controls einen Manager haben) und werden nicht in die DFM geschrieben; nach dem Leeren erscheinen sie sofort wieder. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. Praxis: Denselben TPPGStyleManager wie bei Feldern und Buttons des Formulars zuweisen, dann wechseln Kästchen, Segmente und Kacheln mit Hell/Dunkel und Preset mit. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. In der DFM stehen nur die Werte, die vom Preset abweichen; der Rest kommt beim Laden aus dem Preset. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` Praxis: Färbt Rahmen und Kästchen; der Zustand Checked bestimmt die Farbe der angehakten Kästchen. Für eine einheitliche Markenfarbe besser Preset bzw. StyleManager anpassen. |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. Praxis: An lassen: Hover und Haken wirken dann weich. RespectSystemSettings = True schaltet die Übergänge ab, wenn der Anwender in Windows Animationen abgeschaltet hat. |
| `HighlightFocus` | `Boolean` | `True` | True: Liegt der Fokus auf einem Kind-Control, leuchtet die Plakette in der Fokusfarbe und zeigt so, in welcher Gruppe gerade gearbeitet wird. Praxis: True lassen: Arbeitet der Anwender mit der Tastatur in der Gruppe, leuchtet die Plakette und zeigt, wo er gerade ist. |
| `CaptionStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Aussehen der Beschriftungs-Plakette auf der Rahmenlinie: Fläche, Rand, Textfarbe und Schrift; clDefault = vom Preset. Nutzung: `PPGGroupBox1.CaptionStyle.Color := clNavy; PPGGroupBox1.CaptionStyle.TextColor := clWhite;` Praxis: Nur für hervorgehobene Gruppen ändern, z. B. eine farbige Plakette „Pflichtangaben“. Sonst die Preset-Optik behalten, damit alle Gruppen eines Formulars gleich aussehen. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). Praxis: True lassen: Im Hochkontrastmodus zeichnet die Gruppe Kästchen und Text in Systemfarben, damit sehbehinderte Anwender den Zustand sicher erkennen. |
| `Items` | `TStrings` |  | Einfache Sicht auf die Einträge als Stringliste, wie TRadioGroup.Items; jede Zeile ist ein Eintrag in ItemsEx. Nutzung: `Grp.Items.Add('Firma');` Praxis: Für einfache Listen ohne Zusatzangaben: eine Zeile je Kästchen, z. B. Items.CommaText := 'Mo,Di,Mi,Do,Fr' für Liefertage. Alte TCheckListBox-Listen lassen sich so direkt übernehmen. |
| `ItemsEx` | [TPPGChoiceItems](types/TPPGChoiceItems.md) |  | Einträge mit Beschreibung, Symbol, Bild, Wert, Hinweis und Enabled. Im Designer per Doppelklick. Nutzung: `with Grp.ItemsEx.Add do begin Caption := 'Express'; Description := 'Lieferung morgen'; Icon := $E7C1; end;` Praxis: Wenn Einträge mehr brauchen als den Text: Value als Datenbank-Kürzel, Description und Icon für Kacheln, Enabled und Hint für gesperrte Einträge. Im Designer per Doppelklick bearbeiten. |
| `AllowGrayed` | `Boolean` | `False` | Nur CheckGroup: Kästchen kennen auch den dritten Zustand (cbGrayed); ein Klick wechselt dann aus – grau – an. Praxis: Für einen echten dritten Zustand, z. B. Rechte „bearbeiten / nur lesen / kein Zugriff“ oder „teilweise“ bei Sammelauswahl. Für normale Ja/Nein-Auswahl False lassen, sonst wundert sich der Anwender über graue Kästchen. |
| `Columns` | `Integer` | `1` | Spalten wie bei TRadioGroup; 0 = so viele, wie in die Breite passen (die Einträge brechen um wie Kacheln). Praxis: Bei vier bis acht kurzen Einträgen zwei Spalten, z. B. Wochentage oder Benachrichtigungswege. 0 = so viele Spalten, wie in die Breite passen, praktisch bei Formularen mit veränderbarer Größe. |
| `ChoiceStyle` | `TPPGChoiceStyle` | `csList` | Darstellung: csList = Kreise bzw. Kästchen wie die VCL, csSegmented = Umschalter in einer Zeile mit gleitendem Akzent, csCards = Kacheln mit Symbol, Titel und Beschreibung. Werte: `csList`, `csSegmented`, `csCards`. Nutzung: `Grp.ChoiceStyle := csSegmented; Grp.ShowFrame := False;` Praxis: csList für normale Formulare, csSegmented für kompakte Filter über Listen (z. B. Status „Offen / In Arbeit / Erledigt“), csCards für wenige wichtige Optionen mit Symbol und Erklärung wie Module oder Rechte. |
| `ShowFrame` | `Boolean` | `True` | True: Rahmen und Beschriftungsplakette wie TPPGGroupBox. False: nur die Einträge, z. B. ein Segment-Umschalter in einer Werkzeugleiste. Praxis: False für Filterleisten und Segmente in Werkzeugleisten, wo ein Rahmen stört; dann gibt ein Label daneben die Überschrift. In Formularen True lassen, die Plakette benennt die Gruppe. |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Fehler- bzw. Warnzustand wie bei den Eingabefeldern, z. B. rot bei fehlender Pflichtauswahl. ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if Grp.ItemIndex < 0 then Grp.ValidationState := pvsError;` Praxis: Für Pflichtauswahl: in OnChange bzw. beim Speichern pvsError setzen, wenn Value leer ist, und pvsNone, sobald ein Haken gesetzt wurde. TPPGValidator erledigt das auch automatisch. |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState wie bei den Eingabefeldern: Solange ein Zustand gesetzt ist, erscheint der Text als Tooltip (vor den Hinweisen der Einträge, auch wenn das Formular sonst keine Hints zeigt) und als Beschreibung für den Screenreader; der Hint der Gruppe bleibt unverändert. TPPGValidator setzt hier den Text seiner Regel, TPPGDBRadioGroup beim Verlassen die Meldung des Felds (z. B. aus OnValidate). Nutzung: `Grp.ValidationHint := 'Bitte eine Zahlungsart wählen'; Grp.ValidationState := pvsError;` Praxis: Den Grund kurz und als Aufforderung formulieren („Bitte mindestens einen Weg ankreuzen.“). Er erscheint als Tooltip und wird vom Screenreader vorgelesen. |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). Praxis: Für Kacheln (csCards) mit farbigen Bildern statt Symbolschrift: eine Bildliste zuweisen und je Eintrag ItemsEx[i].ImageIndex setzen. |
| `ItemStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Aussehen der Einträge: Fläche, Text, Rand und Schrift (Segmente, Kacheln, Text der Liste). Praxis: Um Einträge an das Formular anzupassen, z. B. eine kleinere Schrift (FontStyle bzw. Font) bei vielen Einträgen oder eine eigene Kachelfläche. clDefault lassen, wo das Preset passt. |
| `SelectedStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Aussehen des gewählten Eintrags; leer = Akzentfarbe des Presets. Praxis: Für eine eigene Farbe angehakter Segmente und Kacheln, z. B. Grün für „freigeschaltet“. Leer lassen, dann gilt die Akzentfarbe des Presets. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. Praxis: Für Einstellungsseiten mit Align = alTop untereinander stapeln (mit AlignWithMargins); freie Gruppen in Formularen bleiben alNone. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` Praxis: Bei Columns = 0 oder Segmenten [akLeft, akTop, akRight] setzen: Die Gruppe wächst mit dem Fenster und verteilt die Einträge neu. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. Praxis: Nur für arabische oder hebräische Oberflächen; dann stehen Kästchen rechts und die Spalten laufen von rechts nach links. Am besten über ParentBiDiMode vom Formular. |
| `Caption` | `TCaption` |  | Beschriftung. Ein & vor einem Buchstaben macht ihn zur Zugriffstaste (Alt+Buchstabe). Nutzung: `Button1.Caption := '&Speichern';` Praxis: Benennt, was angekreuzt wird („Benachrichtigen per“, „Liefertage“). Ein & vergibt die Zugriffstaste: Alt+Buchstabe springt in die Gruppe. |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. Praxis: Selten nötig; die Gruppe übernimmt mit ParentBackground den Hintergrund ihrer Karte oder ihres Panels. Für Farben der Einträge ItemStyle und SelectedStyle nehmen. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` Praxis: Bei Align oder Anchors eine Mindestbreite setzen (z. B. MinWidth = 200), damit zwei Spalten nicht zu schmal werden. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). Praxis: Nur bei DragMode = dmAutomatic sichtbar; bei Auswahlgruppen fast nie gebraucht. |
| `DragKind` | `TDragKind` |  | dkDrag = Drag & Drop, dkDock = Andocken beim Ziehen. Praxis: dkDrag lassen; Andocken (dkDock) ist für Auswahlgruppen nicht üblich. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. Praxis: dmManual lassen, sonst startet jeder Klick auf ein Kästchen ein Ziehen statt eines Hakens. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. Praxis: Sperrt die ganze Gruppe, z. B. Benachrichtigungen, solange „Kunde gesperrt“ angehakt ist. Einzelne Einträge sperren Sie mit ItemEnabled[i] bzw. ItemsEx[i].Enabled. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` Praxis: Am Formular einstellen und über ParentFont erben. Kacheln (csCards) werden mit größerer Schrift höher, deshalb bei Kacheln die Höhe prüfen. |
| `ParentBackground` | `Boolean` | `True` | True: Der Hintergrund des Parents scheint durch (transparente Wirkung). Praxis: True lassen: Dann liegt die Gruppe ohne eigenen Kasten auf Karte oder Panel. |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. Praxis: True lassen, damit die Gruppe der Leserichtung des Formulars folgt. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. Praxis: True, wenn die Gruppe die Farbe des Parents haben soll; meist zusammen mit ParentBackground. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. Praxis: True lassen, damit die Einträge die Formularschrift tragen. Ändern Sie Font, wird es automatisch False. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). Praxis: True lassen und ShowHint am Formular einschalten; dann erscheinen auch die Hinweise gesperrter Einträge. |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. Praxis: Für Sammelbefehle per Rechtsklick, z. B. „Alle ankreuzen“ und „Keine“ bei langen Listen wie Filialen oder Produktgruppen. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. Praxis: Einschalten (oder am Formular), wenn Einträge einen Hinweis haben, z. B. warum SMS gesperrt ist. Ohne ShowHint bleiben die Hinweise unsichtbar. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. Praxis: Nur bei VCL-Styles wichtig: Nehmen Sie seClient heraus, wenn Segmente oder Kacheln ihre PPGlow-Farben behalten sollen. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). Praxis: So vergeben, dass Tab in der Lesereihenfolge des Formulars in die Gruppe springt; innerhalb der Gruppe wechseln die Pfeiltasten. |
| `TabStop` | `Boolean` | `True` | True: Das Control ist mit Tab erreichbar. Praxis: True lassen: Die Gruppe ist ein Tab-Stopp, darin wechseln Pfeiltasten und die Leertaste kreuzt an. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. Praxis: Blenden Sie Gruppen aus, die für den Kunden oder die Rolle nie gelten (z. B. Rechte eines nicht lizenzierten Moduls). Was nur gerade nicht geht, mit Enabled sperren. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. Praxis: Nur für Touch-Geräte mit eigenen Gesten; normales Antippen der Einträge funktioniert ohne Einstellung. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. Praxis: Bei PPGlow-Controls nicht nötig, die Gruppe zeichnet immer flackerfrei. Steht nur da, damit alte Formulare ohne Fehler laden. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. Praxis: True lassen; bei PPGlow-Controls ohne sichtbare Wirkung. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` Praxis: Zusammen mit Align einschalten, damit gestapelte Gruppen nicht aneinanderkleben; Abstände unter Margins. |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. Praxis: Position im Designer per Maus; im Code nur bei dynamisch erzeugten Gruppen, z. B. Grp.SetBounds(16, 16, 418, 112). |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. Praxis: Wie Left: im Designer per Maus, im Code nur bei dynamisch erzeugten Gruppen. |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: So breit, dass die längste Beschriftung je Spalte passt; mit Columns = 0 bestimmt die Breite die Spaltenzahl. |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Bei csList reichen etwa 26 Pixel je Zeile plus Plakette; Kacheln brauchen etwa 85 Pixel je Reihe, Segmente ohne Rahmen 32 bis 36 Pixel. |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. Praxis: crDefault lassen; die Gruppe zeigt beim Überfahren der Einträge selbst die Hover-Optik. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` Praxis: Erklärt die Gruppe als Ganzes („Diese Wege nutzt der Mahnlauf“). Für einzelne Einträge ItemsEx[i].Hint nehmen; beides braucht ShowHint. |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. Praxis: htKeyword, wenn Sie Stichwörter pflegen, sonst htContext. Ohne Hilfedatei egal. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. Praxis: Wie HelpContext, aber über ein Stichwort (HelpType = htKeyword). |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). Praxis: Nur mit einer Hilfedatei: die Kontext-ID der Seite, die F1 in der Gruppe öffnen soll, z. B. die Erklärung der Rechte. |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. Praxis: Abstand zu Nachbarn bei Align, z. B. Margins.Bottom = 12 zwischen gestapelten Gruppen. Wirkt nur mit AlignWithMargins. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. Praxis: Für Hinweise mit Titel und Symbol: einen TPPGCustomHint zuweisen. Er zeigt auch die Hinweise der einzelnen Einträge (ItemsEx[i].Hint). |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. Praxis: True lassen, damit ein am Formular gesetzter CustomHint auch für die Gruppe und ihre Einträge gilt. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) Praxis: Sprechende Namen vergeben (grpLiefertage, grpRechte) statt PPGCheckGroup1; Code wie grpLiefertage.Value bleibt so lesbar. |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). Praxis: Für mehrere Gruppen mit einem gemeinsamen OnChange: Tag unterscheidet sie, z. B. 1 = Liefertage, 2 = Zustellwege. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` Praxis: Nur auf Touch-Geräten mit eigenen Gesten; Antippen der Einträge braucht kein OnGesture. |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Die Auswahl hat sich durch den Anwender geändert (Klick, Leertaste, Zugriffstaste); kommt nach OnItemClick und OnClick. Setzen von Value, Checked[] oder ItemState[] im Code löst es nicht aus. Praxis: Hier die Auswahl übernehmen: Value speichern, abhängige Felder freigeben oder die Pflichtauswahl prüfen. Feuert nur bei Bedienung durch den Anwender, nicht beim Setzen von Value oder Checked im Code. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. Praxis: Wie in der VCL: meldet einen Haken durch den Anwender, vor OnChange. Für neue Programme OnChange bzw. OnItemClick nehmen, OnClick nur für übernommenen VCL-Code. |
| `OnItemClick` | `TPPGChoiceItemEvent` `(Sender: TObject; Index: Integer)` | Der Benutzer hat einen Eintrag gewählt bzw. umgeschaltet; Index nennt den Eintrag. Praxis: Wenn es darauf ankommt, welcher Eintrag umgeschaltet wurde: Index nennt ihn, Checked[Index] bzw. ItemState[Index] den neuen Zustand. Z. B. beim Abhaken von „Alle Filialen“ die übrigen mitschalten. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. Praxis: Um das Kontextmenü vor dem Öffnen anzupassen, z. B. „Alle ankreuzen“ sperren, wenn schon alle angehakt sind. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. Praxis: Nur, wenn etwas auf die Gruppe gezogen werden darf; bei Auswahlgruppen selten. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. Praxis: Zusammen mit OnDragDrop: Accept := True nur für passende Quellen. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. Praxis: Nur bei DragKind = dkDock; bei Auswahlgruppen praktisch nie gebraucht. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). Praxis: Nach dem Ziehen der Gruppe (DragMode = dmAutomatic); bei Auswahlgruppen selten. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. Praxis: Für einen Hilfetext in der Statusleiste, sobald der Anwender per Tab in die Gruppe kommt („Wege für Mahnungen und Rechnungen“). |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. Praxis: Guter Ort für die Pflichtprüfung beim Verlassen: ohne Haken ValidationState := pvsError. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. Praxis: Um beim Überfahren eine Erklärung in einer Statuszeile zu zeigen. Für Eintrags-Hinweise reicht ItemsEx[i].Hint. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. Praxis: Gegenstück zu OnMouseEnter: Erklärung wieder ausblenden. |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. Praxis: Nur bei DragKind = dkDock; bei Auswahlgruppen praktisch nie gebraucht. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. Praxis: Nur bei eigenem Drag & Drop der Gruppe; bei Auswahlgruppen selten. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. Praxis: Bei Kästchen selten sinnvoll, weil jeder Klick schon umschaltet; eher für Kacheln, die per Doppelklick eine Detailansicht öffnen. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. Praxis: Selten nötig; die Auswahl gehört in OnItemClick bzw. OnChange, weil sie auch per Tastatur kommt. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. Praxis: Selten nötig; feuert bei jeder Bewegung. Mit ItemAt(X, Y) lässt sich der Eintrag unter der Maus ermitteln, z. B. für eine Vorschau. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. Praxis: Selten nötig; Gegenstück zu OnMouseDown. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. Praxis: Selten nötig; Handled := True verhindert, dass das Mausrad über der Gruppe den Parent scrollt. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. Praxis: Nur in Spezialfällen (Werkzeugfenster, die beim Klick nicht aktiv werden sollen); sonst nicht belegen. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` Praxis: Für zusätzliche Tasten, z. B. Strg+A für „alle ankreuzen“. Pfeile, Leertaste, Pos1/Ende und Zugriffstasten erledigt die Gruppe selbst. |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. Praxis: Selten nötig; Zeichentasten wählen über die Zugriffstasten (&) der Einträge. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. Praxis: Selten nötig; Gegenstück zu OnKeyDown. |

Tests: `PPG.Tests.Audit5d`; `PPG.Tests.Phase18` (TChoiceGroupTests); `PPG.Tests.Phase19` (TChoiceValidationHintTests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGCheckGroup.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
