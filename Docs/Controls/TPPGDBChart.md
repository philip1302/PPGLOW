# TPPGDBChart

Palette **PPGlow DB** - Unit `PPG.DB.Chart` - Basis `TPPGCustomDBChart`

**Vorbild:** TDBChart (TeeChart)

## Unterschiede und Hinweise

- Felder auf Diagramm-Ebene: `ValueFields` (`"Umsatz;Kosten"`, je Feld eine Serie in der Reihenfolge von `Series`), `LabelField`, `XField`. Fehlende Serien werden angelegt und nach `DisplayLabel` benannt.
- Anbinden, Öffnen und Schließen laden sofort; Datenänderungen laden nach `ReloadDelay` ms (viele Änderungen = ein Laden).
- Während `Edit`/`Insert` wird nicht gelesen (sonst würde die Eingabe gespeichert); das Laden folgt nach `Post`/`Cancel`.
- `MaxRecords` begrenzt das Lesen; eindirektionale Datenmengen werden nicht gelesen.
- `ShowCurrentRecord` markiert den aktuellen Datensatz, `JumpToRecord` springt beim Klick auf einen Punkt (über `RecNo`).

## Beispiel

```pascal
PPGDBChart1.DataSource := DataSource1;
PPGDBChart1.LabelField := 'Monat';
PPGDBChart1.ValueFields := 'Umsatz;Kosten';
```

## Verhalten (aus dem Quelltext)

TPPGDBChart - Diagramm aus einer Datenmenge (Phase 10e, Paket PPGlowDBR).

- DataSource, ValueFields ("Umsatz;Kosten": je Feld eine Serie, in der Reihenfolge der Series; fehlende Serien werden angelegt und nach Field.DisplayLabel benannt), LabelField (Kategorie-Text) und XField (X-Wert fuer Zahl-/Datumsachse).
- Gelesen wird die ganze Datenmenge (hoechstens MaxRecords) mit DisableControls und Lesezeichen; der aktuelle Datensatz bleibt stehen.
- Anbinden, Oeffnen und Schliessen laden sofort. Datenaenderungen laden verzoegert neu (ReloadDelay ueber den gemeinsamen Animator, nie im Paint): viele Aenderungen hintereinander = ein Laden. Die Ereignisse des eigenen Lesens werden ignoriert.
- ShowCurrentRecord markiert den aktuellen Datensatz (MarkedIndex); Klick auf einen Punkt springt zum Datensatz (JumpToRecord).
- Eindirektionale Datenmengen werden nicht gelesen (kein Zurueckspringen).
- Waehrend Edit/Insert wird nicht gelesen (First wuerde die Eingabe des Anwenders speichern); das Laden folgt nach Post bzw. Cancel.

## PPGlow-Eigenschaften

`DataSource`, `ValueFields`, `LabelField`, `XField`, `MaxRecords`, `ReloadDelay`, `ShowCurrentRecord`, `JumpToRecord`, `Preset`, `StyleManager`, `Appearance`, `Animation`, `HighContrastSupport`, `Title`, `Series`, `Categories`, `XAxis`, `YAxis`, `Y2Axis`, `ReferenceLines`, `Stacking`, `LegendPosition`, `ShowTooltips`, `LegendToggle`, `Align`, `Anchors`, `BiDiMode`, `Constraints`, `Enabled`, `Font`, `Hint`, `ParentBiDiMode`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnClick`, `OnDblClick`, `OnEnter`, `OnExit`, `OnMouseDown`, `OnMouseMove`, `OnMouseUp`, `OnPointClick`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBChart.md`.
