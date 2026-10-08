**Vorbild:** Trello, TMS FNC Kanban Board

## Unterschiede und Hinweise

- Spalten (`Columns`: Titel, Farbe der Kopfleiste, `WipLimit`, `Collapsed`, eigene `Width`), optional Swimlanes (`Lanes`) und Karten (`Cards`). Eine Karte gehört über `ColumnId` und `LaneId` zu einer Zelle; die Reihenfolge in der Zelle ist die Reihenfolge in der Collection.
- Karteninhalt: `Title` (höchstens zwei Zeilen), `Text` mit Markup (höchstens `MaxTextLines` Zeilen), `Labels` („Bug, UI“ als farbige Plaketten), `Due` (überfällig rot), `Assignee` (Initialen im Kreis), `Progress` (Balken, 100 = grün), `Color` (Streifen links).
- **Ohne Swimlanes** scrollt jede Spalte für sich (Mausrad über der Spalte, Daumen ziehen), das Board waagerecht. **Mit Swimlanes** scrollt das ganze Board, die Spaltenköpfe bleiben stehen; ein Klick auf den Kopf einer Swimlane klappt sie ein.
- **Virtuelle Spalten:** `Column.VirtualCount` > 0 und `OnGetCard`. Karten haben dann feste Höhe (`VirtualCardHeight`), Lage und Treffer in O(1); abgefragt wird nur Sichtbares. Verschieben meldet `OnCardMoved` mit Indizes (`Card = nil`), die Daten verschiebt die Anwendung. Zwischen virtuellen und normalen Spalten wird nicht verschoben.
- **Ziehen:** Die Karte folgt der Maus, am Ziel öffnet sich ein Platzhalter, die anderen Karten weichen animiert aus. Am Rand scrollt das Board bzw. die Spalte. Esc bricht ab. Auf einer eingeklappten Spalte landet die Karte am Ende.
- **WIP-Limit:** Die Kopfzeile zeigt „3 / 5“; voll = Warnfarbe, darüber = rot getönte Spalte. `WipMode = kwmBlock` lehnt Karten für volle Spalten ab (Umsortieren in der Spalte bleibt erlaubt). `OnCardMoving` kann jede Bewegung ablehnen.
- **Tastatur:** Pfeile wandern zwischen den Karten (leere Spalten werden übersprungen), Strg+Pfeile verschieben die gewählte Karte (auch in eine leere Spalte; Strg+Oben/Unten am Rand in die nächste Swimlane), Pos1/Ende, Bild auf/ab, Enter = `OnCardOpen`.
- **Screenreader:** Bereich; Kinder sind je Spalte der Kopf („Spalte X, n Karten, Limit m“) und die Karten („Titel, Spalte X, Position Y von N, fällig …, Person, Labels“). Nach einem Verschieben steht „Verschoben nach Spalte X, Position Y von N“ vor dem Namen der fokussierten Karte (`Announcement`).
- Code setzt Werte ohne Ereignisse (`Cards`, `Collapsed`, `SelectedCard`); Anwenderaktionen lösen `OnCardMoving`/`OnCardMoved`, `OnCardClick`, `OnCardOpen` (Doppelklick, Enter), `OnSelectionChange` und `OnColumnCollapse` aus. `MoveCard` verschiebt wie der Anwender (mit Ereignissen).
- Ziehen zwischen Anwendungen (OLE) gibt es nicht.

## Anpassung

- `KanbanStyles` (`Column`, `Card`, `HotCard`, `SelectedCard`, `LaneHeader`) und `OnCustomDrawCard`.
- `SaveLayout`/`LoadLayout`: Spaltenbreiten und eingeklappte Spalten/Swimlanes (nach `Id`). Drucken mit `TPPGKanbanPrinter`.

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
