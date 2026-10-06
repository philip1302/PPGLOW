# TPPGGridPrinter

Palette **PPGlow** - Unit `PPG.Grid.Print` - Basis `TComponent`

**Vorbild:** TMS TAdvGridPrintSettings / Vorschau, DevExpress Printing

## Unterschiede und Hinweise

- Druckt eine `IPPGTableSource`: das Grid (`Grid`), das DB-Grid oder eine eigene Quelle (`SetSource`), z. B. `TPPGStringTableSource`.
- Seite: `Orientation`, `Margins` (mm), `HeaderText`/`FooterText` mit Platzhaltern `[Seite]`/`[Page]`, `[Seiten]`/`[Pages]`, `[Datum]`/`[Date]`, `[Titel]`/`[Title]`.
- `RepeatHeader` (Spaltenköpfe auf jeder Seite), `FitToPageWidth` (sonst Spalten auf mehrere Seiten), `PrintGridLines`, `PrintColors` (bedingte Formate, Kopf-Hintergrund).
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

Drucken von Tabellen (Phase 13e).

- TPPGGridPrinter (Komponente fuer den Formular-Designer) druckt eine IPPGTableSource: das Grid, das DB-Grid oder eine eigene Quelle. Er kennt das Control nicht (DIP); Darstellung (bedingte Formate, Zellarten) kommt ueber das schmale IPPGGridPrintSource.
- Seite: Ausrichtung, Raender (mm), Kopf-/Fusszeile mit Platzhaltern [Seite]/[Page], [Seiten]/[Pages], [Datum]/[Date], [Titel]/[Title]. Spaltenkoepfe auf jeder Seite, auf Seitenbreite einpassen oder Spalten auf mehrere Seiten verteilen, Gitterlinien und Farben abschaltbar.
- Gezeichnet wird mit dem GDI-Canvas in der Aufloesung des Druckers (GDI+ rastert Alpha-Flaechen auf Drucker-DCs zu grossen Bitmaps). Alle Masse sind logisch (96 dpi) und werden mit der Drucker-PPI umgerechnet; die Schrift wird ueber Font.Height mit der Drucker-PPI neu gesetzt.
- Zeilen holt der Drucker seitenweise aus der Quelle (virtuelle Daten).
- Vorschau: TPPGPrintPreviewForm (PPGlow-Controls) zeichnet nur sichtbare Seiten in Metafiles (mit Zwischenspeicher fuer wenige Seiten).

## PPGlow-Eigenschaften

`Grid`, `Title`, `HeaderText`, `FooterText`, `Orientation`, `Margins`, `RepeatHeader`, `FitToPageWidth`, `PrintGridLines`, `PrintColors`, `PrinterName`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGGridPrinter.md`.
