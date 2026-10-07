# TPPGPanel

Palette **PPGlow** - Unit `PPG.Panel` - Basis `TPPGCustomPanel`

**Vorbild:** TPanel

## Unterschiede und Hinweise

- Container ohne `AutoSize`.
- Kinder auf dem Panel zeichnen ihren Hintergrund über den schnellen Eltern-Hintergrund (`GetChildBackground`).

## Verhalten (aus dem Quelltext)

TPPGPanel - Container-Flaeche in der Optik des Presets (abgerundet,
Rahmen, im Classic-Preset mit dezentem Verlauf).

Migration von TPanel: Caption, Alignment, VerticalAlignment, ShowCaption,
Padding und die Bevel-Properties bleiben gueltig (Bevels zeichnet nur die
VCL selbst bei BevelKind <> bkNone). Color bestimmt nur den Hintergrund
hinter den abgerundeten Ecken (ParentBackground = False); die Flaeche kommt
aus Appearance.Normal.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Alignment`, `VerticalAlignment`, `ShowCaption`, `WordWrap`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Anchors`, `BevelEdges`, `BevelInner`, `BevelKind`, `BevelOuter`, `BevelWidth`, `BiDiMode`, `BorderWidth`, `Caption`, `Color`, `Constraints`, `DockSite`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `Font`, `Padding`, `ParentBackground`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `UseDockManager`, `Visible`

## Ereignisse

`OnAlignInsertBefore`, `OnAlignPosition`, `OnClick`, `OnContextPopup`, `OnDblClick`, `OnDockDrop`, `OnDockOver`, `OnDragDrop`, `OnDragOver`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnGetSiteInfo`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnResize`, `OnStartDock`, `OnStartDrag`, `OnUnDock`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGPanel.md`.
