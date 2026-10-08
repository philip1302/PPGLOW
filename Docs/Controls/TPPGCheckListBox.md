# TPPGCheckListBox

Palette **PPGlow** - Unit `PPG.CheckListBox` - Basis `TPPGCustomCheckListBox`

**Vorbild:** TCheckListBox

## Unterschiede und Hinweise

- Kästchen im Preset-Stil; `Header[]` macht Zeilen zu Überschriften (ohne Kästchen, nicht wählbar).
- `Checked[]`/`State[]` im Code lösen kein Ereignis aus; der Anwender löst `OnClickCheck` aus.
- UI Automation: zusätzlich Toggle-Muster je Eintrag.

## Anpassung

- `Styles` und `OnCustomDrawItem` wie `TPPGListBox`.

## Verhalten (aus dem Quelltext)

TPPGCheckListBox - ListBox mit Kaestchen, DFM-kompatibel zu TCheckListBox.

Die Kaestchen zeichnet IPPGIndicatorRenderer des Presets (wie TPPGCheckBox).
Zustand pro Zeile: bei Items in der Huelle der Zeile (wandert beim
Sortieren/Verschieben mit), bei ItemsEx in TPPGItem.Checked, virtuell ueber
OnGetItem (Data.Checked) und OnSetChecked.

Bedienung wie TCheckListBox: Klick auf das Kaestchen oder Leertaste schaltet
um (aus -> an -> gemischt, wenn AllowGrayed), danach OnClickCheck. Setzen
im Code (Checked[], State[], CheckAll) loest kein Ereignis aus.
Header[] macht eine Zeile zur Ueberschrift (ohne Kaestchen, nicht waehlbar).

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Images`, `ItemsEx`, `AllowMarkup`, `AllowReorder`, `Styles`, `ScrollBarMode`, `SmoothScrolling`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`AllowGrayed`, `Align`, `Anchors`, `AutoComplete`, `BiDiMode`, `BorderStyle`, `Color`, `Columns`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `Flat`, `Font`, `HeaderColor`, `HeaderBackgroundColor`, `IntegralHeight`, `ItemHeight`, `Items`, `MultiSelect`, `ExtendedSelect`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ScrollWidth`, `ShowHint`, `Sorted`, `Style`, `StyleElements`, `TabOrder`, `TabStop`, `TabWidth`, `Visible`, `Touch`, `ItemIndex`

## Ereignisse

`OnGesture`, `OnClick`, `OnClickCheck`, `OnContextPopup`, `OnData`, `OnDataFind`, `OnDataObject`, `OnDblClick`, `OnDragDrop`, `OnDragOver`, `OnDrawItem`, `OnCustomDrawItem`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnGetItem`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMeasureItem`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnReorder`, `OnScroll`, `OnSetChecked`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGCheckListBox.md`.
