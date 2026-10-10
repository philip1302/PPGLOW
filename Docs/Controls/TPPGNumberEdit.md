# TPPGNumberEdit

Palette **PPGlow** - Unit `PPG.NumberEdit` - Basis `TPPGCustomNumberEdit`

**Vorbild:** TMS TAdvEdit (`EditType`), WinUI NumberBox

## Wofür

Das Zahlenfeld erfasst Mengen, Preise, Prozente und Maße in einem Control. Es formatiert ohne Fokus („1.234,50 €“), lässt beim Tippen nur Zahlen zu, rechnet auf Wunsch einfache Ausdrücke aus („3*19,99“) und hält den Wert in den Grenzen `Min`/`Max`. Beträge rechnet es mit `nkCurrency` ohne Rundungsfehler.

## Wann verwenden

- Für jede Zahl, mit der gerechnet wird: Menge, Einzelpreis, Rabatt, Gewicht, Steuersatz. Für Nummern ohne Rechenbedeutung (Postleitzahl, Kundennummer, IBAN) ist `TPPGEdit` bzw. `TPPGMaskEdit` richtig.
- Statt `TPPGSpinEdit`, wenn Nachkommastellen, Währung, Prozent oder „kein Wert“ (`AllowNull`) gebraucht werden. `TPPGSpinEdit` bleibt für reine Ganzzahlen und den Umstieg von `TSpinEdit`.
- Statt `TPPGTrackBar`, wenn der genaue Wert zählt und eingetippt werden soll. Ein Schieberegler passt, wenn grob eingestellt und das Verhältnis gesehen werden soll (Lautstärke, Zoom).
- Mit `ReadOnly` auch für berechnete Ergebnisse (Summe, Steuer), damit sie genauso formatiert sind wie die Eingaben.

## Unterschiede und Hinweise

- Ein Feld für Ganzzahl, Kommazahl, Währung und Prozent (`Kind`). Es ersetzt das früher geplante `TPPGFloatSpinEdit`; `TPPGSpinEdit` bleibt für die Kompatibilität mit `TSpinEdit`.
- Ohne Fokus zeigt es das Anzeigeformat (`1.234,50 €`), mit Fokus das Bearbeitungsformat (`1234,5`). Die Einfügemarke bleibt dabei an derselben Ziffer.
- Eingabe:
  - Erlaubt sind Ziffern, Trenner und Minus. Mit `AllowExpressions` darf man auch rechnen (`2*19,99`, Klammern, Punkt vor Strich).
  - Der Punkt des Ziffernblocks wird zum Dezimaltrenner des Gebietsschemas.
  - Eingefügtes `1.234,50 €`, `1,234.50`, `CHF 1'234.50` oder `(12,50)` wird erkannt.
- Übernommen wird bei Enter, beim Verlassen, mit Pfeil/Bild auf/ab, Spin-Buttons und dem Mausrad (nur mit Fokus).
  - Ungültige Eingabe bei Enter: Fehler am Feld.
  - Ungültige Eingabe beim Verlassen: Der letzte gültige Wert kommt zurück.
  - Esc verwirft die Eingabe.
- `nkCurrency` rechnet in `Currency` (`AsCurrency`) und rundet kaufmännisch: 2,345 → 2,35. `Round` der RTL würde dagegen zur geraden Ziffer runden.
- `Min = Max` bedeutet ohne Grenze (wie `TSpinEdit`); Werte werden still begrenzt.
- `OnChange` kommt nur, wenn der Anwender den Wert ändert, also nicht je Tastendruck und nicht aus Code.
- `AllowNull`: Ein leeres Feld bedeutet „kein Wert“ (`IsNull`). In `TPPGDBNumberEdit` ist das die Vorgabe.
- Prozent: `Value` ist die angezeigte Zahl (12,5 für 12,5 %), nicht der Anteil (0,125).

## Beispiel

```pascal
PPGNumberEdit1.Kind := nkCurrency;
PPGNumberEdit1.Min := 0;
PPGNumberEdit1.Max := 100000;
PPGNumberEdit1.AsCurrency := 19.99;
```

## Verhalten (aus dem Quelltext)

TPPGNumberEdit - ein Feld fuer Ganzzahl, Kommazahl, Waehrung und Prozent
(Phase 12b; Vorbild TMS TAdvEdit EditType, WinUI NumberBox).

- Ohne Fokus zeigt das Feld formatiert ("1.234,50 EUR"), mit Fokus roh ("1234,5"). Gewechselt wird in FocusChanged (nie in Paint), die Einfuegemarke bleibt an derselben Ziffer.
- Eingabe: Ziffern, Trenner, Minus; mit AllowExpressions auch + - * / und Klammern ("2*19,99"), ausgerechnet bei Enter und beim Verlassen. Der Punkt des Ziffernblocks wird zum Dezimaltrenner des Gebietsschemas. Eingefuegtes "1.234,50 EUR" oder "1,234.50" wird erkannt (PPG.NumberFormat).
- Uebernommen wird bei Enter, beim Verlassen, mit Pfeilen, Spin-Buttons und Mausrad (nur mit Fokus). Ungueltige Eingabe: Enter zeigt den Fehler am Feld (ValidationState), Verlassen stellt den letzten gueltigen Wert wieder her. Esc verwirft die Eingabe.
- nkCurrency rechnet in Currency (AsCurrency, keine Rundungsfehler bei Geld).
- MinValue = MaxValue: keine Grenze (wie TSpinEdit); Werte werden still begrenzt.
- OnChange kommt nur, wenn der Anwender den Wert aendert (nicht bei jedem Tastendruck und nicht aus Code). Value aus Code loest nichts aus.
- AllowNull: leeres Feld = kein Wert (IsNull). IPPGFieldValue fuer DB-Felder und Grid.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `RoundedCorners` | `TPPGCorners` | `[pcTopLeft, pcTopRight, pcBottomRight, pcBottomLeft]` | Welche Ecken gerundet sind; die übrigen werden eckig. Für Button-Gruppen und Segment-Schalter: linker Button [pcTopLeft, pcBottomLeft], mittlere [], rechter [pcTopRight, pcBottomRight]. Menge aus: `pcTopLeft`, `pcTopRight`, `pcBottomRight`, `pcBottomLeft`. Nutzung: `PPGButton2.RoundedCorners := [];` Praxis: Für zusammengesetzte Eingaben, z. B. Betrag und daneben eine Währungsauswahl: das Zahlenfeld rechts eckig, die Auswahl links eckig. Einzelne Felder behalten alle vier Ecken. |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. Praxis: Die Optik einmal für die ganze Anwendung festlegen, am besten über einen TPPGStyleManager. Dann sehen Zahlenfelder, Textfelder und Buttons gleich aus. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. Praxis: Einen TPPGStyleManager aufs Formular legen und allen Feldern zuweisen. Dann wechselt ein einziger Befehl die Optik aller Controls, auch Hell/Dunkel. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` Praxis: Selten nötig, die Feldoptik kommt vom Preset. Für eine Ausnahme, z. B. ein farbig hervorgehobenes Summenfeld, Normal und Disabled anpassen. |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. Praxis: An lassen; Fokus- und Hover-Übergänge wirken ruhiger. RespectSystemSettings = True schaltet sie aus, wenn der Anwender in Windows Animationen abgeschaltet hat. |
| `Kind` | `TPPGNumberKind` | `nkFloat` | Art der Zahl: nkInteger (Ganzzahl), nkFloat (Kommazahl), nkCurrency (Geldbetrag, intern Currency ohne Rundungsfehler, mit Währungszeichen), nkPercent (Prozent; Value 12,5 wird als „12,5 %" angezeigt). Werte: `nkInteger`, `nkFloat`, `nkCurrency`, `nkPercent`. Praxis: Nach der Bedeutung wählen: nkInteger für Mengen und Stückzahlen, nkCurrency für Preise und Beträge (rechnet ohne Rundungsfehler), nkPercent für Rabatt oder Steuersatz, nkFloat für Maße und Gewichte. |
| `Decimals` | `Integer` | `2` | Nachkommastellen in der Anzeige und beim Runden (0..10; kaufmännisch gerundet). Bei nkInteger ohne Wirkung. Praxis: Nach der Fachlichkeit setzen: 2 für Geld, 1 für Rabatte in Prozent, 3 für Gewichte in kg. Bei nkInteger ohne Wirkung. |
| `Min` | `Double` |  | Kleinster erlaubter Wert; kleinere werden still begrenzt. Min = Max bedeutet keine Grenze. Nutzung: `NumberEdit1.Min := 0; NumberEdit1.Max := 100;` Praxis: Zusammen mit Max den erlaubten Bereich festlegen, z. B. Menge 1 bis 9999 oder Rabatt 0 bis 100. Werte außerhalb werden still begrenzt, eine eigene Prüfung ist dann nicht nötig. |
| `Max` | `Double` |  | Größter erlaubter Wert; größere werden still begrenzt. Min = Max bedeutet keine Grenze (wie TSpinEdit). Praxis: Obergrenze für Plausibilität, z. B. 100 bei Prozent oder ein Kreditlimit. Min = Max (beide 0) bedeutet ohne Grenze; das ist die Vorgabe. |
| `Increment` | `Double` |  | Schrittweite für Pfeil auf/ab, Mausrad und Spin-Buttons. Praxis: Schritt für Pfeiltasten, Mausrad und Spin-Buttons: 1 für Stückzahlen, 0,5 für Rabatte, 0,05 für Preise, die in 5-Cent-Schritten gehen. |
| `LargeIncrement` | `Double` |  | Schrittweite für Bild auf/ab. Praxis: Großer Schritt für Bild auf/ab, z. B. 10 bei Mengen oder 5 bei Prozent. So erreicht man große Werte schnell, ohne zu tippen. |
| `ShowSpinButtons` | `Boolean` | `False` | True: Rechts im Feld erscheinen Auf/Ab-Schaltflächen (Schritt = Increment). Praxis: Für Werte, die man meist nur um wenige Schritte ändert (Menge, Anzahl Kopien, Rabatt). Bei Beträgen, die man eintippt, weglassen, das spart Platz. |
| `ShowThousandSeparator` | `Boolean` | `True` | True: Ohne Fokus wird mit Tausendertrennzeichen angezeigt („1.234,50"). Praxis: True lassen für Beträge und Mengen ab 1.000, das liest sich sicherer. Für Kennnummern wie Jahreszahl oder Postleitzahl ausschalten, besser ist dort aber ein TPPGEdit oder TPPGMaskEdit. |
| `CurrencyString` | `string` |  | Währungszeichen bei Kind = nkCurrency; leer = Zeichen aus den Ländereinstellungen (z. B. „€"). Nutzung: `NumberEdit1.CurrencyString := 'CHF';` Praxis: Leer lassen, dann gilt das Währungszeichen aus den Windows-Einstellungen. Fest eintragen (CHF, USD), wenn ein Betrag in einer anderen Währung erfasst wird, z. B. der Einkaufspreis beim Lieferanten. |
| `AllowExpressions` | `Boolean` | `True` | True: Die Eingabe darf rechnen („2*19,99", „(100-15)/2"); ausgerechnet wird bei Enter und beim Verlassen. Praxis: True lassen bei Preisen und Mengen: Der Anwender tippt „3*19,99" oder „120/1,19" und bekommt das Ergebnis. Ausschalten, wenn nur eine reine Zahl zulässig ist, z. B. bei Importen oder Kennzahlen. |
| `AllowNull` | `Boolean` | `False` | True: Ein leeres Feld bedeutet „kein Wert" (IsNull, bei DB-Feldern Null); False: leer wird zu 0. Praxis: Einschalten, wenn „nicht angegeben" etwas anderes ist als 0, z. B. ein optionaler Meldebestand oder ein Rabatt, der erst noch verhandelt wird. Abfragen mit IsNull. |
| `Value` | `Double` |  | Der Zahlenwert. Ohne Fokus formatiert angezeigt, mit Fokus roh. Setzen aus Code löst kein OnChange aus; OnChange kommt nur bei Änderungen durch den Anwender. Nutzung: `Gesamt := NumberEdit1.Value * 1.19;` Praxis: Den Wert lesen und setzen, z. B. beim Laden eines Datensatzes. Setzen aus Code löst kein OnChange aus; für Geld besser AsCurrency, für Stückzahlen AsInteger verwenden. |
| `TextHint` | `string` |  | Platzhaltertext im leeren Feld (z. B. „Suchen …"). Nutzung: `Edit1.TextHint := 'E-Mail-Adresse';` Praxis: Nur zusammen mit AllowNull sichtbar, denn sonst steht immer eine Zahl im Feld. Erklärt, was ein leeres Feld bedeutet, z. B. „keine Warnung" oder „unbegrenzt". |
| `TextHintVisibleOnFocus` | `Boolean` | `False` | True: Der Platzhalter bleibt sichtbar, bis getippt wird; False: er verschwindet schon beim Fokus. Praxis: Einschalten, wenn der Platzhalter beim Tippen weiterhilft, z. B. „leer = unbegrenzt". Meist reicht die Vorgabe. |
| `UseSystemContextMenu` | `Boolean` | `False` | True: Rechtsklick zeigt das native Windows-Menü des Edits statt des PPGlow-Menüs (Rückgängig, Ausschneiden, Kopieren, Einfügen, Löschen, Alles markieren; übersetzt und im Preset-Stil). Praxis: False lassen: Das PPGlow-Menü passt zur Optik und ist übersetzt. Nur einschalten, wenn die Anwendung überall das Windows-Menü zeigen soll. |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Ergebnis einer Prüfung: pvsNone (neutral), pvsValid (grüner Rand), pvsWarning (gelb), pvsError (rot). Die Farben kommen aus den Signal-Tokens; ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if not IstMail(Edit1.Text) then begin Edit1.ValidationState := pvsError; Edit1.ValidationHint := 'Keine gültige Adresse'; end;` Praxis: Für fachliche Prüfungen, die über Min/Max hinausgehen: pvsWarning, wenn der Bestand unter dem Meldebestand liegt, pvsError bei einem unzulässigen Betrag. Ungültige Eingaben (z. B. Buchstaben) meldet das Feld bei Enter selbst als Fehler. |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState; erscheint als Tooltip und wird vom Screenreader vorgelesen. Praxis: Immer zusammen mit ValidationState setzen und sagen, was zu tun ist („Bestand unter Meldebestand – bitte nachbestellen"). Der Text erscheint als Tooltip und wird vorgelesen. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). Praxis: True lassen: Sehbehinderte Anwender mit Hochkontrast sehen dann klare Systemfarben. Nur für reine Vorschau-Flächen abschalten. |
| `Alignment` | `TAlignment` | `taRightJustify` | Ausrichtung des Textes im Feld (links, rechts, zentriert). Praxis: taRightJustify (Vorgabe) lassen: Zahlen untereinander lassen sich rechtsbündig am besten vergleichen. Linksbündig nur, wenn das Feld neben linksbündigen Textfeldern allein steht. |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen (z. B. eingebettet in eigene Flächen). Praxis: bsSingle für normale Formulare. bsNone, wenn das Feld in eine eigene Fläche eingebettet ist, z. B. als Eingabe in einer Tabellenzeile oder einer Kachel. |
| `ReadOnly` | `Boolean` | `False` | True: Der Text kann gelesen, markiert und kopiert, aber nicht geändert werden. Die Optik bestimmt ReadOnlyStyle. Praxis: Für berechnete Werte, die man sehen und kopieren, aber nicht ändern soll, z. B. Gesamtbetrag oder Steuer. Dazu TabStop = False, damit Tab sie überspringt. |
| `ReadOnlyStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Eigene Optik bei ReadOnly: Fläche, Text- und Randfarbe (je auch für Dunkel). clDefault = wie im bearbeitbaren Zustand. Nutzung: `Edit1.ReadOnlyStyle.Color := $00F0F0F0; Edit1.ReadOnlyStyle.TextColor := clGrayText;` Praxis: Damit berechnete Felder sich sichtbar von Eingabefeldern unterscheiden: eine leicht graue Fläche (Color) und ggf. fette Schrift (FontStyle) für die Summe. |
| `TabStop` | `Boolean` | `True` | True: Das Feld ist mit Tab erreichbar. Praxis: True für Eingabefelder. False für schreibgeschützte Ergebnisfelder, damit Tab direkt zum nächsten Eingabefeld springt. |
| `ShowClearButton` | `Boolean` | `False` | True: Ein „×"-Knopf im Feld leert den Wert (mit AllowNull „kein Wert", sonst 0). Er ist sichtbar, solange das Feld Text hat und bearbeitbar ist; wie Clear aus Code löst er kein OnChange aus. Praxis: Nur zusammen mit AllowNull sinnvoll, wenn „kein Wert" häufig gewählt wird. Achtung: Der Knopf löst kein OnChange aus; abhängige Berechnungen deshalb zusätzlich in OnExit anstoßen. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. Praxis: In Formularen meist alNone. alTop nur in schmalen Seitenleisten, in denen Beschriftung und Feld untereinander stehen. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` Praxis: Zahlenfelder brauchen selten mehr Breite: [akLeft, akTop] lassen. In rechtsbündigen Summenblöcken [akRight, akTop], damit sie beim Vergrößern rechts bleiben. |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). Praxis: True lassen: Die Höhe passt dann immer zur Schrift, auch bei hoher DPI. Die Breite stellen Sie selbst ein. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. Praxis: Nur für arabische oder hebräische Oberflächen ändern. Am Formular setzen und alle Controls über ParentBiDiMode folgen lassen. |
| `Color` | `TColor` | `clWindow` | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. Praxis: Bei PPGlow-Feldern selten nötig: Die Feldfarbe kommt aus Appearance bzw. dem Preset. Für schreibgeschützte Summen ReadOnlyStyle nehmen. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` Praxis: MinWidth hält das Feld breit genug für den größten erwarteten Betrag, z. B. 120 für „99.999,99 €", auch wenn das Formular schmaler wird. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. Praxis: Felder sperren, die gerade nicht gelten, z. B. „Rabatt" erst nach Auswahl eines Kunden. Für reine Anzeige besser ReadOnly, dann bleibt der Wert kopierbar. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` Praxis: Am Formular einstellen und über ParentFont vererben. Für eine hervorgehobene Endsumme Font.Style = [fsBold]. |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. Praxis: True lassen, damit das Feld der Leserichtung des Formulars folgt. |
| `ParentColor` | `Boolean` | `False` | True: Color wird vom Parent übernommen. Praxis: False lassen; die Feldfläche soll sich vom Hintergrund abheben. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. Praxis: True lassen, damit alle Felder die Formularschrift tragen. Ändern Sie Font, wird es automatisch False. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). Praxis: True lassen und ShowHint einmal am Formular einschalten, dann zeigen alle Felder ihre Hints und Prüfhinweise. |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. Praxis: Für Zusatzbefehle per Rechtsklick, z. B. „Letzten Preis übernehmen". Ohne eigenes Menü zeigt das Feld das Bearbeiten-Menü (Kopieren, Einfügen …). |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. Praxis: Einmal am Formular einschalten statt an jedem Feld; dann bleibt ParentShowHint True. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. Praxis: Nur bei VCL-Styles wichtig: Nehmen Sie seClient heraus, wenn das Feld seine PPGlow-Farben behalten soll. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). Praxis: So vergeben, dass Tab in Lesereihenfolge durch die Eingaben läuft, z. B. Menge, Einzelpreis, Rabatt. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. Praxis: Felder ausblenden, die für den Fall nicht gelten, z. B. „Fremdwährungsbetrag" nur bei Auslandskunden. Was nur gerade nicht geht, besser mit Enabled sperren. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. Praxis: Nur für Touch-Geräte: Gesten anhaken und in OnGesture auswerten. Für die normale Eingabe nicht nötig. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. Praxis: dmManual lassen, sonst startet jeder Klick ins Feld ein Ziehen statt die Eingabe. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). Praxis: Nur bei DragMode = dmAutomatic sichtbar; bei Eingabefeldern praktisch nie gebraucht. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. Praxis: Bei PPGlow-Controls nicht nötig, sie zeichnen immer flackerfrei. Steht nur da, damit alte Formulare ohne Fehler laden. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. Praxis: True lassen; bei PPGlow-Controls ohne sichtbare Wirkung. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` Praxis: Zusammen mit Align einschalten, damit ausgerichtete Felder nicht am Rand kleben. Die Abstände stellen Sie unter Margins ein. |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. Praxis: Position im Designer per Maus; im Code nur bei dynamisch erzeugten Feldern setzen, z. B. Ed.SetBounds(X, Y, 160, 32). |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. Praxis: Wie Left: im Designer per Maus, im Code nur bei dynamisch erzeugten Feldern. |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Nach dem größten erwarteten Wert bemessen: 80 für Mengen, 120 bis 160 für Beträge mit Währungszeichen und Spin-Buttons. |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Mit AutoSize bestimmt die Schrift die Höhe. Für einheitliche Zeilen in Formularen AutoSize lassen statt Höhen von Hand zu setzen. |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. Praxis: crDefault lassen; über dem Eingabebereich zeigt Windows ohnehin den Textcursor. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` Praxis: Für Einheit und Bereich, z. B. „Rabatt in Prozent, 0 bis 30". Bei Prüffehlern hat ValidationHint Vorrang. |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. Praxis: htKeyword, wenn Sie Stichwörter pflegen, sonst htContext mit Kontext-IDs. Ohne Hilfedatei egal. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. Praxis: Stichwort der Hilfeseite, die F1 im Feld öffnet, z. B. „Rabattstaffel" (mit HelpType = htKeyword). |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). Praxis: Kontext-ID der Hilfeseite für F1, wenn die Anwendung eine Hilfedatei mit IDs hat. |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. Praxis: Abstand zu Nachbarn bei Align, z. B. Margins.Bottom = 8 zwischen untereinander ausgerichteten Feldern. Wirkt nur mit AlignWithMargins. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. Praxis: Für Hinweise mit Titel und Symbol, z. B. eine Erklärung zur Rabattstaffel: einen TPPGCustomHint oder TBalloonHint aufs Formular legen und hier zuweisen. |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. Praxis: True lassen, damit ein am Formular gesetzter CustomHint auch hier gilt. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) Praxis: Sprechende Namen vergeben (edMenge, edEinzelpreis, edRabatt) statt PPGNumberEdit1: Berechnungen im Code werden dadurch lesbar. |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). Praxis: Für mehrere Felder mit einem gemeinsamen OnChange: Tag = Spaltennummer oder ID der Position, ausgewertet über TPPGNumberEdit(Sender).Tag. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` Praxis: Auf Touch-Geräten: Wischgesten auswerten (EventInfo.GestureID), z. B. Wischen nach oben erhöht um LargeIncrement. |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Anwender hat den Wert geändert und übernommen: Enter, Verlassen des Felds, Pfeil/Bild auf/ab, Spin-Buttons oder Mausrad. Nicht bei jedem Tastendruck und nicht, wenn Value, AsCurrency oder Clear aus Code gesetzt werden. Praxis: Hier abhängige Werte neu berechnen, z. B. Gesamtbetrag aus Menge, Preis und Rabatt. Weil es nur bei übernommenen Änderungen kommt, rechnet die Summe nicht bei jedem Tastendruck. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. Praxis: Selten gebraucht; der Klick setzt nur die Einfügemarke. Für Reaktionen auf neue Werte OnChange nehmen. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. Praxis: Um das Kontextmenü vor dem Öffnen anzupassen, z. B. „Letzten Preis übernehmen" nur anbieten, wenn es einen gibt. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. Praxis: Z. B. um einen Rechner oder eine Preishistorie zu öffnen. Ohne Handler markiert der Doppelklick die Zahl. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. Praxis: Für Hilfetexte in der Statusleiste („Menge in Stück"), sobald das Feld per Tab den Fokus bekommt. Den Wechsel ins Bearbeitungsformat macht das Feld selbst. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. Praxis: Für Prüfungen über mehrere Felder, z. B. „Rabatt nur bis 10 % ohne Freigabe". Der Wert ist hier schon übernommen und gerundet. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` Praxis: Für zusätzliche Tasten, z. B. F4 öffnet die Preisliste. Pfeile und Bild auf/ab nutzt das Feld selbst zum Hoch- und Runterzählen. |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. Praxis: Selten nötig: Das Feld lässt ohnehin nur Ziffern, Trenner, Minus und Rechenzeichen zu. Key := #0 verwirft ein weiteres Zeichen. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. Praxis: Selten gebraucht; z. B. für eine Live-Vorschau, solange getippt wird (der Wert selbst wird erst bei Enter übernommen). |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. Praxis: Selten für Eingabefelder; die normale Bedienung erledigt das Feld selbst. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. Praxis: Um beim Überfahren eine Erklärung zur Einheit in einer Statuszeile zu zeigen. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. Praxis: Gegenstück zu OnMouseEnter: die Erklärung wieder ausblenden. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. Praxis: Selten für Eingabefelder; feuert bei jeder Mausbewegung. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. Praxis: Selten für Eingabefelder; Gegenstück zu OnMouseDown. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. Praxis: Meist nicht nötig: Mit Fokus zählt das Rad selbst um Increment. Handled := True unterdrückt das, z. B. in langen scrollenden Formularen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. Praxis: Nur in Spezialfällen (Werkzeugfenster, die beim Klick nicht aktiv werden sollen); sonst nicht belegen. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. Praxis: Wenn ein Wert per Ziehen übernommen werden darf, z. B. ein Preis aus einer Preisliste: hier den Wert der Quelle in Value schreiben. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. Praxis: Zusammen mit OnDragDrop: Accept nur für passende Quellen setzen, z. B. Source is TPPGListBox. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. Praxis: Nur bei DragMode = dmAutomatic: eigenes DragObject setzen, wenn der Wert in ein anderes Feld gezogen werden soll. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). Praxis: Nach dem Ziehen: Target = nil heißt abgebrochen. |

Tests: `PPG.Tests.Audit11C` (TAudit11CGdiTests); `PPG.Tests.Audit45` (TNamingTests); `PPG.Tests.Audit5d` (TStage3Tests); `PPG.Tests.Audit7A` (TDropDownFieldTests, TWheelTests); `PPG.Tests.Phase12a` (TFieldBaseTests, TNumberEditTests, TPasswordEditTests); `PPG.Tests.Phase12c` (TFieldsGalleryTests); `PPG.Tests.Phase13a` (TGridPaintEditTests); `PPG.Tests.Phase19` (TValidatorTests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGNumberEdit.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
