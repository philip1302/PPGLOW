# TPPGShadow

Typ in Unit `PPG.ElementStyle` - Basis `TPersistent`

Schriften fuer einen Zeichenvorgang: Basis-Schrift plus Stil-Abweichungen. Schatten unter einer Flaeche (Elevation). Size = 0: kein Schatten. Werte in logischen px (skaliert); im Hochkontrast nie gezeichnet.

Schatten unter einer Fläche (Elevation). Size = 0 schaltet ihn aus. Alle Maße in logischen Pixeln.

Nutzung: `PPGPanel1.Shadow.Size := 8; PPGPanel1.Shadow.OffsetY := 3;`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Size` | `Integer` | `0` | Weichzeichnung: so weit reicht der Schatten über die Fläche hinaus (0..64; 0 = kein Schatten). |
| `OffsetY` | `Integer` | `2` | Versatz nach unten (negativ: nach oben), -64..64. Größerer Versatz wirkt „höher". |
| `Color` | `TColor` | `clBlack` | Farbe des Schattens (meist Schwarz). |
| `Opacity` | `Integer` | `64` | Deckkraft direkt an der Kante, 0..255; nach außen nimmt sie linear ab. |

## Verwendet in

[TPPGButton](../TPPGButton.md), [TPPGPanel](../TPPGPanel.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
