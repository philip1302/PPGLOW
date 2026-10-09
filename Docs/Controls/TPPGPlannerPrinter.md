# TPPGPlannerPrinter

Palette **PPGlow** - Unit `PPG.Planner.Print` - Basis `TPPGCustomPrinter`

**Vorbild:** TMS TPlanner.Print, Outlook „Wochenkalender drucken“

## Unterschiede und Hinweise

- Druckt einen `TPPGPlanner` (`Planner`) über denselben Weg wie der Grid-Drucker: Vorschau, „Seite einrichten“, PDF (`PrintToFile` mit „Microsoft Print to PDF“), Kopf-/Fußzeile mit Platzhaltern.
- Eine Seite je Zeitraum der Ansicht `View`: Tag, Arbeitswoche, Woche, Monat oder Agenda (7 Tage je Seite); die Zeitleiste wird als Woche gedruckt. `PrintFrom`/`PrintTo` = 0: nur die Seite um `Planner.Date`. `TakeFromPlanner` übernimmt die Ansicht des Planers.
- Gezeichnet wird mit demselben Code wie auf dem Bildschirm, in der Auflösung des Druckers, mit hellen Farben, ohne Auswahl und „Jetzt“-Linie.
- `WorkHoursOnly` (Vorgabe): das Raster zeigt nur die Arbeitszeit (`WorkStart`..`WorkEnd`) und wird so hoch, dass es die Seite füllt. Die Option steht auch im Dialog „Seite einrichten“.

## Beispiel

```pascal
PPGPlannerPrinter1.Planner := PPGPlanner1;
PPGPlannerPrinter1.Title := 'Team';
PPGPlannerPrinter1.HeaderText := '[Titel]';
PPGPlannerPrinter1.Orientation := poLandscape;
PPGPlannerPrinter1.View := pvWeek;
PPGPlannerPrinter1.PrintFrom := EncodeDate(2026, 6, 1);
PPGPlannerPrinter1.PrintTo := EncodeDate(2026, 6, 30);
PPGPlannerPrinter1.Preview;
```

## Verhalten (aus dem Quelltext)

Drucken des Terminplaners (Phase 14a) ueber den gemeinsamen Druck-Weg
(TPPGCustomPrinter: Vorschau, PDF, Seite einrichten).

- Eine Seite je Zeitraum: Tag (DayCount Tage), Arbeitswoche, Woche, Monat oder Agenda (7 Tage je Seite); die Zeitleiste wird als Woche gedruckt. PrintFrom/PrintTo = 0: nur der Zeitraum um Planner.Date.
- Gezeichnet wird mit demselben Code wie auf dem Bildschirm: ein unsichtbarer Planer in Druckeraufloesung (ScalePPI = Drucker-PPI) mit den Einstellungen und Terminen des Planers, helle Farben, ohne Auswahl und "Jetzt"-Linie. Das Raster wird so hoch, dass die Stunden auf die Seite passen (WorkHoursOnly: nur die Arbeitszeit).

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Planner` | `TPPGCustomPlanner` |  | Der zu druckende Planer (TPPGPlanner oder TPPGDBPlanner). |
| `View` | `TPPGPlannerView` | `pvWeek` | Ansicht für den Druck: eine Seite je Tag, Arbeitswoche, Woche, Monat oder Agenda (7 Tage je Seite); die Zeitleiste wird als Woche gedruckt. TakeFromPlanner übernimmt die Ansicht des Planers. Werte: `pvDay`, `pvWorkWeek`, `pvWeek`, `pvMonth`, `pvTimeline`, `pvAgenda`. |
| `PrintFrom` | `TDate` |  | Erster Tag des Druckzeitraums; 0 = nur die Seite um Planner.Date. Nutzung: `Prn.PrintFrom := EncodeDate(2026, 6, 1); Prn.PrintTo := EncodeDate(2026, 6, 30);` |
| `PrintTo` | `TDate` |  | Letzter Tag des Druckzeitraums; zusammen mit PrintFrom entsteht eine Seite je Zeitraum der Ansicht. |
| `WorkHoursOnly` | `Boolean` | `True` | True: Das Raster zeigt nur die Arbeitszeit (WorkStart bis WorkEnd) und füllt damit die Seite. Auch im Dialog „Seite einrichten" umschaltbar. |
| `Title` | `string` |  | Titel des Druckauftrags (erscheint in der Druckerwarteschlange) und Wert des Platzhalters [Titel]. |
| `HeaderText` | `string` |  | Kopfzeile jeder Seite (fett) mit denselben Platzhaltern wie FooterText; leer = keine Kopfzeile. Nutzung: `PPGGridPrinter1.HeaderText := '[Titel] - Stand [Datum]';` |
| `FooterText` | `string` |  | Fußzeile jeder Seite mit Platzhaltern [Seite], [Seiten], [Datum], [Titel] (auch englisch [Page], [Pages], [Date], [Title]). Leer = keine Fußzeile; Vorgabe „Seite [Seite] von [Seiten]" in der Sprache der Anwendung. |
| `Orientation` | `TPrinterOrientation` | `poPortrait` | Hochformat (poPortrait) oder Querformat (poLandscape). |
| `Margins` | [TPPGPrintMargins](types/TPPGPrintMargins.md) |  | Seitenränder in Millimetern (Left, Top, Right, Bottom; je 15 mm vorgegeben). Auch im Dialog „Seite einrichten" änderbar. |
| `PrinterName` | `string` |  | Name des Druckers; leer = Standarddrucker. Für PDF z. B. „Microsoft Print to PDF" mit PrintToFile. Nutzung: `PPGGridPrinter1.PrintToFile('Microsoft Print to PDF', 'C:\Export\Liste.pdf');` |

Tests: `PPG.Tests.Audit11C` (TAudit11CBehaviourTests); `PPG.Tests.Phase14aPlanner` (TPlannerTests); `PPG.Tests.Streaming` (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGPlannerPrinter.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
