# TPPGFileEdit

Palette **PPGlow** - Unit `PPG.FileEdit` - Basis `TPPGCustomFileEdit`

**Vorbild:** TMS TAdvFileNameEdit / TAdvDirectoryEdit

## Wofür

Das Dateifeld nimmt einen Pfad auf: eine Datei zum Öffnen, ein Speicherziel oder einen Ordner. Der Anwender tippt den Pfad (mit Autovervollständigung), wählt ihn über den Knopf im Feld oder zieht ihn aus dem Explorer hinein. Es ersetzt die übliche Kombination aus `TEdit`, „…“-Button und `TOpenDialog` in einem Control.

## Wann verwenden

- Für Pfade in Import-, Export- und Einstellungsdialogen: Quelldatei, Speicherziel, Arbeits- oder Sicherungsordner.
- Statt `TPPGEdit` mit eigenem Durchsuchen-Button: Dialog, Filter, Ablegen und Existenzprüfung (`MustExist`) sind schon eingebaut.
- Statt eines einzelnen `TOpenDialog` hinter einem Button, wenn der Pfad sichtbar bleiben und gespeichert werden soll. Für einen einmaligen Befehl „Datei öffnen …“ reicht der Dialog allein.
- Nicht für mehrere Dateien auf einmal: Das Feld hält genau einen Pfad. Für Listen von Anhängen eine Liste mit eigenem Hinzufügen-Button nehmen.

## Unterschiede und Hinweise

- `Kind`: Datei öffnen, Datei speichern oder Ordner.
- Der Knopf im Feld (oder Alt+Pfeil runter, F4) öffnet ab Vista `TFileOpenDialog`/`TFileSaveDialog`. Davor gibt es `TOpenDialog`/`TSaveDialog`, für Ordner `SHBrowseForFolder`. `Filter` im VCL-Format wird in Dateitypen umgesetzt.
- Dateien aus dem Explorer lassen sich ablegen: Es zählt die erste Datei bzw. der erste Ordner, der zu `Kind` passt.
- Die Autovervollständigung von Pfaden kommt von Windows (`SHAutoComplete`).
- `MustExist`: Eine fehlende Datei bzw. ein fehlender Ordner steht beim Verlassen als Fehler am Feld. Ein leeres Feld ist gültig.
- `OnBeforeDialog` kann den Dialog abbrechen, `OnAfterDialog` den gewählten Namen ändern oder ablehnen.

## Beispiel

```pascal
PPGFileEdit1.Kind := fkOpenFile;
PPGFileEdit1.Filter := 'Dokumente|*.pdf;*.docx|Alle Dateien|*.*';
PPGFileEdit1.MustExist := True;
```

## Verhalten (aus dem Quelltext)

TPPGFileEdit - Feld fuer eine Datei oder einen Ordner (Phase 12c).

- Kind: Datei oeffnen, Datei speichern oder Ordner. Der Knopf im Feld oeffnet ab Vista TFileOpenDialog/TFileSaveDialog (Ordner ueber fdoPickFolders), davor TOpenDialog/TSaveDialog bzw. SHBrowseForFolder (Laufzeitpruefung, XE2 auf XP).
- Ablegen aus dem Explorer (DragAcceptFiles/WM_DROPFILES): die erste Datei bzw. der erste Ordner passend zu Kind.
- Autovervollstaendigung von Pfaden ueber SHAutoComplete auf dem inneren Edit (dynamisch geladen; ohne Shell-Funktion einfach ohne).
- MustExist: fehlende Datei bzw. fehlender Ordner beim Verlassen als ValidationState (kein Dialog). Leeres Feld ist gueltig.
- Ereignisse: OnBeforeDialog (abbrechbar, Dialog vorbereiten), OnAfterDialog (Name pruefen/aendern), OnChange wie beim Edit.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. Praxis: Nicht am einzelnen Dateifeld setzen, sondern einmal für die Anwendung über einen TPPGStyleManager; dann sehen Dateifeld, Edit und Buttons im Formular gleich aus. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. Praxis: Denselben TPPGStyleManager wie bei den übrigen Feldern des Formulars zuweisen. Dann wechselt das Dateifeld mit, wenn die Anwendung auf Dunkel oder ein anderes Preset umschaltet. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` Praxis: Selten nötig: Rand und Fläche kommen aus dem Preset. Nur für ein besonders hervorgehobenes Pflichtfeld, z. B. die Quelldatei eines Imports, die Randfarbe anpassen. |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. Praxis: An lassen; der weiche Übergang von Rand und Fokus wirkt ruhiger. RespectSystemSettings sorgt dafür, dass er bei abgeschalteten Windows-Animationen entfällt. |
| `Kind` | `TPPGFileEditKind` | `fkOpenFile` | Was gewählt wird: Datei zum Öffnen, Datei zum Speichern oder Ordner. Bestimmt den Dialog des Knopfes und was beim Ablegen angenommen wird. Werte: `fkOpenFile`, `fkSaveFile`, `fkFolder`. Praxis: fkOpenFile für Importe und Anhänge (Datei muss es geben), fkSaveFile für Export- und Sicherungsziele, fkFolder für Arbeits-, Ablage- oder Sicherungsordner. |
| `Filter` | `string` |  | Dateifilter des Dialogs wie TOpenDialog.Filter: Paare aus Beschreibung und Muster, alle durch senkrechte Striche getrennt in einem String. Praxis: Nur die Dateitypen anbieten, die das Programm lesen kann, z. B. 'CSV-Dateien (*.csv)\|*.csv\|Alle Dateien (*.*)\|*.*'. Den Eintrag „Alle Dateien“ hinten anhängen, damit falsch benannte Dateien trotzdem wählbar bleiben. |
| `FilterIndex` | `Integer` | `1` | Vorgewählter Filter im Dialog (1 = erster Eintrag von Filter). Praxis: Den häufigsten Typ vorwählen, z. B. 2 für Excel, wenn der Filter CSV und Excel anbietet. Nach dem Dialog steht hier der zuletzt gewählte Typ; speichern Sie ihn mit den Einstellungen. |
| `InitialDir` | `string` |  | Startordner des Dialogs, wenn das Feld noch leer ist. Praxis: Auf einen sinnvollen Startordner stellen, z. B. TPath.GetDocumentsPath oder den zuletzt benutzten Ordner aus den Einstellungen. Steht schon ein Pfad im Feld, startet der Dialog dort. |
| `DefaultExt` | `string` |  | Endung, die der Speichern-Dialog anhängt, wenn der Anwender keine angibt (ohne Punkt, z. B. "csv"). Praxis: Bei Kind = fkSaveFile immer setzen (ohne Punkt, z. B. 'zip'): Tippt der Anwender nur „Sicherung“, wird daraus „Sicherung.zip“ und die Datei lässt sich später wieder öffnen. |
| `DialogTitle` | `string` |  | Titel des Dateidialogs; leer = Windows-Standardtitel. Praxis: Sagt, wofür gewählt wird: „Kundendaten importieren“ statt „Öffnen“. Besonders wichtig, wenn ein Formular mehrere Dateifelder hat. |
| `MustExist` | `Boolean` | `False` | True: Eine fehlende Datei bzw. ein fehlender Ordner wird beim Verlassen als ValidationState = pvsError markiert (kein Dialog); ein leeres Feld ist gültig. Praxis: Für Quelldateien und Zielordner einschalten: Ein vertippter Pfad wird beim Verlassen rot markiert, ohne dass eine Meldung den Anwender unterbricht. Für Speicherziele (fkSaveFile) prüft es nur den Ordner. |
| `AcceptDrop` | `Boolean` | `True` | True: Eine Datei bzw. ein Ordner kann aus dem Explorer ins Feld gezogen werden; übernommen wird der erste passende Eintrag (je nach Kind). Praxis: An lassen, wenn Anwender Dateien oft schon im Explorer offen haben (Importe, Anhänge). Bei reinen Speicherzielen ausschalten, dort wird nichts abgelegt. |
| `AutoComplete` | `Boolean` | `True` | True: Pfade werden beim Tippen vervollständigt (Windows-Shell-Autovervollständigung). Praxis: An lassen: Wer Pfade tippt, bekommt Ordner und Dateien wie in der Adresszeile des Explorers vorgeschlagen. Bei Kind = fkFolder schlägt es nur Ordner vor. |
| `ShowClearButton` | `Boolean` | `False` | True: Ein „×"-Knopf im Feld löscht den Text (nur sichtbar, wenn Text vorhanden und das Feld bearbeitbar ist). Praxis: Einschalten, wenn das Feld optional ist, z. B. ein Logo für Briefe: Der Anwender löscht die Auswahl mit einem Klick, statt den Pfad zu markieren und zu entfernen. |
| `TextHint` | `string` |  | Platzhaltertext im leeren Feld (z. B. „Suchen …"). Nutzung: `Edit1.TextHint := 'E-Mail-Adresse';` Praxis: Erklärt das leere Feld, z. B. „Datei angeben oder aus dem Explorer ziehen“. Ersetzt kein Label, sondern ergänzt es um den Hinweis, wie man etwas einträgt. |
| `TextHintVisibleOnFocus` | `Boolean` | `False` | True: Der Platzhalter bleibt sichtbar, bis getippt wird; False: er verschwindet schon beim Fokus. Praxis: Einschalten, wenn der Hinweis ein Muster zeigt, z. B. „z. B. Kunden-2026.zip“: Er bleibt dann beim Anklicken stehen, bis der Anwender tippt. |
| `UseSystemContextMenu` | `Boolean` | `False` | True: Rechtsklick zeigt das native Windows-Menü des Edits statt des PPGlow-Menüs (Rückgängig, Ausschneiden, Kopieren, Einfügen, Löschen, Alles markieren; übersetzt und im Preset-Stil). Praxis: Meist False lassen: Das PPGlow-Menü passt zum Preset und ist übersetzt. True nur, wenn die Anwendung überall das Windows-Menü zeigen soll. |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Ergebnis einer Prüfung: pvsNone (neutral), pvsValid (grüner Rand), pvsWarning (gelb), pvsError (rot). Die Farben kommen aus den Signal-Tokens; ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if not IstMail(Edit1.Text) then begin Edit1.ValidationState := pvsError; Edit1.ValidationHint := 'Keine gültige Adresse'; end;` Praxis: Für eigene Prüfungen über MustExist hinaus, z. B. pvsWarning, wenn die gewählte Datei älter als 30 Tage ist. Zusammen mit ValidationHint setzen, damit der Anwender den Grund sieht. |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState; erscheint als Tooltip und wird vom Screenreader vorgelesen. Praxis: Kurz sagen, was nicht stimmt und was zu tun ist, z. B. „Datei ist schreibgeschützt – bitte eine Kopie wählen“. Bei MustExist füllt das Feld den Hinweis selbst. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). Praxis: True lassen: Anwender mit Windows-Hochkontrast sehen Rand, Text und Knopf dann in den Systemfarben. |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen (z. B. eingebettet in eigene Flächen). Praxis: bsSingle in Formularen; bsNone nur, wenn das Feld in eine eigene Fläche eingebettet wird, z. B. in eine Zeile einer Einstellungsliste mit eigenem Rahmen. |
| `MaxLength` | `Integer` | `0` | Höchstzahl der Zeichen; 0 = unbegrenzt. Praxis: Meist 0 lassen; Windows-Pfade können lang sein. Nur begrenzen, wenn der Pfad in ein Datenbankfeld fester Länge geschrieben wird, z. B. 255. |
| `ReadOnly` | `Boolean` | `False` | True: Der Text kann gelesen, markiert und kopiert, aber nicht geändert werden. Die Optik bestimmt ReadOnlyStyle. Praxis: Für Pfade, die nur angezeigt werden, z. B. der Speicherort der Lizenzdatei. Der Anwender kann ihn markieren und kopieren; Knopf und Ablegen sind gesperrt. |
| `ReadOnlyStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Eigene Optik bei ReadOnly: Fläche, Text- und Randfarbe (je auch für Dunkel). clDefault = wie im bearbeitbaren Zustand. Nutzung: `Edit1.ReadOnlyStyle.Color := $00F0F0F0; Edit1.ReadOnlyStyle.TextColor := clGrayText;` Praxis: Damit ein schreibgeschützter Pfad nicht wie ein Eingabefeld aussieht: Fläche etwas grauer (Color) und Text gedämpft (TextColor), im Dunkeln über DarkColor. |
| `TabStop` | `Boolean` | `True` | True: Das Feld ist mit Tab erreichbar. Praxis: True lassen, damit das Feld in der Tab-Reihenfolge liegt; per Tastatur öffnet F4 oder Alt+Pfeil runter den Dialog. |
| `Text` | `string` |  | Der Inhalt des Felds. Setzen aus Code löst OnChange aus (wie bei TEdit). Nutzung: `Edit1.Text := '';` Praxis: Den gespeicherten Pfad beim Öffnen des Formulars laden (Feld.Text := Einstellungen.Importpfad) und beim Speichern zurückschreiben. Setzen löst OnChange aus; ohne OnChange geht es über FileName. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. Praxis: In Einstellungsseiten mit Label darüber alTop, damit das Feld die ganze Breite nutzt; zusammen mit AlignWithMargins für Abstand. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` Praxis: [akLeft, akTop, akRight] in Dialogen mit veränderbarer Größe: Das Feld wird mit dem Fenster breiter, und lange Pfade bleiben lesbar. |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). Praxis: True lassen: Die Höhe folgt der Schrift, und das Feld passt zu den Edits daneben. Ausschalten nur für eine feste Zeilenhöhe in einem Raster. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. Praxis: Nur für arabische oder hebräische Oberflächen ändern, am besten am Formular. Pfade selbst bleiben von links nach rechts lesbar. |
| `Color` | `TColor` | `clWindow` | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. Praxis: Selten nötig, die Feldfarbe kommt aus dem Preset. Wirkt nur ohne Dark Mode und VCL-Style; für ReadOnly lieber ReadOnlyStyle nehmen. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` Praxis: Mit Anchors oder Align: MinWidth = 240 verhindert, dass das Feld in einem schmalen Fenster so kurz wird, dass kein Pfad mehr lesbar ist. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. Praxis: Sperren, solange die Einstellung nicht gilt, z. B. das Sicherungsziel, wenn „Automatische Sicherung“ aus ist. Gesperrt öffnet auch der Knopf keinen Dialog. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` Praxis: Am Formular einstellen und über ParentFont erben. Für sehr lange Pfade kann eine etwas kleinere Schrift helfen, damit mehr vom Pfad sichtbar ist. |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. Praxis: True lassen, damit das Feld der Leserichtung des Formulars folgt. |
| `ParentColor` | `Boolean` | `False` | True: Color wird vom Parent übernommen. Praxis: False lassen: Ein Eingabefeld hebt sich mit eigener Fläche vom Formular ab. True nur für ein eingebettetes Feld mit BorderStyle = bsNone. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. Praxis: True lassen, damit das Dateifeld dieselbe Schrift wie die übrigen Felder trägt. Ändern Sie Font, wird es automatisch False. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). Praxis: True lassen und ShowHint einmal am Formular einschalten; dann zeigen alle Felder ihre Hinweise. |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. Praxis: Für zusätzliche Befehle zum Pfad, z. B. „Im Explorer zeigen“ oder „Zuletzt verwendet“. Ohne eigenes Menü zeigt das Feld Ausschneiden, Kopieren und Einfügen. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. Praxis: Einmal am Formular einschalten statt am Feld; dann bleibt ParentShowHint True. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. Praxis: Nur bei VCL-Styles wichtig: Ohne seClient behält das Feld die Farben aus dem PPGlow-Preset. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). Praxis: So vergeben, dass Tab in der Lesereihenfolge läuft: erst Ordner, dann Dateiname, dann der Button, der damit arbeitet. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. Praxis: Ausblenden, was der Anwender nie braucht, z. B. den Exportordner ohne Export-Recht. Was nur gerade nicht gilt, besser mit Enabled sperren. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. Praxis: Nur für Touch-Geräte: Gesten anhaken und in OnGesture auswerten. Für die Dateiwahl selbst nicht nötig, der Knopf ist auch per Finger bedienbar. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. Praxis: dmManual lassen: Das Feld soll Dateien aus dem Explorer annehmen, nicht selbst gezogen werden. dmAutomatic würde jedes Markieren mit der Maus stören. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). Praxis: Nur bei DragMode = dmAutomatic sichtbar; beim Dateifeld praktisch nie nötig. Das Ablegen aus dem Explorer steuert AcceptDrop. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. Praxis: Nicht nötig, PPGlow-Felder zeichnen flackerfrei. Steht nur da, damit alte Formulare ohne Fehler laden. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. Praxis: True lassen; beim Dateifeld ohne sichtbare Wirkung. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` Praxis: Mit Align = alTop einschalten, damit untereinander stehende Pfadfelder nicht aneinanderkleben; die Abstände kommen aus Margins. |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. Praxis: Im Designer mit der Maus; im Code nur bei dynamisch gebauten Formularen, z. B. Feld.SetBounds(16, 40, 414, 32). |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. Praxis: Wie Left: im Designer setzen, im Code nur bei dynamisch gebauten Formularen, direkt unter dem zugehörigen Label. |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Breit genug für typische Pfade wählen, mindestens 300 Pixel; besser mit Anchors oder Align mitwachsen lassen. |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Mit AutoSize bestimmt die Schrift die Höhe; 32 Pixel passen zu Windows-11-Buttons in derselben Zeile. |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. Praxis: crDefault lassen: Über dem Text zeigt das Feld ohnehin den Textcursor, über dem Knopf den Pfeil. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` Praxis: Sagt, welche Datei erwartet wird, z. B. „CSV-Export aus dem Warenwirtschaftssystem (Trennzeichen Semikolon)“. Hilft besonders bei Importen. |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. Praxis: htKeyword, wenn Ihre Hilfe mit Stichwörtern arbeitet, sonst htContext. Ohne Hilfedatei egal. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. Praxis: Stichwort der Hilfeseite, die F1 im Feld öffnet, z. B. „Import Kundendaten“, wenn dort das erwartete Dateiformat beschrieben ist. |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). Praxis: Kontext-ID der Hilfeseite zum Feld (mit HelpType = htContext), z. B. die Seite mit dem Aufbau der Importdatei. |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. Praxis: Abstand zu Nachbarn bei Align, z. B. Margins.Bottom = 12 zwischen zwei untereinander stehenden Pfadfeldern. Wirkt nur mit AlignWithMargins. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. Praxis: Für ausführlichere Hinweise mit Titel, z. B. zum erwarteten Dateiformat: einen TBalloonHint oder TPPGCustomHint zuweisen. |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. Praxis: True lassen, damit ein am Formular gesetzter CustomHint auch hier gilt. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) Praxis: Sprechend benennen, z. B. edtImportDatei oder edtSicherungsordner; dann ist im Code klar, welcher Pfad gemeint ist. |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). Praxis: Bei mehreren gleichartigen Feldern mit gemeinsamem Ereignis, z. B. Tag = 1 für Import, 2 für Export, und im Handler TPPGFileEdit(Sender).Tag auswerten. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` Praxis: Auf Touch-Geräten, z. B. Wischen nach links leert das Feld; EventInfo.GestureID nennt die Geste. |
| `OnAfterDialog` | `TPPGFileAfterDialogEvent` `(Sender: TObject; var FileName: string; var Accept: Boolean)` | Nach dem Dialog mit dem gewählten Namen: FileName kann geprüft und geändert werden, Accept := False verwirft die Wahl. Nutzung: `if not EndsText('.csv', FileName) then FileName := FileName + '.csv';` Praxis: Die Wahl prüfen oder anpassen: falsche Dateitypen mit Accept := False ablehnen, eine fehlende Endung ergänzen oder den Pfad relativ zum Programmordner speichern. |
| `OnBeforeDialog` | `TPPGFileBeforeDialogEvent` `(Sender: TObject; var Allow: Boolean)` | Bevor der Dialog öffnet: Allow := False bricht ab; hier lassen sich z. B. Filter oder InitialDir anpassen. Praxis: Den Dialog vorbereiten, z. B. InitialDir auf den gewählten Projektordner setzen, oder mit Allow := False abbrechen, solange eine Voraussetzung fehlt. |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Text wurde geändert (Tippen, Einfügen, Code). Praxis: Abhängige Teile sofort nachziehen, z. B. „Importieren“ erst freigeben, wenn die Datei existiert, oder eine Vorschau des Inhalts laden. Feuert bei Tippen, Ablegen und Dialog. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. Praxis: Für einen Hilfetext in der Statusleiste, z. B. „Datei wählen oder aus dem Explorer ziehen (F4 öffnet die Auswahl)“. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. Praxis: Für eigene Prüfungen beim Verlassen, z. B. ob die Datei lesbar ist. Ob sie existiert, prüft MustExist schon selbst. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` Praxis: Für eigene Tasten im Feld, z. B. Enter startet den Import. F4 und Alt+Pfeil runter öffnen bereits den Dialog. |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. Praxis: Um Zeichen abzuweisen, die in Windows-Pfaden nicht erlaubt sind (z. B. * ? " < > \|): Key := #0. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. Praxis: Selten nötig; z. B. um nach dem Tippen verzögert eine Vorschau zu laden. Für Textänderungen ist OnChange der richtige Ort. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. Praxis: Selten nötig, ein Klick setzt nur den Textcursor. Für den Knopf im Feld OnBeforeDialog nehmen, nicht OnClick. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. Praxis: Um z. B. die gewählte Datei per Doppelklick im zugehörigen Programm zu öffnen (ShellExecute), wenn das Feld schon einen Pfad enthält. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. Praxis: Selten für Dateifelder; Markieren und Knopf erledigt das Feld selbst. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. Praxis: Selten nötig; feuert bei jeder Mausbewegung. Hinweise zeigt man besser über Hint. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. Praxis: Gegenstück zu OnMouseDown; beim Dateifeld selten gebraucht. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. Praxis: Um beim Überfahren den vollständigen Pfad in einer Statuszeile zu zeigen, wenn er im Feld abgeschnitten ist. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. Praxis: Gegenstück zu OnMouseEnter: die Pfadanzeige in der Statuszeile wieder leeren. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. Praxis: Selten für Dateifelder; Handled := True verhindert, dass der Parent scrollt. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. Praxis: Nur in Spezialfällen (Werkzeugfenster, die beim Klick nicht aktiv werden sollen); sonst nicht belegen. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. Praxis: Um das Kontextmenü vor dem Öffnen anzupassen, z. B. „Im Explorer zeigen“ nur bei vorhandener Datei freigeben. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. Praxis: Für VCL-Drag & Drop innerhalb der Anwendung, z. B. einen Eintrag aus einer Liste „Zuletzt verwendet“ aufs Feld ziehen und dessen Pfad übernehmen. Dateien aus dem Explorer nimmt AcceptDrop an. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. Praxis: Zusammen mit OnDragDrop: Accept := Source = lstZuletzt erlaubt das Ablegen nur aus der passenden Liste. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. Praxis: Nur wenn das Feld selbst gezogen wird (DragMode = dmAutomatic); beim Dateifeld praktisch nie. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). Praxis: Gegenstück zu OnStartDrag; beim Dateifeld praktisch nie gebraucht. |

Tests: `PPG.Tests.Audit11C` (TAudit11CBehaviourTests, TAudit11CGdiTests); `PPG.Tests.Audit45` (TSetterFixTests); `PPG.Tests.Audit5d`; `PPG.Tests.Phase12b`; `PPG.Tests.Phase12c` (TFieldsGalleryTests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGFileEdit.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
