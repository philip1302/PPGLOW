# TPPGExpander

Palette **PPGlow** - Unit `PPG.Expander` - Basis `TPPGCustomExpander`

**Vorbild:** WinUI Expander, TMS CategoryPanel

## Unterschiede und Hinweise

- `Expanded` im Code löst kein Ereignis aus; zugeklappte Kinder sind nicht in der Tab-Reihenfolge.

## Verhalten (aus dem Quelltext)

TPPGExpander - Container mit Kopfzeile, auf- und zuklappbar (Phase 7a).

- Kopfzeile: Titel (Caption), optional Detailtext darunter, Chevron rechts (zeigt zugeklappt nach unten, aufgeklappt nach oben, Drehung animiert).
- Auf-/Zuklappen animiert die Hoehe zwischen Kopfzeile und ExpandedHeight (gemeinsamer Animator, ekDecelerate). Die Kinder bleiben erhalten; im zugeklappten Zustand sind sie per Tab nicht erreichbar.
- Mehrere Expander mit Align = alTop untereinander ergeben ein Kategorie-Panel.
- Code (Expanded := ...) loest keine Ereignisse aus; der Anwender (Klick, Enter/Leertaste, Pfeile, Screenreader-Aktion) loest OnExpanding (abbrechbar) und danach OnExpanded bzw. OnCollapsed aus.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `HighContrastSupport`, `Expanded`, `HeaderStyle`, `Detail`, `ExpandedHeight`

## Eigenschaften wie in der VCL

`Align`, `Anchors`, `BiDiMode`, `Caption`, `Color`, `Constraints`, `Enabled`, `Font`, `Padding`, `ParentBackground`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`, `Touch`

## Ereignisse

`OnGesture`, `OnCollapsed`, `OnContextPopup`, `OnEnter`, `OnExit`, `OnExpanded`, `OnExpanding`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnResize`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGExpander.md`.
