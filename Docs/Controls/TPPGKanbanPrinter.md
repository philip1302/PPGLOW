# TPPGKanbanPrinter

Palette **PPGlow** - Unit `PPG.Kanban.Print` - Basis `TPPGCustomPrinter`

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

## Verhalten (aus dem Quelltext)

Drucken des Kanban-Boards ueber den gemeinsamen Druck-Weg
(TPPGCustomPrinter: Vorschau, PDF, Seite einrichten).

- Gezeichnet wird mit demselben Code wie auf dem Bildschirm: ein unsichtbares Board in Druckeraufloesung (ScalePPI = Drucker-PPI) mit den Spalten, Swimlanes, Karten, Stilen und Ereignissen des Boards, helle Farben, ohne Auswahl und Hover. Das Board wird so hoch, dass alle Karten ohne Scrollen Platz haben.
- FitToPageWidth: alle Spalten auf die Seitenbreite verkleinern (kleinere Aufloesung); sonst werden zu breite Boards auf mehrere Seiten nebeneinander verteilt. Zu hohe Boards gehen auf Folgeseiten weiter.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Kanban` | `TPPGCustomKanban` |  | Das zu druckende Board (TPPGKanban oder TPPGDBKanban). Nutzung: `PPGKanbanPrinter1.Kanban := PPGKanban1; PPGKanbanPrinter1.Preview;` |
| `FitToPageWidth` | `Boolean` | `True` | True: Alle Spalten werden auf die Seitenbreite verkleinert. False: zu breite Boards gehen auf Seiten nebeneinander weiter. Auch im Dialog „Seite einrichten" umschaltbar. |
| `Title` | `string` |  | Titel des Druckauftrags (erscheint in der Druckerwarteschlange) und Wert des Platzhalters [Titel]. |
| `HeaderText` | `string` |  | Kopfzeile jeder Seite (fett) mit denselben Platzhaltern wie FooterText; leer = keine Kopfzeile. Nutzung: `PPGGridPrinter1.HeaderText := '[Titel] - Stand [Datum]';` |
| `FooterText` | `string` |  | Fußzeile jeder Seite mit Platzhaltern [Seite], [Seiten], [Datum], [Titel] (auch englisch [Page], [Pages], [Date], [Title]). Leer = keine Fußzeile; Vorgabe „Seite [Seite] von [Seiten]" in der Sprache der Anwendung. |
| `Orientation` | `TPrinterOrientation` | `poPortrait` | Hochformat (poPortrait) oder Querformat (poLandscape). |
| `Margins` | [TPPGPrintMargins](types/TPPGPrintMargins.md) |  | Seitenränder in Millimetern (Left, Top, Right, Bottom; je 15 mm vorgegeben). Auch im Dialog „Seite einrichten" änderbar. |
| `PrinterName` | `string` |  | Name des Druckers; leer = Standarddrucker. Für PDF z. B. „Microsoft Print to PDF" mit PrintToFile. Nutzung: `PPGGridPrinter1.PrintToFile('Microsoft Print to PDF', 'C:\Export\Liste.pdf');` |

Tests: `PPG.Tests.Custom` (TCustomRestTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGKanbanPrinter.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
