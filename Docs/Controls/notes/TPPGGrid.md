**Vorbild:** TStringGrid, TMS TAdvStringGrid

## Unterschiede und Hinweise

- `Row`/`Cells[]` arbeiten mit Datenzeilen, `Selection` mit sichtbaren Zeilen (Sortierung/Filter).
- Enter im Editor übernimmt und bleibt in der Zelle (wie `TStringGrid`); Pfeil hoch/runter im Text-Editor übernimmt und wechselt die Zeile.
- `OnSelectCell` kommt wie bei `TStringGrid` auch bei `Row`/`Col` im Code.
- Kopfklick sortiert: aufsteigend → absteigend → unsortiert. Zeilenhöhe nur per Code (`RowHeights`).
- UI Automation: Tabellen-Muster mit Kopfzeilen, Wert, Kästchen-Spalten und Sortieren per Invoke.
