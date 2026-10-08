# TPPGPlanner

Palette **PPGlow** - Unit `PPG.Planner` - Basis `TPPGCustomPlanner`

**Vorbild:** TMS TPlanner / TDBPlanner, Outlook-Kalender

## Unterschiede und Hinweise

- Ansichten über `View`: Tag (`DayCount` Tage), Arbeitswoche (`WorkDays`), Woche, Monat (6 Wochen), Zeitleiste (waagerecht, Zeilen = `Resources`) und Agenda (`AgendaDays` Tage als Liste).
- Termine liegen in `Appointments` (im DFM) oder kommen aus einer eigenen `IPPGAppointmentSource` (`Source`). Abgefragt wird nur der sichtbare Zeitraum. Wiederholungen (`Recurrence`, RRULE nach RFC 5545) werden nur für diesen Zeitraum aufgelöst.
- **Zeiten:** gespeichert in UTC (`TimeZoneMode = tzmUtc`, Vorgabe) bzw. Ortszeit; angezeigt in `TimeZone` ('' = Zone des Rechners, sonst Windows- oder IANA-Name, z. B. `Europe/Berlin`). `Start`/`Finish` eines Termins sind Anzeige-Zeit, `StartTime`/`FinishTime` die gespeicherte Zeit.
- Das Raster ist die Wanduhr: Am Tag der Sommerzeit-Umstellung hat jede Spalte 24 Stunden (wie Outlook).
- Ganztägige und mehrtägige Termine stehen im Band über dem Raster. Termine über Mitternacht werden auf die Tage geteilt und bekommen Fortsetzungsmarken.
- `Resources` + `GroupByResource`: Spaltengruppen je Person/Raum (Tages- und Wochenansichten) bzw. Zeilen der Zeitleiste. Die Farbe kommt aus `Category` (Diagramm-Palette), sonst aus `Resource.Color`, sonst aus dem Akzent; `OnGetAppointmentColor` überschreibt.
- Bedienung: Ziehen verschiebt (Strg kopiert), die Kante ändert die Dauer. Alles rastet an `SlotMinutes`. Ein Vorkommen einer Serie wird beim Ändern herausgelöst (`RecurrenceParent`), die Serie bekommt eine Ausnahme. Ziehen auf freier Fläche wählt Zeitfelder; Doppelklick, Enter oder Tippen legt einen Termin an und öffnet die Bearbeitung des Betreffs (Esc verwirft einen neuen, leeren Termin).
- Ereignisse: `OnAppointmentChanging` (abbrechbar, neue Werte änderbar), `OnAppointmentChanged`, `OnAppointmentCreated`, `OnCreateAppointment` (abbrechbar), `OnDeleting`, `OnAppointmentOpen`, `OnSelectionChange`, `OnRangeChange`. Zuweisungen im Code (`Date := ...`) lösen nur `OnRangeChange` aus.
- Tastatur: Pfeile wandern durch die Felder (Umschalt erweitert), Tab durch die Termine, Strg+Pfeile verschieben den gewählten Termin, Strg+Umschalt+Oben/Unten ändern die Dauer, Enter öffnet bzw. legt an, F2 bearbeitet den Betreff, Entf löscht, Bild auf/ab blättert, Pos1 springt zu heute.
- `Calendar`: ein verbundener `TPPGCalendar` zeigt Tage mit Terminen fett, seine Auswahl stellt den Zeitraum ein.
- „Jetzt“-Linie (`ShowNowLine`) über den gemeinsamen Animator, ohne eigenen Timer.
- Drucken über `TPPGPlannerPrinter`, iCalendar über `PPGSaveICal`/`PPGLoadICal` (Unit `PPG.Planner.ICal`).
- Screenreader: Tabelle, Kinder sind die sichtbaren Termine („Betreff, Beginn bis Ende, Ort“). RTL gespiegelt.

## Anpassung

- `Categories` (Name, Farbe; `Category` des Termins ist der Index), `PlannerStyles` und `OnCustomDrawAppointment`.
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

## Verhalten (aus dem Quelltext)

TPPGPlanner - Terminplaner (Phase 14a).

- Ansichten: Tag (DayCount Tage), Arbeitswoche (WorkDays), Woche, Monat (6 Wochen), Zeitleiste (waagerecht, Zeilen = Ressourcen) und Agenda (Liste nach Tagen).
- Termine kommen aus Appointments (Collection, im DFM) oder einer eigenen IPPGAppointmentSource (Source); abgefragt wird nur der sichtbare Zeitraum.
- Zeiten: Anzeige in der Zone TimeZone ('' = Rechner), gespeichert nach TimeZoneMode (Vorgabe UTC). Das Zeitraster ist die Wanduhr: am Tag der Sommerzeit-Umstellung hat jede Spalte 24 Felder (wie Outlook); ein Termin 02:00-04:00 Ortszeit belegt zwei Stunden, dauert aber nur eine.
- Ganztaegige und mehrtaegige Termine (Dauer >= 1 Tag) liegen im Band ueber dem Raster; Termine ueber Mitternacht werden auf die Tage geteilt und bekommen Fortsetzungsmarken.
- Ressourcen (Resources) werden als Spaltengruppen (GroupByResource) bzw. als Zeilen der Zeitleiste gezeigt.
- Bedienung: Ziehen verschiebt (Strg kopiert), die Kanten aendern die Dauer, alles rastet am Raster (SlotMinutes). Ziehen auf freier Flaeche waehlt Zeitfelder; Doppelklick, Enter oder Tippen legt einen Termin an (OnCreateAppointment, abbrechbar) und oeffnet die Bearbeitung des Betreffs. Vorkommen einer Serie werden beim Aendern herausgeloest.
- Ereignisse: OnAppointmentChanging (abbrechbar, Werte aenderbar), OnAppointmentChanged, OnAppointmentCreated, OnDeleting, OnAppointmentOpen, OnSelectionChange, OnRangeChange. Code (Date := ...) loest nur OnRangeChange aus (die DB-Variante laedt darueber nach).
- Tastatur: Pfeile wandern durch die Zeitfelder (Umschalt erweitert), Tab durch die Termine, Strg+Pfeile verschieben den gewaehlten Termin, Strg+Umschalt+Oben/Unten aendern die Dauer, Enter oeffnet bzw. legt an, F2 bearbeitet den Betreff, Entf loescht, Bild auf/ab blaettert, Pos1 springt zu heute.
- "Jetzt"-Linie ueber den Animator (Schleife, neu gezeichnet nur bei einer neuen Minute), kein eigener Timer.
- Calendar: verbundener TPPGCalendar zeigt Tage mit Terminen fett, seine Auswahl stellt den Zeitraum ein.
- Screenreader: Tabelle, Kinder sind die sichtbaren Termine ("Betreff, Beginn bis Ende, Ort"). RTL gespiegelt.

## PPGlow-Eigenschaften

`Appointments`, `Resources`, `Categories`, `PlannerStyles`, `View`, `Date`, `DayCount`, `FirstDayOfWeek`, `WorkDays`, `WorkStart`, `WorkEnd`, `DayStartHour`, `DayEndHour`, `SlotMinutes`, `SlotHeight`, `SlotWidth`, `TimelineDays`, `AgendaDays`, `GroupByResource`, `ShowNowLine`, `ReadOnly`, `TimeZone`, `TimeZoneMode`, `Calendar`, `Preset`, `StyleManager`, `Appearance`, `Animation`, `HighContrastSupport`, `ScrollBarMode`, `SmoothScrolling`, `Align`, `Anchors`, `BiDiMode`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `TabOrder`, `TabStop`, `Visible`, `Touch`

## Ereignisse

`OnGesture`, `OnAppointmentChanging`, `OnAppointmentChanged`, `OnAppointmentCreated`, `OnAppointmentOpen`, `OnDeleting`, `OnCreateAppointment`, `OnGetAppointmentColor`, `OnCustomDrawAppointment`, `OnSelectionChange`, `OnRangeChange`, `OnScroll`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnMouseDown`, `OnMouseUp`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGPlanner.md`.
