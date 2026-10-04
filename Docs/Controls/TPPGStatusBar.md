# TPPGStatusBar

Palette **PPGlow** - Unit `PPG.StatusBar` - Basis `TPPGCustomControl`

**Vorbild:** TStatusBar

## Unterschiede und Hinweise

- DFM wie `TStatusBar` (`Panels`, `SimplePanel`); zusätzlich Panel-Arten Fortschritt und Plakette.
- Eigene Schrift schaltet `UseSystemFont` ab (wie `TStatusBar`).

## Verhalten (aus dem Quelltext)

TPPGStatusBar - Statusleiste (Phase 7c).

- Panels wie TStatusBar (Text, Width, Alignment, Bevel, Style); Bevel <> pbNone zeichnet eine Trennlinie. Zusaetzlich Kind: Text (optional mit Markup, AllowMarkup), Fortschrittsbalken (Progress 0..100) oder Plakette (BadgeCount); Bild aus Images (ImageIndex). Das letzte Panel fuellt den Rest, wenn seine Breite nicht reicht.
- SimplePanel/SimpleText, AutoHint (Hinweise der Anwendung im ersten Panel bzw. SimpleText, ueber THintAction wie TStatusBar).
- SizeGrip: Griff unten rechts (RTL links); Ziehen veraendert die Groesse des Formulars, nur wenn es sizable und nicht maximiert ist.
- psOwnerDraw: OnDrawPanel mit Canvas (TCanvas ueber dem Zeichenpuffer).
- DFM-nah zu TStatusBar (Panels, SimplePanel, SimpleText, SizeGrip, AutoHint, UseSystemFont, OnDrawPanel).
- Screenreader: Statusleiste; Kinder sind die Panels (Text/Fortschritt).

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `HighContrastSupport`, `Images`, `Panels`, `SimplePanel`, `SimpleText`, `SizeGrip`, `AutoHint`, `UseSystemFont`, `AllowMarkup`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `Color`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `Visible`

## Ereignisse

`OnClick`, `OnContextPopup`, `OnDblClick`, `OnDrawPanel`, `OnHint`, `OnMouseDown`, `OnMouseMove`, `OnMouseUp`, `OnResize`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGStatusBar.md`.
