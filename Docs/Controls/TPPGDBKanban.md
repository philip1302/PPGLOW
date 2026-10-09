# TPPGDBKanban

Palette **PPGlow DB** - Unit `PPG.DB.Kanban` - Basis `TPPGCustomDBKanban`

**Vorbild:** TMS FNC Kanban Board mit Datenbank-Anbindung

## Unterschiede und Hinweise

- Feldzuordnung: `KeyField` (ganze Zahl, Pflicht zum Schreiben), `ColumnField` (Wert = `Column.Key`, sonst `Column.Id`), `OrderField` (Reihenfolge), `TitleField`; optional `LaneField` (Wert = `Lane.Key` bzw. `Id`), `TextField`, `LabelsField`, `AssigneeField`, `DueField`, `ProgressField`, `ColorField`.
- Spalten und Swimlanes legt man wie beim `TPPGKanban` an; die Karten kommen aus der Datenmenge (höchstens `MaxRecords`), sortiert nach `OrderField`. Datensätze mit unbekanntem Spaltenwert erscheinen nicht.
- Nach jedem Verschieben durch den Anwender schreibt das Board Spalte (und Swimlane) der Karte und nummeriert die Karten von Quell- und Zielzelle in Zehnerschritten neu (nur geänderte Datensätze).
- Ohne `KeyField` ist das Board schreibgeschützt (Verschieben wird abgelehnt).
- Änderungen von außen laden nach `ReloadDelay` neu; die Auswahl bleibt an der Karte. `SyncRecord`: die gewählte Karte wird zum aktuellen Datensatz.

## Anpassung

- `KanbanStyles`, `OnCustomDrawCard`, `SaveLayout`/`LoadLayout` wie `TPPGKanban`.

## Beispiel

```pascal
PPGDBKanban1.Columns.AddColumn('Offen').Key := 'todo';
PPGDBKanban1.Columns.AddColumn('In Arbeit', 3).Key := 'doing';
PPGDBKanban1.Columns.AddColumn('Fertig').Key := 'done';
PPGDBKanban1.KeyField := 'ID';
PPGDBKanban1.ColumnField := 'Status';
PPGDBKanban1.OrderField := 'Reihe';
PPGDBKanban1.TitleField := 'Titel';
PPGDBKanban1.DataSource := DataSource1;
```

## Verhalten (aus dem Quelltext)

TPPGDBKanban - Kanban-Board auf einer Datenmenge (Phase 14c, Paket PPGlowDBR).

- Feldzuordnung: KeyField (ganze Zahl, Pflicht zum Schreiben), ColumnField (Wert = Column.Key, sonst Column.Id), OrderField (Reihenfolge in der Spalte), TitleField sowie optional LaneField (Wert = Lane.Key bzw. Id), TextField, LabelsField, AssigneeField, DueField, ProgressField, ColorField.
- Laden: alle Datensaetze (hoechstens MaxRecords) werden in Cards gespiegelt, sortiert nach OrderField. Bestehende Karten werden per Schluessel aktualisiert (Auswahl bleibt).
- Schreiben: nach jedem Verschieben durch den Anwender bekommt die Karte Spalte und Swimlane, die Karten von Quell- und Zielzelle werden in Zehnerschritten neu nummeriert (nur geaenderte Datensaetze).
- Ohne KeyField ist das Board schreibgeschuetzt.
- Datenaenderungen von aussen laden verzoegert neu (ReloadDelay ueber den Animator); eigenes Lesen und Schreiben loest kein Neuladen aus.
- SyncRecord: die gewaehlte Karte wird zum aktuellen Datensatz.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `DataSource` | `TDataSource` |  | Datenquelle, deren Datensätze als Karten gezeigt werden. |
| `KeyField` | `string` |  | Feld mit dem eindeutigen ganzzahligen Schlüssel. Ohne KeyField ist das Board schreibgeschützt (Verschieben wird nicht gespeichert). |
| `ColumnField` | `string` |  | Feld mit der Spalte der Karte. Der Wert wird mit Column.Key verglichen, ist Key leer, mit der Column.Id. Pflicht. Nutzung: `DBKanban1.ColumnField := 'STATUS';` und in den Spalten `Key := 'offen'` usw. |
| `LaneField` | `string` |  | Feld mit der Swimlane; Wert wird mit Lane.Key bzw. Lane.Id verglichen. Optional, nur mit Lanes. |
| `OrderField` | `string` |  | Feld für die Reihenfolge der Karten in einer Spalte (Zahl). Nach dem Verschieben nummeriert das Board die betroffenen Zellen in Zehnerschritten neu und schreibt nur geänderte Datensätze. |
| `TitleField` | `string` |  | Feld mit dem Kartentitel. Pflicht. |
| `TextField` | `string` |  | Feld mit dem Kartentext (darf Markup enthalten). Optional. |
| `LabelsField` | `string` |  | Feld mit den Plaketten, durch Komma getrennt („Bug, UI"). Optional. |
| `AssigneeField` | `string` |  | Feld mit dem Namen der zuständigen Person (Karte zeigt die Initialen). Optional. |
| `DueField` | `string` |  | Feld mit dem Fälligkeitsdatum (Datum/Zeit). Optional; überfällige Karten werden hervorgehoben. |
| `ProgressField` | `string` |  | Feld mit dem Fortschritt 0..100 (leer bzw. -1 = keine Anzeige). Optional. |
| `ColorField` | `string` |  | Feld mit der Farbe des Farbstreifens der Karte (TColor als Zahl). Optional. |
| `MaxRecords` | `Integer` | `10000` | Höchstzahl der gelesenen Datensätze (Schutz vor sehr großen Tabellen), 1 bis MaxInt; Standard 10000. |
| `ReloadDelay` | `Integer` | `100` | Verzögerung in Millisekunden (0 bis 10000), bevor nach Änderungen von außen neu geladen wird; fasst viele Änderungen zu einem Neuladen zusammen. |
| `SyncRecord` | `Boolean` | `True` | True: Die gewählte Karte wird zum aktuellen Datensatz der Datenmenge (z. B. für Detail-Felder daneben). |
| `Columns` | [TPPGKanbanColumns](types/TPPGKanbanColumns.md) |  | Die Spalten des Boards (Collection) mit Titel, Farbe, WIP-Limit, Breite und eingeklappt. Nutzung: `Kanban1.Columns.AddColumn('In Arbeit', 3);` (Titel, WIP-Limit) |
| `Lanes` | [TPPGKanbanLanes](types/TPPGKanbanLanes.md) |  | Swimlanes (Zeilen, Collection). Ohne sichtbare Lanes gibt es eine einzige Zeile und jede Spalte scrollt für sich; mit Lanes scrollt das ganze Board senkrecht. |
| `ColumnWidth` | `Integer` | `272` | Standardbreite der Spalten in logischen Pixeln (120 bis 2000); einzelne Spalten weichen über Column.Width ab. |
| `CardGap` | `Integer` | `8` | Abstand zwischen den Karten in logischen Pixeln (0 bis 64). |
| `MaxTextLines` | `Integer` | `3` | Höchstzahl der Textzeilen je Karte (0 bis 50); längerer Text wird gekürzt. 0 = Kartentext nicht anzeigen. |
| `AllowDrag` | `Boolean` | `True` | True: Karten lassen sich mit der Maus ziehen. Mit False bleibt das Verschieben per Tastatur (Strg+Pfeile) und Code möglich, solange ReadOnly False ist. |
| `ReadOnly` | `Boolean` | `False` | True: Karten können weder gezogen noch per Tastatur verschoben werden; Auswahl, Öffnen und Einklappen bleiben möglich. |
| `WipMode` | `TPPGKanbanWipMode` | `kwmWarn` | Verhalten bei vollem WIP-Limit: kwmWarn färbt die Spalte als Warnung, erlaubt aber das Ablegen; kwmBlock lehnt Karten für volle Spalten ab. Werte: `kwmWarn`, `kwmBlock`. |
| `ShowCardCount` | `Boolean` | `True` | True: Im Spaltenkopf steht die Zahl der Karten (mit WIP-Limit als „3 / 5"). |
| `Styles` | [TPPGKanbanStyles](types/TPPGKanbanStyles.md) |  | Bereiche des Boards einzeln gestalten: Spalten, Karten, Karte unter der Maus, gewählte Karte, Swimlane-Köpfe. Nicht gesetzte Werte kommen aus dem Preset. Nutzung: `Kanban1.Styles.Card.Color := $00FAFAFA;` |
| `VirtualCardHeight` | `Integer` | `0` | Feste Höhe der Karten virtueller Spalten in logischen Pixeln (0 bis 1000); 0 = aus der Schrift berechnet. |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `ScrollBarMode` | `TPPGScrollBarMode` | `sbmAuto` | Wann die Scrollleisten erscheinen: sbmAuto (bei Bedarf, als schmale Overlay-Leiste), sbmAlways (immer), sbmNever (nie; Scrollen nur per Rad, Tastatur oder Code). Werte: `sbmAuto`, `sbmAlways`, `sbmNever`. |
| `SmoothScrolling` | `Boolean` | `True` | True: Scrollen per Rad und Tastatur gleitet weich statt sprunghaft. |
| `FilterText` | `string` |  | Suchbegriff: nur Karten zeigen, deren Titel, Text, Labels oder Person ihn enthalten (ohne Groß-/Kleinschreibung); Treffer im Titel werden hervorgehoben. Ausgeblendete Karten zeigt der Spaltenkopf als „+n“, das WIP-Limit zählt weiter alle. Nutzung: `Kanban1.FilterText := SearchEdit1.Text;` |
| `FilterLabels` | `string` |  | Nur Karten mit mindestens einem dieser Labels zeigen (durch Komma getrennt); leer = alle. |
| `FilterAssignee` | `string` |  | Nur Karten dieser Personen zeigen (durch Komma getrennt, ohne Groß-/Kleinschreibung); leer = alle. Nutzung: `Kanban1.FilterAssignee := 'Anna Berg';` |
| `AllowColumnDrag` | `Boolean` | `True` | True: Spalten lassen sich am Kopf greifen und verschieben, per Tastatur mit Strg+Umschalt+Links/Rechts. False: nur MoveColumn im Code. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). |
| `TabStop` | `Boolean` | `True` | True: Das Control ist mit Tab erreichbar. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnCustomDrawCard` | `TPPGKanbanDrawCardEvent` `(Sender: TObject; Canvas: TCanvas; const Card: TPPGKanbanCardData; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean)` | Vor dem Zeichnen jeder Karte: Style (Fill, TextColor, BorderColor, FontStyle) für diese Karte ändern oder mit DefaultDraw := False selbst auf Canvas zeichnen. Card enthält die Kartendaten, State u. a. idsSelected und idsHot. Nutzung: `if (Card.Due <> 0) and (Card.Due < Date) then Style.BorderColor := clRed;` |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnScroll` | `TNotifyEvent` `(Sender: TObject)` | Die Scrollposition hat sich geändert (Rad, Leiste, Tastatur oder Code). Nutzung: Z. B. um eine Positionsanzeige zu aktualisieren: `lblZeile.Caption := IntToStr(Grid.TopRow);` |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnCardMoving` | `TPPGKanbanMovingEvent` `(Sender: TObject; const Move: TPPGKanbanMove; var Allow: Boolean)` | Vor dem Verschieben einer Karte; Allow := False lehnt ab. Allow kommt bereits False an, wenn WipMode = kwmBlock und die Zielspalte voll ist. Nutzung: `if (Move.ToColumn.Title = 'Erledigt') and (Move.Card.Progress < 100) then Allow := False;` |
| `OnCardMoved` | `TPPGKanbanMovedEvent` `(Sender: TObject; const Move: TPPGKanbanMove)` | Eine Karte wurde verschoben (Maus oder Tastatur). Move enthält Karte, Quell- und Zielspalte bzw. -Swimlane, Positionen und ByKeyboard; die DB-Variante hat dann schon gespeichert. Nutzung: Gut für Protokoll oder Statusmeldung: `Log(Move.Card.Title + ' nach ' + Move.ToColumn.Title);` |
| `OnCardClick` | `TPPGKanbanCardEvent` `(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer; Card: TPPGKanbanCard)` | Eine Karte wurde angeklickt. Column und Index nennen ihre Lage; Card ist nil bei virtuellen Spalten. |
| `OnCardOpen` | `TPPGKanbanCardEvent` `(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer; Card: TPPGKanbanCard)` | Eine Karte soll geöffnet werden (Doppelklick oder Enter); hier z. B. einen Bearbeitungsdialog zeigen. |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Die gewählte Karte hat sich durch den Anwender geändert (SelectedCard). |
| `OnColumnCollapse` | `TPPGKanbanColumnEvent` `(Sender: TObject; Column: TPPGKanbanColumn)` | Der Anwender hat eine Spalte über den Pfeil im Kopf ein- oder ausgeklappt (Column.Collapsed ist schon umgestellt). |
| `OnFilterCard` | `TPPGKanbanFilterEvent` `(Sender: TObject; Card: TPPGKanbanCard; var Accept: Boolean)` | Eigene Filterregel zusätzlich zu FilterText, FilterLabels und FilterAssignee: Accept := False blendet die Karte aus. Nutzung: `Accept := Card.Progress < 100; // Erledigtes ausblenden` |
| `OnColumnMoving` | `TPPGKanbanColumnMovingEvent` `(Sender: TObject; Column: TPPGKanbanColumn; NewIndex: Integer; var Allow: Boolean)` | Bevor eine Spalte verschoben wird, mit der neuen sichtbaren Position; Allow := False lehnt ab. Nutzung: `if Column.Title = 'Backlog' then Allow := False; // Backlog bleibt vorn` |
| `OnColumnMoved` | `TPPGKanbanColumnEvent` `(Sender: TObject; Column: TPPGKanbanColumn)` | Der Anwender hat eine Spalte verschoben (Ziehen, Strg+Umschalt+Pfeile oder MoveColumn); Column.Index ist schon die neue Lage. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBKanban.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
