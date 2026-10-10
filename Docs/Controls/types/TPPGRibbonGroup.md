# TPPGRibbonGroup

Typ in Unit `PPG.Ribbon.Items` - Basis `TCollectionItem`

Eine Gruppe auf einer Registerkarte mit ihren Befehlen; schrumpft bei wenig Platz bis zu einem einzelnen Dropdown-Knopf.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Caption` | `string` |  | Beschriftung der Gruppe (unter den Befehlen). Praxis: Kurz und beschreibend (Zwischenablage, Beleg, Ansicht); der Text steht unter den Befehlen und erscheint auch auf dem Dropdown der geschrumpften Gruppe. |
| `Items` | [TPPGRibbonItems](TPPGRibbonItems.md) |  | Die Befehle der Gruppe. Nutzung: `G.Items.AddButton('Kopieren', $E8C8, rsMedium, KopierenClick);` Praxis: Die Befehle der Gruppe: die wichtigsten groß (rsLarge), weitere klein und gestapelt. Mehr als sechs bis acht Befehle besser auf zwei Gruppen verteilen. |
| `ReduceOrder` | `Integer` | `0` | Reihenfolge beim Schrumpfen, wenn das Ribbon schmaler wird: kleinere Werte schrumpfen zuerst, bei gleichem Wert die Gruppe weiter rechts. Praxis: Selten genutzte Gruppen bekommen kleine Werte und schrumpfen zuerst; die wichtigste Gruppe einen hohen Wert, damit sie am längsten groß bleibt. |
| `Visible` | `Boolean` | `True` | False blendet die Gruppe aus. Praxis: Ganze Gruppen ausblenden, die in einer Ausgabe oder für eine Rolle nicht verfügbar sind. |
| `KeyTip` | `string` |  | Zugriffstaste der zu einem Dropdown geschrumpften Gruppe ('' = automatisch). Praxis: Nur bei Kollisionen setzen; der KeyTip öffnet die zum Dropdown geschrumpfte Gruppe per Tastatur. |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Bild der geschrumpften Gruppe (aus Ribbon.LargeImages bzw. Images); -1 = keins. Praxis: Wie IconChar, aber aus der Bildliste; nur nötig, wenn die Gruppe auf schmalen Bildschirmen zum Dropdown schrumpft. |
| `IconChar` | `Word` | `0` | Symbol der geschrumpften Gruppe aus der Symbolschrift (0 = keins), z. B. $E8C8. Praxis: Symbol für die als Dropdown geschrumpfte Gruppe setzen, wenn das erste Item keines hat oder ein allgemeineres besser passt. |
| `ShowLauncher` | `Boolean` | `False` | True: Kleiner Pfeil unten rechts in der Gruppe, der einen Dialog öffnet (Ereignis OnLauncherClick des Ribbons). Praxis: Einschalten, wenn es zur Gruppe einen ausführlichen Dialog gibt (Schrift, Absatz, Seite einrichten); den Dialog in OnLauncherClick öffnen. |
| `LauncherHint` | `string` |  | Tooltip des Pfeils unten rechts. Praxis: Den Dialog nennen, den der Pfeil öffnet, z. B. „Seite einrichten (Strg+Umschalt+P)". |
| `Tag` | `NativeInt` | `0` | Freier Ganzzahlwert für eigene Zwecke. Praxis: Z. B. eine Gruppen-ID, um in OnLauncherClick den passenden Dialog zu wählen. |

## Verwendet in

[TPPGRibbonGroups](TPPGRibbonGroups.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
