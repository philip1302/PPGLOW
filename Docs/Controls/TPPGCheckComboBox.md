# TPPGCheckComboBox

Palette **PPGlow** - Unit `PPG.CheckComboBox` - Basis `TPPGCustomDropDownField`

**Vorbild:** TMS TCheckListEdit

## Wofür

Die CheckComboBox lässt den Anwender mehrere Werte aus einer Liste wählen und braucht dabei nur den Platz eines Eingabefelds. Typisch sind Filter („Status: Aktiv, Interessent“), Wochentage, Abteilungen oder Kategorien. Die Auswahl steht als ein Text in `CheckedText` und lässt sich so direkt speichern, laden oder an ein Datenbankfeld binden.

## Wann verwenden

- Für Mehrfachauswahl mit wenig Platz, z. B. in Filterleisten über Listen und Grids. Bei genau einem Wert ist `TPPGComboBox` richtig.
- Statt `TPPGCheckListBox`, wenn die Auswahl nur gelegentlich geändert wird und die Liste nicht dauerhaft sichtbar sein muss. Soll man alle Haken auf einen Blick sehen, ist die CheckListBox klarer.
- Statt `TPPGCheckGroup` bzw. mehrerer `TPPGCheckBox`, wenn es mehr als etwa fünf Werte sind oder die Werte aus Daten kommen. Wenige feste Optionen sind als Kästchen direkt im Formular schneller bedient.
- Für frei getippte Schlagwörter, die nicht aus einer festen Liste stammen, ist `TPPGTagEdit` besser geeignet.
- Mit Datenbank: `TPPGDBCheckComboBox` (gleiche Bedienung, Auswahl im Feld als `CheckedText`).

## Unterschiede und Hinweise

- Mehrfachauswahl im Aufklappfeld. Das Popup bleibt beim Anhaken offen; Enter oder ein Klick daneben schließt es.
- Haken wirken sofort (`OnItemCheck`, `OnChange`). Esc schließt nur und nimmt nichts zurück.
- Anzeige im Feld (`DisplayMode`):
  - `cdmCompact`: „A, B, +2“ (`MaxDisplayItems`)
  - `cdmList`: alle Namen
  - `cdmCount`: „3 ausgewählt“
- `ShowSelectAll` zeigt „Alle auswählen“ als erste Zeile. Ab `FilterThreshold` Einträgen filtern getippte Zeichen die Liste; die Leertaste hakt dabei weiter an.
- `CheckedText` liefert die gewählten Einträge, getrennt durch `Delimiter`. So stehen sie im DFM und in `TPPGDBCheckComboBox`.
- Code (`Checked[]`, `CheckAll`, `CheckedText`) löst keine Ereignisse aus.
- „Alle auswählen“ löst ein `OnChange` aus, aber kein `OnItemCheck` je Eintrag.

## Beispiel

```pascal
PPGCheckComboBox1.Items.CommaText := 'Kunde,Lieferant,Partner';
PPGCheckComboBox1.CheckedText := 'Kunde;Partner';
```

## Verhalten (aus dem Quelltext)

TPPGCheckComboBox - Mehrfachauswahl im Aufklappfeld (Phase 12e,
Vorbild TMS TCheckListEdit).

- Popup-Liste mit Kaestchen (Indikator-Renderer wie CheckListBox, keine neue Zeichenlogik). Das Popup bleibt beim Anhaken offen; Enter oder ein Klick daneben schliesst. Haken wirken sofort (OnItemCheck, OnChange).
- Anzeige im Feld: "A, B, +2" (DisplayMode cdmCompact), alle Namen (cdmList) oder "3 ausgewaehlt" (cdmCount). Ohne Auswahl: TextHint.
- Optional "Alle auswaehlen" als erste Zeile (ShowSelectAll) und eine Filterzeile ab FilterThreshold Eintraegen (getippte Zeichen filtern).
- CheckedText: gewaehlte Eintraege getrennt durch Delimiter; damit gespeichert (DFM) und an DB-Felder gebunden (IPPGFieldValue).
- Code (Checked[], CheckAll, CheckedText) loest keine Ereignisse aus.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Items` | `TStrings` |  | Die auswählbaren Einträge, je Zeile einer. Den Haken je Eintrag liest und setzt man über Checked[Index]. Nutzung: `PPGCheckComboBox1.Items.CommaText := 'Rot,Grün,Blau'; PPGCheckComboBox1.Checked[1] := True;` Praxis: Die Werte, aus denen der Anwender mehrere wählt, z. B. Abteilungen, Wochentage oder Status für einen Listenfilter. Kommen sie aus der Datenbank, füllen Sie Items beim Öffnen des Formulars oder in OnDropDown. |
| `CheckedText` | `string` |  | Die angehakten Einträge als ein Text, getrennt durch Delimiter (z. B. „Rot;Grün"). So wird die Auswahl in der DFM gespeichert und an DB-Felder gebunden. Setzen aus Code hakt die passenden Einträge an, ohne OnChange oder OnItemCheck auszulösen. Nutzung: `PPGCheckComboBox1.CheckedText := 'Montag;Mittwoch';` Praxis: Der bequemste Weg zum Speichern und Laden: Settings.Values['Tage'] := Combo.CheckedText bzw. umgekehrt. Setzen aus Code löst kein OnChange aus; prüfen oder filtern Sie danach selbst. |
| `Delimiter` | `Char` | `';'` | Trennzeichen in CheckedText (und damit im DB-Feld). Vorgabe „;". Praxis: An das Ziel anpassen: „," für INI-Werte und CSV-artige Felder, „;" (Vorgabe), wenn die Einträge selbst Kommas enthalten können. Das Zeichen darf in keinem Eintrag vorkommen. |
| `DisplayDelimiter` | `string` |  | Trenner zwischen den Namen in der Anzeige des Felds (Vorgabe „, "). Betrifft nur die Anzeige, nicht CheckedText. Praxis: Meist „, " lassen. „ / " oder „ · " passt, wenn die Namen selbst Kommas enthalten; auf CheckedText hat es keinen Einfluss. |
| `DisplayMode` | `TPPGCheckComboDisplay` | `cdmCompact` | Anzeige der Auswahl im geschlossenen Feld: cdmCompact zeigt die ersten MaxDisplayItems Namen und „+n", cdmList alle Namen, cdmCount nur „3 ausgewählt". Ohne Auswahl erscheint TextHint. Werte: `cdmCompact`, `cdmList`, `cdmCount`. Praxis: cdmCompact für Filter in schmalen Leisten („Rot, Blau, +2"), cdmList, wenn das Feld breit genug für alle Namen ist, cdmCount bei langen Listen wie Regionen oder Kostenstellen („5 ausgewählt"). |
| `MaxDisplayItems` | `Integer` | `2` | Bei DisplayMode = cdmCompact: so viele Namen werden ausgeschrieben, der Rest als „+n" (1..100). Praxis: So viele Namen, wie in die Feldbreite passen: 2 für ein 200 px breites Filterfeld, 3 bis 4 bei breiten Feldern. Der Rest erscheint als „+n". |
| `ShowSelectAll` | `Boolean` | `False` | True: Erste Zeile der Liste ist „Alle auswählen" zum An- und Abhaken aller Einträge. Praxis: Einschalten, wenn „alles" eine häufige Wahl ist, z. B. bei Status- oder Wochentagfiltern. Die Zeile zeigt auch an, ob alle, einige oder keine Einträge gewählt sind. |
| `FilterThreshold` | `Integer` | `12` | Ab dieser Zahl von Einträgen erscheint oben in der Liste eine Filterzeile; getippte Zeichen filtern die Einträge. 0 = nie. Praxis: Bei langen Listen (Länder, Kunden, Kostenstellen) senken, z. B. auf 10, damit man durch Tippen sucht statt zu scrollen. 0 schaltet die Filterzeile ganz ab, etwa bei festen kurzen Listen. |
| `DropDownCount` | `Integer` | `PPGDefaultDropDownCount` | Sichtbare Zeilen der Aufklappliste, danach wird gescrollt (1..100). Praxis: 8 bis 12 Zeilen sind angenehm; bei Wochentagen 7, damit alles ohne Scrollen sichtbar ist. Sehr lange Listen besser mit Filterzeile (FilterThreshold) statt mit vielen Zeilen. |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. Praxis: Am besten über einen TPPGStyleManager für die ganze Anwendung festlegen, damit Filterfelder, Edits und Buttons gleich aussehen. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. Praxis: Den StyleManager des Formulars zuweisen; dann folgt das Feld samt Aufklappliste der Optik und dem Hell/Dunkel-Wechsel der Anwendung. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` Praxis: Nur für einzelne Hervorhebungen anpassen, z. B. einen kräftigeren Rand für einen Pflichtfilter. Die Haken in der Liste nehmen die Farben aus Appearance.Checked. |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. Praxis: An lassen; Hover- und Fokuswechsel wirken dann ruhiger. Die Windows-Einstellung „Animationen anzeigen" wird mit RespectSystemSettings beachtet. |
| `TextHint` | `string` |  | Platzhaltertext im leeren Feld (z. B. „Suchen …"). Nutzung: `Edit1.TextHint := 'E-Mail-Adresse';` Praxis: Sagt, was ohne Haken gilt: „Alle Status" bei Filtern oder „Bitte wählen" bei Pflichtangaben. So versteht der Anwender das leere Feld richtig. |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Ergebnis einer Prüfung: pvsNone (neutral), pvsValid (grüner Rand), pvsWarning (gelb), pvsError (rot). Die Farben kommen aus den Signal-Tokens; ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if not IstMail(Edit1.Text) then begin Edit1.ValidationState := pvsError; Edit1.ValidationHint := 'Keine gültige Adresse'; end;` Praxis: Nach einer Prüfung setzen, z. B. pvsError, wenn bei einer Pflichtangabe kein Eintrag angehakt ist; nach der Korrektur wieder pvsNone. |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState; erscheint als Tooltip und wird vom Screenreader vorgelesen. Praxis: Die konkrete Erklärung zum Fehler („Bitte mindestens einen Tag ankreuzen."). Sie erscheint als Tooltip und wird vom Screenreader vorgelesen. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). Praxis: True lassen: Im Windows-Hochkontrast sind Feld, Haken und Liste dann in klaren Systemfarben gezeichnet. |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen (z. B. eingebettet in eigene Flächen). Praxis: bsSingle für Formulare; bsNone, wenn das Feld in eine eigene Fläche eingebettet ist, z. B. in eine Filterzeile über einem Grid. |
| `ReadOnly` | `Boolean` | `False` | True: Der Text kann gelesen, markiert und kopiert, aber nicht geändert werden. Die Optik bestimmt ReadOnlyStyle. Praxis: Für Anwender ohne Bearbeitungsrecht: Die Auswahl bleibt sichtbar und die Liste lässt sich öffnen, aber Haken ändern sich nicht. |
| `ReadOnlyStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Eigene Optik bei ReadOnly: Fläche, Text- und Randfarbe (je auch für Dunkel). clDefault = wie im bearbeitbaren Zustand. Nutzung: `Edit1.ReadOnlyStyle.Color := $00F0F0F0; Edit1.ReadOnlyStyle.TextColor := clGrayText;` Praxis: Damit gesperrte Felder sofort als nicht änderbar erkennbar sind, z. B. eine leicht graue Fläche (Color) bei ReadOnly. |
| `TabStop` | `Boolean` | `True` | True: Das Feld ist mit Tab erreichbar. Praxis: True lassen; das Feld wird per Tab erreicht und mit Leertaste oder Alt+Pfeil runter aufgeklappt. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. Praxis: Meist alNone. alTop in einer schmalen Seitenleiste mit Filtern untereinander, dann mit AlignWithMargins für Abstände. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` Praxis: In größenveränderlichen Formularen [akLeft, akTop, akRight], damit das Feld mitwächst und mehr Namen zeigt. |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). Praxis: True lassen: Die Höhe passt dann zur Schrift und das Feld ist so hoch wie Edits und ComboBoxen daneben. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. Praxis: Nur für arabische oder hebräische Oberflächen; am Formular setzen und über ParentBiDiMode übernehmen. |
| `Color` | `TColor` | `clWindow` | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. Praxis: Selten nötig; die Feldfarbe kommt aus Appearance bzw. dem Preset. Color wirkt nur ohne Dark Mode, VCL-Style und Hochkontrast. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` Praxis: MinWidth setzen (z. B. 160), damit ein mitwachsendes Feld beim Verkleinern noch mindestens einen Namen zeigt. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. Praxis: Sperren, wenn der Filter gerade nicht gilt, z. B. „Wochentage" nur bei Wiederholung „wöchentlich". Für reines Ansehen besser ReadOnly. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` Praxis: Über ParentFont die Formularschrift übernehmen. Eine eigene Schrift gilt für Feld und Aufklappliste gemeinsam. |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. Praxis: True lassen, damit das Feld der Leserichtung des Formulars folgt. |
| `ParentColor` | `Boolean` | `False` | True: Color wird vom Parent übernommen. Praxis: False lassen; das Feld hat seine eigene Feldfarbe aus Appearance. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. Praxis: True lassen, damit Feld und Liste die Formularschrift tragen. Ändern Sie Font, wird es automatisch False. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). Praxis: True lassen und ShowHint einmal am Formular einschalten. |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. Praxis: Für Zusatzbefehle per Rechtsklick, z. B. „Auswahl als Vorlage speichern" oder „Alle abwählen". |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. Praxis: Einmal am Formular einschalten statt an jedem Feld; dann bleibt ParentShowHint True. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. Praxis: Nur bei VCL-Styles wichtig: Ohne seClient behält das Feld seine eigenen PPGlow-Farben. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). Praxis: So vergeben, dass Tab in der Reihenfolge der Beschriftungen durch die Filter läuft. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. Praxis: Filter ausblenden, die für den Anwender nicht gelten, z. B. „Filiale" in einer Einzelstandort-Lizenz. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. Praxis: Nur für Touch-Geräte mit eigenen Gesten; Aufklappen und Anhaken gehen auch ohne Einstellung per Tippen. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. Praxis: dmManual lassen, sonst startet ein Klick zum Aufklappen ein Ziehen. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). Praxis: Nur mit DragMode = dmAutomatic sichtbar; bei Auswahlfeldern praktisch nie gebraucht. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. Praxis: Nicht nötig, PPGlow zeichnet immer flackerfrei; steht nur da, damit Formulare aus der VCL laden. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. Praxis: True lassen; ohne sichtbare Wirkung bei PPGlow-Controls. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` Praxis: Zusammen mit Align einschalten, damit untereinander angedockte Filterfelder nicht aneinanderkleben (Margins 4 bis 8). |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. Praxis: Im Designer per Maus; im Code nur bei dynamisch erzeugten Filtern, z. B. Combo.SetBounds(X, 40, 200, 32). |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. Praxis: Wie Left: im Designer per Maus, im Code nur bei dynamisch erzeugten Feldern. |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: So breit, dass die üblichen zwei bis drei Namen hineinpassen, typisch 200 bis 300 px; die Aufklappliste ist mindestens so breit wie das Feld. |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Mit AutoSize bestimmt die Schrift die Höhe; sonst 32 px wie die übrigen Eingabefelder im Windows-11-Stil. |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. Praxis: crDefault lassen; das Feld zeigt beim Überfahren schon, dass es klickbar ist. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` Praxis: Erklärt, was die Auswahl bewirkt („An diesen Tagen geht der Bericht raus"). Mit ShowHint am Formular einschalten. |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. Praxis: htKeyword, wenn die Hilfe Stichwörter nutzt, sonst htContext; ohne Hilfedatei egal. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. Praxis: Wie HelpContext, aber über ein Stichwort (HelpType = htKeyword). |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). Praxis: Kontext-ID der Hilfeseite, die F1 im Feld öffnet, z. B. eine Seite, die die Filterwerte erklärt. |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. Praxis: Abstände bei Align, z. B. Margins.Bottom = 8 zwischen untereinander angedockten Filtern. Wirkt nur mit AlignWithMargins. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. Praxis: Für Hinweise mit Titel und Symbol einen TBalloonHint oder TPPGCustomHint zuweisen, z. B. für erklärende Filter in Berichtsdialogen. |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. Praxis: True lassen, damit ein am Formular gesetzter CustomHint auch hier gilt. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) Praxis: Sprechend benennen, z. B. cbxStatusFilter oder cbxBerichtstage, damit der Code in OnChange lesbar bleibt. |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). Praxis: Bei mehreren gleichartigen Filtern mit gemeinsamem OnChange: Tag nennt die Spalte, nach der gefiltert wird. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnItemCheck` | `TPPGCheckItemEvent` | Der Anwender hat einen Eintrag an- oder abgehakt (auch über „Alle auswählen"); Index ist der Eintrag in Items. Danach folgt OnChange. Änderungen aus Code lösen es nicht aus. Nutzung: `procedure TForm1.CheckItem(Sender: TObject; Index: Integer); begin Log(Items[Index]); end;` Praxis: Für Prüfungen und Abhängigkeiten je Eintrag, z. B. „mindestens ein Tag" melden oder beim Haken auf „Alle Filialen" die einzelnen sperren. Index nennt den Eintrag, Checked[Index] den neuen Zustand. |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` Praxis: Auf Touch-Geräten eine Wischgeste auswerten, z. B. Wischen nach links leert die Auswahl. |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Text wurde geändert (Tippen, Einfügen, Code). Praxis: Hier reagieren Sie auf jede Änderung der Auswahl, z. B. eine Liste sofort neu filtern oder einen Speichern-Button freigeben. Code-Änderungen (CheckedText, Checked[]) lösen es nicht aus. |
| `OnCloseUp` | `TNotifyEvent` `(Sender: TObject)` | Die Aufklappliste wurde geschlossen (mit oder ohne Auswahl). Praxis: Für teure Aktionen nach der fertigen Auswahl, z. B. eine Datenbankabfrage erst nach dem Schließen statt bei jedem Haken in OnChange. |
| `OnDropDown` | `TNotifyEvent` `(Sender: TObject)` | Die Aufklappliste öffnet sich gleich; hier kann sie noch befüllt werden. Praxis: Um die Einträge erst beim Öffnen zu laden oder zu aktualisieren, z. B. die aktuellen Mitarbeiter aus der Datenbank. Bereits gesetzte Haken bleiben beim gleichen Text erhalten. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. Praxis: Z. B. einen Hilfetext zum Filter in der Statusleiste zeigen, sobald das Feld den Fokus bekommt. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. Praxis: Guter Ort für die Prüfung einer Pflichtauswahl beim Verlassen, z. B. ValidationState setzen, wenn nichts angehakt ist. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` Praxis: Für eigene Tasten am geschlossenen Feld, z. B. Entf zum Leeren der Auswahl (CheckAll(False)). Leertaste und Alt+Pfeil öffnen schon die Liste. |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. Praxis: Selten nötig; getippte Zeichen filtern in der offenen Liste schon selbst. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. Praxis: Selten nötig; z. B. um nach einer eigenen Taste aus OnKeyDown die Anzeige zu aktualisieren. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. Praxis: Feuert wie OnChange bei jedem Haken des Anwenders (wie bei der ComboBox). Für neue Formulare OnChange oder OnItemCheck nehmen; OnClick ist für übernommenen VCL-Code da. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. Praxis: Selten gebraucht; z. B. um per Doppelklick auf das Feld einen größeren Auswahldialog zu öffnen. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. Praxis: Selten nötig; Aufklappen per Klick macht das Feld selbst. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. Praxis: Feuert bei jeder Mausbewegung über dem Feld; für Hover-Optik reicht Appearance.Hot. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. Praxis: Gegenstück zu OnMouseDown; für die Auswahl selbst OnChange nehmen. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. Praxis: Um beim Überfahren die vollständige Auswahl in einer Statuszeile zu zeigen, wenn das Feld sie nur gekürzt anzeigt. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. Praxis: Gegenstück zu OnMouseEnter: die Statuszeile wieder leeren. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. Praxis: Selten nötig; Handled := True verhindert, dass das Rad den umgebenden Bereich scrollt. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. Praxis: Nur in Spezialfällen (Werkzeugfenster ohne Aktivierung) belegen. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. Praxis: Um das Kontextmenü vor dem Öffnen anzupassen, z. B. „Alle abwählen" sperren, wenn nichts angehakt ist. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. Praxis: Selten; z. B. Einträge aus einer Liste auf das Feld ziehen, um sie anzuhaken. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. Praxis: Zusammen mit OnDragDrop: Accept := Source is TPPGListBox erlaubt das Ablegen nur aus passenden Quellen. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. Praxis: Nur mit DragMode = dmAutomatic; bei Auswahlfeldern praktisch nie gebraucht. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). Praxis: Nur mit DragMode = dmAutomatic; Target = nil heißt, das Ziehen wurde abgebrochen. |

Tests: `PPG.Tests.Audit11C` (TAudit11CBehaviourTests, TAudit11CGdiTests); `PPG.Tests.Audit45` (TNamingTests, TSetterFixTests, TStreamingFixTests); `PPG.Tests.Audit5d` (TVclPropsTests); `PPG.Tests.Phase12c` (TCheckComboTests, TFieldsGalleryTests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGCheckComboBox.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
