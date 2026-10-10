# TPPGPasswordEdit

Palette **PPGlow** - Unit `PPG.PasswordEdit` - Basis `TPPGCustomPasswordEdit`

**Vorbild:** WinUI PasswordBox

## Wofür

Das Kennwortfeld nimmt Kennwörter, PINs und andere Geheimnisse entgegen. Die Zeichen sind verdeckt; ein Auge im Feld deckt sie bei Bedarf auf, und bei aktiver Feststelltaste erscheint ein Hinweis. Kopieren, Ausschneiden und der Rückgängig-Puffer geben den Klartext nicht heraus, und der Text wird nie in der DFM gespeichert.

## Wann verwenden

- Für alles, was niemand mitlesen soll: Anmeldung, Kennwort ändern, PIN, API-Schlüssel oder Zugangsdaten zu einem Server.
- Statt `TPPGEdit` mit `PasswordChar`: Das Kennwortfeld bringt Auge, Feststelltasten-Hinweis, Kopiersperre und Screenreader-Schutz („geschützt", kein Wert) schon mit.
- Nicht für Daten, die nur formatiert sein müssen (IBAN, Telefonnummer); dafür ist `TPPGMaskEdit` gedacht.
- Für Zahlen-PINs mit fester Stellenzahl reicht das Kennwortfeld mit `MaxLength`; ein eigenes PIN-Control gibt es nicht.

## Unterschiede und Hinweise

- Die Zeichen sind verdeckt (`PasswordChar`, Vorgabe ●).
- Das Auge im Feld deckt auf:
  - `rmPeek`: nur solange gedrückt
  - `rmToggle`: Umschalten
  - `rmHidden`: ohne Auge
- `Revealed` aus Code löst kein Ereignis aus. `OnRevealChange` kommt nur bei Anwenderaktionen.
- Bei aktiver Feststelltaste erscheint eine Plakette im Feld, solange es den Fokus hat (`CapsLockWarning`). Screenreader hören den Hinweis in der Beschreibung.
- Solange das Passwort verdeckt ist, sind Kopieren und Ausschneiden gesperrt (`WM_COPY`/`WM_CUT`, Strg+C, Strg+Einfg).
- Nach dem Aufdecken wird der Rückgängig-Puffer des Edits geleert, damit kein Klartext darin liegt. `Clear` überschreibt den Text im Speicher.
- Screenreader: Zustand „geschützt“ (`STATE_SYSTEM_PROTECTED`), kein Wert.

## Beispiel

```pascal
PPGPasswordEdit1.RevealMode := rmToggle;
if Length(PPGPasswordEdit1.Text) < 8 then
  PPGPasswordEdit1.ValidationState := pvsError;
```

## Verhalten (aus dem Quelltext)

TPPGPasswordEdit - Kennwortfeld (Phase 12b, Vorbild WinUI PasswordBox).

- Zeichen verdeckt (PasswordChar, Vorgabe Punkt U+25CF).
- Auge im Feld: RevealMode rmPeek zeigt nur, solange es gedrueckt ist; rmToggle schaltet um; rmHidden ohne Auge. Revealed aus Code.
- Hinweis bei aktiver Feststelltaste (Plakette im Feld, solange es den Fokus hat; CapsLockWarning).
- Kein Kopieren und Ausschneiden, solange verdeckt (WM_COPY/WM_CUT werden abgefangen, auch Strg+C/Strg+Einfg). Nach dem Aufdecken wird der Rueckgaengig-Puffer des Edits geleert (EM_EMPTYUNDOBUFFER), damit dort kein Klartext liegt. Clear ueberschreibt den Text im Speicher.
- Screenreader: Rolle Text mit STATE_SYSTEM_PROTECTED, kein Wert.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. Praxis: Einmal für die ganze Anwendung festlegen, am besten über einen TPPGStyleManager, damit Anmeldemaske und übrige Felder gleich aussehen. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. Praxis: Einen TPPGStyleManager aufs Formular (oder ein Datenmodul) legen und allen Feldern zuweisen; dann folgen alle Eingabefelder gemeinsam Preset und Hell/Dunkel. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` Praxis: Nur für Sonderfälle anpassen, z. B. ein hervorgehobenes Anmeldefeld auf einem farbigen Startbildschirm. Sonst Preset bzw. StyleManager verwenden, damit alle Eingabefelder gleich aussehen. |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. Praxis: An lassen; Hover und Fokus wirken dann ruhiger. RespectSystemSettings = True beachtet die Windows-Einstellung „Animationen anzeigen". |
| `PasswordChar` | `Char` | `#$25CF` | Zeichen, das statt der Eingabe gezeigt wird (Vorgabe Punkt ●). Kopieren und Ausschneiden sind gesperrt, solange verdeckt. Praxis: Die Vorgabe ● (U+25CF) wie in Windows 11 lassen. Ein * nur, wenn die Oberfläche zu älteren Programmen passen soll; #0 ist nicht erlaubt, zum Aufdecken gibt es Revealed. |
| `RevealMode` | `TPPGRevealMode` | `rmPeek` | Auge im Feld: rmPeek zeigt den Klartext nur, solange es gedrückt ist; rmToggle schaltet per Klick um; rmHidden zeigt kein Auge. Werte: `rmPeek`, `rmToggle`, `rmHidden`. Praxis: rmPeek für Anmeldemasken (nur kurz nachsehen), rmToggle für „Kennwort festlegen", wo man das Getippte in Ruhe prüfen will. rmHidden für Wiederholungsfelder oder Orte, an denen niemand mitlesen darf. |
| `CapsLockWarning` | `Boolean` | `True` | True: Bei aktiver Feststelltaste erscheint im Feld ein Hinweis, solange es den Fokus hat. Praxis: True lassen: Der Hinweis auf die Feststelltaste erspart Anwendern Fehlversuche und gesperrte Konten. Abschalten nur bei Feldern, die ohnehin nur Ziffern erwarten (z. B. eine PIN). |
| `TextHint` | `string` |  | Platzhaltertext im leeren Feld (z. B. „Suchen …"). Nutzung: `Edit1.TextHint := 'E-Mail-Adresse';` Praxis: Sagt, was erwartet wird: „Kennwort", „Mindestens 8 Zeichen" oder „Kennwort wiederholen". Die Beschriftung davor ersetzt er nicht. |
| `TextHintVisibleOnFocus` | `Boolean` | `False` | True: Der Platzhalter bleibt sichtbar, bis getippt wird; False: er verschwindet schon beim Fokus. Praxis: True, wenn der Platzhalter eine Regel nennt („Mindestens 8 Zeichen"), die man beim Tippen noch sehen soll; sonst False lassen. |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Ergebnis einer Prüfung: pvsNone (neutral), pvsValid (grüner Rand), pvsWarning (gelb), pvsError (rot). Die Farben kommen aus den Signal-Tokens; ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if not IstMail(Edit1.Text) then begin Edit1.ValidationState := pvsError; Edit1.ValidationHint := 'Keine gültige Adresse'; end;` Praxis: Beim Tippen in OnChange setzen: pvsError bei zu kurzen oder falschen Kennwörtern, pvsWarning bei schwachen, pvsValid wenn alles passt. Nach dem Neutippen wieder pvsNone. |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState; erscheint als Tooltip und wird vom Screenreader vorgelesen. Praxis: Kurz und konkret sagen, was fehlt: „Mindestens 8 Zeichen." oder „Kennwort falsch. Noch 2 Versuche." Leer lassen, wenn alles stimmt. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). Praxis: True lassen: Im Hochkontrast bleiben Rand, Auge und der Hinweis auf die Feststelltaste gut sichtbar. |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen (z. B. eingebettet in eigene Flächen). Praxis: bsSingle für normale Formulare. bsNone, wenn das Feld in eine eigene Fläche eingebettet ist, z. B. eine Anmeldekarte mit eigenem Rahmen. |
| `MaxLength` | `Integer` | `0` | Höchstzahl der Zeichen; 0 = unbegrenzt. Praxis: Auf die Grenze des Systems setzen, in dem das Kennwort gespeichert wird (z. B. 64). So scheitert ein zu langes Kennwort nicht erst beim Speichern. |
| `ReadOnly` | `Boolean` | `False` | True: Der Text kann gelesen, markiert und kopiert, aber nicht geändert werden. Die Optik bestimmt ReadOnlyStyle. Praxis: Selten sinnvoll: ein schreibgeschütztes Kennwortfeld zeigt kein Auge. Für „Kennwort ist gesetzt" lieber ein Label oder Enabled = False. |
| `ReadOnlyStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Eigene Optik bei ReadOnly: Fläche, Text- und Randfarbe (je auch für Dunkel). clDefault = wie im bearbeitbaren Zustand. Nutzung: `Edit1.ReadOnlyStyle.Color := $00F0F0F0; Edit1.ReadOnlyStyle.TextColor := clGrayText;` Praxis: Nur zusammen mit ReadOnly wichtig: z. B. eine graue Fläche, damit klar ist, dass das gespeicherte Kennwort nicht hier geändert wird. |
| `TabStop` | `Boolean` | `True` | True: Das Feld ist mit Tab erreichbar. Praxis: True lassen; das Kennwortfeld muss per Tastatur erreichbar sein. |
| `Text` | `string` |  | Der Inhalt des Felds. Setzen aus Code löst OnChange aus (wie bei TEdit). Nutzung: `Edit1.Text := '';` Praxis: Nur kurz lesen (prüfen oder als Hash speichern) und danach mit Clear löschen. Der Text wird nie in der DFM gespeichert, ein Kennwort gehört also nicht in den Objektinspektor. |
| `ShowClearButton` | `Boolean` | `False` | True: Ein „×"-Knopf im Feld löscht den Text (nur sichtbar, wenn Text vorhanden und das Feld bearbeitbar ist). Praxis: Bei Kennwortfeldern meist aus lassen; Entf oder Strg+A und Rücktaste genügen. Praktisch auf Touch-Geräten, um eine Fehleingabe mit einem Tipp zu verwerfen. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. Praxis: Im Anmeldedialog meist alNone. alTop mit AlignWithMargins, wenn Benutzer- und Kennwortfeld in einem Panel untereinander gestapelt werden sollen. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` Praxis: In Dialogen mit veränderbarer Größe [akLeft, akTop, akRight] setzen, dann wächst das Kennwortfeld mit dem Fenster in die Breite. |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). Praxis: True lassen: Die Höhe folgt der Schrift, und das Feld passt zu den übrigen Eingabefeldern des Formulars. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. Praxis: Nur für arabische oder hebräische Oberflächen ändern; am Formular setzen und über ParentBiDiMode übernehmen. |
| `Color` | `TColor` | `clWindow` | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. Praxis: Selten nötig; die Feldfarbe kommt aus Preset und Appearance. Color wirkt nur ohne Dark Mode, VCL-Style und Hochkontrast. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` Praxis: MinWidth z. B. 200 setzen, wenn das Feld mit Anchors oder Align schrumpfen kann; sonst passt ein langes Kennwort samt Auge nicht mehr hinein. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. Praxis: Sperren Sie das Feld nach zu vielen Fehlversuchen oder solange die Anmeldung läuft; gesperrte Felder bekommen keinen Fokus und keine Eingabe. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` Praxis: Am Formular einstellen und über ParentFont übernehmen. Eine etwas größere Schrift (11 bis 12) macht die Punkte auf Touch-Geräten besser zählbar. |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. Praxis: True lassen, damit das Feld der Leserichtung des Formulars folgt. |
| `ParentColor` | `Boolean` | `False` | True: Color wird vom Parent übernommen. Praxis: False lassen: Ein Eingabefeld soll sich mit eigener Feldfarbe vom Hintergrund abheben. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. Praxis: True lassen, damit Kennwort- und Benutzerfeld dieselbe Schrift tragen. Ändern Sie Font, wird es automatisch False. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). Praxis: True lassen und ShowHint einmal am Formular einschalten, dann zeigt auch das Kennwortfeld seine Hinweise. |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. Praxis: Meist leer lassen, das Standardmenü genügt. Ein eigenes Menü nur für Zusatzbefehle wie „Kennwort erzeugen"; Kopieren und Ausschneiden bleiben gesperrt, solange das Kennwort verdeckt ist. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. Praxis: Einmal am Formular einschalten statt an jedem Feld; dann bleibt ParentShowHint True und der ValidationHint erscheint als Tooltip. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. Praxis: Nur bei VCL-Styles wichtig: seClient herausnehmen, wenn das Feld seine Farben aus Appearance behalten soll. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). Praxis: In der Anmeldemaske Benutzer vor Kennwort und Kennwort vor „Anmelden", damit Tab der Lesereihenfolge folgt. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. Praxis: Ausblenden, wenn ein Kennwort nicht gebraucht wird, z. B. bei Windows-Anmeldung (Single Sign-on) statt eigener Benutzerverwaltung. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. Praxis: Nur für Touch-Geräte: Gesten anhaken und in OnGesture auswerten. Für die Eingabe selbst nicht nötig. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. Praxis: dmManual lassen. Ein Kennwortfeld wird nicht gezogen, und dmAutomatic würde das Markieren mit der Maus stören. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). Praxis: Beim Kennwortfeld praktisch nie gebraucht; nur sichtbar mit DragMode = dmAutomatic. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. Praxis: Bei PPGlow-Controls nicht nötig, sie zeichnen immer flackerfrei. Steht nur da, damit alte Formulare ohne Fehler laden. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. Praxis: True lassen; bei PPGlow-Controls ohne sichtbare Wirkung. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` Praxis: Zusammen mit Align einschalten, damit gestapelte Felder nicht aneinanderkleben; den Abstand (typisch 4 bis 8) stellen Sie unter Margins ein. |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. Praxis: Im Designer per Maus; im Code nur bei dynamisch erzeugten Feldern, z. B. FPassword.SetBounds(16, 108, 300, 32). |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. Praxis: Wie Left: im Designer per Maus, im Code nur bei dynamisch erzeugten Feldern. |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: 240 bis 300 Pixel; breit genug für lange Passphrasen samt Auge und Feststelltasten-Hinweis. |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Mit AutoSize bestimmt die Schrift die Höhe; ohne AutoSize 32 Pixel wie die übrigen Windows-11-Eingabefelder. |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. Praxis: crDefault lassen; im Feld zeigt Windows ohnehin den Textcursor (I-Balken). |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` Praxis: Für die Kennwortregeln („Mindestens 8 Zeichen"), solange keine Prüfung läuft. Ist ValidationHint gesetzt, erklärt der Tooltip den Prüfzustand. |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. Praxis: htKeyword, wenn Sie Stichwörter pflegen, sonst htContext mit Kontext-IDs. Ohne Hilfedatei egal. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. Praxis: Wie HelpContext, aber über ein Stichwort (HelpType = htKeyword), z. B. „Kennwort". |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). Praxis: Nur mit Hilfedatei: die Kontext-ID der Seite „Kennwort vergessen / Kennwortregeln" eintragen, die F1 im Feld öffnet. |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. Praxis: Abstand zum Nachbarn bei Align, z. B. Margins.Top = 4 zwischen Beschriftung und Feld. Wirkt nur mit AlignWithMargins. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. Praxis: Für einen Hinweis mit Titel, z. B. die Kennwortregeln („Mindestens 8 Zeichen, Ziffern und Buchstaben"): einen TPPGCustomHint zuweisen. |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. Praxis: True lassen, damit ein am Formular gesetzter CustomHint auch hier gilt. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) Praxis: Sprechende Namen vergeben (edtKennwort, edtKennwortNeu) statt PPGPasswordEdit1; der Code der Prüfung wird dadurch lesbar. |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). Praxis: Für mehrere Kennwortfelder mit gemeinsamer Prüfroutine, z. B. Tag = 1 für „neu" und 2 für „wiederholen". |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` Praxis: Nur auf Touch-Geräten, z. B. eine Wischgeste zum Leeren des Felds. |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Text wurde geändert (Tippen, Einfügen, Code). Praxis: Hier prüfen: Länge, Mischung der Zeichen, Übereinstimmung mit der Wiederholung; danach ValidationState setzen und den Speichern-Button freigeben oder sperren. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. Praxis: Um beim Betreten die Kennwortregeln in einer Statuszeile oder einem Infotext neben dem Feld zu zeigen. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. Praxis: Guter Ort für die abschließende Prüfung, wenn das Feld verlassen wird, z. B. Wiederholung mit dem neuen Kennwort vergleichen. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` Praxis: Für Enter = Anmelden: if Key = VK_RETURN then btnAnmelden.Click. Strg+C und Strg+X fängt das Feld selbst ab, solange das Kennwort verdeckt ist. |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. Praxis: Um Zeichen abzulehnen, z. B. Leerzeichen in einer PIN: if Key = ' ' then Key := #0. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. Praxis: Selten gebraucht; z. B. für eine Stärkeanzeige, die erst nach dem Loslassen der Taste aktualisiert wird. |
| `OnRevealChange` | `TNotifyEvent` `(Sender: TObject)` | Der Anwender hat den Klartext über das Auge ein- oder ausgeblendet (Revealed geändert). Praxis: Reagiert auf das Auge: z. B. das Wiederholungsfeld mit aufdecken (edtWiederholen.Revealed := edtKennwort.Revealed) oder das Aufdecken protokollieren. Revealed aus Code löst es nicht aus. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. Praxis: Selten gebraucht; feuert beim Klick ins Feld. Für Prüfungen besser OnChange oder OnExit. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. Praxis: Selten gebraucht; ein Doppelklick markiert ohnehin den ganzen Inhalt. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. Praxis: Selten für Kennwortfelder; das Auge bedient das Feld selbst. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. Praxis: Selten gebraucht; feuert bei jeder Mausbewegung über dem Feld. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. Praxis: Selten gebraucht; Gegenstück zu OnMouseDown. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. Praxis: Um beim Überfahren die Kennwortregeln neben dem Feld einzublenden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. Praxis: Gegenstück zu OnMouseEnter: eingeblendete Regeln wieder ausblenden. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. Praxis: Beim Kennwortfeld kaum nötig; Handled := True verhindert, dass der Parent scrollt. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. Praxis: Nur in Spezialfällen (Werkzeugfenster) belegen; sonst leer lassen. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. Praxis: Um das Kontextmenü vor dem Öffnen anzupassen oder es mit Handled := True ganz zu unterdrücken, z. B. an öffentlichen Terminals. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. Praxis: Für Kennwortfelder nicht üblich; Kennwörter sollen nicht per Drag & Drop aus anderen Programmen kommen. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. Praxis: Mit Accept := False Drag & Drop auf das Kennwortfeld ausdrücklich ablehnen, falls ein Parent es sonst annimmt. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. Praxis: Beim Kennwortfeld praktisch nie gebraucht, weil es nicht gezogen wird. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). Praxis: Beim Kennwortfeld praktisch nie gebraucht, weil es nicht gezogen wird. |

Tests: `PPG.Tests.Audit11C` (TAudit11CBehaviourTests, TAudit11CGdiTests); `PPG.Tests.Audit45` (TStreamingFixTests); `PPG.Tests.Audit5d` (TStage3Tests); `PPG.Tests.Phase12a` (TPasswordEditTests); `PPG.Tests.Phase12c` (TFieldsGalleryTests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGPasswordEdit.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
