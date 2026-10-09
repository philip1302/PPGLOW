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
- Bedienung: Ziehen verschiebt (Strg kopiert), die Kante ändert die Dauer. Alles rastet an `SlotMinutes`. Ziehen auf freier Fläche wählt Zeitfelder; Doppelklick, Enter oder Tippen legt einen Termin an und öffnet die Bearbeitung des Betreffs (Esc verwirft einen neuen, leeren Termin).
- **Serien:** Wird ein Vorkommen geändert (Ziehen, Dauer, Betreff, Ort, Dialog, Löschen), fragt der Planer wie Outlook „nur dieses Vorkommen“ oder „ganze Serie“ (`SeriesEditMode = semAsk`, Vorgabe; `semOccurrence`/`semSeries` fragen nicht). `OnSeriesEdit` ersetzt die Abfrage. Nur das Vorkommen: es wird herausgelöst (`RecurrenceParent`), die Serie bekommt eine Ausnahme. Ganze Serie: Verschieben verschiebt die Serie samt Wochentagen, vorhandene Ausnahmen bleiben. Ohne sichtbares Fenster wird nicht gefragt (wie `semOccurrence`).
- **Termin-Dialog:** Ohne `OnAppointmentOpen` öffnen Doppelklick und Enter den eingebauten Dialog (`DefaultEditor`, Unit `PPG.Planner.Dialog`: Betreff, Ort, Beginn/Ende, ganztägig, Person, Kategorie, Wiederholung, Notiz; Prüfung über `TPPGValidator`). `EditAppointment` öffnet ihn im Code, `PPGAppointmentDialogHook` ersetzt ihn durch einen eigenen.
- Ereignisse: `OnAppointmentChanging` (abbrechbar, neue Werte änderbar), `OnAppointmentChanged`, `OnAppointmentCreated`, `OnCreateAppointment` (abbrechbar), `OnDeleting`, `OnAppointmentOpen`, `OnSeriesEdit`, `OnSelectionChange`, `OnRangeChange`. Zuweisungen im Code (`Date := ...`) lösen nur `OnRangeChange` aus.
- Tastatur: Pfeile wandern durch die Felder (Umschalt erweitert), Tab durch die Termine, Strg+Pfeile verschieben den gewählten Termin, Strg+Umschalt+Oben/Unten ändern die Dauer, Enter öffnet bzw. legt an, F2 bearbeitet den Betreff, Umschalt+F2 den Ort, Entf löscht, Bild auf/ab blättert, Pos1 springt zu heute.
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

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Appointments` | [TPPGAppointments](types/TPPGAppointments.md) |  | Die Termine (Collection, wird in der DFM gespeichert). Beim DB-Planer ist sie nur der Spiegel der Datenmenge und wird nicht gespeichert. Nutzung: `Planner1.Appointments.AddAppointment(Start, Finish, 'Besprechung');` |
| `Resources` | [TPPGPlannerResources](types/TPPGPlannerResources.md) |  | Ressourcen (Personen, Räume) mit Id, Name und Farbe; Termine gehören über ResourceId dazu. Nutzung: `Planner1.Resources.AddResource(1, 'Raum A');` |
| `Categories` | [TPPGPlannerCategories](types/TPPGPlannerCategories.md) |  | Kategorien mit Name und Farbe (wie Outlook); Appointment.Category ist der Index. Ohne eigene Farbe gilt eine Farbe der Diagrammpalette. Nutzung: `Planner1.Categories.AddCategory('Kunde', $0050A0F0);` |
| `PlannerStyles` | [TPPGPlannerStyles](types/TPPGPlannerStyles.md) |  | Bereiche des Planers einzeln gestalten: Hintergrund, Kopf, Zeitleiste, Nicht-Arbeitszeit, Heute, Jetzt-Linie, Termine, gewählte Zeitfelder. Nicht gesetzte Werte kommen aus dem Preset. Nutzung: `Planner1.PlannerStyles.NonWorkHours.Color := $00F4F4F4;` |
| `View` | `TPPGPlannerView` | `pvWeek` | Ansicht: Tag (DayCount Tage), Arbeitswoche (WorkDays), Woche, Monat (6 Wochen), Zeitleiste (waagerecht, Zeilen = Ressourcen) oder Agenda (Liste nach Tagen). Werte: `pvDay`, `pvWorkWeek`, `pvWeek`, `pvMonth`, `pvTimeline`, `pvAgenda`. Nutzung: `Planner1.View := pvWorkWeek;` |
| `Date` | `TDate` |  | Bezugstag: der gezeigte Zeitraum enthält diesen Tag (in Tag-, Wochen-, Monats- und Zeitleistenansicht). Wird nicht gespeichert, Vorgabe ist heute; Setzen löst OnRangeChange aus. Nutzung: `Planner1.Date := EncodeDate(2026, 12, 1);` |
| `DayCount` | `Integer` | `1` | Zahl der Tage in der Tagesansicht (pvDay), 1 bis 31. |
| `FirstDayOfWeek` | `TPPGFirstDayOfWeek` | `fdLocale` | Erster Wochentag der Wochen- und Monatsansicht; fdLocale = nach den Ländereinstellungen von Windows. Werte: `fdLocale`, `fdMonday`, `fdTuesday`, `fdWednesday`, `fdThursday`, `fdFriday`, `fdSaturday`, `fdSunday`. |
| `WorkDays` | `TPPGWeekDays` | `[wdMonday, wdTuesday, wdWednesday, wdThursday, wdFriday]` | Arbeitstage: bestimmen die Arbeitswoche (pvWorkWeek); die übrigen Tage werden als freie Tage hinterlegt. Menge aus: `wdMonday`, `wdTuesday`, `wdWednesday`, `wdThursday`, `wdFriday`, `wdSaturday`, `wdSunday`. |
| `WorkStart` | `Integer` | `480` | Beginn der Arbeitszeit in Minuten nach Mitternacht (0 bis 1440, Standard 480 = 8:00); außerhalb wird das Raster als Nicht-Arbeitszeit hinterlegt. Nutzung: `Planner1.WorkStart := 7 * 60 + 30; // 7:30` |
| `WorkEnd` | `Integer` | `1020` | Ende der Arbeitszeit in Minuten nach Mitternacht (0 bis 1440, Standard 1020 = 17:00). |
| `DayStartHour` | `Integer` | `0` | Erste gezeigte Stunde des Zeitrasters (0 bis 23). Nutzung: `Planner1.DayStartHour := 7; Planner1.DayEndHour := 19;` |
| `DayEndHour` | `Integer` | `24` | Letzte gezeigte Stunde des Zeitrasters (1 bis 24, exklusiv); zusammen mit DayStartHour lässt sich z. B. nur 7–19 Uhr zeigen. |
| `SlotMinutes` | `Integer` | `30` | Länge eines Zeitfelds in Minuten: 5, 10, 15, 20, 30 oder 60. Ziehen und Größe ändern rasten an diesem Raster ein; andere Werte lösen EPPGPropertyError aus. |
| `SlotHeight` | `Integer` | `22` | Höhe eines Zeitfelds in logischen Pixeln (8 bis 200). |
| `SlotWidth` | `Integer` | `40` | Breite eines Zeitfelds in der Zeitleiste (pvTimeline) in logischen Pixeln (8 bis 400). |
| `TimelineDays` | `Integer` | `7` | Zahl der Tage in der Zeitleiste (1 bis 366). |
| `AgendaDays` | `Integer` | `14` | Zahl der Tage in der Agenda-Ansicht (1 bis 366). |
| `GroupByResource` | `Boolean` | `True` | True: In Tag- und Wochenansicht bekommt jede Ressource ihre eigene Spaltengruppe (nur mit Resources). In der Zeitleiste sind Ressourcen immer Zeilen. |
| `ShowNowLine` | `Boolean` | `True` | True: Eine Linie markiert die aktuelle Uhrzeit (wird einmal pro Minute aktualisiert). |
| `ReadOnly` | `Boolean` | `False` | True: Termine können weder angelegt, verschoben, in der Dauer geändert noch gelöscht werden; Auswahl und Öffnen bleiben möglich. |
| `TimeZone` | `string` |  | Zeitzone der Anzeige als Windows- oder IANA-Name (z. B. 'Europe/Berlin'); leer = Zone des Rechners. |
| `TimeZoneMode` | `TPPGTimeZoneMode` | `tzmUtc` | In welcher Zeit StartTime und FinishTime gespeichert sind: tzmUtc (Vorgabe, eindeutig auch über Zonen und Sommerzeit) oder tzmLocal (Ortszeit ohne Umrechnung). Werte: `tzmUtc`, `tzmLocal`. |
| `Calendar` | `TPPGCustomCalendar` |  | Verbundener TPPGCalendar: Er zeigt Tage mit Terminen fett, und ein Klick auf einen Tag stellt den Zeitraum des Planers ein. |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `ScrollBarMode` | `TPPGScrollBarMode` | `sbmAuto` | Wann die Scrollleisten erscheinen: sbmAuto (bei Bedarf, als schmale Overlay-Leiste), sbmAlways (immer), sbmNever (nie; Scrollen nur per Rad, Tastatur oder Code). Werte: `sbmAuto`, `sbmAlways`, `sbmNever`. |
| `SmoothScrolling` | `Boolean` | `True` | True: Scrollen per Rad und Tastatur gleitet weich statt sprunghaft. |
| `SeriesEditMode` | `TPPGSeriesEditMode` | `semAsk` | Was beim Ändern eines Vorkommens einer Serie gilt: semAsk fragt wie Outlook „nur dieses Vorkommen“ oder „ganze Serie“ (ohne sichtbares Fenster wie semOccurrence), semOccurrence löst das Vorkommen heraus, semSeries ändert die ganze Serie. Werte: `semAsk`, `semOccurrence`, `semSeries`. |
| `DefaultEditor` | `Boolean` | `True` | True: Ohne OnAppointmentOpen öffnen Doppelklick und Enter den eingebauten Termin-Dialog (Unit PPG.Planner.Dialog). False: der Betreff wird direkt im Planer bearbeitet. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
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
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnAppointmentChanging` | `TPPGAppointmentChangingEvent` `(Sender: TObject; Appointment: TPPGAppointment; Kind: TPPGAppointmentChangeKind; var NewStart, NewFinish: TDateTime; var NewResourceId: Integer; var Allow: Boolean)` | Vor einer Änderung durch den Anwender. Kind nennt die Art (Verschieben, Größe, Kopie, Betreff). NewStart, NewFinish und NewResourceId lassen sich anpassen, Allow := False bricht ab. Nutzung: `if DayOfWeek(NewStart) in [1, 7] then Allow := False; // kein Wochenende` |
| `OnAppointmentChanged` | `TPPGAppointmentEvent` `(Sender: TObject; Appointment: TPPGAppointment)` | Ein Termin wurde vom Anwender geändert (verschoben, in der Dauer geändert, kopiert oder umbenannt); beim DB-Planer ist er bereits gespeichert. |
| `OnAppointmentCreated` | `TPPGAppointmentEvent` `(Sender: TObject; Appointment: TPPGAppointment)` | Ein neuer Termin wurde angelegt (Doppelklick, Enter, Tippen auf freier Fläche oder Kopie); hier z. B. Standardwerte setzen. |
| `OnAppointmentOpen` | `TPPGAppointmentEvent` `(Sender: TObject; Appointment: TPPGAppointment)` | Ein Termin soll geöffnet werden (Doppelklick oder Enter). Ist das Ereignis zugewiesen, wird statt des Termin-Dialogs (DefaultEditor) nur das Ereignis ausgelöst, z. B. für einen eigenen Dialog. |
| `OnDeleting` | `TPPGAppointmentAllowEvent` `(Sender: TObject; Appointment: TPPGAppointment; var Allow: Boolean)` | Bevor ein Termin gelöscht wird (Entf); Allow := False verhindert das Löschen, z. B. nach einer Rückfrage. |
| `OnCreateAppointment` | `TPPGCreateAppointmentEvent` `(Sender: TObject; AStart, AFinish: TDateTime; AResourceId: Integer; AAllDay: Boolean; var Allow: Boolean)` | Bevor ein Termin angelegt wird, mit gewähltem Zeitraum (AStart, AFinish), Ressource und ganztägig; Allow := False verhindert das Anlegen. Nutzung: Eigenen Dialog zeigen und danach selbst anlegen, dann `Allow := False`. |
| `OnGetAppointmentColor` | `TPPGAppointmentColorEvent` `(Sender: TObject; Appointment: TPPGAppointment; var AColor: TColor)` | Liefert die Farbe eines Termins zuletzt: AColor kommt mit der berechneten Farbe (Kategorie, Ressource oder Akzent) und kann überschrieben werden. Nutzung: `if Appointment.Location = 'Extern' then AColor := clTeal;` |
| `OnCustomDrawAppointment` | `TPPGPlannerDrawEvent` `(Sender: TObject; Canvas: TCanvas; Appointment: TPPGAppointment; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean)` | Vor dem Zeichnen jedes Termins: Style (Fill = Terminfarbe, TextColor, BorderColor, FontStyle) ändern oder mit DefaultDraw := False selbst auf Canvas zeichnen. Nutzung: `if Appointment.ReadOnly then Style.FontStyle := [fsItalic];` |
| `OnSelectionChange` | `TNotifyEvent` `(Sender: TObject)` | Auswahl geändert (gewählter Termin oder gewählte Zeitfelder). |
| `OnRangeChange` | `TNotifyEvent` `(Sender: TObject)` | Der sichtbare Zeitraum hat sich geändert (Blättern, Ansicht, Date per Code). Die DB-Variante lädt darüber nach. |
| `OnSeriesEdit` | `TPPGSeriesEditEvent` `(Sender: TObject; const Occurrence: TPPGOccurrence; Action: TPPGSeriesAction; var Choice: TPPGSeriesChoice)` | Ersetzt die Abfrage bei Serienterminen: Occurrence und Action (Verschieben, Dauer, Betreff, Ort, Löschen, Dialog) nennen den Fall, Choice kommt mit scOccurrence und lässt sich auf scSeries oder scCancel setzen. Nur bei SeriesEditMode = semAsk. Nutzung: `if Action = saDelete then Choice := scCancel; // Serien nie per Entf` |
| `OnScroll` | `TNotifyEvent` `(Sender: TObject)` | Die Scrollposition hat sich geändert (Rad, Leiste, Tastatur oder Code). Nutzung: Z. B. um eine Positionsanzeige zu aktualisieren: `lblZeile.Caption := IntToStr(Grid.TopRow);` |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGPlanner.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
