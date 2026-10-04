# TPPGListBox

Palette **PPGlow** - Unit `PPG.ListBox` - Basis `TPPGCustomListBox`

**Vorbild:** TListBox

## Unterschiede und Hinweise

- `ItemHeight` ist eine Mindesthöhe.
- Mehrfachauswahl: `ItemIndex := X` setzt nur den Fokus (wie `TListBox`), nicht die Auswahl.
- Quellen: `Items`, `ItemsEx` (reich: Bild, Detail, Gruppe, Plakette) oder virtuell (`Style = lbVirtual`, `Count` + `OnData`).
- UI Automation: Liste mit Auswahl-Muster, Einträge mit Position im Satz.

## Beispiel

```pascal
PPGListBox1.Style := lbVirtual;
PPGListBox1.Count := 1000000;   // Texte über OnData
```

## Verhalten (aus dem Quelltext)

TPPGListBox - Liste im Stil der Suite, DFM-kompatibel zu TListBox.

Datenquellen (in dieser Rangfolge):
- Style = lbVirtual/lbVirtualOwnerDraw: Count + OnGetItem bzw. OnData (wie TListBox) - Millionen Eintraege, Daten bleiben beim Anwender
- ItemsEx (Collection): Text, Detail, Bild, Plakette, Gruppe - im Designer pflegbar; sobald ItemsEx Eintraege hat, ist es die Quelle
- Items (TStrings): wie TListBox ("Items.Strings" in der DFM)

Items ist eine eigene TStringList, die Einfuegen/Loeschen mit Index meldet:
Auswahl und Fokus wandern mit. Pro Zeile haelt sie eine kleine Huelle
(Objects[] des Anwenders, Kaestchen-Zustand der CheckListBox), die beim
Sortieren und Verschieben mitwandert.

Owner-Draw (lbOwnerDrawFixed/Variable): OnDrawItem zeichnet auf Canvas
(waehrend des Aufrufs ein TCanvas auf dem Zeichenpuffer, Hintergrund und
Auswahl hat das Preset schon gezeichnet), OnMeasureItem liefert Hoehen.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Images`, `ItemsEx`, `AllowMarkup`, `AllowReorder`, `ScrollBarMode`, `SmoothScrolling`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Anchors`, `AutoComplete`, `BiDiMode`, `BorderStyle`, `Color`, `Columns`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `ExtendedSelect`, `Font`, `IntegralHeight`, `ItemHeight`, `Items`, `MultiSelect`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ScrollWidth`, `ShowHint`, `Sorted`, `Style`, `StyleElements`, `TabOrder`, `TabStop`, `TabWidth`, `Visible`, `ItemIndex`

## Ereignisse

`OnClick`, `OnContextPopup`, `OnData`, `OnDataFind`, `OnDataObject`, `OnDblClick`, `OnDragDrop`, `OnDragOver`, `OnDrawItem`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnGetItem`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMeasureItem`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnReorder`, `OnScroll`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGListBox.md`.
