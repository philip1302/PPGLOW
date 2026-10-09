# TPPGPanelScrollBar

Typ in Unit `PPG.Panel` - Basis `TPersistent`

Einstellungen einer Leiste (DFM-kompatibel zu TControlScrollBar).

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Visible` | `Boolean` | `True` | False: diese Richtung nie scrollen, auch wenn Inhalt herausragt. |
| `Range` | `Integer` | `0` | Inhaltsgröße in Pixeln; mit AutoScroll aus den Kind-Controls berechnet, sonst fest (wie TControlScrollBar.Range). |
| `Increment` | `Integer` | `8` | Schritt in Pixeln für Pfeiltasten und einen Klick auf die Leiste (Mausrad: 48 logische Pixel je Rastung). |
| `Position` | `Integer` | `0` | Aktuelle Scrollposition in Pixeln (0 = oben bzw. links); Setzen verschiebt den Inhalt. |
| `Tracking` | `Boolean` | `False` | Der Inhalt folgt dem Daumen schon beim Ziehen (sonst erst beim Loslassen). |
| `Smooth` | `Boolean` | `True` | Weiches Scrollen beim Mausrad und Klick in die Spur. |

## Verwendet in

[TPPGPanel](../TPPGPanel.md), [TPPGScrollBox](../TPPGScrollBox.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
