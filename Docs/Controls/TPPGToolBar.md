# TPPGToolBar

Palette **PPGlow** - Unit `PPG.ToolBar` - Basis `TPPGCustomControl`

**Vorbild:** TToolBar

## Unterschiede und Hinweise

- Einträge (`Items`) statt Kind-Buttons; daher kein automatischer Umstieg von `TToolBar`/`TToolButton`.
- Überlauf als natives Kontextmenü; Actions über `Items[].Action`.

## Verhalten (aus dem Quelltext)

TPPGToolBar - Befehlsleiste (Phase 7c, wie WinUI CommandBar).

- Items: Buttons, Umschalt-Buttons (tisCheck, mit GroupIndex wie Radiobuttons) und Trenner; Symbol aus Images oder der Symbolschrift (IconChar), Text wahlweise daneben (ShowCaptions).
- Optik aus dem Preset: Hover/gedrueckt/eingerastet ueber den Renderer wie TPPGButton, in Ruhe flach.
- Ueberlauf: Was nicht in die Breite passt, landet in einem "..."-Menue am Ende (natives Kontextmenue mit Haken fuer Umschalt-Buttons).
- Actions: Item.Action verbindet Caption, Hint, Enabled, Checked, Visible, ImageIndex und OnExecute; die Leiste aktualisiert die Actions im Leerlauf (InitiateAction) wie die VCL-Controls.
- Tastatur: Links/Rechts, Pos1/Ende, Enter/Leertaste.
- Code (Down := ...) loest kein Ereignis aus; ein Klick loest Item.OnClick (bzw. Action.Execute) und danach OnItemClick aus.
- Screenreader: Symbolleiste; Kinder Buttons/Umschalt-Buttons/Trenner und der Ueberlauf-Knopf.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `HighContrastSupport`, `Images`, `Items`, `ShowCaptions`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `Color`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnEnter`, `OnExit`, `OnItemClick`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGToolBar.md`.
