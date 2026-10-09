# TPPGKanban

Palette **PPGlow** - Unit `PPG.Kanban` - Basis `TPPGCustomKanban`

**Vorbild:** Trello, TMS FNC Kanban Board

## Unterschiede und Hinweise

- Spalten (`Columns`: Titel, Farbe der Kopfleiste, `WipLimit`, `Collapsed`, eigene `Width`), optional Swimlanes (`Lanes`) und Karten (`Cards`). Eine Karte gehört über `ColumnId` und `LaneId` zu einer Zelle; die Reihenfolge in der Zelle ist die Reihenfolge in der Collection.
- Karteninhalt: `Title` (höchstens zwei Zeilen), `Text` mit Markup (höchstens `MaxTextLines` Zeilen), `Labels` („Bug, UI“ als farbige Plaketten), `Due` (überfällig rot), `Assignee` (Initialen im Kreis), `Progress` (Balken, 100 = grün), `Color` (Streifen links).
- **Ohne Swimlanes** scrollt jede Spalte für sich (Mausrad über der Spalte, Daumen ziehen), das Board waagerecht. **Mit Swimlanes** scrollt das ganze Board, die Spaltenköpfe bleiben stehen; ein Klick auf den Kopf einer Swimlane klappt sie ein.
- **Virtuelle Spalten:** `Column.VirtualCount` > 0 und `OnGetCard`. Karten haben dann feste Höhe (`VirtualCardHeight`), Lage und Treffer in O(1); abgefragt wird nur Sichtbares. Verschieben meldet `OnCardMoved` mit Indizes (`Card = nil`), die Daten verschiebt die Anwendung. Zwischen virtuellen und normalen Spalten wird nicht verschoben.
- **Ziehen:** Die Karte folgt der Maus, am Ziel öffnet sich ein Platzhalter, die anderen Karten weichen animiert aus. Am Rand scrollt das Board bzw. die Spalte. Esc bricht ab. Auf einer eingeklappten Spalte landet die Karte am Ende.
- **WIP-Limit:** Die Kopfzeile zeigt „3 / 5“; voll = Warnfarbe, darüber = rot getönte Spalte. `WipMode = kwmBlock` lehnt Karten für volle Spalten ab (Umsortieren in der Spalte bleibt erlaubt). `OnCardMoving` kann jede Bewegung ablehnen.
- **Filter:** `FilterText` (Titel, Text, Labels, Person; ohne Groß-/Kleinschreibung), `FilterLabels` (Komma-Liste, ein Label genügt), `FilterAssignee` (Komma-Liste) und `OnFilterCard` wirken zusammen. Ausgeblendete Karten zeigt der Spaltenkopf als „+n“ (`ColumnHiddenCount`), Treffer im Titel sind hervorgehoben. Das WIP-Limit zählt weiter alle Karten.
- **Spalten verschieben:** Kopf ziehen (`AllowColumnDrag`, Esc bricht ab) oder Strg+Umschalt+Links/Rechts; `MoveColumn` im Code. `OnColumnMoving` kann ablehnen, `OnColumnMoved` meldet die neue Lage.
- **Tastatur:** Pfeile wandern zwischen den Karten (leere Spalten werden übersprungen), Strg+Pfeile verschieben die gewählte Karte (auch in eine leere Spalte; Strg+Oben/Unten am Rand in die nächste Swimlane), Pos1/Ende, Bild auf/ab, Enter = `OnCardOpen`.
- **Screenreader:** Bereich; Kinder sind je Spalte der Kopf („Spalte X, n Karten, Limit m“) und die Karten („Titel, Spalte X, Position Y von N, fällig …, Person, Labels“). Nach einem Verschieben steht „Verschoben nach Spalte X, Position Y von N“ vor dem Namen der fokussierten Karte (`Announcement`).
- Code setzt Werte ohne Ereignisse (`Cards`, `Collapsed`, `SelectedCard`); Anwenderaktionen lösen `OnCardMoving`/`OnCardMoved`, `OnCardClick`, `OnCardOpen` (Doppelklick, Enter), `OnChange` und `OnColumnCollapse` aus. `MoveCard` verschiebt wie der Anwender (mit Ereignissen).
- Ziehen zwischen Anwendungen (OLE) gibt es nicht.

## Anpassung

- `Styles` (`Column`, `Card`, `HotCard`, `SelectedCard`, `LaneHeader`) und `OnCustomDrawCard`.
- `SaveLayout`/`LoadLayout`: Spaltenbreiten, Reihenfolge, Filter und eingeklappte Spalten/Swimlanes (nach `Id`; ältere Layouts ohne Reihenfolge laden weiter). Drucken mit `TPPGKanbanPrinter`.

## Beispiel

```pascal
uses PPG.Kanban.Items;

var
  Todo, Doing: TPPGKanbanColumn;
begin
  Todo := PPGKanban1.Columns.AddColumn('Offen');
  Doing := PPGKanban1.Columns.AddColumn('In Arbeit', 3);   // WIP-Limit 3
  with PPGKanban1.Cards.AddCard(Todo.Id, 'Login-Seite', 'Mit <b>Passkey</b>') do
  begin
    Labels := 'Feature, UI';
    Assignee := 'Anna Berg';
    Due := Date + 3;
    Progress := 20;
  end;
  PPGKanban1.WipMode := kwmBlock;
end;
```

## Verhalten (aus dem Quelltext)

TPPGKanban - Kanban-Board (Phase 14c, Vorbild Trello / TMS FNC Kanban).

- Spalten (Titel, Farbe, WIP-Limit mit Warnfarbe, einklappbar) und Karten (Titel, Text mit Markup, Plaketten, Faelligkeit, Person als Initialen, Fortschritt, Farbstreifen). Optional Swimlanes (Zeilen).
- Ohne Swimlanes scrollt jede Spalte fuer sich (Mausrad, Daumen); das Board scrollt waagerecht. Mit Swimlanes scrollt das ganze Board, die Spaltenkoepfe bleiben stehen.
- Virtuelle Spalten (Column.VirtualCount + OnGetCard): Karten fester Hoehe, Lage in O(1), es wird nur Sichtbares abgefragt und gezeichnet.
- Ziehen innerhalb und zwischen Spalten (und Swimlanes): die Karte folgt der Maus, am Ziel oeffnet sich ein Platzhalter, die anderen Karten weichen animiert aus (gemeinsamer Animator). Am Rand scrollt das Board bzw. die Spalte. OnCardMoving (abbrechbar, z.B. WIP-Limit) und OnCardMoved; WipMode = kwmBlock lehnt Karten fuer volle Spalten ab.
- Tastatur: Pfeile zwischen Karten, Strg+Pfeile verschieben die Karte (auch in die naechste Spalte bzw. Swimlane), Enter oeffnet, Esc bricht das Ziehen ab. Der Screenreader hoert "verschoben nach Spalte X, Position Y".
- Code (Cards, Column.Collapsed, SelectedCard) loest keine Ereignisse aus.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `Columns` | [TPPGKanbanColumns](types/TPPGKanbanColumns.md) |  | Die Spalten des Boards (Collection) mit Titel, Farbe, WIP-Limit, Breite und eingeklappt. Nutzung: `Kanban1.Columns.AddColumn('In Arbeit', 3);` (Titel, WIP-Limit) |
| `Lanes` | [TPPGKanbanLanes](types/TPPGKanbanLanes.md) |  | Swimlanes (Zeilen, Collection). Ohne sichtbare Lanes gibt es eine einzige Zeile und jede Spalte scrollt für sich; mit Lanes scrollt das ganze Board senkrecht. |
| `Cards` | [TPPGKanbanCards](types/TPPGKanbanCards.md) |  | Alle Karten (Collection). Eine Karte gehört über ColumnId und LaneId zu einer Zelle; die Reihenfolge in der Zelle ist die Reihenfolge in der Collection. Nutzung: `Kanban1.Cards.AddCard(Kanban1.Columns[0].Id, 'Neue Aufgabe');` |
| `ColumnWidth` | `Integer` | `272` | Standardbreite der Spalten in logischen Pixeln (120 bis 2000); einzelne Spalten weichen über Column.Width ab. |
| `CardGap` | `Integer` | `8` | Abstand zwischen den Karten in logischen Pixeln (0 bis 64). |
| `MaxTextLines` | `Integer` | `3` | Höchstzahl der Textzeilen je Karte (0 bis 50); längerer Text wird gekürzt. 0 = Kartentext nicht anzeigen. |
| `VirtualCardHeight` | `Integer` | `0` | Feste Höhe der Karten virtueller Spalten in logischen Pixeln (0 bis 1000); 0 = aus der Schrift berechnet. |
| `AllowDrag` | `Boolean` | `True` | True: Karten lassen sich mit der Maus ziehen. Mit False bleibt das Verschieben per Tastatur (Strg+Pfeile) und Code möglich, solange ReadOnly False ist. |
| `ReadOnly` | `Boolean` | `False` | True: Karten können weder gezogen noch per Tastatur verschoben werden; Auswahl, Öffnen und Einklappen bleiben möglich. |
| `WipMode` | `TPPGKanbanWipMode` | `kwmWarn` | Verhalten bei vollem WIP-Limit: kwmWarn färbt die Spalte als Warnung, erlaubt aber das Ablegen; kwmBlock lehnt Karten für volle Spalten ab. Werte: `kwmWarn`, `kwmBlock`. |
| `ShowCardCount` | `Boolean` | `True` | True: Im Spaltenkopf steht die Zahl der Karten (mit WIP-Limit als „3 / 5"). |
| `Styles` | [TPPGKanbanStyles](types/TPPGKanbanStyles.md) |  | Bereiche des Boards einzeln gestalten: Spalten, Karten, Karte unter der Maus, gewählte Karte, Swimlane-Köpfe. Nicht gesetzte Werte kommen aus dem Preset. Nutzung: `Kanban1.Styles.Card.Color := $00FAFAFA;` |
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
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnCustomDrawCard` | `TPPGKanbanDrawCardEvent` `(Sender: TObject; Canvas: TCanvas; const Card: TPPGKanbanCardData; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean)` | Vor dem Zeichnen jeder Karte: Style (Fill, TextColor, BorderColor, FontStyle) für diese Karte ändern oder mit DefaultDraw := False selbst auf Canvas zeichnen. Card enthält die Kartendaten, State u. a. idsSelected und idsHot. Nutzung: `if (Card.Due <> 0) and (Card.Due < Date) then Style.BorderColor := clRed;` |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnCardMoving` | `TPPGKanbanMovingEvent` `(Sender: TObject; const Move: TPPGKanbanMove; var Allow: Boolean)` | Vor dem Verschieben einer Karte; Allow := False lehnt ab. Allow kommt bereits False an, wenn WipMode = kwmBlock und die Zielspalte voll ist. Nutzung: `if (Move.ToColumn.Title = 'Erledigt') and (Move.Card.Progress < 100) then Allow := False;` |
| `OnCardMoved` | `TPPGKanbanMovedEvent` `(Sender: TObject; const Move: TPPGKanbanMove)` | Eine Karte wurde verschoben (Maus oder Tastatur). Move enthält Karte, Quell- und Zielspalte bzw. -Swimlane, Positionen und ByKeyboard; die DB-Variante hat dann schon gespeichert. Nutzung: Gut für Protokoll oder Statusmeldung: `Log(Move.Card.Title + ' nach ' + Move.ToColumn.Title);` |
| `OnCardClick` | `TPPGKanbanCardEvent` `(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer; Card: TPPGKanbanCard)` | Eine Karte wurde angeklickt. Column und Index nennen ihre Lage; Card ist nil bei virtuellen Spalten. |
| `OnCardOpen` | `TPPGKanbanCardEvent` `(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer; Card: TPPGKanbanCard)` | Eine Karte soll geöffnet werden (Doppelklick oder Enter); hier z. B. einen Bearbeitungsdialog zeigen. |
| `OnGetCard` | `TPPGKanbanGetCardEvent` `(Sender: TObject; Column: TPPGKanbanColumn; Index: Integer; var Data: TPPGKanbanCardData)` | Liefert den Inhalt einer Karte virtueller Spalten (Column.VirtualCount > 0): Data für Column und Index füllen. Wird nur für sichtbare Karten aufgerufen. Nutzung: `Data.Title := Liste[Index].Name;` |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Die gewählte Karte hat sich durch den Anwender geändert (SelectedCard). |
| `OnColumnCollapse` | `TPPGKanbanColumnEvent` `(Sender: TObject; Column: TPPGKanbanColumn)` | Der Anwender hat eine Spalte über den Pfeil im Kopf ein- oder ausgeklappt (Column.Collapsed ist schon umgestellt). |
| `OnFilterCard` | `TPPGKanbanFilterEvent` `(Sender: TObject; Card: TPPGKanbanCard; var Accept: Boolean)` | Eigene Filterregel zusätzlich zu FilterText, FilterLabels und FilterAssignee: Accept := False blendet die Karte aus. Nutzung: `Accept := Card.Progress < 100; // Erledigtes ausblenden` |
| `OnColumnMoving` | `TPPGKanbanColumnMovingEvent` `(Sender: TObject; Column: TPPGKanbanColumn; NewIndex: Integer; var Allow: Boolean)` | Bevor eine Spalte verschoben wird, mit der neuen sichtbaren Position; Allow := False lehnt ab. Nutzung: `if Column.Title = 'Backlog' then Allow := False; // Backlog bleibt vorn` |
| `OnColumnMoved` | `TPPGKanbanColumnEvent` `(Sender: TObject; Column: TPPGKanbanColumn)` | Der Anwender hat eine Spalte verschoben (Ziehen, Strg+Umschalt+Pfeile oder MoveColumn); Column.Index ist schon die neue Lage. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnScroll` | `TNotifyEvent` `(Sender: TObject)` | Die Scrollposition hat sich geändert (Rad, Leiste, Tastatur oder Code). Nutzung: Z. B. um eine Positionsanzeige zu aktualisieren: `lblZeile.Caption := IntToStr(Grid.TopRow);` |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGKanban.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
