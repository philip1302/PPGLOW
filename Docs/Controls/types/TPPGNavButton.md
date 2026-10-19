# TPPGNavButton

Typ in Unit `PPG.DB.Navigator` - Basis `TCollectionItem`

Zusatzknopf des Navigators (CustomButtons): Symbol aus Images/ImageIndex bzw. der Symbolschrift (IconChar), sonst der Text (Caption). Ein Klick loest OnClick des Knopfs und danach OnCustomButtonClick des Navigators aus.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Caption` | `string` |  | Text des Zusatzknopfs, wenn kein Symbol gesetzt ist; ein & wird für den Screenreader entfernt. |
| `Hint` | `string` |  | Hinweistext; bei reinen Symbolknöpfen auch der Name für den Screenreader. |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Bild aus Images des Navigators (-1 = keins). |
| `ImageName` | `TImageName` |  | Bild per Namen aus Images (TVirtualImageList, ab Delphi 10.4). |
| `IconChar` | `Word` | `0` | Zeichen der Symbolschrift (0 = keins); gilt, wenn kein Bild aus Images gesetzt ist. |
| `Enabled` | `Boolean` | `True` | False = gesperrt: grau, kein Klick (Vorgabe True). |
| `Visible` | `Boolean` | `True` | False = ausgeblendet; die folgenden Knöpfe rücken auf (Vorgabe True). |
| `Tag` | `NativeInt` | `0` | Freie Zahl für eigene Zwecke. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick auf den Knopf; Sender ist der TPPGNavButton. Danach folgt OnCustomButtonClick des Navigators. |

## Verwendet in

[TPPGNavButtons](TPPGNavButtons.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
