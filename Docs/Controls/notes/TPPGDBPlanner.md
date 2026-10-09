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

## Anpassung

- `Categories`, `Styles`, `OnCustomDrawAppointment`, `SaveLayout`/`LoadLayout` wie `TPPGPlanner`.

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
