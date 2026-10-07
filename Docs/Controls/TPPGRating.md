# TPPGRating

Palette **PPGlow** - Unit `PPG.Rating` - Basis `TPPGCustomRating`

**Vorbild:** TMS Rating

## Unterschiede und Hinweise

- `Value` im Code löst kein Ereignis aus; halbe Sterne mit `AllowHalf` (gerundet wird erst in `Loaded`).

## Verhalten (aus dem Quelltext)

TPPGRating - Sternebewertung (Phase 7a).

- MaxValue Sterne (Icon-Schrift, sonst gezeichnetes Polygon), Value 0..MaxValue, halbe Sterne mit AllowHalf.
- Hover zeigt eine Vorschau; Klick setzt den Wert. Klick auf den aktuellen Wert loescht ihn (AllowClear).
- Tastatur: Links/Rechts (bzw. Hoch/Runter) +/- 1 (halbe: 0,5), Pos1 = 0, Ende = MaxValue, Ziffern 0..9 setzen direkt. RTL gespiegelt.
- ReadOnly zeigt nur an (keine Vorschau, keine Eingabe, bleibt fokussierbar).
- Code (Value := ...) loest kein OnChange aus; der Anwender schon.
- Screenreader: Rolle Schieberegler, Wert "3,5 / 5".

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `HighContrastSupport`, `Value`, `MaxValue`, `AllowHalf`, `AllowClear`, `ReadOnly`, `StarSize`, `StarSpacing`, `StarColor`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `Constraints`, `Enabled`, `ParentBiDiMode`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnChange`, `OnEnter`, `OnExit`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGRating.md`.
