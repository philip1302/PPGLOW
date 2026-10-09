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

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `DataSource` | `TDataSource` |  | Datenquelle, deren Datensätze als Termine gezeigt werden. |
| `KeyField` | `string` |  | Feld mit dem eindeutigen ganzzahligen Schlüssel; Pflicht zum Schreiben. Selbst vergebene Schlüssel (AutoInc) werden nach dem Speichern übernommen. |
| `StartField` | `string` |  | Feld mit dem Beginn (Datum/Zeit, in der Zone nach TimeZoneMode). Pflicht. |
| `FinishField` | `string` |  | Feld mit dem Ende (Datum/Zeit, in der Zone nach TimeZoneMode). Pflicht. |
| `SubjectField` | `string` |  | Feld mit dem Betreff. Pflicht. |
| `LocationField` | `string` |  | Feld mit dem Ort. Optional. |
| `BodyField` | `string` |  | Feld mit dem Beschreibungstext (Markup erlaubt). Optional. |
| `AllDayField` | `string` |  | Feld „ganztägig" (Boolean). Optional. |
| `CategoryField` | `string` |  | Feld mit dem Kategorie-Index (Zahl, -1 = keine). Optional. |
| `ResourceField` | `string` |  | Feld mit der Ressourcen-Id (Zahl, Resources[i].Id). Optional. |
| `RecurrenceField` | `string` |  | Feld mit der Wiederholungsregel (RRULE-Text). Optional. |
| `ExDatesField` | `string` |  | Feld mit den Ausnahmen einer Serie (Text, iCalendar-Zeiten durch Komma getrennt). Optional, nur mit RecurrenceField. |
| `ParentField` | `string` |  | Feld mit der Serien-Id eines herausgelösten Einzeltermins (RecurrenceParent). Optional. |
| `MaxRecords` | `Integer` | `10000` | Höchstzahl der gelesenen Datensätze, 1 bis MaxInt; Standard 10000. Für große Kalender zusätzlich OnGetRange nutzen. |
| `ReloadDelay` | `Integer` | `100` | Verzögerung in Millisekunden (0 bis 10000), bevor nach Änderungen von außen neu geladen wird; eigenes Schreiben löst kein Neuladen aus. |
| `SyncRecord` | `Boolean` | `True` | True: Der gewählte Termin wird zum aktuellen Datensatz der Datenmenge. |
| `Resources` | [TPPGPlannerResources](types/TPPGPlannerResources.md) |  | Ressourcen (Personen, Räume) mit Id, Name und Farbe; Termine gehören über ResourceId dazu. Nutzung: `Planner1.Resources.AddResource(1, 'Raum A');` |
| `Categories` | [TPPGPlannerCategories](types/TPPGPlannerCategories.md) |  | Kategorien mit Name und Farbe (wie Outlook); Appointment.Category ist der Index. Ohne eigene Farbe gilt eine Farbe der Diagrammpalette. Nutzung: `Planner1.Categories.AddCategory('Kunde', $0050A0F0);` |
| `Styles` | [TPPGPlannerStyles](types/TPPGPlannerStyles.md) |  | Bereiche des Planers einzeln gestalten: Hintergrund, Kopf, Zeitleiste, Nicht-Arbeitszeit, Heute, Jetzt-Linie, Termine, gewählte Zeitfelder. Nicht gesetzte Werte kommen aus dem Preset. Nutzung: `Planner1.Styles.NonWorkHours.Color := $00F4F4F4;` |
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
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGetRange` | `TPPGPlannerRangeEvent` `(Sender: TObject; AFrom, ATo: TDateTime)` | Kommt vor jedem Lesen mit dem sichtbaren Zeitraum (AFrom bis ATo). Hier Filter oder Abfrage-Parameter setzen, damit nur dieser Zeitraum gelesen wird; Serien mit Wiederholung müssen immer dabei sein. Nutzung: `Query1.ParamByName('VON').AsDateTime := AFrom; Query1.ParamByName('BIS').AsDateTime := ATo;` |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnAppointmentChanging` | `TPPGAppointmentChangingEvent` `(Sender: TObject; Appointment: TPPGAppointment; Kind: TPPGAppointmentChangeKind; var NewStart, NewFinish: TDateTime; var NewResourceId: Integer; var Allow: Boolean)` | Vor einer Änderung durch den Anwender. Kind nennt die Art (Verschieben, Größe, Kopie, Betreff). NewStart, NewFinish und NewResourceId lassen sich anpassen, Allow := False bricht ab. Nutzung: `if DayOfWeek(NewStart) in [1, 7] then Allow := False; // kein Wochenende` |
| `OnAppointmentChange` | `TPPGAppointmentEvent` `(Sender: TObject; Appointment: TPPGAppointment)` | Ein Termin wurde vom Anwender geändert (verschoben, in der Dauer geändert, kopiert oder umbenannt); beim DB-Planer ist er bereits gespeichert. |
| `OnAppointmentCreated` | `TPPGAppointmentEvent` `(Sender: TObject; Appointment: TPPGAppointment)` | Ein neuer Termin wurde angelegt (Doppelklick, Enter, Tippen auf freier Fläche oder Kopie); hier z. B. Standardwerte setzen. |
| `OnAppointmentOpen` | `TPPGAppointmentEvent` `(Sender: TObject; Appointment: TPPGAppointment)` | Ein Termin soll geöffnet werden (Doppelklick oder Enter). Ist das Ereignis zugewiesen, wird statt des Termin-Dialogs (DefaultEditor) nur das Ereignis ausgelöst, z. B. für einen eigenen Dialog. |
| `OnDeleting` | `TPPGAppointmentAllowEvent` `(Sender: TObject; Appointment: TPPGAppointment; var Allow: Boolean)` | Bevor ein Termin gelöscht wird (Entf); Allow := False verhindert das Löschen, z. B. nach einer Rückfrage. |
| `OnCreateAppointment` | `TPPGCreateAppointmentEvent` `(Sender: TObject; AStart, AFinish: TDateTime; AResourceId: Integer; AAllDay: Boolean; var Allow: Boolean)` | Bevor ein Termin angelegt wird, mit gewähltem Zeitraum (AStart, AFinish), Ressource und ganztägig; Allow := False verhindert das Anlegen. Nutzung: Eigenen Dialog zeigen und danach selbst anlegen, dann `Allow := False`. |
| `OnGetAppointmentColor` | `TPPGAppointmentColorEvent` `(Sender: TObject; Appointment: TPPGAppointment; var AColor: TColor)` | Liefert die Farbe eines Termins zuletzt: AColor kommt mit der berechneten Farbe (Kategorie, Ressource oder Akzent) und kann überschrieben werden. Nutzung: `if Appointment.Location = 'Extern' then AColor := clTeal;` |
| `OnCustomDrawAppointment` | `TPPGPlannerDrawEvent` `(Sender: TObject; Canvas: TCanvas; Appointment: TPPGAppointment; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean)` | Vor dem Zeichnen jedes Termins: Style (Fill = Terminfarbe, TextColor, BorderColor, FontStyle) ändern oder mit DefaultDraw := False selbst auf Canvas zeichnen. Nutzung: `if Appointment.ReadOnly then Style.FontStyle := [fsItalic];` |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Auswahl geändert (gewählter Termin oder gewählte Zeitfelder). |
| `OnRangeChange` | `TNotifyEvent` `(Sender: TObject)` | Der sichtbare Zeitraum hat sich geändert (Blättern, Ansicht, Date per Code). Die DB-Variante lädt darüber nach. |
| `OnSeriesEdit` | `TPPGSeriesEditEvent` `(Sender: TObject; const Occurrence: TPPGOccurrence; Action: TPPGSeriesAction; var Choice: TPPGSeriesChoice)` | Ersetzt die Abfrage bei Serienterminen: Occurrence und Action (Verschieben, Dauer, Betreff, Ort, Löschen, Dialog) nennen den Fall, Choice kommt mit scOccurrence und lässt sich auf scSeries oder scCancel setzen. Nur bei SeriesEditMode = semAsk. Nutzung: `if Action = saDelete then Choice := scCancel; // Serien nie per Entf` |
| `OnScroll` | `TNotifyEvent` `(Sender: TObject)` | Die Scrollposition hat sich geändert (Rad, Leiste, Tastatur oder Code). Nutzung: Z. B. um eine Positionsanzeige zu aktualisieren: `lblZeile.Caption := IntToStr(Grid.TopRow);` |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |

Tests: `PPG.Tests.Audit5d`; `PPG.Tests.Phase14aDB` (TDBPlannerTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBPlanner.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
