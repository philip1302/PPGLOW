# TPPGStatusPanel

Typ in Unit `PPG.StatusBar` - Basis `TCollectionItem`

Ein Feld der Statusleiste: Text, Breite, Ausrichtung, Symbol, Plakette sowie eigene Farben.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Alignment` | `TAlignment` | `taLeftJustify` | Ausrichtung von Text bzw. Inhalt im Feld (links, zentriert, rechts). |
| `Bevel` | `TStatusPanelBevel` | `pbLowered` | Trennlinie zum nächsten Feld: pbNone = keine, pbLowered/pbRaised = Linie. |
| `Style` | `TStatusPanelStyle` | `psText` | psText (Standard) oder psOwnerDraw (Inhalt über StatusBar.OnDrawPanel). |
| `Text` | `string` |  | Text des Felds. |
| `Width` | `Integer` | `50` | Breite in Pixeln (ab 0); das letzte Feld füllt den Rest, wenn seine Breite nicht reicht. |
| `Kind` | `TPPGStatusPanelKind` | `spkText` | Inhalt: spkText (Text, optional mit Markup), spkProgress (Fortschrittsbalken, Progress) oder spkBadge (Plakette, BadgeCount). Werte: `spkText`, `spkProgress`, `spkBadge`. |
| `Progress` | `Integer` | `0` | Fortschritt in Prozent bei Kind = spkProgress (0..100, wird begrenzt). |
| `BadgeCount` | `Integer` | `0` | Zahl auf der Plakette bei Kind = spkBadge (0 = Text statt Zahl). |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Bild aus StatusBar.Images vor dem Inhalt; -1 = keins. |
| `ImageName` | `TImageName` |  | Bild per Namen aus den Images des Besitzers (TVirtualImageList, ab Delphi 10.4). Robust gegen Umsortieren; setzt ImageIndex passend, ein unbekannter Name ergibt „kein Bild". |
| `Hint` | `string` |  | Beschreibung des Felds; der Screenreader liest sie vor dem Fortschritt bzw. der Plakette vor (z. B. „Upload: 40 %"). |
| `Color` | `TColor` | `clDefault` | Eigene Flächenfarbe dieses Felds; clDefault = wie die Leiste. Zusammen mit TextColor und FontStyle z. B. für Warnungen. Nutzung: `PPGStatusBar1.Panels[1].Color := $00C0E0FF;` |
| `TextColor` | `TColor` | `clDefault` | Eigene Textfarbe dieses Felds; clDefault = wie die Leiste. |
| `FontStyle` | `TFontStyles` | `[]` | Zusätzliche Schriftstile nur für dieses Feld. |

## Verwendet in

[TPPGStatusPanels](TPPGStatusPanels.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
