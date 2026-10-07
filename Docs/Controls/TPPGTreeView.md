# TPPGTreeView

Palette **PPGlow** - Unit `PPG.TreeView` - Basis `TPPGCustomTreeView`

**Vorbild:** TTreeView

## Unterschiede und Hinweise

- `ItemHeight` ist eine Mindesthöhe.
- `Selected := X` löst wie `TTreeView` `OnChange` aus (anders als die übrigen PPGlow-Controls).
- Lazy Loading über `HasChildren` + `OnExpanding`; nur der Pfeil dreht sich animiert.
- Knoten aus `TTreeView`-DFMs (binär) werden nicht gelesen; Knoten im Designer über „Edit nodes...“ anlegen.
- UI Automation: Hierarchie, Auf-/Zuklappen, Ebene und Position im Satz.

## Beispiel

```pascal
N := PPGTreeView1.Items.AddChild(nil, 'Dokumente');
N.HasChildren := True;  // Kinder erst in OnExpanding
```

## Verhalten (aus dem Quelltext)

TPPGTreeView - Baum im Stil der Suite (Phase 6b).

Aufbau: Die sichtbaren Knoten bilden eine flache Zeilenliste; sie ist die
IPPGItemSource der Listen-Basis. Zeichnen, Scrollen, Auswahl, Tippsuche
und Barrierefreiheit kommen damit aus TPPGCustomItemList; der Baum fuegt
Einzug, Auf-/Zuklapp-Pfeil, Linien, Kaestchen und das Umbenennen hinzu.

- Knoten: TPPGTreeNode/TPPGTreeNodes mit einer API wie TTreeNode/TTreeNodes (Add, AddChild, Insert, MoveTo, Expand, Collapse, GetNext, ...).
- Lazy Loading wie bei TTreeView: HasChildren := True zeigt den Pfeil ohne Kinder; OnExpanding fuellt die Kinder beim ersten Aufklappen.
- Kaestchen (CheckBoxes) mit drei Zustaenden; AutoCheck gibt den Zustand an Kinder weiter und berechnet die Eltern (alle an / alle aus / gemischt).
- Umbenennen (ReadOnly = False) mit F2 bzw. EditText ueber ein natives Edit: Enter uebernimmt, Esc verwirft, Fokusverlust und Scrollen uebernehmen.
- Knoten ziehen (AllowReorder): oberes/unteres Viertel = davor/danach, Mitte = hinein; OnNodeDrop kann ablehnen.
- Ereignisse: OnChange auch bei Selected im Code (wie TTreeView); Aufklappen ruft OnExpanding auch aus dem Code (noetig fuer Lazy Loading).
- Streaming: Items als lesbare Zeilenliste ("Items.Nodes"); binaere TTreeView-Knoten aus alten DFMs werden nicht gelesen.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Images`, `AllowMarkup`, `AllowReorder`, `ScrollBarMode`, `SmoothScrolling`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Anchors`, `AutoCheck`, `AutoExpand`, `BiDiMode`, `BorderStyle`, `CheckBoxes`, `Color`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `Font`, `HideSelection`, `Indent`, `ItemHeight`, `Items`, `MultiSelect`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ReadOnly`, `RowSelect`, `ShowButtons`, `ShowHint`, `ShowLines`, `ShowRoot`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnChange`, `OnChanging`, `OnChecked`, `OnClick`, `OnCollapsed`, `OnCollapsing`, `OnCompare`, `OnContextPopup`, `OnDblClick`, `OnDeletion`, `OnDragDrop`, `OnDragOver`, `OnEdited`, `OnEditing`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnExpanded`, `OnExpanding`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnNodeDrop`, `OnScroll`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGTreeView.md`.
