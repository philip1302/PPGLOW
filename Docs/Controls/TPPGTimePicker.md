# TPPGTimePicker

Palette **PPGlow** - Unit `PPG.TimePicker` - Basis `TPPGCustomTimePicker`

**Vorbild:** TDateTimePicker (Kind = dtkTime)

## Unterschiede und Hinweise

- Baut auf der ComboBox auf; `OnChange` erst bei der Übernahme (Verlassen, Enter, Liste, Pfeile), nicht bei jedem Tastendruck.
- Keine Spin-Buttons: Oben/Unten und Mausrad ändern den Teil an der Einfügemarke.

## Verhalten (aus dem Quelltext)

TPPGTimePicker - Uhrzeitfeld (Phase 7b).

Basis ist die ComboBox (csDropDown): die Aufklappliste enthaelt die Zeiten
im Abstand MinuteIncrement (Klick bzw. Enter uebernimmt). Dazu:
- 12/24 Stunden aus dem Gebietsschema (LOCALE_ITIME) oder fest (ClockFormat); AM/PM aus FormatSettings; Sekunden optional.
- Oben/Unten bzw. Mausrad aendern den Teil unter der Einfuegemarke (Stunde, Minute, Sekunde, AM/PM) mit Uebertrag.
- Freie Eingabe ("14:30", "1430", "2:30 PM"); geprueft wird beim Verlassen bzw. Enter: gueltig = uebernehmen (OnChange), ungueltig = ValidationState pvsError.
- Beim Aufklappen ist die naechstliegende Zeit der Liste hervorgehoben.
- Code (Time := ...) loest kein OnChange aus.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `TextHint`, `UseSystemContextMenu`, `ValidationState`, `ValidationHint`, `HighContrastSupport`, `Time`, `ShowSeconds`, `ClockFormat`, `MinuteIncrement`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `BorderStyle`, `Color`, `Constraints`, `DropDownCount`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`, `Touch`

## Ereignisse

`OnGesture`, `OnChange`, `OnCloseUp`, `OnContextPopup`, `OnDropDown`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseEnter`, `OnMouseLeave`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGTimePicker.md`.
