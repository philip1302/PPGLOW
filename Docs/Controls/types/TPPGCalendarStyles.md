# TPPGCalendarStyles

Typ in Unit `PPG.Calendar` - Basis `TPPGStyleGroup`

Bereiche des Kalenders (nur gesetzte Werte zaehlen, clDefault = Preset).

Bereiche des Kalenders einzeln gestalten: Hintergrund, Kopf, Wochentage, Heute, Auswahl, Wochenende, Tage anderer Monate und Kalenderwochen. Nicht gesetzte Werte kommen aus dem Preset.

Nutzung: `PPGCalendar1.Styles.Weekend.TextColor := clMaroon;`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Background` | [TPPGElementStyle](TPPGElementStyle.md) |  | Hintergrund des Kalenders: Color = Fläche, TextColor = Text der Tage, BorderColor = Rahmen. Nutzung: `Cal.Styles.Background.Color := $00FAFAFA;` |
| `Header` | [TPPGElementStyle](TPPGElementStyle.md) |  | Titelzeile (Monat und Jahr) samt Blätterpfeilen: TextColor und Schrift. Nutzung: `Cal.Styles.Header.FontStyle := [fsBold];` |
| `DayNames` | [TPPGElementStyle](TPPGElementStyle.md) |  | Zeile mit den Wochentagsnamen (Mo, Di …): TextColor und Schrift. |
| `Today` | [TPPGElementStyle](TPPGElementStyle.md) |  | Markierung von heute: BorderColor = Ring um den Tag, TextColor = Schrift. |
| `Selected` | [TPPGElementStyle](TPPGElementStyle.md) |  | Gewählte Tage: Color = Fläche der Markierung, TextColor = Schrift darauf. |
| `Weekend` | [TPPGElementStyle](TPPGElementStyle.md) |  | Samstag und Sonntag: Color, TextColor und Schrift, z. B. Wochenenden rot hervorheben. Nutzung: `Cal.Styles.Weekend.TextColor := clMaroon;` |
| `OtherMonth` | [TPPGElementStyle](TPPGElementStyle.md) |  | Tage des Vor- und Folgemonats, die die Monatsansicht auffüllen: TextColor (meist gedämpft). |
| `WeekNumbers` | [TPPGElementStyle](TPPGElementStyle.md) |  | Spalte der Kalenderwochen (sichtbar mit ShowWeekNumbers): TextColor und Schrift. |

## Verwendet in

[TPPGCalendar](../TPPGCalendar.md), [TPPGDatePicker](../TPPGDatePicker.md), [TPPGDBDatePicker](../TPPGDBDatePicker.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
