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
