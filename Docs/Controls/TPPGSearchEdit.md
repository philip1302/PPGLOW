# TPPGSearchEdit

Palette **PPGlow** - Unit `PPG.SearchEdit` - Basis `TPPGCustomSearchEdit`

**Vorbild:** TSearchBox (Vcl.WinXCtrls), WinUI AutoSuggestBox

## Unterschiede und Hinweise

- Baut auf der ComboBox auf: Vorschläge in `ItemsEx`, Verzögerung `SearchDelay` über den Animator, `OnSearch`.
- `OnInvokeSearch` von `TSearchBox` heißt hier `OnSearch` (Migrationsskript benennt um).

## Verhalten (aus dem Quelltext)

TPPGSearchEdit - Suchfeld mit Vorschlagsliste (Phase 7a, wie WinUI AutoSuggestBox).

Basis ist die ComboBox (csDropDown): natives Edit, eigene Aufklappliste,
Filter beim Tippen und Tastatur kommen von dort. Dazu:
- Lupen-Button rechts (Klick = Suche absenden), Loeschen-Knopf, kein Aufklapp-Pfeil.
- SearchDelay: Nach dem Tippen wartet das Feld SearchDelay ms (ueber den gemeinsamen Animator, kein Timer) und loest dann OnSearch aus. Dort kann die Anwendung Items (die Vorschlaege) neu fuellen; danach zeigt das Feld die Liste automatisch (gefiltert nach FilterMode).
- Enter, Klick auf die Lupe oder Wahl eines Vorschlags loesen OnSubmit aus (sofort, eine wartende Suche entfaellt). Esc schliesst die Liste bzw. leert den Text.
- Text im Code setzen loest weder OnSearch noch OnSubmit aus.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Images`, `ItemsEx`, `FilterMode`, `SearchDelay`, `ShowClearButton`, `TextHint`, `UseSystemContextMenu`, `TextHintVisibleOnFocus`, `ValidationState`, `ValidationHint`, `HighContrastSupport`, `Align`, `Anchors`, `AutoComplete`, `AutoSize`, `BiDiMode`, `BorderStyle`, `CharCase`, `Color`, `Constraints`, `DropDownCount`, `DropDownWidth`, `Enabled`, `Font`, `ItemHeight`, `Items`, `MaxLength`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `Sorted`, `StyleElements`, `TabOrder`, `TabStop`, `Text`, `Visible`, `Touch`

## Ereignisse

`OnGesture`, `OnChange`, `OnCloseUp`, `OnContextPopup`, `OnDropDown`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseEnter`, `OnMouseLeave`, `OnSearch`, `OnSelect`, `OnSubmit`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGSearchEdit.md`.
