**Vorbild:** TPPGPlannerPrinter, Trello „Board drucken“

## Unterschiede und Hinweise

- Druckt ein `TPPGKanban` bzw. `TPPGDBKanban` (`Kanban`) über denselben Weg wie Grid- und Planer-Drucker: Vorschau, „Seite einrichten“, PDF (`PrintToFile` mit „Microsoft Print to PDF“), Kopf-/Fußzeile mit Platzhaltern.
- Gezeichnet wird mit demselben Code wie auf dem Bildschirm, in der Auflösung des Druckers, mit hellen Farben, ohne Auswahl und Hover. Spalten, Swimlanes, Karten, `Styles`, `OnCustomDrawCard` und `OnGetCard` werden übernommen; eingeklappte Spalten bleiben eingeklappt.
- `FitToPageWidth` (Vorgabe, auch im Dialog „Seite einrichten“): alle Spalten auf die Seitenbreite verkleinern. Sonst gehen zu breite Boards auf Seiten nebeneinander weiter (Reihenfolge: erst nebeneinander, dann untereinander).
- Das Board wird so hoch gedruckt, wie die längste Spalte bzw. alle Swimlanes es brauchen; zu hohe Boards gehen auf Folgeseiten weiter. Karten an der Seitengrenze werden dabei geteilt.

## Beispiel

```pascal
PPGKanbanPrinter1.Kanban := PPGKanban1;
PPGKanbanPrinter1.HeaderText := '[Titel] - [Datum]';
PPGKanbanPrinter1.Title := 'Sprint 12';
PPGKanbanPrinter1.Orientation := poLandscape;
PPGKanbanPrinter1.Preview;
```
