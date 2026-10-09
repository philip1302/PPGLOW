# Roadmap 3 – die wichtigsten weiteren Features

*Stand 08.10.2026. **Vom User am 08.10.2026 freigegeben („passt so, nimm überall die Empfehlungen“):** Reihenfolge wie unten, Phase 18 komplett mit ListView, Phase 21 erst nach einer Inventur, jede Phase mit Detailplan, Bericht und OK. Detailplan Phase 17: `Docs\Phase17-Plan.md`.*

*Grundlage: Abgleich der Palette mit typischen VCL-, TMS- und DevExpress-Anwendungen, die offenen Punkte der Phasen 11–14 und der Umstellungsplan für Kundenprojekte. Leitlinie: kein Aufblähen, nur Bausteine mit echtem Mehrwert für die Vorführung beim Arbeitgeber und für Umstellungen.*

## Übersicht (Vorschlag zur Reihenfolge)

| Phase | Inhalt | Größe | Warum jetzt |
|---|---|---|---|
| 17 | Ausgabe wie am Bildschirm: Druck, PDF und HTML mit der Grid-Optik | klein | Gleiche Kritik wie beim Excel-Export ist absehbar. `IPPGTableLook` gibt es schon. |
| 18 | **Mehrwert statt Klone** (neu gefasst 08.10.2026): Auswahlgruppe mit Segment/Kacheln, `TPPGTileView` (Kachel-/Karten-Galerie), DB-Navigator mit Zähler/Suche/Filter, ScrollBox als `Panel.AutoScroll` | mittel–groß | Nur Controls, die mindestens zwei Dinge können, die VCL und TMS nicht können. Reine Nachbauten erst nach Inventur. |
| 19 | Formular-Produktivität: `TPPGValidator`, `TPPGBusyOverlay` | klein–mittel | Spart in jedem Eingabeformular Code. Fertige Bausteine für Fehlerprüfung und Warten. |
| 20 | Fertigstellen: offene Punkte an Planer, Kanban, Ribbon, ComboBox und Grid-Druck | mittel | Fällt Anwendern eher auf als ein weiteres Control. |
| 21 | Nach der Inventur eines echten Kundenprojekts: `TPPGLayoutControl`, `TPPGInspector`, `TPPGFilterBuilder` | groß | Nur bauen, was die Zahlen rechtfertigen. |
| 16 | (bestehender Plan) Demo-Tour, dazu `TPPGCommandPalette` | mittel | Kommt zuletzt, damit sie alles zeigt. Die Kommando-Palette lohnt sich für die Vorführung. |

Nicht geplant (bewusst): Gantt, Pivot-Grid, Docking, RichEdit/HTML-Editor, Code-Editor, PDF-Viewer, Barcode/QR, Shape/Bevel/Image, weitere Diagrammtypen.

## Phase 17 – Ausgabe wie am Bildschirm
- **Druck/PDF** (`TPPGGridPrinter`): Kopf-, Band-, Summen- und Gruppenfarben, Linienfarbe, Spalten- und Zebra-Stile über `IPPGTableLook`. Bisher sind die Kopffarbe (`$F0F0F0`) und die Linienfarbe fest eingestellt, Bänder, Gruppenzeilen und Summenzeile fehlen im Druck.
  - Schalter `UseGridLook` (Vorgabe True); `PrintColors = False` druckt weiter schwarz-weiß.
  - Offen aus Phase 13: Gruppenzeilen und verbundene Zellen im Druck.
- **HTML**: dieselbe Optik (Kopf, Bänder, Linien, Zebra, Spaltenstile, Kästchen/Sterne als Zeichen, Datenbalken als CSS-Hintergrund).
- **Planer- und Kanban-Druck** prüfen: Kategorienfarben und Element-Stile müssen auch dort ankommen.
- Prüfung: Pixeltests auf der Druckvorschau und Vergleich mit dem Grid-Screenshot.

## Phase 18 – Mehrwert statt Klone
Detailplan: `Docs\Phase18-Plan.md`. **Fertig (09.10.2026):** `TPPGRadioGroup`/`TPPGCheckGroup` (Segmente, Kacheln), `TPPGTileView`, `TPPGDBNavigator` mit Zähler/Suche/Filter, `TPPGDBRadioGroup`, `TPPGPanel.AutoScroll` und `TPPGScrollBox`, Migration dazu. Zurückgestellt bis zu einer Inventur: `TPPGDBText`, `TPPGDBListBox`, `TPPGDBLookupListBox`, `TPPGDBSpinEdit`, `TPPGDBToggleSwitch` und eine 1:1-`TPPGListView` (reine Nachbauten ohne Mehrwert).

## Phase 19 – Formular-Produktivität
- **`TPPGValidator`** (nicht sichtbar): Regeln je Control (Pflicht, Bereich, Länge, Muster, eigene per Ereignis), nutzt den vorhandenen `ValidationState` der Felder, Fehlertext am Feld, Sammelliste, `Validate: Boolean`, springt zum ersten Fehler, optional OK-Button sperren, Prüfung beim Verlassen oder erst beim Speichern.
- **`TPPGBusyOverlay`**: legt sich über ein Control oder Formular, ProgressRing plus Text, optional Abbrechen-Knopf und Fortschritt; Eingaben darunter gesperrt; Screenreader-Ansage.

## Phase 20 – Fertigstellen bestehender Controls
- Planer: Abfrage „nur dieses Vorkommen oder ganze Serie“, Ort/Text direkt bearbeiten.
- Kanban: Filter nach Label/Person, Spalten ziehen (Drucken ist mit `TPPGKanbanPrinter` erledigt).
- Ribbon: Tastaturfokus in Popups, Galerie-Kategorien.
- ComboBox auf die neue Aufklapp-Basis umstellen (Phase 12).
- TrackBar-Auswahlbereich, `TPPGFloatSpinEdit` (falls NumberEdit nicht reicht).

## Phase 21 – nach Inventur (nur bei Bedarf)
Voraussetzung: `Build\inventory.ps1` aus dem Umstellungsplan läuft an einem echten Projekt und zeigt, welche Fremdklassen am häufigsten übrig bleiben.
- `TPPGLayoutControl` (wie `dxLayoutControl`): Gruppen, Beschriftung und Feld automatisch ausgerichtet, DPI und Fenstergröße.
- `TPPGInspector` (wie `TValueListEditor`/`dxVerticalGrid`): Kategorien, Editoren aus Phase 12.
- `TPPGFilterBuilder` (wie `cxFilterControl`): Bedingungen mit Und/Oder, für Grid-Filter und Dataset-Filter.

## Außerhalb der Feature-Phasen (Absicherung)
- XE2- und 10.x-Lauf nach `Docs\Kompatibilitaet.md`. Das ist das größte Risiko für den Einsatz beim Arbeitgeber, weil PPGlow bisher nur mit Delphi 13 kompiliert wurde.
- Der Excel-Export ist in echtem Excel noch nicht angesehen worden, vor allem Datenbalken und Fortschritt (OpenOffice zeigt sie nicht).

## Entscheidungen (vor dem Start)
1. Reihenfolge wie oben, oder andere Schwerpunkte?
2. Phase 18: alle Controls, oder zuerst nur RadioGroup, ScrollBox, DB-Navigator, DBText (ohne ListView)?
3. Phase 21 erst nach einer Inventur, oder LayoutControl schon vorher?
4. Wie bisher: jede Phase mit eigenem Detailplan, Bericht und OK?
