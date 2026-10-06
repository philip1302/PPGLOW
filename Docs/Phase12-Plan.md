# Phase 12 – Detailplan: Eingabe-Erweiterungen

*Stand 05.10.2026. Teil von `Docs\Roadmap2.md`. **Vom User freigegeben am 05.10.2026 (Empfehlungen übernommen).** Setzt Phase 11 voraus (Kontextmenü der Felder, Popup-Platzierung).*

## Warum
Geschäftsanwendungen bestehen zum großen Teil aus Spezialfeldern: Telefon und IBAN mit Maske, Beträge mit Tausendertrennern, Farben, Mehrfachauswahl, Stichwörter. TMS deckt das mit TAdvEdit, TAdvMaskEdit, TAdvMoneyEdit, TAdvColorPickerDropDown, TCheckListEdit und TAdvMultiColumnComboBox ab. PPGlow hat heute Edit, SpinEdit (nur Integer), ComboBox und SearchEdit.

## Teilschritte

| Teil | Inhalt | Größe |
|---|---|---|
| 12a | Feld-Basis erweitern: gemeinsame Edit-Hilfen, Null-Zustand, Anzeige- und Bearbeitungsformat | mittel |
| 12b | `TPPGMaskEdit`, `TPPGNumberEdit` (Zahl/Währung/Prozent, ersetzt das geplante `TPPGFloatSpinEdit`), `TPPGPasswordEdit` | groß |
| 12c | `TPPGFileEdit` (Datei/Ordner, Ziehen und Ablegen) | klein |
| 12d | `TPPGColorPicker` (Palette, zuletzt benutzt, eigene Farbe mit HSV-Feld) | mittel |
| 12e | `TPPGCheckComboBox` (Mehrfachauswahl), `TPPGColumnComboBox` (mehrspaltig mit Kopf) | groß |
| 12f | `TPPGTagEdit` (Stichwörter als Chips, Vorschläge) | mittel |
| 12g | DB-Varianten: `TPPGDBMaskEdit`, `TPPGDBNumberEdit`, `TPPGDBColorPicker`, `TPPGDBCheckComboBox`, `TPPGDBTagEdit` | mittel |

## 12a – Feld-Basis

Vorhanden ist `TPPGCustomField.CreateInner: TCustomEdit` (virtuell). Neue Felder liefern damit ihr eigenes inneres Edit (OCP), etwa einen Nachfahren von `TCustomMaskEdit`.

**Gemeinsame Edit-Hilfen.** Die Farb-Behandlung von `TPPGFieldEdit` (`CN_CTLCOLOREDIT`/`STATIC`, `TextColor`) zieht in Routinen in `PPG.Controls.Field`. Jedes innere Edit ruft sie aus seinen Nachrichten-Handlern auf; Delphi hat keine Mixins, so bleibt es trotzdem eine einzige Stelle (DRY).

**`IPPGFieldValue`** (Interface, ISP) für Felder mit typisiertem Wert:
- `IsNull`, `Clear`, `ValueAsVariant`, `SetValueFromVariant`
- Damit brauchen die DB-Varianten (12g) und das Grid (Phase 13, Zell-Editoren) nur eine einzige Anbindung statt einer pro Feldtyp (DIP).

**Anzeige- und Bearbeitungsformat:**
- Ohne Fokus zeigt das Feld formatiert (`1.234,50 €`), mit Fokus roh (`1234,5`).
- Der Wechsel passiert in `FocusChanged` und nie in Paint.

## 12b – Maske, Zahl, Passwort

**`TPPGMaskEdit`** (Vorbild `TMaskEdit`):
- Inneres Edit `TPPGFieldMaskEdit = class(TCustomMaskEdit)`. Die gesamte Maskenlogik der VCL wird wiederverwendet: `EditMask`, `EditText`, `IsMasked`, `ValidateEdit`. Ein Nachbau würde nur Fehler kopieren.
- DFM wie `TMaskEdit` (C1); ungültige Eingabe beim Verlassen setzt `ValidationState` statt Exception-Dialog (wie die DB-Felder aus Phase 9).

**`TPPGNumberEdit`** (Vorbild TMS TAdvEdit `EditType`, WinUI NumberBox):
- Ein Control für Zahl, Währung und Prozent: `NumberKind = (nkInteger, nkFloat, nkCurrency, nkPercent)`.
- `Value: Double` und `AsCurrency: Currency`; Currency rechnet ohne Rundungsfehler, wichtig bei Geld (C12).
- `Decimals`, `MinValue`/`MaxValue`, `Increment`/`LargeIncrement`, optionale Spin-Buttons, Mausrad nur mit Fokus.
- `AllowNull`, `ShowThousandSeparator`, `CurrencyString` (Vorgabe aus `FormatSettings`).
- Eingabe:
  - Nur Ziffern, ein Dezimaltrenner und ein Minus.
  - Der Punkt auf dem Ziffernblock wird zum Dezimaltrenner des Gebietsschemas (häufiger Wunsch in DE).
  - Einfache Rechnung mit `+ - * /` wie im TMS-Rechnerfeld, ausgewertet bei Enter.
  - Einfügen von `1.234,50 €` oder `1,234.50` wird erkannt.
- Code setzt `Value` ohne `OnChange`; der Anwender löst es aus (Suite-Regel).
- Ersetzt den Backlog-Punkt `TPPGFloatSpinEdit`. `TPPGSpinEdit` bleibt für `TSpinEdit`-Kompatibilität.

**`TPPGPasswordEdit`** (WinUI PasswordBox):
- Zeichen per `PasswordChar` bzw. `ES_PASSWORD`.
- Knopf zum Aufdecken (nur solange gedrückt, oder umschaltbar mit `RevealMode`).
- Hinweis bei aktiver Feststelltaste (Plakette im Feld).
- Kein Kopieren, solange verdeckt (`WM_COPY` abgefangen); keine Rückgängig-Historie mit Klartext.
- Screenreader: Rolle Text mit `STATE_SYSTEM_PROTECTED`.

## 12c – TPPGFileEdit
- `Kind = (fkOpenFile, fkSaveFile, fkFolder)`, `Filter`, `InitialDir`, `DefaultExt`.
- Der Knopf öffnet `TFileOpenDialog` bzw. `TOpenDialog` als Rückfall vor Vista (XE2 auf XP).
- Ablegen aus dem Explorer über `DragAcceptFiles` (`WM_DROPFILES`).
- Optionaler Hinweis „Datei fehlt“ als `ValidationState`, wenn `MustExist`.
- Autovervollständigung von Pfaden über `SHAutoComplete` auf dem inneren Edit (kostet nichts, Anwender erwarten es).

## 12d – TPPGColorPicker
- Feld mit Farbfeld und Namen bzw. Hexwert; das Popup nutzt `TPPGPopupWindow` und `PPG.Popup.Placement`.
- **Palette:** Farben des Presets (Tokens, Diagramm-Palette), Standardfarben, Systemfarben (wie `TColorBox` `cbSystemColors`).
- Bereich „zuletzt benutzt“ (`RecentColors`, im DFM gespeichert).
- „Weitere Farben…“: eigenes HSV-Feld mit Farbton-Leiste und Hex-Eingabe im Popup, kein Windows-`ChooseColor` (stylbar, C2).
- `Style` als Teilmenge kompatibel zu `TColorBox.Style` (C1); `Selected: TColor`; `clNone`/`clDefault` als „keine/Standard“.
- Tastatur: Pfeile im Raster, Enter übernimmt, Esc verwirft. Screenreader: Tabelle mit Farbnamen.

## 12e – Mehrfach- und Spaltenauswahl

**`TPPGCheckComboBox`:**
- Popup-Liste mit Kästchen; nutzt `TPPGItemPainter` und Indikator-Renderer (keine neue Zeichenlogik).
- Text der Auswahl: `A, B, +2`, kürzen per `DisplayMode`.
- `Checked[Index]`, `CheckedCount`, `CheckedText` (getrennt durch `Delimiter`); optional „Alle auswählen“ als erster Eintrag; Suchfeld im Popup ab N Einträgen.
- Leertaste hakt an, Enter schließt; das Popup bleibt beim Anhaken offen (häufige Beschwerde bei Nachbauten).

**`TPPGColumnComboBox`:**
- `Columns` (Titel, Breite, Ausrichtung) und Zeilen aus `ItemsEx` mit `SubItems`, optional virtuell über `OnGetCellText`.
- Kopfzeile im Popup, Sortieren per Klick; `KeyColumn`/`DisplayColumn`.
- Tippsuche in der Anzeigespalte.
- Zeichnen über die Zellroutine des Grids (Phase 13 stellt `TPPGCellPainter` bereit). Bis dahin eine schlanke eigene Zeile; die Zusammenführung ist in Phase 13 eingeplant.

## 12f – TPPGTagEdit
- Chips (Plakette mit Text und ×) vor dem Eingabebereich; Umbruch über mehrere Zeilen mit `AutoSize` (Höhe).
- Eingabe beendet ein Tag mit Enter, `Delimiters` (z. B. `;` `,`) oder beim Verlassen.
- Backspace im leeren Feld markiert erst das letzte Tag und löscht es beim zweiten Druck (wie Outlook); Pfeil links/rechts bewegt sich zwischen den Chips.
- Vorschläge über `TPPGPopupList` (wie SearchEdit), `AllowNew`, `MaxTags`, `CaseSensitive`, keine Doppelten.
- Einfügen von `a; b; c` erzeugt drei Tags.
- `Tags: TStrings`, `OnTagAdding` (abbrechbar, z. B. Prüfung auf E-Mail-Format), `OnTagRemoved`, `OnTagClick`.
- Screenreader: Liste mit Einträgen, Entfernen als Standardaktion.

## 12g – DB-Varianten
- Alle über `IPPGFieldValue` (12a) und den vorhandenen `TPPGFieldDataLink` (Phase 9).
- Null wird zu `IsNull`, `ValidationState` zeigt Fehler am Feld, `Field.EditMask` wird übernommen, wenn das Feld keine eigene Maske hat.
- `TPPGDBCheckComboBox`/`TPPGDBTagEdit` speichern als getrennten Text (`Delimiter`); optional über ein Detail-Dataset (Phase 13+, nicht jetzt).

## Fallstricke
| Bereich | Fallstrick | Gegenmittel |
|---|---|---|
| Maske | `TCustomMaskEdit` wirft `EDBEditError` bei `ValidateEdit` beim Verlassen; der Dialog stört | `ValidateEdit` überschreiben: Fehler als `ValidationState`, Fokus bleibt |
| Maske | IME und Masken vertragen sich schlecht (asiatische Eingabe) | dokumentieren; mit Maske wird IME am inneren Edit abgeschaltet (wie die VCL selbst) |
| Zahl | `StrToFloat` mit Tausendertrennern und unterschiedlichen Gebietsschemas | eigener Parser mit `TFormatSettings`, Tests mit de/en/ch (Apostroph als Tausendertrenner) |
| Zahl | `Double` für Geld | `AsCurrency` und `nkCurrency` rechnen in `Currency` |
| Zahl | Formatwechsel bei Fokus verschiebt die Einfügemarke | Marke nach Ziffern-Position umrechnen |
| Passwort | Klartext im Speicher (Undo-Puffer des Edits) | `EM_EMPTYUNDOBUFFER` nach dem Aufdecken; `Clear` überschreibt den String |
| Datei | `TFileOpenDialog` fehlt unter XP | Rückfall auf `TOpenDialog` per Laufzeitprüfung (`Win32MajorVersion`) |
| Popups | Popup mit Suchfeld braucht echten Tastaturfokus | Ausnahme vom „keine Aktivierung“-Prinzip: Fokus im Popup-Edit, Schließen bei Fokusverlust (in `PPG.Popup` als eigener Modus) |
| Tags | Viele Chips: Layout bei jedem Tastendruck | Layout nur bei Änderung der Tags oder Breite, zwischengespeichert |
| DB | Null vs. 0 bei Zahlen | `AllowNull = True` ist bei DB-Feldern die Vorgabe |

## Anforderungen (Zuordnung zu Roadmap2)
- C1: DFM wie `TMaskEdit`/`TColorBox`, VCL-Maskenlogik.
- C2: eigener Farbdialog statt `ChooseColor`.
- C4: Tastatur und Screenreader je Control.
- C9: Zahlformate nach Gebietsschema, übersetzte Texte.
- C12: Currency, Fehler am Feld statt Dialog.

## Tests (`Tests\PPG.Tests.Phase12a`–`g`)
- **Maske:** VCL-Masken (Telefon, Datum, PLZ), `EditText`/`Text`, ungültig beim Verlassen, DFM von `TMaskEdit`.
- **Zahl:**
  - Parser-Tabelle (de/en/ch, Währung, Prozent, Rechnung)
  - Min/Max-Klemmen, Null, Spin und Mausrad
  - Ereignisse nur bei Anwender-Änderung; Einfügemarke nach Formatwechsel
- **Passwort:** Aufdecken, kein `WM_COPY`, Feststelltaste (simuliert).
- **ColorPicker:** Auswahl per Tastatur, `RecentColors` im DFM, HSV ↔ RGB-Rundreise.
- **CheckCombo/ColumnCombo/TagEdit:** Tastatur, Einfügen, Grenzen, Ereignisse, Barrierefreiheit.
- **DB:** Null, Maske aus dem Feld, Fehler am Feld.
- Galerie, Streaming, Leak-Lauf, Benchmark (TagEdit mit 500 Tags, ColumnCombo mit 100 000 Zeilen virtuell).

## Demo
Seite „Formular“ um die neuen Felder erweitern (Adressmaske, Betrag, Passwort, Datei, Farbe, Kategorien, Stichwörter); DB-Seite bekommt Betrag und Kategorien.

## Entscheidungen für den User
1. Ein Zahlenfeld für alles (`TPPGNumberEdit`, empfohlen) statt getrennter Float-, Money- und Percent-Edits.
2. Farbdialog als eigenes Popup (empfohlen) statt Windows-Dialog.
3. Rechnen im Zahlenfeld (`2*19,99`) einbauen? (TMS kann es; Aufwand klein.)

## Umsetzung (05.10.2026)

| Teil | Units | Ergebnis |
|---|---|---|
| 12a | `PPG.Controls.Field`: `IPPGFieldInner`, `IPPGFieldValue`, `SetTextSilent`, `AdjustInnerBounds`; Spin-Wiederholung als `TPPGSpinRepeater` (`PPG.SpinEdit`) | Tests `PPG.Tests.Phase12a` |
| 12b | `PPG.NumberFormat` (Kern: lesen, rechnen, formatieren, Einfügemarke), `PPG.NumberEdit`, `PPG.MaskEdit`, `PPG.PasswordEdit`; Feld-Symbole `fgReveal`/`fgBrowse` | Tests `PPG.Tests.Phase12a` |
| 12c | `PPG.FileEdit` | Tests `PPG.Tests.Phase12b` |
| 12d | `PPG.ColorSpace` (Kern: HSV, Hex), `PPG.Controls.DropDown` (Aufklapp-Basis), `PPG.ColorPicker` | Tests `PPG.Tests.Phase12b` |
| 12e | `PPG.RowPopup` (Zeilenliste mit Kopf/Filter/Bildlauf), `PPG.CheckComboBox`, `PPG.ColumnComboBox` | Tests `PPG.Tests.Phase12c` |
| 12f | `PPG.TagEdit` | Tests `PPG.Tests.Phase12c` |
| 12g | `PPG.DB.Fields` (`TPPGDBValueBinding` + 5 DB-Varianten, Paket `PPGlowDBR`) | Tests `PPG.Tests.Phase12d` |

**Außerdem:**
- Designer: 8 Felder auf der Palette PPGlow, 5 auf PPGlow DB, jeweils mit Symbolen. Spalten-Editor der ColumnComboBox; Feldlisten für `DataField`.
- 19 neue Texte mit deutscher Übersetzung.
- Hilfeseiten für alle 13 Komponenten; Galerien `ColorPicker.png` und `Fields12.png`.
- Demo: Karte „Spezialfelder“ auf der Seite Formular (alle neuen Felder). Auf der Datenbank-Seite zeigt ein Zahlenfeld den Umsatz, und ein TagEdit verwaltet Schlagwörter.

**QS:**
- 837 Tests grün (vorher 757); Leak-Lauf und Win64 siehe NAECHSTE-SCHRITTE.
- Demo-Selbsttest 94/94.
- Benchmarks: ColumnComboBox mit 100 000 virtuellen Zeilen klappt unter 1 s auf; TagEdit mit 500 Tags ist unter 1,5 s gelegt und gezeichnet.

**Abweichungen vom Plan:**
- **Gemeinsame Aufklapp-Basis:** `TPPGCustomDropDownField` (Capture, Tastatur, Schließen bei Fokusverlust, Barrierefreiheit) und `TPPGRowPopup` (Liste mit Kopf/Filter) sind neu. ColorPicker, CheckCombo, ColumnCombo und TagEdit bauen darauf auf. Die vorhandene ComboBox nutzt sie noch nicht; das Umstellen ist ein Folgeschritt.
- **Popup mit Suchfeld:** Das Popup braucht keinen echten Fokus. Getippte Zeichen gehen über die Tastatur des Felds in die Filterzeile bzw. die Hex-Eingabe. Damit bleibt es beim Grundsatz „Popups werden nie aktiviert“; ein eigener Fokus-Modus in `PPG.Popup` war nicht nötig.
- **ColumnComboBox:** Die Zeilen liegen in `Items` mit `ColumnDelimiter` statt in `ItemsEx` mit `SubItems` (die Einträge haben keine Unterspalten). Dazu kommt ein virtueller Modus über `OnGetCellText`.
- **CheckComboBox:** Haken wirken sofort, Esc nimmt sie nicht zurück. Die Leertaste hakt auch beim Filtern an; Leerzeichen gehen deshalb nicht in den Filter.
- **TagEdit:** Die Vorschläge kommen aus der eigenen Zeilenliste statt aus `TPPGPopupList` (gemeinsame Basis mit den anderen Feldern).
- **ColorPicker:** Farbnamen kommen aus der VCL (englisch, „Red“); andere Farben erscheinen als Hex.
- **NumberEdit:** Bei Prozent ist `Value` die angezeigte Zahl (12,5), nicht der Anteil.
- **Datei-Dialog vor Vista:** `SHBrowseForFolder` statt `SelectDirectory`, weil `Vcl.FileCtrl` dem Laufzeitpaket das Paket `vclx` abverlangen würde.

**Beim Prüfen gefunden und behoben:**
- **Breite der Felder (älterer Fehler):** Felder mit `AutoSize` übernahmen unter Umständen die per `SetBounds` gesetzte Breite nicht. `AutoSize` setzte dann wieder die vorige Breite, weil `AutoSizeWidth` nicht abgeschaltet war. Jetzt folgen Felder nur in der Höhe (wie `TEdit`). Das Referenzbild des Expanders hatte den Fehler festgehalten und ist neu erzeugt.
- **Geld rundete falsch:** Mit `Round`/`RoundTo` der RTL ergab 2,345 den Wert 2,34 (Rundung zur geraden Ziffer). Jetzt wird kaufmännisch gerundet, bei `Currency` exakt über die Ganzzahl.
- **Zeilenliste beim ersten Öffnen weggescrollt:** Vor dem ersten Zeigen kannte das Popup seine Höhe nicht.
- **DB-Maske:** Eine ungültige Maskeneingabe wurde trotzdem geschrieben, und das Schreiben löschte die Fehleranzeige.
