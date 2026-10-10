# TPPGChoiceItem

Typ in Unit `PPG.RadioGroup` - Basis `TCollectionItem`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Caption` | `string` |  | Beschriftung des Eintrags. Praxis: Kurz und eindeutig formulieren, mit & für die Zugriffstaste („&E-Mail“). Für Datenbank und Code besser Value setzen, damit eine geänderte Beschriftung gespeicherte Daten nicht ungültig macht. |
| `Description` | `string` |  | Zweite Zeile unter dem Titel (Kacheln) bzw. gedämpfter Zusatz in der Liste. Praxis: Vor allem für Kacheln: ein kurzer Satz, was die Option bedeutet („Lieferung morgen“, „Adressen und Kontakte“). In der Liste nur für wichtige Zusätze verwenden. |
| `Icon` | `Word` | `0` | Zeichen der Symbolschrift (Segoe Fluent Icons bzw. MDL2), z. B. $E80F; 0 = kein Symbol. Wird nur gezeigt, wenn ImageIndex -1 ist. Praxis: Für Kacheln und Segmente ein Zeichen der Symbolschrift, z. B. $E716 (Personen) für „Kunden“. Einheitlich einfarbige Symbole wirken ruhiger als bunte Bilder. |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Bild aus Images der Gruppe; hat Vorrang vor Icon. -1 = kein Bild. Praxis: Wenn ein farbiges Bild aus Images nötig ist, z. B. Logos von Versanddienstleistern; sonst reicht Icon. |
| `Enabled` | `Boolean` | `True` | False: Eintrag grau und nicht wählbar; die übrigen bleiben bedienbar. Praxis: Optionen sperren, die gerade nicht möglich sind, z. B. SMS ohne Mobilnummer, statt sie auszublenden. Den Grund in Hint nennen. |
| `Hint` | `string` |  | Hinweis, wenn die Maus über diesem Eintrag steht (ShowHint der Gruppe muss an sein). Praxis: Erklärt einen Eintrag, besonders einen gesperrten („Erst eine Mobilnummer eintragen“). Erscheint nur mit ShowHint an der Gruppe bzw. am Formular. |
| `Value` | `string` |  | Wert für Programm und Datenbank; leer = Caption. Bei der CheckGroup ergibt Value der Gruppe die Kommaliste der angehakten Werte. Praxis: Ein festes Kürzel für Datenbank und Programm setzen („mail“, „sms“), dann bleibt die gespeicherte Auswahl gültig, auch wenn die Beschriftung übersetzt oder umformuliert wird. |
| `State` | `TCheckBoxState` | `cbUnchecked` | Nur CheckGroup: Zustand des Kästchens (cbUnchecked, cbChecked, cbGrayed mit AllowGrayed). Praxis: Zustand im Code lesen oder setzen, z. B. beim Laden gespeicherter Rechte; cbGrayed nur mit AllowGrayed an der CheckGroup. Setzen im Code löst kein Ereignis aus. |

## Verwendet in

[TPPGChoiceItems](TPPGChoiceItems.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
