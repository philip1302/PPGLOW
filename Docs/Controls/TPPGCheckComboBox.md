# TPPGCheckComboBox

Palette **PPGlow** - Unit `PPG.CheckComboBox` - Basis `TPPGCustomDropDownField`

**Vorbild:** TMS TCheckListEdit

## Unterschiede und Hinweise

- Mehrfachauswahl im Aufklappfeld. Das Popup bleibt beim Anhaken offen; Enter oder ein Klick daneben schließt es.
- Haken wirken sofort (`OnItemCheck`, `OnChange`). Esc schließt nur und nimmt nichts zurück.
- Anzeige im Feld (`DisplayMode`):
  - `cdmCompact`: „A, B, +2“ (`MaxDisplayItems`)
  - `cdmList`: alle Namen
  - `cdmCount`: „3 ausgewählt“
- `ShowSelectAll` zeigt „Alle auswählen“ als erste Zeile. Ab `FilterThreshold` Einträgen filtern getippte Zeichen die Liste; die Leertaste hakt dabei weiter an.
- `CheckedText` liefert die gewählten Einträge, getrennt durch `Delimiter`. So stehen sie im DFM und in `TPPGDBCheckComboBox`.
- Code (`Checked[]`, `CheckAll`, `CheckedText`) löst keine Ereignisse aus.

## Beispiel

```pascal
PPGCheckComboBox1.Items.CommaText := 'Kunde,Lieferant,Partner';
PPGCheckComboBox1.CheckedText := 'Kunde;Partner';
```

## Verhalten (aus dem Quelltext)

TPPGCheckComboBox - Mehrfachauswahl im Aufklappfeld (Phase 12e,
Vorbild TMS TCheckListEdit).

- Popup-Liste mit Kaestchen (Indikator-Renderer wie CheckListBox, keine neue Zeichenlogik). Das Popup bleibt beim Anhaken offen; Enter oder ein Klick daneben schliesst. Haken wirken sofort (OnItemCheck, OnChange).
- Anzeige im Feld: "A, B, +2" (DisplayMode cdmCompact), alle Namen (cdmList) oder "3 ausgewaehlt" (cdmCount). Ohne Auswahl: TextHint.
- Optional "Alle auswaehlen" als erste Zeile (ShowSelectAll) und eine Filterzeile ab FilterThreshold Eintraegen (getippte Zeichen filtern).
- CheckedText: gewaehlte Eintraege getrennt durch Delimiter; damit gespeichert (DFM) und an DB-Felder gebunden (IPPGFieldValue).
- Code (Checked[], CheckAll, CheckedText) loest keine Ereignisse aus.

## PPGlow-Eigenschaften

`Items`, `CheckedText`, `Delimiter`, `DisplayDelimiter`, `DisplayMode`, `MaxDisplayItems`, `ShowSelectAll`, `FilterThreshold`, `DropDownCount`, `Preset`, `StyleManager`, `Appearance`, `Animation`, `TextHint`, `ValidationState`, `ValidationHint`, `HighContrastSupport`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `BorderStyle`, `Color`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ReadOnly`, `ReadOnlyStyle`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`, `Touch`

## Ereignisse

`OnItemCheck`, `OnGesture`, `OnChange`, `OnCloseUp`, `OnDropDown`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGCheckComboBox.md`.
