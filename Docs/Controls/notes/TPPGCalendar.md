**Vorbild:** TMonthCalendar, WinUI CalendarView

## Unterschiede und Hinweise

- Monat/Jahr/Dekade mit Zoom-Animation, Wochennummern nach ISO 8601, erster Wochentag aus `FormatSettings`.
- `Date` im Code löst kein Ereignis aus.
- `AutoSize` wie bei `TMonthCalendar`: Größe für genau einen Monat bei aktueller Schrift und DPI; unabhängig von der Ansicht.

## Anpassung

- `Styles` (Kopf, Wochentage, Wochenende, Heute, Auswahl, andere Monate …) und `OnCustomDrawDay` (z. B. Feiertage fett).
