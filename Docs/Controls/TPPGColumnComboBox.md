# TPPGColumnComboBox

Palette **PPGlow** - Unit `PPG.ColumnComboBox` - Basis `TPPGCustomDropDownField`

**Vorbild:** TMS TAdvMultiColumnComboBox

## Unterschiede und Hinweise

- `Columns` enthält Titel, Breite in logischen Pixeln, Ausrichtung und Sichtbarkeit. Die Zeilen kommen aus `Items`, jede Zeile mit den Zellen getrennt durch `ColumnDelimiter` (`1001|Albers|Hamburg`).
- Virtuell: `VirtualRowCount` > 0 und `OnGetCellText` liefern die Zellen. Auch 100 000 Zeilen klappen ohne Kopie auf.
- Ein Klick auf die Kopfzeile sortiert die Ansicht, ein zweiter Klick kehrt die Richtung um. Die Daten bleiben unverändert.
- `KeyColumn`/`KeyValue` liefern den Schlüssel, `DisplayColumn` den Text im Feld. Die Tippsuche arbeitet in der Anzeigespalte, offen und geschlossen.
- Geschlossen blättern die Pfeile die Auswahl (wie eine DropDownList).
- Abweichung vom Plan: Die Zeilen liegen in `Items` mit Trennzeichen statt in `ItemsEx` mit `SubItems`, weil die Einträge der Suite keine Unterspalten haben.
- Die Zeile zeichnet das Control selbst, schlank. Die Zellroutine des Grids aus Phase 13 soll das übernehmen.

## Beispiel

```pascal
PPGColumnComboBox1.Columns.Add.Title := 'Nr';
PPGColumnComboBox1.Columns.Add.Title := 'Name';
PPGColumnComboBox1.Items.Add('1001|Albers GmbH');
PPGColumnComboBox1.DisplayColumn := 1;
PPGColumnComboBox1.KeyValue := '1001';
```

## Verhalten (aus dem Quelltext)

TPPGColumnComboBox - mehrspaltige Auswahl mit Kopfzeile (Phase 12e,
Vorbild TMS TAdvMultiColumnComboBox).

- Columns (Titel, Breite in logischen px, Ausrichtung) und Zeilen aus Items: jede Zeile enthaelt die Zellen getrennt durch ColumnDelimiter ("1001|Mueller|Berlin"). Virtuell: VirtualRowCount > 0 und OnGetCellText liefern die Zellen (z.B. 100 000 Zeilen ohne Kopie).
- Kopfzeile im Popup; Klick sortiert (aufsteigend/absteigend), die Reihenfolge der Daten bleibt unveraendert (nur die Ansicht).
- KeyColumn/KeyValue fuer den Schluessel (DB-Anbindung), DisplayColumn fuer den Text im Feld. Tippsuche in der Anzeigespalte (offen und geschlossen).
- Zeichnen: schlanke eigene Zeile; die Zellroutine des Grids (TPPGCellPainter, Phase 13) soll das spaeter uebernehmen.
- OnChange nur bei Auswahl durch den Anwender; ItemIndex/KeyValue aus Code ohne Ereignis.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Columns` | [TPPGComboColumns](types/TPPGComboColumns.md) |  | Spalten der Aufklappliste (Titel, Breite, Ausrichtung, sichtbar). Die Kopfzeile im Popup sortiert per Klick die Ansicht, nicht die Daten. Nutzung: Im Designer per Doppelklick; im Code `with Combo.Columns.Add do begin Title := 'Nr.'; Width := 60; end;` |
| `Items` | `TStrings` |  | Zeilen der Liste, jede mit den Zellen getrennt durch ColumnDelimiter. Wird nicht benutzt, wenn VirtualRowCount > 0 ist. |
| `ColumnDelimiter` | `Char` | `'\|'` | Trennzeichen zwischen den Zellen einer Zeile in Items (Vorgabe senkrechter Strich). Nutzung: `Combo.ColumnDelimiter := ';'; Combo.Items.Add('1001;Müller;Berlin');` |
| `VirtualRowCount` | `Integer` | `0` | Größer 0: Die Liste hat so viele Zeilen und holt ihre Zellen aus OnGetCellText, ohne Kopie in Items (z. B. 100 000 Zeilen). |
| `KeyColumn` | `Integer` | `0` | Index der Spalte mit dem Schlüssel; KeyValue liest bzw. wählt die Zeile über diesen Wert (z. B. für die DB-Anbindung). Nutzung: `Combo.KeyColumn := 0; Combo.KeyValue := '1001';` |
| `DisplayColumn` | `Integer` | `0` | Index der Spalte, deren Text im Feld steht; in ihr sucht auch die Tippsuche. |
| `DropDownCount` | `Integer` | `10` | Sichtbare Zeilen der Aufklappliste, bevor gescrollt wird (1..100). |
| `DropDownWidth` | `Integer` | `0` | Breite der Aufklappliste in logischen Pixeln; 0 = Summe der Spaltenbreiten. |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `TextHint` | `string` |  | Platzhaltertext im leeren Feld (z. B. „Suchen …"). Nutzung: `Edit1.TextHint := 'E-Mail-Adresse';` |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Ergebnis einer Prüfung: pvsNone (neutral), pvsValid (grüner Rand), pvsWarning (gelb), pvsError (rot). Die Farben kommen aus den Signal-Tokens; ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if not IstMail(Edit1.Text) then begin Edit1.ValidationState := pvsError; Edit1.ValidationHint := 'Keine gültige Adresse'; end;` |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState; erscheint als Tooltip und wird vom Screenreader vorgelesen. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen (z. B. eingebettet in eigene Flächen). |
| `ReadOnly` | `Boolean` | `False` | True: Der Text kann gelesen, markiert und kopiert, aber nicht geändert werden. Die Optik bestimmt ReadOnlyStyle. |
| `ReadOnlyStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Eigene Optik bei ReadOnly: Fläche, Text- und Randfarbe (je auch für Dunkel). clDefault = wie im bearbeitbaren Zustand. Nutzung: `Edit1.ReadOnlyStyle.Color := $00F0F0F0; Edit1.ReadOnlyStyle.TextColor := clGrayText;` |
| `TabStop` | `Boolean` | `True` | True: Das Feld ist mit Tab erreichbar. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Color` | `TColor` | `clWindow` | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
| `ParentColor` | `Boolean` | `False` | True: Color wird vom Parent übernommen. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGetCellText` | `TPPGGetCellTextEvent` `(Sender: TObject; ACol, ARow: Integer; var Text: string)` | Virtueller Modus (VirtualRowCount > 0): liefert den Text einer Zelle. Row und Column benennen die Zelle, das Ergebnis kommt in den var-Parameter Text. Nutzung: `Text := Kunden[Row].Felder[Column];` |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Text wurde geändert (Tippen, Einfügen, Code). |
| `OnCloseUp` | `TNotifyEvent` `(Sender: TObject)` | Die Aufklappliste wurde geschlossen (mit oder ohne Auswahl). |
| `OnDropDown` | `TNotifyEvent` `(Sender: TObject)` | Die Aufklappliste öffnet sich gleich; hier kann sie noch befüllt werden. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGColumnComboBox.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
