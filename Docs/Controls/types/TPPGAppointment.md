# TPPGAppointment

Typ in Unit `PPG.Planner.Model` - Basis `TCollectionItem`

Ein Termin des Planers: Zeitraum, Betreff, Ort, Ressource, Kategorie, Farbe und Wiederholung.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Id` | `Integer` | `0` | Eindeutige Nummer des Termins; vergibt die Collection fortlaufend. Wird für Serien (RecurrenceParent) und den DB-Planer (KeyField) gebraucht. |
| `StartTime` | `TDateTime` |  | Gespeicherter Beginn (UTC bei TimeZoneMode = tzmUtc, sonst Ortszeit). Für die Anzeige-Zeit die öffentliche Eigenschaft Start verwenden. Nutzung: Im Code meist `A.Start := ...` (rechnet aus der Anzeige-Zone um); StartTime nur beim Laden aus eigenen Daten. |
| `FinishTime` | `TDateTime` |  | Gespeichertes Ende (UTC bei TimeZoneMode = tzmUtc, sonst Ortszeit). Für die Anzeige-Zeit die öffentliche Eigenschaft Finish verwenden. |
| `AllDay` | `Boolean` | `False` | True: ganztägiger Termin. Er liegt im Band über dem Zeitraster; Beginn und Ende sind dann reine Daten ohne Zeitzone, das Ende ist exklusiv (wie DTEND in iCalendar). Nutzung: Ein Tag: `A.AllDay := True; A.Start := EncodeDate(2026, 10, 8); A.Finish := A.Start + 1;` |
| `Subject` | `string` |  | Betreff; die Überschrift des Termins im Raster. Der Anwender ändert ihn mit F2 oder Doppelklick (ohne OnAppointmentOpen). |
| `Location` | `string` |  | Ort des Termins; erscheint unter dem Betreff, in der Agenda und für den Screenreader. |
| `Body` | `string` |  | Beschreibungstext des Termins; darf Mini-Markup enthalten (<b>, <i>, <color=...>). Wird in der Agenda und im Tooltip gezeigt. |
| `Category` | `Integer` | `-1` | Index in Planner.Categories; bestimmt die Terminfarbe (Kategoriefarbe, bei clDefault eine Farbe der Diagrammpalette). -1 = keine Kategorie, dann gilt die Farbe der Ressource bzw. der Akzent. Nutzung: `A.Category := 2;` Farbe zur Laufzeit ändern über OnGetAppointmentColor. |
| `ResourceId` | `Integer` | `0` | Ressource des Termins (Wert von Resources[i].Id). Bestimmt die Spaltengruppe (GroupByResource) bzw. Zeile der Zeitleiste und ohne Kategorie die Farbe. |
| `Recurrence` | `string` |  | Wiederholungsregel im iCalendar-Format (RRULE). Leer = Einzeltermin. Der Planer löst die Vorkommen nur für den sichtbaren Zeitraum auf. Nutzung: `A.Recurrence := 'FREQ=WEEKLY;BYDAY=MO,WE;COUNT=10';` |
| `ExDates` | `string` |  | Ausnahmen einer Serie: Beginnzeiten ausgefallener Vorkommen im iCalendar-Format, durch Komma getrennt (in gespeicherter Zeit, also UTC bei TimeZoneMode = tzmUtc). Wird beim Löschen bzw. Herauslösen eines Vorkommens automatisch ergänzt. Nutzung: Im Code besser die Methode zum Ausnehmen eines Vorkommens verwenden statt den Text selbst zu bauen. |
| `RecurrenceParent` | `Integer` | `0` | Bei einem geänderten Einzeltermin einer Serie: Id der Serie (0 = kein herausgelöster Termin). Zusammen mit RecurrenceStart ersetzt er genau ein Vorkommen der Serie. |
| `RecurrenceStart` | `TDateTime` |  | Ursprünglicher Beginn des Vorkommens, das dieser herausgelöste Termin ersetzt (nur mit RecurrenceParent <> 0). |
| `ReadOnly` | `Boolean` | `False` | True: Der Anwender kann diesen Termin nicht verschieben, in der Dauer ändern, umbenennen oder löschen; Kopieren mit Strg+Ziehen bleibt erlaubt. |
| `Tag` | `NativeInt` | `0` | Freier Ganzzahlwert der Anwendung (z. B. eine eigene Datensatz-ID). |

## Verwendet in

[TPPGAppointments](TPPGAppointments.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
