**Vorbild:** TDBRadioGroup (DFM gleich: `DataSource`, `DataField`, `Items`, `Values`, `ReadOnly`)

## Unterschiede und Hinweise

- Alles von `TPPGRadioGroup`, also auch Segmente und Kacheln für Datenbankfelder.
- `Values` wie die VCL; fehlt eine Zeile, gilt die Beschriftung des Eintrags (bzw. `ItemsEx[i].Value`).
- Ein Wert im Feld, der zu keinem Eintrag passt, lässt die Gruppe ohne Auswahl (`ItemIndex = -1`).
- Liegt in der Unit `PPG.DB.Navigator` (Paket PPGlowDBR).
