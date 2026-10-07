# TPPGDBPlanner

Palette **PPGlow DB** - Unit `PPG.DB.Planner` - Basis `TPPGCustomDBPlanner`

**Vorbild:** TMS TDBPlanner

## Unterschiede und Hinweise

- Feldzuordnung: `KeyField` (ganze Zahl, nötig zum Schreiben), `StartField`, `FinishField`, `SubjectField`, optional `LocationField`, `BodyField`, `AllDayField`, `CategoryField`, `ResourceField`, `RecurrenceField` (RRULE-Text), `ExDatesField` und `ParentField` (geänderter Einzeltermin einer Serie).
- Zeiten in der Datenmenge wie `TimeZoneMode`: UTC (Vorgabe) oder Ortszeit.
- Gelesen werden alle Datensätze (höchstens `MaxRecords`) und in `Appointments` gespiegelt. Bestehende Termine werden per Schlüssel aktualisiert, nicht neu angelegt: Auswahl und Zeiger bleiben gültig.
- Große Kalender: `OnGetRange(Sender, AFrom, ATo)` meldet den sichtbaren Zeitraum, bevor gelesen wird. Dort Filter oder Parameter der Abfrage setzen; Serien mit Wiederholung müssen dabei immer dabei sein.
- Jede Änderung durch den Anwender (Ziehen, Dauer, Betreff, Anlegen, Löschen, Kopieren, Herauslösen) wird sofort geschrieben: `Locate` per `KeyField`, sonst `Append`. Von der Datenbank vergebene Schlüssel (AutoInc) werden nach `Post` übernommen.
- Änderungen von außen laden verzögert neu (`ReloadDelay`, über den Animator). Eigenes Lesen und Schreiben lösen kein Neuladen aus. Während ein anderes Control die Datenmenge bearbeitet (Edit/Insert), wird nicht gelesen.
- `SyncRecord`: der gewählte Termin wird zum aktuellen Datensatz (z. B. für ein Formular daneben).
- Ohne `KeyField` sind die Termine schreibgeschützt.

## Beispiel

```pascal
PPGDBPlanner1.DataSource := dsTermine;
PPGDBPlanner1.KeyField := 'ID';
PPGDBPlanner1.StartField := 'BEGINN_UTC';
PPGDBPlanner1.FinishField := 'ENDE_UTC';
PPGDBPlanner1.SubjectField := 'BETREFF';
PPGDBPlanner1.RecurrenceField := 'REGEL';
PPGDBPlanner1.OnGetRange := PlannerGetRange;

procedure TForm1.PlannerGetRange(Sender: TObject; AFrom, ATo: TDateTime);
begin
  qTermine.Close;
  qTermine.ParamByName('VON').AsDateTime := AFrom - 1; // Zonenrand
  qTermine.ParamByName('BIS').AsDateTime := ATo + 1;
  qTermine.Open;
end;
```

## Verhalten (aus dem Quelltext)

TPPGDBPlanner - Terminplaner auf einer Datenmenge (Phase 14a, Paket PPGlowDBR).

- Feldzuordnung: KeyField (Pflicht zum Schreiben, ganze Zahl), StartField, FinishField, SubjectField sowie optional LocationField, BodyField, AllDayField, CategoryField, ResourceField, RecurrenceField (RRULE-Text), ExDatesField und ParentField (geaenderter Einzeltermin einer Serie).
- Zeiten in der Datenmenge wie TimeZoneMode: UTC (Vorgabe) oder Ortszeit.
- Laden: alle Datensaetze (hoechstens MaxRecords) werden in Appointments gespiegelt. Bestehende Termine werden per Schluessel aktualisiert statt neu angelegt (Auswahl und Zeiger bleiben gueltig).
- Grosse Kalender: OnGetRange meldet den sichtbaren Zeitraum, bevor gelesen wird; die Anwendung setzt dort Filter bzw. Parameter der Abfrage (Serien mit Wiederholung muessen dabei immer dabei sein).
- Schreiben: jede Aenderung durch den Anwender (Ziehen, Groesse, Betreff, Anlegen, Loeschen, Kopieren, Herausloesen eines Vorkommens) wird sofort in die Datenmenge geschrieben (Locate per KeyField, sonst Append). Selbst vergebene Schluessel (AutoInc) werden nach Post uebernommen.
- Datenaenderungen von aussen laden verzoegert neu (ReloadDelay ueber den Animator); eigenes Lesen und Schreiben loest kein Neuladen aus.
- SyncRecord: der gewaehlte Termin wird zum aktuellen Datensatz.
- Waehrend Edit/Insert durch andere Controls wird nicht gelesen.

## PPGlow-Eigenschaften

`DataSource`, `KeyField`, `StartField`, `FinishField`, `SubjectField`, `LocationField`, `BodyField`, `AllDayField`, `CategoryField`, `ResourceField`, `RecurrenceField`, `ExDatesField`, `ParentField`, `MaxRecords`, `ReloadDelay`, `SyncRecord`, `Resources`, `View`, `Date`, `DayCount`, `FirstDayOfWeek`, `WorkDays`, `WorkStart`, `WorkEnd`, `DayStartHour`, `DayEndHour`, `SlotMinutes`, `SlotHeight`, `SlotWidth`, `TimelineDays`, `AgendaDays`, `GroupByResource`, `ShowNowLine`, `ReadOnly`, `TimeZone`, `TimeZoneMode`, `Calendar`, `Preset`, `StyleManager`, `Appearance`, `Animation`, `HighContrastSupport`, `ScrollBarMode`, `SmoothScrolling`, `Align`, `Anchors`, `BiDiMode`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnGetRange`, `OnAppointmentChanging`, `OnAppointmentChanged`, `OnAppointmentCreated`, `OnAppointmentOpen`, `OnDeleting`, `OnCreateAppointment`, `OnGetAppointmentColor`, `OnSelectionChange`, `OnRangeChange`, `OnScroll`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnMouseDown`, `OnMouseUp`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBPlanner.md`.
