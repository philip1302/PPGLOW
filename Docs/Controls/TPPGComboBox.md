# TPPGComboBox

Palette **PPGlow** - Unit `PPG.ComboBox` - Basis `TPPGCustomComboBox`

**Vorbild:** TComboBox, TMS TAdvComboBox

## Unterschiede und Hinweise

- Ereignisse wie `TComboBox`: `OnClick`, dann `OnSelect`; nur ohne `OnSelect` kommt `OnChange`.
- Das Mausrad ändert die geschlossene Combo nicht.
- `ItemHeight` ist eine Mindesthöhe (alte DFMs speichern 13).
- Eigene Aufklappliste (`PPG.Popup`) mit `ItemsEx` (Bild, Detail, Plakette, Markup) und `FilterMode`; Filtern ersetzt AutoComplete, ohne Treffer schließt die Liste.

## Verhalten (aus dem Quelltext)

TPPGComboBox - Auswahlfeld mit eigener Aufklappliste in der Optik des Presets.

- Basis TPPGCustomField: csDropDown nutzt das native Edit (frei editierbar, AutoComplete), csDropDownList blendet es aus - dann ist das Feld selbst Tabstopp und zeichnet den Eintrag.
- Die Liste ist ein eigenes Popup (PPG.Popup): ohne Aktivierung, die Combo behaelt Fokus und Tastatur und haelt die Maus per SetCapture. Klick ausserhalb, Fokusverlust, Capture-Verlust und Esc schliessen ohne Uebernahme; Klick auf einen Eintrag und Enter uebernehmen.
- Ereignisse wie TComboBox: Auswahl durch den Anwender loest OnClick und danach OnSelect aus - ist OnSelect nicht zugewiesen, stattdessen OnChange. Tippen im Edit loest OnChange aus. ItemIndex/Text im Code setzen loest (wie bei TComboBox) kein Ereignis aus.
- Tastatur: Alt+Unten/Alt+Oben/F4 klappen auf/zu; geschlossen waehlen Oben/Unten/Bild/(Pos1/Ende bei csDropDownList) direkt; offen bewegen sie die Hervorhebung, Enter uebernimmt, Esc verwirft. Tippsuche ueber die Anfangsbuchstaben bei csDropDownList.
- Migration: Property-Namen von TComboBox (Style, Items, ItemIndex, DropDownCount, Sorted, AutoComplete, ...). csSimple wird wie csDropDown, csOwnerDraw* wie csDropDownList behandelt (Owner-Draw gibt es nicht). ItemHeight ist eine Mindesthoehe der Zeilen (0 = aus der Schrift).

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Images`, `ItemsEx`, `FilterMode`, `ShowClearButton`, `TextHint`, `TextHintVisibleOnFocus`, `ValidationState`, `ValidationHint`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Anchors`, `AutoCloseUp`, `AutoComplete`, `AutoDropDown`, `AutoSize`, `BiDiMode`, `BorderStyle`, `CharCase`, `Color`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `DropDownCount`, `DropDownWidth`, `Enabled`, `Font`, `ItemHeight`, `Items`, `ItemIndex`, `MaxLength`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `Sorted`, `Style`, `StyleElements`, `TabOrder`, `TabStop`, `Text`, `Visible`

## Ereignisse

`OnChange`, `OnClick`, `OnCloseUp`, `OnContextPopup`, `OnDblClick`, `OnDragDrop`, `OnDragOver`, `OnDropDown`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnSelect`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGComboBox.md`.
