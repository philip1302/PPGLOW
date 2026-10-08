# TPPGDatePicker

Palette **PPGlow** - Unit `PPG.DatePicker` - Basis `TPPGCustomDatePicker`

**Vorbild:** TDateTimePicker (Kind = dtkDate)

## Unterschiede und Hinweise

- Eingabe nur Ziffern und Datumstrenner (Kurzformat); Prüfung beim Verlassen/Enter, Fehler als `ValidationState`.
- `Kind`, `DateMode`, `ParseInput` werden nur gelesen/gespeichert. Leeres Datum nur mit `ShowCheckbox`.
- Für `Kind = dtkTime` gibt es `TPPGTimePicker`.

## Anpassung

- `CalendarStyles` und `OnCustomDrawDay` gelten für den aufgeklappten Kalender.

## Verhalten (aus dem Quelltext)

TPPGDatePicker - Datumsfeld mit Kalender-Popup (Phase 7b).

- Basis TPPGCustomField: natives Edit fuer die Eingabe, Kalender-Button rechts, optional ein Kontrollkaestchen links (ShowCheckbox/Checked wie TDateTimePicker: ohne Haken gilt "kein Datum").
- Eingabe: Ziffern und Datumstrenner; Oben/Unten aendern den Tag (Strg: Monat). Beim Verlassen bzw. Enter wird geprueft: gueltig = uebernehmen (OnChange), ungueltig = ValidationState pvsError, der Text bleibt zum Korrigieren stehen. Grenzen MinDate/MaxDate.
- Popup: TPPGCalendar in einem Popup ohne Aktivierung. Das Feld behaelt den Fokus und leitet Pfeile, Bild, Pos1/Ende und Enter an den Kalender weiter. Klick ausserhalb (Maus-Hook des Threads, solange offen), Esc und Fokusverlust schliessen; Klick auf einen Tag uebernimmt.
- DFM-nah zu TDateTimePicker (Kind = dtkDate): Date, Time, MinDate, MaxDate, ShowCheckbox, Checked, DateFormat, Format, CalAlignment; Kind, DateMode und ParseInput werden gelesen und gespeichert, aendern aber nichts (fuer Zeiten gibt es TPPGTimePicker).
- Code (Date := ...) loest kein OnChange aus.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `TextHint`, `UseSystemContextMenu`, `ValidationState`, `ValidationHint`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Anchors`, `AutoSize`, `BiDiMode`, `BorderStyle`, `CalAlignment`, `Checked`, `Color`, `Constraints`, `Date`, `DateFormat`, `DateMode`, `Enabled`, `Font`, `Format`, `Kind`, `MaxDate`, `MinDate`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `ParseInput`, `PopupMenu`, `ShowCheckbox`, `CalendarStyles`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Time`, `Visible`, `Touch`

## Ereignisse

`OnCustomDrawDay`, `OnGesture`, `OnChange`, `OnClick`, `OnCloseUp`, `OnContextPopup`, `OnDropDown`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseEnter`, `OnMouseLeave`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDatePicker.md`.
