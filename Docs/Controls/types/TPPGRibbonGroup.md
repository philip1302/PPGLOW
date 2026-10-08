# TPPGRibbonGroup

Typ in Unit `PPG.Ribbon.Items` - Basis `TCollectionItem`

Eine Gruppe auf einer Registerkarte mit ihren Befehlen; schrumpft bei wenig Platz bis zu einem einzelnen Dropdown-Knopf.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Caption` | `string` |  | Beschriftung der Gruppe (unter den Befehlen). |
| `Items` | [TPPGRibbonItems](TPPGRibbonItems.md) |  | Die Befehle der Gruppe. Nutzung: `G.Items.AddButton('Kopieren', $E8C8, rsMedium, KopierenClick);` |
| `ReduceOrder` | `Integer` | `0` | Reihenfolge beim Schrumpfen, wenn das Ribbon schmaler wird: kleinere Werte schrumpfen zuerst, bei gleichem Wert die Gruppe weiter rechts. |
| `Visible` | `Boolean` | `True` | False blendet die Gruppe aus. |
| `KeyTip` | `string` |  | Zugriffstaste der zu einem Dropdown geschrumpften Gruppe ('' = automatisch). |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Bild der geschrumpften Gruppe (aus Ribbon.LargeImages bzw. Images); -1 = keins. |
| `IconChar` | `Word` | `0` | Symbol der geschrumpften Gruppe aus der Symbolschrift (0 = keins), z. B. $E8C8. |
| `ShowLauncher` | `Boolean` | `False` | True: Kleiner Pfeil unten rechts in der Gruppe, der einen Dialog öffnet (Ereignis OnLauncherClick des Ribbons). |
| `LauncherHint` | `string` |  | Tooltip des Pfeils unten rechts. |
| `Tag` | `NativeInt` | `0` | Freier Ganzzahlwert für eigene Zwecke. |

## Verwendet in

[TPPGRibbonGroups](TPPGRibbonGroups.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
