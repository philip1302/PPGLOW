# TPPGBreadcrumb

Palette **PPGlow** - Unit `PPG.Breadcrumb` - Basis `TPPGCustomBreadcrumb`

**Vorbild:** WinUI BreadcrumbBar

## Unterschiede und Hinweise

- Überlauf als natives Kontextmenü (Screenreader-tauglich).

## Verhalten (aus dem Quelltext)

TPPGBreadcrumb - Pfadleiste aus Segmenten (Phase 7c, wie WinUI BreadcrumbBar).

- Items: Segmente von der Wurzel bis zum aktuellen Ort (letztes Segment), getrennt durch Chevrons. Das letzte Segment ist hervorgehoben.
- Passt der Pfad nicht in die Breite, fallen die vorderen Segmente in ein "..."-Menue am Anfang (Menue im Stil der Suite, Screenreader-tauglich, Phase 11).
- Klick bzw. Enter auf ein Segment loest OnItemClick(Index) aus; mit TruncateOnClick werden die folgenden Segmente entfernt.
- Tastatur: Links/Rechts wechseln das Segment, Pos1/Ende, Enter/Leertaste loesen aus. RTL gespiegelt.
- Screenreader: Kinder sind die sichtbaren Segmente (Link) und der Ueberlauf-Knopf.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `HighContrastSupport`, `Items`, `TruncateOnClick`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnEnter`, `OnExit`, `OnItemClick`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGBreadcrumb.md`.
