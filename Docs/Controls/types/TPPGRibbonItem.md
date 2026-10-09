# TPPGRibbonItem

Typ in Unit `PPG.Ribbon.Items` - Basis `TCollectionItem`

Ein Befehl im Ribbon: Art, Größe, Bild bzw. Symbol, Beschriftung, Action, Umschaltzustand, Galerie-Einträge oder eingebettetes Control.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Action` | `TBasicAction` |  | Verknüpfte Action: Beschriftung, Hint, Enabled, Checked, Bild und Ausführen kommen aus ihr. Im Schnellzugriff dient die Action als Schlüssel (SaveQuickAccess). |
| `Caption` | `string` |  | Beschriftung des Befehls; ein & markiert die Zugriffstaste, sonst wird der KeyTip aus der Beschriftung gebildet. |
| `Hint` | `string` |  | Tooltip des Befehls (mit Titel aus Caption). |
| `Kind` | `TPPGRibbonItemKind` | `rikButton` | Art des Items: rikButton, rikSplitButton (Button + Pfeil mit DropDownMenu), rikCheck (Umschalt-Button), rikGallery (Galerie), rikControl (eingebettetes Control) oder rikSeparator (Trennlinie). Werte: `rikButton`, `rikSplitButton`, `rikCheck`, `rikGallery`, `rikControl`, `rikSeparator`. |
| `Size` | `TPPGRibbonSize` | `rsLarge` | Größe, solange die Gruppe genug Platz hat: rsLarge (großes Symbol, Text darunter), rsMedium (kleines Symbol mit Text), rsSmall (nur Symbol). Werte: `rsLarge`, `rsMedium`, `rsSmall`. |
| `MinSize` | `TPPGRibbonSize` | `rsSmall` | Kleinste Größe, auf die das Item schrumpfen darf, wenn die Breite nicht reicht (rsLarge = bleibt groß). Werte: `rsLarge`, `rsMedium`, `rsSmall`. |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Kleines Bild (16 px) aus Ribbon.Images; -1 = keins. |
| `ImageName` | `TImageName` |  | Bild per Namen aus den Images des Besitzers (TVirtualImageList, ab Delphi 10.4). Robust gegen Umsortieren; setzt ImageIndex passend, ein unbekannter Name ergibt „kein Bild". |
| `LargeImageIndex` | `TPPGImageIndex` | `-1` | Großes Bild (32 px) aus Ribbon.LargeImages für Size = rsLarge; -1 = ImageIndex verwenden. |
| `IconChar` | `Word` | `0` | Symbol aus der Icon-Schrift als Zeichencode (0 = keins), z. B. $E8C8 für „Kopieren"; Alternative zu ImageIndex. |
| `GroupIndex` | `Integer` | `0` | Umschalt-Items (rikCheck) mit gleichem GroupIndex <> 0 schließen sich gegenseitig aus (im ganzen Ribbon), z. B. Links/Zentriert/Rechts. |
| `Down` | `Boolean` | `False` | Eingerastet (Kind = rikCheck). Setzen im Code ohne Ereignis; mit GroupIndex wie Radiobuttons. |
| `Enabled` | `Boolean` | `True` | False: Befehl grau und nicht auslösbar. |
| `Visible` | `Boolean` | `True` | False: Item ausgeblendet. |
| `Tag` | `NativeInt` | `0` | Freier Ganzzahlwert, z. B. eine Befehls-ID für OnItemClick. |
| `KeyTip` | `string` |  | Eigener KeyTip (Buchstabe(n) für die Tastaturbedienung nach Alt); leer = automatisch aus der Beschriftung. |
| `BeginColumn` | `Boolean` | `False` | True: Beginnt einen neuen Stapel kleiner bzw. mittlerer Items (bis zu drei Zeilen untereinander). |
| `SameRow` | `Boolean` | `False` | True: Steht rechts neben dem vorigen kleinen Item in derselben Zeile (für kompakte Knopfreihen wie Fett/Kursiv/Unterstrichen). |
| `DropDownMenu` | `TPopupMenu` |  | Menü eines Split-Buttons (rikSplitButton: Pfeilteil) bzw. eines Buttons, der nur aufklappt. |
| `Control` | `TControl` |  | Eingebettetes Control bei Kind = rikControl (z. B. eine ComboBox für die Schriftgröße); das Ribbon wird sein Parent und setzt die Lage. |
| `GalleryItems` | `TStrings` |  | Texte der Galerie-Einträge, einer je Zeile (wenn GalleryCount = 0). |
| `GalleryCount` | `Integer` | `0` | Anzahl virtueller Galerie-Einträge, deren Inhalt OnGetGalleryItem liefert (0..MaxInt); 0 = Einträge aus GalleryItems. |
| `GalleryIndex` | `Integer` | `-1` | Gewählter Galerie-Eintrag (-1 = keiner). |
| `GalleryColumns` | `Integer` | `4` | Spalten der Galerie direkt in der Leiste (1..50). |
| `GalleryPopupColumns` | `Integer` | `0` | Spalten der aufgeklappten Galerie (0..50); 0 = GalleryColumns + 1. |
| `GalleryItemWidth` | `Integer` | `72` | Breite eines Galerie-Eintrags in logischen Pixeln (16..1000). |
| `GalleryItemHeight` | `Integer` | `0` | Höhe eines Galerie-Eintrags in logischen Pixeln (0..1000); 0 = volle Höhe der Leiste. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Das Item wurde ausgelöst; kommt vor Ribbon.OnItemClick. Mit Action wird stattdessen Action.Execute aufgerufen (außer OnClick weicht von OnExecute ab). |

## Verwendet in

[TPPGRibbonItems](TPPGRibbonItems.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
