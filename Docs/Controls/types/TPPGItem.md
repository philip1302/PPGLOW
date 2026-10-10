# TPPGItem

Typ in Unit `PPG.Items` - Basis `TCollectionItem`

Ein Eintrag: Text, Detailzeile, Plakette, Gruppe, Bild, Kästchen-Zustand, Enabled sowie eigene Farbe, Textfarbe und Schriftstil.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Text` | `string` |  | Haupttext des Eintrags; mit AllowMarkup der Liste auch mit <b>, <i>, <color=...>. Praxis: Der Haupttext, nach dem der Anwender sucht: Artikelname, Kundenname. Kurz halten; Nummern und Preise gehören in Detail. |
| `Detail` | `string` |  | Zweite, kleinere Zeile unter dem Text (Optik über Styles.Detail); leer = einzeilig. Praxis: Zusatzinfo in der zweiten Zeile, die bei der Wahl hilft: „Art.-Nr. 10014 · 899,00 €“ oder die Adresse unter dem Kundennamen. |
| `Badge` | `string` |  | Kurzer Text in einer Plakette rechts im Eintrag (z. B. Anzahl ungelesener Nachrichten); leer = keine Plakette. Praxis: Kurze Kennzeichnung rechts, z. B. „neu“, „Aktion“ oder eine Anzahl. Sparsam einsetzen, sonst geht die Wirkung verloren. |
| `Group` | `string` |  | Gruppenname: Aufeinanderfolgende Einträge mit derselben Gruppe erhalten eine gemeinsame Überschrift (Optik über Styles.GroupHeader). Praxis: Einträge nach Gruppe sortiert anlegen (z. B. „Hardware“, „Software“); in Listen mit Gruppenköpfen erscheint die Überschrift einmal je Gruppe. |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Bild aus Images der Liste; -1 = kein Bild. Praxis: Symbol aus Images der Liste, z. B. eine Flagge je Land oder ein Status-Symbol je Auftrag. -1 für Einträge ohne Bild. |
| `Checked` | `TCheckBoxState` | `cbUnchecked` | Zustand des Kästchens (CheckListBox): cbUnchecked, cbChecked oder cbGrayed. Praxis: Nur in Listen mit Kästchen (CheckListBox) sichtbar: den Haken beim Laden setzen, z. B. für bereits zugeordnete Rechte. |
| `Enabled` | `Boolean` | `True` | False: Der Eintrag ist grau und nicht wählbar. Praxis: Einträge zeigen, aber sperren, z. B. ein Lager ohne Bestand. So sieht der Anwender, dass es den Eintrag gibt, er aber gerade nicht wählbar ist. |
| `Tag` | `NativeInt` | `0` | Freier Ganzzahlwert, z. B. eine Datensatz-ID. Praxis: Die ID des Datensatzes ablegen (Artikel-ID, Kunden-Nr.), damit man nach der Wahl nicht über den Text suchen muss. |
| `Color` | `TColor` | `clDefault` | Eigene Fläche dieses Eintrags; clDefault = wie die Liste. Gilt hell und dunkel; Auswahl und Hover liegen darüber. Praxis: Einzelne Einträge farbig hinterlegen, z. B. überfällige Aufträge hellrot. Sparsam einsetzen und nicht als einziges Merkmal (Farbenblindheit). |
| `TextColor` | `TColor` | `clDefault` | Eigene Textfarbe dieses Eintrags; clDefault = wie die Liste. Praxis: Eigene Schriftfarbe, z. B. Grau für auslaufende Artikel. Auf Kontrast zur Fläche achten. |
| `FontStyle` | `TFontStyles` | `[]` | Zusätzliche Schriftstile für diesen Eintrag, z. B. [fsBold] für ungelesene Einträge. Praxis: [fsBold] für hervorgehobene Einträge wie den Standard-Lieferanten oder ungelesene Nachrichten. |

## Verwendet in

[TPPGItems](TPPGItems.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
