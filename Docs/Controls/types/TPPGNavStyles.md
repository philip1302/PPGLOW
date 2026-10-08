# TPPGNavStyles

Typ in Unit `PPG.NavigationView` - Basis `TPPGStyleGroup`

Bereiche der Navigation (nur gesetzte Werte zaehlen, clDefault = Preset).

Bereiche der Navigationsleiste einzeln gestalten (Fläche, Einträge, Auswahl, Indikator, Überschriften …).

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Pane` | [TPPGElementStyle](TPPGElementStyle.md) |  | Die Leiste selbst: Color = Hintergrund, TextColor = Text, BorderColor = Trennlinie zum Inhalt. |
| `Item` | [TPPGElementStyle](TPPGElementStyle.md) |  | Einträge in Ruhe: Fläche, Text, Schrift. |
| `HotItem` | [TPPGElementStyle](TPPGElementStyle.md) |  | Eintrag unter der Maus: Fläche und Text. |
| `SelectedItem` | [TPPGElementStyle](TPPGElementStyle.md) |  | Gewählter Eintrag: Fläche, Text und Schrift. |
| `Header` | [TPPGElementStyle](TPPGElementStyle.md) |  | Gruppenüberschriften (Kind = nikHeader): Textfarbe und Schrift. |
| `Indicator` | [TPPGElementStyle](TPPGElementStyle.md) |  | Der gleitende Auswahl-Indikator neben dem gewählten Eintrag (Color). |
| `PaneTitle` | [TPPGElementStyle](TPPGElementStyle.md) |  | Titel der Leiste (PaneTitle): Textfarbe und Schrift. |

## Verwendet in

[TPPGNavigationView](../TPPGNavigationView.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
