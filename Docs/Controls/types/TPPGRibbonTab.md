# TPPGRibbonTab

Typ in Unit `PPG.Ribbon.Items` - Basis `TCollectionItem`

Eine Registerkarte: Beschriftung, Gruppen, KeyTip und Kontext (für farbig markierte Kontext-Registerkarten).

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Caption` | `string` |  | Beschriftung der Registerkarte. |
| `Groups` | [TPPGRibbonGroups](TPPGRibbonGroups.md) |  | Gruppen der Registerkarte, jede mit Beschriftung und Items. |
| `Visible` | `Boolean` | `True` | False: Registerkarte ausgeblendet (typisch für Kontext-Karten). |
| `KeyTip` | `string` |  | Eigener KeyTip der Registerkarte; leer = automatisch aus der Beschriftung. |
| `ContextName` | `string` |  | Name des Kontexts (z. B. „Bildtools"); leer = normale Registerkarte. Benachbarte Karten mit gleichem Namen bilden eine farbige Gruppe; meist zusammen mit Visible nur bei passender Auswahl zeigen. Nutzung: `tabBildFormat.ContextName := 'Bildtools'; tabBildFormat.Visible := BildGewaehlt;` |
| `ContextColor` | `TColor` | `clNone` | Farbe einer Kontext-Registerkarte (Band über der Karte); clNone = Akzentfarbe des Presets. |
| `Tag` | `NativeInt` | `0` | Freier Ganzzahlwert. |

## Verwendet in

[TPPGRibbonTabs](TPPGRibbonTabs.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
