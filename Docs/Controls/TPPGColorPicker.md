# TPPGColorPicker

Palette **PPGlow** - Unit `PPG.ColorPicker` - Basis `TPPGCustomDropDownField`

**Vorbild:** `TColorBox`, TMS TAdvColorPickerDropDown

## Wofür

Der ColorPicker lässt den Anwender eine Farbe wählen, z. B. für Kategorien, Markierungen in Listen oder Diagrammfarben. Das Feld zeigt Farbfeld und Namen; das Popup bietet Designfarben, Standardfarben, zuletzt benutzte Farben und ein HSV-Feld mit Hex-Eingabe. Er ersetzt `TColorBox` und den Windows-Farbdialog und folgt Preset und Dark Mode.

## Wann verwenden

- Wenn der Anwender eine einzelne Farbe einstellt, die gespeichert wird (Einstellungen, Kategorien, Hervorhebungen). Für die Wahl aus wenigen festen Bedeutungen („Rot = dringend“) ist eine `TPPGComboBox` oder `TPPGRadioGroup` mit Text klarer.
- Statt `TColorBox`: gleiche `Style`-Werte und `Selected`, aber mit Designfarben, zuletzt benutzten Farben und eigener Farbe ohne Windows-Dialog.
- Statt `TColorDialog`, wenn die Farbe direkt im Formular sichtbar bleiben soll und kein eigener Dialog aufgehen soll.
- In datengebundenen Formularen `TPPGDBColorPicker` nehmen; er speichert die Farbe als Ganzzahl im Datenfeld.

## Unterschiede und Hinweise

- Das Feld zeigt Farbfeld und Namen bzw. Hexwert (`ShowHex`).
- Das Popup hat diese Abschnitte (von oben nach unten):
  - „Keine“ und „Standard“ (`cbIncludeNone`, `cbIncludeDefault`)
  - Designfarben (Diagramm-Palette des Presets, `ShowThemeColors`)
  - Standardfarben und erweiterte Farben
  - Systemfarben
  - zuletzt benutzte Farben (`RecentColors`, im DFM gespeichert)
  - „Weitere Farben…“ (`cbCustomColor`)
- `Style` hat den Typ von `TColorBox.Style` (`cbStandardColors`, `cbExtendedColors`, `cbSystemColors`, `cbIncludeNone`, `cbIncludeDefault`, `cbCustomColor`, `cbPrettyNames`).
- „Weitere Farben…“ öffnet ein eigenes HSV-Feld (Fläche für Sättigung und Helligkeit, Farbton-Leiste) mit Hex-Eingabe, ohne Windows-`ChooseColor`. Es folgt deshalb Preset und Dark Mode.
- Tastatur:
  - Leertaste, Alt+Pfeil oder F4 öffnen.
  - Pfeile wandern im Raster.
  - Enter übernimmt, Esc verwirft.
  - Im HSV-Teil Hexwert tippen und mit Enter übernehmen.
- Farbnamen kommen aus der VCL („Red“) und sind nicht übersetzt; andere Farben erscheinen als `#RRGGBB`.
- Systemfarben bleiben in „zuletzt benutzt“ Systemfarben (sie folgen dem Windows-Design).
- `OnChange` und `OnClick` (wie `TColorBox`) feuern nur, wenn der Anwender eine andere Farbe wählt. `Selected` aus Code löst kein Ereignis aus; zum Auswählen wie durch den Anwender gibt es `SelectColor`.

## Beispiel

```pascal
PPGColorPicker1.Style := PPGColorPicker1.Style + [cbIncludeNone];
PPGColorPicker1.Selected := clNone;
```

## Verhalten (aus dem Quelltext)

TPPGColorPicker - Farbauswahl mit Palette (Phase 12d).

- Feld mit Farbfeld und Namen bzw. Hexwert; das Popup (TPPGColorPopup) nutzt die Aufklapp-Basis (PPG.Controls.DropDown) und PPG.Popup.Placement.
- Abschnitte: Designfarben (Akzent, Signalfarben, Diagramm-Palette des Presets), Standardfarben (16 + erweiterte), Systemfarben, zuletzt benutzt (RecentColors, im DFM gespeichert), "Keine"/"Standard".
- "Weitere Farben...": eigenes HSV-Feld (Saettigung/Helligkeit-Flaeche, Farbton-Leiste) mit Hex-Eingabe im Popup - kein Windows-ChooseColor, damit es dem Preset und dem Dark Mode folgt. Die Hex-Eingabe laeuft ueber die Tastatur des Felds (das Popup wird nie aktiviert).
- Style wie TColorBox.Style (TColorBoxStyle, cbStandardColors, ...), Selected: TColor, clNone/clDefault fuer "keine"/"Standard".
- Tastatur: Pfeile im Raster, Enter uebernimmt, Esc verwirft; im HSV-Teil Hex tippen, Enter uebernimmt. Screenreader: Farben als Kinder mit Namen.
- OnChange nur bei Auswahl durch den Anwender; Selected aus Code ohne.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Selected` | `TColor` | `clBlack` | Die gewählte Farbe. clNone = „Keine", clDefault = „Standard". Setzen aus Code löst kein OnChange aus. Nutzung: `Panel1.Color := PPGColorPicker1.Selected;` Praxis: Lesen Sie die Farbe beim Speichern der Einstellungen und setzen Sie sie beim Laden wieder (löst kein OnChange aus). Mit cbIncludeNone steht clNone für „keine Farbe“, z. B. eine Kategorie ohne Markierung. |
| `Style` | `TColorBoxStyle` | `[cbStandardColors, cbExtendedColors, cbCustomColor, cbPrettyNames]` | Abschnitte des Popups wie bei TColorBox: cbStandardColors (16 Grundfarben), cbExtendedColors (weitere Farben), cbSystemColors (clBtnFace usw.), cbIncludeNone („Keine"), cbIncludeDefault („Standard"), cbCustomColor (Schaltfläche „Weitere Farben …" mit HSV-Feld und Hex-Eingabe), cbPrettyNames (lesbare Namen). Nutzung: `PPGColorPicker1.Style := [cbStandardColors, cbIncludeNone, cbCustomColor];` Praxis: Für Anwender-Einstellungen [cbStandardColors, cbExtendedColors, cbCustomColor, cbPrettyNames]; cbIncludeNone, wenn „keine Farbe“ erlaubt ist, cbIncludeDefault für „wie im System“. cbSystemColors nur für Entwickler-Werkzeuge, Anwender kennen clBtnFace nicht. |
| `ShowThemeColors` | `Boolean` | `True` | True: Das Popup zeigt oben die Designfarben des Presets (Akzent, Signalfarben, Diagrammpalette), damit gewählte Farben zum Theme passen. Praxis: True lassen, wenn die gewählte Farbe in der eigenen Oberfläche erscheint (Kategorien, Markierungen): Die Designfarben passen dann zum Preset. False für Farben, die nach außen gehen, z. B. Druck- oder Diagrammfarben eines Berichts. |
| `RecentColors` | `TStrings` |  | Zuletzt benutzte Farben als Hexwerte „#RRGGBB", die neueste zuerst. Wird beim Wählen automatisch fortgeschrieben und in der DFM gespeichert; kann zum Speichern in einer Einstellung gelesen und wieder gesetzt werden. Nutzung: `Ini.WriteString('Farben', 'Zuletzt', PPGColorPicker1.RecentColors.CommaText);` Praxis: Mit CommaText in den Benutzereinstellungen sichern und beim Start zurückschreiben, damit die eigenen Firmenfarben gleich oben stehen. Mehrere Picker eines Dialogs können sich die Liste per Assign teilen. |
| `MaxRecent` | `Integer` | `8` | Wie viele zuletzt benutzte Farben gemerkt und als eigener Abschnitt gezeigt werden (0..32; 0 = kein Abschnitt). Praxis: 6 bis 8 reichen für die typischen Hausfarben; 0 schaltet den Abschnitt ab, z. B. in einem Picker, der nur eine feste Palette anbieten soll. |
| `ShowHex` | `Boolean` | `False` | True: Das Feld zeigt den Hexwert („#1E90FF") statt des Farbnamens. Praxis: Einschalten, wenn Anwender Farben mit anderen Programmen abgleichen (Webseite, Corporate Design mit „#0078D4“). Für Endanwender ohne Grafik-Hintergrund sind Namen wie „Red“ verständlicher. |
| `NoneColorColor` | `TColor` | `clBlack` | Füllung des Farbfelds für „Keine“ (clNone) im Feld und im Popup, wie TColorBox.NoneColorColor. Die Vorgabe clBlack zeigt das Feld leer mit roter Diagonale (Preset-Optik); jede andere Farbe füllt es (die Diagonale bleibt). Nutzung: `ColorPicker1.NoneColorColor := clWhite;` Praxis: Meist clBlack lassen: „Keine“ erscheint dann leer mit roter Diagonale. clWhite, wenn „keine Farbe“ in Ihrer Anwendung „weißer Hintergrund“ bedeutet. |
| `DefaultColorColor` | `TColor` | `clBlack` | Farbe, mit der das Feld „Standard" (Selected = clDefault, mit cbIncludeDefault im Style) dargestellt wird. Praxis: Mit cbIncludeDefault auf die Farbe setzen, die „Standard“ tatsächlich ergibt, z. B. clWindow für einen normalen Listenhintergrund. So sieht der Anwender, was „Standard“ bedeutet. |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Das Standard-Preset wird nicht in der DFM gespeichert. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. Praxis: Einmal für die ganze Anwendung über einen TPPGStyleManager festlegen; das Popup mit HSV-Feld folgt dann derselben Optik. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. Praxis: Den TPPGStyleManager des Formulars zuweisen, damit Feld und Popup wie die übrigen Eingabefelder aussehen und im Dark Mode mitwechseln. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. In der DFM stehen nur die Werte, die vom Preset abweichen; der Rest kommt beim Laden aus dem Preset. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` Praxis: Selten nötig; die Feldoptik kommt vom Preset. Höchstens Rounding an die übrigen Eingabefelder des Formulars angleichen. |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. Praxis: An lassen; Hover und Fokus wirken ruhiger. Mit RespectSystemSettings folgt das Feld der Windows-Einstellung. |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Ergebnis einer Prüfung: pvsNone (neutral), pvsValid (grüner Rand), pvsWarning (gelb), pvsError (rot). Die Farben kommen aus den Signal-Tokens; ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if not IstMail(Edit1.Text) then begin Edit1.ValidationState := pvsError; Edit1.ValidationHint := 'Keine gültige Adresse'; end;` Praxis: Für Prüfungen der Farbwahl, z. B. pvsWarning, wenn eine sehr dunkle Hintergrundfarbe den Text unlesbar macht, oder pvsError, wenn eine Pflichtfarbe fehlt (clNone). |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState; erscheint als Tooltip und wird vom Screenreader vorgelesen. Praxis: Zusammen mit ValidationState die Begründung als Satz: „Dunkle Farbe: schwarzer Text ist schlecht lesbar.“ Der Anwender sieht sie als Tooltip. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). Praxis: True lassen: Im Hochkontrast bekommt das Feld Systemfarben; das Farbfeld selbst zeigt weiter die gewählte Farbe. |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen (z. B. eingebettet in eigene Flächen). Praxis: bsNone, wenn der Picker in eine eigene Fläche eingebettet ist, z. B. in eine Zelle eines Einstellungs-Rasters; sonst bsSingle wie die anderen Felder. |
| `TabStop` | `Boolean` | `True` | True: Das Feld ist mit Tab erreichbar. Praxis: True lassen: Die Farbwahl ist komplett per Tastatur bedienbar (Leertaste öffnet, Pfeile wählen, Enter übernimmt). |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. Praxis: Meist alNone. alTop in schmalen Einstellungs-Spalten, in denen Feld unter Feld steht. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` Praxis: [akLeft, akTop, akRight] in Dialogen mit veränderbarer Größe; das Feld wird dann breiter und lange Namen bzw. Hexwerte haben Platz. |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). Praxis: True lassen: Die Höhe folgt der Schrift und passt zu den übrigen PPGlow-Eingabefeldern. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. Praxis: Nur für arabische oder hebräische Oberflächen ändern; am Formular setzen und über ParentBiDiMode folgen lassen. |
| `Color` | `TColor` | `clWindow` | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. Praxis: Selten nötig; der Feldhintergrund kommt aus dem Preset. Die gewählte Farbe steht in Selected, nicht in Color. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` Praxis: MinWidth = 160 sorgt dafür, dass Farbfeld und Name auch in engen Layouts lesbar bleiben. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. Praxis: Sperren, solange die Farbe keine Rolle spielt, z. B. „Eigene Farbe verwenden“ ist nicht angehakt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` Praxis: Am Formular einstellen und vererben; der Farbname im Feld nutzt diese Schrift. |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. Praxis: True lassen, damit das Feld der Leserichtung des Formulars folgt. |
| `ParentColor` | `Boolean` | `False` | True: Color wird vom Parent übernommen. Praxis: False lassen; der Feldhintergrund kommt aus dem Preset. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. Praxis: True lassen, damit das Feld die Formularschrift trägt. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). Praxis: True lassen und ShowHint einmal am Formular einschalten. |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. Praxis: Für Zusatzbefehle per Rechtsklick, z. B. „Farbe kopieren“ (Hexwert in die Zwischenablage) oder „Auf Standard zurücksetzen“. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. Praxis: Einmal am Formular einschalten statt an jedem Feld; dann bleibt ParentShowHint True. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. Praxis: Nur bei VCL-Styles wichtig: ohne seClient behält das Feld die Farben aus dem Preset. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). Praxis: In Einstellungs-Dialogen in Leserichtung vergeben: Bezeichnung, Farbfeld, nächste Zeile. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. Praxis: Ausblenden, wenn eine Farbe in der aktuellen Variante nicht einstellbar ist; vorübergehend Unpassendes besser mit Enabled sperren. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. Praxis: Nur für Touch-Geräte; zum Antippen und Wählen im Popup nicht nötig. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. Praxis: dmManual lassen, sonst startet ein Klick ein Ziehen statt das Popup zu öffnen. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). Praxis: Nur mit DragMode = dmAutomatic sichtbar; beim Farbfeld selten gebraucht. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. Praxis: Nicht nötig; PPGlow-Controls zeichnen immer flackerfrei. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. Praxis: True lassen; ohne sichtbare Wirkung. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` Praxis: Zusammen mit Align einschalten, damit untereinander ausgerichtete Felder nicht aneinanderkleben. |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. Praxis: Im Designer per Maus; im Code nur bei dynamisch erzeugten Feldern, z. B. SetBounds(X, Y, 200, 32). |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. Praxis: Wie Left: im Designer per Maus, im Code nur bei dynamisch erzeugten Feldern. |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: 180 bis 220 Pixel reichen für Farbfeld und Namen; mit ShowHex genügen 160. |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Mit AutoSize bestimmt die Schrift die Höhe; ohne AutoSize 32 Pixel wie die anderen Eingabefelder. |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. Praxis: crDefault lassen; das Feld sieht schon wie ein Auswahlfeld aus. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` Praxis: Sagen, wofür die Farbe gilt: „Hintergrund offener Rechnungen in der Liste“. Mit ShowHint am Formular anzeigen. |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. Praxis: htKeyword, wenn Ihre Hilfe Stichwörter nutzt, sonst htContext. Ohne Hilfedatei egal. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. Praxis: Wie HelpContext, aber über ein Stichwort (HelpType = htKeyword), z. B. „Farben“. |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). Praxis: Kontext-ID der Hilfeseite zur Farbeinstellung, die F1 im Feld öffnen soll. |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. Praxis: Abstände bei Align, z. B. Margins.Bottom = 8 zwischen untereinander stehenden Feldern. Wirkt nur mit AlignWithMargins. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. Praxis: Für Hinweise mit Titel, z. B. „Kategoriefarbe“ mit Erklärung, einen TPPGCustomHint zuweisen. |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. Praxis: True lassen, damit ein am Formular gesetzter CustomHint auch hier gilt. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) Praxis: Sprechend benennen, z. B. cpKategorieKunde oder cpMarkierung, statt PPGColorPicker1. |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). Praxis: Für mehrere Picker mit einem gemeinsamen OnChange: Tag = Index der Kategorie, die der Picker einfärbt. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` Praxis: Nur auf Touch-Geräten mit eigenen Gesten; zum Wählen einer Farbe nicht nötig. |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Anwender hat eine andere Farbe gewählt (Klick im Popup, Enter, HSV-Feld). Selected aus Code löst kein OnChange aus; die Auswahl derselben Farbe auch nicht. Nutzung: `procedure TForm1.PPGColorPicker1Change(Sender: TObject); begin Vorschau.Color := PPGColorPicker1.Selected; end;` Praxis: Hier übernehmen Sie die Farbe: Vorschau einfärben, Kategorie aktualisieren, Speichern-Button freigeben. Beim Laden der Einstellungen setzen Sie Selected ohne Rückkopplung. |
| `OnCloseUp` | `TNotifyEvent` `(Sender: TObject)` | Die Aufklappliste wurde geschlossen (mit oder ohne Auswahl). Praxis: Nach dem Schließen des Popups, mit oder ohne Auswahl, z. B. um eine Live-Vorschau wieder auf die gespeicherte Farbe zurückzusetzen. |
| `OnDropDown` | `TNotifyEvent` `(Sender: TObject)` | Die Aufklappliste öffnet sich gleich; hier kann sie noch befüllt werden. Praxis: Kurz vor dem Öffnen: RecentColors aus den gemeinsamen Einstellungen auffrischen, damit Farben aus anderen Fenstern oben erscheinen. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. Praxis: Für einen Hilfetext in der Statusleiste, sobald das Feld den Fokus bekommt („Farbe der Kategorie Kunde“). |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. Praxis: Guter Ort für Prüfungen, z. B. ValidationState setzen, wenn eine Pflichtfarbe noch fehlt. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` Praxis: Für eigene Kürzel am geschlossenen Feld, z. B. Entf setzt Selected := clNone. Leertaste, F4 und Alt+Pfeil öffnen das Popup schon selbst. |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. Praxis: Selten gebraucht; Hexwerte tippt der Anwender im HSV-Teil des Popups. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. Praxis: Selten gebraucht; Gegenstück zu OnKeyDown. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. Praxis: Feuert wie bei TColorBox zusammen mit OnChange bei einer Auswahl durch den Anwender. Für neue Programme OnChange nehmen; OnClick ist für übernommenen TColorBox-Code da. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. Praxis: Selten gebraucht; das Popup öffnet schon beim einfachen Klick. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. Praxis: Selten gebraucht; das Öffnen des Popups erledigt das Feld selbst. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. Praxis: Selten gebraucht; feuert bei jeder Mausbewegung über dem Feld. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. Praxis: Selten gebraucht; Gegenstück zu OnMouseDown. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. Praxis: Um beim Überfahren eine Vorschau der aktuellen Farbe an anderer Stelle hervorzuheben. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. Praxis: Gegenstück zu OnMouseEnter: die Hervorhebung wieder entfernen. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. Praxis: Selten gebraucht; Handled := True verhindert, dass das Rad den umgebenden Bereich scrollt. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. Praxis: Nur in Spezialfällen wie Werkzeugfenstern, die beim Klick nicht aktiv werden sollen. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. Praxis: Um das Kontextmenü vor dem Öffnen anzupassen, z. B. „Auf Standard zurücksetzen“ sperren, wenn schon Standard gewählt ist. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. Praxis: Wenn Farben per Drag & Drop übertragen werden, z. B. von einer Farbmuster-Leiste: hier Selected setzen. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. Praxis: Zusammen mit OnDragDrop: Accept nur für passende Quellen setzen, z. B. Source is TPPGColorPicker. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. Praxis: Beim Ziehen des Feldes ein eigenes DragObject setzen, z. B. um die Farbe auf andere Felder zu übertragen. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). Praxis: Nach dem Ziehen des Feldes (DragMode = dmAutomatic): Target = nil heißt abgebrochen. |

Tests: `PPG.Tests.Audit11C` (TAudit11CGdiTests); `PPG.Tests.Audit5d` (TVclPropsTests); `PPG.Tests.Custom` (TCustomVclPropTests); `PPG.Tests.Phase12b` (TColorPickerTests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGColorPicker.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
