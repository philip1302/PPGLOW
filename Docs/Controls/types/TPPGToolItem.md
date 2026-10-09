# TPPGToolItem

Typ in Unit `PPG.ToolBar` - Basis `TCollectionItem`

Ein Element der Werkzeugleiste: Art, Beschriftung, Bild, Action, Umschaltzustand, Menü sowie eigene Farben.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Action` | `TBasicAction` |  | Verknüpfte Action: Caption, Hint, Enabled, Checked, Visible, ImageIndex und Ausführen kommen aus ihr; die Leiste aktualisiert sie im Leerlauf. |
| `Caption` | `string` |  | Beschriftung des Befehls (sichtbar mit ShowCaptions). |
| `Hint` | `string` |  | Tooltip des Befehls. |
| `Style` | `TPPGToolItemStyle` | `tisButton` | Art: tisButton (Befehl), tisCheck (Umschalt-Button) oder tisSeparator (Trennlinie). Werte: `tisButton`, `tisCheck`, `tisSeparator`. |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Bild aus ToolBar.Images; -1 = keins. |
| `ImageName` | `TImageName` |  | Bild per Namen aus den Images des Besitzers (TVirtualImageList, ab Delphi 10.4). Robust gegen Umsortieren; setzt ImageIndex passend, ein unbekannter Name ergibt „kein Bild". Nutzung: `ToolBar1.Images := VirtualImageList1; ToolBar1.Items[0].ImageName := 'save';` |
| `IconChar` | `Word` | `0` | Symbol aus der Icon-Schrift als Zeichencode (0 = keins); Alternative zu ImageIndex. |
| `GroupIndex` | `Integer` | `0` | Umschalt-Buttons (tisCheck) mit gleichem GroupIndex <> 0 schließen sich gegenseitig aus wie Radiobuttons. |
| `Down` | `Boolean` | `False` | Eingerastet (nur Style = tisCheck); Setzen im Code ohne Ereignis. |
| `Enabled` | `Boolean` | `True` | False: Befehl grau und nicht auslösbar. |
| `Visible` | `Boolean` | `True` | False: Befehl ausgeblendet. |
| `Tag` | `NativeInt` | `0` | Freier Ganzzahlwert, z. B. eine Befehls-ID. |
| `Color` | `TColor` | `clDefault` | Eigene Flächenfarbe – auch in Ruhe, z. B. um die Hauptaktion hervorzuheben; clDefault = flach nach Preset. Nutzung: `PPGToolBar1.Items[0].Color := $00D77800; PPGToolBar1.Items[0].TextColor := clWhite;` |
| `TextColor` | `TColor` | `clDefault` | Eigene Textfarbe dieses Befehls; clDefault = vom Preset. |
| `FontStyle` | `TFontStyles` | `[]` | Zusätzliche Schriftstile nur für diesen Befehl; die Breite wird mit dieser Schrift gemessen. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Der Befehl wurde ausgelöst; danach folgt ToolBar.OnItemClick. |

## Verwendet in

[TPPGToolItems](TPPGToolItems.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
