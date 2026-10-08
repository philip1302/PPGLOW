# TPPGNavItem

Typ in Unit `PPG.NavigationView` - Basis `TCollectionItem`

Ein Eintrag der Navigationsleiste: Text, Symbol, Plakette, Untereinträge, Überschrift oder Trennlinie, Fußbereich sowie eigene Farben.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Caption` | `string` |  | Text des Eintrags; in der kompakten Leiste als Tooltip. |
| `Kind` | `TPPGNavItemKind` | `nikItem` | Art: nikItem (wählbarer Eintrag), nikHeader (Gruppenüberschrift) oder nikSeparator (Trennlinie). Werte: `nikItem`, `nikHeader`, `nikSeparator`. |
| `IconChar` | `Word` | `0` | Symbol aus der Icon-Schrift (Segoe Fluent Icons bzw. MDL2) als Zeichencode; 0 = keins (dann ImageIndex). Nutzung: `Item.IconChar := $E80F; // Start` |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Bild aus NavigationView.Images, wenn IconChar = 0; -1 = kein Bild. |
| `BadgeCount` | `Integer` | `0` | Zahl auf der Plakette des Eintrags (z. B. ungelesene Nachrichten); 0 = keine Zahl. Nutzung: `PPGNavigationView1.Items[2].BadgeCount := 12;` |
| `BadgeDot` | `Boolean` | `False` | True: Ein Punkt statt einer Zahl weist auf Neues hin (wird gezeigt, solange BadgeCount = 0). |
| `Enabled` | `Boolean` | `True` | False: Eintrag grau und nicht wählbar. |
| `Visible` | `Boolean` | `True` | False: Eintrag ausgeblendet. |
| `Footer` | `Boolean` | `False` | True: Eintrag steht im Fußbereich unten in der Leiste (typisch „Einstellungen"). |
| `PageIndex` | `Integer` | `-1` | Seite im verbundenen PageControl, die bei Auswahl gezeigt wird; -1 = keine. |
| `Expanded` | `Boolean` | `False` | True: Untereinträge (Items) sind aufgeklappt. Der Anwender klappt per Klick bzw. Rechts/Links. |
| `Hint` | `string` |  | Tooltip des Eintrags (zusätzlich zum Text in der kompakten Leiste). |
| `Tag` | `NativeInt` | `0` | Freier Ganzzahlwert, z. B. eine Befehls-ID für OnItemInvoked. |
| `Items` | [TPPGNavItems](TPPGNavItems.md) |  | Untereinträge; der Eintrag wird damit aufklappbar. |
| `Color` | `TColor` | `clDefault` | Eigene Flächenfarbe dieses Eintrags; clDefault = aus NavStyles. Zusammen mit TextColor und FontStyle zum Hervorheben einzelner Einträge. |
| `TextColor` | `TColor` | `clDefault` | Eigene Textfarbe dieses Eintrags; clDefault = aus NavStyles. |
| `FontStyle` | `TFontStyles` | `[]` | Zusätzliche Schriftstile nur für diesen Eintrag, z. B. [fsBold]. |

## Verwendet in

[TPPGNavItems](TPPGNavItems.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
