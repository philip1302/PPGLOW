# TPPGPageControl

Palette **PPGlow** - Unit `PPG.PageControl` - Basis `TPPGCustomTabs`

**Vorbild:** TPageControl / TTabSheet

## Unterschiede und Hinweise

- Seiten (`TPPGTabSheet`) über den Komponenteneditor: „New Page“, „Next/Previous Page“, „Delete Page“.
- Schließen einer Seite blendet standardmäßig nur den Reiter aus (`caHide`).
- Sind alle Reiter ausgeblendet, bleibt die aktive Seite aktiv und die Reiterleiste verschwindet (für die NavigationView).

## Anpassung

- Je TabSheet `TabColor`, `TabTextColor`, `TabFontStyle`; `TabStyles` (Reiter, Hover, aktiv, Leiste, Indikator).
- Wie `TPageControl`: `MultiLine`, `RaggedRight`, `Style`, `OwnerDraw`, `OnDrawTab`.

## Verhalten (aus dem Quelltext)

TPPGPageControl + TPPGTabSheet - Seiten mit Reitern, DFM-kompatibel zu
TPageControl/TTabSheet (ActivePage, TabPosition, TabWidth, TabHeight,
HotTrack, Images; Seiten mit Caption, ImageIndex, PageIndex, TabVisible).

- Seitenliste: Jede TPPGTabSheet, deren Parent das PageControl ist, ist eine Seite (auch per "Sheet.Parent := PC"). Die Reihenfolge ist die Einfuegereihenfolge bzw. PageIndex; GetChildren schreibt sie so in die DFM.
- Nur die aktive Seite ist sichtbar (csNoDesignVisible: auch im Designer).
- Wird die aktive Seite entfernt oder ihr Reiter ausgeblendet, wird die Nachbarseite aktiv (erst die folgende, sonst die vorige).
- Lag der Fokus auf der alten Seite, geht er auf die neue (erstes Control).
- Schliessen-Knopf: OnCloseQuery(Page, CanClose), dann OnClose(Page, Action) mit caHide (Reiter ausblenden, Standard), caFree oder caNone.
- Designer: Klick auf Reiter wechselt die Seite; ein Control auf einer verdeckten Seite auswaehlen zeigt diese (ShowControl). Komponenteneditor "Neue Seite" usw. in PPG.Reg.

## PPGlow-Eigenschaften

`ActivePage`, `Preset`, `StyleManager`, `Appearance`, `Animation`, `ShowCloseButtons`, `TabStyles`, `MultiLine`, `OwnerDraw`, `RaggedRight`, `ScrollOpposite`, `Style`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Anchors`, `BiDiMode`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `Font`, `HotTrack`, `Images`, `ParentBiDiMode`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabHeight`, `TabOrder`, `TabPosition`, `TabStop`, `TabWidth`, `Visible`, `Touch`

## Ereignisse

`OnGesture`, `OnChange`, `OnChanging`, `OnDrawTab`, `OnCustomDrawItem`, `OnClose`, `OnCloseQuery`, `OnContextPopup`, `OnDragDrop`, `OnDragOver`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnResize`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGPageControl.md`.
