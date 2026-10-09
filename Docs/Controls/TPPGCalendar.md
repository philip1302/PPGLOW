# TPPGCalendar

Palette **PPGlow** - Unit `PPG.Calendar` - Basis `TPPGCustomCalendar`

**Vorbild:** TMonthCalendar, WinUI CalendarView

## Unterschiede und Hinweise

- Monat/Jahr/Dekade mit Zoom-Animation, Wochennummern nach ISO 8601, erster Wochentag aus `FormatSettings`.
- `Date` im Code löst kein Ereignis aus.

## Anpassung

- `Styles` (Kopf, Wochentage, Wochenende, Heute, Auswahl, andere Monate …) und `OnCustomDrawDay` (z. B. Feiertage fett).

## Verhalten (aus dem Quelltext)

TPPGCalendar - Monatskalender mit Jahres- und Dekadenansicht (Phase 7b).

- Ansichten: Monat (Tage), Jahr (Monate), Dekade (Jahre). Klick auf den Titel bzw. Strg+Oben zoomt heraus, Klick auf einen Monat/ein Jahr bzw. Enter zoomt hinein. Wechsel und Blaettern sind animiert (gemeinsamer Animator, ekDecelerate).
- Erster Wochentag aus dem Gebietsschema (LOCALE_IFIRSTDAYOFWEEK) oder fest; Wochennummern nach ISO 8601 (ShowWeekNumbers); Tages- und Monatsnamen aus FormatSettings.
- Auswahl: einzelner Tag, Bereich (zwei Klicks bzw. Umschalt+Klick) oder mehrere Tage (Klick schaltet um). MinDate/MaxDate und OnIsDateDisabled sperren Tage. Heute ist markiert (ShowToday).
- Tastatur: Pfeile (Tag/Woche), Bild auf/ab (Monat), Strg+Bild (Jahr), Pos1/Ende (Monatsanfang/-ende), Enter/Leertaste waehlen, Strg+Oben/Unten zoomen. RTL gespiegelt.
- Code (Date := ...) loest kein OnChange aus; der Anwender schon.
- Screenreader: Tabelle, Kinder sind die Tage (bzw. Monate/Jahre) mit Langdatum als Name, Zustaenden gewaehlt/fokussiert/gesperrt.
- Link (Phase 14a): ein verbundener Planer (IPPGCalendarLink) markiert Tage mit Terminen fett und erfaehrt die Auswahl des Anwenders.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `View` | `TPPGCalendarView` | `cvMonth` | Aktuelle Ansicht: Monat (Tage), Jahr (Monate) oder Dekade (Jahre). Der Anwender zoomt per Klick auf den Titel bzw. Strg+Oben/Unten. Werte: `cvMonth`, `cvYear`, `cvDecade`. |
| `Date` | `TDate` |  | Gewähltes Datum (bei Bereich bzw. Mehrfachauswahl der Fokus-Tag). Setzen im Code springt zum Monat und löst kein OnChange aus. Nutzung: `Cal.Date := EncodeDate(2026, 12, 24);` |
| `SelectionMode` | `TPPGDateSelectionMode` | `dsmSingle` | Auswahlart: ein Tag, ein Bereich (zwei Klicks bzw. Umschalt+Klick) oder mehrere einzelne Tage (Klick schaltet um). Werte: `dsmSingle`, `dsmRange`, `dsmMultiple`. |
| `MinDate` | `TDate` |  | Frühestes wählbares Datum; frühere Tage sind gesperrt. 0 = ohne Grenze. Nutzung: `Cal.MinDate := Date;` erlaubt nur heute und später. |
| `MaxDate` | `TDate` |  | Spätestes wählbares Datum; spätere Tage sind gesperrt. 0 = ohne Grenze. |
| `ShowWeekNumbers` | `Boolean` | `False` | True: Links steht die Kalenderwoche nach ISO 8601. |
| `ShowToday` | `Boolean` | `True` | True: Der heutige Tag ist mit einem Ring markiert (Farbe über Styles.Today). |
| `FirstDayOfWeek` | `TPPGFirstDayOfWeek` | `fdLocale` | Erster Wochentag der Monatsansicht; fdLocale = aus den Windows-Ländereinstellungen. Werte: `fdLocale`, `fdMonday`, `fdTuesday`, `fdWednesday`, `fdThursday`, `fdFriday`, `fdSaturday`, `fdSunday`. |
| `Styles` | [TPPGCalendarStyles](types/TPPGCalendarStyles.md) |  | Bereiche des Kalenders einzeln gestalten: Hintergrund, Kopf, Wochentage, Heute, Auswahl, Wochenende, andere Monate, Wochennummern. Nicht gesetzte Werte kommen aus dem Preset. Nutzung: `Cal.Styles.Weekend.TextColor := clRed;` |

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
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Anwender hat ein Datum bzw. die Auswahl geändert (nicht bei Date im Code). |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnIsDateDisabled` | `TPPGDateDisabledEvent` `(Sender: TObject; ADate: TDate; var Disabled: Boolean)` | Fragt je Tag, ob er gesperrt ist; Disabled := True macht ihn nicht wählbar (zusätzlich zu MinDate/MaxDate). Nutzung: `Disabled := DayOfTheWeek(ADate) in [6, 7];` sperrt Wochenenden. |
| `OnCustomDrawDay` | `TPPGCalendarDrawDayEvent` `(Sender: TObject; Canvas: TCanvas; ADate: TDate; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean)` | Vor dem Zeichnen jedes Tages der Monatsansicht: Style (Fill, TextColor, BorderColor, FontStyle) für diesen Tag ändern oder mit DefaultDraw := False selbst auf Canvas zeichnen. State nennt idsSelected, idsToday, idsDisabled usw. Nutzung: `if IstFeiertag(ADate) then begin Style.TextColor := clRed; Style.FontStyle := [fsBold]; end;` |
| `OnViewChange` | `TNotifyEvent` `(Sender: TObject)` | Die Ansicht (Monat, Jahr, Dekade) oder der angezeigte Zeitraum hat gewechselt, z. B. nach Blättern. |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |

Tests: `PPG.Tests.Audit5d`; `PPG.Tests.Audit7A` (TWheelTests); `PPG.Tests.Custom` (TCustomViewTests); `PPG.Tests.Phase14aPlanner` (TPlannerTests); `PPG.Tests.Phase7b` (TCalendarTests, TPhase7bPaintTests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGCalendar.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
