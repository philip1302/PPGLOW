# TPPGToolItem

Typ in Unit `PPG.ToolBar` - Basis `TCollectionItem`

Ein Element der Werkzeugleiste: Art, Beschriftung, Bild, Action, Umschaltzustand, Menü sowie eigene Farben.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Action` | `TBasicAction` |  | Verknüpfte Action: Caption, Hint, Enabled, Checked, Visible, ImageIndex und Ausführen kommen aus ihr; die Leiste aktualisiert sie im Leerlauf. Praxis: Für Befehle, die auch im Menü oder per Tastenkürzel stehen: eine Action zuweisen. Caption, Hint, Enabled und Checked kommen dann aus ihr; actSpeichern.Enabled := False sperrt alle Stellen auf einmal. |
| `Caption` | `string` |  | Beschriftung des Befehls (sichtbar mit ShowCaptions). Praxis: Kurz und als Verb oder Substantiv („Neu", „Drucken"). Ein & wird nur ausgeblendet, es vergibt keine Zugriffstaste; bei ShowCaptions = False dient die Caption als Tooltip. |
| `Hint` | `string` |  | Tooltip des Befehls. Praxis: Tooltip mit Zweck und Tastenkürzel, z. B. „Kunden entfernen (Entf)". Pflicht bei ShowCaptions = False, wenn die Caption allein nicht genügt. |
| `Style` | `TPPGToolItemStyle` | `tisButton` | Art: tisButton (Befehl), tisCheck (Umschalt-Button) oder tisSeparator (Trennlinie). Werte: `tisButton`, `tisCheck`, `tisSeparator`. Praxis: tisButton für Befehle, tisCheck für Ein/Aus-Zustände (Filter, Fett, Ansicht), tisSeparator, um zusammengehörige Befehle zu gruppieren. |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Bild aus ToolBar.Images; -1 = keins. Praxis: Bild aus ToolBar.Images, wenn Ihre Anwendung eigene Symbole hat. Hat ImageIndex ein Bild, gilt es statt IconChar. |
| `ImageName` | `TImageName` |  | Bild per Namen aus den Images des Besitzers (TVirtualImageList, ab Delphi 10.4). Robust gegen Umsortieren; setzt ImageIndex passend, ein unbekannter Name ergibt „kein Bild". Nutzung: `ToolBar1.Images := VirtualImageList1; ToolBar1.Items[0].ImageName := 'save';` Praxis: Ab Delphi 10.4 statt ImageIndex: Der Name bleibt richtig, wenn die Bildliste umsortiert wird. |
| `IconChar` | `Word` | `0` | Symbol aus der Icon-Schrift als Zeichencode (0 = keins); Alternative zu ImageIndex. Praxis: Symbol aus Segoe Fluent Icons bzw. Segoe MDL2 Assets ohne Bildliste, z. B. $E710 (Neu), $E74E (Speichern), $E749 (Drucken). Färbt sich automatisch in der Textfarbe. |
| `GroupIndex` | `Integer` | `0` | Umschalt-Buttons (tisCheck) mit gleichem GroupIndex <> 0 schließen sich gegenseitig aus wie Radiobuttons. Praxis: Gleiche Zahl > 0 für Umschalt-Buttons, von denen genau einer gedrückt ist, z. B. 1 für Ansicht „Liste / Kacheln / Details". 0 für einzelne Umschalter wie „Nur aktive". |
| `Down` | `Boolean` | `False` | Eingerastet (nur Style = tisCheck); Setzen im Code ohne Ereignis. Praxis: Zustand eines Umschalt-Buttons lesen oder setzen, z. B. itFett.Down := Text.Fett beim Wechsel des Absatzes. Setzen im Code löst kein Ereignis aus. |
| `Enabled` | `Boolean` | `True` | False: Befehl grau und nicht auslösbar. Praxis: Befehle sperren, die gerade nicht gehen, z. B. „Bearbeiten" ohne ausgewählten Datensatz. Mit Action besser deren Enabled setzen. |
| `Visible` | `Boolean` | `True` | False: Befehl ausgeblendet. Praxis: Befehle ausblenden, die der Anwender nicht nutzen darf (fehlendes Recht). Was nur gerade nicht geht, besser mit Enabled sperren. |
| `Tag` | `NativeInt` | `0` | Freier Ganzzahlwert, z. B. eine Befehls-ID. Praxis: Befehls-ID für ein gemeinsames OnItemClick, am besten als Konstante (cmdNeu = 1, cmdDrucken = 2 …): case Item.Tag of … |
| `Color` | `TColor` | `clDefault` | Eigene Flächenfarbe – auch in Ruhe, z. B. um die Hauptaktion hervorzuheben; clDefault = flach nach Preset. Nutzung: `PPGToolBar1.Items[0].Color := $00D77800; PPGToolBar1.Items[0].TextColor := clWhite;` Praxis: Nur für die eine Hauptaktion der Leiste, z. B. „Speichern" oder „Neuer Auftrag" in der Akzentfarbe; zusammen mit TextColor = clWhite. Die übrigen Befehle bleiben flach. |
| `TextColor` | `TColor` | `clDefault` | Eigene Textfarbe dieses Befehls; clDefault = vom Preset. Praxis: Eigene Schriftfarbe, meist zusammen mit Color (Weiß auf Akzent) oder Rot für einen „Löschen"-Befehl. Gesperrte Befehle bleiben trotzdem grau. |
| `FontStyle` | `TFontStyles` | `[]` | Zusätzliche Schriftstile nur für diesen Befehl; die Breite wird mit dieser Schrift gemessen. Praxis: [fsBold] für die Hauptaktion, damit sie auch ohne Farbe auffällt. Die Breite des Befehls passt sich an. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Der Befehl wurde ausgelöst; danach folgt ToolBar.OnItemClick. Praxis: Die Aktion genau dieses Befehls. Für viele Befehle mit ähnlicher Logik ist ein gemeinsames ToolBar.OnItemClick übersichtlicher; mit Action führt die Action den Befehl aus. |

## Verwendet in

[TPPGToolItems](TPPGToolItems.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
