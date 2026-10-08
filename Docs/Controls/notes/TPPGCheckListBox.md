**Vorbild:** TCheckListBox

## Unterschiede und Hinweise

- Kästchen im Preset-Stil; `Header[]` macht Zeilen zu Überschriften (ohne Kästchen, nicht wählbar).
- `Checked[]`/`State[]` im Code lösen kein Ereignis aus; der Anwender löst `OnClickCheck` aus.
- UI Automation: zusätzlich Toggle-Muster je Eintrag.

## Anpassung

- `Styles` und `OnCustomDrawItem` wie `TPPGListBox`.
