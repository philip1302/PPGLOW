# TPPGDBKanban

Palette **PPGlow DB** - Unit `PPG.DB.Kanban` - Basis `TPPGCustomDBKanban`

**Vorbild:** TMS FNC Kanban Board mit Datenbank-Anbindung

## Unterschiede und Hinweise

- Feldzuordnung: `KeyField` (ganze Zahl, Pflicht zum Schreiben), `ColumnField` (Wert = `Column.Key`, sonst `Column.Id`), `OrderField` (Reihenfolge), `TitleField`; optional `LaneField` (Wert = `Lane.Key` bzw. `Id`), `TextField`, `LabelsField`, `AssigneeField`, `DueField`, `ProgressField`, `ColorField`.
- Spalten und Swimlanes legt man wie beim `TPPGKanban` an; die Karten kommen aus der Datenmenge (höchstens `MaxRecords`), sortiert nach `OrderField`. Datensätze mit unbekanntem Spaltenwert erscheinen nicht.
- Nach jedem Verschieben durch den Anwender schreibt das Board Spalte (und Swimlane) der Karte und nummeriert die Karten von Quell- und Zielzelle in Zehnerschritten neu (nur geänderte Datensätze).
- Ohne `KeyField` ist das Board schreibgeschützt (Verschieben wird abgelehnt).
- Änderungen von außen laden nach `ReloadDelay` neu; die Auswahl bleibt an der Karte. `SyncRecord`: die gewählte Karte wird zum aktuellen Datensatz.

## Anpassung

- `KanbanStyles`, `OnCustomDrawCard`, `SaveLayout`/`LoadLayout` wie `TPPGKanban`.

## Beispiel

```pascal
PPGDBKanban1.Columns.AddColumn('Offen').Key := 'todo';
PPGDBKanban1.Columns.AddColumn('In Arbeit', 3).Key := 'doing';
PPGDBKanban1.Columns.AddColumn('Fertig').Key := 'done';
PPGDBKanban1.KeyField := 'ID';
PPGDBKanban1.ColumnField := 'Status';
PPGDBKanban1.OrderField := 'Reihe';
PPGDBKanban1.TitleField := 'Titel';
PPGDBKanban1.DataSource := DataSource1;
```

## Verhalten (aus dem Quelltext)

TPPGDBKanban - Kanban-Board auf einer Datenmenge (Phase 14c, Paket PPGlowDBR).

- Feldzuordnung: KeyField (ganze Zahl, Pflicht zum Schreiben), ColumnField (Wert = Column.Key, sonst Column.Id), OrderField (Reihenfolge in der Spalte), TitleField sowie optional LaneField (Wert = Lane.Key bzw. Id), TextField, LabelsField, AssigneeField, DueField, ProgressField, ColorField.
- Laden: alle Datensaetze (hoechstens MaxRecords) werden in Cards gespiegelt, sortiert nach OrderField. Bestehende Karten werden per Schluessel aktualisiert (Auswahl bleibt).
- Schreiben: nach jedem Verschieben durch den Anwender bekommt die Karte Spalte und Swimlane, die Karten von Quell- und Zielzelle werden in Zehnerschritten neu nummeriert (nur geaenderte Datensaetze).
- Ohne KeyField ist das Board schreibgeschuetzt.
- Datenaenderungen von aussen laden verzoegert neu (ReloadDelay ueber den Animator); eigenes Lesen und Schreiben loest kein Neuladen aus.
- SyncRecord: die gewaehlte Karte wird zum aktuellen Datensatz.

## PPGlow-Eigenschaften

`DataSource`, `KeyField`, `ColumnField`, `LaneField`, `OrderField`, `TitleField`, `TextField`, `LabelsField`, `AssigneeField`, `DueField`, `ProgressField`, `ColorField`, `MaxRecords`, `ReloadDelay`, `SyncRecord`, `Columns`, `Lanes`, `ColumnWidth`, `CardGap`, `MaxTextLines`, `AllowDrag`, `ReadOnly`, `WipMode`, `ShowCardCount`, `KanbanStyles`, `Preset`, `StyleManager`, `Appearance`, `Animation`, `HighContrastSupport`, `ScrollBarMode`, `SmoothScrolling`, `Align`, `Anchors`, `BiDiMode`, `Color`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `TabOrder`, `TabStop`, `Visible`, `Touch`

## Ereignisse

`OnCustomDrawCard`, `OnGesture`, `OnCardMoving`, `OnCardMoved`, `OnCardClick`, `OnCardOpen`, `OnSelectionChange`, `OnColumnCollapse`, `OnEnter`, `OnExit`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBKanban.md`.
