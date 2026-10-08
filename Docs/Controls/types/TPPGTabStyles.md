# TPPGTabStyles

Typ in Unit `PPG.TabStrip` - Basis `TPPGStyleGroup`

Bereiche der Reiterleiste. Nur gesetzte Werte zaehlen (clDefault = Preset).

Bereiche der Reiterleiste einzeln gestalten: Reiter, Reiter unter der Maus, aktiver Reiter, Leiste und Indikator.

Nutzung: `PPGPageControl1.TabStyles.ActiveTab.FontStyle := [fsBold];`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Tab` | [TPPGElementStyle](TPPGElementStyle.md) |  | Nicht gewählte Reiter: Color, TextColor, BorderColor und Schrift. |
| `HotTab` | [TPPGElementStyle](TPPGElementStyle.md) |  | Reiter unter der Maus (mit HotTrack = True). |
| `ActiveTab` | [TPPGElementStyle](TPPGElementStyle.md) |  | Gewählter Reiter: Fläche, Text, Rand und Schrift. |
| `Strip` | [TPPGElementStyle](TPPGElementStyle.md) |  | Fläche hinter den Reitern (Color). |
| `Indicator` | [TPPGElementStyle](TPPGElementStyle.md) |  | Unterstrich des gewählten Reiters (Color). |

## Verwendet in

[TPPGPageControl](../TPPGPageControl.md), [TPPGTabControl](../TPPGTabControl.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
