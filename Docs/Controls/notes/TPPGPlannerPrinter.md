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
