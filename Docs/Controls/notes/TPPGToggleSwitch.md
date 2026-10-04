**Vorbild:** TToggleSwitch (Vcl.WinXCtrls)

## Unterschiede und Hinweise

- Statt `State = tssOn/tssOff` gibt es `Checked` (das Migrationsskript setzt das um).
- `AccValue` liefert „On“/„Off“ für Screenreader (übersetzt mit `PPG.Lang`).
