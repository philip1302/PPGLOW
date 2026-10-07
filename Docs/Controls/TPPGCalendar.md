# TPPGCalendar

Palette **PPGlow** - Unit `PPG.Calendar` - Basis `TPPGCustomCalendar`

**Vorbild:** TMonthCalendar, WinUI CalendarView

## Unterschiede und Hinweise

- Monat/Jahr/Dekade mit Zoom-Animation, Wochennummern nach ISO 8601, erster Wochentag aus `FormatSettings`.
- `Date` im Code löst kein Ereignis aus.

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

`Preset`, `StyleManager`, `Appearance`, `Animation`, `HighContrastSupport`, `View`, `Date`, `SelectionMode`, `MinDate`, `MaxDate`, `ShowWeekNumbers`, `ShowToday`, `FirstDayOfWeek`, `Align`, `Anchors`, `BiDiMode`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnChange`, `OnEnter`, `OnExit`, `OnIsDateDisabled`, `OnViewChange`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGCalendar.md`.
