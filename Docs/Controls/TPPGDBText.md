# TPPGDBText

Palette **PPGlow DB** - Unit `PPG.DB.Controls` - Basis `TPPGLabel`

Ersatz fuer TDBText: zeigt Field.DisplayText, nur lesend, folgt dem Datensatz. Mehrwert gegenueber TDBText: Farben des Themes (Dark Mode, Hochkontrast, Secondary, Markup wie TPPGLabel), NullText fuer leere Felder und DisplayFormat zum Formatieren von Zahlen und Datumsfeldern.

**Vorbild:** TDBText

## Wofür

Zeigt den Wert eines Datenfelds als Beschriftung an, schreibgeschützt und dem Datensatz folgend (Namen, Summen, Status in einer Kopfzeile).

## Wann verwenden

- Für Formulare, die bisher `TDBText` benutzen: Der DFM-Tausch ist 1:1 (`DataSource`, `DataField`, `Alignment`, `Layout`, `WordWrap`, `Transparent`, `Font` …).
- Wenn der Text bei leerem Feld einen Platzhalter zeigen soll (`NullText`) oder Zahlen/Datum ohne Feld-`DisplayFormat` formatiert werden sollen (`DisplayFormat`).

## Unterschiede und Hinweise

- Erbt von `TPPGLabel`: Textfarbe folgt dem Dark Mode, `Secondary` und `AllowMarkup` stehen zur Verfügung.
- Angezeigt wird `Field.DisplayText` (also auch `OnGetText` und `DisplayFormat` des Feldes); ist `DisplayFormat` am Control gesetzt, gilt es für Zahlen- und Datumsfelder (`FormatFloat` bzw. `FormatDateTime`).
- `Caption` wird nicht gespeichert. Wie bei `TDBText` ist `AutoSize` aus und `ShowAccelChar` aus.
- Ohne Datenquelle oder bei geschlossener Datenmenge bleibt der Text leer (im Designer steht der Name des Controls da).

## Beispiel

```pascal
DBText1.DataSource := DataSource1;
DBText1.DataField := 'Umsatz';
DBText1.DisplayFormat := '#,##0.00';
DBText1.NullText := '-';
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
| `DataField` | `string` |  | Name des Felds der Datenmenge, dessen Text (Field.DisplayText) angezeigt wird. |
| `DataSource` | `TDataSource` |  | Datenquelle mit der Datenmenge, aus der DataField kommt. |
| `NullText` | `string` |  | Text, wenn das Feld leer (Null) ist. Leer = nichts anzeigen. Nutzung: `DBText1.NullText := '-';` Praxis: Zeigt in Detailansichten „-“ oder „keine Angabe“ statt einer leeren Fläche. |
| `DisplayFormat` | `string` |  | Format für Zahlen- und Datumsfelder (FormatFloat bzw. FormatDateTime). Leer = DisplayText des Felds. Nutzung: `DBText1.DisplayFormat := '#,##0.00';` Praxis: Für Summen und Datumsangaben, ohne jedes Feld der Datenmenge einzeln zu formatieren. |
| `AllowMarkup` | `Boolean` | `False` | True: Caption darf Mini-Markup enthalten (fett, kursiv, Farbe, Bilder). Links werden nur dargestellt; klickbare Links bietet TPPGLinkLabel. Nutzung: `Label1.AllowMarkup := True; Label1.Caption := 'Summe: <b>42,00 €</b>';` |
| `Secondary` | `Boolean` | `False` | True: dezente Textfarbe (TextSecondary aus dem Theme), z. B. für Hinweise und Beschreibungen; folgt dem Dark Mode. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus zeichnet das Label Text und Links in den Systemfarben (wie alle PPGlow-Controls). |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Caption` | `TCaption` |  | Beschriftung. Ein & vor einem Buchstaben macht ihn zur Zugriffstaste (Alt+Buchstabe). Nutzung: `Button1.Caption := '&Speichern';` |
| `AutoSize` | `Boolean` | `False` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). |
| `ShowAccelChar` |  | `False` | True: & in der Beschriftung markiert die Zugriffstaste; False: & wird als Zeichen angezeigt. |
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Alignment` |  |  | Ausrichtung des Textes (links, zentriert, rechts). |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |
| `DragKind` | `TDragKind` |  | dkDrag = Drag & Drop, dkDock = Andocken beim Ziehen. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `EllipsisPosition` |  |  | Wo zu langer Text mit „…" gekürzt wird (epNone, epPathEllipsis, epEndEllipsis, epWordEllipsis). |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `FocusControl` |  |  | Control, das den Fokus erhält, wenn die Zugriffstaste der Beschriftung gedrückt wird. Nutzung: `Label1.Caption := '&Name:'; Label1.FocusControl := Edit1;` |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `Transparent` |  |  | True: Der Hintergrund wird nicht gefüllt, der Parent scheint durch. |
| `Layout` |  |  | Senkrechte Lage des Textes (tlTop, tlCenter, tlBottom). |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |
| `WordWrap` |  |  | True: Langer Text wird umgebrochen. |
| `Action` | `TBasicAction` |  | Verknüpft das Control mit einer Action (TActionList/TActionManager). Beschriftung, Hint, Bild, Enabled, Checked und OnClick kommen dann aus der Action. Nutzung: `Button1.Action := actSpeichern;` |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |

Tests: `PPG.Tests.Audit5d`; `PPG.Tests.Inventur` (TDBTextTests); `PPG.Tests.Streaming` (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBText.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
