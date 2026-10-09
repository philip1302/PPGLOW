# TPPGGridPrinter

Palette **PPGlow** - Unit `PPG.Grid.Print` - Basis `TPPGCustomPrinter`

**Vorbild:** TMS TAdvGridPrintSettings / Vorschau, DevExpress Printing

## Unterschiede und Hinweise

- Druckt eine `IPPGTableSource`: das Grid (`Grid`), das DB-Grid oder eine eigene Quelle (`SetSource`), z. B. `TPPGStringTableSource`.
- Seite: `Orientation`, `Margins` (mm), `HeaderText`/`FooterText` mit Platzhaltern `[Seite]`/`[Page]`, `[Seiten]`/`[Pages]`, `[Datum]`/`[Date]`, `[Titel]`/`[Title]`.
- `RepeatHeader` (Spaltenköpfe auf jeder Seite), `FitToPageWidth` (sonst Spalten auf mehrere Seiten), `PrintGridLines`, `PrintColors` (bedingte Formate, Kopf-Hintergrund).
- `UseGridLook` (Vorgabe): Ausdruck und PDF sehen aus wie das Grid in heller Darstellung, inklusive Bänder, Gruppenzeilen, verbundener Zellen und Summenzeile (nur am Ende der letzten Seite). Ein Gruppenkopf bleibt nie allein am Seitenende. `Page(i).RowFirst/RowCount` zählen dann Druckzeilen (Gruppenköpfe und Summe zählen mit), `LayoutLineKind` sagt, welche Art eine Zeile ist.
- Gezeichnet wird mit GDI in der Auflösung des Druckers; Zeilen werden seitenweise aus der Quelle geholt.
- `Preview` zeigt die Seitenansicht (Seitenliste, Zoom, Seite einrichten, Drucken); nur sichtbare Seiten werden gezeichnet.
- `PrintToFile(Drucker, Datei)` druckt ohne Dialog in eine Datei; `PPGExportPdf` nutzt damit „Microsoft Print to PDF“.
- Im Designer: „Print preview...“ und „Page setup...“.

## Beispiel

```pascal
PPGGridPrinter1.Grid := PPGGrid1;
PPGGridPrinter1.Title := 'Lagerliste';
PPGGridPrinter1.HeaderText := '[Titel] - [Datum]';
if PPGGridPrinter1.Preview then
  ShowMessage('Gedruckt');
PPGExportPdf(PPGGridPrinter1, 'Lagerliste.pdf');
```

## Verhalten (aus dem Quelltext)

Drucken von Tabellen (Phase 13e, Optik wie im Grid seit Phase 17).

- TPPGGridPrinter (Komponente fuer den Formular-Designer) druckt eine IPPGTableSource: das Grid, das DB-Grid oder eine eigene Quelle. Er kennt das Control nicht (DIP); Darstellung (bedingte Formate, Zellarten) kommt ueber das schmale IPPGGridPrintSource.
- UseGridLook (Vorgabe): mit IPPGTableLook wie am Bildschirm in heller Darstellung - Schrift, Kopf- und Bandzeilen, Spalten- und Zebra-Stile, bedingte Formate, Gruppenzeilen (TPPGTableLines), verbundene Zellen und die Summenzeile am Ende der letzten Seite. Ein Gruppenkopf bleibt nie allein am Seitenende stehen. Ohne IPPGTableLook bzw. mit False: grauer, fetter Kopf und nur Datenzeilen wie bisher.
- Seite (Ausrichtung, Raender, Kopf-/Fusszeile), Drucken, PDF, Vorschau und "Seite einrichten" kommen aus TPPGCustomPrinter (PPG.Print, seit Phase 14a gemeinsam mit dem Planer). Hier: Spaltenkoepfe auf jeder Seite, auf Seitenbreite einpassen oder Spalten auf mehrere Seiten verteilen, Gitterlinien und Farben abschaltbar.
- Gezeichnet wird mit dem GDI-Canvas in der Aufloesung des Druckers (GDI+ rastert Alpha-Flaechen auf Drucker-DCs zu grossen Bitmaps). Alle Masse sind logisch (96 dpi) und werden mit der Drucker-PPI umgerechnet; die Schrift wird ueber Font.Height mit der Drucker-PPI neu gesetzt.
- Zeilen holt der Drucker seitenweise aus der Quelle (virtuelle Daten).
- Die frueher hier deklarierten Typen (TPPGPrintDevice, TPPGPrintMargins, Vorschau- und Seiten-Formular) gibt es weiter unter demselben Namen.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Grid` | `TPPGCustomGrid` |  | Das Grid bzw. DB-Grid, das gedruckt wird (mit seiner aktuellen Ansicht: Sortierung, Filter, sichtbare Spalten). Nutzung: `PPGGridPrinter1.Grid := PPGGrid1; PPGGridPrinter1.Preview;` |
| `Title` | `string` |  | Titel des Druckauftrags (erscheint in der Druckerwarteschlange) und Wert des Platzhalters [Titel]. |
| `HeaderText` | `string` |  | Kopfzeile jeder Seite (fett) mit denselben Platzhaltern wie FooterText; leer = keine Kopfzeile. Nutzung: `PPGGridPrinter1.HeaderText := '[Titel] - Stand [Datum]';` |
| `FooterText` | `string` |  | Fußzeile jeder Seite mit Platzhaltern [Seite], [Seiten], [Datum], [Titel] (auch englisch [Page], [Pages], [Date], [Title]). Leer = keine Fußzeile; Vorgabe „Seite [Seite] von [Seiten]" in der Sprache der Anwendung. |
| `Orientation` | `TPrinterOrientation` | `poPortrait` | Hochformat (poPortrait) oder Querformat (poLandscape). |
| `Margins` | [TPPGPrintMargins](types/TPPGPrintMargins.md) |  | Seitenränder in Millimetern (Left, Top, Right, Bottom; je 15 mm vorgegeben). Auch im Dialog „Seite einrichten" änderbar. |
| `RepeatHeader` | `Boolean` | `True` | True: Die Spaltenköpfe stehen auf jeder Seite. |
| `FitToPageWidth` | `Boolean` | `True` | True: Alle Spalten werden auf die Seitenbreite verkleinert; False: zu breite Tabellen gehen auf weiteren Seiten nebeneinander weiter. |
| `PrintGridLines` | `Boolean` | `True` | True: Gitterlinien werden gedruckt. |
| `PrintColors` | `Boolean` | `True` | True: Zellfarben (bedingte Formate, Zebra) werden mitgedruckt; False: nur Schwarz auf Weiß. |
| `UseGridLook` | `Boolean` | `True` | True (Vorgabe): Der Ausdruck sieht aus wie das Grid in heller Darstellung – Schrift, Kopf- und Bandzeilen, Spalten- und Zebra-Stile, bedingte Formate, Gruppenzeilen, verbundene Zellen und die Summenzeile am Ende der letzten Seite; ein Gruppenkopf bleibt nie allein am Seitenende. False: grauer, fetter Kopf und nur Datenzeilen wie früher. Auch im Dialog „Seite einrichten“ umschaltbar. |
| `PrinterName` | `string` |  | Name des Druckers; leer = Standarddrucker. Für PDF z. B. „Microsoft Print to PDF" mit PrintToFile. Nutzung: `PPGGridPrinter1.PrintToFile('Microsoft Print to PDF', 'C:\Export\Liste.pdf');` |

Tests: `PPG.Tests.Audit45` (TEffectFixTests, TStreamingFixTests); `PPG.Tests.Phase13e` (TGridPrintTests); `PPG.Tests.Phase13f` (TExportTests); `PPG.Tests.Phase13g` (TDBGridColumnTests); `PPG.Tests.Phase17` (TGridLookPrintTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGGridPrinter.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
