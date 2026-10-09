**Vorbild:** TMS TPlanner / TDBPlanner, Outlook-Kalender

## Unterschiede und Hinweise

- Ansichten über `View`: Tag (`DayCount` Tage), Arbeitswoche (`WorkDays`), Woche, Monat (6 Wochen), Zeitleiste (waagerecht, Zeilen = `Resources`) und Agenda (`AgendaDays` Tage als Liste).
- Termine liegen in `Appointments` (im DFM) oder kommen aus einer eigenen `IPPGAppointmentSource` (`Source`). Abgefragt wird nur der sichtbare Zeitraum. Wiederholungen (`Recurrence`, RRULE nach RFC 5545) werden nur für diesen Zeitraum aufgelöst.
- **Zeiten:** gespeichert in UTC (`TimeZoneMode = tzmUtc`, Vorgabe) bzw. Ortszeit; angezeigt in `TimeZone` ('' = Zone des Rechners, sonst Windows- oder IANA-Name, z. B. `Europe/Berlin`). `Start`/`Finish` eines Termins sind Anzeige-Zeit, `StartTime`/`FinishTime` die gespeicherte Zeit.
- Das Raster ist die Wanduhr: Am Tag der Sommerzeit-Umstellung hat jede Spalte 24 Stunden (wie Outlook).
- Ganztägige und mehrtägige Termine stehen im Band über dem Raster. Termine über Mitternacht werden auf die Tage geteilt und bekommen Fortsetzungsmarken.
- `Resources` + `GroupByResource`: Spaltengruppen je Person/Raum (Tages- und Wochenansichten) bzw. Zeilen der Zeitleiste. Die Farbe kommt aus `Category` (Diagramm-Palette), sonst aus `Resource.Color`, sonst aus dem Akzent; `OnGetAppointmentColor` überschreibt.
- Bedienung: Ziehen verschiebt (Strg kopiert), die Kante ändert die Dauer. Alles rastet an `SlotMinutes`. Ziehen auf freier Fläche wählt Zeitfelder; Doppelklick, Enter oder Tippen legt einen Termin an und öffnet die Bearbeitung des Betreffs (Esc verwirft einen neuen, leeren Termin).
- **Serien:** Wird ein Vorkommen geändert (Ziehen, Dauer, Betreff, Ort, Dialog, Löschen), fragt der Planer wie Outlook „nur dieses Vorkommen“ oder „ganze Serie“ (`SeriesEditMode = semAsk`, Vorgabe; `semOccurrence`/`semSeries` fragen nicht). `OnSeriesEdit` ersetzt die Abfrage. Nur das Vorkommen: es wird herausgelöst (`RecurrenceParent`), die Serie bekommt eine Ausnahme. Ganze Serie: Verschieben verschiebt die Serie samt Wochentagen, vorhandene Ausnahmen bleiben. Ohne sichtbares Fenster wird nicht gefragt (wie `semOccurrence`).
- **Termin-Dialog:** Ohne `OnAppointmentOpen` öffnen Doppelklick und Enter den eingebauten Dialog (`DefaultEditor`, Unit `PPG.Planner.Dialog`: Betreff, Ort, Beginn/Ende, ganztägig, Person, Kategorie, Wiederholung, Notiz; Prüfung über `TPPGValidator`). `EditAppointment` öffnet ihn im Code, `PPGAppointmentDialogHook` ersetzt ihn durch einen eigenen.
- Ereignisse: `OnAppointmentChanging` (abbrechbar, neue Werte änderbar), `OnAppointmentChange`, `OnAppointmentCreated`, `OnCreateAppointment` (abbrechbar), `OnDeleting`, `OnAppointmentOpen`, `OnSeriesEdit`, `OnChange`, `OnRangeChange`. Zuweisungen im Code (`Date := ...`) lösen nur `OnRangeChange` aus.
- Tastatur: Pfeile wandern durch die Felder (Umschalt erweitert), Tab durch die Termine, Strg+Pfeile verschieben den gewählten Termin, Strg+Umschalt+Oben/Unten ändern die Dauer, Enter öffnet bzw. legt an, F2 bearbeitet den Betreff, Umschalt+F2 den Ort, Entf löscht, Bild auf/ab blättert, Pos1 springt zu heute.
- `Calendar`: ein verbundener `TPPGCalendar` zeigt Tage mit Terminen fett, seine Auswahl stellt den Zeitraum ein.
- „Jetzt“-Linie (`ShowNowLine`) über den gemeinsamen Animator, ohne eigenen Timer.
- Drucken über `TPPGPlannerPrinter`, iCalendar über `PPGSaveICal`/`PPGLoadICal` (Unit `PPG.Planner.ICal`).
- Screenreader: Tabelle, Kinder sind die sichtbaren Termine („Betreff, Beginn bis Ende, Ort“). RTL gespiegelt.

## Anpassung

- `Categories` (Name, Farbe; `Category` des Termins ist der Index), `Styles` und `OnCustomDrawAppointment`.
- `SaveLayout`/`LoadLayout`: Ansicht, Tage, Raster und Gruppierung.

## Beispiel

```pascal
uses PPG.Planner.Model, PPG.Planner.ICal;

PPGPlanner1.TimeZone := 'Europe/Berlin';
PPGPlanner1.Resources.AddResource(1, 'Anna');
with PPGPlanner1.Appointments.AddAppointment(EncodeDateTime(2026, 6, 1, 9, 0, 0, 0),
  EncodeDateTime(2026, 6, 1, 9, 15, 0, 0), 'Standup') do
begin
  Recurrence := 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
  ResourceId := 1;
end;
PPGPlanner1.Calendar := PPGCalendar1;
PPGSaveICal(PPGPlanner1.Appointments, 'Team.ics', 'Team');
```
