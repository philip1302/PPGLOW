# TPPGRibbonTab

Typ in Unit `PPG.Ribbon.Items` - Basis `TCollectionItem`

Eine Registerkarte: Beschriftung, Gruppen, KeyTip und Kontext (für farbig markierte Kontext-Registerkarten).

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Caption` | `string` |  | Beschriftung der Registerkarte. Praxis: Kurze Substantive wie in Office: Start, Einfügen, Ansicht, Rechnung. Die erste Karte enthält die häufigsten Befehle. |
| `Groups` | [TPPGRibbonGroups](TPPGRibbonGroups.md) |  | Gruppen der Registerkarte, jede mit Beschriftung und Items. Praxis: Die Befehle einer Karte thematisch in Gruppen teilen (Zwischenablage, Schrift, Absatz); drei bis sechs Gruppen pro Karte bleiben übersichtlich. |
| `Visible` | `Boolean` | `True` | False: Registerkarte ausgeblendet (typisch für Kontext-Karten). Praxis: Karten ausblenden, die der Anwender nicht braucht (fehlendes Recht) oder die nur zu einer Auswahl gehören (Kontext-Registerkarten). |
| `KeyTip` | `string` |  | Eigener KeyTip der Registerkarte; leer = automatisch aus der Beschriftung. Praxis: Nur setzen, wenn der automatische Buchstabe kollidiert oder ein gewohnter Buchstabe gewünscht ist (z. B. „R" für Rechnung). |
| `ContextName` | `string` |  | Name des Kontexts (z. B. „Bildtools"); leer = normale Registerkarte. Benachbarte Karten mit gleichem Namen bilden eine farbige Gruppe; meist zusammen mit Visible nur bei passender Auswahl zeigen. Nutzung: `tabBildFormat.ContextName := 'Bildtools'; tabBildFormat.Visible := BildGewaehlt;` Praxis: Für Karten, die nur bei einer bestimmten Auswahl gebraucht werden (Tabelle, Bild, Diagramm): Namen setzen, Visible := False, und bei passender Auswahl einblenden. |
| `ContextColor` | `TColor` | `clDefault` | Farbe einer Kontext-Registerkarte (Band über der Karte); clNone = Akzentfarbe des Presets. Praxis: Eine Farbe je Kontext (z. B. grün für Tabellentools, violett für Bildtools), damit der Anwender sieht, wozu die Karte gehört. clDefault nimmt die Akzentfarbe. |
| `Tag` | `NativeInt` | `0` | Freier Ganzzahlwert. Praxis: Z. B. eine Karten-ID, um in OnChange ohne Textvergleich zu erkennen, welche Karte gewählt wurde. |

## Verwendet in

[TPPGRibbonTabs](TPPGRibbonTabs.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
